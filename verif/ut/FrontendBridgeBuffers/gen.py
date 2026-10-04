#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

三个 FrontendBridge 缓冲：每个 4 个 Queue2（A 两级 nodeOut_a_q/_1，D 两级 nodeIn_d_q/_1）。
ram_ext 不复位：首沿前把 golden 每个 Queue2 的 ram Memory 抄给重写侧（两侧实例路径同名）。
覆盖：每个 Queue2 的 进队 / 出队 / 满且被挡；出口 ready 分相（快出 / 慢出交替）让队列能灌满也能排空。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))

QUEUES = ['nodeOut_a_q', 'nodeOut_a_q_1', 'nodeIn_d_q', 'nodeIn_d_q_1']
# 出口 ready 分相：每 2000 拍在"出得快(75%)"与"出得慢(25%)"间切换
PHASE = "((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
# 各目标里有 ready 输入的出口（D 口恒接收的目标没有 auto_in_d_ready）
READY_IN = {
    'ICacheBuffer':       ['auto_out_a_ready'],
    'InstrUncacheBuffer': ['auto_out_a_ready'],
    'ICacheCtrlBuffer':   ['auto_out_a_ready', 'auto_in_d_ready'],
}
# 恒 0 常量出口（入口补的 0 原样走队列）在 +vcs+initreg+0 档下永不翻转，不计入翻转闸（两侧仍逐拍比）：
#   ICacheBuffer      a.param / a.user_alias / a.user_needHint / a.data / a.corrupt   -> 20 - 5
#   InstrUncacheBuffer a.param / a.corrupt                                            -> 12 - 2
#   ICacheCtrlBuffer  d.param / d.sink / d.denied / d.corrupt                          -> 18 - 4
MIN_TOGGLED = {'ICacheBuffer': 15, 'InstrUncacheBuffer': 10, 'ICacheCtrlBuffer': 14}
args = []
for t, readies in READY_IN.items():
    args += ['--target', t, '--min-toggled', f'{t}:{MIN_TOGGLED[t]}']
    for r in readies:
        args += ['--narrow', f'{t}:{r}$={PHASE}']
    for q in QUEUES:
        args += ['--sync', f'{t}:{q}.ram_ext.Memory=>{q}.ram_ext.Memory',
                 '--cover', f'{t}:{q}_enq=u_g_{t}.{q}.do_enq',
                 '--cover', f'{t}:{q}_deq=u_g_{t}.{q}.do_deq']
        # D 口恒接收（第二级 deq_ready=1）时 D 链两级都不可能满（golden 同），满闸只对有 ready 的链
        if q.startswith('nodeIn_d') and 'auto_in_d_ready' not in readies:
            continue
        args += ['--cover', f'{t}:{q}_full_blocked=u_g_{t}.{q}.full && u_g_{t}.{q}.io_enq_valid']
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
