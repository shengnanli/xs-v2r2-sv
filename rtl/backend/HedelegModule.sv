// HedelegModule.sv — hypervisor exception-delegation CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HedelegModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_EX_IAM, output logic regOut_EX_IAF,
  output logic regOut_EX_II, output logic regOut_EX_BP, output logic regOut_EX_LAM,
  output logic regOut_EX_LAF, output logic regOut_EX_SAM, output logic regOut_EX_SAF,
  output logic regOut_EX_UCALL, output logic regOut_EX_IPF, output logic regOut_EX_LPF,
  output logic regOut_EX_SPF, output logic regOut_EX_SWC, output logic regOut_EX_HWE
);
  logic iam_q,iaf_q,ii_q,bp_q,lam_q,laf_q,sam_q,saf_q,ucall_q;
  logic ipf_q,lpf_q,spf_q,swc_q,hwe_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      iam_q<=0; iaf_q<=0; ii_q<=0; bp_q<=0; lam_q<=0; laf_q<=0; sam_q<=0; saf_q<=0; ucall_q<=0;
      ipf_q<=0; lpf_q<=0; spf_q<=0; swc_q<=0; hwe_q<=0;
    end else if (w_wen) begin
      iam_q<=w_wdata[0]; iaf_q<=w_wdata[1]; ii_q<=w_wdata[2]; bp_q<=w_wdata[3]; lam_q<=w_wdata[4];
      laf_q<=w_wdata[5]; sam_q<=w_wdata[6]; saf_q<=w_wdata[7]; ucall_q<=w_wdata[8]; ipf_q<=w_wdata[12];
      lpf_q<=w_wdata[13]; spf_q<=w_wdata[15]; swc_q<=w_wdata[18]; hwe_q<=w_wdata[19];
    end
  end
  assign rdata={44'h0,hwe_q,swc_q,2'h0,spf_q,1'h0,lpf_q,ipf_q,3'h0,ucall_q,saf_q,sam_q,laf_q,lam_q,bp_q,ii_q,iaf_q,iam_q};
  assign regOut_EX_IAM=iam_q; assign regOut_EX_IAF=iaf_q; assign regOut_EX_II=ii_q; assign regOut_EX_BP=bp_q;
  assign regOut_EX_LAM=lam_q; assign regOut_EX_LAF=laf_q; assign regOut_EX_SAM=sam_q; assign regOut_EX_SAF=saf_q;
  assign regOut_EX_UCALL=ucall_q; assign regOut_EX_IPF=ipf_q; assign regOut_EX_LPF=lpf_q; assign regOut_EX_SPF=spf_q;
  assign regOut_EX_SWC=swc_q; assign regOut_EX_HWE=hwe_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HedelegModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_EX_IAM,
  output logic regOut_EX_IAF,
  output logic regOut_EX_II,
  output logic regOut_EX_BP,
  output logic regOut_EX_LAM,
  output logic regOut_EX_LAF,
  output logic regOut_EX_SAM,
  output logic regOut_EX_SAF,
  output logic regOut_EX_UCALL,
  output logic regOut_EX_IPF,
  output logic regOut_EX_LPF,
  output logic regOut_EX_SPF,
  output logic regOut_EX_SWC,
  output logic regOut_EX_HWE
);

  xs_HedelegModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_EX_IAM(regOut_EX_IAM),
    .regOut_EX_IAF(regOut_EX_IAF),
    .regOut_EX_II(regOut_EX_II),
    .regOut_EX_BP(regOut_EX_BP),
    .regOut_EX_LAM(regOut_EX_LAM),
    .regOut_EX_LAF(regOut_EX_LAF),
    .regOut_EX_SAM(regOut_EX_SAM),
    .regOut_EX_SAF(regOut_EX_SAF),
    .regOut_EX_UCALL(regOut_EX_UCALL),
    .regOut_EX_IPF(regOut_EX_IPF),
    .regOut_EX_LPF(regOut_EX_LPF),
    .regOut_EX_SPF(regOut_EX_SPF),
    .regOut_EX_SWC(regOut_EX_SWC),
    .regOut_EX_HWE(regOut_EX_HWE)
  );
endmodule
// END GENERATED
