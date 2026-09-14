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
assert len(body) == 27, (f'registry 期望 27 条（20 条 D60 + 6 条 D67 + 1 条 0158 §1 ram_40x47），实得 {len(body)}')


def row_by_name(name):
    """按名字取行 + 其下标。**不按下标硬编码** —— 表会增行，下标会漂。"""
    for i, l in enumerate(body):
        if l.split('\t')[0] == name:
            return i, l.split('\t')
    raise AssertionError(f'registry 里找不到 {name}（fixture 失效）')


def mutated(name, col, newval):
    """把某条的某列改掉，返回整表文本。col 用 REG_COLS 里的列名，不用下标。"""
    import importlib.util
    spec = importlib.util.spec_from_file_location('ccs', SCRIPT)
    ccs = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ccs)
    ci = ccs.REG_COLS.index(col)
    i, f = row_by_name(name)
    assert f[ci] != newval, f'{name}.{col} 变异值与原值相同，这条负测什么也没测'
    f = list(f)
    f[ci] = newval
    return '\n'.join(head + body[:i] + ['\t'.join(f)] + body[i + 1:]) + '\n'

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

print('=== E. codex 0153 D67 的 6 条存储宏（每条负测都配 C0 干净夹具对照）===')
# E0 正向对照：reviewer 自己独立读过这六个文件并给出的 sha256，逐条钉进本测试。
#    这不是从表里抄的 —— 表若被改/被扩/被换 golden，本断言立刻炸。
#    复跑：sha256sum $GOLDEN_RTL/array_{19,20,21,22,0_0,0_1}_ext.v
D67_SHA = {
    'array_19_ext':  'a2871e73c0933573a2bfc8e2746e8504cf8b4874884aabc9fe048fa0bcc68ac9',
    'array_20_ext':  '682a8c4402fafe0500cae3915148614fa3f0c294cfc8a276e63566a76e762808',
    'array_21_ext':  'c4e9d83aa43344b2b67864977925a1023b17776ae60f328b08ea5a4a3c20d185',
    'array_22_ext':  '86d0fb51ea2e5d1922b4a17b696e365d2f32814c50364eb11d8a275ec223c38d',
    'array_0_0_ext': 'd64d9b5dded9d34e6502ad82271860037c62e5a4934396920484b2b317b11b48',
    'array_0_1_ext': '84b873d43a1e150fc144cd5a265bbe3e866a64ed03d629eaf39949fba2e271ef',
}
import hashlib as _hl
_e0 = []
for _n, _s in D67_SHA.items():
    _f = pathlib.Path(GOLDEN) / f'{_n}.v'
    if not _f.is_file():
        _e0.append(f'{_n}: golden 里没有 {_f}')
        continue
    _cur = _hl.sha256(_f.read_bytes()).hexdigest()
    if _cur != _s:
        _e0.append(f'{_n}: golden 现文件 sha256={_cur} != reviewer 给的 {_s}')
    _i, _row = row_by_name(_n)
    if _row[4] != _s:
        _e0.append(f'{_n}: registry leaf_sha256={_row[4]} != reviewer 给的 {_s}')
    if _row[1] != 'APPROVED_MEMORY_MACRO_MODEL':
        _e0.append(f'{_n}: kind={_row[1]!r}，D67 要求 APPROVED_MEMORY_MACRO_MODEL')
if _e0:
    FAIL.append('E0 六条与 reviewer 独立给出的 hash/类别一致: ' + '; '.join(_e0))
    print('  FAIL  E0: ' + '; '.join(_e0))
else:
    PASS.append('E0')
    print('  ok    E0 六条 golden 现文件 sha256 == reviewer(codex 0153 D67) 给的值，'
          '且 kind 均为 APPROVED_MEMORY_MACRO_MODEL')

# E1 body hash 不符 —— body_rule 的锚点失效，本条审定必须作废
with_registry(mutated('array_0_1_ext', 'leaf_sha256', '0' * 64),
              'E1 六条之一 leaf_sha256 与 golden 不符', 'registry_mismatch:leaf_sha256')
# E2 端口签名不符 —— 黑盒等价性只依赖接口，接口一变本条即失效
_i, _f = row_by_name('array_21_ext')
with_registry(mutated('array_21_ext', 'port_signature',
                      _f[6].replace('input [15:0] RW0_wmask', 'input [7:0] RW0_wmask')),
              'E2 六条之一 port_signature 与 golden 不符（mask 位宽被改）',
              'registry_mismatch:port_signature')
# E3 深度不符 —— D67 点名要绑定的「深度」
with_registry(mutated('array_0_1_ext', 'depth', '4096'),
              'E3 六条之一 depth 与 golden 不符', 'registry_mismatch:depth')
# E4 mask 粒度不符 —— D67 点名要绑定的「mask 粒度」
with_registry(mutated('array_19_ext', 'mask_granularity', '10x1:bitblend'),
              'E4 六条之一 mask_granularity 与 golden 不符（slice 谎报成 bitblend）',
              'registry_mismatch:mask_granularity')
# E5 时钟语义不符 —— D67 点名要绑定的「单/双时钟读写语义」。
#    array_0_1_ext 是本表唯一的双时钟条目，谎报成单时钟必须被抓。
with_registry(mutated('array_0_1_ext', 'clock_semantics', 'nclk=1;clk=RW0;access=1rw'),
              'E5 唯一的双时钟条目被谎报成单时钟', 'registry_mismatch:clock_semantics')
