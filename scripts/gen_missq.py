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


GENERATORS = [gen_arb16_file]


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
