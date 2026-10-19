#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""oldcert_triage.py —— 非 current-valid 证书的用途分类（codex 0242 裁定 3）。

只读：不改证书、不改 current-valid 判据、不改任何台账；只产出一张新表 docs/oldcert_triage.tsv。

## 它回答什么

对 HEAD 上每张 tracked 证书，用与 batch_reproof validate / green_child **同一个**判据
（fm_verdict._child_cert_current → proof_certificate.validate_certificate_current）复核。
对其中不通过的每一张，机械地查三件事：

  (i)  覆盖率台账是否引用它：
         rewrite_coverage.proven_modules() 的来源（docs/fm_round_*.tsv SUCCEEDED/PASS_DEAD_REF、
         docs/fastlane_ledger.tsv WORKING_PASS*）按目标名命中；
         docs/coverage_three_axis.tsv 的 formal_coverage 列；已跟踪绿 receipt 份数；
         verif/proven_in_cone_verified.tsv 是否有该模块的行。
  (ii) 是否被别的证明依赖（依赖边 = 父证书 allow 里 class=green_child 的 child_target，
       父证书 impl 闭包里挂的 golden-rtl/<T>.sv（validate_impl_golden_certified 的递归边），
       以及 verif/allow/*.json 里尚无证书的父目标的 green_child 声明）。
  (iii) 是否已被一个 **current-valid** 父证明在白盒里覆盖（WB 判据，五条全满足才算）：
       WB1 父证书 current-valid（同一判据 True）；
       WB2 在 G1 golden 例化图里，从父 variant 出发、只走父 golden 闭包里定义的模块、
           在父 allow 声明的 design 处截断，能到达 T（= T 在父证明的 ref 侧被例化、未被黑盒）；
       WB3 父 golden 闭包里 golden-rtl/T.sv 的 sha256 == T 证书记录的那份；
       WB4 T 证书 impl 闭包里所有 kind=repo、路径在 rtl/ 下的文件（path+sha256）⊆ 父 impl 闭包，
           且父 impl 闭包里没有 kind=golden 的 golden-rtl/T.sv（impl 侧不是 golden 复用）；
       WB5 父 proof_mode=signoff-strict（strict 判据本身拒绝任何黑盒）或 assembly 且 T 不在父 allow 的
           design 集合里；
       WB6 父 impl 闭包的 rtl/ 文件里有对 module T 的例化语句（impl 侧确实用了重写的 T）。
       ★WB2 是"被例化"的结构证据，不是 compare point 落点证据★——它说明 T 的两侧实现在父证明里被
       整体展开比较，不说明 T 的每个输出都是父的 compare point（被父常量化/未连的端口不受验）。
       这一点在报告里如实写明，故 HISTORICAL 只用于「从 current-valid 计数中排除」，不用于给覆盖率加分。

## 分类

  REQUIRED    有处于活跃状态的依赖方（依赖方本身 current-valid 或本身 REQUIRED），
              或 (iii) 不成立且 (i) 有引用 —— 必须按叶到父补证。
  HISTORICAL  (iii) 成立（至少一个 current-valid 父白盒覆盖），且没有活跃依赖方 ——
              该证书标历史/过期，从 current-valid 计数中排除；排除依据 = whitebox_parent 列。
  ORPHAN      (i)(ii)(iii) 都不成立（不被任何东西用）。
  （证书目录里的 schema-v1.json / POLICY.json 不是证书，不进表；把 schema-v1 列进 validate 名单
   会得到 green_child_not_fm_target:schema-v1 —— 那是名单制作伪影，不是证书失效。）

用法：
  python3 scripts/oldcert_triage.py [--out docs/oldcert_triage.tsv] [--validate-cache <batch_reproof validate 输出>]
  python3 scripts/oldcert_triage.py --summary   # 只打印统计
"""
import argparse
import collections
import glob
import json
import os
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
G1 = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical'))
CERT_DIR = REPO / 'verif' / 'proof_certificates'
NON_CERT = ('POLICY', 'schema-v1')

def git(*a):
    return subprocess.check_output(['git', '-C', str(REPO)] + list(a)).decode()


def tracked_certs():
    out = []
    for p in git('ls-files', 'verif/proof_certificates/*.json').split():
        t = pathlib.Path(p).stem
        out.append(t)
    return sorted(out)


def validate_all(certs, cache=None):
    """t -> True | 原因串。cache = batch_reproof validate 的输出文件（同一判据，省 2 分钟）。"""
    if cache:
        res = {}
        for ln in open(cache):
            c = ln.rstrip('\n').split('\t')
            if len(c) == 2 and not ln.startswith('=='):
                res[c[0]] = True if c[1] == 'True' else c[1]
        miss = [t for t in certs if t not in res and t not in NON_CERT]
        if miss:
            raise SystemExit('validate cache 缺 %d 个证书（%s…）——不许拿旧缓存充数' % (len(miss), miss[:3]))
        return res
    sys.path.insert(0, str(REPO / 'scripts'))
    os.environ.setdefault('XSSV_HOME', str(REPO))
    import fm_verdict as fv
    head = git('rev-parse', 'HEAD').strip()
    ctx, err = fv._cert_ctx(head)
    if err:
        raise SystemExit('cert ctx: %s' % err)
    canon = (G1 / 'CANONICAL_ID.txt').read_text().strip()
    return {t: fv._child_cert_current(ctx, t, canon) for t in certs if t not in NON_CERT}


# WB1–WB6 的实现已抽到 scripts/proof_currency.py（ledger-cv lane），与覆盖率台账共用同一份。
from proof_currency import golden_graph, needed_impl, allow_of, WhiteBox  # noqa: E402


def golden_lines(fname):
    p = G1 / 'golden-rtl' / fname
    try:
        with open(p, 'rb') as f:
            return sum(1 for _ in f)
    except OSError:
        return 0


def load_docs(certs):
    docs = {}
    for t in certs:
        if t in NON_CERT:
            continue
        docs[t] = json.loads((CERT_DIR / (t + '.json')).read_text())
    return docs


def coverage_refs():
    rc = collections.defaultdict(set)
    for rnd in sorted((REPO / 'docs').glob('fm_round_*.tsv')):
        for l in rnd.read_text(errors='replace').splitlines():
            if l.startswith('#') or l.startswith('target'):
                continue
            c = l.split('\t')
            if len(c) > 1 and c[1] in ('SUCCEEDED', 'PASS_DEAD_REF'):
                rc[c[0]].add(rnd.name)
    led = REPO / 'docs' / 'fastlane_ledger.tsv'
    for l in led.read_text(errors='replace').splitlines():
        c = l.split('\t')
        if not l.startswith('#') and len(c) > 1 and c[1] in ('WORKING_PASS', 'WORKING_PASS_DEAD_REF'):
            rc[c[0]].add(led.name)
    axis = {}
    for l in (REPO / 'docs' / 'coverage_three_axis.tsv').read_text().splitlines():
        c = l.split('\t')
        if not l.startswith('#') and len(c) >= 3:
            axis[c[0]] = c[2]
    rcpt = collections.Counter()
    for rel in git('ls-files', 'evidence/*/receipt.json').split():
        parts = rel.split('/')
        try:
            d = json.loads((REPO / rel).read_text())
        except Exception:
            continue
        if d.get('verdict') in ('SUCCEEDED', 'PASS_DEAD_REF'):
            rcpt[parts[2]] += 1
    pic = collections.defaultdict(list)
    for l in (REPO / 'verif' / 'proven_in_cone_verified.tsv').read_text().splitlines():
        c = l.split('\t')
        if not l.startswith('#') and len(c) > 1:
            pic[c[0]].append(c[1])
    return rc, axis, rcpt, pic


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(REPO / 'docs' / 'oldcert_triage.tsv'))
    ap.add_argument('--validate-cache')
    ap.add_argument('--summary', action='store_true')
    a = ap.parse_args()

    certs = tracked_certs()
    val = validate_all(certs, a.validate_cache)
    docs = load_docs(certs)
    defs, inst = golden_graph()
    rc, axis, rcpt, pic = coverage_refs()

    # ---- 依赖边 parent -> child ------------------------------------------------
    deps = collections.defaultdict(set)          # child -> {(parent, kind)}
    allows = {}
    for p, d in docs.items():
        al = allow_of(d)
        allows[p] = al
        for o in (al or {}).get('objects') or []:
            if o.get('class') == 'green_child' and o.get('child_target'):
                deps[o['child_target']].add((p, 'green_child'))
        for e in d['input_closure']['impl']:
            if e.get('kind') == 'golden':
                m = os.path.basename(e['path'])[:-3]
                if m in docs and m != p:
                    deps[m].add((p, 'impl_golden'))
    for f in sorted((REPO / 'verif' / 'allow').glob('*.json')):
        p = f.stem
        if p in docs:
            continue
        try:
            al = json.loads(f.read_text())
        except Exception:
            continue
        for o in al.get('objects') or []:
            if o.get('class') == 'green_child' and o.get('child_target'):
                deps[o['child_target']].add((p, 'green_child_nocert'))

    bad = sorted(t for t in docs if val.get(t) is not True)

    # ---- (iii) 白盒父 ---------------------------------------------------------
    good = [p for p in docs if val.get(p) is True]
    wbx = WhiteBox({p: docs[p] for p in good}, defs, inst, REPO,
                   allows={p: allows[p] for p in good})
    pinfo = wbx.pinfo

    def wb_parents(t):
        return wbx.parents_of(t, docs[t])

    def nocert_superseded(p):
        """无证书的父目标 P（只在 verif/allow 里有 green_child 声明）是否已被 current-valid 父白盒覆盖：
        某 current-valid 父 Q 的 golden 闭包含 golden-rtl/P.sv、impl 闭包含定义 module P 的 rtl/ 文件
        且不挂 golden P.sv、P 在 Q 的 golden 例化图里可达（strict，或 assembly 且 P 不在 Q 的 allow 里）。
        成立 ⇒ P 的 allow 声明没有任何 current-valid 证明在用，不构成活跃依赖。返回 Q 或 None。"""
        pf = defs.get(p)
        if not pf:
            return None
        for q in sorted(good, key=lambda q: (len(pinfo[q][0]), q)):
            gfiles, impl, implg, cut, mode, var = pinfo[q]
            if pf not in gfiles or pf in implg:
                continue
            if mode not in ('signoff-strict', 'assembly') or p in cut:
                continue
            if not any(path.startswith('rtl/') and re.search(r'^\s*module\s+%s\b' % re.escape(p),
                                                             (REPO / path).read_text(errors='replace'), re.M)
                       for path, _s in impl if os.path.basename(path) == p + '.sv'):
                continue
            if p in wbx.reach_of(q):
                return q
        return None

    nocert_sup = {}
    rows = {}
    for t in bad:
        d = docs[t]
        wb = wb_parents(t)
        rows[t] = dict(
            target=t, ut=d['ut_dir'], variant=d['variant'], mode=d['proof_mode'], verdict=d['verdict'],
            passing=str(d['native_result']['stats'].get('passing')),
            reason=str(val.get(t)).replace('certificate:', ''),
            glines=golden_lines(defs.get(d['variant'], d['variant'] + '.sv')),
            cov=';'.join(filter(None, [
                ('round:' + ','.join(sorted(rc[t]))) if rc.get(t) else '',
                ('axis2:' + axis[t]) if t in axis else 'axis2:-',
                'receipts:%d' % rcpt.get(t, 0),
                ('in_cone_verified:' + ','.join(pic[t])) if pic.get(t) else ''])),
            cov_ref=bool(rc.get(t)) or axis.get(t, '').startswith('PROVEN_DIRECT'),
            deps=sorted(deps.get(t, ())), wb=wb)

    # 活跃依赖方：依赖方 current-valid，或依赖方本身 REQUIRED（不动点）
    cat = {}
    changed = True
    while changed:
        changed = False
        for t, r in rows.items():
            active = []
            for p, k in r['deps']:
                if k == 'green_child_nocert':
                    if p not in nocert_sup:
                        nocert_sup[p] = nocert_superseded(p)
                    if nocert_sup[p] is None:
                        active.append(p)
                elif val.get(p) is True or cat.get(p) == 'REQUIRED':
                    active.append(p)
            if active:
                c = 'REQUIRED'
            elif r['wb']:
                c = 'HISTORICAL'
            elif r['cov_ref']:
                c = 'REQUIRED'
            else:
                c = 'ORPHAN'
            if cat.get(t) != c:
                cat[t] = c
                changed = True
            r['active'] = active

    cv_lines = sum(golden_lines(defs.get(docs[p]['variant'], docs[p]['variant'] + '.sv')) for p in good)
    hdr = ['target', 'ut_dir', 'variant', 'proof_mode', 'cert_verdict', 'cert_passing', 'fail_reason',
           'golden_lines', 'coverage_refs', 'dependents', 'whitebox_parent', 'n_whitebox_parents',
           'category', 'action']
    lines = [
        '# oldcert_triage.tsv —— HEAD 上非 current-valid 证书的用途分类（codex 0242 裁定 3）',
        '# 机械生成：python3 scripts/oldcert_triage.py（判据见脚本 docstring；勿手改）',
        '# validate 基于 HEAD %s（生成时）；tracked 证书 %d 张，current-valid %d，非 current-valid %d' % (
            git('rev-parse', 'HEAD').strip()[:12], len(docs), len(good), len(bad)),
        '# golden 行（每证书 variant 所在 G1 文件行数，按证书计、变体各算）：current-valid %d' % cv_lines,
        '# whitebox_parent = 满足 WB1-WB6 的最近 current-valid 父（golden 闭包最小者）；'
        'n_whitebox_parents = 满足者总数',
        '\t'.join(hdr)]
    stat = collections.Counter()
    for t in sorted(rows, key=lambda x: (cat[x], x)):
        r = rows[t]
        c = cat[t]
        stat[c] += 1
        if c == 'HISTORICAL':
            act = 'exclude_from_current_valid(superseded_by=%s)' % r['wb'][0]
        elif c == 'REQUIRED':
            act = 'reproof'
        else:
            act = 'none'
        dep = ','.join('%s(%s%s%s)' % (p, k, ',cv' if val.get(p) is True else '',
                                       (',superseded_by=%s' % nocert_sup[p]) if nocert_sup.get(p) else '')
                       for p, k in r['deps']) or '-'
        lines.append('\t'.join([t, r['ut'], r['variant'], r['mode'], r['verdict'], r['passing'],
                                r['reason'], str(r['glines']), r['cov'], dep,
                                r['wb'][0] if r['wb'] else '-', str(len(r['wb'])), c, act]))
    if a.summary:
        print(dict(stat))
        return 0
    pathlib.Path(a.out).write_text('\n'.join(lines) + '\n')
    gl = collections.Counter()
    for t, r in rows.items():
        gl[cat[t]] += r['glines']
    print('写出 %s：%s；golden 行 %s；current-valid %d 张 / golden 行 %d' % (
        a.out, dict(stat), dict(gl), len(good), cv_lines))
    return 0


if __name__ == '__main__':
    sys.exit(main())
