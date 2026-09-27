#!/usr/bin/env python3
"""Generate ten readable CSR/privilege leaf modules."""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


def banner(summary: str) -> str:
    return (
        f"// {summary}\n"
        "// The small semantic core makes the architectural transform explicit;\n"
        "// the outer module preserves the generated RTL interface exactly.\n"
    )


OUTPUTS = {
    "Pmpcfg6Module": banner("Expose the decoded PMP configuration word through both CSR views.") + r'''module xs_Pmpcfg6Module_core(
  input  logic [63:0] cfg,
  output logic [63:0] read_value,
  output logic [63:0] mirror_value
);
  assign read_value = cfg;
  assign mirror_value = cfg;
endmodule

module Pmpcfg6Module(
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] cfgRData
);
  xs_Pmpcfg6Module_core u_core (
    .cfg(cfgRData), .read_value(rdata), .mirror_value(regOut_ALL)
  );
endmodule
''',
    "MtopeiModule": banner("Pack the machine top-external-interrupt identity and priority CSR fields.") + r'''module xs_MtopeiModule_core(
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module MtopeiModule(
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_mtopei_IID,
  input  logic [10:0] aiaToCSR_mtopei_IPRIO
);
  xs_MtopeiModule_core u_core (
    .interrupt_id(aiaToCSR_mtopei_IID),
    .interrupt_priority(aiaToCSR_mtopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_mtopei_IID;
  assign regOut_IPRIO = aiaToCSR_mtopei_IPRIO;
endmodule
''',
    "StopeiModule": banner("Pack the supervisor top-external-interrupt identity and priority CSR fields.") + r'''module xs_StopeiModule_core(
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module StopeiModule(
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_stopei_IID,
  input  logic [10:0] aiaToCSR_stopei_IPRIO
);
  xs_StopeiModule_core u_core (
    .interrupt_id(aiaToCSR_stopei_IID),
    .interrupt_priority(aiaToCSR_stopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_stopei_IID;
  assign regOut_IPRIO = aiaToCSR_stopei_IPRIO;
endmodule
''',
    "VStopeiModule": banner("Pack the virtual-supervisor top-external-interrupt identity and priority fields.") + r'''module xs_VStopeiModule_core(
  input  logic [10:0] interrupt_id,
  input  logic [10:0] interrupt_priority,
  output logic [63:0] read_value
);
  assign read_value = {37'b0, interrupt_id, 5'b0, interrupt_priority};
endmodule

module VStopeiModule(
  output logic [63:0] rdata,
  output logic [10:0] regOut_IID,
  output logic [10:0] regOut_IPRIO,
  input  logic [10:0] aiaToCSR_vstopei_IID,
  input  logic [10:0] aiaToCSR_vstopei_IPRIO
);
  xs_VStopeiModule_core u_core (
    .interrupt_id(aiaToCSR_vstopei_IID),
    .interrupt_priority(aiaToCSR_vstopei_IPRIO),
    .read_value(rdata)
  );
  assign regOut_IID = aiaToCSR_vstopei_IID;
  assign regOut_IPRIO = aiaToCSR_vstopei_IPRIO;
endmodule
''',
    "Tdata1Module": banner("Decode the architectural type, debug-mode, and payload fields of tdata1.") + r'''module Tdata1Module(
  output logic [63:0] rdata,
  output logic [3:0]  regOut_TYPE,
  output logic        regOut_DMODE,
  output logic [58:0] regOut_DATA,
  input  logic [63:0] tdataRead_tdata1
);
  assign rdata = tdataRead_tdata1;
  assign regOut_TYPE = tdataRead_tdata1[63:60];
  assign regOut_DMODE = tdataRead_tdata1[59];
  assign regOut_DATA = tdataRead_tdata1[58:0];
endmodule
''',
    "HcontextModule": banner("Read hcontext and forward a masked write to the shared mcontext storage.") + r'''module HcontextModule(
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [13:0] rdata,
  output logic [13:0] regOut_HCONTEXT,
  input  logic [13:0] fromMcontext_HCONTEXT,
  output logic        toMcontext_valid,
  output logic [13:0] toMcontext_bits_HCONTEXT
);
  assign rdata = fromMcontext_HCONTEXT;
  assign regOut_HCONTEXT = fromMcontext_HCONTEXT;
  assign toMcontext_valid = w_wen;
  assign toMcontext_bits_HCONTEXT = w_wdata[13:0];
endmodule
''',
    "SLevelPermitModule": banner("Reject disallowed user accesses to supervisor counters and state-enable CSRs.") + r'''module SLevelPermitModule(
  input  logic [11:0] io_in_csrAccess_addr,
  input  logic [1:0]  io_in_privState_PRVM,
  input  logic        io_in_privState_V,
  input  logic [31:0] io_in_xcounteren_scounteren,
  input  logic        io_in_xstateen_sstateen0_C,
  output logic        io_out_sLevelPermit_EX_II
);
  logic user_mode;
  logic host_user_mode;
  logic selected_counter_enabled;
  logic accesses_user_counter;
  logic accesses_supervisor_state;

  assign user_mode = io_in_privState_PRVM == 2'b00;
  assign host_user_mode = user_mode && !io_in_privState_V;
  assign selected_counter_enabled =
    io_in_xcounteren_scounteren[io_in_csrAccess_addr[4:0]];
  assign accesses_user_counter =
    (io_in_csrAccess_addr > 12'hBFF) && (io_in_csrAccess_addr < 12'hC20);
  assign accesses_supervisor_state =
    (io_in_csrAccess_addr[11:8] == 4'h8) ||
    (io_in_csrAccess_addr[11:6] == 6'h33);

  assign io_out_sLevelPermit_EX_II =
    (accesses_user_counter && host_user_mode && !selected_counter_enabled) ||
    (accesses_supervisor_state && host_user_mode && !io_in_xstateen_sstateen0_C);
endmodule
''',
    "ScountovfModule": banner("Expose counter-overflow bits allowed by the current privilege and virtualization mode.") + r'''module ScountovfModule(
  output logic [31:0] rdata,
  input  logic [28:0] ofVec,
  input  logic [1:0]  privState_PRVM,
  input  logic        privState_V,
  input  logic [28:0] mcounteren_HPM,
  input  logic [28:0] hcounteren_HPM
);
  logic machine_mode;
  logic host_supervisor_mode;
  logic virtual_supervisor_mode;
  logic [28:0] visible_overflows;

  assign machine_mode = &privState_PRVM;
  assign host_supervisor_mode =
    (privState_PRVM == 2'b01) && !privState_V;
  assign virtual_supervisor_mode =
    (privState_PRVM == 2'b01) && privState_V;

  always_comb begin
    visible_overflows = 29'b0;
    if (machine_mode)
      visible_overflows = ofVec;
    else if (host_supervisor_mode)
      visible_overflows = mcounteren_HPM & ofVec;
    else if (virtual_supervisor_mode)
      visible_overflows = mcounteren_HPM & hcounteren_HPM & ofVec;
  end

  assign rdata = {visible_overflows, 3'b0};
endmodule
''',
    "Pmaaddr0Module": banner("Expose PMA address slot zero through the CSR and mirror views.") + r'''module Pmaaddr0Module(
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_0
);
  assign rdata = addrRData_0;
  assign regOut_ALL = addrRData_0;
endmodule
''',
    "Pmpaddr32Module": banner("PMP address slot 32 is outside the implemented range and reads as zero.") + r'''module Pmpaddr32Module(
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
''',
}


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
        print("gen_csr_leaves10c --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_csr_leaves10c --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
