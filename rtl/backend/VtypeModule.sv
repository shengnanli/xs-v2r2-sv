// VtypeModule.sv — committed vector type state.
// vtype starts illegal (VILL=1) and changes only on a valid ROB commit.
// The packed rdata layout is the architectural VILL/VMA/VTA/VSEW/VLMUL layout.
module VtypeModule(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input         robCommit_vtype_valid,
  input         robCommit_vtype_bits_VILL,
  input         robCommit_vtype_bits_VMA,
  input         robCommit_vtype_bits_VTA,
  input  [2:0]  robCommit_vtype_bits_VSEW,
  input  [2:0]  robCommit_vtype_bits_VLMUL
);

  logic      reg_VILL;
  logic      reg_VMA;
  logic      reg_VTA;
  logic [2:0] reg_VSEW;
  logic [2:0] reg_VLMUL;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_VILL <= 1'h1;
      reg_VMA <= 1'h0;
      reg_VTA <= 1'h0;
      reg_VSEW <= 3'h0;
      reg_VLMUL <= 3'h0;
    end
    else if (robCommit_vtype_valid) begin
      reg_VILL <= robCommit_vtype_bits_VILL;
      reg_VMA <= robCommit_vtype_bits_VMA;
      reg_VTA <= robCommit_vtype_bits_VTA;
      reg_VSEW <= robCommit_vtype_bits_VSEW;
      reg_VLMUL <= robCommit_vtype_bits_VLMUL;
    end
  end // always @(posedge, posedge)
  
  assign rdata = {reg_VILL, 55'h0, reg_VMA, reg_VTA, reg_VSEW, reg_VLMUL};
endmodule
