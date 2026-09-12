// NewPipelineConnectPipe_27 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）
// 本文件只做端口适配与直通，不含逻辑。
// 端口规模：43 输入 / 39 输出。

module NewPipelineConnectPipe_27(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  io_in_bits_uop_exceptionVec_3,
  input  io_in_bits_uop_exceptionVec_4,
  input  io_in_bits_uop_exceptionVec_5,
  input  io_in_bits_uop_exceptionVec_6,
  input  io_in_bits_uop_exceptionVec_7,
  input  io_in_bits_uop_exceptionVec_13,
  input  io_in_bits_uop_exceptionVec_15,
  input  io_in_bits_uop_exceptionVec_19,
  input  io_in_bits_uop_exceptionVec_21,
  input  io_in_bits_uop_exceptionVec_23,
  input  [3:0] io_in_bits_uop_trigger,
  input  [8:0] io_in_bits_uop_fuOpType,
  input  io_in_bits_uop_vecWen,
  input  io_in_bits_uop_v0Wen,
  input  io_in_bits_uop_vlWen,
  input  io_in_bits_uop_flushPipe,
  input  io_in_bits_uop_vpu_vma,
  input  io_in_bits_uop_vpu_vta,
  input  [1:0] io_in_bits_uop_vpu_vsew,
  input  [2:0] io_in_bits_uop_vpu_vlmul,
  input  io_in_bits_uop_vpu_vm,
  input  [7:0] io_in_bits_uop_vpu_vstart,
  input  [6:0] io_in_bits_uop_vpu_vuopIdx,
  input  [127:0] io_in_bits_uop_vpu_vmask,
  input  [7:0] io_in_bits_uop_vpu_vl,
  input  [2:0] io_in_bits_uop_vpu_nf,
  input  [1:0] io_in_bits_uop_vpu_veew,
  input  [7:0] io_in_bits_uop_pdest,
  input  io_in_bits_uop_robIdx_flag,
  input  [7:0] io_in_bits_uop_robIdx_value,
  input  [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  io_in_bits_uop_replayInst,
  input  [127:0] io_in_bits_data,
  input  [2:0] io_in_bits_vdIdx,
  input  [2:0] io_in_bits_vdIdxInField,
  input  io_out_ready,
  output io_out_valid,
  output io_out_bits_uop_exceptionVec_3,
  output io_out_bits_uop_exceptionVec_4,
  output io_out_bits_uop_exceptionVec_5,
  output io_out_bits_uop_exceptionVec_6,
  output io_out_bits_uop_exceptionVec_7,
  output io_out_bits_uop_exceptionVec_13,
  output io_out_bits_uop_exceptionVec_15,
  output io_out_bits_uop_exceptionVec_19,
  output io_out_bits_uop_exceptionVec_21,
  output io_out_bits_uop_exceptionVec_23,
  output [3:0] io_out_bits_uop_trigger,
  output [8:0] io_out_bits_uop_fuOpType,
  output io_out_bits_uop_vecWen,
  output io_out_bits_uop_v0Wen,
  output io_out_bits_uop_vlWen,
  output io_out_bits_uop_flushPipe,
  output io_out_bits_uop_vpu_vma,
  output io_out_bits_uop_vpu_vta,
  output [1:0] io_out_bits_uop_vpu_vsew,
  output [2:0] io_out_bits_uop_vpu_vlmul,
  output io_out_bits_uop_vpu_vm,
  output [7:0] io_out_bits_uop_vpu_vstart,
  output [6:0] io_out_bits_uop_vpu_vuopIdx,
  output [127:0] io_out_bits_uop_vpu_vmask,
  output [7:0] io_out_bits_uop_vpu_vl,
  output [2:0] io_out_bits_uop_vpu_nf,
  output [1:0] io_out_bits_uop_vpu_veew,
  output [7:0] io_out_bits_uop_pdest,
  output io_out_bits_uop_robIdx_flag,
  output [7:0] io_out_bits_uop_robIdx_value,
  output [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_out_bits_uop_debugInfo_selectTime,
  output [63:0] io_out_bits_uop_debugInfo_issueTime,
  output io_out_bits_uop_replayInst,
  output [127:0] io_out_bits_data,
  output [2:0] io_out_bits_vdIdx,
  output [2:0] io_out_bits_vdIdxInField,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [534:0] out_bus;
  assign io_out_bits_uop_exceptionVec_3 = out_bus[534:534];
  assign io_out_bits_uop_exceptionVec_4 = out_bus[533:533];
  assign io_out_bits_uop_exceptionVec_5 = out_bus[532:532];
  assign io_out_bits_uop_exceptionVec_6 = out_bus[531:531];
  assign io_out_bits_uop_exceptionVec_7 = out_bus[530:530];
  assign io_out_bits_uop_exceptionVec_13 = out_bus[529:529];
  assign io_out_bits_uop_exceptionVec_15 = out_bus[528:528];
  assign io_out_bits_uop_exceptionVec_19 = out_bus[527:527];
  assign io_out_bits_uop_exceptionVec_21 = out_bus[526:526];
  assign io_out_bits_uop_exceptionVec_23 = out_bus[525:525];
  assign io_out_bits_uop_trigger = out_bus[524:521];
  assign io_out_bits_uop_fuOpType = out_bus[520:512];
  assign io_out_bits_uop_vecWen = out_bus[511:511];
  assign io_out_bits_uop_v0Wen = out_bus[510:510];
  assign io_out_bits_uop_vlWen = out_bus[509:509];
  assign io_out_bits_uop_flushPipe = out_bus[508:508];
  assign io_out_bits_uop_vpu_vma = out_bus[507:507];
  assign io_out_bits_uop_vpu_vta = out_bus[506:506];
  assign io_out_bits_uop_vpu_vsew = out_bus[505:504];
  assign io_out_bits_uop_vpu_vlmul = out_bus[503:501];
  assign io_out_bits_uop_vpu_vm = out_bus[500:500];
  assign io_out_bits_uop_vpu_vstart = out_bus[499:492];
  assign io_out_bits_uop_vpu_vuopIdx = out_bus[491:485];
  assign io_out_bits_uop_vpu_vmask = out_bus[484:357];
  assign io_out_bits_uop_vpu_vl = out_bus[356:349];
  assign io_out_bits_uop_vpu_nf = out_bus[348:346];
  assign io_out_bits_uop_vpu_veew = out_bus[345:344];
  assign io_out_bits_uop_pdest = out_bus[343:336];
  assign io_out_bits_uop_robIdx_flag = out_bus[335:335];
  assign io_out_bits_uop_robIdx_value = out_bus[334:327];
  assign io_out_bits_uop_debugInfo_enqRsTime = out_bus[326:263];
  assign io_out_bits_uop_debugInfo_selectTime = out_bus[262:199];
  assign io_out_bits_uop_debugInfo_issueTime = out_bus[198:135];
  assign io_out_bits_uop_replayInst = out_bus[134:134];
  assign io_out_bits_data = out_bus[133:6];
  assign io_out_bits_vdIdx = out_bus[5:3];
  assign io_out_bits_vdIdxInField = out_bus[2:0];
  xs_PipelineConnect #(.DATA_WIDTH(535)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_uop_exceptionVec_3, io_in_bits_uop_exceptionVec_4, io_in_bits_uop_exceptionVec_5, io_in_bits_uop_exceptionVec_6, io_in_bits_uop_exceptionVec_7, io_in_bits_uop_exceptionVec_13, io_in_bits_uop_exceptionVec_15, io_in_bits_uop_exceptionVec_19, io_in_bits_uop_exceptionVec_21, io_in_bits_uop_exceptionVec_23, io_in_bits_uop_trigger, io_in_bits_uop_fuOpType, io_in_bits_uop_vecWen, io_in_bits_uop_v0Wen, io_in_bits_uop_vlWen, io_in_bits_uop_flushPipe, io_in_bits_uop_vpu_vma, io_in_bits_uop_vpu_vta, io_in_bits_uop_vpu_vsew, io_in_bits_uop_vpu_vlmul, io_in_bits_uop_vpu_vm, io_in_bits_uop_vpu_vstart, io_in_bits_uop_vpu_vuopIdx, io_in_bits_uop_vpu_vmask, io_in_bits_uop_vpu_vl, io_in_bits_uop_vpu_nf, io_in_bits_uop_vpu_veew, io_in_bits_uop_pdest, io_in_bits_uop_robIdx_flag, io_in_bits_uop_robIdx_value, io_in_bits_uop_debugInfo_enqRsTime, io_in_bits_uop_debugInfo_selectTime, io_in_bits_uop_debugInfo_issueTime, io_in_bits_uop_replayInst, io_in_bits_data, io_in_bits_vdIdx, io_in_bits_vdIdxInField}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
