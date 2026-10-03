#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_srt16divint.py —— SRT16Divint 家族的机械派生区生成器（核手写，本脚本不碰核逻辑）。

生成什么：
  rtl/backend/SRT16Divint.sv     GENERATED(srt16divint-iterblock)  核内按位宽例化 IterBlock_v4 /
                                                                     _4 / _6 的扁平端口连线
  rtl/backend/SRT16Divint_4.sv   整个文件（薄 wrapper，BIT_WIDTH=32）
  rtl/backend/SRT16Divint_6.sv   整个文件（薄 wrapper，BIT_WIDTH=64）
  verif/ut/SRT16Divint/fm_pins_pre.tcl  FM「匹配前」钉点（三个目标各一支）
  verif/ut/VectorIdiv/fm_pins_pre.tcl   FM「匹配前」钉点（8 个 SRT 子实例 + 8 个 I8DivNr4 死位）

为什么要钉点：核把商位 0 那档恒 0 的常数删掉，只存 4 个非零档 iter_cons_nz_reg[0..3] /
  spec_r2ud_nz_reg[0..3]（下标 0..3 ↔ golden 的 _0/_1/_3/_4）。FM 的名字匹配会把 golden
  iter_cons_reg_3 配给核里的 [3]（实为 _4），配错之后连带一大片寄存器比对失败（诊断跑实测 513 点）。
  钉点把这 8 组寄存器逐位钉成正确的一对；只消名差，不约束 ref、不 dont_verify。

映射规则（fail-closed）：IterBlock 的每个 golden 端口 io_<base>(_<i>)* 恰好命中下表一条，
  下标个数 = 维数且不越界；核内信号的每个元素恰好被一个端口覆盖。iter_cons / spec_r2ud
  的 golden 端口只有商位下标 0,1,3,4（q=0 那档恒 0 被删），按 0,1,3,4 → *_nz_reg[0..3] 映射。
  SRT16Divint{,_4,_6} 的 golden 端口表必须与本脚本的 wrapper 模板逐行一致（宽度按位宽代入）。

用法:
  python3 scripts/gen_srt16divint.py           # 生成/刷新
  python3 scripts/gen_srt16divint.py --check   # 只比对不写；有漂移 rc=1（闸用）
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

VARIANTS = [  # (父模块, BIT_WIDTH, IterBlock 变体, generate 块名)
    ("SRT16Divint", 16, "IterBlock_v4", "g_w16"),
    ("SRT16Divint_4", 32, "IterBlock_v4_4", "g_w32"),
    ("SRT16Divint_6", 64, "IterBlock_v4_6", "g_w64"),
]

# IterBlock 端口 base -> (核内信号, 维度, 下标映射)
NZ = {0: 0, 1: 1, 3: 2, 4: 3}
ITER_MAP = [
    ("Sel_cons", "sel_cons_reg", [5, 4], None),
    ("Spec_cons", "spec_cons_reg", [5, 4], None),
    ("iter_cons", "iter_cons_nz_reg", [5], NZ),
    ("d_trunc", "d_trunc_reg", [4], None),
    ("spec_r2ud", "spec_r2ud_nz_reg", [5], NZ),
    ("pre_q_A", "iter_q_A_reg", [], None),
    ("pre_q_B", "iter_q_B_reg", [], None),
    ("nxt_q_A", "nxt_q_A", [], None),
    ("nxt_q_B", "nxt_q_B", [], None),
    ("pre_sel", "sel_reg", [4, 2], None),
    ("nxt_sel", "nxt_sel", [4, 2], None),
    ("pre_spec", "spec_reg", [5, 4, 2], None),
    ("nxt_spec", "nxt_spec", [5, 4, 2], None),
    ("pre_iterB", "iterB_reg", [2], None),
    ("nxt_iterB", "nxt_iterB", [2], None),
]


def die(msg):
    sys.stderr.write("gen_srt16divint: ERROR: %s\n" % msg)
    sys.exit(2)


