#!/usr/bin/env python3
"""derive_ut_impl.py —— 从单文件重写源派生 UT 侧 _xs 副本。

单文件规范下，重写文件内含与 golden 同名的 wrapper 模块（如 WrBypass），
UT 双例化要把重写文件与 golden 文件编进同一 elaboration，同名模块会冲突。
本脚本把输入文件中所有**不以 xs_ 开头**的模块声明改名为 <name>_xs，并同步
替换文件集内对这些名字的引用（例化/注释），输出到指定目录。xs_ 前缀的核与
辅助件保持原名（golden 里没有同名者）。

用法: derive_ut_impl.py --out <dir> <file.sv> [file2.sv ...]
输出: <dir>/<原文件名>（内容改名后），并打印派生映射。
"""
import argparse
import pathlib
import re
import sys

MODULE_DECL_RE = re.compile(r'^\s*module\s+([A-Za-z_]\w*)', re.MULTILINE)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('srcs', nargs='+')
    args = ap.parse_args()

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    texts = {}
    renames = {}
    for src in args.srcs:
        p = pathlib.Path(src)
        text = p.read_text()
        texts[p.name] = text
        for name in MODULE_DECL_RE.findall(text):
            if not name.startswith('xs_'):
                renames[name] = name + '_xs'

    # 长名优先替换，防止 WrBypass 抢先命中 WrBypass_32 的前缀
    # （\b 本已避免，此处双保险）。
    patterns = [(re.compile(r'\b' + re.escape(old) + r'\b'), new)
                for old, new in sorted(renames.items(), key=lambda kv: -len(kv[0]))]

    for fname, text in texts.items():
        for pat, new in patterns:
            text = pat.sub(new, text)
        # 幂等写入：内容不变就不动文件，避免每次 derive 都让 simv 判过期重链。
        dst = out_dir / fname
        if not dst.exists() or dst.read_text() != text:
            dst.write_text(text)

    for old, new in sorted(renames.items()):
        print(f'derive_ut_impl: {old} -> {new}')
    if not renames:
        print('derive_ut_impl: 无需改名（全部模块已是 xs_ 前缀）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
