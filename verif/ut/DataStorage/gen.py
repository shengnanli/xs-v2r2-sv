#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
args = []
for v in ('DataStorage', 'DataStorage_1', 'DataStorage_2', 'DataStorage_3'):
    args += ['--target', v,
             # set/way 收窄到 4x2，让读能命中先前写过的块
             '--narrow', f"{v}:io_req_bits_set$=9'($urandom_range(0, 3))",
             '--narrow', f"{v}:io_req_bits_way$=3'($urandom_range(0, 1))",
             # 偶尔注入单/双比特错：写数据正常，读出的码字由阵列给出，错误靠 MBIST 写口制造
             # DFT 辅助时钟旁路（aux_ckbp=1 时 SRAM 时钟直接取 aux_clk）会在 tb 改输入的那一刻造出时钟沿，
             # 与同一时刻改变的地址/数据构成**仿真竞争**（golden 与重写的 delta 深度不同，先后不定），
             # 比出来的差异与 RTL 无关。功能模式下这两根 DFT 线恒 0，这里也钉 0；其等价由 FM 证明。
             '--narrow', f"{v}:sigFromSrams_bore(_\\d)?_ram_aux_(clk|ckbp)$=1'b0",
             '--cover', f'{v}:rd=u_g_{v}.error_REG_1',
             '--cover', f'{v}:err=u_g_{v}.io_error',
             '--cover', f'{v}:wr=u_g_{v}.io_req_valid && u_g_{v}.io_req_bits_wen']
    for k in range(4):
        base = f'array.array_0_0_{k}.array.array.array_18_ext'
        args += ['--sync', f'{v}:{base}.ram=>{base}.ram',
                 '--sync', f'{v}:{base}.reg_RW0_addr=>{base}.reg_RW0_addr',
                 '--sync', f'{v}:{base}.reg_RW0_ren=>{base}.reg_RW0_ren']
    args += ['--sync', f'{v}:error_REG=u_core.error_REG',
             '--sync', f'{v}:error_REG_1=u_core.error_REG_1']
GEN = os.path.join(HERE, '../../../scripts/gen_l2slice_ut.py')
TB = os.path.join(HERE, 'tb.sv')
if '--check' in sys.argv[1:]:
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, 'tb.sv')
        rc = subprocess.call([sys.executable, GEN, '--out', out] + args, stdout=subprocess.DEVNULL)
        ok = rc == 0 and os.path.exists(TB) and filecmp.cmp(out, TB, shallow=False)
    print(('OK: ' if ok else 'DRIFT: ') + TB)
    sys.exit(0 if ok else 1)
sys.exit(subprocess.call([sys.executable, GEN, '--out', TB] + args))
