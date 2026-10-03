#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_unknown_name_verdict.py —— fm_verdict 的「行首 Error: Unknown name ⇒ 不得 SUCCEEDED」双向负测。

为什么有这条判据：set_user_match 对不存在的名字**不抛 Tcl 异常**，只在日志里写一行
行首 `Error: Unknown name: '<obj>' (FM-036)`。钉点脚本若拿 catch 判成败，这一行就是
"钉了个寂寞"留下的唯一痕迹；而 FM 往往自己按签名把那些点配上了，native 照样 SUCCEEDED，
于是整件事在结论里完全看不见（codex_0207 E1：SyncDataModule 8 变体 +
PipelineConnectPipe / NewPipelineConnectPipe_29/_34 / FauFTBWay）。

样本取**已入库**的真实日志，判据输入独立于被测改动：
  clean  evidence/8b9c32ee57dd/SyncDataModuleTemplate__64entry_5/fm.log（修好后的重证，0 行）
  dirty  evidence/e47e713399e0/PipelineConnectPipe/fm.log（修之前，74 行）

  A clean 原样                                        -> SUCCEEDED
  B clean + 注入一行行首 Error: Unknown name          -> PARTIAL（reason 带 unknown_name_errors）
  C clean + 注释/缩进/回显里提到 Unknown name、FM-036  -> 仍 SUCCEEDED（只认行首 Error:）
  D dirty 原样（旧 receipt 当年判的是 SUCCEEDED）     -> PARTIAL，计数 74
  E clean + 注入但 native 本就 FAILED 的日志          -> 结论不被这条判据改写（只收紧绿灯）
"""
import os, sys, pathlib
REPO = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / 'scripts'))
from fm_verdict import verdict  # noqa: E402

CLEAN = REPO / 'evidence/8b9c32ee57dd/SyncDataModuleTemplate__64entry_5/fm.log'
DIRTY = REPO / 'evidence/e47e713399e0/PipelineConnectPipe/fm.log'
INJ = "Error: Unknown name: 'r:/WORK/SyncDataModuleTemplate__64entry_5/x_reg[0]' (FM-036)\n"

ok = True
def ck(label, good, detail=''):
    global ok
    ok &= bool(good)
    print('  %s  %s  %s' % ('ok  ' if good else 'FAIL', label, detail))

def run(txt, top):
    return verdict(txt, 0, 'signoff-strict', top)

clean = CLEAN.read_text(errors='replace')
dirty = DIRTY.read_text(errors='replace')
T5 = 'SyncDataModuleTemplate__64entry_5'

v, q = run(clean, T5)
ck('A clean 原样 -> SUCCEEDED', v == 'SUCCEEDED' and 'unknown_name_errors' not in q, '%s %s' % (v, q.get('reason')))

cut = clean.index('\n', len(clean) // 2) + 1
v, q = run(clean[:cut] + INJ + clean[cut:], T5)
ck('B 注入 1 行行首 Error: Unknown name -> PARTIAL', v == 'PARTIAL' and q.get('unknown_name_errors') == 1
   and 'unknown_name_errors' in (q.get('reason') or ''), '%s %s' % (v, q.get('reason')))

noise = ("# set_user_match 对不存在的名字只写一行 Error: Unknown name (FM-036)\n"
         "    # Error: Unknown name: 'r:/WORK/x' (FM-036)\n"
         "  Error: Unknown name: indented echo, not a real message\n"
         "PIN_NOTE: see FM-036 / Unknown name in comments\n")
v, q = run(clean[:cut] + noise + clean[cut:], T5)
ck('C 注释/缩进里的 Unknown name / FM-036 -> 仍 SUCCEEDED', v == 'SUCCEEDED' and 'unknown_name_errors' not in q,
   '%s %s' % (v, q.get('reason')))

v, q = run(dirty, 'PipelineConnectPipe')
ck('D 修之前的真实日志 -> PARTIAL，计数 74', v == 'PARTIAL' and q.get('unknown_name_errors') == 74,
   '%s %s' % (v, q.get('reason')))

failed = clean.replace('Verification SUCCEEDED', 'Verification FAILED')
fcut = failed.index('\n', len(failed) // 2) + 1
v0, _ = run(failed, T5)
v1, q1 = run(failed[:fcut] + INJ + failed[fcut:], T5)
ck('E 非绿结论不被改写（只收紧绿灯）', v0 != 'SUCCEEDED' and v1 == v0, '%s -> %s' % (v0, v1))

print('unknown-name 判据负测' + ('全过' if ok else '★有失败★'))
sys.exit(0 if ok else 1)
