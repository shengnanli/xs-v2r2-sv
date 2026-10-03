`timescale 1ns/1ps
// csr_m UT: golden and readable wrappers share every input and are compared after
// reset, directed WARL/priority cases, and random CSR traffic.
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned ncycles_arg;
  longint checks = 0, errors = 0;
  logic clock = 1'b0; always #5 clock = ~clock;
  logic reset;
  logic w_wen; logic [63:0] w_wdata;
  logic ml_wen; logic [11:0] ml_addr; logic [1:0] ml_prvm; logic ml_v;
  logic ml_tvm, ml_mfs, ml_vfs, ml_mvs, ml_vvs; logic [31:0] ml_mcounteren; logic [63:0] ml_menvcfg;
  logic ml_se0, ml_envcfg, ml_csrind, ml_aia, ml_imsic, ml_context, ml_c;
  logic ml_se1, ml_se2, ml_se3, ml_mvien;
  wire ml_g_ex, ml_i_ex, ml_g_f, ml_i_f, ml_g_v, ml_i_v;
  wire [63:0] mb_g_rdata, mb_i_rdata; wire [57:0] mb_g_bma, mb_i_bma; wire mb_g_key,mb_i_key,mb_g_bme,mb_i_bme,mb_g_bc,mb_i_bc,mb_g_cm,mb_i_cm;
  wire [13:0] mc_g_rdata,mc_i_rdata,mc_g_h,mc_i_h; logic mc_from_v; logic [13:0] mc_from_h; wire [13:0] mc_g_to,mc_i_to;
  wire [63:0] mp_g_rdata,mp_i_rdata; wire mp_g_c,mp_i_c,mp_g_p,mp_i_p;
  wire [63:0] me_g_rdata,me_i_rdata; wire me_g_cy,me_i_cy,me_g_tm,me_i_tm,me_g_ir,me_i_ir; wire [28:0] me_g_hpm,me_i_hpm;
  wire [63:0] mi_g_rdata,mi_i_rdata; wire mi_g_cy,mi_i_cy,mi_g_ir,mi_i_ir; wire [28:0] mi_g_hpm,mi_i_hpm;
  wire [63:0] md_g_rdata,md_i_rdata; wire md_g_iam,md_i_iam,md_g_iaf,md_i_iaf,md_g_ii,md_i_ii,md_g_bp,md_i_bp,md_g_lam,md_i_lam,md_g_laf,md_i_laf,md_g_sam,md_i_sam,md_g_saf,md_i_saf,md_g_uc,md_i_uc,md_g_hs,md_i_hs,md_g_vs,md_i_vs,md_g_ipf,md_i_ipf,md_g_lpf,md_i_lpf,md_g_spf,md_i_spf,md_g_swc,md_i_swc,md_g_hwe,md_i_hwe,md_g_igpf,md_i_igpf,md_g_lgpf,md_i_lgpf,md_g_vi,md_i_vi,md_g_sgpf,md_i_sgpf;
  wire [63:0] mn_g_rdata,mn_i_rdata; wire mn_g_stce,mn_i_stce,mn_g_pbmte,mn_i_pbmte,mn_g_dte,mn_i_dte; wire [1:0] mn_g_pmm,mn_i_pmm; wire mn_g_cbze,mn_i_cbze,mn_g_cbcfe,mn_i_cbcfe; wire [1:0] mn_g_cbie,mn_i_cbie;
  logic mf_done; wire [63:0] mf_g_rdata,mf_i_rdata; wire mf_g_en,mf_i_en,mf_g_done,mf_i_done;

  MLevelPermitModule g_ml(.io_in_csrAccess_wen(ml_wen),.io_in_csrAccess_addr(ml_addr),.io_in_privState_PRVM(ml_prvm),.io_in_privState_V(ml_v),.io_in_status_tvm(ml_tvm),.io_in_status_mstatusFSOff(ml_mfs),.io_in_status_vsstatusFSOff(ml_vfs),.io_in_status_mstatusVSOff(ml_mvs),.io_in_status_vsstatusVSOff(ml_vvs),.io_in_xcounteren_mcounteren(ml_mcounteren),.io_in_xenvcfg_menvcfg(ml_menvcfg),.io_in_xstateen_mstateen0_SE0(ml_se0),.io_in_xstateen_mstateen0_ENVCFG(ml_envcfg),.io_in_xstateen_mstateen0_CSRIND(ml_csrind),.io_in_xstateen_mstateen0_AIA(ml_aia),.io_in_xstateen_mstateen0_IMSIC(ml_imsic),.io_in_xstateen_mstateen0_CONTEXT(ml_context),.io_in_xstateen_mstateen0_C(ml_c),.io_in_xstateen_mstateen1_SE(ml_se1),.io_in_xstateen_mstateen2_SE(ml_se2),.io_in_xstateen_mstateen3_SE(ml_se3),.io_in_aia_mvienSEIE(ml_mvien),.io_out_mLevelPermit_EX_II(ml_g_ex),.io_out_hasLegalWriteFcsr(ml_g_f),.io_out_hasLegalWriteVcsr(ml_g_v));
  MLevelPermitModule_xs i_ml(.io_in_csrAccess_wen(ml_wen),.io_in_csrAccess_addr(ml_addr),.io_in_privState_PRVM(ml_prvm),.io_in_privState_V(ml_v),.io_in_status_tvm(ml_tvm),.io_in_status_mstatusFSOff(ml_mfs),.io_in_status_vsstatusFSOff(ml_vfs),.io_in_status_mstatusVSOff(ml_mvs),.io_in_status_vsstatusVSOff(ml_vvs),.io_in_xcounteren_mcounteren(ml_mcounteren),.io_in_xenvcfg_menvcfg(ml_menvcfg),.io_in_xstateen_mstateen0_SE0(ml_se0),.io_in_xstateen_mstateen0_ENVCFG(ml_envcfg),.io_in_xstateen_mstateen0_CSRIND(ml_csrind),.io_in_xstateen_mstateen0_AIA(ml_aia),.io_in_xstateen_mstateen0_IMSIC(ml_imsic),.io_in_xstateen_mstateen0_CONTEXT(ml_context),.io_in_xstateen_mstateen0_C(ml_c),.io_in_xstateen_mstateen1_SE(ml_se1),.io_in_xstateen_mstateen2_SE(ml_se2),.io_in_xstateen_mstateen3_SE(ml_se3),.io_in_aia_mvienSEIE(ml_mvien),.io_out_mLevelPermit_EX_II(ml_i_ex),.io_out_hasLegalWriteFcsr(ml_i_f),.io_out_hasLegalWriteVcsr(ml_i_v));
  MbmcModule g_mb(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mb_g_rdata),
    .regOut_BMA(mb_g_bma),
    .regOut_KEYIDEN(mb_g_key),
    .regOut_BME(mb_g_bme),
    .regOut_BCLEAR(mb_g_bc),
    .regOut_CMODE(mb_g_cm)
  );
  MbmcModule_xs i_mb(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mb_i_rdata),
    .regOut_BMA(mb_i_bma),
    .regOut_KEYIDEN(mb_i_key),
    .regOut_BME(mb_i_bme),
    .regOut_BCLEAR(mb_i_bc),
    .regOut_CMODE(mb_i_cm)
  );
  McontextModule g_mc(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mc_g_rdata),
    .regOut_HCONTEXT(mc_g_h),
    .fromHcontext_valid(mc_from_v),
    .fromHcontext_bits_HCONTEXT(mc_from_h),
    .toHcontext_HCONTEXT(mc_g_to)
  );
  McontextModule_xs i_mc(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mc_i_rdata),
    .regOut_HCONTEXT(mc_i_h),
    .fromHcontext_valid(mc_from_v),
    .fromHcontext_bits_HCONTEXT(mc_from_h),
    .toHcontext_HCONTEXT(mc_i_to)
  );
  McorepwrModule g_mp(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mp_g_rdata),
    .regOut_COMMIT_STUCK_CHECK_ENABLE(mp_g_c),
    .regOut_POWER_DOWN_ENABLE(mp_g_p)
  );
  McorepwrModule_xs i_mp(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mp_i_rdata),
    .regOut_COMMIT_STUCK_CHECK_ENABLE(mp_i_c),
    .regOut_POWER_DOWN_ENABLE(mp_i_p)
  );
  McounterenModule g_me(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(me_g_rdata),
    .regOut_CY(me_g_cy),
    .regOut_TM(me_g_tm),
    .regOut_IR(me_g_ir),
    .regOut_HPM(me_g_hpm)
  );
  McounterenModule_xs i_me(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(me_i_rdata),
    .regOut_CY(me_i_cy),
    .regOut_TM(me_i_tm),
    .regOut_IR(me_i_ir),
    .regOut_HPM(me_i_hpm)
  );
  McountinhibitModule g_mi(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mi_g_rdata),
    .regOut_CY(mi_g_cy),
    .regOut_IR(mi_g_ir),
    .regOut_HPM3(mi_g_hpm)
  );
  McountinhibitModule_xs i_mi(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mi_i_rdata),
    .regOut_CY(mi_i_cy),
    .regOut_IR(mi_i_ir),
    .regOut_HPM3(mi_i_hpm)
  );
  MedelegModule g_md(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(md_g_rdata),
    .regOut_EX_IAM(md_g_iam),
    .regOut_EX_IAF(md_g_iaf),
    .regOut_EX_II(md_g_ii),
    .regOut_EX_BP(md_g_bp),
    .regOut_EX_LAM(md_g_lam),
    .regOut_EX_LAF(md_g_laf),
    .regOut_EX_SAM(md_g_sam),
    .regOut_EX_SAF(md_g_saf),
    .regOut_EX_UCALL(md_g_uc),
    .regOut_EX_HSCALL(md_g_hs),
    .regOut_EX_VSCALL(md_g_vs),
    .regOut_EX_IPF(md_g_ipf),
    .regOut_EX_LPF(md_g_lpf),
    .regOut_EX_SPF(md_g_spf),
    .regOut_EX_SWC(md_g_swc),
    .regOut_EX_HWE(md_g_hwe),
    .regOut_EX_IGPF(md_g_igpf),
    .regOut_EX_LGPF(md_g_lgpf),
    .regOut_EX_VI(md_g_vi),
    .regOut_EX_SGPF(md_g_sgpf)
  );
  MedelegModule_xs i_md(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(md_i_rdata),
    .regOut_EX_IAM(md_i_iam),
    .regOut_EX_IAF(md_i_iaf),
    .regOut_EX_II(md_i_ii),
    .regOut_EX_BP(md_i_bp),
    .regOut_EX_LAM(md_i_lam),
    .regOut_EX_LAF(md_i_laf),
    .regOut_EX_SAM(md_i_sam),
    .regOut_EX_SAF(md_i_saf),
    .regOut_EX_UCALL(md_i_uc),
    .regOut_EX_HSCALL(md_i_hs),
    .regOut_EX_VSCALL(md_i_vs),
    .regOut_EX_IPF(md_i_ipf),
    .regOut_EX_LPF(md_i_lpf),
    .regOut_EX_SPF(md_i_spf),
    .regOut_EX_SWC(md_i_swc),
    .regOut_EX_HWE(md_i_hwe),
    .regOut_EX_IGPF(md_i_igpf),
    .regOut_EX_LGPF(md_i_lgpf),
    .regOut_EX_VI(md_i_vi),
    .regOut_EX_SGPF(md_i_sgpf)
  );
  MenvcfgModule g_mn(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mn_g_rdata),
    .regOut_STCE(mn_g_stce),
    .regOut_PBMTE(mn_g_pbmte),
    .regOut_DTE(mn_g_dte),
    .regOut_PMM(mn_g_pmm),
    .regOut_CBZE(mn_g_cbze),
    .regOut_CBCFE(mn_g_cbcfe),
    .regOut_CBIE(mn_g_cbie)
  );
  MenvcfgModule_xs i_mn(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mn_i_rdata),
    .regOut_STCE(mn_i_stce),
    .regOut_PBMTE(mn_i_pbmte),
    .regOut_DTE(mn_i_dte),
    .regOut_PMM(mn_i_pmm),
    .regOut_CBZE(mn_i_cbze),
    .regOut_CBCFE(mn_i_cbcfe),
    .regOut_CBIE(mn_i_cbie)
  );
  MflushpwrModule g_mf(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mf_g_rdata),
    .regOut_FLUSH_L2_ENABLE(mf_g_en),
    .regOut_L2_FLUSH_DONE(mf_g_done),
    .l2FlushDone(mf_done)
  );
  MflushpwrModule_xs i_mf(
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(mf_i_rdata),
    .regOut_FLUSH_L2_ENABLE(mf_i_en),
    .regOut_L2_FLUSH_DONE(mf_i_done),
    .l2FlushDone(mf_done)
  );

  task automatic compare_outputs;
    begin
      checks++; if (ml_g_ex !== ml_i_ex) begin errors++; if (errors < 20) $display("MISMATCH ml ml_g_ex g=%h i=%h", ml_g_ex, ml_i_ex); end
      checks++; if (ml_g_f !== ml_i_f) begin errors++; if (errors < 20) $display("MISMATCH ml ml_g_f g=%h i=%h", ml_g_f, ml_i_f); end
      checks++; if (ml_g_v !== ml_i_v) begin errors++; if (errors < 20) $display("MISMATCH ml ml_g_v g=%h i=%h", ml_g_v, ml_i_v); end
      checks++; if (mb_g_rdata !== mb_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_rdata g=%h i=%h", mb_g_rdata, mb_i_rdata); end
      checks++; if (mb_g_bma !== mb_i_bma) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_bma g=%h i=%h", mb_g_bma, mb_i_bma); end
      checks++; if (mb_g_key !== mb_i_key) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_key g=%h i=%h", mb_g_key, mb_i_key); end
      checks++; if (mb_g_bme !== mb_i_bme) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_bme g=%h i=%h", mb_g_bme, mb_i_bme); end
      checks++; if (mb_g_bc !== mb_i_bc) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_bc g=%h i=%h", mb_g_bc, mb_i_bc); end
      checks++; if (mb_g_cm !== mb_i_cm) begin errors++; if (errors < 20) $display("MISMATCH mb mb_g_cm g=%h i=%h", mb_g_cm, mb_i_cm); end
      checks++; if (mc_g_rdata !== mc_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mc mc_g_rdata g=%h i=%h", mc_g_rdata, mc_i_rdata); end
      checks++; if (mc_g_h !== mc_i_h) begin errors++; if (errors < 20) $display("MISMATCH mc mc_g_h g=%h i=%h", mc_g_h, mc_i_h); end
      checks++; if (mc_g_to !== mc_i_to) begin errors++; if (errors < 20) $display("MISMATCH mc mc_g_to g=%h i=%h", mc_g_to, mc_i_to); end
      checks++; if (mp_g_rdata !== mp_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mp mp_g_rdata g=%h i=%h", mp_g_rdata, mp_i_rdata); end
      checks++; if (mp_g_c !== mp_i_c) begin errors++; if (errors < 20) $display("MISMATCH mp mp_g_c g=%h i=%h", mp_g_c, mp_i_c); end
      checks++; if (mp_g_p !== mp_i_p) begin errors++; if (errors < 20) $display("MISMATCH mp mp_g_p g=%h i=%h", mp_g_p, mp_i_p); end
      checks++; if (me_g_rdata !== me_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH me me_g_rdata g=%h i=%h", me_g_rdata, me_i_rdata); end
      checks++; if (me_g_cy !== me_i_cy) begin errors++; if (errors < 20) $display("MISMATCH me me_g_cy g=%h i=%h", me_g_cy, me_i_cy); end
      checks++; if (me_g_tm !== me_i_tm) begin errors++; if (errors < 20) $display("MISMATCH me me_g_tm g=%h i=%h", me_g_tm, me_i_tm); end
      checks++; if (me_g_ir !== me_i_ir) begin errors++; if (errors < 20) $display("MISMATCH me me_g_ir g=%h i=%h", me_g_ir, me_i_ir); end
      checks++; if (me_g_hpm !== me_i_hpm) begin errors++; if (errors < 20) $display("MISMATCH me me_g_hpm g=%h i=%h", me_g_hpm, me_i_hpm); end
      checks++; if (mi_g_rdata !== mi_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mi mi_g_rdata g=%h i=%h", mi_g_rdata, mi_i_rdata); end
      checks++; if (mi_g_cy !== mi_i_cy) begin errors++; if (errors < 20) $display("MISMATCH mi mi_g_cy g=%h i=%h", mi_g_cy, mi_i_cy); end
      checks++; if (mi_g_ir !== mi_i_ir) begin errors++; if (errors < 20) $display("MISMATCH mi mi_g_ir g=%h i=%h", mi_g_ir, mi_i_ir); end
      checks++; if (mi_g_hpm !== mi_i_hpm) begin errors++; if (errors < 20) $display("MISMATCH mi mi_g_hpm g=%h i=%h", mi_g_hpm, mi_i_hpm); end
      checks++; if (md_g_rdata !== md_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH md md_g_rdata g=%h i=%h", md_g_rdata, md_i_rdata); end
      checks++; if (md_g_iam !== md_i_iam) begin errors++; if (errors < 20) $display("MISMATCH md md_g_iam g=%h i=%h", md_g_iam, md_i_iam); end
      checks++; if (md_g_iaf !== md_i_iaf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_iaf g=%h i=%h", md_g_iaf, md_i_iaf); end
      checks++; if (md_g_ii !== md_i_ii) begin errors++; if (errors < 20) $display("MISMATCH md md_g_ii g=%h i=%h", md_g_ii, md_i_ii); end
      checks++; if (md_g_bp !== md_i_bp) begin errors++; if (errors < 20) $display("MISMATCH md md_g_bp g=%h i=%h", md_g_bp, md_i_bp); end
      checks++; if (md_g_lam !== md_i_lam) begin errors++; if (errors < 20) $display("MISMATCH md md_g_lam g=%h i=%h", md_g_lam, md_i_lam); end
      checks++; if (md_g_laf !== md_i_laf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_laf g=%h i=%h", md_g_laf, md_i_laf); end
      checks++; if (md_g_sam !== md_i_sam) begin errors++; if (errors < 20) $display("MISMATCH md md_g_sam g=%h i=%h", md_g_sam, md_i_sam); end
      checks++; if (md_g_saf !== md_i_saf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_saf g=%h i=%h", md_g_saf, md_i_saf); end
      checks++; if (md_g_uc !== md_i_uc) begin errors++; if (errors < 20) $display("MISMATCH md md_g_uc g=%h i=%h", md_g_uc, md_i_uc); end
      checks++; if (md_g_hs !== md_i_hs) begin errors++; if (errors < 20) $display("MISMATCH md md_g_hs g=%h i=%h", md_g_hs, md_i_hs); end
      checks++; if (md_g_vs !== md_i_vs) begin errors++; if (errors < 20) $display("MISMATCH md md_g_vs g=%h i=%h", md_g_vs, md_i_vs); end
      checks++; if (md_g_ipf !== md_i_ipf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_ipf g=%h i=%h", md_g_ipf, md_i_ipf); end
      checks++; if (md_g_lpf !== md_i_lpf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_lpf g=%h i=%h", md_g_lpf, md_i_lpf); end
      checks++; if (md_g_spf !== md_i_spf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_spf g=%h i=%h", md_g_spf, md_i_spf); end
      checks++; if (md_g_swc !== md_i_swc) begin errors++; if (errors < 20) $display("MISMATCH md md_g_swc g=%h i=%h", md_g_swc, md_i_swc); end
      checks++; if (md_g_hwe !== md_i_hwe) begin errors++; if (errors < 20) $display("MISMATCH md md_g_hwe g=%h i=%h", md_g_hwe, md_i_hwe); end
      checks++; if (md_g_igpf !== md_i_igpf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_igpf g=%h i=%h", md_g_igpf, md_i_igpf); end
      checks++; if (md_g_lgpf !== md_i_lgpf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_lgpf g=%h i=%h", md_g_lgpf, md_i_lgpf); end
      checks++; if (md_g_vi !== md_i_vi) begin errors++; if (errors < 20) $display("MISMATCH md md_g_vi g=%h i=%h", md_g_vi, md_i_vi); end
      checks++; if (md_g_sgpf !== md_i_sgpf) begin errors++; if (errors < 20) $display("MISMATCH md md_g_sgpf g=%h i=%h", md_g_sgpf, md_i_sgpf); end
      checks++; if (mn_g_rdata !== mn_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_rdata g=%h i=%h", mn_g_rdata, mn_i_rdata); end
      checks++; if (mn_g_stce !== mn_i_stce) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_stce g=%h i=%h", mn_g_stce, mn_i_stce); end
      checks++; if (mn_g_pbmte !== mn_i_pbmte) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_pbmte g=%h i=%h", mn_g_pbmte, mn_i_pbmte); end
      checks++; if (mn_g_dte !== mn_i_dte) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_dte g=%h i=%h", mn_g_dte, mn_i_dte); end
      checks++; if (mn_g_pmm !== mn_i_pmm) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_pmm g=%h i=%h", mn_g_pmm, mn_i_pmm); end
      checks++; if (mn_g_cbze !== mn_i_cbze) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_cbze g=%h i=%h", mn_g_cbze, mn_i_cbze); end
      checks++; if (mn_g_cbcfe !== mn_i_cbcfe) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_cbcfe g=%h i=%h", mn_g_cbcfe, mn_i_cbcfe); end
      checks++; if (mn_g_cbie !== mn_i_cbie) begin errors++; if (errors < 20) $display("MISMATCH mn mn_g_cbie g=%h i=%h", mn_g_cbie, mn_i_cbie); end
      checks++; if (mf_g_rdata !== mf_i_rdata) begin errors++; if (errors < 20) $display("MISMATCH mf mf_g_rdata g=%h i=%h", mf_g_rdata, mf_i_rdata); end
      checks++; if (mf_g_en !== mf_i_en) begin errors++; if (errors < 20) $display("MISMATCH mf mf_g_en g=%h i=%h", mf_g_en, mf_i_en); end
      checks++; if (mf_g_done !== mf_i_done) begin errors++; if (errors < 20) $display("MISMATCH mf mf_g_done g=%h i=%h", mf_g_done, mf_i_done); end
    end
  endtask

  task automatic drive_random;
    begin
      w_wen = $urandom_range(0,1); w_wdata = {$urandom,$urandom};
      mc_from_v = $urandom_range(0,1); mc_from_h = $urandom;
      mf_done = $urandom_range(0,1);
      ml_wen = $urandom_range(0,1); ml_addr = $urandom; ml_prvm = $urandom; ml_v = $urandom_range(0,1);
      ml_tvm = $urandom_range(0,1); ml_mfs = $urandom_range(0,1); ml_vfs = $urandom_range(0,1);
      ml_mvs = $urandom_range(0,1); ml_vvs = $urandom_range(0,1); ml_mcounteren = $urandom; ml_menvcfg = {$urandom,$urandom};
      ml_se0=$urandom_range(0,1); ml_envcfg=$urandom_range(0,1); ml_csrind=$urandom_range(0,1); ml_aia=$urandom_range(0,1);
      ml_imsic=$urandom_range(0,1); ml_context=$urandom_range(0,1); ml_c=$urandom_range(0,1);
      ml_se1=$urandom_range(0,1); ml_se2=$urandom_range(0,1); ml_se3=$urandom_range(0,1); ml_mvien=$urandom_range(0,1);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", ncycles_arg)) NCYCLES = ncycles_arg;
    reset=1; w_wen=0; w_wdata='0; mc_from_v=0; mc_from_h='0; mf_done=0;
    ml_wen=0; ml_addr='0; ml_prvm=2'h3; ml_v=0; ml_tvm=0; ml_mfs=0; ml_vfs=0; ml_mvs=0; ml_vvs=0; ml_mcounteren='1; ml_menvcfg='1;
    ml_se0=1; ml_envcfg=1; ml_csrind=1; ml_aia=1; ml_imsic=1; ml_context=1; ml_c=1; ml_se1=1; ml_se2=1; ml_se3=1; ml_mvien=0;
    repeat (2) @(posedge clock); #1; compare_outputs(); reset=0;
    // Directed all-one write, BME lock, context write priority, and WARL rejects.
    @(negedge clock); w_wen=1; w_wdata='1; mc_from_v=1; mc_from_h=14'h1234; #1; compare_outputs();
    @(posedge clock); #1; compare_outputs();
    @(negedge clock); w_wdata=64'h0123_4567_89AB_CDEF; mc_from_v=1; mc_from_h=14'h2AAA;
    @(posedge clock); #1; compare_outputs();
    @(negedge clock); w_wdata='0; w_wdata[33:32]=2'h1; w_wdata[5:4]=2'h2;
    @(posedge clock); #1; compare_outputs();
    w_wen=0; mc_from_v=0;
    for (int unsigned k=0; k<NCYCLES; k++) begin
      @(negedge clock); drive_random();
      @(posedge clock); #1; compare_outputs();
    end
    $display("csr_m UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
