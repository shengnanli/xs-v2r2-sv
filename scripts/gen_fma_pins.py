#!/usr/bin/env python3
"""gen_fma_pins.py —— 标量浮点乘加子树的 FM「匹配前」钉点生成器（agent/misc-core）。

产出三个文件，内容同源（同一张映射表，只差层次前缀）：
  verif/ut/CSA_Nto2With3to2MainPipeline/fm_pins_pre.tcl  —— 压缩树自己（4 个 107 位流水线寄存器）
  verif/ut/FloatFMA/fm_pins_pre.tcl                      —— FloatFMA 顶层寄存器 + U_CSAnto2 内的 4 个
  verif/ut/FMA/fm_pins_pre.tcl                           —— 父级 FMA：上面整套挂在 fma 实例下

为什么要钉：golden 的寄存器是扁平名（sign_result_temp_f32_reg2_r_1、U_CSA4to2_io_in_c_r 之类），
重写件把它们放进 u_core 与三个格式通路实例 g_fmt[f].u_fmt 里、按"级 + 语义"命名。不钉时 FM 靠签名
分析配对，lane 内非正式试跑（diagnostic-full，不出 receipt）实测：
  CSA_Nto2With3to2MainPipeline  4(4) unmatched —— 4 个常 0 位（树最低位的进位恒 0）签名无从下手；
  FloatFMA                      123(123) unmatched —— 压缩树里一批常 0 位 + 几个格式的 adder/尾数位。
钉点只声明"这两个点对应"，比较照比：不约束 ref、不改 appvar、不加黑盒。

映射表也是"寄存器表逐个对齐 golden"的机械核对（fail-closed）：
  (1) golden 模块里每个 `reg` 恰好命中一条规则（漏一个 / 多命中都报错），位宽相符；
  (2) 映射是单射（两个 golden 寄存器不许落到同一个 impl 位）；
  (3) impl 侧的基名必须在对应 rtl 文件里以该名字声明过；
  (4) 运行时逐条数 set_user_match 的返回值，拒一条或总数不等于字面整数即 error（用 error 不用 exit）。

用法:
  scripts/gen_fma_pins.py            # 写文件
  scripts/gen_fma_pins.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

G = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))

FMTS = ["f64", "f32", "f16"]     # g_fmt[0..2]
FMT_RE = "(f64|f32|f16)"
RM = ["RNE", "RTZ", "RDN", "RUP", "RMM"]   # rm_*_q 的位号 0..4
# 三级后缀：golden 的 RegEnable 链 X_r / X_r_1 / X  <->  impl 的 s0 / s1 / s2
STAGE3 = {"_r": "s0", "_r_1": "s1", "": "s2"}


def core(name):
    return ("u_core/", name)


def fmt(f, name):
    return ("u_core/g_fmt[%d].u_fmt/" % FMTS.index(f), name)


# ---- FloatFMA 顶层寄存器（rtl/backend/FloatFMA.sv） ----
FLOATFMA_RULES = [
    (r"fire_reg0_last_r", 1, lambda m: core("fire_s1")),
    (r"fire_reg1_last_r", 1, lambda m: core("fire_s2")),
    (r"is_fp(64|32)_reg([012])", 1, lambda m: core("is_fp%s_s%s_q" % (m[1], m[2]))),
    (r"(RNE|RTZ|RDN|RUP|RMM)_reg2(_r|_r_1|)", 1,
     lambda m: core("rm_%s_q[%d]" % (STAGE3[m[2]], RM.index(m[1])))),
    # is_sub 的 S0 寄存器：f64 一个；f32 / f16 各两个副本（golden 按 Scala 出现顺序起名）
    (r"is_sub_f64_reg0", 1, lambda m: fmt("f64", "is_sub_csa_q")),
    (r"CSA3to2_in_b_r", 1, lambda m: fmt("f32", "is_sub_csa_q")),
    (r"CSA3to2_in_b_r_1", 1, lambda m: fmt("f16", "is_sub_csa_q")),
    (r"adder_(f32|f16)_r", 1, lambda m: fmt(m[1], "g_is_sub_dup.is_sub_dup_q")),
    (r"rshift_(guard|round|sticky)_reg", 1, lambda m: core("rsh_%s_s0_q" % m[1])),
    (r"fp_c_rshiftValue_inv_reg", 162, lambda m: core("c_aligned_s0_q")),
    (r"adder_is_negative_reg([12])", 1, lambda m: core("adder_neg_s%s_q" % m[1])),
    (r"E_greater_reg2(_r|_r_1|)", 12, lambda m: core("exp_greater_%s_q" % STAGE3[m[1]])),
    (r"lshift_value_max_reg0", 12, lambda m: core("lshift_max_s0_q")),
    (r"tzd_adder_reg1", 164, lambda m: core("tzd_src_s1_q")),
    (r"lzd_adder_inv_mask_reg1", 163, lambda m: core("lzd_src_s1_q")),
    (r"lshift_mask_valid_reg", 1, lambda m: core("mask_valid_s1_q")),
    (r"adder_f64_reg1", 164, lambda m: fmt("f64", "adder_s1_q")),
    (r"adder_f32_reg1", 77, lambda m: fmt("f32", "adder_s1_q")),
    (r"adder_f16_reg1", 38, lambda m: fmt("f16", "adder_s1_q")),
    (r"fraction_result_no_round_reg", 52, lambda m: core("frac_s2_q")),
    (r"is_fix_reg2", 1, lambda m: core("is_fix_s2_q")),
    (r"lshift_value_reg2", 8, lambda m: core("lshift_value_s2_q")),
    (r"fp_result_fp_a_or_b_is_zero_reg(_r|_r_1|)", 64, lambda m: core("zero_result_%s_q" % STAGE3[m[1]])),
    # ---- 每格式独占的 1 位寄存器 ----
    (r"sign_result_temp_" + FMT_RE + r"_reg2(_r|_r_1|_r_2|)", 1,
     lambda m: fmt(m[1], {"_r": "sign_c_s0_q", "_r_1": "sign_ab_s0_q",
                          "_r_2": "sign_result_s1_q", "": "sign_result_s2_q"}[m[2]])),
    (r"sticky_(uf_)?" + FMT_RE + r"_reg2(_r|)", 1,
     lambda m: fmt(m[2], "sticky_%s%s_q" % (m[1] or "", "s1" if m[3] else "s2"))),
    (r"round_lshift_" + FMT_RE + r"_reg2", 1, lambda m: fmt(m[1], "round_lsh_s2_q")),
    (r"guard_lshift_" + FMT_RE + r"_reg2", 1, lambda m: fmt(m[1], "guard_lsh_s2_q")),
    (r"round_lshift_uf_" + FMT_RE + r"_reg2", 1, lambda m: fmt(m[1], "round_uf_lsh_s2_q")),
    (r"exponent_is_min_" + FMT_RE, 1, lambda m: fmt(m[1], "exp_is_min_s2_q")),
    (r"normal_result_is_zero_" + FMT_RE + r"_reg2(_r|)", 1,
     lambda m: fmt(m[1], "result_zero_%s_q" % ("s1" if m[2] else "s2"))),
    (r"has_zero_" + FMT_RE + r"_reg2(_r|_r_1|_r_2)", 1,
     lambda m: fmt(m[1], "has_zero_%s_q" % {"_r": "s0", "_r_1": "s1", "_r_2": "s2"}[m[2]])),
    (r"has_nan_" + FMT_RE + r"_reg2(_r|_r_1|)", 1, lambda m: fmt(m[1], "has_nan_%s_q" % STAGE3[m[2]])),
    (r"has_nan_" + FMT_RE + r"_is_NV_reg2(_r|_r_1|)", 1, lambda m: fmt(m[1], "has_nan_nv_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + FMT_RE + r"_reg2(_r|_r_1|)", 1, lambda m: fmt(m[1], "has_inf_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + FMT_RE + r"_is_NV_reg2(_r|_r_1|)", 1, lambda m: fmt(m[1], "has_inf_nv_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + FMT_RE + r"_result_inf_sign_reg2(_r|_r_1|)", 1,
     lambda m: fmt(m[1], "inf_sign_%s_q" % STAGE3[m[2]])),
    (r"fp_a_or_b_is_zero_" + FMT_RE + r"_reg2(_r|_r_1|)", 1, lambda m: fmt(m[1], "ab_zero_%s_q" % STAGE3[m[2]])),
]

# ---- CSA_Nto2With3to2MainPipeline（rtl/backend/CSA_Nto2With3to2MainPipeline.sv） ----
CSA_RULES = [
    (r"U_CSA4to2_io_in_([abcd])_r", 107, lambda m: core("level4_q[%d]" % "abcd".index(m[1]))),
]

# 模块 -> (golden 文件, 规则, 重写件, 子模块 [(子实例名（两侧同名，挂在 impl 的 u_core 下）, 子模块名)])
MODULES = {
    "CSA_Nto2With3to2MainPipeline": ("CSA_Nto2With3to2MainPipeline.sv", CSA_RULES,
                                     "rtl/backend/CSA_Nto2With3to2MainPipeline.sv", []),
    "FloatFMA": ("FloatFMA.sv", FLOATFMA_RULES, "rtl/backend/FloatFMA.sv",
                 [("U_CSAnto2", "CSA_Nto2With3to2MainPipeline")]),
}

# 输出：(UT 目录, FM 顶层, 被钉的模块, ref 前缀, impl 前缀, 说明)
#   FMA：golden 顶层里 FloatFMA 实例叫 fma；重写 FMA 把它放在 u_core 下（rtl/backend/FMA.sv:229）。
TARGETS = [
    ("CSA_Nto2With3to2MainPipeline", "CSA_Nto2With3to2MainPipeline", "CSA_Nto2With3to2MainPipeline", "", ""),
    ("FloatFMA", "FloatFMA", "FloatFMA", "", ""),
    ("FMA", "FMA", "FloatFMA", "fma/", "u_core/fma/"),
]


def golden_regs(mod, fname):
    txt = open(os.path.join(G, fname)).read()
    body = txt[txt.index("\nmodule %s(" % mod):]
    body = body[:body.index("\nendmodule")]
    out = []
    for m in re.finditer(r"^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);$", body, re.M):
        out.append((m.group(2), int(m.group(1)) + 1 if m.group(1) else 1))
    if not out:
        raise SystemExit("gen_fma_pins: golden %s 里一个 reg 都没解析到" % mod)
    return out


def esc(p):
    return p.replace("[", "\\[").replace("]", "\\]")


def module_pins(mod, ref_pfx, impl_pfx):
    """[(ref 基路径, impl 基路径, 位宽)]，路径不含 r:/WORK/<top>/ 前缀。"""
    fname, rules, rtl_rel, children = MODULES[mod]
    rules = [(re.compile(p + r"\Z"), w, f) for p, w, f in rules]
    rtl = open(os.path.join(REPO, rtl_rel)).read()
    pins, used = [], {}
    for name, width in golden_regs(mod, fname):
        hits = [(w, f(m)) for (p, w, f) in rules for m in [p.match(name)] if m]
        if len(hits) != 1:
            raise SystemExit("gen_fma_pins: %s 的 golden 寄存器 %s 命中 %d 条规则（须恰 1）" % (mod, name, len(hits)))
        w, (where, impl) = hits[0]
        if w != width:
            raise SystemExit("gen_fma_pins: %s.%s 位宽 golden=%d 规则=%d" % (mod, name, width, w))
        base = impl.split("[")[0].split(".")[-1]
        if not re.search(r"^\s*logic\b[^;\n]*\b%s\b" % re.escape(base), rtl, re.M):
            raise SystemExit("gen_fma_pins: impl 寄存器 %s 没在 %s 里声明" % (base, rtl_rel))
        key = (where, impl)
        if key in used:
            raise SystemExit("gen_fma_pins: %s 与 %s 落到同一个 impl 寄存器 %s%s" % (name, used[key], where, impl))
        used[key] = name
        head, _, idx = impl.partition("[")
        impl_path = where + head + "_reg" + (("[" + idx) if idx else "")
        pins.append((ref_pfx + name + "_reg", impl_pfx + impl_path, width))
    for inst, child in children:
        pins += module_pins(child, ref_pfx + inst + "/", impl_pfx + "u_core/" + inst + "/")
    return pins


def render(top, mod, ref_pfx, impl_pfx):
    pins = module_pins(mod, ref_pfx, impl_pfx)
    total = sum(w for _, _, w in pins)
    L = []
    L.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_fma_pins.py（勿手改）" % top)
    L.append("#")
    L.append("# 只消 golden 扁平寄存器名与重写件（u_core / g_fmt[f].u_fmt / 压缩树 level4_q）之间的命名鸿沟；")
    L.append("# 钉的是 %s%s 子树（%d 个 golden 寄存器 / %d 位）。" % (ref_pfx or "", mod, len(pins), total))
    L.append("# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    L.append("# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    L.append("# 拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。")
    L.append("set ::FMAPIN_OK 0")
    L.append("set ::FMAPIN_BAD 0")
    L.append("proc fmapin {g i w} {")
    L.append("  if {$w == 1} {")
    L.append('    set pairs [list "r:/WORK/%s/${g}" "i:/WORK/%s/${i}"]' % (top, top))
    L.append("  } else {")
    L.append("    set pairs {}")
    L.append("    for {set b 0} {$b < $w} {incr b} {")
    L.append('      lappend pairs "r:/WORK/%s/${g}\\[$b\\]" "i:/WORK/%s/${i}\\[$b\\]"' % (top, top))
    L.append("    }")
    L.append("  }")
    L.append("  foreach {r m} $pairs {")
    L.append("    if {[set_user_match $r $m]} { incr ::FMAPIN_OK } else {")
    L.append("      incr ::FMAPIN_BAD")
    L.append('      if {$::FMAPIN_BAD <= 10} { puts "FMAPIN_FAIL: $r <-> $m" }')
    L.append("    }")
    L.append("  }")
    L.append("}")
    L.append('puts "FMAPIN_BEGIN %s expect=%d"' % (top, total))
    for g, i, w in pins:
        L.append("fmapin %s %s %d" % (esc(g), esc(i), w))
    L.append('puts "FMAPIN_END %s ok=$::FMAPIN_OK bad=$::FMAPIN_BAD"' % top)
    L.append('if {$::FMAPIN_BAD != 0} { error "FMAPIN_MISS=$::FMAPIN_BAD" }')
    L.append('if {$::FMAPIN_OK != %d} { error "FMAPIN_COUNT=$::FMAPIN_OK expect=%d" }' % (total, total))
    return "\n".join(L) + "\n", len(pins), total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    rc = 0
    for ut, top, mod, ref_pfx, impl_pfx in TARGETS:
        txt, nreg, total = render(top, mod, ref_pfx, impl_pfx)
        out = os.path.join(REPO, "verif", "ut", ut, "fm_pins_pre.tcl")
        rel = os.path.relpath(out, REPO)
        old = open(out).read() if os.path.exists(out) else None
        if args.check:
            if old != txt:
                print("gen_fma_pins: DRIFT %s（请跑 scripts/gen_fma_pins.py 刷新）" % rel)
                rc = 1
            else:
                print("gen_fma_pins: OK %s（%d 个 golden 寄存器 / %d 位）" % (rel, nreg, total))
        elif old != txt:
            with open(out, "w") as f:
                f.write(txt)
            print("gen_fma_pins: wrote %s（%d 个 golden 寄存器 / %d 位）" % (rel, nreg, total))
        else:
            print("gen_fma_pins: unchanged %s" % rel)
    return rc


if __name__ == "__main__":
    sys.exit(main())
