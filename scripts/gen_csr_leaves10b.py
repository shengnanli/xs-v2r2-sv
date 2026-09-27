#!/usr/bin/env python3
"""Generate ten readable constant/pass-through CSR leaves."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]/'rtl/backend'
def emit(n,s): (R/f'{n}.sv').write_text(s)
def hdr(d): return f"// {d}\n// The semantic core states the CSR behavior; the exact wrapper preserves ports.\n// This combinational leaf contains no hidden architectural state.\n"
for n in ['Sstateen1Module','Sstateen2Module','Sstateen3Module']:
 emit(n,hdr(f'{n} is an unimplemented 32-bit state-enable bank and reads as zero.')+f'''module xs_{n}_core(output logic [31:0] value,mirror); assign value=32'b0; assign mirror=32'b0; endmodule
module {n}(output logic [31:0] rdata,output logic [31:0] regOut_ALL); xs_{n}_core u_core(.value(rdata),.mirror(regOut_ALL)); endmodule
''')
for n in ['Pmpcfg8Module','Pmpcfg10Module','Pmpcfg12Module','Pmpcfg14Module']:
 emit(n,hdr(f'{n} is outside the implemented PMP configuration range and reads as zero.')+f'''module xs_{n}_core(output logic [63:0] value,mirror); assign value=64'b0; assign mirror=64'b0; endmodule
module {n}(output logic [63:0] rdata,output logic [63:0] regOut_ALL); xs_{n}_core u_core(.value(rdata),.mirror(regOut_ALL)); endmodule
''')
for n in ['Pmpcfg0Module','Pmpcfg2Module','Pmpcfg4Module']:
 emit(n,hdr(f'{n} exposes the decoded PMP configuration word through both CSR views.')+f'''module xs_{n}_core(input logic [63:0] source,output logic [63:0] value,mirror); assign value=source; assign mirror=source; endmodule
module {n}(output logic [63:0] rdata,output logic [63:0] regOut_ALL,input logic [63:0] cfgRData); xs_{n}_core u_core(.source(cfgRData),.value(rdata),.mirror(regOut_ALL)); endmodule
''')
