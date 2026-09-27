// StopiModule packs interrupt identity and priority into the TOPI CSR layout.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_StopiModule_core(input logic [11:0] iid,input logic [7:0] irq_priority,output logic [63:0] value,output logic [11:0] iid_view); assign value={36'b0,iid,8'b0,irq_priority}; assign iid_view=iid; endmodule
module StopiModule(output logic [63:0] rdata,output logic [11:0] regOut_IID,input logic [11:0] topIR_stopi_IID,input logic [7:0] topIR_stopi_IPRIO); xs_StopiModule_core u_core(.iid(topIR_stopi_IID),.irq_priority(topIR_stopi_IPRIO),.value(rdata),.iid_view(regOut_IID)); endmodule
