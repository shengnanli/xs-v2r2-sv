// HcounterenModule.sv — hypervisor counter-enable CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HcounterenModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_CY, output logic regOut_TM,
  output logic regOut_IR, output logic [28:0] regOut_HPM
);
  logic cy_q, tm_q, ir_q; logic [28:0] hpm_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin cy_q<=0; tm_q<=0; ir_q<=0; hpm_q<=29'h0; end
    else if (w_wen) begin cy_q<=w_wdata[0]; tm_q<=w_wdata[1]; ir_q<=w_wdata[2]; hpm_q<=w_wdata[31:3]; end
  end
  assign rdata={32'h0,hpm_q,ir_q,tm_q,cy_q};
  assign regOut_CY=cy_q; assign regOut_TM=tm_q; assign regOut_IR=ir_q; assign regOut_HPM=hpm_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HcounterenModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_CY,
  output logic regOut_TM,
  output logic regOut_IR,
  output logic [28:0] regOut_HPM
);

  xs_HcounterenModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_CY(regOut_CY),
    .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR),
    .regOut_HPM(regOut_HPM)
  );
endmodule
// END GENERATED
