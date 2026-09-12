#!/usr/bin/env python3
"""declare_dead_ref.py —— 由本轮实跑观测生成 PASS_DEAD_REF 声明。

PASS_DEAD_REF 的含义：FM 已证明全部可达比对点等价（failing=0 / unmatched=0），
唯一残余是 **golden 侧写了但从不被读的 cone-dead 寄存器位**——可读核按 golden 的
真实读取宽度收窄存储，因而这些位在 impl 侧不存在。这不是 waiver：声明逐条列出
ref_path，判定时观测集合必须与声明**精确相等**，多一条少一条都退 PARTIAL。

使用要求（人工把关，脚本不替你判断）：
  --rationale 必填，须说明「这些位为什么在 golden 里也是死的」，并指出 impl 为何
  正确地没有它们。写不出来就不该声明。

用法:
  declare_dead_ref.py <target> --points <unread_points.txt> --rationale "…" [--class 名]
"""
import argparse
import json
import pathlib
import sys

NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target')
    ap.add_argument('--points', required=True)
    ap.add_argument('--rationale', required=True)
    ap.add_argument('--class', dest='cls', default='golden_only_cone_dead')
    a = ap.parse_args()

    lines = pathlib.Path(a.points).read_text().splitlines()
    ref = sorted({l.split('\t', 1)[1].strip() for l in lines if l.startswith('ref\t')})
    other = [l for l in lines if l.strip() and not l.startswith('ref\t')]
    if other:
        sys.exit(f'ERROR: {a.target} 存在非 golden 侧未读点 {len(other)} 条'
                 f'（impl 侧未读或 matched-not-compared）——不属 PASS_DEAD_REF，'
                 f'须先消除或改用 vmucp 双射。首条: {other[0][:120]}')
    if not ref:
        sys.exit(f'ERROR: {a.target} 无未读点，无需声明')
    if len(a.rationale) < 30:
        sys.exit('ERROR: rationale 太短——须说明这些位为何在 golden 中也是死的')

    decl = {
        'schema': 'xs-v2-sv-dead-ref-v1',
        'target': a.target,
        'baseline': 'G1-canonical (kunminghu-v2 @b36a1a2a5)',
        'rationale': a.rationale,
        'observed_points': len(ref),
        'entries': [{'ref_path': p, 'class': a.cls} for p in ref],
    }
    out = NEW / 'verif' / 'dead_ref' / f'{a.target}.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(decl, ensure_ascii=False, indent=1))
    print(f'{a.target}: 声明 {len(ref)} 条 -> {out.relative_to(NEW)}')


if __name__ == '__main__':
    main()
