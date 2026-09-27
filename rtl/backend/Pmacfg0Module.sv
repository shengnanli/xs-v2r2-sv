// Pmacfg0Module exposes the decoded PMA configuration word without transformation.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_Pmacfg0Module_core(input logic [63:0] source,output logic [63:0] value,mirror); assign value=source; assign mirror=source; endmodule
module Pmacfg0Module(output logic [63:0] rdata,output logic [63:0] regOut_ALL,input logic [63:0] cfgRData); xs_Pmacfg0Module_core u_core(.source(cfgRData),.value(rdata),.mirror(regOut_ALL)); endmodule
