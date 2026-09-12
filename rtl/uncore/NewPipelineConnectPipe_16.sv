// NewPipelineConnectPipe_16 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）
// 端口规模：35 输入 / 31 输出；本文件只做参数化与端口展平。
// 端口规模：35 输入 / 31 输出。

module NewPipelineConnectPipe_16(
  input  clock,
  input  reset,
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
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_fpu_wflags,
  input  io_in_bits_vpu_vma,
  input  io_in_bits_vpu_vta,
  input  [1:0] io_in_bits_vpu_vsew,
  input  [2:0] io_in_bits_vpu_vlmul,
  input  io_in_bits_vpu_vm,
  input  [7:0] io_in_bits_vpu_vstart,
  input  io_in_bits_vpu_fpu_isFoldTo1_2,
  input  io_in_bits_vpu_fpu_isFoldTo1_4,
  input  io_in_bits_vpu_fpu_isFoldTo1_8,
  input  [6:0] io_in_bits_vpu_vuopIdx,
  input  io_in_bits_vpu_lastUop,
  input  io_in_bits_vpu_isNarrow,
  input  io_in_bits_vpu_isDstMask,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
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
  output [7:0] io_out_bits_pdest,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_fpu_wflags,
  output io_out_bits_vpu_vma,
  output io_out_bits_vpu_vta,
  output [1:0] io_out_bits_vpu_vsew,
  output [2:0] io_out_bits_vpu_vlmul,
  output io_out_bits_vpu_vm,
  output [7:0] io_out_bits_vpu_vstart,
  output io_out_bits_vpu_fpu_isFoldTo1_2,
  output io_out_bits_vpu_fpu_isFoldTo1_4,
  output io_out_bits_vpu_fpu_isFoldTo1_8,
  output [6:0] io_out_bits_vpu_vuopIdx,
  output io_out_bits_vpu_lastUop,
  output io_out_bits_vpu_isNarrow,
  output io_out_bits_vpu_isDstMask,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [925:0] out_bus;
  assign io_out_bits_fuType = out_bus[925:891];
  assign io_out_bits_fuOpType = out_bus[890:882];
  assign io_out_bits_src_0 = out_bus[881:754];
  assign io_out_bits_src_1 = out_bus[753:626];
  assign io_out_bits_src_2 = out_bus[625:498];
  assign io_out_bits_src_3 = out_bus[497:370];
  assign io_out_bits_src_4 = out_bus[369:242];
  assign io_out_bits_robIdx_flag = out_bus[241:241];
  assign io_out_bits_robIdx_value = out_bus[240:233];
  assign io_out_bits_pdest = out_bus[232:225];
  assign io_out_bits_fpWen = out_bus[224:224];
  assign io_out_bits_vecWen = out_bus[223:223];
  assign io_out_bits_v0Wen = out_bus[222:222];
  assign io_out_bits_fpu_wflags = out_bus[221:221];
  assign io_out_bits_vpu_vma = out_bus[220:220];
  assign io_out_bits_vpu_vta = out_bus[219:219];
  assign io_out_bits_vpu_vsew = out_bus[218:217];
  assign io_out_bits_vpu_vlmul = out_bus[216:214];
  assign io_out_bits_vpu_vm = out_bus[213:213];
  assign io_out_bits_vpu_vstart = out_bus[212:205];
  assign io_out_bits_vpu_fpu_isFoldTo1_2 = out_bus[204:204];
  assign io_out_bits_vpu_fpu_isFoldTo1_4 = out_bus[203:203];
  assign io_out_bits_vpu_fpu_isFoldTo1_8 = out_bus[202:202];
  assign io_out_bits_vpu_vuopIdx = out_bus[201:195];
  assign io_out_bits_vpu_lastUop = out_bus[194:194];
  assign io_out_bits_vpu_isNarrow = out_bus[193:193];
  assign io_out_bits_vpu_isDstMask = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(926)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_src_3, io_in_bits_src_4, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_fpu_wflags, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_lastUop, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
