`timescale 1ns/1ps
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  integer errors = 0;
  integer checks = 0;
  integer cycles = 0;
  integer ncycles = 200000;
  always #1 clock = ~clock;
  initial void'($value$plusargs("ncycles=%d", ncycles));

  // TrapEntryDEventModule exact G1 port differential
  logic valid_0;
  logic [49:0]in_trapPc_0;
  logic [63:0]in_fetchMalTval_0;
  logic in_isFetchMalAddr_0;
  logic in_satpFlushFirstFetchFault_0;
  logic [1:0]in_iMode_PRVM_0;
  logic in_iMode_V_0;
  logic [1:0]in_privState_PRVM_0;
  logic in_privState_V_0;
  logic [3:0]in_hgatp_MODE_0;
  logic [3:0]in_oldSatp_MODE_0;
  logic [3:0]in_oldVsatp_MODE_0;
  logic in_hasTrap_0;
  logic in_debugMode_0;
  logic in_hasDebugIntr_0;
  logic in_triggerEnterDebugMode_0;
  logic in_hasDebugEbreakException_0;
  logic in_hasSingleStep_0;
  logic in_breakPoint_0;
  logic in_criticalErrorStateEnterDebug_0;
  logic in_holdDpc_0;
  wire out_privState_valid_0_g;
  wire out_privState_valid_0_x;
  wire [1:0]out_privState_bits_PRVM_0_g;
  wire [1:0]out_privState_bits_PRVM_0_x;
  wire out_privState_bits_V_0_g;
  wire out_privState_bits_V_0_x;
  wire out_dcsr_valid_0_g;
  wire out_dcsr_valid_0_x;
  wire [3:0]out_dcsr_bits_DEBUGVER_0_g;
  wire [3:0]out_dcsr_bits_DEBUGVER_0_x;
  wire [2:0]out_dcsr_bits_EXTCAUSE_0_g;
  wire [2:0]out_dcsr_bits_EXTCAUSE_0_x;
  wire out_dcsr_bits_CETRIG_0_g;
  wire out_dcsr_bits_CETRIG_0_x;
  wire out_dcsr_bits_EBREAKVS_0_g;
  wire out_dcsr_bits_EBREAKVS_0_x;
  wire out_dcsr_bits_EBREAKVU_0_g;
  wire out_dcsr_bits_EBREAKVU_0_x;
  wire out_dcsr_bits_EBREAKM_0_g;
  wire out_dcsr_bits_EBREAKM_0_x;
  wire out_dcsr_bits_EBREAKS_0_g;
  wire out_dcsr_bits_EBREAKS_0_x;
  wire out_dcsr_bits_EBREAKU_0_g;
  wire out_dcsr_bits_EBREAKU_0_x;
  wire out_dcsr_bits_STEPIE_0_g;
  wire out_dcsr_bits_STEPIE_0_x;
  wire out_dcsr_bits_STOPCOUNT_0_g;
  wire out_dcsr_bits_STOPCOUNT_0_x;
  wire out_dcsr_bits_STOPTIME_0_g;
  wire out_dcsr_bits_STOPTIME_0_x;
  wire [2:0]out_dcsr_bits_CAUSE_0_g;
  wire [2:0]out_dcsr_bits_CAUSE_0_x;
  wire out_dcsr_bits_V_0_g;
  wire out_dcsr_bits_V_0_x;
  wire out_dcsr_bits_MPRVEN_0_g;
  wire out_dcsr_bits_MPRVEN_0_x;
  wire out_dcsr_bits_NMIP_0_g;
  wire out_dcsr_bits_NMIP_0_x;
  wire out_dcsr_bits_STEP_0_g;
  wire out_dcsr_bits_STEP_0_x;
  wire [1:0]out_dcsr_bits_PRV_0_g;
  wire [1:0]out_dcsr_bits_PRV_0_x;
  wire out_dpc_valid_0_g;
  wire out_dpc_valid_0_x;
  wire [62:0]out_dpc_bits_epc_0_g;
  wire [62:0]out_dpc_bits_epc_0_x;
  wire out_targetPc_valid_0_g;
  wire out_targetPc_valid_0_x;
  wire [63:0]out_targetPc_bits_pc_0_g;
  wire [63:0]out_targetPc_bits_pc_0_x;
  wire out_targetPc_bits_raiseIPF_0_g;
  wire out_targetPc_bits_raiseIPF_0_x;
  wire out_targetPc_bits_raiseIAF_0_g;
  wire out_targetPc_bits_raiseIAF_0_x;
  wire out_targetPc_bits_raiseIGPF_0_g;
  wire out_targetPc_bits_raiseIGPF_0_x;
  wire out_debugMode_valid_0_g;
  wire out_debugMode_valid_0_x;
  wire out_debugMode_bits_0_g;
  wire out_debugMode_bits_0_x;
  wire out_debugIntrEnable_valid_0_g;
  wire out_debugIntrEnable_valid_0_x;
  wire out_debugIntrEnable_bits_0_g;
  wire out_debugIntrEnable_bits_0_x;
  TrapEntryDEventModule u_TrapEntryDEventModule_g (
    .valid(valid_0),
    .in_trapPc(in_trapPc_0),
    .in_fetchMalTval(in_fetchMalTval_0),
    .in_isFetchMalAddr(in_isFetchMalAddr_0),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_0),
    .in_iMode_PRVM(in_iMode_PRVM_0),
    .in_iMode_V(in_iMode_V_0),
    .in_privState_PRVM(in_privState_PRVM_0),
    .in_privState_V(in_privState_V_0),
    .in_hgatp_MODE(in_hgatp_MODE_0),
    .in_oldSatp_MODE(in_oldSatp_MODE_0),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_0),
    .in_hasTrap(in_hasTrap_0),
    .in_debugMode(in_debugMode_0),
    .in_hasDebugIntr(in_hasDebugIntr_0),
    .in_triggerEnterDebugMode(in_triggerEnterDebugMode_0),
    .in_hasDebugEbreakException(in_hasDebugEbreakException_0),
    .in_hasSingleStep(in_hasSingleStep_0),
    .in_breakPoint(in_breakPoint_0),
    .in_criticalErrorStateEnterDebug(in_criticalErrorStateEnterDebug_0),
    .in_holdDpc(in_holdDpc_0),
    .out_privState_valid(out_privState_valid_0_g),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_0_g),
    .out_privState_bits_V(out_privState_bits_V_0_g),
    .out_dcsr_valid(out_dcsr_valid_0_g),
    .out_dcsr_bits_DEBUGVER(out_dcsr_bits_DEBUGVER_0_g),
    .out_dcsr_bits_EXTCAUSE(out_dcsr_bits_EXTCAUSE_0_g),
    .out_dcsr_bits_CETRIG(out_dcsr_bits_CETRIG_0_g),
    .out_dcsr_bits_EBREAKVS(out_dcsr_bits_EBREAKVS_0_g),
    .out_dcsr_bits_EBREAKVU(out_dcsr_bits_EBREAKVU_0_g),
    .out_dcsr_bits_EBREAKM(out_dcsr_bits_EBREAKM_0_g),
    .out_dcsr_bits_EBREAKS(out_dcsr_bits_EBREAKS_0_g),
    .out_dcsr_bits_EBREAKU(out_dcsr_bits_EBREAKU_0_g),
    .out_dcsr_bits_STEPIE(out_dcsr_bits_STEPIE_0_g),
    .out_dcsr_bits_STOPCOUNT(out_dcsr_bits_STOPCOUNT_0_g),
    .out_dcsr_bits_STOPTIME(out_dcsr_bits_STOPTIME_0_g),
    .out_dcsr_bits_CAUSE(out_dcsr_bits_CAUSE_0_g),
    .out_dcsr_bits_V(out_dcsr_bits_V_0_g),
    .out_dcsr_bits_MPRVEN(out_dcsr_bits_MPRVEN_0_g),
    .out_dcsr_bits_NMIP(out_dcsr_bits_NMIP_0_g),
    .out_dcsr_bits_STEP(out_dcsr_bits_STEP_0_g),
    .out_dcsr_bits_PRV(out_dcsr_bits_PRV_0_g),
    .out_dpc_valid(out_dpc_valid_0_g),
    .out_dpc_bits_epc(out_dpc_bits_epc_0_g),
    .out_targetPc_valid(out_targetPc_valid_0_g),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_0_g),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_0_g),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_0_g),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_0_g),
    .out_debugMode_valid(out_debugMode_valid_0_g),
    .out_debugMode_bits(out_debugMode_bits_0_g),
    .out_debugIntrEnable_valid(out_debugIntrEnable_valid_0_g),
    .out_debugIntrEnable_bits(out_debugIntrEnable_bits_0_g)
  );
  TrapEntryDEventModule_xs u_TrapEntryDEventModule_x (
    .valid(valid_0),
    .in_trapPc(in_trapPc_0),
    .in_fetchMalTval(in_fetchMalTval_0),
    .in_isFetchMalAddr(in_isFetchMalAddr_0),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_0),
    .in_iMode_PRVM(in_iMode_PRVM_0),
    .in_iMode_V(in_iMode_V_0),
    .in_privState_PRVM(in_privState_PRVM_0),
    .in_privState_V(in_privState_V_0),
    .in_hgatp_MODE(in_hgatp_MODE_0),
    .in_oldSatp_MODE(in_oldSatp_MODE_0),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_0),
    .in_hasTrap(in_hasTrap_0),
    .in_debugMode(in_debugMode_0),
    .in_hasDebugIntr(in_hasDebugIntr_0),
    .in_triggerEnterDebugMode(in_triggerEnterDebugMode_0),
    .in_hasDebugEbreakException(in_hasDebugEbreakException_0),
    .in_hasSingleStep(in_hasSingleStep_0),
    .in_breakPoint(in_breakPoint_0),
    .in_criticalErrorStateEnterDebug(in_criticalErrorStateEnterDebug_0),
    .in_holdDpc(in_holdDpc_0),
    .out_privState_valid(out_privState_valid_0_x),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_0_x),
    .out_privState_bits_V(out_privState_bits_V_0_x),
    .out_dcsr_valid(out_dcsr_valid_0_x),
    .out_dcsr_bits_DEBUGVER(out_dcsr_bits_DEBUGVER_0_x),
    .out_dcsr_bits_EXTCAUSE(out_dcsr_bits_EXTCAUSE_0_x),
    .out_dcsr_bits_CETRIG(out_dcsr_bits_CETRIG_0_x),
    .out_dcsr_bits_EBREAKVS(out_dcsr_bits_EBREAKVS_0_x),
    .out_dcsr_bits_EBREAKVU(out_dcsr_bits_EBREAKVU_0_x),
    .out_dcsr_bits_EBREAKM(out_dcsr_bits_EBREAKM_0_x),
    .out_dcsr_bits_EBREAKS(out_dcsr_bits_EBREAKS_0_x),
    .out_dcsr_bits_EBREAKU(out_dcsr_bits_EBREAKU_0_x),
    .out_dcsr_bits_STEPIE(out_dcsr_bits_STEPIE_0_x),
    .out_dcsr_bits_STOPCOUNT(out_dcsr_bits_STOPCOUNT_0_x),
    .out_dcsr_bits_STOPTIME(out_dcsr_bits_STOPTIME_0_x),
    .out_dcsr_bits_CAUSE(out_dcsr_bits_CAUSE_0_x),
    .out_dcsr_bits_V(out_dcsr_bits_V_0_x),
    .out_dcsr_bits_MPRVEN(out_dcsr_bits_MPRVEN_0_x),
    .out_dcsr_bits_NMIP(out_dcsr_bits_NMIP_0_x),
    .out_dcsr_bits_STEP(out_dcsr_bits_STEP_0_x),
    .out_dcsr_bits_PRV(out_dcsr_bits_PRV_0_x),
    .out_dpc_valid(out_dpc_valid_0_x),
    .out_dpc_bits_epc(out_dpc_bits_epc_0_x),
    .out_targetPc_valid(out_targetPc_valid_0_x),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_0_x),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_0_x),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_0_x),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_0_x),
    .out_debugMode_valid(out_debugMode_valid_0_x),
    .out_debugMode_bits(out_debugMode_bits_0_x),
    .out_debugIntrEnable_valid(out_debugIntrEnable_valid_0_x),
    .out_debugIntrEnable_bits(out_debugIntrEnable_bits_0_x)
  );

  // TrapEntryHSEventModule exact G1 port differential
  logic valid_1;
  logic in_causeNO_Interrupt_1;
  logic [62:0]in_causeNO_ExceptionCode_1;
  logic [49:0]in_trapPc_1;
  logic [55:0]in_trapPcGPA_1;
  logic in_trapInst_valid_1;
  logic [31:0]in_trapInst_bits_1;
  logic [63:0]in_fetchMalTval_1;
  logic in_isCrossPageIPF_1;
  logic in_isHls_1;
  logic in_isFetchMalAddr_1;
  logic in_satpFlushFirstFetchFault_1;
  logic in_isFetchBkpt_1;
  logic in_trapIsForVSnonLeafPTE_1;
  logic [1:0]in_iMode_PRVM_1;
  logic in_iMode_V_1;
  logic in_dMode_V_1;
  logic [1:0]in_privState_PRVM_1;
  logic in_privState_V_1;
  logic in_hstatus_SPVP_1;
  logic in_sstatus_SIE_1;
  logic in_menvcfg_DTE_1;
  logic [63:0]in_pcFromXtvec_1;
  logic [3:0]in_satp_MODE_1;
  logic [3:0]in_hgatp_MODE_1;
  logic [3:0]in_oldSatp_MODE_1;
  logic [3:0]in_oldVsatp_MODE_1;
  logic [63:0]in_memExceptionVAddr_1;
  logic [63:0]in_memExceptionGPAddr_1;
  logic in_memExceptionIsForVSnonLeafPTE_1;
  wire out_privState_valid_1_g;
  wire out_privState_valid_1_x;
  wire [1:0]out_privState_bits_PRVM_1_g;
  wire [1:0]out_privState_bits_PRVM_1_x;
  wire out_privState_bits_V_1_g;
  wire out_privState_bits_V_1_x;
  wire out_mstatus_valid_1_g;
  wire out_mstatus_valid_1_x;
  wire out_mstatus_bits_SIE_1_g;
  wire out_mstatus_bits_SIE_1_x;
  wire out_mstatus_bits_MIE_1_g;
  wire out_mstatus_bits_MIE_1_x;
  wire out_mstatus_bits_SPIE_1_g;
  wire out_mstatus_bits_SPIE_1_x;
  wire out_mstatus_bits_UBE_1_g;
  wire out_mstatus_bits_UBE_1_x;
  wire out_mstatus_bits_MPIE_1_g;
  wire out_mstatus_bits_MPIE_1_x;
  wire out_mstatus_bits_SPP_1_g;
  wire out_mstatus_bits_SPP_1_x;
  wire [1:0]out_mstatus_bits_VS_1_g;
  wire [1:0]out_mstatus_bits_VS_1_x;
  wire [1:0]out_mstatus_bits_MPP_1_g;
  wire [1:0]out_mstatus_bits_MPP_1_x;
  wire [1:0]out_mstatus_bits_FS_1_g;
  wire [1:0]out_mstatus_bits_FS_1_x;
  wire [1:0]out_mstatus_bits_XS_1_g;
  wire [1:0]out_mstatus_bits_XS_1_x;
  wire out_mstatus_bits_MPRV_1_g;
  wire out_mstatus_bits_MPRV_1_x;
  wire out_mstatus_bits_SUM_1_g;
  wire out_mstatus_bits_SUM_1_x;
  wire out_mstatus_bits_MXR_1_g;
  wire out_mstatus_bits_MXR_1_x;
  wire out_mstatus_bits_TVM_1_g;
  wire out_mstatus_bits_TVM_1_x;
  wire out_mstatus_bits_TW_1_g;
  wire out_mstatus_bits_TW_1_x;
  wire out_mstatus_bits_TSR_1_g;
  wire out_mstatus_bits_TSR_1_x;
  wire out_mstatus_bits_SDT_1_g;
  wire out_mstatus_bits_SDT_1_x;
  wire [1:0]out_mstatus_bits_UXL_1_g;
  wire [1:0]out_mstatus_bits_UXL_1_x;
  wire [1:0]out_mstatus_bits_SXL_1_g;
  wire [1:0]out_mstatus_bits_SXL_1_x;
  wire out_mstatus_bits_SBE_1_g;
  wire out_mstatus_bits_SBE_1_x;
  wire out_mstatus_bits_MBE_1_g;
  wire out_mstatus_bits_MBE_1_x;
  wire out_mstatus_bits_GVA_1_g;
  wire out_mstatus_bits_GVA_1_x;
  wire out_mstatus_bits_MPV_1_g;
  wire out_mstatus_bits_MPV_1_x;
  wire out_mstatus_bits_MDT_1_g;
  wire out_mstatus_bits_MDT_1_x;
  wire out_mstatus_bits_SD_1_g;
  wire out_mstatus_bits_SD_1_x;
  wire out_hstatus_valid_1_g;
  wire out_hstatus_valid_1_x;
  wire out_hstatus_bits_VSBE_1_g;
  wire out_hstatus_bits_VSBE_1_x;
  wire out_hstatus_bits_GVA_1_g;
  wire out_hstatus_bits_GVA_1_x;
  wire out_hstatus_bits_SPV_1_g;
  wire out_hstatus_bits_SPV_1_x;
  wire out_hstatus_bits_SPVP_1_g;
  wire out_hstatus_bits_SPVP_1_x;
  wire out_hstatus_bits_HU_1_g;
  wire out_hstatus_bits_HU_1_x;
  wire [5:0]out_hstatus_bits_VGEIN_1_g;
  wire [5:0]out_hstatus_bits_VGEIN_1_x;
  wire out_hstatus_bits_VTVM_1_g;
  wire out_hstatus_bits_VTVM_1_x;
  wire out_hstatus_bits_VTW_1_g;
  wire out_hstatus_bits_VTW_1_x;
  wire out_hstatus_bits_VTSR_1_g;
  wire out_hstatus_bits_VTSR_1_x;
  wire [1:0]out_hstatus_bits_VSXL_1_g;
  wire [1:0]out_hstatus_bits_VSXL_1_x;
  wire [1:0]out_hstatus_bits_HUPMM_1_g;
  wire [1:0]out_hstatus_bits_HUPMM_1_x;
  wire out_sepc_valid_1_g;
  wire out_sepc_valid_1_x;
  wire [62:0]out_sepc_bits_epc_1_g;
  wire [62:0]out_sepc_bits_epc_1_x;
  wire out_scause_valid_1_g;
  wire out_scause_valid_1_x;
  wire out_scause_bits_Interrupt_1_g;
  wire out_scause_bits_Interrupt_1_x;
  wire [62:0]out_scause_bits_ExceptionCode_1_g;
  wire [62:0]out_scause_bits_ExceptionCode_1_x;
  wire out_stval_valid_1_g;
  wire out_stval_valid_1_x;
  wire [63:0]out_stval_bits_ALL_1_g;
  wire [63:0]out_stval_bits_ALL_1_x;
  wire out_htval_valid_1_g;
  wire out_htval_valid_1_x;
  wire [63:0]out_htval_bits_ALL_1_g;
  wire [63:0]out_htval_bits_ALL_1_x;
  wire out_htinst_valid_1_g;
  wire out_htinst_valid_1_x;
  wire [63:0]out_htinst_bits_ALL_1_g;
  wire [63:0]out_htinst_bits_ALL_1_x;
  wire out_targetPc_valid_1_g;
  wire out_targetPc_valid_1_x;
  wire [63:0]out_targetPc_bits_pc_1_g;
  wire [63:0]out_targetPc_bits_pc_1_x;
  wire out_targetPc_bits_raiseIPF_1_g;
  wire out_targetPc_bits_raiseIPF_1_x;
  wire out_targetPc_bits_raiseIAF_1_g;
  wire out_targetPc_bits_raiseIAF_1_x;
  wire out_targetPc_bits_raiseIGPF_1_g;
  wire out_targetPc_bits_raiseIGPF_1_x;
  TrapEntryHSEventModule u_TrapEntryHSEventModule_g (
    .valid(valid_1),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_1),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_1),
    .in_trapPc(in_trapPc_1),
    .in_trapPcGPA(in_trapPcGPA_1),
    .in_trapInst_valid(in_trapInst_valid_1),
    .in_trapInst_bits(in_trapInst_bits_1),
    .in_fetchMalTval(in_fetchMalTval_1),
    .in_isCrossPageIPF(in_isCrossPageIPF_1),
    .in_isHls(in_isHls_1),
    .in_isFetchMalAddr(in_isFetchMalAddr_1),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_1),
    .in_isFetchBkpt(in_isFetchBkpt_1),
    .in_trapIsForVSnonLeafPTE(in_trapIsForVSnonLeafPTE_1),
    .in_iMode_PRVM(in_iMode_PRVM_1),
    .in_iMode_V(in_iMode_V_1),
    .in_dMode_V(in_dMode_V_1),
    .in_privState_PRVM(in_privState_PRVM_1),
    .in_privState_V(in_privState_V_1),
    .in_hstatus_SPVP(in_hstatus_SPVP_1),
    .in_sstatus_SIE(in_sstatus_SIE_1),
    .in_menvcfg_DTE(in_menvcfg_DTE_1),
    .in_pcFromXtvec(in_pcFromXtvec_1),
    .in_satp_MODE(in_satp_MODE_1),
    .in_hgatp_MODE(in_hgatp_MODE_1),
    .in_oldSatp_MODE(in_oldSatp_MODE_1),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_1),
    .in_memExceptionVAddr(in_memExceptionVAddr_1),
    .in_memExceptionGPAddr(in_memExceptionGPAddr_1),
    .in_memExceptionIsForVSnonLeafPTE(in_memExceptionIsForVSnonLeafPTE_1),
    .out_privState_valid(out_privState_valid_1_g),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_1_g),
    .out_privState_bits_V(out_privState_bits_V_1_g),
    .out_mstatus_valid(out_mstatus_valid_1_g),
    .out_mstatus_bits_SIE(out_mstatus_bits_SIE_1_g),
    .out_mstatus_bits_MIE(out_mstatus_bits_MIE_1_g),
    .out_mstatus_bits_SPIE(out_mstatus_bits_SPIE_1_g),
    .out_mstatus_bits_UBE(out_mstatus_bits_UBE_1_g),
    .out_mstatus_bits_MPIE(out_mstatus_bits_MPIE_1_g),
    .out_mstatus_bits_SPP(out_mstatus_bits_SPP_1_g),
    .out_mstatus_bits_VS(out_mstatus_bits_VS_1_g),
    .out_mstatus_bits_MPP(out_mstatus_bits_MPP_1_g),
    .out_mstatus_bits_FS(out_mstatus_bits_FS_1_g),
    .out_mstatus_bits_XS(out_mstatus_bits_XS_1_g),
    .out_mstatus_bits_MPRV(out_mstatus_bits_MPRV_1_g),
    .out_mstatus_bits_SUM(out_mstatus_bits_SUM_1_g),
    .out_mstatus_bits_MXR(out_mstatus_bits_MXR_1_g),
    .out_mstatus_bits_TVM(out_mstatus_bits_TVM_1_g),
    .out_mstatus_bits_TW(out_mstatus_bits_TW_1_g),
    .out_mstatus_bits_TSR(out_mstatus_bits_TSR_1_g),
    .out_mstatus_bits_SDT(out_mstatus_bits_SDT_1_g),
    .out_mstatus_bits_UXL(out_mstatus_bits_UXL_1_g),
    .out_mstatus_bits_SXL(out_mstatus_bits_SXL_1_g),
    .out_mstatus_bits_SBE(out_mstatus_bits_SBE_1_g),
    .out_mstatus_bits_MBE(out_mstatus_bits_MBE_1_g),
    .out_mstatus_bits_GVA(out_mstatus_bits_GVA_1_g),
    .out_mstatus_bits_MPV(out_mstatus_bits_MPV_1_g),
    .out_mstatus_bits_MDT(out_mstatus_bits_MDT_1_g),
    .out_mstatus_bits_SD(out_mstatus_bits_SD_1_g),
    .out_hstatus_valid(out_hstatus_valid_1_g),
    .out_hstatus_bits_VSBE(out_hstatus_bits_VSBE_1_g),
    .out_hstatus_bits_GVA(out_hstatus_bits_GVA_1_g),
    .out_hstatus_bits_SPV(out_hstatus_bits_SPV_1_g),
    .out_hstatus_bits_SPVP(out_hstatus_bits_SPVP_1_g),
    .out_hstatus_bits_HU(out_hstatus_bits_HU_1_g),
    .out_hstatus_bits_VGEIN(out_hstatus_bits_VGEIN_1_g),
    .out_hstatus_bits_VTVM(out_hstatus_bits_VTVM_1_g),
    .out_hstatus_bits_VTW(out_hstatus_bits_VTW_1_g),
    .out_hstatus_bits_VTSR(out_hstatus_bits_VTSR_1_g),
    .out_hstatus_bits_VSXL(out_hstatus_bits_VSXL_1_g),
    .out_hstatus_bits_HUPMM(out_hstatus_bits_HUPMM_1_g),
    .out_sepc_valid(out_sepc_valid_1_g),
    .out_sepc_bits_epc(out_sepc_bits_epc_1_g),
    .out_scause_valid(out_scause_valid_1_g),
    .out_scause_bits_Interrupt(out_scause_bits_Interrupt_1_g),
    .out_scause_bits_ExceptionCode(out_scause_bits_ExceptionCode_1_g),
    .out_stval_valid(out_stval_valid_1_g),
    .out_stval_bits_ALL(out_stval_bits_ALL_1_g),
    .out_htval_valid(out_htval_valid_1_g),
    .out_htval_bits_ALL(out_htval_bits_ALL_1_g),
    .out_htinst_valid(out_htinst_valid_1_g),
    .out_htinst_bits_ALL(out_htinst_bits_ALL_1_g),
    .out_targetPc_valid(out_targetPc_valid_1_g),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_1_g),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_1_g),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_1_g),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_1_g)
  );
  TrapEntryHSEventModule_xs u_TrapEntryHSEventModule_x (
    .valid(valid_1),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_1),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_1),
    .in_trapPc(in_trapPc_1),
    .in_trapPcGPA(in_trapPcGPA_1),
    .in_trapInst_valid(in_trapInst_valid_1),
    .in_trapInst_bits(in_trapInst_bits_1),
    .in_fetchMalTval(in_fetchMalTval_1),
    .in_isCrossPageIPF(in_isCrossPageIPF_1),
    .in_isHls(in_isHls_1),
    .in_isFetchMalAddr(in_isFetchMalAddr_1),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_1),
    .in_isFetchBkpt(in_isFetchBkpt_1),
    .in_trapIsForVSnonLeafPTE(in_trapIsForVSnonLeafPTE_1),
    .in_iMode_PRVM(in_iMode_PRVM_1),
    .in_iMode_V(in_iMode_V_1),
    .in_dMode_V(in_dMode_V_1),
    .in_privState_PRVM(in_privState_PRVM_1),
    .in_privState_V(in_privState_V_1),
    .in_hstatus_SPVP(in_hstatus_SPVP_1),
    .in_sstatus_SIE(in_sstatus_SIE_1),
    .in_menvcfg_DTE(in_menvcfg_DTE_1),
    .in_pcFromXtvec(in_pcFromXtvec_1),
    .in_satp_MODE(in_satp_MODE_1),
    .in_hgatp_MODE(in_hgatp_MODE_1),
    .in_oldSatp_MODE(in_oldSatp_MODE_1),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_1),
    .in_memExceptionVAddr(in_memExceptionVAddr_1),
    .in_memExceptionGPAddr(in_memExceptionGPAddr_1),
    .in_memExceptionIsForVSnonLeafPTE(in_memExceptionIsForVSnonLeafPTE_1),
    .out_privState_valid(out_privState_valid_1_x),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_1_x),
    .out_privState_bits_V(out_privState_bits_V_1_x),
    .out_mstatus_valid(out_mstatus_valid_1_x),
    .out_mstatus_bits_SIE(out_mstatus_bits_SIE_1_x),
    .out_mstatus_bits_MIE(out_mstatus_bits_MIE_1_x),
    .out_mstatus_bits_SPIE(out_mstatus_bits_SPIE_1_x),
    .out_mstatus_bits_UBE(out_mstatus_bits_UBE_1_x),
    .out_mstatus_bits_MPIE(out_mstatus_bits_MPIE_1_x),
    .out_mstatus_bits_SPP(out_mstatus_bits_SPP_1_x),
    .out_mstatus_bits_VS(out_mstatus_bits_VS_1_x),
    .out_mstatus_bits_MPP(out_mstatus_bits_MPP_1_x),
    .out_mstatus_bits_FS(out_mstatus_bits_FS_1_x),
    .out_mstatus_bits_XS(out_mstatus_bits_XS_1_x),
    .out_mstatus_bits_MPRV(out_mstatus_bits_MPRV_1_x),
    .out_mstatus_bits_SUM(out_mstatus_bits_SUM_1_x),
    .out_mstatus_bits_MXR(out_mstatus_bits_MXR_1_x),
    .out_mstatus_bits_TVM(out_mstatus_bits_TVM_1_x),
    .out_mstatus_bits_TW(out_mstatus_bits_TW_1_x),
    .out_mstatus_bits_TSR(out_mstatus_bits_TSR_1_x),
    .out_mstatus_bits_SDT(out_mstatus_bits_SDT_1_x),
    .out_mstatus_bits_UXL(out_mstatus_bits_UXL_1_x),
    .out_mstatus_bits_SXL(out_mstatus_bits_SXL_1_x),
    .out_mstatus_bits_SBE(out_mstatus_bits_SBE_1_x),
    .out_mstatus_bits_MBE(out_mstatus_bits_MBE_1_x),
    .out_mstatus_bits_GVA(out_mstatus_bits_GVA_1_x),
    .out_mstatus_bits_MPV(out_mstatus_bits_MPV_1_x),
    .out_mstatus_bits_MDT(out_mstatus_bits_MDT_1_x),
    .out_mstatus_bits_SD(out_mstatus_bits_SD_1_x),
    .out_hstatus_valid(out_hstatus_valid_1_x),
    .out_hstatus_bits_VSBE(out_hstatus_bits_VSBE_1_x),
    .out_hstatus_bits_GVA(out_hstatus_bits_GVA_1_x),
    .out_hstatus_bits_SPV(out_hstatus_bits_SPV_1_x),
    .out_hstatus_bits_SPVP(out_hstatus_bits_SPVP_1_x),
    .out_hstatus_bits_HU(out_hstatus_bits_HU_1_x),
    .out_hstatus_bits_VGEIN(out_hstatus_bits_VGEIN_1_x),
    .out_hstatus_bits_VTVM(out_hstatus_bits_VTVM_1_x),
    .out_hstatus_bits_VTW(out_hstatus_bits_VTW_1_x),
    .out_hstatus_bits_VTSR(out_hstatus_bits_VTSR_1_x),
    .out_hstatus_bits_VSXL(out_hstatus_bits_VSXL_1_x),
    .out_hstatus_bits_HUPMM(out_hstatus_bits_HUPMM_1_x),
    .out_sepc_valid(out_sepc_valid_1_x),
    .out_sepc_bits_epc(out_sepc_bits_epc_1_x),
    .out_scause_valid(out_scause_valid_1_x),
    .out_scause_bits_Interrupt(out_scause_bits_Interrupt_1_x),
    .out_scause_bits_ExceptionCode(out_scause_bits_ExceptionCode_1_x),
    .out_stval_valid(out_stval_valid_1_x),
    .out_stval_bits_ALL(out_stval_bits_ALL_1_x),
    .out_htval_valid(out_htval_valid_1_x),
    .out_htval_bits_ALL(out_htval_bits_ALL_1_x),
    .out_htinst_valid(out_htinst_valid_1_x),
    .out_htinst_bits_ALL(out_htinst_bits_ALL_1_x),
    .out_targetPc_valid(out_targetPc_valid_1_x),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_1_x),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_1_x),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_1_x),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_1_x)
  );

  // TrapEntryMEventModule exact G1 port differential
  logic valid_2;
  logic in_causeNO_Interrupt_2;
  logic [62:0]in_causeNO_ExceptionCode_2;
  logic [49:0]in_trapPc_2;
  logic [55:0]in_trapPcGPA_2;
  logic in_trapInst_valid_2;
  logic [31:0]in_trapInst_bits_2;
  logic [63:0]in_fetchMalTval_2;
  logic in_isCrossPageIPF_2;
  logic in_isHls_2;
  logic in_isFetchMalAddr_2;
  logic in_satpFlushFirstFetchFault_2;
  logic in_isFetchBkpt_2;
  logic in_trapIsForVSnonLeafPTE_2;
  logic in_hasDTExcp_2;
  logic [1:0]in_iMode_PRVM_2;
  logic in_iMode_V_2;
  logic in_dMode_V_2;
  logic [1:0]in_privState_PRVM_2;
  logic in_privState_V_2;
  logic in_mstatus_MIE_2;
  logic [63:0]in_pcFromXtvec_2;
  logic [3:0]in_hgatp_MODE_2;
  logic [3:0]in_oldSatp_MODE_2;
  logic [3:0]in_oldVsatp_MODE_2;
  logic [63:0]in_memExceptionVAddr_2;
  logic [63:0]in_memExceptionGPAddr_2;
  logic in_memExceptionIsForVSnonLeafPTE_2;
  wire out_privState_valid_2_g;
  wire out_privState_valid_2_x;
  wire [1:0]out_privState_bits_PRVM_2_g;
  wire [1:0]out_privState_bits_PRVM_2_x;
  wire out_privState_bits_V_2_g;
  wire out_privState_bits_V_2_x;
  wire out_mstatus_valid_2_g;
  wire out_mstatus_valid_2_x;
  wire out_mstatus_bits_SIE_2_g;
  wire out_mstatus_bits_SIE_2_x;
  wire out_mstatus_bits_MIE_2_g;
  wire out_mstatus_bits_MIE_2_x;
  wire out_mstatus_bits_SPIE_2_g;
  wire out_mstatus_bits_SPIE_2_x;
  wire out_mstatus_bits_UBE_2_g;
  wire out_mstatus_bits_UBE_2_x;
  wire out_mstatus_bits_MPIE_2_g;
  wire out_mstatus_bits_MPIE_2_x;
  wire out_mstatus_bits_SPP_2_g;
  wire out_mstatus_bits_SPP_2_x;
  wire [1:0]out_mstatus_bits_VS_2_g;
  wire [1:0]out_mstatus_bits_VS_2_x;
  wire [1:0]out_mstatus_bits_MPP_2_g;
  wire [1:0]out_mstatus_bits_MPP_2_x;
  wire [1:0]out_mstatus_bits_FS_2_g;
  wire [1:0]out_mstatus_bits_FS_2_x;
  wire [1:0]out_mstatus_bits_XS_2_g;
  wire [1:0]out_mstatus_bits_XS_2_x;
  wire out_mstatus_bits_MPRV_2_g;
  wire out_mstatus_bits_MPRV_2_x;
  wire out_mstatus_bits_SUM_2_g;
  wire out_mstatus_bits_SUM_2_x;
  wire out_mstatus_bits_MXR_2_g;
  wire out_mstatus_bits_MXR_2_x;
  wire out_mstatus_bits_TVM_2_g;
  wire out_mstatus_bits_TVM_2_x;
  wire out_mstatus_bits_TW_2_g;
  wire out_mstatus_bits_TW_2_x;
  wire out_mstatus_bits_TSR_2_g;
  wire out_mstatus_bits_TSR_2_x;
  wire out_mstatus_bits_SDT_2_g;
  wire out_mstatus_bits_SDT_2_x;
  wire [1:0]out_mstatus_bits_UXL_2_g;
  wire [1:0]out_mstatus_bits_UXL_2_x;
  wire [1:0]out_mstatus_bits_SXL_2_g;
  wire [1:0]out_mstatus_bits_SXL_2_x;
  wire out_mstatus_bits_SBE_2_g;
  wire out_mstatus_bits_SBE_2_x;
  wire out_mstatus_bits_MBE_2_g;
  wire out_mstatus_bits_MBE_2_x;
  wire out_mstatus_bits_GVA_2_g;
  wire out_mstatus_bits_GVA_2_x;
  wire out_mstatus_bits_MPV_2_g;
  wire out_mstatus_bits_MPV_2_x;
  wire out_mstatus_bits_MDT_2_g;
  wire out_mstatus_bits_MDT_2_x;
  wire out_mstatus_bits_SD_2_g;
  wire out_mstatus_bits_SD_2_x;
  wire out_mepc_valid_2_g;
  wire out_mepc_valid_2_x;
  wire [62:0]out_mepc_bits_epc_2_g;
  wire [62:0]out_mepc_bits_epc_2_x;
  wire out_mcause_valid_2_g;
  wire out_mcause_valid_2_x;
  wire out_mcause_bits_Interrupt_2_g;
  wire out_mcause_bits_Interrupt_2_x;
  wire [62:0]out_mcause_bits_ExceptionCode_2_g;
  wire [62:0]out_mcause_bits_ExceptionCode_2_x;
  wire out_mtval_valid_2_g;
  wire out_mtval_valid_2_x;
  wire [63:0]out_mtval_bits_ALL_2_g;
  wire [63:0]out_mtval_bits_ALL_2_x;
  wire out_mtval2_valid_2_g;
  wire out_mtval2_valid_2_x;
  wire [63:0]out_mtval2_bits_ALL_2_g;
  wire [63:0]out_mtval2_bits_ALL_2_x;
  wire out_mtinst_valid_2_g;
  wire out_mtinst_valid_2_x;
  wire [63:0]out_mtinst_bits_ALL_2_g;
  wire [63:0]out_mtinst_bits_ALL_2_x;
  wire out_targetPc_valid_2_g;
  wire out_targetPc_valid_2_x;
  wire [63:0]out_targetPc_bits_pc_2_g;
  wire [63:0]out_targetPc_bits_pc_2_x;
  wire out_targetPc_bits_raiseIPF_2_g;
  wire out_targetPc_bits_raiseIPF_2_x;
  wire out_targetPc_bits_raiseIAF_2_g;
  wire out_targetPc_bits_raiseIAF_2_x;
  wire out_targetPc_bits_raiseIGPF_2_g;
  wire out_targetPc_bits_raiseIGPF_2_x;
  TrapEntryMEventModule u_TrapEntryMEventModule_g (
    .valid(valid_2),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_2),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_2),
    .in_trapPc(in_trapPc_2),
    .in_trapPcGPA(in_trapPcGPA_2),
    .in_trapInst_valid(in_trapInst_valid_2),
    .in_trapInst_bits(in_trapInst_bits_2),
    .in_fetchMalTval(in_fetchMalTval_2),
    .in_isCrossPageIPF(in_isCrossPageIPF_2),
    .in_isHls(in_isHls_2),
    .in_isFetchMalAddr(in_isFetchMalAddr_2),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_2),
    .in_isFetchBkpt(in_isFetchBkpt_2),
    .in_trapIsForVSnonLeafPTE(in_trapIsForVSnonLeafPTE_2),
    .in_hasDTExcp(in_hasDTExcp_2),
    .in_iMode_PRVM(in_iMode_PRVM_2),
    .in_iMode_V(in_iMode_V_2),
    .in_dMode_V(in_dMode_V_2),
    .in_privState_PRVM(in_privState_PRVM_2),
    .in_privState_V(in_privState_V_2),
    .in_mstatus_MIE(in_mstatus_MIE_2),
    .in_pcFromXtvec(in_pcFromXtvec_2),
    .in_hgatp_MODE(in_hgatp_MODE_2),
    .in_oldSatp_MODE(in_oldSatp_MODE_2),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_2),
    .in_memExceptionVAddr(in_memExceptionVAddr_2),
    .in_memExceptionGPAddr(in_memExceptionGPAddr_2),
    .in_memExceptionIsForVSnonLeafPTE(in_memExceptionIsForVSnonLeafPTE_2),
    .out_privState_valid(out_privState_valid_2_g),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_2_g),
    .out_privState_bits_V(out_privState_bits_V_2_g),
    .out_mstatus_valid(out_mstatus_valid_2_g),
    .out_mstatus_bits_SIE(out_mstatus_bits_SIE_2_g),
    .out_mstatus_bits_MIE(out_mstatus_bits_MIE_2_g),
    .out_mstatus_bits_SPIE(out_mstatus_bits_SPIE_2_g),
    .out_mstatus_bits_UBE(out_mstatus_bits_UBE_2_g),
    .out_mstatus_bits_MPIE(out_mstatus_bits_MPIE_2_g),
    .out_mstatus_bits_SPP(out_mstatus_bits_SPP_2_g),
    .out_mstatus_bits_VS(out_mstatus_bits_VS_2_g),
    .out_mstatus_bits_MPP(out_mstatus_bits_MPP_2_g),
    .out_mstatus_bits_FS(out_mstatus_bits_FS_2_g),
    .out_mstatus_bits_XS(out_mstatus_bits_XS_2_g),
    .out_mstatus_bits_MPRV(out_mstatus_bits_MPRV_2_g),
    .out_mstatus_bits_SUM(out_mstatus_bits_SUM_2_g),
    .out_mstatus_bits_MXR(out_mstatus_bits_MXR_2_g),
    .out_mstatus_bits_TVM(out_mstatus_bits_TVM_2_g),
    .out_mstatus_bits_TW(out_mstatus_bits_TW_2_g),
    .out_mstatus_bits_TSR(out_mstatus_bits_TSR_2_g),
    .out_mstatus_bits_SDT(out_mstatus_bits_SDT_2_g),
    .out_mstatus_bits_UXL(out_mstatus_bits_UXL_2_g),
    .out_mstatus_bits_SXL(out_mstatus_bits_SXL_2_g),
    .out_mstatus_bits_SBE(out_mstatus_bits_SBE_2_g),
    .out_mstatus_bits_MBE(out_mstatus_bits_MBE_2_g),
    .out_mstatus_bits_GVA(out_mstatus_bits_GVA_2_g),
    .out_mstatus_bits_MPV(out_mstatus_bits_MPV_2_g),
    .out_mstatus_bits_MDT(out_mstatus_bits_MDT_2_g),
    .out_mstatus_bits_SD(out_mstatus_bits_SD_2_g),
    .out_mepc_valid(out_mepc_valid_2_g),
    .out_mepc_bits_epc(out_mepc_bits_epc_2_g),
    .out_mcause_valid(out_mcause_valid_2_g),
    .out_mcause_bits_Interrupt(out_mcause_bits_Interrupt_2_g),
    .out_mcause_bits_ExceptionCode(out_mcause_bits_ExceptionCode_2_g),
    .out_mtval_valid(out_mtval_valid_2_g),
    .out_mtval_bits_ALL(out_mtval_bits_ALL_2_g),
    .out_mtval2_valid(out_mtval2_valid_2_g),
    .out_mtval2_bits_ALL(out_mtval2_bits_ALL_2_g),
    .out_mtinst_valid(out_mtinst_valid_2_g),
    .out_mtinst_bits_ALL(out_mtinst_bits_ALL_2_g),
    .out_targetPc_valid(out_targetPc_valid_2_g),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_2_g),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_2_g),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_2_g),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_2_g)
  );
  TrapEntryMEventModule_xs u_TrapEntryMEventModule_x (
    .valid(valid_2),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_2),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_2),
    .in_trapPc(in_trapPc_2),
    .in_trapPcGPA(in_trapPcGPA_2),
    .in_trapInst_valid(in_trapInst_valid_2),
    .in_trapInst_bits(in_trapInst_bits_2),
    .in_fetchMalTval(in_fetchMalTval_2),
    .in_isCrossPageIPF(in_isCrossPageIPF_2),
    .in_isHls(in_isHls_2),
    .in_isFetchMalAddr(in_isFetchMalAddr_2),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_2),
    .in_isFetchBkpt(in_isFetchBkpt_2),
    .in_trapIsForVSnonLeafPTE(in_trapIsForVSnonLeafPTE_2),
    .in_hasDTExcp(in_hasDTExcp_2),
    .in_iMode_PRVM(in_iMode_PRVM_2),
    .in_iMode_V(in_iMode_V_2),
    .in_dMode_V(in_dMode_V_2),
    .in_privState_PRVM(in_privState_PRVM_2),
    .in_privState_V(in_privState_V_2),
    .in_mstatus_MIE(in_mstatus_MIE_2),
    .in_pcFromXtvec(in_pcFromXtvec_2),
    .in_hgatp_MODE(in_hgatp_MODE_2),
    .in_oldSatp_MODE(in_oldSatp_MODE_2),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_2),
    .in_memExceptionVAddr(in_memExceptionVAddr_2),
    .in_memExceptionGPAddr(in_memExceptionGPAddr_2),
    .in_memExceptionIsForVSnonLeafPTE(in_memExceptionIsForVSnonLeafPTE_2),
    .out_privState_valid(out_privState_valid_2_x),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_2_x),
    .out_privState_bits_V(out_privState_bits_V_2_x),
    .out_mstatus_valid(out_mstatus_valid_2_x),
    .out_mstatus_bits_SIE(out_mstatus_bits_SIE_2_x),
    .out_mstatus_bits_MIE(out_mstatus_bits_MIE_2_x),
    .out_mstatus_bits_SPIE(out_mstatus_bits_SPIE_2_x),
    .out_mstatus_bits_UBE(out_mstatus_bits_UBE_2_x),
    .out_mstatus_bits_MPIE(out_mstatus_bits_MPIE_2_x),
    .out_mstatus_bits_SPP(out_mstatus_bits_SPP_2_x),
    .out_mstatus_bits_VS(out_mstatus_bits_VS_2_x),
    .out_mstatus_bits_MPP(out_mstatus_bits_MPP_2_x),
    .out_mstatus_bits_FS(out_mstatus_bits_FS_2_x),
    .out_mstatus_bits_XS(out_mstatus_bits_XS_2_x),
    .out_mstatus_bits_MPRV(out_mstatus_bits_MPRV_2_x),
    .out_mstatus_bits_SUM(out_mstatus_bits_SUM_2_x),
    .out_mstatus_bits_MXR(out_mstatus_bits_MXR_2_x),
    .out_mstatus_bits_TVM(out_mstatus_bits_TVM_2_x),
    .out_mstatus_bits_TW(out_mstatus_bits_TW_2_x),
    .out_mstatus_bits_TSR(out_mstatus_bits_TSR_2_x),
    .out_mstatus_bits_SDT(out_mstatus_bits_SDT_2_x),
    .out_mstatus_bits_UXL(out_mstatus_bits_UXL_2_x),
    .out_mstatus_bits_SXL(out_mstatus_bits_SXL_2_x),
    .out_mstatus_bits_SBE(out_mstatus_bits_SBE_2_x),
    .out_mstatus_bits_MBE(out_mstatus_bits_MBE_2_x),
    .out_mstatus_bits_GVA(out_mstatus_bits_GVA_2_x),
    .out_mstatus_bits_MPV(out_mstatus_bits_MPV_2_x),
    .out_mstatus_bits_MDT(out_mstatus_bits_MDT_2_x),
    .out_mstatus_bits_SD(out_mstatus_bits_SD_2_x),
    .out_mepc_valid(out_mepc_valid_2_x),
    .out_mepc_bits_epc(out_mepc_bits_epc_2_x),
    .out_mcause_valid(out_mcause_valid_2_x),
    .out_mcause_bits_Interrupt(out_mcause_bits_Interrupt_2_x),
    .out_mcause_bits_ExceptionCode(out_mcause_bits_ExceptionCode_2_x),
    .out_mtval_valid(out_mtval_valid_2_x),
    .out_mtval_bits_ALL(out_mtval_bits_ALL_2_x),
    .out_mtval2_valid(out_mtval2_valid_2_x),
    .out_mtval2_bits_ALL(out_mtval2_bits_ALL_2_x),
    .out_mtinst_valid(out_mtinst_valid_2_x),
    .out_mtinst_bits_ALL(out_mtinst_bits_ALL_2_x),
    .out_targetPc_valid(out_targetPc_valid_2_x),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_2_x),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_2_x),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_2_x),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_2_x)
  );

  // TrapEntryMNEventModule exact G1 port differential
  logic valid_3;
  logic in_causeNO_Interrupt_3;
  logic [62:0]in_causeNO_ExceptionCode_3;
  logic [49:0]in_trapPc_3;
  logic [63:0]in_fetchMalTval_3;
  logic in_isFetchMalAddr_3;
  logic in_satpFlushFirstFetchFault_3;
  logic [1:0]in_iMode_PRVM_3;
  logic in_iMode_V_3;
  logic [1:0]in_privState_PRVM_3;
  logic in_privState_V_3;
  logic [63:0]in_pcFromXtvec_3;
  logic [3:0]in_hgatp_MODE_3;
  logic [3:0]in_oldSatp_MODE_3;
  logic [3:0]in_oldVsatp_MODE_3;
  wire out_privState_valid_3_g;
  wire out_privState_valid_3_x;
  wire [1:0]out_privState_bits_PRVM_3_g;
  wire [1:0]out_privState_bits_PRVM_3_x;
  wire out_privState_bits_V_3_g;
  wire out_privState_bits_V_3_x;
  wire out_mnstatus_valid_3_g;
  wire out_mnstatus_valid_3_x;
  wire out_mnstatus_bits_NMIE_3_g;
  wire out_mnstatus_bits_NMIE_3_x;
  wire out_mnstatus_bits_MNPV_3_g;
  wire out_mnstatus_bits_MNPV_3_x;
  wire out_mnstatus_bits_MNPELP_3_g;
  wire out_mnstatus_bits_MNPELP_3_x;
  wire [1:0]out_mnstatus_bits_MNPP_3_g;
  wire [1:0]out_mnstatus_bits_MNPP_3_x;
  wire out_mnepc_valid_3_g;
  wire out_mnepc_valid_3_x;
  wire [62:0]out_mnepc_bits_epc_3_g;
  wire [62:0]out_mnepc_bits_epc_3_x;
  wire out_mncause_valid_3_g;
  wire out_mncause_valid_3_x;
  wire out_mncause_bits_Interrupt_3_g;
  wire out_mncause_bits_Interrupt_3_x;
  wire [62:0]out_mncause_bits_ExceptionCode_3_g;
  wire [62:0]out_mncause_bits_ExceptionCode_3_x;
  wire out_targetPc_valid_3_g;
  wire out_targetPc_valid_3_x;
  wire [63:0]out_targetPc_bits_pc_3_g;
  wire [63:0]out_targetPc_bits_pc_3_x;
  wire out_targetPc_bits_raiseIPF_3_g;
  wire out_targetPc_bits_raiseIPF_3_x;
  wire out_targetPc_bits_raiseIAF_3_g;
  wire out_targetPc_bits_raiseIAF_3_x;
  wire out_targetPc_bits_raiseIGPF_3_g;
  wire out_targetPc_bits_raiseIGPF_3_x;
  TrapEntryMNEventModule u_TrapEntryMNEventModule_g (
    .valid(valid_3),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_3),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_3),
    .in_trapPc(in_trapPc_3),
    .in_fetchMalTval(in_fetchMalTval_3),
    .in_isFetchMalAddr(in_isFetchMalAddr_3),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_3),
    .in_iMode_PRVM(in_iMode_PRVM_3),
    .in_iMode_V(in_iMode_V_3),
    .in_privState_PRVM(in_privState_PRVM_3),
    .in_privState_V(in_privState_V_3),
    .in_pcFromXtvec(in_pcFromXtvec_3),
    .in_hgatp_MODE(in_hgatp_MODE_3),
    .in_oldSatp_MODE(in_oldSatp_MODE_3),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_3),
    .out_privState_valid(out_privState_valid_3_g),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_3_g),
    .out_privState_bits_V(out_privState_bits_V_3_g),
    .out_mnstatus_valid(out_mnstatus_valid_3_g),
    .out_mnstatus_bits_NMIE(out_mnstatus_bits_NMIE_3_g),
    .out_mnstatus_bits_MNPV(out_mnstatus_bits_MNPV_3_g),
    .out_mnstatus_bits_MNPELP(out_mnstatus_bits_MNPELP_3_g),
    .out_mnstatus_bits_MNPP(out_mnstatus_bits_MNPP_3_g),
    .out_mnepc_valid(out_mnepc_valid_3_g),
    .out_mnepc_bits_epc(out_mnepc_bits_epc_3_g),
    .out_mncause_valid(out_mncause_valid_3_g),
    .out_mncause_bits_Interrupt(out_mncause_bits_Interrupt_3_g),
    .out_mncause_bits_ExceptionCode(out_mncause_bits_ExceptionCode_3_g),
    .out_targetPc_valid(out_targetPc_valid_3_g),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_3_g),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_3_g),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_3_g),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_3_g)
  );
  TrapEntryMNEventModule_xs u_TrapEntryMNEventModule_x (
    .valid(valid_3),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_3),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_3),
    .in_trapPc(in_trapPc_3),
    .in_fetchMalTval(in_fetchMalTval_3),
    .in_isFetchMalAddr(in_isFetchMalAddr_3),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_3),
    .in_iMode_PRVM(in_iMode_PRVM_3),
    .in_iMode_V(in_iMode_V_3),
    .in_privState_PRVM(in_privState_PRVM_3),
    .in_privState_V(in_privState_V_3),
    .in_pcFromXtvec(in_pcFromXtvec_3),
    .in_hgatp_MODE(in_hgatp_MODE_3),
    .in_oldSatp_MODE(in_oldSatp_MODE_3),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_3),
    .out_privState_valid(out_privState_valid_3_x),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_3_x),
    .out_privState_bits_V(out_privState_bits_V_3_x),
    .out_mnstatus_valid(out_mnstatus_valid_3_x),
    .out_mnstatus_bits_NMIE(out_mnstatus_bits_NMIE_3_x),
    .out_mnstatus_bits_MNPV(out_mnstatus_bits_MNPV_3_x),
    .out_mnstatus_bits_MNPELP(out_mnstatus_bits_MNPELP_3_x),
    .out_mnstatus_bits_MNPP(out_mnstatus_bits_MNPP_3_x),
    .out_mnepc_valid(out_mnepc_valid_3_x),
    .out_mnepc_bits_epc(out_mnepc_bits_epc_3_x),
    .out_mncause_valid(out_mncause_valid_3_x),
    .out_mncause_bits_Interrupt(out_mncause_bits_Interrupt_3_x),
    .out_mncause_bits_ExceptionCode(out_mncause_bits_ExceptionCode_3_x),
    .out_targetPc_valid(out_targetPc_valid_3_x),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_3_x),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_3_x),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_3_x),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_3_x)
  );

  // TrapEntryVSEventModule exact G1 port differential
  logic valid_4;
  logic in_causeNO_Interrupt_4;
  logic [62:0]in_causeNO_ExceptionCode_4;
  logic [49:0]in_trapPc_4;
  logic in_trapInst_valid_4;
  logic [31:0]in_trapInst_bits_4;
  logic [63:0]in_fetchMalTval_4;
  logic in_isCrossPageIPF_4;
  logic in_isFetchMalAddr_4;
  logic in_satpFlushFirstFetchFault_4;
  logic in_isFetchBkpt_4;
  logic [1:0]in_iMode_PRVM_4;
  logic in_iMode_V_4;
  logic in_dMode_V_4;
  logic [1:0]in_privState_PRVM_4;
  logic in_privState_V_4;
  logic in_vsstatus_SIE_4;
  logic in_henvcfg_DTE_4;
  logic [63:0]in_pcFromXtvec_4;
  logic [3:0]in_vsatp_MODE_4;
  logic [3:0]in_hgatp_MODE_4;
  logic [3:0]in_oldSatp_MODE_4;
  logic [3:0]in_oldVsatp_MODE_4;
  logic [63:0]in_memExceptionVAddr_4;
  logic in_virtualInterruptIsHvictlInject_4;
  logic [11:0]in_hvictlIID_4;
  wire out_privState_valid_4_g;
  wire out_privState_valid_4_x;
  wire [1:0]out_privState_bits_PRVM_4_g;
  wire [1:0]out_privState_bits_PRVM_4_x;
  wire out_privState_bits_V_4_g;
  wire out_privState_bits_V_4_x;
  wire out_vsstatus_valid_4_g;
  wire out_vsstatus_valid_4_x;
  wire out_vsstatus_bits_SIE_4_g;
  wire out_vsstatus_bits_SIE_4_x;
  wire out_vsstatus_bits_SPIE_4_g;
  wire out_vsstatus_bits_SPIE_4_x;
  wire out_vsstatus_bits_UBE_4_g;
  wire out_vsstatus_bits_UBE_4_x;
  wire out_vsstatus_bits_SPP_4_g;
  wire out_vsstatus_bits_SPP_4_x;
  wire [1:0]out_vsstatus_bits_VS_4_g;
  wire [1:0]out_vsstatus_bits_VS_4_x;
  wire [1:0]out_vsstatus_bits_FS_4_g;
  wire [1:0]out_vsstatus_bits_FS_4_x;
  wire [1:0]out_vsstatus_bits_XS_4_g;
  wire [1:0]out_vsstatus_bits_XS_4_x;
  wire out_vsstatus_bits_SUM_4_g;
  wire out_vsstatus_bits_SUM_4_x;
  wire out_vsstatus_bits_MXR_4_g;
  wire out_vsstatus_bits_MXR_4_x;
  wire out_vsstatus_bits_SDT_4_g;
  wire out_vsstatus_bits_SDT_4_x;
  wire [1:0]out_vsstatus_bits_UXL_4_g;
  wire [1:0]out_vsstatus_bits_UXL_4_x;
  wire out_vsstatus_bits_SD_4_g;
  wire out_vsstatus_bits_SD_4_x;
  wire out_vsepc_valid_4_g;
  wire out_vsepc_valid_4_x;
  wire [62:0]out_vsepc_bits_epc_4_g;
  wire [62:0]out_vsepc_bits_epc_4_x;
  wire out_vscause_valid_4_g;
  wire out_vscause_valid_4_x;
  wire out_vscause_bits_Interrupt_4_g;
  wire out_vscause_bits_Interrupt_4_x;
  wire [62:0]out_vscause_bits_ExceptionCode_4_g;
  wire [62:0]out_vscause_bits_ExceptionCode_4_x;
  wire out_vstval_valid_4_g;
  wire out_vstval_valid_4_x;
  wire [63:0]out_vstval_bits_ALL_4_g;
  wire [63:0]out_vstval_bits_ALL_4_x;
  wire out_targetPc_valid_4_g;
  wire out_targetPc_valid_4_x;
  wire [63:0]out_targetPc_bits_pc_4_g;
  wire [63:0]out_targetPc_bits_pc_4_x;
  wire out_targetPc_bits_raiseIPF_4_g;
  wire out_targetPc_bits_raiseIPF_4_x;
  wire out_targetPc_bits_raiseIAF_4_g;
  wire out_targetPc_bits_raiseIAF_4_x;
  wire out_targetPc_bits_raiseIGPF_4_g;
  wire out_targetPc_bits_raiseIGPF_4_x;
  TrapEntryVSEventModule u_TrapEntryVSEventModule_g (
    .clock(clock),
    .reset(reset),
    .valid(valid_4),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_4),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_4),
    .in_trapPc(in_trapPc_4),
    .in_trapInst_valid(in_trapInst_valid_4),
    .in_trapInst_bits(in_trapInst_bits_4),
    .in_fetchMalTval(in_fetchMalTval_4),
    .in_isCrossPageIPF(in_isCrossPageIPF_4),
    .in_isFetchMalAddr(in_isFetchMalAddr_4),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_4),
    .in_isFetchBkpt(in_isFetchBkpt_4),
    .in_iMode_PRVM(in_iMode_PRVM_4),
    .in_iMode_V(in_iMode_V_4),
    .in_dMode_V(in_dMode_V_4),
    .in_privState_PRVM(in_privState_PRVM_4),
    .in_privState_V(in_privState_V_4),
    .in_vsstatus_SIE(in_vsstatus_SIE_4),
    .in_henvcfg_DTE(in_henvcfg_DTE_4),
    .in_pcFromXtvec(in_pcFromXtvec_4),
    .in_vsatp_MODE(in_vsatp_MODE_4),
    .in_hgatp_MODE(in_hgatp_MODE_4),
    .in_oldSatp_MODE(in_oldSatp_MODE_4),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_4),
    .in_memExceptionVAddr(in_memExceptionVAddr_4),
    .in_virtualInterruptIsHvictlInject(in_virtualInterruptIsHvictlInject_4),
    .in_hvictlIID(in_hvictlIID_4),
    .out_privState_valid(out_privState_valid_4_g),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_4_g),
    .out_privState_bits_V(out_privState_bits_V_4_g),
    .out_vsstatus_valid(out_vsstatus_valid_4_g),
    .out_vsstatus_bits_SIE(out_vsstatus_bits_SIE_4_g),
    .out_vsstatus_bits_SPIE(out_vsstatus_bits_SPIE_4_g),
    .out_vsstatus_bits_UBE(out_vsstatus_bits_UBE_4_g),
    .out_vsstatus_bits_SPP(out_vsstatus_bits_SPP_4_g),
    .out_vsstatus_bits_VS(out_vsstatus_bits_VS_4_g),
    .out_vsstatus_bits_FS(out_vsstatus_bits_FS_4_g),
    .out_vsstatus_bits_XS(out_vsstatus_bits_XS_4_g),
    .out_vsstatus_bits_SUM(out_vsstatus_bits_SUM_4_g),
    .out_vsstatus_bits_MXR(out_vsstatus_bits_MXR_4_g),
    .out_vsstatus_bits_SDT(out_vsstatus_bits_SDT_4_g),
    .out_vsstatus_bits_UXL(out_vsstatus_bits_UXL_4_g),
    .out_vsstatus_bits_SD(out_vsstatus_bits_SD_4_g),
    .out_vsepc_valid(out_vsepc_valid_4_g),
    .out_vsepc_bits_epc(out_vsepc_bits_epc_4_g),
    .out_vscause_valid(out_vscause_valid_4_g),
    .out_vscause_bits_Interrupt(out_vscause_bits_Interrupt_4_g),
    .out_vscause_bits_ExceptionCode(out_vscause_bits_ExceptionCode_4_g),
    .out_vstval_valid(out_vstval_valid_4_g),
    .out_vstval_bits_ALL(out_vstval_bits_ALL_4_g),
    .out_targetPc_valid(out_targetPc_valid_4_g),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_4_g),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_4_g),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_4_g),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_4_g)
  );
  TrapEntryVSEventModule_xs u_TrapEntryVSEventModule_x (
    .clock(clock),
    .reset(reset),
    .valid(valid_4),
    .in_causeNO_Interrupt(in_causeNO_Interrupt_4),
    .in_causeNO_ExceptionCode(in_causeNO_ExceptionCode_4),
    .in_trapPc(in_trapPc_4),
    .in_trapInst_valid(in_trapInst_valid_4),
    .in_trapInst_bits(in_trapInst_bits_4),
    .in_fetchMalTval(in_fetchMalTval_4),
    .in_isCrossPageIPF(in_isCrossPageIPF_4),
    .in_isFetchMalAddr(in_isFetchMalAddr_4),
    .in_satpFlushFirstFetchFault(in_satpFlushFirstFetchFault_4),
    .in_isFetchBkpt(in_isFetchBkpt_4),
    .in_iMode_PRVM(in_iMode_PRVM_4),
    .in_iMode_V(in_iMode_V_4),
    .in_dMode_V(in_dMode_V_4),
    .in_privState_PRVM(in_privState_PRVM_4),
    .in_privState_V(in_privState_V_4),
    .in_vsstatus_SIE(in_vsstatus_SIE_4),
    .in_henvcfg_DTE(in_henvcfg_DTE_4),
    .in_pcFromXtvec(in_pcFromXtvec_4),
    .in_vsatp_MODE(in_vsatp_MODE_4),
    .in_hgatp_MODE(in_hgatp_MODE_4),
    .in_oldSatp_MODE(in_oldSatp_MODE_4),
    .in_oldVsatp_MODE(in_oldVsatp_MODE_4),
    .in_memExceptionVAddr(in_memExceptionVAddr_4),
    .in_virtualInterruptIsHvictlInject(in_virtualInterruptIsHvictlInject_4),
    .in_hvictlIID(in_hvictlIID_4),
    .out_privState_valid(out_privState_valid_4_x),
    .out_privState_bits_PRVM(out_privState_bits_PRVM_4_x),
    .out_privState_bits_V(out_privState_bits_V_4_x),
    .out_vsstatus_valid(out_vsstatus_valid_4_x),
    .out_vsstatus_bits_SIE(out_vsstatus_bits_SIE_4_x),
    .out_vsstatus_bits_SPIE(out_vsstatus_bits_SPIE_4_x),
    .out_vsstatus_bits_UBE(out_vsstatus_bits_UBE_4_x),
    .out_vsstatus_bits_SPP(out_vsstatus_bits_SPP_4_x),
    .out_vsstatus_bits_VS(out_vsstatus_bits_VS_4_x),
    .out_vsstatus_bits_FS(out_vsstatus_bits_FS_4_x),
    .out_vsstatus_bits_XS(out_vsstatus_bits_XS_4_x),
    .out_vsstatus_bits_SUM(out_vsstatus_bits_SUM_4_x),
    .out_vsstatus_bits_MXR(out_vsstatus_bits_MXR_4_x),
    .out_vsstatus_bits_SDT(out_vsstatus_bits_SDT_4_x),
    .out_vsstatus_bits_UXL(out_vsstatus_bits_UXL_4_x),
    .out_vsstatus_bits_SD(out_vsstatus_bits_SD_4_x),
    .out_vsepc_valid(out_vsepc_valid_4_x),
    .out_vsepc_bits_epc(out_vsepc_bits_epc_4_x),
    .out_vscause_valid(out_vscause_valid_4_x),
    .out_vscause_bits_Interrupt(out_vscause_bits_Interrupt_4_x),
    .out_vscause_bits_ExceptionCode(out_vscause_bits_ExceptionCode_4_x),
    .out_vstval_valid(out_vstval_valid_4_x),
    .out_vstval_bits_ALL(out_vstval_bits_ALL_4_x),
    .out_targetPc_valid(out_targetPc_valid_4_x),
    .out_targetPc_bits_pc(out_targetPc_bits_pc_4_x),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF_4_x),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF_4_x),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF_4_x)
  );

  initial begin
    reset = 1'b1;
    repeat (2) @(posedge clock);
    #0.1;
    valid_0 = '0;
    in_trapPc_0 = '0;
    in_fetchMalTval_0 = '0;
    in_isFetchMalAddr_0 = '0;
    in_satpFlushFirstFetchFault_0 = '0;
    in_iMode_PRVM_0 = '0;
    in_iMode_V_0 = '0;
    in_privState_PRVM_0 = '0;
    in_privState_V_0 = '0;
    in_hgatp_MODE_0 = '0;
    in_oldSatp_MODE_0 = '0;
    in_oldVsatp_MODE_0 = '0;
    in_hasTrap_0 = '0;
    in_debugMode_0 = '0;
    in_hasDebugIntr_0 = '0;
    in_triggerEnterDebugMode_0 = '0;
    in_hasDebugEbreakException_0 = '0;
    in_hasSingleStep_0 = '0;
    in_breakPoint_0 = '0;
    in_criticalErrorStateEnterDebug_0 = '0;
    in_holdDpc_0 = '0;
    valid_1 = '0;
    in_causeNO_Interrupt_1 = '0;
    in_causeNO_ExceptionCode_1 = '0;
    in_trapPc_1 = '0;
    in_trapPcGPA_1 = '0;
    in_trapInst_valid_1 = '0;
    in_trapInst_bits_1 = '0;
    in_fetchMalTval_1 = '0;
    in_isCrossPageIPF_1 = '0;
    in_isHls_1 = '0;
    in_isFetchMalAddr_1 = '0;
    in_satpFlushFirstFetchFault_1 = '0;
    in_isFetchBkpt_1 = '0;
    in_trapIsForVSnonLeafPTE_1 = '0;
    in_iMode_PRVM_1 = '0;
    in_iMode_V_1 = '0;
    in_dMode_V_1 = '0;
    in_privState_PRVM_1 = '0;
    in_privState_V_1 = '0;
    in_hstatus_SPVP_1 = '0;
    in_sstatus_SIE_1 = '0;
    in_menvcfg_DTE_1 = '0;
    in_pcFromXtvec_1 = '0;
    in_satp_MODE_1 = '0;
    in_hgatp_MODE_1 = '0;
    in_oldSatp_MODE_1 = '0;
    in_oldVsatp_MODE_1 = '0;
    in_memExceptionVAddr_1 = '0;
    in_memExceptionGPAddr_1 = '0;
    in_memExceptionIsForVSnonLeafPTE_1 = '0;
    valid_2 = '0;
    in_causeNO_Interrupt_2 = '0;
    in_causeNO_ExceptionCode_2 = '0;
    in_trapPc_2 = '0;
    in_trapPcGPA_2 = '0;
    in_trapInst_valid_2 = '0;
    in_trapInst_bits_2 = '0;
    in_fetchMalTval_2 = '0;
    in_isCrossPageIPF_2 = '0;
    in_isHls_2 = '0;
    in_isFetchMalAddr_2 = '0;
    in_satpFlushFirstFetchFault_2 = '0;
    in_isFetchBkpt_2 = '0;
    in_trapIsForVSnonLeafPTE_2 = '0;
    in_hasDTExcp_2 = '0;
    in_iMode_PRVM_2 = '0;
    in_iMode_V_2 = '0;
    in_dMode_V_2 = '0;
    in_privState_PRVM_2 = '0;
    in_privState_V_2 = '0;
    in_mstatus_MIE_2 = '0;
    in_pcFromXtvec_2 = '0;
    in_hgatp_MODE_2 = '0;
    in_oldSatp_MODE_2 = '0;
    in_oldVsatp_MODE_2 = '0;
    in_memExceptionVAddr_2 = '0;
    in_memExceptionGPAddr_2 = '0;
    in_memExceptionIsForVSnonLeafPTE_2 = '0;
    valid_3 = '0;
    in_causeNO_Interrupt_3 = '0;
    in_causeNO_ExceptionCode_3 = '0;
    in_trapPc_3 = '0;
    in_fetchMalTval_3 = '0;
    in_isFetchMalAddr_3 = '0;
    in_satpFlushFirstFetchFault_3 = '0;
    in_iMode_PRVM_3 = '0;
    in_iMode_V_3 = '0;
    in_privState_PRVM_3 = '0;
    in_privState_V_3 = '0;
    in_pcFromXtvec_3 = '0;
    in_hgatp_MODE_3 = '0;
    in_oldSatp_MODE_3 = '0;
    in_oldVsatp_MODE_3 = '0;
    valid_4 = '0;
    in_causeNO_Interrupt_4 = '0;
    in_causeNO_ExceptionCode_4 = '0;
    in_trapPc_4 = '0;
    in_trapInst_valid_4 = '0;
    in_trapInst_bits_4 = '0;
    in_fetchMalTval_4 = '0;
    in_isCrossPageIPF_4 = '0;
    in_isFetchMalAddr_4 = '0;
    in_satpFlushFirstFetchFault_4 = '0;
    in_isFetchBkpt_4 = '0;
    in_iMode_PRVM_4 = '0;
    in_iMode_V_4 = '0;
    in_dMode_V_4 = '0;
    in_privState_PRVM_4 = '0;
    in_privState_V_4 = '0;
    in_vsstatus_SIE_4 = '0;
    in_henvcfg_DTE_4 = '0;
    in_pcFromXtvec_4 = '0;
    in_vsatp_MODE_4 = '0;
    in_hgatp_MODE_4 = '0;
    in_oldSatp_MODE_4 = '0;
    in_oldVsatp_MODE_4 = '0;
    in_memExceptionVAddr_4 = '0;
    in_virtualInterruptIsHvictlInject_4 = '0;
    in_hvictlIID_4 = '0;
    reset = 1'b0;
    repeat (2) @(posedge clock);
    for (cycles = 0; cycles < ncycles; cycles = cycles + 1) begin
      @(negedge clock);
      valid_0 = {$urandom, $urandom};
      in_trapPc_0 = {$urandom, $urandom};
      in_fetchMalTval_0 = {$urandom, $urandom};
      in_isFetchMalAddr_0 = {$urandom, $urandom};
      in_satpFlushFirstFetchFault_0 = {$urandom, $urandom};
      in_iMode_PRVM_0 = {$urandom, $urandom};
      in_iMode_V_0 = {$urandom, $urandom};
      in_privState_PRVM_0 = {$urandom, $urandom};
      in_privState_V_0 = {$urandom, $urandom};
      in_hgatp_MODE_0 = {$urandom, $urandom};
      in_oldSatp_MODE_0 = {$urandom, $urandom};
      in_oldVsatp_MODE_0 = {$urandom, $urandom};
      in_hasTrap_0 = {$urandom, $urandom};
      in_debugMode_0 = {$urandom, $urandom};
      in_hasDebugIntr_0 = {$urandom, $urandom};
      in_triggerEnterDebugMode_0 = {$urandom, $urandom};
      in_hasDebugEbreakException_0 = {$urandom, $urandom};
      in_hasSingleStep_0 = {$urandom, $urandom};
      in_breakPoint_0 = {$urandom, $urandom};
      in_criticalErrorStateEnterDebug_0 = {$urandom, $urandom};
      in_holdDpc_0 = {$urandom, $urandom};
      valid_1 = {$urandom, $urandom};
      in_causeNO_Interrupt_1 = {$urandom, $urandom};
      in_causeNO_ExceptionCode_1 = {$urandom, $urandom};
      in_trapPc_1 = {$urandom, $urandom};
      in_trapPcGPA_1 = {$urandom, $urandom};
      in_trapInst_valid_1 = {$urandom, $urandom};
      in_trapInst_bits_1 = {$urandom, $urandom};
      in_fetchMalTval_1 = {$urandom, $urandom};
      in_isCrossPageIPF_1 = {$urandom, $urandom};
      in_isHls_1 = {$urandom, $urandom};
      in_isFetchMalAddr_1 = {$urandom, $urandom};
      in_satpFlushFirstFetchFault_1 = {$urandom, $urandom};
      in_isFetchBkpt_1 = {$urandom, $urandom};
      in_trapIsForVSnonLeafPTE_1 = {$urandom, $urandom};
      in_iMode_PRVM_1 = {$urandom, $urandom};
      in_iMode_V_1 = {$urandom, $urandom};
      in_dMode_V_1 = {$urandom, $urandom};
      in_privState_PRVM_1 = {$urandom, $urandom};
      in_privState_V_1 = {$urandom, $urandom};
      in_hstatus_SPVP_1 = {$urandom, $urandom};
      in_sstatus_SIE_1 = {$urandom, $urandom};
      in_menvcfg_DTE_1 = {$urandom, $urandom};
      in_pcFromXtvec_1 = {$urandom, $urandom};
      in_satp_MODE_1 = {$urandom, $urandom};
      in_hgatp_MODE_1 = {$urandom, $urandom};
      in_oldSatp_MODE_1 = {$urandom, $urandom};
      in_oldVsatp_MODE_1 = {$urandom, $urandom};
      in_memExceptionVAddr_1 = {$urandom, $urandom};
      in_memExceptionGPAddr_1 = {$urandom, $urandom};
      in_memExceptionIsForVSnonLeafPTE_1 = {$urandom, $urandom};
      valid_2 = {$urandom, $urandom};
      in_causeNO_Interrupt_2 = {$urandom, $urandom};
      in_causeNO_ExceptionCode_2 = {$urandom, $urandom};
      in_trapPc_2 = {$urandom, $urandom};
      in_trapPcGPA_2 = {$urandom, $urandom};
      in_trapInst_valid_2 = {$urandom, $urandom};
      in_trapInst_bits_2 = {$urandom, $urandom};
      in_fetchMalTval_2 = {$urandom, $urandom};
      in_isCrossPageIPF_2 = {$urandom, $urandom};
      in_isHls_2 = {$urandom, $urandom};
      in_isFetchMalAddr_2 = {$urandom, $urandom};
      in_satpFlushFirstFetchFault_2 = {$urandom, $urandom};
      in_isFetchBkpt_2 = {$urandom, $urandom};
      in_trapIsForVSnonLeafPTE_2 = {$urandom, $urandom};
      in_hasDTExcp_2 = {$urandom, $urandom};
      in_iMode_PRVM_2 = {$urandom, $urandom};
      in_iMode_V_2 = {$urandom, $urandom};
      in_dMode_V_2 = {$urandom, $urandom};
      in_privState_PRVM_2 = {$urandom, $urandom};
      in_privState_V_2 = {$urandom, $urandom};
      in_mstatus_MIE_2 = {$urandom, $urandom};
      in_pcFromXtvec_2 = {$urandom, $urandom};
      in_hgatp_MODE_2 = {$urandom, $urandom};
      in_oldSatp_MODE_2 = {$urandom, $urandom};
      in_oldVsatp_MODE_2 = {$urandom, $urandom};
      in_memExceptionVAddr_2 = {$urandom, $urandom};
      in_memExceptionGPAddr_2 = {$urandom, $urandom};
      in_memExceptionIsForVSnonLeafPTE_2 = {$urandom, $urandom};
      valid_3 = {$urandom, $urandom};
      in_causeNO_Interrupt_3 = {$urandom, $urandom};
      in_causeNO_ExceptionCode_3 = {$urandom, $urandom};
      in_trapPc_3 = {$urandom, $urandom};
      in_fetchMalTval_3 = {$urandom, $urandom};
      in_isFetchMalAddr_3 = {$urandom, $urandom};
      in_satpFlushFirstFetchFault_3 = {$urandom, $urandom};
      in_iMode_PRVM_3 = {$urandom, $urandom};
      in_iMode_V_3 = {$urandom, $urandom};
      in_privState_PRVM_3 = {$urandom, $urandom};
      in_privState_V_3 = {$urandom, $urandom};
      in_pcFromXtvec_3 = {$urandom, $urandom};
      in_hgatp_MODE_3 = {$urandom, $urandom};
      in_oldSatp_MODE_3 = {$urandom, $urandom};
      in_oldVsatp_MODE_3 = {$urandom, $urandom};
      valid_4 = {$urandom, $urandom};
      in_causeNO_Interrupt_4 = {$urandom, $urandom};
      in_causeNO_ExceptionCode_4 = {$urandom, $urandom};
      in_trapPc_4 = {$urandom, $urandom};
      in_trapInst_valid_4 = {$urandom, $urandom};
      in_trapInst_bits_4 = {$urandom, $urandom};
      in_fetchMalTval_4 = {$urandom, $urandom};
      in_isCrossPageIPF_4 = {$urandom, $urandom};
      in_isFetchMalAddr_4 = {$urandom, $urandom};
      in_satpFlushFirstFetchFault_4 = {$urandom, $urandom};
      in_isFetchBkpt_4 = {$urandom, $urandom};
      in_iMode_PRVM_4 = {$urandom, $urandom};
      in_iMode_V_4 = {$urandom, $urandom};
      in_dMode_V_4 = {$urandom, $urandom};
      in_privState_PRVM_4 = {$urandom, $urandom};
      in_privState_V_4 = {$urandom, $urandom};
      in_vsstatus_SIE_4 = {$urandom, $urandom};
      in_henvcfg_DTE_4 = {$urandom, $urandom};
      in_pcFromXtvec_4 = {$urandom, $urandom};
      in_vsatp_MODE_4 = {$urandom, $urandom};
      in_hgatp_MODE_4 = {$urandom, $urandom};
      in_oldSatp_MODE_4 = {$urandom, $urandom};
      in_oldVsatp_MODE_4 = {$urandom, $urandom};
      in_memExceptionVAddr_4 = {$urandom, $urandom};
      in_virtualInterruptIsHvictlInject_4 = {$urandom, $urandom};
      in_hvictlIID_4 = {$urandom, $urandom};
      @(posedge clock);
      #0.1;
      checks = checks + 1;
      if ({out_privState_valid_0_g, out_privState_bits_PRVM_0_g, out_privState_bits_V_0_g, out_dcsr_valid_0_g, out_dcsr_bits_DEBUGVER_0_g, out_dcsr_bits_EXTCAUSE_0_g, out_dcsr_bits_CETRIG_0_g, out_dcsr_bits_EBREAKVS_0_g, out_dcsr_bits_EBREAKVU_0_g, out_dcsr_bits_EBREAKM_0_g, out_dcsr_bits_EBREAKS_0_g, out_dcsr_bits_EBREAKU_0_g, out_dcsr_bits_STEPIE_0_g, out_dcsr_bits_STOPCOUNT_0_g, out_dcsr_bits_STOPTIME_0_g, out_dcsr_bits_CAUSE_0_g, out_dcsr_bits_V_0_g, out_dcsr_bits_MPRVEN_0_g, out_dcsr_bits_NMIP_0_g, out_dcsr_bits_STEP_0_g, out_dcsr_bits_PRV_0_g, out_dpc_valid_0_g, out_dpc_bits_epc_0_g, out_targetPc_valid_0_g, out_targetPc_bits_pc_0_g, out_targetPc_bits_raiseIPF_0_g, out_targetPc_bits_raiseIAF_0_g, out_targetPc_bits_raiseIGPF_0_g, out_debugMode_valid_0_g, out_debugMode_bits_0_g, out_debugIntrEnable_valid_0_g, out_debugIntrEnable_bits_0_g} !== {out_privState_valid_0_x, out_privState_bits_PRVM_0_x, out_privState_bits_V_0_x, out_dcsr_valid_0_x, out_dcsr_bits_DEBUGVER_0_x, out_dcsr_bits_EXTCAUSE_0_x, out_dcsr_bits_CETRIG_0_x, out_dcsr_bits_EBREAKVS_0_x, out_dcsr_bits_EBREAKVU_0_x, out_dcsr_bits_EBREAKM_0_x, out_dcsr_bits_EBREAKS_0_x, out_dcsr_bits_EBREAKU_0_x, out_dcsr_bits_STEPIE_0_x, out_dcsr_bits_STOPCOUNT_0_x, out_dcsr_bits_STOPTIME_0_x, out_dcsr_bits_CAUSE_0_x, out_dcsr_bits_V_0_x, out_dcsr_bits_MPRVEN_0_x, out_dcsr_bits_NMIP_0_x, out_dcsr_bits_STEP_0_x, out_dcsr_bits_PRV_0_x, out_dpc_valid_0_x, out_dpc_bits_epc_0_x, out_targetPc_valid_0_x, out_targetPc_bits_pc_0_x, out_targetPc_bits_raiseIPF_0_x, out_targetPc_bits_raiseIAF_0_x, out_targetPc_bits_raiseIGPF_0_x, out_debugMode_valid_0_x, out_debugMode_bits_0_x, out_debugIntrEnable_valid_0_x, out_debugIntrEnable_bits_0_x}) begin
        errors = errors + 1; $display("FAIL TrapEntryDEventModule cycle=%0d", cycles);
      end
      if ({out_privState_valid_1_g, out_privState_bits_PRVM_1_g, out_privState_bits_V_1_g, out_mstatus_valid_1_g, out_mstatus_bits_SIE_1_g, out_mstatus_bits_MIE_1_g, out_mstatus_bits_SPIE_1_g, out_mstatus_bits_UBE_1_g, out_mstatus_bits_MPIE_1_g, out_mstatus_bits_SPP_1_g, out_mstatus_bits_VS_1_g, out_mstatus_bits_MPP_1_g, out_mstatus_bits_FS_1_g, out_mstatus_bits_XS_1_g, out_mstatus_bits_MPRV_1_g, out_mstatus_bits_SUM_1_g, out_mstatus_bits_MXR_1_g, out_mstatus_bits_TVM_1_g, out_mstatus_bits_TW_1_g, out_mstatus_bits_TSR_1_g, out_mstatus_bits_SDT_1_g, out_mstatus_bits_UXL_1_g, out_mstatus_bits_SXL_1_g, out_mstatus_bits_SBE_1_g, out_mstatus_bits_MBE_1_g, out_mstatus_bits_GVA_1_g, out_mstatus_bits_MPV_1_g, out_mstatus_bits_MDT_1_g, out_mstatus_bits_SD_1_g, out_hstatus_valid_1_g, out_hstatus_bits_VSBE_1_g, out_hstatus_bits_GVA_1_g, out_hstatus_bits_SPV_1_g, out_hstatus_bits_SPVP_1_g, out_hstatus_bits_HU_1_g, out_hstatus_bits_VGEIN_1_g, out_hstatus_bits_VTVM_1_g, out_hstatus_bits_VTW_1_g, out_hstatus_bits_VTSR_1_g, out_hstatus_bits_VSXL_1_g, out_hstatus_bits_HUPMM_1_g, out_sepc_valid_1_g, out_sepc_bits_epc_1_g, out_scause_valid_1_g, out_scause_bits_Interrupt_1_g, out_scause_bits_ExceptionCode_1_g, out_stval_valid_1_g, out_stval_bits_ALL_1_g, out_htval_valid_1_g, out_htval_bits_ALL_1_g, out_htinst_valid_1_g, out_htinst_bits_ALL_1_g, out_targetPc_valid_1_g, out_targetPc_bits_pc_1_g, out_targetPc_bits_raiseIPF_1_g, out_targetPc_bits_raiseIAF_1_g, out_targetPc_bits_raiseIGPF_1_g} !== {out_privState_valid_1_x, out_privState_bits_PRVM_1_x, out_privState_bits_V_1_x, out_mstatus_valid_1_x, out_mstatus_bits_SIE_1_x, out_mstatus_bits_MIE_1_x, out_mstatus_bits_SPIE_1_x, out_mstatus_bits_UBE_1_x, out_mstatus_bits_MPIE_1_x, out_mstatus_bits_SPP_1_x, out_mstatus_bits_VS_1_x, out_mstatus_bits_MPP_1_x, out_mstatus_bits_FS_1_x, out_mstatus_bits_XS_1_x, out_mstatus_bits_MPRV_1_x, out_mstatus_bits_SUM_1_x, out_mstatus_bits_MXR_1_x, out_mstatus_bits_TVM_1_x, out_mstatus_bits_TW_1_x, out_mstatus_bits_TSR_1_x, out_mstatus_bits_SDT_1_x, out_mstatus_bits_UXL_1_x, out_mstatus_bits_SXL_1_x, out_mstatus_bits_SBE_1_x, out_mstatus_bits_MBE_1_x, out_mstatus_bits_GVA_1_x, out_mstatus_bits_MPV_1_x, out_mstatus_bits_MDT_1_x, out_mstatus_bits_SD_1_x, out_hstatus_valid_1_x, out_hstatus_bits_VSBE_1_x, out_hstatus_bits_GVA_1_x, out_hstatus_bits_SPV_1_x, out_hstatus_bits_SPVP_1_x, out_hstatus_bits_HU_1_x, out_hstatus_bits_VGEIN_1_x, out_hstatus_bits_VTVM_1_x, out_hstatus_bits_VTW_1_x, out_hstatus_bits_VTSR_1_x, out_hstatus_bits_VSXL_1_x, out_hstatus_bits_HUPMM_1_x, out_sepc_valid_1_x, out_sepc_bits_epc_1_x, out_scause_valid_1_x, out_scause_bits_Interrupt_1_x, out_scause_bits_ExceptionCode_1_x, out_stval_valid_1_x, out_stval_bits_ALL_1_x, out_htval_valid_1_x, out_htval_bits_ALL_1_x, out_htinst_valid_1_x, out_htinst_bits_ALL_1_x, out_targetPc_valid_1_x, out_targetPc_bits_pc_1_x, out_targetPc_bits_raiseIPF_1_x, out_targetPc_bits_raiseIAF_1_x, out_targetPc_bits_raiseIGPF_1_x}) begin
        errors = errors + 1; $display("FAIL TrapEntryHSEventModule cycle=%0d", cycles);
      end
      if ({out_privState_valid_2_g, out_privState_bits_PRVM_2_g, out_privState_bits_V_2_g, out_mstatus_valid_2_g, out_mstatus_bits_SIE_2_g, out_mstatus_bits_MIE_2_g, out_mstatus_bits_SPIE_2_g, out_mstatus_bits_UBE_2_g, out_mstatus_bits_MPIE_2_g, out_mstatus_bits_SPP_2_g, out_mstatus_bits_VS_2_g, out_mstatus_bits_MPP_2_g, out_mstatus_bits_FS_2_g, out_mstatus_bits_XS_2_g, out_mstatus_bits_MPRV_2_g, out_mstatus_bits_SUM_2_g, out_mstatus_bits_MXR_2_g, out_mstatus_bits_TVM_2_g, out_mstatus_bits_TW_2_g, out_mstatus_bits_TSR_2_g, out_mstatus_bits_SDT_2_g, out_mstatus_bits_UXL_2_g, out_mstatus_bits_SXL_2_g, out_mstatus_bits_SBE_2_g, out_mstatus_bits_MBE_2_g, out_mstatus_bits_GVA_2_g, out_mstatus_bits_MPV_2_g, out_mstatus_bits_MDT_2_g, out_mstatus_bits_SD_2_g, out_mepc_valid_2_g, out_mepc_bits_epc_2_g, out_mcause_valid_2_g, out_mcause_bits_Interrupt_2_g, out_mcause_bits_ExceptionCode_2_g, out_mtval_valid_2_g, out_mtval_bits_ALL_2_g, out_mtval2_valid_2_g, out_mtval2_bits_ALL_2_g, out_mtinst_valid_2_g, out_mtinst_bits_ALL_2_g, out_targetPc_valid_2_g, out_targetPc_bits_pc_2_g, out_targetPc_bits_raiseIPF_2_g, out_targetPc_bits_raiseIAF_2_g, out_targetPc_bits_raiseIGPF_2_g} !== {out_privState_valid_2_x, out_privState_bits_PRVM_2_x, out_privState_bits_V_2_x, out_mstatus_valid_2_x, out_mstatus_bits_SIE_2_x, out_mstatus_bits_MIE_2_x, out_mstatus_bits_SPIE_2_x, out_mstatus_bits_UBE_2_x, out_mstatus_bits_MPIE_2_x, out_mstatus_bits_SPP_2_x, out_mstatus_bits_VS_2_x, out_mstatus_bits_MPP_2_x, out_mstatus_bits_FS_2_x, out_mstatus_bits_XS_2_x, out_mstatus_bits_MPRV_2_x, out_mstatus_bits_SUM_2_x, out_mstatus_bits_MXR_2_x, out_mstatus_bits_TVM_2_x, out_mstatus_bits_TW_2_x, out_mstatus_bits_TSR_2_x, out_mstatus_bits_SDT_2_x, out_mstatus_bits_UXL_2_x, out_mstatus_bits_SXL_2_x, out_mstatus_bits_SBE_2_x, out_mstatus_bits_MBE_2_x, out_mstatus_bits_GVA_2_x, out_mstatus_bits_MPV_2_x, out_mstatus_bits_MDT_2_x, out_mstatus_bits_SD_2_x, out_mepc_valid_2_x, out_mepc_bits_epc_2_x, out_mcause_valid_2_x, out_mcause_bits_Interrupt_2_x, out_mcause_bits_ExceptionCode_2_x, out_mtval_valid_2_x, out_mtval_bits_ALL_2_x, out_mtval2_valid_2_x, out_mtval2_bits_ALL_2_x, out_mtinst_valid_2_x, out_mtinst_bits_ALL_2_x, out_targetPc_valid_2_x, out_targetPc_bits_pc_2_x, out_targetPc_bits_raiseIPF_2_x, out_targetPc_bits_raiseIAF_2_x, out_targetPc_bits_raiseIGPF_2_x}) begin
        errors = errors + 1; $display("FAIL TrapEntryMEventModule cycle=%0d", cycles);
      end
      if ({out_privState_valid_3_g, out_privState_bits_PRVM_3_g, out_privState_bits_V_3_g, out_mnstatus_valid_3_g, out_mnstatus_bits_NMIE_3_g, out_mnstatus_bits_MNPV_3_g, out_mnstatus_bits_MNPELP_3_g, out_mnstatus_bits_MNPP_3_g, out_mnepc_valid_3_g, out_mnepc_bits_epc_3_g, out_mncause_valid_3_g, out_mncause_bits_Interrupt_3_g, out_mncause_bits_ExceptionCode_3_g, out_targetPc_valid_3_g, out_targetPc_bits_pc_3_g, out_targetPc_bits_raiseIPF_3_g, out_targetPc_bits_raiseIAF_3_g, out_targetPc_bits_raiseIGPF_3_g} !== {out_privState_valid_3_x, out_privState_bits_PRVM_3_x, out_privState_bits_V_3_x, out_mnstatus_valid_3_x, out_mnstatus_bits_NMIE_3_x, out_mnstatus_bits_MNPV_3_x, out_mnstatus_bits_MNPELP_3_x, out_mnstatus_bits_MNPP_3_x, out_mnepc_valid_3_x, out_mnepc_bits_epc_3_x, out_mncause_valid_3_x, out_mncause_bits_Interrupt_3_x, out_mncause_bits_ExceptionCode_3_x, out_targetPc_valid_3_x, out_targetPc_bits_pc_3_x, out_targetPc_bits_raiseIPF_3_x, out_targetPc_bits_raiseIAF_3_x, out_targetPc_bits_raiseIGPF_3_x}) begin
        errors = errors + 1; $display("FAIL TrapEntryMNEventModule cycle=%0d", cycles);
      end
      if ({out_privState_valid_4_g, out_privState_bits_PRVM_4_g, out_privState_bits_V_4_g, out_vsstatus_valid_4_g, out_vsstatus_bits_SIE_4_g, out_vsstatus_bits_SPIE_4_g, out_vsstatus_bits_UBE_4_g, out_vsstatus_bits_SPP_4_g, out_vsstatus_bits_VS_4_g, out_vsstatus_bits_FS_4_g, out_vsstatus_bits_XS_4_g, out_vsstatus_bits_SUM_4_g, out_vsstatus_bits_MXR_4_g, out_vsstatus_bits_SDT_4_g, out_vsstatus_bits_UXL_4_g, out_vsstatus_bits_SD_4_g, out_vsepc_valid_4_g, out_vsepc_bits_epc_4_g, out_vscause_valid_4_g, out_vscause_bits_Interrupt_4_g, out_vscause_bits_ExceptionCode_4_g, out_vstval_valid_4_g, out_vstval_bits_ALL_4_g, out_targetPc_valid_4_g, out_targetPc_bits_pc_4_g, out_targetPc_bits_raiseIPF_4_g, out_targetPc_bits_raiseIAF_4_g, out_targetPc_bits_raiseIGPF_4_g} !== {out_privState_valid_4_x, out_privState_bits_PRVM_4_x, out_privState_bits_V_4_x, out_vsstatus_valid_4_x, out_vsstatus_bits_SIE_4_x, out_vsstatus_bits_SPIE_4_x, out_vsstatus_bits_UBE_4_x, out_vsstatus_bits_SPP_4_x, out_vsstatus_bits_VS_4_x, out_vsstatus_bits_FS_4_x, out_vsstatus_bits_XS_4_x, out_vsstatus_bits_SUM_4_x, out_vsstatus_bits_MXR_4_x, out_vsstatus_bits_SDT_4_x, out_vsstatus_bits_UXL_4_x, out_vsstatus_bits_SD_4_x, out_vsepc_valid_4_x, out_vsepc_bits_epc_4_x, out_vscause_valid_4_x, out_vscause_bits_Interrupt_4_x, out_vscause_bits_ExceptionCode_4_x, out_vstval_valid_4_x, out_vstval_bits_ALL_4_x, out_targetPc_valid_4_x, out_targetPc_bits_pc_4_x, out_targetPc_bits_raiseIPF_4_x, out_targetPc_bits_raiseIAF_4_x, out_targetPc_bits_raiseIGPF_4_x}) begin
        errors = errors + 1; $display("FAIL TrapEntryVSEventModule cycle=%0d", cycles);
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=%0d cycles=%0d", checks, errors, cycles);
    else $display("TEST FAILED checks=%0d errors=%0d cycles=%0d", checks, errors, cycles);
    $finish;
  end
endmodule
