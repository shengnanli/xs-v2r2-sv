// 自动生成: scripts/gen_pcp.py —— 勿手改
// tb —— PipelineConnectPipe UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_in_valid;
  logic [31:0] io_in_bits_instr;
  logic [9:0] io_in_bits_foldpc;
  logic io_in_bits_exceptionVec_0;
  logic io_in_bits_exceptionVec_1;
  logic io_in_bits_exceptionVec_2;
  logic io_in_bits_exceptionVec_3;
  logic io_in_bits_exceptionVec_4;
  logic io_in_bits_exceptionVec_5;
  logic io_in_bits_exceptionVec_6;
  logic io_in_bits_exceptionVec_7;
  logic io_in_bits_exceptionVec_8;
  logic io_in_bits_exceptionVec_9;
  logic io_in_bits_exceptionVec_10;
  logic io_in_bits_exceptionVec_11;
  logic io_in_bits_exceptionVec_12;
  logic io_in_bits_exceptionVec_13;
  logic io_in_bits_exceptionVec_14;
  logic io_in_bits_exceptionVec_15;
  logic io_in_bits_exceptionVec_16;
  logic io_in_bits_exceptionVec_17;
  logic io_in_bits_exceptionVec_18;
  logic io_in_bits_exceptionVec_19;
  logic io_in_bits_exceptionVec_20;
  logic io_in_bits_exceptionVec_21;
  logic io_in_bits_exceptionVec_22;
  logic io_in_bits_exceptionVec_23;
  logic io_in_bits_isFetchMalAddr;
  logic [3:0] io_in_bits_trigger;
  logic io_in_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_bits_preDecodeInfo_brType;
  logic io_in_bits_pred_taken;
  logic io_in_bits_crossPageIPFFix;
  logic io_in_bits_ftqPtr_flag;
  logic [5:0] io_in_bits_ftqPtr_value;
  logic [3:0] io_in_bits_ftqOffset;
  logic [3:0] io_in_bits_srcType_0;
  logic [3:0] io_in_bits_srcType_1;
  logic [3:0] io_in_bits_srcType_2;
  logic [3:0] io_in_bits_srcType_3;
  logic [3:0] io_in_bits_srcType_4;
  logic [5:0] io_in_bits_lsrc_0;
  logic [5:0] io_in_bits_lsrc_1;
  logic [5:0] io_in_bits_lsrc_2;
  logic [5:0] io_in_bits_ldest;
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic io_in_bits_rfWen;
  logic io_in_bits_fpWen;
  logic io_in_bits_vecWen;
  logic io_in_bits_v0Wen;
  logic io_in_bits_vlWen;
  logic io_in_bits_isXSTrap;
  logic io_in_bits_waitForward;
  logic io_in_bits_blockBackward;
  logic io_in_bits_flushPipe;
  logic io_in_bits_canRobCompress;
  logic [3:0] io_in_bits_selImm;
  logic [21:0] io_in_bits_imm;
  logic [1:0] io_in_bits_fpu_typeTagOut;
  logic io_in_bits_fpu_wflags;
  logic [1:0] io_in_bits_fpu_typ;
  logic [1:0] io_in_bits_fpu_fmt;
  logic [2:0] io_in_bits_fpu_rm;
  logic io_in_bits_vpu_vill;
  logic io_in_bits_vpu_vma;
  logic io_in_bits_vpu_vta;
  logic [1:0] io_in_bits_vpu_vsew;
  logic [2:0] io_in_bits_vpu_vlmul;
  logic io_in_bits_vpu_specVill;
  logic io_in_bits_vpu_specVma;
  logic io_in_bits_vpu_specVta;
  logic [1:0] io_in_bits_vpu_specVsew;
  logic [2:0] io_in_bits_vpu_specVlmul;
  logic io_in_bits_vpu_vm;
  logic [7:0] io_in_bits_vpu_vstart;
  logic io_in_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0] io_in_bits_vpu_nf;
  logic [1:0] io_in_bits_vpu_veew;
  logic io_in_bits_vpu_isExt;
  logic io_in_bits_vpu_isNarrow;
  logic io_in_bits_vpu_isDstMask;
  logic io_in_bits_vpu_isOpMask;
  logic io_in_bits_vpu_isDependOldVd;
  logic io_in_bits_vpu_isWritePartVd;
  logic io_in_bits_vpu_isVleff;
  logic io_in_bits_vlsInstr;
  logic io_in_bits_wfflags;
  logic io_in_bits_isMove;
  logic [6:0] io_in_bits_uopIdx;
  logic [5:0] io_in_bits_uopSplitType;
  logic io_in_bits_isVset;
  logic io_in_bits_firstUop;
  logic io_in_bits_lastUop;
  logic [6:0] io_in_bits_numWB;
  logic [2:0] io_in_bits_commitType;
  logic io_out_ready;
  logic io_rightOutFire;
  logic io_isFlush;
  logic g_io_in_ready;
  logic g_io_out_valid;
  logic [31:0] g_io_out_bits_instr;
  logic [9:0] g_io_out_bits_foldpc;
  logic g_io_out_bits_exceptionVec_0;
  logic g_io_out_bits_exceptionVec_1;
  logic g_io_out_bits_exceptionVec_2;
  logic g_io_out_bits_exceptionVec_3;
  logic g_io_out_bits_exceptionVec_4;
  logic g_io_out_bits_exceptionVec_5;
  logic g_io_out_bits_exceptionVec_6;
  logic g_io_out_bits_exceptionVec_7;
  logic g_io_out_bits_exceptionVec_8;
  logic g_io_out_bits_exceptionVec_9;
  logic g_io_out_bits_exceptionVec_10;
  logic g_io_out_bits_exceptionVec_11;
  logic g_io_out_bits_exceptionVec_12;
  logic g_io_out_bits_exceptionVec_13;
  logic g_io_out_bits_exceptionVec_14;
  logic g_io_out_bits_exceptionVec_15;
  logic g_io_out_bits_exceptionVec_16;
  logic g_io_out_bits_exceptionVec_17;
  logic g_io_out_bits_exceptionVec_18;
  logic g_io_out_bits_exceptionVec_19;
  logic g_io_out_bits_exceptionVec_20;
  logic g_io_out_bits_exceptionVec_21;
  logic g_io_out_bits_exceptionVec_22;
  logic g_io_out_bits_exceptionVec_23;
  logic g_io_out_bits_isFetchMalAddr;
  logic [3:0] g_io_out_bits_trigger;
  logic g_io_out_bits_preDecodeInfo_isRVC;
  logic [1:0] g_io_out_bits_preDecodeInfo_brType;
  logic g_io_out_bits_pred_taken;
  logic g_io_out_bits_crossPageIPFFix;
  logic g_io_out_bits_ftqPtr_flag;
  logic [5:0] g_io_out_bits_ftqPtr_value;
  logic [3:0] g_io_out_bits_ftqOffset;
  logic [3:0] g_io_out_bits_srcType_0;
  logic [3:0] g_io_out_bits_srcType_1;
  logic [3:0] g_io_out_bits_srcType_2;
  logic [3:0] g_io_out_bits_srcType_3;
  logic [3:0] g_io_out_bits_srcType_4;
  logic [5:0] g_io_out_bits_lsrc_0;
  logic [5:0] g_io_out_bits_lsrc_1;
  logic [5:0] g_io_out_bits_lsrc_2;
  logic [5:0] g_io_out_bits_lsrc_3;
  logic [5:0] g_io_out_bits_lsrc_4;
  logic [5:0] g_io_out_bits_ldest;
  logic [34:0] g_io_out_bits_fuType;
  logic [8:0] g_io_out_bits_fuOpType;
  logic g_io_out_bits_rfWen;
  logic g_io_out_bits_fpWen;
  logic g_io_out_bits_vecWen;
  logic g_io_out_bits_v0Wen;
  logic g_io_out_bits_vlWen;
  logic g_io_out_bits_isXSTrap;
  logic g_io_out_bits_waitForward;
  logic g_io_out_bits_blockBackward;
  logic g_io_out_bits_flushPipe;
  logic g_io_out_bits_canRobCompress;
  logic [3:0] g_io_out_bits_selImm;
  logic [21:0] g_io_out_bits_imm;
  logic [1:0] g_io_out_bits_fpu_typeTagOut;
  logic g_io_out_bits_fpu_wflags;
  logic [1:0] g_io_out_bits_fpu_typ;
  logic [1:0] g_io_out_bits_fpu_fmt;
  logic [2:0] g_io_out_bits_fpu_rm;
  logic g_io_out_bits_vpu_vill;
  logic g_io_out_bits_vpu_vma;
  logic g_io_out_bits_vpu_vta;
  logic [1:0] g_io_out_bits_vpu_vsew;
  logic [2:0] g_io_out_bits_vpu_vlmul;
  logic g_io_out_bits_vpu_specVill;
  logic g_io_out_bits_vpu_specVma;
  logic g_io_out_bits_vpu_specVta;
  logic [1:0] g_io_out_bits_vpu_specVsew;
  logic [2:0] g_io_out_bits_vpu_specVlmul;
  logic g_io_out_bits_vpu_vm;
  logic [7:0] g_io_out_bits_vpu_vstart;
  logic g_io_out_bits_vpu_fpu_isFoldTo1_2;
  logic g_io_out_bits_vpu_fpu_isFoldTo1_4;
  logic g_io_out_bits_vpu_fpu_isFoldTo1_8;
  logic [127:0] g_io_out_bits_vpu_vmask;
  logic [2:0] g_io_out_bits_vpu_nf;
  logic [1:0] g_io_out_bits_vpu_veew;
  logic g_io_out_bits_vpu_isExt;
  logic g_io_out_bits_vpu_isNarrow;
  logic g_io_out_bits_vpu_isDstMask;
  logic g_io_out_bits_vpu_isOpMask;
  logic g_io_out_bits_vpu_isDependOldVd;
  logic g_io_out_bits_vpu_isWritePartVd;
  logic g_io_out_bits_vpu_isVleff;
  logic g_io_out_bits_vlsInstr;
  logic g_io_out_bits_wfflags;
  logic g_io_out_bits_isMove;
  logic [6:0] g_io_out_bits_uopIdx;
  logic [5:0] g_io_out_bits_uopSplitType;
  logic g_io_out_bits_isVset;
  logic g_io_out_bits_firstUop;
  logic g_io_out_bits_lastUop;
  logic [6:0] g_io_out_bits_numWB;
  logic [2:0] g_io_out_bits_commitType;
  logic i_io_in_ready;
  logic i_io_out_valid;
  logic [31:0] i_io_out_bits_instr;
  logic [9:0] i_io_out_bits_foldpc;
  logic i_io_out_bits_exceptionVec_0;
  logic i_io_out_bits_exceptionVec_1;
  logic i_io_out_bits_exceptionVec_2;
  logic i_io_out_bits_exceptionVec_3;
  logic i_io_out_bits_exceptionVec_4;
  logic i_io_out_bits_exceptionVec_5;
  logic i_io_out_bits_exceptionVec_6;
  logic i_io_out_bits_exceptionVec_7;
  logic i_io_out_bits_exceptionVec_8;
  logic i_io_out_bits_exceptionVec_9;
  logic i_io_out_bits_exceptionVec_10;
  logic i_io_out_bits_exceptionVec_11;
  logic i_io_out_bits_exceptionVec_12;
  logic i_io_out_bits_exceptionVec_13;
  logic i_io_out_bits_exceptionVec_14;
  logic i_io_out_bits_exceptionVec_15;
  logic i_io_out_bits_exceptionVec_16;
  logic i_io_out_bits_exceptionVec_17;
  logic i_io_out_bits_exceptionVec_18;
  logic i_io_out_bits_exceptionVec_19;
  logic i_io_out_bits_exceptionVec_20;
  logic i_io_out_bits_exceptionVec_21;
  logic i_io_out_bits_exceptionVec_22;
  logic i_io_out_bits_exceptionVec_23;
  logic i_io_out_bits_isFetchMalAddr;
  logic [3:0] i_io_out_bits_trigger;
  logic i_io_out_bits_preDecodeInfo_isRVC;
  logic [1:0] i_io_out_bits_preDecodeInfo_brType;
  logic i_io_out_bits_pred_taken;
  logic i_io_out_bits_crossPageIPFFix;
  logic i_io_out_bits_ftqPtr_flag;
  logic [5:0] i_io_out_bits_ftqPtr_value;
  logic [3:0] i_io_out_bits_ftqOffset;
  logic [3:0] i_io_out_bits_srcType_0;
  logic [3:0] i_io_out_bits_srcType_1;
  logic [3:0] i_io_out_bits_srcType_2;
  logic [3:0] i_io_out_bits_srcType_3;
  logic [3:0] i_io_out_bits_srcType_4;
  logic [5:0] i_io_out_bits_lsrc_0;
  logic [5:0] i_io_out_bits_lsrc_1;
  logic [5:0] i_io_out_bits_lsrc_2;
  logic [5:0] i_io_out_bits_lsrc_3;
  logic [5:0] i_io_out_bits_lsrc_4;
  logic [5:0] i_io_out_bits_ldest;
  logic [34:0] i_io_out_bits_fuType;
  logic [8:0] i_io_out_bits_fuOpType;
  logic i_io_out_bits_rfWen;
  logic i_io_out_bits_fpWen;
  logic i_io_out_bits_vecWen;
  logic i_io_out_bits_v0Wen;
  logic i_io_out_bits_vlWen;
  logic i_io_out_bits_isXSTrap;
  logic i_io_out_bits_waitForward;
  logic i_io_out_bits_blockBackward;
  logic i_io_out_bits_flushPipe;
  logic i_io_out_bits_canRobCompress;
  logic [3:0] i_io_out_bits_selImm;
  logic [21:0] i_io_out_bits_imm;
  logic [1:0] i_io_out_bits_fpu_typeTagOut;
  logic i_io_out_bits_fpu_wflags;
  logic [1:0] i_io_out_bits_fpu_typ;
  logic [1:0] i_io_out_bits_fpu_fmt;
  logic [2:0] i_io_out_bits_fpu_rm;
  logic i_io_out_bits_vpu_vill;
  logic i_io_out_bits_vpu_vma;
  logic i_io_out_bits_vpu_vta;
  logic [1:0] i_io_out_bits_vpu_vsew;
  logic [2:0] i_io_out_bits_vpu_vlmul;
  logic i_io_out_bits_vpu_specVill;
  logic i_io_out_bits_vpu_specVma;
  logic i_io_out_bits_vpu_specVta;
  logic [1:0] i_io_out_bits_vpu_specVsew;
  logic [2:0] i_io_out_bits_vpu_specVlmul;
  logic i_io_out_bits_vpu_vm;
  logic [7:0] i_io_out_bits_vpu_vstart;
  logic i_io_out_bits_vpu_fpu_isFoldTo1_2;
  logic i_io_out_bits_vpu_fpu_isFoldTo1_4;
  logic i_io_out_bits_vpu_fpu_isFoldTo1_8;
  logic [127:0] i_io_out_bits_vpu_vmask;
  logic [2:0] i_io_out_bits_vpu_nf;
  logic [1:0] i_io_out_bits_vpu_veew;
  logic i_io_out_bits_vpu_isExt;
  logic i_io_out_bits_vpu_isNarrow;
  logic i_io_out_bits_vpu_isDstMask;
  logic i_io_out_bits_vpu_isOpMask;
  logic i_io_out_bits_vpu_isDependOldVd;
  logic i_io_out_bits_vpu_isWritePartVd;
  logic i_io_out_bits_vpu_isVleff;
  logic i_io_out_bits_vlsInstr;
  logic i_io_out_bits_wfflags;
  logic i_io_out_bits_isMove;
  logic [6:0] i_io_out_bits_uopIdx;
  logic [5:0] i_io_out_bits_uopSplitType;
  logic i_io_out_bits_isVset;
  logic i_io_out_bits_firstUop;
  logic i_io_out_bits_lastUop;
  logic [6:0] i_io_out_bits_numWB;
  logic [2:0] i_io_out_bits_commitType;

  PipelineConnectPipe u_g (
    .clock(clk),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_instr(io_in_bits_instr),
    .io_in_bits_foldpc(io_in_bits_foldpc),
    .io_in_bits_exceptionVec_0(io_in_bits_exceptionVec_0),
    .io_in_bits_exceptionVec_1(io_in_bits_exceptionVec_1),
    .io_in_bits_exceptionVec_2(io_in_bits_exceptionVec_2),
    .io_in_bits_exceptionVec_3(io_in_bits_exceptionVec_3),
    .io_in_bits_exceptionVec_4(io_in_bits_exceptionVec_4),
    .io_in_bits_exceptionVec_5(io_in_bits_exceptionVec_5),
    .io_in_bits_exceptionVec_6(io_in_bits_exceptionVec_6),
    .io_in_bits_exceptionVec_7(io_in_bits_exceptionVec_7),
    .io_in_bits_exceptionVec_8(io_in_bits_exceptionVec_8),
    .io_in_bits_exceptionVec_9(io_in_bits_exceptionVec_9),
    .io_in_bits_exceptionVec_10(io_in_bits_exceptionVec_10),
    .io_in_bits_exceptionVec_11(io_in_bits_exceptionVec_11),
    .io_in_bits_exceptionVec_12(io_in_bits_exceptionVec_12),
    .io_in_bits_exceptionVec_13(io_in_bits_exceptionVec_13),
    .io_in_bits_exceptionVec_14(io_in_bits_exceptionVec_14),
    .io_in_bits_exceptionVec_15(io_in_bits_exceptionVec_15),
    .io_in_bits_exceptionVec_16(io_in_bits_exceptionVec_16),
    .io_in_bits_exceptionVec_17(io_in_bits_exceptionVec_17),
    .io_in_bits_exceptionVec_18(io_in_bits_exceptionVec_18),
    .io_in_bits_exceptionVec_19(io_in_bits_exceptionVec_19),
    .io_in_bits_exceptionVec_20(io_in_bits_exceptionVec_20),
    .io_in_bits_exceptionVec_21(io_in_bits_exceptionVec_21),
    .io_in_bits_exceptionVec_22(io_in_bits_exceptionVec_22),
    .io_in_bits_exceptionVec_23(io_in_bits_exceptionVec_23),
    .io_in_bits_isFetchMalAddr(io_in_bits_isFetchMalAddr),
    .io_in_bits_trigger(io_in_bits_trigger),
    .io_in_bits_preDecodeInfo_isRVC(io_in_bits_preDecodeInfo_isRVC),
    .io_in_bits_preDecodeInfo_brType(io_in_bits_preDecodeInfo_brType),
    .io_in_bits_pred_taken(io_in_bits_pred_taken),
    .io_in_bits_crossPageIPFFix(io_in_bits_crossPageIPFFix),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_srcType_0(io_in_bits_srcType_0),
    .io_in_bits_srcType_1(io_in_bits_srcType_1),
    .io_in_bits_srcType_2(io_in_bits_srcType_2),
    .io_in_bits_srcType_3(io_in_bits_srcType_3),
    .io_in_bits_srcType_4(io_in_bits_srcType_4),
    .io_in_bits_lsrc_0(io_in_bits_lsrc_0),
    .io_in_bits_lsrc_1(io_in_bits_lsrc_1),
    .io_in_bits_lsrc_2(io_in_bits_lsrc_2),
    .io_in_bits_ldest(io_in_bits_ldest),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_vecWen(io_in_bits_vecWen),
    .io_in_bits_v0Wen(io_in_bits_v0Wen),
    .io_in_bits_vlWen(io_in_bits_vlWen),
    .io_in_bits_isXSTrap(io_in_bits_isXSTrap),
    .io_in_bits_waitForward(io_in_bits_waitForward),
    .io_in_bits_blockBackward(io_in_bits_blockBackward),
    .io_in_bits_flushPipe(io_in_bits_flushPipe),
    .io_in_bits_canRobCompress(io_in_bits_canRobCompress),
    .io_in_bits_selImm(io_in_bits_selImm),
    .io_in_bits_imm(io_in_bits_imm),
    .io_in_bits_fpu_typeTagOut(io_in_bits_fpu_typeTagOut),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_typ(io_in_bits_fpu_typ),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_vpu_vill(io_in_bits_vpu_vill),
    .io_in_bits_vpu_vma(io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_specVill(io_in_bits_vpu_specVill),
    .io_in_bits_vpu_specVma(io_in_bits_vpu_specVma),
    .io_in_bits_vpu_specVta(io_in_bits_vpu_specVta),
    .io_in_bits_vpu_specVsew(io_in_bits_vpu_specVsew),
    .io_in_bits_vpu_specVlmul(io_in_bits_vpu_specVlmul),
    .io_in_bits_vpu_vm(io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_nf(io_in_bits_vpu_nf),
    .io_in_bits_vpu_veew(io_in_bits_vpu_veew),
    .io_in_bits_vpu_isExt(io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(io_in_bits_vpu_isOpMask),
    .io_in_bits_vpu_isDependOldVd(io_in_bits_vpu_isDependOldVd),
    .io_in_bits_vpu_isWritePartVd(io_in_bits_vpu_isWritePartVd),
    .io_in_bits_vpu_isVleff(io_in_bits_vpu_isVleff),
    .io_in_bits_vlsInstr(io_in_bits_vlsInstr),
    .io_in_bits_wfflags(io_in_bits_wfflags),
    .io_in_bits_isMove(io_in_bits_isMove),
    .io_in_bits_uopIdx(io_in_bits_uopIdx),
    .io_in_bits_uopSplitType(io_in_bits_uopSplitType),
    .io_in_bits_isVset(io_in_bits_isVset),
    .io_in_bits_firstUop(io_in_bits_firstUop),
    .io_in_bits_lastUop(io_in_bits_lastUop),
    .io_in_bits_numWB(io_in_bits_numWB),
    .io_in_bits_commitType(io_in_bits_commitType),
    .io_out_ready(io_out_ready),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_instr(g_io_out_bits_instr),
    .io_out_bits_foldpc(g_io_out_bits_foldpc),
    .io_out_bits_exceptionVec_0(g_io_out_bits_exceptionVec_0),
    .io_out_bits_exceptionVec_1(g_io_out_bits_exceptionVec_1),
    .io_out_bits_exceptionVec_2(g_io_out_bits_exceptionVec_2),
    .io_out_bits_exceptionVec_3(g_io_out_bits_exceptionVec_3),
    .io_out_bits_exceptionVec_4(g_io_out_bits_exceptionVec_4),
    .io_out_bits_exceptionVec_5(g_io_out_bits_exceptionVec_5),
    .io_out_bits_exceptionVec_6(g_io_out_bits_exceptionVec_6),
    .io_out_bits_exceptionVec_7(g_io_out_bits_exceptionVec_7),
    .io_out_bits_exceptionVec_8(g_io_out_bits_exceptionVec_8),
    .io_out_bits_exceptionVec_9(g_io_out_bits_exceptionVec_9),
    .io_out_bits_exceptionVec_10(g_io_out_bits_exceptionVec_10),
    .io_out_bits_exceptionVec_11(g_io_out_bits_exceptionVec_11),
    .io_out_bits_exceptionVec_12(g_io_out_bits_exceptionVec_12),
    .io_out_bits_exceptionVec_13(g_io_out_bits_exceptionVec_13),
    .io_out_bits_exceptionVec_14(g_io_out_bits_exceptionVec_14),
    .io_out_bits_exceptionVec_15(g_io_out_bits_exceptionVec_15),
    .io_out_bits_exceptionVec_16(g_io_out_bits_exceptionVec_16),
    .io_out_bits_exceptionVec_17(g_io_out_bits_exceptionVec_17),
    .io_out_bits_exceptionVec_18(g_io_out_bits_exceptionVec_18),
    .io_out_bits_exceptionVec_19(g_io_out_bits_exceptionVec_19),
    .io_out_bits_exceptionVec_20(g_io_out_bits_exceptionVec_20),
    .io_out_bits_exceptionVec_21(g_io_out_bits_exceptionVec_21),
    .io_out_bits_exceptionVec_22(g_io_out_bits_exceptionVec_22),
    .io_out_bits_exceptionVec_23(g_io_out_bits_exceptionVec_23),
    .io_out_bits_isFetchMalAddr(g_io_out_bits_isFetchMalAddr),
    .io_out_bits_trigger(g_io_out_bits_trigger),
    .io_out_bits_preDecodeInfo_isRVC(g_io_out_bits_preDecodeInfo_isRVC),
    .io_out_bits_preDecodeInfo_brType(g_io_out_bits_preDecodeInfo_brType),
    .io_out_bits_pred_taken(g_io_out_bits_pred_taken),
    .io_out_bits_crossPageIPFFix(g_io_out_bits_crossPageIPFFix),
    .io_out_bits_ftqPtr_flag(g_io_out_bits_ftqPtr_flag),
    .io_out_bits_ftqPtr_value(g_io_out_bits_ftqPtr_value),
    .io_out_bits_ftqOffset(g_io_out_bits_ftqOffset),
    .io_out_bits_srcType_0(g_io_out_bits_srcType_0),
    .io_out_bits_srcType_1(g_io_out_bits_srcType_1),
    .io_out_bits_srcType_2(g_io_out_bits_srcType_2),
    .io_out_bits_srcType_3(g_io_out_bits_srcType_3),
    .io_out_bits_srcType_4(g_io_out_bits_srcType_4),
    .io_out_bits_lsrc_0(g_io_out_bits_lsrc_0),
    .io_out_bits_lsrc_1(g_io_out_bits_lsrc_1),
    .io_out_bits_lsrc_2(g_io_out_bits_lsrc_2),
    .io_out_bits_lsrc_3(g_io_out_bits_lsrc_3),
    .io_out_bits_lsrc_4(g_io_out_bits_lsrc_4),
    .io_out_bits_ldest(g_io_out_bits_ldest),
    .io_out_bits_fuType(g_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_io_out_bits_fuOpType),
    .io_out_bits_rfWen(g_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_io_out_bits_v0Wen),
    .io_out_bits_vlWen(g_io_out_bits_vlWen),
    .io_out_bits_isXSTrap(g_io_out_bits_isXSTrap),
    .io_out_bits_waitForward(g_io_out_bits_waitForward),
    .io_out_bits_blockBackward(g_io_out_bits_blockBackward),
    .io_out_bits_flushPipe(g_io_out_bits_flushPipe),
    .io_out_bits_canRobCompress(g_io_out_bits_canRobCompress),
    .io_out_bits_selImm(g_io_out_bits_selImm),
    .io_out_bits_imm(g_io_out_bits_imm),
    .io_out_bits_fpu_typeTagOut(g_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(g_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(g_io_out_bits_fpu_typ),
    .io_out_bits_fpu_fmt(g_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(g_io_out_bits_fpu_rm),
    .io_out_bits_vpu_vill(g_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(g_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(g_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(g_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(g_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(g_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(g_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(g_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(g_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(g_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(g_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vmask(g_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_nf(g_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(g_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isExt(g_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(g_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(g_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isDependOldVd(g_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(g_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(g_io_out_bits_vpu_isVleff),
    .io_out_bits_vlsInstr(g_io_out_bits_vlsInstr),
    .io_out_bits_wfflags(g_io_out_bits_wfflags),
    .io_out_bits_isMove(g_io_out_bits_isMove),
    .io_out_bits_uopIdx(g_io_out_bits_uopIdx),
    .io_out_bits_uopSplitType(g_io_out_bits_uopSplitType),
    .io_out_bits_isVset(g_io_out_bits_isVset),
    .io_out_bits_firstUop(g_io_out_bits_firstUop),
    .io_out_bits_lastUop(g_io_out_bits_lastUop),
    .io_out_bits_numWB(g_io_out_bits_numWB),
    .io_out_bits_commitType(g_io_out_bits_commitType)
  );

  PipelineConnectPipe_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_instr(io_in_bits_instr),
    .io_in_bits_foldpc(io_in_bits_foldpc),
    .io_in_bits_exceptionVec_0(io_in_bits_exceptionVec_0),
    .io_in_bits_exceptionVec_1(io_in_bits_exceptionVec_1),
    .io_in_bits_exceptionVec_2(io_in_bits_exceptionVec_2),
    .io_in_bits_exceptionVec_3(io_in_bits_exceptionVec_3),
    .io_in_bits_exceptionVec_4(io_in_bits_exceptionVec_4),
    .io_in_bits_exceptionVec_5(io_in_bits_exceptionVec_5),
    .io_in_bits_exceptionVec_6(io_in_bits_exceptionVec_6),
    .io_in_bits_exceptionVec_7(io_in_bits_exceptionVec_7),
    .io_in_bits_exceptionVec_8(io_in_bits_exceptionVec_8),
    .io_in_bits_exceptionVec_9(io_in_bits_exceptionVec_9),
    .io_in_bits_exceptionVec_10(io_in_bits_exceptionVec_10),
    .io_in_bits_exceptionVec_11(io_in_bits_exceptionVec_11),
    .io_in_bits_exceptionVec_12(io_in_bits_exceptionVec_12),
    .io_in_bits_exceptionVec_13(io_in_bits_exceptionVec_13),
    .io_in_bits_exceptionVec_14(io_in_bits_exceptionVec_14),
    .io_in_bits_exceptionVec_15(io_in_bits_exceptionVec_15),
    .io_in_bits_exceptionVec_16(io_in_bits_exceptionVec_16),
    .io_in_bits_exceptionVec_17(io_in_bits_exceptionVec_17),
    .io_in_bits_exceptionVec_18(io_in_bits_exceptionVec_18),
    .io_in_bits_exceptionVec_19(io_in_bits_exceptionVec_19),
    .io_in_bits_exceptionVec_20(io_in_bits_exceptionVec_20),
    .io_in_bits_exceptionVec_21(io_in_bits_exceptionVec_21),
    .io_in_bits_exceptionVec_22(io_in_bits_exceptionVec_22),
    .io_in_bits_exceptionVec_23(io_in_bits_exceptionVec_23),
    .io_in_bits_isFetchMalAddr(io_in_bits_isFetchMalAddr),
    .io_in_bits_trigger(io_in_bits_trigger),
    .io_in_bits_preDecodeInfo_isRVC(io_in_bits_preDecodeInfo_isRVC),
    .io_in_bits_preDecodeInfo_brType(io_in_bits_preDecodeInfo_brType),
    .io_in_bits_pred_taken(io_in_bits_pred_taken),
    .io_in_bits_crossPageIPFFix(io_in_bits_crossPageIPFFix),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_srcType_0(io_in_bits_srcType_0),
    .io_in_bits_srcType_1(io_in_bits_srcType_1),
    .io_in_bits_srcType_2(io_in_bits_srcType_2),
    .io_in_bits_srcType_3(io_in_bits_srcType_3),
    .io_in_bits_srcType_4(io_in_bits_srcType_4),
    .io_in_bits_lsrc_0(io_in_bits_lsrc_0),
    .io_in_bits_lsrc_1(io_in_bits_lsrc_1),
    .io_in_bits_lsrc_2(io_in_bits_lsrc_2),
    .io_in_bits_ldest(io_in_bits_ldest),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_vecWen(io_in_bits_vecWen),
    .io_in_bits_v0Wen(io_in_bits_v0Wen),
    .io_in_bits_vlWen(io_in_bits_vlWen),
    .io_in_bits_isXSTrap(io_in_bits_isXSTrap),
    .io_in_bits_waitForward(io_in_bits_waitForward),
    .io_in_bits_blockBackward(io_in_bits_blockBackward),
    .io_in_bits_flushPipe(io_in_bits_flushPipe),
    .io_in_bits_canRobCompress(io_in_bits_canRobCompress),
    .io_in_bits_selImm(io_in_bits_selImm),
    .io_in_bits_imm(io_in_bits_imm),
    .io_in_bits_fpu_typeTagOut(io_in_bits_fpu_typeTagOut),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_typ(io_in_bits_fpu_typ),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_vpu_vill(io_in_bits_vpu_vill),
    .io_in_bits_vpu_vma(io_in_bits_vpu_vma),
    .io_in_bits_vpu_vta(io_in_bits_vpu_vta),
    .io_in_bits_vpu_vsew(io_in_bits_vpu_vsew),
    .io_in_bits_vpu_vlmul(io_in_bits_vpu_vlmul),
    .io_in_bits_vpu_specVill(io_in_bits_vpu_specVill),
    .io_in_bits_vpu_specVma(io_in_bits_vpu_specVma),
    .io_in_bits_vpu_specVta(io_in_bits_vpu_specVta),
    .io_in_bits_vpu_specVsew(io_in_bits_vpu_specVsew),
    .io_in_bits_vpu_specVlmul(io_in_bits_vpu_specVlmul),
    .io_in_bits_vpu_vm(io_in_bits_vpu_vm),
    .io_in_bits_vpu_vstart(io_in_bits_vpu_vstart),
    .io_in_bits_vpu_fpu_isFoldTo1_2(io_in_bits_vpu_fpu_isFoldTo1_2),
    .io_in_bits_vpu_fpu_isFoldTo1_4(io_in_bits_vpu_fpu_isFoldTo1_4),
    .io_in_bits_vpu_fpu_isFoldTo1_8(io_in_bits_vpu_fpu_isFoldTo1_8),
    .io_in_bits_vpu_nf(io_in_bits_vpu_nf),
    .io_in_bits_vpu_veew(io_in_bits_vpu_veew),
    .io_in_bits_vpu_isExt(io_in_bits_vpu_isExt),
    .io_in_bits_vpu_isNarrow(io_in_bits_vpu_isNarrow),
    .io_in_bits_vpu_isDstMask(io_in_bits_vpu_isDstMask),
    .io_in_bits_vpu_isOpMask(io_in_bits_vpu_isOpMask),
    .io_in_bits_vpu_isDependOldVd(io_in_bits_vpu_isDependOldVd),
    .io_in_bits_vpu_isWritePartVd(io_in_bits_vpu_isWritePartVd),
    .io_in_bits_vpu_isVleff(io_in_bits_vpu_isVleff),
    .io_in_bits_vlsInstr(io_in_bits_vlsInstr),
    .io_in_bits_wfflags(io_in_bits_wfflags),
    .io_in_bits_isMove(io_in_bits_isMove),
    .io_in_bits_uopIdx(io_in_bits_uopIdx),
    .io_in_bits_uopSplitType(io_in_bits_uopSplitType),
    .io_in_bits_isVset(io_in_bits_isVset),
    .io_in_bits_firstUop(io_in_bits_firstUop),
    .io_in_bits_lastUop(io_in_bits_lastUop),
    .io_in_bits_numWB(io_in_bits_numWB),
    .io_in_bits_commitType(io_in_bits_commitType),
    .io_out_ready(io_out_ready),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_instr(i_io_out_bits_instr),
    .io_out_bits_foldpc(i_io_out_bits_foldpc),
    .io_out_bits_exceptionVec_0(i_io_out_bits_exceptionVec_0),
    .io_out_bits_exceptionVec_1(i_io_out_bits_exceptionVec_1),
    .io_out_bits_exceptionVec_2(i_io_out_bits_exceptionVec_2),
    .io_out_bits_exceptionVec_3(i_io_out_bits_exceptionVec_3),
    .io_out_bits_exceptionVec_4(i_io_out_bits_exceptionVec_4),
    .io_out_bits_exceptionVec_5(i_io_out_bits_exceptionVec_5),
    .io_out_bits_exceptionVec_6(i_io_out_bits_exceptionVec_6),
    .io_out_bits_exceptionVec_7(i_io_out_bits_exceptionVec_7),
    .io_out_bits_exceptionVec_8(i_io_out_bits_exceptionVec_8),
    .io_out_bits_exceptionVec_9(i_io_out_bits_exceptionVec_9),
    .io_out_bits_exceptionVec_10(i_io_out_bits_exceptionVec_10),
    .io_out_bits_exceptionVec_11(i_io_out_bits_exceptionVec_11),
    .io_out_bits_exceptionVec_12(i_io_out_bits_exceptionVec_12),
    .io_out_bits_exceptionVec_13(i_io_out_bits_exceptionVec_13),
    .io_out_bits_exceptionVec_14(i_io_out_bits_exceptionVec_14),
    .io_out_bits_exceptionVec_15(i_io_out_bits_exceptionVec_15),
    .io_out_bits_exceptionVec_16(i_io_out_bits_exceptionVec_16),
    .io_out_bits_exceptionVec_17(i_io_out_bits_exceptionVec_17),
    .io_out_bits_exceptionVec_18(i_io_out_bits_exceptionVec_18),
    .io_out_bits_exceptionVec_19(i_io_out_bits_exceptionVec_19),
    .io_out_bits_exceptionVec_20(i_io_out_bits_exceptionVec_20),
    .io_out_bits_exceptionVec_21(i_io_out_bits_exceptionVec_21),
    .io_out_bits_exceptionVec_22(i_io_out_bits_exceptionVec_22),
    .io_out_bits_exceptionVec_23(i_io_out_bits_exceptionVec_23),
    .io_out_bits_isFetchMalAddr(i_io_out_bits_isFetchMalAddr),
    .io_out_bits_trigger(i_io_out_bits_trigger),
    .io_out_bits_preDecodeInfo_isRVC(i_io_out_bits_preDecodeInfo_isRVC),
    .io_out_bits_preDecodeInfo_brType(i_io_out_bits_preDecodeInfo_brType),
    .io_out_bits_pred_taken(i_io_out_bits_pred_taken),
    .io_out_bits_crossPageIPFFix(i_io_out_bits_crossPageIPFFix),
    .io_out_bits_ftqPtr_flag(i_io_out_bits_ftqPtr_flag),
    .io_out_bits_ftqPtr_value(i_io_out_bits_ftqPtr_value),
    .io_out_bits_ftqOffset(i_io_out_bits_ftqOffset),
    .io_out_bits_srcType_0(i_io_out_bits_srcType_0),
    .io_out_bits_srcType_1(i_io_out_bits_srcType_1),
    .io_out_bits_srcType_2(i_io_out_bits_srcType_2),
    .io_out_bits_srcType_3(i_io_out_bits_srcType_3),
    .io_out_bits_srcType_4(i_io_out_bits_srcType_4),
    .io_out_bits_lsrc_0(i_io_out_bits_lsrc_0),
    .io_out_bits_lsrc_1(i_io_out_bits_lsrc_1),
    .io_out_bits_lsrc_2(i_io_out_bits_lsrc_2),
    .io_out_bits_lsrc_3(i_io_out_bits_lsrc_3),
    .io_out_bits_lsrc_4(i_io_out_bits_lsrc_4),
    .io_out_bits_ldest(i_io_out_bits_ldest),
    .io_out_bits_fuType(i_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_io_out_bits_fuOpType),
    .io_out_bits_rfWen(i_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_io_out_bits_v0Wen),
    .io_out_bits_vlWen(i_io_out_bits_vlWen),
    .io_out_bits_isXSTrap(i_io_out_bits_isXSTrap),
    .io_out_bits_waitForward(i_io_out_bits_waitForward),
    .io_out_bits_blockBackward(i_io_out_bits_blockBackward),
    .io_out_bits_flushPipe(i_io_out_bits_flushPipe),
    .io_out_bits_canRobCompress(i_io_out_bits_canRobCompress),
    .io_out_bits_selImm(i_io_out_bits_selImm),
    .io_out_bits_imm(i_io_out_bits_imm),
    .io_out_bits_fpu_typeTagOut(i_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(i_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(i_io_out_bits_fpu_typ),
    .io_out_bits_fpu_fmt(i_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(i_io_out_bits_fpu_rm),
    .io_out_bits_vpu_vill(i_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(i_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(i_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(i_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(i_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(i_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(i_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(i_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_fpu_isFoldTo1_2(i_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(i_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(i_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vmask(i_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_nf(i_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(i_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isExt(i_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(i_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(i_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isDependOldVd(i_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(i_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(i_io_out_bits_vpu_isVleff),
    .io_out_bits_vlsInstr(i_io_out_bits_vlsInstr),
    .io_out_bits_wfflags(i_io_out_bits_wfflags),
    .io_out_bits_isMove(i_io_out_bits_isMove),
    .io_out_bits_uopIdx(i_io_out_bits_uopIdx),
    .io_out_bits_uopSplitType(i_io_out_bits_uopSplitType),
    .io_out_bits_isVset(i_io_out_bits_isVset),
    .io_out_bits_firstUop(i_io_out_bits_firstUop),
    .io_out_bits_lastUop(i_io_out_bits_lastUop),
    .io_out_bits_numWB(i_io_out_bits_numWB),
    .io_out_bits_commitType(i_io_out_bits_commitType)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_in_valid = $urandom;
    io_in_bits_instr = $urandom;
    io_in_bits_foldpc = $urandom;
    io_in_bits_exceptionVec_0 = $urandom;
    io_in_bits_exceptionVec_1 = $urandom;
    io_in_bits_exceptionVec_2 = $urandom;
    io_in_bits_exceptionVec_3 = $urandom;
    io_in_bits_exceptionVec_4 = $urandom;
    io_in_bits_exceptionVec_5 = $urandom;
    io_in_bits_exceptionVec_6 = $urandom;
    io_in_bits_exceptionVec_7 = $urandom;
    io_in_bits_exceptionVec_8 = $urandom;
    io_in_bits_exceptionVec_9 = $urandom;
    io_in_bits_exceptionVec_10 = $urandom;
    io_in_bits_exceptionVec_11 = $urandom;
    io_in_bits_exceptionVec_12 = $urandom;
    io_in_bits_exceptionVec_13 = $urandom;
    io_in_bits_exceptionVec_14 = $urandom;
    io_in_bits_exceptionVec_15 = $urandom;
    io_in_bits_exceptionVec_16 = $urandom;
    io_in_bits_exceptionVec_17 = $urandom;
    io_in_bits_exceptionVec_18 = $urandom;
    io_in_bits_exceptionVec_19 = $urandom;
    io_in_bits_exceptionVec_20 = $urandom;
    io_in_bits_exceptionVec_21 = $urandom;
    io_in_bits_exceptionVec_22 = $urandom;
    io_in_bits_exceptionVec_23 = $urandom;
    io_in_bits_isFetchMalAddr = $urandom;
    io_in_bits_trigger = $urandom;
    io_in_bits_preDecodeInfo_isRVC = $urandom;
    io_in_bits_preDecodeInfo_brType = $urandom;
    io_in_bits_pred_taken = $urandom;
    io_in_bits_crossPageIPFFix = $urandom;
    io_in_bits_ftqPtr_flag = $urandom;
    io_in_bits_ftqPtr_value = $urandom;
    io_in_bits_ftqOffset = $urandom;
    io_in_bits_srcType_0 = $urandom;
    io_in_bits_srcType_1 = $urandom;
    io_in_bits_srcType_2 = $urandom;
    io_in_bits_srcType_3 = $urandom;
    io_in_bits_srcType_4 = $urandom;
    io_in_bits_lsrc_0 = $urandom;
    io_in_bits_lsrc_1 = $urandom;
    io_in_bits_lsrc_2 = $urandom;
    io_in_bits_ldest = $urandom;
    io_in_bits_fuType = $urandom;
    io_in_bits_fuOpType = $urandom;
    io_in_bits_rfWen = $urandom;
    io_in_bits_fpWen = $urandom;
    io_in_bits_vecWen = $urandom;
    io_in_bits_v0Wen = $urandom;
    io_in_bits_vlWen = $urandom;
    io_in_bits_isXSTrap = $urandom;
    io_in_bits_waitForward = $urandom;
    io_in_bits_blockBackward = $urandom;
    io_in_bits_flushPipe = $urandom;
    io_in_bits_canRobCompress = $urandom;
    io_in_bits_selImm = $urandom;
    io_in_bits_imm = $urandom;
    io_in_bits_fpu_typeTagOut = $urandom;
    io_in_bits_fpu_wflags = $urandom;
    io_in_bits_fpu_typ = $urandom;
    io_in_bits_fpu_fmt = $urandom;
    io_in_bits_fpu_rm = $urandom;
    io_in_bits_vpu_vill = $urandom;
    io_in_bits_vpu_vma = $urandom;
    io_in_bits_vpu_vta = $urandom;
    io_in_bits_vpu_vsew = $urandom;
    io_in_bits_vpu_vlmul = $urandom;
    io_in_bits_vpu_specVill = $urandom;
    io_in_bits_vpu_specVma = $urandom;
    io_in_bits_vpu_specVta = $urandom;
    io_in_bits_vpu_specVsew = $urandom;
    io_in_bits_vpu_specVlmul = $urandom;
    io_in_bits_vpu_vm = $urandom;
    io_in_bits_vpu_vstart = $urandom;
    io_in_bits_vpu_fpu_isFoldTo1_2 = $urandom;
    io_in_bits_vpu_fpu_isFoldTo1_4 = $urandom;
    io_in_bits_vpu_fpu_isFoldTo1_8 = $urandom;
    io_in_bits_vpu_nf = $urandom;
    io_in_bits_vpu_veew = $urandom;
    io_in_bits_vpu_isExt = $urandom;
    io_in_bits_vpu_isNarrow = $urandom;
    io_in_bits_vpu_isDstMask = $urandom;
    io_in_bits_vpu_isOpMask = $urandom;
    io_in_bits_vpu_isDependOldVd = $urandom;
    io_in_bits_vpu_isWritePartVd = $urandom;
    io_in_bits_vpu_isVleff = $urandom;
    io_in_bits_vlsInstr = $urandom;
    io_in_bits_wfflags = $urandom;
    io_in_bits_isMove = $urandom;
    io_in_bits_uopIdx = $urandom;
    io_in_bits_uopSplitType = $urandom;
    io_in_bits_isVset = $urandom;
    io_in_bits_firstUop = $urandom;
    io_in_bits_lastUop = $urandom;
    io_in_bits_numWB = $urandom;
    io_in_bits_commitType = $urandom;
    io_out_ready = $urandom;
    io_rightOutFire = $urandom;
    io_isFlush = $urandom;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_in_ready) && (g_io_in_ready) !== (i_io_in_ready)) begin errors++; if (errors<=60) $display("[%0t] io_in_ready g=%h i=%h",$time,g_io_in_ready,i_io_in_ready); end checks++;
    if (!$isunknown(g_io_out_valid) && (g_io_out_valid) !== (i_io_out_valid)) begin errors++; if (errors<=60) $display("[%0t] io_out_valid g=%h i=%h",$time,g_io_out_valid,i_io_out_valid); end checks++;
    if (!$isunknown(g_io_out_bits_instr) && (g_io_out_bits_instr) !== (i_io_out_bits_instr)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_instr g=%h i=%h",$time,g_io_out_bits_instr,i_io_out_bits_instr); end checks++;
    if (!$isunknown(g_io_out_bits_foldpc) && (g_io_out_bits_foldpc) !== (i_io_out_bits_foldpc)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_foldpc g=%h i=%h",$time,g_io_out_bits_foldpc,i_io_out_bits_foldpc); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_0) && (g_io_out_bits_exceptionVec_0) !== (i_io_out_bits_exceptionVec_0)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_0 g=%h i=%h",$time,g_io_out_bits_exceptionVec_0,i_io_out_bits_exceptionVec_0); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_1) && (g_io_out_bits_exceptionVec_1) !== (i_io_out_bits_exceptionVec_1)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_1 g=%h i=%h",$time,g_io_out_bits_exceptionVec_1,i_io_out_bits_exceptionVec_1); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_2) && (g_io_out_bits_exceptionVec_2) !== (i_io_out_bits_exceptionVec_2)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_2 g=%h i=%h",$time,g_io_out_bits_exceptionVec_2,i_io_out_bits_exceptionVec_2); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_3) && (g_io_out_bits_exceptionVec_3) !== (i_io_out_bits_exceptionVec_3)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_3 g=%h i=%h",$time,g_io_out_bits_exceptionVec_3,i_io_out_bits_exceptionVec_3); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_4) && (g_io_out_bits_exceptionVec_4) !== (i_io_out_bits_exceptionVec_4)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_4 g=%h i=%h",$time,g_io_out_bits_exceptionVec_4,i_io_out_bits_exceptionVec_4); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_5) && (g_io_out_bits_exceptionVec_5) !== (i_io_out_bits_exceptionVec_5)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_5 g=%h i=%h",$time,g_io_out_bits_exceptionVec_5,i_io_out_bits_exceptionVec_5); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_6) && (g_io_out_bits_exceptionVec_6) !== (i_io_out_bits_exceptionVec_6)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_6 g=%h i=%h",$time,g_io_out_bits_exceptionVec_6,i_io_out_bits_exceptionVec_6); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_7) && (g_io_out_bits_exceptionVec_7) !== (i_io_out_bits_exceptionVec_7)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_7 g=%h i=%h",$time,g_io_out_bits_exceptionVec_7,i_io_out_bits_exceptionVec_7); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_8) && (g_io_out_bits_exceptionVec_8) !== (i_io_out_bits_exceptionVec_8)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_8 g=%h i=%h",$time,g_io_out_bits_exceptionVec_8,i_io_out_bits_exceptionVec_8); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_9) && (g_io_out_bits_exceptionVec_9) !== (i_io_out_bits_exceptionVec_9)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_9 g=%h i=%h",$time,g_io_out_bits_exceptionVec_9,i_io_out_bits_exceptionVec_9); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_10) && (g_io_out_bits_exceptionVec_10) !== (i_io_out_bits_exceptionVec_10)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_10 g=%h i=%h",$time,g_io_out_bits_exceptionVec_10,i_io_out_bits_exceptionVec_10); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_11) && (g_io_out_bits_exceptionVec_11) !== (i_io_out_bits_exceptionVec_11)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_11 g=%h i=%h",$time,g_io_out_bits_exceptionVec_11,i_io_out_bits_exceptionVec_11); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_12) && (g_io_out_bits_exceptionVec_12) !== (i_io_out_bits_exceptionVec_12)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_12 g=%h i=%h",$time,g_io_out_bits_exceptionVec_12,i_io_out_bits_exceptionVec_12); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_13) && (g_io_out_bits_exceptionVec_13) !== (i_io_out_bits_exceptionVec_13)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_13 g=%h i=%h",$time,g_io_out_bits_exceptionVec_13,i_io_out_bits_exceptionVec_13); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_14) && (g_io_out_bits_exceptionVec_14) !== (i_io_out_bits_exceptionVec_14)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_14 g=%h i=%h",$time,g_io_out_bits_exceptionVec_14,i_io_out_bits_exceptionVec_14); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_15) && (g_io_out_bits_exceptionVec_15) !== (i_io_out_bits_exceptionVec_15)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_15 g=%h i=%h",$time,g_io_out_bits_exceptionVec_15,i_io_out_bits_exceptionVec_15); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_16) && (g_io_out_bits_exceptionVec_16) !== (i_io_out_bits_exceptionVec_16)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_16 g=%h i=%h",$time,g_io_out_bits_exceptionVec_16,i_io_out_bits_exceptionVec_16); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_17) && (g_io_out_bits_exceptionVec_17) !== (i_io_out_bits_exceptionVec_17)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_17 g=%h i=%h",$time,g_io_out_bits_exceptionVec_17,i_io_out_bits_exceptionVec_17); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_18) && (g_io_out_bits_exceptionVec_18) !== (i_io_out_bits_exceptionVec_18)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_18 g=%h i=%h",$time,g_io_out_bits_exceptionVec_18,i_io_out_bits_exceptionVec_18); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_19) && (g_io_out_bits_exceptionVec_19) !== (i_io_out_bits_exceptionVec_19)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_19 g=%h i=%h",$time,g_io_out_bits_exceptionVec_19,i_io_out_bits_exceptionVec_19); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_20) && (g_io_out_bits_exceptionVec_20) !== (i_io_out_bits_exceptionVec_20)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_20 g=%h i=%h",$time,g_io_out_bits_exceptionVec_20,i_io_out_bits_exceptionVec_20); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_21) && (g_io_out_bits_exceptionVec_21) !== (i_io_out_bits_exceptionVec_21)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_21 g=%h i=%h",$time,g_io_out_bits_exceptionVec_21,i_io_out_bits_exceptionVec_21); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_22) && (g_io_out_bits_exceptionVec_22) !== (i_io_out_bits_exceptionVec_22)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_22 g=%h i=%h",$time,g_io_out_bits_exceptionVec_22,i_io_out_bits_exceptionVec_22); end checks++;
    if (!$isunknown(g_io_out_bits_exceptionVec_23) && (g_io_out_bits_exceptionVec_23) !== (i_io_out_bits_exceptionVec_23)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_exceptionVec_23 g=%h i=%h",$time,g_io_out_bits_exceptionVec_23,i_io_out_bits_exceptionVec_23); end checks++;
    if (!$isunknown(g_io_out_bits_isFetchMalAddr) && (g_io_out_bits_isFetchMalAddr) !== (i_io_out_bits_isFetchMalAddr)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_isFetchMalAddr g=%h i=%h",$time,g_io_out_bits_isFetchMalAddr,i_io_out_bits_isFetchMalAddr); end checks++;
    if (!$isunknown(g_io_out_bits_trigger) && (g_io_out_bits_trigger) !== (i_io_out_bits_trigger)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_trigger g=%h i=%h",$time,g_io_out_bits_trigger,i_io_out_bits_trigger); end checks++;
    if (!$isunknown(g_io_out_bits_preDecodeInfo_isRVC) && (g_io_out_bits_preDecodeInfo_isRVC) !== (i_io_out_bits_preDecodeInfo_isRVC)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_preDecodeInfo_isRVC g=%h i=%h",$time,g_io_out_bits_preDecodeInfo_isRVC,i_io_out_bits_preDecodeInfo_isRVC); end checks++;
    if (!$isunknown(g_io_out_bits_preDecodeInfo_brType) && (g_io_out_bits_preDecodeInfo_brType) !== (i_io_out_bits_preDecodeInfo_brType)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_preDecodeInfo_brType g=%h i=%h",$time,g_io_out_bits_preDecodeInfo_brType,i_io_out_bits_preDecodeInfo_brType); end checks++;
    if (!$isunknown(g_io_out_bits_pred_taken) && (g_io_out_bits_pred_taken) !== (i_io_out_bits_pred_taken)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_pred_taken g=%h i=%h",$time,g_io_out_bits_pred_taken,i_io_out_bits_pred_taken); end checks++;
    if (!$isunknown(g_io_out_bits_crossPageIPFFix) && (g_io_out_bits_crossPageIPFFix) !== (i_io_out_bits_crossPageIPFFix)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_crossPageIPFFix g=%h i=%h",$time,g_io_out_bits_crossPageIPFFix,i_io_out_bits_crossPageIPFFix); end checks++;
    if (!$isunknown(g_io_out_bits_ftqPtr_flag) && (g_io_out_bits_ftqPtr_flag) !== (i_io_out_bits_ftqPtr_flag)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_ftqPtr_flag g=%h i=%h",$time,g_io_out_bits_ftqPtr_flag,i_io_out_bits_ftqPtr_flag); end checks++;
    if (!$isunknown(g_io_out_bits_ftqPtr_value) && (g_io_out_bits_ftqPtr_value) !== (i_io_out_bits_ftqPtr_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_ftqPtr_value g=%h i=%h",$time,g_io_out_bits_ftqPtr_value,i_io_out_bits_ftqPtr_value); end checks++;
    if (!$isunknown(g_io_out_bits_ftqOffset) && (g_io_out_bits_ftqOffset) !== (i_io_out_bits_ftqOffset)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_ftqOffset g=%h i=%h",$time,g_io_out_bits_ftqOffset,i_io_out_bits_ftqOffset); end checks++;
    if (!$isunknown(g_io_out_bits_srcType_0) && (g_io_out_bits_srcType_0) !== (i_io_out_bits_srcType_0)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_srcType_0 g=%h i=%h",$time,g_io_out_bits_srcType_0,i_io_out_bits_srcType_0); end checks++;
    if (!$isunknown(g_io_out_bits_srcType_1) && (g_io_out_bits_srcType_1) !== (i_io_out_bits_srcType_1)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_srcType_1 g=%h i=%h",$time,g_io_out_bits_srcType_1,i_io_out_bits_srcType_1); end checks++;
    if (!$isunknown(g_io_out_bits_srcType_2) && (g_io_out_bits_srcType_2) !== (i_io_out_bits_srcType_2)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_srcType_2 g=%h i=%h",$time,g_io_out_bits_srcType_2,i_io_out_bits_srcType_2); end checks++;
    if (!$isunknown(g_io_out_bits_srcType_3) && (g_io_out_bits_srcType_3) !== (i_io_out_bits_srcType_3)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_srcType_3 g=%h i=%h",$time,g_io_out_bits_srcType_3,i_io_out_bits_srcType_3); end checks++;
    if (!$isunknown(g_io_out_bits_srcType_4) && (g_io_out_bits_srcType_4) !== (i_io_out_bits_srcType_4)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_srcType_4 g=%h i=%h",$time,g_io_out_bits_srcType_4,i_io_out_bits_srcType_4); end checks++;
    if (!$isunknown(g_io_out_bits_lsrc_0) && (g_io_out_bits_lsrc_0) !== (i_io_out_bits_lsrc_0)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lsrc_0 g=%h i=%h",$time,g_io_out_bits_lsrc_0,i_io_out_bits_lsrc_0); end checks++;
    if (!$isunknown(g_io_out_bits_lsrc_1) && (g_io_out_bits_lsrc_1) !== (i_io_out_bits_lsrc_1)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lsrc_1 g=%h i=%h",$time,g_io_out_bits_lsrc_1,i_io_out_bits_lsrc_1); end checks++;
    if (!$isunknown(g_io_out_bits_lsrc_2) && (g_io_out_bits_lsrc_2) !== (i_io_out_bits_lsrc_2)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lsrc_2 g=%h i=%h",$time,g_io_out_bits_lsrc_2,i_io_out_bits_lsrc_2); end checks++;
    if (!$isunknown(g_io_out_bits_lsrc_3) && (g_io_out_bits_lsrc_3) !== (i_io_out_bits_lsrc_3)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lsrc_3 g=%h i=%h",$time,g_io_out_bits_lsrc_3,i_io_out_bits_lsrc_3); end checks++;
    if (!$isunknown(g_io_out_bits_lsrc_4) && (g_io_out_bits_lsrc_4) !== (i_io_out_bits_lsrc_4)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lsrc_4 g=%h i=%h",$time,g_io_out_bits_lsrc_4,i_io_out_bits_lsrc_4); end checks++;
    if (!$isunknown(g_io_out_bits_ldest) && (g_io_out_bits_ldest) !== (i_io_out_bits_ldest)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_ldest g=%h i=%h",$time,g_io_out_bits_ldest,i_io_out_bits_ldest); end checks++;
    if (!$isunknown(g_io_out_bits_fuType) && (g_io_out_bits_fuType) !== (i_io_out_bits_fuType)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fuType g=%h i=%h",$time,g_io_out_bits_fuType,i_io_out_bits_fuType); end checks++;
    if (!$isunknown(g_io_out_bits_fuOpType) && (g_io_out_bits_fuOpType) !== (i_io_out_bits_fuOpType)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fuOpType g=%h i=%h",$time,g_io_out_bits_fuOpType,i_io_out_bits_fuOpType); end checks++;
    if (!$isunknown(g_io_out_bits_rfWen) && (g_io_out_bits_rfWen) !== (i_io_out_bits_rfWen)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_rfWen g=%h i=%h",$time,g_io_out_bits_rfWen,i_io_out_bits_rfWen); end checks++;
    if (!$isunknown(g_io_out_bits_fpWen) && (g_io_out_bits_fpWen) !== (i_io_out_bits_fpWen)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpWen g=%h i=%h",$time,g_io_out_bits_fpWen,i_io_out_bits_fpWen); end checks++;
    if (!$isunknown(g_io_out_bits_vecWen) && (g_io_out_bits_vecWen) !== (i_io_out_bits_vecWen)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vecWen g=%h i=%h",$time,g_io_out_bits_vecWen,i_io_out_bits_vecWen); end checks++;
    if (!$isunknown(g_io_out_bits_v0Wen) && (g_io_out_bits_v0Wen) !== (i_io_out_bits_v0Wen)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_v0Wen g=%h i=%h",$time,g_io_out_bits_v0Wen,i_io_out_bits_v0Wen); end checks++;
    if (!$isunknown(g_io_out_bits_vlWen) && (g_io_out_bits_vlWen) !== (i_io_out_bits_vlWen)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vlWen g=%h i=%h",$time,g_io_out_bits_vlWen,i_io_out_bits_vlWen); end checks++;
    if (!$isunknown(g_io_out_bits_isXSTrap) && (g_io_out_bits_isXSTrap) !== (i_io_out_bits_isXSTrap)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_isXSTrap g=%h i=%h",$time,g_io_out_bits_isXSTrap,i_io_out_bits_isXSTrap); end checks++;
    if (!$isunknown(g_io_out_bits_waitForward) && (g_io_out_bits_waitForward) !== (i_io_out_bits_waitForward)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_waitForward g=%h i=%h",$time,g_io_out_bits_waitForward,i_io_out_bits_waitForward); end checks++;
    if (!$isunknown(g_io_out_bits_blockBackward) && (g_io_out_bits_blockBackward) !== (i_io_out_bits_blockBackward)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_blockBackward g=%h i=%h",$time,g_io_out_bits_blockBackward,i_io_out_bits_blockBackward); end checks++;
    if (!$isunknown(g_io_out_bits_flushPipe) && (g_io_out_bits_flushPipe) !== (i_io_out_bits_flushPipe)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_flushPipe g=%h i=%h",$time,g_io_out_bits_flushPipe,i_io_out_bits_flushPipe); end checks++;
    if (!$isunknown(g_io_out_bits_canRobCompress) && (g_io_out_bits_canRobCompress) !== (i_io_out_bits_canRobCompress)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_canRobCompress g=%h i=%h",$time,g_io_out_bits_canRobCompress,i_io_out_bits_canRobCompress); end checks++;
    if (!$isunknown(g_io_out_bits_selImm) && (g_io_out_bits_selImm) !== (i_io_out_bits_selImm)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_selImm g=%h i=%h",$time,g_io_out_bits_selImm,i_io_out_bits_selImm); end checks++;
    if (!$isunknown(g_io_out_bits_imm) && (g_io_out_bits_imm) !== (i_io_out_bits_imm)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_imm g=%h i=%h",$time,g_io_out_bits_imm,i_io_out_bits_imm); end checks++;
    if (!$isunknown(g_io_out_bits_fpu_typeTagOut) && (g_io_out_bits_fpu_typeTagOut) !== (i_io_out_bits_fpu_typeTagOut)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpu_typeTagOut g=%h i=%h",$time,g_io_out_bits_fpu_typeTagOut,i_io_out_bits_fpu_typeTagOut); end checks++;
    if (!$isunknown(g_io_out_bits_fpu_wflags) && (g_io_out_bits_fpu_wflags) !== (i_io_out_bits_fpu_wflags)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpu_wflags g=%h i=%h",$time,g_io_out_bits_fpu_wflags,i_io_out_bits_fpu_wflags); end checks++;
    if (!$isunknown(g_io_out_bits_fpu_typ) && (g_io_out_bits_fpu_typ) !== (i_io_out_bits_fpu_typ)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpu_typ g=%h i=%h",$time,g_io_out_bits_fpu_typ,i_io_out_bits_fpu_typ); end checks++;
    if (!$isunknown(g_io_out_bits_fpu_fmt) && (g_io_out_bits_fpu_fmt) !== (i_io_out_bits_fpu_fmt)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpu_fmt g=%h i=%h",$time,g_io_out_bits_fpu_fmt,i_io_out_bits_fpu_fmt); end checks++;
    if (!$isunknown(g_io_out_bits_fpu_rm) && (g_io_out_bits_fpu_rm) !== (i_io_out_bits_fpu_rm)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_fpu_rm g=%h i=%h",$time,g_io_out_bits_fpu_rm,i_io_out_bits_fpu_rm); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vill) && (g_io_out_bits_vpu_vill) !== (i_io_out_bits_vpu_vill)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vill g=%h i=%h",$time,g_io_out_bits_vpu_vill,i_io_out_bits_vpu_vill); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vma) && (g_io_out_bits_vpu_vma) !== (i_io_out_bits_vpu_vma)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vma g=%h i=%h",$time,g_io_out_bits_vpu_vma,i_io_out_bits_vpu_vma); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vta) && (g_io_out_bits_vpu_vta) !== (i_io_out_bits_vpu_vta)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vta g=%h i=%h",$time,g_io_out_bits_vpu_vta,i_io_out_bits_vpu_vta); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vsew) && (g_io_out_bits_vpu_vsew) !== (i_io_out_bits_vpu_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vsew g=%h i=%h",$time,g_io_out_bits_vpu_vsew,i_io_out_bits_vpu_vsew); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vlmul) && (g_io_out_bits_vpu_vlmul) !== (i_io_out_bits_vpu_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vlmul g=%h i=%h",$time,g_io_out_bits_vpu_vlmul,i_io_out_bits_vpu_vlmul); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_specVill) && (g_io_out_bits_vpu_specVill) !== (i_io_out_bits_vpu_specVill)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_specVill g=%h i=%h",$time,g_io_out_bits_vpu_specVill,i_io_out_bits_vpu_specVill); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_specVma) && (g_io_out_bits_vpu_specVma) !== (i_io_out_bits_vpu_specVma)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_specVma g=%h i=%h",$time,g_io_out_bits_vpu_specVma,i_io_out_bits_vpu_specVma); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_specVta) && (g_io_out_bits_vpu_specVta) !== (i_io_out_bits_vpu_specVta)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_specVta g=%h i=%h",$time,g_io_out_bits_vpu_specVta,i_io_out_bits_vpu_specVta); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_specVsew) && (g_io_out_bits_vpu_specVsew) !== (i_io_out_bits_vpu_specVsew)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_specVsew g=%h i=%h",$time,g_io_out_bits_vpu_specVsew,i_io_out_bits_vpu_specVsew); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_specVlmul) && (g_io_out_bits_vpu_specVlmul) !== (i_io_out_bits_vpu_specVlmul)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_specVlmul g=%h i=%h",$time,g_io_out_bits_vpu_specVlmul,i_io_out_bits_vpu_specVlmul); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vm) && (g_io_out_bits_vpu_vm) !== (i_io_out_bits_vpu_vm)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vm g=%h i=%h",$time,g_io_out_bits_vpu_vm,i_io_out_bits_vpu_vm); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vstart) && (g_io_out_bits_vpu_vstart) !== (i_io_out_bits_vpu_vstart)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vstart g=%h i=%h",$time,g_io_out_bits_vpu_vstart,i_io_out_bits_vpu_vstart); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_fpu_isFoldTo1_2) && (g_io_out_bits_vpu_fpu_isFoldTo1_2) !== (i_io_out_bits_vpu_fpu_isFoldTo1_2)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_fpu_isFoldTo1_2 g=%h i=%h",$time,g_io_out_bits_vpu_fpu_isFoldTo1_2,i_io_out_bits_vpu_fpu_isFoldTo1_2); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_fpu_isFoldTo1_4) && (g_io_out_bits_vpu_fpu_isFoldTo1_4) !== (i_io_out_bits_vpu_fpu_isFoldTo1_4)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_fpu_isFoldTo1_4 g=%h i=%h",$time,g_io_out_bits_vpu_fpu_isFoldTo1_4,i_io_out_bits_vpu_fpu_isFoldTo1_4); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_fpu_isFoldTo1_8) && (g_io_out_bits_vpu_fpu_isFoldTo1_8) !== (i_io_out_bits_vpu_fpu_isFoldTo1_8)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_fpu_isFoldTo1_8 g=%h i=%h",$time,g_io_out_bits_vpu_fpu_isFoldTo1_8,i_io_out_bits_vpu_fpu_isFoldTo1_8); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_vmask) && (g_io_out_bits_vpu_vmask) !== (i_io_out_bits_vpu_vmask)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_vmask g=%h i=%h",$time,g_io_out_bits_vpu_vmask,i_io_out_bits_vpu_vmask); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_nf) && (g_io_out_bits_vpu_nf) !== (i_io_out_bits_vpu_nf)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_nf g=%h i=%h",$time,g_io_out_bits_vpu_nf,i_io_out_bits_vpu_nf); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_veew) && (g_io_out_bits_vpu_veew) !== (i_io_out_bits_vpu_veew)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_veew g=%h i=%h",$time,g_io_out_bits_vpu_veew,i_io_out_bits_vpu_veew); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isExt) && (g_io_out_bits_vpu_isExt) !== (i_io_out_bits_vpu_isExt)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isExt g=%h i=%h",$time,g_io_out_bits_vpu_isExt,i_io_out_bits_vpu_isExt); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isNarrow) && (g_io_out_bits_vpu_isNarrow) !== (i_io_out_bits_vpu_isNarrow)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isNarrow g=%h i=%h",$time,g_io_out_bits_vpu_isNarrow,i_io_out_bits_vpu_isNarrow); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isDstMask) && (g_io_out_bits_vpu_isDstMask) !== (i_io_out_bits_vpu_isDstMask)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isDstMask g=%h i=%h",$time,g_io_out_bits_vpu_isDstMask,i_io_out_bits_vpu_isDstMask); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isOpMask) && (g_io_out_bits_vpu_isOpMask) !== (i_io_out_bits_vpu_isOpMask)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isOpMask g=%h i=%h",$time,g_io_out_bits_vpu_isOpMask,i_io_out_bits_vpu_isOpMask); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isDependOldVd) && (g_io_out_bits_vpu_isDependOldVd) !== (i_io_out_bits_vpu_isDependOldVd)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isDependOldVd g=%h i=%h",$time,g_io_out_bits_vpu_isDependOldVd,i_io_out_bits_vpu_isDependOldVd); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isWritePartVd) && (g_io_out_bits_vpu_isWritePartVd) !== (i_io_out_bits_vpu_isWritePartVd)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isWritePartVd g=%h i=%h",$time,g_io_out_bits_vpu_isWritePartVd,i_io_out_bits_vpu_isWritePartVd); end checks++;
    if (!$isunknown(g_io_out_bits_vpu_isVleff) && (g_io_out_bits_vpu_isVleff) !== (i_io_out_bits_vpu_isVleff)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vpu_isVleff g=%h i=%h",$time,g_io_out_bits_vpu_isVleff,i_io_out_bits_vpu_isVleff); end checks++;
    if (!$isunknown(g_io_out_bits_vlsInstr) && (g_io_out_bits_vlsInstr) !== (i_io_out_bits_vlsInstr)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_vlsInstr g=%h i=%h",$time,g_io_out_bits_vlsInstr,i_io_out_bits_vlsInstr); end checks++;
    if (!$isunknown(g_io_out_bits_wfflags) && (g_io_out_bits_wfflags) !== (i_io_out_bits_wfflags)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_wfflags g=%h i=%h",$time,g_io_out_bits_wfflags,i_io_out_bits_wfflags); end checks++;
    if (!$isunknown(g_io_out_bits_isMove) && (g_io_out_bits_isMove) !== (i_io_out_bits_isMove)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_isMove g=%h i=%h",$time,g_io_out_bits_isMove,i_io_out_bits_isMove); end checks++;
    if (!$isunknown(g_io_out_bits_uopIdx) && (g_io_out_bits_uopIdx) !== (i_io_out_bits_uopIdx)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_uopIdx g=%h i=%h",$time,g_io_out_bits_uopIdx,i_io_out_bits_uopIdx); end checks++;
    if (!$isunknown(g_io_out_bits_uopSplitType) && (g_io_out_bits_uopSplitType) !== (i_io_out_bits_uopSplitType)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_uopSplitType g=%h i=%h",$time,g_io_out_bits_uopSplitType,i_io_out_bits_uopSplitType); end checks++;
    if (!$isunknown(g_io_out_bits_isVset) && (g_io_out_bits_isVset) !== (i_io_out_bits_isVset)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_isVset g=%h i=%h",$time,g_io_out_bits_isVset,i_io_out_bits_isVset); end checks++;
    if (!$isunknown(g_io_out_bits_firstUop) && (g_io_out_bits_firstUop) !== (i_io_out_bits_firstUop)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_firstUop g=%h i=%h",$time,g_io_out_bits_firstUop,i_io_out_bits_firstUop); end checks++;
    if (!$isunknown(g_io_out_bits_lastUop) && (g_io_out_bits_lastUop) !== (i_io_out_bits_lastUop)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_lastUop g=%h i=%h",$time,g_io_out_bits_lastUop,i_io_out_bits_lastUop); end checks++;
    if (!$isunknown(g_io_out_bits_numWB) && (g_io_out_bits_numWB) !== (i_io_out_bits_numWB)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_numWB g=%h i=%h",$time,g_io_out_bits_numWB,i_io_out_bits_numWB); end checks++;
    if (!$isunknown(g_io_out_bits_commitType) && (g_io_out_bits_commitType) !== (i_io_out_bits_commitType)) begin errors++; if (errors<=60) $display("[%0t] io_out_bits_commitType g=%h i=%h",$time,g_io_out_bits_commitType,i_io_out_bits_commitType); end checks++;
  endtask

  initial begin
    drive_inputs();
    reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
