// MedelegModule.sv — machine exception delegation bits.
// Only architecturally delegable exception causes are stored; reserved read bits stay zero.
// The wrapper exposes each stored cause bit with its canonical name.
module xs_MedelegModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata,
  output logic ex_iam, output logic ex_iaf, output logic ex_ii,
  output logic ex_bp, output logic ex_lam, output logic ex_laf,
  output logic ex_sam, output logic ex_saf, output logic ex_ucall,
  output logic ex_hscall, output logic ex_vscall, output logic ex_ipf,
  output logic ex_lpf, output logic ex_spf, output logic ex_swc,
  output logic ex_hwe, output logic ex_igpf, output logic ex_lgpf,
  output logic ex_vi, output logic ex_sgpf
);
  logic ex_iam_q, ex_iaf_q, ex_ii_q, ex_bp_q, ex_lam_q, ex_laf_q;
  logic ex_sam_q, ex_saf_q, ex_ucall_q, ex_hscall_q, ex_vscall_q;
  logic ex_ipf_q, ex_lpf_q, ex_spf_q, ex_swc_q, ex_hwe_q;
  logic ex_igpf_q, ex_lgpf_q, ex_vi_q, ex_sgpf_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ex_iam_q <= 1'b0; ex_iaf_q <= 1'b0; ex_ii_q <= 1'b0; ex_bp_q <= 1'b0;
      ex_lam_q <= 1'b0; ex_laf_q <= 1'b0; ex_sam_q <= 1'b0; ex_saf_q <= 1'b0;
      ex_ucall_q <= 1'b0; ex_hscall_q <= 1'b0; ex_vscall_q <= 1'b0;
      ex_ipf_q <= 1'b0; ex_lpf_q <= 1'b0; ex_spf_q <= 1'b0; ex_swc_q <= 1'b0;
      ex_hwe_q <= 1'b0; ex_igpf_q <= 1'b0; ex_lgpf_q <= 1'b0;
      ex_vi_q <= 1'b0; ex_sgpf_q <= 1'b0;
    end else if (csr_wen) begin
      ex_iam_q <= csr_wdata[0]; ex_iaf_q <= csr_wdata[1]; ex_ii_q <= csr_wdata[2];
      ex_bp_q <= csr_wdata[3]; ex_lam_q <= csr_wdata[4]; ex_laf_q <= csr_wdata[5];
      ex_sam_q <= csr_wdata[6]; ex_saf_q <= csr_wdata[7]; ex_ucall_q <= csr_wdata[8];
      ex_hscall_q <= csr_wdata[9]; ex_vscall_q <= csr_wdata[10];
      ex_ipf_q <= csr_wdata[12]; ex_lpf_q <= csr_wdata[13]; ex_spf_q <= csr_wdata[15];
      ex_swc_q <= csr_wdata[18]; ex_hwe_q <= csr_wdata[19]; ex_igpf_q <= csr_wdata[20];
      ex_lgpf_q <= csr_wdata[21]; ex_vi_q <= csr_wdata[22]; ex_sgpf_q <= csr_wdata[23];
    end
  end

  assign rdata = {40'h0, ex_sgpf_q, ex_vi_q, ex_lgpf_q, ex_igpf_q, ex_hwe_q,
                  ex_swc_q, 2'h0, ex_spf_q, 1'h0, ex_lpf_q, ex_ipf_q, 1'h0,
                  ex_vscall_q, ex_hscall_q, ex_ucall_q, ex_saf_q, ex_sam_q,
                  ex_laf_q, ex_lam_q, ex_bp_q, ex_ii_q, ex_iaf_q, ex_iam_q};
  assign ex_iam = ex_iam_q; assign ex_iaf = ex_iaf_q; assign ex_ii = ex_ii_q;
  assign ex_bp = ex_bp_q; assign ex_lam = ex_lam_q; assign ex_laf = ex_laf_q;
  assign ex_sam = ex_sam_q; assign ex_saf = ex_saf_q; assign ex_ucall = ex_ucall_q;
  assign ex_hscall = ex_hscall_q; assign ex_vscall = ex_vscall_q; assign ex_ipf = ex_ipf_q;
  assign ex_lpf = ex_lpf_q; assign ex_spf = ex_spf_q; assign ex_swc = ex_swc_q;
  assign ex_hwe = ex_hwe_q; assign ex_igpf = ex_igpf_q; assign ex_lgpf = ex_lgpf_q;
  assign ex_vi = ex_vi_q; assign ex_sgpf = ex_sgpf_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module MedelegModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_EX_IAM,
  output        regOut_EX_IAF,
  output        regOut_EX_II,
  output        regOut_EX_BP,
  output        regOut_EX_LAM,
  output        regOut_EX_LAF,
  output        regOut_EX_SAM,
  output        regOut_EX_SAF,
  output        regOut_EX_UCALL,
  output        regOut_EX_HSCALL,
  output        regOut_EX_VSCALL,
  output        regOut_EX_IPF,
  output        regOut_EX_LPF,
  output        regOut_EX_SPF,
  output        regOut_EX_SWC,
  output        regOut_EX_HWE,
  output        regOut_EX_IGPF,
  output        regOut_EX_LGPF,
  output        regOut_EX_VI,
  output        regOut_EX_SGPF
);

  xs_MedelegModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .csr_wen   (w_wen),
    .csr_wdata (w_wdata),
    .rdata     (rdata),
    .ex_iam    (regOut_EX_IAM),
    .ex_iaf    (regOut_EX_IAF),
    .ex_ii     (regOut_EX_II),
    .ex_bp     (regOut_EX_BP),
    .ex_lam    (regOut_EX_LAM),
    .ex_laf    (regOut_EX_LAF),
    .ex_sam    (regOut_EX_SAM),
    .ex_saf    (regOut_EX_SAF),
    .ex_ucall  (regOut_EX_UCALL),
    .ex_hscall (regOut_EX_HSCALL),
    .ex_vscall (regOut_EX_VSCALL),
    .ex_ipf    (regOut_EX_IPF),
    .ex_lpf    (regOut_EX_LPF),
    .ex_spf    (regOut_EX_SPF),
    .ex_swc    (regOut_EX_SWC),
    .ex_hwe    (regOut_EX_HWE),
    .ex_igpf   (regOut_EX_IGPF),
    .ex_lgpf   (regOut_EX_LGPF),
    .ex_vi     (regOut_EX_VI),
    .ex_sgpf   (regOut_EX_SGPF)
  );
endmodule
// END GENERATED
