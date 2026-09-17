// =============================================================================
// DecodeUnitComp UT —— golden DecodeUnitComp 对重写 DecodeUnitComp_xs 双例化，
// 同激励逐拍比对**全部输出线**（6 路 × 105/106 个 DecodedInst 字段 + 6 个 valid
// + complexNum + in_ready，共 638 根）。
//
// ★ 这个 DUT 的判别力全在「uopSplitType × vlmul × vsew × 握手相位」四维乘积上 ★
// 它是一张按 uopSplitType 分 43 个分支的大表，每个分支再按 vlmul/vsew 分叉，把一条
// 复杂向量指令拆成最多 65 个 uop，再每拍吐 6 个。所以：
//   · uopSplitType 必须**定向**覆盖 45 个已定义编码（含 SCA_SIM/dummy）与未定义编码；
//     6 位均匀随机既命不匀、也保证不了每个分支下的 vlmul/vsew 子分支都打到。
//   · numOfUop 必须常常 > 6，否则一拍出完、count 永远是 0，
//     「按 count 取第几组 uop」这条主路径等于没验。
//   · out0_ready 要做长条 0/1，让 count 一路走到 10。
//   · redirect 要在 count 走到一半时插进来。
//
// ★ 复位窗口也比对 ★
// 本模块有 99 个**不带复位**的锁存寄存器（latchedInst/latchedUopInfo）与 3 个带
// 异步复位的状态寄存器。比对窗口按绝对拍数开闸（暖机 WARMUP 拍），开了之后
// 连 rst 拉高的拍也一起比 —— 复位期间照常打激励，而且运行中会多次异步复位。
// 这样「复位域写错」才有可观测窗口（本轮别的 lane 踩过：只在 !rst 时比对，
// 复位域 mutant 直接漏检）。
//
// ★ 覆盖证据 ★
// 覆盖统计全部取自 **golden 侧**的内部信号（独立于被测件）：
// (uopSplitType, vlmul) 的命中次数、count 的取值分布、状态机迁移。
// 任何一个已定义 split 类型、或任何一个 count 取值为 0，这一轮 errors=0 都不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 64;      // 比对窗口按绝对拍数开闸，之后连复位拍一起比
  bit  clk = 0;
  logic rst;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // ---- 输入（两个 DUT 共用）----
  logic            io_redirect;
  logic            io_vtypeBypass_illegal;
  logic            io_vtypeBypass_vma;
  logic            io_vtypeBypass_vta;
  logic [1:0]      io_vtypeBypass_vsew;
  logic [2:0]      io_vtypeBypass_vlmul;
  logic            io_in_valid;
  logic [31:0]     io_in_bits_simpleDecodedInst_instr;
  logic [49:0]     io_in_bits_simpleDecodedInst_pc;
  logic [9:0]      io_in_bits_simpleDecodedInst_foldpc;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_0;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_1;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_2;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_3;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_4;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_5;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_6;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_7;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_8;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_9;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_10;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_11;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_12;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_13;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_14;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_15;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_16;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_17;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_18;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_19;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_20;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_21;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_22;
  logic            io_in_bits_simpleDecodedInst_exceptionVec_23;
  logic            io_in_bits_simpleDecodedInst_isFetchMalAddr;
  logic [3:0]      io_in_bits_simpleDecodedInst_trigger;
  logic            io_in_bits_simpleDecodedInst_preDecodeInfo_valid;
  logic            io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC;
  logic [1:0]      io_in_bits_simpleDecodedInst_preDecodeInfo_brType;
  logic            io_in_bits_simpleDecodedInst_preDecodeInfo_isCall;
  logic            io_in_bits_simpleDecodedInst_preDecodeInfo_isRet;
  logic            io_in_bits_simpleDecodedInst_pred_taken;
  logic            io_in_bits_simpleDecodedInst_crossPageIPFFix;
  logic            io_in_bits_simpleDecodedInst_ftqPtr_flag;
  logic [5:0]      io_in_bits_simpleDecodedInst_ftqPtr_value;
  logic [3:0]      io_in_bits_simpleDecodedInst_ftqOffset;
  logic            io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault;
  logic [3:0]      io_in_bits_simpleDecodedInst_srcType_0;
  logic [3:0]      io_in_bits_simpleDecodedInst_srcType_1;
  logic [3:0]      io_in_bits_simpleDecodedInst_srcType_2;
  logic [3:0]      io_in_bits_simpleDecodedInst_srcType_3;
  logic [3:0]      io_in_bits_simpleDecodedInst_srcType_4;
  logic [5:0]      io_in_bits_simpleDecodedInst_lsrc_0;
  logic [5:0]      io_in_bits_simpleDecodedInst_lsrc_1;
  logic [5:0]      io_in_bits_simpleDecodedInst_lsrc_2;
  logic [5:0]      io_in_bits_simpleDecodedInst_ldest;
  logic [34:0]     io_in_bits_simpleDecodedInst_fuType;
  logic [8:0]      io_in_bits_simpleDecodedInst_fuOpType;
  logic            io_in_bits_simpleDecodedInst_rfWen;
  logic            io_in_bits_simpleDecodedInst_fpWen;
  logic            io_in_bits_simpleDecodedInst_vecWen;
  logic            io_in_bits_simpleDecodedInst_isXSTrap;
  logic            io_in_bits_simpleDecodedInst_waitForward;
  logic            io_in_bits_simpleDecodedInst_blockBackward;
  logic            io_in_bits_simpleDecodedInst_flushPipe;
  logic            io_in_bits_simpleDecodedInst_canRobCompress;
  logic [3:0]      io_in_bits_simpleDecodedInst_selImm;
  logic [21:0]     io_in_bits_simpleDecodedInst_imm;
  logic [1:0]      io_in_bits_simpleDecodedInst_fpu_typeTagOut;
  logic            io_in_bits_simpleDecodedInst_fpu_wflags;
  logic [1:0]      io_in_bits_simpleDecodedInst_fpu_typ;
  logic [1:0]      io_in_bits_simpleDecodedInst_fpu_fmt;
  logic [2:0]      io_in_bits_simpleDecodedInst_fpu_rm;
  logic            io_in_bits_simpleDecodedInst_vpu_vill;
  logic            io_in_bits_simpleDecodedInst_vpu_vma;
  logic            io_in_bits_simpleDecodedInst_vpu_vta;
  logic [1:0]      io_in_bits_simpleDecodedInst_vpu_vsew;
  logic [2:0]      io_in_bits_simpleDecodedInst_vpu_vlmul;
  logic            io_in_bits_simpleDecodedInst_vpu_specVill;
  logic            io_in_bits_simpleDecodedInst_vpu_specVma;
  logic            io_in_bits_simpleDecodedInst_vpu_specVta;
  logic [1:0]      io_in_bits_simpleDecodedInst_vpu_specVsew;
  logic [2:0]      io_in_bits_simpleDecodedInst_vpu_specVlmul;
  logic            io_in_bits_simpleDecodedInst_vpu_vm;
  logic [7:0]      io_in_bits_simpleDecodedInst_vpu_vstart;
  logic [2:0]      io_in_bits_simpleDecodedInst_vpu_nf;
  logic [1:0]      io_in_bits_simpleDecodedInst_vpu_veew;
  logic            io_in_bits_simpleDecodedInst_vpu_isReverse;
  logic            io_in_bits_simpleDecodedInst_vpu_isExt;
  logic            io_in_bits_simpleDecodedInst_vpu_isNarrow;
  logic            io_in_bits_simpleDecodedInst_vpu_isDstMask;
  logic            io_in_bits_simpleDecodedInst_vpu_isOpMask;
  logic            io_in_bits_simpleDecodedInst_vpu_isDependOldVd;
  logic            io_in_bits_simpleDecodedInst_vpu_isWritePartVd;
  logic            io_in_bits_simpleDecodedInst_vpu_isVleff;
  logic            io_in_bits_simpleDecodedInst_wfflags;
  logic            io_in_bits_simpleDecodedInst_isMove;
  logic [5:0]      io_in_bits_simpleDecodedInst_uopSplitType;
  logic            io_in_bits_simpleDecodedInst_isVset;
  logic [2:0]      io_in_bits_simpleDecodedInst_commitType;
  logic [34:0]     io_in_bits_simpleDecodedInst_debug_fuType;
  logic [55:0]     io_in_bits_simpleDecodedInst_debug_seqNum_seqNum;
  logic [7:0]      io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx;
  logic [6:0]      io_in_bits_uopInfo_numOfUop;
  logic [6:0]      io_in_bits_uopInfo_numOfWB;
  logic [3:0]      io_in_bits_uopInfo_lmul;
  logic            io_out_complexDecodedInsts_0_ready;

  // ---- 输出（golden g_ / 重写 x_ 各一份）----
  logic            g_io_in_ready, x_io_in_ready;
  logic            g_io_out_complexDecodedInsts_0_valid, x_io_out_complexDecodedInsts_0_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_0_bits_instr, x_io_out_complexDecodedInsts_0_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_0_bits_pc, x_io_out_complexDecodedInsts_0_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_0_bits_foldpc, x_io_out_complexDecodedInsts_0_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_0, x_io_out_complexDecodedInsts_0_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_1, x_io_out_complexDecodedInsts_0_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_2, x_io_out_complexDecodedInsts_0_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_3, x_io_out_complexDecodedInsts_0_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_4, x_io_out_complexDecodedInsts_0_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_5, x_io_out_complexDecodedInsts_0_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_6, x_io_out_complexDecodedInsts_0_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_7, x_io_out_complexDecodedInsts_0_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_8, x_io_out_complexDecodedInsts_0_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_9, x_io_out_complexDecodedInsts_0_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_10, x_io_out_complexDecodedInsts_0_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_11, x_io_out_complexDecodedInsts_0_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_12, x_io_out_complexDecodedInsts_0_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_13, x_io_out_complexDecodedInsts_0_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_14, x_io_out_complexDecodedInsts_0_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_15, x_io_out_complexDecodedInsts_0_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_16, x_io_out_complexDecodedInsts_0_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_17, x_io_out_complexDecodedInsts_0_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_18, x_io_out_complexDecodedInsts_0_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_19, x_io_out_complexDecodedInsts_0_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_20, x_io_out_complexDecodedInsts_0_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_21, x_io_out_complexDecodedInsts_0_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_22, x_io_out_complexDecodedInsts_0_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_0_bits_exceptionVec_23, x_io_out_complexDecodedInsts_0_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_0_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_0_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_trigger, x_io_out_complexDecodedInsts_0_bits_trigger;
  logic            g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_0_bits_pred_taken, x_io_out_complexDecodedInsts_0_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_0_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_0_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_0_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_0_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_ftqPtr_value, x_io_out_complexDecodedInsts_0_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_ftqOffset, x_io_out_complexDecodedInsts_0_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_srcType_0, x_io_out_complexDecodedInsts_0_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_srcType_1, x_io_out_complexDecodedInsts_0_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_srcType_2, x_io_out_complexDecodedInsts_0_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_srcType_3, x_io_out_complexDecodedInsts_0_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_srcType_4, x_io_out_complexDecodedInsts_0_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_lsrc_0, x_io_out_complexDecodedInsts_0_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_lsrc_1, x_io_out_complexDecodedInsts_0_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_lsrc_2, x_io_out_complexDecodedInsts_0_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_ldest, x_io_out_complexDecodedInsts_0_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_0_bits_fuType, x_io_out_complexDecodedInsts_0_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_0_bits_fuOpType, x_io_out_complexDecodedInsts_0_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_0_bits_rfWen, x_io_out_complexDecodedInsts_0_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_0_bits_fpWen, x_io_out_complexDecodedInsts_0_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_0_bits_vecWen, x_io_out_complexDecodedInsts_0_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_0_bits_vlWen, x_io_out_complexDecodedInsts_0_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_0_bits_isXSTrap, x_io_out_complexDecodedInsts_0_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_0_bits_waitForward, x_io_out_complexDecodedInsts_0_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_0_bits_blockBackward, x_io_out_complexDecodedInsts_0_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_0_bits_flushPipe, x_io_out_complexDecodedInsts_0_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_0_bits_canRobCompress, x_io_out_complexDecodedInsts_0_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_0_bits_selImm, x_io_out_complexDecodedInsts_0_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_0_bits_imm, x_io_out_complexDecodedInsts_0_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_0_bits_fpu_wflags, x_io_out_complexDecodedInsts_0_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_fpu_typ, x_io_out_complexDecodedInsts_0_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_fpu_fmt, x_io_out_complexDecodedInsts_0_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_0_bits_fpu_rm, x_io_out_complexDecodedInsts_0_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_vill, x_io_out_complexDecodedInsts_0_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_vma, x_io_out_complexDecodedInsts_0_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_vta, x_io_out_complexDecodedInsts_0_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_vpu_vsew, x_io_out_complexDecodedInsts_0_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_0_bits_vpu_vlmul, x_io_out_complexDecodedInsts_0_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_specVill, x_io_out_complexDecodedInsts_0_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_specVma, x_io_out_complexDecodedInsts_0_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_specVta, x_io_out_complexDecodedInsts_0_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_vpu_specVsew, x_io_out_complexDecodedInsts_0_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_0_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_0_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_vm, x_io_out_complexDecodedInsts_0_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_0_bits_vpu_vstart, x_io_out_complexDecodedInsts_0_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_0_bits_vpu_nf, x_io_out_complexDecodedInsts_0_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_0_bits_vpu_veew, x_io_out_complexDecodedInsts_0_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isReverse, x_io_out_complexDecodedInsts_0_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isExt, x_io_out_complexDecodedInsts_0_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_0_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_0_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_0_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_0_bits_vpu_isVleff, x_io_out_complexDecodedInsts_0_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_0_bits_vlsInstr, x_io_out_complexDecodedInsts_0_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_0_bits_wfflags, x_io_out_complexDecodedInsts_0_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_0_bits_isMove, x_io_out_complexDecodedInsts_0_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_0_bits_uopIdx, x_io_out_complexDecodedInsts_0_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_0_bits_uopSplitType, x_io_out_complexDecodedInsts_0_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_0_bits_isVset, x_io_out_complexDecodedInsts_0_bits_isVset;
  logic            g_io_out_complexDecodedInsts_0_bits_firstUop, x_io_out_complexDecodedInsts_0_bits_firstUop;
  logic            g_io_out_complexDecodedInsts_0_bits_lastUop, x_io_out_complexDecodedInsts_0_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_0_bits_numUops, x_io_out_complexDecodedInsts_0_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_0_bits_numWB, x_io_out_complexDecodedInsts_0_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_0_bits_commitType, x_io_out_complexDecodedInsts_0_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_0_bits_debug_fuType, x_io_out_complexDecodedInsts_0_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx;
  logic            g_io_out_complexDecodedInsts_1_valid, x_io_out_complexDecodedInsts_1_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_1_bits_instr, x_io_out_complexDecodedInsts_1_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_1_bits_pc, x_io_out_complexDecodedInsts_1_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_1_bits_foldpc, x_io_out_complexDecodedInsts_1_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_0, x_io_out_complexDecodedInsts_1_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_1, x_io_out_complexDecodedInsts_1_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_2, x_io_out_complexDecodedInsts_1_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_3, x_io_out_complexDecodedInsts_1_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_4, x_io_out_complexDecodedInsts_1_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_5, x_io_out_complexDecodedInsts_1_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_6, x_io_out_complexDecodedInsts_1_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_7, x_io_out_complexDecodedInsts_1_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_8, x_io_out_complexDecodedInsts_1_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_9, x_io_out_complexDecodedInsts_1_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_10, x_io_out_complexDecodedInsts_1_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_11, x_io_out_complexDecodedInsts_1_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_12, x_io_out_complexDecodedInsts_1_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_13, x_io_out_complexDecodedInsts_1_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_14, x_io_out_complexDecodedInsts_1_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_15, x_io_out_complexDecodedInsts_1_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_16, x_io_out_complexDecodedInsts_1_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_17, x_io_out_complexDecodedInsts_1_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_18, x_io_out_complexDecodedInsts_1_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_19, x_io_out_complexDecodedInsts_1_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_20, x_io_out_complexDecodedInsts_1_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_21, x_io_out_complexDecodedInsts_1_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_22, x_io_out_complexDecodedInsts_1_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_1_bits_exceptionVec_23, x_io_out_complexDecodedInsts_1_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_1_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_1_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_trigger, x_io_out_complexDecodedInsts_1_bits_trigger;
  logic            g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_1_bits_pred_taken, x_io_out_complexDecodedInsts_1_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_1_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_1_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_1_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_1_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_ftqPtr_value, x_io_out_complexDecodedInsts_1_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_ftqOffset, x_io_out_complexDecodedInsts_1_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_srcType_0, x_io_out_complexDecodedInsts_1_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_srcType_1, x_io_out_complexDecodedInsts_1_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_srcType_2, x_io_out_complexDecodedInsts_1_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_srcType_3, x_io_out_complexDecodedInsts_1_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_srcType_4, x_io_out_complexDecodedInsts_1_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_lsrc_0, x_io_out_complexDecodedInsts_1_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_lsrc_1, x_io_out_complexDecodedInsts_1_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_lsrc_2, x_io_out_complexDecodedInsts_1_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_ldest, x_io_out_complexDecodedInsts_1_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_1_bits_fuType, x_io_out_complexDecodedInsts_1_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_1_bits_fuOpType, x_io_out_complexDecodedInsts_1_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_1_bits_rfWen, x_io_out_complexDecodedInsts_1_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_1_bits_fpWen, x_io_out_complexDecodedInsts_1_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_1_bits_vecWen, x_io_out_complexDecodedInsts_1_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_1_bits_vlWen, x_io_out_complexDecodedInsts_1_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_1_bits_isXSTrap, x_io_out_complexDecodedInsts_1_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_1_bits_waitForward, x_io_out_complexDecodedInsts_1_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_1_bits_blockBackward, x_io_out_complexDecodedInsts_1_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_1_bits_flushPipe, x_io_out_complexDecodedInsts_1_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_1_bits_canRobCompress, x_io_out_complexDecodedInsts_1_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_1_bits_selImm, x_io_out_complexDecodedInsts_1_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_1_bits_imm, x_io_out_complexDecodedInsts_1_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_1_bits_fpu_wflags, x_io_out_complexDecodedInsts_1_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_fpu_typ, x_io_out_complexDecodedInsts_1_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_fpu_fmt, x_io_out_complexDecodedInsts_1_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_1_bits_fpu_rm, x_io_out_complexDecodedInsts_1_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_vill, x_io_out_complexDecodedInsts_1_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_vma, x_io_out_complexDecodedInsts_1_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_vta, x_io_out_complexDecodedInsts_1_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_vpu_vsew, x_io_out_complexDecodedInsts_1_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_1_bits_vpu_vlmul, x_io_out_complexDecodedInsts_1_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_specVill, x_io_out_complexDecodedInsts_1_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_specVma, x_io_out_complexDecodedInsts_1_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_specVta, x_io_out_complexDecodedInsts_1_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_vpu_specVsew, x_io_out_complexDecodedInsts_1_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_1_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_1_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_vm, x_io_out_complexDecodedInsts_1_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_1_bits_vpu_vstart, x_io_out_complexDecodedInsts_1_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_1_bits_vpu_nf, x_io_out_complexDecodedInsts_1_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_1_bits_vpu_veew, x_io_out_complexDecodedInsts_1_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isReverse, x_io_out_complexDecodedInsts_1_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isExt, x_io_out_complexDecodedInsts_1_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_1_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_1_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_1_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_1_bits_vpu_isVleff, x_io_out_complexDecodedInsts_1_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_1_bits_vlsInstr, x_io_out_complexDecodedInsts_1_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_1_bits_wfflags, x_io_out_complexDecodedInsts_1_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_1_bits_isMove, x_io_out_complexDecodedInsts_1_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_1_bits_uopIdx, x_io_out_complexDecodedInsts_1_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_1_bits_uopSplitType, x_io_out_complexDecodedInsts_1_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_1_bits_isVset, x_io_out_complexDecodedInsts_1_bits_isVset;
  logic            g_io_out_complexDecodedInsts_1_bits_lastUop, x_io_out_complexDecodedInsts_1_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_1_bits_numUops, x_io_out_complexDecodedInsts_1_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_1_bits_numWB, x_io_out_complexDecodedInsts_1_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_1_bits_commitType, x_io_out_complexDecodedInsts_1_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_1_bits_debug_fuType, x_io_out_complexDecodedInsts_1_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx;
  logic            g_io_out_complexDecodedInsts_2_valid, x_io_out_complexDecodedInsts_2_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_2_bits_instr, x_io_out_complexDecodedInsts_2_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_2_bits_pc, x_io_out_complexDecodedInsts_2_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_2_bits_foldpc, x_io_out_complexDecodedInsts_2_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_0, x_io_out_complexDecodedInsts_2_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_1, x_io_out_complexDecodedInsts_2_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_2, x_io_out_complexDecodedInsts_2_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_3, x_io_out_complexDecodedInsts_2_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_4, x_io_out_complexDecodedInsts_2_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_5, x_io_out_complexDecodedInsts_2_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_6, x_io_out_complexDecodedInsts_2_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_7, x_io_out_complexDecodedInsts_2_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_8, x_io_out_complexDecodedInsts_2_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_9, x_io_out_complexDecodedInsts_2_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_10, x_io_out_complexDecodedInsts_2_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_11, x_io_out_complexDecodedInsts_2_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_12, x_io_out_complexDecodedInsts_2_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_13, x_io_out_complexDecodedInsts_2_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_14, x_io_out_complexDecodedInsts_2_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_15, x_io_out_complexDecodedInsts_2_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_16, x_io_out_complexDecodedInsts_2_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_17, x_io_out_complexDecodedInsts_2_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_18, x_io_out_complexDecodedInsts_2_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_19, x_io_out_complexDecodedInsts_2_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_20, x_io_out_complexDecodedInsts_2_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_21, x_io_out_complexDecodedInsts_2_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_22, x_io_out_complexDecodedInsts_2_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_2_bits_exceptionVec_23, x_io_out_complexDecodedInsts_2_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_2_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_2_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_trigger, x_io_out_complexDecodedInsts_2_bits_trigger;
  logic            g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_2_bits_pred_taken, x_io_out_complexDecodedInsts_2_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_2_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_2_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_2_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_2_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_ftqPtr_value, x_io_out_complexDecodedInsts_2_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_ftqOffset, x_io_out_complexDecodedInsts_2_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_srcType_0, x_io_out_complexDecodedInsts_2_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_srcType_1, x_io_out_complexDecodedInsts_2_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_srcType_2, x_io_out_complexDecodedInsts_2_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_srcType_3, x_io_out_complexDecodedInsts_2_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_srcType_4, x_io_out_complexDecodedInsts_2_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_lsrc_0, x_io_out_complexDecodedInsts_2_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_lsrc_1, x_io_out_complexDecodedInsts_2_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_lsrc_2, x_io_out_complexDecodedInsts_2_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_ldest, x_io_out_complexDecodedInsts_2_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_2_bits_fuType, x_io_out_complexDecodedInsts_2_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_2_bits_fuOpType, x_io_out_complexDecodedInsts_2_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_2_bits_rfWen, x_io_out_complexDecodedInsts_2_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_2_bits_fpWen, x_io_out_complexDecodedInsts_2_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_2_bits_vecWen, x_io_out_complexDecodedInsts_2_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_2_bits_vlWen, x_io_out_complexDecodedInsts_2_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_2_bits_isXSTrap, x_io_out_complexDecodedInsts_2_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_2_bits_waitForward, x_io_out_complexDecodedInsts_2_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_2_bits_blockBackward, x_io_out_complexDecodedInsts_2_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_2_bits_flushPipe, x_io_out_complexDecodedInsts_2_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_2_bits_canRobCompress, x_io_out_complexDecodedInsts_2_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_2_bits_selImm, x_io_out_complexDecodedInsts_2_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_2_bits_imm, x_io_out_complexDecodedInsts_2_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_2_bits_fpu_wflags, x_io_out_complexDecodedInsts_2_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_fpu_typ, x_io_out_complexDecodedInsts_2_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_fpu_fmt, x_io_out_complexDecodedInsts_2_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_2_bits_fpu_rm, x_io_out_complexDecodedInsts_2_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_vill, x_io_out_complexDecodedInsts_2_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_vma, x_io_out_complexDecodedInsts_2_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_vta, x_io_out_complexDecodedInsts_2_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_vpu_vsew, x_io_out_complexDecodedInsts_2_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_2_bits_vpu_vlmul, x_io_out_complexDecodedInsts_2_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_specVill, x_io_out_complexDecodedInsts_2_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_specVma, x_io_out_complexDecodedInsts_2_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_specVta, x_io_out_complexDecodedInsts_2_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_vpu_specVsew, x_io_out_complexDecodedInsts_2_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_2_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_2_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_vm, x_io_out_complexDecodedInsts_2_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_2_bits_vpu_vstart, x_io_out_complexDecodedInsts_2_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_2_bits_vpu_nf, x_io_out_complexDecodedInsts_2_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_2_bits_vpu_veew, x_io_out_complexDecodedInsts_2_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isReverse, x_io_out_complexDecodedInsts_2_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isExt, x_io_out_complexDecodedInsts_2_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_2_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_2_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_2_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_2_bits_vpu_isVleff, x_io_out_complexDecodedInsts_2_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_2_bits_vlsInstr, x_io_out_complexDecodedInsts_2_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_2_bits_wfflags, x_io_out_complexDecodedInsts_2_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_2_bits_isMove, x_io_out_complexDecodedInsts_2_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_2_bits_uopIdx, x_io_out_complexDecodedInsts_2_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_2_bits_uopSplitType, x_io_out_complexDecodedInsts_2_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_2_bits_isVset, x_io_out_complexDecodedInsts_2_bits_isVset;
  logic            g_io_out_complexDecodedInsts_2_bits_lastUop, x_io_out_complexDecodedInsts_2_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_2_bits_numUops, x_io_out_complexDecodedInsts_2_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_2_bits_numWB, x_io_out_complexDecodedInsts_2_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_2_bits_commitType, x_io_out_complexDecodedInsts_2_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_2_bits_debug_fuType, x_io_out_complexDecodedInsts_2_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx;
  logic            g_io_out_complexDecodedInsts_3_valid, x_io_out_complexDecodedInsts_3_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_3_bits_instr, x_io_out_complexDecodedInsts_3_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_3_bits_pc, x_io_out_complexDecodedInsts_3_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_3_bits_foldpc, x_io_out_complexDecodedInsts_3_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_0, x_io_out_complexDecodedInsts_3_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_1, x_io_out_complexDecodedInsts_3_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_2, x_io_out_complexDecodedInsts_3_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_3, x_io_out_complexDecodedInsts_3_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_4, x_io_out_complexDecodedInsts_3_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_5, x_io_out_complexDecodedInsts_3_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_6, x_io_out_complexDecodedInsts_3_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_7, x_io_out_complexDecodedInsts_3_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_8, x_io_out_complexDecodedInsts_3_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_9, x_io_out_complexDecodedInsts_3_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_10, x_io_out_complexDecodedInsts_3_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_11, x_io_out_complexDecodedInsts_3_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_12, x_io_out_complexDecodedInsts_3_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_13, x_io_out_complexDecodedInsts_3_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_14, x_io_out_complexDecodedInsts_3_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_15, x_io_out_complexDecodedInsts_3_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_16, x_io_out_complexDecodedInsts_3_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_17, x_io_out_complexDecodedInsts_3_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_18, x_io_out_complexDecodedInsts_3_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_19, x_io_out_complexDecodedInsts_3_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_20, x_io_out_complexDecodedInsts_3_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_21, x_io_out_complexDecodedInsts_3_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_22, x_io_out_complexDecodedInsts_3_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_3_bits_exceptionVec_23, x_io_out_complexDecodedInsts_3_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_3_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_3_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_trigger, x_io_out_complexDecodedInsts_3_bits_trigger;
  logic            g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_3_bits_pred_taken, x_io_out_complexDecodedInsts_3_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_3_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_3_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_3_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_3_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_ftqPtr_value, x_io_out_complexDecodedInsts_3_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_ftqOffset, x_io_out_complexDecodedInsts_3_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_srcType_0, x_io_out_complexDecodedInsts_3_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_srcType_1, x_io_out_complexDecodedInsts_3_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_srcType_2, x_io_out_complexDecodedInsts_3_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_srcType_3, x_io_out_complexDecodedInsts_3_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_srcType_4, x_io_out_complexDecodedInsts_3_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_lsrc_0, x_io_out_complexDecodedInsts_3_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_lsrc_1, x_io_out_complexDecodedInsts_3_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_lsrc_2, x_io_out_complexDecodedInsts_3_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_ldest, x_io_out_complexDecodedInsts_3_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_3_bits_fuType, x_io_out_complexDecodedInsts_3_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_3_bits_fuOpType, x_io_out_complexDecodedInsts_3_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_3_bits_rfWen, x_io_out_complexDecodedInsts_3_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_3_bits_fpWen, x_io_out_complexDecodedInsts_3_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_3_bits_vecWen, x_io_out_complexDecodedInsts_3_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_3_bits_vlWen, x_io_out_complexDecodedInsts_3_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_3_bits_isXSTrap, x_io_out_complexDecodedInsts_3_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_3_bits_waitForward, x_io_out_complexDecodedInsts_3_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_3_bits_blockBackward, x_io_out_complexDecodedInsts_3_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_3_bits_flushPipe, x_io_out_complexDecodedInsts_3_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_3_bits_canRobCompress, x_io_out_complexDecodedInsts_3_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_3_bits_selImm, x_io_out_complexDecodedInsts_3_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_3_bits_imm, x_io_out_complexDecodedInsts_3_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_3_bits_fpu_wflags, x_io_out_complexDecodedInsts_3_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_fpu_typ, x_io_out_complexDecodedInsts_3_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_fpu_fmt, x_io_out_complexDecodedInsts_3_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_3_bits_fpu_rm, x_io_out_complexDecodedInsts_3_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_vill, x_io_out_complexDecodedInsts_3_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_vma, x_io_out_complexDecodedInsts_3_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_vta, x_io_out_complexDecodedInsts_3_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_vpu_vsew, x_io_out_complexDecodedInsts_3_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_3_bits_vpu_vlmul, x_io_out_complexDecodedInsts_3_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_specVill, x_io_out_complexDecodedInsts_3_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_specVma, x_io_out_complexDecodedInsts_3_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_specVta, x_io_out_complexDecodedInsts_3_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_vpu_specVsew, x_io_out_complexDecodedInsts_3_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_3_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_3_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_vm, x_io_out_complexDecodedInsts_3_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_3_bits_vpu_vstart, x_io_out_complexDecodedInsts_3_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_3_bits_vpu_nf, x_io_out_complexDecodedInsts_3_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_3_bits_vpu_veew, x_io_out_complexDecodedInsts_3_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isReverse, x_io_out_complexDecodedInsts_3_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isExt, x_io_out_complexDecodedInsts_3_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_3_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_3_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_3_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_3_bits_vpu_isVleff, x_io_out_complexDecodedInsts_3_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_3_bits_vlsInstr, x_io_out_complexDecodedInsts_3_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_3_bits_wfflags, x_io_out_complexDecodedInsts_3_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_3_bits_isMove, x_io_out_complexDecodedInsts_3_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_3_bits_uopIdx, x_io_out_complexDecodedInsts_3_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_3_bits_uopSplitType, x_io_out_complexDecodedInsts_3_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_3_bits_isVset, x_io_out_complexDecodedInsts_3_bits_isVset;
  logic            g_io_out_complexDecodedInsts_3_bits_lastUop, x_io_out_complexDecodedInsts_3_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_3_bits_numUops, x_io_out_complexDecodedInsts_3_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_3_bits_numWB, x_io_out_complexDecodedInsts_3_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_3_bits_commitType, x_io_out_complexDecodedInsts_3_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_3_bits_debug_fuType, x_io_out_complexDecodedInsts_3_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx;
  logic            g_io_out_complexDecodedInsts_4_valid, x_io_out_complexDecodedInsts_4_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_4_bits_instr, x_io_out_complexDecodedInsts_4_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_4_bits_pc, x_io_out_complexDecodedInsts_4_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_4_bits_foldpc, x_io_out_complexDecodedInsts_4_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_0, x_io_out_complexDecodedInsts_4_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_1, x_io_out_complexDecodedInsts_4_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_2, x_io_out_complexDecodedInsts_4_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_3, x_io_out_complexDecodedInsts_4_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_4, x_io_out_complexDecodedInsts_4_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_5, x_io_out_complexDecodedInsts_4_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_6, x_io_out_complexDecodedInsts_4_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_7, x_io_out_complexDecodedInsts_4_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_8, x_io_out_complexDecodedInsts_4_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_9, x_io_out_complexDecodedInsts_4_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_10, x_io_out_complexDecodedInsts_4_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_11, x_io_out_complexDecodedInsts_4_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_12, x_io_out_complexDecodedInsts_4_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_13, x_io_out_complexDecodedInsts_4_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_14, x_io_out_complexDecodedInsts_4_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_15, x_io_out_complexDecodedInsts_4_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_16, x_io_out_complexDecodedInsts_4_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_17, x_io_out_complexDecodedInsts_4_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_18, x_io_out_complexDecodedInsts_4_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_19, x_io_out_complexDecodedInsts_4_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_20, x_io_out_complexDecodedInsts_4_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_21, x_io_out_complexDecodedInsts_4_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_22, x_io_out_complexDecodedInsts_4_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_4_bits_exceptionVec_23, x_io_out_complexDecodedInsts_4_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_4_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_4_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_trigger, x_io_out_complexDecodedInsts_4_bits_trigger;
  logic            g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_4_bits_pred_taken, x_io_out_complexDecodedInsts_4_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_4_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_4_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_4_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_4_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_ftqPtr_value, x_io_out_complexDecodedInsts_4_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_ftqOffset, x_io_out_complexDecodedInsts_4_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_srcType_0, x_io_out_complexDecodedInsts_4_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_srcType_1, x_io_out_complexDecodedInsts_4_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_srcType_2, x_io_out_complexDecodedInsts_4_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_srcType_3, x_io_out_complexDecodedInsts_4_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_srcType_4, x_io_out_complexDecodedInsts_4_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_lsrc_0, x_io_out_complexDecodedInsts_4_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_lsrc_1, x_io_out_complexDecodedInsts_4_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_lsrc_2, x_io_out_complexDecodedInsts_4_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_ldest, x_io_out_complexDecodedInsts_4_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_4_bits_fuType, x_io_out_complexDecodedInsts_4_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_4_bits_fuOpType, x_io_out_complexDecodedInsts_4_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_4_bits_rfWen, x_io_out_complexDecodedInsts_4_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_4_bits_fpWen, x_io_out_complexDecodedInsts_4_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_4_bits_vecWen, x_io_out_complexDecodedInsts_4_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_4_bits_vlWen, x_io_out_complexDecodedInsts_4_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_4_bits_isXSTrap, x_io_out_complexDecodedInsts_4_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_4_bits_waitForward, x_io_out_complexDecodedInsts_4_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_4_bits_blockBackward, x_io_out_complexDecodedInsts_4_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_4_bits_flushPipe, x_io_out_complexDecodedInsts_4_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_4_bits_canRobCompress, x_io_out_complexDecodedInsts_4_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_4_bits_selImm, x_io_out_complexDecodedInsts_4_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_4_bits_imm, x_io_out_complexDecodedInsts_4_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_4_bits_fpu_wflags, x_io_out_complexDecodedInsts_4_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_fpu_typ, x_io_out_complexDecodedInsts_4_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_fpu_fmt, x_io_out_complexDecodedInsts_4_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_4_bits_fpu_rm, x_io_out_complexDecodedInsts_4_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_vill, x_io_out_complexDecodedInsts_4_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_vma, x_io_out_complexDecodedInsts_4_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_vta, x_io_out_complexDecodedInsts_4_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_vpu_vsew, x_io_out_complexDecodedInsts_4_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_4_bits_vpu_vlmul, x_io_out_complexDecodedInsts_4_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_specVill, x_io_out_complexDecodedInsts_4_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_specVma, x_io_out_complexDecodedInsts_4_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_specVta, x_io_out_complexDecodedInsts_4_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_vpu_specVsew, x_io_out_complexDecodedInsts_4_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_4_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_4_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_vm, x_io_out_complexDecodedInsts_4_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_4_bits_vpu_vstart, x_io_out_complexDecodedInsts_4_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_4_bits_vpu_nf, x_io_out_complexDecodedInsts_4_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_4_bits_vpu_veew, x_io_out_complexDecodedInsts_4_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isReverse, x_io_out_complexDecodedInsts_4_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isExt, x_io_out_complexDecodedInsts_4_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_4_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_4_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_4_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_4_bits_vpu_isVleff, x_io_out_complexDecodedInsts_4_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_4_bits_vlsInstr, x_io_out_complexDecodedInsts_4_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_4_bits_wfflags, x_io_out_complexDecodedInsts_4_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_4_bits_isMove, x_io_out_complexDecodedInsts_4_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_4_bits_uopIdx, x_io_out_complexDecodedInsts_4_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_4_bits_uopSplitType, x_io_out_complexDecodedInsts_4_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_4_bits_isVset, x_io_out_complexDecodedInsts_4_bits_isVset;
  logic            g_io_out_complexDecodedInsts_4_bits_lastUop, x_io_out_complexDecodedInsts_4_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_4_bits_numUops, x_io_out_complexDecodedInsts_4_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_4_bits_numWB, x_io_out_complexDecodedInsts_4_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_4_bits_commitType, x_io_out_complexDecodedInsts_4_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_4_bits_debug_fuType, x_io_out_complexDecodedInsts_4_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx;
  logic            g_io_out_complexDecodedInsts_5_valid, x_io_out_complexDecodedInsts_5_valid;
  logic [31:0]     g_io_out_complexDecodedInsts_5_bits_instr, x_io_out_complexDecodedInsts_5_bits_instr;
  logic [49:0]     g_io_out_complexDecodedInsts_5_bits_pc, x_io_out_complexDecodedInsts_5_bits_pc;
  logic [9:0]      g_io_out_complexDecodedInsts_5_bits_foldpc, x_io_out_complexDecodedInsts_5_bits_foldpc;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_0, x_io_out_complexDecodedInsts_5_bits_exceptionVec_0;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_1, x_io_out_complexDecodedInsts_5_bits_exceptionVec_1;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_2, x_io_out_complexDecodedInsts_5_bits_exceptionVec_2;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_3, x_io_out_complexDecodedInsts_5_bits_exceptionVec_3;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_4, x_io_out_complexDecodedInsts_5_bits_exceptionVec_4;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_5, x_io_out_complexDecodedInsts_5_bits_exceptionVec_5;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_6, x_io_out_complexDecodedInsts_5_bits_exceptionVec_6;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_7, x_io_out_complexDecodedInsts_5_bits_exceptionVec_7;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_8, x_io_out_complexDecodedInsts_5_bits_exceptionVec_8;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_9, x_io_out_complexDecodedInsts_5_bits_exceptionVec_9;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_10, x_io_out_complexDecodedInsts_5_bits_exceptionVec_10;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_11, x_io_out_complexDecodedInsts_5_bits_exceptionVec_11;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_12, x_io_out_complexDecodedInsts_5_bits_exceptionVec_12;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_13, x_io_out_complexDecodedInsts_5_bits_exceptionVec_13;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_14, x_io_out_complexDecodedInsts_5_bits_exceptionVec_14;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_15, x_io_out_complexDecodedInsts_5_bits_exceptionVec_15;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_16, x_io_out_complexDecodedInsts_5_bits_exceptionVec_16;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_17, x_io_out_complexDecodedInsts_5_bits_exceptionVec_17;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_18, x_io_out_complexDecodedInsts_5_bits_exceptionVec_18;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_19, x_io_out_complexDecodedInsts_5_bits_exceptionVec_19;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_20, x_io_out_complexDecodedInsts_5_bits_exceptionVec_20;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_21, x_io_out_complexDecodedInsts_5_bits_exceptionVec_21;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_22, x_io_out_complexDecodedInsts_5_bits_exceptionVec_22;
  logic            g_io_out_complexDecodedInsts_5_bits_exceptionVec_23, x_io_out_complexDecodedInsts_5_bits_exceptionVec_23;
  logic            g_io_out_complexDecodedInsts_5_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_5_bits_isFetchMalAddr;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_trigger, x_io_out_complexDecodedInsts_5_bits_trigger;
  logic            g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid;
  logic            g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType;
  logic            g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall;
  logic            g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet;
  logic            g_io_out_complexDecodedInsts_5_bits_pred_taken, x_io_out_complexDecodedInsts_5_bits_pred_taken;
  logic            g_io_out_complexDecodedInsts_5_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_5_bits_crossPageIPFFix;
  logic            g_io_out_complexDecodedInsts_5_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_5_bits_ftqPtr_flag;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_ftqPtr_value, x_io_out_complexDecodedInsts_5_bits_ftqPtr_value;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_ftqOffset, x_io_out_complexDecodedInsts_5_bits_ftqOffset;
  logic            g_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_srcType_0, x_io_out_complexDecodedInsts_5_bits_srcType_0;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_srcType_1, x_io_out_complexDecodedInsts_5_bits_srcType_1;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_srcType_2, x_io_out_complexDecodedInsts_5_bits_srcType_2;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_srcType_3, x_io_out_complexDecodedInsts_5_bits_srcType_3;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_srcType_4, x_io_out_complexDecodedInsts_5_bits_srcType_4;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_lsrc_0, x_io_out_complexDecodedInsts_5_bits_lsrc_0;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_lsrc_1, x_io_out_complexDecodedInsts_5_bits_lsrc_1;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_lsrc_2, x_io_out_complexDecodedInsts_5_bits_lsrc_2;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_ldest, x_io_out_complexDecodedInsts_5_bits_ldest;
  logic [34:0]     g_io_out_complexDecodedInsts_5_bits_fuType, x_io_out_complexDecodedInsts_5_bits_fuType;
  logic [8:0]      g_io_out_complexDecodedInsts_5_bits_fuOpType, x_io_out_complexDecodedInsts_5_bits_fuOpType;
  logic            g_io_out_complexDecodedInsts_5_bits_rfWen, x_io_out_complexDecodedInsts_5_bits_rfWen;
  logic            g_io_out_complexDecodedInsts_5_bits_fpWen, x_io_out_complexDecodedInsts_5_bits_fpWen;
  logic            g_io_out_complexDecodedInsts_5_bits_vecWen, x_io_out_complexDecodedInsts_5_bits_vecWen;
  logic            g_io_out_complexDecodedInsts_5_bits_vlWen, x_io_out_complexDecodedInsts_5_bits_vlWen;
  logic            g_io_out_complexDecodedInsts_5_bits_isXSTrap, x_io_out_complexDecodedInsts_5_bits_isXSTrap;
  logic            g_io_out_complexDecodedInsts_5_bits_waitForward, x_io_out_complexDecodedInsts_5_bits_waitForward;
  logic            g_io_out_complexDecodedInsts_5_bits_blockBackward, x_io_out_complexDecodedInsts_5_bits_blockBackward;
  logic            g_io_out_complexDecodedInsts_5_bits_flushPipe, x_io_out_complexDecodedInsts_5_bits_flushPipe;
  logic            g_io_out_complexDecodedInsts_5_bits_canRobCompress, x_io_out_complexDecodedInsts_5_bits_canRobCompress;
  logic [3:0]      g_io_out_complexDecodedInsts_5_bits_selImm, x_io_out_complexDecodedInsts_5_bits_selImm;
  logic [21:0]     g_io_out_complexDecodedInsts_5_bits_imm, x_io_out_complexDecodedInsts_5_bits_imm;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut;
  logic            g_io_out_complexDecodedInsts_5_bits_fpu_wflags, x_io_out_complexDecodedInsts_5_bits_fpu_wflags;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_fpu_typ, x_io_out_complexDecodedInsts_5_bits_fpu_typ;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_fpu_fmt, x_io_out_complexDecodedInsts_5_bits_fpu_fmt;
  logic [2:0]      g_io_out_complexDecodedInsts_5_bits_fpu_rm, x_io_out_complexDecodedInsts_5_bits_fpu_rm;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_vill, x_io_out_complexDecodedInsts_5_bits_vpu_vill;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_vma, x_io_out_complexDecodedInsts_5_bits_vpu_vma;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_vta, x_io_out_complexDecodedInsts_5_bits_vpu_vta;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_vpu_vsew, x_io_out_complexDecodedInsts_5_bits_vpu_vsew;
  logic [2:0]      g_io_out_complexDecodedInsts_5_bits_vpu_vlmul, x_io_out_complexDecodedInsts_5_bits_vpu_vlmul;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_specVill, x_io_out_complexDecodedInsts_5_bits_vpu_specVill;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_specVma, x_io_out_complexDecodedInsts_5_bits_vpu_specVma;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_specVta, x_io_out_complexDecodedInsts_5_bits_vpu_specVta;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_vpu_specVsew, x_io_out_complexDecodedInsts_5_bits_vpu_specVsew;
  logic [2:0]      g_io_out_complexDecodedInsts_5_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_5_bits_vpu_specVlmul;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_vm, x_io_out_complexDecodedInsts_5_bits_vpu_vm;
  logic [7:0]      g_io_out_complexDecodedInsts_5_bits_vpu_vstart, x_io_out_complexDecodedInsts_5_bits_vpu_vstart;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]      g_io_out_complexDecodedInsts_5_bits_vpu_nf, x_io_out_complexDecodedInsts_5_bits_vpu_nf;
  logic [1:0]      g_io_out_complexDecodedInsts_5_bits_vpu_veew, x_io_out_complexDecodedInsts_5_bits_vpu_veew;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isReverse, x_io_out_complexDecodedInsts_5_bits_vpu_isReverse;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isExt, x_io_out_complexDecodedInsts_5_bits_vpu_isExt;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_5_bits_vpu_isNarrow;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_5_bits_vpu_isDstMask;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_5_bits_vpu_isOpMask;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd;
  logic            g_io_out_complexDecodedInsts_5_bits_vpu_isVleff, x_io_out_complexDecodedInsts_5_bits_vpu_isVleff;
  logic            g_io_out_complexDecodedInsts_5_bits_vlsInstr, x_io_out_complexDecodedInsts_5_bits_vlsInstr;
  logic            g_io_out_complexDecodedInsts_5_bits_wfflags, x_io_out_complexDecodedInsts_5_bits_wfflags;
  logic            g_io_out_complexDecodedInsts_5_bits_isMove, x_io_out_complexDecodedInsts_5_bits_isMove;
  logic [6:0]      g_io_out_complexDecodedInsts_5_bits_uopIdx, x_io_out_complexDecodedInsts_5_bits_uopIdx;
  logic [5:0]      g_io_out_complexDecodedInsts_5_bits_uopSplitType, x_io_out_complexDecodedInsts_5_bits_uopSplitType;
  logic            g_io_out_complexDecodedInsts_5_bits_isVset, x_io_out_complexDecodedInsts_5_bits_isVset;
  logic            g_io_out_complexDecodedInsts_5_bits_lastUop, x_io_out_complexDecodedInsts_5_bits_lastUop;
  logic [6:0]      g_io_out_complexDecodedInsts_5_bits_numUops, x_io_out_complexDecodedInsts_5_bits_numUops;
  logic [6:0]      g_io_out_complexDecodedInsts_5_bits_numWB, x_io_out_complexDecodedInsts_5_bits_numWB;
  logic [2:0]      g_io_out_complexDecodedInsts_5_bits_commitType, x_io_out_complexDecodedInsts_5_bits_commitType;
  logic [34:0]     g_io_out_complexDecodedInsts_5_bits_debug_fuType, x_io_out_complexDecodedInsts_5_bits_debug_fuType;
  logic [55:0]     g_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum;
  logic [7:0]      g_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx;
  logic [2:0]      g_io_complexNum, x_io_complexNum;

  DecodeUnitComp u_gold (
    .clock(clk), .reset(rst), .io_redirect(io_redirect),
    .io_vtypeBypass_illegal(io_vtypeBypass_illegal), .io_vtypeBypass_vma(io_vtypeBypass_vma), .io_vtypeBypass_vta(io_vtypeBypass_vta),
    .io_vtypeBypass_vsew(io_vtypeBypass_vsew), .io_vtypeBypass_vlmul(io_vtypeBypass_vlmul), .io_in_valid(io_in_valid),
    .io_in_bits_simpleDecodedInst_instr(io_in_bits_simpleDecodedInst_instr), .io_in_bits_simpleDecodedInst_pc(io_in_bits_simpleDecodedInst_pc), .io_in_bits_simpleDecodedInst_foldpc(io_in_bits_simpleDecodedInst_foldpc),
    .io_in_bits_simpleDecodedInst_exceptionVec_0(io_in_bits_simpleDecodedInst_exceptionVec_0), .io_in_bits_simpleDecodedInst_exceptionVec_1(io_in_bits_simpleDecodedInst_exceptionVec_1), .io_in_bits_simpleDecodedInst_exceptionVec_2(io_in_bits_simpleDecodedInst_exceptionVec_2),
    .io_in_bits_simpleDecodedInst_exceptionVec_3(io_in_bits_simpleDecodedInst_exceptionVec_3), .io_in_bits_simpleDecodedInst_exceptionVec_4(io_in_bits_simpleDecodedInst_exceptionVec_4), .io_in_bits_simpleDecodedInst_exceptionVec_5(io_in_bits_simpleDecodedInst_exceptionVec_5),
    .io_in_bits_simpleDecodedInst_exceptionVec_6(io_in_bits_simpleDecodedInst_exceptionVec_6), .io_in_bits_simpleDecodedInst_exceptionVec_7(io_in_bits_simpleDecodedInst_exceptionVec_7), .io_in_bits_simpleDecodedInst_exceptionVec_8(io_in_bits_simpleDecodedInst_exceptionVec_8),
    .io_in_bits_simpleDecodedInst_exceptionVec_9(io_in_bits_simpleDecodedInst_exceptionVec_9), .io_in_bits_simpleDecodedInst_exceptionVec_10(io_in_bits_simpleDecodedInst_exceptionVec_10), .io_in_bits_simpleDecodedInst_exceptionVec_11(io_in_bits_simpleDecodedInst_exceptionVec_11),
    .io_in_bits_simpleDecodedInst_exceptionVec_12(io_in_bits_simpleDecodedInst_exceptionVec_12), .io_in_bits_simpleDecodedInst_exceptionVec_13(io_in_bits_simpleDecodedInst_exceptionVec_13), .io_in_bits_simpleDecodedInst_exceptionVec_14(io_in_bits_simpleDecodedInst_exceptionVec_14),
    .io_in_bits_simpleDecodedInst_exceptionVec_15(io_in_bits_simpleDecodedInst_exceptionVec_15), .io_in_bits_simpleDecodedInst_exceptionVec_16(io_in_bits_simpleDecodedInst_exceptionVec_16), .io_in_bits_simpleDecodedInst_exceptionVec_17(io_in_bits_simpleDecodedInst_exceptionVec_17),
    .io_in_bits_simpleDecodedInst_exceptionVec_18(io_in_bits_simpleDecodedInst_exceptionVec_18), .io_in_bits_simpleDecodedInst_exceptionVec_19(io_in_bits_simpleDecodedInst_exceptionVec_19), .io_in_bits_simpleDecodedInst_exceptionVec_20(io_in_bits_simpleDecodedInst_exceptionVec_20),
    .io_in_bits_simpleDecodedInst_exceptionVec_21(io_in_bits_simpleDecodedInst_exceptionVec_21), .io_in_bits_simpleDecodedInst_exceptionVec_22(io_in_bits_simpleDecodedInst_exceptionVec_22), .io_in_bits_simpleDecodedInst_exceptionVec_23(io_in_bits_simpleDecodedInst_exceptionVec_23),
    .io_in_bits_simpleDecodedInst_isFetchMalAddr(io_in_bits_simpleDecodedInst_isFetchMalAddr), .io_in_bits_simpleDecodedInst_trigger(io_in_bits_simpleDecodedInst_trigger), .io_in_bits_simpleDecodedInst_preDecodeInfo_valid(io_in_bits_simpleDecodedInst_preDecodeInfo_valid),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC(io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC), .io_in_bits_simpleDecodedInst_preDecodeInfo_brType(io_in_bits_simpleDecodedInst_preDecodeInfo_brType), .io_in_bits_simpleDecodedInst_preDecodeInfo_isCall(io_in_bits_simpleDecodedInst_preDecodeInfo_isCall),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRet(io_in_bits_simpleDecodedInst_preDecodeInfo_isRet), .io_in_bits_simpleDecodedInst_pred_taken(io_in_bits_simpleDecodedInst_pred_taken), .io_in_bits_simpleDecodedInst_crossPageIPFFix(io_in_bits_simpleDecodedInst_crossPageIPFFix),
    .io_in_bits_simpleDecodedInst_ftqPtr_flag(io_in_bits_simpleDecodedInst_ftqPtr_flag), .io_in_bits_simpleDecodedInst_ftqPtr_value(io_in_bits_simpleDecodedInst_ftqPtr_value), .io_in_bits_simpleDecodedInst_ftqOffset(io_in_bits_simpleDecodedInst_ftqOffset),
    .io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault(io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault), .io_in_bits_simpleDecodedInst_srcType_0(io_in_bits_simpleDecodedInst_srcType_0), .io_in_bits_simpleDecodedInst_srcType_1(io_in_bits_simpleDecodedInst_srcType_1),
    .io_in_bits_simpleDecodedInst_srcType_2(io_in_bits_simpleDecodedInst_srcType_2), .io_in_bits_simpleDecodedInst_srcType_3(io_in_bits_simpleDecodedInst_srcType_3), .io_in_bits_simpleDecodedInst_srcType_4(io_in_bits_simpleDecodedInst_srcType_4),
    .io_in_bits_simpleDecodedInst_lsrc_0(io_in_bits_simpleDecodedInst_lsrc_0), .io_in_bits_simpleDecodedInst_lsrc_1(io_in_bits_simpleDecodedInst_lsrc_1), .io_in_bits_simpleDecodedInst_lsrc_2(io_in_bits_simpleDecodedInst_lsrc_2),
    .io_in_bits_simpleDecodedInst_ldest(io_in_bits_simpleDecodedInst_ldest), .io_in_bits_simpleDecodedInst_fuType(io_in_bits_simpleDecodedInst_fuType), .io_in_bits_simpleDecodedInst_fuOpType(io_in_bits_simpleDecodedInst_fuOpType),
    .io_in_bits_simpleDecodedInst_rfWen(io_in_bits_simpleDecodedInst_rfWen), .io_in_bits_simpleDecodedInst_fpWen(io_in_bits_simpleDecodedInst_fpWen), .io_in_bits_simpleDecodedInst_vecWen(io_in_bits_simpleDecodedInst_vecWen),
    .io_in_bits_simpleDecodedInst_isXSTrap(io_in_bits_simpleDecodedInst_isXSTrap), .io_in_bits_simpleDecodedInst_waitForward(io_in_bits_simpleDecodedInst_waitForward), .io_in_bits_simpleDecodedInst_blockBackward(io_in_bits_simpleDecodedInst_blockBackward),
    .io_in_bits_simpleDecodedInst_flushPipe(io_in_bits_simpleDecodedInst_flushPipe), .io_in_bits_simpleDecodedInst_canRobCompress(io_in_bits_simpleDecodedInst_canRobCompress), .io_in_bits_simpleDecodedInst_selImm(io_in_bits_simpleDecodedInst_selImm),
    .io_in_bits_simpleDecodedInst_imm(io_in_bits_simpleDecodedInst_imm), .io_in_bits_simpleDecodedInst_fpu_typeTagOut(io_in_bits_simpleDecodedInst_fpu_typeTagOut), .io_in_bits_simpleDecodedInst_fpu_wflags(io_in_bits_simpleDecodedInst_fpu_wflags),
    .io_in_bits_simpleDecodedInst_fpu_typ(io_in_bits_simpleDecodedInst_fpu_typ), .io_in_bits_simpleDecodedInst_fpu_fmt(io_in_bits_simpleDecodedInst_fpu_fmt), .io_in_bits_simpleDecodedInst_fpu_rm(io_in_bits_simpleDecodedInst_fpu_rm),
    .io_in_bits_simpleDecodedInst_vpu_vill(io_in_bits_simpleDecodedInst_vpu_vill), .io_in_bits_simpleDecodedInst_vpu_vma(io_in_bits_simpleDecodedInst_vpu_vma), .io_in_bits_simpleDecodedInst_vpu_vta(io_in_bits_simpleDecodedInst_vpu_vta),
    .io_in_bits_simpleDecodedInst_vpu_vsew(io_in_bits_simpleDecodedInst_vpu_vsew), .io_in_bits_simpleDecodedInst_vpu_vlmul(io_in_bits_simpleDecodedInst_vpu_vlmul), .io_in_bits_simpleDecodedInst_vpu_specVill(io_in_bits_simpleDecodedInst_vpu_specVill),
    .io_in_bits_simpleDecodedInst_vpu_specVma(io_in_bits_simpleDecodedInst_vpu_specVma), .io_in_bits_simpleDecodedInst_vpu_specVta(io_in_bits_simpleDecodedInst_vpu_specVta), .io_in_bits_simpleDecodedInst_vpu_specVsew(io_in_bits_simpleDecodedInst_vpu_specVsew),
    .io_in_bits_simpleDecodedInst_vpu_specVlmul(io_in_bits_simpleDecodedInst_vpu_specVlmul), .io_in_bits_simpleDecodedInst_vpu_vm(io_in_bits_simpleDecodedInst_vpu_vm), .io_in_bits_simpleDecodedInst_vpu_vstart(io_in_bits_simpleDecodedInst_vpu_vstart),
    .io_in_bits_simpleDecodedInst_vpu_nf(io_in_bits_simpleDecodedInst_vpu_nf), .io_in_bits_simpleDecodedInst_vpu_veew(io_in_bits_simpleDecodedInst_vpu_veew), .io_in_bits_simpleDecodedInst_vpu_isReverse(io_in_bits_simpleDecodedInst_vpu_isReverse),
    .io_in_bits_simpleDecodedInst_vpu_isExt(io_in_bits_simpleDecodedInst_vpu_isExt), .io_in_bits_simpleDecodedInst_vpu_isNarrow(io_in_bits_simpleDecodedInst_vpu_isNarrow), .io_in_bits_simpleDecodedInst_vpu_isDstMask(io_in_bits_simpleDecodedInst_vpu_isDstMask),
    .io_in_bits_simpleDecodedInst_vpu_isOpMask(io_in_bits_simpleDecodedInst_vpu_isOpMask), .io_in_bits_simpleDecodedInst_vpu_isDependOldVd(io_in_bits_simpleDecodedInst_vpu_isDependOldVd), .io_in_bits_simpleDecodedInst_vpu_isWritePartVd(io_in_bits_simpleDecodedInst_vpu_isWritePartVd),
    .io_in_bits_simpleDecodedInst_vpu_isVleff(io_in_bits_simpleDecodedInst_vpu_isVleff), .io_in_bits_simpleDecodedInst_wfflags(io_in_bits_simpleDecodedInst_wfflags), .io_in_bits_simpleDecodedInst_isMove(io_in_bits_simpleDecodedInst_isMove),
    .io_in_bits_simpleDecodedInst_uopSplitType(io_in_bits_simpleDecodedInst_uopSplitType), .io_in_bits_simpleDecodedInst_isVset(io_in_bits_simpleDecodedInst_isVset), .io_in_bits_simpleDecodedInst_commitType(io_in_bits_simpleDecodedInst_commitType),
    .io_in_bits_simpleDecodedInst_debug_fuType(io_in_bits_simpleDecodedInst_debug_fuType), .io_in_bits_simpleDecodedInst_debug_seqNum_seqNum(io_in_bits_simpleDecodedInst_debug_seqNum_seqNum), .io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx(io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx),
    .io_in_bits_uopInfo_numOfUop(io_in_bits_uopInfo_numOfUop), .io_in_bits_uopInfo_numOfWB(io_in_bits_uopInfo_numOfWB), .io_in_bits_uopInfo_lmul(io_in_bits_uopInfo_lmul),
    .io_out_complexDecodedInsts_0_ready(io_out_complexDecodedInsts_0_ready), .io_in_ready(g_io_in_ready), .io_out_complexDecodedInsts_0_valid(g_io_out_complexDecodedInsts_0_valid),
    .io_out_complexDecodedInsts_0_bits_instr(g_io_out_complexDecodedInsts_0_bits_instr), .io_out_complexDecodedInsts_0_bits_pc(g_io_out_complexDecodedInsts_0_bits_pc), .io_out_complexDecodedInsts_0_bits_foldpc(g_io_out_complexDecodedInsts_0_bits_foldpc),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_0(g_io_out_complexDecodedInsts_0_bits_exceptionVec_0), .io_out_complexDecodedInsts_0_bits_exceptionVec_1(g_io_out_complexDecodedInsts_0_bits_exceptionVec_1), .io_out_complexDecodedInsts_0_bits_exceptionVec_2(g_io_out_complexDecodedInsts_0_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_3(g_io_out_complexDecodedInsts_0_bits_exceptionVec_3), .io_out_complexDecodedInsts_0_bits_exceptionVec_4(g_io_out_complexDecodedInsts_0_bits_exceptionVec_4), .io_out_complexDecodedInsts_0_bits_exceptionVec_5(g_io_out_complexDecodedInsts_0_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_6(g_io_out_complexDecodedInsts_0_bits_exceptionVec_6), .io_out_complexDecodedInsts_0_bits_exceptionVec_7(g_io_out_complexDecodedInsts_0_bits_exceptionVec_7), .io_out_complexDecodedInsts_0_bits_exceptionVec_8(g_io_out_complexDecodedInsts_0_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_9(g_io_out_complexDecodedInsts_0_bits_exceptionVec_9), .io_out_complexDecodedInsts_0_bits_exceptionVec_10(g_io_out_complexDecodedInsts_0_bits_exceptionVec_10), .io_out_complexDecodedInsts_0_bits_exceptionVec_11(g_io_out_complexDecodedInsts_0_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_12(g_io_out_complexDecodedInsts_0_bits_exceptionVec_12), .io_out_complexDecodedInsts_0_bits_exceptionVec_13(g_io_out_complexDecodedInsts_0_bits_exceptionVec_13), .io_out_complexDecodedInsts_0_bits_exceptionVec_14(g_io_out_complexDecodedInsts_0_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_15(g_io_out_complexDecodedInsts_0_bits_exceptionVec_15), .io_out_complexDecodedInsts_0_bits_exceptionVec_16(g_io_out_complexDecodedInsts_0_bits_exceptionVec_16), .io_out_complexDecodedInsts_0_bits_exceptionVec_17(g_io_out_complexDecodedInsts_0_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_18(g_io_out_complexDecodedInsts_0_bits_exceptionVec_18), .io_out_complexDecodedInsts_0_bits_exceptionVec_19(g_io_out_complexDecodedInsts_0_bits_exceptionVec_19), .io_out_complexDecodedInsts_0_bits_exceptionVec_20(g_io_out_complexDecodedInsts_0_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_21(g_io_out_complexDecodedInsts_0_bits_exceptionVec_21), .io_out_complexDecodedInsts_0_bits_exceptionVec_22(g_io_out_complexDecodedInsts_0_bits_exceptionVec_22), .io_out_complexDecodedInsts_0_bits_exceptionVec_23(g_io_out_complexDecodedInsts_0_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_0_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_0_bits_isFetchMalAddr), .io_out_complexDecodedInsts_0_bits_trigger(g_io_out_complexDecodedInsts_0_bits_trigger), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_0_bits_pred_taken(g_io_out_complexDecodedInsts_0_bits_pred_taken), .io_out_complexDecodedInsts_0_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_0_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_0_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_0_bits_ftqPtr_flag), .io_out_complexDecodedInsts_0_bits_ftqPtr_value(g_io_out_complexDecodedInsts_0_bits_ftqPtr_value), .io_out_complexDecodedInsts_0_bits_ftqOffset(g_io_out_complexDecodedInsts_0_bits_ftqOffset),
    .io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_0_bits_srcType_0(g_io_out_complexDecodedInsts_0_bits_srcType_0), .io_out_complexDecodedInsts_0_bits_srcType_1(g_io_out_complexDecodedInsts_0_bits_srcType_1),
    .io_out_complexDecodedInsts_0_bits_srcType_2(g_io_out_complexDecodedInsts_0_bits_srcType_2), .io_out_complexDecodedInsts_0_bits_srcType_3(g_io_out_complexDecodedInsts_0_bits_srcType_3), .io_out_complexDecodedInsts_0_bits_srcType_4(g_io_out_complexDecodedInsts_0_bits_srcType_4),
    .io_out_complexDecodedInsts_0_bits_lsrc_0(g_io_out_complexDecodedInsts_0_bits_lsrc_0), .io_out_complexDecodedInsts_0_bits_lsrc_1(g_io_out_complexDecodedInsts_0_bits_lsrc_1), .io_out_complexDecodedInsts_0_bits_lsrc_2(g_io_out_complexDecodedInsts_0_bits_lsrc_2),
    .io_out_complexDecodedInsts_0_bits_ldest(g_io_out_complexDecodedInsts_0_bits_ldest), .io_out_complexDecodedInsts_0_bits_fuType(g_io_out_complexDecodedInsts_0_bits_fuType), .io_out_complexDecodedInsts_0_bits_fuOpType(g_io_out_complexDecodedInsts_0_bits_fuOpType),
    .io_out_complexDecodedInsts_0_bits_rfWen(g_io_out_complexDecodedInsts_0_bits_rfWen), .io_out_complexDecodedInsts_0_bits_fpWen(g_io_out_complexDecodedInsts_0_bits_fpWen), .io_out_complexDecodedInsts_0_bits_vecWen(g_io_out_complexDecodedInsts_0_bits_vecWen),
    .io_out_complexDecodedInsts_0_bits_vlWen(g_io_out_complexDecodedInsts_0_bits_vlWen), .io_out_complexDecodedInsts_0_bits_isXSTrap(g_io_out_complexDecodedInsts_0_bits_isXSTrap), .io_out_complexDecodedInsts_0_bits_waitForward(g_io_out_complexDecodedInsts_0_bits_waitForward),
    .io_out_complexDecodedInsts_0_bits_blockBackward(g_io_out_complexDecodedInsts_0_bits_blockBackward), .io_out_complexDecodedInsts_0_bits_flushPipe(g_io_out_complexDecodedInsts_0_bits_flushPipe), .io_out_complexDecodedInsts_0_bits_canRobCompress(g_io_out_complexDecodedInsts_0_bits_canRobCompress),
    .io_out_complexDecodedInsts_0_bits_selImm(g_io_out_complexDecodedInsts_0_bits_selImm), .io_out_complexDecodedInsts_0_bits_imm(g_io_out_complexDecodedInsts_0_bits_imm), .io_out_complexDecodedInsts_0_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_0_bits_fpu_wflags(g_io_out_complexDecodedInsts_0_bits_fpu_wflags), .io_out_complexDecodedInsts_0_bits_fpu_typ(g_io_out_complexDecodedInsts_0_bits_fpu_typ), .io_out_complexDecodedInsts_0_bits_fpu_fmt(g_io_out_complexDecodedInsts_0_bits_fpu_fmt),
    .io_out_complexDecodedInsts_0_bits_fpu_rm(g_io_out_complexDecodedInsts_0_bits_fpu_rm), .io_out_complexDecodedInsts_0_bits_vpu_vill(g_io_out_complexDecodedInsts_0_bits_vpu_vill), .io_out_complexDecodedInsts_0_bits_vpu_vma(g_io_out_complexDecodedInsts_0_bits_vpu_vma),
    .io_out_complexDecodedInsts_0_bits_vpu_vta(g_io_out_complexDecodedInsts_0_bits_vpu_vta), .io_out_complexDecodedInsts_0_bits_vpu_vsew(g_io_out_complexDecodedInsts_0_bits_vpu_vsew), .io_out_complexDecodedInsts_0_bits_vpu_vlmul(g_io_out_complexDecodedInsts_0_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_0_bits_vpu_specVill(g_io_out_complexDecodedInsts_0_bits_vpu_specVill), .io_out_complexDecodedInsts_0_bits_vpu_specVma(g_io_out_complexDecodedInsts_0_bits_vpu_specVma), .io_out_complexDecodedInsts_0_bits_vpu_specVta(g_io_out_complexDecodedInsts_0_bits_vpu_specVta),
    .io_out_complexDecodedInsts_0_bits_vpu_specVsew(g_io_out_complexDecodedInsts_0_bits_vpu_specVsew), .io_out_complexDecodedInsts_0_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_0_bits_vpu_specVlmul), .io_out_complexDecodedInsts_0_bits_vpu_vm(g_io_out_complexDecodedInsts_0_bits_vpu_vm),
    .io_out_complexDecodedInsts_0_bits_vpu_vstart(g_io_out_complexDecodedInsts_0_bits_vpu_vstart), .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_0_bits_vpu_nf(g_io_out_complexDecodedInsts_0_bits_vpu_nf), .io_out_complexDecodedInsts_0_bits_vpu_veew(g_io_out_complexDecodedInsts_0_bits_vpu_veew),
    .io_out_complexDecodedInsts_0_bits_vpu_isReverse(g_io_out_complexDecodedInsts_0_bits_vpu_isReverse), .io_out_complexDecodedInsts_0_bits_vpu_isExt(g_io_out_complexDecodedInsts_0_bits_vpu_isExt), .io_out_complexDecodedInsts_0_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_0_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_0_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_0_bits_vpu_isDstMask), .io_out_complexDecodedInsts_0_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_0_bits_vpu_isOpMask), .io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_0_bits_vpu_isVleff(g_io_out_complexDecodedInsts_0_bits_vpu_isVleff), .io_out_complexDecodedInsts_0_bits_vlsInstr(g_io_out_complexDecodedInsts_0_bits_vlsInstr),
    .io_out_complexDecodedInsts_0_bits_wfflags(g_io_out_complexDecodedInsts_0_bits_wfflags), .io_out_complexDecodedInsts_0_bits_isMove(g_io_out_complexDecodedInsts_0_bits_isMove), .io_out_complexDecodedInsts_0_bits_uopIdx(g_io_out_complexDecodedInsts_0_bits_uopIdx),
    .io_out_complexDecodedInsts_0_bits_uopSplitType(g_io_out_complexDecodedInsts_0_bits_uopSplitType), .io_out_complexDecodedInsts_0_bits_isVset(g_io_out_complexDecodedInsts_0_bits_isVset), .io_out_complexDecodedInsts_0_bits_firstUop(g_io_out_complexDecodedInsts_0_bits_firstUop),
    .io_out_complexDecodedInsts_0_bits_lastUop(g_io_out_complexDecodedInsts_0_bits_lastUop), .io_out_complexDecodedInsts_0_bits_numUops(g_io_out_complexDecodedInsts_0_bits_numUops), .io_out_complexDecodedInsts_0_bits_numWB(g_io_out_complexDecodedInsts_0_bits_numWB),
    .io_out_complexDecodedInsts_0_bits_commitType(g_io_out_complexDecodedInsts_0_bits_commitType), .io_out_complexDecodedInsts_0_bits_debug_fuType(g_io_out_complexDecodedInsts_0_bits_debug_fuType), .io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_1_valid(g_io_out_complexDecodedInsts_1_valid), .io_out_complexDecodedInsts_1_bits_instr(g_io_out_complexDecodedInsts_1_bits_instr),
    .io_out_complexDecodedInsts_1_bits_pc(g_io_out_complexDecodedInsts_1_bits_pc), .io_out_complexDecodedInsts_1_bits_foldpc(g_io_out_complexDecodedInsts_1_bits_foldpc), .io_out_complexDecodedInsts_1_bits_exceptionVec_0(g_io_out_complexDecodedInsts_1_bits_exceptionVec_0),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_1(g_io_out_complexDecodedInsts_1_bits_exceptionVec_1), .io_out_complexDecodedInsts_1_bits_exceptionVec_2(g_io_out_complexDecodedInsts_1_bits_exceptionVec_2), .io_out_complexDecodedInsts_1_bits_exceptionVec_3(g_io_out_complexDecodedInsts_1_bits_exceptionVec_3),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_4(g_io_out_complexDecodedInsts_1_bits_exceptionVec_4), .io_out_complexDecodedInsts_1_bits_exceptionVec_5(g_io_out_complexDecodedInsts_1_bits_exceptionVec_5), .io_out_complexDecodedInsts_1_bits_exceptionVec_6(g_io_out_complexDecodedInsts_1_bits_exceptionVec_6),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_7(g_io_out_complexDecodedInsts_1_bits_exceptionVec_7), .io_out_complexDecodedInsts_1_bits_exceptionVec_8(g_io_out_complexDecodedInsts_1_bits_exceptionVec_8), .io_out_complexDecodedInsts_1_bits_exceptionVec_9(g_io_out_complexDecodedInsts_1_bits_exceptionVec_9),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_10(g_io_out_complexDecodedInsts_1_bits_exceptionVec_10), .io_out_complexDecodedInsts_1_bits_exceptionVec_11(g_io_out_complexDecodedInsts_1_bits_exceptionVec_11), .io_out_complexDecodedInsts_1_bits_exceptionVec_12(g_io_out_complexDecodedInsts_1_bits_exceptionVec_12),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_13(g_io_out_complexDecodedInsts_1_bits_exceptionVec_13), .io_out_complexDecodedInsts_1_bits_exceptionVec_14(g_io_out_complexDecodedInsts_1_bits_exceptionVec_14), .io_out_complexDecodedInsts_1_bits_exceptionVec_15(g_io_out_complexDecodedInsts_1_bits_exceptionVec_15),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_16(g_io_out_complexDecodedInsts_1_bits_exceptionVec_16), .io_out_complexDecodedInsts_1_bits_exceptionVec_17(g_io_out_complexDecodedInsts_1_bits_exceptionVec_17), .io_out_complexDecodedInsts_1_bits_exceptionVec_18(g_io_out_complexDecodedInsts_1_bits_exceptionVec_18),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_19(g_io_out_complexDecodedInsts_1_bits_exceptionVec_19), .io_out_complexDecodedInsts_1_bits_exceptionVec_20(g_io_out_complexDecodedInsts_1_bits_exceptionVec_20), .io_out_complexDecodedInsts_1_bits_exceptionVec_21(g_io_out_complexDecodedInsts_1_bits_exceptionVec_21),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_22(g_io_out_complexDecodedInsts_1_bits_exceptionVec_22), .io_out_complexDecodedInsts_1_bits_exceptionVec_23(g_io_out_complexDecodedInsts_1_bits_exceptionVec_23), .io_out_complexDecodedInsts_1_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_1_bits_isFetchMalAddr),
    .io_out_complexDecodedInsts_1_bits_trigger(g_io_out_complexDecodedInsts_1_bits_trigger), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_1_bits_pred_taken(g_io_out_complexDecodedInsts_1_bits_pred_taken), .io_out_complexDecodedInsts_1_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_1_bits_crossPageIPFFix), .io_out_complexDecodedInsts_1_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_1_bits_ftqPtr_flag),
    .io_out_complexDecodedInsts_1_bits_ftqPtr_value(g_io_out_complexDecodedInsts_1_bits_ftqPtr_value), .io_out_complexDecodedInsts_1_bits_ftqOffset(g_io_out_complexDecodedInsts_1_bits_ftqOffset), .io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_1_bits_srcType_0(g_io_out_complexDecodedInsts_1_bits_srcType_0), .io_out_complexDecodedInsts_1_bits_srcType_1(g_io_out_complexDecodedInsts_1_bits_srcType_1), .io_out_complexDecodedInsts_1_bits_srcType_2(g_io_out_complexDecodedInsts_1_bits_srcType_2),
    .io_out_complexDecodedInsts_1_bits_srcType_3(g_io_out_complexDecodedInsts_1_bits_srcType_3), .io_out_complexDecodedInsts_1_bits_srcType_4(g_io_out_complexDecodedInsts_1_bits_srcType_4), .io_out_complexDecodedInsts_1_bits_lsrc_0(g_io_out_complexDecodedInsts_1_bits_lsrc_0),
    .io_out_complexDecodedInsts_1_bits_lsrc_1(g_io_out_complexDecodedInsts_1_bits_lsrc_1), .io_out_complexDecodedInsts_1_bits_lsrc_2(g_io_out_complexDecodedInsts_1_bits_lsrc_2), .io_out_complexDecodedInsts_1_bits_ldest(g_io_out_complexDecodedInsts_1_bits_ldest),
    .io_out_complexDecodedInsts_1_bits_fuType(g_io_out_complexDecodedInsts_1_bits_fuType), .io_out_complexDecodedInsts_1_bits_fuOpType(g_io_out_complexDecodedInsts_1_bits_fuOpType), .io_out_complexDecodedInsts_1_bits_rfWen(g_io_out_complexDecodedInsts_1_bits_rfWen),
    .io_out_complexDecodedInsts_1_bits_fpWen(g_io_out_complexDecodedInsts_1_bits_fpWen), .io_out_complexDecodedInsts_1_bits_vecWen(g_io_out_complexDecodedInsts_1_bits_vecWen), .io_out_complexDecodedInsts_1_bits_vlWen(g_io_out_complexDecodedInsts_1_bits_vlWen),
    .io_out_complexDecodedInsts_1_bits_isXSTrap(g_io_out_complexDecodedInsts_1_bits_isXSTrap), .io_out_complexDecodedInsts_1_bits_waitForward(g_io_out_complexDecodedInsts_1_bits_waitForward), .io_out_complexDecodedInsts_1_bits_blockBackward(g_io_out_complexDecodedInsts_1_bits_blockBackward),
    .io_out_complexDecodedInsts_1_bits_flushPipe(g_io_out_complexDecodedInsts_1_bits_flushPipe), .io_out_complexDecodedInsts_1_bits_canRobCompress(g_io_out_complexDecodedInsts_1_bits_canRobCompress), .io_out_complexDecodedInsts_1_bits_selImm(g_io_out_complexDecodedInsts_1_bits_selImm),
    .io_out_complexDecodedInsts_1_bits_imm(g_io_out_complexDecodedInsts_1_bits_imm), .io_out_complexDecodedInsts_1_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_1_bits_fpu_wflags(g_io_out_complexDecodedInsts_1_bits_fpu_wflags),
    .io_out_complexDecodedInsts_1_bits_fpu_typ(g_io_out_complexDecodedInsts_1_bits_fpu_typ), .io_out_complexDecodedInsts_1_bits_fpu_fmt(g_io_out_complexDecodedInsts_1_bits_fpu_fmt), .io_out_complexDecodedInsts_1_bits_fpu_rm(g_io_out_complexDecodedInsts_1_bits_fpu_rm),
    .io_out_complexDecodedInsts_1_bits_vpu_vill(g_io_out_complexDecodedInsts_1_bits_vpu_vill), .io_out_complexDecodedInsts_1_bits_vpu_vma(g_io_out_complexDecodedInsts_1_bits_vpu_vma), .io_out_complexDecodedInsts_1_bits_vpu_vta(g_io_out_complexDecodedInsts_1_bits_vpu_vta),
    .io_out_complexDecodedInsts_1_bits_vpu_vsew(g_io_out_complexDecodedInsts_1_bits_vpu_vsew), .io_out_complexDecodedInsts_1_bits_vpu_vlmul(g_io_out_complexDecodedInsts_1_bits_vpu_vlmul), .io_out_complexDecodedInsts_1_bits_vpu_specVill(g_io_out_complexDecodedInsts_1_bits_vpu_specVill),
    .io_out_complexDecodedInsts_1_bits_vpu_specVma(g_io_out_complexDecodedInsts_1_bits_vpu_specVma), .io_out_complexDecodedInsts_1_bits_vpu_specVta(g_io_out_complexDecodedInsts_1_bits_vpu_specVta), .io_out_complexDecodedInsts_1_bits_vpu_specVsew(g_io_out_complexDecodedInsts_1_bits_vpu_specVsew),
    .io_out_complexDecodedInsts_1_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_1_bits_vpu_specVlmul), .io_out_complexDecodedInsts_1_bits_vpu_vm(g_io_out_complexDecodedInsts_1_bits_vpu_vm), .io_out_complexDecodedInsts_1_bits_vpu_vstart(g_io_out_complexDecodedInsts_1_bits_vpu_vstart),
    .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_1_bits_vpu_nf(g_io_out_complexDecodedInsts_1_bits_vpu_nf), .io_out_complexDecodedInsts_1_bits_vpu_veew(g_io_out_complexDecodedInsts_1_bits_vpu_veew), .io_out_complexDecodedInsts_1_bits_vpu_isReverse(g_io_out_complexDecodedInsts_1_bits_vpu_isReverse),
    .io_out_complexDecodedInsts_1_bits_vpu_isExt(g_io_out_complexDecodedInsts_1_bits_vpu_isExt), .io_out_complexDecodedInsts_1_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_1_bits_vpu_isNarrow), .io_out_complexDecodedInsts_1_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_1_bits_vpu_isDstMask),
    .io_out_complexDecodedInsts_1_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_1_bits_vpu_isOpMask), .io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd),
    .io_out_complexDecodedInsts_1_bits_vpu_isVleff(g_io_out_complexDecodedInsts_1_bits_vpu_isVleff), .io_out_complexDecodedInsts_1_bits_vlsInstr(g_io_out_complexDecodedInsts_1_bits_vlsInstr), .io_out_complexDecodedInsts_1_bits_wfflags(g_io_out_complexDecodedInsts_1_bits_wfflags),
    .io_out_complexDecodedInsts_1_bits_isMove(g_io_out_complexDecodedInsts_1_bits_isMove), .io_out_complexDecodedInsts_1_bits_uopIdx(g_io_out_complexDecodedInsts_1_bits_uopIdx), .io_out_complexDecodedInsts_1_bits_uopSplitType(g_io_out_complexDecodedInsts_1_bits_uopSplitType),
    .io_out_complexDecodedInsts_1_bits_isVset(g_io_out_complexDecodedInsts_1_bits_isVset), .io_out_complexDecodedInsts_1_bits_lastUop(g_io_out_complexDecodedInsts_1_bits_lastUop), .io_out_complexDecodedInsts_1_bits_numUops(g_io_out_complexDecodedInsts_1_bits_numUops),
    .io_out_complexDecodedInsts_1_bits_numWB(g_io_out_complexDecodedInsts_1_bits_numWB), .io_out_complexDecodedInsts_1_bits_commitType(g_io_out_complexDecodedInsts_1_bits_commitType), .io_out_complexDecodedInsts_1_bits_debug_fuType(g_io_out_complexDecodedInsts_1_bits_debug_fuType),
    .io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_2_valid(g_io_out_complexDecodedInsts_2_valid),
    .io_out_complexDecodedInsts_2_bits_instr(g_io_out_complexDecodedInsts_2_bits_instr), .io_out_complexDecodedInsts_2_bits_pc(g_io_out_complexDecodedInsts_2_bits_pc), .io_out_complexDecodedInsts_2_bits_foldpc(g_io_out_complexDecodedInsts_2_bits_foldpc),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_0(g_io_out_complexDecodedInsts_2_bits_exceptionVec_0), .io_out_complexDecodedInsts_2_bits_exceptionVec_1(g_io_out_complexDecodedInsts_2_bits_exceptionVec_1), .io_out_complexDecodedInsts_2_bits_exceptionVec_2(g_io_out_complexDecodedInsts_2_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_3(g_io_out_complexDecodedInsts_2_bits_exceptionVec_3), .io_out_complexDecodedInsts_2_bits_exceptionVec_4(g_io_out_complexDecodedInsts_2_bits_exceptionVec_4), .io_out_complexDecodedInsts_2_bits_exceptionVec_5(g_io_out_complexDecodedInsts_2_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_6(g_io_out_complexDecodedInsts_2_bits_exceptionVec_6), .io_out_complexDecodedInsts_2_bits_exceptionVec_7(g_io_out_complexDecodedInsts_2_bits_exceptionVec_7), .io_out_complexDecodedInsts_2_bits_exceptionVec_8(g_io_out_complexDecodedInsts_2_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_9(g_io_out_complexDecodedInsts_2_bits_exceptionVec_9), .io_out_complexDecodedInsts_2_bits_exceptionVec_10(g_io_out_complexDecodedInsts_2_bits_exceptionVec_10), .io_out_complexDecodedInsts_2_bits_exceptionVec_11(g_io_out_complexDecodedInsts_2_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_12(g_io_out_complexDecodedInsts_2_bits_exceptionVec_12), .io_out_complexDecodedInsts_2_bits_exceptionVec_13(g_io_out_complexDecodedInsts_2_bits_exceptionVec_13), .io_out_complexDecodedInsts_2_bits_exceptionVec_14(g_io_out_complexDecodedInsts_2_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_15(g_io_out_complexDecodedInsts_2_bits_exceptionVec_15), .io_out_complexDecodedInsts_2_bits_exceptionVec_16(g_io_out_complexDecodedInsts_2_bits_exceptionVec_16), .io_out_complexDecodedInsts_2_bits_exceptionVec_17(g_io_out_complexDecodedInsts_2_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_18(g_io_out_complexDecodedInsts_2_bits_exceptionVec_18), .io_out_complexDecodedInsts_2_bits_exceptionVec_19(g_io_out_complexDecodedInsts_2_bits_exceptionVec_19), .io_out_complexDecodedInsts_2_bits_exceptionVec_20(g_io_out_complexDecodedInsts_2_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_21(g_io_out_complexDecodedInsts_2_bits_exceptionVec_21), .io_out_complexDecodedInsts_2_bits_exceptionVec_22(g_io_out_complexDecodedInsts_2_bits_exceptionVec_22), .io_out_complexDecodedInsts_2_bits_exceptionVec_23(g_io_out_complexDecodedInsts_2_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_2_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_2_bits_isFetchMalAddr), .io_out_complexDecodedInsts_2_bits_trigger(g_io_out_complexDecodedInsts_2_bits_trigger), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_2_bits_pred_taken(g_io_out_complexDecodedInsts_2_bits_pred_taken), .io_out_complexDecodedInsts_2_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_2_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_2_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_2_bits_ftqPtr_flag), .io_out_complexDecodedInsts_2_bits_ftqPtr_value(g_io_out_complexDecodedInsts_2_bits_ftqPtr_value), .io_out_complexDecodedInsts_2_bits_ftqOffset(g_io_out_complexDecodedInsts_2_bits_ftqOffset),
    .io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_2_bits_srcType_0(g_io_out_complexDecodedInsts_2_bits_srcType_0), .io_out_complexDecodedInsts_2_bits_srcType_1(g_io_out_complexDecodedInsts_2_bits_srcType_1),
    .io_out_complexDecodedInsts_2_bits_srcType_2(g_io_out_complexDecodedInsts_2_bits_srcType_2), .io_out_complexDecodedInsts_2_bits_srcType_3(g_io_out_complexDecodedInsts_2_bits_srcType_3), .io_out_complexDecodedInsts_2_bits_srcType_4(g_io_out_complexDecodedInsts_2_bits_srcType_4),
    .io_out_complexDecodedInsts_2_bits_lsrc_0(g_io_out_complexDecodedInsts_2_bits_lsrc_0), .io_out_complexDecodedInsts_2_bits_lsrc_1(g_io_out_complexDecodedInsts_2_bits_lsrc_1), .io_out_complexDecodedInsts_2_bits_lsrc_2(g_io_out_complexDecodedInsts_2_bits_lsrc_2),
    .io_out_complexDecodedInsts_2_bits_ldest(g_io_out_complexDecodedInsts_2_bits_ldest), .io_out_complexDecodedInsts_2_bits_fuType(g_io_out_complexDecodedInsts_2_bits_fuType), .io_out_complexDecodedInsts_2_bits_fuOpType(g_io_out_complexDecodedInsts_2_bits_fuOpType),
    .io_out_complexDecodedInsts_2_bits_rfWen(g_io_out_complexDecodedInsts_2_bits_rfWen), .io_out_complexDecodedInsts_2_bits_fpWen(g_io_out_complexDecodedInsts_2_bits_fpWen), .io_out_complexDecodedInsts_2_bits_vecWen(g_io_out_complexDecodedInsts_2_bits_vecWen),
    .io_out_complexDecodedInsts_2_bits_vlWen(g_io_out_complexDecodedInsts_2_bits_vlWen), .io_out_complexDecodedInsts_2_bits_isXSTrap(g_io_out_complexDecodedInsts_2_bits_isXSTrap), .io_out_complexDecodedInsts_2_bits_waitForward(g_io_out_complexDecodedInsts_2_bits_waitForward),
    .io_out_complexDecodedInsts_2_bits_blockBackward(g_io_out_complexDecodedInsts_2_bits_blockBackward), .io_out_complexDecodedInsts_2_bits_flushPipe(g_io_out_complexDecodedInsts_2_bits_flushPipe), .io_out_complexDecodedInsts_2_bits_canRobCompress(g_io_out_complexDecodedInsts_2_bits_canRobCompress),
    .io_out_complexDecodedInsts_2_bits_selImm(g_io_out_complexDecodedInsts_2_bits_selImm), .io_out_complexDecodedInsts_2_bits_imm(g_io_out_complexDecodedInsts_2_bits_imm), .io_out_complexDecodedInsts_2_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_2_bits_fpu_wflags(g_io_out_complexDecodedInsts_2_bits_fpu_wflags), .io_out_complexDecodedInsts_2_bits_fpu_typ(g_io_out_complexDecodedInsts_2_bits_fpu_typ), .io_out_complexDecodedInsts_2_bits_fpu_fmt(g_io_out_complexDecodedInsts_2_bits_fpu_fmt),
    .io_out_complexDecodedInsts_2_bits_fpu_rm(g_io_out_complexDecodedInsts_2_bits_fpu_rm), .io_out_complexDecodedInsts_2_bits_vpu_vill(g_io_out_complexDecodedInsts_2_bits_vpu_vill), .io_out_complexDecodedInsts_2_bits_vpu_vma(g_io_out_complexDecodedInsts_2_bits_vpu_vma),
    .io_out_complexDecodedInsts_2_bits_vpu_vta(g_io_out_complexDecodedInsts_2_bits_vpu_vta), .io_out_complexDecodedInsts_2_bits_vpu_vsew(g_io_out_complexDecodedInsts_2_bits_vpu_vsew), .io_out_complexDecodedInsts_2_bits_vpu_vlmul(g_io_out_complexDecodedInsts_2_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_2_bits_vpu_specVill(g_io_out_complexDecodedInsts_2_bits_vpu_specVill), .io_out_complexDecodedInsts_2_bits_vpu_specVma(g_io_out_complexDecodedInsts_2_bits_vpu_specVma), .io_out_complexDecodedInsts_2_bits_vpu_specVta(g_io_out_complexDecodedInsts_2_bits_vpu_specVta),
    .io_out_complexDecodedInsts_2_bits_vpu_specVsew(g_io_out_complexDecodedInsts_2_bits_vpu_specVsew), .io_out_complexDecodedInsts_2_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_2_bits_vpu_specVlmul), .io_out_complexDecodedInsts_2_bits_vpu_vm(g_io_out_complexDecodedInsts_2_bits_vpu_vm),
    .io_out_complexDecodedInsts_2_bits_vpu_vstart(g_io_out_complexDecodedInsts_2_bits_vpu_vstart), .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_2_bits_vpu_nf(g_io_out_complexDecodedInsts_2_bits_vpu_nf), .io_out_complexDecodedInsts_2_bits_vpu_veew(g_io_out_complexDecodedInsts_2_bits_vpu_veew),
    .io_out_complexDecodedInsts_2_bits_vpu_isReverse(g_io_out_complexDecodedInsts_2_bits_vpu_isReverse), .io_out_complexDecodedInsts_2_bits_vpu_isExt(g_io_out_complexDecodedInsts_2_bits_vpu_isExt), .io_out_complexDecodedInsts_2_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_2_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_2_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_2_bits_vpu_isDstMask), .io_out_complexDecodedInsts_2_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_2_bits_vpu_isOpMask), .io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_2_bits_vpu_isVleff(g_io_out_complexDecodedInsts_2_bits_vpu_isVleff), .io_out_complexDecodedInsts_2_bits_vlsInstr(g_io_out_complexDecodedInsts_2_bits_vlsInstr),
    .io_out_complexDecodedInsts_2_bits_wfflags(g_io_out_complexDecodedInsts_2_bits_wfflags), .io_out_complexDecodedInsts_2_bits_isMove(g_io_out_complexDecodedInsts_2_bits_isMove), .io_out_complexDecodedInsts_2_bits_uopIdx(g_io_out_complexDecodedInsts_2_bits_uopIdx),
    .io_out_complexDecodedInsts_2_bits_uopSplitType(g_io_out_complexDecodedInsts_2_bits_uopSplitType), .io_out_complexDecodedInsts_2_bits_isVset(g_io_out_complexDecodedInsts_2_bits_isVset), .io_out_complexDecodedInsts_2_bits_lastUop(g_io_out_complexDecodedInsts_2_bits_lastUop),
    .io_out_complexDecodedInsts_2_bits_numUops(g_io_out_complexDecodedInsts_2_bits_numUops), .io_out_complexDecodedInsts_2_bits_numWB(g_io_out_complexDecodedInsts_2_bits_numWB), .io_out_complexDecodedInsts_2_bits_commitType(g_io_out_complexDecodedInsts_2_bits_commitType),
    .io_out_complexDecodedInsts_2_bits_debug_fuType(g_io_out_complexDecodedInsts_2_bits_debug_fuType), .io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_3_valid(g_io_out_complexDecodedInsts_3_valid), .io_out_complexDecodedInsts_3_bits_instr(g_io_out_complexDecodedInsts_3_bits_instr), .io_out_complexDecodedInsts_3_bits_pc(g_io_out_complexDecodedInsts_3_bits_pc),
    .io_out_complexDecodedInsts_3_bits_foldpc(g_io_out_complexDecodedInsts_3_bits_foldpc), .io_out_complexDecodedInsts_3_bits_exceptionVec_0(g_io_out_complexDecodedInsts_3_bits_exceptionVec_0), .io_out_complexDecodedInsts_3_bits_exceptionVec_1(g_io_out_complexDecodedInsts_3_bits_exceptionVec_1),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_2(g_io_out_complexDecodedInsts_3_bits_exceptionVec_2), .io_out_complexDecodedInsts_3_bits_exceptionVec_3(g_io_out_complexDecodedInsts_3_bits_exceptionVec_3), .io_out_complexDecodedInsts_3_bits_exceptionVec_4(g_io_out_complexDecodedInsts_3_bits_exceptionVec_4),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_5(g_io_out_complexDecodedInsts_3_bits_exceptionVec_5), .io_out_complexDecodedInsts_3_bits_exceptionVec_6(g_io_out_complexDecodedInsts_3_bits_exceptionVec_6), .io_out_complexDecodedInsts_3_bits_exceptionVec_7(g_io_out_complexDecodedInsts_3_bits_exceptionVec_7),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_8(g_io_out_complexDecodedInsts_3_bits_exceptionVec_8), .io_out_complexDecodedInsts_3_bits_exceptionVec_9(g_io_out_complexDecodedInsts_3_bits_exceptionVec_9), .io_out_complexDecodedInsts_3_bits_exceptionVec_10(g_io_out_complexDecodedInsts_3_bits_exceptionVec_10),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_11(g_io_out_complexDecodedInsts_3_bits_exceptionVec_11), .io_out_complexDecodedInsts_3_bits_exceptionVec_12(g_io_out_complexDecodedInsts_3_bits_exceptionVec_12), .io_out_complexDecodedInsts_3_bits_exceptionVec_13(g_io_out_complexDecodedInsts_3_bits_exceptionVec_13),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_14(g_io_out_complexDecodedInsts_3_bits_exceptionVec_14), .io_out_complexDecodedInsts_3_bits_exceptionVec_15(g_io_out_complexDecodedInsts_3_bits_exceptionVec_15), .io_out_complexDecodedInsts_3_bits_exceptionVec_16(g_io_out_complexDecodedInsts_3_bits_exceptionVec_16),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_17(g_io_out_complexDecodedInsts_3_bits_exceptionVec_17), .io_out_complexDecodedInsts_3_bits_exceptionVec_18(g_io_out_complexDecodedInsts_3_bits_exceptionVec_18), .io_out_complexDecodedInsts_3_bits_exceptionVec_19(g_io_out_complexDecodedInsts_3_bits_exceptionVec_19),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_20(g_io_out_complexDecodedInsts_3_bits_exceptionVec_20), .io_out_complexDecodedInsts_3_bits_exceptionVec_21(g_io_out_complexDecodedInsts_3_bits_exceptionVec_21), .io_out_complexDecodedInsts_3_bits_exceptionVec_22(g_io_out_complexDecodedInsts_3_bits_exceptionVec_22),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_23(g_io_out_complexDecodedInsts_3_bits_exceptionVec_23), .io_out_complexDecodedInsts_3_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_3_bits_isFetchMalAddr), .io_out_complexDecodedInsts_3_bits_trigger(g_io_out_complexDecodedInsts_3_bits_trigger),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_3_bits_pred_taken(g_io_out_complexDecodedInsts_3_bits_pred_taken),
    .io_out_complexDecodedInsts_3_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_3_bits_crossPageIPFFix), .io_out_complexDecodedInsts_3_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_3_bits_ftqPtr_flag), .io_out_complexDecodedInsts_3_bits_ftqPtr_value(g_io_out_complexDecodedInsts_3_bits_ftqPtr_value),
    .io_out_complexDecodedInsts_3_bits_ftqOffset(g_io_out_complexDecodedInsts_3_bits_ftqOffset), .io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_3_bits_srcType_0(g_io_out_complexDecodedInsts_3_bits_srcType_0),
    .io_out_complexDecodedInsts_3_bits_srcType_1(g_io_out_complexDecodedInsts_3_bits_srcType_1), .io_out_complexDecodedInsts_3_bits_srcType_2(g_io_out_complexDecodedInsts_3_bits_srcType_2), .io_out_complexDecodedInsts_3_bits_srcType_3(g_io_out_complexDecodedInsts_3_bits_srcType_3),
    .io_out_complexDecodedInsts_3_bits_srcType_4(g_io_out_complexDecodedInsts_3_bits_srcType_4), .io_out_complexDecodedInsts_3_bits_lsrc_0(g_io_out_complexDecodedInsts_3_bits_lsrc_0), .io_out_complexDecodedInsts_3_bits_lsrc_1(g_io_out_complexDecodedInsts_3_bits_lsrc_1),
    .io_out_complexDecodedInsts_3_bits_lsrc_2(g_io_out_complexDecodedInsts_3_bits_lsrc_2), .io_out_complexDecodedInsts_3_bits_ldest(g_io_out_complexDecodedInsts_3_bits_ldest), .io_out_complexDecodedInsts_3_bits_fuType(g_io_out_complexDecodedInsts_3_bits_fuType),
    .io_out_complexDecodedInsts_3_bits_fuOpType(g_io_out_complexDecodedInsts_3_bits_fuOpType), .io_out_complexDecodedInsts_3_bits_rfWen(g_io_out_complexDecodedInsts_3_bits_rfWen), .io_out_complexDecodedInsts_3_bits_fpWen(g_io_out_complexDecodedInsts_3_bits_fpWen),
    .io_out_complexDecodedInsts_3_bits_vecWen(g_io_out_complexDecodedInsts_3_bits_vecWen), .io_out_complexDecodedInsts_3_bits_vlWen(g_io_out_complexDecodedInsts_3_bits_vlWen), .io_out_complexDecodedInsts_3_bits_isXSTrap(g_io_out_complexDecodedInsts_3_bits_isXSTrap),
    .io_out_complexDecodedInsts_3_bits_waitForward(g_io_out_complexDecodedInsts_3_bits_waitForward), .io_out_complexDecodedInsts_3_bits_blockBackward(g_io_out_complexDecodedInsts_3_bits_blockBackward), .io_out_complexDecodedInsts_3_bits_flushPipe(g_io_out_complexDecodedInsts_3_bits_flushPipe),
    .io_out_complexDecodedInsts_3_bits_canRobCompress(g_io_out_complexDecodedInsts_3_bits_canRobCompress), .io_out_complexDecodedInsts_3_bits_selImm(g_io_out_complexDecodedInsts_3_bits_selImm), .io_out_complexDecodedInsts_3_bits_imm(g_io_out_complexDecodedInsts_3_bits_imm),
    .io_out_complexDecodedInsts_3_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_3_bits_fpu_wflags(g_io_out_complexDecodedInsts_3_bits_fpu_wflags), .io_out_complexDecodedInsts_3_bits_fpu_typ(g_io_out_complexDecodedInsts_3_bits_fpu_typ),
    .io_out_complexDecodedInsts_3_bits_fpu_fmt(g_io_out_complexDecodedInsts_3_bits_fpu_fmt), .io_out_complexDecodedInsts_3_bits_fpu_rm(g_io_out_complexDecodedInsts_3_bits_fpu_rm), .io_out_complexDecodedInsts_3_bits_vpu_vill(g_io_out_complexDecodedInsts_3_bits_vpu_vill),
    .io_out_complexDecodedInsts_3_bits_vpu_vma(g_io_out_complexDecodedInsts_3_bits_vpu_vma), .io_out_complexDecodedInsts_3_bits_vpu_vta(g_io_out_complexDecodedInsts_3_bits_vpu_vta), .io_out_complexDecodedInsts_3_bits_vpu_vsew(g_io_out_complexDecodedInsts_3_bits_vpu_vsew),
    .io_out_complexDecodedInsts_3_bits_vpu_vlmul(g_io_out_complexDecodedInsts_3_bits_vpu_vlmul), .io_out_complexDecodedInsts_3_bits_vpu_specVill(g_io_out_complexDecodedInsts_3_bits_vpu_specVill), .io_out_complexDecodedInsts_3_bits_vpu_specVma(g_io_out_complexDecodedInsts_3_bits_vpu_specVma),
    .io_out_complexDecodedInsts_3_bits_vpu_specVta(g_io_out_complexDecodedInsts_3_bits_vpu_specVta), .io_out_complexDecodedInsts_3_bits_vpu_specVsew(g_io_out_complexDecodedInsts_3_bits_vpu_specVsew), .io_out_complexDecodedInsts_3_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_3_bits_vpu_specVlmul),
    .io_out_complexDecodedInsts_3_bits_vpu_vm(g_io_out_complexDecodedInsts_3_bits_vpu_vm), .io_out_complexDecodedInsts_3_bits_vpu_vstart(g_io_out_complexDecodedInsts_3_bits_vpu_vstart), .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_3_bits_vpu_nf(g_io_out_complexDecodedInsts_3_bits_vpu_nf),
    .io_out_complexDecodedInsts_3_bits_vpu_veew(g_io_out_complexDecodedInsts_3_bits_vpu_veew), .io_out_complexDecodedInsts_3_bits_vpu_isReverse(g_io_out_complexDecodedInsts_3_bits_vpu_isReverse), .io_out_complexDecodedInsts_3_bits_vpu_isExt(g_io_out_complexDecodedInsts_3_bits_vpu_isExt),
    .io_out_complexDecodedInsts_3_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_3_bits_vpu_isNarrow), .io_out_complexDecodedInsts_3_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_3_bits_vpu_isDstMask), .io_out_complexDecodedInsts_3_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_3_bits_vpu_isOpMask),
    .io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_3_bits_vpu_isVleff(g_io_out_complexDecodedInsts_3_bits_vpu_isVleff),
    .io_out_complexDecodedInsts_3_bits_vlsInstr(g_io_out_complexDecodedInsts_3_bits_vlsInstr), .io_out_complexDecodedInsts_3_bits_wfflags(g_io_out_complexDecodedInsts_3_bits_wfflags), .io_out_complexDecodedInsts_3_bits_isMove(g_io_out_complexDecodedInsts_3_bits_isMove),
    .io_out_complexDecodedInsts_3_bits_uopIdx(g_io_out_complexDecodedInsts_3_bits_uopIdx), .io_out_complexDecodedInsts_3_bits_uopSplitType(g_io_out_complexDecodedInsts_3_bits_uopSplitType), .io_out_complexDecodedInsts_3_bits_isVset(g_io_out_complexDecodedInsts_3_bits_isVset),
    .io_out_complexDecodedInsts_3_bits_lastUop(g_io_out_complexDecodedInsts_3_bits_lastUop), .io_out_complexDecodedInsts_3_bits_numUops(g_io_out_complexDecodedInsts_3_bits_numUops), .io_out_complexDecodedInsts_3_bits_numWB(g_io_out_complexDecodedInsts_3_bits_numWB),
    .io_out_complexDecodedInsts_3_bits_commitType(g_io_out_complexDecodedInsts_3_bits_commitType), .io_out_complexDecodedInsts_3_bits_debug_fuType(g_io_out_complexDecodedInsts_3_bits_debug_fuType), .io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_4_valid(g_io_out_complexDecodedInsts_4_valid), .io_out_complexDecodedInsts_4_bits_instr(g_io_out_complexDecodedInsts_4_bits_instr),
    .io_out_complexDecodedInsts_4_bits_pc(g_io_out_complexDecodedInsts_4_bits_pc), .io_out_complexDecodedInsts_4_bits_foldpc(g_io_out_complexDecodedInsts_4_bits_foldpc), .io_out_complexDecodedInsts_4_bits_exceptionVec_0(g_io_out_complexDecodedInsts_4_bits_exceptionVec_0),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_1(g_io_out_complexDecodedInsts_4_bits_exceptionVec_1), .io_out_complexDecodedInsts_4_bits_exceptionVec_2(g_io_out_complexDecodedInsts_4_bits_exceptionVec_2), .io_out_complexDecodedInsts_4_bits_exceptionVec_3(g_io_out_complexDecodedInsts_4_bits_exceptionVec_3),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_4(g_io_out_complexDecodedInsts_4_bits_exceptionVec_4), .io_out_complexDecodedInsts_4_bits_exceptionVec_5(g_io_out_complexDecodedInsts_4_bits_exceptionVec_5), .io_out_complexDecodedInsts_4_bits_exceptionVec_6(g_io_out_complexDecodedInsts_4_bits_exceptionVec_6),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_7(g_io_out_complexDecodedInsts_4_bits_exceptionVec_7), .io_out_complexDecodedInsts_4_bits_exceptionVec_8(g_io_out_complexDecodedInsts_4_bits_exceptionVec_8), .io_out_complexDecodedInsts_4_bits_exceptionVec_9(g_io_out_complexDecodedInsts_4_bits_exceptionVec_9),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_10(g_io_out_complexDecodedInsts_4_bits_exceptionVec_10), .io_out_complexDecodedInsts_4_bits_exceptionVec_11(g_io_out_complexDecodedInsts_4_bits_exceptionVec_11), .io_out_complexDecodedInsts_4_bits_exceptionVec_12(g_io_out_complexDecodedInsts_4_bits_exceptionVec_12),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_13(g_io_out_complexDecodedInsts_4_bits_exceptionVec_13), .io_out_complexDecodedInsts_4_bits_exceptionVec_14(g_io_out_complexDecodedInsts_4_bits_exceptionVec_14), .io_out_complexDecodedInsts_4_bits_exceptionVec_15(g_io_out_complexDecodedInsts_4_bits_exceptionVec_15),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_16(g_io_out_complexDecodedInsts_4_bits_exceptionVec_16), .io_out_complexDecodedInsts_4_bits_exceptionVec_17(g_io_out_complexDecodedInsts_4_bits_exceptionVec_17), .io_out_complexDecodedInsts_4_bits_exceptionVec_18(g_io_out_complexDecodedInsts_4_bits_exceptionVec_18),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_19(g_io_out_complexDecodedInsts_4_bits_exceptionVec_19), .io_out_complexDecodedInsts_4_bits_exceptionVec_20(g_io_out_complexDecodedInsts_4_bits_exceptionVec_20), .io_out_complexDecodedInsts_4_bits_exceptionVec_21(g_io_out_complexDecodedInsts_4_bits_exceptionVec_21),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_22(g_io_out_complexDecodedInsts_4_bits_exceptionVec_22), .io_out_complexDecodedInsts_4_bits_exceptionVec_23(g_io_out_complexDecodedInsts_4_bits_exceptionVec_23), .io_out_complexDecodedInsts_4_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_4_bits_isFetchMalAddr),
    .io_out_complexDecodedInsts_4_bits_trigger(g_io_out_complexDecodedInsts_4_bits_trigger), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_4_bits_pred_taken(g_io_out_complexDecodedInsts_4_bits_pred_taken), .io_out_complexDecodedInsts_4_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_4_bits_crossPageIPFFix), .io_out_complexDecodedInsts_4_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_4_bits_ftqPtr_flag),
    .io_out_complexDecodedInsts_4_bits_ftqPtr_value(g_io_out_complexDecodedInsts_4_bits_ftqPtr_value), .io_out_complexDecodedInsts_4_bits_ftqOffset(g_io_out_complexDecodedInsts_4_bits_ftqOffset), .io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_4_bits_srcType_0(g_io_out_complexDecodedInsts_4_bits_srcType_0), .io_out_complexDecodedInsts_4_bits_srcType_1(g_io_out_complexDecodedInsts_4_bits_srcType_1), .io_out_complexDecodedInsts_4_bits_srcType_2(g_io_out_complexDecodedInsts_4_bits_srcType_2),
    .io_out_complexDecodedInsts_4_bits_srcType_3(g_io_out_complexDecodedInsts_4_bits_srcType_3), .io_out_complexDecodedInsts_4_bits_srcType_4(g_io_out_complexDecodedInsts_4_bits_srcType_4), .io_out_complexDecodedInsts_4_bits_lsrc_0(g_io_out_complexDecodedInsts_4_bits_lsrc_0),
    .io_out_complexDecodedInsts_4_bits_lsrc_1(g_io_out_complexDecodedInsts_4_bits_lsrc_1), .io_out_complexDecodedInsts_4_bits_lsrc_2(g_io_out_complexDecodedInsts_4_bits_lsrc_2), .io_out_complexDecodedInsts_4_bits_ldest(g_io_out_complexDecodedInsts_4_bits_ldest),
    .io_out_complexDecodedInsts_4_bits_fuType(g_io_out_complexDecodedInsts_4_bits_fuType), .io_out_complexDecodedInsts_4_bits_fuOpType(g_io_out_complexDecodedInsts_4_bits_fuOpType), .io_out_complexDecodedInsts_4_bits_rfWen(g_io_out_complexDecodedInsts_4_bits_rfWen),
    .io_out_complexDecodedInsts_4_bits_fpWen(g_io_out_complexDecodedInsts_4_bits_fpWen), .io_out_complexDecodedInsts_4_bits_vecWen(g_io_out_complexDecodedInsts_4_bits_vecWen), .io_out_complexDecodedInsts_4_bits_vlWen(g_io_out_complexDecodedInsts_4_bits_vlWen),
    .io_out_complexDecodedInsts_4_bits_isXSTrap(g_io_out_complexDecodedInsts_4_bits_isXSTrap), .io_out_complexDecodedInsts_4_bits_waitForward(g_io_out_complexDecodedInsts_4_bits_waitForward), .io_out_complexDecodedInsts_4_bits_blockBackward(g_io_out_complexDecodedInsts_4_bits_blockBackward),
    .io_out_complexDecodedInsts_4_bits_flushPipe(g_io_out_complexDecodedInsts_4_bits_flushPipe), .io_out_complexDecodedInsts_4_bits_canRobCompress(g_io_out_complexDecodedInsts_4_bits_canRobCompress), .io_out_complexDecodedInsts_4_bits_selImm(g_io_out_complexDecodedInsts_4_bits_selImm),
    .io_out_complexDecodedInsts_4_bits_imm(g_io_out_complexDecodedInsts_4_bits_imm), .io_out_complexDecodedInsts_4_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_4_bits_fpu_wflags(g_io_out_complexDecodedInsts_4_bits_fpu_wflags),
    .io_out_complexDecodedInsts_4_bits_fpu_typ(g_io_out_complexDecodedInsts_4_bits_fpu_typ), .io_out_complexDecodedInsts_4_bits_fpu_fmt(g_io_out_complexDecodedInsts_4_bits_fpu_fmt), .io_out_complexDecodedInsts_4_bits_fpu_rm(g_io_out_complexDecodedInsts_4_bits_fpu_rm),
    .io_out_complexDecodedInsts_4_bits_vpu_vill(g_io_out_complexDecodedInsts_4_bits_vpu_vill), .io_out_complexDecodedInsts_4_bits_vpu_vma(g_io_out_complexDecodedInsts_4_bits_vpu_vma), .io_out_complexDecodedInsts_4_bits_vpu_vta(g_io_out_complexDecodedInsts_4_bits_vpu_vta),
    .io_out_complexDecodedInsts_4_bits_vpu_vsew(g_io_out_complexDecodedInsts_4_bits_vpu_vsew), .io_out_complexDecodedInsts_4_bits_vpu_vlmul(g_io_out_complexDecodedInsts_4_bits_vpu_vlmul), .io_out_complexDecodedInsts_4_bits_vpu_specVill(g_io_out_complexDecodedInsts_4_bits_vpu_specVill),
    .io_out_complexDecodedInsts_4_bits_vpu_specVma(g_io_out_complexDecodedInsts_4_bits_vpu_specVma), .io_out_complexDecodedInsts_4_bits_vpu_specVta(g_io_out_complexDecodedInsts_4_bits_vpu_specVta), .io_out_complexDecodedInsts_4_bits_vpu_specVsew(g_io_out_complexDecodedInsts_4_bits_vpu_specVsew),
    .io_out_complexDecodedInsts_4_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_4_bits_vpu_specVlmul), .io_out_complexDecodedInsts_4_bits_vpu_vm(g_io_out_complexDecodedInsts_4_bits_vpu_vm), .io_out_complexDecodedInsts_4_bits_vpu_vstart(g_io_out_complexDecodedInsts_4_bits_vpu_vstart),
    .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_4_bits_vpu_nf(g_io_out_complexDecodedInsts_4_bits_vpu_nf), .io_out_complexDecodedInsts_4_bits_vpu_veew(g_io_out_complexDecodedInsts_4_bits_vpu_veew), .io_out_complexDecodedInsts_4_bits_vpu_isReverse(g_io_out_complexDecodedInsts_4_bits_vpu_isReverse),
    .io_out_complexDecodedInsts_4_bits_vpu_isExt(g_io_out_complexDecodedInsts_4_bits_vpu_isExt), .io_out_complexDecodedInsts_4_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_4_bits_vpu_isNarrow), .io_out_complexDecodedInsts_4_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_4_bits_vpu_isDstMask),
    .io_out_complexDecodedInsts_4_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_4_bits_vpu_isOpMask), .io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd),
    .io_out_complexDecodedInsts_4_bits_vpu_isVleff(g_io_out_complexDecodedInsts_4_bits_vpu_isVleff), .io_out_complexDecodedInsts_4_bits_vlsInstr(g_io_out_complexDecodedInsts_4_bits_vlsInstr), .io_out_complexDecodedInsts_4_bits_wfflags(g_io_out_complexDecodedInsts_4_bits_wfflags),
    .io_out_complexDecodedInsts_4_bits_isMove(g_io_out_complexDecodedInsts_4_bits_isMove), .io_out_complexDecodedInsts_4_bits_uopIdx(g_io_out_complexDecodedInsts_4_bits_uopIdx), .io_out_complexDecodedInsts_4_bits_uopSplitType(g_io_out_complexDecodedInsts_4_bits_uopSplitType),
    .io_out_complexDecodedInsts_4_bits_isVset(g_io_out_complexDecodedInsts_4_bits_isVset), .io_out_complexDecodedInsts_4_bits_lastUop(g_io_out_complexDecodedInsts_4_bits_lastUop), .io_out_complexDecodedInsts_4_bits_numUops(g_io_out_complexDecodedInsts_4_bits_numUops),
    .io_out_complexDecodedInsts_4_bits_numWB(g_io_out_complexDecodedInsts_4_bits_numWB), .io_out_complexDecodedInsts_4_bits_commitType(g_io_out_complexDecodedInsts_4_bits_commitType), .io_out_complexDecodedInsts_4_bits_debug_fuType(g_io_out_complexDecodedInsts_4_bits_debug_fuType),
    .io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_5_valid(g_io_out_complexDecodedInsts_5_valid),
    .io_out_complexDecodedInsts_5_bits_instr(g_io_out_complexDecodedInsts_5_bits_instr), .io_out_complexDecodedInsts_5_bits_pc(g_io_out_complexDecodedInsts_5_bits_pc), .io_out_complexDecodedInsts_5_bits_foldpc(g_io_out_complexDecodedInsts_5_bits_foldpc),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_0(g_io_out_complexDecodedInsts_5_bits_exceptionVec_0), .io_out_complexDecodedInsts_5_bits_exceptionVec_1(g_io_out_complexDecodedInsts_5_bits_exceptionVec_1), .io_out_complexDecodedInsts_5_bits_exceptionVec_2(g_io_out_complexDecodedInsts_5_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_3(g_io_out_complexDecodedInsts_5_bits_exceptionVec_3), .io_out_complexDecodedInsts_5_bits_exceptionVec_4(g_io_out_complexDecodedInsts_5_bits_exceptionVec_4), .io_out_complexDecodedInsts_5_bits_exceptionVec_5(g_io_out_complexDecodedInsts_5_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_6(g_io_out_complexDecodedInsts_5_bits_exceptionVec_6), .io_out_complexDecodedInsts_5_bits_exceptionVec_7(g_io_out_complexDecodedInsts_5_bits_exceptionVec_7), .io_out_complexDecodedInsts_5_bits_exceptionVec_8(g_io_out_complexDecodedInsts_5_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_9(g_io_out_complexDecodedInsts_5_bits_exceptionVec_9), .io_out_complexDecodedInsts_5_bits_exceptionVec_10(g_io_out_complexDecodedInsts_5_bits_exceptionVec_10), .io_out_complexDecodedInsts_5_bits_exceptionVec_11(g_io_out_complexDecodedInsts_5_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_12(g_io_out_complexDecodedInsts_5_bits_exceptionVec_12), .io_out_complexDecodedInsts_5_bits_exceptionVec_13(g_io_out_complexDecodedInsts_5_bits_exceptionVec_13), .io_out_complexDecodedInsts_5_bits_exceptionVec_14(g_io_out_complexDecodedInsts_5_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_15(g_io_out_complexDecodedInsts_5_bits_exceptionVec_15), .io_out_complexDecodedInsts_5_bits_exceptionVec_16(g_io_out_complexDecodedInsts_5_bits_exceptionVec_16), .io_out_complexDecodedInsts_5_bits_exceptionVec_17(g_io_out_complexDecodedInsts_5_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_18(g_io_out_complexDecodedInsts_5_bits_exceptionVec_18), .io_out_complexDecodedInsts_5_bits_exceptionVec_19(g_io_out_complexDecodedInsts_5_bits_exceptionVec_19), .io_out_complexDecodedInsts_5_bits_exceptionVec_20(g_io_out_complexDecodedInsts_5_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_21(g_io_out_complexDecodedInsts_5_bits_exceptionVec_21), .io_out_complexDecodedInsts_5_bits_exceptionVec_22(g_io_out_complexDecodedInsts_5_bits_exceptionVec_22), .io_out_complexDecodedInsts_5_bits_exceptionVec_23(g_io_out_complexDecodedInsts_5_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_5_bits_isFetchMalAddr(g_io_out_complexDecodedInsts_5_bits_isFetchMalAddr), .io_out_complexDecodedInsts_5_bits_trigger(g_io_out_complexDecodedInsts_5_bits_trigger), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid(g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC(g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType(g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall(g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet(g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_5_bits_pred_taken(g_io_out_complexDecodedInsts_5_bits_pred_taken), .io_out_complexDecodedInsts_5_bits_crossPageIPFFix(g_io_out_complexDecodedInsts_5_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_5_bits_ftqPtr_flag(g_io_out_complexDecodedInsts_5_bits_ftqPtr_flag), .io_out_complexDecodedInsts_5_bits_ftqPtr_value(g_io_out_complexDecodedInsts_5_bits_ftqPtr_value), .io_out_complexDecodedInsts_5_bits_ftqOffset(g_io_out_complexDecodedInsts_5_bits_ftqOffset),
    .io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault(g_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_5_bits_srcType_0(g_io_out_complexDecodedInsts_5_bits_srcType_0), .io_out_complexDecodedInsts_5_bits_srcType_1(g_io_out_complexDecodedInsts_5_bits_srcType_1),
    .io_out_complexDecodedInsts_5_bits_srcType_2(g_io_out_complexDecodedInsts_5_bits_srcType_2), .io_out_complexDecodedInsts_5_bits_srcType_3(g_io_out_complexDecodedInsts_5_bits_srcType_3), .io_out_complexDecodedInsts_5_bits_srcType_4(g_io_out_complexDecodedInsts_5_bits_srcType_4),
    .io_out_complexDecodedInsts_5_bits_lsrc_0(g_io_out_complexDecodedInsts_5_bits_lsrc_0), .io_out_complexDecodedInsts_5_bits_lsrc_1(g_io_out_complexDecodedInsts_5_bits_lsrc_1), .io_out_complexDecodedInsts_5_bits_lsrc_2(g_io_out_complexDecodedInsts_5_bits_lsrc_2),
    .io_out_complexDecodedInsts_5_bits_ldest(g_io_out_complexDecodedInsts_5_bits_ldest), .io_out_complexDecodedInsts_5_bits_fuType(g_io_out_complexDecodedInsts_5_bits_fuType), .io_out_complexDecodedInsts_5_bits_fuOpType(g_io_out_complexDecodedInsts_5_bits_fuOpType),
    .io_out_complexDecodedInsts_5_bits_rfWen(g_io_out_complexDecodedInsts_5_bits_rfWen), .io_out_complexDecodedInsts_5_bits_fpWen(g_io_out_complexDecodedInsts_5_bits_fpWen), .io_out_complexDecodedInsts_5_bits_vecWen(g_io_out_complexDecodedInsts_5_bits_vecWen),
    .io_out_complexDecodedInsts_5_bits_vlWen(g_io_out_complexDecodedInsts_5_bits_vlWen), .io_out_complexDecodedInsts_5_bits_isXSTrap(g_io_out_complexDecodedInsts_5_bits_isXSTrap), .io_out_complexDecodedInsts_5_bits_waitForward(g_io_out_complexDecodedInsts_5_bits_waitForward),
    .io_out_complexDecodedInsts_5_bits_blockBackward(g_io_out_complexDecodedInsts_5_bits_blockBackward), .io_out_complexDecodedInsts_5_bits_flushPipe(g_io_out_complexDecodedInsts_5_bits_flushPipe), .io_out_complexDecodedInsts_5_bits_canRobCompress(g_io_out_complexDecodedInsts_5_bits_canRobCompress),
    .io_out_complexDecodedInsts_5_bits_selImm(g_io_out_complexDecodedInsts_5_bits_selImm), .io_out_complexDecodedInsts_5_bits_imm(g_io_out_complexDecodedInsts_5_bits_imm), .io_out_complexDecodedInsts_5_bits_fpu_typeTagOut(g_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_5_bits_fpu_wflags(g_io_out_complexDecodedInsts_5_bits_fpu_wflags), .io_out_complexDecodedInsts_5_bits_fpu_typ(g_io_out_complexDecodedInsts_5_bits_fpu_typ), .io_out_complexDecodedInsts_5_bits_fpu_fmt(g_io_out_complexDecodedInsts_5_bits_fpu_fmt),
    .io_out_complexDecodedInsts_5_bits_fpu_rm(g_io_out_complexDecodedInsts_5_bits_fpu_rm), .io_out_complexDecodedInsts_5_bits_vpu_vill(g_io_out_complexDecodedInsts_5_bits_vpu_vill), .io_out_complexDecodedInsts_5_bits_vpu_vma(g_io_out_complexDecodedInsts_5_bits_vpu_vma),
    .io_out_complexDecodedInsts_5_bits_vpu_vta(g_io_out_complexDecodedInsts_5_bits_vpu_vta), .io_out_complexDecodedInsts_5_bits_vpu_vsew(g_io_out_complexDecodedInsts_5_bits_vpu_vsew), .io_out_complexDecodedInsts_5_bits_vpu_vlmul(g_io_out_complexDecodedInsts_5_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_5_bits_vpu_specVill(g_io_out_complexDecodedInsts_5_bits_vpu_specVill), .io_out_complexDecodedInsts_5_bits_vpu_specVma(g_io_out_complexDecodedInsts_5_bits_vpu_specVma), .io_out_complexDecodedInsts_5_bits_vpu_specVta(g_io_out_complexDecodedInsts_5_bits_vpu_specVta),
    .io_out_complexDecodedInsts_5_bits_vpu_specVsew(g_io_out_complexDecodedInsts_5_bits_vpu_specVsew), .io_out_complexDecodedInsts_5_bits_vpu_specVlmul(g_io_out_complexDecodedInsts_5_bits_vpu_specVlmul), .io_out_complexDecodedInsts_5_bits_vpu_vm(g_io_out_complexDecodedInsts_5_bits_vpu_vm),
    .io_out_complexDecodedInsts_5_bits_vpu_vstart(g_io_out_complexDecodedInsts_5_bits_vpu_vstart), .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2(g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4(g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8(g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_5_bits_vpu_nf(g_io_out_complexDecodedInsts_5_bits_vpu_nf), .io_out_complexDecodedInsts_5_bits_vpu_veew(g_io_out_complexDecodedInsts_5_bits_vpu_veew),
    .io_out_complexDecodedInsts_5_bits_vpu_isReverse(g_io_out_complexDecodedInsts_5_bits_vpu_isReverse), .io_out_complexDecodedInsts_5_bits_vpu_isExt(g_io_out_complexDecodedInsts_5_bits_vpu_isExt), .io_out_complexDecodedInsts_5_bits_vpu_isNarrow(g_io_out_complexDecodedInsts_5_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_5_bits_vpu_isDstMask(g_io_out_complexDecodedInsts_5_bits_vpu_isDstMask), .io_out_complexDecodedInsts_5_bits_vpu_isOpMask(g_io_out_complexDecodedInsts_5_bits_vpu_isOpMask), .io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd(g_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd(g_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_5_bits_vpu_isVleff(g_io_out_complexDecodedInsts_5_bits_vpu_isVleff), .io_out_complexDecodedInsts_5_bits_vlsInstr(g_io_out_complexDecodedInsts_5_bits_vlsInstr),
    .io_out_complexDecodedInsts_5_bits_wfflags(g_io_out_complexDecodedInsts_5_bits_wfflags), .io_out_complexDecodedInsts_5_bits_isMove(g_io_out_complexDecodedInsts_5_bits_isMove), .io_out_complexDecodedInsts_5_bits_uopIdx(g_io_out_complexDecodedInsts_5_bits_uopIdx),
    .io_out_complexDecodedInsts_5_bits_uopSplitType(g_io_out_complexDecodedInsts_5_bits_uopSplitType), .io_out_complexDecodedInsts_5_bits_isVset(g_io_out_complexDecodedInsts_5_bits_isVset), .io_out_complexDecodedInsts_5_bits_lastUop(g_io_out_complexDecodedInsts_5_bits_lastUop),
    .io_out_complexDecodedInsts_5_bits_numUops(g_io_out_complexDecodedInsts_5_bits_numUops), .io_out_complexDecodedInsts_5_bits_numWB(g_io_out_complexDecodedInsts_5_bits_numWB), .io_out_complexDecodedInsts_5_bits_commitType(g_io_out_complexDecodedInsts_5_bits_commitType),
    .io_out_complexDecodedInsts_5_bits_debug_fuType(g_io_out_complexDecodedInsts_5_bits_debug_fuType), .io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum(g_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx(g_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx),
    .io_complexNum(g_io_complexNum)
  );

  DecodeUnitComp_xs u_xs (
    .clock(clk), .reset(rst), .io_redirect(io_redirect),
    .io_vtypeBypass_illegal(io_vtypeBypass_illegal), .io_vtypeBypass_vma(io_vtypeBypass_vma), .io_vtypeBypass_vta(io_vtypeBypass_vta),
    .io_vtypeBypass_vsew(io_vtypeBypass_vsew), .io_vtypeBypass_vlmul(io_vtypeBypass_vlmul), .io_in_valid(io_in_valid),
    .io_in_bits_simpleDecodedInst_instr(io_in_bits_simpleDecodedInst_instr), .io_in_bits_simpleDecodedInst_pc(io_in_bits_simpleDecodedInst_pc), .io_in_bits_simpleDecodedInst_foldpc(io_in_bits_simpleDecodedInst_foldpc),
    .io_in_bits_simpleDecodedInst_exceptionVec_0(io_in_bits_simpleDecodedInst_exceptionVec_0), .io_in_bits_simpleDecodedInst_exceptionVec_1(io_in_bits_simpleDecodedInst_exceptionVec_1), .io_in_bits_simpleDecodedInst_exceptionVec_2(io_in_bits_simpleDecodedInst_exceptionVec_2),
    .io_in_bits_simpleDecodedInst_exceptionVec_3(io_in_bits_simpleDecodedInst_exceptionVec_3), .io_in_bits_simpleDecodedInst_exceptionVec_4(io_in_bits_simpleDecodedInst_exceptionVec_4), .io_in_bits_simpleDecodedInst_exceptionVec_5(io_in_bits_simpleDecodedInst_exceptionVec_5),
    .io_in_bits_simpleDecodedInst_exceptionVec_6(io_in_bits_simpleDecodedInst_exceptionVec_6), .io_in_bits_simpleDecodedInst_exceptionVec_7(io_in_bits_simpleDecodedInst_exceptionVec_7), .io_in_bits_simpleDecodedInst_exceptionVec_8(io_in_bits_simpleDecodedInst_exceptionVec_8),
    .io_in_bits_simpleDecodedInst_exceptionVec_9(io_in_bits_simpleDecodedInst_exceptionVec_9), .io_in_bits_simpleDecodedInst_exceptionVec_10(io_in_bits_simpleDecodedInst_exceptionVec_10), .io_in_bits_simpleDecodedInst_exceptionVec_11(io_in_bits_simpleDecodedInst_exceptionVec_11),
    .io_in_bits_simpleDecodedInst_exceptionVec_12(io_in_bits_simpleDecodedInst_exceptionVec_12), .io_in_bits_simpleDecodedInst_exceptionVec_13(io_in_bits_simpleDecodedInst_exceptionVec_13), .io_in_bits_simpleDecodedInst_exceptionVec_14(io_in_bits_simpleDecodedInst_exceptionVec_14),
    .io_in_bits_simpleDecodedInst_exceptionVec_15(io_in_bits_simpleDecodedInst_exceptionVec_15), .io_in_bits_simpleDecodedInst_exceptionVec_16(io_in_bits_simpleDecodedInst_exceptionVec_16), .io_in_bits_simpleDecodedInst_exceptionVec_17(io_in_bits_simpleDecodedInst_exceptionVec_17),
    .io_in_bits_simpleDecodedInst_exceptionVec_18(io_in_bits_simpleDecodedInst_exceptionVec_18), .io_in_bits_simpleDecodedInst_exceptionVec_19(io_in_bits_simpleDecodedInst_exceptionVec_19), .io_in_bits_simpleDecodedInst_exceptionVec_20(io_in_bits_simpleDecodedInst_exceptionVec_20),
    .io_in_bits_simpleDecodedInst_exceptionVec_21(io_in_bits_simpleDecodedInst_exceptionVec_21), .io_in_bits_simpleDecodedInst_exceptionVec_22(io_in_bits_simpleDecodedInst_exceptionVec_22), .io_in_bits_simpleDecodedInst_exceptionVec_23(io_in_bits_simpleDecodedInst_exceptionVec_23),
    .io_in_bits_simpleDecodedInst_isFetchMalAddr(io_in_bits_simpleDecodedInst_isFetchMalAddr), .io_in_bits_simpleDecodedInst_trigger(io_in_bits_simpleDecodedInst_trigger), .io_in_bits_simpleDecodedInst_preDecodeInfo_valid(io_in_bits_simpleDecodedInst_preDecodeInfo_valid),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC(io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC), .io_in_bits_simpleDecodedInst_preDecodeInfo_brType(io_in_bits_simpleDecodedInst_preDecodeInfo_brType), .io_in_bits_simpleDecodedInst_preDecodeInfo_isCall(io_in_bits_simpleDecodedInst_preDecodeInfo_isCall),
    .io_in_bits_simpleDecodedInst_preDecodeInfo_isRet(io_in_bits_simpleDecodedInst_preDecodeInfo_isRet), .io_in_bits_simpleDecodedInst_pred_taken(io_in_bits_simpleDecodedInst_pred_taken), .io_in_bits_simpleDecodedInst_crossPageIPFFix(io_in_bits_simpleDecodedInst_crossPageIPFFix),
    .io_in_bits_simpleDecodedInst_ftqPtr_flag(io_in_bits_simpleDecodedInst_ftqPtr_flag), .io_in_bits_simpleDecodedInst_ftqPtr_value(io_in_bits_simpleDecodedInst_ftqPtr_value), .io_in_bits_simpleDecodedInst_ftqOffset(io_in_bits_simpleDecodedInst_ftqOffset),
    .io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault(io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault), .io_in_bits_simpleDecodedInst_srcType_0(io_in_bits_simpleDecodedInst_srcType_0), .io_in_bits_simpleDecodedInst_srcType_1(io_in_bits_simpleDecodedInst_srcType_1),
    .io_in_bits_simpleDecodedInst_srcType_2(io_in_bits_simpleDecodedInst_srcType_2), .io_in_bits_simpleDecodedInst_srcType_3(io_in_bits_simpleDecodedInst_srcType_3), .io_in_bits_simpleDecodedInst_srcType_4(io_in_bits_simpleDecodedInst_srcType_4),
    .io_in_bits_simpleDecodedInst_lsrc_0(io_in_bits_simpleDecodedInst_lsrc_0), .io_in_bits_simpleDecodedInst_lsrc_1(io_in_bits_simpleDecodedInst_lsrc_1), .io_in_bits_simpleDecodedInst_lsrc_2(io_in_bits_simpleDecodedInst_lsrc_2),
    .io_in_bits_simpleDecodedInst_ldest(io_in_bits_simpleDecodedInst_ldest), .io_in_bits_simpleDecodedInst_fuType(io_in_bits_simpleDecodedInst_fuType), .io_in_bits_simpleDecodedInst_fuOpType(io_in_bits_simpleDecodedInst_fuOpType),
    .io_in_bits_simpleDecodedInst_rfWen(io_in_bits_simpleDecodedInst_rfWen), .io_in_bits_simpleDecodedInst_fpWen(io_in_bits_simpleDecodedInst_fpWen), .io_in_bits_simpleDecodedInst_vecWen(io_in_bits_simpleDecodedInst_vecWen),
    .io_in_bits_simpleDecodedInst_isXSTrap(io_in_bits_simpleDecodedInst_isXSTrap), .io_in_bits_simpleDecodedInst_waitForward(io_in_bits_simpleDecodedInst_waitForward), .io_in_bits_simpleDecodedInst_blockBackward(io_in_bits_simpleDecodedInst_blockBackward),
    .io_in_bits_simpleDecodedInst_flushPipe(io_in_bits_simpleDecodedInst_flushPipe), .io_in_bits_simpleDecodedInst_canRobCompress(io_in_bits_simpleDecodedInst_canRobCompress), .io_in_bits_simpleDecodedInst_selImm(io_in_bits_simpleDecodedInst_selImm),
    .io_in_bits_simpleDecodedInst_imm(io_in_bits_simpleDecodedInst_imm), .io_in_bits_simpleDecodedInst_fpu_typeTagOut(io_in_bits_simpleDecodedInst_fpu_typeTagOut), .io_in_bits_simpleDecodedInst_fpu_wflags(io_in_bits_simpleDecodedInst_fpu_wflags),
    .io_in_bits_simpleDecodedInst_fpu_typ(io_in_bits_simpleDecodedInst_fpu_typ), .io_in_bits_simpleDecodedInst_fpu_fmt(io_in_bits_simpleDecodedInst_fpu_fmt), .io_in_bits_simpleDecodedInst_fpu_rm(io_in_bits_simpleDecodedInst_fpu_rm),
    .io_in_bits_simpleDecodedInst_vpu_vill(io_in_bits_simpleDecodedInst_vpu_vill), .io_in_bits_simpleDecodedInst_vpu_vma(io_in_bits_simpleDecodedInst_vpu_vma), .io_in_bits_simpleDecodedInst_vpu_vta(io_in_bits_simpleDecodedInst_vpu_vta),
    .io_in_bits_simpleDecodedInst_vpu_vsew(io_in_bits_simpleDecodedInst_vpu_vsew), .io_in_bits_simpleDecodedInst_vpu_vlmul(io_in_bits_simpleDecodedInst_vpu_vlmul), .io_in_bits_simpleDecodedInst_vpu_specVill(io_in_bits_simpleDecodedInst_vpu_specVill),
    .io_in_bits_simpleDecodedInst_vpu_specVma(io_in_bits_simpleDecodedInst_vpu_specVma), .io_in_bits_simpleDecodedInst_vpu_specVta(io_in_bits_simpleDecodedInst_vpu_specVta), .io_in_bits_simpleDecodedInst_vpu_specVsew(io_in_bits_simpleDecodedInst_vpu_specVsew),
    .io_in_bits_simpleDecodedInst_vpu_specVlmul(io_in_bits_simpleDecodedInst_vpu_specVlmul), .io_in_bits_simpleDecodedInst_vpu_vm(io_in_bits_simpleDecodedInst_vpu_vm), .io_in_bits_simpleDecodedInst_vpu_vstart(io_in_bits_simpleDecodedInst_vpu_vstart),
    .io_in_bits_simpleDecodedInst_vpu_nf(io_in_bits_simpleDecodedInst_vpu_nf), .io_in_bits_simpleDecodedInst_vpu_veew(io_in_bits_simpleDecodedInst_vpu_veew), .io_in_bits_simpleDecodedInst_vpu_isReverse(io_in_bits_simpleDecodedInst_vpu_isReverse),
    .io_in_bits_simpleDecodedInst_vpu_isExt(io_in_bits_simpleDecodedInst_vpu_isExt), .io_in_bits_simpleDecodedInst_vpu_isNarrow(io_in_bits_simpleDecodedInst_vpu_isNarrow), .io_in_bits_simpleDecodedInst_vpu_isDstMask(io_in_bits_simpleDecodedInst_vpu_isDstMask),
    .io_in_bits_simpleDecodedInst_vpu_isOpMask(io_in_bits_simpleDecodedInst_vpu_isOpMask), .io_in_bits_simpleDecodedInst_vpu_isDependOldVd(io_in_bits_simpleDecodedInst_vpu_isDependOldVd), .io_in_bits_simpleDecodedInst_vpu_isWritePartVd(io_in_bits_simpleDecodedInst_vpu_isWritePartVd),
    .io_in_bits_simpleDecodedInst_vpu_isVleff(io_in_bits_simpleDecodedInst_vpu_isVleff), .io_in_bits_simpleDecodedInst_wfflags(io_in_bits_simpleDecodedInst_wfflags), .io_in_bits_simpleDecodedInst_isMove(io_in_bits_simpleDecodedInst_isMove),
    .io_in_bits_simpleDecodedInst_uopSplitType(io_in_bits_simpleDecodedInst_uopSplitType), .io_in_bits_simpleDecodedInst_isVset(io_in_bits_simpleDecodedInst_isVset), .io_in_bits_simpleDecodedInst_commitType(io_in_bits_simpleDecodedInst_commitType),
    .io_in_bits_simpleDecodedInst_debug_fuType(io_in_bits_simpleDecodedInst_debug_fuType), .io_in_bits_simpleDecodedInst_debug_seqNum_seqNum(io_in_bits_simpleDecodedInst_debug_seqNum_seqNum), .io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx(io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx),
    .io_in_bits_uopInfo_numOfUop(io_in_bits_uopInfo_numOfUop), .io_in_bits_uopInfo_numOfWB(io_in_bits_uopInfo_numOfWB), .io_in_bits_uopInfo_lmul(io_in_bits_uopInfo_lmul),
    .io_out_complexDecodedInsts_0_ready(io_out_complexDecodedInsts_0_ready), .io_in_ready(x_io_in_ready), .io_out_complexDecodedInsts_0_valid(x_io_out_complexDecodedInsts_0_valid),
    .io_out_complexDecodedInsts_0_bits_instr(x_io_out_complexDecodedInsts_0_bits_instr), .io_out_complexDecodedInsts_0_bits_pc(x_io_out_complexDecodedInsts_0_bits_pc), .io_out_complexDecodedInsts_0_bits_foldpc(x_io_out_complexDecodedInsts_0_bits_foldpc),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_0(x_io_out_complexDecodedInsts_0_bits_exceptionVec_0), .io_out_complexDecodedInsts_0_bits_exceptionVec_1(x_io_out_complexDecodedInsts_0_bits_exceptionVec_1), .io_out_complexDecodedInsts_0_bits_exceptionVec_2(x_io_out_complexDecodedInsts_0_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_3(x_io_out_complexDecodedInsts_0_bits_exceptionVec_3), .io_out_complexDecodedInsts_0_bits_exceptionVec_4(x_io_out_complexDecodedInsts_0_bits_exceptionVec_4), .io_out_complexDecodedInsts_0_bits_exceptionVec_5(x_io_out_complexDecodedInsts_0_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_6(x_io_out_complexDecodedInsts_0_bits_exceptionVec_6), .io_out_complexDecodedInsts_0_bits_exceptionVec_7(x_io_out_complexDecodedInsts_0_bits_exceptionVec_7), .io_out_complexDecodedInsts_0_bits_exceptionVec_8(x_io_out_complexDecodedInsts_0_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_9(x_io_out_complexDecodedInsts_0_bits_exceptionVec_9), .io_out_complexDecodedInsts_0_bits_exceptionVec_10(x_io_out_complexDecodedInsts_0_bits_exceptionVec_10), .io_out_complexDecodedInsts_0_bits_exceptionVec_11(x_io_out_complexDecodedInsts_0_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_12(x_io_out_complexDecodedInsts_0_bits_exceptionVec_12), .io_out_complexDecodedInsts_0_bits_exceptionVec_13(x_io_out_complexDecodedInsts_0_bits_exceptionVec_13), .io_out_complexDecodedInsts_0_bits_exceptionVec_14(x_io_out_complexDecodedInsts_0_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_15(x_io_out_complexDecodedInsts_0_bits_exceptionVec_15), .io_out_complexDecodedInsts_0_bits_exceptionVec_16(x_io_out_complexDecodedInsts_0_bits_exceptionVec_16), .io_out_complexDecodedInsts_0_bits_exceptionVec_17(x_io_out_complexDecodedInsts_0_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_18(x_io_out_complexDecodedInsts_0_bits_exceptionVec_18), .io_out_complexDecodedInsts_0_bits_exceptionVec_19(x_io_out_complexDecodedInsts_0_bits_exceptionVec_19), .io_out_complexDecodedInsts_0_bits_exceptionVec_20(x_io_out_complexDecodedInsts_0_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_0_bits_exceptionVec_21(x_io_out_complexDecodedInsts_0_bits_exceptionVec_21), .io_out_complexDecodedInsts_0_bits_exceptionVec_22(x_io_out_complexDecodedInsts_0_bits_exceptionVec_22), .io_out_complexDecodedInsts_0_bits_exceptionVec_23(x_io_out_complexDecodedInsts_0_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_0_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_0_bits_isFetchMalAddr), .io_out_complexDecodedInsts_0_bits_trigger(x_io_out_complexDecodedInsts_0_bits_trigger), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_0_bits_pred_taken(x_io_out_complexDecodedInsts_0_bits_pred_taken), .io_out_complexDecodedInsts_0_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_0_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_0_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_0_bits_ftqPtr_flag), .io_out_complexDecodedInsts_0_bits_ftqPtr_value(x_io_out_complexDecodedInsts_0_bits_ftqPtr_value), .io_out_complexDecodedInsts_0_bits_ftqOffset(x_io_out_complexDecodedInsts_0_bits_ftqOffset),
    .io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_0_bits_srcType_0(x_io_out_complexDecodedInsts_0_bits_srcType_0), .io_out_complexDecodedInsts_0_bits_srcType_1(x_io_out_complexDecodedInsts_0_bits_srcType_1),
    .io_out_complexDecodedInsts_0_bits_srcType_2(x_io_out_complexDecodedInsts_0_bits_srcType_2), .io_out_complexDecodedInsts_0_bits_srcType_3(x_io_out_complexDecodedInsts_0_bits_srcType_3), .io_out_complexDecodedInsts_0_bits_srcType_4(x_io_out_complexDecodedInsts_0_bits_srcType_4),
    .io_out_complexDecodedInsts_0_bits_lsrc_0(x_io_out_complexDecodedInsts_0_bits_lsrc_0), .io_out_complexDecodedInsts_0_bits_lsrc_1(x_io_out_complexDecodedInsts_0_bits_lsrc_1), .io_out_complexDecodedInsts_0_bits_lsrc_2(x_io_out_complexDecodedInsts_0_bits_lsrc_2),
    .io_out_complexDecodedInsts_0_bits_ldest(x_io_out_complexDecodedInsts_0_bits_ldest), .io_out_complexDecodedInsts_0_bits_fuType(x_io_out_complexDecodedInsts_0_bits_fuType), .io_out_complexDecodedInsts_0_bits_fuOpType(x_io_out_complexDecodedInsts_0_bits_fuOpType),
    .io_out_complexDecodedInsts_0_bits_rfWen(x_io_out_complexDecodedInsts_0_bits_rfWen), .io_out_complexDecodedInsts_0_bits_fpWen(x_io_out_complexDecodedInsts_0_bits_fpWen), .io_out_complexDecodedInsts_0_bits_vecWen(x_io_out_complexDecodedInsts_0_bits_vecWen),
    .io_out_complexDecodedInsts_0_bits_vlWen(x_io_out_complexDecodedInsts_0_bits_vlWen), .io_out_complexDecodedInsts_0_bits_isXSTrap(x_io_out_complexDecodedInsts_0_bits_isXSTrap), .io_out_complexDecodedInsts_0_bits_waitForward(x_io_out_complexDecodedInsts_0_bits_waitForward),
    .io_out_complexDecodedInsts_0_bits_blockBackward(x_io_out_complexDecodedInsts_0_bits_blockBackward), .io_out_complexDecodedInsts_0_bits_flushPipe(x_io_out_complexDecodedInsts_0_bits_flushPipe), .io_out_complexDecodedInsts_0_bits_canRobCompress(x_io_out_complexDecodedInsts_0_bits_canRobCompress),
    .io_out_complexDecodedInsts_0_bits_selImm(x_io_out_complexDecodedInsts_0_bits_selImm), .io_out_complexDecodedInsts_0_bits_imm(x_io_out_complexDecodedInsts_0_bits_imm), .io_out_complexDecodedInsts_0_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_0_bits_fpu_wflags(x_io_out_complexDecodedInsts_0_bits_fpu_wflags), .io_out_complexDecodedInsts_0_bits_fpu_typ(x_io_out_complexDecodedInsts_0_bits_fpu_typ), .io_out_complexDecodedInsts_0_bits_fpu_fmt(x_io_out_complexDecodedInsts_0_bits_fpu_fmt),
    .io_out_complexDecodedInsts_0_bits_fpu_rm(x_io_out_complexDecodedInsts_0_bits_fpu_rm), .io_out_complexDecodedInsts_0_bits_vpu_vill(x_io_out_complexDecodedInsts_0_bits_vpu_vill), .io_out_complexDecodedInsts_0_bits_vpu_vma(x_io_out_complexDecodedInsts_0_bits_vpu_vma),
    .io_out_complexDecodedInsts_0_bits_vpu_vta(x_io_out_complexDecodedInsts_0_bits_vpu_vta), .io_out_complexDecodedInsts_0_bits_vpu_vsew(x_io_out_complexDecodedInsts_0_bits_vpu_vsew), .io_out_complexDecodedInsts_0_bits_vpu_vlmul(x_io_out_complexDecodedInsts_0_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_0_bits_vpu_specVill(x_io_out_complexDecodedInsts_0_bits_vpu_specVill), .io_out_complexDecodedInsts_0_bits_vpu_specVma(x_io_out_complexDecodedInsts_0_bits_vpu_specVma), .io_out_complexDecodedInsts_0_bits_vpu_specVta(x_io_out_complexDecodedInsts_0_bits_vpu_specVta),
    .io_out_complexDecodedInsts_0_bits_vpu_specVsew(x_io_out_complexDecodedInsts_0_bits_vpu_specVsew), .io_out_complexDecodedInsts_0_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_0_bits_vpu_specVlmul), .io_out_complexDecodedInsts_0_bits_vpu_vm(x_io_out_complexDecodedInsts_0_bits_vpu_vm),
    .io_out_complexDecodedInsts_0_bits_vpu_vstart(x_io_out_complexDecodedInsts_0_bits_vpu_vstart), .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_0_bits_vpu_nf(x_io_out_complexDecodedInsts_0_bits_vpu_nf), .io_out_complexDecodedInsts_0_bits_vpu_veew(x_io_out_complexDecodedInsts_0_bits_vpu_veew),
    .io_out_complexDecodedInsts_0_bits_vpu_isReverse(x_io_out_complexDecodedInsts_0_bits_vpu_isReverse), .io_out_complexDecodedInsts_0_bits_vpu_isExt(x_io_out_complexDecodedInsts_0_bits_vpu_isExt), .io_out_complexDecodedInsts_0_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_0_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_0_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_0_bits_vpu_isDstMask), .io_out_complexDecodedInsts_0_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_0_bits_vpu_isOpMask), .io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_0_bits_vpu_isVleff(x_io_out_complexDecodedInsts_0_bits_vpu_isVleff), .io_out_complexDecodedInsts_0_bits_vlsInstr(x_io_out_complexDecodedInsts_0_bits_vlsInstr),
    .io_out_complexDecodedInsts_0_bits_wfflags(x_io_out_complexDecodedInsts_0_bits_wfflags), .io_out_complexDecodedInsts_0_bits_isMove(x_io_out_complexDecodedInsts_0_bits_isMove), .io_out_complexDecodedInsts_0_bits_uopIdx(x_io_out_complexDecodedInsts_0_bits_uopIdx),
    .io_out_complexDecodedInsts_0_bits_uopSplitType(x_io_out_complexDecodedInsts_0_bits_uopSplitType), .io_out_complexDecodedInsts_0_bits_isVset(x_io_out_complexDecodedInsts_0_bits_isVset), .io_out_complexDecodedInsts_0_bits_firstUop(x_io_out_complexDecodedInsts_0_bits_firstUop),
    .io_out_complexDecodedInsts_0_bits_lastUop(x_io_out_complexDecodedInsts_0_bits_lastUop), .io_out_complexDecodedInsts_0_bits_numUops(x_io_out_complexDecodedInsts_0_bits_numUops), .io_out_complexDecodedInsts_0_bits_numWB(x_io_out_complexDecodedInsts_0_bits_numWB),
    .io_out_complexDecodedInsts_0_bits_commitType(x_io_out_complexDecodedInsts_0_bits_commitType), .io_out_complexDecodedInsts_0_bits_debug_fuType(x_io_out_complexDecodedInsts_0_bits_debug_fuType), .io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_1_valid(x_io_out_complexDecodedInsts_1_valid), .io_out_complexDecodedInsts_1_bits_instr(x_io_out_complexDecodedInsts_1_bits_instr),
    .io_out_complexDecodedInsts_1_bits_pc(x_io_out_complexDecodedInsts_1_bits_pc), .io_out_complexDecodedInsts_1_bits_foldpc(x_io_out_complexDecodedInsts_1_bits_foldpc), .io_out_complexDecodedInsts_1_bits_exceptionVec_0(x_io_out_complexDecodedInsts_1_bits_exceptionVec_0),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_1(x_io_out_complexDecodedInsts_1_bits_exceptionVec_1), .io_out_complexDecodedInsts_1_bits_exceptionVec_2(x_io_out_complexDecodedInsts_1_bits_exceptionVec_2), .io_out_complexDecodedInsts_1_bits_exceptionVec_3(x_io_out_complexDecodedInsts_1_bits_exceptionVec_3),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_4(x_io_out_complexDecodedInsts_1_bits_exceptionVec_4), .io_out_complexDecodedInsts_1_bits_exceptionVec_5(x_io_out_complexDecodedInsts_1_bits_exceptionVec_5), .io_out_complexDecodedInsts_1_bits_exceptionVec_6(x_io_out_complexDecodedInsts_1_bits_exceptionVec_6),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_7(x_io_out_complexDecodedInsts_1_bits_exceptionVec_7), .io_out_complexDecodedInsts_1_bits_exceptionVec_8(x_io_out_complexDecodedInsts_1_bits_exceptionVec_8), .io_out_complexDecodedInsts_1_bits_exceptionVec_9(x_io_out_complexDecodedInsts_1_bits_exceptionVec_9),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_10(x_io_out_complexDecodedInsts_1_bits_exceptionVec_10), .io_out_complexDecodedInsts_1_bits_exceptionVec_11(x_io_out_complexDecodedInsts_1_bits_exceptionVec_11), .io_out_complexDecodedInsts_1_bits_exceptionVec_12(x_io_out_complexDecodedInsts_1_bits_exceptionVec_12),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_13(x_io_out_complexDecodedInsts_1_bits_exceptionVec_13), .io_out_complexDecodedInsts_1_bits_exceptionVec_14(x_io_out_complexDecodedInsts_1_bits_exceptionVec_14), .io_out_complexDecodedInsts_1_bits_exceptionVec_15(x_io_out_complexDecodedInsts_1_bits_exceptionVec_15),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_16(x_io_out_complexDecodedInsts_1_bits_exceptionVec_16), .io_out_complexDecodedInsts_1_bits_exceptionVec_17(x_io_out_complexDecodedInsts_1_bits_exceptionVec_17), .io_out_complexDecodedInsts_1_bits_exceptionVec_18(x_io_out_complexDecodedInsts_1_bits_exceptionVec_18),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_19(x_io_out_complexDecodedInsts_1_bits_exceptionVec_19), .io_out_complexDecodedInsts_1_bits_exceptionVec_20(x_io_out_complexDecodedInsts_1_bits_exceptionVec_20), .io_out_complexDecodedInsts_1_bits_exceptionVec_21(x_io_out_complexDecodedInsts_1_bits_exceptionVec_21),
    .io_out_complexDecodedInsts_1_bits_exceptionVec_22(x_io_out_complexDecodedInsts_1_bits_exceptionVec_22), .io_out_complexDecodedInsts_1_bits_exceptionVec_23(x_io_out_complexDecodedInsts_1_bits_exceptionVec_23), .io_out_complexDecodedInsts_1_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_1_bits_isFetchMalAddr),
    .io_out_complexDecodedInsts_1_bits_trigger(x_io_out_complexDecodedInsts_1_bits_trigger), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_1_bits_pred_taken(x_io_out_complexDecodedInsts_1_bits_pred_taken), .io_out_complexDecodedInsts_1_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_1_bits_crossPageIPFFix), .io_out_complexDecodedInsts_1_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_1_bits_ftqPtr_flag),
    .io_out_complexDecodedInsts_1_bits_ftqPtr_value(x_io_out_complexDecodedInsts_1_bits_ftqPtr_value), .io_out_complexDecodedInsts_1_bits_ftqOffset(x_io_out_complexDecodedInsts_1_bits_ftqOffset), .io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_1_bits_srcType_0(x_io_out_complexDecodedInsts_1_bits_srcType_0), .io_out_complexDecodedInsts_1_bits_srcType_1(x_io_out_complexDecodedInsts_1_bits_srcType_1), .io_out_complexDecodedInsts_1_bits_srcType_2(x_io_out_complexDecodedInsts_1_bits_srcType_2),
    .io_out_complexDecodedInsts_1_bits_srcType_3(x_io_out_complexDecodedInsts_1_bits_srcType_3), .io_out_complexDecodedInsts_1_bits_srcType_4(x_io_out_complexDecodedInsts_1_bits_srcType_4), .io_out_complexDecodedInsts_1_bits_lsrc_0(x_io_out_complexDecodedInsts_1_bits_lsrc_0),
    .io_out_complexDecodedInsts_1_bits_lsrc_1(x_io_out_complexDecodedInsts_1_bits_lsrc_1), .io_out_complexDecodedInsts_1_bits_lsrc_2(x_io_out_complexDecodedInsts_1_bits_lsrc_2), .io_out_complexDecodedInsts_1_bits_ldest(x_io_out_complexDecodedInsts_1_bits_ldest),
    .io_out_complexDecodedInsts_1_bits_fuType(x_io_out_complexDecodedInsts_1_bits_fuType), .io_out_complexDecodedInsts_1_bits_fuOpType(x_io_out_complexDecodedInsts_1_bits_fuOpType), .io_out_complexDecodedInsts_1_bits_rfWen(x_io_out_complexDecodedInsts_1_bits_rfWen),
    .io_out_complexDecodedInsts_1_bits_fpWen(x_io_out_complexDecodedInsts_1_bits_fpWen), .io_out_complexDecodedInsts_1_bits_vecWen(x_io_out_complexDecodedInsts_1_bits_vecWen), .io_out_complexDecodedInsts_1_bits_vlWen(x_io_out_complexDecodedInsts_1_bits_vlWen),
    .io_out_complexDecodedInsts_1_bits_isXSTrap(x_io_out_complexDecodedInsts_1_bits_isXSTrap), .io_out_complexDecodedInsts_1_bits_waitForward(x_io_out_complexDecodedInsts_1_bits_waitForward), .io_out_complexDecodedInsts_1_bits_blockBackward(x_io_out_complexDecodedInsts_1_bits_blockBackward),
    .io_out_complexDecodedInsts_1_bits_flushPipe(x_io_out_complexDecodedInsts_1_bits_flushPipe), .io_out_complexDecodedInsts_1_bits_canRobCompress(x_io_out_complexDecodedInsts_1_bits_canRobCompress), .io_out_complexDecodedInsts_1_bits_selImm(x_io_out_complexDecodedInsts_1_bits_selImm),
    .io_out_complexDecodedInsts_1_bits_imm(x_io_out_complexDecodedInsts_1_bits_imm), .io_out_complexDecodedInsts_1_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_1_bits_fpu_wflags(x_io_out_complexDecodedInsts_1_bits_fpu_wflags),
    .io_out_complexDecodedInsts_1_bits_fpu_typ(x_io_out_complexDecodedInsts_1_bits_fpu_typ), .io_out_complexDecodedInsts_1_bits_fpu_fmt(x_io_out_complexDecodedInsts_1_bits_fpu_fmt), .io_out_complexDecodedInsts_1_bits_fpu_rm(x_io_out_complexDecodedInsts_1_bits_fpu_rm),
    .io_out_complexDecodedInsts_1_bits_vpu_vill(x_io_out_complexDecodedInsts_1_bits_vpu_vill), .io_out_complexDecodedInsts_1_bits_vpu_vma(x_io_out_complexDecodedInsts_1_bits_vpu_vma), .io_out_complexDecodedInsts_1_bits_vpu_vta(x_io_out_complexDecodedInsts_1_bits_vpu_vta),
    .io_out_complexDecodedInsts_1_bits_vpu_vsew(x_io_out_complexDecodedInsts_1_bits_vpu_vsew), .io_out_complexDecodedInsts_1_bits_vpu_vlmul(x_io_out_complexDecodedInsts_1_bits_vpu_vlmul), .io_out_complexDecodedInsts_1_bits_vpu_specVill(x_io_out_complexDecodedInsts_1_bits_vpu_specVill),
    .io_out_complexDecodedInsts_1_bits_vpu_specVma(x_io_out_complexDecodedInsts_1_bits_vpu_specVma), .io_out_complexDecodedInsts_1_bits_vpu_specVta(x_io_out_complexDecodedInsts_1_bits_vpu_specVta), .io_out_complexDecodedInsts_1_bits_vpu_specVsew(x_io_out_complexDecodedInsts_1_bits_vpu_specVsew),
    .io_out_complexDecodedInsts_1_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_1_bits_vpu_specVlmul), .io_out_complexDecodedInsts_1_bits_vpu_vm(x_io_out_complexDecodedInsts_1_bits_vpu_vm), .io_out_complexDecodedInsts_1_bits_vpu_vstart(x_io_out_complexDecodedInsts_1_bits_vpu_vstart),
    .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_1_bits_vpu_nf(x_io_out_complexDecodedInsts_1_bits_vpu_nf), .io_out_complexDecodedInsts_1_bits_vpu_veew(x_io_out_complexDecodedInsts_1_bits_vpu_veew), .io_out_complexDecodedInsts_1_bits_vpu_isReverse(x_io_out_complexDecodedInsts_1_bits_vpu_isReverse),
    .io_out_complexDecodedInsts_1_bits_vpu_isExt(x_io_out_complexDecodedInsts_1_bits_vpu_isExt), .io_out_complexDecodedInsts_1_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_1_bits_vpu_isNarrow), .io_out_complexDecodedInsts_1_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_1_bits_vpu_isDstMask),
    .io_out_complexDecodedInsts_1_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_1_bits_vpu_isOpMask), .io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd),
    .io_out_complexDecodedInsts_1_bits_vpu_isVleff(x_io_out_complexDecodedInsts_1_bits_vpu_isVleff), .io_out_complexDecodedInsts_1_bits_vlsInstr(x_io_out_complexDecodedInsts_1_bits_vlsInstr), .io_out_complexDecodedInsts_1_bits_wfflags(x_io_out_complexDecodedInsts_1_bits_wfflags),
    .io_out_complexDecodedInsts_1_bits_isMove(x_io_out_complexDecodedInsts_1_bits_isMove), .io_out_complexDecodedInsts_1_bits_uopIdx(x_io_out_complexDecodedInsts_1_bits_uopIdx), .io_out_complexDecodedInsts_1_bits_uopSplitType(x_io_out_complexDecodedInsts_1_bits_uopSplitType),
    .io_out_complexDecodedInsts_1_bits_isVset(x_io_out_complexDecodedInsts_1_bits_isVset), .io_out_complexDecodedInsts_1_bits_lastUop(x_io_out_complexDecodedInsts_1_bits_lastUop), .io_out_complexDecodedInsts_1_bits_numUops(x_io_out_complexDecodedInsts_1_bits_numUops),
    .io_out_complexDecodedInsts_1_bits_numWB(x_io_out_complexDecodedInsts_1_bits_numWB), .io_out_complexDecodedInsts_1_bits_commitType(x_io_out_complexDecodedInsts_1_bits_commitType), .io_out_complexDecodedInsts_1_bits_debug_fuType(x_io_out_complexDecodedInsts_1_bits_debug_fuType),
    .io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_2_valid(x_io_out_complexDecodedInsts_2_valid),
    .io_out_complexDecodedInsts_2_bits_instr(x_io_out_complexDecodedInsts_2_bits_instr), .io_out_complexDecodedInsts_2_bits_pc(x_io_out_complexDecodedInsts_2_bits_pc), .io_out_complexDecodedInsts_2_bits_foldpc(x_io_out_complexDecodedInsts_2_bits_foldpc),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_0(x_io_out_complexDecodedInsts_2_bits_exceptionVec_0), .io_out_complexDecodedInsts_2_bits_exceptionVec_1(x_io_out_complexDecodedInsts_2_bits_exceptionVec_1), .io_out_complexDecodedInsts_2_bits_exceptionVec_2(x_io_out_complexDecodedInsts_2_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_3(x_io_out_complexDecodedInsts_2_bits_exceptionVec_3), .io_out_complexDecodedInsts_2_bits_exceptionVec_4(x_io_out_complexDecodedInsts_2_bits_exceptionVec_4), .io_out_complexDecodedInsts_2_bits_exceptionVec_5(x_io_out_complexDecodedInsts_2_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_6(x_io_out_complexDecodedInsts_2_bits_exceptionVec_6), .io_out_complexDecodedInsts_2_bits_exceptionVec_7(x_io_out_complexDecodedInsts_2_bits_exceptionVec_7), .io_out_complexDecodedInsts_2_bits_exceptionVec_8(x_io_out_complexDecodedInsts_2_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_9(x_io_out_complexDecodedInsts_2_bits_exceptionVec_9), .io_out_complexDecodedInsts_2_bits_exceptionVec_10(x_io_out_complexDecodedInsts_2_bits_exceptionVec_10), .io_out_complexDecodedInsts_2_bits_exceptionVec_11(x_io_out_complexDecodedInsts_2_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_12(x_io_out_complexDecodedInsts_2_bits_exceptionVec_12), .io_out_complexDecodedInsts_2_bits_exceptionVec_13(x_io_out_complexDecodedInsts_2_bits_exceptionVec_13), .io_out_complexDecodedInsts_2_bits_exceptionVec_14(x_io_out_complexDecodedInsts_2_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_15(x_io_out_complexDecodedInsts_2_bits_exceptionVec_15), .io_out_complexDecodedInsts_2_bits_exceptionVec_16(x_io_out_complexDecodedInsts_2_bits_exceptionVec_16), .io_out_complexDecodedInsts_2_bits_exceptionVec_17(x_io_out_complexDecodedInsts_2_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_18(x_io_out_complexDecodedInsts_2_bits_exceptionVec_18), .io_out_complexDecodedInsts_2_bits_exceptionVec_19(x_io_out_complexDecodedInsts_2_bits_exceptionVec_19), .io_out_complexDecodedInsts_2_bits_exceptionVec_20(x_io_out_complexDecodedInsts_2_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_2_bits_exceptionVec_21(x_io_out_complexDecodedInsts_2_bits_exceptionVec_21), .io_out_complexDecodedInsts_2_bits_exceptionVec_22(x_io_out_complexDecodedInsts_2_bits_exceptionVec_22), .io_out_complexDecodedInsts_2_bits_exceptionVec_23(x_io_out_complexDecodedInsts_2_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_2_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_2_bits_isFetchMalAddr), .io_out_complexDecodedInsts_2_bits_trigger(x_io_out_complexDecodedInsts_2_bits_trigger), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_2_bits_pred_taken(x_io_out_complexDecodedInsts_2_bits_pred_taken), .io_out_complexDecodedInsts_2_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_2_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_2_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_2_bits_ftqPtr_flag), .io_out_complexDecodedInsts_2_bits_ftqPtr_value(x_io_out_complexDecodedInsts_2_bits_ftqPtr_value), .io_out_complexDecodedInsts_2_bits_ftqOffset(x_io_out_complexDecodedInsts_2_bits_ftqOffset),
    .io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_2_bits_srcType_0(x_io_out_complexDecodedInsts_2_bits_srcType_0), .io_out_complexDecodedInsts_2_bits_srcType_1(x_io_out_complexDecodedInsts_2_bits_srcType_1),
    .io_out_complexDecodedInsts_2_bits_srcType_2(x_io_out_complexDecodedInsts_2_bits_srcType_2), .io_out_complexDecodedInsts_2_bits_srcType_3(x_io_out_complexDecodedInsts_2_bits_srcType_3), .io_out_complexDecodedInsts_2_bits_srcType_4(x_io_out_complexDecodedInsts_2_bits_srcType_4),
    .io_out_complexDecodedInsts_2_bits_lsrc_0(x_io_out_complexDecodedInsts_2_bits_lsrc_0), .io_out_complexDecodedInsts_2_bits_lsrc_1(x_io_out_complexDecodedInsts_2_bits_lsrc_1), .io_out_complexDecodedInsts_2_bits_lsrc_2(x_io_out_complexDecodedInsts_2_bits_lsrc_2),
    .io_out_complexDecodedInsts_2_bits_ldest(x_io_out_complexDecodedInsts_2_bits_ldest), .io_out_complexDecodedInsts_2_bits_fuType(x_io_out_complexDecodedInsts_2_bits_fuType), .io_out_complexDecodedInsts_2_bits_fuOpType(x_io_out_complexDecodedInsts_2_bits_fuOpType),
    .io_out_complexDecodedInsts_2_bits_rfWen(x_io_out_complexDecodedInsts_2_bits_rfWen), .io_out_complexDecodedInsts_2_bits_fpWen(x_io_out_complexDecodedInsts_2_bits_fpWen), .io_out_complexDecodedInsts_2_bits_vecWen(x_io_out_complexDecodedInsts_2_bits_vecWen),
    .io_out_complexDecodedInsts_2_bits_vlWen(x_io_out_complexDecodedInsts_2_bits_vlWen), .io_out_complexDecodedInsts_2_bits_isXSTrap(x_io_out_complexDecodedInsts_2_bits_isXSTrap), .io_out_complexDecodedInsts_2_bits_waitForward(x_io_out_complexDecodedInsts_2_bits_waitForward),
    .io_out_complexDecodedInsts_2_bits_blockBackward(x_io_out_complexDecodedInsts_2_bits_blockBackward), .io_out_complexDecodedInsts_2_bits_flushPipe(x_io_out_complexDecodedInsts_2_bits_flushPipe), .io_out_complexDecodedInsts_2_bits_canRobCompress(x_io_out_complexDecodedInsts_2_bits_canRobCompress),
    .io_out_complexDecodedInsts_2_bits_selImm(x_io_out_complexDecodedInsts_2_bits_selImm), .io_out_complexDecodedInsts_2_bits_imm(x_io_out_complexDecodedInsts_2_bits_imm), .io_out_complexDecodedInsts_2_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_2_bits_fpu_wflags(x_io_out_complexDecodedInsts_2_bits_fpu_wflags), .io_out_complexDecodedInsts_2_bits_fpu_typ(x_io_out_complexDecodedInsts_2_bits_fpu_typ), .io_out_complexDecodedInsts_2_bits_fpu_fmt(x_io_out_complexDecodedInsts_2_bits_fpu_fmt),
    .io_out_complexDecodedInsts_2_bits_fpu_rm(x_io_out_complexDecodedInsts_2_bits_fpu_rm), .io_out_complexDecodedInsts_2_bits_vpu_vill(x_io_out_complexDecodedInsts_2_bits_vpu_vill), .io_out_complexDecodedInsts_2_bits_vpu_vma(x_io_out_complexDecodedInsts_2_bits_vpu_vma),
    .io_out_complexDecodedInsts_2_bits_vpu_vta(x_io_out_complexDecodedInsts_2_bits_vpu_vta), .io_out_complexDecodedInsts_2_bits_vpu_vsew(x_io_out_complexDecodedInsts_2_bits_vpu_vsew), .io_out_complexDecodedInsts_2_bits_vpu_vlmul(x_io_out_complexDecodedInsts_2_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_2_bits_vpu_specVill(x_io_out_complexDecodedInsts_2_bits_vpu_specVill), .io_out_complexDecodedInsts_2_bits_vpu_specVma(x_io_out_complexDecodedInsts_2_bits_vpu_specVma), .io_out_complexDecodedInsts_2_bits_vpu_specVta(x_io_out_complexDecodedInsts_2_bits_vpu_specVta),
    .io_out_complexDecodedInsts_2_bits_vpu_specVsew(x_io_out_complexDecodedInsts_2_bits_vpu_specVsew), .io_out_complexDecodedInsts_2_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_2_bits_vpu_specVlmul), .io_out_complexDecodedInsts_2_bits_vpu_vm(x_io_out_complexDecodedInsts_2_bits_vpu_vm),
    .io_out_complexDecodedInsts_2_bits_vpu_vstart(x_io_out_complexDecodedInsts_2_bits_vpu_vstart), .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_2_bits_vpu_nf(x_io_out_complexDecodedInsts_2_bits_vpu_nf), .io_out_complexDecodedInsts_2_bits_vpu_veew(x_io_out_complexDecodedInsts_2_bits_vpu_veew),
    .io_out_complexDecodedInsts_2_bits_vpu_isReverse(x_io_out_complexDecodedInsts_2_bits_vpu_isReverse), .io_out_complexDecodedInsts_2_bits_vpu_isExt(x_io_out_complexDecodedInsts_2_bits_vpu_isExt), .io_out_complexDecodedInsts_2_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_2_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_2_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_2_bits_vpu_isDstMask), .io_out_complexDecodedInsts_2_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_2_bits_vpu_isOpMask), .io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_2_bits_vpu_isVleff(x_io_out_complexDecodedInsts_2_bits_vpu_isVleff), .io_out_complexDecodedInsts_2_bits_vlsInstr(x_io_out_complexDecodedInsts_2_bits_vlsInstr),
    .io_out_complexDecodedInsts_2_bits_wfflags(x_io_out_complexDecodedInsts_2_bits_wfflags), .io_out_complexDecodedInsts_2_bits_isMove(x_io_out_complexDecodedInsts_2_bits_isMove), .io_out_complexDecodedInsts_2_bits_uopIdx(x_io_out_complexDecodedInsts_2_bits_uopIdx),
    .io_out_complexDecodedInsts_2_bits_uopSplitType(x_io_out_complexDecodedInsts_2_bits_uopSplitType), .io_out_complexDecodedInsts_2_bits_isVset(x_io_out_complexDecodedInsts_2_bits_isVset), .io_out_complexDecodedInsts_2_bits_lastUop(x_io_out_complexDecodedInsts_2_bits_lastUop),
    .io_out_complexDecodedInsts_2_bits_numUops(x_io_out_complexDecodedInsts_2_bits_numUops), .io_out_complexDecodedInsts_2_bits_numWB(x_io_out_complexDecodedInsts_2_bits_numWB), .io_out_complexDecodedInsts_2_bits_commitType(x_io_out_complexDecodedInsts_2_bits_commitType),
    .io_out_complexDecodedInsts_2_bits_debug_fuType(x_io_out_complexDecodedInsts_2_bits_debug_fuType), .io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx),
    .io_out_complexDecodedInsts_3_valid(x_io_out_complexDecodedInsts_3_valid), .io_out_complexDecodedInsts_3_bits_instr(x_io_out_complexDecodedInsts_3_bits_instr), .io_out_complexDecodedInsts_3_bits_pc(x_io_out_complexDecodedInsts_3_bits_pc),
    .io_out_complexDecodedInsts_3_bits_foldpc(x_io_out_complexDecodedInsts_3_bits_foldpc), .io_out_complexDecodedInsts_3_bits_exceptionVec_0(x_io_out_complexDecodedInsts_3_bits_exceptionVec_0), .io_out_complexDecodedInsts_3_bits_exceptionVec_1(x_io_out_complexDecodedInsts_3_bits_exceptionVec_1),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_2(x_io_out_complexDecodedInsts_3_bits_exceptionVec_2), .io_out_complexDecodedInsts_3_bits_exceptionVec_3(x_io_out_complexDecodedInsts_3_bits_exceptionVec_3), .io_out_complexDecodedInsts_3_bits_exceptionVec_4(x_io_out_complexDecodedInsts_3_bits_exceptionVec_4),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_5(x_io_out_complexDecodedInsts_3_bits_exceptionVec_5), .io_out_complexDecodedInsts_3_bits_exceptionVec_6(x_io_out_complexDecodedInsts_3_bits_exceptionVec_6), .io_out_complexDecodedInsts_3_bits_exceptionVec_7(x_io_out_complexDecodedInsts_3_bits_exceptionVec_7),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_8(x_io_out_complexDecodedInsts_3_bits_exceptionVec_8), .io_out_complexDecodedInsts_3_bits_exceptionVec_9(x_io_out_complexDecodedInsts_3_bits_exceptionVec_9), .io_out_complexDecodedInsts_3_bits_exceptionVec_10(x_io_out_complexDecodedInsts_3_bits_exceptionVec_10),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_11(x_io_out_complexDecodedInsts_3_bits_exceptionVec_11), .io_out_complexDecodedInsts_3_bits_exceptionVec_12(x_io_out_complexDecodedInsts_3_bits_exceptionVec_12), .io_out_complexDecodedInsts_3_bits_exceptionVec_13(x_io_out_complexDecodedInsts_3_bits_exceptionVec_13),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_14(x_io_out_complexDecodedInsts_3_bits_exceptionVec_14), .io_out_complexDecodedInsts_3_bits_exceptionVec_15(x_io_out_complexDecodedInsts_3_bits_exceptionVec_15), .io_out_complexDecodedInsts_3_bits_exceptionVec_16(x_io_out_complexDecodedInsts_3_bits_exceptionVec_16),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_17(x_io_out_complexDecodedInsts_3_bits_exceptionVec_17), .io_out_complexDecodedInsts_3_bits_exceptionVec_18(x_io_out_complexDecodedInsts_3_bits_exceptionVec_18), .io_out_complexDecodedInsts_3_bits_exceptionVec_19(x_io_out_complexDecodedInsts_3_bits_exceptionVec_19),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_20(x_io_out_complexDecodedInsts_3_bits_exceptionVec_20), .io_out_complexDecodedInsts_3_bits_exceptionVec_21(x_io_out_complexDecodedInsts_3_bits_exceptionVec_21), .io_out_complexDecodedInsts_3_bits_exceptionVec_22(x_io_out_complexDecodedInsts_3_bits_exceptionVec_22),
    .io_out_complexDecodedInsts_3_bits_exceptionVec_23(x_io_out_complexDecodedInsts_3_bits_exceptionVec_23), .io_out_complexDecodedInsts_3_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_3_bits_isFetchMalAddr), .io_out_complexDecodedInsts_3_bits_trigger(x_io_out_complexDecodedInsts_3_bits_trigger),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType),
    .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_3_bits_pred_taken(x_io_out_complexDecodedInsts_3_bits_pred_taken),
    .io_out_complexDecodedInsts_3_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_3_bits_crossPageIPFFix), .io_out_complexDecodedInsts_3_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_3_bits_ftqPtr_flag), .io_out_complexDecodedInsts_3_bits_ftqPtr_value(x_io_out_complexDecodedInsts_3_bits_ftqPtr_value),
    .io_out_complexDecodedInsts_3_bits_ftqOffset(x_io_out_complexDecodedInsts_3_bits_ftqOffset), .io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_3_bits_srcType_0(x_io_out_complexDecodedInsts_3_bits_srcType_0),
    .io_out_complexDecodedInsts_3_bits_srcType_1(x_io_out_complexDecodedInsts_3_bits_srcType_1), .io_out_complexDecodedInsts_3_bits_srcType_2(x_io_out_complexDecodedInsts_3_bits_srcType_2), .io_out_complexDecodedInsts_3_bits_srcType_3(x_io_out_complexDecodedInsts_3_bits_srcType_3),
    .io_out_complexDecodedInsts_3_bits_srcType_4(x_io_out_complexDecodedInsts_3_bits_srcType_4), .io_out_complexDecodedInsts_3_bits_lsrc_0(x_io_out_complexDecodedInsts_3_bits_lsrc_0), .io_out_complexDecodedInsts_3_bits_lsrc_1(x_io_out_complexDecodedInsts_3_bits_lsrc_1),
    .io_out_complexDecodedInsts_3_bits_lsrc_2(x_io_out_complexDecodedInsts_3_bits_lsrc_2), .io_out_complexDecodedInsts_3_bits_ldest(x_io_out_complexDecodedInsts_3_bits_ldest), .io_out_complexDecodedInsts_3_bits_fuType(x_io_out_complexDecodedInsts_3_bits_fuType),
    .io_out_complexDecodedInsts_3_bits_fuOpType(x_io_out_complexDecodedInsts_3_bits_fuOpType), .io_out_complexDecodedInsts_3_bits_rfWen(x_io_out_complexDecodedInsts_3_bits_rfWen), .io_out_complexDecodedInsts_3_bits_fpWen(x_io_out_complexDecodedInsts_3_bits_fpWen),
    .io_out_complexDecodedInsts_3_bits_vecWen(x_io_out_complexDecodedInsts_3_bits_vecWen), .io_out_complexDecodedInsts_3_bits_vlWen(x_io_out_complexDecodedInsts_3_bits_vlWen), .io_out_complexDecodedInsts_3_bits_isXSTrap(x_io_out_complexDecodedInsts_3_bits_isXSTrap),
    .io_out_complexDecodedInsts_3_bits_waitForward(x_io_out_complexDecodedInsts_3_bits_waitForward), .io_out_complexDecodedInsts_3_bits_blockBackward(x_io_out_complexDecodedInsts_3_bits_blockBackward), .io_out_complexDecodedInsts_3_bits_flushPipe(x_io_out_complexDecodedInsts_3_bits_flushPipe),
    .io_out_complexDecodedInsts_3_bits_canRobCompress(x_io_out_complexDecodedInsts_3_bits_canRobCompress), .io_out_complexDecodedInsts_3_bits_selImm(x_io_out_complexDecodedInsts_3_bits_selImm), .io_out_complexDecodedInsts_3_bits_imm(x_io_out_complexDecodedInsts_3_bits_imm),
    .io_out_complexDecodedInsts_3_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_3_bits_fpu_wflags(x_io_out_complexDecodedInsts_3_bits_fpu_wflags), .io_out_complexDecodedInsts_3_bits_fpu_typ(x_io_out_complexDecodedInsts_3_bits_fpu_typ),
    .io_out_complexDecodedInsts_3_bits_fpu_fmt(x_io_out_complexDecodedInsts_3_bits_fpu_fmt), .io_out_complexDecodedInsts_3_bits_fpu_rm(x_io_out_complexDecodedInsts_3_bits_fpu_rm), .io_out_complexDecodedInsts_3_bits_vpu_vill(x_io_out_complexDecodedInsts_3_bits_vpu_vill),
    .io_out_complexDecodedInsts_3_bits_vpu_vma(x_io_out_complexDecodedInsts_3_bits_vpu_vma), .io_out_complexDecodedInsts_3_bits_vpu_vta(x_io_out_complexDecodedInsts_3_bits_vpu_vta), .io_out_complexDecodedInsts_3_bits_vpu_vsew(x_io_out_complexDecodedInsts_3_bits_vpu_vsew),
    .io_out_complexDecodedInsts_3_bits_vpu_vlmul(x_io_out_complexDecodedInsts_3_bits_vpu_vlmul), .io_out_complexDecodedInsts_3_bits_vpu_specVill(x_io_out_complexDecodedInsts_3_bits_vpu_specVill), .io_out_complexDecodedInsts_3_bits_vpu_specVma(x_io_out_complexDecodedInsts_3_bits_vpu_specVma),
    .io_out_complexDecodedInsts_3_bits_vpu_specVta(x_io_out_complexDecodedInsts_3_bits_vpu_specVta), .io_out_complexDecodedInsts_3_bits_vpu_specVsew(x_io_out_complexDecodedInsts_3_bits_vpu_specVsew), .io_out_complexDecodedInsts_3_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_3_bits_vpu_specVlmul),
    .io_out_complexDecodedInsts_3_bits_vpu_vm(x_io_out_complexDecodedInsts_3_bits_vpu_vm), .io_out_complexDecodedInsts_3_bits_vpu_vstart(x_io_out_complexDecodedInsts_3_bits_vpu_vstart), .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2),
    .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_3_bits_vpu_nf(x_io_out_complexDecodedInsts_3_bits_vpu_nf),
    .io_out_complexDecodedInsts_3_bits_vpu_veew(x_io_out_complexDecodedInsts_3_bits_vpu_veew), .io_out_complexDecodedInsts_3_bits_vpu_isReverse(x_io_out_complexDecodedInsts_3_bits_vpu_isReverse), .io_out_complexDecodedInsts_3_bits_vpu_isExt(x_io_out_complexDecodedInsts_3_bits_vpu_isExt),
    .io_out_complexDecodedInsts_3_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_3_bits_vpu_isNarrow), .io_out_complexDecodedInsts_3_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_3_bits_vpu_isDstMask), .io_out_complexDecodedInsts_3_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_3_bits_vpu_isOpMask),
    .io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_3_bits_vpu_isVleff(x_io_out_complexDecodedInsts_3_bits_vpu_isVleff),
    .io_out_complexDecodedInsts_3_bits_vlsInstr(x_io_out_complexDecodedInsts_3_bits_vlsInstr), .io_out_complexDecodedInsts_3_bits_wfflags(x_io_out_complexDecodedInsts_3_bits_wfflags), .io_out_complexDecodedInsts_3_bits_isMove(x_io_out_complexDecodedInsts_3_bits_isMove),
    .io_out_complexDecodedInsts_3_bits_uopIdx(x_io_out_complexDecodedInsts_3_bits_uopIdx), .io_out_complexDecodedInsts_3_bits_uopSplitType(x_io_out_complexDecodedInsts_3_bits_uopSplitType), .io_out_complexDecodedInsts_3_bits_isVset(x_io_out_complexDecodedInsts_3_bits_isVset),
    .io_out_complexDecodedInsts_3_bits_lastUop(x_io_out_complexDecodedInsts_3_bits_lastUop), .io_out_complexDecodedInsts_3_bits_numUops(x_io_out_complexDecodedInsts_3_bits_numUops), .io_out_complexDecodedInsts_3_bits_numWB(x_io_out_complexDecodedInsts_3_bits_numWB),
    .io_out_complexDecodedInsts_3_bits_commitType(x_io_out_complexDecodedInsts_3_bits_commitType), .io_out_complexDecodedInsts_3_bits_debug_fuType(x_io_out_complexDecodedInsts_3_bits_debug_fuType), .io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum),
    .io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_4_valid(x_io_out_complexDecodedInsts_4_valid), .io_out_complexDecodedInsts_4_bits_instr(x_io_out_complexDecodedInsts_4_bits_instr),
    .io_out_complexDecodedInsts_4_bits_pc(x_io_out_complexDecodedInsts_4_bits_pc), .io_out_complexDecodedInsts_4_bits_foldpc(x_io_out_complexDecodedInsts_4_bits_foldpc), .io_out_complexDecodedInsts_4_bits_exceptionVec_0(x_io_out_complexDecodedInsts_4_bits_exceptionVec_0),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_1(x_io_out_complexDecodedInsts_4_bits_exceptionVec_1), .io_out_complexDecodedInsts_4_bits_exceptionVec_2(x_io_out_complexDecodedInsts_4_bits_exceptionVec_2), .io_out_complexDecodedInsts_4_bits_exceptionVec_3(x_io_out_complexDecodedInsts_4_bits_exceptionVec_3),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_4(x_io_out_complexDecodedInsts_4_bits_exceptionVec_4), .io_out_complexDecodedInsts_4_bits_exceptionVec_5(x_io_out_complexDecodedInsts_4_bits_exceptionVec_5), .io_out_complexDecodedInsts_4_bits_exceptionVec_6(x_io_out_complexDecodedInsts_4_bits_exceptionVec_6),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_7(x_io_out_complexDecodedInsts_4_bits_exceptionVec_7), .io_out_complexDecodedInsts_4_bits_exceptionVec_8(x_io_out_complexDecodedInsts_4_bits_exceptionVec_8), .io_out_complexDecodedInsts_4_bits_exceptionVec_9(x_io_out_complexDecodedInsts_4_bits_exceptionVec_9),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_10(x_io_out_complexDecodedInsts_4_bits_exceptionVec_10), .io_out_complexDecodedInsts_4_bits_exceptionVec_11(x_io_out_complexDecodedInsts_4_bits_exceptionVec_11), .io_out_complexDecodedInsts_4_bits_exceptionVec_12(x_io_out_complexDecodedInsts_4_bits_exceptionVec_12),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_13(x_io_out_complexDecodedInsts_4_bits_exceptionVec_13), .io_out_complexDecodedInsts_4_bits_exceptionVec_14(x_io_out_complexDecodedInsts_4_bits_exceptionVec_14), .io_out_complexDecodedInsts_4_bits_exceptionVec_15(x_io_out_complexDecodedInsts_4_bits_exceptionVec_15),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_16(x_io_out_complexDecodedInsts_4_bits_exceptionVec_16), .io_out_complexDecodedInsts_4_bits_exceptionVec_17(x_io_out_complexDecodedInsts_4_bits_exceptionVec_17), .io_out_complexDecodedInsts_4_bits_exceptionVec_18(x_io_out_complexDecodedInsts_4_bits_exceptionVec_18),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_19(x_io_out_complexDecodedInsts_4_bits_exceptionVec_19), .io_out_complexDecodedInsts_4_bits_exceptionVec_20(x_io_out_complexDecodedInsts_4_bits_exceptionVec_20), .io_out_complexDecodedInsts_4_bits_exceptionVec_21(x_io_out_complexDecodedInsts_4_bits_exceptionVec_21),
    .io_out_complexDecodedInsts_4_bits_exceptionVec_22(x_io_out_complexDecodedInsts_4_bits_exceptionVec_22), .io_out_complexDecodedInsts_4_bits_exceptionVec_23(x_io_out_complexDecodedInsts_4_bits_exceptionVec_23), .io_out_complexDecodedInsts_4_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_4_bits_isFetchMalAddr),
    .io_out_complexDecodedInsts_4_bits_trigger(x_io_out_complexDecodedInsts_4_bits_trigger), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC),
    .io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall), .io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet),
    .io_out_complexDecodedInsts_4_bits_pred_taken(x_io_out_complexDecodedInsts_4_bits_pred_taken), .io_out_complexDecodedInsts_4_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_4_bits_crossPageIPFFix), .io_out_complexDecodedInsts_4_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_4_bits_ftqPtr_flag),
    .io_out_complexDecodedInsts_4_bits_ftqPtr_value(x_io_out_complexDecodedInsts_4_bits_ftqPtr_value), .io_out_complexDecodedInsts_4_bits_ftqOffset(x_io_out_complexDecodedInsts_4_bits_ftqOffset), .io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault),
    .io_out_complexDecodedInsts_4_bits_srcType_0(x_io_out_complexDecodedInsts_4_bits_srcType_0), .io_out_complexDecodedInsts_4_bits_srcType_1(x_io_out_complexDecodedInsts_4_bits_srcType_1), .io_out_complexDecodedInsts_4_bits_srcType_2(x_io_out_complexDecodedInsts_4_bits_srcType_2),
    .io_out_complexDecodedInsts_4_bits_srcType_3(x_io_out_complexDecodedInsts_4_bits_srcType_3), .io_out_complexDecodedInsts_4_bits_srcType_4(x_io_out_complexDecodedInsts_4_bits_srcType_4), .io_out_complexDecodedInsts_4_bits_lsrc_0(x_io_out_complexDecodedInsts_4_bits_lsrc_0),
    .io_out_complexDecodedInsts_4_bits_lsrc_1(x_io_out_complexDecodedInsts_4_bits_lsrc_1), .io_out_complexDecodedInsts_4_bits_lsrc_2(x_io_out_complexDecodedInsts_4_bits_lsrc_2), .io_out_complexDecodedInsts_4_bits_ldest(x_io_out_complexDecodedInsts_4_bits_ldest),
    .io_out_complexDecodedInsts_4_bits_fuType(x_io_out_complexDecodedInsts_4_bits_fuType), .io_out_complexDecodedInsts_4_bits_fuOpType(x_io_out_complexDecodedInsts_4_bits_fuOpType), .io_out_complexDecodedInsts_4_bits_rfWen(x_io_out_complexDecodedInsts_4_bits_rfWen),
    .io_out_complexDecodedInsts_4_bits_fpWen(x_io_out_complexDecodedInsts_4_bits_fpWen), .io_out_complexDecodedInsts_4_bits_vecWen(x_io_out_complexDecodedInsts_4_bits_vecWen), .io_out_complexDecodedInsts_4_bits_vlWen(x_io_out_complexDecodedInsts_4_bits_vlWen),
    .io_out_complexDecodedInsts_4_bits_isXSTrap(x_io_out_complexDecodedInsts_4_bits_isXSTrap), .io_out_complexDecodedInsts_4_bits_waitForward(x_io_out_complexDecodedInsts_4_bits_waitForward), .io_out_complexDecodedInsts_4_bits_blockBackward(x_io_out_complexDecodedInsts_4_bits_blockBackward),
    .io_out_complexDecodedInsts_4_bits_flushPipe(x_io_out_complexDecodedInsts_4_bits_flushPipe), .io_out_complexDecodedInsts_4_bits_canRobCompress(x_io_out_complexDecodedInsts_4_bits_canRobCompress), .io_out_complexDecodedInsts_4_bits_selImm(x_io_out_complexDecodedInsts_4_bits_selImm),
    .io_out_complexDecodedInsts_4_bits_imm(x_io_out_complexDecodedInsts_4_bits_imm), .io_out_complexDecodedInsts_4_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut), .io_out_complexDecodedInsts_4_bits_fpu_wflags(x_io_out_complexDecodedInsts_4_bits_fpu_wflags),
    .io_out_complexDecodedInsts_4_bits_fpu_typ(x_io_out_complexDecodedInsts_4_bits_fpu_typ), .io_out_complexDecodedInsts_4_bits_fpu_fmt(x_io_out_complexDecodedInsts_4_bits_fpu_fmt), .io_out_complexDecodedInsts_4_bits_fpu_rm(x_io_out_complexDecodedInsts_4_bits_fpu_rm),
    .io_out_complexDecodedInsts_4_bits_vpu_vill(x_io_out_complexDecodedInsts_4_bits_vpu_vill), .io_out_complexDecodedInsts_4_bits_vpu_vma(x_io_out_complexDecodedInsts_4_bits_vpu_vma), .io_out_complexDecodedInsts_4_bits_vpu_vta(x_io_out_complexDecodedInsts_4_bits_vpu_vta),
    .io_out_complexDecodedInsts_4_bits_vpu_vsew(x_io_out_complexDecodedInsts_4_bits_vpu_vsew), .io_out_complexDecodedInsts_4_bits_vpu_vlmul(x_io_out_complexDecodedInsts_4_bits_vpu_vlmul), .io_out_complexDecodedInsts_4_bits_vpu_specVill(x_io_out_complexDecodedInsts_4_bits_vpu_specVill),
    .io_out_complexDecodedInsts_4_bits_vpu_specVma(x_io_out_complexDecodedInsts_4_bits_vpu_specVma), .io_out_complexDecodedInsts_4_bits_vpu_specVta(x_io_out_complexDecodedInsts_4_bits_vpu_specVta), .io_out_complexDecodedInsts_4_bits_vpu_specVsew(x_io_out_complexDecodedInsts_4_bits_vpu_specVsew),
    .io_out_complexDecodedInsts_4_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_4_bits_vpu_specVlmul), .io_out_complexDecodedInsts_4_bits_vpu_vm(x_io_out_complexDecodedInsts_4_bits_vpu_vm), .io_out_complexDecodedInsts_4_bits_vpu_vstart(x_io_out_complexDecodedInsts_4_bits_vpu_vstart),
    .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4), .io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8),
    .io_out_complexDecodedInsts_4_bits_vpu_nf(x_io_out_complexDecodedInsts_4_bits_vpu_nf), .io_out_complexDecodedInsts_4_bits_vpu_veew(x_io_out_complexDecodedInsts_4_bits_vpu_veew), .io_out_complexDecodedInsts_4_bits_vpu_isReverse(x_io_out_complexDecodedInsts_4_bits_vpu_isReverse),
    .io_out_complexDecodedInsts_4_bits_vpu_isExt(x_io_out_complexDecodedInsts_4_bits_vpu_isExt), .io_out_complexDecodedInsts_4_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_4_bits_vpu_isNarrow), .io_out_complexDecodedInsts_4_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_4_bits_vpu_isDstMask),
    .io_out_complexDecodedInsts_4_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_4_bits_vpu_isOpMask), .io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd), .io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd),
    .io_out_complexDecodedInsts_4_bits_vpu_isVleff(x_io_out_complexDecodedInsts_4_bits_vpu_isVleff), .io_out_complexDecodedInsts_4_bits_vlsInstr(x_io_out_complexDecodedInsts_4_bits_vlsInstr), .io_out_complexDecodedInsts_4_bits_wfflags(x_io_out_complexDecodedInsts_4_bits_wfflags),
    .io_out_complexDecodedInsts_4_bits_isMove(x_io_out_complexDecodedInsts_4_bits_isMove), .io_out_complexDecodedInsts_4_bits_uopIdx(x_io_out_complexDecodedInsts_4_bits_uopIdx), .io_out_complexDecodedInsts_4_bits_uopSplitType(x_io_out_complexDecodedInsts_4_bits_uopSplitType),
    .io_out_complexDecodedInsts_4_bits_isVset(x_io_out_complexDecodedInsts_4_bits_isVset), .io_out_complexDecodedInsts_4_bits_lastUop(x_io_out_complexDecodedInsts_4_bits_lastUop), .io_out_complexDecodedInsts_4_bits_numUops(x_io_out_complexDecodedInsts_4_bits_numUops),
    .io_out_complexDecodedInsts_4_bits_numWB(x_io_out_complexDecodedInsts_4_bits_numWB), .io_out_complexDecodedInsts_4_bits_commitType(x_io_out_complexDecodedInsts_4_bits_commitType), .io_out_complexDecodedInsts_4_bits_debug_fuType(x_io_out_complexDecodedInsts_4_bits_debug_fuType),
    .io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx), .io_out_complexDecodedInsts_5_valid(x_io_out_complexDecodedInsts_5_valid),
    .io_out_complexDecodedInsts_5_bits_instr(x_io_out_complexDecodedInsts_5_bits_instr), .io_out_complexDecodedInsts_5_bits_pc(x_io_out_complexDecodedInsts_5_bits_pc), .io_out_complexDecodedInsts_5_bits_foldpc(x_io_out_complexDecodedInsts_5_bits_foldpc),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_0(x_io_out_complexDecodedInsts_5_bits_exceptionVec_0), .io_out_complexDecodedInsts_5_bits_exceptionVec_1(x_io_out_complexDecodedInsts_5_bits_exceptionVec_1), .io_out_complexDecodedInsts_5_bits_exceptionVec_2(x_io_out_complexDecodedInsts_5_bits_exceptionVec_2),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_3(x_io_out_complexDecodedInsts_5_bits_exceptionVec_3), .io_out_complexDecodedInsts_5_bits_exceptionVec_4(x_io_out_complexDecodedInsts_5_bits_exceptionVec_4), .io_out_complexDecodedInsts_5_bits_exceptionVec_5(x_io_out_complexDecodedInsts_5_bits_exceptionVec_5),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_6(x_io_out_complexDecodedInsts_5_bits_exceptionVec_6), .io_out_complexDecodedInsts_5_bits_exceptionVec_7(x_io_out_complexDecodedInsts_5_bits_exceptionVec_7), .io_out_complexDecodedInsts_5_bits_exceptionVec_8(x_io_out_complexDecodedInsts_5_bits_exceptionVec_8),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_9(x_io_out_complexDecodedInsts_5_bits_exceptionVec_9), .io_out_complexDecodedInsts_5_bits_exceptionVec_10(x_io_out_complexDecodedInsts_5_bits_exceptionVec_10), .io_out_complexDecodedInsts_5_bits_exceptionVec_11(x_io_out_complexDecodedInsts_5_bits_exceptionVec_11),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_12(x_io_out_complexDecodedInsts_5_bits_exceptionVec_12), .io_out_complexDecodedInsts_5_bits_exceptionVec_13(x_io_out_complexDecodedInsts_5_bits_exceptionVec_13), .io_out_complexDecodedInsts_5_bits_exceptionVec_14(x_io_out_complexDecodedInsts_5_bits_exceptionVec_14),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_15(x_io_out_complexDecodedInsts_5_bits_exceptionVec_15), .io_out_complexDecodedInsts_5_bits_exceptionVec_16(x_io_out_complexDecodedInsts_5_bits_exceptionVec_16), .io_out_complexDecodedInsts_5_bits_exceptionVec_17(x_io_out_complexDecodedInsts_5_bits_exceptionVec_17),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_18(x_io_out_complexDecodedInsts_5_bits_exceptionVec_18), .io_out_complexDecodedInsts_5_bits_exceptionVec_19(x_io_out_complexDecodedInsts_5_bits_exceptionVec_19), .io_out_complexDecodedInsts_5_bits_exceptionVec_20(x_io_out_complexDecodedInsts_5_bits_exceptionVec_20),
    .io_out_complexDecodedInsts_5_bits_exceptionVec_21(x_io_out_complexDecodedInsts_5_bits_exceptionVec_21), .io_out_complexDecodedInsts_5_bits_exceptionVec_22(x_io_out_complexDecodedInsts_5_bits_exceptionVec_22), .io_out_complexDecodedInsts_5_bits_exceptionVec_23(x_io_out_complexDecodedInsts_5_bits_exceptionVec_23),
    .io_out_complexDecodedInsts_5_bits_isFetchMalAddr(x_io_out_complexDecodedInsts_5_bits_isFetchMalAddr), .io_out_complexDecodedInsts_5_bits_trigger(x_io_out_complexDecodedInsts_5_bits_trigger), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid(x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC(x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType(x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType), .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall(x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall),
    .io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet(x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet), .io_out_complexDecodedInsts_5_bits_pred_taken(x_io_out_complexDecodedInsts_5_bits_pred_taken), .io_out_complexDecodedInsts_5_bits_crossPageIPFFix(x_io_out_complexDecodedInsts_5_bits_crossPageIPFFix),
    .io_out_complexDecodedInsts_5_bits_ftqPtr_flag(x_io_out_complexDecodedInsts_5_bits_ftqPtr_flag), .io_out_complexDecodedInsts_5_bits_ftqPtr_value(x_io_out_complexDecodedInsts_5_bits_ftqPtr_value), .io_out_complexDecodedInsts_5_bits_ftqOffset(x_io_out_complexDecodedInsts_5_bits_ftqOffset),
    .io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault(x_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault), .io_out_complexDecodedInsts_5_bits_srcType_0(x_io_out_complexDecodedInsts_5_bits_srcType_0), .io_out_complexDecodedInsts_5_bits_srcType_1(x_io_out_complexDecodedInsts_5_bits_srcType_1),
    .io_out_complexDecodedInsts_5_bits_srcType_2(x_io_out_complexDecodedInsts_5_bits_srcType_2), .io_out_complexDecodedInsts_5_bits_srcType_3(x_io_out_complexDecodedInsts_5_bits_srcType_3), .io_out_complexDecodedInsts_5_bits_srcType_4(x_io_out_complexDecodedInsts_5_bits_srcType_4),
    .io_out_complexDecodedInsts_5_bits_lsrc_0(x_io_out_complexDecodedInsts_5_bits_lsrc_0), .io_out_complexDecodedInsts_5_bits_lsrc_1(x_io_out_complexDecodedInsts_5_bits_lsrc_1), .io_out_complexDecodedInsts_5_bits_lsrc_2(x_io_out_complexDecodedInsts_5_bits_lsrc_2),
    .io_out_complexDecodedInsts_5_bits_ldest(x_io_out_complexDecodedInsts_5_bits_ldest), .io_out_complexDecodedInsts_5_bits_fuType(x_io_out_complexDecodedInsts_5_bits_fuType), .io_out_complexDecodedInsts_5_bits_fuOpType(x_io_out_complexDecodedInsts_5_bits_fuOpType),
    .io_out_complexDecodedInsts_5_bits_rfWen(x_io_out_complexDecodedInsts_5_bits_rfWen), .io_out_complexDecodedInsts_5_bits_fpWen(x_io_out_complexDecodedInsts_5_bits_fpWen), .io_out_complexDecodedInsts_5_bits_vecWen(x_io_out_complexDecodedInsts_5_bits_vecWen),
    .io_out_complexDecodedInsts_5_bits_vlWen(x_io_out_complexDecodedInsts_5_bits_vlWen), .io_out_complexDecodedInsts_5_bits_isXSTrap(x_io_out_complexDecodedInsts_5_bits_isXSTrap), .io_out_complexDecodedInsts_5_bits_waitForward(x_io_out_complexDecodedInsts_5_bits_waitForward),
    .io_out_complexDecodedInsts_5_bits_blockBackward(x_io_out_complexDecodedInsts_5_bits_blockBackward), .io_out_complexDecodedInsts_5_bits_flushPipe(x_io_out_complexDecodedInsts_5_bits_flushPipe), .io_out_complexDecodedInsts_5_bits_canRobCompress(x_io_out_complexDecodedInsts_5_bits_canRobCompress),
    .io_out_complexDecodedInsts_5_bits_selImm(x_io_out_complexDecodedInsts_5_bits_selImm), .io_out_complexDecodedInsts_5_bits_imm(x_io_out_complexDecodedInsts_5_bits_imm), .io_out_complexDecodedInsts_5_bits_fpu_typeTagOut(x_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut),
    .io_out_complexDecodedInsts_5_bits_fpu_wflags(x_io_out_complexDecodedInsts_5_bits_fpu_wflags), .io_out_complexDecodedInsts_5_bits_fpu_typ(x_io_out_complexDecodedInsts_5_bits_fpu_typ), .io_out_complexDecodedInsts_5_bits_fpu_fmt(x_io_out_complexDecodedInsts_5_bits_fpu_fmt),
    .io_out_complexDecodedInsts_5_bits_fpu_rm(x_io_out_complexDecodedInsts_5_bits_fpu_rm), .io_out_complexDecodedInsts_5_bits_vpu_vill(x_io_out_complexDecodedInsts_5_bits_vpu_vill), .io_out_complexDecodedInsts_5_bits_vpu_vma(x_io_out_complexDecodedInsts_5_bits_vpu_vma),
    .io_out_complexDecodedInsts_5_bits_vpu_vta(x_io_out_complexDecodedInsts_5_bits_vpu_vta), .io_out_complexDecodedInsts_5_bits_vpu_vsew(x_io_out_complexDecodedInsts_5_bits_vpu_vsew), .io_out_complexDecodedInsts_5_bits_vpu_vlmul(x_io_out_complexDecodedInsts_5_bits_vpu_vlmul),
    .io_out_complexDecodedInsts_5_bits_vpu_specVill(x_io_out_complexDecodedInsts_5_bits_vpu_specVill), .io_out_complexDecodedInsts_5_bits_vpu_specVma(x_io_out_complexDecodedInsts_5_bits_vpu_specVma), .io_out_complexDecodedInsts_5_bits_vpu_specVta(x_io_out_complexDecodedInsts_5_bits_vpu_specVta),
    .io_out_complexDecodedInsts_5_bits_vpu_specVsew(x_io_out_complexDecodedInsts_5_bits_vpu_specVsew), .io_out_complexDecodedInsts_5_bits_vpu_specVlmul(x_io_out_complexDecodedInsts_5_bits_vpu_specVlmul), .io_out_complexDecodedInsts_5_bits_vpu_vm(x_io_out_complexDecodedInsts_5_bits_vpu_vm),
    .io_out_complexDecodedInsts_5_bits_vpu_vstart(x_io_out_complexDecodedInsts_5_bits_vpu_vstart), .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2(x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2), .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4(x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4),
    .io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8(x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8), .io_out_complexDecodedInsts_5_bits_vpu_nf(x_io_out_complexDecodedInsts_5_bits_vpu_nf), .io_out_complexDecodedInsts_5_bits_vpu_veew(x_io_out_complexDecodedInsts_5_bits_vpu_veew),
    .io_out_complexDecodedInsts_5_bits_vpu_isReverse(x_io_out_complexDecodedInsts_5_bits_vpu_isReverse), .io_out_complexDecodedInsts_5_bits_vpu_isExt(x_io_out_complexDecodedInsts_5_bits_vpu_isExt), .io_out_complexDecodedInsts_5_bits_vpu_isNarrow(x_io_out_complexDecodedInsts_5_bits_vpu_isNarrow),
    .io_out_complexDecodedInsts_5_bits_vpu_isDstMask(x_io_out_complexDecodedInsts_5_bits_vpu_isDstMask), .io_out_complexDecodedInsts_5_bits_vpu_isOpMask(x_io_out_complexDecodedInsts_5_bits_vpu_isOpMask), .io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd(x_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd),
    .io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd(x_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd), .io_out_complexDecodedInsts_5_bits_vpu_isVleff(x_io_out_complexDecodedInsts_5_bits_vpu_isVleff), .io_out_complexDecodedInsts_5_bits_vlsInstr(x_io_out_complexDecodedInsts_5_bits_vlsInstr),
    .io_out_complexDecodedInsts_5_bits_wfflags(x_io_out_complexDecodedInsts_5_bits_wfflags), .io_out_complexDecodedInsts_5_bits_isMove(x_io_out_complexDecodedInsts_5_bits_isMove), .io_out_complexDecodedInsts_5_bits_uopIdx(x_io_out_complexDecodedInsts_5_bits_uopIdx),
    .io_out_complexDecodedInsts_5_bits_uopSplitType(x_io_out_complexDecodedInsts_5_bits_uopSplitType), .io_out_complexDecodedInsts_5_bits_isVset(x_io_out_complexDecodedInsts_5_bits_isVset), .io_out_complexDecodedInsts_5_bits_lastUop(x_io_out_complexDecodedInsts_5_bits_lastUop),
    .io_out_complexDecodedInsts_5_bits_numUops(x_io_out_complexDecodedInsts_5_bits_numUops), .io_out_complexDecodedInsts_5_bits_numWB(x_io_out_complexDecodedInsts_5_bits_numWB), .io_out_complexDecodedInsts_5_bits_commitType(x_io_out_complexDecodedInsts_5_bits_commitType),
    .io_out_complexDecodedInsts_5_bits_debug_fuType(x_io_out_complexDecodedInsts_5_bits_debug_fuType), .io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum(x_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum), .io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx(x_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx),
    .io_complexNum(x_io_complexNum)
  );


  // ---- 45 个已定义的 uopSplitType 编码（含 SCA_SIM 与 dummy）----
  localparam int NSPLIT = 45;
  logic [5:0] split_code [NSPLIT];
  string      split_name [NSPLIT];
  longint     cov_split  [64];
  longint     cov_split_vlmul [64][8];
  longint     cov_count  [16];
  longint     cov_state  [2];
  longint     cov_redir_active = 0;
  longint     cov_numuop_gt6 = 0;
  longint     cov_backpressure = 0;
  longint     cov_widen_osum = 0;   // VEC_VFREDOSUM 的「加宽」支
  longint     cov_plain_osum = 0;   // VEC_VFREDOSUM 的「非加宽」支
  longint     cov_us_seg = 0, cov_ix_seg = 0, cov_sd_seg = 0;  // 三种段访存

  initial begin
    split_code[0] = 6'h00; split_name[0] = "SCA_SIM";
    split_code[1] = 6'h04; split_name[1] = "VEC_MVNR";
    split_code[2] = 6'h11; split_name[2] = "VSET";
    split_code[3] = 6'h12; split_name[3] = "VEC_VVV";
    split_code[4] = 6'h13; split_name[4] = "VEC_VXV";
    split_code[5] = 6'h14; split_name[5] = "VEC_0XV";
    split_code[6] = 6'h15; split_name[6] = "VEC_VVW";
    split_code[7] = 6'h16; split_name[7] = "VEC_WVW";
    split_code[8] = 6'h17; split_name[8] = "VEC_VXW";
    split_code[9] = 6'h18; split_name[9] = "VEC_WXW";
    split_code[10] = 6'h19; split_name[10] = "VEC_WVV";
    split_code[11] = 6'h1A; split_name[11] = "VEC_WXV";
    split_code[12] = 6'h1B; split_name[12] = "VEC_EXT2";
    split_code[13] = 6'h1C; split_name[13] = "VEC_EXT4";
    split_code[14] = 6'h1D; split_name[14] = "VEC_EXT8";
    split_code[15] = 6'h1E; split_name[15] = "VEC_VVM";
    split_code[16] = 6'h1F; split_name[16] = "VEC_VXM";
    split_code[17] = 6'h20; split_name[17] = "VEC_SLIDE1UP";
    split_code[18] = 6'h21; split_name[18] = "VEC_FSLIDE1UP";
    split_code[19] = 6'h22; split_name[19] = "VEC_SLIDE1DOWN";
    split_code[20] = 6'h23; split_name[20] = "VEC_FSLIDE1DOWN";
    split_code[21] = 6'h24; split_name[21] = "VEC_VRED";
    split_code[22] = 6'h25; split_name[22] = "VEC_SLIDEUP";
    split_code[23] = 6'h27; split_name[23] = "VEC_SLIDEDOWN";
    split_code[24] = 6'h29; split_name[24] = "VEC_M0X";
    split_code[25] = 6'h2A; split_name[25] = "VEC_MVV";
    split_code[26] = 6'h2C; split_name[26] = "VEC_VWW";
    split_code[27] = 6'h2D; split_name[27] = "VEC_RGATHER";
    split_code[28] = 6'h2E; split_name[28] = "VEC_RGATHER_VX";
    split_code[29] = 6'h2F; split_name[29] = "VEC_RGATHEREI16";
    split_code[30] = 6'h30; split_name[30] = "VEC_COMPRESS";
    split_code[31] = 6'h31; split_name[31] = "VEC_US_LDST";
    split_code[32] = 6'h32; split_name[32] = "VEC_S_LDST";
    split_code[33] = 6'h33; split_name[33] = "VEC_I_LDST";
    split_code[34] = 6'h34; split_name[34] = "VEC_US_FF_LD";
    split_code[35] = 6'h35; split_name[35] = "AMO_CAS_W";
    split_code[36] = 6'h36; split_name[36] = "AMO_CAS_D";
    split_code[37] = 6'h37; split_name[37] = "AMO_CAS_Q";
    split_code[38] = 6'h38; split_name[38] = "VEC_VFV";
    split_code[39] = 6'h39; split_name[39] = "VEC_VFW";
    split_code[40] = 6'h3A; split_name[40] = "VEC_WFW";
    split_code[41] = 6'h3B; split_name[41] = "VEC_VFM";
    split_code[42] = 6'h3C; split_name[42] = "VEC_VFRED";
    split_code[43] = 6'h3D; split_name[43] = "VEC_VFREDOSUM";
    split_code[44] = 6'h3F; split_name[44] = "dummy";
  end

  // numOfUop 的取值分布：小值（一拍出完）/ 刚过 6（count 走一两格）/
  // 大值（count 走到 10）/ 0（golden 有断言的非法值，输出仍须一致）。
  function automatic logic [6:0] gen_numuop();
    case ($urandom_range(0, 9))
      0:       return 7'd0;
      1, 2, 3: return 7'($urandom_range(1, 6));
      4, 5:    return 7'($urandom_range(7, 16));
      6, 7:    return 7'($urandom_range(17, 48));
      default: return 7'($urandom_range(49, 65));
    endcase
  endfunction

  // out0_ready 做成长条：连续若干拍全 1 或全 0，制造 count 连续推进与反压。
  int ready_run = 0;
  logic ready_lvl = 1'b1;
  function automatic logic next_ready();
    if (ready_run == 0) begin
      ready_run = $urandom_range(1, 12);
      ready_lvl = ($urandom_range(0, 3) != 0);   // 3/4 概率给 ready
    end
    ready_run--;
    return ready_lvl;
  endfunction

  task automatic drive_random_inputs();
    // 先给**所有**输入一份随机值（包括 75 个纯直通字段，它们的接线错也要能抓到），
    // 再把有判别力的几个覆盖掉。
    io_redirect = 1'($urandom);
    io_vtypeBypass_illegal = 1'($urandom);
    io_vtypeBypass_vma = 1'($urandom);
    io_vtypeBypass_vta = 1'($urandom);
    io_vtypeBypass_vsew = 2'($urandom);
    io_vtypeBypass_vlmul = 3'($urandom);
    io_in_valid = 1'($urandom);
    io_in_bits_simpleDecodedInst_instr = 32'($urandom);
    io_in_bits_simpleDecodedInst_pc = {50'($urandom), 50'($urandom)} ^ 50'($urandom);
    io_in_bits_simpleDecodedInst_foldpc = 10'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_0 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_1 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_2 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_3 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_4 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_5 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_6 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_7 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_8 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_9 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_10 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_11 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_12 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_13 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_14 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_15 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_16 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_17 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_18 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_19 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_20 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_21 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_22 = 1'($urandom);
    io_in_bits_simpleDecodedInst_exceptionVec_23 = 1'($urandom);
    io_in_bits_simpleDecodedInst_isFetchMalAddr = 1'($urandom);
    io_in_bits_simpleDecodedInst_trigger = 4'($urandom);
    io_in_bits_simpleDecodedInst_preDecodeInfo_valid = 1'($urandom);
    io_in_bits_simpleDecodedInst_preDecodeInfo_isRVC = 1'($urandom);
    io_in_bits_simpleDecodedInst_preDecodeInfo_brType = 2'($urandom);
    io_in_bits_simpleDecodedInst_preDecodeInfo_isCall = 1'($urandom);
    io_in_bits_simpleDecodedInst_preDecodeInfo_isRet = 1'($urandom);
    io_in_bits_simpleDecodedInst_pred_taken = 1'($urandom);
    io_in_bits_simpleDecodedInst_crossPageIPFFix = 1'($urandom);
    io_in_bits_simpleDecodedInst_ftqPtr_flag = 1'($urandom);
    io_in_bits_simpleDecodedInst_ftqPtr_value = 6'($urandom);
    io_in_bits_simpleDecodedInst_ftqOffset = 4'($urandom);
    io_in_bits_simpleDecodedInst_satpFlushFirstFetchFault = 1'($urandom);
    io_in_bits_simpleDecodedInst_srcType_0 = 4'($urandom);
    io_in_bits_simpleDecodedInst_srcType_1 = 4'($urandom);
    io_in_bits_simpleDecodedInst_srcType_2 = 4'($urandom);
    io_in_bits_simpleDecodedInst_srcType_3 = 4'($urandom);
    io_in_bits_simpleDecodedInst_srcType_4 = 4'($urandom);
    io_in_bits_simpleDecodedInst_lsrc_0 = 6'($urandom);
    io_in_bits_simpleDecodedInst_lsrc_1 = 6'($urandom);
    io_in_bits_simpleDecodedInst_lsrc_2 = 6'($urandom);
    io_in_bits_simpleDecodedInst_ldest = 6'($urandom);
    io_in_bits_simpleDecodedInst_fuType = {35'($urandom), 35'($urandom)} ^ 35'($urandom);
    io_in_bits_simpleDecodedInst_fuOpType = 9'($urandom);
    io_in_bits_simpleDecodedInst_rfWen = 1'($urandom);
    io_in_bits_simpleDecodedInst_fpWen = 1'($urandom);
    io_in_bits_simpleDecodedInst_vecWen = 1'($urandom);
    io_in_bits_simpleDecodedInst_isXSTrap = 1'($urandom);
    io_in_bits_simpleDecodedInst_waitForward = 1'($urandom);
    io_in_bits_simpleDecodedInst_blockBackward = 1'($urandom);
    io_in_bits_simpleDecodedInst_flushPipe = 1'($urandom);
    io_in_bits_simpleDecodedInst_canRobCompress = 1'($urandom);
    io_in_bits_simpleDecodedInst_selImm = 4'($urandom);
    io_in_bits_simpleDecodedInst_imm = 22'($urandom);
    io_in_bits_simpleDecodedInst_fpu_typeTagOut = 2'($urandom);
    io_in_bits_simpleDecodedInst_fpu_wflags = 1'($urandom);
    io_in_bits_simpleDecodedInst_fpu_typ = 2'($urandom);
    io_in_bits_simpleDecodedInst_fpu_fmt = 2'($urandom);
    io_in_bits_simpleDecodedInst_fpu_rm = 3'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vill = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vma = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vta = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vsew = 2'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vlmul = 3'($urandom);
    io_in_bits_simpleDecodedInst_vpu_specVill = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_specVma = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_specVta = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_specVsew = 2'($urandom);
    io_in_bits_simpleDecodedInst_vpu_specVlmul = 3'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vm = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_vstart = 8'($urandom);
    io_in_bits_simpleDecodedInst_vpu_nf = 3'($urandom);
    io_in_bits_simpleDecodedInst_vpu_veew = 2'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isReverse = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isExt = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isNarrow = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isDstMask = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isOpMask = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isDependOldVd = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isWritePartVd = 1'($urandom);
    io_in_bits_simpleDecodedInst_vpu_isVleff = 1'($urandom);
    io_in_bits_simpleDecodedInst_wfflags = 1'($urandom);
    io_in_bits_simpleDecodedInst_isMove = 1'($urandom);
    io_in_bits_simpleDecodedInst_uopSplitType = 6'($urandom);
    io_in_bits_simpleDecodedInst_isVset = 1'($urandom);
    io_in_bits_simpleDecodedInst_commitType = 3'($urandom);
    io_in_bits_simpleDecodedInst_debug_fuType = {35'($urandom), 35'($urandom)} ^ 35'($urandom);
    io_in_bits_simpleDecodedInst_debug_seqNum_seqNum = {56'($urandom), 56'($urandom)} ^ 56'($urandom);
    io_in_bits_simpleDecodedInst_debug_seqNum_uopIdx = 8'($urandom);
    io_in_bits_uopInfo_numOfUop = 7'($urandom);
    io_in_bits_uopInfo_numOfWB = 7'($urandom);
    io_in_bits_uopInfo_lmul = 4'($urandom);
    io_out_complexDecodedInsts_0_ready = 1'($urandom);
  endtask

  task automatic compare_outputs();
    checks++;
    if (g_io_in_ready !== x_io_in_ready) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_in_ready: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_in_ready, x_io_in_ready, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_valid !== x_io_out_complexDecodedInsts_0_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_valid, x_io_out_complexDecodedInsts_0_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_instr !== x_io_out_complexDecodedInsts_0_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_instr, x_io_out_complexDecodedInsts_0_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_pc !== x_io_out_complexDecodedInsts_0_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_pc, x_io_out_complexDecodedInsts_0_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_foldpc !== x_io_out_complexDecodedInsts_0_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_foldpc, x_io_out_complexDecodedInsts_0_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_0, x_io_out_complexDecodedInsts_0_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_1, x_io_out_complexDecodedInsts_0_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_2, x_io_out_complexDecodedInsts_0_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_3, x_io_out_complexDecodedInsts_0_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_4, x_io_out_complexDecodedInsts_0_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_5, x_io_out_complexDecodedInsts_0_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_6, x_io_out_complexDecodedInsts_0_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_7, x_io_out_complexDecodedInsts_0_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_8, x_io_out_complexDecodedInsts_0_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_9, x_io_out_complexDecodedInsts_0_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_10, x_io_out_complexDecodedInsts_0_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_11, x_io_out_complexDecodedInsts_0_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_12, x_io_out_complexDecodedInsts_0_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_13, x_io_out_complexDecodedInsts_0_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_14, x_io_out_complexDecodedInsts_0_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_15, x_io_out_complexDecodedInsts_0_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_16, x_io_out_complexDecodedInsts_0_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_17, x_io_out_complexDecodedInsts_0_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_18, x_io_out_complexDecodedInsts_0_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_19, x_io_out_complexDecodedInsts_0_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_20, x_io_out_complexDecodedInsts_0_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_21, x_io_out_complexDecodedInsts_0_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_22, x_io_out_complexDecodedInsts_0_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_0_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_exceptionVec_23, x_io_out_complexDecodedInsts_0_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_0_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_0_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_trigger !== x_io_out_complexDecodedInsts_0_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_trigger, x_io_out_complexDecodedInsts_0_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_0_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_pred_taken !== x_io_out_complexDecodedInsts_0_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_pred_taken, x_io_out_complexDecodedInsts_0_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_0_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_0_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_0_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_0_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_0_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_ftqPtr_value, x_io_out_complexDecodedInsts_0_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_ftqOffset !== x_io_out_complexDecodedInsts_0_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_ftqOffset, x_io_out_complexDecodedInsts_0_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_0_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_srcType_0 !== x_io_out_complexDecodedInsts_0_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_srcType_0, x_io_out_complexDecodedInsts_0_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_srcType_1 !== x_io_out_complexDecodedInsts_0_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_srcType_1, x_io_out_complexDecodedInsts_0_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_srcType_2 !== x_io_out_complexDecodedInsts_0_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_srcType_2, x_io_out_complexDecodedInsts_0_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_srcType_3 !== x_io_out_complexDecodedInsts_0_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_srcType_3, x_io_out_complexDecodedInsts_0_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_srcType_4 !== x_io_out_complexDecodedInsts_0_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_srcType_4, x_io_out_complexDecodedInsts_0_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_lsrc_0 !== x_io_out_complexDecodedInsts_0_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_lsrc_0, x_io_out_complexDecodedInsts_0_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_lsrc_1 !== x_io_out_complexDecodedInsts_0_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_lsrc_1, x_io_out_complexDecodedInsts_0_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_lsrc_2 !== x_io_out_complexDecodedInsts_0_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_lsrc_2, x_io_out_complexDecodedInsts_0_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_ldest !== x_io_out_complexDecodedInsts_0_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_ldest, x_io_out_complexDecodedInsts_0_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fuType !== x_io_out_complexDecodedInsts_0_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fuType, x_io_out_complexDecodedInsts_0_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fuOpType !== x_io_out_complexDecodedInsts_0_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fuOpType, x_io_out_complexDecodedInsts_0_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_rfWen !== x_io_out_complexDecodedInsts_0_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_rfWen, x_io_out_complexDecodedInsts_0_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpWen !== x_io_out_complexDecodedInsts_0_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpWen, x_io_out_complexDecodedInsts_0_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vecWen !== x_io_out_complexDecodedInsts_0_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vecWen, x_io_out_complexDecodedInsts_0_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vlWen !== x_io_out_complexDecodedInsts_0_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vlWen, x_io_out_complexDecodedInsts_0_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_isXSTrap !== x_io_out_complexDecodedInsts_0_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_isXSTrap, x_io_out_complexDecodedInsts_0_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_waitForward !== x_io_out_complexDecodedInsts_0_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_waitForward, x_io_out_complexDecodedInsts_0_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_blockBackward !== x_io_out_complexDecodedInsts_0_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_blockBackward, x_io_out_complexDecodedInsts_0_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_flushPipe !== x_io_out_complexDecodedInsts_0_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_flushPipe, x_io_out_complexDecodedInsts_0_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_canRobCompress !== x_io_out_complexDecodedInsts_0_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_canRobCompress, x_io_out_complexDecodedInsts_0_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_selImm !== x_io_out_complexDecodedInsts_0_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_selImm, x_io_out_complexDecodedInsts_0_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_imm !== x_io_out_complexDecodedInsts_0_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_imm, x_io_out_complexDecodedInsts_0_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_0_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpu_wflags !== x_io_out_complexDecodedInsts_0_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpu_wflags, x_io_out_complexDecodedInsts_0_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpu_typ !== x_io_out_complexDecodedInsts_0_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpu_typ, x_io_out_complexDecodedInsts_0_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpu_fmt !== x_io_out_complexDecodedInsts_0_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpu_fmt, x_io_out_complexDecodedInsts_0_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_fpu_rm !== x_io_out_complexDecodedInsts_0_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_fpu_rm, x_io_out_complexDecodedInsts_0_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vill !== x_io_out_complexDecodedInsts_0_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vill, x_io_out_complexDecodedInsts_0_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vma !== x_io_out_complexDecodedInsts_0_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vma, x_io_out_complexDecodedInsts_0_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vta !== x_io_out_complexDecodedInsts_0_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vta, x_io_out_complexDecodedInsts_0_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vsew !== x_io_out_complexDecodedInsts_0_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vsew, x_io_out_complexDecodedInsts_0_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_0_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vlmul, x_io_out_complexDecodedInsts_0_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_specVill !== x_io_out_complexDecodedInsts_0_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_specVill, x_io_out_complexDecodedInsts_0_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_specVma !== x_io_out_complexDecodedInsts_0_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_specVma, x_io_out_complexDecodedInsts_0_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_specVta !== x_io_out_complexDecodedInsts_0_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_specVta, x_io_out_complexDecodedInsts_0_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_0_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_specVsew, x_io_out_complexDecodedInsts_0_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_0_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_0_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vm !== x_io_out_complexDecodedInsts_0_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vm, x_io_out_complexDecodedInsts_0_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_vstart !== x_io_out_complexDecodedInsts_0_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_vstart, x_io_out_complexDecodedInsts_0_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_0_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_nf !== x_io_out_complexDecodedInsts_0_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_nf, x_io_out_complexDecodedInsts_0_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_veew !== x_io_out_complexDecodedInsts_0_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_veew, x_io_out_complexDecodedInsts_0_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_0_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isReverse, x_io_out_complexDecodedInsts_0_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isExt !== x_io_out_complexDecodedInsts_0_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isExt, x_io_out_complexDecodedInsts_0_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_0_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_0_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_0_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_0_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_0_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_0_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_0_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_0_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_0_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vpu_isVleff, x_io_out_complexDecodedInsts_0_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_vlsInstr !== x_io_out_complexDecodedInsts_0_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_vlsInstr, x_io_out_complexDecodedInsts_0_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_wfflags !== x_io_out_complexDecodedInsts_0_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_wfflags, x_io_out_complexDecodedInsts_0_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_isMove !== x_io_out_complexDecodedInsts_0_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_isMove, x_io_out_complexDecodedInsts_0_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_uopIdx !== x_io_out_complexDecodedInsts_0_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_uopIdx, x_io_out_complexDecodedInsts_0_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_uopSplitType !== x_io_out_complexDecodedInsts_0_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_uopSplitType, x_io_out_complexDecodedInsts_0_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_isVset !== x_io_out_complexDecodedInsts_0_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_isVset, x_io_out_complexDecodedInsts_0_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_firstUop !== x_io_out_complexDecodedInsts_0_bits_firstUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_firstUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_firstUop, x_io_out_complexDecodedInsts_0_bits_firstUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_lastUop !== x_io_out_complexDecodedInsts_0_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_lastUop, x_io_out_complexDecodedInsts_0_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_numUops !== x_io_out_complexDecodedInsts_0_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_numUops, x_io_out_complexDecodedInsts_0_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_numWB !== x_io_out_complexDecodedInsts_0_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_numWB, x_io_out_complexDecodedInsts_0_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_commitType !== x_io_out_complexDecodedInsts_0_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_commitType, x_io_out_complexDecodedInsts_0_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_debug_fuType !== x_io_out_complexDecodedInsts_0_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_debug_fuType, x_io_out_complexDecodedInsts_0_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_0_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_0_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_valid !== x_io_out_complexDecodedInsts_1_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_valid, x_io_out_complexDecodedInsts_1_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_instr !== x_io_out_complexDecodedInsts_1_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_instr, x_io_out_complexDecodedInsts_1_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_pc !== x_io_out_complexDecodedInsts_1_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_pc, x_io_out_complexDecodedInsts_1_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_foldpc !== x_io_out_complexDecodedInsts_1_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_foldpc, x_io_out_complexDecodedInsts_1_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_0, x_io_out_complexDecodedInsts_1_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_1, x_io_out_complexDecodedInsts_1_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_2, x_io_out_complexDecodedInsts_1_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_3, x_io_out_complexDecodedInsts_1_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_4, x_io_out_complexDecodedInsts_1_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_5, x_io_out_complexDecodedInsts_1_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_6, x_io_out_complexDecodedInsts_1_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_7, x_io_out_complexDecodedInsts_1_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_8, x_io_out_complexDecodedInsts_1_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_9, x_io_out_complexDecodedInsts_1_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_10, x_io_out_complexDecodedInsts_1_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_11, x_io_out_complexDecodedInsts_1_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_12, x_io_out_complexDecodedInsts_1_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_13, x_io_out_complexDecodedInsts_1_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_14, x_io_out_complexDecodedInsts_1_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_15, x_io_out_complexDecodedInsts_1_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_16, x_io_out_complexDecodedInsts_1_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_17, x_io_out_complexDecodedInsts_1_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_18, x_io_out_complexDecodedInsts_1_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_19, x_io_out_complexDecodedInsts_1_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_20, x_io_out_complexDecodedInsts_1_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_21, x_io_out_complexDecodedInsts_1_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_22, x_io_out_complexDecodedInsts_1_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_1_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_exceptionVec_23, x_io_out_complexDecodedInsts_1_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_1_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_1_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_trigger !== x_io_out_complexDecodedInsts_1_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_trigger, x_io_out_complexDecodedInsts_1_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_1_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_pred_taken !== x_io_out_complexDecodedInsts_1_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_pred_taken, x_io_out_complexDecodedInsts_1_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_1_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_1_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_1_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_1_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_1_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_ftqPtr_value, x_io_out_complexDecodedInsts_1_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_ftqOffset !== x_io_out_complexDecodedInsts_1_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_ftqOffset, x_io_out_complexDecodedInsts_1_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_1_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_srcType_0 !== x_io_out_complexDecodedInsts_1_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_srcType_0, x_io_out_complexDecodedInsts_1_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_srcType_1 !== x_io_out_complexDecodedInsts_1_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_srcType_1, x_io_out_complexDecodedInsts_1_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_srcType_2 !== x_io_out_complexDecodedInsts_1_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_srcType_2, x_io_out_complexDecodedInsts_1_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_srcType_3 !== x_io_out_complexDecodedInsts_1_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_srcType_3, x_io_out_complexDecodedInsts_1_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_srcType_4 !== x_io_out_complexDecodedInsts_1_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_srcType_4, x_io_out_complexDecodedInsts_1_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_lsrc_0 !== x_io_out_complexDecodedInsts_1_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_lsrc_0, x_io_out_complexDecodedInsts_1_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_lsrc_1 !== x_io_out_complexDecodedInsts_1_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_lsrc_1, x_io_out_complexDecodedInsts_1_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_lsrc_2 !== x_io_out_complexDecodedInsts_1_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_lsrc_2, x_io_out_complexDecodedInsts_1_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_ldest !== x_io_out_complexDecodedInsts_1_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_ldest, x_io_out_complexDecodedInsts_1_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fuType !== x_io_out_complexDecodedInsts_1_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fuType, x_io_out_complexDecodedInsts_1_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fuOpType !== x_io_out_complexDecodedInsts_1_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fuOpType, x_io_out_complexDecodedInsts_1_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_rfWen !== x_io_out_complexDecodedInsts_1_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_rfWen, x_io_out_complexDecodedInsts_1_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpWen !== x_io_out_complexDecodedInsts_1_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpWen, x_io_out_complexDecodedInsts_1_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vecWen !== x_io_out_complexDecodedInsts_1_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vecWen, x_io_out_complexDecodedInsts_1_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vlWen !== x_io_out_complexDecodedInsts_1_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vlWen, x_io_out_complexDecodedInsts_1_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_isXSTrap !== x_io_out_complexDecodedInsts_1_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_isXSTrap, x_io_out_complexDecodedInsts_1_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_waitForward !== x_io_out_complexDecodedInsts_1_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_waitForward, x_io_out_complexDecodedInsts_1_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_blockBackward !== x_io_out_complexDecodedInsts_1_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_blockBackward, x_io_out_complexDecodedInsts_1_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_flushPipe !== x_io_out_complexDecodedInsts_1_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_flushPipe, x_io_out_complexDecodedInsts_1_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_canRobCompress !== x_io_out_complexDecodedInsts_1_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_canRobCompress, x_io_out_complexDecodedInsts_1_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_selImm !== x_io_out_complexDecodedInsts_1_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_selImm, x_io_out_complexDecodedInsts_1_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_imm !== x_io_out_complexDecodedInsts_1_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_imm, x_io_out_complexDecodedInsts_1_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_1_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpu_wflags !== x_io_out_complexDecodedInsts_1_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpu_wflags, x_io_out_complexDecodedInsts_1_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpu_typ !== x_io_out_complexDecodedInsts_1_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpu_typ, x_io_out_complexDecodedInsts_1_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpu_fmt !== x_io_out_complexDecodedInsts_1_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpu_fmt, x_io_out_complexDecodedInsts_1_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_fpu_rm !== x_io_out_complexDecodedInsts_1_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_fpu_rm, x_io_out_complexDecodedInsts_1_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vill !== x_io_out_complexDecodedInsts_1_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vill, x_io_out_complexDecodedInsts_1_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vma !== x_io_out_complexDecodedInsts_1_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vma, x_io_out_complexDecodedInsts_1_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vta !== x_io_out_complexDecodedInsts_1_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vta, x_io_out_complexDecodedInsts_1_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vsew !== x_io_out_complexDecodedInsts_1_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vsew, x_io_out_complexDecodedInsts_1_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_1_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vlmul, x_io_out_complexDecodedInsts_1_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_specVill !== x_io_out_complexDecodedInsts_1_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_specVill, x_io_out_complexDecodedInsts_1_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_specVma !== x_io_out_complexDecodedInsts_1_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_specVma, x_io_out_complexDecodedInsts_1_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_specVta !== x_io_out_complexDecodedInsts_1_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_specVta, x_io_out_complexDecodedInsts_1_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_1_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_specVsew, x_io_out_complexDecodedInsts_1_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_1_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_1_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vm !== x_io_out_complexDecodedInsts_1_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vm, x_io_out_complexDecodedInsts_1_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_vstart !== x_io_out_complexDecodedInsts_1_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_vstart, x_io_out_complexDecodedInsts_1_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_1_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_nf !== x_io_out_complexDecodedInsts_1_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_nf, x_io_out_complexDecodedInsts_1_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_veew !== x_io_out_complexDecodedInsts_1_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_veew, x_io_out_complexDecodedInsts_1_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_1_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isReverse, x_io_out_complexDecodedInsts_1_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isExt !== x_io_out_complexDecodedInsts_1_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isExt, x_io_out_complexDecodedInsts_1_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_1_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_1_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_1_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_1_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_1_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_1_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_1_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_1_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_1_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vpu_isVleff, x_io_out_complexDecodedInsts_1_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_vlsInstr !== x_io_out_complexDecodedInsts_1_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_vlsInstr, x_io_out_complexDecodedInsts_1_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_wfflags !== x_io_out_complexDecodedInsts_1_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_wfflags, x_io_out_complexDecodedInsts_1_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_isMove !== x_io_out_complexDecodedInsts_1_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_isMove, x_io_out_complexDecodedInsts_1_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_uopIdx !== x_io_out_complexDecodedInsts_1_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_uopIdx, x_io_out_complexDecodedInsts_1_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_uopSplitType !== x_io_out_complexDecodedInsts_1_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_uopSplitType, x_io_out_complexDecodedInsts_1_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_isVset !== x_io_out_complexDecodedInsts_1_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_isVset, x_io_out_complexDecodedInsts_1_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_lastUop !== x_io_out_complexDecodedInsts_1_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_lastUop, x_io_out_complexDecodedInsts_1_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_numUops !== x_io_out_complexDecodedInsts_1_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_numUops, x_io_out_complexDecodedInsts_1_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_numWB !== x_io_out_complexDecodedInsts_1_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_numWB, x_io_out_complexDecodedInsts_1_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_commitType !== x_io_out_complexDecodedInsts_1_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_commitType, x_io_out_complexDecodedInsts_1_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_debug_fuType !== x_io_out_complexDecodedInsts_1_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_debug_fuType, x_io_out_complexDecodedInsts_1_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_1_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_1_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_valid !== x_io_out_complexDecodedInsts_2_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_valid, x_io_out_complexDecodedInsts_2_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_instr !== x_io_out_complexDecodedInsts_2_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_instr, x_io_out_complexDecodedInsts_2_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_pc !== x_io_out_complexDecodedInsts_2_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_pc, x_io_out_complexDecodedInsts_2_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_foldpc !== x_io_out_complexDecodedInsts_2_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_foldpc, x_io_out_complexDecodedInsts_2_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_0, x_io_out_complexDecodedInsts_2_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_1, x_io_out_complexDecodedInsts_2_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_2, x_io_out_complexDecodedInsts_2_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_3, x_io_out_complexDecodedInsts_2_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_4, x_io_out_complexDecodedInsts_2_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_5, x_io_out_complexDecodedInsts_2_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_6, x_io_out_complexDecodedInsts_2_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_7, x_io_out_complexDecodedInsts_2_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_8, x_io_out_complexDecodedInsts_2_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_9, x_io_out_complexDecodedInsts_2_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_10, x_io_out_complexDecodedInsts_2_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_11, x_io_out_complexDecodedInsts_2_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_12, x_io_out_complexDecodedInsts_2_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_13, x_io_out_complexDecodedInsts_2_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_14, x_io_out_complexDecodedInsts_2_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_15, x_io_out_complexDecodedInsts_2_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_16, x_io_out_complexDecodedInsts_2_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_17, x_io_out_complexDecodedInsts_2_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_18, x_io_out_complexDecodedInsts_2_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_19, x_io_out_complexDecodedInsts_2_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_20, x_io_out_complexDecodedInsts_2_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_21, x_io_out_complexDecodedInsts_2_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_22, x_io_out_complexDecodedInsts_2_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_2_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_exceptionVec_23, x_io_out_complexDecodedInsts_2_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_2_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_2_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_trigger !== x_io_out_complexDecodedInsts_2_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_trigger, x_io_out_complexDecodedInsts_2_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_2_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_pred_taken !== x_io_out_complexDecodedInsts_2_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_pred_taken, x_io_out_complexDecodedInsts_2_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_2_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_2_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_2_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_2_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_2_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_ftqPtr_value, x_io_out_complexDecodedInsts_2_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_ftqOffset !== x_io_out_complexDecodedInsts_2_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_ftqOffset, x_io_out_complexDecodedInsts_2_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_2_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_srcType_0 !== x_io_out_complexDecodedInsts_2_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_srcType_0, x_io_out_complexDecodedInsts_2_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_srcType_1 !== x_io_out_complexDecodedInsts_2_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_srcType_1, x_io_out_complexDecodedInsts_2_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_srcType_2 !== x_io_out_complexDecodedInsts_2_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_srcType_2, x_io_out_complexDecodedInsts_2_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_srcType_3 !== x_io_out_complexDecodedInsts_2_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_srcType_3, x_io_out_complexDecodedInsts_2_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_srcType_4 !== x_io_out_complexDecodedInsts_2_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_srcType_4, x_io_out_complexDecodedInsts_2_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_lsrc_0 !== x_io_out_complexDecodedInsts_2_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_lsrc_0, x_io_out_complexDecodedInsts_2_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_lsrc_1 !== x_io_out_complexDecodedInsts_2_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_lsrc_1, x_io_out_complexDecodedInsts_2_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_lsrc_2 !== x_io_out_complexDecodedInsts_2_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_lsrc_2, x_io_out_complexDecodedInsts_2_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_ldest !== x_io_out_complexDecodedInsts_2_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_ldest, x_io_out_complexDecodedInsts_2_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fuType !== x_io_out_complexDecodedInsts_2_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fuType, x_io_out_complexDecodedInsts_2_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fuOpType !== x_io_out_complexDecodedInsts_2_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fuOpType, x_io_out_complexDecodedInsts_2_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_rfWen !== x_io_out_complexDecodedInsts_2_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_rfWen, x_io_out_complexDecodedInsts_2_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpWen !== x_io_out_complexDecodedInsts_2_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpWen, x_io_out_complexDecodedInsts_2_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vecWen !== x_io_out_complexDecodedInsts_2_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vecWen, x_io_out_complexDecodedInsts_2_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vlWen !== x_io_out_complexDecodedInsts_2_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vlWen, x_io_out_complexDecodedInsts_2_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_isXSTrap !== x_io_out_complexDecodedInsts_2_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_isXSTrap, x_io_out_complexDecodedInsts_2_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_waitForward !== x_io_out_complexDecodedInsts_2_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_waitForward, x_io_out_complexDecodedInsts_2_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_blockBackward !== x_io_out_complexDecodedInsts_2_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_blockBackward, x_io_out_complexDecodedInsts_2_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_flushPipe !== x_io_out_complexDecodedInsts_2_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_flushPipe, x_io_out_complexDecodedInsts_2_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_canRobCompress !== x_io_out_complexDecodedInsts_2_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_canRobCompress, x_io_out_complexDecodedInsts_2_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_selImm !== x_io_out_complexDecodedInsts_2_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_selImm, x_io_out_complexDecodedInsts_2_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_imm !== x_io_out_complexDecodedInsts_2_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_imm, x_io_out_complexDecodedInsts_2_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_2_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpu_wflags !== x_io_out_complexDecodedInsts_2_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpu_wflags, x_io_out_complexDecodedInsts_2_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpu_typ !== x_io_out_complexDecodedInsts_2_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpu_typ, x_io_out_complexDecodedInsts_2_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpu_fmt !== x_io_out_complexDecodedInsts_2_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpu_fmt, x_io_out_complexDecodedInsts_2_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_fpu_rm !== x_io_out_complexDecodedInsts_2_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_fpu_rm, x_io_out_complexDecodedInsts_2_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vill !== x_io_out_complexDecodedInsts_2_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vill, x_io_out_complexDecodedInsts_2_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vma !== x_io_out_complexDecodedInsts_2_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vma, x_io_out_complexDecodedInsts_2_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vta !== x_io_out_complexDecodedInsts_2_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vta, x_io_out_complexDecodedInsts_2_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vsew !== x_io_out_complexDecodedInsts_2_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vsew, x_io_out_complexDecodedInsts_2_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_2_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vlmul, x_io_out_complexDecodedInsts_2_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_specVill !== x_io_out_complexDecodedInsts_2_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_specVill, x_io_out_complexDecodedInsts_2_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_specVma !== x_io_out_complexDecodedInsts_2_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_specVma, x_io_out_complexDecodedInsts_2_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_specVta !== x_io_out_complexDecodedInsts_2_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_specVta, x_io_out_complexDecodedInsts_2_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_2_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_specVsew, x_io_out_complexDecodedInsts_2_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_2_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_2_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vm !== x_io_out_complexDecodedInsts_2_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vm, x_io_out_complexDecodedInsts_2_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_vstart !== x_io_out_complexDecodedInsts_2_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_vstart, x_io_out_complexDecodedInsts_2_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_2_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_nf !== x_io_out_complexDecodedInsts_2_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_nf, x_io_out_complexDecodedInsts_2_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_veew !== x_io_out_complexDecodedInsts_2_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_veew, x_io_out_complexDecodedInsts_2_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_2_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isReverse, x_io_out_complexDecodedInsts_2_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isExt !== x_io_out_complexDecodedInsts_2_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isExt, x_io_out_complexDecodedInsts_2_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_2_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_2_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_2_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_2_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_2_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_2_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_2_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_2_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_2_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vpu_isVleff, x_io_out_complexDecodedInsts_2_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_vlsInstr !== x_io_out_complexDecodedInsts_2_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_vlsInstr, x_io_out_complexDecodedInsts_2_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_wfflags !== x_io_out_complexDecodedInsts_2_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_wfflags, x_io_out_complexDecodedInsts_2_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_isMove !== x_io_out_complexDecodedInsts_2_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_isMove, x_io_out_complexDecodedInsts_2_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_uopIdx !== x_io_out_complexDecodedInsts_2_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_uopIdx, x_io_out_complexDecodedInsts_2_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_uopSplitType !== x_io_out_complexDecodedInsts_2_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_uopSplitType, x_io_out_complexDecodedInsts_2_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_isVset !== x_io_out_complexDecodedInsts_2_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_isVset, x_io_out_complexDecodedInsts_2_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_lastUop !== x_io_out_complexDecodedInsts_2_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_lastUop, x_io_out_complexDecodedInsts_2_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_numUops !== x_io_out_complexDecodedInsts_2_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_numUops, x_io_out_complexDecodedInsts_2_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_numWB !== x_io_out_complexDecodedInsts_2_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_numWB, x_io_out_complexDecodedInsts_2_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_commitType !== x_io_out_complexDecodedInsts_2_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_commitType, x_io_out_complexDecodedInsts_2_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_debug_fuType !== x_io_out_complexDecodedInsts_2_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_debug_fuType, x_io_out_complexDecodedInsts_2_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_2_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_2_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_valid !== x_io_out_complexDecodedInsts_3_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_valid, x_io_out_complexDecodedInsts_3_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_instr !== x_io_out_complexDecodedInsts_3_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_instr, x_io_out_complexDecodedInsts_3_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_pc !== x_io_out_complexDecodedInsts_3_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_pc, x_io_out_complexDecodedInsts_3_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_foldpc !== x_io_out_complexDecodedInsts_3_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_foldpc, x_io_out_complexDecodedInsts_3_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_0, x_io_out_complexDecodedInsts_3_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_1, x_io_out_complexDecodedInsts_3_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_2, x_io_out_complexDecodedInsts_3_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_3, x_io_out_complexDecodedInsts_3_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_4, x_io_out_complexDecodedInsts_3_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_5, x_io_out_complexDecodedInsts_3_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_6, x_io_out_complexDecodedInsts_3_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_7, x_io_out_complexDecodedInsts_3_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_8, x_io_out_complexDecodedInsts_3_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_9, x_io_out_complexDecodedInsts_3_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_10, x_io_out_complexDecodedInsts_3_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_11, x_io_out_complexDecodedInsts_3_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_12, x_io_out_complexDecodedInsts_3_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_13, x_io_out_complexDecodedInsts_3_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_14, x_io_out_complexDecodedInsts_3_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_15, x_io_out_complexDecodedInsts_3_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_16, x_io_out_complexDecodedInsts_3_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_17, x_io_out_complexDecodedInsts_3_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_18, x_io_out_complexDecodedInsts_3_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_19, x_io_out_complexDecodedInsts_3_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_20, x_io_out_complexDecodedInsts_3_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_21, x_io_out_complexDecodedInsts_3_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_22, x_io_out_complexDecodedInsts_3_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_3_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_exceptionVec_23, x_io_out_complexDecodedInsts_3_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_3_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_3_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_trigger !== x_io_out_complexDecodedInsts_3_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_trigger, x_io_out_complexDecodedInsts_3_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_3_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_pred_taken !== x_io_out_complexDecodedInsts_3_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_pred_taken, x_io_out_complexDecodedInsts_3_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_3_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_3_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_3_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_3_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_3_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_ftqPtr_value, x_io_out_complexDecodedInsts_3_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_ftqOffset !== x_io_out_complexDecodedInsts_3_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_ftqOffset, x_io_out_complexDecodedInsts_3_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_3_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_srcType_0 !== x_io_out_complexDecodedInsts_3_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_srcType_0, x_io_out_complexDecodedInsts_3_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_srcType_1 !== x_io_out_complexDecodedInsts_3_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_srcType_1, x_io_out_complexDecodedInsts_3_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_srcType_2 !== x_io_out_complexDecodedInsts_3_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_srcType_2, x_io_out_complexDecodedInsts_3_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_srcType_3 !== x_io_out_complexDecodedInsts_3_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_srcType_3, x_io_out_complexDecodedInsts_3_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_srcType_4 !== x_io_out_complexDecodedInsts_3_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_srcType_4, x_io_out_complexDecodedInsts_3_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_lsrc_0 !== x_io_out_complexDecodedInsts_3_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_lsrc_0, x_io_out_complexDecodedInsts_3_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_lsrc_1 !== x_io_out_complexDecodedInsts_3_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_lsrc_1, x_io_out_complexDecodedInsts_3_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_lsrc_2 !== x_io_out_complexDecodedInsts_3_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_lsrc_2, x_io_out_complexDecodedInsts_3_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_ldest !== x_io_out_complexDecodedInsts_3_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_ldest, x_io_out_complexDecodedInsts_3_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fuType !== x_io_out_complexDecodedInsts_3_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fuType, x_io_out_complexDecodedInsts_3_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fuOpType !== x_io_out_complexDecodedInsts_3_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fuOpType, x_io_out_complexDecodedInsts_3_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_rfWen !== x_io_out_complexDecodedInsts_3_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_rfWen, x_io_out_complexDecodedInsts_3_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpWen !== x_io_out_complexDecodedInsts_3_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpWen, x_io_out_complexDecodedInsts_3_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vecWen !== x_io_out_complexDecodedInsts_3_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vecWen, x_io_out_complexDecodedInsts_3_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vlWen !== x_io_out_complexDecodedInsts_3_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vlWen, x_io_out_complexDecodedInsts_3_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_isXSTrap !== x_io_out_complexDecodedInsts_3_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_isXSTrap, x_io_out_complexDecodedInsts_3_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_waitForward !== x_io_out_complexDecodedInsts_3_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_waitForward, x_io_out_complexDecodedInsts_3_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_blockBackward !== x_io_out_complexDecodedInsts_3_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_blockBackward, x_io_out_complexDecodedInsts_3_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_flushPipe !== x_io_out_complexDecodedInsts_3_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_flushPipe, x_io_out_complexDecodedInsts_3_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_canRobCompress !== x_io_out_complexDecodedInsts_3_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_canRobCompress, x_io_out_complexDecodedInsts_3_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_selImm !== x_io_out_complexDecodedInsts_3_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_selImm, x_io_out_complexDecodedInsts_3_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_imm !== x_io_out_complexDecodedInsts_3_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_imm, x_io_out_complexDecodedInsts_3_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_3_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpu_wflags !== x_io_out_complexDecodedInsts_3_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpu_wflags, x_io_out_complexDecodedInsts_3_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpu_typ !== x_io_out_complexDecodedInsts_3_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpu_typ, x_io_out_complexDecodedInsts_3_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpu_fmt !== x_io_out_complexDecodedInsts_3_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpu_fmt, x_io_out_complexDecodedInsts_3_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_fpu_rm !== x_io_out_complexDecodedInsts_3_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_fpu_rm, x_io_out_complexDecodedInsts_3_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vill !== x_io_out_complexDecodedInsts_3_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vill, x_io_out_complexDecodedInsts_3_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vma !== x_io_out_complexDecodedInsts_3_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vma, x_io_out_complexDecodedInsts_3_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vta !== x_io_out_complexDecodedInsts_3_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vta, x_io_out_complexDecodedInsts_3_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vsew !== x_io_out_complexDecodedInsts_3_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vsew, x_io_out_complexDecodedInsts_3_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_3_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vlmul, x_io_out_complexDecodedInsts_3_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_specVill !== x_io_out_complexDecodedInsts_3_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_specVill, x_io_out_complexDecodedInsts_3_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_specVma !== x_io_out_complexDecodedInsts_3_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_specVma, x_io_out_complexDecodedInsts_3_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_specVta !== x_io_out_complexDecodedInsts_3_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_specVta, x_io_out_complexDecodedInsts_3_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_3_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_specVsew, x_io_out_complexDecodedInsts_3_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_3_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_3_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vm !== x_io_out_complexDecodedInsts_3_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vm, x_io_out_complexDecodedInsts_3_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_vstart !== x_io_out_complexDecodedInsts_3_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_vstart, x_io_out_complexDecodedInsts_3_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_3_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_nf !== x_io_out_complexDecodedInsts_3_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_nf, x_io_out_complexDecodedInsts_3_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_veew !== x_io_out_complexDecodedInsts_3_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_veew, x_io_out_complexDecodedInsts_3_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_3_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isReverse, x_io_out_complexDecodedInsts_3_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isExt !== x_io_out_complexDecodedInsts_3_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isExt, x_io_out_complexDecodedInsts_3_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_3_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_3_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_3_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_3_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_3_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_3_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_3_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_3_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_3_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vpu_isVleff, x_io_out_complexDecodedInsts_3_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_vlsInstr !== x_io_out_complexDecodedInsts_3_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_vlsInstr, x_io_out_complexDecodedInsts_3_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_wfflags !== x_io_out_complexDecodedInsts_3_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_wfflags, x_io_out_complexDecodedInsts_3_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_isMove !== x_io_out_complexDecodedInsts_3_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_isMove, x_io_out_complexDecodedInsts_3_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_uopIdx !== x_io_out_complexDecodedInsts_3_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_uopIdx, x_io_out_complexDecodedInsts_3_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_uopSplitType !== x_io_out_complexDecodedInsts_3_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_uopSplitType, x_io_out_complexDecodedInsts_3_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_isVset !== x_io_out_complexDecodedInsts_3_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_isVset, x_io_out_complexDecodedInsts_3_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_lastUop !== x_io_out_complexDecodedInsts_3_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_lastUop, x_io_out_complexDecodedInsts_3_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_numUops !== x_io_out_complexDecodedInsts_3_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_numUops, x_io_out_complexDecodedInsts_3_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_numWB !== x_io_out_complexDecodedInsts_3_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_numWB, x_io_out_complexDecodedInsts_3_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_commitType !== x_io_out_complexDecodedInsts_3_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_commitType, x_io_out_complexDecodedInsts_3_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_debug_fuType !== x_io_out_complexDecodedInsts_3_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_debug_fuType, x_io_out_complexDecodedInsts_3_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_3_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_3_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_valid !== x_io_out_complexDecodedInsts_4_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_valid, x_io_out_complexDecodedInsts_4_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_instr !== x_io_out_complexDecodedInsts_4_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_instr, x_io_out_complexDecodedInsts_4_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_pc !== x_io_out_complexDecodedInsts_4_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_pc, x_io_out_complexDecodedInsts_4_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_foldpc !== x_io_out_complexDecodedInsts_4_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_foldpc, x_io_out_complexDecodedInsts_4_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_0, x_io_out_complexDecodedInsts_4_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_1, x_io_out_complexDecodedInsts_4_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_2, x_io_out_complexDecodedInsts_4_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_3, x_io_out_complexDecodedInsts_4_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_4, x_io_out_complexDecodedInsts_4_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_5, x_io_out_complexDecodedInsts_4_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_6, x_io_out_complexDecodedInsts_4_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_7, x_io_out_complexDecodedInsts_4_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_8, x_io_out_complexDecodedInsts_4_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_9, x_io_out_complexDecodedInsts_4_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_10, x_io_out_complexDecodedInsts_4_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_11, x_io_out_complexDecodedInsts_4_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_12, x_io_out_complexDecodedInsts_4_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_13, x_io_out_complexDecodedInsts_4_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_14, x_io_out_complexDecodedInsts_4_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_15, x_io_out_complexDecodedInsts_4_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_16, x_io_out_complexDecodedInsts_4_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_17, x_io_out_complexDecodedInsts_4_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_18, x_io_out_complexDecodedInsts_4_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_19, x_io_out_complexDecodedInsts_4_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_20, x_io_out_complexDecodedInsts_4_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_21, x_io_out_complexDecodedInsts_4_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_22, x_io_out_complexDecodedInsts_4_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_4_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_exceptionVec_23, x_io_out_complexDecodedInsts_4_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_4_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_4_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_trigger !== x_io_out_complexDecodedInsts_4_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_trigger, x_io_out_complexDecodedInsts_4_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_4_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_pred_taken !== x_io_out_complexDecodedInsts_4_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_pred_taken, x_io_out_complexDecodedInsts_4_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_4_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_4_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_4_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_4_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_4_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_ftqPtr_value, x_io_out_complexDecodedInsts_4_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_ftqOffset !== x_io_out_complexDecodedInsts_4_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_ftqOffset, x_io_out_complexDecodedInsts_4_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_4_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_srcType_0 !== x_io_out_complexDecodedInsts_4_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_srcType_0, x_io_out_complexDecodedInsts_4_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_srcType_1 !== x_io_out_complexDecodedInsts_4_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_srcType_1, x_io_out_complexDecodedInsts_4_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_srcType_2 !== x_io_out_complexDecodedInsts_4_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_srcType_2, x_io_out_complexDecodedInsts_4_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_srcType_3 !== x_io_out_complexDecodedInsts_4_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_srcType_3, x_io_out_complexDecodedInsts_4_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_srcType_4 !== x_io_out_complexDecodedInsts_4_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_srcType_4, x_io_out_complexDecodedInsts_4_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_lsrc_0 !== x_io_out_complexDecodedInsts_4_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_lsrc_0, x_io_out_complexDecodedInsts_4_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_lsrc_1 !== x_io_out_complexDecodedInsts_4_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_lsrc_1, x_io_out_complexDecodedInsts_4_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_lsrc_2 !== x_io_out_complexDecodedInsts_4_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_lsrc_2, x_io_out_complexDecodedInsts_4_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_ldest !== x_io_out_complexDecodedInsts_4_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_ldest, x_io_out_complexDecodedInsts_4_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fuType !== x_io_out_complexDecodedInsts_4_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fuType, x_io_out_complexDecodedInsts_4_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fuOpType !== x_io_out_complexDecodedInsts_4_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fuOpType, x_io_out_complexDecodedInsts_4_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_rfWen !== x_io_out_complexDecodedInsts_4_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_rfWen, x_io_out_complexDecodedInsts_4_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpWen !== x_io_out_complexDecodedInsts_4_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpWen, x_io_out_complexDecodedInsts_4_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vecWen !== x_io_out_complexDecodedInsts_4_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vecWen, x_io_out_complexDecodedInsts_4_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vlWen !== x_io_out_complexDecodedInsts_4_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vlWen, x_io_out_complexDecodedInsts_4_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_isXSTrap !== x_io_out_complexDecodedInsts_4_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_isXSTrap, x_io_out_complexDecodedInsts_4_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_waitForward !== x_io_out_complexDecodedInsts_4_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_waitForward, x_io_out_complexDecodedInsts_4_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_blockBackward !== x_io_out_complexDecodedInsts_4_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_blockBackward, x_io_out_complexDecodedInsts_4_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_flushPipe !== x_io_out_complexDecodedInsts_4_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_flushPipe, x_io_out_complexDecodedInsts_4_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_canRobCompress !== x_io_out_complexDecodedInsts_4_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_canRobCompress, x_io_out_complexDecodedInsts_4_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_selImm !== x_io_out_complexDecodedInsts_4_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_selImm, x_io_out_complexDecodedInsts_4_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_imm !== x_io_out_complexDecodedInsts_4_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_imm, x_io_out_complexDecodedInsts_4_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_4_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpu_wflags !== x_io_out_complexDecodedInsts_4_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpu_wflags, x_io_out_complexDecodedInsts_4_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpu_typ !== x_io_out_complexDecodedInsts_4_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpu_typ, x_io_out_complexDecodedInsts_4_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpu_fmt !== x_io_out_complexDecodedInsts_4_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpu_fmt, x_io_out_complexDecodedInsts_4_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_fpu_rm !== x_io_out_complexDecodedInsts_4_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_fpu_rm, x_io_out_complexDecodedInsts_4_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vill !== x_io_out_complexDecodedInsts_4_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vill, x_io_out_complexDecodedInsts_4_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vma !== x_io_out_complexDecodedInsts_4_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vma, x_io_out_complexDecodedInsts_4_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vta !== x_io_out_complexDecodedInsts_4_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vta, x_io_out_complexDecodedInsts_4_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vsew !== x_io_out_complexDecodedInsts_4_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vsew, x_io_out_complexDecodedInsts_4_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_4_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vlmul, x_io_out_complexDecodedInsts_4_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_specVill !== x_io_out_complexDecodedInsts_4_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_specVill, x_io_out_complexDecodedInsts_4_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_specVma !== x_io_out_complexDecodedInsts_4_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_specVma, x_io_out_complexDecodedInsts_4_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_specVta !== x_io_out_complexDecodedInsts_4_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_specVta, x_io_out_complexDecodedInsts_4_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_4_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_specVsew, x_io_out_complexDecodedInsts_4_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_4_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_4_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vm !== x_io_out_complexDecodedInsts_4_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vm, x_io_out_complexDecodedInsts_4_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_vstart !== x_io_out_complexDecodedInsts_4_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_vstart, x_io_out_complexDecodedInsts_4_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_4_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_nf !== x_io_out_complexDecodedInsts_4_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_nf, x_io_out_complexDecodedInsts_4_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_veew !== x_io_out_complexDecodedInsts_4_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_veew, x_io_out_complexDecodedInsts_4_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_4_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isReverse, x_io_out_complexDecodedInsts_4_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isExt !== x_io_out_complexDecodedInsts_4_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isExt, x_io_out_complexDecodedInsts_4_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_4_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_4_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_4_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_4_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_4_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_4_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_4_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_4_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_4_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vpu_isVleff, x_io_out_complexDecodedInsts_4_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_vlsInstr !== x_io_out_complexDecodedInsts_4_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_vlsInstr, x_io_out_complexDecodedInsts_4_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_wfflags !== x_io_out_complexDecodedInsts_4_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_wfflags, x_io_out_complexDecodedInsts_4_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_isMove !== x_io_out_complexDecodedInsts_4_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_isMove, x_io_out_complexDecodedInsts_4_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_uopIdx !== x_io_out_complexDecodedInsts_4_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_uopIdx, x_io_out_complexDecodedInsts_4_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_uopSplitType !== x_io_out_complexDecodedInsts_4_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_uopSplitType, x_io_out_complexDecodedInsts_4_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_isVset !== x_io_out_complexDecodedInsts_4_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_isVset, x_io_out_complexDecodedInsts_4_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_lastUop !== x_io_out_complexDecodedInsts_4_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_lastUop, x_io_out_complexDecodedInsts_4_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_numUops !== x_io_out_complexDecodedInsts_4_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_numUops, x_io_out_complexDecodedInsts_4_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_numWB !== x_io_out_complexDecodedInsts_4_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_numWB, x_io_out_complexDecodedInsts_4_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_commitType !== x_io_out_complexDecodedInsts_4_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_commitType, x_io_out_complexDecodedInsts_4_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_debug_fuType !== x_io_out_complexDecodedInsts_4_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_debug_fuType, x_io_out_complexDecodedInsts_4_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_4_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_4_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_valid !== x_io_out_complexDecodedInsts_5_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_valid, x_io_out_complexDecodedInsts_5_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_instr !== x_io_out_complexDecodedInsts_5_bits_instr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_instr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_instr, x_io_out_complexDecodedInsts_5_bits_instr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_pc !== x_io_out_complexDecodedInsts_5_bits_pc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_pc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_pc, x_io_out_complexDecodedInsts_5_bits_pc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_foldpc !== x_io_out_complexDecodedInsts_5_bits_foldpc) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_foldpc: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_foldpc, x_io_out_complexDecodedInsts_5_bits_foldpc, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_0 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_0, x_io_out_complexDecodedInsts_5_bits_exceptionVec_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_1 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_1, x_io_out_complexDecodedInsts_5_bits_exceptionVec_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_2 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_2, x_io_out_complexDecodedInsts_5_bits_exceptionVec_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_3 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_3, x_io_out_complexDecodedInsts_5_bits_exceptionVec_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_4 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_4, x_io_out_complexDecodedInsts_5_bits_exceptionVec_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_5 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_5) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_5: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_5, x_io_out_complexDecodedInsts_5_bits_exceptionVec_5, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_6 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_6) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_6: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_6, x_io_out_complexDecodedInsts_5_bits_exceptionVec_6, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_7 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_7) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_7: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_7, x_io_out_complexDecodedInsts_5_bits_exceptionVec_7, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_8 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_8, x_io_out_complexDecodedInsts_5_bits_exceptionVec_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_9 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_9) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_9: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_9, x_io_out_complexDecodedInsts_5_bits_exceptionVec_9, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_10 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_10) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_10: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_10, x_io_out_complexDecodedInsts_5_bits_exceptionVec_10, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_11 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_11) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_11: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_11, x_io_out_complexDecodedInsts_5_bits_exceptionVec_11, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_12 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_12) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_12: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_12, x_io_out_complexDecodedInsts_5_bits_exceptionVec_12, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_13 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_13) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_13: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_13, x_io_out_complexDecodedInsts_5_bits_exceptionVec_13, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_14 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_14) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_14: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_14, x_io_out_complexDecodedInsts_5_bits_exceptionVec_14, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_15 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_15) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_15: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_15, x_io_out_complexDecodedInsts_5_bits_exceptionVec_15, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_16 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_16) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_16: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_16, x_io_out_complexDecodedInsts_5_bits_exceptionVec_16, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_17 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_17) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_17: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_17, x_io_out_complexDecodedInsts_5_bits_exceptionVec_17, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_18 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_18) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_18: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_18, x_io_out_complexDecodedInsts_5_bits_exceptionVec_18, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_19 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_19) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_19: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_19, x_io_out_complexDecodedInsts_5_bits_exceptionVec_19, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_20 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_20) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_20: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_20, x_io_out_complexDecodedInsts_5_bits_exceptionVec_20, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_21 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_21) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_21: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_21, x_io_out_complexDecodedInsts_5_bits_exceptionVec_21, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_22 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_22) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_22: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_22, x_io_out_complexDecodedInsts_5_bits_exceptionVec_22, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_exceptionVec_23 !== x_io_out_complexDecodedInsts_5_bits_exceptionVec_23) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_exceptionVec_23: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_exceptionVec_23, x_io_out_complexDecodedInsts_5_bits_exceptionVec_23, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_isFetchMalAddr !== x_io_out_complexDecodedInsts_5_bits_isFetchMalAddr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_isFetchMalAddr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_isFetchMalAddr, x_io_out_complexDecodedInsts_5_bits_isFetchMalAddr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_trigger !== x_io_out_complexDecodedInsts_5_bits_trigger) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_trigger: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_trigger, x_io_out_complexDecodedInsts_5_bits_trigger, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid !== x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_valid, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC !== x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRVC, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType !== x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_brType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall !== x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isCall, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet !== x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet, x_io_out_complexDecodedInsts_5_bits_preDecodeInfo_isRet, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_pred_taken !== x_io_out_complexDecodedInsts_5_bits_pred_taken) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_pred_taken: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_pred_taken, x_io_out_complexDecodedInsts_5_bits_pred_taken, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_crossPageIPFFix !== x_io_out_complexDecodedInsts_5_bits_crossPageIPFFix) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_crossPageIPFFix: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_crossPageIPFFix, x_io_out_complexDecodedInsts_5_bits_crossPageIPFFix, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_ftqPtr_flag !== x_io_out_complexDecodedInsts_5_bits_ftqPtr_flag) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_ftqPtr_flag: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_ftqPtr_flag, x_io_out_complexDecodedInsts_5_bits_ftqPtr_flag, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_ftqPtr_value !== x_io_out_complexDecodedInsts_5_bits_ftqPtr_value) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_ftqPtr_value: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_ftqPtr_value, x_io_out_complexDecodedInsts_5_bits_ftqPtr_value, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_ftqOffset !== x_io_out_complexDecodedInsts_5_bits_ftqOffset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_ftqOffset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_ftqOffset, x_io_out_complexDecodedInsts_5_bits_ftqOffset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault !== x_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault, x_io_out_complexDecodedInsts_5_bits_satpFlushFirstFetchFault, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_srcType_0 !== x_io_out_complexDecodedInsts_5_bits_srcType_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_srcType_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_srcType_0, x_io_out_complexDecodedInsts_5_bits_srcType_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_srcType_1 !== x_io_out_complexDecodedInsts_5_bits_srcType_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_srcType_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_srcType_1, x_io_out_complexDecodedInsts_5_bits_srcType_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_srcType_2 !== x_io_out_complexDecodedInsts_5_bits_srcType_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_srcType_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_srcType_2, x_io_out_complexDecodedInsts_5_bits_srcType_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_srcType_3 !== x_io_out_complexDecodedInsts_5_bits_srcType_3) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_srcType_3: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_srcType_3, x_io_out_complexDecodedInsts_5_bits_srcType_3, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_srcType_4 !== x_io_out_complexDecodedInsts_5_bits_srcType_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_srcType_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_srcType_4, x_io_out_complexDecodedInsts_5_bits_srcType_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_lsrc_0 !== x_io_out_complexDecodedInsts_5_bits_lsrc_0) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_lsrc_0: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_lsrc_0, x_io_out_complexDecodedInsts_5_bits_lsrc_0, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_lsrc_1 !== x_io_out_complexDecodedInsts_5_bits_lsrc_1) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_lsrc_1: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_lsrc_1, x_io_out_complexDecodedInsts_5_bits_lsrc_1, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_lsrc_2 !== x_io_out_complexDecodedInsts_5_bits_lsrc_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_lsrc_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_lsrc_2, x_io_out_complexDecodedInsts_5_bits_lsrc_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_ldest !== x_io_out_complexDecodedInsts_5_bits_ldest) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_ldest: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_ldest, x_io_out_complexDecodedInsts_5_bits_ldest, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fuType !== x_io_out_complexDecodedInsts_5_bits_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fuType, x_io_out_complexDecodedInsts_5_bits_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fuOpType !== x_io_out_complexDecodedInsts_5_bits_fuOpType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fuOpType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fuOpType, x_io_out_complexDecodedInsts_5_bits_fuOpType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_rfWen !== x_io_out_complexDecodedInsts_5_bits_rfWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_rfWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_rfWen, x_io_out_complexDecodedInsts_5_bits_rfWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpWen !== x_io_out_complexDecodedInsts_5_bits_fpWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpWen, x_io_out_complexDecodedInsts_5_bits_fpWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vecWen !== x_io_out_complexDecodedInsts_5_bits_vecWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vecWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vecWen, x_io_out_complexDecodedInsts_5_bits_vecWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vlWen !== x_io_out_complexDecodedInsts_5_bits_vlWen) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vlWen: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vlWen, x_io_out_complexDecodedInsts_5_bits_vlWen, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_isXSTrap !== x_io_out_complexDecodedInsts_5_bits_isXSTrap) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_isXSTrap: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_isXSTrap, x_io_out_complexDecodedInsts_5_bits_isXSTrap, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_waitForward !== x_io_out_complexDecodedInsts_5_bits_waitForward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_waitForward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_waitForward, x_io_out_complexDecodedInsts_5_bits_waitForward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_blockBackward !== x_io_out_complexDecodedInsts_5_bits_blockBackward) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_blockBackward: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_blockBackward, x_io_out_complexDecodedInsts_5_bits_blockBackward, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_flushPipe !== x_io_out_complexDecodedInsts_5_bits_flushPipe) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_flushPipe: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_flushPipe, x_io_out_complexDecodedInsts_5_bits_flushPipe, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_canRobCompress !== x_io_out_complexDecodedInsts_5_bits_canRobCompress) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_canRobCompress: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_canRobCompress, x_io_out_complexDecodedInsts_5_bits_canRobCompress, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_selImm !== x_io_out_complexDecodedInsts_5_bits_selImm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_selImm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_selImm, x_io_out_complexDecodedInsts_5_bits_selImm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_imm !== x_io_out_complexDecodedInsts_5_bits_imm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_imm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_imm, x_io_out_complexDecodedInsts_5_bits_imm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut !== x_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpu_typeTagOut: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut, x_io_out_complexDecodedInsts_5_bits_fpu_typeTagOut, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpu_wflags !== x_io_out_complexDecodedInsts_5_bits_fpu_wflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpu_wflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpu_wflags, x_io_out_complexDecodedInsts_5_bits_fpu_wflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpu_typ !== x_io_out_complexDecodedInsts_5_bits_fpu_typ) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpu_typ: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpu_typ, x_io_out_complexDecodedInsts_5_bits_fpu_typ, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpu_fmt !== x_io_out_complexDecodedInsts_5_bits_fpu_fmt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpu_fmt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpu_fmt, x_io_out_complexDecodedInsts_5_bits_fpu_fmt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_fpu_rm !== x_io_out_complexDecodedInsts_5_bits_fpu_rm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_fpu_rm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_fpu_rm, x_io_out_complexDecodedInsts_5_bits_fpu_rm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vill !== x_io_out_complexDecodedInsts_5_bits_vpu_vill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vill, x_io_out_complexDecodedInsts_5_bits_vpu_vill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vma !== x_io_out_complexDecodedInsts_5_bits_vpu_vma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vma, x_io_out_complexDecodedInsts_5_bits_vpu_vma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vta !== x_io_out_complexDecodedInsts_5_bits_vpu_vta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vta, x_io_out_complexDecodedInsts_5_bits_vpu_vta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vsew !== x_io_out_complexDecodedInsts_5_bits_vpu_vsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vsew, x_io_out_complexDecodedInsts_5_bits_vpu_vsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vlmul !== x_io_out_complexDecodedInsts_5_bits_vpu_vlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vlmul, x_io_out_complexDecodedInsts_5_bits_vpu_vlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_specVill !== x_io_out_complexDecodedInsts_5_bits_vpu_specVill) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_specVill: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_specVill, x_io_out_complexDecodedInsts_5_bits_vpu_specVill, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_specVma !== x_io_out_complexDecodedInsts_5_bits_vpu_specVma) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_specVma: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_specVma, x_io_out_complexDecodedInsts_5_bits_vpu_specVma, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_specVta !== x_io_out_complexDecodedInsts_5_bits_vpu_specVta) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_specVta: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_specVta, x_io_out_complexDecodedInsts_5_bits_vpu_specVta, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_specVsew !== x_io_out_complexDecodedInsts_5_bits_vpu_specVsew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_specVsew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_specVsew, x_io_out_complexDecodedInsts_5_bits_vpu_specVsew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_specVlmul !== x_io_out_complexDecodedInsts_5_bits_vpu_specVlmul) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_specVlmul: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_specVlmul, x_io_out_complexDecodedInsts_5_bits_vpu_specVlmul, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vm !== x_io_out_complexDecodedInsts_5_bits_vpu_vm) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vm: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vm, x_io_out_complexDecodedInsts_5_bits_vpu_vm, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_vstart !== x_io_out_complexDecodedInsts_5_bits_vpu_vstart) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_vstart: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_vstart, x_io_out_complexDecodedInsts_5_bits_vpu_vstart, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_2, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_4, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8, x_io_out_complexDecodedInsts_5_bits_vpu_fpu_isFoldTo1_8, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_nf !== x_io_out_complexDecodedInsts_5_bits_vpu_nf) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_nf: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_nf, x_io_out_complexDecodedInsts_5_bits_vpu_nf, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_veew !== x_io_out_complexDecodedInsts_5_bits_vpu_veew) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_veew: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_veew, x_io_out_complexDecodedInsts_5_bits_vpu_veew, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isReverse !== x_io_out_complexDecodedInsts_5_bits_vpu_isReverse) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isReverse: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isReverse, x_io_out_complexDecodedInsts_5_bits_vpu_isReverse, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isExt !== x_io_out_complexDecodedInsts_5_bits_vpu_isExt) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isExt: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isExt, x_io_out_complexDecodedInsts_5_bits_vpu_isExt, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isNarrow !== x_io_out_complexDecodedInsts_5_bits_vpu_isNarrow) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isNarrow: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isNarrow, x_io_out_complexDecodedInsts_5_bits_vpu_isNarrow, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isDstMask !== x_io_out_complexDecodedInsts_5_bits_vpu_isDstMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isDstMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isDstMask, x_io_out_complexDecodedInsts_5_bits_vpu_isDstMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isOpMask !== x_io_out_complexDecodedInsts_5_bits_vpu_isOpMask) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isOpMask: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isOpMask, x_io_out_complexDecodedInsts_5_bits_vpu_isOpMask, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd !== x_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd, x_io_out_complexDecodedInsts_5_bits_vpu_isDependOldVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd !== x_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd, x_io_out_complexDecodedInsts_5_bits_vpu_isWritePartVd, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vpu_isVleff !== x_io_out_complexDecodedInsts_5_bits_vpu_isVleff) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vpu_isVleff: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vpu_isVleff, x_io_out_complexDecodedInsts_5_bits_vpu_isVleff, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_vlsInstr !== x_io_out_complexDecodedInsts_5_bits_vlsInstr) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_vlsInstr: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_vlsInstr, x_io_out_complexDecodedInsts_5_bits_vlsInstr, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_wfflags !== x_io_out_complexDecodedInsts_5_bits_wfflags) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_wfflags: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_wfflags, x_io_out_complexDecodedInsts_5_bits_wfflags, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_isMove !== x_io_out_complexDecodedInsts_5_bits_isMove) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_isMove: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_isMove, x_io_out_complexDecodedInsts_5_bits_isMove, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_uopIdx !== x_io_out_complexDecodedInsts_5_bits_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_uopIdx, x_io_out_complexDecodedInsts_5_bits_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_uopSplitType !== x_io_out_complexDecodedInsts_5_bits_uopSplitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_uopSplitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_uopSplitType, x_io_out_complexDecodedInsts_5_bits_uopSplitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_isVset !== x_io_out_complexDecodedInsts_5_bits_isVset) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_isVset: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_isVset, x_io_out_complexDecodedInsts_5_bits_isVset, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_lastUop !== x_io_out_complexDecodedInsts_5_bits_lastUop) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_lastUop: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_lastUop, x_io_out_complexDecodedInsts_5_bits_lastUop, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_numUops !== x_io_out_complexDecodedInsts_5_bits_numUops) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_numUops: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_numUops, x_io_out_complexDecodedInsts_5_bits_numUops, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_numWB !== x_io_out_complexDecodedInsts_5_bits_numWB) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_numWB: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_numWB, x_io_out_complexDecodedInsts_5_bits_numWB, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_commitType !== x_io_out_complexDecodedInsts_5_bits_commitType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_commitType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_commitType, x_io_out_complexDecodedInsts_5_bits_commitType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_debug_fuType !== x_io_out_complexDecodedInsts_5_bits_debug_fuType) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_debug_fuType: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_debug_fuType, x_io_out_complexDecodedInsts_5_bits_debug_fuType, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum !== x_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum, x_io_out_complexDecodedInsts_5_bits_debug_seqNum_seqNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx !== x_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx, x_io_out_complexDecodedInsts_5_bits_debug_seqNum_uopIdx, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
    if (g_io_complexNum !== x_io_complexNum) begin
      errors++;
      if (errors < 40)
        $display("MISMATCH %0t io_complexNum: gold=%h xs=%h  split=%h vlmul=%h vsew=%h count=%0d state=%0b numOfUop=%0d",
                 $time, g_io_complexNum, x_io_complexNum, u_gold.latchedInst_uopSplitType,
                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,
                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);
    end
  endtask


  int si;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 64; i++) begin
      cov_split[i] = 0;
      for (int j = 0; j < 8; j++) cov_split_vlmul[i][j] = 0;
    end
    for (int i = 0; i < 16; i++) cov_count[i] = 0;
    cov_state[0] = 0; cov_state[1] = 0;

    rst = 1'b1;
    drive_random_inputs();
    io_in_valid = 1'b0;
    io_redirect = 1'b0;
    repeat (4) @(negedge clk);
    rst = 1'b0;

    for (longint c = 0; c < NCYCLES; c++) begin
      // 运行中多次异步复位：每约 4000 拍来一次 3 拍的复位，复位期间照常打激励。
      rst = ((c % 4096) < 3) && (c > WARMUP);

      drive_random_inputs();
      // uopSplitType：85% 从 45 个已定义编码里定向取，15% 随机（含未定义编码）
      if ($urandom_range(0, 99) < 85) begin
        si = $urandom_range(0, NSPLIT - 1);
        io_in_bits_simpleDecodedInst_uopSplitType = split_code[si];
      end
      // vlmul / vsew 全取值等概率（分支全挂在它们上面）
      io_in_bits_simpleDecodedInst_vpu_vlmul = 3'($urandom);
      io_in_bits_simpleDecodedInst_vpu_vsew  = 2'($urandom);
      io_in_bits_uopInfo_lmul                = 4'($urandom_range(0, 8));
      io_in_bits_uopInfo_numOfUop            = gen_numuop();
      io_in_bits_uopInfo_numOfWB             = gen_numuop();
      // vstart：一半为 0（正常），一半非零（VSET 分支靠它改 flushPipe/blockBackward）
      io_in_bits_simpleDecodedInst_vpu_vstart =
          $urandom_range(0, 1) ? 8'($urandom) : 8'h0;
      // isVset / fuOpType：VSET 分支的四条子路径全靠它们 + rd/rs1 是否为 0。
      // ★fuOpType 还要定向打 9'h36★：VEC_VFREDOSUM 分支按
      // `fuOpType == VfaluType.vfwredosum`(=9'h36) 分成「加宽有序归约」与普通两支，
      // 9 位均匀随机只有 1/512 命中率，200k 拍下来那一支只有个位数次，等于没验。
      io_in_bits_simpleDecodedInst_isVset = ($urandom_range(0, 2) != 0);
      io_in_bits_simpleDecodedInst_fuOpType =
          ($urandom_range(0, 4) == 0) ? 9'h36 : 9'($urandom);
      // instr 的 rd/rs1 域：各 1/3 概率取 0（VSET 的分支条件）
      if ($urandom_range(0, 2) == 0) io_in_bits_simpleDecodedInst_instr[11:7]  = 5'h0;
      if ($urandom_range(0, 2) == 0) io_in_bits_simpleDecodedInst_instr[19:15] = 5'h0;
      // srcType_0：imm / fp / xp / vp 等概率（VEC_0XV / VEC_VXV 按它分叉）
      io_in_bits_simpleDecodedInst_srcType_0 =
          (4'h1 << $urandom_range(0, 3)) >> 1;
      io_in_valid = ($urandom_range(0, 9) != 0);          // 90% 有效
      io_redirect = ($urandom_range(0, 199) == 0);        // 0.5% 冲刷
      io_out_complexDecodedInsts_0_ready = next_ready();

      #1;
      if (c > WARMUP) compare_outputs();
      // 覆盖统计全部取自 golden 内部
      if (u_gold.state) begin
        cov_split[u_gold.latchedInst_uopSplitType]++;
        cov_split_vlmul[u_gold.latchedInst_uopSplitType][u_gold.latchedInst_vpu_vlmul]++;
        cov_count[u_gold.count]++;
        if (u_gold.latchedUopInfo_numOfUop > 7'd6) cov_numuop_gt6++;
        if (!io_out_complexDecodedInsts_0_ready) cov_backpressure++;
        if (io_redirect) cov_redir_active++;
        if (u_gold.latchedInst_uopSplitType == 6'h3D) begin
          if (u_gold.latchedInst_fuOpType == 9'h36) cov_widen_osum++;
          else                                      cov_plain_osum++;
        end
        if (u_gold.isUsSegment) cov_us_seg++;
        if (u_gold.isIxSegment) cov_ix_seg++;
        if (u_gold.isSdSegment) cov_sd_seg++;
      end
      cov_state[u_gold.state]++;
      @(negedge clk);
    end

    $display("=== COVERAGE (DecodeUnitComp) ===");
    $display("  checks=%0d  state idle=%0d active=%0d", checks, cov_state[0], cov_state[1]);
    $display("  numOfUop>6 while active=%0d  backpressure=%0d  redirect while active=%0d",
             cov_numuop_gt6, cov_backpressure, cov_redir_active);
    $display("  vfredosum 加宽支=%0d 非加宽支=%0d   段访存 us=%0d ix=%0d sd=%0d",
             cov_widen_osum, cov_plain_osum, cov_us_seg, cov_ix_seg, cov_sd_seg);
    begin
      int zero_split = 0, zero_count = 0;
      longint minsplit = -1;
      for (int i = 0; i < NSPLIT; i++) begin
        if (cov_split[split_code[i]] == 0) begin
          zero_split++;
          $display("  ZERO-HIT uopSplitType %s (6'h%02h)", split_name[i], split_code[i]);
        end
        if (minsplit < 0 || cov_split[split_code[i]] < minsplit)
          minsplit = cov_split[split_code[i]];
      end
      for (int k = 0; k < 11; k++)
        if (cov_count[k] == 0) begin
          zero_count++;
          $display("  ZERO-HIT count=%0d", k);
        end
      $display("  uopSplitType: %0d 个已定义编码，未命中 %0d，最少命中 %0d",
               NSPLIT, zero_split, minsplit);
      $display("  count 0..10 未命中 %0d 个", zero_count);
      if (zero_split != 0 || zero_count != 0) begin
        $display("COVERAGE INSUFFICIENT");
        errors++;
      end
      if (cov_numuop_gt6 == 0 || cov_backpressure == 0 || cov_redir_active == 0) begin
        $display("COVERAGE INSUFFICIENT: 长序列 / 反压 / 冲刷 有一项没打到");
        errors++;
      end
      // 这五项各自守着一个「整条分支只有一半被验到」的风险：
      // 加宽/非加宽有序归约是 VEC_VFREDOSUM 的两半，三种段访存各自决定
      // waitForward/blockBackward 那一对。
      if (cov_widen_osum == 0 || cov_plain_osum == 0 ||
          cov_us_seg == 0 || cov_ix_seg == 0 || cov_sd_seg == 0) begin
        $display("COVERAGE INSUFFICIENT: vfwredosum 两支 / 三种段访存 有一项没打到");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
