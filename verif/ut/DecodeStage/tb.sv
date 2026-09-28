// =============================================================================
// DecodeStage UT —— golden DecodeStage 对重写 DecodeStage_xs 双例化，同激励逐拍比对
// 全部 783 根输出线。子模块（DecodeUnit×6 / DecodeUnitComp / VTypeGen 及其闭包）两侧
// 共用 golden 定义（RTL_GOLDEN_DEPS），所以本 UT 验的是 DecodeStage 这一层的粘合逻辑：
// 复杂/简单指令的排布与 ready 计算、finalDecodedInst 选择、输出修饰、RAT 读口、trapInstInfo、perf。
// 本文件由 gen.py 生成，不要手改（改 gen.py 再重跑）。
//
// ★判别力在「isComplex 的分布 × complexNum × ready 相位」★
//   指令流里定向放向量算术/向量访存/vset/amocas（让 DecodeUnit 报 isComplex），
//   让 DecodeUnitComp 真的锁存并多拍吐 uop（complexNum 走遍 0..6），
//   out_ready[0] 做长条 0/1，redirect / isResumeVType 随机插入，非法指令走 trapInstInfo。
// ★无复位寄存器★ trapInstInfo 的 REG_* 与 perf 两级打拍无复位但每拍都写，
//   DecodeUnitComp 的锁存寄存器无复位、只在 in.fire 时写：暖机 WARMUP 拍里全 valid、全 ready、
//   定向喂复杂指令让它锁存一次，之后才开比对窗口，所以两档 initreg 都必须 errors=0。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 64;
  bit clk = 0; logic rst; int errors = 0; longint checks = 0;
  always #5 clk = ~clk;

  logic          io_redirect;
  logic          io_in_0_valid;
  logic [31:0]   io_in_0_bits_instr;
  logic [49:0]   io_in_0_bits_pc;
  logic [9:0]    io_in_0_bits_foldpc;
  logic          io_in_0_bits_exceptionVec_0;
  logic          io_in_0_bits_exceptionVec_1;
  logic          io_in_0_bits_exceptionVec_2;
  logic          io_in_0_bits_exceptionVec_4;
  logic          io_in_0_bits_exceptionVec_5;
  logic          io_in_0_bits_exceptionVec_6;
  logic          io_in_0_bits_exceptionVec_7;
  logic          io_in_0_bits_exceptionVec_8;
  logic          io_in_0_bits_exceptionVec_9;
  logic          io_in_0_bits_exceptionVec_10;
  logic          io_in_0_bits_exceptionVec_11;
  logic          io_in_0_bits_exceptionVec_12;
  logic          io_in_0_bits_exceptionVec_13;
  logic          io_in_0_bits_exceptionVec_14;
  logic          io_in_0_bits_exceptionVec_15;
  logic          io_in_0_bits_exceptionVec_16;
  logic          io_in_0_bits_exceptionVec_17;
  logic          io_in_0_bits_exceptionVec_18;
  logic          io_in_0_bits_exceptionVec_19;
  logic          io_in_0_bits_exceptionVec_20;
  logic          io_in_0_bits_exceptionVec_21;
  logic          io_in_0_bits_exceptionVec_23;
  logic          io_in_0_bits_isFetchMalAddr;
  logic [3:0]    io_in_0_bits_trigger;
  logic          io_in_0_bits_preDecodeInfo_valid;
  logic          io_in_0_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_0_bits_preDecodeInfo_brType;
  logic          io_in_0_bits_preDecodeInfo_isCall;
  logic          io_in_0_bits_preDecodeInfo_isRet;
  logic          io_in_0_bits_pred_taken;
  logic          io_in_0_bits_crossPageIPFFix;
  logic          io_in_0_bits_ftqPtr_flag;
  logic [5:0]    io_in_0_bits_ftqPtr_value;
  logic [3:0]    io_in_0_bits_ftqOffset;
  logic          io_in_0_bits_isLastInFtqEntry;
  logic [55:0]   io_in_0_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_0_bits_debug_seqNum_uopIdx;
  logic          io_in_0_bits_satpFlushFirstFetchFault;
  logic          io_in_1_valid;
  logic [31:0]   io_in_1_bits_instr;
  logic [49:0]   io_in_1_bits_pc;
  logic [9:0]    io_in_1_bits_foldpc;
  logic          io_in_1_bits_exceptionVec_0;
  logic          io_in_1_bits_exceptionVec_1;
  logic          io_in_1_bits_exceptionVec_2;
  logic          io_in_1_bits_exceptionVec_4;
  logic          io_in_1_bits_exceptionVec_5;
  logic          io_in_1_bits_exceptionVec_6;
  logic          io_in_1_bits_exceptionVec_7;
  logic          io_in_1_bits_exceptionVec_8;
  logic          io_in_1_bits_exceptionVec_9;
  logic          io_in_1_bits_exceptionVec_10;
  logic          io_in_1_bits_exceptionVec_11;
  logic          io_in_1_bits_exceptionVec_12;
  logic          io_in_1_bits_exceptionVec_13;
  logic          io_in_1_bits_exceptionVec_14;
  logic          io_in_1_bits_exceptionVec_15;
  logic          io_in_1_bits_exceptionVec_16;
  logic          io_in_1_bits_exceptionVec_17;
  logic          io_in_1_bits_exceptionVec_18;
  logic          io_in_1_bits_exceptionVec_19;
  logic          io_in_1_bits_exceptionVec_20;
  logic          io_in_1_bits_exceptionVec_21;
  logic          io_in_1_bits_exceptionVec_23;
  logic          io_in_1_bits_isFetchMalAddr;
  logic [3:0]    io_in_1_bits_trigger;
  logic          io_in_1_bits_preDecodeInfo_valid;
  logic          io_in_1_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_1_bits_preDecodeInfo_brType;
  logic          io_in_1_bits_preDecodeInfo_isCall;
  logic          io_in_1_bits_preDecodeInfo_isRet;
  logic          io_in_1_bits_pred_taken;
  logic          io_in_1_bits_crossPageIPFFix;
  logic          io_in_1_bits_ftqPtr_flag;
  logic [5:0]    io_in_1_bits_ftqPtr_value;
  logic [3:0]    io_in_1_bits_ftqOffset;
  logic          io_in_1_bits_isLastInFtqEntry;
  logic [55:0]   io_in_1_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_1_bits_debug_seqNum_uopIdx;
  logic          io_in_1_bits_satpFlushFirstFetchFault;
  logic          io_in_2_valid;
  logic [31:0]   io_in_2_bits_instr;
  logic [49:0]   io_in_2_bits_pc;
  logic [9:0]    io_in_2_bits_foldpc;
  logic          io_in_2_bits_exceptionVec_0;
  logic          io_in_2_bits_exceptionVec_1;
  logic          io_in_2_bits_exceptionVec_2;
  logic          io_in_2_bits_exceptionVec_4;
  logic          io_in_2_bits_exceptionVec_5;
  logic          io_in_2_bits_exceptionVec_6;
  logic          io_in_2_bits_exceptionVec_7;
  logic          io_in_2_bits_exceptionVec_8;
  logic          io_in_2_bits_exceptionVec_9;
  logic          io_in_2_bits_exceptionVec_10;
  logic          io_in_2_bits_exceptionVec_11;
  logic          io_in_2_bits_exceptionVec_12;
  logic          io_in_2_bits_exceptionVec_13;
  logic          io_in_2_bits_exceptionVec_14;
  logic          io_in_2_bits_exceptionVec_15;
  logic          io_in_2_bits_exceptionVec_16;
  logic          io_in_2_bits_exceptionVec_17;
  logic          io_in_2_bits_exceptionVec_18;
  logic          io_in_2_bits_exceptionVec_19;
  logic          io_in_2_bits_exceptionVec_20;
  logic          io_in_2_bits_exceptionVec_21;
  logic          io_in_2_bits_exceptionVec_23;
  logic          io_in_2_bits_isFetchMalAddr;
  logic [3:0]    io_in_2_bits_trigger;
  logic          io_in_2_bits_preDecodeInfo_valid;
  logic          io_in_2_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_2_bits_preDecodeInfo_brType;
  logic          io_in_2_bits_preDecodeInfo_isCall;
  logic          io_in_2_bits_preDecodeInfo_isRet;
  logic          io_in_2_bits_pred_taken;
  logic          io_in_2_bits_crossPageIPFFix;
  logic          io_in_2_bits_ftqPtr_flag;
  logic [5:0]    io_in_2_bits_ftqPtr_value;
  logic [3:0]    io_in_2_bits_ftqOffset;
  logic          io_in_2_bits_isLastInFtqEntry;
  logic [55:0]   io_in_2_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_2_bits_debug_seqNum_uopIdx;
  logic          io_in_2_bits_satpFlushFirstFetchFault;
  logic          io_in_3_valid;
  logic [31:0]   io_in_3_bits_instr;
  logic [49:0]   io_in_3_bits_pc;
  logic [9:0]    io_in_3_bits_foldpc;
  logic          io_in_3_bits_exceptionVec_0;
  logic          io_in_3_bits_exceptionVec_1;
  logic          io_in_3_bits_exceptionVec_2;
  logic          io_in_3_bits_exceptionVec_4;
  logic          io_in_3_bits_exceptionVec_5;
  logic          io_in_3_bits_exceptionVec_6;
  logic          io_in_3_bits_exceptionVec_7;
  logic          io_in_3_bits_exceptionVec_8;
  logic          io_in_3_bits_exceptionVec_9;
  logic          io_in_3_bits_exceptionVec_10;
  logic          io_in_3_bits_exceptionVec_11;
  logic          io_in_3_bits_exceptionVec_12;
  logic          io_in_3_bits_exceptionVec_13;
  logic          io_in_3_bits_exceptionVec_14;
  logic          io_in_3_bits_exceptionVec_15;
  logic          io_in_3_bits_exceptionVec_16;
  logic          io_in_3_bits_exceptionVec_17;
  logic          io_in_3_bits_exceptionVec_18;
  logic          io_in_3_bits_exceptionVec_19;
  logic          io_in_3_bits_exceptionVec_20;
  logic          io_in_3_bits_exceptionVec_21;
  logic          io_in_3_bits_exceptionVec_23;
  logic          io_in_3_bits_isFetchMalAddr;
  logic [3:0]    io_in_3_bits_trigger;
  logic          io_in_3_bits_preDecodeInfo_valid;
  logic          io_in_3_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_3_bits_preDecodeInfo_brType;
  logic          io_in_3_bits_preDecodeInfo_isCall;
  logic          io_in_3_bits_preDecodeInfo_isRet;
  logic          io_in_3_bits_pred_taken;
  logic          io_in_3_bits_crossPageIPFFix;
  logic          io_in_3_bits_ftqPtr_flag;
  logic [5:0]    io_in_3_bits_ftqPtr_value;
  logic [3:0]    io_in_3_bits_ftqOffset;
  logic          io_in_3_bits_isLastInFtqEntry;
  logic [55:0]   io_in_3_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_3_bits_debug_seqNum_uopIdx;
  logic          io_in_3_bits_satpFlushFirstFetchFault;
  logic          io_in_4_valid;
  logic [31:0]   io_in_4_bits_instr;
  logic [49:0]   io_in_4_bits_pc;
  logic [9:0]    io_in_4_bits_foldpc;
  logic          io_in_4_bits_exceptionVec_0;
  logic          io_in_4_bits_exceptionVec_1;
  logic          io_in_4_bits_exceptionVec_2;
  logic          io_in_4_bits_exceptionVec_4;
  logic          io_in_4_bits_exceptionVec_5;
  logic          io_in_4_bits_exceptionVec_6;
  logic          io_in_4_bits_exceptionVec_7;
  logic          io_in_4_bits_exceptionVec_8;
  logic          io_in_4_bits_exceptionVec_9;
  logic          io_in_4_bits_exceptionVec_10;
  logic          io_in_4_bits_exceptionVec_11;
  logic          io_in_4_bits_exceptionVec_12;
  logic          io_in_4_bits_exceptionVec_13;
  logic          io_in_4_bits_exceptionVec_14;
  logic          io_in_4_bits_exceptionVec_15;
  logic          io_in_4_bits_exceptionVec_16;
  logic          io_in_4_bits_exceptionVec_17;
  logic          io_in_4_bits_exceptionVec_18;
  logic          io_in_4_bits_exceptionVec_19;
  logic          io_in_4_bits_exceptionVec_20;
  logic          io_in_4_bits_exceptionVec_21;
  logic          io_in_4_bits_exceptionVec_23;
  logic          io_in_4_bits_isFetchMalAddr;
  logic [3:0]    io_in_4_bits_trigger;
  logic          io_in_4_bits_preDecodeInfo_valid;
  logic          io_in_4_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_4_bits_preDecodeInfo_brType;
  logic          io_in_4_bits_preDecodeInfo_isCall;
  logic          io_in_4_bits_preDecodeInfo_isRet;
  logic          io_in_4_bits_pred_taken;
  logic          io_in_4_bits_crossPageIPFFix;
  logic          io_in_4_bits_ftqPtr_flag;
  logic [5:0]    io_in_4_bits_ftqPtr_value;
  logic [3:0]    io_in_4_bits_ftqOffset;
  logic          io_in_4_bits_isLastInFtqEntry;
  logic [55:0]   io_in_4_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_4_bits_debug_seqNum_uopIdx;
  logic          io_in_4_bits_satpFlushFirstFetchFault;
  logic          io_in_5_valid;
  logic [31:0]   io_in_5_bits_instr;
  logic [49:0]   io_in_5_bits_pc;
  logic [9:0]    io_in_5_bits_foldpc;
  logic          io_in_5_bits_exceptionVec_0;
  logic          io_in_5_bits_exceptionVec_1;
  logic          io_in_5_bits_exceptionVec_2;
  logic          io_in_5_bits_exceptionVec_4;
  logic          io_in_5_bits_exceptionVec_5;
  logic          io_in_5_bits_exceptionVec_6;
  logic          io_in_5_bits_exceptionVec_7;
  logic          io_in_5_bits_exceptionVec_8;
  logic          io_in_5_bits_exceptionVec_9;
  logic          io_in_5_bits_exceptionVec_10;
  logic          io_in_5_bits_exceptionVec_11;
  logic          io_in_5_bits_exceptionVec_12;
  logic          io_in_5_bits_exceptionVec_13;
  logic          io_in_5_bits_exceptionVec_14;
  logic          io_in_5_bits_exceptionVec_15;
  logic          io_in_5_bits_exceptionVec_16;
  logic          io_in_5_bits_exceptionVec_17;
  logic          io_in_5_bits_exceptionVec_18;
  logic          io_in_5_bits_exceptionVec_19;
  logic          io_in_5_bits_exceptionVec_20;
  logic          io_in_5_bits_exceptionVec_21;
  logic          io_in_5_bits_exceptionVec_23;
  logic          io_in_5_bits_isFetchMalAddr;
  logic [3:0]    io_in_5_bits_trigger;
  logic          io_in_5_bits_preDecodeInfo_valid;
  logic          io_in_5_bits_preDecodeInfo_isRVC;
  logic [1:0]    io_in_5_bits_preDecodeInfo_brType;
  logic          io_in_5_bits_preDecodeInfo_isCall;
  logic          io_in_5_bits_preDecodeInfo_isRet;
  logic          io_in_5_bits_pred_taken;
  logic          io_in_5_bits_crossPageIPFFix;
  logic          io_in_5_bits_ftqPtr_flag;
  logic [5:0]    io_in_5_bits_ftqPtr_value;
  logic [3:0]    io_in_5_bits_ftqOffset;
  logic          io_in_5_bits_isLastInFtqEntry;
  logic [55:0]   io_in_5_bits_debug_seqNum_seqNum;
  logic [7:0]    io_in_5_bits_debug_seqNum_uopIdx;
  logic          io_in_5_bits_satpFlushFirstFetchFault;
  logic          io_out_0_ready;
  logic          io_out_1_ready;
  logic          io_out_2_ready;
  logic          io_out_3_ready;
  logic          io_out_4_ready;
  logic          io_out_5_ready;
  logic          io_csrCtrl_singlestep;
  logic          io_fromCSR_illegalInst_sfenceVMA;
  logic          io_fromCSR_illegalInst_sfencePart;
  logic          io_fromCSR_illegalInst_hfenceGVMA;
  logic          io_fromCSR_illegalInst_hfenceVVMA;
  logic          io_fromCSR_illegalInst_hlsv;
  logic          io_fromCSR_illegalInst_fsIsOff;
  logic          io_fromCSR_illegalInst_vsIsOff;
  logic          io_fromCSR_illegalInst_wfi;
  logic          io_fromCSR_illegalInst_wrs_nto;
  logic          io_fromCSR_illegalInst_frm;
  logic          io_fromCSR_illegalInst_cboZ;
  logic          io_fromCSR_illegalInst_cboCF;
  logic          io_fromCSR_illegalInst_cboI;
  logic          io_fromCSR_virtualInst_sfenceVMA;
  logic          io_fromCSR_virtualInst_sfencePart;
  logic          io_fromCSR_virtualInst_hfence;
  logic          io_fromCSR_virtualInst_hlsv;
  logic          io_fromCSR_virtualInst_wfi;
  logic          io_fromCSR_virtualInst_wrs_nto;
  logic          io_fromCSR_virtualInst_cboZ;
  logic          io_fromCSR_virtualInst_cboCF;
  logic          io_fromCSR_virtualInst_cboI;
  logic          io_fromCSR_special_cboI2F;
  logic          io_fusion_0;
  logic          io_fusion_1;
  logic          io_fusion_2;
  logic          io_fusion_3;
  logic          io_fusion_4;
  logic          io_backendCanAccept;
  logic          io_fromRob_isResumeVType;
  logic          io_fromRob_walkToArchVType;
  logic          io_fromRob_commitVType_vtype_valid;
  logic          io_fromRob_commitVType_vtype_bits_illegal;
  logic          io_fromRob_commitVType_vtype_bits_vma;
  logic          io_fromRob_commitVType_vtype_bits_vta;
  logic [1:0]    io_fromRob_commitVType_vtype_bits_vsew;
  logic [2:0]    io_fromRob_commitVType_vtype_bits_vlmul;
  logic          io_fromRob_commitVType_hasVsetvl;
  logic          io_fromRob_walkVType_valid;
  logic          io_fromRob_walkVType_bits_illegal;
  logic          io_fromRob_walkVType_bits_vma;
  logic          io_fromRob_walkVType_bits_vta;
  logic [1:0]    io_fromRob_walkVType_bits_vsew;
  logic [2:0]    io_fromRob_walkVType_bits_vlmul;
  logic [5:0]    io_stallReason_in_reason_0;
  logic [5:0]    io_stallReason_in_reason_1;
  logic [5:0]    io_stallReason_in_reason_2;
  logic [5:0]    io_stallReason_in_reason_3;
  logic [5:0]    io_stallReason_in_reason_4;
  logic [5:0]    io_stallReason_in_reason_5;
  logic          io_stallReason_out_backReason_valid;
  logic [5:0]    io_stallReason_out_backReason_bits;
  logic          io_vsetvlVType_illegal;
  logic          io_vsetvlVType_vma;
  logic          io_vsetvlVType_vta;
  logic [1:0]    io_vsetvlVType_vsew;
  logic [2:0]    io_vsetvlVType_vlmul;
  logic [7:0]    io_vstart;
  logic          g_io_in_0_ready;
  logic          g_io_in_1_ready;
  logic          g_io_in_2_ready;
  logic          g_io_in_3_ready;
  logic          g_io_in_4_ready;
  logic          g_io_in_5_ready;
  logic          g_io_out_0_valid;
  logic [31:0]   g_io_out_0_bits_instr;
  logic [49:0]   g_io_out_0_bits_pc;
  logic [9:0]    g_io_out_0_bits_foldpc;
  logic          g_io_out_0_bits_exceptionVec_0;
  logic          g_io_out_0_bits_exceptionVec_1;
  logic          g_io_out_0_bits_exceptionVec_2;
  logic          g_io_out_0_bits_exceptionVec_3;
  logic          g_io_out_0_bits_exceptionVec_4;
  logic          g_io_out_0_bits_exceptionVec_5;
  logic          g_io_out_0_bits_exceptionVec_6;
  logic          g_io_out_0_bits_exceptionVec_7;
  logic          g_io_out_0_bits_exceptionVec_8;
  logic          g_io_out_0_bits_exceptionVec_9;
  logic          g_io_out_0_bits_exceptionVec_10;
  logic          g_io_out_0_bits_exceptionVec_11;
  logic          g_io_out_0_bits_exceptionVec_12;
  logic          g_io_out_0_bits_exceptionVec_13;
  logic          g_io_out_0_bits_exceptionVec_14;
  logic          g_io_out_0_bits_exceptionVec_15;
  logic          g_io_out_0_bits_exceptionVec_16;
  logic          g_io_out_0_bits_exceptionVec_17;
  logic          g_io_out_0_bits_exceptionVec_18;
  logic          g_io_out_0_bits_exceptionVec_19;
  logic          g_io_out_0_bits_exceptionVec_20;
  logic          g_io_out_0_bits_exceptionVec_21;
  logic          g_io_out_0_bits_exceptionVec_22;
  logic          g_io_out_0_bits_exceptionVec_23;
  logic          g_io_out_0_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_0_bits_trigger;
  logic          g_io_out_0_bits_preDecodeInfo_valid;
  logic          g_io_out_0_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_0_bits_preDecodeInfo_brType;
  logic          g_io_out_0_bits_preDecodeInfo_isCall;
  logic          g_io_out_0_bits_preDecodeInfo_isRet;
  logic          g_io_out_0_bits_pred_taken;
  logic          g_io_out_0_bits_crossPageIPFFix;
  logic          g_io_out_0_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_0_bits_ftqPtr_value;
  logic [3:0]    g_io_out_0_bits_ftqOffset;
  logic          g_io_out_0_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_0_bits_srcType_0;
  logic [3:0]    g_io_out_0_bits_srcType_1;
  logic [3:0]    g_io_out_0_bits_srcType_2;
  logic [3:0]    g_io_out_0_bits_srcType_3;
  logic [3:0]    g_io_out_0_bits_srcType_4;
  logic [5:0]    g_io_out_0_bits_lsrc_0;
  logic [5:0]    g_io_out_0_bits_lsrc_1;
  logic [5:0]    g_io_out_0_bits_lsrc_2;
  logic [5:0]    g_io_out_0_bits_ldest;
  logic [34:0]   g_io_out_0_bits_fuType;
  logic [8:0]    g_io_out_0_bits_fuOpType;
  logic          g_io_out_0_bits_rfWen;
  logic          g_io_out_0_bits_fpWen;
  logic          g_io_out_0_bits_vecWen;
  logic          g_io_out_0_bits_v0Wen;
  logic          g_io_out_0_bits_vlWen;
  logic          g_io_out_0_bits_isXSTrap;
  logic          g_io_out_0_bits_waitForward;
  logic          g_io_out_0_bits_blockBackward;
  logic          g_io_out_0_bits_flushPipe;
  logic          g_io_out_0_bits_canRobCompress;
  logic [3:0]    g_io_out_0_bits_selImm;
  logic [21:0]   g_io_out_0_bits_imm;
  logic [1:0]    g_io_out_0_bits_fpu_typeTagOut;
  logic          g_io_out_0_bits_fpu_wflags;
  logic [1:0]    g_io_out_0_bits_fpu_typ;
  logic [1:0]    g_io_out_0_bits_fpu_fmt;
  logic [2:0]    g_io_out_0_bits_fpu_rm;
  logic          g_io_out_0_bits_vpu_vill;
  logic          g_io_out_0_bits_vpu_vma;
  logic          g_io_out_0_bits_vpu_vta;
  logic [1:0]    g_io_out_0_bits_vpu_vsew;
  logic [2:0]    g_io_out_0_bits_vpu_vlmul;
  logic          g_io_out_0_bits_vpu_specVill;
  logic          g_io_out_0_bits_vpu_specVma;
  logic          g_io_out_0_bits_vpu_specVta;
  logic [1:0]    g_io_out_0_bits_vpu_specVsew;
  logic [2:0]    g_io_out_0_bits_vpu_specVlmul;
  logic          g_io_out_0_bits_vpu_vm;
  logic [7:0]    g_io_out_0_bits_vpu_vstart;
  logic          g_io_out_0_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_0_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_0_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_0_bits_vpu_nf;
  logic [1:0]    g_io_out_0_bits_vpu_veew;
  logic          g_io_out_0_bits_vpu_isReverse;
  logic          g_io_out_0_bits_vpu_isExt;
  logic          g_io_out_0_bits_vpu_isNarrow;
  logic          g_io_out_0_bits_vpu_isDstMask;
  logic          g_io_out_0_bits_vpu_isOpMask;
  logic          g_io_out_0_bits_vpu_isDependOldVd;
  logic          g_io_out_0_bits_vpu_isWritePartVd;
  logic          g_io_out_0_bits_vpu_isVleff;
  logic          g_io_out_0_bits_vlsInstr;
  logic          g_io_out_0_bits_wfflags;
  logic          g_io_out_0_bits_isMove;
  logic [6:0]    g_io_out_0_bits_uopIdx;
  logic [5:0]    g_io_out_0_bits_uopSplitType;
  logic          g_io_out_0_bits_isVset;
  logic          g_io_out_0_bits_firstUop;
  logic          g_io_out_0_bits_lastUop;
  logic [6:0]    g_io_out_0_bits_numUops;
  logic [6:0]    g_io_out_0_bits_numWB;
  logic [2:0]    g_io_out_0_bits_commitType;
  logic [34:0]   g_io_out_0_bits_debug_fuType;
  logic [55:0]   g_io_out_0_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_0_bits_debug_seqNum_uopIdx;
  logic          g_io_out_1_valid;
  logic [31:0]   g_io_out_1_bits_instr;
  logic [49:0]   g_io_out_1_bits_pc;
  logic [9:0]    g_io_out_1_bits_foldpc;
  logic          g_io_out_1_bits_exceptionVec_0;
  logic          g_io_out_1_bits_exceptionVec_1;
  logic          g_io_out_1_bits_exceptionVec_2;
  logic          g_io_out_1_bits_exceptionVec_3;
  logic          g_io_out_1_bits_exceptionVec_4;
  logic          g_io_out_1_bits_exceptionVec_5;
  logic          g_io_out_1_bits_exceptionVec_6;
  logic          g_io_out_1_bits_exceptionVec_7;
  logic          g_io_out_1_bits_exceptionVec_8;
  logic          g_io_out_1_bits_exceptionVec_9;
  logic          g_io_out_1_bits_exceptionVec_10;
  logic          g_io_out_1_bits_exceptionVec_11;
  logic          g_io_out_1_bits_exceptionVec_12;
  logic          g_io_out_1_bits_exceptionVec_13;
  logic          g_io_out_1_bits_exceptionVec_14;
  logic          g_io_out_1_bits_exceptionVec_15;
  logic          g_io_out_1_bits_exceptionVec_16;
  logic          g_io_out_1_bits_exceptionVec_17;
  logic          g_io_out_1_bits_exceptionVec_18;
  logic          g_io_out_1_bits_exceptionVec_19;
  logic          g_io_out_1_bits_exceptionVec_20;
  logic          g_io_out_1_bits_exceptionVec_21;
  logic          g_io_out_1_bits_exceptionVec_22;
  logic          g_io_out_1_bits_exceptionVec_23;
  logic          g_io_out_1_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_1_bits_trigger;
  logic          g_io_out_1_bits_preDecodeInfo_valid;
  logic          g_io_out_1_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_1_bits_preDecodeInfo_brType;
  logic          g_io_out_1_bits_preDecodeInfo_isCall;
  logic          g_io_out_1_bits_preDecodeInfo_isRet;
  logic          g_io_out_1_bits_pred_taken;
  logic          g_io_out_1_bits_crossPageIPFFix;
  logic          g_io_out_1_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_1_bits_ftqPtr_value;
  logic [3:0]    g_io_out_1_bits_ftqOffset;
  logic          g_io_out_1_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_1_bits_srcType_0;
  logic [3:0]    g_io_out_1_bits_srcType_1;
  logic [3:0]    g_io_out_1_bits_srcType_2;
  logic [3:0]    g_io_out_1_bits_srcType_3;
  logic [3:0]    g_io_out_1_bits_srcType_4;
  logic [5:0]    g_io_out_1_bits_lsrc_0;
  logic [5:0]    g_io_out_1_bits_lsrc_1;
  logic [5:0]    g_io_out_1_bits_lsrc_2;
  logic [5:0]    g_io_out_1_bits_ldest;
  logic [34:0]   g_io_out_1_bits_fuType;
  logic [8:0]    g_io_out_1_bits_fuOpType;
  logic          g_io_out_1_bits_rfWen;
  logic          g_io_out_1_bits_fpWen;
  logic          g_io_out_1_bits_vecWen;
  logic          g_io_out_1_bits_v0Wen;
  logic          g_io_out_1_bits_vlWen;
  logic          g_io_out_1_bits_isXSTrap;
  logic          g_io_out_1_bits_waitForward;
  logic          g_io_out_1_bits_blockBackward;
  logic          g_io_out_1_bits_flushPipe;
  logic          g_io_out_1_bits_canRobCompress;
  logic [3:0]    g_io_out_1_bits_selImm;
  logic [21:0]   g_io_out_1_bits_imm;
  logic [1:0]    g_io_out_1_bits_fpu_typeTagOut;
  logic          g_io_out_1_bits_fpu_wflags;
  logic [1:0]    g_io_out_1_bits_fpu_typ;
  logic [1:0]    g_io_out_1_bits_fpu_fmt;
  logic [2:0]    g_io_out_1_bits_fpu_rm;
  logic          g_io_out_1_bits_vpu_vill;
  logic          g_io_out_1_bits_vpu_vma;
  logic          g_io_out_1_bits_vpu_vta;
  logic [1:0]    g_io_out_1_bits_vpu_vsew;
  logic [2:0]    g_io_out_1_bits_vpu_vlmul;
  logic          g_io_out_1_bits_vpu_specVill;
  logic          g_io_out_1_bits_vpu_specVma;
  logic          g_io_out_1_bits_vpu_specVta;
  logic [1:0]    g_io_out_1_bits_vpu_specVsew;
  logic [2:0]    g_io_out_1_bits_vpu_specVlmul;
  logic          g_io_out_1_bits_vpu_vm;
  logic [7:0]    g_io_out_1_bits_vpu_vstart;
  logic          g_io_out_1_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_1_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_1_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_1_bits_vpu_nf;
  logic [1:0]    g_io_out_1_bits_vpu_veew;
  logic          g_io_out_1_bits_vpu_isReverse;
  logic          g_io_out_1_bits_vpu_isExt;
  logic          g_io_out_1_bits_vpu_isNarrow;
  logic          g_io_out_1_bits_vpu_isDstMask;
  logic          g_io_out_1_bits_vpu_isOpMask;
  logic          g_io_out_1_bits_vpu_isDependOldVd;
  logic          g_io_out_1_bits_vpu_isWritePartVd;
  logic          g_io_out_1_bits_vpu_isVleff;
  logic          g_io_out_1_bits_vlsInstr;
  logic          g_io_out_1_bits_wfflags;
  logic          g_io_out_1_bits_isMove;
  logic [6:0]    g_io_out_1_bits_uopIdx;
  logic [5:0]    g_io_out_1_bits_uopSplitType;
  logic          g_io_out_1_bits_isVset;
  logic          g_io_out_1_bits_firstUop;
  logic          g_io_out_1_bits_lastUop;
  logic [6:0]    g_io_out_1_bits_numUops;
  logic [6:0]    g_io_out_1_bits_numWB;
  logic [2:0]    g_io_out_1_bits_commitType;
  logic [34:0]   g_io_out_1_bits_debug_fuType;
  logic [55:0]   g_io_out_1_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_1_bits_debug_seqNum_uopIdx;
  logic          g_io_out_2_valid;
  logic [31:0]   g_io_out_2_bits_instr;
  logic [49:0]   g_io_out_2_bits_pc;
  logic [9:0]    g_io_out_2_bits_foldpc;
  logic          g_io_out_2_bits_exceptionVec_0;
  logic          g_io_out_2_bits_exceptionVec_1;
  logic          g_io_out_2_bits_exceptionVec_2;
  logic          g_io_out_2_bits_exceptionVec_3;
  logic          g_io_out_2_bits_exceptionVec_4;
  logic          g_io_out_2_bits_exceptionVec_5;
  logic          g_io_out_2_bits_exceptionVec_6;
  logic          g_io_out_2_bits_exceptionVec_7;
  logic          g_io_out_2_bits_exceptionVec_8;
  logic          g_io_out_2_bits_exceptionVec_9;
  logic          g_io_out_2_bits_exceptionVec_10;
  logic          g_io_out_2_bits_exceptionVec_11;
  logic          g_io_out_2_bits_exceptionVec_12;
  logic          g_io_out_2_bits_exceptionVec_13;
  logic          g_io_out_2_bits_exceptionVec_14;
  logic          g_io_out_2_bits_exceptionVec_15;
  logic          g_io_out_2_bits_exceptionVec_16;
  logic          g_io_out_2_bits_exceptionVec_17;
  logic          g_io_out_2_bits_exceptionVec_18;
  logic          g_io_out_2_bits_exceptionVec_19;
  logic          g_io_out_2_bits_exceptionVec_20;
  logic          g_io_out_2_bits_exceptionVec_21;
  logic          g_io_out_2_bits_exceptionVec_22;
  logic          g_io_out_2_bits_exceptionVec_23;
  logic          g_io_out_2_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_2_bits_trigger;
  logic          g_io_out_2_bits_preDecodeInfo_valid;
  logic          g_io_out_2_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_2_bits_preDecodeInfo_brType;
  logic          g_io_out_2_bits_preDecodeInfo_isCall;
  logic          g_io_out_2_bits_preDecodeInfo_isRet;
  logic          g_io_out_2_bits_pred_taken;
  logic          g_io_out_2_bits_crossPageIPFFix;
  logic          g_io_out_2_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_2_bits_ftqPtr_value;
  logic [3:0]    g_io_out_2_bits_ftqOffset;
  logic          g_io_out_2_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_2_bits_srcType_0;
  logic [3:0]    g_io_out_2_bits_srcType_1;
  logic [3:0]    g_io_out_2_bits_srcType_2;
  logic [3:0]    g_io_out_2_bits_srcType_3;
  logic [3:0]    g_io_out_2_bits_srcType_4;
  logic [5:0]    g_io_out_2_bits_lsrc_0;
  logic [5:0]    g_io_out_2_bits_lsrc_1;
  logic [5:0]    g_io_out_2_bits_lsrc_2;
  logic [5:0]    g_io_out_2_bits_ldest;
  logic [34:0]   g_io_out_2_bits_fuType;
  logic [8:0]    g_io_out_2_bits_fuOpType;
  logic          g_io_out_2_bits_rfWen;
  logic          g_io_out_2_bits_fpWen;
  logic          g_io_out_2_bits_vecWen;
  logic          g_io_out_2_bits_v0Wen;
  logic          g_io_out_2_bits_vlWen;
  logic          g_io_out_2_bits_isXSTrap;
  logic          g_io_out_2_bits_waitForward;
  logic          g_io_out_2_bits_blockBackward;
  logic          g_io_out_2_bits_flushPipe;
  logic          g_io_out_2_bits_canRobCompress;
  logic [3:0]    g_io_out_2_bits_selImm;
  logic [21:0]   g_io_out_2_bits_imm;
  logic [1:0]    g_io_out_2_bits_fpu_typeTagOut;
  logic          g_io_out_2_bits_fpu_wflags;
  logic [1:0]    g_io_out_2_bits_fpu_typ;
  logic [1:0]    g_io_out_2_bits_fpu_fmt;
  logic [2:0]    g_io_out_2_bits_fpu_rm;
  logic          g_io_out_2_bits_vpu_vill;
  logic          g_io_out_2_bits_vpu_vma;
  logic          g_io_out_2_bits_vpu_vta;
  logic [1:0]    g_io_out_2_bits_vpu_vsew;
  logic [2:0]    g_io_out_2_bits_vpu_vlmul;
  logic          g_io_out_2_bits_vpu_specVill;
  logic          g_io_out_2_bits_vpu_specVma;
  logic          g_io_out_2_bits_vpu_specVta;
  logic [1:0]    g_io_out_2_bits_vpu_specVsew;
  logic [2:0]    g_io_out_2_bits_vpu_specVlmul;
  logic          g_io_out_2_bits_vpu_vm;
  logic [7:0]    g_io_out_2_bits_vpu_vstart;
  logic          g_io_out_2_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_2_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_2_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_2_bits_vpu_nf;
  logic [1:0]    g_io_out_2_bits_vpu_veew;
  logic          g_io_out_2_bits_vpu_isReverse;
  logic          g_io_out_2_bits_vpu_isExt;
  logic          g_io_out_2_bits_vpu_isNarrow;
  logic          g_io_out_2_bits_vpu_isDstMask;
  logic          g_io_out_2_bits_vpu_isOpMask;
  logic          g_io_out_2_bits_vpu_isDependOldVd;
  logic          g_io_out_2_bits_vpu_isWritePartVd;
  logic          g_io_out_2_bits_vpu_isVleff;
  logic          g_io_out_2_bits_vlsInstr;
  logic          g_io_out_2_bits_wfflags;
  logic          g_io_out_2_bits_isMove;
  logic [6:0]    g_io_out_2_bits_uopIdx;
  logic [5:0]    g_io_out_2_bits_uopSplitType;
  logic          g_io_out_2_bits_isVset;
  logic          g_io_out_2_bits_firstUop;
  logic          g_io_out_2_bits_lastUop;
  logic [6:0]    g_io_out_2_bits_numUops;
  logic [6:0]    g_io_out_2_bits_numWB;
  logic [2:0]    g_io_out_2_bits_commitType;
  logic [34:0]   g_io_out_2_bits_debug_fuType;
  logic [55:0]   g_io_out_2_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_2_bits_debug_seqNum_uopIdx;
  logic          g_io_out_3_valid;
  logic [31:0]   g_io_out_3_bits_instr;
  logic [49:0]   g_io_out_3_bits_pc;
  logic [9:0]    g_io_out_3_bits_foldpc;
  logic          g_io_out_3_bits_exceptionVec_0;
  logic          g_io_out_3_bits_exceptionVec_1;
  logic          g_io_out_3_bits_exceptionVec_2;
  logic          g_io_out_3_bits_exceptionVec_3;
  logic          g_io_out_3_bits_exceptionVec_4;
  logic          g_io_out_3_bits_exceptionVec_5;
  logic          g_io_out_3_bits_exceptionVec_6;
  logic          g_io_out_3_bits_exceptionVec_7;
  logic          g_io_out_3_bits_exceptionVec_8;
  logic          g_io_out_3_bits_exceptionVec_9;
  logic          g_io_out_3_bits_exceptionVec_10;
  logic          g_io_out_3_bits_exceptionVec_11;
  logic          g_io_out_3_bits_exceptionVec_12;
  logic          g_io_out_3_bits_exceptionVec_13;
  logic          g_io_out_3_bits_exceptionVec_14;
  logic          g_io_out_3_bits_exceptionVec_15;
  logic          g_io_out_3_bits_exceptionVec_16;
  logic          g_io_out_3_bits_exceptionVec_17;
  logic          g_io_out_3_bits_exceptionVec_18;
  logic          g_io_out_3_bits_exceptionVec_19;
  logic          g_io_out_3_bits_exceptionVec_20;
  logic          g_io_out_3_bits_exceptionVec_21;
  logic          g_io_out_3_bits_exceptionVec_22;
  logic          g_io_out_3_bits_exceptionVec_23;
  logic          g_io_out_3_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_3_bits_trigger;
  logic          g_io_out_3_bits_preDecodeInfo_valid;
  logic          g_io_out_3_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_3_bits_preDecodeInfo_brType;
  logic          g_io_out_3_bits_preDecodeInfo_isCall;
  logic          g_io_out_3_bits_preDecodeInfo_isRet;
  logic          g_io_out_3_bits_pred_taken;
  logic          g_io_out_3_bits_crossPageIPFFix;
  logic          g_io_out_3_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_3_bits_ftqPtr_value;
  logic [3:0]    g_io_out_3_bits_ftqOffset;
  logic          g_io_out_3_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_3_bits_srcType_0;
  logic [3:0]    g_io_out_3_bits_srcType_1;
  logic [3:0]    g_io_out_3_bits_srcType_2;
  logic [3:0]    g_io_out_3_bits_srcType_3;
  logic [3:0]    g_io_out_3_bits_srcType_4;
  logic [5:0]    g_io_out_3_bits_lsrc_0;
  logic [5:0]    g_io_out_3_bits_lsrc_1;
  logic [5:0]    g_io_out_3_bits_lsrc_2;
  logic [5:0]    g_io_out_3_bits_ldest;
  logic [34:0]   g_io_out_3_bits_fuType;
  logic [8:0]    g_io_out_3_bits_fuOpType;
  logic          g_io_out_3_bits_rfWen;
  logic          g_io_out_3_bits_fpWen;
  logic          g_io_out_3_bits_vecWen;
  logic          g_io_out_3_bits_v0Wen;
  logic          g_io_out_3_bits_vlWen;
  logic          g_io_out_3_bits_isXSTrap;
  logic          g_io_out_3_bits_waitForward;
  logic          g_io_out_3_bits_blockBackward;
  logic          g_io_out_3_bits_flushPipe;
  logic          g_io_out_3_bits_canRobCompress;
  logic [3:0]    g_io_out_3_bits_selImm;
  logic [21:0]   g_io_out_3_bits_imm;
  logic [1:0]    g_io_out_3_bits_fpu_typeTagOut;
  logic          g_io_out_3_bits_fpu_wflags;
  logic [1:0]    g_io_out_3_bits_fpu_typ;
  logic [1:0]    g_io_out_3_bits_fpu_fmt;
  logic [2:0]    g_io_out_3_bits_fpu_rm;
  logic          g_io_out_3_bits_vpu_vill;
  logic          g_io_out_3_bits_vpu_vma;
  logic          g_io_out_3_bits_vpu_vta;
  logic [1:0]    g_io_out_3_bits_vpu_vsew;
  logic [2:0]    g_io_out_3_bits_vpu_vlmul;
  logic          g_io_out_3_bits_vpu_specVill;
  logic          g_io_out_3_bits_vpu_specVma;
  logic          g_io_out_3_bits_vpu_specVta;
  logic [1:0]    g_io_out_3_bits_vpu_specVsew;
  logic [2:0]    g_io_out_3_bits_vpu_specVlmul;
  logic          g_io_out_3_bits_vpu_vm;
  logic [7:0]    g_io_out_3_bits_vpu_vstart;
  logic          g_io_out_3_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_3_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_3_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_3_bits_vpu_nf;
  logic [1:0]    g_io_out_3_bits_vpu_veew;
  logic          g_io_out_3_bits_vpu_isReverse;
  logic          g_io_out_3_bits_vpu_isExt;
  logic          g_io_out_3_bits_vpu_isNarrow;
  logic          g_io_out_3_bits_vpu_isDstMask;
  logic          g_io_out_3_bits_vpu_isOpMask;
  logic          g_io_out_3_bits_vpu_isDependOldVd;
  logic          g_io_out_3_bits_vpu_isWritePartVd;
  logic          g_io_out_3_bits_vpu_isVleff;
  logic          g_io_out_3_bits_vlsInstr;
  logic          g_io_out_3_bits_wfflags;
  logic          g_io_out_3_bits_isMove;
  logic [6:0]    g_io_out_3_bits_uopIdx;
  logic [5:0]    g_io_out_3_bits_uopSplitType;
  logic          g_io_out_3_bits_isVset;
  logic          g_io_out_3_bits_firstUop;
  logic          g_io_out_3_bits_lastUop;
  logic [6:0]    g_io_out_3_bits_numUops;
  logic [6:0]    g_io_out_3_bits_numWB;
  logic [2:0]    g_io_out_3_bits_commitType;
  logic [34:0]   g_io_out_3_bits_debug_fuType;
  logic [55:0]   g_io_out_3_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_3_bits_debug_seqNum_uopIdx;
  logic          g_io_out_4_valid;
  logic [31:0]   g_io_out_4_bits_instr;
  logic [49:0]   g_io_out_4_bits_pc;
  logic [9:0]    g_io_out_4_bits_foldpc;
  logic          g_io_out_4_bits_exceptionVec_0;
  logic          g_io_out_4_bits_exceptionVec_1;
  logic          g_io_out_4_bits_exceptionVec_2;
  logic          g_io_out_4_bits_exceptionVec_3;
  logic          g_io_out_4_bits_exceptionVec_4;
  logic          g_io_out_4_bits_exceptionVec_5;
  logic          g_io_out_4_bits_exceptionVec_6;
  logic          g_io_out_4_bits_exceptionVec_7;
  logic          g_io_out_4_bits_exceptionVec_8;
  logic          g_io_out_4_bits_exceptionVec_9;
  logic          g_io_out_4_bits_exceptionVec_10;
  logic          g_io_out_4_bits_exceptionVec_11;
  logic          g_io_out_4_bits_exceptionVec_12;
  logic          g_io_out_4_bits_exceptionVec_13;
  logic          g_io_out_4_bits_exceptionVec_14;
  logic          g_io_out_4_bits_exceptionVec_15;
  logic          g_io_out_4_bits_exceptionVec_16;
  logic          g_io_out_4_bits_exceptionVec_17;
  logic          g_io_out_4_bits_exceptionVec_18;
  logic          g_io_out_4_bits_exceptionVec_19;
  logic          g_io_out_4_bits_exceptionVec_20;
  logic          g_io_out_4_bits_exceptionVec_21;
  logic          g_io_out_4_bits_exceptionVec_22;
  logic          g_io_out_4_bits_exceptionVec_23;
  logic          g_io_out_4_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_4_bits_trigger;
  logic          g_io_out_4_bits_preDecodeInfo_valid;
  logic          g_io_out_4_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_4_bits_preDecodeInfo_brType;
  logic          g_io_out_4_bits_preDecodeInfo_isCall;
  logic          g_io_out_4_bits_preDecodeInfo_isRet;
  logic          g_io_out_4_bits_pred_taken;
  logic          g_io_out_4_bits_crossPageIPFFix;
  logic          g_io_out_4_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_4_bits_ftqPtr_value;
  logic [3:0]    g_io_out_4_bits_ftqOffset;
  logic          g_io_out_4_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_4_bits_srcType_0;
  logic [3:0]    g_io_out_4_bits_srcType_1;
  logic [3:0]    g_io_out_4_bits_srcType_2;
  logic [3:0]    g_io_out_4_bits_srcType_3;
  logic [3:0]    g_io_out_4_bits_srcType_4;
  logic [5:0]    g_io_out_4_bits_lsrc_0;
  logic [5:0]    g_io_out_4_bits_lsrc_1;
  logic [5:0]    g_io_out_4_bits_lsrc_2;
  logic [5:0]    g_io_out_4_bits_ldest;
  logic [34:0]   g_io_out_4_bits_fuType;
  logic [8:0]    g_io_out_4_bits_fuOpType;
  logic          g_io_out_4_bits_rfWen;
  logic          g_io_out_4_bits_fpWen;
  logic          g_io_out_4_bits_vecWen;
  logic          g_io_out_4_bits_v0Wen;
  logic          g_io_out_4_bits_vlWen;
  logic          g_io_out_4_bits_isXSTrap;
  logic          g_io_out_4_bits_waitForward;
  logic          g_io_out_4_bits_blockBackward;
  logic          g_io_out_4_bits_flushPipe;
  logic          g_io_out_4_bits_canRobCompress;
  logic [3:0]    g_io_out_4_bits_selImm;
  logic [21:0]   g_io_out_4_bits_imm;
  logic [1:0]    g_io_out_4_bits_fpu_typeTagOut;
  logic          g_io_out_4_bits_fpu_wflags;
  logic [1:0]    g_io_out_4_bits_fpu_typ;
  logic [1:0]    g_io_out_4_bits_fpu_fmt;
  logic [2:0]    g_io_out_4_bits_fpu_rm;
  logic          g_io_out_4_bits_vpu_vill;
  logic          g_io_out_4_bits_vpu_vma;
  logic          g_io_out_4_bits_vpu_vta;
  logic [1:0]    g_io_out_4_bits_vpu_vsew;
  logic [2:0]    g_io_out_4_bits_vpu_vlmul;
  logic          g_io_out_4_bits_vpu_specVill;
  logic          g_io_out_4_bits_vpu_specVma;
  logic          g_io_out_4_bits_vpu_specVta;
  logic [1:0]    g_io_out_4_bits_vpu_specVsew;
  logic [2:0]    g_io_out_4_bits_vpu_specVlmul;
  logic          g_io_out_4_bits_vpu_vm;
  logic [7:0]    g_io_out_4_bits_vpu_vstart;
  logic          g_io_out_4_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_4_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_4_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_4_bits_vpu_nf;
  logic [1:0]    g_io_out_4_bits_vpu_veew;
  logic          g_io_out_4_bits_vpu_isReverse;
  logic          g_io_out_4_bits_vpu_isExt;
  logic          g_io_out_4_bits_vpu_isNarrow;
  logic          g_io_out_4_bits_vpu_isDstMask;
  logic          g_io_out_4_bits_vpu_isOpMask;
  logic          g_io_out_4_bits_vpu_isDependOldVd;
  logic          g_io_out_4_bits_vpu_isWritePartVd;
  logic          g_io_out_4_bits_vpu_isVleff;
  logic          g_io_out_4_bits_vlsInstr;
  logic          g_io_out_4_bits_wfflags;
  logic          g_io_out_4_bits_isMove;
  logic [6:0]    g_io_out_4_bits_uopIdx;
  logic [5:0]    g_io_out_4_bits_uopSplitType;
  logic          g_io_out_4_bits_isVset;
  logic          g_io_out_4_bits_firstUop;
  logic          g_io_out_4_bits_lastUop;
  logic [6:0]    g_io_out_4_bits_numUops;
  logic [6:0]    g_io_out_4_bits_numWB;
  logic [2:0]    g_io_out_4_bits_commitType;
  logic [34:0]   g_io_out_4_bits_debug_fuType;
  logic [55:0]   g_io_out_4_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_4_bits_debug_seqNum_uopIdx;
  logic          g_io_out_5_valid;
  logic [31:0]   g_io_out_5_bits_instr;
  logic [49:0]   g_io_out_5_bits_pc;
  logic [9:0]    g_io_out_5_bits_foldpc;
  logic          g_io_out_5_bits_exceptionVec_0;
  logic          g_io_out_5_bits_exceptionVec_1;
  logic          g_io_out_5_bits_exceptionVec_2;
  logic          g_io_out_5_bits_exceptionVec_3;
  logic          g_io_out_5_bits_exceptionVec_4;
  logic          g_io_out_5_bits_exceptionVec_5;
  logic          g_io_out_5_bits_exceptionVec_6;
  logic          g_io_out_5_bits_exceptionVec_7;
  logic          g_io_out_5_bits_exceptionVec_8;
  logic          g_io_out_5_bits_exceptionVec_9;
  logic          g_io_out_5_bits_exceptionVec_10;
  logic          g_io_out_5_bits_exceptionVec_11;
  logic          g_io_out_5_bits_exceptionVec_12;
  logic          g_io_out_5_bits_exceptionVec_13;
  logic          g_io_out_5_bits_exceptionVec_14;
  logic          g_io_out_5_bits_exceptionVec_15;
  logic          g_io_out_5_bits_exceptionVec_16;
  logic          g_io_out_5_bits_exceptionVec_17;
  logic          g_io_out_5_bits_exceptionVec_18;
  logic          g_io_out_5_bits_exceptionVec_19;
  logic          g_io_out_5_bits_exceptionVec_20;
  logic          g_io_out_5_bits_exceptionVec_21;
  logic          g_io_out_5_bits_exceptionVec_22;
  logic          g_io_out_5_bits_exceptionVec_23;
  logic          g_io_out_5_bits_isFetchMalAddr;
  logic [3:0]    g_io_out_5_bits_trigger;
  logic          g_io_out_5_bits_preDecodeInfo_valid;
  logic          g_io_out_5_bits_preDecodeInfo_isRVC;
  logic [1:0]    g_io_out_5_bits_preDecodeInfo_brType;
  logic          g_io_out_5_bits_preDecodeInfo_isCall;
  logic          g_io_out_5_bits_preDecodeInfo_isRet;
  logic          g_io_out_5_bits_pred_taken;
  logic          g_io_out_5_bits_crossPageIPFFix;
  logic          g_io_out_5_bits_ftqPtr_flag;
  logic [5:0]    g_io_out_5_bits_ftqPtr_value;
  logic [3:0]    g_io_out_5_bits_ftqOffset;
  logic          g_io_out_5_bits_satpFlushFirstFetchFault;
  logic [3:0]    g_io_out_5_bits_srcType_0;
  logic [3:0]    g_io_out_5_bits_srcType_1;
  logic [3:0]    g_io_out_5_bits_srcType_2;
  logic [3:0]    g_io_out_5_bits_srcType_3;
  logic [3:0]    g_io_out_5_bits_srcType_4;
  logic [5:0]    g_io_out_5_bits_lsrc_0;
  logic [5:0]    g_io_out_5_bits_lsrc_1;
  logic [5:0]    g_io_out_5_bits_lsrc_2;
  logic [5:0]    g_io_out_5_bits_ldest;
  logic [34:0]   g_io_out_5_bits_fuType;
  logic [8:0]    g_io_out_5_bits_fuOpType;
  logic          g_io_out_5_bits_rfWen;
  logic          g_io_out_5_bits_fpWen;
  logic          g_io_out_5_bits_vecWen;
  logic          g_io_out_5_bits_v0Wen;
  logic          g_io_out_5_bits_vlWen;
  logic          g_io_out_5_bits_isXSTrap;
  logic          g_io_out_5_bits_waitForward;
  logic          g_io_out_5_bits_blockBackward;
  logic          g_io_out_5_bits_flushPipe;
  logic          g_io_out_5_bits_canRobCompress;
  logic [3:0]    g_io_out_5_bits_selImm;
  logic [21:0]   g_io_out_5_bits_imm;
  logic [1:0]    g_io_out_5_bits_fpu_typeTagOut;
  logic          g_io_out_5_bits_fpu_wflags;
  logic [1:0]    g_io_out_5_bits_fpu_typ;
  logic [1:0]    g_io_out_5_bits_fpu_fmt;
  logic [2:0]    g_io_out_5_bits_fpu_rm;
  logic          g_io_out_5_bits_vpu_vill;
  logic          g_io_out_5_bits_vpu_vma;
  logic          g_io_out_5_bits_vpu_vta;
  logic [1:0]    g_io_out_5_bits_vpu_vsew;
  logic [2:0]    g_io_out_5_bits_vpu_vlmul;
  logic          g_io_out_5_bits_vpu_specVill;
  logic          g_io_out_5_bits_vpu_specVma;
  logic          g_io_out_5_bits_vpu_specVta;
  logic [1:0]    g_io_out_5_bits_vpu_specVsew;
  logic [2:0]    g_io_out_5_bits_vpu_specVlmul;
  logic          g_io_out_5_bits_vpu_vm;
  logic [7:0]    g_io_out_5_bits_vpu_vstart;
  logic          g_io_out_5_bits_vpu_fpu_isFoldTo1_2;
  logic          g_io_out_5_bits_vpu_fpu_isFoldTo1_4;
  logic          g_io_out_5_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    g_io_out_5_bits_vpu_nf;
  logic [1:0]    g_io_out_5_bits_vpu_veew;
  logic          g_io_out_5_bits_vpu_isReverse;
  logic          g_io_out_5_bits_vpu_isExt;
  logic          g_io_out_5_bits_vpu_isNarrow;
  logic          g_io_out_5_bits_vpu_isDstMask;
  logic          g_io_out_5_bits_vpu_isOpMask;
  logic          g_io_out_5_bits_vpu_isDependOldVd;
  logic          g_io_out_5_bits_vpu_isWritePartVd;
  logic          g_io_out_5_bits_vpu_isVleff;
  logic          g_io_out_5_bits_vlsInstr;
  logic          g_io_out_5_bits_wfflags;
  logic          g_io_out_5_bits_isMove;
  logic [6:0]    g_io_out_5_bits_uopIdx;
  logic [5:0]    g_io_out_5_bits_uopSplitType;
  logic          g_io_out_5_bits_isVset;
  logic          g_io_out_5_bits_firstUop;
  logic          g_io_out_5_bits_lastUop;
  logic [6:0]    g_io_out_5_bits_numUops;
  logic [6:0]    g_io_out_5_bits_numWB;
  logic [2:0]    g_io_out_5_bits_commitType;
  logic [34:0]   g_io_out_5_bits_debug_fuType;
  logic [55:0]   g_io_out_5_bits_debug_seqNum_seqNum;
  logic [7:0]    g_io_out_5_bits_debug_seqNum_uopIdx;
  logic          g_io_intRat_0_0_hold;
  logic [31:0]   g_io_intRat_0_0_addr;
  logic          g_io_intRat_0_1_hold;
  logic [31:0]   g_io_intRat_0_1_addr;
  logic          g_io_intRat_1_0_hold;
  logic [31:0]   g_io_intRat_1_0_addr;
  logic          g_io_intRat_1_1_hold;
  logic [31:0]   g_io_intRat_1_1_addr;
  logic          g_io_intRat_2_0_hold;
  logic [31:0]   g_io_intRat_2_0_addr;
  logic          g_io_intRat_2_1_hold;
  logic [31:0]   g_io_intRat_2_1_addr;
  logic          g_io_intRat_3_0_hold;
  logic [31:0]   g_io_intRat_3_0_addr;
  logic          g_io_intRat_3_1_hold;
  logic [31:0]   g_io_intRat_3_1_addr;
  logic          g_io_intRat_4_0_hold;
  logic [31:0]   g_io_intRat_4_0_addr;
  logic          g_io_intRat_4_1_hold;
  logic [31:0]   g_io_intRat_4_1_addr;
  logic          g_io_intRat_5_0_hold;
  logic [31:0]   g_io_intRat_5_0_addr;
  logic          g_io_intRat_5_1_hold;
  logic [31:0]   g_io_intRat_5_1_addr;
  logic          g_io_fpRat_0_0_hold;
  logic [33:0]   g_io_fpRat_0_0_addr;
  logic          g_io_fpRat_0_1_hold;
  logic [33:0]   g_io_fpRat_0_1_addr;
  logic          g_io_fpRat_0_2_hold;
  logic [33:0]   g_io_fpRat_0_2_addr;
  logic          g_io_fpRat_1_0_hold;
  logic [33:0]   g_io_fpRat_1_0_addr;
  logic          g_io_fpRat_1_1_hold;
  logic [33:0]   g_io_fpRat_1_1_addr;
  logic          g_io_fpRat_1_2_hold;
  logic [33:0]   g_io_fpRat_1_2_addr;
  logic          g_io_fpRat_2_0_hold;
  logic [33:0]   g_io_fpRat_2_0_addr;
  logic          g_io_fpRat_2_1_hold;
  logic [33:0]   g_io_fpRat_2_1_addr;
  logic          g_io_fpRat_2_2_hold;
  logic [33:0]   g_io_fpRat_2_2_addr;
  logic          g_io_fpRat_3_0_hold;
  logic [33:0]   g_io_fpRat_3_0_addr;
  logic          g_io_fpRat_3_1_hold;
  logic [33:0]   g_io_fpRat_3_1_addr;
  logic          g_io_fpRat_3_2_hold;
  logic [33:0]   g_io_fpRat_3_2_addr;
  logic          g_io_fpRat_4_0_hold;
  logic [33:0]   g_io_fpRat_4_0_addr;
  logic          g_io_fpRat_4_1_hold;
  logic [33:0]   g_io_fpRat_4_1_addr;
  logic          g_io_fpRat_4_2_hold;
  logic [33:0]   g_io_fpRat_4_2_addr;
  logic          g_io_fpRat_5_0_hold;
  logic [33:0]   g_io_fpRat_5_0_addr;
  logic          g_io_fpRat_5_1_hold;
  logic [33:0]   g_io_fpRat_5_1_addr;
  logic          g_io_fpRat_5_2_hold;
  logic [33:0]   g_io_fpRat_5_2_addr;
  logic          g_io_vecRat_0_0_hold;
  logic [46:0]   g_io_vecRat_0_0_addr;
  logic          g_io_vecRat_0_1_hold;
  logic [46:0]   g_io_vecRat_0_1_addr;
  logic          g_io_vecRat_0_2_hold;
  logic [46:0]   g_io_vecRat_0_2_addr;
  logic          g_io_vecRat_1_0_hold;
  logic [46:0]   g_io_vecRat_1_0_addr;
  logic          g_io_vecRat_1_1_hold;
  logic [46:0]   g_io_vecRat_1_1_addr;
  logic          g_io_vecRat_1_2_hold;
  logic [46:0]   g_io_vecRat_1_2_addr;
  logic          g_io_vecRat_2_0_hold;
  logic [46:0]   g_io_vecRat_2_0_addr;
  logic          g_io_vecRat_2_1_hold;
  logic [46:0]   g_io_vecRat_2_1_addr;
  logic          g_io_vecRat_2_2_hold;
  logic [46:0]   g_io_vecRat_2_2_addr;
  logic          g_io_vecRat_3_0_hold;
  logic [46:0]   g_io_vecRat_3_0_addr;
  logic          g_io_vecRat_3_1_hold;
  logic [46:0]   g_io_vecRat_3_1_addr;
  logic          g_io_vecRat_3_2_hold;
  logic [46:0]   g_io_vecRat_3_2_addr;
  logic          g_io_vecRat_4_0_hold;
  logic [46:0]   g_io_vecRat_4_0_addr;
  logic          g_io_vecRat_4_1_hold;
  logic [46:0]   g_io_vecRat_4_1_addr;
  logic          g_io_vecRat_4_2_hold;
  logic [46:0]   g_io_vecRat_4_2_addr;
  logic          g_io_vecRat_5_0_hold;
  logic [46:0]   g_io_vecRat_5_0_addr;
  logic          g_io_vecRat_5_1_hold;
  logic [46:0]   g_io_vecRat_5_1_addr;
  logic          g_io_vecRat_5_2_hold;
  logic [46:0]   g_io_vecRat_5_2_addr;
  logic          g_io_v0Rat_0_hold;
  logic          g_io_v0Rat_1_hold;
  logic          g_io_v0Rat_2_hold;
  logic          g_io_v0Rat_3_hold;
  logic          g_io_v0Rat_4_hold;
  logic          g_io_v0Rat_5_hold;
  logic          g_io_vlRat_0_hold;
  logic          g_io_vlRat_1_hold;
  logic          g_io_vlRat_2_hold;
  logic          g_io_vlRat_3_hold;
  logic          g_io_vlRat_4_hold;
  logic          g_io_vlRat_5_hold;
  logic          g_io_stallReason_in_backReason_valid;
  logic [5:0]    g_io_stallReason_in_backReason_bits;
  logic [5:0]    g_io_stallReason_out_reason_0;
  logic [5:0]    g_io_stallReason_out_reason_1;
  logic [5:0]    g_io_stallReason_out_reason_2;
  logic [5:0]    g_io_stallReason_out_reason_3;
  logic [5:0]    g_io_stallReason_out_reason_4;
  logic [5:0]    g_io_stallReason_out_reason_5;
  logic          g_io_toCSR_trapInstInfo_valid;
  logic [31:0]   g_io_toCSR_trapInstInfo_bits_instr;
  logic          g_io_toCSR_trapInstInfo_bits_ftqPtr_flag;
  logic [5:0]    g_io_toCSR_trapInstInfo_bits_ftqPtr_value;
  logic [3:0]    g_io_toCSR_trapInstInfo_bits_ftqOffset;
  logic [5:0]    g_io_perf_0_value;
  logic [5:0]    g_io_perf_1_value;
  logic [5:0]    g_io_perf_2_value;
  logic [5:0]    g_io_perf_3_value;
  logic [5:0]    g_io_perf_4_value;
  logic [5:0]    g_io_perf_5_value;
  logic [5:0]    g_io_perf_6_value;
  logic [5:0]    g_io_perf_7_value;
  logic          x_io_in_0_ready;
  logic          x_io_in_1_ready;
  logic          x_io_in_2_ready;
  logic          x_io_in_3_ready;
  logic          x_io_in_4_ready;
  logic          x_io_in_5_ready;
  logic          x_io_out_0_valid;
  logic [31:0]   x_io_out_0_bits_instr;
  logic [49:0]   x_io_out_0_bits_pc;
  logic [9:0]    x_io_out_0_bits_foldpc;
  logic          x_io_out_0_bits_exceptionVec_0;
  logic          x_io_out_0_bits_exceptionVec_1;
  logic          x_io_out_0_bits_exceptionVec_2;
  logic          x_io_out_0_bits_exceptionVec_3;
  logic          x_io_out_0_bits_exceptionVec_4;
  logic          x_io_out_0_bits_exceptionVec_5;
  logic          x_io_out_0_bits_exceptionVec_6;
  logic          x_io_out_0_bits_exceptionVec_7;
  logic          x_io_out_0_bits_exceptionVec_8;
  logic          x_io_out_0_bits_exceptionVec_9;
  logic          x_io_out_0_bits_exceptionVec_10;
  logic          x_io_out_0_bits_exceptionVec_11;
  logic          x_io_out_0_bits_exceptionVec_12;
  logic          x_io_out_0_bits_exceptionVec_13;
  logic          x_io_out_0_bits_exceptionVec_14;
  logic          x_io_out_0_bits_exceptionVec_15;
  logic          x_io_out_0_bits_exceptionVec_16;
  logic          x_io_out_0_bits_exceptionVec_17;
  logic          x_io_out_0_bits_exceptionVec_18;
  logic          x_io_out_0_bits_exceptionVec_19;
  logic          x_io_out_0_bits_exceptionVec_20;
  logic          x_io_out_0_bits_exceptionVec_21;
  logic          x_io_out_0_bits_exceptionVec_22;
  logic          x_io_out_0_bits_exceptionVec_23;
  logic          x_io_out_0_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_0_bits_trigger;
  logic          x_io_out_0_bits_preDecodeInfo_valid;
  logic          x_io_out_0_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_0_bits_preDecodeInfo_brType;
  logic          x_io_out_0_bits_preDecodeInfo_isCall;
  logic          x_io_out_0_bits_preDecodeInfo_isRet;
  logic          x_io_out_0_bits_pred_taken;
  logic          x_io_out_0_bits_crossPageIPFFix;
  logic          x_io_out_0_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_0_bits_ftqPtr_value;
  logic [3:0]    x_io_out_0_bits_ftqOffset;
  logic          x_io_out_0_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_0_bits_srcType_0;
  logic [3:0]    x_io_out_0_bits_srcType_1;
  logic [3:0]    x_io_out_0_bits_srcType_2;
  logic [3:0]    x_io_out_0_bits_srcType_3;
  logic [3:0]    x_io_out_0_bits_srcType_4;
  logic [5:0]    x_io_out_0_bits_lsrc_0;
  logic [5:0]    x_io_out_0_bits_lsrc_1;
  logic [5:0]    x_io_out_0_bits_lsrc_2;
  logic [5:0]    x_io_out_0_bits_ldest;
  logic [34:0]   x_io_out_0_bits_fuType;
  logic [8:0]    x_io_out_0_bits_fuOpType;
  logic          x_io_out_0_bits_rfWen;
  logic          x_io_out_0_bits_fpWen;
  logic          x_io_out_0_bits_vecWen;
  logic          x_io_out_0_bits_v0Wen;
  logic          x_io_out_0_bits_vlWen;
  logic          x_io_out_0_bits_isXSTrap;
  logic          x_io_out_0_bits_waitForward;
  logic          x_io_out_0_bits_blockBackward;
  logic          x_io_out_0_bits_flushPipe;
  logic          x_io_out_0_bits_canRobCompress;
  logic [3:0]    x_io_out_0_bits_selImm;
  logic [21:0]   x_io_out_0_bits_imm;
  logic [1:0]    x_io_out_0_bits_fpu_typeTagOut;
  logic          x_io_out_0_bits_fpu_wflags;
  logic [1:0]    x_io_out_0_bits_fpu_typ;
  logic [1:0]    x_io_out_0_bits_fpu_fmt;
  logic [2:0]    x_io_out_0_bits_fpu_rm;
  logic          x_io_out_0_bits_vpu_vill;
  logic          x_io_out_0_bits_vpu_vma;
  logic          x_io_out_0_bits_vpu_vta;
  logic [1:0]    x_io_out_0_bits_vpu_vsew;
  logic [2:0]    x_io_out_0_bits_vpu_vlmul;
  logic          x_io_out_0_bits_vpu_specVill;
  logic          x_io_out_0_bits_vpu_specVma;
  logic          x_io_out_0_bits_vpu_specVta;
  logic [1:0]    x_io_out_0_bits_vpu_specVsew;
  logic [2:0]    x_io_out_0_bits_vpu_specVlmul;
  logic          x_io_out_0_bits_vpu_vm;
  logic [7:0]    x_io_out_0_bits_vpu_vstart;
  logic          x_io_out_0_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_0_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_0_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_0_bits_vpu_nf;
  logic [1:0]    x_io_out_0_bits_vpu_veew;
  logic          x_io_out_0_bits_vpu_isReverse;
  logic          x_io_out_0_bits_vpu_isExt;
  logic          x_io_out_0_bits_vpu_isNarrow;
  logic          x_io_out_0_bits_vpu_isDstMask;
  logic          x_io_out_0_bits_vpu_isOpMask;
  logic          x_io_out_0_bits_vpu_isDependOldVd;
  logic          x_io_out_0_bits_vpu_isWritePartVd;
  logic          x_io_out_0_bits_vpu_isVleff;
  logic          x_io_out_0_bits_vlsInstr;
  logic          x_io_out_0_bits_wfflags;
  logic          x_io_out_0_bits_isMove;
  logic [6:0]    x_io_out_0_bits_uopIdx;
  logic [5:0]    x_io_out_0_bits_uopSplitType;
  logic          x_io_out_0_bits_isVset;
  logic          x_io_out_0_bits_firstUop;
  logic          x_io_out_0_bits_lastUop;
  logic [6:0]    x_io_out_0_bits_numUops;
  logic [6:0]    x_io_out_0_bits_numWB;
  logic [2:0]    x_io_out_0_bits_commitType;
  logic [34:0]   x_io_out_0_bits_debug_fuType;
  logic [55:0]   x_io_out_0_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_0_bits_debug_seqNum_uopIdx;
  logic          x_io_out_1_valid;
  logic [31:0]   x_io_out_1_bits_instr;
  logic [49:0]   x_io_out_1_bits_pc;
  logic [9:0]    x_io_out_1_bits_foldpc;
  logic          x_io_out_1_bits_exceptionVec_0;
  logic          x_io_out_1_bits_exceptionVec_1;
  logic          x_io_out_1_bits_exceptionVec_2;
  logic          x_io_out_1_bits_exceptionVec_3;
  logic          x_io_out_1_bits_exceptionVec_4;
  logic          x_io_out_1_bits_exceptionVec_5;
  logic          x_io_out_1_bits_exceptionVec_6;
  logic          x_io_out_1_bits_exceptionVec_7;
  logic          x_io_out_1_bits_exceptionVec_8;
  logic          x_io_out_1_bits_exceptionVec_9;
  logic          x_io_out_1_bits_exceptionVec_10;
  logic          x_io_out_1_bits_exceptionVec_11;
  logic          x_io_out_1_bits_exceptionVec_12;
  logic          x_io_out_1_bits_exceptionVec_13;
  logic          x_io_out_1_bits_exceptionVec_14;
  logic          x_io_out_1_bits_exceptionVec_15;
  logic          x_io_out_1_bits_exceptionVec_16;
  logic          x_io_out_1_bits_exceptionVec_17;
  logic          x_io_out_1_bits_exceptionVec_18;
  logic          x_io_out_1_bits_exceptionVec_19;
  logic          x_io_out_1_bits_exceptionVec_20;
  logic          x_io_out_1_bits_exceptionVec_21;
  logic          x_io_out_1_bits_exceptionVec_22;
  logic          x_io_out_1_bits_exceptionVec_23;
  logic          x_io_out_1_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_1_bits_trigger;
  logic          x_io_out_1_bits_preDecodeInfo_valid;
  logic          x_io_out_1_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_1_bits_preDecodeInfo_brType;
  logic          x_io_out_1_bits_preDecodeInfo_isCall;
  logic          x_io_out_1_bits_preDecodeInfo_isRet;
  logic          x_io_out_1_bits_pred_taken;
  logic          x_io_out_1_bits_crossPageIPFFix;
  logic          x_io_out_1_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_1_bits_ftqPtr_value;
  logic [3:0]    x_io_out_1_bits_ftqOffset;
  logic          x_io_out_1_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_1_bits_srcType_0;
  logic [3:0]    x_io_out_1_bits_srcType_1;
  logic [3:0]    x_io_out_1_bits_srcType_2;
  logic [3:0]    x_io_out_1_bits_srcType_3;
  logic [3:0]    x_io_out_1_bits_srcType_4;
  logic [5:0]    x_io_out_1_bits_lsrc_0;
  logic [5:0]    x_io_out_1_bits_lsrc_1;
  logic [5:0]    x_io_out_1_bits_lsrc_2;
  logic [5:0]    x_io_out_1_bits_ldest;
  logic [34:0]   x_io_out_1_bits_fuType;
  logic [8:0]    x_io_out_1_bits_fuOpType;
  logic          x_io_out_1_bits_rfWen;
  logic          x_io_out_1_bits_fpWen;
  logic          x_io_out_1_bits_vecWen;
  logic          x_io_out_1_bits_v0Wen;
  logic          x_io_out_1_bits_vlWen;
  logic          x_io_out_1_bits_isXSTrap;
  logic          x_io_out_1_bits_waitForward;
  logic          x_io_out_1_bits_blockBackward;
  logic          x_io_out_1_bits_flushPipe;
  logic          x_io_out_1_bits_canRobCompress;
  logic [3:0]    x_io_out_1_bits_selImm;
  logic [21:0]   x_io_out_1_bits_imm;
  logic [1:0]    x_io_out_1_bits_fpu_typeTagOut;
  logic          x_io_out_1_bits_fpu_wflags;
  logic [1:0]    x_io_out_1_bits_fpu_typ;
  logic [1:0]    x_io_out_1_bits_fpu_fmt;
  logic [2:0]    x_io_out_1_bits_fpu_rm;
  logic          x_io_out_1_bits_vpu_vill;
  logic          x_io_out_1_bits_vpu_vma;
  logic          x_io_out_1_bits_vpu_vta;
  logic [1:0]    x_io_out_1_bits_vpu_vsew;
  logic [2:0]    x_io_out_1_bits_vpu_vlmul;
  logic          x_io_out_1_bits_vpu_specVill;
  logic          x_io_out_1_bits_vpu_specVma;
  logic          x_io_out_1_bits_vpu_specVta;
  logic [1:0]    x_io_out_1_bits_vpu_specVsew;
  logic [2:0]    x_io_out_1_bits_vpu_specVlmul;
  logic          x_io_out_1_bits_vpu_vm;
  logic [7:0]    x_io_out_1_bits_vpu_vstart;
  logic          x_io_out_1_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_1_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_1_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_1_bits_vpu_nf;
  logic [1:0]    x_io_out_1_bits_vpu_veew;
  logic          x_io_out_1_bits_vpu_isReverse;
  logic          x_io_out_1_bits_vpu_isExt;
  logic          x_io_out_1_bits_vpu_isNarrow;
  logic          x_io_out_1_bits_vpu_isDstMask;
  logic          x_io_out_1_bits_vpu_isOpMask;
  logic          x_io_out_1_bits_vpu_isDependOldVd;
  logic          x_io_out_1_bits_vpu_isWritePartVd;
  logic          x_io_out_1_bits_vpu_isVleff;
  logic          x_io_out_1_bits_vlsInstr;
  logic          x_io_out_1_bits_wfflags;
  logic          x_io_out_1_bits_isMove;
  logic [6:0]    x_io_out_1_bits_uopIdx;
  logic [5:0]    x_io_out_1_bits_uopSplitType;
  logic          x_io_out_1_bits_isVset;
  logic          x_io_out_1_bits_firstUop;
  logic          x_io_out_1_bits_lastUop;
  logic [6:0]    x_io_out_1_bits_numUops;
  logic [6:0]    x_io_out_1_bits_numWB;
  logic [2:0]    x_io_out_1_bits_commitType;
  logic [34:0]   x_io_out_1_bits_debug_fuType;
  logic [55:0]   x_io_out_1_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_1_bits_debug_seqNum_uopIdx;
  logic          x_io_out_2_valid;
  logic [31:0]   x_io_out_2_bits_instr;
  logic [49:0]   x_io_out_2_bits_pc;
  logic [9:0]    x_io_out_2_bits_foldpc;
  logic          x_io_out_2_bits_exceptionVec_0;
  logic          x_io_out_2_bits_exceptionVec_1;
  logic          x_io_out_2_bits_exceptionVec_2;
  logic          x_io_out_2_bits_exceptionVec_3;
  logic          x_io_out_2_bits_exceptionVec_4;
  logic          x_io_out_2_bits_exceptionVec_5;
  logic          x_io_out_2_bits_exceptionVec_6;
  logic          x_io_out_2_bits_exceptionVec_7;
  logic          x_io_out_2_bits_exceptionVec_8;
  logic          x_io_out_2_bits_exceptionVec_9;
  logic          x_io_out_2_bits_exceptionVec_10;
  logic          x_io_out_2_bits_exceptionVec_11;
  logic          x_io_out_2_bits_exceptionVec_12;
  logic          x_io_out_2_bits_exceptionVec_13;
  logic          x_io_out_2_bits_exceptionVec_14;
  logic          x_io_out_2_bits_exceptionVec_15;
  logic          x_io_out_2_bits_exceptionVec_16;
  logic          x_io_out_2_bits_exceptionVec_17;
  logic          x_io_out_2_bits_exceptionVec_18;
  logic          x_io_out_2_bits_exceptionVec_19;
  logic          x_io_out_2_bits_exceptionVec_20;
  logic          x_io_out_2_bits_exceptionVec_21;
  logic          x_io_out_2_bits_exceptionVec_22;
  logic          x_io_out_2_bits_exceptionVec_23;
  logic          x_io_out_2_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_2_bits_trigger;
  logic          x_io_out_2_bits_preDecodeInfo_valid;
  logic          x_io_out_2_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_2_bits_preDecodeInfo_brType;
  logic          x_io_out_2_bits_preDecodeInfo_isCall;
  logic          x_io_out_2_bits_preDecodeInfo_isRet;
  logic          x_io_out_2_bits_pred_taken;
  logic          x_io_out_2_bits_crossPageIPFFix;
  logic          x_io_out_2_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_2_bits_ftqPtr_value;
  logic [3:0]    x_io_out_2_bits_ftqOffset;
  logic          x_io_out_2_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_2_bits_srcType_0;
  logic [3:0]    x_io_out_2_bits_srcType_1;
  logic [3:0]    x_io_out_2_bits_srcType_2;
  logic [3:0]    x_io_out_2_bits_srcType_3;
  logic [3:0]    x_io_out_2_bits_srcType_4;
  logic [5:0]    x_io_out_2_bits_lsrc_0;
  logic [5:0]    x_io_out_2_bits_lsrc_1;
  logic [5:0]    x_io_out_2_bits_lsrc_2;
  logic [5:0]    x_io_out_2_bits_ldest;
  logic [34:0]   x_io_out_2_bits_fuType;
  logic [8:0]    x_io_out_2_bits_fuOpType;
  logic          x_io_out_2_bits_rfWen;
  logic          x_io_out_2_bits_fpWen;
  logic          x_io_out_2_bits_vecWen;
  logic          x_io_out_2_bits_v0Wen;
  logic          x_io_out_2_bits_vlWen;
  logic          x_io_out_2_bits_isXSTrap;
  logic          x_io_out_2_bits_waitForward;
  logic          x_io_out_2_bits_blockBackward;
  logic          x_io_out_2_bits_flushPipe;
  logic          x_io_out_2_bits_canRobCompress;
  logic [3:0]    x_io_out_2_bits_selImm;
  logic [21:0]   x_io_out_2_bits_imm;
  logic [1:0]    x_io_out_2_bits_fpu_typeTagOut;
  logic          x_io_out_2_bits_fpu_wflags;
  logic [1:0]    x_io_out_2_bits_fpu_typ;
  logic [1:0]    x_io_out_2_bits_fpu_fmt;
  logic [2:0]    x_io_out_2_bits_fpu_rm;
  logic          x_io_out_2_bits_vpu_vill;
  logic          x_io_out_2_bits_vpu_vma;
  logic          x_io_out_2_bits_vpu_vta;
  logic [1:0]    x_io_out_2_bits_vpu_vsew;
  logic [2:0]    x_io_out_2_bits_vpu_vlmul;
  logic          x_io_out_2_bits_vpu_specVill;
  logic          x_io_out_2_bits_vpu_specVma;
  logic          x_io_out_2_bits_vpu_specVta;
  logic [1:0]    x_io_out_2_bits_vpu_specVsew;
  logic [2:0]    x_io_out_2_bits_vpu_specVlmul;
  logic          x_io_out_2_bits_vpu_vm;
  logic [7:0]    x_io_out_2_bits_vpu_vstart;
  logic          x_io_out_2_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_2_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_2_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_2_bits_vpu_nf;
  logic [1:0]    x_io_out_2_bits_vpu_veew;
  logic          x_io_out_2_bits_vpu_isReverse;
  logic          x_io_out_2_bits_vpu_isExt;
  logic          x_io_out_2_bits_vpu_isNarrow;
  logic          x_io_out_2_bits_vpu_isDstMask;
  logic          x_io_out_2_bits_vpu_isOpMask;
  logic          x_io_out_2_bits_vpu_isDependOldVd;
  logic          x_io_out_2_bits_vpu_isWritePartVd;
  logic          x_io_out_2_bits_vpu_isVleff;
  logic          x_io_out_2_bits_vlsInstr;
  logic          x_io_out_2_bits_wfflags;
  logic          x_io_out_2_bits_isMove;
  logic [6:0]    x_io_out_2_bits_uopIdx;
  logic [5:0]    x_io_out_2_bits_uopSplitType;
  logic          x_io_out_2_bits_isVset;
  logic          x_io_out_2_bits_firstUop;
  logic          x_io_out_2_bits_lastUop;
  logic [6:0]    x_io_out_2_bits_numUops;
  logic [6:0]    x_io_out_2_bits_numWB;
  logic [2:0]    x_io_out_2_bits_commitType;
  logic [34:0]   x_io_out_2_bits_debug_fuType;
  logic [55:0]   x_io_out_2_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_2_bits_debug_seqNum_uopIdx;
  logic          x_io_out_3_valid;
  logic [31:0]   x_io_out_3_bits_instr;
  logic [49:0]   x_io_out_3_bits_pc;
  logic [9:0]    x_io_out_3_bits_foldpc;
  logic          x_io_out_3_bits_exceptionVec_0;
  logic          x_io_out_3_bits_exceptionVec_1;
  logic          x_io_out_3_bits_exceptionVec_2;
  logic          x_io_out_3_bits_exceptionVec_3;
  logic          x_io_out_3_bits_exceptionVec_4;
  logic          x_io_out_3_bits_exceptionVec_5;
  logic          x_io_out_3_bits_exceptionVec_6;
  logic          x_io_out_3_bits_exceptionVec_7;
  logic          x_io_out_3_bits_exceptionVec_8;
  logic          x_io_out_3_bits_exceptionVec_9;
  logic          x_io_out_3_bits_exceptionVec_10;
  logic          x_io_out_3_bits_exceptionVec_11;
  logic          x_io_out_3_bits_exceptionVec_12;
  logic          x_io_out_3_bits_exceptionVec_13;
  logic          x_io_out_3_bits_exceptionVec_14;
  logic          x_io_out_3_bits_exceptionVec_15;
  logic          x_io_out_3_bits_exceptionVec_16;
  logic          x_io_out_3_bits_exceptionVec_17;
  logic          x_io_out_3_bits_exceptionVec_18;
  logic          x_io_out_3_bits_exceptionVec_19;
  logic          x_io_out_3_bits_exceptionVec_20;
  logic          x_io_out_3_bits_exceptionVec_21;
  logic          x_io_out_3_bits_exceptionVec_22;
  logic          x_io_out_3_bits_exceptionVec_23;
  logic          x_io_out_3_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_3_bits_trigger;
  logic          x_io_out_3_bits_preDecodeInfo_valid;
  logic          x_io_out_3_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_3_bits_preDecodeInfo_brType;
  logic          x_io_out_3_bits_preDecodeInfo_isCall;
  logic          x_io_out_3_bits_preDecodeInfo_isRet;
  logic          x_io_out_3_bits_pred_taken;
  logic          x_io_out_3_bits_crossPageIPFFix;
  logic          x_io_out_3_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_3_bits_ftqPtr_value;
  logic [3:0]    x_io_out_3_bits_ftqOffset;
  logic          x_io_out_3_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_3_bits_srcType_0;
  logic [3:0]    x_io_out_3_bits_srcType_1;
  logic [3:0]    x_io_out_3_bits_srcType_2;
  logic [3:0]    x_io_out_3_bits_srcType_3;
  logic [3:0]    x_io_out_3_bits_srcType_4;
  logic [5:0]    x_io_out_3_bits_lsrc_0;
  logic [5:0]    x_io_out_3_bits_lsrc_1;
  logic [5:0]    x_io_out_3_bits_lsrc_2;
  logic [5:0]    x_io_out_3_bits_ldest;
  logic [34:0]   x_io_out_3_bits_fuType;
  logic [8:0]    x_io_out_3_bits_fuOpType;
  logic          x_io_out_3_bits_rfWen;
  logic          x_io_out_3_bits_fpWen;
  logic          x_io_out_3_bits_vecWen;
  logic          x_io_out_3_bits_v0Wen;
  logic          x_io_out_3_bits_vlWen;
  logic          x_io_out_3_bits_isXSTrap;
  logic          x_io_out_3_bits_waitForward;
  logic          x_io_out_3_bits_blockBackward;
  logic          x_io_out_3_bits_flushPipe;
  logic          x_io_out_3_bits_canRobCompress;
  logic [3:0]    x_io_out_3_bits_selImm;
  logic [21:0]   x_io_out_3_bits_imm;
  logic [1:0]    x_io_out_3_bits_fpu_typeTagOut;
  logic          x_io_out_3_bits_fpu_wflags;
  logic [1:0]    x_io_out_3_bits_fpu_typ;
  logic [1:0]    x_io_out_3_bits_fpu_fmt;
  logic [2:0]    x_io_out_3_bits_fpu_rm;
  logic          x_io_out_3_bits_vpu_vill;
  logic          x_io_out_3_bits_vpu_vma;
  logic          x_io_out_3_bits_vpu_vta;
  logic [1:0]    x_io_out_3_bits_vpu_vsew;
  logic [2:0]    x_io_out_3_bits_vpu_vlmul;
  logic          x_io_out_3_bits_vpu_specVill;
  logic          x_io_out_3_bits_vpu_specVma;
  logic          x_io_out_3_bits_vpu_specVta;
  logic [1:0]    x_io_out_3_bits_vpu_specVsew;
  logic [2:0]    x_io_out_3_bits_vpu_specVlmul;
  logic          x_io_out_3_bits_vpu_vm;
  logic [7:0]    x_io_out_3_bits_vpu_vstart;
  logic          x_io_out_3_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_3_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_3_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_3_bits_vpu_nf;
  logic [1:0]    x_io_out_3_bits_vpu_veew;
  logic          x_io_out_3_bits_vpu_isReverse;
  logic          x_io_out_3_bits_vpu_isExt;
  logic          x_io_out_3_bits_vpu_isNarrow;
  logic          x_io_out_3_bits_vpu_isDstMask;
  logic          x_io_out_3_bits_vpu_isOpMask;
  logic          x_io_out_3_bits_vpu_isDependOldVd;
  logic          x_io_out_3_bits_vpu_isWritePartVd;
  logic          x_io_out_3_bits_vpu_isVleff;
  logic          x_io_out_3_bits_vlsInstr;
  logic          x_io_out_3_bits_wfflags;
  logic          x_io_out_3_bits_isMove;
  logic [6:0]    x_io_out_3_bits_uopIdx;
  logic [5:0]    x_io_out_3_bits_uopSplitType;
  logic          x_io_out_3_bits_isVset;
  logic          x_io_out_3_bits_firstUop;
  logic          x_io_out_3_bits_lastUop;
  logic [6:0]    x_io_out_3_bits_numUops;
  logic [6:0]    x_io_out_3_bits_numWB;
  logic [2:0]    x_io_out_3_bits_commitType;
  logic [34:0]   x_io_out_3_bits_debug_fuType;
  logic [55:0]   x_io_out_3_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_3_bits_debug_seqNum_uopIdx;
  logic          x_io_out_4_valid;
  logic [31:0]   x_io_out_4_bits_instr;
  logic [49:0]   x_io_out_4_bits_pc;
  logic [9:0]    x_io_out_4_bits_foldpc;
  logic          x_io_out_4_bits_exceptionVec_0;
  logic          x_io_out_4_bits_exceptionVec_1;
  logic          x_io_out_4_bits_exceptionVec_2;
  logic          x_io_out_4_bits_exceptionVec_3;
  logic          x_io_out_4_bits_exceptionVec_4;
  logic          x_io_out_4_bits_exceptionVec_5;
  logic          x_io_out_4_bits_exceptionVec_6;
  logic          x_io_out_4_bits_exceptionVec_7;
  logic          x_io_out_4_bits_exceptionVec_8;
  logic          x_io_out_4_bits_exceptionVec_9;
  logic          x_io_out_4_bits_exceptionVec_10;
  logic          x_io_out_4_bits_exceptionVec_11;
  logic          x_io_out_4_bits_exceptionVec_12;
  logic          x_io_out_4_bits_exceptionVec_13;
  logic          x_io_out_4_bits_exceptionVec_14;
  logic          x_io_out_4_bits_exceptionVec_15;
  logic          x_io_out_4_bits_exceptionVec_16;
  logic          x_io_out_4_bits_exceptionVec_17;
  logic          x_io_out_4_bits_exceptionVec_18;
  logic          x_io_out_4_bits_exceptionVec_19;
  logic          x_io_out_4_bits_exceptionVec_20;
  logic          x_io_out_4_bits_exceptionVec_21;
  logic          x_io_out_4_bits_exceptionVec_22;
  logic          x_io_out_4_bits_exceptionVec_23;
  logic          x_io_out_4_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_4_bits_trigger;
  logic          x_io_out_4_bits_preDecodeInfo_valid;
  logic          x_io_out_4_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_4_bits_preDecodeInfo_brType;
  logic          x_io_out_4_bits_preDecodeInfo_isCall;
  logic          x_io_out_4_bits_preDecodeInfo_isRet;
  logic          x_io_out_4_bits_pred_taken;
  logic          x_io_out_4_bits_crossPageIPFFix;
  logic          x_io_out_4_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_4_bits_ftqPtr_value;
  logic [3:0]    x_io_out_4_bits_ftqOffset;
  logic          x_io_out_4_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_4_bits_srcType_0;
  logic [3:0]    x_io_out_4_bits_srcType_1;
  logic [3:0]    x_io_out_4_bits_srcType_2;
  logic [3:0]    x_io_out_4_bits_srcType_3;
  logic [3:0]    x_io_out_4_bits_srcType_4;
  logic [5:0]    x_io_out_4_bits_lsrc_0;
  logic [5:0]    x_io_out_4_bits_lsrc_1;
  logic [5:0]    x_io_out_4_bits_lsrc_2;
  logic [5:0]    x_io_out_4_bits_ldest;
  logic [34:0]   x_io_out_4_bits_fuType;
  logic [8:0]    x_io_out_4_bits_fuOpType;
  logic          x_io_out_4_bits_rfWen;
  logic          x_io_out_4_bits_fpWen;
  logic          x_io_out_4_bits_vecWen;
  logic          x_io_out_4_bits_v0Wen;
  logic          x_io_out_4_bits_vlWen;
  logic          x_io_out_4_bits_isXSTrap;
  logic          x_io_out_4_bits_waitForward;
  logic          x_io_out_4_bits_blockBackward;
  logic          x_io_out_4_bits_flushPipe;
  logic          x_io_out_4_bits_canRobCompress;
  logic [3:0]    x_io_out_4_bits_selImm;
  logic [21:0]   x_io_out_4_bits_imm;
  logic [1:0]    x_io_out_4_bits_fpu_typeTagOut;
  logic          x_io_out_4_bits_fpu_wflags;
  logic [1:0]    x_io_out_4_bits_fpu_typ;
  logic [1:0]    x_io_out_4_bits_fpu_fmt;
  logic [2:0]    x_io_out_4_bits_fpu_rm;
  logic          x_io_out_4_bits_vpu_vill;
  logic          x_io_out_4_bits_vpu_vma;
  logic          x_io_out_4_bits_vpu_vta;
  logic [1:0]    x_io_out_4_bits_vpu_vsew;
  logic [2:0]    x_io_out_4_bits_vpu_vlmul;
  logic          x_io_out_4_bits_vpu_specVill;
  logic          x_io_out_4_bits_vpu_specVma;
  logic          x_io_out_4_bits_vpu_specVta;
  logic [1:0]    x_io_out_4_bits_vpu_specVsew;
  logic [2:0]    x_io_out_4_bits_vpu_specVlmul;
  logic          x_io_out_4_bits_vpu_vm;
  logic [7:0]    x_io_out_4_bits_vpu_vstart;
  logic          x_io_out_4_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_4_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_4_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_4_bits_vpu_nf;
  logic [1:0]    x_io_out_4_bits_vpu_veew;
  logic          x_io_out_4_bits_vpu_isReverse;
  logic          x_io_out_4_bits_vpu_isExt;
  logic          x_io_out_4_bits_vpu_isNarrow;
  logic          x_io_out_4_bits_vpu_isDstMask;
  logic          x_io_out_4_bits_vpu_isOpMask;
  logic          x_io_out_4_bits_vpu_isDependOldVd;
  logic          x_io_out_4_bits_vpu_isWritePartVd;
  logic          x_io_out_4_bits_vpu_isVleff;
  logic          x_io_out_4_bits_vlsInstr;
  logic          x_io_out_4_bits_wfflags;
  logic          x_io_out_4_bits_isMove;
  logic [6:0]    x_io_out_4_bits_uopIdx;
  logic [5:0]    x_io_out_4_bits_uopSplitType;
  logic          x_io_out_4_bits_isVset;
  logic          x_io_out_4_bits_firstUop;
  logic          x_io_out_4_bits_lastUop;
  logic [6:0]    x_io_out_4_bits_numUops;
  logic [6:0]    x_io_out_4_bits_numWB;
  logic [2:0]    x_io_out_4_bits_commitType;
  logic [34:0]   x_io_out_4_bits_debug_fuType;
  logic [55:0]   x_io_out_4_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_4_bits_debug_seqNum_uopIdx;
  logic          x_io_out_5_valid;
  logic [31:0]   x_io_out_5_bits_instr;
  logic [49:0]   x_io_out_5_bits_pc;
  logic [9:0]    x_io_out_5_bits_foldpc;
  logic          x_io_out_5_bits_exceptionVec_0;
  logic          x_io_out_5_bits_exceptionVec_1;
  logic          x_io_out_5_bits_exceptionVec_2;
  logic          x_io_out_5_bits_exceptionVec_3;
  logic          x_io_out_5_bits_exceptionVec_4;
  logic          x_io_out_5_bits_exceptionVec_5;
  logic          x_io_out_5_bits_exceptionVec_6;
  logic          x_io_out_5_bits_exceptionVec_7;
  logic          x_io_out_5_bits_exceptionVec_8;
  logic          x_io_out_5_bits_exceptionVec_9;
  logic          x_io_out_5_bits_exceptionVec_10;
  logic          x_io_out_5_bits_exceptionVec_11;
  logic          x_io_out_5_bits_exceptionVec_12;
  logic          x_io_out_5_bits_exceptionVec_13;
  logic          x_io_out_5_bits_exceptionVec_14;
  logic          x_io_out_5_bits_exceptionVec_15;
  logic          x_io_out_5_bits_exceptionVec_16;
  logic          x_io_out_5_bits_exceptionVec_17;
  logic          x_io_out_5_bits_exceptionVec_18;
  logic          x_io_out_5_bits_exceptionVec_19;
  logic          x_io_out_5_bits_exceptionVec_20;
  logic          x_io_out_5_bits_exceptionVec_21;
  logic          x_io_out_5_bits_exceptionVec_22;
  logic          x_io_out_5_bits_exceptionVec_23;
  logic          x_io_out_5_bits_isFetchMalAddr;
  logic [3:0]    x_io_out_5_bits_trigger;
  logic          x_io_out_5_bits_preDecodeInfo_valid;
  logic          x_io_out_5_bits_preDecodeInfo_isRVC;
  logic [1:0]    x_io_out_5_bits_preDecodeInfo_brType;
  logic          x_io_out_5_bits_preDecodeInfo_isCall;
  logic          x_io_out_5_bits_preDecodeInfo_isRet;
  logic          x_io_out_5_bits_pred_taken;
  logic          x_io_out_5_bits_crossPageIPFFix;
  logic          x_io_out_5_bits_ftqPtr_flag;
  logic [5:0]    x_io_out_5_bits_ftqPtr_value;
  logic [3:0]    x_io_out_5_bits_ftqOffset;
  logic          x_io_out_5_bits_satpFlushFirstFetchFault;
  logic [3:0]    x_io_out_5_bits_srcType_0;
  logic [3:0]    x_io_out_5_bits_srcType_1;
  logic [3:0]    x_io_out_5_bits_srcType_2;
  logic [3:0]    x_io_out_5_bits_srcType_3;
  logic [3:0]    x_io_out_5_bits_srcType_4;
  logic [5:0]    x_io_out_5_bits_lsrc_0;
  logic [5:0]    x_io_out_5_bits_lsrc_1;
  logic [5:0]    x_io_out_5_bits_lsrc_2;
  logic [5:0]    x_io_out_5_bits_ldest;
  logic [34:0]   x_io_out_5_bits_fuType;
  logic [8:0]    x_io_out_5_bits_fuOpType;
  logic          x_io_out_5_bits_rfWen;
  logic          x_io_out_5_bits_fpWen;
  logic          x_io_out_5_bits_vecWen;
  logic          x_io_out_5_bits_v0Wen;
  logic          x_io_out_5_bits_vlWen;
  logic          x_io_out_5_bits_isXSTrap;
  logic          x_io_out_5_bits_waitForward;
  logic          x_io_out_5_bits_blockBackward;
  logic          x_io_out_5_bits_flushPipe;
  logic          x_io_out_5_bits_canRobCompress;
  logic [3:0]    x_io_out_5_bits_selImm;
  logic [21:0]   x_io_out_5_bits_imm;
  logic [1:0]    x_io_out_5_bits_fpu_typeTagOut;
  logic          x_io_out_5_bits_fpu_wflags;
  logic [1:0]    x_io_out_5_bits_fpu_typ;
  logic [1:0]    x_io_out_5_bits_fpu_fmt;
  logic [2:0]    x_io_out_5_bits_fpu_rm;
  logic          x_io_out_5_bits_vpu_vill;
  logic          x_io_out_5_bits_vpu_vma;
  logic          x_io_out_5_bits_vpu_vta;
  logic [1:0]    x_io_out_5_bits_vpu_vsew;
  logic [2:0]    x_io_out_5_bits_vpu_vlmul;
  logic          x_io_out_5_bits_vpu_specVill;
  logic          x_io_out_5_bits_vpu_specVma;
  logic          x_io_out_5_bits_vpu_specVta;
  logic [1:0]    x_io_out_5_bits_vpu_specVsew;
  logic [2:0]    x_io_out_5_bits_vpu_specVlmul;
  logic          x_io_out_5_bits_vpu_vm;
  logic [7:0]    x_io_out_5_bits_vpu_vstart;
  logic          x_io_out_5_bits_vpu_fpu_isFoldTo1_2;
  logic          x_io_out_5_bits_vpu_fpu_isFoldTo1_4;
  logic          x_io_out_5_bits_vpu_fpu_isFoldTo1_8;
  logic [2:0]    x_io_out_5_bits_vpu_nf;
  logic [1:0]    x_io_out_5_bits_vpu_veew;
  logic          x_io_out_5_bits_vpu_isReverse;
  logic          x_io_out_5_bits_vpu_isExt;
  logic          x_io_out_5_bits_vpu_isNarrow;
  logic          x_io_out_5_bits_vpu_isDstMask;
  logic          x_io_out_5_bits_vpu_isOpMask;
  logic          x_io_out_5_bits_vpu_isDependOldVd;
  logic          x_io_out_5_bits_vpu_isWritePartVd;
  logic          x_io_out_5_bits_vpu_isVleff;
  logic          x_io_out_5_bits_vlsInstr;
  logic          x_io_out_5_bits_wfflags;
  logic          x_io_out_5_bits_isMove;
  logic [6:0]    x_io_out_5_bits_uopIdx;
  logic [5:0]    x_io_out_5_bits_uopSplitType;
  logic          x_io_out_5_bits_isVset;
  logic          x_io_out_5_bits_firstUop;
  logic          x_io_out_5_bits_lastUop;
  logic [6:0]    x_io_out_5_bits_numUops;
  logic [6:0]    x_io_out_5_bits_numWB;
  logic [2:0]    x_io_out_5_bits_commitType;
  logic [34:0]   x_io_out_5_bits_debug_fuType;
  logic [55:0]   x_io_out_5_bits_debug_seqNum_seqNum;
  logic [7:0]    x_io_out_5_bits_debug_seqNum_uopIdx;
  logic          x_io_intRat_0_0_hold;
  logic [31:0]   x_io_intRat_0_0_addr;
  logic          x_io_intRat_0_1_hold;
  logic [31:0]   x_io_intRat_0_1_addr;
  logic          x_io_intRat_1_0_hold;
  logic [31:0]   x_io_intRat_1_0_addr;
  logic          x_io_intRat_1_1_hold;
  logic [31:0]   x_io_intRat_1_1_addr;
  logic          x_io_intRat_2_0_hold;
  logic [31:0]   x_io_intRat_2_0_addr;
  logic          x_io_intRat_2_1_hold;
  logic [31:0]   x_io_intRat_2_1_addr;
  logic          x_io_intRat_3_0_hold;
  logic [31:0]   x_io_intRat_3_0_addr;
  logic          x_io_intRat_3_1_hold;
  logic [31:0]   x_io_intRat_3_1_addr;
  logic          x_io_intRat_4_0_hold;
  logic [31:0]   x_io_intRat_4_0_addr;
  logic          x_io_intRat_4_1_hold;
  logic [31:0]   x_io_intRat_4_1_addr;
  logic          x_io_intRat_5_0_hold;
  logic [31:0]   x_io_intRat_5_0_addr;
  logic          x_io_intRat_5_1_hold;
  logic [31:0]   x_io_intRat_5_1_addr;
  logic          x_io_fpRat_0_0_hold;
  logic [33:0]   x_io_fpRat_0_0_addr;
  logic          x_io_fpRat_0_1_hold;
  logic [33:0]   x_io_fpRat_0_1_addr;
  logic          x_io_fpRat_0_2_hold;
  logic [33:0]   x_io_fpRat_0_2_addr;
  logic          x_io_fpRat_1_0_hold;
  logic [33:0]   x_io_fpRat_1_0_addr;
  logic          x_io_fpRat_1_1_hold;
  logic [33:0]   x_io_fpRat_1_1_addr;
  logic          x_io_fpRat_1_2_hold;
  logic [33:0]   x_io_fpRat_1_2_addr;
  logic          x_io_fpRat_2_0_hold;
  logic [33:0]   x_io_fpRat_2_0_addr;
  logic          x_io_fpRat_2_1_hold;
  logic [33:0]   x_io_fpRat_2_1_addr;
  logic          x_io_fpRat_2_2_hold;
  logic [33:0]   x_io_fpRat_2_2_addr;
  logic          x_io_fpRat_3_0_hold;
  logic [33:0]   x_io_fpRat_3_0_addr;
  logic          x_io_fpRat_3_1_hold;
  logic [33:0]   x_io_fpRat_3_1_addr;
  logic          x_io_fpRat_3_2_hold;
  logic [33:0]   x_io_fpRat_3_2_addr;
  logic          x_io_fpRat_4_0_hold;
  logic [33:0]   x_io_fpRat_4_0_addr;
  logic          x_io_fpRat_4_1_hold;
  logic [33:0]   x_io_fpRat_4_1_addr;
  logic          x_io_fpRat_4_2_hold;
  logic [33:0]   x_io_fpRat_4_2_addr;
  logic          x_io_fpRat_5_0_hold;
  logic [33:0]   x_io_fpRat_5_0_addr;
  logic          x_io_fpRat_5_1_hold;
  logic [33:0]   x_io_fpRat_5_1_addr;
  logic          x_io_fpRat_5_2_hold;
  logic [33:0]   x_io_fpRat_5_2_addr;
  logic          x_io_vecRat_0_0_hold;
  logic [46:0]   x_io_vecRat_0_0_addr;
  logic          x_io_vecRat_0_1_hold;
  logic [46:0]   x_io_vecRat_0_1_addr;
  logic          x_io_vecRat_0_2_hold;
  logic [46:0]   x_io_vecRat_0_2_addr;
  logic          x_io_vecRat_1_0_hold;
  logic [46:0]   x_io_vecRat_1_0_addr;
  logic          x_io_vecRat_1_1_hold;
  logic [46:0]   x_io_vecRat_1_1_addr;
  logic          x_io_vecRat_1_2_hold;
  logic [46:0]   x_io_vecRat_1_2_addr;
  logic          x_io_vecRat_2_0_hold;
  logic [46:0]   x_io_vecRat_2_0_addr;
  logic          x_io_vecRat_2_1_hold;
  logic [46:0]   x_io_vecRat_2_1_addr;
  logic          x_io_vecRat_2_2_hold;
  logic [46:0]   x_io_vecRat_2_2_addr;
  logic          x_io_vecRat_3_0_hold;
  logic [46:0]   x_io_vecRat_3_0_addr;
  logic          x_io_vecRat_3_1_hold;
  logic [46:0]   x_io_vecRat_3_1_addr;
  logic          x_io_vecRat_3_2_hold;
  logic [46:0]   x_io_vecRat_3_2_addr;
  logic          x_io_vecRat_4_0_hold;
  logic [46:0]   x_io_vecRat_4_0_addr;
  logic          x_io_vecRat_4_1_hold;
  logic [46:0]   x_io_vecRat_4_1_addr;
  logic          x_io_vecRat_4_2_hold;
  logic [46:0]   x_io_vecRat_4_2_addr;
  logic          x_io_vecRat_5_0_hold;
  logic [46:0]   x_io_vecRat_5_0_addr;
  logic          x_io_vecRat_5_1_hold;
  logic [46:0]   x_io_vecRat_5_1_addr;
  logic          x_io_vecRat_5_2_hold;
  logic [46:0]   x_io_vecRat_5_2_addr;
  logic          x_io_v0Rat_0_hold;
  logic          x_io_v0Rat_1_hold;
  logic          x_io_v0Rat_2_hold;
  logic          x_io_v0Rat_3_hold;
  logic          x_io_v0Rat_4_hold;
  logic          x_io_v0Rat_5_hold;
  logic          x_io_vlRat_0_hold;
  logic          x_io_vlRat_1_hold;
  logic          x_io_vlRat_2_hold;
  logic          x_io_vlRat_3_hold;
  logic          x_io_vlRat_4_hold;
  logic          x_io_vlRat_5_hold;
  logic          x_io_stallReason_in_backReason_valid;
  logic [5:0]    x_io_stallReason_in_backReason_bits;
  logic [5:0]    x_io_stallReason_out_reason_0;
  logic [5:0]    x_io_stallReason_out_reason_1;
  logic [5:0]    x_io_stallReason_out_reason_2;
  logic [5:0]    x_io_stallReason_out_reason_3;
  logic [5:0]    x_io_stallReason_out_reason_4;
  logic [5:0]    x_io_stallReason_out_reason_5;
  logic          x_io_toCSR_trapInstInfo_valid;
  logic [31:0]   x_io_toCSR_trapInstInfo_bits_instr;
  logic          x_io_toCSR_trapInstInfo_bits_ftqPtr_flag;
  logic [5:0]    x_io_toCSR_trapInstInfo_bits_ftqPtr_value;
  logic [3:0]    x_io_toCSR_trapInstInfo_bits_ftqOffset;
  logic [5:0]    x_io_perf_0_value;
  logic [5:0]    x_io_perf_1_value;
  logic [5:0]    x_io_perf_2_value;
  logic [5:0]    x_io_perf_3_value;
  logic [5:0]    x_io_perf_4_value;
  logic [5:0]    x_io_perf_5_value;
  logic [5:0]    x_io_perf_6_value;
  logic [5:0]    x_io_perf_7_value;

  DecodeStage u_gold (
    .clock(clk), .reset(rst),
    .io_redirect(io_redirect), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_instr(io_in_0_bits_instr), .io_in_0_bits_pc(io_in_0_bits_pc),
    .io_in_0_bits_foldpc(io_in_0_bits_foldpc), .io_in_0_bits_exceptionVec_0(io_in_0_bits_exceptionVec_0), .io_in_0_bits_exceptionVec_1(io_in_0_bits_exceptionVec_1), .io_in_0_bits_exceptionVec_2(io_in_0_bits_exceptionVec_2),
    .io_in_0_bits_exceptionVec_4(io_in_0_bits_exceptionVec_4), .io_in_0_bits_exceptionVec_5(io_in_0_bits_exceptionVec_5), .io_in_0_bits_exceptionVec_6(io_in_0_bits_exceptionVec_6), .io_in_0_bits_exceptionVec_7(io_in_0_bits_exceptionVec_7),
    .io_in_0_bits_exceptionVec_8(io_in_0_bits_exceptionVec_8), .io_in_0_bits_exceptionVec_9(io_in_0_bits_exceptionVec_9), .io_in_0_bits_exceptionVec_10(io_in_0_bits_exceptionVec_10), .io_in_0_bits_exceptionVec_11(io_in_0_bits_exceptionVec_11),
    .io_in_0_bits_exceptionVec_12(io_in_0_bits_exceptionVec_12), .io_in_0_bits_exceptionVec_13(io_in_0_bits_exceptionVec_13), .io_in_0_bits_exceptionVec_14(io_in_0_bits_exceptionVec_14), .io_in_0_bits_exceptionVec_15(io_in_0_bits_exceptionVec_15),
    .io_in_0_bits_exceptionVec_16(io_in_0_bits_exceptionVec_16), .io_in_0_bits_exceptionVec_17(io_in_0_bits_exceptionVec_17), .io_in_0_bits_exceptionVec_18(io_in_0_bits_exceptionVec_18), .io_in_0_bits_exceptionVec_19(io_in_0_bits_exceptionVec_19),
    .io_in_0_bits_exceptionVec_20(io_in_0_bits_exceptionVec_20), .io_in_0_bits_exceptionVec_21(io_in_0_bits_exceptionVec_21), .io_in_0_bits_exceptionVec_23(io_in_0_bits_exceptionVec_23), .io_in_0_bits_isFetchMalAddr(io_in_0_bits_isFetchMalAddr),
    .io_in_0_bits_trigger(io_in_0_bits_trigger), .io_in_0_bits_preDecodeInfo_valid(io_in_0_bits_preDecodeInfo_valid), .io_in_0_bits_preDecodeInfo_isRVC(io_in_0_bits_preDecodeInfo_isRVC), .io_in_0_bits_preDecodeInfo_brType(io_in_0_bits_preDecodeInfo_brType),
    .io_in_0_bits_preDecodeInfo_isCall(io_in_0_bits_preDecodeInfo_isCall), .io_in_0_bits_preDecodeInfo_isRet(io_in_0_bits_preDecodeInfo_isRet), .io_in_0_bits_pred_taken(io_in_0_bits_pred_taken), .io_in_0_bits_crossPageIPFFix(io_in_0_bits_crossPageIPFFix),
    .io_in_0_bits_ftqPtr_flag(io_in_0_bits_ftqPtr_flag), .io_in_0_bits_ftqPtr_value(io_in_0_bits_ftqPtr_value), .io_in_0_bits_ftqOffset(io_in_0_bits_ftqOffset), .io_in_0_bits_isLastInFtqEntry(io_in_0_bits_isLastInFtqEntry),
    .io_in_0_bits_debug_seqNum_seqNum(io_in_0_bits_debug_seqNum_seqNum), .io_in_0_bits_debug_seqNum_uopIdx(io_in_0_bits_debug_seqNum_uopIdx), .io_in_0_bits_satpFlushFirstFetchFault(io_in_0_bits_satpFlushFirstFetchFault), .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_instr(io_in_1_bits_instr), .io_in_1_bits_pc(io_in_1_bits_pc), .io_in_1_bits_foldpc(io_in_1_bits_foldpc), .io_in_1_bits_exceptionVec_0(io_in_1_bits_exceptionVec_0),
    .io_in_1_bits_exceptionVec_1(io_in_1_bits_exceptionVec_1), .io_in_1_bits_exceptionVec_2(io_in_1_bits_exceptionVec_2), .io_in_1_bits_exceptionVec_4(io_in_1_bits_exceptionVec_4), .io_in_1_bits_exceptionVec_5(io_in_1_bits_exceptionVec_5),
    .io_in_1_bits_exceptionVec_6(io_in_1_bits_exceptionVec_6), .io_in_1_bits_exceptionVec_7(io_in_1_bits_exceptionVec_7), .io_in_1_bits_exceptionVec_8(io_in_1_bits_exceptionVec_8), .io_in_1_bits_exceptionVec_9(io_in_1_bits_exceptionVec_9),
    .io_in_1_bits_exceptionVec_10(io_in_1_bits_exceptionVec_10), .io_in_1_bits_exceptionVec_11(io_in_1_bits_exceptionVec_11), .io_in_1_bits_exceptionVec_12(io_in_1_bits_exceptionVec_12), .io_in_1_bits_exceptionVec_13(io_in_1_bits_exceptionVec_13),
    .io_in_1_bits_exceptionVec_14(io_in_1_bits_exceptionVec_14), .io_in_1_bits_exceptionVec_15(io_in_1_bits_exceptionVec_15), .io_in_1_bits_exceptionVec_16(io_in_1_bits_exceptionVec_16), .io_in_1_bits_exceptionVec_17(io_in_1_bits_exceptionVec_17),
    .io_in_1_bits_exceptionVec_18(io_in_1_bits_exceptionVec_18), .io_in_1_bits_exceptionVec_19(io_in_1_bits_exceptionVec_19), .io_in_1_bits_exceptionVec_20(io_in_1_bits_exceptionVec_20), .io_in_1_bits_exceptionVec_21(io_in_1_bits_exceptionVec_21),
    .io_in_1_bits_exceptionVec_23(io_in_1_bits_exceptionVec_23), .io_in_1_bits_isFetchMalAddr(io_in_1_bits_isFetchMalAddr), .io_in_1_bits_trigger(io_in_1_bits_trigger), .io_in_1_bits_preDecodeInfo_valid(io_in_1_bits_preDecodeInfo_valid),
    .io_in_1_bits_preDecodeInfo_isRVC(io_in_1_bits_preDecodeInfo_isRVC), .io_in_1_bits_preDecodeInfo_brType(io_in_1_bits_preDecodeInfo_brType), .io_in_1_bits_preDecodeInfo_isCall(io_in_1_bits_preDecodeInfo_isCall), .io_in_1_bits_preDecodeInfo_isRet(io_in_1_bits_preDecodeInfo_isRet),
    .io_in_1_bits_pred_taken(io_in_1_bits_pred_taken), .io_in_1_bits_crossPageIPFFix(io_in_1_bits_crossPageIPFFix), .io_in_1_bits_ftqPtr_flag(io_in_1_bits_ftqPtr_flag), .io_in_1_bits_ftqPtr_value(io_in_1_bits_ftqPtr_value),
    .io_in_1_bits_ftqOffset(io_in_1_bits_ftqOffset), .io_in_1_bits_isLastInFtqEntry(io_in_1_bits_isLastInFtqEntry), .io_in_1_bits_debug_seqNum_seqNum(io_in_1_bits_debug_seqNum_seqNum), .io_in_1_bits_debug_seqNum_uopIdx(io_in_1_bits_debug_seqNum_uopIdx),
    .io_in_1_bits_satpFlushFirstFetchFault(io_in_1_bits_satpFlushFirstFetchFault), .io_in_2_valid(io_in_2_valid), .io_in_2_bits_instr(io_in_2_bits_instr), .io_in_2_bits_pc(io_in_2_bits_pc),
    .io_in_2_bits_foldpc(io_in_2_bits_foldpc), .io_in_2_bits_exceptionVec_0(io_in_2_bits_exceptionVec_0), .io_in_2_bits_exceptionVec_1(io_in_2_bits_exceptionVec_1), .io_in_2_bits_exceptionVec_2(io_in_2_bits_exceptionVec_2),
    .io_in_2_bits_exceptionVec_4(io_in_2_bits_exceptionVec_4), .io_in_2_bits_exceptionVec_5(io_in_2_bits_exceptionVec_5), .io_in_2_bits_exceptionVec_6(io_in_2_bits_exceptionVec_6), .io_in_2_bits_exceptionVec_7(io_in_2_bits_exceptionVec_7),
    .io_in_2_bits_exceptionVec_8(io_in_2_bits_exceptionVec_8), .io_in_2_bits_exceptionVec_9(io_in_2_bits_exceptionVec_9), .io_in_2_bits_exceptionVec_10(io_in_2_bits_exceptionVec_10), .io_in_2_bits_exceptionVec_11(io_in_2_bits_exceptionVec_11),
    .io_in_2_bits_exceptionVec_12(io_in_2_bits_exceptionVec_12), .io_in_2_bits_exceptionVec_13(io_in_2_bits_exceptionVec_13), .io_in_2_bits_exceptionVec_14(io_in_2_bits_exceptionVec_14), .io_in_2_bits_exceptionVec_15(io_in_2_bits_exceptionVec_15),
    .io_in_2_bits_exceptionVec_16(io_in_2_bits_exceptionVec_16), .io_in_2_bits_exceptionVec_17(io_in_2_bits_exceptionVec_17), .io_in_2_bits_exceptionVec_18(io_in_2_bits_exceptionVec_18), .io_in_2_bits_exceptionVec_19(io_in_2_bits_exceptionVec_19),
    .io_in_2_bits_exceptionVec_20(io_in_2_bits_exceptionVec_20), .io_in_2_bits_exceptionVec_21(io_in_2_bits_exceptionVec_21), .io_in_2_bits_exceptionVec_23(io_in_2_bits_exceptionVec_23), .io_in_2_bits_isFetchMalAddr(io_in_2_bits_isFetchMalAddr),
    .io_in_2_bits_trigger(io_in_2_bits_trigger), .io_in_2_bits_preDecodeInfo_valid(io_in_2_bits_preDecodeInfo_valid), .io_in_2_bits_preDecodeInfo_isRVC(io_in_2_bits_preDecodeInfo_isRVC), .io_in_2_bits_preDecodeInfo_brType(io_in_2_bits_preDecodeInfo_brType),
    .io_in_2_bits_preDecodeInfo_isCall(io_in_2_bits_preDecodeInfo_isCall), .io_in_2_bits_preDecodeInfo_isRet(io_in_2_bits_preDecodeInfo_isRet), .io_in_2_bits_pred_taken(io_in_2_bits_pred_taken), .io_in_2_bits_crossPageIPFFix(io_in_2_bits_crossPageIPFFix),
    .io_in_2_bits_ftqPtr_flag(io_in_2_bits_ftqPtr_flag), .io_in_2_bits_ftqPtr_value(io_in_2_bits_ftqPtr_value), .io_in_2_bits_ftqOffset(io_in_2_bits_ftqOffset), .io_in_2_bits_isLastInFtqEntry(io_in_2_bits_isLastInFtqEntry),
    .io_in_2_bits_debug_seqNum_seqNum(io_in_2_bits_debug_seqNum_seqNum), .io_in_2_bits_debug_seqNum_uopIdx(io_in_2_bits_debug_seqNum_uopIdx), .io_in_2_bits_satpFlushFirstFetchFault(io_in_2_bits_satpFlushFirstFetchFault), .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_instr(io_in_3_bits_instr), .io_in_3_bits_pc(io_in_3_bits_pc), .io_in_3_bits_foldpc(io_in_3_bits_foldpc), .io_in_3_bits_exceptionVec_0(io_in_3_bits_exceptionVec_0),
    .io_in_3_bits_exceptionVec_1(io_in_3_bits_exceptionVec_1), .io_in_3_bits_exceptionVec_2(io_in_3_bits_exceptionVec_2), .io_in_3_bits_exceptionVec_4(io_in_3_bits_exceptionVec_4), .io_in_3_bits_exceptionVec_5(io_in_3_bits_exceptionVec_5),
    .io_in_3_bits_exceptionVec_6(io_in_3_bits_exceptionVec_6), .io_in_3_bits_exceptionVec_7(io_in_3_bits_exceptionVec_7), .io_in_3_bits_exceptionVec_8(io_in_3_bits_exceptionVec_8), .io_in_3_bits_exceptionVec_9(io_in_3_bits_exceptionVec_9),
    .io_in_3_bits_exceptionVec_10(io_in_3_bits_exceptionVec_10), .io_in_3_bits_exceptionVec_11(io_in_3_bits_exceptionVec_11), .io_in_3_bits_exceptionVec_12(io_in_3_bits_exceptionVec_12), .io_in_3_bits_exceptionVec_13(io_in_3_bits_exceptionVec_13),
    .io_in_3_bits_exceptionVec_14(io_in_3_bits_exceptionVec_14), .io_in_3_bits_exceptionVec_15(io_in_3_bits_exceptionVec_15), .io_in_3_bits_exceptionVec_16(io_in_3_bits_exceptionVec_16), .io_in_3_bits_exceptionVec_17(io_in_3_bits_exceptionVec_17),
    .io_in_3_bits_exceptionVec_18(io_in_3_bits_exceptionVec_18), .io_in_3_bits_exceptionVec_19(io_in_3_bits_exceptionVec_19), .io_in_3_bits_exceptionVec_20(io_in_3_bits_exceptionVec_20), .io_in_3_bits_exceptionVec_21(io_in_3_bits_exceptionVec_21),
    .io_in_3_bits_exceptionVec_23(io_in_3_bits_exceptionVec_23), .io_in_3_bits_isFetchMalAddr(io_in_3_bits_isFetchMalAddr), .io_in_3_bits_trigger(io_in_3_bits_trigger), .io_in_3_bits_preDecodeInfo_valid(io_in_3_bits_preDecodeInfo_valid),
    .io_in_3_bits_preDecodeInfo_isRVC(io_in_3_bits_preDecodeInfo_isRVC), .io_in_3_bits_preDecodeInfo_brType(io_in_3_bits_preDecodeInfo_brType), .io_in_3_bits_preDecodeInfo_isCall(io_in_3_bits_preDecodeInfo_isCall), .io_in_3_bits_preDecodeInfo_isRet(io_in_3_bits_preDecodeInfo_isRet),
    .io_in_3_bits_pred_taken(io_in_3_bits_pred_taken), .io_in_3_bits_crossPageIPFFix(io_in_3_bits_crossPageIPFFix), .io_in_3_bits_ftqPtr_flag(io_in_3_bits_ftqPtr_flag), .io_in_3_bits_ftqPtr_value(io_in_3_bits_ftqPtr_value),
    .io_in_3_bits_ftqOffset(io_in_3_bits_ftqOffset), .io_in_3_bits_isLastInFtqEntry(io_in_3_bits_isLastInFtqEntry), .io_in_3_bits_debug_seqNum_seqNum(io_in_3_bits_debug_seqNum_seqNum), .io_in_3_bits_debug_seqNum_uopIdx(io_in_3_bits_debug_seqNum_uopIdx),
    .io_in_3_bits_satpFlushFirstFetchFault(io_in_3_bits_satpFlushFirstFetchFault), .io_in_4_valid(io_in_4_valid), .io_in_4_bits_instr(io_in_4_bits_instr), .io_in_4_bits_pc(io_in_4_bits_pc),
    .io_in_4_bits_foldpc(io_in_4_bits_foldpc), .io_in_4_bits_exceptionVec_0(io_in_4_bits_exceptionVec_0), .io_in_4_bits_exceptionVec_1(io_in_4_bits_exceptionVec_1), .io_in_4_bits_exceptionVec_2(io_in_4_bits_exceptionVec_2),
    .io_in_4_bits_exceptionVec_4(io_in_4_bits_exceptionVec_4), .io_in_4_bits_exceptionVec_5(io_in_4_bits_exceptionVec_5), .io_in_4_bits_exceptionVec_6(io_in_4_bits_exceptionVec_6), .io_in_4_bits_exceptionVec_7(io_in_4_bits_exceptionVec_7),
    .io_in_4_bits_exceptionVec_8(io_in_4_bits_exceptionVec_8), .io_in_4_bits_exceptionVec_9(io_in_4_bits_exceptionVec_9), .io_in_4_bits_exceptionVec_10(io_in_4_bits_exceptionVec_10), .io_in_4_bits_exceptionVec_11(io_in_4_bits_exceptionVec_11),
    .io_in_4_bits_exceptionVec_12(io_in_4_bits_exceptionVec_12), .io_in_4_bits_exceptionVec_13(io_in_4_bits_exceptionVec_13), .io_in_4_bits_exceptionVec_14(io_in_4_bits_exceptionVec_14), .io_in_4_bits_exceptionVec_15(io_in_4_bits_exceptionVec_15),
    .io_in_4_bits_exceptionVec_16(io_in_4_bits_exceptionVec_16), .io_in_4_bits_exceptionVec_17(io_in_4_bits_exceptionVec_17), .io_in_4_bits_exceptionVec_18(io_in_4_bits_exceptionVec_18), .io_in_4_bits_exceptionVec_19(io_in_4_bits_exceptionVec_19),
    .io_in_4_bits_exceptionVec_20(io_in_4_bits_exceptionVec_20), .io_in_4_bits_exceptionVec_21(io_in_4_bits_exceptionVec_21), .io_in_4_bits_exceptionVec_23(io_in_4_bits_exceptionVec_23), .io_in_4_bits_isFetchMalAddr(io_in_4_bits_isFetchMalAddr),
    .io_in_4_bits_trigger(io_in_4_bits_trigger), .io_in_4_bits_preDecodeInfo_valid(io_in_4_bits_preDecodeInfo_valid), .io_in_4_bits_preDecodeInfo_isRVC(io_in_4_bits_preDecodeInfo_isRVC), .io_in_4_bits_preDecodeInfo_brType(io_in_4_bits_preDecodeInfo_brType),
    .io_in_4_bits_preDecodeInfo_isCall(io_in_4_bits_preDecodeInfo_isCall), .io_in_4_bits_preDecodeInfo_isRet(io_in_4_bits_preDecodeInfo_isRet), .io_in_4_bits_pred_taken(io_in_4_bits_pred_taken), .io_in_4_bits_crossPageIPFFix(io_in_4_bits_crossPageIPFFix),
    .io_in_4_bits_ftqPtr_flag(io_in_4_bits_ftqPtr_flag), .io_in_4_bits_ftqPtr_value(io_in_4_bits_ftqPtr_value), .io_in_4_bits_ftqOffset(io_in_4_bits_ftqOffset), .io_in_4_bits_isLastInFtqEntry(io_in_4_bits_isLastInFtqEntry),
    .io_in_4_bits_debug_seqNum_seqNum(io_in_4_bits_debug_seqNum_seqNum), .io_in_4_bits_debug_seqNum_uopIdx(io_in_4_bits_debug_seqNum_uopIdx), .io_in_4_bits_satpFlushFirstFetchFault(io_in_4_bits_satpFlushFirstFetchFault), .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_instr(io_in_5_bits_instr), .io_in_5_bits_pc(io_in_5_bits_pc), .io_in_5_bits_foldpc(io_in_5_bits_foldpc), .io_in_5_bits_exceptionVec_0(io_in_5_bits_exceptionVec_0),
    .io_in_5_bits_exceptionVec_1(io_in_5_bits_exceptionVec_1), .io_in_5_bits_exceptionVec_2(io_in_5_bits_exceptionVec_2), .io_in_5_bits_exceptionVec_4(io_in_5_bits_exceptionVec_4), .io_in_5_bits_exceptionVec_5(io_in_5_bits_exceptionVec_5),
    .io_in_5_bits_exceptionVec_6(io_in_5_bits_exceptionVec_6), .io_in_5_bits_exceptionVec_7(io_in_5_bits_exceptionVec_7), .io_in_5_bits_exceptionVec_8(io_in_5_bits_exceptionVec_8), .io_in_5_bits_exceptionVec_9(io_in_5_bits_exceptionVec_9),
    .io_in_5_bits_exceptionVec_10(io_in_5_bits_exceptionVec_10), .io_in_5_bits_exceptionVec_11(io_in_5_bits_exceptionVec_11), .io_in_5_bits_exceptionVec_12(io_in_5_bits_exceptionVec_12), .io_in_5_bits_exceptionVec_13(io_in_5_bits_exceptionVec_13),
    .io_in_5_bits_exceptionVec_14(io_in_5_bits_exceptionVec_14), .io_in_5_bits_exceptionVec_15(io_in_5_bits_exceptionVec_15), .io_in_5_bits_exceptionVec_16(io_in_5_bits_exceptionVec_16), .io_in_5_bits_exceptionVec_17(io_in_5_bits_exceptionVec_17),
    .io_in_5_bits_exceptionVec_18(io_in_5_bits_exceptionVec_18), .io_in_5_bits_exceptionVec_19(io_in_5_bits_exceptionVec_19), .io_in_5_bits_exceptionVec_20(io_in_5_bits_exceptionVec_20), .io_in_5_bits_exceptionVec_21(io_in_5_bits_exceptionVec_21),
    .io_in_5_bits_exceptionVec_23(io_in_5_bits_exceptionVec_23), .io_in_5_bits_isFetchMalAddr(io_in_5_bits_isFetchMalAddr), .io_in_5_bits_trigger(io_in_5_bits_trigger), .io_in_5_bits_preDecodeInfo_valid(io_in_5_bits_preDecodeInfo_valid),
    .io_in_5_bits_preDecodeInfo_isRVC(io_in_5_bits_preDecodeInfo_isRVC), .io_in_5_bits_preDecodeInfo_brType(io_in_5_bits_preDecodeInfo_brType), .io_in_5_bits_preDecodeInfo_isCall(io_in_5_bits_preDecodeInfo_isCall), .io_in_5_bits_preDecodeInfo_isRet(io_in_5_bits_preDecodeInfo_isRet),
    .io_in_5_bits_pred_taken(io_in_5_bits_pred_taken), .io_in_5_bits_crossPageIPFFix(io_in_5_bits_crossPageIPFFix), .io_in_5_bits_ftqPtr_flag(io_in_5_bits_ftqPtr_flag), .io_in_5_bits_ftqPtr_value(io_in_5_bits_ftqPtr_value),
    .io_in_5_bits_ftqOffset(io_in_5_bits_ftqOffset), .io_in_5_bits_isLastInFtqEntry(io_in_5_bits_isLastInFtqEntry), .io_in_5_bits_debug_seqNum_seqNum(io_in_5_bits_debug_seqNum_seqNum), .io_in_5_bits_debug_seqNum_uopIdx(io_in_5_bits_debug_seqNum_uopIdx),
    .io_in_5_bits_satpFlushFirstFetchFault(io_in_5_bits_satpFlushFirstFetchFault), .io_out_0_ready(io_out_0_ready), .io_out_1_ready(io_out_1_ready), .io_out_2_ready(io_out_2_ready),
    .io_out_3_ready(io_out_3_ready), .io_out_4_ready(io_out_4_ready), .io_out_5_ready(io_out_5_ready), .io_csrCtrl_singlestep(io_csrCtrl_singlestep),
    .io_fromCSR_illegalInst_sfenceVMA(io_fromCSR_illegalInst_sfenceVMA), .io_fromCSR_illegalInst_sfencePart(io_fromCSR_illegalInst_sfencePart), .io_fromCSR_illegalInst_hfenceGVMA(io_fromCSR_illegalInst_hfenceGVMA), .io_fromCSR_illegalInst_hfenceVVMA(io_fromCSR_illegalInst_hfenceVVMA),
    .io_fromCSR_illegalInst_hlsv(io_fromCSR_illegalInst_hlsv), .io_fromCSR_illegalInst_fsIsOff(io_fromCSR_illegalInst_fsIsOff), .io_fromCSR_illegalInst_vsIsOff(io_fromCSR_illegalInst_vsIsOff), .io_fromCSR_illegalInst_wfi(io_fromCSR_illegalInst_wfi),
    .io_fromCSR_illegalInst_wrs_nto(io_fromCSR_illegalInst_wrs_nto), .io_fromCSR_illegalInst_frm(io_fromCSR_illegalInst_frm), .io_fromCSR_illegalInst_cboZ(io_fromCSR_illegalInst_cboZ), .io_fromCSR_illegalInst_cboCF(io_fromCSR_illegalInst_cboCF),
    .io_fromCSR_illegalInst_cboI(io_fromCSR_illegalInst_cboI), .io_fromCSR_virtualInst_sfenceVMA(io_fromCSR_virtualInst_sfenceVMA), .io_fromCSR_virtualInst_sfencePart(io_fromCSR_virtualInst_sfencePart), .io_fromCSR_virtualInst_hfence(io_fromCSR_virtualInst_hfence),
    .io_fromCSR_virtualInst_hlsv(io_fromCSR_virtualInst_hlsv), .io_fromCSR_virtualInst_wfi(io_fromCSR_virtualInst_wfi), .io_fromCSR_virtualInst_wrs_nto(io_fromCSR_virtualInst_wrs_nto), .io_fromCSR_virtualInst_cboZ(io_fromCSR_virtualInst_cboZ),
    .io_fromCSR_virtualInst_cboCF(io_fromCSR_virtualInst_cboCF), .io_fromCSR_virtualInst_cboI(io_fromCSR_virtualInst_cboI), .io_fromCSR_special_cboI2F(io_fromCSR_special_cboI2F), .io_fusion_0(io_fusion_0),
    .io_fusion_1(io_fusion_1), .io_fusion_2(io_fusion_2), .io_fusion_3(io_fusion_3), .io_fusion_4(io_fusion_4),
    .io_backendCanAccept(io_backendCanAccept), .io_fromRob_isResumeVType(io_fromRob_isResumeVType), .io_fromRob_walkToArchVType(io_fromRob_walkToArchVType), .io_fromRob_commitVType_vtype_valid(io_fromRob_commitVType_vtype_valid),
    .io_fromRob_commitVType_vtype_bits_illegal(io_fromRob_commitVType_vtype_bits_illegal), .io_fromRob_commitVType_vtype_bits_vma(io_fromRob_commitVType_vtype_bits_vma), .io_fromRob_commitVType_vtype_bits_vta(io_fromRob_commitVType_vtype_bits_vta), .io_fromRob_commitVType_vtype_bits_vsew(io_fromRob_commitVType_vtype_bits_vsew),
    .io_fromRob_commitVType_vtype_bits_vlmul(io_fromRob_commitVType_vtype_bits_vlmul), .io_fromRob_commitVType_hasVsetvl(io_fromRob_commitVType_hasVsetvl), .io_fromRob_walkVType_valid(io_fromRob_walkVType_valid), .io_fromRob_walkVType_bits_illegal(io_fromRob_walkVType_bits_illegal),
    .io_fromRob_walkVType_bits_vma(io_fromRob_walkVType_bits_vma), .io_fromRob_walkVType_bits_vta(io_fromRob_walkVType_bits_vta), .io_fromRob_walkVType_bits_vsew(io_fromRob_walkVType_bits_vsew), .io_fromRob_walkVType_bits_vlmul(io_fromRob_walkVType_bits_vlmul),
    .io_stallReason_in_reason_0(io_stallReason_in_reason_0), .io_stallReason_in_reason_1(io_stallReason_in_reason_1), .io_stallReason_in_reason_2(io_stallReason_in_reason_2), .io_stallReason_in_reason_3(io_stallReason_in_reason_3),
    .io_stallReason_in_reason_4(io_stallReason_in_reason_4), .io_stallReason_in_reason_5(io_stallReason_in_reason_5), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid), .io_stallReason_out_backReason_bits(io_stallReason_out_backReason_bits),
    .io_vsetvlVType_illegal(io_vsetvlVType_illegal), .io_vsetvlVType_vma(io_vsetvlVType_vma), .io_vsetvlVType_vta(io_vsetvlVType_vta), .io_vsetvlVType_vsew(io_vsetvlVType_vsew),
    .io_vsetvlVType_vlmul(io_vsetvlVType_vlmul), .io_vstart(io_vstart), .io_in_0_ready(g_io_in_0_ready), .io_in_1_ready(g_io_in_1_ready),
    .io_in_2_ready(g_io_in_2_ready), .io_in_3_ready(g_io_in_3_ready), .io_in_4_ready(g_io_in_4_ready), .io_in_5_ready(g_io_in_5_ready),
    .io_out_0_valid(g_io_out_0_valid), .io_out_0_bits_instr(g_io_out_0_bits_instr), .io_out_0_bits_pc(g_io_out_0_bits_pc), .io_out_0_bits_foldpc(g_io_out_0_bits_foldpc),
    .io_out_0_bits_exceptionVec_0(g_io_out_0_bits_exceptionVec_0), .io_out_0_bits_exceptionVec_1(g_io_out_0_bits_exceptionVec_1), .io_out_0_bits_exceptionVec_2(g_io_out_0_bits_exceptionVec_2), .io_out_0_bits_exceptionVec_3(g_io_out_0_bits_exceptionVec_3),
    .io_out_0_bits_exceptionVec_4(g_io_out_0_bits_exceptionVec_4), .io_out_0_bits_exceptionVec_5(g_io_out_0_bits_exceptionVec_5), .io_out_0_bits_exceptionVec_6(g_io_out_0_bits_exceptionVec_6), .io_out_0_bits_exceptionVec_7(g_io_out_0_bits_exceptionVec_7),
    .io_out_0_bits_exceptionVec_8(g_io_out_0_bits_exceptionVec_8), .io_out_0_bits_exceptionVec_9(g_io_out_0_bits_exceptionVec_9), .io_out_0_bits_exceptionVec_10(g_io_out_0_bits_exceptionVec_10), .io_out_0_bits_exceptionVec_11(g_io_out_0_bits_exceptionVec_11),
    .io_out_0_bits_exceptionVec_12(g_io_out_0_bits_exceptionVec_12), .io_out_0_bits_exceptionVec_13(g_io_out_0_bits_exceptionVec_13), .io_out_0_bits_exceptionVec_14(g_io_out_0_bits_exceptionVec_14), .io_out_0_bits_exceptionVec_15(g_io_out_0_bits_exceptionVec_15),
    .io_out_0_bits_exceptionVec_16(g_io_out_0_bits_exceptionVec_16), .io_out_0_bits_exceptionVec_17(g_io_out_0_bits_exceptionVec_17), .io_out_0_bits_exceptionVec_18(g_io_out_0_bits_exceptionVec_18), .io_out_0_bits_exceptionVec_19(g_io_out_0_bits_exceptionVec_19),
    .io_out_0_bits_exceptionVec_20(g_io_out_0_bits_exceptionVec_20), .io_out_0_bits_exceptionVec_21(g_io_out_0_bits_exceptionVec_21), .io_out_0_bits_exceptionVec_22(g_io_out_0_bits_exceptionVec_22), .io_out_0_bits_exceptionVec_23(g_io_out_0_bits_exceptionVec_23),
    .io_out_0_bits_isFetchMalAddr(g_io_out_0_bits_isFetchMalAddr), .io_out_0_bits_trigger(g_io_out_0_bits_trigger), .io_out_0_bits_preDecodeInfo_valid(g_io_out_0_bits_preDecodeInfo_valid), .io_out_0_bits_preDecodeInfo_isRVC(g_io_out_0_bits_preDecodeInfo_isRVC),
    .io_out_0_bits_preDecodeInfo_brType(g_io_out_0_bits_preDecodeInfo_brType), .io_out_0_bits_preDecodeInfo_isCall(g_io_out_0_bits_preDecodeInfo_isCall), .io_out_0_bits_preDecodeInfo_isRet(g_io_out_0_bits_preDecodeInfo_isRet), .io_out_0_bits_pred_taken(g_io_out_0_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(g_io_out_0_bits_crossPageIPFFix), .io_out_0_bits_ftqPtr_flag(g_io_out_0_bits_ftqPtr_flag), .io_out_0_bits_ftqPtr_value(g_io_out_0_bits_ftqPtr_value), .io_out_0_bits_ftqOffset(g_io_out_0_bits_ftqOffset),
    .io_out_0_bits_satpFlushFirstFetchFault(g_io_out_0_bits_satpFlushFirstFetchFault), .io_out_0_bits_srcType_0(g_io_out_0_bits_srcType_0), .io_out_0_bits_srcType_1(g_io_out_0_bits_srcType_1), .io_out_0_bits_srcType_2(g_io_out_0_bits_srcType_2),
    .io_out_0_bits_srcType_3(g_io_out_0_bits_srcType_3), .io_out_0_bits_srcType_4(g_io_out_0_bits_srcType_4), .io_out_0_bits_lsrc_0(g_io_out_0_bits_lsrc_0), .io_out_0_bits_lsrc_1(g_io_out_0_bits_lsrc_1),
    .io_out_0_bits_lsrc_2(g_io_out_0_bits_lsrc_2), .io_out_0_bits_ldest(g_io_out_0_bits_ldest), .io_out_0_bits_fuType(g_io_out_0_bits_fuType), .io_out_0_bits_fuOpType(g_io_out_0_bits_fuOpType),
    .io_out_0_bits_rfWen(g_io_out_0_bits_rfWen), .io_out_0_bits_fpWen(g_io_out_0_bits_fpWen), .io_out_0_bits_vecWen(g_io_out_0_bits_vecWen), .io_out_0_bits_v0Wen(g_io_out_0_bits_v0Wen),
    .io_out_0_bits_vlWen(g_io_out_0_bits_vlWen), .io_out_0_bits_isXSTrap(g_io_out_0_bits_isXSTrap), .io_out_0_bits_waitForward(g_io_out_0_bits_waitForward), .io_out_0_bits_blockBackward(g_io_out_0_bits_blockBackward),
    .io_out_0_bits_flushPipe(g_io_out_0_bits_flushPipe), .io_out_0_bits_canRobCompress(g_io_out_0_bits_canRobCompress), .io_out_0_bits_selImm(g_io_out_0_bits_selImm), .io_out_0_bits_imm(g_io_out_0_bits_imm),
    .io_out_0_bits_fpu_typeTagOut(g_io_out_0_bits_fpu_typeTagOut), .io_out_0_bits_fpu_wflags(g_io_out_0_bits_fpu_wflags), .io_out_0_bits_fpu_typ(g_io_out_0_bits_fpu_typ), .io_out_0_bits_fpu_fmt(g_io_out_0_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm(g_io_out_0_bits_fpu_rm), .io_out_0_bits_vpu_vill(g_io_out_0_bits_vpu_vill), .io_out_0_bits_vpu_vma(g_io_out_0_bits_vpu_vma), .io_out_0_bits_vpu_vta(g_io_out_0_bits_vpu_vta),
    .io_out_0_bits_vpu_vsew(g_io_out_0_bits_vpu_vsew), .io_out_0_bits_vpu_vlmul(g_io_out_0_bits_vpu_vlmul), .io_out_0_bits_vpu_specVill(g_io_out_0_bits_vpu_specVill), .io_out_0_bits_vpu_specVma(g_io_out_0_bits_vpu_specVma),
    .io_out_0_bits_vpu_specVta(g_io_out_0_bits_vpu_specVta), .io_out_0_bits_vpu_specVsew(g_io_out_0_bits_vpu_specVsew), .io_out_0_bits_vpu_specVlmul(g_io_out_0_bits_vpu_specVlmul), .io_out_0_bits_vpu_vm(g_io_out_0_bits_vpu_vm),
    .io_out_0_bits_vpu_vstart(g_io_out_0_bits_vpu_vstart), .io_out_0_bits_vpu_fpu_isFoldTo1_2(g_io_out_0_bits_vpu_fpu_isFoldTo1_2), .io_out_0_bits_vpu_fpu_isFoldTo1_4(g_io_out_0_bits_vpu_fpu_isFoldTo1_4), .io_out_0_bits_vpu_fpu_isFoldTo1_8(g_io_out_0_bits_vpu_fpu_isFoldTo1_8),
    .io_out_0_bits_vpu_nf(g_io_out_0_bits_vpu_nf), .io_out_0_bits_vpu_veew(g_io_out_0_bits_vpu_veew), .io_out_0_bits_vpu_isReverse(g_io_out_0_bits_vpu_isReverse), .io_out_0_bits_vpu_isExt(g_io_out_0_bits_vpu_isExt),
    .io_out_0_bits_vpu_isNarrow(g_io_out_0_bits_vpu_isNarrow), .io_out_0_bits_vpu_isDstMask(g_io_out_0_bits_vpu_isDstMask), .io_out_0_bits_vpu_isOpMask(g_io_out_0_bits_vpu_isOpMask), .io_out_0_bits_vpu_isDependOldVd(g_io_out_0_bits_vpu_isDependOldVd),
    .io_out_0_bits_vpu_isWritePartVd(g_io_out_0_bits_vpu_isWritePartVd), .io_out_0_bits_vpu_isVleff(g_io_out_0_bits_vpu_isVleff), .io_out_0_bits_vlsInstr(g_io_out_0_bits_vlsInstr), .io_out_0_bits_wfflags(g_io_out_0_bits_wfflags),
    .io_out_0_bits_isMove(g_io_out_0_bits_isMove), .io_out_0_bits_uopIdx(g_io_out_0_bits_uopIdx), .io_out_0_bits_uopSplitType(g_io_out_0_bits_uopSplitType), .io_out_0_bits_isVset(g_io_out_0_bits_isVset),
    .io_out_0_bits_firstUop(g_io_out_0_bits_firstUop), .io_out_0_bits_lastUop(g_io_out_0_bits_lastUop), .io_out_0_bits_numUops(g_io_out_0_bits_numUops), .io_out_0_bits_numWB(g_io_out_0_bits_numWB),
    .io_out_0_bits_commitType(g_io_out_0_bits_commitType), .io_out_0_bits_debug_fuType(g_io_out_0_bits_debug_fuType), .io_out_0_bits_debug_seqNum_seqNum(g_io_out_0_bits_debug_seqNum_seqNum), .io_out_0_bits_debug_seqNum_uopIdx(g_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_valid(g_io_out_1_valid), .io_out_1_bits_instr(g_io_out_1_bits_instr), .io_out_1_bits_pc(g_io_out_1_bits_pc), .io_out_1_bits_foldpc(g_io_out_1_bits_foldpc),
    .io_out_1_bits_exceptionVec_0(g_io_out_1_bits_exceptionVec_0), .io_out_1_bits_exceptionVec_1(g_io_out_1_bits_exceptionVec_1), .io_out_1_bits_exceptionVec_2(g_io_out_1_bits_exceptionVec_2), .io_out_1_bits_exceptionVec_3(g_io_out_1_bits_exceptionVec_3),
    .io_out_1_bits_exceptionVec_4(g_io_out_1_bits_exceptionVec_4), .io_out_1_bits_exceptionVec_5(g_io_out_1_bits_exceptionVec_5), .io_out_1_bits_exceptionVec_6(g_io_out_1_bits_exceptionVec_6), .io_out_1_bits_exceptionVec_7(g_io_out_1_bits_exceptionVec_7),
    .io_out_1_bits_exceptionVec_8(g_io_out_1_bits_exceptionVec_8), .io_out_1_bits_exceptionVec_9(g_io_out_1_bits_exceptionVec_9), .io_out_1_bits_exceptionVec_10(g_io_out_1_bits_exceptionVec_10), .io_out_1_bits_exceptionVec_11(g_io_out_1_bits_exceptionVec_11),
    .io_out_1_bits_exceptionVec_12(g_io_out_1_bits_exceptionVec_12), .io_out_1_bits_exceptionVec_13(g_io_out_1_bits_exceptionVec_13), .io_out_1_bits_exceptionVec_14(g_io_out_1_bits_exceptionVec_14), .io_out_1_bits_exceptionVec_15(g_io_out_1_bits_exceptionVec_15),
    .io_out_1_bits_exceptionVec_16(g_io_out_1_bits_exceptionVec_16), .io_out_1_bits_exceptionVec_17(g_io_out_1_bits_exceptionVec_17), .io_out_1_bits_exceptionVec_18(g_io_out_1_bits_exceptionVec_18), .io_out_1_bits_exceptionVec_19(g_io_out_1_bits_exceptionVec_19),
    .io_out_1_bits_exceptionVec_20(g_io_out_1_bits_exceptionVec_20), .io_out_1_bits_exceptionVec_21(g_io_out_1_bits_exceptionVec_21), .io_out_1_bits_exceptionVec_22(g_io_out_1_bits_exceptionVec_22), .io_out_1_bits_exceptionVec_23(g_io_out_1_bits_exceptionVec_23),
    .io_out_1_bits_isFetchMalAddr(g_io_out_1_bits_isFetchMalAddr), .io_out_1_bits_trigger(g_io_out_1_bits_trigger), .io_out_1_bits_preDecodeInfo_valid(g_io_out_1_bits_preDecodeInfo_valid), .io_out_1_bits_preDecodeInfo_isRVC(g_io_out_1_bits_preDecodeInfo_isRVC),
    .io_out_1_bits_preDecodeInfo_brType(g_io_out_1_bits_preDecodeInfo_brType), .io_out_1_bits_preDecodeInfo_isCall(g_io_out_1_bits_preDecodeInfo_isCall), .io_out_1_bits_preDecodeInfo_isRet(g_io_out_1_bits_preDecodeInfo_isRet), .io_out_1_bits_pred_taken(g_io_out_1_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(g_io_out_1_bits_crossPageIPFFix), .io_out_1_bits_ftqPtr_flag(g_io_out_1_bits_ftqPtr_flag), .io_out_1_bits_ftqPtr_value(g_io_out_1_bits_ftqPtr_value), .io_out_1_bits_ftqOffset(g_io_out_1_bits_ftqOffset),
    .io_out_1_bits_satpFlushFirstFetchFault(g_io_out_1_bits_satpFlushFirstFetchFault), .io_out_1_bits_srcType_0(g_io_out_1_bits_srcType_0), .io_out_1_bits_srcType_1(g_io_out_1_bits_srcType_1), .io_out_1_bits_srcType_2(g_io_out_1_bits_srcType_2),
    .io_out_1_bits_srcType_3(g_io_out_1_bits_srcType_3), .io_out_1_bits_srcType_4(g_io_out_1_bits_srcType_4), .io_out_1_bits_lsrc_0(g_io_out_1_bits_lsrc_0), .io_out_1_bits_lsrc_1(g_io_out_1_bits_lsrc_1),
    .io_out_1_bits_lsrc_2(g_io_out_1_bits_lsrc_2), .io_out_1_bits_ldest(g_io_out_1_bits_ldest), .io_out_1_bits_fuType(g_io_out_1_bits_fuType), .io_out_1_bits_fuOpType(g_io_out_1_bits_fuOpType),
    .io_out_1_bits_rfWen(g_io_out_1_bits_rfWen), .io_out_1_bits_fpWen(g_io_out_1_bits_fpWen), .io_out_1_bits_vecWen(g_io_out_1_bits_vecWen), .io_out_1_bits_v0Wen(g_io_out_1_bits_v0Wen),
    .io_out_1_bits_vlWen(g_io_out_1_bits_vlWen), .io_out_1_bits_isXSTrap(g_io_out_1_bits_isXSTrap), .io_out_1_bits_waitForward(g_io_out_1_bits_waitForward), .io_out_1_bits_blockBackward(g_io_out_1_bits_blockBackward),
    .io_out_1_bits_flushPipe(g_io_out_1_bits_flushPipe), .io_out_1_bits_canRobCompress(g_io_out_1_bits_canRobCompress), .io_out_1_bits_selImm(g_io_out_1_bits_selImm), .io_out_1_bits_imm(g_io_out_1_bits_imm),
    .io_out_1_bits_fpu_typeTagOut(g_io_out_1_bits_fpu_typeTagOut), .io_out_1_bits_fpu_wflags(g_io_out_1_bits_fpu_wflags), .io_out_1_bits_fpu_typ(g_io_out_1_bits_fpu_typ), .io_out_1_bits_fpu_fmt(g_io_out_1_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm(g_io_out_1_bits_fpu_rm), .io_out_1_bits_vpu_vill(g_io_out_1_bits_vpu_vill), .io_out_1_bits_vpu_vma(g_io_out_1_bits_vpu_vma), .io_out_1_bits_vpu_vta(g_io_out_1_bits_vpu_vta),
    .io_out_1_bits_vpu_vsew(g_io_out_1_bits_vpu_vsew), .io_out_1_bits_vpu_vlmul(g_io_out_1_bits_vpu_vlmul), .io_out_1_bits_vpu_specVill(g_io_out_1_bits_vpu_specVill), .io_out_1_bits_vpu_specVma(g_io_out_1_bits_vpu_specVma),
    .io_out_1_bits_vpu_specVta(g_io_out_1_bits_vpu_specVta), .io_out_1_bits_vpu_specVsew(g_io_out_1_bits_vpu_specVsew), .io_out_1_bits_vpu_specVlmul(g_io_out_1_bits_vpu_specVlmul), .io_out_1_bits_vpu_vm(g_io_out_1_bits_vpu_vm),
    .io_out_1_bits_vpu_vstart(g_io_out_1_bits_vpu_vstart), .io_out_1_bits_vpu_fpu_isFoldTo1_2(g_io_out_1_bits_vpu_fpu_isFoldTo1_2), .io_out_1_bits_vpu_fpu_isFoldTo1_4(g_io_out_1_bits_vpu_fpu_isFoldTo1_4), .io_out_1_bits_vpu_fpu_isFoldTo1_8(g_io_out_1_bits_vpu_fpu_isFoldTo1_8),
    .io_out_1_bits_vpu_nf(g_io_out_1_bits_vpu_nf), .io_out_1_bits_vpu_veew(g_io_out_1_bits_vpu_veew), .io_out_1_bits_vpu_isReverse(g_io_out_1_bits_vpu_isReverse), .io_out_1_bits_vpu_isExt(g_io_out_1_bits_vpu_isExt),
    .io_out_1_bits_vpu_isNarrow(g_io_out_1_bits_vpu_isNarrow), .io_out_1_bits_vpu_isDstMask(g_io_out_1_bits_vpu_isDstMask), .io_out_1_bits_vpu_isOpMask(g_io_out_1_bits_vpu_isOpMask), .io_out_1_bits_vpu_isDependOldVd(g_io_out_1_bits_vpu_isDependOldVd),
    .io_out_1_bits_vpu_isWritePartVd(g_io_out_1_bits_vpu_isWritePartVd), .io_out_1_bits_vpu_isVleff(g_io_out_1_bits_vpu_isVleff), .io_out_1_bits_vlsInstr(g_io_out_1_bits_vlsInstr), .io_out_1_bits_wfflags(g_io_out_1_bits_wfflags),
    .io_out_1_bits_isMove(g_io_out_1_bits_isMove), .io_out_1_bits_uopIdx(g_io_out_1_bits_uopIdx), .io_out_1_bits_uopSplitType(g_io_out_1_bits_uopSplitType), .io_out_1_bits_isVset(g_io_out_1_bits_isVset),
    .io_out_1_bits_firstUop(g_io_out_1_bits_firstUop), .io_out_1_bits_lastUop(g_io_out_1_bits_lastUop), .io_out_1_bits_numUops(g_io_out_1_bits_numUops), .io_out_1_bits_numWB(g_io_out_1_bits_numWB),
    .io_out_1_bits_commitType(g_io_out_1_bits_commitType), .io_out_1_bits_debug_fuType(g_io_out_1_bits_debug_fuType), .io_out_1_bits_debug_seqNum_seqNum(g_io_out_1_bits_debug_seqNum_seqNum), .io_out_1_bits_debug_seqNum_uopIdx(g_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_valid(g_io_out_2_valid), .io_out_2_bits_instr(g_io_out_2_bits_instr), .io_out_2_bits_pc(g_io_out_2_bits_pc), .io_out_2_bits_foldpc(g_io_out_2_bits_foldpc),
    .io_out_2_bits_exceptionVec_0(g_io_out_2_bits_exceptionVec_0), .io_out_2_bits_exceptionVec_1(g_io_out_2_bits_exceptionVec_1), .io_out_2_bits_exceptionVec_2(g_io_out_2_bits_exceptionVec_2), .io_out_2_bits_exceptionVec_3(g_io_out_2_bits_exceptionVec_3),
    .io_out_2_bits_exceptionVec_4(g_io_out_2_bits_exceptionVec_4), .io_out_2_bits_exceptionVec_5(g_io_out_2_bits_exceptionVec_5), .io_out_2_bits_exceptionVec_6(g_io_out_2_bits_exceptionVec_6), .io_out_2_bits_exceptionVec_7(g_io_out_2_bits_exceptionVec_7),
    .io_out_2_bits_exceptionVec_8(g_io_out_2_bits_exceptionVec_8), .io_out_2_bits_exceptionVec_9(g_io_out_2_bits_exceptionVec_9), .io_out_2_bits_exceptionVec_10(g_io_out_2_bits_exceptionVec_10), .io_out_2_bits_exceptionVec_11(g_io_out_2_bits_exceptionVec_11),
    .io_out_2_bits_exceptionVec_12(g_io_out_2_bits_exceptionVec_12), .io_out_2_bits_exceptionVec_13(g_io_out_2_bits_exceptionVec_13), .io_out_2_bits_exceptionVec_14(g_io_out_2_bits_exceptionVec_14), .io_out_2_bits_exceptionVec_15(g_io_out_2_bits_exceptionVec_15),
    .io_out_2_bits_exceptionVec_16(g_io_out_2_bits_exceptionVec_16), .io_out_2_bits_exceptionVec_17(g_io_out_2_bits_exceptionVec_17), .io_out_2_bits_exceptionVec_18(g_io_out_2_bits_exceptionVec_18), .io_out_2_bits_exceptionVec_19(g_io_out_2_bits_exceptionVec_19),
    .io_out_2_bits_exceptionVec_20(g_io_out_2_bits_exceptionVec_20), .io_out_2_bits_exceptionVec_21(g_io_out_2_bits_exceptionVec_21), .io_out_2_bits_exceptionVec_22(g_io_out_2_bits_exceptionVec_22), .io_out_2_bits_exceptionVec_23(g_io_out_2_bits_exceptionVec_23),
    .io_out_2_bits_isFetchMalAddr(g_io_out_2_bits_isFetchMalAddr), .io_out_2_bits_trigger(g_io_out_2_bits_trigger), .io_out_2_bits_preDecodeInfo_valid(g_io_out_2_bits_preDecodeInfo_valid), .io_out_2_bits_preDecodeInfo_isRVC(g_io_out_2_bits_preDecodeInfo_isRVC),
    .io_out_2_bits_preDecodeInfo_brType(g_io_out_2_bits_preDecodeInfo_brType), .io_out_2_bits_preDecodeInfo_isCall(g_io_out_2_bits_preDecodeInfo_isCall), .io_out_2_bits_preDecodeInfo_isRet(g_io_out_2_bits_preDecodeInfo_isRet), .io_out_2_bits_pred_taken(g_io_out_2_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(g_io_out_2_bits_crossPageIPFFix), .io_out_2_bits_ftqPtr_flag(g_io_out_2_bits_ftqPtr_flag), .io_out_2_bits_ftqPtr_value(g_io_out_2_bits_ftqPtr_value), .io_out_2_bits_ftqOffset(g_io_out_2_bits_ftqOffset),
    .io_out_2_bits_satpFlushFirstFetchFault(g_io_out_2_bits_satpFlushFirstFetchFault), .io_out_2_bits_srcType_0(g_io_out_2_bits_srcType_0), .io_out_2_bits_srcType_1(g_io_out_2_bits_srcType_1), .io_out_2_bits_srcType_2(g_io_out_2_bits_srcType_2),
    .io_out_2_bits_srcType_3(g_io_out_2_bits_srcType_3), .io_out_2_bits_srcType_4(g_io_out_2_bits_srcType_4), .io_out_2_bits_lsrc_0(g_io_out_2_bits_lsrc_0), .io_out_2_bits_lsrc_1(g_io_out_2_bits_lsrc_1),
    .io_out_2_bits_lsrc_2(g_io_out_2_bits_lsrc_2), .io_out_2_bits_ldest(g_io_out_2_bits_ldest), .io_out_2_bits_fuType(g_io_out_2_bits_fuType), .io_out_2_bits_fuOpType(g_io_out_2_bits_fuOpType),
    .io_out_2_bits_rfWen(g_io_out_2_bits_rfWen), .io_out_2_bits_fpWen(g_io_out_2_bits_fpWen), .io_out_2_bits_vecWen(g_io_out_2_bits_vecWen), .io_out_2_bits_v0Wen(g_io_out_2_bits_v0Wen),
    .io_out_2_bits_vlWen(g_io_out_2_bits_vlWen), .io_out_2_bits_isXSTrap(g_io_out_2_bits_isXSTrap), .io_out_2_bits_waitForward(g_io_out_2_bits_waitForward), .io_out_2_bits_blockBackward(g_io_out_2_bits_blockBackward),
    .io_out_2_bits_flushPipe(g_io_out_2_bits_flushPipe), .io_out_2_bits_canRobCompress(g_io_out_2_bits_canRobCompress), .io_out_2_bits_selImm(g_io_out_2_bits_selImm), .io_out_2_bits_imm(g_io_out_2_bits_imm),
    .io_out_2_bits_fpu_typeTagOut(g_io_out_2_bits_fpu_typeTagOut), .io_out_2_bits_fpu_wflags(g_io_out_2_bits_fpu_wflags), .io_out_2_bits_fpu_typ(g_io_out_2_bits_fpu_typ), .io_out_2_bits_fpu_fmt(g_io_out_2_bits_fpu_fmt),
    .io_out_2_bits_fpu_rm(g_io_out_2_bits_fpu_rm), .io_out_2_bits_vpu_vill(g_io_out_2_bits_vpu_vill), .io_out_2_bits_vpu_vma(g_io_out_2_bits_vpu_vma), .io_out_2_bits_vpu_vta(g_io_out_2_bits_vpu_vta),
    .io_out_2_bits_vpu_vsew(g_io_out_2_bits_vpu_vsew), .io_out_2_bits_vpu_vlmul(g_io_out_2_bits_vpu_vlmul), .io_out_2_bits_vpu_specVill(g_io_out_2_bits_vpu_specVill), .io_out_2_bits_vpu_specVma(g_io_out_2_bits_vpu_specVma),
    .io_out_2_bits_vpu_specVta(g_io_out_2_bits_vpu_specVta), .io_out_2_bits_vpu_specVsew(g_io_out_2_bits_vpu_specVsew), .io_out_2_bits_vpu_specVlmul(g_io_out_2_bits_vpu_specVlmul), .io_out_2_bits_vpu_vm(g_io_out_2_bits_vpu_vm),
    .io_out_2_bits_vpu_vstart(g_io_out_2_bits_vpu_vstart), .io_out_2_bits_vpu_fpu_isFoldTo1_2(g_io_out_2_bits_vpu_fpu_isFoldTo1_2), .io_out_2_bits_vpu_fpu_isFoldTo1_4(g_io_out_2_bits_vpu_fpu_isFoldTo1_4), .io_out_2_bits_vpu_fpu_isFoldTo1_8(g_io_out_2_bits_vpu_fpu_isFoldTo1_8),
    .io_out_2_bits_vpu_nf(g_io_out_2_bits_vpu_nf), .io_out_2_bits_vpu_veew(g_io_out_2_bits_vpu_veew), .io_out_2_bits_vpu_isReverse(g_io_out_2_bits_vpu_isReverse), .io_out_2_bits_vpu_isExt(g_io_out_2_bits_vpu_isExt),
    .io_out_2_bits_vpu_isNarrow(g_io_out_2_bits_vpu_isNarrow), .io_out_2_bits_vpu_isDstMask(g_io_out_2_bits_vpu_isDstMask), .io_out_2_bits_vpu_isOpMask(g_io_out_2_bits_vpu_isOpMask), .io_out_2_bits_vpu_isDependOldVd(g_io_out_2_bits_vpu_isDependOldVd),
    .io_out_2_bits_vpu_isWritePartVd(g_io_out_2_bits_vpu_isWritePartVd), .io_out_2_bits_vpu_isVleff(g_io_out_2_bits_vpu_isVleff), .io_out_2_bits_vlsInstr(g_io_out_2_bits_vlsInstr), .io_out_2_bits_wfflags(g_io_out_2_bits_wfflags),
    .io_out_2_bits_isMove(g_io_out_2_bits_isMove), .io_out_2_bits_uopIdx(g_io_out_2_bits_uopIdx), .io_out_2_bits_uopSplitType(g_io_out_2_bits_uopSplitType), .io_out_2_bits_isVset(g_io_out_2_bits_isVset),
    .io_out_2_bits_firstUop(g_io_out_2_bits_firstUop), .io_out_2_bits_lastUop(g_io_out_2_bits_lastUop), .io_out_2_bits_numUops(g_io_out_2_bits_numUops), .io_out_2_bits_numWB(g_io_out_2_bits_numWB),
    .io_out_2_bits_commitType(g_io_out_2_bits_commitType), .io_out_2_bits_debug_fuType(g_io_out_2_bits_debug_fuType), .io_out_2_bits_debug_seqNum_seqNum(g_io_out_2_bits_debug_seqNum_seqNum), .io_out_2_bits_debug_seqNum_uopIdx(g_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_valid(g_io_out_3_valid), .io_out_3_bits_instr(g_io_out_3_bits_instr), .io_out_3_bits_pc(g_io_out_3_bits_pc), .io_out_3_bits_foldpc(g_io_out_3_bits_foldpc),
    .io_out_3_bits_exceptionVec_0(g_io_out_3_bits_exceptionVec_0), .io_out_3_bits_exceptionVec_1(g_io_out_3_bits_exceptionVec_1), .io_out_3_bits_exceptionVec_2(g_io_out_3_bits_exceptionVec_2), .io_out_3_bits_exceptionVec_3(g_io_out_3_bits_exceptionVec_3),
    .io_out_3_bits_exceptionVec_4(g_io_out_3_bits_exceptionVec_4), .io_out_3_bits_exceptionVec_5(g_io_out_3_bits_exceptionVec_5), .io_out_3_bits_exceptionVec_6(g_io_out_3_bits_exceptionVec_6), .io_out_3_bits_exceptionVec_7(g_io_out_3_bits_exceptionVec_7),
    .io_out_3_bits_exceptionVec_8(g_io_out_3_bits_exceptionVec_8), .io_out_3_bits_exceptionVec_9(g_io_out_3_bits_exceptionVec_9), .io_out_3_bits_exceptionVec_10(g_io_out_3_bits_exceptionVec_10), .io_out_3_bits_exceptionVec_11(g_io_out_3_bits_exceptionVec_11),
    .io_out_3_bits_exceptionVec_12(g_io_out_3_bits_exceptionVec_12), .io_out_3_bits_exceptionVec_13(g_io_out_3_bits_exceptionVec_13), .io_out_3_bits_exceptionVec_14(g_io_out_3_bits_exceptionVec_14), .io_out_3_bits_exceptionVec_15(g_io_out_3_bits_exceptionVec_15),
    .io_out_3_bits_exceptionVec_16(g_io_out_3_bits_exceptionVec_16), .io_out_3_bits_exceptionVec_17(g_io_out_3_bits_exceptionVec_17), .io_out_3_bits_exceptionVec_18(g_io_out_3_bits_exceptionVec_18), .io_out_3_bits_exceptionVec_19(g_io_out_3_bits_exceptionVec_19),
    .io_out_3_bits_exceptionVec_20(g_io_out_3_bits_exceptionVec_20), .io_out_3_bits_exceptionVec_21(g_io_out_3_bits_exceptionVec_21), .io_out_3_bits_exceptionVec_22(g_io_out_3_bits_exceptionVec_22), .io_out_3_bits_exceptionVec_23(g_io_out_3_bits_exceptionVec_23),
    .io_out_3_bits_isFetchMalAddr(g_io_out_3_bits_isFetchMalAddr), .io_out_3_bits_trigger(g_io_out_3_bits_trigger), .io_out_3_bits_preDecodeInfo_valid(g_io_out_3_bits_preDecodeInfo_valid), .io_out_3_bits_preDecodeInfo_isRVC(g_io_out_3_bits_preDecodeInfo_isRVC),
    .io_out_3_bits_preDecodeInfo_brType(g_io_out_3_bits_preDecodeInfo_brType), .io_out_3_bits_preDecodeInfo_isCall(g_io_out_3_bits_preDecodeInfo_isCall), .io_out_3_bits_preDecodeInfo_isRet(g_io_out_3_bits_preDecodeInfo_isRet), .io_out_3_bits_pred_taken(g_io_out_3_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(g_io_out_3_bits_crossPageIPFFix), .io_out_3_bits_ftqPtr_flag(g_io_out_3_bits_ftqPtr_flag), .io_out_3_bits_ftqPtr_value(g_io_out_3_bits_ftqPtr_value), .io_out_3_bits_ftqOffset(g_io_out_3_bits_ftqOffset),
    .io_out_3_bits_satpFlushFirstFetchFault(g_io_out_3_bits_satpFlushFirstFetchFault), .io_out_3_bits_srcType_0(g_io_out_3_bits_srcType_0), .io_out_3_bits_srcType_1(g_io_out_3_bits_srcType_1), .io_out_3_bits_srcType_2(g_io_out_3_bits_srcType_2),
    .io_out_3_bits_srcType_3(g_io_out_3_bits_srcType_3), .io_out_3_bits_srcType_4(g_io_out_3_bits_srcType_4), .io_out_3_bits_lsrc_0(g_io_out_3_bits_lsrc_0), .io_out_3_bits_lsrc_1(g_io_out_3_bits_lsrc_1),
    .io_out_3_bits_lsrc_2(g_io_out_3_bits_lsrc_2), .io_out_3_bits_ldest(g_io_out_3_bits_ldest), .io_out_3_bits_fuType(g_io_out_3_bits_fuType), .io_out_3_bits_fuOpType(g_io_out_3_bits_fuOpType),
    .io_out_3_bits_rfWen(g_io_out_3_bits_rfWen), .io_out_3_bits_fpWen(g_io_out_3_bits_fpWen), .io_out_3_bits_vecWen(g_io_out_3_bits_vecWen), .io_out_3_bits_v0Wen(g_io_out_3_bits_v0Wen),
    .io_out_3_bits_vlWen(g_io_out_3_bits_vlWen), .io_out_3_bits_isXSTrap(g_io_out_3_bits_isXSTrap), .io_out_3_bits_waitForward(g_io_out_3_bits_waitForward), .io_out_3_bits_blockBackward(g_io_out_3_bits_blockBackward),
    .io_out_3_bits_flushPipe(g_io_out_3_bits_flushPipe), .io_out_3_bits_canRobCompress(g_io_out_3_bits_canRobCompress), .io_out_3_bits_selImm(g_io_out_3_bits_selImm), .io_out_3_bits_imm(g_io_out_3_bits_imm),
    .io_out_3_bits_fpu_typeTagOut(g_io_out_3_bits_fpu_typeTagOut), .io_out_3_bits_fpu_wflags(g_io_out_3_bits_fpu_wflags), .io_out_3_bits_fpu_typ(g_io_out_3_bits_fpu_typ), .io_out_3_bits_fpu_fmt(g_io_out_3_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm(g_io_out_3_bits_fpu_rm), .io_out_3_bits_vpu_vill(g_io_out_3_bits_vpu_vill), .io_out_3_bits_vpu_vma(g_io_out_3_bits_vpu_vma), .io_out_3_bits_vpu_vta(g_io_out_3_bits_vpu_vta),
    .io_out_3_bits_vpu_vsew(g_io_out_3_bits_vpu_vsew), .io_out_3_bits_vpu_vlmul(g_io_out_3_bits_vpu_vlmul), .io_out_3_bits_vpu_specVill(g_io_out_3_bits_vpu_specVill), .io_out_3_bits_vpu_specVma(g_io_out_3_bits_vpu_specVma),
    .io_out_3_bits_vpu_specVta(g_io_out_3_bits_vpu_specVta), .io_out_3_bits_vpu_specVsew(g_io_out_3_bits_vpu_specVsew), .io_out_3_bits_vpu_specVlmul(g_io_out_3_bits_vpu_specVlmul), .io_out_3_bits_vpu_vm(g_io_out_3_bits_vpu_vm),
    .io_out_3_bits_vpu_vstart(g_io_out_3_bits_vpu_vstart), .io_out_3_bits_vpu_fpu_isFoldTo1_2(g_io_out_3_bits_vpu_fpu_isFoldTo1_2), .io_out_3_bits_vpu_fpu_isFoldTo1_4(g_io_out_3_bits_vpu_fpu_isFoldTo1_4), .io_out_3_bits_vpu_fpu_isFoldTo1_8(g_io_out_3_bits_vpu_fpu_isFoldTo1_8),
    .io_out_3_bits_vpu_nf(g_io_out_3_bits_vpu_nf), .io_out_3_bits_vpu_veew(g_io_out_3_bits_vpu_veew), .io_out_3_bits_vpu_isReverse(g_io_out_3_bits_vpu_isReverse), .io_out_3_bits_vpu_isExt(g_io_out_3_bits_vpu_isExt),
    .io_out_3_bits_vpu_isNarrow(g_io_out_3_bits_vpu_isNarrow), .io_out_3_bits_vpu_isDstMask(g_io_out_3_bits_vpu_isDstMask), .io_out_3_bits_vpu_isOpMask(g_io_out_3_bits_vpu_isOpMask), .io_out_3_bits_vpu_isDependOldVd(g_io_out_3_bits_vpu_isDependOldVd),
    .io_out_3_bits_vpu_isWritePartVd(g_io_out_3_bits_vpu_isWritePartVd), .io_out_3_bits_vpu_isVleff(g_io_out_3_bits_vpu_isVleff), .io_out_3_bits_vlsInstr(g_io_out_3_bits_vlsInstr), .io_out_3_bits_wfflags(g_io_out_3_bits_wfflags),
    .io_out_3_bits_isMove(g_io_out_3_bits_isMove), .io_out_3_bits_uopIdx(g_io_out_3_bits_uopIdx), .io_out_3_bits_uopSplitType(g_io_out_3_bits_uopSplitType), .io_out_3_bits_isVset(g_io_out_3_bits_isVset),
    .io_out_3_bits_firstUop(g_io_out_3_bits_firstUop), .io_out_3_bits_lastUop(g_io_out_3_bits_lastUop), .io_out_3_bits_numUops(g_io_out_3_bits_numUops), .io_out_3_bits_numWB(g_io_out_3_bits_numWB),
    .io_out_3_bits_commitType(g_io_out_3_bits_commitType), .io_out_3_bits_debug_fuType(g_io_out_3_bits_debug_fuType), .io_out_3_bits_debug_seqNum_seqNum(g_io_out_3_bits_debug_seqNum_seqNum), .io_out_3_bits_debug_seqNum_uopIdx(g_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_4_valid(g_io_out_4_valid), .io_out_4_bits_instr(g_io_out_4_bits_instr), .io_out_4_bits_pc(g_io_out_4_bits_pc), .io_out_4_bits_foldpc(g_io_out_4_bits_foldpc),
    .io_out_4_bits_exceptionVec_0(g_io_out_4_bits_exceptionVec_0), .io_out_4_bits_exceptionVec_1(g_io_out_4_bits_exceptionVec_1), .io_out_4_bits_exceptionVec_2(g_io_out_4_bits_exceptionVec_2), .io_out_4_bits_exceptionVec_3(g_io_out_4_bits_exceptionVec_3),
    .io_out_4_bits_exceptionVec_4(g_io_out_4_bits_exceptionVec_4), .io_out_4_bits_exceptionVec_5(g_io_out_4_bits_exceptionVec_5), .io_out_4_bits_exceptionVec_6(g_io_out_4_bits_exceptionVec_6), .io_out_4_bits_exceptionVec_7(g_io_out_4_bits_exceptionVec_7),
    .io_out_4_bits_exceptionVec_8(g_io_out_4_bits_exceptionVec_8), .io_out_4_bits_exceptionVec_9(g_io_out_4_bits_exceptionVec_9), .io_out_4_bits_exceptionVec_10(g_io_out_4_bits_exceptionVec_10), .io_out_4_bits_exceptionVec_11(g_io_out_4_bits_exceptionVec_11),
    .io_out_4_bits_exceptionVec_12(g_io_out_4_bits_exceptionVec_12), .io_out_4_bits_exceptionVec_13(g_io_out_4_bits_exceptionVec_13), .io_out_4_bits_exceptionVec_14(g_io_out_4_bits_exceptionVec_14), .io_out_4_bits_exceptionVec_15(g_io_out_4_bits_exceptionVec_15),
    .io_out_4_bits_exceptionVec_16(g_io_out_4_bits_exceptionVec_16), .io_out_4_bits_exceptionVec_17(g_io_out_4_bits_exceptionVec_17), .io_out_4_bits_exceptionVec_18(g_io_out_4_bits_exceptionVec_18), .io_out_4_bits_exceptionVec_19(g_io_out_4_bits_exceptionVec_19),
    .io_out_4_bits_exceptionVec_20(g_io_out_4_bits_exceptionVec_20), .io_out_4_bits_exceptionVec_21(g_io_out_4_bits_exceptionVec_21), .io_out_4_bits_exceptionVec_22(g_io_out_4_bits_exceptionVec_22), .io_out_4_bits_exceptionVec_23(g_io_out_4_bits_exceptionVec_23),
    .io_out_4_bits_isFetchMalAddr(g_io_out_4_bits_isFetchMalAddr), .io_out_4_bits_trigger(g_io_out_4_bits_trigger), .io_out_4_bits_preDecodeInfo_valid(g_io_out_4_bits_preDecodeInfo_valid), .io_out_4_bits_preDecodeInfo_isRVC(g_io_out_4_bits_preDecodeInfo_isRVC),
    .io_out_4_bits_preDecodeInfo_brType(g_io_out_4_bits_preDecodeInfo_brType), .io_out_4_bits_preDecodeInfo_isCall(g_io_out_4_bits_preDecodeInfo_isCall), .io_out_4_bits_preDecodeInfo_isRet(g_io_out_4_bits_preDecodeInfo_isRet), .io_out_4_bits_pred_taken(g_io_out_4_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(g_io_out_4_bits_crossPageIPFFix), .io_out_4_bits_ftqPtr_flag(g_io_out_4_bits_ftqPtr_flag), .io_out_4_bits_ftqPtr_value(g_io_out_4_bits_ftqPtr_value), .io_out_4_bits_ftqOffset(g_io_out_4_bits_ftqOffset),
    .io_out_4_bits_satpFlushFirstFetchFault(g_io_out_4_bits_satpFlushFirstFetchFault), .io_out_4_bits_srcType_0(g_io_out_4_bits_srcType_0), .io_out_4_bits_srcType_1(g_io_out_4_bits_srcType_1), .io_out_4_bits_srcType_2(g_io_out_4_bits_srcType_2),
    .io_out_4_bits_srcType_3(g_io_out_4_bits_srcType_3), .io_out_4_bits_srcType_4(g_io_out_4_bits_srcType_4), .io_out_4_bits_lsrc_0(g_io_out_4_bits_lsrc_0), .io_out_4_bits_lsrc_1(g_io_out_4_bits_lsrc_1),
    .io_out_4_bits_lsrc_2(g_io_out_4_bits_lsrc_2), .io_out_4_bits_ldest(g_io_out_4_bits_ldest), .io_out_4_bits_fuType(g_io_out_4_bits_fuType), .io_out_4_bits_fuOpType(g_io_out_4_bits_fuOpType),
    .io_out_4_bits_rfWen(g_io_out_4_bits_rfWen), .io_out_4_bits_fpWen(g_io_out_4_bits_fpWen), .io_out_4_bits_vecWen(g_io_out_4_bits_vecWen), .io_out_4_bits_v0Wen(g_io_out_4_bits_v0Wen),
    .io_out_4_bits_vlWen(g_io_out_4_bits_vlWen), .io_out_4_bits_isXSTrap(g_io_out_4_bits_isXSTrap), .io_out_4_bits_waitForward(g_io_out_4_bits_waitForward), .io_out_4_bits_blockBackward(g_io_out_4_bits_blockBackward),
    .io_out_4_bits_flushPipe(g_io_out_4_bits_flushPipe), .io_out_4_bits_canRobCompress(g_io_out_4_bits_canRobCompress), .io_out_4_bits_selImm(g_io_out_4_bits_selImm), .io_out_4_bits_imm(g_io_out_4_bits_imm),
    .io_out_4_bits_fpu_typeTagOut(g_io_out_4_bits_fpu_typeTagOut), .io_out_4_bits_fpu_wflags(g_io_out_4_bits_fpu_wflags), .io_out_4_bits_fpu_typ(g_io_out_4_bits_fpu_typ), .io_out_4_bits_fpu_fmt(g_io_out_4_bits_fpu_fmt),
    .io_out_4_bits_fpu_rm(g_io_out_4_bits_fpu_rm), .io_out_4_bits_vpu_vill(g_io_out_4_bits_vpu_vill), .io_out_4_bits_vpu_vma(g_io_out_4_bits_vpu_vma), .io_out_4_bits_vpu_vta(g_io_out_4_bits_vpu_vta),
    .io_out_4_bits_vpu_vsew(g_io_out_4_bits_vpu_vsew), .io_out_4_bits_vpu_vlmul(g_io_out_4_bits_vpu_vlmul), .io_out_4_bits_vpu_specVill(g_io_out_4_bits_vpu_specVill), .io_out_4_bits_vpu_specVma(g_io_out_4_bits_vpu_specVma),
    .io_out_4_bits_vpu_specVta(g_io_out_4_bits_vpu_specVta), .io_out_4_bits_vpu_specVsew(g_io_out_4_bits_vpu_specVsew), .io_out_4_bits_vpu_specVlmul(g_io_out_4_bits_vpu_specVlmul), .io_out_4_bits_vpu_vm(g_io_out_4_bits_vpu_vm),
    .io_out_4_bits_vpu_vstart(g_io_out_4_bits_vpu_vstart), .io_out_4_bits_vpu_fpu_isFoldTo1_2(g_io_out_4_bits_vpu_fpu_isFoldTo1_2), .io_out_4_bits_vpu_fpu_isFoldTo1_4(g_io_out_4_bits_vpu_fpu_isFoldTo1_4), .io_out_4_bits_vpu_fpu_isFoldTo1_8(g_io_out_4_bits_vpu_fpu_isFoldTo1_8),
    .io_out_4_bits_vpu_nf(g_io_out_4_bits_vpu_nf), .io_out_4_bits_vpu_veew(g_io_out_4_bits_vpu_veew), .io_out_4_bits_vpu_isReverse(g_io_out_4_bits_vpu_isReverse), .io_out_4_bits_vpu_isExt(g_io_out_4_bits_vpu_isExt),
    .io_out_4_bits_vpu_isNarrow(g_io_out_4_bits_vpu_isNarrow), .io_out_4_bits_vpu_isDstMask(g_io_out_4_bits_vpu_isDstMask), .io_out_4_bits_vpu_isOpMask(g_io_out_4_bits_vpu_isOpMask), .io_out_4_bits_vpu_isDependOldVd(g_io_out_4_bits_vpu_isDependOldVd),
    .io_out_4_bits_vpu_isWritePartVd(g_io_out_4_bits_vpu_isWritePartVd), .io_out_4_bits_vpu_isVleff(g_io_out_4_bits_vpu_isVleff), .io_out_4_bits_vlsInstr(g_io_out_4_bits_vlsInstr), .io_out_4_bits_wfflags(g_io_out_4_bits_wfflags),
    .io_out_4_bits_isMove(g_io_out_4_bits_isMove), .io_out_4_bits_uopIdx(g_io_out_4_bits_uopIdx), .io_out_4_bits_uopSplitType(g_io_out_4_bits_uopSplitType), .io_out_4_bits_isVset(g_io_out_4_bits_isVset),
    .io_out_4_bits_firstUop(g_io_out_4_bits_firstUop), .io_out_4_bits_lastUop(g_io_out_4_bits_lastUop), .io_out_4_bits_numUops(g_io_out_4_bits_numUops), .io_out_4_bits_numWB(g_io_out_4_bits_numWB),
    .io_out_4_bits_commitType(g_io_out_4_bits_commitType), .io_out_4_bits_debug_fuType(g_io_out_4_bits_debug_fuType), .io_out_4_bits_debug_seqNum_seqNum(g_io_out_4_bits_debug_seqNum_seqNum), .io_out_4_bits_debug_seqNum_uopIdx(g_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_5_valid(g_io_out_5_valid), .io_out_5_bits_instr(g_io_out_5_bits_instr), .io_out_5_bits_pc(g_io_out_5_bits_pc), .io_out_5_bits_foldpc(g_io_out_5_bits_foldpc),
    .io_out_5_bits_exceptionVec_0(g_io_out_5_bits_exceptionVec_0), .io_out_5_bits_exceptionVec_1(g_io_out_5_bits_exceptionVec_1), .io_out_5_bits_exceptionVec_2(g_io_out_5_bits_exceptionVec_2), .io_out_5_bits_exceptionVec_3(g_io_out_5_bits_exceptionVec_3),
    .io_out_5_bits_exceptionVec_4(g_io_out_5_bits_exceptionVec_4), .io_out_5_bits_exceptionVec_5(g_io_out_5_bits_exceptionVec_5), .io_out_5_bits_exceptionVec_6(g_io_out_5_bits_exceptionVec_6), .io_out_5_bits_exceptionVec_7(g_io_out_5_bits_exceptionVec_7),
    .io_out_5_bits_exceptionVec_8(g_io_out_5_bits_exceptionVec_8), .io_out_5_bits_exceptionVec_9(g_io_out_5_bits_exceptionVec_9), .io_out_5_bits_exceptionVec_10(g_io_out_5_bits_exceptionVec_10), .io_out_5_bits_exceptionVec_11(g_io_out_5_bits_exceptionVec_11),
    .io_out_5_bits_exceptionVec_12(g_io_out_5_bits_exceptionVec_12), .io_out_5_bits_exceptionVec_13(g_io_out_5_bits_exceptionVec_13), .io_out_5_bits_exceptionVec_14(g_io_out_5_bits_exceptionVec_14), .io_out_5_bits_exceptionVec_15(g_io_out_5_bits_exceptionVec_15),
    .io_out_5_bits_exceptionVec_16(g_io_out_5_bits_exceptionVec_16), .io_out_5_bits_exceptionVec_17(g_io_out_5_bits_exceptionVec_17), .io_out_5_bits_exceptionVec_18(g_io_out_5_bits_exceptionVec_18), .io_out_5_bits_exceptionVec_19(g_io_out_5_bits_exceptionVec_19),
    .io_out_5_bits_exceptionVec_20(g_io_out_5_bits_exceptionVec_20), .io_out_5_bits_exceptionVec_21(g_io_out_5_bits_exceptionVec_21), .io_out_5_bits_exceptionVec_22(g_io_out_5_bits_exceptionVec_22), .io_out_5_bits_exceptionVec_23(g_io_out_5_bits_exceptionVec_23),
    .io_out_5_bits_isFetchMalAddr(g_io_out_5_bits_isFetchMalAddr), .io_out_5_bits_trigger(g_io_out_5_bits_trigger), .io_out_5_bits_preDecodeInfo_valid(g_io_out_5_bits_preDecodeInfo_valid), .io_out_5_bits_preDecodeInfo_isRVC(g_io_out_5_bits_preDecodeInfo_isRVC),
    .io_out_5_bits_preDecodeInfo_brType(g_io_out_5_bits_preDecodeInfo_brType), .io_out_5_bits_preDecodeInfo_isCall(g_io_out_5_bits_preDecodeInfo_isCall), .io_out_5_bits_preDecodeInfo_isRet(g_io_out_5_bits_preDecodeInfo_isRet), .io_out_5_bits_pred_taken(g_io_out_5_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(g_io_out_5_bits_crossPageIPFFix), .io_out_5_bits_ftqPtr_flag(g_io_out_5_bits_ftqPtr_flag), .io_out_5_bits_ftqPtr_value(g_io_out_5_bits_ftqPtr_value), .io_out_5_bits_ftqOffset(g_io_out_5_bits_ftqOffset),
    .io_out_5_bits_satpFlushFirstFetchFault(g_io_out_5_bits_satpFlushFirstFetchFault), .io_out_5_bits_srcType_0(g_io_out_5_bits_srcType_0), .io_out_5_bits_srcType_1(g_io_out_5_bits_srcType_1), .io_out_5_bits_srcType_2(g_io_out_5_bits_srcType_2),
    .io_out_5_bits_srcType_3(g_io_out_5_bits_srcType_3), .io_out_5_bits_srcType_4(g_io_out_5_bits_srcType_4), .io_out_5_bits_lsrc_0(g_io_out_5_bits_lsrc_0), .io_out_5_bits_lsrc_1(g_io_out_5_bits_lsrc_1),
    .io_out_5_bits_lsrc_2(g_io_out_5_bits_lsrc_2), .io_out_5_bits_ldest(g_io_out_5_bits_ldest), .io_out_5_bits_fuType(g_io_out_5_bits_fuType), .io_out_5_bits_fuOpType(g_io_out_5_bits_fuOpType),
    .io_out_5_bits_rfWen(g_io_out_5_bits_rfWen), .io_out_5_bits_fpWen(g_io_out_5_bits_fpWen), .io_out_5_bits_vecWen(g_io_out_5_bits_vecWen), .io_out_5_bits_v0Wen(g_io_out_5_bits_v0Wen),
    .io_out_5_bits_vlWen(g_io_out_5_bits_vlWen), .io_out_5_bits_isXSTrap(g_io_out_5_bits_isXSTrap), .io_out_5_bits_waitForward(g_io_out_5_bits_waitForward), .io_out_5_bits_blockBackward(g_io_out_5_bits_blockBackward),
    .io_out_5_bits_flushPipe(g_io_out_5_bits_flushPipe), .io_out_5_bits_canRobCompress(g_io_out_5_bits_canRobCompress), .io_out_5_bits_selImm(g_io_out_5_bits_selImm), .io_out_5_bits_imm(g_io_out_5_bits_imm),
    .io_out_5_bits_fpu_typeTagOut(g_io_out_5_bits_fpu_typeTagOut), .io_out_5_bits_fpu_wflags(g_io_out_5_bits_fpu_wflags), .io_out_5_bits_fpu_typ(g_io_out_5_bits_fpu_typ), .io_out_5_bits_fpu_fmt(g_io_out_5_bits_fpu_fmt),
    .io_out_5_bits_fpu_rm(g_io_out_5_bits_fpu_rm), .io_out_5_bits_vpu_vill(g_io_out_5_bits_vpu_vill), .io_out_5_bits_vpu_vma(g_io_out_5_bits_vpu_vma), .io_out_5_bits_vpu_vta(g_io_out_5_bits_vpu_vta),
    .io_out_5_bits_vpu_vsew(g_io_out_5_bits_vpu_vsew), .io_out_5_bits_vpu_vlmul(g_io_out_5_bits_vpu_vlmul), .io_out_5_bits_vpu_specVill(g_io_out_5_bits_vpu_specVill), .io_out_5_bits_vpu_specVma(g_io_out_5_bits_vpu_specVma),
    .io_out_5_bits_vpu_specVta(g_io_out_5_bits_vpu_specVta), .io_out_5_bits_vpu_specVsew(g_io_out_5_bits_vpu_specVsew), .io_out_5_bits_vpu_specVlmul(g_io_out_5_bits_vpu_specVlmul), .io_out_5_bits_vpu_vm(g_io_out_5_bits_vpu_vm),
    .io_out_5_bits_vpu_vstart(g_io_out_5_bits_vpu_vstart), .io_out_5_bits_vpu_fpu_isFoldTo1_2(g_io_out_5_bits_vpu_fpu_isFoldTo1_2), .io_out_5_bits_vpu_fpu_isFoldTo1_4(g_io_out_5_bits_vpu_fpu_isFoldTo1_4), .io_out_5_bits_vpu_fpu_isFoldTo1_8(g_io_out_5_bits_vpu_fpu_isFoldTo1_8),
    .io_out_5_bits_vpu_nf(g_io_out_5_bits_vpu_nf), .io_out_5_bits_vpu_veew(g_io_out_5_bits_vpu_veew), .io_out_5_bits_vpu_isReverse(g_io_out_5_bits_vpu_isReverse), .io_out_5_bits_vpu_isExt(g_io_out_5_bits_vpu_isExt),
    .io_out_5_bits_vpu_isNarrow(g_io_out_5_bits_vpu_isNarrow), .io_out_5_bits_vpu_isDstMask(g_io_out_5_bits_vpu_isDstMask), .io_out_5_bits_vpu_isOpMask(g_io_out_5_bits_vpu_isOpMask), .io_out_5_bits_vpu_isDependOldVd(g_io_out_5_bits_vpu_isDependOldVd),
    .io_out_5_bits_vpu_isWritePartVd(g_io_out_5_bits_vpu_isWritePartVd), .io_out_5_bits_vpu_isVleff(g_io_out_5_bits_vpu_isVleff), .io_out_5_bits_vlsInstr(g_io_out_5_bits_vlsInstr), .io_out_5_bits_wfflags(g_io_out_5_bits_wfflags),
    .io_out_5_bits_isMove(g_io_out_5_bits_isMove), .io_out_5_bits_uopIdx(g_io_out_5_bits_uopIdx), .io_out_5_bits_uopSplitType(g_io_out_5_bits_uopSplitType), .io_out_5_bits_isVset(g_io_out_5_bits_isVset),
    .io_out_5_bits_firstUop(g_io_out_5_bits_firstUop), .io_out_5_bits_lastUop(g_io_out_5_bits_lastUop), .io_out_5_bits_numUops(g_io_out_5_bits_numUops), .io_out_5_bits_numWB(g_io_out_5_bits_numWB),
    .io_out_5_bits_commitType(g_io_out_5_bits_commitType), .io_out_5_bits_debug_fuType(g_io_out_5_bits_debug_fuType), .io_out_5_bits_debug_seqNum_seqNum(g_io_out_5_bits_debug_seqNum_seqNum), .io_out_5_bits_debug_seqNum_uopIdx(g_io_out_5_bits_debug_seqNum_uopIdx),
    .io_intRat_0_0_hold(g_io_intRat_0_0_hold), .io_intRat_0_0_addr(g_io_intRat_0_0_addr), .io_intRat_0_1_hold(g_io_intRat_0_1_hold), .io_intRat_0_1_addr(g_io_intRat_0_1_addr),
    .io_intRat_1_0_hold(g_io_intRat_1_0_hold), .io_intRat_1_0_addr(g_io_intRat_1_0_addr), .io_intRat_1_1_hold(g_io_intRat_1_1_hold), .io_intRat_1_1_addr(g_io_intRat_1_1_addr),
    .io_intRat_2_0_hold(g_io_intRat_2_0_hold), .io_intRat_2_0_addr(g_io_intRat_2_0_addr), .io_intRat_2_1_hold(g_io_intRat_2_1_hold), .io_intRat_2_1_addr(g_io_intRat_2_1_addr),
    .io_intRat_3_0_hold(g_io_intRat_3_0_hold), .io_intRat_3_0_addr(g_io_intRat_3_0_addr), .io_intRat_3_1_hold(g_io_intRat_3_1_hold), .io_intRat_3_1_addr(g_io_intRat_3_1_addr),
    .io_intRat_4_0_hold(g_io_intRat_4_0_hold), .io_intRat_4_0_addr(g_io_intRat_4_0_addr), .io_intRat_4_1_hold(g_io_intRat_4_1_hold), .io_intRat_4_1_addr(g_io_intRat_4_1_addr),
    .io_intRat_5_0_hold(g_io_intRat_5_0_hold), .io_intRat_5_0_addr(g_io_intRat_5_0_addr), .io_intRat_5_1_hold(g_io_intRat_5_1_hold), .io_intRat_5_1_addr(g_io_intRat_5_1_addr),
    .io_fpRat_0_0_hold(g_io_fpRat_0_0_hold), .io_fpRat_0_0_addr(g_io_fpRat_0_0_addr), .io_fpRat_0_1_hold(g_io_fpRat_0_1_hold), .io_fpRat_0_1_addr(g_io_fpRat_0_1_addr),
    .io_fpRat_0_2_hold(g_io_fpRat_0_2_hold), .io_fpRat_0_2_addr(g_io_fpRat_0_2_addr), .io_fpRat_1_0_hold(g_io_fpRat_1_0_hold), .io_fpRat_1_0_addr(g_io_fpRat_1_0_addr),
    .io_fpRat_1_1_hold(g_io_fpRat_1_1_hold), .io_fpRat_1_1_addr(g_io_fpRat_1_1_addr), .io_fpRat_1_2_hold(g_io_fpRat_1_2_hold), .io_fpRat_1_2_addr(g_io_fpRat_1_2_addr),
    .io_fpRat_2_0_hold(g_io_fpRat_2_0_hold), .io_fpRat_2_0_addr(g_io_fpRat_2_0_addr), .io_fpRat_2_1_hold(g_io_fpRat_2_1_hold), .io_fpRat_2_1_addr(g_io_fpRat_2_1_addr),
    .io_fpRat_2_2_hold(g_io_fpRat_2_2_hold), .io_fpRat_2_2_addr(g_io_fpRat_2_2_addr), .io_fpRat_3_0_hold(g_io_fpRat_3_0_hold), .io_fpRat_3_0_addr(g_io_fpRat_3_0_addr),
    .io_fpRat_3_1_hold(g_io_fpRat_3_1_hold), .io_fpRat_3_1_addr(g_io_fpRat_3_1_addr), .io_fpRat_3_2_hold(g_io_fpRat_3_2_hold), .io_fpRat_3_2_addr(g_io_fpRat_3_2_addr),
    .io_fpRat_4_0_hold(g_io_fpRat_4_0_hold), .io_fpRat_4_0_addr(g_io_fpRat_4_0_addr), .io_fpRat_4_1_hold(g_io_fpRat_4_1_hold), .io_fpRat_4_1_addr(g_io_fpRat_4_1_addr),
    .io_fpRat_4_2_hold(g_io_fpRat_4_2_hold), .io_fpRat_4_2_addr(g_io_fpRat_4_2_addr), .io_fpRat_5_0_hold(g_io_fpRat_5_0_hold), .io_fpRat_5_0_addr(g_io_fpRat_5_0_addr),
    .io_fpRat_5_1_hold(g_io_fpRat_5_1_hold), .io_fpRat_5_1_addr(g_io_fpRat_5_1_addr), .io_fpRat_5_2_hold(g_io_fpRat_5_2_hold), .io_fpRat_5_2_addr(g_io_fpRat_5_2_addr),
    .io_vecRat_0_0_hold(g_io_vecRat_0_0_hold), .io_vecRat_0_0_addr(g_io_vecRat_0_0_addr), .io_vecRat_0_1_hold(g_io_vecRat_0_1_hold), .io_vecRat_0_1_addr(g_io_vecRat_0_1_addr),
    .io_vecRat_0_2_hold(g_io_vecRat_0_2_hold), .io_vecRat_0_2_addr(g_io_vecRat_0_2_addr), .io_vecRat_1_0_hold(g_io_vecRat_1_0_hold), .io_vecRat_1_0_addr(g_io_vecRat_1_0_addr),
    .io_vecRat_1_1_hold(g_io_vecRat_1_1_hold), .io_vecRat_1_1_addr(g_io_vecRat_1_1_addr), .io_vecRat_1_2_hold(g_io_vecRat_1_2_hold), .io_vecRat_1_2_addr(g_io_vecRat_1_2_addr),
    .io_vecRat_2_0_hold(g_io_vecRat_2_0_hold), .io_vecRat_2_0_addr(g_io_vecRat_2_0_addr), .io_vecRat_2_1_hold(g_io_vecRat_2_1_hold), .io_vecRat_2_1_addr(g_io_vecRat_2_1_addr),
    .io_vecRat_2_2_hold(g_io_vecRat_2_2_hold), .io_vecRat_2_2_addr(g_io_vecRat_2_2_addr), .io_vecRat_3_0_hold(g_io_vecRat_3_0_hold), .io_vecRat_3_0_addr(g_io_vecRat_3_0_addr),
    .io_vecRat_3_1_hold(g_io_vecRat_3_1_hold), .io_vecRat_3_1_addr(g_io_vecRat_3_1_addr), .io_vecRat_3_2_hold(g_io_vecRat_3_2_hold), .io_vecRat_3_2_addr(g_io_vecRat_3_2_addr),
    .io_vecRat_4_0_hold(g_io_vecRat_4_0_hold), .io_vecRat_4_0_addr(g_io_vecRat_4_0_addr), .io_vecRat_4_1_hold(g_io_vecRat_4_1_hold), .io_vecRat_4_1_addr(g_io_vecRat_4_1_addr),
    .io_vecRat_4_2_hold(g_io_vecRat_4_2_hold), .io_vecRat_4_2_addr(g_io_vecRat_4_2_addr), .io_vecRat_5_0_hold(g_io_vecRat_5_0_hold), .io_vecRat_5_0_addr(g_io_vecRat_5_0_addr),
    .io_vecRat_5_1_hold(g_io_vecRat_5_1_hold), .io_vecRat_5_1_addr(g_io_vecRat_5_1_addr), .io_vecRat_5_2_hold(g_io_vecRat_5_2_hold), .io_vecRat_5_2_addr(g_io_vecRat_5_2_addr),
    .io_v0Rat_0_hold(g_io_v0Rat_0_hold), .io_v0Rat_1_hold(g_io_v0Rat_1_hold), .io_v0Rat_2_hold(g_io_v0Rat_2_hold), .io_v0Rat_3_hold(g_io_v0Rat_3_hold),
    .io_v0Rat_4_hold(g_io_v0Rat_4_hold), .io_v0Rat_5_hold(g_io_v0Rat_5_hold), .io_vlRat_0_hold(g_io_vlRat_0_hold), .io_vlRat_1_hold(g_io_vlRat_1_hold),
    .io_vlRat_2_hold(g_io_vlRat_2_hold), .io_vlRat_3_hold(g_io_vlRat_3_hold), .io_vlRat_4_hold(g_io_vlRat_4_hold), .io_vlRat_5_hold(g_io_vlRat_5_hold),
    .io_stallReason_in_backReason_valid(g_io_stallReason_in_backReason_valid), .io_stallReason_in_backReason_bits(g_io_stallReason_in_backReason_bits), .io_stallReason_out_reason_0(g_io_stallReason_out_reason_0), .io_stallReason_out_reason_1(g_io_stallReason_out_reason_1),
    .io_stallReason_out_reason_2(g_io_stallReason_out_reason_2), .io_stallReason_out_reason_3(g_io_stallReason_out_reason_3), .io_stallReason_out_reason_4(g_io_stallReason_out_reason_4), .io_stallReason_out_reason_5(g_io_stallReason_out_reason_5),
    .io_toCSR_trapInstInfo_valid(g_io_toCSR_trapInstInfo_valid), .io_toCSR_trapInstInfo_bits_instr(g_io_toCSR_trapInstInfo_bits_instr), .io_toCSR_trapInstInfo_bits_ftqPtr_flag(g_io_toCSR_trapInstInfo_bits_ftqPtr_flag), .io_toCSR_trapInstInfo_bits_ftqPtr_value(g_io_toCSR_trapInstInfo_bits_ftqPtr_value),
    .io_toCSR_trapInstInfo_bits_ftqOffset(g_io_toCSR_trapInstInfo_bits_ftqOffset), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value)
  );

  DecodeStage_xs u_xs (
    .clock(clk), .reset(rst),
    .io_redirect(io_redirect), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_instr(io_in_0_bits_instr), .io_in_0_bits_pc(io_in_0_bits_pc),
    .io_in_0_bits_foldpc(io_in_0_bits_foldpc), .io_in_0_bits_exceptionVec_0(io_in_0_bits_exceptionVec_0), .io_in_0_bits_exceptionVec_1(io_in_0_bits_exceptionVec_1), .io_in_0_bits_exceptionVec_2(io_in_0_bits_exceptionVec_2),
    .io_in_0_bits_exceptionVec_4(io_in_0_bits_exceptionVec_4), .io_in_0_bits_exceptionVec_5(io_in_0_bits_exceptionVec_5), .io_in_0_bits_exceptionVec_6(io_in_0_bits_exceptionVec_6), .io_in_0_bits_exceptionVec_7(io_in_0_bits_exceptionVec_7),
    .io_in_0_bits_exceptionVec_8(io_in_0_bits_exceptionVec_8), .io_in_0_bits_exceptionVec_9(io_in_0_bits_exceptionVec_9), .io_in_0_bits_exceptionVec_10(io_in_0_bits_exceptionVec_10), .io_in_0_bits_exceptionVec_11(io_in_0_bits_exceptionVec_11),
    .io_in_0_bits_exceptionVec_12(io_in_0_bits_exceptionVec_12), .io_in_0_bits_exceptionVec_13(io_in_0_bits_exceptionVec_13), .io_in_0_bits_exceptionVec_14(io_in_0_bits_exceptionVec_14), .io_in_0_bits_exceptionVec_15(io_in_0_bits_exceptionVec_15),
    .io_in_0_bits_exceptionVec_16(io_in_0_bits_exceptionVec_16), .io_in_0_bits_exceptionVec_17(io_in_0_bits_exceptionVec_17), .io_in_0_bits_exceptionVec_18(io_in_0_bits_exceptionVec_18), .io_in_0_bits_exceptionVec_19(io_in_0_bits_exceptionVec_19),
    .io_in_0_bits_exceptionVec_20(io_in_0_bits_exceptionVec_20), .io_in_0_bits_exceptionVec_21(io_in_0_bits_exceptionVec_21), .io_in_0_bits_exceptionVec_23(io_in_0_bits_exceptionVec_23), .io_in_0_bits_isFetchMalAddr(io_in_0_bits_isFetchMalAddr),
    .io_in_0_bits_trigger(io_in_0_bits_trigger), .io_in_0_bits_preDecodeInfo_valid(io_in_0_bits_preDecodeInfo_valid), .io_in_0_bits_preDecodeInfo_isRVC(io_in_0_bits_preDecodeInfo_isRVC), .io_in_0_bits_preDecodeInfo_brType(io_in_0_bits_preDecodeInfo_brType),
    .io_in_0_bits_preDecodeInfo_isCall(io_in_0_bits_preDecodeInfo_isCall), .io_in_0_bits_preDecodeInfo_isRet(io_in_0_bits_preDecodeInfo_isRet), .io_in_0_bits_pred_taken(io_in_0_bits_pred_taken), .io_in_0_bits_crossPageIPFFix(io_in_0_bits_crossPageIPFFix),
    .io_in_0_bits_ftqPtr_flag(io_in_0_bits_ftqPtr_flag), .io_in_0_bits_ftqPtr_value(io_in_0_bits_ftqPtr_value), .io_in_0_bits_ftqOffset(io_in_0_bits_ftqOffset), .io_in_0_bits_isLastInFtqEntry(io_in_0_bits_isLastInFtqEntry),
    .io_in_0_bits_debug_seqNum_seqNum(io_in_0_bits_debug_seqNum_seqNum), .io_in_0_bits_debug_seqNum_uopIdx(io_in_0_bits_debug_seqNum_uopIdx), .io_in_0_bits_satpFlushFirstFetchFault(io_in_0_bits_satpFlushFirstFetchFault), .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_instr(io_in_1_bits_instr), .io_in_1_bits_pc(io_in_1_bits_pc), .io_in_1_bits_foldpc(io_in_1_bits_foldpc), .io_in_1_bits_exceptionVec_0(io_in_1_bits_exceptionVec_0),
    .io_in_1_bits_exceptionVec_1(io_in_1_bits_exceptionVec_1), .io_in_1_bits_exceptionVec_2(io_in_1_bits_exceptionVec_2), .io_in_1_bits_exceptionVec_4(io_in_1_bits_exceptionVec_4), .io_in_1_bits_exceptionVec_5(io_in_1_bits_exceptionVec_5),
    .io_in_1_bits_exceptionVec_6(io_in_1_bits_exceptionVec_6), .io_in_1_bits_exceptionVec_7(io_in_1_bits_exceptionVec_7), .io_in_1_bits_exceptionVec_8(io_in_1_bits_exceptionVec_8), .io_in_1_bits_exceptionVec_9(io_in_1_bits_exceptionVec_9),
    .io_in_1_bits_exceptionVec_10(io_in_1_bits_exceptionVec_10), .io_in_1_bits_exceptionVec_11(io_in_1_bits_exceptionVec_11), .io_in_1_bits_exceptionVec_12(io_in_1_bits_exceptionVec_12), .io_in_1_bits_exceptionVec_13(io_in_1_bits_exceptionVec_13),
    .io_in_1_bits_exceptionVec_14(io_in_1_bits_exceptionVec_14), .io_in_1_bits_exceptionVec_15(io_in_1_bits_exceptionVec_15), .io_in_1_bits_exceptionVec_16(io_in_1_bits_exceptionVec_16), .io_in_1_bits_exceptionVec_17(io_in_1_bits_exceptionVec_17),
    .io_in_1_bits_exceptionVec_18(io_in_1_bits_exceptionVec_18), .io_in_1_bits_exceptionVec_19(io_in_1_bits_exceptionVec_19), .io_in_1_bits_exceptionVec_20(io_in_1_bits_exceptionVec_20), .io_in_1_bits_exceptionVec_21(io_in_1_bits_exceptionVec_21),
    .io_in_1_bits_exceptionVec_23(io_in_1_bits_exceptionVec_23), .io_in_1_bits_isFetchMalAddr(io_in_1_bits_isFetchMalAddr), .io_in_1_bits_trigger(io_in_1_bits_trigger), .io_in_1_bits_preDecodeInfo_valid(io_in_1_bits_preDecodeInfo_valid),
    .io_in_1_bits_preDecodeInfo_isRVC(io_in_1_bits_preDecodeInfo_isRVC), .io_in_1_bits_preDecodeInfo_brType(io_in_1_bits_preDecodeInfo_brType), .io_in_1_bits_preDecodeInfo_isCall(io_in_1_bits_preDecodeInfo_isCall), .io_in_1_bits_preDecodeInfo_isRet(io_in_1_bits_preDecodeInfo_isRet),
    .io_in_1_bits_pred_taken(io_in_1_bits_pred_taken), .io_in_1_bits_crossPageIPFFix(io_in_1_bits_crossPageIPFFix), .io_in_1_bits_ftqPtr_flag(io_in_1_bits_ftqPtr_flag), .io_in_1_bits_ftqPtr_value(io_in_1_bits_ftqPtr_value),
    .io_in_1_bits_ftqOffset(io_in_1_bits_ftqOffset), .io_in_1_bits_isLastInFtqEntry(io_in_1_bits_isLastInFtqEntry), .io_in_1_bits_debug_seqNum_seqNum(io_in_1_bits_debug_seqNum_seqNum), .io_in_1_bits_debug_seqNum_uopIdx(io_in_1_bits_debug_seqNum_uopIdx),
    .io_in_1_bits_satpFlushFirstFetchFault(io_in_1_bits_satpFlushFirstFetchFault), .io_in_2_valid(io_in_2_valid), .io_in_2_bits_instr(io_in_2_bits_instr), .io_in_2_bits_pc(io_in_2_bits_pc),
    .io_in_2_bits_foldpc(io_in_2_bits_foldpc), .io_in_2_bits_exceptionVec_0(io_in_2_bits_exceptionVec_0), .io_in_2_bits_exceptionVec_1(io_in_2_bits_exceptionVec_1), .io_in_2_bits_exceptionVec_2(io_in_2_bits_exceptionVec_2),
    .io_in_2_bits_exceptionVec_4(io_in_2_bits_exceptionVec_4), .io_in_2_bits_exceptionVec_5(io_in_2_bits_exceptionVec_5), .io_in_2_bits_exceptionVec_6(io_in_2_bits_exceptionVec_6), .io_in_2_bits_exceptionVec_7(io_in_2_bits_exceptionVec_7),
    .io_in_2_bits_exceptionVec_8(io_in_2_bits_exceptionVec_8), .io_in_2_bits_exceptionVec_9(io_in_2_bits_exceptionVec_9), .io_in_2_bits_exceptionVec_10(io_in_2_bits_exceptionVec_10), .io_in_2_bits_exceptionVec_11(io_in_2_bits_exceptionVec_11),
    .io_in_2_bits_exceptionVec_12(io_in_2_bits_exceptionVec_12), .io_in_2_bits_exceptionVec_13(io_in_2_bits_exceptionVec_13), .io_in_2_bits_exceptionVec_14(io_in_2_bits_exceptionVec_14), .io_in_2_bits_exceptionVec_15(io_in_2_bits_exceptionVec_15),
    .io_in_2_bits_exceptionVec_16(io_in_2_bits_exceptionVec_16), .io_in_2_bits_exceptionVec_17(io_in_2_bits_exceptionVec_17), .io_in_2_bits_exceptionVec_18(io_in_2_bits_exceptionVec_18), .io_in_2_bits_exceptionVec_19(io_in_2_bits_exceptionVec_19),
    .io_in_2_bits_exceptionVec_20(io_in_2_bits_exceptionVec_20), .io_in_2_bits_exceptionVec_21(io_in_2_bits_exceptionVec_21), .io_in_2_bits_exceptionVec_23(io_in_2_bits_exceptionVec_23), .io_in_2_bits_isFetchMalAddr(io_in_2_bits_isFetchMalAddr),
    .io_in_2_bits_trigger(io_in_2_bits_trigger), .io_in_2_bits_preDecodeInfo_valid(io_in_2_bits_preDecodeInfo_valid), .io_in_2_bits_preDecodeInfo_isRVC(io_in_2_bits_preDecodeInfo_isRVC), .io_in_2_bits_preDecodeInfo_brType(io_in_2_bits_preDecodeInfo_brType),
    .io_in_2_bits_preDecodeInfo_isCall(io_in_2_bits_preDecodeInfo_isCall), .io_in_2_bits_preDecodeInfo_isRet(io_in_2_bits_preDecodeInfo_isRet), .io_in_2_bits_pred_taken(io_in_2_bits_pred_taken), .io_in_2_bits_crossPageIPFFix(io_in_2_bits_crossPageIPFFix),
    .io_in_2_bits_ftqPtr_flag(io_in_2_bits_ftqPtr_flag), .io_in_2_bits_ftqPtr_value(io_in_2_bits_ftqPtr_value), .io_in_2_bits_ftqOffset(io_in_2_bits_ftqOffset), .io_in_2_bits_isLastInFtqEntry(io_in_2_bits_isLastInFtqEntry),
    .io_in_2_bits_debug_seqNum_seqNum(io_in_2_bits_debug_seqNum_seqNum), .io_in_2_bits_debug_seqNum_uopIdx(io_in_2_bits_debug_seqNum_uopIdx), .io_in_2_bits_satpFlushFirstFetchFault(io_in_2_bits_satpFlushFirstFetchFault), .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_instr(io_in_3_bits_instr), .io_in_3_bits_pc(io_in_3_bits_pc), .io_in_3_bits_foldpc(io_in_3_bits_foldpc), .io_in_3_bits_exceptionVec_0(io_in_3_bits_exceptionVec_0),
    .io_in_3_bits_exceptionVec_1(io_in_3_bits_exceptionVec_1), .io_in_3_bits_exceptionVec_2(io_in_3_bits_exceptionVec_2), .io_in_3_bits_exceptionVec_4(io_in_3_bits_exceptionVec_4), .io_in_3_bits_exceptionVec_5(io_in_3_bits_exceptionVec_5),
    .io_in_3_bits_exceptionVec_6(io_in_3_bits_exceptionVec_6), .io_in_3_bits_exceptionVec_7(io_in_3_bits_exceptionVec_7), .io_in_3_bits_exceptionVec_8(io_in_3_bits_exceptionVec_8), .io_in_3_bits_exceptionVec_9(io_in_3_bits_exceptionVec_9),
    .io_in_3_bits_exceptionVec_10(io_in_3_bits_exceptionVec_10), .io_in_3_bits_exceptionVec_11(io_in_3_bits_exceptionVec_11), .io_in_3_bits_exceptionVec_12(io_in_3_bits_exceptionVec_12), .io_in_3_bits_exceptionVec_13(io_in_3_bits_exceptionVec_13),
    .io_in_3_bits_exceptionVec_14(io_in_3_bits_exceptionVec_14), .io_in_3_bits_exceptionVec_15(io_in_3_bits_exceptionVec_15), .io_in_3_bits_exceptionVec_16(io_in_3_bits_exceptionVec_16), .io_in_3_bits_exceptionVec_17(io_in_3_bits_exceptionVec_17),
    .io_in_3_bits_exceptionVec_18(io_in_3_bits_exceptionVec_18), .io_in_3_bits_exceptionVec_19(io_in_3_bits_exceptionVec_19), .io_in_3_bits_exceptionVec_20(io_in_3_bits_exceptionVec_20), .io_in_3_bits_exceptionVec_21(io_in_3_bits_exceptionVec_21),
    .io_in_3_bits_exceptionVec_23(io_in_3_bits_exceptionVec_23), .io_in_3_bits_isFetchMalAddr(io_in_3_bits_isFetchMalAddr), .io_in_3_bits_trigger(io_in_3_bits_trigger), .io_in_3_bits_preDecodeInfo_valid(io_in_3_bits_preDecodeInfo_valid),
    .io_in_3_bits_preDecodeInfo_isRVC(io_in_3_bits_preDecodeInfo_isRVC), .io_in_3_bits_preDecodeInfo_brType(io_in_3_bits_preDecodeInfo_brType), .io_in_3_bits_preDecodeInfo_isCall(io_in_3_bits_preDecodeInfo_isCall), .io_in_3_bits_preDecodeInfo_isRet(io_in_3_bits_preDecodeInfo_isRet),
    .io_in_3_bits_pred_taken(io_in_3_bits_pred_taken), .io_in_3_bits_crossPageIPFFix(io_in_3_bits_crossPageIPFFix), .io_in_3_bits_ftqPtr_flag(io_in_3_bits_ftqPtr_flag), .io_in_3_bits_ftqPtr_value(io_in_3_bits_ftqPtr_value),
    .io_in_3_bits_ftqOffset(io_in_3_bits_ftqOffset), .io_in_3_bits_isLastInFtqEntry(io_in_3_bits_isLastInFtqEntry), .io_in_3_bits_debug_seqNum_seqNum(io_in_3_bits_debug_seqNum_seqNum), .io_in_3_bits_debug_seqNum_uopIdx(io_in_3_bits_debug_seqNum_uopIdx),
    .io_in_3_bits_satpFlushFirstFetchFault(io_in_3_bits_satpFlushFirstFetchFault), .io_in_4_valid(io_in_4_valid), .io_in_4_bits_instr(io_in_4_bits_instr), .io_in_4_bits_pc(io_in_4_bits_pc),
    .io_in_4_bits_foldpc(io_in_4_bits_foldpc), .io_in_4_bits_exceptionVec_0(io_in_4_bits_exceptionVec_0), .io_in_4_bits_exceptionVec_1(io_in_4_bits_exceptionVec_1), .io_in_4_bits_exceptionVec_2(io_in_4_bits_exceptionVec_2),
    .io_in_4_bits_exceptionVec_4(io_in_4_bits_exceptionVec_4), .io_in_4_bits_exceptionVec_5(io_in_4_bits_exceptionVec_5), .io_in_4_bits_exceptionVec_6(io_in_4_bits_exceptionVec_6), .io_in_4_bits_exceptionVec_7(io_in_4_bits_exceptionVec_7),
    .io_in_4_bits_exceptionVec_8(io_in_4_bits_exceptionVec_8), .io_in_4_bits_exceptionVec_9(io_in_4_bits_exceptionVec_9), .io_in_4_bits_exceptionVec_10(io_in_4_bits_exceptionVec_10), .io_in_4_bits_exceptionVec_11(io_in_4_bits_exceptionVec_11),
    .io_in_4_bits_exceptionVec_12(io_in_4_bits_exceptionVec_12), .io_in_4_bits_exceptionVec_13(io_in_4_bits_exceptionVec_13), .io_in_4_bits_exceptionVec_14(io_in_4_bits_exceptionVec_14), .io_in_4_bits_exceptionVec_15(io_in_4_bits_exceptionVec_15),
    .io_in_4_bits_exceptionVec_16(io_in_4_bits_exceptionVec_16), .io_in_4_bits_exceptionVec_17(io_in_4_bits_exceptionVec_17), .io_in_4_bits_exceptionVec_18(io_in_4_bits_exceptionVec_18), .io_in_4_bits_exceptionVec_19(io_in_4_bits_exceptionVec_19),
    .io_in_4_bits_exceptionVec_20(io_in_4_bits_exceptionVec_20), .io_in_4_bits_exceptionVec_21(io_in_4_bits_exceptionVec_21), .io_in_4_bits_exceptionVec_23(io_in_4_bits_exceptionVec_23), .io_in_4_bits_isFetchMalAddr(io_in_4_bits_isFetchMalAddr),
    .io_in_4_bits_trigger(io_in_4_bits_trigger), .io_in_4_bits_preDecodeInfo_valid(io_in_4_bits_preDecodeInfo_valid), .io_in_4_bits_preDecodeInfo_isRVC(io_in_4_bits_preDecodeInfo_isRVC), .io_in_4_bits_preDecodeInfo_brType(io_in_4_bits_preDecodeInfo_brType),
    .io_in_4_bits_preDecodeInfo_isCall(io_in_4_bits_preDecodeInfo_isCall), .io_in_4_bits_preDecodeInfo_isRet(io_in_4_bits_preDecodeInfo_isRet), .io_in_4_bits_pred_taken(io_in_4_bits_pred_taken), .io_in_4_bits_crossPageIPFFix(io_in_4_bits_crossPageIPFFix),
    .io_in_4_bits_ftqPtr_flag(io_in_4_bits_ftqPtr_flag), .io_in_4_bits_ftqPtr_value(io_in_4_bits_ftqPtr_value), .io_in_4_bits_ftqOffset(io_in_4_bits_ftqOffset), .io_in_4_bits_isLastInFtqEntry(io_in_4_bits_isLastInFtqEntry),
    .io_in_4_bits_debug_seqNum_seqNum(io_in_4_bits_debug_seqNum_seqNum), .io_in_4_bits_debug_seqNum_uopIdx(io_in_4_bits_debug_seqNum_uopIdx), .io_in_4_bits_satpFlushFirstFetchFault(io_in_4_bits_satpFlushFirstFetchFault), .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_instr(io_in_5_bits_instr), .io_in_5_bits_pc(io_in_5_bits_pc), .io_in_5_bits_foldpc(io_in_5_bits_foldpc), .io_in_5_bits_exceptionVec_0(io_in_5_bits_exceptionVec_0),
    .io_in_5_bits_exceptionVec_1(io_in_5_bits_exceptionVec_1), .io_in_5_bits_exceptionVec_2(io_in_5_bits_exceptionVec_2), .io_in_5_bits_exceptionVec_4(io_in_5_bits_exceptionVec_4), .io_in_5_bits_exceptionVec_5(io_in_5_bits_exceptionVec_5),
    .io_in_5_bits_exceptionVec_6(io_in_5_bits_exceptionVec_6), .io_in_5_bits_exceptionVec_7(io_in_5_bits_exceptionVec_7), .io_in_5_bits_exceptionVec_8(io_in_5_bits_exceptionVec_8), .io_in_5_bits_exceptionVec_9(io_in_5_bits_exceptionVec_9),
    .io_in_5_bits_exceptionVec_10(io_in_5_bits_exceptionVec_10), .io_in_5_bits_exceptionVec_11(io_in_5_bits_exceptionVec_11), .io_in_5_bits_exceptionVec_12(io_in_5_bits_exceptionVec_12), .io_in_5_bits_exceptionVec_13(io_in_5_bits_exceptionVec_13),
    .io_in_5_bits_exceptionVec_14(io_in_5_bits_exceptionVec_14), .io_in_5_bits_exceptionVec_15(io_in_5_bits_exceptionVec_15), .io_in_5_bits_exceptionVec_16(io_in_5_bits_exceptionVec_16), .io_in_5_bits_exceptionVec_17(io_in_5_bits_exceptionVec_17),
    .io_in_5_bits_exceptionVec_18(io_in_5_bits_exceptionVec_18), .io_in_5_bits_exceptionVec_19(io_in_5_bits_exceptionVec_19), .io_in_5_bits_exceptionVec_20(io_in_5_bits_exceptionVec_20), .io_in_5_bits_exceptionVec_21(io_in_5_bits_exceptionVec_21),
    .io_in_5_bits_exceptionVec_23(io_in_5_bits_exceptionVec_23), .io_in_5_bits_isFetchMalAddr(io_in_5_bits_isFetchMalAddr), .io_in_5_bits_trigger(io_in_5_bits_trigger), .io_in_5_bits_preDecodeInfo_valid(io_in_5_bits_preDecodeInfo_valid),
    .io_in_5_bits_preDecodeInfo_isRVC(io_in_5_bits_preDecodeInfo_isRVC), .io_in_5_bits_preDecodeInfo_brType(io_in_5_bits_preDecodeInfo_brType), .io_in_5_bits_preDecodeInfo_isCall(io_in_5_bits_preDecodeInfo_isCall), .io_in_5_bits_preDecodeInfo_isRet(io_in_5_bits_preDecodeInfo_isRet),
    .io_in_5_bits_pred_taken(io_in_5_bits_pred_taken), .io_in_5_bits_crossPageIPFFix(io_in_5_bits_crossPageIPFFix), .io_in_5_bits_ftqPtr_flag(io_in_5_bits_ftqPtr_flag), .io_in_5_bits_ftqPtr_value(io_in_5_bits_ftqPtr_value),
    .io_in_5_bits_ftqOffset(io_in_5_bits_ftqOffset), .io_in_5_bits_isLastInFtqEntry(io_in_5_bits_isLastInFtqEntry), .io_in_5_bits_debug_seqNum_seqNum(io_in_5_bits_debug_seqNum_seqNum), .io_in_5_bits_debug_seqNum_uopIdx(io_in_5_bits_debug_seqNum_uopIdx),
    .io_in_5_bits_satpFlushFirstFetchFault(io_in_5_bits_satpFlushFirstFetchFault), .io_out_0_ready(io_out_0_ready), .io_out_1_ready(io_out_1_ready), .io_out_2_ready(io_out_2_ready),
    .io_out_3_ready(io_out_3_ready), .io_out_4_ready(io_out_4_ready), .io_out_5_ready(io_out_5_ready), .io_csrCtrl_singlestep(io_csrCtrl_singlestep),
    .io_fromCSR_illegalInst_sfenceVMA(io_fromCSR_illegalInst_sfenceVMA), .io_fromCSR_illegalInst_sfencePart(io_fromCSR_illegalInst_sfencePart), .io_fromCSR_illegalInst_hfenceGVMA(io_fromCSR_illegalInst_hfenceGVMA), .io_fromCSR_illegalInst_hfenceVVMA(io_fromCSR_illegalInst_hfenceVVMA),
    .io_fromCSR_illegalInst_hlsv(io_fromCSR_illegalInst_hlsv), .io_fromCSR_illegalInst_fsIsOff(io_fromCSR_illegalInst_fsIsOff), .io_fromCSR_illegalInst_vsIsOff(io_fromCSR_illegalInst_vsIsOff), .io_fromCSR_illegalInst_wfi(io_fromCSR_illegalInst_wfi),
    .io_fromCSR_illegalInst_wrs_nto(io_fromCSR_illegalInst_wrs_nto), .io_fromCSR_illegalInst_frm(io_fromCSR_illegalInst_frm), .io_fromCSR_illegalInst_cboZ(io_fromCSR_illegalInst_cboZ), .io_fromCSR_illegalInst_cboCF(io_fromCSR_illegalInst_cboCF),
    .io_fromCSR_illegalInst_cboI(io_fromCSR_illegalInst_cboI), .io_fromCSR_virtualInst_sfenceVMA(io_fromCSR_virtualInst_sfenceVMA), .io_fromCSR_virtualInst_sfencePart(io_fromCSR_virtualInst_sfencePart), .io_fromCSR_virtualInst_hfence(io_fromCSR_virtualInst_hfence),
    .io_fromCSR_virtualInst_hlsv(io_fromCSR_virtualInst_hlsv), .io_fromCSR_virtualInst_wfi(io_fromCSR_virtualInst_wfi), .io_fromCSR_virtualInst_wrs_nto(io_fromCSR_virtualInst_wrs_nto), .io_fromCSR_virtualInst_cboZ(io_fromCSR_virtualInst_cboZ),
    .io_fromCSR_virtualInst_cboCF(io_fromCSR_virtualInst_cboCF), .io_fromCSR_virtualInst_cboI(io_fromCSR_virtualInst_cboI), .io_fromCSR_special_cboI2F(io_fromCSR_special_cboI2F), .io_fusion_0(io_fusion_0),
    .io_fusion_1(io_fusion_1), .io_fusion_2(io_fusion_2), .io_fusion_3(io_fusion_3), .io_fusion_4(io_fusion_4),
    .io_backendCanAccept(io_backendCanAccept), .io_fromRob_isResumeVType(io_fromRob_isResumeVType), .io_fromRob_walkToArchVType(io_fromRob_walkToArchVType), .io_fromRob_commitVType_vtype_valid(io_fromRob_commitVType_vtype_valid),
    .io_fromRob_commitVType_vtype_bits_illegal(io_fromRob_commitVType_vtype_bits_illegal), .io_fromRob_commitVType_vtype_bits_vma(io_fromRob_commitVType_vtype_bits_vma), .io_fromRob_commitVType_vtype_bits_vta(io_fromRob_commitVType_vtype_bits_vta), .io_fromRob_commitVType_vtype_bits_vsew(io_fromRob_commitVType_vtype_bits_vsew),
    .io_fromRob_commitVType_vtype_bits_vlmul(io_fromRob_commitVType_vtype_bits_vlmul), .io_fromRob_commitVType_hasVsetvl(io_fromRob_commitVType_hasVsetvl), .io_fromRob_walkVType_valid(io_fromRob_walkVType_valid), .io_fromRob_walkVType_bits_illegal(io_fromRob_walkVType_bits_illegal),
    .io_fromRob_walkVType_bits_vma(io_fromRob_walkVType_bits_vma), .io_fromRob_walkVType_bits_vta(io_fromRob_walkVType_bits_vta), .io_fromRob_walkVType_bits_vsew(io_fromRob_walkVType_bits_vsew), .io_fromRob_walkVType_bits_vlmul(io_fromRob_walkVType_bits_vlmul),
    .io_stallReason_in_reason_0(io_stallReason_in_reason_0), .io_stallReason_in_reason_1(io_stallReason_in_reason_1), .io_stallReason_in_reason_2(io_stallReason_in_reason_2), .io_stallReason_in_reason_3(io_stallReason_in_reason_3),
    .io_stallReason_in_reason_4(io_stallReason_in_reason_4), .io_stallReason_in_reason_5(io_stallReason_in_reason_5), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid), .io_stallReason_out_backReason_bits(io_stallReason_out_backReason_bits),
    .io_vsetvlVType_illegal(io_vsetvlVType_illegal), .io_vsetvlVType_vma(io_vsetvlVType_vma), .io_vsetvlVType_vta(io_vsetvlVType_vta), .io_vsetvlVType_vsew(io_vsetvlVType_vsew),
    .io_vsetvlVType_vlmul(io_vsetvlVType_vlmul), .io_vstart(io_vstart), .io_in_0_ready(x_io_in_0_ready), .io_in_1_ready(x_io_in_1_ready),
    .io_in_2_ready(x_io_in_2_ready), .io_in_3_ready(x_io_in_3_ready), .io_in_4_ready(x_io_in_4_ready), .io_in_5_ready(x_io_in_5_ready),
    .io_out_0_valid(x_io_out_0_valid), .io_out_0_bits_instr(x_io_out_0_bits_instr), .io_out_0_bits_pc(x_io_out_0_bits_pc), .io_out_0_bits_foldpc(x_io_out_0_bits_foldpc),
    .io_out_0_bits_exceptionVec_0(x_io_out_0_bits_exceptionVec_0), .io_out_0_bits_exceptionVec_1(x_io_out_0_bits_exceptionVec_1), .io_out_0_bits_exceptionVec_2(x_io_out_0_bits_exceptionVec_2), .io_out_0_bits_exceptionVec_3(x_io_out_0_bits_exceptionVec_3),
    .io_out_0_bits_exceptionVec_4(x_io_out_0_bits_exceptionVec_4), .io_out_0_bits_exceptionVec_5(x_io_out_0_bits_exceptionVec_5), .io_out_0_bits_exceptionVec_6(x_io_out_0_bits_exceptionVec_6), .io_out_0_bits_exceptionVec_7(x_io_out_0_bits_exceptionVec_7),
    .io_out_0_bits_exceptionVec_8(x_io_out_0_bits_exceptionVec_8), .io_out_0_bits_exceptionVec_9(x_io_out_0_bits_exceptionVec_9), .io_out_0_bits_exceptionVec_10(x_io_out_0_bits_exceptionVec_10), .io_out_0_bits_exceptionVec_11(x_io_out_0_bits_exceptionVec_11),
    .io_out_0_bits_exceptionVec_12(x_io_out_0_bits_exceptionVec_12), .io_out_0_bits_exceptionVec_13(x_io_out_0_bits_exceptionVec_13), .io_out_0_bits_exceptionVec_14(x_io_out_0_bits_exceptionVec_14), .io_out_0_bits_exceptionVec_15(x_io_out_0_bits_exceptionVec_15),
    .io_out_0_bits_exceptionVec_16(x_io_out_0_bits_exceptionVec_16), .io_out_0_bits_exceptionVec_17(x_io_out_0_bits_exceptionVec_17), .io_out_0_bits_exceptionVec_18(x_io_out_0_bits_exceptionVec_18), .io_out_0_bits_exceptionVec_19(x_io_out_0_bits_exceptionVec_19),
    .io_out_0_bits_exceptionVec_20(x_io_out_0_bits_exceptionVec_20), .io_out_0_bits_exceptionVec_21(x_io_out_0_bits_exceptionVec_21), .io_out_0_bits_exceptionVec_22(x_io_out_0_bits_exceptionVec_22), .io_out_0_bits_exceptionVec_23(x_io_out_0_bits_exceptionVec_23),
    .io_out_0_bits_isFetchMalAddr(x_io_out_0_bits_isFetchMalAddr), .io_out_0_bits_trigger(x_io_out_0_bits_trigger), .io_out_0_bits_preDecodeInfo_valid(x_io_out_0_bits_preDecodeInfo_valid), .io_out_0_bits_preDecodeInfo_isRVC(x_io_out_0_bits_preDecodeInfo_isRVC),
    .io_out_0_bits_preDecodeInfo_brType(x_io_out_0_bits_preDecodeInfo_brType), .io_out_0_bits_preDecodeInfo_isCall(x_io_out_0_bits_preDecodeInfo_isCall), .io_out_0_bits_preDecodeInfo_isRet(x_io_out_0_bits_preDecodeInfo_isRet), .io_out_0_bits_pred_taken(x_io_out_0_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(x_io_out_0_bits_crossPageIPFFix), .io_out_0_bits_ftqPtr_flag(x_io_out_0_bits_ftqPtr_flag), .io_out_0_bits_ftqPtr_value(x_io_out_0_bits_ftqPtr_value), .io_out_0_bits_ftqOffset(x_io_out_0_bits_ftqOffset),
    .io_out_0_bits_satpFlushFirstFetchFault(x_io_out_0_bits_satpFlushFirstFetchFault), .io_out_0_bits_srcType_0(x_io_out_0_bits_srcType_0), .io_out_0_bits_srcType_1(x_io_out_0_bits_srcType_1), .io_out_0_bits_srcType_2(x_io_out_0_bits_srcType_2),
    .io_out_0_bits_srcType_3(x_io_out_0_bits_srcType_3), .io_out_0_bits_srcType_4(x_io_out_0_bits_srcType_4), .io_out_0_bits_lsrc_0(x_io_out_0_bits_lsrc_0), .io_out_0_bits_lsrc_1(x_io_out_0_bits_lsrc_1),
    .io_out_0_bits_lsrc_2(x_io_out_0_bits_lsrc_2), .io_out_0_bits_ldest(x_io_out_0_bits_ldest), .io_out_0_bits_fuType(x_io_out_0_bits_fuType), .io_out_0_bits_fuOpType(x_io_out_0_bits_fuOpType),
    .io_out_0_bits_rfWen(x_io_out_0_bits_rfWen), .io_out_0_bits_fpWen(x_io_out_0_bits_fpWen), .io_out_0_bits_vecWen(x_io_out_0_bits_vecWen), .io_out_0_bits_v0Wen(x_io_out_0_bits_v0Wen),
    .io_out_0_bits_vlWen(x_io_out_0_bits_vlWen), .io_out_0_bits_isXSTrap(x_io_out_0_bits_isXSTrap), .io_out_0_bits_waitForward(x_io_out_0_bits_waitForward), .io_out_0_bits_blockBackward(x_io_out_0_bits_blockBackward),
    .io_out_0_bits_flushPipe(x_io_out_0_bits_flushPipe), .io_out_0_bits_canRobCompress(x_io_out_0_bits_canRobCompress), .io_out_0_bits_selImm(x_io_out_0_bits_selImm), .io_out_0_bits_imm(x_io_out_0_bits_imm),
    .io_out_0_bits_fpu_typeTagOut(x_io_out_0_bits_fpu_typeTagOut), .io_out_0_bits_fpu_wflags(x_io_out_0_bits_fpu_wflags), .io_out_0_bits_fpu_typ(x_io_out_0_bits_fpu_typ), .io_out_0_bits_fpu_fmt(x_io_out_0_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm(x_io_out_0_bits_fpu_rm), .io_out_0_bits_vpu_vill(x_io_out_0_bits_vpu_vill), .io_out_0_bits_vpu_vma(x_io_out_0_bits_vpu_vma), .io_out_0_bits_vpu_vta(x_io_out_0_bits_vpu_vta),
    .io_out_0_bits_vpu_vsew(x_io_out_0_bits_vpu_vsew), .io_out_0_bits_vpu_vlmul(x_io_out_0_bits_vpu_vlmul), .io_out_0_bits_vpu_specVill(x_io_out_0_bits_vpu_specVill), .io_out_0_bits_vpu_specVma(x_io_out_0_bits_vpu_specVma),
    .io_out_0_bits_vpu_specVta(x_io_out_0_bits_vpu_specVta), .io_out_0_bits_vpu_specVsew(x_io_out_0_bits_vpu_specVsew), .io_out_0_bits_vpu_specVlmul(x_io_out_0_bits_vpu_specVlmul), .io_out_0_bits_vpu_vm(x_io_out_0_bits_vpu_vm),
    .io_out_0_bits_vpu_vstart(x_io_out_0_bits_vpu_vstart), .io_out_0_bits_vpu_fpu_isFoldTo1_2(x_io_out_0_bits_vpu_fpu_isFoldTo1_2), .io_out_0_bits_vpu_fpu_isFoldTo1_4(x_io_out_0_bits_vpu_fpu_isFoldTo1_4), .io_out_0_bits_vpu_fpu_isFoldTo1_8(x_io_out_0_bits_vpu_fpu_isFoldTo1_8),
    .io_out_0_bits_vpu_nf(x_io_out_0_bits_vpu_nf), .io_out_0_bits_vpu_veew(x_io_out_0_bits_vpu_veew), .io_out_0_bits_vpu_isReverse(x_io_out_0_bits_vpu_isReverse), .io_out_0_bits_vpu_isExt(x_io_out_0_bits_vpu_isExt),
    .io_out_0_bits_vpu_isNarrow(x_io_out_0_bits_vpu_isNarrow), .io_out_0_bits_vpu_isDstMask(x_io_out_0_bits_vpu_isDstMask), .io_out_0_bits_vpu_isOpMask(x_io_out_0_bits_vpu_isOpMask), .io_out_0_bits_vpu_isDependOldVd(x_io_out_0_bits_vpu_isDependOldVd),
    .io_out_0_bits_vpu_isWritePartVd(x_io_out_0_bits_vpu_isWritePartVd), .io_out_0_bits_vpu_isVleff(x_io_out_0_bits_vpu_isVleff), .io_out_0_bits_vlsInstr(x_io_out_0_bits_vlsInstr), .io_out_0_bits_wfflags(x_io_out_0_bits_wfflags),
    .io_out_0_bits_isMove(x_io_out_0_bits_isMove), .io_out_0_bits_uopIdx(x_io_out_0_bits_uopIdx), .io_out_0_bits_uopSplitType(x_io_out_0_bits_uopSplitType), .io_out_0_bits_isVset(x_io_out_0_bits_isVset),
    .io_out_0_bits_firstUop(x_io_out_0_bits_firstUop), .io_out_0_bits_lastUop(x_io_out_0_bits_lastUop), .io_out_0_bits_numUops(x_io_out_0_bits_numUops), .io_out_0_bits_numWB(x_io_out_0_bits_numWB),
    .io_out_0_bits_commitType(x_io_out_0_bits_commitType), .io_out_0_bits_debug_fuType(x_io_out_0_bits_debug_fuType), .io_out_0_bits_debug_seqNum_seqNum(x_io_out_0_bits_debug_seqNum_seqNum), .io_out_0_bits_debug_seqNum_uopIdx(x_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_valid(x_io_out_1_valid), .io_out_1_bits_instr(x_io_out_1_bits_instr), .io_out_1_bits_pc(x_io_out_1_bits_pc), .io_out_1_bits_foldpc(x_io_out_1_bits_foldpc),
    .io_out_1_bits_exceptionVec_0(x_io_out_1_bits_exceptionVec_0), .io_out_1_bits_exceptionVec_1(x_io_out_1_bits_exceptionVec_1), .io_out_1_bits_exceptionVec_2(x_io_out_1_bits_exceptionVec_2), .io_out_1_bits_exceptionVec_3(x_io_out_1_bits_exceptionVec_3),
    .io_out_1_bits_exceptionVec_4(x_io_out_1_bits_exceptionVec_4), .io_out_1_bits_exceptionVec_5(x_io_out_1_bits_exceptionVec_5), .io_out_1_bits_exceptionVec_6(x_io_out_1_bits_exceptionVec_6), .io_out_1_bits_exceptionVec_7(x_io_out_1_bits_exceptionVec_7),
    .io_out_1_bits_exceptionVec_8(x_io_out_1_bits_exceptionVec_8), .io_out_1_bits_exceptionVec_9(x_io_out_1_bits_exceptionVec_9), .io_out_1_bits_exceptionVec_10(x_io_out_1_bits_exceptionVec_10), .io_out_1_bits_exceptionVec_11(x_io_out_1_bits_exceptionVec_11),
    .io_out_1_bits_exceptionVec_12(x_io_out_1_bits_exceptionVec_12), .io_out_1_bits_exceptionVec_13(x_io_out_1_bits_exceptionVec_13), .io_out_1_bits_exceptionVec_14(x_io_out_1_bits_exceptionVec_14), .io_out_1_bits_exceptionVec_15(x_io_out_1_bits_exceptionVec_15),
    .io_out_1_bits_exceptionVec_16(x_io_out_1_bits_exceptionVec_16), .io_out_1_bits_exceptionVec_17(x_io_out_1_bits_exceptionVec_17), .io_out_1_bits_exceptionVec_18(x_io_out_1_bits_exceptionVec_18), .io_out_1_bits_exceptionVec_19(x_io_out_1_bits_exceptionVec_19),
    .io_out_1_bits_exceptionVec_20(x_io_out_1_bits_exceptionVec_20), .io_out_1_bits_exceptionVec_21(x_io_out_1_bits_exceptionVec_21), .io_out_1_bits_exceptionVec_22(x_io_out_1_bits_exceptionVec_22), .io_out_1_bits_exceptionVec_23(x_io_out_1_bits_exceptionVec_23),
    .io_out_1_bits_isFetchMalAddr(x_io_out_1_bits_isFetchMalAddr), .io_out_1_bits_trigger(x_io_out_1_bits_trigger), .io_out_1_bits_preDecodeInfo_valid(x_io_out_1_bits_preDecodeInfo_valid), .io_out_1_bits_preDecodeInfo_isRVC(x_io_out_1_bits_preDecodeInfo_isRVC),
    .io_out_1_bits_preDecodeInfo_brType(x_io_out_1_bits_preDecodeInfo_brType), .io_out_1_bits_preDecodeInfo_isCall(x_io_out_1_bits_preDecodeInfo_isCall), .io_out_1_bits_preDecodeInfo_isRet(x_io_out_1_bits_preDecodeInfo_isRet), .io_out_1_bits_pred_taken(x_io_out_1_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(x_io_out_1_bits_crossPageIPFFix), .io_out_1_bits_ftqPtr_flag(x_io_out_1_bits_ftqPtr_flag), .io_out_1_bits_ftqPtr_value(x_io_out_1_bits_ftqPtr_value), .io_out_1_bits_ftqOffset(x_io_out_1_bits_ftqOffset),
    .io_out_1_bits_satpFlushFirstFetchFault(x_io_out_1_bits_satpFlushFirstFetchFault), .io_out_1_bits_srcType_0(x_io_out_1_bits_srcType_0), .io_out_1_bits_srcType_1(x_io_out_1_bits_srcType_1), .io_out_1_bits_srcType_2(x_io_out_1_bits_srcType_2),
    .io_out_1_bits_srcType_3(x_io_out_1_bits_srcType_3), .io_out_1_bits_srcType_4(x_io_out_1_bits_srcType_4), .io_out_1_bits_lsrc_0(x_io_out_1_bits_lsrc_0), .io_out_1_bits_lsrc_1(x_io_out_1_bits_lsrc_1),
    .io_out_1_bits_lsrc_2(x_io_out_1_bits_lsrc_2), .io_out_1_bits_ldest(x_io_out_1_bits_ldest), .io_out_1_bits_fuType(x_io_out_1_bits_fuType), .io_out_1_bits_fuOpType(x_io_out_1_bits_fuOpType),
    .io_out_1_bits_rfWen(x_io_out_1_bits_rfWen), .io_out_1_bits_fpWen(x_io_out_1_bits_fpWen), .io_out_1_bits_vecWen(x_io_out_1_bits_vecWen), .io_out_1_bits_v0Wen(x_io_out_1_bits_v0Wen),
    .io_out_1_bits_vlWen(x_io_out_1_bits_vlWen), .io_out_1_bits_isXSTrap(x_io_out_1_bits_isXSTrap), .io_out_1_bits_waitForward(x_io_out_1_bits_waitForward), .io_out_1_bits_blockBackward(x_io_out_1_bits_blockBackward),
    .io_out_1_bits_flushPipe(x_io_out_1_bits_flushPipe), .io_out_1_bits_canRobCompress(x_io_out_1_bits_canRobCompress), .io_out_1_bits_selImm(x_io_out_1_bits_selImm), .io_out_1_bits_imm(x_io_out_1_bits_imm),
    .io_out_1_bits_fpu_typeTagOut(x_io_out_1_bits_fpu_typeTagOut), .io_out_1_bits_fpu_wflags(x_io_out_1_bits_fpu_wflags), .io_out_1_bits_fpu_typ(x_io_out_1_bits_fpu_typ), .io_out_1_bits_fpu_fmt(x_io_out_1_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm(x_io_out_1_bits_fpu_rm), .io_out_1_bits_vpu_vill(x_io_out_1_bits_vpu_vill), .io_out_1_bits_vpu_vma(x_io_out_1_bits_vpu_vma), .io_out_1_bits_vpu_vta(x_io_out_1_bits_vpu_vta),
    .io_out_1_bits_vpu_vsew(x_io_out_1_bits_vpu_vsew), .io_out_1_bits_vpu_vlmul(x_io_out_1_bits_vpu_vlmul), .io_out_1_bits_vpu_specVill(x_io_out_1_bits_vpu_specVill), .io_out_1_bits_vpu_specVma(x_io_out_1_bits_vpu_specVma),
    .io_out_1_bits_vpu_specVta(x_io_out_1_bits_vpu_specVta), .io_out_1_bits_vpu_specVsew(x_io_out_1_bits_vpu_specVsew), .io_out_1_bits_vpu_specVlmul(x_io_out_1_bits_vpu_specVlmul), .io_out_1_bits_vpu_vm(x_io_out_1_bits_vpu_vm),
    .io_out_1_bits_vpu_vstart(x_io_out_1_bits_vpu_vstart), .io_out_1_bits_vpu_fpu_isFoldTo1_2(x_io_out_1_bits_vpu_fpu_isFoldTo1_2), .io_out_1_bits_vpu_fpu_isFoldTo1_4(x_io_out_1_bits_vpu_fpu_isFoldTo1_4), .io_out_1_bits_vpu_fpu_isFoldTo1_8(x_io_out_1_bits_vpu_fpu_isFoldTo1_8),
    .io_out_1_bits_vpu_nf(x_io_out_1_bits_vpu_nf), .io_out_1_bits_vpu_veew(x_io_out_1_bits_vpu_veew), .io_out_1_bits_vpu_isReverse(x_io_out_1_bits_vpu_isReverse), .io_out_1_bits_vpu_isExt(x_io_out_1_bits_vpu_isExt),
    .io_out_1_bits_vpu_isNarrow(x_io_out_1_bits_vpu_isNarrow), .io_out_1_bits_vpu_isDstMask(x_io_out_1_bits_vpu_isDstMask), .io_out_1_bits_vpu_isOpMask(x_io_out_1_bits_vpu_isOpMask), .io_out_1_bits_vpu_isDependOldVd(x_io_out_1_bits_vpu_isDependOldVd),
    .io_out_1_bits_vpu_isWritePartVd(x_io_out_1_bits_vpu_isWritePartVd), .io_out_1_bits_vpu_isVleff(x_io_out_1_bits_vpu_isVleff), .io_out_1_bits_vlsInstr(x_io_out_1_bits_vlsInstr), .io_out_1_bits_wfflags(x_io_out_1_bits_wfflags),
    .io_out_1_bits_isMove(x_io_out_1_bits_isMove), .io_out_1_bits_uopIdx(x_io_out_1_bits_uopIdx), .io_out_1_bits_uopSplitType(x_io_out_1_bits_uopSplitType), .io_out_1_bits_isVset(x_io_out_1_bits_isVset),
    .io_out_1_bits_firstUop(x_io_out_1_bits_firstUop), .io_out_1_bits_lastUop(x_io_out_1_bits_lastUop), .io_out_1_bits_numUops(x_io_out_1_bits_numUops), .io_out_1_bits_numWB(x_io_out_1_bits_numWB),
    .io_out_1_bits_commitType(x_io_out_1_bits_commitType), .io_out_1_bits_debug_fuType(x_io_out_1_bits_debug_fuType), .io_out_1_bits_debug_seqNum_seqNum(x_io_out_1_bits_debug_seqNum_seqNum), .io_out_1_bits_debug_seqNum_uopIdx(x_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_valid(x_io_out_2_valid), .io_out_2_bits_instr(x_io_out_2_bits_instr), .io_out_2_bits_pc(x_io_out_2_bits_pc), .io_out_2_bits_foldpc(x_io_out_2_bits_foldpc),
    .io_out_2_bits_exceptionVec_0(x_io_out_2_bits_exceptionVec_0), .io_out_2_bits_exceptionVec_1(x_io_out_2_bits_exceptionVec_1), .io_out_2_bits_exceptionVec_2(x_io_out_2_bits_exceptionVec_2), .io_out_2_bits_exceptionVec_3(x_io_out_2_bits_exceptionVec_3),
    .io_out_2_bits_exceptionVec_4(x_io_out_2_bits_exceptionVec_4), .io_out_2_bits_exceptionVec_5(x_io_out_2_bits_exceptionVec_5), .io_out_2_bits_exceptionVec_6(x_io_out_2_bits_exceptionVec_6), .io_out_2_bits_exceptionVec_7(x_io_out_2_bits_exceptionVec_7),
    .io_out_2_bits_exceptionVec_8(x_io_out_2_bits_exceptionVec_8), .io_out_2_bits_exceptionVec_9(x_io_out_2_bits_exceptionVec_9), .io_out_2_bits_exceptionVec_10(x_io_out_2_bits_exceptionVec_10), .io_out_2_bits_exceptionVec_11(x_io_out_2_bits_exceptionVec_11),
    .io_out_2_bits_exceptionVec_12(x_io_out_2_bits_exceptionVec_12), .io_out_2_bits_exceptionVec_13(x_io_out_2_bits_exceptionVec_13), .io_out_2_bits_exceptionVec_14(x_io_out_2_bits_exceptionVec_14), .io_out_2_bits_exceptionVec_15(x_io_out_2_bits_exceptionVec_15),
    .io_out_2_bits_exceptionVec_16(x_io_out_2_bits_exceptionVec_16), .io_out_2_bits_exceptionVec_17(x_io_out_2_bits_exceptionVec_17), .io_out_2_bits_exceptionVec_18(x_io_out_2_bits_exceptionVec_18), .io_out_2_bits_exceptionVec_19(x_io_out_2_bits_exceptionVec_19),
    .io_out_2_bits_exceptionVec_20(x_io_out_2_bits_exceptionVec_20), .io_out_2_bits_exceptionVec_21(x_io_out_2_bits_exceptionVec_21), .io_out_2_bits_exceptionVec_22(x_io_out_2_bits_exceptionVec_22), .io_out_2_bits_exceptionVec_23(x_io_out_2_bits_exceptionVec_23),
    .io_out_2_bits_isFetchMalAddr(x_io_out_2_bits_isFetchMalAddr), .io_out_2_bits_trigger(x_io_out_2_bits_trigger), .io_out_2_bits_preDecodeInfo_valid(x_io_out_2_bits_preDecodeInfo_valid), .io_out_2_bits_preDecodeInfo_isRVC(x_io_out_2_bits_preDecodeInfo_isRVC),
    .io_out_2_bits_preDecodeInfo_brType(x_io_out_2_bits_preDecodeInfo_brType), .io_out_2_bits_preDecodeInfo_isCall(x_io_out_2_bits_preDecodeInfo_isCall), .io_out_2_bits_preDecodeInfo_isRet(x_io_out_2_bits_preDecodeInfo_isRet), .io_out_2_bits_pred_taken(x_io_out_2_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(x_io_out_2_bits_crossPageIPFFix), .io_out_2_bits_ftqPtr_flag(x_io_out_2_bits_ftqPtr_flag), .io_out_2_bits_ftqPtr_value(x_io_out_2_bits_ftqPtr_value), .io_out_2_bits_ftqOffset(x_io_out_2_bits_ftqOffset),
    .io_out_2_bits_satpFlushFirstFetchFault(x_io_out_2_bits_satpFlushFirstFetchFault), .io_out_2_bits_srcType_0(x_io_out_2_bits_srcType_0), .io_out_2_bits_srcType_1(x_io_out_2_bits_srcType_1), .io_out_2_bits_srcType_2(x_io_out_2_bits_srcType_2),
    .io_out_2_bits_srcType_3(x_io_out_2_bits_srcType_3), .io_out_2_bits_srcType_4(x_io_out_2_bits_srcType_4), .io_out_2_bits_lsrc_0(x_io_out_2_bits_lsrc_0), .io_out_2_bits_lsrc_1(x_io_out_2_bits_lsrc_1),
    .io_out_2_bits_lsrc_2(x_io_out_2_bits_lsrc_2), .io_out_2_bits_ldest(x_io_out_2_bits_ldest), .io_out_2_bits_fuType(x_io_out_2_bits_fuType), .io_out_2_bits_fuOpType(x_io_out_2_bits_fuOpType),
    .io_out_2_bits_rfWen(x_io_out_2_bits_rfWen), .io_out_2_bits_fpWen(x_io_out_2_bits_fpWen), .io_out_2_bits_vecWen(x_io_out_2_bits_vecWen), .io_out_2_bits_v0Wen(x_io_out_2_bits_v0Wen),
    .io_out_2_bits_vlWen(x_io_out_2_bits_vlWen), .io_out_2_bits_isXSTrap(x_io_out_2_bits_isXSTrap), .io_out_2_bits_waitForward(x_io_out_2_bits_waitForward), .io_out_2_bits_blockBackward(x_io_out_2_bits_blockBackward),
    .io_out_2_bits_flushPipe(x_io_out_2_bits_flushPipe), .io_out_2_bits_canRobCompress(x_io_out_2_bits_canRobCompress), .io_out_2_bits_selImm(x_io_out_2_bits_selImm), .io_out_2_bits_imm(x_io_out_2_bits_imm),
    .io_out_2_bits_fpu_typeTagOut(x_io_out_2_bits_fpu_typeTagOut), .io_out_2_bits_fpu_wflags(x_io_out_2_bits_fpu_wflags), .io_out_2_bits_fpu_typ(x_io_out_2_bits_fpu_typ), .io_out_2_bits_fpu_fmt(x_io_out_2_bits_fpu_fmt),
    .io_out_2_bits_fpu_rm(x_io_out_2_bits_fpu_rm), .io_out_2_bits_vpu_vill(x_io_out_2_bits_vpu_vill), .io_out_2_bits_vpu_vma(x_io_out_2_bits_vpu_vma), .io_out_2_bits_vpu_vta(x_io_out_2_bits_vpu_vta),
    .io_out_2_bits_vpu_vsew(x_io_out_2_bits_vpu_vsew), .io_out_2_bits_vpu_vlmul(x_io_out_2_bits_vpu_vlmul), .io_out_2_bits_vpu_specVill(x_io_out_2_bits_vpu_specVill), .io_out_2_bits_vpu_specVma(x_io_out_2_bits_vpu_specVma),
    .io_out_2_bits_vpu_specVta(x_io_out_2_bits_vpu_specVta), .io_out_2_bits_vpu_specVsew(x_io_out_2_bits_vpu_specVsew), .io_out_2_bits_vpu_specVlmul(x_io_out_2_bits_vpu_specVlmul), .io_out_2_bits_vpu_vm(x_io_out_2_bits_vpu_vm),
    .io_out_2_bits_vpu_vstart(x_io_out_2_bits_vpu_vstart), .io_out_2_bits_vpu_fpu_isFoldTo1_2(x_io_out_2_bits_vpu_fpu_isFoldTo1_2), .io_out_2_bits_vpu_fpu_isFoldTo1_4(x_io_out_2_bits_vpu_fpu_isFoldTo1_4), .io_out_2_bits_vpu_fpu_isFoldTo1_8(x_io_out_2_bits_vpu_fpu_isFoldTo1_8),
    .io_out_2_bits_vpu_nf(x_io_out_2_bits_vpu_nf), .io_out_2_bits_vpu_veew(x_io_out_2_bits_vpu_veew), .io_out_2_bits_vpu_isReverse(x_io_out_2_bits_vpu_isReverse), .io_out_2_bits_vpu_isExt(x_io_out_2_bits_vpu_isExt),
    .io_out_2_bits_vpu_isNarrow(x_io_out_2_bits_vpu_isNarrow), .io_out_2_bits_vpu_isDstMask(x_io_out_2_bits_vpu_isDstMask), .io_out_2_bits_vpu_isOpMask(x_io_out_2_bits_vpu_isOpMask), .io_out_2_bits_vpu_isDependOldVd(x_io_out_2_bits_vpu_isDependOldVd),
    .io_out_2_bits_vpu_isWritePartVd(x_io_out_2_bits_vpu_isWritePartVd), .io_out_2_bits_vpu_isVleff(x_io_out_2_bits_vpu_isVleff), .io_out_2_bits_vlsInstr(x_io_out_2_bits_vlsInstr), .io_out_2_bits_wfflags(x_io_out_2_bits_wfflags),
    .io_out_2_bits_isMove(x_io_out_2_bits_isMove), .io_out_2_bits_uopIdx(x_io_out_2_bits_uopIdx), .io_out_2_bits_uopSplitType(x_io_out_2_bits_uopSplitType), .io_out_2_bits_isVset(x_io_out_2_bits_isVset),
    .io_out_2_bits_firstUop(x_io_out_2_bits_firstUop), .io_out_2_bits_lastUop(x_io_out_2_bits_lastUop), .io_out_2_bits_numUops(x_io_out_2_bits_numUops), .io_out_2_bits_numWB(x_io_out_2_bits_numWB),
    .io_out_2_bits_commitType(x_io_out_2_bits_commitType), .io_out_2_bits_debug_fuType(x_io_out_2_bits_debug_fuType), .io_out_2_bits_debug_seqNum_seqNum(x_io_out_2_bits_debug_seqNum_seqNum), .io_out_2_bits_debug_seqNum_uopIdx(x_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_valid(x_io_out_3_valid), .io_out_3_bits_instr(x_io_out_3_bits_instr), .io_out_3_bits_pc(x_io_out_3_bits_pc), .io_out_3_bits_foldpc(x_io_out_3_bits_foldpc),
    .io_out_3_bits_exceptionVec_0(x_io_out_3_bits_exceptionVec_0), .io_out_3_bits_exceptionVec_1(x_io_out_3_bits_exceptionVec_1), .io_out_3_bits_exceptionVec_2(x_io_out_3_bits_exceptionVec_2), .io_out_3_bits_exceptionVec_3(x_io_out_3_bits_exceptionVec_3),
    .io_out_3_bits_exceptionVec_4(x_io_out_3_bits_exceptionVec_4), .io_out_3_bits_exceptionVec_5(x_io_out_3_bits_exceptionVec_5), .io_out_3_bits_exceptionVec_6(x_io_out_3_bits_exceptionVec_6), .io_out_3_bits_exceptionVec_7(x_io_out_3_bits_exceptionVec_7),
    .io_out_3_bits_exceptionVec_8(x_io_out_3_bits_exceptionVec_8), .io_out_3_bits_exceptionVec_9(x_io_out_3_bits_exceptionVec_9), .io_out_3_bits_exceptionVec_10(x_io_out_3_bits_exceptionVec_10), .io_out_3_bits_exceptionVec_11(x_io_out_3_bits_exceptionVec_11),
    .io_out_3_bits_exceptionVec_12(x_io_out_3_bits_exceptionVec_12), .io_out_3_bits_exceptionVec_13(x_io_out_3_bits_exceptionVec_13), .io_out_3_bits_exceptionVec_14(x_io_out_3_bits_exceptionVec_14), .io_out_3_bits_exceptionVec_15(x_io_out_3_bits_exceptionVec_15),
    .io_out_3_bits_exceptionVec_16(x_io_out_3_bits_exceptionVec_16), .io_out_3_bits_exceptionVec_17(x_io_out_3_bits_exceptionVec_17), .io_out_3_bits_exceptionVec_18(x_io_out_3_bits_exceptionVec_18), .io_out_3_bits_exceptionVec_19(x_io_out_3_bits_exceptionVec_19),
    .io_out_3_bits_exceptionVec_20(x_io_out_3_bits_exceptionVec_20), .io_out_3_bits_exceptionVec_21(x_io_out_3_bits_exceptionVec_21), .io_out_3_bits_exceptionVec_22(x_io_out_3_bits_exceptionVec_22), .io_out_3_bits_exceptionVec_23(x_io_out_3_bits_exceptionVec_23),
    .io_out_3_bits_isFetchMalAddr(x_io_out_3_bits_isFetchMalAddr), .io_out_3_bits_trigger(x_io_out_3_bits_trigger), .io_out_3_bits_preDecodeInfo_valid(x_io_out_3_bits_preDecodeInfo_valid), .io_out_3_bits_preDecodeInfo_isRVC(x_io_out_3_bits_preDecodeInfo_isRVC),
    .io_out_3_bits_preDecodeInfo_brType(x_io_out_3_bits_preDecodeInfo_brType), .io_out_3_bits_preDecodeInfo_isCall(x_io_out_3_bits_preDecodeInfo_isCall), .io_out_3_bits_preDecodeInfo_isRet(x_io_out_3_bits_preDecodeInfo_isRet), .io_out_3_bits_pred_taken(x_io_out_3_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(x_io_out_3_bits_crossPageIPFFix), .io_out_3_bits_ftqPtr_flag(x_io_out_3_bits_ftqPtr_flag), .io_out_3_bits_ftqPtr_value(x_io_out_3_bits_ftqPtr_value), .io_out_3_bits_ftqOffset(x_io_out_3_bits_ftqOffset),
    .io_out_3_bits_satpFlushFirstFetchFault(x_io_out_3_bits_satpFlushFirstFetchFault), .io_out_3_bits_srcType_0(x_io_out_3_bits_srcType_0), .io_out_3_bits_srcType_1(x_io_out_3_bits_srcType_1), .io_out_3_bits_srcType_2(x_io_out_3_bits_srcType_2),
    .io_out_3_bits_srcType_3(x_io_out_3_bits_srcType_3), .io_out_3_bits_srcType_4(x_io_out_3_bits_srcType_4), .io_out_3_bits_lsrc_0(x_io_out_3_bits_lsrc_0), .io_out_3_bits_lsrc_1(x_io_out_3_bits_lsrc_1),
    .io_out_3_bits_lsrc_2(x_io_out_3_bits_lsrc_2), .io_out_3_bits_ldest(x_io_out_3_bits_ldest), .io_out_3_bits_fuType(x_io_out_3_bits_fuType), .io_out_3_bits_fuOpType(x_io_out_3_bits_fuOpType),
    .io_out_3_bits_rfWen(x_io_out_3_bits_rfWen), .io_out_3_bits_fpWen(x_io_out_3_bits_fpWen), .io_out_3_bits_vecWen(x_io_out_3_bits_vecWen), .io_out_3_bits_v0Wen(x_io_out_3_bits_v0Wen),
    .io_out_3_bits_vlWen(x_io_out_3_bits_vlWen), .io_out_3_bits_isXSTrap(x_io_out_3_bits_isXSTrap), .io_out_3_bits_waitForward(x_io_out_3_bits_waitForward), .io_out_3_bits_blockBackward(x_io_out_3_bits_blockBackward),
    .io_out_3_bits_flushPipe(x_io_out_3_bits_flushPipe), .io_out_3_bits_canRobCompress(x_io_out_3_bits_canRobCompress), .io_out_3_bits_selImm(x_io_out_3_bits_selImm), .io_out_3_bits_imm(x_io_out_3_bits_imm),
    .io_out_3_bits_fpu_typeTagOut(x_io_out_3_bits_fpu_typeTagOut), .io_out_3_bits_fpu_wflags(x_io_out_3_bits_fpu_wflags), .io_out_3_bits_fpu_typ(x_io_out_3_bits_fpu_typ), .io_out_3_bits_fpu_fmt(x_io_out_3_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm(x_io_out_3_bits_fpu_rm), .io_out_3_bits_vpu_vill(x_io_out_3_bits_vpu_vill), .io_out_3_bits_vpu_vma(x_io_out_3_bits_vpu_vma), .io_out_3_bits_vpu_vta(x_io_out_3_bits_vpu_vta),
    .io_out_3_bits_vpu_vsew(x_io_out_3_bits_vpu_vsew), .io_out_3_bits_vpu_vlmul(x_io_out_3_bits_vpu_vlmul), .io_out_3_bits_vpu_specVill(x_io_out_3_bits_vpu_specVill), .io_out_3_bits_vpu_specVma(x_io_out_3_bits_vpu_specVma),
    .io_out_3_bits_vpu_specVta(x_io_out_3_bits_vpu_specVta), .io_out_3_bits_vpu_specVsew(x_io_out_3_bits_vpu_specVsew), .io_out_3_bits_vpu_specVlmul(x_io_out_3_bits_vpu_specVlmul), .io_out_3_bits_vpu_vm(x_io_out_3_bits_vpu_vm),
    .io_out_3_bits_vpu_vstart(x_io_out_3_bits_vpu_vstart), .io_out_3_bits_vpu_fpu_isFoldTo1_2(x_io_out_3_bits_vpu_fpu_isFoldTo1_2), .io_out_3_bits_vpu_fpu_isFoldTo1_4(x_io_out_3_bits_vpu_fpu_isFoldTo1_4), .io_out_3_bits_vpu_fpu_isFoldTo1_8(x_io_out_3_bits_vpu_fpu_isFoldTo1_8),
    .io_out_3_bits_vpu_nf(x_io_out_3_bits_vpu_nf), .io_out_3_bits_vpu_veew(x_io_out_3_bits_vpu_veew), .io_out_3_bits_vpu_isReverse(x_io_out_3_bits_vpu_isReverse), .io_out_3_bits_vpu_isExt(x_io_out_3_bits_vpu_isExt),
    .io_out_3_bits_vpu_isNarrow(x_io_out_3_bits_vpu_isNarrow), .io_out_3_bits_vpu_isDstMask(x_io_out_3_bits_vpu_isDstMask), .io_out_3_bits_vpu_isOpMask(x_io_out_3_bits_vpu_isOpMask), .io_out_3_bits_vpu_isDependOldVd(x_io_out_3_bits_vpu_isDependOldVd),
    .io_out_3_bits_vpu_isWritePartVd(x_io_out_3_bits_vpu_isWritePartVd), .io_out_3_bits_vpu_isVleff(x_io_out_3_bits_vpu_isVleff), .io_out_3_bits_vlsInstr(x_io_out_3_bits_vlsInstr), .io_out_3_bits_wfflags(x_io_out_3_bits_wfflags),
    .io_out_3_bits_isMove(x_io_out_3_bits_isMove), .io_out_3_bits_uopIdx(x_io_out_3_bits_uopIdx), .io_out_3_bits_uopSplitType(x_io_out_3_bits_uopSplitType), .io_out_3_bits_isVset(x_io_out_3_bits_isVset),
    .io_out_3_bits_firstUop(x_io_out_3_bits_firstUop), .io_out_3_bits_lastUop(x_io_out_3_bits_lastUop), .io_out_3_bits_numUops(x_io_out_3_bits_numUops), .io_out_3_bits_numWB(x_io_out_3_bits_numWB),
    .io_out_3_bits_commitType(x_io_out_3_bits_commitType), .io_out_3_bits_debug_fuType(x_io_out_3_bits_debug_fuType), .io_out_3_bits_debug_seqNum_seqNum(x_io_out_3_bits_debug_seqNum_seqNum), .io_out_3_bits_debug_seqNum_uopIdx(x_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_4_valid(x_io_out_4_valid), .io_out_4_bits_instr(x_io_out_4_bits_instr), .io_out_4_bits_pc(x_io_out_4_bits_pc), .io_out_4_bits_foldpc(x_io_out_4_bits_foldpc),
    .io_out_4_bits_exceptionVec_0(x_io_out_4_bits_exceptionVec_0), .io_out_4_bits_exceptionVec_1(x_io_out_4_bits_exceptionVec_1), .io_out_4_bits_exceptionVec_2(x_io_out_4_bits_exceptionVec_2), .io_out_4_bits_exceptionVec_3(x_io_out_4_bits_exceptionVec_3),
    .io_out_4_bits_exceptionVec_4(x_io_out_4_bits_exceptionVec_4), .io_out_4_bits_exceptionVec_5(x_io_out_4_bits_exceptionVec_5), .io_out_4_bits_exceptionVec_6(x_io_out_4_bits_exceptionVec_6), .io_out_4_bits_exceptionVec_7(x_io_out_4_bits_exceptionVec_7),
    .io_out_4_bits_exceptionVec_8(x_io_out_4_bits_exceptionVec_8), .io_out_4_bits_exceptionVec_9(x_io_out_4_bits_exceptionVec_9), .io_out_4_bits_exceptionVec_10(x_io_out_4_bits_exceptionVec_10), .io_out_4_bits_exceptionVec_11(x_io_out_4_bits_exceptionVec_11),
    .io_out_4_bits_exceptionVec_12(x_io_out_4_bits_exceptionVec_12), .io_out_4_bits_exceptionVec_13(x_io_out_4_bits_exceptionVec_13), .io_out_4_bits_exceptionVec_14(x_io_out_4_bits_exceptionVec_14), .io_out_4_bits_exceptionVec_15(x_io_out_4_bits_exceptionVec_15),
    .io_out_4_bits_exceptionVec_16(x_io_out_4_bits_exceptionVec_16), .io_out_4_bits_exceptionVec_17(x_io_out_4_bits_exceptionVec_17), .io_out_4_bits_exceptionVec_18(x_io_out_4_bits_exceptionVec_18), .io_out_4_bits_exceptionVec_19(x_io_out_4_bits_exceptionVec_19),
    .io_out_4_bits_exceptionVec_20(x_io_out_4_bits_exceptionVec_20), .io_out_4_bits_exceptionVec_21(x_io_out_4_bits_exceptionVec_21), .io_out_4_bits_exceptionVec_22(x_io_out_4_bits_exceptionVec_22), .io_out_4_bits_exceptionVec_23(x_io_out_4_bits_exceptionVec_23),
    .io_out_4_bits_isFetchMalAddr(x_io_out_4_bits_isFetchMalAddr), .io_out_4_bits_trigger(x_io_out_4_bits_trigger), .io_out_4_bits_preDecodeInfo_valid(x_io_out_4_bits_preDecodeInfo_valid), .io_out_4_bits_preDecodeInfo_isRVC(x_io_out_4_bits_preDecodeInfo_isRVC),
    .io_out_4_bits_preDecodeInfo_brType(x_io_out_4_bits_preDecodeInfo_brType), .io_out_4_bits_preDecodeInfo_isCall(x_io_out_4_bits_preDecodeInfo_isCall), .io_out_4_bits_preDecodeInfo_isRet(x_io_out_4_bits_preDecodeInfo_isRet), .io_out_4_bits_pred_taken(x_io_out_4_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(x_io_out_4_bits_crossPageIPFFix), .io_out_4_bits_ftqPtr_flag(x_io_out_4_bits_ftqPtr_flag), .io_out_4_bits_ftqPtr_value(x_io_out_4_bits_ftqPtr_value), .io_out_4_bits_ftqOffset(x_io_out_4_bits_ftqOffset),
    .io_out_4_bits_satpFlushFirstFetchFault(x_io_out_4_bits_satpFlushFirstFetchFault), .io_out_4_bits_srcType_0(x_io_out_4_bits_srcType_0), .io_out_4_bits_srcType_1(x_io_out_4_bits_srcType_1), .io_out_4_bits_srcType_2(x_io_out_4_bits_srcType_2),
    .io_out_4_bits_srcType_3(x_io_out_4_bits_srcType_3), .io_out_4_bits_srcType_4(x_io_out_4_bits_srcType_4), .io_out_4_bits_lsrc_0(x_io_out_4_bits_lsrc_0), .io_out_4_bits_lsrc_1(x_io_out_4_bits_lsrc_1),
    .io_out_4_bits_lsrc_2(x_io_out_4_bits_lsrc_2), .io_out_4_bits_ldest(x_io_out_4_bits_ldest), .io_out_4_bits_fuType(x_io_out_4_bits_fuType), .io_out_4_bits_fuOpType(x_io_out_4_bits_fuOpType),
    .io_out_4_bits_rfWen(x_io_out_4_bits_rfWen), .io_out_4_bits_fpWen(x_io_out_4_bits_fpWen), .io_out_4_bits_vecWen(x_io_out_4_bits_vecWen), .io_out_4_bits_v0Wen(x_io_out_4_bits_v0Wen),
    .io_out_4_bits_vlWen(x_io_out_4_bits_vlWen), .io_out_4_bits_isXSTrap(x_io_out_4_bits_isXSTrap), .io_out_4_bits_waitForward(x_io_out_4_bits_waitForward), .io_out_4_bits_blockBackward(x_io_out_4_bits_blockBackward),
    .io_out_4_bits_flushPipe(x_io_out_4_bits_flushPipe), .io_out_4_bits_canRobCompress(x_io_out_4_bits_canRobCompress), .io_out_4_bits_selImm(x_io_out_4_bits_selImm), .io_out_4_bits_imm(x_io_out_4_bits_imm),
    .io_out_4_bits_fpu_typeTagOut(x_io_out_4_bits_fpu_typeTagOut), .io_out_4_bits_fpu_wflags(x_io_out_4_bits_fpu_wflags), .io_out_4_bits_fpu_typ(x_io_out_4_bits_fpu_typ), .io_out_4_bits_fpu_fmt(x_io_out_4_bits_fpu_fmt),
    .io_out_4_bits_fpu_rm(x_io_out_4_bits_fpu_rm), .io_out_4_bits_vpu_vill(x_io_out_4_bits_vpu_vill), .io_out_4_bits_vpu_vma(x_io_out_4_bits_vpu_vma), .io_out_4_bits_vpu_vta(x_io_out_4_bits_vpu_vta),
    .io_out_4_bits_vpu_vsew(x_io_out_4_bits_vpu_vsew), .io_out_4_bits_vpu_vlmul(x_io_out_4_bits_vpu_vlmul), .io_out_4_bits_vpu_specVill(x_io_out_4_bits_vpu_specVill), .io_out_4_bits_vpu_specVma(x_io_out_4_bits_vpu_specVma),
    .io_out_4_bits_vpu_specVta(x_io_out_4_bits_vpu_specVta), .io_out_4_bits_vpu_specVsew(x_io_out_4_bits_vpu_specVsew), .io_out_4_bits_vpu_specVlmul(x_io_out_4_bits_vpu_specVlmul), .io_out_4_bits_vpu_vm(x_io_out_4_bits_vpu_vm),
    .io_out_4_bits_vpu_vstart(x_io_out_4_bits_vpu_vstart), .io_out_4_bits_vpu_fpu_isFoldTo1_2(x_io_out_4_bits_vpu_fpu_isFoldTo1_2), .io_out_4_bits_vpu_fpu_isFoldTo1_4(x_io_out_4_bits_vpu_fpu_isFoldTo1_4), .io_out_4_bits_vpu_fpu_isFoldTo1_8(x_io_out_4_bits_vpu_fpu_isFoldTo1_8),
    .io_out_4_bits_vpu_nf(x_io_out_4_bits_vpu_nf), .io_out_4_bits_vpu_veew(x_io_out_4_bits_vpu_veew), .io_out_4_bits_vpu_isReverse(x_io_out_4_bits_vpu_isReverse), .io_out_4_bits_vpu_isExt(x_io_out_4_bits_vpu_isExt),
    .io_out_4_bits_vpu_isNarrow(x_io_out_4_bits_vpu_isNarrow), .io_out_4_bits_vpu_isDstMask(x_io_out_4_bits_vpu_isDstMask), .io_out_4_bits_vpu_isOpMask(x_io_out_4_bits_vpu_isOpMask), .io_out_4_bits_vpu_isDependOldVd(x_io_out_4_bits_vpu_isDependOldVd),
    .io_out_4_bits_vpu_isWritePartVd(x_io_out_4_bits_vpu_isWritePartVd), .io_out_4_bits_vpu_isVleff(x_io_out_4_bits_vpu_isVleff), .io_out_4_bits_vlsInstr(x_io_out_4_bits_vlsInstr), .io_out_4_bits_wfflags(x_io_out_4_bits_wfflags),
    .io_out_4_bits_isMove(x_io_out_4_bits_isMove), .io_out_4_bits_uopIdx(x_io_out_4_bits_uopIdx), .io_out_4_bits_uopSplitType(x_io_out_4_bits_uopSplitType), .io_out_4_bits_isVset(x_io_out_4_bits_isVset),
    .io_out_4_bits_firstUop(x_io_out_4_bits_firstUop), .io_out_4_bits_lastUop(x_io_out_4_bits_lastUop), .io_out_4_bits_numUops(x_io_out_4_bits_numUops), .io_out_4_bits_numWB(x_io_out_4_bits_numWB),
    .io_out_4_bits_commitType(x_io_out_4_bits_commitType), .io_out_4_bits_debug_fuType(x_io_out_4_bits_debug_fuType), .io_out_4_bits_debug_seqNum_seqNum(x_io_out_4_bits_debug_seqNum_seqNum), .io_out_4_bits_debug_seqNum_uopIdx(x_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_5_valid(x_io_out_5_valid), .io_out_5_bits_instr(x_io_out_5_bits_instr), .io_out_5_bits_pc(x_io_out_5_bits_pc), .io_out_5_bits_foldpc(x_io_out_5_bits_foldpc),
    .io_out_5_bits_exceptionVec_0(x_io_out_5_bits_exceptionVec_0), .io_out_5_bits_exceptionVec_1(x_io_out_5_bits_exceptionVec_1), .io_out_5_bits_exceptionVec_2(x_io_out_5_bits_exceptionVec_2), .io_out_5_bits_exceptionVec_3(x_io_out_5_bits_exceptionVec_3),
    .io_out_5_bits_exceptionVec_4(x_io_out_5_bits_exceptionVec_4), .io_out_5_bits_exceptionVec_5(x_io_out_5_bits_exceptionVec_5), .io_out_5_bits_exceptionVec_6(x_io_out_5_bits_exceptionVec_6), .io_out_5_bits_exceptionVec_7(x_io_out_5_bits_exceptionVec_7),
    .io_out_5_bits_exceptionVec_8(x_io_out_5_bits_exceptionVec_8), .io_out_5_bits_exceptionVec_9(x_io_out_5_bits_exceptionVec_9), .io_out_5_bits_exceptionVec_10(x_io_out_5_bits_exceptionVec_10), .io_out_5_bits_exceptionVec_11(x_io_out_5_bits_exceptionVec_11),
    .io_out_5_bits_exceptionVec_12(x_io_out_5_bits_exceptionVec_12), .io_out_5_bits_exceptionVec_13(x_io_out_5_bits_exceptionVec_13), .io_out_5_bits_exceptionVec_14(x_io_out_5_bits_exceptionVec_14), .io_out_5_bits_exceptionVec_15(x_io_out_5_bits_exceptionVec_15),
    .io_out_5_bits_exceptionVec_16(x_io_out_5_bits_exceptionVec_16), .io_out_5_bits_exceptionVec_17(x_io_out_5_bits_exceptionVec_17), .io_out_5_bits_exceptionVec_18(x_io_out_5_bits_exceptionVec_18), .io_out_5_bits_exceptionVec_19(x_io_out_5_bits_exceptionVec_19),
    .io_out_5_bits_exceptionVec_20(x_io_out_5_bits_exceptionVec_20), .io_out_5_bits_exceptionVec_21(x_io_out_5_bits_exceptionVec_21), .io_out_5_bits_exceptionVec_22(x_io_out_5_bits_exceptionVec_22), .io_out_5_bits_exceptionVec_23(x_io_out_5_bits_exceptionVec_23),
    .io_out_5_bits_isFetchMalAddr(x_io_out_5_bits_isFetchMalAddr), .io_out_5_bits_trigger(x_io_out_5_bits_trigger), .io_out_5_bits_preDecodeInfo_valid(x_io_out_5_bits_preDecodeInfo_valid), .io_out_5_bits_preDecodeInfo_isRVC(x_io_out_5_bits_preDecodeInfo_isRVC),
    .io_out_5_bits_preDecodeInfo_brType(x_io_out_5_bits_preDecodeInfo_brType), .io_out_5_bits_preDecodeInfo_isCall(x_io_out_5_bits_preDecodeInfo_isCall), .io_out_5_bits_preDecodeInfo_isRet(x_io_out_5_bits_preDecodeInfo_isRet), .io_out_5_bits_pred_taken(x_io_out_5_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(x_io_out_5_bits_crossPageIPFFix), .io_out_5_bits_ftqPtr_flag(x_io_out_5_bits_ftqPtr_flag), .io_out_5_bits_ftqPtr_value(x_io_out_5_bits_ftqPtr_value), .io_out_5_bits_ftqOffset(x_io_out_5_bits_ftqOffset),
    .io_out_5_bits_satpFlushFirstFetchFault(x_io_out_5_bits_satpFlushFirstFetchFault), .io_out_5_bits_srcType_0(x_io_out_5_bits_srcType_0), .io_out_5_bits_srcType_1(x_io_out_5_bits_srcType_1), .io_out_5_bits_srcType_2(x_io_out_5_bits_srcType_2),
    .io_out_5_bits_srcType_3(x_io_out_5_bits_srcType_3), .io_out_5_bits_srcType_4(x_io_out_5_bits_srcType_4), .io_out_5_bits_lsrc_0(x_io_out_5_bits_lsrc_0), .io_out_5_bits_lsrc_1(x_io_out_5_bits_lsrc_1),
    .io_out_5_bits_lsrc_2(x_io_out_5_bits_lsrc_2), .io_out_5_bits_ldest(x_io_out_5_bits_ldest), .io_out_5_bits_fuType(x_io_out_5_bits_fuType), .io_out_5_bits_fuOpType(x_io_out_5_bits_fuOpType),
    .io_out_5_bits_rfWen(x_io_out_5_bits_rfWen), .io_out_5_bits_fpWen(x_io_out_5_bits_fpWen), .io_out_5_bits_vecWen(x_io_out_5_bits_vecWen), .io_out_5_bits_v0Wen(x_io_out_5_bits_v0Wen),
    .io_out_5_bits_vlWen(x_io_out_5_bits_vlWen), .io_out_5_bits_isXSTrap(x_io_out_5_bits_isXSTrap), .io_out_5_bits_waitForward(x_io_out_5_bits_waitForward), .io_out_5_bits_blockBackward(x_io_out_5_bits_blockBackward),
    .io_out_5_bits_flushPipe(x_io_out_5_bits_flushPipe), .io_out_5_bits_canRobCompress(x_io_out_5_bits_canRobCompress), .io_out_5_bits_selImm(x_io_out_5_bits_selImm), .io_out_5_bits_imm(x_io_out_5_bits_imm),
    .io_out_5_bits_fpu_typeTagOut(x_io_out_5_bits_fpu_typeTagOut), .io_out_5_bits_fpu_wflags(x_io_out_5_bits_fpu_wflags), .io_out_5_bits_fpu_typ(x_io_out_5_bits_fpu_typ), .io_out_5_bits_fpu_fmt(x_io_out_5_bits_fpu_fmt),
    .io_out_5_bits_fpu_rm(x_io_out_5_bits_fpu_rm), .io_out_5_bits_vpu_vill(x_io_out_5_bits_vpu_vill), .io_out_5_bits_vpu_vma(x_io_out_5_bits_vpu_vma), .io_out_5_bits_vpu_vta(x_io_out_5_bits_vpu_vta),
    .io_out_5_bits_vpu_vsew(x_io_out_5_bits_vpu_vsew), .io_out_5_bits_vpu_vlmul(x_io_out_5_bits_vpu_vlmul), .io_out_5_bits_vpu_specVill(x_io_out_5_bits_vpu_specVill), .io_out_5_bits_vpu_specVma(x_io_out_5_bits_vpu_specVma),
    .io_out_5_bits_vpu_specVta(x_io_out_5_bits_vpu_specVta), .io_out_5_bits_vpu_specVsew(x_io_out_5_bits_vpu_specVsew), .io_out_5_bits_vpu_specVlmul(x_io_out_5_bits_vpu_specVlmul), .io_out_5_bits_vpu_vm(x_io_out_5_bits_vpu_vm),
    .io_out_5_bits_vpu_vstart(x_io_out_5_bits_vpu_vstart), .io_out_5_bits_vpu_fpu_isFoldTo1_2(x_io_out_5_bits_vpu_fpu_isFoldTo1_2), .io_out_5_bits_vpu_fpu_isFoldTo1_4(x_io_out_5_bits_vpu_fpu_isFoldTo1_4), .io_out_5_bits_vpu_fpu_isFoldTo1_8(x_io_out_5_bits_vpu_fpu_isFoldTo1_8),
    .io_out_5_bits_vpu_nf(x_io_out_5_bits_vpu_nf), .io_out_5_bits_vpu_veew(x_io_out_5_bits_vpu_veew), .io_out_5_bits_vpu_isReverse(x_io_out_5_bits_vpu_isReverse), .io_out_5_bits_vpu_isExt(x_io_out_5_bits_vpu_isExt),
    .io_out_5_bits_vpu_isNarrow(x_io_out_5_bits_vpu_isNarrow), .io_out_5_bits_vpu_isDstMask(x_io_out_5_bits_vpu_isDstMask), .io_out_5_bits_vpu_isOpMask(x_io_out_5_bits_vpu_isOpMask), .io_out_5_bits_vpu_isDependOldVd(x_io_out_5_bits_vpu_isDependOldVd),
    .io_out_5_bits_vpu_isWritePartVd(x_io_out_5_bits_vpu_isWritePartVd), .io_out_5_bits_vpu_isVleff(x_io_out_5_bits_vpu_isVleff), .io_out_5_bits_vlsInstr(x_io_out_5_bits_vlsInstr), .io_out_5_bits_wfflags(x_io_out_5_bits_wfflags),
    .io_out_5_bits_isMove(x_io_out_5_bits_isMove), .io_out_5_bits_uopIdx(x_io_out_5_bits_uopIdx), .io_out_5_bits_uopSplitType(x_io_out_5_bits_uopSplitType), .io_out_5_bits_isVset(x_io_out_5_bits_isVset),
    .io_out_5_bits_firstUop(x_io_out_5_bits_firstUop), .io_out_5_bits_lastUop(x_io_out_5_bits_lastUop), .io_out_5_bits_numUops(x_io_out_5_bits_numUops), .io_out_5_bits_numWB(x_io_out_5_bits_numWB),
    .io_out_5_bits_commitType(x_io_out_5_bits_commitType), .io_out_5_bits_debug_fuType(x_io_out_5_bits_debug_fuType), .io_out_5_bits_debug_seqNum_seqNum(x_io_out_5_bits_debug_seqNum_seqNum), .io_out_5_bits_debug_seqNum_uopIdx(x_io_out_5_bits_debug_seqNum_uopIdx),
    .io_intRat_0_0_hold(x_io_intRat_0_0_hold), .io_intRat_0_0_addr(x_io_intRat_0_0_addr), .io_intRat_0_1_hold(x_io_intRat_0_1_hold), .io_intRat_0_1_addr(x_io_intRat_0_1_addr),
    .io_intRat_1_0_hold(x_io_intRat_1_0_hold), .io_intRat_1_0_addr(x_io_intRat_1_0_addr), .io_intRat_1_1_hold(x_io_intRat_1_1_hold), .io_intRat_1_1_addr(x_io_intRat_1_1_addr),
    .io_intRat_2_0_hold(x_io_intRat_2_0_hold), .io_intRat_2_0_addr(x_io_intRat_2_0_addr), .io_intRat_2_1_hold(x_io_intRat_2_1_hold), .io_intRat_2_1_addr(x_io_intRat_2_1_addr),
    .io_intRat_3_0_hold(x_io_intRat_3_0_hold), .io_intRat_3_0_addr(x_io_intRat_3_0_addr), .io_intRat_3_1_hold(x_io_intRat_3_1_hold), .io_intRat_3_1_addr(x_io_intRat_3_1_addr),
    .io_intRat_4_0_hold(x_io_intRat_4_0_hold), .io_intRat_4_0_addr(x_io_intRat_4_0_addr), .io_intRat_4_1_hold(x_io_intRat_4_1_hold), .io_intRat_4_1_addr(x_io_intRat_4_1_addr),
    .io_intRat_5_0_hold(x_io_intRat_5_0_hold), .io_intRat_5_0_addr(x_io_intRat_5_0_addr), .io_intRat_5_1_hold(x_io_intRat_5_1_hold), .io_intRat_5_1_addr(x_io_intRat_5_1_addr),
    .io_fpRat_0_0_hold(x_io_fpRat_0_0_hold), .io_fpRat_0_0_addr(x_io_fpRat_0_0_addr), .io_fpRat_0_1_hold(x_io_fpRat_0_1_hold), .io_fpRat_0_1_addr(x_io_fpRat_0_1_addr),
    .io_fpRat_0_2_hold(x_io_fpRat_0_2_hold), .io_fpRat_0_2_addr(x_io_fpRat_0_2_addr), .io_fpRat_1_0_hold(x_io_fpRat_1_0_hold), .io_fpRat_1_0_addr(x_io_fpRat_1_0_addr),
    .io_fpRat_1_1_hold(x_io_fpRat_1_1_hold), .io_fpRat_1_1_addr(x_io_fpRat_1_1_addr), .io_fpRat_1_2_hold(x_io_fpRat_1_2_hold), .io_fpRat_1_2_addr(x_io_fpRat_1_2_addr),
    .io_fpRat_2_0_hold(x_io_fpRat_2_0_hold), .io_fpRat_2_0_addr(x_io_fpRat_2_0_addr), .io_fpRat_2_1_hold(x_io_fpRat_2_1_hold), .io_fpRat_2_1_addr(x_io_fpRat_2_1_addr),
    .io_fpRat_2_2_hold(x_io_fpRat_2_2_hold), .io_fpRat_2_2_addr(x_io_fpRat_2_2_addr), .io_fpRat_3_0_hold(x_io_fpRat_3_0_hold), .io_fpRat_3_0_addr(x_io_fpRat_3_0_addr),
    .io_fpRat_3_1_hold(x_io_fpRat_3_1_hold), .io_fpRat_3_1_addr(x_io_fpRat_3_1_addr), .io_fpRat_3_2_hold(x_io_fpRat_3_2_hold), .io_fpRat_3_2_addr(x_io_fpRat_3_2_addr),
    .io_fpRat_4_0_hold(x_io_fpRat_4_0_hold), .io_fpRat_4_0_addr(x_io_fpRat_4_0_addr), .io_fpRat_4_1_hold(x_io_fpRat_4_1_hold), .io_fpRat_4_1_addr(x_io_fpRat_4_1_addr),
    .io_fpRat_4_2_hold(x_io_fpRat_4_2_hold), .io_fpRat_4_2_addr(x_io_fpRat_4_2_addr), .io_fpRat_5_0_hold(x_io_fpRat_5_0_hold), .io_fpRat_5_0_addr(x_io_fpRat_5_0_addr),
    .io_fpRat_5_1_hold(x_io_fpRat_5_1_hold), .io_fpRat_5_1_addr(x_io_fpRat_5_1_addr), .io_fpRat_5_2_hold(x_io_fpRat_5_2_hold), .io_fpRat_5_2_addr(x_io_fpRat_5_2_addr),
    .io_vecRat_0_0_hold(x_io_vecRat_0_0_hold), .io_vecRat_0_0_addr(x_io_vecRat_0_0_addr), .io_vecRat_0_1_hold(x_io_vecRat_0_1_hold), .io_vecRat_0_1_addr(x_io_vecRat_0_1_addr),
    .io_vecRat_0_2_hold(x_io_vecRat_0_2_hold), .io_vecRat_0_2_addr(x_io_vecRat_0_2_addr), .io_vecRat_1_0_hold(x_io_vecRat_1_0_hold), .io_vecRat_1_0_addr(x_io_vecRat_1_0_addr),
    .io_vecRat_1_1_hold(x_io_vecRat_1_1_hold), .io_vecRat_1_1_addr(x_io_vecRat_1_1_addr), .io_vecRat_1_2_hold(x_io_vecRat_1_2_hold), .io_vecRat_1_2_addr(x_io_vecRat_1_2_addr),
    .io_vecRat_2_0_hold(x_io_vecRat_2_0_hold), .io_vecRat_2_0_addr(x_io_vecRat_2_0_addr), .io_vecRat_2_1_hold(x_io_vecRat_2_1_hold), .io_vecRat_2_1_addr(x_io_vecRat_2_1_addr),
    .io_vecRat_2_2_hold(x_io_vecRat_2_2_hold), .io_vecRat_2_2_addr(x_io_vecRat_2_2_addr), .io_vecRat_3_0_hold(x_io_vecRat_3_0_hold), .io_vecRat_3_0_addr(x_io_vecRat_3_0_addr),
    .io_vecRat_3_1_hold(x_io_vecRat_3_1_hold), .io_vecRat_3_1_addr(x_io_vecRat_3_1_addr), .io_vecRat_3_2_hold(x_io_vecRat_3_2_hold), .io_vecRat_3_2_addr(x_io_vecRat_3_2_addr),
    .io_vecRat_4_0_hold(x_io_vecRat_4_0_hold), .io_vecRat_4_0_addr(x_io_vecRat_4_0_addr), .io_vecRat_4_1_hold(x_io_vecRat_4_1_hold), .io_vecRat_4_1_addr(x_io_vecRat_4_1_addr),
    .io_vecRat_4_2_hold(x_io_vecRat_4_2_hold), .io_vecRat_4_2_addr(x_io_vecRat_4_2_addr), .io_vecRat_5_0_hold(x_io_vecRat_5_0_hold), .io_vecRat_5_0_addr(x_io_vecRat_5_0_addr),
    .io_vecRat_5_1_hold(x_io_vecRat_5_1_hold), .io_vecRat_5_1_addr(x_io_vecRat_5_1_addr), .io_vecRat_5_2_hold(x_io_vecRat_5_2_hold), .io_vecRat_5_2_addr(x_io_vecRat_5_2_addr),
    .io_v0Rat_0_hold(x_io_v0Rat_0_hold), .io_v0Rat_1_hold(x_io_v0Rat_1_hold), .io_v0Rat_2_hold(x_io_v0Rat_2_hold), .io_v0Rat_3_hold(x_io_v0Rat_3_hold),
    .io_v0Rat_4_hold(x_io_v0Rat_4_hold), .io_v0Rat_5_hold(x_io_v0Rat_5_hold), .io_vlRat_0_hold(x_io_vlRat_0_hold), .io_vlRat_1_hold(x_io_vlRat_1_hold),
    .io_vlRat_2_hold(x_io_vlRat_2_hold), .io_vlRat_3_hold(x_io_vlRat_3_hold), .io_vlRat_4_hold(x_io_vlRat_4_hold), .io_vlRat_5_hold(x_io_vlRat_5_hold),
    .io_stallReason_in_backReason_valid(x_io_stallReason_in_backReason_valid), .io_stallReason_in_backReason_bits(x_io_stallReason_in_backReason_bits), .io_stallReason_out_reason_0(x_io_stallReason_out_reason_0), .io_stallReason_out_reason_1(x_io_stallReason_out_reason_1),
    .io_stallReason_out_reason_2(x_io_stallReason_out_reason_2), .io_stallReason_out_reason_3(x_io_stallReason_out_reason_3), .io_stallReason_out_reason_4(x_io_stallReason_out_reason_4), .io_stallReason_out_reason_5(x_io_stallReason_out_reason_5),
    .io_toCSR_trapInstInfo_valid(x_io_toCSR_trapInstInfo_valid), .io_toCSR_trapInstInfo_bits_instr(x_io_toCSR_trapInstInfo_bits_instr), .io_toCSR_trapInstInfo_bits_ftqPtr_flag(x_io_toCSR_trapInstInfo_bits_ftqPtr_flag), .io_toCSR_trapInstInfo_bits_ftqPtr_value(x_io_toCSR_trapInstInfo_bits_ftqPtr_value),
    .io_toCSR_trapInstInfo_bits_ftqOffset(x_io_toCSR_trapInstInfo_bits_ftqOffset), .io_perf_0_value(x_io_perf_0_value), .io_perf_1_value(x_io_perf_1_value), .io_perf_2_value(x_io_perf_2_value),
    .io_perf_3_value(x_io_perf_3_value), .io_perf_4_value(x_io_perf_4_value), .io_perf_5_value(x_io_perf_5_value), .io_perf_6_value(x_io_perf_6_value),
    .io_perf_7_value(x_io_perf_7_value)
  );

  // ---- 指令构造 ----
  // 定向模板：让 DecodeUnit 报 isComplex 的（向量算术 OP-V / 向量访存 / vset / amocas）+ 常见标量 + 非法
  function automatic logic [31:0] mk_instr();
    logic [4:0] rd = 5'($urandom), rs1 = 5'($urandom), rs2 = 5'($urandom);
    logic [2:0] f3 = 3'($urandom);
    int pick = $urandom_range(0, 99);
    if (pick < 25)      return {6'($urandom), 1'($urandom), rs2, rs1, (f3 == 3'b111) ? 3'b000 : f3, rd, 7'h57};   // OP-V 算术（funct3 != 111）
    else if (pick < 33) return {6'($urandom), 1'($urandom), rs2, rs1, 3'b111, rd, 7'h57};                        // vsetvli/vsetivli/vsetvl
    else if (pick < 43) return {3'($urandom), 2'($urandom), 1'($urandom), 1'($urandom), rs2, rs1, (pick & 1) ? 3'b000 : 3'b110, rd, 7'h07}; // 向量 load
    else if (pick < 50) return {3'($urandom), 2'($urandom), 1'($urandom), 1'($urandom), rs2, rs1, (pick & 1) ? 3'b101 : 3'b111, rd, 7'h27}; // 向量 store
    else if (pick < 53) return {5'b00101, 1'($urandom), 1'($urandom), rs2, rs1, (pick & 1) ? 3'b011 : 3'b010, rd, 7'h2F};   // amocas
    else if (pick < 63) return {7'($urandom), rs2, rs1, f3, rd, 7'h33};                                             // R 型整数
    else if (pick < 70) return {12'($urandom), rs1, f3, rd, 7'h13};                                                 // I 型整数
    else if (pick < 75) return {12'($urandom), rs1, (f3 == 3'b111) ? 3'b011 : f3, rd, 7'h03};                         // load
    else if (pick < 80) return {7'($urandom), rs2, rs1, f3, rd, 7'h53};                                             // FP
    else if (pick < 84) return {12'($urandom), rs1, f3, rd, 7'h73};                                                 // SYSTEM/CSR
    else if (pick < 88) return {12'h000, 5'h0, 3'b000, 5'h0, 7'h0F};                                             // fence
    else if (pick < 92) return 32'h0;                                                                           // 非法（全 0）
    else                return $urandom;
  endfunction

  function automatic logic next_ready();
    static int hold = 0; static logic cur = 1;
    if (hold == 0) begin cur = ($urandom_range(0, 3) != 0); hold = $urandom_range(1, 12); end
    hold--; return cur;
  endfunction

  logic i_ready_0;   // out[0].ready 的长条 0/1 源
  task automatic drive_inputs(input bit warm);
    io_redirect = 1'($urandom);
    io_in_0_valid = 1'($urandom);
    io_in_0_bits_instr = 32'($urandom);
    io_in_0_bits_pc = 50'($urandom);
    io_in_0_bits_foldpc = 10'($urandom);
    io_in_0_bits_exceptionVec_0 = 1'($urandom);
    io_in_0_bits_exceptionVec_1 = 1'($urandom);
    io_in_0_bits_exceptionVec_2 = 1'($urandom);
    io_in_0_bits_exceptionVec_4 = 1'($urandom);
    io_in_0_bits_exceptionVec_5 = 1'($urandom);
    io_in_0_bits_exceptionVec_6 = 1'($urandom);
    io_in_0_bits_exceptionVec_7 = 1'($urandom);
    io_in_0_bits_exceptionVec_8 = 1'($urandom);
    io_in_0_bits_exceptionVec_9 = 1'($urandom);
    io_in_0_bits_exceptionVec_10 = 1'($urandom);
    io_in_0_bits_exceptionVec_11 = 1'($urandom);
    io_in_0_bits_exceptionVec_12 = 1'($urandom);
    io_in_0_bits_exceptionVec_13 = 1'($urandom);
    io_in_0_bits_exceptionVec_14 = 1'($urandom);
    io_in_0_bits_exceptionVec_15 = 1'($urandom);
    io_in_0_bits_exceptionVec_16 = 1'($urandom);
    io_in_0_bits_exceptionVec_17 = 1'($urandom);
    io_in_0_bits_exceptionVec_18 = 1'($urandom);
    io_in_0_bits_exceptionVec_19 = 1'($urandom);
    io_in_0_bits_exceptionVec_20 = 1'($urandom);
    io_in_0_bits_exceptionVec_21 = 1'($urandom);
    io_in_0_bits_exceptionVec_23 = 1'($urandom);
    io_in_0_bits_isFetchMalAddr = 1'($urandom);
    io_in_0_bits_trigger = 4'($urandom);
    io_in_0_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_0_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_0_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_0_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_0_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_0_bits_pred_taken = 1'($urandom);
    io_in_0_bits_crossPageIPFFix = 1'($urandom);
    io_in_0_bits_ftqPtr_flag = 1'($urandom);
    io_in_0_bits_ftqPtr_value = 6'($urandom);
    io_in_0_bits_ftqOffset = 4'($urandom);
    io_in_0_bits_isLastInFtqEntry = 1'($urandom);
    io_in_0_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_0_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_0_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_1_valid = 1'($urandom);
    io_in_1_bits_instr = 32'($urandom);
    io_in_1_bits_pc = 50'($urandom);
    io_in_1_bits_foldpc = 10'($urandom);
    io_in_1_bits_exceptionVec_0 = 1'($urandom);
    io_in_1_bits_exceptionVec_1 = 1'($urandom);
    io_in_1_bits_exceptionVec_2 = 1'($urandom);
    io_in_1_bits_exceptionVec_4 = 1'($urandom);
    io_in_1_bits_exceptionVec_5 = 1'($urandom);
    io_in_1_bits_exceptionVec_6 = 1'($urandom);
    io_in_1_bits_exceptionVec_7 = 1'($urandom);
    io_in_1_bits_exceptionVec_8 = 1'($urandom);
    io_in_1_bits_exceptionVec_9 = 1'($urandom);
    io_in_1_bits_exceptionVec_10 = 1'($urandom);
    io_in_1_bits_exceptionVec_11 = 1'($urandom);
    io_in_1_bits_exceptionVec_12 = 1'($urandom);
    io_in_1_bits_exceptionVec_13 = 1'($urandom);
    io_in_1_bits_exceptionVec_14 = 1'($urandom);
    io_in_1_bits_exceptionVec_15 = 1'($urandom);
    io_in_1_bits_exceptionVec_16 = 1'($urandom);
    io_in_1_bits_exceptionVec_17 = 1'($urandom);
    io_in_1_bits_exceptionVec_18 = 1'($urandom);
    io_in_1_bits_exceptionVec_19 = 1'($urandom);
    io_in_1_bits_exceptionVec_20 = 1'($urandom);
    io_in_1_bits_exceptionVec_21 = 1'($urandom);
    io_in_1_bits_exceptionVec_23 = 1'($urandom);
    io_in_1_bits_isFetchMalAddr = 1'($urandom);
    io_in_1_bits_trigger = 4'($urandom);
    io_in_1_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_1_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_1_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_1_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_1_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_1_bits_pred_taken = 1'($urandom);
    io_in_1_bits_crossPageIPFFix = 1'($urandom);
    io_in_1_bits_ftqPtr_flag = 1'($urandom);
    io_in_1_bits_ftqPtr_value = 6'($urandom);
    io_in_1_bits_ftqOffset = 4'($urandom);
    io_in_1_bits_isLastInFtqEntry = 1'($urandom);
    io_in_1_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_1_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_1_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_2_valid = 1'($urandom);
    io_in_2_bits_instr = 32'($urandom);
    io_in_2_bits_pc = 50'($urandom);
    io_in_2_bits_foldpc = 10'($urandom);
    io_in_2_bits_exceptionVec_0 = 1'($urandom);
    io_in_2_bits_exceptionVec_1 = 1'($urandom);
    io_in_2_bits_exceptionVec_2 = 1'($urandom);
    io_in_2_bits_exceptionVec_4 = 1'($urandom);
    io_in_2_bits_exceptionVec_5 = 1'($urandom);
    io_in_2_bits_exceptionVec_6 = 1'($urandom);
    io_in_2_bits_exceptionVec_7 = 1'($urandom);
    io_in_2_bits_exceptionVec_8 = 1'($urandom);
    io_in_2_bits_exceptionVec_9 = 1'($urandom);
    io_in_2_bits_exceptionVec_10 = 1'($urandom);
    io_in_2_bits_exceptionVec_11 = 1'($urandom);
    io_in_2_bits_exceptionVec_12 = 1'($urandom);
    io_in_2_bits_exceptionVec_13 = 1'($urandom);
    io_in_2_bits_exceptionVec_14 = 1'($urandom);
    io_in_2_bits_exceptionVec_15 = 1'($urandom);
    io_in_2_bits_exceptionVec_16 = 1'($urandom);
    io_in_2_bits_exceptionVec_17 = 1'($urandom);
    io_in_2_bits_exceptionVec_18 = 1'($urandom);
    io_in_2_bits_exceptionVec_19 = 1'($urandom);
    io_in_2_bits_exceptionVec_20 = 1'($urandom);
    io_in_2_bits_exceptionVec_21 = 1'($urandom);
    io_in_2_bits_exceptionVec_23 = 1'($urandom);
    io_in_2_bits_isFetchMalAddr = 1'($urandom);
    io_in_2_bits_trigger = 4'($urandom);
    io_in_2_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_2_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_2_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_2_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_2_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_2_bits_pred_taken = 1'($urandom);
    io_in_2_bits_crossPageIPFFix = 1'($urandom);
    io_in_2_bits_ftqPtr_flag = 1'($urandom);
    io_in_2_bits_ftqPtr_value = 6'($urandom);
    io_in_2_bits_ftqOffset = 4'($urandom);
    io_in_2_bits_isLastInFtqEntry = 1'($urandom);
    io_in_2_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_2_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_2_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_3_valid = 1'($urandom);
    io_in_3_bits_instr = 32'($urandom);
    io_in_3_bits_pc = 50'($urandom);
    io_in_3_bits_foldpc = 10'($urandom);
    io_in_3_bits_exceptionVec_0 = 1'($urandom);
    io_in_3_bits_exceptionVec_1 = 1'($urandom);
    io_in_3_bits_exceptionVec_2 = 1'($urandom);
    io_in_3_bits_exceptionVec_4 = 1'($urandom);
    io_in_3_bits_exceptionVec_5 = 1'($urandom);
    io_in_3_bits_exceptionVec_6 = 1'($urandom);
    io_in_3_bits_exceptionVec_7 = 1'($urandom);
    io_in_3_bits_exceptionVec_8 = 1'($urandom);
    io_in_3_bits_exceptionVec_9 = 1'($urandom);
    io_in_3_bits_exceptionVec_10 = 1'($urandom);
    io_in_3_bits_exceptionVec_11 = 1'($urandom);
    io_in_3_bits_exceptionVec_12 = 1'($urandom);
    io_in_3_bits_exceptionVec_13 = 1'($urandom);
    io_in_3_bits_exceptionVec_14 = 1'($urandom);
    io_in_3_bits_exceptionVec_15 = 1'($urandom);
    io_in_3_bits_exceptionVec_16 = 1'($urandom);
    io_in_3_bits_exceptionVec_17 = 1'($urandom);
    io_in_3_bits_exceptionVec_18 = 1'($urandom);
    io_in_3_bits_exceptionVec_19 = 1'($urandom);
    io_in_3_bits_exceptionVec_20 = 1'($urandom);
    io_in_3_bits_exceptionVec_21 = 1'($urandom);
    io_in_3_bits_exceptionVec_23 = 1'($urandom);
    io_in_3_bits_isFetchMalAddr = 1'($urandom);
    io_in_3_bits_trigger = 4'($urandom);
    io_in_3_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_3_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_3_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_3_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_3_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_3_bits_pred_taken = 1'($urandom);
    io_in_3_bits_crossPageIPFFix = 1'($urandom);
    io_in_3_bits_ftqPtr_flag = 1'($urandom);
    io_in_3_bits_ftqPtr_value = 6'($urandom);
    io_in_3_bits_ftqOffset = 4'($urandom);
    io_in_3_bits_isLastInFtqEntry = 1'($urandom);
    io_in_3_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_3_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_3_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_4_valid = 1'($urandom);
    io_in_4_bits_instr = 32'($urandom);
    io_in_4_bits_pc = 50'($urandom);
    io_in_4_bits_foldpc = 10'($urandom);
    io_in_4_bits_exceptionVec_0 = 1'($urandom);
    io_in_4_bits_exceptionVec_1 = 1'($urandom);
    io_in_4_bits_exceptionVec_2 = 1'($urandom);
    io_in_4_bits_exceptionVec_4 = 1'($urandom);
    io_in_4_bits_exceptionVec_5 = 1'($urandom);
    io_in_4_bits_exceptionVec_6 = 1'($urandom);
    io_in_4_bits_exceptionVec_7 = 1'($urandom);
    io_in_4_bits_exceptionVec_8 = 1'($urandom);
    io_in_4_bits_exceptionVec_9 = 1'($urandom);
    io_in_4_bits_exceptionVec_10 = 1'($urandom);
    io_in_4_bits_exceptionVec_11 = 1'($urandom);
    io_in_4_bits_exceptionVec_12 = 1'($urandom);
    io_in_4_bits_exceptionVec_13 = 1'($urandom);
    io_in_4_bits_exceptionVec_14 = 1'($urandom);
    io_in_4_bits_exceptionVec_15 = 1'($urandom);
    io_in_4_bits_exceptionVec_16 = 1'($urandom);
    io_in_4_bits_exceptionVec_17 = 1'($urandom);
    io_in_4_bits_exceptionVec_18 = 1'($urandom);
    io_in_4_bits_exceptionVec_19 = 1'($urandom);
    io_in_4_bits_exceptionVec_20 = 1'($urandom);
    io_in_4_bits_exceptionVec_21 = 1'($urandom);
    io_in_4_bits_exceptionVec_23 = 1'($urandom);
    io_in_4_bits_isFetchMalAddr = 1'($urandom);
    io_in_4_bits_trigger = 4'($urandom);
    io_in_4_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_4_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_4_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_4_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_4_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_4_bits_pred_taken = 1'($urandom);
    io_in_4_bits_crossPageIPFFix = 1'($urandom);
    io_in_4_bits_ftqPtr_flag = 1'($urandom);
    io_in_4_bits_ftqPtr_value = 6'($urandom);
    io_in_4_bits_ftqOffset = 4'($urandom);
    io_in_4_bits_isLastInFtqEntry = 1'($urandom);
    io_in_4_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_4_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_4_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_5_valid = 1'($urandom);
    io_in_5_bits_instr = 32'($urandom);
    io_in_5_bits_pc = 50'($urandom);
    io_in_5_bits_foldpc = 10'($urandom);
    io_in_5_bits_exceptionVec_0 = 1'($urandom);
    io_in_5_bits_exceptionVec_1 = 1'($urandom);
    io_in_5_bits_exceptionVec_2 = 1'($urandom);
    io_in_5_bits_exceptionVec_4 = 1'($urandom);
    io_in_5_bits_exceptionVec_5 = 1'($urandom);
    io_in_5_bits_exceptionVec_6 = 1'($urandom);
    io_in_5_bits_exceptionVec_7 = 1'($urandom);
    io_in_5_bits_exceptionVec_8 = 1'($urandom);
    io_in_5_bits_exceptionVec_9 = 1'($urandom);
    io_in_5_bits_exceptionVec_10 = 1'($urandom);
    io_in_5_bits_exceptionVec_11 = 1'($urandom);
    io_in_5_bits_exceptionVec_12 = 1'($urandom);
    io_in_5_bits_exceptionVec_13 = 1'($urandom);
    io_in_5_bits_exceptionVec_14 = 1'($urandom);
    io_in_5_bits_exceptionVec_15 = 1'($urandom);
    io_in_5_bits_exceptionVec_16 = 1'($urandom);
    io_in_5_bits_exceptionVec_17 = 1'($urandom);
    io_in_5_bits_exceptionVec_18 = 1'($urandom);
    io_in_5_bits_exceptionVec_19 = 1'($urandom);
    io_in_5_bits_exceptionVec_20 = 1'($urandom);
    io_in_5_bits_exceptionVec_21 = 1'($urandom);
    io_in_5_bits_exceptionVec_23 = 1'($urandom);
    io_in_5_bits_isFetchMalAddr = 1'($urandom);
    io_in_5_bits_trigger = 4'($urandom);
    io_in_5_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_5_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_5_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_5_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_5_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_5_bits_pred_taken = 1'($urandom);
    io_in_5_bits_crossPageIPFFix = 1'($urandom);
    io_in_5_bits_ftqPtr_flag = 1'($urandom);
    io_in_5_bits_ftqPtr_value = 6'($urandom);
    io_in_5_bits_ftqOffset = 4'($urandom);
    io_in_5_bits_isLastInFtqEntry = 1'($urandom);
    io_in_5_bits_debug_seqNum_seqNum = 56'($urandom);
    io_in_5_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_5_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_out_0_ready = 1'($urandom);
    io_out_1_ready = 1'($urandom);
    io_out_2_ready = 1'($urandom);
    io_out_3_ready = 1'($urandom);
    io_out_4_ready = 1'($urandom);
    io_out_5_ready = 1'($urandom);
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
    io_fusion_0 = 1'($urandom);
    io_fusion_1 = 1'($urandom);
    io_fusion_2 = 1'($urandom);
    io_fusion_3 = 1'($urandom);
    io_fusion_4 = 1'($urandom);
    io_backendCanAccept = 1'($urandom);
    io_fromRob_isResumeVType = 1'($urandom);
    io_fromRob_walkToArchVType = 1'($urandom);
    io_fromRob_commitVType_vtype_valid = 1'($urandom);
    io_fromRob_commitVType_vtype_bits_illegal = 1'($urandom);
    io_fromRob_commitVType_vtype_bits_vma = 1'($urandom);
    io_fromRob_commitVType_vtype_bits_vta = 1'($urandom);
    io_fromRob_commitVType_vtype_bits_vsew = 2'($urandom);
    io_fromRob_commitVType_vtype_bits_vlmul = 3'($urandom);
    io_fromRob_commitVType_hasVsetvl = 1'($urandom);
    io_fromRob_walkVType_valid = 1'($urandom);
    io_fromRob_walkVType_bits_illegal = 1'($urandom);
    io_fromRob_walkVType_bits_vma = 1'($urandom);
    io_fromRob_walkVType_bits_vta = 1'($urandom);
    io_fromRob_walkVType_bits_vsew = 2'($urandom);
    io_fromRob_walkVType_bits_vlmul = 3'($urandom);
    io_stallReason_in_reason_0 = 6'($urandom);
    io_stallReason_in_reason_1 = 6'($urandom);
    io_stallReason_in_reason_2 = 6'($urandom);
    io_stallReason_in_reason_3 = 6'($urandom);
    io_stallReason_in_reason_4 = 6'($urandom);
    io_stallReason_in_reason_5 = 6'($urandom);
    io_stallReason_out_backReason_valid = 1'($urandom);
    io_stallReason_out_backReason_bits = 6'($urandom);
    io_vsetvlVType_illegal = 1'($urandom);
    io_vsetvlVType_vma = 1'($urandom);
    io_vsetvlVType_vta = 1'($urandom);
    io_vsetvlVType_vsew = 2'($urandom);
    io_vsetvlVType_vlmul = 3'($urandom);
    io_vstart = 8'($urandom);
    // 主控信号按分布覆盖
    io_in_0_bits_instr = mk_instr();
    io_in_0_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_0_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_in_1_bits_instr = mk_instr();
    io_in_1_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_1_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_in_2_bits_instr = mk_instr();
    io_in_2_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_2_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_in_3_bits_instr = mk_instr();
    io_in_3_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_3_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_in_4_bits_instr = mk_instr();
    io_in_4_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_4_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_in_5_bits_instr = mk_instr();
    io_in_5_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);
    io_out_5_ready = warm ? 1'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));
    io_out_0_ready = warm ? 1'b1 : i_ready_0;
    io_redirect = warm ? 1'b0 : ($urandom_range(0, 49) == 0);
    io_fromRob_isResumeVType = warm ? 1'b0 : ($urandom_range(0, 29) == 0);
    io_fromRob_walkToArchVType = warm ? 1'b0 : ($urandom_range(0, 29) == 0);
    io_fromRob_commitVType_vtype_valid = warm ? 1'b0 : ($urandom_range(0, 9) == 0);
    io_fromRob_walkVType_valid = warm ? 1'b0 : ($urandom_range(0, 19) == 0);
    io_backendCanAccept = ($urandom_range(0, 3) != 0);
    io_csrCtrl_singlestep = ($urandom_range(0, 19) == 0);
    io_stallReason_out_backReason_valid = ($urandom_range(0, 3) == 0);
  endtask

  task automatic compare_outputs();
    checks++;
    if (g_io_in_0_ready !== x_io_in_0_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_0_ready g=%h x=%h", $time, g_io_in_0_ready, x_io_in_0_ready); end
    if (g_io_in_1_ready !== x_io_in_1_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_1_ready g=%h x=%h", $time, g_io_in_1_ready, x_io_in_1_ready); end
    if (g_io_in_2_ready !== x_io_in_2_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_2_ready g=%h x=%h", $time, g_io_in_2_ready, x_io_in_2_ready); end
    if (g_io_in_3_ready !== x_io_in_3_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_3_ready g=%h x=%h", $time, g_io_in_3_ready, x_io_in_3_ready); end
    if (g_io_in_4_ready !== x_io_in_4_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_4_ready g=%h x=%h", $time, g_io_in_4_ready, x_io_in_4_ready); end
    if (g_io_in_5_ready !== x_io_in_5_ready) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_in_5_ready g=%h x=%h", $time, g_io_in_5_ready, x_io_in_5_ready); end
    if (g_io_out_0_valid !== x_io_out_0_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_valid g=%h x=%h", $time, g_io_out_0_valid, x_io_out_0_valid); end
    if (g_io_out_0_bits_instr !== x_io_out_0_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_instr g=%h x=%h", $time, g_io_out_0_bits_instr, x_io_out_0_bits_instr); end
    if (g_io_out_0_bits_pc !== x_io_out_0_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_pc g=%h x=%h", $time, g_io_out_0_bits_pc, x_io_out_0_bits_pc); end
    if (g_io_out_0_bits_foldpc !== x_io_out_0_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_foldpc g=%h x=%h", $time, g_io_out_0_bits_foldpc, x_io_out_0_bits_foldpc); end
    if (g_io_out_0_bits_exceptionVec_0 !== x_io_out_0_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_0, x_io_out_0_bits_exceptionVec_0); end
    if (g_io_out_0_bits_exceptionVec_1 !== x_io_out_0_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_1, x_io_out_0_bits_exceptionVec_1); end
    if (g_io_out_0_bits_exceptionVec_2 !== x_io_out_0_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_2, x_io_out_0_bits_exceptionVec_2); end
    if (g_io_out_0_bits_exceptionVec_3 !== x_io_out_0_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_3, x_io_out_0_bits_exceptionVec_3); end
    if (g_io_out_0_bits_exceptionVec_4 !== x_io_out_0_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_4, x_io_out_0_bits_exceptionVec_4); end
    if (g_io_out_0_bits_exceptionVec_5 !== x_io_out_0_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_5, x_io_out_0_bits_exceptionVec_5); end
    if (g_io_out_0_bits_exceptionVec_6 !== x_io_out_0_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_6, x_io_out_0_bits_exceptionVec_6); end
    if (g_io_out_0_bits_exceptionVec_7 !== x_io_out_0_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_7, x_io_out_0_bits_exceptionVec_7); end
    if (g_io_out_0_bits_exceptionVec_8 !== x_io_out_0_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_8, x_io_out_0_bits_exceptionVec_8); end
    if (g_io_out_0_bits_exceptionVec_9 !== x_io_out_0_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_9, x_io_out_0_bits_exceptionVec_9); end
    if (g_io_out_0_bits_exceptionVec_10 !== x_io_out_0_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_10, x_io_out_0_bits_exceptionVec_10); end
    if (g_io_out_0_bits_exceptionVec_11 !== x_io_out_0_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_11, x_io_out_0_bits_exceptionVec_11); end
    if (g_io_out_0_bits_exceptionVec_12 !== x_io_out_0_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_12, x_io_out_0_bits_exceptionVec_12); end
    if (g_io_out_0_bits_exceptionVec_13 !== x_io_out_0_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_13, x_io_out_0_bits_exceptionVec_13); end
    if (g_io_out_0_bits_exceptionVec_14 !== x_io_out_0_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_14, x_io_out_0_bits_exceptionVec_14); end
    if (g_io_out_0_bits_exceptionVec_15 !== x_io_out_0_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_15, x_io_out_0_bits_exceptionVec_15); end
    if (g_io_out_0_bits_exceptionVec_16 !== x_io_out_0_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_16, x_io_out_0_bits_exceptionVec_16); end
    if (g_io_out_0_bits_exceptionVec_17 !== x_io_out_0_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_17, x_io_out_0_bits_exceptionVec_17); end
    if (g_io_out_0_bits_exceptionVec_18 !== x_io_out_0_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_18, x_io_out_0_bits_exceptionVec_18); end
    if (g_io_out_0_bits_exceptionVec_19 !== x_io_out_0_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_19, x_io_out_0_bits_exceptionVec_19); end
    if (g_io_out_0_bits_exceptionVec_20 !== x_io_out_0_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_20, x_io_out_0_bits_exceptionVec_20); end
    if (g_io_out_0_bits_exceptionVec_21 !== x_io_out_0_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_21, x_io_out_0_bits_exceptionVec_21); end
    if (g_io_out_0_bits_exceptionVec_22 !== x_io_out_0_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_22, x_io_out_0_bits_exceptionVec_22); end
    if (g_io_out_0_bits_exceptionVec_23 !== x_io_out_0_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_0_bits_exceptionVec_23, x_io_out_0_bits_exceptionVec_23); end
    if (g_io_out_0_bits_isFetchMalAddr !== x_io_out_0_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_0_bits_isFetchMalAddr, x_io_out_0_bits_isFetchMalAddr); end
    if (g_io_out_0_bits_trigger !== x_io_out_0_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_trigger g=%h x=%h", $time, g_io_out_0_bits_trigger, x_io_out_0_bits_trigger); end
    if (g_io_out_0_bits_preDecodeInfo_valid !== x_io_out_0_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_0_bits_preDecodeInfo_valid, x_io_out_0_bits_preDecodeInfo_valid); end
    if (g_io_out_0_bits_preDecodeInfo_isRVC !== x_io_out_0_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_0_bits_preDecodeInfo_isRVC, x_io_out_0_bits_preDecodeInfo_isRVC); end
    if (g_io_out_0_bits_preDecodeInfo_brType !== x_io_out_0_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_0_bits_preDecodeInfo_brType, x_io_out_0_bits_preDecodeInfo_brType); end
    if (g_io_out_0_bits_preDecodeInfo_isCall !== x_io_out_0_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_0_bits_preDecodeInfo_isCall, x_io_out_0_bits_preDecodeInfo_isCall); end
    if (g_io_out_0_bits_preDecodeInfo_isRet !== x_io_out_0_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_0_bits_preDecodeInfo_isRet, x_io_out_0_bits_preDecodeInfo_isRet); end
    if (g_io_out_0_bits_pred_taken !== x_io_out_0_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_pred_taken g=%h x=%h", $time, g_io_out_0_bits_pred_taken, x_io_out_0_bits_pred_taken); end
    if (g_io_out_0_bits_crossPageIPFFix !== x_io_out_0_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_0_bits_crossPageIPFFix, x_io_out_0_bits_crossPageIPFFix); end
    if (g_io_out_0_bits_ftqPtr_flag !== x_io_out_0_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_0_bits_ftqPtr_flag, x_io_out_0_bits_ftqPtr_flag); end
    if (g_io_out_0_bits_ftqPtr_value !== x_io_out_0_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_0_bits_ftqPtr_value, x_io_out_0_bits_ftqPtr_value); end
    if (g_io_out_0_bits_ftqOffset !== x_io_out_0_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_ftqOffset g=%h x=%h", $time, g_io_out_0_bits_ftqOffset, x_io_out_0_bits_ftqOffset); end
    if (g_io_out_0_bits_satpFlushFirstFetchFault !== x_io_out_0_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_0_bits_satpFlushFirstFetchFault, x_io_out_0_bits_satpFlushFirstFetchFault); end
    if (g_io_out_0_bits_srcType_0 !== x_io_out_0_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_srcType_0 g=%h x=%h", $time, g_io_out_0_bits_srcType_0, x_io_out_0_bits_srcType_0); end
    if (g_io_out_0_bits_srcType_1 !== x_io_out_0_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_srcType_1 g=%h x=%h", $time, g_io_out_0_bits_srcType_1, x_io_out_0_bits_srcType_1); end
    if (g_io_out_0_bits_srcType_2 !== x_io_out_0_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_srcType_2 g=%h x=%h", $time, g_io_out_0_bits_srcType_2, x_io_out_0_bits_srcType_2); end
    if (g_io_out_0_bits_srcType_3 !== x_io_out_0_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_srcType_3 g=%h x=%h", $time, g_io_out_0_bits_srcType_3, x_io_out_0_bits_srcType_3); end
    if (g_io_out_0_bits_srcType_4 !== x_io_out_0_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_srcType_4 g=%h x=%h", $time, g_io_out_0_bits_srcType_4, x_io_out_0_bits_srcType_4); end
    if (g_io_out_0_bits_lsrc_0 !== x_io_out_0_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_lsrc_0 g=%h x=%h", $time, g_io_out_0_bits_lsrc_0, x_io_out_0_bits_lsrc_0); end
    if (g_io_out_0_bits_lsrc_1 !== x_io_out_0_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_lsrc_1 g=%h x=%h", $time, g_io_out_0_bits_lsrc_1, x_io_out_0_bits_lsrc_1); end
    if (g_io_out_0_bits_lsrc_2 !== x_io_out_0_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_lsrc_2 g=%h x=%h", $time, g_io_out_0_bits_lsrc_2, x_io_out_0_bits_lsrc_2); end
    if (g_io_out_0_bits_ldest !== x_io_out_0_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_ldest g=%h x=%h", $time, g_io_out_0_bits_ldest, x_io_out_0_bits_ldest); end
    if (g_io_out_0_bits_fuType !== x_io_out_0_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fuType g=%h x=%h", $time, g_io_out_0_bits_fuType, x_io_out_0_bits_fuType); end
    if (g_io_out_0_bits_fuOpType !== x_io_out_0_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fuOpType g=%h x=%h", $time, g_io_out_0_bits_fuOpType, x_io_out_0_bits_fuOpType); end
    if (g_io_out_0_bits_rfWen !== x_io_out_0_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_rfWen g=%h x=%h", $time, g_io_out_0_bits_rfWen, x_io_out_0_bits_rfWen); end
    if (g_io_out_0_bits_fpWen !== x_io_out_0_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpWen g=%h x=%h", $time, g_io_out_0_bits_fpWen, x_io_out_0_bits_fpWen); end
    if (g_io_out_0_bits_vecWen !== x_io_out_0_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vecWen g=%h x=%h", $time, g_io_out_0_bits_vecWen, x_io_out_0_bits_vecWen); end
    if (g_io_out_0_bits_v0Wen !== x_io_out_0_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_v0Wen g=%h x=%h", $time, g_io_out_0_bits_v0Wen, x_io_out_0_bits_v0Wen); end
    if (g_io_out_0_bits_vlWen !== x_io_out_0_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vlWen g=%h x=%h", $time, g_io_out_0_bits_vlWen, x_io_out_0_bits_vlWen); end
    if (g_io_out_0_bits_isXSTrap !== x_io_out_0_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_isXSTrap g=%h x=%h", $time, g_io_out_0_bits_isXSTrap, x_io_out_0_bits_isXSTrap); end
    if (g_io_out_0_bits_waitForward !== x_io_out_0_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_waitForward g=%h x=%h", $time, g_io_out_0_bits_waitForward, x_io_out_0_bits_waitForward); end
    if (g_io_out_0_bits_blockBackward !== x_io_out_0_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_blockBackward g=%h x=%h", $time, g_io_out_0_bits_blockBackward, x_io_out_0_bits_blockBackward); end
    if (g_io_out_0_bits_flushPipe !== x_io_out_0_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_flushPipe g=%h x=%h", $time, g_io_out_0_bits_flushPipe, x_io_out_0_bits_flushPipe); end
    if (g_io_out_0_bits_canRobCompress !== x_io_out_0_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_canRobCompress g=%h x=%h", $time, g_io_out_0_bits_canRobCompress, x_io_out_0_bits_canRobCompress); end
    if (g_io_out_0_bits_selImm !== x_io_out_0_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_selImm g=%h x=%h", $time, g_io_out_0_bits_selImm, x_io_out_0_bits_selImm); end
    if (g_io_out_0_bits_imm !== x_io_out_0_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_imm g=%h x=%h", $time, g_io_out_0_bits_imm, x_io_out_0_bits_imm); end
    if (g_io_out_0_bits_fpu_typeTagOut !== x_io_out_0_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_0_bits_fpu_typeTagOut, x_io_out_0_bits_fpu_typeTagOut); end
    if (g_io_out_0_bits_fpu_wflags !== x_io_out_0_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpu_wflags g=%h x=%h", $time, g_io_out_0_bits_fpu_wflags, x_io_out_0_bits_fpu_wflags); end
    if (g_io_out_0_bits_fpu_typ !== x_io_out_0_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpu_typ g=%h x=%h", $time, g_io_out_0_bits_fpu_typ, x_io_out_0_bits_fpu_typ); end
    if (g_io_out_0_bits_fpu_fmt !== x_io_out_0_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpu_fmt g=%h x=%h", $time, g_io_out_0_bits_fpu_fmt, x_io_out_0_bits_fpu_fmt); end
    if (g_io_out_0_bits_fpu_rm !== x_io_out_0_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_fpu_rm g=%h x=%h", $time, g_io_out_0_bits_fpu_rm, x_io_out_0_bits_fpu_rm); end
    if (g_io_out_0_bits_vpu_vill !== x_io_out_0_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vill g=%h x=%h", $time, g_io_out_0_bits_vpu_vill, x_io_out_0_bits_vpu_vill); end
    if (g_io_out_0_bits_vpu_vma !== x_io_out_0_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vma g=%h x=%h", $time, g_io_out_0_bits_vpu_vma, x_io_out_0_bits_vpu_vma); end
    if (g_io_out_0_bits_vpu_vta !== x_io_out_0_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vta g=%h x=%h", $time, g_io_out_0_bits_vpu_vta, x_io_out_0_bits_vpu_vta); end
    if (g_io_out_0_bits_vpu_vsew !== x_io_out_0_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vsew g=%h x=%h", $time, g_io_out_0_bits_vpu_vsew, x_io_out_0_bits_vpu_vsew); end
    if (g_io_out_0_bits_vpu_vlmul !== x_io_out_0_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_0_bits_vpu_vlmul, x_io_out_0_bits_vpu_vlmul); end
    if (g_io_out_0_bits_vpu_specVill !== x_io_out_0_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_specVill g=%h x=%h", $time, g_io_out_0_bits_vpu_specVill, x_io_out_0_bits_vpu_specVill); end
    if (g_io_out_0_bits_vpu_specVma !== x_io_out_0_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_specVma g=%h x=%h", $time, g_io_out_0_bits_vpu_specVma, x_io_out_0_bits_vpu_specVma); end
    if (g_io_out_0_bits_vpu_specVta !== x_io_out_0_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_specVta g=%h x=%h", $time, g_io_out_0_bits_vpu_specVta, x_io_out_0_bits_vpu_specVta); end
    if (g_io_out_0_bits_vpu_specVsew !== x_io_out_0_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_0_bits_vpu_specVsew, x_io_out_0_bits_vpu_specVsew); end
    if (g_io_out_0_bits_vpu_specVlmul !== x_io_out_0_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_0_bits_vpu_specVlmul, x_io_out_0_bits_vpu_specVlmul); end
    if (g_io_out_0_bits_vpu_vm !== x_io_out_0_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vm g=%h x=%h", $time, g_io_out_0_bits_vpu_vm, x_io_out_0_bits_vpu_vm); end
    if (g_io_out_0_bits_vpu_vstart !== x_io_out_0_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_vstart g=%h x=%h", $time, g_io_out_0_bits_vpu_vstart, x_io_out_0_bits_vpu_vstart); end
    if (g_io_out_0_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_0_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_0_bits_vpu_fpu_isFoldTo1_2, x_io_out_0_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_0_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_0_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_0_bits_vpu_fpu_isFoldTo1_4, x_io_out_0_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_0_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_0_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_0_bits_vpu_fpu_isFoldTo1_8, x_io_out_0_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_0_bits_vpu_nf !== x_io_out_0_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_nf g=%h x=%h", $time, g_io_out_0_bits_vpu_nf, x_io_out_0_bits_vpu_nf); end
    if (g_io_out_0_bits_vpu_veew !== x_io_out_0_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_veew g=%h x=%h", $time, g_io_out_0_bits_vpu_veew, x_io_out_0_bits_vpu_veew); end
    if (g_io_out_0_bits_vpu_isReverse !== x_io_out_0_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_0_bits_vpu_isReverse, x_io_out_0_bits_vpu_isReverse); end
    if (g_io_out_0_bits_vpu_isExt !== x_io_out_0_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isExt g=%h x=%h", $time, g_io_out_0_bits_vpu_isExt, x_io_out_0_bits_vpu_isExt); end
    if (g_io_out_0_bits_vpu_isNarrow !== x_io_out_0_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_0_bits_vpu_isNarrow, x_io_out_0_bits_vpu_isNarrow); end
    if (g_io_out_0_bits_vpu_isDstMask !== x_io_out_0_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_0_bits_vpu_isDstMask, x_io_out_0_bits_vpu_isDstMask); end
    if (g_io_out_0_bits_vpu_isOpMask !== x_io_out_0_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_0_bits_vpu_isOpMask, x_io_out_0_bits_vpu_isOpMask); end
    if (g_io_out_0_bits_vpu_isDependOldVd !== x_io_out_0_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_0_bits_vpu_isDependOldVd, x_io_out_0_bits_vpu_isDependOldVd); end
    if (g_io_out_0_bits_vpu_isWritePartVd !== x_io_out_0_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_0_bits_vpu_isWritePartVd, x_io_out_0_bits_vpu_isWritePartVd); end
    if (g_io_out_0_bits_vpu_isVleff !== x_io_out_0_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_0_bits_vpu_isVleff, x_io_out_0_bits_vpu_isVleff); end
    if (g_io_out_0_bits_vlsInstr !== x_io_out_0_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_vlsInstr g=%h x=%h", $time, g_io_out_0_bits_vlsInstr, x_io_out_0_bits_vlsInstr); end
    if (g_io_out_0_bits_wfflags !== x_io_out_0_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_wfflags g=%h x=%h", $time, g_io_out_0_bits_wfflags, x_io_out_0_bits_wfflags); end
    if (g_io_out_0_bits_isMove !== x_io_out_0_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_isMove g=%h x=%h", $time, g_io_out_0_bits_isMove, x_io_out_0_bits_isMove); end
    if (g_io_out_0_bits_uopIdx !== x_io_out_0_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_uopIdx g=%h x=%h", $time, g_io_out_0_bits_uopIdx, x_io_out_0_bits_uopIdx); end
    if (g_io_out_0_bits_uopSplitType !== x_io_out_0_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_uopSplitType g=%h x=%h", $time, g_io_out_0_bits_uopSplitType, x_io_out_0_bits_uopSplitType); end
    if (g_io_out_0_bits_isVset !== x_io_out_0_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_isVset g=%h x=%h", $time, g_io_out_0_bits_isVset, x_io_out_0_bits_isVset); end
    if (g_io_out_0_bits_firstUop !== x_io_out_0_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_firstUop g=%h x=%h", $time, g_io_out_0_bits_firstUop, x_io_out_0_bits_firstUop); end
    if (g_io_out_0_bits_lastUop !== x_io_out_0_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_lastUop g=%h x=%h", $time, g_io_out_0_bits_lastUop, x_io_out_0_bits_lastUop); end
    if (g_io_out_0_bits_numUops !== x_io_out_0_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_numUops g=%h x=%h", $time, g_io_out_0_bits_numUops, x_io_out_0_bits_numUops); end
    if (g_io_out_0_bits_numWB !== x_io_out_0_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_numWB g=%h x=%h", $time, g_io_out_0_bits_numWB, x_io_out_0_bits_numWB); end
    if (g_io_out_0_bits_commitType !== x_io_out_0_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_commitType g=%h x=%h", $time, g_io_out_0_bits_commitType, x_io_out_0_bits_commitType); end
    if (g_io_out_0_bits_debug_fuType !== x_io_out_0_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_debug_fuType g=%h x=%h", $time, g_io_out_0_bits_debug_fuType, x_io_out_0_bits_debug_fuType); end
    if (g_io_out_0_bits_debug_seqNum_seqNum !== x_io_out_0_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_0_bits_debug_seqNum_seqNum, x_io_out_0_bits_debug_seqNum_seqNum); end
    if (g_io_out_0_bits_debug_seqNum_uopIdx !== x_io_out_0_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_0_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_0_bits_debug_seqNum_uopIdx, x_io_out_0_bits_debug_seqNum_uopIdx); end
    if (g_io_out_1_valid !== x_io_out_1_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_valid g=%h x=%h", $time, g_io_out_1_valid, x_io_out_1_valid); end
    if (g_io_out_1_bits_instr !== x_io_out_1_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_instr g=%h x=%h", $time, g_io_out_1_bits_instr, x_io_out_1_bits_instr); end
    if (g_io_out_1_bits_pc !== x_io_out_1_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_pc g=%h x=%h", $time, g_io_out_1_bits_pc, x_io_out_1_bits_pc); end
    if (g_io_out_1_bits_foldpc !== x_io_out_1_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_foldpc g=%h x=%h", $time, g_io_out_1_bits_foldpc, x_io_out_1_bits_foldpc); end
    if (g_io_out_1_bits_exceptionVec_0 !== x_io_out_1_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_0, x_io_out_1_bits_exceptionVec_0); end
    if (g_io_out_1_bits_exceptionVec_1 !== x_io_out_1_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_1, x_io_out_1_bits_exceptionVec_1); end
    if (g_io_out_1_bits_exceptionVec_2 !== x_io_out_1_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_2, x_io_out_1_bits_exceptionVec_2); end
    if (g_io_out_1_bits_exceptionVec_3 !== x_io_out_1_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_3, x_io_out_1_bits_exceptionVec_3); end
    if (g_io_out_1_bits_exceptionVec_4 !== x_io_out_1_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_4, x_io_out_1_bits_exceptionVec_4); end
    if (g_io_out_1_bits_exceptionVec_5 !== x_io_out_1_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_5, x_io_out_1_bits_exceptionVec_5); end
    if (g_io_out_1_bits_exceptionVec_6 !== x_io_out_1_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_6, x_io_out_1_bits_exceptionVec_6); end
    if (g_io_out_1_bits_exceptionVec_7 !== x_io_out_1_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_7, x_io_out_1_bits_exceptionVec_7); end
    if (g_io_out_1_bits_exceptionVec_8 !== x_io_out_1_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_8, x_io_out_1_bits_exceptionVec_8); end
    if (g_io_out_1_bits_exceptionVec_9 !== x_io_out_1_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_9, x_io_out_1_bits_exceptionVec_9); end
    if (g_io_out_1_bits_exceptionVec_10 !== x_io_out_1_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_10, x_io_out_1_bits_exceptionVec_10); end
    if (g_io_out_1_bits_exceptionVec_11 !== x_io_out_1_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_11, x_io_out_1_bits_exceptionVec_11); end
    if (g_io_out_1_bits_exceptionVec_12 !== x_io_out_1_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_12, x_io_out_1_bits_exceptionVec_12); end
    if (g_io_out_1_bits_exceptionVec_13 !== x_io_out_1_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_13, x_io_out_1_bits_exceptionVec_13); end
    if (g_io_out_1_bits_exceptionVec_14 !== x_io_out_1_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_14, x_io_out_1_bits_exceptionVec_14); end
    if (g_io_out_1_bits_exceptionVec_15 !== x_io_out_1_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_15, x_io_out_1_bits_exceptionVec_15); end
    if (g_io_out_1_bits_exceptionVec_16 !== x_io_out_1_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_16, x_io_out_1_bits_exceptionVec_16); end
    if (g_io_out_1_bits_exceptionVec_17 !== x_io_out_1_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_17, x_io_out_1_bits_exceptionVec_17); end
    if (g_io_out_1_bits_exceptionVec_18 !== x_io_out_1_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_18, x_io_out_1_bits_exceptionVec_18); end
    if (g_io_out_1_bits_exceptionVec_19 !== x_io_out_1_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_19, x_io_out_1_bits_exceptionVec_19); end
    if (g_io_out_1_bits_exceptionVec_20 !== x_io_out_1_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_20, x_io_out_1_bits_exceptionVec_20); end
    if (g_io_out_1_bits_exceptionVec_21 !== x_io_out_1_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_21, x_io_out_1_bits_exceptionVec_21); end
    if (g_io_out_1_bits_exceptionVec_22 !== x_io_out_1_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_22, x_io_out_1_bits_exceptionVec_22); end
    if (g_io_out_1_bits_exceptionVec_23 !== x_io_out_1_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_1_bits_exceptionVec_23, x_io_out_1_bits_exceptionVec_23); end
    if (g_io_out_1_bits_isFetchMalAddr !== x_io_out_1_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_1_bits_isFetchMalAddr, x_io_out_1_bits_isFetchMalAddr); end
    if (g_io_out_1_bits_trigger !== x_io_out_1_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_trigger g=%h x=%h", $time, g_io_out_1_bits_trigger, x_io_out_1_bits_trigger); end
    if (g_io_out_1_bits_preDecodeInfo_valid !== x_io_out_1_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_1_bits_preDecodeInfo_valid, x_io_out_1_bits_preDecodeInfo_valid); end
    if (g_io_out_1_bits_preDecodeInfo_isRVC !== x_io_out_1_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_1_bits_preDecodeInfo_isRVC, x_io_out_1_bits_preDecodeInfo_isRVC); end
    if (g_io_out_1_bits_preDecodeInfo_brType !== x_io_out_1_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_1_bits_preDecodeInfo_brType, x_io_out_1_bits_preDecodeInfo_brType); end
    if (g_io_out_1_bits_preDecodeInfo_isCall !== x_io_out_1_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_1_bits_preDecodeInfo_isCall, x_io_out_1_bits_preDecodeInfo_isCall); end
    if (g_io_out_1_bits_preDecodeInfo_isRet !== x_io_out_1_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_1_bits_preDecodeInfo_isRet, x_io_out_1_bits_preDecodeInfo_isRet); end
    if (g_io_out_1_bits_pred_taken !== x_io_out_1_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_pred_taken g=%h x=%h", $time, g_io_out_1_bits_pred_taken, x_io_out_1_bits_pred_taken); end
    if (g_io_out_1_bits_crossPageIPFFix !== x_io_out_1_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_1_bits_crossPageIPFFix, x_io_out_1_bits_crossPageIPFFix); end
    if (g_io_out_1_bits_ftqPtr_flag !== x_io_out_1_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_1_bits_ftqPtr_flag, x_io_out_1_bits_ftqPtr_flag); end
    if (g_io_out_1_bits_ftqPtr_value !== x_io_out_1_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_1_bits_ftqPtr_value, x_io_out_1_bits_ftqPtr_value); end
    if (g_io_out_1_bits_ftqOffset !== x_io_out_1_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_ftqOffset g=%h x=%h", $time, g_io_out_1_bits_ftqOffset, x_io_out_1_bits_ftqOffset); end
    if (g_io_out_1_bits_satpFlushFirstFetchFault !== x_io_out_1_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_1_bits_satpFlushFirstFetchFault, x_io_out_1_bits_satpFlushFirstFetchFault); end
    if (g_io_out_1_bits_srcType_0 !== x_io_out_1_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_srcType_0 g=%h x=%h", $time, g_io_out_1_bits_srcType_0, x_io_out_1_bits_srcType_0); end
    if (g_io_out_1_bits_srcType_1 !== x_io_out_1_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_srcType_1 g=%h x=%h", $time, g_io_out_1_bits_srcType_1, x_io_out_1_bits_srcType_1); end
    if (g_io_out_1_bits_srcType_2 !== x_io_out_1_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_srcType_2 g=%h x=%h", $time, g_io_out_1_bits_srcType_2, x_io_out_1_bits_srcType_2); end
    if (g_io_out_1_bits_srcType_3 !== x_io_out_1_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_srcType_3 g=%h x=%h", $time, g_io_out_1_bits_srcType_3, x_io_out_1_bits_srcType_3); end
    if (g_io_out_1_bits_srcType_4 !== x_io_out_1_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_srcType_4 g=%h x=%h", $time, g_io_out_1_bits_srcType_4, x_io_out_1_bits_srcType_4); end
    if (g_io_out_1_bits_lsrc_0 !== x_io_out_1_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_lsrc_0 g=%h x=%h", $time, g_io_out_1_bits_lsrc_0, x_io_out_1_bits_lsrc_0); end
    if (g_io_out_1_bits_lsrc_1 !== x_io_out_1_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_lsrc_1 g=%h x=%h", $time, g_io_out_1_bits_lsrc_1, x_io_out_1_bits_lsrc_1); end
    if (g_io_out_1_bits_lsrc_2 !== x_io_out_1_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_lsrc_2 g=%h x=%h", $time, g_io_out_1_bits_lsrc_2, x_io_out_1_bits_lsrc_2); end
    if (g_io_out_1_bits_ldest !== x_io_out_1_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_ldest g=%h x=%h", $time, g_io_out_1_bits_ldest, x_io_out_1_bits_ldest); end
    if (g_io_out_1_bits_fuType !== x_io_out_1_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fuType g=%h x=%h", $time, g_io_out_1_bits_fuType, x_io_out_1_bits_fuType); end
    if (g_io_out_1_bits_fuOpType !== x_io_out_1_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fuOpType g=%h x=%h", $time, g_io_out_1_bits_fuOpType, x_io_out_1_bits_fuOpType); end
    if (g_io_out_1_bits_rfWen !== x_io_out_1_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_rfWen g=%h x=%h", $time, g_io_out_1_bits_rfWen, x_io_out_1_bits_rfWen); end
    if (g_io_out_1_bits_fpWen !== x_io_out_1_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpWen g=%h x=%h", $time, g_io_out_1_bits_fpWen, x_io_out_1_bits_fpWen); end
    if (g_io_out_1_bits_vecWen !== x_io_out_1_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vecWen g=%h x=%h", $time, g_io_out_1_bits_vecWen, x_io_out_1_bits_vecWen); end
    if (g_io_out_1_bits_v0Wen !== x_io_out_1_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_v0Wen g=%h x=%h", $time, g_io_out_1_bits_v0Wen, x_io_out_1_bits_v0Wen); end
    if (g_io_out_1_bits_vlWen !== x_io_out_1_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vlWen g=%h x=%h", $time, g_io_out_1_bits_vlWen, x_io_out_1_bits_vlWen); end
    if (g_io_out_1_bits_isXSTrap !== x_io_out_1_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_isXSTrap g=%h x=%h", $time, g_io_out_1_bits_isXSTrap, x_io_out_1_bits_isXSTrap); end
    if (g_io_out_1_bits_waitForward !== x_io_out_1_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_waitForward g=%h x=%h", $time, g_io_out_1_bits_waitForward, x_io_out_1_bits_waitForward); end
    if (g_io_out_1_bits_blockBackward !== x_io_out_1_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_blockBackward g=%h x=%h", $time, g_io_out_1_bits_blockBackward, x_io_out_1_bits_blockBackward); end
    if (g_io_out_1_bits_flushPipe !== x_io_out_1_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_flushPipe g=%h x=%h", $time, g_io_out_1_bits_flushPipe, x_io_out_1_bits_flushPipe); end
    if (g_io_out_1_bits_canRobCompress !== x_io_out_1_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_canRobCompress g=%h x=%h", $time, g_io_out_1_bits_canRobCompress, x_io_out_1_bits_canRobCompress); end
    if (g_io_out_1_bits_selImm !== x_io_out_1_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_selImm g=%h x=%h", $time, g_io_out_1_bits_selImm, x_io_out_1_bits_selImm); end
    if (g_io_out_1_bits_imm !== x_io_out_1_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_imm g=%h x=%h", $time, g_io_out_1_bits_imm, x_io_out_1_bits_imm); end
    if (g_io_out_1_bits_fpu_typeTagOut !== x_io_out_1_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_1_bits_fpu_typeTagOut, x_io_out_1_bits_fpu_typeTagOut); end
    if (g_io_out_1_bits_fpu_wflags !== x_io_out_1_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpu_wflags g=%h x=%h", $time, g_io_out_1_bits_fpu_wflags, x_io_out_1_bits_fpu_wflags); end
    if (g_io_out_1_bits_fpu_typ !== x_io_out_1_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpu_typ g=%h x=%h", $time, g_io_out_1_bits_fpu_typ, x_io_out_1_bits_fpu_typ); end
    if (g_io_out_1_bits_fpu_fmt !== x_io_out_1_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpu_fmt g=%h x=%h", $time, g_io_out_1_bits_fpu_fmt, x_io_out_1_bits_fpu_fmt); end
    if (g_io_out_1_bits_fpu_rm !== x_io_out_1_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_fpu_rm g=%h x=%h", $time, g_io_out_1_bits_fpu_rm, x_io_out_1_bits_fpu_rm); end
    if (g_io_out_1_bits_vpu_vill !== x_io_out_1_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vill g=%h x=%h", $time, g_io_out_1_bits_vpu_vill, x_io_out_1_bits_vpu_vill); end
    if (g_io_out_1_bits_vpu_vma !== x_io_out_1_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vma g=%h x=%h", $time, g_io_out_1_bits_vpu_vma, x_io_out_1_bits_vpu_vma); end
    if (g_io_out_1_bits_vpu_vta !== x_io_out_1_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vta g=%h x=%h", $time, g_io_out_1_bits_vpu_vta, x_io_out_1_bits_vpu_vta); end
    if (g_io_out_1_bits_vpu_vsew !== x_io_out_1_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vsew g=%h x=%h", $time, g_io_out_1_bits_vpu_vsew, x_io_out_1_bits_vpu_vsew); end
    if (g_io_out_1_bits_vpu_vlmul !== x_io_out_1_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_1_bits_vpu_vlmul, x_io_out_1_bits_vpu_vlmul); end
    if (g_io_out_1_bits_vpu_specVill !== x_io_out_1_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_specVill g=%h x=%h", $time, g_io_out_1_bits_vpu_specVill, x_io_out_1_bits_vpu_specVill); end
    if (g_io_out_1_bits_vpu_specVma !== x_io_out_1_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_specVma g=%h x=%h", $time, g_io_out_1_bits_vpu_specVma, x_io_out_1_bits_vpu_specVma); end
    if (g_io_out_1_bits_vpu_specVta !== x_io_out_1_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_specVta g=%h x=%h", $time, g_io_out_1_bits_vpu_specVta, x_io_out_1_bits_vpu_specVta); end
    if (g_io_out_1_bits_vpu_specVsew !== x_io_out_1_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_1_bits_vpu_specVsew, x_io_out_1_bits_vpu_specVsew); end
    if (g_io_out_1_bits_vpu_specVlmul !== x_io_out_1_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_1_bits_vpu_specVlmul, x_io_out_1_bits_vpu_specVlmul); end
    if (g_io_out_1_bits_vpu_vm !== x_io_out_1_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vm g=%h x=%h", $time, g_io_out_1_bits_vpu_vm, x_io_out_1_bits_vpu_vm); end
    if (g_io_out_1_bits_vpu_vstart !== x_io_out_1_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_vstart g=%h x=%h", $time, g_io_out_1_bits_vpu_vstart, x_io_out_1_bits_vpu_vstart); end
    if (g_io_out_1_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_1_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_1_bits_vpu_fpu_isFoldTo1_2, x_io_out_1_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_1_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_1_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_1_bits_vpu_fpu_isFoldTo1_4, x_io_out_1_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_1_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_1_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_1_bits_vpu_fpu_isFoldTo1_8, x_io_out_1_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_1_bits_vpu_nf !== x_io_out_1_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_nf g=%h x=%h", $time, g_io_out_1_bits_vpu_nf, x_io_out_1_bits_vpu_nf); end
    if (g_io_out_1_bits_vpu_veew !== x_io_out_1_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_veew g=%h x=%h", $time, g_io_out_1_bits_vpu_veew, x_io_out_1_bits_vpu_veew); end
    if (g_io_out_1_bits_vpu_isReverse !== x_io_out_1_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_1_bits_vpu_isReverse, x_io_out_1_bits_vpu_isReverse); end
    if (g_io_out_1_bits_vpu_isExt !== x_io_out_1_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isExt g=%h x=%h", $time, g_io_out_1_bits_vpu_isExt, x_io_out_1_bits_vpu_isExt); end
    if (g_io_out_1_bits_vpu_isNarrow !== x_io_out_1_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_1_bits_vpu_isNarrow, x_io_out_1_bits_vpu_isNarrow); end
    if (g_io_out_1_bits_vpu_isDstMask !== x_io_out_1_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_1_bits_vpu_isDstMask, x_io_out_1_bits_vpu_isDstMask); end
    if (g_io_out_1_bits_vpu_isOpMask !== x_io_out_1_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_1_bits_vpu_isOpMask, x_io_out_1_bits_vpu_isOpMask); end
    if (g_io_out_1_bits_vpu_isDependOldVd !== x_io_out_1_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_1_bits_vpu_isDependOldVd, x_io_out_1_bits_vpu_isDependOldVd); end
    if (g_io_out_1_bits_vpu_isWritePartVd !== x_io_out_1_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_1_bits_vpu_isWritePartVd, x_io_out_1_bits_vpu_isWritePartVd); end
    if (g_io_out_1_bits_vpu_isVleff !== x_io_out_1_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_1_bits_vpu_isVleff, x_io_out_1_bits_vpu_isVleff); end
    if (g_io_out_1_bits_vlsInstr !== x_io_out_1_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_vlsInstr g=%h x=%h", $time, g_io_out_1_bits_vlsInstr, x_io_out_1_bits_vlsInstr); end
    if (g_io_out_1_bits_wfflags !== x_io_out_1_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_wfflags g=%h x=%h", $time, g_io_out_1_bits_wfflags, x_io_out_1_bits_wfflags); end
    if (g_io_out_1_bits_isMove !== x_io_out_1_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_isMove g=%h x=%h", $time, g_io_out_1_bits_isMove, x_io_out_1_bits_isMove); end
    if (g_io_out_1_bits_uopIdx !== x_io_out_1_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_uopIdx g=%h x=%h", $time, g_io_out_1_bits_uopIdx, x_io_out_1_bits_uopIdx); end
    if (g_io_out_1_bits_uopSplitType !== x_io_out_1_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_uopSplitType g=%h x=%h", $time, g_io_out_1_bits_uopSplitType, x_io_out_1_bits_uopSplitType); end
    if (g_io_out_1_bits_isVset !== x_io_out_1_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_isVset g=%h x=%h", $time, g_io_out_1_bits_isVset, x_io_out_1_bits_isVset); end
    if (g_io_out_1_bits_firstUop !== x_io_out_1_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_firstUop g=%h x=%h", $time, g_io_out_1_bits_firstUop, x_io_out_1_bits_firstUop); end
    if (g_io_out_1_bits_lastUop !== x_io_out_1_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_lastUop g=%h x=%h", $time, g_io_out_1_bits_lastUop, x_io_out_1_bits_lastUop); end
    if (g_io_out_1_bits_numUops !== x_io_out_1_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_numUops g=%h x=%h", $time, g_io_out_1_bits_numUops, x_io_out_1_bits_numUops); end
    if (g_io_out_1_bits_numWB !== x_io_out_1_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_numWB g=%h x=%h", $time, g_io_out_1_bits_numWB, x_io_out_1_bits_numWB); end
    if (g_io_out_1_bits_commitType !== x_io_out_1_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_commitType g=%h x=%h", $time, g_io_out_1_bits_commitType, x_io_out_1_bits_commitType); end
    if (g_io_out_1_bits_debug_fuType !== x_io_out_1_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_debug_fuType g=%h x=%h", $time, g_io_out_1_bits_debug_fuType, x_io_out_1_bits_debug_fuType); end
    if (g_io_out_1_bits_debug_seqNum_seqNum !== x_io_out_1_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_1_bits_debug_seqNum_seqNum, x_io_out_1_bits_debug_seqNum_seqNum); end
    if (g_io_out_1_bits_debug_seqNum_uopIdx !== x_io_out_1_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_1_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_1_bits_debug_seqNum_uopIdx, x_io_out_1_bits_debug_seqNum_uopIdx); end
    if (g_io_out_2_valid !== x_io_out_2_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_valid g=%h x=%h", $time, g_io_out_2_valid, x_io_out_2_valid); end
    if (g_io_out_2_bits_instr !== x_io_out_2_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_instr g=%h x=%h", $time, g_io_out_2_bits_instr, x_io_out_2_bits_instr); end
    if (g_io_out_2_bits_pc !== x_io_out_2_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_pc g=%h x=%h", $time, g_io_out_2_bits_pc, x_io_out_2_bits_pc); end
    if (g_io_out_2_bits_foldpc !== x_io_out_2_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_foldpc g=%h x=%h", $time, g_io_out_2_bits_foldpc, x_io_out_2_bits_foldpc); end
    if (g_io_out_2_bits_exceptionVec_0 !== x_io_out_2_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_0, x_io_out_2_bits_exceptionVec_0); end
    if (g_io_out_2_bits_exceptionVec_1 !== x_io_out_2_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_1, x_io_out_2_bits_exceptionVec_1); end
    if (g_io_out_2_bits_exceptionVec_2 !== x_io_out_2_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_2, x_io_out_2_bits_exceptionVec_2); end
    if (g_io_out_2_bits_exceptionVec_3 !== x_io_out_2_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_3, x_io_out_2_bits_exceptionVec_3); end
    if (g_io_out_2_bits_exceptionVec_4 !== x_io_out_2_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_4, x_io_out_2_bits_exceptionVec_4); end
    if (g_io_out_2_bits_exceptionVec_5 !== x_io_out_2_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_5, x_io_out_2_bits_exceptionVec_5); end
    if (g_io_out_2_bits_exceptionVec_6 !== x_io_out_2_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_6, x_io_out_2_bits_exceptionVec_6); end
    if (g_io_out_2_bits_exceptionVec_7 !== x_io_out_2_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_7, x_io_out_2_bits_exceptionVec_7); end
    if (g_io_out_2_bits_exceptionVec_8 !== x_io_out_2_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_8, x_io_out_2_bits_exceptionVec_8); end
    if (g_io_out_2_bits_exceptionVec_9 !== x_io_out_2_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_9, x_io_out_2_bits_exceptionVec_9); end
    if (g_io_out_2_bits_exceptionVec_10 !== x_io_out_2_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_10, x_io_out_2_bits_exceptionVec_10); end
    if (g_io_out_2_bits_exceptionVec_11 !== x_io_out_2_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_11, x_io_out_2_bits_exceptionVec_11); end
    if (g_io_out_2_bits_exceptionVec_12 !== x_io_out_2_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_12, x_io_out_2_bits_exceptionVec_12); end
    if (g_io_out_2_bits_exceptionVec_13 !== x_io_out_2_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_13, x_io_out_2_bits_exceptionVec_13); end
    if (g_io_out_2_bits_exceptionVec_14 !== x_io_out_2_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_14, x_io_out_2_bits_exceptionVec_14); end
    if (g_io_out_2_bits_exceptionVec_15 !== x_io_out_2_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_15, x_io_out_2_bits_exceptionVec_15); end
    if (g_io_out_2_bits_exceptionVec_16 !== x_io_out_2_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_16, x_io_out_2_bits_exceptionVec_16); end
    if (g_io_out_2_bits_exceptionVec_17 !== x_io_out_2_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_17, x_io_out_2_bits_exceptionVec_17); end
    if (g_io_out_2_bits_exceptionVec_18 !== x_io_out_2_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_18, x_io_out_2_bits_exceptionVec_18); end
    if (g_io_out_2_bits_exceptionVec_19 !== x_io_out_2_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_19, x_io_out_2_bits_exceptionVec_19); end
    if (g_io_out_2_bits_exceptionVec_20 !== x_io_out_2_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_20, x_io_out_2_bits_exceptionVec_20); end
    if (g_io_out_2_bits_exceptionVec_21 !== x_io_out_2_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_21, x_io_out_2_bits_exceptionVec_21); end
    if (g_io_out_2_bits_exceptionVec_22 !== x_io_out_2_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_22, x_io_out_2_bits_exceptionVec_22); end
    if (g_io_out_2_bits_exceptionVec_23 !== x_io_out_2_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_2_bits_exceptionVec_23, x_io_out_2_bits_exceptionVec_23); end
    if (g_io_out_2_bits_isFetchMalAddr !== x_io_out_2_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_2_bits_isFetchMalAddr, x_io_out_2_bits_isFetchMalAddr); end
    if (g_io_out_2_bits_trigger !== x_io_out_2_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_trigger g=%h x=%h", $time, g_io_out_2_bits_trigger, x_io_out_2_bits_trigger); end
    if (g_io_out_2_bits_preDecodeInfo_valid !== x_io_out_2_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_2_bits_preDecodeInfo_valid, x_io_out_2_bits_preDecodeInfo_valid); end
    if (g_io_out_2_bits_preDecodeInfo_isRVC !== x_io_out_2_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_2_bits_preDecodeInfo_isRVC, x_io_out_2_bits_preDecodeInfo_isRVC); end
    if (g_io_out_2_bits_preDecodeInfo_brType !== x_io_out_2_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_2_bits_preDecodeInfo_brType, x_io_out_2_bits_preDecodeInfo_brType); end
    if (g_io_out_2_bits_preDecodeInfo_isCall !== x_io_out_2_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_2_bits_preDecodeInfo_isCall, x_io_out_2_bits_preDecodeInfo_isCall); end
    if (g_io_out_2_bits_preDecodeInfo_isRet !== x_io_out_2_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_2_bits_preDecodeInfo_isRet, x_io_out_2_bits_preDecodeInfo_isRet); end
    if (g_io_out_2_bits_pred_taken !== x_io_out_2_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_pred_taken g=%h x=%h", $time, g_io_out_2_bits_pred_taken, x_io_out_2_bits_pred_taken); end
    if (g_io_out_2_bits_crossPageIPFFix !== x_io_out_2_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_2_bits_crossPageIPFFix, x_io_out_2_bits_crossPageIPFFix); end
    if (g_io_out_2_bits_ftqPtr_flag !== x_io_out_2_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_2_bits_ftqPtr_flag, x_io_out_2_bits_ftqPtr_flag); end
    if (g_io_out_2_bits_ftqPtr_value !== x_io_out_2_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_2_bits_ftqPtr_value, x_io_out_2_bits_ftqPtr_value); end
    if (g_io_out_2_bits_ftqOffset !== x_io_out_2_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_ftqOffset g=%h x=%h", $time, g_io_out_2_bits_ftqOffset, x_io_out_2_bits_ftqOffset); end
    if (g_io_out_2_bits_satpFlushFirstFetchFault !== x_io_out_2_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_2_bits_satpFlushFirstFetchFault, x_io_out_2_bits_satpFlushFirstFetchFault); end
    if (g_io_out_2_bits_srcType_0 !== x_io_out_2_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_srcType_0 g=%h x=%h", $time, g_io_out_2_bits_srcType_0, x_io_out_2_bits_srcType_0); end
    if (g_io_out_2_bits_srcType_1 !== x_io_out_2_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_srcType_1 g=%h x=%h", $time, g_io_out_2_bits_srcType_1, x_io_out_2_bits_srcType_1); end
    if (g_io_out_2_bits_srcType_2 !== x_io_out_2_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_srcType_2 g=%h x=%h", $time, g_io_out_2_bits_srcType_2, x_io_out_2_bits_srcType_2); end
    if (g_io_out_2_bits_srcType_3 !== x_io_out_2_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_srcType_3 g=%h x=%h", $time, g_io_out_2_bits_srcType_3, x_io_out_2_bits_srcType_3); end
    if (g_io_out_2_bits_srcType_4 !== x_io_out_2_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_srcType_4 g=%h x=%h", $time, g_io_out_2_bits_srcType_4, x_io_out_2_bits_srcType_4); end
    if (g_io_out_2_bits_lsrc_0 !== x_io_out_2_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_lsrc_0 g=%h x=%h", $time, g_io_out_2_bits_lsrc_0, x_io_out_2_bits_lsrc_0); end
    if (g_io_out_2_bits_lsrc_1 !== x_io_out_2_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_lsrc_1 g=%h x=%h", $time, g_io_out_2_bits_lsrc_1, x_io_out_2_bits_lsrc_1); end
    if (g_io_out_2_bits_lsrc_2 !== x_io_out_2_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_lsrc_2 g=%h x=%h", $time, g_io_out_2_bits_lsrc_2, x_io_out_2_bits_lsrc_2); end
    if (g_io_out_2_bits_ldest !== x_io_out_2_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_ldest g=%h x=%h", $time, g_io_out_2_bits_ldest, x_io_out_2_bits_ldest); end
    if (g_io_out_2_bits_fuType !== x_io_out_2_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fuType g=%h x=%h", $time, g_io_out_2_bits_fuType, x_io_out_2_bits_fuType); end
    if (g_io_out_2_bits_fuOpType !== x_io_out_2_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fuOpType g=%h x=%h", $time, g_io_out_2_bits_fuOpType, x_io_out_2_bits_fuOpType); end
    if (g_io_out_2_bits_rfWen !== x_io_out_2_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_rfWen g=%h x=%h", $time, g_io_out_2_bits_rfWen, x_io_out_2_bits_rfWen); end
    if (g_io_out_2_bits_fpWen !== x_io_out_2_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpWen g=%h x=%h", $time, g_io_out_2_bits_fpWen, x_io_out_2_bits_fpWen); end
    if (g_io_out_2_bits_vecWen !== x_io_out_2_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vecWen g=%h x=%h", $time, g_io_out_2_bits_vecWen, x_io_out_2_bits_vecWen); end
    if (g_io_out_2_bits_v0Wen !== x_io_out_2_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_v0Wen g=%h x=%h", $time, g_io_out_2_bits_v0Wen, x_io_out_2_bits_v0Wen); end
    if (g_io_out_2_bits_vlWen !== x_io_out_2_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vlWen g=%h x=%h", $time, g_io_out_2_bits_vlWen, x_io_out_2_bits_vlWen); end
    if (g_io_out_2_bits_isXSTrap !== x_io_out_2_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_isXSTrap g=%h x=%h", $time, g_io_out_2_bits_isXSTrap, x_io_out_2_bits_isXSTrap); end
    if (g_io_out_2_bits_waitForward !== x_io_out_2_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_waitForward g=%h x=%h", $time, g_io_out_2_bits_waitForward, x_io_out_2_bits_waitForward); end
    if (g_io_out_2_bits_blockBackward !== x_io_out_2_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_blockBackward g=%h x=%h", $time, g_io_out_2_bits_blockBackward, x_io_out_2_bits_blockBackward); end
    if (g_io_out_2_bits_flushPipe !== x_io_out_2_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_flushPipe g=%h x=%h", $time, g_io_out_2_bits_flushPipe, x_io_out_2_bits_flushPipe); end
    if (g_io_out_2_bits_canRobCompress !== x_io_out_2_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_canRobCompress g=%h x=%h", $time, g_io_out_2_bits_canRobCompress, x_io_out_2_bits_canRobCompress); end
    if (g_io_out_2_bits_selImm !== x_io_out_2_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_selImm g=%h x=%h", $time, g_io_out_2_bits_selImm, x_io_out_2_bits_selImm); end
    if (g_io_out_2_bits_imm !== x_io_out_2_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_imm g=%h x=%h", $time, g_io_out_2_bits_imm, x_io_out_2_bits_imm); end
    if (g_io_out_2_bits_fpu_typeTagOut !== x_io_out_2_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_2_bits_fpu_typeTagOut, x_io_out_2_bits_fpu_typeTagOut); end
    if (g_io_out_2_bits_fpu_wflags !== x_io_out_2_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpu_wflags g=%h x=%h", $time, g_io_out_2_bits_fpu_wflags, x_io_out_2_bits_fpu_wflags); end
    if (g_io_out_2_bits_fpu_typ !== x_io_out_2_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpu_typ g=%h x=%h", $time, g_io_out_2_bits_fpu_typ, x_io_out_2_bits_fpu_typ); end
    if (g_io_out_2_bits_fpu_fmt !== x_io_out_2_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpu_fmt g=%h x=%h", $time, g_io_out_2_bits_fpu_fmt, x_io_out_2_bits_fpu_fmt); end
    if (g_io_out_2_bits_fpu_rm !== x_io_out_2_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_fpu_rm g=%h x=%h", $time, g_io_out_2_bits_fpu_rm, x_io_out_2_bits_fpu_rm); end
    if (g_io_out_2_bits_vpu_vill !== x_io_out_2_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vill g=%h x=%h", $time, g_io_out_2_bits_vpu_vill, x_io_out_2_bits_vpu_vill); end
    if (g_io_out_2_bits_vpu_vma !== x_io_out_2_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vma g=%h x=%h", $time, g_io_out_2_bits_vpu_vma, x_io_out_2_bits_vpu_vma); end
    if (g_io_out_2_bits_vpu_vta !== x_io_out_2_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vta g=%h x=%h", $time, g_io_out_2_bits_vpu_vta, x_io_out_2_bits_vpu_vta); end
    if (g_io_out_2_bits_vpu_vsew !== x_io_out_2_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vsew g=%h x=%h", $time, g_io_out_2_bits_vpu_vsew, x_io_out_2_bits_vpu_vsew); end
    if (g_io_out_2_bits_vpu_vlmul !== x_io_out_2_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_2_bits_vpu_vlmul, x_io_out_2_bits_vpu_vlmul); end
    if (g_io_out_2_bits_vpu_specVill !== x_io_out_2_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_specVill g=%h x=%h", $time, g_io_out_2_bits_vpu_specVill, x_io_out_2_bits_vpu_specVill); end
    if (g_io_out_2_bits_vpu_specVma !== x_io_out_2_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_specVma g=%h x=%h", $time, g_io_out_2_bits_vpu_specVma, x_io_out_2_bits_vpu_specVma); end
    if (g_io_out_2_bits_vpu_specVta !== x_io_out_2_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_specVta g=%h x=%h", $time, g_io_out_2_bits_vpu_specVta, x_io_out_2_bits_vpu_specVta); end
    if (g_io_out_2_bits_vpu_specVsew !== x_io_out_2_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_2_bits_vpu_specVsew, x_io_out_2_bits_vpu_specVsew); end
    if (g_io_out_2_bits_vpu_specVlmul !== x_io_out_2_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_2_bits_vpu_specVlmul, x_io_out_2_bits_vpu_specVlmul); end
    if (g_io_out_2_bits_vpu_vm !== x_io_out_2_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vm g=%h x=%h", $time, g_io_out_2_bits_vpu_vm, x_io_out_2_bits_vpu_vm); end
    if (g_io_out_2_bits_vpu_vstart !== x_io_out_2_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_vstart g=%h x=%h", $time, g_io_out_2_bits_vpu_vstart, x_io_out_2_bits_vpu_vstart); end
    if (g_io_out_2_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_2_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_2_bits_vpu_fpu_isFoldTo1_2, x_io_out_2_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_2_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_2_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_2_bits_vpu_fpu_isFoldTo1_4, x_io_out_2_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_2_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_2_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_2_bits_vpu_fpu_isFoldTo1_8, x_io_out_2_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_2_bits_vpu_nf !== x_io_out_2_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_nf g=%h x=%h", $time, g_io_out_2_bits_vpu_nf, x_io_out_2_bits_vpu_nf); end
    if (g_io_out_2_bits_vpu_veew !== x_io_out_2_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_veew g=%h x=%h", $time, g_io_out_2_bits_vpu_veew, x_io_out_2_bits_vpu_veew); end
    if (g_io_out_2_bits_vpu_isReverse !== x_io_out_2_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_2_bits_vpu_isReverse, x_io_out_2_bits_vpu_isReverse); end
    if (g_io_out_2_bits_vpu_isExt !== x_io_out_2_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isExt g=%h x=%h", $time, g_io_out_2_bits_vpu_isExt, x_io_out_2_bits_vpu_isExt); end
    if (g_io_out_2_bits_vpu_isNarrow !== x_io_out_2_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_2_bits_vpu_isNarrow, x_io_out_2_bits_vpu_isNarrow); end
    if (g_io_out_2_bits_vpu_isDstMask !== x_io_out_2_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_2_bits_vpu_isDstMask, x_io_out_2_bits_vpu_isDstMask); end
    if (g_io_out_2_bits_vpu_isOpMask !== x_io_out_2_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_2_bits_vpu_isOpMask, x_io_out_2_bits_vpu_isOpMask); end
    if (g_io_out_2_bits_vpu_isDependOldVd !== x_io_out_2_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_2_bits_vpu_isDependOldVd, x_io_out_2_bits_vpu_isDependOldVd); end
    if (g_io_out_2_bits_vpu_isWritePartVd !== x_io_out_2_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_2_bits_vpu_isWritePartVd, x_io_out_2_bits_vpu_isWritePartVd); end
    if (g_io_out_2_bits_vpu_isVleff !== x_io_out_2_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_2_bits_vpu_isVleff, x_io_out_2_bits_vpu_isVleff); end
    if (g_io_out_2_bits_vlsInstr !== x_io_out_2_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_vlsInstr g=%h x=%h", $time, g_io_out_2_bits_vlsInstr, x_io_out_2_bits_vlsInstr); end
    if (g_io_out_2_bits_wfflags !== x_io_out_2_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_wfflags g=%h x=%h", $time, g_io_out_2_bits_wfflags, x_io_out_2_bits_wfflags); end
    if (g_io_out_2_bits_isMove !== x_io_out_2_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_isMove g=%h x=%h", $time, g_io_out_2_bits_isMove, x_io_out_2_bits_isMove); end
    if (g_io_out_2_bits_uopIdx !== x_io_out_2_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_uopIdx g=%h x=%h", $time, g_io_out_2_bits_uopIdx, x_io_out_2_bits_uopIdx); end
    if (g_io_out_2_bits_uopSplitType !== x_io_out_2_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_uopSplitType g=%h x=%h", $time, g_io_out_2_bits_uopSplitType, x_io_out_2_bits_uopSplitType); end
    if (g_io_out_2_bits_isVset !== x_io_out_2_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_isVset g=%h x=%h", $time, g_io_out_2_bits_isVset, x_io_out_2_bits_isVset); end
    if (g_io_out_2_bits_firstUop !== x_io_out_2_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_firstUop g=%h x=%h", $time, g_io_out_2_bits_firstUop, x_io_out_2_bits_firstUop); end
    if (g_io_out_2_bits_lastUop !== x_io_out_2_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_lastUop g=%h x=%h", $time, g_io_out_2_bits_lastUop, x_io_out_2_bits_lastUop); end
    if (g_io_out_2_bits_numUops !== x_io_out_2_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_numUops g=%h x=%h", $time, g_io_out_2_bits_numUops, x_io_out_2_bits_numUops); end
    if (g_io_out_2_bits_numWB !== x_io_out_2_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_numWB g=%h x=%h", $time, g_io_out_2_bits_numWB, x_io_out_2_bits_numWB); end
    if (g_io_out_2_bits_commitType !== x_io_out_2_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_commitType g=%h x=%h", $time, g_io_out_2_bits_commitType, x_io_out_2_bits_commitType); end
    if (g_io_out_2_bits_debug_fuType !== x_io_out_2_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_debug_fuType g=%h x=%h", $time, g_io_out_2_bits_debug_fuType, x_io_out_2_bits_debug_fuType); end
    if (g_io_out_2_bits_debug_seqNum_seqNum !== x_io_out_2_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_2_bits_debug_seqNum_seqNum, x_io_out_2_bits_debug_seqNum_seqNum); end
    if (g_io_out_2_bits_debug_seqNum_uopIdx !== x_io_out_2_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_2_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_2_bits_debug_seqNum_uopIdx, x_io_out_2_bits_debug_seqNum_uopIdx); end
    if (g_io_out_3_valid !== x_io_out_3_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_valid g=%h x=%h", $time, g_io_out_3_valid, x_io_out_3_valid); end
    if (g_io_out_3_bits_instr !== x_io_out_3_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_instr g=%h x=%h", $time, g_io_out_3_bits_instr, x_io_out_3_bits_instr); end
    if (g_io_out_3_bits_pc !== x_io_out_3_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_pc g=%h x=%h", $time, g_io_out_3_bits_pc, x_io_out_3_bits_pc); end
    if (g_io_out_3_bits_foldpc !== x_io_out_3_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_foldpc g=%h x=%h", $time, g_io_out_3_bits_foldpc, x_io_out_3_bits_foldpc); end
    if (g_io_out_3_bits_exceptionVec_0 !== x_io_out_3_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_0, x_io_out_3_bits_exceptionVec_0); end
    if (g_io_out_3_bits_exceptionVec_1 !== x_io_out_3_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_1, x_io_out_3_bits_exceptionVec_1); end
    if (g_io_out_3_bits_exceptionVec_2 !== x_io_out_3_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_2, x_io_out_3_bits_exceptionVec_2); end
    if (g_io_out_3_bits_exceptionVec_3 !== x_io_out_3_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_3, x_io_out_3_bits_exceptionVec_3); end
    if (g_io_out_3_bits_exceptionVec_4 !== x_io_out_3_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_4, x_io_out_3_bits_exceptionVec_4); end
    if (g_io_out_3_bits_exceptionVec_5 !== x_io_out_3_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_5, x_io_out_3_bits_exceptionVec_5); end
    if (g_io_out_3_bits_exceptionVec_6 !== x_io_out_3_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_6, x_io_out_3_bits_exceptionVec_6); end
    if (g_io_out_3_bits_exceptionVec_7 !== x_io_out_3_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_7, x_io_out_3_bits_exceptionVec_7); end
    if (g_io_out_3_bits_exceptionVec_8 !== x_io_out_3_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_8, x_io_out_3_bits_exceptionVec_8); end
    if (g_io_out_3_bits_exceptionVec_9 !== x_io_out_3_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_9, x_io_out_3_bits_exceptionVec_9); end
    if (g_io_out_3_bits_exceptionVec_10 !== x_io_out_3_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_10, x_io_out_3_bits_exceptionVec_10); end
    if (g_io_out_3_bits_exceptionVec_11 !== x_io_out_3_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_11, x_io_out_3_bits_exceptionVec_11); end
    if (g_io_out_3_bits_exceptionVec_12 !== x_io_out_3_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_12, x_io_out_3_bits_exceptionVec_12); end
    if (g_io_out_3_bits_exceptionVec_13 !== x_io_out_3_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_13, x_io_out_3_bits_exceptionVec_13); end
    if (g_io_out_3_bits_exceptionVec_14 !== x_io_out_3_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_14, x_io_out_3_bits_exceptionVec_14); end
    if (g_io_out_3_bits_exceptionVec_15 !== x_io_out_3_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_15, x_io_out_3_bits_exceptionVec_15); end
    if (g_io_out_3_bits_exceptionVec_16 !== x_io_out_3_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_16, x_io_out_3_bits_exceptionVec_16); end
    if (g_io_out_3_bits_exceptionVec_17 !== x_io_out_3_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_17, x_io_out_3_bits_exceptionVec_17); end
    if (g_io_out_3_bits_exceptionVec_18 !== x_io_out_3_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_18, x_io_out_3_bits_exceptionVec_18); end
    if (g_io_out_3_bits_exceptionVec_19 !== x_io_out_3_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_19, x_io_out_3_bits_exceptionVec_19); end
    if (g_io_out_3_bits_exceptionVec_20 !== x_io_out_3_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_20, x_io_out_3_bits_exceptionVec_20); end
    if (g_io_out_3_bits_exceptionVec_21 !== x_io_out_3_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_21, x_io_out_3_bits_exceptionVec_21); end
    if (g_io_out_3_bits_exceptionVec_22 !== x_io_out_3_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_22, x_io_out_3_bits_exceptionVec_22); end
    if (g_io_out_3_bits_exceptionVec_23 !== x_io_out_3_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_3_bits_exceptionVec_23, x_io_out_3_bits_exceptionVec_23); end
    if (g_io_out_3_bits_isFetchMalAddr !== x_io_out_3_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_3_bits_isFetchMalAddr, x_io_out_3_bits_isFetchMalAddr); end
    if (g_io_out_3_bits_trigger !== x_io_out_3_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_trigger g=%h x=%h", $time, g_io_out_3_bits_trigger, x_io_out_3_bits_trigger); end
    if (g_io_out_3_bits_preDecodeInfo_valid !== x_io_out_3_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_3_bits_preDecodeInfo_valid, x_io_out_3_bits_preDecodeInfo_valid); end
    if (g_io_out_3_bits_preDecodeInfo_isRVC !== x_io_out_3_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_3_bits_preDecodeInfo_isRVC, x_io_out_3_bits_preDecodeInfo_isRVC); end
    if (g_io_out_3_bits_preDecodeInfo_brType !== x_io_out_3_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_3_bits_preDecodeInfo_brType, x_io_out_3_bits_preDecodeInfo_brType); end
    if (g_io_out_3_bits_preDecodeInfo_isCall !== x_io_out_3_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_3_bits_preDecodeInfo_isCall, x_io_out_3_bits_preDecodeInfo_isCall); end
    if (g_io_out_3_bits_preDecodeInfo_isRet !== x_io_out_3_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_3_bits_preDecodeInfo_isRet, x_io_out_3_bits_preDecodeInfo_isRet); end
    if (g_io_out_3_bits_pred_taken !== x_io_out_3_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_pred_taken g=%h x=%h", $time, g_io_out_3_bits_pred_taken, x_io_out_3_bits_pred_taken); end
    if (g_io_out_3_bits_crossPageIPFFix !== x_io_out_3_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_3_bits_crossPageIPFFix, x_io_out_3_bits_crossPageIPFFix); end
    if (g_io_out_3_bits_ftqPtr_flag !== x_io_out_3_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_3_bits_ftqPtr_flag, x_io_out_3_bits_ftqPtr_flag); end
    if (g_io_out_3_bits_ftqPtr_value !== x_io_out_3_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_3_bits_ftqPtr_value, x_io_out_3_bits_ftqPtr_value); end
    if (g_io_out_3_bits_ftqOffset !== x_io_out_3_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_ftqOffset g=%h x=%h", $time, g_io_out_3_bits_ftqOffset, x_io_out_3_bits_ftqOffset); end
    if (g_io_out_3_bits_satpFlushFirstFetchFault !== x_io_out_3_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_3_bits_satpFlushFirstFetchFault, x_io_out_3_bits_satpFlushFirstFetchFault); end
    if (g_io_out_3_bits_srcType_0 !== x_io_out_3_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_srcType_0 g=%h x=%h", $time, g_io_out_3_bits_srcType_0, x_io_out_3_bits_srcType_0); end
    if (g_io_out_3_bits_srcType_1 !== x_io_out_3_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_srcType_1 g=%h x=%h", $time, g_io_out_3_bits_srcType_1, x_io_out_3_bits_srcType_1); end
    if (g_io_out_3_bits_srcType_2 !== x_io_out_3_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_srcType_2 g=%h x=%h", $time, g_io_out_3_bits_srcType_2, x_io_out_3_bits_srcType_2); end
    if (g_io_out_3_bits_srcType_3 !== x_io_out_3_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_srcType_3 g=%h x=%h", $time, g_io_out_3_bits_srcType_3, x_io_out_3_bits_srcType_3); end
    if (g_io_out_3_bits_srcType_4 !== x_io_out_3_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_srcType_4 g=%h x=%h", $time, g_io_out_3_bits_srcType_4, x_io_out_3_bits_srcType_4); end
    if (g_io_out_3_bits_lsrc_0 !== x_io_out_3_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_lsrc_0 g=%h x=%h", $time, g_io_out_3_bits_lsrc_0, x_io_out_3_bits_lsrc_0); end
    if (g_io_out_3_bits_lsrc_1 !== x_io_out_3_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_lsrc_1 g=%h x=%h", $time, g_io_out_3_bits_lsrc_1, x_io_out_3_bits_lsrc_1); end
    if (g_io_out_3_bits_lsrc_2 !== x_io_out_3_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_lsrc_2 g=%h x=%h", $time, g_io_out_3_bits_lsrc_2, x_io_out_3_bits_lsrc_2); end
    if (g_io_out_3_bits_ldest !== x_io_out_3_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_ldest g=%h x=%h", $time, g_io_out_3_bits_ldest, x_io_out_3_bits_ldest); end
    if (g_io_out_3_bits_fuType !== x_io_out_3_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fuType g=%h x=%h", $time, g_io_out_3_bits_fuType, x_io_out_3_bits_fuType); end
    if (g_io_out_3_bits_fuOpType !== x_io_out_3_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fuOpType g=%h x=%h", $time, g_io_out_3_bits_fuOpType, x_io_out_3_bits_fuOpType); end
    if (g_io_out_3_bits_rfWen !== x_io_out_3_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_rfWen g=%h x=%h", $time, g_io_out_3_bits_rfWen, x_io_out_3_bits_rfWen); end
    if (g_io_out_3_bits_fpWen !== x_io_out_3_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpWen g=%h x=%h", $time, g_io_out_3_bits_fpWen, x_io_out_3_bits_fpWen); end
    if (g_io_out_3_bits_vecWen !== x_io_out_3_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vecWen g=%h x=%h", $time, g_io_out_3_bits_vecWen, x_io_out_3_bits_vecWen); end
    if (g_io_out_3_bits_v0Wen !== x_io_out_3_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_v0Wen g=%h x=%h", $time, g_io_out_3_bits_v0Wen, x_io_out_3_bits_v0Wen); end
    if (g_io_out_3_bits_vlWen !== x_io_out_3_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vlWen g=%h x=%h", $time, g_io_out_3_bits_vlWen, x_io_out_3_bits_vlWen); end
    if (g_io_out_3_bits_isXSTrap !== x_io_out_3_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_isXSTrap g=%h x=%h", $time, g_io_out_3_bits_isXSTrap, x_io_out_3_bits_isXSTrap); end
    if (g_io_out_3_bits_waitForward !== x_io_out_3_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_waitForward g=%h x=%h", $time, g_io_out_3_bits_waitForward, x_io_out_3_bits_waitForward); end
    if (g_io_out_3_bits_blockBackward !== x_io_out_3_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_blockBackward g=%h x=%h", $time, g_io_out_3_bits_blockBackward, x_io_out_3_bits_blockBackward); end
    if (g_io_out_3_bits_flushPipe !== x_io_out_3_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_flushPipe g=%h x=%h", $time, g_io_out_3_bits_flushPipe, x_io_out_3_bits_flushPipe); end
    if (g_io_out_3_bits_canRobCompress !== x_io_out_3_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_canRobCompress g=%h x=%h", $time, g_io_out_3_bits_canRobCompress, x_io_out_3_bits_canRobCompress); end
    if (g_io_out_3_bits_selImm !== x_io_out_3_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_selImm g=%h x=%h", $time, g_io_out_3_bits_selImm, x_io_out_3_bits_selImm); end
    if (g_io_out_3_bits_imm !== x_io_out_3_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_imm g=%h x=%h", $time, g_io_out_3_bits_imm, x_io_out_3_bits_imm); end
    if (g_io_out_3_bits_fpu_typeTagOut !== x_io_out_3_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_3_bits_fpu_typeTagOut, x_io_out_3_bits_fpu_typeTagOut); end
    if (g_io_out_3_bits_fpu_wflags !== x_io_out_3_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpu_wflags g=%h x=%h", $time, g_io_out_3_bits_fpu_wflags, x_io_out_3_bits_fpu_wflags); end
    if (g_io_out_3_bits_fpu_typ !== x_io_out_3_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpu_typ g=%h x=%h", $time, g_io_out_3_bits_fpu_typ, x_io_out_3_bits_fpu_typ); end
    if (g_io_out_3_bits_fpu_fmt !== x_io_out_3_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpu_fmt g=%h x=%h", $time, g_io_out_3_bits_fpu_fmt, x_io_out_3_bits_fpu_fmt); end
    if (g_io_out_3_bits_fpu_rm !== x_io_out_3_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_fpu_rm g=%h x=%h", $time, g_io_out_3_bits_fpu_rm, x_io_out_3_bits_fpu_rm); end
    if (g_io_out_3_bits_vpu_vill !== x_io_out_3_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vill g=%h x=%h", $time, g_io_out_3_bits_vpu_vill, x_io_out_3_bits_vpu_vill); end
    if (g_io_out_3_bits_vpu_vma !== x_io_out_3_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vma g=%h x=%h", $time, g_io_out_3_bits_vpu_vma, x_io_out_3_bits_vpu_vma); end
    if (g_io_out_3_bits_vpu_vta !== x_io_out_3_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vta g=%h x=%h", $time, g_io_out_3_bits_vpu_vta, x_io_out_3_bits_vpu_vta); end
    if (g_io_out_3_bits_vpu_vsew !== x_io_out_3_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vsew g=%h x=%h", $time, g_io_out_3_bits_vpu_vsew, x_io_out_3_bits_vpu_vsew); end
    if (g_io_out_3_bits_vpu_vlmul !== x_io_out_3_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_3_bits_vpu_vlmul, x_io_out_3_bits_vpu_vlmul); end
    if (g_io_out_3_bits_vpu_specVill !== x_io_out_3_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_specVill g=%h x=%h", $time, g_io_out_3_bits_vpu_specVill, x_io_out_3_bits_vpu_specVill); end
    if (g_io_out_3_bits_vpu_specVma !== x_io_out_3_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_specVma g=%h x=%h", $time, g_io_out_3_bits_vpu_specVma, x_io_out_3_bits_vpu_specVma); end
    if (g_io_out_3_bits_vpu_specVta !== x_io_out_3_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_specVta g=%h x=%h", $time, g_io_out_3_bits_vpu_specVta, x_io_out_3_bits_vpu_specVta); end
    if (g_io_out_3_bits_vpu_specVsew !== x_io_out_3_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_3_bits_vpu_specVsew, x_io_out_3_bits_vpu_specVsew); end
    if (g_io_out_3_bits_vpu_specVlmul !== x_io_out_3_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_3_bits_vpu_specVlmul, x_io_out_3_bits_vpu_specVlmul); end
    if (g_io_out_3_bits_vpu_vm !== x_io_out_3_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vm g=%h x=%h", $time, g_io_out_3_bits_vpu_vm, x_io_out_3_bits_vpu_vm); end
    if (g_io_out_3_bits_vpu_vstart !== x_io_out_3_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_vstart g=%h x=%h", $time, g_io_out_3_bits_vpu_vstart, x_io_out_3_bits_vpu_vstart); end
    if (g_io_out_3_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_3_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_3_bits_vpu_fpu_isFoldTo1_2, x_io_out_3_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_3_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_3_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_3_bits_vpu_fpu_isFoldTo1_4, x_io_out_3_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_3_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_3_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_3_bits_vpu_fpu_isFoldTo1_8, x_io_out_3_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_3_bits_vpu_nf !== x_io_out_3_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_nf g=%h x=%h", $time, g_io_out_3_bits_vpu_nf, x_io_out_3_bits_vpu_nf); end
    if (g_io_out_3_bits_vpu_veew !== x_io_out_3_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_veew g=%h x=%h", $time, g_io_out_3_bits_vpu_veew, x_io_out_3_bits_vpu_veew); end
    if (g_io_out_3_bits_vpu_isReverse !== x_io_out_3_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_3_bits_vpu_isReverse, x_io_out_3_bits_vpu_isReverse); end
    if (g_io_out_3_bits_vpu_isExt !== x_io_out_3_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isExt g=%h x=%h", $time, g_io_out_3_bits_vpu_isExt, x_io_out_3_bits_vpu_isExt); end
    if (g_io_out_3_bits_vpu_isNarrow !== x_io_out_3_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_3_bits_vpu_isNarrow, x_io_out_3_bits_vpu_isNarrow); end
    if (g_io_out_3_bits_vpu_isDstMask !== x_io_out_3_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_3_bits_vpu_isDstMask, x_io_out_3_bits_vpu_isDstMask); end
    if (g_io_out_3_bits_vpu_isOpMask !== x_io_out_3_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_3_bits_vpu_isOpMask, x_io_out_3_bits_vpu_isOpMask); end
    if (g_io_out_3_bits_vpu_isDependOldVd !== x_io_out_3_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_3_bits_vpu_isDependOldVd, x_io_out_3_bits_vpu_isDependOldVd); end
    if (g_io_out_3_bits_vpu_isWritePartVd !== x_io_out_3_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_3_bits_vpu_isWritePartVd, x_io_out_3_bits_vpu_isWritePartVd); end
    if (g_io_out_3_bits_vpu_isVleff !== x_io_out_3_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_3_bits_vpu_isVleff, x_io_out_3_bits_vpu_isVleff); end
    if (g_io_out_3_bits_vlsInstr !== x_io_out_3_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_vlsInstr g=%h x=%h", $time, g_io_out_3_bits_vlsInstr, x_io_out_3_bits_vlsInstr); end
    if (g_io_out_3_bits_wfflags !== x_io_out_3_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_wfflags g=%h x=%h", $time, g_io_out_3_bits_wfflags, x_io_out_3_bits_wfflags); end
    if (g_io_out_3_bits_isMove !== x_io_out_3_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_isMove g=%h x=%h", $time, g_io_out_3_bits_isMove, x_io_out_3_bits_isMove); end
    if (g_io_out_3_bits_uopIdx !== x_io_out_3_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_uopIdx g=%h x=%h", $time, g_io_out_3_bits_uopIdx, x_io_out_3_bits_uopIdx); end
    if (g_io_out_3_bits_uopSplitType !== x_io_out_3_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_uopSplitType g=%h x=%h", $time, g_io_out_3_bits_uopSplitType, x_io_out_3_bits_uopSplitType); end
    if (g_io_out_3_bits_isVset !== x_io_out_3_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_isVset g=%h x=%h", $time, g_io_out_3_bits_isVset, x_io_out_3_bits_isVset); end
    if (g_io_out_3_bits_firstUop !== x_io_out_3_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_firstUop g=%h x=%h", $time, g_io_out_3_bits_firstUop, x_io_out_3_bits_firstUop); end
    if (g_io_out_3_bits_lastUop !== x_io_out_3_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_lastUop g=%h x=%h", $time, g_io_out_3_bits_lastUop, x_io_out_3_bits_lastUop); end
    if (g_io_out_3_bits_numUops !== x_io_out_3_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_numUops g=%h x=%h", $time, g_io_out_3_bits_numUops, x_io_out_3_bits_numUops); end
    if (g_io_out_3_bits_numWB !== x_io_out_3_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_numWB g=%h x=%h", $time, g_io_out_3_bits_numWB, x_io_out_3_bits_numWB); end
    if (g_io_out_3_bits_commitType !== x_io_out_3_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_commitType g=%h x=%h", $time, g_io_out_3_bits_commitType, x_io_out_3_bits_commitType); end
    if (g_io_out_3_bits_debug_fuType !== x_io_out_3_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_debug_fuType g=%h x=%h", $time, g_io_out_3_bits_debug_fuType, x_io_out_3_bits_debug_fuType); end
    if (g_io_out_3_bits_debug_seqNum_seqNum !== x_io_out_3_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_3_bits_debug_seqNum_seqNum, x_io_out_3_bits_debug_seqNum_seqNum); end
    if (g_io_out_3_bits_debug_seqNum_uopIdx !== x_io_out_3_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_3_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_3_bits_debug_seqNum_uopIdx, x_io_out_3_bits_debug_seqNum_uopIdx); end
    if (g_io_out_4_valid !== x_io_out_4_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_valid g=%h x=%h", $time, g_io_out_4_valid, x_io_out_4_valid); end
    if (g_io_out_4_bits_instr !== x_io_out_4_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_instr g=%h x=%h", $time, g_io_out_4_bits_instr, x_io_out_4_bits_instr); end
    if (g_io_out_4_bits_pc !== x_io_out_4_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_pc g=%h x=%h", $time, g_io_out_4_bits_pc, x_io_out_4_bits_pc); end
    if (g_io_out_4_bits_foldpc !== x_io_out_4_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_foldpc g=%h x=%h", $time, g_io_out_4_bits_foldpc, x_io_out_4_bits_foldpc); end
    if (g_io_out_4_bits_exceptionVec_0 !== x_io_out_4_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_0, x_io_out_4_bits_exceptionVec_0); end
    if (g_io_out_4_bits_exceptionVec_1 !== x_io_out_4_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_1, x_io_out_4_bits_exceptionVec_1); end
    if (g_io_out_4_bits_exceptionVec_2 !== x_io_out_4_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_2, x_io_out_4_bits_exceptionVec_2); end
    if (g_io_out_4_bits_exceptionVec_3 !== x_io_out_4_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_3, x_io_out_4_bits_exceptionVec_3); end
    if (g_io_out_4_bits_exceptionVec_4 !== x_io_out_4_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_4, x_io_out_4_bits_exceptionVec_4); end
    if (g_io_out_4_bits_exceptionVec_5 !== x_io_out_4_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_5, x_io_out_4_bits_exceptionVec_5); end
    if (g_io_out_4_bits_exceptionVec_6 !== x_io_out_4_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_6, x_io_out_4_bits_exceptionVec_6); end
    if (g_io_out_4_bits_exceptionVec_7 !== x_io_out_4_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_7, x_io_out_4_bits_exceptionVec_7); end
    if (g_io_out_4_bits_exceptionVec_8 !== x_io_out_4_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_8, x_io_out_4_bits_exceptionVec_8); end
    if (g_io_out_4_bits_exceptionVec_9 !== x_io_out_4_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_9, x_io_out_4_bits_exceptionVec_9); end
    if (g_io_out_4_bits_exceptionVec_10 !== x_io_out_4_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_10, x_io_out_4_bits_exceptionVec_10); end
    if (g_io_out_4_bits_exceptionVec_11 !== x_io_out_4_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_11, x_io_out_4_bits_exceptionVec_11); end
    if (g_io_out_4_bits_exceptionVec_12 !== x_io_out_4_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_12, x_io_out_4_bits_exceptionVec_12); end
    if (g_io_out_4_bits_exceptionVec_13 !== x_io_out_4_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_13, x_io_out_4_bits_exceptionVec_13); end
    if (g_io_out_4_bits_exceptionVec_14 !== x_io_out_4_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_14, x_io_out_4_bits_exceptionVec_14); end
    if (g_io_out_4_bits_exceptionVec_15 !== x_io_out_4_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_15, x_io_out_4_bits_exceptionVec_15); end
    if (g_io_out_4_bits_exceptionVec_16 !== x_io_out_4_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_16, x_io_out_4_bits_exceptionVec_16); end
    if (g_io_out_4_bits_exceptionVec_17 !== x_io_out_4_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_17, x_io_out_4_bits_exceptionVec_17); end
    if (g_io_out_4_bits_exceptionVec_18 !== x_io_out_4_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_18, x_io_out_4_bits_exceptionVec_18); end
    if (g_io_out_4_bits_exceptionVec_19 !== x_io_out_4_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_19, x_io_out_4_bits_exceptionVec_19); end
    if (g_io_out_4_bits_exceptionVec_20 !== x_io_out_4_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_20, x_io_out_4_bits_exceptionVec_20); end
    if (g_io_out_4_bits_exceptionVec_21 !== x_io_out_4_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_21, x_io_out_4_bits_exceptionVec_21); end
    if (g_io_out_4_bits_exceptionVec_22 !== x_io_out_4_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_22, x_io_out_4_bits_exceptionVec_22); end
    if (g_io_out_4_bits_exceptionVec_23 !== x_io_out_4_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_4_bits_exceptionVec_23, x_io_out_4_bits_exceptionVec_23); end
    if (g_io_out_4_bits_isFetchMalAddr !== x_io_out_4_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_4_bits_isFetchMalAddr, x_io_out_4_bits_isFetchMalAddr); end
    if (g_io_out_4_bits_trigger !== x_io_out_4_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_trigger g=%h x=%h", $time, g_io_out_4_bits_trigger, x_io_out_4_bits_trigger); end
    if (g_io_out_4_bits_preDecodeInfo_valid !== x_io_out_4_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_4_bits_preDecodeInfo_valid, x_io_out_4_bits_preDecodeInfo_valid); end
    if (g_io_out_4_bits_preDecodeInfo_isRVC !== x_io_out_4_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_4_bits_preDecodeInfo_isRVC, x_io_out_4_bits_preDecodeInfo_isRVC); end
    if (g_io_out_4_bits_preDecodeInfo_brType !== x_io_out_4_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_4_bits_preDecodeInfo_brType, x_io_out_4_bits_preDecodeInfo_brType); end
    if (g_io_out_4_bits_preDecodeInfo_isCall !== x_io_out_4_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_4_bits_preDecodeInfo_isCall, x_io_out_4_bits_preDecodeInfo_isCall); end
    if (g_io_out_4_bits_preDecodeInfo_isRet !== x_io_out_4_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_4_bits_preDecodeInfo_isRet, x_io_out_4_bits_preDecodeInfo_isRet); end
    if (g_io_out_4_bits_pred_taken !== x_io_out_4_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_pred_taken g=%h x=%h", $time, g_io_out_4_bits_pred_taken, x_io_out_4_bits_pred_taken); end
    if (g_io_out_4_bits_crossPageIPFFix !== x_io_out_4_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_4_bits_crossPageIPFFix, x_io_out_4_bits_crossPageIPFFix); end
    if (g_io_out_4_bits_ftqPtr_flag !== x_io_out_4_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_4_bits_ftqPtr_flag, x_io_out_4_bits_ftqPtr_flag); end
    if (g_io_out_4_bits_ftqPtr_value !== x_io_out_4_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_4_bits_ftqPtr_value, x_io_out_4_bits_ftqPtr_value); end
    if (g_io_out_4_bits_ftqOffset !== x_io_out_4_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_ftqOffset g=%h x=%h", $time, g_io_out_4_bits_ftqOffset, x_io_out_4_bits_ftqOffset); end
    if (g_io_out_4_bits_satpFlushFirstFetchFault !== x_io_out_4_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_4_bits_satpFlushFirstFetchFault, x_io_out_4_bits_satpFlushFirstFetchFault); end
    if (g_io_out_4_bits_srcType_0 !== x_io_out_4_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_srcType_0 g=%h x=%h", $time, g_io_out_4_bits_srcType_0, x_io_out_4_bits_srcType_0); end
    if (g_io_out_4_bits_srcType_1 !== x_io_out_4_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_srcType_1 g=%h x=%h", $time, g_io_out_4_bits_srcType_1, x_io_out_4_bits_srcType_1); end
    if (g_io_out_4_bits_srcType_2 !== x_io_out_4_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_srcType_2 g=%h x=%h", $time, g_io_out_4_bits_srcType_2, x_io_out_4_bits_srcType_2); end
    if (g_io_out_4_bits_srcType_3 !== x_io_out_4_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_srcType_3 g=%h x=%h", $time, g_io_out_4_bits_srcType_3, x_io_out_4_bits_srcType_3); end
    if (g_io_out_4_bits_srcType_4 !== x_io_out_4_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_srcType_4 g=%h x=%h", $time, g_io_out_4_bits_srcType_4, x_io_out_4_bits_srcType_4); end
    if (g_io_out_4_bits_lsrc_0 !== x_io_out_4_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_lsrc_0 g=%h x=%h", $time, g_io_out_4_bits_lsrc_0, x_io_out_4_bits_lsrc_0); end
    if (g_io_out_4_bits_lsrc_1 !== x_io_out_4_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_lsrc_1 g=%h x=%h", $time, g_io_out_4_bits_lsrc_1, x_io_out_4_bits_lsrc_1); end
    if (g_io_out_4_bits_lsrc_2 !== x_io_out_4_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_lsrc_2 g=%h x=%h", $time, g_io_out_4_bits_lsrc_2, x_io_out_4_bits_lsrc_2); end
    if (g_io_out_4_bits_ldest !== x_io_out_4_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_ldest g=%h x=%h", $time, g_io_out_4_bits_ldest, x_io_out_4_bits_ldest); end
    if (g_io_out_4_bits_fuType !== x_io_out_4_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fuType g=%h x=%h", $time, g_io_out_4_bits_fuType, x_io_out_4_bits_fuType); end
    if (g_io_out_4_bits_fuOpType !== x_io_out_4_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fuOpType g=%h x=%h", $time, g_io_out_4_bits_fuOpType, x_io_out_4_bits_fuOpType); end
    if (g_io_out_4_bits_rfWen !== x_io_out_4_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_rfWen g=%h x=%h", $time, g_io_out_4_bits_rfWen, x_io_out_4_bits_rfWen); end
    if (g_io_out_4_bits_fpWen !== x_io_out_4_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpWen g=%h x=%h", $time, g_io_out_4_bits_fpWen, x_io_out_4_bits_fpWen); end
    if (g_io_out_4_bits_vecWen !== x_io_out_4_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vecWen g=%h x=%h", $time, g_io_out_4_bits_vecWen, x_io_out_4_bits_vecWen); end
    if (g_io_out_4_bits_v0Wen !== x_io_out_4_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_v0Wen g=%h x=%h", $time, g_io_out_4_bits_v0Wen, x_io_out_4_bits_v0Wen); end
    if (g_io_out_4_bits_vlWen !== x_io_out_4_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vlWen g=%h x=%h", $time, g_io_out_4_bits_vlWen, x_io_out_4_bits_vlWen); end
    if (g_io_out_4_bits_isXSTrap !== x_io_out_4_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_isXSTrap g=%h x=%h", $time, g_io_out_4_bits_isXSTrap, x_io_out_4_bits_isXSTrap); end
    if (g_io_out_4_bits_waitForward !== x_io_out_4_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_waitForward g=%h x=%h", $time, g_io_out_4_bits_waitForward, x_io_out_4_bits_waitForward); end
    if (g_io_out_4_bits_blockBackward !== x_io_out_4_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_blockBackward g=%h x=%h", $time, g_io_out_4_bits_blockBackward, x_io_out_4_bits_blockBackward); end
    if (g_io_out_4_bits_flushPipe !== x_io_out_4_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_flushPipe g=%h x=%h", $time, g_io_out_4_bits_flushPipe, x_io_out_4_bits_flushPipe); end
    if (g_io_out_4_bits_canRobCompress !== x_io_out_4_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_canRobCompress g=%h x=%h", $time, g_io_out_4_bits_canRobCompress, x_io_out_4_bits_canRobCompress); end
    if (g_io_out_4_bits_selImm !== x_io_out_4_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_selImm g=%h x=%h", $time, g_io_out_4_bits_selImm, x_io_out_4_bits_selImm); end
    if (g_io_out_4_bits_imm !== x_io_out_4_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_imm g=%h x=%h", $time, g_io_out_4_bits_imm, x_io_out_4_bits_imm); end
    if (g_io_out_4_bits_fpu_typeTagOut !== x_io_out_4_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_4_bits_fpu_typeTagOut, x_io_out_4_bits_fpu_typeTagOut); end
    if (g_io_out_4_bits_fpu_wflags !== x_io_out_4_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpu_wflags g=%h x=%h", $time, g_io_out_4_bits_fpu_wflags, x_io_out_4_bits_fpu_wflags); end
    if (g_io_out_4_bits_fpu_typ !== x_io_out_4_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpu_typ g=%h x=%h", $time, g_io_out_4_bits_fpu_typ, x_io_out_4_bits_fpu_typ); end
    if (g_io_out_4_bits_fpu_fmt !== x_io_out_4_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpu_fmt g=%h x=%h", $time, g_io_out_4_bits_fpu_fmt, x_io_out_4_bits_fpu_fmt); end
    if (g_io_out_4_bits_fpu_rm !== x_io_out_4_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_fpu_rm g=%h x=%h", $time, g_io_out_4_bits_fpu_rm, x_io_out_4_bits_fpu_rm); end
    if (g_io_out_4_bits_vpu_vill !== x_io_out_4_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vill g=%h x=%h", $time, g_io_out_4_bits_vpu_vill, x_io_out_4_bits_vpu_vill); end
    if (g_io_out_4_bits_vpu_vma !== x_io_out_4_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vma g=%h x=%h", $time, g_io_out_4_bits_vpu_vma, x_io_out_4_bits_vpu_vma); end
    if (g_io_out_4_bits_vpu_vta !== x_io_out_4_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vta g=%h x=%h", $time, g_io_out_4_bits_vpu_vta, x_io_out_4_bits_vpu_vta); end
    if (g_io_out_4_bits_vpu_vsew !== x_io_out_4_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vsew g=%h x=%h", $time, g_io_out_4_bits_vpu_vsew, x_io_out_4_bits_vpu_vsew); end
    if (g_io_out_4_bits_vpu_vlmul !== x_io_out_4_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_4_bits_vpu_vlmul, x_io_out_4_bits_vpu_vlmul); end
    if (g_io_out_4_bits_vpu_specVill !== x_io_out_4_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_specVill g=%h x=%h", $time, g_io_out_4_bits_vpu_specVill, x_io_out_4_bits_vpu_specVill); end
    if (g_io_out_4_bits_vpu_specVma !== x_io_out_4_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_specVma g=%h x=%h", $time, g_io_out_4_bits_vpu_specVma, x_io_out_4_bits_vpu_specVma); end
    if (g_io_out_4_bits_vpu_specVta !== x_io_out_4_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_specVta g=%h x=%h", $time, g_io_out_4_bits_vpu_specVta, x_io_out_4_bits_vpu_specVta); end
    if (g_io_out_4_bits_vpu_specVsew !== x_io_out_4_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_4_bits_vpu_specVsew, x_io_out_4_bits_vpu_specVsew); end
    if (g_io_out_4_bits_vpu_specVlmul !== x_io_out_4_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_4_bits_vpu_specVlmul, x_io_out_4_bits_vpu_specVlmul); end
    if (g_io_out_4_bits_vpu_vm !== x_io_out_4_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vm g=%h x=%h", $time, g_io_out_4_bits_vpu_vm, x_io_out_4_bits_vpu_vm); end
    if (g_io_out_4_bits_vpu_vstart !== x_io_out_4_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_vstart g=%h x=%h", $time, g_io_out_4_bits_vpu_vstart, x_io_out_4_bits_vpu_vstart); end
    if (g_io_out_4_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_4_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_4_bits_vpu_fpu_isFoldTo1_2, x_io_out_4_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_4_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_4_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_4_bits_vpu_fpu_isFoldTo1_4, x_io_out_4_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_4_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_4_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_4_bits_vpu_fpu_isFoldTo1_8, x_io_out_4_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_4_bits_vpu_nf !== x_io_out_4_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_nf g=%h x=%h", $time, g_io_out_4_bits_vpu_nf, x_io_out_4_bits_vpu_nf); end
    if (g_io_out_4_bits_vpu_veew !== x_io_out_4_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_veew g=%h x=%h", $time, g_io_out_4_bits_vpu_veew, x_io_out_4_bits_vpu_veew); end
    if (g_io_out_4_bits_vpu_isReverse !== x_io_out_4_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_4_bits_vpu_isReverse, x_io_out_4_bits_vpu_isReverse); end
    if (g_io_out_4_bits_vpu_isExt !== x_io_out_4_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isExt g=%h x=%h", $time, g_io_out_4_bits_vpu_isExt, x_io_out_4_bits_vpu_isExt); end
    if (g_io_out_4_bits_vpu_isNarrow !== x_io_out_4_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_4_bits_vpu_isNarrow, x_io_out_4_bits_vpu_isNarrow); end
    if (g_io_out_4_bits_vpu_isDstMask !== x_io_out_4_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_4_bits_vpu_isDstMask, x_io_out_4_bits_vpu_isDstMask); end
    if (g_io_out_4_bits_vpu_isOpMask !== x_io_out_4_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_4_bits_vpu_isOpMask, x_io_out_4_bits_vpu_isOpMask); end
    if (g_io_out_4_bits_vpu_isDependOldVd !== x_io_out_4_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_4_bits_vpu_isDependOldVd, x_io_out_4_bits_vpu_isDependOldVd); end
    if (g_io_out_4_bits_vpu_isWritePartVd !== x_io_out_4_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_4_bits_vpu_isWritePartVd, x_io_out_4_bits_vpu_isWritePartVd); end
    if (g_io_out_4_bits_vpu_isVleff !== x_io_out_4_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_4_bits_vpu_isVleff, x_io_out_4_bits_vpu_isVleff); end
    if (g_io_out_4_bits_vlsInstr !== x_io_out_4_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_vlsInstr g=%h x=%h", $time, g_io_out_4_bits_vlsInstr, x_io_out_4_bits_vlsInstr); end
    if (g_io_out_4_bits_wfflags !== x_io_out_4_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_wfflags g=%h x=%h", $time, g_io_out_4_bits_wfflags, x_io_out_4_bits_wfflags); end
    if (g_io_out_4_bits_isMove !== x_io_out_4_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_isMove g=%h x=%h", $time, g_io_out_4_bits_isMove, x_io_out_4_bits_isMove); end
    if (g_io_out_4_bits_uopIdx !== x_io_out_4_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_uopIdx g=%h x=%h", $time, g_io_out_4_bits_uopIdx, x_io_out_4_bits_uopIdx); end
    if (g_io_out_4_bits_uopSplitType !== x_io_out_4_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_uopSplitType g=%h x=%h", $time, g_io_out_4_bits_uopSplitType, x_io_out_4_bits_uopSplitType); end
    if (g_io_out_4_bits_isVset !== x_io_out_4_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_isVset g=%h x=%h", $time, g_io_out_4_bits_isVset, x_io_out_4_bits_isVset); end
    if (g_io_out_4_bits_firstUop !== x_io_out_4_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_firstUop g=%h x=%h", $time, g_io_out_4_bits_firstUop, x_io_out_4_bits_firstUop); end
    if (g_io_out_4_bits_lastUop !== x_io_out_4_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_lastUop g=%h x=%h", $time, g_io_out_4_bits_lastUop, x_io_out_4_bits_lastUop); end
    if (g_io_out_4_bits_numUops !== x_io_out_4_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_numUops g=%h x=%h", $time, g_io_out_4_bits_numUops, x_io_out_4_bits_numUops); end
    if (g_io_out_4_bits_numWB !== x_io_out_4_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_numWB g=%h x=%h", $time, g_io_out_4_bits_numWB, x_io_out_4_bits_numWB); end
    if (g_io_out_4_bits_commitType !== x_io_out_4_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_commitType g=%h x=%h", $time, g_io_out_4_bits_commitType, x_io_out_4_bits_commitType); end
    if (g_io_out_4_bits_debug_fuType !== x_io_out_4_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_debug_fuType g=%h x=%h", $time, g_io_out_4_bits_debug_fuType, x_io_out_4_bits_debug_fuType); end
    if (g_io_out_4_bits_debug_seqNum_seqNum !== x_io_out_4_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_4_bits_debug_seqNum_seqNum, x_io_out_4_bits_debug_seqNum_seqNum); end
    if (g_io_out_4_bits_debug_seqNum_uopIdx !== x_io_out_4_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_4_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_4_bits_debug_seqNum_uopIdx, x_io_out_4_bits_debug_seqNum_uopIdx); end
    if (g_io_out_5_valid !== x_io_out_5_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_valid g=%h x=%h", $time, g_io_out_5_valid, x_io_out_5_valid); end
    if (g_io_out_5_bits_instr !== x_io_out_5_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_instr g=%h x=%h", $time, g_io_out_5_bits_instr, x_io_out_5_bits_instr); end
    if (g_io_out_5_bits_pc !== x_io_out_5_bits_pc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_pc g=%h x=%h", $time, g_io_out_5_bits_pc, x_io_out_5_bits_pc); end
    if (g_io_out_5_bits_foldpc !== x_io_out_5_bits_foldpc) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_foldpc g=%h x=%h", $time, g_io_out_5_bits_foldpc, x_io_out_5_bits_foldpc); end
    if (g_io_out_5_bits_exceptionVec_0 !== x_io_out_5_bits_exceptionVec_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_0 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_0, x_io_out_5_bits_exceptionVec_0); end
    if (g_io_out_5_bits_exceptionVec_1 !== x_io_out_5_bits_exceptionVec_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_1 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_1, x_io_out_5_bits_exceptionVec_1); end
    if (g_io_out_5_bits_exceptionVec_2 !== x_io_out_5_bits_exceptionVec_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_2 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_2, x_io_out_5_bits_exceptionVec_2); end
    if (g_io_out_5_bits_exceptionVec_3 !== x_io_out_5_bits_exceptionVec_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_3 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_3, x_io_out_5_bits_exceptionVec_3); end
    if (g_io_out_5_bits_exceptionVec_4 !== x_io_out_5_bits_exceptionVec_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_4 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_4, x_io_out_5_bits_exceptionVec_4); end
    if (g_io_out_5_bits_exceptionVec_5 !== x_io_out_5_bits_exceptionVec_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_5 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_5, x_io_out_5_bits_exceptionVec_5); end
    if (g_io_out_5_bits_exceptionVec_6 !== x_io_out_5_bits_exceptionVec_6) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_6 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_6, x_io_out_5_bits_exceptionVec_6); end
    if (g_io_out_5_bits_exceptionVec_7 !== x_io_out_5_bits_exceptionVec_7) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_7 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_7, x_io_out_5_bits_exceptionVec_7); end
    if (g_io_out_5_bits_exceptionVec_8 !== x_io_out_5_bits_exceptionVec_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_8 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_8, x_io_out_5_bits_exceptionVec_8); end
    if (g_io_out_5_bits_exceptionVec_9 !== x_io_out_5_bits_exceptionVec_9) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_9 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_9, x_io_out_5_bits_exceptionVec_9); end
    if (g_io_out_5_bits_exceptionVec_10 !== x_io_out_5_bits_exceptionVec_10) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_10 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_10, x_io_out_5_bits_exceptionVec_10); end
    if (g_io_out_5_bits_exceptionVec_11 !== x_io_out_5_bits_exceptionVec_11) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_11 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_11, x_io_out_5_bits_exceptionVec_11); end
    if (g_io_out_5_bits_exceptionVec_12 !== x_io_out_5_bits_exceptionVec_12) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_12 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_12, x_io_out_5_bits_exceptionVec_12); end
    if (g_io_out_5_bits_exceptionVec_13 !== x_io_out_5_bits_exceptionVec_13) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_13 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_13, x_io_out_5_bits_exceptionVec_13); end
    if (g_io_out_5_bits_exceptionVec_14 !== x_io_out_5_bits_exceptionVec_14) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_14 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_14, x_io_out_5_bits_exceptionVec_14); end
    if (g_io_out_5_bits_exceptionVec_15 !== x_io_out_5_bits_exceptionVec_15) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_15 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_15, x_io_out_5_bits_exceptionVec_15); end
    if (g_io_out_5_bits_exceptionVec_16 !== x_io_out_5_bits_exceptionVec_16) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_16 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_16, x_io_out_5_bits_exceptionVec_16); end
    if (g_io_out_5_bits_exceptionVec_17 !== x_io_out_5_bits_exceptionVec_17) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_17 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_17, x_io_out_5_bits_exceptionVec_17); end
    if (g_io_out_5_bits_exceptionVec_18 !== x_io_out_5_bits_exceptionVec_18) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_18 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_18, x_io_out_5_bits_exceptionVec_18); end
    if (g_io_out_5_bits_exceptionVec_19 !== x_io_out_5_bits_exceptionVec_19) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_19 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_19, x_io_out_5_bits_exceptionVec_19); end
    if (g_io_out_5_bits_exceptionVec_20 !== x_io_out_5_bits_exceptionVec_20) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_20 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_20, x_io_out_5_bits_exceptionVec_20); end
    if (g_io_out_5_bits_exceptionVec_21 !== x_io_out_5_bits_exceptionVec_21) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_21 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_21, x_io_out_5_bits_exceptionVec_21); end
    if (g_io_out_5_bits_exceptionVec_22 !== x_io_out_5_bits_exceptionVec_22) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_22 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_22, x_io_out_5_bits_exceptionVec_22); end
    if (g_io_out_5_bits_exceptionVec_23 !== x_io_out_5_bits_exceptionVec_23) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_exceptionVec_23 g=%h x=%h", $time, g_io_out_5_bits_exceptionVec_23, x_io_out_5_bits_exceptionVec_23); end
    if (g_io_out_5_bits_isFetchMalAddr !== x_io_out_5_bits_isFetchMalAddr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_isFetchMalAddr g=%h x=%h", $time, g_io_out_5_bits_isFetchMalAddr, x_io_out_5_bits_isFetchMalAddr); end
    if (g_io_out_5_bits_trigger !== x_io_out_5_bits_trigger) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_trigger g=%h x=%h", $time, g_io_out_5_bits_trigger, x_io_out_5_bits_trigger); end
    if (g_io_out_5_bits_preDecodeInfo_valid !== x_io_out_5_bits_preDecodeInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_preDecodeInfo_valid g=%h x=%h", $time, g_io_out_5_bits_preDecodeInfo_valid, x_io_out_5_bits_preDecodeInfo_valid); end
    if (g_io_out_5_bits_preDecodeInfo_isRVC !== x_io_out_5_bits_preDecodeInfo_isRVC) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_preDecodeInfo_isRVC g=%h x=%h", $time, g_io_out_5_bits_preDecodeInfo_isRVC, x_io_out_5_bits_preDecodeInfo_isRVC); end
    if (g_io_out_5_bits_preDecodeInfo_brType !== x_io_out_5_bits_preDecodeInfo_brType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_preDecodeInfo_brType g=%h x=%h", $time, g_io_out_5_bits_preDecodeInfo_brType, x_io_out_5_bits_preDecodeInfo_brType); end
    if (g_io_out_5_bits_preDecodeInfo_isCall !== x_io_out_5_bits_preDecodeInfo_isCall) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_preDecodeInfo_isCall g=%h x=%h", $time, g_io_out_5_bits_preDecodeInfo_isCall, x_io_out_5_bits_preDecodeInfo_isCall); end
    if (g_io_out_5_bits_preDecodeInfo_isRet !== x_io_out_5_bits_preDecodeInfo_isRet) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_preDecodeInfo_isRet g=%h x=%h", $time, g_io_out_5_bits_preDecodeInfo_isRet, x_io_out_5_bits_preDecodeInfo_isRet); end
    if (g_io_out_5_bits_pred_taken !== x_io_out_5_bits_pred_taken) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_pred_taken g=%h x=%h", $time, g_io_out_5_bits_pred_taken, x_io_out_5_bits_pred_taken); end
    if (g_io_out_5_bits_crossPageIPFFix !== x_io_out_5_bits_crossPageIPFFix) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_crossPageIPFFix g=%h x=%h", $time, g_io_out_5_bits_crossPageIPFFix, x_io_out_5_bits_crossPageIPFFix); end
    if (g_io_out_5_bits_ftqPtr_flag !== x_io_out_5_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_ftqPtr_flag g=%h x=%h", $time, g_io_out_5_bits_ftqPtr_flag, x_io_out_5_bits_ftqPtr_flag); end
    if (g_io_out_5_bits_ftqPtr_value !== x_io_out_5_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_ftqPtr_value g=%h x=%h", $time, g_io_out_5_bits_ftqPtr_value, x_io_out_5_bits_ftqPtr_value); end
    if (g_io_out_5_bits_ftqOffset !== x_io_out_5_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_ftqOffset g=%h x=%h", $time, g_io_out_5_bits_ftqOffset, x_io_out_5_bits_ftqOffset); end
    if (g_io_out_5_bits_satpFlushFirstFetchFault !== x_io_out_5_bits_satpFlushFirstFetchFault) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_satpFlushFirstFetchFault g=%h x=%h", $time, g_io_out_5_bits_satpFlushFirstFetchFault, x_io_out_5_bits_satpFlushFirstFetchFault); end
    if (g_io_out_5_bits_srcType_0 !== x_io_out_5_bits_srcType_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_srcType_0 g=%h x=%h", $time, g_io_out_5_bits_srcType_0, x_io_out_5_bits_srcType_0); end
    if (g_io_out_5_bits_srcType_1 !== x_io_out_5_bits_srcType_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_srcType_1 g=%h x=%h", $time, g_io_out_5_bits_srcType_1, x_io_out_5_bits_srcType_1); end
    if (g_io_out_5_bits_srcType_2 !== x_io_out_5_bits_srcType_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_srcType_2 g=%h x=%h", $time, g_io_out_5_bits_srcType_2, x_io_out_5_bits_srcType_2); end
    if (g_io_out_5_bits_srcType_3 !== x_io_out_5_bits_srcType_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_srcType_3 g=%h x=%h", $time, g_io_out_5_bits_srcType_3, x_io_out_5_bits_srcType_3); end
    if (g_io_out_5_bits_srcType_4 !== x_io_out_5_bits_srcType_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_srcType_4 g=%h x=%h", $time, g_io_out_5_bits_srcType_4, x_io_out_5_bits_srcType_4); end
    if (g_io_out_5_bits_lsrc_0 !== x_io_out_5_bits_lsrc_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_lsrc_0 g=%h x=%h", $time, g_io_out_5_bits_lsrc_0, x_io_out_5_bits_lsrc_0); end
    if (g_io_out_5_bits_lsrc_1 !== x_io_out_5_bits_lsrc_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_lsrc_1 g=%h x=%h", $time, g_io_out_5_bits_lsrc_1, x_io_out_5_bits_lsrc_1); end
    if (g_io_out_5_bits_lsrc_2 !== x_io_out_5_bits_lsrc_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_lsrc_2 g=%h x=%h", $time, g_io_out_5_bits_lsrc_2, x_io_out_5_bits_lsrc_2); end
    if (g_io_out_5_bits_ldest !== x_io_out_5_bits_ldest) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_ldest g=%h x=%h", $time, g_io_out_5_bits_ldest, x_io_out_5_bits_ldest); end
    if (g_io_out_5_bits_fuType !== x_io_out_5_bits_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fuType g=%h x=%h", $time, g_io_out_5_bits_fuType, x_io_out_5_bits_fuType); end
    if (g_io_out_5_bits_fuOpType !== x_io_out_5_bits_fuOpType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fuOpType g=%h x=%h", $time, g_io_out_5_bits_fuOpType, x_io_out_5_bits_fuOpType); end
    if (g_io_out_5_bits_rfWen !== x_io_out_5_bits_rfWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_rfWen g=%h x=%h", $time, g_io_out_5_bits_rfWen, x_io_out_5_bits_rfWen); end
    if (g_io_out_5_bits_fpWen !== x_io_out_5_bits_fpWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpWen g=%h x=%h", $time, g_io_out_5_bits_fpWen, x_io_out_5_bits_fpWen); end
    if (g_io_out_5_bits_vecWen !== x_io_out_5_bits_vecWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vecWen g=%h x=%h", $time, g_io_out_5_bits_vecWen, x_io_out_5_bits_vecWen); end
    if (g_io_out_5_bits_v0Wen !== x_io_out_5_bits_v0Wen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_v0Wen g=%h x=%h", $time, g_io_out_5_bits_v0Wen, x_io_out_5_bits_v0Wen); end
    if (g_io_out_5_bits_vlWen !== x_io_out_5_bits_vlWen) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vlWen g=%h x=%h", $time, g_io_out_5_bits_vlWen, x_io_out_5_bits_vlWen); end
    if (g_io_out_5_bits_isXSTrap !== x_io_out_5_bits_isXSTrap) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_isXSTrap g=%h x=%h", $time, g_io_out_5_bits_isXSTrap, x_io_out_5_bits_isXSTrap); end
    if (g_io_out_5_bits_waitForward !== x_io_out_5_bits_waitForward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_waitForward g=%h x=%h", $time, g_io_out_5_bits_waitForward, x_io_out_5_bits_waitForward); end
    if (g_io_out_5_bits_blockBackward !== x_io_out_5_bits_blockBackward) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_blockBackward g=%h x=%h", $time, g_io_out_5_bits_blockBackward, x_io_out_5_bits_blockBackward); end
    if (g_io_out_5_bits_flushPipe !== x_io_out_5_bits_flushPipe) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_flushPipe g=%h x=%h", $time, g_io_out_5_bits_flushPipe, x_io_out_5_bits_flushPipe); end
    if (g_io_out_5_bits_canRobCompress !== x_io_out_5_bits_canRobCompress) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_canRobCompress g=%h x=%h", $time, g_io_out_5_bits_canRobCompress, x_io_out_5_bits_canRobCompress); end
    if (g_io_out_5_bits_selImm !== x_io_out_5_bits_selImm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_selImm g=%h x=%h", $time, g_io_out_5_bits_selImm, x_io_out_5_bits_selImm); end
    if (g_io_out_5_bits_imm !== x_io_out_5_bits_imm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_imm g=%h x=%h", $time, g_io_out_5_bits_imm, x_io_out_5_bits_imm); end
    if (g_io_out_5_bits_fpu_typeTagOut !== x_io_out_5_bits_fpu_typeTagOut) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpu_typeTagOut g=%h x=%h", $time, g_io_out_5_bits_fpu_typeTagOut, x_io_out_5_bits_fpu_typeTagOut); end
    if (g_io_out_5_bits_fpu_wflags !== x_io_out_5_bits_fpu_wflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpu_wflags g=%h x=%h", $time, g_io_out_5_bits_fpu_wflags, x_io_out_5_bits_fpu_wflags); end
    if (g_io_out_5_bits_fpu_typ !== x_io_out_5_bits_fpu_typ) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpu_typ g=%h x=%h", $time, g_io_out_5_bits_fpu_typ, x_io_out_5_bits_fpu_typ); end
    if (g_io_out_5_bits_fpu_fmt !== x_io_out_5_bits_fpu_fmt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpu_fmt g=%h x=%h", $time, g_io_out_5_bits_fpu_fmt, x_io_out_5_bits_fpu_fmt); end
    if (g_io_out_5_bits_fpu_rm !== x_io_out_5_bits_fpu_rm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_fpu_rm g=%h x=%h", $time, g_io_out_5_bits_fpu_rm, x_io_out_5_bits_fpu_rm); end
    if (g_io_out_5_bits_vpu_vill !== x_io_out_5_bits_vpu_vill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vill g=%h x=%h", $time, g_io_out_5_bits_vpu_vill, x_io_out_5_bits_vpu_vill); end
    if (g_io_out_5_bits_vpu_vma !== x_io_out_5_bits_vpu_vma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vma g=%h x=%h", $time, g_io_out_5_bits_vpu_vma, x_io_out_5_bits_vpu_vma); end
    if (g_io_out_5_bits_vpu_vta !== x_io_out_5_bits_vpu_vta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vta g=%h x=%h", $time, g_io_out_5_bits_vpu_vta, x_io_out_5_bits_vpu_vta); end
    if (g_io_out_5_bits_vpu_vsew !== x_io_out_5_bits_vpu_vsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vsew g=%h x=%h", $time, g_io_out_5_bits_vpu_vsew, x_io_out_5_bits_vpu_vsew); end
    if (g_io_out_5_bits_vpu_vlmul !== x_io_out_5_bits_vpu_vlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vlmul g=%h x=%h", $time, g_io_out_5_bits_vpu_vlmul, x_io_out_5_bits_vpu_vlmul); end
    if (g_io_out_5_bits_vpu_specVill !== x_io_out_5_bits_vpu_specVill) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_specVill g=%h x=%h", $time, g_io_out_5_bits_vpu_specVill, x_io_out_5_bits_vpu_specVill); end
    if (g_io_out_5_bits_vpu_specVma !== x_io_out_5_bits_vpu_specVma) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_specVma g=%h x=%h", $time, g_io_out_5_bits_vpu_specVma, x_io_out_5_bits_vpu_specVma); end
    if (g_io_out_5_bits_vpu_specVta !== x_io_out_5_bits_vpu_specVta) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_specVta g=%h x=%h", $time, g_io_out_5_bits_vpu_specVta, x_io_out_5_bits_vpu_specVta); end
    if (g_io_out_5_bits_vpu_specVsew !== x_io_out_5_bits_vpu_specVsew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_specVsew g=%h x=%h", $time, g_io_out_5_bits_vpu_specVsew, x_io_out_5_bits_vpu_specVsew); end
    if (g_io_out_5_bits_vpu_specVlmul !== x_io_out_5_bits_vpu_specVlmul) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_specVlmul g=%h x=%h", $time, g_io_out_5_bits_vpu_specVlmul, x_io_out_5_bits_vpu_specVlmul); end
    if (g_io_out_5_bits_vpu_vm !== x_io_out_5_bits_vpu_vm) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vm g=%h x=%h", $time, g_io_out_5_bits_vpu_vm, x_io_out_5_bits_vpu_vm); end
    if (g_io_out_5_bits_vpu_vstart !== x_io_out_5_bits_vpu_vstart) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_vstart g=%h x=%h", $time, g_io_out_5_bits_vpu_vstart, x_io_out_5_bits_vpu_vstart); end
    if (g_io_out_5_bits_vpu_fpu_isFoldTo1_2 !== x_io_out_5_bits_vpu_fpu_isFoldTo1_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_fpu_isFoldTo1_2 g=%h x=%h", $time, g_io_out_5_bits_vpu_fpu_isFoldTo1_2, x_io_out_5_bits_vpu_fpu_isFoldTo1_2); end
    if (g_io_out_5_bits_vpu_fpu_isFoldTo1_4 !== x_io_out_5_bits_vpu_fpu_isFoldTo1_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_fpu_isFoldTo1_4 g=%h x=%h", $time, g_io_out_5_bits_vpu_fpu_isFoldTo1_4, x_io_out_5_bits_vpu_fpu_isFoldTo1_4); end
    if (g_io_out_5_bits_vpu_fpu_isFoldTo1_8 !== x_io_out_5_bits_vpu_fpu_isFoldTo1_8) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_fpu_isFoldTo1_8 g=%h x=%h", $time, g_io_out_5_bits_vpu_fpu_isFoldTo1_8, x_io_out_5_bits_vpu_fpu_isFoldTo1_8); end
    if (g_io_out_5_bits_vpu_nf !== x_io_out_5_bits_vpu_nf) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_nf g=%h x=%h", $time, g_io_out_5_bits_vpu_nf, x_io_out_5_bits_vpu_nf); end
    if (g_io_out_5_bits_vpu_veew !== x_io_out_5_bits_vpu_veew) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_veew g=%h x=%h", $time, g_io_out_5_bits_vpu_veew, x_io_out_5_bits_vpu_veew); end
    if (g_io_out_5_bits_vpu_isReverse !== x_io_out_5_bits_vpu_isReverse) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isReverse g=%h x=%h", $time, g_io_out_5_bits_vpu_isReverse, x_io_out_5_bits_vpu_isReverse); end
    if (g_io_out_5_bits_vpu_isExt !== x_io_out_5_bits_vpu_isExt) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isExt g=%h x=%h", $time, g_io_out_5_bits_vpu_isExt, x_io_out_5_bits_vpu_isExt); end
    if (g_io_out_5_bits_vpu_isNarrow !== x_io_out_5_bits_vpu_isNarrow) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isNarrow g=%h x=%h", $time, g_io_out_5_bits_vpu_isNarrow, x_io_out_5_bits_vpu_isNarrow); end
    if (g_io_out_5_bits_vpu_isDstMask !== x_io_out_5_bits_vpu_isDstMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isDstMask g=%h x=%h", $time, g_io_out_5_bits_vpu_isDstMask, x_io_out_5_bits_vpu_isDstMask); end
    if (g_io_out_5_bits_vpu_isOpMask !== x_io_out_5_bits_vpu_isOpMask) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isOpMask g=%h x=%h", $time, g_io_out_5_bits_vpu_isOpMask, x_io_out_5_bits_vpu_isOpMask); end
    if (g_io_out_5_bits_vpu_isDependOldVd !== x_io_out_5_bits_vpu_isDependOldVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isDependOldVd g=%h x=%h", $time, g_io_out_5_bits_vpu_isDependOldVd, x_io_out_5_bits_vpu_isDependOldVd); end
    if (g_io_out_5_bits_vpu_isWritePartVd !== x_io_out_5_bits_vpu_isWritePartVd) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isWritePartVd g=%h x=%h", $time, g_io_out_5_bits_vpu_isWritePartVd, x_io_out_5_bits_vpu_isWritePartVd); end
    if (g_io_out_5_bits_vpu_isVleff !== x_io_out_5_bits_vpu_isVleff) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vpu_isVleff g=%h x=%h", $time, g_io_out_5_bits_vpu_isVleff, x_io_out_5_bits_vpu_isVleff); end
    if (g_io_out_5_bits_vlsInstr !== x_io_out_5_bits_vlsInstr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_vlsInstr g=%h x=%h", $time, g_io_out_5_bits_vlsInstr, x_io_out_5_bits_vlsInstr); end
    if (g_io_out_5_bits_wfflags !== x_io_out_5_bits_wfflags) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_wfflags g=%h x=%h", $time, g_io_out_5_bits_wfflags, x_io_out_5_bits_wfflags); end
    if (g_io_out_5_bits_isMove !== x_io_out_5_bits_isMove) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_isMove g=%h x=%h", $time, g_io_out_5_bits_isMove, x_io_out_5_bits_isMove); end
    if (g_io_out_5_bits_uopIdx !== x_io_out_5_bits_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_uopIdx g=%h x=%h", $time, g_io_out_5_bits_uopIdx, x_io_out_5_bits_uopIdx); end
    if (g_io_out_5_bits_uopSplitType !== x_io_out_5_bits_uopSplitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_uopSplitType g=%h x=%h", $time, g_io_out_5_bits_uopSplitType, x_io_out_5_bits_uopSplitType); end
    if (g_io_out_5_bits_isVset !== x_io_out_5_bits_isVset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_isVset g=%h x=%h", $time, g_io_out_5_bits_isVset, x_io_out_5_bits_isVset); end
    if (g_io_out_5_bits_firstUop !== x_io_out_5_bits_firstUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_firstUop g=%h x=%h", $time, g_io_out_5_bits_firstUop, x_io_out_5_bits_firstUop); end
    if (g_io_out_5_bits_lastUop !== x_io_out_5_bits_lastUop) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_lastUop g=%h x=%h", $time, g_io_out_5_bits_lastUop, x_io_out_5_bits_lastUop); end
    if (g_io_out_5_bits_numUops !== x_io_out_5_bits_numUops) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_numUops g=%h x=%h", $time, g_io_out_5_bits_numUops, x_io_out_5_bits_numUops); end
    if (g_io_out_5_bits_numWB !== x_io_out_5_bits_numWB) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_numWB g=%h x=%h", $time, g_io_out_5_bits_numWB, x_io_out_5_bits_numWB); end
    if (g_io_out_5_bits_commitType !== x_io_out_5_bits_commitType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_commitType g=%h x=%h", $time, g_io_out_5_bits_commitType, x_io_out_5_bits_commitType); end
    if (g_io_out_5_bits_debug_fuType !== x_io_out_5_bits_debug_fuType) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_debug_fuType g=%h x=%h", $time, g_io_out_5_bits_debug_fuType, x_io_out_5_bits_debug_fuType); end
    if (g_io_out_5_bits_debug_seqNum_seqNum !== x_io_out_5_bits_debug_seqNum_seqNum) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_debug_seqNum_seqNum g=%h x=%h", $time, g_io_out_5_bits_debug_seqNum_seqNum, x_io_out_5_bits_debug_seqNum_seqNum); end
    if (g_io_out_5_bits_debug_seqNum_uopIdx !== x_io_out_5_bits_debug_seqNum_uopIdx) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_out_5_bits_debug_seqNum_uopIdx g=%h x=%h", $time, g_io_out_5_bits_debug_seqNum_uopIdx, x_io_out_5_bits_debug_seqNum_uopIdx); end
    if (g_io_intRat_0_0_hold !== x_io_intRat_0_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_0_0_hold g=%h x=%h", $time, g_io_intRat_0_0_hold, x_io_intRat_0_0_hold); end
    if (g_io_intRat_0_0_addr !== x_io_intRat_0_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_0_0_addr g=%h x=%h", $time, g_io_intRat_0_0_addr, x_io_intRat_0_0_addr); end
    if (g_io_intRat_0_1_hold !== x_io_intRat_0_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_0_1_hold g=%h x=%h", $time, g_io_intRat_0_1_hold, x_io_intRat_0_1_hold); end
    if (g_io_intRat_0_1_addr !== x_io_intRat_0_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_0_1_addr g=%h x=%h", $time, g_io_intRat_0_1_addr, x_io_intRat_0_1_addr); end
    if (g_io_intRat_1_0_hold !== x_io_intRat_1_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_1_0_hold g=%h x=%h", $time, g_io_intRat_1_0_hold, x_io_intRat_1_0_hold); end
    if (g_io_intRat_1_0_addr !== x_io_intRat_1_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_1_0_addr g=%h x=%h", $time, g_io_intRat_1_0_addr, x_io_intRat_1_0_addr); end
    if (g_io_intRat_1_1_hold !== x_io_intRat_1_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_1_1_hold g=%h x=%h", $time, g_io_intRat_1_1_hold, x_io_intRat_1_1_hold); end
    if (g_io_intRat_1_1_addr !== x_io_intRat_1_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_1_1_addr g=%h x=%h", $time, g_io_intRat_1_1_addr, x_io_intRat_1_1_addr); end
    if (g_io_intRat_2_0_hold !== x_io_intRat_2_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_2_0_hold g=%h x=%h", $time, g_io_intRat_2_0_hold, x_io_intRat_2_0_hold); end
    if (g_io_intRat_2_0_addr !== x_io_intRat_2_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_2_0_addr g=%h x=%h", $time, g_io_intRat_2_0_addr, x_io_intRat_2_0_addr); end
    if (g_io_intRat_2_1_hold !== x_io_intRat_2_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_2_1_hold g=%h x=%h", $time, g_io_intRat_2_1_hold, x_io_intRat_2_1_hold); end
    if (g_io_intRat_2_1_addr !== x_io_intRat_2_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_2_1_addr g=%h x=%h", $time, g_io_intRat_2_1_addr, x_io_intRat_2_1_addr); end
    if (g_io_intRat_3_0_hold !== x_io_intRat_3_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_3_0_hold g=%h x=%h", $time, g_io_intRat_3_0_hold, x_io_intRat_3_0_hold); end
    if (g_io_intRat_3_0_addr !== x_io_intRat_3_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_3_0_addr g=%h x=%h", $time, g_io_intRat_3_0_addr, x_io_intRat_3_0_addr); end
    if (g_io_intRat_3_1_hold !== x_io_intRat_3_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_3_1_hold g=%h x=%h", $time, g_io_intRat_3_1_hold, x_io_intRat_3_1_hold); end
    if (g_io_intRat_3_1_addr !== x_io_intRat_3_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_3_1_addr g=%h x=%h", $time, g_io_intRat_3_1_addr, x_io_intRat_3_1_addr); end
    if (g_io_intRat_4_0_hold !== x_io_intRat_4_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_4_0_hold g=%h x=%h", $time, g_io_intRat_4_0_hold, x_io_intRat_4_0_hold); end
    if (g_io_intRat_4_0_addr !== x_io_intRat_4_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_4_0_addr g=%h x=%h", $time, g_io_intRat_4_0_addr, x_io_intRat_4_0_addr); end
    if (g_io_intRat_4_1_hold !== x_io_intRat_4_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_4_1_hold g=%h x=%h", $time, g_io_intRat_4_1_hold, x_io_intRat_4_1_hold); end
    if (g_io_intRat_4_1_addr !== x_io_intRat_4_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_4_1_addr g=%h x=%h", $time, g_io_intRat_4_1_addr, x_io_intRat_4_1_addr); end
    if (g_io_intRat_5_0_hold !== x_io_intRat_5_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_5_0_hold g=%h x=%h", $time, g_io_intRat_5_0_hold, x_io_intRat_5_0_hold); end
    if (g_io_intRat_5_0_addr !== x_io_intRat_5_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_5_0_addr g=%h x=%h", $time, g_io_intRat_5_0_addr, x_io_intRat_5_0_addr); end
    if (g_io_intRat_5_1_hold !== x_io_intRat_5_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_5_1_hold g=%h x=%h", $time, g_io_intRat_5_1_hold, x_io_intRat_5_1_hold); end
    if (g_io_intRat_5_1_addr !== x_io_intRat_5_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_intRat_5_1_addr g=%h x=%h", $time, g_io_intRat_5_1_addr, x_io_intRat_5_1_addr); end
    if (g_io_fpRat_0_0_hold !== x_io_fpRat_0_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_0_hold g=%h x=%h", $time, g_io_fpRat_0_0_hold, x_io_fpRat_0_0_hold); end
    if (g_io_fpRat_0_0_addr !== x_io_fpRat_0_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_0_addr g=%h x=%h", $time, g_io_fpRat_0_0_addr, x_io_fpRat_0_0_addr); end
    if (g_io_fpRat_0_1_hold !== x_io_fpRat_0_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_1_hold g=%h x=%h", $time, g_io_fpRat_0_1_hold, x_io_fpRat_0_1_hold); end
    if (g_io_fpRat_0_1_addr !== x_io_fpRat_0_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_1_addr g=%h x=%h", $time, g_io_fpRat_0_1_addr, x_io_fpRat_0_1_addr); end
    if (g_io_fpRat_0_2_hold !== x_io_fpRat_0_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_2_hold g=%h x=%h", $time, g_io_fpRat_0_2_hold, x_io_fpRat_0_2_hold); end
    if (g_io_fpRat_0_2_addr !== x_io_fpRat_0_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_0_2_addr g=%h x=%h", $time, g_io_fpRat_0_2_addr, x_io_fpRat_0_2_addr); end
    if (g_io_fpRat_1_0_hold !== x_io_fpRat_1_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_0_hold g=%h x=%h", $time, g_io_fpRat_1_0_hold, x_io_fpRat_1_0_hold); end
    if (g_io_fpRat_1_0_addr !== x_io_fpRat_1_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_0_addr g=%h x=%h", $time, g_io_fpRat_1_0_addr, x_io_fpRat_1_0_addr); end
    if (g_io_fpRat_1_1_hold !== x_io_fpRat_1_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_1_hold g=%h x=%h", $time, g_io_fpRat_1_1_hold, x_io_fpRat_1_1_hold); end
    if (g_io_fpRat_1_1_addr !== x_io_fpRat_1_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_1_addr g=%h x=%h", $time, g_io_fpRat_1_1_addr, x_io_fpRat_1_1_addr); end
    if (g_io_fpRat_1_2_hold !== x_io_fpRat_1_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_2_hold g=%h x=%h", $time, g_io_fpRat_1_2_hold, x_io_fpRat_1_2_hold); end
    if (g_io_fpRat_1_2_addr !== x_io_fpRat_1_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_1_2_addr g=%h x=%h", $time, g_io_fpRat_1_2_addr, x_io_fpRat_1_2_addr); end
    if (g_io_fpRat_2_0_hold !== x_io_fpRat_2_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_0_hold g=%h x=%h", $time, g_io_fpRat_2_0_hold, x_io_fpRat_2_0_hold); end
    if (g_io_fpRat_2_0_addr !== x_io_fpRat_2_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_0_addr g=%h x=%h", $time, g_io_fpRat_2_0_addr, x_io_fpRat_2_0_addr); end
    if (g_io_fpRat_2_1_hold !== x_io_fpRat_2_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_1_hold g=%h x=%h", $time, g_io_fpRat_2_1_hold, x_io_fpRat_2_1_hold); end
    if (g_io_fpRat_2_1_addr !== x_io_fpRat_2_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_1_addr g=%h x=%h", $time, g_io_fpRat_2_1_addr, x_io_fpRat_2_1_addr); end
    if (g_io_fpRat_2_2_hold !== x_io_fpRat_2_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_2_hold g=%h x=%h", $time, g_io_fpRat_2_2_hold, x_io_fpRat_2_2_hold); end
    if (g_io_fpRat_2_2_addr !== x_io_fpRat_2_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_2_2_addr g=%h x=%h", $time, g_io_fpRat_2_2_addr, x_io_fpRat_2_2_addr); end
    if (g_io_fpRat_3_0_hold !== x_io_fpRat_3_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_0_hold g=%h x=%h", $time, g_io_fpRat_3_0_hold, x_io_fpRat_3_0_hold); end
    if (g_io_fpRat_3_0_addr !== x_io_fpRat_3_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_0_addr g=%h x=%h", $time, g_io_fpRat_3_0_addr, x_io_fpRat_3_0_addr); end
    if (g_io_fpRat_3_1_hold !== x_io_fpRat_3_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_1_hold g=%h x=%h", $time, g_io_fpRat_3_1_hold, x_io_fpRat_3_1_hold); end
    if (g_io_fpRat_3_1_addr !== x_io_fpRat_3_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_1_addr g=%h x=%h", $time, g_io_fpRat_3_1_addr, x_io_fpRat_3_1_addr); end
    if (g_io_fpRat_3_2_hold !== x_io_fpRat_3_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_2_hold g=%h x=%h", $time, g_io_fpRat_3_2_hold, x_io_fpRat_3_2_hold); end
    if (g_io_fpRat_3_2_addr !== x_io_fpRat_3_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_3_2_addr g=%h x=%h", $time, g_io_fpRat_3_2_addr, x_io_fpRat_3_2_addr); end
    if (g_io_fpRat_4_0_hold !== x_io_fpRat_4_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_0_hold g=%h x=%h", $time, g_io_fpRat_4_0_hold, x_io_fpRat_4_0_hold); end
    if (g_io_fpRat_4_0_addr !== x_io_fpRat_4_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_0_addr g=%h x=%h", $time, g_io_fpRat_4_0_addr, x_io_fpRat_4_0_addr); end
    if (g_io_fpRat_4_1_hold !== x_io_fpRat_4_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_1_hold g=%h x=%h", $time, g_io_fpRat_4_1_hold, x_io_fpRat_4_1_hold); end
    if (g_io_fpRat_4_1_addr !== x_io_fpRat_4_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_1_addr g=%h x=%h", $time, g_io_fpRat_4_1_addr, x_io_fpRat_4_1_addr); end
    if (g_io_fpRat_4_2_hold !== x_io_fpRat_4_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_2_hold g=%h x=%h", $time, g_io_fpRat_4_2_hold, x_io_fpRat_4_2_hold); end
    if (g_io_fpRat_4_2_addr !== x_io_fpRat_4_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_4_2_addr g=%h x=%h", $time, g_io_fpRat_4_2_addr, x_io_fpRat_4_2_addr); end
    if (g_io_fpRat_5_0_hold !== x_io_fpRat_5_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_0_hold g=%h x=%h", $time, g_io_fpRat_5_0_hold, x_io_fpRat_5_0_hold); end
    if (g_io_fpRat_5_0_addr !== x_io_fpRat_5_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_0_addr g=%h x=%h", $time, g_io_fpRat_5_0_addr, x_io_fpRat_5_0_addr); end
    if (g_io_fpRat_5_1_hold !== x_io_fpRat_5_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_1_hold g=%h x=%h", $time, g_io_fpRat_5_1_hold, x_io_fpRat_5_1_hold); end
    if (g_io_fpRat_5_1_addr !== x_io_fpRat_5_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_1_addr g=%h x=%h", $time, g_io_fpRat_5_1_addr, x_io_fpRat_5_1_addr); end
    if (g_io_fpRat_5_2_hold !== x_io_fpRat_5_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_2_hold g=%h x=%h", $time, g_io_fpRat_5_2_hold, x_io_fpRat_5_2_hold); end
    if (g_io_fpRat_5_2_addr !== x_io_fpRat_5_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_fpRat_5_2_addr g=%h x=%h", $time, g_io_fpRat_5_2_addr, x_io_fpRat_5_2_addr); end
    if (g_io_vecRat_0_0_hold !== x_io_vecRat_0_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_0_hold g=%h x=%h", $time, g_io_vecRat_0_0_hold, x_io_vecRat_0_0_hold); end
    if (g_io_vecRat_0_0_addr !== x_io_vecRat_0_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_0_addr g=%h x=%h", $time, g_io_vecRat_0_0_addr, x_io_vecRat_0_0_addr); end
    if (g_io_vecRat_0_1_hold !== x_io_vecRat_0_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_1_hold g=%h x=%h", $time, g_io_vecRat_0_1_hold, x_io_vecRat_0_1_hold); end
    if (g_io_vecRat_0_1_addr !== x_io_vecRat_0_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_1_addr g=%h x=%h", $time, g_io_vecRat_0_1_addr, x_io_vecRat_0_1_addr); end
    if (g_io_vecRat_0_2_hold !== x_io_vecRat_0_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_2_hold g=%h x=%h", $time, g_io_vecRat_0_2_hold, x_io_vecRat_0_2_hold); end
    if (g_io_vecRat_0_2_addr !== x_io_vecRat_0_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_0_2_addr g=%h x=%h", $time, g_io_vecRat_0_2_addr, x_io_vecRat_0_2_addr); end
    if (g_io_vecRat_1_0_hold !== x_io_vecRat_1_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_0_hold g=%h x=%h", $time, g_io_vecRat_1_0_hold, x_io_vecRat_1_0_hold); end
    if (g_io_vecRat_1_0_addr !== x_io_vecRat_1_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_0_addr g=%h x=%h", $time, g_io_vecRat_1_0_addr, x_io_vecRat_1_0_addr); end
    if (g_io_vecRat_1_1_hold !== x_io_vecRat_1_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_1_hold g=%h x=%h", $time, g_io_vecRat_1_1_hold, x_io_vecRat_1_1_hold); end
    if (g_io_vecRat_1_1_addr !== x_io_vecRat_1_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_1_addr g=%h x=%h", $time, g_io_vecRat_1_1_addr, x_io_vecRat_1_1_addr); end
    if (g_io_vecRat_1_2_hold !== x_io_vecRat_1_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_2_hold g=%h x=%h", $time, g_io_vecRat_1_2_hold, x_io_vecRat_1_2_hold); end
    if (g_io_vecRat_1_2_addr !== x_io_vecRat_1_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_1_2_addr g=%h x=%h", $time, g_io_vecRat_1_2_addr, x_io_vecRat_1_2_addr); end
    if (g_io_vecRat_2_0_hold !== x_io_vecRat_2_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_0_hold g=%h x=%h", $time, g_io_vecRat_2_0_hold, x_io_vecRat_2_0_hold); end
    if (g_io_vecRat_2_0_addr !== x_io_vecRat_2_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_0_addr g=%h x=%h", $time, g_io_vecRat_2_0_addr, x_io_vecRat_2_0_addr); end
    if (g_io_vecRat_2_1_hold !== x_io_vecRat_2_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_1_hold g=%h x=%h", $time, g_io_vecRat_2_1_hold, x_io_vecRat_2_1_hold); end
    if (g_io_vecRat_2_1_addr !== x_io_vecRat_2_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_1_addr g=%h x=%h", $time, g_io_vecRat_2_1_addr, x_io_vecRat_2_1_addr); end
    if (g_io_vecRat_2_2_hold !== x_io_vecRat_2_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_2_hold g=%h x=%h", $time, g_io_vecRat_2_2_hold, x_io_vecRat_2_2_hold); end
    if (g_io_vecRat_2_2_addr !== x_io_vecRat_2_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_2_2_addr g=%h x=%h", $time, g_io_vecRat_2_2_addr, x_io_vecRat_2_2_addr); end
    if (g_io_vecRat_3_0_hold !== x_io_vecRat_3_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_0_hold g=%h x=%h", $time, g_io_vecRat_3_0_hold, x_io_vecRat_3_0_hold); end
    if (g_io_vecRat_3_0_addr !== x_io_vecRat_3_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_0_addr g=%h x=%h", $time, g_io_vecRat_3_0_addr, x_io_vecRat_3_0_addr); end
    if (g_io_vecRat_3_1_hold !== x_io_vecRat_3_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_1_hold g=%h x=%h", $time, g_io_vecRat_3_1_hold, x_io_vecRat_3_1_hold); end
    if (g_io_vecRat_3_1_addr !== x_io_vecRat_3_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_1_addr g=%h x=%h", $time, g_io_vecRat_3_1_addr, x_io_vecRat_3_1_addr); end
    if (g_io_vecRat_3_2_hold !== x_io_vecRat_3_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_2_hold g=%h x=%h", $time, g_io_vecRat_3_2_hold, x_io_vecRat_3_2_hold); end
    if (g_io_vecRat_3_2_addr !== x_io_vecRat_3_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_3_2_addr g=%h x=%h", $time, g_io_vecRat_3_2_addr, x_io_vecRat_3_2_addr); end
    if (g_io_vecRat_4_0_hold !== x_io_vecRat_4_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_0_hold g=%h x=%h", $time, g_io_vecRat_4_0_hold, x_io_vecRat_4_0_hold); end
    if (g_io_vecRat_4_0_addr !== x_io_vecRat_4_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_0_addr g=%h x=%h", $time, g_io_vecRat_4_0_addr, x_io_vecRat_4_0_addr); end
    if (g_io_vecRat_4_1_hold !== x_io_vecRat_4_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_1_hold g=%h x=%h", $time, g_io_vecRat_4_1_hold, x_io_vecRat_4_1_hold); end
    if (g_io_vecRat_4_1_addr !== x_io_vecRat_4_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_1_addr g=%h x=%h", $time, g_io_vecRat_4_1_addr, x_io_vecRat_4_1_addr); end
    if (g_io_vecRat_4_2_hold !== x_io_vecRat_4_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_2_hold g=%h x=%h", $time, g_io_vecRat_4_2_hold, x_io_vecRat_4_2_hold); end
    if (g_io_vecRat_4_2_addr !== x_io_vecRat_4_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_4_2_addr g=%h x=%h", $time, g_io_vecRat_4_2_addr, x_io_vecRat_4_2_addr); end
    if (g_io_vecRat_5_0_hold !== x_io_vecRat_5_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_0_hold g=%h x=%h", $time, g_io_vecRat_5_0_hold, x_io_vecRat_5_0_hold); end
    if (g_io_vecRat_5_0_addr !== x_io_vecRat_5_0_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_0_addr g=%h x=%h", $time, g_io_vecRat_5_0_addr, x_io_vecRat_5_0_addr); end
    if (g_io_vecRat_5_1_hold !== x_io_vecRat_5_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_1_hold g=%h x=%h", $time, g_io_vecRat_5_1_hold, x_io_vecRat_5_1_hold); end
    if (g_io_vecRat_5_1_addr !== x_io_vecRat_5_1_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_1_addr g=%h x=%h", $time, g_io_vecRat_5_1_addr, x_io_vecRat_5_1_addr); end
    if (g_io_vecRat_5_2_hold !== x_io_vecRat_5_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_2_hold g=%h x=%h", $time, g_io_vecRat_5_2_hold, x_io_vecRat_5_2_hold); end
    if (g_io_vecRat_5_2_addr !== x_io_vecRat_5_2_addr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vecRat_5_2_addr g=%h x=%h", $time, g_io_vecRat_5_2_addr, x_io_vecRat_5_2_addr); end
    if (g_io_v0Rat_0_hold !== x_io_v0Rat_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_0_hold g=%h x=%h", $time, g_io_v0Rat_0_hold, x_io_v0Rat_0_hold); end
    if (g_io_v0Rat_1_hold !== x_io_v0Rat_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_1_hold g=%h x=%h", $time, g_io_v0Rat_1_hold, x_io_v0Rat_1_hold); end
    if (g_io_v0Rat_2_hold !== x_io_v0Rat_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_2_hold g=%h x=%h", $time, g_io_v0Rat_2_hold, x_io_v0Rat_2_hold); end
    if (g_io_v0Rat_3_hold !== x_io_v0Rat_3_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_3_hold g=%h x=%h", $time, g_io_v0Rat_3_hold, x_io_v0Rat_3_hold); end
    if (g_io_v0Rat_4_hold !== x_io_v0Rat_4_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_4_hold g=%h x=%h", $time, g_io_v0Rat_4_hold, x_io_v0Rat_4_hold); end
    if (g_io_v0Rat_5_hold !== x_io_v0Rat_5_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_v0Rat_5_hold g=%h x=%h", $time, g_io_v0Rat_5_hold, x_io_v0Rat_5_hold); end
    if (g_io_vlRat_0_hold !== x_io_vlRat_0_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_0_hold g=%h x=%h", $time, g_io_vlRat_0_hold, x_io_vlRat_0_hold); end
    if (g_io_vlRat_1_hold !== x_io_vlRat_1_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_1_hold g=%h x=%h", $time, g_io_vlRat_1_hold, x_io_vlRat_1_hold); end
    if (g_io_vlRat_2_hold !== x_io_vlRat_2_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_2_hold g=%h x=%h", $time, g_io_vlRat_2_hold, x_io_vlRat_2_hold); end
    if (g_io_vlRat_3_hold !== x_io_vlRat_3_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_3_hold g=%h x=%h", $time, g_io_vlRat_3_hold, x_io_vlRat_3_hold); end
    if (g_io_vlRat_4_hold !== x_io_vlRat_4_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_4_hold g=%h x=%h", $time, g_io_vlRat_4_hold, x_io_vlRat_4_hold); end
    if (g_io_vlRat_5_hold !== x_io_vlRat_5_hold) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_vlRat_5_hold g=%h x=%h", $time, g_io_vlRat_5_hold, x_io_vlRat_5_hold); end
    if (g_io_stallReason_in_backReason_valid !== x_io_stallReason_in_backReason_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_in_backReason_valid g=%h x=%h", $time, g_io_stallReason_in_backReason_valid, x_io_stallReason_in_backReason_valid); end
    if (g_io_stallReason_in_backReason_bits !== x_io_stallReason_in_backReason_bits) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_in_backReason_bits g=%h x=%h", $time, g_io_stallReason_in_backReason_bits, x_io_stallReason_in_backReason_bits); end
    if (g_io_stallReason_out_reason_0 !== x_io_stallReason_out_reason_0) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_0 g=%h x=%h", $time, g_io_stallReason_out_reason_0, x_io_stallReason_out_reason_0); end
    if (g_io_stallReason_out_reason_1 !== x_io_stallReason_out_reason_1) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_1 g=%h x=%h", $time, g_io_stallReason_out_reason_1, x_io_stallReason_out_reason_1); end
    if (g_io_stallReason_out_reason_2 !== x_io_stallReason_out_reason_2) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_2 g=%h x=%h", $time, g_io_stallReason_out_reason_2, x_io_stallReason_out_reason_2); end
    if (g_io_stallReason_out_reason_3 !== x_io_stallReason_out_reason_3) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_3 g=%h x=%h", $time, g_io_stallReason_out_reason_3, x_io_stallReason_out_reason_3); end
    if (g_io_stallReason_out_reason_4 !== x_io_stallReason_out_reason_4) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_4 g=%h x=%h", $time, g_io_stallReason_out_reason_4, x_io_stallReason_out_reason_4); end
    if (g_io_stallReason_out_reason_5 !== x_io_stallReason_out_reason_5) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_stallReason_out_reason_5 g=%h x=%h", $time, g_io_stallReason_out_reason_5, x_io_stallReason_out_reason_5); end
    if (g_io_toCSR_trapInstInfo_valid !== x_io_toCSR_trapInstInfo_valid) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_toCSR_trapInstInfo_valid g=%h x=%h", $time, g_io_toCSR_trapInstInfo_valid, x_io_toCSR_trapInstInfo_valid); end
    if (g_io_toCSR_trapInstInfo_bits_instr !== x_io_toCSR_trapInstInfo_bits_instr) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_toCSR_trapInstInfo_bits_instr g=%h x=%h", $time, g_io_toCSR_trapInstInfo_bits_instr, x_io_toCSR_trapInstInfo_bits_instr); end
    if (g_io_toCSR_trapInstInfo_bits_ftqPtr_flag !== x_io_toCSR_trapInstInfo_bits_ftqPtr_flag) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_toCSR_trapInstInfo_bits_ftqPtr_flag g=%h x=%h", $time, g_io_toCSR_trapInstInfo_bits_ftqPtr_flag, x_io_toCSR_trapInstInfo_bits_ftqPtr_flag); end
    if (g_io_toCSR_trapInstInfo_bits_ftqPtr_value !== x_io_toCSR_trapInstInfo_bits_ftqPtr_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_toCSR_trapInstInfo_bits_ftqPtr_value g=%h x=%h", $time, g_io_toCSR_trapInstInfo_bits_ftqPtr_value, x_io_toCSR_trapInstInfo_bits_ftqPtr_value); end
    if (g_io_toCSR_trapInstInfo_bits_ftqOffset !== x_io_toCSR_trapInstInfo_bits_ftqOffset) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_toCSR_trapInstInfo_bits_ftqOffset g=%h x=%h", $time, g_io_toCSR_trapInstInfo_bits_ftqOffset, x_io_toCSR_trapInstInfo_bits_ftqOffset); end
    if (g_io_perf_0_value !== x_io_perf_0_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_0_value g=%h x=%h", $time, g_io_perf_0_value, x_io_perf_0_value); end
    if (g_io_perf_1_value !== x_io_perf_1_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_1_value g=%h x=%h", $time, g_io_perf_1_value, x_io_perf_1_value); end
    if (g_io_perf_2_value !== x_io_perf_2_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_2_value g=%h x=%h", $time, g_io_perf_2_value, x_io_perf_2_value); end
    if (g_io_perf_3_value !== x_io_perf_3_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_3_value g=%h x=%h", $time, g_io_perf_3_value, x_io_perf_3_value); end
    if (g_io_perf_4_value !== x_io_perf_4_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_4_value g=%h x=%h", $time, g_io_perf_4_value, x_io_perf_4_value); end
    if (g_io_perf_5_value !== x_io_perf_5_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_5_value g=%h x=%h", $time, g_io_perf_5_value, x_io_perf_5_value); end
    if (g_io_perf_6_value !== x_io_perf_6_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_6_value g=%h x=%h", $time, g_io_perf_6_value, x_io_perf_6_value); end
    if (g_io_perf_7_value !== x_io_perf_7_value) begin errors++; if (errors < 20) $display("MISMATCH @%0t io_perf_7_value g=%h x=%h", $time, g_io_perf_7_value, x_io_perf_7_value); end
  endtask

  longint cov_cnum[8]; longint cov_inready[7]; longint cov_outvalid[7]; longint cov_trap = 0, cov_resume = 0, cov_redir_cplx = 0, cov_cplx_fire = 0, cov_backpressure = 0;
  task automatic collect_cov();
    int nr = 0, nv = 0;
    cov_cnum[u_gold.complexNum]++;
    if (g_io_in_0_ready === 1'b1) nr++;
    if (g_io_out_0_valid === 1'b1) nv++;
    if (g_io_in_1_ready === 1'b1) nr++;
    if (g_io_out_1_valid === 1'b1) nv++;
    if (g_io_in_2_ready === 1'b1) nr++;
    if (g_io_out_2_valid === 1'b1) nv++;
    if (g_io_in_3_ready === 1'b1) nr++;
    if (g_io_out_3_valid === 1'b1) nv++;
    if (g_io_in_4_ready === 1'b1) nr++;
    if (g_io_out_4_valid === 1'b1) nv++;
    if (g_io_in_5_ready === 1'b1) nr++;
    if (g_io_out_5_valid === 1'b1) nv++;
    cov_inready[nr]++; cov_outvalid[nv]++;
    if (g_io_toCSR_trapInstInfo_valid === 1'b1) cov_trap++;
    if (io_fromRob_isResumeVType) cov_resume++;
    if (io_redirect && u_gold.complexNum != 0) cov_redir_cplx++;
    if (u_gold._decoderComp_io_in_ready && u_gold._decoderComp_io_in_valid_T_1) cov_cplx_fire++;
    if (!io_out_0_ready) cov_backpressure++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 8; i++) cov_cnum[i] = 0;
    for (int i = 0; i < 7; i++) begin cov_inready[i] = 0; cov_outvalid[i] = 0; end
    i_ready_0 = 1; rst = 1'b1; drive_inputs(1'b1);
    repeat (4) @(negedge clk);
    rst = 1'b0;
    for (longint c = 0; c < NCYCLES; c++) begin
      // 运行中多次异步复位（每 ~16000 拍 2 拍），复位期间照常打激励并比对
      rst = ((c % 16384) < 2) && (c > WARMUP);
      i_ready_0 = next_ready();
      drive_inputs(c < WARMUP);
      #1;
      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end
      @(negedge clk);
    end
    $display("=== COVERAGE (DecodeStage) ===");
    $display("  checks=%0d trap=%0d resume=%0d redirect_while_complex=%0d complex_fire=%0d backpressure=%0d", checks, cov_trap, cov_resume, cov_redir_cplx, cov_cplx_fire, cov_backpressure);
    for (int i = 0; i < 7; i++) $display("  complexNum=%0d: %0d   #in_ready=%0d: %0d   #out_valid=%0d: %0d", i, cov_cnum[i], i, cov_inready[i], i, cov_outvalid[i]);
    begin
      int bad = 0;
      for (int i = 0; i < 7; i++) if (cov_cnum[i] == 0 || cov_inready[i] == 0 || cov_outvalid[i] == 0) bad++;
      if (bad != 0 || cov_trap == 0 || cov_resume == 0 || cov_redir_cplx == 0 || cov_cplx_fire == 0 || cov_backpressure == 0) begin
        $display("COVERAGE INSUFFICIENT"); errors++;
      end
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
