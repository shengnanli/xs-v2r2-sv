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
  C0 fm_verdict 在「最近一次更新 GrantBuffer 证书的 commit」上验证书：Slice 通过
     （锚在那个 commit 而不是 HEAD：HEAD 上证书是否新鲜是集成状态，不是本判据对错；
      证书过期时 Slice 的正式判定会自己变红，那由 fm_verdict 管，不该让负测跟着漂）
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
    fails += ram40_cases()
    fails += codex0210_cases()
    fails += codex0215_cases()
    if fails:
        print(f'test_audit_ram_manual_review: ★{len(fails)} 条不过★ {fails}')
        return 1
    print('test_audit_ram_manual_review: 全过（M3 复核 1 正 + 7 负；父级范围 2 正 + 10 负；ram_40x47 3 正 + 10 负；'
          'codex 0210 3 正 + 12 负；codex 0215 6 正 + 16 负）')
    return 0


def codex0210_cases():
    """codex 0210：R1 ram_78x15 单条审定（仅 Queue78_PCrdGranted，M3 impl 侧人工复核绑定共享核 sha）；
    R2 ram_40x47 父级扩到 Queue40_L2TlbMQBundle。
    T0 ram_78x15 真实复核绑定通过               T1 Queue78 真实 allow 声明通过   T2 Queue40 真实 allow 声明通过
    T3 共享核 sha 变一位 → 红                   T4 复核消息号用 0202 → 红        T5 绑定不含 Queue78 薄文件 → 红
    T6 ram_78x15 别的父级（Queue2_PCrdGranted）→ 红
    T7 ram_78x15 套到 ram_10x89 的父级（Queue10_GrantBuffer_Anon）→ 红
    T8 别的 ram（ram_10x89）套 Queue78 → 红     T9 别的 ram（ram_16x25）套 Queue40 → 红
    T10 Queue78 两侧不对称（impl 缺）→ 红       T11 Queue78 一侧两实例 → 红
    T12 Queue40 两侧不对称（ref 缺）→ 红        T13 Queue40 一侧两实例 → 红
    T14 Queue40 授权路径外（io_out_q/ram_ext 套到 Queue40 自己）→ 红"""
    import json
    fails = []

    def chk(name, got, want):
        ok = (got is True) == want
        print(f'  {name:28s} {"ok" if ok else "★FAIL★"}  {str(got)[:110]}')
        if not ok:
            fails.append(name)

    def objs(t, design):
        d = json.loads((REPO / 'verif' / 'allow' / f'{t}.json').read_text())
        return [e for e in d['objects'] if e['design'] == design]

    q78 = 'rtl/uncore/Queue78_PCrdGranted.sv'
    good = f'codex_0210;{q78}={sha(q78)};{CORE}={sha(CORE)}'
    chk('T0 78x15 复核绑定', A.check_manual_review('ram_78x15', good, str(REPO / q78))[0], True)
    o78 = objs('Queue78_PCrdGranted', 'ram_78x15')
    o40 = objs('Queue40_L2TlbMQBundle', 'ram_40x47')
    r = A.check_parent_scope('ram_78x15', 'Queue78_PCrdGranted', o78)
    chk('T1 Queue78 allow', r[0] or r[1], True)
    r = A.check_parent_scope('ram_40x47', 'Queue40_L2TlbMQBundle', o40)
    chk('T2 Queue40 allow', r[0] or r[1], True)
    chk('T3 共享核 sha 变', A.check_manual_review(
        'ram_78x15', good.replace(sha(CORE), flip(sha(CORE))), str(REPO / q78))[0] or 'red', False)
    chk('T4 消息号 0202', A.check_manual_review(
        'ram_78x15', good.replace('codex_0210', 'codex_0202'), str(REPO / q78))[0] or 'red', False)
    chk('T5 绑定缺薄文件', A.check_manual_review(
        'ram_78x15', f'codex_0210;{CORE}={sha(CORE)}', str(REPO / q78))[0] or 'red', False)
    mv = lambda os_, a, b: [dict(e, path=e['path'].replace(a, b)) for e in os_]
    chk('T6 78x15 别的父级', A.check_parent_scope(
        'ram_78x15', 'Queue2_PCrdGranted',
        mv(o78, '/WORK/Queue78_PCrdGranted/', '/WORK/Queue2_PCrdGranted/'))[0] or 'red', False)
    chk('T7 78x15 套 0202 父级', A.check_parent_scope(
        'ram_78x15', 'Queue10_GrantBuffer_Anon',
        mv(o78, '/WORK/Queue78_PCrdGranted/', '/WORK/Queue10_GrantBuffer_Anon/'))[0] or 'red', False)
    chk('T8 别的 ram 套 Queue78', A.check_parent_scope(
        'ram_10x89', 'Queue78_PCrdGranted', o78)[0] or 'red', False)
    chk('T9 别的 ram 套 Queue40', A.check_parent_scope(
        'ram_16x25', 'Queue40_L2TlbMQBundle', o40)[0] or 'red', False)
    chk('T10 Q78 两侧不对称', A.check_parent_scope(
        'ram_78x15', 'Queue78_PCrdGranted', [e for e in o78 if e['side'] == 'r'])[0] or 'red', False)
    chk('T11 Q78 一侧两实例', A.check_parent_scope(
        'ram_78x15', 'Queue78_PCrdGranted', o78 + o78[:1])[0] or 'red', False)
    chk('T12 Q40 两侧不对称', A.check_parent_scope(
        'ram_40x47', 'Queue40_L2TlbMQBundle', [e for e in o40 if e['side'] == 'i'])[0] or 'red', False)
    chk('T13 Q40 一侧两实例', A.check_parent_scope(
        'ram_40x47', 'Queue40_L2TlbMQBundle', o40 + o40[1:])[0] or 'red', False)
    chk('T14 Q40 授权路径外', A.check_parent_scope(
        'ram_40x47', 'Queue40_L2TlbMQBundle', mv(o40, '/ram_ext', '/io_out_q/ram_ext'))[0] or 'red', False)
    return fails


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
    anchor = subprocess.check_output(
        ['git', '-C', str(REPO), 'log', '--format=%H', '-1', '--',
         'verif/proof_certificates/GrantBuffer.json']).decode().strip()
    chk('C0 证书 commit 上 GrantBuffer 证书有效', F._ram_parent_scope_check(decl, 'Slice', anchor, canon), True)
    # 没有 GrantBuffer 证书的 commit（main 分叉点之前）：证书不在 → 红
    nocert = subprocess.check_output(
        ['git', '-C', str(REPO), 'log', '--format=%H', '-1', '--diff-filter=A', '--',
         'verif/proof_certificates/GrantBuffer.json']).decode().strip()
    parent = nocert + '~1' if nocert else 'HEAD'
    chk('C1 证书不在该 commit', F._ram_parent_scope_check(decl, 'Slice', parent, canon), False)
    # 证书失效：GrantBuffer 闭包里任一文件字节变了（在证书副本里把一条 impl sha 翻一位来模拟）
    import types
    ctx, _e = F._cert_ctx(anchor)
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



