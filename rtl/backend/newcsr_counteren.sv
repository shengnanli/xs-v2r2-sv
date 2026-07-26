// NewCSR CSR-field primitive: counteren (*counteren counter-enable CSR).
//
// Faithful, readable reimplementation of the golden {M,S,H}counterenModule
// family — all three golden bodies are byte-identical. A *counteren CSR gates
// lower-privilege access to the performance counters:
//   CY  = bit 0     (cycle)
//   TM  = bit 1     (time)
//   IR  = bit 2     (instret)
//   HPM = bits 31:3 (hpmcounter3..31, 29 bits)
// The upper 32 bits read as 0. All fields plain R/W, async-reset to 0.

module xs_counteren (
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

  reg        reg_CY;
  reg        reg_TM;
  reg        reg_IR;
  reg [28:0] reg_HPM;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_CY  <= 1'h0;
      reg_TM  <= 1'h0;
      reg_IR  <= 1'h0;
      reg_HPM <= 29'h0;
    end
    else if (w_wen) begin
      reg_CY  <= w_wdata[0];
      reg_TM  <= w_wdata[1];
      reg_IR  <= w_wdata[2];
      reg_HPM <= w_wdata[31:3];
    end
  end

  assign rdata      = {32'h0, reg_HPM, reg_IR, reg_TM, reg_CY};
  assign regOut_CY  = reg_CY;
  assign regOut_TM  = reg_TM;
  assign regOut_IR  = reg_IR;
  assign regOut_HPM = reg_HPM;

endmodule
