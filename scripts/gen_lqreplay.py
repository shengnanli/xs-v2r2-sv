#!/usr/bin/env python3
"""gen_lqreplay.py —— LoadQueueReplay 单文件内机械派生区的生成器。

本轮单文件规范：一个 golden 模块 = 一个 .sv 文件。LoadQueueReplay 的 golden
(G1, 138860 行) 里有 99% 的体量是「72 条 entry × 完整 DynInst uop bundle」的
存-转发 payload 展平。这部分**没有微架构**，纯机械，于是：

  · 可读核 xs_LoadQueueReplay_core 的端口用 struct/数组表达（手写，语义清楚）；
  · uop 的 177 个字段、wrapper 的 1389 个扁平端口、以及 wrapper↔core 的
    打包/拆包连线，由本脚本从 **golden 自身** 读出来生成，写进单文件内的
    `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 区间。

三个 tag：
  uop_fields    —— package 里 lqr_uop_t 的成员声明（从 golden uop_0_* 寄存器 +
                   io_enq_0_bits_uop_* 端口推出，含只在入队用的 loadWaitStrict）
  wrapper_ports —— module LoadQueueReplay 的扁平端口表（逐字取 golden 端口表，
                   顺序/名字/位宽全同）
  wrapper_body  —— wrapper 内的 struct 打包 + u_core 例化连线

用法:
  scripts/gen_lqreplay.py --check     # 只比对，不写（gate 用）
  scripts/gen_lqreplay.py             # 原地替换三个 GENERATED 区

★手写区脚本不得触碰★：本脚本只在 marker 之间替换，marker 之外一个字节都不动。
"""
import argparse
import os
import re
import sys

GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl/LoadQueueReplay.sv"
HERE = os.path.dirname(os.path.abspath(__file__))
TARGET = os.path.join(HERE, "..", "rtl", "memblock", "LoadQueueReplay.sv")

LD_PIPE_W = 3          # LoadPipelineWidth
VEC_FIELDS = ["isvec", "is128bit", "elemIdx", "alignedType", "mbIndex",
              "elemIdxInsideVd", "reg_offset", "vecActive", "mask"]

# ---------------------------------------------------------------------------
#  读 golden
# ---------------------------------------------------------------------------


def read_golden():
    with open(GOLDEN) as f:
        return f.read().split("\n")


def port_table(lines):
    """golden 顶层端口表：[(dir, msb, lsb, name)]，顺序即 golden 顺序。"""
    start = next(i for i, l in enumerate(lines) if l.startswith("module LoadQueueReplay("))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            continue
        msb = int(m.group(2)) if m.group(2) is not None else None
        lsb = int(m.group(3)) if m.group(3) is not None else None
        out.append((m.group(1), msb, lsb, m.group(4)))
    return out


def uop_field_widths(lines, ports):
    """uop 字段 -> 位宽。

    优先用 golden 的 per-entry 寄存器 `uop_0_<f>` 的声明位宽；入队才有、不存的字段
    （loadWaitStrict）退回用 `io_enq_0_bits_uop_<f>` 端口位宽。
    """
    w = {}
    pat = re.compile(r"^  reg\s+(?:\[(\d+):(\d+)\]\s+)?uop_0_(\w+);")
    for l in lines:
        m = pat.match(l)
        if m:
            w[m.group(3)] = (int(m.group(1)) - int(m.group(2)) + 1) if m.group(1) else 1
    stored = set(w)
    # 入队端口里出现、但不逐 entry 存的字段
    for d, msb, lsb, n in ports:
        m = re.match(r"^io_enq_0_bits_uop_(\w+)$", n)
        if m and m.group(1) not in w:
            w[m.group(1)] = (msb - lsb + 1) if msb is not None else 1
    return w, stored


# ---------------------------------------------------------------------------
#  生成：uop_fields
# ---------------------------------------------------------------------------


