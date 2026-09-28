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


def fm_pin_tcl(top, tag, pins, impl_root, why_lines):
    """钉点 tcl：每条 set_user_match 必须返回 1，总数必须等于字面整数（fail-closed）。"""
    regs = golden_regs(top)
    seen_r, seen_i, pairs = set(), set(), []
    for g, w, core in pins:
        if regs.get(g) != w:
            raise SystemExit("gen_missq: %s 钉点 golden 寄存器 %s 位宽 golden=%s 表=%d" % (top, g, regs.get(g), w))
        if g in seen_r or core in seen_i:
            raise SystemExit("gen_missq: %s 钉点重复：%s / %s" % (top, g, core))
        seen_r.add(g)
        seen_i.add(core)
        # 核的数组元素：a[3] -> a_reg[3]
        m = re.fullmatch(r"(\w+)((?:\[\d+\])*)", core)
        base, idx = m.group(1), m.group(2)
        for b in range(w):
            rp = "$r/%s_reg" % g + ("\\[%d\\]" % b if w > 1 else "")
            ip = "$i/%s_reg" % base + idx.replace("[", "\\[").replace("]", "\\]") + \
                 ("\\[%d\\]" % b if w > 1 else "")
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
          "    set i \"i:/WORK/%s/%s\"" % (top, impl_root),
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


GENERATORS = [gen_arb16_file, gen_missentry_file, gen_missentry_pins]


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
