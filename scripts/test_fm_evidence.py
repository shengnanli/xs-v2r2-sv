#!/usr/bin/env python3
"""FM 失败侧证据链的负测。

背景（真实事故）: FCVT 的 native Formal 报了 20 个 failing compare points，
但 evidence/<commit>/FCVT/ 里**没有任何一处记着"是哪 20 个"**——
unmatched.rpt 是空的（unmatched=0），native_facts.json 只有计数。
诊断只能手写 tcl 重跑一遍 verify（130 秒）才拿到点名；大目标要几十分钟到几小时。
同时 fm_verdict.py 在 native FAILED 时 passing/failing/unverified 全是 null
（数字采集长在 SUCCEEDED 分支里，FAILED 早早 return 了）。

本文件锁两件事:
  A. fm_verdict.py 在**失败**日志上也给出真实数字与 reason，且畸形日志 fail-closed；
  B. scripts/sidecar/fm_native_emit.tcl 的失败侧采集：落盘点名清单、
     查询失败真的非零退出、超限不静默截断。

⚠ 本工程有过"测试假通过"的教训——三条断言全被前置的 dirty 门挡掉，测试却报 PASS。
   所以这里每条负测都**断言失败原因里含预期关键字**（而不是只断言"不是 SUCCEEDED"），
   并且有 test_fixtures_reach_the_intended_gate 专门证明 fixture 没有被更早的闸拦下。

关于 FCVT 样本的性质（reviewer 0146 提示，务必别误读）:
   evidence/7cdbed029dfc/FCVT/fm.log 里那 20 个 failing 的根因**不是 RTL 功能差异**，
   而是两级流水寄存器被 Formality 名字匹配配反了（词干 mvResult_s* vs result_r*，
   退化成比尾部序号）。钉上 128 位精确双射后 raw FM 变成 SUCCEEDED/2509 passing。
   这份日志作为"真实发生过的失败形态"仍然是有效的解析样本，仅此而已。

用法: python3 scripts/test_fm_evidence.py
"""
import importlib.util
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
HOME = HERE.parent
EVID = HOME / 'evidence' / '7cdbed029dfc'
FCVT_LOG = EVID / 'FCVT' / 'fm.log'          # 真实 FAILED 样本 2249/20/240
FMA_LOG = EVID / 'FMA' / 'fm.log'            # 真实 SUCCEEDED 样本 4101/0
ALU_LOG = HOME / 'evidence' / '26c4bf21b739' / 'Alu' / 'fm.log'   # matched=0/unmatched=450
EMIT_TCL = HERE / 'sidecar' / 'fm_native_emit.tcl'

sys.path.insert(0, str(HERE))
_spec = importlib.util.spec_from_file_location('fm_verdict', HERE / 'fm_verdict.py')
V = importlib.util.module_from_spec(_spec)
sys.modules['fm_verdict'] = V
_spec.loader.exec_module(V)

FAILURES = []
PASSES = []


def check(name, cond, detail=''):
    if cond:
        PASSES.append(name)
    else:
        FAILURES.append(f'{name}: {detail}')


def expect_reason(name, verdict_tuple, want_verdict, want_reason_substr):
    """断言判定名 **且** reason 含预期关键字。

    只断言 verdict 名是不够的：ERROR 可能来自 make_rc_nonzero / no_marker 这些
    **更早的闸**，那样测试通过了却根本没碰到被测判据（本工程的假通过教训）。
    """
    v, q = verdict_tuple
    r = q.get('reason') or ''
    ok = (v == want_verdict) and (want_reason_substr in r)
    check(name, ok, f'got verdict={v} reason={r!r}, want {want_verdict} reason~{want_reason_substr!r}')


# ----------------------------------------------------------------------------
# A. fm_verdict.py 解析
# ----------------------------------------------------------------------------

