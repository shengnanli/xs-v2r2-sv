#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_mmuleaf.py —— mmuleaf lane 的机械派生区：FM「匹配前」钉点 fm_pins_pre.tcl + 子模块例化连线。

golden 是 firtool 展平后的寄存器名（array_3_tag、valids_7、last_REG_5 …），重写核用 generate 块 /
数组 / 语义名（array[3].tag、valids[7]、array[5].last_REG …）。名字对不上时 Formality 只能靠签名
分析去猜，表项多了就会卡在 matching。这里按规则表把 **golden 顶层每一个寄存器的每一位** 一一对应
到重写核里的寄存器位，生成 set_user_match 钉点：

  · 规则表 fail-closed：每个 golden 寄存器必须恰好命中一条规则，否则拒绝生成；
  · 映射必须是单射（两个 golden 寄存器不许落到同一个重写寄存器），否则拒绝生成；
  · 生成的 tcl 运行时逐条数 set_user_match 的返回值（它从不抛异常，0 = 没配上），
    拒一条或总数不等于字面整数（= golden 顶层寄存器总位数）就 error。

set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。

另外，重写核里例化 golden 子模块（扁平端口 io_in_<i>_valid …）的连线没有设计决策，只是长长的逐口
连线，也在这里按 golden 子模块端口表生成，写进 rtl 文件的 `BEGIN GENERATED(<tag>)` 区：
每个端口必须恰好被一条映射规则认领，认领不了（或有规则没用上）就拒绝生成。

用法：
    python3 scripts/gen_mmuleaf.py            # 生成（幂等：内容不变不写文件）
    python3 scripts/gen_mmuleaf.py --check    # 产物与生成器不一致则 rc=1
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"


def golden_top_regs(module):
    """golden 顶层（不含子模块）寄存器声明：[(名字, 位宽)]，按声明顺序。"""
    t = open(os.path.join(GOLDEN_DIR, module + ".sv")).read()
    body = t[t.index("module %s(" % module):]
    body = body[:body.index("\nendmodule")]
    body = re.sub(r"reg\s+(\[\d+:\d+\])\s*\n\s*", r"reg \1 ", body)  # 折行的声明
    out = []
    for a, b, n in re.findall(r"^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);", body, re.M):
        out.append((n, int(a) - int(b) + 1 if a else 1))
    if not out:
        raise SystemExit("gen_mmuleaf: golden %s 里一个寄存器也没解析到" % module)
    return out


def esc(s):
    return s.replace("[", "\\[").replace("]", "\\]")


# -----------------------------------------------------------------------------
#  规则表：golden 寄存器名 -> (重写核里的寄存器名, 数组下标串)
#  最终 impl 路径 = u_core/<名>_reg<下标串>[<位>]（单比特无 [<位>]）
# -----------------------------------------------------------------------------
def sbva_rule(name):
    rules = [
        # 表项字段：generate 块 array[i] 里的同名字段
        (r"array_(\d+)_(tag|bit_vec|active|cnt)", lambda m: ("array[%s].%s" % (m[1], m[2]), "")),
        (r"valids_(\d+)", lambda m: ("valids", "[%s]" % m[1])),
        # RegNext(flush)：每项一份，第 0 项无后缀
        (r"last_REG(?:_(\d+))?", lambda m: ("array[%d].last_REG" % int(m[1] or 0), "")),
        # 内联的 PLRU 树 -> 共享辅助件实例
        (r"state_reg", lambda m: ("u_plru/state_reg", "")),
        # 只喂断言的三个寄存器（§7）
        (r"REG", lambda m: ("assert_s0_valid_d1", "")),
        (r"r", lambda m: ("assert_s0_hit_d1", "")),
        (r"r_1", lambda m: ("assert_plru_way_d1", "")),
        # 其余流水寄存器与 golden 同名
        (r"(s[1-5]_\w+)", lambda m: (m[1], "")),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    return hits


# -----------------------------------------------------------------------------
#  子模块例化连线
# -----------------------------------------------------------------------------
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")


def golden_ports(mod):
    t = open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % re.escape(mod), t, re.S | re.M)
    if not m:
        raise SystemExit("gen_mmuleaf: golden 里找不到 module %s" % mod)
    out = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            raise SystemExit("gen_mmuleaf: %s 端口行解析不了：%r" % (mod, ln))
        out.append(pm.group(3))
    return out