def gen_uop_fields(widths, stored, order):
    """EXC_KEEP + lqr_uop_pay_t + lqr_uop_t 三段。

    为什么要拆成两层 struct（而不是一个扁平 struct）：golden 的 uop bundle 里有两类
    字段**不逐 entry 存**——
      · exceptionVec 的某些 bit（本配置是 bit4，在 G1 里连端口都没有）；
      · loadWaitStrict（入队时算完 strict_N 就丢）。
    若核里整包 `uop[i] <= enq_uop[w]` 存下去，这些字段会各自变成 72 个
    **impl-only 未读寄存器**（golden 侧根本没有对应寄存器）——strict 签核下
    任何 unread 都判 PARTIAL。把「整包要存的 152 个字段」收进 lqr_uop_pay_t，
    存的时候就能写成一句 `uop[i].p <= ...`，而 exceptionVec 逐位按 EXC_KEEP 存、
    loadWaitStrict 干脆不驱动。可读性也更好：结构本身说明了「哪些是存的」。
    """
    exc_bits = sorted(int(f.split("_")[1]) for f in widths if f.startswith("exceptionVec_"))
    keep = 0
    for b in exc_bits:
        keep |= 1 << b
    pay = [f for f in order if not f.startswith("exceptionVec_") and f in stored]
    extra = [f for f in order if not f.startswith("exceptionVec_") and f not in stored]
    L = []
    L.append("  // golden 逐 entry 存的 exceptionVec 位集合（1=存）。本配置存 bit "
             + ",".join(str(b) for b in exc_bits) + "。")
    L.append("  localparam logic [23:0] EXC_KEEP = 24'b%s;" % format(keep, "024b"))
    L.append("")
    L.append("  // ---- 逐 entry 整包存的 uop payload（golden uop_N_<field> 寄存器全集）----")
    L.append("  typedef struct packed {")
    maxn = max(len(f) for f in pay + extra)
    for f in pay:
        w = widths[f]
        ty = "logic" if w == 1 else "logic [%d:0]" % (w - 1)
        L.append("    %-14s %-*s;" % (ty, maxn, f))
    L.append("  } lqr_uop_pay_t;")
    L.append("")
    L.append("  // ---- 入队/重放口上的完整 uop bundle ----")
    L.append("  typedef struct packed {")
    L.append("    // 位号 = 架构异常号，与 golden uop_N_exceptionVec_<b> 逐位同号。")
    L.append("    logic [23:0]   exceptionVec;")
    for f in extra:
        w = widths[f]
        ty = "logic" if w == 1 else "logic [%d:0]" % (w - 1)
        L.append("    %-14s %-*s;   // 仅入队用，golden 不逐 entry 存、也不从重放口出" % (ty, maxn, f))
    L.append("    lqr_uop_pay_t  p;")
    L.append("  } lqr_uop_t;")
    return L, exc_bits, pay


# ---------------------------------------------------------------------------
#  生成：wrapper_ports
# ---------------------------------------------------------------------------


def gen_wrapper_ports(ports):
    out = []
    n = len(ports)
    for i, (d, msb, lsb, name) in enumerate(ports):
        rng = "" if msb is None else "[%d:%d] " % (msb, lsb)
        comma = "" if i == n - 1 else ","
        out.append("  %-6s %-10s%s%s" % (d, rng, name, comma))
    return out


# ---------------------------------------------------------------------------
#  生成：wrapper_body（扁平 io_* <-> 核的 struct/数组）
# ---------------------------------------------------------------------------