def test_real_failing_log_numbers():
    """(任务 3-①) 真实失败日志必须解析出 2249/20/240。"""
    txt = FCVT_LOG.read_text()
    v, q = V.verdict(txt, 0, 'signoff-strict', 'FCVT')
    check('real_failing:verdict_FAILED', v == 'FAILED', f'got {v}')
    check('real_failing:passing=2249', q['passing'] == 2249, f"got {q['passing']}")
    check('real_failing:failing=20', q['failing'] == 20, f"got {q['failing']}")
    check('real_failing:unverified=240', q['unverified'] == 240, f"got {q['unverified']}")
    # 修复前这三个全是 null —— 断言"不再是 null"正是本次修复的核心
    check('real_failing:no_null_numbers',
          None not in (q['passing'], q['failing'], q['unverified']),
          f'passing={q["passing"]} failing={q["failing"]} unverified={q["unverified"]}')
    check('real_failing:reason_not_null', q['reason'], f"reason={q['reason']!r}")
    check('real_failing:reason_has_counts',
          'failing=20' in (q['reason'] or '') and 'unverified=240' in (q['reason'] or ''),
          f"reason={q['reason']!r}")


def test_real_success_log():
    """(任务 3-②) 成功日志解析正常且 failing=0，判定仍是 SUCCEEDED。"""
    txt = FMA_LOG.read_text()
    v, q = V.verdict(txt, 0, 'signoff-strict', 'FMA')
    check('real_success:verdict_SUCCEEDED', v == 'SUCCEEDED', f'got {v} reason={q.get("reason")}')
    check('real_success:failing=0', q['failing'] == 0, f"got {q['failing']}")
    check('real_success:passing=4101', q['passing'] == 4101, f"got {q['passing']}")
    check('real_success:reason_is_none', q['reason'] is None, f"reason={q['reason']!r}")


def test_zero_category_without_table_row():
    """(reviewer ④) FM 对全零类别不出表行；散文 "0 Aborted compare points" 必须兜底。

    FCVT 的表里没有 Aborted 行，修复前 aborted=null。null 会悄悄通过
    strict 的 `not in (0, None)` 闸——这正是"分不清 0 和不知道"的 fail-open 温床。
    """
    txt = FCVT_LOG.read_text()
    _, q = V.verdict(txt, 0, 'signoff-strict', 'FCVT')
    tbl = V._last_table(txt)
    check('zero_cat:table_really_has_no_aborted_row',
          V._row_int(tbl, 'aborted') is None,
          'fixture 前提不成立: 表里居然有 Aborted 行')
    check('zero_cat:aborted_filled_to_0', q['aborted'] == 0, f"got {q['aborted']}")


def test_unmatched_failing_not_reported_as_zero():
    """(reviewer ③) matched failing=0 但 unmatched failing=450，不能报成 "0 个失败"。

    真实样本 Alu: 表 `Failing (not equivalent)` = 0，散文 450(0 matched, 450 unmatched)。
    只看表会把"450 个点在失败"读成"0 个点在失败"。
    """
    if not ALU_LOG.exists():
        check('unmatched_failing:sample_exists', False, f'缺样本 {ALU_LOG}')
        return
    txt = ALU_LOG.read_text()
    v, q = V.verdict(txt, 0, 'signoff-strict', 'Alu')
    check('unmatched_failing:table_row_is_0', q['failing'] == 0, f"got {q['failing']}")
    check('unmatched_failing:total_is_450', q['failing_total'] == 450, f"got {q['failing_total']}")
    check('unmatched_failing:matched_is_0', q['failing_matched'] == 0, f"got {q['failing_matched']}")
    check('unmatched_failing:unmatched_is_450',
          q['failing_unmatched'] == 450, f"got {q['failing_unmatched']}")
    check('unmatched_failing:reason_shows_450',
          'failing=450' in (q['reason'] or ''), f"reason={q['reason']!r}")
    check('unmatched_failing:verdict_FAILED', v == 'FAILED', f'got {v}')


# ---- 畸形/截断日志: 必须判错，不得静默放行 --------------------------------

_SUCC_TAIL = '''
********************************* Verification Results *********************************
Verification SUCCEEDED
----------------------
 Reference design: r:/WORK/T
 Implementation design: i:/WORK/T
 100 Passing compare points
----------------------------------------------------------------------------------------
Matched Compare Points     BBPin    Loop   BBNet     Cut    Port     DFF     LAT   TOTAL
----------------------------------------------------------------------------------------
Passing (equivalent)           0       0       0       0     100       0       0     100
Failing (not equivalent)       0       0       0       0       0       0       0       0
****************************************************************************************
FM_RESULT: Verification SUCCEEDED for T
'''


def test_truncated_log_no_table():
    """成功 marker 但汇总表被截掉 → ERROR（不得因为"没看到 failing"就放行）。"""
    txt = 'FM_RESULT: Verification SUCCEEDED for T\n'
    expect_reason('malformed:no_summary_table',
                  V.verdict(txt, 0, 'signoff-strict', 'T'), 'ERROR', 'no_summary_table')


