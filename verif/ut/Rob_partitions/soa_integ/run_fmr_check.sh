#!/usr/bin/env bash
# Impl-only FMR gate for SoA integration. Reads SoA core via read_sverilog -i and
# greps FMR_VLOG-091 / FMR_ELAB-118 counts (must be 0). Fast (~1-2 min, no golden).
set -u
LABEL="${1:-base}"
RTL=/tmp/rob-soa-integ/rtl/backend
G=/home/eda/xs-env/G0-canonical/golden-rtl
EV=/tmp/rob-soa-integ-evidence/fmr_${LABEL}
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"
# impl srcs: SoA core + pkg + lsq outputs + wrapper (+ symmetric golden child deps so
# the wrapper's child instances resolve; they're black-boxed via unresolved_modules).
export FMR_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv \
$G/VTypeBuffer.sv $G/DummyDPICWrapper.sv $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv \
$G/SnapshotGenerator_1.sv $G/SnapshotGenerator_2.sv $G/DataModule__16entry_12.sv \
$RTL/Rob_difftest_stubs.sv"
export FMR_TOP="Rob"
fm_shell -64 -work_path "$EV/fm_work" -file /tmp/rob-soa-integ-evidence/fmr_check.tcl \
  > fm.log 2>&1
RC=$?
F091=$(grep -cE 'FMR_VLOG-091' fm.log)
F118=$(grep -cE 'FMR_ELAB-118' fm.log)
FELAB=$(grep -oE 'FMR_ELAB-[0-9]+' fm.log | sort | uniq -c)
FVLOG=$(grep -oE 'FMR_VLOG-[0-9]+' fm.log | sort | uniq -c)
echo "FMR_CHECK label=$LABEL rc=$RC VLOG-091=$F091 ELAB-118=$F118"
echo "  all FMR_ELAB: ${FELAB:-none}"
echo "  all FMR_VLOG: ${FVLOG:-none}"
grep -E 'FMR_CHECK_ELABORATE_DONE|Error:|FM-' fm.log | grep -vE 'FM-036|black_box' | tail -10