# E6 ★按后缀批量放行必须被拒★（D67 原文：不得根据 `_ext` 后缀批量放行）
_i, _f = row_by_name('array_19_ext')
_wild = list(_f)
_wild[0] = 'array_*_ext'
with_registry('\n'.join(head + body[:_i] + ['\t'.join(_wild)] + body[_i + 1:]) + '\n',
              'E6 用 `array_*_ext` 通配想一条放行一族', 'registry_pattern_not_literal')
# E7 类别越界 —— 不得自造/复用泛化类别绕过 D67 的单独审定
with_registry(mutated('array_22_ext', 'kind', 'vendor_macro'),
              'E7 kind 用了封闭集合之外的值', 'registry_kind_unknown:vendor_macro')
assert REG.read_text() == reg_orig, 'registry 被 E 段测试改动了'

print('=== F. registry × 台账 逐名精确对账（D67：GAP 不得消失）===')
LEDGER = REPO / 'docs' / 'g1_boundary_ledger.tsv'
led_orig = LEDGER.read_text()
rc, out = run('--reconcile-ledger')
check('F0 对照：仓内 registry+台账 原样 -> CLEAN', rc, out, CLEAN, '对账完成且守恒')

# F1 ★GAP 不得消失★：把两条边界轴的 GAP 余量钉死。任何一次「顺手把 GAP 吸收掉」
#    的改动都会在这里炸。数字来源见报告；口径 = 逐名精确匹配，无通配。
#
#    ★这组数字只能随 reviewer 的**逐名**裁定而动，且每动一次都要在这里写明依据★
#    2026-09-14 FM_BBOX 轴 2->3 / 93->92：codex 0158 §1 逐名批准 `ram_40x47`
#    （L2TlbMissQueue 的存储边界）为 APPROVED_MEMORY_MACRO_MODEL。三项最小功能审查
#    可复算：`python3 scripts/audit_ram_memory_model.py --check`。
#    ★这不是「上层边界获批所以下面的 GAP 跟着消失」（那正是 D67 禁止的）★ ——
#    是这**一个名字本身**被单独审定了，其余 92 项一个都没动。
_want = [
    ('FM_BBOX_REACHABLE: 95 项', 'FM_BBOX 轴总数'),
    ('★由 GAP 转 approved = 3★',
     'FM_BBOX 轴只许 array_0_0_ext/array_0_1_ext(D67) + ram_40x47(0158 §1) 转绿'),
    ('★仍为 GAP = 92★', 'FM_BBOX 轴剩余 GAP'),
    ('BEHIND_BOUNDARY: 44 项', 'BEHIND 轴总数'),
    ('★由 GAP 转 approved = 4★', 'BEHIND 轴只许 array_19..22_ext 转绿'),
    ('★仍为 GAP = 20★', 'BEHIND 轴剩余 GAP（24 里的 4 个本身就是 D67 批准的六条之一）'),
]
_miss = [f'{k!r}({why})' for k, why in _want if k not in out]
if rc != CLEAN or _miss:
    FAIL.append(f'F1 对账余量: rc={rc}; 缺 {"; ".join(_miss)}')
    print(f'  FAIL  F1: rc={rc}; 缺 {"; ".join(_miss)}')
else:
    PASS.append('F1')
    print('  ok    F1 两轴 GAP 余量与逐名对账一致（95=3+92, 44=20vendor+4macro+20GAP）')

# F2 通配 registry 在对账口径下同样被拒（两条入口都不许按后缀批量放行）
with tempfile.TemporaryDirectory() as td:
    f = pathlib.Path(td) / 'vb.tsv'
    _i, _f = row_by_name('array_20_ext')
    _w = list(_f)
    _w[0] = 'array_*_ext'
    f.write_text('\n'.join(head + body[:_i] + ['\t'.join(_w)] + body[_i + 1:]) + '\n')
    rc, out = run('--reconcile-ledger', '--registry', str(f))
    check('F2 对账入口也拒绝通配条目', rc, out, VIOLATION, 'registry_pattern_not_literal')

# F3 fail-closed：台账里出现不认识的 axis，不得静默跳过
with tempfile.TemporaryDirectory() as td:
    f = pathlib.Path(td) / 'led.tsv'
    f.write_text(led_orig.replace('\nBEHIND_BOUNDARY\tarray\t',
                                  '\nSOMETHING_NEW\tarray\t', 1))
    rc, out = run('--reconcile-ledger', '--ledger', str(f))
    check('F3 台账出现未知 axis -> fail-closed', rc, out, VIOLATION, '未知 axis')
assert LEDGER.read_text() == led_orig, '台账被测试改动了'
assert REG.read_text() == reg_orig, 'registry 被 F 段测试改动了'

print('=== G. 用到这六条的 UT，两侧闭包必须对称（D67：ref/impl 对称才算 approved）===')
# OpenLLC 是六条**全部**出现的那个 UT，也是 codex 0153 D68 点名的 1-vs-69 不对称现场。
# 这里同时做对照与变异：撤回 RTL_GOLDEN_DEPS 必须立刻退回不对称。
for name, ut, mutate, kw in [
    ('G1 OpenLLC 撤回 RTL_GOLDEN_DEPS（还原 D68 现场）',
     'OpenLLC',
     ('RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_OpenLLC))\n',
      'RTL_GOLDEN_DEPS =\n'),
     'assembly_bbox_not_symmetric:MMIODiverger(ref=0,impl=1)'),
    ('G2 SubDirectory_1 只给 impl 侧 array_0_0（造成单侧白盒）',
     'SubDirectory_1',
     ('RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory_1.sv\n',
      'RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory_1.sv\n'
      'RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/SRAMTemplate_196.sv\n'),
     'assembly_bbox_not_symmetric:'),
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
