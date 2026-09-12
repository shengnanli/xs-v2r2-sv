#!/usr/bin/env python3
"""split_variants_file.py —— 把上轮的合并变体文件拆成单文件规范（一模块一文件）。

用法:
  split_variants_file.py <src.sv> --out <rtl子目录> [--rename OLD=NEW ...]
                         [--only NAME ...] [--skip NAME ...]

--rename 同时作用于模块自身名与文件内对该名的引用（G1 重编号：外层名与其例化的
内层名一并改）。拆出的每个模块写成 <新名>.sv，保留原文件头注释作为家族说明。
"""
import argparse
import pathlib
import re
import sys

MOD_RE = re.compile(r'^module\s+([A-Za-z_]\w*)', re.MULTILINE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('--out', required=True)
    ap.add_argument('--rename', nargs='*', default=[])
    ap.add_argument('--only', nargs='*', default=[])
    ap.add_argument('--skip', nargs='*', default=[])
    a = ap.parse_args()

    ren = dict(x.split('=', 1) for x in a.rename)
    text = pathlib.Path(a.src).read_text()
    starts = [(m.start(), m.group(1)) for m in MOD_RE.finditer(text)]
    if not starts:
        sys.exit('ERROR: 源文件无 module')
    header = text[:starts[0][0]].rstrip()
    out_dir = pathlib.Path(a.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    pats = [(re.compile(r'\b' + re.escape(o) + r'\b'), n)
            for o, n in sorted(ren.items(), key=lambda kv: -len(kv[0]))]

    written = []
    for i, (pos, name) in enumerate(starts):
        if a.only and name not in a.only:
            continue
        if name in a.skip:
            continue
        end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
        body = text[pos:end].rstrip() + '\n'
        new_name = ren.get(name, name)
        for pat, rep in pats:
            body = pat.sub(rep, body)
        note = ''
        if new_name != name:
            note = f'// G1 重编号: 上轮名 {name} → 本轮 {new_name}（含其例化的内层名同步改）\n'
        (out_dir / f'{new_name}.sv').write_text(header + '\n\n' + note + body)
        written.append(new_name)

    print(f'拆出 {len(written)} 个模块 -> {out_dir}: {" ".join(written)}')


if __name__ == '__main__':
    main()
