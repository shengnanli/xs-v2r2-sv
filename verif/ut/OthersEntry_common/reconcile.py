#!/usr/bin/env python3
"""reconcile.py —— 预测 vs 实测逐条对账（★数字不手抄，从 receipt 里读★）。

规矩是跑前把预测写死（PREDICTIONS.md + predict.py），跑完逐条对账，
对不上按 fail 上报、不事后改预测。
本脚本把「实测」那一列**从 evidence/<commit>/<top>/receipt.json 机械读出来**，
所以对账表不会因为手抄而和真实产物脱节；每行同时带上 receipt 自己的
impl 闭包 sha256，谁都能顺着去核。

用法:
    python3 reconcile.py <commit前缀>          # 打对账表，非零退出=有对不上的
    python3 reconcile.py <commit前缀> --md     # 输出 markdown 表（贴进 PREDICTIONS.md）
"""
import json, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(HERE))
from predict import predict, DONE18                            # noqa: E402


def load(commit, top):
    cands = sorted((REPO / 'evidence').glob(f'{commit}*/{top}/receipt.json'))
    if not cands:
        return None
    return json.loads(cands[-1].read_text())


def main(argv):
    commit = argv[0]
    md = '--md' in argv
    rows, bad = [], 0
    for top in DONE18:
        p = predict(top)
        r = load(commit, top)
        if r is None:
            rows.append((top, p, None, 'MISSING', 0))
            bad += 1
            continue
        d = r['verdict_detail'] if isinstance(r.get('verdict_detail'), dict) \
            else json.loads(r['verdict_detail'])
        got = d.get('passing')
        # 判据：实测 ∈ [可接受下界, 模型上界]，且 failing/unmatched 全 0
        ok = (got is not None and p['lo'] <= got <= p['model']
              and d.get('failing', 1) == 0 and d.get('unmatched', 1) == 0
              and r['verdict'] == 'SUCCEEDED')
        if not ok:
            bad += 1
        rows.append((top, p, d, r['verdict'], got))
    if md:
        print('| 变体 | 模型(上界) | 下界 | 实测 passing | 差 | failing | unmatched | '
              'unread | verdict | vmucp |')
        print('|---|---|---|---|---|---|---|---|---|---|')
        for top, p, d, v, got in rows:
            if d is None:
                print(f'| `{top}` | {p["model"]} | {p["lo"]} | — | — | — | — | — | '
                      f'MISSING | — |')
                continue
            r = load(commit, top)
            vm = r['proof_config']['verify_matched_unread_compare_points']
            ur = d.get('unread')
            print(f'| `{top}` | {p["model"]} | {p["lo"]} | **{got}** | '
                  f'{got - p["model"]:+d} | {d.get("failing")} | '
                  f'{d.get("unmatched")} | {0 if ur in (None, 0) else ur} | '
                  f'{v} | {vm} |')
    else:
        print(f'{"变体":<18}{"模型":>7}{"实测":>7}{"差":>6}  verdict')
        for top, p, d, v, got in rows:
            print(f'{top:<18}{p["model"]:>7}{(got if got else 0):>7}'
                  f'{((got - p["model"]) if got else 0):>+6}  {v}')
        print(f'\n对不上的: {bad} 个')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
