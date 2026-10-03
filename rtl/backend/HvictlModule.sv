// HvictlModule.sv — virtual interrupt-control CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HvictlModule_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic regOut_VTI,output logic [11:0] regOut_IID,output logic regOut_DPR,output logic regOut_IPRIOM,output logic [7:0] regOut_IPRIO);
  logic vti_q,dpr_q,ipriom_q; logic [11:0] iid_q; logic [7:0] iprio_q;
  always_ff @(posedge clock or posedge reset) begin if(reset) begin vti_q<=0;iid_q<=0;dpr_q<=0;ipriom_q<=0;iprio_q<=0; end else if(w_wen) begin vti_q<=w_wdata[30];iid_q<=w_wdata[27:16];dpr_q<=w_wdata[9];ipriom_q<=w_wdata[8];iprio_q<=w_wdata[7:0]; end end
  assign rdata={33'h0,vti_q,2'h0,iid_q,6'h0,dpr_q,ipriom_q,iprio_q}; assign regOut_VTI=vti_q; assign regOut_IID=iid_q; assign regOut_DPR=dpr_q; assign regOut_IPRIOM=ipriom_q; assign regOut_IPRIO=iprio_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HvictlModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_VTI,
  output logic [11:0] regOut_IID,
  output logic regOut_DPR,
  output logic regOut_IPRIOM,
  output logic [7:0] regOut_IPRIO
);

  xs_HvictlModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_VTI(regOut_VTI),
    .regOut_IID(regOut_IID),
    .regOut_DPR(regOut_DPR),
    .regOut_IPRIOM(regOut_IPRIOM),
    .regOut_IPRIO(regOut_IPRIO)
  );
endmodule
// END GENERATED
