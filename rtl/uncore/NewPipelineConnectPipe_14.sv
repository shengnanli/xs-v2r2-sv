// NewPipelineConnectPipe_14 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_14(
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
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_vlWen,
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
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_vlWen,
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
  wire [927:0] out_bus;
  assign io_out_bits_fuType = out_bus[927:893];
  assign io_out_bits_fuOpType = out_bus[892:884];
  assign io_out_bits_src_0 = out_bus[883:756];
  assign io_out_bits_src_1 = out_bus[755:628];
  assign io_out_bits_src_2 = out_bus[627:500];
  assign io_out_bits_src_3 = out_bus[499:372];
  assign io_out_bits_src_4 = out_bus[371:244];
  assign io_out_bits_robIdx_flag = out_bus[243:243];
  assign io_out_bits_robIdx_value = out_bus[242:235];
  assign io_out_bits_pdest = out_bus[234:227];
  assign io_out_bits_rfWen = out_bus[226:226];
  assign io_out_bits_fpWen = out_bus[225:225];
  assign io_out_bits_vecWen = out_bus[224:224];
  assign io_out_bits_v0Wen = out_bus[223:223];
  assign io_out_bits_vlWen = out_bus[222:222];
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
  xs_PipelineConnect #(.DATA_WIDTH(928)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_src_3, io_in_bits_src_4, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_fpu_wflags, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_lastUop, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
