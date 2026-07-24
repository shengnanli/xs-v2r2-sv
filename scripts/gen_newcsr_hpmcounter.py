#!/usr/bin/env python3
"""Generate the Hpmcounter CSR-field family wrappers for NewCSR.

The golden HpmcounterNModule family (N=3..31, 29 instances) is byte-identical
across all instances modulo (a) the module name and (b) the machine-mode source
input port name `mHPM_hpmcounters_{N-3}`. We reimplement the shared behavior once
in the readable parameterized primitive `xs_hpmcounter` (rtl/backend/
newcsr_hpmcounter.sv) and emit a thin per-index wrapper module here that binds the
golden per-instance port name to the primitive's generic `mhpm_src` port.

Outputs:
  rtl/backend/newcsr_hpmcounter_wrappers.sv  (29 thin wrapper modules)

These wrappers replace the empty black-box stubs currently in newcsr_stub.sv and
are FM-verified against golden per index in signoff-strict mode via the
Hpmcounter3Module AUX UT (verif/ut/Hpmcounter3Module).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_hpmcounter_wrappers.sv")

HEADER = """// 自动生成: scripts/gen_newcsr_hpmcounter.py —— 勿手改
// NewCSR Hpmcounter family thin wrappers (N=3..31, index = N-3).
// Each wrapper instantiates the readable primitive xs_hpmcounter (see
// rtl/backend/newcsr_hpmcounter.sv) and binds the golden per-instance
// machine-mode source port name mHPM_hpmcounters_{N-3} to mhpm_src.
// FM-verified against golden HpmcounterNModule.sv in signoff-strict mode.
"""

WRAP = """
module Hpmcounter{n}Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_{idx},
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX({idx})) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_{idx}),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule
"""


def main():
    parts = [HEADER]
    for n in range(3, 32):
        parts.append(WRAP.format(n=n, idx=n - 3))
    with open(OUT, "w") as f:
        f.write("".join(parts))
    print(f"wrote {OUT} ({32 - 3} wrappers)")


if __name__ == "__main__":
    main()