def golden_ports(module):
    text = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    m = re.search(r"^module %s\((.*?)^\);" % re.escape(module), text, re.S | re.M)
    if not m:
        die("golden %s 找不到模块头" % module)
    out = []
    for line in m.group(1).splitlines():
        if line.strip():
            pm = PORT_RE.match(line)
            if not pm:
                die("golden %s 端口行无法解析: %r" % (module, line))
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else None, pm.group(3)))
    return out


def iter_conns(module):
    conns, covered = [], set()
    for d, w, name in golden_ports(module):
        n = name[3:]
        hits = []
        for base, sig, dims, remap in ITER_MAP:
            if n == base and not dims:
                hits.append((base, sig, (), remap))
            elif dims and n.startswith(base + "_"):
                im = re.fullmatch(r"(?:_(\d+))" * len(dims), n[len(base):])
                if im:
                    idx = tuple(int(x) for x in im.groups())
                    if all(i < lim for i, lim in zip(idx, dims)):
                        hits.append((base, sig, idx, remap))
        if len(hits) != 1:
            die("%s.%s 命中 %d 条规则" % (module, name, len(hits)))
        base, sig, idx, remap = hits[0]
        if remap is not None:
            if idx[0] not in remap:
                die("%s.%s 的下标 %d 不在非零档映射里" % (module, name, idx[0]))
            sidx = (remap[idx[0]],)
        else:
            sidx = idx
        key = (sig, sidx)
        if key in covered:
            die("%s: %s%r 被两个端口覆盖" % (module, sig, sidx))
        covered.add(key)
        conns.append((name, sig + "".join("[%d]" % i for i in sidx)))
    for base, sig, dims, remap in ITER_MAP:
        space = [()] if not dims else (
            [(v,) for v in sorted(remap.values())] if remap is not None
            else list(itertools.product(*[range(x) for x in dims])))
        for idx in space:
            if (sig, tuple(idx)) not in covered:
                die("%s: %s%r 没有端口覆盖" % (module, sig, idx))
    return conns


def gen_region():
    out = []
    for k, (_, bw, iterb, blk) in enumerate(VARIANTS):
        head = "if" if k == 0 else "end else if"
        out.append("  %s (BIT_WIDTH == %d) begin : %s" % (head, bw, blk))
        conns = iter_conns(iterb)
        pw = max(len(n) for n, _ in conns)
        out.append("    %s IterBlock (" % iterb)
        for j, (n, e) in enumerate(conns):
            sep = "," if j + 1 < len(conns) else ""
            out.append("      .%-*s (%s)%s" % (pw, n, e, sep))
        out.append("    );")
    out.append("  end")
    return "\n".join(out) + "\n"


WRAPPER_PORTS = [  # (dir, 是否 BIT_WIDTH 宽 / 固定宽, name)
    ("input", None, "clock"), ("input", None, "reset"), ("input", None, "io_sign"),
    ("input", "BW", "io_dividend"), ("input", "BW", "io_divisor"), ("input", None, "io_flush"),
    ("input", 2, "io_sew"), ("input", None, "io_div_in_valid"), ("input", None, "io_div_out_ready"),
    ("output", None, "io_div_out_valid"), ("output", "BW", "io_div_out_q"),
    ("output", "BW", "io_div_out_rem"),
]
CORE_CONN = [("clock", "clock"), ("reset", "reset"), ("sign", "io_sign"),
             ("dividend", "io_dividend"), ("divisor", "io_divisor"), ("flush", "io_flush"),
             ("sew", "io_sew"), ("div_in_valid", "io_div_in_valid"),
             ("div_out_ready", "io_div_out_ready"), ("div_out_valid", "io_div_out_valid"),
             ("div_out_q", "io_div_out_q"), ("div_out_rem", "io_div_out_rem")]


