#!/usr/bin/env python3
"""gen_missq.py —— DCache MissQueue 簇的机械派生区生成器（lane missq）。

只生成"没有微架构"的纯机械部分，手写区一个字节都不动：
  rtl/memblock/Arbiter16_MainPipeReq.sv
    arb16-ports   golden 端口表（逐字取 G1 golden，顺序/名字/位宽全同）
    arb16-ways    16 路字段拼包 + valid/ready 接线

端口表逐字取自 G1 golden 同名模块，生成时机械核对：
  (1) golden 端口集合 == 预期形状（16 路 × 14 字段 + ready/valid，输出 14 字段），多一个少一个都报错；
  (2) 生成结果与磁盘逐字节比较（--check）。

用法:
  scripts/gen_missq.py            # 写文件（内容不变不写，幂等）
  scripts/gen_missq.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.normpath(os.path.join(HERE, "..", "rtl", "memblock"))

PORT_RE = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行去逗号)]，顺序即 golden 顺序。"""
    lines = open(os.path.join(GOLDEN_DIR, module + ".sv")).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    for l in lines[start + 1:end]:
        m = PORT_RE.match(l)
        if not m:
            raise SystemExit("gen_missq: %s 端口行解析失败: %r" % (module, l))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip().rstrip(",")))
    return out


def port_block(module):
    """golden 端口表原文（去掉末行逗号规则由我们重排：除最后一行外都带逗号）。"""
    ps = port_table(module)
    return "\n".join(p[3] + ("," if i + 1 < len(ps) else "") for i, p in enumerate(ps))


def wrap_list(head, items, tail, width=100):
    """把 items 用逗号连成一串，超过 width 就折行，续行与首项对齐。"""
    lines, cur, pad = [], head, " " * len(head)
    for i, it in enumerate(items):
        piece = it + ("," if i + 1 < len(items) else tail)
        if cur.strip() and cur != head and len(cur) + 1 + len(piece) > width:
            lines.append(cur.rstrip())
            cur = pad + piece
        else:
            cur = cur + ("" if cur == head else " ") + piece
    lines.append(cur)
    return lines


def replace_region(text, tag, body):
    begin = "// BEGIN GENERATED(%s)" % tag
    end = "// END GENERATED"
    i = text.index(begin)
    j = text.index(end, i)
    line_start = text.rfind("\n", 0, i) + 1
    indent = text[line_start:i]
    return text[:i] + begin + "\n" + body + "\n" + indent + end + text[j + len(end):]


# ---------------------------------------------------------------------------
#  Arbiter16_MainPipeReq
# ---------------------------------------------------------------------------
ARB16 = "Arbiter16_MainPipeReq"
ARB16_FIELDS = [  # (字段名, 位宽)，顺序 = golden 输出端口顺序 = miss_refill_req_t 字段顺序
    ("miss_id", 4), ("occupy_way", 4), ("miss_fail_cause_evict_btot", 1), ("source", 4),
    ("cmd", 5), ("vaddr", 50), ("addr", 48), ("word_idx", 3), ("amo_data", 128),
    ("amo_mask", 16), ("amo_cmp", 128), ("pf_source", 3), ("access", 1), ("id", 6),
]
ARB16_N = 16


def arb16_expected_ports():
    exp = []
    for k in range(ARB16_N):
        exp.append(("output", 1, "io_in_%d_ready" % k))
        exp.append(("input", 1, "io_in_%d_valid" % k))
        exp += [("input", w, "io_in_%d_bits_%s" % (k, f)) for f, w in ARB16_FIELDS]
    exp.append(("input", 1, "io_out_ready"))
    exp.append(("output", 1, "io_out_valid"))
    exp += [("output", w, "io_out_bits_%s" % f) for f, w in ARB16_FIELDS]
    return exp


def gen_arb16_file():
    got = [(d, w, n) for d, w, n, _ in port_table(ARB16)]
    if got != arb16_expected_ports():
        raise SystemExit("gen_missq: %s golden 端口表与预期形状不一致" % ARB16)
    ports = port_block(ARB16)
    o = []
    for k in range(ARB16_N):
        o += wrap_list("  assign way_req[%d] = {" % k,
                       ["io_in_%d_bits_%s" % (k, f) for f, _ in ARB16_FIELDS], "};")
    o.append("  assign in_valid_vec = {%s};" % ", ".join("io_in_%d_valid" % k for k in range(ARB16_N)))
    for k in range(ARB16_N):
        o.append("  assign io_in_%d_ready = in_ready_vec[%d];" % (k, ARB16_N - 1 - k))
    path = os.path.join(RTL, ARB16 + ".sv")
    text = open(path).read()
    text = replace_region(text, "arb16-ports", ports)
    text = replace_region(text, "arb16-ways", "\n".join(o))
    return path, text


# ---------------------------------------------------------------------------
#  MissEntry wrapper：golden 扁平端口 <-> 核的结构体端口
# ---------------------------------------------------------------------------
# 规则表逐项写死；生成时核对：每个 golden 端口恰好被一条规则绑定（不多不少）、
# 方向与位宽逐个与规则一致。任何一条对不上就生成失败（fail-closed）。
ME = "MissEntry"

# (wrapper 里的结构体信号, 类型, golden 端口前缀, 方向, [(字段, golden 后缀, 位宽)])
ME_STRUCTS = [
    ("req_s", "query_req_t", "io_req_bits_", "input",
     [("source", "source", 4), ("addr", "addr", 48), ("vaddr", "vaddr", 50)]),
] + [
    ("query_s[%d]" % q, None, "io_queryME_%d_req_bits_" % q, "input",
     [("source", "source", 4), ("addr", "addr", 48), ("vaddr", "vaddr", 50)]) for q in range(4)
] + [
    ("pipe_s", "pipe_req_t", "io_miss_req_pipe_reg_req_", "input",
     [("source", "source", 4), ("pf_source", "pf_source", 3), ("cmd", "cmd", 5),
      ("addr", "addr", 48), ("vaddr", "vaddr", 50), ("full_overwrite", "full_overwrite", 1),
      ("word_idx", "word_idx", 3), ("amo_data", "amo_data", 128), ("amo_mask", "amo_mask", 16),
      ("amo_cmp", "amo_cmp", 128), ("req_coh_state", "req_coh_state", 2), ("id", "id", 6),
      ("isBtoT", "isBtoT", 1), ("occupy_way", "occupy_way", 4),
      ("store_data", "store_data", 512), ("store_mask", "store_mask", 64)]),
    ("grant_s", "grant_t", "io_mem_grant_bits_", "input",
     [("opcode", "opcode", 4), ("param", "param", 2), ("size", "size", 3), ("sink", "sink", 10),
      ("denied", "denied", 1), ("data", "data", 256), ("corrupt", "corrupt", 1)]),
    ("acq_s", "acquire_t", "io_mem_acquire_bits_", "output",
     [("opcode", "opcode", 4), ("param", "param", 3), ("source", "source", 6),
      ("address", "address", 48), ("user_alias", "user_alias", 2), ("user_vaddr", "user_vaddr", 44),
      ("user_reqSource", "user_reqSource", 5), ("user_needHint", "user_needHint", 1),
      ("echo_isKeyword", "echo_isKeyword", 1)]),
    ("ldq_s", "refill_ldq_t", "io_refill_to_ldq_bits_", "output",
     [("addr", "addr", 48), ("data", "data", 256), ("error", "error", 1),
      ("data_raw", "data_raw", 512), ("hasdata", "hasdata", 1), ("refill_done", "refill_done", 1),
      ("id", "id", 4)]),
    ("mp_s", "mp_req_t", "io_main_pipe_req_bits_", "output",
     [(f, f, w) for f, w in [
         ("miss_id", 4), ("occupy_way", 4), ("miss_fail_cause_evict_btot", 1), ("source", 4),
         ("cmd", 5), ("vaddr", 50), ("addr", 48), ("word_idx", 3), ("amo_data", 128),
         ("amo_mask", 16), ("amo_cmp", 128), ("pf_source", 3), ("access", 1), ("id", 6)]]),
    ("info_s", "refill_info_t", "io_refill_info_bits_", "output",
     [("store_data", "store_data", 512), ("miss_param", "miss_param", 2),
      ("tl_denied", "error_tl_denied", 1), ("tl_corrupt", "error_tl_corrupt", 1)]),
    ("fwd_s", "fwd_info_t", "io_forwardInfo_", "output",
     [("inflight", "inflight", 1), ("paddr", "paddr", 48)] +
     [("raw_data[%d]" % i, "raw_data_%d" % i, 64) for i in range(8)] +
     [("firstbeat_valid", "firstbeat_valid", 1), ("lastbeat_valid", "lastbeat_valid", 1),
      ("denied", "denied", 1), ("corrupt", "corrupt", 1)]),
]