def test_native_failed_but_summary_missing():
    """(reviewer ⑤) native FAILED 且汇总表缺失 → 仍判 FAILED，且 reason 说明表没了。"""
    txt = ('Verification FAILED\n'
           'FM_RESULT: Verification FAILED or INCONCLUSIVE for T\n')
    expect_reason('malformed:failed_no_summary_table',
                  V.verdict(txt, 0, 'signoff-strict', 'T'), 'FAILED', 'no_summary_table')


def test_table_without_failing_row():
    """表在但 Failing 行被截掉 → ERROR（不确定，fail-closed）。"""
    txt = _SUCC_TAIL.replace(
        'Failing (not equivalent)       0       0       0       0       0       0       0       0\n', '')
    expect_reason('malformed:failing_row_missing',
                  V.verdict(txt, 0, 'signoff-strict', 'T'), 'ERROR', 'failing_row_missing')


def test_prose_table_mismatch_is_fail_closed():
    """(reviewer ⑥ · 最关键) 表与散文对不上 → 必须判失败，不许挑一个信。"""
    # 散文说 100 passing，表说 999 —— 两个来源矛盾
    txt = _SUCC_TAIL.replace(
        'Passing (equivalent)           0       0       0       0     100       0       0     100',
        'Passing (equivalent)           0       0       0       0     999       0       0     999')
    expect_reason('mismatch:passing_table_vs_prose',
                  V.verdict(txt, 0, 'signoff-strict', 'T'), 'ERROR', 'stats_inconsistent:passing')

    # 表 failing=7，但没有任何散文失败行（散文失败行只在有失败点时出现）
    txt2 = _SUCC_TAIL.replace(
        'Failing (not equivalent)       0       0       0       0       0       0       0       0',
        'Failing (not equivalent)       0       0       0       0       0       7       0       7')
    expect_reason('mismatch:failing_table_vs_prose_absent',
                  V.verdict(txt2, 0, 'signoff-strict', 'T'), 'ERROR', 'stats_inconsistent:failing')

    # 散文自相矛盾: total != matched + unmatched
    txt3 = _SUCC_TAIL.replace(
        ' 100 Passing compare points',
        ' 100 Passing compare points\n 9 Failing compare points (2 matched, 3 unmatched)')
    expect_reason('mismatch:prose_total_ne_matched_plus_unmatched',
                  V.verdict(txt3, 0, 'signoff-strict', 'T'), 'ERROR', 'stats_inconsistent:failing')

    # 有表却没有 "Verification Results" 段头 = 日志被裁剪，两来源无法互证
    txt4 = '\n'.join(l for l in _SUCC_TAIL.splitlines()
                     if 'Verification Results' not in l)
    expect_reason('mismatch:no_results_block',
                  V.verdict(txt4, 0, 'signoff-strict', 'T'), 'ERROR', 'no_results_block')


def _two_round_log(first_block, last_block):
    """同一会话跑了两轮 verify：两个结果段，但只有一个 FM_RESULT marker。"""
    return first_block + '\n' + last_block


_FAIL_BLOCK = '''********************************* Verification Results *********************************
Verification FAILED
-------------------
 Reference design: r:/WORK/T
 Implementation design: i:/WORK/T
 50 Passing compare points
 7 Failing compare points (7 matched, 0 unmatched)
 0 Aborted compare points
 3 Unverified compare points
----------------------------------------------------------------------------------------
Matched Compare Points     BBPin    Loop   BBNet     Cut    Port     DFF     LAT   TOTAL
----------------------------------------------------------------------------------------
Passing (equivalent)           0       0       0       0      50       0       0      50
Failing (not equivalent)       0       0       0       0       0       7       0       7
Unverified                     0       0       0       0       3       0       0       3
****************************************************************************************
'''

_FAIL_BLOCK2 = _FAIL_BLOCK.replace('7 Failing compare points (7 matched, 0 unmatched)',
                                   '9 Failing compare points (9 matched, 0 unmatched)') \
                          .replace('       0       7       0       7',
                                   '       0       9       0       9')


