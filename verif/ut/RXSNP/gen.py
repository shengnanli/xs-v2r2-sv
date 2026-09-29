#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'RXSNP'
# snoop 地址收窄：tag∈{0,1}、set∈{0,1}，其余位随机 —— 让与 MSHR 的 set/tag 比较能命中
ADDR = "{30'h0, 1'($urandom), 8'h0, 1'($urandom), 5'($urandom)}"
args = ['--target', T,
        '--narrow', f'{T}:io_rxsnp_bits_addr$={ADDR}',
        '--narrow', f"{T}:io_msInfo_\\d+_bits_set$=9'($urandom_range(0, 1))",
        '--narrow', f"{T}:io_msInfo_\\d+_bits_(reqTag|metaTag)$=31'($urandom_range(0, 1))",
        # MSHR 有效率压到 1/4，免得 16 个里总有一个把 snoop 挡死
        '--narrow', f"{T}:io_msInfo_\\d+_valid$=(($urandom % 4) == 0)",
        '--sync', f'{T}:queue.ram_ext.Memory=>queue.ram_ext.Memory',
        '--cover', f'{T}:stall=u_g_{T}.stall',
        '--cover', f'{T}:fire=u_g_{T}._GEN',
        '--cover', f'{T}:nest=u_g_{T}.io_task_bits_snpHitRelease && u_g_{T}.io_task_valid',
        '--cover', f"{T}:nestIdxNZ=u_g_{T}.io_task_bits_snpHitRelease && u_g_{T}.io_task_bits_snpHitReleaseIdx != 0",
        '--cover', f'{T}:replBlk=u_g_{T}.replaceBlockSnp']
for i in range(16):
    sfx = '' if i == 0 else f'_{i}'
    args += ['--sync', f'{T}:replaceBlockSnpMask_REG{sfx}=u_core.replPrevForBlock[{i}]',
             '--sync', f'{T}:replaceNestSnpMask_REG{sfx}=u_core.replPrevForNest[{i}]']
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
