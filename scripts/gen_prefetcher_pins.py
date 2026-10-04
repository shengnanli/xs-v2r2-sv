#!/usr/bin/env python3
"""gen_prefetcher_pins.py —— Prefetcher 的 FM「匹配前」钉点生成器（verif/ut/Prefetcher/fm_pins_pre.tcl）。

Prefetcher 例化 pbop（PBestOffsetPrefetch）与 vbop（VBestOffsetPrefetch），两侧白盒。这两个 child 单独签核时
各有一批"本层无读者、golden 扁平名 vs 重写数组名、FM 按名配不上"的寄存器位，靠 scripts/gen_l2mp_pins.py 的
规则逐位钉配（PBOP 353 位、VBOP 531 位，依据见该脚本文件头）。放进 Prefetcher 之后这批位仍然无读者
（Prefetcher 不读 child 内部），对象不变，只是路径多一层实例名 pbop/ 或 vbop/。
这 884 位**不另立规则**：直接取 gen_l2mp_pins.TARGETS 的规则与它的 golden 寄存器表，逐条加实例前缀。

另有 76 位是 Prefetcher 这一层才出现的无读者寄存器（lane 内 diagnostic-full 诊断跑实测：两侧各 76 位
"Unmatched unread"，名字不同、结构相同），规则见 EXTRA：
  * Prefetcher 自己的 recv_addr 两级延迟寄存器（golden pfRcv_io_recv_addr_d_addr / _d_1_addr，重写核
    u_core/recvAddr_addr_d1 / _d2）的 [5:0] 与 [63:48]：PrefetchReceiver 只取地址 [47:6]（48 位物理地址的块地址），
    块内偏移与高 16 位无读者。2 × 22 = 44 位。
  * pftQueue（PrefetchQueue）的 valids_0..30（重写 u_core/queue_valid_reg[0..30]）：Chisel 的 empty/full 只读
    valids.last；其余 31 位唯一的读者是自己的次态（与 PrefetchQueue 单独签核时同一批，见
    verif/fm_target_config/PrefetchQueue.tcl）。31 位。
  * mbistPl（MbistPipeL2Prefetcher）的 beReg（重写 u_core/beReg_reg[0]）：它只驱动 toSRAM_0/1_wmask，一路接到
    pbop / vbop 的 rrTable 里 SRAMTemplate_146 的 boreChildrenBd_bore_wmask —— golden 在那里只赋给一根
    mbistBd_wmask 线，再无读者（RRT 是单路 SRAM，MBIST 写不用掩码）。1 位。

fail-closed：
  · 生成期：沿用 gen_l2mp_pins 的检查（每条规则至少命中一个 golden 寄存器、位在宽度内、映射单射、
    每个 child 的位数等于其字面期望）；EXTRA 的寄存器名与位宽从 golden 现读、位数等于字面 76；
    全体映射单射、总数等于字面 960；
  · 运行期：逐条数 set_user_match 返回值，拒一条或总数 != 960 即 error。

用法：python3 scripts/gen_prefetcher_pins.py          # 生成
      python3 scripts/gen_prefetcher_pins.py --check  # 与仓库里的文件逐字节比较，不一致 rc=1
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_l2mp_pins as base  # noqa: E402

REPO = os.path.dirname(HERE)
TOP = "Prefetcher"
CHILDREN = [("pbop", "PBestOffsetPrefetch"), ("vbop", "VBestOffsetPrefetch")]
EXPECT = 960

# 本层新出现的无读者位：(golden 模块, golden 寄存器名, ref 路径前缀, impl 元素模板（{b}=位）, 钉的位（None=1 位寄存器）)
EXTRA = [
    ("Prefetcher", "pfRcv_io_recv_addr_d_addr", "", "u_core/recvAddr_addr_d1_reg[{b}]",
     list(range(0, 6)) + list(range(48, 64))),
    ("Prefetcher", "pfRcv_io_recv_addr_d_1_addr", "", "u_core/recvAddr_addr_d2_reg[{b}]",
     list(range(0, 6)) + list(range(48, 64))),
] + [("PrefetchQueue", "valids_%d" % k, "pftQueue/", "pftQueue/u_core/queue_valid_reg[%d]" % k, None)
     for k in range(31)] + [
    ("MbistPipeL2Prefetcher", "beReg", "mbistPl/", "mbistPl/u_core/beReg_reg[0]", None),
]
EXTRA_EXPECT = 76


def die(msg):
    raise SystemExit("gen_prefetcher_pins: " + msg)


def child_pairs(child):
    """与 gen_l2mp_pins.build() 同一算法，返回 [(ref 相对 child, impl 相对 child)]。"""
    expect, rules = base.TARGETS[child]
    pairs = []
    seen_r, seen_i = set(), set()
    for inst, mod, pat, tmpl, bits in rules:
        regs = base.golden_regs(mod)
        hit = 0
        for name in sorted(regs, key=lambda n: [int(x) if x.isdigit() else x for x in base.re.split(r"(\d+)", n)]):
            m = base.re.fullmatch(pat, name)
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
            die("%s: 规则 %s/%s 一个 golden 寄存器都没命中" % (child, mod, pat))
    if len(pairs) != expect:
        die("%s: 钉点 %d 位，字面期望 %d" % (child, len(pairs), expect))
    return pairs


def extra_pairs():
    pairs = []
    for mod, name, rpre, itmpl, bits in EXTRA:
        regs = base.golden_regs(mod)
        if name not in regs:
            die("golden %s 里没有寄存器 %s" % (mod, name))
        w = regs[name]
        if bits is None:
            if w != 1:
                die("%s.%s 宽 %d，规则按 1 位钉" % (mod, name, w))
            pairs.append(("%s%s_reg" % (rpre, name), itmpl))
        else:
            if max(bits) >= w:
                die("%s.%s 宽 %d，规则要钉到位 %d" % (mod, name, w, max(bits)))
            pairs += [("%s%s_reg[%d]" % (rpre, name, b), itmpl.format(b=b)) for b in bits]
    if len(pairs) != EXTRA_EXPECT:
        die("本层钉点 %d 位，字面期望 %d" % (len(pairs), EXTRA_EXPECT))
    # PrefetchQueue 的 valids 必须恰好 32 个（最后一个 valids_31 有读者，不钉）
    if "valids_31" not in base.golden_regs("PrefetchQueue") or "valids_32" in base.golden_regs("PrefetchQueue"):
        die("golden PrefetchQueue 的 valids 个数不是 32")
    return pairs


def build():
    pairs = []
    for inst, child in CHILDREN:
        pairs += [("%s/%s" % (inst, r), "%s/%s" % (inst, i)) for r, i in child_pairs(child)]
    pairs += extra_pairs()
    if len({r for r, _ in pairs}) != len(pairs) or len({i for _, i in pairs}) != len(pairs):
        die("映射不单射")
    if len(pairs) != EXPECT:
        die("钉点 %d 位，字面期望 %d" % (len(pairs), EXPECT))
    o = []
    o.append("# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_prefetcher_pins.py（勿手改）" % TOP)
    o.append("#")
    o.append("# 两侧对称的无读者寄存器位：pbop / vbop 内部 884 位（规则即 scripts/gen_l2mp_pins.py 的 PBOP 353 + VBOP 531，")
    o.append("# 本层只加实例前缀）+ 本层新出现的 76 位（recv_addr 延迟寄存器 44 / pftQueue valids 31 / mbistPl beReg 1）。")
    o.append("# FM 按名配不上（Unmatched unread），不钉则 vmucp 空转。set_user_match 只声明对应，比较照比。")
    o.append("# fail-closed：逐条数返回值，拒一条或总数 != %d 即 error。进 fm.log 的输出一律 ASCII。" % EXPECT)
    o.append("set ::PFT_PIN_EXPECT %d" % EXPECT)
    o.append("set ::PFT_PIN_OK 0")
    o.append("set ::PFT_PIN_BAD 0")
    o.append("proc pft_pin {r i} {")
    o.append("  if {[set_user_match \"r:/WORK/%s/$r\" \"i:/WORK/%s/$i\"]} { incr ::PFT_PIN_OK } else {" % (TOP, TOP))
    o.append("    incr ::PFT_PIN_BAD")
    o.append("    if {$::PFT_PIN_BAD <= 10} { puts \"PFT_PIN_FAIL: $r <-> $i\" }")
    o.append("  }")
    o.append("}")
    o.append("puts \"PFT_PIN_BEGIN %s expect=$::PFT_PIN_EXPECT\"" % TOP)
    for r, i in pairs:
        o.append("pft_pin {%s} {%s}" % (r, i))
    o.append("puts \"PFT_PIN_END %s ok=$::PFT_PIN_OK bad=$::PFT_PIN_BAD\"" % TOP)
    o.append("if {$::PFT_PIN_BAD != 0} { error \"PFT_PIN_MISS=$::PFT_PIN_BAD\" }")
    o.append("if {$::PFT_PIN_OK != %d} { error \"PFT_PIN_COUNT=$::PFT_PIN_OK expect=%d\" }" % (EXPECT, EXPECT))
    return "\n".join(o) + "\n"


def main():
    path = os.path.join(REPO, "verif", "ut", TOP, "fm_pins_pre.tcl")
    txt = build()
    if "--check" in sys.argv[1:]:
        ok = os.path.exists(path) and open(path).read() == txt
        print(("OK: " if ok else "DRIFT: ") + path)
        return 0 if ok else 1
    if not os.path.exists(path) or open(path).read() != txt:
        open(path, "w").write(txt)
    print("wrote " + path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
