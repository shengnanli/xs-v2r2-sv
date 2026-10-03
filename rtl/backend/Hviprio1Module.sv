// Hviprio1Module.sv — virtual interrupt-priority bytes.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_Hviprio1Module_core (input logic clock,input logic reset,input logic w_wen,input logic [63:0] w_wdata,output logic [63:0] rdata,output logic [7:0] regOut_PrioSSI,output logic [7:0] regOut_PrioSTI,output logic [7:0] regOut_PrioCOI,output logic [7:0] regOut_Prio14,output logic [7:0] regOut_Prio15);
  logic [7:0] ssi_q,sti_q,coi_q,irq14_q,irq15_q;
  always_ff @(posedge clock or posedge reset) begin if(reset) begin ssi_q<=0;sti_q<=0;coi_q<=0;irq14_q<=0;irq15_q<=0; end else if(w_wen) begin ssi_q<=w_wdata[15:8];sti_q<=w_wdata[31:24];coi_q<=w_wdata[47:40];irq14_q<=w_wdata[55:48];irq15_q<=w_wdata[63:56]; end end
  assign rdata={irq15_q,irq14_q,coi_q,8'h0,sti_q,8'h0,ssi_q,8'h0}; assign regOut_PrioSSI=ssi_q; assign regOut_PrioSTI=sti_q; assign regOut_PrioCOI=coi_q; assign regOut_Prio14=irq14_q; assign regOut_Prio15=irq15_q;
endmodule

// BEGIN GENERATED(csr_dh)
module Hviprio1Module(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [7:0] regOut_PrioSSI,
  output logic [7:0] regOut_PrioSTI,
  output logic [7:0] regOut_PrioCOI,
  output logic [7:0] regOut_Prio14,
  output logic [7:0] regOut_Prio15
);

  xs_Hviprio1Module_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_PrioSSI(regOut_PrioSSI),
    .regOut_PrioSTI(regOut_PrioSTI),
    .regOut_PrioCOI(regOut_PrioCOI),
    .regOut_Prio14(regOut_Prio14),
    .regOut_Prio15(regOut_Prio15)
  );
endmodule
// END GENERATED
