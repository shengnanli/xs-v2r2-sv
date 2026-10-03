// Reject disallowed user accesses to supervisor counters and state-enable CSRs.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module SLevelPermitModule (
  input  logic [11:0] io_in_csrAccess_addr,
  input  logic [1:0]  io_in_privState_PRVM,
  input  logic        io_in_privState_V,
  input  logic [31:0] io_in_xcounteren_scounteren,
  input  logic        io_in_xstateen_sstateen0_C,
  output logic        io_out_sLevelPermit_EX_II
);
  logic user_mode;
  logic host_user_mode;
  logic selected_counter_enabled;
  logic accesses_user_counter;
  logic accesses_supervisor_state;

  assign user_mode = io_in_privState_PRVM == 2'b00;
  assign host_user_mode = user_mode && !io_in_privState_V;
  assign selected_counter_enabled =
    io_in_xcounteren_scounteren[io_in_csrAccess_addr[4:0]];
  assign accesses_user_counter =
    (io_in_csrAccess_addr > 12'hBFF) && (io_in_csrAccess_addr < 12'hC20);
  assign accesses_supervisor_state =
    (io_in_csrAccess_addr[11:8] == 4'h8) ||
    (io_in_csrAccess_addr[11:6] == 6'h33);

  assign io_out_sLevelPermit_EX_II =
    (accesses_user_counter && host_user_mode && !selected_counter_enabled) ||
    (accesses_supervisor_state && host_user_mode && !io_in_xstateen_sstateen0_C);
endmodule
