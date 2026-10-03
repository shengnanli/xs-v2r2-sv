// XRetPermitModule.sv — legality check of the trap-return instructions
// (mnret / mret / sret / dret) inside CSRPermitModule of NewCSR.
// Scala: NewCSR/CSRPermitModule.scala (class XRetPermitModule).  Purely
// combinational.  For each xRET it decides whether it raises
//   EX_II  illegal-instruction exception, or
//   EX_VI  virtual-instruction exception (only sret, only in a guest),
// and otherwise reports it as a legal return:
//   mnret, mret  illegal unless in M-mode (PRVM==3; V is not consulted)
//   sret         illegal in HU, or in HS while mstatus.TSR=1;
//                virtual-instruction in VU, or in VS while hstatus.VTSR=1
//   dret         illegal outside debug mode
module xs_XRetPermitModule_core (
  input  logic [1:0] prvm,
  input  logic       virt,
  input  logic       debug_mode,
  input  logic       mnret,
  input  logic       mret,
  input  logic       sret,
  input  logic       dret,
  input  logic       tsr,          // mstatus.TSR
  input  logic       vtsr,         // hstatus.VTSR
  output logic       ex_ii,        // some xRET raises illegal instruction
  output logic       ex_vi,        // sret raises virtual instruction
  output logic       legal_mnret,
  output logic       legal_mret,
  output logic       legal_sret,
  output logic       legal_dret
);
  logic mode_m, mode_hs, mode_hu, mode_vs, mode_vu;
  assign mode_m  = (prvm == 2'b11);
  assign mode_hs = ~virt & (prvm == 2'b01);
  assign mode_hu = ~virt & (prvm == 2'b00);
  assign mode_vs =  virt & (prvm == 2'b01);
  assign mode_vu =  virt & (prvm == 2'b00);

  logic mnret_ii, mret_ii, sret_ii, sret_vi, dret_ii;
  assign mnret_ii = mnret & ~mode_m;
  assign mret_ii  = mret  & ~mode_m;
  assign sret_ii  = sret  & (mode_hu | (mode_hs & tsr));
  assign sret_vi  = sret  & (mode_vu | (mode_vs & vtsr));
  assign dret_ii  = dret  & ~debug_mode;

  assign ex_ii       = mnret_ii | mret_ii | sret_ii | dret_ii;
  assign ex_vi       = sret_vi;
  assign legal_mnret = mnret & ~mnret_ii;
  assign legal_mret  = mret  & ~mret_ii;
  assign legal_sret  = sret  & ~(sret_ii | sret_vi);
  assign legal_dret  = dret  & ~dret_ii;
endmodule

module XRetPermitModule (
  input  [1:0] io_in_privState_PRVM,
  input        io_in_privState_V,
  input        io_in_debugMode,
  input        io_in_xRet_mnret,
  input        io_in_xRet_mret,
  input        io_in_xRet_sret,
  input        io_in_xRet_dret,
  input        io_in_status_tsr,
  input        io_in_status_vtsr,
  output       io_out_Xret_EX_II,
  output       io_out_Xret_EX_VI,
  output       io_out_hasLegalMNret,
  output       io_out_hasLegalMret,
  output       io_out_hasLegalSret,
  output       io_out_hasLegalDret
);
  xs_XRetPermitModule_core u_core (
    .prvm        (io_in_privState_PRVM),
    .virt        (io_in_privState_V),
    .debug_mode  (io_in_debugMode),
    .mnret       (io_in_xRet_mnret),
    .mret        (io_in_xRet_mret),
    .sret        (io_in_xRet_sret),
    .dret        (io_in_xRet_dret),
    .tsr         (io_in_status_tsr),
    .vtsr        (io_in_status_vtsr),
    .ex_ii       (io_out_Xret_EX_II),
    .ex_vi       (io_out_Xret_EX_VI),
    .legal_mnret (io_out_hasLegalMNret),
    .legal_mret  (io_out_hasLegalMret),
    .legal_sret  (io_out_hasLegalSret),
    .legal_dret  (io_out_hasLegalDret)
  );
endmodule
