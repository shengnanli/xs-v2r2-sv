#!/usr/bin/env python3
"""test_audit_ram_manual_review.py —— M3 MANUAL_REVIEWED 窄出口的负测（codex 0203 裁定 X）。

正样本：当前仓里 ram_10x89 的真实绑定必须通过。
负测（每条都必须**不通过**）：
  N1 去掉消息号
  N2 消息号不对（换成别的 codex 号）
  N3 绑定文件 sha256 改一位（等价于「改任一绑定字节」）
  N4 绑定里没有 parent_impl 本身
  N5 design 不在硬编码名单里（名单不读 tsv，不推广到其它 ram_*）
  N6 绑定项格式坏（没有 =）
  N7 绑定了不存在的文件
父级授权范围（codex 0206 D3，MANUAL_REVIEW_PARENTS）：
  S0 Slice/Slice_1/Slice_2/Slice_3 + GrantBuffer + Queue10 的真实 allow 声明通过（静态判据）
  S1 别的父级（L2Top）                       S2 别的 ram（ram_16x25）
  S3 同一父级里别的路径                       S4 两侧不对称（impl 缺）
  S5 一侧两个实例                             S6 class 不是 APPROVED_MEMORY_MACRO_MODEL
  C0 fm_verdict 在 HEAD 上验 GrantBuffer 证书：Slice 通过
  C1 GrantBuffer 证书失效（在没有证书的 commit 上验）→ 红
  C2 GrantBuffer 证书字节被篡改（声明 sha 与证书不符）→ 红
用法: python3 scripts/test_audit_ram_manual_review.py
"""
import hashlib
import os
import pathlib
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audit_ram_memory_model as A  # noqa: E402

REPO = A.REPO
IMPL = 'rtl/uncore/Queue10_GrantBuffer_Anon.sv'
CORE = 'rtl/common/xs_ChiselQueue_core.sv'


def sha(p):
    return hashlib.sha256((REPO / p).read_bytes()).hexdigest()


def flip(h):
    return ('0' if h[0] != '0' else '1') + h[1:]


def main():
    good = f'codex_0202;{IMPL}={sha(IMPL)};{CORE}={sha(CORE)}'
    impl_path = str(REPO / IMPL)
    cases = [
        ('P0 真实绑定通过', 'ram_10x89', good, True),
        ('N1 去掉消息号', 'ram_10x89', f'{IMPL}={sha(IMPL)};{CORE}={sha(CORE)}', False),
        ('N2 消息号不对', 'ram_10x89', good.replace('codex_0202', 'codex_0199'), False),
        ('N3 绑定字节变了', 'ram_10x89', good.replace(sha(CORE), flip(sha(CORE))), False),
        ('N4 绑定不含 parent_impl', 'ram_10x89', f'codex_0202;{CORE}={sha(CORE)}', False),
        ('N5 design 不在名单', 'ram_16x25', good, False),
        ('N6 绑定项格式坏', 'ram_10x89', f'codex_0202;{IMPL}', False),
        ('N7 绑定不存在的文件', 'ram_10x89', good + ';rtl/nope/none.sv=' + '0' * 64, False),
    ]
    fails = []
    for name, design, review, want in cases:
        ok, msg = A.check_manual_review(design, review, impl_path)
        good_ = (ok is True) == want
        print(f'  {name:28s} {"ok" if good_ else "★FAIL★"}  {msg[:90]}')
        if not good_:
            fails.append(name)
    fails += scope_cases()
    if fails:
        print(f'test_audit_ram_manual_review: ★{len(fails)} 条不过★ {fails}')
        return 1
    print('test_audit_ram_manual_review: 全过（M3 复核 1 正 + 7 负；父级范围 2 正 + 8 负）')
    return 0


def _objs(target):
    import json
    d = json.loads((REPO / 'verif' / 'allow' / f'{target}.json').read_text())
    return [e for e in d['objects'] if e['design'] == 'ram_10x89']


def scope_cases():
    import copy
    import subprocess
    import fm_verdict as F
    fails = []

    def chk(name, got, want):
        ok = (got is True) == want
        print(f'  {name:28s} {"ok" if ok else "★FAIL★"}  {str(got)[:110]}')
        if not ok:
            fails.append(name)

    for t in ('GrantBuffer', 'Queue10_GrantBuffer_Anon', 'Slice', 'Slice_1', 'Slice_2', 'Slice_3'):
        ok, msg, _ = A.check_parent_scope('ram_10x89', t, _objs(t))
        chk(f'S0 {t}', ok or msg, True)
    sl = _objs('Slice')
    l2 = [dict(e, path=e['path'].replace('/WORK/Slice/', '/WORK/L2Top/')) for e in sl]
    chk('S1 别的父级 L2Top', A.check_parent_scope('ram_10x89', 'L2Top', l2)[0] or 'red', False)
    chk('S2 别的 ram', A.check_parent_scope('ram_16x25', 'Slice', sl)[0] or 'red', False)
    other = [dict(e, path=e['path'].replace('pftRespQueue', 'grantQueue')) for e in sl]
    chk('S3 同父级别的路径', A.check_parent_scope('ram_10x89', 'Slice', other)[0] or 'red', False)
    chk('S4 两侧不对称', A.check_parent_scope(
        'ram_10x89', 'Slice', [e for e in sl if e['side'] == 'r'])[0] or 'red', False)
    chk('S5 一侧两个实例', A.check_parent_scope('ram_10x89', 'Slice', sl + sl[:1])[0] or 'red', False)
    chk('S6 class 不对', A.check_parent_scope(
        'ram_10x89', 'Slice', [dict(e, **{'class': 'vendor_macro'}) for e in sl])[0] or 'red', False)

    # 证书：fm_verdict 在指定 commit 上读 tracked 证书并复算 GrantBuffer 闭包
    canon = (pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical')
             / 'CANONICAL_ID.txt').read_text().strip()
    decl = {('r' if e['side'] == 'r' else 'i', e['design'], e['path']): e for e in sl}
    chk('C0 HEAD 上 GrantBuffer 证书有效', F._ram_parent_scope_check(decl, 'Slice', 'HEAD', canon), True)
    # 没有 GrantBuffer 证书的 commit（main 分叉点之前）：证书不在 → 红
    nocert = subprocess.check_output(
        ['git', '-C', str(REPO), 'log', '--format=%H', '-1', '--diff-filter=A', '--',
         'verif/proof_certificates/GrantBuffer.json']).decode().strip()
    parent = nocert + '~1' if nocert else 'HEAD'
    chk('C1 证书不在该 commit', F._ram_parent_scope_check(decl, 'Slice', parent, canon), False)
    # 证书被篡改：直接用 validate_child_certificate 的 declared sha 不符路径
    import proof_certificate as PC
    repo = PC.Repo(REPO)
    _doc, blob, _err = PC.load_certificate(repo, repo.rev_parse('HEAD'), 'GrantBuffer')
    bad = ('0' if (blob or 'x')[0] != '0' else '1') + (blob or '')[1:]
    r = PC.validate_child_certificate(repo, repo.rev_parse('HEAD'), 'GrantBuffer', bad,
                                      expect_canonical=canon,
                                      policy=PC.load_policy(repo, repo.rev_parse('HEAD'))[0],
                                      fm_targets={'GrantBuffer': None}, fm_targets_unresolved=[])
    chk('C2 证书 sha 不符', r, False)
    return fails


if __name__ == '__main__':
    sys.exit(main())
