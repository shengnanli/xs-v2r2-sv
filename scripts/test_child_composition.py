#!/usr/bin/env python3
"""test_child_composition.py —— 组合性绑定负测（codex 0141 §29）。

要证明的事：child receipt 证过的 impl 字节，若在父 commit 下被改了一个字节，
父 proof 必须拒绝复用该 child receipt。

做法（不跑 FM，只测 make_receipt 的绑定逻辑）：
  1. 取一份真实 child receipt，把其中某个 impl 闭包条目的 sha256 改掉一位
     （等价于"父 commit 下的字节与 child 证过的不一致"）；
  2. 让 make_receipt 以该 child 为 green_child 出父 receipt → 必须非零退出并报
     child receipt 失效；
  3. 另测"条目路径在父 commit 下不存在"同样必须拒。
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
# reviewer 环境反馈：/tmp 上 shutil.copytree 会因复制 ACL/xattr 报 Errno 22，
# 导致三条断言根本没执行却"通过"（第二次栽在同一个测试上）。
# 对策：① fixture 建在仓库内的可写临时目录；② 所有复制用 copyfile（只搬字节，
# 不碰元数据）；③ 末尾校验"每条用例确实跑到了判定"，跑不到即 FAIL。
FIXTURE_ROOT = REPO / '.test_tmp' 


def newest_evidence():
    cands = sorted(REPO.glob('evidence/*/TageTable/receipt.json'),
                   key=lambda p: p.stat().st_mtime)
    return cands[-1].parent if cands else None


def run_case(name, mutate, expect_fail=True):
    ev = newest_evidence()
    if ev is None:
        print(f'  BAD  {name}: 无可用 TageTable 证据 —— 断言未执行（不算通过）')
        return False
    FIXTURE_ROOT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=str(FIXTURE_ROOT)) as td:
        td = pathlib.Path(td)
        # 复制整份证据树到临时索引根，只改 child receipt
        # 只搬判定需要的字节：证据树里的 receipt.json + verif/allow。
        # 一律 copyfile（不复制权限/ACL/xattr），避免跨文件系统的 Errno 22。
        for rp in (REPO / 'evidence').glob('*/*/receipt.json'):
            dst = td / rp.relative_to(REPO)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(str(rp), str(dst))
        (td / 'docs').mkdir(exist_ok=True)
        (td / 'verif' / 'allow').mkdir(parents=True, exist_ok=True)
        for ap_ in (REPO / 'verif' / 'allow').glob('*.json'):
            shutil.copyfile(str(ap_), str(td / 'verif' / 'allow' / ap_.name))
        (td / 'scripts').mkdir(exist_ok=True)
        for f in ('build_receipt_index.py',):
            shutil.copyfile(str(REPO / 'scripts' / f), str(td / 'scripts' / f))
        # 找 WrBypass child receipt 并改
        target = sorted((td / 'evidence').glob('*/WrBypass/receipt.json'))
        if not target:
            print(f'  BAD  {name}: 无 WrBypass child receipt —— fixture 没建起来，'
                  f'断言未执行（不算通过）')
            return False
        for tp in target:
            d = json.loads(tp.read_text())
            mutate(d)
            tp.write_text(json.dumps(d))
        # 重建索引（指向临时根）
        env = dict(os.environ, XSSV_HOME=str(td), XSSV_INDEX_HOME=str(td))
        subprocess.run([sys.executable, str(td / 'scripts' / 'build_receipt_index.py')],
                       env=env, stdout=subprocess.DEVNULL)
        # 用真实父证据 + 临时索引跑 make_receipt
        wd = td / 'work'; (wd / 'sidecar').mkdir(parents=True)
        shutil.copyfile(str(ev / 'sidecar' / 'native_facts.json'),
                        str(wd / 'sidecar' / 'native_facts.json'))
        facts = json.loads((wd / 'sidecar' / 'native_facts.json').read_text())
        head = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=str(REPO),
                              stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
        verdict = 'PASS_DEAD_REF\t' + json.dumps({'native': facts['native_verdict']})
        r = subprocess.run([
            sys.executable, str(REPO / 'scripts' / 'make_receipt.py'),
            '--top', 'TageTable', '--workdir', str(wd),
            '--ref-srcs', str(REPO / '..' / 'G1-canonical' / 'golden-rtl' / 'TageTable.sv'),
            '--impl-srcs', str(REPO / 'rtl' / 'frontend' / 'TageTable.sv'),
            '--mode', 'assembly', '--rc', '0', '--verdict', verdict,
            '--expect-run-id', facts['run_id'], '--parent-commit', head,
            # 本测试要验的是**组合性闸**，故放过 dirty 闸，否则 dirty 会先拦下来、
            # 测试就变成假过（第一次写就踩了这个坑）。
            '--allow-dirty',
        ], env=dict(os.environ, XSSV_HOME=str(REPO), XSSV_INDEX_HOME=str(td)),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
        reason = [l for l in r.stdout.splitlines() if 'ERROR' in l]
        msg = reason[0] if reason else ''
        # 必须是"组合性/child receipt 失效"这类原因，不接受被别的闸误拦而算过
        by_composition = ('green_child' in msg)
        good = (r.returncode != 0 and by_composition) if expect_fail else (r.returncode == 0)
        print(f'  {"ok " if good else "BAD"} {name}: rc={r.returncode} {msg[:100]}')
        return good


def main():
    res = []
    res.append(run_case('child impl 闭包某文件 sha 改一位',
                        lambda d: d['impl_closure'][0].update(
                            sha256='0' * 63 + '1') if d.get('impl_closure') else None))
    res.append(run_case('child impl 闭包指向父 commit 下不存在的路径',
                        lambda d: d['impl_closure'][0].update(
                            path='rtl/common/__no_such_file__.sv') if d.get('impl_closure') else None))
    res.append(run_case('child impl 闭包被清空(无可核对条目)',
                        lambda d: d.update(impl_closure=[])))
    print(f'\n{sum(res)}/{len(res)} 通过')
    return 0 if all(res) else 1


if __name__ == '__main__':
    sys.exit(main())
