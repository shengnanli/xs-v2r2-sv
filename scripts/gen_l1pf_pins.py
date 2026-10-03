#!/usr/bin/env python3
"""gen_l1pf_pins.py —— l1prefetch-tables lane 的 FM「匹配前」钉点生成器（verif/ut/<T>/fm_pins_pre.tcl）。

三个目标都有"FM 按名配不上、又全是 unread 的寄存器"：不钉，vmucp 也只能空转
（vmucp 只比较**已配对**的 unread 点；"Unmatched unread" 它管不到）。
  StridePF       golden 无输出端口（stride_en=0 / s2_gen_req 未接，整条预取通路被裁），220 位寄存器
                 全 unread；prev_pc 10 位按名配上，其余 210 位钉。不钉时证明是空的（0 比较点）。
  SMSTrainFilter 被裁 store 口留下的 3/4 号入队指针（8 位）：分配下标 PopCount ≤ 2，永不被读。
  PrefetchQueue  valids_0..30（31 位）：empty/full 只看 valids_31，其余 valid 位只喂自己的次态。
  PrefetchReqBuffer 146 位：prev_in_req/s1_in_req 的 full_vaddr[5:0] 与 s3_tlb_resp_paddr[5:0]（块内偏移，
                 只用 [..:6]），以及 16 项 paddrNoOffset[49:42]（PF tag 只取 [41:9]）。这些寄存器的其余位
                 FM 已按签名配上，所以只钉指定位（规则返回 (元素, 位列表)）。

钉点只声明"这两个点是同一个点"，比较照比：不约束 ref、不改 appvar、不加黑盒。
fail-closed：
  · 生成期：StridePF 要求 golden 每个寄存器恰好命中一条规则（含"按名配对、不钉"）；
    其余目标要求每条规则至少命中一个寄存器、映射单射；钉点总位数必须等于字面期望。
  · 运行期：逐条数 set_user_match 返回值，拒一条或总数 != 字面期望即 error。

用法：python3 scripts/gen_l1pf_pins.py          # 生成全部
      python3 scripts/gen_l1pf_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

# target -> (完整覆盖?, 期望 golden 寄存器位数(仅完整覆盖时核对), 期望钉点位数, 规则表)
# 规则：golden 寄存器名正则 -> impl 元素表达式（None = 按名自动配对、不钉）
TARGETS = {
    "StridePF": (True, 220, 210, [
        (r"prev_valid_last_REG", lambda m: "u_core/prev_valid_reg"),
        (r"prev_pc",             lambda m: None),
        (r"state_reg",           lambda m: "u_core/u_plru/state_reg_reg"),
        (r"valids_(\d+)",        lambda m: "u_core/ent_valid_reg[%s]" % m[1]),
        (r"entries_pc_(\d+)",    lambda m: "u_core/ent_pc_reg[%s]" % m[1]),
        (r"s1_hit_last_REG",     lambda m: "u_core/s1_hit_q_reg"),
        (r"s1_alloc_last_REG",   lambda m: "u_core/s1_alloc_q_reg"),
        (r"s1_match_vec_(\d+)",  lambda m: "u_core/s1_match_reg[%s]" % m[1]),
    ]),
    "SMSTrainFilter": (False, None, 8, [
        (r"enqPtrExt_([34])_flag",  lambda m: "u_core/enq_flag_reg[%s]" % m[1]),
        (r"enqPtrExt_([34])_value", lambda m: "u_core/enq_value_reg[%s]" % m[1]),
    ]),
    "PrefetchQueue": (False, None, 31, [
        (r"valids_(\d|[12]\d|30)", lambda m: "u_core/queue_valid_reg[%s]" % m[1]),
    ]),
    "PrefetchReqBuffer": (False, None, 146, [
        (r"prev_in_req_full_vaddr",       lambda m: ("u_core/prev_in_full_vaddr_reg", range(0, 6))),
        (r"s1_in_req_full_vaddr",         lambda m: ("u_core/s1_in_full_vaddr_reg", range(0, 6))),
        (r"s3_tlb_resp_paddr_0",          lambda m: ("u_core/s3_tlb_resp_paddr_reg", range(0, 6))),
        (r"entries_(\d+)_paddrNoOffset", lambda m: ("u_core/ent_paddrNoOffset_reg[%s]" % m[1], range(42, 50))),
    ]),
}


def out_path(top):
    return os.path.normpath(os.path.join(HERE, "..", "verif", "ut", top, "fm_pins_pre.tcl"))


def golden_regs(top):
    src = open(os.path.join(GOLDEN, top + ".sv")).read()
    body = src[src.index("module %s(" % top):]
    return [(m.group(2), int(m.group(1)) + 1 if m.group(1) else 1)
            for m in re.finditer(r"^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);", body, re.M)]


def build(top):
    full, expect_bits, expect_pins, rules = TARGETS[top]
    regs = golden_regs(top)
    if full and sum(w for _, w in regs) != expect_bits:
        sys.exit("gen_l1pf_pins[%s]: golden 寄存器位数 %d != 期望 %d" % (top, sum(w for _, w in regs), expect_bits))
    lines, seen, npins, used = [], set(), 0, set()
    for name, w in regs:
        hits = [(pat, f) for pat, f in rules if re.fullmatch(pat, name)]
        if len(hits) > 1 or (full and len(hits) != 1):
            sys.exit("gen_l1pf_pins[%s]: %s 命中 %d 条规则" % (top, name, len(hits)))
        if not hits:
            continue
        used.add(hits[0][0])
        tgt = hits[0][1](re.fullmatch(hits[0][0], name))
        if tgt is None:
            continue
        if isinstance(tgt, tuple):          # 只钉指定位
            tgt, bits = tgt[0], list(tgt[1])
            if not bits or max(bits) >= w:
                sys.exit("gen_l1pf_pins[%s]: %s 位列表越界（宽 %d）" % (top, name, w))
            partial = True
        else:
            bits, partial = None, False
        if tgt in seen:
            sys.exit("gen_l1pf_pins[%s]: 映射不是单射：%s" % (top, tgt))
        seen.add(tgt)
        esc = tgt.replace("[", "\\[").replace("]", "\\]")
        if partial:
            lines.append("l1pf_pin_bits %s %s {%s}" % (name, esc, " ".join(map(str, bits))))
            npins += len(bits)
        else:
            lines.append("l1pf_pin %s %s %d" % (name, esc, w))
            npins += w
    unused = [p for p, _ in rules if p not in used]
    if unused:
        sys.exit("gen_l1pf_pins[%s]: 规则没有命中任何寄存器：%s" % (top, unused))
    if npins != expect_pins:
        sys.exit("gen_l1pf_pins[%s]: 钉点位数 %d != 期望 %d" % (top, npins, expect_pins))
    head = """# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_l1pf_pins.py（勿手改）
