// =============================================================================
// MemExeUnit —— std 执行单元外壳：把发射来的 uop 接到 Std 功能单元，并补齐写回 uop 字段
//
// 在哪一层：MemBlock 里 store-data 发射口的执行单元（xiangshan/backend/exu/ExeUnit.scala
//   class MemExeUnit），唯一 FU = Std（见 Std.sv）。
// 机制：纯组合——
//   - 握手与数据经 Std：in.valid/ready、src(0) -> data、robIdx 进出都走 Std 实例；
//   - 写回 uop 里 Std 不认识的字段（fuType / fuOpType / sqIdx）由本层从输入 uop 直接旁路，
//     StoreQueue 靠 sqIdx 找到要填数据的表项。
//   Scala 里 out.bits 其余字段写 0 / pdest、debugInfo 等在本配置下被 firtool 裁掉，端口表只剩下面这些。
// 边界：无时钟、无复位；flush 在 Std 内未使用，golden 端口表里已无该口。
// 结构：golden 端口 -> xs_MemExeUnit_core（可读核，内含 golden 同名子模块 Std 的实例）。
// golden 对照：G1-canonical/golden-rtl/MemExeUnit.sv
// =============================================================================
module xs_MemExeUnit_core (
  // 上游：发射来的 store-data uop
  output logic        in_ready,
  input  logic        in_valid,
  input  logic [34:0] in_fu_type,
  input  logic [8:0]  in_fu_op_type,
  input  logic        in_rob_flag,
  input  logic [7:0]  in_rob_value,
  input  logic        in_sq_flag,
  input  logic [5:0]  in_sq_value,
  input  logic [63:0] in_store_data,
  // 下游：写回给 StoreQueue
  input  logic        out_ready,
  output logic        out_valid,
  output logic [34:0] out_fu_type,
  output logic [8:0]  out_fu_op_type,
  output logic        out_rob_flag,
  output logic [7:0]  out_rob_value,
  output logic        out_sq_flag,
  output logic [5:0]  out_sq_value,
  output logic [63:0] out_data
);
  // ---- 功能单元：握手、数据、robIdx 都穿过 Std ----
  Std u_std (
    .io_in_ready                   (in_ready),
    .io_in_valid                   (in_valid),
    .io_in_bits_ctrl_robIdx_flag   (in_rob_flag),
    .io_in_bits_ctrl_robIdx_value  (in_rob_value),
    .io_in_bits_data_src_0         (in_store_data),
    .io_out_ready                  (out_ready),
    .io_out_valid                  (out_valid),
    .io_out_bits_ctrl_robIdx_flag  (out_rob_flag),
    .io_out_bits_ctrl_robIdx_value (out_rob_value),
    .io_out_bits_res_data          (out_data)
  );

  // ---- Std 不经手的 uop 字段：从输入 uop 原样旁路到写回 uop ----
  assign out_fu_type    = in_fu_type;
  assign out_fu_op_type = in_fu_op_type;
  assign out_sq_flag    = in_sq_flag;
  assign out_sq_value   = in_sq_value;
endmodule

module MemExeUnit (
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic [34:0] io_in_bits_uop_fuType,
  input  logic [8:0]  io_in_bits_uop_fuOpType,
  input  logic        io_in_bits_uop_robIdx_flag,
  input  logic [7:0]  io_in_bits_uop_robIdx_value,
  input  logic        io_in_bits_uop_sqIdx_flag,
  input  logic [5:0]  io_in_bits_uop_sqIdx_value,
  input  logic [63:0] io_in_bits_src_0,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [34:0] io_out_bits_uop_fuType,
  output logic [8:0]  io_out_bits_uop_fuOpType,
  output logic        io_out_bits_uop_robIdx_flag,
  output logic [7:0]  io_out_bits_uop_robIdx_value,
  output logic        io_out_bits_uop_sqIdx_flag,
  output logic [5:0]  io_out_bits_uop_sqIdx_value,
  output logic [63:0] io_out_bits_data
);
  xs_MemExeUnit_core u_core (
    .in_ready       (io_in_ready),
    .in_valid       (io_in_valid),
    .in_fu_type     (io_in_bits_uop_fuType),
    .in_fu_op_type  (io_in_bits_uop_fuOpType),
    .in_rob_flag    (io_in_bits_uop_robIdx_flag),
    .in_rob_value   (io_in_bits_uop_robIdx_value),
    .in_sq_flag     (io_in_bits_uop_sqIdx_flag),
    .in_sq_value    (io_in_bits_uop_sqIdx_value),
    .in_store_data  (io_in_bits_src_0),
    .out_ready      (io_out_ready),
    .out_valid      (io_out_valid),
    .out_fu_type    (io_out_bits_uop_fuType),
    .out_fu_op_type (io_out_bits_uop_fuOpType),
    .out_rob_flag   (io_out_bits_uop_robIdx_flag),
    .out_rob_value  (io_out_bits_uop_robIdx_value),
    .out_sq_flag    (io_out_bits_uop_sqIdx_flag),
    .out_sq_value   (io_out_bits_uop_sqIdx_value),
    .out_data       (io_out_bits_data)
  );
endmodule