def gen_inst(mod, inst, rules, indent="  "):
    """rules: [(正则, 连线表达式模板)]，模板里 {0},{1}… 是正则分组。每口恰好一条、每条至少用一次。"""
    ports = golden_ports(mod)
    used = [0] * len(rules)
    width = max(len(p) for p in ports)
    lines = []
    for p in ports:
        hits = [(k, re.fullmatch(pat, p)) for k, (pat, _) in enumerate(rules)]
        hits = [(k, m) for k, m in hits if m]
        if len(hits) != 1:
            raise SystemExit("gen_mmuleaf: %s.%s 被 %d 条规则认领（必须恰好 1）" % (mod, p, len(hits)))
        k, m = hits[0]
        used[k] += 1
        lines.append("%s  .%s (%s)" % (indent, p.ljust(width), rules[k][1].format(*m.groups())))
    for k, n in enumerate(used):
        if n == 0:
            raise SystemExit("gen_mmuleaf: %s 的规则 %r 一个端口也没认领（端口表变了？）" % (mod, rules[k][0]))
    return "%s%s %s (\n%s\n%s);" % (indent, mod, inst, ",\n".join(lines), indent)


def replace_region(text, tag, body):
    b = "// BEGIN GENERATED(%s) —— scripts/gen_mmuleaf.py\n" % tag
    pat = re.compile(r"([ \t]*)" + re.escape(b) + r".*?^([ \t]*)// END GENERATED\n", re.S | re.M)
    m = pat.search(text)
    if not m:
        raise SystemExit("gen_mmuleaf: 找不到生成区 %s" % tag)
    ind = m.group(1)
    new = ind + b + body + "\n" + ind + "// END GENERATED\n"
    return text[:m.start()] + new + text[m.end():]


def gen_prefetchfilter_rtl():
    path = os.path.join(REPO, "rtl", "memblock", "PrefetchFilter.sv")
    text = open(path).read()
    tlb = gen_inst("RRArbiterInit_5", "tlb_req_arb", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_(\d+)_ready", "tlb_arb_in_ready[{0}]"),
        (r"io_in_(\d+)_valid", "tlb_arb_in_valid[{0}]"),
        (r"io_in_(\d+)_bits_vaddr", "tlb_arb_in_vaddr[{0}]"),
        (r"io_out_valid", "tlb_arb_out_valid"),
        (r"io_out_bits_vaddr", "tlb_arb_out_vaddr"),
    ])
    pf = gen_inst("RRArbiterInit_6", "pf_req_arb", [
        (r"clock", "clock"),
        (r"reset", "reset"),
        (r"io_in_(\d+)_ready", "pf_arb_in_ready[{0}]"),
        (r"io_in_(\d+)_valid", "pf_arb_in_valid[{0}]"),
        (r"io_in_(\d+)_bits", "pf_arb_in_addr[{0}]"),
        (r"io_out_valid", "l2_pf_valid"),
        (r"io_out_bits", "l2_pf_addr"),
        (r"io_chosen", "pf_arb_chosen"),
    ])
    text = replace_region(text, "tlb_req_arb", tlb)
    text = replace_region(text, "pf_req_arb", pf)
    return path, text


def pf_rule(name):
    rules = [
        (r"entries_(\d+)_(region_tag|region_addr|region_bits|filter_bits|paddr_valid|decr_mode)",
         lambda m: ("entries[%s].%s" % (m[1], m[2]), "")),
        (r"valids_(\d+)", lambda m: ("valids", "[%s]" % m[1])),
        (r"(s[123])_tlb_fire_vec_r_r_(\d+)", lambda m: ("%s_tlb_fire_vec" % m[1], "[%s]" % m[2])),
        (r"state_reg", lambda m: ("u_plru/state_reg", "")),
        (r"(prev_\w+|s1_(?!tlb_fire_vec_r_r_)\w+|s3_tlb_resp_\w+)", lambda m: (m[1], "")),
    ]
    hits = []
    for pat, fn in rules:
        m = re.fullmatch(pat, name)
        if m:
            hits.append(fn(m))
    return hits


