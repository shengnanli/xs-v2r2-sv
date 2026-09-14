#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""proof_status.py —— 「这个 target 的 proof status 是什么」的**单一实现**（codex 0153 D66）。

## 为什么要有这个文件

在此之前 `scripts/g1_universe.py` 的 status 列有两个来源：

  docs/fastlane_ledger.tsv    tracked，append-only 的**工作台账**（WORKING_PASS…）
  docs/receipt_index.tsv      ★untracked★（.gitignore:22），由 untracked 的
                              evidence/**/receipt.json 机械派生 → REVALIDATED_*

后者是权威 status 的来源，而它在 clean clone 里**根本不存在**。实测（见报告）：
同一个 commit、同一条命令，主树（有 receipt_index）产出 118 行 REVALIDATED_PASS，
clean worktree（无 receipt_index）产出 0 行 —— 冻结表的字节取决于一份没人跟踪的文件。

D66 的裁定：

  * `g1_universe.tsv`/configured universe **只冻结设计身份、G0↔G1 映射、层次角色、
    fingerprint、scope 与 proof obligation**；
  * 正式 proof status **只由 tracked `verif/proof_certificates/*.json` 派生**；
  * **clean clone 无证书时，正确状态就是 `UNVERIFIED`**，不是试图复原旧绿；
  * `docs/receipt_index.tsv` 可以再生，但**不是输入真相**。

所以本模块只认 tracked 证书，别的一概不看。

## 状态取值（四个，全部 fail-closed）

  VERIFIED       tracked 证书存在、通过 proof_certificate.validate_document 的
                 schema 层校验、verdict ∈ POLICY.qualifying_verdicts、
                 且 impl_commit == POLICY.freeze_commit。
  CERT_REJECTED  证书在、schema 也过，但不足以放行（verdict 不合格 /
                 freeze_commit 为 null / impl_commit 对不上 / 文件名与 target 不符）。
  CERT_INVALID   证书在，但 schema 层就没过 —— 这是仓库缺陷，必须响，不许静默成
                 「没有证书」。
  UNVERIFIED     没有 tracked 证书。**clean clone 的正确答案**。

★只有 VERIFIED 算证明过★。其余三个都是「没证明」，区别只在于为什么。

## 两条刻意的设计

 1. **trackedness 由 `git ls-files` 判定**，不是 `os.listdir`。
    往工作树里丢一份 untracked 的 `verif/proof_certificates/X.json` 不会让 X 变绿
    （与 scripts/test_proof_certificate.py:576 那条「untracked receipt_index 不得转绿」
    同一条纪律）。
 2. **schema 校验直接调 `proof_certificate.validate_document`**，不另写一份。
    证书 owner 改了 schema，本模块跟着改，不会各判各的。
    证书内容按**工作树字节**读，并把 sha256 写进 note —— 证书改一个字节，
    冻结表的字节就变，`--check` 立刻响。

## 复跑

    python3 scripts/proof_status.py --repo <repo>
