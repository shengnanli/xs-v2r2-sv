#!/usr/bin/env python3
"""gen_l2mp_pins.py —— l2-mem-parents lane 的 FM「匹配前」钉点生成器（verif/ut/<T>/fm_pins_pre.tcl）。

PBestOffsetPrefetch / VBestOffsetPrefetch 两个父级里，child 内部有一批寄存器位在**父级上下文里**没有读者
（child 单独签核时它们连到 child 输出口、是活的）。golden 与重写两侧结构相同，FM 按名配不上
（golden 扁平名 vs 重写数组名），于是成了两侧对称的 "Unmatched unread"——vmucp 只比较已配对的 unread 点，
不钉就空转。实测（lane 内 diagnostic-full 诊断跑，未出证）：
  delayQueue（DelayQueue / _1）的 16 项 queue_<k>_addrNoOffset 高位：RecentRequestTable 只读写口地址的
      io_w_bits[25:6]（setIdx = [13:6]^[21:14]，tag = [25:14]），即 addrNoOffset[19:0]；
      [41:20]（PBOP，42 位）/ [43:20]（VBOP，44 位）无读者。PBOP 352 位、VBOP 384 位。
  rrTable（RecentRequestTable / _1）的 REG：Scala assert(!RegNext(w.fire && r.req.fire)) 的寄存器，
      唯一读者是 `ifndef SYNTHESIS 断言；重写核里同一个寄存器叫 rw_same_cycle_q（同 verif/ut/RecentRequestTable/fm_pins.tcl）。1 位。
  reqFilter（PrefetchReqBuffer，仅 VBOP）：与 PrefetchReqBuffer 单独签核时同一批 146 位
      （prev_in_req/s1_in_req 的 full_vaddr[5:0]、s3_tlb_resp_paddr_0[5:0]、16 项 paddrNoOffset[49:42]），
      规则同 scripts/gen_l1pf_pins.py，只是路径前缀多了实例名 reqFilter/。
钉点只声明"这两个点是同一个点"，比较照比：不约束 ref、不改 appvar、不加黑盒。

fail-closed：
  · 生成期：golden 寄存器名与位宽从 G1 golden child 源文件现读；每条规则至少命中一个寄存器、钉的位必须在
    寄存器位宽内、映射单射；钉点总位数必须等于字面期望。
  · 运行期：逐条数 set_user_match 返回值，拒一条或总数 != 字面期望即 error。

用法：python3 scripts/gen_l2mp_pins.py          # 生成全部
      python3 scripts/gen_l2mp_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

# 规则：(实例路径, golden child 模块, golden 寄存器名正则, impl 元素模板（\1 = 捕获组）, 钉的位（None=1 位寄存器）)
DQ_P = ("delayQueue", "DelayQueue", r"queue_(\d+)_addrNoOffset", r"delayQueue/u_core/queue_addr_reg[\1]", range(20, 42))
DQ_V = ("delayQueue", "DelayQueue_1", r"queue_(\d+)_addrNoOffset", r"delayQueue/u_core/queue_addr_reg[\1]", range(20, 44))
RRT_P = ("rrTable", "RecentRequestTable", r"REG", r"rrTable/u_core/rw_same_cycle_q_reg", None)
RRT_V = ("rrTable", "RecentRequestTable_1", r"REG", r"rrTable/u_core/rw_same_cycle_q_reg", None)
PRB = [
    ("reqFilter", "PrefetchReqBuffer", r"prev_in_req_full_vaddr", r"reqFilter/u_core/prev_in_full_vaddr_reg", range(0, 6)),
    ("reqFilter", "PrefetchReqBuffer", r"s1_in_req_full_vaddr", r"reqFilter/u_core/s1_in_full_vaddr_reg", range(0, 6)),
    ("reqFilter", "PrefetchReqBuffer", r"s3_tlb_resp_paddr_0", r"reqFilter/u_core/s3_tlb_resp_paddr_reg", range(0, 6)),
    ("reqFilter", "PrefetchReqBuffer", r"entries_(\d+)_paddrNoOffset", r"reqFilter/u_core/ent_paddrNoOffset_reg[\1]", range(42, 50)),
]
TARGETS = {
    "PBestOffsetPrefetch": (353, [DQ_P, RRT_P]),
    "VBestOffsetPrefetch": (531, [DQ_V, RRT_V] + PRB),
}


def die(msg):
    raise SystemExit("gen_l2mp_pins: " + msg)


def golden_regs(mod):
    t = open(os.path.join(GOLDEN, mod + ".sv")).read()
    i = t.index("\nmodule %s(" % mod)
    regs = {}
    for m in re.finditer(r"^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);", t[i:], re.M):
        regs[m.group(2)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    return regs


def build(top):
    expect, rules = TARGETS[top]
    pairs = []
    seen_r, seen_i = set(), set()
    for inst, mod, pat, tmpl, bits in rules:
        regs = golden_regs(mod)
        hit = 0
        for name in sorted(regs, key=lambda n: [int(x) if x.isdigit() else x for x in re.split(r"(\d+)", n)]):
            m = re.fullmatch(pat, name)
            if not m:
                continue
            hit += 1
            ielem = m.expand(tmpl)
            w = regs[name]
            if bits is None:
                if w != 1:
                    die("%s.%s 宽 %d，规则按 1 位钉" % (mod, name, w))
                plist = [("%s/%s_reg" % (inst, name), ielem)]
            else:
                if max(bits) >= w:
                    die("%s.%s 宽 %d，规则要钉到位 %d" % (mod, name, w, max(bits)))
                plist = [("%s/%s_reg[%d]" % (inst, name, b), "%s[%d]" % (ielem, b)) for b in bits]
            for r, i in plist:
                if r in seen_r or i in seen_i:
                    die("映射不单射：%s <-> %s" % (r, i))
                seen_r.add(r)
                seen_i.add(i)
                pairs.append((r, i))
        if hit == 0:
            die("%s: 规则 %s/%s 一个 golden 寄存器都没命中" % (top, mod, pat))
    if len(pairs) != expect:
        die("%s: 钉点 %d 位，字面期望 %d" % (top, len(pairs), expect))
    o = []
    o.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_l2mp_pins.py（勿手改）" % top)
    o.append("#")
    o.append("# 依据见生成器文件头与 verif/fm_target_config/%s.tcl：父级上下文里两侧对称的无读者寄存器位，" % top)
    o.append("# FM 按名配不上（Unmatched unread），不钉则 vmucp 空转。set_user_match 只声明对应，比较照比。")
    o.append("# fail-closed：逐条数返回值，拒一条或总数 != %d 即 error。进 fm.log 的输出一律 ASCII。" % expect)
    o.append("set ::L2MP_PIN_EXPECT %d" % expect)
    o.append("set ::L2MP_PIN_OK 0")
    o.append("set ::L2MP_PIN_BAD 0")
    o.append("proc l2mp_pin {r i} {")
    o.append("  if {[set_user_match \"r:/WORK/%s/$r\" \"i:/WORK/%s/$i\"]} { incr ::L2MP_PIN_OK } else {" % (top, top))
    o.append("    incr ::L2MP_PIN_BAD")
    o.append("    if {$::L2MP_PIN_BAD <= 10} { puts \"L2MP_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"L2MP_PIN_BEGIN %s expect=$::L2MP_PIN_EXPECT\"" % top)
    for r, i in pairs:
        o.append("l2mp_pin {%s} {%s}" % (r, i))
    o.append("puts \"L2MP_PIN_END %s ok=$::L2MP_PIN_OK bad=$::L2MP_PIN_BAD\"" % top)
    o.append("if {$::L2MP_PIN_BAD != 0} { error \"L2MP_PIN_MISS=$::L2MP_PIN_BAD\" }")
    o.append("if {$::L2MP_PIN_OK != %d} { error \"L2MP_PIN_COUNT=$::L2MP_PIN_OK expect=%d\" }" % (expect, expect))
    return "\n".join(o) + "\n"


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for top in TARGETS:
        path = os.path.join(REPO, "verif", "ut", top, "fm_pins_pre.tcl")
        txt = build(top)
        if check:
            ok = os.path.exists(path) and open(path).read() == txt
            print(("OK: " if ok else "DRIFT: ") + path)
            rc |= 0 if ok else 1
        else:
            if not os.path.exists(path) or open(path).read() != txt:
                open(path, "w").write(txt)
            print("wrote " + path)
    return rc


if __name__ == "__main__":
    sys.exit(main())
