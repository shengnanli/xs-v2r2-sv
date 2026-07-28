// ============================================================================
// MemExeUnit_wrapper —— golden 同名顶层 `MemExeUnit`(扁平端口 ↔ xs_MemExeUnit_core)
// 端口与 golden/chisel-rtl/MemExeUnit.sv 逐位一致。仅做机械端口透传, 供 FM / ST。
// 内部实例化可读手写核 xs_MemExeUnit_core(其 Std 子模块两侧 elaborate golden Std.sv)。
// ============================================================================
module MemExeUnit(
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
