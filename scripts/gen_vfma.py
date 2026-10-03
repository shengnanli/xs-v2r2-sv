#!/usr/bin/env python3
"""gen_vfma.py —— VectorFloatFMA 的 FM「匹配前」钉点生成器（verif/ut/VectorFloatFMA/fm_pins_pre.tcl）。

为什么要钉：golden 顶层 301 个寄存器是扁平名（sign_result_temp_f16_2_reg2_r_1 之类），重写核把它们
放在 u_core 与七个通道实例 u_core/g_lane[l].u_lane 里、按"级 + 语义"命名。不钉时 FM 靠签名分析配对，
而本模块有成组的**内容相同**的寄存器（is_sub 的两个副本、sticky / sticky_uf 的第 1 级副本、七条通道
结构对称），签名分析要么配不上（lane 内非正式试跑：1(1) unmatched）、要么可能错配。钉点只声明
"这两个点对应"，比较照比：不约束 ref、不改 appvar、不加黑盒。

映射表（本文件 RULES）也是"寄存器表逐个对齐 golden"的机械核对：
  (1) golden 顶层每个 `reg` 恰好命中一条规则（漏一个 / 多命中都报错）；
  (2) 映射是单射（两个 golden 寄存器不许落到同一个 impl 位）；
  (3) impl 侧的基名必须在 rtl/backend/VectorFloatFMA.sv 里以该名字声明过；
  (4) 运行时逐条数 set_user_match 的返回值，拒一条或总数不等于字面整数（= golden 顶层寄存器位数）即 error。
子模块（U_CSAnto2 的 4 个 107 位寄存器）两侧同名，不钉。

用法:
  scripts/gen_vfma.py            # 写文件
  scripts/gen_vfma.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl/VectorFloatFMA.sv"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
RTL = os.path.join(REPO, "rtl", "backend", "VectorFloatFMA.sv")
OUT = os.path.join(REPO, "verif", "ut", "VectorFloatFMA", "fm_pins_pre.tcl")

LANES = ["f64", "f32_0", "f32_1", "f16_0", "f16_1", "f16_2", "f16_3"]   # 通道号 0..6
LANE_RE = "(f64|f32_[01]|f16_[0-3])"
RM = ["RNE", "RTZ", "RDN", "RUP", "RMM"]                                 # rm_*_q 的位号 0..4

# 三级后缀：golden 的 RegEnable 链 X_r / X_r_1 / X  <->  impl 的 s0 / s1 / s2
STAGE3 = {"_r": "s0", "_r_1": "s1", "": "s2"}


def core(name):
    """核里的寄存器。"""
    return ("core", name)


def lane(m_lane, name):
    """通道实例里的寄存器。"""
    return ("lane%d" % LANES.index(m_lane), name)


def bit(sig, idx):
    return "%s[%d]" % (sig, idx)


# (golden 名的正则, 位宽, m -> (位置, impl 寄存器名[可带下标]))
RULES = [
    (r"fire_reg0_last_r", 1, lambda m: core("fire_s1")),
    (r"fire_reg1_last_r", 1, lambda m: core("fire_s2")),
    (r"is_fp(64|32)_reg([012])", 1, lambda m: core("is_fp%s_s%s_q" % (m[1], m[2]))),
    (r"is_sub_f64_reg0", 1, lambda m: core("is_sub_f64_s0_q")),
    (r"rshift_(guard|round|sticky)_reg", 4, lambda m: core("rsh_%s_s0_q" % m[1])),
    (r"fp_c_rshiftValue_inv_reg", 162, lambda m: core("c_aligned_s0_q")),
    # is_sub 的两个副本（f32 / f16 通道）。golden 第一个副本按 Scala 里出现的顺序编号：
    #   CSA3to2_in_b_r, _r_1 = f32_1, f32_0；_r_2.._r_5 = f16_3, f16_2, f16_1, f16_0
    (r"CSA3to2_in_b_r(?:_([1-5]))?", 1,
     lambda m: core(bit("is_sub_csa_s0_q", [2, 1, 6, 5, 4, 3][int(m[1] or 0)]))),
    (r"adder_" + LANE_RE + "_r", 1, lambda m: core(bit("is_sub_adder_s0_q", LANES.index(m[1])))),
    (r"adder_is_negative_reg([12])", 4, lambda m: core("adder_neg_s%s_q" % m[1])),
    (r"E_greater_reg2(_r|_r_1|)", 24, lambda m: core("exp_greater_%s_q" % STAGE3[m[1]])),
    (r"lshift_value_max_reg0", 24, lambda m: core("lshift_max_s0_q")),
    (r"tzd_adder_reg1", 164, lambda m: core("tzd_src_s1_q")),
    (r"lzd_adder_inv_mask_reg1", 163, lambda m: core("lzd_src_s1_q")),
    (r"lshift_mask_valid_reg", 4, lambda m: core("mask_valid_s1_q")),
    (r"adder_reg1", 164, lambda m: core("adder_s1_q")),
    (r"fraction_result_no_round_reg", 52, lambda m: core("frac_s2_q")),
    (r"(RNE|RTZ|RDN|RUP|RMM)_reg2(_r|_r_1|)", 1,
     lambda m: core(bit("rm_%s_q" % STAGE3[m[2]], RM.index(m[1])))),
    (r"is_fix_reg2", 4, lambda m: core("is_fix_s2_q")),
    (r"lshift_value_reg2", 24, lambda m: core("lshift_value_s2_q")),
    (r"fp_result_fp_a_or_b_is_zero_reg(_r|_r_1|)", 64, lambda m: core("zero_result_%s_q" % STAGE3[m[1]])),
    # ---- 每条通道独占的 1 位寄存器 ----
    (r"sign_result_temp_" + LANE_RE + r"_reg2(_r|_r_1|_r_2|)", 1,
     lambda m: lane(m[1], {"_r": "sign_c_s0_q", "_r_1": "sign_ab_s0_q",
                           "_r_2": "sign_result_s1_q", "": "sign_result_s2_q"}[m[2]])),
    (r"sticky_(uf_)?" + LANE_RE + r"_reg2(_r|)", 1,
     lambda m: lane(m[2], "sticky_%s%s_q" % (m[1] or "", "s1" if m[3] else "s2"))),
    # golden 里 f32_1 这一个的名字是 round_lshift_f32_1_Reg2（Scala 源的大小写笔误），照认
    (r"round_lshift_" + LANE_RE + r"_[rR]eg2", 1, lambda m: lane(m[1], "round_lsh_s2_q")),
    (r"guard_lshift_" + LANE_RE + r"_reg2", 1, lambda m: lane(m[1], "guard_lsh_s2_q")),
    (r"round_lshift_uf_" + LANE_RE + r"_reg2", 1, lambda m: lane(m[1], "round_uf_lsh_s2_q")),
    (r"exponent_is_min_" + LANE_RE, 1, lambda m: lane(m[1], "exp_is_min_s2_q")),
    (r"normal_result_is_zero_" + LANE_RE + r"_reg2(_r|)", 1,
     lambda m: lane(m[1], "result_zero_%s_q" % ("s1" if m[2] else "s2"))),
    (r"has_zero_" + LANE_RE + r"_reg2(_r|_r_1|_r_2)", 1,
     lambda m: lane(m[1], "has_zero_%s_q" % {"_r": "s0", "_r_1": "s1", "_r_2": "s2"}[m[2]])),
    (r"has_nan_" + LANE_RE + r"_reg2(_r|_r_1|)", 1, lambda m: lane(m[1], "has_nan_%s_q" % STAGE3[m[2]])),
    (r"has_nan_" + LANE_RE + r"_is_NV_reg2(_r|_r_1|)", 1, lambda m: lane(m[1], "has_nan_nv_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + LANE_RE + r"_reg2(_r|_r_1|)", 1, lambda m: lane(m[1], "has_inf_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + LANE_RE + r"_is_NV_reg2(_r|_r_1|)", 1, lambda m: lane(m[1], "has_inf_nv_%s_q" % STAGE3[m[2]])),
    (r"has_inf_" + LANE_RE + r"_result_inf_sign_reg2(_r|_r_1|)", 1,
     lambda m: lane(m[1], "inf_sign_%s_q" % STAGE3[m[2]])),
    (r"fp_a_or_b_is_zero_" + LANE_RE + r"_reg2(_r|_r_1|)", 1, lambda m: lane(m[1], "ab_zero_%s_q" % STAGE3[m[2]])),
]
RULES = [(re.compile(p + r"\Z"), w, f) for p, w, f in RULES]


def golden_regs():
    """golden 顶层 VectorFloatFMA 的寄存器表：[(name, width)]，按声明顺序。"""
    txt = open(GOLDEN).read()
    body = txt[txt.index("\nmodule VectorFloatFMA("):]
    body = body[:body.index("\nendmodule")]
    out = []
    for m in re.finditer(r"^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);$", body, re.M):
        out.append((m.group(2), int(m.group(1)) + 1 if m.group(1) else 1))
    return out


def build():
    regs = golden_regs()
    rtl = open(RTL).read()
    pins, used, total = [], {}, 0
    for name, width in regs:
        hits = [(w, f(m)) for (p, w, f) in RULES for m in [p.match(name)] if m]
        if len(hits) != 1:
            raise SystemExit("gen_vfma: golden 寄存器 %s 命中 %d 条规则（须恰 1）" % (name, len(hits)))
        w, (where, impl) = hits[0]
        if w != width:
            raise SystemExit("gen_vfma: %s 位宽 golden=%d 规则=%d" % (name, width, w))
        base = impl.split("[")[0]
        if not re.search(r"^\s*logic\b[^;\n]*\b%s\b" % re.escape(base), rtl, re.M):
            raise SystemExit("gen_vfma: impl 寄存器 %s 没在 %s 里声明" % (base, os.path.basename(RTL)))
        if "[" in impl and width != 1:
            raise SystemExit("gen_vfma: %s 带下标的 impl 目标只能是 1 位" % name)
        key = (where, impl)
        if key in used:
            raise SystemExit("gen_vfma: %s 与 %s 落到同一个 impl 寄存器 %s/%s" % (name, used[key], where, impl))
        used[key] = name
        if where == "core":
            path = base + "_reg" + impl[len(base):]
        else:
            path = "g_lane[%s].u_lane/%s_reg%s" % (where[4:], base, impl[len(base):])
        pins.append((name, path.replace("[", "\\[").replace("]", "\\]"), width))
        total += width
    return pins, total, len(regs)


def render():
    pins, total, nreg = build()
    L = []
    L.append("# VectorFloatFMA FM「匹配前」钉点 —— 自动生成：scripts/gen_vfma.py（勿手改）")
    L.append("#")
    L.append("# 只消 golden 扁平寄存器名与重写核（u_core + 七个通道实例）寄存器名之间的命名鸿沟。")
    L.append("# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    L.append("# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    L.append("# 拒一条或总数不等于字面整数（= golden 顶层 %d 个寄存器的位数）就 error。" % nreg)
    L.append("# U_CSAnto2 内部的寄存器两侧同名，不钉。进 fm.log 的输出一律 ASCII。")
    L.append("set ::VFMA_PIN_EXPECT %d" % total)
    L.append("set ::VFMA_PIN_OK 0")
    L.append("set ::VFMA_PIN_BAD 0")
    L.append("proc vfma_pin {g i w} {")
    L.append("  if {$w == 1} {")
    L.append('    set pairs [list "r:/WORK/VectorFloatFMA/${g}_reg" "i:/WORK/VectorFloatFMA/u_core/${i}"]')
    L.append("  } else {")
    L.append("    set pairs {}")
    L.append("    for {set b 0} {$b < $w} {incr b} {")
    L.append('      lappend pairs "r:/WORK/VectorFloatFMA/${g}_reg\\[$b\\]" "i:/WORK/VectorFloatFMA/u_core/${i}\\[$b\\]"')
    L.append("    }")
    L.append("  }")
    L.append("  foreach {r m} $pairs {")
    L.append("    if {[set_user_match $r $m]} { incr ::VFMA_PIN_OK } else {")
    L.append("      incr ::VFMA_PIN_BAD")
    L.append('      if {$::VFMA_PIN_BAD <= 10} { puts "VFMA_PIN_FAIL: $r <-> $m" }')
    L.append("    }")
    L.append("  }")
    L.append("}")
    L.append('puts "VFMA_PIN_BEGIN VectorFloatFMA expect=$::VFMA_PIN_EXPECT"')
    for g, i, w in pins:
        L.append("vfma_pin %s %s %d" % (g, i, w))
    L.append('puts "VFMA_PIN_END VectorFloatFMA ok=$::VFMA_PIN_OK bad=$::VFMA_PIN_BAD"')
    L.append('if {$::VFMA_PIN_BAD != 0} { error "VFMA_PIN_MISS=$::VFMA_PIN_BAD" }')
    L.append('if {$::VFMA_PIN_OK != %d} { error "VFMA_PIN_COUNT=$::VFMA_PIN_OK expect=%d" }' % (total, total))
    return "\n".join(L) + "\n", total, nreg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    txt, total, nreg = render()
    old = open(OUT).read() if os.path.exists(OUT) else None
    rel = os.path.relpath(OUT, REPO)
    if args.check:
        if old != txt:
            print("gen_vfma: DRIFT %s（请跑 scripts/gen_vfma.py 刷新）" % rel)
            return 1
        print("gen_vfma: OK %s（%d 个 golden 寄存器 / %d 位，一一对应）" % (rel, nreg, total))
        return 0
    if old != txt:
        with open(OUT, "w") as f:
            f.write(txt)
        print("gen_vfma: wrote %s（%d 个 golden 寄存器 / %d 位）" % (rel, nreg, total))
    else:
        print("gen_vfma: unchanged %s（%d 个 golden 寄存器 / %d 位）" % (rel, nreg, total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
