// =============================================================================
// Alu (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/Alu.sv 完全一致。
// -----------------------------------------------------------------------------
// 作用:把可读核 xs_Alu_core 适配成 golden 的扁平端口,供 Formality 等价比对
//       与系统级替换。本层是 **机械的端口适配 + 直通**:
//   - ALU 是纯组合单周期,golden 顶层 Alu 也只是把 fuOpType/src 接到
//     AluDataModule、并把 valid/robIdx/pdest/rfWen/perfDebugInfo 等控制位
//     **原样直通**(out := in)。这里照搬这层直通,核心运算交给 xs_Alu_core。
//   - fuOpType 端口 9 位,ALU 只用低 7 位(高 2 位恒由译码保证为 0)。
// =============================================================================
module Alu (
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrlPipe_0_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_0_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_0_pdest,
  input         io_in_bits_ctrlPipe_0_rfWen,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output [63:0] io_out_bits_res_data,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime
);

  // 组合运算核:src/func -> result。
  xs_Alu_core u_core (
    .src1   (io_in_bits_data_src_0),
    .src2   (io_in_bits_data_src_1),
    .func   (io_in_bits_ctrl_fuOpType[6:0]),
    .result (io_out_bits_res_data)
  );

  // 控制/调试旁路直通(对应 Scala PipedFuncUnit 的 out := in)。
  assign io_out_valid                       = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag       = io_in_bits_ctrlPipe_0_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value      = io_in_bits_ctrlPipe_0_robIdx_value;
  assign io_out_bits_ctrl_pdest             = io_in_bits_ctrlPipe_0_pdest;
  assign io_out_bits_ctrl_rfWen             = io_in_bits_ctrlPipe_0_rfWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
