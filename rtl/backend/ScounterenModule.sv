// ScounterenModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_ScounterenModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_CY,
  output logic regOut_TM,
  output logic regOut_IR,
  output logic [28:0] regOut_HPM
);
logic        reg_CY;
  logic        reg_TM;
  logic        reg_IR;
  logic [28:0] reg_HPM;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_CY <= 1'h0;
      reg_TM <= 1'h0;
      reg_IR <= 1'h0;
      reg_HPM <= 29'h0;
    end
    else if (w_wen) begin
      reg_CY <= w_wdata[0];
      reg_TM <= w_wdata[1];
      reg_IR <= w_wdata[2];
      reg_HPM <= w_wdata[31:3];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {32'h0, reg_HPM, reg_IR, reg_TM, reg_CY};
  end
  always_comb begin
    regOut_CY = reg_CY;
  end
  always_comb begin
    regOut_TM = reg_TM;
  end
  always_comb begin
    regOut_IR = reg_IR;
  end
  always_comb begin
    regOut_HPM = reg_HPM;
  end
endmodule

module ScounterenModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_TM,
  output        regOut_IR,
  output [28:0] regOut_HPM
);
  xs_ScounterenModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_CY(regOut_CY),
    .regOut_TM(regOut_TM),
    .regOut_IR(regOut_IR),
    .regOut_HPM(regOut_HPM)
  );
endmodule
