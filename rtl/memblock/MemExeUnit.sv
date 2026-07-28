// ============================================================================
// MemExeUnit —— 访存执行单元顶层壳(可读手写核 xs_MemExeUnit_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden MemExeUnit.sv(firtool 展开)。本配置下 MemExeUnit 是一个纯组合
// 的数据/控制透传壳:
//   * 实例化 Std 子模块(store-data FU): io_in→io_out 的 valid/ready 握手 + robIdx
//     透传 + res_data = src_0(store 数据直接搬运, 无运算);
//   * uop 的其余四个字段(fuType/fuOpType/sqIdx_flag/sqIdx_value)在顶层组合旁路透传
//     (Std 不消费它们, 直接 io_in→io_out)。
// 逻辑等价 bug-for-bug(golden MemExeUnit.sv L106-119):
//   io_in_ready                 = io_out_ready         (来自 Std)
//   io_out_valid                = io_in_valid          (来自 Std)
//   io_out_bits_uop_robIdx_value= io_in_bits_uop_robIdx_value (来自 Std)
//   io_out_bits_data            = io_in_bits_src_0      (来自 Std, res_data=data_src_0)
//   io_out_bits_uop_fuType      = io_in_bits_uop_fuType (顶层旁路)
//   io_out_bits_uop_fuOpType    = io_in_bits_uop_fuOpType(顶层旁路)
//   io_out_bits_uop_sqIdx_flag  = io_in_bits_uop_sqIdx_flag(顶层旁路)
//   io_out_bits_uop_sqIdx_value = io_in_bits_uop_sqIdx_value(顶层旁路)
// Std 是确定性纯组合逻辑子模块(非厂商宏), 在 FM 两侧 elaborate(golden Std.sv 同读)。
// ============================================================================
module xs_MemExeUnit_core(
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

  // store-data FU: 握手 + robIdx + res_data(=src_0) 由 Std 驱动(与 golden 逐位一致)。
  Std Std (
    .io_in_ready                   (io_in_ready),
    .io_in_valid                   (io_in_valid),
    .io_in_bits_ctrl_robIdx_value  (io_in_bits_uop_robIdx_value),
    .io_in_bits_data_src_0         (io_in_bits_src_0),
    .io_out_ready                  (io_out_ready),
    .io_out_valid                  (io_out_valid),
    .io_out_bits_ctrl_robIdx_value (io_out_bits_uop_robIdx_value),
    .io_out_bits_res_data          (io_out_bits_data)
  );

  // uop 其余字段顶层组合旁路(Std 不消费, 直接 io_in→io_out 透传)。
  assign io_out_bits_uop_fuType      = io_in_bits_uop_fuType;
  assign io_out_bits_uop_fuOpType    = io_in_bits_uop_fuOpType;
  assign io_out_bits_uop_sqIdx_flag  = io_in_bits_uop_sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value = io_in_bits_uop_sqIdx_value;

endmodule
