#!/usr/bin/env python3
"""check_closure_symmetry.py 的负测。

本工程有过多次「测试假通过」：断言被前置门挡掉却报 PASS、VCS 对 $fatal 返回退出码 0、
反测崩溃的 traceback 退出码与"抓到了"都是 1。本文件按三条规矩写：

  R1 **每条断言都要求输出里出现预期关键字**，不只看退出码 —— 退出码相同的两种失败
     （真抓到 vs 脚本自己炸）必须能区分。被测脚本为此把退出码分成
     0=CLEAN / 1=VIOLATION / 2=USAGE / 3=INTERNAL，本文件逐个钉死。
  R2 **每个变异测试都配一个未变异的对照**：先断言原样 fixture 通过，再变异、断言失败。
     否则「fixture 本来就坏」会被误读成「变异被抓到了」。
  R3 **本文件自身的失败必须是 AssertionError 且带原因**，不靠 print 观察。

跑法： python3 scripts/test_check_closure_symmetry.py     （exit 0 = 全过）
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
SCRIPT = HERE / 'check_closure_symmetry.py'
GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
CLEAN, VIOLATION, USAGE, INTERNAL = 0, 1, 2, 3

PASS, FAIL = [], []


def run(*args):
    p = subprocess.run([sys.executable, str(SCRIPT)] + list(args),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True, cwd=str(REPO))
    return p.returncode, p.stdout


def check(name, rc, out, want_rc, want_kw):
    """want_kw 必须出现在输出里 —— 只比退出码会把「脚本自己炸了」当成「抓到了」。"""
    why = []
    if rc != want_rc:
        why.append(f'退出码 期望{want_rc} 实得{rc}')
    if want_kw and want_kw not in out:
        why.append(f'输出缺预期关键字 {want_kw!r}')
    if 'INTERNAL_ERROR' in out and want_rc != INTERNAL:
        why.append('输出含 INTERNAL_ERROR（脚本自身异常，不是检查结论）')
    if 'Traceback' in out and want_rc != INTERNAL:
        why.append('输出含 Traceback')
    if why:
        FAIL.append(f'{name}: ' + '; '.join(why) + f'\n    ---- 输出 ----\n{out[:900]}')
        print(f'  FAIL  {name}: {"; ".join(why)}')
    else:
        PASS.append(name)
        print(f'  ok    {name}  (rc={rc}, 含 {want_kw!r})')


# ---------------------------------------------------------------- fixtures
MK_SYM = '''MODULE = FIXT
RTL_SRCS = {golden}/TLBuffer_13.sv
RTL_GOLDEN_DEPS = {golden}/Queue2_TLBundleA_19.sv {golden}/ram_2x119.sv
FM_REF_DEPS_TLBuffer_13 = Queue2_TLBundleA_19.sv ram_2x119.sv
FM_VARIANTS = TLBuffer_13
TB_SRCS =
include {repo}/scripts/ut_common.mk
'''
# 变异：ram_2x119.sv 只留在 ref 侧 —— 正是 DuplicatedTagArray/array_8 那个坑的形状
MK_ASYM = MK_SYM.replace(' {golden}/ram_2x119.sv', '')
# 变异：依赖文件不存在 —— fail-closed，必须判 ERROR 而不是「没看出问题所以通过」
MK_MISSING = MK_SYM.replace('{golden}/Queue2_TLBundleA_19.sv',
                            '{golden}/NoSuchFile_zzz.sv')


def mk_ut(root, name, tmpl):
    d = pathlib.Path(root) / name
    d.mkdir(parents=True)
    (d / 'Makefile').write_text(tmpl.format(golden=GOLDEN, repo=REPO))
    return d


print('=== A. closure 对称性（含 R2 对照）===')
with tempfile.TemporaryDirectory() as td:
    mk_ut(td, 'FIXT', MK_SYM)
    rc, out = run('--ut-root', td)
    check('A1 对照：两侧同读 ram_2x119 -> CLEAN', rc, out, CLEAN,
          '所检 target 两侧 elaboration closure 对称')

with tempfile.TemporaryDirectory() as td:
    mk_ut(td, 'FIXT', MK_ASYM)
    rc, out = run('--ut-root', td)
    check('A2 变异：ram 只在 ref 侧 -> 抓到不对称', rc, out, VIOLATION,
          'assembly_bbox_not_symmetric:ram_2x119(ref=0,impl=4)')

with tempfile.TemporaryDirectory() as td:
    mk_ut(td, 'FIXT', MK_MISSING)
    rc, out = run('--ut-root', td)
    check('A3 fail-closed：依赖文件不存在 -> ERROR 而非通过', rc, out, VIOLATION,
          'elab_src_missing')

print('=== B. 真实目标的变异对照（证明本轮的修法确实起作用）===')
for name, ut, mutate, kw in [
    ('B1 DuplicatedTagArray 撤回 array_8.sv',
     'DuplicatedTagArray', ('                  $(GOLDEN_RTL)/array_8.sv \\\n', ''),
     'assembly_bbox_not_symmetric:array_8(ref=0,impl=8)'),
    ('B2 TLBuffer_13 撤回 5 个 ram 的 impl 侧',
     'TLBuffer_13', ('                  $(GOLDEN_RTL)/ram_2x119.sv \\\n', ''),
     'assembly_bbox_not_symmetric:ram_2x119(ref=0,impl=4)'),
]:
    src = REPO / 'verif' / 'ut' / ut / 'Makefile'
    orig = src.read_text()
    rc, out = run('--only', ut)
    check(f'{name} [对照:原样]', rc, out, CLEAN, '两侧 elaboration closure 对称')
    old, new = mutate
    assert old in orig, f'{name}: 变异锚点不存在，fixture 失效: {old!r}'
    try:
        src.write_text(orig.replace(old, new, 1))
        rc, out = run('--only', ut)
        check(f'{name} [变异]', rc, out, VIOLATION, kw)
    finally:
        src.write_text(orig)
    assert src.read_text() == orig, f'{name}: 未能还原 {src}'

print('=== C. registry schema（含 R2 对照）===')
REG = REPO / 'verif' / 'vendor_boundary.tsv'
reg_orig = REG.read_text()
rc, out = run('--check-registry')
check('C0 对照：仓内 registry 原样 -> CLEAN', rc, out, CLEAN,
      'registry 每条的端口签名/参数签名/leaf hash 与 golden 现文件一致')


def with_registry(text, name, want_kw):
    with tempfile.TemporaryDirectory() as td:
        f = pathlib.Path(td) / 'vb.tsv'
        f.write_text(text)
        rc, out = run('--check-registry', '--registry', str(f))
        check(name, rc, out, VIOLATION, want_kw)


body = [l for l in reg_orig.splitlines() if l.strip() and not l.startswith('#')]
head = [l for l in reg_orig.splitlines() if l.startswith('#')]
assert len(body) == 20, f'registry 期望 20 条，实得 {len(body)}'

# C1 少列（回到 schema v1 的 3 列）
with_registry('\n'.join(head + ['\t'.join(body[0].split('\t')[:3])] + body[1:]) + '\n',
              'C1 条目缺字段（只剩 3 列）', 'registry_field_count')
# C2 字段留空
f2 = body[0].split('\t'); f2[6] = ''
with_registry('\n'.join(head + ['\t'.join(f2)] + body[1:]) + '\n',
              'C2 端口签名留空', 'registry_field_empty:port_signature')
# C3 hash 被改（body 规则的锚点失效）
f3 = body[3].split('\t'); f3[4] = '0' * 64
with_registry('\n'.join(head + body[:3] + ['\t'.join(f3)] + body[4:]) + '\n',
              'C3 leaf_sha256 与 golden 不符', 'registry_mismatch:leaf_sha256')
# C4 端口签名被改（接口形状失效）
f4 = body[5].split('\t'); f4[6] = f4[6].replace('input', 'output', 1)
with_registry('\n'.join(head + body[:5] + ['\t'.join(f4)] + body[6:]) + '\n',
              'C4 port_signature 与 golden 不符', 'registry_mismatch:port_signature')
# C5 body_rule 丢了 pin
f5 = body[7].split('\t'); f5[9] = 'fm_blackbox_both_sides'
with_registry('\n'.join(head + body[:7] + ['\t'.join(f5)] + body[8:]) + '\n',
              'C5 body_rule 缺 pin_by=leaf_sha256', 'registry_body_rule_missing_pin')
# C6 表里有 golden 里不存在的 design
f6 = body[0].split('\t'); f6[0] = 'array_999_ext'
with_registry('\n'.join(head + ['\t'.join(f6)] + body[1:]) + '\n',
              'C6 design 在 golden 里不存在', 'registry_golden_extract_failed')
# C7 空表不算通过（fail-closed）
with_registry('\n'.join(head) + '\n', 'C7 空表', 'registry_empty')
assert REG.read_text() == reg_orig, 'registry 被测试改动了'

print('=== D. 退出码语义可区分（避免「崩溃」与「抓到了」都是 1）===')
rc, out = run('--ut-root', '/definitely/not/a/dir/zzz')
check('D1 用法错 -> 2 且不是 1', rc, out, USAGE, 'USAGE_ERROR')
with tempfile.TemporaryDirectory() as td:
    rc, out = run('--ut-root', td)
    check('D2 空 ut-root -> 2（不得报 OK）', rc, out, USAGE, 'USAGE_ERROR')
rc, out = run('--only', 'NoSuchUtDir_zzz')
check('D3 --only 指向不存在的 UT -> 2', rc, out, USAGE, 'USAGE_ERROR')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
if FAIL:
    print('\n'.join('FAILED: ' + x for x in FAIL))
    sys.exit(1)
print('ALL NEGATIVE TESTS PASSED')