def ram40_cases():
    """codex 0209：ram_40x47 父级范围 {L2TlbMissQueue, L2TLB, L2TLBWrapper}，仅限 L2TlbMissQueue 子树。
    R0 L2TlbMissQueue 真实 allow 声明通过；R0-0228 L2TLB/L2TLBWrapper 的 allow 不得再有 ram_40x47（codex 0228）
    R0f 0228 前的 L2TLB / L2TLBWrapper 声明（冻结夹具）通过 0209 父级范围判据
    R1 别的父级（L2Top）                 R2 别的 ram 套 L2TLB 的路径（ram_10x89）
    R3 路径不在 L2TlbMissQueue 子树      R4 两侧不对称（impl 缺）    R5 一侧两个实例
    R6 child receipt 的 impl 闭包 stale  R7 child receipt verdict 不合格  R8 child receipt 不存在
    R9 fm_verdict 判据：L2TLB 声明里多出一个子树外的 ram_40x47 → 红"""
    import json
    import shutil
    import tempfile
    import fm_verdict as F
    fails = []

    def chk(name, got, want):
        ok = (got is True) == want
        print(f'  {name:28s} {"ok" if ok else "★FAIL★"}  {str(got)[:110]}')
        if not ok:
            fails.append(name)

    def objs(t):
        d = json.loads((REPO / 'verif' / 'allow' / f'{t}.json').read_text())
        return [e for e in d['objects'] if e['design'] == 'ram_40x47']

    # codex 0228：L2TLB / L2TLBWrapper 改走嵌套 green_child，ram_40x47 只留在 L2TlbMissQueue 子树内部，
    # 不得再出现在这两个父级的 allow 里。真实声明只剩 L2TlbMissQueue 一处（R0），另两处断言为空（R0-0228）。
    ok, msg, _ = A.check_parent_scope('ram_40x47', 'L2TlbMissQueue', objs('L2TlbMissQueue'))
    chk('R0 L2TlbMissQueue', ok or msg, True)
    for t in ('L2TLB', 'L2TLBWrapper'):
        chk(f'R0-0228 {t} 无 ram_40x47', not objs(t) or 'ram_40x47_in_%s_allow' % t, True)
    # R0f..R9 的 L2TLB 级样本：0228 前 main（20df9ac22c5fa1cc081ebbb8bee5e323843526e5）verif/allow/L2TLB.json
    # 里的 ram_40x47 声明原样冻结为夹具——check_parent_scope 的 0209 判据本身仍在，负测仍须能判红。
    lt = [{'side': 'r', 'design': 'ram_40x47', 'path': 'r:/WORK/L2TLB/missQueue/io_out_q/ram_ext',
           'attrs': 'i', 'class': 'APPROVED_MEMORY_MACRO_MODEL'},
          {'side': 'i', 'design': 'ram_40x47', 'path': 'i:/WORK/L2TLB/u_core/u_missQueue/io_out_q/ram_ext',
           'attrs': 'i', 'class': 'APPROVED_MEMORY_MACRO_MODEL'}]
    for t in ('L2TLB', 'L2TLBWrapper'):
        tl = [dict(e, path=e['path'].replace('/WORK/L2TLB/', '/WORK/L2TLBWrapper/ptw/' if t == 'L2TLBWrapper'
                                              else '/WORK/L2TLB/')) for e in lt]
        ok, msg, _ = A.check_parent_scope('ram_40x47', t, tl)
        chk(f'R0f {t} 夹具', ok or msg, True)
    l2 = [dict(e, path=e['path'].replace('/WORK/L2TLB/', '/WORK/L2Top/')) for e in lt]
    chk('R1 别的父级 L2Top', A.check_parent_scope('ram_40x47', 'L2Top', l2)[0] or 'red', False)
    chk('R2 别的 ram', A.check_parent_scope('ram_10x89', 'L2TLB', lt)[0] or 'red', False)
    out = [dict(e, path=e['path'].replace('issQueue/io_out_q', 'issQueue2/io_out_q')) for e in lt]
    chk('R3 不在 MissQueue 子树', A.check_parent_scope('ram_40x47', 'L2TLB', out)[0] or 'red', False)
    chk('R4 两侧不对称', A.check_parent_scope(
        'ram_40x47', 'L2TLB', [e for e in lt if e['side'] == 'r'])[0] or 'red', False)
    chk('R5 一侧两个实例', A.check_parent_scope('ram_40x47', 'L2TLB', lt + lt[:1])[0] or 'red', False)

    rel = A.L2TLB_MQ_RECEIPT[len('receipt:'):]
    rec = json.loads((REPO / rel).read_text())
    with tempfile.TemporaryDirectory() as td:
        tdp = pathlib.Path(td)

        def mk(doc, tamper_impl=False):
            for sub in (tdp / 'evidence', tdp / 'rtl'):
                shutil.rmtree(sub, ignore_errors=True)
            (tdp / rel).parent.mkdir(parents=True, exist_ok=True)
            (tdp / rel).write_text(json.dumps(doc))
            for e in doc['impl_closure']:
                dst = tdp / e['path']
                dst.parent.mkdir(parents=True, exist_ok=True)
                b = (REPO / e['path']).read_bytes()
                dst.write_bytes(b + (b'\n// tampered\n' if tamper_impl else b''))
        mk(rec)
        chk('R6- 副本仓库原样通过', A.check_child_receipt_current(rel, repo=tdp)[0] or 'red', True)
        mk(rec, tamper_impl=True)
        chk('R6 impl 闭包 stale', A.check_child_receipt_current(rel, repo=tdp)[0] or 'red', False)
        mk(dict(rec, verdict='PARTIAL'))
        chk('R7 verdict 不合格', A.check_child_receipt_current(rel, repo=tdp)[0] or 'red', False)
        chk('R8 receipt 不存在', A.check_child_receipt_current(
            'evidence/000000000000/L2TlbMissQueue/receipt.json')[0] or 'red', False)

    extra = dict(lt[0], path='r:/WORK/L2TLB/cache/ram_ext')
    decl = {(e['side'], e['design'], e['path']): e for e in lt + [extra]}
    chk('R9 fm_verdict 子树外多一个', F._ram_parent_scope_check(decl, 'L2TLB', None, None), False)
    decl_ok = {(e['side'], e['design'], e['path']): e for e in lt}
    chk('R9- fm_verdict 真实声明通过', F._ram_parent_scope_check(decl_ok, 'L2TLB', None, None), True)
    return fails