def core_signal_for(name, exc_bits, pay=()):
    """把一个 golden 扁平端口名映射到核侧表达式；返回 None 表示这个端口单独处理。

    `pay` 是逐 entry 整包存的字段集合（住在 lqr_uop_t.p 里），其余 uop 标量字段
    （本配置只有 loadWaitStrict）直接挂在 lqr_uop_t 顶层。
    """
    def uop(side, w, f):
        return "%s_uop[%s].%s%s" % (side, w, "p." if f in pay else "", f)

    m = re.match(r"^io_enq_(\d)_bits_uop_exceptionVec_(\d+)$", name)
    if m:
        return "enq_uop[%s].exceptionVec[%s]" % (m.group(1), m.group(2))
    m = re.match(r"^io_enq_(\d)_bits_uop_(\w+)$", name)
    if m:
        return uop("enq", m.group(1), m.group(2))
    m = re.match(r"^io_replay_(\d)_bits_uop_exceptionVec_(\d+)$", name)
    if m:
        return "replay_uop[%s].exceptionVec[%s]" % (m.group(1), m.group(2))
    m = re.match(r"^io_replay_(\d)_bits_uop_(\w+)$", name)
    if m:
        return uop("replay", m.group(1), m.group(2))
    m = re.match(r"^io_enq_(\d)_bits_(\w+)$", name)
    if m:
        w, f = m.group(1), m.group(2)
        if f in VEC_FIELDS:
            return "enq_vec[%s].%s" % (w, f)
        return {
            "vaddr": "enq_vaddr[%s]" % w,
            "isLoadReplay": "enq_isLoadReplay[%s]" % w,
            "handledByMSHR": "enq_handledByMSHR[%s]" % w,
            "schedIndex": "enq_schedIndex[%s]" % w,
            "rep_info_mshr_id": "enq_mshr_id[%s]" % w,
            "rep_info_full_fwd": "enq_full_fwd[%s]" % w,
            "rep_info_data_inv_sq_idx_flag": "enq_data_inv_sq_idx[%s].flag" % w,
            "rep_info_data_inv_sq_idx_value": "enq_data_inv_sq_idx[%s].value" % w,
            "rep_info_addr_inv_sq_idx_flag": "enq_addr_inv_sq_idx[%s].flag" % w,
            "rep_info_addr_inv_sq_idx_value": "enq_addr_inv_sq_idx[%s].value" % w,
            "rep_info_last_beat": "enq_last_beat[%s]" % w,
            "rep_info_tlb_id": "enq_tlb_id[%s]" % w,
            "rep_info_tlb_full": "enq_tlb_full[%s]" % w,
        }.get(f) or (("enq_cause[%s][%s]" % (w, f[len("rep_info_cause_"):]))
                     if f.startswith("rep_info_cause_") else None)
    m = re.match(r"^io_enq_(\d)_valid$", name)
    if m:
        return "enq_valid[%s]" % m.group(1)
    m = re.match(r"^io_replay_(\d)_bits_(\w+)$", name)
    if m:
        w, f = m.group(1), m.group(2)
        if f in VEC_FIELDS:
            return "replay_vec[%s].%s" % (w, f)
        return {
            "vaddr": "replay_vaddr[%s]" % w,
            "mshrid": "replay_mshrid[%s]" % w,
            "forward_tlDchannel": "replay_forward_tlDchannel[%s]" % w,
            "schedIndex": "replay_schedIndex[%s]" % w,
        }.get(f)
    m = re.match(r"^io_replay_(\d)_(valid|ready)$", name)
    if m:
        return "replay_%s[%s]" % (m.group(2), m.group(1))
    m = re.match(r"^io_vecFeedback_(\d)_(?:bits_)?(\w+)$", name)
    if m:
        w, f = m.group(1), m.group(2)
        return {
            "valid": "vecFb_valid[%s]" % w,
            "robidx_flag": "vecFb_robIdx[%s].flag" % w,
            "robidx_value": "vecFb_robIdx[%s].value" % w,
            "uopidx": "vecFb_uopIdx[%s]" % w,
            "feedback_0": "vecFb_isCommit[%s]" % w,
            "feedback_1": "vecFb_isFlush[%s]" % w,
        }.get(f)
    m = re.match(r"^io_storeAddrIn_(\d)_(?:bits_)?(\w+)$", name)
    if m:
        w, f = m.group(1), m.group(2)
        return {"valid": "staIn_valid[%s]" % w,
                "uop_sqIdx_flag": "staIn_sqIdx[%s].flag" % w,
                "uop_sqIdx_value": "staIn_sqIdx[%s].value" % w,
                "miss": "staIn_miss[%s]" % w}.get(f)
    m = re.match(r"^io_storeDataIn_(\d)_(?:bits_)?(\w+)$", name)
    if m:
        w, f = m.group(1), m.group(2)
        return {"valid": "stdIn_valid[%s]" % w,
                "uop_sqIdx_flag": "stdIn_sqIdx[%s].flag" % w,
                "uop_sqIdx_value": "stdIn_sqIdx[%s].value" % w}.get(f)
    m = re.match(r"^io_(stAddrReadyVec|stDataReadyVec)_(\d+)$", name)
    if m:
        return "%s[%s]" % (m.group(1), m.group(2))
    m = re.match(r"^io_perf_(\d+)_value$", name)
    if m:
        return "perf_value[%s]" % m.group(1)
    return {
        "clock": "clock", "reset": "reset",
        "io_redirect_valid": "redirect_valid",
        "io_redirect_bits_robIdx_flag": "redirect_robIdx.flag",
        "io_redirect_bits_robIdx_value": "redirect_robIdx.value",
        "io_redirect_bits_level": "redirect_level",
        "io_tl_d_channel_valid": "tl_d_valid",
        "io_tl_d_channel_mshrid": "tl_d_mshrid",
        "io_stAddrReadySqPtr_flag": "stAddrReadySqPtr.flag",
        "io_stAddrReadySqPtr_value": "stAddrReadySqPtr.value",
        "io_stDataReadySqPtr_flag": "stDataReadySqPtr.flag",
        "io_stDataReadySqPtr_value": "stDataReadySqPtr.value",
        "io_sqEmpty": "sqEmpty",
        "io_lqFull": "lqFull",
        "io_ldWbPtr_flag": "ldWbPtr.flag",
        "io_ldWbPtr_value": "ldWbPtr.value",
        "io_robDeqPtr_flag": "robDeqPtr.flag",
        "io_robDeqPtr_value": "robDeqPtr.value",
        "io_rarFull": "rarFull",
        "io_rawFull": "rawFull",
        "io_l2_hint_valid": "l2_hint_valid",
        "io_l2_hint_bits_sourceId": "l2_hint_sourceId",
        "io_l2_hint_bits_isKeyword": "l2_hint_isKeyword",
        "io_tlb_hint_resp_valid": "tlb_hint_valid",
        "io_tlb_hint_resp_bits_id": "tlb_hint_id",
        "io_tlb_hint_resp_bits_replay_all": "tlb_hint_replay_all",
        "io_debugTopDown_robHeadVaddr_valid": "dtd_robHeadVaddr_valid",
        "io_debugTopDown_robHeadVaddr_bits": "dtd_robHeadVaddr_bits",
        "io_debugTopDown_robHeadTlbReplay": "dtd_robHeadTlbReplay",
        "io_debugTopDown_robHeadTlbMiss": "dtd_robHeadTlbMiss",
        "io_debugTopDown_robHeadLoadVio": "dtd_robHeadLoadVio",
        "io_debugTopDown_robHeadLoadMSHR": "dtd_robHeadLoadMSHR",
        "io_debugTopDown_robHeadMissInDTlb": "dtd_robHeadMissInDTlb",
        "io_replayAllocate": "replayAllocate",
    }.get(name)


