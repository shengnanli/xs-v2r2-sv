// 自动生成：scripts/gen_rename.py —— 勿手改

// golden 同名扁平端口 → 可读核 xs_Rename_core 的机械适配层。
// 1579 端口的拆装全在这里完成；核内只见 struct/数组。
module Rename
  import rename_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0] io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_redirect_bits_debugIsCtrl,
  input         io_redirect_bits_debugIsMemVio,
  input         io_rabCommits_isCommit,
  input         io_rabCommits_commitValid_0,
  input         io_rabCommits_commitValid_1,
  input         io_rabCommits_commitValid_2,
  input         io_rabCommits_commitValid_3,
  input         io_rabCommits_commitValid_4,
  input         io_rabCommits_commitValid_5,
  input         io_rabCommits_isWalk,
  input         io_rabCommits_walkValid_0,
  input         io_rabCommits_walkValid_1,
  input         io_rabCommits_walkValid_2,
  input         io_rabCommits_walkValid_3,
  input         io_rabCommits_walkValid_4,
  input         io_rabCommits_walkValid_5,
  input         io_rabCommits_info_0_rfWen,
  input         io_rabCommits_info_0_fpWen,
  input         io_rabCommits_info_0_vecWen,
  input         io_rabCommits_info_0_v0Wen,
  input         io_rabCommits_info_0_vlWen,
  input         io_rabCommits_info_0_isMove,
  input         io_rabCommits_info_1_rfWen,
  input         io_rabCommits_info_1_fpWen,
  input         io_rabCommits_info_1_vecWen,
  input         io_rabCommits_info_1_v0Wen,
  input         io_rabCommits_info_1_vlWen,
  input         io_rabCommits_info_1_isMove,
  input         io_rabCommits_info_2_rfWen,
  input         io_rabCommits_info_2_fpWen,
  input         io_rabCommits_info_2_vecWen,
  input         io_rabCommits_info_2_v0Wen,
  input         io_rabCommits_info_2_vlWen,
  input         io_rabCommits_info_2_isMove,
  input         io_rabCommits_info_3_rfWen,
  input         io_rabCommits_info_3_fpWen,
  input         io_rabCommits_info_3_vecWen,
  input         io_rabCommits_info_3_v0Wen,
  input         io_rabCommits_info_3_vlWen,
  input         io_rabCommits_info_3_isMove,
  input         io_rabCommits_info_4_rfWen,
  input         io_rabCommits_info_4_fpWen,
  input         io_rabCommits_info_4_vecWen,
  input         io_rabCommits_info_4_v0Wen,
  input         io_rabCommits_info_4_vlWen,
  input         io_rabCommits_info_4_isMove,
  input         io_rabCommits_info_5_rfWen,
  input         io_rabCommits_info_5_fpWen,
  input         io_rabCommits_info_5_vecWen,
  input         io_rabCommits_info_5_v0Wen,
  input         io_rabCommits_info_5_vlWen,
  input         io_rabCommits_info_5_isMove,
  input         io_singleStep,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits_instr,
  input         io_in_0_bits_exceptionVec_0,
  input         io_in_0_bits_exceptionVec_1,
  input         io_in_0_bits_exceptionVec_2,
  input         io_in_0_bits_exceptionVec_3,
  input         io_in_0_bits_exceptionVec_4,
  input         io_in_0_bits_exceptionVec_5,
  input         io_in_0_bits_exceptionVec_6,
  input         io_in_0_bits_exceptionVec_7,
  input         io_in_0_bits_exceptionVec_8,
  input         io_in_0_bits_exceptionVec_9,
  input         io_in_0_bits_exceptionVec_10,
  input         io_in_0_bits_exceptionVec_11,
  input         io_in_0_bits_exceptionVec_12,
  input         io_in_0_bits_exceptionVec_13,
  input         io_in_0_bits_exceptionVec_14,
  input         io_in_0_bits_exceptionVec_15,
  input         io_in_0_bits_exceptionVec_16,
  input         io_in_0_bits_exceptionVec_17,
  input         io_in_0_bits_exceptionVec_18,
  input         io_in_0_bits_exceptionVec_19,
  input         io_in_0_bits_exceptionVec_20,
  input         io_in_0_bits_exceptionVec_21,
  input         io_in_0_bits_exceptionVec_22,
  input         io_in_0_bits_exceptionVec_23,
  input         io_in_0_bits_isFetchMalAddr,
  input  [3:0] io_in_0_bits_trigger,
  input         io_in_0_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_0_bits_preDecodeInfo_brType,
  input         io_in_0_bits_pred_taken,
  input         io_in_0_bits_crossPageIPFFix,
  input         io_in_0_bits_ftqPtr_flag,
  input  [5:0] io_in_0_bits_ftqPtr_value,
  input  [3:0] io_in_0_bits_ftqOffset,
  input  [3:0] io_in_0_bits_srcType_0,
  input  [3:0] io_in_0_bits_srcType_1,
  input  [3:0] io_in_0_bits_srcType_2,
  input  [3:0] io_in_0_bits_srcType_3,
  input  [3:0] io_in_0_bits_srcType_4,
  input  [5:0] io_in_0_bits_lsrc_0,
  input  [5:0] io_in_0_bits_lsrc_1,
  input  [5:0] io_in_0_bits_ldest,
  input  [34:0] io_in_0_bits_fuType,
  input  [8:0] io_in_0_bits_fuOpType,
  input         io_in_0_bits_rfWen,
  input         io_in_0_bits_fpWen,
  input         io_in_0_bits_vecWen,
  input         io_in_0_bits_v0Wen,
  input         io_in_0_bits_vlWen,
  input         io_in_0_bits_isXSTrap,
  input         io_in_0_bits_waitForward,
  input         io_in_0_bits_blockBackward,
  input         io_in_0_bits_flushPipe,
  input         io_in_0_bits_canRobCompress,
  input  [3:0] io_in_0_bits_selImm,
  input  [21:0] io_in_0_bits_imm,
  input  [1:0] io_in_0_bits_fpu_typeTagOut,
  input         io_in_0_bits_fpu_wflags,
  input  [1:0] io_in_0_bits_fpu_typ,
  input  [1:0] io_in_0_bits_fpu_fmt,
  input  [2:0] io_in_0_bits_fpu_rm,
  input         io_in_0_bits_vpu_vill,
  input         io_in_0_bits_vpu_vma,
  input         io_in_0_bits_vpu_vta,
  input  [1:0] io_in_0_bits_vpu_vsew,
  input  [2:0] io_in_0_bits_vpu_vlmul,
  input         io_in_0_bits_vpu_specVill,
  input         io_in_0_bits_vpu_specVma,
  input         io_in_0_bits_vpu_specVta,
  input  [1:0] io_in_0_bits_vpu_specVsew,
  input  [2:0] io_in_0_bits_vpu_specVlmul,
  input         io_in_0_bits_vpu_vm,
  input  [7:0] io_in_0_bits_vpu_vstart,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_0_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_0_bits_vpu_vmask,
  input  [2:0] io_in_0_bits_vpu_nf,
  input  [1:0] io_in_0_bits_vpu_veew,
  input         io_in_0_bits_vpu_isExt,
  input         io_in_0_bits_vpu_isNarrow,
  input         io_in_0_bits_vpu_isDstMask,
  input         io_in_0_bits_vpu_isOpMask,
  input         io_in_0_bits_vpu_isDependOldVd,
  input         io_in_0_bits_vpu_isWritePartVd,
  input         io_in_0_bits_vpu_isVleff,
  input         io_in_0_bits_vlsInstr,
  input         io_in_0_bits_wfflags,
  input         io_in_0_bits_isMove,
  input  [6:0] io_in_0_bits_uopIdx,
  input  [5:0] io_in_0_bits_uopSplitType,
  input         io_in_0_bits_isVset,
  input         io_in_0_bits_firstUop,
  input         io_in_0_bits_lastUop,
  input  [6:0] io_in_0_bits_numWB,
  input  [2:0] io_in_0_bits_commitType,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits_instr,
  input         io_in_1_bits_exceptionVec_0,
  input         io_in_1_bits_exceptionVec_1,
  input         io_in_1_bits_exceptionVec_2,
  input         io_in_1_bits_exceptionVec_3,
  input         io_in_1_bits_exceptionVec_4,
  input         io_in_1_bits_exceptionVec_5,
  input         io_in_1_bits_exceptionVec_6,
  input         io_in_1_bits_exceptionVec_7,
  input         io_in_1_bits_exceptionVec_8,
  input         io_in_1_bits_exceptionVec_9,
  input         io_in_1_bits_exceptionVec_10,
  input         io_in_1_bits_exceptionVec_11,
  input         io_in_1_bits_exceptionVec_12,
  input         io_in_1_bits_exceptionVec_13,
  input         io_in_1_bits_exceptionVec_14,
  input         io_in_1_bits_exceptionVec_15,
  input         io_in_1_bits_exceptionVec_16,
  input         io_in_1_bits_exceptionVec_17,
  input         io_in_1_bits_exceptionVec_18,
  input         io_in_1_bits_exceptionVec_19,
  input         io_in_1_bits_exceptionVec_20,
  input         io_in_1_bits_exceptionVec_21,
  input         io_in_1_bits_exceptionVec_22,
  input         io_in_1_bits_exceptionVec_23,
  input         io_in_1_bits_isFetchMalAddr,
  input  [3:0] io_in_1_bits_trigger,
  input         io_in_1_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_1_bits_preDecodeInfo_brType,
  input         io_in_1_bits_pred_taken,
  input         io_in_1_bits_crossPageIPFFix,
  input         io_in_1_bits_ftqPtr_flag,
  input  [5:0] io_in_1_bits_ftqPtr_value,
  input  [3:0] io_in_1_bits_ftqOffset,
  input  [3:0] io_in_1_bits_srcType_0,
  input  [3:0] io_in_1_bits_srcType_1,
  input  [3:0] io_in_1_bits_srcType_2,
  input  [3:0] io_in_1_bits_srcType_3,
  input  [3:0] io_in_1_bits_srcType_4,
  input  [5:0] io_in_1_bits_lsrc_0,
  input  [5:0] io_in_1_bits_lsrc_1,
  input  [5:0] io_in_1_bits_lsrc_2,
  input  [5:0] io_in_1_bits_lsrc_3,
  input  [5:0] io_in_1_bits_lsrc_4,
  input  [5:0] io_in_1_bits_ldest,
  input  [34:0] io_in_1_bits_fuType,
  input  [8:0] io_in_1_bits_fuOpType,
  input         io_in_1_bits_rfWen,
  input         io_in_1_bits_fpWen,
  input         io_in_1_bits_vecWen,
  input         io_in_1_bits_v0Wen,
  input         io_in_1_bits_vlWen,
  input         io_in_1_bits_isXSTrap,
  input         io_in_1_bits_waitForward,
  input         io_in_1_bits_blockBackward,
  input         io_in_1_bits_flushPipe,
  input         io_in_1_bits_canRobCompress,
  input  [3:0] io_in_1_bits_selImm,
  input  [21:0] io_in_1_bits_imm,
  input  [1:0] io_in_1_bits_fpu_typeTagOut,
  input         io_in_1_bits_fpu_wflags,
  input  [1:0] io_in_1_bits_fpu_typ,
  input  [1:0] io_in_1_bits_fpu_fmt,
  input  [2:0] io_in_1_bits_fpu_rm,
  input         io_in_1_bits_vpu_vill,
  input         io_in_1_bits_vpu_vma,
  input         io_in_1_bits_vpu_vta,
  input  [1:0] io_in_1_bits_vpu_vsew,
  input  [2:0] io_in_1_bits_vpu_vlmul,
  input         io_in_1_bits_vpu_specVill,
  input         io_in_1_bits_vpu_specVma,
  input         io_in_1_bits_vpu_specVta,
  input  [1:0] io_in_1_bits_vpu_specVsew,
  input  [2:0] io_in_1_bits_vpu_specVlmul,
  input         io_in_1_bits_vpu_vm,
  input  [7:0] io_in_1_bits_vpu_vstart,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_1_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_1_bits_vpu_vmask,
  input  [2:0] io_in_1_bits_vpu_nf,
  input  [1:0] io_in_1_bits_vpu_veew,
  input         io_in_1_bits_vpu_isExt,
  input         io_in_1_bits_vpu_isNarrow,
  input         io_in_1_bits_vpu_isDstMask,
  input         io_in_1_bits_vpu_isOpMask,
  input         io_in_1_bits_vpu_isDependOldVd,
  input         io_in_1_bits_vpu_isWritePartVd,
  input         io_in_1_bits_vpu_isVleff,
  input         io_in_1_bits_vlsInstr,
  input         io_in_1_bits_wfflags,
  input         io_in_1_bits_isMove,
  input  [6:0] io_in_1_bits_uopIdx,
  input  [5:0] io_in_1_bits_uopSplitType,
  input         io_in_1_bits_isVset,
  input         io_in_1_bits_firstUop,
  input         io_in_1_bits_lastUop,
  input  [6:0] io_in_1_bits_numWB,
  input  [2:0] io_in_1_bits_commitType,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [31:0] io_in_2_bits_instr,
  input         io_in_2_bits_exceptionVec_0,
  input         io_in_2_bits_exceptionVec_1,
  input         io_in_2_bits_exceptionVec_2,
  input         io_in_2_bits_exceptionVec_3,
  input         io_in_2_bits_exceptionVec_4,
  input         io_in_2_bits_exceptionVec_5,
  input         io_in_2_bits_exceptionVec_6,
  input         io_in_2_bits_exceptionVec_7,
  input         io_in_2_bits_exceptionVec_8,
  input         io_in_2_bits_exceptionVec_9,
  input         io_in_2_bits_exceptionVec_10,
  input         io_in_2_bits_exceptionVec_11,
  input         io_in_2_bits_exceptionVec_12,
  input         io_in_2_bits_exceptionVec_13,
  input         io_in_2_bits_exceptionVec_14,
  input         io_in_2_bits_exceptionVec_15,
  input         io_in_2_bits_exceptionVec_16,
  input         io_in_2_bits_exceptionVec_17,
  input         io_in_2_bits_exceptionVec_18,
  input         io_in_2_bits_exceptionVec_19,
  input         io_in_2_bits_exceptionVec_20,
  input         io_in_2_bits_exceptionVec_21,
  input         io_in_2_bits_exceptionVec_22,
  input         io_in_2_bits_exceptionVec_23,
  input         io_in_2_bits_isFetchMalAddr,
  input  [3:0] io_in_2_bits_trigger,
  input         io_in_2_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_2_bits_preDecodeInfo_brType,
  input         io_in_2_bits_pred_taken,
  input         io_in_2_bits_crossPageIPFFix,
  input         io_in_2_bits_ftqPtr_flag,
  input  [5:0] io_in_2_bits_ftqPtr_value,
  input  [3:0] io_in_2_bits_ftqOffset,
  input  [3:0] io_in_2_bits_srcType_0,
  input  [3:0] io_in_2_bits_srcType_1,
  input  [3:0] io_in_2_bits_srcType_2,
  input  [3:0] io_in_2_bits_srcType_3,
  input  [3:0] io_in_2_bits_srcType_4,
  input  [5:0] io_in_2_bits_lsrc_0,
  input  [5:0] io_in_2_bits_lsrc_1,
  input  [5:0] io_in_2_bits_lsrc_2,
  input  [5:0] io_in_2_bits_lsrc_3,
  input  [5:0] io_in_2_bits_lsrc_4,
  input  [5:0] io_in_2_bits_ldest,
  input  [34:0] io_in_2_bits_fuType,
  input  [8:0] io_in_2_bits_fuOpType,
  input         io_in_2_bits_rfWen,
  input         io_in_2_bits_fpWen,
  input         io_in_2_bits_vecWen,
  input         io_in_2_bits_v0Wen,
  input         io_in_2_bits_vlWen,
  input         io_in_2_bits_isXSTrap,
  input         io_in_2_bits_waitForward,
  input         io_in_2_bits_blockBackward,
  input         io_in_2_bits_flushPipe,
  input         io_in_2_bits_canRobCompress,
  input  [3:0] io_in_2_bits_selImm,
  input  [21:0] io_in_2_bits_imm,
  input  [1:0] io_in_2_bits_fpu_typeTagOut,
  input         io_in_2_bits_fpu_wflags,
  input  [1:0] io_in_2_bits_fpu_typ,
  input  [1:0] io_in_2_bits_fpu_fmt,
  input  [2:0] io_in_2_bits_fpu_rm,
  input         io_in_2_bits_vpu_vill,
  input         io_in_2_bits_vpu_vma,
  input         io_in_2_bits_vpu_vta,
  input  [1:0] io_in_2_bits_vpu_vsew,
  input  [2:0] io_in_2_bits_vpu_vlmul,
  input         io_in_2_bits_vpu_specVill,
  input         io_in_2_bits_vpu_specVma,
  input         io_in_2_bits_vpu_specVta,
  input  [1:0] io_in_2_bits_vpu_specVsew,
  input  [2:0] io_in_2_bits_vpu_specVlmul,
  input         io_in_2_bits_vpu_vm,
  input  [7:0] io_in_2_bits_vpu_vstart,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_2_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_2_bits_vpu_vmask,
  input  [2:0] io_in_2_bits_vpu_nf,
  input  [1:0] io_in_2_bits_vpu_veew,
  input         io_in_2_bits_vpu_isExt,
  input         io_in_2_bits_vpu_isNarrow,
  input         io_in_2_bits_vpu_isDstMask,
  input         io_in_2_bits_vpu_isOpMask,
  input         io_in_2_bits_vpu_isDependOldVd,
  input         io_in_2_bits_vpu_isWritePartVd,
  input         io_in_2_bits_vpu_isVleff,
  input         io_in_2_bits_vlsInstr,
  input         io_in_2_bits_wfflags,
  input         io_in_2_bits_isMove,
  input  [6:0] io_in_2_bits_uopIdx,
  input  [5:0] io_in_2_bits_uopSplitType,
  input         io_in_2_bits_isVset,
  input         io_in_2_bits_firstUop,
  input         io_in_2_bits_lastUop,
  input  [6:0] io_in_2_bits_numWB,
  input  [2:0] io_in_2_bits_commitType,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [31:0] io_in_3_bits_instr,
  input         io_in_3_bits_exceptionVec_0,
  input         io_in_3_bits_exceptionVec_1,
  input         io_in_3_bits_exceptionVec_2,
  input         io_in_3_bits_exceptionVec_3,
  input         io_in_3_bits_exceptionVec_4,
  input         io_in_3_bits_exceptionVec_5,
  input         io_in_3_bits_exceptionVec_6,
  input         io_in_3_bits_exceptionVec_7,
  input         io_in_3_bits_exceptionVec_8,
  input         io_in_3_bits_exceptionVec_9,
  input         io_in_3_bits_exceptionVec_10,
  input         io_in_3_bits_exceptionVec_11,
  input         io_in_3_bits_exceptionVec_12,
  input         io_in_3_bits_exceptionVec_13,
  input         io_in_3_bits_exceptionVec_14,
  input         io_in_3_bits_exceptionVec_15,
  input         io_in_3_bits_exceptionVec_16,
  input         io_in_3_bits_exceptionVec_17,
  input         io_in_3_bits_exceptionVec_18,
  input         io_in_3_bits_exceptionVec_19,
  input         io_in_3_bits_exceptionVec_20,
  input         io_in_3_bits_exceptionVec_21,
  input         io_in_3_bits_exceptionVec_22,
  input         io_in_3_bits_exceptionVec_23,
  input         io_in_3_bits_isFetchMalAddr,
  input  [3:0] io_in_3_bits_trigger,
  input         io_in_3_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_3_bits_preDecodeInfo_brType,
  input         io_in_3_bits_pred_taken,
  input         io_in_3_bits_crossPageIPFFix,
  input         io_in_3_bits_ftqPtr_flag,
  input  [5:0] io_in_3_bits_ftqPtr_value,
  input  [3:0] io_in_3_bits_ftqOffset,
  input  [3:0] io_in_3_bits_srcType_0,
  input  [3:0] io_in_3_bits_srcType_1,
  input  [3:0] io_in_3_bits_srcType_2,
  input  [3:0] io_in_3_bits_srcType_3,
  input  [3:0] io_in_3_bits_srcType_4,
  input  [5:0] io_in_3_bits_lsrc_0,
  input  [5:0] io_in_3_bits_lsrc_1,
  input  [5:0] io_in_3_bits_lsrc_2,
  input  [5:0] io_in_3_bits_lsrc_3,
  input  [5:0] io_in_3_bits_lsrc_4,
  input  [5:0] io_in_3_bits_ldest,
  input  [34:0] io_in_3_bits_fuType,
  input  [8:0] io_in_3_bits_fuOpType,
  input         io_in_3_bits_rfWen,
  input         io_in_3_bits_fpWen,
  input         io_in_3_bits_vecWen,
  input         io_in_3_bits_v0Wen,
  input         io_in_3_bits_vlWen,
  input         io_in_3_bits_isXSTrap,
  input         io_in_3_bits_waitForward,
  input         io_in_3_bits_blockBackward,
  input         io_in_3_bits_flushPipe,
  input         io_in_3_bits_canRobCompress,
  input  [3:0] io_in_3_bits_selImm,
  input  [21:0] io_in_3_bits_imm,
  input  [1:0] io_in_3_bits_fpu_typeTagOut,
  input         io_in_3_bits_fpu_wflags,
  input  [1:0] io_in_3_bits_fpu_typ,
  input  [1:0] io_in_3_bits_fpu_fmt,
  input  [2:0] io_in_3_bits_fpu_rm,
  input         io_in_3_bits_vpu_vill,
  input         io_in_3_bits_vpu_vma,
  input         io_in_3_bits_vpu_vta,
  input  [1:0] io_in_3_bits_vpu_vsew,
  input  [2:0] io_in_3_bits_vpu_vlmul,
  input         io_in_3_bits_vpu_specVill,
  input         io_in_3_bits_vpu_specVma,
  input         io_in_3_bits_vpu_specVta,
  input  [1:0] io_in_3_bits_vpu_specVsew,
  input  [2:0] io_in_3_bits_vpu_specVlmul,
  input         io_in_3_bits_vpu_vm,
  input  [7:0] io_in_3_bits_vpu_vstart,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_3_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_3_bits_vpu_vmask,
  input  [2:0] io_in_3_bits_vpu_nf,
  input  [1:0] io_in_3_bits_vpu_veew,
  input         io_in_3_bits_vpu_isExt,
  input         io_in_3_bits_vpu_isNarrow,
  input         io_in_3_bits_vpu_isDstMask,
  input         io_in_3_bits_vpu_isOpMask,
  input         io_in_3_bits_vpu_isDependOldVd,
  input         io_in_3_bits_vpu_isWritePartVd,
  input         io_in_3_bits_vpu_isVleff,
  input         io_in_3_bits_vlsInstr,
  input         io_in_3_bits_wfflags,
  input         io_in_3_bits_isMove,
  input  [6:0] io_in_3_bits_uopIdx,
  input  [5:0] io_in_3_bits_uopSplitType,
  input         io_in_3_bits_isVset,
  input         io_in_3_bits_firstUop,
  input         io_in_3_bits_lastUop,
  input  [6:0] io_in_3_bits_numWB,
  input  [2:0] io_in_3_bits_commitType,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [31:0] io_in_4_bits_instr,
  input         io_in_4_bits_exceptionVec_0,
  input         io_in_4_bits_exceptionVec_1,
  input         io_in_4_bits_exceptionVec_2,
  input         io_in_4_bits_exceptionVec_3,
  input         io_in_4_bits_exceptionVec_4,
  input         io_in_4_bits_exceptionVec_5,
  input         io_in_4_bits_exceptionVec_6,
  input         io_in_4_bits_exceptionVec_7,
  input         io_in_4_bits_exceptionVec_8,
  input         io_in_4_bits_exceptionVec_9,
  input         io_in_4_bits_exceptionVec_10,
  input         io_in_4_bits_exceptionVec_11,
  input         io_in_4_bits_exceptionVec_12,
  input         io_in_4_bits_exceptionVec_13,
  input         io_in_4_bits_exceptionVec_14,
  input         io_in_4_bits_exceptionVec_15,
  input         io_in_4_bits_exceptionVec_16,
  input         io_in_4_bits_exceptionVec_17,
  input         io_in_4_bits_exceptionVec_18,
  input         io_in_4_bits_exceptionVec_19,
  input         io_in_4_bits_exceptionVec_20,
  input         io_in_4_bits_exceptionVec_21,
  input         io_in_4_bits_exceptionVec_22,
  input         io_in_4_bits_exceptionVec_23,
  input         io_in_4_bits_isFetchMalAddr,
  input  [3:0] io_in_4_bits_trigger,
  input         io_in_4_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_4_bits_preDecodeInfo_brType,
  input         io_in_4_bits_pred_taken,
  input         io_in_4_bits_crossPageIPFFix,
  input         io_in_4_bits_ftqPtr_flag,
  input  [5:0] io_in_4_bits_ftqPtr_value,
  input  [3:0] io_in_4_bits_ftqOffset,
  input  [3:0] io_in_4_bits_srcType_0,
  input  [3:0] io_in_4_bits_srcType_1,
  input  [3:0] io_in_4_bits_srcType_2,
  input  [3:0] io_in_4_bits_srcType_3,
  input  [3:0] io_in_4_bits_srcType_4,
  input  [5:0] io_in_4_bits_lsrc_0,
  input  [5:0] io_in_4_bits_lsrc_1,
  input  [5:0] io_in_4_bits_lsrc_2,
  input  [5:0] io_in_4_bits_lsrc_3,
  input  [5:0] io_in_4_bits_lsrc_4,
  input  [5:0] io_in_4_bits_ldest,
  input  [34:0] io_in_4_bits_fuType,
  input  [8:0] io_in_4_bits_fuOpType,
  input         io_in_4_bits_rfWen,
  input         io_in_4_bits_fpWen,
  input         io_in_4_bits_vecWen,
  input         io_in_4_bits_v0Wen,
  input         io_in_4_bits_vlWen,
  input         io_in_4_bits_isXSTrap,
  input         io_in_4_bits_waitForward,
  input         io_in_4_bits_blockBackward,
  input         io_in_4_bits_flushPipe,
  input         io_in_4_bits_canRobCompress,
  input  [3:0] io_in_4_bits_selImm,
  input  [21:0] io_in_4_bits_imm,
  input  [1:0] io_in_4_bits_fpu_typeTagOut,
  input         io_in_4_bits_fpu_wflags,
  input  [1:0] io_in_4_bits_fpu_typ,
  input  [1:0] io_in_4_bits_fpu_fmt,
  input  [2:0] io_in_4_bits_fpu_rm,
  input         io_in_4_bits_vpu_vill,
  input         io_in_4_bits_vpu_vma,
  input         io_in_4_bits_vpu_vta,
  input  [1:0] io_in_4_bits_vpu_vsew,
  input  [2:0] io_in_4_bits_vpu_vlmul,
  input         io_in_4_bits_vpu_specVill,
  input         io_in_4_bits_vpu_specVma,
  input         io_in_4_bits_vpu_specVta,
  input  [1:0] io_in_4_bits_vpu_specVsew,
  input  [2:0] io_in_4_bits_vpu_specVlmul,
  input         io_in_4_bits_vpu_vm,
  input  [7:0] io_in_4_bits_vpu_vstart,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_4_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_4_bits_vpu_vmask,
  input  [2:0] io_in_4_bits_vpu_nf,
  input  [1:0] io_in_4_bits_vpu_veew,
  input         io_in_4_bits_vpu_isExt,
  input         io_in_4_bits_vpu_isNarrow,
  input         io_in_4_bits_vpu_isDstMask,
  input         io_in_4_bits_vpu_isOpMask,
  input         io_in_4_bits_vpu_isDependOldVd,
  input         io_in_4_bits_vpu_isWritePartVd,
  input         io_in_4_bits_vpu_isVleff,
  input         io_in_4_bits_vlsInstr,
  input         io_in_4_bits_wfflags,
  input         io_in_4_bits_isMove,
  input  [6:0] io_in_4_bits_uopIdx,
  input  [5:0] io_in_4_bits_uopSplitType,
  input         io_in_4_bits_isVset,
  input         io_in_4_bits_firstUop,
  input         io_in_4_bits_lastUop,
  input  [6:0] io_in_4_bits_numWB,
  input  [2:0] io_in_4_bits_commitType,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [31:0] io_in_5_bits_instr,
  input         io_in_5_bits_exceptionVec_0,
  input         io_in_5_bits_exceptionVec_1,
  input         io_in_5_bits_exceptionVec_2,
  input         io_in_5_bits_exceptionVec_3,
  input         io_in_5_bits_exceptionVec_4,
  input         io_in_5_bits_exceptionVec_5,
  input         io_in_5_bits_exceptionVec_6,
  input         io_in_5_bits_exceptionVec_7,
  input         io_in_5_bits_exceptionVec_8,
  input         io_in_5_bits_exceptionVec_9,
  input         io_in_5_bits_exceptionVec_10,
  input         io_in_5_bits_exceptionVec_11,
  input         io_in_5_bits_exceptionVec_12,
  input         io_in_5_bits_exceptionVec_13,
  input         io_in_5_bits_exceptionVec_14,
  input         io_in_5_bits_exceptionVec_15,
  input         io_in_5_bits_exceptionVec_16,
  input         io_in_5_bits_exceptionVec_17,
  input         io_in_5_bits_exceptionVec_18,
  input         io_in_5_bits_exceptionVec_19,
  input         io_in_5_bits_exceptionVec_20,
  input         io_in_5_bits_exceptionVec_21,
  input         io_in_5_bits_exceptionVec_22,
  input         io_in_5_bits_exceptionVec_23,
  input         io_in_5_bits_isFetchMalAddr,
  input  [3:0] io_in_5_bits_trigger,
  input         io_in_5_bits_preDecodeInfo_isRVC,
  input  [1:0] io_in_5_bits_preDecodeInfo_brType,
  input         io_in_5_bits_pred_taken,
  input         io_in_5_bits_crossPageIPFFix,
  input         io_in_5_bits_ftqPtr_flag,
  input  [5:0] io_in_5_bits_ftqPtr_value,
  input  [3:0] io_in_5_bits_ftqOffset,
  input  [3:0] io_in_5_bits_srcType_0,
  input  [3:0] io_in_5_bits_srcType_1,
  input  [3:0] io_in_5_bits_srcType_2,
  input  [3:0] io_in_5_bits_srcType_3,
  input  [3:0] io_in_5_bits_srcType_4,
  input  [5:0] io_in_5_bits_lsrc_0,
  input  [5:0] io_in_5_bits_lsrc_1,
  input  [5:0] io_in_5_bits_lsrc_2,
  input  [5:0] io_in_5_bits_lsrc_3,
  input  [5:0] io_in_5_bits_lsrc_4,
  input  [5:0] io_in_5_bits_ldest,
  input  [34:0] io_in_5_bits_fuType,
  input  [8:0] io_in_5_bits_fuOpType,
  input         io_in_5_bits_rfWen,
  input         io_in_5_bits_fpWen,
  input         io_in_5_bits_vecWen,
  input         io_in_5_bits_v0Wen,
  input         io_in_5_bits_vlWen,
  input         io_in_5_bits_isXSTrap,
  input         io_in_5_bits_waitForward,
  input         io_in_5_bits_blockBackward,
  input         io_in_5_bits_flushPipe,
  input         io_in_5_bits_canRobCompress,
  input  [3:0] io_in_5_bits_selImm,
  input  [21:0] io_in_5_bits_imm,
  input  [1:0] io_in_5_bits_fpu_typeTagOut,
  input         io_in_5_bits_fpu_wflags,
  input  [1:0] io_in_5_bits_fpu_typ,
  input  [1:0] io_in_5_bits_fpu_fmt,
  input  [2:0] io_in_5_bits_fpu_rm,
  input         io_in_5_bits_vpu_vill,
  input         io_in_5_bits_vpu_vma,
  input         io_in_5_bits_vpu_vta,
  input  [1:0] io_in_5_bits_vpu_vsew,
  input  [2:0] io_in_5_bits_vpu_vlmul,
  input         io_in_5_bits_vpu_specVill,
  input         io_in_5_bits_vpu_specVma,
  input         io_in_5_bits_vpu_specVta,
  input  [1:0] io_in_5_bits_vpu_specVsew,
  input  [2:0] io_in_5_bits_vpu_specVlmul,
  input         io_in_5_bits_vpu_vm,
  input  [7:0] io_in_5_bits_vpu_vstart,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_2,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_4,
  input         io_in_5_bits_vpu_fpu_isFoldTo1_8,
  input  [127:0] io_in_5_bits_vpu_vmask,
  input  [2:0] io_in_5_bits_vpu_nf,
  input  [1:0] io_in_5_bits_vpu_veew,
  input         io_in_5_bits_vpu_isExt,
  input         io_in_5_bits_vpu_isNarrow,
  input         io_in_5_bits_vpu_isDstMask,
  input         io_in_5_bits_vpu_isOpMask,
  input         io_in_5_bits_vpu_isDependOldVd,
  input         io_in_5_bits_vpu_isWritePartVd,
  input         io_in_5_bits_vpu_isVleff,
  input         io_in_5_bits_vlsInstr,
  input         io_in_5_bits_wfflags,
  input         io_in_5_bits_isMove,
  input  [6:0] io_in_5_bits_uopIdx,
  input  [5:0] io_in_5_bits_uopSplitType,
  input         io_in_5_bits_isVset,
  input         io_in_5_bits_firstUop,
  input         io_in_5_bits_lastUop,
  input  [6:0] io_in_5_bits_numWB,
  input  [2:0] io_in_5_bits_commitType,
  input         io_fusionInfo_0_rs2FromRs1,
  input         io_fusionInfo_0_rs2FromRs2,
  input         io_fusionInfo_0_rs2FromZero,
  input         io_fusionInfo_1_rs2FromRs1,
  input         io_fusionInfo_1_rs2FromRs2,
  input         io_fusionInfo_1_rs2FromZero,
  input         io_fusionInfo_2_rs2FromRs1,
  input         io_fusionInfo_2_rs2FromRs2,
  input         io_fusionInfo_2_rs2FromZero,
  input         io_fusionInfo_3_rs2FromRs1,
  input         io_fusionInfo_3_rs2FromRs2,
  input         io_fusionInfo_3_rs2FromZero,
  input         io_fusionInfo_4_rs2FromRs1,
  input         io_fusionInfo_4_rs2FromRs2,
  input         io_fusionInfo_4_rs2FromZero,
  input  [7:0] io_intReadPorts_0_0,
  input  [7:0] io_intReadPorts_0_1,
  input  [7:0] io_intReadPorts_1_0,
  input  [7:0] io_intReadPorts_1_1,
  input  [7:0] io_intReadPorts_2_0,
  input  [7:0] io_intReadPorts_2_1,
  input  [7:0] io_intReadPorts_3_0,
  input  [7:0] io_intReadPorts_3_1,
  input  [7:0] io_intReadPorts_4_0,
  input  [7:0] io_intReadPorts_4_1,
  input  [7:0] io_intReadPorts_5_0,
  input  [7:0] io_intReadPorts_5_1,
  input  [7:0] io_fpReadPorts_0_0,
  input  [7:0] io_fpReadPorts_0_1,
  input  [7:0] io_fpReadPorts_0_2,
  input  [7:0] io_fpReadPorts_1_0,
  input  [7:0] io_fpReadPorts_1_1,
  input  [7:0] io_fpReadPorts_1_2,
  input  [7:0] io_fpReadPorts_2_0,
  input  [7:0] io_fpReadPorts_2_1,
  input  [7:0] io_fpReadPorts_2_2,
  input  [7:0] io_fpReadPorts_3_0,
  input  [7:0] io_fpReadPorts_3_1,
  input  [7:0] io_fpReadPorts_3_2,
  input  [7:0] io_fpReadPorts_4_0,
  input  [7:0] io_fpReadPorts_4_1,
  input  [7:0] io_fpReadPorts_4_2,
  input  [7:0] io_fpReadPorts_5_0,
  input  [7:0] io_fpReadPorts_5_1,
  input  [7:0] io_fpReadPorts_5_2,
  input  [7:0] io_vecReadPorts_0_0,
  input  [7:0] io_vecReadPorts_0_1,
  input  [7:0] io_vecReadPorts_0_2,
  input  [7:0] io_vecReadPorts_1_0,
  input  [7:0] io_vecReadPorts_1_1,
  input  [7:0] io_vecReadPorts_1_2,
  input  [7:0] io_vecReadPorts_2_0,
  input  [7:0] io_vecReadPorts_2_1,
  input  [7:0] io_vecReadPorts_2_2,
  input  [7:0] io_vecReadPorts_3_0,
  input  [7:0] io_vecReadPorts_3_1,
  input  [7:0] io_vecReadPorts_3_2,
  input  [7:0] io_vecReadPorts_4_0,
  input  [7:0] io_vecReadPorts_4_1,
  input  [7:0] io_vecReadPorts_4_2,
  input  [7:0] io_vecReadPorts_5_0,
  input  [7:0] io_vecReadPorts_5_1,
  input  [7:0] io_vecReadPorts_5_2,
  input  [7:0] io_v0ReadPorts_0_0,
  input  [7:0] io_v0ReadPorts_1_0,
  input  [7:0] io_v0ReadPorts_2_0,
  input  [7:0] io_v0ReadPorts_3_0,
  input  [7:0] io_v0ReadPorts_4_0,
  input  [7:0] io_v0ReadPorts_5_0,
  input  [7:0] io_vlReadPorts_0_0,
  input  [7:0] io_vlReadPorts_1_0,
  input  [7:0] io_vlReadPorts_2_0,
  input  [7:0] io_vlReadPorts_3_0,
  input  [7:0] io_vlReadPorts_4_0,
  input  [7:0] io_vlReadPorts_5_0,
  output        io_intRenamePorts_0_wen,
  output [4:0] io_intRenamePorts_0_addr,
  output [7:0] io_intRenamePorts_0_data,
  output        io_intRenamePorts_1_wen,
  output [4:0] io_intRenamePorts_1_addr,
  output [7:0] io_intRenamePorts_1_data,
  output        io_intRenamePorts_2_wen,
  output [4:0] io_intRenamePorts_2_addr,
  output [7:0] io_intRenamePorts_2_data,
  output        io_intRenamePorts_3_wen,
  output [4:0] io_intRenamePorts_3_addr,
  output [7:0] io_intRenamePorts_3_data,
  output        io_intRenamePorts_4_wen,
  output [4:0] io_intRenamePorts_4_addr,
  output [7:0] io_intRenamePorts_4_data,
  output        io_intRenamePorts_5_wen,
  output [4:0] io_intRenamePorts_5_addr,
  output [7:0] io_intRenamePorts_5_data,
  output        io_fpRenamePorts_0_wen,
  output [5:0] io_fpRenamePorts_0_addr,
  output [7:0] io_fpRenamePorts_0_data,
  output        io_fpRenamePorts_1_wen,
  output [5:0] io_fpRenamePorts_1_addr,
  output [7:0] io_fpRenamePorts_1_data,
  output        io_fpRenamePorts_2_wen,
  output [5:0] io_fpRenamePorts_2_addr,
  output [7:0] io_fpRenamePorts_2_data,
  output        io_fpRenamePorts_3_wen,
  output [5:0] io_fpRenamePorts_3_addr,
  output [7:0] io_fpRenamePorts_3_data,
  output        io_fpRenamePorts_4_wen,
  output [5:0] io_fpRenamePorts_4_addr,
  output [7:0] io_fpRenamePorts_4_data,
  output        io_fpRenamePorts_5_wen,
  output [5:0] io_fpRenamePorts_5_addr,
  output [7:0] io_fpRenamePorts_5_data,
  output        io_vecRenamePorts_0_wen,
  output [5:0] io_vecRenamePorts_0_addr,
  output [7:0] io_vecRenamePorts_0_data,
  output        io_vecRenamePorts_1_wen,
  output [5:0] io_vecRenamePorts_1_addr,
  output [7:0] io_vecRenamePorts_1_data,
  output        io_vecRenamePorts_2_wen,
  output [5:0] io_vecRenamePorts_2_addr,
  output [7:0] io_vecRenamePorts_2_data,
  output        io_vecRenamePorts_3_wen,
  output [5:0] io_vecRenamePorts_3_addr,
  output [7:0] io_vecRenamePorts_3_data,
  output        io_vecRenamePorts_4_wen,
  output [5:0] io_vecRenamePorts_4_addr,
  output [7:0] io_vecRenamePorts_4_data,
  output        io_vecRenamePorts_5_wen,
  output [5:0] io_vecRenamePorts_5_addr,
  output [7:0] io_vecRenamePorts_5_data,
  output        io_v0RenamePorts_0_wen,
  output [7:0] io_v0RenamePorts_0_data,
  output        io_v0RenamePorts_1_wen,
  output [7:0] io_v0RenamePorts_1_data,
  output        io_v0RenamePorts_2_wen,
  output [7:0] io_v0RenamePorts_2_data,
  output        io_v0RenamePorts_3_wen,
  output [7:0] io_v0RenamePorts_3_data,
  output        io_v0RenamePorts_4_wen,
  output [7:0] io_v0RenamePorts_4_data,
  output        io_v0RenamePorts_5_wen,
  output [7:0] io_v0RenamePorts_5_data,
  output        io_vlRenamePorts_0_wen,
  output [7:0] io_vlRenamePorts_0_data,
  output        io_vlRenamePorts_1_wen,
  output [7:0] io_vlRenamePorts_1_data,
  output        io_vlRenamePorts_2_wen,
  output [7:0] io_vlRenamePorts_2_data,
  output        io_vlRenamePorts_3_wen,
  output [7:0] io_vlRenamePorts_3_data,
  output        io_vlRenamePorts_4_wen,
  output [7:0] io_vlRenamePorts_4_data,
  output        io_vlRenamePorts_5_wen,
  output [7:0] io_vlRenamePorts_5_data,
  input  [7:0] io_int_old_pdest_0,
  input  [7:0] io_int_old_pdest_1,
  input  [7:0] io_int_old_pdest_2,
  input  [7:0] io_int_old_pdest_3,
  input  [7:0] io_int_old_pdest_4,
  input  [7:0] io_int_old_pdest_5,
  input  [7:0] io_fp_old_pdest_0,
  input  [7:0] io_fp_old_pdest_1,
  input  [7:0] io_fp_old_pdest_2,
  input  [7:0] io_fp_old_pdest_3,
  input  [7:0] io_fp_old_pdest_4,
  input  [7:0] io_fp_old_pdest_5,
  input  [7:0] io_vec_old_pdest_0,
  input  [7:0] io_vec_old_pdest_1,
  input  [7:0] io_vec_old_pdest_2,
  input  [7:0] io_vec_old_pdest_3,
  input  [7:0] io_vec_old_pdest_4,
  input  [7:0] io_vec_old_pdest_5,
  input  [7:0] io_v0_old_pdest_0,
  input  [7:0] io_v0_old_pdest_1,
  input  [7:0] io_v0_old_pdest_2,
  input  [7:0] io_v0_old_pdest_3,
  input  [7:0] io_v0_old_pdest_4,
  input  [7:0] io_v0_old_pdest_5,
  input  [7:0] io_vl_old_pdest_0,
  input  [7:0] io_vl_old_pdest_1,
  input  [7:0] io_vl_old_pdest_2,
  input  [7:0] io_vl_old_pdest_3,
  input  [7:0] io_vl_old_pdest_4,
  input  [7:0] io_vl_old_pdest_5,
  input         io_int_need_free_0,
  input         io_int_need_free_1,
  input         io_int_need_free_2,
  input         io_int_need_free_3,
  input         io_int_need_free_4,
  input         io_int_need_free_5,
  input         io_out_0_ready,
  output        io_out_0_valid,
  output [31:0] io_out_0_bits_instr,
  output        io_out_0_bits_exceptionVec_0,
  output        io_out_0_bits_exceptionVec_1,
  output        io_out_0_bits_exceptionVec_2,
  output        io_out_0_bits_exceptionVec_3,
  output        io_out_0_bits_exceptionVec_4,
  output        io_out_0_bits_exceptionVec_5,
  output        io_out_0_bits_exceptionVec_6,
  output        io_out_0_bits_exceptionVec_7,
  output        io_out_0_bits_exceptionVec_8,
  output        io_out_0_bits_exceptionVec_9,
  output        io_out_0_bits_exceptionVec_10,
  output        io_out_0_bits_exceptionVec_11,
  output        io_out_0_bits_exceptionVec_12,
  output        io_out_0_bits_exceptionVec_13,
  output        io_out_0_bits_exceptionVec_14,
  output        io_out_0_bits_exceptionVec_15,
  output        io_out_0_bits_exceptionVec_16,
  output        io_out_0_bits_exceptionVec_17,
  output        io_out_0_bits_exceptionVec_18,
  output        io_out_0_bits_exceptionVec_19,
  output        io_out_0_bits_exceptionVec_20,
  output        io_out_0_bits_exceptionVec_21,
  output        io_out_0_bits_exceptionVec_22,
  output        io_out_0_bits_exceptionVec_23,
  output        io_out_0_bits_isFetchMalAddr,
  output        io_out_0_bits_hasException,
  output [3:0] io_out_0_bits_trigger,
  output        io_out_0_bits_preDecodeInfo_isRVC,
  output        io_out_0_bits_pred_taken,
  output        io_out_0_bits_crossPageIPFFix,
  output        io_out_0_bits_ftqPtr_flag,
  output [5:0] io_out_0_bits_ftqPtr_value,
  output [3:0] io_out_0_bits_ftqOffset,
  output [3:0] io_out_0_bits_srcType_0,
  output [3:0] io_out_0_bits_srcType_1,
  output [3:0] io_out_0_bits_srcType_2,
  output [3:0] io_out_0_bits_srcType_3,
  output [3:0] io_out_0_bits_srcType_4,
  output [5:0] io_out_0_bits_ldest,
  output [34:0] io_out_0_bits_fuType,
  output [8:0] io_out_0_bits_fuOpType,
  output        io_out_0_bits_rfWen,
  output        io_out_0_bits_fpWen,
  output        io_out_0_bits_vecWen,
  output        io_out_0_bits_v0Wen,
  output        io_out_0_bits_vlWen,
  output        io_out_0_bits_isXSTrap,
  output        io_out_0_bits_waitForward,
  output        io_out_0_bits_blockBackward,
  output        io_out_0_bits_flushPipe,
  output [3:0] io_out_0_bits_selImm,
  output [31:0] io_out_0_bits_imm,
  output [1:0] io_out_0_bits_fpu_typeTagOut,
  output        io_out_0_bits_fpu_wflags,
  output [1:0] io_out_0_bits_fpu_typ,
  output [1:0] io_out_0_bits_fpu_fmt,
  output [2:0] io_out_0_bits_fpu_rm,
  output        io_out_0_bits_vpu_vill,
  output        io_out_0_bits_vpu_vma,
  output        io_out_0_bits_vpu_vta,
  output [1:0] io_out_0_bits_vpu_vsew,
  output [2:0] io_out_0_bits_vpu_vlmul,
  output        io_out_0_bits_vpu_specVill,
  output        io_out_0_bits_vpu_specVma,
  output        io_out_0_bits_vpu_specVta,
  output [1:0] io_out_0_bits_vpu_specVsew,
  output [2:0] io_out_0_bits_vpu_specVlmul,
  output        io_out_0_bits_vpu_vm,
  output [7:0] io_out_0_bits_vpu_vstart,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_0_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_0_bits_vpu_vmask,
  output [2:0] io_out_0_bits_vpu_nf,
  output [1:0] io_out_0_bits_vpu_veew,
  output        io_out_0_bits_vpu_isExt,
  output        io_out_0_bits_vpu_isNarrow,
  output        io_out_0_bits_vpu_isDstMask,
  output        io_out_0_bits_vpu_isOpMask,
  output        io_out_0_bits_vpu_isDependOldVd,
  output        io_out_0_bits_vpu_isWritePartVd,
  output        io_out_0_bits_vpu_isVleff,
  output        io_out_0_bits_vlsInstr,
  output        io_out_0_bits_wfflags,
  output        io_out_0_bits_isMove,
  output [6:0] io_out_0_bits_uopIdx,
  output        io_out_0_bits_isVset,
  output        io_out_0_bits_firstUop,
  output        io_out_0_bits_lastUop,
  output [6:0] io_out_0_bits_numWB,
  output [2:0] io_out_0_bits_commitType,
  output [7:0] io_out_0_bits_psrc_0,
  output [7:0] io_out_0_bits_psrc_1,
  output [7:0] io_out_0_bits_psrc_2,
  output [7:0] io_out_0_bits_psrc_3,
  output [7:0] io_out_0_bits_psrc_4,
  output [7:0] io_out_0_bits_pdest,
  output        io_out_0_bits_robIdx_flag,
  output [7:0] io_out_0_bits_robIdx_value,
  output [2:0] io_out_0_bits_instrSize,
  output        io_out_0_bits_dirtyFs,
  output        io_out_0_bits_dirtyVs,
  output [3:0] io_out_0_bits_traceBlockInPipe_itype,
  output [3:0] io_out_0_bits_traceBlockInPipe_iretire,
  output        io_out_0_bits_traceBlockInPipe_ilastsize,
  output        io_out_0_bits_eliminatedMove,
  output        io_out_0_bits_snapshot,
  output [63:0] io_out_0_bits_debugInfo_renameTime,
  output [4:0] io_out_0_bits_numLsElem,
  input         io_out_1_ready,
  output        io_out_1_valid,
  output [31:0] io_out_1_bits_instr,
  output        io_out_1_bits_exceptionVec_0,
  output        io_out_1_bits_exceptionVec_1,
  output        io_out_1_bits_exceptionVec_2,
  output        io_out_1_bits_exceptionVec_3,
  output        io_out_1_bits_exceptionVec_4,
  output        io_out_1_bits_exceptionVec_5,
  output        io_out_1_bits_exceptionVec_6,
  output        io_out_1_bits_exceptionVec_7,
  output        io_out_1_bits_exceptionVec_8,
  output        io_out_1_bits_exceptionVec_9,
  output        io_out_1_bits_exceptionVec_10,
  output        io_out_1_bits_exceptionVec_11,
  output        io_out_1_bits_exceptionVec_12,
  output        io_out_1_bits_exceptionVec_13,
  output        io_out_1_bits_exceptionVec_14,
  output        io_out_1_bits_exceptionVec_15,
  output        io_out_1_bits_exceptionVec_16,
  output        io_out_1_bits_exceptionVec_17,
  output        io_out_1_bits_exceptionVec_18,
  output        io_out_1_bits_exceptionVec_19,
  output        io_out_1_bits_exceptionVec_20,
  output        io_out_1_bits_exceptionVec_21,
  output        io_out_1_bits_exceptionVec_22,
  output        io_out_1_bits_exceptionVec_23,
  output        io_out_1_bits_isFetchMalAddr,
  output        io_out_1_bits_hasException,
  output [3:0] io_out_1_bits_trigger,
  output        io_out_1_bits_preDecodeInfo_isRVC,
  output        io_out_1_bits_pred_taken,
  output        io_out_1_bits_crossPageIPFFix,
  output        io_out_1_bits_ftqPtr_flag,
  output [5:0] io_out_1_bits_ftqPtr_value,
  output [3:0] io_out_1_bits_ftqOffset,
  output [3:0] io_out_1_bits_srcType_0,
  output [3:0] io_out_1_bits_srcType_1,
  output [3:0] io_out_1_bits_srcType_2,
  output [3:0] io_out_1_bits_srcType_3,
  output [3:0] io_out_1_bits_srcType_4,
  output [5:0] io_out_1_bits_ldest,
  output [34:0] io_out_1_bits_fuType,
  output [8:0] io_out_1_bits_fuOpType,
  output        io_out_1_bits_rfWen,
  output        io_out_1_bits_fpWen,
  output        io_out_1_bits_vecWen,
  output        io_out_1_bits_v0Wen,
  output        io_out_1_bits_vlWen,
  output        io_out_1_bits_isXSTrap,
  output        io_out_1_bits_waitForward,
  output        io_out_1_bits_blockBackward,
  output        io_out_1_bits_flushPipe,
  output [3:0] io_out_1_bits_selImm,
  output [31:0] io_out_1_bits_imm,
  output [1:0] io_out_1_bits_fpu_typeTagOut,
  output        io_out_1_bits_fpu_wflags,
  output [1:0] io_out_1_bits_fpu_typ,
  output [1:0] io_out_1_bits_fpu_fmt,
  output [2:0] io_out_1_bits_fpu_rm,
  output        io_out_1_bits_vpu_vill,
  output        io_out_1_bits_vpu_vma,
  output        io_out_1_bits_vpu_vta,
  output [1:0] io_out_1_bits_vpu_vsew,
  output [2:0] io_out_1_bits_vpu_vlmul,
  output        io_out_1_bits_vpu_specVill,
  output        io_out_1_bits_vpu_specVma,
  output        io_out_1_bits_vpu_specVta,
  output [1:0] io_out_1_bits_vpu_specVsew,
  output [2:0] io_out_1_bits_vpu_specVlmul,
  output        io_out_1_bits_vpu_vm,
  output [7:0] io_out_1_bits_vpu_vstart,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_1_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_1_bits_vpu_vmask,
  output [2:0] io_out_1_bits_vpu_nf,
  output [1:0] io_out_1_bits_vpu_veew,
  output        io_out_1_bits_vpu_isExt,
  output        io_out_1_bits_vpu_isNarrow,
  output        io_out_1_bits_vpu_isDstMask,
  output        io_out_1_bits_vpu_isOpMask,
  output        io_out_1_bits_vpu_isDependOldVd,
  output        io_out_1_bits_vpu_isWritePartVd,
  output        io_out_1_bits_vpu_isVleff,
  output        io_out_1_bits_vlsInstr,
  output        io_out_1_bits_wfflags,
  output        io_out_1_bits_isMove,
  output [6:0] io_out_1_bits_uopIdx,
  output        io_out_1_bits_isVset,
  output        io_out_1_bits_firstUop,
  output        io_out_1_bits_lastUop,
  output [6:0] io_out_1_bits_numWB,
  output [2:0] io_out_1_bits_commitType,
  output [7:0] io_out_1_bits_psrc_0,
  output [7:0] io_out_1_bits_psrc_1,
  output [7:0] io_out_1_bits_psrc_2,
  output [7:0] io_out_1_bits_psrc_3,
  output [7:0] io_out_1_bits_psrc_4,
  output [7:0] io_out_1_bits_pdest,
  output        io_out_1_bits_robIdx_flag,
  output [7:0] io_out_1_bits_robIdx_value,
  output [2:0] io_out_1_bits_instrSize,
  output        io_out_1_bits_dirtyFs,
  output        io_out_1_bits_dirtyVs,
  output [3:0] io_out_1_bits_traceBlockInPipe_itype,
  output [3:0] io_out_1_bits_traceBlockInPipe_iretire,
  output        io_out_1_bits_traceBlockInPipe_ilastsize,
  output        io_out_1_bits_eliminatedMove,
  output        io_out_1_bits_snapshot,
  output [63:0] io_out_1_bits_debugInfo_renameTime,
  output [4:0] io_out_1_bits_numLsElem,
  input         io_out_2_ready,
  output        io_out_2_valid,
  output [31:0] io_out_2_bits_instr,
  output        io_out_2_bits_exceptionVec_0,
  output        io_out_2_bits_exceptionVec_1,
  output        io_out_2_bits_exceptionVec_2,
  output        io_out_2_bits_exceptionVec_3,
  output        io_out_2_bits_exceptionVec_4,
  output        io_out_2_bits_exceptionVec_5,
  output        io_out_2_bits_exceptionVec_6,
  output        io_out_2_bits_exceptionVec_7,
  output        io_out_2_bits_exceptionVec_8,
  output        io_out_2_bits_exceptionVec_9,
  output        io_out_2_bits_exceptionVec_10,
  output        io_out_2_bits_exceptionVec_11,
  output        io_out_2_bits_exceptionVec_12,
  output        io_out_2_bits_exceptionVec_13,
  output        io_out_2_bits_exceptionVec_14,
  output        io_out_2_bits_exceptionVec_15,
  output        io_out_2_bits_exceptionVec_16,
  output        io_out_2_bits_exceptionVec_17,
  output        io_out_2_bits_exceptionVec_18,
  output        io_out_2_bits_exceptionVec_19,
  output        io_out_2_bits_exceptionVec_20,
  output        io_out_2_bits_exceptionVec_21,
  output        io_out_2_bits_exceptionVec_22,
  output        io_out_2_bits_exceptionVec_23,
  output        io_out_2_bits_isFetchMalAddr,
  output        io_out_2_bits_hasException,
  output [3:0] io_out_2_bits_trigger,
  output        io_out_2_bits_preDecodeInfo_isRVC,
  output        io_out_2_bits_pred_taken,
  output        io_out_2_bits_crossPageIPFFix,
  output        io_out_2_bits_ftqPtr_flag,
  output [5:0] io_out_2_bits_ftqPtr_value,
  output [3:0] io_out_2_bits_ftqOffset,
  output [3:0] io_out_2_bits_srcType_0,
  output [3:0] io_out_2_bits_srcType_1,
  output [3:0] io_out_2_bits_srcType_2,
  output [3:0] io_out_2_bits_srcType_3,
  output [3:0] io_out_2_bits_srcType_4,
  output [5:0] io_out_2_bits_ldest,
  output [34:0] io_out_2_bits_fuType,
  output [8:0] io_out_2_bits_fuOpType,
  output        io_out_2_bits_rfWen,
  output        io_out_2_bits_fpWen,
  output        io_out_2_bits_vecWen,
  output        io_out_2_bits_v0Wen,
  output        io_out_2_bits_vlWen,
  output        io_out_2_bits_isXSTrap,
  output        io_out_2_bits_waitForward,
  output        io_out_2_bits_blockBackward,
  output        io_out_2_bits_flushPipe,
  output [3:0] io_out_2_bits_selImm,
  output [31:0] io_out_2_bits_imm,
  output [1:0] io_out_2_bits_fpu_typeTagOut,
  output        io_out_2_bits_fpu_wflags,
  output [1:0] io_out_2_bits_fpu_typ,
  output [1:0] io_out_2_bits_fpu_fmt,
  output [2:0] io_out_2_bits_fpu_rm,
  output        io_out_2_bits_vpu_vill,
  output        io_out_2_bits_vpu_vma,
  output        io_out_2_bits_vpu_vta,
  output [1:0] io_out_2_bits_vpu_vsew,
  output [2:0] io_out_2_bits_vpu_vlmul,
  output        io_out_2_bits_vpu_specVill,
  output        io_out_2_bits_vpu_specVma,
  output        io_out_2_bits_vpu_specVta,
  output [1:0] io_out_2_bits_vpu_specVsew,
  output [2:0] io_out_2_bits_vpu_specVlmul,
  output        io_out_2_bits_vpu_vm,
  output [7:0] io_out_2_bits_vpu_vstart,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_2_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_2_bits_vpu_vmask,
  output [2:0] io_out_2_bits_vpu_nf,
  output [1:0] io_out_2_bits_vpu_veew,
  output        io_out_2_bits_vpu_isExt,
  output        io_out_2_bits_vpu_isNarrow,
  output        io_out_2_bits_vpu_isDstMask,
  output        io_out_2_bits_vpu_isOpMask,
  output        io_out_2_bits_vpu_isDependOldVd,
  output        io_out_2_bits_vpu_isWritePartVd,
  output        io_out_2_bits_vpu_isVleff,
  output        io_out_2_bits_vlsInstr,
  output        io_out_2_bits_wfflags,
  output        io_out_2_bits_isMove,
  output [6:0] io_out_2_bits_uopIdx,
  output        io_out_2_bits_isVset,
  output        io_out_2_bits_firstUop,
  output        io_out_2_bits_lastUop,
  output [6:0] io_out_2_bits_numWB,
  output [2:0] io_out_2_bits_commitType,
  output [7:0] io_out_2_bits_psrc_0,
  output [7:0] io_out_2_bits_psrc_1,
  output [7:0] io_out_2_bits_psrc_2,
  output [7:0] io_out_2_bits_psrc_3,
  output [7:0] io_out_2_bits_psrc_4,
  output [7:0] io_out_2_bits_pdest,
  output        io_out_2_bits_robIdx_flag,
  output [7:0] io_out_2_bits_robIdx_value,
  output [2:0] io_out_2_bits_instrSize,
  output        io_out_2_bits_dirtyFs,
  output        io_out_2_bits_dirtyVs,
  output [3:0] io_out_2_bits_traceBlockInPipe_itype,
  output [3:0] io_out_2_bits_traceBlockInPipe_iretire,
  output        io_out_2_bits_traceBlockInPipe_ilastsize,
  output        io_out_2_bits_eliminatedMove,
  output        io_out_2_bits_snapshot,
  output [63:0] io_out_2_bits_debugInfo_renameTime,
  output [4:0] io_out_2_bits_numLsElem,
  input         io_out_3_ready,
  output        io_out_3_valid,
  output [31:0] io_out_3_bits_instr,
  output        io_out_3_bits_exceptionVec_0,
  output        io_out_3_bits_exceptionVec_1,
  output        io_out_3_bits_exceptionVec_2,
  output        io_out_3_bits_exceptionVec_3,
  output        io_out_3_bits_exceptionVec_4,
  output        io_out_3_bits_exceptionVec_5,
  output        io_out_3_bits_exceptionVec_6,
  output        io_out_3_bits_exceptionVec_7,
  output        io_out_3_bits_exceptionVec_8,
  output        io_out_3_bits_exceptionVec_9,
  output        io_out_3_bits_exceptionVec_10,
  output        io_out_3_bits_exceptionVec_11,
  output        io_out_3_bits_exceptionVec_12,
  output        io_out_3_bits_exceptionVec_13,
  output        io_out_3_bits_exceptionVec_14,
  output        io_out_3_bits_exceptionVec_15,
  output        io_out_3_bits_exceptionVec_16,
  output        io_out_3_bits_exceptionVec_17,
  output        io_out_3_bits_exceptionVec_18,
  output        io_out_3_bits_exceptionVec_19,
  output        io_out_3_bits_exceptionVec_20,
  output        io_out_3_bits_exceptionVec_21,
  output        io_out_3_bits_exceptionVec_22,
  output        io_out_3_bits_exceptionVec_23,
  output        io_out_3_bits_isFetchMalAddr,
  output        io_out_3_bits_hasException,
  output [3:0] io_out_3_bits_trigger,
  output        io_out_3_bits_preDecodeInfo_isRVC,
  output        io_out_3_bits_pred_taken,
  output        io_out_3_bits_crossPageIPFFix,
  output        io_out_3_bits_ftqPtr_flag,
  output [5:0] io_out_3_bits_ftqPtr_value,
  output [3:0] io_out_3_bits_ftqOffset,
  output [3:0] io_out_3_bits_srcType_0,
  output [3:0] io_out_3_bits_srcType_1,
  output [3:0] io_out_3_bits_srcType_2,
  output [3:0] io_out_3_bits_srcType_3,
  output [3:0] io_out_3_bits_srcType_4,
  output [5:0] io_out_3_bits_ldest,
  output [34:0] io_out_3_bits_fuType,
  output [8:0] io_out_3_bits_fuOpType,
  output        io_out_3_bits_rfWen,
  output        io_out_3_bits_fpWen,
  output        io_out_3_bits_vecWen,
  output        io_out_3_bits_v0Wen,
  output        io_out_3_bits_vlWen,
  output        io_out_3_bits_isXSTrap,
  output        io_out_3_bits_waitForward,
  output        io_out_3_bits_blockBackward,
  output        io_out_3_bits_flushPipe,
  output [3:0] io_out_3_bits_selImm,
  output [31:0] io_out_3_bits_imm,
  output [1:0] io_out_3_bits_fpu_typeTagOut,
  output        io_out_3_bits_fpu_wflags,
  output [1:0] io_out_3_bits_fpu_typ,
  output [1:0] io_out_3_bits_fpu_fmt,
  output [2:0] io_out_3_bits_fpu_rm,
  output        io_out_3_bits_vpu_vill,
  output        io_out_3_bits_vpu_vma,
  output        io_out_3_bits_vpu_vta,
  output [1:0] io_out_3_bits_vpu_vsew,
  output [2:0] io_out_3_bits_vpu_vlmul,
  output        io_out_3_bits_vpu_specVill,
  output        io_out_3_bits_vpu_specVma,
  output        io_out_3_bits_vpu_specVta,
  output [1:0] io_out_3_bits_vpu_specVsew,
  output [2:0] io_out_3_bits_vpu_specVlmul,
  output        io_out_3_bits_vpu_vm,
  output [7:0] io_out_3_bits_vpu_vstart,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_3_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_3_bits_vpu_vmask,
  output [2:0] io_out_3_bits_vpu_nf,
  output [1:0] io_out_3_bits_vpu_veew,
  output        io_out_3_bits_vpu_isExt,
  output        io_out_3_bits_vpu_isNarrow,
  output        io_out_3_bits_vpu_isDstMask,
  output        io_out_3_bits_vpu_isOpMask,
  output        io_out_3_bits_vpu_isDependOldVd,
  output        io_out_3_bits_vpu_isWritePartVd,
  output        io_out_3_bits_vpu_isVleff,
  output        io_out_3_bits_vlsInstr,
  output        io_out_3_bits_wfflags,
  output        io_out_3_bits_isMove,
  output [6:0] io_out_3_bits_uopIdx,
  output        io_out_3_bits_isVset,
  output        io_out_3_bits_firstUop,
  output        io_out_3_bits_lastUop,
  output [6:0] io_out_3_bits_numWB,
  output [2:0] io_out_3_bits_commitType,
  output [7:0] io_out_3_bits_psrc_0,
  output [7:0] io_out_3_bits_psrc_1,
  output [7:0] io_out_3_bits_psrc_2,
  output [7:0] io_out_3_bits_psrc_3,
  output [7:0] io_out_3_bits_psrc_4,
  output [7:0] io_out_3_bits_pdest,
  output        io_out_3_bits_robIdx_flag,
  output [7:0] io_out_3_bits_robIdx_value,
  output [2:0] io_out_3_bits_instrSize,
  output        io_out_3_bits_dirtyFs,
  output        io_out_3_bits_dirtyVs,
  output [3:0] io_out_3_bits_traceBlockInPipe_itype,
  output [3:0] io_out_3_bits_traceBlockInPipe_iretire,
  output        io_out_3_bits_traceBlockInPipe_ilastsize,
  output        io_out_3_bits_eliminatedMove,
  output        io_out_3_bits_snapshot,
  output [63:0] io_out_3_bits_debugInfo_renameTime,
  output [4:0] io_out_3_bits_numLsElem,
  input         io_out_4_ready,
  output        io_out_4_valid,
  output [31:0] io_out_4_bits_instr,
  output        io_out_4_bits_exceptionVec_0,
  output        io_out_4_bits_exceptionVec_1,
  output        io_out_4_bits_exceptionVec_2,
  output        io_out_4_bits_exceptionVec_3,
  output        io_out_4_bits_exceptionVec_4,
  output        io_out_4_bits_exceptionVec_5,
  output        io_out_4_bits_exceptionVec_6,
  output        io_out_4_bits_exceptionVec_7,
  output        io_out_4_bits_exceptionVec_8,
  output        io_out_4_bits_exceptionVec_9,
  output        io_out_4_bits_exceptionVec_10,
  output        io_out_4_bits_exceptionVec_11,
  output        io_out_4_bits_exceptionVec_12,
  output        io_out_4_bits_exceptionVec_13,
  output        io_out_4_bits_exceptionVec_14,
  output        io_out_4_bits_exceptionVec_15,
  output        io_out_4_bits_exceptionVec_16,
  output        io_out_4_bits_exceptionVec_17,
  output        io_out_4_bits_exceptionVec_18,
  output        io_out_4_bits_exceptionVec_19,
  output        io_out_4_bits_exceptionVec_20,
  output        io_out_4_bits_exceptionVec_21,
  output        io_out_4_bits_exceptionVec_22,
  output        io_out_4_bits_exceptionVec_23,
  output        io_out_4_bits_isFetchMalAddr,
  output        io_out_4_bits_hasException,
  output [3:0] io_out_4_bits_trigger,
  output        io_out_4_bits_preDecodeInfo_isRVC,
  output        io_out_4_bits_pred_taken,
  output        io_out_4_bits_crossPageIPFFix,
  output        io_out_4_bits_ftqPtr_flag,
  output [5:0] io_out_4_bits_ftqPtr_value,
  output [3:0] io_out_4_bits_ftqOffset,
  output [3:0] io_out_4_bits_srcType_0,
  output [3:0] io_out_4_bits_srcType_1,
  output [3:0] io_out_4_bits_srcType_2,
  output [3:0] io_out_4_bits_srcType_3,
  output [3:0] io_out_4_bits_srcType_4,
  output [5:0] io_out_4_bits_ldest,
  output [34:0] io_out_4_bits_fuType,
  output [8:0] io_out_4_bits_fuOpType,
  output        io_out_4_bits_rfWen,
  output        io_out_4_bits_fpWen,
  output        io_out_4_bits_vecWen,
  output        io_out_4_bits_v0Wen,
  output        io_out_4_bits_vlWen,
  output        io_out_4_bits_isXSTrap,
  output        io_out_4_bits_waitForward,
  output        io_out_4_bits_blockBackward,
  output        io_out_4_bits_flushPipe,
  output [3:0] io_out_4_bits_selImm,
  output [31:0] io_out_4_bits_imm,
  output [1:0] io_out_4_bits_fpu_typeTagOut,
  output        io_out_4_bits_fpu_wflags,
  output [1:0] io_out_4_bits_fpu_typ,
  output [1:0] io_out_4_bits_fpu_fmt,
  output [2:0] io_out_4_bits_fpu_rm,
  output        io_out_4_bits_vpu_vill,
  output        io_out_4_bits_vpu_vma,
  output        io_out_4_bits_vpu_vta,
  output [1:0] io_out_4_bits_vpu_vsew,
  output [2:0] io_out_4_bits_vpu_vlmul,
  output        io_out_4_bits_vpu_specVill,
  output        io_out_4_bits_vpu_specVma,
  output        io_out_4_bits_vpu_specVta,
  output [1:0] io_out_4_bits_vpu_specVsew,
  output [2:0] io_out_4_bits_vpu_specVlmul,
  output        io_out_4_bits_vpu_vm,
  output [7:0] io_out_4_bits_vpu_vstart,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_4_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_4_bits_vpu_vmask,
  output [2:0] io_out_4_bits_vpu_nf,
  output [1:0] io_out_4_bits_vpu_veew,
  output        io_out_4_bits_vpu_isExt,
  output        io_out_4_bits_vpu_isNarrow,
  output        io_out_4_bits_vpu_isDstMask,
  output        io_out_4_bits_vpu_isOpMask,
  output        io_out_4_bits_vpu_isDependOldVd,
  output        io_out_4_bits_vpu_isWritePartVd,
  output        io_out_4_bits_vpu_isVleff,
  output        io_out_4_bits_vlsInstr,
  output        io_out_4_bits_wfflags,
  output        io_out_4_bits_isMove,
  output [6:0] io_out_4_bits_uopIdx,
  output        io_out_4_bits_isVset,
  output        io_out_4_bits_firstUop,
  output        io_out_4_bits_lastUop,
  output [6:0] io_out_4_bits_numWB,
  output [2:0] io_out_4_bits_commitType,
  output [7:0] io_out_4_bits_psrc_0,
  output [7:0] io_out_4_bits_psrc_1,
  output [7:0] io_out_4_bits_psrc_2,
  output [7:0] io_out_4_bits_psrc_3,
  output [7:0] io_out_4_bits_psrc_4,
  output [7:0] io_out_4_bits_pdest,
  output        io_out_4_bits_robIdx_flag,
  output [7:0] io_out_4_bits_robIdx_value,
  output [2:0] io_out_4_bits_instrSize,
  output        io_out_4_bits_dirtyFs,
  output        io_out_4_bits_dirtyVs,
  output [3:0] io_out_4_bits_traceBlockInPipe_itype,
  output [3:0] io_out_4_bits_traceBlockInPipe_iretire,
  output        io_out_4_bits_traceBlockInPipe_ilastsize,
  output        io_out_4_bits_eliminatedMove,
  output        io_out_4_bits_snapshot,
  output [63:0] io_out_4_bits_debugInfo_renameTime,
  output [4:0] io_out_4_bits_numLsElem,
  input         io_out_5_ready,
  output        io_out_5_valid,
  output [31:0] io_out_5_bits_instr,
  output        io_out_5_bits_exceptionVec_0,
  output        io_out_5_bits_exceptionVec_1,
  output        io_out_5_bits_exceptionVec_2,
  output        io_out_5_bits_exceptionVec_3,
  output        io_out_5_bits_exceptionVec_4,
  output        io_out_5_bits_exceptionVec_5,
  output        io_out_5_bits_exceptionVec_6,
  output        io_out_5_bits_exceptionVec_7,
  output        io_out_5_bits_exceptionVec_8,
  output        io_out_5_bits_exceptionVec_9,
  output        io_out_5_bits_exceptionVec_10,
  output        io_out_5_bits_exceptionVec_11,
  output        io_out_5_bits_exceptionVec_12,
  output        io_out_5_bits_exceptionVec_13,
  output        io_out_5_bits_exceptionVec_14,
  output        io_out_5_bits_exceptionVec_15,
  output        io_out_5_bits_exceptionVec_16,
  output        io_out_5_bits_exceptionVec_17,
  output        io_out_5_bits_exceptionVec_18,
  output        io_out_5_bits_exceptionVec_19,
  output        io_out_5_bits_exceptionVec_20,
  output        io_out_5_bits_exceptionVec_21,
  output        io_out_5_bits_exceptionVec_22,
  output        io_out_5_bits_exceptionVec_23,
  output        io_out_5_bits_isFetchMalAddr,
  output        io_out_5_bits_hasException,
  output [3:0] io_out_5_bits_trigger,
  output        io_out_5_bits_preDecodeInfo_isRVC,
  output        io_out_5_bits_pred_taken,
  output        io_out_5_bits_crossPageIPFFix,
  output        io_out_5_bits_ftqPtr_flag,
  output [5:0] io_out_5_bits_ftqPtr_value,
  output [3:0] io_out_5_bits_ftqOffset,
  output [3:0] io_out_5_bits_srcType_0,
  output [3:0] io_out_5_bits_srcType_1,
  output [3:0] io_out_5_bits_srcType_2,
  output [3:0] io_out_5_bits_srcType_3,
  output [3:0] io_out_5_bits_srcType_4,
  output [5:0] io_out_5_bits_ldest,
  output [34:0] io_out_5_bits_fuType,
  output [8:0] io_out_5_bits_fuOpType,
  output        io_out_5_bits_rfWen,
  output        io_out_5_bits_fpWen,
  output        io_out_5_bits_vecWen,
  output        io_out_5_bits_v0Wen,
  output        io_out_5_bits_vlWen,
  output        io_out_5_bits_isXSTrap,
  output        io_out_5_bits_waitForward,
  output        io_out_5_bits_blockBackward,
  output        io_out_5_bits_flushPipe,
  output [3:0] io_out_5_bits_selImm,
  output [31:0] io_out_5_bits_imm,
  output [1:0] io_out_5_bits_fpu_typeTagOut,
  output        io_out_5_bits_fpu_wflags,
  output [1:0] io_out_5_bits_fpu_typ,
  output [1:0] io_out_5_bits_fpu_fmt,
  output [2:0] io_out_5_bits_fpu_rm,
  output        io_out_5_bits_vpu_vill,
  output        io_out_5_bits_vpu_vma,
  output        io_out_5_bits_vpu_vta,
  output [1:0] io_out_5_bits_vpu_vsew,
  output [2:0] io_out_5_bits_vpu_vlmul,
  output        io_out_5_bits_vpu_specVill,
  output        io_out_5_bits_vpu_specVma,
  output        io_out_5_bits_vpu_specVta,
  output [1:0] io_out_5_bits_vpu_specVsew,
  output [2:0] io_out_5_bits_vpu_specVlmul,
  output        io_out_5_bits_vpu_vm,
  output [7:0] io_out_5_bits_vpu_vstart,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_2,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_4,
  output        io_out_5_bits_vpu_fpu_isFoldTo1_8,
  output [127:0] io_out_5_bits_vpu_vmask,
  output [2:0] io_out_5_bits_vpu_nf,
  output [1:0] io_out_5_bits_vpu_veew,
  output        io_out_5_bits_vpu_isExt,
  output        io_out_5_bits_vpu_isNarrow,
  output        io_out_5_bits_vpu_isDstMask,
  output        io_out_5_bits_vpu_isOpMask,
  output        io_out_5_bits_vpu_isDependOldVd,
  output        io_out_5_bits_vpu_isWritePartVd,
  output        io_out_5_bits_vpu_isVleff,
  output        io_out_5_bits_vlsInstr,
  output        io_out_5_bits_wfflags,
  output        io_out_5_bits_isMove,
  output [6:0] io_out_5_bits_uopIdx,
  output        io_out_5_bits_isVset,
  output        io_out_5_bits_firstUop,
  output        io_out_5_bits_lastUop,
  output [6:0] io_out_5_bits_numWB,
  output [2:0] io_out_5_bits_commitType,
  output [7:0] io_out_5_bits_psrc_0,
  output [7:0] io_out_5_bits_psrc_1,
  output [7:0] io_out_5_bits_psrc_2,
  output [7:0] io_out_5_bits_psrc_3,
  output [7:0] io_out_5_bits_psrc_4,
  output [7:0] io_out_5_bits_pdest,
  output        io_out_5_bits_robIdx_flag,
  output [7:0] io_out_5_bits_robIdx_value,
  output [2:0] io_out_5_bits_instrSize,
  output        io_out_5_bits_dirtyFs,
  output        io_out_5_bits_dirtyVs,
  output [3:0] io_out_5_bits_traceBlockInPipe_itype,
  output [3:0] io_out_5_bits_traceBlockInPipe_iretire,
  output        io_out_5_bits_traceBlockInPipe_ilastsize,
  output        io_out_5_bits_eliminatedMove,
  output        io_out_5_bits_snapshot,
  output [63:0] io_out_5_bits_debugInfo_renameTime,
  output [4:0] io_out_5_bits_numLsElem,
  input         io_snpt_snptDeq,
  input         io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input         io_snpt_flushVec_0,
  input         io_snpt_flushVec_1,
  input         io_snpt_flushVec_2,
  input         io_snpt_flushVec_3,
  input         io_snptLastEnq_valid,
  input         io_snptLastEnq_bits_flag,
  input  [7:0] io_snptLastEnq_bits_value,
  input         io_snptIsFull,
  input  [5:0] io_stallReason_in_reason_0,
  input  [5:0] io_stallReason_in_reason_1,
  input  [5:0] io_stallReason_in_reason_2,
  input  [5:0] io_stallReason_in_reason_3,
  input  [5:0] io_stallReason_in_reason_4,
  input  [5:0] io_stallReason_in_reason_5,
  output        io_stallReason_in_backReason_valid,
  output [5:0] io_stallReason_in_backReason_bits,
  output [5:0] io_stallReason_out_reason_0,
  output [5:0] io_stallReason_out_reason_1,
  output [5:0] io_stallReason_out_reason_2,
  output [5:0] io_stallReason_out_reason_3,
  output [5:0] io_stallReason_out_reason_4,
  output [5:0] io_stallReason_out_reason_5,
  input         io_stallReason_out_backReason_valid,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  output [5:0] io_perf_19_value,
  output [5:0] io_perf_20_value,
  output [5:0] io_perf_21_value,
  output [5:0] io_perf_22_value,
  output [5:0] io_perf_23_value,
  output [5:0] io_perf_24_value,
  output [5:0] io_perf_25_value,
  output [5:0] io_perf_26_value,
  output [5:0] io_perf_27_value,
  output [5:0] io_perf_28_value,
  output [5:0] io_perf_29_value
);

  decoded_inst_t in_b   [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] in_v, in_r, out_v, out_r;
  decoded_inst_t out_pt [RENAME_WIDTH];
  logic [7:0]  o_psrc [RENAME_WIDTH][NUM_SRC];
  logic [7:0]  o_pdest [RENAME_WIDTH];
  logic        o_robIdx_flag [RENAME_WIDTH];
  logic [7:0]  o_robIdx_value [RENAME_WIDTH];
  logic        o_eliminatedMove [RENAME_WIDTH], o_snapshot [RENAME_WIDTH], o_hasException [RENAME_WIDTH];
  logic [3:0]  o_srcType0 [RENAME_WIDTH];
  logic [31:0] o_imm [RENAME_WIDTH];
  logic [63:0] o_renameTime [RENAME_WIDTH];
  logic [2:0]  o_instrSize [RENAME_WIDTH];
  logic        o_dirtyFs [RENAME_WIDTH], o_dirtyVs [RENAME_WIDTH], o_ilastsize [RENAME_WIDTH];
  logic [3:0]  o_itype [RENAME_WIDTH], o_iretire [RENAME_WIDTH];
  logic        o_lastUop [RENAME_WIDTH], o_wfflags [RENAME_WIDTH];
  logic [6:0]  o_numWB [RENAME_WIDTH];
  logic [4:0]  o_numLsElem [RENAME_WIDTH];
  rat_wport_t  intRP [COMMIT_WIDTH], fpRP [COMMIT_WIDTH], vecRP [COMMIT_WIDTH];
  logic        v0RP_wen [COMMIT_WIDTH], vlRP_wen [COMMIT_WIDTH];
  logic [7:0]  v0RP_data [COMMIT_WIDTH], vlRP_data [COMMIT_WIDTH];
  logic [7:0]  intRd [RENAME_WIDTH][2], fpRd [RENAME_WIDTH][3], vecRd [RENAME_WIDTH][3];
  logic [7:0]  v0Rd [RENAME_WIDTH], vlRd [RENAME_WIDTH];
  logic [7:0]  int_oldpd [COMMIT_WIDTH], fp_oldpd [COMMIT_WIDTH], vec_oldpd [COMMIT_WIDTH], v0_oldpd [COMMIT_WIDTH], vl_oldpd [COMMIT_WIDTH];
  logic [5:0]  sr_in [RENAME_WIDTH], sr_out [RENAME_WIDTH];
  logic [5:0]  perf_v [30];
  logic        sr_bv; logic [5:0] sr_bb;
  logic [3:0]  flushv;
  logic [COMMIT_WIDTH-1:0] rab_cv, rab_wv, rab_rf, rab_fp, rab_vec, rab_v0, rab_vl, rab_mv, int_nf;
  logic [RENAME_WIDTH-1:0] fi_r1, fi_r2, fi_z;

  // ---- io_in_0 → in_b[0] ----
  assign in_v[0] = io_in_0_valid;
  assign io_in_0_ready = in_r[0];
  assign in_b[0].instr = io_in_0_bits_instr;
  assign in_b[0].exceptionVec = {io_in_0_bits_exceptionVec_23, io_in_0_bits_exceptionVec_22, io_in_0_bits_exceptionVec_21, io_in_0_bits_exceptionVec_20, io_in_0_bits_exceptionVec_19, io_in_0_bits_exceptionVec_18, io_in_0_bits_exceptionVec_17, io_in_0_bits_exceptionVec_16, io_in_0_bits_exceptionVec_15, io_in_0_bits_exceptionVec_14, io_in_0_bits_exceptionVec_13, io_in_0_bits_exceptionVec_12, io_in_0_bits_exceptionVec_11, io_in_0_bits_exceptionVec_10, io_in_0_bits_exceptionVec_9, io_in_0_bits_exceptionVec_8, io_in_0_bits_exceptionVec_7, io_in_0_bits_exceptionVec_6, io_in_0_bits_exceptionVec_5, io_in_0_bits_exceptionVec_4, io_in_0_bits_exceptionVec_3, io_in_0_bits_exceptionVec_2, io_in_0_bits_exceptionVec_1, io_in_0_bits_exceptionVec_0};
  assign in_b[0].isFetchMalAddr = io_in_0_bits_isFetchMalAddr;
  assign in_b[0].trigger = io_in_0_bits_trigger;
  assign in_b[0].preDecodeInfo_isRVC = io_in_0_bits_preDecodeInfo_isRVC;
  assign in_b[0].preDecodeInfo_brType = io_in_0_bits_preDecodeInfo_brType;
  assign in_b[0].pred_taken = io_in_0_bits_pred_taken;
  assign in_b[0].crossPageIPFFix = io_in_0_bits_crossPageIPFFix;
  assign in_b[0].ftqPtr_flag = io_in_0_bits_ftqPtr_flag;
  assign in_b[0].ftqPtr_value = io_in_0_bits_ftqPtr_value;
  assign in_b[0].ftqOffset = io_in_0_bits_ftqOffset;
  assign in_b[0].srcType[0] = io_in_0_bits_srcType_0;
  assign in_b[0].srcType[1] = io_in_0_bits_srcType_1;
  assign in_b[0].srcType[2] = io_in_0_bits_srcType_2;
  assign in_b[0].srcType[3] = io_in_0_bits_srcType_3;
  assign in_b[0].srcType[4] = io_in_0_bits_srcType_4;
  assign in_b[0].lsrc[0] = io_in_0_bits_lsrc_0;
  assign in_b[0].lsrc[1] = io_in_0_bits_lsrc_1;
  assign in_b[0].lsrc[2] = '0; assign in_b[0].lsrc[3] = '0; assign in_b[0].lsrc[4] = '0;
  assign in_b[0].ldest = io_in_0_bits_ldest;
  assign in_b[0].fuType = io_in_0_bits_fuType;
  assign in_b[0].fuOpType = io_in_0_bits_fuOpType;
  assign in_b[0].rfWen = io_in_0_bits_rfWen;
  assign in_b[0].fpWen = io_in_0_bits_fpWen;
  assign in_b[0].vecWen = io_in_0_bits_vecWen;
  assign in_b[0].v0Wen = io_in_0_bits_v0Wen;
  assign in_b[0].vlWen = io_in_0_bits_vlWen;
  assign in_b[0].isXSTrap = io_in_0_bits_isXSTrap;
  assign in_b[0].waitForward = io_in_0_bits_waitForward;
  assign in_b[0].blockBackward = io_in_0_bits_blockBackward;
  assign in_b[0].flushPipe = io_in_0_bits_flushPipe;
  assign in_b[0].canRobCompress = io_in_0_bits_canRobCompress;
  assign in_b[0].selImm = io_in_0_bits_selImm;
  assign in_b[0].imm = io_in_0_bits_imm;
  assign in_b[0].fpu_typeTagOut = io_in_0_bits_fpu_typeTagOut;
  assign in_b[0].fpu_wflags = io_in_0_bits_fpu_wflags;
  assign in_b[0].fpu_typ = io_in_0_bits_fpu_typ;
  assign in_b[0].fpu_fmt = io_in_0_bits_fpu_fmt;
  assign in_b[0].fpu_rm = io_in_0_bits_fpu_rm;
  assign in_b[0].vpu_vill = io_in_0_bits_vpu_vill;
  assign in_b[0].vpu_vma = io_in_0_bits_vpu_vma;
  assign in_b[0].vpu_vta = io_in_0_bits_vpu_vta;
  assign in_b[0].vpu_vsew = io_in_0_bits_vpu_vsew;
  assign in_b[0].vpu_vlmul = io_in_0_bits_vpu_vlmul;
  assign in_b[0].vpu_specVill = io_in_0_bits_vpu_specVill;
  assign in_b[0].vpu_specVma = io_in_0_bits_vpu_specVma;
  assign in_b[0].vpu_specVta = io_in_0_bits_vpu_specVta;
  assign in_b[0].vpu_specVsew = io_in_0_bits_vpu_specVsew;
  assign in_b[0].vpu_specVlmul = io_in_0_bits_vpu_specVlmul;
  assign in_b[0].vpu_vm = io_in_0_bits_vpu_vm;
  assign in_b[0].vpu_vstart = io_in_0_bits_vpu_vstart;
  assign in_b[0].vpu_fpu_isFoldTo1_2 = io_in_0_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[0].vpu_fpu_isFoldTo1_4 = io_in_0_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[0].vpu_fpu_isFoldTo1_8 = io_in_0_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[0].vpu_vmask = io_in_0_bits_vpu_vmask;
  assign in_b[0].vpu_nf = io_in_0_bits_vpu_nf;
  assign in_b[0].vpu_veew = io_in_0_bits_vpu_veew;
  assign in_b[0].vpu_isExt = io_in_0_bits_vpu_isExt;
  assign in_b[0].vpu_isNarrow = io_in_0_bits_vpu_isNarrow;
  assign in_b[0].vpu_isDstMask = io_in_0_bits_vpu_isDstMask;
  assign in_b[0].vpu_isOpMask = io_in_0_bits_vpu_isOpMask;
  assign in_b[0].vpu_isDependOldVd = io_in_0_bits_vpu_isDependOldVd;
  assign in_b[0].vpu_isWritePartVd = io_in_0_bits_vpu_isWritePartVd;
  assign in_b[0].vpu_isVleff = io_in_0_bits_vpu_isVleff;
  assign in_b[0].vlsInstr = io_in_0_bits_vlsInstr;
  assign in_b[0].wfflags = io_in_0_bits_wfflags;
  assign in_b[0].isMove = io_in_0_bits_isMove;
  assign in_b[0].uopIdx = io_in_0_bits_uopIdx;
  assign in_b[0].uopSplitType = io_in_0_bits_uopSplitType;
  assign in_b[0].isVset = io_in_0_bits_isVset;
  assign in_b[0].firstUop = io_in_0_bits_firstUop;
  assign in_b[0].lastUop = io_in_0_bits_lastUop;
  assign in_b[0].numWB = io_in_0_bits_numWB;
  assign in_b[0].commitType = io_in_0_bits_commitType;

  // ---- io_in_1 → in_b[1] ----
  assign in_v[1] = io_in_1_valid;
  assign io_in_1_ready = in_r[1];
  assign in_b[1].instr = io_in_1_bits_instr;
  assign in_b[1].exceptionVec = {io_in_1_bits_exceptionVec_23, io_in_1_bits_exceptionVec_22, io_in_1_bits_exceptionVec_21, io_in_1_bits_exceptionVec_20, io_in_1_bits_exceptionVec_19, io_in_1_bits_exceptionVec_18, io_in_1_bits_exceptionVec_17, io_in_1_bits_exceptionVec_16, io_in_1_bits_exceptionVec_15, io_in_1_bits_exceptionVec_14, io_in_1_bits_exceptionVec_13, io_in_1_bits_exceptionVec_12, io_in_1_bits_exceptionVec_11, io_in_1_bits_exceptionVec_10, io_in_1_bits_exceptionVec_9, io_in_1_bits_exceptionVec_8, io_in_1_bits_exceptionVec_7, io_in_1_bits_exceptionVec_6, io_in_1_bits_exceptionVec_5, io_in_1_bits_exceptionVec_4, io_in_1_bits_exceptionVec_3, io_in_1_bits_exceptionVec_2, io_in_1_bits_exceptionVec_1, io_in_1_bits_exceptionVec_0};
  assign in_b[1].isFetchMalAddr = io_in_1_bits_isFetchMalAddr;
  assign in_b[1].trigger = io_in_1_bits_trigger;
  assign in_b[1].preDecodeInfo_isRVC = io_in_1_bits_preDecodeInfo_isRVC;
  assign in_b[1].preDecodeInfo_brType = io_in_1_bits_preDecodeInfo_brType;
  assign in_b[1].pred_taken = io_in_1_bits_pred_taken;
  assign in_b[1].crossPageIPFFix = io_in_1_bits_crossPageIPFFix;
  assign in_b[1].ftqPtr_flag = io_in_1_bits_ftqPtr_flag;
  assign in_b[1].ftqPtr_value = io_in_1_bits_ftqPtr_value;
  assign in_b[1].ftqOffset = io_in_1_bits_ftqOffset;
  assign in_b[1].srcType[0] = io_in_1_bits_srcType_0;
  assign in_b[1].srcType[1] = io_in_1_bits_srcType_1;
  assign in_b[1].srcType[2] = io_in_1_bits_srcType_2;
  assign in_b[1].srcType[3] = io_in_1_bits_srcType_3;
  assign in_b[1].srcType[4] = io_in_1_bits_srcType_4;
  assign in_b[1].lsrc[0] = io_in_1_bits_lsrc_0;
  assign in_b[1].lsrc[1] = io_in_1_bits_lsrc_1;
  assign in_b[1].lsrc[2] = io_in_1_bits_lsrc_2;
  assign in_b[1].lsrc[3] = io_in_1_bits_lsrc_3;
  assign in_b[1].lsrc[4] = io_in_1_bits_lsrc_4;
  assign in_b[1].ldest = io_in_1_bits_ldest;
  assign in_b[1].fuType = io_in_1_bits_fuType;
  assign in_b[1].fuOpType = io_in_1_bits_fuOpType;
  assign in_b[1].rfWen = io_in_1_bits_rfWen;
  assign in_b[1].fpWen = io_in_1_bits_fpWen;
  assign in_b[1].vecWen = io_in_1_bits_vecWen;
  assign in_b[1].v0Wen = io_in_1_bits_v0Wen;
  assign in_b[1].vlWen = io_in_1_bits_vlWen;
  assign in_b[1].isXSTrap = io_in_1_bits_isXSTrap;
  assign in_b[1].waitForward = io_in_1_bits_waitForward;
  assign in_b[1].blockBackward = io_in_1_bits_blockBackward;
  assign in_b[1].flushPipe = io_in_1_bits_flushPipe;
  assign in_b[1].canRobCompress = io_in_1_bits_canRobCompress;
  assign in_b[1].selImm = io_in_1_bits_selImm;
  assign in_b[1].imm = io_in_1_bits_imm;
  assign in_b[1].fpu_typeTagOut = io_in_1_bits_fpu_typeTagOut;
  assign in_b[1].fpu_wflags = io_in_1_bits_fpu_wflags;
  assign in_b[1].fpu_typ = io_in_1_bits_fpu_typ;
  assign in_b[1].fpu_fmt = io_in_1_bits_fpu_fmt;
  assign in_b[1].fpu_rm = io_in_1_bits_fpu_rm;
  assign in_b[1].vpu_vill = io_in_1_bits_vpu_vill;
  assign in_b[1].vpu_vma = io_in_1_bits_vpu_vma;
  assign in_b[1].vpu_vta = io_in_1_bits_vpu_vta;
  assign in_b[1].vpu_vsew = io_in_1_bits_vpu_vsew;
  assign in_b[1].vpu_vlmul = io_in_1_bits_vpu_vlmul;
  assign in_b[1].vpu_specVill = io_in_1_bits_vpu_specVill;
  assign in_b[1].vpu_specVma = io_in_1_bits_vpu_specVma;
  assign in_b[1].vpu_specVta = io_in_1_bits_vpu_specVta;
  assign in_b[1].vpu_specVsew = io_in_1_bits_vpu_specVsew;
  assign in_b[1].vpu_specVlmul = io_in_1_bits_vpu_specVlmul;
  assign in_b[1].vpu_vm = io_in_1_bits_vpu_vm;
  assign in_b[1].vpu_vstart = io_in_1_bits_vpu_vstart;
  assign in_b[1].vpu_fpu_isFoldTo1_2 = io_in_1_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[1].vpu_fpu_isFoldTo1_4 = io_in_1_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[1].vpu_fpu_isFoldTo1_8 = io_in_1_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[1].vpu_vmask = io_in_1_bits_vpu_vmask;
  assign in_b[1].vpu_nf = io_in_1_bits_vpu_nf;
  assign in_b[1].vpu_veew = io_in_1_bits_vpu_veew;
  assign in_b[1].vpu_isExt = io_in_1_bits_vpu_isExt;
  assign in_b[1].vpu_isNarrow = io_in_1_bits_vpu_isNarrow;
  assign in_b[1].vpu_isDstMask = io_in_1_bits_vpu_isDstMask;
  assign in_b[1].vpu_isOpMask = io_in_1_bits_vpu_isOpMask;
  assign in_b[1].vpu_isDependOldVd = io_in_1_bits_vpu_isDependOldVd;
  assign in_b[1].vpu_isWritePartVd = io_in_1_bits_vpu_isWritePartVd;
  assign in_b[1].vpu_isVleff = io_in_1_bits_vpu_isVleff;
  assign in_b[1].vlsInstr = io_in_1_bits_vlsInstr;
  assign in_b[1].wfflags = io_in_1_bits_wfflags;
  assign in_b[1].isMove = io_in_1_bits_isMove;
  assign in_b[1].uopIdx = io_in_1_bits_uopIdx;
  assign in_b[1].uopSplitType = io_in_1_bits_uopSplitType;
  assign in_b[1].isVset = io_in_1_bits_isVset;
  assign in_b[1].firstUop = io_in_1_bits_firstUop;
  assign in_b[1].lastUop = io_in_1_bits_lastUop;
  assign in_b[1].numWB = io_in_1_bits_numWB;
  assign in_b[1].commitType = io_in_1_bits_commitType;

  // ---- io_in_2 → in_b[2] ----
  assign in_v[2] = io_in_2_valid;
  assign io_in_2_ready = in_r[2];
  assign in_b[2].instr = io_in_2_bits_instr;
  assign in_b[2].exceptionVec = {io_in_2_bits_exceptionVec_23, io_in_2_bits_exceptionVec_22, io_in_2_bits_exceptionVec_21, io_in_2_bits_exceptionVec_20, io_in_2_bits_exceptionVec_19, io_in_2_bits_exceptionVec_18, io_in_2_bits_exceptionVec_17, io_in_2_bits_exceptionVec_16, io_in_2_bits_exceptionVec_15, io_in_2_bits_exceptionVec_14, io_in_2_bits_exceptionVec_13, io_in_2_bits_exceptionVec_12, io_in_2_bits_exceptionVec_11, io_in_2_bits_exceptionVec_10, io_in_2_bits_exceptionVec_9, io_in_2_bits_exceptionVec_8, io_in_2_bits_exceptionVec_7, io_in_2_bits_exceptionVec_6, io_in_2_bits_exceptionVec_5, io_in_2_bits_exceptionVec_4, io_in_2_bits_exceptionVec_3, io_in_2_bits_exceptionVec_2, io_in_2_bits_exceptionVec_1, io_in_2_bits_exceptionVec_0};
  assign in_b[2].isFetchMalAddr = io_in_2_bits_isFetchMalAddr;
  assign in_b[2].trigger = io_in_2_bits_trigger;
  assign in_b[2].preDecodeInfo_isRVC = io_in_2_bits_preDecodeInfo_isRVC;
  assign in_b[2].preDecodeInfo_brType = io_in_2_bits_preDecodeInfo_brType;
  assign in_b[2].pred_taken = io_in_2_bits_pred_taken;
  assign in_b[2].crossPageIPFFix = io_in_2_bits_crossPageIPFFix;
  assign in_b[2].ftqPtr_flag = io_in_2_bits_ftqPtr_flag;
  assign in_b[2].ftqPtr_value = io_in_2_bits_ftqPtr_value;
  assign in_b[2].ftqOffset = io_in_2_bits_ftqOffset;
  assign in_b[2].srcType[0] = io_in_2_bits_srcType_0;
  assign in_b[2].srcType[1] = io_in_2_bits_srcType_1;
  assign in_b[2].srcType[2] = io_in_2_bits_srcType_2;
  assign in_b[2].srcType[3] = io_in_2_bits_srcType_3;
  assign in_b[2].srcType[4] = io_in_2_bits_srcType_4;
  assign in_b[2].lsrc[0] = io_in_2_bits_lsrc_0;
  assign in_b[2].lsrc[1] = io_in_2_bits_lsrc_1;
  assign in_b[2].lsrc[2] = io_in_2_bits_lsrc_2;
  assign in_b[2].lsrc[3] = io_in_2_bits_lsrc_3;
  assign in_b[2].lsrc[4] = io_in_2_bits_lsrc_4;
  assign in_b[2].ldest = io_in_2_bits_ldest;
  assign in_b[2].fuType = io_in_2_bits_fuType;
  assign in_b[2].fuOpType = io_in_2_bits_fuOpType;
  assign in_b[2].rfWen = io_in_2_bits_rfWen;
  assign in_b[2].fpWen = io_in_2_bits_fpWen;
  assign in_b[2].vecWen = io_in_2_bits_vecWen;
  assign in_b[2].v0Wen = io_in_2_bits_v0Wen;
  assign in_b[2].vlWen = io_in_2_bits_vlWen;
  assign in_b[2].isXSTrap = io_in_2_bits_isXSTrap;
  assign in_b[2].waitForward = io_in_2_bits_waitForward;
  assign in_b[2].blockBackward = io_in_2_bits_blockBackward;
  assign in_b[2].flushPipe = io_in_2_bits_flushPipe;
  assign in_b[2].canRobCompress = io_in_2_bits_canRobCompress;
  assign in_b[2].selImm = io_in_2_bits_selImm;
  assign in_b[2].imm = io_in_2_bits_imm;
  assign in_b[2].fpu_typeTagOut = io_in_2_bits_fpu_typeTagOut;
  assign in_b[2].fpu_wflags = io_in_2_bits_fpu_wflags;
  assign in_b[2].fpu_typ = io_in_2_bits_fpu_typ;
  assign in_b[2].fpu_fmt = io_in_2_bits_fpu_fmt;
  assign in_b[2].fpu_rm = io_in_2_bits_fpu_rm;
  assign in_b[2].vpu_vill = io_in_2_bits_vpu_vill;
  assign in_b[2].vpu_vma = io_in_2_bits_vpu_vma;
  assign in_b[2].vpu_vta = io_in_2_bits_vpu_vta;
  assign in_b[2].vpu_vsew = io_in_2_bits_vpu_vsew;
  assign in_b[2].vpu_vlmul = io_in_2_bits_vpu_vlmul;
  assign in_b[2].vpu_specVill = io_in_2_bits_vpu_specVill;
  assign in_b[2].vpu_specVma = io_in_2_bits_vpu_specVma;
  assign in_b[2].vpu_specVta = io_in_2_bits_vpu_specVta;
  assign in_b[2].vpu_specVsew = io_in_2_bits_vpu_specVsew;
  assign in_b[2].vpu_specVlmul = io_in_2_bits_vpu_specVlmul;
  assign in_b[2].vpu_vm = io_in_2_bits_vpu_vm;
  assign in_b[2].vpu_vstart = io_in_2_bits_vpu_vstart;
  assign in_b[2].vpu_fpu_isFoldTo1_2 = io_in_2_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[2].vpu_fpu_isFoldTo1_4 = io_in_2_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[2].vpu_fpu_isFoldTo1_8 = io_in_2_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[2].vpu_vmask = io_in_2_bits_vpu_vmask;
  assign in_b[2].vpu_nf = io_in_2_bits_vpu_nf;
  assign in_b[2].vpu_veew = io_in_2_bits_vpu_veew;
  assign in_b[2].vpu_isExt = io_in_2_bits_vpu_isExt;
  assign in_b[2].vpu_isNarrow = io_in_2_bits_vpu_isNarrow;
  assign in_b[2].vpu_isDstMask = io_in_2_bits_vpu_isDstMask;
  assign in_b[2].vpu_isOpMask = io_in_2_bits_vpu_isOpMask;
  assign in_b[2].vpu_isDependOldVd = io_in_2_bits_vpu_isDependOldVd;
  assign in_b[2].vpu_isWritePartVd = io_in_2_bits_vpu_isWritePartVd;
  assign in_b[2].vpu_isVleff = io_in_2_bits_vpu_isVleff;
  assign in_b[2].vlsInstr = io_in_2_bits_vlsInstr;
  assign in_b[2].wfflags = io_in_2_bits_wfflags;
  assign in_b[2].isMove = io_in_2_bits_isMove;
  assign in_b[2].uopIdx = io_in_2_bits_uopIdx;
  assign in_b[2].uopSplitType = io_in_2_bits_uopSplitType;
  assign in_b[2].isVset = io_in_2_bits_isVset;
  assign in_b[2].firstUop = io_in_2_bits_firstUop;
  assign in_b[2].lastUop = io_in_2_bits_lastUop;
  assign in_b[2].numWB = io_in_2_bits_numWB;
  assign in_b[2].commitType = io_in_2_bits_commitType;

  // ---- io_in_3 → in_b[3] ----
  assign in_v[3] = io_in_3_valid;
  assign io_in_3_ready = in_r[3];
  assign in_b[3].instr = io_in_3_bits_instr;
  assign in_b[3].exceptionVec = {io_in_3_bits_exceptionVec_23, io_in_3_bits_exceptionVec_22, io_in_3_bits_exceptionVec_21, io_in_3_bits_exceptionVec_20, io_in_3_bits_exceptionVec_19, io_in_3_bits_exceptionVec_18, io_in_3_bits_exceptionVec_17, io_in_3_bits_exceptionVec_16, io_in_3_bits_exceptionVec_15, io_in_3_bits_exceptionVec_14, io_in_3_bits_exceptionVec_13, io_in_3_bits_exceptionVec_12, io_in_3_bits_exceptionVec_11, io_in_3_bits_exceptionVec_10, io_in_3_bits_exceptionVec_9, io_in_3_bits_exceptionVec_8, io_in_3_bits_exceptionVec_7, io_in_3_bits_exceptionVec_6, io_in_3_bits_exceptionVec_5, io_in_3_bits_exceptionVec_4, io_in_3_bits_exceptionVec_3, io_in_3_bits_exceptionVec_2, io_in_3_bits_exceptionVec_1, io_in_3_bits_exceptionVec_0};
  assign in_b[3].isFetchMalAddr = io_in_3_bits_isFetchMalAddr;
  assign in_b[3].trigger = io_in_3_bits_trigger;
  assign in_b[3].preDecodeInfo_isRVC = io_in_3_bits_preDecodeInfo_isRVC;
  assign in_b[3].preDecodeInfo_brType = io_in_3_bits_preDecodeInfo_brType;
  assign in_b[3].pred_taken = io_in_3_bits_pred_taken;
  assign in_b[3].crossPageIPFFix = io_in_3_bits_crossPageIPFFix;
  assign in_b[3].ftqPtr_flag = io_in_3_bits_ftqPtr_flag;
  assign in_b[3].ftqPtr_value = io_in_3_bits_ftqPtr_value;
  assign in_b[3].ftqOffset = io_in_3_bits_ftqOffset;
  assign in_b[3].srcType[0] = io_in_3_bits_srcType_0;
  assign in_b[3].srcType[1] = io_in_3_bits_srcType_1;
  assign in_b[3].srcType[2] = io_in_3_bits_srcType_2;
  assign in_b[3].srcType[3] = io_in_3_bits_srcType_3;
  assign in_b[3].srcType[4] = io_in_3_bits_srcType_4;
  assign in_b[3].lsrc[0] = io_in_3_bits_lsrc_0;
  assign in_b[3].lsrc[1] = io_in_3_bits_lsrc_1;
  assign in_b[3].lsrc[2] = io_in_3_bits_lsrc_2;
  assign in_b[3].lsrc[3] = io_in_3_bits_lsrc_3;
  assign in_b[3].lsrc[4] = io_in_3_bits_lsrc_4;
  assign in_b[3].ldest = io_in_3_bits_ldest;
  assign in_b[3].fuType = io_in_3_bits_fuType;
  assign in_b[3].fuOpType = io_in_3_bits_fuOpType;
  assign in_b[3].rfWen = io_in_3_bits_rfWen;
  assign in_b[3].fpWen = io_in_3_bits_fpWen;
  assign in_b[3].vecWen = io_in_3_bits_vecWen;
  assign in_b[3].v0Wen = io_in_3_bits_v0Wen;
  assign in_b[3].vlWen = io_in_3_bits_vlWen;
  assign in_b[3].isXSTrap = io_in_3_bits_isXSTrap;
  assign in_b[3].waitForward = io_in_3_bits_waitForward;
  assign in_b[3].blockBackward = io_in_3_bits_blockBackward;
  assign in_b[3].flushPipe = io_in_3_bits_flushPipe;
  assign in_b[3].canRobCompress = io_in_3_bits_canRobCompress;
  assign in_b[3].selImm = io_in_3_bits_selImm;
  assign in_b[3].imm = io_in_3_bits_imm;
  assign in_b[3].fpu_typeTagOut = io_in_3_bits_fpu_typeTagOut;
  assign in_b[3].fpu_wflags = io_in_3_bits_fpu_wflags;
  assign in_b[3].fpu_typ = io_in_3_bits_fpu_typ;
  assign in_b[3].fpu_fmt = io_in_3_bits_fpu_fmt;
  assign in_b[3].fpu_rm = io_in_3_bits_fpu_rm;
  assign in_b[3].vpu_vill = io_in_3_bits_vpu_vill;
  assign in_b[3].vpu_vma = io_in_3_bits_vpu_vma;
  assign in_b[3].vpu_vta = io_in_3_bits_vpu_vta;
  assign in_b[3].vpu_vsew = io_in_3_bits_vpu_vsew;
  assign in_b[3].vpu_vlmul = io_in_3_bits_vpu_vlmul;
  assign in_b[3].vpu_specVill = io_in_3_bits_vpu_specVill;
  assign in_b[3].vpu_specVma = io_in_3_bits_vpu_specVma;
  assign in_b[3].vpu_specVta = io_in_3_bits_vpu_specVta;
  assign in_b[3].vpu_specVsew = io_in_3_bits_vpu_specVsew;
  assign in_b[3].vpu_specVlmul = io_in_3_bits_vpu_specVlmul;
  assign in_b[3].vpu_vm = io_in_3_bits_vpu_vm;
  assign in_b[3].vpu_vstart = io_in_3_bits_vpu_vstart;
  assign in_b[3].vpu_fpu_isFoldTo1_2 = io_in_3_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[3].vpu_fpu_isFoldTo1_4 = io_in_3_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[3].vpu_fpu_isFoldTo1_8 = io_in_3_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[3].vpu_vmask = io_in_3_bits_vpu_vmask;
  assign in_b[3].vpu_nf = io_in_3_bits_vpu_nf;
  assign in_b[3].vpu_veew = io_in_3_bits_vpu_veew;
  assign in_b[3].vpu_isExt = io_in_3_bits_vpu_isExt;
  assign in_b[3].vpu_isNarrow = io_in_3_bits_vpu_isNarrow;
  assign in_b[3].vpu_isDstMask = io_in_3_bits_vpu_isDstMask;
  assign in_b[3].vpu_isOpMask = io_in_3_bits_vpu_isOpMask;
  assign in_b[3].vpu_isDependOldVd = io_in_3_bits_vpu_isDependOldVd;
  assign in_b[3].vpu_isWritePartVd = io_in_3_bits_vpu_isWritePartVd;
  assign in_b[3].vpu_isVleff = io_in_3_bits_vpu_isVleff;
  assign in_b[3].vlsInstr = io_in_3_bits_vlsInstr;
  assign in_b[3].wfflags = io_in_3_bits_wfflags;
  assign in_b[3].isMove = io_in_3_bits_isMove;
  assign in_b[3].uopIdx = io_in_3_bits_uopIdx;
  assign in_b[3].uopSplitType = io_in_3_bits_uopSplitType;
  assign in_b[3].isVset = io_in_3_bits_isVset;
  assign in_b[3].firstUop = io_in_3_bits_firstUop;
  assign in_b[3].lastUop = io_in_3_bits_lastUop;
  assign in_b[3].numWB = io_in_3_bits_numWB;
  assign in_b[3].commitType = io_in_3_bits_commitType;

  // ---- io_in_4 → in_b[4] ----
  assign in_v[4] = io_in_4_valid;
  assign io_in_4_ready = in_r[4];
  assign in_b[4].instr = io_in_4_bits_instr;
  assign in_b[4].exceptionVec = {io_in_4_bits_exceptionVec_23, io_in_4_bits_exceptionVec_22, io_in_4_bits_exceptionVec_21, io_in_4_bits_exceptionVec_20, io_in_4_bits_exceptionVec_19, io_in_4_bits_exceptionVec_18, io_in_4_bits_exceptionVec_17, io_in_4_bits_exceptionVec_16, io_in_4_bits_exceptionVec_15, io_in_4_bits_exceptionVec_14, io_in_4_bits_exceptionVec_13, io_in_4_bits_exceptionVec_12, io_in_4_bits_exceptionVec_11, io_in_4_bits_exceptionVec_10, io_in_4_bits_exceptionVec_9, io_in_4_bits_exceptionVec_8, io_in_4_bits_exceptionVec_7, io_in_4_bits_exceptionVec_6, io_in_4_bits_exceptionVec_5, io_in_4_bits_exceptionVec_4, io_in_4_bits_exceptionVec_3, io_in_4_bits_exceptionVec_2, io_in_4_bits_exceptionVec_1, io_in_4_bits_exceptionVec_0};
  assign in_b[4].isFetchMalAddr = io_in_4_bits_isFetchMalAddr;
  assign in_b[4].trigger = io_in_4_bits_trigger;
  assign in_b[4].preDecodeInfo_isRVC = io_in_4_bits_preDecodeInfo_isRVC;
  assign in_b[4].preDecodeInfo_brType = io_in_4_bits_preDecodeInfo_brType;
  assign in_b[4].pred_taken = io_in_4_bits_pred_taken;
  assign in_b[4].crossPageIPFFix = io_in_4_bits_crossPageIPFFix;
  assign in_b[4].ftqPtr_flag = io_in_4_bits_ftqPtr_flag;
  assign in_b[4].ftqPtr_value = io_in_4_bits_ftqPtr_value;
  assign in_b[4].ftqOffset = io_in_4_bits_ftqOffset;
  assign in_b[4].srcType[0] = io_in_4_bits_srcType_0;
  assign in_b[4].srcType[1] = io_in_4_bits_srcType_1;
  assign in_b[4].srcType[2] = io_in_4_bits_srcType_2;
  assign in_b[4].srcType[3] = io_in_4_bits_srcType_3;
  assign in_b[4].srcType[4] = io_in_4_bits_srcType_4;
  assign in_b[4].lsrc[0] = io_in_4_bits_lsrc_0;
  assign in_b[4].lsrc[1] = io_in_4_bits_lsrc_1;
  assign in_b[4].lsrc[2] = io_in_4_bits_lsrc_2;
  assign in_b[4].lsrc[3] = io_in_4_bits_lsrc_3;
  assign in_b[4].lsrc[4] = io_in_4_bits_lsrc_4;
  assign in_b[4].ldest = io_in_4_bits_ldest;
  assign in_b[4].fuType = io_in_4_bits_fuType;
  assign in_b[4].fuOpType = io_in_4_bits_fuOpType;
  assign in_b[4].rfWen = io_in_4_bits_rfWen;
  assign in_b[4].fpWen = io_in_4_bits_fpWen;
  assign in_b[4].vecWen = io_in_4_bits_vecWen;
  assign in_b[4].v0Wen = io_in_4_bits_v0Wen;
  assign in_b[4].vlWen = io_in_4_bits_vlWen;
  assign in_b[4].isXSTrap = io_in_4_bits_isXSTrap;
  assign in_b[4].waitForward = io_in_4_bits_waitForward;
  assign in_b[4].blockBackward = io_in_4_bits_blockBackward;
  assign in_b[4].flushPipe = io_in_4_bits_flushPipe;
  assign in_b[4].canRobCompress = io_in_4_bits_canRobCompress;
  assign in_b[4].selImm = io_in_4_bits_selImm;
  assign in_b[4].imm = io_in_4_bits_imm;
  assign in_b[4].fpu_typeTagOut = io_in_4_bits_fpu_typeTagOut;
  assign in_b[4].fpu_wflags = io_in_4_bits_fpu_wflags;
  assign in_b[4].fpu_typ = io_in_4_bits_fpu_typ;
  assign in_b[4].fpu_fmt = io_in_4_bits_fpu_fmt;
  assign in_b[4].fpu_rm = io_in_4_bits_fpu_rm;
  assign in_b[4].vpu_vill = io_in_4_bits_vpu_vill;
  assign in_b[4].vpu_vma = io_in_4_bits_vpu_vma;
  assign in_b[4].vpu_vta = io_in_4_bits_vpu_vta;
  assign in_b[4].vpu_vsew = io_in_4_bits_vpu_vsew;
  assign in_b[4].vpu_vlmul = io_in_4_bits_vpu_vlmul;
  assign in_b[4].vpu_specVill = io_in_4_bits_vpu_specVill;
  assign in_b[4].vpu_specVma = io_in_4_bits_vpu_specVma;
  assign in_b[4].vpu_specVta = io_in_4_bits_vpu_specVta;
  assign in_b[4].vpu_specVsew = io_in_4_bits_vpu_specVsew;
  assign in_b[4].vpu_specVlmul = io_in_4_bits_vpu_specVlmul;
  assign in_b[4].vpu_vm = io_in_4_bits_vpu_vm;
  assign in_b[4].vpu_vstart = io_in_4_bits_vpu_vstart;
  assign in_b[4].vpu_fpu_isFoldTo1_2 = io_in_4_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[4].vpu_fpu_isFoldTo1_4 = io_in_4_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[4].vpu_fpu_isFoldTo1_8 = io_in_4_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[4].vpu_vmask = io_in_4_bits_vpu_vmask;
  assign in_b[4].vpu_nf = io_in_4_bits_vpu_nf;
  assign in_b[4].vpu_veew = io_in_4_bits_vpu_veew;
  assign in_b[4].vpu_isExt = io_in_4_bits_vpu_isExt;
  assign in_b[4].vpu_isNarrow = io_in_4_bits_vpu_isNarrow;
  assign in_b[4].vpu_isDstMask = io_in_4_bits_vpu_isDstMask;
  assign in_b[4].vpu_isOpMask = io_in_4_bits_vpu_isOpMask;
  assign in_b[4].vpu_isDependOldVd = io_in_4_bits_vpu_isDependOldVd;
  assign in_b[4].vpu_isWritePartVd = io_in_4_bits_vpu_isWritePartVd;
  assign in_b[4].vpu_isVleff = io_in_4_bits_vpu_isVleff;
  assign in_b[4].vlsInstr = io_in_4_bits_vlsInstr;
  assign in_b[4].wfflags = io_in_4_bits_wfflags;
  assign in_b[4].isMove = io_in_4_bits_isMove;
  assign in_b[4].uopIdx = io_in_4_bits_uopIdx;
  assign in_b[4].uopSplitType = io_in_4_bits_uopSplitType;
  assign in_b[4].isVset = io_in_4_bits_isVset;
  assign in_b[4].firstUop = io_in_4_bits_firstUop;
  assign in_b[4].lastUop = io_in_4_bits_lastUop;
  assign in_b[4].numWB = io_in_4_bits_numWB;
  assign in_b[4].commitType = io_in_4_bits_commitType;

  // ---- io_in_5 → in_b[5] ----
  assign in_v[5] = io_in_5_valid;
  assign io_in_5_ready = in_r[5];
  assign in_b[5].instr = io_in_5_bits_instr;
  assign in_b[5].exceptionVec = {io_in_5_bits_exceptionVec_23, io_in_5_bits_exceptionVec_22, io_in_5_bits_exceptionVec_21, io_in_5_bits_exceptionVec_20, io_in_5_bits_exceptionVec_19, io_in_5_bits_exceptionVec_18, io_in_5_bits_exceptionVec_17, io_in_5_bits_exceptionVec_16, io_in_5_bits_exceptionVec_15, io_in_5_bits_exceptionVec_14, io_in_5_bits_exceptionVec_13, io_in_5_bits_exceptionVec_12, io_in_5_bits_exceptionVec_11, io_in_5_bits_exceptionVec_10, io_in_5_bits_exceptionVec_9, io_in_5_bits_exceptionVec_8, io_in_5_bits_exceptionVec_7, io_in_5_bits_exceptionVec_6, io_in_5_bits_exceptionVec_5, io_in_5_bits_exceptionVec_4, io_in_5_bits_exceptionVec_3, io_in_5_bits_exceptionVec_2, io_in_5_bits_exceptionVec_1, io_in_5_bits_exceptionVec_0};
  assign in_b[5].isFetchMalAddr = io_in_5_bits_isFetchMalAddr;
  assign in_b[5].trigger = io_in_5_bits_trigger;
  assign in_b[5].preDecodeInfo_isRVC = io_in_5_bits_preDecodeInfo_isRVC;
  assign in_b[5].preDecodeInfo_brType = io_in_5_bits_preDecodeInfo_brType;
  assign in_b[5].pred_taken = io_in_5_bits_pred_taken;
  assign in_b[5].crossPageIPFFix = io_in_5_bits_crossPageIPFFix;
  assign in_b[5].ftqPtr_flag = io_in_5_bits_ftqPtr_flag;
  assign in_b[5].ftqPtr_value = io_in_5_bits_ftqPtr_value;
  assign in_b[5].ftqOffset = io_in_5_bits_ftqOffset;
  assign in_b[5].srcType[0] = io_in_5_bits_srcType_0;
  assign in_b[5].srcType[1] = io_in_5_bits_srcType_1;
  assign in_b[5].srcType[2] = io_in_5_bits_srcType_2;
  assign in_b[5].srcType[3] = io_in_5_bits_srcType_3;
  assign in_b[5].srcType[4] = io_in_5_bits_srcType_4;
  assign in_b[5].lsrc[0] = io_in_5_bits_lsrc_0;
  assign in_b[5].lsrc[1] = io_in_5_bits_lsrc_1;
  assign in_b[5].lsrc[2] = io_in_5_bits_lsrc_2;
  assign in_b[5].lsrc[3] = io_in_5_bits_lsrc_3;
  assign in_b[5].lsrc[4] = io_in_5_bits_lsrc_4;
  assign in_b[5].ldest = io_in_5_bits_ldest;
  assign in_b[5].fuType = io_in_5_bits_fuType;
  assign in_b[5].fuOpType = io_in_5_bits_fuOpType;
  assign in_b[5].rfWen = io_in_5_bits_rfWen;
  assign in_b[5].fpWen = io_in_5_bits_fpWen;
  assign in_b[5].vecWen = io_in_5_bits_vecWen;
  assign in_b[5].v0Wen = io_in_5_bits_v0Wen;
  assign in_b[5].vlWen = io_in_5_bits_vlWen;
  assign in_b[5].isXSTrap = io_in_5_bits_isXSTrap;
  assign in_b[5].waitForward = io_in_5_bits_waitForward;
  assign in_b[5].blockBackward = io_in_5_bits_blockBackward;
  assign in_b[5].flushPipe = io_in_5_bits_flushPipe;
  assign in_b[5].canRobCompress = io_in_5_bits_canRobCompress;
  assign in_b[5].selImm = io_in_5_bits_selImm;
  assign in_b[5].imm = io_in_5_bits_imm;
  assign in_b[5].fpu_typeTagOut = io_in_5_bits_fpu_typeTagOut;
  assign in_b[5].fpu_wflags = io_in_5_bits_fpu_wflags;
  assign in_b[5].fpu_typ = io_in_5_bits_fpu_typ;
  assign in_b[5].fpu_fmt = io_in_5_bits_fpu_fmt;
  assign in_b[5].fpu_rm = io_in_5_bits_fpu_rm;
  assign in_b[5].vpu_vill = io_in_5_bits_vpu_vill;
  assign in_b[5].vpu_vma = io_in_5_bits_vpu_vma;
  assign in_b[5].vpu_vta = io_in_5_bits_vpu_vta;
  assign in_b[5].vpu_vsew = io_in_5_bits_vpu_vsew;
  assign in_b[5].vpu_vlmul = io_in_5_bits_vpu_vlmul;
  assign in_b[5].vpu_specVill = io_in_5_bits_vpu_specVill;
  assign in_b[5].vpu_specVma = io_in_5_bits_vpu_specVma;
  assign in_b[5].vpu_specVta = io_in_5_bits_vpu_specVta;
  assign in_b[5].vpu_specVsew = io_in_5_bits_vpu_specVsew;
  assign in_b[5].vpu_specVlmul = io_in_5_bits_vpu_specVlmul;
  assign in_b[5].vpu_vm = io_in_5_bits_vpu_vm;
  assign in_b[5].vpu_vstart = io_in_5_bits_vpu_vstart;
  assign in_b[5].vpu_fpu_isFoldTo1_2 = io_in_5_bits_vpu_fpu_isFoldTo1_2;
  assign in_b[5].vpu_fpu_isFoldTo1_4 = io_in_5_bits_vpu_fpu_isFoldTo1_4;
  assign in_b[5].vpu_fpu_isFoldTo1_8 = io_in_5_bits_vpu_fpu_isFoldTo1_8;
  assign in_b[5].vpu_vmask = io_in_5_bits_vpu_vmask;
  assign in_b[5].vpu_nf = io_in_5_bits_vpu_nf;
  assign in_b[5].vpu_veew = io_in_5_bits_vpu_veew;
  assign in_b[5].vpu_isExt = io_in_5_bits_vpu_isExt;
  assign in_b[5].vpu_isNarrow = io_in_5_bits_vpu_isNarrow;
  assign in_b[5].vpu_isDstMask = io_in_5_bits_vpu_isDstMask;
  assign in_b[5].vpu_isOpMask = io_in_5_bits_vpu_isOpMask;
  assign in_b[5].vpu_isDependOldVd = io_in_5_bits_vpu_isDependOldVd;
  assign in_b[5].vpu_isWritePartVd = io_in_5_bits_vpu_isWritePartVd;
  assign in_b[5].vpu_isVleff = io_in_5_bits_vpu_isVleff;
  assign in_b[5].vlsInstr = io_in_5_bits_vlsInstr;
  assign in_b[5].wfflags = io_in_5_bits_wfflags;
  assign in_b[5].isMove = io_in_5_bits_isMove;
  assign in_b[5].uopIdx = io_in_5_bits_uopIdx;
  assign in_b[5].uopSplitType = io_in_5_bits_uopSplitType;
  assign in_b[5].isVset = io_in_5_bits_isVset;
  assign in_b[5].firstUop = io_in_5_bits_firstUop;
  assign in_b[5].lastUop = io_in_5_bits_lastUop;
  assign in_b[5].numWB = io_in_5_bits_numWB;
  assign in_b[5].commitType = io_in_5_bits_commitType;

  // ---- 标量/向量打平 ----
  assign rab_cv[0] = io_rabCommits_commitValid_0;
  assign rab_wv[0] = io_rabCommits_walkValid_0;
  assign rab_rf[0] = io_rabCommits_info_0_rfWen;
  assign rab_fp[0] = io_rabCommits_info_0_fpWen;
  assign rab_vec[0] = io_rabCommits_info_0_vecWen;
  assign rab_v0[0] = io_rabCommits_info_0_v0Wen;
  assign rab_vl[0] = io_rabCommits_info_0_vlWen;
  assign rab_mv[0] = io_rabCommits_info_0_isMove;
  assign int_nf[0] = io_int_need_free_0;
  assign rab_cv[1] = io_rabCommits_commitValid_1;
  assign rab_wv[1] = io_rabCommits_walkValid_1;
  assign rab_rf[1] = io_rabCommits_info_1_rfWen;
  assign rab_fp[1] = io_rabCommits_info_1_fpWen;
  assign rab_vec[1] = io_rabCommits_info_1_vecWen;
  assign rab_v0[1] = io_rabCommits_info_1_v0Wen;
  assign rab_vl[1] = io_rabCommits_info_1_vlWen;
  assign rab_mv[1] = io_rabCommits_info_1_isMove;
  assign int_nf[1] = io_int_need_free_1;
  assign rab_cv[2] = io_rabCommits_commitValid_2;
  assign rab_wv[2] = io_rabCommits_walkValid_2;
  assign rab_rf[2] = io_rabCommits_info_2_rfWen;
  assign rab_fp[2] = io_rabCommits_info_2_fpWen;
  assign rab_vec[2] = io_rabCommits_info_2_vecWen;
  assign rab_v0[2] = io_rabCommits_info_2_v0Wen;
  assign rab_vl[2] = io_rabCommits_info_2_vlWen;
  assign rab_mv[2] = io_rabCommits_info_2_isMove;
  assign int_nf[2] = io_int_need_free_2;
  assign rab_cv[3] = io_rabCommits_commitValid_3;
  assign rab_wv[3] = io_rabCommits_walkValid_3;
  assign rab_rf[3] = io_rabCommits_info_3_rfWen;
  assign rab_fp[3] = io_rabCommits_info_3_fpWen;
  assign rab_vec[3] = io_rabCommits_info_3_vecWen;
  assign rab_v0[3] = io_rabCommits_info_3_v0Wen;
  assign rab_vl[3] = io_rabCommits_info_3_vlWen;
  assign rab_mv[3] = io_rabCommits_info_3_isMove;
  assign int_nf[3] = io_int_need_free_3;
  assign rab_cv[4] = io_rabCommits_commitValid_4;
  assign rab_wv[4] = io_rabCommits_walkValid_4;
  assign rab_rf[4] = io_rabCommits_info_4_rfWen;
  assign rab_fp[4] = io_rabCommits_info_4_fpWen;
  assign rab_vec[4] = io_rabCommits_info_4_vecWen;
  assign rab_v0[4] = io_rabCommits_info_4_v0Wen;
  assign rab_vl[4] = io_rabCommits_info_4_vlWen;
  assign rab_mv[4] = io_rabCommits_info_4_isMove;
  assign int_nf[4] = io_int_need_free_4;
  assign rab_cv[5] = io_rabCommits_commitValid_5;
  assign rab_wv[5] = io_rabCommits_walkValid_5;
  assign rab_rf[5] = io_rabCommits_info_5_rfWen;
  assign rab_fp[5] = io_rabCommits_info_5_fpWen;
  assign rab_vec[5] = io_rabCommits_info_5_vecWen;
  assign rab_v0[5] = io_rabCommits_info_5_v0Wen;
  assign rab_vl[5] = io_rabCommits_info_5_vlWen;
  assign rab_mv[5] = io_rabCommits_info_5_isMove;
  assign int_nf[5] = io_int_need_free_5;
  assign fi_r1[0] = io_fusionInfo_0_rs2FromRs1;
  assign fi_r2[0] = io_fusionInfo_0_rs2FromRs2;
  assign fi_z[0]  = io_fusionInfo_0_rs2FromZero;
  assign fi_r1[1] = io_fusionInfo_1_rs2FromRs1;
  assign fi_r2[1] = io_fusionInfo_1_rs2FromRs2;
  assign fi_z[1]  = io_fusionInfo_1_rs2FromZero;
  assign fi_r1[2] = io_fusionInfo_2_rs2FromRs1;
  assign fi_r2[2] = io_fusionInfo_2_rs2FromRs2;
  assign fi_z[2]  = io_fusionInfo_2_rs2FromZero;
  assign fi_r1[3] = io_fusionInfo_3_rs2FromRs1;
  assign fi_r2[3] = io_fusionInfo_3_rs2FromRs2;
  assign fi_z[3]  = io_fusionInfo_3_rs2FromZero;
  assign fi_r1[4] = io_fusionInfo_4_rs2FromRs1;
  assign fi_r2[4] = io_fusionInfo_4_rs2FromRs2;
  assign fi_z[4]  = io_fusionInfo_4_rs2FromZero;
  assign fi_r1[5] = 1'b0;
  assign fi_r2[5] = 1'b0;
  assign fi_z[5]  = 1'b0;
  assign intRd[0][0]=io_intReadPorts_0_0; assign intRd[0][1]=io_intReadPorts_0_1;
  assign fpRd[0][0]=io_fpReadPorts_0_0; assign fpRd[0][1]=io_fpReadPorts_0_1; assign fpRd[0][2]=io_fpReadPorts_0_2;
  assign vecRd[0][0]=io_vecReadPorts_0_0; assign vecRd[0][1]=io_vecReadPorts_0_1; assign vecRd[0][2]=io_vecReadPorts_0_2;
  assign v0Rd[0]=io_v0ReadPorts_0_0; assign vlRd[0]=io_vlReadPorts_0_0;
  assign intRd[1][0]=io_intReadPorts_1_0; assign intRd[1][1]=io_intReadPorts_1_1;
  assign fpRd[1][0]=io_fpReadPorts_1_0; assign fpRd[1][1]=io_fpReadPorts_1_1; assign fpRd[1][2]=io_fpReadPorts_1_2;
  assign vecRd[1][0]=io_vecReadPorts_1_0; assign vecRd[1][1]=io_vecReadPorts_1_1; assign vecRd[1][2]=io_vecReadPorts_1_2;
  assign v0Rd[1]=io_v0ReadPorts_1_0; assign vlRd[1]=io_vlReadPorts_1_0;
  assign intRd[2][0]=io_intReadPorts_2_0; assign intRd[2][1]=io_intReadPorts_2_1;
  assign fpRd[2][0]=io_fpReadPorts_2_0; assign fpRd[2][1]=io_fpReadPorts_2_1; assign fpRd[2][2]=io_fpReadPorts_2_2;
  assign vecRd[2][0]=io_vecReadPorts_2_0; assign vecRd[2][1]=io_vecReadPorts_2_1; assign vecRd[2][2]=io_vecReadPorts_2_2;
  assign v0Rd[2]=io_v0ReadPorts_2_0; assign vlRd[2]=io_vlReadPorts_2_0;
  assign intRd[3][0]=io_intReadPorts_3_0; assign intRd[3][1]=io_intReadPorts_3_1;
  assign fpRd[3][0]=io_fpReadPorts_3_0; assign fpRd[3][1]=io_fpReadPorts_3_1; assign fpRd[3][2]=io_fpReadPorts_3_2;
  assign vecRd[3][0]=io_vecReadPorts_3_0; assign vecRd[3][1]=io_vecReadPorts_3_1; assign vecRd[3][2]=io_vecReadPorts_3_2;
  assign v0Rd[3]=io_v0ReadPorts_3_0; assign vlRd[3]=io_vlReadPorts_3_0;
  assign intRd[4][0]=io_intReadPorts_4_0; assign intRd[4][1]=io_intReadPorts_4_1;
  assign fpRd[4][0]=io_fpReadPorts_4_0; assign fpRd[4][1]=io_fpReadPorts_4_1; assign fpRd[4][2]=io_fpReadPorts_4_2;
  assign vecRd[4][0]=io_vecReadPorts_4_0; assign vecRd[4][1]=io_vecReadPorts_4_1; assign vecRd[4][2]=io_vecReadPorts_4_2;
  assign v0Rd[4]=io_v0ReadPorts_4_0; assign vlRd[4]=io_vlReadPorts_4_0;
  assign intRd[5][0]=io_intReadPorts_5_0; assign intRd[5][1]=io_intReadPorts_5_1;
  assign fpRd[5][0]=io_fpReadPorts_5_0; assign fpRd[5][1]=io_fpReadPorts_5_1; assign fpRd[5][2]=io_fpReadPorts_5_2;
  assign vecRd[5][0]=io_vecReadPorts_5_0; assign vecRd[5][1]=io_vecReadPorts_5_1; assign vecRd[5][2]=io_vecReadPorts_5_2;
  assign v0Rd[5]=io_v0ReadPorts_5_0; assign vlRd[5]=io_vlReadPorts_5_0;
  assign int_oldpd[0]=io_int_old_pdest_0; assign fp_oldpd[0]=io_fp_old_pdest_0;
  assign vec_oldpd[0]=io_vec_old_pdest_0; assign v0_oldpd[0]=io_v0_old_pdest_0; assign vl_oldpd[0]=io_vl_old_pdest_0;
  assign int_oldpd[1]=io_int_old_pdest_1; assign fp_oldpd[1]=io_fp_old_pdest_1;
  assign vec_oldpd[1]=io_vec_old_pdest_1; assign v0_oldpd[1]=io_v0_old_pdest_1; assign vl_oldpd[1]=io_vl_old_pdest_1;
  assign int_oldpd[2]=io_int_old_pdest_2; assign fp_oldpd[2]=io_fp_old_pdest_2;
  assign vec_oldpd[2]=io_vec_old_pdest_2; assign v0_oldpd[2]=io_v0_old_pdest_2; assign vl_oldpd[2]=io_vl_old_pdest_2;
  assign int_oldpd[3]=io_int_old_pdest_3; assign fp_oldpd[3]=io_fp_old_pdest_3;
  assign vec_oldpd[3]=io_vec_old_pdest_3; assign v0_oldpd[3]=io_v0_old_pdest_3; assign vl_oldpd[3]=io_vl_old_pdest_3;
  assign int_oldpd[4]=io_int_old_pdest_4; assign fp_oldpd[4]=io_fp_old_pdest_4;
  assign vec_oldpd[4]=io_vec_old_pdest_4; assign v0_oldpd[4]=io_v0_old_pdest_4; assign vl_oldpd[4]=io_vl_old_pdest_4;
  assign int_oldpd[5]=io_int_old_pdest_5; assign fp_oldpd[5]=io_fp_old_pdest_5;
  assign vec_oldpd[5]=io_vec_old_pdest_5; assign v0_oldpd[5]=io_v0_old_pdest_5; assign vl_oldpd[5]=io_vl_old_pdest_5;
  assign sr_in[0] = io_stallReason_in_reason_0;
  assign io_stallReason_out_reason_0 = sr_out[0];
  assign sr_in[1] = io_stallReason_in_reason_1;
  assign io_stallReason_out_reason_1 = sr_out[1];
  assign sr_in[2] = io_stallReason_in_reason_2;
  assign io_stallReason_out_reason_2 = sr_out[2];
  assign sr_in[3] = io_stallReason_in_reason_3;
  assign io_stallReason_out_reason_3 = sr_out[3];
  assign sr_in[4] = io_stallReason_in_reason_4;
  assign io_stallReason_out_reason_4 = sr_out[4];
  assign sr_in[5] = io_stallReason_in_reason_5;
  assign io_stallReason_out_reason_5 = sr_out[5];
  assign flushv = {io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0};
  assign out_r = {io_out_5_ready, io_out_4_ready, io_out_3_ready, io_out_2_ready, io_out_1_ready, io_out_0_ready};

  // ---- 输出重组：85 直通(out_pt) + A批计算字段 ----
  assign io_out_0_valid = out_v[0];
  assign io_out_0_bits_instr = out_pt[0].instr;
  assign io_out_0_bits_exceptionVec_0 = out_pt[0].exceptionVec[0];
  assign io_out_0_bits_exceptionVec_1 = out_pt[0].exceptionVec[1];
  assign io_out_0_bits_exceptionVec_2 = out_pt[0].exceptionVec[2];
  assign io_out_0_bits_exceptionVec_3 = out_pt[0].exceptionVec[3];
  assign io_out_0_bits_exceptionVec_4 = out_pt[0].exceptionVec[4];
  assign io_out_0_bits_exceptionVec_5 = out_pt[0].exceptionVec[5];
  assign io_out_0_bits_exceptionVec_6 = out_pt[0].exceptionVec[6];
  assign io_out_0_bits_exceptionVec_7 = out_pt[0].exceptionVec[7];
  assign io_out_0_bits_exceptionVec_8 = out_pt[0].exceptionVec[8];
  assign io_out_0_bits_exceptionVec_9 = out_pt[0].exceptionVec[9];
  assign io_out_0_bits_exceptionVec_10 = out_pt[0].exceptionVec[10];
  assign io_out_0_bits_exceptionVec_11 = out_pt[0].exceptionVec[11];
  assign io_out_0_bits_exceptionVec_12 = out_pt[0].exceptionVec[12];
  assign io_out_0_bits_exceptionVec_13 = out_pt[0].exceptionVec[13];
  assign io_out_0_bits_exceptionVec_14 = out_pt[0].exceptionVec[14];
  assign io_out_0_bits_exceptionVec_15 = out_pt[0].exceptionVec[15];
  assign io_out_0_bits_exceptionVec_16 = out_pt[0].exceptionVec[16];
  assign io_out_0_bits_exceptionVec_17 = out_pt[0].exceptionVec[17];
  assign io_out_0_bits_exceptionVec_18 = out_pt[0].exceptionVec[18];
  assign io_out_0_bits_exceptionVec_19 = out_pt[0].exceptionVec[19];
  assign io_out_0_bits_exceptionVec_20 = out_pt[0].exceptionVec[20];
  assign io_out_0_bits_exceptionVec_21 = out_pt[0].exceptionVec[21];
  assign io_out_0_bits_exceptionVec_22 = out_pt[0].exceptionVec[22];
  assign io_out_0_bits_exceptionVec_23 = out_pt[0].exceptionVec[23];
  assign io_out_0_bits_isFetchMalAddr = out_pt[0].isFetchMalAddr;
  assign io_out_0_bits_trigger = out_pt[0].trigger;
  assign io_out_0_bits_preDecodeInfo_isRVC = out_pt[0].preDecodeInfo_isRVC;
  assign io_out_0_bits_pred_taken = out_pt[0].pred_taken;
  assign io_out_0_bits_crossPageIPFFix = out_pt[0].crossPageIPFFix;
  assign io_out_0_bits_ftqPtr_flag = out_pt[0].ftqPtr_flag;
  assign io_out_0_bits_ftqPtr_value = out_pt[0].ftqPtr_value;
  assign io_out_0_bits_ftqOffset = out_pt[0].ftqOffset;
  assign io_out_0_bits_srcType_1 = out_pt[0].srcType[1];
  assign io_out_0_bits_srcType_2 = out_pt[0].srcType[2];
  assign io_out_0_bits_srcType_3 = out_pt[0].srcType[3];
  assign io_out_0_bits_srcType_4 = out_pt[0].srcType[4];
  assign io_out_0_bits_ldest = out_pt[0].ldest;
  assign io_out_0_bits_fuType = out_pt[0].fuType;
  assign io_out_0_bits_fuOpType = out_pt[0].fuOpType;
  assign io_out_0_bits_rfWen = out_pt[0].rfWen;
  assign io_out_0_bits_fpWen = out_pt[0].fpWen;
  assign io_out_0_bits_vecWen = out_pt[0].vecWen;
  assign io_out_0_bits_v0Wen = out_pt[0].v0Wen;
  assign io_out_0_bits_vlWen = out_pt[0].vlWen;
  assign io_out_0_bits_isXSTrap = out_pt[0].isXSTrap;
  assign io_out_0_bits_waitForward = out_pt[0].waitForward;
  assign io_out_0_bits_blockBackward = out_pt[0].blockBackward;
  assign io_out_0_bits_flushPipe = out_pt[0].flushPipe;
  assign io_out_0_bits_selImm = out_pt[0].selImm;
  assign io_out_0_bits_fpu_typeTagOut = out_pt[0].fpu_typeTagOut;
  assign io_out_0_bits_fpu_wflags = out_pt[0].fpu_wflags;
  assign io_out_0_bits_fpu_typ = out_pt[0].fpu_typ;
  assign io_out_0_bits_fpu_fmt = out_pt[0].fpu_fmt;
  assign io_out_0_bits_fpu_rm = out_pt[0].fpu_rm;
  assign io_out_0_bits_vpu_vill = out_pt[0].vpu_vill;
  assign io_out_0_bits_vpu_vma = out_pt[0].vpu_vma;
  assign io_out_0_bits_vpu_vta = out_pt[0].vpu_vta;
  assign io_out_0_bits_vpu_vsew = out_pt[0].vpu_vsew;
  assign io_out_0_bits_vpu_vlmul = out_pt[0].vpu_vlmul;
  assign io_out_0_bits_vpu_specVill = out_pt[0].vpu_specVill;
  assign io_out_0_bits_vpu_specVma = out_pt[0].vpu_specVma;
  assign io_out_0_bits_vpu_specVta = out_pt[0].vpu_specVta;
  assign io_out_0_bits_vpu_specVsew = out_pt[0].vpu_specVsew;
  assign io_out_0_bits_vpu_specVlmul = out_pt[0].vpu_specVlmul;
  assign io_out_0_bits_vpu_vm = out_pt[0].vpu_vm;
  assign io_out_0_bits_vpu_vstart = out_pt[0].vpu_vstart;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_2 = out_pt[0].vpu_fpu_isFoldTo1_2;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_4 = out_pt[0].vpu_fpu_isFoldTo1_4;
  assign io_out_0_bits_vpu_fpu_isFoldTo1_8 = out_pt[0].vpu_fpu_isFoldTo1_8;
  assign io_out_0_bits_vpu_vmask = out_pt[0].vpu_vmask;
  assign io_out_0_bits_vpu_nf = out_pt[0].vpu_nf;
  assign io_out_0_bits_vpu_veew = out_pt[0].vpu_veew;
  assign io_out_0_bits_vpu_isExt = out_pt[0].vpu_isExt;
  assign io_out_0_bits_vpu_isNarrow = out_pt[0].vpu_isNarrow;
  assign io_out_0_bits_vpu_isDstMask = out_pt[0].vpu_isDstMask;
  assign io_out_0_bits_vpu_isOpMask = out_pt[0].vpu_isOpMask;
  assign io_out_0_bits_vpu_isDependOldVd = out_pt[0].vpu_isDependOldVd;
  assign io_out_0_bits_vpu_isWritePartVd = out_pt[0].vpu_isWritePartVd;
  assign io_out_0_bits_vpu_isVleff = out_pt[0].vpu_isVleff;
  assign io_out_0_bits_vlsInstr = out_pt[0].vlsInstr;
  assign io_out_0_bits_isMove = out_pt[0].isMove;
  assign io_out_0_bits_uopIdx = out_pt[0].uopIdx;
  assign io_out_0_bits_isVset = out_pt[0].isVset;
  assign io_out_0_bits_firstUop = out_pt[0].firstUop;
  assign io_out_0_bits_commitType = out_pt[0].commitType;
  assign io_out_0_bits_psrc_0 = o_psrc[0][0];
  assign io_out_0_bits_psrc_1 = o_psrc[0][1];
  assign io_out_0_bits_psrc_2 = o_psrc[0][2];
  assign io_out_0_bits_psrc_3 = o_psrc[0][3];
  assign io_out_0_bits_psrc_4 = o_psrc[0][4];
  assign io_out_0_bits_pdest = o_pdest[0];
  assign io_out_0_bits_robIdx_flag = o_robIdx_flag[0];
  assign io_out_0_bits_robIdx_value = o_robIdx_value[0];
  assign io_out_0_bits_eliminatedMove = o_eliminatedMove[0];
  assign io_out_0_bits_snapshot = o_snapshot[0];
  assign io_out_0_bits_hasException = o_hasException[0];
  assign io_out_0_bits_srcType_0 = o_srcType0[0];
  assign io_out_0_bits_imm = o_imm[0];
  assign io_out_0_bits_debugInfo_renameTime = o_renameTime[0];
  assign io_out_0_bits_instrSize = o_instrSize[0];
  assign io_out_0_bits_dirtyFs = o_dirtyFs[0];
  assign io_out_0_bits_dirtyVs = o_dirtyVs[0];
  assign io_out_0_bits_traceBlockInPipe_itype = o_itype[0];
  assign io_out_0_bits_traceBlockInPipe_iretire = o_iretire[0];
  assign io_out_0_bits_traceBlockInPipe_ilastsize = o_ilastsize[0];
  assign io_out_0_bits_lastUop = o_lastUop[0];
  assign io_out_0_bits_numWB = o_numWB[0];
  assign io_out_0_bits_wfflags = o_wfflags[0];
  assign io_out_0_bits_numLsElem = o_numLsElem[0];
  assign io_out_1_valid = out_v[1];
  assign io_out_1_bits_instr = out_pt[1].instr;
  assign io_out_1_bits_exceptionVec_0 = out_pt[1].exceptionVec[0];
  assign io_out_1_bits_exceptionVec_1 = out_pt[1].exceptionVec[1];
  assign io_out_1_bits_exceptionVec_2 = out_pt[1].exceptionVec[2];
  assign io_out_1_bits_exceptionVec_3 = out_pt[1].exceptionVec[3];
  assign io_out_1_bits_exceptionVec_4 = out_pt[1].exceptionVec[4];
  assign io_out_1_bits_exceptionVec_5 = out_pt[1].exceptionVec[5];
  assign io_out_1_bits_exceptionVec_6 = out_pt[1].exceptionVec[6];
  assign io_out_1_bits_exceptionVec_7 = out_pt[1].exceptionVec[7];
  assign io_out_1_bits_exceptionVec_8 = out_pt[1].exceptionVec[8];
  assign io_out_1_bits_exceptionVec_9 = out_pt[1].exceptionVec[9];
  assign io_out_1_bits_exceptionVec_10 = out_pt[1].exceptionVec[10];
  assign io_out_1_bits_exceptionVec_11 = out_pt[1].exceptionVec[11];
  assign io_out_1_bits_exceptionVec_12 = out_pt[1].exceptionVec[12];
  assign io_out_1_bits_exceptionVec_13 = out_pt[1].exceptionVec[13];
  assign io_out_1_bits_exceptionVec_14 = out_pt[1].exceptionVec[14];
  assign io_out_1_bits_exceptionVec_15 = out_pt[1].exceptionVec[15];
  assign io_out_1_bits_exceptionVec_16 = out_pt[1].exceptionVec[16];
  assign io_out_1_bits_exceptionVec_17 = out_pt[1].exceptionVec[17];
  assign io_out_1_bits_exceptionVec_18 = out_pt[1].exceptionVec[18];
  assign io_out_1_bits_exceptionVec_19 = out_pt[1].exceptionVec[19];
  assign io_out_1_bits_exceptionVec_20 = out_pt[1].exceptionVec[20];
  assign io_out_1_bits_exceptionVec_21 = out_pt[1].exceptionVec[21];
  assign io_out_1_bits_exceptionVec_22 = out_pt[1].exceptionVec[22];
  assign io_out_1_bits_exceptionVec_23 = out_pt[1].exceptionVec[23];
  assign io_out_1_bits_isFetchMalAddr = out_pt[1].isFetchMalAddr;
  assign io_out_1_bits_trigger = out_pt[1].trigger;
  assign io_out_1_bits_preDecodeInfo_isRVC = out_pt[1].preDecodeInfo_isRVC;
  assign io_out_1_bits_pred_taken = out_pt[1].pred_taken;
  assign io_out_1_bits_crossPageIPFFix = out_pt[1].crossPageIPFFix;
  assign io_out_1_bits_ftqPtr_flag = out_pt[1].ftqPtr_flag;
  assign io_out_1_bits_ftqPtr_value = out_pt[1].ftqPtr_value;
  assign io_out_1_bits_ftqOffset = out_pt[1].ftqOffset;
  assign io_out_1_bits_srcType_1 = out_pt[1].srcType[1];
  assign io_out_1_bits_srcType_2 = out_pt[1].srcType[2];
  assign io_out_1_bits_srcType_3 = out_pt[1].srcType[3];
  assign io_out_1_bits_srcType_4 = out_pt[1].srcType[4];
  assign io_out_1_bits_ldest = out_pt[1].ldest;
  assign io_out_1_bits_fuType = out_pt[1].fuType;
  assign io_out_1_bits_fuOpType = out_pt[1].fuOpType;
  assign io_out_1_bits_rfWen = out_pt[1].rfWen;
  assign io_out_1_bits_fpWen = out_pt[1].fpWen;
  assign io_out_1_bits_vecWen = out_pt[1].vecWen;
  assign io_out_1_bits_v0Wen = out_pt[1].v0Wen;
  assign io_out_1_bits_vlWen = out_pt[1].vlWen;
  assign io_out_1_bits_isXSTrap = out_pt[1].isXSTrap;
  assign io_out_1_bits_waitForward = out_pt[1].waitForward;
  assign io_out_1_bits_blockBackward = out_pt[1].blockBackward;
  assign io_out_1_bits_flushPipe = out_pt[1].flushPipe;
  assign io_out_1_bits_selImm = out_pt[1].selImm;
  assign io_out_1_bits_fpu_typeTagOut = out_pt[1].fpu_typeTagOut;
  assign io_out_1_bits_fpu_wflags = out_pt[1].fpu_wflags;
  assign io_out_1_bits_fpu_typ = out_pt[1].fpu_typ;
  assign io_out_1_bits_fpu_fmt = out_pt[1].fpu_fmt;
  assign io_out_1_bits_fpu_rm = out_pt[1].fpu_rm;
  assign io_out_1_bits_vpu_vill = out_pt[1].vpu_vill;
  assign io_out_1_bits_vpu_vma = out_pt[1].vpu_vma;
  assign io_out_1_bits_vpu_vta = out_pt[1].vpu_vta;
  assign io_out_1_bits_vpu_vsew = out_pt[1].vpu_vsew;
  assign io_out_1_bits_vpu_vlmul = out_pt[1].vpu_vlmul;
  assign io_out_1_bits_vpu_specVill = out_pt[1].vpu_specVill;
  assign io_out_1_bits_vpu_specVma = out_pt[1].vpu_specVma;
  assign io_out_1_bits_vpu_specVta = out_pt[1].vpu_specVta;
  assign io_out_1_bits_vpu_specVsew = out_pt[1].vpu_specVsew;
  assign io_out_1_bits_vpu_specVlmul = out_pt[1].vpu_specVlmul;
  assign io_out_1_bits_vpu_vm = out_pt[1].vpu_vm;
  assign io_out_1_bits_vpu_vstart = out_pt[1].vpu_vstart;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_2 = out_pt[1].vpu_fpu_isFoldTo1_2;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_4 = out_pt[1].vpu_fpu_isFoldTo1_4;
  assign io_out_1_bits_vpu_fpu_isFoldTo1_8 = out_pt[1].vpu_fpu_isFoldTo1_8;
  assign io_out_1_bits_vpu_vmask = out_pt[1].vpu_vmask;
  assign io_out_1_bits_vpu_nf = out_pt[1].vpu_nf;
  assign io_out_1_bits_vpu_veew = out_pt[1].vpu_veew;
  assign io_out_1_bits_vpu_isExt = out_pt[1].vpu_isExt;
  assign io_out_1_bits_vpu_isNarrow = out_pt[1].vpu_isNarrow;
  assign io_out_1_bits_vpu_isDstMask = out_pt[1].vpu_isDstMask;
  assign io_out_1_bits_vpu_isOpMask = out_pt[1].vpu_isOpMask;
  assign io_out_1_bits_vpu_isDependOldVd = out_pt[1].vpu_isDependOldVd;
  assign io_out_1_bits_vpu_isWritePartVd = out_pt[1].vpu_isWritePartVd;
  assign io_out_1_bits_vpu_isVleff = out_pt[1].vpu_isVleff;
  assign io_out_1_bits_vlsInstr = out_pt[1].vlsInstr;
  assign io_out_1_bits_isMove = out_pt[1].isMove;
  assign io_out_1_bits_uopIdx = out_pt[1].uopIdx;
  assign io_out_1_bits_isVset = out_pt[1].isVset;
  assign io_out_1_bits_firstUop = out_pt[1].firstUop;
  assign io_out_1_bits_commitType = out_pt[1].commitType;
  assign io_out_1_bits_psrc_0 = o_psrc[1][0];
  assign io_out_1_bits_psrc_1 = o_psrc[1][1];
  assign io_out_1_bits_psrc_2 = o_psrc[1][2];
  assign io_out_1_bits_psrc_3 = o_psrc[1][3];
  assign io_out_1_bits_psrc_4 = o_psrc[1][4];
  assign io_out_1_bits_pdest = o_pdest[1];
  assign io_out_1_bits_robIdx_flag = o_robIdx_flag[1];
  assign io_out_1_bits_robIdx_value = o_robIdx_value[1];
  assign io_out_1_bits_eliminatedMove = o_eliminatedMove[1];
  assign io_out_1_bits_snapshot = o_snapshot[1];
  assign io_out_1_bits_hasException = o_hasException[1];
  assign io_out_1_bits_srcType_0 = o_srcType0[1];
  assign io_out_1_bits_imm = o_imm[1];
  assign io_out_1_bits_debugInfo_renameTime = o_renameTime[1];
  assign io_out_1_bits_instrSize = o_instrSize[1];
  assign io_out_1_bits_dirtyFs = o_dirtyFs[1];
  assign io_out_1_bits_dirtyVs = o_dirtyVs[1];
  assign io_out_1_bits_traceBlockInPipe_itype = o_itype[1];
  assign io_out_1_bits_traceBlockInPipe_iretire = o_iretire[1];
  assign io_out_1_bits_traceBlockInPipe_ilastsize = o_ilastsize[1];
  assign io_out_1_bits_lastUop = o_lastUop[1];
  assign io_out_1_bits_numWB = o_numWB[1];
  assign io_out_1_bits_wfflags = o_wfflags[1];
  assign io_out_1_bits_numLsElem = o_numLsElem[1];
  assign io_out_2_valid = out_v[2];
  assign io_out_2_bits_instr = out_pt[2].instr;
  assign io_out_2_bits_exceptionVec_0 = out_pt[2].exceptionVec[0];
  assign io_out_2_bits_exceptionVec_1 = out_pt[2].exceptionVec[1];
  assign io_out_2_bits_exceptionVec_2 = out_pt[2].exceptionVec[2];
  assign io_out_2_bits_exceptionVec_3 = out_pt[2].exceptionVec[3];
  assign io_out_2_bits_exceptionVec_4 = out_pt[2].exceptionVec[4];
  assign io_out_2_bits_exceptionVec_5 = out_pt[2].exceptionVec[5];
  assign io_out_2_bits_exceptionVec_6 = out_pt[2].exceptionVec[6];
  assign io_out_2_bits_exceptionVec_7 = out_pt[2].exceptionVec[7];
  assign io_out_2_bits_exceptionVec_8 = out_pt[2].exceptionVec[8];
  assign io_out_2_bits_exceptionVec_9 = out_pt[2].exceptionVec[9];
  assign io_out_2_bits_exceptionVec_10 = out_pt[2].exceptionVec[10];
  assign io_out_2_bits_exceptionVec_11 = out_pt[2].exceptionVec[11];
  assign io_out_2_bits_exceptionVec_12 = out_pt[2].exceptionVec[12];
  assign io_out_2_bits_exceptionVec_13 = out_pt[2].exceptionVec[13];
  assign io_out_2_bits_exceptionVec_14 = out_pt[2].exceptionVec[14];
  assign io_out_2_bits_exceptionVec_15 = out_pt[2].exceptionVec[15];
  assign io_out_2_bits_exceptionVec_16 = out_pt[2].exceptionVec[16];
  assign io_out_2_bits_exceptionVec_17 = out_pt[2].exceptionVec[17];
  assign io_out_2_bits_exceptionVec_18 = out_pt[2].exceptionVec[18];
  assign io_out_2_bits_exceptionVec_19 = out_pt[2].exceptionVec[19];
  assign io_out_2_bits_exceptionVec_20 = out_pt[2].exceptionVec[20];
  assign io_out_2_bits_exceptionVec_21 = out_pt[2].exceptionVec[21];
  assign io_out_2_bits_exceptionVec_22 = out_pt[2].exceptionVec[22];
  assign io_out_2_bits_exceptionVec_23 = out_pt[2].exceptionVec[23];
  assign io_out_2_bits_isFetchMalAddr = out_pt[2].isFetchMalAddr;
  assign io_out_2_bits_trigger = out_pt[2].trigger;
  assign io_out_2_bits_preDecodeInfo_isRVC = out_pt[2].preDecodeInfo_isRVC;
  assign io_out_2_bits_pred_taken = out_pt[2].pred_taken;
  assign io_out_2_bits_crossPageIPFFix = out_pt[2].crossPageIPFFix;
  assign io_out_2_bits_ftqPtr_flag = out_pt[2].ftqPtr_flag;
  assign io_out_2_bits_ftqPtr_value = out_pt[2].ftqPtr_value;
  assign io_out_2_bits_ftqOffset = out_pt[2].ftqOffset;
  assign io_out_2_bits_srcType_1 = out_pt[2].srcType[1];
  assign io_out_2_bits_srcType_2 = out_pt[2].srcType[2];
  assign io_out_2_bits_srcType_3 = out_pt[2].srcType[3];
  assign io_out_2_bits_srcType_4 = out_pt[2].srcType[4];
  assign io_out_2_bits_ldest = out_pt[2].ldest;
  assign io_out_2_bits_fuType = out_pt[2].fuType;
  assign io_out_2_bits_fuOpType = out_pt[2].fuOpType;
  assign io_out_2_bits_rfWen = out_pt[2].rfWen;
  assign io_out_2_bits_fpWen = out_pt[2].fpWen;
  assign io_out_2_bits_vecWen = out_pt[2].vecWen;
  assign io_out_2_bits_v0Wen = out_pt[2].v0Wen;
  assign io_out_2_bits_vlWen = out_pt[2].vlWen;
  assign io_out_2_bits_isXSTrap = out_pt[2].isXSTrap;
  assign io_out_2_bits_waitForward = out_pt[2].waitForward;
  assign io_out_2_bits_blockBackward = out_pt[2].blockBackward;
  assign io_out_2_bits_flushPipe = out_pt[2].flushPipe;
  assign io_out_2_bits_selImm = out_pt[2].selImm;
  assign io_out_2_bits_fpu_typeTagOut = out_pt[2].fpu_typeTagOut;
  assign io_out_2_bits_fpu_wflags = out_pt[2].fpu_wflags;
  assign io_out_2_bits_fpu_typ = out_pt[2].fpu_typ;
  assign io_out_2_bits_fpu_fmt = out_pt[2].fpu_fmt;
  assign io_out_2_bits_fpu_rm = out_pt[2].fpu_rm;
  assign io_out_2_bits_vpu_vill = out_pt[2].vpu_vill;
  assign io_out_2_bits_vpu_vma = out_pt[2].vpu_vma;
  assign io_out_2_bits_vpu_vta = out_pt[2].vpu_vta;
  assign io_out_2_bits_vpu_vsew = out_pt[2].vpu_vsew;
  assign io_out_2_bits_vpu_vlmul = out_pt[2].vpu_vlmul;
  assign io_out_2_bits_vpu_specVill = out_pt[2].vpu_specVill;
  assign io_out_2_bits_vpu_specVma = out_pt[2].vpu_specVma;
  assign io_out_2_bits_vpu_specVta = out_pt[2].vpu_specVta;
  assign io_out_2_bits_vpu_specVsew = out_pt[2].vpu_specVsew;
  assign io_out_2_bits_vpu_specVlmul = out_pt[2].vpu_specVlmul;
  assign io_out_2_bits_vpu_vm = out_pt[2].vpu_vm;
  assign io_out_2_bits_vpu_vstart = out_pt[2].vpu_vstart;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_2 = out_pt[2].vpu_fpu_isFoldTo1_2;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_4 = out_pt[2].vpu_fpu_isFoldTo1_4;
  assign io_out_2_bits_vpu_fpu_isFoldTo1_8 = out_pt[2].vpu_fpu_isFoldTo1_8;
  assign io_out_2_bits_vpu_vmask = out_pt[2].vpu_vmask;
  assign io_out_2_bits_vpu_nf = out_pt[2].vpu_nf;
  assign io_out_2_bits_vpu_veew = out_pt[2].vpu_veew;
  assign io_out_2_bits_vpu_isExt = out_pt[2].vpu_isExt;
  assign io_out_2_bits_vpu_isNarrow = out_pt[2].vpu_isNarrow;
  assign io_out_2_bits_vpu_isDstMask = out_pt[2].vpu_isDstMask;
  assign io_out_2_bits_vpu_isOpMask = out_pt[2].vpu_isOpMask;
  assign io_out_2_bits_vpu_isDependOldVd = out_pt[2].vpu_isDependOldVd;
  assign io_out_2_bits_vpu_isWritePartVd = out_pt[2].vpu_isWritePartVd;
  assign io_out_2_bits_vpu_isVleff = out_pt[2].vpu_isVleff;
  assign io_out_2_bits_vlsInstr = out_pt[2].vlsInstr;
  assign io_out_2_bits_isMove = out_pt[2].isMove;
  assign io_out_2_bits_uopIdx = out_pt[2].uopIdx;
  assign io_out_2_bits_isVset = out_pt[2].isVset;
  assign io_out_2_bits_firstUop = out_pt[2].firstUop;
  assign io_out_2_bits_commitType = out_pt[2].commitType;
  assign io_out_2_bits_psrc_0 = o_psrc[2][0];
  assign io_out_2_bits_psrc_1 = o_psrc[2][1];
  assign io_out_2_bits_psrc_2 = o_psrc[2][2];
  assign io_out_2_bits_psrc_3 = o_psrc[2][3];
  assign io_out_2_bits_psrc_4 = o_psrc[2][4];
  assign io_out_2_bits_pdest = o_pdest[2];
  assign io_out_2_bits_robIdx_flag = o_robIdx_flag[2];
  assign io_out_2_bits_robIdx_value = o_robIdx_value[2];
  assign io_out_2_bits_eliminatedMove = o_eliminatedMove[2];
  assign io_out_2_bits_snapshot = o_snapshot[2];
  assign io_out_2_bits_hasException = o_hasException[2];
  assign io_out_2_bits_srcType_0 = o_srcType0[2];
  assign io_out_2_bits_imm = o_imm[2];
  assign io_out_2_bits_debugInfo_renameTime = o_renameTime[2];
  assign io_out_2_bits_instrSize = o_instrSize[2];
  assign io_out_2_bits_dirtyFs = o_dirtyFs[2];
  assign io_out_2_bits_dirtyVs = o_dirtyVs[2];
  assign io_out_2_bits_traceBlockInPipe_itype = o_itype[2];
  assign io_out_2_bits_traceBlockInPipe_iretire = o_iretire[2];
  assign io_out_2_bits_traceBlockInPipe_ilastsize = o_ilastsize[2];
  assign io_out_2_bits_lastUop = o_lastUop[2];
  assign io_out_2_bits_numWB = o_numWB[2];
  assign io_out_2_bits_wfflags = o_wfflags[2];
  assign io_out_2_bits_numLsElem = o_numLsElem[2];
  assign io_out_3_valid = out_v[3];
  assign io_out_3_bits_instr = out_pt[3].instr;
  assign io_out_3_bits_exceptionVec_0 = out_pt[3].exceptionVec[0];
  assign io_out_3_bits_exceptionVec_1 = out_pt[3].exceptionVec[1];
  assign io_out_3_bits_exceptionVec_2 = out_pt[3].exceptionVec[2];
  assign io_out_3_bits_exceptionVec_3 = out_pt[3].exceptionVec[3];
  assign io_out_3_bits_exceptionVec_4 = out_pt[3].exceptionVec[4];
  assign io_out_3_bits_exceptionVec_5 = out_pt[3].exceptionVec[5];
  assign io_out_3_bits_exceptionVec_6 = out_pt[3].exceptionVec[6];
  assign io_out_3_bits_exceptionVec_7 = out_pt[3].exceptionVec[7];
  assign io_out_3_bits_exceptionVec_8 = out_pt[3].exceptionVec[8];
  assign io_out_3_bits_exceptionVec_9 = out_pt[3].exceptionVec[9];
  assign io_out_3_bits_exceptionVec_10 = out_pt[3].exceptionVec[10];
  assign io_out_3_bits_exceptionVec_11 = out_pt[3].exceptionVec[11];
  assign io_out_3_bits_exceptionVec_12 = out_pt[3].exceptionVec[12];
  assign io_out_3_bits_exceptionVec_13 = out_pt[3].exceptionVec[13];
  assign io_out_3_bits_exceptionVec_14 = out_pt[3].exceptionVec[14];
  assign io_out_3_bits_exceptionVec_15 = out_pt[3].exceptionVec[15];
  assign io_out_3_bits_exceptionVec_16 = out_pt[3].exceptionVec[16];
  assign io_out_3_bits_exceptionVec_17 = out_pt[3].exceptionVec[17];
  assign io_out_3_bits_exceptionVec_18 = out_pt[3].exceptionVec[18];
  assign io_out_3_bits_exceptionVec_19 = out_pt[3].exceptionVec[19];
  assign io_out_3_bits_exceptionVec_20 = out_pt[3].exceptionVec[20];
  assign io_out_3_bits_exceptionVec_21 = out_pt[3].exceptionVec[21];
  assign io_out_3_bits_exceptionVec_22 = out_pt[3].exceptionVec[22];
  assign io_out_3_bits_exceptionVec_23 = out_pt[3].exceptionVec[23];
  assign io_out_3_bits_isFetchMalAddr = out_pt[3].isFetchMalAddr;
  assign io_out_3_bits_trigger = out_pt[3].trigger;
  assign io_out_3_bits_preDecodeInfo_isRVC = out_pt[3].preDecodeInfo_isRVC;
  assign io_out_3_bits_pred_taken = out_pt[3].pred_taken;
  assign io_out_3_bits_crossPageIPFFix = out_pt[3].crossPageIPFFix;
  assign io_out_3_bits_ftqPtr_flag = out_pt[3].ftqPtr_flag;
  assign io_out_3_bits_ftqPtr_value = out_pt[3].ftqPtr_value;
  assign io_out_3_bits_ftqOffset = out_pt[3].ftqOffset;
  assign io_out_3_bits_srcType_1 = out_pt[3].srcType[1];
  assign io_out_3_bits_srcType_2 = out_pt[3].srcType[2];
  assign io_out_3_bits_srcType_3 = out_pt[3].srcType[3];
  assign io_out_3_bits_srcType_4 = out_pt[3].srcType[4];
  assign io_out_3_bits_ldest = out_pt[3].ldest;
  assign io_out_3_bits_fuType = out_pt[3].fuType;
  assign io_out_3_bits_fuOpType = out_pt[3].fuOpType;
  assign io_out_3_bits_rfWen = out_pt[3].rfWen;
  assign io_out_3_bits_fpWen = out_pt[3].fpWen;
  assign io_out_3_bits_vecWen = out_pt[3].vecWen;
  assign io_out_3_bits_v0Wen = out_pt[3].v0Wen;
  assign io_out_3_bits_vlWen = out_pt[3].vlWen;
  assign io_out_3_bits_isXSTrap = out_pt[3].isXSTrap;
  assign io_out_3_bits_waitForward = out_pt[3].waitForward;
  assign io_out_3_bits_blockBackward = out_pt[3].blockBackward;
  assign io_out_3_bits_flushPipe = out_pt[3].flushPipe;
  assign io_out_3_bits_selImm = out_pt[3].selImm;
  assign io_out_3_bits_fpu_typeTagOut = out_pt[3].fpu_typeTagOut;
  assign io_out_3_bits_fpu_wflags = out_pt[3].fpu_wflags;
  assign io_out_3_bits_fpu_typ = out_pt[3].fpu_typ;
  assign io_out_3_bits_fpu_fmt = out_pt[3].fpu_fmt;
  assign io_out_3_bits_fpu_rm = out_pt[3].fpu_rm;
  assign io_out_3_bits_vpu_vill = out_pt[3].vpu_vill;
  assign io_out_3_bits_vpu_vma = out_pt[3].vpu_vma;
  assign io_out_3_bits_vpu_vta = out_pt[3].vpu_vta;
  assign io_out_3_bits_vpu_vsew = out_pt[3].vpu_vsew;
  assign io_out_3_bits_vpu_vlmul = out_pt[3].vpu_vlmul;
  assign io_out_3_bits_vpu_specVill = out_pt[3].vpu_specVill;
  assign io_out_3_bits_vpu_specVma = out_pt[3].vpu_specVma;
  assign io_out_3_bits_vpu_specVta = out_pt[3].vpu_specVta;
  assign io_out_3_bits_vpu_specVsew = out_pt[3].vpu_specVsew;
  assign io_out_3_bits_vpu_specVlmul = out_pt[3].vpu_specVlmul;
  assign io_out_3_bits_vpu_vm = out_pt[3].vpu_vm;
  assign io_out_3_bits_vpu_vstart = out_pt[3].vpu_vstart;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_2 = out_pt[3].vpu_fpu_isFoldTo1_2;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_4 = out_pt[3].vpu_fpu_isFoldTo1_4;
  assign io_out_3_bits_vpu_fpu_isFoldTo1_8 = out_pt[3].vpu_fpu_isFoldTo1_8;
  assign io_out_3_bits_vpu_vmask = out_pt[3].vpu_vmask;
  assign io_out_3_bits_vpu_nf = out_pt[3].vpu_nf;
  assign io_out_3_bits_vpu_veew = out_pt[3].vpu_veew;
  assign io_out_3_bits_vpu_isExt = out_pt[3].vpu_isExt;
  assign io_out_3_bits_vpu_isNarrow = out_pt[3].vpu_isNarrow;
  assign io_out_3_bits_vpu_isDstMask = out_pt[3].vpu_isDstMask;
  assign io_out_3_bits_vpu_isOpMask = out_pt[3].vpu_isOpMask;
  assign io_out_3_bits_vpu_isDependOldVd = out_pt[3].vpu_isDependOldVd;
  assign io_out_3_bits_vpu_isWritePartVd = out_pt[3].vpu_isWritePartVd;
  assign io_out_3_bits_vpu_isVleff = out_pt[3].vpu_isVleff;
  assign io_out_3_bits_vlsInstr = out_pt[3].vlsInstr;
  assign io_out_3_bits_isMove = out_pt[3].isMove;
  assign io_out_3_bits_uopIdx = out_pt[3].uopIdx;
  assign io_out_3_bits_isVset = out_pt[3].isVset;
  assign io_out_3_bits_firstUop = out_pt[3].firstUop;
  assign io_out_3_bits_commitType = out_pt[3].commitType;
  assign io_out_3_bits_psrc_0 = o_psrc[3][0];
  assign io_out_3_bits_psrc_1 = o_psrc[3][1];
  assign io_out_3_bits_psrc_2 = o_psrc[3][2];
  assign io_out_3_bits_psrc_3 = o_psrc[3][3];
  assign io_out_3_bits_psrc_4 = o_psrc[3][4];
  assign io_out_3_bits_pdest = o_pdest[3];
  assign io_out_3_bits_robIdx_flag = o_robIdx_flag[3];
  assign io_out_3_bits_robIdx_value = o_robIdx_value[3];
  assign io_out_3_bits_eliminatedMove = o_eliminatedMove[3];
  assign io_out_3_bits_snapshot = o_snapshot[3];
  assign io_out_3_bits_hasException = o_hasException[3];
  assign io_out_3_bits_srcType_0 = o_srcType0[3];
  assign io_out_3_bits_imm = o_imm[3];
  assign io_out_3_bits_debugInfo_renameTime = o_renameTime[3];
  assign io_out_3_bits_instrSize = o_instrSize[3];
  assign io_out_3_bits_dirtyFs = o_dirtyFs[3];
  assign io_out_3_bits_dirtyVs = o_dirtyVs[3];
  assign io_out_3_bits_traceBlockInPipe_itype = o_itype[3];
  assign io_out_3_bits_traceBlockInPipe_iretire = o_iretire[3];
  assign io_out_3_bits_traceBlockInPipe_ilastsize = o_ilastsize[3];
  assign io_out_3_bits_lastUop = o_lastUop[3];
  assign io_out_3_bits_numWB = o_numWB[3];
  assign io_out_3_bits_wfflags = o_wfflags[3];
  assign io_out_3_bits_numLsElem = o_numLsElem[3];
  assign io_out_4_valid = out_v[4];
  assign io_out_4_bits_instr = out_pt[4].instr;
  assign io_out_4_bits_exceptionVec_0 = out_pt[4].exceptionVec[0];
  assign io_out_4_bits_exceptionVec_1 = out_pt[4].exceptionVec[1];
  assign io_out_4_bits_exceptionVec_2 = out_pt[4].exceptionVec[2];
  assign io_out_4_bits_exceptionVec_3 = out_pt[4].exceptionVec[3];
  assign io_out_4_bits_exceptionVec_4 = out_pt[4].exceptionVec[4];
  assign io_out_4_bits_exceptionVec_5 = out_pt[4].exceptionVec[5];
  assign io_out_4_bits_exceptionVec_6 = out_pt[4].exceptionVec[6];
  assign io_out_4_bits_exceptionVec_7 = out_pt[4].exceptionVec[7];
  assign io_out_4_bits_exceptionVec_8 = out_pt[4].exceptionVec[8];
  assign io_out_4_bits_exceptionVec_9 = out_pt[4].exceptionVec[9];
  assign io_out_4_bits_exceptionVec_10 = out_pt[4].exceptionVec[10];
  assign io_out_4_bits_exceptionVec_11 = out_pt[4].exceptionVec[11];
  assign io_out_4_bits_exceptionVec_12 = out_pt[4].exceptionVec[12];
  assign io_out_4_bits_exceptionVec_13 = out_pt[4].exceptionVec[13];
  assign io_out_4_bits_exceptionVec_14 = out_pt[4].exceptionVec[14];
  assign io_out_4_bits_exceptionVec_15 = out_pt[4].exceptionVec[15];
  assign io_out_4_bits_exceptionVec_16 = out_pt[4].exceptionVec[16];
  assign io_out_4_bits_exceptionVec_17 = out_pt[4].exceptionVec[17];
  assign io_out_4_bits_exceptionVec_18 = out_pt[4].exceptionVec[18];
  assign io_out_4_bits_exceptionVec_19 = out_pt[4].exceptionVec[19];
  assign io_out_4_bits_exceptionVec_20 = out_pt[4].exceptionVec[20];
  assign io_out_4_bits_exceptionVec_21 = out_pt[4].exceptionVec[21];
  assign io_out_4_bits_exceptionVec_22 = out_pt[4].exceptionVec[22];
  assign io_out_4_bits_exceptionVec_23 = out_pt[4].exceptionVec[23];
  assign io_out_4_bits_isFetchMalAddr = out_pt[4].isFetchMalAddr;
  assign io_out_4_bits_trigger = out_pt[4].trigger;
  assign io_out_4_bits_preDecodeInfo_isRVC = out_pt[4].preDecodeInfo_isRVC;
  assign io_out_4_bits_pred_taken = out_pt[4].pred_taken;
  assign io_out_4_bits_crossPageIPFFix = out_pt[4].crossPageIPFFix;
  assign io_out_4_bits_ftqPtr_flag = out_pt[4].ftqPtr_flag;
  assign io_out_4_bits_ftqPtr_value = out_pt[4].ftqPtr_value;
  assign io_out_4_bits_ftqOffset = out_pt[4].ftqOffset;
  assign io_out_4_bits_srcType_1 = out_pt[4].srcType[1];
  assign io_out_4_bits_srcType_2 = out_pt[4].srcType[2];
  assign io_out_4_bits_srcType_3 = out_pt[4].srcType[3];
  assign io_out_4_bits_srcType_4 = out_pt[4].srcType[4];
  assign io_out_4_bits_ldest = out_pt[4].ldest;
  assign io_out_4_bits_fuType = out_pt[4].fuType;
  assign io_out_4_bits_fuOpType = out_pt[4].fuOpType;
  assign io_out_4_bits_rfWen = out_pt[4].rfWen;
  assign io_out_4_bits_fpWen = out_pt[4].fpWen;
  assign io_out_4_bits_vecWen = out_pt[4].vecWen;
  assign io_out_4_bits_v0Wen = out_pt[4].v0Wen;
  assign io_out_4_bits_vlWen = out_pt[4].vlWen;
  assign io_out_4_bits_isXSTrap = out_pt[4].isXSTrap;
  assign io_out_4_bits_waitForward = out_pt[4].waitForward;
  assign io_out_4_bits_blockBackward = out_pt[4].blockBackward;
  assign io_out_4_bits_flushPipe = out_pt[4].flushPipe;
  assign io_out_4_bits_selImm = out_pt[4].selImm;
  assign io_out_4_bits_fpu_typeTagOut = out_pt[4].fpu_typeTagOut;
  assign io_out_4_bits_fpu_wflags = out_pt[4].fpu_wflags;
  assign io_out_4_bits_fpu_typ = out_pt[4].fpu_typ;
  assign io_out_4_bits_fpu_fmt = out_pt[4].fpu_fmt;
  assign io_out_4_bits_fpu_rm = out_pt[4].fpu_rm;
  assign io_out_4_bits_vpu_vill = out_pt[4].vpu_vill;
  assign io_out_4_bits_vpu_vma = out_pt[4].vpu_vma;
  assign io_out_4_bits_vpu_vta = out_pt[4].vpu_vta;
  assign io_out_4_bits_vpu_vsew = out_pt[4].vpu_vsew;
  assign io_out_4_bits_vpu_vlmul = out_pt[4].vpu_vlmul;
  assign io_out_4_bits_vpu_specVill = out_pt[4].vpu_specVill;
  assign io_out_4_bits_vpu_specVma = out_pt[4].vpu_specVma;
  assign io_out_4_bits_vpu_specVta = out_pt[4].vpu_specVta;
  assign io_out_4_bits_vpu_specVsew = out_pt[4].vpu_specVsew;
  assign io_out_4_bits_vpu_specVlmul = out_pt[4].vpu_specVlmul;
  assign io_out_4_bits_vpu_vm = out_pt[4].vpu_vm;
  assign io_out_4_bits_vpu_vstart = out_pt[4].vpu_vstart;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_2 = out_pt[4].vpu_fpu_isFoldTo1_2;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_4 = out_pt[4].vpu_fpu_isFoldTo1_4;
  assign io_out_4_bits_vpu_fpu_isFoldTo1_8 = out_pt[4].vpu_fpu_isFoldTo1_8;
  assign io_out_4_bits_vpu_vmask = out_pt[4].vpu_vmask;
  assign io_out_4_bits_vpu_nf = out_pt[4].vpu_nf;
  assign io_out_4_bits_vpu_veew = out_pt[4].vpu_veew;
  assign io_out_4_bits_vpu_isExt = out_pt[4].vpu_isExt;
  assign io_out_4_bits_vpu_isNarrow = out_pt[4].vpu_isNarrow;
  assign io_out_4_bits_vpu_isDstMask = out_pt[4].vpu_isDstMask;
  assign io_out_4_bits_vpu_isOpMask = out_pt[4].vpu_isOpMask;
  assign io_out_4_bits_vpu_isDependOldVd = out_pt[4].vpu_isDependOldVd;
  assign io_out_4_bits_vpu_isWritePartVd = out_pt[4].vpu_isWritePartVd;
  assign io_out_4_bits_vpu_isVleff = out_pt[4].vpu_isVleff;
  assign io_out_4_bits_vlsInstr = out_pt[4].vlsInstr;
  assign io_out_4_bits_isMove = out_pt[4].isMove;
  assign io_out_4_bits_uopIdx = out_pt[4].uopIdx;
  assign io_out_4_bits_isVset = out_pt[4].isVset;
  assign io_out_4_bits_firstUop = out_pt[4].firstUop;
  assign io_out_4_bits_commitType = out_pt[4].commitType;
  assign io_out_4_bits_psrc_0 = o_psrc[4][0];
  assign io_out_4_bits_psrc_1 = o_psrc[4][1];
  assign io_out_4_bits_psrc_2 = o_psrc[4][2];
  assign io_out_4_bits_psrc_3 = o_psrc[4][3];
  assign io_out_4_bits_psrc_4 = o_psrc[4][4];
  assign io_out_4_bits_pdest = o_pdest[4];
  assign io_out_4_bits_robIdx_flag = o_robIdx_flag[4];
  assign io_out_4_bits_robIdx_value = o_robIdx_value[4];
  assign io_out_4_bits_eliminatedMove = o_eliminatedMove[4];
  assign io_out_4_bits_snapshot = o_snapshot[4];
  assign io_out_4_bits_hasException = o_hasException[4];
  assign io_out_4_bits_srcType_0 = o_srcType0[4];
  assign io_out_4_bits_imm = o_imm[4];
  assign io_out_4_bits_debugInfo_renameTime = o_renameTime[4];
  assign io_out_4_bits_instrSize = o_instrSize[4];
  assign io_out_4_bits_dirtyFs = o_dirtyFs[4];
  assign io_out_4_bits_dirtyVs = o_dirtyVs[4];
  assign io_out_4_bits_traceBlockInPipe_itype = o_itype[4];
  assign io_out_4_bits_traceBlockInPipe_iretire = o_iretire[4];
  assign io_out_4_bits_traceBlockInPipe_ilastsize = o_ilastsize[4];
  assign io_out_4_bits_lastUop = o_lastUop[4];
  assign io_out_4_bits_numWB = o_numWB[4];
  assign io_out_4_bits_wfflags = o_wfflags[4];
  assign io_out_4_bits_numLsElem = o_numLsElem[4];
  assign io_out_5_valid = out_v[5];
  assign io_out_5_bits_instr = out_pt[5].instr;
  assign io_out_5_bits_exceptionVec_0 = out_pt[5].exceptionVec[0];
  assign io_out_5_bits_exceptionVec_1 = out_pt[5].exceptionVec[1];
  assign io_out_5_bits_exceptionVec_2 = out_pt[5].exceptionVec[2];
  assign io_out_5_bits_exceptionVec_3 = out_pt[5].exceptionVec[3];
  assign io_out_5_bits_exceptionVec_4 = out_pt[5].exceptionVec[4];
  assign io_out_5_bits_exceptionVec_5 = out_pt[5].exceptionVec[5];
  assign io_out_5_bits_exceptionVec_6 = out_pt[5].exceptionVec[6];
  assign io_out_5_bits_exceptionVec_7 = out_pt[5].exceptionVec[7];
  assign io_out_5_bits_exceptionVec_8 = out_pt[5].exceptionVec[8];
  assign io_out_5_bits_exceptionVec_9 = out_pt[5].exceptionVec[9];
  assign io_out_5_bits_exceptionVec_10 = out_pt[5].exceptionVec[10];
  assign io_out_5_bits_exceptionVec_11 = out_pt[5].exceptionVec[11];
  assign io_out_5_bits_exceptionVec_12 = out_pt[5].exceptionVec[12];
  assign io_out_5_bits_exceptionVec_13 = out_pt[5].exceptionVec[13];
  assign io_out_5_bits_exceptionVec_14 = out_pt[5].exceptionVec[14];
  assign io_out_5_bits_exceptionVec_15 = out_pt[5].exceptionVec[15];
  assign io_out_5_bits_exceptionVec_16 = out_pt[5].exceptionVec[16];
  assign io_out_5_bits_exceptionVec_17 = out_pt[5].exceptionVec[17];
  assign io_out_5_bits_exceptionVec_18 = out_pt[5].exceptionVec[18];
  assign io_out_5_bits_exceptionVec_19 = out_pt[5].exceptionVec[19];
  assign io_out_5_bits_exceptionVec_20 = out_pt[5].exceptionVec[20];
  assign io_out_5_bits_exceptionVec_21 = out_pt[5].exceptionVec[21];
  assign io_out_5_bits_exceptionVec_22 = out_pt[5].exceptionVec[22];
  assign io_out_5_bits_exceptionVec_23 = out_pt[5].exceptionVec[23];
  assign io_out_5_bits_isFetchMalAddr = out_pt[5].isFetchMalAddr;
  assign io_out_5_bits_trigger = out_pt[5].trigger;
  assign io_out_5_bits_preDecodeInfo_isRVC = out_pt[5].preDecodeInfo_isRVC;
  assign io_out_5_bits_pred_taken = out_pt[5].pred_taken;
  assign io_out_5_bits_crossPageIPFFix = out_pt[5].crossPageIPFFix;
  assign io_out_5_bits_ftqPtr_flag = out_pt[5].ftqPtr_flag;
  assign io_out_5_bits_ftqPtr_value = out_pt[5].ftqPtr_value;
  assign io_out_5_bits_ftqOffset = out_pt[5].ftqOffset;
  assign io_out_5_bits_srcType_1 = out_pt[5].srcType[1];
  assign io_out_5_bits_srcType_2 = out_pt[5].srcType[2];
  assign io_out_5_bits_srcType_3 = out_pt[5].srcType[3];
  assign io_out_5_bits_srcType_4 = out_pt[5].srcType[4];
  assign io_out_5_bits_ldest = out_pt[5].ldest;
  assign io_out_5_bits_fuType = out_pt[5].fuType;
  assign io_out_5_bits_fuOpType = out_pt[5].fuOpType;
  assign io_out_5_bits_rfWen = out_pt[5].rfWen;
  assign io_out_5_bits_fpWen = out_pt[5].fpWen;
  assign io_out_5_bits_vecWen = out_pt[5].vecWen;
  assign io_out_5_bits_v0Wen = out_pt[5].v0Wen;
  assign io_out_5_bits_vlWen = out_pt[5].vlWen;
  assign io_out_5_bits_isXSTrap = out_pt[5].isXSTrap;
  assign io_out_5_bits_waitForward = out_pt[5].waitForward;
  assign io_out_5_bits_blockBackward = out_pt[5].blockBackward;
  assign io_out_5_bits_flushPipe = out_pt[5].flushPipe;
  assign io_out_5_bits_selImm = out_pt[5].selImm;
  assign io_out_5_bits_fpu_typeTagOut = out_pt[5].fpu_typeTagOut;
  assign io_out_5_bits_fpu_wflags = out_pt[5].fpu_wflags;
  assign io_out_5_bits_fpu_typ = out_pt[5].fpu_typ;
  assign io_out_5_bits_fpu_fmt = out_pt[5].fpu_fmt;
  assign io_out_5_bits_fpu_rm = out_pt[5].fpu_rm;
  assign io_out_5_bits_vpu_vill = out_pt[5].vpu_vill;
  assign io_out_5_bits_vpu_vma = out_pt[5].vpu_vma;
  assign io_out_5_bits_vpu_vta = out_pt[5].vpu_vta;
  assign io_out_5_bits_vpu_vsew = out_pt[5].vpu_vsew;
  assign io_out_5_bits_vpu_vlmul = out_pt[5].vpu_vlmul;
  assign io_out_5_bits_vpu_specVill = out_pt[5].vpu_specVill;
  assign io_out_5_bits_vpu_specVma = out_pt[5].vpu_specVma;
  assign io_out_5_bits_vpu_specVta = out_pt[5].vpu_specVta;
  assign io_out_5_bits_vpu_specVsew = out_pt[5].vpu_specVsew;
  assign io_out_5_bits_vpu_specVlmul = out_pt[5].vpu_specVlmul;
  assign io_out_5_bits_vpu_vm = out_pt[5].vpu_vm;
  assign io_out_5_bits_vpu_vstart = out_pt[5].vpu_vstart;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_2 = out_pt[5].vpu_fpu_isFoldTo1_2;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_4 = out_pt[5].vpu_fpu_isFoldTo1_4;
  assign io_out_5_bits_vpu_fpu_isFoldTo1_8 = out_pt[5].vpu_fpu_isFoldTo1_8;
  assign io_out_5_bits_vpu_vmask = out_pt[5].vpu_vmask;
  assign io_out_5_bits_vpu_nf = out_pt[5].vpu_nf;
  assign io_out_5_bits_vpu_veew = out_pt[5].vpu_veew;
  assign io_out_5_bits_vpu_isExt = out_pt[5].vpu_isExt;
  assign io_out_5_bits_vpu_isNarrow = out_pt[5].vpu_isNarrow;
  assign io_out_5_bits_vpu_isDstMask = out_pt[5].vpu_isDstMask;
  assign io_out_5_bits_vpu_isOpMask = out_pt[5].vpu_isOpMask;
  assign io_out_5_bits_vpu_isDependOldVd = out_pt[5].vpu_isDependOldVd;
  assign io_out_5_bits_vpu_isWritePartVd = out_pt[5].vpu_isWritePartVd;
  assign io_out_5_bits_vpu_isVleff = out_pt[5].vpu_isVleff;
  assign io_out_5_bits_vlsInstr = out_pt[5].vlsInstr;
  assign io_out_5_bits_isMove = out_pt[5].isMove;
  assign io_out_5_bits_uopIdx = out_pt[5].uopIdx;
  assign io_out_5_bits_isVset = out_pt[5].isVset;
  assign io_out_5_bits_firstUop = out_pt[5].firstUop;
  assign io_out_5_bits_commitType = out_pt[5].commitType;
  assign io_out_5_bits_psrc_0 = o_psrc[5][0];
  assign io_out_5_bits_psrc_1 = o_psrc[5][1];
  assign io_out_5_bits_psrc_2 = o_psrc[5][2];
  assign io_out_5_bits_psrc_3 = o_psrc[5][3];
  assign io_out_5_bits_psrc_4 = o_psrc[5][4];
  assign io_out_5_bits_pdest = o_pdest[5];
  assign io_out_5_bits_robIdx_flag = o_robIdx_flag[5];
  assign io_out_5_bits_robIdx_value = o_robIdx_value[5];
  assign io_out_5_bits_eliminatedMove = o_eliminatedMove[5];
  assign io_out_5_bits_snapshot = o_snapshot[5];
  assign io_out_5_bits_hasException = o_hasException[5];
  assign io_out_5_bits_srcType_0 = o_srcType0[5];
  assign io_out_5_bits_imm = o_imm[5];
  assign io_out_5_bits_debugInfo_renameTime = o_renameTime[5];
  assign io_out_5_bits_instrSize = o_instrSize[5];
  assign io_out_5_bits_dirtyFs = o_dirtyFs[5];
  assign io_out_5_bits_dirtyVs = o_dirtyVs[5];
  assign io_out_5_bits_traceBlockInPipe_itype = o_itype[5];
  assign io_out_5_bits_traceBlockInPipe_iretire = o_iretire[5];
  assign io_out_5_bits_traceBlockInPipe_ilastsize = o_ilastsize[5];
  assign io_out_5_bits_lastUop = o_lastUop[5];
  assign io_out_5_bits_numWB = o_numWB[5];
  assign io_out_5_bits_wfflags = o_wfflags[5];
  assign io_out_5_bits_numLsElem = o_numLsElem[5];
  assign io_intRenamePorts_0_wen = intRP[0].wen; assign io_intRenamePorts_0_addr = intRP[0].addr[4:0]; assign io_intRenamePorts_0_data = intRP[0].data;
  assign io_fpRenamePorts_0_wen = fpRP[0].wen; assign io_fpRenamePorts_0_addr = fpRP[0].addr; assign io_fpRenamePorts_0_data = fpRP[0].data;
  assign io_vecRenamePorts_0_wen = vecRP[0].wen; assign io_vecRenamePorts_0_addr = vecRP[0].addr; assign io_vecRenamePorts_0_data = vecRP[0].data;
  assign io_v0RenamePorts_0_wen = v0RP_wen[0]; assign io_v0RenamePorts_0_data = v0RP_data[0];
  assign io_vlRenamePorts_0_wen = vlRP_wen[0]; assign io_vlRenamePorts_0_data = vlRP_data[0];
  assign io_intRenamePorts_1_wen = intRP[1].wen; assign io_intRenamePorts_1_addr = intRP[1].addr[4:0]; assign io_intRenamePorts_1_data = intRP[1].data;
  assign io_fpRenamePorts_1_wen = fpRP[1].wen; assign io_fpRenamePorts_1_addr = fpRP[1].addr; assign io_fpRenamePorts_1_data = fpRP[1].data;
  assign io_vecRenamePorts_1_wen = vecRP[1].wen; assign io_vecRenamePorts_1_addr = vecRP[1].addr; assign io_vecRenamePorts_1_data = vecRP[1].data;
  assign io_v0RenamePorts_1_wen = v0RP_wen[1]; assign io_v0RenamePorts_1_data = v0RP_data[1];
  assign io_vlRenamePorts_1_wen = vlRP_wen[1]; assign io_vlRenamePorts_1_data = vlRP_data[1];
  assign io_intRenamePorts_2_wen = intRP[2].wen; assign io_intRenamePorts_2_addr = intRP[2].addr[4:0]; assign io_intRenamePorts_2_data = intRP[2].data;
  assign io_fpRenamePorts_2_wen = fpRP[2].wen; assign io_fpRenamePorts_2_addr = fpRP[2].addr; assign io_fpRenamePorts_2_data = fpRP[2].data;
  assign io_vecRenamePorts_2_wen = vecRP[2].wen; assign io_vecRenamePorts_2_addr = vecRP[2].addr; assign io_vecRenamePorts_2_data = vecRP[2].data;
  assign io_v0RenamePorts_2_wen = v0RP_wen[2]; assign io_v0RenamePorts_2_data = v0RP_data[2];
  assign io_vlRenamePorts_2_wen = vlRP_wen[2]; assign io_vlRenamePorts_2_data = vlRP_data[2];
  assign io_intRenamePorts_3_wen = intRP[3].wen; assign io_intRenamePorts_3_addr = intRP[3].addr[4:0]; assign io_intRenamePorts_3_data = intRP[3].data;
  assign io_fpRenamePorts_3_wen = fpRP[3].wen; assign io_fpRenamePorts_3_addr = fpRP[3].addr; assign io_fpRenamePorts_3_data = fpRP[3].data;
  assign io_vecRenamePorts_3_wen = vecRP[3].wen; assign io_vecRenamePorts_3_addr = vecRP[3].addr; assign io_vecRenamePorts_3_data = vecRP[3].data;
  assign io_v0RenamePorts_3_wen = v0RP_wen[3]; assign io_v0RenamePorts_3_data = v0RP_data[3];
  assign io_vlRenamePorts_3_wen = vlRP_wen[3]; assign io_vlRenamePorts_3_data = vlRP_data[3];
  assign io_intRenamePorts_4_wen = intRP[4].wen; assign io_intRenamePorts_4_addr = intRP[4].addr[4:0]; assign io_intRenamePorts_4_data = intRP[4].data;
  assign io_fpRenamePorts_4_wen = fpRP[4].wen; assign io_fpRenamePorts_4_addr = fpRP[4].addr; assign io_fpRenamePorts_4_data = fpRP[4].data;
  assign io_vecRenamePorts_4_wen = vecRP[4].wen; assign io_vecRenamePorts_4_addr = vecRP[4].addr; assign io_vecRenamePorts_4_data = vecRP[4].data;
  assign io_v0RenamePorts_4_wen = v0RP_wen[4]; assign io_v0RenamePorts_4_data = v0RP_data[4];
  assign io_vlRenamePorts_4_wen = vlRP_wen[4]; assign io_vlRenamePorts_4_data = vlRP_data[4];
  assign io_intRenamePorts_5_wen = intRP[5].wen; assign io_intRenamePorts_5_addr = intRP[5].addr[4:0]; assign io_intRenamePorts_5_data = intRP[5].data;
  assign io_fpRenamePorts_5_wen = fpRP[5].wen; assign io_fpRenamePorts_5_addr = fpRP[5].addr; assign io_fpRenamePorts_5_data = fpRP[5].data;
  assign io_vecRenamePorts_5_wen = vecRP[5].wen; assign io_vecRenamePorts_5_addr = vecRP[5].addr; assign io_vecRenamePorts_5_data = vecRP[5].data;
  assign io_v0RenamePorts_5_wen = v0RP_wen[5]; assign io_v0RenamePorts_5_data = v0RP_data[5];
  assign io_vlRenamePorts_5_wen = vlRP_wen[5]; assign io_vlRenamePorts_5_data = vlRP_data[5];
  assign io_stallReason_in_backReason_valid = sr_bv;
  assign io_stallReason_in_backReason_bits  = sr_bb;
  assign io_perf_0_value = perf_v[0];
  assign io_perf_1_value = perf_v[1];
  assign io_perf_2_value = perf_v[2];
  assign io_perf_3_value = perf_v[3];
  assign io_perf_4_value = perf_v[4];
  assign io_perf_5_value = perf_v[5];
  assign io_perf_6_value = perf_v[6];
  assign io_perf_7_value = perf_v[7];
  assign io_perf_8_value = perf_v[8];
  assign io_perf_9_value = perf_v[9];
  assign io_perf_10_value = perf_v[10];
  assign io_perf_11_value = perf_v[11];
  assign io_perf_12_value = perf_v[12];
  assign io_perf_13_value = perf_v[13];
  assign io_perf_14_value = perf_v[14];
  assign io_perf_15_value = perf_v[15];
  assign io_perf_16_value = perf_v[16];
  assign io_perf_17_value = perf_v[17];
  assign io_perf_18_value = perf_v[18];
  assign io_perf_19_value = perf_v[19];
  assign io_perf_20_value = perf_v[20];
  assign io_perf_21_value = perf_v[21];
  assign io_perf_22_value = perf_v[22];
  assign io_perf_23_value = perf_v[23];
  assign io_perf_24_value = perf_v[24];
  assign io_perf_25_value = perf_v[25];
  assign io_perf_26_value = perf_v[26];
  assign io_perf_27_value = perf_v[27];
  assign io_perf_28_value = perf_v[28];
  assign io_perf_29_value = perf_v[29];

  xs_Rename_core u_core (
    .clock(clock), .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_isWalk(io_rabCommits_isWalk),
    .io_rabCommits_commitValid(rab_cv), .io_rabCommits_walkValid(rab_wv),
    .io_rabCommits_info_rfWen(rab_rf), .io_rabCommits_info_fpWen(rab_fp),
    .io_rabCommits_info_vecWen(rab_vec), .io_rabCommits_info_v0Wen(rab_v0),
    .io_rabCommits_info_vlWen(rab_vl), .io_rabCommits_info_isMove(rab_mv),
    .io_singleStep(io_singleStep),
    .io_in_bits(in_b), .io_in_valid(in_v), .io_in_ready(in_r),
    .io_fusionInfo_rs2FromRs1(fi_r1), .io_fusionInfo_rs2FromRs2(fi_r2), .io_fusionInfo_rs2FromZero(fi_z),
    .io_intReadPorts(intRd), .io_fpReadPorts(fpRd), .io_vecReadPorts(vecRd),
    .io_v0ReadPorts(v0Rd), .io_vlReadPorts(vlRd),
    .io_intRenamePorts(intRP), .io_fpRenamePorts(fpRP), .io_vecRenamePorts(vecRP),
    .io_v0RenamePorts_wen(v0RP_wen), .io_v0RenamePorts_data(v0RP_data),
    .io_vlRenamePorts_wen(vlRP_wen), .io_vlRenamePorts_data(vlRP_data),
    .io_int_old_pdest(int_oldpd), .io_fp_old_pdest(fp_oldpd), .io_vec_old_pdest(vec_oldpd),
    .io_v0_old_pdest(v0_oldpd), .io_vl_old_pdest(vl_oldpd), .io_int_need_free(int_nf),
    .io_out_valid(out_v), .io_out_ready(out_r), .io_out_passthru(out_pt),
    .io_out_psrc(o_psrc), .io_out_pdest(o_pdest),
    .io_out_robIdx_flag(o_robIdx_flag), .io_out_robIdx_value(o_robIdx_value),
    .io_out_eliminatedMove(o_eliminatedMove), .io_out_snapshot(o_snapshot),
    .io_out_hasException(o_hasException), .io_out_srcType0(o_srcType0),
    .io_out_imm(o_imm), .io_out_debugInfo_renameTime(o_renameTime),
    .io_out_instrSize(o_instrSize), .io_out_dirtyFs(o_dirtyFs), .io_out_dirtyVs(o_dirtyVs),
    .io_out_itype(o_itype), .io_out_iretire(o_iretire), .io_out_ilastsize(o_ilastsize),
    .io_out_lastUop_o(o_lastUop), .io_out_numWB(o_numWB), .io_out_wfflags_o(o_wfflags),
    .io_out_numLsElem(o_numLsElem),
    .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec(flushv),
    .io_snptLastEnq_valid(io_snptLastEnq_valid), .io_snptLastEnq_bits_flag(io_snptLastEnq_bits_flag),
    .io_snptLastEnq_bits_value(io_snptLastEnq_bits_value), .io_snptIsFull(io_snptIsFull),
    .io_stallReason_in_reason(sr_in), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid),
    .io_stallReason_in_backReason_valid(sr_bv), .io_stallReason_in_backReason_bits(sr_bb),
    .io_stallReason_out_reason(sr_out), .io_perf_value(perf_v)
  );
endmodule