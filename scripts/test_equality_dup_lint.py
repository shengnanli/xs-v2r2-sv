#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""equality_dup_lint.py 的负测。

## 为什么这组负测要这么写

本工程出过多次「测试假通过」，这里逐条针对：

1. **「扫出来 0」和「检测器根本不会响」在报告里长得一模一样。**
   真实基线上这道闸是 clean 的（2 组重复都已登记）。所以必须有人造夹具
   证明每一条判据都真的会响。

2. **Python 未捕获异常的退出码也是 1，和「抓到 1 个 finding」无法区分。**
   所以每条负测除了看退出码，还必须同时满足：
     - stdout/stderr 里**不含 `Traceback`**；
     - 输出里出现**预期的 finding code**（`DIVERGED` / `HASH_STALE` / …）。
   只看 rc 的断言在这里是无效断言。

3. **必须证明夹具真的走到了被测判据，而不是因为夹具本身畸形才 FAIL。**
   做法：每条负测都配一个**只差注入缺陷这一处**的干净孪生，先断言孪生
   PASS（rc=0 且输出 `clean`），再断言注入版 FAIL。两边只有一个变量。

跑法: python3 scripts/test_equality_dup_lint.py    （退出码 0 = 全过）
"""
import atexit
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(os.path.abspath(__file__)).parent
LINT = str(HERE / 'equality_dup_lint.py')

_TMPDIRS = []
atexit.register(lambda: [shutil.rmtree(d, ignore_errors=True)
                         for d in _TMPDIRS])

failures = []


def check(cond, what):
    print(('  ok   ' if cond else '  FAIL ') + what)
    if not cond:
        failures.append(what)


# ---------------------------------------------------------------- 夹具

def mkrepo(files, registry_rows=None, header=None, extra_lines=None):
    """造一个临时仓库：rtl/<path> + docs/deferred_refactor.tsv。"""
    root = pathlib.Path(tempfile.mkdtemp(prefix='eqdup_'))
    _TMPDIRS.append(str(root))
    for rel, text in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding='utf-8')
    (root / 'docs').mkdir(parents=True, exist_ok=True)
    if registry_rows is not None or header is not None:
        import equality_dup_lint as E
        lines = []
        lines.append('\t'.join(header if header is not None else E.REGISTRY_COLS))
        for r in (registry_rows or []):
            lines.append('\t'.join(r))
        lines.extend(extra_lines or [])
        (root / 'docs' / 'deferred_refactor.tsv').write_text(
            '\n'.join(lines) + '\n', encoding='utf-8')
    return root


def mod(name, body=''):
    return 'module %s(\n  input logic clock\n);\n%s\nendmodule\n' % (name, body)


def run(root, *args):
    pr = subprocess.Popen(
        [sys.executable, LINT, '--repo-root', str(root)] + list(args),
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out, _ = pr.communicate()
    return pr.returncode, out.decode('utf-8', 'replace')


def sha(root, rel):
    import equality_dup_lint as E
    return E.sha256_file(root / rel)


def row(rid, typ, members, hashes, why='推迟理由', recipe='收口配方', targets='T'):
    return [rid, typ, ','.join(members), ','.join(hashes), why, recipe, targets]


# 断言助手：三个「有牙齿」的断言，都强制排除 Traceback
def expect_clean(root, what, *args):
    rc, out = run(root, *args)
    ok = (rc == 0) and ('clean' in out) and ('Traceback' not in out)
    check(ok, what + '  [rc=%d]' % rc)
    if not ok:
        print(out)
    return out


def expect_finding(root, code, what, *args):
    rc, out = run(root, *args)
    ok = (rc == 1) and (code in out) and ('Traceback' not in out)
    check(ok, what + '  [rc=%d, 期望 code=%s]' % (rc, code))
    if not ok:
        print(out)
    return out


def expect_failclosed(root, keyword, what, *args):
    rc, out = run(root, *args)
    ok = (rc == 2) and ('[ERROR]' in out) and (keyword in out) \
        and ('Traceback' not in out)
    check(ok, what + '  [rc=%d, 期望关键字=%r]' % (rc, keyword))
    if not ok:
        print(out)
    return out


sys.path.insert(0, str(HERE))

print('== 0. 正向对照：无重复、空登记表 → clean ==')
r = mkrepo({'rtl/a.sv': mod('A'), 'rtl/b.sv': mod('B')}, registry_rows=[])
expect_clean(r, '两个不同模块不报重复')

print('\n== 1. 发现判据 A：未登记的逐字节重复 ==')
# 干净孪生：内容不同 → 不该报
same = mod('X')
r_ok = mkrepo({'rtl/a.sv': same, 'rtl/b.sv': mod('Y')}, registry_rows=[])
expect_clean(r_ok, '对照：内容不同不报（证明不是逢二必报）')
r_bad = mkrepo({'rtl/a.sv': same, 'rtl/b.sv': same}, registry_rows=[])
expect_finding(r_bad, 'UNDECLARED_DUPLICATE', '逐字节相同且未登记 → 响')

print('\n== 2. 发现判据 A：未登记的同名模块多处定义（内容不同）==')
# 只差一行注释 → 不逐字节相同，但模块同名；证明两条判据彼此独立
r_bad = mkrepo({'rtl/a.sv': mod('X'), 'rtl/b.sv': '// 注释\n' + mod('X')},
               registry_rows=[])
out = expect_finding(r_bad, 'UNDECLARED_MODULE_COLLISION',
                     '同名不同内容 → 响（且不应报 UNDECLARED_DUPLICATE）')
check('UNDECLARED_DUPLICATE' not in out,
      '  同名但内容不同时不误报 UNDECLARED_DUPLICATE（两判据独立）')

print('\n== 3. 注释里的 module 不算定义（防误报）==')
r = mkrepo({'rtl/a.sv': mod('X'),
            'rtl/b.sv': '// module X\n/* module X */\n' + mod('Z')},
           registry_rows=[])
expect_clean(r, '注释里的 module X 不被当成定义')

print('\n== 4. ★核心★ 已登记的逐字节重复发生分叉 → DIVERGED ==')
# 干净孪生与注入版只差 b.sv 末尾一行，登记表逐字一致
files_sync = {'rtl/a.sv': same, 'rtl/b.sv': same}
r_ok = mkrepo(files_sync, registry_rows=[])
h = sha(r_ok, 'rtl/a.sv')
reg = [row('dup', 'byte_identical', ['rtl/a.sv', 'rtl/b.sv'], [h, h])]
r_ok = mkrepo(files_sync, registry_rows=reg)
expect_clean(r_ok, '对照：两份仍同步且 hash 未变 → clean（证明夹具能通过判据）')

r_bad = mkrepo({'rtl/a.sv': same, 'rtl/b.sv': same + '// 有人只改了这一份\n'},
               registry_rows=reg)
out = expect_finding(r_bad, 'DIVERGED',
                     '★只改一份、另一份没跟上 → DIVERGED（这道闸的全部价值）')
check('静默分叉' in out, '  DIVERGED 的说明里点明了「静默分叉」')

print('\n== 5. --update-hashes 不得掩盖 DIVERGED ==')
out = expect_finding(r_bad, 'DIVERGED',
                     '带 --update-hashes 仍然报 DIVERGED（不可被静音）',
                     '--update-hashes')

print('\n== 6. 同步地一起改 → HASH_STALE（留痕，强制重钉）==')
both = same + '// 两份一起改\n'
r_bad = mkrepo({'rtl/a.sv': both, 'rtl/b.sv': both}, registry_rows=reg)
expect_finding(r_bad, 'HASH_STALE', '两份同步改但没重钉 hash → 响')
# 重钉后应转 clean，且真的写回了文件
rc, out = run(r_bad, '--update-hashes')
check(rc == 0 and 'REPIN' in out and 'Traceback' not in out,
      '--update-hashes 重钉后转 clean 且打印 REPIN  [rc=%d]' % rc)
newtsv = (r_bad / 'docs' / 'deferred_refactor.tsv').read_text(encoding='utf-8')
check(sha(r_bad, 'rtl/a.sv') in newtsv, '  新 hash 真的写回了登记表')
expect_clean(r_bad, '  重钉后再跑一次确实 clean')

print('\n== 7. functional_duplicate：任一份变动 → MEMBER_CHANGED ==')
fa, fb = mod('CoreA'), mod('CoreB')
r_ok = mkrepo({'rtl/a.sv': fa, 'rtl/b.sv': fb}, registry_rows=[])
reg2 = [row('fdup', 'functional_duplicate', ['rtl/a.sv', 'rtl/b.sv'],
            [sha(r_ok, 'rtl/a.sv'), sha(r_ok, 'rtl/b.sv')])]
r_ok = mkrepo({'rtl/a.sv': fa, 'rtl/b.sv': fb}, registry_rows=reg2)
expect_clean(r_ok, '对照：两份都没动 → clean')
r_bad = mkrepo({'rtl/a.sv': fa + '// 只动了 A\n', 'rtl/b.sv': fb},
               registry_rows=reg2)
expect_finding(r_bad, 'MEMBER_CHANGED', '功能重复的一侧变了 → 响')

print('\n== 8. 登记的成员文件消失 → MISSING_MEMBER ==')
r_bad = mkrepo({'rtl/a.sv': fa}, registry_rows=reg2)
expect_finding(r_bad, 'MISSING_MEMBER', '登记表引用了不存在的文件 → 响')

print('\n== 9. 登记只覆盖子集：第 3 份重复出现仍要响 ==')
r_bad = mkrepo({'rtl/a.sv': same, 'rtl/b.sv': same, 'rtl/c.sv': same},
               registry_rows=reg)
expect_finding(r_bad, 'UNDECLARED_DUPLICATE',
               '登记了 2 份、实际 3 份相同 → 仍报未登记（登记不是通行证）')

print('\n== 10. fail-closed：登记表读不懂必须 rc=2，绝不当成「没条目」放行 ==')
# 每个 fail-closed 夹具都由「能通过的孪生」改一处而来
base_files = {'rtl/a.sv': same, 'rtl/b.sv': same}
expect_clean(mkrepo(base_files, registry_rows=reg), '对照：合法登记表 → clean')

import equality_dup_lint as E
bad_header = list(E.REGISTRY_COLS)
bad_header[0] = 'ID'
expect_failclosed(mkrepo(base_files, registry_rows=reg, header=bad_header),
                  '表头', '表头不对 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[reg[0][:-1]]), '列数',
    '列数不足 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'byte_identical', ['rtl/a.sv', 'rtl/b.sv'], [h])]),
    '逐位对齐', 'hash 个数与 members 不齐 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'sort_of_same', ['rtl/a.sv', 'rtl/b.sv'], [h, h])]),
    'type', 'type 不在白名单 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'byte_identical', ['rtl/a.sv', 'rtl/b.sv'], [h, h], why='')]),
    'why_deferred', 'why_deferred 空 → rc=2（登记表的价值就在这列）')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'byte_identical', ['rtl/a.sv', 'rtl/b.sv'], [h, h],
            recipe='')]),
    'next_cycle_recipe', 'next_cycle_recipe 空 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'byte_identical', ['rtl/a.sv', 'rtl/b.sv'], ['zz', 'zz'])]),
    '非法值', 'hash 不是 64 位十六进制 → rc=2')

expect_failclosed(
    mkrepo(base_files, registry_rows=[
        row('dup', 'byte_identical', ['rtl/a.sv'], [h])]),
    '少于 2', 'members 只有 1 个 → rc=2')

print('\n== 11. rtl 根目录不存在 → rc=2（不静默当成 0 个文件）==')
empty = pathlib.Path(tempfile.mkdtemp(prefix='eqdup_norlt_'))
_TMPDIRS.append(str(empty))
rc, out = run(empty)
check(rc == 2 and 'Traceback' not in out, 'rtl/ 缺失 → rc=2  [rc=%d]' % rc)

print('\n================ 汇总 ================')
if failures:
    print('FAILED %d 项:' % len(failures))
    for f in failures:
        print('  - ' + f)
    sys.exit(1)
print('全部通过')
sys.exit(0)
