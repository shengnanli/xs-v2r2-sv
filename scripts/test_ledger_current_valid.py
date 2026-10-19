#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_ledger_current_valid.py —— 台账 proven 只认 current-valid 证明（ledger-cv lane）的正反测。

两半，缺一不可：

一、口径接线（合成仓，秒级）：在临时 git 仓里放证书 / receipt / rtl / golden，注入「判据结论」，
    验 proof_currency.evaluate → rewrite_coverage.split_current / coverage_three_axis.axis2 的分档：
    (a) 证书脚本闭包过期              → 不再 PROVEN_DIRECT
    (b) 过期但 WB1–WB6 成立           → PROVEN_IN_CONE(superseded_by=父)，不进 proven
    (c) 过期且无白盒父                → 不 proven（rewrite_coverage dropped；三轴 UNPROVEN、无 closure 候选）
    (d) current-valid                → PROVEN_DIRECT
    (e) 只有 receipt 的根             → 同上三档同一判据（current-valid / superseded / 不 proven）
    外加 WB 反例：父 impl 闭包里 T 的 rtl 字节不同（WB4）→ 不给 superseded；台账有绿判决但无任何证明 → 不 proven。

二、真判据（真仓 HEAD，分钟级）：不注入，走 proof_certificate.validate_certificate_current 本身：
    (d) 一张真 current-valid 证书 → True；(a) 同一张把 scripts/fm_eq.tcl 的脚本闭包 sha 改一位 → script_closure_changed
    (e) 一份只有 receipt、无证书的真根 → validate_receipt current-valid；
        复制它的 evidence、把 script_closure.list 里 fm_eq.tcl 的 sha 改一位 →
        ① validate_receipt 判 script_closure_changed；② **绕过预筛**直接派生 + validate_certificate_current
        也判 script_closure_changed（预筛只是提前算，不是唯一防线）。
