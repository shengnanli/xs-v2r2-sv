// =============================================================================
// Fence —— golden 同名扁平端口包装层（机械适配，供 FM 等价比对 / ST 替换）
//
// 职责：把 golden（firtool）展平的 io_* 标量端口拼成 fence_pkg 的 struct，例化可读核
// xs_Fence_core，再把核输出拆回扁平端口。本层不含微架构逻辑，只做端口拼装与
// 几个恒定值（res.data=0、perfDebugInfo 透传）的补齐。
// =============================================================================
module Fence
  import fence_pkg::*;
(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_flushPipe,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_data_imm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_flushPipe,
  output [63:0] io_out_bits_res_data,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output        io_fenceio_sfence_valid,
  output        io_fenceio_sfence_bits_rs1,
  output        io_fenceio_sfence_bits_rs2,
  output [49:0] io_fenceio_sfence_bits_addr,
  output [15:0] io_fenceio_sfence_bits_id,
  output        io_fenceio_sfence_bits_flushPipe,
  output        io_fenceio_sfence_bits_hv,
  output        io_fenceio_sfence_bits_hg,
  output        io_fenceio_fencei,
  output        io_fenceio_sbuffer_flushSb,
  input         io_fenceio_sbuffer_sbIsEmpty
);

  // 入口字段 → struct
  fence_uop_t in_uop;
  assign in_uop.fuOpType     = io_in_bits_ctrl_fuOpType;
  assign in_uop.robIdx_flag  = io_in_bits_ctrl_robIdx_flag;
  assign in_uop.robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign in_uop.pdest        = io_in_bits_ctrl_pdest;
  assign in_uop.flushPipe    = io_in_bits_ctrl_flushPipe;
  assign in_uop.imm          = io_in_bits_data_imm[IMM_USED_W-1:0]; // 仅低 10 位被 sfence 判定读取

  fence_uop_t out_uop;

  xs_Fence_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_uop           (in_uop),
    .in_src0          (io_in_bits_data_src_0),
    .in_src1          (io_in_bits_data_src_1),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_uop          (out_uop),
    .sbuffer_flushSb  (io_fenceio_sbuffer_flushSb),
    .sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty),
    .fencei           (io_fenceio_fencei),
    .sfence_valid     (io_fenceio_sfence_valid),
    .sfence_rs1       (io_fenceio_sfence_bits_rs1),
    .sfence_rs2       (io_fenceio_sfence_bits_rs2),
    .sfence_addr      (io_fenceio_sfence_bits_addr),
    .sfence_id        (io_fenceio_sfence_bits_id),
    .sfence_flushPipe (io_fenceio_sfence_bits_flushPipe),
    .sfence_hv        (io_fenceio_sfence_bits_hv),
    .sfence_hg        (io_fenceio_sfence_bits_hg)
  );

  // 出口 struct → 扁平端口（res.data 恒 0，perf 信息直透）
  assign io_out_bits_ctrl_robIdx_flag  = out_uop.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_uop.robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_uop.pdest;
  assign io_out_bits_ctrl_flushPipe    = out_uop.flushPipe;
  assign io_out_bits_res_data          = 64'h0;
  assign io_out_bits_perfDebugInfo_enqRsTime   = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime  = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime   = io_in_bits_perfDebugInfo_issueTime;

endmodule