def test_two_rounds_last_wins():
    """(reviewer ①) 第一轮 FAILED、末轮 SUCCEEDED → 必须取**末轮**。

    这是 reviewer 0146 P0 的核心：散文原来用 search() 取第一个，
    表和 native verdict 取最后一个，两者会错配。
    """
    txt = _two_round_log(_FAIL_BLOCK, _SUCC_TAIL.strip())
    v, q = V.verdict(txt, 0, 'signoff-strict', 'T')
    check('two_rounds:last_wins_verdict', v == 'SUCCEEDED', f'got {v} reason={q.get("reason")}')
    check('two_rounds:last_wins_passing', q['passing'] == 100, f"got {q['passing']}")
    check('two_rounds:last_wins_failing', q['failing'] == 0, f"got {q['failing']}")
    check('two_rounds:first_round_7_not_leaked',
          q['failing_total'] in (0, None), f"failing_total={q['failing_total']}")


def test_two_rounds_different_numbers():
    """(reviewer ②) 两轮都失败但数字不同 → 取末轮的数字（9，不是 7）。"""
    txt = _two_round_log(_FAIL_BLOCK, _FAIL_BLOCK2) + \
        'FM_RESULT: Verification FAILED or INCONCLUSIVE for T\n'
    v, q = V.verdict(txt, 0, 'signoff-strict', 'T')
    check('two_rounds_diff:verdict_FAILED', v == 'FAILED', f'got {v}')
    check('two_rounds_diff:failing_is_last_round_9', q['failing'] == 9, f"got {q['failing']}")
    check('two_rounds_diff:total_is_last_round_9',
          q['failing_total'] == 9, f"got {q['failing_total']}")
    check('two_rounds_diff:reason_says_9',
          'failing=9' in (q['reason'] or ''), f"reason={q['reason']!r}")


def test_fixtures_reach_the_intended_gate():
    """防"假通过": 证明上面的畸形 fixture 不是被更早的闸拦下的。

    本工程真出过这事——三条断言全被前置 dirty 门挡掉，测试照样 PASS。
    这里逐条确认: fixture 有且只有一个 marker、top 对得上、make_rc=0，
    所以它们确实走到了被测的解析判据，而不是死在 no_marker/wrong_top/make_rc_nonzero。
    """
    fixtures = {
        'succ_tail': _SUCC_TAIL,
        'fail_block_with_marker': _FAIL_BLOCK + 'FM_RESULT: Verification FAILED or INCONCLUSIVE for T\n',
    }
    for nm, txt in fixtures.items():
        marks = V._MARKER.findall(txt)
        check(f'gate_witness:{nm}:exactly_one_marker', len(marks) == 1, f'got {len(marks)}')
        if marks:
            check(f'gate_witness:{nm}:top_is_T', marks[0][1] == 'T', f'got {marks[0][1]!r}')

    # 反证: 换成"更早的闸"应当给出**不同**的 reason，说明我们分得清
    expect_reason('gate_witness:make_rc_gate_is_distinct',
                  V.verdict(_SUCC_TAIL, 1, 'signoff-strict', 'T'), 'ERROR', 'make_rc_nonzero')
    expect_reason('gate_witness:no_marker_gate_is_distinct',
                  V.verdict('nothing here\n', 0, 'signoff-strict', 'T'), 'ERROR', 'no_marker')
    expect_reason('gate_witness:wrong_top_gate_is_distinct',
                  V.verdict(_SUCC_TAIL, 0, 'signoff-strict', 'OTHER'), 'ERROR', 'wrong_top')


# ----------------------------------------------------------------------------
# B. sidecar 失败侧采集（真跑 tclsh，不是纸上推理）
# ----------------------------------------------------------------------------

_BB_RPT = '''**************************************************
Report         : black_boxes

Reference      : r:/WORK/T
Implementation : i:/WORK/T
Version        : V-2023.12-SP3
Date           : Sat Sep 12 12:50:44 2026
**************************************************
Information: Reporting black boxes for current reference and implementation designs. (FM-184)
Information: No 'black boxes' matched current 'reference and implementation designs'. (FM-249)
1'''

