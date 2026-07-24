#!/usr/bin/env python3
"""Generate the indirect-register CSR-field family wrappers for NewCSR.

Golden {S,M,VS}iregNModule family (18 modules): 3 base + 15 numbered (N=2..6).
Base modules pass an external indirect read straight through to rdata and expose
the raw staged register; numbered modules expose only the staged register. Both
are plain clock-only write-latches (no reset). Shared readable primitives live
in rtl/backend/newcsr_indireg.sv (xs_indireg / xs_indireg_wo); this script emits
one thin wrapper per golden module binding the golden per-instance port names.

Outputs: rtl/backend/newcsr_indireg_wrappers.sv (18 wrappers).
FM-verified against golden per module in signoff-strict mode via the SiregModule
AUX UT family.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_indireg_wrappers.sv")

HEADER = """// 自动生成: scripts/gen_newcsr_indireg.py —— 勿手改
// NewCSR indirect-register family thin wrappers ({S,M,VS}iregNModule, 18 modules).
// base (SiregModule/MiregModule/VSiregModule): xs_indireg (write-latch + external
//   rdata passthrough + regOut_ALL); numbered (N=2..6): xs_indireg_wo (latch +
//   regOut_ALL). golden 无 reset —— clock-only 写锁存, 逐位照搬。
// FM-verified against golden in signoff-strict mode.
"""

# base: prefix -> golden iregRead port name
BASE_IREAD = {
    "Sireg":  "iregRead_sireg",
    "Mireg":  "iregRead_mireg",
    "VSireg": "iregRead_sireg",  # golden VSiregModule reuses iregRead_sireg
}

BASE_WRAP = """
module {pfx}Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] {iread}
);
  xs_indireg u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .iread      ({iread}),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
"""

WO_WRAP = """
module {pfx}{n}Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
"""


def main():
    parts = [HEADER]
    for pfx in ("Sireg", "Mireg", "VSireg"):
        parts.append(BASE_WRAP.format(pfx=pfx, iread=BASE_IREAD[pfx]))
        for n in range(2, 7):
            parts.append(WO_WRAP.format(pfx=pfx, n=n))
    with open(OUT, "w") as f:
        f.write("".join(parts))
    print(f"wrote {OUT} (18 wrappers)")


if __name__ == "__main__":
    main()
