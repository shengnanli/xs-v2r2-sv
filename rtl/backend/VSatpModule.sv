// VSatpModule.sv — virtual-supervisor address-translation register.
// MODE/ASID/PPN are WARL state; PPN is restricted by the active guest-physical mode.
// The wrapper preserves the exact G1 ports while the core gives each field semantic names.
module VSatpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN,
  input         v,
  input  [3:0]  hgatp_MODE
);

  logic [3:0]  reg_MODE;
  logic [15:0] reg_ASID;
  logic [43:0] reg_PPN;
  wire        mode_legal =
    w_wdata[63:60] == 4'h0 | w_wdata[63:60] == 4'h8 | w_wdata[63:60] == 4'h9;
  wire        write_legal = w_wen & mode_legal;
  wire        write_nonvirtual_illegal = w_wen & ~v & ~mode_legal;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0;
      reg_ASID <= 16'h0;
      reg_PPN <= 44'h0;
    end
    else begin
      if (write_legal | write_nonvirtual_illegal & write_legal)
        reg_MODE <= w_wdata[63:60];
      if (write_legal | write_nonvirtual_illegal)
        reg_ASID <= w_wdata[59:44];
      if (write_legal | write_nonvirtual_illegal)
        reg_PPN <=
          w_wdata[43:0]
          & ((hgatp_MODE == 4'h0 ? 44'hFFFFFFFFF : 44'h0)
             | (hgatp_MODE == 4'h8 ? 44'h1FFFFFFF : 44'h0)
             | (hgatp_MODE == 4'h9 ? 44'h3FFFFFFFFF : 44'h0));
    end
  end // always @(posedge, posedge)
  
  assign rdata = {reg_MODE, reg_ASID, reg_PPN};
  assign regOut_MODE = reg_MODE;
  assign regOut_ASID = reg_ASID;
  assign regOut_PPN = reg_PPN;
endmodule
