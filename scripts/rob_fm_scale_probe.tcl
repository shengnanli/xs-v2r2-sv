# rob_fm_scale_probe.tcl -- DIAGNOSTIC ONLY, never a signoff.
#
# Why this exists: the previous round (xs-v2r2-sv) never ran a monolithic FM on
# Rob. It went straight to a bespoke 5-way cone-DCE partition and recorded the
# only non-SIGNOFF_PASS verdict in its 306-target release. Nowhere in that
# round's artifacts is there a measurement showing that monolithic was actually
# out of reach -- it was assumed. This probe measures the floor.
#
# What it measures: read_sverilog + set_top (elaborate) and match, with ref and
# impl both fed the *same* G1 golden Rob.sv and all 8 child instances left as
# symmetric unresolved blackboxes. Verify on identical netlists is trivial, so
# this is a LOWER BOUND on a real run -- but elaborate memory is the hard wall
# and it is measured exactly here.
#
# Reproduce:
#   D=<scratch dir with a unique suffix>
#   cp /home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv $D/Rob_impl.sv
#   cd $D && fm_shell -64 -work_path $D/fmwork \
#       -file <repo>/scripts/rob_fm_scale_probe.tcl < /dev/null > $D/probe.log 2>&1
#   (the `< /dev/null` is mandatory: on a script error fm_shell drops into an
#    interactive prompt and sits there holding a license, log frozen mid-file.)
#
# Liveness check while it runs (the parent fm_shell is a /bin/sh wrapper and
# shows 0 CPU forever -- look at the fm_shell_exec child instead):
#   for p in $(pgrep -x fm_shell_exec); do readlink /proc/$p/cwd; done
#   awk '{print $14+$15}' /proc/<pid>/stat     # utime+stime jiffies, must climb

set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers true

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
report_unmatched_points > unmatched.rpt
puts "PROBE_DONE_ELAB_MATCH"
exit 0
