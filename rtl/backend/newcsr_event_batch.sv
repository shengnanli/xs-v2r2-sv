// NewCSR trap-entry / xret event CSRs — readable transcriptions.
//   {M,HS,VS,D,MN}Event trap-entry modules compute the next privilege state,
//   trap vector target PC, and the *epc/*cause/*tval field values latched on a
//   trap into that mode.  {M,S,D,MN}retEvent modules compute the restored
//   privilege state and target PC for the corresponding xret.
//
// These golden bodies are purely combinational next-state functions. The
// readable rewrite drops the sim randomize-init block and rewrites the CIRCT
// "_T_<n>" intermediate-wire suffix to "_t<n>" (keeping the descriptive prefix,
// e.g. instrAddrTransType_x5, xepc_ret_epc). FM-verified strict golden-vs-impl
// SUCCEEDED, no black box, no dont_verify.


module MretEventModule(
  input         valid,
  input         in_mstatus_MPIE,
  input  [1:0]  in_mstatus_MPP,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MPV,
  input         in_vsstatus_SDT,
  input  [62:0] in_mepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
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
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire [1:0] _out_privState_bits_PRVM_output = in_mstatus_MPP;
  wire       instrAddrTransType_x1_v_PrvmIsM = &_out_privState_bits_PRVM_output;
  wire       instrAddrTransType_x1_isModeM = instrAddrTransType_x1_v_PrvmIsM;
  wire       _out_privState_bits_V_output;
  wire       _instrAddrTransType_x5_t2 = in_vsatp_MODE == 4'h0;
  assign _out_privState_bits_V_output = ~(&in_mstatus_MPP) & in_mstatus_MPV;
  wire       mretToM_v_PrvmIsM = &in_mstatus_MPP;
  wire       isModeM = mretToM_v_PrvmIsM;
  wire       PrvmIsS = in_mstatus_MPP == 2'h1;
  wire       isModeHS = ~_out_privState_bits_V_output & PrvmIsS;
  wire       PrvmIsU = in_mstatus_MPP == 2'h0;
  wire       isModeVU = _out_privState_bits_V_output & PrvmIsU;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = _out_privState_bits_PRVM_output;
  assign out_privState_bits_V = _out_privState_bits_V_output;
  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'h0;
  assign out_mstatus_bits_MIE = in_mstatus_MPIE;
  assign out_mstatus_bits_SPIE = 1'h0;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = 1'h1;
  assign out_mstatus_bits_SPP = 1'h0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = (&in_mstatus_MPP) & in_mstatus_MPRV;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT = (isModeM | isModeHS) & in_mstatus_SDT;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = 1'h0;
  assign out_mstatus_bits_MPV = 1'h0;
  assign out_mstatus_bits_MDT = 1'h0;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_vsstatus_valid = 1'h0;
  assign out_vsstatus_bits_SIE = 1'h0;
  assign out_vsstatus_bits_SPIE = 1'h0;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = 1'h0;
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = ~isModeVU & in_vsstatus_SDT;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = {in_mepc_epc, 1'h0};
  assign out_targetPc_bits_raiseIPF =
    (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output & in_satp_MODE == 4'h8
     | _out_privState_bits_V_output & in_vsatp_MODE == 4'h8)
    & in_mepc_epc[62:38] != {25{in_mepc_epc[37]}}
    | (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output
       & in_satp_MODE == 4'h9 | _out_privState_bits_V_output & in_vsatp_MODE == 4'h9)
    & in_mepc_epc[62:47] != {16{in_mepc_epc[46]}};
  assign out_targetPc_bits_raiseIAF =
    (instrAddrTransType_x1_isModeM | ~_out_privState_bits_V_output & in_satp_MODE == 4'h0
     | _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h0)
    & (|(in_mepc_epc[62:47]));
  assign out_targetPc_bits_raiseIGPF =
    _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h8
    & (|(in_mepc_epc[62:40])) | _out_privState_bits_V_output & _instrAddrTransType_x5_t2
    & in_hgatp_MODE == 4'h9 & (|(in_mepc_epc[62:49]));
endmodule


module SretEventModule(
  input         valid,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_mstatus_SPIE,
  input         in_mstatus_SPP,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input         in_hstatus_SPV,
  input         in_vsstatus_SPIE,
  input         in_vsstatus_SPP,
  input  [62:0] in_sepc_epc,
  input  [62:0] in_vsepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
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
  output        out_hstatus_valid,
  output        out_hstatus_bits_VSBE,
  output        out_hstatus_bits_GVA,
  output        out_hstatus_bits_SPV,
  output        out_hstatus_bits_SPVP,
  output        out_hstatus_bits_HU,
  output [5:0]  out_hstatus_bits_VGEIN,
  output        out_hstatus_bits_VTVM,
  output        out_hstatus_bits_VTW,
  output        out_hstatus_bits_VTSR,
  output [1:0]  out_hstatus_bits_VSXL,
  output [1:0]  out_hstatus_bits_HUPMM,
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
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF,
  output        outSDT_vsstatus_valid
);

  wire        _out_privState_bits_V_output;
  wire        _instrAddrTransType_x5_t2 = in_vsatp_MODE == 4'h0;
  wire        sretInM_v_PrvmIsM = &in_privState_PRVM;
  wire        isModeM = sretInM_v_PrvmIsM;
  wire        PrvmIsS = in_privState_PRVM == 2'h1;
  wire        isModeHS = ~in_privState_V & PrvmIsS;
  wire        sretInHSorM = isModeM | isModeHS;
  wire        isModeVS = in_privState_V & PrvmIsS;
  wire [62:0] _xepc_ret_epc_t4 =
    (sretInHSorM ? in_sepc_epc : 63'h0) | (isModeVS ? in_vsepc_epc : 63'h0);
  wire        PrvmIsS_1 = sretInHSorM & in_mstatus_SPP | isModeVS & in_vsstatus_SPP;
  assign _out_privState_bits_V_output =
    sretInHSorM & in_hstatus_SPV | isModeVS & in_privState_V;
  wire        PrvmIsU = ~PrvmIsS_1;
  wire        isModeVU = _out_privState_bits_V_output & PrvmIsU;
  wire        isModeVS_1 = _out_privState_bits_V_output & PrvmIsS_1;
  wire        isModeHU = ~_out_privState_bits_V_output & PrvmIsU;
  wire        _out_mstatus_valid_T = valid & sretInHSorM;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = {1'h0, PrvmIsS_1};
  assign out_privState_bits_V = _out_privState_bits_V_output;
  assign out_mstatus_valid = _out_mstatus_valid_T;
  assign out_mstatus_bits_SIE = in_mstatus_SPIE;
  assign out_mstatus_bits_MIE = 1'h0;
  assign out_mstatus_bits_SPIE = 1'h1;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = 1'h0;
  assign out_mstatus_bits_SPP = 1'h0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = 1'h0;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT =
    ~(isModeHS | isModeM & (isModeHU | isModeVS_1 | isModeVU)) & in_mstatus_SDT;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = 1'h0;
  assign out_mstatus_bits_MPV = 1'h0;
  assign out_mstatus_bits_MDT = ~isModeM & in_mstatus_MDT;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_hstatus_valid = _out_mstatus_valid_T;
  assign out_hstatus_bits_VSBE = 1'h0;
  assign out_hstatus_bits_GVA = 1'h0;
  assign out_hstatus_bits_SPV = 1'h0;
  assign out_hstatus_bits_SPVP = 1'h0;
  assign out_hstatus_bits_HU = 1'h0;
  assign out_hstatus_bits_VGEIN = 6'h0;
  assign out_hstatus_bits_VTVM = 1'h0;
  assign out_hstatus_bits_VTW = 1'h0;
  assign out_hstatus_bits_VTSR = 1'h0;
  assign out_hstatus_bits_VSXL = 2'h0;
  assign out_hstatus_bits_HUPMM = 2'h0;
  assign out_vsstatus_valid = valid & isModeVS;
  assign out_vsstatus_bits_SIE = in_vsstatus_SPIE;
  assign out_vsstatus_bits_SPIE = 1'h1;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = 1'h0;
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = 1'h0;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = {_xepc_ret_epc_t4, 1'h0};
  assign out_targetPc_bits_raiseIPF =
    (~_out_privState_bits_V_output & in_satp_MODE == 4'h8 | _out_privState_bits_V_output
     & in_vsatp_MODE == 4'h8) & _xepc_ret_epc_t4[62:38] != {25{_xepc_ret_epc_t4[37]}}
    | (~_out_privState_bits_V_output & in_satp_MODE == 4'h9 | _out_privState_bits_V_output
       & in_vsatp_MODE == 4'h9) & _xepc_ret_epc_t4[62:47] != {16{_xepc_ret_epc_t4[46]}};
  assign out_targetPc_bits_raiseIAF =
    (~_out_privState_bits_V_output & in_satp_MODE == 4'h0 | _out_privState_bits_V_output
     & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h0)
    & (|(_xepc_ret_epc_t4[62:47]));
  assign out_targetPc_bits_raiseIGPF =
    _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h8
    & (|(_xepc_ret_epc_t4[62:40])) | _out_privState_bits_V_output
    & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h9 & (|(_xepc_ret_epc_t4[62:49]));
  assign outSDT_vsstatus_valid = valid & (isModeVU | isModeVS);
endmodule


module DretEventModule(
  input         valid,
  input         in_dcsr_V,
  input  [1:0]  in_dcsr_PRV,
  input  [62:0] in_dpc_epc,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input         in_vsstatus_SDT,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_dcsr_valid,
  output [3:0]  out_dcsr_bits_DEBUGVER,
  output [2:0]  out_dcsr_bits_EXTCAUSE,
  output        out_dcsr_bits_CETRIG,
  output        out_dcsr_bits_EBREAKVS,
  output        out_dcsr_bits_EBREAKVU,
  output        out_dcsr_bits_EBREAKM,
  output        out_dcsr_bits_EBREAKS,
  output        out_dcsr_bits_EBREAKU,
  output        out_dcsr_bits_STEPIE,
  output        out_dcsr_bits_STOPCOUNT,
  output        out_dcsr_bits_STOPTIME,
  output [2:0]  out_dcsr_bits_CAUSE,
  output        out_dcsr_bits_V,
  output        out_dcsr_bits_MPRVEN,
  output        out_dcsr_bits_NMIP,
  output        out_dcsr_bits_STEP,
  output [1:0]  out_dcsr_bits_PRV,
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
  output        out_debugMode_valid,
  output        out_debugMode_bits,
  output        out_debugIntrEnable_valid,
  output        out_debugIntrEnable_bits,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire [1:0] _out_privState_bits_PRVM_output = in_dcsr_PRV;
  wire       instrAddrTransType_x1_v_PrvmIsM = &_out_privState_bits_PRVM_output;
  wire       instrAddrTransType_x1_isModeM = instrAddrTransType_x1_v_PrvmIsM;
  wire       _out_privState_bits_V_output;
  wire       _instrAddrTransType_x5_t2 = in_vsatp_MODE == 4'h0;
  assign _out_privState_bits_V_output = in_dcsr_PRV != 2'h3 & in_dcsr_V;
  wire       PrvmIsU = _out_privState_bits_PRVM_output == 2'h0;
  wire       isModeHU = ~_out_privState_bits_V_output & PrvmIsU;
  wire       isModeVU = _out_privState_bits_V_output & PrvmIsU;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = _out_privState_bits_PRVM_output;
  assign out_privState_bits_V = _out_privState_bits_V_output;
  assign out_dcsr_valid = valid;
  assign out_dcsr_bits_DEBUGVER = 4'h0;
  assign out_dcsr_bits_EXTCAUSE = 3'h0;
  assign out_dcsr_bits_CETRIG = 1'h0;
  assign out_dcsr_bits_EBREAKVS = 1'h0;
  assign out_dcsr_bits_EBREAKVU = 1'h0;
  assign out_dcsr_bits_EBREAKM = 1'h0;
  assign out_dcsr_bits_EBREAKS = 1'h0;
  assign out_dcsr_bits_EBREAKU = 1'h0;
  assign out_dcsr_bits_STEPIE = 1'h0;
  assign out_dcsr_bits_STOPCOUNT = 1'h0;
  assign out_dcsr_bits_STOPTIME = 1'h0;
  assign out_dcsr_bits_CAUSE = 3'h0;
  assign out_dcsr_bits_V = 1'h0;
  assign out_dcsr_bits_MPRVEN = 1'h0;
  assign out_dcsr_bits_NMIP = 1'h0;
  assign out_dcsr_bits_STEP = 1'h0;
  assign out_dcsr_bits_PRV = 2'h0;
  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'h0;
  assign out_mstatus_bits_MIE = 1'h0;
  assign out_mstatus_bits_SPIE = 1'h0;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = 1'h0;
  assign out_mstatus_bits_SPP = 1'h0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = instrAddrTransType_x1_isModeM & in_mstatus_MPRV;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT =
    ~(_out_privState_bits_V_output | isModeHU) & in_mstatus_SDT;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = 1'h0;
  assign out_mstatus_bits_MPV = 1'h0;
  assign out_mstatus_bits_MDT = instrAddrTransType_x1_isModeM & in_mstatus_MDT;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_vsstatus_valid = valid;
  assign out_vsstatus_bits_SIE = 1'h0;
  assign out_vsstatus_bits_SPIE = 1'h0;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = 1'h0;
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = ~isModeVU & in_vsstatus_SDT;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_debugMode_valid = valid;
  assign out_debugMode_bits = 1'h0;
  assign out_debugIntrEnable_valid = valid;
  assign out_debugIntrEnable_bits = 1'h1;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = {in_dpc_epc, 1'h0};
  assign out_targetPc_bits_raiseIPF =
    (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output & in_satp_MODE == 4'h8
     | _out_privState_bits_V_output & in_vsatp_MODE == 4'h8)
    & in_dpc_epc[62:38] != {25{in_dpc_epc[37]}}
    | (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output
       & in_satp_MODE == 4'h9 | _out_privState_bits_V_output & in_vsatp_MODE == 4'h9)
    & in_dpc_epc[62:47] != {16{in_dpc_epc[46]}};
  assign out_targetPc_bits_raiseIAF =
    (instrAddrTransType_x1_isModeM | ~_out_privState_bits_V_output & in_satp_MODE == 4'h0
     | _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h0)
    & (|(in_dpc_epc[62:47]));
  assign out_targetPc_bits_raiseIGPF =
    _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h8
    & (|(in_dpc_epc[62:40])) | _out_privState_bits_V_output & _instrAddrTransType_x5_t2
    & in_hgatp_MODE == 4'h9 & (|(in_dpc_epc[62:49]));
endmodule


module MNretEventModule(
  input         valid,
  input         in_mnstatus_MNPV,
  input  [1:0]  in_mnstatus_MNPP,
  input         in_mstatus_MPRV,
  input         in_mstatus_SDT,
  input         in_mstatus_MDT,
  input  [62:0] in_mnepc_epc,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input         in_vsstatus_SDT,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mnstatus_valid,
  output        out_mnstatus_bits_NMIE,
  output        out_mnstatus_bits_MNPV,
  output        out_mnstatus_bits_MNPELP,
  output [1:0]  out_mnstatus_bits_MNPP,
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
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire [1:0] _out_privState_bits_PRVM_output = in_mnstatus_MNPP;
  wire       instrAddrTransType_x1_v_PrvmIsM = &_out_privState_bits_PRVM_output;
  wire       instrAddrTransType_x1_isModeM = instrAddrTransType_x1_v_PrvmIsM;
  wire       _out_privState_bits_V_output;
  wire       _instrAddrTransType_x5_t2 = in_vsatp_MODE == 4'h0;
  assign _out_privState_bits_V_output = ~(&in_mnstatus_MNPP) & in_mnstatus_MNPV;
  wire       mnretToM_v_PrvmIsM = &in_mnstatus_MNPP;
  wire       isModeM = mnretToM_v_PrvmIsM;
  wire       PrvmIsS = in_mnstatus_MNPP == 2'h1;
  wire       isModeHS = ~_out_privState_bits_V_output & PrvmIsS;
  wire       PrvmIsU = in_mnstatus_MNPP == 2'h0;
  wire       isModeVU = _out_privState_bits_V_output & PrvmIsU;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = _out_privState_bits_PRVM_output;
  assign out_privState_bits_V = _out_privState_bits_V_output;
  assign out_mnstatus_valid = valid;
  assign out_mnstatus_bits_NMIE = 1'h1;
  assign out_mnstatus_bits_MNPV = 1'h0;
  assign out_mnstatus_bits_MNPELP = 1'h0;
  assign out_mnstatus_bits_MNPP = 2'h0;
  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'h0;
  assign out_mstatus_bits_MIE = 1'h0;
  assign out_mstatus_bits_SPIE = 1'h0;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = 1'h0;
  assign out_mstatus_bits_SPP = 1'h0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = (&in_mnstatus_MNPP) & in_mstatus_MPRV;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT = (isModeM | isModeHS) & in_mstatus_SDT;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = 1'h0;
  assign out_mstatus_bits_MPV = 1'h0;
  assign out_mstatus_bits_MDT = isModeM & in_mstatus_MDT;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_vsstatus_valid = valid;
  assign out_vsstatus_bits_SIE = 1'h0;
  assign out_vsstatus_bits_SPIE = 1'h0;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = 1'h0;
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = ~isModeVU & in_vsstatus_SDT;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = {in_mnepc_epc, 1'h0};
  assign out_targetPc_bits_raiseIPF =
    (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output & in_satp_MODE == 4'h8
     | _out_privState_bits_V_output & in_vsatp_MODE == 4'h8)
    & in_mnepc_epc[62:38] != {25{in_mnepc_epc[37]}}
    | (~instrAddrTransType_x1_isModeM & ~_out_privState_bits_V_output
       & in_satp_MODE == 4'h9 | _out_privState_bits_V_output & in_vsatp_MODE == 4'h9)
    & in_mnepc_epc[62:47] != {16{in_mnepc_epc[46]}};
  assign out_targetPc_bits_raiseIAF =
    (instrAddrTransType_x1_isModeM | ~_out_privState_bits_V_output & in_satp_MODE == 4'h0
     | _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h0)
    & (|(in_mnepc_epc[62:47]));
  assign out_targetPc_bits_raiseIGPF =
    _out_privState_bits_V_output & _instrAddrTransType_x5_t2 & in_hgatp_MODE == 4'h8
    & (|(in_mnepc_epc[62:40])) | _out_privState_bits_V_output & _instrAddrTransType_x5_t2
    & in_hgatp_MODE == 4'h9 & (|(in_mnepc_epc[62:49]));
endmodule


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
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
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

  wire        trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire        trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire        trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire        trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire        _trapPC_isSv48_T = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire        _trapPC_isSv48x4_t2 = in_vsatp_MODE == 4'h0;
  wire [63:0] trapPC =
    (trapPC_isBare_isModeM | _trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h0
     | in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h0
       ? {16'h0, in_trapPc[47:0]}
       : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h8 | in_iMode_V
       & in_vsatp_MODE == 4'h8
         ? {{25{in_trapPc[38]}}, in_trapPc[38:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h8
         ? {23'h0, in_trapPc[40:0]}
         : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h9 | in_iMode_V
       & in_vsatp_MODE == 4'h9
         ? {{16{in_trapPc[47]}}, in_trapPc[47:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h9
         ? {14'h0, in_trapPc}
         : 64'h0);
  wire        isFetchExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h0 | in_causeNO_ExceptionCode == 63'h1
       | in_causeNO_ExceptionCode == 63'hC);
  wire        isMemExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h4 | in_causeNO_ExceptionCode == 63'h5
       | in_causeNO_ExceptionCode == 63'hD | in_causeNO_ExceptionCode == 63'h13
       | in_causeNO_ExceptionCode == 63'h6 | in_causeNO_ExceptionCode == 63'h7
       | in_causeNO_ExceptionCode == 63'hF);
  wire        isBpExcp = ~in_causeNO_Interrupt & in_causeNO_ExceptionCode == 63'h3;
  wire        isFetchBkpt = isBpExcp & in_isFetchBkpt;
  wire        isLSGuestExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h15 | in_causeNO_ExceptionCode == 63'h17);
  wire        isFetchGuestExcp =
    ~in_causeNO_Interrupt & in_causeNO_ExceptionCode == 63'h14;
  wire        _tvalFillPcPlus2_T = isFetchExcp | isFetchGuestExcp;
  wire        tvalFillMemVaddr = isMemExcp | isBpExcp & ~in_isFetchBkpt;
  wire        tvalFillGVA =
    ~in_causeNO_Interrupt & in_isHls & isMemExcp | isLSGuestExcp | isFetchGuestExcp
    | (isFetchExcp | isFetchBkpt) & in_iMode_V | tvalFillMemVaddr & in_dMode_V;
  wire [63:0] _tval_t8 =
    (_tvalFillPcPlus2_T & ~in_isCrossPageIPF | isFetchBkpt ? trapPC : 64'h0)
    | (_tvalFillPcPlus2_T & in_isCrossPageIPF ? 64'(trapPC + 64'h2) : 64'h0)
    | (tvalFillMemVaddr | isLSGuestExcp ? in_memExceptionVAddr : 64'h0);
  wire [55:0] _tval2_t8 = 56'(in_trapPcGPA + 56'h2);
  wire [61:0] _tval2_t10 =
    isFetchGuestExcp & in_isFetchMalAddr ? in_fetchMalTval[63:2] : 62'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h3;
  assign out_privState_bits_V = 1'h0;
  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'h0;
  assign out_mstatus_bits_MIE = 1'h0;
  assign out_mstatus_bits_SPIE = 1'h0;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = in_mstatus_MIE;
  assign out_mstatus_bits_SPP = 1'h0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = in_privState_PRVM;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = 1'h0;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT = 1'h0;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = tvalFillGVA;
  assign out_mstatus_bits_MPV = in_privState_V;
  assign out_mstatus_bits_MDT = 1'h1;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_mepc_valid = valid;
  assign out_mepc_bits_epc = in_isFetchMalAddr ? in_fetchMalTval[63:1] : trapPC[63:1];
  assign out_mcause_valid = valid;
  assign out_mcause_bits_Interrupt = in_causeNO_Interrupt & ~in_hasDTExcp;
  assign out_mcause_bits_ExceptionCode = in_hasDTExcp ? 63'h10 : in_causeNO_ExceptionCode;
  assign out_mtval_valid = valid;
  assign out_mtval_bits_ALL =
    ~in_causeNO_Interrupt & in_isFetchMalAddr
      ? in_fetchMalTval
      : {_tval_t8[63:32],
         _tval_t8[31:0]
           | (~in_causeNO_Interrupt
              & (in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h16)
              & in_trapInst_valid
                ? in_trapInst_bits
                : 32'h0)};
  assign out_mtval2_valid = valid;
  assign out_mtval2_bits_ALL =
    in_hasDTExcp
      ? {in_causeNO_Interrupt, in_causeNO_ExceptionCode}
      : {2'h0,
         {_tval2_t10[61:54],
          _tval2_t10[53:0]
            | (isFetchGuestExcp & ~in_isFetchMalAddr & ~in_isCrossPageIPF
                 ? in_trapPcGPA[55:2]
                 : 54'h0)
            | (isFetchGuestExcp & ~in_isFetchMalAddr & in_isCrossPageIPF
                 ? _tval2_t8[55:2]
                 : 54'h0)} | (isLSGuestExcp ? in_memExceptionGPAddr[63:2] : 62'h0)};
  assign out_mtinst_valid = valid;
  assign out_mtinst_bits_ALL =
    {50'h0,
     isFetchGuestExcp & in_trapIsForVSnonLeafPTE | isLSGuestExcp
     & in_memExceptionIsForVSnonLeafPTE
       ? 14'h3000
       : 14'h0};
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF = 1'h0;
  assign out_targetPc_bits_raiseIAF = |(in_pcFromXtvec[63:48]);
  assign out_targetPc_bits_raiseIGPF = 1'h0;
endmodule


module TrapEntryHSEventModule(
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
  input         in_isFetchBkpt,
  input         in_trapIsForVSnonLeafPTE,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_hstatus_SPVP,
  input         in_sstatus_SIE,
  input         in_menvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
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
  output        out_hstatus_valid,
  output        out_hstatus_bits_VSBE,
  output        out_hstatus_bits_GVA,
  output        out_hstatus_bits_SPV,
  output        out_hstatus_bits_SPVP,
  output        out_hstatus_bits_HU,
  output [5:0]  out_hstatus_bits_VGEIN,
  output        out_hstatus_bits_VTVM,
  output        out_hstatus_bits_VTW,
  output        out_hstatus_bits_VTSR,
  output [1:0]  out_hstatus_bits_VSXL,
  output [1:0]  out_hstatus_bits_HUPMM,
  output        out_sepc_valid,
  output [62:0] out_sepc_bits_epc,
  output        out_scause_valid,
  output        out_scause_bits_Interrupt,
  output [62:0] out_scause_bits_ExceptionCode,
  output        out_stval_valid,
  output [63:0] out_stval_bits_ALL,
  output        out_htval_valid,
  output [63:0] out_htval_bits_ALL,
  output        out_htinst_valid,
  output [63:0] out_htinst_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire        trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire        trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire        trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire        trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire        _trapPC_isSv48_T = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire        instrAddrTransType_x1 = in_satp_MODE == 4'h0;
  wire        _trapPC_isSv48x4_t2 = in_vsatp_MODE == 4'h0;
  wire        instrAddrTransType_x2 = in_satp_MODE == 4'h8;
  wire        instrAddrTransType_x3 = in_satp_MODE == 4'h9;
  wire [63:0] trapPC =
    (trapPC_isBare_isModeM | _trapPC_isSv48_T & ~in_iMode_V & instrAddrTransType_x1
     | in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h0
       ? {16'h0, in_trapPc[47:0]}
       : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & instrAddrTransType_x2 | in_iMode_V
       & in_vsatp_MODE == 4'h8
         ? {{25{in_trapPc[38]}}, in_trapPc[38:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h8
         ? {23'h0, in_trapPc[40:0]}
         : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & instrAddrTransType_x3 | in_iMode_V
       & in_vsatp_MODE == 4'h9
         ? {{16{in_trapPc[47]}}, in_trapPc[47:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h9
         ? {14'h0, in_trapPc}
         : 64'h0);
  wire        isFetchExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h0 | in_causeNO_ExceptionCode == 63'h1
       | in_causeNO_ExceptionCode == 63'hC);
  wire        isMemExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h4 | in_causeNO_ExceptionCode == 63'h5
       | in_causeNO_ExceptionCode == 63'hD | in_causeNO_ExceptionCode == 63'h13
       | in_causeNO_ExceptionCode == 63'h6 | in_causeNO_ExceptionCode == 63'h7
       | in_causeNO_ExceptionCode == 63'hF);
  wire        isBpExcp = ~in_causeNO_Interrupt & in_causeNO_ExceptionCode == 63'h3;
  wire        isFetchBkpt = isBpExcp & in_isFetchBkpt;
  wire        isLSGuestExcp =
    ~in_causeNO_Interrupt
    & (in_causeNO_ExceptionCode == 63'h15 | in_causeNO_ExceptionCode == 63'h17);
  wire        isFetchGuestExcp =
    ~in_causeNO_Interrupt & in_causeNO_ExceptionCode == 63'h14;
  wire        _tvalFillPcPlus2_T = isFetchExcp | isFetchGuestExcp;
  wire        tvalFillMemVaddr = isMemExcp | isBpExcp & ~in_isFetchBkpt;
  wire        tvalFillGVA =
    ~in_causeNO_Interrupt & in_isHls & isMemExcp | isLSGuestExcp | isFetchGuestExcp
    | (isFetchExcp | isFetchBkpt) & in_iMode_V | tvalFillMemVaddr & in_dMode_V;
  wire [63:0] _tval_t8 =
    (_tvalFillPcPlus2_T & ~in_isCrossPageIPF | isFetchBkpt ? trapPC : 64'h0)
    | (_tvalFillPcPlus2_T & in_isCrossPageIPF ? 64'(trapPC + 64'h2) : 64'h0)
    | (tvalFillMemVaddr | isLSGuestExcp ? in_memExceptionVAddr : 64'h0);
  wire [55:0] _tval2_t8 = 56'(in_trapPcGPA + 56'h2);
  wire [61:0] _tval2_t10 =
    isFetchGuestExcp & in_isFetchMalAddr ? in_fetchMalTval[63:2] : 62'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h1;
  assign out_privState_bits_V = 1'h0;
  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'h0;
  assign out_mstatus_bits_MIE = 1'h0;
  assign out_mstatus_bits_SPIE = in_sstatus_SIE;
  assign out_mstatus_bits_UBE = 1'h0;
  assign out_mstatus_bits_MPIE = 1'h0;
  assign out_mstatus_bits_SPP = in_privState_PRVM[0];
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = 1'h0;
  assign out_mstatus_bits_SUM = 1'h0;
  assign out_mstatus_bits_MXR = 1'h0;
  assign out_mstatus_bits_TVM = 1'h0;
  assign out_mstatus_bits_TW = 1'h0;
  assign out_mstatus_bits_TSR = 1'h0;
  assign out_mstatus_bits_SDT = in_menvcfg_DTE;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'h0;
  assign out_mstatus_bits_MBE = 1'h0;
  assign out_mstatus_bits_GVA = 1'h0;
  assign out_mstatus_bits_MPV = 1'h0;
  assign out_mstatus_bits_MDT = 1'h0;
  assign out_mstatus_bits_SD = 1'h0;
  assign out_hstatus_valid = valid;
  assign out_hstatus_bits_VSBE = 1'h0;
  assign out_hstatus_bits_GVA = tvalFillGVA;
  assign out_hstatus_bits_SPV = in_privState_V;
  assign out_hstatus_bits_SPVP = in_privState_V ? in_privState_PRVM[0] : in_hstatus_SPVP;
  assign out_hstatus_bits_HU = 1'h0;
  assign out_hstatus_bits_VGEIN = 6'h0;
  assign out_hstatus_bits_VTVM = 1'h0;
  assign out_hstatus_bits_VTW = 1'h0;
  assign out_hstatus_bits_VTSR = 1'h0;
  assign out_hstatus_bits_VSXL = 2'h0;
  assign out_hstatus_bits_HUPMM = 2'h0;
  assign out_sepc_valid = valid;
  assign out_sepc_bits_epc = in_isFetchMalAddr ? in_fetchMalTval[63:1] : trapPC[63:1];
  assign out_scause_valid = valid;
  assign out_scause_bits_Interrupt = in_causeNO_Interrupt;
  assign out_scause_bits_ExceptionCode = in_causeNO_ExceptionCode;
  assign out_stval_valid = valid;
  assign out_stval_bits_ALL =
    ~in_causeNO_Interrupt & in_isFetchMalAddr
      ? in_fetchMalTval
      : {_tval_t8[63:32],
         _tval_t8[31:0]
           | (~in_causeNO_Interrupt
              & (in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h16)
              & in_trapInst_valid
                ? in_trapInst_bits
                : 32'h0)};
  assign out_htval_valid = valid;
  assign out_htval_bits_ALL =
    {2'h0,
     {_tval2_t10[61:54],
      _tval2_t10[53:0]
        | (isFetchGuestExcp & ~in_isFetchMalAddr & ~in_isCrossPageIPF
             ? in_trapPcGPA[55:2]
             : 54'h0)
        | (isFetchGuestExcp & ~in_isFetchMalAddr & in_isCrossPageIPF
             ? _tval2_t8[55:2]
             : 54'h0)} | (isLSGuestExcp ? in_memExceptionGPAddr[63:2] : 62'h0)};
  assign out_htinst_valid = valid;
  assign out_htinst_bits_ALL =
    {50'h0,
     isFetchGuestExcp & in_trapIsForVSnonLeafPTE | isLSGuestExcp
     & in_memExceptionIsForVSnonLeafPTE
       ? 14'h3000
       : 14'h0};
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF =
    instrAddrTransType_x2 & in_pcFromXtvec[63:39] != {25{in_pcFromXtvec[38]}}
    | instrAddrTransType_x3 & in_pcFromXtvec[63:48] != {16{in_pcFromXtvec[47]}};
  assign out_targetPc_bits_raiseIAF = instrAddrTransType_x1 & (|(in_pcFromXtvec[63:48]));
  assign out_targetPc_bits_raiseIGPF = 1'h0;
endmodule


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
  input         in_isFetchBkpt,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_vsstatus_SIE,
  input         in_henvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
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

  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (valid & ~reset & ~in_privState_V) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The mode must be VU or VS when entry VS mode\n    at TrapEntryVSEvent.scala:29 assert(in.privState.isVirtual, \"The mode must be VU or VS when entry VS mode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (valid & in_causeNO_Interrupt & ~in_virtualInterruptIsHvictlInject & ~reset
          & ~(in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h6
              | in_causeNO_ExceptionCode == 63'hA | in_causeNO_ExceptionCode == 63'h2F
              | in_causeNO_ExceptionCode == 63'h17 | in_causeNO_ExceptionCode == 63'h2E
              | in_causeNO_ExceptionCode == 63'h2D | in_causeNO_ExceptionCode == 63'h16
              | in_causeNO_ExceptionCode == 63'h2C | in_causeNO_ExceptionCode == 63'h2B
              | in_causeNO_ExceptionCode == 63'h15 | in_causeNO_ExceptionCode == 63'h2A
              | in_causeNO_ExceptionCode == 63'h29 | in_causeNO_ExceptionCode == 63'h14
              | in_causeNO_ExceptionCode == 63'h28 | in_causeNO_ExceptionCode == 63'h27
              | in_causeNO_ExceptionCode == 63'h13 | in_causeNO_ExceptionCode == 63'h26
              | in_causeNO_ExceptionCode == 63'h25 | in_causeNO_ExceptionCode == 63'h12
              | in_causeNO_ExceptionCode == 63'h24 | in_causeNO_ExceptionCode == 63'h23
              | in_causeNO_ExceptionCode == 63'h11 | in_causeNO_ExceptionCode == 63'h22
              | in_causeNO_ExceptionCode == 63'h21 | in_causeNO_ExceptionCode == 63'h10
              | in_causeNO_ExceptionCode == 63'h20 | in_causeNO_ExceptionCode == 63'h3F
              | in_causeNO_ExceptionCode == 63'h1F | in_causeNO_ExceptionCode == 63'h3E
              | in_causeNO_ExceptionCode == 63'h3D | in_causeNO_ExceptionCode == 63'h1E
              | in_causeNO_ExceptionCode == 63'h3C | in_causeNO_ExceptionCode == 63'h3B
              | in_causeNO_ExceptionCode == 63'h1D | in_causeNO_ExceptionCode == 63'h3A
              | in_causeNO_ExceptionCode == 63'h39 | in_causeNO_ExceptionCode == 63'h1C
              | in_causeNO_ExceptionCode == 63'h38 | in_causeNO_ExceptionCode == 63'h37
              | in_causeNO_ExceptionCode == 63'h1B | in_causeNO_ExceptionCode == 63'h36
              | in_causeNO_ExceptionCode == 63'h35 | in_causeNO_ExceptionCode == 63'h1A
              | in_causeNO_ExceptionCode == 63'h34 | in_causeNO_ExceptionCode == 63'h33
              | in_causeNO_ExceptionCode == 63'h19 | in_causeNO_ExceptionCode == 63'h32
              | in_causeNO_ExceptionCode == 63'h31 | in_causeNO_ExceptionCode == 63'h18
              | in_causeNO_ExceptionCode == 63'h30
              | in_causeNO_ExceptionCode == 63'hD)) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The VS mode can only handle VSEI, VSTI, VSSI and local interrupts\n    at TrapEntryVSEvent.scala:46 assert(\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end
  `endif // not def SYNTHESIS
  wire [62:0] highPrioTrapNO =
    (in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h6
     | in_causeNO_ExceptionCode == 63'hA) & in_causeNO_Interrupt
      ? 63'(in_causeNO_ExceptionCode - 63'h1)
      : in_causeNO_ExceptionCode;
  wire        trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire        trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire        trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire        trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire        _trapPC_isSv48_T = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire        _instrAddrTransType_x5_T = in_vsatp_MODE == 4'h0;
  wire        _instrAddrTransType_x1_t1 = in_hgatp_MODE == 4'h0;
  wire        instrAddrTransType_x2 = in_vsatp_MODE == 4'h8;
  wire        instrAddrTransType_x3 = in_vsatp_MODE == 4'h9;
  wire        _instrAddrTransType_x4_t1 = in_hgatp_MODE == 4'h8;
  wire        _instrAddrTransType_x5_t1 = in_hgatp_MODE == 4'h9;
  wire [63:0] trapPC =
    (trapPC_isBare_isModeM | _trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h0
     | in_iMode_V & _instrAddrTransType_x5_T & _instrAddrTransType_x1_t1
       ? {16'h0, in_trapPc[47:0]}
       : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h8 | in_iMode_V
       & instrAddrTransType_x2
         ? {{25{in_trapPc[38]}}, in_trapPc[38:0]}
         : 64'h0)
    | (in_iMode_V & _instrAddrTransType_x5_T & _instrAddrTransType_x4_t1
         ? {23'h0, in_trapPc[40:0]}
         : 64'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h9 | in_iMode_V
       & instrAddrTransType_x3
         ? {{16{in_trapPc[47]}}, in_trapPc[47:0]}
         : 64'h0)
    | (in_iMode_V & _instrAddrTransType_x5_T & _instrAddrTransType_x5_t1
         ? {14'h0, in_trapPc}
         : 64'h0);
  wire        isFetchExcp =
    ~in_causeNO_Interrupt & (highPrioTrapNO == 63'h1 | highPrioTrapNO == 63'hC);
  wire        isBpExcp = ~in_causeNO_Interrupt & highPrioTrapNO == 63'h3;
  wire        isFetchBkpt = isBpExcp & in_isFetchBkpt;
  wire        tvalFillMemVaddr =
    ~in_causeNO_Interrupt
    & (highPrioTrapNO == 63'h4 | highPrioTrapNO == 63'h5 | highPrioTrapNO == 63'h6
       | highPrioTrapNO == 63'h7 | highPrioTrapNO == 63'hD | highPrioTrapNO == 63'hF)
    | isBpExcp & ~in_isFetchBkpt;
  wire        tvalFillGVA =
    (isFetchExcp | isFetchBkpt) & in_iMode_V | tvalFillMemVaddr & in_dMode_V;
  wire [63:0] _tval_t7 =
    (isFetchExcp & ~in_isCrossPageIPF | isFetchBkpt ? trapPC : 64'h0)
    | (isFetchExcp & in_isCrossPageIPF ? 64'(trapPC + 64'h2) : 64'h0)
    | (tvalFillMemVaddr ? in_memExceptionVAddr : 64'h0);
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h1;
  assign out_privState_bits_V = 1'h1;
  assign out_vsstatus_valid = valid;
  assign out_vsstatus_bits_SIE = 1'h0;
  assign out_vsstatus_bits_SPIE = in_vsstatus_SIE;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = in_privState_PRVM[0];
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = in_henvcfg_DTE;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_vsepc_valid = valid;
  assign out_vsepc_bits_epc = in_isFetchMalAddr ? in_fetchMalTval[63:1] : trapPC[63:1];
  assign out_vscause_valid = valid;
  assign out_vscause_bits_Interrupt = in_causeNO_Interrupt;
  assign out_vscause_bits_ExceptionCode =
    in_virtualInterruptIsHvictlInject ? {51'h0, in_hvictlIID} : highPrioTrapNO;
  assign out_vstval_valid = valid;
  assign out_vstval_bits_ALL =
    ~in_causeNO_Interrupt & in_isFetchMalAddr
      ? in_fetchMalTval
      : {_tval_t7[63:32],
         _tval_t7[31:0]
           | (~in_causeNO_Interrupt & (highPrioTrapNO == 63'h2 | highPrioTrapNO == 63'h16)
              & in_trapInst_valid
                ? in_trapInst_bits
                : 32'h0)};
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF =
    instrAddrTransType_x2 & in_pcFromXtvec[63:39] != {25{in_pcFromXtvec[38]}}
    | instrAddrTransType_x3 & in_pcFromXtvec[63:48] != {16{in_pcFromXtvec[47]}};
  assign out_targetPc_bits_raiseIAF =
    _instrAddrTransType_x5_T & _instrAddrTransType_x1_t1 & (|(in_pcFromXtvec[63:48]));
  assign out_targetPc_bits_raiseIGPF =
    _instrAddrTransType_x5_T & _instrAddrTransType_x4_t1 & (|(in_pcFromXtvec[63:41]))
    | _instrAddrTransType_x5_T & _instrAddrTransType_x5_t1 & (|(in_pcFromXtvec[63:50]));
endmodule


module TrapEntryDEventModule(
  input         valid,
  input  [49:0] in_trapPc,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input         in_hasTrap,
  input         in_debugMode,
  input         in_hasDebugIntr,
  input         in_triggerEnterDebugMode,
  input         in_hasDebugEbreakException,
  input         in_hasSingleStep,
  input         in_breakPoint,
  input         in_criticalErrorStateEnterDebug,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_dcsr_valid,
  output [3:0]  out_dcsr_bits_DEBUGVER,
  output [2:0]  out_dcsr_bits_EXTCAUSE,
  output        out_dcsr_bits_CETRIG,
  output        out_dcsr_bits_EBREAKVS,
  output        out_dcsr_bits_EBREAKVU,
  output        out_dcsr_bits_EBREAKM,
  output        out_dcsr_bits_EBREAKS,
  output        out_dcsr_bits_EBREAKU,
  output        out_dcsr_bits_STEPIE,
  output        out_dcsr_bits_STOPCOUNT,
  output        out_dcsr_bits_STOPTIME,
  output [2:0]  out_dcsr_bits_CAUSE,
  output        out_dcsr_bits_V,
  output        out_dcsr_bits_MPRVEN,
  output        out_dcsr_bits_NMIP,
  output        out_dcsr_bits_STEP,
  output [1:0]  out_dcsr_bits_PRV,
  output        out_dpc_valid,
  output [62:0] out_dpc_bits_epc,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF,
  output        out_debugMode_valid,
  output        out_debugMode_bits,
  output        out_debugIntrEnable_valid,
  output        out_debugIntrEnable_bits
);

  wire hasExceptionInDmode = in_debugMode & in_hasTrap;
  wire trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire _trapPC_isSv48_T = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire _trapPC_isSv48x4_t2 = in_vsatp_MODE == 4'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h3;
  assign out_privState_bits_V = 1'h0;
  assign out_dcsr_valid = valid;
  assign out_dcsr_bits_DEBUGVER = 4'h0;
  assign out_dcsr_bits_EXTCAUSE = 3'h0;
  assign out_dcsr_bits_CETRIG = 1'h0;
  assign out_dcsr_bits_EBREAKVS = 1'h0;
  assign out_dcsr_bits_EBREAKVU = 1'h0;
  assign out_dcsr_bits_EBREAKM = 1'h0;
  assign out_dcsr_bits_EBREAKS = 1'h0;
  assign out_dcsr_bits_EBREAKU = 1'h0;
  assign out_dcsr_bits_STEPIE = 1'h0;
  assign out_dcsr_bits_STOPCOUNT = 1'h0;
  assign out_dcsr_bits_STOPTIME = 1'h0;
  assign out_dcsr_bits_CAUSE =
    in_hasDebugIntr
      ? 3'h3
      : in_criticalErrorStateEnterDebug
          ? 3'h7
          : in_triggerEnterDebugMode
              ? 3'h2
              : in_hasDebugEbreakException ? 3'h1 : {in_hasSingleStep, 2'h0};
  assign out_dcsr_bits_V = in_privState_V;
  assign out_dcsr_bits_MPRVEN = 1'h0;
  assign out_dcsr_bits_NMIP = 1'h0;
  assign out_dcsr_bits_STEP = 1'h0;
  assign out_dcsr_bits_PRV = in_privState_PRVM;
  assign out_dpc_valid = valid;
  assign out_dpc_bits_epc =
    (trapPC_isBare_isModeM | _trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h0
     | in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h0
       ? {16'h0, in_trapPc[47:1]}
       : 63'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h8 | in_iMode_V
       & in_vsatp_MODE == 4'h8
         ? {{25{in_trapPc[38]}}, in_trapPc[38:1]}
         : 63'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h8
         ? {23'h0, in_trapPc[40:1]}
         : 63'h0)
    | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h9 | in_iMode_V
       & in_vsatp_MODE == 4'h9
         ? {{16{in_trapPc[47]}}, in_trapPc[47:1]}
         : 63'h0)
    | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h9
         ? {14'h0, in_trapPc[49:1]}
         : 63'h0);
  assign out_targetPc_valid = valid | hasExceptionInDmode;
  assign out_targetPc_bits_pc = {60'h3802080, hasExceptionInDmode & ~in_breakPoint, 3'h0};
  assign out_targetPc_bits_raiseIPF = 1'h0;
  assign out_targetPc_bits_raiseIAF = 1'h0;
  assign out_targetPc_bits_raiseIGPF = 1'h0;
  assign out_debugMode_valid = valid;
  assign out_debugMode_bits = 1'h1;
  assign out_debugIntrEnable_valid = valid;
  assign out_debugIntrEnable_bits = 1'h0;
endmodule


module TrapEntryMNEventModule(
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [63:0] in_fetchMalTval,
  input         in_isFetchMalAddr,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_satp_MODE,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mnstatus_valid,
  output        out_mnstatus_bits_NMIE,
  output        out_mnstatus_bits_MNPV,
  output        out_mnstatus_bits_MNPELP,
  output [1:0]  out_mnstatus_bits_MNPP,
  output        out_mnepc_valid,
  output [62:0] out_mnepc_bits_epc,
  output        out_mncause_valid,
  output        out_mncause_bits_Interrupt,
  output [62:0] out_mncause_bits_ExceptionCode,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire _trapPC_isSv48_T = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire _trapPC_isSv48x4_t2 = in_vsatp_MODE == 4'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h3;
  assign out_privState_bits_V = 1'h0;
  assign out_mnstatus_valid = valid;
  assign out_mnstatus_bits_NMIE = 1'h0;
  assign out_mnstatus_bits_MNPV = in_privState_V;
  assign out_mnstatus_bits_MNPELP = 1'h0;
  assign out_mnstatus_bits_MNPP = in_privState_PRVM;
  assign out_mnepc_valid = valid;
  assign out_mnepc_bits_epc =
    in_isFetchMalAddr
      ? in_fetchMalTval[63:1]
      : (trapPC_isBare_isModeM | _trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h0
         | in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h0
           ? {16'h0, in_trapPc[47:1]}
           : 63'h0)
        | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h8 | in_iMode_V
           & in_vsatp_MODE == 4'h8
             ? {{25{in_trapPc[38]}}, in_trapPc[38:1]}
             : 63'h0)
        | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h8
             ? {23'h0, in_trapPc[40:1]}
             : 63'h0)
        | (_trapPC_isSv48_T & ~in_iMode_V & in_satp_MODE == 4'h9 | in_iMode_V
           & in_vsatp_MODE == 4'h9
             ? {{16{in_trapPc[47]}}, in_trapPc[47:1]}
             : 63'h0)
        | (in_iMode_V & _trapPC_isSv48x4_t2 & in_hgatp_MODE == 4'h9
             ? {14'h0, in_trapPc[49:1]}
             : 63'h0);
  assign out_mncause_valid = valid;
  assign out_mncause_bits_Interrupt = in_causeNO_Interrupt;
  assign out_mncause_bits_ExceptionCode = in_causeNO_ExceptionCode;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF = 1'h0;
  assign out_targetPc_bits_raiseIAF = |(in_pcFromXtvec[63:48]);
  assign out_targetPc_bits_raiseIGPF = 1'h0;
endmodule