def gen_wrapper_body(ports, exc_bits, pay):
    """wrapper 内部：把扁平 io_* 打包成核的 struct/数组，例化核，再拆回输出。"""
    ins = [p for p in ports if p[0] == "input" and p[3] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("  // ---- 核侧信号（struct/数组）----")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_valid;")
    L.append("  lqr_uop_t [LD_PIPE_W-1:0]                        enq_uop;")
    L.append("  lqr_vec_t [LD_PIPE_W-1:0]                        enq_vec;")
    L.append("  logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]        enq_vaddr;")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_isLoadReplay;")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_handledByMSHR;")
    L.append("  logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0]       enq_schedIndex;")
    L.append("  logic     [LD_PIPE_W-1:0][N_CAUSES-1:0]          enq_cause;")
    L.append("  logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]         enq_mshr_id;")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_full_fwd;")
    L.append("  sq_ptr_t  [LD_PIPE_W-1:0]                        enq_data_inv_sq_idx;")
    L.append("  sq_ptr_t  [LD_PIPE_W-1:0]                        enq_addr_inv_sq_idx;")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_last_beat;")
    L.append("  logic     [LD_PIPE_W-1:0][TLB_ID_W-1:0]          enq_tlb_id;")
    L.append("  logic     [LD_PIPE_W-1:0]                        enq_tlb_full;")
    L.append("  logic     [LD_PIPE_W-1:0]                        replay_valid, replay_ready;")
    L.append("  lqr_uop_t [LD_PIPE_W-1:0]                        replay_uop;")
    L.append("  lqr_vec_t [LD_PIPE_W-1:0]                        replay_vec;")
    L.append("  logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]        replay_vaddr;")
    L.append("  logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]         replay_mshrid;")
    L.append("  logic     [LD_PIPE_W-1:0]                        replay_forward_tlDchannel;")
    L.append("  logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0]       replay_schedIndex;")
    L.append("  logic     [VEC_PIPE_W-1:0]                       vecFb_valid;")
    L.append("  rob_ptr_t [VEC_PIPE_W-1:0]                       vecFb_robIdx;")
    L.append("  logic     [VEC_PIPE_W-1:0][UOP_IDX_W-1:0]        vecFb_uopIdx;")
    L.append("  logic     [VEC_PIPE_W-1:0]                       vecFb_isCommit, vecFb_isFlush;")
    L.append("  logic     [ST_PIPE_W-1:0]                        staIn_valid, staIn_miss, stdIn_valid;")
    L.append("  sq_ptr_t  [ST_PIPE_W-1:0]                        staIn_sqIdx, stdIn_sqIdx;")
    L.append("  sq_ptr_t                                         stAddrReadySqPtr, stDataReadySqPtr;")
    L.append("  logic     [SQ_SIZE-1:0]                          stAddrReadyVec, stDataReadyVec;")
    L.append("  lq_ptr_t                                         ldWbPtr;")
    L.append("  rob_ptr_t                                        robDeqPtr;")
    L.append("  rob_ptr_t                                        redirect_robIdx;")
    L.append("  logic     [5:0]                                  perf_value [13];")
    L.append("  logic redirect_valid, redirect_level, tl_d_valid, sqEmpty, lqFull;")
    L.append("  logic [MSHR_ID_W-1:0] tl_d_mshrid, l2_hint_sourceId;")
    L.append("  logic rarFull, rawFull, l2_hint_valid, l2_hint_isKeyword;")
    L.append("  logic tlb_hint_valid, tlb_hint_replay_all;")
    L.append("  logic [TLB_ID_W-1:0] tlb_hint_id;")
    L.append("  logic dtd_robHeadVaddr_valid, dtd_robHeadMissInDTlb;")
    L.append("  logic [VADDR_BITS-1:0] dtd_robHeadVaddr_bits;")
    L.append("  logic dtd_robHeadTlbReplay, dtd_robHeadTlbMiss, dtd_robHeadLoadVio, dtd_robHeadLoadMSHR;")
    L.append("  logic replayAllocate;")
    L.append("")
    absent = [b for b in range(24) if b not in exc_bits]
    if absent:
        L.append("  // golden 在本配置里没有 exceptionVec bit %s 的入队端口（firtool 已消）。"
                 % ",".join(str(b) for b in absent))
        L.append("  // 钉 0 只为仿真不传 X：核里这几位从不被存、也从不被读，FM 前端直接剪除。")
        for w in range(LD_PIPE_W):
            for b in absent:
                L.append("  assign enq_uop[%d].exceptionVec[%d] = 1'b0;" % (w, b))
        L.append("")
    L.append("  // ---- 输入打包：golden 扁平端口 -> 核 struct/数组 ----")
    for d, msb, lsb, n in ins:
        sig = core_signal_for(n, exc_bits, pay)
        if sig is None:
            raise SystemExit("未映射的输入端口: " + n)
        L.append("  assign %s = %s;" % (sig, n))
    L.append("")
    L.append("  // ---- 核例化 ----")
    L.append("  xs_LoadQueueReplay_core u_core (.*);")
    L.append("")
    L.append("  // ---- 输出拆包：核 struct/数组 -> golden 扁平端口 ----")
    for d, msb, lsb, n in outs:
        sig = core_signal_for(n, exc_bits, pay)
        if sig is None:
            raise SystemExit("未映射的输出端口: " + n)
        L.append("  assign %s = %s;" % (n, sig))
    return L


