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
# 目标 -> (golden ram 路径, 重写侧 ram 路径)；ram 不复位，首沿前把 golden 的 Memory 抄给重写侧
Q = {'Queue16_CHIREQ': ('ram_ext', 'ram_ext'), 'Queue16_CHIRSP': ('ram_ext', 'ram_ext'),
     'Queue4_CHISNP': ('ram_ext', 'ram_ext'), 'Queue2_PCrdGranted': ('ram_ext', 'ram_ext'),
     'Queue78_PCrdGranted': ('ram_ext', 'ram_ext'),
     'Queue40_L2TlbMQBundle': ('ram_ext', 'u_core.ram_ext')}
# 出队 ready 分相：每 2000 拍在"出得快(75%)"与"出得慢(25%)"间切换，让队列既能排空也能灌满
DEQ = "((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
args = []
for q, (g, i) in Q.items():
    full = f'u_g_{q}.maybe_full && u_g_{q}.ptr_match'
    args += ['--target', q, '--narrow', f'{q}:io_deq_ready$={DEQ}',
             '--sync', f'{q}:{g}.Memory=>{i}.Memory',
             '--cover', f'{q}:full={full}',
             '--cover', f'{q}:enq=u_g_{q}.do_enq',
             '--cover', f'{q}:deq=u_g_{q}.do_deq',
             '--cover', f'{q}:enq_deq_same=u_g_{q}.do_enq && u_g_{q}.do_deq',
             '--cover', f'{q}:full_blocked={full} && {q}__io_enq_valid && !{q}__io_deq_ready']
for q in Q:
    args += ['--min-toggled', f'{q}:{min_toggled(q)}']
# pipe=true：满队列在出口接走的同拍照样入队
args += ['--cover', 'Queue4_CHISNP:pipe_enq_when_full=u_g_Queue4_CHISNP.maybe_full && u_g_Queue4_CHISNP.ptr_match'
         ' && u_g_Queue4_CHISNP.do_enq']
# 非 2 的幂深度：指针在 DEPTH-1 处回 0
args += ['--cover', 'Queue78_PCrdGranted:enq_wrap=u_g_Queue78_PCrdGranted.do_enq && u_g_Queue78_PCrdGranted.enq_ptr_value == 7\'d77',
         '--cover', 'Queue78_PCrdGranted:deq_wrap=u_g_Queue78_PCrdGranted.do_deq && u_g_Queue78_PCrdGranted.deq_ptr_value == 7\'d77',
         '--cover', 'Queue40_L2TlbMQBundle:enq_wrap=u_g_Queue40_L2TlbMQBundle.do_enq && u_g_Queue40_L2TlbMQBundle.enq_ptr_value == 6\'d39',
         '--cover', 'Queue40_L2TlbMQBundle:deq_wrap=u_g_Queue40_L2TlbMQBundle.do_deq && u_g_Queue40_L2TlbMQBundle.deq_ptr_value == 6\'d39']
# flush：稀疏（约 1/300 拍），且要盖到"非空时 flush"与"flush 同拍入队"
args += ['--narrow', 'Queue40_L2TlbMQBundle:io_flush$=(($urandom % 300) == 0)',
         '--cover', 'Queue40_L2TlbMQBundle:flush_nonempty=Queue40_L2TlbMQBundle__io_flush && !u_g_Queue40_L2TlbMQBundle.empty',
         '--cover', 'Queue40_L2TlbMQBundle:flush_with_enq=Queue40_L2TlbMQBundle__io_flush && u_g_Queue40_L2TlbMQBundle.do_enq']
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
