#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fm_predict 变体枚举回归（codex 0244 B：FM_VARIANTS=$(LEAVES) 由 make 展开）。

两层：
  1. 合成树（fm_predict.selftest_enum）：$(LEAVES) 展开 / 普通字面量 / make 失败 fail-closed。
  2. 本仓真实形态：
     - ArbiterLeaves5 `FM_VARIANTS = $(LEAVES)` -> Arbiter2_PtwReq 归 ArbiterLeaves5（修前 None）
     - CompareLeaves6 的 FM_REF_DEPS_<t> 经 make 进模型：compare_2to1 expected 必须
       等于已提交 receipt 的实测 passing（修前按黑盒算出 96，实测 32）
     - 普通字面量目标 NewPipelineConnectPipe_29 走原 from_ut 路径，结果与已提交登记逐键相同
用法: python3 scripts/test_fm_predict_enum.py
"""
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / 'scripts'))
import fm_predict as P                                              # noqa: E402

fails = 0


def ck(name, ok, detail=''):
    global fails
    print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name, '  ' + detail if detail else ''))
    fails += 0 if ok else 1


def receipt_passing(t):
    rp = P.find_receipt(t)
    if rp is None:
        return None
    d = json.loads(rp.read_text())
    v = d['verdict_detail'] if isinstance(d['verdict_detail'], dict) \
        else json.loads(d['verdict_detail'])
    return v.get('passing')


def main():
    print('test_fm_predict_enum:')
    print(' 合成树:')
    global fails
    fails += P.selftest_enum()

    print(' 本仓真实形态:')
    ck('$(LEAVES)：Arbiter2_PtwReq -> ArbiterLeaves5',
       P.ut_of('Arbiter2_PtwReq') == 'ArbiterLeaves5', str(P.ut_of('Arbiter2_PtwReq')))
    ck('$(VARIANT_NAMES)：UncacheEntry_3 -> UncacheEntry 且 merge_dup=false 生效',
       P.predict_one('UncacheEntry_3')['model_applicable'] is True)
    p = P.predict_one('compare_2to1')
    act = receipt_passing('compare_2to1')
    ck('$(LEAVES)+FM_REF_DEPS 经 make：compare_2to1 expected == 实测',
       p['ut'] == 'CompareLeaves6' and act is not None and p['expected'] == act,
       'expected=%s 实测=%s' % (p['expected'], act))
    ck('普通字面量：NewPipelineConnectPipe_29 -> NewPipelineConnectPipe_29_34_35',
       P.ut_of('NewPipelineConnectPipe_29') == 'NewPipelineConnectPipe_29_34_35')
    reg = json.loads(P.reg_path('NewPipelineConnectPipe_29').read_text())
    reg.pop('note', None)
    ck('普通字面量走原 from_ut 路径：与已提交登记逐键相同',
       P.predict_one('NewPipelineConnectPipe_29') == reg)

    print('PASS' if fails == 0 else 'FAIL (%d)' % fails)
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
