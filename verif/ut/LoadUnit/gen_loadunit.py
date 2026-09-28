#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_loadunit.py —— LoadUnit 的机械派生区生成器（rtl/memblock/LoadUnit.sv 的 GENERATED 段 + UT tb）。

★为什么要机械生成★ golden LoadUnit 有 2429 个扁平端口、957 个扁平寄存器。其中：
  * 端口：7 个 load 来源各带一份 ~180 字段的 DynInst(uop)，4 个 LqWriteBundle 输出又各带一份；
    wrapper 只是"扁平端口 ↔ 核的 struct"的拆装，手抄几千行 assign 漏一根线 UT 未必抓得住；
  * 寄存器：s1_in / s2_in / s3_in 三级流水寄存器各 ~200 个字段。golden 留下哪些字段是
    firtool 的 DCE / 常量折叠决定的（CONVENTIONS：字段集合必须从 golden 现数，不能从 Chisel 推），
    所以"留哪些字段"这张表只能从 golden 的 reg 声明机械读出来；
    每个字段的**次态逻辑**（s0_out / s1_out / s2_out 怎么算）全部在核里手写。

本脚本产出（幂等）：
  rtl/memblock/LoadUnit.sv 里的 GENERATED 段（其余手写区原样保留）：
    GENERATED(types)       loadunit_pkg 里的 uop_t / lq_write_t / 各接口 struct（字段 = golden 端口表并集）
    GENERATED(core_ports)  xs_LoadUnit_core 的端口表（每个接口一个 struct 口 + 若干标量口）
    GENERATED(pipe_regs)   s1_in / s2_in / s3_in 等"整包打拍"寄存器组：声明 + 装载 + 读回成 struct
    GENERATED(wrapper)     golden 同名 wrapper：golden 端口表逐位照抄，拆装成 struct 接核
  verif/ut/LoadUnit/tb.sv  golden LoadUnit vs LoadUnit_xs 双例化逐拍比对全部输出

生成时的机械核对（fail-closed，任何一项不符拒绝生成）：
  1. 每个 golden 端口恰好归属一个接口组或一个标量口；组内字段在 struct 里存在且位宽相等；
  2. 流水寄存器组里每个 golden 寄存器字段都能在对应 struct 里找到同宽成员；
  3. golden 的寄存器全集 = 本脚本生成的寄存器 ∪ 核里手写区声明的寄存器（逐名比对，多一个少一个都红）。

用法：
    python3 gen_loadunit.py            # 生成
    python3 gen_loadunit.py --check    # 产物与生成器不一致则非零退出
