`timescale 1ns/1ps
module tb;
  bit clock=0;
  always #5 clock=~clock;
  integer checks=0, errors=0;
  integer cycle;
  integer ncycles;

  // DpcModule
  logic DpcModule_reset;
  logic DpcModule_w_wen;
  logic [63:0] DpcModule_w_wdata;
  wire [63:0] DpcModule_g_rdata, DpcModule_i_rdata;
  wire [62:0] DpcModule_g_regOut_epc, DpcModule_i_regOut_epc;
  logic DpcModule_trapToD_dpc_valid;
  logic [62:0] DpcModule_trapToD_dpc_bits_epc;

  // DretEventModule
  logic DretEventModule_valid;
  logic DretEventModule_in_dcsr_V;
  logic [1:0] DretEventModule_in_dcsr_PRV;
  logic [62:0] DretEventModule_in_dpc_epc;
  logic DretEventModule_in_mstatus_MPRV;
  logic DretEventModule_in_mstatus_SDT;
  logic DretEventModule_in_mstatus_MDT;
  logic DretEventModule_in_vsstatus_SDT;
  logic [3:0] DretEventModule_in_satp_MODE;
  logic [3:0] DretEventModule_in_vsatp_MODE;
  logic [3:0] DretEventModule_in_hgatp_MODE;
  wire DretEventModule_g_out_privState_valid, DretEventModule_i_out_privState_valid;
  wire [1:0] DretEventModule_g_out_privState_bits_PRVM, DretEventModule_i_out_privState_bits_PRVM;
  wire DretEventModule_g_out_privState_bits_V, DretEventModule_i_out_privState_bits_V;
  wire DretEventModule_g_out_dcsr_valid, DretEventModule_i_out_dcsr_valid;
  wire [3:0] DretEventModule_g_out_dcsr_bits_DEBUGVER, DretEventModule_i_out_dcsr_bits_DEBUGVER;
  wire [2:0] DretEventModule_g_out_dcsr_bits_EXTCAUSE, DretEventModule_i_out_dcsr_bits_EXTCAUSE;
  wire DretEventModule_g_out_dcsr_bits_CETRIG, DretEventModule_i_out_dcsr_bits_CETRIG;
  wire DretEventModule_g_out_dcsr_bits_EBREAKVS, DretEventModule_i_out_dcsr_bits_EBREAKVS;
  wire DretEventModule_g_out_dcsr_bits_EBREAKVU, DretEventModule_i_out_dcsr_bits_EBREAKVU;
  wire DretEventModule_g_out_dcsr_bits_EBREAKM, DretEventModule_i_out_dcsr_bits_EBREAKM;
  wire DretEventModule_g_out_dcsr_bits_EBREAKS, DretEventModule_i_out_dcsr_bits_EBREAKS;
  wire DretEventModule_g_out_dcsr_bits_EBREAKU, DretEventModule_i_out_dcsr_bits_EBREAKU;
  wire DretEventModule_g_out_dcsr_bits_STEPIE, DretEventModule_i_out_dcsr_bits_STEPIE;
  wire DretEventModule_g_out_dcsr_bits_STOPCOUNT, DretEventModule_i_out_dcsr_bits_STOPCOUNT;
  wire DretEventModule_g_out_dcsr_bits_STOPTIME, DretEventModule_i_out_dcsr_bits_STOPTIME;
  wire [2:0] DretEventModule_g_out_dcsr_bits_CAUSE, DretEventModule_i_out_dcsr_bits_CAUSE;
  wire DretEventModule_g_out_dcsr_bits_V, DretEventModule_i_out_dcsr_bits_V;
  wire DretEventModule_g_out_dcsr_bits_MPRVEN, DretEventModule_i_out_dcsr_bits_MPRVEN;
  wire DretEventModule_g_out_dcsr_bits_NMIP, DretEventModule_i_out_dcsr_bits_NMIP;
  wire DretEventModule_g_out_dcsr_bits_STEP, DretEventModule_i_out_dcsr_bits_STEP;
  wire [1:0] DretEventModule_g_out_dcsr_bits_PRV, DretEventModule_i_out_dcsr_bits_PRV;
  wire DretEventModule_g_out_mstatus_valid, DretEventModule_i_out_mstatus_valid;
  wire DretEventModule_g_out_mstatus_bits_SIE, DretEventModule_i_out_mstatus_bits_SIE;
  wire DretEventModule_g_out_mstatus_bits_MIE, DretEventModule_i_out_mstatus_bits_MIE;
  wire DretEventModule_g_out_mstatus_bits_SPIE, DretEventModule_i_out_mstatus_bits_SPIE;
  wire DretEventModule_g_out_mstatus_bits_UBE, DretEventModule_i_out_mstatus_bits_UBE;
  wire DretEventModule_g_out_mstatus_bits_MPIE, DretEventModule_i_out_mstatus_bits_MPIE;
  wire DretEventModule_g_out_mstatus_bits_SPP, DretEventModule_i_out_mstatus_bits_SPP;
  wire [1:0] DretEventModule_g_out_mstatus_bits_VS, DretEventModule_i_out_mstatus_bits_VS;
  wire [1:0] DretEventModule_g_out_mstatus_bits_MPP, DretEventModule_i_out_mstatus_bits_MPP;
  wire [1:0] DretEventModule_g_out_mstatus_bits_FS, DretEventModule_i_out_mstatus_bits_FS;
  wire [1:0] DretEventModule_g_out_mstatus_bits_XS, DretEventModule_i_out_mstatus_bits_XS;
  wire DretEventModule_g_out_mstatus_bits_MPRV, DretEventModule_i_out_mstatus_bits_MPRV;
  wire DretEventModule_g_out_mstatus_bits_SUM, DretEventModule_i_out_mstatus_bits_SUM;
  wire DretEventModule_g_out_mstatus_bits_MXR, DretEventModule_i_out_mstatus_bits_MXR;
  wire DretEventModule_g_out_mstatus_bits_TVM, DretEventModule_i_out_mstatus_bits_TVM;
  wire DretEventModule_g_out_mstatus_bits_TW, DretEventModule_i_out_mstatus_bits_TW;
  wire DretEventModule_g_out_mstatus_bits_TSR, DretEventModule_i_out_mstatus_bits_TSR;
  wire DretEventModule_g_out_mstatus_bits_SDT, DretEventModule_i_out_mstatus_bits_SDT;
  wire [1:0] DretEventModule_g_out_mstatus_bits_UXL, DretEventModule_i_out_mstatus_bits_UXL;
  wire [1:0] DretEventModule_g_out_mstatus_bits_SXL, DretEventModule_i_out_mstatus_bits_SXL;
  wire DretEventModule_g_out_mstatus_bits_SBE, DretEventModule_i_out_mstatus_bits_SBE;
  wire DretEventModule_g_out_mstatus_bits_MBE, DretEventModule_i_out_mstatus_bits_MBE;
  wire DretEventModule_g_out_mstatus_bits_GVA, DretEventModule_i_out_mstatus_bits_GVA;
  wire DretEventModule_g_out_mstatus_bits_MPV, DretEventModule_i_out_mstatus_bits_MPV;
  wire DretEventModule_g_out_mstatus_bits_MDT, DretEventModule_i_out_mstatus_bits_MDT;
  wire DretEventModule_g_out_mstatus_bits_SD, DretEventModule_i_out_mstatus_bits_SD;
  wire DretEventModule_g_out_vsstatus_valid, DretEventModule_i_out_vsstatus_valid;
  wire DretEventModule_g_out_vsstatus_bits_SIE, DretEventModule_i_out_vsstatus_bits_SIE;
  wire DretEventModule_g_out_vsstatus_bits_SPIE, DretEventModule_i_out_vsstatus_bits_SPIE;
  wire DretEventModule_g_out_vsstatus_bits_UBE, DretEventModule_i_out_vsstatus_bits_UBE;
  wire DretEventModule_g_out_vsstatus_bits_SPP, DretEventModule_i_out_vsstatus_bits_SPP;
  wire [1:0] DretEventModule_g_out_vsstatus_bits_VS, DretEventModule_i_out_vsstatus_bits_VS;
  wire [1:0] DretEventModule_g_out_vsstatus_bits_FS, DretEventModule_i_out_vsstatus_bits_FS;
  wire [1:0] DretEventModule_g_out_vsstatus_bits_XS, DretEventModule_i_out_vsstatus_bits_XS;
  wire DretEventModule_g_out_vsstatus_bits_SUM, DretEventModule_i_out_vsstatus_bits_SUM;
  wire DretEventModule_g_out_vsstatus_bits_MXR, DretEventModule_i_out_vsstatus_bits_MXR;
  wire DretEventModule_g_out_vsstatus_bits_SDT, DretEventModule_i_out_vsstatus_bits_SDT;
  wire [1:0] DretEventModule_g_out_vsstatus_bits_UXL, DretEventModule_i_out_vsstatus_bits_UXL;
  wire DretEventModule_g_out_vsstatus_bits_SD, DretEventModule_i_out_vsstatus_bits_SD;
  wire DretEventModule_g_out_debugMode_valid, DretEventModule_i_out_debugMode_valid;
  wire DretEventModule_g_out_debugMode_bits, DretEventModule_i_out_debugMode_bits;
  wire DretEventModule_g_out_debugIntrEnable_valid, DretEventModule_i_out_debugIntrEnable_valid;
  wire DretEventModule_g_out_debugIntrEnable_bits, DretEventModule_i_out_debugIntrEnable_bits;
  wire DretEventModule_g_out_targetPc_valid, DretEventModule_i_out_targetPc_valid;
  wire [63:0] DretEventModule_g_out_targetPc_bits_pc, DretEventModule_i_out_targetPc_bits_pc;
  wire DretEventModule_g_out_targetPc_bits_raiseIPF, DretEventModule_i_out_targetPc_bits_raiseIPF;
  wire DretEventModule_g_out_targetPc_bits_raiseIAF, DretEventModule_i_out_targetPc_bits_raiseIAF;
  wire DretEventModule_g_out_targetPc_bits_raiseIGPF, DretEventModule_i_out_targetPc_bits_raiseIGPF;

  // HcounterenModule
  logic HcounterenModule_reset;
  logic HcounterenModule_w_wen;
  logic [63:0] HcounterenModule_w_wdata;
  wire [63:0] HcounterenModule_g_rdata, HcounterenModule_i_rdata;
  wire HcounterenModule_g_regOut_CY, HcounterenModule_i_regOut_CY;
  wire HcounterenModule_g_regOut_TM, HcounterenModule_i_regOut_TM;
  wire HcounterenModule_g_regOut_IR, HcounterenModule_i_regOut_IR;
  wire [28:0] HcounterenModule_g_regOut_HPM, HcounterenModule_i_regOut_HPM;

  // HedelegModule
  logic HedelegModule_reset;
  logic HedelegModule_w_wen;
  logic [63:0] HedelegModule_w_wdata;
  wire [63:0] HedelegModule_g_rdata, HedelegModule_i_rdata;
  wire HedelegModule_g_regOut_EX_IAM, HedelegModule_i_regOut_EX_IAM;
  wire HedelegModule_g_regOut_EX_IAF, HedelegModule_i_regOut_EX_IAF;
  wire HedelegModule_g_regOut_EX_II, HedelegModule_i_regOut_EX_II;
  wire HedelegModule_g_regOut_EX_BP, HedelegModule_i_regOut_EX_BP;
  wire HedelegModule_g_regOut_EX_LAM, HedelegModule_i_regOut_EX_LAM;
  wire HedelegModule_g_regOut_EX_LAF, HedelegModule_i_regOut_EX_LAF;
  wire HedelegModule_g_regOut_EX_SAM, HedelegModule_i_regOut_EX_SAM;
  wire HedelegModule_g_regOut_EX_SAF, HedelegModule_i_regOut_EX_SAF;
  wire HedelegModule_g_regOut_EX_UCALL, HedelegModule_i_regOut_EX_UCALL;
  wire HedelegModule_g_regOut_EX_IPF, HedelegModule_i_regOut_EX_IPF;
  wire HedelegModule_g_regOut_EX_LPF, HedelegModule_i_regOut_EX_LPF;
  wire HedelegModule_g_regOut_EX_SPF, HedelegModule_i_regOut_EX_SPF;
  wire HedelegModule_g_regOut_EX_SWC, HedelegModule_i_regOut_EX_SWC;
  wire HedelegModule_g_regOut_EX_HWE, HedelegModule_i_regOut_EX_HWE;

  // HenvcfgModule
  logic HenvcfgModule_reset;
  logic HenvcfgModule_w_wen;
  logic [63:0] HenvcfgModule_w_wdata;
  wire [63:0] HenvcfgModule_g_rdata, HenvcfgModule_i_rdata;
  wire HenvcfgModule_g_regOut_STCE, HenvcfgModule_i_regOut_STCE;
  wire HenvcfgModule_g_regOut_PBMTE, HenvcfgModule_i_regOut_PBMTE;
  wire HenvcfgModule_g_regOut_DTE, HenvcfgModule_i_regOut_DTE;
  wire [1:0] HenvcfgModule_g_regOut_PMM, HenvcfgModule_i_regOut_PMM;
  wire HenvcfgModule_g_regOut_CBZE, HenvcfgModule_i_regOut_CBZE;
  wire HenvcfgModule_g_regOut_CBCFE, HenvcfgModule_i_regOut_CBCFE;
  wire [1:0] HenvcfgModule_g_regOut_CBIE, HenvcfgModule_i_regOut_CBIE;
  logic HenvcfgModule_menvcfg_STCE;
  logic HenvcfgModule_menvcfg_PBMTE;
  logic HenvcfgModule_menvcfg_DTE;

  // HgatpModule
  logic HgatpModule_reset;
  logic HgatpModule_w_wen;
  logic [63:0] HgatpModule_w_wdata;
  wire [63:0] HgatpModule_g_rdata, HgatpModule_i_rdata;
  wire [3:0] HgatpModule_g_regOut_MODE, HgatpModule_i_regOut_MODE;
  wire [13:0] HgatpModule_g_regOut_VMID, HgatpModule_i_regOut_VMID;
  wire [43:0] HgatpModule_g_regOut_PPN, HgatpModule_i_regOut_PPN;

  // HidelegModule
  logic HidelegModule_reset;
  logic HidelegModule_w_wen;
  logic [63:0] HidelegModule_w_wdata;
  wire [63:0] HidelegModule_g_rdata, HidelegModule_i_rdata;
  wire HidelegModule_g_regOut_SSI, HidelegModule_i_regOut_SSI;
  wire HidelegModule_g_regOut_VSSI, HidelegModule_i_regOut_VSSI;
  wire HidelegModule_g_regOut_MSI, HidelegModule_i_regOut_MSI;
  wire HidelegModule_g_regOut_STI, HidelegModule_i_regOut_STI;
  wire HidelegModule_g_regOut_VSTI, HidelegModule_i_regOut_VSTI;
  wire HidelegModule_g_regOut_MTI, HidelegModule_i_regOut_MTI;
  wire HidelegModule_g_regOut_SEI, HidelegModule_i_regOut_SEI;
  wire HidelegModule_g_regOut_VSEI, HidelegModule_i_regOut_VSEI;
  wire HidelegModule_g_regOut_MEI, HidelegModule_i_regOut_MEI;
  wire HidelegModule_g_regOut_SGEI, HidelegModule_i_regOut_SGEI;
  wire HidelegModule_g_regOut_LCOFI, HidelegModule_i_regOut_LCOFI;
  logic HidelegModule_mideleg_SSI;
  logic HidelegModule_mideleg_STI;
  logic HidelegModule_mideleg_SEI;
  logic HidelegModule_mideleg_LCOFI;

  // Hstateen0Module
  logic Hstateen0Module_reset;
  logic Hstateen0Module_w_wen;
  logic [63:0] Hstateen0Module_w_wdata;
  wire [63:0] Hstateen0Module_g_rdata, Hstateen0Module_i_rdata;
  wire Hstateen0Module_g_regOut_JVT, Hstateen0Module_i_regOut_JVT;
  wire Hstateen0Module_g_regOut_FCSR, Hstateen0Module_i_regOut_FCSR;
  wire Hstateen0Module_g_regOut_C, Hstateen0Module_i_regOut_C;
  wire Hstateen0Module_g_regOut_SE0, Hstateen0Module_i_regOut_SE0;
  wire Hstateen0Module_g_regOut_ENVCFG, Hstateen0Module_i_regOut_ENVCFG;
  wire Hstateen0Module_g_regOut_CSRIND, Hstateen0Module_i_regOut_CSRIND;
  wire Hstateen0Module_g_regOut_AIA, Hstateen0Module_i_regOut_AIA;
  wire Hstateen0Module_g_regOut_IMSIC, Hstateen0Module_i_regOut_IMSIC;
  wire Hstateen0Module_g_regOut_CONTEXT, Hstateen0Module_i_regOut_CONTEXT;
  logic Hstateen0Module_fromMstateen0_SE0;
  logic Hstateen0Module_fromMstateen0_ENVCFG;
  logic Hstateen0Module_fromMstateen0_CSRIND;
  logic Hstateen0Module_fromMstateen0_AIA;
  logic Hstateen0Module_fromMstateen0_IMSIC;
  logic Hstateen0Module_fromMstateen0_CONTEXT;
  logic Hstateen0Module_fromMstateen0_C;

  // Hstateen1Module
  logic Hstateen1Module_w_wen;
  logic [63:0] Hstateen1Module_w_wdata;
  wire [63:0] Hstateen1Module_g_rdata, Hstateen1Module_i_rdata;
  wire Hstateen1Module_g_regOut_SE, Hstateen1Module_i_regOut_SE;
  logic Hstateen1Module_fromMstateen1_SE;

  // Hstateen2Module
  logic Hstateen2Module_w_wen;
  logic [63:0] Hstateen2Module_w_wdata;
  wire [63:0] Hstateen2Module_g_rdata, Hstateen2Module_i_rdata;
  wire Hstateen2Module_g_regOut_SE, Hstateen2Module_i_regOut_SE;
  logic Hstateen2Module_fromMstateen2_SE;

  // Hstateen3Module
  logic Hstateen3Module_w_wen;
  logic [63:0] Hstateen3Module_w_wdata;
  wire [63:0] Hstateen3Module_g_rdata, Hstateen3Module_i_rdata;
  wire Hstateen3Module_g_regOut_SE, Hstateen3Module_i_regOut_SE;
  logic Hstateen3Module_fromMstateen3_SE;

  // HstatusModule
  logic HstatusModule_reset;
  logic HstatusModule_w_wen;
  logic [63:0] HstatusModule_w_wdata;
  wire [63:0] HstatusModule_g_rdata, HstatusModule_i_rdata;
  wire HstatusModule_g_regOut_GVA, HstatusModule_i_regOut_GVA;
  wire HstatusModule_g_regOut_SPV, HstatusModule_i_regOut_SPV;
  wire HstatusModule_g_regOut_SPVP, HstatusModule_i_regOut_SPVP;
  wire HstatusModule_g_regOut_HU, HstatusModule_i_regOut_HU;
  wire [5:0] HstatusModule_g_regOut_VGEIN, HstatusModule_i_regOut_VGEIN;
  wire HstatusModule_g_regOut_VTVM, HstatusModule_i_regOut_VTVM;
  wire HstatusModule_g_regOut_VTW, HstatusModule_i_regOut_VTW;
  wire HstatusModule_g_regOut_VTSR, HstatusModule_i_regOut_VTSR;
  wire [1:0] HstatusModule_g_regOut_HUPMM, HstatusModule_i_regOut_HUPMM;
  logic HstatusModule_retFromS_hstatus_valid;
  logic HstatusModule_retFromS_hstatus_bits_SPV;
  logic HstatusModule_trapToHS_hstatus_valid;
  logic HstatusModule_trapToHS_hstatus_bits_GVA;
  logic HstatusModule_trapToHS_hstatus_bits_SPV;
  logic HstatusModule_trapToHS_hstatus_bits_SPVP;

  // HtimedeltaModule
  logic HtimedeltaModule_reset;
  logic HtimedeltaModule_w_wen;
  logic [63:0] HtimedeltaModule_w_wdata;
  wire [63:0] HtimedeltaModule_g_rdata, HtimedeltaModule_i_rdata;
  wire [63:0] HtimedeltaModule_g_regOut_ALL, HtimedeltaModule_i_regOut_ALL;

  // HtinstModule
  logic HtinstModule_reset;
  logic HtinstModule_w_wen;
  logic [63:0] HtinstModule_w_wdata;
  wire [63:0] HtinstModule_g_rdata, HtinstModule_i_rdata;
  wire [63:0] HtinstModule_g_regOut_ALL, HtinstModule_i_regOut_ALL;
  logic HtinstModule_trapToHS_htinst_valid;
  logic [63:0] HtinstModule_trapToHS_htinst_bits_ALL;

  // HtvalModule
  logic HtvalModule_reset;
  logic HtvalModule_w_wen;
  logic [63:0] HtvalModule_w_wdata;
  wire [63:0] HtvalModule_g_rdata, HtvalModule_i_rdata;
  wire [63:0] HtvalModule_g_regOut_ALL, HtvalModule_i_regOut_ALL;
  logic HtvalModule_trapToHS_htval_valid;
  logic [63:0] HtvalModule_trapToHS_htval_bits_ALL;

  // HvictlModule
  logic HvictlModule_reset;
  logic HvictlModule_w_wen;
  logic [63:0] HvictlModule_w_wdata;
  wire [63:0] HvictlModule_g_rdata, HvictlModule_i_rdata;
  wire HvictlModule_g_regOut_VTI, HvictlModule_i_regOut_VTI;
  wire [11:0] HvictlModule_g_regOut_IID, HvictlModule_i_regOut_IID;
  wire HvictlModule_g_regOut_DPR, HvictlModule_i_regOut_DPR;
  wire HvictlModule_g_regOut_IPRIOM, HvictlModule_i_regOut_IPRIOM;
  wire [7:0] HvictlModule_g_regOut_IPRIO, HvictlModule_i_regOut_IPRIO;

  // Hviprio1Module
  logic Hviprio1Module_reset;
  logic Hviprio1Module_w_wen;
  logic [63:0] Hviprio1Module_w_wdata;
  wire [63:0] Hviprio1Module_g_rdata, Hviprio1Module_i_rdata;
  wire [7:0] Hviprio1Module_g_regOut_PrioSSI, Hviprio1Module_i_regOut_PrioSSI;
  wire [7:0] Hviprio1Module_g_regOut_PrioSTI, Hviprio1Module_i_regOut_PrioSTI;
  wire [7:0] Hviprio1Module_g_regOut_PrioCOI, Hviprio1Module_i_regOut_PrioCOI;
  wire [7:0] Hviprio1Module_g_regOut_Prio14, Hviprio1Module_i_regOut_Prio14;
  wire [7:0] Hviprio1Module_g_regOut_Prio15, Hviprio1Module_i_regOut_Prio15;

  // Hviprio2Module
  logic Hviprio2Module_reset;
  logic Hviprio2Module_w_wen;
  logic [63:0] Hviprio2Module_w_wdata;
  wire [63:0] Hviprio2Module_g_rdata, Hviprio2Module_i_rdata;
  wire [63:0] Hviprio2Module_g_regOut_ALL, Hviprio2Module_i_regOut_ALL;

  DpcModule u_DpcModule_g (
    .clock(clock),
    .reset(DpcModule_reset),
    .w_wen(DpcModule_w_wen),
    .w_wdata(DpcModule_w_wdata),
    .rdata(DpcModule_g_rdata),
    .regOut_epc(DpcModule_g_regOut_epc),
    .trapToD_dpc_valid(DpcModule_trapToD_dpc_valid),
    .trapToD_dpc_bits_epc(DpcModule_trapToD_dpc_bits_epc)
  );
  DpcModule_xs u_DpcModule_i (
    .clock(clock),
    .reset(DpcModule_reset),
    .w_wen(DpcModule_w_wen),
    .w_wdata(DpcModule_w_wdata),
    .rdata(DpcModule_i_rdata),
    .regOut_epc(DpcModule_i_regOut_epc),
    .trapToD_dpc_valid(DpcModule_trapToD_dpc_valid),
    .trapToD_dpc_bits_epc(DpcModule_trapToD_dpc_bits_epc)
  );

  DretEventModule u_DretEventModule_g (
    .valid(DretEventModule_valid),
    .in_dcsr_V(DretEventModule_in_dcsr_V),
    .in_dcsr_PRV(DretEventModule_in_dcsr_PRV),
    .in_dpc_epc(DretEventModule_in_dpc_epc),
    .in_mstatus_MPRV(DretEventModule_in_mstatus_MPRV),
    .in_mstatus_SDT(DretEventModule_in_mstatus_SDT),
    .in_mstatus_MDT(DretEventModule_in_mstatus_MDT),
    .in_vsstatus_SDT(DretEventModule_in_vsstatus_SDT),
    .in_satp_MODE(DretEventModule_in_satp_MODE),
    .in_vsatp_MODE(DretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(DretEventModule_in_hgatp_MODE),
    .out_privState_valid(DretEventModule_g_out_privState_valid),
    .out_privState_bits_PRVM(DretEventModule_g_out_privState_bits_PRVM),
    .out_privState_bits_V(DretEventModule_g_out_privState_bits_V),
    .out_dcsr_valid(DretEventModule_g_out_dcsr_valid),
    .out_dcsr_bits_DEBUGVER(DretEventModule_g_out_dcsr_bits_DEBUGVER),
    .out_dcsr_bits_EXTCAUSE(DretEventModule_g_out_dcsr_bits_EXTCAUSE),
    .out_dcsr_bits_CETRIG(DretEventModule_g_out_dcsr_bits_CETRIG),
    .out_dcsr_bits_EBREAKVS(DretEventModule_g_out_dcsr_bits_EBREAKVS),
    .out_dcsr_bits_EBREAKVU(DretEventModule_g_out_dcsr_bits_EBREAKVU),
    .out_dcsr_bits_EBREAKM(DretEventModule_g_out_dcsr_bits_EBREAKM),
    .out_dcsr_bits_EBREAKS(DretEventModule_g_out_dcsr_bits_EBREAKS),
    .out_dcsr_bits_EBREAKU(DretEventModule_g_out_dcsr_bits_EBREAKU),
    .out_dcsr_bits_STEPIE(DretEventModule_g_out_dcsr_bits_STEPIE),
    .out_dcsr_bits_STOPCOUNT(DretEventModule_g_out_dcsr_bits_STOPCOUNT),
    .out_dcsr_bits_STOPTIME(DretEventModule_g_out_dcsr_bits_STOPTIME),
    .out_dcsr_bits_CAUSE(DretEventModule_g_out_dcsr_bits_CAUSE),
    .out_dcsr_bits_V(DretEventModule_g_out_dcsr_bits_V),
    .out_dcsr_bits_MPRVEN(DretEventModule_g_out_dcsr_bits_MPRVEN),
    .out_dcsr_bits_NMIP(DretEventModule_g_out_dcsr_bits_NMIP),
    .out_dcsr_bits_STEP(DretEventModule_g_out_dcsr_bits_STEP),
    .out_dcsr_bits_PRV(DretEventModule_g_out_dcsr_bits_PRV),
    .out_mstatus_valid(DretEventModule_g_out_mstatus_valid),
    .out_mstatus_bits_SIE(DretEventModule_g_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(DretEventModule_g_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(DretEventModule_g_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(DretEventModule_g_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(DretEventModule_g_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(DretEventModule_g_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(DretEventModule_g_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(DretEventModule_g_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(DretEventModule_g_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(DretEventModule_g_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(DretEventModule_g_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(DretEventModule_g_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(DretEventModule_g_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(DretEventModule_g_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(DretEventModule_g_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(DretEventModule_g_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(DretEventModule_g_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(DretEventModule_g_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(DretEventModule_g_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(DretEventModule_g_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(DretEventModule_g_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(DretEventModule_g_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(DretEventModule_g_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(DretEventModule_g_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(DretEventModule_g_out_mstatus_bits_SD),
    .out_vsstatus_valid(DretEventModule_g_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(DretEventModule_g_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(DretEventModule_g_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(DretEventModule_g_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(DretEventModule_g_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(DretEventModule_g_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(DretEventModule_g_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(DretEventModule_g_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(DretEventModule_g_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(DretEventModule_g_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(DretEventModule_g_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(DretEventModule_g_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(DretEventModule_g_out_vsstatus_bits_SD),
    .out_debugMode_valid(DretEventModule_g_out_debugMode_valid),
    .out_debugMode_bits(DretEventModule_g_out_debugMode_bits),
    .out_debugIntrEnable_valid(DretEventModule_g_out_debugIntrEnable_valid),
    .out_debugIntrEnable_bits(DretEventModule_g_out_debugIntrEnable_bits),
    .out_targetPc_valid(DretEventModule_g_out_targetPc_valid),
    .out_targetPc_bits_pc(DretEventModule_g_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(DretEventModule_g_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(DretEventModule_g_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(DretEventModule_g_out_targetPc_bits_raiseIGPF)
  );
  DretEventModule_xs u_DretEventModule_i (
    .valid(DretEventModule_valid),
    .in_dcsr_V(DretEventModule_in_dcsr_V),
    .in_dcsr_PRV(DretEventModule_in_dcsr_PRV),
    .in_dpc_epc(DretEventModule_in_dpc_epc),
    .in_mstatus_MPRV(DretEventModule_in_mstatus_MPRV),
    .in_mstatus_SDT(DretEventModule_in_mstatus_SDT),
    .in_mstatus_MDT(DretEventModule_in_mstatus_MDT),
    .in_vsstatus_SDT(DretEventModule_in_vsstatus_SDT),
    .in_satp_MODE(DretEventModule_in_satp_MODE),
    .in_vsatp_MODE(DretEventModule_in_vsatp_MODE),
    .in_hgatp_MODE(DretEventModule_in_hgatp_MODE),
    .out_privState_valid(DretEventModule_i_out_privState_valid),
    .out_privState_bits_PRVM(DretEventModule_i_out_privState_bits_PRVM),
    .out_privState_bits_V(DretEventModule_i_out_privState_bits_V),
    .out_dcsr_valid(DretEventModule_i_out_dcsr_valid),
    .out_dcsr_bits_DEBUGVER(DretEventModule_i_out_dcsr_bits_DEBUGVER),
    .out_dcsr_bits_EXTCAUSE(DretEventModule_i_out_dcsr_bits_EXTCAUSE),
    .out_dcsr_bits_CETRIG(DretEventModule_i_out_dcsr_bits_CETRIG),
    .out_dcsr_bits_EBREAKVS(DretEventModule_i_out_dcsr_bits_EBREAKVS),
    .out_dcsr_bits_EBREAKVU(DretEventModule_i_out_dcsr_bits_EBREAKVU),
    .out_dcsr_bits_EBREAKM(DretEventModule_i_out_dcsr_bits_EBREAKM),
    .out_dcsr_bits_EBREAKS(DretEventModule_i_out_dcsr_bits_EBREAKS),
    .out_dcsr_bits_EBREAKU(DretEventModule_i_out_dcsr_bits_EBREAKU),
    .out_dcsr_bits_STEPIE(DretEventModule_i_out_dcsr_bits_STEPIE),
    .out_dcsr_bits_STOPCOUNT(DretEventModule_i_out_dcsr_bits_STOPCOUNT),
    .out_dcsr_bits_STOPTIME(DretEventModule_i_out_dcsr_bits_STOPTIME),
    .out_dcsr_bits_CAUSE(DretEventModule_i_out_dcsr_bits_CAUSE),
    .out_dcsr_bits_V(DretEventModule_i_out_dcsr_bits_V),
    .out_dcsr_bits_MPRVEN(DretEventModule_i_out_dcsr_bits_MPRVEN),
    .out_dcsr_bits_NMIP(DretEventModule_i_out_dcsr_bits_NMIP),
    .out_dcsr_bits_STEP(DretEventModule_i_out_dcsr_bits_STEP),
    .out_dcsr_bits_PRV(DretEventModule_i_out_dcsr_bits_PRV),
    .out_mstatus_valid(DretEventModule_i_out_mstatus_valid),
    .out_mstatus_bits_SIE(DretEventModule_i_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(DretEventModule_i_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(DretEventModule_i_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(DretEventModule_i_out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(DretEventModule_i_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(DretEventModule_i_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(DretEventModule_i_out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(DretEventModule_i_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(DretEventModule_i_out_mstatus_bits_FS),
    .out_mstatus_bits_XS(DretEventModule_i_out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(DretEventModule_i_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(DretEventModule_i_out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(DretEventModule_i_out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(DretEventModule_i_out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(DretEventModule_i_out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(DretEventModule_i_out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(DretEventModule_i_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(DretEventModule_i_out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(DretEventModule_i_out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(DretEventModule_i_out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(DretEventModule_i_out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(DretEventModule_i_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(DretEventModule_i_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(DretEventModule_i_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(DretEventModule_i_out_mstatus_bits_SD),
    .out_vsstatus_valid(DretEventModule_i_out_vsstatus_valid),
    .out_vsstatus_bits_SIE(DretEventModule_i_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(DretEventModule_i_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(DretEventModule_i_out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(DretEventModule_i_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(DretEventModule_i_out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(DretEventModule_i_out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(DretEventModule_i_out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(DretEventModule_i_out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(DretEventModule_i_out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(DretEventModule_i_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(DretEventModule_i_out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(DretEventModule_i_out_vsstatus_bits_SD),
    .out_debugMode_valid(DretEventModule_i_out_debugMode_valid),
    .out_debugMode_bits(DretEventModule_i_out_debugMode_bits),
    .out_debugIntrEnable_valid(DretEventModule_i_out_debugIntrEnable_valid),
    .out_debugIntrEnable_bits(DretEventModule_i_out_debugIntrEnable_bits),
    .out_targetPc_valid(DretEventModule_i_out_targetPc_valid),
    .out_targetPc_bits_pc(DretEventModule_i_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(DretEventModule_i_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(DretEventModule_i_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(DretEventModule_i_out_targetPc_bits_raiseIGPF)
  );

  HcounterenModule u_HcounterenModule_g (
    .clock(clock),
    .reset(HcounterenModule_reset),
    .w_wen(HcounterenModule_w_wen),
    .w_wdata(HcounterenModule_w_wdata),
    .rdata(HcounterenModule_g_rdata),
    .regOut_CY(HcounterenModule_g_regOut_CY),
    .regOut_TM(HcounterenModule_g_regOut_TM),
    .regOut_IR(HcounterenModule_g_regOut_IR),
    .regOut_HPM(HcounterenModule_g_regOut_HPM)
  );
  HcounterenModule_xs u_HcounterenModule_i (
    .clock(clock),
    .reset(HcounterenModule_reset),
    .w_wen(HcounterenModule_w_wen),
    .w_wdata(HcounterenModule_w_wdata),
    .rdata(HcounterenModule_i_rdata),
    .regOut_CY(HcounterenModule_i_regOut_CY),
    .regOut_TM(HcounterenModule_i_regOut_TM),
    .regOut_IR(HcounterenModule_i_regOut_IR),
    .regOut_HPM(HcounterenModule_i_regOut_HPM)
  );

  HedelegModule u_HedelegModule_g (
    .clock(clock),
    .reset(HedelegModule_reset),
    .w_wen(HedelegModule_w_wen),
    .w_wdata(HedelegModule_w_wdata),
    .rdata(HedelegModule_g_rdata),
    .regOut_EX_IAM(HedelegModule_g_regOut_EX_IAM),
    .regOut_EX_IAF(HedelegModule_g_regOut_EX_IAF),
    .regOut_EX_II(HedelegModule_g_regOut_EX_II),
    .regOut_EX_BP(HedelegModule_g_regOut_EX_BP),
    .regOut_EX_LAM(HedelegModule_g_regOut_EX_LAM),
    .regOut_EX_LAF(HedelegModule_g_regOut_EX_LAF),
    .regOut_EX_SAM(HedelegModule_g_regOut_EX_SAM),
    .regOut_EX_SAF(HedelegModule_g_regOut_EX_SAF),
    .regOut_EX_UCALL(HedelegModule_g_regOut_EX_UCALL),
    .regOut_EX_IPF(HedelegModule_g_regOut_EX_IPF),
    .regOut_EX_LPF(HedelegModule_g_regOut_EX_LPF),
    .regOut_EX_SPF(HedelegModule_g_regOut_EX_SPF),
    .regOut_EX_SWC(HedelegModule_g_regOut_EX_SWC),
    .regOut_EX_HWE(HedelegModule_g_regOut_EX_HWE)
  );
  HedelegModule_xs u_HedelegModule_i (
    .clock(clock),
    .reset(HedelegModule_reset),
    .w_wen(HedelegModule_w_wen),
    .w_wdata(HedelegModule_w_wdata),
    .rdata(HedelegModule_i_rdata),
    .regOut_EX_IAM(HedelegModule_i_regOut_EX_IAM),
    .regOut_EX_IAF(HedelegModule_i_regOut_EX_IAF),
    .regOut_EX_II(HedelegModule_i_regOut_EX_II),
    .regOut_EX_BP(HedelegModule_i_regOut_EX_BP),
    .regOut_EX_LAM(HedelegModule_i_regOut_EX_LAM),
    .regOut_EX_LAF(HedelegModule_i_regOut_EX_LAF),
    .regOut_EX_SAM(HedelegModule_i_regOut_EX_SAM),
    .regOut_EX_SAF(HedelegModule_i_regOut_EX_SAF),
    .regOut_EX_UCALL(HedelegModule_i_regOut_EX_UCALL),
    .regOut_EX_IPF(HedelegModule_i_regOut_EX_IPF),
    .regOut_EX_LPF(HedelegModule_i_regOut_EX_LPF),
    .regOut_EX_SPF(HedelegModule_i_regOut_EX_SPF),
    .regOut_EX_SWC(HedelegModule_i_regOut_EX_SWC),
    .regOut_EX_HWE(HedelegModule_i_regOut_EX_HWE)
  );

  HenvcfgModule u_HenvcfgModule_g (
    .clock(clock),
    .reset(HenvcfgModule_reset),
    .w_wen(HenvcfgModule_w_wen),
    .w_wdata(HenvcfgModule_w_wdata),
    .rdata(HenvcfgModule_g_rdata),
    .regOut_STCE(HenvcfgModule_g_regOut_STCE),
    .regOut_PBMTE(HenvcfgModule_g_regOut_PBMTE),
    .regOut_DTE(HenvcfgModule_g_regOut_DTE),
    .regOut_PMM(HenvcfgModule_g_regOut_PMM),
    .regOut_CBZE(HenvcfgModule_g_regOut_CBZE),
    .regOut_CBCFE(HenvcfgModule_g_regOut_CBCFE),
    .regOut_CBIE(HenvcfgModule_g_regOut_CBIE),
    .menvcfg_STCE(HenvcfgModule_menvcfg_STCE),
    .menvcfg_PBMTE(HenvcfgModule_menvcfg_PBMTE),
    .menvcfg_DTE(HenvcfgModule_menvcfg_DTE)
  );
  HenvcfgModule_xs u_HenvcfgModule_i (
    .clock(clock),
    .reset(HenvcfgModule_reset),
    .w_wen(HenvcfgModule_w_wen),
    .w_wdata(HenvcfgModule_w_wdata),
    .rdata(HenvcfgModule_i_rdata),
    .regOut_STCE(HenvcfgModule_i_regOut_STCE),
    .regOut_PBMTE(HenvcfgModule_i_regOut_PBMTE),
    .regOut_DTE(HenvcfgModule_i_regOut_DTE),
    .regOut_PMM(HenvcfgModule_i_regOut_PMM),
    .regOut_CBZE(HenvcfgModule_i_regOut_CBZE),
    .regOut_CBCFE(HenvcfgModule_i_regOut_CBCFE),
    .regOut_CBIE(HenvcfgModule_i_regOut_CBIE),
    .menvcfg_STCE(HenvcfgModule_menvcfg_STCE),
    .menvcfg_PBMTE(HenvcfgModule_menvcfg_PBMTE),
    .menvcfg_DTE(HenvcfgModule_menvcfg_DTE)
  );

  HgatpModule u_HgatpModule_g (
    .clock(clock),
    .reset(HgatpModule_reset),
    .w_wen(HgatpModule_w_wen),
    .w_wdata(HgatpModule_w_wdata),
    .rdata(HgatpModule_g_rdata),
    .regOut_MODE(HgatpModule_g_regOut_MODE),
    .regOut_VMID(HgatpModule_g_regOut_VMID),
    .regOut_PPN(HgatpModule_g_regOut_PPN)
  );
  HgatpModule_xs u_HgatpModule_i (
    .clock(clock),
    .reset(HgatpModule_reset),
    .w_wen(HgatpModule_w_wen),
    .w_wdata(HgatpModule_w_wdata),
    .rdata(HgatpModule_i_rdata),
    .regOut_MODE(HgatpModule_i_regOut_MODE),
    .regOut_VMID(HgatpModule_i_regOut_VMID),
    .regOut_PPN(HgatpModule_i_regOut_PPN)
  );

  HidelegModule u_HidelegModule_g (
    .clock(clock),
    .reset(HidelegModule_reset),
    .w_wen(HidelegModule_w_wen),
    .w_wdata(HidelegModule_w_wdata),
    .rdata(HidelegModule_g_rdata),
    .regOut_SSI(HidelegModule_g_regOut_SSI),
    .regOut_VSSI(HidelegModule_g_regOut_VSSI),
    .regOut_MSI(HidelegModule_g_regOut_MSI),
    .regOut_STI(HidelegModule_g_regOut_STI),
    .regOut_VSTI(HidelegModule_g_regOut_VSTI),
    .regOut_MTI(HidelegModule_g_regOut_MTI),
    .regOut_SEI(HidelegModule_g_regOut_SEI),
    .regOut_VSEI(HidelegModule_g_regOut_VSEI),
    .regOut_MEI(HidelegModule_g_regOut_MEI),
    .regOut_SGEI(HidelegModule_g_regOut_SGEI),
    .regOut_LCOFI(HidelegModule_g_regOut_LCOFI),
    .mideleg_SSI(HidelegModule_mideleg_SSI),
    .mideleg_STI(HidelegModule_mideleg_STI),
    .mideleg_SEI(HidelegModule_mideleg_SEI),
    .mideleg_LCOFI(HidelegModule_mideleg_LCOFI)
  );
  HidelegModule_xs u_HidelegModule_i (
    .clock(clock),
    .reset(HidelegModule_reset),
    .w_wen(HidelegModule_w_wen),
    .w_wdata(HidelegModule_w_wdata),
    .rdata(HidelegModule_i_rdata),
    .regOut_SSI(HidelegModule_i_regOut_SSI),
    .regOut_VSSI(HidelegModule_i_regOut_VSSI),
    .regOut_MSI(HidelegModule_i_regOut_MSI),
    .regOut_STI(HidelegModule_i_regOut_STI),
    .regOut_VSTI(HidelegModule_i_regOut_VSTI),
    .regOut_MTI(HidelegModule_i_regOut_MTI),
    .regOut_SEI(HidelegModule_i_regOut_SEI),
    .regOut_VSEI(HidelegModule_i_regOut_VSEI),
    .regOut_MEI(HidelegModule_i_regOut_MEI),
    .regOut_SGEI(HidelegModule_i_regOut_SGEI),
    .regOut_LCOFI(HidelegModule_i_regOut_LCOFI),
    .mideleg_SSI(HidelegModule_mideleg_SSI),
    .mideleg_STI(HidelegModule_mideleg_STI),
    .mideleg_SEI(HidelegModule_mideleg_SEI),
    .mideleg_LCOFI(HidelegModule_mideleg_LCOFI)
  );

  Hstateen0Module u_Hstateen0Module_g (
    .clock(clock),
    .reset(Hstateen0Module_reset),
    .w_wen(Hstateen0Module_w_wen),
    .w_wdata(Hstateen0Module_w_wdata),
    .rdata(Hstateen0Module_g_rdata),
    .regOut_JVT(Hstateen0Module_g_regOut_JVT),
    .regOut_FCSR(Hstateen0Module_g_regOut_FCSR),
    .regOut_C(Hstateen0Module_g_regOut_C),
    .regOut_SE0(Hstateen0Module_g_regOut_SE0),
    .regOut_ENVCFG(Hstateen0Module_g_regOut_ENVCFG),
    .regOut_CSRIND(Hstateen0Module_g_regOut_CSRIND),
    .regOut_AIA(Hstateen0Module_g_regOut_AIA),
    .regOut_IMSIC(Hstateen0Module_g_regOut_IMSIC),
    .regOut_CONTEXT(Hstateen0Module_g_regOut_CONTEXT),
    .fromMstateen0_SE0(Hstateen0Module_fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(Hstateen0Module_fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(Hstateen0Module_fromMstateen0_CSRIND),
    .fromMstateen0_AIA(Hstateen0Module_fromMstateen0_AIA),
    .fromMstateen0_IMSIC(Hstateen0Module_fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(Hstateen0Module_fromMstateen0_CONTEXT),
    .fromMstateen0_C(Hstateen0Module_fromMstateen0_C)
  );
  Hstateen0Module_xs u_Hstateen0Module_i (
    .clock(clock),
    .reset(Hstateen0Module_reset),
    .w_wen(Hstateen0Module_w_wen),
    .w_wdata(Hstateen0Module_w_wdata),
    .rdata(Hstateen0Module_i_rdata),
    .regOut_JVT(Hstateen0Module_i_regOut_JVT),
    .regOut_FCSR(Hstateen0Module_i_regOut_FCSR),
    .regOut_C(Hstateen0Module_i_regOut_C),
    .regOut_SE0(Hstateen0Module_i_regOut_SE0),
    .regOut_ENVCFG(Hstateen0Module_i_regOut_ENVCFG),
    .regOut_CSRIND(Hstateen0Module_i_regOut_CSRIND),
    .regOut_AIA(Hstateen0Module_i_regOut_AIA),
    .regOut_IMSIC(Hstateen0Module_i_regOut_IMSIC),
    .regOut_CONTEXT(Hstateen0Module_i_regOut_CONTEXT),
    .fromMstateen0_SE0(Hstateen0Module_fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(Hstateen0Module_fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(Hstateen0Module_fromMstateen0_CSRIND),
    .fromMstateen0_AIA(Hstateen0Module_fromMstateen0_AIA),
    .fromMstateen0_IMSIC(Hstateen0Module_fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(Hstateen0Module_fromMstateen0_CONTEXT),
    .fromMstateen0_C(Hstateen0Module_fromMstateen0_C)
  );

  Hstateen1Module u_Hstateen1Module_g (
    .clock(clock),
    .w_wen(Hstateen1Module_w_wen),
    .w_wdata(Hstateen1Module_w_wdata),
    .rdata(Hstateen1Module_g_rdata),
    .regOut_SE(Hstateen1Module_g_regOut_SE),
    .fromMstateen1_SE(Hstateen1Module_fromMstateen1_SE)
  );
  Hstateen1Module_xs u_Hstateen1Module_i (
    .clock(clock),
    .w_wen(Hstateen1Module_w_wen),
    .w_wdata(Hstateen1Module_w_wdata),
    .rdata(Hstateen1Module_i_rdata),
    .regOut_SE(Hstateen1Module_i_regOut_SE),
    .fromMstateen1_SE(Hstateen1Module_fromMstateen1_SE)
  );

  Hstateen2Module u_Hstateen2Module_g (
    .clock(clock),
    .w_wen(Hstateen2Module_w_wen),
    .w_wdata(Hstateen2Module_w_wdata),
    .rdata(Hstateen2Module_g_rdata),
    .regOut_SE(Hstateen2Module_g_regOut_SE),
    .fromMstateen2_SE(Hstateen2Module_fromMstateen2_SE)
  );
  Hstateen2Module_xs u_Hstateen2Module_i (
    .clock(clock),
    .w_wen(Hstateen2Module_w_wen),
    .w_wdata(Hstateen2Module_w_wdata),
    .rdata(Hstateen2Module_i_rdata),
    .regOut_SE(Hstateen2Module_i_regOut_SE),
    .fromMstateen2_SE(Hstateen2Module_fromMstateen2_SE)
  );

  Hstateen3Module u_Hstateen3Module_g (
    .clock(clock),
    .w_wen(Hstateen3Module_w_wen),
    .w_wdata(Hstateen3Module_w_wdata),
    .rdata(Hstateen3Module_g_rdata),
    .regOut_SE(Hstateen3Module_g_regOut_SE),
    .fromMstateen3_SE(Hstateen3Module_fromMstateen3_SE)
  );
  Hstateen3Module_xs u_Hstateen3Module_i (
    .clock(clock),
    .w_wen(Hstateen3Module_w_wen),
    .w_wdata(Hstateen3Module_w_wdata),
    .rdata(Hstateen3Module_i_rdata),
    .regOut_SE(Hstateen3Module_i_regOut_SE),
    .fromMstateen3_SE(Hstateen3Module_fromMstateen3_SE)
  );

  HstatusModule u_HstatusModule_g (
    .clock(clock),
    .reset(HstatusModule_reset),
    .w_wen(HstatusModule_w_wen),
    .w_wdata(HstatusModule_w_wdata),
    .rdata(HstatusModule_g_rdata),
    .regOut_GVA(HstatusModule_g_regOut_GVA),
    .regOut_SPV(HstatusModule_g_regOut_SPV),
    .regOut_SPVP(HstatusModule_g_regOut_SPVP),
    .regOut_HU(HstatusModule_g_regOut_HU),
    .regOut_VGEIN(HstatusModule_g_regOut_VGEIN),
    .regOut_VTVM(HstatusModule_g_regOut_VTVM),
    .regOut_VTW(HstatusModule_g_regOut_VTW),
    .regOut_VTSR(HstatusModule_g_regOut_VTSR),
    .regOut_HUPMM(HstatusModule_g_regOut_HUPMM),
    .retFromS_hstatus_valid(HstatusModule_retFromS_hstatus_valid),
    .retFromS_hstatus_bits_SPV(HstatusModule_retFromS_hstatus_bits_SPV),
    .trapToHS_hstatus_valid(HstatusModule_trapToHS_hstatus_valid),
    .trapToHS_hstatus_bits_GVA(HstatusModule_trapToHS_hstatus_bits_GVA),
    .trapToHS_hstatus_bits_SPV(HstatusModule_trapToHS_hstatus_bits_SPV),
    .trapToHS_hstatus_bits_SPVP(HstatusModule_trapToHS_hstatus_bits_SPVP)
  );
  HstatusModule_xs u_HstatusModule_i (
    .clock(clock),
    .reset(HstatusModule_reset),
    .w_wen(HstatusModule_w_wen),
    .w_wdata(HstatusModule_w_wdata),
    .rdata(HstatusModule_i_rdata),
    .regOut_GVA(HstatusModule_i_regOut_GVA),
    .regOut_SPV(HstatusModule_i_regOut_SPV),
    .regOut_SPVP(HstatusModule_i_regOut_SPVP),
    .regOut_HU(HstatusModule_i_regOut_HU),
    .regOut_VGEIN(HstatusModule_i_regOut_VGEIN),
    .regOut_VTVM(HstatusModule_i_regOut_VTVM),
    .regOut_VTW(HstatusModule_i_regOut_VTW),
    .regOut_VTSR(HstatusModule_i_regOut_VTSR),
    .regOut_HUPMM(HstatusModule_i_regOut_HUPMM),
    .retFromS_hstatus_valid(HstatusModule_retFromS_hstatus_valid),
    .retFromS_hstatus_bits_SPV(HstatusModule_retFromS_hstatus_bits_SPV),
    .trapToHS_hstatus_valid(HstatusModule_trapToHS_hstatus_valid),
    .trapToHS_hstatus_bits_GVA(HstatusModule_trapToHS_hstatus_bits_GVA),
    .trapToHS_hstatus_bits_SPV(HstatusModule_trapToHS_hstatus_bits_SPV),
    .trapToHS_hstatus_bits_SPVP(HstatusModule_trapToHS_hstatus_bits_SPVP)
  );

  HtimedeltaModule u_HtimedeltaModule_g (
    .clock(clock),
    .reset(HtimedeltaModule_reset),
    .w_wen(HtimedeltaModule_w_wen),
    .w_wdata(HtimedeltaModule_w_wdata),
    .rdata(HtimedeltaModule_g_rdata),
    .regOut_ALL(HtimedeltaModule_g_regOut_ALL)
  );
  HtimedeltaModule_xs u_HtimedeltaModule_i (
    .clock(clock),
    .reset(HtimedeltaModule_reset),
    .w_wen(HtimedeltaModule_w_wen),
    .w_wdata(HtimedeltaModule_w_wdata),
    .rdata(HtimedeltaModule_i_rdata),
    .regOut_ALL(HtimedeltaModule_i_regOut_ALL)
  );

  HtinstModule u_HtinstModule_g (
    .clock(clock),
    .reset(HtinstModule_reset),
    .w_wen(HtinstModule_w_wen),
    .w_wdata(HtinstModule_w_wdata),
    .rdata(HtinstModule_g_rdata),
    .regOut_ALL(HtinstModule_g_regOut_ALL),
    .trapToHS_htinst_valid(HtinstModule_trapToHS_htinst_valid),
    .trapToHS_htinst_bits_ALL(HtinstModule_trapToHS_htinst_bits_ALL)
  );
  HtinstModule_xs u_HtinstModule_i (
    .clock(clock),
    .reset(HtinstModule_reset),
    .w_wen(HtinstModule_w_wen),
    .w_wdata(HtinstModule_w_wdata),
    .rdata(HtinstModule_i_rdata),
    .regOut_ALL(HtinstModule_i_regOut_ALL),
    .trapToHS_htinst_valid(HtinstModule_trapToHS_htinst_valid),
    .trapToHS_htinst_bits_ALL(HtinstModule_trapToHS_htinst_bits_ALL)
  );

  HtvalModule u_HtvalModule_g (
    .clock(clock),
    .reset(HtvalModule_reset),
    .w_wen(HtvalModule_w_wen),
    .w_wdata(HtvalModule_w_wdata),
    .rdata(HtvalModule_g_rdata),
    .regOut_ALL(HtvalModule_g_regOut_ALL),
    .trapToHS_htval_valid(HtvalModule_trapToHS_htval_valid),
    .trapToHS_htval_bits_ALL(HtvalModule_trapToHS_htval_bits_ALL)
  );
  HtvalModule_xs u_HtvalModule_i (
    .clock(clock),
    .reset(HtvalModule_reset),
    .w_wen(HtvalModule_w_wen),
    .w_wdata(HtvalModule_w_wdata),
    .rdata(HtvalModule_i_rdata),
    .regOut_ALL(HtvalModule_i_regOut_ALL),
    .trapToHS_htval_valid(HtvalModule_trapToHS_htval_valid),
    .trapToHS_htval_bits_ALL(HtvalModule_trapToHS_htval_bits_ALL)
  );

  HvictlModule u_HvictlModule_g (
    .clock(clock),
    .reset(HvictlModule_reset),
    .w_wen(HvictlModule_w_wen),
    .w_wdata(HvictlModule_w_wdata),
    .rdata(HvictlModule_g_rdata),
    .regOut_VTI(HvictlModule_g_regOut_VTI),
    .regOut_IID(HvictlModule_g_regOut_IID),
    .regOut_DPR(HvictlModule_g_regOut_DPR),
    .regOut_IPRIOM(HvictlModule_g_regOut_IPRIOM),
    .regOut_IPRIO(HvictlModule_g_regOut_IPRIO)
  );
  HvictlModule_xs u_HvictlModule_i (
    .clock(clock),
    .reset(HvictlModule_reset),
    .w_wen(HvictlModule_w_wen),
    .w_wdata(HvictlModule_w_wdata),
    .rdata(HvictlModule_i_rdata),
    .regOut_VTI(HvictlModule_i_regOut_VTI),
    .regOut_IID(HvictlModule_i_regOut_IID),
    .regOut_DPR(HvictlModule_i_regOut_DPR),
    .regOut_IPRIOM(HvictlModule_i_regOut_IPRIOM),
    .regOut_IPRIO(HvictlModule_i_regOut_IPRIO)
  );

  Hviprio1Module u_Hviprio1Module_g (
    .clock(clock),
    .reset(Hviprio1Module_reset),
    .w_wen(Hviprio1Module_w_wen),
    .w_wdata(Hviprio1Module_w_wdata),
    .rdata(Hviprio1Module_g_rdata),
    .regOut_PrioSSI(Hviprio1Module_g_regOut_PrioSSI),
    .regOut_PrioSTI(Hviprio1Module_g_regOut_PrioSTI),
    .regOut_PrioCOI(Hviprio1Module_g_regOut_PrioCOI),
    .regOut_Prio14(Hviprio1Module_g_regOut_Prio14),
    .regOut_Prio15(Hviprio1Module_g_regOut_Prio15)
  );
  Hviprio1Module_xs u_Hviprio1Module_i (
    .clock(clock),
    .reset(Hviprio1Module_reset),
    .w_wen(Hviprio1Module_w_wen),
    .w_wdata(Hviprio1Module_w_wdata),
    .rdata(Hviprio1Module_i_rdata),
    .regOut_PrioSSI(Hviprio1Module_i_regOut_PrioSSI),
    .regOut_PrioSTI(Hviprio1Module_i_regOut_PrioSTI),
    .regOut_PrioCOI(Hviprio1Module_i_regOut_PrioCOI),
    .regOut_Prio14(Hviprio1Module_i_regOut_Prio14),
    .regOut_Prio15(Hviprio1Module_i_regOut_Prio15)
  );

  Hviprio2Module u_Hviprio2Module_g (
    .clock(clock),
    .reset(Hviprio2Module_reset),
    .w_wen(Hviprio2Module_w_wen),
    .w_wdata(Hviprio2Module_w_wdata),
    .rdata(Hviprio2Module_g_rdata),
    .regOut_ALL(Hviprio2Module_g_regOut_ALL)
  );
  Hviprio2Module_xs u_Hviprio2Module_i (
    .clock(clock),
    .reset(Hviprio2Module_reset),
    .w_wen(Hviprio2Module_w_wen),
    .w_wdata(Hviprio2Module_w_wdata),
    .rdata(Hviprio2Module_i_rdata),
    .regOut_ALL(Hviprio2Module_i_regOut_ALL)
  );

  always @(posedge clock) begin
    #1;
    if (cycle > 5) begin
      checks++; if (DpcModule_g_rdata !== DpcModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH DpcModule.rdata g=%h i=%h", DpcModule_g_rdata, DpcModule_i_rdata); end
      checks++; if (DpcModule_g_regOut_epc !== DpcModule_i_regOut_epc) begin errors++; if (errors < 20) $display("MISMATCH DpcModule.regOut_epc g=%h i=%h", DpcModule_g_regOut_epc, DpcModule_i_regOut_epc); end
      checks++; if (DretEventModule_g_out_privState_valid !== DretEventModule_i_out_privState_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_privState_valid g=%h i=%h", DretEventModule_g_out_privState_valid, DretEventModule_i_out_privState_valid); end
      checks++; if (DretEventModule_g_out_privState_bits_PRVM !== DretEventModule_i_out_privState_bits_PRVM) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_privState_bits_PRVM g=%h i=%h", DretEventModule_g_out_privState_bits_PRVM, DretEventModule_i_out_privState_bits_PRVM); end
      checks++; if (DretEventModule_g_out_privState_bits_V !== DretEventModule_i_out_privState_bits_V) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_privState_bits_V g=%h i=%h", DretEventModule_g_out_privState_bits_V, DretEventModule_i_out_privState_bits_V); end
      checks++; if (DretEventModule_g_out_dcsr_valid !== DretEventModule_i_out_dcsr_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_valid g=%h i=%h", DretEventModule_g_out_dcsr_valid, DretEventModule_i_out_dcsr_valid); end
      checks++; if (DretEventModule_g_out_dcsr_bits_DEBUGVER !== DretEventModule_i_out_dcsr_bits_DEBUGVER) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_DEBUGVER g=%h i=%h", DretEventModule_g_out_dcsr_bits_DEBUGVER, DretEventModule_i_out_dcsr_bits_DEBUGVER); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EXTCAUSE !== DretEventModule_i_out_dcsr_bits_EXTCAUSE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EXTCAUSE g=%h i=%h", DretEventModule_g_out_dcsr_bits_EXTCAUSE, DretEventModule_i_out_dcsr_bits_EXTCAUSE); end
      checks++; if (DretEventModule_g_out_dcsr_bits_CETRIG !== DretEventModule_i_out_dcsr_bits_CETRIG) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_CETRIG g=%h i=%h", DretEventModule_g_out_dcsr_bits_CETRIG, DretEventModule_i_out_dcsr_bits_CETRIG); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EBREAKVS !== DretEventModule_i_out_dcsr_bits_EBREAKVS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EBREAKVS g=%h i=%h", DretEventModule_g_out_dcsr_bits_EBREAKVS, DretEventModule_i_out_dcsr_bits_EBREAKVS); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EBREAKVU !== DretEventModule_i_out_dcsr_bits_EBREAKVU) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EBREAKVU g=%h i=%h", DretEventModule_g_out_dcsr_bits_EBREAKVU, DretEventModule_i_out_dcsr_bits_EBREAKVU); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EBREAKM !== DretEventModule_i_out_dcsr_bits_EBREAKM) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EBREAKM g=%h i=%h", DretEventModule_g_out_dcsr_bits_EBREAKM, DretEventModule_i_out_dcsr_bits_EBREAKM); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EBREAKS !== DretEventModule_i_out_dcsr_bits_EBREAKS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EBREAKS g=%h i=%h", DretEventModule_g_out_dcsr_bits_EBREAKS, DretEventModule_i_out_dcsr_bits_EBREAKS); end
      checks++; if (DretEventModule_g_out_dcsr_bits_EBREAKU !== DretEventModule_i_out_dcsr_bits_EBREAKU) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_EBREAKU g=%h i=%h", DretEventModule_g_out_dcsr_bits_EBREAKU, DretEventModule_i_out_dcsr_bits_EBREAKU); end
      checks++; if (DretEventModule_g_out_dcsr_bits_STEPIE !== DretEventModule_i_out_dcsr_bits_STEPIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_STEPIE g=%h i=%h", DretEventModule_g_out_dcsr_bits_STEPIE, DretEventModule_i_out_dcsr_bits_STEPIE); end
      checks++; if (DretEventModule_g_out_dcsr_bits_STOPCOUNT !== DretEventModule_i_out_dcsr_bits_STOPCOUNT) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_STOPCOUNT g=%h i=%h", DretEventModule_g_out_dcsr_bits_STOPCOUNT, DretEventModule_i_out_dcsr_bits_STOPCOUNT); end
      checks++; if (DretEventModule_g_out_dcsr_bits_STOPTIME !== DretEventModule_i_out_dcsr_bits_STOPTIME) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_STOPTIME g=%h i=%h", DretEventModule_g_out_dcsr_bits_STOPTIME, DretEventModule_i_out_dcsr_bits_STOPTIME); end
      checks++; if (DretEventModule_g_out_dcsr_bits_CAUSE !== DretEventModule_i_out_dcsr_bits_CAUSE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_CAUSE g=%h i=%h", DretEventModule_g_out_dcsr_bits_CAUSE, DretEventModule_i_out_dcsr_bits_CAUSE); end
      checks++; if (DretEventModule_g_out_dcsr_bits_V !== DretEventModule_i_out_dcsr_bits_V) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_V g=%h i=%h", DretEventModule_g_out_dcsr_bits_V, DretEventModule_i_out_dcsr_bits_V); end
      checks++; if (DretEventModule_g_out_dcsr_bits_MPRVEN !== DretEventModule_i_out_dcsr_bits_MPRVEN) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_MPRVEN g=%h i=%h", DretEventModule_g_out_dcsr_bits_MPRVEN, DretEventModule_i_out_dcsr_bits_MPRVEN); end
      checks++; if (DretEventModule_g_out_dcsr_bits_NMIP !== DretEventModule_i_out_dcsr_bits_NMIP) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_NMIP g=%h i=%h", DretEventModule_g_out_dcsr_bits_NMIP, DretEventModule_i_out_dcsr_bits_NMIP); end
      checks++; if (DretEventModule_g_out_dcsr_bits_STEP !== DretEventModule_i_out_dcsr_bits_STEP) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_STEP g=%h i=%h", DretEventModule_g_out_dcsr_bits_STEP, DretEventModule_i_out_dcsr_bits_STEP); end
      checks++; if (DretEventModule_g_out_dcsr_bits_PRV !== DretEventModule_i_out_dcsr_bits_PRV) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_dcsr_bits_PRV g=%h i=%h", DretEventModule_g_out_dcsr_bits_PRV, DretEventModule_i_out_dcsr_bits_PRV); end
      checks++; if (DretEventModule_g_out_mstatus_valid !== DretEventModule_i_out_mstatus_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_valid g=%h i=%h", DretEventModule_g_out_mstatus_valid, DretEventModule_i_out_mstatus_valid); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SIE !== DretEventModule_i_out_mstatus_bits_SIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SIE g=%h i=%h", DretEventModule_g_out_mstatus_bits_SIE, DretEventModule_i_out_mstatus_bits_SIE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MIE !== DretEventModule_i_out_mstatus_bits_MIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MIE g=%h i=%h", DretEventModule_g_out_mstatus_bits_MIE, DretEventModule_i_out_mstatus_bits_MIE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SPIE !== DretEventModule_i_out_mstatus_bits_SPIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SPIE g=%h i=%h", DretEventModule_g_out_mstatus_bits_SPIE, DretEventModule_i_out_mstatus_bits_SPIE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_UBE !== DretEventModule_i_out_mstatus_bits_UBE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_UBE g=%h i=%h", DretEventModule_g_out_mstatus_bits_UBE, DretEventModule_i_out_mstatus_bits_UBE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MPIE !== DretEventModule_i_out_mstatus_bits_MPIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MPIE g=%h i=%h", DretEventModule_g_out_mstatus_bits_MPIE, DretEventModule_i_out_mstatus_bits_MPIE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SPP !== DretEventModule_i_out_mstatus_bits_SPP) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SPP g=%h i=%h", DretEventModule_g_out_mstatus_bits_SPP, DretEventModule_i_out_mstatus_bits_SPP); end
      checks++; if (DretEventModule_g_out_mstatus_bits_VS !== DretEventModule_i_out_mstatus_bits_VS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_VS g=%h i=%h", DretEventModule_g_out_mstatus_bits_VS, DretEventModule_i_out_mstatus_bits_VS); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MPP !== DretEventModule_i_out_mstatus_bits_MPP) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MPP g=%h i=%h", DretEventModule_g_out_mstatus_bits_MPP, DretEventModule_i_out_mstatus_bits_MPP); end
      checks++; if (DretEventModule_g_out_mstatus_bits_FS !== DretEventModule_i_out_mstatus_bits_FS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_FS g=%h i=%h", DretEventModule_g_out_mstatus_bits_FS, DretEventModule_i_out_mstatus_bits_FS); end
      checks++; if (DretEventModule_g_out_mstatus_bits_XS !== DretEventModule_i_out_mstatus_bits_XS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_XS g=%h i=%h", DretEventModule_g_out_mstatus_bits_XS, DretEventModule_i_out_mstatus_bits_XS); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MPRV !== DretEventModule_i_out_mstatus_bits_MPRV) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MPRV g=%h i=%h", DretEventModule_g_out_mstatus_bits_MPRV, DretEventModule_i_out_mstatus_bits_MPRV); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SUM !== DretEventModule_i_out_mstatus_bits_SUM) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SUM g=%h i=%h", DretEventModule_g_out_mstatus_bits_SUM, DretEventModule_i_out_mstatus_bits_SUM); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MXR !== DretEventModule_i_out_mstatus_bits_MXR) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MXR g=%h i=%h", DretEventModule_g_out_mstatus_bits_MXR, DretEventModule_i_out_mstatus_bits_MXR); end
      checks++; if (DretEventModule_g_out_mstatus_bits_TVM !== DretEventModule_i_out_mstatus_bits_TVM) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_TVM g=%h i=%h", DretEventModule_g_out_mstatus_bits_TVM, DretEventModule_i_out_mstatus_bits_TVM); end
      checks++; if (DretEventModule_g_out_mstatus_bits_TW !== DretEventModule_i_out_mstatus_bits_TW) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_TW g=%h i=%h", DretEventModule_g_out_mstatus_bits_TW, DretEventModule_i_out_mstatus_bits_TW); end
      checks++; if (DretEventModule_g_out_mstatus_bits_TSR !== DretEventModule_i_out_mstatus_bits_TSR) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_TSR g=%h i=%h", DretEventModule_g_out_mstatus_bits_TSR, DretEventModule_i_out_mstatus_bits_TSR); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SDT !== DretEventModule_i_out_mstatus_bits_SDT) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SDT g=%h i=%h", DretEventModule_g_out_mstatus_bits_SDT, DretEventModule_i_out_mstatus_bits_SDT); end
      checks++; if (DretEventModule_g_out_mstatus_bits_UXL !== DretEventModule_i_out_mstatus_bits_UXL) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_UXL g=%h i=%h", DretEventModule_g_out_mstatus_bits_UXL, DretEventModule_i_out_mstatus_bits_UXL); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SXL !== DretEventModule_i_out_mstatus_bits_SXL) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SXL g=%h i=%h", DretEventModule_g_out_mstatus_bits_SXL, DretEventModule_i_out_mstatus_bits_SXL); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SBE !== DretEventModule_i_out_mstatus_bits_SBE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SBE g=%h i=%h", DretEventModule_g_out_mstatus_bits_SBE, DretEventModule_i_out_mstatus_bits_SBE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MBE !== DretEventModule_i_out_mstatus_bits_MBE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MBE g=%h i=%h", DretEventModule_g_out_mstatus_bits_MBE, DretEventModule_i_out_mstatus_bits_MBE); end
      checks++; if (DretEventModule_g_out_mstatus_bits_GVA !== DretEventModule_i_out_mstatus_bits_GVA) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_GVA g=%h i=%h", DretEventModule_g_out_mstatus_bits_GVA, DretEventModule_i_out_mstatus_bits_GVA); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MPV !== DretEventModule_i_out_mstatus_bits_MPV) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MPV g=%h i=%h", DretEventModule_g_out_mstatus_bits_MPV, DretEventModule_i_out_mstatus_bits_MPV); end
      checks++; if (DretEventModule_g_out_mstatus_bits_MDT !== DretEventModule_i_out_mstatus_bits_MDT) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_MDT g=%h i=%h", DretEventModule_g_out_mstatus_bits_MDT, DretEventModule_i_out_mstatus_bits_MDT); end
      checks++; if (DretEventModule_g_out_mstatus_bits_SD !== DretEventModule_i_out_mstatus_bits_SD) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_mstatus_bits_SD g=%h i=%h", DretEventModule_g_out_mstatus_bits_SD, DretEventModule_i_out_mstatus_bits_SD); end
      checks++; if (DretEventModule_g_out_vsstatus_valid !== DretEventModule_i_out_vsstatus_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_valid g=%h i=%h", DretEventModule_g_out_vsstatus_valid, DretEventModule_i_out_vsstatus_valid); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SIE !== DretEventModule_i_out_vsstatus_bits_SIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SIE g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SIE, DretEventModule_i_out_vsstatus_bits_SIE); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SPIE !== DretEventModule_i_out_vsstatus_bits_SPIE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SPIE g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SPIE, DretEventModule_i_out_vsstatus_bits_SPIE); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_UBE !== DretEventModule_i_out_vsstatus_bits_UBE) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_UBE g=%h i=%h", DretEventModule_g_out_vsstatus_bits_UBE, DretEventModule_i_out_vsstatus_bits_UBE); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SPP !== DretEventModule_i_out_vsstatus_bits_SPP) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SPP g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SPP, DretEventModule_i_out_vsstatus_bits_SPP); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_VS !== DretEventModule_i_out_vsstatus_bits_VS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_VS g=%h i=%h", DretEventModule_g_out_vsstatus_bits_VS, DretEventModule_i_out_vsstatus_bits_VS); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_FS !== DretEventModule_i_out_vsstatus_bits_FS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_FS g=%h i=%h", DretEventModule_g_out_vsstatus_bits_FS, DretEventModule_i_out_vsstatus_bits_FS); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_XS !== DretEventModule_i_out_vsstatus_bits_XS) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_XS g=%h i=%h", DretEventModule_g_out_vsstatus_bits_XS, DretEventModule_i_out_vsstatus_bits_XS); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SUM !== DretEventModule_i_out_vsstatus_bits_SUM) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SUM g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SUM, DretEventModule_i_out_vsstatus_bits_SUM); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_MXR !== DretEventModule_i_out_vsstatus_bits_MXR) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_MXR g=%h i=%h", DretEventModule_g_out_vsstatus_bits_MXR, DretEventModule_i_out_vsstatus_bits_MXR); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SDT !== DretEventModule_i_out_vsstatus_bits_SDT) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SDT g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SDT, DretEventModule_i_out_vsstatus_bits_SDT); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_UXL !== DretEventModule_i_out_vsstatus_bits_UXL) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_UXL g=%h i=%h", DretEventModule_g_out_vsstatus_bits_UXL, DretEventModule_i_out_vsstatus_bits_UXL); end
      checks++; if (DretEventModule_g_out_vsstatus_bits_SD !== DretEventModule_i_out_vsstatus_bits_SD) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_vsstatus_bits_SD g=%h i=%h", DretEventModule_g_out_vsstatus_bits_SD, DretEventModule_i_out_vsstatus_bits_SD); end
      checks++; if (DretEventModule_g_out_debugMode_valid !== DretEventModule_i_out_debugMode_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_debugMode_valid g=%h i=%h", DretEventModule_g_out_debugMode_valid, DretEventModule_i_out_debugMode_valid); end
      checks++; if (DretEventModule_g_out_debugMode_bits !== DretEventModule_i_out_debugMode_bits) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_debugMode_bits g=%h i=%h", DretEventModule_g_out_debugMode_bits, DretEventModule_i_out_debugMode_bits); end
      checks++; if (DretEventModule_g_out_debugIntrEnable_valid !== DretEventModule_i_out_debugIntrEnable_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_debugIntrEnable_valid g=%h i=%h", DretEventModule_g_out_debugIntrEnable_valid, DretEventModule_i_out_debugIntrEnable_valid); end
      checks++; if (DretEventModule_g_out_debugIntrEnable_bits !== DretEventModule_i_out_debugIntrEnable_bits) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_debugIntrEnable_bits g=%h i=%h", DretEventModule_g_out_debugIntrEnable_bits, DretEventModule_i_out_debugIntrEnable_bits); end
      checks++; if (DretEventModule_g_out_targetPc_valid !== DretEventModule_i_out_targetPc_valid) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_targetPc_valid g=%h i=%h", DretEventModule_g_out_targetPc_valid, DretEventModule_i_out_targetPc_valid); end
      checks++; if (DretEventModule_g_out_targetPc_bits_pc !== DretEventModule_i_out_targetPc_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_targetPc_bits_pc g=%h i=%h", DretEventModule_g_out_targetPc_bits_pc, DretEventModule_i_out_targetPc_bits_pc); end
      checks++; if (DretEventModule_g_out_targetPc_bits_raiseIPF !== DretEventModule_i_out_targetPc_bits_raiseIPF) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_targetPc_bits_raiseIPF g=%h i=%h", DretEventModule_g_out_targetPc_bits_raiseIPF, DretEventModule_i_out_targetPc_bits_raiseIPF); end
      checks++; if (DretEventModule_g_out_targetPc_bits_raiseIAF !== DretEventModule_i_out_targetPc_bits_raiseIAF) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_targetPc_bits_raiseIAF g=%h i=%h", DretEventModule_g_out_targetPc_bits_raiseIAF, DretEventModule_i_out_targetPc_bits_raiseIAF); end
      checks++; if (DretEventModule_g_out_targetPc_bits_raiseIGPF !== DretEventModule_i_out_targetPc_bits_raiseIGPF) begin errors++; if (errors < 20) $display("MISMATCH DretEventModule.out_targetPc_bits_raiseIGPF g=%h i=%h", DretEventModule_g_out_targetPc_bits_raiseIGPF, DretEventModule_i_out_targetPc_bits_raiseIGPF); end
      checks++; if (HcounterenModule_g_rdata !== HcounterenModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HcounterenModule.rdata g=%h i=%h", HcounterenModule_g_rdata, HcounterenModule_i_rdata); end
      checks++; if (HcounterenModule_g_regOut_CY !== HcounterenModule_i_regOut_CY) begin errors++; if (errors < 20) $display("MISMATCH HcounterenModule.regOut_CY g=%h i=%h", HcounterenModule_g_regOut_CY, HcounterenModule_i_regOut_CY); end
      checks++; if (HcounterenModule_g_regOut_TM !== HcounterenModule_i_regOut_TM) begin errors++; if (errors < 20) $display("MISMATCH HcounterenModule.regOut_TM g=%h i=%h", HcounterenModule_g_regOut_TM, HcounterenModule_i_regOut_TM); end
      checks++; if (HcounterenModule_g_regOut_IR !== HcounterenModule_i_regOut_IR) begin errors++; if (errors < 20) $display("MISMATCH HcounterenModule.regOut_IR g=%h i=%h", HcounterenModule_g_regOut_IR, HcounterenModule_i_regOut_IR); end
      checks++; if (HcounterenModule_g_regOut_HPM !== HcounterenModule_i_regOut_HPM) begin errors++; if (errors < 20) $display("MISMATCH HcounterenModule.regOut_HPM g=%h i=%h", HcounterenModule_g_regOut_HPM, HcounterenModule_i_regOut_HPM); end
      checks++; if (HedelegModule_g_rdata !== HedelegModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.rdata g=%h i=%h", HedelegModule_g_rdata, HedelegModule_i_rdata); end
      checks++; if (HedelegModule_g_regOut_EX_IAM !== HedelegModule_i_regOut_EX_IAM) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_IAM g=%h i=%h", HedelegModule_g_regOut_EX_IAM, HedelegModule_i_regOut_EX_IAM); end
      checks++; if (HedelegModule_g_regOut_EX_IAF !== HedelegModule_i_regOut_EX_IAF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_IAF g=%h i=%h", HedelegModule_g_regOut_EX_IAF, HedelegModule_i_regOut_EX_IAF); end
      checks++; if (HedelegModule_g_regOut_EX_II !== HedelegModule_i_regOut_EX_II) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_II g=%h i=%h", HedelegModule_g_regOut_EX_II, HedelegModule_i_regOut_EX_II); end
      checks++; if (HedelegModule_g_regOut_EX_BP !== HedelegModule_i_regOut_EX_BP) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_BP g=%h i=%h", HedelegModule_g_regOut_EX_BP, HedelegModule_i_regOut_EX_BP); end
      checks++; if (HedelegModule_g_regOut_EX_LAM !== HedelegModule_i_regOut_EX_LAM) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_LAM g=%h i=%h", HedelegModule_g_regOut_EX_LAM, HedelegModule_i_regOut_EX_LAM); end
      checks++; if (HedelegModule_g_regOut_EX_LAF !== HedelegModule_i_regOut_EX_LAF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_LAF g=%h i=%h", HedelegModule_g_regOut_EX_LAF, HedelegModule_i_regOut_EX_LAF); end
      checks++; if (HedelegModule_g_regOut_EX_SAM !== HedelegModule_i_regOut_EX_SAM) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_SAM g=%h i=%h", HedelegModule_g_regOut_EX_SAM, HedelegModule_i_regOut_EX_SAM); end
      checks++; if (HedelegModule_g_regOut_EX_SAF !== HedelegModule_i_regOut_EX_SAF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_SAF g=%h i=%h", HedelegModule_g_regOut_EX_SAF, HedelegModule_i_regOut_EX_SAF); end
      checks++; if (HedelegModule_g_regOut_EX_UCALL !== HedelegModule_i_regOut_EX_UCALL) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_UCALL g=%h i=%h", HedelegModule_g_regOut_EX_UCALL, HedelegModule_i_regOut_EX_UCALL); end
      checks++; if (HedelegModule_g_regOut_EX_IPF !== HedelegModule_i_regOut_EX_IPF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_IPF g=%h i=%h", HedelegModule_g_regOut_EX_IPF, HedelegModule_i_regOut_EX_IPF); end
      checks++; if (HedelegModule_g_regOut_EX_LPF !== HedelegModule_i_regOut_EX_LPF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_LPF g=%h i=%h", HedelegModule_g_regOut_EX_LPF, HedelegModule_i_regOut_EX_LPF); end
      checks++; if (HedelegModule_g_regOut_EX_SPF !== HedelegModule_i_regOut_EX_SPF) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_SPF g=%h i=%h", HedelegModule_g_regOut_EX_SPF, HedelegModule_i_regOut_EX_SPF); end
      checks++; if (HedelegModule_g_regOut_EX_SWC !== HedelegModule_i_regOut_EX_SWC) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_SWC g=%h i=%h", HedelegModule_g_regOut_EX_SWC, HedelegModule_i_regOut_EX_SWC); end
      checks++; if (HedelegModule_g_regOut_EX_HWE !== HedelegModule_i_regOut_EX_HWE) begin errors++; if (errors < 20) $display("MISMATCH HedelegModule.regOut_EX_HWE g=%h i=%h", HedelegModule_g_regOut_EX_HWE, HedelegModule_i_regOut_EX_HWE); end
      checks++; if (HenvcfgModule_g_rdata !== HenvcfgModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.rdata g=%h i=%h", HenvcfgModule_g_rdata, HenvcfgModule_i_rdata); end
      checks++; if (HenvcfgModule_g_regOut_STCE !== HenvcfgModule_i_regOut_STCE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_STCE g=%h i=%h", HenvcfgModule_g_regOut_STCE, HenvcfgModule_i_regOut_STCE); end
      checks++; if (HenvcfgModule_g_regOut_PBMTE !== HenvcfgModule_i_regOut_PBMTE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_PBMTE g=%h i=%h", HenvcfgModule_g_regOut_PBMTE, HenvcfgModule_i_regOut_PBMTE); end
      checks++; if (HenvcfgModule_g_regOut_DTE !== HenvcfgModule_i_regOut_DTE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_DTE g=%h i=%h", HenvcfgModule_g_regOut_DTE, HenvcfgModule_i_regOut_DTE); end
      checks++; if (HenvcfgModule_g_regOut_PMM !== HenvcfgModule_i_regOut_PMM) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_PMM g=%h i=%h", HenvcfgModule_g_regOut_PMM, HenvcfgModule_i_regOut_PMM); end
      checks++; if (HenvcfgModule_g_regOut_CBZE !== HenvcfgModule_i_regOut_CBZE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_CBZE g=%h i=%h", HenvcfgModule_g_regOut_CBZE, HenvcfgModule_i_regOut_CBZE); end
      checks++; if (HenvcfgModule_g_regOut_CBCFE !== HenvcfgModule_i_regOut_CBCFE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_CBCFE g=%h i=%h", HenvcfgModule_g_regOut_CBCFE, HenvcfgModule_i_regOut_CBCFE); end
      checks++; if (HenvcfgModule_g_regOut_CBIE !== HenvcfgModule_i_regOut_CBIE) begin errors++; if (errors < 20) $display("MISMATCH HenvcfgModule.regOut_CBIE g=%h i=%h", HenvcfgModule_g_regOut_CBIE, HenvcfgModule_i_regOut_CBIE); end
      checks++; if (HgatpModule_g_rdata !== HgatpModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HgatpModule.rdata g=%h i=%h", HgatpModule_g_rdata, HgatpModule_i_rdata); end
      checks++; if (HgatpModule_g_regOut_MODE !== HgatpModule_i_regOut_MODE) begin errors++; if (errors < 20) $display("MISMATCH HgatpModule.regOut_MODE g=%h i=%h", HgatpModule_g_regOut_MODE, HgatpModule_i_regOut_MODE); end
      checks++; if (HgatpModule_g_regOut_VMID !== HgatpModule_i_regOut_VMID) begin errors++; if (errors < 20) $display("MISMATCH HgatpModule.regOut_VMID g=%h i=%h", HgatpModule_g_regOut_VMID, HgatpModule_i_regOut_VMID); end
      checks++; if (HgatpModule_g_regOut_PPN !== HgatpModule_i_regOut_PPN) begin errors++; if (errors < 20) $display("MISMATCH HgatpModule.regOut_PPN g=%h i=%h", HgatpModule_g_regOut_PPN, HgatpModule_i_regOut_PPN); end
      checks++; if (HidelegModule_g_rdata !== HidelegModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.rdata g=%h i=%h", HidelegModule_g_rdata, HidelegModule_i_rdata); end
      checks++; if (HidelegModule_g_regOut_SSI !== HidelegModule_i_regOut_SSI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_SSI g=%h i=%h", HidelegModule_g_regOut_SSI, HidelegModule_i_regOut_SSI); end
      checks++; if (HidelegModule_g_regOut_VSSI !== HidelegModule_i_regOut_VSSI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_VSSI g=%h i=%h", HidelegModule_g_regOut_VSSI, HidelegModule_i_regOut_VSSI); end
      checks++; if (HidelegModule_g_regOut_MSI !== HidelegModule_i_regOut_MSI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_MSI g=%h i=%h", HidelegModule_g_regOut_MSI, HidelegModule_i_regOut_MSI); end
      checks++; if (HidelegModule_g_regOut_STI !== HidelegModule_i_regOut_STI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_STI g=%h i=%h", HidelegModule_g_regOut_STI, HidelegModule_i_regOut_STI); end
      checks++; if (HidelegModule_g_regOut_VSTI !== HidelegModule_i_regOut_VSTI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_VSTI g=%h i=%h", HidelegModule_g_regOut_VSTI, HidelegModule_i_regOut_VSTI); end
      checks++; if (HidelegModule_g_regOut_MTI !== HidelegModule_i_regOut_MTI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_MTI g=%h i=%h", HidelegModule_g_regOut_MTI, HidelegModule_i_regOut_MTI); end
      checks++; if (HidelegModule_g_regOut_SEI !== HidelegModule_i_regOut_SEI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_SEI g=%h i=%h", HidelegModule_g_regOut_SEI, HidelegModule_i_regOut_SEI); end
      checks++; if (HidelegModule_g_regOut_VSEI !== HidelegModule_i_regOut_VSEI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_VSEI g=%h i=%h", HidelegModule_g_regOut_VSEI, HidelegModule_i_regOut_VSEI); end
      checks++; if (HidelegModule_g_regOut_MEI !== HidelegModule_i_regOut_MEI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_MEI g=%h i=%h", HidelegModule_g_regOut_MEI, HidelegModule_i_regOut_MEI); end
      checks++; if (HidelegModule_g_regOut_SGEI !== HidelegModule_i_regOut_SGEI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_SGEI g=%h i=%h", HidelegModule_g_regOut_SGEI, HidelegModule_i_regOut_SGEI); end
      checks++; if (HidelegModule_g_regOut_LCOFI !== HidelegModule_i_regOut_LCOFI) begin errors++; if (errors < 20) $display("MISMATCH HidelegModule.regOut_LCOFI g=%h i=%h", HidelegModule_g_regOut_LCOFI, HidelegModule_i_regOut_LCOFI); end
      checks++; if (Hstateen0Module_g_rdata !== Hstateen0Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.rdata g=%h i=%h", Hstateen0Module_g_rdata, Hstateen0Module_i_rdata); end
      checks++; if (Hstateen0Module_g_regOut_JVT !== Hstateen0Module_i_regOut_JVT) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_JVT g=%h i=%h", Hstateen0Module_g_regOut_JVT, Hstateen0Module_i_regOut_JVT); end
      checks++; if (Hstateen0Module_g_regOut_FCSR !== Hstateen0Module_i_regOut_FCSR) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_FCSR g=%h i=%h", Hstateen0Module_g_regOut_FCSR, Hstateen0Module_i_regOut_FCSR); end
      checks++; if (Hstateen0Module_g_regOut_C !== Hstateen0Module_i_regOut_C) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_C g=%h i=%h", Hstateen0Module_g_regOut_C, Hstateen0Module_i_regOut_C); end
      checks++; if (Hstateen0Module_g_regOut_SE0 !== Hstateen0Module_i_regOut_SE0) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_SE0 g=%h i=%h", Hstateen0Module_g_regOut_SE0, Hstateen0Module_i_regOut_SE0); end
      checks++; if (Hstateen0Module_g_regOut_ENVCFG !== Hstateen0Module_i_regOut_ENVCFG) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_ENVCFG g=%h i=%h", Hstateen0Module_g_regOut_ENVCFG, Hstateen0Module_i_regOut_ENVCFG); end
      checks++; if (Hstateen0Module_g_regOut_CSRIND !== Hstateen0Module_i_regOut_CSRIND) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_CSRIND g=%h i=%h", Hstateen0Module_g_regOut_CSRIND, Hstateen0Module_i_regOut_CSRIND); end
      checks++; if (Hstateen0Module_g_regOut_AIA !== Hstateen0Module_i_regOut_AIA) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_AIA g=%h i=%h", Hstateen0Module_g_regOut_AIA, Hstateen0Module_i_regOut_AIA); end
      checks++; if (Hstateen0Module_g_regOut_IMSIC !== Hstateen0Module_i_regOut_IMSIC) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_IMSIC g=%h i=%h", Hstateen0Module_g_regOut_IMSIC, Hstateen0Module_i_regOut_IMSIC); end
      checks++; if (Hstateen0Module_g_regOut_CONTEXT !== Hstateen0Module_i_regOut_CONTEXT) begin errors++; if (errors < 20) $display("MISMATCH Hstateen0Module.regOut_CONTEXT g=%h i=%h", Hstateen0Module_g_regOut_CONTEXT, Hstateen0Module_i_regOut_CONTEXT); end
      checks++; if (Hstateen1Module_g_rdata !== Hstateen1Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hstateen1Module.rdata g=%h i=%h", Hstateen1Module_g_rdata, Hstateen1Module_i_rdata); end
      checks++; if (Hstateen1Module_g_regOut_SE !== Hstateen1Module_i_regOut_SE) begin errors++; if (errors < 20) $display("MISMATCH Hstateen1Module.regOut_SE g=%h i=%h", Hstateen1Module_g_regOut_SE, Hstateen1Module_i_regOut_SE); end
      checks++; if (Hstateen2Module_g_rdata !== Hstateen2Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hstateen2Module.rdata g=%h i=%h", Hstateen2Module_g_rdata, Hstateen2Module_i_rdata); end
      checks++; if (Hstateen2Module_g_regOut_SE !== Hstateen2Module_i_regOut_SE) begin errors++; if (errors < 20) $display("MISMATCH Hstateen2Module.regOut_SE g=%h i=%h", Hstateen2Module_g_regOut_SE, Hstateen2Module_i_regOut_SE); end
      checks++; if (Hstateen3Module_g_rdata !== Hstateen3Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hstateen3Module.rdata g=%h i=%h", Hstateen3Module_g_rdata, Hstateen3Module_i_rdata); end
      checks++; if (Hstateen3Module_g_regOut_SE !== Hstateen3Module_i_regOut_SE) begin errors++; if (errors < 20) $display("MISMATCH Hstateen3Module.regOut_SE g=%h i=%h", Hstateen3Module_g_regOut_SE, Hstateen3Module_i_regOut_SE); end
      checks++; if (HstatusModule_g_rdata !== HstatusModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.rdata g=%h i=%h", HstatusModule_g_rdata, HstatusModule_i_rdata); end
      checks++; if (HstatusModule_g_regOut_GVA !== HstatusModule_i_regOut_GVA) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_GVA g=%h i=%h", HstatusModule_g_regOut_GVA, HstatusModule_i_regOut_GVA); end
      checks++; if (HstatusModule_g_regOut_SPV !== HstatusModule_i_regOut_SPV) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_SPV g=%h i=%h", HstatusModule_g_regOut_SPV, HstatusModule_i_regOut_SPV); end
      checks++; if (HstatusModule_g_regOut_SPVP !== HstatusModule_i_regOut_SPVP) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_SPVP g=%h i=%h", HstatusModule_g_regOut_SPVP, HstatusModule_i_regOut_SPVP); end
      checks++; if (HstatusModule_g_regOut_HU !== HstatusModule_i_regOut_HU) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_HU g=%h i=%h", HstatusModule_g_regOut_HU, HstatusModule_i_regOut_HU); end
      checks++; if (HstatusModule_g_regOut_VGEIN !== HstatusModule_i_regOut_VGEIN) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_VGEIN g=%h i=%h", HstatusModule_g_regOut_VGEIN, HstatusModule_i_regOut_VGEIN); end
      checks++; if (HstatusModule_g_regOut_VTVM !== HstatusModule_i_regOut_VTVM) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_VTVM g=%h i=%h", HstatusModule_g_regOut_VTVM, HstatusModule_i_regOut_VTVM); end
      checks++; if (HstatusModule_g_regOut_VTW !== HstatusModule_i_regOut_VTW) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_VTW g=%h i=%h", HstatusModule_g_regOut_VTW, HstatusModule_i_regOut_VTW); end
      checks++; if (HstatusModule_g_regOut_VTSR !== HstatusModule_i_regOut_VTSR) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_VTSR g=%h i=%h", HstatusModule_g_regOut_VTSR, HstatusModule_i_regOut_VTSR); end
      checks++; if (HstatusModule_g_regOut_HUPMM !== HstatusModule_i_regOut_HUPMM) begin errors++; if (errors < 20) $display("MISMATCH HstatusModule.regOut_HUPMM g=%h i=%h", HstatusModule_g_regOut_HUPMM, HstatusModule_i_regOut_HUPMM); end
      checks++; if (HtimedeltaModule_g_rdata !== HtimedeltaModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HtimedeltaModule.rdata g=%h i=%h", HtimedeltaModule_g_rdata, HtimedeltaModule_i_rdata); end
      checks++; if (HtimedeltaModule_g_regOut_ALL !== HtimedeltaModule_i_regOut_ALL) begin errors++; if (errors < 20) $display("MISMATCH HtimedeltaModule.regOut_ALL g=%h i=%h", HtimedeltaModule_g_regOut_ALL, HtimedeltaModule_i_regOut_ALL); end
      checks++; if (HtinstModule_g_rdata !== HtinstModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HtinstModule.rdata g=%h i=%h", HtinstModule_g_rdata, HtinstModule_i_rdata); end
      checks++; if (HtinstModule_g_regOut_ALL !== HtinstModule_i_regOut_ALL) begin errors++; if (errors < 20) $display("MISMATCH HtinstModule.regOut_ALL g=%h i=%h", HtinstModule_g_regOut_ALL, HtinstModule_i_regOut_ALL); end
      checks++; if (HtvalModule_g_rdata !== HtvalModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HtvalModule.rdata g=%h i=%h", HtvalModule_g_rdata, HtvalModule_i_rdata); end
      checks++; if (HtvalModule_g_regOut_ALL !== HtvalModule_i_regOut_ALL) begin errors++; if (errors < 20) $display("MISMATCH HtvalModule.regOut_ALL g=%h i=%h", HtvalModule_g_regOut_ALL, HtvalModule_i_regOut_ALL); end
      checks++; if (HvictlModule_g_rdata !== HvictlModule_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.rdata g=%h i=%h", HvictlModule_g_rdata, HvictlModule_i_rdata); end
      checks++; if (HvictlModule_g_regOut_VTI !== HvictlModule_i_regOut_VTI) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.regOut_VTI g=%h i=%h", HvictlModule_g_regOut_VTI, HvictlModule_i_regOut_VTI); end
      checks++; if (HvictlModule_g_regOut_IID !== HvictlModule_i_regOut_IID) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.regOut_IID g=%h i=%h", HvictlModule_g_regOut_IID, HvictlModule_i_regOut_IID); end
      checks++; if (HvictlModule_g_regOut_DPR !== HvictlModule_i_regOut_DPR) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.regOut_DPR g=%h i=%h", HvictlModule_g_regOut_DPR, HvictlModule_i_regOut_DPR); end
      checks++; if (HvictlModule_g_regOut_IPRIOM !== HvictlModule_i_regOut_IPRIOM) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.regOut_IPRIOM g=%h i=%h", HvictlModule_g_regOut_IPRIOM, HvictlModule_i_regOut_IPRIOM); end
      checks++; if (HvictlModule_g_regOut_IPRIO !== HvictlModule_i_regOut_IPRIO) begin errors++; if (errors < 20) $display("MISMATCH HvictlModule.regOut_IPRIO g=%h i=%h", HvictlModule_g_regOut_IPRIO, HvictlModule_i_regOut_IPRIO); end
      checks++; if (Hviprio1Module_g_rdata !== Hviprio1Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.rdata g=%h i=%h", Hviprio1Module_g_rdata, Hviprio1Module_i_rdata); end
      checks++; if (Hviprio1Module_g_regOut_PrioSSI !== Hviprio1Module_i_regOut_PrioSSI) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.regOut_PrioSSI g=%h i=%h", Hviprio1Module_g_regOut_PrioSSI, Hviprio1Module_i_regOut_PrioSSI); end
      checks++; if (Hviprio1Module_g_regOut_PrioSTI !== Hviprio1Module_i_regOut_PrioSTI) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.regOut_PrioSTI g=%h i=%h", Hviprio1Module_g_regOut_PrioSTI, Hviprio1Module_i_regOut_PrioSTI); end
      checks++; if (Hviprio1Module_g_regOut_PrioCOI !== Hviprio1Module_i_regOut_PrioCOI) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.regOut_PrioCOI g=%h i=%h", Hviprio1Module_g_regOut_PrioCOI, Hviprio1Module_i_regOut_PrioCOI); end
      checks++; if (Hviprio1Module_g_regOut_Prio14 !== Hviprio1Module_i_regOut_Prio14) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.regOut_Prio14 g=%h i=%h", Hviprio1Module_g_regOut_Prio14, Hviprio1Module_i_regOut_Prio14); end
      checks++; if (Hviprio1Module_g_regOut_Prio15 !== Hviprio1Module_i_regOut_Prio15) begin errors++; if (errors < 20) $display("MISMATCH Hviprio1Module.regOut_Prio15 g=%h i=%h", Hviprio1Module_g_regOut_Prio15, Hviprio1Module_i_regOut_Prio15); end
      checks++; if (Hviprio2Module_g_rdata !== Hviprio2Module_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH Hviprio2Module.rdata g=%h i=%h", Hviprio2Module_g_rdata, Hviprio2Module_i_rdata); end
      checks++; if (Hviprio2Module_g_regOut_ALL !== Hviprio2Module_i_regOut_ALL) begin errors++; if (errors < 20) $display("MISMATCH Hviprio2Module.regOut_ALL g=%h i=%h", Hviprio2Module_g_regOut_ALL, Hviprio2Module_i_regOut_ALL); end
    end
  end
  always @(negedge clock) begin
    cycle <= cycle + 1;
    DpcModule_reset <= (cycle < 4);
    DpcModule_w_wen <= $urandom;
    DpcModule_w_wdata <= {$urandom, $urandom};
    DpcModule_trapToD_dpc_valid <= $urandom;
    DpcModule_trapToD_dpc_bits_epc <= {$urandom, $urandom};
    DretEventModule_valid <= $urandom;
    DretEventModule_in_dcsr_V <= $urandom;
    DretEventModule_in_dcsr_PRV <= $urandom;
    DretEventModule_in_dpc_epc <= {$urandom, $urandom};
    DretEventModule_in_mstatus_MPRV <= $urandom;
    DretEventModule_in_mstatus_SDT <= $urandom;
    DretEventModule_in_mstatus_MDT <= $urandom;
    DretEventModule_in_vsstatus_SDT <= $urandom;
    DretEventModule_in_satp_MODE <= $urandom;
    DretEventModule_in_vsatp_MODE <= $urandom;
    DretEventModule_in_hgatp_MODE <= $urandom;
    HcounterenModule_reset <= (cycle < 4);
    HcounterenModule_w_wen <= $urandom;
    HcounterenModule_w_wdata <= {$urandom, $urandom};
    HedelegModule_reset <= (cycle < 4);
    HedelegModule_w_wen <= $urandom;
    HedelegModule_w_wdata <= {$urandom, $urandom};
    HenvcfgModule_reset <= (cycle < 4);
    HenvcfgModule_w_wen <= $urandom;
    HenvcfgModule_w_wdata <= {$urandom, $urandom};
    HenvcfgModule_menvcfg_STCE <= $urandom;
    HenvcfgModule_menvcfg_PBMTE <= $urandom;
    HenvcfgModule_menvcfg_DTE <= $urandom;
    HgatpModule_reset <= (cycle < 4);
    HgatpModule_w_wen <= $urandom;
    HgatpModule_w_wdata <= {$urandom, $urandom};
    HidelegModule_reset <= (cycle < 4);
    HidelegModule_w_wen <= $urandom;
    HidelegModule_w_wdata <= {$urandom, $urandom};
    HidelegModule_mideleg_SSI <= $urandom;
    HidelegModule_mideleg_STI <= $urandom;
    HidelegModule_mideleg_SEI <= $urandom;
    HidelegModule_mideleg_LCOFI <= $urandom;
    Hstateen0Module_reset <= (cycle < 4);
    Hstateen0Module_w_wen <= $urandom;
    Hstateen0Module_w_wdata <= {$urandom, $urandom};
    Hstateen0Module_fromMstateen0_SE0 <= $urandom;
    Hstateen0Module_fromMstateen0_ENVCFG <= $urandom;
    Hstateen0Module_fromMstateen0_CSRIND <= $urandom;
    Hstateen0Module_fromMstateen0_AIA <= $urandom;
    Hstateen0Module_fromMstateen0_IMSIC <= $urandom;
    Hstateen0Module_fromMstateen0_CONTEXT <= $urandom;
    Hstateen0Module_fromMstateen0_C <= $urandom;
    Hstateen1Module_w_wen <= $urandom;
    Hstateen1Module_w_wdata <= {$urandom, $urandom};
    Hstateen1Module_fromMstateen1_SE <= $urandom;
    Hstateen2Module_w_wen <= $urandom;
    Hstateen2Module_w_wdata <= {$urandom, $urandom};
    Hstateen2Module_fromMstateen2_SE <= $urandom;
    Hstateen3Module_w_wen <= $urandom;
    Hstateen3Module_w_wdata <= {$urandom, $urandom};
    Hstateen3Module_fromMstateen3_SE <= $urandom;
    HstatusModule_reset <= (cycle < 4);
    HstatusModule_w_wen <= $urandom;
    HstatusModule_w_wdata <= {$urandom, $urandom};
    HstatusModule_retFromS_hstatus_valid <= $urandom;
    HstatusModule_retFromS_hstatus_bits_SPV <= $urandom;
    HstatusModule_trapToHS_hstatus_valid <= $urandom;
    HstatusModule_trapToHS_hstatus_bits_GVA <= $urandom;
    HstatusModule_trapToHS_hstatus_bits_SPV <= $urandom;
    HstatusModule_trapToHS_hstatus_bits_SPVP <= $urandom;
    HtimedeltaModule_reset <= (cycle < 4);
    HtimedeltaModule_w_wen <= $urandom;
    HtimedeltaModule_w_wdata <= {$urandom, $urandom};
    HtinstModule_reset <= (cycle < 4);
    HtinstModule_w_wen <= $urandom;
    HtinstModule_w_wdata <= {$urandom, $urandom};
    HtinstModule_trapToHS_htinst_valid <= $urandom;
    HtinstModule_trapToHS_htinst_bits_ALL <= {$urandom, $urandom};
    HtvalModule_reset <= (cycle < 4);
    HtvalModule_w_wen <= $urandom;
    HtvalModule_w_wdata <= {$urandom, $urandom};
    HtvalModule_trapToHS_htval_valid <= $urandom;
    HtvalModule_trapToHS_htval_bits_ALL <= {$urandom, $urandom};
    HvictlModule_reset <= (cycle < 4);
    HvictlModule_w_wen <= $urandom;
    HvictlModule_w_wdata <= {$urandom, $urandom};
    Hviprio1Module_reset <= (cycle < 4);
    Hviprio1Module_w_wen <= $urandom;
    Hviprio1Module_w_wdata <= {$urandom, $urandom};
    Hviprio2Module_reset <= (cycle < 4);
    Hviprio2Module_w_wen <= $urandom;
    Hviprio2Module_w_wdata <= {$urandom, $urandom};
  end
  initial begin
    cycle=0;
    DpcModule_reset=1;
    HcounterenModule_reset=1;
    HedelegModule_reset=1;
    HenvcfgModule_reset=1;
    HgatpModule_reset=1;
    HidelegModule_reset=1;
    Hstateen0Module_reset=1;
    HstatusModule_reset=1;
    HtimedeltaModule_reset=1;
    HtinstModule_reset=1;
    HtvalModule_reset=1;
    HvictlModule_reset=1;
    Hviprio1Module_reset=1;
    Hviprio2Module_reset=1;
    ncycles=200000;
    void'($value$plusargs("ncycles=%d", ncycles));
    repeat (ncycles) @(posedge clock);
    if (checks==0 || errors!=0) begin $display("TEST FAILED checks=%0d errors=%0d",checks,errors); $finish(1); end
    $display("TEST PASSED checks=%0d errors=%0d",checks,errors); $finish;
  end
endmodule
