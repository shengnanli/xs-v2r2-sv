// McounterenModule.sv — machine counter delegation enables.
// CY, TM, IR and HPM[28:0] are ordinary resettable WARL bit fields.
// The wrapper preserves the flattened NewCSR field outputs.
module xs_McounterenModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata,
  output logic cy, output logic tm, output logic ir,
  output logic [28:0] hpm
);
  logic cy_q, tm_q, ir_q;
  logic [28:0] hpm_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cy_q <= 1'b0;
      tm_q <= 1'b0;
      ir_q <= 1'b0;
      hpm_q <= 29'h0;
    end else if (csr_wen) begin
      cy_q <= csr_wdata[0];
      tm_q <= csr_wdata[1];
      ir_q <= csr_wdata[2];
      hpm_q <= csr_wdata[31:3];
    end
  end

  assign rdata = {32'h0, hpm_q, ir_q, tm_q, cy_q};
  assign cy = cy_q;
  assign tm = tm_q;
  assign ir = ir_q;
  assign hpm = hpm_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module McounterenModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);

  xs_McounterenModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .csr_wen   (w_wen),
    .csr_wdata (w_wdata),
    .rdata     (rdata),
    .cy        (regOut_CY),
    .tm        (regOut_TM),
    .ir        (regOut_IR),
    .hpm       (regOut_HPM)
  );
endmodule
// END GENERATED
