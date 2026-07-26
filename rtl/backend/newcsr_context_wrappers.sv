// NewCSR context CSRs (McontextModule, ScontextModule, HcontextModule).
//
// The three *context CSRs are structurally different (unlike the trap-value
// families), so there is no shared primitive; each is faithfully transcribed
// here. FM-verified strict, no black box. HcontextModule is H-extension.
//
//   McontextModule : 14-bit HCONTEXT register. Written by a CSR write, OR by the
//                    hcontext write-through path (fromHcontext_valid latches
//                    fromHcontext_bits, w_wen takes priority). Exports its value
//                    both as the CSR read and to Hcontext (toHcontext_HCONTEXT).
//                    No reset (matches golden: clock-only register).
//   ScontextModule : plain 32-bit R/W register, no reset.
//   HcontextModule : purely combinational alias of mcontext[13:0]; a write to
//                    hcontext is forwarded to mcontext (toMcontext_valid=w_wen,
//                    toMcontext_bits=w_wdata[13:0]).

module McontextModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input         fromHcontext_valid,
  input  [13:0] fromHcontext_bits_HCONTEXT,
  output [13:0] toHcontext_HCONTEXT
);
  reg [13:0] reg_HCONTEXT;
  always @(posedge clock) begin
    if (w_wen)
      reg_HCONTEXT <= w_wdata[13:0];
    else if (fromHcontext_valid)
      reg_HCONTEXT <= fromHcontext_bits_HCONTEXT;
  end
  assign rdata               = reg_HCONTEXT;
  assign regOut_HCONTEXT     = reg_HCONTEXT;
  assign toHcontext_HCONTEXT = reg_HCONTEXT;
endmodule

module ScontextModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output [31:0] regOut_ALL
);
  reg [31:0] reg_ALL;
  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata[31:0];
  end
  assign rdata      = reg_ALL;
  assign regOut_ALL = reg_ALL;
endmodule

module HcontextModule(
  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input  [13:0] fromMcontext_HCONTEXT,
  output        toMcontext_valid,
  output [13:0] toMcontext_bits_HCONTEXT
);
  assign rdata                    = fromMcontext_HCONTEXT;
  assign regOut_HCONTEXT          = fromMcontext_HCONTEXT;
  assign toMcontext_valid         = w_wen;
  assign toMcontext_bits_HCONTEXT = w_wdata[13:0];
endmodule
