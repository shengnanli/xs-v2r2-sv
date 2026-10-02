// Shared PMP configuration CSR core for the eight family-I leaves.
// One entry stores the R/W/X permissions, WARL A encoding, and lock bit.
// Writes are accepted on the clock edge unless reset is asserted; the W bit
// is intentionally held when a write requests the reserved R=0/W=1 encoding.
module xs_Pmpcfg_core #(
  parameter int unsigned SLOT = 0
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
  output logic       regOut_L
);
  logic reg_R;
  logic reg_W;
  logic reg_X;
  logic [1:0] reg_A;
  logic reg_L;

  // The A field maps the reserved 2'b10 request to TOR (2'b11).
  // R, X, and L update together; W has golden's reserved-combination guard.
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_R <= 1'b0;
      reg_W <= 1'b0;
      reg_X <= 1'b0;
      reg_A <= 2'b00;
      reg_L <= 1'b0;
    end else begin
      if (w_wen) begin
        reg_R <= w_wdata[0];
        reg_X <= w_wdata[2];
        reg_A <= (w_wdata[4:3] == 2'b10) ? 2'b11 : w_wdata[4:3];
        reg_L <= w_wdata[7];
      end
      if (w_wen & ~(~w_wdata[0] & w_wdata[1]))
        reg_W <= w_wdata[1];
    end
  end

  assign rdata = {reg_L, 2'b00, reg_A, reg_X, reg_W, reg_R};
  assign regOut_R = reg_R;
  assign regOut_W = reg_W;
  assign regOut_X = reg_X;
  assign regOut_A = reg_A;
  assign regOut_L = reg_L;
endmodule
