#!/usr/bin/env python3
"""Generate the fourteen readable CSR leaf rewrites of family C (k3-next20).

Modules covered (all 0-child golden leaves, parents NewCSR / CSRPermitModule):
  cycleModule, instretModule      - unprivileged cycle/instret counter views
  HipModule, HieModule, HgeieModule - hypervisor interrupt CSRs
  MscratchModule, SscratchModule, VSscratchModule, MnscratchModule,
  Dscratch0Module, Dscratch1Module  - 64-bit scratch CSRs (no reset, per golden)
  ScontextModule                  - 32-bit scontext CSR (async reset to 0)
  TselectModule                   - 2-bit tselect CSR (async reset, write-ignore >= 4)
  PrivilegePermitModule           - combinational CSR privilege legality decode

Each emitted file is self-contained per the single-file spec:
  xs_<Module>_core (readable core) + <Module> wrapper with golden-exact ports.
Deterministic: no timestamps; --check exits nonzero on drift.
"""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"
OUTPUTS = {}


def emit(name: str, text: str) -> None:
    OUTPUTS[name] = text


def counter_leaf(name: str, field: str) -> str:
    """cycleModule / instretModule: unprivileged read view of an HPM counter.

    Golden semantics (bug-for-bug):
      - reg_<field> has NO reset; it is only loaded when unprivCountUpdate.
      - rdata is the frozen register while debugModeStopCount is set,
        otherwise the live mHPM counter value passes through combinationally.
    """
    return f"""// {name}.sv — unprivileged ({field}) counter read view inside NewCSR.
// NewCSR keeps the architectural {field} count in mHPM_{field}; this leaf only
// holds the snapshot used while debug mode has stopped counting.
// Reset: the snapshot register has NO reset in golden (holds power-on value
// until the first unprivCountUpdate). Reproduced bug-for-bug.
// Read mux: debugModeStopCount=1 reads the frozen snapshot, 0 reads the live count.
module xs_{name}_core (
  input  logic        clock,
  input  logic [63:0] live_count,      // mHPM_{field}: live HPM counter value
  input  logic        debug_stop,      // debugModeStopCount: counting stopped in debug
  input  logic        count_update,    // unprivCountUpdate: snapshot load enable
  output logic [63:0] value
);
  // Snapshot of the counter, loaded only when the unprivileged view is updated.
  logic [63:0] snapshot_q;

  always @(posedge clock) begin
    if (count_update)
      snapshot_q <= live_count;
  end

  assign value = debug_stop ? snapshot_q : live_count;
endmodule

module {name} (
  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_{field},
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_{name}_core u_core (
    .clock(clock),
    .live_count(mHPM_{field}),
    .debug_stop(debugModeStopCount),
    .count_update(unprivCountUpdate),
    .value(rdata)
  );
endmodule
"""


emit("cycleModule", counter_leaf("cycleModule", "cycle"))
emit("instretModule", counter_leaf("instretModule", "instret"))


