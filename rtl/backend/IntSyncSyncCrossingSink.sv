// Synchronous interrupt crossing sink is a one-bit transparent endpoint.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_IntSyncSyncCrossingSink_core(input logic incoming,output logic outgoing); assign outgoing=incoming; endmodule
module IntSyncSyncCrossingSink(input logic auto_in_sync_0,output logic auto_out_0); xs_IntSyncSyncCrossingSink_core u_core(.incoming(auto_in_sync_0),.outgoing(auto_out_0)); endmodule
