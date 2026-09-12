#!/usr/bin/env python3
"""g1_leaf_audit.py —— 黑盒候选的机械叶子审计（codex 0143 §3）。

黑盒名单只能来自已定义的排除类（vendor macro / array·sram wrapper / 纯 behavioral RAM），
而且**不能仅凭命名判断它是叶子**：若某个拟黑盒模块仍例化了「不在同一排除闭包内」的
module，就说明黑盒它会截断真实设计层次，必须拒绝入名单并报告。

输出：
  docs/g1_blackbox_candidates.tsv   通过审计的黑盒名单（含类别、子例化统计、文件 sha256）
  docs/g1_leaf_audit_rejected.tsv   被拒的候选及其越界子模块
非零退出 = 有候选被拒（需人工看过再决定）。
"""
import hashlib
import pathlib
import re
import sys

G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parent.parent

# 排除类定义（与 g1_configured_universe.py 保持一致）
CLASSES = [
    (re.compile(r'_ext$'),                 'vendor_macro_leaf'),
    (re.compile(r'^sram_array_'),          'vendor_sram_wrapper'),
    (re.compile(r'^array(_\d+)?$'),        'vendor_array_wrapper'),
    (re.compile(r'^ram_\w*\d+x\d+$'),      'behavioral_ram'),
    (re.compile(r'^ram_sink_\w+$'),        'behavioral_ram'),
    (re.compile(r'^data_mem_'),            'behavioral_ram'),
]
INST = re.compile(r'^\s+([A-Za-z_]\w*)\s*(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*)?\w*\s*\($',
                  re.MULTILINE)


def cls_of(name):
    for pat, c in CLASSES:
        if pat.search(name):
            return c
    return None


def main():
    # 全库模块 → 定义文件（.sv 与 .v 都收，vendor 叶子常在 .v）
    where = {}
    for p in list(G1.glob('*.sv')) + list(G1.glob('*.v')):
        for m in re.finditer(r'^module\s+(\w+)', p.read_text(errors='replace'), re.M):
            where[m.group(1)] = p

    cands = sorted(n for n in where if cls_of(n))
    ok, rejected = [], []
    for n in cands:
        p = where[n]
        text = p.read_text(errors='replace')
        kids = {m.group(1) for m in INST.finditer(text)
                if m.group(1) in where and m.group(1) != n}
        outside = sorted(k for k in kids if cls_of(k) is None)
        if outside:
            rejected.append((n, cls_of(n), str(p.name), ','.join(outside[:5])))
        else:
            ok.append((n, cls_of(n), str(p.name), str(len(kids)),
                       hashlib.sha256(p.read_bytes()).hexdigest()))

    o = REPO / 'docs' / 'g1_blackbox_candidates.tsv'
    with o.open('w') as f:
        f.write('# 通过 leaf audit 的黑盒名单（仅用于 universe 提取加速，'
                '禁止进入任何 Formal signoff 配置或 allow 声明 —— codex 0143 §1）\n')
        f.write('# module\tclass\tdef_file\tn_children_in_closure\tfile_sha256\n')
        for r in ok:
            f.write('\t'.join(r) + '\n')

    r = REPO / 'docs' / 'g1_leaf_audit_rejected.tsv'
    with r.open('w') as f:
        f.write('# 被拒的黑盒候选：仍例化了排除闭包之外的 module，黑盒它会截断真实设计层次\n')
        f.write('# module\tclass\tdef_file\toutside_children\n')
        for x in rejected:
            f.write('\t'.join(x) + '\n')

    from collections import Counter
    print(f'黑盒候选 {len(cands)} 个：通过 {len(ok)}，拒绝 {len(rejected)}')
    print('  通过分类:', dict(Counter(x[1] for x in ok).most_common()))
    if rejected:
        print('  ★被拒（越界子例化）:')
        for x in rejected[:10]:
            print(f'    {x[0]} ({x[1]}) → {x[3]}')
    return 1 if rejected else 0


if __name__ == '__main__':
    sys.exit(main())