# ---------------------------------------------------------------------------
#  生成：td_tree（ParallelOperation 平衡归约树）
# ---------------------------------------------------------------------------


def gen_td_tree(n_leaf):
    """复刻 chisel utility ParallelOperation 的**平衡二叉树**展开。

    ParallelOperation(xs, f) 按 `xs.splitAt(xs.size/2)` 递归切分，左右各自归约后
    再 f 合并。这跟左结合 fold 不是一回事：在两侧 robIdx 相同（平局）时，
    combine 走的分支不同，结果就会分叉。节点按「左子树全部 → 右子树全部 → 本节点」
    的后序编号，与上一轮手工展开的编号一致。
    """
    L = []
    counter = [0]

    def rec(lo, hi):
        if hi - lo == 1:
            idx = counter[0]
            counter[0] += 1
            L.append("    td_n[%d] = td_leaf[%d];" % (idx, lo))
            return idx
        mid = lo + (hi - lo) // 2
        a = rec(lo, mid)
        b = rec(mid, hi)
        idx = counter[0]
        counter[0] += 1
        L.append("    td_n[%d] = td_merge(td_n[%d], td_n[%d]);" % (idx, a, b))
        return idx

    root = rec(0, n_leaf)
    L.insert(0, "    // 平衡树共 %d 个节点（%d 叶 + %d 次 merge），根 = td_n[%d]"
             % (counter[0], n_leaf, counter[0] - n_leaf, root))
    return L


