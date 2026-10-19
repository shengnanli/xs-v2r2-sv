// TrapEntryVSEventModule.sv — privilege-specific trap-entry event transformation.
// This leaf translates trap causes, saved state, and target addresses for the CSR block.
// Address-mode and virtualization cases intentionally preserve the G1 reset/field semantics.
// The VS trap path prioritizes interrupt causes before forming translated PC and tval outputs.
// Assertion-print / stop gates used by the `ifndef SYNTHESIS checks below.
// Same names, override hooks and defaults as the firtool-1.62.1 standard header that every
// G1 golden file carries: +define+ASSERT_VERBOSE_COND=<expr> / +define+STOP_COND=<expr>
// add an extra gate; left undefined the gate is 1. `ifndef on the underscore name makes this
// a no-op when a golden file (or the user) has already defined it, so co-compiling with
// golden never redefines a macro, whichever file comes first. xs_assert_v2 itself is a
// DPI-C import supplied by the testbench (difftest src/test/vsrc/common/assert.v).
`ifndef ASSERT_VERBOSE_COND_
  `ifdef ASSERT_VERBOSE_COND
    `define ASSERT_VERBOSE_COND_ (`ASSERT_VERBOSE_COND)
  `else
    `define ASSERT_VERBOSE_COND_ 1
  `endif
`endif
`ifndef STOP_COND_
  `ifdef STOP_COND
    `define STOP_COND_ (`STOP_COND)
  `else
    `define STOP_COND_ 1
  `endif
`endif
module TrapEntryVSEventModule(
  input         clock,
  input         reset,
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isFetchMalAddr,
  input         in_satpFlushFirstFetchFault,
  input         in_isFetchBkpt,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_vsstatus_SIE,
  input         in_henvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input  [3:0]  in_oldSatp_MODE,
  input  [3:0]  in_oldVsatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input         in_virtualInterruptIsHvictlInject,
  input  [11:0] in_hvictlIID,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_vsepc_valid,
  output [62:0] out_vsepc_bits_epc,
  output        out_vscause_valid,
  output        out_vscause_bits_Interrupt,
  output [62:0] out_vscause_bits_ExceptionCode,
  output        out_vstval_valid,
  output [63:0] out_vstval_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);
  // Internal procedural nets keep the recovered module port declarations unchanged.
  logic out_privState_valid_i;
  logic [1:0] out_privState_bits_PRVM_i;
  logic out_privState_bits_V_i;
  logic out_vsstatus_valid_i;
  logic out_vsstatus_bits_SIE_i;
  logic out_vsstatus_bits_SPIE_i;
  logic out_vsstatus_bits_UBE_i;
  logic out_vsstatus_bits_SPP_i;
  logic [1:0] out_vsstatus_bits_VS_i;
  logic [1:0] out_vsstatus_bits_FS_i;
  logic [1:0] out_vsstatus_bits_XS_i;
  logic out_vsstatus_bits_SUM_i;
  logic out_vsstatus_bits_MXR_i;
  logic out_vsstatus_bits_SDT_i;
  logic [1:0] out_vsstatus_bits_UXL_i;
  logic out_vsstatus_bits_SD_i;
  logic out_vsepc_valid_i;
  logic [62:0] out_vsepc_bits_epc_i;
  logic out_vscause_valid_i;
  logic out_vscause_bits_Interrupt_i;
  logic [62:0] out_vscause_bits_ExceptionCode_i;
  logic out_vstval_valid_i;
  logic [63:0] out_vstval_bits_ALL_i;
  logic out_targetPc_valid_i;
  logic [63:0] out_targetPc_bits_pc_i;
  logic out_targetPc_bits_raiseIPF_i;
  logic out_targetPc_bits_raiseIAF_i;
  logic out_targetPc_bits_raiseIGPF_i;


  // Assertions use semantic exception classes so the datapath below stays readable.
  wire unsupported_vs_mode = valid & ~reset & ~in_privState_V;
  wire unsupported_interrupt = valid & in_causeNO_Interrupt &
    ~in_virtualInterruptIsHvictlInject & ~reset &
    ~((in_causeNO_ExceptionCode == 63'h2) |
      (in_causeNO_ExceptionCode == 63'h6) |
      (in_causeNO_ExceptionCode == 63'hA) |
      (in_causeNO_ExceptionCode == 63'h2F) |
      (in_causeNO_ExceptionCode == 63'h17) |
      (in_causeNO_ExceptionCode == 63'h2E) |
      (in_causeNO_ExceptionCode == 63'h2D) |
      (in_causeNO_ExceptionCode == 63'h16) |
      (in_causeNO_ExceptionCode == 63'h2C) |
      (in_causeNO_ExceptionCode == 63'h2B) |
      (in_causeNO_ExceptionCode == 63'h15) |
      (in_causeNO_ExceptionCode == 63'h2A) |
      (in_causeNO_ExceptionCode == 63'h29) |
      (in_causeNO_ExceptionCode == 63'h14) |
      (in_causeNO_ExceptionCode == 63'h28) |
      (in_causeNO_ExceptionCode == 63'h27) |
      (in_causeNO_ExceptionCode == 63'h13) |
      (in_causeNO_ExceptionCode == 63'h26) |
      (in_causeNO_ExceptionCode == 63'h25) |
      (in_causeNO_ExceptionCode == 63'h12) |
      (in_causeNO_ExceptionCode == 63'h24) |
      (in_causeNO_ExceptionCode == 63'h23) |
      (in_causeNO_ExceptionCode == 63'h11) |
      (in_causeNO_ExceptionCode == 63'h22) |
      (in_causeNO_ExceptionCode == 63'h21) |
      (in_causeNO_ExceptionCode == 63'h10) |
      (in_causeNO_ExceptionCode == 63'h20) |
      (in_causeNO_ExceptionCode == 63'h3F) |
      (in_causeNO_ExceptionCode == 63'h1F) |
      (in_causeNO_ExceptionCode == 63'h3E) |
      (in_causeNO_ExceptionCode == 63'h3D) |
      (in_causeNO_ExceptionCode == 63'h1E) |
      (in_causeNO_ExceptionCode == 63'h3C) |
      (in_causeNO_ExceptionCode == 63'h3B) |
      (in_causeNO_ExceptionCode == 63'h1D) |
      (in_causeNO_ExceptionCode == 63'h3A) |
      (in_causeNO_ExceptionCode == 63'h39) |
      (in_causeNO_ExceptionCode == 63'h1C) |
      (in_causeNO_ExceptionCode == 63'h38) |
      (in_causeNO_ExceptionCode == 63'h37) |
      (in_causeNO_ExceptionCode == 63'h1B) |
      (in_causeNO_ExceptionCode == 63'h36) |
      (in_causeNO_ExceptionCode == 63'h35) |
      (in_causeNO_ExceptionCode == 63'h1A) |
      (in_causeNO_ExceptionCode == 63'h34) |
      (in_causeNO_ExceptionCode == 63'h33) |
      (in_causeNO_ExceptionCode == 63'h19) |
      (in_causeNO_ExceptionCode == 63'h32) |
      (in_causeNO_ExceptionCode == 63'h31) |
      (in_causeNO_ExceptionCode == 63'h18) |
      (in_causeNO_ExceptionCode == 63'h30) |
      (in_causeNO_ExceptionCode == 63'hD));
  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (unsupported_vs_mode) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The mode must be VU or VS when entry VS mode\n    at TrapEntryVSEvent.scala:29 assert(in.privState.isVirtual, \"The mode must be VU or VS when entry VS mode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (unsupported_interrupt) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The VS mode can only handle VSEI, VSTI, VSSI and local interrupts\n    at TrapEntryVSEvent.scala:48 assert(\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end
  `endif

  wire mode_m_bare = &in_iMode_PRVM;
  wire mode_u_or_s = (in_iMode_PRVM == 2'h0) | (in_iMode_PRVM == 2'h1);
  wire guest_satp_bare = in_oldVsatp_MODE == 4'h0;
  wire guest_hgatp_bare = in_hgatp_MODE == 4'h0;
  wire guest_hgatp_sv39 = in_hgatp_MODE == 4'h8;
  wire guest_hgatp_sv48 = in_hgatp_MODE == 4'h9;
  wire host_satp_sv39 = in_oldSatp_MODE == 4'h8;
  wire guest_satp_sv39 = in_oldVsatp_MODE == 4'h8;
  wire host_satp_sv48 = in_oldSatp_MODE == 4'h9;
  wire guest_satp_sv48 = in_oldVsatp_MODE == 4'h9;
  wire target_satp_bare = in_vsatp_MODE == 4'h0;
  wire target_hgatp_bare = in_hgatp_MODE == 4'h0;
  wire target_hgatp_sv39 = in_hgatp_MODE == 4'h8;
  wire target_hgatp_sv48 = in_hgatp_MODE == 4'h9;

  logic [62:0] prioritized_cause;
  always_comb begin
    prioritized_cause = in_causeNO_ExceptionCode;
    if (in_causeNO_Interrupt &&
        ((in_causeNO_ExceptionCode == 63'h2) |
         (in_causeNO_ExceptionCode == 63'h6) |
         (in_causeNO_ExceptionCode == 63'hA)))
      prioritized_cause = in_causeNO_ExceptionCode - 63'd1;
  end

  logic [63:0] trap_pc;
  always_comb begin
    trap_pc = 64'b0;
    trap_pc = trap_pc | ({16'b0, in_trapPc[47:0]} &
      {64{mode_m_bare | (mode_u_or_s & ~in_iMode_V & (in_oldSatp_MODE == 4'h0)) |
          (in_iMode_V & guest_satp_bare & guest_hgatp_bare)}});
    trap_pc = trap_pc | ({{25{in_trapPc[38]}}, in_trapPc[38:0]} &
      {64{(mode_u_or_s & ~in_iMode_V & host_satp_sv39) |
          (in_iMode_V & guest_satp_sv39)}});
    trap_pc = trap_pc | ({23'b0, in_trapPc[40:0]} &
      {64{in_iMode_V & guest_satp_bare & guest_hgatp_sv39}});
    trap_pc = trap_pc | ({{16{in_trapPc[47]}}, in_trapPc[47:0]} &
      {64{(mode_u_or_s & ~in_iMode_V & host_satp_sv48) |
          (in_iMode_V & guest_satp_sv48)}});
    trap_pc = trap_pc | ({14'b0, in_trapPc} &
      {64{in_iMode_V & guest_satp_bare & guest_hgatp_sv48}});
  end

  wire fetch_exception = ~in_causeNO_Interrupt &
    ((prioritized_cause == 63'h1) | (prioritized_cause == 63'hC));
  wire breakpoint_exception = ~in_causeNO_Interrupt & (prioritized_cause == 63'h3);
  wire fetch_breakpoint = breakpoint_exception & in_isFetchBkpt;
  wire fill_memory_address =
    (~in_causeNO_Interrupt &
      ((prioritized_cause == 63'h4) | (prioritized_cause == 63'h5) |
       (prioritized_cause == 63'h6) | (prioritized_cause == 63'h7) |
       (prioritized_cause == 63'hD) | (prioritized_cause == 63'hF))) |
    (breakpoint_exception & ~in_isFetchBkpt);
  wire fill_guest_address = ((fetch_exception | fetch_breakpoint) & in_iMode_V) |
    (fill_memory_address & in_dMode_V);

  logic [63:0] tval_value;
  always_comb begin
    tval_value = 64'b0;
    tval_value = tval_value |
      (trap_pc & {64{(fetch_exception & ~in_isCrossPageIPF) | fetch_breakpoint}});
    tval_value = tval_value |
      ((trap_pc + 64'd2) & {64{fetch_exception & in_isCrossPageIPF}});
    tval_value = tval_value |
      (in_memExceptionVAddr & {64{fill_memory_address}});
  end

  always_comb begin
    out_privState_valid_i = valid;
    out_privState_bits_PRVM_i = 2'd1;
    out_privState_bits_V_i = 1'b1;
    out_vsstatus_valid_i = valid;
    out_vsstatus_bits_SIE_i = 1'b0;
    out_vsstatus_bits_SPIE_i = in_vsstatus_SIE;
    out_vsstatus_bits_UBE_i = 1'b0;
    out_vsstatus_bits_SPP_i = in_privState_PRVM[0];
    out_vsstatus_bits_VS_i = 2'b0;
    out_vsstatus_bits_FS_i = 2'b0;
    out_vsstatus_bits_XS_i = 2'b0;
    out_vsstatus_bits_SUM_i = 1'b0;
    out_vsstatus_bits_MXR_i = 1'b0;
    out_vsstatus_bits_SDT_i = in_henvcfg_DTE;
    out_vsstatus_bits_UXL_i = 2'b0;
    out_vsstatus_bits_SD_i = 1'b0;
    out_vsepc_valid_i = valid;
    out_vsepc_bits_epc_i = (in_satpFlushFirstFetchFault | ~in_isFetchMalAddr) ?
      trap_pc[63:1] : in_fetchMalTval[63:1];
    out_vscause_valid_i = valid;
    out_vscause_bits_Interrupt_i = in_causeNO_Interrupt;
    out_vscause_bits_ExceptionCode_i =
      (in_virtualInterruptIsHvictlInject & in_causeNO_Interrupt) ?
      {51'b0, in_hvictlIID} : prioritized_cause;
    out_vstval_valid_i = valid;
    out_vstval_bits_ALL_i = (in_satpFlushFirstFetchFault |
      ~(~in_causeNO_Interrupt & in_isFetchMalAddr)) ?
      {tval_value[63:32], tval_value[31:0] |
        ((~in_causeNO_Interrupt &
          ((prioritized_cause == 63'h2) | (prioritized_cause == 63'h16)) &
          in_trapInst_valid) ? in_trapInst_bits : 32'b0)} : in_fetchMalTval;
    out_targetPc_valid_i = valid;
    out_targetPc_bits_pc_i = in_pcFromXtvec;
    out_targetPc_bits_raiseIPF_i =
      ((in_vsatp_MODE == 4'h8) &
       (in_pcFromXtvec[63:39] != {25{in_pcFromXtvec[38]}})) |
      ((in_vsatp_MODE == 4'h9) &
       (in_pcFromXtvec[63:48] != {16{in_pcFromXtvec[47]}}));
    out_targetPc_bits_raiseIAF_i = target_satp_bare & target_hgatp_bare &
      (|in_pcFromXtvec[63:48]);
    out_targetPc_bits_raiseIGPF_i = target_satp_bare & target_hgatp_sv39 &
      (|in_pcFromXtvec[63:41]) |
      target_satp_bare & target_hgatp_sv48 & (|in_pcFromXtvec[63:50]);
  end

  assign out_privState_valid = out_privState_valid_i;
  assign out_privState_bits_PRVM = out_privState_bits_PRVM_i;
  assign out_privState_bits_V = out_privState_bits_V_i;
  assign out_vsstatus_valid = out_vsstatus_valid_i;
  assign out_vsstatus_bits_SIE = out_vsstatus_bits_SIE_i;
  assign out_vsstatus_bits_SPIE = out_vsstatus_bits_SPIE_i;
  assign out_vsstatus_bits_UBE = out_vsstatus_bits_UBE_i;
  assign out_vsstatus_bits_SPP = out_vsstatus_bits_SPP_i;
  assign out_vsstatus_bits_VS = out_vsstatus_bits_VS_i;
  assign out_vsstatus_bits_FS = out_vsstatus_bits_FS_i;
  assign out_vsstatus_bits_XS = out_vsstatus_bits_XS_i;
  assign out_vsstatus_bits_SUM = out_vsstatus_bits_SUM_i;
  assign out_vsstatus_bits_MXR = out_vsstatus_bits_MXR_i;
  assign out_vsstatus_bits_SDT = out_vsstatus_bits_SDT_i;
  assign out_vsstatus_bits_UXL = out_vsstatus_bits_UXL_i;
  assign out_vsstatus_bits_SD = out_vsstatus_bits_SD_i;
  assign out_vsepc_valid = out_vsepc_valid_i;
  assign out_vsepc_bits_epc = out_vsepc_bits_epc_i;
  assign out_vscause_valid = out_vscause_valid_i;
  assign out_vscause_bits_Interrupt = out_vscause_bits_Interrupt_i;
  assign out_vscause_bits_ExceptionCode = out_vscause_bits_ExceptionCode_i;
  assign out_vstval_valid = out_vstval_valid_i;
  assign out_vstval_bits_ALL = out_vstval_bits_ALL_i;
  assign out_targetPc_valid = out_targetPc_valid_i;
  assign out_targetPc_bits_pc = out_targetPc_bits_pc_i;
  assign out_targetPc_bits_raiseIPF = out_targetPc_bits_raiseIPF_i;
  assign out_targetPc_bits_raiseIAF = out_targetPc_bits_raiseIAF_i;
  assign out_targetPc_bits_raiseIGPF = out_targetPc_bits_raiseIGPF_i;
endmodule
