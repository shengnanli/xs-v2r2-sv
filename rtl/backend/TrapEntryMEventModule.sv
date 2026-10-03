// TrapEntryMEventModule.sv — privilege-specific trap-entry event transformation.
// This leaf translates trap causes, saved state, and target addresses for the CSR block.
// Address-mode and virtualization cases intentionally preserve the G1 reset/field semantics.
module TrapEntryMEventModule(
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [55:0] in_trapPcGPA,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isHls,
  input         in_isFetchMalAddr,
  input         in_satpFlushFirstFetchFault,
  input         in_isFetchBkpt,
  input         in_trapIsForVSnonLeafPTE,
  input         in_hasDTExcp,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_mstatus_MIE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_hgatp_MODE,
  input  [3:0]  in_oldSatp_MODE,
  input  [3:0]  in_oldVsatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input  [63:0] in_memExceptionGPAddr,
  input         in_memExceptionIsForVSnonLeafPTE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mstatus_valid,
  output        out_mstatus_bits_SIE,
  output        out_mstatus_bits_MIE,
  output        out_mstatus_bits_SPIE,
  output        out_mstatus_bits_UBE,
  output        out_mstatus_bits_MPIE,
  output        out_mstatus_bits_SPP,
  output [1:0]  out_mstatus_bits_VS,
  output [1:0]  out_mstatus_bits_MPP,
  output [1:0]  out_mstatus_bits_FS,
  output [1:0]  out_mstatus_bits_XS,
  output        out_mstatus_bits_MPRV,
  output        out_mstatus_bits_SUM,
  output        out_mstatus_bits_MXR,
  output        out_mstatus_bits_TVM,
  output        out_mstatus_bits_TW,
  output        out_mstatus_bits_TSR,
  output        out_mstatus_bits_SDT,
  output [1:0]  out_mstatus_bits_UXL,
  output [1:0]  out_mstatus_bits_SXL,
  output        out_mstatus_bits_SBE,
  output        out_mstatus_bits_MBE,
  output        out_mstatus_bits_GVA,
  output        out_mstatus_bits_MPV,
  output        out_mstatus_bits_MDT,
  output        out_mstatus_bits_SD,
  output        out_mepc_valid,
  output [62:0] out_mepc_bits_epc,
  output        out_mcause_valid,
  output        out_mcause_bits_Interrupt,
  output [62:0] out_mcause_bits_ExceptionCode,
  output        out_mtval_valid,
  output [63:0] out_mtval_bits_ALL,
  output        out_mtval2_valid,
  output [63:0] out_mtval2_bits_ALL,
  output        out_mtinst_valid,
  output [63:0] out_mtinst_bits_ALL,
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
  logic out_mstatus_valid_i;
  logic out_mstatus_bits_SIE_i;
  logic out_mstatus_bits_MIE_i;
  logic out_mstatus_bits_SPIE_i;
  logic out_mstatus_bits_UBE_i;
  logic out_mstatus_bits_MPIE_i;
  logic out_mstatus_bits_SPP_i;
  logic [1:0] out_mstatus_bits_VS_i;
  logic [1:0] out_mstatus_bits_MPP_i;
  logic [1:0] out_mstatus_bits_FS_i;
  logic [1:0] out_mstatus_bits_XS_i;
  logic out_mstatus_bits_MPRV_i;
  logic out_mstatus_bits_SUM_i;
  logic out_mstatus_bits_MXR_i;
  logic out_mstatus_bits_TVM_i;
  logic out_mstatus_bits_TW_i;
  logic out_mstatus_bits_TSR_i;
  logic out_mstatus_bits_SDT_i;
  logic [1:0] out_mstatus_bits_UXL_i;
  logic [1:0] out_mstatus_bits_SXL_i;
  logic out_mstatus_bits_SBE_i;
  logic out_mstatus_bits_MBE_i;
  logic out_mstatus_bits_GVA_i;
  logic out_mstatus_bits_MPV_i;
  logic out_mstatus_bits_MDT_i;
  logic out_mstatus_bits_SD_i;
  logic out_mepc_valid_i;
  logic [62:0] out_mepc_bits_epc_i;
  logic out_mcause_valid_i;
  logic out_mcause_bits_Interrupt_i;
  logic [62:0] out_mcause_bits_ExceptionCode_i;
  logic out_mtval_valid_i;
  logic [63:0] out_mtval_bits_ALL_i;
  logic out_mtval2_valid_i;
  logic [63:0] out_mtval2_bits_ALL_i;
  logic out_mtinst_valid_i;
  logic [63:0] out_mtinst_bits_ALL_i;
  logic out_targetPc_valid_i;
  logic [63:0] out_targetPc_bits_pc_i;
  logic out_targetPc_bits_raiseIPF_i;
  logic out_targetPc_bits_raiseIAF_i;
  logic out_targetPc_bits_raiseIGPF_i;


  // Decode the translation mode once, then use those semantic predicates below.
  wire mode_m_bare = &in_iMode_PRVM;
  wire mode_u_or_s = (in_iMode_PRVM == 2'h0) | (in_iMode_PRVM == 2'h1);
  wire guest_satp_bare = in_oldVsatp_MODE == 4'h0;
  wire guest_hgatp_bare = in_hgatp_MODE == 4'h0;
  wire host_satp_bare = in_oldSatp_MODE == 4'h0;
  wire host_satp_sv39 = in_oldSatp_MODE == 4'h8;
  wire guest_satp_sv39 = in_oldVsatp_MODE == 4'h8;
  wire host_satp_sv48 = in_oldSatp_MODE == 4'h9;
  wire guest_satp_sv48 = in_oldVsatp_MODE == 4'h9;
  wire guest_hgatp_sv39 = in_hgatp_MODE == 4'h8;
  wire guest_hgatp_sv48 = in_hgatp_MODE == 4'h9;

  logic [63:0] trap_pc;
  logic [63:0] trap_pc_gpa;
  // Each translation case contributes a masked candidate; OR keeps the original
  // independent-case semantics while making the address modes visible to readers.
  always_comb begin
    trap_pc = 64'b0;
    trap_pc = trap_pc | ({16'b0, in_trapPc[47:0]} &
      {64{mode_m_bare | (mode_u_or_s & ~in_iMode_V & host_satp_bare) |
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
  always_comb begin
    trap_pc_gpa = 64'b0;
    trap_pc_gpa = trap_pc_gpa | ({16'b0, in_trapPcGPA[47:0]} &
      {64{mode_m_bare | (mode_u_or_s & ~in_iMode_V & host_satp_bare) |
          (in_iMode_V & guest_satp_bare & guest_hgatp_bare)}});
    trap_pc_gpa = trap_pc_gpa | ({{25{in_trapPcGPA[38]}}, in_trapPcGPA[38:0]} &
      {64{(mode_u_or_s & ~in_iMode_V & host_satp_sv39) |
          (in_iMode_V & guest_satp_sv39)}});
    trap_pc_gpa = trap_pc_gpa | ({23'b0, in_trapPcGPA[40:0]} &
      {64{in_iMode_V & guest_satp_bare & guest_hgatp_sv39}});
    trap_pc_gpa = trap_pc_gpa | ({{16{in_trapPcGPA[47]}}, in_trapPcGPA[47:0]} &
      {64{(mode_u_or_s & ~in_iMode_V & host_satp_sv48) |
          (in_iMode_V & guest_satp_sv48)}});
    trap_pc_gpa = trap_pc_gpa | ({14'b0, in_trapPcGPA[49:0]} &
      {64{in_iMode_V & guest_satp_bare & guest_hgatp_sv48}});
  end

  wire fetch_exception = ~in_causeNO_Interrupt &
    ((in_causeNO_ExceptionCode == 63'h0) |
     (in_causeNO_ExceptionCode == 63'h1) |
     (in_causeNO_ExceptionCode == 63'hC));
  wire breakpoint_exception = ~in_causeNO_Interrupt &
    (in_causeNO_ExceptionCode == 63'h3);
  wire fetch_breakpoint = breakpoint_exception & in_isFetchBkpt;
  wire load_store_guest_exception = ~in_causeNO_Interrupt &
    ((in_causeNO_ExceptionCode == 63'h15) |
     (in_causeNO_ExceptionCode == 63'h17));
  wire fetch_guest_exception = ~in_causeNO_Interrupt &
    (in_causeNO_ExceptionCode == 63'h14);
  wire fill_pc_plus_two = fetch_exception | fetch_guest_exception;
  wire fill_memory_address =
    (~in_causeNO_Interrupt &
      ((in_causeNO_ExceptionCode == 63'h4) |
       (in_causeNO_ExceptionCode == 63'h5) |
       (in_causeNO_ExceptionCode == 63'hD) |
       (in_causeNO_ExceptionCode == 63'h13) |
       (in_causeNO_ExceptionCode == 63'h6) |
       (in_causeNO_ExceptionCode == 63'h7) |
       (in_causeNO_ExceptionCode == 63'hF))) |
    (breakpoint_exception & ~in_isFetchBkpt);
  wire fill_guest_address = load_store_guest_exception | fetch_guest_exception |
    ((fetch_exception | fetch_breakpoint) & in_iMode_V) |
    (fill_memory_address & (in_dMode_V |
      (~in_causeNO_Interrupt & in_isHls)));

  logic [63:0] tval_value;
  logic [63:0] tval2_value;
  logic [61:0] tval2_gp;
  logic [63:0] trap_pc_gpa_plus_two;
  logic [55:0] trap_pc_input_plus_two;
  always_comb begin
    trap_pc_gpa_plus_two = trap_pc_gpa + 64'd2;
    trap_pc_input_plus_two = in_trapPcGPA + 56'd2;
  end
  always_comb begin
    tval_value = 64'b0;
    tval_value = tval_value |
      (trap_pc & {64{(fill_pc_plus_two & ~in_isCrossPageIPF) | fetch_breakpoint}});
    tval_value = tval_value |
      ((trap_pc + 64'd2) & {64{fill_pc_plus_two & in_isCrossPageIPF}});
    tval_value = tval_value |
      (in_memExceptionVAddr & {64{fill_memory_address | load_store_guest_exception}});
    tval2_gp = load_store_guest_exception ? in_memExceptionGPAddr[63:2] : 62'b0;
    tval2_value = 64'b0;
    if (in_satpFlushFirstFetchFault) begin
      tval2_value[61:0] = (in_fetchMalTval[63:2] &
        {62{fetch_guest_exception & in_isFetchMalAddr}}) |
        (trap_pc_gpa[63:2] &
        {62{fetch_guest_exception & ~in_isFetchMalAddr & ~in_isCrossPageIPF}}) |
        (trap_pc_gpa_plus_two[63:2] &
        {62{fetch_guest_exception & ~in_isFetchMalAddr & in_isCrossPageIPF}});
    end else begin
      tval2_value[61:0] = (in_fetchMalTval[63:2] &
        {62{fetch_guest_exception & in_isFetchMalAddr}}) |
        (in_trapPcGPA[55:2] &
        {62{fetch_guest_exception & ~in_isFetchMalAddr & ~in_isCrossPageIPF}}) |
        (trap_pc_input_plus_two[55:2] &
        {54{fetch_guest_exception & ~in_isFetchMalAddr & in_isCrossPageIPF}});
    end
    tval2_value[61:0] = tval2_value[61:0] | tval2_gp;
  end

  always_comb begin
    out_privState_valid_i = valid;
    out_privState_bits_PRVM_i = 2'd3;
    out_privState_bits_V_i = 1'b0;
    out_mstatus_valid_i = valid;
    out_mstatus_bits_SIE_i = 1'b0;
    out_mstatus_bits_MIE_i = 1'b0;
    out_mstatus_bits_SPIE_i = 1'b0;
    out_mstatus_bits_UBE_i = 1'b0;
    out_mstatus_bits_MPIE_i = in_mstatus_MIE;
    out_mstatus_bits_SPP_i = 1'b0;
    out_mstatus_bits_VS_i = 2'b0;
    out_mstatus_bits_MPP_i = in_privState_PRVM;
    out_mstatus_bits_FS_i = 2'b0;
    out_mstatus_bits_XS_i = 2'b0;
    out_mstatus_bits_MPRV_i = 1'b0;
    out_mstatus_bits_SUM_i = 1'b0;
    out_mstatus_bits_MXR_i = 1'b0;
    out_mstatus_bits_TVM_i = 1'b0;
    out_mstatus_bits_TW_i = 1'b0;
    out_mstatus_bits_TSR_i = 1'b0;
    out_mstatus_bits_SDT_i = 1'b0;
    out_mstatus_bits_UXL_i = 2'b0;
    out_mstatus_bits_SXL_i = 2'b0;
    out_mstatus_bits_SBE_i = 1'b0;
    out_mstatus_bits_MBE_i = 1'b0;
    out_mstatus_bits_GVA_i = fill_guest_address;
    out_mstatus_bits_MPV_i = in_privState_V;
    out_mstatus_bits_MDT_i = 1'b1;
    out_mstatus_bits_SD_i = 1'b0;

    out_mepc_valid_i = valid;
    out_mepc_bits_epc_i = (in_satpFlushFirstFetchFault | ~in_isFetchMalAddr) ?
      trap_pc[63:1] : in_fetchMalTval[63:1];
    out_mcause_valid_i = valid;
    out_mcause_bits_Interrupt_i = in_causeNO_Interrupt & ~in_hasDTExcp;
    out_mcause_bits_ExceptionCode_i = in_hasDTExcp ? 63'h10 : in_causeNO_ExceptionCode;
    out_mtval_valid_i = valid;
    out_mtval_bits_ALL_i = in_satpFlushFirstFetchFault |
      ~(~in_causeNO_Interrupt & in_isFetchMalAddr) ?
      {tval_value[63:32], tval_value[31:0] |
        ((~in_causeNO_Interrupt &
          ((in_causeNO_ExceptionCode == 63'h2) |
           (in_causeNO_ExceptionCode == 63'h16)) & in_trapInst_valid) ?
          in_trapInst_bits : 32'b0)} : in_fetchMalTval;
    out_mtval2_valid_i = valid;
    out_mtval2_bits_ALL_i = in_hasDTExcp ?
      {in_causeNO_Interrupt, in_causeNO_ExceptionCode} : {2'b0, tval2_value[61:0]};
    out_mtinst_valid_i = valid;
    out_mtinst_bits_ALL_i = {50'b0,
      ((fetch_guest_exception & in_trapIsForVSnonLeafPTE) |
       (load_store_guest_exception & in_memExceptionIsForVSnonLeafPTE)) ?
      14'h3000 : 14'b0};
    out_targetPc_valid_i = valid;
    out_targetPc_bits_pc_i = in_pcFromXtvec;
    out_targetPc_bits_raiseIPF_i = 1'b0;
    out_targetPc_bits_raiseIAF_i = |in_pcFromXtvec[63:48];
    out_targetPc_bits_raiseIGPF_i = 1'b0;
  end

  assign out_privState_valid = out_privState_valid_i;
  assign out_privState_bits_PRVM = out_privState_bits_PRVM_i;
  assign out_privState_bits_V = out_privState_bits_V_i;
  assign out_mstatus_valid = out_mstatus_valid_i;
  assign out_mstatus_bits_SIE = out_mstatus_bits_SIE_i;
  assign out_mstatus_bits_MIE = out_mstatus_bits_MIE_i;
  assign out_mstatus_bits_SPIE = out_mstatus_bits_SPIE_i;
  assign out_mstatus_bits_UBE = out_mstatus_bits_UBE_i;
  assign out_mstatus_bits_MPIE = out_mstatus_bits_MPIE_i;
  assign out_mstatus_bits_SPP = out_mstatus_bits_SPP_i;
  assign out_mstatus_bits_VS = out_mstatus_bits_VS_i;
  assign out_mstatus_bits_MPP = out_mstatus_bits_MPP_i;
  assign out_mstatus_bits_FS = out_mstatus_bits_FS_i;
  assign out_mstatus_bits_XS = out_mstatus_bits_XS_i;
  assign out_mstatus_bits_MPRV = out_mstatus_bits_MPRV_i;
  assign out_mstatus_bits_SUM = out_mstatus_bits_SUM_i;
  assign out_mstatus_bits_MXR = out_mstatus_bits_MXR_i;
  assign out_mstatus_bits_TVM = out_mstatus_bits_TVM_i;
  assign out_mstatus_bits_TW = out_mstatus_bits_TW_i;
  assign out_mstatus_bits_TSR = out_mstatus_bits_TSR_i;
  assign out_mstatus_bits_SDT = out_mstatus_bits_SDT_i;
  assign out_mstatus_bits_UXL = out_mstatus_bits_UXL_i;
  assign out_mstatus_bits_SXL = out_mstatus_bits_SXL_i;
  assign out_mstatus_bits_SBE = out_mstatus_bits_SBE_i;
  assign out_mstatus_bits_MBE = out_mstatus_bits_MBE_i;
  assign out_mstatus_bits_GVA = out_mstatus_bits_GVA_i;
  assign out_mstatus_bits_MPV = out_mstatus_bits_MPV_i;
  assign out_mstatus_bits_MDT = out_mstatus_bits_MDT_i;
  assign out_mstatus_bits_SD = out_mstatus_bits_SD_i;
  assign out_mepc_valid = out_mepc_valid_i;
  assign out_mepc_bits_epc = out_mepc_bits_epc_i;
  assign out_mcause_valid = out_mcause_valid_i;
  assign out_mcause_bits_Interrupt = out_mcause_bits_Interrupt_i;
  assign out_mcause_bits_ExceptionCode = out_mcause_bits_ExceptionCode_i;
  assign out_mtval_valid = out_mtval_valid_i;
  assign out_mtval_bits_ALL = out_mtval_bits_ALL_i;
  assign out_mtval2_valid = out_mtval2_valid_i;
  assign out_mtval2_bits_ALL = out_mtval2_bits_ALL_i;
  assign out_mtinst_valid = out_mtinst_valid_i;
  assign out_mtinst_bits_ALL = out_mtinst_bits_ALL_i;
  assign out_targetPc_valid = out_targetPc_valid_i;
  assign out_targetPc_bits_pc = out_targetPc_bits_pc_i;
  assign out_targetPc_bits_raiseIPF = out_targetPc_bits_raiseIPF_i;
  assign out_targetPc_bits_raiseIAF = out_targetPc_bits_raiseIAF_i;
  assign out_targetPc_bits_raiseIGPF = out_targetPc_bits_raiseIGPF_i;
endmodule
