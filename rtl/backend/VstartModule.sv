// VstartModule.sv — vector restart index CSR.
// A CSR write wins over commit metadata; dirty commits clear or replace the index.
// The asynchronous reset value is zero, preserving restart behavior after reset.
module VstartModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [6:0]  regOut_vstart,
  input         robCommit_vsDirty,
  input         robCommit_vstart_valid,
  input  [6:0]  robCommit_vstart_bits
);

  logic [6:0] reg_vstart;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_vstart <= 7'h0;
    else if (w_wen)
      reg_vstart <= w_wdata[6:0];
    else if (robCommit_vsDirty & ~robCommit_vstart_valid)
      reg_vstart <= 7'h0;
    else if (robCommit_vstart_valid)
      reg_vstart <= robCommit_vstart_bits;
  end // always @(posedge, posedge)
  
  assign rdata = {57'h0, reg_vstart};
  assign regOut_vstart = reg_vstart;
endmodule
