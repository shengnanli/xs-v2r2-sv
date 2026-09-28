#!/usr/bin/env python3
"""gen_lquncache.py —— LoadQueueUncache 的机械派生区生成器。

LoadQueueUncache 的 golden 59,051 行几乎全是展平：7 种 bundle（每种 4 .. 203 个字段）
在 16 个条目实例、5 个流水寄存器实例、1 个仲裁器实例的端口上逐字段连线，外加 wrapper
级 1425 个端口。这些都是**没有微架构**的机械部分，由本脚本从 golden 端口表生成；
可读核（xs_LoadQueueUncache_core 的 §1..§10）是手写的，本脚本一个字节都不碰。

生成对象：
  rtl/memblock/LoadQueueUncache.sv 的四个 GENERATED 区：
    lqu-types    package 里的 bundle 结构体（字段表逐字取 golden 端口表）+ 投影函数 to_ent_req
    lqu-entries  16 个 UncacheEntry 实例（端口逐字段接到核的条目数组）
    lqu-pipes    RRArbiterInit_11 + 5 个 PipelineRegModule 实例
    lqu-wrapper  golden 同名 wrapper（1425 个端口 <-> 核的结构体端口）
  verif/ut/LoadQueueUncache/fm_pins_pre.tcl   FM 匹配前逐位钉点
  verif/ut/LoadQueueUncache/tb.sv             双例化 UT（激励逻辑见其文件头）

生成前的机械核对（任何一项不符即失败，不生成）：
  (1) 结构体取自哪张端口表、与之必须逐项同名同宽同序的其它端口表（见 BUNDLES 的 same_as）；
  (2) golden LoadQueueUncache 的每个端口恰好命中一条映射规则，每条规则至少命中一个端口；
  (3) 每个 child 实例的每个端口恰好命中一条接线规则；
  (4) 钉点：golden 顶层每个寄存器恰好命中一条映射规则、映射是单射，位数与寄存器位数相等；
      child 流水寄存器的钉点位数 = 各自寄存器位数；
  (5) --check：生成结果与磁盘逐字节比较。

用法:
  scripts/gen_lquncache.py            # 写文件
  scripts/gen_lquncache.py --check    # 只比对，不写；有漂移 rc=1
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "memblock")
UT = os.path.join(REPO, "verif", "ut", "LoadQueueUncache")
LQU = os.path.join(RTL, "LoadQueueUncache.sv")
TOP = "LoadQueueUncache"
NUM_ENTRIES = 16
LD_W = 3

SV_KEYWORDS = {"alias", "type", "bit", "byte", "int", "logic", "reg", "wire", "input", "output",
               "inout", "module", "begin", "end", "case", "default", "function", "task", "string",
               "event", "time", "real", "class", "struct", "union", "enum", "package", "interface",
               "property", "sequence", "assert", "cover", "assume", "bind", "const", "var", "ref",
               "virtual", "static", "automatic", "local", "protected", "rand", "randc", "with",
               "unique", "priority", "final", "initial", "always", "fork", "join", "do", "while",
               "for", "foreach", "repeat", "forever", "if", "else", "return", "break", "continue",
               "void", "shortint", "longint", "integer", "signed", "unsigned", "edge", "posedge",
               "negedge", "or", "and", "not", "xor", "nand", "nor", "buf", "supply0", "supply1",
               "table", "config", "cell", "library", "design", "instance", "use", "liblist",
               "specify", "generate", "genvar", "parameter", "localparam", "defparam", "import",
               "export", "extern", "context", "pure", "chandle", "null", "this", "super", "new",
               "matches", "tagged", "wait", "disable", "inside", "dist", "solve", "before", "first_match",
               "throughout", "within", "intersect", "iff", "global", "clocking", "checker", "let",
               "program", "primitive", "timeprecision", "timeunit", "force", "release", "assign",
               "deassign", "wand", "wor", "tri", "tri0", "tri1", "triand", "trior", "trireg",
               "uwire", "cmos", "rcmos", "nmos", "pmos", "rnmos", "rpmos", "tran", "tranif0",
               "tranif1", "rtran", "rtranif0", "rtranif1", "pullup", "pulldown", "highz0", "highz1",
               "strong0", "strong1", "pull0", "pull1", "weak0", "weak1", "large", "medium", "small",
               "scalared", "vectored", "showcancelled", "noshowcancelled", "pulsestyle_onevent",
               "pulsestyle_ondetect", "specparam", "macromodule", "endmodule", "casex", "casez",
               "endcase", "join_any", "join_none", "randcase", "randsequence", "coverpoint", "cross",
               "bins", "binsof", "illegal_bins", "ignore_bins", "wildcard", "covergroup", "modport",
               "nettype", "interconnect", "implements", "implies", "nexttime", "s_always",
               "s_eventually", "s_nexttime", "s_until", "s_until_with", "strong", "weak", "until",
               "until_with", "untyped", "accept_on", "reject_on", "sync_accept_on", "sync_reject_on",
               "eventually", "restrict", "soft", "unique0", "endfunction"}


def die(msg):
    raise SystemExit("gen_lquncache: " + msg)


_PORT_CACHE = {}


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    if module in _PORT_CACHE:
        return _PORT_CACHE[module]
    lines = open(os.path.join(GOLDEN_DIR, module + ".sv")).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    pat = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")
    for l in lines[start + 1:end]:
        m = pat.match(l)
        if not m:
            die("端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    _PORT_CACHE[module] = out
    return out


def fields(module, prefix):
    return [(n[len(prefix):], w) for _, w, n, _ in port_table(module) if n.startswith(prefix)]


# ---------------------------------------------------------------------------
#  bundle 结构体：(类型名, 取自 (模块, 端口前缀), 必须与之同形的其它端口表, 一句话)
# ---------------------------------------------------------------------------
BUNDLES = [
    ("lqu_req_t", (TOP, "io_req_0_bits_"),
     [(TOP, "io_req_1_bits_"), (TOP, "io_req_2_bits_")],
     "load 流水线交来的整条 load（LqWriteBundle 在本层被用到的字段）"),
    ("lqu_ent_req_t", ("UncacheEntry", "io_req_bits_"), [],
     "写进条目的请求（lqu_req_t 去掉 exceptionVec_5/19 与 rep_info：条目自己不用，父级也不传）"),
    ("lqu_mmio_out_t", ("UncacheEntry", "io_mmioOut_bits_"),
     [("PipelineRegModule_1", "io_in_bits_"), ("PipelineRegModule_1", "io_out_bits_"),
      (TOP, "io_mmioOut_2_bits_")],
     "MMIO 写回（MemExuOutput）"),
    ("lqu_nc_out_t", ("UncacheEntry", "io_ncOut_bits_"),
     [("PipelineRegModule_2", "io_in_bits_"), ("PipelineRegModule_2", "io_out_bits_"),
      (TOP, "io_ncOut_0_bits_"), (TOP, "io_ncOut_1_bits_"), (TOP, "io_ncOut_2_bits_")],
     "NC 写回（LsPipelineBundle）"),
    ("lqu_raw_t", ("UncacheEntry", "io_mmioRawData_"), [(TOP, "io_mmioRawData_2_")],
     "MMIO 原始数据（LoadDataFromLQBundle：lqData + 拼数据要用的 fuOpType/fpWen/地址低位）"),
    ("lqu_ent_ureq_t", ("UncacheEntry", "io_uncache_req_bits_"), [("RRArbiterInit_11", "io_in_0_bits_")],
     "条目发出的 uncache 请求（不含 cmd/data/id：它们是常数或由父级填）"),
    ("lqu_ureq_t", ("PipelineRegModule", "io_in_bits_"),
     [("PipelineRegModule", "io_out_bits_"), (TOP, "io_uncache_req_bits_")],
     "发往 Uncache 的总线请求（UncacheWordReq 在本层被用到的字段）"),
    ("lqu_exc_t", ("UncacheEntry", "io_exception_bits_"), [(TOP, "io_exception_bits_")],
     "写回那一拍广播给 LoadQueue 的异常信息（只剩异常位/robIdx/uopIdx/地址这几项）"),
    ("lqu_rollback_t", (TOP, "io_rollback_bits_"), [],
     "满了回滚用的 redirect（Redirect 在本层被用到的字段）"),
]


def bundle_fields():
    out = {}
    for tname, (mod, pre), same, _ in BUNDLES:
        f = fields(mod, pre)
        if not f:
            die("%s: %s/%s* 没有端口" % (tname, mod, pre))
        for n, _ in f:
            if n in SV_KEYWORDS:
                die("%s: 字段名 %s 是 SV 关键字" % (tname, n))
        for m2, p2 in same:
            if fields(m2, p2) != f:
                die("%s: %s/%s* 与 %s/%s* 的字段表不一致" % (tname, m2, p2, mod, pre))
        out[tname] = f
    # 条目请求必须是 lqu_req_t 的保序子集（to_ent_req 按名字投影）
    req = [n for n, _ in out["lqu_req_t"]]
    ent = [n for n, _ in out["lqu_ent_req_t"]]
    if [n for n in req if n in set(ent)] != ent:
        die("lqu_ent_req_t 不是 lqu_req_t 的保序子集")
    wreq = dict(out["lqu_req_t"])
    for n, w in out["lqu_ent_req_t"]:
        if wreq[n] != w:
            die("lqu_ent_req_t.%s 位宽与 lqu_req_t 不同" % n)
    # 仲裁器输出 = 条目请求 + id
    if fields("RRArbiterInit_11", "io_out_bits_") != out["lqu_ent_ureq_t"][:-2] + [("id", 7)] + out["lqu_ent_ureq_t"][-2:]:
        die("RRArbiterInit_11 io_out_bits_* 不是 条目请求字段 + id")
    return out


def decl(w):
    return "logic" if w == 1 else "logic [%d:0]" % (w - 1)


def gen_types(bf):
    o = []
    for tname, (mod, pre), same, brief in BUNDLES:
        f = bf[tname]
        o.append("  // %s：%s" % (tname, brief))
        o.append("  //   %d 字段 / %d 位，字段表取自 golden %s 的 %s*%s" % (
            len(f), sum(w for _, w in f), mod, pre,
            "（与 " + "、".join("%s %s*" % (m, p) for m, p in same) + " 逐项相同）" if same else ""))
        o.append("  typedef struct packed {")
        for n, w in f:
            o.append("    %-13s %s;" % (decl(w), n))
        o.append("  } %s;" % tname)
        o.append("")
    o.append("  // LqWriteBundle -> 条目请求：按字段名投影（丢掉 exceptionVec_5/19 与 rep_info_cause_*）")
    o.append("  function automatic lqu_ent_req_t to_ent_req(lqu_req_t r);")
    o.append("    lqu_ent_req_t e;")
    for n, _ in bf["lqu_ent_req_t"]:
        o.append("    e.%s = r.%s;" % (n, n))
    o.append("    return e;")
    o.append("  endfunction")
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  child 实例接线规则：(正则, 表达式模板)。{i} = 条目号；\1 等 = 正则分组
# ---------------------------------------------------------------------------
ENTRY_RULES = [
    (r"clock", "clock"),
    (r"reset", "reset"),
    (r"(io_redirect_\w+)", r"\1"),
    (r"(io_rob_pending\w+)", r"\1"),
    (r"io_flush", "ent_flush[{i}]"),
    (r"io_mmioSelect", "ent_mmio_sel[{i}]"),
    (r"io_slaveId_valid", "ent_slave_valid[{i}]"),
    (r"io_slaveId_bits", "ent_slave_id[{i}]"),
    (r"io_req_valid", "ent_req_valid[{i}]"),
    (r"io_req_bits_(\w+)", r"ent_req_bits[{i}].\1"),
    (r"io_mmioOut_ready", "ent_mmio_ready[{i}]"),
    (r"io_mmioOut_valid", "ent_mmio_valid[{i}]"),
    (r"io_mmioOut_bits_(\w+)", r"ent_mmio_bits[{i}].\1"),
    (r"io_mmioRawData_(\w+)", r"ent_raw[{i}].\1"),
    (r"io_ncOut_ready", "ent_nc_ready[{i}]"),
    (r"io_ncOut_valid", "ent_nc_valid[{i}]"),
    (r"io_ncOut_bits_(\w+)", r"ent_nc_bits[{i}].\1"),
    (r"io_uncache_req_ready", "ent_ureq_ready[{i}]"),
    (r"io_uncache_req_valid", "ent_ureq_valid[{i}]"),
    (r"io_uncache_req_bits_(\w+)", r"ent_ureq_bits[{i}].\1"),
    (r"io_uncache_idResp_valid", "ent_idresp_valid[{i}]"),
    (r"(io_uncache_idResp_bits_\w+)", r"\1"),
    (r"io_uncache_resp_valid", "ent_resp_valid[{i}]"),
    (r"(io_uncache_resp_bits_\w+)", r"\1"),
    (r"io_exception_valid", "ent_exc_valid[{i}]"),
    (r"io_exception_bits_(\w+)", r"ent_exc_bits[{i}].\1"),
]

ARB_RULES = [
    (r"clock", "clock"),
    (r"reset", "reset"),
    (r"io_in_(\d+)_ready", r"arb_in_ready[\1]"),
    (r"io_in_(\d+)_valid", r"arb_in_valid[\1]"),
    (r"io_in_(\d+)_bits_(\w+)", r"ent_ureq_bits[\1].\2"),
    (r"io_out_ready", "arb_out_ready"),
    (r"io_out_valid", "arb_out_valid"),
    (r"io_out_bits_id", "arb_out_id"),
    (r"io_out_bits_(?!id$)(\w+)", r"arb_out_bits.\1"),
]


def pipe_rules(in_pfx, out_pfx):
    """流水寄存器：in 侧接核内信号 <in_pfx>_{ready,valid,bits}，out 侧接核端口 <out_pfx>_*。"""
    return [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_ready", in_pfx + "_in_ready"),
        (r"io_in_valid", in_pfx + "_in_valid"),
        (r"io_in_bits_(\w+)", in_pfx + r"_in_bits.\1"),
        (r"io_out_ready", out_pfx + "_ready"),
        (r"io_out_valid", out_pfx + "_valid"),
        (r"io_out_bits_(\w+)", out_pfx + r"_bits.\1"),
    ]


PIPES = [
    # (模块, 实例名, in 侧信号前缀, out 侧核端口前缀, 说明)
    ("PipelineRegModule", "pipelineReg", "ureq_pipe", "io_uncache_req",
     "uncache 总线请求出口（io.uncache.req）"),
    ("PipelineRegModule_1", "pipelineReg_1", "mmio_pipe", "io_mmioOut",
     "MMIO 写回出口（io.mmioOut(2)）"),
    ("PipelineRegModule_2", "pipelineReg_2", "nc_pipe[0]", "io_ncOut[0]",
     "NC 写回 0 号口（不接任何条目：in_valid 恒 0）"),
    ("PipelineRegModule_2", "pipelineReg_3", "nc_pipe[1]", "io_ncOut[1]",
     "NC 写回 1 号口（偶数号条目组）"),
    ("PipelineRegModule_2", "pipelineReg_4", "nc_pipe[2]", "io_ncOut[2]",
     "NC 写回 2 号口（奇数号条目组）"),
]


def pipe_expr(s):
    """把 'nc_pipe[1]_in_bits.f' 这种写法变成合法的 SV：nc_pipe_in_bits[1].f。"""
    m = re.match(r"(\w+)\[(\d+)\]_(\w+?)(\..*)?$", s)
    if m:
        return "%s_%s[%s]%s" % (m.group(1), m.group(3), m.group(2), m.group(4) or "")
    return s


def apply_rules(module, rules, i=None):
    used = [0] * len(rules)
    out = []
    for _, _, name, _ in port_table(module):
        hits = [k for k, (pat, _) in enumerate(rules) if re.fullmatch(pat, name)]
        if len(hits) != 1:
            die("%s 端口 %s 命中 %d 条接线规则（必须恰好 1 条）" % (module, name, len(hits)))
        k = hits[0]
        used[k] += 1
        pat, tpl = rules[k]
        expr = re.sub(pat, tpl, name) if "\\" in tpl else tpl
        if i is not None:
            expr = expr.replace("{i}", str(i))
        out.append((name, pipe_expr(expr)))
    for k, u in enumerate(used):
        if u == 0:
            die("%s 的接线规则 %r 一个端口都没命中（规则写错了？）" % (module, rules[k][0]))
    return out


def inst(module, name, conns):
    o = ["  %s %s (" % (module, name)]
    width = max(len(n) for n, _ in conns)
    for k, (n, e) in enumerate(conns):
        o.append("    .%-*s (%s)%s" % (width, n, e, "," if k + 1 < len(conns) else ""))
    o.append("  );")
    return o


def gen_entries():
    o = []
    for i in range(NUM_ENTRIES):
        mod = "UncacheEntry" if i == 0 else "UncacheEntry_%d" % i
        # 16 个变体端口表必须逐字相同（只差认领常数）
        if [p[:3] for p in port_table(mod)] != [p[:3] for p in port_table("UncacheEntry")]:
            die("%s 端口表与 UncacheEntry 不同" % mod)
        o.append("  // 条目 %d" % i)
        o += inst(mod, "entries_%d" % i, apply_rules(mod, ENTRY_RULES, i))
        o.append("")
    return "\n".join(o)


def gen_pipes():
    o = []
    o.append("  // NC 请求的 16 路轮转仲裁（§5）")
    o += inst("RRArbiterInit_11", "ncReqArb", apply_rules("RRArbiterInit_11", ARB_RULES))
    o.append("")
    for mod, name, ip, op, brief in PIPES:
        o.append("  // %s" % brief)
        o += inst(mod, name, apply_rules(mod, pipe_rules(ip, op)))
        o.append("")
    return "\n".join(o)


# ---------------------------------------------------------------------------
#  wrapper：golden 端口 -> 核端口
# ---------------------------------------------------------------------------
# (正则, 核端口名, 形状)  形状: scalar / vbit(索引=\1) / arr(索引=\1) / sarr(索引=\1, 字段=\2) / s(字段=\1)
WRAP_RULES = [
    (r"clock|reset|io_redirect_\w+|io_rob_pendingMMIOld|io_rob_pendingPtr_\w+|io_uncache_req_ready"
     r"|io_uncache_req_valid|io_uncache_idResp_\w+|io_uncache_resp_\w+|io_rollback_valid"
     r"|io_exception_valid", None, "scalar"),
    (r"io_rob_loadMmio_(\d)", "io_rob_loadMmio", "vbit"),
    (r"io_rob_loadMmioUop_(\d)_robIdx_value", "io_rob_loadMmioUop_robIdx_value", "arr"),
    (r"io_req_(\d)_valid", "io_req_valid", "vbit"),
    (r"io_req_(\d)_bits_(\w+)", "io_req_bits", "sarr"),
    (r"io_mmioOut_2_ready", "io_mmioOut_ready", "rename"),
    (r"io_mmioOut_2_valid", "io_mmioOut_valid", "rename"),
    (r"io_mmioOut_2_bits_(\w+)", "io_mmioOut_bits", "s"),
    (r"io_mmioRawData_2_(\w+)", "io_mmioRawData", "s"),
    (r"io_ncOut_(\d)_ready", "io_ncOut_ready", "vbit"),
    (r"io_ncOut_(\d)_valid", "io_ncOut_valid", "vbit"),
    (r"io_ncOut_(\d)_bits_(\w+)", "io_ncOut_bits", "sarr"),
    (r"io_uncache_req_bits_(\w+)", "io_uncache_req_bits", "s"),
    (r"io_rollback_bits_(\w+)", "io_rollback_bits", "s"),
    (r"io_exception_bits_(\w+)", "io_exception_bits", "s"),
]

# 核端口声明（名字 -> (方向, 类型, 非打包维)），与手写核的端口表一致（elaborate 会核对）
CORE_AGG = {
    "io_rob_loadMmio": ("output", "logic [LD_W-1:0]", ""),
    "io_rob_loadMmioUop_robIdx_value": ("output", "logic [7:0]", " [LD_W]"),
    "io_req_valid": ("input", "logic [LD_W-1:0]", ""),
    "io_req_bits": ("input", "lqu_req_t", " [LD_W]"),
    "io_mmioOut_bits": ("output", "lqu_mmio_out_t", ""),
    "io_mmioRawData": ("output", "lqu_raw_t", ""),
    "io_ncOut_ready": ("input", "logic [LD_W-1:0]", ""),
    "io_ncOut_valid": ("output", "logic [LD_W-1:0]", ""),
    "io_ncOut_bits": ("output", "lqu_nc_out_t", " [LD_W]"),
    "io_uncache_req_bits": ("output", "lqu_ureq_t", ""),
    "io_rollback_bits": ("output", "lqu_rollback_t", ""),
    "io_exception_bits": ("output", "lqu_exc_t", ""),
}


def classify_top():
    """每个 golden 端口 -> (规则下标, 核端口, 核侧表达式)。"""
    used = [0] * len(WRAP_RULES)
    out = []
    for d, w, name, raw in port_table(TOP):
        hits = [k for k, (pat, _, _) in enumerate(WRAP_RULES) if re.fullmatch(pat, name)]
        if len(hits) != 1:
            die("golden 端口 %s 命中 %d 条 wrapper 规则（必须恰好 1 条）" % (name, len(hits)))
        k = hits[0]
        used[k] += 1
        pat, cport, shape = WRAP_RULES[k]
        m = re.fullmatch(pat, name)
        if shape == "scalar":
            out.append((d, name, name, "c_" + name, shape))
        elif shape == "rename":
            out.append((d, name, cport, "c_" + cport, shape))
        elif shape == "vbit":
            out.append((d, name, cport, "c_%s[%s]" % (cport, m.group(1)), shape))
        elif shape == "arr":
            out.append((d, name, cport, "c_%s[%s]" % (cport, m.group(1)), shape))
        elif shape == "sarr":
            out.append((d, name, cport, "c_%s[%s].%s" % (cport, m.group(1), m.group(2)), shape))
        elif shape == "s":
            out.append((d, name, cport, "c_%s.%s" % (cport, m.group(1)), shape))
    for k, u in enumerate(used):
        if u == 0:
            die("wrapper 规则 %r 没命中任何端口" % WRAP_RULES[k][0])
    return out


def gen_wrapper():
    ports = port_table(TOP)
    cls = classify_top()
    o = []
    o.append("// " + "=" * 77)
    o.append("// LoadQueueUncache（golden 同名 wrapper）—— 端口表逐字取 golden（1425 个），")
    o.append("// 按 bundle 装/拆成核的结构体端口。整段由 scripts/gen_lquncache.py 生成，勿手改。")
    o.append("// " + "=" * 77)
    o.append("module %s" % TOP)
    o.append("  import loadqueueuncache_pkg::*;")
    o.append("(")
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i + 1 < len(ports) else ""))
    o.append(");")
    # 聚合端口的本地信号
    for cport, (d, t, dim) in CORE_AGG.items():
        o.append("  %s c_%s%s;" % (t, cport, dim))
    o.append("")
    for d, name, cport, expr, shape in cls:
        if shape in ("scalar", "rename"):
            continue
        if d == "input":
            o.append("  assign %s = %s;" % (expr, name))
    o.append("")
    o.append("  xs_LoadQueueUncache_core u_core (")
    conns = []
    seen = set()
    for d, name, cport, expr, shape in cls:
        if shape == "scalar":
            conns.append((name, name))
        elif shape == "rename":
            conns.append((cport, name))
        elif cport not in seen:
            seen.add(cport)
            conns.append((cport, "c_" + cport))
    width = max(len(n) for n, _ in conns)
    for k, (n, e) in enumerate(conns):
        o.append("    .%-*s (%s)%s" % (width, n, e, "," if k + 1 < len(conns) else ""))
    o.append("  );")
    o.append("")
    for d, name, cport, expr, shape in cls:
        if shape in ("scalar", "rename"):
            continue
        if d == "output":
            o.append("  assign %s = %s;" % (name, expr))
    o.append("endmodule")
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  FM 钉点
# ---------------------------------------------------------------------------
def golden_regs(module):
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    s = t.index("module %s(" % module)
    e = t.index("endmodule", s)
    regs = re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", t[s:e], re.M)
    return [(n, int(a) - int(b) + 1 if a else 1) for a, b, n in regs]


REDIRECT_FIELDS = [("valid", 1), ("robIdx_flag", 1), ("robIdx_value", 8), ("level", 1)]


def top_reg_map(bf):
    """golden 顶层寄存器 -> 核内寄存器（FM 名字形状），返回 [(golden名, 宽, impl名)]。"""
    rules = []
    for k in range(LD_W):
        for f, w in bf["lqu_req_t"]:
            rules.append(("s2_req_%d_%s" % (k, f), w, "s2_req_q_reg[%d]\\[%s]" % (k, f)))
    for k, gname in enumerate(["s2_valid_REG", "s2_valid_REG_2", "s2_valid_REG_4"]):
        rules.append((gname, 1, "s2_valid_q_reg[%d]" % k))
    for k, gname in enumerate(["s2_valid_REG_1", "s2_valid_REG_3", "s2_valid_REG_5"]):
        for f, w in REDIRECT_FIELDS:
            gf = "valid" if f == "valid" else "bits_" + f
            rules.append(("%s_%s" % (gname, gf), w, "s2_redirect_q_reg[%d]\\[%s]" % (k, f)))
    for f, w in bf["lqu_raw_t"]:
        rules.append(("io_mmioRawData_2_r_%s" % f, w, "mmio_raw_q_reg\\[%s]" % f))
    for k in range(LD_W):
        rules.append(("io_rob_loadMmio_%d_REG" % k, 1, "rob_load_mmio_q_reg[%d]" % k))
        rules.append(("io_rob_loadMmioUop_%d_r_robIdx_value" % k, 8, "rob_load_mmio_rob_q_reg[%d]" % k))
    for gpre, ipre in (("lastCycleRedirect", "last_redirect_q_reg"),
                       ("lastLastCycleRedirect", "last2_redirect_q_reg")):
        for f, w in REDIRECT_FIELDS:
            gf = "valid_REG" if f == "valid" else "bits_r_" + f
            rules.append(("%s_%s" % (gpre, gf), w, "%s\\[%s]" % (ipre, f)))
    rules.append(("io_rollback_valid_last_REG", 1, "rollback_valid_q_reg"))
    for f, w in bf["lqu_rollback_t"]:
        rules.append(("io_rollback_bits_r_%s" % f, w, "rollback_q_reg\\[%s]" % f))
    greg = dict(golden_regs(TOP))
    if len(greg) != len(golden_regs(TOP)):
        die("golden 顶层寄存器名有重复")
    rmap = {}
    for g, w, i in rules:
        if g not in greg:
            die("钉点规则指向不存在的 golden 寄存器 %s" % g)
        if greg[g] != w:
            die("golden 寄存器 %s 宽 %d，规则写 %d" % (g, greg[g], w))
        if g in rmap:
            die("golden 寄存器 %s 被两条规则命中" % g)
        rmap[g] = (w, i)
    missing = sorted(set(greg) - set(rmap))
    if missing:
        die("golden 顶层寄存器没有钉点规则: %s" % missing[:10])
    imps = [i for _, i in rmap.values()]
    if len(set(imps)) != len(imps):
        die("钉点映射不是单射")
    return [(g, rmap[g][0], rmap[g][1]) for g, _ in golden_regs(TOP)]


def pipe_layout(module):
    f = fields(module, "io_in_bits_")
    total = sum(w for _, w in f)
    out, hi = [], total
    for n, w in f:
        hi -= w
        out.append((n, hi, w))
    return total, out


def gen_pins(bf):
    top_map = top_reg_map(bf)
    n_top = sum(w for _, w, _ in top_map)
    n_pipe = 0
    for mod, _, _, _, _ in PIPES:
        total, _ = pipe_layout(mod)
        if sum(w for _, w in golden_regs(mod)) != total + 1:
            die("%s 寄存器位数 != payload + valid" % mod)
        n_pipe += total + 1
    expect = n_top + n_pipe
    o = []
    o.append("# LoadQueueUncache FM「匹配前」钉点 —— 自动生成：scripts/gen_lquncache.py（勿手改）")
    o.append("#")
    o.append("# 只消名差，不修错配：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、")
    o.append("# 不加黑盒、不 dont_verify。两类名差：")
    o.append("#   (a) golden 顶层寄存器是按字段展平的 s2_req_<k>_<字段> 等（%d 个寄存器 / %d 位），"
             % (len(top_map), n_top))
    o.append("#       重写核是结构体数组 u_core/s2_req_q_reg[k]\\[字段][b] 等（形状取自 LoadQueueReplay /")
    o.append("#       InstrUncache 的 matched.rpt 实测：字段名下标带一个反斜杠，数字下标不带）；")
    o.append("#   (b) 5 个 PipelineRegModule 实例的 payload：golden io_out_bits_r_<字段>_reg[b]，")
    o.append("#       重写件是一根向量 u_core/<实例>/u_core/bits_q_reg[偏移+b]（%d 位，含 5 个 valid）。" % n_pipe)
    o.append("# 条目 / FreeList / 仲裁器内部不钉（名字只差一层 u_core，交给 FM 自动配对）。")
    o.append("# fail-closed：set_user_match 从不抛异常（没配上返回 0），逐条数返回值；")
    o.append("# 拒一条、或成功数不等于字面整数 %d，就 error（safe interp 里 exit 被隐藏）。" % expect)
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::LQU_PIN_EXPECT %d" % expect)
    o.append("set ::LQU_PIN_OK 0")
    o.append("set ::LQU_PIN_BAD 0")
    o.append("proc lqu_pin1 {r i} {")
    o.append("  if {[set_user_match $r $i]} { incr ::LQU_PIN_OK } else {")
    o.append("    incr ::LQU_PIN_BAD")
    o.append("    if {$::LQU_PIN_BAD <= 10} { puts \"LQU_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("# 寄存器 g（宽 w）<-> 核内 i：w==1 时两侧都不带位下标")
    o.append("proc lqu_pin {g i w} {")
    o.append("  set r \"r:/WORK/LoadQueueUncache/${g}_reg\"")
    o.append("  set m \"i:/WORK/LoadQueueUncache/u_core/$i\"")
    o.append("  if {$w == 1} { lqu_pin1 $r $m } else {")
    o.append("    for {set b 0} {$b < $w} {incr b} { lqu_pin1 \"$r\\[$b\\]\" \"$m\\[$b\\]\" }")
    o.append("  }")
    o.append("}")
    o.append("# 流水寄存器实例 p 的字段 f（宽 w，向量偏移 lsb）")
    o.append("proc lqu_pipe {p f w lsb} {")
    o.append("  set r \"r:/WORK/LoadQueueUncache/$p/io_out_bits_r_${f}_reg\"")
    o.append("  set m \"i:/WORK/LoadQueueUncache/u_core/$p/u_core/bits_q_reg\"")
    o.append("  if {$w == 1} { lqu_pin1 $r \"$m\\[$lsb\\]\" } else {")
    o.append("    for {set b 0} {$b < $w} {incr b} { lqu_pin1 \"$r\\[$b\\]\" \"$m\\[[expr {$lsb + $b}]\\]\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"LQU_PIN_BEGIN LoadQueueUncache expect=$::LQU_PIN_EXPECT\"")
    for g, w, i in top_map:
        o.append("lqu_pin %s {%s} %d" % (g, i, w))
    for mod, name, _, _, _ in PIPES:
        _, lay = pipe_layout(mod)
        o.append("lqu_pin1 r:/WORK/LoadQueueUncache/%s/pipeline_reg_valid_reg "
                 "i:/WORK/LoadQueueUncache/u_core/%s/u_core/valid_q_reg" % (name, name))
        for f, lsb, w in lay:
            o.append("lqu_pipe %s %s %d %d" % (name, f, w, lsb))
    o.append("puts \"LQU_PIN_END LoadQueueUncache ok=$::LQU_PIN_OK bad=$::LQU_PIN_BAD\"")
    o.append("if {$::LQU_PIN_BAD != 0} { error \"LQU_PIN_MISS=$::LQU_PIN_BAD\" }")
    o.append("if {$::LQU_PIN_OK != %d} { error \"LQU_PIN_COUNT=$::LQU_PIN_OK expect=%d\" }" % (expect, expect))
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
#  UT tb
# ---------------------------------------------------------------------------
def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s)\n" % tag
    e = "// END GENERATED\n"
    i = text.index(b) + len(b)
    j = text.index(e, i)
    return text[:i] + body + text[j:]


TB_READY = True

# tb 里的输入驱动名（golden 输入端口 -> tb 表达式）；未列出的输入用同名 tb 信号
TB_IN_RULES = [
    (r"clock", "clk"),
    (r"reset", "rst"),
    (r"io_req_(\d)_valid", r"req_valid[\1]"),
    (r"io_req_(\d)_bits_(\w+)", r"req_bits[\1].\2"),
    (r"io_ncOut_(\d)_ready", r"nc_ready[\1]"),
    (r"io_mmioOut_2_ready", "mmio_ready"),
    (r"io_uncache_req_ready", "ureq_ready"),
]

# 输出分组：依赖不复位寄存器的输出，只在"该寄存器已被写过"之后才比（见 tb 文件头）
TB_OUT_GROUPS = [
    ("nc0", r"io_ncOut_0_bits_\w+"),
    ("nc1", r"io_ncOut_1_bits_\w+"),
    ("nc2", r"io_ncOut_2_bits_\w+"),
    ("mmio", r"io_mmioOut_2_bits_\w+|io_mmioRawData_2_\w+"),
    ("ureq", r"io_uncache_req_bits_\w+"),
    ("rb", r"io_rollback_bits_\w+"),
    ("exc", r"io_exception_bits_\w+"),
    ("uop0", r"io_rob_loadMmioUop_0_\w+"),
    ("uop1", r"io_rob_loadMmioUop_1_\w+"),
    ("uop2", r"io_rob_loadMmioUop_2_\w+"),
]

TB_HEAD = r"""// ===========================================================================
// LoadQueueUncache UT：golden LoadQueueUncache 对重写 LoadQueueUncache_xs（整棵子树：
// 16 个 UncacheEntry、FreeList_6、RRArbiterInit_11、5 个 PipelineRegModule 两侧各用
// 自己的件），同一套激励，逐拍比对全部 791 个输出端口（打包成 NOW 位向量）。
//
// ★激励★
//   · 三条 load 请求：每 lane 30%（慢相 20%）有效；payload 全随机，但控制字段有偏：robIdx
//     按程序序唯一递增（RobSize=160 绕圈、flag 翻转），同拍三条的先后随机分给三个 lane
//     （考 s1 排序），偶尔让 NC load 同龄（考相等分支）；
//     mmio/nc 约 20%/50%/30%(都不置)——★两者互斥★：mmio 与 nc 同置的条目
//     走 MMIO 路由却不等 ROB 头，多条会同时进 S_REQ，同上死锁（实测第二版激励），LduCfg 的 6 个异常位各 2%、
//     rep_info 11 个重放原因各 1%。
//   · redirect ~2%，指向最近 24 条以内的某条 load。ROB 的 pendingMMIOld ~60%，pendingPtr
//     = golden 在册 MMIO 条目里最老的那条的 robIdx（ROB 头语义，见 drive() 里的注释）。
//     ★robIdx 必须唯一★：两条 MMIO 同龄会同时"成为 ROB 头"，两个条目都进 S_REQ、都看到
//     mmioReq.ready 而进 S_RESP，只有一条请求真的发出去，另一条永远等不到 resp（golden
//     本身如此；真实硬件里 robIdx 唯一，不会发生）。第一版激励用 16 值小池子，实测死锁。
//   · Uncache 总线是一个行为模型：看到 golden 的 io_uncache_req 成交就记下 id，之后
//     随机拍发 idResp{mid=id, sid=新号}，再随机拍发 resp{id=sid, data, denied 4%,
//     corrupt 4%}；另有 2% 的杂讯 idResp / resp（随便的 mid / id）。
//   · 快/慢两相交替（每 4000 拍切换）：慢相里各 ready 与总线响应都很稀，条目积压到
//     16 个满，触发"满了就回滚"。
//   · 每 25000 拍一次 3 拍的整体复位（期间输入安静），行为模型清空。
// ★不复位寄存器的比较口径★
//   golden 与重写的不复位寄存器（s2_req、各流水寄存器 payload、条目 payload、
//   rawData、rollback bits、loadMmioUop）在 +vcs+initreg+random / +<seed>017 档两侧
//   初值不同。依赖它们的输出分组，只在该组寄存器已被写过之后才比：
//     ncOut_k/mmioOut/uncache_req/rollback 的 bits —— 该口 valid 第一次为 1 起；
//     loadMmioUop_k —— s1 第 k 槽第一次有效之后；
//     exception bits —— 被选中的条目（编号最小的有效者，全无效取 15）写过请求之后。
//   ncOut(0) 从不被写，它的 bits 在随机档里永远不比 —— 由 FM 覆盖（两侧同为一组
//   从不写入的寄存器）。+vcs+initreg+0 / +1 这两个常量档从第一拍起全比。
// ★覆盖★ tb 统计若干有判别力的事件（COVERAGE 行），任何一项为 0 本轮判红。
// 自动生成：scripts/gen_lquncache.py —— 勿手改
// ===========================================================================
`timescale 1ns/1ps

module tb;
  import loadqueueuncache_pkg::*;

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int      errors = 0;
  longint  checks = 0;
  bit      cmp_all = 0;        // 常量 initreg 档：全部输出从第一拍起比
  always #5 clk = ~clk;

  // ---- 输入 ----
  logic            io_redirect_valid;
  logic            io_redirect_bits_robIdx_flag;
  logic [7:0]      io_redirect_bits_robIdx_value;
  logic            io_redirect_bits_level;
  logic            io_rob_pendingMMIOld;
  logic            io_rob_pendingPtr_flag;
  logic [7:0]      io_rob_pendingPtr_value;
  logic [2:0]      req_valid;
  lqu_req_t        req_bits [3];
  logic            mmio_ready;
  logic [2:0]      nc_ready;
  logic            ureq_ready;
  logic            io_uncache_idResp_valid;
  logic [6:0]      io_uncache_idResp_bits_mid;
  logic [3:0]      io_uncache_idResp_bits_sid;
  logic            io_uncache_resp_valid;
  logic [63:0]     io_uncache_resp_bits_data;
  logic [3:0]      io_uncache_resp_bits_id;
  logic            io_uncache_resp_bits_denied;
  logic            io_uncache_resp_bits_corrupt;
"""

TB_TAIL = r"""
  // ---- golden 内部观测（只读：条目写入 / 异常有效 / 当前 robIdx）----
  wire [15:0] g_ent_req_valid = {@ENT_REQ_VALID@};
  wire [15:0] g_ent_exc_valid = {@ENT_EXC_VALID@};
  wire [15:0] g_ent_flush     = {@ENT_FLUSH@};
  wire [8:0]  g_ent_rob [16];
@ENT_ROB@
  bit  [15:0] ent_written = '0;
  wire [15:0] g_ent_live_mmio = {@ENT_LIVE_MMIO@};
  int g_oldest_mmio;       // 在册 MMIO 条目里 robIdx 最老的那个（没有则 -1）
  always_comb begin
    g_oldest_mmio = -1;
    for (int i = 0; i < 16; i++)
      if (g_ent_live_mmio[i] && (g_oldest_mmio < 0 ||
          (g_ent_rob[i][8] ^ g_ent_rob[g_oldest_mmio][8] ^ (g_ent_rob[i][7:0] < g_ent_rob[g_oldest_mmio][7:0]))))
        g_oldest_mmio = i;
  end

  // ---- 比较口径 ----
  bit wr_nc0 = 0, wr_nc1 = 0, wr_nc2 = 0, wr_mmio = 0, wr_ureq = 0, wr_rb = 0;
  bit [2:0] wr_uop = '0;
  bit [NOW-1:0] cmp_mask;

  task automatic compare(int cyc);
    int sel;
    if (g_io_ncOut_1_valid) wr_nc1 = 1;
    if (g_io_ncOut_2_valid) wr_nc2 = 1;
    if (g_io_mmioOut_2_valid) wr_mmio = 1;
    if (g_io_uncache_req_valid) wr_ureq = 1;
    if (g_io_rollback_valid) wr_rb = 1;
    sel = 15;
    for (int i = 15; i >= 0; i--) if (g_ent_exc_valid[i]) sel = i;
    cmp_mask = M_CTRL;
    if (cmp_all | wr_nc0) cmp_mask |= M_NC0;
    if (cmp_all | wr_nc1) cmp_mask |= M_NC1;
    if (cmp_all | wr_nc2) cmp_mask |= M_NC2;
    if (cmp_all | wr_mmio) cmp_mask |= M_MMIO;
    if (cmp_all | wr_ureq) cmp_mask |= M_UREQ;
    if (cmp_all | wr_rb) cmp_mask |= M_RB;
    if (cmp_all | ent_written[sel]) cmp_mask |= M_EXC;
    if (cmp_all | wr_uop[0]) cmp_mask |= M_UOP0;
    if (cmp_all | wr_uop[1]) cmp_mask |= M_UOP1;
    if (cmp_all | wr_uop[2]) cmp_mask |= M_UOP2;
    checks++;
    if ((g_out & cmp_mask) !== (x_out & cmp_mask)) begin
      errors++;
      if (errors <= 10)
        for (int p = 0; p < NPORT; p++) begin
          bit [NOW-1:0] pm;
          pm = ({NOW{1'b1}} >> (NOW - PW[p])) << POFF[p];
          if ((g_out & pm & cmp_mask) !== (x_out & pm & cmp_mask))
            $display("[%0d] MISMATCH %s g=%h x=%h", cyc, PNAME[p],
                     (g_out & pm) >> POFF[p], (x_out & pm) >> POFF[p]);
        end
    end
  endtask

  // ---- Uncache 总线行为模型 ----
  typedef struct { bit [6:0] id; bit [3:0] sid; int st; } txn_t;   // st: 1=等 idResp 2=等 resp
  txn_t txq [$];
  bit [3:0] sid_ctr = 0;
  bit slow = 0;

  // ---- 覆盖 ----
  longint cov_enq = 0, cov_multi_enq = 0, cov_mmio_req = 0, cov_nc_req = 0, cov_mmio_wb = 0;
  longint cov_nc1_wb = 0, cov_nc2_wb = 0, cov_rollback = 0, cov_exception = 0, cov_flush = 0;
  longint cov_denied = 0, cov_idresp = 0, cov_resp = 0, cov_reset = 0;

  task automatic sample();   // 在时钟沿之前调用：输入与输出都是即将被这个沿采下的值
    int n;
    n = $countones(g_ent_req_valid);
    cov_enq += n;
    if (n >= 2) cov_multi_enq++;
    for (int i = 0; i < 16; i++) if (g_ent_req_valid[i]) ent_written[i] = 1;
    for (int k = 0; k < 3; k++) if ($countones(req_valid) > k) wr_uop[k] = 1;
    if (g_io_uncache_req_valid & ureq_ready) begin
      txn_t t;
      if (g_io_uncache_req_bits_nc) cov_nc_req++; else cov_mmio_req++;
      t.id = g_io_uncache_req_bits_id; t.sid = 0; t.st = 1;
      txq.push_back(t);
    end
    if (g_io_mmioOut_2_valid & mmio_ready) cov_mmio_wb++;
    if (g_io_ncOut_1_valid & nc_ready[1]) cov_nc1_wb++;
    if (g_io_ncOut_2_valid & nc_ready[2]) cov_nc2_wb++;
    if (g_io_rollback_valid) cov_rollback++;
    if (g_io_exception_valid) cov_exception++;
    if (g_io_exception_valid & g_io_exception_bits_uop_exceptionVec_5) cov_denied++;
    if (|g_ent_flush) cov_flush++;
    if (io_uncache_idResp_valid) cov_idresp++;
    if (io_uncache_resp_valid) cov_resp++;
  endtask

  // RobPtr（RobSize = 160：value 0..159，绕一圈 flag 翻转）
  logic [8:0] rob_next = '0;     // 下一条新 load 的 robIdx（程序序单调前进）
  function automatic logic [8:0] rob_add(logic [8:0] p, int n);   // n 可为负
    int v;
    logic f;
    f = p[8];
    v = int'(p[7:0]) + n;
    while (v >= 160) begin v -= 160; f = ~f; end
    while (v < 0) begin v += 160; f = ~f; end
    return {f, 8'(v)};
  endfunction

  task automatic quiet();
    io_redirect_valid = 0; io_redirect_bits_robIdx_flag = 0; io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0; io_rob_pendingMMIOld = 0; io_rob_pendingPtr_flag = 0;
    io_rob_pendingPtr_value = 0; req_valid = 0;
    for (int k = 0; k < 3; k++) req_bits[k] = '0;
    mmio_ready = 0; nc_ready = 0; ureq_ready = 0;
    io_uncache_idResp_valid = 0; io_uncache_idResp_bits_mid = 0; io_uncache_idResp_bits_sid = 0;
    io_uncache_resp_valid = 0; io_uncache_resp_bits_data = 0; io_uncache_resp_bits_id = 0;
    io_uncache_resp_bits_denied = 0; io_uncache_resp_bits_corrupt = 0;
  endtask

  task automatic drive();
    logic [$bits(lqu_req_t)+31:0] rnd;
    int r;
    int perm [3];
    // redirect：指向最近发出的某条 load（冲掉比它年轻的）
    io_redirect_valid = ($urandom_range(0, 99) < 2);
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value} = rob_add(rob_next, -$urandom_range(1, 24));
    io_redirect_bits_level = $urandom_range(0, 1);
    // ROB：一半时间把 pendingPtr 对准某个条目当前的 robIdx（否则 MMIO 很难等到成为 ROB 头）
    // ROB 头 = 最老的在册 MMIO load；没有在册 MMIO 时指向一个已经过去的号（谁也不匹配）。
    // ★不能随便指★：ROB 头在 MMIO 完成前不会移走；若 pendingPtr 先指 A 再指 B，A、B 会
    // 先后进 S_REQ 同时等 mmioReq.ready，一起进 S_RESP 而只有一条请求真的发出（实测死锁）。
    io_rob_pendingMMIOld = ($urandom_range(0, 99) < 60);
    if (g_oldest_mmio >= 0)
      {io_rob_pendingPtr_flag, io_rob_pendingPtr_value} = g_ent_rob[g_oldest_mmio];
    else
      {io_rob_pendingPtr_flag, io_rob_pendingPtr_value} = rob_add(rob_next, -$urandom_range(1, 30));
    // 三条请求：robIdx 在程序序上唯一递增，但分给三个 lane 的次序随机打乱（考 s1 排序）
    perm[0] = 0; perm[1] = 1; perm[2] = 2;
    for (int k = 2; k > 0; k--) begin
      int t, j;
      j = $urandom_range(0, k);
      t = perm[k]; perm[k] = perm[j]; perm[j] = t;
    end
    for (int k = 0; k < 3; k++)
      req_valid[k] = ($urandom_range(0, 99) < (slow ? 20 : 30));
    for (int k = 0; k < 3; k++) begin
      int nth;
      for (int b = 0; b < $bits(lqu_req_t); b += 32) rnd[b +: 32] = $urandom();
      req_bits[k] = rnd[$bits(lqu_req_t)-1:0];
      // 有效 lane 按 perm 次序领连续的号（无效 lane 的号码不占程序序，随便给一个旧号）
      nth = 0;
      for (int j = 0; j < 3; j++) if (req_valid[j] && perm[j] < perm[k]) nth++;
      {req_bits[k].uop_robIdx_flag, req_bits[k].uop_robIdx_value} =
        req_valid[k] ? rob_add(rob_next, nth) : rob_add(rob_next, -$urandom_range(1, 40));
      r = $urandom_range(0, 9);
      req_bits[k].mmio = (r <= 1);
      req_bits[k].nc   = (r >= 2 && r <= 6);
      // 偶尔（3%）让 NC load 与 0 号 lane 同龄：考排序的相等分支（MMIO 同龄会让两条同时
      // 成为"ROB 头"，真实硬件里不会发生，这里不造）
      if (k > 0 && !req_bits[k].mmio && !req_bits[0].mmio && $urandom_range(0, 99) < 3)
        {req_bits[k].uop_robIdx_flag, req_bits[k].uop_robIdx_value} =
          {req_bits[0].uop_robIdx_flag, req_bits[0].uop_robIdx_value};
      req_bits[k].uop_exceptionVec_3  = ($urandom_range(0, 99) < 2);
      req_bits[k].uop_exceptionVec_4  = ($urandom_range(0, 99) < 2);
      req_bits[k].uop_exceptionVec_5  = ($urandom_range(0, 99) < 2);
      req_bits[k].uop_exceptionVec_13 = ($urandom_range(0, 99) < 2);
      req_bits[k].uop_exceptionVec_19 = ($urandom_range(0, 99) < 2);
      req_bits[k].uop_exceptionVec_21 = ($urandom_range(0, 99) < 2);
@REP_BIAS@
    end
    rob_next = rob_add(rob_next, $countones(req_valid));
    // 写回与请求的 ready
    mmio_ready = ($urandom_range(0, 99) < (slow ? 20 : 75));
    for (int k = 0; k < 3; k++) nc_ready[k] = ($urandom_range(0, 99) < (slow ? 20 : 75));
    ureq_ready = ($urandom_range(0, 99) < (slow ? 15 : 70));
    // Uncache 总线模型
    io_uncache_idResp_valid = 0;
    io_uncache_resp_valid = 0;
    io_uncache_idResp_bits_mid = 7'($urandom_range(0, 17));
    io_uncache_idResp_bits_sid = 4'($urandom());
    io_uncache_resp_bits_id = 4'($urandom());
    io_uncache_resp_bits_data = {$urandom(), $urandom()};
    io_uncache_resp_bits_denied = ($urandom_range(0, 99) < 4);
    io_uncache_resp_bits_corrupt = ($urandom_range(0, 99) < 4);
    if ($urandom_range(0, 99) < (slow ? 10 : 50)) begin
      foreach (txq[q]) if (txq[q].st == 1) begin
        io_uncache_idResp_valid = 1;
        io_uncache_idResp_bits_mid = txq[q].id;
        io_uncache_idResp_bits_sid = sid_ctr;
        txq[q].sid = sid_ctr; txq[q].st = 3;   // 3 = 本拍刚发 idResp，下一拍起才能收 resp
        sid_ctr++;
        break;
      end
    end else if ($urandom_range(0, 99) < 2) io_uncache_idResp_valid = 1;   // 杂讯
    if ($urandom_range(0, 99) < (slow ? 8 : 40)) begin
      foreach (txq[q]) if (txq[q].st == 2) begin
        io_uncache_resp_valid = 1;
        io_uncache_resp_bits_id = txq[q].sid;
        txq.delete(q);
        break;
      end
    end else if ($urandom_range(0, 99) < 2) io_uncache_resp_valid = 1;     // 杂讯
    foreach (txq[q]) if (txq[q].st == 3 && !(io_uncache_idResp_valid && io_uncache_idResp_bits_sid == txq[q].sid && io_uncache_idResp_bits_mid == txq[q].id)) txq[q].st = 2;
  endtask

  initial begin
    string ir;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    if ($value$plusargs("vcs+initreg+%s", ir) && (ir == "0" || ir == "1")) cmp_all = 1;
    rst = 1'b1;
    quiet();
    repeat (6) @(posedge clk);
    #1 rst = 1'b0;
    for (int cyc = 0; cyc < NCYCLES; cyc++) begin
      if (cyc % 4000 == 0) slow = ($urandom_range(0, 99) < 40);
      if (cyc % 25000 == 12500) begin
        rst = 1'b1; quiet(); txq.delete(); cov_reset++;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
      end
      drive();
      #1 compare(cyc);
      sample();
      @(posedge clk);
      #1;
    end
    $display("COVERAGE enq=%0d multi_enq=%0d mmio_req=%0d nc_req=%0d mmio_wb=%0d nc1_wb=%0d nc2_wb=%0d",
             cov_enq, cov_multi_enq, cov_mmio_req, cov_nc_req, cov_mmio_wb, cov_nc1_wb, cov_nc2_wb);
    $display("COVERAGE rollback=%0d exception=%0d denied=%0d flush=%0d idresp=%0d resp=%0d reset=%0d",
             cov_rollback, cov_exception, cov_denied, cov_flush, cov_idresp, cov_resp, cov_reset);
    if (cov_enq == 0 || cov_multi_enq == 0 || cov_mmio_req == 0 || cov_nc_req == 0 || cov_mmio_wb == 0
        || cov_nc1_wb == 0 || cov_nc2_wb == 0 || cov_rollback == 0 || cov_exception == 0
        || cov_denied == 0 || cov_flush == 0 || cov_idresp == 0 || cov_resp == 0 || cov_reset == 0) begin
      $display("COVERAGE HOLE -> run does not count");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
"""


def gen_tb(bf):
    ports = port_table(TOP)
    outs = [(n, w) for d, w, n, _ in ports if d == "output"]
    total = sum(w for _, w in outs)
    lay, off = [], 0
    for n, w in outs:
        lay.append((n, off, w))
        off += w
    o = [TB_HEAD]
    o.append("  // ---- 输出：每个实例打包成一根 NOW 位向量（端口顺序同 golden，偏移见 POFF）----")
    o.append("  localparam int NOW = %d;" % total)
    o.append("  localparam int NPORT = %d;" % len(outs))
    o.append("  wire [NOW-1:0] g_out, x_out;")
    o.append("  string PNAME [NPORT];")
    o.append("  int    POFF  [NPORT];")
    o.append("  int    PW    [NPORT];")
    o.append("  initial begin")
    for k, (n, of, w) in enumerate(lay):
        o.append("    PNAME[%d] = \"%s\"; POFF[%d] = %d; PW[%d] = %d;" % (k, n, k, of, k, w))
    o.append("  end")
    # 分组掩码
    groups = {g: [] for g, _ in TB_OUT_GROUPS}
    ctrl = []
    for n, of, w in lay:
        hit = [g for g, pat in TB_OUT_GROUPS if re.fullmatch(pat, n)]
        if len(hit) > 1:
            die("tb 输出 %s 命中多个分组" % n)
        (groups[hit[0]] if hit else ctrl).append((of, w))
    def mask(name, segs):
        o.append("  bit [NOW-1:0] %s;" % name)
        o.append("  initial begin")
        o.append("    %s = '0;" % name)
        for of, w in segs:
            o.append("    %s[%d +: %d] = '1;" % (name, of, w))
        o.append("  end")
    mask("M_CTRL", ctrl)
    for g, _ in TB_OUT_GROUPS:
        if not groups[g]:
            die("tb 输出分组 %s 是空的" % g)
        mask("M_" + g.upper(), groups[g])
    # 若干 golden 输出的具名别名（tb 逻辑要看）
    for n in ["io_ncOut_1_valid", "io_ncOut_2_valid", "io_mmioOut_2_valid", "io_uncache_req_valid",
              "io_rollback_valid", "io_exception_valid", "io_uncache_req_bits_nc", "io_uncache_req_bits_id",
              "io_exception_bits_uop_exceptionVec_5"]:
        _, of, w = next(x for x in lay if x[0] == n)
        o.append("  wire %sg_%s = g_out[%d +: %d];" % ("" if w == 1 else "[%d:0] " % (w - 1), n, of, w))
    # 两个实例
    for side, mod in (("g", TOP), ("x", TOP + "_xs")):
        o.append("  %s u_%s (" % (mod, side))
        conns = []
        for d, w, n, _ in ports:
            if d == "input":
                hits = [(p, t) for p, t in TB_IN_RULES if re.fullmatch(p, n)]
                e = re.sub(hits[0][0], hits[0][1], n) if hits else n
            else:
                _, of, _ = next(x for x in lay if x[0] == n)
                e = "%s_out[%d +: %d]" % (side, of, w)
            conns.append((n, e))
        wd = max(len(n) for n, _ in conns)
        for k, (n, e) in enumerate(conns):
            o.append("    .%-*s (%s)%s" % (wd, n, e, "," if k + 1 < len(conns) else ""))
        o.append("  );")
    tail = TB_TAIL
    ents = ["u_g.entries_%d" % i for i in reversed(range(NUM_ENTRIES))]
    tail = tail.replace("@ENT_REQ_VALID@", ", ".join(e + ".io_req_valid" for e in ents))
    tail = tail.replace("@ENT_EXC_VALID@", ", ".join(e + ".io_exception_valid" for e in ents))
    tail = tail.replace("@ENT_FLUSH@", ", ".join(e + ".io_flush" for e in ents))
    tail = tail.replace("@ENT_LIVE_MMIO@", ", ".join("%s.req_valid & %s.req_mmio" % (e, e) for e in ents))
    tail = tail.replace("@ENT_ROB@", "\n".join(
        "  assign g_ent_rob[%d] = {u_g.entries_%d.io_exception_bits_uop_robIdx_flag, "
        "u_g.entries_%d.io_exception_bits_uop_robIdx_value};" % (i, i, i) for i in range(NUM_ENTRIES)))
    reps = [n for n, _ in bf["lqu_req_t"] if n.startswith("rep_info_cause_")]
    tail = tail.replace("@REP_BIAS@", "\n".join(
        "      req_bits[k].%s = ($urandom_range(0, 99) < 1);" % n for n in reps))
    o.append(tail)
    return "\n".join(o)


def targets():
    bf = bundle_fields()
    cur = open(LQU).read()
    txt = replace_region(cur, "lqu-types", gen_types(bf))
    txt = replace_region(txt, "lqu-entries", gen_entries() + "\n")
    txt = replace_region(txt, "lqu-pipes", gen_pipes() + "\n")
    txt = replace_region(txt, "lqu-wrapper", gen_wrapper())
    out = {LQU: txt, os.path.join(UT, "fm_pins_pre.tcl"): gen_pins(bf)}
    if TB_READY:
        out[os.path.join(UT, "tb.sv")] = gen_tb(bf)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_lquncache: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_lquncache: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)
            print("gen_lquncache: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
