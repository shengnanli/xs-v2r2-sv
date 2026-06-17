// VSetRiWi_xs —— UT 用的可读核包装(golden 同端口,改名避免与 golden 冲突)。
// 与 rtl/backend/VSetRiWi_wrapper.sv(名为 VSetRiWi,FM 用)逻辑一致,仅模块名不同。
module VSetRiWi_xs (
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

  assign io_out_valid                         = io_in_valid;
  assign io_out_bits_ctrl_robIdx_flag         = io_in_bits_ctrl_robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value        = io_in_bits_ctrl_robIdx_value;
  assign io_out_bits_ctrl_pdest               = io_in_bits_ctrl_pdest;
  assign io_out_bits_ctrl_rfWen               = io_in_bits_ctrl_rfWen;
  assign io_out_bits_perfDebugInfo_enqRsTime  = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime  = io_in_bits_perfDebugInfo_issueTime;

endmodule