# 标量/向量端口：(核端口, wrapper 表达式或 golden 端口, golden 端口, 方向, 位宽)
ME_VEC = {  # 核的向量端口 -> 每个元素绑到的 golden 端口
    "query_primary_ready":    ["io_queryME_%d_primary_ready" % q for q in range(4)],
    "query_secondary_ready":  ["io_queryME_%d_secondary_ready" % q for q in range(4)],
    "query_secondary_reject": ["io_queryME_%d_secondary_reject" % q for q in range(4)],
    "latency_refilling":      ["io_latency_monitor_%s_miss_refilling" % k
                               for k in ("load", "store", "amo", "pf")],
}
ME_SCALARS = [  # (核端口, golden 端口)
    ("clock", "clock"), ("reset", "reset"), ("id", "io_id"),
    ("req_valid", "io_req_valid"), ("req_cancel", "io_req_bits_cancel"),
    ("wbq_block_miss_req", "io_wbq_block_miss_req"), ("primary_valid", "io_primary_valid"),
    ("primary_ready", "io_primary_ready"), ("secondary_ready", "io_secondary_ready"),
    ("secondary_reject", "io_secondary_reject"), ("req_handled", "io_req_handled_by_this_entry"),
    ("pipe_alloc", "io_miss_req_pipe_reg_alloc"), ("pipe_merge", "io_miss_req_pipe_reg_merge"),
    ("pipe_cancel", "io_miss_req_pipe_reg_cancel"),
    ("acquire_fired_by_pipe_reg", "io_acquire_fired_by_pipe_reg"),
    ("acquire_ready", "io_mem_acquire_ready"), ("acquire_valid", "io_mem_acquire_valid"),
    ("grant_valid", "io_mem_grant_valid"),
    ("finish_ready", "io_mem_finish_ready"), ("finish_valid", "io_mem_finish_valid"),
    ("finish_sink", "io_mem_finish_bits_sink"), ("l2_hint_valid", "io_l2_hint_valid"),
    ("mp_req_ready", "io_main_pipe_req_ready"), ("mp_req_valid", "io_main_pipe_req_valid"),
    ("mp_resp", "io_main_pipe_resp"), ("mp_refill_resp", "io_main_pipe_refill_resp"),
    ("mp_replay", "io_main_pipe_replay"), ("mp_evict_BtoT_way", "io_main_pipe_evict_BtoT_way"),
    ("mp_next_evict_way", "io_main_pipe_next_evict_way"),
    ("refill_info_valid", "io_refill_info_valid"), ("refill_ldq_valid", "io_refill_to_ldq_valid"),
    ("probe_addr", "io_probe_req_bits_addr"), ("probe_vaddr", "io_probe_req_bits_vaddr"),
    ("probe_block", "io_probe_block"),
    ("replace_addr", "io_replace_req_bits_addr"), ("replace_vaddr", "io_replace_req_bits_vaddr"),
    ("replace_block", "io_replace_block"), ("occupy_way", "io_occupy_way"),
    ("req_vaddr_valid", "io_req_vaddr_valid"), ("req_vaddr_bits", "io_req_vaddr_bits"),
    ("req_isBtoT", "io_req_isBtoT"), ("l2_pf_store_only", "io_l2_pf_store_only"),
    ("memSetPattenDetected", "io_memSetPattenDetected"),
    ("rob_head_vaddr", "io_rob_head_query_vaddr"),
    ("rob_head_query_valid", "io_rob_head_query_query_valid"),
    ("rob_head_resp", "io_rob_head_query_resp"),
    ("perf_pending_prefetch", "io_perf_pending_prefetch"),
    ("perf_pending_normal", "io_perf_pending_normal"),
    ("late_prefetch", "io_prefetch_info_late_prefetch"), ("matched", "io_matched"),
    ("l1Miss", "io_l1Miss"), ("wfi_req", "io_wfi_wfiReq"), ("wfi_safe", "io_wfi_wfiSafe"),
]
# 核端口 -> wrapper 里的结构体信号（ME_STRUCTS 的第一列去掉下标）
ME_STRUCT_PORTS = [("req", "req_s"), ("query_req", "query_s"), ("pipe", "pipe_s"),
                   ("grant", "grant_s"), ("acquire", "acq_s"), ("refill_ldq", "ldq_s"),
                   ("mp_req", "mp_s"), ("refill_info", "info_s"), ("fwd", "fwd_s")]


def gen_missentry_file():
    gp = {n: (d, w) for d, w, n, _ in port_table(ME)}
    bound = {}

    def bind(port, d, w, why):
        if port not in gp:
            raise SystemExit("gen_missq: %s 规则 %s 绑定了不存在的 golden 端口 %s" % (ME, why, port))
        if gp[port] != (d, w):
            raise SystemExit("gen_missq: %s 端口 %s 方向/位宽 golden=%s 规则=%s" % (ME, port, gp[port], (d, w)))
        if port in bound:
            raise SystemExit("gen_missq: %s 端口 %s 被两条规则绑定（%s / %s）" % (ME, port, bound[port], why))
        bound[port] = why

    body = []
    body.append("  // ---- 结构体信号（golden 扁平端口在这里拆装）----")
    decl = {"req_s": "query_req_t       req_s;", "query_s": "query_req_t [3:0] query_s;",
            "pipe_s": "pipe_req_t        pipe_s;", "grant_s": "grant_t           grant_s;",
            "acq_s": "acquire_t         acq_s;", "ldq_s": "refill_ldq_t      ldq_s;",
            "mp_s": "mp_req_t          mp_s;", "info_s": "refill_info_t     info_s;",
            "fwd_s": "fwd_info_t        fwd_s;"}
    for k in ("req_s", "query_s", "pipe_s", "grant_s", "acq_s", "ldq_s", "mp_s", "info_s", "fwd_s"):
        body.append("  " + decl[k])
    for k, ports in ME_VEC.items():
        body.append("  logic [%d:0] %s_s;" % (len(ports) - 1, k))
    body.append("")
    for sig, _t, pre, d, fields in ME_STRUCTS:
        for f, suf, w in fields:
            port = pre + suf
            bind(port, d, w, "%s.%s" % (sig, f))
            if d == "input":
                body.append("  assign %s.%s = %s;" % (sig, f, port))
            else:
                body.append("  assign %s = %s.%s;" % (port, sig, f))
    for k, ports in ME_VEC.items():
        for i, port in enumerate(ports):
            d = gp.get(port, ("?",))[0]
            bind(port, d, 1, "%s[%d]" % (k, i))
            body.append("  assign %s = %s_s[%d];" % (port, k, i))
    for cp, port in ME_SCALARS:
        d, w = gp.get(port, ("?", 0))
        bind(port, d, w, cp)
    missing = [n for n in gp if n not in bound]
    if missing:
        raise SystemExit("gen_missq: %s 有 %d 个 golden 端口没有规则绑定：%s" % (ME, len(missing), missing[:8]))
    body.append("")
    conns = [(cp, port) for cp, port in ME_SCALARS]
    conns += [(cp, sig) for cp, sig in ME_STRUCT_PORTS]
    conns += [(k, k + "_s") for k in ME_VEC]
    body.append("  xs_MissEntry_core u_core (")
    width = max(len(c) for c, _ in conns)
    for i, (cp, sig) in enumerate(conns):
        body.append("    .%-*s (%s)%s" % (width, cp, sig, "," if i + 1 < len(conns) else ""))
    body.append("  );")

    path = os.path.join(RTL, ME + ".sv")
    text = open(path).read()
    text = replace_region(text, "missentry-ports", port_block(ME))
    text = replace_region(text, "missentry-body", "\n".join(body))
    return path, text


