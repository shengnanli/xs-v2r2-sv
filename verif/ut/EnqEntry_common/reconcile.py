#!/usr/bin/env python3
"""reconcile.py —— EnqEntry* 预测 vs 实测逐条对账（★数字不手抄，从 receipt 里读★）。

规矩：跑前把预测写死（PREDICTIONS.md + predict.py），跑完逐条对账，
对不上按 fail 上报、把差额逐位指认出来，**不事后改预测**。

本脚本把「实测」那一列从 `evidence/<commit>/<top>/receipt.json` 机械读出来，
对账表因此不会因为手抄而和真实产物脱节。

判据（本族用等号，依据见 predict.py 的 docstring）：
    passing == model 且 failing == 0 且 unmatched == 0 且 verdict == SUCCEEDED

用法:
    python3 reconcile.py <commit前缀>          # 打对账表，非零退出=有对不上的
    python3 reconcile.py <commit前缀> --md     # markdown 表（贴进 PREDICTIONS.md）
"""
import json, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(HERE))
from predict import predict, DONE9                             # noqa: E402


def load(commit, top):
    cands = sorted((REPO / 'evidence').glob('%s*/%s/receipt.json' % (commit, top)))
    return json.loads(cands[-1].read_text()) if cands else None


def main(argv):
    commit = argv[0]
    md = '--md' in argv
    tops = [a for a in argv[1:] if not a.startswith('-')] or DONE9
    rows, bad = [], 0
    for top in tops:
        p = predict(top)
        r = load(commit, top)
        if r is None:
            rows.append((top, p, None, 'MISSING', None))
            bad += 1
            continue
        d = r['verdict_detail'] if isinstance(r.get('verdict_detail'), dict) \
            else json.loads(r['verdict_detail'])
        got = d.get('passing')
        ok = (got == p['model'] and d.get('failing', 1) == 0
              and d.get('unmatched', 1) == 0 and r['verdict'] == 'SUCCEEDED')
        if not ok:
            bad += 1
        rows.append((top, p, d, r['verdict'], got))
    if md:
        print('| 变体 | 模型(=预测) | 实测 passing | 差 | failing | unmatched | '
              'unread | constant_reg | verdict |')
        print('|---|---|---|---|---|---|---|---|---|')
        for top, p, d, v, got in rows:
            if d is None:
                print('| `%s` | %d | — | — | — | — | — | — | MISSING |'
                      % (top, p['model']))
                continue
            ur = d.get('unread')
            print('| `%s` | %d | **%s** | %+d | %s | %s | %s | %s | %s |'
                  % (top, p['model'], got, got - p['model'], d.get('failing'),
                     d.get('unmatched'), 0 if ur in (None, 0) else ur,
                     d.get('constant_reg'), v))
    else:
        print('%-14s%8s%8s%7s  verdict' % ('变体', '模型', '实测', '差'))
        for top, p, d, v, got in rows:
            print('%-14s%8d%8d%+7d  %s'
                  % (top, p['model'], got or 0,
                     (got - p['model']) if got else 0, v))
        print('\n对不上的: %d 个' % bad)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
