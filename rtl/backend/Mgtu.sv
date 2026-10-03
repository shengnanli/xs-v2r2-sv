// Mgtu.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_Mgtu_core(
  input  [127:0] io_in_vd,
  input  [7:0]   io_in_vl,
  output logic [127:0] io_out_vd
);
  integer lane;
  always_comb begin
    for (lane = 0; lane < 128; lane = lane + 1)
      io_out_vd[lane] = (io_in_vl <= lane) | io_in_vd[lane];
  end

endmodule

module Mgtu(
  input  [127:0] io_in_vd,
  input  [7:0]   io_in_vl,
  output [127:0] io_out_vd
);
  xs_Mgtu_core u_core (
    .io_in_vd(io_in_vd),
    .io_in_vl(io_in_vl),
    .io_out_vd(io_out_vd)
  );
endmodule