emit(
    "HipModule",
    """// HipModule.sv — hypervisor interrupt-pending CSR (hip) slice inside NewCSR.
// hip is a read view: every pending bit lives elsewhere (mip / hvip) and this
// leaf only assembles the 64-bit CSR encoding. The one writable-looking bit,
// VSSIP (bit 2), is not stored here: a write sideband (toHvip_VSSIP_*) forwards
// the write to the hvip register, and reads always reflect hvip_VSSIP.
// Hardwired-zero bits: [63:13], [11], [9:7], [5:3], [1:0]. No state, no reset.
module xs_HipModule_core (
  input  logic        wen,            // w_wen: CSR write strobe (to hvip sideband)
  input  logic [63:0] wdata,          // w_wdata: only bit 2 (VSSIP) is forwarded
  input  logic        mip_vstip,      // VSTIP pending lives in mip
  input  logic        mip_vseip,      // VSEIP pending lives in mip
  input  logic        mip_sgeip,      // SGEIP pending lives in mip
  input  logic        hvip_vssip,     // VSSIP pending lives in hvip
  output logic [63:0] value,          // assembled hip read data
  output logic        out_vssip,
  output logic        out_vstip,
  output logic        out_vseip,
  output logic        out_sgeip,
  output logic        hvip_wen,       // sideband write strobe to hvip.VSSIP
  output logic        hvip_wbit       // sideband write data bit
);
  // hip layout: SGEIP=12, VSEIP=10, VSTIP=6, VSSIP=2; all other bits hard 0.
  assign value = {51'h0, mip_sgeip, 1'h0, mip_vseip, 3'h0,
                  mip_vstip, 3'h0, hvip_vssip, 2'h0};
  assign out_vssip = hvip_vssip;
  assign out_vstip = mip_vstip;
  assign out_vseip = mip_vseip;
  assign out_sgeip = mip_sgeip;
  // Write sideband: note golden does NOT gate the bits with wen
  // (toHvip_VSSIP_bits = w_wdata[2] unconditionally); kept bug-for-bug.
  assign hvip_wen  = wen;
  assign hvip_wbit = wdata[2];
endmodule

module HipModule (
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIP,
  output        regOut_VSTIP,
  output        regOut_VSEIP,
  output        regOut_SGEIP,
  input         mip_VSTIP,
  input         mip_VSEIP,
  input         mip_SGEIP,
  input         hvip_VSSIP,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits
);
  xs_HipModule_core u_core (
    .wen(w_wen),
    .wdata(w_wdata),
    .mip_vstip(mip_VSTIP),
    .mip_vseip(mip_VSEIP),
    .mip_sgeip(mip_SGEIP),
    .hvip_vssip(hvip_VSSIP),
    .value(rdata),
    .out_vssip(regOut_VSSIP),
    .out_vstip(regOut_VSTIP),
    .out_vseip(regOut_VSEIP),
    .out_sgeip(regOut_SGEIP),
    .hvip_wen(toHvip_VSSIP_valid),
    .hvip_wbit(toHvip_VSSIP_bits)
  );
endmodule
""",
)


emit(
    "HieModule",
    """// HieModule.sv — hypervisor interrupt-enable CSR (hie) slice inside NewCSR.
// hie is a read view of the VS-mapped enable bits that physically live in mie;
// this leaf stores nothing. CSR writes are forwarded bit-by-bit to mie via the
// toMie_* sidebands (valid = write strobe, bits = the written data bit).
// Hardwired-zero bits: [63:13], [11], [9:7], [5:3], [1:0]. No state, no reset.
module xs_HieModule_core (
  input  logic        wen,           // w_wen: CSR write strobe
  input  logic [63:0] wdata,         // w_wdata: bits 2/6/10/12 forwarded to mie
  input  logic        mie_vssie,
  input  logic        mie_vstie,
  input  logic        mie_vseie,
  input  logic        mie_sgeie,
  output logic [63:0] value,         // assembled hie read data
  output logic        out_vssie,
  output logic        out_vstie,
  output logic        out_vseie,
  output logic        out_sgeie,
  output logic        mie_wen_vssie,
  output logic        mie_wbit_vssie,
  output logic        mie_wen_vstie,
  output logic        mie_wbit_vstie,
  output logic        mie_wen_vseie,
  output logic        mie_wbit_vseie,
  output logic        mie_wen_sgeie,
  output logic        mie_wbit_sgeie
);
  // hie layout: SGEIE=12, VSEIE=10, VSTIE=6, VSSIE=2; all other bits hard 0.
  assign value = {51'h0, mie_sgeie, 1'h0, mie_vseie, 3'h0,
                  mie_vstie, 3'h0, mie_vssie, 2'h0};
  assign out_vssie = mie_vssie;
  assign out_vstie = mie_vstie;
  assign out_vseie = mie_vseie;
  assign out_sgeie = mie_sgeie;
  // Write sidebands. Golden asymmetry kept bug-for-bug: *_valid is the bare
  // write strobe, while *_bits is the data bit ANDed with the strobe.
  assign mie_wen_vssie  = wen;
  assign mie_wbit_vssie = wen & wdata[2];
  assign mie_wen_vstie  = wen;
  assign mie_wbit_vstie = wen & wdata[6];
  assign mie_wen_vseie  = wen;
  assign mie_wbit_vseie = wen & wdata[10];
  assign mie_wen_sgeie  = wen;
  assign mie_wbit_sgeie = wen & wdata[12];
endmodule

module HieModule (
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIE,
  output        regOut_VSTIE,
  output        regOut_VSEIE,
  output        regOut_SGEIE,
  input         mie_VSSIE,
  input         mie_VSTIE,
  input         mie_VSEIE,
  input         mie_SGEIE,
  output        toMie_VSSIE_valid,
  output        toMie_VSSIE_bits,
  output        toMie_VSTIE_valid,
  output        toMie_VSTIE_bits,
  output        toMie_VSEIE_valid,
  output        toMie_VSEIE_bits,
  output        toMie_SGEIE_valid,
  output        toMie_SGEIE_bits
);
  xs_HieModule_core u_core (
    .wen(w_wen),
    .wdata(w_wdata),
    .mie_vssie(mie_VSSIE),
    .mie_vstie(mie_VSTIE),
    .mie_vseie(mie_VSEIE),
    .mie_sgeie(mie_SGEIE),
    .value(rdata),
    .out_vssie(regOut_VSSIE),
    .out_vstie(regOut_VSTIE),
    .out_vseie(regOut_VSEIE),
    .out_sgeie(regOut_SGEIE),
    .mie_wen_vssie(toMie_VSSIE_valid),
    .mie_wbit_vssie(toMie_VSSIE_bits),
    .mie_wen_vstie(toMie_VSTIE_valid),
    .mie_wbit_vstie(toMie_VSTIE_bits),
    .mie_wen_vseie(toMie_VSEIE_valid),
    .mie_wbit_vseie(toMie_VSEIE_bits),
    .mie_wen_sgeie(toMie_SGEIE_valid),
    .mie_wbit_sgeie(toMie_SGEIE_bits)
  );
endmodule
""",
)


