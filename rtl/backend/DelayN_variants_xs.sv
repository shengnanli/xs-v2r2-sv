// =============================================================================
// DelayN_*_xs —— UT 用可读核包装(与 rtl/backend/DelayN.sv 的 golden 同名 wrapper
//   逻辑一致, 仅模块名加 _xs 后缀, 以便与 golden 同时例化逐拍比对)。
// =============================================================================
module DelayN_1_xs(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(2)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule

module DelayN_15_xs(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(4)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule

module DelayN_17_xs(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(5)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule
