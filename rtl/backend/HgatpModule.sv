// HgatpModule.sv — hypervisor address-translation root CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HgatpModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic [3:0] regOut_MODE, output logic [13:0] regOut_VMID, output logic [43:0] regOut_PPN
);
  logic [3:0] mode_q; logic [13:0] vmid_q; logic [43:0] ppn_q;
  wire mode_legal=(w_wdata[63:60]==4'h0)||(w_wdata[63:60]==4'h8)||(w_wdata[63:60]==4'h9);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin mode_q<=0; vmid_q<=0; ppn_q<=0; end
    else begin
      if (w_wen && mode_legal) mode_q<=w_wdata[63:60];
      if (w_wen) begin vmid_q<=w_wdata[57:44]; ppn_q<={8'h0,w_wdata[35:2],2'h0}; end
    end
  end
  assign rdata={mode_q,2'h0,vmid_q,ppn_q}; assign regOut_MODE=mode_q; assign regOut_VMID=vmid_q; assign regOut_PPN=ppn_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HgatpModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [3:0] regOut_MODE,
  output logic [13:0] regOut_VMID,
  output logic [43:0] regOut_PPN
);

  xs_HgatpModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_MODE(regOut_MODE),
    .regOut_VMID(regOut_VMID),
    .regOut_PPN(regOut_PPN)
  );
endmodule
// END GENERATED