emit(
    "HgeieModule",
    """// HgeieModule.sv — hypervisor guest external interrupt-enable CSR (hgeie).
// Holds enables for guest external interrupts 1..7 in a 7-bit register:
// CSR bit i (i=1..7) maps to reg_ie[i-1]; CSR bit 0 and bits [63:8] are
// hardwired zero. Writes are plain wen/wdata (bit slice [7:1]), no byte masks.
// Reset: asynchronous, active-high, resets the enables to all-zero (golden:
// always @(posedge clock or posedge reset), reset value 7'h0).
module xs_HgeieModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,            // w_wen: CSR write strobe
  input  logic [63:0] wdata,          // w_wdata: only bits [7:1] are stored
  output logic [63:0] value,          // assembled hgeie read data
  output logic [6:0]  enables         // raw enable vector to the interrupt logic
);
  logic [6:0] ie_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      ie_q <= 7'h0;
    else if (wen)
      ie_q <= wdata[7:1];
  end

  assign value   = {56'h0, ie_q, 1'h0};
  assign enables = ie_q;
endmodule

module HgeieModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [6:0]  regOut_ie
);
  xs_HgeieModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .enables(regOut_ie)
  );
endmodule
""",
)


def scratch_leaf(name: str, blurb: str) -> str:
    """The six 64-bit scratch CSRs: plain wen/wdata register, NO reset."""
    return f"""// {name}.sv — {blurb}
// A plain 64-bit read/write CSR storage register: a write strobe latches the
// full write data; both the CSR read data and the regOut_ALL view read the
// register directly. All 64 bits are writable, none hardwired.
// Reset: golden gives this register NO reset (holds its power-on value until
// the first write). Reproduced bug-for-bug — do not "fix" by adding one.
module xs_{name}_core (
  input  logic        clock,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [63:0] value,
  output logic [63:0] mirror
);
  logic [63:0] scratch_q;

  always @(posedge clock) begin
    if (wen)
      scratch_q <= wdata;
  end

  assign value  = scratch_q;
  assign mirror = scratch_q;
endmodule

module {name} (
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_{name}_core u_core (
    .clock(clock),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
"""


emit("MscratchModule", scratch_leaf("MscratchModule", "machine scratch CSR (mscratch)."))
emit("SscratchModule", scratch_leaf("SscratchModule", "supervisor scratch CSR (sscratch)."))
emit("VSscratchModule", scratch_leaf("VSscratchModule", "virtual-supervisor scratch CSR (vsscratch)."))
emit("MnscratchModule", scratch_leaf("MnscratchModule", "RnMI scratch CSR (mnscratch)."))
emit("Dscratch0Module", scratch_leaf("Dscratch0Module", "debug scratch 0 CSR (dscratch0)."))
emit("Dscratch1Module", scratch_leaf("Dscratch1Module", "debug scratch 1 CSR (dscratch1)."))


