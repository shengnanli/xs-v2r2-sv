#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_proof_certificate_grandchild.py —— 「child 的 impl 闭包里挂着 golden」这条新判据的负测。

# 它守的是什么（2026-09-20，LoadQueueReplay 手核时发现的洞）

`LqVAddrModule` 的 receipt 里 `input_closure.impl` 挂着三份 **golden** 文件
（`golden-rtl/DelayN_13.sv` / `DelayNWithValid_152` / `_155`）——那一跑把 golden DelayN
**两侧 elaborate、不黑盒**。它的 verdict 是干干净净的 SUCCEEDED。

★只看 verdict、不看 `impl_closure` 里挂着 golden，就会把一个**还带着 golden 依赖**的绿
 当成无条件绿。★ 而 `recompute_closure_at` **只复算 kind=='repo'**，golden 条目被整个跳过，
所以 D57 原来那九条一条都不会响。

新判据 `validate_impl_golden_certified` 要求：impl 侧挂着的每个 golden 文件，
其模块**自身**要有合格证书，且该证书证的 golden 与这里挂的**逐字节同一份**；并递归往下。

# 这套负测自己的判据（照抄本仓规矩）

  正例      挂 golden + 有合格证书且字节对齐          -> 必须**放行**
  负例 A    挂 golden + 根本没有证书                   -> 必须红（uncertified）
  负例 B    挂 golden + 有证书但证的是**别的字节**     -> 必须红（bytes_mismatch）
  负例 C    挂 golden + 证书 verdict 不合格            -> 必须红（verdict_not_qualifying）
  负例 D    挂 golden + 那个模块根本不是 FM target     -> 必须红（not_fm_target）
  元负例    把判据本身改成"无条件放行"                 -> ★正例仍绿、四个负例全转绿★
            = 这四行负测立刻失去分辨力，看得见

★正例那一行是最值钱的★：没有它，一个 `return '...'`（无条件拒绝）也能让四个负例全红。
★元负例是第二值钱的★：没有它，一个 `return True`（无条件放行）会让四个负例全绿而正例仍绿——
今天已经有两条 lane 各自撞到"负测本身是空的"，所以这两行都不能省。

用法:
    python3 scripts/test_proof_certificate_grandchild.py
    SABOTAGE_GC=1 python3 scripts/test_proof_certificate_grandchild.py   # 元负例
