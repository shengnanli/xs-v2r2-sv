#!/usr/bin/env python3
"""Generate the Mhpmcounter CSR-field family wrappers for NewCSR.

The golden MhpmcounterNModule family (N=3..31, 29 instances) is byte-identical
across all instances modulo (a) the module name and (b) the single bit index
`mcountinhibit_HPM3[N-3]` selected inside `countingInhibit`. We reimplement the
shared behavior once in the readable parameterized primitive `xs_mhpmcounter`
(rtl/backend/newcsr_mhpmcounter.sv) and emit a thin per-index wrapper module
here that fixes IDX = N-3 (the primitive itself indexes HPM3[IDX]).

Outputs:
  rtl/backend/newcsr_mhpmcounter_wrappers.sv  (29 thin wrapper modules)

These wrappers replace the empty black-box stubs currently in newcsr_stub.sv and
are FM-verified against golden per index in signoff-strict mode via the
Mhpmcounter3Module AUX UT (verif/ut/Mhpmcounter3Module).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_mhpmcounter_wrappers.sv")

HEADER = """// 自动生成: scripts/gen_newcsr_mhpmcounter.py —— 勿手改
// NewCSR Mhpmcounter family thin wrappers (N=3..31, index = N-3).
// Each wrapper instantiates the readable primitive xs_mhpmcounter (see
// rtl/backend/newcsr_mhpmcounter.sv) with IDX=N-3; the primitive selects
// mcountinhibit_HPM3[IDX] for its counting-inhibit term, matching golden.
// FM-verified against golden MhpmcounterNModule.sv in signoff-strict mode.
"""

WRAP = """
module Mhpmcounter{n}Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
  xs_mhpmcounter #(.IDX({idx})) u_core (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (w_wen),
    .w_wdata            (w_wdata),
    .rdata              (rdata),
    .regOut_ALL         (regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_CY),
    .mcountinhibit_IR   (mcountinhibit_IR),
    .mcountinhibit_HPM3 (mcountinhibit_HPM3),
    .countingEn         (countingEn),
    .perf_value         (perf_value),
    .toMhpmeventOF      (toMhpmeventOF)
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
