#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
TARGETS = ('L2Slice', 'L2Slice_1', 'L2Slice_2', 'L2Slice_3')
args = []
for v in TARGETS:
    args += ['--target', v,
             # 唯一不复位寄存器：读数据回程打拍（golden always @(posedge clock) if (activated)）
             '--sync', f'{v}:pipelineDataOutReg=u_core.g_node_return.pipelineDataOutReg',
             '--cover', f'{v}:sel0=u_g_{v}.selected',
             '--cover', f'{v}:sel1=u_g_{v}.selected_1',
             '--cover', f'{v}:act=u_g_{v}.activated']
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
