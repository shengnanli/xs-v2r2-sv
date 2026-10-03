#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
# (SRAMTemplate 实例路径, 厂商宏叶子名)
SRAMS = [('tagArray.array_0_0_0', 'array_14_ext'), ('tagArray.array_0_0_1', 'array_14_ext'),
         ('tagArray.array_0_1_0', 'array_14_ext'), ('tagArray.array_0_1_1', 'array_14_ext'),
         ('metaArray', 'array_15_ext'), ('replacer_sram_opt', 'array_16_ext'), ('origin_bit_opt', 'array_17_ext')]
SMALL2 = lambda w: f"{w}'($urandom_range(0, 3))"
# set 取 {0,1,2,240}：0 落在 SRRIP 监视组（set[8:4]==set[4:0]），240=9'b0_1111_0000 落在 BRRIP 监视组
# （set[8:4]==~set[4:0]；两段在 bit4 重叠，所以要 set[4]==~set[0]）
# 每 4000 拍里有 1000 拍（"拥挤相"）把读与 MSHR 全压到 set 0，让"8 路全被 MSHR 占 -> retry"能出现
CROWD = "((cyc / 1000) % 4 == 0)"
SETS = f"{CROWD} ? 9'h0 : 9'(($urandom % 4) == 3 ? 240 : $urandom_range(0, 2))"
args = []
for v in ('Directory', 'Directory_1', 'Directory_2', 'Directory_3'):
    args += ['--target', v,
             # set / tag 收窄到 4 个值，让读能命中写过的行、MSHR 占用判定能命中
             '--narrow', f"{v}:io_(read|metaWReq|tagWReq)_bits_set$={SETS}",
             '--narrow', f"{v}:io_msInfo_\\d+_bits_set$={SETS}",
             '--narrow', f"{v}:io_(read_bits_tag|tagWReq_bits_wtag)$={SMALL2(31)}",
             # 写请求 1/4 概率：给读留出 ready
             '--narrow', f"{v}:io_(metaWReq|tagWReq)_valid$=(($urandom % 4) == 0)",
             # MSHR 有效率分相：平时 1/4，每 4000 拍里有 1000 拍拉到 7/8，让"8 路全被占 -> retry"能出现
             '--narrow', f"{v}:io_msInfo_\\d+_valid$={CROWD} ? (($urandom % 8) != 0) : (($urandom % 4) == 0)",
             # DFT 辅助时钟旁路钉 0（见 DataStorage 的同一条说明：会在改输入瞬间造时钟沿，形成仿真竞争）
             '--narrow', f"{v}:sigFromSrams_bore(_\\d)?_ram_aux_(clk|ckbp)$=1'b0",
             '--cover', f'{v}:hit=u_g_{v}.io_resp_valid && u_g_{v}.io_resp_bits_hit',
             '--cover', f'{v}:miss=u_g_{v}.io_resp_valid && !u_g_{v}.io_resp_bits_hit',
             '--cover', f'{v}:repl=u_g_{v}.io_replResp_valid',
             '--cover', f'{v}:retry=u_g_{v}.io_replResp_valid && u_g_{v}.io_replResp_bits_retry',
             '--cover', f'{v}:err=u_g_{v}.io_resp_valid && u_g_{v}.io_resp_bits_error',
             '--cover', f"{v}:pselUp=u_g_{v}.PSEL > 10'h200",
             '--cover', f"{v}:pselDn=u_g_{v}.refillReqValid_s3 && u_g_{v}.match_b && !u_g_{v}.hit_s3",
             '--cover', f'{v}:initDone=u_g_{v}.resetFinish']
    for path, ext in SRAMS:
        leaf = f'{path}.array.array.{ext}'
        args += ['--preinit', f'{v}:{leaf}.ram',
                 '--sync', f'{v}:{leaf}.ram=>{leaf}.ram',
                 '--sync', f'{v}:{leaf}.reg_RW0_addr=>{leaf}.reg_RW0_addr',
                 '--sync', f'{v}:{leaf}.reg_RW0_ren=>{leaf}.reg_RW0_ren',
                 '--sync', f'{v}:{path}.rdataReg={path}.u_core.rdataReg']
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