def gen_wrapper(module, bw):
    want = [(d, (bw if w == "BW" else w), n) for d, w, n in WRAPPER_PORTS]
    got = golden_ports(module)
    if [(d, w if w != 1 else None, n) for d, w, n in want] != got:
        die("%s 的 golden 端口表与 wrapper 模板不一致" % module)
    wfield = len("[%d:0]" % (bw - 1))
    lines = ["module %s(" % module]
    for k, (d, w, n) in enumerate(want):
        wd = ("[%d:0]" % (w - 1)) if w else ""
        sep = "," if k + 1 < len(want) else ""
        lines.append("  %-6s %-*s %s%s" % (d, wfield, wd, n, sep))
    lines.append(");")
    lines.append("  xs_SRT16Divint_core #(.BIT_WIDTH(%d)) u_core (" % bw)
    for k, (p, e) in enumerate(CORE_CONN):
        sep = "," if k + 1 < len(CORE_CONN) else ""
        lines.append("    .%-13s (%s)%s" % (p, e, sep))
    lines.append("  );")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


VARIANT_HEADER = """// =============================================================================
// {mod}.sv —— SRT radix-16 整数除法器，**本变体 BIT_WIDTH={bw}**
//
// 在哪一层：VectorIdiv 的 {bw} 位车道（{inst}），sew 可取 00..{sewmax}。
// 本变体规模：余数 carry-save 宽 W={w}（= BIT_WIDTH + 6）、前导零计数 {lzc} 位、迭代计数 {itn} 位，
//   最多 {maxit} 拍迭代（每拍 4 位商）；子模块 SRT4qdsCons ×1、{iterb} ×1（本仓已签核重写件）。
// 与 SRT16Divint（16 位）只差位宽与 IterBlock 变体；握手状态机、PRE0/PRE1/ITER/POST 各级、
//   寄存器复用与 bug-for-bug 要点都在参数化核 xs_SRT16Divint_core（rtl/backend/SRT16Divint.sv）里，
//   核体不复制。
//
// 本文件由 scripts/gen_srt16divint.py 生成，勿手改。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class SRT16Divint)
// golden 对照：G1-canonical/golden-rtl/{mod}.sv
// =============================================================================

"""


def replace_region(text, tag, body, path):
    begin = "// BEGIN GENERATED(%s)\n" % tag
    pat = re.compile(r"([ \t]*)" + re.escape(begin) + r"(.*?)([ \t]*)// END GENERATED\n", re.S)
    if len(pat.findall(text)) != 1:
        die("%s: GENERATED(%s) 区须恰好 1 处" % (path, tag))
    return pat.sub(lambda m: m.group(1) + begin + body + m.group(3) + "// END GENERATED\n",
                   text, count=1)


PIN_HEADER = """# {ut} FM「匹配前」钉点 —— 由 scripts/gen_srt16divint.py 生成，勿手改
# ============================================================================
# 只消名差：不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点。
# SRT16Divint 家族：核只存商位 +2/+1/-1/-2 四个非零档的迭代常数（iter_cons_nz_reg[0..3]、
#   spec_r2ud_nz_reg[0..3]，下标 0..3 <-> golden iter_cons_reg_0/_1/_3/_4），FM 名字匹配会按
#   "_3"<->"[3]" 配错（诊断跑：513 个 failing 全是这一错配的连带），故逐位钉成正确的一对。
{extra}# fail-closed：用 set_user_match 的返回值计数（它找不到名字不抛异常），字面整数守卫，
# 中止一律 error（safe interp 里没有 exit）。
# ============================================================================
"""

I8_DEAD_NOTE = """# I8DivNr4 的 4 个死位 const_d_reg_k[9]（10 位寄存器只被读低 9 位，两侧对称），每个实例一组，
#   钉成 matched-unread 后由 vmucp 真去比（白名单 verif/fm_target_config/VectorIdiv.tcl）。
"""


