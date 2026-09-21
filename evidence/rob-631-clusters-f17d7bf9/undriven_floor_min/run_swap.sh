#!/usr/bin/env bash
# Soundness probe for `verification_set_undriven_signals`.
#
# swap_ref.sv  : o1 = g_0 ; o2 = g_1   (g_0, g_1 declared, never driven)
# swap_impl.sv : o1 = g_1 ; o2 = g_0   -- the two undriven sources are SWAPPED.
#
# A sound treatment of undriven signals must call this NOT equivalent: which
# dangling source reaches which output is a real structural difference.
# Usage: ./run_swap.sh <undriven-setting>
set -eu
UND=${1:-binary}
cat > /tmp/_swap_$$.tcl <<TCL
set_app_var verification_set_undriven_signals $UND
read_sverilog -r -define {SYNTHESIS} swap_ref.sv
set_top r:/WORK/S
read_sverilog -i -define {SYNTHESIS} swap_impl.sv
set_top i:/WORK/S
match
verify
exit
TCL
fm_shell -64 -work_path /tmp/_swapwork_$$ -file /tmp/_swap_$$.tcl < /dev/null 2>&1 \
  | grep -E '^Verification|Passing compare|Failing compare'
rm -rf /tmp/_swap_$$.tcl /tmp/_swapwork_$$
