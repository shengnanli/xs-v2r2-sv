#!/usr/bin/env python3
"""Generate the eight PMA configuration CSR wrappers from G1 port headers.

The register behavior lives once in xs_Pmacfg_core.  Each generated wrapper keeps
its golden module name and exact port declaration, selecting the PMA slot through
the core parameter.  The wrapper region is deliberately marked so future edits
are deterministic and --check can catch drift.
"""

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "rtl/backend"
GOLDEN_DIR = Path("/home/eda/xs-env/G1-canonical/golden-rtl")
SLOTS = tuple(range(8))

CORE_TEXT = r'''// xs_Pmacfg_core — readable, parameterized PMA configuration CSR state.
//
// Each PMA slot has the same seven architectural fields.  Reset is asynchronous
// and dominant.  A write updates R/W/X/ATOMIC/C/L and updates A only when the
// golden WARL predicate accepts the two-bit encoding.  The golden design does
// not make L sticky: L is an ordinary writable field, so that behavior is kept.
module xs_Pmacfg_core #(
  parameter int PMA_INDEX = 0
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       w_wen,
  input  logic [63:0] w_wdata,
  output logic [7:0] rdata,
  output logic       regOut_R,
  output logic       regOut_W,
  output logic       regOut_X,
  output logic [1:0] regOut_A,
  output logic       regOut_ATOMIC,
  output logic       regOut_C,
  output logic       regOut_L
);
  logic       reg_R;
  logic       reg_W;
  logic       reg_X;
  logic [1:0] reg_A;
  logic       reg_ATOMIC;
  logic       reg_C;
  logic       reg_L;

  // The four two-bit encodings are exactly the four cases accepted by golden.
  logic a_warl_legal;
  assign a_warl_legal = (w_wdata[4:3] == 2'h0) |
                        (w_wdata[4:3] == 2'h1) |
                        (w_wdata[4:3] == 2'h2) |
                        (&w_wdata[4:3]);

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_R      <= 1'b0;
      reg_W      <= 1'b0;
      reg_X      <= 1'b0;
      reg_A      <= 2'b0;
      reg_ATOMIC <= 1'b0;
      reg_C      <= 1'b0;
      reg_L      <= 1'b0;
    end else begin
      if (w_wen) begin
        reg_R      <= w_wdata[0];
        reg_W      <= w_wdata[1];
        reg_X      <= w_wdata[2];
        reg_ATOMIC <= w_wdata[5];
        reg_C      <= w_wdata[6];
        reg_L      <= w_wdata[7];
      end
      if (w_wen && a_warl_legal)
        reg_A <= w_wdata[4:3];
    end
  end

  assign rdata       = {reg_L, reg_C, reg_ATOMIC, reg_A, reg_X, reg_W, reg_R};
  assign regOut_R    = reg_R;
  assign regOut_W    = reg_W;
  assign regOut_X    = reg_X;
  assign regOut_A    = reg_A;
  assign regOut_ATOMIC = reg_ATOMIC;
  assign regOut_C    = reg_C;
  assign regOut_L    = reg_L;
endmodule
'''


def golden_port_header(slot: int) -> str:
    name = f"Pma{slot}cfgModule"
    source = (GOLDEN_DIR / f"{name}.sv").read_text()
    match = re.search(rf"module\s+{re.escape(name)}\s*\(.*?\n\);", source, re.S)
    if match is None:
        raise RuntimeError(f"cannot find port header for {name}")
    return match.group(0)


def wrapper_text(slot: int) -> str:
    name = f"Pma{slot}cfgModule"
    header = golden_port_header(slot)
    return f'''// {name} — PMA configuration CSR leaf {slot}.
// The shared core preserves golden reset, WARL, write priority, and field layout.
// This file is generated; edit scripts/gen_pmacfg_leaves8.py instead.
// BEGIN GENERATED(wrapper) — scripts/gen_pmacfg_leaves8.py
{header}
  xs_Pmacfg_core #(.PMA_INDEX({slot})) u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_R(regOut_R),
    .regOut_W(regOut_W),
    .regOut_X(regOut_X),
    .regOut_A(regOut_A),
    .regOut_ATOMIC(regOut_ATOMIC),
    .regOut_C(regOut_C),
    .regOut_L(regOut_L)
  );
endmodule
// END GENERATED(wrapper)
'''


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    expected = {RTL_DIR / "xs_Pmacfg_core.sv": CORE_TEXT}
    expected.update(
        {RTL_DIR / f"Pma{slot}cfgModule.sv": wrapper_text(slot) for slot in SLOTS}
    )

    drift = []
    for path, text in expected.items():
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        else:
            path.write_text(text)

    if drift:
        print("gen_pmacfg_leaves8 --check: DRIFT: " + " ".join(drift))
        return 1
    if args.check:
        print(f"gen_pmacfg_leaves8 --check: OK ({len(SLOTS)} wrappers + core)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
