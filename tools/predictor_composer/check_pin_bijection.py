#!/usr/bin/env python3
"""check_pin_bijection.py —— 核对 verif/ut/Composer/fm_pins_pre.tcl 钉的 400 对
与 FM 实测的 unmatched unread 点集合**精确相等**（无多、无缺）。

为什么需要这道核对：fm_pins_pre.tcl 里的 400 对是按段布局机械生成的，它自带
fail-closed（钉不上就 error 退出）。但"每一条都钉上了"只证明这些对象存在，
**不证明它们正好就是卡住证明的那批未读点**——多钉（把本来配好的点重新绑走）
或少钉（剩下的未读点继续拦着 strict）都不会被那道闸抓到。

所以判据必须是集合相等：
    生成的 400 条 ref 路径 == FM 报的 ref 侧 unmatched unread 全集
    生成的 400 条 impl 路径 == FM 报的 impl 侧 unmatched unread 全集
两侧都相等，才谈得上 400<->400 的严格双射。

输入 = 钉点**之前**那次 strict 跑出的 fm_work/Composer/unread_points.txt
（或证据目录里的同名文件）。钉点之后这 400 点会变成 matched_nc，不再出现在
ref/impl 两类里，本脚本要的是钉点前的那一份。

用法: check_pin_bijection.py <unread_points.txt>
"""
import sys

# 段布局：与 golden Composer.sv 的段声明、fm_pins_pre.tcl 的 _segs 表逐字对应。
#   seg_0 = pc[49:24] 26 位 -> 可读核 hi ; seg_1 = pc[23:12] 12 位 -> mid
#   seg_2 = pc[11:0]  12 位 -> lo
SEGS = [(0, "hi", 26), (1, "mid", 12), (2, "lo", 12)]
NUM_DUP = 4
STAGES = (2, 3)


def generated(top="Composer"):
    ref, impl = set(), set()
    for st in STAGES:
        for d in range(NUM_DUP):
            sfx = "" if d == 0 else f"_{d}"          # firtool: dup0 无后缀
            for si, sname, w in SEGS:
                for b in range(w):
                    ref.add(f"r:/WORK/{top}/s{st}_pc_dup_s{st}_pc_seg_{si}_value{sfx}_reg[{b}]")
                    impl.add(f"i:/WORK/{top}/u_core/s{st}_pc_{sname}_reg[{d}][{b}]")
    return ref, impl


def observed(path):
    ref, impl = set(), set()
    with open(path) as f:
        for ln in f:
            if "\t" not in ln:
                continue
            kind, p = ln.rstrip("\n").split("\t", 1)
            if kind == "ref":
                ref.add(p)
            elif kind == "impl":
                impl.add(p)
    return ref, impl


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    gr, gi = generated()
    orf, oi = observed(sys.argv[1])
    bad = 0
    for side, gen, obs in (("ref", gr, orf), ("impl", gi, oi)):
        extra, missing = sorted(gen - obs), sorted(obs - gen)
        if extra or missing:
            bad += 1
            print(f"FAIL {side}: 生成 {len(gen)} / 实测 {len(obs)}；"
                  f"多钉 {len(extra)}、漏钉 {len(missing)}")
            for x in extra[:5]:
                print(f"      多: {x}")
            for x in missing[:5]:
                print(f"      漏: {x}")
        else:
            print(f"ok   {side}: {len(gen)} 条，与实测 unmatched unread 集合精确相等")
    if bad:
        print("=== 钉点集合与实测未读点不一致 —— 双射主张不成立 ===")
        return 1
    print("=== 400<->400 严格双射：两侧集合各自精确相等 ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
