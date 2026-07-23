#!/usr/bin/env python3
"""fm_verdict 负向测试(2026-07, 二审全 P0 版)。每例针对一个能骗过旧 grep 的真实陷阱。"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_verdict import verdict

TCL_ECHO = (
    '    if {[verify]} {\n'
    '        puts "FM_RESULT: Verification SUCCEEDED for $top"\n'
    '    } else {\n'
    '        puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"\n'
    '    }\n'
)

def table(passing=100, failing=0, unver=None, abort=None, unread_nc=None):
    """复刻最后一个 Matched Compare Points 汇总表(末列 TOTAL)。"""
    s = ("Matched Compare Points     BBPin  Loop  BBNet  Cut  Port  DFF  LAT  TOTAL\n"
         "----\n"
         f"Passing (equivalent)   {passing} 0 0 0 0 0 0  {passing}\n"
         f"Failing (not equivalent)   {failing} 0 0 0 0 0 0  {failing}\n")
    if unver is not None:     s += f"Unverified   {unver} 0 0 0 0 0 0  {unver}\n"
    if abort is not None:     s += f"Aborted   {abort} 0 0 0 0 0 0  {abort}\n"
    if unread_nc is not None: s += f"Not Compared\n  Unread   {unread_nc} 0 0 0 0 0 0  {unread_nc}\n"
    s += "****************************************************************\n"
    return s

def mark(v="SUCCEEDED", top="X"):
    return f"FM_RESULT: Verification {v} for {top}\n"

def native(v):
    return f"Verification {v}\n"

CASES = []
def C(name, text, want, rc=0, mode="signoff-strict", top=None, allowlist=0):
    CASES.append((name, text, rc, mode, top, allowlist, want))

# 假绿灯根源:回显未执行 SUCCEEDED, 实际 FAILED
C("echo_unexecuted_success", TCL_ECHO + native("FAILED") + table(failing=20) + mark("FAILED"), "FAILED")
# SUCCEEDED marker 但 failing>0
C("marker_success_failing>0", table(failing=20) + mark("SUCCEEDED"), "FAILED")
# 干净 strict SUCCEEDED
C("clean_success", table(failing=0) + native("SUCCEEDED") + mark("SUCCEEDED"), "SUCCEEDED")
# WAIVED 绝不升级
C("waived", table(failing=20) + mark("WAIVED"), "WAIVED")
# make 非零 → ERROR
C("nonzero_rc", table(failing=0) + mark("SUCCEEDED"), "ERROR", rc=2)
# 多 marker → ERROR
C("multi_marker", mark("SUCCEEDED", "A") + mark("SUCCEEDED", "B"), "ERROR")
# 缺 marker → ERROR
C("missing_marker", TCL_ECHO + "Process terminated by kill.\n", "ERROR")
# NOT RUN → UNRUN
C("notrun", "reference design 'r:/WORK/StorePipe' is a black box. (FM-081)\nVerification NOT RUN\n", "UNRUN")
# strict: unverified→PARTIAL
C("strict_unverified", table(failing=0, unver=100) + mark("SUCCEEDED"), "PARTIAL")
# strict: unmatched→PARTIAL
C("strict_unmatched", table(failing=0) + " 0(31196) Unmatched reference(implementation) compare points\n" + mark("SUCCEEDED"), "PARTIAL")
# 无汇总表 → ERROR (P0-8)
C("no_table", TCL_ECHO + mark("SUCCEEDED"), "ERROR")
# assembly: 对称 unmatched 在配额内 → SUCCEEDED (P0-2)
C("assembly_unmatched_ok", table(failing=0) + " 5(5) Unmatched reference(implementation) compare points\n" + mark("SUCCEEDED"), "SUCCEEDED", mode="assembly", allowlist=5)
# assembly: 对称 unmatched 超配额 → PARTIAL (P0-2)
C("assembly_unmatched_over", table(failing=0) + " 9(9) Unmatched reference(implementation) compare points\n" + mark("SUCCEEDED"), "PARTIAL", mode="assembly", allowlist=5)
# strict: unread (Not-Compared) → PARTIAL
C("strict_unread_nc", table(failing=0, unread_nc=1) + mark("SUCCEEDED"), "PARTIAL")
# strict: unmatched-unread → PARTIAL
C("strict_unread_um", table(failing=0) + " 20(20) Unmatched reference(implementation) unread points\n" + mark("SUCCEEDED"), "PARTIAL")
# P0-1: 未知 mode → ERROR
C("unknown_mode", table(failing=0) + mark("SUCCEEDED"), "ERROR", mode="signoff")
# P0-1: diagnostic-full 永不 SUCCEEDED → DIAGNOSTIC
C("diagnostic_never_success", table(failing=0) + mark("SUCCEEDED"), "DIAGNOSTIC", mode="diagnostic-full")
# P0-1: shadow → SHADOW_CHECK
C("shadow_only", table(failing=0) + mark("SUCCEEDED"), "SHADOW_CHECK", mode="shadow")
# P0-4: 原生 FAILED 但 marker SUCCEEDED(矛盾)→ FAILED
C("native_failed_marker_success", native("FAILED") + table(failing=0) + mark("SUCCEEDED"), "FAILED")
# P0-5: WrongTop → ERROR
C("wrong_top", table(failing=0) + native("SUCCEEDED") + mark("SUCCEEDED", "WrongMod"), "ERROR", top="Bku")
# P0-5: 正确 top → SUCCEEDED
C("right_top", table(failing=0) + native("SUCCEEDED") + mark("SUCCEEDED", "Bku"), "SUCCEEDED", top="Bku")
# P0-6: strict 有 dont_verify → PARTIAL
C("strict_dontverify", "set_dont_verify_points ...\n" + table(failing=0) + mark("SUCCEEDED"), "PARTIAL")
# P0-6: strict 有 ELAB-147 → PARTIAL
C("strict_elab147", "Warning: FMR_ELAB-147 ...\n" + table(failing=0) + mark("SUCCEEDED"), "PARTIAL")
# P0-7: 较早短格式不得覆盖终态表(早期"5 Failing compare points"但最终表 failing=0)
C("early_shortfmt_ignored", "5 Failing compare points\n" + table(failing=0) + native("SUCCEEDED") + mark("SUCCEEDED"), "SUCCEEDED")
# 对抗-1: 空证明 passing=0 failing=0 → ERROR(不得判绿)
C("empty_proof_passing0", table(passing=0, failing=0) + native("SUCCEEDED") + mark("SUCCEEDED"), "ERROR")
# 对抗-2: 给 expected top 但 marker 无 "for X" → ERROR
C("expected_top_marker_no_top",
  table(failing=0) + native("SUCCEEDED") + "FM_RESULT: Verification SUCCEEDED\n", "ERROR", top="Bku")
# 对抗-3: strict 出现未声明 blackbox(black-box outputs 非0)→ PARTIAL
C("strict_undeclared_blackbox",
  table(failing=0) + " 3(3) Unmatched reference(implementation) black-box outputs\n" + mark("SUCCEEDED"), "PARTIAL")
# 对抗-4: assembly 非对称 5(0) unmatched, 即便 allowlist=5 也 PARTIAL
C("assembly_asymmetric_5_0",
  table(failing=0) + " 5(0) Unmatched reference(implementation) compare points\n" + mark("SUCCEEDED"),
  "PARTIAL", mode="assembly", allowlist=5)
# 对抗-4b: assembly 对称 5(5) 在配额内 → SUCCEEDED
C("assembly_symmetric_5_5",
  table(failing=0) + " 5(5) Unmatched reference(implementation) compare points\n" + mark("SUCCEEDED"),
  "SUCCEEDED", mode="assembly", allowlist=5)

def main():
    npass = 0
    for name, text, rc, mode, top, allow, want in CASES:
        got, q = verdict(text, rc, mode, top, allow)
        ok = got == want
        npass += ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:32s} want={want:12s} got={got:12s}"
              + ("" if ok else f"  reason={q.get('reason')} quals={ {k:q[k] for k in ('failing','unverified','unmatched','unread')} }"))
    print(f"\n{npass}/{len(CASES)} passed")
    sys.exit(0 if npass == len(CASES) else 1)

if __name__ == "__main__":
    main()
