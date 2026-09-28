#!/usr/bin/env python3
"""Generate fifteen readable CSR/control leaf wrappers."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
OUTPUTS = {}


def emit(name: str, text: str) -> None:
    OUTPUTS[name] = text


def header(description: str) -> str:
    return (
        f"// {description}\n"
        "// The semantic core names the operation; the exact-name wrapper preserves integration.\n"
        "// This leaf is combinational and contains no hidden architectural state.\n"
    )


emit(
    "MconfigptrModule",
    header("Machine configuration pointer is architecturally hard-wired to zero.")
    + r'''module xs_MconfigptrModule_core (
  output logic [63:0] value
);
  assign value = 64'b0;
endmodule

module MconfigptrModule (
  output logic [63:0] rdata
);
  xs_MconfigptrModule_core u_core (
    .value(rdata)
  );
endmodule
''',
)

emit(
    "MhartidModule",
    header("Machine hart ID zero-extends the six-bit platform identifier.")
    + r'''module xs_MhartidModule_core (
  input  logic [5:0]  hart_id,
  output logic [63:0] value
);
  assign value = {58'b0, hart_id};
endmodule

module MhartidModule (
  output logic [63:0] rdata,
  input  logic [5:0]  hartid
);
  xs_MhartidModule_core u_core (
    .hart_id(hartid),
    .value(rdata)
  );
endmodule
''',
)

emit(
    "HgeipModule",
    header("Guest external interrupt pending bits feed both CSR encoding and raw view.")
    + r'''module xs_HgeipModule_core (
  input  logic [6:0]  pending,
  output logic [63:0] value,
  output logic [6:0]  raw_pending
);
  assign value = {56'b0, pending, 1'b0};
  assign raw_pending = pending;
endmodule

module HgeipModule (
  output logic [63:0] rdata,
  output logic [6:0]  regOut_ip,
  input  logic [6:0]  aiaToCSR_vseip
);
  xs_HgeipModule_core u_core (
    .pending(aiaToCSR_vseip),
    .value(rdata),
    .raw_pending(regOut_ip)
  );
endmodule
''',
)

for name, source_port in [
    ("MiregModule", "iregRead_mireg"),
    ("SiregModule", "iregRead_sireg"),
    ("VSiregModule", "iregRead_sireg"),
    ("Tdata2Module", "tdataRead_tdata2"),
]:
    emit(
        name,
        header(f"{name} mirrors its selected 64-bit indirect read source to both views.")
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
  input  logic [63:0] {source_port}
);
  xs_{name}_core u_core (
    .source({source_port}),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
''',
    )

for name, prefix in [
    ("MtopiModule", "mtopi"),
    ("StopiModule", "stopi"),
    ("VStopiModule", "vstopi"),
]:
    emit(
        name,
        header(f"{name} packs interrupt identity and priority into the TOPI CSR layout.")
        + f'''module xs_{name}_core (
  input  logic [11:0] iid,
  input  logic [7:0]  irq_priority,
  output logic [63:0] value,
  output logic [11:0] iid_view
);
  assign value = {{36'b0, iid, 8'b0, irq_priority}};
  assign iid_view = iid;
endmodule

module {name} (
  output logic [63:0] rdata,
  output logic [11:0] regOut_IID,
  input  logic [11:0] topIR_{prefix}_IID,
  input  logic [7:0]  topIR_{prefix}_IPRIO
);
  xs_{name}_core u_core (
    .iid(topIR_{prefix}_IID),
    .irq_priority(topIR_{prefix}_IPRIO),
    .value(rdata),
    .iid_view(regOut_IID)
  );
endmodule
''',
    )

for name in ["Pmacfg0Module", "Pmacfg2Module", "Pmacfg4Module", "Pmacfg6Module"]:
    emit(
        name,
        header(f"{name} exposes the decoded PMA configuration word without transformation.")
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

emit(
    "IntSyncSyncCrossingSink",
    header("Synchronous interrupt crossing sink is a one-bit transparent endpoint.")
    + r'''module xs_IntSyncSyncCrossingSink_core (
  input  logic incoming,
  output logic outgoing
);
  assign outgoing = incoming;
endmodule

module IntSyncSyncCrossingSink (
  input  logic auto_in_sync_0,
  output logic auto_out_0
);
  xs_IntSyncSyncCrossingSink_core u_core (
    .incoming(auto_in_sync_0),
    .outgoing(auto_out_0)
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
        print("gen_csr_leaves15 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_csr_leaves15 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
