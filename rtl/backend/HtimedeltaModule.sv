// HtimedeltaModule.sv — 64-bit writable hypervisor CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HtimedeltaModule_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic [63:0] regOut_ALL);
  logic [63:0] value_q;
  always_ff @(posedge clock or posedge reset) begin if(reset) value_q<=64'h0; else if(w_wen) value_q<=w_wdata; end
  assign rdata=value_q; assign regOut_ALL=value_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HtimedeltaModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);

  xs_HtimedeltaModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_ALL(regOut_ALL)
  );
endmodule
// END GENERATED
