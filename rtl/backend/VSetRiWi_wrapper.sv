// =============================================================================
// VSetRiWi (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/VSetRiWi.sv 一致。
// -----------------------------------------------------------------------------
// 作用:把可读核 xs_VSetRiWi_core 适配成 golden 扁平端口,供 Formality 等价比对
//       与系统替换。本层为机械的端口适配 + 控制位直通(对应 VSetBase 的
//       out := in 直通:valid/robIdx/pdest/rfWen/perfDebugInfo 原样透传)。
// =============================================================================
module VSetRiWi (
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_rfWen,
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

  xs_VSetRiWi_core u_core (
    .func     (io_in_bits_ctrl_fuOpType),
    .src0     (io_in_bits_data_src_0),
    .src1     (io_in_bits_data_src_1),
    .res_data (io_out_bits_res_data)
  );

  // 控制/调试旁路直通(VSetBase: out := in)。
  assign io_out_valid                         = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag         = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value        = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest               = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen               = io_in_bits_ctrl_rfWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
