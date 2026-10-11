#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_backend.py —— Backend（后端顶层装配）的 golden 同名 wrapper 生成器。

产出：
  1. rtl/backend/Backend.sv 里 `// BEGIN GENERATED(be_wrapper)` … `// END GENERATED` 之间的 module Backend：
     端口表（与 golden 逐位同名同序）、子模块之间的连线声明、46 个子模块例化（模块名与实例名照搬 golden）、
     可读核 u_core 的例化、顶层输出 assign。手写区（文件头 + xs_Backend_core）脚本不碰。
  2. verif/ut/Backend/fm_pins_pre.tcl —— 只有 Backend 本层的「顶层胶合寄存器」钉点：golden 本层**每一个**寄存器
     （firtool 展平名 inner_*）逐位 set_user_match 到 u_core 里的对应寄存器位（codex 0226 的 green_child 组合：
     子模块两侧 -interface_only，不碰 child 内部，也不读任何诊断 matched.rpt）。

★fail-closed（对照 golden 现读，任何一条不满足就非零退出、不写文件）★
  1. 端口：golden Backend 的每个端口按原序原宽原方向出现。
  2. 例化：golden 的 46 个实例逐个照搬模块名与实例名；每个端口连接的 golden 表达式必须落进下面已知形状之一：
       a. 纯连线形状（wire_shape）：顶层端口 / `_inner_<实例>_<端口>`（子模块输出线，改名 `<别名>_<端口去 io_>`，
          驱动方必须恰是那个实例的那个输出口）/ 常量 / 上述之一的位截取 `x[h:l]`、`x[i]` / 高位补零 `{N'h0, x}` /
          golden 具名线（`wire a = <纯连线形状>;`，如 inner_cg_cgen = io_dft_cgen）；
       b. golden 本层寄存器 → u_core 的对应输出口元素（REG_TO_CORE，见 core_reg_map）；
       c. 其余（有运算的胶合表达式）→ 按 (实例, 端口) 查 CORE_EXPR_RULES 得 u_core 输出口元素，且 golden 表达式
          必须匹配规则里给的形状正则（例如 wbPregs*_valid 必须正是 `wen & xWen`）；
       d. 输出悬空 → 空连接。
     落不进任何一类 = 报错；u_core 输出口被引用的下标与位宽逐个和核端口表比对。
  3. 顶层输出：golden 的每条 assign 的左边必须是顶层输出；右边是纯连线形状，或 CORE_TOP 里列出的、由 u_core 同名
     输出口直接驱动的口；每个顶层输出恰有一个驱动（子模块输出口直连 / assign / u_core）。
  4. u_core 的输入：与顶层端口或子模块输出线**同名同宽**的标量口直接相连；其余（打包数组口）必须在 CORE_IN 里
     逐元素给出 golden 来源（每个元素必须是纯连线形状或常量 0 —— 常量 0 只许给 golden 里确实不存在的字段，
     生成器逐个核对该子模块端口不存在），总宽与核端口宽相等。核的每个口都必须被用上。
  5. 分组注释：实例之间每一对"谁连谁"都必须在 PAIR_DESC 里有一句说明（按实例族归一，新出现的连接对 = 报错）；
     顶层端口按 TOP_GROUPS 前缀归组，未归组的端口 = 报错。
  6. 钉点：golden 本层 420 个寄存器必须全部在 core_reg_map 里有对端（漏一个、多一个都报错），位宽逐个相等；
     钉点总数写成字面常数，运行时逐条数返回值，拒一条或总数不符即 error。

