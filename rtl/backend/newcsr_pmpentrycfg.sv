// NewCSR CSR-field primitive: PmpEntryCfg (one PMP entry's 8-bit config field).
//
// Faithful, readable reimplementation of the golden PmpNcfgModule family
// (Pmp0cfgModule .. Pmp15cfgModule) — all 16 golden bodies are byte-identical
// apart from the module name. Each handles the WARL legalization for ONE PMP
// entry's config byte (the 8-bit pmpcfg[i] slice: L,0,0,A[1:0],X,W,R):
//
//   reg_R,reg_X,reg_A[1:0],reg_L : latched from w_wdata on w_wen.
//     * reg_A : WARL — the NA4 encoding (A==2'b10) is not supported here and is
//               forced up to NAPOT (2'b11); TOR(01)/OFF(00)/NAPOT(11) pass
//               through. (Golden: w_wdata[4:3]==2'h2 ? 2'h3 : w_wdata[4:3].)
//   reg_W  : WARL — RESERVED combo W=1,R=0 is illegal, so a write is *dropped*
//            (register holds its old value) when ~R & W. Guarded write enable:
//            w_wen & ~(~w_wdata[0] & w_wdata[1]).
//
// rdata packs {L, 2'b0, A, X, W, R}; the two bits [6:5] read as 0.
// All registers async-reset to 0. Pure single-entry, no cross-entry coupling.

module xs_pmpentrycfg (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [7:0]  rdata,
    output        regOut_R,
    output        regOut_W,
    output        regOut_X,
    output [1:0]  regOut_A,
    output        regOut_L
);

  reg       reg_R;
  reg       reg_W;
  reg       reg_X;
  reg [1:0] reg_A;
  reg       reg_L;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_R <= 1'h0;
      reg_W <= 1'h0;
      reg_X <= 1'h0;
      reg_A <= 2'h0;
      reg_L <= 1'h0;
    end
    else begin
      if (w_wen) begin
        reg_R <= w_wdata[0];
        reg_X <= w_wdata[2];
        reg_A <= w_wdata[4:3] == 2'h2 ? 2'h3 : w_wdata[4:3];
        reg_L <= w_wdata[7];
      end
      // W legalization: reject the reserved R=0,W=1 combination (write dropped).
      if (w_wen & ~(~(w_wdata[0]) & w_wdata[1]))
        reg_W <= w_wdata[1];
    end
  end

  assign rdata    = {reg_L, 2'h0, reg_A, reg_X, reg_W, reg_R};
  assign regOut_R = reg_R;
  assign regOut_W = reg_W;
  assign regOut_X = reg_X;
  assign regOut_A = reg_A;
  assign regOut_L = reg_L;

endmodule
