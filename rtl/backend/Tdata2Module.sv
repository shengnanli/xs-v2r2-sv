// Tdata2Module mirrors its selected 64-bit indirect read source to both views.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_Tdata2Module_core(input logic [63:0] source,output logic [63:0] value,mirror); assign value=source; assign mirror=source; endmodule
module Tdata2Module(output logic [63:0] rdata,output logic [63:0] regOut_ALL,input logic [63:0] tdataRead_tdata2); xs_Tdata2Module_core u_core(.source(tdataRead_tdata2),.value(rdata),.mirror(regOut_ALL)); endmodule
