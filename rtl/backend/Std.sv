// =============================================================================
// Std —— store-data 功能单元：把 store 的数据源原样转成写回结果
//
// 在哪一层：MemExeUnit 唯一的 FU（xiangshan/mem/MemBlock.scala class Std）。
//   store 指令拆成 sta（地址）与 std（数据）两条 uop，std 这一路不做任何运算，
//   只把 src(0) 当作结果交给 StoreQueue，并带上 robIdx 供后端定位。
// 机制：纯组合直通，零延迟——
//   in.ready  = out.ready（反压原样回传）
//   out.valid = in.valid
//   out.res.data = in.data.src(0)，out.ctrl.robIdx = in.ctrl.robIdx
//   Scala 里 out.bits 的其余字段写 0，firtool 已把这些常量口裁掉，端口表只剩上面几根。
// 边界：无时钟、无复位、无子模块。
// 结构：golden 端口 -> xs_Std_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/Std.sv
// =============================================================================
module xs_Std_core (
  // 上游（发射侧）
  output logic        in_ready,
  input  logic        in_valid,
  input  logic        in_rob_flag,
  input  logic [7:0]  in_rob_value,
  input  logic [63:0] in_store_data,
  // 下游（写回侧）
  input  logic        out_ready,
  output logic        out_valid,
  output logic        out_rob_flag,
  output logic [7:0]  out_rob_value,
  output logic [63:0] out_result
);
  // 握手：std 不缓存任何东西，valid/ready 两个方向都直通
  assign in_ready  = out_ready;
  assign out_valid = in_valid;

  // 数据：store 数据即结果；robIdx 跟着走
  assign out_result    = in_store_data;
  assign out_rob_flag  = in_rob_flag;
  assign out_rob_value = in_rob_value;
endmodule

module Std (
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic        io_in_bits_ctrl_robIdx_flag,
  input  logic [7:0]  io_in_bits_ctrl_robIdx_value,
  input  logic [63:0] io_in_bits_data_src_0,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic        io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]  io_out_bits_ctrl_robIdx_value,
  output logic [63:0] io_out_bits_res_data
);
  xs_Std_core u_core (
    .in_ready      (io_in_ready),
    .in_valid      (io_in_valid),
    .in_rob_flag   (io_in_bits_ctrl_robIdx_flag),
    .in_rob_value  (io_in_bits_ctrl_robIdx_value),
    .in_store_data (io_in_bits_data_src_0),
    .out_ready     (io_out_ready),
    .out_valid     (io_out_valid),
    .out_rob_flag  (io_out_bits_ctrl_robIdx_flag),
    .out_rob_value (io_out_bits_ctrl_robIdx_value),
    .out_result    (io_out_bits_res_data)
  );
endmodule