emit(
    "ScontextModule",
    """// ScontextModule.sv — supervisor context CSR (scontext).
// A 32-bit read/write register: writes store the low half of the 64-bit write
// data (w_wdata[31:0]); the CSR read data and regOut_ALL are both the raw
// 32-bit register (this CSR is narrower than the 64-bit bus by design).
// Reset: asynchronous, active-high, resets to 32'h0 (golden: always
// @(posedge clock or posedge reset)).
module xs_ScontextModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [31:0] value,
  output logic [31:0] mirror
);
  logic [31:0] context_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      context_q <= 32'h0;
    else if (wen)
      context_q <= wdata[31:0];
  end

  assign value  = context_q;
  assign mirror = context_q;
endmodule

module ScontextModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output [31:0] regOut_ALL
);
  xs_ScontextModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
""",
)


emit(
    "TselectModule",
    """// TselectModule.sv — trigger select CSR (tselect).
// A 2-bit read/write register selecting one of the (few) implemented triggers.
// Write-ignore semantics, bug-for-bug from golden: a write takes effect only
// when w_wdata < 64'h4; writes of any larger value are silently dropped and
// the register keeps its old value. Only w_wdata[1:0] is stored.
// Reset: asynchronous, active-high, resets to 2'h0.
module xs_TselectModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [1:0]  value,
  output logic [1:0]  mirror
);
  logic [1:0] select_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      select_q <= 2'h0;
    else if (wen & (wdata < 64'h4))
      select_q <= wdata[1:0];
  end

  assign value  = select_q;
  assign mirror = select_q;
endmodule

module TselectModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [1:0]  rdata,
  output [1:0]  regOut_ALL
);
  xs_TselectModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
""",
)


emit(
    "PrivilegePermitModule",
    """// PrivilegePermitModule.sv — CSR privilege legality decode inside CSRPermitModule.
// Purely combinational: given the CSR address, the current privilege mode
// (PRVM) and virtualization state (V), decide whether the access is legal and,
// if not, which exception to raise (EX_II = illegal instruction,
// EX_VI = virtual instruction).
// Legality (from golden, kept term-for-term):
//   - debug CSRs (addr[11:4] == 8'h7B) are illegal outside debug mode;
//   - otherwise the access is legal iff the CSR's encoded privilege level
//     (addr[9:8]) does not exceed the effective privilege (PRVM, with V
//     demoting M to HS), or debug mode is active.
// EX_II vs EX_VI split: illegal accesses in V-mode to a non-Hypervisor CSR
// raise EX_VI; all other illegal accesses raise EX_II.
module xs_PrivilegePermitModule_core (
  input  logic [11:0] csr_addr,
  input  logic [1:0]  prvm,
  input  logic        virt,
  input  logic        debug_mode,
  output logic        ex_ii,
  output logic        ex_vi
);
  // Inverted decode inputs, matching the golden sum-of-products form.
  logic [4:0] inv;
  assign inv = ~{virt, prvm, csr_addr[9:8]};

  // Four legal-access product terms (effective privilege reaches the CSR level):
  //   U-mode CSR (addr[9:8]=00) reachable below M; S CSR from S; HS CSR from
  //   HS (V=1) or non-V S; M CSR only from real M (V=0).
  logic legal_regular;
  assign legal_regular =
      |{&{inv[0], inv[1], inv[3]},
        &{inv[1], prvm[0], inv[3]},
        &{inv[0], prvm[0], inv[4]},
        &{prvm[0], prvm[1], inv[4]}};

  logic legal;
  assign legal = (csr_addr[11:4] != 8'h7B) & legal_regular | debug_mode;

  assign ex_ii = ~legal & (~virt | (&csr_addr[9:8]));
  assign ex_vi = ~legal & virt & ~(&csr_addr[9:8]);
endmodule

module PrivilegePermitModule (
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_debugMode,
  output        io_out_privilege_EX_II,
  output        io_out_privilege_EX_VI
);
  xs_PrivilegePermitModule_core u_core (
    .csr_addr(io_in_csrAccess_addr),
    .prvm(io_in_privState_PRVM),
    .virt(io_in_privState_V),
    .debug_mode(io_in_debugMode),
    .ex_ii(io_out_privilege_EX_II),
    .ex_vi(io_out_privilege_EX_VI)
  );
endmodule
""",
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
        print("gen_csr_leaves14 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_csr_leaves14 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
