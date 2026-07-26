#!/usr/bin/env python3
"""Generate the Pmpaddr CSR-field family wrappers for NewCSR.

The golden PmpaddrNModule family (N=0..15, 16 instances) is byte-identical
across all instances modulo (a) the module name and (b) the read-mux source
input port name `addrRData_{N}`. We reimplement the shared behavior once in the
readable parameterized primitive `xs_pmpaddr` (rtl/backend/newcsr_pmpaddr.sv)
and emit a thin per-index wrapper module here that binds the golden per-instance
port name `addrRData_{N}` to the primitive's generic `addr_rdata` port.

Outputs:
  rtl/backend/newcsr_pmpaddr_wrappers.sv  (16 thin wrapper modules)

These wrappers replace the empty black-box stubs currently in newcsr_stub.sv and
are FM-verified against golden per index in signoff-strict mode via the
Pmpaddr0Module AUX UT (verif/ut/Pmpaddr0Module).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "rtl", "backend", "newcsr_pmpaddr_wrappers.sv")

HEADER = """// 自动生成: scripts/gen_newcsr_pmpaddr.py —— 勿手改
// NewCSR Pmpaddr family thin wrappers (N=0..15).
// Each wrapper instantiates the readable primitive xs_pmpaddr (see
// rtl/backend/newcsr_pmpaddr.sv) and binds the golden per-instance read-mux
// source port name addrRData_{N} to the primitive's generic addr_rdata port.
// FM-verified against golden PmpaddrNModule.sv in signoff-strict mode.
"""

WRAP = """
module Pmpaddr{n}Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_{n}
);
  xs_pmpaddr #(.IDX({n})) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_{n})
  );
endmodule
"""


def main():
    parts = [HEADER]
    for n in range(0, 16):
        parts.append(WRAP.format(n=n))
    with open(OUT, "w") as f:
        f.write("".join(parts))
    print(f"wrote {OUT} ({16} wrappers)")


if __name__ == "__main__":
    main()