"""
from __future__ import print_function

import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import proof_certificate as PC                                     # noqa: E402

CERT_DIR = 'verif/proof_certificates'
#: 证书目录里**不是证书**的文件（策略与 schema 自身）。
NON_CERT = ('POLICY.json', 'schema-v1.json')

VERIFIED = 'VERIFIED'
CERT_REJECTED = 'CERT_REJECTED'
CERT_INVALID = 'CERT_INVALID'
UNVERIFIED = 'UNVERIFIED'

#: 唯一表示「证明过」的状态。任何闸都必须按这个集合判，不许自己列字符串。
PROVEN = frozenset([VERIFIED])
ALL_STATES = (VERIFIED, CERT_REJECTED, CERT_INVALID, UNVERIFIED)


class PolicyError(Exception):
    """fail-closed：策略读不到/坏了一律抛出，绝不当成「没有策略所以放行」。"""


def _git_tracked(repo, subdir):
    """`git ls-files -- <subdir>` 的结果。git 不可用 → None（调用方 fail-closed）。"""
    try:
        p = subprocess.run(['git', 'ls-files', '--', subdir], cwd=str(repo),
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except (OSError, ValueError):
        return None
    if p.returncode != 0:
        return None
    return [ln for ln in p.stdout.decode('utf-8', 'replace').splitlines() if ln.strip()]


def load_policy(repo):
    """读 tracked 的 POLICY.json。缺失/不可解析 → PolicyError（fail-closed）。"""
    p = pathlib.Path(repo) / CERT_DIR / 'POLICY.json'
    if not p.exists():
        raise PolicyError('证书策略不存在: %s（fail-closed：没有策略不等于放行）' % p)
    try:
        pol = json.loads(p.read_text())
    except ValueError as e:
        raise PolicyError('证书策略不可解析: %s: %s' % (p, e))
    errs = PC.validate_policy(pol)
    if errs:
        raise PolicyError('证书策略不合法: %s' % errs[0])
    return pol


def certificate_files(repo):
    """tracked 的证书文件列表 [(target, 相对路径)]。

    ★只认 `git ls-files`★ —— 工作树里放一份 untracked 证书不会被当成证书。
    """
    repo = pathlib.Path(repo)
    tracked = _git_tracked(repo, CERT_DIR)
    if tracked is None:
        raise PolicyError('git ls-files 不可用（repo=%s）—— 无法判定证书是否 tracked，'
                          'fail-closed' % repo)
    out = []
    for rel in sorted(tracked):
        name = rel.rsplit('/', 1)[-1]
        if not name.endswith('.json') or name in NON_CERT:
            continue
        out.append((name[:-len('.json')], rel))
    return out


def status_map(repo):
    """{target: (status, note)} —— 只含**有 tracked 证书**的 target。

    没有证书的 target 不出现在这里；调用方一律按 `UNVERIFIED` 处理
    （见 `status_of`）。
    """
    repo = pathlib.Path(repo)
    pol = load_policy(repo)
    qualify = set(pol.get('qualifying_verdicts') or ())
    freeze = pol.get('freeze_commit')
    out = {}
    for target, rel in certificate_files(repo):
        path = repo / rel
        try:
            raw = path.read_bytes()
        except OSError as e:
            out[target] = (CERT_INVALID, 'certificate_unreadable:%s' % type(e).__name__)
            continue
        sha = hashlib.sha256(raw).hexdigest()
        stamp = '%s sha256=%s' % (rel, sha[:16])
        try:
            doc = json.loads(raw.decode('utf-8'))
        except (ValueError, UnicodeDecodeError):
            out[target] = (CERT_INVALID, 'certificate_unparsable; %s' % stamp)
            continue
        errs = PC.validate_document(doc)
        if errs:
            out[target] = (CERT_INVALID, '%s; %s' % (errs[0], stamp))
            continue
        # 文件名即 target 名 —— 不允许一份证书挂到别的名字上（串位的老形态）
        if doc.get('target') != target:
            out[target] = (CERT_REJECTED,
                           'certificate_target_mismatch:doc=%s; %s'
                           % (doc.get('target'), stamp))
            continue
        if doc.get('verdict') not in qualify:
            out[target] = (CERT_REJECTED,
                           'verdict_not_qualifying:%s; %s' % (doc.get('verdict'), stamp))
            continue
        # POLICY.freeze_commit 为 null 时一律拒绝放行（POLICY.json 自己写死的语义：
        # 「宁可全红，也不能因为没人填这一格就默认放行」）。
        if not freeze:
            out[target] = (CERT_REJECTED, 'policy_freeze_commit_null; %s' % stamp)
            continue
        if doc.get('impl_commit') != freeze:
            out[target] = (CERT_REJECTED,
                           'impl_commit_not_freeze_commit:%s; %s'
                           % (str(doc.get('impl_commit'))[:12], stamp))
            continue
        out[target] = (VERIFIED, 'certificate %s verdict=%s' % (stamp, doc['verdict']))
    return out


def status_of(smap, target):
    """没有证书 = UNVERIFIED。**clean clone 的正确答案就是这个**。"""
    return smap.get(target, (UNVERIFIED, 'no tracked certificate'))


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent))
    a = ap.parse_args(argv)
    try:
        pol = load_policy(a.repo)
        smap = status_map(a.repo)
    except PolicyError as e:
        sys.stderr.write('POLICY ERROR (fail-closed): %s\n' % e)
        return 2
    print('# repo=%s' % a.repo)
    print('# POLICY.freeze_commit=%s  qualifying_verdicts=%s'
          % (pol.get('freeze_commit'), pol.get('qualifying_verdicts')))
    print('# tracked 证书 %d 份' % len(smap))
    for t in sorted(smap):
        print('%s\t%s\t%s' % (t, smap[t][0], smap[t][1]))
    if not smap:
        print('# （无 tracked 证书 —— 所有 target 的正确 proof status 是 %s）' % UNVERIFIED)
    return 0


if __name__ == '__main__':
    sys.exit(main())
