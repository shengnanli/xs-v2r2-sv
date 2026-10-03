// Readable implementation derived from G1-canonical/golden-rtl/MNretEventModule.sv.
// This is the combinational state/target generation for the MNRET event.
// The combinational outputs select the return privilege and translated target PC.
module MNretEventModule(
  input  logic       valid,
  input  logic       in_mnstatus_MNPV,
  input  logic [1:0] in_mnstatus_MNPP,
  input  logic       in_mstatus_MPRV,
  input  logic       in_mstatus_SDT,
  input  logic       in_mstatus_MDT,
  input  logic [62:0] in_mnepc_epc,
  input  logic [3:0] in_satp_MODE,
  input  logic [3:0] in_vsatp_MODE,
  input  logic [3:0] in_hgatp_MODE,
  input  logic       in_vsstatus_SDT,
  output logic       out_privState_valid,
  output logic [1:0] out_privState_bits_PRVM,
  output logic       out_privState_bits_V,
  output logic       out_mnstatus_valid,
  output logic       out_mnstatus_bits_NMIE,
  output logic       out_mnstatus_bits_MNPV,
  output logic       out_mnstatus_bits_MNPELP,
  output logic [1:0] out_mnstatus_bits_MNPP,
  output logic       out_mstatus_valid,
  output logic       out_mstatus_bits_SIE,
  output logic       out_mstatus_bits_MIE,
  output logic       out_mstatus_bits_SPIE,
  output logic       out_mstatus_bits_UBE,
  output logic       out_mstatus_bits_MPIE,
  output logic       out_mstatus_bits_SPP,
  output logic [1:0] out_mstatus_bits_VS,
  output logic [1:0] out_mstatus_bits_MPP,
  output logic [1:0] out_mstatus_bits_FS,
  output logic [1:0] out_mstatus_bits_XS,
  output logic       out_mstatus_bits_MPRV,
  output logic       out_mstatus_bits_SUM,
  output logic       out_mstatus_bits_MXR,
  output logic       out_mstatus_bits_TVM,
  output logic       out_mstatus_bits_TW,
  output logic       out_mstatus_bits_TSR,
  output logic       out_mstatus_bits_SDT,
  output logic [1:0] out_mstatus_bits_UXL,
  output logic [1:0] out_mstatus_bits_SXL,
  output logic       out_mstatus_bits_SBE,
  output logic       out_mstatus_bits_MBE,
  output logic       out_mstatus_bits_GVA,
  output logic       out_mstatus_bits_MPV,
  output logic       out_mstatus_bits_MDT,
  output logic       out_mstatus_bits_SD,
  output logic       out_vsstatus_valid,
  output logic       out_vsstatus_bits_SIE,
  output logic       out_vsstatus_bits_SPIE,
  output logic       out_vsstatus_bits_UBE,
  output logic       out_vsstatus_bits_SPP,
  output logic [1:0] out_vsstatus_bits_VS,
  output logic [1:0] out_vsstatus_bits_FS,
  output logic [1:0] out_vsstatus_bits_XS,
  output logic       out_vsstatus_bits_SUM,
  output logic       out_vsstatus_bits_MXR,
  output logic       out_vsstatus_bits_SDT,
  output logic [1:0] out_vsstatus_bits_UXL,
  output logic       out_vsstatus_bits_SD,
  output logic       out_targetPc_valid,
  output logic [63:0] out_targetPc_bits_pc,
  output logic       out_targetPc_bits_raiseIPF,
  output logic       out_targetPc_bits_raiseIAF,
  output logic       out_targetPc_bits_raiseIGPF
);
  logic is_mode_m;
  logic is_mode_hs;
  logic is_mode_vu;
  logic priv_v;
  logic vsatp_bare;

  assign out_privState_bits_PRVM = in_mnstatus_MNPP;
  assign is_mode_m = &in_mnstatus_MNPP;
  assign priv_v = ~(&in_mnstatus_MNPP) & in_mnstatus_MNPV;
  assign is_mode_hs = ~priv_v && (in_mnstatus_MNPP == 2'h1);
  assign is_mode_vu = priv_v && (in_mnstatus_MNPP == 2'h0);
  assign vsatp_bare = (in_vsatp_MODE == 4'h0);

  assign out_privState_valid = valid;
  assign out_privState_bits_V = priv_v;

  assign out_mnstatus_valid = valid;
  assign out_mnstatus_bits_NMIE = 1'b1;
  assign out_mnstatus_bits_MNPV = 1'b0;
  assign out_mnstatus_bits_MNPELP = 1'b0;
  assign out_mnstatus_bits_MNPP = 2'h0;

  assign out_mstatus_valid = valid;
  assign out_mstatus_bits_SIE = 1'b0;
  assign out_mstatus_bits_MIE = 1'b0;
  assign out_mstatus_bits_SPIE = 1'b0;
  assign out_mstatus_bits_UBE = 1'b0;
  assign out_mstatus_bits_MPIE = 1'b0;
  assign out_mstatus_bits_SPP = 1'b0;
  assign out_mstatus_bits_VS = 2'h0;
  assign out_mstatus_bits_MPP = 2'h0;
  assign out_mstatus_bits_FS = 2'h0;
  assign out_mstatus_bits_XS = 2'h0;
  assign out_mstatus_bits_MPRV = is_mode_m && in_mstatus_MPRV;
  assign out_mstatus_bits_SUM = 1'b0;
  assign out_mstatus_bits_MXR = 1'b0;
  assign out_mstatus_bits_TVM = 1'b0;
  assign out_mstatus_bits_TW = 1'b0;
  assign out_mstatus_bits_TSR = 1'b0;
  assign out_mstatus_bits_SDT = (is_mode_m || is_mode_hs) && in_mstatus_SDT;
  assign out_mstatus_bits_UXL = 2'h0;
  assign out_mstatus_bits_SXL = 2'h0;
  assign out_mstatus_bits_SBE = 1'b0;
  assign out_mstatus_bits_MBE = 1'b0;
  assign out_mstatus_bits_GVA = 1'b0;
  assign out_mstatus_bits_MPV = 1'b0;
  assign out_mstatus_bits_MDT = is_mode_m && in_mstatus_MDT;
  assign out_mstatus_bits_SD = 1'b0;

  assign out_vsstatus_valid = valid;
  assign out_vsstatus_bits_SIE = 1'b0;
  assign out_vsstatus_bits_SPIE = 1'b0;
  assign out_vsstatus_bits_UBE = 1'b0;
  assign out_vsstatus_bits_SPP = 1'b0;
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'b0;
  assign out_vsstatus_bits_MXR = 1'b0;
  assign out_vsstatus_bits_SDT = ~is_mode_vu && in_vsstatus_SDT;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'b0;

  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = {in_mnepc_epc, 1'b0};
  assign out_targetPc_bits_raiseIPF =
      (((!is_mode_m && !priv_v && (in_satp_MODE == 4'h8)) ||
        (priv_v && (in_vsatp_MODE == 4'h8))) &&
       (in_mnepc_epc[62:38] != {25{in_mnepc_epc[37]}})) ||
      (((!is_mode_m && !priv_v && (in_satp_MODE == 4'h9)) ||
        (priv_v && (in_vsatp_MODE == 4'h9))) &&
       (in_mnepc_epc[62:47] != {16{in_mnepc_epc[46]}}));
  assign out_targetPc_bits_raiseIAF =
      ((is_mode_m || (!priv_v && (in_satp_MODE == 4'h0)) ||
        (priv_v && vsatp_bare && (in_hgatp_MODE == 4'h0))) &&
       (|in_mnepc_epc[62:47]));
  assign out_targetPc_bits_raiseIGPF =
      (priv_v && vsatp_bare && (in_hgatp_MODE == 4'h8) &&
       (|in_mnepc_epc[62:40])) ||
      (priv_v && vsatp_bare && (in_hgatp_MODE == 4'h9) &&
       (|in_mnepc_epc[62:49]));
endmodule
