// VStimecmpModule.sv — virtual-supervisor timer compare register.
// It resets to all ones so the timer cannot interrupt before software programs it.
// A write updates the full 64-bit compare value and the mirror output.
module VStimecmpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_vstimecmp
);

  logic [63:0] reg_vstimecmp;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_vstimecmp <= 64'hFFFFFFFFFFFFFFFF;
    else if (w_wen)
      reg_vstimecmp <= w_wdata;
  end // always @(posedge, posedge)
  
  assign rdata = reg_vstimecmp;
  assign regOut_vstimecmp = reg_vstimecmp;
endmodule
