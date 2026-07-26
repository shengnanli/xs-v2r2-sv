// satp UT variant (_xs): a name-distinct copy of the impl body (authoritative
// impl is FM-verified; this is only for the UT smoke test).
module SatpModule_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN
);
  reg [3:0]  reg_MODE;
  reg [15:0] reg_ASID;
  reg [43:0] reg_PPN;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0; reg_ASID <= 16'h0; reg_PPN <= 44'h0;
    end
    else if (w_wen
             & (|{w_wdata[63:60] == 4'h9, w_wdata[63:60] == 4'h8, w_wdata[63:60] == 4'h0})) begin
      reg_MODE <= w_wdata[63:60];
      reg_ASID <= w_wdata[59:44];
      reg_PPN  <= {8'h0, w_wdata[35:0]};
    end
  end
  assign rdata       = {reg_MODE, reg_ASID, reg_PPN};
  assign regOut_MODE = reg_MODE;
  assign regOut_ASID = reg_ASID;
  assign regOut_PPN  = reg_PPN;
endmodule
