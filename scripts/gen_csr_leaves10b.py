#!/usr/bin/env python3
"""Generate ten readable constant/pass-through CSR leaves."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
OUTPUTS = {}


def emit(name: str, text: str) -> None:
    OUTPUTS[name] = text


def header(description: str) -> str:
    return (
        f"// {description}\n"
        "// The semantic core states the CSR behavior; the exact wrapper preserves ports.\n"
        "// This combinational leaf contains no hidden architectural state.\n"
    )


for name in ["Sstateen1Module", "Sstateen2Module", "Sstateen3Module"]:
    emit(
        name,
        header(f"{name} is an unimplemented 32-bit state-enable bank and reads as zero.")
        + f'''module xs_{name}_core (
  output logic [31:0] value,
  output logic [31:0] mirror
);
  assign value = 32'b0;
  assign mirror = 32'b0;
endmodule

module {name} (
  output logic [31:0] rdata,
  output logic [31:0] regOut_ALL
);
  xs_{name}_core u_core (
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
''',
    )

for name in ["Pmpcfg8Module", "Pmpcfg10Module", "Pmpcfg12Module", "Pmpcfg14Module"]:
    emit(
        name,
        header(f"{name} is outside the implemented PMP configuration range and reads as zero.")
        + f'''module xs_{name}_core (
  output logic [63:0] value,
  output logic [63:0] mirror
);
  assign value = 64'b0;
  assign mirror = 64'b0;
endmodule

module {name} (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  xs_{name}_core u_core (
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
''',
    )

for name in ["Pmpcfg0Module", "Pmpcfg2Module", "Pmpcfg4Module"]:
    emit(
        name,
        header(f"{name} exposes the decoded PMP configuration word through both CSR views.")
        + f'''module xs_{name}_core (
  input  logic [63:0] source,
  output logic [63:0] value,
  output logic [63:0] mirror
);
  assign value = source;
  assign mirror = source;
endmodule

module {name} (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] cfgRData
);
  xs_{name}_core u_core (
    .source(cfgRData),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
''',
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = []
    for name, text in OUTPUTS.items():
        path = RTL_DIR / f"{name}.sv"
        if args.check:
            if not path.exists() or path.read_text() != text:
                drift.append(str(path))
        else:
            path.write_text(text)
    if drift:
        print("gen_csr_leaves10b --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_csr_leaves10b --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