用法：python3 scripts/gen_backend.py [--check]
"""
import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'backend' / 'Backend.sv'
PINS = REPO / 'verif' / 'ut' / 'Backend' / 'fm_pins_pre.tcl'
BEGIN = '// BEGIN GENERATED(be_wrapper)'
END = '// END GENERATED'


def fail(msg):
    sys.stderr.write('gen_backend: FAIL: %s\n' % msg)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 实例别名与分节（wrapper 里按这个顺序出现）
# ---------------------------------------------------------------------------
def _pipe_list():
    out = []
    for k in range(8):
        out.append(('inner_bypassNetwork2intExuBlock' + ('_%d' % k if k else ''), 'toIntExu%d' % k))
    for k in range(5):
        out.append(('inner_bypassNetwork2fpExuBlock' + ('_%d' % k if k else ''), 'toFpExu%d' % k))
    for k in range(5):
        out.append(('inner_bypassNetwork2vfExuBlock' + ('_%d' % k if k else ''), 'toVfExu%d' % k))
    for k in range(9):
        out.append(('inner_bypassNetwork2toMemExus' + ('_%d' % k if k else ''), 'toMem%d' % k))
    return out


PIPES = _pipe_list()                     # 序号 = xs_Backend_core 的 pipe_* 下标
PIPE_INDEX = {inst: p for p, (inst, _) in enumerate(PIPES)}
VLDU_PIPES = (23, 24)                    # toMem5 / toMem6
LDA_PIPES = (20, 21, 22)                 # toMem2..4

SECTIONS = [
    ('§A 控制块：译码 / 重命名 / 派遣 / ROB（CtrlBlock）', [('inner_ctrlBlock', 'ctrlBlock')]),
    ('§B 四个调度器（发射队列 + 唤醒）与写回端口占用表', [
        ('inner_intScheduler', 'intScheduler'), ('inner_fpScheduler', 'fpScheduler'),
        ('inner_vfScheduler', 'vfScheduler'), ('inner_memScheduler', 'memScheduler'),
        ('inner_wbFuBusyTable', 'wbFuBusyTable')]),
    ('§C 读寄存器与旁路：DataPath（寄存器堆 + 读口仲裁）、向量 OG2 级、BypassNetwork', [
        ('inner_dataPath', 'dataPath'), ('inner_og2ForVector', 'og2ForVector'),
        ('inner_bypassNetwork', 'bypassNetwork'),
        ('inner_dataPath_io_topDownInfo_replayAllocate_delay', 'replayAllocateDelay'),
        ('inner_dataPath_io_topDownInfo_sqFull_delay', 'sqFullDelay'),
        ('inner_dataPath_io_topDownInfo_sbFull_delay', 'sbFullDelay')]),
    ('§D 发射流水寄存器（旁路网络 → 执行块 / MemBlock，NewPipelineConnect，27 个）', PIPES),
    ('§E 三个执行块（int 含 CSR/跳转/乘除，fp，vf）', [
        ('inner_intExuBlock', 'intExuBlock'), ('inner_fpExuBlock', 'fpExuBlock'),
        ('inner_vfExuBlock', 'vfExuBlock')]),
    ('§F 写回：WbDataPath（写回仲裁 → 寄存器堆 / ROB / 调度器）与向量异常的旧值合并', [
        ('inner_wbDataPath', 'wbDataPath'), ('inner_vecExcpMod', 'vecExcpMod')]),
    ('§G 性能事件：PFEvent（CSR 选择）+ HPerfMonitor（汇成 8 路）', [
        ('inner_pfevent', 'pfevent'), ('inner_perfEvents_hpm', 'perfHpm')]),
]
ALIAS = collections.OrderedDict((i, a) for _, lst in SECTIONS for i, a in lst)


def fam(alias):
    """连接对说明按实例族归一（27 个流水寄存器四族各一句）。"""
    m = re.fullmatch(r'(toIntExu|toFpExu|toVfExu|toMem)\d+', alias)
    return m.group(1) + '*' if m else alias


# ---------------------------------------------------------------------------
# 顶层端口分组（最长前缀命中）
# ---------------------------------------------------------------------------
TOP_GROUPS = [
    ('clock', '时钟'), ('reset', '复位'),
    ('io_fromTop', 'SoC 顶层输入（核号、外部中断、MSI、CLINT 时间、L2 刷新完成）'),
    ('io_toTop', '送 SoC 顶层（停机、关键错误）'),
    ('io_traceCoreInterface', '处理器踪迹接口'),
    ('io_fenceio', 'fence 输出'),
    ('io_frontend', '与前端：指令输入 / 重定向 / 提交 / PC 存储'),
    ('io_frontendSfence', '送前端的 sfence'),
    ('io_frontendCsrCtrl', '送前端的自定义 CSR 控制'),
    ('io_frontendTlbCsr', '送前端的 TLB CSR'),
    ('io_mem', '与 MemBlock：发射 / 写回 / LSQ / 异常 / CSR'),
    ('io_tlb', 'TLB CSR'),
    ('io_csrCustomCtrl', '自定义 CSR 控制'),
    ('io_perf', '性能事件'),
    ('io_debugTopDown', 'TopDown 调试'),
    ('io_topDownInfo', 'TopDown 信息'),
    ('io_debugRolling', '滚动性能调试'),
    ('io_dft', 'DFT 广播（SRAM 测试控制）'),
    ('gatewayIn_packed', 'MBIST 网关穿线'),
]

# 实例之间"谁连谁"的说明（无序对，按 fam() 归一）。新出现的连接对必须在这里补一句，否则生成器报错。
PAIR_DESC = {}   # 填充见文件尾 _PAIR_DESC_TEXT（太长，放在后面）


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')


def golden_ports(mod):
    t = (G1 / ('%s.sv' % mod)).read_text(errors='replace')
    m = re.search(r'^module %s\(\n(.*?)\n\);' % re.escape(mod), t, re.M | re.S)
    if not m:
        fail('golden %s 端口表解析失败' % mod)
    out = []
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if not pm:
            fail('golden %s 端口行形状未知: %r' % (mod, ln))
        out.append((pm.group(1), int(pm.group(2) or 0) + 1, pm.group(3)))
    return out


def golden_body():
    t = (G1 / 'Backend.sv').read_text(errors='replace')
    start = re.search(r'^module Backend\(', t, re.M).start()
    body = t[start:]
    body = body[:body.index('\nendmodule')]
    code = body[body.index('\n);') + 3:]
    code = re.sub(r'`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS', '', code, flags=re.S)
    code = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_', '', code, flags=re.S)
    return code


def parse_golden():
    code = golden_body()
    insts = collections.OrderedDict()
    for m in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)\n  \);', code, re.M | re.S):
        conns = []
        for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?=,\n|\Z)', m.group(3), re.S):
            conns.append((c.group(1), ' '.join(c.group(2).split())))
        insts[m.group(2)] = (m.group(1), conns)
    assigns = [(m.group(1), ' '.join(m.group(2).split()))
               for m in re.finditer(r'^  assign (\w+) =\s*(.*?);', code, re.M | re.S)]
    wires = collections.OrderedDict(
        (m.group(1), ' '.join(m.group(2).split()))
        for m in re.finditer(r'^  wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=\s*(.*?);', code, re.M | re.S))
    regs = collections.OrderedDict(
        (m.group(2), int(m.group(1) or 0) + 1)
        for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', code, re.M))
    # 寄存器的 D 端（只认 `<reg> <= <单一名字>;` 的 RegNext / RegEnable 形状，用来追唤醒寄存器的来源）
    reg_src = {}
    for m in re.finditer(r'^\s+(inner_\w+) <=\s*(\w+);', code, re.M):
        reg_src.setdefault(m.group(1), m.group(2))
    return golden_ports('Backend'), insts, assigns, wires, regs, reg_src


# ---------------------------------------------------------------------------
# 核端口表
# ---------------------------------------------------------------------------
def parse_core():
    t = OUT.read_text()
    m = re.search(r'^module xs_Backend_core \(\n(.*?)\n\);', t, re.M | re.S)
    if not m:
        fail('rtl/backend/Backend.sv 里找不到手写核 xs_Backend_core 的端口表')
    ports = collections.OrderedDict()
    for ln in m.group(1).splitlines():
        s = ln.strip()
        if not s or s.startswith('//'):
            continue
        pm = re.match(r'(input|output)\s+logic\s+((?:\[\d+:0\])*)\s*(\w+),?$', s)
        if not pm:
            fail('核端口行形状未知: %r' % ln)
        dims = [int(x) + 1 for x in re.findall(r'\[(\d+):0\]', pm.group(2))]
        ports[pm.group(3)] = (pm.group(1), dims)
    return ports


def dims_width(dims):
    out = 1
    for d in dims:
        out *= d
    return out


# ---------------------------------------------------------------------------
# golden 本层寄存器 → u_core 输出口元素
# ---------------------------------------------------------------------------
WB_FAMILIES = [  # (golden 前缀, 核前缀, golden xWen 名, 写回口个数)
    ('int', 'wbInt', 'intWen', 8), ('fp', 'wbFp', 'fpWen', 6), ('vf', 'wbVf', 'vecWen', 6),
    ('v0', 'wbV0', 'v0Wen', 6), ('vl', 'wbVl', 'vlWen', 4)]
WAKEUP_FAMILIES = {'intScheduler': 'intWakeup', 'fpScheduler': 'fpWakeup', 'memScheduler': 'memWakeup'}

SIMPLE_REG_TO_CORE = {
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_mtip': 'csrIn_mtip',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_msip': 'csrIn_msip',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_meip': 'csrIn_meip',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_seip': 'csrIn_seip',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_debug': 'csrIn_debug',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_nmi_nmi_31': 'csrIn_nmi31',
    'inner_intExuBlock_io_csrio_externalInterrupt_REG_nmi_nmi_43': 'csrIn_nmi43',
    'inner_intExuBlock_io_csrin_msiInfo_valid_REG': 'csrIn_msiValid',
    'inner_intExuBlock_io_csrin_msiInfo_bits_r': 'csrIn_msiBits',
    'inner_intExuBlock_io_csrin_clintTime_valid_REG': 'csrIn_clintTimeValid',
    'inner_intExuBlock_io_csrin_clintTime_bits_r': 'csrIn_clintTimeBits',
    'inner_intExuBlock_io_csrin_l2FlushDone_REG': 'csrIn_l2FlushDone',
    'inner_pfevent_io_distribute_csr_REG_w_valid': 'pfCsrWrite_valid',
    'inner_pfevent_io_distribute_csr_REG_w_bits_addr': 'pfCsrWrite_addr',
    'inner_pfevent_io_distribute_csr_REG_w_bits_data': 'pfCsrWrite_data',
    'inner_dataPath_io_topDownInfo_l1Miss_REG': 'topDown_l1Miss',
    'inner_vsetvlVType_illegal': 'vsetvl_illegal',
    'inner_vsetvlVType_vma': 'vsetvl_vma',
    'inner_vsetvlVType_vta': 'vsetvl_vta',
    'inner_vsetvlVType_vsew': 'vsetvl_vsew',
    'inner_vsetvlVType_vlmul': 'vsetvl_vlmul',
}
for _t in ('bare', 'sv39', 'sv39x4', 'sv48', 'sv48x4'):
    SIMPLE_REG_TO_CORE['inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_%s' % _t] = 'transType_%s' % _t
# 核内部寄存器（不是输出口）：只用于钉点
INTERNAL_REG_TO_CORE = {
    'inner_debugVl_s1_REG': 'debugVl_s1',
    'inner_issueTimeout_c_value': 'vldu_timeoutCnt[0]',
    'inner_issueTimeout_c_value_1': 'vldu_timeoutCnt[1]',
}


def wakeup_field_to_core(field):
    """唤醒字段名（去掉 wakeupVec_<c>_ 之后）→ (核端口后缀, 子下标列表)。"""
    m = re.fullmatch(r'valid', field)
    if m:
        return 'valid', []
    m = re.fullmatch(r'bits_(rfWen|fpWen|vecWen|v0Wen|vlWen|pdest|is0Lat|rcDest)', field)
    if m:
        return m.group(1), []
    m = re.fullmatch(r'bits_loadDependency_(\d)', field)
    if m:
        return 'loadDependency', [int(m.group(1))]
    m = re.fullmatch(r'bits_(pdestCopy|rfWenCopy|fpWenCopy)_(\d)', field)
    if m:
        return m.group(1), [int(m.group(2))]
    m = re.fullmatch(r'bits_loadDependencyCopy_(\d)_(\d)', field)
    if m:
        return 'loadDependencyCopy', [int(m.group(1)), int(m.group(2))]
    return None


def core_reg_map(regs, reg_src):
    """golden 本层寄存器 → (u_core 元素表达式, 是否核输出口)。漏一个 = 报错。"""
    out = collections.OrderedDict()
    for r in regs:
        if r in SIMPLE_REG_TO_CORE:
            out[r] = (SIMPLE_REG_TO_CORE[r], True)
            continue
        if r in INTERNAL_REG_TO_CORE:
            out[r] = (INTERNAL_REG_TO_CORE[r], False)
            continue
        m = re.fullmatch(r'inner_(int|fp|vf|v0|vl)WriteBackDelayed_(\d+)_(wen_REG|\w+Wen_REG|addr_r)', r)
        if m:
            gf, k, f = m.group(1), int(m.group(2)), m.group(3)
            pre, xw = [(c, x) for g, c, x, _ in WB_FAMILIES if g == gf][0]
            fld = 'wen' if f == 'wen_REG' else ('addr' if f == 'addr_r' else f[:-4])
            if fld not in ('wen', 'addr', xw):
                fail('写回延迟寄存器 %s 的字段 %s 不认识' % (r, fld))
            out[r] = ('%sDly_%s[%d]' % (pre, fld, k), True)
            continue
        if r.startswith('inner_iqWakeUpMappedBundleDelayed_delayed_REG'):
            s = reg_src.get(r)
            sm = re.fullmatch(r'_inner_(\w+?)_io_toSchedulers_wakeupVec_(\d+)_(\w+)', s or '')
            if not sm or sm.group(1) not in WAKEUP_FAMILIES:
                fail('唤醒延迟寄存器 %s 的来源 %r 不是调度器的 toSchedulers.wakeupVec' % (r, s))
            wf = wakeup_field_to_core(sm.group(3))
            if wf is None:
                fail('唤醒字段 %s 不认识' % sm.group(3))
            base, sub = wf
            idx = ''.join('[%d]' % i for i in [int(sm.group(2))] + sub)
            out[r] = ('%sDly_%s%s' % (WAKEUP_FAMILIES[sm.group(1)], base, idx), True)
            continue
        fail('golden 本层寄存器 %s 没有对应的核寄存器（补 core_reg_map）' % r)
    return out


# ---------------------------------------------------------------------------
# 有运算的胶合表达式：(实例, 端口) → (核输出元素, golden 表达式形状正则)
# ---------------------------------------------------------------------------
N = r'[\w\[\]:]+'


def core_expr_rules():
    R = {}
    for g, pre, xw, n in WB_FAMILIES:
        dn = {'int': 'Int', 'fp': 'Fp', 'vf': 'Vec', 'v0': 'V0', 'vl': 'Vl'}[g]
        pn = {'int': 'Int', 'fp': 'Fp', 'vf': 'Vf', 'v0': 'V0', 'vl': 'Vl'}[g]
        for k in range(n):
            R[('inner_ctrlBlock', 'io_toDispatch_wbPregs%s_%d_valid' % (dn, k))] = (
                'wbPregs%s_valid[%d]' % (dn, k),
                r'_inner_wbDataPath_io_to%sPreg_%d_wen & _inner_wbDataPath_io_to%sPreg_%d_%s' % (pn, k, pn, k, xw))
    R[('inner_ctrlBlock', 'io_robio_robHeadLsIssue')] = ('robHeadLsIssue', r'io_mem_issueSta_0_ready & .*robHeadLsIssue_T_2')
    R[('inner_intExuBlock', 'io_csrin_criticalErrorState')] = (
        'criticalErrorState', r'_inner_ctrlBlock_io_error_0 \| _inner_intExuBlock_io_error_0')
    R[('inner_intExuBlock', 'io_csrio_vpu_set_vtype_bits')] = (
        'csrVpu_setVtypeBits', r"\{_inner_ctrlBlock_io_robio_commitVType_hasVsetvl \? inner_vsetvlVType_illegal : .*\}")
    R[('inner_intExuBlock', 'io_csrio_vpu_vl')] = ('csrVpu_vl', r"\{56'h0, inner_debugVl_s1_REG\}")
    R[('inner_bypassNetwork', 'io_fromExus_mem_2_0_bits_intWen')] = (
        'ldaWb0_intWen', r'io_mem_writebackLda_0_bits_uop_rfWen & io_mem_writebackLda_0_bits_isFromLoadUnit')
    for v, w in ((0, 5), (1, 6)):
        for f in ('isIndexed', 'isMasked', 'isStrided', 'isWhole', 'isVecLoad', 'isVlm'):
            R[('inner_wbDataPath', 'io_fromMemExu_%d_0_bits_vls_%s' % (w, f))] = (
                'vlduWb_%s[%d]' % (f, v), r'.*io_mem_writebackVldu_%d_bits_uop_fuOpType\[.*' % v)
        R[('inner_memScheduler', 'io_vecLoadFinalIssueResp_%d_0_valid' % w)] = (
            'vldu_finalIssueRespValid[%d]' % v, r'inner_issueTimeout%s \| inner__%d' % ('' if v == 0 else '_1', 1 + 3 * v))
        R[('inner_memScheduler', 'io_vecLoadIssueResp_%d_0_valid' % w)] = (
            'vldu_issueRespValid[%d]' % v,
            r"inner__%d & _inner_bypassNetwork2toMemExus_%d_io_out_bits_fuOpType\[8:7\] == 2'h1" % (3 * v, w))
    for p, (inst, _) in enumerate(PIPES):
        R[(inst, 'io_rightOutFire')] = ('pipe_rightOutFire[%d]' % p, r'.*')
        R[(inst, 'io_isFlush')] = ('pipe_isFlush[%d]' % p, r'.*\? _inner_ctrlBlock_io_toExuBlock_flush_valid & .*')
    for v, p in enumerate(VLDU_PIPES):
        R[(PIPES[p][0], 'io_isOlder')] = ('vldu_isOlder[%d]' % v, r'inner__%d' % (1 + 3 * v))
    return R


# rightOutFire 的 golden 形状：<dst ready> & _inner_<pipe>_io_out_valid（Vldu 口经具名线 inner__0 / inner__3）
# 顶层输出里由 u_core 同名输出口直接驱动的（有加法 / 移位）
CORE_TOP = {
    'io_mem_issueLda_0_bits_uop_pc', 'io_mem_issueLda_1_bits_uop_pc', 'io_mem_issueLda_2_bits_uop_pc',
    'io_mem_issueVldu_0_bits_uop_pc', 'io_mem_issueVldu_1_bits_uop_pc',
}


# ---------------------------------------------------------------------------
# 核的打包数组输入：逐元素给出 golden 来源（元素序 = 下标 0 起；每个元素是叶子位宽的一根线或常量 0）
# ---------------------------------------------------------------------------
def core_in_spec(cports):
    S = collections.OrderedDict()
    for g, pre, xw, n in WB_FAMILIES:
        pn = {'int': 'Int', 'fp': 'Fp', 'vf': 'Vf', 'v0': 'V0', 'vl': 'Vl'}[g]
        for f in ('wen', xw, 'addr'):
            S['%s_%s' % (pre, f)] = ['_inner_wbDataPath_io_to%sPreg_%d_%s' % (pn, k, f) for k in range(n)]
    # 唤醒：按核端口的维数逐元素展开，golden 来源 _inner_<sched>_io_toSchedulers_wakeupVec_<c>_<field>
    rev = {v: k for k, v in WAKEUP_FAMILIES.items()}
    for name, (d, dims) in cports.items():
        m = re.fullmatch(r'(intWakeup|fpWakeup|memWakeup)_(\w+)', name)
        if not m or d != 'input':
            continue
        sched, base = rev[m.group(1)], m.group(2)
        S[name] = _wakeup_elems(sched, base, dims)
    ld = {}
    for p, (inst, _) in enumerate(PIPES):
        S.setdefault('pipe_srcValid', []).append('@in_valid:%s' % inst)
        S.setdefault('pipe_srcRobIdx', []).append('@src:%s:robIdx' % inst)
        S.setdefault('pipe_srcLdDep', []).append('@src:%s:loadDependency' % inst)
        S.setdefault('pipe_inReady', []).append('_inner_%s_io_in_ready' % inst[len('inner_'):])
        S.setdefault('pipe_outValid', []).append('_inner_%s_io_out_valid' % inst[len('inner_'):])
        S.setdefault('pipe_outRobIdx', []).append('{_inner_%s_io_out_bits_robIdx_flag, _inner_%s_io_out_bits_robIdx_value}'
                                                  % (inst[6:], inst[6:]))
        S.setdefault('pipe_outReady', []).append('@out_ready:%s' % inst)
    for v, p in enumerate(VLDU_PIPES):
        i = PIPES[p][0][6:]
        S.setdefault('vldu_srcLqIdx', []).append('@src:%s:lqIdx' % PIPES[p][0])
        S.setdefault('vldu_srcSqIdx', []).append('@src:%s:sqIdx' % PIPES[p][0])
        S.setdefault('vldu_outLqIdx', []).append('{_inner_%s_io_out_bits_lqIdx_flag, _inner_%s_io_out_bits_lqIdx_value}' % (i, i))
        S.setdefault('vldu_outSqIdx', []).append('{_inner_%s_io_out_bits_sqIdx_flag, _inner_%s_io_out_bits_sqIdx_value}' % (i, i))
        S.setdefault('vldu_outFuOpTypeHi', []).append('_inner_%s_io_out_bits_fuOpType[8:7]' % i)
        S.setdefault('vldu_outFtqOffset', []).append('_inner_%s_io_out_bits_ftqOffset' % i)
        S.setdefault('vlduWb_fuOpType', []).append('io_mem_writebackVldu_%d_bits_uop_fuOpType' % v)
    for p in LDA_PIPES:
        i = PIPES[p][0][6:]
        S.setdefault('lda_outPc', []).append('_inner_%s_io_out_bits_pc' % i)
        S.setdefault('lda_outFtqOffset', []).append('_inner_%s_io_out_bits_ftqOffset' % i)
    return S


def _wakeup_elems(sched, base, dims):
    """唤醒核端口的元素列表（下标 0 起的行优先展开到叶子）。"""
    def field(c, sub):
        if base == 'valid':
            return 'valid'
        if base in ('rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen', 'pdest', 'is0Lat', 'rcDest'):
            return 'bits_' + base
        if base == 'loadDependency':
            return 'bits_loadDependency_%d' % sub[0]
        if base in ('pdestCopy', 'rfWenCopy', 'fpWenCopy'):
            return 'bits_%s_%d' % (base, sub[0])
        if base == 'loadDependencyCopy':
            return 'bits_loadDependencyCopy_%d_%d' % (sub[0], sub[1])
        fail('唤醒核端口字段 %s 不认识' % base)
    # 叶子维：pdest/rcDest/loadDependency* 的最内维是位宽，其余是 1 位
    leafw = {'pdest': 1, 'rcDest': 1, 'loadDependency': 1, 'pdestCopy': 1, 'loadDependencyCopy': 1}
    nidx = len(dims) - (1 if base in leafw else 0)
    if base not in leafw and len(dims) == 1:
        nidx = 1
    outer = dims[:nidx]
    out = []
    for flat in range(dims_width(outer)):
        idx, r = [], flat
        for d in reversed(outer):
            idx.insert(0, r % d)
            r //= d
        out.append('_inner_%s_io_toSchedulers_wakeupVec_%d_%s' % (sched, idx[0], field(idx[0], idx[1:])))
    return out


# ---------------------------------------------------------------------------
# 构建
# ---------------------------------------------------------------------------
def strip_io(p):
    return p[3:] if p.startswith('io_') else p


def top_group(name):
    best = None
    for pfx, desc in TOP_GROUPS:
        if name == pfx or name.startswith(pfx + '_'):
            if best is None or len(pfx) > len(best[0]):
                best = (pfx, desc)
    if best is None:
        fail('顶层端口 %s 没有归组（补 TOP_GROUPS）' % name)
    return best


class Ctx:
    pass


def build():
    tports, insts, assigns, wires, regs, reg_src = parse_golden()
    C = Ctx()
    C.tports = tports
    tdir = {n: d for d, w, n in tports}
    twid = {n: w for d, w, n in tports}
    if set(insts) != set(ALIAS):
        fail('golden 实例集合与 ALIAS 不一致: 多 %s 少 %s' % (sorted(set(insts) - set(ALIAS))[:5],
                                                         sorted(set(ALIAS) - set(insts))[:5]))
    cports = {}
    for inst, (mod, conns) in insts.items():
        cports[inst] = {n: (d, w) for d, w, n in golden_ports(mod)}
        if sorted(p for p, _ in conns) != sorted(cports[inst]):
            fail('%s(%s) 的连接端口集合与模块端口表不一致' % (inst, mod))
    core = parse_core()

    # ---- 1. 子模块输出线 ----
    child_net = {}        # golden 名 -> (新名, 驱动实例, 端口, 宽)
    for inst, (mod, conns) in insts.items():
        for p, e in conns:
            d, w = cports[inst][p]
            if d == 'output' and e.startswith('_inner_'):
                if e != '_%s_%s' % (inst, p):
                    fail('%s.%s 驱动的线名 %s 不是预期的 _%s_%s' % (inst, p, e, inst, p))
                child_net[e] = ('%s_%s' % (ALIAS[inst], strip_io(p)), inst, p, w)
    newnames = [v[0] for v in child_net.values()]
    dup = [n for n, c in collections.Counter(newnames).items() if c > 1]
    if dup:
        fail('改名后线名冲突: %s' % dup[:5])
    if set(newnames) & set(tdir):
        fail('改名后线名与顶层端口冲突: %s' % sorted(set(newnames) & set(tdir))[:5])
    if set(newnames) & set(core):
        # 核标量输入同名同宽直连子模块输出线 —— 这是允许的（见 6.）
        pass

    consumers = collections.defaultdict(list)     # 新线名 -> [别名 / 'core' / 'top']

    def width_of_shape(kind, val):
        return val[1]

    # 纯连线形状 → (渲染文本, 宽, 引用到的新线名列表)；不是纯连线返回 None
    def wire_shape(e, depth=0):
        e = e.strip()
        if e in tdir:
            return e, twid[e], []
        if e in child_net:
            n = child_net[e]
            return n[0], n[3], [n[0]]
        m = re.fullmatch(r"(\d+)'h([0-9A-F]+)", e)
        if m:
            return e, int(m.group(1)), []
        m = re.fullmatch(r'(\w+)\[(\d+)(?::(\d+))?\]', e)
        if m:
            b = wire_shape(m.group(1), depth + 1)
            if b is None:
                return None
            hi, lo = int(m.group(2)), int(m.group(3) if m.group(3) is not None else m.group(2))
            if hi >= b[1] or lo > hi:
                fail('位截取 %s 越界（宽 %d）' % (e, b[1]))
            return '%s[%s]' % (b[0], m.group(2) if m.group(3) is None else '%d:%d' % (hi, lo)), hi - lo + 1, b[2]
        m = re.fullmatch(r"\{(\d+)'h0, (\w+)\}", e)
        if m:
            b = wire_shape(m.group(2), depth + 1)
            if b is None:
                return None
            return "{%s'h0, %s}" % (m.group(1), b[0]), int(m.group(1)) + b[1], b[2]
        if e in wires and depth < 4:
            return wire_shape(wires[e], depth + 1)
        return None

    regmap = core_reg_map(regs, reg_src)
    rules = core_expr_rules()

    def core_elem(expr):
        """'name[i][j]' → (核端口名, 下标列表, 叶宽)；与核端口表比对。"""
        m = re.fullmatch(r'(\w+)((?:\[\d+\])*)', expr)
        name, idx = m.group(1), [int(x) for x in re.findall(r'\[(\d+)\]', m.group(2))]
        if name not in core:
            fail('u_core 没有端口 %s（%s）' % (name, expr))
        d, dims = core[name]
        if len(idx) > len(dims) or any(i >= n for i, n in zip(idx, dims)):
            fail('u_core.%s%s 下标越界（维 %s）' % (name, ''.join('[%d]' % i for i in idx), dims))
        return name, d, idx, dims_width(dims[len(idx):]) if dims[len(idx):] else 1

    # ---- 2. 逐实例逐端口分类 ----
    rendered = collections.OrderedDict()
    used_rules = set()
    used_core_out = set()
    for inst, (mod, conns) in insts.items():
        rows = []
        for p, e in conns:
            d, w = cports[inst][p]
            if e in ('', '/* unused */'):
                if d != 'output':
                    fail('%s.%s 是输入却悬空' % (inst, p))
                rows.append((p, '', d, ('unused', None)))
                continue
            if d == 'output':
                if e in tdir:
                    if tdir[e] != 'output' or twid[e] != w:
                        fail('%s.%s 直接驱动顶层 %s 但方向/宽不符' % (inst, p, e))
                    rows.append((p, e, d, ('top', top_group(e))))
                elif e in child_net:
                    rows.append((p, child_net[e][0], d, ('drv', None)))
                else:
                    fail('%s.%s 输出连到未知表达式 %r' % (inst, p, e))
                continue
            sh = wire_shape(e)
            if sh is not None:
                text, sw, refs = sh
                if sw != w:
                    fail('%s.%s 宽 %d 与连线 %s 宽 %d 不符' % (inst, p, w, text, sw))
                for n in refs:
                    consumers[n].append(ALIAS[inst])
                if refs:
                    src_inst = [child_net[k][1] for k in child_net if child_net[k][0] == refs[0]][0]
                    rows.append((p, text, d, ('inst', ALIAS[src_inst])))
                elif re.fullmatch(r"\d+'h[0-9A-F]+", text):
                    rows.append((p, text, d, ('const', None)))
                else:
                    top = re.match(r"(?:\{\d+'h0, )?(\w+)", text).group(1)
                    rows.append((p, text, d, ('top', top_group(top))))
                continue
            if e in regmap:
                ce, is_out = regmap[e]
                if not is_out:
                    fail('%s.%s 连到核内部寄存器 %s（应是核输出口）' % (inst, p, e))
                key = None
            elif (inst, p) in rules:
                ce, pat = rules[(inst, p)]
                if not re.fullmatch(pat, e):
                    fail('%s.%s 的 golden 表达式与规则形状不符: %r' % (inst, p, e[:200]))
                used_rules.add((inst, p))
            else:
                fail('%s.%s 的 golden 连接表达式未归类: %r' % (inst, p, e[:200]))
            name, cd, idx, cw = core_elem(ce)
            if cd != 'output':
                fail('u_core.%s 不是输出口' % name)
            if cw != w:
                fail('u_core.%s 叶宽 %d 与 %s.%s 宽 %d 不符' % (ce, cw, inst, p, w))
            used_core_out.add(name)
            rows.append((p, ce, d, ('core', None)))
        rendered[inst] = (mod, rows)
    if set(rules) - used_rules:
        fail('CORE_EXPR_RULES 有规则没用上: %s' % sorted(set(rules) - used_rules)[:5])

    # ---- 3. 顶层输出 ----
    top_assign = collections.OrderedDict()
    for lhs, rhs in assigns:
        if tdir.get(lhs) != 'output':
            fail('golden assign 的左边 %s 不是顶层输出' % lhs)
        if lhs in CORE_TOP:
            name, cd, idx, cw = core_elem(lhs)
            if cd != 'output' or idx or cw != twid[lhs]:
                fail('顶层输出 %s 应由核同名同宽输出口驱动' % lhs)
            used_core_out.add(lhs)
            top_assign[lhs] = None
            continue
        sh = wire_shape(rhs)
        if sh is None:
            fail('顶层输出 %s 的 golden 驱动 %r 未归类（不是纯连线，也不在 CORE_TOP）' % (lhs, rhs[:200]))
        if sh[1] != twid[lhs]:
            fail('assign %s 宽不符' % lhs)
        for n in sh[2]:
            consumers[n].append('top')
        top_assign[lhs] = sh[0]
    if CORE_TOP - set(top_assign):
        fail('CORE_TOP 里有顶层输出 golden 没有 assign: %s' % sorted(CORE_TOP - set(top_assign)))
    driven_by_inst = collections.Counter(e for _, (_, rows) in rendered.items() for p, e, d, k in rows
                                         if d == 'output' and k[0] == 'top')
    for d, w, n in tports:
        if d == 'output':
            cnt = driven_by_inst[n] + (1 if n in top_assign else 0)
            if cnt != 1:
                fail('顶层输出 %s 的驱动个数 %d（应为 1）' % (n, cnt))

    # ---- 4. u_core 输入 ----
    spec = core_in_spec(core)
    netw = {v[0]: v[3] for v in child_net.values()}
    core_conn = []
    for name, (d, dims) in core.items():
        w = dims_width(dims)
        if d == 'output':
            if name not in used_core_out:
                fail('核输出 %s 没有被任何子模块 / 顶层用到' % name)
            core_conn.append((d, dims, name, name))
            continue
        if name in ('clock', 'reset'):
            core_conn.append((d, dims, name, name))
            continue
        if name in spec:
            elems = spec.pop(name)
            texts, total = [], 0
            leafw = None
            for el in elems:
                t, ew = resolve_in_elem(el, insts, cports, child_net, wire_shape, consumers)
                if leafw is None:
                    leafw = ew
                elif leafw != ew:
                    fail('核输入 %s 的元素宽不一（%d / %d）' % (name, leafw, ew))
                texts.append(t)
                total += ew
            if total != w:
                fail('核输入 %s 宽 %d，CORE_IN 给了 %d' % (name, w, total))
            core_conn.append((d, dims, name, '{' + ', '.join(reversed(texts)) + '}'))
            continue
        if name in tdir:
            if tdir[name] != 'input' or twid[name] != w:
                fail('核输入 %s 与同名顶层端口方向/宽不符' % name)
            core_conn.append((d, dims, name, name))
            continue
        if name in netw:
            if netw[name] != w:
                fail('核输入 %s 宽 %d 与同名子模块输出线宽 %d 不符' % (name, w, netw[name]))
            consumers[name].append('core')
            core_conn.append((d, dims, name, name))
            continue
        fail('核输入 %s 对不上顶层端口 / 子模块输出线 / CORE_IN' % name)
    if spec:
        fail('CORE_IN 里有核没有的端口: %s' % sorted(spec)[:5])

    # ---- 5. 连接对说明齐全 ----
    need = set()
    for inst, (mod, rows) in rendered.items():
        a = ALIAS[inst]
        for p, e, d, k in rows:
            if k[0] == 'inst':
                need.add((fam(a), fam(k[1])))
            elif k[0] == 'core':
                need.add((fam(a), 'core'))
            elif k[0] == 'drv':
                for c in consumers.get(e, []):
                    if c != 'top':
                        need.add((fam(a), fam(c)))
    miss = sorted({tuple(sorted(x)) for x in need if pair_desc(*x) is None})
    if miss:
        fail('PAIR_DESC 缺这些连接对的说明: %s' % miss)

    C.rendered, C.child_net, C.consumers, C.core_conn, C.top_assign = rendered, child_net, consumers, core_conn, top_assign
    C.core, C.regs, C.regmap = core, regs, regmap
    return C


def resolve_in_elem(el, insts, cports, child_net, wire_shape, consumers):
    """CORE_IN 元素 → (渲染文本, 宽)。'@...' 是按 golden 连接现查的间接元素。"""
    m = re.fullmatch(r'@in_valid:(\w+)', el)
    if m:
        el = dict(insts[m.group(1)][1])['io_in_valid']
    m = re.fullmatch(r'@out_ready:(\w+)', el)
    if m:
        el = dict(insts[m.group(1)][1])['io_out_ready']
    m = re.fullmatch(r'@src:(\w+):(robIdx|loadDependency|lqIdx|sqIdx)', el)
    if m:
        inst, what = m.group(1), m.group(2)
        v = dict(insts[inst][1])['io_in_valid']
        sm = re.fullmatch(r'_inner_bypassNetwork_io_(toExus_\w+?_\d+_\d+)_valid', v)
        if not sm:
            fail('%s.io_in_valid 的来源 %r 不是旁路网络出口' % (inst, v))
        src = 'io_' + sm.group(1)
        bp = cports['inner_bypassNetwork']
        if what == 'loadDependency':
            names = ['%s_bits_loadDependency_%d' % (src, j) for j in range(3)]
            have = [n in bp for n in names]
            if not any(have):
                # 这一族没有 loadDependency（fp / vf / Vldu）：golden 的 isFlush 里也没有 ld2Cancel 项
                isf = dict(insts[inst][1])['io_isFlush']
                if 'ld2Cancel' in isf:
                    fail('%s 的旁路出口没有 loadDependency，但 golden isFlush 里有 ld2Cancel' % inst)
                return "6'h0", 6
            if not all(have):
                fail('%s 的 loadDependency 口不全' % src)
            parts = [wire_shape('_inner_bypassNetwork_%s' % n) for n in names]
            for pt in parts:
                consumers[pt[0]].append('core')
            return '{' + ', '.join(pt[0] for pt in reversed(parts)) + '}', sum(pt[1] for pt in parts)
        el = '{_inner_bypassNetwork_%s_bits_%s_flag, _inner_bypassNetwork_%s_bits_%s_value}' % (src, what, src, what)
    m = re.fullmatch(r'\{(.*)\}', el)
    if m:
        parts = [wire_shape(x) for x in m.group(1).split(', ')]
        if any(pt is None for pt in parts):
            fail('CORE_IN 元素 %s 不是纯连线拼接' % el)
        for pt in parts:
            for n in pt[2]:
                consumers[n].append('core')
        return '{' + ', '.join(pt[0] for pt in parts) + '}', sum(pt[1] for pt in parts)
    sh = wire_shape(el)
    if sh is None:
        fail('CORE_IN 元素 %s 不是纯连线形状' % el)
    for n in sh[2]:
        consumers[n].append('core')
    return sh[0], sh[1]


def pair_desc(a, b):
    k = tuple(sorted((a, b)))
    return PAIR_DESC.get(k)


# ---------------------------------------------------------------------------
# 渲染 wrapper
# ---------------------------------------------------------------------------
def decl(dims, n):
    if not dims:
        return '  logic %s;' % n
    return '  logic %s %s;' % (''.join('[%d:0]' % (d - 1) for d in dims), n)


def render(C):
    L = []
    A = L.append
    A(BEGIN + ' —— 由 scripts/gen_backend.py 从 golden 端口表与例化表产出，勿手改')
    A('// golden 同名 wrapper：端口与 golden 逐位同名同序；子模块实例名与 golden 一致；')
    A('// 子模块之间的线一律命名为"<驱动实例别名>_<端口名去掉 io_>"。')
    A('module Backend (')
    for k, (d, w, n) in enumerate(C.tports):
        A('  %-6s logic %s%s%s' % (d, ('[%d:0] ' % (w - 1)) if w > 1 else '', n,
                                   ',' if k + 1 < len(C.tports) else ''))
    A(');')
    A('')
    A('  // ===========================================================================')
    A('  // 子模块输出线（按驱动实例分组）')
    A('  // ===========================================================================')
    by_drv = collections.OrderedDict((i, []) for i in ALIAS)
    for e, (n, di, dp, w) in C.child_net.items():
        by_drv[di].append((n, w))
    for i, nets in by_drv.items():
        if not nets:
            continue
        A('  // ---- %s（%s）----' % (ALIAS[i], i))
        for n, w in nets:
            A(decl([w] if w > 1 else [], n))
    A('  // ---- 可读核产生、送进子模块的信号 ----')
    tnames = {x[2] for x in C.tports}
    for d, dims, n, conn in C.core_conn:
        if d == 'output' and n not in tnames:
            A(decl(dims, n))
    A('')
    A('  // ===========================================================================')
    A('  // 可读核：SoC 输入打拍 / CSR 回送 / vtype / 写回 / 唤醒延迟 / 访存写回字段 / 发射流水 / 访存 uop')
    A('  // ===========================================================================')
    A('  xs_Backend_core u_core (')
    for k, (d, dims, n, conn) in enumerate(C.core_conn):
        A('    .%s (%s)%s' % (n, conn, ',' if k + 1 < len(C.core_conn) else ''))
    A('  );')
    for title, lst in SECTIONS:
        A('')
        A('  // ===========================================================================')
        A('  // %s' % title)
        A('  // ===========================================================================')
        for inst, alias in lst:
            mod, rows = C.rendered[inst]
            groups = collections.OrderedDict()
            for p, e, d, k in rows:
                if k[0] == 'top' and k[1][0] in ('clock', 'reset'):
                    key, head = ('top', 'clock/reset'), '时钟 / 复位'
                elif k[0] == 'top':
                    key = ('top', k[1][0])
                    head = '顶层 %s* —— %s' % (k[1][0], k[1][1])
                elif k[0] == 'inst':
                    key = ('inst', k[1])
                    head = '← %s：%s' % (k[1], pair_desc(fam(alias), fam(k[1])))
                elif k[0] == 'core':
                    key = ('core',)
                    head = '← u_core：%s' % pair_desc(fam(alias), 'core')
                elif k[0] == 'drv':
                    cs = list(collections.OrderedDict.fromkeys(C.consumers.get(e, [])))
                    key = ('drv', tuple(cs))
                    if not cs:
                        head = '→ 无读者（golden 同样只连到一根没人读的线）'
                    elif cs == ['top']:
                        head = '→ 顶层输出（经 assign）'
                    else:
                        parts = []
                        for c in cs:
                            parts.append('顶层输出' if c == 'top' else '%s（%s）' % (c, pair_desc(fam(alias), fam(c))))
                        head = '→ ' + '；'.join(parts)
                elif k[0] == 'const':
                    key, head = ('const',), '常量（golden 在本配置下钉死的输入）'
                else:
                    key, head = ('unused',), '无读者的输出（golden 同样悬空）'
                groups.setdefault(key, (head, []))[1].append((p, e))
            pw = max(len(p) for p, _, _, _ in rows)
            A('  %s %s (' % (mod, inst))
            flat = [(key, head, p, e) for key, (head, items) in groups.items() for p, e in items]
            last = len(flat) - 1
            prev = None
            for idx, (key, head, p, e) in enumerate(flat):
                if key != prev:
                    A('    // ---- %s ----' % head)
                    prev = key
                A('    .%-*s (%s)%s' % (pw, p, e, ',' if idx < last else ''))
            A('  );')
    A('')
    A('  // ===========================================================================')
    A('  // 顶层输出：子模块结果原样送出（io_mem_issueLda*/Vldu* 的 uop.pc 由 u_core 直接驱动）')
    A('  // ===========================================================================')
    for lhs, rhs in C.top_assign.items():
        if rhs is not None:
            A('  assign %s = %s;' % (lhs, rhs))
    A('')
    A('endmodule')
    A(END)
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# 钉点：golden 本层寄存器 → u_core 寄存器位
# ---------------------------------------------------------------------------
def core_internal_regs():
    """核内部（非端口）寄存器的声明：name -> (叶宽, 非打包维)。"""
    t = OUT.read_text()
    m = re.search(r'^module xs_Backend_core \((.*?)^endmodule', t, re.M | re.S)
    body = m.group(1)
    out = {}
    for mm in re.finditer(r'^\s*logic\s+(?:\[(\d+):0\]\s+)?(\w+)(?:\s*\[(\d+)\])?\s*;', body, re.M):
        out[mm.group(2)] = (int(mm.group(1) or 0) + 1, int(mm.group(3)) if mm.group(3) else None)
    return out


def render_pins(C):
    internal = core_internal_regs()
    pairs = []
    for gr, (ce, is_out) in C.regmap.items():
        w = C.regs[gr]
        m = re.fullmatch(r'(\w+)((?:\[\d+\])*)', ce)
        name, idx = m.group(1), [int(x) for x in re.findall(r'\[(\d+)\]', m.group(2))]
        if is_out:
            d, dims = C.core[name]
            rest = dims[len(idx):]
            cw = dims_width(rest) if rest else 1
            if len(rest) > 1:
                fail('钉点 %s：核寄存器 %s 剩余维 %s 不是向量' % (gr, ce, rest))
        else:
            if name not in internal:
                fail('u_core 里找不到内部寄存器 %s' % name)
            cw, un = internal[name]
            if (un is None) != (not idx) or (un is not None and idx[0] >= un):
                fail('内部寄存器 %s 的维与 %s 不符' % (name, ce))
        if cw != w:
            fail('寄存器 %s(宽 %d) 与 u_core.%s(宽 %d) 不符' % (gr, w, ce, cw))
        ipre = 'u_core/%s_reg%s' % (name, ''.join('[%d]' % i for i in idx))
        for b in range(w):
            rb = '' if w == 1 else '[%d]' % b
            pairs.append(('r:/WORK/Backend/%s_reg%s' % (gr, rb), 'i:/WORK/Backend/%s%s' % (ipre, rb)))
    L = []
    A = L.append
    A('# Backend FM 「匹配前」钉点 —— 自动生成：scripts/gen_backend.py（勿手改；规则与理由见生成器文件头）')
    A('# 只 set_user_match 消名差：不约束 ref、不改 appvar、不加黑盒。逐条数返回值，拒一条或总数不等于字面常数即 error。')
    A('# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。')
    A('if {$top ne "Backend"} { error "BACKEND_PRE_PIN_UNKNOWN_TOP=$top" }')
    A('# ---- 顶层胶合寄存器（golden 本层 %d 个寄存器 / %d 位 -> u_core）----' % (len(C.regmap), len(pairs)))
    A('set ::BE_CORE_EXPECT %d' % len(pairs))
    A('set ::BE_CORE_OK 0')
    A('set ::BE_CORE_BAD 0')
    A('proc be_core_pin {r i} {')
    A('  if {[set_user_match $r $i]} { incr ::BE_CORE_OK } else {')
    A('    incr ::BE_CORE_BAD')
    A('    if {$::BE_CORE_BAD <= 10} { puts "BE_CORE_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "BE_CORE_PIN_BEGIN expect=$::BE_CORE_EXPECT"')
    for r, i in pairs:
        A('be_core_pin {%s} {%s}' % (r, i))
    A('puts "BE_CORE_PIN_END ok=$::BE_CORE_OK bad=$::BE_CORE_BAD expect=$::BE_CORE_EXPECT"')
    A('if {$::BE_CORE_BAD != 0 || $::BE_CORE_OK != $::BE_CORE_EXPECT} {')
    A('  error "BE_CORE_PIN: ok=$::BE_CORE_OK bad=$::BE_CORE_BAD expect=$::BE_CORE_EXPECT"')
    A('}')
    return '\n'.join(L) + '\n'


def splice(text, gen):
    if BEGIN in text:
        i = text.index(BEGIN)
        j = text.index(END, i) + len(END) + 1
        return text[:i] + gen + text[j:]
    return text.rstrip('\n') + '\n\n' + gen


# ---------------------------------------------------------------------------
# 连接对说明（按 fam() 归一的无序对）
# ---------------------------------------------------------------------------
_PAIR_DESC_TEXT = r"""
bypassNetwork|core	旁路出口的 valid / robIdx / loadDependency / LQ·SQ 号（算流水寄存器的冲刷与 Vldu 的"更老 uop"判定）
bypassNetwork|dataPath	OG1 读出的源操作数与旁路来源编号（int / fp / mem 三族直进旁路网络）、寄存器缓存读数据
bypassNetwork|fpExuBlock	fp 执行块的结果回旁路（下一拍旁路给相关指令）
bypassNetwork|intExuBlock	int 执行块的结果回旁路
bypassNetwork|og2ForVector	向量（vf 运算 / 向量访存）多走一级 OG2 后进旁路网络
bypassNetwork|toFpExu*	旁路网络 fp 出口 → 流水寄存器（payload 直连，ready 回送）
bypassNetwork|toIntExu*	旁路网络 int 出口 → 流水寄存器（payload 直连，ready 回送）
bypassNetwork|toMem*	旁路网络 mem 出口 → 流水寄存器（payload 直连，ready 回送）
bypassNetwork|toVfExu*	旁路网络 vf 出口 → 流水寄存器（payload 直连，ready 回送）
core|ctrlBlock	ROB 出队指针、关键错误、提交时的 vtype（入核）；打拍后的 CSR 翻译模式、vsetvl vtype、写回忙表清除、ROB 头访存发射（出核）
core|dataPath	difftest vl（入核打一拍）；打一拍的 TopDown L1 miss（出核）
core|fpExuBlock	流水寄存器的右侧 ready（算 rightOutFire）
core|fpScheduler	晚一拍的 fp 写回与 fp 唤醒；本调度器的唤醒总线（入核打拍）
core|intExuBlock	CSR 的翻译模式 / distribute_csr / 关键错误 / vtype（入核）；打拍后的中断 / MSI / 时钟 / vl / vtype CSR 写入值（出核）
core|intScheduler	晚一拍的 int 写回与唤醒；本调度器的唤醒总线（入核打拍）
core|memScheduler	晚一拍的五类写回与唤醒；本调度器的唤醒总线（入核打拍）；Vldu 的发射回应（出核）
core|pfevent	打一拍的 distribute_csr 写（性能事件选择寄存器）
core|toFpExu*	流水寄存器的 in.ready / out.valid / out.robIdx（入核）与 rightOutFire / isFlush（出核）
core|toIntExu*	流水寄存器的 in.ready / out.valid / out.robIdx（入核）与 rightOutFire / isFlush（出核）
core|toMem*	流水寄存器的 in.ready / out 握手与 robIdx·LQ·SQ·fuOpType·pc（入核）与 rightOutFire / isFlush / isOlder（出核）
core|toVfExu*	流水寄存器的 in.ready / out.valid / out.robIdx（入核）与 rightOutFire / isFlush（出核）
core|vfExuBlock	vsetvl 的 vtype（vf 执行块那一路，入核）；流水寄存器的右侧 ready
core|vfScheduler	晚一拍的 vf / v0 / vl 写回
core|wbDataPath	寄存器堆写口（入核：忙表清除与晚一拍写回）；向量 load 写回的寻址类型（出核）
ctrlBlock|ctrlBlock	CtrlBlock 自己的 LSQ 入队请求回接到它的调试口（debugEnqLsq）
ctrlBlock|dataPath	PC / 跳转目标存储读口（DataPath 读 PC 给跳转单元）、OG0 取消、数据通路冲刷
ctrlBlock|fpExuBlock	执行块冲刷（重定向）
ctrlBlock|fpScheduler	派遣到 fp 发射队列的 uop
ctrlBlock|intExuBlock	提交的异常 / 中断信息给 CSR，CSR 给译码的非法指令判定、trap 指令信息、fflags/vxsat 等提交副作用
ctrlBlock|intScheduler	派遣到 int 发射队列的 uop
ctrlBlock|memScheduler	派遣到访存发射队列的 uop、LSQ 入队信息、ROB 提交状态
ctrlBlock|og2ForVector	向量 OG2 级冲刷
ctrlBlock|perfHpm	CtrlBlock 性能事件
ctrlBlock|vecExcpMod	向量异常：ROB / 重命名表给出的逻辑-物理寄存器映射与旧 vd，合并模块忙标志回 CtrlBlock
ctrlBlock|vfExuBlock	执行块冲刷；vl 是否为 0 / vlmax 回派遣
ctrlBlock|vfScheduler	派遣到 vf 发射队列的 uop
ctrlBlock|wbDataPath	写回结果（含重定向、异常）给 ROB 标记完成
dataPath|fpScheduler	fp 发射：IQ 发出 → DataPath 读寄存器，OG0/OG1 回应
dataPath|intScheduler	int 发射：IQ 发出 → DataPath 读寄存器，OG0/OG1 回应
dataPath|memScheduler	访存发射：IQ 发出 → DataPath 读寄存器，OG0/OG1 回应与取消
dataPath|og2ForVector	向量 OG1 读出 → OG2
dataPath|perfHpm	DataPath 性能事件
dataPath|replayAllocateDelay	TopDown replayAllocate（打两拍）
dataPath|sbFullDelay	TopDown sbFull（打两拍）
dataPath|sqFullDelay	TopDown sqFull（打两拍）
dataPath|vecExcpMod	向量异常合并模块读写向量寄存器堆
dataPath|vfScheduler	vf 发射：IQ 发出 → DataPath 读寄存器，OG0/OG1 回应
dataPath|wbDataPath	寄存器堆写口（int / fp / vf / v0 / vl）
fpExuBlock|intExuBlock	CSR 的舍入模式 frm
fpExuBlock|toFpExu*	流水寄存器 → fp 执行块（payload 直连）
fpExuBlock|wbDataPath	fp 执行结果写回
fpScheduler|fpScheduler	fp 唤醒总线回到本调度器（同拍唤醒）
fpScheduler|perfHpm	fp 调度器性能事件
fpScheduler|wbDataPath	fp 寄存器堆写口（同拍写回唤醒）
fpScheduler|wbFuBusyTable	fp 调度器写回口占用表读写
intExuBlock|intExuBlock	CSR 的 frm 回给本执行块的 fp 相关单元
intExuBlock|memScheduler	vsetvl 算出的 vl 是否为 0 / vlmax（给向量访存发射）
intExuBlock|perfHpm	汇总后的 8 路后端性能事件给 CSR 的 hpm 计数器
intExuBlock|toIntExu*	流水寄存器 → int 执行块（payload 直连）
intExuBlock|vecExcpMod	向量异常合并忙标志给 CSR
intExuBlock|vfExuBlock	CSR 的 frm / vxrm
intExuBlock|vfScheduler	vsetvl 算出的 vl 是否为 0 / vlmax
intExuBlock|wbDataPath	int 执行结果（含跳转重定向）写回
intScheduler|intScheduler	int 唤醒总线回到本调度器（同拍唤醒）
intScheduler|memScheduler	int / mem 调度器之间的同拍唤醒（load 唤醒整数相关指令，整数唤醒访存地址计算）
intScheduler|perfHpm	int 调度器性能事件
intScheduler|wbDataPath	int 寄存器堆写口（同拍写回唤醒）
intScheduler|wbFuBusyTable	int 调度器写回口占用表读写
memScheduler|memScheduler	访存唤醒总线回到本调度器（同拍唤醒）
memScheduler|og2ForVector	向量访存 OG2 回应
memScheduler|perfHpm	访存调度器性能事件
memScheduler|toMem*	流水寄存器里的 uop（fuType / robIdx / LQ·SQ 号等）作 load / 向量 load 的最终发射回应字段
memScheduler|vfExuBlock	vf 执行块 vsetvl 的 vl 是否为 0 / vlmax
memScheduler|wbDataPath	五类寄存器堆写口（同拍写回唤醒，mem 调度器全收）
og2ForVector|vfScheduler	vf 运算 OG2 回应
perfHpm|pfevent	CSR 选出的 8 个性能事件编码
perfHpm|vfScheduler	vf 调度器性能事件
toVfExu*|vfExuBlock	流水寄存器 → vf 执行块（payload 直连）
vfExuBlock|vfScheduler	vf 执行块 vsetvl 的 vl 是否为 0 / vlmax
vfExuBlock|wbDataPath	vf 执行结果写回
vfScheduler|wbDataPath	vf / v0 / vl 寄存器堆写口（同拍写回唤醒）
vfScheduler|wbFuBusyTable	vf 调度器写回口占用表读写
"""
for _ln in _PAIR_DESC_TEXT.strip().splitlines():
    _k, _v = _ln.split('\t')
    _a, _b = _k.split('|')
    PAIR_DESC[tuple(sorted((_a, _b)))] = _v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    C = build()
    text = OUT.read_text()
    outs = [(OUT, text, splice(text, render(C))),
            (PINS, PINS.read_text() if PINS.exists() else '', render_pins(C))]
    rc = 0
    for path, old, new in outs:
        if a.check:
            if new != old:
                print('DRIFT: %s 与生成器输出不一致' % path.relative_to(REPO))
                rc = 1
            else:
                print('OK: %s' % path.relative_to(REPO))
        elif new != old:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(new)
            print('wrote %s' % path.relative_to(REPO))
        else:
            print('unchanged %s' % path.relative_to(REPO))
    return rc


if __name__ == '__main__':
    sys.exit(main())