"""
import collections
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
RTL = REPO / 'rtl' / 'memblock' / 'LoadUnit.sv'
TB = HERE / 'tb.sv'
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/LoadUnit.sv')
TAG = 'verif/ut/LoadUnit/gen_loadunit.py'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
REG_RE = re.compile(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')


def die(msg):
    raise SystemExit('gen_loadunit: ★拒绝生成★ ' + msg)


# ---------------------------------------------------------------------------
# 0. 读 golden
# ---------------------------------------------------------------------------
def golden_ports():
    text = GOLDEN.read_text()
    m = re.search(r'^module LoadUnit\((.*?)\n\);', text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        pm = PORT_RE.match(line)
        if not pm:
            die('不认识的端口行: %r' % line)
        w = int(pm.group(2)) + 1 if pm.group(2) else 1
        res.append((pm.group(1), w, pm.group(3)))
    return res


def golden_regs():
    res = collections.OrderedDict()
    for line in GOLDEN.read_text().splitlines():
        m = REG_RE.match(line)
        if m:
            res[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
    return res


PORTS = golden_ports()
REGS = golden_regs()
PW = {n: w for _, w, n in PORTS}

# ---------------------------------------------------------------------------
# 1. 字段模型
# ---------------------------------------------------------------------------
# 数组化的字段：golden 展平成 <name>_<i>，struct 里收成一个打包数组 <name>[N]
ARRAYS = {
    'exceptionVec': 24,     # ExceptionNO 全集
    'rep_info_cause': 11,   # LoadReplayCauses.allCauses
    'forwardMask': 16,      # VLEN/8
    'forwardData': 16,
    'paddr': 2,             # tlb_resp 的两份 paddr（lsu / dcache 各一份）
}


# 撞 SystemVerilog 关键字的字段名（golden 端口名里是前缀的一部分，不撞；进了 struct 就撞了）
SV_KEYWORDS = {'alias', 'data_t', 'type', 'string', 'bit', 'byte', 'int', 'real', 'event', 'final'}


def split_field(f):
    """把 golden 字段名拆成 (struct 成员名, 数组下标或 None)。"""
    m = re.fullmatch(r'(\w+?)_(\d+)', f)
    if m and m.group(1) in ARRAYS:
        return m.group(1), int(m.group(2))
    if f in SV_KEYWORDS:
        return f + '_', None
    return f, None


class Struct:
    """一个 packed struct：成员有序表 name -> (elem_width, array_len or None, nested type or None)。"""

    def __init__(self, name, doc):
        self.name, self.doc = name, doc
        self.members = collections.OrderedDict()

    def add(self, field, width):
        """登记一个 golden 扁平字段（不含 uop_ 前缀的部分）。"""
        name, idx = split_field(field)
        if idx is not None:
            n = ARRAYS[name]
            if idx >= n:
                die('%s.%s 下标越界 %d' % (self.name, name, idx))
            old = self.members.get(name)
            if old and (old[0] != width or old[1] != n):
                die('%s.%s 位宽不一致' % (self.name, name))
            self.members[name] = (width, n, None)
        else:
            old = self.members.get(name)
            if old and (old[0] != width or old[1] is not None):
                die('%s.%s 位宽不一致 %r vs %d' % (self.name, name, old, width))
            self.members[name] = (width, None, None)

    def add_nested(self, name, typ):
        self.members[name] = (0, None, typ)

    def emit(self):
        out = ['  // %s' % self.doc, '  typedef struct packed {']
        for n, (w, arr, typ) in self.members.items():
            if typ:
                out.append('    %-22s %s;' % (typ, n))
            elif arr:
                if w == 1:
                    out.append('    logic %-16s %s;' % ('[%d:0]' % (arr - 1), n))
                else:
                    out.append('    logic %-16s %s;' % ('[%d:0][%d:0]' % (arr - 1, w - 1), n))
            elif w == 1:
                out.append('    logic %-16s %s;' % ('', n))
            else:
                out.append('    logic %-16s %s;' % ('[%d:0]' % (w - 1), n))
        out.append('  } %s;' % self.name)
        return out

    def has(self, field, width):
        name, idx = split_field(field)
        m = self.members.get(name)
        if not m or m[2]:
            return False
        return m[0] == width and ((idx is None) == (m[1] is None))

    def lvalue(self, var, field):
        name, idx = split_field(field)
        return '%s.%s%s' % (var, name, '' if idx is None else '[%d]' % idx)


# ---- uop_t：DynInst 在 LoadUnit 端口/寄存器里出现过的全部字段（并集） ----
UOP = Struct('uop_t', 'DynInst（后端微操作）在 LoadUnit 里出现过的全部字段；各接口只用其中一部分，'
             '其余在 wrapper 里补 0 / 丢弃')
# 以 fast_rep_in 的顺序为准（它带 DynInst 几乎全部字段，顺序即 Scala Bundle 定义序）
UOP_SOURCES = ['io_fast_rep_in_bits_uop_', 'io_misalign_ldin_bits_uop_', 'io_replay_bits_uop_',
               'io_lsq_nc_ldin_bits_uop_', 'io_lsq_uncache_bits_uop_', 'io_vecldin_bits_uop_',
               'io_ldin_bits_uop_', 'io_lsq_ldin_bits_uop_', 'io_fast_rep_out_bits_uop_',
               'io_misalign_enq_req_bits_uop_', 'io_wakeup_bits_', 'io_ldout_bits_uop_',
               'io_misalign_ldout_bits_uop_', 'io_lsq_forward_uop_', 'io_lsq_ld_raw_data_uop_',
               'io_lsq_ldld_nuke_query_req_bits_uop_', 'io_lsq_stld_nuke_query_req_bits_uop_']
for pre in UOP_SOURCES:
    for _, w, n in PORTS:
        if n.startswith(pre):
            UOP.add(n[len(pre):], w)
for rn, w in REGS.items():
    m = re.match(r'(s1_in_r|s2_in_r|s3_in|s2_mmio_req_bits_REG(?:_1)?|s3_mmio_req_bits|'
                 r's3_misalign_wakeup_req_bits_REG(?:_\d)?|s3_ld_raw_data_frm_mmio(?:_REG(?:_1)?)?)_uop_(\w+)$', rn)
    if m:
        UOP.add(m.group(2), w)

# ---- lq_write_t：LsPipelineBundle / LqWriteBundle ----
# 成员顺序照 Scala mem/Bundles.scala 的定义序；位宽取 golden。只收 golden 里出现过的字段，
# 外加 LQW_EXTRA（核里要用、但 golden 在任何端口/寄存器里都没留下的中间字段）。
LQW_ORDER = [
    'vaddr', 'fullva', 'vaNeedExt', 'paddr', 'gpaddr', 'mask', 'data', 'miss', 'tlbMiss', 'ptwBack',
    'nc', 'mmio', 'memBackTypeMM', 'hasException', 'isHyper', 'isForVSnonLeafPTE', 'isPrefetch',
    'isHWPrefetch', 'isvec', 'is128bit', 'elemIdx', 'alignedType', 'mbIndex', 'reg_offset',
    'elemIdxInsideVd', 'vecBaseVaddr', 'vecVaddrOffset', 'vecTriggerMask', 'vecActive',
    'isLoadReplay', 'isFastReplay', 'isFirstIssue', 'hasROBEntry', 'mshrid', 'handledByMSHR',
    'forward_tlDchannel', 'delayedLoadError', 'lateKill', 'feedbacked', 'schedIndex', 'tlbNoQuery',
    'isFrmMisAlignBuf', 'isMisalign', 'isFinalSplit', 'misalignWith16Byte', 'misalignNeedWakeUp',
    'updateAddrValid', 'rep_info_mshr_id', 'rep_info_full_fwd', 'rep_info_data_inv_sq_idx_flag',
    'rep_info_data_inv_sq_idx_value', 'rep_info_addr_inv_sq_idx_flag',
    'rep_info_addr_inv_sq_idx_value', 'rep_info_last_beat', 'rep_info_cause', 'rep_info_tlb_id',
    'rep_info_tlb_full', 'nc_with_data']
LQW_EXTRA = {'miss': 1, 'delayedLoadError': 1, 'feedbacked': 1}
LQW_SOURCES = ['io_fast_rep_in_bits_', 'io_misalign_ldin_bits_', 'io_replay_bits_',
               'io_lsq_nc_ldin_bits_', 'io_lsq_ldin_bits_', 'io_fast_rep_out_bits_',
               'io_misalign_enq_req_bits_', 'io_misalign_ldout_bits_']
LQW_REG_GROUPS = ['s1_in_r_', 's2_in_r_', 's3_in_', 's3_misalign_wakeup_req_bits_REG_']
_lqw_seen = collections.OrderedDict()
for pre in LQW_SOURCES:
    for _, w, n in PORTS:
        if n.startswith(pre) and not n[len(pre):].startswith('uop_'):
            _lqw_seen.setdefault(n[len(pre):], w)
for pre in LQW_REG_GROUPS:
    for rn, w in REGS.items():
        if rn.startswith(pre) and not rn[len(pre):].startswith('uop_') and not re.match(r'\d', rn[len(pre):]):
            _lqw_seen.setdefault(rn[len(pre):], w)
LQW = Struct('lq_write_t', 'LqWriteBundle（= LsPipelineBundle + rep_info + nc_with_data）：'
             'load 流水各级的"包"，也是 replay/快速重发/非对齐缓冲/LSQ 各口的载荷')
LQW.add_nested('uop', 'uop_t')
_lqw_names = collections.OrderedDict()
for f, w in list(_lqw_seen.items()) + list(LQW_EXTRA.items()):
    name, _ = split_field(f)
    if name not in LQW_ORDER:
        die('lq_write_t 遇到不认识的字段 %r（请把它加进 LQW_ORDER）' % f)
    _lqw_names.setdefault(name, []).append((f, w))
for name in LQW_ORDER:
    for f, w in _lqw_names.get(name, []):
        LQW.add(f, w)

# ---------------------------------------------------------------------------
# 2. 接口分组：(核端口名, golden 前缀, 方向, struct 类型名, 说明)
#    类型名 'uop_t' / 'lq_write_t' 用上面两个公共类型；其它类型名由组内字段并集自动生成。
# ---------------------------------------------------------------------------
GROUPS = [
    # ---- s0：7 路 load 来源 + 硬件预取 ----
    ('ldin',              'io_ldin_bits_',              'input',  'ldin_t',        '标量 load 首次发射（发射队列）：src_0=基址寄存器'),
    ('vecldin',           'io_vecldin_bits_',           'input',  'vecldin_t',     '向量 load 拆出的元素流（VLSplit）'),
    ('misalign_ldin',     'io_misalign_ldin_bits_',     'input',  'lq_write_t',    '非对齐缓冲拆出的对齐子访问'),
    ('replay',            'io_replay_bits_',            'input',  'lq_write_t',    'LoadQueueReplay 重发'),
    ('fast_rep_in',       'io_fast_rep_in_bits_',       'input',  'lq_write_t',    '本流水 s3 的快速重发回灌'),
    ('lsq_nc_ldin',       'io_lsq_nc_ldin_bits_',       'input',  'lq_write_t',    'NC(非缓存可合并) load 带数据回来'),
    ('lsq_uncache',       'io_lsq_uncache_bits_',       'input',  'exu_out_t',     'MMIO load 从 uncache 回来的写回包'),
    ('prefetch_req',      'io_prefetch_req_bits_',      'input',  'pf_req_t',      '硬件预取请求（L1 prefetcher）'),
    # ---- s1：TLB / 触发器 / 违例查询 ----
    ('tlb_resp',          'io_tlb_resp_bits_',          'input',  'tlb_resp_t',    'DTLB 应答（s1）'),
    ('trigger_csr',       'io_fromCsrTrigger_',         'input',  'trigger_csr_t', 'CSR 下发的调试触发器配置'),
    ('stld_nuke_query_0', 'io_stld_nuke_query_0_',      'input',  'st_query_t',    'store 流水 0 的 st-ld 违例广播'),
    ('stld_nuke_query_1', 'io_stld_nuke_query_1_',      'input',  'st_query_t',    'store 流水 1 的 st-ld 违例广播'),
    # ---- s2：DCache 应答 / 前递 ----
    ('pmp',               'io_pmp_',                    'input',  'pmp_t',         'PMP/PMA 检查结果（与 TLB 应答同拍到达，s2 用）'),
    ('dcache_resp',       'io_dcache_resp_bits_',       'input',  'dcache_resp_t', 'DCache 应答（s2；tl_error_delayed 在 s3 用）'),
    ('sbuffer_resp',      'io_sbuffer_',                'input',  'fwd_resp_t',    'sbuffer 前递结果'),
    ('ubuffer_resp',      'io_ubuffer_',                'input',  'fwd_resp_t',    'uncache buffer 前递结果（NC）'),
    ('lsq_fwd_resp',      'io_lsq_forward_',            'input',  'lsq_fwd_resp_t', 'store queue 前递结果'),
    ('tl_d_channel',      'io_tl_d_channel_',           'input',  'd_chan_t',      'TileLink D 通道回填数据（前递用）'),
    ('mshr_fwd_resp',     'io_forward_mshr_',           'input',  'mshr_fwd_resp_t', 'MSHR 前递结果'),
    ('tlb_hint',          'io_tlb_hint_',               'input',  'tlb_hint_t',    'TLB miss 的 filter 表项号（回放唤醒用）'),
    # ---- s3 ----
    ('ld_raw_data',       'io_lsq_ld_raw_data_',        'input',  'ld_raw_data_t', 'MMIO load 的原始数据（LQ 合并好的 64 位）'),
    ('robDeqIdx',         'io_robDeqIdx_',              'input',  'rob_ptr_t',     'ROB 队头：非对齐只准最老指令进缓冲'),
    ('redirect',          'io_redirect_bits_',          'input',  'redirect_t',    '后端重定向（冲刷）'),
    ('csrCtrl',           'io_csrCtrl_',                'input',  'csr_ctrl_t',    '自定义 CSR 开关'),
    # ---- 输出 ----
    ('tlb_req',           'io_tlb_req_bits_',           'output', 'tlb_req_t',     'DTLB 请求（s0 发，s1 带 pmp_addr）'),
    ('dcache_req',        'io_dcache_req_bits_',        'output', 'dcache_req_t',  'DCache 请求（s0）'),
    ('sbuffer_req',       'io_sbuffer_',                'output', 'fwd_req_t',     'sbuffer 前递查询（s1）'),
    ('ubuffer_req',       'io_ubuffer_',                'output', 'fwd_req_t',     'uncache buffer 前递查询（s1）'),
    ('lsq_fwd_req',       'io_lsq_forward_',            'output', 'lsq_fwd_req_t', 'store queue 前递查询（s1）'),
    ('mshr_fwd_req',      'io_forward_mshr_',           'output', 'mshr_fwd_req_t', 'MSHR 前递查询（s1）'),
    ('stld_nuke_req',     'io_lsq_stld_nuke_query_req_bits_', 'output', 'nuke_req_t', '登记 RAW 违例队列（s2）'),
    ('ldld_nuke_req',     'io_lsq_ldld_nuke_query_req_bits_', 'output', 'nuke_req_t', '登记 RAR 违例队列（s2）'),
    ('prefetch_train',    'io_prefetch_train_bits_',    'output', 'pf_train_t',    '训练 SMS 预取器（s3）'),
    ('prefetch_train_l1', 'io_prefetch_train_l1_bits_', 'output', 'pf_train_t',    '训练 L1 stream/stride 预取器（s3）'),
    ('ifetchPrefetch',    'io_ifetchPrefetch_bits_',    'output', 'ifetch_pf_t',   'prefetch.i 转给取指'),
    ('wakeup',            'io_wakeup_bits_',            'output', 'uop_t',         's0 推测唤醒的 uop'),
    ('ldout',             'io_ldout_bits_',             'output', 'exu_out_t',     '标量写回（s3）'),
    ('vecldout',          'io_vecldout_bits_',          'output', 'vecldout_t',    '向量写回到合并缓冲（s3）'),
    ('lsq_ldin',          'io_lsq_ldin_bits_',          'output', 'lq_write_t',    '写 load queue（s3）'),
    ('fast_rep_out',      'io_fast_rep_out_bits_',      'output', 'lq_write_t',    '快速重发（s3 → 下一拍 s0）'),
    ('misalign_enq',      'io_misalign_enq_req_bits_',  'output', 'lq_write_t',    '非对齐访问进非对齐缓冲（s3）'),
    ('misalign_ldout',    'io_misalign_ldout_bits_',    'output', 'lq_write_t',    '非对齐子访问的结果回非对齐缓冲（s3）'),
    ('feedback_slow',     'io_feedback_slow_bits_',     'output', 'feedback_t',    '给发射队列的慢反馈（s3）'),
    ('rollback',          'io_rollback_bits_',          'output', 'rollback_t',    'RAR 违例 / 前递地址失配引起的回滚重定向（s3）'),
    ('lsTopdownInfo',     'io_lsTopdownInfo_',          'output', 'topdown_t',     'topdown 性能分析'),
]
DOC = {g[3]: g[4] for g in GROUPS}
DOC.update({'exu_out_t': 'MemExuOutput（写回包）', 'fwd_resp_t': 'sbuffer/ubuffer 前递结果',
            'fwd_req_t': 'sbuffer/ubuffer 前递查询', 'nuke_req_t': 'RAR/RAW 违例队列登记请求',
            'pf_train_t': '预取训练包', 'st_query_t': 'store 流水的 st-ld 违例广播'})

TYPES = collections.OrderedDict()
TYPES['uop_t'] = UOP
TYPES['lq_write_t'] = LQW


def group_ports(pre, direction):
    """该前缀下、该方向的全部 golden 端口（valid/ready 另算标量口，不进 struct）。"""
    res = []
    for d, w, n in PORTS:
        if d == direction and n.startswith(pre):
            res.append((n[len(pre):], w, n))
    return res


# 自动类型：字段并集（uop_ 前缀收成嵌套 uop_t）
for core, pre, d, typ, doc in GROUPS:
    if typ in ('uop_t', 'lq_write_t'):
        continue
    st = TYPES.setdefault(typ, Struct(typ, DOC[typ]))
    for f, w, n in group_ports(pre, d):
        if f.startswith('uop_'):
            if 'uop' not in st.members:
                st.add_nested('uop', 'uop_t')
            continue
        st.add(f, w)

# 标量口（不属于任何组的端口）
GROUPED = {}
for core, pre, d, typ, doc in GROUPS:
    for f, w, n in group_ports(pre, d):
        if n in GROUPED:
            die('端口 %s 同时属于两个组' % n)
        GROUPED[n] = (core, typ, f)
SCALARS = [(d, w, n) for d, w, n in PORTS if n not in GROUPED and n not in ('clock', 'reset')]

# ---- 端口 → 核 struct 成员 的映射核对 ----
for n, (core, typ, f) in GROUPED.items():
    st = TYPES[typ]
    if typ == 'uop_t':
        if not UOP.has(f, PW[n]):
            die('%s -> %s.%s 不在 uop_t 里或位宽不符' % (n, core, f))
    elif f.startswith('uop_'):
        if not UOP.has(f[4:], PW[n]):
            die('%s -> %s.uop.%s 不在 uop_t 里或位宽不符' % (n, core, f[4:]))
    elif not st.has(f, PW[n]):
        die('%s -> %s.%s 不在 %s 里或位宽不符' % (n, core, f, typ))


def member_lvalue(var, typ, f):
    if typ == 'uop_t':
        return UOP.lvalue(var, f)
    if f.startswith('uop_'):
        return UOP.lvalue(var + '.uop', f[4:])
    return TYPES[typ].lvalue(var, f)


# ---------------------------------------------------------------------------
# 3. 流水寄存器组：golden 寄存器名前缀 -> 核里的 struct 变量
#    (前缀, 装载源 struct 表达式, 读回 struct 变量, 类型, 装载使能, 说明)
# ---------------------------------------------------------------------------
PIPE_GROUPS = [
    # 三级主流水：整包打拍
    ('s1_in_r_', 's0_out', 's1_in', 'lq_write_t', 's0_fire', 's1_in  <= s0_out（s0_fire 时整包打拍，无复位）'),
    ('s2_in_r_', 's1_out', 's2_in', 'lq_write_t', 's1_fire', 's2_in  <= s1_out（s1_fire 时整包打拍，无复位）'),
    ('s3_in_',   's2_out', 's3_in', 'lq_write_t', 's2_fire', 's3_in  <= s2_out（s2_fire 时整包打拍，无复位）'),
    # MMIO 写回包：uncache 回来的写回包逐拍打 3 拍，与主流水 s3 对齐（RegNextN(bits, 2) 再 RegNext）
    ('s2_mmio_req_bits_REG_',   'lsq_uncache', 'mmio_req_d1',       'exu_out_t', None, 'MMIO 写回包第 1 拍'),
    ('s2_mmio_req_bits_REG_1_', 'mmio_req_d1', 's2_mmio_req_bits',  'exu_out_t', None, 'MMIO 写回包第 2 拍（= s2_mmio_req.bits）'),
    ('s3_mmio_req_bits_',       's2_mmio_req_bits', 's3_mmio_req_bits', 'exu_out_t', None, 'MMIO 写回包第 3 拍（= s3_mmio_req.bits）'),
    # MMIO 原始数据：LQ 送来的 64 位数据同样打 3 拍
    ('s3_ld_raw_data_frm_mmio_REG_',   'ld_raw_data', 'mmio_raw_d1', 'ld_raw_data_t', None, 'MMIO 原始数据第 1 拍'),
    ('s3_ld_raw_data_frm_mmio_REG_1_', 'mmio_raw_d1', 'mmio_raw_d2', 'ld_raw_data_t', None, 'MMIO 原始数据第 2 拍'),
    ('s3_ld_raw_data_frm_mmio_',       'mmio_raw_d2', 's3_ld_raw_data_frm_mmio', 'ld_raw_data_t', None, 'MMIO 原始数据第 3 拍'),
    # 非对齐缓冲的"唤醒"请求：misalign_ldin 的包原样打 3 拍，从 misalign_ldout 回送
    ('s3_misalign_wakeup_req_bits_REG_',   'misalign_ldin', 'mab_wakeup_d1', 'lq_write_t', None, '非对齐唤醒包第 1 拍'),
    ('s3_misalign_wakeup_req_bits_REG_1_', 'mab_wakeup_d1', 'mab_wakeup_d2', 'lq_write_t', None, '非对齐唤醒包第 2 拍'),
    ('s3_misalign_wakeup_req_bits_REG_2_', 'mab_wakeup_d2', 's3_misalign_wakeup_req_bits', 'lq_write_t', None, '非对齐唤醒包第 3 拍'),
    # 预取训练：s2_in 在训练有效时锁存一拍（LsPrefetchTrainBundle.fromLsPipelineBundle(latch=true)）
    ('inputReg_',   's2_in', 'pf_train_in',    'lq_write_t', 's2_prefetch_train_valid',    'SMS 训练包锁存'),
    ('inputReg_1_', 's2_in', 'pf_train_l1_in', 'lq_write_t', 's2_prefetch_train_l1_valid', 'L1 预取训练包锁存'),
]
PIPE_REGS = collections.OrderedDict()   # golden 寄存器名 -> (组下标, 字段)
for rn, w in REGS.items():
    best = None
    for gi, g in enumerate(PIPE_GROUPS):
        if rn.startswith(g[0]) and (best is None or len(g[0]) > len(PIPE_GROUPS[best][0])):
            best = gi
    if best is None:
        continue
    pre, src, dst, typ, en, doc = PIPE_GROUPS[best]
    f = rn[len(pre):]
    ok = UOP.has(f[4:], w) if f.startswith('uop_') else TYPES[typ].has(f, w)
    if not ok:
        die('流水寄存器 %s 的字段 %s 不在 %s 里或位宽不符' % (rn, f, typ))
    PIPE_REGS[rn] = (best, f)


# ---------------------------------------------------------------------------
# 4. 文本生成
# ---------------------------------------------------------------------------
def sv_decl(w, name, kind='logic'):
    return '  %s %s%s;' % (kind, '[%d:0] ' % (w - 1) if w > 1 else '', name)


def gen_types():
    out = []
    # 被引用的类型先定义：uop_t -> lq_write_t -> 其余
    for name, st in TYPES.items():
        out += st.emit()
        out.append('')
    return out[:-1]


def gen_core_ports():
    out = []
    out.append('  input  logic                clock,')
    out.append('  input  logic                reset,')
    for core, pre, d, typ, doc in GROUPS:
        out.append('  %-6s %-20s %s,  // %s' % (d, typ, core, doc))
    out.append('  // ---- 握手 / 标量口（名字 = golden 端口名去掉 io_ 前缀）----')
    for i, (d, w, n) in enumerate(SCALARS):
        sep = ',' if i < len(SCALARS) - 1 else ''
        rng = '[%d:0]' % (w - 1) if w > 1 else ''
        out.append('  %-6s logic %-14s %s%s' % (d, rng, n[3:], sep))
    return out


def gen_pipe_regs():
    out = []
    for gi, (pre, src, dst, typ, en, doc) in enumerate(PIPE_GROUPS):
        regs = [(rn, f) for rn, (g, f) in PIPE_REGS.items() if g == gi]
        out.append('  // ---- %s：golden 留下的 %d 个字段 ----' % (doc, len(regs)))
        for rn, f in regs:
            out.append(sv_decl(REGS[rn], rn))
        out.append('  always_ff @(posedge clock) begin')
        if en:
            out.append('    if (%s) begin' % en)
        ind = '      ' if en else '    '
        for rn, f in regs:
            out.append('%s%s <= %s;' % (ind, rn, member_lvalue(src, typ, f)))
        if en:
            out.append('    end')
        out.append('  end')
        out.append('  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0')
        out.append('  always_comb begin')
        out.append("    %s = '0;" % dst)
        for rn, f in regs:
            out.append('    %s = %s;' % (member_lvalue(dst, typ, f), rn))
        out.append('  end')
        out.append('')
    return out[:-1]


def gen_wrapper():
    out = []
    out.append('module LoadUnit')
    out.append('  import loadunit_pkg::*;')
    out.append('(')
    for i, (d, w, n) in enumerate(PORTS):
        sep = ',' if i < len(PORTS) - 1 else ''
        rng = '[%d:0]' % (w - 1) if w > 1 else ''
        out.append('  %-6s %-8s %s%s' % (d, rng, n, sep))
    out.append(');')
    out.append('')
    # struct 信号
    for core, pre, d, typ, doc in GROUPS:
        out.append('  %-16s %s;' % (typ, core))
    out.append('')
    for core, pre, d, typ, doc in GROUPS:
        members = group_ports(pre, d)
        if d == 'input':
            out.append('  always_comb begin')
            out.append("    %s = '0;" % core)
            for f, w, n in members:
                out.append('    %s = %s;' % (member_lvalue(core, typ, f), n))
            out.append('  end')
        else:
            for f, w, n in members:
                out.append('  assign %s = %s;' % (n, member_lvalue(core, typ, f)))
    out.append('')
    out.append('  xs_LoadUnit_core u_core (')
    conns = ['    .clock (clock)', '    .reset (reset)']
    for core, pre, d, typ, doc in GROUPS:
        conns.append('    .%s (%s)' % (core, core))
    for d, w, n in SCALARS:
        conns.append('    .%s (%s)' % (n[3:], n))
    out.append(',\n'.join(conns))
    out.append('  );')
    out.append('')
    out.append('endmodule')
    return out


def replace_region(text, tag, lines):
    b = '// BEGIN GENERATED(%s) —— %s 生成，勿手改' % (tag, TAG)
    e = '// END GENERATED(%s)' % tag
    pat = re.compile(r'([ \t]*)' + re.escape(b) + r'\n.*?' + re.escape(e), re.S)
    m = pat.search(text)
    if not m:
        die('LoadUnit.sv 里找不到 GENERATED(%s) 标记' % tag)
    ind = m.group(1)
    body = '\n'.join(lines)
    return text[:m.start()] + ind + b + '\n' + body + '\n' + ind + e + text[m.end():]


NAV = [
    ('loadunit_pkg：常量、FlowSource、小工具函数', r'^  // ---------------- 流水宽度与地址参数'),
    ('xs_LoadUnit_core —— 可读核', r'^// xs_LoadUnit_core —— 可读核'),
    ('s0：11 路来源选一路，发 DTLB / DCache 请求', r'^  // s0：从 11 路来源'),
    ('s1：TLB 应答、前递查询、st-ld 违例、调试触发器', r'^  // s1：拿 TLB 应答'),
    ('s2：DCache 应答、前递合并、异常与 replay 原因', r'^  // s2：拿 DCache 应答'),
    ('s3：写回 / 写 LQ / 快速重发 / 非对齐 / 回滚', r'^  // s3：写回 / 写 LQ'),
    ('性能事件', r'^  // 性能事件：'),
    ('整包打拍寄存器（生成）', r'^  // 整包打拍寄存器（golden'),
    ('golden 同名 wrapper（生成）', r'^// golden 同名 wrapper —— 端口逐位照抄'),
]


def gen_nav(text):
    lines = text.split('\n')
    out = []
    for label, pat in NAV:
        idx = [i for i, ln in enumerate(lines) if re.match(pat, ln)]
        if len(idx) != 1:
            die('导航锚点 %r 命中 %d 处（要求恰好 1 处）' % (pat, len(idx)))
        out.append('//   L%-5d %s' % (idx[0] + 1, label))
    return out


def check_reg_universe(text):
    """golden 寄存器全集 == 生成的流水寄存器 ∪ 手写区声明的寄存器（逐名）。"""
    code = re.sub(r'//[^\n]*', '', text)
    code = re.sub(r'// BEGIN GENERATED\(pipe_regs\).*?// END GENERATED\(pipe_regs\)', '', text, flags=re.S)
    code = re.sub(r'//[^\n]*', '', code)
    core = re.search(r'module xs_LoadUnit_core(.*?)\nendmodule', code, re.S)
    if not core:
        return ['找不到 xs_LoadUnit_core']
    hand = set()
    for m in re.finditer(r'^\s*logic\s+(?:\[[^\]]+\]\s*)*([\w,\s]+?);', core.group(1), re.M):
        for nm in m.group(1).split(','):
            hand.add(nm.strip())
    errs = []
    for rn in REGS:
        if rn not in PIPE_REGS and rn not in hand:
            errs.append('golden 寄存器 %s 在核里没有同名声明' % rn)
    return errs


# ---------------------------------------------------------------------------
# 5. tb
# ---------------------------------------------------------------------------
from tb_template import gen_tb  # noqa: E402  (同目录：激励与覆盖计数的手写部分)


def main(argv):
    check = '--check' in argv
    text = RTL.read_text()
    new = replace_region(text, 'types', gen_types())
    new = replace_region(new, 'core_ports', gen_core_ports())
    new = replace_region(new, 'pipe_regs', gen_pipe_regs())
    new = replace_region(new, 'wrapper', gen_wrapper())
    # 导航行数固定：先填一遍让行数到位，再按到位后的行号填第二遍
    new = replace_region(new, 'nav', gen_nav(new))
    new = replace_region(new, 'nav', gen_nav(new))
    errs = check_reg_universe(new)
    if errs and '--allow-missing-regs' not in argv:
        for e in errs[:40]:
            print('  ' + e)
        die('%d 个 golden 寄存器在核里找不到同名声明' % len(errs))
    tb = gen_tb(PORTS, REGS)
    outputs = [(RTL, new), (TB, tb)]
    if check:
        bad = [p for p, t in outputs if not p.exists() or p.read_text() != t]
        if bad:
            print('gen_loadunit --check: 以下产物与生成器不一致：')
            for p in bad:
                print('  ' + str(p.relative_to(REPO)))
            return 1
        print('gen_loadunit --check: %d 个产物与生成器一致' % len(outputs))
        return 0
    for p, t in outputs:
        if not p.exists() or p.read_text() != t:
            p.write_text(t)
            print('写入 ' + str(p.relative_to(REPO)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
