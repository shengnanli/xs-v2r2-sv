// =============================================================================
// Bku_wrapper —— golden 同名顶层端口适配层（FM / ST 用）
//
// 机械地把 firtool golden 的扁平端口拆/拼成可读核 xs_Bku_core 的结构体端口。
// 本层不含任何运算逻辑，只做线连接，允许平铺。
// =============================================================================
module Bku (
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_rfWen,
  input         io_in_bits_validPipe_0,
  input         io_in_bits_validPipe_1,
  input         io_in_bits_validPipe_2,
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
  import xs_bku_pkg::*;

  bku_ctrl_t in_ctrl, out_ctrl;
  bku_perf_t in_perf, out_perf;

  assign in_ctrl = '{
    robIdx_flag:  io_in_bits_ctrlPipe_2_robIdx_flag,
    robIdx_value: io_in_bits_ctrlPipe_2_robIdx_value,
    pdest:        io_in_bits_ctrlPipe_2_pdest,
    rfWen:        io_in_bits_ctrlPipe_2_rfWen
  };
  assign in_perf = '{
    enqRsTime:  io_in_bits_perfDebugInfo_enqRsTime,
    selectTime: io_in_bits_perfDebugInfo_selectTime,
    issueTime:  io_in_bits_perfDebugInfo_issueTime
  };

  xs_Bku_core u_core (
    .clock        (clock),
    .reset        (reset),
    .in_valid     (io_in_valid),
    .in_fuOpType  (io_in_bits_ctrl_fuOpType),
    .in_src0      (io_in_bits_data_src_0),
    .in_src1      (io_in_bits_data_src_1),
    .in_perf      (in_perf),
    .in_validPipe0(io_in_bits_validPipe_0),
    .in_validPipe1(io_in_bits_validPipe_1),
    .in_validPipe2(io_in_bits_validPipe_2),
    .in_ctrlPipe2 (in_ctrl),
    .out_valid    (io_out_valid),
    .out_ctrl     (out_ctrl),
    .out_res_data (io_out_bits_res_data),
    .out_perf     (out_perf)
  );

  assign io_out_bits_ctrl_robIdx_flag  = out_ctrl.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_ctrl.robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_ctrl.pdest;
  assign io_out_bits_ctrl_rfWen        = out_ctrl.rfWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = out_perf.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = out_perf.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = out_perf.issueTime;
endmodule
