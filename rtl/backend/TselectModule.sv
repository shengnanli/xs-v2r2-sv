// TselectModule.sv — trigger select CSR (tselect).
// A 2-bit read/write register selecting one of the (few) implemented triggers.
// Write-ignore semantics, bug-for-bug from golden: a write takes effect only
// when w_wdata < 64'h4; writes of any larger value are silently dropped and
// the register keeps its old value. Only w_wdata[1:0] is stored.
// Reset: asynchronous, active-high, resets to 2'h0.
module xs_TselectModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [1:0]  value,
  output logic [1:0]  mirror
);
  logic [1:0] select_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      select_q <= 2'h0;
    else if (wen & (wdata < 64'h4))
      select_q <= wdata[1:0];
  end

  assign value  = select_q;
  assign mirror = select_q;
endmodule

module TselectModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [1:0]  rdata,
  output [1:0]  regOut_ALL
);
  xs_TselectModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
