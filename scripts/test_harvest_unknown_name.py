#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_harvest_unknown_name.py —— receipt 收录表 chk_facts 的「行首 Error: Unknown name ⇒ 不得收」双向负测。

为什么有这条：fm_verdict 已有同名判据（scripts/test_unknown_name_verdict.py 负测），但收录表
gen_receipt_harvest.py 的 chk_facts 只看 receipt 的 native_facts 数，不看日志。早于该判据落地的
receipt（实测 ITTage@68bffe7f2938：250 行 FM-036，native SUCCEEDED）于是被本表收成 COLLECTED。
本测钉住的是：两处用**同一个**正则对象、同一口径（只认行首），且 >0 即 chk_facts=DIFFER。

样本取**已入库**的真实日志，判据输入独立于被测改动：
  clean  evidence/22184c5297e2/PtwCache/fm.log（0 行行首；但有 3 处注释回显提到 Unknown name/FM-036）
  dirty  evidence/68bffe7f2938/ITTage/fm.log（250 行行首）

  A clean 原样                                     -> 计数 0，chk_facts same
  B clean + 注入一行行首 Error: Unknown name       -> 计数 1，chk_facts DIFFER，原因带 Unknown name=1
  C clean + 注释/缩进/行中提到 Unknown name、FM-036 -> 计数 0，chk_facts same（只认行首）
  D dirty 原样                                     -> 计数 250，chk_facts DIFFER
  E 日志缺失（None）                               -> 计数 None，本判据不介入（由 chk_tool 判 UNKNOWN）
  F 口径同源：本表用的正则就是 fm_verdict._UNKNOWN_NAME 这个对象（不是抄了一份）
"""
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / 'scripts'))
import fm_verdict  # noqa: E402
import gen_receipt_harvest as H  # noqa: E402

CLEAN = REPO / 'evidence/22184c5297e2/PtwCache/fm.log'
DIRTY = REPO / 'evidence/68bffe7f2938/ITTage/fm.log'
INJ = "Error: Unknown name: 'i:/WORK/PtwCache/u_core/nope_reg[0]' (FM-036)\n"
ECHO = ("# Error: Unknown name: 'x' (FM-036) is what a silent miss looks like\n"
        "    Error: Unknown name: 'indented echo' (FM-036)\n"
        "puts \"PIN_FAIL: see Error: Unknown name (FM-036)\"\n")

ok = True


def ck(label, good, detail=''):
    global ok
    ok &= bool(good)
    print('  %s  %s  %s' % ('ok  ' if good else 'FAIL', label, detail))


def facts(n):
    """一份 native_facts 全干净的最小记录，只让 unknown_name 变。"""
    r = {'stats': {'passing': 100, 'failing': 0, 'unverified': 0, 'aborted': 0,
                   'unread_notcompared': 0},
         'unmatched': {'compare_ref': 0, 'compare_impl': 0, 'unread_ref': 0,
                       'unread_impl': 0, 'bbout_ref': 0, 'bbout_impl': 0},
         'quals': {}, 'verdict': 'SUCCEEDED', 'declarations': {}, 'objects': {},
         'unknown_name': n}
    return H.chk_facts(r)


for p in (CLEAN, DIRTY):
    if not p.is_file():
        print('样本缺失：%s —— 拒绝按"通过"放过' % p.relative_to(REPO))
        sys.exit(2)
clean = CLEAN.read_text(errors='replace')
dirty = DIRTY.read_text(errors='replace')

n = H.unknown_name_count(clean)
v, w = facts(n)
ck('A clean 原样', n == 0 and v == 'same', 'n=%r chk_facts=%s' % (n, v))

n = H.unknown_name_count(clean + INJ)
v, w = facts(n)
ck('B clean + 行首注入', n == 1 and v == 'DIFFER' and 'Unknown name=1' in w,
   'n=%r chk_facts=%s' % (n, v))

n = H.unknown_name_count(clean + ECHO)
v, w = facts(n)
ck('C clean + 注释/缩进/行中回显', n == 0 and v == 'same',
   'n=%r chk_facts=%s（样本自带 %d 处非行首提及）'
   % (n, v, sum(1 for l in clean.splitlines() if 'Unknown name' in l or 'FM-036' in l)))

n = H.unknown_name_count(dirty)
v, w = facts(n)
ck('D dirty 原样 (ITTage@68bffe7f2938)', n == 250 and v == 'DIFFER', 'n=%r chk_facts=%s' % (n, v))

n = H.unknown_name_count(None)
v, w = facts(n)
ck('E 日志缺失', n is None and v == 'same', 'n=%r chk_facts=%s' % (n, v))

ck('F 正则与 fm_verdict 同一对象', H.UNKNOWN_NAME_RE is fm_verdict._UNKNOWN_NAME,
   H.UNKNOWN_NAME_RE.pattern)

print('自测全过' if ok else '★有判据未过★')
sys.exit(0 if ok else 1)
