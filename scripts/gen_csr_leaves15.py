#!/usr/bin/env python3
"""Generate fifteen readable CSR/control leaf wrappers."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]/'rtl/backend'
def emit(n,s): (R/f'{n}.sv').write_text(s)
def head(desc): return f"// {desc}\n// The semantic core names the operation; the exact-name wrapper preserves integration.\n// This leaf is combinational and contains no hidden architectural state.\n"

emit('MconfigptrModule',head('Machine configuration pointer is architecturally hard-wired to zero.')+'''module xs_MconfigptrModule_core(output logic [63:0] value); assign value=64'b0; endmodule
module MconfigptrModule(output logic [63:0] rdata); xs_MconfigptrModule_core u_core(.value(rdata)); endmodule
''')
emit('MhartidModule',head('Machine hart ID zero-extends the six-bit platform identifier.')+'''module xs_MhartidModule_core(input logic [5:0] hart_id,output logic [63:0] value); assign value={58'b0,hart_id}; endmodule
module MhartidModule(output logic [63:0] rdata,input logic [5:0] hartid); xs_MhartidModule_core u_core(.hart_id(hartid),.value(rdata)); endmodule
''')
emit('HgeipModule',head('Guest external interrupt pending bits feed both CSR encoding and raw view.')+'''module xs_HgeipModule_core(input logic [6:0] pending,output logic [63:0] value,output logic [6:0] raw_pending); assign value={56'b0,pending,1'b0}; assign raw_pending=pending; endmodule
module HgeipModule(output logic [63:0] rdata,output logic [6:0] regOut_ip,input logic [6:0] aiaToCSR_vseip); xs_HgeipModule_core u_core(.pending(aiaToCSR_vseip),.value(rdata),.raw_pending(regOut_ip)); endmodule
''')
for n,p in [('MiregModule','iregRead_mireg'),('SiregModule','iregRead_sireg'),('VSiregModule','iregRead_sireg'),('Tdata2Module','tdataRead_tdata2')]:
 emit(n,head(f'{n} mirrors its selected 64-bit indirect read source to both views.')+f'''module xs_{n}_core(input logic [63:0] source,output logic [63:0] value,mirror); assign value=source; assign mirror=source; endmodule
module {n}(output logic [63:0] rdata,output logic [63:0] regOut_ALL,input logic [63:0] {p}); xs_{n}_core u_core(.source({p}),.value(rdata),.mirror(regOut_ALL)); endmodule
''')
for n,p in [('MtopiModule','mtopi'),('StopiModule','stopi'),('VStopiModule','vstopi')]:
 emit(n,head(f'{n} packs interrupt identity and priority into the TOPI CSR layout.')+f'''module xs_{n}_core(input logic [11:0] iid,input logic [7:0] irq_priority,output logic [63:0] value,output logic [11:0] iid_view); assign value={{36'b0,iid,8'b0,irq_priority}}; assign iid_view=iid; endmodule
module {n}(output logic [63:0] rdata,output logic [11:0] regOut_IID,input logic [11:0] topIR_{p}_IID,input logic [7:0] topIR_{p}_IPRIO); xs_{n}_core u_core(.iid(topIR_{p}_IID),.irq_priority(topIR_{p}_IPRIO),.value(rdata),.iid_view(regOut_IID)); endmodule
''')
for n in ['Pmacfg0Module','Pmacfg2Module','Pmacfg4Module','Pmacfg6Module']:
 emit(n,head(f'{n} exposes the decoded PMA configuration word without transformation.')+f'''module xs_{n}_core(input logic [63:0] source,output logic [63:0] value,mirror); assign value=source; assign mirror=source; endmodule
module {n}(output logic [63:0] rdata,output logic [63:0] regOut_ALL,input logic [63:0] cfgRData); xs_{n}_core u_core(.source(cfgRData),.value(rdata),.mirror(regOut_ALL)); endmodule
''')
emit('IntSyncSyncCrossingSink',head('Synchronous interrupt crossing sink is a one-bit transparent endpoint.')+'''module xs_IntSyncSyncCrossingSink_core(input logic incoming,output logic outgoing); assign outgoing=incoming; endmodule
module IntSyncSyncCrossingSink(input logic auto_in_sync_0,output logic auto_out_0); xs_IntSyncSyncCrossingSink_core u_core(.incoming(auto_in_sync_0),.outgoing(auto_out_0)); endmodule
''')
