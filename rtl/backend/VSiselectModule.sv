// VSiselectModule.sv — virtual-supervisor indirect CSR selector and IMSIC-range decode.
// Writes with bit 12 set are ignored; reset clears the selector.
// The range output is a combinational decode used by the virtual interrupt path.
module VSiselectModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [12:0] regOut_ALL,
  output        inIMSICRange
);

  logic [12:0] value;
  always @(posedge clock or posedge reset) begin
    if (reset)
      value <= 13'h0;
    else if (w_wen & ~(w_wdata[12]))
      value <= w_wdata[12:0];
  end // always @(posedge, posedge)
  
  assign rdata = {51'h0, value};
  assign regOut_ALL = value;
  assign inIMSICRange = value > 13'h6F & value < 13'h100;
endmodule
