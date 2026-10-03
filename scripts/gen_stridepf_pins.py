#!/usr/bin/env python3
"""gen_stridepf_pins.py —— StridePF 的 FM「匹配前」钉点生成器（verif/ut/StridePF/fm_pins_pre.tcl）。

为什么需要：本配置下 golden StridePF 没有任何输出端口（stride_en=0、s2_gen_req 未接，整条预取生成
通路被 firtool 裁掉），FM 的比较点只剩 220 个寄存器，且它们**全部是 unread**。不开 vmucp 时
passing = 0（证明是空的）；开 vmucp 也只能比"已配对"的 unread 点，而 golden 扁平名
（valids_3、entries_pc_7、s1_match_vec_12、state_reg …）与核里的数组名
（u_core/ent_valid[3]、u_core/ent_pc[7]、u_core/s1_match[12]、u_core/u_plru/state_reg …）
FM 按名只配上 prev_pc 的 10 位，其余 210 位必须钉。

钉点只声明"这两个点是同一个点"，比较照比：不约束 ref、不改 appvar、不加黑盒。
fail-closed：golden 每个寄存器必须恰好命中一条规则（含"按名自动配对、不钉"这条），
否则生成失败；运行期逐条数 set_user_match 返回值，拒一条或总数 != 字面期望就 error。

用法：python3 scripts/gen_stridepf_pins.py          # 生成
      python3 scripts/gen_stridepf_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
OUT = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "StridePF", "fm_pins_pre.tcl"))
TOP = "StridePF"
EXPECT_REG_BITS = 220      # golden StridePF 的寄存器位数总和（模型同 fm_predict）
EXPECT_PINS = 210          # 其中需要钉的位数；剩下 10 位（prev_pc）按名自动配上

# golden 寄存器名 -> (impl 元素表达式 或 None=按名自动配对不钉)
RULES = [
    (r"prev_valid_last_REG", lambda m: "u_core/prev_valid_reg"),
    (r"prev_pc",             lambda m: None),
    (r"state_reg",           lambda m: "u_core/u_plru/state_reg_reg"),
    (r"valids_(\d+)",        lambda m: "u_core/ent_valid_reg[%s]" % m[1]),
    (r"entries_pc_(\d+)",    lambda m: "u_core/ent_pc_reg[%s]" % m[1]),
    (r"s1_hit_last_REG",     lambda m: "u_core/s1_hit_q_reg"),
    (r"s1_alloc_last_REG",   lambda m: "u_core/s1_alloc_q_reg"),
    (r"s1_match_vec_(\d+)",  lambda m: "u_core/s1_match_reg[%s]" % m[1]),
]


def golden_regs():
    src = open(os.path.join(GOLDEN, TOP + ".sv")).read()
    body = src[src.index("module %s(" % TOP):]
    regs = []
    for m in re.finditer(r"^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);", body, re.M):
        regs.append((m.group(2), int(m.group(1)) + 1 if m.group(1) else 1))
    return regs


def build():
    regs = golden_regs()
    total = sum(w for _, w in regs)
    if total != EXPECT_REG_BITS:
        sys.exit("gen_stridepf_pins: golden 寄存器位数 %d != 期望 %d" % (total, EXPECT_REG_BITS))
    lines, seen, npins = [], set(), 0
    for name, w in regs:
        hits = [(pat, f) for pat, f in RULES if re.fullmatch(pat, name)]
        if len(hits) != 1:
            sys.exit("gen_stridepf_pins: %s 命中 %d 条规则（必须恰好 1 条）" % (name, len(hits)))
        tgt = hits[0][1](re.fullmatch(hits[0][0], name))
        if tgt is None:
            continue
        if tgt in seen:
            sys.exit("gen_stridepf_pins: 映射不是单射：%s" % tgt)
        seen.add(tgt)
        lines.append("stridepf_pin %s %s %d" % (name, tgt.replace("[", "\\[").replace("]", "\\]"), w))
        npins += w
    if npins != EXPECT_PINS:
        sys.exit("gen_stridepf_pins: 钉点位数 %d != 期望 %d" % (npins, EXPECT_PINS))
    head = """# StridePF FM「匹配前」钉点 —— 自动生成：scripts/gen_stridepf_pins.py（勿手改）
#
# golden 无输出端口，比较点全是寄存器（全 unread，靠 vmucp 比较），故全部寄存器必须配对。
# 只消扁平名与数组名的命名差：set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != %d 即 error。prev_pc 10 位按名自动配对，不钉。
# 进 fm.log 的输出一律 ASCII。
set ::SPF_PIN_EXPECT %d
set ::SPF_PIN_OK 0
set ::SPF_PIN_BAD 0
proc stridepf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/%s/${g}_reg" "i:/WORK/%s/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/%s/${g}_reg\\[$b\\]" "i:/WORK/%s/${i}\\[$b\\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::SPF_PIN_OK } else {
      incr ::SPF_PIN_BAD
      if {$::SPF_PIN_BAD <= 10} { puts "SPF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "SPF_PIN_BEGIN %s expect=$::SPF_PIN_EXPECT"
""" % (EXPECT_PINS, EXPECT_PINS, TOP, TOP, TOP, TOP, TOP)
    tail = """puts "SPF_PIN_END %s ok=$::SPF_PIN_OK bad=$::SPF_PIN_BAD"
if {$::SPF_PIN_BAD != 0} { error "SPF_PIN_MISS=$::SPF_PIN_BAD" }
if {$::SPF_PIN_OK != %d} { error "SPF_PIN_COUNT=$::SPF_PIN_OK expect=%d" }
""" % (TOP, EXPECT_PINS, EXPECT_PINS)
    return head + "\n".join(lines) + "\n" + tail


def main():
    text = build()
    if "--check" in sys.argv[1:]:
        cur = open(OUT).read() if os.path.exists(OUT) else None
        if cur != text:
            print("gen_stridepf_pins --check: %s 与生成结果不一致" % OUT)
            return 1
        print("gen_stridepf_pins --check: OK")
        return 0
    with open(OUT, "w") as f:
        f.write(text)
    print("gen_stridepf_pins: 写出 %s（%d 位钉点）" % (OUT, EXPECT_PINS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
