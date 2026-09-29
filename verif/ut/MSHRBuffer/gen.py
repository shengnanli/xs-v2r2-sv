#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
args = []
ID = "(($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17))"
for v in ('MSHRBuffer', 'MSHRBuffer_1'):
    args += ['--target', v, '--narrow', f'{v}:_bits_id$={ID}']
    # 存储阵列不复位：首沿前把 golden 的 buffer_<i>_<b> 初值抄给重写侧 buffer[i][b]
    for i in range(16):
        for b in range(2):
            args += ['--sync', f'{v}:buffer_{i}_{b}=u_core.buffer[{i}][{b}]']
    args += ['--cover', f'{v}:rd=u_g_{v}.io_r_valid']
args += ['--cover', "MSHRBuffer:w0partial=MSHRBuffer__io_w_0_valid && MSHRBuffer__io_w_0_bits_beatMask != 2'b11 && MSHRBuffer__io_w_0_bits_id < 16",
         '--cover', "MSHRBuffer:collide=MSHRBuffer__io_w_0_valid && MSHRBuffer__io_w_1_valid && MSHRBuffer__io_w_0_bits_id == MSHRBuffer__io_w_1_bits_id && MSHRBuffer__io_w_0_bits_id < 16",
         '--cover', "MSHRBuffer_1:collide3=MSHRBuffer_1__io_w_1_valid && MSHRBuffer_1__io_w_2_valid && MSHRBuffer_1__io_w_1_bits_id == MSHRBuffer_1__io_w_2_bits_id && MSHRBuffer_1__io_w_1_bits_id < 16",
         '--cover', "MSHRBuffer:rdhigh=MSHRBuffer__io_r_valid && MSHRBuffer__io_r_bits_id > 15"]
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
