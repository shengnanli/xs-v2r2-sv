// SretEventModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_SretEventModule_core(
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
  output logic out_privState_valid,
  output logic [1:0]  out_privState_bits_PRVM,
  output logic out_privState_bits_V,
  output logic out_mstatus_valid,
  output logic out_mstatus_bits_SIE,
  output logic out_mstatus_bits_MIE,
  output logic out_mstatus_bits_SPIE,
  output logic out_mstatus_bits_UBE,
  output logic out_mstatus_bits_MPIE,
  output logic out_mstatus_bits_SPP,
  output logic [1:0]  out_mstatus_bits_VS,
  output logic [1:0]  out_mstatus_bits_MPP,
  output logic [1:0]  out_mstatus_bits_FS,
  output logic [1:0]  out_mstatus_bits_XS,
  output logic out_mstatus_bits_MPRV,
  output logic out_mstatus_bits_SUM,
  output logic out_mstatus_bits_MXR,
  output logic out_mstatus_bits_TVM,
  output logic out_mstatus_bits_TW,
  output logic out_mstatus_bits_TSR,
  output logic out_mstatus_bits_SDT,
  output logic [1:0]  out_mstatus_bits_UXL,
  output logic [1:0]  out_mstatus_bits_SXL,
  output logic out_mstatus_bits_SBE,
  output logic out_mstatus_bits_MBE,
  output logic out_mstatus_bits_GVA,
  output logic out_mstatus_bits_MPV,
  output logic out_mstatus_bits_MDT,
  output logic out_mstatus_bits_SD,
  output logic out_hstatus_valid,
  output logic out_hstatus_bits_VSBE,
  output logic out_hstatus_bits_GVA,
  output logic out_hstatus_bits_SPV,
  output logic out_hstatus_bits_SPVP,
  output logic out_hstatus_bits_HU,
  output logic [5:0]  out_hstatus_bits_VGEIN,
  output logic out_hstatus_bits_VTVM,
  output logic out_hstatus_bits_VTW,
  output logic out_hstatus_bits_VTSR,
  output logic [1:0]  out_hstatus_bits_VSXL,
  output logic [1:0]  out_hstatus_bits_HUPMM,
  output logic out_vsstatus_valid,
  output logic out_vsstatus_bits_SIE,
  output logic out_vsstatus_bits_SPIE,
  output logic out_vsstatus_bits_UBE,
  output logic out_vsstatus_bits_SPP,
  output logic [1:0]  out_vsstatus_bits_VS,
  output logic [1:0]  out_vsstatus_bits_FS,
  output logic [1:0]  out_vsstatus_bits_XS,
  output logic out_vsstatus_bits_SUM,
  output logic out_vsstatus_bits_MXR,
  output logic out_vsstatus_bits_SDT,
  output logic [1:0]  out_vsstatus_bits_UXL,
  output logic out_vsstatus_bits_SD,
  output logic out_targetPc_valid,
  output logic [63:0] out_targetPc_bits_pc,
  output logic out_targetPc_bits_raiseIPF,
  output logic out_targetPc_bits_raiseIAF,
  output logic out_targetPc_bits_raiseIGPF,
  output logic outSDT_vsstatus_valid
);
logic        return_virtual;
  logic vsatp_bare;
  always_comb begin
    vsatp_bare = in_vsatp_MODE == 4'h0;
  end
  logic sretInM_v_PrvmIsM;
  always_comb begin
    sretInM_v_PrvmIsM = &in_privState_PRVM;
  end
  logic isModeM;
  always_comb begin
    isModeM = sretInM_v_PrvmIsM;
  end
  logic PrvmIsS;
  always_comb begin
    PrvmIsS = in_privState_PRVM == 2'h1;
  end
  logic isModeHS;
  always_comb begin
    isModeHS = ~in_privState_V & PrvmIsS;
  end
  logic sretInHSorM;
  always_comb begin
    sretInHSorM = isModeM | isModeHS;
  end
  logic isModeVS;
  always_comb begin
    isModeVS = in_privState_V & PrvmIsS;
  end
  logic [62:0] return_epc;
  always_comb begin
    return_epc = (sretInHSorM ? in_sepc_epc : 63'h0) | (isModeVS ? in_vsepc_epc : 63'h0);
  end
  logic PrvmIsS_1;
  always_comb begin
    PrvmIsS_1 = sretInHSorM & in_mstatus_SPP | isModeVS & in_vsstatus_SPP;
  end
  always_comb begin
    return_virtual = sretInHSorM & in_hstatus_SPV | isModeVS & in_privState_V;
  end
  logic PrvmIsU;
  always_comb begin
    PrvmIsU = ~PrvmIsS_1;
  end
  logic isModeVU;
  always_comb begin
    isModeVU = return_virtual & PrvmIsU;
  end
  logic isModeVS_1;
  always_comb begin
    isModeVS_1 = return_virtual & PrvmIsS_1;
  end
  logic isModeHU;
  always_comb begin
    isModeHU = ~return_virtual & PrvmIsU;
  end
  logic mstatus_update_valid;
  always_comb begin
    mstatus_update_valid = valid & sretInHSorM;
  end
  always_comb begin
    out_privState_valid = valid;
  end
  always_comb begin
    out_privState_bits_PRVM = {1'h0, PrvmIsS_1};
  end
  always_comb begin
    out_privState_bits_V = return_virtual;
  end
  always_comb begin
    out_mstatus_valid = mstatus_update_valid;
  end
  always_comb begin
    out_mstatus_bits_SIE = in_mstatus_SPIE;
  end
  always_comb begin
    out_mstatus_bits_MIE = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_SPIE = 1'h1;
  end
  always_comb begin
    out_mstatus_bits_UBE = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_MPIE = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_SPP = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_VS = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_MPP = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_FS = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_XS = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_MPRV = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_SUM = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_MXR = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_TVM = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_TW = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_TSR = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_SDT = ~(isModeHS | isModeM & (isModeHU | isModeVS_1 | isModeVU)) & in_mstatus_SDT;
  end
  always_comb begin
    out_mstatus_bits_UXL = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_SXL = 2'h0;
  end
  always_comb begin
    out_mstatus_bits_SBE = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_MBE = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_GVA = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_MPV = 1'h0;
  end
  always_comb begin
    out_mstatus_bits_MDT = ~isModeM & in_mstatus_MDT;
  end
  always_comb begin
    out_mstatus_bits_SD = 1'h0;
  end
  always_comb begin
    out_hstatus_valid = mstatus_update_valid;
  end
  always_comb begin
    out_hstatus_bits_VSBE = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_GVA = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_SPV = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_SPVP = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_HU = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_VGEIN = 6'h0;
  end
  always_comb begin
    out_hstatus_bits_VTVM = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_VTW = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_VTSR = 1'h0;
  end
  always_comb begin
    out_hstatus_bits_VSXL = 2'h0;
  end
  always_comb begin
    out_hstatus_bits_HUPMM = 2'h0;
  end
  always_comb begin
    out_vsstatus_valid = valid & isModeVS;
  end
  always_comb begin
    out_vsstatus_bits_SIE = in_vsstatus_SPIE;
  end
  always_comb begin
    out_vsstatus_bits_SPIE = 1'h1;
  end
  always_comb begin
    out_vsstatus_bits_UBE = 1'h0;
  end
  always_comb begin
    out_vsstatus_bits_SPP = 1'h0;
  end
  always_comb begin
    out_vsstatus_bits_VS = 2'h0;
  end
  always_comb begin
    out_vsstatus_bits_FS = 2'h0;
  end
  always_comb begin
    out_vsstatus_bits_XS = 2'h0;
  end
  always_comb begin
    out_vsstatus_bits_SUM = 1'h0;
  end
  always_comb begin
    out_vsstatus_bits_MXR = 1'h0;
  end
  always_comb begin
    out_vsstatus_bits_SDT = 1'h0;
  end
  always_comb begin
    out_vsstatus_bits_UXL = 2'h0;
  end
  always_comb begin
    out_vsstatus_bits_SD = 1'h0;
  end
  always_comb begin
    out_targetPc_valid = valid;
  end
  always_comb begin
    out_targetPc_bits_pc = {return_epc, 1'h0};
  end
  always_comb begin
    out_targetPc_bits_raiseIPF = (~return_virtual & in_satp_MODE == 4'h8 | return_virtual
     & in_vsatp_MODE == 4'h8) & return_epc[62:38] != {25{return_epc[37]}}
    | (~return_virtual & in_satp_MODE == 4'h9 | return_virtual
       & in_vsatp_MODE == 4'h9) & return_epc[62:47] != {16{return_epc[46]}};
  end
  always_comb begin
    out_targetPc_bits_raiseIAF = (~return_virtual & in_satp_MODE == 4'h0 | return_virtual
     & vsatp_bare & in_hgatp_MODE == 4'h0)
    & (|(return_epc[62:47]));
  end
  always_comb begin
    out_targetPc_bits_raiseIGPF = return_virtual & vsatp_bare & in_hgatp_MODE == 4'h8
    & (|(return_epc[62:40])) | return_virtual
    & vsatp_bare & in_hgatp_MODE == 4'h9 & (|(return_epc[62:49]));
  end
  always_comb begin
    outSDT_vsstatus_valid = valid & (isModeVU | isModeVS);
  end
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
  xs_SretEventModule_core u_core (
    .valid(valid),
    .in_privState_PRVM(in_privState_PRVM),
    .in_privState_V(in_privState_V),
    .in_mstatus_SPIE(in_mstatus_SPIE),
    .in_mstatus_SPP(in_mstatus_SPP),
    .in_mstatus_SDT(in_mstatus_SDT),
    .in_mstatus_MDT(in_mstatus_MDT),
    .in_hstatus_SPV(in_hstatus_SPV),
    .in_vsstatus_SPIE(in_vsstatus_SPIE),
    .in_vsstatus_SPP(in_vsstatus_SPP),
    .in_sepc_epc(in_sepc_epc),
    .in_vsepc_epc(in_vsepc_epc),
    .in_satp_MODE(in_satp_MODE),
    .in_vsatp_MODE(in_vsatp_MODE),
    .in_hgatp_MODE(in_hgatp_MODE),
    .out_privState_valid(out_privState_valid),
    .out_privState_bits_PRVM(out_privState_bits_PRVM),
    .out_privState_bits_V(out_privState_bits_V),
    .out_mstatus_valid(out_mstatus_valid),
    .out_mstatus_bits_SIE(out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE(out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE(out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE(out_mstatus_bits_UBE),
    .out_mstatus_bits_MPIE(out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP(out_mstatus_bits_SPP),
    .out_mstatus_bits_VS(out_mstatus_bits_VS),
    .out_mstatus_bits_MPP(out_mstatus_bits_MPP),
    .out_mstatus_bits_FS(out_mstatus_bits_FS),
    .out_mstatus_bits_XS(out_mstatus_bits_XS),
    .out_mstatus_bits_MPRV(out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM(out_mstatus_bits_SUM),
    .out_mstatus_bits_MXR(out_mstatus_bits_MXR),
    .out_mstatus_bits_TVM(out_mstatus_bits_TVM),
    .out_mstatus_bits_TW(out_mstatus_bits_TW),
    .out_mstatus_bits_TSR(out_mstatus_bits_TSR),
    .out_mstatus_bits_SDT(out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL(out_mstatus_bits_UXL),
    .out_mstatus_bits_SXL(out_mstatus_bits_SXL),
    .out_mstatus_bits_SBE(out_mstatus_bits_SBE),
    .out_mstatus_bits_MBE(out_mstatus_bits_MBE),
    .out_mstatus_bits_GVA(out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV(out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT(out_mstatus_bits_MDT),
    .out_mstatus_bits_SD(out_mstatus_bits_SD),
    .out_hstatus_valid(out_hstatus_valid),
    .out_hstatus_bits_VSBE(out_hstatus_bits_VSBE),
    .out_hstatus_bits_GVA(out_hstatus_bits_GVA),
    .out_hstatus_bits_SPV(out_hstatus_bits_SPV),
    .out_hstatus_bits_SPVP(out_hstatus_bits_SPVP),
    .out_hstatus_bits_HU(out_hstatus_bits_HU),
    .out_hstatus_bits_VGEIN(out_hstatus_bits_VGEIN),
    .out_hstatus_bits_VTVM(out_hstatus_bits_VTVM),
    .out_hstatus_bits_VTW(out_hstatus_bits_VTW),
    .out_hstatus_bits_VTSR(out_hstatus_bits_VTSR),
    .out_hstatus_bits_VSXL(out_hstatus_bits_VSXL),
    .out_hstatus_bits_HUPMM(out_hstatus_bits_HUPMM),
    .out_vsstatus_valid(out_vsstatus_valid),
    .out_vsstatus_bits_SIE(out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE(out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE(out_vsstatus_bits_UBE),
    .out_vsstatus_bits_SPP(out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS(out_vsstatus_bits_VS),
    .out_vsstatus_bits_FS(out_vsstatus_bits_FS),
    .out_vsstatus_bits_XS(out_vsstatus_bits_XS),
    .out_vsstatus_bits_SUM(out_vsstatus_bits_SUM),
    .out_vsstatus_bits_MXR(out_vsstatus_bits_MXR),
    .out_vsstatus_bits_SDT(out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL(out_vsstatus_bits_UXL),
    .out_vsstatus_bits_SD(out_vsstatus_bits_SD),
    .out_targetPc_valid(out_targetPc_valid),
    .out_targetPc_bits_pc(out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF(out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF(out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF(out_targetPc_bits_raiseIGPF),
    .outSDT_vsstatus_valid(outSDT_vsstatus_valid)
  );
endmodule
