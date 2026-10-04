#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))

# 翻转闸：整段只读 ram 常量段的出队输出（父模块入队时恒为常量，firtool 把常量拼进 ram 字）在第一次
# 入队后就不再变化，能否"翻转"只取决于 ram 初值（initreg 档），与重写对错无关 —— 不计入翻转闸
# （两侧逐拍相等照比）。名单由 scripts/gen_uncore_queues.py 的 golden 解析现算，不手抄。
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
import gen_uncore_queues as guq  # noqa: E402


def min_toggled(q, extra=0):
    R = guq.parse_queue(q)
    consts = [(h, l) for k, _, _, h, l in R['layout'] if k == 'const']
    const_only = [n for n, (h, l) in R['deq'].items()
                  if n[len('io_deq_bits_'):] not in {x[2] for x in R['layout'] if x[0] == 'field'}
                  and any(cl <= l and h <= ch for ch, cl in consts)]
    n_out = sum(1 for d, _, _ in R['P'] if d == 'output')
    return n_out - len(const_only) - extra
# 目标 -> ram 实例名（两侧同名；ram 不复位，首沿前把 golden 的 Memory 抄给重写侧）
Q = {'Queue2_TLBundle' + s: 'ram_ext' for s in
     'A_6 A_7 A_8 A_10 A_12 A_14 A_15 A_19 A_31 B B_1 C C_1 D_7 D_8 D_11 D_13 D_15 D_20'.split()}
Q['Queue2_TLBundleE'] = 'ram_sink_ext'
Q['Queue2_TLBundleE_1'] = 'ram_sink_ext'
NO_DEQ_READY = {'Queue2_TLBundleE_1'}   # 父模块把 deq.ready 钉成 1，firtool 删了端口
# 出队 ready 分相：每 2000 拍在"出得快(75%)"与"出得慢(25%)"间切换，让队列既能排空也能灌满
DEQ = "((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
args = []
for q, r in Q.items():
    if q not in NO_DEQ_READY:
        args += ['--narrow', f'{q}:io_deq_ready$={DEQ}',
                 '--cover', f'{q}:deq=u_g_{q}.do_deq',
                 '--cover', f'{q}:enq_deq_same=u_g_{q}.do_enq && u_g_{q}.do_deq',
                 '--cover', f'{q}:full_blocked=u_g_{q}.full && {q}__io_enq_valid',
                 '--cover', f'{q}:full=u_g_{q}.maybe_full && u_g_{q}.ptr_match']
    else:
        # deq.ready 恒 1：非空即出队，队列最多存 1 项，"满"不可达（golden 同），只盖进/出与同拍进出
        args += ['--cover', f'{q}:deq=!u_g_{q}.empty',
                 '--cover', f'{q}:enq_deq_same=u_g_{q}.do_enq && !u_g_{q}.empty']
    # Queue2_TLBundleE_1：deq.ready 恒 1，队列永远不满，io_enq_ready 复位后恒 1（golden 同），也不计
    args += ['--min-toggled', f'{q}:{min_toggled(q, 1 if q in NO_DEQ_READY else 0)}']
    args += ['--target', q, '--sync', f'{q}:{r}.Memory=>{r}.Memory',
             '--cover', f'{q}:enq=u_g_{q}.do_enq']
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
