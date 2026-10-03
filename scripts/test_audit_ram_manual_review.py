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
  C2 GrantBuffer impl 闭包字节变了 → 红    C3 golden 闭包字节变了 → 红    C4 G1 不同源 → 红
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
    print('test_audit_ram_manual_review: 全过（M3 复核 1 正 + 7 负；父级范围 2 正 + 10 负）')
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
    # 证书失效：GrantBuffer 闭包里任一文件字节变了（在证书副本里把一条 impl sha 翻一位来模拟）
    import types
    ctx, _e = F._cert_ctx('HEAD')
    real = ctx['PC']

    def tamper(field):
        def _load(repo, commit, target):
            doc, blob, err = real.load_certificate(repo, commit, target)
            doc = copy.deepcopy(doc)
            ents = doc['input_closure'][field]
            ents[0]['sha256'] = ('0' if ents[0]['sha256'][0] != '0' else '1') + ents[0]['sha256'][1:]
            return doc, blob, err
        shim = types.SimpleNamespace(**{k: getattr(real, k) for k in dir(real) if not k.startswith('__')})
        shim.load_certificate = _load
        return dict(ctx, PC=shim)
    chk('C2 impl 闭包字节变了', F._child_cert_current(tamper('impl'), 'GrantBuffer', canon), False)
    chk('C3 golden 闭包字节变了', F._child_cert_current(tamper('golden'), 'GrantBuffer', canon), False)
    chk('C4 G1 canonical 不同源', F._child_cert_current(ctx, 'GrantBuffer', 'G1-deadbeef'), False)
    return fails


if __name__ == '__main__':
    sys.exit(main())
