// MLevelPermitModule.sv — CSR legality checks for machine-level access control.
// The core mirrors the privilege, status, delegation, and state-enable predicates from
// NewCSR.  mLevelPermit_EX_II is asserted for illegal writes or blocked subordinate CSRs.
module xs_MLevelPermitModule_core (
  input logic csr_wen,
  input logic [11:0] csr_addr,
  input logic [1:0] priv_prvm,
  input logic priv_v,
  input logic status_tvm,
  input logic status_mstatus_fs_off,
  input logic status_vsstatus_fs_off,
  input logic status_mstatus_vs_off,
  input logic status_vsstatus_vs_off,
  input logic [31:0] mcounteren,
  input logic [63:0] menvcfg,
  input logic stateen0_se0,
  input logic stateen0_envcfg,
  input logic stateen0_csrind,
  input logic stateen0_aia,
  input logic stateen0_imsic,
  input logic stateen0_context,
  input logic stateen0_c,
  input logic stateen1_se,
  input logic stateen2_se,
  input logic stateen3_se,
  input logic aia_mvien_seie,
  output logic mlevel_permit_ex_ii,
  output logic has_legal_write_fcsr,
  output logic has_legal_write_vcsr
);
  logic csr_is_fp;
  logic csr_is_vec_8, csr_is_vec_9, csr_is_vec_a, csr_is_vec_f;
  logic fs_effective_off, vs_effective_off;
  logic mode_m, mode_s_hs, csr_is_stimecmp, csr_is_stopei;
  logic c_stateen_restricted;
  logic [31:0] access_hpm;

  assign csr_is_fp = (csr_addr == 12'h001) || (csr_addr == 12'h002) ||
                     (csr_addr == 12'h003);
  assign csr_is_vec_8 = csr_addr == 12'h008;
  assign csr_is_vec_9 = csr_addr == 12'h009;
  assign csr_is_vec_a = csr_addr == 12'h00A;
  assign csr_is_vec_f = csr_addr == 12'h00F;
  assign fs_effective_off = (status_mstatus_fs_off && !priv_v) ||
                            ((status_mstatus_fs_off || status_vsstatus_fs_off) && priv_v);
  assign vs_effective_off = (status_mstatus_vs_off && !priv_v) ||
                            ((status_mstatus_vs_off || status_vsstatus_vs_off) && priv_v);
  assign mode_m = &priv_prvm;
  assign csr_is_stimecmp = csr_addr == 12'h14D;
  assign mode_s_hs = !priv_v && (priv_prvm == 2'h1);
  assign csr_is_stopei = csr_addr == 12'h15C;
  assign access_hpm = mcounteren >> csr_addr[4:0];
  assign c_stateen_restricted =
      ((|csr_addr[11:10]) && csr_addr[9:8] == 2'h2 && &csr_addr[7:6]) ||
      ((|csr_addr[11:10]) && csr_addr[9:8] == 2'h1 && &csr_addr[7:6]) ||
      (csr_addr[11:8] == 4'h8) || (csr_addr[11:6] == 6'h33);

  assign mlevel_permit_ex_ii =
      (&csr_addr[11:10]) && csr_wen
    || csr_is_fp && fs_effective_off
    || (csr_is_vec_8 || csr_is_vec_9 || csr_is_vec_a || csr_is_vec_f ||
        csr_addr == 12'hC21) && vs_effective_off
    || !mode_m &&
       ((!mcounteren[1] && ((csr_addr == 12'h24D) || csr_is_stimecmp)) ||
        (!menvcfg[63] && csr_is_stimecmp))
    || (csr_addr > 12'hBFF && csr_addr < 12'hC20) && !mode_m && !access_hpm[0]
    || mode_s_hs && status_tvm && ((csr_addr == 12'h180) || (csr_addr == 12'h680))
    || mode_s_hs && aia_mvien_seie && csr_is_stopei
    || (csr_addr == 12'h60C || csr_addr == 12'h10C) && !mode_m && !stateen0_se0
    || (csr_addr == 12'h60D || csr_addr == 12'h10D) && !mode_m && !stateen1_se
    || (csr_addr == 12'h60E || csr_addr == 12'h10E) && !mode_m && !stateen2_se
    || (csr_addr == 12'h60F || csr_addr == 12'h10F) && !mode_m && !stateen3_se
    || (csr_addr == 12'h60A || csr_addr == 12'h10A) && !mode_m && !stateen0_envcfg
    || (((csr_addr > 12'h14F && csr_addr < 12'h158 && csr_addr != 12'h154) ||
         (csr_addr > 12'h24F && csr_addr < 12'h258 && csr_addr != 12'h254)) &&
        !mode_m && !stateen0_csrind)
    || (csr_addr == 12'h608 || csr_addr == 12'h609 ||
        csr_addr == 12'h646 || csr_addr == 12'h647 ||
        csr_addr == 12'hEB0 || csr_addr == 12'hDB0) && !mode_m && !stateen0_aia
    || (csr_is_stopei || csr_addr == 12'h25C) && !mode_m && !stateen0_imsic
    || (csr_addr == 12'h6A8 || csr_addr == 12'h5A8) && !mode_m && !stateen0_context
    || c_stateen_restricted && !mode_m && !stateen0_c;

  assign has_legal_write_fcsr = csr_wen && csr_is_fp && !fs_effective_off;
  assign has_legal_write_vcsr = csr_wen &&
      (csr_is_vec_8 || csr_is_vec_9 || csr_is_vec_a || csr_is_vec_f) && !vs_effective_off;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module MLevelPermitModule(
  input         io_in_csrAccess_wen,
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_status_tvm,
  input         io_in_status_mstatusFSOff,
  input         io_in_status_vsstatusFSOff,
  input         io_in_status_mstatusVSOff,
  input         io_in_status_vsstatusVSOff,
  input  [31:0] io_in_xcounteren_mcounteren,
  input  [63:0] io_in_xenvcfg_menvcfg,
  input         io_in_xstateen_mstateen0_SE0,
  input         io_in_xstateen_mstateen0_ENVCFG,
  input         io_in_xstateen_mstateen0_CSRIND,
  input         io_in_xstateen_mstateen0_AIA,
  input         io_in_xstateen_mstateen0_IMSIC,
  input         io_in_xstateen_mstateen0_CONTEXT,
  input         io_in_xstateen_mstateen0_C,
  input         io_in_xstateen_mstateen1_SE,
  input         io_in_xstateen_mstateen2_SE,
  input         io_in_xstateen_mstateen3_SE,
  input         io_in_aia_mvienSEIE,
  output        io_out_mLevelPermit_EX_II,
  output        io_out_hasLegalWriteFcsr,
  output        io_out_hasLegalWriteVcsr
);

  xs_MLevelPermitModule_core u_core (
    .csr_wen                (io_in_csrAccess_wen),
    .csr_addr               (io_in_csrAccess_addr),
    .priv_prvm              (io_in_privState_PRVM),
    .priv_v                 (io_in_privState_V),
    .status_tvm             (io_in_status_tvm),
    .status_mstatus_fs_off  (io_in_status_mstatusFSOff),
    .status_vsstatus_fs_off (io_in_status_vsstatusFSOff),
    .status_mstatus_vs_off  (io_in_status_mstatusVSOff),
    .status_vsstatus_vs_off (io_in_status_vsstatusVSOff),
    .mcounteren             (io_in_xcounteren_mcounteren),
    .menvcfg                (io_in_xenvcfg_menvcfg),
    .stateen0_se0           (io_in_xstateen_mstateen0_SE0),
    .stateen0_envcfg        (io_in_xstateen_mstateen0_ENVCFG),
    .stateen0_csrind        (io_in_xstateen_mstateen0_CSRIND),
    .stateen0_aia           (io_in_xstateen_mstateen0_AIA),
    .stateen0_imsic         (io_in_xstateen_mstateen0_IMSIC),
    .stateen0_context       (io_in_xstateen_mstateen0_CONTEXT),
    .stateen0_c             (io_in_xstateen_mstateen0_C),
    .stateen1_se            (io_in_xstateen_mstateen1_SE),
    .stateen2_se            (io_in_xstateen_mstateen2_SE),
    .stateen3_se            (io_in_xstateen_mstateen3_SE),
    .aia_mvien_seie         (io_in_aia_mvienSEIE),
    .mlevel_permit_ex_ii    (io_out_mLevelPermit_EX_II),
    .has_legal_write_fcsr   (io_out_hasLegalWriteFcsr),
    .has_legal_write_vcsr   (io_out_hasLegalWriteVcsr)
  );
endmodule
// END GENERATED