def codex0215_cases():
    """codex 0215 Q1：ram_10x89（slices_0..3）/ ram_78x15（pCrdQueue_s2）扩到 TL2CHICoupledL2 / L2Top，逐对象完整路径。
    U0 TL2 / L2Top 两 design 的合成正例（与诊断跑 black_boxes.rpt 实测路径一致）各通过（4 正）
    U1 ram_78x15 经由的 Queue78 receipt 在本仓字节上不 stale；副本仓库原样通过（2 正）
    负例（必须红）：
    V1 错 slice 编号（slices_4）           V2 少一个 slice                 V3 单侧路径不同（impl 少 u_core）
    V4 L2Top 少 inner_l2cache 层（用 TL2 的路径）  V5 多一个同名 RAM（别处的 ram_10x89）
    V6 一侧重复同一对象                     V7 ref / impl slice 交叉（ref slices_0 配 impl slices_1 缺）
    V8 L2Top 用 TL2 的 target 名            V9 golden ram_10x89 hash 变（golden 副本改一字节）
    V10 golden ram_78x15 深度变（副本把 Memory[0:77] 改成 [0:79]）
    V11 Queue78 receipt 的指针核心 xs_ChiselQueue_core.sv 变（副本仓库）
    V12 ram_78x15 套 TL2 的 slices 路径      V13 别的父级（XSTile）
    V14 class 不是 APPROVED_MEMORY_MACRO_MODEL  V15 ram_10x89 少了 ref 侧整组
    V16 fm_verdict 判据：TL2 声明里多一个授权外 ram_10x89"""
    import json
    import shutil
    import tempfile
    import fm_verdict as F
    fails = []

    def chk(name, got, want):
        ok = (got is True) == want
        print(f'  {name:28s} {"ok" if ok else "★FAIL★"}  {str(got)[:110]}')
        if not ok:
            fails.append(name)

    def mk(top, design, pfx=''):
        out = []
        if design == 'ram_10x89':
            for k in range(4):
                out.append({'side': 'r', 'design': design, 'attrs': 'u', 'class': 'APPROVED_MEMORY_MACRO_MODEL',
                            'path': f'r:/WORK/{top}/{pfx}slices_{k}/grantBuf/pftRespQueue/ram_ext'})
                out.append({'side': 'i', 'design': design, 'attrs': 'u', 'class': 'APPROVED_MEMORY_MACRO_MODEL',
                            'path': f'i:/WORK/{top}/{pfx}slices_{k}/u_core/grantBuf/pftRespQueue/ram_ext'})
        else:
            for sd in 'ri':
                out.append({'side': sd, 'design': design, 'attrs': 'u', 'class': 'APPROVED_MEMORY_MACRO_MODEL',
                            'path': f'{sd}:/WORK/{top}/{pfx}pCrdQueue_s2/ram_ext'})
        return out

    for top, pfx in (('TL2CHICoupledL2', ''), ('L2Top', 'inner_l2cache/')):
        for d in ('ram_10x89', 'ram_78x15'):
            ok, msg, _ = A.check_parent_scope(d, top, mk(top, d, pfx))
            chk(f'U0 {top} {d}', ok or msg, True)
    rel = A.Q78_RECEIPT[len('receipt:'):]
    chk('U1 Q78 receipt 不 stale', A.check_child_receipt_current(rel)[0] or 'red', True)
    t10 = mk('TL2CHICoupledL2', 'ram_10x89')
    l10 = mk('L2Top', 'ram_10x89', 'inner_l2cache/')
    T = 'TL2CHICoupledL2'
    ps = lambda os_, a, b: [dict(e, path=e['path'].replace(a, b)) for e in os_]
    chk('V1 错 slice 编号', A.check_parent_scope('ram_10x89', T, ps(t10, 'slices_3/', 'slices_4/'))[0] or 'red', False)
    chk('V2 少一个 slice', A.check_parent_scope(
        'ram_10x89', T, [e for e in t10 if 'slices_2/' not in e['path']])[0] or 'red', False)
    one = [dict(e, path=e['path'].replace('slices_1/u_core/', 'slices_1/')) for e in t10]
    chk('V3 单侧路径不同', A.check_parent_scope('ram_10x89', T, one)[0] or 'red', False)
    chk('V4 L2Top 少 inner_l2cache', A.check_parent_scope(
        'ram_10x89', 'L2Top', ps(t10, '/WORK/TL2CHICoupledL2/', '/WORK/L2Top/'))[0] or 'red', False)
    extra = dict(t10[0], path='r:/WORK/TL2CHICoupledL2/mmioBridge/q/ram_ext')
    extra_i = dict(t10[1], path='i:/WORK/TL2CHICoupledL2/mmioBridge/q/ram_ext')
    chk('V5 多一个同名 RAM', A.check_parent_scope('ram_10x89', T, t10 + [extra, extra_i])[0] or 'red', False)
    chk('V6 一侧重复', A.check_parent_scope('ram_10x89', T, t10 + t10[:1])[0] or 'red', False)
    cross = [e for e in t10 if not (e['side'] == 'i' and 'slices_0/' in e['path'])]
    chk('V7 ref/impl slice 交叉缺', A.check_parent_scope('ram_10x89', T, cross)[0] or 'red', False)
    chk('V8 L2Top 用 TL2 target', A.check_parent_scope('ram_10x89', T, l10)[0] or 'red', False)
    with tempfile.TemporaryDirectory() as td:
        g = pathlib.Path(td)
        src = pathlib.Path(A.DEFAULT_G1) / 'golden-rtl'
        for f in ('ram_10x89.sv', 'ram_78x15.sv'):
            (g / f).write_bytes((src / f).read_bytes())
        ok0 = A.check_parent_scope('ram_10x89', T, t10, golden_rtl=str(g))
        chk('V9- golden 副本原样通过', ok0[0] or ok0[1], True)
        (g / 'ram_10x89.sv').write_bytes((src / 'ram_10x89.sv').read_bytes() + b'\n')
        chk('V9 ram_10x89 hash 变', A.check_parent_scope('ram_10x89', T, t10, golden_rtl=str(g))[0] or 'red', False)
        t78 = (src / 'ram_78x15.sv').read_text()
        if '[0:77]' not in t78:
            raise SystemExit('ram_78x15.sv 里没有 [0:77]（负测前提变了）')
        (g / 'ram_78x15.sv').write_text(t78.replace('[0:77]', '[0:79]'))
        chk('V10 ram_78x15 深度变', A.check_parent_scope(
            'ram_78x15', T, mk(T, 'ram_78x15'), golden_rtl=str(g))[0] or 'red', False)
    rec = json.loads((REPO / rel).read_text())
    with tempfile.TemporaryDirectory() as td:
        tdp = pathlib.Path(td)

        def mkrepo(tamper):
            shutil.rmtree(tdp / 'rtl', ignore_errors=True)
            (tdp / rel).parent.mkdir(parents=True, exist_ok=True)
            (tdp / rel).write_text(json.dumps(rec))
            for e in rec['impl_closure']:
                if e.get('kind') != 'repo':
                    continue
                dst = tdp / e['path']
                dst.parent.mkdir(parents=True, exist_ok=True)
                b = (REPO / e['path']).read_bytes()
                if tamper and e['path'].endswith('xs_ChiselQueue_core.sv'):
                    b = b.replace(b'next_ptr', b'next_ptr ', 1)
                dst.write_bytes(b)
        mkrepo(False)
        chk('U1- 副本仓库原样通过', A.check_child_receipt_current(rel, repo=tdp)[0] or 'red', True)
        if not any(e['path'].endswith('xs_ChiselQueue_core.sv') for e in rec['impl_closure']):
            raise SystemExit('Q78 receipt 闭包里没有 xs_ChiselQueue_core.sv（负测前提变了）')
        mkrepo(True)
        chk('V11 Q78 指针核心变', A.check_child_receipt_current(rel, repo=tdp)[0] or 'red', False)
    chk('V12 78x15 套 slices 路径', A.check_parent_scope(
        'ram_78x15', T, [dict(e, design='ram_78x15') for e in t10])[0] or 'red', False)
    chk('V13 别的父级 XSTile', A.check_parent_scope(
        'ram_10x89', 'XSTile', ps(l10, '/WORK/L2Top/', '/WORK/XSTile/'))[0] or 'red', False)
    chk('V14 class 不对', A.check_parent_scope(
        'ram_10x89', T, [dict(e, **{'class': 'vendor_macro'}) for e in t10])[0] or 'red', False)
    chk('V15 少 ref 整组', A.check_parent_scope(
        'ram_10x89', T, [e for e in t10 if e['side'] == 'i'])[0] or 'red', False)
    decl = {(e['side'], e['design'], e['path']): e for e in mk(T, 'ram_78x15') + [extra]}
    chk('V16 fm_verdict 多一个授权外', F._ram_parent_scope_check(decl, T, None, None), False)
    return fails


if __name__ == '__main__':
    sys.exit(main())
