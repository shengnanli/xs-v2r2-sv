# rob_fm_scale_probe.tcl -- DIAGNOSTIC ONLY, never a signoff.
#
# Why this exists
# ---------------
# The previous round (xs-v2r2-sv) never ran a monolithic FM on Rob. It went
# straight to a bespoke 5-way cone-DCE partition and recorded the only
# non-SIGNOFF_PASS verdict in its 306-target release. Nowhere in that round's
# artifacts is there a measurement showing monolithic was actually out of reach
# -- it was assumed. This probe measures the floor.
#
# What it measures: read_sverilog + set_top (elaborate) and match, with ref and
# impl both fed the SAME G1 golden Rob.sv and all 8 child instances left as
# symmetric unresolved blackboxes. Verify on identical netlists is trivial, so
# match/verify here are a LOWER BOUND on a real run -- but elaborate cost is the
# hard wall and it is measured exactly.
#
# ROB_MERGE_DUP selects the variant (default true, the tool default this repo
# uses elsewhere).
#
# Measured (2026-09-18, fm_shell V-2023.12-SP3, G1 Rob.sv sha256
# 4aa8838b95283d5aa1f46161e4abf96de764a6c6cbaff09f189a829ae601f130, 266227 lines,
# 2200 ports, 11,639 registers, 8 children blackboxed):
#
#   variant A  ROB_MERGE_DUP=true
#     ref elaborate   626 s
#     impl elaborate  696 s
#     peak RSS        15.2 GB
#     match           ★NEVER REACHED★ -- terminated by its owner after 5674 s
#                     (1.58 h) of CPU still inside "Merging duplicated registers
#                     in block i:/WORK/Rob". 0 errors; it was progressing, not
#                     hung -- just quadratic on the wrong thing.
#
#   variant B  ROB_MERGE_DUP=false      <- see the header of this file's log
#
# Why variant B is the one that matters: Rob has 11,639 registers and ~79% of
# its 169,763 register bits are 160-entry debug/difftest arrays whose next-state
# functions are structurally identical across entries -- precisely the input that
# makes duplicate-register merging blow up. This repo already turns merging off
# for RenameBuffer and MulUnit, and there it is a STRENGTHENING, not a
# relaxation: nothing is blackboxed, no point is skipped, the reference is not
# constrained. FM is only required to compare registers one by one instead of
# after merging, so compare points can only increase.
#
# Reproduce
#   D=<scratch dir with a unique suffix>            # never a semantic name
#   cp /home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv $D/Rob_impl.sv
#   cd $D && ROB_MERGE_DUP=false fm_shell -64 -work_path $D/fmwork \
#       -file <repo>/scripts/rob_fm_scale_probe.tcl < /dev/null > $D/probe.log 2>&1
#
#   The `< /dev/null` is mandatory: on a script error fm_shell drops into an
#   interactive prompt and sits there holding a license, log frozen mid-file.
#
# Liveness while it runs -- the parent fm_shell is a /bin/sh wrapper and shows
# 0 CPU forever, so watch the fm_shell_exec child:
#   for p in $(pgrep -x fm_shell_exec); do echo "$p $(readlink /proc/$p/cwd)"; done
#   awk '{print $14+$15}' /proc/<pid>/stat     # utime+stime jiffies, must climb
# Stop only by explicit PID you started yourself. Never pkill -f: this machine is
# shared and other lanes' proofs run for hours.

set_app_var hdlin_unresolved_modules black_box

set mergedup "true"
if {[info exists env(ROB_MERGE_DUP)]} { set mergedup $env(ROB_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $mergedup
puts "PROBE_MERGE_DUP $mergedup"

set G /home/eda/xs-env/G1-canonical/golden-rtl

set t0 [clock seconds]
read_sverilog -container r -libname WORK -05 $G/Rob.sv
set_top r:/WORK/Rob
set t1 [clock seconds]
puts "PROBE_REF_ELAB_SEC [expr {$t1-$t0}]"

read_sverilog -container i -libname WORK -05 ./Rob_impl.sv
set_top i:/WORK/Rob
set t2 [clock seconds]
puts "PROBE_IMPL_ELAB_SEC [expr {$t2-$t1}]"

match
set t3 [clock seconds]
puts "PROBE_MATCH_SEC [expr {$t3-$t2}]"
redirect -file unmatched.rpt { report_unmatched_points }
puts "PROBE_MATCH_DONE"

verify
puts "PROBE_VERIFY_SEC [expr {[clock seconds]-$t3}]"
puts "PROBE_DONE"
exit 0
