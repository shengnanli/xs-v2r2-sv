// =============================================================================
// DecodeUnit UT —— golden DecodeUnit 对重写 DecodeUnit_xs 双例化，同激励逐拍比对全部
// 101 根输出线。本文件由 verif/ut/DecodeUnit/gen.py 生成（幂等），不要手改。
//
// ★ 被测件是纯组合译码器：判别力全在「指令编码空间」上 ★
//   · 均匀随机 32 位字几乎只会落进"非法"一行（表里 700 多条指令的编码密度极低），
//     所以主激励是：随机挑一条表项，把它的 `?` 位随机填满 —— 每条表项都被命中过才算数；
//   · 再定向打那些"表之外"的判据：csrr vl / csrr vlenb（转 vsetvl/addi）、prefetch.{i,r,w}、
//     fli、zimop、cbo、TRAP、amocas.q 奇数寄存器、aes64ks1i 保留 rnum、NF!=0 的向量访存等；
//   · 剩余份额给全随机字（非法指令路径）。
//   · fromCSR 的 24 个标志、vtype、vstart、singlestep、isLastInFtqEntry 每拍全随机，
//     让异常判据里每个 && 的两边都有 0/1。
// 覆盖判据：表里每条**可达**的指令（前面没有更宽的模式把它整个遮住）命中次数 ≥ 1，
// 否则这一轮 errors=0 不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）----
  logic [31:0] io_enq_ctrlFlow_instr;
  logic [49:0] io_enq_ctrlFlow_pc;
  logic [9:0] io_enq_ctrlFlow_foldpc;
  logic       io_enq_ctrlFlow_exceptionVec_0;
  logic       io_enq_ctrlFlow_exceptionVec_1;
  logic       io_enq_ctrlFlow_exceptionVec_2;
  logic       io_enq_ctrlFlow_exceptionVec_4;
  logic       io_enq_ctrlFlow_exceptionVec_5;
  logic       io_enq_ctrlFlow_exceptionVec_6;
  logic       io_enq_ctrlFlow_exceptionVec_7;
  logic       io_enq_ctrlFlow_exceptionVec_8;
  logic       io_enq_ctrlFlow_exceptionVec_9;
  logic       io_enq_ctrlFlow_exceptionVec_10;
  logic       io_enq_ctrlFlow_exceptionVec_11;
  logic       io_enq_ctrlFlow_exceptionVec_12;
  logic       io_enq_ctrlFlow_exceptionVec_13;
  logic       io_enq_ctrlFlow_exceptionVec_14;
  logic       io_enq_ctrlFlow_exceptionVec_15;
  logic       io_enq_ctrlFlow_exceptionVec_16;
  logic       io_enq_ctrlFlow_exceptionVec_17;
  logic       io_enq_ctrlFlow_exceptionVec_18;
  logic       io_enq_ctrlFlow_exceptionVec_19;
  logic       io_enq_ctrlFlow_exceptionVec_20;
  logic       io_enq_ctrlFlow_exceptionVec_21;
  logic       io_enq_ctrlFlow_exceptionVec_23;
  logic       io_enq_ctrlFlow_isFetchMalAddr;
  logic [3:0] io_enq_ctrlFlow_trigger;
  logic       io_enq_ctrlFlow_preDecodeInfo_valid;
  logic       io_enq_ctrlFlow_preDecodeInfo_isRVC;
  logic [1:0] io_enq_ctrlFlow_preDecodeInfo_brType;
  logic       io_enq_ctrlFlow_preDecodeInfo_isCall;
  logic       io_enq_ctrlFlow_preDecodeInfo_isRet;
  logic       io_enq_ctrlFlow_pred_taken;
  logic       io_enq_ctrlFlow_crossPageIPFFix;
  logic       io_enq_ctrlFlow_ftqPtr_flag;
  logic [5:0] io_enq_ctrlFlow_ftqPtr_value;
  logic [3:0] io_enq_ctrlFlow_ftqOffset;
  logic       io_enq_ctrlFlow_isLastInFtqEntry;
  logic [55:0] io_enq_ctrlFlow_debug_seqNum_seqNum;
  logic [7:0] io_enq_ctrlFlow_debug_seqNum_uopIdx;
  logic       io_enq_ctrlFlow_satpFlushFirstFetchFault;
  logic       io_enq_vtype_illegal;
  logic       io_enq_vtype_vma;
  logic       io_enq_vtype_vta;
  logic [1:0] io_enq_vtype_vsew;
  logic [2:0] io_enq_vtype_vlmul;
  logic [7:0] io_enq_vstart;
  logic       io_csrCtrl_singlestep;
  logic       io_fromCSR_illegalInst_sfenceVMA;
  logic       io_fromCSR_illegalInst_sfencePart;
  logic       io_fromCSR_illegalInst_hfenceGVMA;
  logic       io_fromCSR_illegalInst_hfenceVVMA;
  logic       io_fromCSR_illegalInst_hlsv;
  logic       io_fromCSR_illegalInst_fsIsOff;
  logic       io_fromCSR_illegalInst_vsIsOff;
  logic       io_fromCSR_illegalInst_wfi;
  logic       io_fromCSR_illegalInst_wrs_nto;
  logic       io_fromCSR_illegalInst_frm;
  logic       io_fromCSR_illegalInst_cboZ;
  logic       io_fromCSR_illegalInst_cboCF;
  logic       io_fromCSR_illegalInst_cboI;
  logic       io_fromCSR_virtualInst_sfenceVMA;
  logic       io_fromCSR_virtualInst_sfencePart;
  logic       io_fromCSR_virtualInst_hfence;
  logic       io_fromCSR_virtualInst_hlsv;
  logic       io_fromCSR_virtualInst_wfi;
  logic       io_fromCSR_virtualInst_wrs_nto;
  logic       io_fromCSR_virtualInst_cboZ;
  logic       io_fromCSR_virtualInst_cboCF;
  logic       io_fromCSR_virtualInst_cboI;
  logic       io_fromCSR_special_cboI2F;

  // ---- 输出（各一份）----
  logic [31:0] g_io_deq_decodedInst_instr, x_io_deq_decodedInst_instr;
  logic [49:0] g_io_deq_decodedInst_pc, x_io_deq_decodedInst_pc;
  logic [9:0] g_io_deq_decodedInst_foldpc, x_io_deq_decodedInst_foldpc;
  logic       g_io_deq_decodedInst_exceptionVec_0, x_io_deq_decodedInst_exceptionVec_0;
  logic       g_io_deq_decodedInst_exceptionVec_1, x_io_deq_decodedInst_exceptionVec_1;
  logic       g_io_deq_decodedInst_exceptionVec_2, x_io_deq_decodedInst_exceptionVec_2;
  logic       g_io_deq_decodedInst_exceptionVec_3, x_io_deq_decodedInst_exceptionVec_3;
  logic       g_io_deq_decodedInst_exceptionVec_4, x_io_deq_decodedInst_exceptionVec_4;
  logic       g_io_deq_decodedInst_exceptionVec_5, x_io_deq_decodedInst_exceptionVec_5;
  logic       g_io_deq_decodedInst_exceptionVec_6, x_io_deq_decodedInst_exceptionVec_6;
  logic       g_io_deq_decodedInst_exceptionVec_7, x_io_deq_decodedInst_exceptionVec_7;
  logic       g_io_deq_decodedInst_exceptionVec_8, x_io_deq_decodedInst_exceptionVec_8;
  logic       g_io_deq_decodedInst_exceptionVec_9, x_io_deq_decodedInst_exceptionVec_9;
  logic       g_io_deq_decodedInst_exceptionVec_10, x_io_deq_decodedInst_exceptionVec_10;
  logic       g_io_deq_decodedInst_exceptionVec_11, x_io_deq_decodedInst_exceptionVec_11;
  logic       g_io_deq_decodedInst_exceptionVec_12, x_io_deq_decodedInst_exceptionVec_12;
  logic       g_io_deq_decodedInst_exceptionVec_13, x_io_deq_decodedInst_exceptionVec_13;
  logic       g_io_deq_decodedInst_exceptionVec_14, x_io_deq_decodedInst_exceptionVec_14;
  logic       g_io_deq_decodedInst_exceptionVec_15, x_io_deq_decodedInst_exceptionVec_15;
  logic       g_io_deq_decodedInst_exceptionVec_16, x_io_deq_decodedInst_exceptionVec_16;
  logic       g_io_deq_decodedInst_exceptionVec_17, x_io_deq_decodedInst_exceptionVec_17;
  logic       g_io_deq_decodedInst_exceptionVec_18, x_io_deq_decodedInst_exceptionVec_18;
  logic       g_io_deq_decodedInst_exceptionVec_19, x_io_deq_decodedInst_exceptionVec_19;
  logic       g_io_deq_decodedInst_exceptionVec_20, x_io_deq_decodedInst_exceptionVec_20;
  logic       g_io_deq_decodedInst_exceptionVec_21, x_io_deq_decodedInst_exceptionVec_21;
  logic       g_io_deq_decodedInst_exceptionVec_22, x_io_deq_decodedInst_exceptionVec_22;
  logic       g_io_deq_decodedInst_exceptionVec_23, x_io_deq_decodedInst_exceptionVec_23;
  logic       g_io_deq_decodedInst_isFetchMalAddr, x_io_deq_decodedInst_isFetchMalAddr;
  logic [3:0] g_io_deq_decodedInst_trigger, x_io_deq_decodedInst_trigger;
  logic       g_io_deq_decodedInst_preDecodeInfo_valid, x_io_deq_decodedInst_preDecodeInfo_valid;
  logic       g_io_deq_decodedInst_preDecodeInfo_isRVC, x_io_deq_decodedInst_preDecodeInfo_isRVC;
  logic [1:0] g_io_deq_decodedInst_preDecodeInfo_brType, x_io_deq_decodedInst_preDecodeInfo_brType;
  logic       g_io_deq_decodedInst_preDecodeInfo_isCall, x_io_deq_decodedInst_preDecodeInfo_isCall;
  logic       g_io_deq_decodedInst_preDecodeInfo_isRet, x_io_deq_decodedInst_preDecodeInfo_isRet;
  logic       g_io_deq_decodedInst_pred_taken, x_io_deq_decodedInst_pred_taken;
  logic       g_io_deq_decodedInst_crossPageIPFFix, x_io_deq_decodedInst_crossPageIPFFix;
  logic       g_io_deq_decodedInst_ftqPtr_flag, x_io_deq_decodedInst_ftqPtr_flag;
  logic [5:0] g_io_deq_decodedInst_ftqPtr_value, x_io_deq_decodedInst_ftqPtr_value;
  logic [3:0] g_io_deq_decodedInst_ftqOffset, x_io_deq_decodedInst_ftqOffset;
  logic       g_io_deq_decodedInst_satpFlushFirstFetchFault, x_io_deq_decodedInst_satpFlushFirstFetchFault;
  logic [3:0] g_io_deq_decodedInst_srcType_0, x_io_deq_decodedInst_srcType_0;
  logic [3:0] g_io_deq_decodedInst_srcType_1, x_io_deq_decodedInst_srcType_1;
  logic [3:0] g_io_deq_decodedInst_srcType_2, x_io_deq_decodedInst_srcType_2;
  logic [3:0] g_io_deq_decodedInst_srcType_3, x_io_deq_decodedInst_srcType_3;
  logic [3:0] g_io_deq_decodedInst_srcType_4, x_io_deq_decodedInst_srcType_4;
  logic [5:0] g_io_deq_decodedInst_lsrc_0, x_io_deq_decodedInst_lsrc_0;
  logic [5:0] g_io_deq_decodedInst_lsrc_1, x_io_deq_decodedInst_lsrc_1;
  logic [5:0] g_io_deq_decodedInst_lsrc_2, x_io_deq_decodedInst_lsrc_2;
  logic [5:0] g_io_deq_decodedInst_ldest, x_io_deq_decodedInst_ldest;
  logic [34:0] g_io_deq_decodedInst_fuType, x_io_deq_decodedInst_fuType;
  logic [8:0] g_io_deq_decodedInst_fuOpType, x_io_deq_decodedInst_fuOpType;
  logic       g_io_deq_decodedInst_rfWen, x_io_deq_decodedInst_rfWen;
  logic       g_io_deq_decodedInst_fpWen, x_io_deq_decodedInst_fpWen;
  logic       g_io_deq_decodedInst_vecWen, x_io_deq_decodedInst_vecWen;
  logic       g_io_deq_decodedInst_isXSTrap, x_io_deq_decodedInst_isXSTrap;
  logic       g_io_deq_decodedInst_waitForward, x_io_deq_decodedInst_waitForward;
  logic       g_io_deq_decodedInst_blockBackward, x_io_deq_decodedInst_blockBackward;
  logic       g_io_deq_decodedInst_flushPipe, x_io_deq_decodedInst_flushPipe;
  logic       g_io_deq_decodedInst_canRobCompress, x_io_deq_decodedInst_canRobCompress;
  logic [3:0] g_io_deq_decodedInst_selImm, x_io_deq_decodedInst_selImm;
  logic [21:0] g_io_deq_decodedInst_imm, x_io_deq_decodedInst_imm;
  logic [1:0] g_io_deq_decodedInst_fpu_typeTagOut, x_io_deq_decodedInst_fpu_typeTagOut;
  logic       g_io_deq_decodedInst_fpu_wflags, x_io_deq_decodedInst_fpu_wflags;
  logic [1:0] g_io_deq_decodedInst_fpu_typ, x_io_deq_decodedInst_fpu_typ;
  logic [1:0] g_io_deq_decodedInst_fpu_fmt, x_io_deq_decodedInst_fpu_fmt;
  logic [2:0] g_io_deq_decodedInst_fpu_rm, x_io_deq_decodedInst_fpu_rm;
  logic       g_io_deq_decodedInst_vpu_vill, x_io_deq_decodedInst_vpu_vill;
  logic       g_io_deq_decodedInst_vpu_vma, x_io_deq_decodedInst_vpu_vma;
  logic       g_io_deq_decodedInst_vpu_vta, x_io_deq_decodedInst_vpu_vta;
  logic [1:0] g_io_deq_decodedInst_vpu_vsew, x_io_deq_decodedInst_vpu_vsew;
  logic [2:0] g_io_deq_decodedInst_vpu_vlmul, x_io_deq_decodedInst_vpu_vlmul;
  logic       g_io_deq_decodedInst_vpu_specVill, x_io_deq_decodedInst_vpu_specVill;
  logic       g_io_deq_decodedInst_vpu_specVma, x_io_deq_decodedInst_vpu_specVma;
  logic       g_io_deq_decodedInst_vpu_specVta, x_io_deq_decodedInst_vpu_specVta;
  logic [1:0] g_io_deq_decodedInst_vpu_specVsew, x_io_deq_decodedInst_vpu_specVsew;
  logic [2:0] g_io_deq_decodedInst_vpu_specVlmul, x_io_deq_decodedInst_vpu_specVlmul;
  logic       g_io_deq_decodedInst_vpu_vm, x_io_deq_decodedInst_vpu_vm;
  logic [7:0] g_io_deq_decodedInst_vpu_vstart, x_io_deq_decodedInst_vpu_vstart;
  logic [2:0] g_io_deq_decodedInst_vpu_nf, x_io_deq_decodedInst_vpu_nf;
  logic [1:0] g_io_deq_decodedInst_vpu_veew, x_io_deq_decodedInst_vpu_veew;
  logic       g_io_deq_decodedInst_vpu_isReverse, x_io_deq_decodedInst_vpu_isReverse;
  logic       g_io_deq_decodedInst_vpu_isExt, x_io_deq_decodedInst_vpu_isExt;
  logic       g_io_deq_decodedInst_vpu_isNarrow, x_io_deq_decodedInst_vpu_isNarrow;
  logic       g_io_deq_decodedInst_vpu_isDstMask, x_io_deq_decodedInst_vpu_isDstMask;
  logic       g_io_deq_decodedInst_vpu_isOpMask, x_io_deq_decodedInst_vpu_isOpMask;
  logic       g_io_deq_decodedInst_vpu_isDependOldVd, x_io_deq_decodedInst_vpu_isDependOldVd;
  logic       g_io_deq_decodedInst_vpu_isWritePartVd, x_io_deq_decodedInst_vpu_isWritePartVd;
  logic       g_io_deq_decodedInst_vpu_isVleff, x_io_deq_decodedInst_vpu_isVleff;
  logic       g_io_deq_decodedInst_vlsInstr, x_io_deq_decodedInst_vlsInstr;
  logic       g_io_deq_decodedInst_wfflags, x_io_deq_decodedInst_wfflags;
  logic       g_io_deq_decodedInst_isMove, x_io_deq_decodedInst_isMove;
  logic [5:0] g_io_deq_decodedInst_uopSplitType, x_io_deq_decodedInst_uopSplitType;
  logic       g_io_deq_decodedInst_isVset, x_io_deq_decodedInst_isVset;
  logic [2:0] g_io_deq_decodedInst_commitType, x_io_deq_decodedInst_commitType;
  logic [34:0] g_io_deq_decodedInst_debug_fuType, x_io_deq_decodedInst_debug_fuType;
  logic [55:0] g_io_deq_decodedInst_debug_seqNum_seqNum, x_io_deq_decodedInst_debug_seqNum_seqNum;
  logic [7:0] g_io_deq_decodedInst_debug_seqNum_uopIdx, x_io_deq_decodedInst_debug_seqNum_uopIdx;
  logic       g_io_deq_isComplex, x_io_deq_isComplex;
  logic [6:0] g_io_deq_uopInfo_numOfUop, x_io_deq_uopInfo_numOfUop;
  logic [6:0] g_io_deq_uopInfo_numOfWB, x_io_deq_uopInfo_numOfWB;
  logic [3:0] g_io_deq_uopInfo_lmul, x_io_deq_uopInfo_lmul;

  DecodeUnit u_g (
    .io_enq_ctrlFlow_instr(io_enq_ctrlFlow_instr),
    .io_enq_ctrlFlow_pc(io_enq_ctrlFlow_pc),
    .io_enq_ctrlFlow_foldpc(io_enq_ctrlFlow_foldpc),
    .io_enq_ctrlFlow_exceptionVec_0(io_enq_ctrlFlow_exceptionVec_0),
    .io_enq_ctrlFlow_exceptionVec_1(io_enq_ctrlFlow_exceptionVec_1),
    .io_enq_ctrlFlow_exceptionVec_2(io_enq_ctrlFlow_exceptionVec_2),
    .io_enq_ctrlFlow_exceptionVec_4(io_enq_ctrlFlow_exceptionVec_4),
    .io_enq_ctrlFlow_exceptionVec_5(io_enq_ctrlFlow_exceptionVec_5),
    .io_enq_ctrlFlow_exceptionVec_6(io_enq_ctrlFlow_exceptionVec_6),
    .io_enq_ctrlFlow_exceptionVec_7(io_enq_ctrlFlow_exceptionVec_7),
    .io_enq_ctrlFlow_exceptionVec_8(io_enq_ctrlFlow_exceptionVec_8),
    .io_enq_ctrlFlow_exceptionVec_9(io_enq_ctrlFlow_exceptionVec_9),
    .io_enq_ctrlFlow_exceptionVec_10(io_enq_ctrlFlow_exceptionVec_10),
    .io_enq_ctrlFlow_exceptionVec_11(io_enq_ctrlFlow_exceptionVec_11),
    .io_enq_ctrlFlow_exceptionVec_12(io_enq_ctrlFlow_exceptionVec_12),
    .io_enq_ctrlFlow_exceptionVec_13(io_enq_ctrlFlow_exceptionVec_13),
    .io_enq_ctrlFlow_exceptionVec_14(io_enq_ctrlFlow_exceptionVec_14),
    .io_enq_ctrlFlow_exceptionVec_15(io_enq_ctrlFlow_exceptionVec_15),
    .io_enq_ctrlFlow_exceptionVec_16(io_enq_ctrlFlow_exceptionVec_16),
    .io_enq_ctrlFlow_exceptionVec_17(io_enq_ctrlFlow_exceptionVec_17),
    .io_enq_ctrlFlow_exceptionVec_18(io_enq_ctrlFlow_exceptionVec_18),
    .io_enq_ctrlFlow_exceptionVec_19(io_enq_ctrlFlow_exceptionVec_19),
    .io_enq_ctrlFlow_exceptionVec_20(io_enq_ctrlFlow_exceptionVec_20),
    .io_enq_ctrlFlow_exceptionVec_21(io_enq_ctrlFlow_exceptionVec_21),
    .io_enq_ctrlFlow_exceptionVec_23(io_enq_ctrlFlow_exceptionVec_23),
    .io_enq_ctrlFlow_isFetchMalAddr(io_enq_ctrlFlow_isFetchMalAddr),
    .io_enq_ctrlFlow_trigger(io_enq_ctrlFlow_trigger),
    .io_enq_ctrlFlow_preDecodeInfo_valid(io_enq_ctrlFlow_preDecodeInfo_valid),
    .io_enq_ctrlFlow_preDecodeInfo_isRVC(io_enq_ctrlFlow_preDecodeInfo_isRVC),
    .io_enq_ctrlFlow_preDecodeInfo_brType(io_enq_ctrlFlow_preDecodeInfo_brType),
    .io_enq_ctrlFlow_preDecodeInfo_isCall(io_enq_ctrlFlow_preDecodeInfo_isCall),
    .io_enq_ctrlFlow_preDecodeInfo_isRet(io_enq_ctrlFlow_preDecodeInfo_isRet),
    .io_enq_ctrlFlow_pred_taken(io_enq_ctrlFlow_pred_taken),
    .io_enq_ctrlFlow_crossPageIPFFix(io_enq_ctrlFlow_crossPageIPFFix),
    .io_enq_ctrlFlow_ftqPtr_flag(io_enq_ctrlFlow_ftqPtr_flag),
    .io_enq_ctrlFlow_ftqPtr_value(io_enq_ctrlFlow_ftqPtr_value),
    .io_enq_ctrlFlow_ftqOffset(io_enq_ctrlFlow_ftqOffset),
    .io_enq_ctrlFlow_isLastInFtqEntry(io_enq_ctrlFlow_isLastInFtqEntry),
    .io_enq_ctrlFlow_debug_seqNum_seqNum(io_enq_ctrlFlow_debug_seqNum_seqNum),
    .io_enq_ctrlFlow_debug_seqNum_uopIdx(io_enq_ctrlFlow_debug_seqNum_uopIdx),
    .io_enq_ctrlFlow_satpFlushFirstFetchFault(io_enq_ctrlFlow_satpFlushFirstFetchFault),
    .io_enq_vtype_illegal(io_enq_vtype_illegal),
    .io_enq_vtype_vma(io_enq_vtype_vma),
    .io_enq_vtype_vta(io_enq_vtype_vta),
    .io_enq_vtype_vsew(io_enq_vtype_vsew),
    .io_enq_vtype_vlmul(io_enq_vtype_vlmul),
    .io_enq_vstart(io_enq_vstart),
    .io_csrCtrl_singlestep(io_csrCtrl_singlestep),
    .io_fromCSR_illegalInst_sfenceVMA(io_fromCSR_illegalInst_sfenceVMA),
    .io_fromCSR_illegalInst_sfencePart(io_fromCSR_illegalInst_sfencePart),
    .io_fromCSR_illegalInst_hfenceGVMA(io_fromCSR_illegalInst_hfenceGVMA),
    .io_fromCSR_illegalInst_hfenceVVMA(io_fromCSR_illegalInst_hfenceVVMA),
    .io_fromCSR_illegalInst_hlsv(io_fromCSR_illegalInst_hlsv),
    .io_fromCSR_illegalInst_fsIsOff(io_fromCSR_illegalInst_fsIsOff),
    .io_fromCSR_illegalInst_vsIsOff(io_fromCSR_illegalInst_vsIsOff),
    .io_fromCSR_illegalInst_wfi(io_fromCSR_illegalInst_wfi),
    .io_fromCSR_illegalInst_wrs_nto(io_fromCSR_illegalInst_wrs_nto),
    .io_fromCSR_illegalInst_frm(io_fromCSR_illegalInst_frm),
    .io_fromCSR_illegalInst_cboZ(io_fromCSR_illegalInst_cboZ),
    .io_fromCSR_illegalInst_cboCF(io_fromCSR_illegalInst_cboCF),
    .io_fromCSR_illegalInst_cboI(io_fromCSR_illegalInst_cboI),
    .io_fromCSR_virtualInst_sfenceVMA(io_fromCSR_virtualInst_sfenceVMA),
    .io_fromCSR_virtualInst_sfencePart(io_fromCSR_virtualInst_sfencePart),
    .io_fromCSR_virtualInst_hfence(io_fromCSR_virtualInst_hfence),
    .io_fromCSR_virtualInst_hlsv(io_fromCSR_virtualInst_hlsv),
    .io_fromCSR_virtualInst_wfi(io_fromCSR_virtualInst_wfi),
    .io_fromCSR_virtualInst_wrs_nto(io_fromCSR_virtualInst_wrs_nto),
    .io_fromCSR_virtualInst_cboZ(io_fromCSR_virtualInst_cboZ),
    .io_fromCSR_virtualInst_cboCF(io_fromCSR_virtualInst_cboCF),
    .io_fromCSR_virtualInst_cboI(io_fromCSR_virtualInst_cboI),
    .io_fromCSR_special_cboI2F(io_fromCSR_special_cboI2F),
    .io_deq_decodedInst_instr(g_io_deq_decodedInst_instr),
    .io_deq_decodedInst_pc(g_io_deq_decodedInst_pc),
    .io_deq_decodedInst_foldpc(g_io_deq_decodedInst_foldpc),
    .io_deq_decodedInst_exceptionVec_0(g_io_deq_decodedInst_exceptionVec_0),
    .io_deq_decodedInst_exceptionVec_1(g_io_deq_decodedInst_exceptionVec_1),
    .io_deq_decodedInst_exceptionVec_2(g_io_deq_decodedInst_exceptionVec_2),
    .io_deq_decodedInst_exceptionVec_3(g_io_deq_decodedInst_exceptionVec_3),
    .io_deq_decodedInst_exceptionVec_4(g_io_deq_decodedInst_exceptionVec_4),
    .io_deq_decodedInst_exceptionVec_5(g_io_deq_decodedInst_exceptionVec_5),
    .io_deq_decodedInst_exceptionVec_6(g_io_deq_decodedInst_exceptionVec_6),
    .io_deq_decodedInst_exceptionVec_7(g_io_deq_decodedInst_exceptionVec_7),
    .io_deq_decodedInst_exceptionVec_8(g_io_deq_decodedInst_exceptionVec_8),
    .io_deq_decodedInst_exceptionVec_9(g_io_deq_decodedInst_exceptionVec_9),
    .io_deq_decodedInst_exceptionVec_10(g_io_deq_decodedInst_exceptionVec_10),
    .io_deq_decodedInst_exceptionVec_11(g_io_deq_decodedInst_exceptionVec_11),
    .io_deq_decodedInst_exceptionVec_12(g_io_deq_decodedInst_exceptionVec_12),
    .io_deq_decodedInst_exceptionVec_13(g_io_deq_decodedInst_exceptionVec_13),
    .io_deq_decodedInst_exceptionVec_14(g_io_deq_decodedInst_exceptionVec_14),
    .io_deq_decodedInst_exceptionVec_15(g_io_deq_decodedInst_exceptionVec_15),
    .io_deq_decodedInst_exceptionVec_16(g_io_deq_decodedInst_exceptionVec_16),
    .io_deq_decodedInst_exceptionVec_17(g_io_deq_decodedInst_exceptionVec_17),
    .io_deq_decodedInst_exceptionVec_18(g_io_deq_decodedInst_exceptionVec_18),
    .io_deq_decodedInst_exceptionVec_19(g_io_deq_decodedInst_exceptionVec_19),
    .io_deq_decodedInst_exceptionVec_20(g_io_deq_decodedInst_exceptionVec_20),
    .io_deq_decodedInst_exceptionVec_21(g_io_deq_decodedInst_exceptionVec_21),
    .io_deq_decodedInst_exceptionVec_22(g_io_deq_decodedInst_exceptionVec_22),
    .io_deq_decodedInst_exceptionVec_23(g_io_deq_decodedInst_exceptionVec_23),
    .io_deq_decodedInst_isFetchMalAddr(g_io_deq_decodedInst_isFetchMalAddr),
    .io_deq_decodedInst_trigger(g_io_deq_decodedInst_trigger),
    .io_deq_decodedInst_preDecodeInfo_valid(g_io_deq_decodedInst_preDecodeInfo_valid),
    .io_deq_decodedInst_preDecodeInfo_isRVC(g_io_deq_decodedInst_preDecodeInfo_isRVC),
    .io_deq_decodedInst_preDecodeInfo_brType(g_io_deq_decodedInst_preDecodeInfo_brType),
    .io_deq_decodedInst_preDecodeInfo_isCall(g_io_deq_decodedInst_preDecodeInfo_isCall),
    .io_deq_decodedInst_preDecodeInfo_isRet(g_io_deq_decodedInst_preDecodeInfo_isRet),
    .io_deq_decodedInst_pred_taken(g_io_deq_decodedInst_pred_taken),
    .io_deq_decodedInst_crossPageIPFFix(g_io_deq_decodedInst_crossPageIPFFix),
    .io_deq_decodedInst_ftqPtr_flag(g_io_deq_decodedInst_ftqPtr_flag),
    .io_deq_decodedInst_ftqPtr_value(g_io_deq_decodedInst_ftqPtr_value),
    .io_deq_decodedInst_ftqOffset(g_io_deq_decodedInst_ftqOffset),
    .io_deq_decodedInst_satpFlushFirstFetchFault(g_io_deq_decodedInst_satpFlushFirstFetchFault),
    .io_deq_decodedInst_srcType_0(g_io_deq_decodedInst_srcType_0),
    .io_deq_decodedInst_srcType_1(g_io_deq_decodedInst_srcType_1),
    .io_deq_decodedInst_srcType_2(g_io_deq_decodedInst_srcType_2),
    .io_deq_decodedInst_srcType_3(g_io_deq_decodedInst_srcType_3),
    .io_deq_decodedInst_srcType_4(g_io_deq_decodedInst_srcType_4),
    .io_deq_decodedInst_lsrc_0(g_io_deq_decodedInst_lsrc_0),
    .io_deq_decodedInst_lsrc_1(g_io_deq_decodedInst_lsrc_1),
    .io_deq_decodedInst_lsrc_2(g_io_deq_decodedInst_lsrc_2),
    .io_deq_decodedInst_ldest(g_io_deq_decodedInst_ldest),
    .io_deq_decodedInst_fuType(g_io_deq_decodedInst_fuType),
    .io_deq_decodedInst_fuOpType(g_io_deq_decodedInst_fuOpType),
    .io_deq_decodedInst_rfWen(g_io_deq_decodedInst_rfWen),
    .io_deq_decodedInst_fpWen(g_io_deq_decodedInst_fpWen),
    .io_deq_decodedInst_vecWen(g_io_deq_decodedInst_vecWen),
    .io_deq_decodedInst_isXSTrap(g_io_deq_decodedInst_isXSTrap),
    .io_deq_decodedInst_waitForward(g_io_deq_decodedInst_waitForward),
    .io_deq_decodedInst_blockBackward(g_io_deq_decodedInst_blockBackward),
    .io_deq_decodedInst_flushPipe(g_io_deq_decodedInst_flushPipe),
    .io_deq_decodedInst_canRobCompress(g_io_deq_decodedInst_canRobCompress),
    .io_deq_decodedInst_selImm(g_io_deq_decodedInst_selImm),
    .io_deq_decodedInst_imm(g_io_deq_decodedInst_imm),
    .io_deq_decodedInst_fpu_typeTagOut(g_io_deq_decodedInst_fpu_typeTagOut),
    .io_deq_decodedInst_fpu_wflags(g_io_deq_decodedInst_fpu_wflags),
    .io_deq_decodedInst_fpu_typ(g_io_deq_decodedInst_fpu_typ),
    .io_deq_decodedInst_fpu_fmt(g_io_deq_decodedInst_fpu_fmt),
    .io_deq_decodedInst_fpu_rm(g_io_deq_decodedInst_fpu_rm),
    .io_deq_decodedInst_vpu_vill(g_io_deq_decodedInst_vpu_vill),
    .io_deq_decodedInst_vpu_vma(g_io_deq_decodedInst_vpu_vma),
    .io_deq_decodedInst_vpu_vta(g_io_deq_decodedInst_vpu_vta),
    .io_deq_decodedInst_vpu_vsew(g_io_deq_decodedInst_vpu_vsew),
    .io_deq_decodedInst_vpu_vlmul(g_io_deq_decodedInst_vpu_vlmul),
    .io_deq_decodedInst_vpu_specVill(g_io_deq_decodedInst_vpu_specVill),
    .io_deq_decodedInst_vpu_specVma(g_io_deq_decodedInst_vpu_specVma),
    .io_deq_decodedInst_vpu_specVta(g_io_deq_decodedInst_vpu_specVta),
    .io_deq_decodedInst_vpu_specVsew(g_io_deq_decodedInst_vpu_specVsew),
    .io_deq_decodedInst_vpu_specVlmul(g_io_deq_decodedInst_vpu_specVlmul),
    .io_deq_decodedInst_vpu_vm(g_io_deq_decodedInst_vpu_vm),
    .io_deq_decodedInst_vpu_vstart(g_io_deq_decodedInst_vpu_vstart),
    .io_deq_decodedInst_vpu_nf(g_io_deq_decodedInst_vpu_nf),
    .io_deq_decodedInst_vpu_veew(g_io_deq_decodedInst_vpu_veew),
    .io_deq_decodedInst_vpu_isReverse(g_io_deq_decodedInst_vpu_isReverse),
    .io_deq_decodedInst_vpu_isExt(g_io_deq_decodedInst_vpu_isExt),
    .io_deq_decodedInst_vpu_isNarrow(g_io_deq_decodedInst_vpu_isNarrow),
    .io_deq_decodedInst_vpu_isDstMask(g_io_deq_decodedInst_vpu_isDstMask),
    .io_deq_decodedInst_vpu_isOpMask(g_io_deq_decodedInst_vpu_isOpMask),
    .io_deq_decodedInst_vpu_isDependOldVd(g_io_deq_decodedInst_vpu_isDependOldVd),
    .io_deq_decodedInst_vpu_isWritePartVd(g_io_deq_decodedInst_vpu_isWritePartVd),
    .io_deq_decodedInst_vpu_isVleff(g_io_deq_decodedInst_vpu_isVleff),
    .io_deq_decodedInst_vlsInstr(g_io_deq_decodedInst_vlsInstr),
    .io_deq_decodedInst_wfflags(g_io_deq_decodedInst_wfflags),
    .io_deq_decodedInst_isMove(g_io_deq_decodedInst_isMove),
    .io_deq_decodedInst_uopSplitType(g_io_deq_decodedInst_uopSplitType),
    .io_deq_decodedInst_isVset(g_io_deq_decodedInst_isVset),
    .io_deq_decodedInst_commitType(g_io_deq_decodedInst_commitType),
    .io_deq_decodedInst_debug_fuType(g_io_deq_decodedInst_debug_fuType),
    .io_deq_decodedInst_debug_seqNum_seqNum(g_io_deq_decodedInst_debug_seqNum_seqNum),
    .io_deq_decodedInst_debug_seqNum_uopIdx(g_io_deq_decodedInst_debug_seqNum_uopIdx),
    .io_deq_isComplex(g_io_deq_isComplex),
    .io_deq_uopInfo_numOfUop(g_io_deq_uopInfo_numOfUop),
    .io_deq_uopInfo_numOfWB(g_io_deq_uopInfo_numOfWB),
    .io_deq_uopInfo_lmul(g_io_deq_uopInfo_lmul)
  );

  DecodeUnit_xs u_x (
    .io_enq_ctrlFlow_instr(io_enq_ctrlFlow_instr),
    .io_enq_ctrlFlow_pc(io_enq_ctrlFlow_pc),
    .io_enq_ctrlFlow_foldpc(io_enq_ctrlFlow_foldpc),
    .io_enq_ctrlFlow_exceptionVec_0(io_enq_ctrlFlow_exceptionVec_0),
    .io_enq_ctrlFlow_exceptionVec_1(io_enq_ctrlFlow_exceptionVec_1),
    .io_enq_ctrlFlow_exceptionVec_2(io_enq_ctrlFlow_exceptionVec_2),
    .io_enq_ctrlFlow_exceptionVec_4(io_enq_ctrlFlow_exceptionVec_4),
    .io_enq_ctrlFlow_exceptionVec_5(io_enq_ctrlFlow_exceptionVec_5),
    .io_enq_ctrlFlow_exceptionVec_6(io_enq_ctrlFlow_exceptionVec_6),
    .io_enq_ctrlFlow_exceptionVec_7(io_enq_ctrlFlow_exceptionVec_7),
    .io_enq_ctrlFlow_exceptionVec_8(io_enq_ctrlFlow_exceptionVec_8),
    .io_enq_ctrlFlow_exceptionVec_9(io_enq_ctrlFlow_exceptionVec_9),
    .io_enq_ctrlFlow_exceptionVec_10(io_enq_ctrlFlow_exceptionVec_10),
    .io_enq_ctrlFlow_exceptionVec_11(io_enq_ctrlFlow_exceptionVec_11),
    .io_enq_ctrlFlow_exceptionVec_12(io_enq_ctrlFlow_exceptionVec_12),
    .io_enq_ctrlFlow_exceptionVec_13(io_enq_ctrlFlow_exceptionVec_13),
    .io_enq_ctrlFlow_exceptionVec_14(io_enq_ctrlFlow_exceptionVec_14),
    .io_enq_ctrlFlow_exceptionVec_15(io_enq_ctrlFlow_exceptionVec_15),
    .io_enq_ctrlFlow_exceptionVec_16(io_enq_ctrlFlow_exceptionVec_16),
    .io_enq_ctrlFlow_exceptionVec_17(io_enq_ctrlFlow_exceptionVec_17),
    .io_enq_ctrlFlow_exceptionVec_18(io_enq_ctrlFlow_exceptionVec_18),
    .io_enq_ctrlFlow_exceptionVec_19(io_enq_ctrlFlow_exceptionVec_19),
    .io_enq_ctrlFlow_exceptionVec_20(io_enq_ctrlFlow_exceptionVec_20),
    .io_enq_ctrlFlow_exceptionVec_21(io_enq_ctrlFlow_exceptionVec_21),
    .io_enq_ctrlFlow_exceptionVec_23(io_enq_ctrlFlow_exceptionVec_23),
    .io_enq_ctrlFlow_isFetchMalAddr(io_enq_ctrlFlow_isFetchMalAddr),
    .io_enq_ctrlFlow_trigger(io_enq_ctrlFlow_trigger),
    .io_enq_ctrlFlow_preDecodeInfo_valid(io_enq_ctrlFlow_preDecodeInfo_valid),
    .io_enq_ctrlFlow_preDecodeInfo_isRVC(io_enq_ctrlFlow_preDecodeInfo_isRVC),
    .io_enq_ctrlFlow_preDecodeInfo_brType(io_enq_ctrlFlow_preDecodeInfo_brType),
    .io_enq_ctrlFlow_preDecodeInfo_isCall(io_enq_ctrlFlow_preDecodeInfo_isCall),
    .io_enq_ctrlFlow_preDecodeInfo_isRet(io_enq_ctrlFlow_preDecodeInfo_isRet),
    .io_enq_ctrlFlow_pred_taken(io_enq_ctrlFlow_pred_taken),
    .io_enq_ctrlFlow_crossPageIPFFix(io_enq_ctrlFlow_crossPageIPFFix),
    .io_enq_ctrlFlow_ftqPtr_flag(io_enq_ctrlFlow_ftqPtr_flag),
    .io_enq_ctrlFlow_ftqPtr_value(io_enq_ctrlFlow_ftqPtr_value),
    .io_enq_ctrlFlow_ftqOffset(io_enq_ctrlFlow_ftqOffset),
    .io_enq_ctrlFlow_isLastInFtqEntry(io_enq_ctrlFlow_isLastInFtqEntry),
    .io_enq_ctrlFlow_debug_seqNum_seqNum(io_enq_ctrlFlow_debug_seqNum_seqNum),
    .io_enq_ctrlFlow_debug_seqNum_uopIdx(io_enq_ctrlFlow_debug_seqNum_uopIdx),
    .io_enq_ctrlFlow_satpFlushFirstFetchFault(io_enq_ctrlFlow_satpFlushFirstFetchFault),
    .io_enq_vtype_illegal(io_enq_vtype_illegal),
    .io_enq_vtype_vma(io_enq_vtype_vma),
    .io_enq_vtype_vta(io_enq_vtype_vta),
    .io_enq_vtype_vsew(io_enq_vtype_vsew),
    .io_enq_vtype_vlmul(io_enq_vtype_vlmul),
    .io_enq_vstart(io_enq_vstart),
    .io_csrCtrl_singlestep(io_csrCtrl_singlestep),
    .io_fromCSR_illegalInst_sfenceVMA(io_fromCSR_illegalInst_sfenceVMA),
    .io_fromCSR_illegalInst_sfencePart(io_fromCSR_illegalInst_sfencePart),
    .io_fromCSR_illegalInst_hfenceGVMA(io_fromCSR_illegalInst_hfenceGVMA),
    .io_fromCSR_illegalInst_hfenceVVMA(io_fromCSR_illegalInst_hfenceVVMA),
    .io_fromCSR_illegalInst_hlsv(io_fromCSR_illegalInst_hlsv),
    .io_fromCSR_illegalInst_fsIsOff(io_fromCSR_illegalInst_fsIsOff),
    .io_fromCSR_illegalInst_vsIsOff(io_fromCSR_illegalInst_vsIsOff),
    .io_fromCSR_illegalInst_wfi(io_fromCSR_illegalInst_wfi),
    .io_fromCSR_illegalInst_wrs_nto(io_fromCSR_illegalInst_wrs_nto),
    .io_fromCSR_illegalInst_frm(io_fromCSR_illegalInst_frm),
    .io_fromCSR_illegalInst_cboZ(io_fromCSR_illegalInst_cboZ),
    .io_fromCSR_illegalInst_cboCF(io_fromCSR_illegalInst_cboCF),
    .io_fromCSR_illegalInst_cboI(io_fromCSR_illegalInst_cboI),
    .io_fromCSR_virtualInst_sfenceVMA(io_fromCSR_virtualInst_sfenceVMA),
    .io_fromCSR_virtualInst_sfencePart(io_fromCSR_virtualInst_sfencePart),
    .io_fromCSR_virtualInst_hfence(io_fromCSR_virtualInst_hfence),
    .io_fromCSR_virtualInst_hlsv(io_fromCSR_virtualInst_hlsv),
    .io_fromCSR_virtualInst_wfi(io_fromCSR_virtualInst_wfi),
    .io_fromCSR_virtualInst_wrs_nto(io_fromCSR_virtualInst_wrs_nto),
    .io_fromCSR_virtualInst_cboZ(io_fromCSR_virtualInst_cboZ),
    .io_fromCSR_virtualInst_cboCF(io_fromCSR_virtualInst_cboCF),
    .io_fromCSR_virtualInst_cboI(io_fromCSR_virtualInst_cboI),
    .io_fromCSR_special_cboI2F(io_fromCSR_special_cboI2F),
    .io_deq_decodedInst_instr(x_io_deq_decodedInst_instr),
    .io_deq_decodedInst_pc(x_io_deq_decodedInst_pc),
    .io_deq_decodedInst_foldpc(x_io_deq_decodedInst_foldpc),
    .io_deq_decodedInst_exceptionVec_0(x_io_deq_decodedInst_exceptionVec_0),
    .io_deq_decodedInst_exceptionVec_1(x_io_deq_decodedInst_exceptionVec_1),
    .io_deq_decodedInst_exceptionVec_2(x_io_deq_decodedInst_exceptionVec_2),
    .io_deq_decodedInst_exceptionVec_3(x_io_deq_decodedInst_exceptionVec_3),
    .io_deq_decodedInst_exceptionVec_4(x_io_deq_decodedInst_exceptionVec_4),
    .io_deq_decodedInst_exceptionVec_5(x_io_deq_decodedInst_exceptionVec_5),
    .io_deq_decodedInst_exceptionVec_6(x_io_deq_decodedInst_exceptionVec_6),
    .io_deq_decodedInst_exceptionVec_7(x_io_deq_decodedInst_exceptionVec_7),
    .io_deq_decodedInst_exceptionVec_8(x_io_deq_decodedInst_exceptionVec_8),
    .io_deq_decodedInst_exceptionVec_9(x_io_deq_decodedInst_exceptionVec_9),
    .io_deq_decodedInst_exceptionVec_10(x_io_deq_decodedInst_exceptionVec_10),
    .io_deq_decodedInst_exceptionVec_11(x_io_deq_decodedInst_exceptionVec_11),
    .io_deq_decodedInst_exceptionVec_12(x_io_deq_decodedInst_exceptionVec_12),
    .io_deq_decodedInst_exceptionVec_13(x_io_deq_decodedInst_exceptionVec_13),
    .io_deq_decodedInst_exceptionVec_14(x_io_deq_decodedInst_exceptionVec_14),
    .io_deq_decodedInst_exceptionVec_15(x_io_deq_decodedInst_exceptionVec_15),
    .io_deq_decodedInst_exceptionVec_16(x_io_deq_decodedInst_exceptionVec_16),
    .io_deq_decodedInst_exceptionVec_17(x_io_deq_decodedInst_exceptionVec_17),
    .io_deq_decodedInst_exceptionVec_18(x_io_deq_decodedInst_exceptionVec_18),
    .io_deq_decodedInst_exceptionVec_19(x_io_deq_decodedInst_exceptionVec_19),
    .io_deq_decodedInst_exceptionVec_20(x_io_deq_decodedInst_exceptionVec_20),
    .io_deq_decodedInst_exceptionVec_21(x_io_deq_decodedInst_exceptionVec_21),
    .io_deq_decodedInst_exceptionVec_22(x_io_deq_decodedInst_exceptionVec_22),
    .io_deq_decodedInst_exceptionVec_23(x_io_deq_decodedInst_exceptionVec_23),
    .io_deq_decodedInst_isFetchMalAddr(x_io_deq_decodedInst_isFetchMalAddr),
    .io_deq_decodedInst_trigger(x_io_deq_decodedInst_trigger),
    .io_deq_decodedInst_preDecodeInfo_valid(x_io_deq_decodedInst_preDecodeInfo_valid),
    .io_deq_decodedInst_preDecodeInfo_isRVC(x_io_deq_decodedInst_preDecodeInfo_isRVC),
    .io_deq_decodedInst_preDecodeInfo_brType(x_io_deq_decodedInst_preDecodeInfo_brType),
    .io_deq_decodedInst_preDecodeInfo_isCall(x_io_deq_decodedInst_preDecodeInfo_isCall),
    .io_deq_decodedInst_preDecodeInfo_isRet(x_io_deq_decodedInst_preDecodeInfo_isRet),
    .io_deq_decodedInst_pred_taken(x_io_deq_decodedInst_pred_taken),
    .io_deq_decodedInst_crossPageIPFFix(x_io_deq_decodedInst_crossPageIPFFix),
    .io_deq_decodedInst_ftqPtr_flag(x_io_deq_decodedInst_ftqPtr_flag),
    .io_deq_decodedInst_ftqPtr_value(x_io_deq_decodedInst_ftqPtr_value),
    .io_deq_decodedInst_ftqOffset(x_io_deq_decodedInst_ftqOffset),
    .io_deq_decodedInst_satpFlushFirstFetchFault(x_io_deq_decodedInst_satpFlushFirstFetchFault),
    .io_deq_decodedInst_srcType_0(x_io_deq_decodedInst_srcType_0),
    .io_deq_decodedInst_srcType_1(x_io_deq_decodedInst_srcType_1),
    .io_deq_decodedInst_srcType_2(x_io_deq_decodedInst_srcType_2),
    .io_deq_decodedInst_srcType_3(x_io_deq_decodedInst_srcType_3),
    .io_deq_decodedInst_srcType_4(x_io_deq_decodedInst_srcType_4),
    .io_deq_decodedInst_lsrc_0(x_io_deq_decodedInst_lsrc_0),
    .io_deq_decodedInst_lsrc_1(x_io_deq_decodedInst_lsrc_1),
    .io_deq_decodedInst_lsrc_2(x_io_deq_decodedInst_lsrc_2),
    .io_deq_decodedInst_ldest(x_io_deq_decodedInst_ldest),
    .io_deq_decodedInst_fuType(x_io_deq_decodedInst_fuType),
    .io_deq_decodedInst_fuOpType(x_io_deq_decodedInst_fuOpType),
    .io_deq_decodedInst_rfWen(x_io_deq_decodedInst_rfWen),
    .io_deq_decodedInst_fpWen(x_io_deq_decodedInst_fpWen),
    .io_deq_decodedInst_vecWen(x_io_deq_decodedInst_vecWen),
    .io_deq_decodedInst_isXSTrap(x_io_deq_decodedInst_isXSTrap),
    .io_deq_decodedInst_waitForward(x_io_deq_decodedInst_waitForward),
    .io_deq_decodedInst_blockBackward(x_io_deq_decodedInst_blockBackward),
    .io_deq_decodedInst_flushPipe(x_io_deq_decodedInst_flushPipe),
    .io_deq_decodedInst_canRobCompress(x_io_deq_decodedInst_canRobCompress),
    .io_deq_decodedInst_selImm(x_io_deq_decodedInst_selImm),
    .io_deq_decodedInst_imm(x_io_deq_decodedInst_imm),
    .io_deq_decodedInst_fpu_typeTagOut(x_io_deq_decodedInst_fpu_typeTagOut),
    .io_deq_decodedInst_fpu_wflags(x_io_deq_decodedInst_fpu_wflags),
    .io_deq_decodedInst_fpu_typ(x_io_deq_decodedInst_fpu_typ),
    .io_deq_decodedInst_fpu_fmt(x_io_deq_decodedInst_fpu_fmt),
    .io_deq_decodedInst_fpu_rm(x_io_deq_decodedInst_fpu_rm),
    .io_deq_decodedInst_vpu_vill(x_io_deq_decodedInst_vpu_vill),
    .io_deq_decodedInst_vpu_vma(x_io_deq_decodedInst_vpu_vma),
    .io_deq_decodedInst_vpu_vta(x_io_deq_decodedInst_vpu_vta),
    .io_deq_decodedInst_vpu_vsew(x_io_deq_decodedInst_vpu_vsew),
    .io_deq_decodedInst_vpu_vlmul(x_io_deq_decodedInst_vpu_vlmul),
    .io_deq_decodedInst_vpu_specVill(x_io_deq_decodedInst_vpu_specVill),
    .io_deq_decodedInst_vpu_specVma(x_io_deq_decodedInst_vpu_specVma),
    .io_deq_decodedInst_vpu_specVta(x_io_deq_decodedInst_vpu_specVta),
    .io_deq_decodedInst_vpu_specVsew(x_io_deq_decodedInst_vpu_specVsew),
    .io_deq_decodedInst_vpu_specVlmul(x_io_deq_decodedInst_vpu_specVlmul),
    .io_deq_decodedInst_vpu_vm(x_io_deq_decodedInst_vpu_vm),
    .io_deq_decodedInst_vpu_vstart(x_io_deq_decodedInst_vpu_vstart),
    .io_deq_decodedInst_vpu_nf(x_io_deq_decodedInst_vpu_nf),
    .io_deq_decodedInst_vpu_veew(x_io_deq_decodedInst_vpu_veew),
    .io_deq_decodedInst_vpu_isReverse(x_io_deq_decodedInst_vpu_isReverse),
    .io_deq_decodedInst_vpu_isExt(x_io_deq_decodedInst_vpu_isExt),
    .io_deq_decodedInst_vpu_isNarrow(x_io_deq_decodedInst_vpu_isNarrow),
    .io_deq_decodedInst_vpu_isDstMask(x_io_deq_decodedInst_vpu_isDstMask),
    .io_deq_decodedInst_vpu_isOpMask(x_io_deq_decodedInst_vpu_isOpMask),
    .io_deq_decodedInst_vpu_isDependOldVd(x_io_deq_decodedInst_vpu_isDependOldVd),
    .io_deq_decodedInst_vpu_isWritePartVd(x_io_deq_decodedInst_vpu_isWritePartVd),
    .io_deq_decodedInst_vpu_isVleff(x_io_deq_decodedInst_vpu_isVleff),
    .io_deq_decodedInst_vlsInstr(x_io_deq_decodedInst_vlsInstr),
    .io_deq_decodedInst_wfflags(x_io_deq_decodedInst_wfflags),
    .io_deq_decodedInst_isMove(x_io_deq_decodedInst_isMove),
    .io_deq_decodedInst_uopSplitType(x_io_deq_decodedInst_uopSplitType),
    .io_deq_decodedInst_isVset(x_io_deq_decodedInst_isVset),
    .io_deq_decodedInst_commitType(x_io_deq_decodedInst_commitType),
    .io_deq_decodedInst_debug_fuType(x_io_deq_decodedInst_debug_fuType),
    .io_deq_decodedInst_debug_seqNum_seqNum(x_io_deq_decodedInst_debug_seqNum_seqNum),
    .io_deq_decodedInst_debug_seqNum_uopIdx(x_io_deq_decodedInst_debug_seqNum_uopIdx),
    .io_deq_isComplex(x_io_deq_isComplex),
    .io_deq_uopInfo_numOfUop(x_io_deq_uopInfo_numOfUop),
    .io_deq_uopInfo_numOfWB(x_io_deq_uopInfo_numOfWB),
    .io_deq_uopInfo_lmul(x_io_deq_uopInfo_lmul)
  );

  // ---- 译码表模式（717 条，表序）：value / mask，与 rtl 的 localparam 同源 ----
  localparam int NPAT = 717;
  logic [31:0] pat_val [NPAT];
  logic [31:0] pat_mask[NPAT];
  bit          pat_reach[NPAT];   // 0 = 被前面更宽的模式整个遮住（表序优先下不可达）
  int          pat_hit [NPAT];
  initial begin
    pat_val[  0] = 32'h00002003; pat_mask[  0] = 32'h0000707F; pat_reach[  0] = 1;  // LW
    pat_val[  1] = 32'h00001003; pat_mask[  1] = 32'h0000707F; pat_reach[  1] = 1;  // LH
    pat_val[  2] = 32'h00005003; pat_mask[  2] = 32'h0000707F; pat_reach[  2] = 1;  // LHU
    pat_val[  3] = 32'h00000003; pat_mask[  3] = 32'h0000707F; pat_reach[  3] = 1;  // LB
    pat_val[  4] = 32'h00004003; pat_mask[  4] = 32'h0000707F; pat_reach[  4] = 1;  // LBU
    pat_val[  5] = 32'h00002023; pat_mask[  5] = 32'h0000707F; pat_reach[  5] = 1;  // SW
    pat_val[  6] = 32'h00001023; pat_mask[  6] = 32'h0000707F; pat_reach[  6] = 1;  // SH
    pat_val[  7] = 32'h00000023; pat_mask[  7] = 32'h0000707F; pat_reach[  7] = 1;  // SB
    pat_val[  8] = 32'h00000037; pat_mask[  8] = 32'h0000007F; pat_reach[  8] = 1;  // LUI
    pat_val[  9] = 32'h00000013; pat_mask[  9] = 32'h0000707F; pat_reach[  9] = 1;  // ADDI
    pat_val[ 10] = 32'h00007013; pat_mask[ 10] = 32'h0000707F; pat_reach[ 10] = 1;  // ANDI
    pat_val[ 11] = 32'h00006013; pat_mask[ 11] = 32'h0000707F; pat_reach[ 11] = 1;  // ORI
    pat_val[ 12] = 32'h00004013; pat_mask[ 12] = 32'h0000707F; pat_reach[ 12] = 1;  // XORI
    pat_val[ 13] = 32'h00002013; pat_mask[ 13] = 32'h0000707F; pat_reach[ 13] = 1;  // SLTI
    pat_val[ 14] = 32'h00003013; pat_mask[ 14] = 32'h0000707F; pat_reach[ 14] = 1;  // SLTIU
    pat_val[ 15] = 32'h00001033; pat_mask[ 15] = 32'hFE00707F; pat_reach[ 15] = 1;  // SLL
    pat_val[ 16] = 32'h00000033; pat_mask[ 16] = 32'hFE00707F; pat_reach[ 16] = 1;  // ADD
    pat_val[ 17] = 32'h40000033; pat_mask[ 17] = 32'hFE00707F; pat_reach[ 17] = 1;  // SUB
    pat_val[ 18] = 32'h00002033; pat_mask[ 18] = 32'hFE00707F; pat_reach[ 18] = 1;  // SLT
    pat_val[ 19] = 32'h00003033; pat_mask[ 19] = 32'hFE00707F; pat_reach[ 19] = 1;  // SLTU
    pat_val[ 20] = 32'h00007033; pat_mask[ 20] = 32'hFE00707F; pat_reach[ 20] = 1;  // AND
    pat_val[ 21] = 32'h00006033; pat_mask[ 21] = 32'hFE00707F; pat_reach[ 21] = 1;  // OR
    pat_val[ 22] = 32'h00004033; pat_mask[ 22] = 32'hFE00707F; pat_reach[ 22] = 1;  // XOR
    pat_val[ 23] = 32'h40005033; pat_mask[ 23] = 32'hFE00707F; pat_reach[ 23] = 1;  // SRA
    pat_val[ 24] = 32'h00005033; pat_mask[ 24] = 32'hFE00707F; pat_reach[ 24] = 1;  // SRL
    pat_val[ 25] = 32'h00003003; pat_mask[ 25] = 32'h0000707F; pat_reach[ 25] = 1;  // LD
    pat_val[ 26] = 32'h00006003; pat_mask[ 26] = 32'h0000707F; pat_reach[ 26] = 1;  // LWU
    pat_val[ 27] = 32'h00003023; pat_mask[ 27] = 32'h0000707F; pat_reach[ 27] = 1;  // SD
    pat_val[ 28] = 32'h00001013; pat_mask[ 28] = 32'hFC00707F; pat_reach[ 28] = 1;  // SLLI
    pat_val[ 29] = 32'h00005013; pat_mask[ 29] = 32'hFC00707F; pat_reach[ 29] = 1;  // SRLI
    pat_val[ 30] = 32'h40005013; pat_mask[ 30] = 32'hFC00707F; pat_reach[ 30] = 1;  // SRAI
    pat_val[ 31] = 32'h0000001B; pat_mask[ 31] = 32'h0000707F; pat_reach[ 31] = 1;  // ADDIW
    pat_val[ 32] = 32'h0000101B; pat_mask[ 32] = 32'hFE00707F; pat_reach[ 32] = 1;  // SLLIW
    pat_val[ 33] = 32'h4000501B; pat_mask[ 33] = 32'hFE00707F; pat_reach[ 33] = 1;  // SRAIW
    pat_val[ 34] = 32'h0000501B; pat_mask[ 34] = 32'hFE00707F; pat_reach[ 34] = 1;  // SRLIW
    pat_val[ 35] = 32'h0000003B; pat_mask[ 35] = 32'hFE00707F; pat_reach[ 35] = 1;  // ADDW
    pat_val[ 36] = 32'h4000003B; pat_mask[ 36] = 32'hFE00707F; pat_reach[ 36] = 1;  // SUBW
    pat_val[ 37] = 32'h0000103B; pat_mask[ 37] = 32'hFE00707F; pat_reach[ 37] = 1;  // SLLW
    pat_val[ 38] = 32'h4000503B; pat_mask[ 38] = 32'hFE00707F; pat_reach[ 38] = 1;  // SRAW
    pat_val[ 39] = 32'h0000503B; pat_mask[ 39] = 32'hFE00707F; pat_reach[ 39] = 1;  // SRLW
    pat_val[ 40] = 32'h02000033; pat_mask[ 40] = 32'hFE00707F; pat_reach[ 40] = 1;  // MUL
    pat_val[ 41] = 32'h02001033; pat_mask[ 41] = 32'hFE00707F; pat_reach[ 41] = 1;  // MULH
    pat_val[ 42] = 32'h02003033; pat_mask[ 42] = 32'hFE00707F; pat_reach[ 42] = 1;  // MULHU
    pat_val[ 43] = 32'h02002033; pat_mask[ 43] = 32'hFE00707F; pat_reach[ 43] = 1;  // MULHSU
    pat_val[ 44] = 32'h0200003B; pat_mask[ 44] = 32'hFE00707F; pat_reach[ 44] = 1;  // MULW
    pat_val[ 45] = 32'h02004033; pat_mask[ 45] = 32'hFE00707F; pat_reach[ 45] = 1;  // DIV
    pat_val[ 46] = 32'h02005033; pat_mask[ 46] = 32'hFE00707F; pat_reach[ 46] = 1;  // DIVU
    pat_val[ 47] = 32'h02006033; pat_mask[ 47] = 32'hFE00707F; pat_reach[ 47] = 1;  // REM
    pat_val[ 48] = 32'h02007033; pat_mask[ 48] = 32'hFE00707F; pat_reach[ 48] = 1;  // REMU
    pat_val[ 49] = 32'h0200403B; pat_mask[ 49] = 32'hFE00707F; pat_reach[ 49] = 1;  // DIVW
    pat_val[ 50] = 32'h0200503B; pat_mask[ 50] = 32'hFE00707F; pat_reach[ 50] = 1;  // DIVUW
    pat_val[ 51] = 32'h0200603B; pat_mask[ 51] = 32'hFE00707F; pat_reach[ 51] = 1;  // REMW
    pat_val[ 52] = 32'h0200703B; pat_mask[ 52] = 32'hFE00707F; pat_reach[ 52] = 1;  // REMUW
    pat_val[ 53] = 32'h00000017; pat_mask[ 53] = 32'h0000007F; pat_reach[ 53] = 1;  // AUIPC
    pat_val[ 54] = 32'h0000006F; pat_mask[ 54] = 32'h0000007F; pat_reach[ 54] = 1;  // JAL
    pat_val[ 55] = 32'h00000067; pat_mask[ 55] = 32'h0000707F; pat_reach[ 55] = 1;  // JALR
    pat_val[ 56] = 32'h00000063; pat_mask[ 56] = 32'h0000707F; pat_reach[ 56] = 1;  // BEQ
    pat_val[ 57] = 32'h00001063; pat_mask[ 57] = 32'h0000707F; pat_reach[ 57] = 1;  // BNE
    pat_val[ 58] = 32'h00005063; pat_mask[ 58] = 32'h0000707F; pat_reach[ 58] = 1;  // BGE
    pat_val[ 59] = 32'h00007063; pat_mask[ 59] = 32'h0000707F; pat_reach[ 59] = 1;  // BGEU
    pat_val[ 60] = 32'h00004063; pat_mask[ 60] = 32'h0000707F; pat_reach[ 60] = 1;  // BLT
    pat_val[ 61] = 32'h00006063; pat_mask[ 61] = 32'h0000707F; pat_reach[ 61] = 1;  // BLTU
    pat_val[ 62] = 32'h00001073; pat_mask[ 62] = 32'h0000707F; pat_reach[ 62] = 1;  // CSRRW
    pat_val[ 63] = 32'h00002073; pat_mask[ 63] = 32'h0000707F; pat_reach[ 63] = 1;  // CSRRS
    pat_val[ 64] = 32'h00003073; pat_mask[ 64] = 32'h0000707F; pat_reach[ 64] = 1;  // CSRRC
    pat_val[ 65] = 32'h00005073; pat_mask[ 65] = 32'h0000707F; pat_reach[ 65] = 1;  // CSRRWI
    pat_val[ 66] = 32'h00006073; pat_mask[ 66] = 32'h0000707F; pat_reach[ 66] = 1;  // CSRRSI
    pat_val[ 67] = 32'h00007073; pat_mask[ 67] = 32'h0000707F; pat_reach[ 67] = 1;  // CSRRCI
    pat_val[ 68] = 32'h00100073; pat_mask[ 68] = 32'hFFFFFFFF; pat_reach[ 68] = 1;  // EBREAK
    pat_val[ 69] = 32'h00000073; pat_mask[ 69] = 32'hFFFFFFFF; pat_reach[ 69] = 1;  // ECALL
    pat_val[ 70] = 32'h10200073; pat_mask[ 70] = 32'hFFFFFFFF; pat_reach[ 70] = 1;  // SRET
    pat_val[ 71] = 32'h30200073; pat_mask[ 71] = 32'hFFFFFFFF; pat_reach[ 71] = 1;  // MRET
    pat_val[ 72] = 32'h70200073; pat_mask[ 72] = 32'hFFFFFFFF; pat_reach[ 72] = 1;  // MNRET
    pat_val[ 73] = 32'h7B200073; pat_mask[ 73] = 32'hFFFFFFFF; pat_reach[ 73] = 1;  // DRET
    pat_val[ 74] = 32'h10500073; pat_mask[ 74] = 32'hFFFFFFFF; pat_reach[ 74] = 1;  // WFI
    pat_val[ 75] = 32'h12000073; pat_mask[ 75] = 32'hFE007FFF; pat_reach[ 75] = 1;  // SFENCE_VMA
    pat_val[ 76] = 32'h0000100F; pat_mask[ 76] = 32'h0000707F; pat_reach[ 76] = 1;  // FENCE_I
    pat_val[ 77] = 32'h0000000F; pat_mask[ 77] = 32'h0000707F; pat_reach[ 77] = 1;  // FENCE
    pat_val[ 78] = 32'h0100000F; pat_mask[ 78] = 32'hFFFFFFFF; pat_reach[ 78] = 0;  // PAUSE
    pat_val[ 79] = 32'h00D00073; pat_mask[ 79] = 32'hFFFFFFFF; pat_reach[ 79] = 1;  // WRS_NTO
    pat_val[ 80] = 32'h01D00073; pat_mask[ 80] = 32'hFFFFFFFF; pat_reach[ 80] = 1;  // WRS_STO
    pat_val[ 81] = 32'h0000202F; pat_mask[ 81] = 32'hF800707F; pat_reach[ 81] = 1;  // AMOADD_W
    pat_val[ 82] = 32'h2000202F; pat_mask[ 82] = 32'hF800707F; pat_reach[ 82] = 1;  // AMOXOR_W
    pat_val[ 83] = 32'h0800202F; pat_mask[ 83] = 32'hF800707F; pat_reach[ 83] = 1;  // AMOSWAP_W
    pat_val[ 84] = 32'h6000202F; pat_mask[ 84] = 32'hF800707F; pat_reach[ 84] = 1;  // AMOAND_W
    pat_val[ 85] = 32'h4000202F; pat_mask[ 85] = 32'hF800707F; pat_reach[ 85] = 1;  // AMOOR_W
    pat_val[ 86] = 32'h8000202F; pat_mask[ 86] = 32'hF800707F; pat_reach[ 86] = 1;  // AMOMIN_W
    pat_val[ 87] = 32'hC000202F; pat_mask[ 87] = 32'hF800707F; pat_reach[ 87] = 1;  // AMOMINU_W
    pat_val[ 88] = 32'hA000202F; pat_mask[ 88] = 32'hF800707F; pat_reach[ 88] = 1;  // AMOMAX_W
    pat_val[ 89] = 32'hE000202F; pat_mask[ 89] = 32'hF800707F; pat_reach[ 89] = 1;  // AMOMAXU_W
    pat_val[ 90] = 32'h2800202F; pat_mask[ 90] = 32'hF800707F; pat_reach[ 90] = 1;  // AMOCAS_W
    pat_val[ 91] = 32'h0000302F; pat_mask[ 91] = 32'hF800707F; pat_reach[ 91] = 1;  // AMOADD_D
    pat_val[ 92] = 32'h2000302F; pat_mask[ 92] = 32'hF800707F; pat_reach[ 92] = 1;  // AMOXOR_D
    pat_val[ 93] = 32'h0800302F; pat_mask[ 93] = 32'hF800707F; pat_reach[ 93] = 1;  // AMOSWAP_D
    pat_val[ 94] = 32'h6000302F; pat_mask[ 94] = 32'hF800707F; pat_reach[ 94] = 1;  // AMOAND_D
    pat_val[ 95] = 32'h4000302F; pat_mask[ 95] = 32'hF800707F; pat_reach[ 95] = 1;  // AMOOR_D
    pat_val[ 96] = 32'h8000302F; pat_mask[ 96] = 32'hF800707F; pat_reach[ 96] = 1;  // AMOMIN_D
    pat_val[ 97] = 32'hC000302F; pat_mask[ 97] = 32'hF800707F; pat_reach[ 97] = 1;  // AMOMINU_D
    pat_val[ 98] = 32'hA000302F; pat_mask[ 98] = 32'hF800707F; pat_reach[ 98] = 1;  // AMOMAX_D
    pat_val[ 99] = 32'hE000302F; pat_mask[ 99] = 32'hF800707F; pat_reach[ 99] = 1;  // AMOMAXU_D
    pat_val[100] = 32'h2800302F; pat_mask[100] = 32'hF800707F; pat_reach[100] = 1;  // AMOCAS_D
    pat_val[101] = 32'h2800402F; pat_mask[101] = 32'hF800707F; pat_reach[101] = 1;  // AMOCAS_Q
    pat_val[102] = 32'h1000202F; pat_mask[102] = 32'hF9F0707F; pat_reach[102] = 1;  // LR_W
    pat_val[103] = 32'h1000302F; pat_mask[103] = 32'hF9F0707F; pat_reach[103] = 1;  // LR_D
    pat_val[104] = 32'h1800202F; pat_mask[104] = 32'hF800707F; pat_reach[104] = 1;  // SC_W
    pat_val[105] = 32'h1800302F; pat_mask[105] = 32'hF800707F; pat_reach[105] = 1;  // SC_D
    pat_val[106] = 32'h00001007; pat_mask[106] = 32'h0000707F; pat_reach[106] = 1;  // FLH
    pat_val[107] = 32'h00002007; pat_mask[107] = 32'h0000707F; pat_reach[107] = 1;  // FLW
    pat_val[108] = 32'h00003007; pat_mask[108] = 32'h0000707F; pat_reach[108] = 1;  // FLD
    pat_val[109] = 32'h00001027; pat_mask[109] = 32'h0000707F; pat_reach[109] = 1;  // FSH
    pat_val[110] = 32'h00002027; pat_mask[110] = 32'h0000707F; pat_reach[110] = 1;  // FSW
    pat_val[111] = 32'h00003027; pat_mask[111] = 32'h0000707F; pat_reach[111] = 1;  // FSD
    pat_val[112] = 32'hF2000053; pat_mask[112] = 32'hFFF0707F; pat_reach[112] = 1;  // FMV_D_X
    pat_val[113] = 32'hF0000053; pat_mask[113] = 32'hFFF0707F; pat_reach[113] = 1;  // FMV_W_X
    pat_val[114] = 32'hF4000053; pat_mask[114] = 32'hFFF0707F; pat_reach[114] = 1;  // FMV_H_X
    pat_val[115] = 32'hD0000053; pat_mask[115] = 32'hFFF0007F; pat_reach[115] = 1;  // FCVT_S_W
    pat_val[116] = 32'hD0100053; pat_mask[116] = 32'hFFF0007F; pat_reach[116] = 1;  // FCVT_S_WU
    pat_val[117] = 32'hD0200053; pat_mask[117] = 32'hFFF0007F; pat_reach[117] = 1;  // FCVT_S_L
    pat_val[118] = 32'hD0300053; pat_mask[118] = 32'hFFF0007F; pat_reach[118] = 1;  // FCVT_S_LU
    pat_val[119] = 32'hD2000053; pat_mask[119] = 32'hFFF0007F; pat_reach[119] = 1;  // FCVT_D_W
    pat_val[120] = 32'hD2100053; pat_mask[120] = 32'hFFF0007F; pat_reach[120] = 1;  // FCVT_D_WU
    pat_val[121] = 32'hD2200053; pat_mask[121] = 32'hFFF0007F; pat_reach[121] = 1;  // FCVT_D_L
    pat_val[122] = 32'hD2300053; pat_mask[122] = 32'hFFF0007F; pat_reach[122] = 1;  // FCVT_D_LU
    pat_val[123] = 32'hD4000053; pat_mask[123] = 32'hFFF0007F; pat_reach[123] = 1;  // FCVT_H_W
    pat_val[124] = 32'hD4100053; pat_mask[124] = 32'hFFF0007F; pat_reach[124] = 1;  // FCVT_H_WU
    pat_val[125] = 32'hD4200053; pat_mask[125] = 32'hFFF0007F; pat_reach[125] = 1;  // FCVT_H_L
    pat_val[126] = 32'hD4300053; pat_mask[126] = 32'hFFF0007F; pat_reach[126] = 1;  // FCVT_H_LU
    pat_val[127] = 32'h0800003B; pat_mask[127] = 32'hFE00707F; pat_reach[127] = 1;  // ADD_UW
    pat_val[128] = 32'h20002033; pat_mask[128] = 32'hFE00707F; pat_reach[128] = 1;  // SH1ADD
    pat_val[129] = 32'h2000203B; pat_mask[129] = 32'hFE00707F; pat_reach[129] = 1;  // SH1ADD_UW
    pat_val[130] = 32'h20004033; pat_mask[130] = 32'hFE00707F; pat_reach[130] = 1;  // SH2ADD
    pat_val[131] = 32'h2000403B; pat_mask[131] = 32'hFE00707F; pat_reach[131] = 1;  // SH2ADD_UW
    pat_val[132] = 32'h20006033; pat_mask[132] = 32'hFE00707F; pat_reach[132] = 1;  // SH3ADD
    pat_val[133] = 32'h2000603B; pat_mask[133] = 32'hFE00707F; pat_reach[133] = 1;  // SH3ADD_UW
    pat_val[134] = 32'h0800101B; pat_mask[134] = 32'hFC00707F; pat_reach[134] = 1;  // SLLI_UW
    pat_val[135] = 32'h40007033; pat_mask[135] = 32'hFE00707F; pat_reach[135] = 1;  // ANDN
    pat_val[136] = 32'h40006033; pat_mask[136] = 32'hFE00707F; pat_reach[136] = 1;  // ORN
    pat_val[137] = 32'h40004033; pat_mask[137] = 32'hFE00707F; pat_reach[137] = 1;  // XNOR
    pat_val[138] = 32'h60001013; pat_mask[138] = 32'hFFF0707F; pat_reach[138] = 1;  // CLZ
    pat_val[139] = 32'h6000101B; pat_mask[139] = 32'hFFF0707F; pat_reach[139] = 1;  // CLZW
    pat_val[140] = 32'h60101013; pat_mask[140] = 32'hFFF0707F; pat_reach[140] = 1;  // CTZ
    pat_val[141] = 32'h6010101B; pat_mask[141] = 32'hFFF0707F; pat_reach[141] = 1;  // CTZW
    pat_val[142] = 32'h60201013; pat_mask[142] = 32'hFFF0707F; pat_reach[142] = 1;  // CPOP
    pat_val[143] = 32'h6020101B; pat_mask[143] = 32'hFFF0707F; pat_reach[143] = 1;  // CPOPW
    pat_val[144] = 32'h0A006033; pat_mask[144] = 32'hFE00707F; pat_reach[144] = 1;  // MAX
    pat_val[145] = 32'h0A007033; pat_mask[145] = 32'hFE00707F; pat_reach[145] = 1;  // MAXU
    pat_val[146] = 32'h0A004033; pat_mask[146] = 32'hFE00707F; pat_reach[146] = 1;  // MIN
    pat_val[147] = 32'h0A005033; pat_mask[147] = 32'hFE00707F; pat_reach[147] = 1;  // MINU
    pat_val[148] = 32'h60401013; pat_mask[148] = 32'hFFF0707F; pat_reach[148] = 1;  // SEXT_B
    pat_val[149] = 32'h60501013; pat_mask[149] = 32'hFFF0707F; pat_reach[149] = 1;  // SEXT_H
    pat_val[150] = 32'h60001033; pat_mask[150] = 32'hFE00707F; pat_reach[150] = 1;  // ROL
    pat_val[151] = 32'h6000103B; pat_mask[151] = 32'hFE00707F; pat_reach[151] = 1;  // ROLW
    pat_val[152] = 32'h60005033; pat_mask[152] = 32'hFE00707F; pat_reach[152] = 1;  // ROR
    pat_val[153] = 32'h60005013; pat_mask[153] = 32'hFC00707F; pat_reach[153] = 1;  // RORI
    pat_val[154] = 32'h6000501B; pat_mask[154] = 32'hFE00707F; pat_reach[154] = 1;  // RORIW
    pat_val[155] = 32'h6000503B; pat_mask[155] = 32'hFE00707F; pat_reach[155] = 1;  // RORW
    pat_val[156] = 32'h28705013; pat_mask[156] = 32'hFFF0707F; pat_reach[156] = 1;  // ORC_B
    pat_val[157] = 32'h6B805013; pat_mask[157] = 32'hFFF0707F; pat_reach[157] = 1;  // REV8
    pat_val[158] = 32'h0A001033; pat_mask[158] = 32'hFE00707F; pat_reach[158] = 1;  // CLMUL
    pat_val[159] = 32'h0A003033; pat_mask[159] = 32'hFE00707F; pat_reach[159] = 1;  // CLMULH
    pat_val[160] = 32'h0A002033; pat_mask[160] = 32'hFE00707F; pat_reach[160] = 1;  // CLMULR
    pat_val[161] = 32'h48001033; pat_mask[161] = 32'hFE00707F; pat_reach[161] = 1;  // BCLR
    pat_val[162] = 32'h48001013; pat_mask[162] = 32'hFC00707F; pat_reach[162] = 1;  // BCLRI
    pat_val[163] = 32'h48005033; pat_mask[163] = 32'hFE00707F; pat_reach[163] = 1;  // BEXT
    pat_val[164] = 32'h48005013; pat_mask[164] = 32'hFC00707F; pat_reach[164] = 1;  // BEXTI
    pat_val[165] = 32'h68001033; pat_mask[165] = 32'hFE00707F; pat_reach[165] = 1;  // BINV
    pat_val[166] = 32'h68001013; pat_mask[166] = 32'hFC00707F; pat_reach[166] = 1;  // BINVI
    pat_val[167] = 32'h28001033; pat_mask[167] = 32'hFE00707F; pat_reach[167] = 1;  // BSET
    pat_val[168] = 32'h28001013; pat_mask[168] = 32'hFC00707F; pat_reach[168] = 1;  // BSETI
    pat_val[169] = 32'h08004033; pat_mask[169] = 32'hFE00707F; pat_reach[169] = 1;  // PACK
    pat_val[170] = 32'h08007033; pat_mask[170] = 32'hFE00707F; pat_reach[170] = 1;  // PACKH
    pat_val[171] = 32'h0800403B; pat_mask[171] = 32'hFE00707F; pat_reach[171] = 1;  // PACKW
    pat_val[172] = 32'h68705013; pat_mask[172] = 32'hFFF0707F; pat_reach[172] = 1;  // BREV8
    pat_val[173] = 32'h28002033; pat_mask[173] = 32'hFE00707F; pat_reach[173] = 1;  // XPERM4
    pat_val[174] = 32'h28004033; pat_mask[174] = 32'hFE00707F; pat_reach[174] = 1;  // XPERM8
    pat_val[175] = 32'h3A000033; pat_mask[175] = 32'hFE00707F; pat_reach[175] = 1;  // AES64DS
    pat_val[176] = 32'h3E000033; pat_mask[176] = 32'hFE00707F; pat_reach[176] = 1;  // AES64DSM
    pat_val[177] = 32'h30001013; pat_mask[177] = 32'hFFF0707F; pat_reach[177] = 1;  // AES64IM
    pat_val[178] = 32'h31001013; pat_mask[178] = 32'hFF00707F; pat_reach[178] = 1;  // AES64KS1I
    pat_val[179] = 32'h7E000033; pat_mask[179] = 32'hFE00707F; pat_reach[179] = 1;  // AES64KS2
    pat_val[180] = 32'h32000033; pat_mask[180] = 32'hFE00707F; pat_reach[180] = 1;  // AES64ES
    pat_val[181] = 32'h36000033; pat_mask[181] = 32'hFE00707F; pat_reach[181] = 1;  // AES64ESM
    pat_val[182] = 32'h10201013; pat_mask[182] = 32'hFFF0707F; pat_reach[182] = 1;  // SHA256SIG0
    pat_val[183] = 32'h10301013; pat_mask[183] = 32'hFFF0707F; pat_reach[183] = 1;  // SHA256SIG1
    pat_val[184] = 32'h10001013; pat_mask[184] = 32'hFFF0707F; pat_reach[184] = 1;  // SHA256SUM0
    pat_val[185] = 32'h10101013; pat_mask[185] = 32'hFFF0707F; pat_reach[185] = 1;  // SHA256SUM1
    pat_val[186] = 32'h10601013; pat_mask[186] = 32'hFFF0707F; pat_reach[186] = 1;  // SHA512SIG0
    pat_val[187] = 32'h10701013; pat_mask[187] = 32'hFFF0707F; pat_reach[187] = 1;  // SHA512SIG1
    pat_val[188] = 32'h10401013; pat_mask[188] = 32'hFFF0707F; pat_reach[188] = 1;  // SHA512SUM0
    pat_val[189] = 32'h10501013; pat_mask[189] = 32'hFFF0707F; pat_reach[189] = 1;  // SHA512SUM1
    pat_val[190] = 32'h30000033; pat_mask[190] = 32'hFE00707F; pat_reach[190] = 1;  // SM4ED0
    pat_val[191] = 32'h70000033; pat_mask[191] = 32'hFE00707F; pat_reach[191] = 1;  // SM4ED1
    pat_val[192] = 32'hB0000033; pat_mask[192] = 32'hFE00707F; pat_reach[192] = 1;  // SM4ED2
    pat_val[193] = 32'hF0000033; pat_mask[193] = 32'hFE00707F; pat_reach[193] = 1;  // SM4ED3
    pat_val[194] = 32'h34000033; pat_mask[194] = 32'hFE00707F; pat_reach[194] = 1;  // SM4KS0
    pat_val[195] = 32'h74000033; pat_mask[195] = 32'hFE00707F; pat_reach[195] = 1;  // SM4KS1
    pat_val[196] = 32'hB4000033; pat_mask[196] = 32'hFE00707F; pat_reach[196] = 1;  // SM4KS2
    pat_val[197] = 32'hF4000033; pat_mask[197] = 32'hFE00707F; pat_reach[197] = 1;  // SM4KS3
    pat_val[198] = 32'h10801013; pat_mask[198] = 32'hFFF0707F; pat_reach[198] = 1;  // SM3P0
    pat_val[199] = 32'h10901013; pat_mask[199] = 32'hFFF0707F; pat_reach[199] = 1;  // SM3P1
    pat_val[200] = 32'h0000006B; pat_mask[200] = 32'hFFF07FFF; pat_reach[200] = 1;  // TRAP
    pat_val[201] = 32'h0040200F; pat_mask[201] = 32'hFFF07FFF; pat_reach[201] = 1;  // CBO_ZERO
    pat_val[202] = 32'h0010200F; pat_mask[202] = 32'hFFF07FFF; pat_reach[202] = 1;  // CBO_CLEAN
    pat_val[203] = 32'h0020200F; pat_mask[203] = 32'hFFF07FFF; pat_reach[203] = 1;  // CBO_FLUSH
    pat_val[204] = 32'h0000200F; pat_mask[204] = 32'hFFF07FFF; pat_reach[204] = 1;  // CBO_INVAL
    pat_val[205] = 32'h16000073; pat_mask[205] = 32'hFE007FFF; pat_reach[205] = 1;  // SINVAL_VMA
    pat_val[206] = 32'h18000073; pat_mask[206] = 32'hFFFFFFFF; pat_reach[206] = 1;  // SFENCE_W_INVAL
    pat_val[207] = 32'h18100073; pat_mask[207] = 32'hFFFFFFFF; pat_reach[207] = 1;  // SFENCE_INVAL_IR
    pat_val[208] = 32'h62000073; pat_mask[208] = 32'hFE007FFF; pat_reach[208] = 1;  // HFENCE_GVMA
    pat_val[209] = 32'h22000073; pat_mask[209] = 32'hFE007FFF; pat_reach[209] = 1;  // HFENCE_VVMA
    pat_val[210] = 32'h66000073; pat_mask[210] = 32'hFE007FFF; pat_reach[210] = 1;  // HINVAL_GVMA
    pat_val[211] = 32'h26000073; pat_mask[211] = 32'hFE007FFF; pat_reach[211] = 1;  // HINVAL_VVMA
    pat_val[212] = 32'h60004073; pat_mask[212] = 32'hFFF0707F; pat_reach[212] = 1;  // HLV_B
    pat_val[213] = 32'h60104073; pat_mask[213] = 32'hFFF0707F; pat_reach[213] = 1;  // HLV_BU
    pat_val[214] = 32'h6C004073; pat_mask[214] = 32'hFFF0707F; pat_reach[214] = 1;  // HLV_D
    pat_val[215] = 32'h64004073; pat_mask[215] = 32'hFFF0707F; pat_reach[215] = 1;  // HLV_H
    pat_val[216] = 32'h64104073; pat_mask[216] = 32'hFFF0707F; pat_reach[216] = 1;  // HLV_HU
    pat_val[217] = 32'h68004073; pat_mask[217] = 32'hFFF0707F; pat_reach[217] = 1;  // HLV_W
    pat_val[218] = 32'h68104073; pat_mask[218] = 32'hFFF0707F; pat_reach[218] = 1;  // HLV_WU
    pat_val[219] = 32'h64304073; pat_mask[219] = 32'hFFF0707F; pat_reach[219] = 1;  // HLVX_HU
    pat_val[220] = 32'h68304073; pat_mask[220] = 32'hFFF0707F; pat_reach[220] = 1;  // HLVX_WU
    pat_val[221] = 32'h62004073; pat_mask[221] = 32'hFE007FFF; pat_reach[221] = 1;  // HSV_B
    pat_val[222] = 32'h6E004073; pat_mask[222] = 32'hFE007FFF; pat_reach[222] = 1;  // HSV_D
    pat_val[223] = 32'h66004073; pat_mask[223] = 32'hFE007FFF; pat_reach[223] = 1;  // HSV_H
    pat_val[224] = 32'h6A004073; pat_mask[224] = 32'hFE007FFF; pat_reach[224] = 1;  // HSV_W
    pat_val[225] = 32'h00007057; pat_mask[225] = 32'h8000707F; pat_reach[225] = 1;  // VSETVLI
    pat_val[226] = 32'hC0007057; pat_mask[226] = 32'hC000707F; pat_reach[226] = 1;  // VSETIVLI
    pat_val[227] = 32'h80007057; pat_mask[227] = 32'hFE00707F; pat_reach[227] = 1;  // VSETVL
    pat_val[228] = 32'h00000057; pat_mask[228] = 32'hFC00707F; pat_reach[228] = 1;  // VADD_VV
    pat_val[229] = 32'h08000057; pat_mask[229] = 32'hFC00707F; pat_reach[229] = 1;  // VSUB_VV
    pat_val[230] = 32'h10000057; pat_mask[230] = 32'hFC00707F; pat_reach[230] = 1;  // VMINU_VV
    pat_val[231] = 32'h14000057; pat_mask[231] = 32'hFC00707F; pat_reach[231] = 1;  // VMIN_VV
    pat_val[232] = 32'h18000057; pat_mask[232] = 32'hFC00707F; pat_reach[232] = 1;  // VMAXU_VV
    pat_val[233] = 32'h1C000057; pat_mask[233] = 32'hFC00707F; pat_reach[233] = 1;  // VMAX_VV
    pat_val[234] = 32'h24000057; pat_mask[234] = 32'hFC00707F; pat_reach[234] = 1;  // VAND_VV
    pat_val[235] = 32'h28000057; pat_mask[235] = 32'hFC00707F; pat_reach[235] = 1;  // VOR_VV
    pat_val[236] = 32'h2C000057; pat_mask[236] = 32'hFC00707F; pat_reach[236] = 1;  // VXOR_VV
    pat_val[237] = 32'h30000057; pat_mask[237] = 32'hFC00707F; pat_reach[237] = 1;  // VRGATHER_VV
    pat_val[238] = 32'h38000057; pat_mask[238] = 32'hFC00707F; pat_reach[238] = 1;  // VRGATHEREI16_VV
    pat_val[239] = 32'h40000057; pat_mask[239] = 32'hFE00707F; pat_reach[239] = 1;  // VADC_VVM
    pat_val[240] = 32'h44000057; pat_mask[240] = 32'hFE00707F; pat_reach[240] = 1;  // VMADC_VVM
    pat_val[241] = 32'h46000057; pat_mask[241] = 32'hFE00707F; pat_reach[241] = 1;  // VMADC_VV
    pat_val[242] = 32'h48000057; pat_mask[242] = 32'hFE00707F; pat_reach[242] = 1;  // VSBC_VVM
    pat_val[243] = 32'h4E000057; pat_mask[243] = 32'hFE00707F; pat_reach[243] = 1;  // VMSBC_VV
    pat_val[244] = 32'h4C000057; pat_mask[244] = 32'hFE00707F; pat_reach[244] = 1;  // VMSBC_VVM
    pat_val[245] = 32'h5C000057; pat_mask[245] = 32'hFE00707F; pat_reach[245] = 1;  // VMERGE_VVM
    pat_val[246] = 32'h5E000057; pat_mask[246] = 32'hFFF0707F; pat_reach[246] = 1;  // VMV_V_V
    pat_val[247] = 32'h60000057; pat_mask[247] = 32'hFC00707F; pat_reach[247] = 1;  // VMSEQ_VV
    pat_val[248] = 32'h64000057; pat_mask[248] = 32'hFC00707F; pat_reach[248] = 1;  // VMSNE_VV
    pat_val[249] = 32'h68000057; pat_mask[249] = 32'hFC00707F; pat_reach[249] = 1;  // VMSLTU_VV
    pat_val[250] = 32'h6C000057; pat_mask[250] = 32'hFC00707F; pat_reach[250] = 1;  // VMSLT_VV
    pat_val[251] = 32'h70000057; pat_mask[251] = 32'hFC00707F; pat_reach[251] = 1;  // VMSLEU_VV
    pat_val[252] = 32'h74000057; pat_mask[252] = 32'hFC00707F; pat_reach[252] = 1;  // VMSLE_VV
    pat_val[253] = 32'h94000057; pat_mask[253] = 32'hFC00707F; pat_reach[253] = 1;  // VSLL_VV
    pat_val[254] = 32'hA0000057; pat_mask[254] = 32'hFC00707F; pat_reach[254] = 1;  // VSRL_VV
    pat_val[255] = 32'hA4000057; pat_mask[255] = 32'hFC00707F; pat_reach[255] = 1;  // VSRA_VV
    pat_val[256] = 32'hB0000057; pat_mask[256] = 32'hFC00707F; pat_reach[256] = 1;  // VNSRL_WV
    pat_val[257] = 32'hB4000057; pat_mask[257] = 32'hFC00707F; pat_reach[257] = 1;  // VNSRA_WV
    pat_val[258] = 32'h80000057; pat_mask[258] = 32'hFC00707F; pat_reach[258] = 1;  // VSADDU_VV
    pat_val[259] = 32'h84000057; pat_mask[259] = 32'hFC00707F; pat_reach[259] = 1;  // VSADD_VV
    pat_val[260] = 32'h88000057; pat_mask[260] = 32'hFC00707F; pat_reach[260] = 1;  // VSSUBU_VV
    pat_val[261] = 32'h8C000057; pat_mask[261] = 32'hFC00707F; pat_reach[261] = 1;  // VSSUB_VV
    pat_val[262] = 32'h9C000057; pat_mask[262] = 32'hFC00707F; pat_reach[262] = 1;  // VSMUL_VV
    pat_val[263] = 32'hA8000057; pat_mask[263] = 32'hFC00707F; pat_reach[263] = 1;  // VSSRL_VV
    pat_val[264] = 32'hAC000057; pat_mask[264] = 32'hFC00707F; pat_reach[264] = 1;  // VSSRA_VV
    pat_val[265] = 32'hB8000057; pat_mask[265] = 32'hFC00707F; pat_reach[265] = 1;  // VNCLIPU_WV
    pat_val[266] = 32'hBC000057; pat_mask[266] = 32'hFC00707F; pat_reach[266] = 1;  // VNCLIP_WV
    pat_val[267] = 32'hC0000057; pat_mask[267] = 32'hFC00707F; pat_reach[267] = 1;  // VWREDSUMU_VS
    pat_val[268] = 32'hC4000057; pat_mask[268] = 32'hFC00707F; pat_reach[268] = 1;  // VWREDSUM_VS
    pat_val[269] = 32'h04000057; pat_mask[269] = 32'hFC00707F; pat_reach[269] = 1;  // VANDN_VV
    pat_val[270] = 32'h54000057; pat_mask[270] = 32'hFC00707F; pat_reach[270] = 1;  // VROL_VV
    pat_val[271] = 32'h50000057; pat_mask[271] = 32'hFC00707F; pat_reach[271] = 1;  // VROR_VV
    pat_val[272] = 32'hD4000057; pat_mask[272] = 32'hFC00707F; pat_reach[272] = 1;  // VWSLL_VV
    pat_val[273] = 32'h00004057; pat_mask[273] = 32'hFC00707F; pat_reach[273] = 1;  // VADD_VX
    pat_val[274] = 32'h08004057; pat_mask[274] = 32'hFC00707F; pat_reach[274] = 1;  // VSUB_VX
    pat_val[275] = 32'h0C004057; pat_mask[275] = 32'hFC00707F; pat_reach[275] = 1;  // VRSUB_VX
    pat_val[276] = 32'h10004057; pat_mask[276] = 32'hFC00707F; pat_reach[276] = 1;  // VMINU_VX
    pat_val[277] = 32'h14004057; pat_mask[277] = 32'hFC00707F; pat_reach[277] = 1;  // VMIN_VX
    pat_val[278] = 32'h18004057; pat_mask[278] = 32'hFC00707F; pat_reach[278] = 1;  // VMAXU_VX
    pat_val[279] = 32'h1C004057; pat_mask[279] = 32'hFC00707F; pat_reach[279] = 1;  // VMAX_VX
    pat_val[280] = 32'h24004057; pat_mask[280] = 32'hFC00707F; pat_reach[280] = 1;  // VAND_VX
    pat_val[281] = 32'h28004057; pat_mask[281] = 32'hFC00707F; pat_reach[281] = 1;  // VOR_VX
    pat_val[282] = 32'h2C004057; pat_mask[282] = 32'hFC00707F; pat_reach[282] = 1;  // VXOR_VX
    pat_val[283] = 32'h30004057; pat_mask[283] = 32'hFC00707F; pat_reach[283] = 1;  // VRGATHER_VX
    pat_val[284] = 32'h38004057; pat_mask[284] = 32'hFC00707F; pat_reach[284] = 1;  // VSLIDEUP_VX
    pat_val[285] = 32'h3C004057; pat_mask[285] = 32'hFC00707F; pat_reach[285] = 1;  // VSLIDEDOWN_VX
    pat_val[286] = 32'h40004057; pat_mask[286] = 32'hFE00707F; pat_reach[286] = 1;  // VADC_VXM
    pat_val[287] = 32'h44004057; pat_mask[287] = 32'hFE00707F; pat_reach[287] = 1;  // VMADC_VXM
    pat_val[288] = 32'h46004057; pat_mask[288] = 32'hFE00707F; pat_reach[288] = 1;  // VMADC_VX
    pat_val[289] = 32'h48004057; pat_mask[289] = 32'hFE00707F; pat_reach[289] = 1;  // VSBC_VXM
    pat_val[290] = 32'h4E004057; pat_mask[290] = 32'hFE00707F; pat_reach[290] = 1;  // VMSBC_VX
    pat_val[291] = 32'h4C004057; pat_mask[291] = 32'hFE00707F; pat_reach[291] = 1;  // VMSBC_VXM
    pat_val[292] = 32'h5C004057; pat_mask[292] = 32'hFE00707F; pat_reach[292] = 1;  // VMERGE_VXM
    pat_val[293] = 32'h5E004057; pat_mask[293] = 32'hFFF0707F; pat_reach[293] = 1;  // VMV_V_X
    pat_val[294] = 32'h60004057; pat_mask[294] = 32'hFC00707F; pat_reach[294] = 1;  // VMSEQ_VX
    pat_val[295] = 32'h64004057; pat_mask[295] = 32'hFC00707F; pat_reach[295] = 1;  // VMSNE_VX
    pat_val[296] = 32'h68004057; pat_mask[296] = 32'hFC00707F; pat_reach[296] = 1;  // VMSLTU_VX
    pat_val[297] = 32'h6C004057; pat_mask[297] = 32'hFC00707F; pat_reach[297] = 1;  // VMSLT_VX
    pat_val[298] = 32'h70004057; pat_mask[298] = 32'hFC00707F; pat_reach[298] = 1;  // VMSLEU_VX
    pat_val[299] = 32'h74004057; pat_mask[299] = 32'hFC00707F; pat_reach[299] = 1;  // VMSLE_VX
    pat_val[300] = 32'h78004057; pat_mask[300] = 32'hFC00707F; pat_reach[300] = 1;  // VMSGTU_VX
    pat_val[301] = 32'h7C004057; pat_mask[301] = 32'hFC00707F; pat_reach[301] = 1;  // VMSGT_VX
    pat_val[302] = 32'h94004057; pat_mask[302] = 32'hFC00707F; pat_reach[302] = 1;  // VSLL_VX
    pat_val[303] = 32'hA0004057; pat_mask[303] = 32'hFC00707F; pat_reach[303] = 1;  // VSRL_VX
    pat_val[304] = 32'hA4004057; pat_mask[304] = 32'hFC00707F; pat_reach[304] = 1;  // VSRA_VX
    pat_val[305] = 32'hB0004057; pat_mask[305] = 32'hFC00707F; pat_reach[305] = 1;  // VNSRL_WX
    pat_val[306] = 32'hB4004057; pat_mask[306] = 32'hFC00707F; pat_reach[306] = 1;  // VNSRA_WX
    pat_val[307] = 32'h80004057; pat_mask[307] = 32'hFC00707F; pat_reach[307] = 1;  // VSADDU_VX
    pat_val[308] = 32'h84004057; pat_mask[308] = 32'hFC00707F; pat_reach[308] = 1;  // VSADD_VX
    pat_val[309] = 32'h88004057; pat_mask[309] = 32'hFC00707F; pat_reach[309] = 1;  // VSSUBU_VX
    pat_val[310] = 32'h8C004057; pat_mask[310] = 32'hFC00707F; pat_reach[310] = 1;  // VSSUB_VX
    pat_val[311] = 32'h9C004057; pat_mask[311] = 32'hFC00707F; pat_reach[311] = 1;  // VSMUL_VX
    pat_val[312] = 32'hA8004057; pat_mask[312] = 32'hFC00707F; pat_reach[312] = 1;  // VSSRL_VX
    pat_val[313] = 32'hAC004057; pat_mask[313] = 32'hFC00707F; pat_reach[313] = 1;  // VSSRA_VX
    pat_val[314] = 32'hB8004057; pat_mask[314] = 32'hFC00707F; pat_reach[314] = 1;  // VNCLIPU_WX
    pat_val[315] = 32'hBC004057; pat_mask[315] = 32'hFC00707F; pat_reach[315] = 1;  // VNCLIP_WX
    pat_val[316] = 32'h04004057; pat_mask[316] = 32'hFC00707F; pat_reach[316] = 1;  // VANDN_VX
    pat_val[317] = 32'h54004057; pat_mask[317] = 32'hFC00707F; pat_reach[317] = 1;  // VROL_VX
    pat_val[318] = 32'h50004057; pat_mask[318] = 32'hFC00707F; pat_reach[318] = 1;  // VROR_VX
    pat_val[319] = 32'hD4004057; pat_mask[319] = 32'hFC00707F; pat_reach[319] = 1;  // VWSLL_VX
    pat_val[320] = 32'h00003057; pat_mask[320] = 32'hFC00707F; pat_reach[320] = 1;  // VADD_VI
    pat_val[321] = 32'h0C003057; pat_mask[321] = 32'hFC00707F; pat_reach[321] = 1;  // VRSUB_VI
    pat_val[322] = 32'h24003057; pat_mask[322] = 32'hFC00707F; pat_reach[322] = 1;  // VAND_VI
    pat_val[323] = 32'h28003057; pat_mask[323] = 32'hFC00707F; pat_reach[323] = 1;  // VOR_VI
    pat_val[324] = 32'h2C003057; pat_mask[324] = 32'hFC00707F; pat_reach[324] = 1;  // VXOR_VI
    pat_val[325] = 32'h30003057; pat_mask[325] = 32'hFC00707F; pat_reach[325] = 1;  // VRGATHER_VI
    pat_val[326] = 32'h38003057; pat_mask[326] = 32'hFC00707F; pat_reach[326] = 1;  // VSLIDEUP_VI
    pat_val[327] = 32'h3C003057; pat_mask[327] = 32'hFC00707F; pat_reach[327] = 1;  // VSLIDEDOWN_VI
    pat_val[328] = 32'h40003057; pat_mask[328] = 32'hFE00707F; pat_reach[328] = 1;  // VADC_VIM
    pat_val[329] = 32'h44003057; pat_mask[329] = 32'hFE00707F; pat_reach[329] = 1;  // VMADC_VIM
    pat_val[330] = 32'h46003057; pat_mask[330] = 32'hFE00707F; pat_reach[330] = 1;  // VMADC_VI
    pat_val[331] = 32'h5C003057; pat_mask[331] = 32'hFE00707F; pat_reach[331] = 1;  // VMERGE_VIM
    pat_val[332] = 32'h5E003057; pat_mask[332] = 32'hFFF0707F; pat_reach[332] = 1;  // VMV_V_I
    pat_val[333] = 32'h60003057; pat_mask[333] = 32'hFC00707F; pat_reach[333] = 1;  // VMSEQ_VI
    pat_val[334] = 32'h64003057; pat_mask[334] = 32'hFC00707F; pat_reach[334] = 1;  // VMSNE_VI
    pat_val[335] = 32'h70003057; pat_mask[335] = 32'hFC00707F; pat_reach[335] = 1;  // VMSLEU_VI
    pat_val[336] = 32'h74003057; pat_mask[336] = 32'hFC00707F; pat_reach[336] = 1;  // VMSLE_VI
    pat_val[337] = 32'h78003057; pat_mask[337] = 32'hFC00707F; pat_reach[337] = 1;  // VMSGTU_VI
    pat_val[338] = 32'h7C003057; pat_mask[338] = 32'hFC00707F; pat_reach[338] = 1;  // VMSGT_VI
    pat_val[339] = 32'h94003057; pat_mask[339] = 32'hFC00707F; pat_reach[339] = 1;  // VSLL_VI
    pat_val[340] = 32'hA0003057; pat_mask[340] = 32'hFC00707F; pat_reach[340] = 1;  // VSRL_VI
    pat_val[341] = 32'hA4003057; pat_mask[341] = 32'hFC00707F; pat_reach[341] = 1;  // VSRA_VI
    pat_val[342] = 32'hB0003057; pat_mask[342] = 32'hFC00707F; pat_reach[342] = 1;  // VNSRL_WI
    pat_val[343] = 32'hB4003057; pat_mask[343] = 32'hFC00707F; pat_reach[343] = 1;  // VNSRA_WI
    pat_val[344] = 32'h80003057; pat_mask[344] = 32'hFC00707F; pat_reach[344] = 1;  // VSADDU_VI
    pat_val[345] = 32'h84003057; pat_mask[345] = 32'hFC00707F; pat_reach[345] = 1;  // VSADD_VI
    pat_val[346] = 32'hA8003057; pat_mask[346] = 32'hFC00707F; pat_reach[346] = 1;  // VSSRL_VI
    pat_val[347] = 32'hAC003057; pat_mask[347] = 32'hFC00707F; pat_reach[347] = 1;  // VSSRA_VI
    pat_val[348] = 32'hB8003057; pat_mask[348] = 32'hFC00707F; pat_reach[348] = 1;  // VNCLIPU_WI
    pat_val[349] = 32'hBC003057; pat_mask[349] = 32'hFC00707F; pat_reach[349] = 1;  // VNCLIP_WI
    pat_val[350] = 32'h9E003057; pat_mask[350] = 32'hFE0FF07F; pat_reach[350] = 1;  // VMV1R_V
    pat_val[351] = 32'h9E00B057; pat_mask[351] = 32'hFE0FF07F; pat_reach[351] = 1;  // VMV2R_V
    pat_val[352] = 32'h9E01B057; pat_mask[352] = 32'hFE0FF07F; pat_reach[352] = 1;  // VMV4R_V
    pat_val[353] = 32'h9E03B057; pat_mask[353] = 32'hFE0FF07F; pat_reach[353] = 1;  // VMV8R_V
    pat_val[354] = 32'h50003057; pat_mask[354] = 32'hF800707F; pat_reach[354] = 1;  // VROR_VI
    pat_val[355] = 32'hD4003057; pat_mask[355] = 32'hFC00707F; pat_reach[355] = 1;  // VWSLL_VI
    pat_val[356] = 32'h24002057; pat_mask[356] = 32'hFC00707F; pat_reach[356] = 1;  // VAADD_VV
    pat_val[357] = 32'h20002057; pat_mask[357] = 32'hFC00707F; pat_reach[357] = 1;  // VAADDU_VV
    pat_val[358] = 32'h2C002057; pat_mask[358] = 32'hFC00707F; pat_reach[358] = 1;  // VASUB_VV
    pat_val[359] = 32'h28002057; pat_mask[359] = 32'hFC00707F; pat_reach[359] = 1;  // VASUBU_VV
    pat_val[360] = 32'h5E002057; pat_mask[360] = 32'hFE00707F; pat_reach[360] = 1;  // VCOMPRESS_VM
    pat_val[361] = 32'h40082057; pat_mask[361] = 32'hFC0FF07F; pat_reach[361] = 1;  // VCPOP_M
    pat_val[362] = 32'h84002057; pat_mask[362] = 32'hFC00707F; pat_reach[362] = 1;  // VDIV_VV
    pat_val[363] = 32'h80002057; pat_mask[363] = 32'hFC00707F; pat_reach[363] = 1;  // VDIVU_VV
    pat_val[364] = 32'h4008A057; pat_mask[364] = 32'hFC0FF07F; pat_reach[364] = 1;  // VFIRST_M
    pat_val[365] = 32'h5008A057; pat_mask[365] = 32'hFDFFF07F; pat_reach[365] = 1;  // VID_V
    pat_val[366] = 32'h50082057; pat_mask[366] = 32'hFC0FF07F; pat_reach[366] = 1;  // VIOTA_M
    pat_val[367] = 32'hB4002057; pat_mask[367] = 32'hFC00707F; pat_reach[367] = 1;  // VMACC_VV
    pat_val[368] = 32'hA4002057; pat_mask[368] = 32'hFC00707F; pat_reach[368] = 1;  // VMADD_VV
    pat_val[369] = 32'h66002057; pat_mask[369] = 32'hFE00707F; pat_reach[369] = 1;  // VMAND_MM
    pat_val[370] = 32'h62002057; pat_mask[370] = 32'hFE00707F; pat_reach[370] = 1;  // VMANDN_MM
    pat_val[371] = 32'h76002057; pat_mask[371] = 32'hFE00707F; pat_reach[371] = 1;  // VMNAND_MM
    pat_val[372] = 32'h7A002057; pat_mask[372] = 32'hFE00707F; pat_reach[372] = 1;  // VMNOR_MM
    pat_val[373] = 32'h6A002057; pat_mask[373] = 32'hFE00707F; pat_reach[373] = 1;  // VMOR_MM
    pat_val[374] = 32'h72002057; pat_mask[374] = 32'hFE00707F; pat_reach[374] = 1;  // VMORN_MM
    pat_val[375] = 32'h7E002057; pat_mask[375] = 32'hFE00707F; pat_reach[375] = 1;  // VMXNOR_MM
    pat_val[376] = 32'h6E002057; pat_mask[376] = 32'hFE00707F; pat_reach[376] = 1;  // VMXOR_MM
    pat_val[377] = 32'h5000A057; pat_mask[377] = 32'hFC0FF07F; pat_reach[377] = 1;  // VMSBF_M
    pat_val[378] = 32'h5001A057; pat_mask[378] = 32'hFC0FF07F; pat_reach[378] = 1;  // VMSIF_M
    pat_val[379] = 32'h50012057; pat_mask[379] = 32'hFC0FF07F; pat_reach[379] = 1;  // VMSOF_M
    pat_val[380] = 32'h94002057; pat_mask[380] = 32'hFC00707F; pat_reach[380] = 1;  // VMUL_VV
    pat_val[381] = 32'h9C002057; pat_mask[381] = 32'hFC00707F; pat_reach[381] = 1;  // VMULH_VV
    pat_val[382] = 32'h98002057; pat_mask[382] = 32'hFC00707F; pat_reach[382] = 1;  // VMULHSU_VV
    pat_val[383] = 32'h90002057; pat_mask[383] = 32'hFC00707F; pat_reach[383] = 1;  // VMULHU_VV
    pat_val[384] = 32'h42002057; pat_mask[384] = 32'hFE0FF07F; pat_reach[384] = 1;  // VMV_X_S
    pat_val[385] = 32'hBC002057; pat_mask[385] = 32'hFC00707F; pat_reach[385] = 1;  // VNMSAC_VV
    pat_val[386] = 32'hAC002057; pat_mask[386] = 32'hFC00707F; pat_reach[386] = 1;  // VNMSUB_VV
    pat_val[387] = 32'h04002057; pat_mask[387] = 32'hFC00707F; pat_reach[387] = 1;  // VREDAND_VS
    pat_val[388] = 32'h1C002057; pat_mask[388] = 32'hFC00707F; pat_reach[388] = 1;  // VREDMAX_VS
    pat_val[389] = 32'h18002057; pat_mask[389] = 32'hFC00707F; pat_reach[389] = 1;  // VREDMAXU_VS
    pat_val[390] = 32'h14002057; pat_mask[390] = 32'hFC00707F; pat_reach[390] = 1;  // VREDMIN_VS
    pat_val[391] = 32'h10002057; pat_mask[391] = 32'hFC00707F; pat_reach[391] = 1;  // VREDMINU_VS
    pat_val[392] = 32'h08002057; pat_mask[392] = 32'hFC00707F; pat_reach[392] = 1;  // VREDOR_VS
    pat_val[393] = 32'h00002057; pat_mask[393] = 32'hFC00707F; pat_reach[393] = 1;  // VREDSUM_VS
    pat_val[394] = 32'h0C002057; pat_mask[394] = 32'hFC00707F; pat_reach[394] = 1;  // VREDXOR_VS
    pat_val[395] = 32'h8C002057; pat_mask[395] = 32'hFC00707F; pat_reach[395] = 1;  // VREM_VV
    pat_val[396] = 32'h88002057; pat_mask[396] = 32'hFC00707F; pat_reach[396] = 1;  // VREMU_VV
    pat_val[397] = 32'h4803A057; pat_mask[397] = 32'hFC0FF07F; pat_reach[397] = 1;  // VSEXT_VF2
    pat_val[398] = 32'h4802A057; pat_mask[398] = 32'hFC0FF07F; pat_reach[398] = 1;  // VSEXT_VF4
    pat_val[399] = 32'h4801A057; pat_mask[399] = 32'hFC0FF07F; pat_reach[399] = 1;  // VSEXT_VF8
    pat_val[400] = 32'h48032057; pat_mask[400] = 32'hFC0FF07F; pat_reach[400] = 1;  // VZEXT_VF2
    pat_val[401] = 32'h48022057; pat_mask[401] = 32'hFC0FF07F; pat_reach[401] = 1;  // VZEXT_VF4
    pat_val[402] = 32'h48012057; pat_mask[402] = 32'hFC0FF07F; pat_reach[402] = 1;  // VZEXT_VF8
    pat_val[403] = 32'hC4002057; pat_mask[403] = 32'hFC00707F; pat_reach[403] = 1;  // VWADD_VV
    pat_val[404] = 32'hD4002057; pat_mask[404] = 32'hFC00707F; pat_reach[404] = 1;  // VWADD_WV
    pat_val[405] = 32'hC0002057; pat_mask[405] = 32'hFC00707F; pat_reach[405] = 1;  // VWADDU_VV
    pat_val[406] = 32'hD0002057; pat_mask[406] = 32'hFC00707F; pat_reach[406] = 1;  // VWADDU_WV
    pat_val[407] = 32'hF4002057; pat_mask[407] = 32'hFC00707F; pat_reach[407] = 1;  // VWMACC_VV
    pat_val[408] = 32'hFC002057; pat_mask[408] = 32'hFC00707F; pat_reach[408] = 1;  // VWMACCSU_VV
    pat_val[409] = 32'hF0002057; pat_mask[409] = 32'hFC00707F; pat_reach[409] = 1;  // VWMACCU_VV
    pat_val[410] = 32'hEC002057; pat_mask[410] = 32'hFC00707F; pat_reach[410] = 1;  // VWMUL_VV
    pat_val[411] = 32'hE8002057; pat_mask[411] = 32'hFC00707F; pat_reach[411] = 1;  // VWMULSU_VV
    pat_val[412] = 32'hE0002057; pat_mask[412] = 32'hFC00707F; pat_reach[412] = 1;  // VWMULU_VV
    pat_val[413] = 32'hCC002057; pat_mask[413] = 32'hFC00707F; pat_reach[413] = 1;  // VWSUB_VV
    pat_val[414] = 32'hDC002057; pat_mask[414] = 32'hFC00707F; pat_reach[414] = 1;  // VWSUB_WV
    pat_val[415] = 32'hC8002057; pat_mask[415] = 32'hFC00707F; pat_reach[415] = 1;  // VWSUBU_VV
    pat_val[416] = 32'hD8002057; pat_mask[416] = 32'hFC00707F; pat_reach[416] = 1;  // VWSUBU_WV
    pat_val[417] = 32'h48052057; pat_mask[417] = 32'hFC0FF07F; pat_reach[417] = 1;  // VBREV_V
    pat_val[418] = 32'h48042057; pat_mask[418] = 32'hFC0FF07F; pat_reach[418] = 1;  // VBREV8_V
    pat_val[419] = 32'h4804A057; pat_mask[419] = 32'hFC0FF07F; pat_reach[419] = 1;  // VREV8_V
    pat_val[420] = 32'h48062057; pat_mask[420] = 32'hFC0FF07F; pat_reach[420] = 1;  // VCLZ_V
    pat_val[421] = 32'h4806A057; pat_mask[421] = 32'hFC0FF07F; pat_reach[421] = 1;  // VCTZ_V
    pat_val[422] = 32'h48072057; pat_mask[422] = 32'hFC0FF07F; pat_reach[422] = 1;  // VCPOP_V
    pat_val[423] = 32'h24006057; pat_mask[423] = 32'hFC00707F; pat_reach[423] = 1;  // VAADD_VX
    pat_val[424] = 32'h20006057; pat_mask[424] = 32'hFC00707F; pat_reach[424] = 1;  // VAADDU_VX
    pat_val[425] = 32'h2C006057; pat_mask[425] = 32'hFC00707F; pat_reach[425] = 1;  // VASUB_VX
    pat_val[426] = 32'h28006057; pat_mask[426] = 32'hFC00707F; pat_reach[426] = 1;  // VASUBU_VX
    pat_val[427] = 32'h84006057; pat_mask[427] = 32'hFC00707F; pat_reach[427] = 1;  // VDIV_VX
    pat_val[428] = 32'h80006057; pat_mask[428] = 32'hFC00707F; pat_reach[428] = 1;  // VDIVU_VX
    pat_val[429] = 32'hB4006057; pat_mask[429] = 32'hFC00707F; pat_reach[429] = 1;  // VMACC_VX
    pat_val[430] = 32'hA4006057; pat_mask[430] = 32'hFC00707F; pat_reach[430] = 1;  // VMADD_VX
    pat_val[431] = 32'h94006057; pat_mask[431] = 32'hFC00707F; pat_reach[431] = 1;  // VMUL_VX
    pat_val[432] = 32'h9C006057; pat_mask[432] = 32'hFC00707F; pat_reach[432] = 1;  // VMULH_VX
    pat_val[433] = 32'h98006057; pat_mask[433] = 32'hFC00707F; pat_reach[433] = 1;  // VMULHSU_VX
    pat_val[434] = 32'h90006057; pat_mask[434] = 32'hFC00707F; pat_reach[434] = 1;  // VMULHU_VX
    pat_val[435] = 32'h42006057; pat_mask[435] = 32'hFFF0707F; pat_reach[435] = 1;  // VMV_S_X
    pat_val[436] = 32'hBC006057; pat_mask[436] = 32'hFC00707F; pat_reach[436] = 1;  // VNMSAC_VX
    pat_val[437] = 32'hAC006057; pat_mask[437] = 32'hFC00707F; pat_reach[437] = 1;  // VNMSUB_VX
    pat_val[438] = 32'h8C006057; pat_mask[438] = 32'hFC00707F; pat_reach[438] = 1;  // VREM_VX
    pat_val[439] = 32'h88006057; pat_mask[439] = 32'hFC00707F; pat_reach[439] = 1;  // VREMU_VX
    pat_val[440] = 32'h3C006057; pat_mask[440] = 32'hFC00707F; pat_reach[440] = 1;  // VSLIDE1DOWN_VX
    pat_val[441] = 32'h38006057; pat_mask[441] = 32'hFC00707F; pat_reach[441] = 1;  // VSLIDE1UP_VX
    pat_val[442] = 32'hC4006057; pat_mask[442] = 32'hFC00707F; pat_reach[442] = 1;  // VWADD_VX
    pat_val[443] = 32'hD4006057; pat_mask[443] = 32'hFC00707F; pat_reach[443] = 1;  // VWADD_WX
    pat_val[444] = 32'hC0006057; pat_mask[444] = 32'hFC00707F; pat_reach[444] = 1;  // VWADDU_VX
    pat_val[445] = 32'hD0006057; pat_mask[445] = 32'hFC00707F; pat_reach[445] = 1;  // VWADDU_WX
    pat_val[446] = 32'hF4006057; pat_mask[446] = 32'hFC00707F; pat_reach[446] = 1;  // VWMACC_VX
    pat_val[447] = 32'hFC006057; pat_mask[447] = 32'hFC00707F; pat_reach[447] = 1;  // VWMACCSU_VX
    pat_val[448] = 32'hF0006057; pat_mask[448] = 32'hFC00707F; pat_reach[448] = 1;  // VWMACCU_VX
    pat_val[449] = 32'hF8006057; pat_mask[449] = 32'hFC00707F; pat_reach[449] = 1;  // VWMACCUS_VX
    pat_val[450] = 32'hEC006057; pat_mask[450] = 32'hFC00707F; pat_reach[450] = 1;  // VWMUL_VX
    pat_val[451] = 32'hE8006057; pat_mask[451] = 32'hFC00707F; pat_reach[451] = 1;  // VWMULSU_VX
    pat_val[452] = 32'hE0006057; pat_mask[452] = 32'hFC00707F; pat_reach[452] = 1;  // VWMULU_VX
    pat_val[453] = 32'hCC006057; pat_mask[453] = 32'hFC00707F; pat_reach[453] = 1;  // VWSUB_VX
    pat_val[454] = 32'hDC006057; pat_mask[454] = 32'hFC00707F; pat_reach[454] = 1;  // VWSUB_WX
    pat_val[455] = 32'hC8006057; pat_mask[455] = 32'hFC00707F; pat_reach[455] = 1;  // VWSUBU_VX
    pat_val[456] = 32'hD8006057; pat_mask[456] = 32'hFC00707F; pat_reach[456] = 1;  // VWSUBU_WX
    pat_val[457] = 32'h00001057; pat_mask[457] = 32'hFC00707F; pat_reach[457] = 1;  // VFADD_VV
    pat_val[458] = 32'h08001057; pat_mask[458] = 32'hFC00707F; pat_reach[458] = 1;  // VFSUB_VV
    pat_val[459] = 32'hC0001057; pat_mask[459] = 32'hFC00707F; pat_reach[459] = 1;  // VFWADD_VV
    pat_val[460] = 32'hC8001057; pat_mask[460] = 32'hFC00707F; pat_reach[460] = 1;  // VFWSUB_VV
    pat_val[461] = 32'hD0001057; pat_mask[461] = 32'hFC00707F; pat_reach[461] = 1;  // VFWADD_WV
    pat_val[462] = 32'hD8001057; pat_mask[462] = 32'hFC00707F; pat_reach[462] = 1;  // VFWSUB_WV
    pat_val[463] = 32'h90001057; pat_mask[463] = 32'hFC00707F; pat_reach[463] = 1;  // VFMUL_VV
    pat_val[464] = 32'h80001057; pat_mask[464] = 32'hFC00707F; pat_reach[464] = 1;  // VFDIV_VV
    pat_val[465] = 32'hE0001057; pat_mask[465] = 32'hFC00707F; pat_reach[465] = 1;  // VFWMUL_VV
    pat_val[466] = 32'hB0001057; pat_mask[466] = 32'hFC00707F; pat_reach[466] = 1;  // VFMACC_VV
    pat_val[467] = 32'hB4001057; pat_mask[467] = 32'hFC00707F; pat_reach[467] = 1;  // VFNMACC_VV
    pat_val[468] = 32'hB8001057; pat_mask[468] = 32'hFC00707F; pat_reach[468] = 1;  // VFMSAC_VV
    pat_val[469] = 32'hBC001057; pat_mask[469] = 32'hFC00707F; pat_reach[469] = 1;  // VFNMSAC_VV
    pat_val[470] = 32'hA0001057; pat_mask[470] = 32'hFC00707F; pat_reach[470] = 1;  // VFMADD_VV
    pat_val[471] = 32'hA4001057; pat_mask[471] = 32'hFC00707F; pat_reach[471] = 1;  // VFNMADD_VV
    pat_val[472] = 32'hA8001057; pat_mask[472] = 32'hFC00707F; pat_reach[472] = 1;  // VFMSUB_VV
    pat_val[473] = 32'hAC001057; pat_mask[473] = 32'hFC00707F; pat_reach[473] = 1;  // VFNMSUB_VV
    pat_val[474] = 32'hF0001057; pat_mask[474] = 32'hFC00707F; pat_reach[474] = 1;  // VFWMACC_VV
    pat_val[475] = 32'hF4001057; pat_mask[475] = 32'hFC00707F; pat_reach[475] = 1;  // VFWNMACC_VV
    pat_val[476] = 32'hF8001057; pat_mask[476] = 32'hFC00707F; pat_reach[476] = 1;  // VFWMSAC_VV
    pat_val[477] = 32'hFC001057; pat_mask[477] = 32'hFC00707F; pat_reach[477] = 1;  // VFWNMSAC_VV
    pat_val[478] = 32'h4C001057; pat_mask[478] = 32'hFC0FF07F; pat_reach[478] = 1;  // VFSQRT_V
    pat_val[479] = 32'h4C021057; pat_mask[479] = 32'hFC0FF07F; pat_reach[479] = 1;  // VFRSQRT7_V
    pat_val[480] = 32'h4C029057; pat_mask[480] = 32'hFC0FF07F; pat_reach[480] = 1;  // VFREC7_V
    pat_val[481] = 32'h10001057; pat_mask[481] = 32'hFC00707F; pat_reach[481] = 1;  // VFMIN_VV
    pat_val[482] = 32'h18001057; pat_mask[482] = 32'hFC00707F; pat_reach[482] = 1;  // VFMAX_VV
    pat_val[483] = 32'h20001057; pat_mask[483] = 32'hFC00707F; pat_reach[483] = 1;  // VFSGNJ_VV
    pat_val[484] = 32'h24001057; pat_mask[484] = 32'hFC00707F; pat_reach[484] = 1;  // VFSGNJN_VV
    pat_val[485] = 32'h28001057; pat_mask[485] = 32'hFC00707F; pat_reach[485] = 1;  // VFSGNJX_VV
    pat_val[486] = 32'h60001057; pat_mask[486] = 32'hFC00707F; pat_reach[486] = 1;  // VMFEQ_VV
    pat_val[487] = 32'h70001057; pat_mask[487] = 32'hFC00707F; pat_reach[487] = 1;  // VMFNE_VV
    pat_val[488] = 32'h6C001057; pat_mask[488] = 32'hFC00707F; pat_reach[488] = 1;  // VMFLT_VV
    pat_val[489] = 32'h64001057; pat_mask[489] = 32'hFC00707F; pat_reach[489] = 1;  // VMFLE_VV
    pat_val[490] = 32'h4C081057; pat_mask[490] = 32'hFC0FF07F; pat_reach[490] = 1;  // VFCLASS_V
    pat_val[491] = 32'h48001057; pat_mask[491] = 32'hFC0FF07F; pat_reach[491] = 1;  // VFCVT_XU_F_V
    pat_val[492] = 32'h48009057; pat_mask[492] = 32'hFC0FF07F; pat_reach[492] = 1;  // VFCVT_X_F_V
    pat_val[493] = 32'h48031057; pat_mask[493] = 32'hFC0FF07F; pat_reach[493] = 1;  // VFCVT_RTZ_XU_F_V
    pat_val[494] = 32'h48039057; pat_mask[494] = 32'hFC0FF07F; pat_reach[494] = 1;  // VFCVT_RTZ_X_F_V
    pat_val[495] = 32'h48011057; pat_mask[495] = 32'hFC0FF07F; pat_reach[495] = 1;  // VFCVT_F_XU_V
    pat_val[496] = 32'h48019057; pat_mask[496] = 32'hFC0FF07F; pat_reach[496] = 1;  // VFCVT_F_X_V
    pat_val[497] = 32'h48041057; pat_mask[497] = 32'hFC0FF07F; pat_reach[497] = 1;  // VFWCVT_XU_F_V
    pat_val[498] = 32'h48049057; pat_mask[498] = 32'hFC0FF07F; pat_reach[498] = 1;  // VFWCVT_X_F_V
    pat_val[499] = 32'h48071057; pat_mask[499] = 32'hFC0FF07F; pat_reach[499] = 1;  // VFWCVT_RTZ_XU_F_V
    pat_val[500] = 32'h48079057; pat_mask[500] = 32'hFC0FF07F; pat_reach[500] = 1;  // VFWCVT_RTZ_X_F_V
    pat_val[501] = 32'h48051057; pat_mask[501] = 32'hFC0FF07F; pat_reach[501] = 1;  // VFWCVT_F_XU_V
    pat_val[502] = 32'h48059057; pat_mask[502] = 32'hFC0FF07F; pat_reach[502] = 1;  // VFWCVT_F_X_V
    pat_val[503] = 32'h48061057; pat_mask[503] = 32'hFC0FF07F; pat_reach[503] = 1;  // VFWCVT_F_F_V
    pat_val[504] = 32'h48081057; pat_mask[504] = 32'hFC0FF07F; pat_reach[504] = 1;  // VFNCVT_XU_F_W
    pat_val[505] = 32'h48089057; pat_mask[505] = 32'hFC0FF07F; pat_reach[505] = 1;  // VFNCVT_X_F_W
    pat_val[506] = 32'h480B1057; pat_mask[506] = 32'hFC0FF07F; pat_reach[506] = 1;  // VFNCVT_RTZ_XU_F_W
    pat_val[507] = 32'h480B9057; pat_mask[507] = 32'hFC0FF07F; pat_reach[507] = 1;  // VFNCVT_RTZ_X_F_W
    pat_val[508] = 32'h48091057; pat_mask[508] = 32'hFC0FF07F; pat_reach[508] = 1;  // VFNCVT_F_XU_W
    pat_val[509] = 32'h48099057; pat_mask[509] = 32'hFC0FF07F; pat_reach[509] = 1;  // VFNCVT_F_X_W
    pat_val[510] = 32'h480A1057; pat_mask[510] = 32'hFC0FF07F; pat_reach[510] = 1;  // VFNCVT_F_F_W
    pat_val[511] = 32'h480A9057; pat_mask[511] = 32'hFC0FF07F; pat_reach[511] = 1;  // VFNCVT_ROD_F_F_W
    pat_val[512] = 32'h0C001057; pat_mask[512] = 32'hFC00707F; pat_reach[512] = 1;  // VFREDOSUM_VS
    pat_val[513] = 32'h04001057; pat_mask[513] = 32'hFC00707F; pat_reach[513] = 1;  // VFREDUSUM_VS
    pat_val[514] = 32'h1C001057; pat_mask[514] = 32'hFC00707F; pat_reach[514] = 1;  // VFREDMAX_VS
    pat_val[515] = 32'h14001057; pat_mask[515] = 32'hFC00707F; pat_reach[515] = 1;  // VFREDMIN_VS
    pat_val[516] = 32'hCC001057; pat_mask[516] = 32'hFC00707F; pat_reach[516] = 1;  // VFWREDOSUM_VS
    pat_val[517] = 32'hC4001057; pat_mask[517] = 32'hFC00707F; pat_reach[517] = 1;  // VFWREDUSUM_VS
    pat_val[518] = 32'h00005057; pat_mask[518] = 32'hFC00707F; pat_reach[518] = 1;  // VFADD_VF
    pat_val[519] = 32'h08005057; pat_mask[519] = 32'hFC00707F; pat_reach[519] = 1;  // VFSUB_VF
    pat_val[520] = 32'h9C005057; pat_mask[520] = 32'hFC00707F; pat_reach[520] = 1;  // VFRSUB_VF
    pat_val[521] = 32'hC0005057; pat_mask[521] = 32'hFC00707F; pat_reach[521] = 1;  // VFWADD_VF
    pat_val[522] = 32'hC8005057; pat_mask[522] = 32'hFC00707F; pat_reach[522] = 1;  // VFWSUB_VF
    pat_val[523] = 32'hD0005057; pat_mask[523] = 32'hFC00707F; pat_reach[523] = 1;  // VFWADD_WF
    pat_val[524] = 32'hD8005057; pat_mask[524] = 32'hFC00707F; pat_reach[524] = 1;  // VFWSUB_WF
    pat_val[525] = 32'h90005057; pat_mask[525] = 32'hFC00707F; pat_reach[525] = 1;  // VFMUL_VF
    pat_val[526] = 32'h80005057; pat_mask[526] = 32'hFC00707F; pat_reach[526] = 1;  // VFDIV_VF
    pat_val[527] = 32'h84005057; pat_mask[527] = 32'hFC00707F; pat_reach[527] = 1;  // VFRDIV_VF
    pat_val[528] = 32'hE0005057; pat_mask[528] = 32'hFC00707F; pat_reach[528] = 1;  // VFWMUL_VF
    pat_val[529] = 32'hB0005057; pat_mask[529] = 32'hFC00707F; pat_reach[529] = 1;  // VFMACC_VF
    pat_val[530] = 32'hB4005057; pat_mask[530] = 32'hFC00707F; pat_reach[530] = 1;  // VFNMACC_VF
    pat_val[531] = 32'hB8005057; pat_mask[531] = 32'hFC00707F; pat_reach[531] = 1;  // VFMSAC_VF
    pat_val[532] = 32'hBC005057; pat_mask[532] = 32'hFC00707F; pat_reach[532] = 1;  // VFNMSAC_VF
    pat_val[533] = 32'hA0005057; pat_mask[533] = 32'hFC00707F; pat_reach[533] = 1;  // VFMADD_VF
    pat_val[534] = 32'hA4005057; pat_mask[534] = 32'hFC00707F; pat_reach[534] = 1;  // VFNMADD_VF
    pat_val[535] = 32'hA8005057; pat_mask[535] = 32'hFC00707F; pat_reach[535] = 1;  // VFMSUB_VF
    pat_val[536] = 32'hAC005057; pat_mask[536] = 32'hFC00707F; pat_reach[536] = 1;  // VFNMSUB_VF
    pat_val[537] = 32'hF0005057; pat_mask[537] = 32'hFC00707F; pat_reach[537] = 1;  // VFWMACC_VF
    pat_val[538] = 32'hF4005057; pat_mask[538] = 32'hFC00707F; pat_reach[538] = 1;  // VFWNMACC_VF
    pat_val[539] = 32'hF8005057; pat_mask[539] = 32'hFC00707F; pat_reach[539] = 1;  // VFWMSAC_VF
    pat_val[540] = 32'hFC005057; pat_mask[540] = 32'hFC00707F; pat_reach[540] = 1;  // VFWNMSAC_VF
    pat_val[541] = 32'h10005057; pat_mask[541] = 32'hFC00707F; pat_reach[541] = 1;  // VFMIN_VF
    pat_val[542] = 32'h18005057; pat_mask[542] = 32'hFC00707F; pat_reach[542] = 1;  // VFMAX_VF
    pat_val[543] = 32'h20005057; pat_mask[543] = 32'hFC00707F; pat_reach[543] = 1;  // VFSGNJ_VF
    pat_val[544] = 32'h24005057; pat_mask[544] = 32'hFC00707F; pat_reach[544] = 1;  // VFSGNJN_VF
    pat_val[545] = 32'h28005057; pat_mask[545] = 32'hFC00707F; pat_reach[545] = 1;  // VFSGNJX_VF
    pat_val[546] = 32'h60005057; pat_mask[546] = 32'hFC00707F; pat_reach[546] = 1;  // VMFEQ_VF
    pat_val[547] = 32'h70005057; pat_mask[547] = 32'hFC00707F; pat_reach[547] = 1;  // VMFNE_VF
    pat_val[548] = 32'h6C005057; pat_mask[548] = 32'hFC00707F; pat_reach[548] = 1;  // VMFLT_VF
    pat_val[549] = 32'h64005057; pat_mask[549] = 32'hFC00707F; pat_reach[549] = 1;  // VMFLE_VF
    pat_val[550] = 32'h74005057; pat_mask[550] = 32'hFC00707F; pat_reach[550] = 1;  // VMFGT_VF
    pat_val[551] = 32'h7C005057; pat_mask[551] = 32'hFC00707F; pat_reach[551] = 1;  // VMFGE_VF
    pat_val[552] = 32'h5C005057; pat_mask[552] = 32'hFE00707F; pat_reach[552] = 1;  // VFMERGE_VFM
    pat_val[553] = 32'h5E005057; pat_mask[553] = 32'hFFF0707F; pat_reach[553] = 1;  // VFMV_V_F
    pat_val[554] = 32'h42001057; pat_mask[554] = 32'hFE0FF07F; pat_reach[554] = 1;  // VFMV_F_S
    pat_val[555] = 32'h42005057; pat_mask[555] = 32'hFFF0707F; pat_reach[555] = 1;  // VFMV_S_F
    pat_val[556] = 32'h38005057; pat_mask[556] = 32'hFC00707F; pat_reach[556] = 1;  // VFSLIDE1UP_VF
    pat_val[557] = 32'h3C005057; pat_mask[557] = 32'hFC00707F; pat_reach[557] = 1;  // VFSLIDE1DOWN_VF
    pat_val[558] = 32'h00000053; pat_mask[558] = 32'hFE00007F; pat_reach[558] = 1;  // FADD_S
    pat_val[559] = 32'h02000053; pat_mask[559] = 32'hFE00007F; pat_reach[559] = 1;  // FADD_D
    pat_val[560] = 32'h04000053; pat_mask[560] = 32'hFE00007F; pat_reach[560] = 1;  // FADD_H
    pat_val[561] = 32'h08000053; pat_mask[561] = 32'hFE00007F; pat_reach[561] = 1;  // FSUB_S
    pat_val[562] = 32'h0A000053; pat_mask[562] = 32'hFE00007F; pat_reach[562] = 1;  // FSUB_D
    pat_val[563] = 32'h0C000053; pat_mask[563] = 32'hFE00007F; pat_reach[563] = 1;  // FSUB_H
    pat_val[564] = 32'hA0002053; pat_mask[564] = 32'hFE00707F; pat_reach[564] = 1;  // FEQ_S
    pat_val[565] = 32'hA0001053; pat_mask[565] = 32'hFE00707F; pat_reach[565] = 1;  // FLT_S
    pat_val[566] = 32'hA0000053; pat_mask[566] = 32'hFE00707F; pat_reach[566] = 1;  // FLE_S
    pat_val[567] = 32'hA2002053; pat_mask[567] = 32'hFE00707F; pat_reach[567] = 1;  // FEQ_D
    pat_val[568] = 32'hA2001053; pat_mask[568] = 32'hFE00707F; pat_reach[568] = 1;  // FLT_D
    pat_val[569] = 32'hA2000053; pat_mask[569] = 32'hFE00707F; pat_reach[569] = 1;  // FLE_D
    pat_val[570] = 32'hA4002053; pat_mask[570] = 32'hFE00707F; pat_reach[570] = 1;  // FEQ_H
    pat_val[571] = 32'hA4001053; pat_mask[571] = 32'hFE00707F; pat_reach[571] = 1;  // FLT_H
    pat_val[572] = 32'hA4000053; pat_mask[572] = 32'hFE00707F; pat_reach[572] = 1;  // FLE_H
    pat_val[573] = 32'h28000053; pat_mask[573] = 32'hFE00707F; pat_reach[573] = 1;  // FMIN_S
    pat_val[574] = 32'h2A000053; pat_mask[574] = 32'hFE00707F; pat_reach[574] = 1;  // FMIN_D
    pat_val[575] = 32'h28001053; pat_mask[575] = 32'hFE00707F; pat_reach[575] = 1;  // FMAX_S
    pat_val[576] = 32'h2A001053; pat_mask[576] = 32'hFE00707F; pat_reach[576] = 1;  // FMAX_D
    pat_val[577] = 32'h2C000053; pat_mask[577] = 32'hFE00707F; pat_reach[577] = 1;  // FMIN_H
    pat_val[578] = 32'h2C001053; pat_mask[578] = 32'hFE00707F; pat_reach[578] = 1;  // FMAX_H
    pat_val[579] = 32'hC0000053; pat_mask[579] = 32'hFFF0007F; pat_reach[579] = 1;  // FCVT_W_S
    pat_val[580] = 32'hC0100053; pat_mask[580] = 32'hFFF0007F; pat_reach[580] = 1;  // FCVT_WU_S
    pat_val[581] = 32'hC0200053; pat_mask[581] = 32'hFFF0007F; pat_reach[581] = 1;  // FCVT_L_S
    pat_val[582] = 32'hC0300053; pat_mask[582] = 32'hFFF0007F; pat_reach[582] = 1;  // FCVT_LU_S
    pat_val[583] = 32'hC2000053; pat_mask[583] = 32'hFFF0007F; pat_reach[583] = 1;  // FCVT_W_D
    pat_val[584] = 32'hC2100053; pat_mask[584] = 32'hFFF0007F; pat_reach[584] = 1;  // FCVT_WU_D
    pat_val[585] = 32'hC2200053; pat_mask[585] = 32'hFFF0007F; pat_reach[585] = 1;  // FCVT_L_D
    pat_val[586] = 32'hC2300053; pat_mask[586] = 32'hFFF0007F; pat_reach[586] = 1;  // FCVT_LU_D
    pat_val[587] = 32'h40100053; pat_mask[587] = 32'hFFF0007F; pat_reach[587] = 1;  // FCVT_S_D
    pat_val[588] = 32'h42000053; pat_mask[588] = 32'hFFF0007F; pat_reach[588] = 1;  // FCVT_D_S
    pat_val[589] = 32'h44000053; pat_mask[589] = 32'hFFF0007F; pat_reach[589] = 1;  // FCVT_H_S
    pat_val[590] = 32'h40200053; pat_mask[590] = 32'hFFF0007F; pat_reach[590] = 1;  // FCVT_S_H
    pat_val[591] = 32'h44100053; pat_mask[591] = 32'hFFF0007F; pat_reach[591] = 1;  // FCVT_H_D
    pat_val[592] = 32'h42200053; pat_mask[592] = 32'hFFF0007F; pat_reach[592] = 1;  // FCVT_D_H
    pat_val[593] = 32'hC4000053; pat_mask[593] = 32'hFFF0007F; pat_reach[593] = 1;  // FCVT_W_H
    pat_val[594] = 32'hC4100053; pat_mask[594] = 32'hFFF0007F; pat_reach[594] = 1;  // FCVT_WU_H
    pat_val[595] = 32'hC4200053; pat_mask[595] = 32'hFFF0007F; pat_reach[595] = 1;  // FCVT_L_H
    pat_val[596] = 32'hC4300053; pat_mask[596] = 32'hFFF0007F; pat_reach[596] = 1;  // FCVT_LU_H
    pat_val[597] = 32'hE2000053; pat_mask[597] = 32'hFFF0707F; pat_reach[597] = 1;  // FMV_X_D
    pat_val[598] = 32'hE0000053; pat_mask[598] = 32'hFFF0707F; pat_reach[598] = 1;  // FMV_X_W
    pat_val[599] = 32'hE4000053; pat_mask[599] = 32'hFFF0707F; pat_reach[599] = 1;  // FMV_X_H
    pat_val[600] = 32'hE0001053; pat_mask[600] = 32'hFFF0707F; pat_reach[600] = 1;  // FCLASS_S
    pat_val[601] = 32'hE2001053; pat_mask[601] = 32'hFFF0707F; pat_reach[601] = 1;  // FCLASS_D
    pat_val[602] = 32'hE4001053; pat_mask[602] = 32'hFFF0707F; pat_reach[602] = 1;  // FCLASS_H
    pat_val[603] = 32'h20000053; pat_mask[603] = 32'hFE00707F; pat_reach[603] = 1;  // FSGNJ_S
    pat_val[604] = 32'h22000053; pat_mask[604] = 32'hFE00707F; pat_reach[604] = 1;  // FSGNJ_D
    pat_val[605] = 32'h24000053; pat_mask[605] = 32'hFE00707F; pat_reach[605] = 1;  // FSGNJ_H
    pat_val[606] = 32'h20002053; pat_mask[606] = 32'hFE00707F; pat_reach[606] = 1;  // FSGNJX_S
    pat_val[607] = 32'h22002053; pat_mask[607] = 32'hFE00707F; pat_reach[607] = 1;  // FSGNJX_D
    pat_val[608] = 32'h24002053; pat_mask[608] = 32'hFE00707F; pat_reach[608] = 1;  // FSGNJX_H
    pat_val[609] = 32'h20001053; pat_mask[609] = 32'hFE00707F; pat_reach[609] = 1;  // FSGNJN_S
    pat_val[610] = 32'h22001053; pat_mask[610] = 32'hFE00707F; pat_reach[610] = 1;  // FSGNJN_D
    pat_val[611] = 32'h24001053; pat_mask[611] = 32'hFE00707F; pat_reach[611] = 1;  // FSGNJN_H
    pat_val[612] = 32'h10000053; pat_mask[612] = 32'hFE00007F; pat_reach[612] = 1;  // FMUL_S
    pat_val[613] = 32'h12000053; pat_mask[613] = 32'hFE00007F; pat_reach[613] = 1;  // FMUL_D
    pat_val[614] = 32'h14000053; pat_mask[614] = 32'hFE00007F; pat_reach[614] = 1;  // FMUL_H
    pat_val[615] = 32'h18000053; pat_mask[615] = 32'hFE00007F; pat_reach[615] = 1;  // FDIV_S
    pat_val[616] = 32'h1A000053; pat_mask[616] = 32'hFE00007F; pat_reach[616] = 1;  // FDIV_D
    pat_val[617] = 32'h1C000053; pat_mask[617] = 32'hFE00007F; pat_reach[617] = 1;  // FDIV_H
    pat_val[618] = 32'h58000053; pat_mask[618] = 32'hFFF0007F; pat_reach[618] = 1;  // FSQRT_S
    pat_val[619] = 32'h5A000053; pat_mask[619] = 32'hFFF0007F; pat_reach[619] = 1;  // FSQRT_D
    pat_val[620] = 32'h5C000053; pat_mask[620] = 32'hFFF0007F; pat_reach[620] = 1;  // FSQRT_H
    pat_val[621] = 32'h00000043; pat_mask[621] = 32'h0600007F; pat_reach[621] = 1;  // FMADD_S
    pat_val[622] = 32'h00000047; pat_mask[622] = 32'h0600007F; pat_reach[622] = 1;  // FMSUB_S
    pat_val[623] = 32'h0000004F; pat_mask[623] = 32'h0600007F; pat_reach[623] = 1;  // FNMADD_S
    pat_val[624] = 32'h0000004B; pat_mask[624] = 32'h0600007F; pat_reach[624] = 1;  // FNMSUB_S
    pat_val[625] = 32'h02000043; pat_mask[625] = 32'h0600007F; pat_reach[625] = 1;  // FMADD_D
    pat_val[626] = 32'h02000047; pat_mask[626] = 32'h0600007F; pat_reach[626] = 1;  // FMSUB_D
    pat_val[627] = 32'h0200004F; pat_mask[627] = 32'h0600007F; pat_reach[627] = 1;  // FNMADD_D
    pat_val[628] = 32'h0200004B; pat_mask[628] = 32'h0600007F; pat_reach[628] = 1;  // FNMSUB_D
    pat_val[629] = 32'h04000043; pat_mask[629] = 32'h0600007F; pat_reach[629] = 1;  // FMADD_H
    pat_val[630] = 32'h04000047; pat_mask[630] = 32'h0600007F; pat_reach[630] = 1;  // FMSUB_H
    pat_val[631] = 32'h0400004F; pat_mask[631] = 32'h0600007F; pat_reach[631] = 1;  // FNMADD_H
    pat_val[632] = 32'h0400004B; pat_mask[632] = 32'h0600007F; pat_reach[632] = 1;  // FNMSUB_H
    pat_val[633] = 32'h00000007; pat_mask[633] = 32'h1DF0707F; pat_reach[633] = 1;  // VLE8_V
    pat_val[634] = 32'h00005007; pat_mask[634] = 32'h1DF0707F; pat_reach[634] = 1;  // VLE16_V
    pat_val[635] = 32'h00006007; pat_mask[635] = 32'h1DF0707F; pat_reach[635] = 1;  // VLE32_V
    pat_val[636] = 32'h00007007; pat_mask[636] = 32'h1DF0707F; pat_reach[636] = 1;  // VLE64_V
    pat_val[637] = 32'h00000027; pat_mask[637] = 32'h1DF0707F; pat_reach[637] = 1;  // VSE8_V
    pat_val[638] = 32'h00005027; pat_mask[638] = 32'h1DF0707F; pat_reach[638] = 1;  // VSE16_V
    pat_val[639] = 32'h00006027; pat_mask[639] = 32'h1DF0707F; pat_reach[639] = 1;  // VSE32_V
    pat_val[640] = 32'h00007027; pat_mask[640] = 32'h1DF0707F; pat_reach[640] = 1;  // VSE64_V
    pat_val[641] = 32'h02B00007; pat_mask[641] = 32'hFFF0707F; pat_reach[641] = 1;  // VLM_V
    pat_val[642] = 32'h02B00027; pat_mask[642] = 32'hFFF0707F; pat_reach[642] = 1;  // VSM_V
    pat_val[643] = 32'h08000007; pat_mask[643] = 32'h1C00707F; pat_reach[643] = 1;  // VLSE8_V
    pat_val[644] = 32'h08005007; pat_mask[644] = 32'h1C00707F; pat_reach[644] = 1;  // VLSE16_V
    pat_val[645] = 32'h08006007; pat_mask[645] = 32'h1C00707F; pat_reach[645] = 1;  // VLSE32_V
    pat_val[646] = 32'h08007007; pat_mask[646] = 32'h1C00707F; pat_reach[646] = 1;  // VLSE64_V
    pat_val[647] = 32'h08000027; pat_mask[647] = 32'h1C00707F; pat_reach[647] = 1;  // VSSE8_V
    pat_val[648] = 32'h08005027; pat_mask[648] = 32'h1C00707F; pat_reach[648] = 1;  // VSSE16_V
    pat_val[649] = 32'h08006027; pat_mask[649] = 32'h1C00707F; pat_reach[649] = 1;  // VSSE32_V
    pat_val[650] = 32'h08007027; pat_mask[650] = 32'h1C00707F; pat_reach[650] = 1;  // VSSE64_V
    pat_val[651] = 32'h04000007; pat_mask[651] = 32'h1C00707F; pat_reach[651] = 1;  // VLUXEI8_V
    pat_val[652] = 32'h04005007; pat_mask[652] = 32'h1C00707F; pat_reach[652] = 1;  // VLUXEI16_V
    pat_val[653] = 32'h04006007; pat_mask[653] = 32'h1C00707F; pat_reach[653] = 1;  // VLUXEI32_V
    pat_val[654] = 32'h04007007; pat_mask[654] = 32'h1C00707F; pat_reach[654] = 1;  // VLUXEI64_V
    pat_val[655] = 32'h0C000007; pat_mask[655] = 32'h1C00707F; pat_reach[655] = 1;  // VLOXEI8_V
    pat_val[656] = 32'h0C005007; pat_mask[656] = 32'h1C00707F; pat_reach[656] = 1;  // VLOXEI16_V
    pat_val[657] = 32'h0C006007; pat_mask[657] = 32'h1C00707F; pat_reach[657] = 1;  // VLOXEI32_V
    pat_val[658] = 32'h0C007007; pat_mask[658] = 32'h1C00707F; pat_reach[658] = 1;  // VLOXEI64_V
    pat_val[659] = 32'h04000027; pat_mask[659] = 32'h1C00707F; pat_reach[659] = 1;  // VSUXEI8_V
    pat_val[660] = 32'h04005027; pat_mask[660] = 32'h1C00707F; pat_reach[660] = 1;  // VSUXEI16_V
    pat_val[661] = 32'h04006027; pat_mask[661] = 32'h1C00707F; pat_reach[661] = 1;  // VSUXEI32_V
    pat_val[662] = 32'h04007027; pat_mask[662] = 32'h1C00707F; pat_reach[662] = 1;  // VSUXEI64_V
    pat_val[663] = 32'h0C000027; pat_mask[663] = 32'h1C00707F; pat_reach[663] = 1;  // VSOXEI8_V
    pat_val[664] = 32'h0C005027; pat_mask[664] = 32'h1C00707F; pat_reach[664] = 1;  // VSOXEI16_V
    pat_val[665] = 32'h0C006027; pat_mask[665] = 32'h1C00707F; pat_reach[665] = 1;  // VSOXEI32_V
    pat_val[666] = 32'h0C007027; pat_mask[666] = 32'h1C00707F; pat_reach[666] = 1;  // VSOXEI64_V
    pat_val[667] = 32'h01000007; pat_mask[667] = 32'h1DF0707F; pat_reach[667] = 1;  // VLE8FF_V
    pat_val[668] = 32'h01005007; pat_mask[668] = 32'h1DF0707F; pat_reach[668] = 1;  // VLE16FF_V
    pat_val[669] = 32'h01006007; pat_mask[669] = 32'h1DF0707F; pat_reach[669] = 1;  // VLE32FF_V
    pat_val[670] = 32'h01007007; pat_mask[670] = 32'h1DF0707F; pat_reach[670] = 1;  // VLE64FF_V
    pat_val[671] = 32'h02800007; pat_mask[671] = 32'hFFF0707F; pat_reach[671] = 1;  // VL1RE8_V
    pat_val[672] = 32'h02805007; pat_mask[672] = 32'hFFF0707F; pat_reach[672] = 1;  // VL1RE16_V
    pat_val[673] = 32'h02806007; pat_mask[673] = 32'hFFF0707F; pat_reach[673] = 1;  // VL1RE32_V
    pat_val[674] = 32'h02807007; pat_mask[674] = 32'hFFF0707F; pat_reach[674] = 1;  // VL1RE64_V
    pat_val[675] = 32'h22800007; pat_mask[675] = 32'hFFF0707F; pat_reach[675] = 1;  // VL2RE8_V
    pat_val[676] = 32'h22805007; pat_mask[676] = 32'hFFF0707F; pat_reach[676] = 1;  // VL2RE16_V
    pat_val[677] = 32'h22806007; pat_mask[677] = 32'hFFF0707F; pat_reach[677] = 1;  // VL2RE32_V
    pat_val[678] = 32'h22807007; pat_mask[678] = 32'hFFF0707F; pat_reach[678] = 1;  // VL2RE64_V
    pat_val[679] = 32'h62800007; pat_mask[679] = 32'hFFF0707F; pat_reach[679] = 1;  // VL4RE8_V
    pat_val[680] = 32'h62805007; pat_mask[680] = 32'hFFF0707F; pat_reach[680] = 1;  // VL4RE16_V
    pat_val[681] = 32'h62806007; pat_mask[681] = 32'hFFF0707F; pat_reach[681] = 1;  // VL4RE32_V
    pat_val[682] = 32'h62807007; pat_mask[682] = 32'hFFF0707F; pat_reach[682] = 1;  // VL4RE64_V
    pat_val[683] = 32'hE2800007; pat_mask[683] = 32'hFFF0707F; pat_reach[683] = 1;  // VL8RE8_V
    pat_val[684] = 32'hE2805007; pat_mask[684] = 32'hFFF0707F; pat_reach[684] = 1;  // VL8RE16_V
    pat_val[685] = 32'hE2806007; pat_mask[685] = 32'hFFF0707F; pat_reach[685] = 1;  // VL8RE32_V
    pat_val[686] = 32'hE2807007; pat_mask[686] = 32'hFFF0707F; pat_reach[686] = 1;  // VL8RE64_V
    pat_val[687] = 32'h02800027; pat_mask[687] = 32'hFFF0707F; pat_reach[687] = 1;  // VS1R_V
    pat_val[688] = 32'h22800027; pat_mask[688] = 32'hFFF0707F; pat_reach[688] = 1;  // VS2R_V
    pat_val[689] = 32'h62800027; pat_mask[689] = 32'hFFF0707F; pat_reach[689] = 1;  // VS4R_V
    pat_val[690] = 32'hE2800027; pat_mask[690] = 32'hFFF0707F; pat_reach[690] = 1;  // VS8R_V
    pat_val[691] = 32'h0E005033; pat_mask[691] = 32'hFE00707F; pat_reach[691] = 1;  // CZERO_EQZ
    pat_val[692] = 32'h0E007033; pat_mask[692] = 32'hFE00707F; pat_reach[692] = 1;  // CZERO_NEZ
    pat_val[693] = 32'h81C04073; pat_mask[693] = 32'hB3C0707F; pat_reach[693] = 1;  // MOP_R
    pat_val[694] = 32'h82004073; pat_mask[694] = 32'hB200707F; pat_reach[694] = 1;  // MOP_RR
    pat_val[695] = 32'hF4100053; pat_mask[695] = 32'hFFF0707F; pat_reach[695] = 1;  // FLI_H
    pat_val[696] = 32'hF0100053; pat_mask[696] = 32'hFFF0707F; pat_reach[696] = 1;  // FLI_S
    pat_val[697] = 32'hF2100053; pat_mask[697] = 32'hFFF0707F; pat_reach[697] = 1;  // FLI_D
    pat_val[698] = 32'h2C002053; pat_mask[698] = 32'hFE00707F; pat_reach[698] = 1;  // FMINM_H
    pat_val[699] = 32'h28002053; pat_mask[699] = 32'hFE00707F; pat_reach[699] = 1;  // FMINM_S
    pat_val[700] = 32'h2A002053; pat_mask[700] = 32'hFE00707F; pat_reach[700] = 1;  // FMINM_D
    pat_val[701] = 32'h2C003053; pat_mask[701] = 32'hFE00707F; pat_reach[701] = 1;  // FMAXM_H
    pat_val[702] = 32'h28003053; pat_mask[702] = 32'hFE00707F; pat_reach[702] = 1;  // FMAXM_S
    pat_val[703] = 32'h2A003053; pat_mask[703] = 32'hFE00707F; pat_reach[703] = 1;  // FMAXM_D
    pat_val[704] = 32'h44400053; pat_mask[704] = 32'hFFF0007F; pat_reach[704] = 1;  // FROUND_H
    pat_val[705] = 32'h40400053; pat_mask[705] = 32'hFFF0007F; pat_reach[705] = 1;  // FROUND_S
    pat_val[706] = 32'h42400053; pat_mask[706] = 32'hFFF0007F; pat_reach[706] = 1;  // FROUND_D
    pat_val[707] = 32'h44500053; pat_mask[707] = 32'hFFF0007F; pat_reach[707] = 1;  // FROUNDNX_H
    pat_val[708] = 32'h40500053; pat_mask[708] = 32'hFFF0007F; pat_reach[708] = 1;  // FROUNDNX_S
    pat_val[709] = 32'h42500053; pat_mask[709] = 32'hFFF0007F; pat_reach[709] = 1;  // FROUNDNX_D
    pat_val[710] = 32'hC2801053; pat_mask[710] = 32'hFFF0707F; pat_reach[710] = 1;  // FCVTMOD_W_D
    pat_val[711] = 32'hA4004053; pat_mask[711] = 32'hFE00707F; pat_reach[711] = 1;  // FLEQ_H
    pat_val[712] = 32'hA0004053; pat_mask[712] = 32'hFE00707F; pat_reach[712] = 1;  // FLEQ_S
    pat_val[713] = 32'hA2004053; pat_mask[713] = 32'hFE00707F; pat_reach[713] = 1;  // FLEQ_D
    pat_val[714] = 32'hA4005053; pat_mask[714] = 32'hFE00707F; pat_reach[714] = 1;  // FLTQ_H
    pat_val[715] = 32'hA0005053; pat_mask[715] = 32'hFE00707F; pat_reach[715] = 1;  // FLTQ_S
    pat_val[716] = 32'hA2005053; pat_mask[716] = 32'hFE00707F; pat_reach[716] = 1;  // FLTQ_D
  end

  function automatic logic [31:0] fill(input int i);
    return (pat_val[i] & pat_mask[i]) | (32'($urandom) & ~pat_mask[i]);
  endfunction

  // 定向激励：表之外的判据
  function automatic logic [31:0] mk_special();
    logic [4:0] rd = 5'($urandom), rs1 = 5'($urandom), rs2 = 5'($urandom);
    case ($urandom_range(0, 15))
      0:  return {12'hC20, 5'h0, 3'b010, rd, 7'h73};                       // csrr rd, vl  (csrrs rd, vl, x0)
      1:  return {12'hC22, 5'h0, 3'b010, rd, 7'h73};                       // csrr rd, vlenb
      2:  return {12'hC20 | 12'($urandom_range(0,3)), 5'h0, (1'($urandom) ? 3'b110 : 3'b010), rd, 7'h73}; // csrrs/csrrsi 附近
      3:  return {7'($urandom), 5'($urandom_range(0,3)), rs1, 3'b110, 5'h0, 7'h13};  // prefetch.{i,r,w} 及邻近 ori x0
      4:  return {5'b11110, 2'($urandom), 5'h1, rs1, 3'b000, rd, 7'h53};     // fli.{h,s,d}
      5:  return {1'b1, 1'($urandom), 2'b00, 2'($urandom), 1'b0, 3'b111, 2'($urandom), rs1, 3'b100, rd, 7'h73}; // mop.r
      6:  return {1'b1, 1'($urandom), 2'b00, 2'($urandom), 1'b1, 5'($urandom), rs1, 3'b100, rd, 7'h73}; // mop.rr
      7:  return {12'h000, rs1, 3'b000, rd, 7'h13};                          // addi rd, rs1, 0 (isMove)
      8:  return {12'($urandom_range(0,4)), rs1, 3'b010, 5'h0, 7'h0F};       // cbo.*
      9:  return {12'h000, rs1, 3'b000, 5'h0, 7'h6B};                        // TRAP
      10: return {5'b00101, 1'($urandom), 1'($urandom), rs2, rs1, 3'b100, rd, 7'h2F}; // amocas.q（rd/rs2 奇偶随机）
      11: return {8'b00110001, 4'($urandom), rs1, 3'b001, rd, 7'h13};         // aes64ks1i（rnum 含保留值）
      12: return {3'($urandom), 1'b0, 2'($urandom), 1'($urandom), rs2, rs1, (1'($urandom) ? 3'b000 : 3'b110), rd, 7'h07}; // 向量 load，NF 随机
      13: return {3'($urandom), 1'b0, 2'($urandom), 1'($urandom), rs2, rs1, (1'($urandom) ? 3'b101 : 3'b111), rd, 7'h27}; // 向量 store，NF 随机
      14: return {7'($urandom), rs2, rs1, 3'b111, rd, 7'h57};                // vset* 及非法 funct3=111
      default: return {7'($urandom), rs2, rs1, 3'($urandom), rd, 7'h53};    // 随机 OP-FP（含 rm=5/6/7）
    endcase
  endfunction

  function automatic logic [31:0] mk_instr();
    int pick = $urandom_range(0, 99);
    if (pick < 60)      return fill($urandom_range(0, NPAT - 1));
    else if (pick < 85) return mk_special();
    else                return $urandom;
  endfunction

  task automatic drive_inputs();
    io_enq_ctrlFlow_instr = mk_instr();
    io_enq_ctrlFlow_pc = {50'($urandom), 50'($urandom)} ^ 50'($urandom);
    io_enq_ctrlFlow_foldpc = 10'($urandom);
    io_enq_ctrlFlow_exceptionVec_0 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_1 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_2 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_4 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_5 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_6 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_7 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_8 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_9 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_10 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_11 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_12 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_13 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_14 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_15 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_16 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_17 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_18 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_19 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_20 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_21 = 1'($urandom);
    io_enq_ctrlFlow_exceptionVec_23 = 1'($urandom);
    io_enq_ctrlFlow_isFetchMalAddr = 1'($urandom);
    io_enq_ctrlFlow_trigger = 4'($urandom);
    io_enq_ctrlFlow_preDecodeInfo_valid = 1'($urandom);
    io_enq_ctrlFlow_preDecodeInfo_isRVC = 1'($urandom);
    io_enq_ctrlFlow_preDecodeInfo_brType = 2'($urandom);
    io_enq_ctrlFlow_preDecodeInfo_isCall = 1'($urandom);
    io_enq_ctrlFlow_preDecodeInfo_isRet = 1'($urandom);
    io_enq_ctrlFlow_pred_taken = 1'($urandom);
    io_enq_ctrlFlow_crossPageIPFFix = 1'($urandom);
    io_enq_ctrlFlow_ftqPtr_flag = 1'($urandom);
    io_enq_ctrlFlow_ftqPtr_value = 6'($urandom);
    io_enq_ctrlFlow_ftqOffset = 4'($urandom);
    io_enq_ctrlFlow_isLastInFtqEntry = 1'($urandom);
    io_enq_ctrlFlow_debug_seqNum_seqNum = {56'($urandom), 56'($urandom)} ^ 56'($urandom);
    io_enq_ctrlFlow_debug_seqNum_uopIdx = 8'($urandom);
    io_enq_ctrlFlow_satpFlushFirstFetchFault = 1'($urandom);
    io_enq_vtype_illegal = 1'($urandom);
    io_enq_vtype_vma = 1'($urandom);
    io_enq_vtype_vta = 1'($urandom);
    io_enq_vtype_vsew = 2'($urandom);
    io_enq_vtype_vlmul = 3'($urandom);
    io_enq_vstart = 1'($urandom) ? 8'h0 : 8'($urandom);
    io_csrCtrl_singlestep = 1'($urandom);
    io_fromCSR_illegalInst_sfenceVMA = 1'($urandom);
    io_fromCSR_illegalInst_sfencePart = 1'($urandom);
    io_fromCSR_illegalInst_hfenceGVMA = 1'($urandom);
    io_fromCSR_illegalInst_hfenceVVMA = 1'($urandom);
    io_fromCSR_illegalInst_hlsv = 1'($urandom);
    io_fromCSR_illegalInst_fsIsOff = 1'($urandom);
    io_fromCSR_illegalInst_vsIsOff = 1'($urandom);
    io_fromCSR_illegalInst_wfi = 1'($urandom);
    io_fromCSR_illegalInst_wrs_nto = 1'($urandom);
    io_fromCSR_illegalInst_frm = 1'($urandom);
    io_fromCSR_illegalInst_cboZ = 1'($urandom);
    io_fromCSR_illegalInst_cboCF = 1'($urandom);
    io_fromCSR_illegalInst_cboI = 1'($urandom);
    io_fromCSR_virtualInst_sfenceVMA = 1'($urandom);
    io_fromCSR_virtualInst_sfencePart = 1'($urandom);
    io_fromCSR_virtualInst_hfence = 1'($urandom);
    io_fromCSR_virtualInst_hlsv = 1'($urandom);
    io_fromCSR_virtualInst_wfi = 1'($urandom);
    io_fromCSR_virtualInst_wrs_nto = 1'($urandom);
    io_fromCSR_virtualInst_cboZ = 1'($urandom);
    io_fromCSR_virtualInst_cboCF = 1'($urandom);
    io_fromCSR_virtualInst_cboI = 1'($urandom);
    io_fromCSR_special_cboI2F = 1'($urandom);
  endtask

  task automatic compare_outputs();
    checks++;
    if (g_io_deq_decodedInst_instr !== x_io_deq_decodedInst_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_instr g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_instr, x_io_deq_decodedInst_instr); end
    if (g_io_deq_decodedInst_pc !== x_io_deq_decodedInst_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_pc g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_pc, x_io_deq_decodedInst_pc); end
    if (g_io_deq_decodedInst_foldpc !== x_io_deq_decodedInst_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_foldpc g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_foldpc, x_io_deq_decodedInst_foldpc); end
    if (g_io_deq_decodedInst_exceptionVec_0 !== x_io_deq_decodedInst_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_0 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_0, x_io_deq_decodedInst_exceptionVec_0); end
    if (g_io_deq_decodedInst_exceptionVec_1 !== x_io_deq_decodedInst_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_1 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_1, x_io_deq_decodedInst_exceptionVec_1); end
    if (g_io_deq_decodedInst_exceptionVec_2 !== x_io_deq_decodedInst_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_2 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_2, x_io_deq_decodedInst_exceptionVec_2); end
    if (g_io_deq_decodedInst_exceptionVec_3 !== x_io_deq_decodedInst_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_3 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_3, x_io_deq_decodedInst_exceptionVec_3); end
    if (g_io_deq_decodedInst_exceptionVec_4 !== x_io_deq_decodedInst_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_4 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_4, x_io_deq_decodedInst_exceptionVec_4); end
    if (g_io_deq_decodedInst_exceptionVec_5 !== x_io_deq_decodedInst_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_5 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_5, x_io_deq_decodedInst_exceptionVec_5); end
    if (g_io_deq_decodedInst_exceptionVec_6 !== x_io_deq_decodedInst_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_6 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_6, x_io_deq_decodedInst_exceptionVec_6); end
    if (g_io_deq_decodedInst_exceptionVec_7 !== x_io_deq_decodedInst_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_7 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_7, x_io_deq_decodedInst_exceptionVec_7); end
    if (g_io_deq_decodedInst_exceptionVec_8 !== x_io_deq_decodedInst_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_8 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_8, x_io_deq_decodedInst_exceptionVec_8); end
    if (g_io_deq_decodedInst_exceptionVec_9 !== x_io_deq_decodedInst_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_9 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_9, x_io_deq_decodedInst_exceptionVec_9); end
    if (g_io_deq_decodedInst_exceptionVec_10 !== x_io_deq_decodedInst_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_10 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_10, x_io_deq_decodedInst_exceptionVec_10); end
    if (g_io_deq_decodedInst_exceptionVec_11 !== x_io_deq_decodedInst_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_11 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_11, x_io_deq_decodedInst_exceptionVec_11); end
    if (g_io_deq_decodedInst_exceptionVec_12 !== x_io_deq_decodedInst_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_12 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_12, x_io_deq_decodedInst_exceptionVec_12); end
    if (g_io_deq_decodedInst_exceptionVec_13 !== x_io_deq_decodedInst_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_13 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_13, x_io_deq_decodedInst_exceptionVec_13); end
    if (g_io_deq_decodedInst_exceptionVec_14 !== x_io_deq_decodedInst_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_14 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_14, x_io_deq_decodedInst_exceptionVec_14); end
    if (g_io_deq_decodedInst_exceptionVec_15 !== x_io_deq_decodedInst_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_15 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_15, x_io_deq_decodedInst_exceptionVec_15); end
    if (g_io_deq_decodedInst_exceptionVec_16 !== x_io_deq_decodedInst_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_16 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_16, x_io_deq_decodedInst_exceptionVec_16); end
    if (g_io_deq_decodedInst_exceptionVec_17 !== x_io_deq_decodedInst_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_17 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_17, x_io_deq_decodedInst_exceptionVec_17); end
    if (g_io_deq_decodedInst_exceptionVec_18 !== x_io_deq_decodedInst_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_18 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_18, x_io_deq_decodedInst_exceptionVec_18); end
    if (g_io_deq_decodedInst_exceptionVec_19 !== x_io_deq_decodedInst_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_19 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_19, x_io_deq_decodedInst_exceptionVec_19); end
    if (g_io_deq_decodedInst_exceptionVec_20 !== x_io_deq_decodedInst_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_20 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_20, x_io_deq_decodedInst_exceptionVec_20); end
    if (g_io_deq_decodedInst_exceptionVec_21 !== x_io_deq_decodedInst_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_21 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_21, x_io_deq_decodedInst_exceptionVec_21); end
    if (g_io_deq_decodedInst_exceptionVec_22 !== x_io_deq_decodedInst_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_22 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_22, x_io_deq_decodedInst_exceptionVec_22); end
    if (g_io_deq_decodedInst_exceptionVec_23 !== x_io_deq_decodedInst_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_exceptionVec_23 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_exceptionVec_23, x_io_deq_decodedInst_exceptionVec_23); end
    if (g_io_deq_decodedInst_isFetchMalAddr !== x_io_deq_decodedInst_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_isFetchMalAddr g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_isFetchMalAddr, x_io_deq_decodedInst_isFetchMalAddr); end
    if (g_io_deq_decodedInst_trigger !== x_io_deq_decodedInst_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_trigger g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_trigger, x_io_deq_decodedInst_trigger); end
    if (g_io_deq_decodedInst_preDecodeInfo_valid !== x_io_deq_decodedInst_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_preDecodeInfo_valid g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_preDecodeInfo_valid, x_io_deq_decodedInst_preDecodeInfo_valid); end
    if (g_io_deq_decodedInst_preDecodeInfo_isRVC !== x_io_deq_decodedInst_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_preDecodeInfo_isRVC g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_preDecodeInfo_isRVC, x_io_deq_decodedInst_preDecodeInfo_isRVC); end
    if (g_io_deq_decodedInst_preDecodeInfo_brType !== x_io_deq_decodedInst_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_preDecodeInfo_brType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_preDecodeInfo_brType, x_io_deq_decodedInst_preDecodeInfo_brType); end
    if (g_io_deq_decodedInst_preDecodeInfo_isCall !== x_io_deq_decodedInst_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_preDecodeInfo_isCall g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_preDecodeInfo_isCall, x_io_deq_decodedInst_preDecodeInfo_isCall); end
    if (g_io_deq_decodedInst_preDecodeInfo_isRet !== x_io_deq_decodedInst_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_preDecodeInfo_isRet g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_preDecodeInfo_isRet, x_io_deq_decodedInst_preDecodeInfo_isRet); end
    if (g_io_deq_decodedInst_pred_taken !== x_io_deq_decodedInst_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_pred_taken g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_pred_taken, x_io_deq_decodedInst_pred_taken); end
    if (g_io_deq_decodedInst_crossPageIPFFix !== x_io_deq_decodedInst_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_crossPageIPFFix g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_crossPageIPFFix, x_io_deq_decodedInst_crossPageIPFFix); end
    if (g_io_deq_decodedInst_ftqPtr_flag !== x_io_deq_decodedInst_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_ftqPtr_flag g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_ftqPtr_flag, x_io_deq_decodedInst_ftqPtr_flag); end
    if (g_io_deq_decodedInst_ftqPtr_value !== x_io_deq_decodedInst_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_ftqPtr_value g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_ftqPtr_value, x_io_deq_decodedInst_ftqPtr_value); end
    if (g_io_deq_decodedInst_ftqOffset !== x_io_deq_decodedInst_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_ftqOffset g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_ftqOffset, x_io_deq_decodedInst_ftqOffset); end
    if (g_io_deq_decodedInst_satpFlushFirstFetchFault !== x_io_deq_decodedInst_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_satpFlushFirstFetchFault g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_satpFlushFirstFetchFault, x_io_deq_decodedInst_satpFlushFirstFetchFault); end
    if (g_io_deq_decodedInst_srcType_0 !== x_io_deq_decodedInst_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_srcType_0 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_srcType_0, x_io_deq_decodedInst_srcType_0); end
    if (g_io_deq_decodedInst_srcType_1 !== x_io_deq_decodedInst_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_srcType_1 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_srcType_1, x_io_deq_decodedInst_srcType_1); end
    if (g_io_deq_decodedInst_srcType_2 !== x_io_deq_decodedInst_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_srcType_2 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_srcType_2, x_io_deq_decodedInst_srcType_2); end
    if (g_io_deq_decodedInst_srcType_3 !== x_io_deq_decodedInst_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_srcType_3 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_srcType_3, x_io_deq_decodedInst_srcType_3); end
    if (g_io_deq_decodedInst_srcType_4 !== x_io_deq_decodedInst_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_srcType_4 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_srcType_4, x_io_deq_decodedInst_srcType_4); end
    if (g_io_deq_decodedInst_lsrc_0 !== x_io_deq_decodedInst_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_lsrc_0 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_lsrc_0, x_io_deq_decodedInst_lsrc_0); end
    if (g_io_deq_decodedInst_lsrc_1 !== x_io_deq_decodedInst_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_lsrc_1 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_lsrc_1, x_io_deq_decodedInst_lsrc_1); end
    if (g_io_deq_decodedInst_lsrc_2 !== x_io_deq_decodedInst_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_lsrc_2 g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_lsrc_2, x_io_deq_decodedInst_lsrc_2); end
    if (g_io_deq_decodedInst_ldest !== x_io_deq_decodedInst_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_ldest g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_ldest, x_io_deq_decodedInst_ldest); end
    if (g_io_deq_decodedInst_fuType !== x_io_deq_decodedInst_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fuType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fuType, x_io_deq_decodedInst_fuType); end
    if (g_io_deq_decodedInst_fuOpType !== x_io_deq_decodedInst_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fuOpType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fuOpType, x_io_deq_decodedInst_fuOpType); end
    if (g_io_deq_decodedInst_rfWen !== x_io_deq_decodedInst_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_rfWen g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_rfWen, x_io_deq_decodedInst_rfWen); end
    if (g_io_deq_decodedInst_fpWen !== x_io_deq_decodedInst_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpWen g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpWen, x_io_deq_decodedInst_fpWen); end
    if (g_io_deq_decodedInst_vecWen !== x_io_deq_decodedInst_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vecWen g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vecWen, x_io_deq_decodedInst_vecWen); end
    if (g_io_deq_decodedInst_isXSTrap !== x_io_deq_decodedInst_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_isXSTrap g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_isXSTrap, x_io_deq_decodedInst_isXSTrap); end
    if (g_io_deq_decodedInst_waitForward !== x_io_deq_decodedInst_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_waitForward g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_waitForward, x_io_deq_decodedInst_waitForward); end
    if (g_io_deq_decodedInst_blockBackward !== x_io_deq_decodedInst_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_blockBackward g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_blockBackward, x_io_deq_decodedInst_blockBackward); end
    if (g_io_deq_decodedInst_flushPipe !== x_io_deq_decodedInst_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_flushPipe g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_flushPipe, x_io_deq_decodedInst_flushPipe); end
    if (g_io_deq_decodedInst_canRobCompress !== x_io_deq_decodedInst_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_canRobCompress g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_canRobCompress, x_io_deq_decodedInst_canRobCompress); end
    if (g_io_deq_decodedInst_selImm !== x_io_deq_decodedInst_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_selImm g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_selImm, x_io_deq_decodedInst_selImm); end
    if (g_io_deq_decodedInst_imm !== x_io_deq_decodedInst_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_imm g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_imm, x_io_deq_decodedInst_imm); end
    if (g_io_deq_decodedInst_fpu_typeTagOut !== x_io_deq_decodedInst_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpu_typeTagOut g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpu_typeTagOut, x_io_deq_decodedInst_fpu_typeTagOut); end
    if (g_io_deq_decodedInst_fpu_wflags !== x_io_deq_decodedInst_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpu_wflags g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpu_wflags, x_io_deq_decodedInst_fpu_wflags); end
    if (g_io_deq_decodedInst_fpu_typ !== x_io_deq_decodedInst_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpu_typ g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpu_typ, x_io_deq_decodedInst_fpu_typ); end
    if (g_io_deq_decodedInst_fpu_fmt !== x_io_deq_decodedInst_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpu_fmt g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpu_fmt, x_io_deq_decodedInst_fpu_fmt); end
    if (g_io_deq_decodedInst_fpu_rm !== x_io_deq_decodedInst_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_fpu_rm g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_fpu_rm, x_io_deq_decodedInst_fpu_rm); end
    if (g_io_deq_decodedInst_vpu_vill !== x_io_deq_decodedInst_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vill g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vill, x_io_deq_decodedInst_vpu_vill); end
    if (g_io_deq_decodedInst_vpu_vma !== x_io_deq_decodedInst_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vma g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vma, x_io_deq_decodedInst_vpu_vma); end
    if (g_io_deq_decodedInst_vpu_vta !== x_io_deq_decodedInst_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vta g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vta, x_io_deq_decodedInst_vpu_vta); end
    if (g_io_deq_decodedInst_vpu_vsew !== x_io_deq_decodedInst_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vsew g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vsew, x_io_deq_decodedInst_vpu_vsew); end
    if (g_io_deq_decodedInst_vpu_vlmul !== x_io_deq_decodedInst_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vlmul g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vlmul, x_io_deq_decodedInst_vpu_vlmul); end
    if (g_io_deq_decodedInst_vpu_specVill !== x_io_deq_decodedInst_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_specVill g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_specVill, x_io_deq_decodedInst_vpu_specVill); end
    if (g_io_deq_decodedInst_vpu_specVma !== x_io_deq_decodedInst_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_specVma g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_specVma, x_io_deq_decodedInst_vpu_specVma); end
    if (g_io_deq_decodedInst_vpu_specVta !== x_io_deq_decodedInst_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_specVta g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_specVta, x_io_deq_decodedInst_vpu_specVta); end
    if (g_io_deq_decodedInst_vpu_specVsew !== x_io_deq_decodedInst_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_specVsew g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_specVsew, x_io_deq_decodedInst_vpu_specVsew); end
    if (g_io_deq_decodedInst_vpu_specVlmul !== x_io_deq_decodedInst_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_specVlmul g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_specVlmul, x_io_deq_decodedInst_vpu_specVlmul); end
    if (g_io_deq_decodedInst_vpu_vm !== x_io_deq_decodedInst_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vm g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vm, x_io_deq_decodedInst_vpu_vm); end
    if (g_io_deq_decodedInst_vpu_vstart !== x_io_deq_decodedInst_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_vstart g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_vstart, x_io_deq_decodedInst_vpu_vstart); end
    if (g_io_deq_decodedInst_vpu_nf !== x_io_deq_decodedInst_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_nf g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_nf, x_io_deq_decodedInst_vpu_nf); end
    if (g_io_deq_decodedInst_vpu_veew !== x_io_deq_decodedInst_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_veew g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_veew, x_io_deq_decodedInst_vpu_veew); end
    if (g_io_deq_decodedInst_vpu_isReverse !== x_io_deq_decodedInst_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isReverse g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isReverse, x_io_deq_decodedInst_vpu_isReverse); end
    if (g_io_deq_decodedInst_vpu_isExt !== x_io_deq_decodedInst_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isExt g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isExt, x_io_deq_decodedInst_vpu_isExt); end
    if (g_io_deq_decodedInst_vpu_isNarrow !== x_io_deq_decodedInst_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isNarrow g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isNarrow, x_io_deq_decodedInst_vpu_isNarrow); end
    if (g_io_deq_decodedInst_vpu_isDstMask !== x_io_deq_decodedInst_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isDstMask g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isDstMask, x_io_deq_decodedInst_vpu_isDstMask); end
    if (g_io_deq_decodedInst_vpu_isOpMask !== x_io_deq_decodedInst_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isOpMask g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isOpMask, x_io_deq_decodedInst_vpu_isOpMask); end
    if (g_io_deq_decodedInst_vpu_isDependOldVd !== x_io_deq_decodedInst_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isDependOldVd g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isDependOldVd, x_io_deq_decodedInst_vpu_isDependOldVd); end
    if (g_io_deq_decodedInst_vpu_isWritePartVd !== x_io_deq_decodedInst_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isWritePartVd g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isWritePartVd, x_io_deq_decodedInst_vpu_isWritePartVd); end
    if (g_io_deq_decodedInst_vpu_isVleff !== x_io_deq_decodedInst_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vpu_isVleff g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vpu_isVleff, x_io_deq_decodedInst_vpu_isVleff); end
    if (g_io_deq_decodedInst_vlsInstr !== x_io_deq_decodedInst_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_vlsInstr g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_vlsInstr, x_io_deq_decodedInst_vlsInstr); end
    if (g_io_deq_decodedInst_wfflags !== x_io_deq_decodedInst_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_wfflags g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_wfflags, x_io_deq_decodedInst_wfflags); end
    if (g_io_deq_decodedInst_isMove !== x_io_deq_decodedInst_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_isMove g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_isMove, x_io_deq_decodedInst_isMove); end
    if (g_io_deq_decodedInst_uopSplitType !== x_io_deq_decodedInst_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_uopSplitType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_uopSplitType, x_io_deq_decodedInst_uopSplitType); end
    if (g_io_deq_decodedInst_isVset !== x_io_deq_decodedInst_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_isVset g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_isVset, x_io_deq_decodedInst_isVset); end
    if (g_io_deq_decodedInst_commitType !== x_io_deq_decodedInst_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_commitType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_commitType, x_io_deq_decodedInst_commitType); end
    if (g_io_deq_decodedInst_debug_fuType !== x_io_deq_decodedInst_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_debug_fuType g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_debug_fuType, x_io_deq_decodedInst_debug_fuType); end
    if (g_io_deq_decodedInst_debug_seqNum_seqNum !== x_io_deq_decodedInst_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_debug_seqNum_seqNum g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_debug_seqNum_seqNum, x_io_deq_decodedInst_debug_seqNum_seqNum); end
    if (g_io_deq_decodedInst_debug_seqNum_uopIdx !== x_io_deq_decodedInst_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_decodedInst_debug_seqNum_uopIdx g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_decodedInst_debug_seqNum_uopIdx, x_io_deq_decodedInst_debug_seqNum_uopIdx); end
    if (g_io_deq_isComplex !== x_io_deq_isComplex) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_isComplex g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_isComplex, x_io_deq_isComplex); end
    if (g_io_deq_uopInfo_numOfUop !== x_io_deq_uopInfo_numOfUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_uopInfo_numOfUop g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_uopInfo_numOfUop, x_io_deq_uopInfo_numOfUop); end
    if (g_io_deq_uopInfo_numOfWB !== x_io_deq_uopInfo_numOfWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_uopInfo_numOfWB g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_uopInfo_numOfWB, x_io_deq_uopInfo_numOfWB); end
    if (g_io_deq_uopInfo_lmul !== x_io_deq_uopInfo_lmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h io_deq_uopInfo_lmul g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_io_deq_uopInfo_lmul, x_io_deq_uopInfo_lmul); end
  endtask

  task automatic collect_cov();
    for (int i = 0; i < NPAT; i++)
      if ((io_enq_ctrlFlow_instr & pat_mask[i]) == pat_val[i]) begin pat_hit[i]++; break; end   // 表序优先，首条命中
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < NPAT; i++) pat_hit[i] = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      drive_inputs();
      #1;
      compare_outputs(); collect_cov();
      @(negedge clk);
    end
    begin
      int bad = 0, reach = 0;
      for (int i = 0; i < NPAT; i++) begin
        if (pat_reach[i]) reach++;
        if (pat_reach[i] && pat_hit[i] == 0) begin bad++; $display("  UNCOVERED pattern #%0d", i); end
      end
      $display("=== COVERAGE (DecodeUnit) === checks=%0d patterns=%0d reachable=%0d uncovered=%0d", checks, NPAT, reach, bad);
      if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
