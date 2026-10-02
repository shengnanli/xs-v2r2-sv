// HieModule.sv — hypervisor interrupt-enable CSR (hie) slice inside NewCSR.
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
