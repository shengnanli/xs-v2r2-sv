// 自动生成：scripts/gen_pc_wrappers.py —— 勿手改
module NewPipelineConnectPipe(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [381:0] out_bus;
  assign io_out_bits_fuType = out_bus[381:347];
  assign io_out_bits_fuOpType = out_bus[346:338];
  assign io_out_bits_src_0 = out_bus[337:274];
  assign io_out_bits_src_1 = out_bus[273:210];
  assign io_out_bits_robIdx_flag = out_bus[209:209];
  assign io_out_bits_robIdx_value = out_bus[208:201];
  assign io_out_bits_pdest = out_bus[200:193];
  assign io_out_bits_rfWen = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(382)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_1(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_imm,
  input  [4:0] io_in_bits_nextPcOffset,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  [49:0] io_in_bits_pc,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  [49:0] io_in_bits_predictInfo_target,
  input  io_in_bits_predictInfo_taken,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_imm,
  output [4:0] io_out_bits_nextPcOffset,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output [49:0] io_out_bits_pc,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output [49:0] io_out_bits_predictInfo_target,
  output io_out_bits_predictInfo_taken,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [562:0] out_bus;
  assign io_out_bits_fuType = out_bus[562:528];
  assign io_out_bits_fuOpType = out_bus[527:519];
  assign io_out_bits_src_0 = out_bus[518:455];
  assign io_out_bits_src_1 = out_bus[454:391];
  assign io_out_bits_imm = out_bus[390:327];
  assign io_out_bits_nextPcOffset = out_bus[326:322];
  assign io_out_bits_robIdx_flag = out_bus[321:321];
  assign io_out_bits_robIdx_value = out_bus[320:313];
  assign io_out_bits_pdest = out_bus[312:305];
  assign io_out_bits_rfWen = out_bus[304:304];
  assign io_out_bits_pc = out_bus[303:254];
  assign io_out_bits_ftqIdx_flag = out_bus[253:253];
  assign io_out_bits_ftqIdx_value = out_bus[252:247];
  assign io_out_bits_ftqOffset = out_bus[246:243];
  assign io_out_bits_predictInfo_target = out_bus[242:193];
  assign io_out_bits_predictInfo_taken = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(563)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_imm, io_in_bits_nextPcOffset, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_pc, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_predictInfo_target, io_in_bits_predictInfo_taken, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_5(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_imm,
  input  [4:0] io_in_bits_nextPcOffset,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_vlWen,
  input  [1:0] io_in_bits_fpu_typeTagOut,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_typ,
  input  [2:0] io_in_bits_fpu_rm,
  input  [49:0] io_in_bits_pc,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  [49:0] io_in_bits_predictInfo_target,
  input  io_in_bits_predictInfo_taken,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_imm,
  output [4:0] io_out_bits_nextPcOffset,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_vlWen,
  output [1:0] io_out_bits_fpu_typeTagOut,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_typ,
  output [2:0] io_out_bits_fpu_rm,
  output [49:0] io_out_bits_pc,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output [49:0] io_out_bits_predictInfo_target,
  output io_out_bits_predictInfo_taken,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [574:0] out_bus;
  assign io_out_bits_fuType = out_bus[574:540];
  assign io_out_bits_fuOpType = out_bus[539:531];
  assign io_out_bits_src_0 = out_bus[530:467];
  assign io_out_bits_src_1 = out_bus[466:403];
  assign io_out_bits_imm = out_bus[402:339];
  assign io_out_bits_nextPcOffset = out_bus[338:334];
  assign io_out_bits_robIdx_flag = out_bus[333:333];
  assign io_out_bits_robIdx_value = out_bus[332:325];
  assign io_out_bits_pdest = out_bus[324:317];
  assign io_out_bits_rfWen = out_bus[316:316];
  assign io_out_bits_fpWen = out_bus[315:315];
  assign io_out_bits_vecWen = out_bus[314:314];
  assign io_out_bits_v0Wen = out_bus[313:313];
  assign io_out_bits_vlWen = out_bus[312:312];
  assign io_out_bits_fpu_typeTagOut = out_bus[311:310];
  assign io_out_bits_fpu_wflags = out_bus[309:309];
  assign io_out_bits_fpu_typ = out_bus[308:307];
  assign io_out_bits_fpu_rm = out_bus[306:304];
  assign io_out_bits_pc = out_bus[303:254];
  assign io_out_bits_ftqIdx_flag = out_bus[253:253];
  assign io_out_bits_ftqIdx_value = out_bus[252:247];
  assign io_out_bits_ftqOffset = out_bus[246:243];
  assign io_out_bits_predictInfo_target = out_bus[242:193];
  assign io_out_bits_predictInfo_taken = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(575)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_imm, io_in_bits_nextPcOffset, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_fpu_typeTagOut, io_in_bits_fpu_wflags, io_in_bits_fpu_typ, io_in_bits_fpu_rm, io_in_bits_pc, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_predictInfo_target, io_in_bits_predictInfo_taken, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_7(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_imm,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_flushPipe,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_imm,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_flushPipe,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [457:0] out_bus;
  assign io_out_bits_fuType = out_bus[457:423];
  assign io_out_bits_fuOpType = out_bus[422:414];
  assign io_out_bits_src_0 = out_bus[413:350];
  assign io_out_bits_src_1 = out_bus[349:286];
  assign io_out_bits_imm = out_bus[285:222];
  assign io_out_bits_robIdx_flag = out_bus[221:221];
  assign io_out_bits_robIdx_value = out_bus[220:213];
  assign io_out_bits_pdest = out_bus[212:205];
  assign io_out_bits_rfWen = out_bus[204:204];
  assign io_out_bits_flushPipe = out_bus[203:203];
  assign io_out_bits_ftqIdx_flag = out_bus[202:202];
  assign io_out_bits_ftqIdx_value = out_bus[201:196];
  assign io_out_bits_ftqOffset = out_bus[195:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(458)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_imm, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_flushPipe, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_8(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_src_2,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_fmt,
  input  [2:0] io_in_bits_fpu_rm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_src_2,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_fmt,
  output [2:0] io_out_bits_fpu_rm,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [454:0] out_bus;
  assign io_out_bits_fuType = out_bus[454:420];
  assign io_out_bits_fuOpType = out_bus[419:411];
  assign io_out_bits_src_0 = out_bus[410:347];
  assign io_out_bits_src_1 = out_bus[346:283];
  assign io_out_bits_src_2 = out_bus[282:219];
  assign io_out_bits_robIdx_flag = out_bus[218:218];
  assign io_out_bits_robIdx_value = out_bus[217:210];
  assign io_out_bits_pdest = out_bus[209:202];
  assign io_out_bits_rfWen = out_bus[201:201];
  assign io_out_bits_fpWen = out_bus[200:200];
  assign io_out_bits_vecWen = out_bus[199:199];
  assign io_out_bits_v0Wen = out_bus[198:198];
  assign io_out_bits_fpu_wflags = out_bus[197:197];
  assign io_out_bits_fpu_fmt = out_bus[196:195];
  assign io_out_bits_fpu_rm = out_bus[194:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(455)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_fpu_wflags, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_9(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_fpWen,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_fmt,
  input  [2:0] io_in_bits_fpu_rm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_fpWen,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_fmt,
  output [2:0] io_out_bits_fpu_rm,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [387:0] out_bus;
  assign io_out_bits_fuType = out_bus[387:353];
  assign io_out_bits_fuOpType = out_bus[352:344];
  assign io_out_bits_src_0 = out_bus[343:280];
  assign io_out_bits_src_1 = out_bus[279:216];
  assign io_out_bits_robIdx_flag = out_bus[215:215];
  assign io_out_bits_robIdx_value = out_bus[214:207];
  assign io_out_bits_pdest = out_bus[206:199];
  assign io_out_bits_fpWen = out_bus[198:198];
  assign io_out_bits_fpu_wflags = out_bus[197:197];
  assign io_out_bits_fpu_fmt = out_bus[196:195];
  assign io_out_bits_fpu_rm = out_bus[194:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(388)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_fpWen, io_in_bits_fpu_wflags, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_10(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_src_2,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_fmt,
  input  [2:0] io_in_bits_fpu_rm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_src_2,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_fmt,
  output [2:0] io_out_bits_fpu_rm,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [452:0] out_bus;
  assign io_out_bits_fuType = out_bus[452:418];
  assign io_out_bits_fuOpType = out_bus[417:409];
  assign io_out_bits_src_0 = out_bus[408:345];
  assign io_out_bits_src_1 = out_bus[344:281];
  assign io_out_bits_src_2 = out_bus[280:217];
  assign io_out_bits_robIdx_flag = out_bus[216:216];
  assign io_out_bits_robIdx_value = out_bus[215:208];
  assign io_out_bits_pdest = out_bus[207:200];
  assign io_out_bits_rfWen = out_bus[199:199];
  assign io_out_bits_fpWen = out_bus[198:198];
  assign io_out_bits_fpu_wflags = out_bus[197:197];
  assign io_out_bits_fpu_fmt = out_bus[196:195];
  assign io_out_bits_fpu_rm = out_bus[194:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(453)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_fpu_wflags, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_13(
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
  input  io_in_bits_fpu_wflags,
  input  io_in_bits_vpu_vma,
  input  io_in_bits_vpu_vta,
  input  [1:0] io_in_bits_vpu_vsew,
  input  [2:0] io_in_bits_vpu_vlmul,
  input  io_in_bits_vpu_vm,
  input  [7:0] io_in_bits_vpu_vstart,
  input  [6:0] io_in_bits_vpu_vuopIdx,
  input  io_in_bits_vpu_isExt,
  input  io_in_bits_vpu_isNarrow,
  input  io_in_bits_vpu_isDstMask,
  input  io_in_bits_vpu_isOpMask,
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
  output io_out_bits_fpu_wflags,
  output io_out_bits_vpu_vma,
  output io_out_bits_vpu_vta,
  output [1:0] io_out_bits_vpu_vsew,
  output [2:0] io_out_bits_vpu_vlmul,
  output io_out_bits_vpu_vm,
  output [7:0] io_out_bits_vpu_vstart,
  output [6:0] io_out_bits_vpu_vuopIdx,
  output io_out_bits_vpu_isExt,
  output io_out_bits_vpu_isNarrow,
  output io_out_bits_vpu_isDstMask,
  output io_out_bits_vpu_isOpMask,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [921:0] out_bus;
  assign io_out_bits_fuType = out_bus[921:887];
  assign io_out_bits_fuOpType = out_bus[886:878];
  assign io_out_bits_src_0 = out_bus[877:750];
  assign io_out_bits_src_1 = out_bus[749:622];
  assign io_out_bits_src_2 = out_bus[621:494];
  assign io_out_bits_src_3 = out_bus[493:366];
  assign io_out_bits_src_4 = out_bus[365:238];
  assign io_out_bits_robIdx_flag = out_bus[237:237];
  assign io_out_bits_robIdx_value = out_bus[236:229];
  assign io_out_bits_pdest = out_bus[228:222];
  assign io_out_bits_vecWen = out_bus[221:221];
  assign io_out_bits_v0Wen = out_bus[220:220];
  assign io_out_bits_fpu_wflags = out_bus[219:219];
  assign io_out_bits_vpu_vma = out_bus[218:218];
  assign io_out_bits_vpu_vta = out_bus[217:217];
  assign io_out_bits_vpu_vsew = out_bus[216:215];
  assign io_out_bits_vpu_vlmul = out_bus[214:212];
  assign io_out_bits_vpu_vm = out_bus[211:211];
  assign io_out_bits_vpu_vstart = out_bus[210:203];
  assign io_out_bits_vpu_vuopIdx = out_bus[202:196];
  assign io_out_bits_vpu_isExt = out_bus[195:195];
  assign io_out_bits_vpu_isNarrow = out_bus[194:194];
  assign io_out_bits_vpu_isDstMask = out_bus[193:193];
  assign io_out_bits_vpu_isOpMask = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(922)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_src_3, io_in_bits_src_4, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_fpu_wflags, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_isExt, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_vpu_isOpMask, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

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

module NewPipelineConnectPipe_18(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_imm,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  io_in_bits_isFirstIssue,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_imm,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output io_out_bits_isFirstIssue,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [399:0] out_bus;
  assign io_out_bits_fuType = out_bus[399:365];
  assign io_out_bits_fuOpType = out_bus[364:356];
  assign io_out_bits_src_0 = out_bus[355:292];
  assign io_out_bits_imm = out_bus[291:228];
  assign io_out_bits_robIdx_flag = out_bus[227:227];
  assign io_out_bits_robIdx_value = out_bus[226:219];
  assign io_out_bits_isFirstIssue = out_bus[218:218];
  assign io_out_bits_pdest = out_bus[217:210];
  assign io_out_bits_rfWen = out_bus[209:209];
  assign io_out_bits_ftqIdx_value = out_bus[208:203];
  assign io_out_bits_ftqOffset = out_bus[202:199];
  assign io_out_bits_sqIdx_flag = out_bus[198:198];
  assign io_out_bits_sqIdx_value = out_bus[197:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(400)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_imm, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_isFirstIssue, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

module NewPipelineConnectPipe_20(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_imm,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  [49:0] io_in_bits_pc,
  input  io_in_bits_preDecode_isRVC,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  io_in_bits_loadWaitBit,
  input  io_in_bits_waitForRobIdx_flag,
  input  [7:0] io_in_bits_waitForRobIdx_value,
  input  io_in_bits_storeSetHit,
  input  io_in_bits_loadWaitStrict,
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
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_imm,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output [49:0] io_out_bits_pc,
  output io_out_bits_preDecode_isRVC,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output io_out_bits_loadWaitBit,
  output io_out_bits_waitForRobIdx_flag,
  output [7:0] io_out_bits_waitForRobIdx_value,
  output io_out_bits_storeSetHit,
  output io_out_bits_loadWaitStrict,
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
  wire [471:0] out_bus;
  assign io_out_bits_fuType = out_bus[471:437];
  assign io_out_bits_fuOpType = out_bus[436:428];
  assign io_out_bits_src_0 = out_bus[427:364];
  assign io_out_bits_imm = out_bus[363:300];
  assign io_out_bits_robIdx_flag = out_bus[299:299];
  assign io_out_bits_robIdx_value = out_bus[298:291];
  assign io_out_bits_pdest = out_bus[290:283];
  assign io_out_bits_rfWen = out_bus[282:282];
  assign io_out_bits_fpWen = out_bus[281:281];
  assign io_out_bits_pc = out_bus[280:231];
  assign io_out_bits_preDecode_isRVC = out_bus[230:230];
  assign io_out_bits_ftqIdx_flag = out_bus[229:229];
  assign io_out_bits_ftqIdx_value = out_bus[228:223];
  assign io_out_bits_ftqOffset = out_bus[222:219];
  assign io_out_bits_loadWaitBit = out_bus[218:218];
  assign io_out_bits_waitForRobIdx_flag = out_bus[217:217];
  assign io_out_bits_waitForRobIdx_value = out_bus[216:209];
  assign io_out_bits_storeSetHit = out_bus[208:208];
  assign io_out_bits_loadWaitStrict = out_bus[207:207];
  assign io_out_bits_sqIdx_flag = out_bus[206:206];
  assign io_out_bits_sqIdx_value = out_bus[205:200];
  assign io_out_bits_lqIdx_flag = out_bus[199:199];
  assign io_out_bits_lqIdx_value = out_bus[198:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(472)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_imm, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_pc, io_in_bits_preDecode_isRVC, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_loadWaitBit, io_in_bits_waitForRobIdx_flag, io_in_bits_waitForRobIdx_value, io_in_bits_storeSetHit, io_in_bits_loadWaitStrict, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value, io_in_bits_lqIdx_flag, io_in_bits_lqIdx_value, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

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

module NewPipelineConnectPipe_25(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [123:0] out_bus;
  assign io_out_bits_fuType = out_bus[123:89];
  assign io_out_bits_fuOpType = out_bus[88:80];
  assign io_out_bits_src_0 = out_bus[79:16];
  assign io_out_bits_robIdx_flag = out_bus[15:15];
  assign io_out_bits_robIdx_value = out_bus[14:7];
  assign io_out_bits_sqIdx_flag = out_bus[6:6];
  assign io_out_bits_sqIdx_value = out_bus[5:0];
  xs_PipelineConnect #(.DATA_WIDTH(124)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

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

module NewPipelineConnectPipe_31(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [49:0] io_in_bits_vaddr,
  input  [127:0] io_in_bits_data,
  input  [15:0] io_in_bits_mask,
  input  [47:0] io_in_bits_addr,
  input  io_in_bits_vecValid,
  input  io_out_ready,
  output io_out_valid,
  output [49:0] io_out_bits_vaddr,
  output [127:0] io_out_bits_data,
  output [15:0] io_out_bits_mask,
  output [47:0] io_out_bits_addr,
  output io_out_bits_vecValid,
  input  io_rightOutFire
);
  wire [242:0] out_bus;
  assign io_out_bits_vaddr = out_bus[242:193];
  assign io_out_bits_data = out_bus[192:65];
  assign io_out_bits_mask = out_bus[64:49];
  assign io_out_bits_addr = out_bus[48:1];
  assign io_out_bits_vecValid = out_bus[0:0];
  xs_PipelineConnect #(.DATA_WIDTH(243)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask, io_in_bits_addr, io_in_bits_vecValid}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule

module NewPipelineConnectPipe_32(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  io_in_bits_uop_exceptionVec_0,
  input  io_in_bits_uop_exceptionVec_1,
  input  io_in_bits_uop_exceptionVec_2,
  input  io_in_bits_uop_exceptionVec_3,
  input  io_in_bits_uop_exceptionVec_4,
  input  io_in_bits_uop_exceptionVec_5,
  input  io_in_bits_uop_exceptionVec_6,
  input  io_in_bits_uop_exceptionVec_7,
  input  io_in_bits_uop_exceptionVec_8,
  input  io_in_bits_uop_exceptionVec_9,
  input  io_in_bits_uop_exceptionVec_10,
  input  io_in_bits_uop_exceptionVec_11,
  input  io_in_bits_uop_exceptionVec_12,
  input  io_in_bits_uop_exceptionVec_13,
  input  io_in_bits_uop_exceptionVec_14,
  input  io_in_bits_uop_exceptionVec_15,
  input  io_in_bits_uop_exceptionVec_16,
  input  io_in_bits_uop_exceptionVec_17,
  input  io_in_bits_uop_exceptionVec_18,
  input  io_in_bits_uop_exceptionVec_19,
  input  io_in_bits_uop_exceptionVec_20,
  input  io_in_bits_uop_exceptionVec_21,
  input  io_in_bits_uop_exceptionVec_22,
  input  io_in_bits_uop_exceptionVec_23,
  input  [3:0] io_in_bits_uop_trigger,
  input  io_in_bits_uop_flushPipe,
  input  io_in_bits_uop_robIdx_flag,
  input  [7:0] io_in_bits_uop_robIdx_value,
  input  [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  io_in_bits_debug_isMMIO,
  input  io_out_ready,
  output io_out_valid,
  output io_out_bits_uop_exceptionVec_0,
  output io_out_bits_uop_exceptionVec_1,
  output io_out_bits_uop_exceptionVec_2,
  output io_out_bits_uop_exceptionVec_3,
  output io_out_bits_uop_exceptionVec_4,
  output io_out_bits_uop_exceptionVec_5,
  output io_out_bits_uop_exceptionVec_6,
  output io_out_bits_uop_exceptionVec_7,
  output io_out_bits_uop_exceptionVec_8,
  output io_out_bits_uop_exceptionVec_9,
  output io_out_bits_uop_exceptionVec_10,
  output io_out_bits_uop_exceptionVec_11,
  output io_out_bits_uop_exceptionVec_12,
  output io_out_bits_uop_exceptionVec_13,
  output io_out_bits_uop_exceptionVec_14,
  output io_out_bits_uop_exceptionVec_15,
  output io_out_bits_uop_exceptionVec_16,
  output io_out_bits_uop_exceptionVec_17,
  output io_out_bits_uop_exceptionVec_18,
  output io_out_bits_uop_exceptionVec_19,
  output io_out_bits_uop_exceptionVec_20,
  output io_out_bits_uop_exceptionVec_21,
  output io_out_bits_uop_exceptionVec_22,
  output io_out_bits_uop_exceptionVec_23,
  output [3:0] io_out_bits_uop_trigger,
  output io_out_bits_uop_flushPipe,
  output io_out_bits_uop_robIdx_flag,
  output [7:0] io_out_bits_uop_robIdx_value,
  output [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_out_bits_uop_debugInfo_selectTime,
  output [63:0] io_out_bits_uop_debugInfo_issueTime,
  output io_out_bits_debug_isMMIO,
  input  io_rightOutFire
);
  wire [230:0] out_bus;
  assign io_out_bits_uop_exceptionVec_0 = out_bus[230:230];
  assign io_out_bits_uop_exceptionVec_1 = out_bus[229:229];
  assign io_out_bits_uop_exceptionVec_2 = out_bus[228:228];
  assign io_out_bits_uop_exceptionVec_3 = out_bus[227:227];
  assign io_out_bits_uop_exceptionVec_4 = out_bus[226:226];
  assign io_out_bits_uop_exceptionVec_5 = out_bus[225:225];
  assign io_out_bits_uop_exceptionVec_6 = out_bus[224:224];
  assign io_out_bits_uop_exceptionVec_7 = out_bus[223:223];
  assign io_out_bits_uop_exceptionVec_8 = out_bus[222:222];
  assign io_out_bits_uop_exceptionVec_9 = out_bus[221:221];
  assign io_out_bits_uop_exceptionVec_10 = out_bus[220:220];
  assign io_out_bits_uop_exceptionVec_11 = out_bus[219:219];
  assign io_out_bits_uop_exceptionVec_12 = out_bus[218:218];
  assign io_out_bits_uop_exceptionVec_13 = out_bus[217:217];
  assign io_out_bits_uop_exceptionVec_14 = out_bus[216:216];
  assign io_out_bits_uop_exceptionVec_15 = out_bus[215:215];
  assign io_out_bits_uop_exceptionVec_16 = out_bus[214:214];
  assign io_out_bits_uop_exceptionVec_17 = out_bus[213:213];
  assign io_out_bits_uop_exceptionVec_18 = out_bus[212:212];
  assign io_out_bits_uop_exceptionVec_19 = out_bus[211:211];
  assign io_out_bits_uop_exceptionVec_20 = out_bus[210:210];
  assign io_out_bits_uop_exceptionVec_21 = out_bus[209:209];
  assign io_out_bits_uop_exceptionVec_22 = out_bus[208:208];
  assign io_out_bits_uop_exceptionVec_23 = out_bus[207:207];
  assign io_out_bits_uop_trigger = out_bus[206:203];
  assign io_out_bits_uop_flushPipe = out_bus[202:202];
  assign io_out_bits_uop_robIdx_flag = out_bus[201:201];
  assign io_out_bits_uop_robIdx_value = out_bus[200:193];
  assign io_out_bits_uop_debugInfo_enqRsTime = out_bus[192:129];
  assign io_out_bits_uop_debugInfo_selectTime = out_bus[128:65];
  assign io_out_bits_uop_debugInfo_issueTime = out_bus[64:1];
  assign io_out_bits_debug_isMMIO = out_bus[0:0];
  xs_PipelineConnect #(.DATA_WIDTH(231)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_uop_exceptionVec_0, io_in_bits_uop_exceptionVec_1, io_in_bits_uop_exceptionVec_2, io_in_bits_uop_exceptionVec_3, io_in_bits_uop_exceptionVec_4, io_in_bits_uop_exceptionVec_5, io_in_bits_uop_exceptionVec_6, io_in_bits_uop_exceptionVec_7, io_in_bits_uop_exceptionVec_8, io_in_bits_uop_exceptionVec_9, io_in_bits_uop_exceptionVec_10, io_in_bits_uop_exceptionVec_11, io_in_bits_uop_exceptionVec_12, io_in_bits_uop_exceptionVec_13, io_in_bits_uop_exceptionVec_14, io_in_bits_uop_exceptionVec_15, io_in_bits_uop_exceptionVec_16, io_in_bits_uop_exceptionVec_17, io_in_bits_uop_exceptionVec_18, io_in_bits_uop_exceptionVec_19, io_in_bits_uop_exceptionVec_20, io_in_bits_uop_exceptionVec_21, io_in_bits_uop_exceptionVec_22, io_in_bits_uop_exceptionVec_23, io_in_bits_uop_trigger, io_in_bits_uop_flushPipe, io_in_bits_uop_robIdx_flag, io_in_bits_uop_robIdx_value, io_in_bits_uop_debugInfo_enqRsTime, io_in_bits_uop_debugInfo_selectTime, io_in_bits_uop_debugInfo_issueTime, io_in_bits_debug_isMMIO}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule

module NewPipelineConnectPipe_33(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [63:0] io_in_bits_vaddr,
  input  [49:0] io_in_bits_basevaddr,
  input  [15:0] io_in_bits_mask,
  input  [3:0] io_in_bits_reg_offset,
  input  [2:0] io_in_bits_alignedType,
  input  io_in_bits_vecActive,
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
  input  io_in_bits_uop_preDecodeInfo_isRVC,
  input  io_in_bits_uop_ftqPtr_flag,
  input  [5:0] io_in_bits_uop_ftqPtr_value,
  input  [3:0] io_in_bits_uop_ftqOffset,
  input  [8:0] io_in_bits_uop_fuOpType,
  input  io_in_bits_uop_rfWen,
  input  io_in_bits_uop_fpWen,
  input  [7:0] io_in_bits_uop_vpu_vstart,
  input  [1:0] io_in_bits_uop_vpu_veew,
  input  [6:0] io_in_bits_uop_uopIdx,
  input  [7:0] io_in_bits_uop_pdest,
  input  io_in_bits_uop_robIdx_flag,
  input  [7:0] io_in_bits_uop_robIdx_value,
  input  [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  io_in_bits_uop_storeSetHit,
  input  io_in_bits_uop_waitForRobIdx_flag,
  input  [7:0] io_in_bits_uop_waitForRobIdx_value,
  input  io_in_bits_uop_loadWaitBit,
  input  io_in_bits_uop_loadWaitStrict,
  input  io_in_bits_uop_lqIdx_flag,
  input  [6:0] io_in_bits_uop_lqIdx_value,
  input  io_in_bits_uop_sqIdx_flag,
  input  [5:0] io_in_bits_uop_sqIdx_value,
  input  [3:0] io_in_bits_mBIndex,
  input  [7:0] io_in_bits_elemIdx,
  input  [7:0] io_in_bits_elemIdxInsideVd,
  input  io_out_ready,
  output io_out_valid,
  output [63:0] io_out_bits_vaddr,
  output [49:0] io_out_bits_basevaddr,
  output [15:0] io_out_bits_mask,
  output [3:0] io_out_bits_reg_offset,
  output [2:0] io_out_bits_alignedType,
  output io_out_bits_vecActive,
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
  output io_out_bits_uop_preDecodeInfo_isRVC,
  output io_out_bits_uop_ftqPtr_flag,
  output [5:0] io_out_bits_uop_ftqPtr_value,
  output [3:0] io_out_bits_uop_ftqOffset,
  output [8:0] io_out_bits_uop_fuOpType,
  output io_out_bits_uop_rfWen,
  output io_out_bits_uop_fpWen,
  output [7:0] io_out_bits_uop_vpu_vstart,
  output [1:0] io_out_bits_uop_vpu_veew,
  output [6:0] io_out_bits_uop_uopIdx,
  output [7:0] io_out_bits_uop_pdest,
  output io_out_bits_uop_robIdx_flag,
  output [7:0] io_out_bits_uop_robIdx_value,
  output [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_out_bits_uop_debugInfo_selectTime,
  output [63:0] io_out_bits_uop_debugInfo_issueTime,
  output io_out_bits_uop_storeSetHit,
  output io_out_bits_uop_waitForRobIdx_flag,
  output [7:0] io_out_bits_uop_waitForRobIdx_value,
  output io_out_bits_uop_loadWaitBit,
  output io_out_bits_uop_loadWaitStrict,
  output io_out_bits_uop_lqIdx_flag,
  output [6:0] io_out_bits_uop_lqIdx_value,
  output io_out_bits_uop_sqIdx_flag,
  output [5:0] io_out_bits_uop_sqIdx_value,
  output [3:0] io_out_bits_mBIndex,
  output [7:0] io_out_bits_elemIdx,
  output [7:0] io_out_bits_elemIdxInsideVd,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [446:0] out_bus;
  assign io_out_bits_vaddr = out_bus[446:383];
  assign io_out_bits_basevaddr = out_bus[382:333];
  assign io_out_bits_mask = out_bus[332:317];
  assign io_out_bits_reg_offset = out_bus[316:313];
  assign io_out_bits_alignedType = out_bus[312:310];
  assign io_out_bits_vecActive = out_bus[309:309];
  assign io_out_bits_uop_exceptionVec_4 = out_bus[308:308];
  assign io_out_bits_uop_exceptionVec_5 = out_bus[307:307];
  assign io_out_bits_uop_exceptionVec_6 = out_bus[306:306];
  assign io_out_bits_uop_exceptionVec_7 = out_bus[305:305];
  assign io_out_bits_uop_exceptionVec_13 = out_bus[304:304];
  assign io_out_bits_uop_exceptionVec_15 = out_bus[303:303];
  assign io_out_bits_uop_exceptionVec_19 = out_bus[302:302];
  assign io_out_bits_uop_exceptionVec_21 = out_bus[301:301];
  assign io_out_bits_uop_exceptionVec_23 = out_bus[300:300];
  assign io_out_bits_uop_trigger = out_bus[299:296];
  assign io_out_bits_uop_preDecodeInfo_isRVC = out_bus[295:295];
  assign io_out_bits_uop_ftqPtr_flag = out_bus[294:294];
  assign io_out_bits_uop_ftqPtr_value = out_bus[293:288];
  assign io_out_bits_uop_ftqOffset = out_bus[287:284];
  assign io_out_bits_uop_fuOpType = out_bus[283:275];
  assign io_out_bits_uop_rfWen = out_bus[274:274];
  assign io_out_bits_uop_fpWen = out_bus[273:273];
  assign io_out_bits_uop_vpu_vstart = out_bus[272:265];
  assign io_out_bits_uop_vpu_veew = out_bus[264:263];
  assign io_out_bits_uop_uopIdx = out_bus[262:256];
  assign io_out_bits_uop_pdest = out_bus[255:248];
  assign io_out_bits_uop_robIdx_flag = out_bus[247:247];
  assign io_out_bits_uop_robIdx_value = out_bus[246:239];
  assign io_out_bits_uop_debugInfo_enqRsTime = out_bus[238:175];
  assign io_out_bits_uop_debugInfo_selectTime = out_bus[174:111];
  assign io_out_bits_uop_debugInfo_issueTime = out_bus[110:47];
  assign io_out_bits_uop_storeSetHit = out_bus[46:46];
  assign io_out_bits_uop_waitForRobIdx_flag = out_bus[45:45];
  assign io_out_bits_uop_waitForRobIdx_value = out_bus[44:37];
  assign io_out_bits_uop_loadWaitBit = out_bus[36:36];
  assign io_out_bits_uop_loadWaitStrict = out_bus[35:35];
  assign io_out_bits_uop_lqIdx_flag = out_bus[34:34];
  assign io_out_bits_uop_lqIdx_value = out_bus[33:27];
  assign io_out_bits_uop_sqIdx_flag = out_bus[26:26];
  assign io_out_bits_uop_sqIdx_value = out_bus[25:20];
  assign io_out_bits_mBIndex = out_bus[19:16];
  assign io_out_bits_elemIdx = out_bus[15:8];
  assign io_out_bits_elemIdxInsideVd = out_bus[7:0];
  xs_PipelineConnect #(.DATA_WIDTH(447)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_basevaddr, io_in_bits_mask, io_in_bits_reg_offset, io_in_bits_alignedType, io_in_bits_vecActive, io_in_bits_uop_exceptionVec_4, io_in_bits_uop_exceptionVec_5, io_in_bits_uop_exceptionVec_6, io_in_bits_uop_exceptionVec_7, io_in_bits_uop_exceptionVec_13, io_in_bits_uop_exceptionVec_15, io_in_bits_uop_exceptionVec_19, io_in_bits_uop_exceptionVec_21, io_in_bits_uop_exceptionVec_23, io_in_bits_uop_trigger, io_in_bits_uop_preDecodeInfo_isRVC, io_in_bits_uop_ftqPtr_flag, io_in_bits_uop_ftqPtr_value, io_in_bits_uop_ftqOffset, io_in_bits_uop_fuOpType, io_in_bits_uop_rfWen, io_in_bits_uop_fpWen, io_in_bits_uop_vpu_vstart, io_in_bits_uop_vpu_veew, io_in_bits_uop_uopIdx, io_in_bits_uop_pdest, io_in_bits_uop_robIdx_flag, io_in_bits_uop_robIdx_value, io_in_bits_uop_debugInfo_enqRsTime, io_in_bits_uop_debugInfo_selectTime, io_in_bits_uop_debugInfo_issueTime, io_in_bits_uop_storeSetHit, io_in_bits_uop_waitForRobIdx_flag, io_in_bits_uop_waitForRobIdx_value, io_in_bits_uop_loadWaitBit, io_in_bits_uop_loadWaitStrict, io_in_bits_uop_lqIdx_flag, io_in_bits_uop_lqIdx_value, io_in_bits_uop_sqIdx_flag, io_in_bits_uop_sqIdx_value, io_in_bits_mBIndex, io_in_bits_elemIdx, io_in_bits_elemIdxInsideVd}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