# ---------------------------------------------------------------------------
#  marker 原地替换
# ---------------------------------------------------------------------------


def splice(text, tag, body):
    b = "// BEGIN GENERATED(%s)" % tag
    e = "// END GENERATED"
    lines = text.split("\n")
    try:
        i = next(k for k, l in enumerate(lines) if l.strip() == b)
    except StopIteration:
        raise SystemExit("找不到 marker: " + b)
    j = next(k for k in range(i + 1, len(lines)) if lines[k].strip() == e)
    indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
    return "\n".join(lines[:i + 1] + body + [indent + e] + lines[j + 1:])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写；有差异 exit 1")
    a = ap.parse_args()

    lines = read_golden()
    ports = port_table(lines)
    widths, stored = uop_field_widths(lines, ports)
    order = []
    seen = set()
    pat = re.compile(r"^  reg\s+(?:\[\d+:\d+\]\s+)?uop_0_(\w+);")
    for l in lines:
        m = pat.match(l)
        if m and m.group(1) not in seen:
            seen.add(m.group(1))
            order.append(m.group(1))
    for f in sorted(set(widths) - seen):
        order.append(f)

    uf, exc_bits, pay = gen_uop_fields(widths, stored, order)
    wp = gen_wrapper_ports(ports)
    wb = gen_wrapper_body(ports, exc_bits, set(pay))
    tt = gen_td_tree(72)

    path = os.path.normpath(TARGET)
    with open(path) as f:
        text = f.read()
    new = text
    for tag, body in (("uop_fields", uf), ("td_tree", tt),
                      ("wrapper_ports", wp), ("wrapper_body", wb)):
        new = splice(new, tag, body)

    if a.check:
        if new != text:
            sys.stderr.write("GENERATED 区与 golden 派生结果不一致：请重跑 %s\n" % __file__)
            return 1
        print("gen_lqreplay: GENERATED 区与 golden 一致 (ports=%d uop_fields=%d exc_bits=%d)"
              % (len(ports), len(widths), len(exc_bits)))
        return 0
    with open(path, "w") as f:
        f.write(new)
    print("gen_lqreplay: 已写入 %s (ports=%d uop_fields=%d exc_bits=%d)"
          % (path, len(ports), len(widths), len(exc_bits)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
