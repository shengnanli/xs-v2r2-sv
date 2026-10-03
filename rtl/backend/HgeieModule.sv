// HgeieModule.sv — hypervisor guest external interrupt-enable CSR (hgeie).
// Holds enables for guest external interrupts 1..7 in a 7-bit register:
// CSR bit i (i=1..7) maps to reg_ie[i-1]; CSR bit 0 and bits [63:8] are
// hardwired zero. Writes are plain wen/wdata (bit slice [7:1]), no byte masks.
// Reset: asynchronous, active-high, resets the enables to all-zero (golden:
// always @(posedge clock or posedge reset), reset value 7'h0).
module xs_HgeieModule_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,            // w_wen: CSR write strobe
  input  logic [63:0] wdata,          // w_wdata: only bits [7:1] are stored
  output logic [63:0] value,          // assembled hgeie read data
  output logic [6:0]  enables         // raw enable vector to the interrupt logic
);
  logic [6:0] ie_q;

  always @(posedge clock or posedge reset) begin
    if (reset)
      ie_q <= 7'h0;
    else if (wen)
      ie_q <= wdata[7:1];
  end

  assign value   = {56'h0, ie_q, 1'h0};
  assign enables = ie_q;
endmodule

module HgeieModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [6:0]  regOut_ie
);
  xs_HgeieModule_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .value(rdata),
    .enables(regOut_ie)
  );
endmodule
