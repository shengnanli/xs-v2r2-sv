// Guest external interrupt pending bits feed both CSR encoding and raw view.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_HgeipModule_core(input logic [6:0] pending,output logic [63:0] value,output logic [6:0] raw_pending); assign value={56'b0,pending,1'b0}; assign raw_pending=pending; endmodule
module HgeipModule(output logic [63:0] rdata,output logic [6:0] regOut_ip,input logic [6:0] aiaToCSR_vseip); xs_HgeipModule_core u_core(.pending(aiaToCSR_vseip),.value(rdata),.raw_pending(regOut_ip)); endmodule
