#!/usr/bin/env python3
"""fm_verdict 负向测试(2026-07)。覆盖审查要求的全部陷阱——这些**必须**先绿才允许 sweep。
每个用例都是一个能骗过旧 `grep SUCCEEDED` 的真实场景。"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_verdict import verdict

# 模拟 Formality 回显 Tcl 源码(含未执行分支的 puts)—— 这是假绿灯 bug 的根源
TCL_ECHO = (
    '    if {[verify]} {\n'
    '        puts "FM_RESULT: Verification SUCCEEDED for $top"\n'
    '    } else {\n'
    '        puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"\n'
    '    }\n'
)

def stats(failing=0, unver=0, unmatch=0, abort=0, unread=0):
    # 复刻真实 FM report 表格式(末列 TOTAL);Unmatched 为 "N(N) Unmatched ... compare points"。
    return (f"Passing (equivalent)      100  0 0 0 0 0 0  100\n"
            f"Failing (not equivalent)   {failing} 0 0 0 0 0 0  {failing}\n"
            + (f"Unverified  {unver} 0 0 0 0 0 0  {unver}\n" if unver else "")
            + (f" {unmatch}({unmatch}) Unmatched reference(implementation) compare points\n" if unmatch else "")
            + (f"Aborted  {abort} 0 0 0 0 0 0  {abort}\n" if abort else "")
            + (f"Not Compared\n  Unread  {unread} 0 0 0 0 0 0  {unread}\n" if unread else ""))

CASES = []
def case(name, text, rc, mode, want):
    CASES.append((name, text, rc, mode, want))

# 1. 日志回显未执行的 SUCCEEDED, 实际 emit FAILED —— 旧 grep 会误判 SUCCEEDED
case("echo_unexecuted_success",
     TCL_ECHO + stats(failing=20) + "FM_RESULT: Verification FAILED or INCONCLUSIVE for Backend\n",
     0, "signoff-strict", "FAILED")

# 2. SUCCEEDED marker 但 failing>0 (自相矛盾) —— 打回 FAILED
case("success_marker_but_failing",
     stats(failing=20) + "FM_RESULT: Verification SUCCEEDED for X\n",
     0, "signoff-strict", "FAILED")

# 3. 真干净 SUCCEEDED (failing=0/unver=0/unmatch=0)
case("clean_success",
     TCL_ECHO + stats(failing=0) + "FM_RESULT: Verification SUCCEEDED for Bku\n",
     0, "signoff-strict", "SUCCEEDED")

# 4. WAIVED 绝不算 SUCCEEDED
case("waived_not_success",
     stats(failing=20) + "FM_RESULT: Verification WAIVED for MemBlock (perf false-positive; 20 pts)\n",
     0, "signoff-strict", "WAIVED")

# 5. make 非零返回码 → ERROR (即便日志看似成功)
case("nonzero_make_rc",
     stats(failing=0) + "FM_RESULT: Verification SUCCEEDED for X\n",
     2, "signoff-strict", "ERROR")

# 6. 多个终态 marker (拼接了历史/多variant日志) → ERROR
case("multiple_markers",
     "FM_RESULT: Verification SUCCEEDED for A\nFM_RESULT: Verification SUCCEEDED for B\n",
     0, "signoff-strict", "ERROR")

# 7. 缺失 marker (被 SIGTERM/超时杀掉) → ERROR
case("missing_marker",
     TCL_ECHO + "Status: Merging duplicated registers...\nProcess terminated by kill.\n",
     0, "signoff-strict", "ERROR")

# 8. NOT RUN (reference 黑盒, vacuous) → UNRUN
case("notrun_blackbox",
     "Error: The reference design 'r:/WORK/StorePipe' is a black box. (FM-081)\nVerification NOT RUN\n",
     0, "signoff-strict", "UNRUN")

# 9. SUCCEEDED 但有 unverified (strict 拒绝) → PARTIAL
case("success_with_unverified_strict",
     stats(failing=0, unver=100) + "FM_RESULT: Verification SUCCEEDED for XSCore\n",
     0, "signoff-strict", "PARTIAL")

# 10. SUCCEEDED 但有 unmatched (strict 拒绝) → PARTIAL
case("success_with_unmatched_strict",
     stats(failing=0, unmatch=31196) + "FM_RESULT: Verification SUCCEEDED for XSCore\n",
     0, "signoff-strict", "PARTIAL")

# 11. SUCCEEDED marker 但完全没有 report 统计行 → 无法确认 failing=0 → fail-closed ERROR
case("success_no_stats",
     TCL_ECHO + "FM_RESULT: Verification SUCCEEDED for X\n",
     0, "signoff-strict", "ERROR")

# 12. assembly 模式: 有 unmatched 但 failing=0 —— 本层放行(上层按 allowlist 复核), 不叫 strict SUCCEEDED
case("assembly_unmatched_ok",
     stats(failing=0, unmatch=5) + "FM_RESULT: Verification SUCCEEDED for Backend\n",
     0, "assembly", "SUCCEEDED")

# 13. P0: SUCCEEDED marker + failing=0 但有 unread 未验证点(fm_eq.tcl 禁验 unread)→ strict 拒 PARTIAL
case("success_with_unread_strict",
     stats(failing=0, unread=1) + "FM_RESULT: Verification SUCCEEDED for Bku\n",
     0, "signoff-strict", "PARTIAL")

# 14. 未配对 unread(Unmatched ... unread points)同样 strict 拒
case("success_with_unmatched_unread",
     stats(failing=0) + " 20(20) Unmatched reference(implementation) unread points\n"
     + "FM_RESULT: Verification SUCCEEDED for Bku\n",
     0, "signoff-strict", "PARTIAL")

def main():
    npass = 0
    for name, text, rc, mode, want in CASES:
        got, q = verdict(text, rc, mode)
        ok = got == want
        npass += ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:34s} want={want:10s} got={got:10s}"
              + ("" if ok else f"  quals={q}"))
    print(f"\n{npass}/{len(CASES)} passed")
    sys.exit(0 if npass == len(CASES) else 1)

if __name__ == "__main__":
    main()