def srt_pins(ref_pfx, impl_pfx, bw):
    w = bw + 6
    out = []
    for golden_idx, nz in sorted(NZ.items()):
        for b in range(w):
            out.append(("%siter_cons_reg_%d_reg\\[%d\\]" % (ref_pfx, golden_idx, b),
                        "%siter_cons_nz_reg_reg\\[%d\\]\\[%d\\]" % (impl_pfx, nz, b)))
        for b in range(11):
            out.append(("%sspec_r2ud_reg_%d_reg\\[%d\\]" % (ref_pfx, golden_idx, b),
                        "%sspec_r2ud_nz_reg_reg\\[%d\\]\\[%d\\]" % (impl_pfx, nz, b)))
    return out


def i8_pins(ref_pfx, impl_pfx):
    return [("%sconst_d_reg_%d_reg\\[9\\]" % (ref_pfx, k),
             "%sconst_d_reg_reg\\[%d\\]\\[9\\]" % (impl_pfx, k)) for k in range(4)]


def pin_branch(top, pairs, tag):
    lines = ['if {$top eq "%s"} {' % top, "  set _n 0"]
    for r, i in pairs:
        lines.append('  if {[set_user_match "r:/WORK/$top/%s" "i:/WORK/$top/%s"]} { incr _n } '
                     'else { puts "%s_PIN_FAIL: %s" }' % (r, i, tag, r))
    lines.append('  puts "%s_PINS: $_n / %d points pinned"' % (tag, len(pairs)))
    lines.append('  if {$_n != %d} { error "%s_PIN_COUNT=$_n expected %d" }' % (len(pairs), tag, len(pairs)))
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_pins_srt():
    text = PIN_HEADER.format(ut="SRT16Divint", extra="")
    for mod, bw, _, _ in VARIANTS:
        text += "\n" + pin_branch(mod, srt_pins("", "u_core/", bw), mod.upper())
    return text


VI_SRT_INST = [("_16bit_divide_%d" % i, 16) for i in range(4)] + \
              [("_32bit_divide_%d" % i, 32) for i in range(2)] + \
              [("_64bit_divide_%d" % i, 64) for i in range(2)]


def gen_pins_vi():
    pairs = []
    for inst, bw in VI_SRT_INST:
        pairs += srt_pins(inst + "/", "u_core/%s/u_core/" % inst, bw)
    for i in range(8):
        inst = "_8bit_divide_%d" % i
        pairs += i8_pins(inst + "/", "u_core/%s/u_core/" % inst)
    return PIN_HEADER.format(ut="VectorIdiv", extra=I8_DEAD_NOTE) + "\n" + \
        pin_branch("VectorIdiv", pairs, "VECTORIDIV")


def targets():
    out = {}
    path = os.path.join(RTL, "SRT16Divint.sv")
    text = replace_region(open(path).read(), "srt16divint-iterblock", gen_region(), path)
    # 16 位 wrapper 手写在文件里，这里只核对它与模板一致
    if gen_wrapper("SRT16Divint", 16) not in text:
        die("SRT16Divint.sv 里的手写 wrapper 与 golden 端口模板不一致")
    out[path] = text
    info = {32: ("_32bit_divide_0..1", "10", "SRT16Divint_4"), 64: ("_64bit_divide_0..1", "11", "SRT16Divint_6")}
    for mod, bw, iterb, _ in VARIANTS[1:]:
        inst, sewmax, _ = info[bw]
        lzc = (bw - 1).bit_length()
        hdr = VARIANT_HEADER.format(mod=mod, bw=bw, w=bw + 6, inst=inst, sewmax=sewmax,
                                    lzc=lzc, itn=lzc - 2, maxit=2 ** (lzc - 2), iterb=iterb)
        out[os.path.join(RTL, mod + ".sv")] = hdr + gen_wrapper(mod, bw)
    out[os.path.join(REPO, "verif", "ut", "SRT16Divint", "fm_pins_pre.tcl")] = gen_pins_srt()
    out[os.path.join(REPO, "verif", "ut", "VectorIdiv", "fm_pins_pre.tcl")] = gen_pins_vi()
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
            print("gen_srt16divint: OK     %s" % rel)
            continue
        if args.check:
            print("gen_srt16divint: DRIFT  %s" % rel)
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_srt16divint: WROTE  %s" % rel)
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
