#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
# 目标 -> ram 实例名（两侧同名；ram 不复位，首沿前把 golden 的 Memory 抄给重写侧）
Q = {'Queue16_DSBeat': 'ram_data_ext', 'Queue16_TaskBundle': 'ram_ext', 'Queue2_CHISNP': 'ram_ext',
     'Queue16_GrantQueueTask': 'ram_ext', 'Queue16_GrantQueueData': 'ram_data_data_ext'}
# 出队 ready 分相：每 2000 拍在"出得快(75%)"与"出得慢(25%)"间切换，让队列既能排空也能灌满
DEQ = "((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
args = []
for q, r in Q.items():
    args += ['--target', q, '--narrow', f'{q}:io_deq_ready$={DEQ}',
             '--sync', f'{q}:{r}.Memory=>{r}.Memory',
             '--cover', f'{q}:full=u_g_{q}.maybe_full && u_g_{q}.ptr_match' if q != 'Queue16_GrantQueueData'
             else f'{q}:full=!u_g_{q}.io_enq_ready',
             '--cover', f'{q}:deq=u_g_{q}.do_deq']
for q in ('Queue16_DSBeat', 'Queue16_TaskBundle'):   # flow 直通：空队列同拍进出
    args += ['--cover', f'{q}:bypass=u_g_{q}.empty && {q}__io_enq_valid && {q}__io_deq_ready']
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
