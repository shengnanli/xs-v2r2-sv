#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_srt_divblocks.py —— SRT radix-16 整数除法迭代块的机械派生区生成器。

生成什么（核一律手写，本脚本只碰 GENERATED 区与薄变体文件）：
  rtl/backend/SelBlock_v4.sv    GENERATED(selblock-wrapper)   golden 同名 wrapper
  rtl/backend/SpecBlock_v4.sv   GENERATED(specblock-wrapper)  golden 同名 wrapper
  rtl/backend/IterBlock_v4.sv   GENERATED(iterblock-selB)     核内 SelBlock_v4 例化连线
                                GENERATED(iterblock-specB)    核内 SpecBlock_v4 例化连线
                                GENERATED(iterblock-wrapper)  IterBlock_v4 wrapper
  rtl/backend/IterBlock_v4_4.sv 整个文件（薄 wrapper，BIT_WIDTH=32）
  rtl/backend/IterBlock_v4_6.sv 整个文件（薄 wrapper，BIT_WIDTH=64）

映射规则（fail-closed）：golden 端口 io_<base>(_<i>)* ↔ 核数组 <base>[i]...，
  每个模块给出 base → 维度 的形状表。生成时机械核对：
  (1) 每个 golden 端口恰好命中形状表里一个 base，下标个数 = 维数且不越界；
  (2) 核数组的每个元素恰好被一个 golden 端口覆盖，或列在 TIE0（只许输入）；
  (3) 同一 base 的所有端口位宽一致、方向一致。
  任何一条不满足即报错退出，不产出半成品。

用法:
  python3 scripts/gen_srt_divblocks.py           # 生成/刷新
  python3 scripts/gen_srt_divblocks.py --check   # 只比对不写；有漂移 rc=1（闸用）