# ---------------------------------------------------------------------------
#  MissEntry 的 FM「匹配前」钉点（verif/ut/MissEntry/fm_pins_pre.tcl）
# ---------------------------------------------------------------------------
# 只消命名差，不约束 ref、不改 appvar、不加黑盒。两类寄存器 FM 自己配不准：
#   (a) 值恒等的多份打拍（每个请求口各一份 RegNext(primary_fire) / RegNext(id>=2)，
#       四份延迟秒表）：签名完全相同，FM 会配错或配不上（lane 内首跑 10(10) unmatched，
#       下游 7 个 failing）；
#   (b) 只为断言/性能计数存在的死寄存器：没有扇出锥，名字又不同，签名分析配不上。
# 配对表逐项写死（golden 名 -> 核里的寄存器元素），多位寄存器逐位展开；
# 生成时核对：golden 侧名字确是 golden MissEntry 里声明的寄存器且位宽一致、两侧都一对一。
ME_PINS = [  # (golden 寄存器, 位宽, 核里的寄存器（不含 _reg 后缀）)
    # (a) 每个请求口一份的打拍：[0]=main 口，[1..4]=queryME 0..3
    ("last_REG", 1, "prefetch_slot_q[0]"),
    ("io_primary_ready_last_REG", 1, "prim_fire_q_slot[0]"),
    ("io_primary_ready_last_REG_1", 1, "prim_fire_q_other[0]"),
] + [x for q in range(4) for x in (
    ("last_REG_%d" % (q + 1), 1, "prefetch_slot_q[%d]" % (q + 1)),
    ("io_queryME_%d_primary_ready_last_REG" % q, 1, "prim_fire_q_slot[%d]" % (q + 1)),
    ("io_queryME_%d_primary_ready_last_REG_1" % q, 1, "prim_fire_q_other[%d]" % (q + 1)))
] + [
    ("start_counting_last_REG", 1, "acq_fire_q"),
    ("start_counting_last_REG_1", 1, "prim_fire_dly[0]"),
    ("start_counting_last_REG_2", 1, "prim_fire_dly[1]"),
    ("io_latency_monitor_load_miss_refilling_r", 1, "lat_watch_q[0]"),
    ("io_latency_monitor_store_miss_refilling_r", 1, "lat_watch_q[1]"),
    ("io_latency_monitor_amo_miss_refilling_r", 1, "lat_watch_q[2]"),
    ("io_latency_monitor_pf_miss_refilling_r", 1, "lat_watch_q[3]"),
    # (b) 断言打拍 / 性能计数
    ("REG", 1, "chk_primary_valid_not_ready"),
    ("REG_1", 1, "chk_primary_fire_d1"),
    ("REG_2", 1, "chk_secondary_fire_d1"),
    ("REG_3", 1, "chk_primary_fire_m1"),
    ("REG_4", 1, "chk_primary_fire_m2"),
    ("REG_5", 1, "chk_ready_onehot"),
    ("REG_6", 1, "chk_grant_is_request"),
    ("REG_7", 1, "w_grantlast_d1"),
    ("r", 1, "perf_load_penalty_watch"),
    ("r_3", 1, "perf_grantlast_release_watch"),
    ("r_4", 1, "perf_mainpipe_watch"),
    ("last_REG_5", 1, "perf_prim_fire_dly[0]"),
    ("last_REG_6", 1, "perf_prim_fire_dly[1]"),
    ("refill_finished_last_REG", 1, "perf_refill_finished_d1"),
    ("last_REG_7", 1, "perf_last_beat_d1"),
    ("counter", 64, "perf_mshr_penalty"),
    ("counter_1", 64, "perf_load_miss_penalty"),
    ("counter_2", 64, "perf_a_to_d_penalty"),
]


def golden_regs(module):
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    out = {}
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out[n] = int(a) - int(b) + 1 if a else 1
    return out


def fm_pin_tcl(top, tag, pins, impl_root, why_lines, ref_module=None):
    """钉点 tcl：每条 set_user_match 必须返回 1，总数必须等于字面整数（fail-closed）。

    pins = [(golden 寄存器, 位宽, 核里的寄存器)]；golden 寄存器可带实例前缀 "entries_3/REG"，
    此时位宽按该实例的 golden 模块（ref_module(前缀)）核对；核里的寄存器可带实例前缀 "u_acq_arb/state[3]"。"""
    seen_r, seen_i, pairs = set(), set(), []
    reg_cache = {}
    for g, w, core in pins:
        gpre, gname = g.rsplit("/", 1) if "/" in g else ("", g)
        mod = top if not gpre else ref_module(gpre)
        regs = reg_cache.setdefault(mod, golden_regs(mod))
        gm = re.fullmatch(r"(\w+)(?:\[(\d+)\])?", gname)
        if gm.group(2) is not None:
            # 单独钉某一位：golden 寄存器须存在且该位在范围内，表里位宽写 1
            if w != 1 or regs.get(gm.group(1), 0) <= int(gm.group(2)):
                raise SystemExit("gen_missq: %s 钉点 golden 位 %s 越界/位宽不是 1" % (top, g))
        elif regs.get(gname) != w:
            raise SystemExit("gen_missq: %s 钉点 golden 寄存器 %s 位宽 golden=%s 表=%d" % (top, g, regs.get(gname), w))
        if g in seen_r or core in seen_i:
            raise SystemExit("gen_missq: %s 钉点重复：%s / %s" % (top, g, core))
        seen_r.add(g)
        seen_i.add(core)
        # 核的数组元素：a[3] -> a_reg[3]（可带实例前缀）
        cpre, cname = core.rsplit("/", 1) if "/" in core else ("", core)
        m = re.fullmatch(r"(\w+)((?:\.\w+)?)((?:\[\d+\])*)", cname)
        base = (cpre + "/" if cpre else "") + m.group(1)
        # 结构体成员在 FM 里叫 reg\[field]（MainPipe 钉点同写法）
        field = "\\\\\\[%s\\]" % m.group(2)[1:] if m.group(2) else ""
        idx = m.group(3).replace("[", "\\[").replace("]", "\\]")
        gbase, gbit = (gm.group(1), gm.group(2))
        for b in range(w):
            if gbit is not None:
                rp = "$r/%s%s_reg\\[%s\\]" % (gpre + "/" if gpre else "", gbase, gbit)
            else:
                rp = "$r/%s_reg" % g + ("\\[%d\\]" % b if w > 1 else "")
            ip = "$i/%s_reg" % base + field + idx + ("\\[%d\\]" % b if w > 1 else "")
            pairs.append((rp, ip))
    n = len(pairs)
    o = ["# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_missq.py（勿手改）" % top, "#"]
    o += ["# " + l for l in why_lines]
    o += ["# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。",
          "# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error（safe interp 里不用 exit）。",
          "# 进 fm.log 的输出一律 ASCII。",
          "proc _%s_pre_pin { } {" % tag,
          "    set _expect %d" % n,
          "    set r \"r:/WORK/%s\"" % top,
          "    set i \"i:/WORK/%s\"" % (top + ("/" + impl_root if impl_root else "")),
          "    set pairs [list \\"]
    width = max(len(a) for a, _ in pairs)
    for k, (a, b) in enumerate(pairs):
        o.append("        \"%s\"%s \"%s\"%s" % (a, " " * (width - len(a)), b,
                                                " ]" if k + 1 == n else " \\"))
    o += ["    puts \"%s_PREPIN_BEGIN %s expect=$_expect\"" % (tag.upper(), top),
          "    set n 0",
          "    foreach {rp ip} $pairs {",
          "        if {![set_user_match $rp $ip]} {",
          "            puts \"%s_PREPIN_FAIL: set_user_match returned 0 for $rp <-> $ip\"" % tag.upper(),
          "            error \"%s_PREPIN_MISS=$rp\"" % tag.upper(),
          "        }",
          "        incr n",
          "    }",
          "    puts \"%s_PREPIN_END %s n=$n expect=$_expect\"" % (tag.upper(), top),
          "    if {$n != $_expect} {",
          "        puts \"%s_PREPIN_ERROR: pinned $n but expected $_expect\"" % tag.upper(),
          "        error \"%s_PREPIN_COUNT=$n\"" % tag.upper(),
          "    }",
          "}",
          "_%s_pre_pin" % tag]
    return "\n".join(o) + "\n"


