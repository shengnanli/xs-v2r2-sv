// PipelineConnectPipe UT —— golden vs 派生 PipelineConnectPipe_xs 双例化，同激励逐拍比全部输出。
//
// 被测语义（核 xs_PipelineConnectPipe_core，见 rtl/backend/PipelineConnectPipe.sv）：
//   in_ready = out_ready；fire = in_valid & out_ready
//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）
//   data     = RegEnable(in_bits, fire)；13 个无入口字段 fire 拍装 0
//
// 覆盖闸（流水连接件极易假绿：握手永远畅通、flush 永不触发也能 errors=0）：
//   fire / 反压(in_valid & ~out_ready) / hold(valid & ~rightOutFire) / deq(valid & rightOutFire) /
//   占用中被改写(valid & fire) / flush 命中占用中的表项 / flush 与 fire 同拍（冲刷优先级）/
//   入口 payload 每一位都取到过 1、也取到过 0（位宽写窄或字段漏掉不会假绿）。
// 采样时机：覆盖在**时钟沿之前**采（沿后采永远看不到 flush——它把 valid 清了）。
// 无入口字段的出口在首个 fire 前是 X（golden 亦然）：CHECK 宏遇 golden X 跳过，之后恒 0 参与比对。
//
// 本文件由 scripts/gen_cb_connect.py 生成，勿手改。
`timescale 1ns/1ps

`define CHECK(TAG,SIG) begin \
  if (!$isunknown(g_``TAG``_``SIG)) begin \
    checks++; \
    if (g_``TAG``_``SIG !== i_``TAG``_``SIG) begin \
      errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s.%s g=%0h i=%0h", $time, `"TAG`", `"SIG`", \
                                 g_``TAG``_``SIG, i_``TAG``_``SIG); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  longint checks = 0;
  always #5 clock = ~clock;

  int cov_fail = 0;
  task automatic gate(string nm, longint got, longint need, string why);
    if (got < need) begin
      $display("COVERAGE HOLE: %s = %0d < %0d —— %s", nm, got, need, why);
      cov_fail++;
    end
  endtask

  // ---- 激励与两侧输出 ----
  logic io_in_valid, io_out_ready, io_rightOutFire, io_isFlush;
  logic [31:0] io_in_bits_instr;
  logic [49:0] io_in_bits_pc;
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
  logic io_in_bits_preDecodeInfo_valid;
  logic io_in_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_bits_preDecodeInfo_brType;
  logic io_in_bits_preDecodeInfo_isCall;
  logic io_in_bits_preDecodeInfo_isRet;
  logic io_in_bits_pred_taken;
  logic io_in_bits_crossPageIPFFix;
  logic io_in_bits_ftqPtr_flag;
  logic [5:0] io_in_bits_ftqPtr_value;
  logic [3:0] io_in_bits_ftqOffset;
  logic io_in_bits_satpFlushFirstFetchFault;
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
  logic io_in_bits_vpu_isReverse;
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
  logic [6:0] io_in_bits_numUops;
  logic [6:0] io_in_bits_numWB;
  logic [2:0] io_in_bits_commitType;
  logic [34:0] io_in_bits_debug_fuType;
  logic [55:0] io_in_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_debug_seqNum_uopIdx;
  wire  g_p_io_in_ready, i_p_io_in_ready, g_p_io_out_valid, i_p_io_out_valid;
  wire  [31:0] g_p_io_out_bits_instr, i_p_io_out_bits_instr;
  wire  [49:0] g_p_io_out_bits_pc, i_p_io_out_bits_pc;
  wire  [9:0] g_p_io_out_bits_foldpc, i_p_io_out_bits_foldpc;
  wire  g_p_io_out_bits_exceptionVec_0, i_p_io_out_bits_exceptionVec_0;
  wire  g_p_io_out_bits_exceptionVec_1, i_p_io_out_bits_exceptionVec_1;
  wire  g_p_io_out_bits_exceptionVec_2, i_p_io_out_bits_exceptionVec_2;
  wire  g_p_io_out_bits_exceptionVec_3, i_p_io_out_bits_exceptionVec_3;
  wire  g_p_io_out_bits_exceptionVec_4, i_p_io_out_bits_exceptionVec_4;
  wire  g_p_io_out_bits_exceptionVec_5, i_p_io_out_bits_exceptionVec_5;
  wire  g_p_io_out_bits_exceptionVec_6, i_p_io_out_bits_exceptionVec_6;
  wire  g_p_io_out_bits_exceptionVec_7, i_p_io_out_bits_exceptionVec_7;
  wire  g_p_io_out_bits_exceptionVec_8, i_p_io_out_bits_exceptionVec_8;
  wire  g_p_io_out_bits_exceptionVec_9, i_p_io_out_bits_exceptionVec_9;
  wire  g_p_io_out_bits_exceptionVec_10, i_p_io_out_bits_exceptionVec_10;
  wire  g_p_io_out_bits_exceptionVec_11, i_p_io_out_bits_exceptionVec_11;
  wire  g_p_io_out_bits_exceptionVec_12, i_p_io_out_bits_exceptionVec_12;
  wire  g_p_io_out_bits_exceptionVec_13, i_p_io_out_bits_exceptionVec_13;
  wire  g_p_io_out_bits_exceptionVec_14, i_p_io_out_bits_exceptionVec_14;
  wire  g_p_io_out_bits_exceptionVec_15, i_p_io_out_bits_exceptionVec_15;
  wire  g_p_io_out_bits_exceptionVec_16, i_p_io_out_bits_exceptionVec_16;
  wire  g_p_io_out_bits_exceptionVec_17, i_p_io_out_bits_exceptionVec_17;
  wire  g_p_io_out_bits_exceptionVec_18, i_p_io_out_bits_exceptionVec_18;
  wire  g_p_io_out_bits_exceptionVec_19, i_p_io_out_bits_exceptionVec_19;
  wire  g_p_io_out_bits_exceptionVec_20, i_p_io_out_bits_exceptionVec_20;
  wire  g_p_io_out_bits_exceptionVec_21, i_p_io_out_bits_exceptionVec_21;
  wire  g_p_io_out_bits_exceptionVec_22, i_p_io_out_bits_exceptionVec_22;
  wire  g_p_io_out_bits_exceptionVec_23, i_p_io_out_bits_exceptionVec_23;
  wire  g_p_io_out_bits_isFetchMalAddr, i_p_io_out_bits_isFetchMalAddr;
  wire  [3:0] g_p_io_out_bits_trigger, i_p_io_out_bits_trigger;
  wire  g_p_io_out_bits_preDecodeInfo_valid, i_p_io_out_bits_preDecodeInfo_valid;
  wire  g_p_io_out_bits_preDecodeInfo_isRVC, i_p_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_p_io_out_bits_preDecodeInfo_brType, i_p_io_out_bits_preDecodeInfo_brType;
  wire  g_p_io_out_bits_preDecodeInfo_isCall, i_p_io_out_bits_preDecodeInfo_isCall;
  wire  g_p_io_out_bits_preDecodeInfo_isRet, i_p_io_out_bits_preDecodeInfo_isRet;
  wire  g_p_io_out_bits_pred_taken, i_p_io_out_bits_pred_taken;
  wire  g_p_io_out_bits_crossPageIPFFix, i_p_io_out_bits_crossPageIPFFix;
  wire  g_p_io_out_bits_ftqPtr_flag, i_p_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_p_io_out_bits_ftqPtr_value, i_p_io_out_bits_ftqPtr_value;
  wire  [3:0] g_p_io_out_bits_ftqOffset, i_p_io_out_bits_ftqOffset;
  wire  g_p_io_out_bits_satpFlushFirstFetchFault, i_p_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_p_io_out_bits_srcType_0, i_p_io_out_bits_srcType_0;
  wire  [3:0] g_p_io_out_bits_srcType_1, i_p_io_out_bits_srcType_1;
  wire  [3:0] g_p_io_out_bits_srcType_2, i_p_io_out_bits_srcType_2;
  wire  [3:0] g_p_io_out_bits_srcType_3, i_p_io_out_bits_srcType_3;
  wire  [3:0] g_p_io_out_bits_srcType_4, i_p_io_out_bits_srcType_4;
  wire  [5:0] g_p_io_out_bits_lsrc_0, i_p_io_out_bits_lsrc_0;
  wire  [5:0] g_p_io_out_bits_lsrc_1, i_p_io_out_bits_lsrc_1;
  wire  [5:0] g_p_io_out_bits_lsrc_2, i_p_io_out_bits_lsrc_2;
  wire  [5:0] g_p_io_out_bits_lsrc_3, i_p_io_out_bits_lsrc_3;
  wire  [5:0] g_p_io_out_bits_lsrc_4, i_p_io_out_bits_lsrc_4;
  wire  [5:0] g_p_io_out_bits_ldest, i_p_io_out_bits_ldest;
  wire  [34:0] g_p_io_out_bits_fuType, i_p_io_out_bits_fuType;
  wire  [8:0] g_p_io_out_bits_fuOpType, i_p_io_out_bits_fuOpType;
  wire  g_p_io_out_bits_rfWen, i_p_io_out_bits_rfWen;
  wire  g_p_io_out_bits_fpWen, i_p_io_out_bits_fpWen;
  wire  g_p_io_out_bits_vecWen, i_p_io_out_bits_vecWen;
  wire  g_p_io_out_bits_v0Wen, i_p_io_out_bits_v0Wen;
  wire  g_p_io_out_bits_vlWen, i_p_io_out_bits_vlWen;
  wire  g_p_io_out_bits_isXSTrap, i_p_io_out_bits_isXSTrap;
  wire  g_p_io_out_bits_waitForward, i_p_io_out_bits_waitForward;
  wire  g_p_io_out_bits_blockBackward, i_p_io_out_bits_blockBackward;
  wire  g_p_io_out_bits_flushPipe, i_p_io_out_bits_flushPipe;
  wire  g_p_io_out_bits_canRobCompress, i_p_io_out_bits_canRobCompress;
  wire  [3:0] g_p_io_out_bits_selImm, i_p_io_out_bits_selImm;
  wire  [21:0] g_p_io_out_bits_imm, i_p_io_out_bits_imm;
  wire  [1:0] g_p_io_out_bits_fpu_typeTagOut, i_p_io_out_bits_fpu_typeTagOut;
  wire  g_p_io_out_bits_fpu_wflags, i_p_io_out_bits_fpu_wflags;
  wire  [1:0] g_p_io_out_bits_fpu_typ, i_p_io_out_bits_fpu_typ;
  wire  [1:0] g_p_io_out_bits_fpu_fmt, i_p_io_out_bits_fpu_fmt;
  wire  [2:0] g_p_io_out_bits_fpu_rm, i_p_io_out_bits_fpu_rm;
  wire  g_p_io_out_bits_vpu_vill, i_p_io_out_bits_vpu_vill;
  wire  g_p_io_out_bits_vpu_vma, i_p_io_out_bits_vpu_vma;
  wire  g_p_io_out_bits_vpu_vta, i_p_io_out_bits_vpu_vta;
  wire  [1:0] g_p_io_out_bits_vpu_vsew, i_p_io_out_bits_vpu_vsew;
  wire  [2:0] g_p_io_out_bits_vpu_vlmul, i_p_io_out_bits_vpu_vlmul;
  wire  g_p_io_out_bits_vpu_specVill, i_p_io_out_bits_vpu_specVill;
  wire  g_p_io_out_bits_vpu_specVma, i_p_io_out_bits_vpu_specVma;
  wire  g_p_io_out_bits_vpu_specVta, i_p_io_out_bits_vpu_specVta;
  wire  [1:0] g_p_io_out_bits_vpu_specVsew, i_p_io_out_bits_vpu_specVsew;
  wire  [2:0] g_p_io_out_bits_vpu_specVlmul, i_p_io_out_bits_vpu_specVlmul;
  wire  g_p_io_out_bits_vpu_vm, i_p_io_out_bits_vpu_vm;
  wire  [7:0] g_p_io_out_bits_vpu_vstart, i_p_io_out_bits_vpu_vstart;
  wire  [2:0] g_p_io_out_bits_vpu_frm, i_p_io_out_bits_vpu_frm;
  wire  g_p_io_out_bits_vpu_fpu_isFpToVecInst, i_p_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_p_io_out_bits_vpu_fpu_isFP32Instr, i_p_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_p_io_out_bits_vpu_fpu_isFP64Instr, i_p_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_p_io_out_bits_vpu_fpu_isReduction, i_p_io_out_bits_vpu_fpu_isReduction;
  wire  g_p_io_out_bits_vpu_fpu_isFoldTo1_2, i_p_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_p_io_out_bits_vpu_fpu_isFoldTo1_4, i_p_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_p_io_out_bits_vpu_fpu_isFoldTo1_8, i_p_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_p_io_out_bits_vpu_vxrm, i_p_io_out_bits_vpu_vxrm;
  wire  [6:0] g_p_io_out_bits_vpu_vuopIdx, i_p_io_out_bits_vpu_vuopIdx;
  wire  g_p_io_out_bits_vpu_lastUop, i_p_io_out_bits_vpu_lastUop;
  wire  [127:0] g_p_io_out_bits_vpu_vmask, i_p_io_out_bits_vpu_vmask;
  wire  [7:0] g_p_io_out_bits_vpu_vl, i_p_io_out_bits_vpu_vl;
  wire  [2:0] g_p_io_out_bits_vpu_nf, i_p_io_out_bits_vpu_nf;
  wire  [1:0] g_p_io_out_bits_vpu_veew, i_p_io_out_bits_vpu_veew;
  wire  g_p_io_out_bits_vpu_isReverse, i_p_io_out_bits_vpu_isReverse;
  wire  g_p_io_out_bits_vpu_isExt, i_p_io_out_bits_vpu_isExt;
  wire  g_p_io_out_bits_vpu_isNarrow, i_p_io_out_bits_vpu_isNarrow;
  wire  g_p_io_out_bits_vpu_isDstMask, i_p_io_out_bits_vpu_isDstMask;
  wire  g_p_io_out_bits_vpu_isOpMask, i_p_io_out_bits_vpu_isOpMask;
  wire  g_p_io_out_bits_vpu_isMove, i_p_io_out_bits_vpu_isMove;
  wire  g_p_io_out_bits_vpu_isDependOldVd, i_p_io_out_bits_vpu_isDependOldVd;
  wire  g_p_io_out_bits_vpu_isWritePartVd, i_p_io_out_bits_vpu_isWritePartVd;
  wire  g_p_io_out_bits_vpu_isVleff, i_p_io_out_bits_vpu_isVleff;
  wire  g_p_io_out_bits_vlsInstr, i_p_io_out_bits_vlsInstr;
  wire  g_p_io_out_bits_wfflags, i_p_io_out_bits_wfflags;
  wire  g_p_io_out_bits_isMove, i_p_io_out_bits_isMove;
  wire  [6:0] g_p_io_out_bits_uopIdx, i_p_io_out_bits_uopIdx;
  wire  [5:0] g_p_io_out_bits_uopSplitType, i_p_io_out_bits_uopSplitType;
  wire  g_p_io_out_bits_isVset, i_p_io_out_bits_isVset;
  wire  g_p_io_out_bits_firstUop, i_p_io_out_bits_firstUop;
  wire  g_p_io_out_bits_lastUop, i_p_io_out_bits_lastUop;
  wire  [6:0] g_p_io_out_bits_numUops, i_p_io_out_bits_numUops;
  wire  [6:0] g_p_io_out_bits_numWB, i_p_io_out_bits_numWB;
  wire  [2:0] g_p_io_out_bits_commitType, i_p_io_out_bits_commitType;
  wire  [34:0] g_p_io_out_bits_debug_fuType, i_p_io_out_bits_debug_fuType;
  wire  [55:0] g_p_io_out_bits_debug_seqNum_seqNum, i_p_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_p_io_out_bits_debug_seqNum_uopIdx, i_p_io_out_bits_debug_seqNum_uopIdx;
  longint n_fire = 0, n_bp = 0, n_hold = 0, n_deq = 0, n_owr = 0, n_flush = 0, n_flfire = 0;
  logic [450:0] por = '0, pand = '1;   // 入口 payload 逐位或 / 逐位与
  wire  [450:0] pcat = {io_in_bits_instr, io_in_bits_pc, io_in_bits_foldpc, io_in_bits_exceptionVec_0, io_in_bits_exceptionVec_1, io_in_bits_exceptionVec_2, io_in_bits_exceptionVec_3, io_in_bits_exceptionVec_4, io_in_bits_exceptionVec_5, io_in_bits_exceptionVec_6, io_in_bits_exceptionVec_7, io_in_bits_exceptionVec_8, io_in_bits_exceptionVec_9, io_in_bits_exceptionVec_10, io_in_bits_exceptionVec_11, io_in_bits_exceptionVec_12, io_in_bits_exceptionVec_13, io_in_bits_exceptionVec_14, io_in_bits_exceptionVec_15, io_in_bits_exceptionVec_16, io_in_bits_exceptionVec_17, io_in_bits_exceptionVec_18, io_in_bits_exceptionVec_19, io_in_bits_exceptionVec_20, io_in_bits_exceptionVec_21, io_in_bits_exceptionVec_22, io_in_bits_exceptionVec_23, io_in_bits_isFetchMalAddr, io_in_bits_trigger, io_in_bits_preDecodeInfo_valid, io_in_bits_preDecodeInfo_isRVC, io_in_bits_preDecodeInfo_brType, io_in_bits_preDecodeInfo_isCall, io_in_bits_preDecodeInfo_isRet, io_in_bits_pred_taken, io_in_bits_crossPageIPFFix, io_in_bits_ftqPtr_flag, io_in_bits_ftqPtr_value, io_in_bits_ftqOffset, io_in_bits_satpFlushFirstFetchFault, io_in_bits_srcType_0, io_in_bits_srcType_1, io_in_bits_srcType_2, io_in_bits_srcType_3, io_in_bits_srcType_4, io_in_bits_lsrc_0, io_in_bits_lsrc_1, io_in_bits_lsrc_2, io_in_bits_ldest, io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_isXSTrap, io_in_bits_waitForward, io_in_bits_blockBackward, io_in_bits_flushPipe, io_in_bits_canRobCompress, io_in_bits_selImm, io_in_bits_imm, io_in_bits_fpu_typeTagOut, io_in_bits_fpu_wflags, io_in_bits_fpu_typ, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_vpu_vill, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_specVill, io_in_bits_vpu_specVma, io_in_bits_vpu_specVta, io_in_bits_vpu_specVsew, io_in_bits_vpu_specVlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_nf, io_in_bits_vpu_veew, io_in_bits_vpu_isReverse, io_in_bits_vpu_isExt, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_vpu_isOpMask, io_in_bits_vpu_isDependOldVd, io_in_bits_vpu_isWritePartVd, io_in_bits_vpu_isVleff, io_in_bits_vlsInstr, io_in_bits_wfflags, io_in_bits_isMove, io_in_bits_uopIdx, io_in_bits_uopSplitType, io_in_bits_isVset, io_in_bits_firstUop, io_in_bits_lastUop, io_in_bits_numUops, io_in_bits_numWB, io_in_bits_commitType, io_in_bits_debug_fuType, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};

  PipelineConnectPipe u_golden (
    .clock(clock), .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_instr(io_in_bits_instr),
    .io_in_bits_pc(io_in_bits_pc),
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
    .io_in_bits_preDecodeInfo_valid(io_in_bits_preDecodeInfo_valid),
    .io_in_bits_preDecodeInfo_isRVC(io_in_bits_preDecodeInfo_isRVC),
    .io_in_bits_preDecodeInfo_brType(io_in_bits_preDecodeInfo_brType),
    .io_in_bits_preDecodeInfo_isCall(io_in_bits_preDecodeInfo_isCall),
    .io_in_bits_preDecodeInfo_isRet(io_in_bits_preDecodeInfo_isRet),
    .io_in_bits_pred_taken(io_in_bits_pred_taken),
    .io_in_bits_crossPageIPFFix(io_in_bits_crossPageIPFFix),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_satpFlushFirstFetchFault(io_in_bits_satpFlushFirstFetchFault),
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
    .io_in_bits_vpu_isReverse(io_in_bits_vpu_isReverse),
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
    .io_in_bits_numUops(io_in_bits_numUops),
    .io_in_bits_numWB(io_in_bits_numWB),
    .io_in_bits_commitType(io_in_bits_commitType),
    .io_in_bits_debug_fuType(io_in_bits_debug_fuType),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush),
    .io_in_ready(g_p_io_in_ready),
    .io_out_valid(g_p_io_out_valid),
    .io_out_bits_instr(g_p_io_out_bits_instr),
    .io_out_bits_pc(g_p_io_out_bits_pc),
    .io_out_bits_foldpc(g_p_io_out_bits_foldpc),
    .io_out_bits_exceptionVec_0(g_p_io_out_bits_exceptionVec_0),
    .io_out_bits_exceptionVec_1(g_p_io_out_bits_exceptionVec_1),
    .io_out_bits_exceptionVec_2(g_p_io_out_bits_exceptionVec_2),
    .io_out_bits_exceptionVec_3(g_p_io_out_bits_exceptionVec_3),
    .io_out_bits_exceptionVec_4(g_p_io_out_bits_exceptionVec_4),
    .io_out_bits_exceptionVec_5(g_p_io_out_bits_exceptionVec_5),
    .io_out_bits_exceptionVec_6(g_p_io_out_bits_exceptionVec_6),
    .io_out_bits_exceptionVec_7(g_p_io_out_bits_exceptionVec_7),
    .io_out_bits_exceptionVec_8(g_p_io_out_bits_exceptionVec_8),
    .io_out_bits_exceptionVec_9(g_p_io_out_bits_exceptionVec_9),
    .io_out_bits_exceptionVec_10(g_p_io_out_bits_exceptionVec_10),
    .io_out_bits_exceptionVec_11(g_p_io_out_bits_exceptionVec_11),
    .io_out_bits_exceptionVec_12(g_p_io_out_bits_exceptionVec_12),
    .io_out_bits_exceptionVec_13(g_p_io_out_bits_exceptionVec_13),
    .io_out_bits_exceptionVec_14(g_p_io_out_bits_exceptionVec_14),
    .io_out_bits_exceptionVec_15(g_p_io_out_bits_exceptionVec_15),
    .io_out_bits_exceptionVec_16(g_p_io_out_bits_exceptionVec_16),
    .io_out_bits_exceptionVec_17(g_p_io_out_bits_exceptionVec_17),
    .io_out_bits_exceptionVec_18(g_p_io_out_bits_exceptionVec_18),
    .io_out_bits_exceptionVec_19(g_p_io_out_bits_exceptionVec_19),
    .io_out_bits_exceptionVec_20(g_p_io_out_bits_exceptionVec_20),
    .io_out_bits_exceptionVec_21(g_p_io_out_bits_exceptionVec_21),
    .io_out_bits_exceptionVec_22(g_p_io_out_bits_exceptionVec_22),
    .io_out_bits_exceptionVec_23(g_p_io_out_bits_exceptionVec_23),
    .io_out_bits_isFetchMalAddr(g_p_io_out_bits_isFetchMalAddr),
    .io_out_bits_trigger(g_p_io_out_bits_trigger),
    .io_out_bits_preDecodeInfo_valid(g_p_io_out_bits_preDecodeInfo_valid),
    .io_out_bits_preDecodeInfo_isRVC(g_p_io_out_bits_preDecodeInfo_isRVC),
    .io_out_bits_preDecodeInfo_brType(g_p_io_out_bits_preDecodeInfo_brType),
    .io_out_bits_preDecodeInfo_isCall(g_p_io_out_bits_preDecodeInfo_isCall),
    .io_out_bits_preDecodeInfo_isRet(g_p_io_out_bits_preDecodeInfo_isRet),
    .io_out_bits_pred_taken(g_p_io_out_bits_pred_taken),
    .io_out_bits_crossPageIPFFix(g_p_io_out_bits_crossPageIPFFix),
    .io_out_bits_ftqPtr_flag(g_p_io_out_bits_ftqPtr_flag),
    .io_out_bits_ftqPtr_value(g_p_io_out_bits_ftqPtr_value),
    .io_out_bits_ftqOffset(g_p_io_out_bits_ftqOffset),
    .io_out_bits_satpFlushFirstFetchFault(g_p_io_out_bits_satpFlushFirstFetchFault),
    .io_out_bits_srcType_0(g_p_io_out_bits_srcType_0),
    .io_out_bits_srcType_1(g_p_io_out_bits_srcType_1),
    .io_out_bits_srcType_2(g_p_io_out_bits_srcType_2),
    .io_out_bits_srcType_3(g_p_io_out_bits_srcType_3),
    .io_out_bits_srcType_4(g_p_io_out_bits_srcType_4),
    .io_out_bits_lsrc_0(g_p_io_out_bits_lsrc_0),
    .io_out_bits_lsrc_1(g_p_io_out_bits_lsrc_1),
    .io_out_bits_lsrc_2(g_p_io_out_bits_lsrc_2),
    .io_out_bits_lsrc_3(g_p_io_out_bits_lsrc_3),
    .io_out_bits_lsrc_4(g_p_io_out_bits_lsrc_4),
    .io_out_bits_ldest(g_p_io_out_bits_ldest),
    .io_out_bits_fuType(g_p_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_p_io_out_bits_fuOpType),
    .io_out_bits_rfWen(g_p_io_out_bits_rfWen),
    .io_out_bits_fpWen(g_p_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_p_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_p_io_out_bits_v0Wen),
    .io_out_bits_vlWen(g_p_io_out_bits_vlWen),
    .io_out_bits_isXSTrap(g_p_io_out_bits_isXSTrap),
    .io_out_bits_waitForward(g_p_io_out_bits_waitForward),
    .io_out_bits_blockBackward(g_p_io_out_bits_blockBackward),
    .io_out_bits_flushPipe(g_p_io_out_bits_flushPipe),
    .io_out_bits_canRobCompress(g_p_io_out_bits_canRobCompress),
    .io_out_bits_selImm(g_p_io_out_bits_selImm),
    .io_out_bits_imm(g_p_io_out_bits_imm),
    .io_out_bits_fpu_typeTagOut(g_p_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(g_p_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(g_p_io_out_bits_fpu_typ),
    .io_out_bits_fpu_fmt(g_p_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(g_p_io_out_bits_fpu_rm),
    .io_out_bits_vpu_vill(g_p_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(g_p_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(g_p_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(g_p_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(g_p_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(g_p_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(g_p_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(g_p_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(g_p_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(g_p_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(g_p_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(g_p_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_frm(g_p_io_out_bits_vpu_frm),
    .io_out_bits_vpu_fpu_isFpToVecInst(g_p_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_bits_vpu_fpu_isFP32Instr(g_p_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_bits_vpu_fpu_isFP64Instr(g_p_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_bits_vpu_fpu_isReduction(g_p_io_out_bits_vpu_fpu_isReduction),
    .io_out_bits_vpu_fpu_isFoldTo1_2(g_p_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(g_p_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(g_p_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vxrm(g_p_io_out_bits_vpu_vxrm),
    .io_out_bits_vpu_vuopIdx(g_p_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(g_p_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_vmask(g_p_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_vl(g_p_io_out_bits_vpu_vl),
    .io_out_bits_vpu_nf(g_p_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(g_p_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isReverse(g_p_io_out_bits_vpu_isReverse),
    .io_out_bits_vpu_isExt(g_p_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(g_p_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(g_p_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(g_p_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isMove(g_p_io_out_bits_vpu_isMove),
    .io_out_bits_vpu_isDependOldVd(g_p_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(g_p_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(g_p_io_out_bits_vpu_isVleff),
    .io_out_bits_vlsInstr(g_p_io_out_bits_vlsInstr),
    .io_out_bits_wfflags(g_p_io_out_bits_wfflags),
    .io_out_bits_isMove(g_p_io_out_bits_isMove),
    .io_out_bits_uopIdx(g_p_io_out_bits_uopIdx),
    .io_out_bits_uopSplitType(g_p_io_out_bits_uopSplitType),
    .io_out_bits_isVset(g_p_io_out_bits_isVset),
    .io_out_bits_firstUop(g_p_io_out_bits_firstUop),
    .io_out_bits_lastUop(g_p_io_out_bits_lastUop),
    .io_out_bits_numUops(g_p_io_out_bits_numUops),
    .io_out_bits_numWB(g_p_io_out_bits_numWB),
    .io_out_bits_commitType(g_p_io_out_bits_commitType),
    .io_out_bits_debug_fuType(g_p_io_out_bits_debug_fuType),
    .io_out_bits_debug_seqNum_seqNum(g_p_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_p_io_out_bits_debug_seqNum_uopIdx)
  );

  PipelineConnectPipe_xs u_impl (
    .clock(clock), .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_instr(io_in_bits_instr),
    .io_in_bits_pc(io_in_bits_pc),
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
    .io_in_bits_preDecodeInfo_valid(io_in_bits_preDecodeInfo_valid),
    .io_in_bits_preDecodeInfo_isRVC(io_in_bits_preDecodeInfo_isRVC),
    .io_in_bits_preDecodeInfo_brType(io_in_bits_preDecodeInfo_brType),
    .io_in_bits_preDecodeInfo_isCall(io_in_bits_preDecodeInfo_isCall),
    .io_in_bits_preDecodeInfo_isRet(io_in_bits_preDecodeInfo_isRet),
    .io_in_bits_pred_taken(io_in_bits_pred_taken),
    .io_in_bits_crossPageIPFFix(io_in_bits_crossPageIPFFix),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_satpFlushFirstFetchFault(io_in_bits_satpFlushFirstFetchFault),
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
    .io_in_bits_vpu_isReverse(io_in_bits_vpu_isReverse),
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
    .io_in_bits_numUops(io_in_bits_numUops),
    .io_in_bits_numWB(io_in_bits_numWB),
    .io_in_bits_commitType(io_in_bits_commitType),
    .io_in_bits_debug_fuType(io_in_bits_debug_fuType),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush),
    .io_in_ready(i_p_io_in_ready),
    .io_out_valid(i_p_io_out_valid),
    .io_out_bits_instr(i_p_io_out_bits_instr),
    .io_out_bits_pc(i_p_io_out_bits_pc),
    .io_out_bits_foldpc(i_p_io_out_bits_foldpc),
    .io_out_bits_exceptionVec_0(i_p_io_out_bits_exceptionVec_0),
    .io_out_bits_exceptionVec_1(i_p_io_out_bits_exceptionVec_1),
    .io_out_bits_exceptionVec_2(i_p_io_out_bits_exceptionVec_2),
    .io_out_bits_exceptionVec_3(i_p_io_out_bits_exceptionVec_3),
    .io_out_bits_exceptionVec_4(i_p_io_out_bits_exceptionVec_4),
    .io_out_bits_exceptionVec_5(i_p_io_out_bits_exceptionVec_5),
    .io_out_bits_exceptionVec_6(i_p_io_out_bits_exceptionVec_6),
    .io_out_bits_exceptionVec_7(i_p_io_out_bits_exceptionVec_7),
    .io_out_bits_exceptionVec_8(i_p_io_out_bits_exceptionVec_8),
    .io_out_bits_exceptionVec_9(i_p_io_out_bits_exceptionVec_9),
    .io_out_bits_exceptionVec_10(i_p_io_out_bits_exceptionVec_10),
    .io_out_bits_exceptionVec_11(i_p_io_out_bits_exceptionVec_11),
    .io_out_bits_exceptionVec_12(i_p_io_out_bits_exceptionVec_12),
    .io_out_bits_exceptionVec_13(i_p_io_out_bits_exceptionVec_13),
    .io_out_bits_exceptionVec_14(i_p_io_out_bits_exceptionVec_14),
    .io_out_bits_exceptionVec_15(i_p_io_out_bits_exceptionVec_15),
    .io_out_bits_exceptionVec_16(i_p_io_out_bits_exceptionVec_16),
    .io_out_bits_exceptionVec_17(i_p_io_out_bits_exceptionVec_17),
    .io_out_bits_exceptionVec_18(i_p_io_out_bits_exceptionVec_18),
    .io_out_bits_exceptionVec_19(i_p_io_out_bits_exceptionVec_19),
    .io_out_bits_exceptionVec_20(i_p_io_out_bits_exceptionVec_20),
    .io_out_bits_exceptionVec_21(i_p_io_out_bits_exceptionVec_21),
    .io_out_bits_exceptionVec_22(i_p_io_out_bits_exceptionVec_22),
    .io_out_bits_exceptionVec_23(i_p_io_out_bits_exceptionVec_23),
    .io_out_bits_isFetchMalAddr(i_p_io_out_bits_isFetchMalAddr),
    .io_out_bits_trigger(i_p_io_out_bits_trigger),
    .io_out_bits_preDecodeInfo_valid(i_p_io_out_bits_preDecodeInfo_valid),
    .io_out_bits_preDecodeInfo_isRVC(i_p_io_out_bits_preDecodeInfo_isRVC),
    .io_out_bits_preDecodeInfo_brType(i_p_io_out_bits_preDecodeInfo_brType),
    .io_out_bits_preDecodeInfo_isCall(i_p_io_out_bits_preDecodeInfo_isCall),
    .io_out_bits_preDecodeInfo_isRet(i_p_io_out_bits_preDecodeInfo_isRet),
    .io_out_bits_pred_taken(i_p_io_out_bits_pred_taken),
    .io_out_bits_crossPageIPFFix(i_p_io_out_bits_crossPageIPFFix),
    .io_out_bits_ftqPtr_flag(i_p_io_out_bits_ftqPtr_flag),
    .io_out_bits_ftqPtr_value(i_p_io_out_bits_ftqPtr_value),
    .io_out_bits_ftqOffset(i_p_io_out_bits_ftqOffset),
    .io_out_bits_satpFlushFirstFetchFault(i_p_io_out_bits_satpFlushFirstFetchFault),
    .io_out_bits_srcType_0(i_p_io_out_bits_srcType_0),
    .io_out_bits_srcType_1(i_p_io_out_bits_srcType_1),
    .io_out_bits_srcType_2(i_p_io_out_bits_srcType_2),
    .io_out_bits_srcType_3(i_p_io_out_bits_srcType_3),
    .io_out_bits_srcType_4(i_p_io_out_bits_srcType_4),
    .io_out_bits_lsrc_0(i_p_io_out_bits_lsrc_0),
    .io_out_bits_lsrc_1(i_p_io_out_bits_lsrc_1),
    .io_out_bits_lsrc_2(i_p_io_out_bits_lsrc_2),
    .io_out_bits_lsrc_3(i_p_io_out_bits_lsrc_3),
    .io_out_bits_lsrc_4(i_p_io_out_bits_lsrc_4),
    .io_out_bits_ldest(i_p_io_out_bits_ldest),
    .io_out_bits_fuType(i_p_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_p_io_out_bits_fuOpType),
    .io_out_bits_rfWen(i_p_io_out_bits_rfWen),
    .io_out_bits_fpWen(i_p_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_p_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_p_io_out_bits_v0Wen),
    .io_out_bits_vlWen(i_p_io_out_bits_vlWen),
    .io_out_bits_isXSTrap(i_p_io_out_bits_isXSTrap),
    .io_out_bits_waitForward(i_p_io_out_bits_waitForward),
    .io_out_bits_blockBackward(i_p_io_out_bits_blockBackward),
    .io_out_bits_flushPipe(i_p_io_out_bits_flushPipe),
    .io_out_bits_canRobCompress(i_p_io_out_bits_canRobCompress),
    .io_out_bits_selImm(i_p_io_out_bits_selImm),
    .io_out_bits_imm(i_p_io_out_bits_imm),
    .io_out_bits_fpu_typeTagOut(i_p_io_out_bits_fpu_typeTagOut),
    .io_out_bits_fpu_wflags(i_p_io_out_bits_fpu_wflags),
    .io_out_bits_fpu_typ(i_p_io_out_bits_fpu_typ),
    .io_out_bits_fpu_fmt(i_p_io_out_bits_fpu_fmt),
    .io_out_bits_fpu_rm(i_p_io_out_bits_fpu_rm),
    .io_out_bits_vpu_vill(i_p_io_out_bits_vpu_vill),
    .io_out_bits_vpu_vma(i_p_io_out_bits_vpu_vma),
    .io_out_bits_vpu_vta(i_p_io_out_bits_vpu_vta),
    .io_out_bits_vpu_vsew(i_p_io_out_bits_vpu_vsew),
    .io_out_bits_vpu_vlmul(i_p_io_out_bits_vpu_vlmul),
    .io_out_bits_vpu_specVill(i_p_io_out_bits_vpu_specVill),
    .io_out_bits_vpu_specVma(i_p_io_out_bits_vpu_specVma),
    .io_out_bits_vpu_specVta(i_p_io_out_bits_vpu_specVta),
    .io_out_bits_vpu_specVsew(i_p_io_out_bits_vpu_specVsew),
    .io_out_bits_vpu_specVlmul(i_p_io_out_bits_vpu_specVlmul),
    .io_out_bits_vpu_vm(i_p_io_out_bits_vpu_vm),
    .io_out_bits_vpu_vstart(i_p_io_out_bits_vpu_vstart),
    .io_out_bits_vpu_frm(i_p_io_out_bits_vpu_frm),
    .io_out_bits_vpu_fpu_isFpToVecInst(i_p_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_bits_vpu_fpu_isFP32Instr(i_p_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_bits_vpu_fpu_isFP64Instr(i_p_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_bits_vpu_fpu_isReduction(i_p_io_out_bits_vpu_fpu_isReduction),
    .io_out_bits_vpu_fpu_isFoldTo1_2(i_p_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_bits_vpu_fpu_isFoldTo1_4(i_p_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_bits_vpu_fpu_isFoldTo1_8(i_p_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_bits_vpu_vxrm(i_p_io_out_bits_vpu_vxrm),
    .io_out_bits_vpu_vuopIdx(i_p_io_out_bits_vpu_vuopIdx),
    .io_out_bits_vpu_lastUop(i_p_io_out_bits_vpu_lastUop),
    .io_out_bits_vpu_vmask(i_p_io_out_bits_vpu_vmask),
    .io_out_bits_vpu_vl(i_p_io_out_bits_vpu_vl),
    .io_out_bits_vpu_nf(i_p_io_out_bits_vpu_nf),
    .io_out_bits_vpu_veew(i_p_io_out_bits_vpu_veew),
    .io_out_bits_vpu_isReverse(i_p_io_out_bits_vpu_isReverse),
    .io_out_bits_vpu_isExt(i_p_io_out_bits_vpu_isExt),
    .io_out_bits_vpu_isNarrow(i_p_io_out_bits_vpu_isNarrow),
    .io_out_bits_vpu_isDstMask(i_p_io_out_bits_vpu_isDstMask),
    .io_out_bits_vpu_isOpMask(i_p_io_out_bits_vpu_isOpMask),
    .io_out_bits_vpu_isMove(i_p_io_out_bits_vpu_isMove),
    .io_out_bits_vpu_isDependOldVd(i_p_io_out_bits_vpu_isDependOldVd),
    .io_out_bits_vpu_isWritePartVd(i_p_io_out_bits_vpu_isWritePartVd),
    .io_out_bits_vpu_isVleff(i_p_io_out_bits_vpu_isVleff),
    .io_out_bits_vlsInstr(i_p_io_out_bits_vlsInstr),
    .io_out_bits_wfflags(i_p_io_out_bits_wfflags),
    .io_out_bits_isMove(i_p_io_out_bits_isMove),
    .io_out_bits_uopIdx(i_p_io_out_bits_uopIdx),
    .io_out_bits_uopSplitType(i_p_io_out_bits_uopSplitType),
    .io_out_bits_isVset(i_p_io_out_bits_isVset),
    .io_out_bits_firstUop(i_p_io_out_bits_firstUop),
    .io_out_bits_lastUop(i_p_io_out_bits_lastUop),
    .io_out_bits_numUops(i_p_io_out_bits_numUops),
    .io_out_bits_numWB(i_p_io_out_bits_numWB),
    .io_out_bits_commitType(i_p_io_out_bits_commitType),
    .io_out_bits_debug_fuType(i_p_io_out_bits_debug_fuType),
    .io_out_bits_debug_seqNum_seqNum(i_p_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_p_io_out_bits_debug_seqNum_uopIdx)
  );

  task automatic drive_all();
    io_in_valid     = ($urandom % 100) < 75;
    io_out_ready    = ($urandom % 100) < 55;
    io_rightOutFire = ($urandom % 100) < 50;
    io_isFlush      = ($urandom % 512) == 0;
    io_in_bits_instr = 32'($urandom);
    io_in_bits_pc = 50'({$urandom, $urandom});
    io_in_bits_foldpc = 10'($urandom);
    io_in_bits_exceptionVec_0 = 1'($urandom);
    io_in_bits_exceptionVec_1 = 1'($urandom);
    io_in_bits_exceptionVec_2 = 1'($urandom);
    io_in_bits_exceptionVec_3 = 1'($urandom);
    io_in_bits_exceptionVec_4 = 1'($urandom);
    io_in_bits_exceptionVec_5 = 1'($urandom);
    io_in_bits_exceptionVec_6 = 1'($urandom);
    io_in_bits_exceptionVec_7 = 1'($urandom);
    io_in_bits_exceptionVec_8 = 1'($urandom);
    io_in_bits_exceptionVec_9 = 1'($urandom);
    io_in_bits_exceptionVec_10 = 1'($urandom);
    io_in_bits_exceptionVec_11 = 1'($urandom);
    io_in_bits_exceptionVec_12 = 1'($urandom);
    io_in_bits_exceptionVec_13 = 1'($urandom);
    io_in_bits_exceptionVec_14 = 1'($urandom);
    io_in_bits_exceptionVec_15 = 1'($urandom);
    io_in_bits_exceptionVec_16 = 1'($urandom);
    io_in_bits_exceptionVec_17 = 1'($urandom);
    io_in_bits_exceptionVec_18 = 1'($urandom);
    io_in_bits_exceptionVec_19 = 1'($urandom);
    io_in_bits_exceptionVec_20 = 1'($urandom);
    io_in_bits_exceptionVec_21 = 1'($urandom);
    io_in_bits_exceptionVec_22 = 1'($urandom);
    io_in_bits_exceptionVec_23 = 1'($urandom);
    io_in_bits_isFetchMalAddr = 1'($urandom);
    io_in_bits_trigger = 4'($urandom);
    io_in_bits_preDecodeInfo_valid = 1'($urandom);
    io_in_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_in_bits_preDecodeInfo_brType = 2'($urandom);
    io_in_bits_preDecodeInfo_isCall = 1'($urandom);
    io_in_bits_preDecodeInfo_isRet = 1'($urandom);
    io_in_bits_pred_taken = 1'($urandom);
    io_in_bits_crossPageIPFFix = 1'($urandom);
    io_in_bits_ftqPtr_flag = 1'($urandom);
    io_in_bits_ftqPtr_value = 6'($urandom);
    io_in_bits_ftqOffset = 4'($urandom);
    io_in_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_bits_srcType_0 = 4'($urandom);
    io_in_bits_srcType_1 = 4'($urandom);
    io_in_bits_srcType_2 = 4'($urandom);
    io_in_bits_srcType_3 = 4'($urandom);
    io_in_bits_srcType_4 = 4'($urandom);
    io_in_bits_lsrc_0 = 6'($urandom);
    io_in_bits_lsrc_1 = 6'($urandom);
    io_in_bits_lsrc_2 = 6'($urandom);
    io_in_bits_ldest = 6'($urandom);
    io_in_bits_fuType = 35'({$urandom, $urandom});
    io_in_bits_fuOpType = 9'($urandom);
    io_in_bits_rfWen = 1'($urandom);
    io_in_bits_fpWen = 1'($urandom);
    io_in_bits_vecWen = 1'($urandom);
    io_in_bits_v0Wen = 1'($urandom);
    io_in_bits_vlWen = 1'($urandom);
    io_in_bits_isXSTrap = 1'($urandom);
    io_in_bits_waitForward = 1'($urandom);
    io_in_bits_blockBackward = 1'($urandom);
    io_in_bits_flushPipe = 1'($urandom);
    io_in_bits_canRobCompress = 1'($urandom);
    io_in_bits_selImm = 4'($urandom);
    io_in_bits_imm = 22'($urandom);
    io_in_bits_fpu_typeTagOut = 2'($urandom);
    io_in_bits_fpu_wflags = 1'($urandom);
    io_in_bits_fpu_typ = 2'($urandom);
    io_in_bits_fpu_fmt = 2'($urandom);
    io_in_bits_fpu_rm = 3'($urandom);
    io_in_bits_vpu_vill = 1'($urandom);
    io_in_bits_vpu_vma = 1'($urandom);
    io_in_bits_vpu_vta = 1'($urandom);
    io_in_bits_vpu_vsew = 2'($urandom);
    io_in_bits_vpu_vlmul = 3'($urandom);
    io_in_bits_vpu_specVill = 1'($urandom);
    io_in_bits_vpu_specVma = 1'($urandom);
    io_in_bits_vpu_specVta = 1'($urandom);
    io_in_bits_vpu_specVsew = 2'($urandom);
    io_in_bits_vpu_specVlmul = 3'($urandom);
    io_in_bits_vpu_vm = 1'($urandom);
    io_in_bits_vpu_vstart = 8'($urandom);
    io_in_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_bits_vpu_nf = 3'($urandom);
    io_in_bits_vpu_veew = 2'($urandom);
    io_in_bits_vpu_isReverse = 1'($urandom);
    io_in_bits_vpu_isExt = 1'($urandom);
    io_in_bits_vpu_isNarrow = 1'($urandom);
    io_in_bits_vpu_isDstMask = 1'($urandom);
    io_in_bits_vpu_isOpMask = 1'($urandom);
    io_in_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_bits_vpu_isVleff = 1'($urandom);
    io_in_bits_vlsInstr = 1'($urandom);
    io_in_bits_wfflags = 1'($urandom);
    io_in_bits_isMove = 1'($urandom);
    io_in_bits_uopIdx = 7'($urandom);
    io_in_bits_uopSplitType = 6'($urandom);
    io_in_bits_isVset = 1'($urandom);
    io_in_bits_firstUop = 1'($urandom);
    io_in_bits_lastUop = 1'($urandom);
    io_in_bits_numUops = 7'($urandom);
    io_in_bits_numWB = 7'($urandom);
    io_in_bits_commitType = 3'($urandom);
    io_in_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
  endtask

  task automatic check_all();
    `CHECK(p,io_in_ready)
    `CHECK(p,io_out_valid)
    `CHECK(p,io_out_bits_instr)
    `CHECK(p,io_out_bits_pc)
    `CHECK(p,io_out_bits_foldpc)
    `CHECK(p,io_out_bits_exceptionVec_0)
    `CHECK(p,io_out_bits_exceptionVec_1)
    `CHECK(p,io_out_bits_exceptionVec_2)
    `CHECK(p,io_out_bits_exceptionVec_3)
    `CHECK(p,io_out_bits_exceptionVec_4)
    `CHECK(p,io_out_bits_exceptionVec_5)
    `CHECK(p,io_out_bits_exceptionVec_6)
    `CHECK(p,io_out_bits_exceptionVec_7)
    `CHECK(p,io_out_bits_exceptionVec_8)
    `CHECK(p,io_out_bits_exceptionVec_9)
    `CHECK(p,io_out_bits_exceptionVec_10)
    `CHECK(p,io_out_bits_exceptionVec_11)
    `CHECK(p,io_out_bits_exceptionVec_12)
    `CHECK(p,io_out_bits_exceptionVec_13)
    `CHECK(p,io_out_bits_exceptionVec_14)
    `CHECK(p,io_out_bits_exceptionVec_15)
    `CHECK(p,io_out_bits_exceptionVec_16)
    `CHECK(p,io_out_bits_exceptionVec_17)
    `CHECK(p,io_out_bits_exceptionVec_18)
    `CHECK(p,io_out_bits_exceptionVec_19)
    `CHECK(p,io_out_bits_exceptionVec_20)
    `CHECK(p,io_out_bits_exceptionVec_21)
    `CHECK(p,io_out_bits_exceptionVec_22)
    `CHECK(p,io_out_bits_exceptionVec_23)
    `CHECK(p,io_out_bits_isFetchMalAddr)
    `CHECK(p,io_out_bits_trigger)
    `CHECK(p,io_out_bits_preDecodeInfo_valid)
    `CHECK(p,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(p,io_out_bits_preDecodeInfo_brType)
    `CHECK(p,io_out_bits_preDecodeInfo_isCall)
    `CHECK(p,io_out_bits_preDecodeInfo_isRet)
    `CHECK(p,io_out_bits_pred_taken)
    `CHECK(p,io_out_bits_crossPageIPFFix)
    `CHECK(p,io_out_bits_ftqPtr_flag)
    `CHECK(p,io_out_bits_ftqPtr_value)
    `CHECK(p,io_out_bits_ftqOffset)
    `CHECK(p,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(p,io_out_bits_srcType_0)
    `CHECK(p,io_out_bits_srcType_1)
    `CHECK(p,io_out_bits_srcType_2)
    `CHECK(p,io_out_bits_srcType_3)
    `CHECK(p,io_out_bits_srcType_4)
    `CHECK(p,io_out_bits_lsrc_0)
    `CHECK(p,io_out_bits_lsrc_1)
    `CHECK(p,io_out_bits_lsrc_2)
    `CHECK(p,io_out_bits_lsrc_3)
    `CHECK(p,io_out_bits_lsrc_4)
    `CHECK(p,io_out_bits_ldest)
    `CHECK(p,io_out_bits_fuType)
    `CHECK(p,io_out_bits_fuOpType)
    `CHECK(p,io_out_bits_rfWen)
    `CHECK(p,io_out_bits_fpWen)
    `CHECK(p,io_out_bits_vecWen)
    `CHECK(p,io_out_bits_v0Wen)
    `CHECK(p,io_out_bits_vlWen)
    `CHECK(p,io_out_bits_isXSTrap)
    `CHECK(p,io_out_bits_waitForward)
    `CHECK(p,io_out_bits_blockBackward)
    `CHECK(p,io_out_bits_flushPipe)
    `CHECK(p,io_out_bits_canRobCompress)
    `CHECK(p,io_out_bits_selImm)
    `CHECK(p,io_out_bits_imm)
    `CHECK(p,io_out_bits_fpu_typeTagOut)
    `CHECK(p,io_out_bits_fpu_wflags)
    `CHECK(p,io_out_bits_fpu_typ)
    `CHECK(p,io_out_bits_fpu_fmt)
    `CHECK(p,io_out_bits_fpu_rm)
    `CHECK(p,io_out_bits_vpu_vill)
    `CHECK(p,io_out_bits_vpu_vma)
    `CHECK(p,io_out_bits_vpu_vta)
    `CHECK(p,io_out_bits_vpu_vsew)
    `CHECK(p,io_out_bits_vpu_vlmul)
    `CHECK(p,io_out_bits_vpu_specVill)
    `CHECK(p,io_out_bits_vpu_specVma)
    `CHECK(p,io_out_bits_vpu_specVta)
    `CHECK(p,io_out_bits_vpu_specVsew)
    `CHECK(p,io_out_bits_vpu_specVlmul)
    `CHECK(p,io_out_bits_vpu_vm)
    `CHECK(p,io_out_bits_vpu_vstart)
    `CHECK(p,io_out_bits_vpu_frm)
    `CHECK(p,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(p,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(p,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(p,io_out_bits_vpu_fpu_isReduction)
    `CHECK(p,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(p,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(p,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(p,io_out_bits_vpu_vxrm)
    `CHECK(p,io_out_bits_vpu_vuopIdx)
    `CHECK(p,io_out_bits_vpu_lastUop)
    `CHECK(p,io_out_bits_vpu_vmask)
    `CHECK(p,io_out_bits_vpu_vl)
    `CHECK(p,io_out_bits_vpu_nf)
    `CHECK(p,io_out_bits_vpu_veew)
    `CHECK(p,io_out_bits_vpu_isReverse)
    `CHECK(p,io_out_bits_vpu_isExt)
    `CHECK(p,io_out_bits_vpu_isNarrow)
    `CHECK(p,io_out_bits_vpu_isDstMask)
    `CHECK(p,io_out_bits_vpu_isOpMask)
    `CHECK(p,io_out_bits_vpu_isMove)
    `CHECK(p,io_out_bits_vpu_isDependOldVd)
    `CHECK(p,io_out_bits_vpu_isWritePartVd)
    `CHECK(p,io_out_bits_vpu_isVleff)
    `CHECK(p,io_out_bits_vlsInstr)
    `CHECK(p,io_out_bits_wfflags)
    `CHECK(p,io_out_bits_isMove)
    `CHECK(p,io_out_bits_uopIdx)
    `CHECK(p,io_out_bits_uopSplitType)
    `CHECK(p,io_out_bits_isVset)
    `CHECK(p,io_out_bits_firstUop)
    `CHECK(p,io_out_bits_lastUop)
    `CHECK(p,io_out_bits_numUops)
    `CHECK(p,io_out_bits_numWB)
    `CHECK(p,io_out_bits_commitType)
    `CHECK(p,io_out_bits_debug_fuType)
    `CHECK(p,io_out_bits_debug_seqNum_seqNum)
    `CHECK(p,io_out_bits_debug_seqNum_uopIdx)
  endtask

  task automatic sample_cov();
    if (io_in_valid && io_out_ready) begin
      n_fire++; por |= pcat; pand &= pcat;
      if (io_isFlush) n_flfire++;
      if (g_p_io_out_valid === 1'b1) n_owr++;
    end
    if (io_in_valid && !io_out_ready) n_bp++;
    if (g_p_io_out_valid === 1'b1) begin
      if (io_isFlush) n_flush++;
      if (io_rightOutFire) n_deq++; else n_hold++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    drive_all();
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_all();
      #1 sample_cov();          // 沿前采：见文件头「采样时机」
      @(posedge clock);
      #1 check_all();
    end
    $display("\n==== PipelineConnectPipe: checks=%0d errors=%0d (ncycles=%0d) ====", checks, errors, NCYCLES);
    $display("fire=%0d backpr=%0d hold=%0d deq=%0d owrite=%0d flush=%0d flush&fire=%0d payload=%s",
             n_fire, n_bp, n_hold, n_deq, n_owr, n_flush, n_flfire,
             ((&por) && (pand == '0)) ? "ok" : "HOLE");
    gate("fire",       n_fire,   1000, "从没锁进过数据");
    gate("backpr",     n_bp,      100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("hold",       n_hold,    100, "表项从没被压住过");
    gate("deq",        n_deq,     100, "表项从没被下游取走过");
    gate("owr",        n_owr,     100, "从没在占用中被新数据改写过");
    gate("flush",      n_flush,    10, "flush 从没命中占用中的表项");
    gate("flush&fire", n_flfire,   10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");
    if (!(&por)) begin $display("COVERAGE HOLE: 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand != '0) begin $display("COVERAGE HOLE: 入口 payload 有位从未取到 0"); cov_fail++; end

    if (cov_fail != 0) begin
      $display("TEST FAILED (%0d 个覆盖闸没过)", cov_fail);
      $fatal(1);
    end
    if (errors == 0 && checks > 100000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
