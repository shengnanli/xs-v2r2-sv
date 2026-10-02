#!/usr/bin/env python3
"""Generate the eight readable PMP configuration CSR wrappers.

The shared behavioral core lives in rtl/backend/xs_Pmpcfg_core.sv. This
script owns only the repetitive exact-name wrappers and keeps their generated
region explicit so drift is detected rather than silently repaired.
"""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl/backend"
SLOTS = tuple(range(5, 13))
BEGIN = "// BEGIN GENERATED(pmpcfg-leaves8)"
END = "// END GENERATED(pmpcfg-leaves8)"


def generated_region(slot: int) -> str:
    name = f"Pmp{slot}cfgModule"
    return f"""{BEGIN}
// {name} is PMP configuration CSR entry {slot} in NewCSR.
// The shared core implements WARL permissions, lock behavior, and reset.
// This wrapper preserves the exact golden port contract for integration.
module {name} (
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [7:0] rdata,
  output logic regOut_R,
  output logic regOut_W,
  output logic regOut_X,
  output logic [1:0] regOut_A,
  output logic regOut_L
);
  xs_Pmpcfg_core #(.SLOT({slot})) u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_R(regOut_R),
    .regOut_W(regOut_W),
    .regOut_X(regOut_X),
    .regOut_A(regOut_A),
    .regOut_L(regOut_L)
  );
endmodule
{END}
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    drift = []
    for slot in SLOTS:
        path = RTL / f"Pmp{slot}cfgModule.sv"
        text = generated_region(slot)
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path.relative_to(ROOT)))
        else:
            path.write_text(text)
    if drift:
        print("gen_pmpcfg_leaves8 --check: DRIFT " + " ".join(drift))
        return 1
    if args.check:
        print(f"gen_pmpcfg_leaves8 --check: OK ({len(SLOTS)} files)")
    else:
        print(f"gen_pmpcfg_leaves8: wrote {len(SLOTS)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
