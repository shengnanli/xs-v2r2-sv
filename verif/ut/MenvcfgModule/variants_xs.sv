// menvcfg UT variant (_xs): name-distinct copy of the impl body for the UT
// double-instantiation (authoritative impl is FM-verified against golden).
module MenvcfgModule_xs(
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
  reg       reg_STCE, reg_PBMTE, reg_DTE, reg_CBZE, reg_CBCFE;
  reg [1:0] reg_PMM, reg_CBIE;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_STCE <= 1'h1; reg_PBMTE <= 1'h0; reg_DTE <= 1'h0; reg_PMM <= 2'h0;
      reg_CBZE <= 1'h1; reg_CBCFE <= 1'h1; reg_CBIE <= 2'h3;
    end
    else begin
      if (w_wen) begin
        reg_STCE <= w_wdata[63]; reg_PBMTE <= w_wdata[62]; reg_DTE <= w_wdata[59];
        reg_CBZE <= w_wdata[7]; reg_CBCFE <= w_wdata[6];
      end
      if (w_wen & (|{&(w_wdata[33:32]), w_wdata[33:32] == 2'h2, w_wdata[33:32] == 2'h0}))
        reg_PMM <= w_wdata[33:32];
      if (w_wen & (|{&(w_wdata[5:4]), w_wdata[5:4] == 2'h1, w_wdata[5:4] == 2'h0}))
        reg_CBIE <= w_wdata[5:4];
    end
  end
  assign rdata = {reg_STCE, reg_PBMTE, 2'h0, reg_DTE, 25'h0, reg_PMM, 24'h0,
                  reg_CBZE, reg_CBCFE, reg_CBIE, 4'h0};
  assign regOut_STCE = reg_STCE; assign regOut_PBMTE = reg_PBMTE;
  assign regOut_DTE = reg_DTE; assign regOut_PMM = reg_PMM;
  assign regOut_CBZE = reg_CBZE; assign regOut_CBCFE = reg_CBCFE;
  assign regOut_CBIE = reg_CBIE;
endmodule
