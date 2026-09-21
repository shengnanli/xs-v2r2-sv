#!/usr/bin/env bash
# Minimal, seconds-long reproduction of the Rob "undriven floor".
#
# T.sv          : golden-shaped. 4 registers declared and NEVER driven, muxed
#                 out to a primary output -- the exact shape of golden Rob's
#                 robDeqGroup_<n>_debug_otherPdest_<m> -> io_commits_info_*.
# T_rewrite_style.sv : the same function written the way the rewrite writes it
#                 (unpacked array inside a core submodule).
#
# Usage:  ./run_floor.sh <undriven-setting>     e.g. ./run_floor.sh binary:X
# Pass impl=self to compare T.sv against ITSELF.
set -eu
UND=${1:-binary:X}
IMPL=${2:-T_rewrite_style.sv}
cat > /tmp/_floor_$$.tcl <<TCL
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_set_undriven_signals $UND
read_sverilog -r -define {SYNTHESIS} T.sv
set_top r:/WORK/T
read_sverilog -i -define {SYNTHESIS} $IMPL
set_top i:/WORK/T
match
puts "FLOOR_REF_UNMATCHED [llength [report_unmatched_points -reference -list]]"
puts "FLOOR_IMPL_UNMATCHED [llength [report_unmatched_points -implementation -list]]"
verify
exit
TCL
fm_shell -64 -work_path /tmp/_floorwork_$$ -file /tmp/_floor_$$.tcl < /dev/null 2>&1 \
  | grep -E 'FLOOR_|^Verification|Passing compare|Failing compare'
rm -rf /tmp/_floor_$$.tcl /tmp/_floorwork_$$