#
# 依据见生成器文件头与 verif/fm_target_config/%s.tcl：这些寄存器 FM 按名配不上且全是 unread，
# 不钉则 vmucp 空转。set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != %d 即 error。进 fm.log 的输出一律 ASCII。
set ::L1PF_PIN_EXPECT %d
set ::L1PF_PIN_OK 0
set ::L1PF_PIN_BAD 0
proc l1pf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/%s/${g}_reg" "i:/WORK/%s/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/%s/${g}_reg\\[$b\\]" "i:/WORK/%s/${i}\\[$b\\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "L1PF_PIN_BEGIN %s expect=$::L1PF_PIN_EXPECT"
""" % (top, top, expect_pins, expect_pins, top, top, top, top, top)
    if any(l.startswith("l1pf_pin_bits ") for l in lines):
        head += """proc l1pf_pin_bits {g i bits} {
  foreach b $bits {
    set r "r:/WORK/%s/${g}_reg\\[$b\\]"
    set m "i:/WORK/%s/${i}\\[$b\\]"
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
""" % (top, top)
    tail = """puts "L1PF_PIN_END %s ok=$::L1PF_PIN_OK bad=$::L1PF_PIN_BAD"
if {$::L1PF_PIN_BAD != 0} { error "L1PF_PIN_MISS=$::L1PF_PIN_BAD" }
if {$::L1PF_PIN_OK != %d} { error "L1PF_PIN_COUNT=$::L1PF_PIN_OK expect=%d" }
""" % (top, expect_pins, expect_pins)
    return head + "\n".join(lines) + "\n" + tail


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for top in TARGETS:
        text, path = build(top), out_path(top)
        if check:
            cur = open(path).read() if os.path.exists(path) else None
            if cur != text:
                print("gen_l1pf_pins --check: %s 与生成结果不一致" % path)
                rc = 1
            continue
        with open(path, "w") as f:
            f.write(text)
        print("gen_l1pf_pins: 写出 %s（%d 位钉点）" % (path, TARGETS[top][2]))
    if check and rc == 0:
        print("gen_l1pf_pins --check: OK")
    return rc


if __name__ == "__main__":
    sys.exit(main())
