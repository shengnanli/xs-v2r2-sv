// NewPipelineConnectPipe_32 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

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
