// 自动生成: scripts/gen_pcp.py —— 勿手改
module PipelineConnectPipe_xs(
  input clock,
  input reset,
  output io_in_ready,
  input io_in_valid,
  input [31:0] io_in_bits_instr,
  input [9:0] io_in_bits_foldpc,
  input io_in_bits_exceptionVec_0,
  input io_in_bits_exceptionVec_1,
  input io_in_bits_exceptionVec_2,
  input io_in_bits_exceptionVec_3,
  input io_in_bits_exceptionVec_4,
  input io_in_bits_exceptionVec_5,
  input io_in_bits_exceptionVec_6,
  input io_in_bits_exceptionVec_7,
  input io_in_bits_exceptionVec_8,
  input io_in_bits_exceptionVec_9,
  input io_in_bits_exceptionVec_10,
  input io_in_bits_exceptionVec_11,
  input io_in_bits_exceptionVec_12,
  input io_in_bits_exceptionVec_13,
  input io_in_bits_exceptionVec_14,
  input io_in_bits_exceptionVec_15,
  input io_in_bits_exceptionVec_16,
  input io_in_bits_exceptionVec_17,
  input io_in_bits_exceptionVec_18,
  input io_in_bits_exceptionVec_19,
  input io_in_bits_exceptionVec_20,
  input io_in_bits_exceptionVec_21,
  input io_in_bits_exceptionVec_22,
  input io_in_bits_exceptionVec_23,
  input io_in_bits_isFetchMalAddr,
  input [3:0] io_in_bits_trigger,
  input io_in_bits_preDecodeInfo_isRVC,
  input [1:0] io_in_bits_preDecodeInfo_brType,
  input io_in_bits_pred_taken,
  input io_in_bits_crossPageIPFFix,
  input io_in_bits_ftqPtr_flag,
  input [5:0] io_in_bits_ftqPtr_value,
  input [3:0] io_in_bits_ftqOffset,
  input [3:0] io_in_bits_srcType_0,
  input [3:0] io_in_bits_srcType_1,
  input [3:0] io_in_bits_srcType_2,
  input [3:0] io_in_bits_srcType_3,
  input [3:0] io_in_bits_srcType_4,
  input [5:0] io_in_bits_lsrc_0,
  input [5:0] io_in_bits_lsrc_1,
  input [5:0] io_in_bits_lsrc_2,
  input [5:0] io_in_bits_ldest,
  input [34:0] io_in_bits_fuType,
  input [8:0] io_in_bits_fuOpType,
  input io_in_bits_rfWen,
  input io_in_bits_fpWen,
  input io_in_bits_vecWen,
  input io_in_bits_v0Wen,
  input io_in_bits_vlWen,
  input io_in_bits_isXSTrap,
  input io_in_bits_waitForward,
  input io_in_bits_blockBackward,
  input io_in_bits_flushPipe,
  input io_in_bits_canRobCompress,
  input [3:0] io_in_bits_selImm,
  input [21:0] io_in_bits_imm,
  input [1:0] io_in_bits_fpu_typeTagOut,
  input io_in_bits_fpu_wflags,
  input [1:0] io_in_bits_fpu_typ,
  input [1:0] io_in_bits_fpu_fmt,
  input [2:0] io_in_bits_fpu_rm,
  input io_in_bits_vpu_vill,
  input io_in_bits_vpu_vma,
  input io_in_bits_vpu_vta,
  input [1:0] io_in_bits_vpu_vsew,
  input [2:0] io_in_bits_vpu_vlmul,
  input io_in_bits_vpu_specVill,
  input io_in_bits_vpu_specVma,
  input io_in_bits_vpu_specVta,
  input [1:0] io_in_bits_vpu_specVsew,
  input [2:0] io_in_bits_vpu_specVlmul,
  input io_in_bits_vpu_vm,
  input [7:0] io_in_bits_vpu_vstart,
  input io_in_bits_vpu_fpu_isFoldTo1_2,
  input io_in_bits_vpu_fpu_isFoldTo1_4,
  input io_in_bits_vpu_fpu_isFoldTo1_8,
  input [2:0] io_in_bits_vpu_nf,
  input [1:0] io_in_bits_vpu_veew,
  input io_in_bits_vpu_isExt,
  input io_in_bits_vpu_isNarrow,
  input io_in_bits_vpu_isDstMask,
  input io_in_bits_vpu_isOpMask,
  input io_in_bits_vpu_isDependOldVd,
  input io_in_bits_vpu_isWritePartVd,
  input io_in_bits_vpu_isVleff,
  input io_in_bits_vlsInstr,
  input io_in_bits_wfflags,
  input io_in_bits_isMove,
  input [6:0] io_in_bits_uopIdx,
  input [5:0] io_in_bits_uopSplitType,
  input io_in_bits_isVset,
  input io_in_bits_firstUop,
  input io_in_bits_lastUop,
  input [6:0] io_in_bits_numWB,
  input [2:0] io_in_bits_commitType,
  input io_out_ready,
  output io_out_valid,
  output [31:0] io_out_bits_instr,
  output [9:0] io_out_bits_foldpc,
  output io_out_bits_exceptionVec_0,
  output io_out_bits_exceptionVec_1,
  output io_out_bits_exceptionVec_2,
  output io_out_bits_exceptionVec_3,
  output io_out_bits_exceptionVec_4,
  output io_out_bits_exceptionVec_5,
  output io_out_bits_exceptionVec_6,
  output io_out_bits_exceptionVec_7,
  output io_out_bits_exceptionVec_8,
  output io_out_bits_exceptionVec_9,
  output io_out_bits_exceptionVec_10,
  output io_out_bits_exceptionVec_11,
  output io_out_bits_exceptionVec_12,
  output io_out_bits_exceptionVec_13,
  output io_out_bits_exceptionVec_14,
  output io_out_bits_exceptionVec_15,
  output io_out_bits_exceptionVec_16,
  output io_out_bits_exceptionVec_17,
  output io_out_bits_exceptionVec_18,
  output io_out_bits_exceptionVec_19,
  output io_out_bits_exceptionVec_20,
  output io_out_bits_exceptionVec_21,
  output io_out_bits_exceptionVec_22,
  output io_out_bits_exceptionVec_23,
  output io_out_bits_isFetchMalAddr,
  output [3:0] io_out_bits_trigger,
  output io_out_bits_preDecodeInfo_isRVC,
  output [1:0] io_out_bits_preDecodeInfo_brType,
  output io_out_bits_pred_taken,
  output io_out_bits_crossPageIPFFix,
  output io_out_bits_ftqPtr_flag,
  output [5:0] io_out_bits_ftqPtr_value,
  output [3:0] io_out_bits_ftqOffset,
  output [3:0] io_out_bits_srcType_0,
  output [3:0] io_out_bits_srcType_1,
  output [3:0] io_out_bits_srcType_2,
  output [3:0] io_out_bits_srcType_3,
  output [3:0] io_out_bits_srcType_4,
  output [5:0] io_out_bits_lsrc_0,
  output [5:0] io_out_bits_lsrc_1,
  output [5:0] io_out_bits_lsrc_2,
  output [5:0] io_out_bits_lsrc_3,
  output [5:0] io_out_bits_lsrc_4,
  output [5:0] io_out_bits_ldest,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_vlWen,
  output io_out_bits_isXSTrap,
  output io_out_bits_waitForward,
  output io_out_bits_blockBackward,
  output io_out_bits_flushPipe,
  output io_out_bits_canRobCompress,
  output [3:0] io_out_bits_selImm,
  output [21:0] io_out_bits_imm,
  output [1:0] io_out_bits_fpu_typeTagOut,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_typ,
  output [1:0] io_out_bits_fpu_fmt,
  output [2:0] io_out_bits_fpu_rm,
  output io_out_bits_vpu_vill,
  output io_out_bits_vpu_vma,
  output io_out_bits_vpu_vta,
  output [1:0] io_out_bits_vpu_vsew,
  output [2:0] io_out_bits_vpu_vlmul,
  output io_out_bits_vpu_specVill,
  output io_out_bits_vpu_specVma,
  output io_out_bits_vpu_specVta,
  output [1:0] io_out_bits_vpu_specVsew,
  output [2:0] io_out_bits_vpu_specVlmul,
  output io_out_bits_vpu_vm,
  output [7:0] io_out_bits_vpu_vstart,
  output io_out_bits_vpu_fpu_isFoldTo1_2,
  output io_out_bits_vpu_fpu_isFoldTo1_4,
  output io_out_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_bits_vpu_vmask,
  output [2:0] io_out_bits_vpu_nf,
  output [1:0] io_out_bits_vpu_veew,
  output io_out_bits_vpu_isExt,
  output io_out_bits_vpu_isNarrow,
  output io_out_bits_vpu_isDstMask,
  output io_out_bits_vpu_isOpMask,
  output io_out_bits_vpu_isDependOldVd,
  output io_out_bits_vpu_isWritePartVd,
  output io_out_bits_vpu_isVleff,
  output io_out_bits_vlsInstr,
  output io_out_bits_wfflags,
  output io_out_bits_isMove,
  output [6:0] io_out_bits_uopIdx,
  output [5:0] io_out_bits_uopSplitType,
  output io_out_bits_isVset,
  output io_out_bits_firstUop,
  output io_out_bits_lastUop,
  output [6:0] io_out_bits_numWB,
  output [2:0] io_out_bits_commitType,
  input io_rightOutFire,
  input io_isFlush
);
  wire [429:0] out_bus;
  assign io_out_bits_instr = out_bus[429:398];
  assign io_out_bits_foldpc = out_bus[397:388];
  assign io_out_bits_exceptionVec_0 = out_bus[387:387];
  assign io_out_bits_exceptionVec_1 = out_bus[386:386];
  assign io_out_bits_exceptionVec_2 = out_bus[385:385];
  assign io_out_bits_exceptionVec_3 = out_bus[384:384];
  assign io_out_bits_exceptionVec_4 = out_bus[383:383];
  assign io_out_bits_exceptionVec_5 = out_bus[382:382];
  assign io_out_bits_exceptionVec_6 = out_bus[381:381];
  assign io_out_bits_exceptionVec_7 = out_bus[380:380];
  assign io_out_bits_exceptionVec_8 = out_bus[379:379];
  assign io_out_bits_exceptionVec_9 = out_bus[378:378];
  assign io_out_bits_exceptionVec_10 = out_bus[377:377];
  assign io_out_bits_exceptionVec_11 = out_bus[376:376];
  assign io_out_bits_exceptionVec_12 = out_bus[375:375];
  assign io_out_bits_exceptionVec_13 = out_bus[374:374];
  assign io_out_bits_exceptionVec_14 = out_bus[373:373];
  assign io_out_bits_exceptionVec_15 = out_bus[372:372];
  assign io_out_bits_exceptionVec_16 = out_bus[371:371];
  assign io_out_bits_exceptionVec_17 = out_bus[370:370];
  assign io_out_bits_exceptionVec_18 = out_bus[369:369];
  assign io_out_bits_exceptionVec_19 = out_bus[368:368];
  assign io_out_bits_exceptionVec_20 = out_bus[367:367];
  assign io_out_bits_exceptionVec_21 = out_bus[366:366];
  assign io_out_bits_exceptionVec_22 = out_bus[365:365];
  assign io_out_bits_exceptionVec_23 = out_bus[364:364];
  assign io_out_bits_isFetchMalAddr = out_bus[363:363];
  assign io_out_bits_trigger = out_bus[362:359];
  assign io_out_bits_preDecodeInfo_isRVC = out_bus[358:358];
  assign io_out_bits_preDecodeInfo_brType = out_bus[357:356];
  assign io_out_bits_pred_taken = out_bus[355:355];
  assign io_out_bits_crossPageIPFFix = out_bus[354:354];
  assign io_out_bits_ftqPtr_flag = out_bus[353:353];
  assign io_out_bits_ftqPtr_value = out_bus[352:347];
  assign io_out_bits_ftqOffset = out_bus[346:343];
  assign io_out_bits_srcType_0 = out_bus[342:339];
  assign io_out_bits_srcType_1 = out_bus[338:335];
  assign io_out_bits_srcType_2 = out_bus[334:331];
  assign io_out_bits_srcType_3 = out_bus[330:327];
  assign io_out_bits_srcType_4 = out_bus[326:323];
  assign io_out_bits_lsrc_0 = out_bus[322:317];
  assign io_out_bits_lsrc_1 = out_bus[316:311];
  assign io_out_bits_lsrc_2 = out_bus[310:305];
  assign io_out_bits_lsrc_3 = out_bus[304:299];
  assign io_out_bits_lsrc_4 = out_bus[298:293];
  assign io_out_bits_ldest = out_bus[292:287];
  assign io_out_bits_fuType = out_bus[286:252];
  assign io_out_bits_fuOpType = out_bus[251:243];
  assign io_out_bits_rfWen = out_bus[242:242];
  assign io_out_bits_fpWen = out_bus[241:241];
  assign io_out_bits_vecWen = out_bus[240:240];
  assign io_out_bits_v0Wen = out_bus[239:239];
  assign io_out_bits_vlWen = out_bus[238:238];
  assign io_out_bits_isXSTrap = out_bus[237:237];
  assign io_out_bits_waitForward = out_bus[236:236];
  assign io_out_bits_blockBackward = out_bus[235:235];
  assign io_out_bits_flushPipe = out_bus[234:234];
  assign io_out_bits_canRobCompress = out_bus[233:233];
  assign io_out_bits_selImm = out_bus[232:229];
  assign io_out_bits_imm = out_bus[228:207];
  assign io_out_bits_fpu_typeTagOut = out_bus[206:205];
  assign io_out_bits_fpu_wflags = out_bus[204:204];
  assign io_out_bits_fpu_typ = out_bus[203:202];
  assign io_out_bits_fpu_fmt = out_bus[201:200];
  assign io_out_bits_fpu_rm = out_bus[199:197];
  assign io_out_bits_vpu_vill = out_bus[196:196];
  assign io_out_bits_vpu_vma = out_bus[195:195];
  assign io_out_bits_vpu_vta = out_bus[194:194];
  assign io_out_bits_vpu_vsew = out_bus[193:192];
  assign io_out_bits_vpu_vlmul = out_bus[191:189];
  assign io_out_bits_vpu_specVill = out_bus[188:188];
  assign io_out_bits_vpu_specVma = out_bus[187:187];
  assign io_out_bits_vpu_specVta = out_bus[186:186];
  assign io_out_bits_vpu_specVsew = out_bus[185:184];
  assign io_out_bits_vpu_specVlmul = out_bus[183:181];
  assign io_out_bits_vpu_vm = out_bus[180:180];
  assign io_out_bits_vpu_vstart = out_bus[179:172];
  assign io_out_bits_vpu_fpu_isFoldTo1_2 = out_bus[171:171];
  assign io_out_bits_vpu_fpu_isFoldTo1_4 = out_bus[170:170];
  assign io_out_bits_vpu_fpu_isFoldTo1_8 = out_bus[169:169];
  assign io_out_bits_vpu_vmask = out_bus[168:41];
  assign io_out_bits_vpu_nf = out_bus[40:38];
  assign io_out_bits_vpu_veew = out_bus[37:36];
  assign io_out_bits_vpu_isExt = out_bus[35:35];
  assign io_out_bits_vpu_isNarrow = out_bus[34:34];
  assign io_out_bits_vpu_isDstMask = out_bus[33:33];
  assign io_out_bits_vpu_isOpMask = out_bus[32:32];
  assign io_out_bits_vpu_isDependOldVd = out_bus[31:31];
  assign io_out_bits_vpu_isWritePartVd = out_bus[30:30];
  assign io_out_bits_vpu_isVleff = out_bus[29:29];
  assign io_out_bits_vlsInstr = out_bus[28:28];
  assign io_out_bits_wfflags = out_bus[27:27];
  assign io_out_bits_isMove = out_bus[26:26];
  assign io_out_bits_uopIdx = out_bus[25:19];
  assign io_out_bits_uopSplitType = out_bus[18:13];
  assign io_out_bits_isVset = out_bus[12:12];
  assign io_out_bits_firstUop = out_bus[11:11];
  assign io_out_bits_lastUop = out_bus[10:10];
  assign io_out_bits_numWB = out_bus[9:3];
  assign io_out_bits_commitType = out_bus[2:0];
  xs_PipelineConnectPipe #(.DATA_WIDTH(430)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_instr, io_in_bits_foldpc, io_in_bits_exceptionVec_0, io_in_bits_exceptionVec_1, io_in_bits_exceptionVec_2, io_in_bits_exceptionVec_3, io_in_bits_exceptionVec_4, io_in_bits_exceptionVec_5, io_in_bits_exceptionVec_6, io_in_bits_exceptionVec_7, io_in_bits_exceptionVec_8, io_in_bits_exceptionVec_9, io_in_bits_exceptionVec_10, io_in_bits_exceptionVec_11, io_in_bits_exceptionVec_12, io_in_bits_exceptionVec_13, io_in_bits_exceptionVec_14, io_in_bits_exceptionVec_15, io_in_bits_exceptionVec_16, io_in_bits_exceptionVec_17, io_in_bits_exceptionVec_18, io_in_bits_exceptionVec_19, io_in_bits_exceptionVec_20, io_in_bits_exceptionVec_21, io_in_bits_exceptionVec_22, io_in_bits_exceptionVec_23, io_in_bits_isFetchMalAddr, io_in_bits_trigger, io_in_bits_preDecodeInfo_isRVC, io_in_bits_preDecodeInfo_brType, io_in_bits_pred_taken, io_in_bits_crossPageIPFFix, io_in_bits_ftqPtr_flag, io_in_bits_ftqPtr_value, io_in_bits_ftqOffset, io_in_bits_srcType_0, io_in_bits_srcType_1, io_in_bits_srcType_2, io_in_bits_srcType_3, io_in_bits_srcType_4, io_in_bits_lsrc_0, io_in_bits_lsrc_1, io_in_bits_lsrc_2, 6'h0, 6'h0, io_in_bits_ldest, io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_isXSTrap, io_in_bits_waitForward, io_in_bits_blockBackward, io_in_bits_flushPipe, io_in_bits_canRobCompress, io_in_bits_selImm, io_in_bits_imm, io_in_bits_fpu_typeTagOut, io_in_bits_fpu_wflags, io_in_bits_fpu_typ, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_vpu_vill, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_specVill, io_in_bits_vpu_specVma, io_in_bits_vpu_specVta, io_in_bits_vpu_specVsew, io_in_bits_vpu_specVlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_8, 128'h0, io_in_bits_vpu_nf, io_in_bits_vpu_veew, io_in_bits_vpu_isExt, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_vpu_isOpMask, io_in_bits_vpu_isDependOldVd, io_in_bits_vpu_isWritePartVd, io_in_bits_vpu_isVleff, io_in_bits_vlsInstr, io_in_bits_wfflags, io_in_bits_isMove, io_in_bits_uopIdx, io_in_bits_uopSplitType, io_in_bits_isVset, io_in_bits_firstUop, io_in_bits_lastUop, io_in_bits_numWB, io_in_bits_commitType}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule
