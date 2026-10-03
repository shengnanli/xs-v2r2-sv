// Trigger0_Tdata2Module.sv — slot 0 trigger match-value register wrapper.
// The canonical value core is intentionally not reset, matching the golden sequential domain.
// Writes are accepted only on w_wen and read back unchanged on rdata.
module Trigger0_Tdata2Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);
  xs_trigger_tdata2_core u_core (
    .clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule
