#!/usr/bin/env python3
"""test_child_composition.py —— 组合性绑定负测（codex 0141 §29 → codex 0157 D57 重写）。

要证明的事**没变**：child 被证明过的 impl 字节，若在父 commit 下被改了一个字节，
父 proof 必须拒绝复用该 child 的背书。

变的是背书从哪儿来。原版把一份 `evidence/**/receipt.json` 改一位、重建
`docs/receipt_index.tsv`、再跑 `make_receipt.py`。D57 之后：

  * `evidence/` 与 `docs/receipt_index.tsv` 都在 .gitignore 里，clean clone 下原版
    **三条断言一条都跑不起来**（实测 0/3，报 "无可用 TageTable 证据"）；
  * `make_receipt.py` 已改读 tracked 的 `verif/proof_certificates/<child>.json`，
    原版改 receipt 的做法根本碰不到现在的判据 —— 更糟的是它的通过判据只查
    "原因里有没有 green_child"，而新路径在没有证书时也会报一个带 green_child 的原因，
    于是原版会**因为完全无关的理由报 PASS**。这正是本工程反复栽的"测试假通过"。

所以这里改成：用 `test_proof_certificate.Fixture` 造一个自带 git 历史的最小仓库
（clean clone 下也能跑），驱动**真的 `make_receipt.py` 子进程**，验四件事：

  CONTROL  证书有效 → make_receipt 正常出 receipt（rc=0），
           且 receipt 里记下了 green_child_closure_checks。
  A        child 源在父 commit 下改了一个字节 → 拒绝，原因 closure_changed
  B        child 闭包条目在父 commit 下不存在   → 拒绝，原因 closure_missing_at_parent
  C        证书没进 commit（只躺在工作树里）   → 拒绝，原因 certificate_not_in_commit

每条都断言**具体原因关键字**，不是"原因里有 green_child 就算过"。
CONTROL 不过 = 夹具没走到判据，整体判失败。

用法: python3 scripts/test_child_composition.py
"""
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))

import test_proof_certificate as T                          # noqa: E402

RESULTS = []


def _prep_workdir(fx):
    wd = fx.root / 'work'
    (wd / 'sidecar').mkdir(parents=True, exist_ok=True)
    facts = {'schema': 'fm-sidecar-native-v1', 'run_id': 'parent-run-1',
             'top': 'ParentAsm', 'native_verdict': 'SUCCEEDED',
             'stats': {'passing': 9, 'failing': 0}, 'unmatched': {}}
    (wd / 'sidecar' / 'native_facts.json').write_text(json.dumps(facts))
    return wd, facts


def run_make_receipt(fx, allow_dirty=False):
    wd, facts = _prep_workdir(fx)
    verdict = 'SUCCEEDED\t' + json.dumps({'native': 'SUCCEEDED'})
    env = dict(os.environ, XSSV_HOME=str(fx.repo_dir), G1_CANONICAL=str(fx.g1))
    env.pop('XSSV_INDEX_HOME', None)
    argv = [
        sys.executable, str(HERE / 'make_receipt.py'),
        '--top', 'ParentAsm', '--workdir', str(wd),
        '--ref-srcs', str(fx.g1 / 'golden-rtl' / 'ChildLeaf.sv'),
        '--impl-srcs', str(fx.repo_dir / 'rtl' / 'common' / 'ChildLeaf.sv'),
        '--mode', 'assembly', '--rc', '0', '--verdict', verdict,
        '--expect-run-id', facts['run_id'], '--parent-commit', fx.parent_commit,
    ]
    if allow_dirty:
        argv.append('--allow-dirty')
    r = subprocess.run(argv, env=env, cwd=str(fx.repo_dir), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True)
    return r.returncode, r.stdout, wd


def case(name, fx, expect_rc_nonzero, keyword=None, allow_dirty=False):
    rc, out, wd = run_make_receipt(fx, allow_dirty)
    if expect_rc_nonzero:
        if rc == 0:
            print('  BAD  %s: make_receipt 竟然放行了（rc=0）' % name)
            print('       %s' % out.strip().splitlines()[-1:] or out[:200])
            RESULTS.append(False)
            return
        ok = keyword in out
        print('  %s %s: rc=%d %s' % ('ok ' if ok else 'BAD', name, rc,
                                     [l for l in out.splitlines() if 'ERROR' in l][:1]))
        if not ok:
            print('       期望原因含 %r，实际输出：\n%s' % (keyword, out[-600:]))
        RESULTS.append(ok)
    else:
        recp = wd / 'receipt.json'
        ok = rc == 0 and recp.exists()
        detail = ''
        if ok:
            d = json.loads(recp.read_text())
            checks = d.get('green_child_closure_checks') or []
            ok = bool(checks) and checks[0].get('child_target') == 'ChildLeaf' \
                and checks[0].get('child_impl_files_verified_at_parent_commit', 0) > 0
            detail = 'green_child_closure_checks=%r' % checks
        print('  %s %s[CONTROL]: rc=%d %s' % ('ok ' if ok else 'BAD', name, rc,
                                              detail if ok else out[-500:]))
        RESULTS.append(ok)


def main():
    if shutil.which('git') is None:
        print('SKIP: 没有 git')
        return 2

    case('证书有效', T.Fixture(), expect_rc_nonzero=False)

    def change_src(fx):
        (fx.repo_dir / 'rtl/common/xs_child_core.sv').write_text(
            'module xs_child_core; wire tampered; endmodule\n')
    case('child 源在父 commit 下改了一个字节', T.Fixture(post_commit=change_src),
         True, 'green_child_closure_changed')

    def rm_src(fx):
        (fx.repo_dir / 'rtl/common/xs_child_core.sv').unlink()
    case('child 闭包条目在父 commit 下不存在', T.Fixture(post_commit=rm_src),
         True, 'green_child_closure_missing_at_parent')

    # ★这条要**显式打开 dirty 闸**才测得到。未提交的证书文件本身就让工作树 dirty，
    # 于是 make_receipt 会先在 dirty 闸上退出——第一版就这样，本测试如实报了 BAD
    # （"期望原因含 green_child_certificate_not_in_commit，实际是 impl 工作树 dirty"），
    # 没有把"被更早的门拦下"冒充成"抓到了"。这里给 --allow-dirty 放过前一道闸，
    # 断言仍然钉在具体关键字上，所以不会因为换了个理由失败就算过。
    case('证书没进 commit（只躺在工作树里）', T.Fixture(commit_cert=False),
         True, 'green_child_certificate_not_in_commit', allow_dirty=True)

    for d in T._TMPDIRS:
        shutil.rmtree(str(d), ignore_errors=True)
    print('\n%d/%d 通过' % (sum(RESULTS), len(RESULTS)))
    if len(RESULTS) != 4:
        print('★断言条数 %d != 4 —— 有用例没跑到，判失败' % len(RESULTS))
        return 1
    return 0 if all(RESULTS) else 1


if __name__ == '__main__':
    sys.exit(main())
