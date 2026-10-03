// MbmcModule.sv — machine memory block control CSR with one-way BME locking.
// BMA and BME become immutable after BME is set; KEYIDEN/CMODE are ordinary fields.
// BCLEAR is a write-one toggle that clears itself after the triggering write.
module xs_MbmcModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata, output logic [57:0] bma,
  output logic keyiden, output logic bme, output logic bclear,
  output logic cmode
);
  logic [57:0] bma_q;
  logic keyiden_q, bme_q, bclear_q, cmode_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      bma_q <= 58'h0;
      keyiden_q <= 1'b0;
      bme_q <= 1'b0;
      bclear_q <= 1'b0;
      cmode_q <= 1'b0;
    end else begin
      if (csr_wen && !bme_q)
        bma_q <= csr_wdata[63:6];
      if (csr_wen) begin
        keyiden_q <= csr_wdata[3];
        cmode_q <= csr_wdata[0];
      end
      if (csr_wen && !bme_q)
        bme_q <= csr_wdata[2];
      bclear_q <= ~bclear_q & csr_wen & csr_wdata[1];
    end
  end

  assign rdata = {bma_q, 2'h0, keyiden_q, bme_q, bclear_q, cmode_q};
  assign bma = bma_q;
  assign keyiden = keyiden_q;
  assign bme = bme_q;
  assign bclear = bclear_q;
  assign cmode = cmode_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module MbmcModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [57:0] regOut_BMA,
  output        regOut_KEYIDEN,
  output        regOut_BME,
  output        regOut_BCLEAR,
  output        regOut_CMODE
);

  xs_MbmcModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .csr_wen   (w_wen),
    .csr_wdata (w_wdata),
    .rdata     (rdata),
    .bma       (regOut_BMA),
    .keyiden   (regOut_KEYIDEN),
    .bme       (regOut_BME),
    .bclear    (regOut_BCLEAR),
    .cmode     (regOut_CMODE)
  );
endmodule
// END GENERATED