def gen_missentry_pins():
    path = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "MissEntry", "fm_pins_pre.tcl"))
    why = ["对象：(a) 值恒等的多份打拍（每个请求口一份 RegNext(primary_fire)/RegNext(id>=2)、",
           "四份延迟秒表）—— 签名相同，首跑（lane 内 diagnostic）10(10) unmatched + 下游 7 failing；",
           "(b) 只喂断言/性能计数的死寄存器（REG_*、r_*、counter*）—— 无扇出、名字不同。",
           "配对依据见 scripts/gen_missq.py 的 ME_PINS（逐项写死，不猜名字）。"]
    return path, fm_pin_tcl("MissEntry", "me", ME_PINS, "u_core", why)


# ---------------------------------------------------------------------------
#  MissQueue wrapper：golden 端口表 + 核 + 16 个 MissEntry + CMOUnit + Arbiter16 的全部连线
# ---------------------------------------------------------------------------
# 规则逐项写死；生成时核对：
#   (1) MissQueue 的每个 golden **输出**端口恰好被驱动一次，每个**输入**端口至少被用到一次；
#   (2) MissEntry / CMOUnit / Arbiter16_MainPipeReq 的每个 golden 端口恰好一条连线规则
#       （MissEntry 有 9 个输出 golden 父级也不读，显式列为悬空）；
#   (3) 结构体字段与 golden 端口位宽逐个相等。
MQ = "MissQueue"
NE, NQ, NL = 16, 4, 3

MQ_REQ_FIELDS = [("source", 4), ("pf_source", 3), ("cmd", 5), ("addr", 48), ("vaddr", 50),
                 ("full_overwrite", 1), ("word_idx", 3), ("amo_data", 128), ("amo_mask", 16),
                 ("amo_cmp", 128), ("req_coh_state", 2), ("id", 6), ("isBtoT", 1),
                 ("occupy_way", 4), ("store_data", 512), ("store_mask", 64)]
MQ_A_FIELDS = [("opcode", 4), ("param", 3), ("size", 3), ("source", 6), ("address", 48),
               ("user_alias", 2), ("user_vaddr", 44), ("user_reqSource", 5), ("user_needHint", 1),
               ("echo_isKeyword", 1), ("mask", 32)]
MQ_ENT_A_FIELDS = [f for f in MQ_A_FIELDS if f[0] not in ("size", "mask")]
MQ_D_FIELDS = [("opcode", 4), ("param", 2), ("size", 3), ("source", 6), ("sink", 10),
               ("denied", 1), ("data", 256), ("corrupt", 1)]
MQ_INFO_FIELDS = [("s2_valid", 1), ("s2_miss_id", 4), ("s2_replay_to_mq", 1),
                  ("s2_evict_BtoT_way", 1), ("s2_next_evict_way", 4), ("s3_valid", 1),
                  ("s3_miss_id", 4), ("s3_refill_resp", 1)]
MQ_MP_FIELDS = ARB16_FIELDS
MQ_ENT_INFO = [("store_data", "store_data", 512), ("miss_param", "miss_param", 2),
               ("tl_denied", "error_tl_denied", 1), ("tl_corrupt", "error_tl_corrupt", 1)]
MQ_ENT_FWD = ([("inflight", "inflight", 1), ("paddr", "paddr", 48)] +
              [("raw_data[%d]" % j, "raw_data_%d" % j, 64) for j in range(8)] +
              [("firstbeat_valid", "firstbeat_valid", 1), ("lastbeat_valid", "lastbeat_valid", 1),
               ("denied", "denied", 1), ("corrupt", "corrupt", 1)])


