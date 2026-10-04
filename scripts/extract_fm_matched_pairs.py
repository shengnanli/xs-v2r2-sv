#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""extract_fm_matched_pairs.py —— 从一次 FM 跑的 matched.rpt 抽出"两侧名字不同"的寄存器配对，存成父级钉点的输入数据。

用途：父级（Composer）把子模块（FauFTB / Tage_SC / ITTage）两侧白盒展开后，规模太大，FM 的签名分析在子模块内部
那些对称结构（WrBypass CAM、FauFTB 32 路、SRAM 包装）上配不全（实测 Composer 诊断跑 18136 个 unmatched compare point）。
而同一份重写件在子模块**自己的**证明里，FM 已经把这些寄存器逐个配好了（signoff-strict SUCCEEDED / PASS_DEAD_REF）。
本脚本把子模块自证时 FM 自己给出的配对（只取寄存器类：DFF* / LAT*，且 ref 与 impl 的相对路径不同的那些）原样抽出，
父级钉点生成器（scripts/gen_bpu_stagepc_pins.py）加上实例前缀后 set_user_match —— 只消名差，配对本身是 FM 的结论，不是人工指定。

输入必须是**与 receipt 同字节**的那次子模块 FM 跑（调用者负责）；输出头部记录来源 commit 与 matched.rpt 的 sha256。
用法：extract_fm_matched_pairs.py <matched.rpt> <top> <commit> <out.tsv>
输出：每行 "<ref 相对路径>\\t<impl 相对路径>"（相对 r:/WORK/<top>/ 与 i:/WORK/<top>/），按 ref 排序。
"""
import hashlib
import re
import sys


def main():
    rpt, top, commit, out = sys.argv[1:5]
    raw = open(rpt, "rb").read()
    lines = raw.decode(errors="replace").splitlines()
    pairs = []
    i = 0
    rx_ref = re.compile(r"^\s+Ref\s+(\S+)\s+\S+\s+r:/WORK/%s/(\S+)$" % re.escape(top))
    rx_imp = re.compile(r"^\s+Impl\s+(\S+)\s+\S+\s+i:/WORK/%s/(\S+)$" % re.escape(top))
    while i < len(lines):
        m = rx_ref.match(lines[i])
        if m and i + 1 < len(lines):
            n = rx_imp.match(lines[i + 1])
            if not n:
                sys.exit("配对格式异常（Ref 后不是 Impl）：行 %d" % (i + 1))
            if (m.group(1).startswith(("DFF", "LAT")) and n.group(1).startswith(("DFF", "LAT"))
                    and m.group(2) != n.group(2)):
                pairs.append((m.group(2), n.group(2)))
            i += 2
            continue
        i += 1
    refs = [r for r, _ in pairs]
    imps = [x for _, x in pairs]
    if len(set(refs)) != len(refs) or len(set(imps)) != len(imps):
        sys.exit("配对不是单射（matched.rpt 里有一对多）")
    pairs.sort()
    with open(out, "w") as f:
        f.write("# source: FM matched.rpt of %s @ %s sha256=%s ; pairs=%d (scripts/extract_fm_matched_pairs.py)\n"
                % (top, commit, hashlib.sha256(raw).hexdigest(), len(pairs)))
        for r, x in pairs:
            f.write("%s\t%s\n" % (r, x))
    print("%s: %d pairs -> %s" % (top, len(pairs), out))


if __name__ == "__main__":
    main()
