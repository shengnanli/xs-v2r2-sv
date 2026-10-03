// MenvcfgModule.sv — machine environment configuration CSR.
// PMM accepts 0, 2, and 3; CBIE accepts 0, 1, and 3, preserving WARL semantics.
// All fields retain the golden asynchronous reset and write-enable priority.
module xs_MenvcfgModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata,
  output logic stce, output logic pbmte, output logic dte,
  output logic [1:0] pmm, output logic cbze, output logic cbcfe,
  output logic [1:0] cbie
);
  logic stce_q, pbmte_q, dte_q, cbze_q, cbcfe_q;
  logic [1:0] pmm_q, cbie_q;
  logic pmm_wlegal, cbie_wlegal;

  assign pmm_wlegal = (csr_wdata[33:32] == 2'h0) ||
                      (csr_wdata[33:32] == 2'h2) || (&csr_wdata[33:32]);
  assign cbie_wlegal = (csr_wdata[5:4] == 2'h0) ||
                       (csr_wdata[5:4] == 2'h1) || (&csr_wdata[5:4]);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      stce_q <= 1'b1; pbmte_q <= 1'b0; dte_q <= 1'b0; pmm_q <= 2'h0;
      cbze_q <= 1'b1; cbcfe_q <= 1'b1; cbie_q <= 2'h3;
    end else begin
      if (csr_wen) begin
        stce_q <= csr_wdata[63];
        pbmte_q <= csr_wdata[62];
        dte_q <= csr_wdata[59];
        cbze_q <= csr_wdata[7];
        cbcfe_q <= csr_wdata[6];
      end
      if (csr_wen && pmm_wlegal)
        pmm_q <= csr_wdata[33:32];
      if (csr_wen && cbie_wlegal)
        cbie_q <= csr_wdata[5:4];
    end
  end

  assign rdata = {stce_q, pbmte_q, 2'h0, dte_q, 25'h0, pmm_q,
                  24'h0, cbze_q, cbcfe_q, cbie_q, 4'h0};
  assign stce = stce_q; assign pbmte = pbmte_q; assign dte = dte_q;
  assign pmm = pmm_q; assign cbze = cbze_q; assign cbcfe = cbcfe_q; assign cbie = cbie_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module MenvcfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_STCE,
  output        regOut_PBMTE,
  output        regOut_DTE,
  output [1:0]  regOut_PMM,
  output        regOut_CBZE,
  output        regOut_CBCFE,
  output [1:0]  regOut_CBIE
);

  xs_MenvcfgModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .csr_wen   (w_wen),
    .csr_wdata (w_wdata),
    .rdata     (rdata),
    .stce      (regOut_STCE),
    .pbmte     (regOut_PBMTE),
    .dte       (regOut_DTE),
    .pmm       (regOut_PMM),
    .cbze      (regOut_CBZE),
    .cbcfe     (regOut_CBCFE),
    .cbie      (regOut_CBIE)
  );
endmodule
// END GENERATED
