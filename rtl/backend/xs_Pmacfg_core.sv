// xs_Pmacfg_core — readable, parameterized PMA configuration CSR state.
//
// Each PMA slot has the same seven architectural fields.  Reset is asynchronous
// and dominant.  A write updates R/W/X/ATOMIC/C/L and updates A only when the
// golden WARL predicate accepts the two-bit encoding.  The golden design does
// not make L sticky: L is an ordinary writable field, so that behavior is kept.
module xs_Pmacfg_core #(
  parameter int PMA_INDEX = 0
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       w_wen,
  input  logic [63:0] w_wdata,
  output logic [7:0] rdata,
  output logic       regOut_R,
  output logic       regOut_W,
  output logic       regOut_X,
  output logic [1:0] regOut_A,
  output logic       regOut_ATOMIC,
  output logic       regOut_C,
  output logic       regOut_L
);
  logic       reg_R;
  logic       reg_W;
  logic       reg_X;
  logic [1:0] reg_A;
  logic       reg_ATOMIC;
  logic       reg_C;
  logic       reg_L;

  // The four two-bit encodings are exactly the four cases accepted by golden.
  logic a_warl_legal;
  assign a_warl_legal = (w_wdata[4:3] == 2'h0) |
                        (w_wdata[4:3] == 2'h1) |
                        (w_wdata[4:3] == 2'h2) |
                        (&w_wdata[4:3]);

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_R      <= 1'b0;
      reg_W      <= 1'b0;
      reg_X      <= 1'b0;
      reg_A      <= 2'b0;
      reg_ATOMIC <= 1'b0;
      reg_C      <= 1'b0;
      reg_L      <= 1'b0;
    end else begin
      if (w_wen) begin
        reg_R      <= w_wdata[0];
        reg_W      <= w_wdata[1];
        reg_X      <= w_wdata[2];
        reg_ATOMIC <= w_wdata[5];
        reg_C      <= w_wdata[6];
        reg_L      <= w_wdata[7];
      end
      if (w_wen && a_warl_legal)
        reg_A <= w_wdata[4:3];
    end
  end

  assign rdata       = {reg_L, reg_C, reg_ATOMIC, reg_A, reg_X, reg_W, reg_R};
  assign regOut_R    = reg_R;
  assign regOut_W    = reg_W;
  assign regOut_X    = reg_X;
  assign regOut_A    = reg_A;
  assign regOut_ATOMIC = reg_ATOMIC;
  assign regOut_C    = reg_C;
  assign regOut_L    = reg_L;
endmodule
