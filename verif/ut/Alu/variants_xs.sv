// Alu_xs —— UT 用的可读核包装(golden 同端口,改名避免与 golden Alu 冲突)。
// 与 rtl/backend/Alu_wrapper.sv(名为 Alu,FM 用)逻辑一致,仅模块名不同,
// 使 tb 能同时例化 golden Alu(u_g) 与可读核 Alu_xs(u_i) 逐拍比对。
module Alu_xs (
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

  xs_Alu_core u_core (
    .src1   (io_in_bits_data_src_0),
    .src2   (io_in_bits_data_src_1),
    .func   (io_in_bits_ctrl_fuOpType[6:0]),
    .result (io_out_bits_res_data)
  );

  assign io_out_valid                       = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag       = io_in_bits_ctrlPipe_0_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value      = io_in_bits_ctrlPipe_0_robIdx_value;
  assign io_out_bits_ctrl_pdest             = io_in_bits_ctrlPipe_0_pdest;
  assign io_out_bits_ctrl_rfWen             = io_in_bits_ctrlPipe_0_rfWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