def rng_decl(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


def missentry_bind(i):
    """MissEntry 端口 -> wrapper 表达式（None = 悬空的输出）。每个端口恰好一条。"""
    b = {"clock": "clock", "reset": "reset", "io_id": "4'd%d" % i,
         "io_req_valid": "io_req_valid", "io_req_bits_cancel": "io_req_bits_cancel",
         "io_wbq_block_miss_req": "io_wbq_block_miss_req",
         "io_miss_req_pipe_reg_merge": "ent_pipe_merge[%d]" % i,
         "io_miss_req_pipe_reg_alloc": "ent_pipe_alloc[%d]" % i,
         "io_miss_req_pipe_reg_cancel": "pipe_cancel_s",
         "io_primary_valid": "ent_primary_valid[%d]" % i,
         "io_primary_ready": "ent_primary_ready[%d]" % i,
         "io_secondary_ready": "ent_secondary_ready[%d]" % i,
         "io_secondary_reject": "ent_secondary_reject[%d]" % i,
         "io_mem_acquire_ready": "ent_acq_ready[%d]" % i,
         "io_mem_acquire_valid": "ent_acq_valid[%d]" % i,
         "io_mem_grant_valid": "ent_grant_valid[%d]" % i,
         "io_mem_finish_ready": "ent_finish_ready[%d]" % i,
         "io_mem_finish_valid": "ent_finish_valid[%d]" % i,
         "io_mem_finish_bits_sink": "ent_finish_sink[%d]" % i,
         "io_refill_to_ldq_valid": "ent_ldq_valid[%d]" % i,
         "io_refill_to_ldq_bits_addr": "ent_ldq_addr[%d]" % i,
         "io_refill_to_ldq_bits_data_raw": "ent_ldq_data_raw[%d]" % i,
         "io_refill_to_ldq_bits_hasdata": "ent_ldq_hasdata[%d]" % i,
         "io_refill_to_ldq_bits_refill_done": "ent_ldq_refill_done[%d]" % i,
         "io_l2_hint_valid": "ent_l2_hint_valid[%d]" % i,
         "io_main_pipe_req_ready": "arb_in_ready[%d]" % i,
         "io_main_pipe_req_valid": "ent_mp_valid[%d]" % i,
         "io_main_pipe_resp": "ent_mp_resp[%d]" % i,
         "io_main_pipe_refill_resp": "ent_mp_refill_resp[%d]" % i,
         "io_main_pipe_replay": "ent_mp_replay[%d]" % i,
         "io_main_pipe_evict_BtoT_way": "ent_mp_evict_BtoT_way[%d]" % i,
         "io_main_pipe_next_evict_way": "io_mainpipe_info_s2_next_evict_way",
         "io_refill_info_valid": "ent_refill_info_valid[%d]" % i,
         "io_occupy_way": "ent_occupy_way[%d]" % i,
         "io_probe_req_bits_addr": "io_probe_req_bits_addr",
         "io_probe_req_bits_vaddr": "io_probe_req_bits_vaddr",
         "io_probe_block": "ent_probe_block[%d]" % i,
         "io_replace_req_bits_addr": "io_replace_req_bits_addr",
         "io_replace_req_bits_vaddr": "io_replace_req_bits_vaddr",
         "io_replace_block": "ent_replace_block[%d]" % i,
         "io_req_vaddr_valid": "ent_vaddr_valid[%d]" % i,
         "io_req_vaddr_bits": "ent_vaddr[%d]" % i,
         "io_req_isBtoT": "ent_isBtoT[%d]" % i,
         "io_req_handled_by_this_entry": "ent_req_handled[%d]" % i,
         "io_l2_pf_store_only": "io_l2_pf_store_only",
         "io_acquire_fired_by_pipe_reg": "acquire_fired_by_pipe_reg_s",
         "io_memSetPattenDetected": "memset_pattern_detected_s",
         "io_rob_head_query_vaddr": "io_debugTopDown_robHeadVaddr_bits",
         "io_rob_head_query_query_valid": "io_debugTopDown_robHeadVaddr_valid",
         "io_rob_head_query_resp": "ent_rob_head_resp[%d]" % i,
         "io_prefetch_info_late_prefetch": "ent_late_prefetch[%d]" % i,
         "io_matched": "ent_matched[%d]" % i,
         "io_l1Miss": "ent_l1Miss[%d]" % i,
         "io_wfi_wfiReq": "io_wfi_wfiReq",
         "io_wfi_wfiSafe": "ent_wfi_safe[%d]" % i}
    # golden 父级不读的输出：悬空
    for n in ("io_refill_to_ldq_bits_data", "io_refill_to_ldq_bits_error", "io_refill_to_ldq_bits_id",
              "io_perf_pending_prefetch", "io_perf_pending_normal",
              "io_latency_monitor_load_miss_refilling", "io_latency_monitor_store_miss_refilling",
              "io_latency_monitor_amo_miss_refilling", "io_latency_monitor_pf_miss_refilling"):
        b[n] = None
    for f in ("source", "addr", "vaddr"):
        b["io_req_bits_" + f] = "io_req_bits_" + f
        for q in range(NQ):
            b["io_queryME_%d_req_bits_%s" % (q, f)] = "io_queryMQ_%d_req_bits_%s" % (q, f)
    for q in range(NQ):
        for k in ("primary_ready", "secondary_ready", "secondary_reject"):
            b["io_queryME_%d_%s" % (q, k)] = "ent_query_%s[%d][%d]" % (k, i, q)
    for f, _ in MQ_REQ_FIELDS:
        b["io_miss_req_pipe_reg_req_" + f] = "pipe_s." + f
    for f, _ in MQ_ENT_A_FIELDS:
        b["io_mem_acquire_bits_" + f] = "ent_acq[%d].%s" % (i, f)
    for f, _ in MQ_D_FIELDS:
        if f != "source":
            b["io_mem_grant_bits_" + f] = "io_mem_grant_bits_" + f
    for f, _ in MQ_MP_FIELDS:
        b["io_main_pipe_req_bits_" + f] = "ent_mp_%s[%d]" % (f, i)
    for f, suf, _ in MQ_ENT_INFO:
        b["io_refill_info_bits_" + suf] = "ent_refill_info[%d].%s" % (i, f)
    for f, suf, _ in MQ_ENT_FWD:
        b["io_forwardInfo_" + suf] = "ent_fwd[%d].%s" % (i, f)
    return b


def cmo_bind():
    return {"clock": "clock", "reset": "reset",
            "io_req_ready": "io_cmo_req_ready", "io_req_valid": "io_cmo_req_valid",
            "io_req_bits_opcode": "io_cmo_req_bits_opcode", "io_req_bits_address": "io_cmo_req_bits_address",
            "io_req_chanA_ready": "cmo_a_ready_s", "io_req_chanA_valid": "cmo_a_valid_s",
            "io_req_chanA_bits_opcode": "cmo_a_opcode_s", "io_req_chanA_bits_address": "cmo_a_address_s",
            "io_resp_chanD_ready": "cmo_d_ready_s", "io_resp_chanD_valid": "cmo_d_valid_s",
            "io_resp_chanD_bits_denied": "io_mem_grant_bits_denied",
            "io_resp_chanD_bits_corrupt": "io_mem_grant_bits_corrupt",
            "io_resp_to_lsq_ready": "io_cmo_resp_ready", "io_resp_to_lsq_valid": "io_cmo_resp_valid",
            "io_resp_to_lsq_bits_denied": "io_cmo_resp_bits_denied",
            "io_resp_to_lsq_bits_corrupt": "io_cmo_resp_bits_corrupt",
            "io_wfi_wfiReq": "io_wfi_wfiReq", "io_wfi_wfiSafe": "cmo_wfi_safe_s"}


def arb_bind():
    b = {"io_out_ready": "io_main_pipe_req_ready", "io_out_valid": "arb_out_valid_s"}
    for i in range(NE):
        b["io_in_%d_ready" % i] = "arb_in_ready[%d]" % i
        b["io_in_%d_valid" % i] = "ent_mp_valid[%d]" % i
        for f, _ in MQ_MP_FIELDS:
            b["io_in_%d_bits_%s" % (i, f)] = "ent_mp_%s[%d]" % (f, i)
    for f, _ in MQ_MP_FIELDS:
        b["io_out_bits_" + f] = "io_main_pipe_req_bits_" + f
    return b


# 核端口 -> wrapper 表达式（核端口表手写在 MissQueue.sv 里；这里只管连线）
def core_bind():
    c = [("clock", "clock"), ("reset", "reset"), ("hartId", "io_hartId"),
         ("req_valid", "io_req_valid"), ("req", "req_s"), ("req_cancel", "io_req_bits_cancel"),
         ("req_ready", "io_req_ready"), ("resp_id", "io_resp_id"),
         ("resp_handled", "io_resp_handled"), ("resp_merged", "io_resp_merged"),
         ("wbq_block_miss_req", "io_wbq_block_miss_req"),
         ("query_req", "query_s"), ("query_ready", "query_ready_s"),
         ("acq_ready", "io_mem_acquire_ready"), ("acq_valid", "io_mem_acquire_valid"),
         ("acq", "acq_s"), ("grant_valid", "io_mem_grant_valid"), ("grant", "grant_s"),
         ("grant_ready", "io_mem_grant_ready"), ("finish_ready", "io_mem_finish_ready"),
         ("finish_valid", "io_mem_finish_valid"), ("finish_sink", "io_mem_finish_bits_sink"),
         ("l2_hint_valid", "io_l2_hint_valid"), ("l2_hint_source_id", "io_l2_hint_bits_sourceId"),
         ("mp_req_out_valid", "arb_out_valid_s"), ("mp_req_out_ready", "io_main_pipe_req_ready"),
         ("mp_resp_valid", "io_main_pipe_resp_valid"),
         ("mp_resp_miss_id", "io_main_pipe_resp_bits_miss_id"),
         ("mp_resp_ack_miss_queue", "io_main_pipe_resp_bits_ack_miss_queue"),
         ("mp_info", "mp_info_s"),
         ("refill_info_valid", "io_refill_info_valid"),
         ("refill_info_store_data", "io_refill_info_bits_store_data"),
         ("refill_info_store_mask", "io_refill_info_bits_store_mask"),
         ("refill_info_miss_param", "io_refill_info_bits_miss_param"),
         ("refill_info_tl_denied", "io_refill_info_bits_error_tl_denied"),
         ("refill_info_tl_corrupt", "io_refill_info_bits_error_tl_corrupt"),
         ("probe_block", "io_probe_block"),
         ("replace_addr", "io_replace_req_bits_addr"), ("replace_vaddr", "io_replace_req_bits_vaddr"),
         ("replace_block", "io_replace_block"), ("evict_set", "io_evict_set"),
         ("btot_ways_for_set", "io_btot_ways_for_set"),
         ("occupy_set", "occupy_set_s"), ("occupy_fail", "occupy_fail_s"),
         ("fwd_valid", "fwd_valid_s"), ("fwd_mshrid", "fwd_mshrid_s"), ("fwd_paddr", "fwd_paddr_s"),
         ("fwd_forward_mshr", "fwd_forward_mshr_s"), ("fwd_data", "fwd_data_s"),
         ("fwd_result_valid", "fwd_result_valid_s"), ("fwd_denied", "fwd_denied_s"),
         ("fwd_corrupt", "fwd_corrupt_s"),
         ("l2_pf_store_only", "io_l2_pf_store_only"), ("lqEmpty", "io_lqEmpty"),
         ("pf_naive_late_miss_prefetch", "io_prefetch_info_naive_late_miss_prefetch"),
         ("pf_fdp_late_miss_prefetch", "io_prefetch_info_fdp_late_miss_prefetch"),
         ("pf_fdp_prefetch_monitor_cnt", "io_prefetch_info_fdp_prefetch_monitor_cnt"),
         ("pf_fdp_total_prefetch", "io_prefetch_info_fdp_total_prefetch"),
         ("wfi_req", "io_wfi_wfiReq"), ("wfi_safe", "io_wfi_wfiSafe"),
         ("rob_head_miss_in_dcache", "io_debugTopDown_robHeadMissInDCache"),
         ("l1Miss", "io_l1Miss"), ("perf_value", "perf_value_s"),
         ("difftest_refill_bore", "gatewayIn_packed_41_bore"),
         ("pipe", "pipe_s"), ("pipe_cancel", "pipe_cancel_s"),
         ("acquire_fired_by_pipe_reg", "acquire_fired_by_pipe_reg_s"),
         ("memset_pattern_detected", "memset_pattern_detected_s"),
         ("cmo_a_valid", "cmo_a_valid_s"), ("cmo_a_opcode", "cmo_a_opcode_s"),
         ("cmo_a_address", "cmo_a_address_s"), ("cmo_a_ready", "cmo_a_ready_s"),
         ("cmo_d_valid", "cmo_d_valid_s"), ("cmo_d_ready", "cmo_d_ready_s"),
         ("cmo_wfi_safe", "cmo_wfi_safe_s")]
    for n in ("pipe_alloc", "pipe_merge", "primary_valid", "acq_ready", "grant_valid", "finish_ready",
              "l2_hint_valid", "mp_resp", "mp_refill_resp", "mp_replay", "mp_evict_BtoT_way",
              "primary_ready", "secondary_ready", "secondary_reject", "query_primary_ready",
              "query_secondary_ready", "query_secondary_reject", "req_handled", "acq_valid", "acq",
              "finish_valid", "finish_sink", "ldq_valid", "ldq_addr", "ldq_data_raw", "ldq_hasdata",
              "ldq_refill_done", "refill_info_valid", "refill_info", "occupy_way", "probe_block",
              "replace_block", "vaddr_valid", "vaddr", "isBtoT", "fwd", "rob_head_resp",
              "late_prefetch", "matched", "l1Miss", "wfi_safe"):
        c.append(("ent_" + n, "ent_" + n))
    return c


def inst_block(mod, inst, binds, conn_note=""):
    ports = port_table(mod)
    names = [p[2] for p in ports]
    if set(binds) != set(names):
        extra = sorted(set(binds) - set(names))
        miss = sorted(set(names) - set(binds))
        raise SystemExit("gen_missq: %s %s 连线规则与 golden 端口不符：多 %s 少 %s" % (mod, inst, extra[:5], miss[:5]))
    o = ["  %s %s (" % (mod, inst)]
    width = max(len(n) for n in names)
    for k, n in enumerate(names):
        e = binds[n]
        o.append("    .%-*s (%s)%s" % (width, n, "" if e is None else e, "," if k + 1 < len(names) else ""))
    o.append("  );")
    return o


def gen_missqueue_file():
    gp = {n: (d, w) for d, w, n, _ in port_table(MQ)}
    body = []
    decl = body.append
    decl("  // ---- 核 <-> 顶层端口：结构体 / 向量信号 ----")
    decl("  miss_req_t                          req_s;")
    decl("  query_req_t [N_QUERY-1:0]           query_s;")
    decl("  logic [N_QUERY-1:0]                 query_ready_s;")
    decl("  tl_a_t                              acq_s;")
    decl("  tl_d_t                              grant_s;")
    decl("  mp_info_t                           mp_info_s;")
    decl("  logic [N_LDU-1:0][7:0]              occupy_set_s;")
    decl("  logic [N_LDU-1:0]                   occupy_fail_s;")
    decl("  logic [N_LDU-1:0]                   fwd_valid_s, fwd_forward_mshr_s, fwd_result_valid_s;")
    decl("  logic [N_LDU-1:0]                   fwd_denied_s, fwd_corrupt_s;")
    decl("  logic [N_LDU-1:0][3:0]              fwd_mshrid_s;")
    decl("  logic [N_LDU-1:0][47:0]             fwd_paddr_s;")
    decl("  logic [N_LDU-1:0][15:0][7:0]        fwd_data_s;")
    decl("  logic [4:0][5:0]                    perf_value_s;")
    decl("  // ---- 核 -> MSHR ----")
    decl("  miss_req_t                          pipe_s;")
    decl("  logic                               pipe_cancel_s, acquire_fired_by_pipe_reg_s, memset_pattern_detected_s;")
    for n in ("pipe_alloc", "pipe_merge", "primary_valid", "acq_ready", "grant_valid", "finish_ready",
              "l2_hint_valid", "mp_resp", "mp_refill_resp", "mp_replay", "mp_evict_BtoT_way"):
        decl("  logic [N_ENTRIES-1:0]               ent_%s;" % n)
    decl("  // ---- MSHR -> 核 / 仲裁器 ----")
    for n in ("primary_ready", "secondary_ready", "secondary_reject", "req_handled", "acq_valid",
              "finish_valid", "ldq_valid", "ldq_hasdata", "ldq_refill_done", "refill_info_valid",
              "probe_block", "replace_block", "vaddr_valid", "isBtoT", "rob_head_resp",
              "late_prefetch", "matched", "l1Miss", "wfi_safe", "mp_valid"):
        decl("  logic [N_ENTRIES-1:0]               ent_%s;" % n)
    for n in ("query_primary_ready", "query_secondary_ready", "query_secondary_reject"):
        decl("  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_%s;" % n)
    decl("  ent_acq_t [N_ENTRIES-1:0]           ent_acq;")
    decl("  logic [N_ENTRIES-1:0][9:0]          ent_finish_sink;")
    decl("  logic [N_ENTRIES-1:0][47:0]         ent_ldq_addr;")
    decl("  logic [N_ENTRIES-1:0][511:0]        ent_ldq_data_raw;")
    decl("  ent_refill_info_t [N_ENTRIES-1:0]   ent_refill_info;")
    decl("  logic [N_ENTRIES-1:0][3:0]          ent_occupy_way;")
    decl("  logic [N_ENTRIES-1:0][49:0]         ent_vaddr;")
    decl("  ent_fwd_t [N_ENTRIES-1:0]           ent_fwd;")
    for f, w in MQ_MP_FIELDS:
        decl("  logic [N_ENTRIES-1:0]%s ent_mp_%s;" % ("" if w == 1 else "[%d:0]" % (w - 1), f))
    decl("  logic [N_ENTRIES-1:0]               arb_in_ready;")
    decl("  logic                               arb_out_valid_s;")
    decl("  // ---- CMOUnit ----")
    decl("  logic                               cmo_a_valid_s, cmo_a_ready_s, cmo_d_valid_s, cmo_d_ready_s;")
    decl("  logic                               cmo_wfi_safe_s;")
    decl("  logic [3:0]                         cmo_a_opcode_s;")
    decl("  logic [47:0]                        cmo_a_address_s;")
    decl("")
    driven, used = {}, set()

    def drive(port, expr):
        if gp.get(port, ("?",))[0] != "output":
            raise SystemExit("gen_missq: MissQueue 驱动了非输出端口 %s" % port)
        if port in driven:
            raise SystemExit("gen_missq: MissQueue 输出 %s 被驱动两次" % port)
        driven[port] = expr

    def use(port, w=None):
        if gp.get(port, ("?",))[0] != "input":
            raise SystemExit("gen_missq: MissQueue 规则引用了非输入端口 %s" % port)
        if w is not None and gp[port][1] != w:
            raise SystemExit("gen_missq: MissQueue 端口 %s 位宽 golden=%d 规则=%d" % (port, gp[port][1], w))
        used.add(port)
        return port

    decl("  // ---- 顶层端口拆装 ----")
    for f, w in MQ_REQ_FIELDS:
        decl("  assign req_s.%s = %s;" % (f, use("io_req_bits_" + f, w)))
    for q in range(NQ):
        for f, w in (("source", 4), ("addr", 48), ("vaddr", 50)):
            decl("  assign query_s[%d].%s = %s;" % (q, f, use("io_queryMQ_%d_req_bits_%s" % (q, f), w)))
        drive("io_queryMQ_%d_ready" % q, "query_ready_s[%d]" % q)
    for f, w in MQ_D_FIELDS:
        decl("  assign grant_s.%s = %s;" % (f, use("io_mem_grant_bits_" + f, w)))
    for f, w in MQ_INFO_FIELDS:
        decl("  assign mp_info_s.%s = %s;" % (f, use("io_mainpipe_info_" + f, w)))
    for f, w in MQ_A_FIELDS:
        if gp["io_mem_acquire_bits_" + f][1] != w:
            raise SystemExit("gen_missq: A 通道字段 %s 位宽不符" % f)
        drive("io_mem_acquire_bits_" + f, "acq_s.%s" % f)
    for k in range(NL):
        decl("  assign occupy_set_s[%d] = %s;" % (k, use("io_occupy_set_%d" % k, 8)))
        drive("io_occupy_fail_%d" % k, "occupy_fail_s[%d]" % k)
        decl("  assign fwd_valid_s[%d] = %s;" % (k, use("io_forward_%d_valid" % k, 1)))
        decl("  assign fwd_mshrid_s[%d] = %s;" % (k, use("io_forward_%d_mshrid" % k, 4)))
        decl("  assign fwd_paddr_s[%d] = %s;" % (k, use("io_forward_%d_paddr" % k, 48)))
        drive("io_forward_%d_forward_mshr" % k, "fwd_forward_mshr_s[%d]" % k)
        for j in range(16):
            drive("io_forward_%d_forwardData_%d" % (k, j), "fwd_data_s[%d][%d]" % (k, j))
        drive("io_forward_%d_forward_result_valid" % k, "fwd_result_valid_s[%d]" % k)
        drive("io_forward_%d_denied" % k, "fwd_denied_s[%d]" % k)
        drive("io_forward_%d_corrupt" % k, "fwd_corrupt_s[%d]" % k)
    for k in range(5):
        drive("io_perf_%d_value" % k, "perf_value_s[%d]" % k)
    drive("io_main_pipe_req_valid", "arb_out_valid_s")
    for port, expr in driven.items():
        decl("  assign %s = %s;" % (port, expr))
    decl("")

    # 核
    conns = core_bind()
    for cp, e in conns:
        if e in gp:
            if gp[e][0] == "output":
                drive(e, "u_core.%s" % cp)
            else:
                use(e)
    decl("  xs_MissQueue_core u_core (")
    width = max(len(c) for c, _ in conns)
    for k, (cp, e) in enumerate(conns):
        decl("    .%-*s (%s)%s" % (width, cp, e, "," if k + 1 < len(conns) else ""))
    decl("  );")
    decl("")

    # 子模块
    def account(binds):
        for n, e in binds.items():
            if e is None:
                continue
            for tok in re.findall(r"[A-Za-z_]\w*", e):
                if tok in gp:
                    if gp[tok][0] == "input":
                        used.add(tok)
    for i in range(NE):
        b = missentry_bind(i)
        account(b)
        body.extend(inst_block("MissEntry", "entries_%d" % i, b))
    cb = cmo_bind()
    account(cb)
    for n in ("io_req_ready", "io_resp_to_lsq_valid", "io_resp_to_lsq_bits_denied", "io_resp_to_lsq_bits_corrupt"):
        drive(cb[n], "cmo_unit.%s" % n)
    body.extend(inst_block("CMOUnit", "cmo_unit", cb))
    ab = arb_bind()
    account(ab)
    for f, _ in MQ_MP_FIELDS:
        drive("io_main_pipe_req_bits_" + f, "main_pipe_req_arb.io_out_bits_" + f)
    body.extend(inst_block("Arbiter16_MainPipeReq", "main_pipe_req_arb", ab))

    outs = [n for n, (d, _) in gp.items() if d == "output"]
    ins = [n for n, (d, _) in gp.items() if d == "input"]
    miss_out = [n for n in outs if n not in driven]
    miss_in = [n for n in ins if n not in used]
    if miss_out or miss_in:
        raise SystemExit("gen_missq: MissQueue 未驱动输出 %s / 未使用输入 %s" % (miss_out[:6], miss_in[:6]))

    path = os.path.join(RTL, MQ + ".sv")
    text = open(path).read()
    text = replace_region(text, "missqueue-ports", port_block(MQ))
    text = replace_region(text, "missqueue-body", "\n".join(body))
    return path, text


# ---------------------------------------------------------------------------
#  MissQueue 的 FM「匹配前」钉点（verif/ut/MissQueue/fm_pins_pre.tcl）
# ---------------------------------------------------------------------------
# 顶层：两个 TLArbiter 的 state/beatsLeft（每路一位、签名相近）、打拍的性能事件、前递结果寄存器、
#   只喂断言/性能计数的死寄存器（REG / max_inflight）等名字不同的寄存器逐个写死；
# 子模块：16 个 MissEntry 各自内部照搬 MissEntry 单独签核时的 229 对（前缀 entries_i/ <-> entries_i/u_core/）。
MQ_TOP_PINS = (
    [("state_%d" % k, 1, "u_core/u_acq_arb/state[%d]" % k) for k in range(18)] +
    [("beatsLeft", 1, "u_core/u_acq_arb/beats_left[0]")] +
    [("state_1_%d" % k, 1, "u_core/u_finish_arb/state[%d]" % k) for k in range(16)] +
    [("beatsLeft_1", 1, "u_core/u_finish_arb/beats_left[0]")] +
    [("io_perf_%d_value_REG" % k, 1, "u_core/perf_event_q1[%d]" % k) for k in range(5)] +
    [("io_perf_%d_value_REG_1" % k, 1, "u_core/perf_event_q2[%d]" % k) for k in range(5)] +
    [("perfValidCount", 5, "u_core/perf_valid_count_q"),
     ("REG", 1, "u_core/chk_secondary_ready_onehot"),
     ("max_inflight", 5, "u_core/perf_max_inflight"),
     ("memSetPattenDetected_last_REG", 1, "u_core/memset_q"),
     ("io_l1Miss_REG", 1, "u_core/l1Miss_q"),
     ("source_except_load_cnt", 10, "u_core/source_except_load_cnt"),
     ("miss_req_pipe_reg_merge", 1, "u_core/pipe_merge_q"),
     ("miss_req_pipe_reg_alloc", 1, "u_core/pipe_alloc_q"),
     ("miss_req_pipe_reg_cancel", 1, "u_core/pipe_cancel_q"),
     ("miss_req_pipe_reg_mshr_id", 4, "u_core/pipe_mshr_id_q")] +
    [("forward_mshr" + ("" if k == 0 else "_%d" % k), 1, "u_core/fwd_mshr_q[%d]" % k) for k in range(3)] +
    [("forwardData_%s%d" % ("" if k == 0 else "%d_" % k, j), 8, "u_core/fwd_data_q[%d][%d]" % (k, j))
     for k in range(3) for j in range(16)] +
    [("io_forward_%d_forward_result_valid_REG" % k, 1, "u_core/fwd_result_valid_q[%d]" % k) for k in range(3)] +
    [("io_forward_%d_corrupt_REG" % k, 1, "u_core/fwd_corrupt_q[%d]" % k) for k in range(3)] +
    [("io_forward_%d_denied_REG" % k, 1, "u_core/fwd_denied_q[%d]" % k) for k in range(3)] +
    # 流水寄存器 addr[5:0]：表项与 Acquire 只用行地址 [47:6]，这 6 位在父级是死位
    [("miss_req_pipe_reg_req_addr[%d]" % b, 1, "u_core/pipe_q.addr[%d]" % b) for b in range(6)]
)
# 在 MissQueue 里才变成死位的 MissEntry 寄存器（refill_to_ldq 的 data / error 父级不读）；
# MissEntry 单独签核时它们是活的、FM 按签名配上，所以不在 ME_PINS 里。
MQ_ENTRY_EXTRA_PINS = [
    ("io_refill_to_ldq_bits_data_r", 1, "refill_ldq_half_q"),
    ("io_refill_to_ldq_bits_error_r", 1, "refill_ldq_error_q"),
]


def gen_missqueue_pins():
    path = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "MissQueue", "fm_pins_pre.tcl"))
    pins = list(MQ_TOP_PINS)
    for i in range(NE):
        for g, w, core in ME_PINS + MQ_ENTRY_EXTRA_PINS:
            pins.append(("entries_%d/%s" % (i, g), w, "entries_%d/u_core/%s" % (i, core)))
    why = ["对象：顶层 TLArbiter 的每路 state 位 / beatsLeft、两级打拍的性能事件、前递结果寄存器、",
           "流水寄存器标志、只喂断言/性能计数的死寄存器（REG / max_inflight）—— 名字与 golden 不同；",
           "16 个 MissEntry 内部照搬 MissEntry 单独签核时的 229 对（值恒等的多份打拍 + 死寄存器）。",
           "配对依据见 scripts/gen_missq.py 的 MQ_TOP_PINS / ME_PINS（逐项写死，不猜名字）。"]
    return path, fm_pin_tcl("MissQueue", "mq", pins, "", why,
                            ref_module=lambda pre: "MissEntry" if pre.startswith("entries_") else None)


