// MemExeUnit_xs —— UT 用变体(与 MemExeUnit_wrapper 同, 仅模块名改为 MemExeUnit_xs)。
// 供 UT 与 golden MemExeUnit 双例化对拍。内部 Std 子模块两侧共用 golden Std.sv 定义。
module MemExeUnit_xs(
  output        io_in_ready,
  input         io_in_valid,
  input  [34:0] io_in_bits_uop_fuType,
  input  [8:0]  io_in_bits_uop_fuOpType,
  input  [7:0]  io_in_bits_uop_robIdx_value,
  input         io_in_bits_uop_sqIdx_flag,
  input  [5:0]  io_in_bits_uop_sqIdx_value,
  input  [63:0] io_in_bits_src_0,
  input         io_out_ready,
  output        io_out_valid,
  output [34:0] io_out_bits_uop_fuType,
  output [8:0]  io_out_bits_uop_fuOpType,
  output [7:0]  io_out_bits_uop_robIdx_value,
  output        io_out_bits_uop_sqIdx_flag,
  output [5:0]  io_out_bits_uop_sqIdx_value,
  output [63:0] io_out_bits_data
);
  xs_MemExeUnit_core u_core (
    .io_in_ready                 (io_in_ready),
    .io_in_valid                 (io_in_valid),
    .io_in_bits_uop_fuType       (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType     (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_sqIdx_flag   (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value  (io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0            (io_in_bits_src_0),
    .io_out_ready                (io_out_ready),
    .io_out_valid                (io_out_valid),
    .io_out_bits_uop_fuType      (io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType    (io_out_bits_uop_fuOpType),
    .io_out_bits_uop_robIdx_value(io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_sqIdx_flag  (io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value (io_out_bits_uop_sqIdx_value),
    .io_out_bits_data            (io_out_bits_data)
  );
endmodule
