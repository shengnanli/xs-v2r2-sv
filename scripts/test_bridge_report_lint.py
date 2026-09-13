#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""bridge_report_lint.py 的负测 + 历史回归。

## 这组负测针对本工程真实出过的「假通过」

1. **Python 未捕获异常退出码也是 1**，与「抓到 1 个 finding」不可区分。
   所以每条断言都同时要求：rc 正确 + 输出含**预期 finding code** + 输出
   **不含 `Traceback`**。只看 rc 的断言在这里等于没断言。
2. **「没报」既可能是「没问题」，也可能是「判据根本没走到」**。所以每条负测都
   配一个**只差注入缺陷一处**的干净孪生，先证孪生 rc=0，再证注入版 rc=1。
3. **误报回归**：`UNPROVABLE_GOLDEN_STUB/INFRA_BLOCKED`（状态标签）、UUID 片段、
   `evidence/<commit>/…`（模板路径）实测都曾被误判。各留一条钉子测试。
4. **历史回归**：0147/0148 两封真实消息（空代码块 + `b36a1a2a5` 属于 XiangShan
   而非 xs-v2-sv）必须被抓到。缺这两条，这道闸就没证明过它能防那次事故。

跑法: python3 scripts/test_bridge_report_lint.py    （退出码 0 = 全过）
     历史回归需要 /home/eda/xs-env/.agent-bridge 与两个 repo 在位；
     不在位时该组显式 SKIP，不会假装通过。
