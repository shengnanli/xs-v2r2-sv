// MidelegModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_MidelegModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_SSI,
  output logic regOut_STI,
  output logic regOut_SEI,
  output logic regOut_LCOFI
);
logic reg_SSI;
  logic reg_STI;
  logic reg_SEI;
  logic reg_LCOFI;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SSI <= 1'h0;
      reg_STI <= 1'h0;
      reg_SEI <= 1'h0;
      reg_LCOFI <= 1'h0;
    end
    else if (w_wen) begin
      reg_SSI <= w_wdata[1];
      reg_STI <= w_wdata[5];
      reg_SEI <= w_wdata[9];
      reg_LCOFI <= w_wdata[13];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {50'h0, reg_LCOFI, 3'h5, reg_SEI, 3'h1, reg_STI, 3'h1, reg_SSI, 1'h0};
  end
  always_comb begin
    regOut_SSI = reg_SSI;
  end
  always_comb begin
    regOut_STI = reg_STI;
  end
  always_comb begin
    regOut_SEI = reg_SEI;
  end
  always_comb begin
    regOut_LCOFI = reg_LCOFI;
  end
endmodule

module MidelegModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSI,
  output        regOut_STI,
  output        regOut_SEI,
  output        regOut_LCOFI
);
  xs_MidelegModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SSI(regOut_SSI),
    .regOut_STI(regOut_STI),
    .regOut_SEI(regOut_SEI),
    .regOut_LCOFI(regOut_LCOFI)
  );
endmodule
