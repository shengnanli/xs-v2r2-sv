// HenvcfgModule.sv — hypervisor environment configuration CSR.
// This readable core preserves the G1 golden reset, WARL, and write-priority behavior.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.
module xs_HenvcfgModule_core (
  input logic clock, input logic reset, input logic w_wen, input logic [63:0] w_wdata,
  output logic [63:0] rdata, output logic regOut_STCE, output logic regOut_PBMTE, output logic regOut_DTE,
  output logic [1:0] regOut_PMM, output logic regOut_CBZE, output logic regOut_CBCFE, output logic [1:0] regOut_CBIE,
  input logic menvcfg_STCE, input logic menvcfg_PBMTE, input logic menvcfg_DTE
);
  logic stce_q,pbmte_q,dte_q,cbze_q,cbcfe_q; logic [1:0] pmm_q,cbie_q;
  wire pmm_legal=(w_wdata[33:32]==2'h0)||(w_wdata[33:32]==2'h2)||(&w_wdata[33:32]);
  wire cbie_legal=(w_wdata[5:4]==2'h0)||(w_wdata[5:4]==2'h1)||(&w_wdata[5:4]);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin stce_q<=1; pbmte_q<=0; dte_q<=0; pmm_q<=0; cbze_q<=1; cbcfe_q<=1; cbie_q<=2'h3; end
    else begin
      if (w_wen) begin stce_q<=w_wdata[63]; pbmte_q<=w_wdata[62]; dte_q<=w_wdata[59]; cbze_q<=w_wdata[7]; cbcfe_q<=w_wdata[6]; end
      if (w_wen && pmm_legal) pmm_q<=w_wdata[33:32];
      if (w_wen && cbie_legal) cbie_q<=w_wdata[5:4];
    end
  end
  wire stce_out=menvcfg_STCE&stce_q, pbmte_out=menvcfg_PBMTE&pbmte_q, dte_out=menvcfg_DTE&dte_q;
  assign rdata={stce_out,pbmte_out,2'h0,dte_out,25'h0,pmm_q,24'h0,cbze_q,cbcfe_q,cbie_q,4'h0};
  assign regOut_STCE=stce_out; assign regOut_PBMTE=pbmte_out; assign regOut_DTE=dte_out; assign regOut_PMM=pmm_q;
  assign regOut_CBZE=cbze_q; assign regOut_CBCFE=cbcfe_q; assign regOut_CBIE=cbie_q;
endmodule

// BEGIN GENERATED(csr_dh)
module HenvcfgModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_STCE,
  output logic regOut_PBMTE,
  output logic regOut_DTE,
  output logic [1:0] regOut_PMM,
  output logic regOut_CBZE,
  output logic regOut_CBCFE,
  output logic [1:0] regOut_CBIE,
  input logic menvcfg_STCE,
  input logic menvcfg_PBMTE,
  input logic menvcfg_DTE
);

  xs_HenvcfgModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_STCE(regOut_STCE),
    .regOut_PBMTE(regOut_PBMTE),
    .regOut_DTE(regOut_DTE),
    .regOut_PMM(regOut_PMM),
    .regOut_CBZE(regOut_CBZE),
    .regOut_CBCFE(regOut_CBCFE),
    .regOut_CBIE(regOut_CBIE),
    .menvcfg_STCE(menvcfg_STCE),
    .menvcfg_PBMTE(menvcfg_PBMTE),
    .menvcfg_DTE(menvcfg_DTE)
  );
endmodule
// END GENERATED
