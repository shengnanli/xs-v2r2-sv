#!/usr/bin/env python3
"""gen_dcache.py —— DCache 本体（L1 数据缓存顶层）的机械派生区生成器（lane dcachebody）。

DCache 是"22 类已签核子模块 + 一点胶水"。胶水核 xs_DCache_core 是手写的（rtl/memblock/DCache.sv
§1..§9）；本脚本只产出没有微架构的部分：

  rtl/memblock/DCache.sv   GENERATED(dcache-ports) / GENERATED(dcache-body)
      端口表：逐字取 G1 golden；
      body：子模块输出线声明 → 胶水核例化 → 子模块例化（实例名、端口顺序同 golden）→ 本层输出 assign。
  verif/ut/DCache/fm_pins_pre.tcl
      FM「匹配前」钉点 = 本层胶水寄存器（逐位写死，golden 平铺名 <-> 核里的数组元素）
      + 各子模块签核时用的那份 fm_pins_pre.tcl（tclsh 里用桩执行、逐对收割，
        把 r:/WORK/<子模块>/ 与 i:/WORK/<子模块>/ 换成 DCache/<实例名>/）。
  verif/allow/DCache.json
      assembly 黑盒声明 = 各子模块签核时声明过的厂商 SRAM 叶子（array_7_ext / array_8_ext），
      逐条从子模块的 allow 文件收割、路径换成 DCache/<实例名>/ 之下；不新增任何别的黑盒。
  verif/ut/DCache/tb.sv     GENERATED(tb-ports) / GENERATED(tb-compare)

★连线规则（每个子模块端口恰好命中一条，fail-closed）★
  (a) golden 接的是本层端口名             → 原样接同名端口（位宽核对）；
  (b) golden 接的是 _<实例>_io_<端口> 线   → 接 <简称>_<端口去 io_>（该实例的输出线）；
      子模块输出必须恰好接自己的线（名字逐字核对）；
  (c) golden 输出写的是 /* unused */      → 留空 ()；
  (d) 其余（表达式 / golden 的中间线）     → 必须出现在 GLUE_IN 表里，表里逐字记着 golden 的
      表达式（空白归一后比较），改接到胶水核的一个输出上；GLUE_IN 也可以覆盖 (a)(b)。
  子模块输出接到 golden 的中间线（只有 XSPerf 死探针 _probe / _probe_0）→ 必须在 DEAD_OUT 表里。
  本层输出：golden `assign io_x = _<实例>_io_<y>` → 生成同形 assign；其余必须在 GLUE_OUT 表里。
  总核对：每个本层输出恰好被驱动一次；没人用的本层输入必须恰好等于 UNUSED_IN 且在 golden 里也只出现在端口表；
  GLUE_IN / GLUE_OUT / DEAD_OUT 每条都被用到。

用法:
  scripts/gen_dcache.py            # 写文件（内容不变不写，幂等）
  scripts/gen_dcache.py --check    # 只比对；有漂移 rc=1
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
TOP = "DCache"
RTL_FILE = os.path.join(REPO, "rtl", "memblock", "DCache.sv")

PORT_RE = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
IDENT_RE = re.compile(r"^[A-Za-z_]\w*$")
UNUSED_OUT = "/* unused */"


def die(msg):
    raise SystemExit("gen_dcache: ERROR: " + msg)


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


# ---------------------------------------------------------------------------
#  golden 解析
# ---------------------------------------------------------------------------
_cache = {}


def golden_text(module):
    if module not in _cache:
        t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
        i = t.index("\nmodule %s(" % module) + 1
        _cache[module] = t[i:t.index("\nendmodule", i)]
    return _cache[module]


def port_table(module):
    """[(dir, width, name, 原文行去逗号)]，顺序即 golden 顺序。"""
    lines = golden_text(module).split("\n")
    end = next(i for i, l in enumerate(lines) if l.startswith(");"))
    out = []
    for l in lines[1:end]:
        m = PORT_RE.match(l)
        if not m:
            die("%s 端口行解析失败: %r" % (module, l))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip().rstrip(",")))
    return out


def instances(module):
    """[(子模块, 实例名, [(端口, golden 表达式)])]，顺序即 golden 顺序。"""
    body = golden_text(module)
    out = []
    for m in re.finditer(r"\n  ([A-Za-z_]\w*) ([A-Za-z_]\w*) \((.*?)\n  \);", body, re.S):
        conns = re.findall(r"\.(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)", m.group(3), re.S)
        out.append((m.group(1), m.group(2), [(p, norm(e)) for p, e in conns]))
    return out


def top_assigns(module):
    outs = {n for d, w, n, _ in port_table(module) if d == "output"}
    res = {}
    for m in re.finditer(r"\n  assign (\w+) =(.*?);", golden_text(module), re.S):
        if m.group(1) in outs:
            if m.group(1) in res:
                die("%s 输出 %s 被 assign 两次" % (module, m.group(1)))
            res[m.group(1)] = norm(m.group(2))
    return res


def golden_regs(module):
    out = {}
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", golden_text(module), re.M):
        out[n] = int(a) - int(b) + 1 if a else 1
    return out


def rng(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


def wrap_list(head, items, tail, width=100):
    lines, cur, pad = [], head, " " * len(head)
    for i, it in enumerate(items):
        piece = it + ("," if i + 1 < len(items) else tail)
        if cur != head and len(cur) + 1 + len(piece) > width:
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
#  装配表（DCache）
# ---------------------------------------------------------------------------
ALIAS = {
    "cacheCtrlOpt": "ctrl", "bankedDataArray": "data_array", "metaArray": "meta_array",
    "errorArray": "error_array", "prefetchArray": "pf_array", "accessArray": "access_array",
    "tagArray": "tag_array", "prefetcherMonitor": "pf_monitor", "fdpMonitor": "fdp_monitor",
    "bloomFilter": "bloom", "counterFilter": "counter_filter",
    "ldu_0": "ldu0", "ldu_1": "ldu1", "ldu_2": "ldu2", "stu_0": "stu0", "stu_1": "stu1",
    "mainPipe": "mp", "missQueue": "mq", "probeQueue": "pq", "wb": "wbq",
    "tag_write_arb": "tag_write_arb", "dataWriteArb": "data_write_arb",
    "dataWriteArb_dup": "data_write_arb_dup0",
    **{"dataWriteArb_dup_%d" % k: "data_write_arb_dup%d" % k for k in range(1, 8)},
    "missReqArb": "miss_req_arb", "missReadyGen": "miss_ready_gen",
}

N_LDU = 3
N_PERF = 40
# 40 个性能事件的来源（generatePerfEvent 的顺序：wb, mainPipe, missQueue, probeQueue, ldu_0..2）
PERF_SRC = ([("wb", k) for k in range(5)] + [("mainPipe", k) for k in range(4)]
            + [("missQueue", k) for k in range(5)] + [("probeQueue", k) for k in range(5)]
            + [("ldu_%d" % i, k) for i in range(N_LDU) for k in range(7)])
assert len(PERF_SRC) == N_PERF


def w_(inst, port):
    """子模块输出线名。"""
    rest = port[3:] if port.startswith("io_") else port
    return "%s_%s" % (ALIAS[inst], rest)


def ldus(port):
    return [w_("ldu_%d" % i, port) for i in range(N_LDU)]


CORE = "xs_DCache_core"
CORE_CONNS = [
    ("clock", "clock"),
    ("reset", "reset"),
    # §1 D 通道
    ("d_valid", "auto_client_out_d_valid"),
    ("d_opcode", "auto_client_out_d_bits_opcode"),
    ("d_size", "auto_client_out_d_bits_size"),
    ("d_source", "auto_client_out_d_bits_source"),
    ("d_data", "auto_client_out_d_bits_data"),
    ("d_denied", "auto_client_out_d_bits_denied"),
    ("d_corrupt", "auto_client_out_d_bits_corrupt"),
    ("d_echo_is_keyword", "auto_client_out_d_bits_echo_isKeyword"),
    ("d_ready", ("out", "", "core_d_ready")),
    ("mq_grant_ready", w_("missQueue", "io_mem_grant_ready")),
    ("mq_grant_valid", ("out", "", "core_mq_grant_valid")),
    ("wb_grant_valid", ("out", "", "core_wb_grant_valid")),
    ("tl_d_channel_valid", ("out", "", "core_tl_d_channel_valid")),
    ("tl_d_channel_mshrid", ("out", "[3:0]", "core_tl_d_channel_mshrid")),
    ("fwd_d_valid", ("out", "[2:0]", "core_fwd_d_valid")),
    ("fwd_d_data", ("out", "[2:0][255:0]", "core_fwd_d_data")),
    ("fwd_d_mshrid", ("out", "[2:0][3:0]", "core_fwd_d_mshrid")),
    ("fwd_d_last", ("out", "[2:0]", "core_fwd_d_last")),
    ("fwd_d_denied", ("out", "[2:0]", "core_fwd_d_denied")),
    ("fwd_d_corrupt", ("out", "[2:0]", "core_fwd_d_corrupt")),
    # §2 B 通道
    ("b_valid", "auto_client_out_b_valid"),
    ("b_address", "auto_client_out_b_bits_address"),
    ("b_data", "auto_client_out_b_bits_data"),
    ("b_ready", ("out", "", "core_b_ready")),
    ("pq_probe_ready", w_("probeQueue", "io_mem_probe_ready")),
    ("mq_probe_block", w_("missQueue", "io_probe_block")),
    ("pq_probe_valid", ("out", "", "core_pq_probe_valid")),
    ("mq_probe_vaddr", ("out", "[49:0]", "core_mq_probe_vaddr")),
    # §3 L2 提示
    ("l2_hint_valid", "io_l2_hint_valid"),
    ("l2_hint_source_id", "io_l2_hint_bits_sourceId"),
    ("l2_pf_store_only", "io_l2_pf_store_only"),
    ("mq_l2_hint_valid", ("out", "", "core_mq_l2_hint_valid")),
    ("mq_l2_hint_source_id", ("out", "[3:0]", "core_mq_l2_hint_source_id")),
    ("mq_l2_pf_store_only", ("out", "", "core_mq_l2_pf_store_only")),
    # §4 阵列口胶水
    ("mp_tag_write_intend", w_("mainPipe", "io_tag_write_intend")),
    ("tag_array_write_valid", w_("tag_write_arb", "io_out_valid")),
    ("ldu_tag_read_ready", ("out", "", "core_ldu_tag_read_ready")),
    ("mp_pseudo_tag_inj_done", w_("mainPipe", "io_pseudo_tag_error_inj_done")),
    ("ldu_pseudo_tag_inj_done", ldus("io_pseudo_tag_error_inj_done")),
    ("mp_pseudo_data_inj_done", w_("mainPipe", "io_pseudo_data_error_inj_done")),
    ("ldu_pseudo_data_inj_done", ldus("io_pseudo_data_error_inj_done")),
    ("bda_pseudo_error_ready", w_("bankedDataArray", "io_pseudo_error_ready")),
    ("pseudo_tag_error_ready", ("out", "", "core_pseudo_tag_error_ready")),
    ("pseudo_data_error_ready", ("out", "", "core_pseudo_data_error_ready")),
    # §5 替换
    ("ldu_repl_valid", ldus("io_replace_access_valid")),
    ("ldu_repl_set", ldus("io_replace_access_bits_set")),
    ("ldu_repl_way", ldus("io_replace_access_bits_way")),
    ("mp_repl_valid", w_("mainPipe", "io_replace_access_valid")),
    ("mp_repl_set", w_("mainPipe", "io_replace_access_bits_set")),
    ("mp_repl_way", w_("mainPipe", "io_replace_access_bits_way")),
    ("mp_victim_set", w_("mainPipe", "io_replace_way_set_bits")),
    ("mp_victim_way", ("out", "[1:0]", "core_mp_victim_way")),
    # §6 MainPipe 回应
    ("mp_atomic_valid", w_("mainPipe", "io_atomic_resp_valid")),
    ("mp_atomic_source", w_("mainPipe", "io_atomic_resp_bits_source")),
    ("mp_atomic_data", w_("mainPipe", "io_atomic_resp_bits_data")),
    ("mp_atomic_miss", w_("mainPipe", "io_atomic_resp_bits_miss")),
    ("mp_atomic_replay", w_("mainPipe", "io_atomic_resp_bits_replay")),
    ("mp_atomic_denied", w_("mainPipe", "io_atomic_resp_bits_tl_error_tl_denied")),
    ("mp_atomic_corrupt", w_("mainPipe", "io_atomic_resp_bits_tl_error_tl_corrupt")),
    ("mp_atomic_id", w_("mainPipe", "io_atomic_resp_bits_id")),
    ("mp_atomic_miss_id", w_("mainPipe", "io_atomic_resp_bits_miss_id")),
    ("mp_atomic_ack_miss_queue", w_("mainPipe", "io_atomic_resp_bits_ack_miss_queue")),
    ("lsu_atomic_valid", ("out", "", "core_lsu_atomic_valid")),
    ("lsu_atomic_data", ("out", "[127:0]", "core_lsu_atomic_data")),
    ("lsu_atomic_miss", ("out", "", "core_lsu_atomic_miss")),
    ("lsu_atomic_replay", ("out", "", "core_lsu_atomic_replay")),
    ("lsu_atomic_denied", ("out", "", "core_lsu_atomic_denied")),
    ("lsu_atomic_corrupt", ("out", "", "core_lsu_atomic_corrupt")),
    ("lsu_atomic_id", ("out", "[5:0]", "core_lsu_atomic_id")),
    ("mq_mp_resp_valid", ("out", "", "core_mq_mp_resp_valid")),
    ("mq_mp_resp_miss_id", ("out", "[3:0]", "core_mq_mp_resp_miss_id")),
    ("mq_mp_resp_ack_miss_queue", ("out", "", "core_mq_mp_resp_ack_miss_queue")),
    ("mp_store_replay_valid", w_("mainPipe", "io_store_replay_resp_valid")),
    ("mp_store_replay_id", w_("mainPipe", "io_store_replay_resp_bits_id")),
    ("lsu_store_replay_valid", ("out", "", "core_lsu_store_replay_valid")),
    ("lsu_store_replay_id", ("out", "[5:0]", "core_lsu_store_replay_id")),
    ("wb_req_ready", w_("wb", "io_req_ready")),
    ("mp_wb_valid", w_("mainPipe", "io_wb_valid")),
    ("mp_wb_addr", w_("mainPipe", "io_wb_bits_addr")),
    ("mp_lrsc_valid", w_("mainPipe", "io_lrsc_locked_block_valid")),
    ("mp_lrsc_block", w_("mainPipe", "io_lrsc_locked_block_bits")),
    ("lsu_release_valid", ("out", "", "core_lsu_release_valid")),
    ("lsu_release_paddr", ("out", "[47:0]", "core_lsu_release_paddr")),
    ("mp_invalid_resv_set", ("out", "", "core_mp_invalid_resv_set")),
    # §7 错误
    ("err_valid", [w_("mainPipe", "io_error_valid")] + ldus("io_error_valid")),
    ("err_paddr", [w_("mainPipe", "io_error_bits_paddr")] + ldus("io_error_bits_paddr")),
    ("err_report_to_beu", [w_("mainPipe", "io_error_bits_report_to_beu")] + ldus("io_error_bits_report_to_beu")),
    ("error_valid", ("out", "", "core_error_valid")),
    ("error_paddr", ("out", "[47:0]", "core_error_paddr")),
    ("error_report_to_beu", ("out", "", "core_error_report_to_beu")),
    # §8 预取统计
    ("ldu_pf_total", ldus("io_prefetch_info_naive_total_prefetch")),
    ("ldu_pf_late_hit", ldus("io_prefetch_info_naive_late_hit_prefetch")),
    ("mp_pf_flag_write_valid", w_("mainPipe", "io_prefetch_flag_write_valid")),
    ("mp_pf_flag_write_way_en", w_("mainPipe", "io_prefetch_flag_write_bits_way_en")),
    ("pf_array_last_resp", [w_("prefetchArray", "io_resp_4_%d" % k) for k in range(4)]),
    ("access_array_last_resp", [w_("accessArray", "io_resp_4_%d" % k) for k in range(4)]),
    ("ldu_pf_flag_write_valid", ldus("io_prefetch_flag_write_valid")[:2]),
    ("ldu_pf_flag_write_idx", ldus("io_prefetch_flag_write_bits_idx")[:2]),
    ("ldu_pf_flag_write_way_en", ldus("io_prefetch_flag_write_bits_way_en")[:2]),
    ("ldu_fdp_useful", ldus("io_prefetch_info_fdp_useful_prefetch")),
    ("pfm_total_prefetch", ("out", "", "core_pfm_total_prefetch")),
    ("pfm_late_hit_prefetch", ("out", "", "core_pfm_late_hit_prefetch")),
    ("pfm_good_prefetch", ("out", "", "core_pfm_good_prefetch")),
    ("pfm_bad_prefetch", ("out", "", "core_pfm_bad_prefetch")),
    ("fdp_useful_prefetch", ("out", "[2:0]", "core_fdp_useful_prefetch")),
    # §9 性能事件
    ("perf_in", [w_(i, "io_perf_%d_value" % k) for i, k in PERF_SRC]),
    ("perf_out", ("out", "[39:0][5:0]", "core_perf_out")),
]

_LDU_INJ = lambda kind: " | ".join("_ldu_%d_io_pseudo_%s_error_inj_done" % (i, kind) for i in range(N_LDU))
GLUE_IN = {
    ("cacheCtrlOpt", "io_pseudoError_0_ready"):
        ("_mainPipe_io_pseudo_tag_error_inj_done | " + _LDU_INJ("tag"), "core_pseudo_tag_error_ready"),
    ("cacheCtrlOpt", "io_pseudoError_1_ready"):
        ("_bankedDataArray_io_pseudo_error_ready & (_mainPipe_io_pseudo_data_error_inj_done | "
         + _LDU_INJ("data") + ")", "core_pseudo_data_error_ready"),
    ("prefetcherMonitor", "io_timely_total_prefetch"): ("_probe_3", "core_pfm_total_prefetch"),
    ("prefetcherMonitor", "io_timely_late_hit_prefetch"): ("_probe_4", "core_pfm_late_hit_prefetch"),
    ("prefetcherMonitor", "io_validity_good_prefetch"): ("_probe_1", "core_pfm_good_prefetch"),
    ("prefetcherMonitor", "io_validity_bad_prefetch"): ("_probe_2", "core_pfm_bad_prefetch"),
    ("fdpMonitor", "io_accuracy_useful_prefetch_0"):
        ("_ldu_0_io_prefetch_info_fdp_useful_prefetch", "core_fdp_useful_prefetch[0]"),
    **{("fdpMonitor", "io_accuracy_useful_prefetch_%d" % i):
       ("~same_cycle_update_pf_flag_probe & _ldu_%d_io_prefetch_info_fdp_useful_prefetch" % i,
        "core_fdp_useful_prefetch[%d]" % i) for i in (1, 2)},
    **{("ldu_%d" % i, "io_tag_read_ready"): ("~_mainPipe_io_tag_write_intend", "core_ldu_tag_read_ready")
       for i in range(N_LDU)},
    ("mainPipe", "io_replace_way_way"):
        ("{_GEN_16[2], _GEN_16[2] ? _GEN_16[1] : _GEN_16[0]}", "core_mp_victim_way"),
    ("mainPipe", "io_invalid_resv_set"): ("mainPipe_io_invalid_resv_set_REG", "core_mp_invalid_resv_set"),
    ("missQueue", "io_mem_grant_valid"): ("_GEN_13 & auto_client_out_d_valid", "core_mq_grant_valid"),
    ("missQueue", "io_l2_hint_valid"): ("missQueue_io_l2_hint_REG_valid", "core_mq_l2_hint_valid"),
    ("missQueue", "io_l2_hint_bits_sourceId"):
        ("missQueue_io_l2_hint_REG_bits_sourceId", "core_mq_l2_hint_source_id"),
    ("missQueue", "io_main_pipe_resp_valid"): ("missQueue_io_main_pipe_resp_valid_REG", "core_mq_mp_resp_valid"),
    ("missQueue", "io_main_pipe_resp_bits_miss_id"):
        ("missQueue_io_main_pipe_resp_bits_r_miss_id", "core_mq_mp_resp_miss_id"),
    ("missQueue", "io_main_pipe_resp_bits_ack_miss_queue"):
        ("missQueue_io_main_pipe_resp_bits_r_ack_miss_queue", "core_mq_mp_resp_ack_miss_queue"),
    ("missQueue", "io_probe_req_bits_vaddr"):
        ("{2'h0, auto_client_out_b_bits_address[47:14], auto_client_out_b_bits_data[2:1], "
         "auto_client_out_b_bits_address[11:0]}", "core_mq_probe_vaddr"),
    ("missQueue", "io_l2_pf_store_only"): ("missQueue_io_l2_pf_store_only_REG", "core_mq_l2_pf_store_only"),
    ("probeQueue", "io_mem_probe_valid"):
        ("auto_client_out_b_valid & ~_missQueue_io_probe_block", "core_pq_probe_valid"),
    ("wb", "io_mem_grant_valid"): ("~_GEN_13 & _GEN_14 & auto_client_out_d_valid", "core_wb_grant_valid"),
}

# 子模块输出接到 golden 中间线、但该线无人读（XSPerfAccumulate 的死探针）
DEAD_OUT = {
    ("missQueue", "io_prefetch_info_fdp_prefetch_monitor_cnt"): "_probe_0",
    ("missQueue", "io_prefetch_info_fdp_total_prefetch"): "_probe",
}


def _fwd(k):
    g = {}
    g["io_lsu_forward_D_%d_valid" % k] = ("io_lsu_forward_D_2_valid_0", "core_fwd_d_valid[%d]" % k)
    g["io_lsu_forward_D_%d_data" % k] = ("auto_client_out_d_bits_data", "core_fwd_d_data[%d]" % k)
    g["io_lsu_forward_D_%d_mshrid" % k] = ("auto_client_out_d_bits_source[3:0]", "core_fwd_d_mshrid[%d]" % k)
    sfx = "" if k == 0 else "_%d" % k
    g["io_lsu_forward_D_%d_last" % k] = (
        "auto_client_out_d_bits_echo_isKeyword ^ (done_r_counter%s | ~done_r_beats1%s) & _done_T%s"
        % (sfx, sfx, sfx), "core_fwd_d_last[%d]" % k)
    g["io_lsu_forward_D_%d_denied" % k] = ("io_lsu_forward_D_2_denied_0", "core_fwd_d_denied[%d]" % k)
    g["io_lsu_forward_D_%d_corrupt" % k] = ("io_lsu_forward_D_2_corrupt_0", "core_fwd_d_corrupt[%d]" % k)
    return g


GLUE_OUT = {
    "auto_client_out_b_ready": ("clientNodeOut_b_ready", "core_b_ready"),
    "auto_client_out_d_ready": ("clientNodeOut_d_ready", "core_d_ready"),
    "io_lsu_tl_d_channel_valid": ("(_GEN | _GEN_1) & auto_client_out_d_valid", "core_tl_d_channel_valid"),
    "io_lsu_tl_d_channel_mshrid": ("auto_client_out_d_bits_source[3:0]", "core_tl_d_channel_mshrid"),
    "io_lsu_store_replay_resp_valid": ("io_lsu_store_replay_resp_valid_REG", "core_lsu_store_replay_valid"),
    "io_lsu_store_replay_resp_bits_id": ("io_lsu_store_replay_resp_bits_r_id", "core_lsu_store_replay_id"),
    "io_lsu_atomics_resp_valid": ("io_lsu_atomics_resp_valid_REG", "core_lsu_atomic_valid"),
    "io_lsu_atomics_resp_bits_data": ("io_lsu_atomics_resp_bits_r_data", "core_lsu_atomic_data"),
    "io_lsu_atomics_resp_bits_miss": ("io_lsu_atomics_resp_bits_r_miss", "core_lsu_atomic_miss"),
    "io_lsu_atomics_resp_bits_replay": ("io_lsu_atomics_resp_bits_r_replay", "core_lsu_atomic_replay"),
    "io_lsu_atomics_resp_bits_tl_error_tl_denied":
        ("io_lsu_atomics_resp_bits_r_tl_error_tl_denied", "core_lsu_atomic_denied"),
    "io_lsu_atomics_resp_bits_tl_error_tl_corrupt":
        ("io_lsu_atomics_resp_bits_r_tl_error_tl_corrupt", "core_lsu_atomic_corrupt"),
    "io_lsu_atomics_resp_bits_id": ("io_lsu_atomics_resp_bits_r_id", "core_lsu_atomic_id"),
    "io_lsu_release_valid": ("io_lsu_release_valid_REG", "core_lsu_release_valid"),
    "io_lsu_release_bits_paddr": ("io_lsu_release_bits_paddr_r", "core_lsu_release_paddr"),
    **_fwd(0), **_fwd(1), **_fwd(2),
    "io_error_valid": ("io_error_valid_REG_1", "core_error_valid"),
    "io_error_bits_paddr": ("io_error_bits_r_4_paddr", "core_error_paddr"),
    "io_error_bits_report_to_beu": ("io_error_bits_r_4_report_to_beu", "core_error_report_to_beu"),
    **{"io_perf_%d_value" % k: ("io_perf_%d_value_REG_1" % k, "core_perf_out[%d]" % k) for k in range(N_PERF)},
}

# golden 里只出现在端口表、无人读的本层输入：本配置下没有（io_lsu_sta_*_req_valid 接给 StorePipe 死 stub）
UNUSED_IN = []
UNUSED_IN_GOLDEN_USES = {}


# ---------------------------------------------------------------------------
#  wrapper 生成
# ---------------------------------------------------------------------------
def golden_wire(cp, expr):
    """_<实例>_io_x -> (实例, io_x)；不是就 None。"""
    m = re.fullmatch(r"_([A-Za-z]\w*?)_(io_\w+|auto_\w+)", expr)
    if m and m.group(1) in cp and m.group(2) in cp[m.group(1)]:
        return m.group(1), m.group(2)
    return None


def build_body():
    ports = port_table(TOP)
    pdir = {n: (d, w) for d, w, n, _ in ports}
    insts = instances(TOP)
    cp = {inst: {n: (d, w) for d, w, n, _ in port_table(mod)} for mod, inst, _ in insts}
    if set(cp) != set(ALIAS):
        die("实例集合 golden=%s ALIAS=%s" % (sorted(cp), sorted(ALIAS)))
    used_in, driven, wires = set(), {}, {}
    glue_in_used, dead_used = set(), set()

    # 核输出线（名字 -> 声明）
    core_outs = {}
    for c, how in CORE_CONNS:
        if isinstance(how, tuple):
            core_outs[how[2]] = how[1]

    def core_sig_ok(sig):
        base = re.match(r"[A-Za-z_]\w*", sig).group(0)
        if base not in core_outs:
            die("GLUE 接法 %s 不是核输出" % sig)

    inst_blocks = []
    for mod, inst, conns in insts:
        if [p for p, _ in conns] != [n for d, w, n, _ in port_table(mod)]:
            die("%s 连线端口顺序/集合与 %s 端口表不一致" % (inst, mod))
        lines = []
        for p, e in conns:
            d, w = cp[inst][p]
            key = (inst, p)
            if key in GLUE_IN:
                ge, new = GLUE_IN[key]
                if norm(ge) != e:
                    die("%s.%s golden 表达式漂了：表=%r golden=%r" % (inst, p, ge, e))
                if d != "input":
                    die("GLUE_IN %s.%s 不是输入" % (inst, p))
                core_sig_ok(new)
                glue_in_used.add(key)
                sig = new
            elif d == "output" and e == UNUSED_OUT:
                sig = ""
            elif d == "output" and key in DEAD_OUT:
                if DEAD_OUT[key] != e:
                    die("DEAD_OUT %s.%s golden 接的是 %r 不是 %r" % (inst, p, e, DEAD_OUT[key]))
                if len(re.findall(r"\b%s\b" % re.escape(e), golden_text(TOP))) != 2:
                    die("DEAD_OUT %s 在 golden 里有读者（声明 + 连线之外还出现）" % e)
                dead_used.add(key)
                sig = ""
            elif IDENT_RE.match(e) and e in pdir:
                td, tw = pdir[e]
                if tw != w:
                    die("%s.%s 位宽 %d 与本层端口 %s 位宽 %d 不符" % (inst, p, w, e, tw))
                if d == "output":
                    if td != "output":
                        die("%s.%s 输出接到了本层输入 %s" % (inst, p, e))
                    if e in driven:
                        die("本层输出 %s 被驱动两次" % e)
                    driven[e] = "%s.%s" % (inst, p)
                else:
                    used_in.add(e)
                sig = e
            elif golden_wire(cp, e):
                wi, wp = golden_wire(cp, e)
                if d == "output":
                    if (wi, wp) != (inst, p):
                        die("%s.%s 输出接的线 %s 不是它自己的" % (inst, p, e))
                    wires[w_(inst, p)] = w
                elif cp[wi][wp] != ("output", w):
                    die("%s.%s 读的 %s 方向/位宽不符" % (inst, p, e))
                sig = w_(wi, wp)
            else:
                die("%s.%s 的 golden 接法 %r 没有规则（须进 GLUE_IN 表）" % (inst, p, e))
            lines.append((p, sig))
        width = max(len(p) for p, _ in lines)
        blk = ["  %s %s (" % (mod, inst)]
        for k, (p, sig) in enumerate(lines):
            blk.append("    .%-*s (%s)%s" % (width, p, sig, "," if k + 1 < len(lines) else ""))
        blk.append("  );")
        inst_blocks.append(blk)
    for tbl, used, nm in ((GLUE_IN, glue_in_used, "GLUE_IN"), (DEAD_OUT, dead_used, "DEAD_OUT")):
        miss = set(tbl) - used
        if miss:
            die("%s 有没用到的条目：%s" % (nm, sorted(miss)))

    # 本层输出
    assigns, glue_out_used = [], set()
    ga = top_assigns(TOP)
    for d, w, n, _ in ports:
        if d != "output":
            continue
        if n in driven:
            if n in ga:
                die("%s 既由子模块直接驱动又有 golden assign" % n)
            continue
        if n not in ga:
            die("本层输出 %s 在 golden 里既不接子模块也没有 assign" % n)
        if n in GLUE_OUT:
            ge, new = GLUE_OUT[n]
            if norm(ge) != ga[n]:
                die("GLUE_OUT %s golden 表达式漂了：表=%r golden=%r" % (n, ge, ga[n]))
            core_sig_ok(new)
            glue_out_used.add(n)
            assigns.append("  assign %s = %s;" % (n, new))
        elif golden_wire(cp, ga[n]):
            wi, wp = golden_wire(cp, ga[n])
            if cp[wi][wp] != ("output", w):
                die("%s <- %s 位宽不符" % (n, ga[n]))
            assigns.append("  assign %s = %s;" % (n, w_(wi, wp)))
        else:
            die("本层输出 %s 的 golden 驱动 %r 没有规则（须进 GLUE_OUT 表）" % (n, ga[n]))
        driven[n] = "assign"
    miss = set(GLUE_OUT) - glue_out_used
    if miss:
        die("GLUE_OUT 有没用到的条目：%s" % sorted(miss))

    # 胶水核连线
    known = set(wires) | set(pdir) | set(core_outs)
    core_decl, core_lines = [], []
    for c, how in CORE_CONNS:
        sigs = [how] if isinstance(how, str) else (how if isinstance(how, list) else [])
        for s in sigs:
            if s not in known:
                die("核连线 %s 用到未知信号 %s" % (c, s))
            if s in pdir and pdir[s][0] == "input":
                used_in.add(s)
        if isinstance(how, tuple):
            core_decl.append("  logic %s%s;" % (how[1] + " " if how[1] else "", how[2]))
            core_lines.append((c, how[2]))
        elif isinstance(how, list):
            core_lines.append((c, list(reversed(how))))
        else:
            core_lines.append((c, how))

    und = [n for d, w, n, _ in ports if d == "output" and n not in driven]
    if und:
        die("本层输出没人驱动：%s" % und[:8])
    unused = [n for d, w, n, _ in ports if d == "input" and n not in used_in]
    if set(unused) != set(UNUSED_IN):
        die("本层没人用的输入与 UNUSED_IN 不一致：实测 %s" % unused)
    for n in unused:
        if len(re.findall(r"\b%s\b" % n, golden_text(TOP))) != UNUSED_IN_GOLDEN_USES[n]:
            die("%s 在 golden 里有读者，却被声明为无人使用" % n)

    body = ["  // ---- 子模块输出线（<简称>_<端口名去掉 io_>）----"]
    for mod, inst, conns in insts:
        names = [w_(inst, p) for p, _ in conns if w_(inst, p) in wires]
        if not names:
            continue
        body.append("  // %s %s" % (mod, inst))
        for nm in names:
            body.append("  logic %s%s;" % (rng(wires[nm]), nm))
    body.append("")
    body.append("  // ---- 胶水核的输出线 ----")
    body += core_decl
    body.append("")
    width = max(len(c) for c, _ in core_lines)
    body.append("  %s u_core (" % CORE)
    for k, (c, sig) in enumerate(core_lines):
        tail = ")" + ("," if k + 1 < len(core_lines) else "")
        head = "    .%-*s (" % (width, c)
        if isinstance(sig, list):
            body += wrap_list(head + "{", sig, "}" + tail)
        else:
            body.append(head + sig + tail)
    body.append("  );")
    for blk in inst_blocks:
        body.append("")
        body += blk
    body.append("")
    body.append("  // ---- 本层输出 ----")
    body += assigns
    return "\n".join(body)


def port_block():
    ps = port_table(TOP)
    return "\n".join(p[3] + ("," if i + 1 < len(ps) else "") for i, p in enumerate(ps))


# ---------------------------------------------------------------------------
#  FM「匹配前」钉点：本层胶水寄存器 + 各子模块签核时的钉点（收割）
# ---------------------------------------------------------------------------
# (golden 寄存器, 位宽, 核里的寄存器元素)；核里的元素写法 = FM 的实例名（<名>_reg 后接下标）。
GLUE_PINS = (
    [("missQueue_io_l2_pf_store_only_REG", 1, "l2_pf_store_only_q"),
     ("missQueue_io_l2_hint_REG_valid", 1, "l2_hint_valid_q"),
     ("missQueue_io_l2_hint_REG_bits_sourceId", 4, "l2_hint_source_id_q"),
     ("io_error_bits_REG", 1, "err_src_valid_q[0]"),
     ("io_error_bits_REG_1", 1, "err_src_valid_q[1]"),
     ("io_error_bits_REG_2", 1, "err_src_valid_q[2]"),
     ("io_error_bits_r_paddr", 48, "err_src_paddr_q[0]"),
     ("io_error_bits_r_report_to_beu", 1, "err_src_beu_q[0]")]
    + [("io_error_bits_r_%d_paddr" % k, 48, "err_src_paddr_q[%d]" % k) for k in (1, 2, 3)]
    + [("io_error_bits_r_%d_report_to_beu" % k, 1, "err_src_beu_q[%d]" % k) for k in (1, 2, 3)]
    + [("io_error_bits_REG_4", 1, "err_any_q"),
       ("io_error_bits_r_4_paddr", 48, "err_out_paddr_q"),
       ("io_error_bits_r_4_report_to_beu", 1, "err_out_beu_q"),
       ("io_error_valid_REG", 1, "err_valid_q1"),
       ("io_error_valid_REG_1", 1, "err_valid_q2"),
       ("extra_flag_valid", 1, "extra_flag_valid_q"),
       ("extra_flag_way_en", 4, "extra_flag_way_en_q"),
       ("REG", 1, "tag_write_unintended_q"),
       ("done_r_counter", 1, "fwd_d_beat_cnt[0]"),
       ("done_r_counter_1", 1, "fwd_d_beat_cnt[1]"),
       ("done_r_counter_2", 1, "fwd_d_beat_cnt[2]"),
       ("io_lsu_atomics_resp_valid_REG", 1, "lsu_atomic_valid_q"),
       ("io_lsu_atomics_resp_bits_r_data", 128, "lsu_atomic_data_q"),
       ("io_lsu_atomics_resp_bits_r_miss", 1, "lsu_atomic_miss_q"),
       ("io_lsu_atomics_resp_bits_r_replay", 1, "lsu_atomic_replay_q"),
       ("io_lsu_atomics_resp_bits_r_tl_error_tl_denied", 1, "lsu_atomic_denied_q"),
       ("io_lsu_atomics_resp_bits_r_tl_error_tl_corrupt", 1, "lsu_atomic_corrupt_q"),
       ("io_lsu_atomics_resp_bits_r_id", 6, "lsu_atomic_id_q"),
       ("missQueue_io_main_pipe_resp_valid_REG", 1, "mq_mp_resp_valid_q"),
       ("missQueue_io_main_pipe_resp_bits_r_miss_id", 4, "mq_mp_resp_miss_id_q"),
       ("missQueue_io_main_pipe_resp_bits_r_ack_miss_queue", 1, "mq_mp_resp_ack_q"),
       ("io_lsu_store_replay_resp_valid_REG", 1, "store_replay_valid_q"),
       ("io_lsu_store_replay_resp_bits_r_id", 6, "store_replay_id_q"),
       ("mainPipe_io_invalid_resv_set_REG", 1, "invalid_resv_set_q"),
       ("io_lsu_release_valid_REG", 1, "release_valid_q"),
       ("io_lsu_release_bits_paddr_r", 48, "release_paddr_q")]
    + [("state_vec_%d" % s, 3, "plru_state[%d]" % s) for s in range(256)]
    + [("io_perf_%d_value_REG" % k, 6, "perf_q1[%d]" % k) for k in range(N_PERF)]
    + [("io_perf_%d_value_REG_1" % k, 6, "perf_q2[%d]" % k) for k in range(N_PERF)])

# 子模块签核时用的钉点文件（相对仓根）：{实例名: (子模块顶层名, 文件)}。
# 其余子模块签核时没有钉点文件（FM 按名配对），这里也不钉；CHILD_NO_PINS 逐个列出并核对。
CHILD_PINS = {
    "cacheCtrlOpt": ("CtrlUnit", "verif/ut/CtrlUnit/fm_pins_pre.tcl"),
    "bankedDataArray": ("BankedDataArray", "verif/ut/BankedDataArray/fm_pins_pre.tcl"),
    "mainPipe": ("MainPipe", "verif/ut/MainPipe/fm_pins_pre.tcl"),
    "missQueue": ("MissQueue", "verif/ut/MissQueue/fm_pins_pre.tcl"),
}
CHILD_NO_PINS = {
    "metaArray": "L1CohMetaArray", "errorArray": "L1ErrorMetaArray", "prefetchArray": "L1PrefetchSourceArray",
    "accessArray": "L1FlagMetaArray", "tagArray": "DuplicatedTagArray", "prefetcherMonitor": "PrefetcherMonitor",
    "fdpMonitor": "FDPrefetcherMonitor", "bloomFilter": "BloomFilter", "counterFilter": "CounterFilter",
    "ldu_0": "LoadPipe", "ldu_1": "LoadPipe", "ldu_2": "LoadPipe", "stu_0": "StorePipe", "stu_1": "StorePipe",
    "probeQueue": "ProbeQueue", "wb": "WritebackQueue", "tag_write_arb": "Arbiter1_TagWriteReq",
    "dataWriteArb": "Arbiter1_L1BankedDataWriteReq",
    **{k: "Arbiter1_L1BankedDataWriteReqCtrl" for k in ["dataWriteArb_dup"] + ["dataWriteArb_dup_%d" % i for i in range(1, 8)]},
    "missReqArb": "TreeArbiter", "missReadyGen": "MissReadyGen",
}
# 证明这些子模块签核时确实没有钉点文件：它们所在 UT 目录（verif/ut/<名>/）里没有 fm_pins_pre.tcl / fm_pins.tcl
CHILD_NO_PIN_UTS = ["L1CohMetaArray", "L1ErrorMetaArray", "L1PrefetchSourceArray", "L1FlagMetaArray",
                    "DuplicatedTagArray", "BloomFilter", "CounterFilter", "LoadPipe", "StorePipe",
                    "ProbeQueue", "WritebackQueue", "DCacheLeaves"]

HARVEST_TCL = r"""
set top [lindex $argv 0]
set ::__out [open [lindex $argv 2] w]
proc set_user_match {r i} { puts $::__out "$r\t$i"; return 1 }
source [lindex $argv 1]
close $::__out
"""


def harvest(child_top, pin_file):
    """在 tclsh 里用桩 set_user_match（恒返回 1、记下两侧名字）执行子模块自己的钉点文件，
    收回它实际发出的每一对名字。子文件自己的计数闸照常执行：任何一处 error 都让收割失败。
    `top` 设成子模块名 —— 与它单独签核时 fm_eq.tcl 里的 $top 相同（有的钉点文件会核对它）。"""
    with tempfile.TemporaryDirectory() as td:
        drv = os.path.join(td, "h.tcl")
        out = os.path.join(td, "pairs.tsv")
        open(drv, "w").write(HARVEST_TCL)
        r = subprocess.run(["tclsh", drv, child_top, os.path.join(REPO, pin_file), out],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
        if r.returncode != 0:
            die("收割 %s 失败：\n%s" % (pin_file, r.stdout[-2000:]))
        pairs = [tuple(l.split("\t")) for l in open(out).read().splitlines()]
    rp, ip = "r:/WORK/%s/" % child_top, "i:/WORK/%s/" % child_top
    for a, b in pairs:
        if not a.startswith(rp) or not b.startswith(ip):
            die("%s 的钉点 %s <-> %s 不在 %s 之下" % (pin_file, a, b, child_top))
    return [(a[len(rp):], b[len(ip):]) for a, b in pairs]


def glue_pairs():
    regs = golden_regs(TOP)
    pinned = [g for g, _, _ in GLUE_PINS]
    if len(set(pinned)) != len(pinned) or set(pinned) != set(regs):
        die("胶水钉点表与 golden 本层寄存器不一致：多 %s 少 %s"
            % (sorted(set(pinned) - set(regs)), sorted(set(regs) - set(pinned))))
    out = []
    for g, w, core in GLUE_PINS:
        if regs[g] != w:
            die("钉点 %s 位宽 golden=%d 表=%d" % (g, regs[g], w))
        m = re.fullmatch(r"(\w+)((?:\[\d+\])*)", core)
        for b in range(w):
            rb = "%s_reg" % g + ("[%d]" % b if w > 1 else "")
            ib = "u_core/%s_reg%s" % (m.group(1), m.group(2)) + ("[%d]" % b if w > 1 else "")
            out.append((rb, ib))
    return out


def all_pairs():
    insts = {inst: mod for mod, inst, _ in instances(TOP)}
    if set(CHILD_PINS) | set(CHILD_NO_PINS) != set(insts) or set(CHILD_PINS) & set(CHILD_NO_PINS):
        die("CHILD_PINS ∪ CHILD_NO_PINS 必须恰好划分全部实例")
    for inst, (mod, _) in CHILD_PINS.items():
        if insts[inst] != mod:
            die("CHILD_PINS %s 是 %s 不是 %s" % (inst, insts[inst], mod))
    for inst, mod in CHILD_NO_PINS.items():
        if insts[inst] != mod:
            die("CHILD_NO_PINS %s 是 %s 不是 %s" % (inst, insts[inst], mod))
    for ut in CHILD_NO_PIN_UTS:
        d = os.path.join(REPO, "verif/ut", ut)
        if not os.path.isdir(d):
            die("UT 目录 %s 不存在" % d)
        for f in ("fm_pins_pre.tcl", "fm_pins.tcl"):
            if os.path.exists(os.path.join(d, f)):
                die("%s 有 %s，却被列为无钉点" % (ut, f))
    out = glue_pairs()
    counts = [("glue", len(out))]
    for inst, (ctop, f) in CHILD_PINS.items():
        ps = [(inst + "/" + a, inst + "/" + b) for a, b in harvest(ctop, f)]
        counts.append((inst, len(ps)))
        out += ps
    return out, counts


def gen_pins():
    pairs, counts = all_pairs()
    seen_r, seen_i = set(), set()
    for a, b in pairs:
        if a in seen_r or b in seen_i:
            die("钉点不是一一对应：%s / %s" % (a, b))
        seen_r.add(a)
        seen_i.add(b)
        if "{" in a + b or "}" in a + b or a.endswith("\\") or b.endswith("\\"):
            die("钉点名字含花括号/结尾反斜杠，不能用 {} 引用：%s" % a)
    n = len(pairs)
    o = ["# DCache FM「匹配前」钉点 —— 自动生成：scripts/gen_dcache.py（勿手改）",
         "#",
         "# 两侧都是整棵子树白盒：ref 读 golden 各子模块，impl 读本仓重写件。名字差有两层：",
         "#   (1) 本层胶水寄存器：golden 平铺名（state_vec_<s> / io_perf_<k>_value_REG / io_error_bits_r_* ...）",
         "#       <-> 核里的数组元素 u_core/...（逐位写死，见 gen_dcache.py 的 GLUE_PINS）；",
         "#   (2) 子模块内部：直接收割该子模块签核时用的那份 fm_pins_pre.tcl（tclsh 里用桩执行、逐对记下），",
         "#       把 <子模块>/ 前缀换成 <实例名>/ —— 与子模块单独签核时是同一批点对。",
         "# 签核时没有钉点文件的子模块（FM 按名配对）这里也不钉（gen_dcache.py 的 CHILD_NO_PINS 逐个核对）。",
         "#",
         "# 组成（条数）：" + "，".join("%s %d" % c for c in counts) + "，合计 %d。" % n,
         "# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。",
         "# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。",
         "proc _dc_pre_pin { } {",
         "    set _expect %d" % n,
         "    set r \"r:/WORK/%s\"" % TOP,
         "    set i \"i:/WORK/%s\"" % TOP,
         "    set pairs {"]
    for a, b in pairs:
        o.append("        {%s} {%s}" % (a, b))
    o += ["    }",
          "    puts \"DC_PREPIN_BEGIN %s expect=$_expect\"" % TOP,
          "    set n 0",
          "    foreach {rp ip} $pairs {",
          "        if {![set_user_match \"$r/$rp\" \"$i/$ip\"]} {",
          "            puts \"DC_PREPIN_FAIL: set_user_match returned 0 for $r/$rp <-> $i/$ip\"",
          "            error \"DC_PREPIN_MISS=$rp\"",
          "        }",
          "        incr n",
          "    }",
          "    puts \"DC_PREPIN_END %s n=$n expect=$_expect\"" % TOP,
          "    if {$n != $_expect} {",
          "        puts \"DC_PREPIN_ERROR: pinned $n but expected $_expect\"",
          "        error \"DC_PREPIN_COUNT=$n\"",
          "    }",
          "}",
          "_dc_pre_pin"]
    return os.path.join(REPO, "verif/ut/DCache/fm_pins_pre.tcl"), "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  UT testbench 的生成区（verif/ut/DCache/tb.sv；手写区不动）
# ---------------------------------------------------------------------------
def qualifier(outs, n):
    """输出 n 的"有效位"限定：最长前缀 P 使 n 以 P_bits_ 开头且 P_valid 也是输出。无则 None。"""
    best = None
    for m in re.finditer(r"_bits_", n):
        v = n[:m.start()] + "_valid"
        if v in outs:
            best = v
    return best


def tb_ports():
    ps = port_table(TOP)
    L = ["  // ---- 输入（两侧共用；clock/reset 由手写区驱动；未驱动的口保持 0）----"]
    for d, w, n, _ in ps:
        if d == "input" and n not in ("clock", "reset"):
            L.append("  logic %s%s = '0;" % (rng(w), n))
    L.append("  // ---- 输出（g_ = golden，i_ = 重写）----")
    for d, w, n, _ in ps:
        if d == "output":
            L.append("  wire  %sg_%s, i_%s;" % (rng(w), n, n))
    for inst, pre, mod in (("u_gold", "g_", TOP), ("u_impl", "i_", TOP + "_xs")):
        L.append("  %s %s (" % (mod, inst))
        conns = ["    .%s(%s)" % (n, n if d == "input" else pre + n) for d, w, n, _ in ps]
        L.append(",\n".join(conns))
        L.append("  );")
    return L


def tb_compare():
    """逐位比全部输出。cmp_all=1（全常量初值档）时复位后全比；本层随机初值档下 *_bits_* 只在
    golden 的对应 *_valid 为 1 时比，且每个端口在两侧第一次相等之后才开始比（arm）。
    另记每个输出位见过 0/1（toggle 覆盖）。"""
    outs = [(w, n) for d, w, n, _ in port_table(TOP) if d == "output"]
    names = {n for _, n in outs}
    L = []
    for w, n in outs:
        L.append("  logic %sseen1_%s = '0, seen0_%s = '0;" % (rng(w), n, n))
    for w, n in outs:
        L.append("  bit armed_%s = 0;" % n)
    L.append("  task automatic compare_outputs();")
    for w, n in outs:
        q = qualifier(names, n)
        cond = "g_%s !== i_%s" % (n, n)
        if q:
            cond = "(cmp_all | g_%s) && (%s)" % (q, cond)
        L.append("    if (!cmp_all && !armed_%s && g_%s === i_%s) armed_%s = 1;" % (n, n, n, n))
        L.append("    if ((cmp_all | armed_%s) && %s) begin" % (n, cond))
        L.append("      errors++;")
        L.append("      if (errors <= 30) $display(\"MISMATCH cyc=%%0d %s: g=%%h i=%%h\", cyc, g_%s, i_%s);" % (n, n, n))
        L.append("    end")
        L.append("    seen1_%s |= g_%s;" % (n, n))
        L.append("    seen0_%s |= ~g_%s;" % (n, n))
    L.append("    checks++;")
    L.append("  endtask")
    L.append("  // 从未翻转过的输出位个数（逐端口打印前 60 个）")
    L.append("  function automatic int report_toggle();")
    L.append("    int bad = 0;")
    L.append("    int ports = 0;")
    for w, n in outs:
        L.append("    if ((~seen1_%s | ~seen0_%s) != '0) begin ports++; bad += $countones(~seen1_%s | ~seen0_%s);"
                 " if (ports <= 60) $display(\"TOGGLE MISS %s 1=%%h 0=%%h\", seen1_%s, seen0_%s); end"
                 % (n, n, n, n, n, n, n))
    L.append("    begin int na = 0;")
    for w, n in outs:
        L.append("      if (!cmp_all && !armed_%s) begin na++; if (na <= 40) $display(\"NEVER ARMED %s\"); end" % (n, n))
    L.append("      $display(\"ARMED: %0d ports never armed (glue-random mode only)\", na);")
    L.append("    end")
    L.append("    $display(\"TOGGLE: %%0d output bits never toggled, in %%0d ports (of %d ports / %d bits)\", bad, ports);"
             % (len(outs), sum(w for w, _ in outs)))
    L.append("    return bad;")
    L.append("  endfunction")
    return L


def gen_tb():
    path = os.path.join(REPO, "verif/ut/DCache/tb.sv")
    text = open(path).read()
    text = replace_region(text, "tb-ports", "\n".join(tb_ports()))
    text = replace_region(text, "tb-compare", "\n".join(tb_compare()))
    return path, text


# ---------------------------------------------------------------------------
#  assembly 黑盒声明：收割子模块签核时的 allow 声明（只收子模块顶层之下的实例，按 codex 0199 的
#  「只比 /WORK/<top>/ 下实例」口径；子模块容器里的辅助 design root 不是本目标的实例）
# ---------------------------------------------------------------------------
CHILD_ALLOW = {"bankedDataArray": "BankedDataArray", "tagArray": "DuplicatedTagArray"}
ALLOW_EXPECT = {"array_7_ext": 32, "array_8_ext": 8}    # 每侧的实例数（字面）


def gen_allow():
    objs = []
    for inst, ctop in CHILD_ALLOW.items():
        d = json.load(open(os.path.join(REPO, "verif/allow/%s.json" % ctop)))
        if d.get("target") != ctop:
            die("verif/allow/%s.json 的 target 不是 %s" % (ctop, ctop))
        for o in d["objects"]:
            pre = "%s:/WORK/%s/" % (o["side"], ctop)
            if not o["path"].startswith(pre):
                continue          # 辅助 design root（uniquify 副本），不是 <ctop> 的实例
            if o["class"] != "vendor_macro":
                die("%s 的 allow 对象 %s 不是 vendor_macro" % (ctop, o["path"]))
            n = dict(o)
            n["path"] = "%s:/WORK/%s/%s/%s" % (o["side"], TOP, inst, o["path"][len(pre):])
            objs.append(n)
        base = d["baseline"]
    for side in ("r", "i"):
        for design, k in ALLOW_EXPECT.items():
            got = sum(1 for o in objs if o["side"] == side and o["design"] == design)
            if got != k:
                die("allow 收割：%s 侧 %s 实例 %d 个，字面期望 %d" % (side, design, got, k))
    if len({o["path"] for o in objs}) != len(objs):
        die("allow 收割出重复路径")
    out = {"schema": "xs-v2-sv-allow-v1", "target": TOP, "baseline": base, "objects": objs}
    return os.path.join(REPO, "verif/allow/%s.json" % TOP), json.dumps(out, indent=1, ensure_ascii=False) + "\n"


def gen_rtl():
    text = open(RTL_FILE).read()
    text = replace_region(text, "dcache-ports", port_block())
    text = replace_region(text, "dcache-body", build_body())
    return RTL_FILE, text


GENERATORS = [gen_rtl, gen_pins, gen_tb, gen_allow]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    drift = 0
    for g in GENERATORS:
        path, text = g()
        old = open(path).read() if os.path.exists(path) else None
        rel = os.path.relpath(path, REPO)
        if old == text:
            continue
        if a.check:
            print("DRIFT: %s" % rel)
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "w").write(text)
            print("wrote %s" % rel)
    if a.check:
        print("gen_dcache --check: %s" % ("DRIFT" if drift else "OK"))
        return 1 if drift else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