"""
import copy
import json
import os
import pathlib
import sys

_HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))

import proof_certificate as PC          # noqa: E402
import test_proof_certificate as T      # noqa: E402

SABOTAGE = os.environ.get('SABOTAGE_GC') == '1'

GRAND = 'GrandGolden'
GRAND_SV = GRAND + '.sv'
GRAND_TEXT = 'module %s; endmodule // golden\n' % GRAND
GRAND_OTHER = 'module %s; endmodule // golden CHANGED\n' % GRAND

_RESULTS = []


def check(name, ok, detail=''):
    _RESULTS.append((name, ok, detail))
    print('  %-46s %s%s' % (name, 'ok' if ok else '★FAIL', ('  ' + detail) if detail else ''))


def expect_reason(name, got, keyword):
    if got is True:
        check(name, False, '判据放行了，应当拒绝')
    elif not isinstance(got, str):
        check(name, False, '返回了非字符串: %r' % (got,))
    elif keyword not in got:
        check(name, False, '拒绝理由不对: %r（应含 %r）' % (got, keyword))
    else:
        check(name, True)


def _grand_cert(fx, verdict='SUCCEEDED', golden_text=GRAND_TEXT):
    """从 ChildLeaf 的证书派生一份 GrandGolden 的证书（只改必要字段）。"""
    doc = copy.deepcopy(fx.cert)
    doc['target'] = GRAND
    doc['variant'] = GRAND
    doc['ut_dir'] = GRAND
    doc['verdict'] = verdict
    doc['run_id'] = GRAND + '-fixture'
    gold = [{'path': 'golden-rtl/%s' % GRAND_SV, 'kind': 'golden',
             'sha256': T._sha(golden_text.encode())}]
    doc['input_closure']['golden'] = gold
    doc['input_closure']['golden_sha256'] = PC.closure_digest(gold)
    nr = doc['native_result']
    doc['result_sha256'] = PC.canon_digest({'verdict': verdict, 'native_result': nr})
    doc['reproduce'] = {'command': 'PROOF_COMMIT=%s scripts/run_proof.sh %s %s'
                                   % (doc['impl_commit'], GRAND, GRAND)}
    return doc


MC_RAM = 'ram_16x25.sv'


def _mc_entry():
    g = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical') / 'golden-rtl'
    b = (g / MC_RAM).read_bytes()
    return b, {'path': 'golden-rtl/%s' % MC_RAM, 'kind': 'golden', 'sha256': T._sha(b)}


def build(case):
    """按 case 造夹具。返回 (fixture, judge_result)。"""
    # golden 文件表是模块级的，夹具在 __init__ 里读它 —— 加一项再造夹具
    T.GOLDEN_FILES[GRAND_SV] = GRAND_TEXT
    mc = case == 'mc_shared_with_grand'
    mc_bytes, mc_e = _mc_entry() if mc else (None, None)

    def cert_mutate(doc):
        """把 GrandGolden 的 golden 文件塞进 **ChildLeaf 的 impl 闭包** ——
        这就是 LqVAddrModule 现场那个形状。"""
        impl = doc['input_closure']['impl']
        impl.append({'path': 'golden-rtl/%s' % GRAND_SV, 'kind': 'golden',
                     'sha256': T._sha(GRAND_TEXT.encode())})
        if mc:
            # FTB 形状（2026-10-06）：本层 impl 先挂一个 golden FM target（其证书也挂同一份 MC 存储模型），
            # 再在本层自己挂同一份 MC 模型。本层的 MC hit 必须照计，external_dependency 不得判 spurious。
            impl.append(dict(mc_e))
            gold = doc['input_closure']['golden']
            gold.append(dict(mc_e))
            doc['input_closure']['golden_sha256'] = PC.closure_digest(gold)
            doc['external_dependency'] = PC.EXTERNAL_DEPENDENCY_MC
        doc['input_closure']['impl_sha256'] = PC.closure_digest(impl)
        return doc

    def post_commit(fx):
        if case != 'not_fm_target':
            fx._w('verif/ut/%s/Makefile' % GRAND,
                  'MODULE = %s\nFM_VARIANTS = %s\n' % (GRAND, GRAND))
        if case == 'uncertified':
            return                      # 故意不写证书
        if case == 'bytes_mismatch':
            doc = _grand_cert(fx, golden_text=GRAND_OTHER)
        elif case == 'verdict_bad':
            doc = _grand_cert(fx, verdict='PARTIAL')
        else:
            doc = _grand_cert(fx)
        if mc:
            for k in ('impl', 'golden'):
                doc['input_closure'][k].append(dict(mc_e))
                doc['input_closure'][k + '_sha256'] = PC.closure_digest(doc['input_closure'][k])
            doc['external_dependency'] = PC.EXTERNAL_DEPENDENCY_MC
        fx._w('verif/proof_certificates/%s.json' % GRAND,
              json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True) + '\n')

    try:
        kw = dict(extra_golden={MC_RAM: mc_bytes}, mc_repo=True) if mc else {}
        fx = T.Fixture(cert_mutate=cert_mutate, post_commit=post_commit, **kw)
        return fx, fx.judge()
    finally:
        T.GOLDEN_FILES.pop(GRAND_SV, None)


def main():
    if SABOTAGE:
        # 元负例：把判据本身改成无条件放行
        PC.validate_impl_golden_certified = (
            lambda *a, **k: True)                                   # noqa: E731
        print('=== SABOTAGE_GC：判据已被改成无条件放行，四个负例应当全部转绿 ===')

    print('=== child 的 impl 闭包挂 golden：正例 + 四个负例 ===')

    _, r = build('ok')
    check('正例  挂 golden + 合格证书且字节对齐 -> 放行', r is True,
          '' if r is True else '被拒了: %r' % (r,))

    _, r = build('uncertified')
    expect_reason('负例A 挂 golden + 没有证书', r, 'impl_golden_uncertified')

    _, r = build('bytes_mismatch')
    expect_reason('负例B 挂 golden + 证书证的是别的字节', r, 'impl_golden_bytes_mismatch')

    _, r = build('verdict_bad')
    expect_reason('负例C 挂 golden + 证书 verdict 不合格', r,
                  'impl_golden_verdict_not_qualifying')

    _, r = build('not_fm_target')
    expect_reason('负例D 挂 golden + 不是 FM target', r, 'impl_golden_')

    _, r = build('mc_shared_with_grand')
    check('正例2 本层与 golden 子层共用同一 MC 对象 -> 本层计 hit、放行', r is True,
          '' if r is True else '被拒了: %r' % (r,))

    total = len(_RESULTS)
    bad = [n for n, ok, _ in _RESULTS if not ok]
    print('\n断言 %d 条，未过 %d 条' % (total, len(bad)))
    if total != 6:
        print('★断言条数 %d != 6 —— 有用例被跳过，判失败★' % total)
        return 1
    rc = 1 if bad else 0
    if SABOTAGE:
        if rc == 0:
            print('★★ SABOTAGE 没被抓到 —— 这套负测是瞎的，判失败 ★★')
            return 1
        print('SABOTAGE 被抓到（如期变红，未过的是：%s）：本次的"红"是**预期结果**'
              % ', '.join(bad))
        return 0
    print('ALL OK' if rc == 0 else 'NOT OK')
    return rc


if __name__ == '__main__':
    sys.exit(main())