_HARNESS = r'''
# tclsh 桩: 用假的 FM 命令驱动真的 sidecar 代码。
set OUT      [lindex $argv 0]
set MODE     [lindex $argv 1]   ;# ok | queryfail | emptybody | trunc | nofail
set NFAIL    [lindex $argv 2]

set ::env(FM_SIDECAR_OUT) $OUT
set ::env(FM_RUN_ID) "T-test"

# redirect -variable VAR SCRIPT: 桩成"执行 script, 拿返回值当捕获文本"
proc redirect {args} {
    set var    [lindex $args 1]
    set script [lindex $args 2]
    upvar 1 $var v
    set v [uplevel 1 $script]
    return ""
}
proc get_app_var {k} {
    if {$k eq "verification_status"} { return "FAILED" }
    return ""
}

# 造 NFAIL 个成对失败点（模仿 FCVT: result_r_1_reg[i] <-> u_core/mvResult_s1_reg[i]）
proc noncontig_bits {} {
    # 真实 FCVT 形态: {0,1,10..27} 共 20 位
    set b {0 1}
    for {set i 10} {$i <= 27} {incr i} { lappend b $i }
    return $b
}
proc mk_fail_list {n} {
    global MODE
    if {$MODE eq "noncontig"} {
        set l {}
        foreach i [noncontig_bits] {
            lappend l [list "r:/WORK/T/result_r_1_reg\[$i\]" "i:/WORK/T/u_core/mvResult_s1_reg\[$i\]"]
        }
        return $l
    }
    set l {}
    for {set i 0} {$i < $n} {incr i} {
        lappend l [list "r:/WORK/T/result_r_1_reg\[$i\]" "i:/WORK/T/u_core/mvResult_s1_reg\[$i\]"]
    }
    return $l
}
proc mk_fail_text {n} {
    global MODE
    if {$MODE eq "noncontig"} {
        set t "**********\nReport         : failing_points\n**********\n"
        foreach i [noncontig_bits] {
            append t "r:/WORK/T/result_r_1_reg\[$i\]\ti:/WORK/T/u_core/mvResult_s1_reg\[$i\]\n"
        }
        append t "1"
        return $t
    }
    set t "**************************************************\n"
    append t "Report         : failing_points\n\n"
    append t "Reference      : r:/WORK/T\n**************************************************\n"
    for {set i 0} {$i < $n} {incr i} {
        append t "r:/WORK/T/result_r_1_reg\[$i\]\ti:/WORK/T/u_core/mvResult_s1_reg\[$i\]\n"
    }
    append t "1"
    return $t
}

proc report_failing_points {args} {
    global MODE NFAIL
    if {[lsearch -exact $args "-list"] >= 0} { return [mk_fail_list $NFAIL] }
    # 无 -list = 原文报告
    switch -- $MODE {
        queryfail { error "FM-999 simulated query failure" }
        emptybody { return "**********\nReport         : failing_points\nNo failing points.\n1" }
        default   { return [mk_fail_text $NFAIL] }
    }
}
proc report_passing_points {args}    { return {} }
proc report_unverified_points {args} {
    if {[lsearch -exact $args "-list"] >= 0} { return {} }
    return "**********\nReport         : unverified_points\nNo unverified points.\n1"
}
proc report_aborted_points {args} {
    if {[lsearch -exact $args "-list"] >= 0} { return {} }
    return "**********\nReport         : aborted_points\nNo aborted points.\n1"
}
proc report_matched_points {args}   { return {} }
proc report_unmatched_points {args} { return {} }
proc report_black_boxes {args}      { global BB; return $BB }
proc report_dont_verify_points {args} {
    return "**********\nReport         : dont_verify_points\nDon't verify points: None\n1"
}

source SIDECAR_TCL_PATH
set BB [read [open BB_RPT_PATH r]]

# appvar readback 桩（verify 前本应由 sidecar_capture_appvars 填）
array set ::SIDECAR_AV {
    verification_verify_unread_compare_points false
    verification_verify_matched_unread_compare_points false
    verification_verify_unread_bbox_inputs false
    verification_verify_matched_unread_bbox_inputs true
    verification_verify_unread_tech_cell_pins true
    verification_verify_unread_tech_cell_pg_pins true
    hdlin_unresolved_modules black_box
    hdlin_interface_only {}
    verification_merge_duplicated_registers true
}

sidecar_emit T
exit 0
'''