TARGETS = {
    # 目标名: (UT 目录, 规则函数, 打印前缀)
    "StreamBitVectorArray": ("StreamBitVectorArray", sbva_rule, "SBVA"),
    "PrefetchFilter":       ("PrefetchFilter", pf_rule, "PFF"),
}

RTL_GENERATORS = [gen_prefetchfilter_rtl]


def gen_pins(top, rule, tag):
    regs = golden_top_regs(top)
    total = sum(w for _, w in regs)
    seen = set()
    o = []
    o.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）" % top)
    o.append("#")
    o.append("# 只消 golden 展平寄存器名与重写核 generate 块/数组/语义名之间的命名鸿沟（规则见生成器）。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。")
    o.append("# 进 fm.log 的输出一律 ASCII。")
    o.append("set ::%s_PIN_EXPECT %d" % (tag, total))
    o.append("set ::%s_PIN_OK 0" % tag)
    o.append("set ::%s_PIN_BAD 0" % tag)
    o.append("proc %s_pin {g i w} {" % tag.lower())
    o.append("  if {$w == 1} {")
    o.append("    set pairs [list \"r:/WORK/%s/${g}_reg\" \"i:/WORK/%s/u_core/${i}\"]" % (top, top))
    o.append("  } else {")
    o.append("    set pairs {}")
    o.append("    for {set b 0} {$b < $w} {incr b} {")
    o.append("      lappend pairs \"r:/WORK/%s/${g}_reg\\[$b\\]\" \"i:/WORK/%s/u_core/${i}\\[$b\\]\"" % (top, top))
    o.append("    }")
    o.append("  }")
    o.append("  foreach {r m} $pairs {")
    o.append("    if {[set_user_match $r $m]} { incr ::%s_PIN_OK } else {" % tag)
    o.append("      incr ::%s_PIN_BAD" % tag)
    o.append("      if {$::%s_PIN_BAD <= 10} { puts \"%s_PIN_FAIL: $r <-> $m\" }" % (tag, tag))
    o.append("    }")
    o.append("  }")
    o.append("}")
    o.append("puts \"%s_PIN_BEGIN %s expect=$::%s_PIN_EXPECT\"" % (tag, top, tag))
    for n, w in regs:
        hits = rule(n)
        if len(hits) != 1:
            raise SystemExit("gen_mmuleaf: %s 的钉点规则对 golden 寄存器 %s 命中 %d 条（必须恰好 1）"
                             % (top, n, len(hits)))
        base, idx = hits[0]
        key = base + idx
        if key in seen:
            raise SystemExit("gen_mmuleaf: %s 两个 golden 寄存器映射到同一个重写寄存器 %s（不是双射）" % (top, key))
        seen.add(key)
        o.append("%s_pin %s %s %d" % (tag.lower(), n, esc(base + "_reg" + idx), w))
    o.append("puts \"%s_PIN_END %s ok=$::%s_PIN_OK bad=$::%s_PIN_BAD\"" % (tag, top, tag, tag))
    o.append("if {$::%s_PIN_BAD != 0} { error \"%s_PIN_MISS=$::%s_PIN_BAD\" }" % (tag, tag, tag))
    o.append("if {$::%s_PIN_OK != %d} { error \"%s_PIN_COUNT=$::%s_PIN_OK expect=%d\" }"
             % (tag, total, tag, tag, total))
    return "\n".join(o) + "\n"


def targets():
    out = {}
    for top, (ut, rule, tag) in TARGETS.items():
        out[os.path.join(REPO, "verif", "ut", ut, "fm_pins_pre.tcl")] = gen_pins(top, rule, tag)
    for g in RTL_GENERATORS:
        path, text = g()
        out[path] = text
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = open(path).read() if os.path.exists(path) else None
        if cur == text:
            print("gen_mmuleaf: OK     %s" % os.path.relpath(path, REPO))
            continue
        if args.check:
            print("gen_mmuleaf: DRIFT  %s" % os.path.relpath(path, REPO))
            drift += 1
        else:
            with open(path, "w") as f:
                f.write(text)
            print("gen_mmuleaf: WROTE  %s" % os.path.relpath(path, REPO))
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