"""
import hashlib
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(os.path.abspath(__file__)).parent
LINT = str(HERE / 'bridge_report_lint.py')

failures = []
skipped = []


def check(cond, what):
    print(('  ok   ' if cond else '  FAIL ') + what)
    if not cond:
        failures.append(what)


# ---------------------------------------------------------------- 夹具

def git(repo, *args):
    return subprocess.check_output(
        ['git', '-C', str(repo), '-c', 'user.name=t', '-c', 'user.email=t@t'] +
        list(args), stderr=subprocess.STDOUT).decode()


def mkgitrepo(name, files=None):
    root = pathlib.Path(tempfile.mkdtemp(prefix='brl_%s_' % name))
    git(root, 'init', '-q')
    for rel, txt in (files or {'README.md': 'x\n'}).items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(txt, encoding='utf-8')
    git(root, 'add', '-A')
    git(root, 'commit', '-q', '-m', 'init')
    sha = git(root, 'rev-parse', 'HEAD').strip()
    return root, sha


HDR = ('schema: agent-bridge-v1\nsender: claude\nrecipient: codex\n'
       'type: UPDATE\n---\n')


def msg(body, header=HDR):
    d = pathlib.Path(tempfile.mkdtemp(prefix='brl_msg_'))
    p = d / 'm.md'
    p.write_text(header + body, encoding='utf-8')
    return p


def run(path, *args):
    pr = subprocess.Popen([sys.executable, LINT, str(path)] + list(args),
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out, _ = pr.communicate()
    return pr.returncode, out.decode('utf-8', 'replace')


def expect_clean(path, what, *args):
    rc, out = run(path, *args)
    ok = (rc == 0) and ('clean' in out) and ('Traceback' not in out)
    check(ok, what + '  [rc=%d]' % rc)
    if not ok:
        print(out)
    return out


def expect_finding(path, code, what, *args):
    rc, out = run(path, *args)
    ok = (rc == 1) and (code in out) and ('Traceback' not in out)
    check(ok, what + '  [rc=%d, 期望 %s]' % (rc, code))
    if not ok:
        print(out)
    return out


def expect_not_finding(path, code, what, *args):
    rc, out = run(path, *args)
    ok = (code not in out) and ('Traceback' not in out)
    check(ok, what + '  [rc=%d, 不该出现 %s]' % (rc, code))
    if not ok:
        print(out)
    return out


# 两个真 git repo：A 是「声明的 repo」，B 是「另一个 repo」
REPO_A, SHA_A = mkgitrepo('A', {'rtl/a.sv': 'module A;\nendmodule\n',
                                'docs/t.tsv': 'x\ny\nz\n'})
REPO_B, SHA_B = mkgitrepo('B')
RA = ['--repo', 'A=%s' % REPO_A, '--repo', 'B=%s' % REPO_B,
      '--default-repo', 'A']

print('== 0. 正向对照 ==')
expect_clean(msg('正文，没有任何可疑内容。\n'), '干净消息 → rc=0', *RA)

print('\n== 1. 代码块非空（0147/0148 事故的第一个环节）==')
expect_clean(msg('commit 列表：\n```\nabc def\n```\n'),
             '对照：代码块有内容 → clean', *RA)
out = expect_finding(msg('自 X 以来的 commit（按序）：\n```\n\n```\n'),
                     'EMPTY_CODE_BLOCK', '★空代码块 → 响', *RA)
check('自 X 以来的 commit' in out, '  报告里回显了那句「声称已附」的正文做上下文')
expect_finding(msg('块里只有空白：\n```\n   \n\t\n```\n'),
               'EMPTY_CODE_BLOCK', '只有空白字符也算空', *RA)
expect_finding(msg('没闭合：\n```\nfoo\n'),
               'UNCLOSED_CODE_BLOCK', '围栏没闭合 → 响', *RA)

print('\n== 2. commit 属于声明的 repo（事故的第二个环节）==')
expect_clean(msg('基线 `%s`。\n' % SHA_A), '对照：commit 属于声明 repo → clean', *RA)
out = expect_finding(msg('自 `%s` 以来：\n' % SHA_B), 'COMMIT_WRONG_REPO',
                     '★commit 属于另一个 repo → 响（正是 b36a1a2a5 那次）', *RA)
check('B(commit)' in out, '  报告指名道姓说出它属于哪个 repo')
expect_finding(msg('见 `deadbeefcafe123`。\n'), 'COMMIT_UNRESOLVABLE',
               '哪个 repo 都解析不了 → 响', *RA)
expect_finding(msg('范围 `%s..HEAD` 的结果：\n' % SHA_B), 'COMMIT_WRONG_REPO',
               'X..HEAD 形式里的 X 也查', *RA)

print('\n== 3. 引用的文件存在 ==')
expect_clean(msg('见 `rtl/a.sv`。\n'), '对照：路径存在 → clean', *RA)
expect_finding(msg('见 `rtl/nope.sv`。\n'), 'MISSING_FILE', '路径不存在 → 响', *RA)
expect_finding(msg('见 `rtll/a.sv`。\n'), 'MISSING_FILE',
               '首段拼错但有 .sv 扩展名 → 仍抓得到', *RA)
expect_finding(msg('见 `rtl/a.sv:42`。\n'.replace('a.sv', 'nope.sv')),
               'MISSING_FILE', '带 :行号 的引用也查', *RA)

print('\n== 4. ★误报回归★（这三条曾经真的误报过）==')
expect_not_finding(msg('StorePipe 记 `UNPROVABLE_GOLDEN_STUB/INFRA_BLOCKED`。\n'),
                   'MISSING_FILE',
                   '含 / 的状态标签不当路径（实测 0148 误报过）', *RA)
expect_not_finding(msg('证据在 `evidence/<commit>/<target>/receipt.json`。\n'),
                   'MISSING_FILE', '模板路径 <…> 不当具体路径', *RA)
expect_not_finding(msg('声明在 `verif/allow/*.json`。\n'),
                   'MISSING_FILE', '通配路径不当具体路径', *RA)
expect_not_finding(msg('scratchpad /tmp/x/6824a231-879a-49e3-b98d-f29f5afc381c/s\n'),
                   'COMMIT_UNRESOLVABLE',
                   'UUID 片段不当 commit（实测误报过 f29f5afc381c）', *RA)
expect_not_finding(msg('```\n见 rtl/nope.sv 与 %s\n```\n' % SHA_B),
                   'MISSING_FILE', '围栏代码块内的路径不查（那是命令/输出）', *RA)

print('\n== 5. sha256 声称可核对 ==')
good = hashlib.sha256((REPO_A / 'rtl/a.sv').read_bytes()).hexdigest()
expect_clean(msg('产物：\n%s  rtl/a.sv\n' % good), '对照：sha256 对得上 → clean', *RA)
expect_finding(msg('产物：\n%s  rtl/a.sv\n' % ('0' * 64)), 'SHA256_MISMATCH',
               '★sha256 对不上 → 响（以机器产物为准）', *RA)
expect_finding(msg('产物：\n%s  rtl/gone.sv\n' % good), 'SHA256_MISSING_FILE',
               'sha256 指向的文件不存在 → 响', *RA)
expect_finding(msg('G1 canonical `G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33edd…`\n'),
               'TRUNCATED_HASH', '截断的 hash 不可核对 → 响（0147 真实案例）', *RA)

print('\n== 6. 计数可复算（D62：脚本非零/输出为空不得转述为事实）==')
expect_clean(msg('共 3 行 <!-- lint:count 3 :: wc -l < docs/t.tsv -->\n'),
             '对照：计数复算对得上 → clean（证明命令真的跑了）', *RA)
expect_finding(msg('共 99 行 <!-- lint:count 99 :: wc -l < docs/t.tsv -->\n'),
               'COUNT_MISMATCH', '★声称与复算不符 → 响', *RA)
# ★这条夹具必须「输出对得上、但退出码非零」★
# 早先写的是 `exit 7`（无输出），变异测试证明它其实是走「输出为空」那条分支过的，
# 把 returncode 判据关掉照样报 —— 断言没落在它声称测的判据上。改成先 echo 再 exit：
# 计数恰好等于声称值，于是只有 returncode 判据能让它响。
expect_finding(msg('共 3 个 <!-- lint:count 3 :: echo 3; exit 7 -->\n'),
               'COUNT_CMD_FAILED',
               '★命令非零退出 → 响（哪怕数字对得上），不许当事实', *RA)
expect_finding(msg('共 3 个 <!-- lint:count 3 :: true -->\n'),
               'COUNT_CMD_FAILED', '★命令输出为空 → 响，不许当事实', *RA)
# --no-run-counts 必须显式说「没查」，不能假装 clean
rc, out = run(msg('共 99 <!-- lint:count 99 :: wc -l < docs/t.tsv -->\n'),
              *(RA + ['--no-run-counts']))
check('[SKIP]' in out and 'Traceback' not in out,
      '--no-run-counts 时显式打印 [SKIP]，不假装查过  [rc=%d]' % rc)

print('\n== 7. 消息头 ==')
expect_finding(msg('正文\n', header='sender: claude\n---\n'),
               'HEADER_MISSING_FIELD', '缺 schema/type 等必填头 → 响', *RA)
expect_finding(msg('正文\n', header=HDR.replace(
    '---\n', 'in_reply_to: 不存在的消息.md\n---\n')),
    'HEADER_REPLY_TARGET_MISSING', 'in_reply_to 指向的消息不存在 → 响', *RA)
expect_finding(msg('正文\n', header=HDR.replace('---\n', 'repo: 没这个repo\n---\n')),
               'HEADER_UNKNOWN_REPO', '声明了未知 repo → 响（fail-closed）', *RA)
# 消息头里声明 repo: B 后，B 的 commit 就不该再报 WRONG_REPO
expect_not_finding(msg('基线 `%s`\n' % SHA_B,
                       header=HDR.replace('---\n', 'repo: B\n---\n')),
                   'COMMIT_WRONG_REPO',
                   '消息头 repo: B 声明后，B 的 commit 合法', *RA)

print('\n== 8. fail-closed：用法错误 rc=2 ==')
rc, out = run('/nonexistent/msg.md', *RA)
check(rc == 2 and 'Traceback' not in out, '消息文件不存在 → rc=2  [rc=%d]' % rc)
rc, out = run(msg('x\n'), '--repo', 'nosuchsyntax')
check(rc == 2 and 'Traceback' not in out, '--repo 语法错 → rc=2  [rc=%d]' % rc)
rc, out = run(msg('x\n'), '--repo', 'X=/definitely/not/here')
check(rc == 2 and 'Traceback' not in out, '--repo 路径不存在 → rc=2  [rc=%d]' % rc)

print('\n== 9. ★历史回归★：0147/0148 两封真实消息必须被抓到 ==')
INBOX = pathlib.Path('/home/eda/xs-env/.agent-bridge/inbox')
M147 = INBOX / '20260913T0100Z_claude_0147_QUESTION_decision_payload.md'
M148 = INBOX / '20260913T0130Z_claude_0148_UPDATE_process_truth_and_plan.md'
XSV2 = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
XS = pathlib.Path('/home/eda/xs-env/XiangShan')
if not (M147.exists() and M148.exists() and XSV2.is_dir() and XS.is_dir()):
    skipped.append('历史回归（消息或 repo 不在位）')
    print('  SKIP 历史回归：缺 %s' % ', '.join(
        str(x) for x in (M147, M148, XSV2, XS) if not x.exists()))
else:
    real = ['--repo', 'xs-v2-sv=%s' % XSV2, '--repo', 'XiangShan=%s' % XS,
            '--default-repo', 'xs-v2-sv', '--no-run-counts']
    out = expect_finding(M147, 'EMPTY_CODE_BLOCK',
                         '0147 的空代码块被抓到', *real)
    out = expect_finding(M148, 'EMPTY_CODE_BLOCK',
                         '0148 的空代码块被抓到', *real)
    out = expect_finding(M148, 'COMMIT_WRONG_REPO',
                         '★0148 的 b36a1a2a5 被判为不属于 xs-v2-sv', *real)
    check('b36a1a2a5' in out and 'XiangShan' in out,
          '  并指出它属于 XiangShan')
    # 反向对照：b36a1a2a5 在 XiangShan 里确实解析得出（证明判据两侧都成立）
    ok = subprocess.call(['git', '-C', str(XS), 'cat-file', '-t', 'b36a1a2a5'],
                         stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL) == 0
    bad = subprocess.call(['git', '-C', str(XSV2), 'cat-file', '-t', 'b36a1a2a5'],
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL) != 0
    check(ok and bad,
          '  独立复核：b36a1a2a5 在 XiangShan 解析得出、在 xs-v2-sv 解析不出')

print('\n================ 汇总 ================')
for s in skipped:
    print('SKIP: ' + s)
if failures:
    print('FAILED %d 项:' % len(failures))
    for f in failures:
        print('  - ' + f)
    sys.exit(1)
print('全部通过（%d 项 SKIP）' % len(skipped))
sys.exit(0)