def _run_harness(mode, nfail, cap=None):
    tmp = pathlib.Path(tempfile.mkdtemp(prefix='fmevid_'))
    try:
        out = tmp / 'sidecar'
        out.mkdir()
        bb = tmp / 'bb.rpt'
        bb.write_text(_BB_RPT)
        h = tmp / 'h.tcl'
        h.write_text(_HARNESS
                     .replace('SIDECAR_TCL_PATH', str(EMIT_TCL))
                     .replace('BB_RPT_PATH', str(bb)))
        env = dict(os.environ)
        env.pop('FM_SIDECAR_POINTS_MAX', None)
        if cap is not None:
            env['FM_SIDECAR_POINTS_MAX'] = str(cap)
        p = subprocess.run(['tclsh', str(h), str(out), mode, str(nfail)],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           universal_newlines=True, env=env, timeout=120)
        files = {f.name: (out / f.name).read_text() for f in out.iterdir()}
        return p, files, out
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_sidecar_writes_failing_points():
    """(任务 1) 正常失败场景：三个清单文件 + native_facts.json 的结构化摘要。"""
    p, files, _ = _run_harness('ok', 20)
    check('sidecar:ok_exit0', p.returncode == 0, f'rc={p.returncode} err={p.stderr[-400:]}')
    for f in ('failing_points.txt', 'unverified_points.txt',
              'aborted_points.txt', 'native_facts.json'):
        check(f'sidecar:ok_has_{f}', f in files, f'files={sorted(files)}')
    if 'failing_points.txt' in files:
        check('sidecar:failing_txt_has_points',
              files['failing_points.txt'].count('result_r_1_reg') == 20,
              f"count={files['failing_points.txt'].count('result_r_1_reg')}")
    if 'native_facts.json' in files:
        d = json.loads(files['native_facts.json'])
        fl = d.get('failures', {}).get('failing', {})
        check('sidecar:json_total_20', fl.get('total') == 20, f'got {fl.get("total")}')
        check('sidecar:json_not_truncated', fl.get('truncated') is False, f'got {fl.get("truncated")}')
        check('sidecar:json_pairs_20', len(fl.get('pairs', [])) == 20, f'got {len(fl.get("pairs", []))}')
        br = fl.get('by_register', [])
        check('sidecar:by_register_merged_to_1', len(br) == 1, f'got {len(br)} -> {br}')
        if br:
            check('sidecar:by_register_count_20', br[0].get('count') == 20, f'got {br[0]}')
            check('sidecar:by_register_bits_0_19',
                  br[0].get('bit_lo') == 0 and br[0].get('bit_hi') == 19, f'got {br[0]}')
            # 0..19 连续 20 位 -> contiguous 必须为 true
            check('sidecar:by_register_contiguous_true',
                  br[0].get('contiguous') is True, f'got {br[0]}')
            check('sidecar:by_register_ref_stem',
                  br[0].get('ref', '').endswith('result_r_1_reg'), f'got {br[0].get("ref")}')
            check('sidecar:by_register_impl_stem',
                  br[0].get('impl', '').endswith('mvResult_s1_reg'), f'got {br[0].get("impl")}')


def test_sidecar_noncontiguous_bits_flagged():
    """真实 FCVT 的 20 个失败位是 {0,1,10..27}——**不连续**。

    只给 bit_lo/bit_hi(0/27) 会被读成"连续 28 位"，与 count=20 矛盾却不显形，
    所以必须显式标 contiguous=false。
    """
    p, files, _ = _run_harness('noncontig', 0)
    check('sidecar:noncontig_exit0', p.returncode == 0, f'rc={p.returncode} out={p.stdout[-300:]}')
    if 'native_facts.json' in files:
        br = json.loads(files['native_facts.json'])['failures']['failing']['by_register']
        check('sidecar:noncontig_one_reg', len(br) == 1, f'got {br}')
        if br:
            check('sidecar:noncontig_count_20', br[0].get('count') == 20, f'got {br[0]}')
            check('sidecar:noncontig_hi_27', br[0].get('bit_hi') == 27, f'got {br[0]}')
            check('sidecar:noncontig_flag_false',
                  br[0].get('contiguous') is False, f'got {br[0]}')


def test_sidecar_query_failure_exits_nonzero():
    """(任务 3-④) 查询失败必须**真的**非零退出，且不留半成品。"""
    p, files, _ = _run_harness('queryfail', 20)
    check('sidecar:queryfail_nonzero_exit', p.returncode != 0, f'rc={p.returncode}')
    check('sidecar:queryfail_exit_is_4', p.returncode == 4, f'rc={p.returncode}')
    check('sidecar:queryfail_says_report_query_failed',
          'report_query_failed' in (p.stdout + p.stderr),
          f'stdout={p.stdout[-400:]!r}')
    # 关键: 不得留下 native_facts.json（否则下游会当成一次成功采集）
    check('sidecar:queryfail_no_native_facts',
          'native_facts.json' not in files, f'files={sorted(files)}')
    check('sidecar:queryfail_no_tmp_left',
          not any('.tmp.' in f for f in files), f'files={sorted(files)}')


