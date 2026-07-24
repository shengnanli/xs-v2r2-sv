#!/usr/bin/env python3
"""Generate the Pmpcfg CSR-field family wrappers for NewCSR.

RV64 exposes only the even-numbered pmpcfg CSRs; the golden set is
{Pmpcfg0Module, Pmpcfg2Module}. Each golden module is a PURE COMBINATIONAL read
slicer of a 128-bit upstream-legalized packed config bus `cfgRData`:
  Pmpcfg0Module -> cfgRData[63:0]     (HI=0)
  Pmpcfg2Module -> cfgRData[127:64]   (HI=1)
(The R/W/X/A/L WARL legalization lives upstream, not in these modules.)

We reimplement the shared behavior once in the readable parameterized primitive
`xs_pmpcfg` (rtl/backend/newcsr_pmpcfg.sv) and emit a thin per-instance wrapper
here that fixes HI (0 for Pmpcfg0, 1 for Pmpcfg2).

Outputs:
  rtl/backend/newcsr_pmpcfg_wrappers.sv  (2 thin wrapper modules)

These wrappers replace the empty black-box stubs currently in newcsr_stub.sv and
are FM-verified against golden per instance in signoff-strict mode via the
Pmpcfg0Module AUX UT (verif/ut/Pmpcfg0Module).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_pmpcfg_wrappers.sv")

HEADER = """// 自动生成: scripts/gen_newcsr_pmpcfg.py —— 勿手改
// NewCSR Pmpcfg family thin wrappers (Pmpcfg0Module HI=0, Pmpcfg2Module HI=1).
// Each wrapper instantiates the readable primitive xs_pmpcfg (see
// rtl/backend/newcsr_pmpcfg.sv) with the per-instance 64-bit half select HI.
// FM-verified against golden PmpcfgNModule.sv in signoff-strict mode.
"""

WRAP = """
module Pmpcfg{n}Module(
  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
  xs_pmpcfg #(.HI(1'b{hi})) u_core (
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL),
    .cfgRData   (cfgRData)
  );
endmodule
"""

# (module suffix number, HI select)  RV64 even pmpcfg CSRs only
INSTANCES = [(0, 0), (2, 1)]


def main():
    parts = [HEADER]
    for n, hi in INSTANCES:
        parts.append(WRAP.format(n=n, hi=hi))
    with open(OUT, "w") as f:
        f.write("".join(parts))
    print(f"wrote {OUT} ({len(INSTANCES)} wrappers)")


if __name__ == "__main__":
    main()
