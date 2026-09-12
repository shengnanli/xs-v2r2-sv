// NewPipelineConnectPipe_23 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）
// 本文件只做端口适配与直通，不含逻辑。
// 端口规模：42 输入 / 38 输出。

module NewPipelineConnectPipe_23(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [6:0] io_in_bits_pdest,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_vlWen,
  input  io_in_bits_vpu_vma,
  input  io_in_bits_vpu_vta,
  input  [1:0] io_in_bits_vpu_vsew,
  input  [2:0] io_in_bits_vpu_vlmul,
  input  io_in_bits_vpu_vm,
  input  [7:0] io_in_bits_vpu_vstart,
  input  [6:0] io_in_bits_vpu_vuopIdx,
  input  io_in_bits_vpu_lastUop,
  input  [127:0] io_in_bits_vpu_vmask,
  input  [2:0] io_in_bits_vpu_nf,
  input  [1:0] io_in_bits_vpu_veew,
  input  io_in_bits_vpu_isVleff,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  [4:0] io_in_bits_numLsElem,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  io_in_bits_lqIdx_flag,
  input  [6:0] io_in_bits_lqIdx_value,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [127:0] io_out_bits_src_0,
  output [127:0] io_out_bits_src_1,
  output [127:0] io_out_bits_src_2,
  output [127:0] io_out_bits_src_3,
  output [127:0] io_out_bits_src_4,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [6:0] io_out_bits_pdest,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_vlWen,
  output io_out_bits_vpu_vma,
  output io_out_bits_vpu_vta,
  output [1:0] io_out_bits_vpu_vsew,
  output [2:0] io_out_bits_vpu_vlmul,
  output io_out_bits_vpu_vm,
  output [7:0] io_out_bits_vpu_vstart,
  output [6:0] io_out_bits_vpu_vuopIdx,
  output io_out_bits_vpu_lastUop,
  output [127:0] io_out_bits_vpu_vmask,
  output [2:0] io_out_bits_vpu_nf,
  output [1:0] io_out_bits_vpu_veew,
  output io_out_bits_vpu_isVleff,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output [4:0] io_out_bits_numLsElem,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  output io_out_bits_lqIdx_flag,
  output [6:0] io_out_bits_lqIdx_value,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [1083:0] out_bus;
  assign io_out_bits_fuType = out_bus[1083:1049];
  assign io_out_bits_fuOpType = out_bus[1048:1040];
  assign io_out_bits_src_0 = out_bus[1039:912];
  assign io_out_bits_src_1 = out_bus[911:784];
  assign io_out_bits_src_2 = out_bus[783:656];
  assign io_out_bits_src_3 = out_bus[655:528];
  assign io_out_bits_src_4 = out_bus[527:400];
  assign io_out_bits_robIdx_flag = out_bus[399:399];
  assign io_out_bits_robIdx_value = out_bus[398:391];
  assign io_out_bits_pdest = out_bus[390:384];
  assign io_out_bits_vecWen = out_bus[383:383];
  assign io_out_bits_v0Wen = out_bus[382:382];
  assign io_out_bits_vlWen = out_bus[381:381];
  assign io_out_bits_vpu_vma = out_bus[380:380];
  assign io_out_bits_vpu_vta = out_bus[379:379];
  assign io_out_bits_vpu_vsew = out_bus[378:377];
  assign io_out_bits_vpu_vlmul = out_bus[376:374];
  assign io_out_bits_vpu_vm = out_bus[373:373];
  assign io_out_bits_vpu_vstart = out_bus[372:365];
  assign io_out_bits_vpu_vuopIdx = out_bus[364:358];
  assign io_out_bits_vpu_lastUop = out_bus[357:357];
  assign io_out_bits_vpu_vmask = out_bus[356:229];
  assign io_out_bits_vpu_nf = out_bus[228:226];
  assign io_out_bits_vpu_veew = out_bus[225:224];
  assign io_out_bits_vpu_isVleff = out_bus[223:223];
  assign io_out_bits_ftqIdx_flag = out_bus[222:222];
  assign io_out_bits_ftqIdx_value = out_bus[221:216];
  assign io_out_bits_ftqOffset = out_bus[215:212];
  assign io_out_bits_numLsElem = out_bus[211:207];
  assign io_out_bits_sqIdx_flag = out_bus[206:206];
  assign io_out_bits_sqIdx_value = out_bus[205:200];
  assign io_out_bits_lqIdx_flag = out_bus[199:199];
  assign io_out_bits_lqIdx_value = out_bus[198:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(1084)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_src_3, io_in_bits_src_4, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_lastUop, io_in_bits_vpu_vmask, io_in_bits_vpu_nf, io_in_bits_vpu_veew, io_in_bits_vpu_isVleff, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_numLsElem, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value, io_in_bits_lqIdx_flag, io_in_bits_lqIdx_value, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
