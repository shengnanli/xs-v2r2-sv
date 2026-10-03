// Hstateen2Module.sv — VS state-enable level 2.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_Hstateen2Module_core (
  input logic clock, input logic w_wen, input logic [63:0] w_wdata, output logic [63:0] rdata,
  output logic regOut_SE, input logic fromMstateen2_SE
);
  logic se_q;
  always_ff @(posedge clock) if (w_wen) se_q<=w_wdata[63];
  wire se_out=se_q&fromMstateen2_SE;
  assign rdata={se_out,63'h0}; assign regOut_SE=se_out;
endmodule

// BEGIN GENERATED(csr_dh)
module Hstateen2Module(
  input logic clock,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_SE,
  input logic fromMstateen2_SE
);

  xs_Hstateen2Module_core u_core (
    .clock(clock),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SE(regOut_SE),
    .fromMstateen2_SE(fromMstateen2_SE)
  );
endmodule
// END GENERATED