def test_sidecar_empty_report_with_nonzero_count_is_error():
    """计数>0 却报告没有实质内容 = 捕获漏 → 必须炸，不能当成"报告为空"放过。"""
    p, files, _ = _run_harness('emptybody', 20)
    check('sidecar:emptybody_nonzero_exit', p.returncode == 4, f'rc={p.returncode}')
    check('sidecar:emptybody_reason',
          'report_empty_but_count_nonzero' in (p.stdout + p.stderr),
          f'stdout={p.stdout[-400:]!r}')
    check('sidecar:emptybody_no_native_facts',
          'native_facts.json' not in files, f'files={sorted(files)}')


def test_sidecar_empty_report_with_zero_count_is_ok():
    """区分"报告为空"与"查询失败": verify 全过时空报告是合法的，不得报错。"""
    p, files, _ = _run_harness('ok', 0)
    check('sidecar:zero_ok_exit0', p.returncode == 0, f'rc={p.returncode} out={p.stdout[-400:]}')
    check('sidecar:zero_ok_has_native_facts', 'native_facts.json' in files, f'files={sorted(files)}')
    if 'native_facts.json' in files:
        d = json.loads(files['native_facts.json'])
        fl = d.get('failures', {}).get('failing', {})
        check('sidecar:zero_total_0', fl.get('total') == 0, f'got {fl.get("total")}')
        check('sidecar:zero_pairs_empty', fl.get('pairs') == [], f'got {fl.get("pairs")}')


def test_sidecar_truncation_is_loud():
    """超上限必须**明说**已截断+总数，不许静默丢点。"""
    p, files, _ = _run_harness('ok', 10, cap=3)
    check('sidecar:trunc_exit0', p.returncode == 0, f'rc={p.returncode} out={p.stdout[-400:]}')
    body = files.get('failing_points.txt', '')
    check('sidecar:trunc_banner', 'TRUNCATED' in body, f'body head={body[:200]!r}')
    check('sidecar:trunc_states_total', '共 10 条' in body, f'body head={body[:200]!r}')
    check('sidecar:trunc_states_cap', 'cap=3' in body, f'body head={body[:200]!r}')
    if 'native_facts.json' in files:
        d = json.loads(files['native_facts.json'])
        fl = d['failures']['failing']
        check('sidecar:trunc_json_flag', fl.get('truncated') is True, f'got {fl.get("truncated")}')
        check('sidecar:trunc_json_total_is_full_10', fl.get('total') == 10, f'got {fl.get("total")}')
        check('sidecar:trunc_json_pairs_capped', len(fl.get('pairs', [])) == 3,
              f'got {len(fl.get("pairs", []))}')


def test_sidecar_bad_cap_is_rejected():
    """cap 非法值直接炸——不做"看不懂就用默认"的 fail-open。"""
    p, _, _ = _run_harness('ok', 5, cap='abc')
    check('sidecar:bad_cap_nonzero', p.returncode == 4, f'rc={p.returncode}')
    check('sidecar:bad_cap_reason', 'bad_FM_SIDECAR_POINTS_MAX' in (p.stdout + p.stderr),
          f'stdout={p.stdout[-300:]!r}')


def main():
    if not FCVT_LOG.exists() or not FMA_LOG.exists():
        print(f'SKIP: 缺样本日志 {FCVT_LOG} / {FMA_LOG}')
        return 2
    if shutil.which('tclsh') is None:
        print('WARN: 没有 tclsh，sidecar 段无法执行')
    tests = [v for k, v in sorted(globals().items()) if k.startswith('test_')]
    for t in tests:
        try:
            t()
        except Exception as e:                      # noqa: BLE001
            FAILURES.append(f'{t.__name__}: EXCEPTION {e!r}')
    print(f'checks passed: {len(PASSES)}')
    if FAILURES:
        print(f'checks FAILED: {len(FAILURES)}')
        for f in FAILURES:
            print('  FAIL ' + f)
        return 1
    print('ALL OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())