"""
import copy
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))
import proof_currency as PCUR          # noqa: E402

FAILS = []
N = [0]


def ck(name, ok, detail=''):
    N[0] += 1
    print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name, ('  ' + str(detail)) if detail else ''))
    if not ok:
        FAILS.append(name)


def sha(b):
    return hashlib.sha256(b).hexdigest()


# ---------------------------------------------------------------------------
# 一、合成仓
# ---------------------------------------------------------------------------
GOLD = {
    'P': 'module P(input a, output b, output c);\n  T u_t (.a(a), .b(b));\n  S u_s (.a(a), .b(c));\nendmodule\n',
    'T': 'module T(input a, output b);\n  assign b = a;\nendmodule\n',
    'S': 'module S(input a, output b);\n  assign b = ~a;\nendmodule\n',
    'W': 'module W(input a, output b);\n  assign b = a;\nendmodule\n',
    'Q': 'module Q(input a, output b);\n  assign b = a;\nendmodule\n',
    'U': 'module U(input a, output b);\n  assign b = a;\nendmodule\n',
    'R': 'module R(input a, output b);\n  assign b = a;\nendmodule\n',
}
RTL = {
    'P': 'module P(input logic a, output logic b, output logic c);\n  T u_t (.a(a), .b(b));\n'
         '  S u_s (.a(a), .b(c));\nendmodule\n',
    'T': 'module T(input logic a, output logic b);\n  assign b = a;\nendmodule\n',
    'S': 'module S(input logic a, output logic b);\n  assign b = ~a;\nendmodule\n',
    'W': 'module W(input logic a, output logic b);\n  assign b = a;\nendmodule\n',
    'Q': 'module Q(input logic a, output logic b);\n  assign b = a;\nendmodule\n',
    'U': 'module U(input logic a, output logic b);\n  assign b = a;\nendmodule\n',
    'R': 'module R(input logic a, output logic b);\n  assign b = a;\nendmodule\n',
}


def gent(m):
    return {'path': 'golden-rtl/%s.sv' % m, 'kind': 'golden', 'sha256': sha(GOLD[m].encode())}


def rent(m, text=None):
    return {'path': 'rtl/%s.sv' % m, 'kind': 'repo', 'sha256': sha((text or RTL[m]).encode())}


def cert(t, golden, impl, mode='signoff-strict'):
    return {'target': t, 'variant': t, 'proof_mode': mode, 'verdict': 'SUCCEEDED', 'proof_config': {},
            'input_closure': {'golden': golden, 'impl': impl}}


def receipt(t, golden, impl):
    return {'top': t, 'verdict': 'SUCCEEDED', 'run_id': '%s-20261019T000000Z-x' % t,
            'impl_closure': impl, 'golden_closure': golden}


def build_fixture(root):
    g1 = root / 'g1'
    (g1 / 'golden-rtl').mkdir(parents=True)
    for m, t in GOLD.items():
        (g1 / 'golden-rtl' / (m + '.sv')).write_text(t)
    repo = root / 'repo'
    (repo / 'rtl').mkdir(parents=True)
    for m, t in RTL.items():
        (repo / 'rtl' / (m + '.sv')).write_text(t)
    cd = repo / 'verif' / 'proof_certificates'
    cd.mkdir(parents=True)
    certs = {
        'P': cert('P', [gent('P'), gent('T'), gent('S')], [rent('P'), rent('T'), rent('S')]),   # (d)
        'T': cert('T', [gent('T')], [rent('T')]),                                             # (a)(b)
        'Q': cert('Q', [gent('Q')], [rent('Q')]),                                             # (c)
        # W：父 P 的闭包里根本没有 W —— 无白盒父；另造 W 的 rtl 字节与 P 闭包不同的 WB4 反例见 T2
    }
    for t, d in certs.items():
        (cd / (t + '.json')).write_text(json.dumps(d))
    # T2：和 T 同一个 golden，但 T2 证书记录的 rtl/T.sv 字节与父 P 闭包里的不同（WB4 反例）
    t2 = cert('T', [gent('T')], [rent('T', RTL['T'] + '// old\n')])
    t2['target'] = 'T2'
    (cd / 'T2.json').write_text(json.dumps(t2))
    rcpts = {
        'R': receipt('R', [gent('R')], [rent('R')]),                                          # (e)(d)
        'S': receipt('S', [gent('S')], [rent('S')]),                                          # (e)(b)
        'U': receipt('U', [gent('U')], [rent('U')]),                                          # (e)(c)
    }
    for t, d in rcpts.items():
        p = repo / 'evidence' / 'c0' / t / 'receipt.json'
        p.parent.mkdir(parents=True)
        p.write_text(json.dumps(d))
    subprocess.check_call(['git', 'init', '-q'], cwd=str(repo))
    subprocess.check_call(['git', 'add', '-f', '.'], cwd=str(repo))
    subprocess.check_call(['git', '-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'fx'],
                          cwd=str(repo))
    return repo, g1


STALE = 'green_child_script_closure_changed:%s:scripts/fm_eq.tcl'


def t_synthetic():
    import rewrite_coverage as RC
    import coverage_three_axis as C3
    with tempfile.TemporaryDirectory() as tmp:
        repo, g1 = build_fixture(pathlib.Path(tmp))
        cv_certs = {'P'}
        cv_rcpts = {'R'}

        def cert_validate(t):
            return True if t in cv_certs else 'certificate:' + STALE % t

        def receipt_validate(t, rel, rec):
            if t in cv_rcpts:
                return {'variant': t, 'proof_mode': 'signoff-strict', 'proof_config': {},
                        'input_closure': {'golden': rec['golden_closure'], 'impl': rec['impl_closure']}}, None
            return None, STALE % t

        cur = PCUR.evaluate(repo, g1=g1, cert_validate=cert_validate, receipt_validate=receipt_validate,
                            defs_inst=PCUR.golden_graph(g1))
        tr = {m: cur.tier(m) for m in 'PTQRSUV'}
        tr['T2'] = cur.tier('T2')
        ck('(d) current-valid 证书 → PROVEN_DIRECT', tr['P'] == ('PROVEN_DIRECT', None), tr['P'])
        ck('(a) 脚本闭包过期的证书 → 不是 PROVEN_DIRECT', tr['T'][0] != 'PROVEN_DIRECT', tr['T'])
        ck('(b) 过期 + WB 成立 → PROVEN_IN_CONE(superseded_by=P)', tr['T'] == ('PROVEN_IN_CONE', 'P'), tr['T'])
        ck('(c) 过期 + 无白盒父 → NOT_CURRENT（原因保留）',
           tr['Q'][0] == 'NOT_CURRENT' and 'script_closure_changed' in tr['Q'][1], tr['Q'])
        ck('(b 反例 WB4) T2 的 rtl 字节与父闭包不同 → 不给 superseded', tr['T2'][0] == 'NOT_CURRENT', tr['T2'])
        ck('(e)(d) 只有 receipt、current-valid → PROVEN_DIRECT via receipt',
           tr['R'] == ('PROVEN_DIRECT', None) and cur.via['R'].startswith('receipt:evidence/'), (tr['R'], cur.via.get('R')))
        ck('(e)(b) 只有 receipt、过期、WB 成立 → PROVEN_IN_CONE(P)', tr['S'] == ('PROVEN_IN_CONE', 'P'), tr['S'])
        ck('(e)(c) 只有 receipt、过期、无白盒父 → NOT_CURRENT', tr['U'][0] == 'NOT_CURRENT', tr['U'])
        ck('无任何证明 → NO_PROOF', tr['V'] == ('NO_PROOF', None), tr['V'])

        # rewrite_coverage：台账绿判决集合按档切分
        claimed = {'P', 'T', 'Q', 'R', 'S', 'U', 'V'}
        prov, sup, dropped = RC.split_current(claimed, cur)
        ck('rewrite_coverage proven 只剩 current-valid（P、R）', prov == {'P', 'R'}, sorted(prov))
        ck('rewrite_coverage superseded = {T:P, S:P}，且不在 proven 里',
           sup == {'T': 'P', 'S': 'P'} and not (set(sup) & prov), sup)
        ck('rewrite_coverage dropped = Q/U/V（如实下降）', set(dropped) == {'Q', 'U', 'V'}, sorted(dropped))

        # 三轴轴二：Q 即便出现在某 current-valid 证明的 closure 候选里，也不许拿到 PROVEN_IN_CONE
        in_cone = {'T', 'S', 'Q'}
        a2 = {m: C3.axis2(m, set(), cur, in_cone, set()) for m in 'PTQRSUVX'}
        ck('三轴 (d) P → PROVEN_DIRECT / current_valid:certificate',
           a2['P'] == ('PROVEN_DIRECT', 'current_valid:certificate'), a2['P'])
        ck('三轴 (e) R → PROVEN_DIRECT / current_valid:receipt:…',
           a2['R'][0] == 'PROVEN_DIRECT' and a2['R'][1].startswith('current_valid:receipt:'), a2['R'])
        ck('三轴 (b) T → PROVEN_IN_CONE / superseded_by=P', a2['T'] == ('PROVEN_IN_CONE', 'superseded_by=P'), a2['T'])
        ck('三轴 (c) Q 在 closure 候选里也 → UNPROVEN / not_current',
           a2['Q'][0] == 'UNPROVEN' and a2['Q'][1].startswith('not_current:'), a2['Q'])
        ck('三轴 (c) U 被黑盒 → BLACKBOXED / not_current',
           C3.axis2('U', set(), cur, set(), {'U'})[0] == 'BLACKBOXED')
        ck('三轴 非证明根 X 在候选里 → PROVEN_IN_CONE / -',
           C3.axis2('X', set(), cur, {'X'}, set()) == ('PROVEN_IN_CONE', '-'))
        ck('三轴 vendor 压过一切', C3.axis2('P', {'P'}, cur, set(), set())[0] == 'VENDOR_BOUNDARY')

        # 父本身不 current-valid → 子也不得 superseded（WB1）
        cv_certs.clear()
        cur2 = PCUR.evaluate(repo, g1=g1, cert_validate=cert_validate, receipt_validate=receipt_validate,
                             defs_inst=PCUR.golden_graph(g1))
        ck('(WB1) 父 P 也过期 → T/S 都不 superseded', cur2.tier('T')[0] == 'NOT_CURRENT'
           and cur2.tier('S')[0] == 'NOT_CURRENT' and cur2.tier('P')[0] == 'NOT_CURRENT',
           (cur2.tier('T'), cur2.tier('S')))


# ---------------------------------------------------------------------------
# 二、真判据（真仓 HEAD）
# ---------------------------------------------------------------------------
def t_real():
    os.environ.setdefault('XSSV_HOME', str(REPO))
    import fm_verdict as fv
    import proof_certificate as PC
    ctx, err = fv._cert_ctx('HEAD')
    ck('真仓 cert ctx 可得', err is None, err)
    if err:
        return
    canon = (PCUR.G1 / 'CANONICAL_ID.txt').read_text().strip()

    def val(t, doc):
        return PC.validate_certificate_current(
            ctx['repo'], ctx['commit'], t, doc, expect_canonical=canon, policy=ctx['policy'],
            fm_targets=ctx['targets'], fm_targets_unresolved=ctx['unresolved'], g1_root=str(PCUR.G1))

    # (d)/(a) 证书
    good = None
    for t in PCUR.tracked_certs(REPO):
        doc, _sha, e = PC.load_certificate(ctx['repo'], ctx['commit'], t)
        if e is None and any(x['path'] == 'scripts/fm_eq.tcl' for x in doc['script_closure']['entries']) \
                and val(t, doc) is True:
            good = (t, doc)
            break
    ck('(d) 真仓找得到一张 current-valid 证书', good is not None)
    if good:
        t, doc = good
        bad = copy.deepcopy(doc)
        for x in bad['script_closure']['entries']:
            if x['path'] == 'scripts/fm_eq.tcl':
                x['sha256'] = ('0' if x['sha256'][0] != '0' else '1') + x['sha256'][1:]
        r = val(t, bad)
        ck('(a) 真判据：%s 证书改 fm_eq.tcl 脚本闭包 sha → script_closure_changed' % t,
           isinstance(r, str) and 'script_closure_changed' in r and 'fm_eq.tcl' in r, r)

    # (e) 只有 receipt 的根
    certs = set(PCUR.tracked_certs(REPO))
    rc = PCUR.tracked_green_receipts(REPO)
    pick = None
    for t in sorted(rc):
        if t in certs:
            continue
        rel, rec = rc[t][0]
        if PCUR.receipt_prefilter(ctx, rec, (REPO / rel).parent) is not None:
            continue
        doc, why = PCUR.validate_receipt(ctx, canon, (REPO / rel).parent, rec, PCUR.G1, REPO)
        if doc is not None:
            pick = (t, rel, rec)
            break
    ck('(e) 真仓找得到一份 current-valid 的只有 receipt 的根', pick is not None)
    if not pick:
        return
    t, rel, rec = pick
    with tempfile.TemporaryDirectory() as tmp:
        src = (REPO / rel).parent
        dst = pathlib.Path(tmp) / 'run' / t
        shutil.copytree(str(src), str(dst))
        shutil.copy(str(src.parent / 'RUN_CONTEXT.tsv'), str(dst.parent / 'RUN_CONTEXT.tsv'))
        doc, why = PCUR.validate_receipt(ctx, canon, dst, rec, PCUR.G1, REPO)
        ck('(e) 真判据：%s（只有 receipt）原样副本 → current-valid' % t, doc is not None, why)
        scl = dst / 'sidecar' / 'script_closure.list'
        lines = scl.read_text().splitlines()
        hit = False
        for i, ln in enumerate(lines):
            c = ln.split('\t')
            if len(c) == 3 and c[0].endswith('scripts/fm_eq.tcl'):
                c[2] = ('0' if c[2][0] != '0' else '1') + c[2][1:]
                lines[i] = '\t'.join(c)
                hit = True
        scl.write_text('\n'.join(lines) + '\n')
        ck('(e) 副本里找到了 fm_eq.tcl 行可改', hit)
        doc, why = PCUR.validate_receipt(ctx, canon, dst, rec, PCUR.G1, REPO)
        ck('(e)(a) 真判据：receipt 的 fm_eq.tcl 脚本闭包 sha 改一位 → script_closure_changed',
           doc is None and 'script_closure_changed' in (why or '') and 'fm_eq.tcl' in (why or ''), why)
        doc, derr = PCUR._derive_from_receipt(REPO, dst, PCUR.G1)
        r = val(t, doc) if doc is not None else derr
        ck('(e)(a) 绕过预筛、直接派生 + validate_certificate_current 也 → script_closure_changed',
           isinstance(r, str) and 'script_closure_changed' in r, r)


def main():
    print('一、口径接线（合成仓）')
    t_synthetic()
    if '--quick' not in sys.argv:
        print('二、真判据（真仓 HEAD）')
        t_real()
    print('test_ledger_current_valid: %d 条，失败 %d' % (N[0], len(FAILS)))
    return 1 if FAILS else 0


if __name__ == '__main__':
    sys.exit(main())