"""
import argparse
import itertools
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RTL = os.path.join(REPO, "rtl", "backend")
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+)\s*,?\s*$")

# 形状表：base -> 维度列表（[] = 标量）。顺序即核端口顺序。
SEL_SHAPE = [("q_j", []), ("q_j_1", []), ("cons", [5, 4]), ("rem_3_5", [2]),
             ("pre_sel", [4, 2]), ("nxt_sel", [4, 2])]
SPEC_SHAPE = [("q_j", []), ("cons", [5, 4]), ("d_trunc", [4]), ("q_j_1", []),
              ("rem_3_5", [2]), ("q_j_2", []), ("pre_spec", [5, 4, 2]),
              ("nxt_spec", [5, 4, 2])]
ITER_SHAPE = [("Sel_cons", [5, 4]), ("Spec_cons", [5, 4]), ("iter_cons", [5]),
              ("d_trunc", [4]), ("spec_r2ud", [5]), ("pre_q_A", []), ("pre_q_B", []),
              ("nxt_q_A", []), ("nxt_q_B", []), ("pre_sel", [4, 2]), ("nxt_sel", [4, 2]),
              ("pre_spec", [5, 4, 2]), ("nxt_spec", [5, 4, 2]), ("pre_iterB", [2]),
              ("nxt_iterB", [2])]
# golden 优化掉的端口（父级恒连 0：商位 q=0 对应的 −0·d）
ITER_TIE0 = {("iter_cons", (2,)), ("spec_r2ud", (2,))}

# IterBlock 核里 selB/specB 的端口 base -> 核内信号名
SEL_IN_ITER = {"q_j": "q2_oh", "q_j_1": "q1_oh", "cons": "Sel_cons", "rem_3_5": "sel_rem",
               "pre_sel": "pre_sel", "nxt_sel": "nxt_sel"}
SPEC_IN_ITER = {"q_j": "q2_oh", "cons": "Spec_cons", "d_trunc": "d_trunc", "q_j_1": "q1_oh",
                "rem_3_5": "spec_rem", "q_j_2": "q2_oh", "pre_spec": "pre_spec",
                "nxt_spec": "nxt_spec"}

ITER_VARIANTS = [  # (模块, BIT_WIDTH, 整宽 CSA, Conversion)
    ("IterBlock_v4", 16, "CSA3_2_3987", "Conversion"),
    ("IterBlock_v4_4", 32, "CSA3_2_4111", "Conversion_8"),
    ("IterBlock_v4_6", 64, "CSA3_2_4173", "Conversion_12"),
]


def die(msg):
    sys.stderr.write("gen_srt_divblocks: ERROR: %s\n" % msg)
    sys.exit(2)


def golden_ports(module):
    """[(dir, width, name)]，顺序即 golden 顺序；width 为 None 表示 1 位。"""
    path = os.path.join(GOLDEN_DIR, module + ".sv")
    text = open(path).read()
    m = re.search(r"^module %s\((.*?)^\);" % re.escape(module), text, re.S | re.M)
    if not m:
        die("golden %s 找不到模块头" % module)
    ports = []
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        pm = PORT_RE.match(line)
        if not pm:
            die("golden %s 端口行无法解析: %r" % (module, line))
        ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else None, pm.group(3)))
    return ports


def map_ports(module, ports, shape, tie0=frozenset()):
    """返回 (逐端口映射 [(port, base, idx)], base 信息 {base: (dir, width)})；fail-closed。"""
    dims = dict(shape)
    mapping, info, covered = [], {}, {}
    for d, w, name in ports:
        if not name.startswith("io_"):
            die("%s: 端口 %s 不以 io_ 开头" % (module, name))
        n = name[3:]
        hits = []
        for base, dd in shape:
            if n == base and not dd:
                hits.append((base, ()))
            elif n.startswith(base + "_") and dd:
                rest = n[len(base):]
                im = re.fullmatch(r"(?:_(\d+))" * len(dd), rest)
                if im:
                    idx = tuple(int(x) for x in im.groups())
                    if all(i < lim for i, lim in zip(idx, dd)):
                        hits.append((base, idx))
        if len(hits) != 1:
            die("%s: 端口 %s 命中 %d 条形状规则 %r（须恰好 1 条）" % (module, name, len(hits), hits))
        base, idx = hits[0]
        if base in info and info[base] != (d, w):
            die("%s: %s 的方向/位宽与同组不一致" % (module, name))
        info[base] = (d, w)
        if (base, idx) in covered:
            die("%s: %s%r 被两个端口覆盖" % (module, base, idx))
        covered[(base, idx)] = name
        mapping.append((name, base, idx))
    for base, dd in shape:
        if base not in info:
            die("%s: 形状表的 %s 在 golden 端口里一个都没有" % (module, base))
        for idx in itertools.product(*[range(x) for x in dd]):
            key = (base, tuple(idx))
            if key in covered:
                if key in tie0:
                    die("%s: %s%r 列在 TIE0 却有 golden 端口" % (module, base, idx))
            elif key in tie0:
                if info[base][0] != "input":
                    die("%s: TIE0 只许输入，%s 是输出" % (module, base))
            else:
                die("%s: 核数组元素 %s%r 没有 golden 端口覆盖" % (module, base, idx))
    return mapping, info


def width_decl(w):
    return "[%d:0] " % (w - 1) if w else ""


def idx_str(idx):
    return "".join("[%d]" % i for i in idx)


def dims_decl(dd):
    return "".join(" [0:%d]" % (x - 1) for x in dd)


def gen_wrapper(module, core, shape, params="", tie0=frozenset()):
    ports = golden_ports(module)
    mapping, info = map_ports(module, ports, shape, tie0)
    dims = dict(shape)
    wmax = max((w or 1) for _, w, _ in ports)
    wfield = len("[%d:0]" % (wmax - 1))
    out = []
    out.append("module %s(" % module)
    for k, (d, w, name) in enumerate(ports):
        wd = ("[%d:0]" % (w - 1)) if w else ""
        sep = "," if k + 1 < len(ports) else ""
        out.append("  %-6s %-*s %s%s" % (d, wfield, wd, name, sep))
    out.append(");")
    out.append("")
    out.append("  // 展平端口 <-> 核的数组（Scala Vec）")
    for base, dd in shape:
        if dd:
            out.append("  logic %s%s%s;" % (width_decl(info[base][1]), base, dims_decl(dd)))
    out.append("")
    for name, base, idx in mapping:
        if info[base][0] == "input" and dims[base]:
            out.append("  assign %s%s = %s;" % (base, idx_str(idx), name))
    for base, idx in sorted(tie0):
        out.append("  assign %s%s = '0;   // golden 无此端口：父级恒连 0（q=0 时 −0·d）"
                   % (base, idx_str(idx)))
    out.append("")
    out.append("  %s%s u_core (" % (core, params))
    conns = []
    for base, dd in shape:
        if dd:
            conns.append((base, base))
        else:
            conns.append((base, "io_" + base))
    bw = max(len(b) for b, _ in conns)
    for k, (b, e) in enumerate(conns):
        sep = "," if k + 1 < len(conns) else ""
        out.append("    .%-*s (%s)%s" % (bw, b, e, sep))
    out.append("  );")
    outs = [(name, base, idx) for name, base, idx in mapping
            if info[base][0] == "output" and dims[base]]
    if outs:
        out.append("")
        for name, base, idx in outs:
            out.append("  assign %s = %s%s;" % (name, base, idx_str(idx)))
    out.append("endmodule")
    return "\n".join(out) + "\n"


def gen_child_inst(child, inst, shape, sigmap, indent="  "):
    ports = golden_ports(child)
    mapping, _ = map_ports(child, ports, shape)
    pw = max(len(n) for n, _, _ in mapping)
    out = ["%s%s %s (" % (indent, child, inst)]
    for k, (name, base, idx) in enumerate(mapping):
        if base not in sigmap:
            die("%s 例化: base %s 没有核内信号映射" % (child, base))
        sep = "," if k + 1 < len(mapping) else ""
        out.append("%s  .%-*s (%s%s)%s" % (indent, pw, name, sigmap[base], idx_str(idx), sep))
    out.append("%s);" % indent)
    return "\n".join(out) + "\n"


def replace_region(text, tag, body, path):
    begin = "// BEGIN GENERATED(%s)\n" % tag
    pat = re.compile(r"([ \t]*)" + re.escape(begin) + r"(.*?)([ \t]*)// END GENERATED\n", re.S)
    hits = pat.findall(text)
    if len(hits) != 1:
        die("%s: GENERATED(%s) 区出现 %d 次（须恰好 1 次）" % (path, tag, len(hits)))
    return pat.sub(lambda m: m.group(1) + begin + body + m.group(3) + "// END GENERATED\n",
                   text, count=1)


WRAPPER_BANNER = """// -----------------------------------------------------------------------------
// {mod} —— golden 同名 wrapper：端口表逐字取 golden，展平端口 <-> 核数组（机械生成）
// -----------------------------------------------------------------------------
"""

VARIANT_HEADER = """// =============================================================================
// {mod}.sv —— SRT radix-16 整数除法的一拍迭代，**本变体 BIT_WIDTH={bw}**
//
// 在哪一层：VectorIdiv → {parent}（{bw} 位整数除法，sew 可取 00..{sewmax}）→ 本块。
// 本变体规模：余数 carry-save 向量宽 W={w}（= BIT_WIDTH + 6），商 A/B 各 {bw} 位；
//   子模块 {csa}（{w} 位 3:2 CSA）×2、CSA3_2_4017 ×1、{conv} ×2、
//   SelBlock_v4 ×1、SpecBlock_v4 ×1，全部为本仓已签核重写件。纯组合。
// 与 IterBlock_v4（16 位）只差位宽与子模块编号；SRT 原理、商位编码、位宽推导与
//   参数化核 xs_IterBlock_v4_core 都在 rtl/backend/IterBlock_v4.sv，核体不复制。
// golden 无 io_iter_cons_2 / io_spec_r2ud_2（父级恒连 0），wrapper 在该下标接 0。
//
// 本文件由 scripts/gen_srt_divblocks.py 生成，勿手改。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class IterBlock_v4)
// golden 对照：G1-canonical/golden-rtl/{mod}.sv
// =============================================================================
"""


def targets():
    out = {}
    # SelBlock_v4 / SpecBlock_v4：wrapper 区
    for fname, mod, core, shape, tag in [
            ("SelBlock_v4.sv", "SelBlock_v4", "xs_SelBlock_v4_core", SEL_SHAPE, "selblock-wrapper"),
            ("SpecBlock_v4.sv", "SpecBlock_v4", "xs_SpecBlock_v4_core", SPEC_SHAPE, "specblock-wrapper")]:
        path = os.path.join(RTL, fname)
        text = open(path).read()
        body = WRAPPER_BANNER.format(mod=mod) + gen_wrapper(mod, core, shape)
        out[path] = replace_region(text, tag, body, path)
    # IterBlock_v4：核内 selB/specB 连线 + wrapper 区
    path = os.path.join(RTL, "IterBlock_v4.sv")
    text = open(path).read()
    text = replace_region(text, "iterblock-selB",
                          gen_child_inst("SelBlock_v4", "u_sel", SEL_SHAPE, SEL_IN_ITER), path)
    text = replace_region(text, "iterblock-specB",
                          gen_child_inst("SpecBlock_v4", "u_spec", SPEC_SHAPE, SPEC_IN_ITER), path)
    mod, bw, _, _ = ITER_VARIANTS[0]
    body = WRAPPER_BANNER.format(mod=mod) + gen_wrapper(
        mod, "xs_IterBlock_v4_core", ITER_SHAPE, " #(.BIT_WIDTH(%d))" % bw, ITER_TIE0)
    out[path] = replace_region(text, "iterblock-wrapper", body, path)
    # 薄变体文件
    for mod, bw, csa, conv in ITER_VARIANTS[1:]:
        parent = {32: "SRT16Divint_4", 64: "SRT16Divint_6"}[bw]
        sewmax = {32: "10", 64: "11"}[bw]
        text = VARIANT_HEADER.format(mod=mod, bw=bw, w=bw + 6, csa=csa, conv=conv,
                                     parent=parent, sewmax=sewmax)
        text += "\n" + gen_wrapper(mod, "xs_IterBlock_v4_core", ITER_SHAPE,
                                   " #(.BIT_WIDTH(%d))" % bw, ITER_TIE0)
        out[os.path.join(RTL, mod + ".sv")] = text
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        rel = os.path.relpath(path, REPO)
        if cur == text:
            print("gen_srt_divblocks: OK     %s" % rel)
            continue
        if args.check:
            print("gen_srt_divblocks: DRIFT  %s" % rel)
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_srt_divblocks: WROTE  %s" % rel)
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