# ---------------------------------------------------------------------------
#  UT testbench 公共生成片段（verif/ut/<T>/gen.py 调用；本文件自己不写 tb）
# ---------------------------------------------------------------------------
def _rng(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


def tb_ports(module, skip_inputs=("clock", "reset")):
    """tb 的端口声明 + golden / _xs 两个实例。输入两侧共用，输出 g_/i_ 前缀。"""
    ps = port_table(module)
    L = ["  // ---- 输入（两侧共用；clock/reset 由 tb 手写区驱动）----"]
    for d, w, n, _ in ps:
        if d == "input" and n not in skip_inputs:
            L.append("  logic %s%s;" % (_rng(w), n))
    L.append("  // ---- 输出（g_ = golden，i_ = 重写）----")
    for d, w, n, _ in ps:
        if d == "output":
            L.append("  wire  %sg_%s, i_%s;" % (_rng(w), n, n))
    for inst, pre, mod in (("u_gold", "g_", module), ("u_impl", "i_", module + "_xs")):
        L.append("  %s %s (" % (mod, inst))
        conns = ["    .%s(%s)" % (n, n if d == "input" else pre + n) for d, w, n, _ in ps]
        L.append(",\n".join(conns))
        L.append("  );")
    return L


def tb_compare(module, toggle_exempt=None):
    """每拍逐位比较**全部**输出端口；同时记每个输出位是否见过 0 和 1（toggle 覆盖）。

    toggle_exempt = {端口名: 位掩码}：结构上恒定、不可能翻转的位（调用方逐个写明理由）。
    只豁免 toggle 覆盖，不豁免比较。"""
    toggle_exempt = toggle_exempt or {}
    for n in toggle_exempt:
        if n not in [p[2] for p in port_table(module) if p[0] == "output"]:
            raise SystemExit("gen_missq: toggle 豁免的端口 %s 不是 %s 的输出" % (n, module))
    outs = [(w, n) for d, w, n, _ in port_table(module) if d == "output"]
    L = []
    for w, n in outs:
        L.append("  logic %sseen1_%s = '0, seen0_%s = '0;" % (_rng(w), n, n))
    L.append("  task automatic compare_outputs();")
    for w, n in outs:
        L.append("    if (g_%s !== i_%s) begin" % (n, n))
        L.append("      errors++;")
        L.append("      if (errors <= 20) $display(\"MISMATCH cyc=%%0d %s: g=%%h i=%%h\", cyc, g_%s, i_%s);" % (n, n, n))
        L.append("    end")
        L.append("    seen1_%s |= g_%s;" % (n, n))
        L.append("    seen0_%s |= ~g_%s;" % (n, n))
    L.append("    checks++;")
    L.append("  endtask")
    L.append("  // 返回从未翻转过的输出端口个数（逐个打印）")
    L.append("  function automatic int report_toggle();")
    L.append("    int bad = 0;")
    for w, n in outs:
        m = toggle_exempt.get(n)
        keep = "" if m is None else " & ~%d'h%x" % (w, m)
        L.append("    if (((~seen1_%s | ~seen0_%s)%s) != '0) begin bad++; $display(\"TOGGLE MISS %s 1=%%h 0=%%h\", seen1_%s, seen0_%s); end" % (n, n, keep, n, n, n))
    L.append("    return bad;")
    L.append("  endfunction")
    return L


def gen_tb_regions(tb_path, module, toggle_exempt=None):
    text = open(tb_path).read()
    text = replace_region(text, "tb-ports", "\n".join(tb_ports(module)))
    text = replace_region(text, "tb-compare", "\n".join(tb_compare(module, toggle_exempt)))
    return text


def tb_main(tb_path, module, toggle_exempt=None):
    """verif/ut/<T>/gen.py 的公共入口：python3 gen.py [--check]"""
    text = gen_tb_regions(tb_path, module, toggle_exempt)
    old = open(tb_path).read()
    if "--check" in sys.argv:
        if old != text:
            print("GEN CHECK FAILED: %s 与生成器输出不一致" % tb_path)
            return 1
        print("GEN CHECK OK")
        return 0
    if old != text:
        open(tb_path, "w").write(text)
        print("wrote %s" % tb_path)
    else:
        print("unchanged")
    return 0


GENERATORS = [gen_arb16_file, gen_missentry_file, gen_missentry_pins, gen_missqueue_file,
              gen_missqueue_pins]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    drift = 0
    for g in GENERATORS:
        path, text = g()
        old = open(path).read() if os.path.exists(path) else None
        if old == text:
            continue
        if a.check:
            print("DRIFT: %s" % os.path.relpath(path, os.path.join(HERE, "..")))
            drift += 1
        else:
            open(path, "w").write(text)
            print("wrote %s" % os.path.relpath(path, os.path.join(HERE, "..")))
    if a.check:
        print("gen_missq --check: %s" % ("DRIFT" if drift else "OK"))
        return 1 if drift else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
