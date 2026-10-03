// PrivilegePermitModule.sv — CSR privilege legality decode inside CSRPermitModule.
// Purely combinational: given the CSR address, the current privilege mode
// (PRVM) and virtualization state (V), decide whether the access is legal and,
// if not, which exception to raise (EX_II = illegal instruction,
// EX_VI = virtual instruction).
// Legality (from golden, kept term-for-term):
//   - debug CSRs (addr[11:4] == 8'h7B) are illegal outside debug mode;
//   - otherwise the access is legal iff the CSR's encoded privilege level
//     (addr[9:8]) does not exceed the effective privilege (PRVM, with V
//     demoting M to HS), or debug mode is active.
// EX_II vs EX_VI split: illegal accesses in V-mode to a non-Hypervisor CSR
// raise EX_VI; all other illegal accesses raise EX_II.
module xs_PrivilegePermitModule_core (
  input  logic [11:0] csr_addr,
  input  logic [1:0]  prvm,
  input  logic        virt,
  input  logic        debug_mode,
  output logic        ex_ii,
  output logic        ex_vi
);
  // Inverted decode inputs, matching the golden sum-of-products form.
  logic [4:0] inv;
  assign inv = ~{virt, prvm, csr_addr[9:8]};

  // Four legal-access product terms (effective privilege reaches the CSR level):
  //   U-mode CSR (addr[9:8]=00) reachable below M; S CSR from S; HS CSR from
  //   HS (V=1) or non-V S; M CSR only from real M (V=0).
  logic legal_regular;
  assign legal_regular =
      |{&{inv[0], inv[1], inv[3]},
        &{inv[1], prvm[0], inv[3]},
        &{inv[0], prvm[0], inv[4]},
        &{prvm[0], prvm[1], inv[4]}};

  logic legal;
  assign legal = (csr_addr[11:4] != 8'h7B) & legal_regular | debug_mode;

  assign ex_ii = ~legal & (~virt | (&csr_addr[9:8]));
  assign ex_vi = ~legal & virt & ~(&csr_addr[9:8]);
endmodule

module PrivilegePermitModule (
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_debugMode,
  output        io_out_privilege_EX_II,
  output        io_out_privilege_EX_VI
);
  xs_PrivilegePermitModule_core u_core (
    .csr_addr(io_in_csrAccess_addr),
    .prvm(io_in_privState_PRVM),
    .virt(io_in_privState_V),
    .debug_mode(io_in_debugMode),
    .ex_ii(io_out_privilege_EX_II),
    .ex_vi(io_out_privilege_EX_VI)
  );
endmodule
