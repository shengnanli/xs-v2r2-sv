#!/usr/bin/env python3
"""check_pin_bijection.py —— 核对 verif/ut/Composer/fm_pins_pre.tcl 钉的 601 对
与 FM 实测的「Composer 本层未读点」集合**精确相等**（无多、无缺）。

为什么需要这道核对
------------------
fm_pins_pre.tcl 自带 fail-closed：钉不上任何一条就 error 退出。但"每一条都钉上了"
只证明这些对象**存在**，不证明它们正好就是卡住证明的那批未读点：
  · 多钉 —— 把本来 FM 自己配好的点重新绑走，可能把别的配对搅乱；
  · 漏钉 —— 剩下的未读点继续拦着 strict，判定还是 PARTIAL。
两种错那道闸都抓不到，所以判据必须是**集合相等**。

"Composer 本层未读点"怎么数
---------------------------
输入是钉点**之前**那次 strict 跑出的 fm_work/Composer/unread_points.txt，它有三类行：
    ref\\t<路径>            两侧没配上、只在 golden 侧的未读点
    impl\\t<路径>           两侧没配上、只在可读核侧的未读点
    matched_nc\\t<ref> <impl>  已配上但不比对（Not-Compared）的未读点对
Composer 的 5 个预测器子模块与 4 个 DelayN 两侧同源用 golden（见 UT Makefile 的
RTL_GOLDEN_DEPS），它们内部的未读点 ref/impl **层次路径逐字相同**——那批是按构造
对称的，不需要钉。需要钉的正是剩下的：两侧路径不同的 matched_nc，加上两侧都没
配上的 ref/impl。本脚本就按这个定义取"观测集合"，再与生成集合比。

★为什么要连"FM 自己已经配上的"一起钉★（2026-09-14 实测）
    不加强时 s1_pc/modified_reset 是 matched unread（FM 自己配上了），只有 s2/s3
    的 400 点是 unmatched。但一旦打开 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS，
    未读点升级成比对点，s1_pc 那 200 点的配对**掉了**，变成新的 200(200)
    unmatched unread（实测 compare points 526085、判定仍 PARTIAL）。
    所以判据取的是"整条影子流水"，不是"当前恰好报出来没配上的那一批"。

用法: check_pin_bijection.py <unread_points.txt>
"""
import sys

TOP = "Composer"
# 段布局：与 golden Composer.sv 的段声明、fm_pins_pre.tcl 的 _segs 表逐字对应。
#   seg_0 = pc[49:24] 26 位 -> 可读核 hi ; seg_1 = pc[23:12] 12 位 -> mid
#   seg_2 = pc[11:0]  12 位 -> lo
SEGS = [(0, "hi", 26), (1, "mid", 12), (2, "lo", 12)]
NUM_DUP = 4
PC_W = 50


def generated_pairs():
    """与 fm_pins_pre.tcl 同一张表生成的 601 对 (ref, impl)。"""
    pairs = [(f"r:/WORK/{TOP}/modified_reset_reg",
              f"i:/WORK/{TOP}/u_core/modified_reset_reg")]
    for d in range(NUM_DUP):
        for b in range(PC_W):
            pairs.append((f"r:/WORK/{TOP}/s1_pc_dup_{d}_reg[{b}]",
                          f"i:/WORK/{TOP}/u_core/s1_pc_reg[{d}][{b}]"))
    for st in (2, 3):
        for d in range(NUM_DUP):
            sfx = "" if d == 0 else f"_{d}"      # firtool: dup0 无后缀
            for si, sname, w in SEGS:
                for b in range(w):
                    pairs.append((
                        f"r:/WORK/{TOP}/s{st}_pc_dup_s{st}_pc_seg_{si}_value{sfx}_reg[{b}]",
                        f"i:/WORK/{TOP}/u_core/s{st}_pc_{sname}_reg[{d}][{b}]"))
    return pairs


def _tcl_pair(s):
    """matched_nc 行是一个两元素 Tcl 列表，元素可能被 {} 包起来。"""
    toks, i = [], 0
    while i < len(s):
        if s[i] == " ":
            i += 1
        elif s[i] == "{":
            j = s.index("}", i)
            toks.append(s[i + 1:j])
            i = j + 1
        else:
            j = s.find(" ", i)
            j = len(s) if j < 0 else j
            toks.append(s[i:j])
            i = j
    return toks


def observed(path):
    """返回 (ref 集合, impl 集合, 两侧路径不同的 matched_nc 对, 路径相同的条数)。"""
    ref, impl, nonid, ident = set(), set(), set(), 0
    with open(path) as f:
        for ln in f:
            if "\t" not in ln:
                continue
            kind, rest = ln.rstrip("\n").split("\t", 1)
            if kind == "ref":
                ref.add(rest)
            elif kind == "impl":
                impl.add(rest)
            elif kind == "matched_nc":
                t = _tcl_pair(rest)
                if len(t) != 2:
                    raise SystemExit(f"无法解析 matched_nc 行: {rest}")
                r, i = t
                if r[2:] == i[2:]:          # 去掉 r:/i: 前缀后逐字相同
                    ident += 1
                else:
                    nonid.add((r, i))
                    ref.add(r)
                    impl.add(i)
    return ref, impl, nonid, ident


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    pairs = generated_pairs()
    gen_ref = {r for r, _ in pairs}
    gen_impl = {i for _, i in pairs}
    if len(gen_ref) != len(pairs) or len(gen_impl) != len(pairs):
        print("FAIL 生成集合内部有重复路径 —— 不是双射")
        return 1
    obs_ref, obs_impl, nonid, ident = observed(sys.argv[1])
    print(f"输入: {sys.argv[1]}")
    print(f"     两侧路径逐字相同的 matched_nc（子模块内部，按构造对称，不钉）: {ident}")
    bad = 0
    for side, gen, obs in (("ref", gen_ref, obs_ref), ("impl", gen_impl, obs_impl)):
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
            print(f"ok   {side}: {len(gen)} 条，与实测 Composer 本层未读点集合精确相等")
    # FM 自己已经配好的那些对，配法必须与本脚本/钉点文件一致，否则"钉"会改变配对语义
    wrong = sorted(nonid - set(pairs))
    if wrong:
        bad += 1
        print(f"FAIL FM 已有配对与生成配对不一致 {len(wrong)} 对：")
        for r, i in wrong[:5]:
            print(f"      {r} <-> {i}")
    else:
        print(f"ok   FM 已有的 {len(nonid)} 对非同路径配对与生成配对逐对一致")
    if bad:
        print("=== 钉点集合与实测未读点不一致 —— 双射主张不成立 ===")
        return 1
    print(f"=== {len(pairs)}<->{len(pairs)} 严格双射：两侧集合各自精确相等 ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
