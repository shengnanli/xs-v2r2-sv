// PipeGroupConnect UT —— golden vs 派生 PipeGroupConnect_xs 双例化，同激励逐拍比全部输出。
//
// 被测语义（核 xs_PipeGroupConnect_core + 6 个 slot，见 rtl/backend/PipeGroupConnect.sv）：
//   canAcc = outAllFire | (validVec == 0)；in_i_ready = canAcc；fire_i = in_i_valid & canAcc
//   valid_i' = ~flush & (fire_i | ~out_i_ready & valid_i)（异步复位清 0）
//   data_i = RegEnable(in_i_bits, fire_i)
//
// 覆盖闸（按 lane 计数，每条 lane 都要过）：
//   fire / 反压(in_valid & ~canAcc) / hold(valid & ~out_ready) / deq(valid & out_ready) /
//   占用中被改写(valid & fire) / flush 命中占用中的表项 / 入口 payload 每一位都取到过 1 和 0；
//   整组级：canAcc **仅因 outAllFire** 成立的拍（outAllFire & validVec!=0）——不打到就等于
//   没测 outAllFire 那一项；flush 与 fire 同拍（冲刷优先级）。
// 采样时机：覆盖在**时钟沿之前**采（沿后采永远看不到 flush——它把 valid 清了）。
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
  logic io_flush, io_outAllFire;
  logic io_in_0_valid, io_out_0_ready;
  logic [31:0] io_in_0_bits_instr;
  logic [49:0] io_in_0_bits_pc;
  logic [9:0] io_in_0_bits_foldpc;
  logic io_in_0_bits_exceptionVec_0;
  logic io_in_0_bits_exceptionVec_1;
  logic io_in_0_bits_exceptionVec_2;
  logic io_in_0_bits_exceptionVec_3;
  logic io_in_0_bits_exceptionVec_4;
  logic io_in_0_bits_exceptionVec_5;
  logic io_in_0_bits_exceptionVec_6;
  logic io_in_0_bits_exceptionVec_7;
  logic io_in_0_bits_exceptionVec_8;
  logic io_in_0_bits_exceptionVec_9;
  logic io_in_0_bits_exceptionVec_10;
  logic io_in_0_bits_exceptionVec_11;
  logic io_in_0_bits_exceptionVec_12;
  logic io_in_0_bits_exceptionVec_13;
  logic io_in_0_bits_exceptionVec_14;
  logic io_in_0_bits_exceptionVec_15;
  logic io_in_0_bits_exceptionVec_16;
  logic io_in_0_bits_exceptionVec_17;
  logic io_in_0_bits_exceptionVec_18;
  logic io_in_0_bits_exceptionVec_19;
  logic io_in_0_bits_exceptionVec_20;
  logic io_in_0_bits_exceptionVec_21;
  logic io_in_0_bits_exceptionVec_22;
  logic io_in_0_bits_exceptionVec_23;
  logic io_in_0_bits_isFetchMalAddr;
  logic io_in_0_bits_hasException;
  logic [3:0] io_in_0_bits_trigger;
  logic io_in_0_bits_preDecodeInfo_valid;
  logic io_in_0_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_0_bits_preDecodeInfo_brType;
  logic io_in_0_bits_preDecodeInfo_isCall;
  logic io_in_0_bits_preDecodeInfo_isRet;
  logic io_in_0_bits_pred_taken;
  logic io_in_0_bits_crossPageIPFFix;
  logic io_in_0_bits_ftqPtr_flag;
  logic [5:0] io_in_0_bits_ftqPtr_value;
  logic [3:0] io_in_0_bits_ftqOffset;
  logic io_in_0_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_0_bits_srcType_0;
  logic [3:0] io_in_0_bits_srcType_1;
  logic [3:0] io_in_0_bits_srcType_2;
  logic [3:0] io_in_0_bits_srcType_3;
  logic [3:0] io_in_0_bits_srcType_4;
  logic [5:0] io_in_0_bits_ldest;
  logic [34:0] io_in_0_bits_fuType;
  logic [8:0] io_in_0_bits_fuOpType;
  logic io_in_0_bits_rfWen;
  logic io_in_0_bits_fpWen;
  logic io_in_0_bits_vecWen;
  logic io_in_0_bits_v0Wen;
  logic io_in_0_bits_vlWen;
  logic io_in_0_bits_isXSTrap;
  logic io_in_0_bits_waitForward;
  logic io_in_0_bits_blockBackward;
  logic io_in_0_bits_flushPipe;
  logic io_in_0_bits_canRobCompress;
  logic [3:0] io_in_0_bits_selImm;
  logic [31:0] io_in_0_bits_imm;
  logic [1:0] io_in_0_bits_fpu_typeTagOut;
  logic io_in_0_bits_fpu_wflags;
  logic [1:0] io_in_0_bits_fpu_typ;
  logic [1:0] io_in_0_bits_fpu_fmt;
  logic [2:0] io_in_0_bits_fpu_rm;
  logic io_in_0_bits_vpu_vill;
  logic io_in_0_bits_vpu_vma;
  logic io_in_0_bits_vpu_vta;
  logic [1:0] io_in_0_bits_vpu_vsew;
  logic [2:0] io_in_0_bits_vpu_vlmul;
  logic io_in_0_bits_vpu_specVill;
  logic io_in_0_bits_vpu_specVma;
  logic io_in_0_bits_vpu_specVta;
  logic [1:0] io_in_0_bits_vpu_specVsew;
  logic [2:0] io_in_0_bits_vpu_specVlmul;
  logic io_in_0_bits_vpu_vm;
  logic [7:0] io_in_0_bits_vpu_vstart;
  logic [2:0] io_in_0_bits_vpu_frm;
  logic io_in_0_bits_vpu_fpu_isFpToVecInst;
  logic io_in_0_bits_vpu_fpu_isFP32Instr;
  logic io_in_0_bits_vpu_fpu_isFP64Instr;
  logic io_in_0_bits_vpu_fpu_isReduction;
  logic io_in_0_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_0_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_0_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_0_bits_vpu_vxrm;
  logic [6:0] io_in_0_bits_vpu_vuopIdx;
  logic io_in_0_bits_vpu_lastUop;
  logic [127:0] io_in_0_bits_vpu_vmask;
  logic [7:0] io_in_0_bits_vpu_vl;
  logic [2:0] io_in_0_bits_vpu_nf;
  logic [1:0] io_in_0_bits_vpu_veew;
  logic io_in_0_bits_vpu_isReverse;
  logic io_in_0_bits_vpu_isExt;
  logic io_in_0_bits_vpu_isNarrow;
  logic io_in_0_bits_vpu_isDstMask;
  logic io_in_0_bits_vpu_isOpMask;
  logic io_in_0_bits_vpu_isMove;
  logic io_in_0_bits_vpu_isDependOldVd;
  logic io_in_0_bits_vpu_isWritePartVd;
  logic io_in_0_bits_vpu_isVleff;
  logic io_in_0_bits_vlsInstr;
  logic io_in_0_bits_wfflags;
  logic io_in_0_bits_isMove;
  logic [6:0] io_in_0_bits_uopIdx;
  logic io_in_0_bits_isVset;
  logic io_in_0_bits_firstUop;
  logic io_in_0_bits_lastUop;
  logic [6:0] io_in_0_bits_numUops;
  logic [6:0] io_in_0_bits_numWB;
  logic [2:0] io_in_0_bits_commitType;
  logic [7:0] io_in_0_bits_psrc_0;
  logic [7:0] io_in_0_bits_psrc_1;
  logic [7:0] io_in_0_bits_psrc_2;
  logic [7:0] io_in_0_bits_psrc_3;
  logic [7:0] io_in_0_bits_psrc_4;
  logic [7:0] io_in_0_bits_pdest;
  logic io_in_0_bits_robIdx_flag;
  logic [7:0] io_in_0_bits_robIdx_value;
  logic [2:0] io_in_0_bits_instrSize;
  logic io_in_0_bits_dirtyFs;
  logic io_in_0_bits_dirtyVs;
  logic [3:0] io_in_0_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_0_bits_traceBlockInPipe_iretire;
  logic io_in_0_bits_traceBlockInPipe_ilastsize;
  logic io_in_0_bits_eliminatedMove;
  logic io_in_0_bits_snapshot;
  logic [63:0] io_in_0_bits_debugInfo_renameTime;
  logic [55:0] io_in_0_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_0_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_0_bits_debug_fuType;
  logic io_in_0_bits_debug_sim_trig;
  logic [4:0] io_in_0_bits_numLsElem;
  logic io_in_1_valid, io_out_1_ready;
  logic [31:0] io_in_1_bits_instr;
  logic [49:0] io_in_1_bits_pc;
  logic [9:0] io_in_1_bits_foldpc;
  logic io_in_1_bits_exceptionVec_0;
  logic io_in_1_bits_exceptionVec_1;
  logic io_in_1_bits_exceptionVec_2;
  logic io_in_1_bits_exceptionVec_3;
  logic io_in_1_bits_exceptionVec_4;
  logic io_in_1_bits_exceptionVec_5;
  logic io_in_1_bits_exceptionVec_6;
  logic io_in_1_bits_exceptionVec_7;
  logic io_in_1_bits_exceptionVec_8;
  logic io_in_1_bits_exceptionVec_9;
  logic io_in_1_bits_exceptionVec_10;
  logic io_in_1_bits_exceptionVec_11;
  logic io_in_1_bits_exceptionVec_12;
  logic io_in_1_bits_exceptionVec_13;
  logic io_in_1_bits_exceptionVec_14;
  logic io_in_1_bits_exceptionVec_15;
  logic io_in_1_bits_exceptionVec_16;
  logic io_in_1_bits_exceptionVec_17;
  logic io_in_1_bits_exceptionVec_18;
  logic io_in_1_bits_exceptionVec_19;
  logic io_in_1_bits_exceptionVec_20;
  logic io_in_1_bits_exceptionVec_21;
  logic io_in_1_bits_exceptionVec_22;
  logic io_in_1_bits_exceptionVec_23;
  logic io_in_1_bits_isFetchMalAddr;
  logic io_in_1_bits_hasException;
  logic [3:0] io_in_1_bits_trigger;
  logic io_in_1_bits_preDecodeInfo_valid;
  logic io_in_1_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_1_bits_preDecodeInfo_brType;
  logic io_in_1_bits_preDecodeInfo_isCall;
  logic io_in_1_bits_preDecodeInfo_isRet;
  logic io_in_1_bits_pred_taken;
  logic io_in_1_bits_crossPageIPFFix;
  logic io_in_1_bits_ftqPtr_flag;
  logic [5:0] io_in_1_bits_ftqPtr_value;
  logic [3:0] io_in_1_bits_ftqOffset;
  logic io_in_1_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_1_bits_srcType_0;
  logic [3:0] io_in_1_bits_srcType_1;
  logic [3:0] io_in_1_bits_srcType_2;
  logic [3:0] io_in_1_bits_srcType_3;
  logic [3:0] io_in_1_bits_srcType_4;
  logic [5:0] io_in_1_bits_ldest;
  logic [34:0] io_in_1_bits_fuType;
  logic [8:0] io_in_1_bits_fuOpType;
  logic io_in_1_bits_rfWen;
  logic io_in_1_bits_fpWen;
  logic io_in_1_bits_vecWen;
  logic io_in_1_bits_v0Wen;
  logic io_in_1_bits_vlWen;
  logic io_in_1_bits_isXSTrap;
  logic io_in_1_bits_waitForward;
  logic io_in_1_bits_blockBackward;
  logic io_in_1_bits_flushPipe;
  logic io_in_1_bits_canRobCompress;
  logic [3:0] io_in_1_bits_selImm;
  logic [31:0] io_in_1_bits_imm;
  logic [1:0] io_in_1_bits_fpu_typeTagOut;
  logic io_in_1_bits_fpu_wflags;
  logic [1:0] io_in_1_bits_fpu_typ;
  logic [1:0] io_in_1_bits_fpu_fmt;
  logic [2:0] io_in_1_bits_fpu_rm;
  logic io_in_1_bits_vpu_vill;
  logic io_in_1_bits_vpu_vma;
  logic io_in_1_bits_vpu_vta;
  logic [1:0] io_in_1_bits_vpu_vsew;
  logic [2:0] io_in_1_bits_vpu_vlmul;
  logic io_in_1_bits_vpu_specVill;
  logic io_in_1_bits_vpu_specVma;
  logic io_in_1_bits_vpu_specVta;
  logic [1:0] io_in_1_bits_vpu_specVsew;
  logic [2:0] io_in_1_bits_vpu_specVlmul;
  logic io_in_1_bits_vpu_vm;
  logic [7:0] io_in_1_bits_vpu_vstart;
  logic [2:0] io_in_1_bits_vpu_frm;
  logic io_in_1_bits_vpu_fpu_isFpToVecInst;
  logic io_in_1_bits_vpu_fpu_isFP32Instr;
  logic io_in_1_bits_vpu_fpu_isFP64Instr;
  logic io_in_1_bits_vpu_fpu_isReduction;
  logic io_in_1_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_1_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_1_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_1_bits_vpu_vxrm;
  logic [6:0] io_in_1_bits_vpu_vuopIdx;
  logic io_in_1_bits_vpu_lastUop;
  logic [127:0] io_in_1_bits_vpu_vmask;
  logic [7:0] io_in_1_bits_vpu_vl;
  logic [2:0] io_in_1_bits_vpu_nf;
  logic [1:0] io_in_1_bits_vpu_veew;
  logic io_in_1_bits_vpu_isReverse;
  logic io_in_1_bits_vpu_isExt;
  logic io_in_1_bits_vpu_isNarrow;
  logic io_in_1_bits_vpu_isDstMask;
  logic io_in_1_bits_vpu_isOpMask;
  logic io_in_1_bits_vpu_isMove;
  logic io_in_1_bits_vpu_isDependOldVd;
  logic io_in_1_bits_vpu_isWritePartVd;
  logic io_in_1_bits_vpu_isVleff;
  logic io_in_1_bits_vlsInstr;
  logic io_in_1_bits_wfflags;
  logic io_in_1_bits_isMove;
  logic [6:0] io_in_1_bits_uopIdx;
  logic io_in_1_bits_isVset;
  logic io_in_1_bits_firstUop;
  logic io_in_1_bits_lastUop;
  logic [6:0] io_in_1_bits_numUops;
  logic [6:0] io_in_1_bits_numWB;
  logic [2:0] io_in_1_bits_commitType;
  logic [7:0] io_in_1_bits_psrc_0;
  logic [7:0] io_in_1_bits_psrc_1;
  logic [7:0] io_in_1_bits_psrc_2;
  logic [7:0] io_in_1_bits_psrc_3;
  logic [7:0] io_in_1_bits_psrc_4;
  logic [7:0] io_in_1_bits_pdest;
  logic io_in_1_bits_robIdx_flag;
  logic [7:0] io_in_1_bits_robIdx_value;
  logic [2:0] io_in_1_bits_instrSize;
  logic io_in_1_bits_dirtyFs;
  logic io_in_1_bits_dirtyVs;
  logic [3:0] io_in_1_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_1_bits_traceBlockInPipe_iretire;
  logic io_in_1_bits_traceBlockInPipe_ilastsize;
  logic io_in_1_bits_eliminatedMove;
  logic [63:0] io_in_1_bits_debugInfo_renameTime;
  logic [55:0] io_in_1_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_1_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_1_bits_debug_fuType;
  logic io_in_1_bits_debug_sim_trig;
  logic [4:0] io_in_1_bits_numLsElem;
  logic io_in_2_valid, io_out_2_ready;
  logic [31:0] io_in_2_bits_instr;
  logic [49:0] io_in_2_bits_pc;
  logic [9:0] io_in_2_bits_foldpc;
  logic io_in_2_bits_exceptionVec_0;
  logic io_in_2_bits_exceptionVec_1;
  logic io_in_2_bits_exceptionVec_2;
  logic io_in_2_bits_exceptionVec_3;
  logic io_in_2_bits_exceptionVec_4;
  logic io_in_2_bits_exceptionVec_5;
  logic io_in_2_bits_exceptionVec_6;
  logic io_in_2_bits_exceptionVec_7;
  logic io_in_2_bits_exceptionVec_8;
  logic io_in_2_bits_exceptionVec_9;
  logic io_in_2_bits_exceptionVec_10;
  logic io_in_2_bits_exceptionVec_11;
  logic io_in_2_bits_exceptionVec_12;
  logic io_in_2_bits_exceptionVec_13;
  logic io_in_2_bits_exceptionVec_14;
  logic io_in_2_bits_exceptionVec_15;
  logic io_in_2_bits_exceptionVec_16;
  logic io_in_2_bits_exceptionVec_17;
  logic io_in_2_bits_exceptionVec_18;
  logic io_in_2_bits_exceptionVec_19;
  logic io_in_2_bits_exceptionVec_20;
  logic io_in_2_bits_exceptionVec_21;
  logic io_in_2_bits_exceptionVec_22;
  logic io_in_2_bits_exceptionVec_23;
  logic io_in_2_bits_isFetchMalAddr;
  logic io_in_2_bits_hasException;
  logic [3:0] io_in_2_bits_trigger;
  logic io_in_2_bits_preDecodeInfo_valid;
  logic io_in_2_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_2_bits_preDecodeInfo_brType;
  logic io_in_2_bits_preDecodeInfo_isCall;
  logic io_in_2_bits_preDecodeInfo_isRet;
  logic io_in_2_bits_pred_taken;
  logic io_in_2_bits_crossPageIPFFix;
  logic io_in_2_bits_ftqPtr_flag;
  logic [5:0] io_in_2_bits_ftqPtr_value;
  logic [3:0] io_in_2_bits_ftqOffset;
  logic io_in_2_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_2_bits_srcType_0;
  logic [3:0] io_in_2_bits_srcType_1;
  logic [3:0] io_in_2_bits_srcType_2;
  logic [3:0] io_in_2_bits_srcType_3;
  logic [3:0] io_in_2_bits_srcType_4;
  logic [5:0] io_in_2_bits_ldest;
  logic [34:0] io_in_2_bits_fuType;
  logic [8:0] io_in_2_bits_fuOpType;
  logic io_in_2_bits_rfWen;
  logic io_in_2_bits_fpWen;
  logic io_in_2_bits_vecWen;
  logic io_in_2_bits_v0Wen;
  logic io_in_2_bits_vlWen;
  logic io_in_2_bits_isXSTrap;
  logic io_in_2_bits_waitForward;
  logic io_in_2_bits_blockBackward;
  logic io_in_2_bits_flushPipe;
  logic io_in_2_bits_canRobCompress;
  logic [3:0] io_in_2_bits_selImm;
  logic [31:0] io_in_2_bits_imm;
  logic [1:0] io_in_2_bits_fpu_typeTagOut;
  logic io_in_2_bits_fpu_wflags;
  logic [1:0] io_in_2_bits_fpu_typ;
  logic [1:0] io_in_2_bits_fpu_fmt;
  logic [2:0] io_in_2_bits_fpu_rm;
  logic io_in_2_bits_vpu_vill;
  logic io_in_2_bits_vpu_vma;
  logic io_in_2_bits_vpu_vta;
  logic [1:0] io_in_2_bits_vpu_vsew;
  logic [2:0] io_in_2_bits_vpu_vlmul;
  logic io_in_2_bits_vpu_specVill;
  logic io_in_2_bits_vpu_specVma;
  logic io_in_2_bits_vpu_specVta;
  logic [1:0] io_in_2_bits_vpu_specVsew;
  logic [2:0] io_in_2_bits_vpu_specVlmul;
  logic io_in_2_bits_vpu_vm;
  logic [7:0] io_in_2_bits_vpu_vstart;
  logic [2:0] io_in_2_bits_vpu_frm;
  logic io_in_2_bits_vpu_fpu_isFpToVecInst;
  logic io_in_2_bits_vpu_fpu_isFP32Instr;
  logic io_in_2_bits_vpu_fpu_isFP64Instr;
  logic io_in_2_bits_vpu_fpu_isReduction;
  logic io_in_2_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_2_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_2_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_2_bits_vpu_vxrm;
  logic [6:0] io_in_2_bits_vpu_vuopIdx;
  logic io_in_2_bits_vpu_lastUop;
  logic [127:0] io_in_2_bits_vpu_vmask;
  logic [7:0] io_in_2_bits_vpu_vl;
  logic [2:0] io_in_2_bits_vpu_nf;
  logic [1:0] io_in_2_bits_vpu_veew;
  logic io_in_2_bits_vpu_isReverse;
  logic io_in_2_bits_vpu_isExt;
  logic io_in_2_bits_vpu_isNarrow;
  logic io_in_2_bits_vpu_isDstMask;
  logic io_in_2_bits_vpu_isOpMask;
  logic io_in_2_bits_vpu_isMove;
  logic io_in_2_bits_vpu_isDependOldVd;
  logic io_in_2_bits_vpu_isWritePartVd;
  logic io_in_2_bits_vpu_isVleff;
  logic io_in_2_bits_vlsInstr;
  logic io_in_2_bits_wfflags;
  logic io_in_2_bits_isMove;
  logic [6:0] io_in_2_bits_uopIdx;
  logic io_in_2_bits_isVset;
  logic io_in_2_bits_firstUop;
  logic io_in_2_bits_lastUop;
  logic [6:0] io_in_2_bits_numUops;
  logic [6:0] io_in_2_bits_numWB;
  logic [2:0] io_in_2_bits_commitType;
  logic [7:0] io_in_2_bits_psrc_0;
  logic [7:0] io_in_2_bits_psrc_1;
  logic [7:0] io_in_2_bits_psrc_2;
  logic [7:0] io_in_2_bits_psrc_3;
  logic [7:0] io_in_2_bits_psrc_4;
  logic [7:0] io_in_2_bits_pdest;
  logic io_in_2_bits_robIdx_flag;
  logic [7:0] io_in_2_bits_robIdx_value;
  logic [2:0] io_in_2_bits_instrSize;
  logic io_in_2_bits_dirtyFs;
  logic io_in_2_bits_dirtyVs;
  logic [3:0] io_in_2_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_2_bits_traceBlockInPipe_iretire;
  logic io_in_2_bits_traceBlockInPipe_ilastsize;
  logic io_in_2_bits_eliminatedMove;
  logic [63:0] io_in_2_bits_debugInfo_renameTime;
  logic [55:0] io_in_2_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_2_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_2_bits_debug_fuType;
  logic io_in_2_bits_debug_sim_trig;
  logic [4:0] io_in_2_bits_numLsElem;
  logic io_in_3_valid, io_out_3_ready;
  logic [31:0] io_in_3_bits_instr;
  logic [49:0] io_in_3_bits_pc;
  logic [9:0] io_in_3_bits_foldpc;
  logic io_in_3_bits_exceptionVec_0;
  logic io_in_3_bits_exceptionVec_1;
  logic io_in_3_bits_exceptionVec_2;
  logic io_in_3_bits_exceptionVec_3;
  logic io_in_3_bits_exceptionVec_4;
  logic io_in_3_bits_exceptionVec_5;
  logic io_in_3_bits_exceptionVec_6;
  logic io_in_3_bits_exceptionVec_7;
  logic io_in_3_bits_exceptionVec_8;
  logic io_in_3_bits_exceptionVec_9;
  logic io_in_3_bits_exceptionVec_10;
  logic io_in_3_bits_exceptionVec_11;
  logic io_in_3_bits_exceptionVec_12;
  logic io_in_3_bits_exceptionVec_13;
  logic io_in_3_bits_exceptionVec_14;
  logic io_in_3_bits_exceptionVec_15;
  logic io_in_3_bits_exceptionVec_16;
  logic io_in_3_bits_exceptionVec_17;
  logic io_in_3_bits_exceptionVec_18;
  logic io_in_3_bits_exceptionVec_19;
  logic io_in_3_bits_exceptionVec_20;
  logic io_in_3_bits_exceptionVec_21;
  logic io_in_3_bits_exceptionVec_22;
  logic io_in_3_bits_exceptionVec_23;
  logic io_in_3_bits_isFetchMalAddr;
  logic io_in_3_bits_hasException;
  logic [3:0] io_in_3_bits_trigger;
  logic io_in_3_bits_preDecodeInfo_valid;
  logic io_in_3_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_3_bits_preDecodeInfo_brType;
  logic io_in_3_bits_preDecodeInfo_isCall;
  logic io_in_3_bits_preDecodeInfo_isRet;
  logic io_in_3_bits_pred_taken;
  logic io_in_3_bits_crossPageIPFFix;
  logic io_in_3_bits_ftqPtr_flag;
  logic [5:0] io_in_3_bits_ftqPtr_value;
  logic [3:0] io_in_3_bits_ftqOffset;
  logic io_in_3_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_3_bits_srcType_0;
  logic [3:0] io_in_3_bits_srcType_1;
  logic [3:0] io_in_3_bits_srcType_2;
  logic [3:0] io_in_3_bits_srcType_3;
  logic [3:0] io_in_3_bits_srcType_4;
  logic [5:0] io_in_3_bits_ldest;
  logic [34:0] io_in_3_bits_fuType;
  logic [8:0] io_in_3_bits_fuOpType;
  logic io_in_3_bits_rfWen;
  logic io_in_3_bits_fpWen;
  logic io_in_3_bits_vecWen;
  logic io_in_3_bits_v0Wen;
  logic io_in_3_bits_vlWen;
  logic io_in_3_bits_isXSTrap;
  logic io_in_3_bits_waitForward;
  logic io_in_3_bits_blockBackward;
  logic io_in_3_bits_flushPipe;
  logic io_in_3_bits_canRobCompress;
  logic [3:0] io_in_3_bits_selImm;
  logic [31:0] io_in_3_bits_imm;
  logic [1:0] io_in_3_bits_fpu_typeTagOut;
  logic io_in_3_bits_fpu_wflags;
  logic [1:0] io_in_3_bits_fpu_typ;
  logic [1:0] io_in_3_bits_fpu_fmt;
  logic [2:0] io_in_3_bits_fpu_rm;
  logic io_in_3_bits_vpu_vill;
  logic io_in_3_bits_vpu_vma;
  logic io_in_3_bits_vpu_vta;
  logic [1:0] io_in_3_bits_vpu_vsew;
  logic [2:0] io_in_3_bits_vpu_vlmul;
  logic io_in_3_bits_vpu_specVill;
  logic io_in_3_bits_vpu_specVma;
  logic io_in_3_bits_vpu_specVta;
  logic [1:0] io_in_3_bits_vpu_specVsew;
  logic [2:0] io_in_3_bits_vpu_specVlmul;
  logic io_in_3_bits_vpu_vm;
  logic [7:0] io_in_3_bits_vpu_vstart;
  logic [2:0] io_in_3_bits_vpu_frm;
  logic io_in_3_bits_vpu_fpu_isFpToVecInst;
  logic io_in_3_bits_vpu_fpu_isFP32Instr;
  logic io_in_3_bits_vpu_fpu_isFP64Instr;
  logic io_in_3_bits_vpu_fpu_isReduction;
  logic io_in_3_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_3_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_3_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_3_bits_vpu_vxrm;
  logic [6:0] io_in_3_bits_vpu_vuopIdx;
  logic io_in_3_bits_vpu_lastUop;
  logic [127:0] io_in_3_bits_vpu_vmask;
  logic [7:0] io_in_3_bits_vpu_vl;
  logic [2:0] io_in_3_bits_vpu_nf;
  logic [1:0] io_in_3_bits_vpu_veew;
  logic io_in_3_bits_vpu_isReverse;
  logic io_in_3_bits_vpu_isExt;
  logic io_in_3_bits_vpu_isNarrow;
  logic io_in_3_bits_vpu_isDstMask;
  logic io_in_3_bits_vpu_isOpMask;
  logic io_in_3_bits_vpu_isMove;
  logic io_in_3_bits_vpu_isDependOldVd;
  logic io_in_3_bits_vpu_isWritePartVd;
  logic io_in_3_bits_vpu_isVleff;
  logic io_in_3_bits_vlsInstr;
  logic io_in_3_bits_wfflags;
  logic io_in_3_bits_isMove;
  logic [6:0] io_in_3_bits_uopIdx;
  logic io_in_3_bits_isVset;
  logic io_in_3_bits_firstUop;
  logic io_in_3_bits_lastUop;
  logic [6:0] io_in_3_bits_numUops;
  logic [6:0] io_in_3_bits_numWB;
  logic [2:0] io_in_3_bits_commitType;
  logic [7:0] io_in_3_bits_psrc_0;
  logic [7:0] io_in_3_bits_psrc_1;
  logic [7:0] io_in_3_bits_psrc_2;
  logic [7:0] io_in_3_bits_psrc_3;
  logic [7:0] io_in_3_bits_psrc_4;
  logic [7:0] io_in_3_bits_pdest;
  logic io_in_3_bits_robIdx_flag;
  logic [7:0] io_in_3_bits_robIdx_value;
  logic [2:0] io_in_3_bits_instrSize;
  logic io_in_3_bits_dirtyFs;
  logic io_in_3_bits_dirtyVs;
  logic [3:0] io_in_3_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_3_bits_traceBlockInPipe_iretire;
  logic io_in_3_bits_traceBlockInPipe_ilastsize;
  logic io_in_3_bits_eliminatedMove;
  logic [63:0] io_in_3_bits_debugInfo_renameTime;
  logic [55:0] io_in_3_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_3_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_3_bits_debug_fuType;
  logic io_in_3_bits_debug_sim_trig;
  logic [4:0] io_in_3_bits_numLsElem;
  logic io_in_4_valid, io_out_4_ready;
  logic [31:0] io_in_4_bits_instr;
  logic [49:0] io_in_4_bits_pc;
  logic [9:0] io_in_4_bits_foldpc;
  logic io_in_4_bits_exceptionVec_0;
  logic io_in_4_bits_exceptionVec_1;
  logic io_in_4_bits_exceptionVec_2;
  logic io_in_4_bits_exceptionVec_3;
  logic io_in_4_bits_exceptionVec_4;
  logic io_in_4_bits_exceptionVec_5;
  logic io_in_4_bits_exceptionVec_6;
  logic io_in_4_bits_exceptionVec_7;
  logic io_in_4_bits_exceptionVec_8;
  logic io_in_4_bits_exceptionVec_9;
  logic io_in_4_bits_exceptionVec_10;
  logic io_in_4_bits_exceptionVec_11;
  logic io_in_4_bits_exceptionVec_12;
  logic io_in_4_bits_exceptionVec_13;
  logic io_in_4_bits_exceptionVec_14;
  logic io_in_4_bits_exceptionVec_15;
  logic io_in_4_bits_exceptionVec_16;
  logic io_in_4_bits_exceptionVec_17;
  logic io_in_4_bits_exceptionVec_18;
  logic io_in_4_bits_exceptionVec_19;
  logic io_in_4_bits_exceptionVec_20;
  logic io_in_4_bits_exceptionVec_21;
  logic io_in_4_bits_exceptionVec_22;
  logic io_in_4_bits_exceptionVec_23;
  logic io_in_4_bits_isFetchMalAddr;
  logic io_in_4_bits_hasException;
  logic [3:0] io_in_4_bits_trigger;
  logic io_in_4_bits_preDecodeInfo_valid;
  logic io_in_4_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_4_bits_preDecodeInfo_brType;
  logic io_in_4_bits_preDecodeInfo_isCall;
  logic io_in_4_bits_preDecodeInfo_isRet;
  logic io_in_4_bits_pred_taken;
  logic io_in_4_bits_crossPageIPFFix;
  logic io_in_4_bits_ftqPtr_flag;
  logic [5:0] io_in_4_bits_ftqPtr_value;
  logic [3:0] io_in_4_bits_ftqOffset;
  logic io_in_4_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_4_bits_srcType_0;
  logic [3:0] io_in_4_bits_srcType_1;
  logic [3:0] io_in_4_bits_srcType_2;
  logic [3:0] io_in_4_bits_srcType_3;
  logic [3:0] io_in_4_bits_srcType_4;
  logic [5:0] io_in_4_bits_ldest;
  logic [34:0] io_in_4_bits_fuType;
  logic [8:0] io_in_4_bits_fuOpType;
  logic io_in_4_bits_rfWen;
  logic io_in_4_bits_fpWen;
  logic io_in_4_bits_vecWen;
  logic io_in_4_bits_v0Wen;
  logic io_in_4_bits_vlWen;
  logic io_in_4_bits_isXSTrap;
  logic io_in_4_bits_waitForward;
  logic io_in_4_bits_blockBackward;
  logic io_in_4_bits_flushPipe;
  logic io_in_4_bits_canRobCompress;
  logic [3:0] io_in_4_bits_selImm;
  logic [31:0] io_in_4_bits_imm;
  logic [1:0] io_in_4_bits_fpu_typeTagOut;
  logic io_in_4_bits_fpu_wflags;
  logic [1:0] io_in_4_bits_fpu_typ;
  logic [1:0] io_in_4_bits_fpu_fmt;
  logic [2:0] io_in_4_bits_fpu_rm;
  logic io_in_4_bits_vpu_vill;
  logic io_in_4_bits_vpu_vma;
  logic io_in_4_bits_vpu_vta;
  logic [1:0] io_in_4_bits_vpu_vsew;
  logic [2:0] io_in_4_bits_vpu_vlmul;
  logic io_in_4_bits_vpu_specVill;
  logic io_in_4_bits_vpu_specVma;
  logic io_in_4_bits_vpu_specVta;
  logic [1:0] io_in_4_bits_vpu_specVsew;
  logic [2:0] io_in_4_bits_vpu_specVlmul;
  logic io_in_4_bits_vpu_vm;
  logic [7:0] io_in_4_bits_vpu_vstart;
  logic [2:0] io_in_4_bits_vpu_frm;
  logic io_in_4_bits_vpu_fpu_isFpToVecInst;
  logic io_in_4_bits_vpu_fpu_isFP32Instr;
  logic io_in_4_bits_vpu_fpu_isFP64Instr;
  logic io_in_4_bits_vpu_fpu_isReduction;
  logic io_in_4_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_4_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_4_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_4_bits_vpu_vxrm;
  logic [6:0] io_in_4_bits_vpu_vuopIdx;
  logic io_in_4_bits_vpu_lastUop;
  logic [127:0] io_in_4_bits_vpu_vmask;
  logic [7:0] io_in_4_bits_vpu_vl;
  logic [2:0] io_in_4_bits_vpu_nf;
  logic [1:0] io_in_4_bits_vpu_veew;
  logic io_in_4_bits_vpu_isReverse;
  logic io_in_4_bits_vpu_isExt;
  logic io_in_4_bits_vpu_isNarrow;
  logic io_in_4_bits_vpu_isDstMask;
  logic io_in_4_bits_vpu_isOpMask;
  logic io_in_4_bits_vpu_isMove;
  logic io_in_4_bits_vpu_isDependOldVd;
  logic io_in_4_bits_vpu_isWritePartVd;
  logic io_in_4_bits_vpu_isVleff;
  logic io_in_4_bits_vlsInstr;
  logic io_in_4_bits_wfflags;
  logic io_in_4_bits_isMove;
  logic [6:0] io_in_4_bits_uopIdx;
  logic io_in_4_bits_isVset;
  logic io_in_4_bits_firstUop;
  logic io_in_4_bits_lastUop;
  logic [6:0] io_in_4_bits_numUops;
  logic [6:0] io_in_4_bits_numWB;
  logic [2:0] io_in_4_bits_commitType;
  logic [7:0] io_in_4_bits_psrc_0;
  logic [7:0] io_in_4_bits_psrc_1;
  logic [7:0] io_in_4_bits_psrc_2;
  logic [7:0] io_in_4_bits_psrc_3;
  logic [7:0] io_in_4_bits_psrc_4;
  logic [7:0] io_in_4_bits_pdest;
  logic io_in_4_bits_robIdx_flag;
  logic [7:0] io_in_4_bits_robIdx_value;
  logic [2:0] io_in_4_bits_instrSize;
  logic io_in_4_bits_dirtyFs;
  logic io_in_4_bits_dirtyVs;
  logic [3:0] io_in_4_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_4_bits_traceBlockInPipe_iretire;
  logic io_in_4_bits_traceBlockInPipe_ilastsize;
  logic io_in_4_bits_eliminatedMove;
  logic [63:0] io_in_4_bits_debugInfo_renameTime;
  logic [55:0] io_in_4_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_4_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_4_bits_debug_fuType;
  logic io_in_4_bits_debug_sim_trig;
  logic [4:0] io_in_4_bits_numLsElem;
  logic io_in_5_valid, io_out_5_ready;
  logic [31:0] io_in_5_bits_instr;
  logic [49:0] io_in_5_bits_pc;
  logic [9:0] io_in_5_bits_foldpc;
  logic io_in_5_bits_exceptionVec_0;
  logic io_in_5_bits_exceptionVec_1;
  logic io_in_5_bits_exceptionVec_2;
  logic io_in_5_bits_exceptionVec_3;
  logic io_in_5_bits_exceptionVec_4;
  logic io_in_5_bits_exceptionVec_5;
  logic io_in_5_bits_exceptionVec_6;
  logic io_in_5_bits_exceptionVec_7;
  logic io_in_5_bits_exceptionVec_8;
  logic io_in_5_bits_exceptionVec_9;
  logic io_in_5_bits_exceptionVec_10;
  logic io_in_5_bits_exceptionVec_11;
  logic io_in_5_bits_exceptionVec_12;
  logic io_in_5_bits_exceptionVec_13;
  logic io_in_5_bits_exceptionVec_14;
  logic io_in_5_bits_exceptionVec_15;
  logic io_in_5_bits_exceptionVec_16;
  logic io_in_5_bits_exceptionVec_17;
  logic io_in_5_bits_exceptionVec_18;
  logic io_in_5_bits_exceptionVec_19;
  logic io_in_5_bits_exceptionVec_20;
  logic io_in_5_bits_exceptionVec_21;
  logic io_in_5_bits_exceptionVec_22;
  logic io_in_5_bits_exceptionVec_23;
  logic io_in_5_bits_isFetchMalAddr;
  logic io_in_5_bits_hasException;
  logic [3:0] io_in_5_bits_trigger;
  logic io_in_5_bits_preDecodeInfo_valid;
  logic io_in_5_bits_preDecodeInfo_isRVC;
  logic [1:0] io_in_5_bits_preDecodeInfo_brType;
  logic io_in_5_bits_preDecodeInfo_isCall;
  logic io_in_5_bits_preDecodeInfo_isRet;
  logic io_in_5_bits_pred_taken;
  logic io_in_5_bits_crossPageIPFFix;
  logic io_in_5_bits_ftqPtr_flag;
  logic [5:0] io_in_5_bits_ftqPtr_value;
  logic [3:0] io_in_5_bits_ftqOffset;
  logic io_in_5_bits_satpFlushFirstFetchFault;
  logic [3:0] io_in_5_bits_srcType_0;
  logic [3:0] io_in_5_bits_srcType_1;
  logic [3:0] io_in_5_bits_srcType_2;
  logic [3:0] io_in_5_bits_srcType_3;
  logic [3:0] io_in_5_bits_srcType_4;
  logic [5:0] io_in_5_bits_ldest;
  logic [34:0] io_in_5_bits_fuType;
  logic [8:0] io_in_5_bits_fuOpType;
  logic io_in_5_bits_rfWen;
  logic io_in_5_bits_fpWen;
  logic io_in_5_bits_vecWen;
  logic io_in_5_bits_v0Wen;
  logic io_in_5_bits_vlWen;
  logic io_in_5_bits_isXSTrap;
  logic io_in_5_bits_waitForward;
  logic io_in_5_bits_blockBackward;
  logic io_in_5_bits_flushPipe;
  logic io_in_5_bits_canRobCompress;
  logic [3:0] io_in_5_bits_selImm;
  logic [31:0] io_in_5_bits_imm;
  logic [1:0] io_in_5_bits_fpu_typeTagOut;
  logic io_in_5_bits_fpu_wflags;
  logic [1:0] io_in_5_bits_fpu_typ;
  logic [1:0] io_in_5_bits_fpu_fmt;
  logic [2:0] io_in_5_bits_fpu_rm;
  logic io_in_5_bits_vpu_vill;
  logic io_in_5_bits_vpu_vma;
  logic io_in_5_bits_vpu_vta;
  logic [1:0] io_in_5_bits_vpu_vsew;
  logic [2:0] io_in_5_bits_vpu_vlmul;
  logic io_in_5_bits_vpu_specVill;
  logic io_in_5_bits_vpu_specVma;
  logic io_in_5_bits_vpu_specVta;
  logic [1:0] io_in_5_bits_vpu_specVsew;
  logic [2:0] io_in_5_bits_vpu_specVlmul;
  logic io_in_5_bits_vpu_vm;
  logic [7:0] io_in_5_bits_vpu_vstart;
  logic [2:0] io_in_5_bits_vpu_frm;
  logic io_in_5_bits_vpu_fpu_isFpToVecInst;
  logic io_in_5_bits_vpu_fpu_isFP32Instr;
  logic io_in_5_bits_vpu_fpu_isFP64Instr;
  logic io_in_5_bits_vpu_fpu_isReduction;
  logic io_in_5_bits_vpu_fpu_isFoldTo1_2;
  logic io_in_5_bits_vpu_fpu_isFoldTo1_4;
  logic io_in_5_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_in_5_bits_vpu_vxrm;
  logic [6:0] io_in_5_bits_vpu_vuopIdx;
  logic io_in_5_bits_vpu_lastUop;
  logic [127:0] io_in_5_bits_vpu_vmask;
  logic [7:0] io_in_5_bits_vpu_vl;
  logic [2:0] io_in_5_bits_vpu_nf;
  logic [1:0] io_in_5_bits_vpu_veew;
  logic io_in_5_bits_vpu_isReverse;
  logic io_in_5_bits_vpu_isExt;
  logic io_in_5_bits_vpu_isNarrow;
  logic io_in_5_bits_vpu_isDstMask;
  logic io_in_5_bits_vpu_isOpMask;
  logic io_in_5_bits_vpu_isMove;
  logic io_in_5_bits_vpu_isDependOldVd;
  logic io_in_5_bits_vpu_isWritePartVd;
  logic io_in_5_bits_vpu_isVleff;
  logic io_in_5_bits_vlsInstr;
  logic io_in_5_bits_wfflags;
  logic io_in_5_bits_isMove;
  logic [6:0] io_in_5_bits_uopIdx;
  logic io_in_5_bits_isVset;
  logic io_in_5_bits_firstUop;
  logic io_in_5_bits_lastUop;
  logic [6:0] io_in_5_bits_numUops;
  logic [6:0] io_in_5_bits_numWB;
  logic [2:0] io_in_5_bits_commitType;
  logic [7:0] io_in_5_bits_psrc_0;
  logic [7:0] io_in_5_bits_psrc_1;
  logic [7:0] io_in_5_bits_psrc_2;
  logic [7:0] io_in_5_bits_psrc_3;
  logic [7:0] io_in_5_bits_psrc_4;
  logic [7:0] io_in_5_bits_pdest;
  logic io_in_5_bits_robIdx_flag;
  logic [7:0] io_in_5_bits_robIdx_value;
  logic [2:0] io_in_5_bits_instrSize;
  logic io_in_5_bits_dirtyFs;
  logic io_in_5_bits_dirtyVs;
  logic [3:0] io_in_5_bits_traceBlockInPipe_itype;
  logic [3:0] io_in_5_bits_traceBlockInPipe_iretire;
  logic io_in_5_bits_traceBlockInPipe_ilastsize;
  logic io_in_5_bits_eliminatedMove;
  logic [63:0] io_in_5_bits_debugInfo_renameTime;
  logic [55:0] io_in_5_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_5_bits_debug_seqNum_uopIdx;
  logic [34:0] io_in_5_bits_debug_fuType;
  logic io_in_5_bits_debug_sim_trig;
  logic [4:0] io_in_5_bits_numLsElem;
  wire  g_l0_io_in_ready, i_l0_io_in_ready, g_l0_io_out_valid, i_l0_io_out_valid;
  wire  [31:0] g_l0_io_out_bits_instr, i_l0_io_out_bits_instr;
  wire  [49:0] g_l0_io_out_bits_pc, i_l0_io_out_bits_pc;
  wire  [9:0] g_l0_io_out_bits_foldpc, i_l0_io_out_bits_foldpc;
  wire  g_l0_io_out_bits_exceptionVec_0, i_l0_io_out_bits_exceptionVec_0;
  wire  g_l0_io_out_bits_exceptionVec_1, i_l0_io_out_bits_exceptionVec_1;
  wire  g_l0_io_out_bits_exceptionVec_2, i_l0_io_out_bits_exceptionVec_2;
  wire  g_l0_io_out_bits_exceptionVec_3, i_l0_io_out_bits_exceptionVec_3;
  wire  g_l0_io_out_bits_exceptionVec_4, i_l0_io_out_bits_exceptionVec_4;
  wire  g_l0_io_out_bits_exceptionVec_5, i_l0_io_out_bits_exceptionVec_5;
  wire  g_l0_io_out_bits_exceptionVec_6, i_l0_io_out_bits_exceptionVec_6;
  wire  g_l0_io_out_bits_exceptionVec_7, i_l0_io_out_bits_exceptionVec_7;
  wire  g_l0_io_out_bits_exceptionVec_8, i_l0_io_out_bits_exceptionVec_8;
  wire  g_l0_io_out_bits_exceptionVec_9, i_l0_io_out_bits_exceptionVec_9;
  wire  g_l0_io_out_bits_exceptionVec_10, i_l0_io_out_bits_exceptionVec_10;
  wire  g_l0_io_out_bits_exceptionVec_11, i_l0_io_out_bits_exceptionVec_11;
  wire  g_l0_io_out_bits_exceptionVec_12, i_l0_io_out_bits_exceptionVec_12;
  wire  g_l0_io_out_bits_exceptionVec_13, i_l0_io_out_bits_exceptionVec_13;
  wire  g_l0_io_out_bits_exceptionVec_14, i_l0_io_out_bits_exceptionVec_14;
  wire  g_l0_io_out_bits_exceptionVec_15, i_l0_io_out_bits_exceptionVec_15;
  wire  g_l0_io_out_bits_exceptionVec_16, i_l0_io_out_bits_exceptionVec_16;
  wire  g_l0_io_out_bits_exceptionVec_17, i_l0_io_out_bits_exceptionVec_17;
  wire  g_l0_io_out_bits_exceptionVec_18, i_l0_io_out_bits_exceptionVec_18;
  wire  g_l0_io_out_bits_exceptionVec_19, i_l0_io_out_bits_exceptionVec_19;
  wire  g_l0_io_out_bits_exceptionVec_20, i_l0_io_out_bits_exceptionVec_20;
  wire  g_l0_io_out_bits_exceptionVec_21, i_l0_io_out_bits_exceptionVec_21;
  wire  g_l0_io_out_bits_exceptionVec_22, i_l0_io_out_bits_exceptionVec_22;
  wire  g_l0_io_out_bits_exceptionVec_23, i_l0_io_out_bits_exceptionVec_23;
  wire  g_l0_io_out_bits_isFetchMalAddr, i_l0_io_out_bits_isFetchMalAddr;
  wire  g_l0_io_out_bits_hasException, i_l0_io_out_bits_hasException;
  wire  [3:0] g_l0_io_out_bits_trigger, i_l0_io_out_bits_trigger;
  wire  g_l0_io_out_bits_preDecodeInfo_valid, i_l0_io_out_bits_preDecodeInfo_valid;
  wire  g_l0_io_out_bits_preDecodeInfo_isRVC, i_l0_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l0_io_out_bits_preDecodeInfo_brType, i_l0_io_out_bits_preDecodeInfo_brType;
  wire  g_l0_io_out_bits_preDecodeInfo_isCall, i_l0_io_out_bits_preDecodeInfo_isCall;
  wire  g_l0_io_out_bits_preDecodeInfo_isRet, i_l0_io_out_bits_preDecodeInfo_isRet;
  wire  g_l0_io_out_bits_pred_taken, i_l0_io_out_bits_pred_taken;
  wire  g_l0_io_out_bits_crossPageIPFFix, i_l0_io_out_bits_crossPageIPFFix;
  wire  g_l0_io_out_bits_ftqPtr_flag, i_l0_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l0_io_out_bits_ftqPtr_value, i_l0_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l0_io_out_bits_ftqOffset, i_l0_io_out_bits_ftqOffset;
  wire  g_l0_io_out_bits_satpFlushFirstFetchFault, i_l0_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l0_io_out_bits_srcType_0, i_l0_io_out_bits_srcType_0;
  wire  [3:0] g_l0_io_out_bits_srcType_1, i_l0_io_out_bits_srcType_1;
  wire  [3:0] g_l0_io_out_bits_srcType_2, i_l0_io_out_bits_srcType_2;
  wire  [3:0] g_l0_io_out_bits_srcType_3, i_l0_io_out_bits_srcType_3;
  wire  [3:0] g_l0_io_out_bits_srcType_4, i_l0_io_out_bits_srcType_4;
  wire  [5:0] g_l0_io_out_bits_ldest, i_l0_io_out_bits_ldest;
  wire  [34:0] g_l0_io_out_bits_fuType, i_l0_io_out_bits_fuType;
  wire  [8:0] g_l0_io_out_bits_fuOpType, i_l0_io_out_bits_fuOpType;
  wire  g_l0_io_out_bits_rfWen, i_l0_io_out_bits_rfWen;
  wire  g_l0_io_out_bits_fpWen, i_l0_io_out_bits_fpWen;
  wire  g_l0_io_out_bits_vecWen, i_l0_io_out_bits_vecWen;
  wire  g_l0_io_out_bits_v0Wen, i_l0_io_out_bits_v0Wen;
  wire  g_l0_io_out_bits_vlWen, i_l0_io_out_bits_vlWen;
  wire  g_l0_io_out_bits_isXSTrap, i_l0_io_out_bits_isXSTrap;
  wire  g_l0_io_out_bits_waitForward, i_l0_io_out_bits_waitForward;
  wire  g_l0_io_out_bits_blockBackward, i_l0_io_out_bits_blockBackward;
  wire  g_l0_io_out_bits_flushPipe, i_l0_io_out_bits_flushPipe;
  wire  g_l0_io_out_bits_canRobCompress, i_l0_io_out_bits_canRobCompress;
  wire  [3:0] g_l0_io_out_bits_selImm, i_l0_io_out_bits_selImm;
  wire  [31:0] g_l0_io_out_bits_imm, i_l0_io_out_bits_imm;
  wire  [1:0] g_l0_io_out_bits_fpu_typeTagOut, i_l0_io_out_bits_fpu_typeTagOut;
  wire  g_l0_io_out_bits_fpu_wflags, i_l0_io_out_bits_fpu_wflags;
  wire  [1:0] g_l0_io_out_bits_fpu_typ, i_l0_io_out_bits_fpu_typ;
  wire  [1:0] g_l0_io_out_bits_fpu_fmt, i_l0_io_out_bits_fpu_fmt;
  wire  [2:0] g_l0_io_out_bits_fpu_rm, i_l0_io_out_bits_fpu_rm;
  wire  g_l0_io_out_bits_vpu_vill, i_l0_io_out_bits_vpu_vill;
  wire  g_l0_io_out_bits_vpu_vma, i_l0_io_out_bits_vpu_vma;
  wire  g_l0_io_out_bits_vpu_vta, i_l0_io_out_bits_vpu_vta;
  wire  [1:0] g_l0_io_out_bits_vpu_vsew, i_l0_io_out_bits_vpu_vsew;
  wire  [2:0] g_l0_io_out_bits_vpu_vlmul, i_l0_io_out_bits_vpu_vlmul;
  wire  g_l0_io_out_bits_vpu_specVill, i_l0_io_out_bits_vpu_specVill;
  wire  g_l0_io_out_bits_vpu_specVma, i_l0_io_out_bits_vpu_specVma;
  wire  g_l0_io_out_bits_vpu_specVta, i_l0_io_out_bits_vpu_specVta;
  wire  [1:0] g_l0_io_out_bits_vpu_specVsew, i_l0_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l0_io_out_bits_vpu_specVlmul, i_l0_io_out_bits_vpu_specVlmul;
  wire  g_l0_io_out_bits_vpu_vm, i_l0_io_out_bits_vpu_vm;
  wire  [7:0] g_l0_io_out_bits_vpu_vstart, i_l0_io_out_bits_vpu_vstart;
  wire  [2:0] g_l0_io_out_bits_vpu_frm, i_l0_io_out_bits_vpu_frm;
  wire  g_l0_io_out_bits_vpu_fpu_isFpToVecInst, i_l0_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l0_io_out_bits_vpu_fpu_isFP32Instr, i_l0_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l0_io_out_bits_vpu_fpu_isFP64Instr, i_l0_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l0_io_out_bits_vpu_fpu_isReduction, i_l0_io_out_bits_vpu_fpu_isReduction;
  wire  g_l0_io_out_bits_vpu_fpu_isFoldTo1_2, i_l0_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l0_io_out_bits_vpu_fpu_isFoldTo1_4, i_l0_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l0_io_out_bits_vpu_fpu_isFoldTo1_8, i_l0_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l0_io_out_bits_vpu_vxrm, i_l0_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l0_io_out_bits_vpu_vuopIdx, i_l0_io_out_bits_vpu_vuopIdx;
  wire  g_l0_io_out_bits_vpu_lastUop, i_l0_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l0_io_out_bits_vpu_vmask, i_l0_io_out_bits_vpu_vmask;
  wire  [7:0] g_l0_io_out_bits_vpu_vl, i_l0_io_out_bits_vpu_vl;
  wire  [2:0] g_l0_io_out_bits_vpu_nf, i_l0_io_out_bits_vpu_nf;
  wire  [1:0] g_l0_io_out_bits_vpu_veew, i_l0_io_out_bits_vpu_veew;
  wire  g_l0_io_out_bits_vpu_isReverse, i_l0_io_out_bits_vpu_isReverse;
  wire  g_l0_io_out_bits_vpu_isExt, i_l0_io_out_bits_vpu_isExt;
  wire  g_l0_io_out_bits_vpu_isNarrow, i_l0_io_out_bits_vpu_isNarrow;
  wire  g_l0_io_out_bits_vpu_isDstMask, i_l0_io_out_bits_vpu_isDstMask;
  wire  g_l0_io_out_bits_vpu_isOpMask, i_l0_io_out_bits_vpu_isOpMask;
  wire  g_l0_io_out_bits_vpu_isMove, i_l0_io_out_bits_vpu_isMove;
  wire  g_l0_io_out_bits_vpu_isDependOldVd, i_l0_io_out_bits_vpu_isDependOldVd;
  wire  g_l0_io_out_bits_vpu_isWritePartVd, i_l0_io_out_bits_vpu_isWritePartVd;
  wire  g_l0_io_out_bits_vpu_isVleff, i_l0_io_out_bits_vpu_isVleff;
  wire  g_l0_io_out_bits_vlsInstr, i_l0_io_out_bits_vlsInstr;
  wire  g_l0_io_out_bits_wfflags, i_l0_io_out_bits_wfflags;
  wire  g_l0_io_out_bits_isMove, i_l0_io_out_bits_isMove;
  wire  [6:0] g_l0_io_out_bits_uopIdx, i_l0_io_out_bits_uopIdx;
  wire  g_l0_io_out_bits_isVset, i_l0_io_out_bits_isVset;
  wire  g_l0_io_out_bits_firstUop, i_l0_io_out_bits_firstUop;
  wire  g_l0_io_out_bits_lastUop, i_l0_io_out_bits_lastUop;
  wire  [6:0] g_l0_io_out_bits_numUops, i_l0_io_out_bits_numUops;
  wire  [6:0] g_l0_io_out_bits_numWB, i_l0_io_out_bits_numWB;
  wire  [2:0] g_l0_io_out_bits_commitType, i_l0_io_out_bits_commitType;
  wire  [7:0] g_l0_io_out_bits_psrc_0, i_l0_io_out_bits_psrc_0;
  wire  [7:0] g_l0_io_out_bits_psrc_1, i_l0_io_out_bits_psrc_1;
  wire  [7:0] g_l0_io_out_bits_psrc_2, i_l0_io_out_bits_psrc_2;
  wire  [7:0] g_l0_io_out_bits_psrc_3, i_l0_io_out_bits_psrc_3;
  wire  [7:0] g_l0_io_out_bits_psrc_4, i_l0_io_out_bits_psrc_4;
  wire  [7:0] g_l0_io_out_bits_pdest, i_l0_io_out_bits_pdest;
  wire  g_l0_io_out_bits_robIdx_flag, i_l0_io_out_bits_robIdx_flag;
  wire  [7:0] g_l0_io_out_bits_robIdx_value, i_l0_io_out_bits_robIdx_value;
  wire  [2:0] g_l0_io_out_bits_instrSize, i_l0_io_out_bits_instrSize;
  wire  g_l0_io_out_bits_dirtyFs, i_l0_io_out_bits_dirtyFs;
  wire  g_l0_io_out_bits_dirtyVs, i_l0_io_out_bits_dirtyVs;
  wire  [3:0] g_l0_io_out_bits_traceBlockInPipe_itype, i_l0_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l0_io_out_bits_traceBlockInPipe_iretire, i_l0_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l0_io_out_bits_traceBlockInPipe_ilastsize, i_l0_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l0_io_out_bits_eliminatedMove, i_l0_io_out_bits_eliminatedMove;
  wire  g_l0_io_out_bits_snapshot, i_l0_io_out_bits_snapshot;
  wire  [63:0] g_l0_io_out_bits_debugInfo_renameTime, i_l0_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l0_io_out_bits_debug_seqNum_seqNum, i_l0_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l0_io_out_bits_debug_seqNum_uopIdx, i_l0_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l0_io_out_bits_debug_fuType, i_l0_io_out_bits_debug_fuType;
  wire  g_l0_io_out_bits_debug_sim_trig, i_l0_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l0_io_out_bits_numLsElem, i_l0_io_out_bits_numLsElem;
  wire  g_l1_io_in_ready, i_l1_io_in_ready, g_l1_io_out_valid, i_l1_io_out_valid;
  wire  [31:0] g_l1_io_out_bits_instr, i_l1_io_out_bits_instr;
  wire  [49:0] g_l1_io_out_bits_pc, i_l1_io_out_bits_pc;
  wire  [9:0] g_l1_io_out_bits_foldpc, i_l1_io_out_bits_foldpc;
  wire  g_l1_io_out_bits_exceptionVec_0, i_l1_io_out_bits_exceptionVec_0;
  wire  g_l1_io_out_bits_exceptionVec_1, i_l1_io_out_bits_exceptionVec_1;
  wire  g_l1_io_out_bits_exceptionVec_2, i_l1_io_out_bits_exceptionVec_2;
  wire  g_l1_io_out_bits_exceptionVec_3, i_l1_io_out_bits_exceptionVec_3;
  wire  g_l1_io_out_bits_exceptionVec_4, i_l1_io_out_bits_exceptionVec_4;
  wire  g_l1_io_out_bits_exceptionVec_5, i_l1_io_out_bits_exceptionVec_5;
  wire  g_l1_io_out_bits_exceptionVec_6, i_l1_io_out_bits_exceptionVec_6;
  wire  g_l1_io_out_bits_exceptionVec_7, i_l1_io_out_bits_exceptionVec_7;
  wire  g_l1_io_out_bits_exceptionVec_8, i_l1_io_out_bits_exceptionVec_8;
  wire  g_l1_io_out_bits_exceptionVec_9, i_l1_io_out_bits_exceptionVec_9;
  wire  g_l1_io_out_bits_exceptionVec_10, i_l1_io_out_bits_exceptionVec_10;
  wire  g_l1_io_out_bits_exceptionVec_11, i_l1_io_out_bits_exceptionVec_11;
  wire  g_l1_io_out_bits_exceptionVec_12, i_l1_io_out_bits_exceptionVec_12;
  wire  g_l1_io_out_bits_exceptionVec_13, i_l1_io_out_bits_exceptionVec_13;
  wire  g_l1_io_out_bits_exceptionVec_14, i_l1_io_out_bits_exceptionVec_14;
  wire  g_l1_io_out_bits_exceptionVec_15, i_l1_io_out_bits_exceptionVec_15;
  wire  g_l1_io_out_bits_exceptionVec_16, i_l1_io_out_bits_exceptionVec_16;
  wire  g_l1_io_out_bits_exceptionVec_17, i_l1_io_out_bits_exceptionVec_17;
  wire  g_l1_io_out_bits_exceptionVec_18, i_l1_io_out_bits_exceptionVec_18;
  wire  g_l1_io_out_bits_exceptionVec_19, i_l1_io_out_bits_exceptionVec_19;
  wire  g_l1_io_out_bits_exceptionVec_20, i_l1_io_out_bits_exceptionVec_20;
  wire  g_l1_io_out_bits_exceptionVec_21, i_l1_io_out_bits_exceptionVec_21;
  wire  g_l1_io_out_bits_exceptionVec_22, i_l1_io_out_bits_exceptionVec_22;
  wire  g_l1_io_out_bits_exceptionVec_23, i_l1_io_out_bits_exceptionVec_23;
  wire  g_l1_io_out_bits_isFetchMalAddr, i_l1_io_out_bits_isFetchMalAddr;
  wire  g_l1_io_out_bits_hasException, i_l1_io_out_bits_hasException;
  wire  [3:0] g_l1_io_out_bits_trigger, i_l1_io_out_bits_trigger;
  wire  g_l1_io_out_bits_preDecodeInfo_valid, i_l1_io_out_bits_preDecodeInfo_valid;
  wire  g_l1_io_out_bits_preDecodeInfo_isRVC, i_l1_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l1_io_out_bits_preDecodeInfo_brType, i_l1_io_out_bits_preDecodeInfo_brType;
  wire  g_l1_io_out_bits_preDecodeInfo_isCall, i_l1_io_out_bits_preDecodeInfo_isCall;
  wire  g_l1_io_out_bits_preDecodeInfo_isRet, i_l1_io_out_bits_preDecodeInfo_isRet;
  wire  g_l1_io_out_bits_pred_taken, i_l1_io_out_bits_pred_taken;
  wire  g_l1_io_out_bits_crossPageIPFFix, i_l1_io_out_bits_crossPageIPFFix;
  wire  g_l1_io_out_bits_ftqPtr_flag, i_l1_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l1_io_out_bits_ftqPtr_value, i_l1_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l1_io_out_bits_ftqOffset, i_l1_io_out_bits_ftqOffset;
  wire  g_l1_io_out_bits_satpFlushFirstFetchFault, i_l1_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l1_io_out_bits_srcType_0, i_l1_io_out_bits_srcType_0;
  wire  [3:0] g_l1_io_out_bits_srcType_1, i_l1_io_out_bits_srcType_1;
  wire  [3:0] g_l1_io_out_bits_srcType_2, i_l1_io_out_bits_srcType_2;
  wire  [3:0] g_l1_io_out_bits_srcType_3, i_l1_io_out_bits_srcType_3;
  wire  [3:0] g_l1_io_out_bits_srcType_4, i_l1_io_out_bits_srcType_4;
  wire  [5:0] g_l1_io_out_bits_ldest, i_l1_io_out_bits_ldest;
  wire  [34:0] g_l1_io_out_bits_fuType, i_l1_io_out_bits_fuType;
  wire  [8:0] g_l1_io_out_bits_fuOpType, i_l1_io_out_bits_fuOpType;
  wire  g_l1_io_out_bits_rfWen, i_l1_io_out_bits_rfWen;
  wire  g_l1_io_out_bits_fpWen, i_l1_io_out_bits_fpWen;
  wire  g_l1_io_out_bits_vecWen, i_l1_io_out_bits_vecWen;
  wire  g_l1_io_out_bits_v0Wen, i_l1_io_out_bits_v0Wen;
  wire  g_l1_io_out_bits_vlWen, i_l1_io_out_bits_vlWen;
  wire  g_l1_io_out_bits_isXSTrap, i_l1_io_out_bits_isXSTrap;
  wire  g_l1_io_out_bits_waitForward, i_l1_io_out_bits_waitForward;
  wire  g_l1_io_out_bits_blockBackward, i_l1_io_out_bits_blockBackward;
  wire  g_l1_io_out_bits_flushPipe, i_l1_io_out_bits_flushPipe;
  wire  g_l1_io_out_bits_canRobCompress, i_l1_io_out_bits_canRobCompress;
  wire  [3:0] g_l1_io_out_bits_selImm, i_l1_io_out_bits_selImm;
  wire  [31:0] g_l1_io_out_bits_imm, i_l1_io_out_bits_imm;
  wire  [1:0] g_l1_io_out_bits_fpu_typeTagOut, i_l1_io_out_bits_fpu_typeTagOut;
  wire  g_l1_io_out_bits_fpu_wflags, i_l1_io_out_bits_fpu_wflags;
  wire  [1:0] g_l1_io_out_bits_fpu_typ, i_l1_io_out_bits_fpu_typ;
  wire  [1:0] g_l1_io_out_bits_fpu_fmt, i_l1_io_out_bits_fpu_fmt;
  wire  [2:0] g_l1_io_out_bits_fpu_rm, i_l1_io_out_bits_fpu_rm;
  wire  g_l1_io_out_bits_vpu_vill, i_l1_io_out_bits_vpu_vill;
  wire  g_l1_io_out_bits_vpu_vma, i_l1_io_out_bits_vpu_vma;
  wire  g_l1_io_out_bits_vpu_vta, i_l1_io_out_bits_vpu_vta;
  wire  [1:0] g_l1_io_out_bits_vpu_vsew, i_l1_io_out_bits_vpu_vsew;
  wire  [2:0] g_l1_io_out_bits_vpu_vlmul, i_l1_io_out_bits_vpu_vlmul;
  wire  g_l1_io_out_bits_vpu_specVill, i_l1_io_out_bits_vpu_specVill;
  wire  g_l1_io_out_bits_vpu_specVma, i_l1_io_out_bits_vpu_specVma;
  wire  g_l1_io_out_bits_vpu_specVta, i_l1_io_out_bits_vpu_specVta;
  wire  [1:0] g_l1_io_out_bits_vpu_specVsew, i_l1_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l1_io_out_bits_vpu_specVlmul, i_l1_io_out_bits_vpu_specVlmul;
  wire  g_l1_io_out_bits_vpu_vm, i_l1_io_out_bits_vpu_vm;
  wire  [7:0] g_l1_io_out_bits_vpu_vstart, i_l1_io_out_bits_vpu_vstart;
  wire  [2:0] g_l1_io_out_bits_vpu_frm, i_l1_io_out_bits_vpu_frm;
  wire  g_l1_io_out_bits_vpu_fpu_isFpToVecInst, i_l1_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l1_io_out_bits_vpu_fpu_isFP32Instr, i_l1_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l1_io_out_bits_vpu_fpu_isFP64Instr, i_l1_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l1_io_out_bits_vpu_fpu_isReduction, i_l1_io_out_bits_vpu_fpu_isReduction;
  wire  g_l1_io_out_bits_vpu_fpu_isFoldTo1_2, i_l1_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l1_io_out_bits_vpu_fpu_isFoldTo1_4, i_l1_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l1_io_out_bits_vpu_fpu_isFoldTo1_8, i_l1_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l1_io_out_bits_vpu_vxrm, i_l1_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l1_io_out_bits_vpu_vuopIdx, i_l1_io_out_bits_vpu_vuopIdx;
  wire  g_l1_io_out_bits_vpu_lastUop, i_l1_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l1_io_out_bits_vpu_vmask, i_l1_io_out_bits_vpu_vmask;
  wire  [7:0] g_l1_io_out_bits_vpu_vl, i_l1_io_out_bits_vpu_vl;
  wire  [2:0] g_l1_io_out_bits_vpu_nf, i_l1_io_out_bits_vpu_nf;
  wire  [1:0] g_l1_io_out_bits_vpu_veew, i_l1_io_out_bits_vpu_veew;
  wire  g_l1_io_out_bits_vpu_isReverse, i_l1_io_out_bits_vpu_isReverse;
  wire  g_l1_io_out_bits_vpu_isExt, i_l1_io_out_bits_vpu_isExt;
  wire  g_l1_io_out_bits_vpu_isNarrow, i_l1_io_out_bits_vpu_isNarrow;
  wire  g_l1_io_out_bits_vpu_isDstMask, i_l1_io_out_bits_vpu_isDstMask;
  wire  g_l1_io_out_bits_vpu_isOpMask, i_l1_io_out_bits_vpu_isOpMask;
  wire  g_l1_io_out_bits_vpu_isMove, i_l1_io_out_bits_vpu_isMove;
  wire  g_l1_io_out_bits_vpu_isDependOldVd, i_l1_io_out_bits_vpu_isDependOldVd;
  wire  g_l1_io_out_bits_vpu_isWritePartVd, i_l1_io_out_bits_vpu_isWritePartVd;
  wire  g_l1_io_out_bits_vpu_isVleff, i_l1_io_out_bits_vpu_isVleff;
  wire  g_l1_io_out_bits_vlsInstr, i_l1_io_out_bits_vlsInstr;
  wire  g_l1_io_out_bits_wfflags, i_l1_io_out_bits_wfflags;
  wire  g_l1_io_out_bits_isMove, i_l1_io_out_bits_isMove;
  wire  [6:0] g_l1_io_out_bits_uopIdx, i_l1_io_out_bits_uopIdx;
  wire  g_l1_io_out_bits_isVset, i_l1_io_out_bits_isVset;
  wire  g_l1_io_out_bits_firstUop, i_l1_io_out_bits_firstUop;
  wire  g_l1_io_out_bits_lastUop, i_l1_io_out_bits_lastUop;
  wire  [6:0] g_l1_io_out_bits_numUops, i_l1_io_out_bits_numUops;
  wire  [6:0] g_l1_io_out_bits_numWB, i_l1_io_out_bits_numWB;
  wire  [2:0] g_l1_io_out_bits_commitType, i_l1_io_out_bits_commitType;
  wire  [7:0] g_l1_io_out_bits_psrc_0, i_l1_io_out_bits_psrc_0;
  wire  [7:0] g_l1_io_out_bits_psrc_1, i_l1_io_out_bits_psrc_1;
  wire  [7:0] g_l1_io_out_bits_psrc_2, i_l1_io_out_bits_psrc_2;
  wire  [7:0] g_l1_io_out_bits_psrc_3, i_l1_io_out_bits_psrc_3;
  wire  [7:0] g_l1_io_out_bits_psrc_4, i_l1_io_out_bits_psrc_4;
  wire  [7:0] g_l1_io_out_bits_pdest, i_l1_io_out_bits_pdest;
  wire  g_l1_io_out_bits_robIdx_flag, i_l1_io_out_bits_robIdx_flag;
  wire  [7:0] g_l1_io_out_bits_robIdx_value, i_l1_io_out_bits_robIdx_value;
  wire  [2:0] g_l1_io_out_bits_instrSize, i_l1_io_out_bits_instrSize;
  wire  g_l1_io_out_bits_dirtyFs, i_l1_io_out_bits_dirtyFs;
  wire  g_l1_io_out_bits_dirtyVs, i_l1_io_out_bits_dirtyVs;
  wire  [3:0] g_l1_io_out_bits_traceBlockInPipe_itype, i_l1_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l1_io_out_bits_traceBlockInPipe_iretire, i_l1_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l1_io_out_bits_traceBlockInPipe_ilastsize, i_l1_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l1_io_out_bits_eliminatedMove, i_l1_io_out_bits_eliminatedMove;
  wire  [63:0] g_l1_io_out_bits_debugInfo_renameTime, i_l1_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l1_io_out_bits_debug_seqNum_seqNum, i_l1_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l1_io_out_bits_debug_seqNum_uopIdx, i_l1_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l1_io_out_bits_debug_fuType, i_l1_io_out_bits_debug_fuType;
  wire  g_l1_io_out_bits_debug_sim_trig, i_l1_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l1_io_out_bits_numLsElem, i_l1_io_out_bits_numLsElem;
  wire  g_l2_io_in_ready, i_l2_io_in_ready, g_l2_io_out_valid, i_l2_io_out_valid;
  wire  [31:0] g_l2_io_out_bits_instr, i_l2_io_out_bits_instr;
  wire  [49:0] g_l2_io_out_bits_pc, i_l2_io_out_bits_pc;
  wire  [9:0] g_l2_io_out_bits_foldpc, i_l2_io_out_bits_foldpc;
  wire  g_l2_io_out_bits_exceptionVec_0, i_l2_io_out_bits_exceptionVec_0;
  wire  g_l2_io_out_bits_exceptionVec_1, i_l2_io_out_bits_exceptionVec_1;
  wire  g_l2_io_out_bits_exceptionVec_2, i_l2_io_out_bits_exceptionVec_2;
  wire  g_l2_io_out_bits_exceptionVec_3, i_l2_io_out_bits_exceptionVec_3;
  wire  g_l2_io_out_bits_exceptionVec_4, i_l2_io_out_bits_exceptionVec_4;
  wire  g_l2_io_out_bits_exceptionVec_5, i_l2_io_out_bits_exceptionVec_5;
  wire  g_l2_io_out_bits_exceptionVec_6, i_l2_io_out_bits_exceptionVec_6;
  wire  g_l2_io_out_bits_exceptionVec_7, i_l2_io_out_bits_exceptionVec_7;
  wire  g_l2_io_out_bits_exceptionVec_8, i_l2_io_out_bits_exceptionVec_8;
  wire  g_l2_io_out_bits_exceptionVec_9, i_l2_io_out_bits_exceptionVec_9;
  wire  g_l2_io_out_bits_exceptionVec_10, i_l2_io_out_bits_exceptionVec_10;
  wire  g_l2_io_out_bits_exceptionVec_11, i_l2_io_out_bits_exceptionVec_11;
  wire  g_l2_io_out_bits_exceptionVec_12, i_l2_io_out_bits_exceptionVec_12;
  wire  g_l2_io_out_bits_exceptionVec_13, i_l2_io_out_bits_exceptionVec_13;
  wire  g_l2_io_out_bits_exceptionVec_14, i_l2_io_out_bits_exceptionVec_14;
  wire  g_l2_io_out_bits_exceptionVec_15, i_l2_io_out_bits_exceptionVec_15;
  wire  g_l2_io_out_bits_exceptionVec_16, i_l2_io_out_bits_exceptionVec_16;
  wire  g_l2_io_out_bits_exceptionVec_17, i_l2_io_out_bits_exceptionVec_17;
  wire  g_l2_io_out_bits_exceptionVec_18, i_l2_io_out_bits_exceptionVec_18;
  wire  g_l2_io_out_bits_exceptionVec_19, i_l2_io_out_bits_exceptionVec_19;
  wire  g_l2_io_out_bits_exceptionVec_20, i_l2_io_out_bits_exceptionVec_20;
  wire  g_l2_io_out_bits_exceptionVec_21, i_l2_io_out_bits_exceptionVec_21;
  wire  g_l2_io_out_bits_exceptionVec_22, i_l2_io_out_bits_exceptionVec_22;
  wire  g_l2_io_out_bits_exceptionVec_23, i_l2_io_out_bits_exceptionVec_23;
  wire  g_l2_io_out_bits_isFetchMalAddr, i_l2_io_out_bits_isFetchMalAddr;
  wire  g_l2_io_out_bits_hasException, i_l2_io_out_bits_hasException;
  wire  [3:0] g_l2_io_out_bits_trigger, i_l2_io_out_bits_trigger;
  wire  g_l2_io_out_bits_preDecodeInfo_valid, i_l2_io_out_bits_preDecodeInfo_valid;
  wire  g_l2_io_out_bits_preDecodeInfo_isRVC, i_l2_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l2_io_out_bits_preDecodeInfo_brType, i_l2_io_out_bits_preDecodeInfo_brType;
  wire  g_l2_io_out_bits_preDecodeInfo_isCall, i_l2_io_out_bits_preDecodeInfo_isCall;
  wire  g_l2_io_out_bits_preDecodeInfo_isRet, i_l2_io_out_bits_preDecodeInfo_isRet;
  wire  g_l2_io_out_bits_pred_taken, i_l2_io_out_bits_pred_taken;
  wire  g_l2_io_out_bits_crossPageIPFFix, i_l2_io_out_bits_crossPageIPFFix;
  wire  g_l2_io_out_bits_ftqPtr_flag, i_l2_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l2_io_out_bits_ftqPtr_value, i_l2_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l2_io_out_bits_ftqOffset, i_l2_io_out_bits_ftqOffset;
  wire  g_l2_io_out_bits_satpFlushFirstFetchFault, i_l2_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l2_io_out_bits_srcType_0, i_l2_io_out_bits_srcType_0;
  wire  [3:0] g_l2_io_out_bits_srcType_1, i_l2_io_out_bits_srcType_1;
  wire  [3:0] g_l2_io_out_bits_srcType_2, i_l2_io_out_bits_srcType_2;
  wire  [3:0] g_l2_io_out_bits_srcType_3, i_l2_io_out_bits_srcType_3;
  wire  [3:0] g_l2_io_out_bits_srcType_4, i_l2_io_out_bits_srcType_4;
  wire  [5:0] g_l2_io_out_bits_ldest, i_l2_io_out_bits_ldest;
  wire  [34:0] g_l2_io_out_bits_fuType, i_l2_io_out_bits_fuType;
  wire  [8:0] g_l2_io_out_bits_fuOpType, i_l2_io_out_bits_fuOpType;
  wire  g_l2_io_out_bits_rfWen, i_l2_io_out_bits_rfWen;
  wire  g_l2_io_out_bits_fpWen, i_l2_io_out_bits_fpWen;
  wire  g_l2_io_out_bits_vecWen, i_l2_io_out_bits_vecWen;
  wire  g_l2_io_out_bits_v0Wen, i_l2_io_out_bits_v0Wen;
  wire  g_l2_io_out_bits_vlWen, i_l2_io_out_bits_vlWen;
  wire  g_l2_io_out_bits_isXSTrap, i_l2_io_out_bits_isXSTrap;
  wire  g_l2_io_out_bits_waitForward, i_l2_io_out_bits_waitForward;
  wire  g_l2_io_out_bits_blockBackward, i_l2_io_out_bits_blockBackward;
  wire  g_l2_io_out_bits_flushPipe, i_l2_io_out_bits_flushPipe;
  wire  g_l2_io_out_bits_canRobCompress, i_l2_io_out_bits_canRobCompress;
  wire  [3:0] g_l2_io_out_bits_selImm, i_l2_io_out_bits_selImm;
  wire  [31:0] g_l2_io_out_bits_imm, i_l2_io_out_bits_imm;
  wire  [1:0] g_l2_io_out_bits_fpu_typeTagOut, i_l2_io_out_bits_fpu_typeTagOut;
  wire  g_l2_io_out_bits_fpu_wflags, i_l2_io_out_bits_fpu_wflags;
  wire  [1:0] g_l2_io_out_bits_fpu_typ, i_l2_io_out_bits_fpu_typ;
  wire  [1:0] g_l2_io_out_bits_fpu_fmt, i_l2_io_out_bits_fpu_fmt;
  wire  [2:0] g_l2_io_out_bits_fpu_rm, i_l2_io_out_bits_fpu_rm;
  wire  g_l2_io_out_bits_vpu_vill, i_l2_io_out_bits_vpu_vill;
  wire  g_l2_io_out_bits_vpu_vma, i_l2_io_out_bits_vpu_vma;
  wire  g_l2_io_out_bits_vpu_vta, i_l2_io_out_bits_vpu_vta;
  wire  [1:0] g_l2_io_out_bits_vpu_vsew, i_l2_io_out_bits_vpu_vsew;
  wire  [2:0] g_l2_io_out_bits_vpu_vlmul, i_l2_io_out_bits_vpu_vlmul;
  wire  g_l2_io_out_bits_vpu_specVill, i_l2_io_out_bits_vpu_specVill;
  wire  g_l2_io_out_bits_vpu_specVma, i_l2_io_out_bits_vpu_specVma;
  wire  g_l2_io_out_bits_vpu_specVta, i_l2_io_out_bits_vpu_specVta;
  wire  [1:0] g_l2_io_out_bits_vpu_specVsew, i_l2_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l2_io_out_bits_vpu_specVlmul, i_l2_io_out_bits_vpu_specVlmul;
  wire  g_l2_io_out_bits_vpu_vm, i_l2_io_out_bits_vpu_vm;
  wire  [7:0] g_l2_io_out_bits_vpu_vstart, i_l2_io_out_bits_vpu_vstart;
  wire  [2:0] g_l2_io_out_bits_vpu_frm, i_l2_io_out_bits_vpu_frm;
  wire  g_l2_io_out_bits_vpu_fpu_isFpToVecInst, i_l2_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l2_io_out_bits_vpu_fpu_isFP32Instr, i_l2_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l2_io_out_bits_vpu_fpu_isFP64Instr, i_l2_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l2_io_out_bits_vpu_fpu_isReduction, i_l2_io_out_bits_vpu_fpu_isReduction;
  wire  g_l2_io_out_bits_vpu_fpu_isFoldTo1_2, i_l2_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l2_io_out_bits_vpu_fpu_isFoldTo1_4, i_l2_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l2_io_out_bits_vpu_fpu_isFoldTo1_8, i_l2_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l2_io_out_bits_vpu_vxrm, i_l2_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l2_io_out_bits_vpu_vuopIdx, i_l2_io_out_bits_vpu_vuopIdx;
  wire  g_l2_io_out_bits_vpu_lastUop, i_l2_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l2_io_out_bits_vpu_vmask, i_l2_io_out_bits_vpu_vmask;
  wire  [7:0] g_l2_io_out_bits_vpu_vl, i_l2_io_out_bits_vpu_vl;
  wire  [2:0] g_l2_io_out_bits_vpu_nf, i_l2_io_out_bits_vpu_nf;
  wire  [1:0] g_l2_io_out_bits_vpu_veew, i_l2_io_out_bits_vpu_veew;
  wire  g_l2_io_out_bits_vpu_isReverse, i_l2_io_out_bits_vpu_isReverse;
  wire  g_l2_io_out_bits_vpu_isExt, i_l2_io_out_bits_vpu_isExt;
  wire  g_l2_io_out_bits_vpu_isNarrow, i_l2_io_out_bits_vpu_isNarrow;
  wire  g_l2_io_out_bits_vpu_isDstMask, i_l2_io_out_bits_vpu_isDstMask;
  wire  g_l2_io_out_bits_vpu_isOpMask, i_l2_io_out_bits_vpu_isOpMask;
  wire  g_l2_io_out_bits_vpu_isMove, i_l2_io_out_bits_vpu_isMove;
  wire  g_l2_io_out_bits_vpu_isDependOldVd, i_l2_io_out_bits_vpu_isDependOldVd;
  wire  g_l2_io_out_bits_vpu_isWritePartVd, i_l2_io_out_bits_vpu_isWritePartVd;
  wire  g_l2_io_out_bits_vpu_isVleff, i_l2_io_out_bits_vpu_isVleff;
  wire  g_l2_io_out_bits_vlsInstr, i_l2_io_out_bits_vlsInstr;
  wire  g_l2_io_out_bits_wfflags, i_l2_io_out_bits_wfflags;
  wire  g_l2_io_out_bits_isMove, i_l2_io_out_bits_isMove;
  wire  [6:0] g_l2_io_out_bits_uopIdx, i_l2_io_out_bits_uopIdx;
  wire  g_l2_io_out_bits_isVset, i_l2_io_out_bits_isVset;
  wire  g_l2_io_out_bits_firstUop, i_l2_io_out_bits_firstUop;
  wire  g_l2_io_out_bits_lastUop, i_l2_io_out_bits_lastUop;
  wire  [6:0] g_l2_io_out_bits_numUops, i_l2_io_out_bits_numUops;
  wire  [6:0] g_l2_io_out_bits_numWB, i_l2_io_out_bits_numWB;
  wire  [2:0] g_l2_io_out_bits_commitType, i_l2_io_out_bits_commitType;
  wire  [7:0] g_l2_io_out_bits_psrc_0, i_l2_io_out_bits_psrc_0;
  wire  [7:0] g_l2_io_out_bits_psrc_1, i_l2_io_out_bits_psrc_1;
  wire  [7:0] g_l2_io_out_bits_psrc_2, i_l2_io_out_bits_psrc_2;
  wire  [7:0] g_l2_io_out_bits_psrc_3, i_l2_io_out_bits_psrc_3;
  wire  [7:0] g_l2_io_out_bits_psrc_4, i_l2_io_out_bits_psrc_4;
  wire  [7:0] g_l2_io_out_bits_pdest, i_l2_io_out_bits_pdest;
  wire  g_l2_io_out_bits_robIdx_flag, i_l2_io_out_bits_robIdx_flag;
  wire  [7:0] g_l2_io_out_bits_robIdx_value, i_l2_io_out_bits_robIdx_value;
  wire  [2:0] g_l2_io_out_bits_instrSize, i_l2_io_out_bits_instrSize;
  wire  g_l2_io_out_bits_dirtyFs, i_l2_io_out_bits_dirtyFs;
  wire  g_l2_io_out_bits_dirtyVs, i_l2_io_out_bits_dirtyVs;
  wire  [3:0] g_l2_io_out_bits_traceBlockInPipe_itype, i_l2_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l2_io_out_bits_traceBlockInPipe_iretire, i_l2_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l2_io_out_bits_traceBlockInPipe_ilastsize, i_l2_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l2_io_out_bits_eliminatedMove, i_l2_io_out_bits_eliminatedMove;
  wire  [63:0] g_l2_io_out_bits_debugInfo_renameTime, i_l2_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l2_io_out_bits_debug_seqNum_seqNum, i_l2_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l2_io_out_bits_debug_seqNum_uopIdx, i_l2_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l2_io_out_bits_debug_fuType, i_l2_io_out_bits_debug_fuType;
  wire  g_l2_io_out_bits_debug_sim_trig, i_l2_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l2_io_out_bits_numLsElem, i_l2_io_out_bits_numLsElem;
  wire  g_l3_io_in_ready, i_l3_io_in_ready, g_l3_io_out_valid, i_l3_io_out_valid;
  wire  [31:0] g_l3_io_out_bits_instr, i_l3_io_out_bits_instr;
  wire  [49:0] g_l3_io_out_bits_pc, i_l3_io_out_bits_pc;
  wire  [9:0] g_l3_io_out_bits_foldpc, i_l3_io_out_bits_foldpc;
  wire  g_l3_io_out_bits_exceptionVec_0, i_l3_io_out_bits_exceptionVec_0;
  wire  g_l3_io_out_bits_exceptionVec_1, i_l3_io_out_bits_exceptionVec_1;
  wire  g_l3_io_out_bits_exceptionVec_2, i_l3_io_out_bits_exceptionVec_2;
  wire  g_l3_io_out_bits_exceptionVec_3, i_l3_io_out_bits_exceptionVec_3;
  wire  g_l3_io_out_bits_exceptionVec_4, i_l3_io_out_bits_exceptionVec_4;
  wire  g_l3_io_out_bits_exceptionVec_5, i_l3_io_out_bits_exceptionVec_5;
  wire  g_l3_io_out_bits_exceptionVec_6, i_l3_io_out_bits_exceptionVec_6;
  wire  g_l3_io_out_bits_exceptionVec_7, i_l3_io_out_bits_exceptionVec_7;
  wire  g_l3_io_out_bits_exceptionVec_8, i_l3_io_out_bits_exceptionVec_8;
  wire  g_l3_io_out_bits_exceptionVec_9, i_l3_io_out_bits_exceptionVec_9;
  wire  g_l3_io_out_bits_exceptionVec_10, i_l3_io_out_bits_exceptionVec_10;
  wire  g_l3_io_out_bits_exceptionVec_11, i_l3_io_out_bits_exceptionVec_11;
  wire  g_l3_io_out_bits_exceptionVec_12, i_l3_io_out_bits_exceptionVec_12;
  wire  g_l3_io_out_bits_exceptionVec_13, i_l3_io_out_bits_exceptionVec_13;
  wire  g_l3_io_out_bits_exceptionVec_14, i_l3_io_out_bits_exceptionVec_14;
  wire  g_l3_io_out_bits_exceptionVec_15, i_l3_io_out_bits_exceptionVec_15;
  wire  g_l3_io_out_bits_exceptionVec_16, i_l3_io_out_bits_exceptionVec_16;
  wire  g_l3_io_out_bits_exceptionVec_17, i_l3_io_out_bits_exceptionVec_17;
  wire  g_l3_io_out_bits_exceptionVec_18, i_l3_io_out_bits_exceptionVec_18;
  wire  g_l3_io_out_bits_exceptionVec_19, i_l3_io_out_bits_exceptionVec_19;
  wire  g_l3_io_out_bits_exceptionVec_20, i_l3_io_out_bits_exceptionVec_20;
  wire  g_l3_io_out_bits_exceptionVec_21, i_l3_io_out_bits_exceptionVec_21;
  wire  g_l3_io_out_bits_exceptionVec_22, i_l3_io_out_bits_exceptionVec_22;
  wire  g_l3_io_out_bits_exceptionVec_23, i_l3_io_out_bits_exceptionVec_23;
  wire  g_l3_io_out_bits_isFetchMalAddr, i_l3_io_out_bits_isFetchMalAddr;
  wire  g_l3_io_out_bits_hasException, i_l3_io_out_bits_hasException;
  wire  [3:0] g_l3_io_out_bits_trigger, i_l3_io_out_bits_trigger;
  wire  g_l3_io_out_bits_preDecodeInfo_valid, i_l3_io_out_bits_preDecodeInfo_valid;
  wire  g_l3_io_out_bits_preDecodeInfo_isRVC, i_l3_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l3_io_out_bits_preDecodeInfo_brType, i_l3_io_out_bits_preDecodeInfo_brType;
  wire  g_l3_io_out_bits_preDecodeInfo_isCall, i_l3_io_out_bits_preDecodeInfo_isCall;
  wire  g_l3_io_out_bits_preDecodeInfo_isRet, i_l3_io_out_bits_preDecodeInfo_isRet;
  wire  g_l3_io_out_bits_pred_taken, i_l3_io_out_bits_pred_taken;
  wire  g_l3_io_out_bits_crossPageIPFFix, i_l3_io_out_bits_crossPageIPFFix;
  wire  g_l3_io_out_bits_ftqPtr_flag, i_l3_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l3_io_out_bits_ftqPtr_value, i_l3_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l3_io_out_bits_ftqOffset, i_l3_io_out_bits_ftqOffset;
  wire  g_l3_io_out_bits_satpFlushFirstFetchFault, i_l3_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l3_io_out_bits_srcType_0, i_l3_io_out_bits_srcType_0;
  wire  [3:0] g_l3_io_out_bits_srcType_1, i_l3_io_out_bits_srcType_1;
  wire  [3:0] g_l3_io_out_bits_srcType_2, i_l3_io_out_bits_srcType_2;
  wire  [3:0] g_l3_io_out_bits_srcType_3, i_l3_io_out_bits_srcType_3;
  wire  [3:0] g_l3_io_out_bits_srcType_4, i_l3_io_out_bits_srcType_4;
  wire  [5:0] g_l3_io_out_bits_ldest, i_l3_io_out_bits_ldest;
  wire  [34:0] g_l3_io_out_bits_fuType, i_l3_io_out_bits_fuType;
  wire  [8:0] g_l3_io_out_bits_fuOpType, i_l3_io_out_bits_fuOpType;
  wire  g_l3_io_out_bits_rfWen, i_l3_io_out_bits_rfWen;
  wire  g_l3_io_out_bits_fpWen, i_l3_io_out_bits_fpWen;
  wire  g_l3_io_out_bits_vecWen, i_l3_io_out_bits_vecWen;
  wire  g_l3_io_out_bits_v0Wen, i_l3_io_out_bits_v0Wen;
  wire  g_l3_io_out_bits_vlWen, i_l3_io_out_bits_vlWen;
  wire  g_l3_io_out_bits_isXSTrap, i_l3_io_out_bits_isXSTrap;
  wire  g_l3_io_out_bits_waitForward, i_l3_io_out_bits_waitForward;
  wire  g_l3_io_out_bits_blockBackward, i_l3_io_out_bits_blockBackward;
  wire  g_l3_io_out_bits_flushPipe, i_l3_io_out_bits_flushPipe;
  wire  g_l3_io_out_bits_canRobCompress, i_l3_io_out_bits_canRobCompress;
  wire  [3:0] g_l3_io_out_bits_selImm, i_l3_io_out_bits_selImm;
  wire  [31:0] g_l3_io_out_bits_imm, i_l3_io_out_bits_imm;
  wire  [1:0] g_l3_io_out_bits_fpu_typeTagOut, i_l3_io_out_bits_fpu_typeTagOut;
  wire  g_l3_io_out_bits_fpu_wflags, i_l3_io_out_bits_fpu_wflags;
  wire  [1:0] g_l3_io_out_bits_fpu_typ, i_l3_io_out_bits_fpu_typ;
  wire  [1:0] g_l3_io_out_bits_fpu_fmt, i_l3_io_out_bits_fpu_fmt;
  wire  [2:0] g_l3_io_out_bits_fpu_rm, i_l3_io_out_bits_fpu_rm;
  wire  g_l3_io_out_bits_vpu_vill, i_l3_io_out_bits_vpu_vill;
  wire  g_l3_io_out_bits_vpu_vma, i_l3_io_out_bits_vpu_vma;
  wire  g_l3_io_out_bits_vpu_vta, i_l3_io_out_bits_vpu_vta;
  wire  [1:0] g_l3_io_out_bits_vpu_vsew, i_l3_io_out_bits_vpu_vsew;
  wire  [2:0] g_l3_io_out_bits_vpu_vlmul, i_l3_io_out_bits_vpu_vlmul;
  wire  g_l3_io_out_bits_vpu_specVill, i_l3_io_out_bits_vpu_specVill;
  wire  g_l3_io_out_bits_vpu_specVma, i_l3_io_out_bits_vpu_specVma;
  wire  g_l3_io_out_bits_vpu_specVta, i_l3_io_out_bits_vpu_specVta;
  wire  [1:0] g_l3_io_out_bits_vpu_specVsew, i_l3_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l3_io_out_bits_vpu_specVlmul, i_l3_io_out_bits_vpu_specVlmul;
  wire  g_l3_io_out_bits_vpu_vm, i_l3_io_out_bits_vpu_vm;
  wire  [7:0] g_l3_io_out_bits_vpu_vstart, i_l3_io_out_bits_vpu_vstart;
  wire  [2:0] g_l3_io_out_bits_vpu_frm, i_l3_io_out_bits_vpu_frm;
  wire  g_l3_io_out_bits_vpu_fpu_isFpToVecInst, i_l3_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l3_io_out_bits_vpu_fpu_isFP32Instr, i_l3_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l3_io_out_bits_vpu_fpu_isFP64Instr, i_l3_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l3_io_out_bits_vpu_fpu_isReduction, i_l3_io_out_bits_vpu_fpu_isReduction;
  wire  g_l3_io_out_bits_vpu_fpu_isFoldTo1_2, i_l3_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l3_io_out_bits_vpu_fpu_isFoldTo1_4, i_l3_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l3_io_out_bits_vpu_fpu_isFoldTo1_8, i_l3_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l3_io_out_bits_vpu_vxrm, i_l3_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l3_io_out_bits_vpu_vuopIdx, i_l3_io_out_bits_vpu_vuopIdx;
  wire  g_l3_io_out_bits_vpu_lastUop, i_l3_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l3_io_out_bits_vpu_vmask, i_l3_io_out_bits_vpu_vmask;
  wire  [7:0] g_l3_io_out_bits_vpu_vl, i_l3_io_out_bits_vpu_vl;
  wire  [2:0] g_l3_io_out_bits_vpu_nf, i_l3_io_out_bits_vpu_nf;
  wire  [1:0] g_l3_io_out_bits_vpu_veew, i_l3_io_out_bits_vpu_veew;
  wire  g_l3_io_out_bits_vpu_isReverse, i_l3_io_out_bits_vpu_isReverse;
  wire  g_l3_io_out_bits_vpu_isExt, i_l3_io_out_bits_vpu_isExt;
  wire  g_l3_io_out_bits_vpu_isNarrow, i_l3_io_out_bits_vpu_isNarrow;
  wire  g_l3_io_out_bits_vpu_isDstMask, i_l3_io_out_bits_vpu_isDstMask;
  wire  g_l3_io_out_bits_vpu_isOpMask, i_l3_io_out_bits_vpu_isOpMask;
  wire  g_l3_io_out_bits_vpu_isMove, i_l3_io_out_bits_vpu_isMove;
  wire  g_l3_io_out_bits_vpu_isDependOldVd, i_l3_io_out_bits_vpu_isDependOldVd;
  wire  g_l3_io_out_bits_vpu_isWritePartVd, i_l3_io_out_bits_vpu_isWritePartVd;
  wire  g_l3_io_out_bits_vpu_isVleff, i_l3_io_out_bits_vpu_isVleff;
  wire  g_l3_io_out_bits_vlsInstr, i_l3_io_out_bits_vlsInstr;
  wire  g_l3_io_out_bits_wfflags, i_l3_io_out_bits_wfflags;
  wire  g_l3_io_out_bits_isMove, i_l3_io_out_bits_isMove;
  wire  [6:0] g_l3_io_out_bits_uopIdx, i_l3_io_out_bits_uopIdx;
  wire  g_l3_io_out_bits_isVset, i_l3_io_out_bits_isVset;
  wire  g_l3_io_out_bits_firstUop, i_l3_io_out_bits_firstUop;
  wire  g_l3_io_out_bits_lastUop, i_l3_io_out_bits_lastUop;
  wire  [6:0] g_l3_io_out_bits_numUops, i_l3_io_out_bits_numUops;
  wire  [6:0] g_l3_io_out_bits_numWB, i_l3_io_out_bits_numWB;
  wire  [2:0] g_l3_io_out_bits_commitType, i_l3_io_out_bits_commitType;
  wire  [7:0] g_l3_io_out_bits_psrc_0, i_l3_io_out_bits_psrc_0;
  wire  [7:0] g_l3_io_out_bits_psrc_1, i_l3_io_out_bits_psrc_1;
  wire  [7:0] g_l3_io_out_bits_psrc_2, i_l3_io_out_bits_psrc_2;
  wire  [7:0] g_l3_io_out_bits_psrc_3, i_l3_io_out_bits_psrc_3;
  wire  [7:0] g_l3_io_out_bits_psrc_4, i_l3_io_out_bits_psrc_4;
  wire  [7:0] g_l3_io_out_bits_pdest, i_l3_io_out_bits_pdest;
  wire  g_l3_io_out_bits_robIdx_flag, i_l3_io_out_bits_robIdx_flag;
  wire  [7:0] g_l3_io_out_bits_robIdx_value, i_l3_io_out_bits_robIdx_value;
  wire  [2:0] g_l3_io_out_bits_instrSize, i_l3_io_out_bits_instrSize;
  wire  g_l3_io_out_bits_dirtyFs, i_l3_io_out_bits_dirtyFs;
  wire  g_l3_io_out_bits_dirtyVs, i_l3_io_out_bits_dirtyVs;
  wire  [3:0] g_l3_io_out_bits_traceBlockInPipe_itype, i_l3_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l3_io_out_bits_traceBlockInPipe_iretire, i_l3_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l3_io_out_bits_traceBlockInPipe_ilastsize, i_l3_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l3_io_out_bits_eliminatedMove, i_l3_io_out_bits_eliminatedMove;
  wire  [63:0] g_l3_io_out_bits_debugInfo_renameTime, i_l3_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l3_io_out_bits_debug_seqNum_seqNum, i_l3_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l3_io_out_bits_debug_seqNum_uopIdx, i_l3_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l3_io_out_bits_debug_fuType, i_l3_io_out_bits_debug_fuType;
  wire  g_l3_io_out_bits_debug_sim_trig, i_l3_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l3_io_out_bits_numLsElem, i_l3_io_out_bits_numLsElem;
  wire  g_l4_io_in_ready, i_l4_io_in_ready, g_l4_io_out_valid, i_l4_io_out_valid;
  wire  [31:0] g_l4_io_out_bits_instr, i_l4_io_out_bits_instr;
  wire  [49:0] g_l4_io_out_bits_pc, i_l4_io_out_bits_pc;
  wire  [9:0] g_l4_io_out_bits_foldpc, i_l4_io_out_bits_foldpc;
  wire  g_l4_io_out_bits_exceptionVec_0, i_l4_io_out_bits_exceptionVec_0;
  wire  g_l4_io_out_bits_exceptionVec_1, i_l4_io_out_bits_exceptionVec_1;
  wire  g_l4_io_out_bits_exceptionVec_2, i_l4_io_out_bits_exceptionVec_2;
  wire  g_l4_io_out_bits_exceptionVec_3, i_l4_io_out_bits_exceptionVec_3;
  wire  g_l4_io_out_bits_exceptionVec_4, i_l4_io_out_bits_exceptionVec_4;
  wire  g_l4_io_out_bits_exceptionVec_5, i_l4_io_out_bits_exceptionVec_5;
  wire  g_l4_io_out_bits_exceptionVec_6, i_l4_io_out_bits_exceptionVec_6;
  wire  g_l4_io_out_bits_exceptionVec_7, i_l4_io_out_bits_exceptionVec_7;
  wire  g_l4_io_out_bits_exceptionVec_8, i_l4_io_out_bits_exceptionVec_8;
  wire  g_l4_io_out_bits_exceptionVec_9, i_l4_io_out_bits_exceptionVec_9;
  wire  g_l4_io_out_bits_exceptionVec_10, i_l4_io_out_bits_exceptionVec_10;
  wire  g_l4_io_out_bits_exceptionVec_11, i_l4_io_out_bits_exceptionVec_11;
  wire  g_l4_io_out_bits_exceptionVec_12, i_l4_io_out_bits_exceptionVec_12;
  wire  g_l4_io_out_bits_exceptionVec_13, i_l4_io_out_bits_exceptionVec_13;
  wire  g_l4_io_out_bits_exceptionVec_14, i_l4_io_out_bits_exceptionVec_14;
  wire  g_l4_io_out_bits_exceptionVec_15, i_l4_io_out_bits_exceptionVec_15;
  wire  g_l4_io_out_bits_exceptionVec_16, i_l4_io_out_bits_exceptionVec_16;
  wire  g_l4_io_out_bits_exceptionVec_17, i_l4_io_out_bits_exceptionVec_17;
  wire  g_l4_io_out_bits_exceptionVec_18, i_l4_io_out_bits_exceptionVec_18;
  wire  g_l4_io_out_bits_exceptionVec_19, i_l4_io_out_bits_exceptionVec_19;
  wire  g_l4_io_out_bits_exceptionVec_20, i_l4_io_out_bits_exceptionVec_20;
  wire  g_l4_io_out_bits_exceptionVec_21, i_l4_io_out_bits_exceptionVec_21;
  wire  g_l4_io_out_bits_exceptionVec_22, i_l4_io_out_bits_exceptionVec_22;
  wire  g_l4_io_out_bits_exceptionVec_23, i_l4_io_out_bits_exceptionVec_23;
  wire  g_l4_io_out_bits_isFetchMalAddr, i_l4_io_out_bits_isFetchMalAddr;
  wire  g_l4_io_out_bits_hasException, i_l4_io_out_bits_hasException;
  wire  [3:0] g_l4_io_out_bits_trigger, i_l4_io_out_bits_trigger;
  wire  g_l4_io_out_bits_preDecodeInfo_valid, i_l4_io_out_bits_preDecodeInfo_valid;
  wire  g_l4_io_out_bits_preDecodeInfo_isRVC, i_l4_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l4_io_out_bits_preDecodeInfo_brType, i_l4_io_out_bits_preDecodeInfo_brType;
  wire  g_l4_io_out_bits_preDecodeInfo_isCall, i_l4_io_out_bits_preDecodeInfo_isCall;
  wire  g_l4_io_out_bits_preDecodeInfo_isRet, i_l4_io_out_bits_preDecodeInfo_isRet;
  wire  g_l4_io_out_bits_pred_taken, i_l4_io_out_bits_pred_taken;
  wire  g_l4_io_out_bits_crossPageIPFFix, i_l4_io_out_bits_crossPageIPFFix;
  wire  g_l4_io_out_bits_ftqPtr_flag, i_l4_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l4_io_out_bits_ftqPtr_value, i_l4_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l4_io_out_bits_ftqOffset, i_l4_io_out_bits_ftqOffset;
  wire  g_l4_io_out_bits_satpFlushFirstFetchFault, i_l4_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l4_io_out_bits_srcType_0, i_l4_io_out_bits_srcType_0;
  wire  [3:0] g_l4_io_out_bits_srcType_1, i_l4_io_out_bits_srcType_1;
  wire  [3:0] g_l4_io_out_bits_srcType_2, i_l4_io_out_bits_srcType_2;
  wire  [3:0] g_l4_io_out_bits_srcType_3, i_l4_io_out_bits_srcType_3;
  wire  [3:0] g_l4_io_out_bits_srcType_4, i_l4_io_out_bits_srcType_4;
  wire  [5:0] g_l4_io_out_bits_ldest, i_l4_io_out_bits_ldest;
  wire  [34:0] g_l4_io_out_bits_fuType, i_l4_io_out_bits_fuType;
  wire  [8:0] g_l4_io_out_bits_fuOpType, i_l4_io_out_bits_fuOpType;
  wire  g_l4_io_out_bits_rfWen, i_l4_io_out_bits_rfWen;
  wire  g_l4_io_out_bits_fpWen, i_l4_io_out_bits_fpWen;
  wire  g_l4_io_out_bits_vecWen, i_l4_io_out_bits_vecWen;
  wire  g_l4_io_out_bits_v0Wen, i_l4_io_out_bits_v0Wen;
  wire  g_l4_io_out_bits_vlWen, i_l4_io_out_bits_vlWen;
  wire  g_l4_io_out_bits_isXSTrap, i_l4_io_out_bits_isXSTrap;
  wire  g_l4_io_out_bits_waitForward, i_l4_io_out_bits_waitForward;
  wire  g_l4_io_out_bits_blockBackward, i_l4_io_out_bits_blockBackward;
  wire  g_l4_io_out_bits_flushPipe, i_l4_io_out_bits_flushPipe;
  wire  g_l4_io_out_bits_canRobCompress, i_l4_io_out_bits_canRobCompress;
  wire  [3:0] g_l4_io_out_bits_selImm, i_l4_io_out_bits_selImm;
  wire  [31:0] g_l4_io_out_bits_imm, i_l4_io_out_bits_imm;
  wire  [1:0] g_l4_io_out_bits_fpu_typeTagOut, i_l4_io_out_bits_fpu_typeTagOut;
  wire  g_l4_io_out_bits_fpu_wflags, i_l4_io_out_bits_fpu_wflags;
  wire  [1:0] g_l4_io_out_bits_fpu_typ, i_l4_io_out_bits_fpu_typ;
  wire  [1:0] g_l4_io_out_bits_fpu_fmt, i_l4_io_out_bits_fpu_fmt;
  wire  [2:0] g_l4_io_out_bits_fpu_rm, i_l4_io_out_bits_fpu_rm;
  wire  g_l4_io_out_bits_vpu_vill, i_l4_io_out_bits_vpu_vill;
  wire  g_l4_io_out_bits_vpu_vma, i_l4_io_out_bits_vpu_vma;
  wire  g_l4_io_out_bits_vpu_vta, i_l4_io_out_bits_vpu_vta;
  wire  [1:0] g_l4_io_out_bits_vpu_vsew, i_l4_io_out_bits_vpu_vsew;
  wire  [2:0] g_l4_io_out_bits_vpu_vlmul, i_l4_io_out_bits_vpu_vlmul;
  wire  g_l4_io_out_bits_vpu_specVill, i_l4_io_out_bits_vpu_specVill;
  wire  g_l4_io_out_bits_vpu_specVma, i_l4_io_out_bits_vpu_specVma;
  wire  g_l4_io_out_bits_vpu_specVta, i_l4_io_out_bits_vpu_specVta;
  wire  [1:0] g_l4_io_out_bits_vpu_specVsew, i_l4_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l4_io_out_bits_vpu_specVlmul, i_l4_io_out_bits_vpu_specVlmul;
  wire  g_l4_io_out_bits_vpu_vm, i_l4_io_out_bits_vpu_vm;
  wire  [7:0] g_l4_io_out_bits_vpu_vstart, i_l4_io_out_bits_vpu_vstart;
  wire  [2:0] g_l4_io_out_bits_vpu_frm, i_l4_io_out_bits_vpu_frm;
  wire  g_l4_io_out_bits_vpu_fpu_isFpToVecInst, i_l4_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l4_io_out_bits_vpu_fpu_isFP32Instr, i_l4_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l4_io_out_bits_vpu_fpu_isFP64Instr, i_l4_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l4_io_out_bits_vpu_fpu_isReduction, i_l4_io_out_bits_vpu_fpu_isReduction;
  wire  g_l4_io_out_bits_vpu_fpu_isFoldTo1_2, i_l4_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l4_io_out_bits_vpu_fpu_isFoldTo1_4, i_l4_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l4_io_out_bits_vpu_fpu_isFoldTo1_8, i_l4_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l4_io_out_bits_vpu_vxrm, i_l4_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l4_io_out_bits_vpu_vuopIdx, i_l4_io_out_bits_vpu_vuopIdx;
  wire  g_l4_io_out_bits_vpu_lastUop, i_l4_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l4_io_out_bits_vpu_vmask, i_l4_io_out_bits_vpu_vmask;
  wire  [7:0] g_l4_io_out_bits_vpu_vl, i_l4_io_out_bits_vpu_vl;
  wire  [2:0] g_l4_io_out_bits_vpu_nf, i_l4_io_out_bits_vpu_nf;
  wire  [1:0] g_l4_io_out_bits_vpu_veew, i_l4_io_out_bits_vpu_veew;
  wire  g_l4_io_out_bits_vpu_isReverse, i_l4_io_out_bits_vpu_isReverse;
  wire  g_l4_io_out_bits_vpu_isExt, i_l4_io_out_bits_vpu_isExt;
  wire  g_l4_io_out_bits_vpu_isNarrow, i_l4_io_out_bits_vpu_isNarrow;
  wire  g_l4_io_out_bits_vpu_isDstMask, i_l4_io_out_bits_vpu_isDstMask;
  wire  g_l4_io_out_bits_vpu_isOpMask, i_l4_io_out_bits_vpu_isOpMask;
  wire  g_l4_io_out_bits_vpu_isMove, i_l4_io_out_bits_vpu_isMove;
  wire  g_l4_io_out_bits_vpu_isDependOldVd, i_l4_io_out_bits_vpu_isDependOldVd;
  wire  g_l4_io_out_bits_vpu_isWritePartVd, i_l4_io_out_bits_vpu_isWritePartVd;
  wire  g_l4_io_out_bits_vpu_isVleff, i_l4_io_out_bits_vpu_isVleff;
  wire  g_l4_io_out_bits_vlsInstr, i_l4_io_out_bits_vlsInstr;
  wire  g_l4_io_out_bits_wfflags, i_l4_io_out_bits_wfflags;
  wire  g_l4_io_out_bits_isMove, i_l4_io_out_bits_isMove;
  wire  [6:0] g_l4_io_out_bits_uopIdx, i_l4_io_out_bits_uopIdx;
  wire  g_l4_io_out_bits_isVset, i_l4_io_out_bits_isVset;
  wire  g_l4_io_out_bits_firstUop, i_l4_io_out_bits_firstUop;
  wire  g_l4_io_out_bits_lastUop, i_l4_io_out_bits_lastUop;
  wire  [6:0] g_l4_io_out_bits_numUops, i_l4_io_out_bits_numUops;
  wire  [6:0] g_l4_io_out_bits_numWB, i_l4_io_out_bits_numWB;
  wire  [2:0] g_l4_io_out_bits_commitType, i_l4_io_out_bits_commitType;
  wire  [7:0] g_l4_io_out_bits_psrc_0, i_l4_io_out_bits_psrc_0;
  wire  [7:0] g_l4_io_out_bits_psrc_1, i_l4_io_out_bits_psrc_1;
  wire  [7:0] g_l4_io_out_bits_psrc_2, i_l4_io_out_bits_psrc_2;
  wire  [7:0] g_l4_io_out_bits_psrc_3, i_l4_io_out_bits_psrc_3;
  wire  [7:0] g_l4_io_out_bits_psrc_4, i_l4_io_out_bits_psrc_4;
  wire  [7:0] g_l4_io_out_bits_pdest, i_l4_io_out_bits_pdest;
  wire  g_l4_io_out_bits_robIdx_flag, i_l4_io_out_bits_robIdx_flag;
  wire  [7:0] g_l4_io_out_bits_robIdx_value, i_l4_io_out_bits_robIdx_value;
  wire  [2:0] g_l4_io_out_bits_instrSize, i_l4_io_out_bits_instrSize;
  wire  g_l4_io_out_bits_dirtyFs, i_l4_io_out_bits_dirtyFs;
  wire  g_l4_io_out_bits_dirtyVs, i_l4_io_out_bits_dirtyVs;
  wire  [3:0] g_l4_io_out_bits_traceBlockInPipe_itype, i_l4_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l4_io_out_bits_traceBlockInPipe_iretire, i_l4_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l4_io_out_bits_traceBlockInPipe_ilastsize, i_l4_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l4_io_out_bits_eliminatedMove, i_l4_io_out_bits_eliminatedMove;
  wire  [63:0] g_l4_io_out_bits_debugInfo_renameTime, i_l4_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l4_io_out_bits_debug_seqNum_seqNum, i_l4_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l4_io_out_bits_debug_seqNum_uopIdx, i_l4_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l4_io_out_bits_debug_fuType, i_l4_io_out_bits_debug_fuType;
  wire  g_l4_io_out_bits_debug_sim_trig, i_l4_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l4_io_out_bits_numLsElem, i_l4_io_out_bits_numLsElem;
  wire  g_l5_io_in_ready, i_l5_io_in_ready, g_l5_io_out_valid, i_l5_io_out_valid;
  wire  [31:0] g_l5_io_out_bits_instr, i_l5_io_out_bits_instr;
  wire  [49:0] g_l5_io_out_bits_pc, i_l5_io_out_bits_pc;
  wire  [9:0] g_l5_io_out_bits_foldpc, i_l5_io_out_bits_foldpc;
  wire  g_l5_io_out_bits_exceptionVec_0, i_l5_io_out_bits_exceptionVec_0;
  wire  g_l5_io_out_bits_exceptionVec_1, i_l5_io_out_bits_exceptionVec_1;
  wire  g_l5_io_out_bits_exceptionVec_2, i_l5_io_out_bits_exceptionVec_2;
  wire  g_l5_io_out_bits_exceptionVec_3, i_l5_io_out_bits_exceptionVec_3;
  wire  g_l5_io_out_bits_exceptionVec_4, i_l5_io_out_bits_exceptionVec_4;
  wire  g_l5_io_out_bits_exceptionVec_5, i_l5_io_out_bits_exceptionVec_5;
  wire  g_l5_io_out_bits_exceptionVec_6, i_l5_io_out_bits_exceptionVec_6;
  wire  g_l5_io_out_bits_exceptionVec_7, i_l5_io_out_bits_exceptionVec_7;
  wire  g_l5_io_out_bits_exceptionVec_8, i_l5_io_out_bits_exceptionVec_8;
  wire  g_l5_io_out_bits_exceptionVec_9, i_l5_io_out_bits_exceptionVec_9;
  wire  g_l5_io_out_bits_exceptionVec_10, i_l5_io_out_bits_exceptionVec_10;
  wire  g_l5_io_out_bits_exceptionVec_11, i_l5_io_out_bits_exceptionVec_11;
  wire  g_l5_io_out_bits_exceptionVec_12, i_l5_io_out_bits_exceptionVec_12;
  wire  g_l5_io_out_bits_exceptionVec_13, i_l5_io_out_bits_exceptionVec_13;
  wire  g_l5_io_out_bits_exceptionVec_14, i_l5_io_out_bits_exceptionVec_14;
  wire  g_l5_io_out_bits_exceptionVec_15, i_l5_io_out_bits_exceptionVec_15;
  wire  g_l5_io_out_bits_exceptionVec_16, i_l5_io_out_bits_exceptionVec_16;
  wire  g_l5_io_out_bits_exceptionVec_17, i_l5_io_out_bits_exceptionVec_17;
  wire  g_l5_io_out_bits_exceptionVec_18, i_l5_io_out_bits_exceptionVec_18;
  wire  g_l5_io_out_bits_exceptionVec_19, i_l5_io_out_bits_exceptionVec_19;
  wire  g_l5_io_out_bits_exceptionVec_20, i_l5_io_out_bits_exceptionVec_20;
  wire  g_l5_io_out_bits_exceptionVec_21, i_l5_io_out_bits_exceptionVec_21;
  wire  g_l5_io_out_bits_exceptionVec_22, i_l5_io_out_bits_exceptionVec_22;
  wire  g_l5_io_out_bits_exceptionVec_23, i_l5_io_out_bits_exceptionVec_23;
  wire  g_l5_io_out_bits_isFetchMalAddr, i_l5_io_out_bits_isFetchMalAddr;
  wire  g_l5_io_out_bits_hasException, i_l5_io_out_bits_hasException;
  wire  [3:0] g_l5_io_out_bits_trigger, i_l5_io_out_bits_trigger;
  wire  g_l5_io_out_bits_preDecodeInfo_valid, i_l5_io_out_bits_preDecodeInfo_valid;
  wire  g_l5_io_out_bits_preDecodeInfo_isRVC, i_l5_io_out_bits_preDecodeInfo_isRVC;
  wire  [1:0] g_l5_io_out_bits_preDecodeInfo_brType, i_l5_io_out_bits_preDecodeInfo_brType;
  wire  g_l5_io_out_bits_preDecodeInfo_isCall, i_l5_io_out_bits_preDecodeInfo_isCall;
  wire  g_l5_io_out_bits_preDecodeInfo_isRet, i_l5_io_out_bits_preDecodeInfo_isRet;
  wire  g_l5_io_out_bits_pred_taken, i_l5_io_out_bits_pred_taken;
  wire  g_l5_io_out_bits_crossPageIPFFix, i_l5_io_out_bits_crossPageIPFFix;
  wire  g_l5_io_out_bits_ftqPtr_flag, i_l5_io_out_bits_ftqPtr_flag;
  wire  [5:0] g_l5_io_out_bits_ftqPtr_value, i_l5_io_out_bits_ftqPtr_value;
  wire  [3:0] g_l5_io_out_bits_ftqOffset, i_l5_io_out_bits_ftqOffset;
  wire  g_l5_io_out_bits_satpFlushFirstFetchFault, i_l5_io_out_bits_satpFlushFirstFetchFault;
  wire  [3:0] g_l5_io_out_bits_srcType_0, i_l5_io_out_bits_srcType_0;
  wire  [3:0] g_l5_io_out_bits_srcType_1, i_l5_io_out_bits_srcType_1;
  wire  [3:0] g_l5_io_out_bits_srcType_2, i_l5_io_out_bits_srcType_2;
  wire  [3:0] g_l5_io_out_bits_srcType_3, i_l5_io_out_bits_srcType_3;
  wire  [3:0] g_l5_io_out_bits_srcType_4, i_l5_io_out_bits_srcType_4;
  wire  [5:0] g_l5_io_out_bits_ldest, i_l5_io_out_bits_ldest;
  wire  [34:0] g_l5_io_out_bits_fuType, i_l5_io_out_bits_fuType;
  wire  [8:0] g_l5_io_out_bits_fuOpType, i_l5_io_out_bits_fuOpType;
  wire  g_l5_io_out_bits_rfWen, i_l5_io_out_bits_rfWen;
  wire  g_l5_io_out_bits_fpWen, i_l5_io_out_bits_fpWen;
  wire  g_l5_io_out_bits_vecWen, i_l5_io_out_bits_vecWen;
  wire  g_l5_io_out_bits_v0Wen, i_l5_io_out_bits_v0Wen;
  wire  g_l5_io_out_bits_vlWen, i_l5_io_out_bits_vlWen;
  wire  g_l5_io_out_bits_isXSTrap, i_l5_io_out_bits_isXSTrap;
  wire  g_l5_io_out_bits_waitForward, i_l5_io_out_bits_waitForward;
  wire  g_l5_io_out_bits_blockBackward, i_l5_io_out_bits_blockBackward;
  wire  g_l5_io_out_bits_flushPipe, i_l5_io_out_bits_flushPipe;
  wire  g_l5_io_out_bits_canRobCompress, i_l5_io_out_bits_canRobCompress;
  wire  [3:0] g_l5_io_out_bits_selImm, i_l5_io_out_bits_selImm;
  wire  [31:0] g_l5_io_out_bits_imm, i_l5_io_out_bits_imm;
  wire  [1:0] g_l5_io_out_bits_fpu_typeTagOut, i_l5_io_out_bits_fpu_typeTagOut;
  wire  g_l5_io_out_bits_fpu_wflags, i_l5_io_out_bits_fpu_wflags;
  wire  [1:0] g_l5_io_out_bits_fpu_typ, i_l5_io_out_bits_fpu_typ;
  wire  [1:0] g_l5_io_out_bits_fpu_fmt, i_l5_io_out_bits_fpu_fmt;
  wire  [2:0] g_l5_io_out_bits_fpu_rm, i_l5_io_out_bits_fpu_rm;
  wire  g_l5_io_out_bits_vpu_vill, i_l5_io_out_bits_vpu_vill;
  wire  g_l5_io_out_bits_vpu_vma, i_l5_io_out_bits_vpu_vma;
  wire  g_l5_io_out_bits_vpu_vta, i_l5_io_out_bits_vpu_vta;
  wire  [1:0] g_l5_io_out_bits_vpu_vsew, i_l5_io_out_bits_vpu_vsew;
  wire  [2:0] g_l5_io_out_bits_vpu_vlmul, i_l5_io_out_bits_vpu_vlmul;
  wire  g_l5_io_out_bits_vpu_specVill, i_l5_io_out_bits_vpu_specVill;
  wire  g_l5_io_out_bits_vpu_specVma, i_l5_io_out_bits_vpu_specVma;
  wire  g_l5_io_out_bits_vpu_specVta, i_l5_io_out_bits_vpu_specVta;
  wire  [1:0] g_l5_io_out_bits_vpu_specVsew, i_l5_io_out_bits_vpu_specVsew;
  wire  [2:0] g_l5_io_out_bits_vpu_specVlmul, i_l5_io_out_bits_vpu_specVlmul;
  wire  g_l5_io_out_bits_vpu_vm, i_l5_io_out_bits_vpu_vm;
  wire  [7:0] g_l5_io_out_bits_vpu_vstart, i_l5_io_out_bits_vpu_vstart;
  wire  [2:0] g_l5_io_out_bits_vpu_frm, i_l5_io_out_bits_vpu_frm;
  wire  g_l5_io_out_bits_vpu_fpu_isFpToVecInst, i_l5_io_out_bits_vpu_fpu_isFpToVecInst;
  wire  g_l5_io_out_bits_vpu_fpu_isFP32Instr, i_l5_io_out_bits_vpu_fpu_isFP32Instr;
  wire  g_l5_io_out_bits_vpu_fpu_isFP64Instr, i_l5_io_out_bits_vpu_fpu_isFP64Instr;
  wire  g_l5_io_out_bits_vpu_fpu_isReduction, i_l5_io_out_bits_vpu_fpu_isReduction;
  wire  g_l5_io_out_bits_vpu_fpu_isFoldTo1_2, i_l5_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire  g_l5_io_out_bits_vpu_fpu_isFoldTo1_4, i_l5_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire  g_l5_io_out_bits_vpu_fpu_isFoldTo1_8, i_l5_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire  [1:0] g_l5_io_out_bits_vpu_vxrm, i_l5_io_out_bits_vpu_vxrm;
  wire  [6:0] g_l5_io_out_bits_vpu_vuopIdx, i_l5_io_out_bits_vpu_vuopIdx;
  wire  g_l5_io_out_bits_vpu_lastUop, i_l5_io_out_bits_vpu_lastUop;
  wire  [127:0] g_l5_io_out_bits_vpu_vmask, i_l5_io_out_bits_vpu_vmask;
  wire  [7:0] g_l5_io_out_bits_vpu_vl, i_l5_io_out_bits_vpu_vl;
  wire  [2:0] g_l5_io_out_bits_vpu_nf, i_l5_io_out_bits_vpu_nf;
  wire  [1:0] g_l5_io_out_bits_vpu_veew, i_l5_io_out_bits_vpu_veew;
  wire  g_l5_io_out_bits_vpu_isReverse, i_l5_io_out_bits_vpu_isReverse;
  wire  g_l5_io_out_bits_vpu_isExt, i_l5_io_out_bits_vpu_isExt;
  wire  g_l5_io_out_bits_vpu_isNarrow, i_l5_io_out_bits_vpu_isNarrow;
  wire  g_l5_io_out_bits_vpu_isDstMask, i_l5_io_out_bits_vpu_isDstMask;
  wire  g_l5_io_out_bits_vpu_isOpMask, i_l5_io_out_bits_vpu_isOpMask;
  wire  g_l5_io_out_bits_vpu_isMove, i_l5_io_out_bits_vpu_isMove;
  wire  g_l5_io_out_bits_vpu_isDependOldVd, i_l5_io_out_bits_vpu_isDependOldVd;
  wire  g_l5_io_out_bits_vpu_isWritePartVd, i_l5_io_out_bits_vpu_isWritePartVd;
  wire  g_l5_io_out_bits_vpu_isVleff, i_l5_io_out_bits_vpu_isVleff;
  wire  g_l5_io_out_bits_vlsInstr, i_l5_io_out_bits_vlsInstr;
  wire  g_l5_io_out_bits_wfflags, i_l5_io_out_bits_wfflags;
  wire  g_l5_io_out_bits_isMove, i_l5_io_out_bits_isMove;
  wire  [6:0] g_l5_io_out_bits_uopIdx, i_l5_io_out_bits_uopIdx;
  wire  g_l5_io_out_bits_isVset, i_l5_io_out_bits_isVset;
  wire  g_l5_io_out_bits_firstUop, i_l5_io_out_bits_firstUop;
  wire  g_l5_io_out_bits_lastUop, i_l5_io_out_bits_lastUop;
  wire  [6:0] g_l5_io_out_bits_numUops, i_l5_io_out_bits_numUops;
  wire  [6:0] g_l5_io_out_bits_numWB, i_l5_io_out_bits_numWB;
  wire  [2:0] g_l5_io_out_bits_commitType, i_l5_io_out_bits_commitType;
  wire  [7:0] g_l5_io_out_bits_psrc_0, i_l5_io_out_bits_psrc_0;
  wire  [7:0] g_l5_io_out_bits_psrc_1, i_l5_io_out_bits_psrc_1;
  wire  [7:0] g_l5_io_out_bits_psrc_2, i_l5_io_out_bits_psrc_2;
  wire  [7:0] g_l5_io_out_bits_psrc_3, i_l5_io_out_bits_psrc_3;
  wire  [7:0] g_l5_io_out_bits_psrc_4, i_l5_io_out_bits_psrc_4;
  wire  [7:0] g_l5_io_out_bits_pdest, i_l5_io_out_bits_pdest;
  wire  g_l5_io_out_bits_robIdx_flag, i_l5_io_out_bits_robIdx_flag;
  wire  [7:0] g_l5_io_out_bits_robIdx_value, i_l5_io_out_bits_robIdx_value;
  wire  [2:0] g_l5_io_out_bits_instrSize, i_l5_io_out_bits_instrSize;
  wire  g_l5_io_out_bits_dirtyFs, i_l5_io_out_bits_dirtyFs;
  wire  g_l5_io_out_bits_dirtyVs, i_l5_io_out_bits_dirtyVs;
  wire  [3:0] g_l5_io_out_bits_traceBlockInPipe_itype, i_l5_io_out_bits_traceBlockInPipe_itype;
  wire  [3:0] g_l5_io_out_bits_traceBlockInPipe_iretire, i_l5_io_out_bits_traceBlockInPipe_iretire;
  wire  g_l5_io_out_bits_traceBlockInPipe_ilastsize, i_l5_io_out_bits_traceBlockInPipe_ilastsize;
  wire  g_l5_io_out_bits_eliminatedMove, i_l5_io_out_bits_eliminatedMove;
  wire  [63:0] g_l5_io_out_bits_debugInfo_renameTime, i_l5_io_out_bits_debugInfo_renameTime;
  wire  [55:0] g_l5_io_out_bits_debug_seqNum_seqNum, i_l5_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_l5_io_out_bits_debug_seqNum_uopIdx, i_l5_io_out_bits_debug_seqNum_uopIdx;
  wire  [34:0] g_l5_io_out_bits_debug_fuType, i_l5_io_out_bits_debug_fuType;
  wire  g_l5_io_out_bits_debug_sim_trig, i_l5_io_out_bits_debug_sim_trig;
  wire  [4:0] g_l5_io_out_bits_numLsElem, i_l5_io_out_bits_numLsElem;
  longint n_fire[6], n_bp[6], n_hold[6], n_deq[6], n_owr[6], n_flush[6];
  longint n_allfire = 0, n_flfire = 0;
  logic [734:0] por_0 = '0, pand_0 = '1;
  wire  [734:0] pcat_0 = {io_in_0_bits_instr, io_in_0_bits_pc, io_in_0_bits_foldpc, io_in_0_bits_exceptionVec_0, io_in_0_bits_exceptionVec_1, io_in_0_bits_exceptionVec_2, io_in_0_bits_exceptionVec_3, io_in_0_bits_exceptionVec_4, io_in_0_bits_exceptionVec_5, io_in_0_bits_exceptionVec_6, io_in_0_bits_exceptionVec_7, io_in_0_bits_exceptionVec_8, io_in_0_bits_exceptionVec_9, io_in_0_bits_exceptionVec_10, io_in_0_bits_exceptionVec_11, io_in_0_bits_exceptionVec_12, io_in_0_bits_exceptionVec_13, io_in_0_bits_exceptionVec_14, io_in_0_bits_exceptionVec_15, io_in_0_bits_exceptionVec_16, io_in_0_bits_exceptionVec_17, io_in_0_bits_exceptionVec_18, io_in_0_bits_exceptionVec_19, io_in_0_bits_exceptionVec_20, io_in_0_bits_exceptionVec_21, io_in_0_bits_exceptionVec_22, io_in_0_bits_exceptionVec_23, io_in_0_bits_isFetchMalAddr, io_in_0_bits_hasException, io_in_0_bits_trigger, io_in_0_bits_preDecodeInfo_valid, io_in_0_bits_preDecodeInfo_isRVC, io_in_0_bits_preDecodeInfo_brType, io_in_0_bits_preDecodeInfo_isCall, io_in_0_bits_preDecodeInfo_isRet, io_in_0_bits_pred_taken, io_in_0_bits_crossPageIPFFix, io_in_0_bits_ftqPtr_flag, io_in_0_bits_ftqPtr_value, io_in_0_bits_ftqOffset, io_in_0_bits_satpFlushFirstFetchFault, io_in_0_bits_srcType_0, io_in_0_bits_srcType_1, io_in_0_bits_srcType_2, io_in_0_bits_srcType_3, io_in_0_bits_srcType_4, io_in_0_bits_ldest, io_in_0_bits_fuType, io_in_0_bits_fuOpType, io_in_0_bits_rfWen, io_in_0_bits_fpWen, io_in_0_bits_vecWen, io_in_0_bits_v0Wen, io_in_0_bits_vlWen, io_in_0_bits_isXSTrap, io_in_0_bits_waitForward, io_in_0_bits_blockBackward, io_in_0_bits_flushPipe, io_in_0_bits_canRobCompress, io_in_0_bits_selImm, io_in_0_bits_imm, io_in_0_bits_fpu_typeTagOut, io_in_0_bits_fpu_wflags, io_in_0_bits_fpu_typ, io_in_0_bits_fpu_fmt, io_in_0_bits_fpu_rm, io_in_0_bits_vpu_vill, io_in_0_bits_vpu_vma, io_in_0_bits_vpu_vta, io_in_0_bits_vpu_vsew, io_in_0_bits_vpu_vlmul, io_in_0_bits_vpu_specVill, io_in_0_bits_vpu_specVma, io_in_0_bits_vpu_specVta, io_in_0_bits_vpu_specVsew, io_in_0_bits_vpu_specVlmul, io_in_0_bits_vpu_vm, io_in_0_bits_vpu_vstart, io_in_0_bits_vpu_frm, io_in_0_bits_vpu_fpu_isFpToVecInst, io_in_0_bits_vpu_fpu_isFP32Instr, io_in_0_bits_vpu_fpu_isFP64Instr, io_in_0_bits_vpu_fpu_isReduction, io_in_0_bits_vpu_fpu_isFoldTo1_2, io_in_0_bits_vpu_fpu_isFoldTo1_4, io_in_0_bits_vpu_fpu_isFoldTo1_8, io_in_0_bits_vpu_vxrm, io_in_0_bits_vpu_vuopIdx, io_in_0_bits_vpu_lastUop, io_in_0_bits_vpu_vmask, io_in_0_bits_vpu_vl, io_in_0_bits_vpu_nf, io_in_0_bits_vpu_veew, io_in_0_bits_vpu_isReverse, io_in_0_bits_vpu_isExt, io_in_0_bits_vpu_isNarrow, io_in_0_bits_vpu_isDstMask, io_in_0_bits_vpu_isOpMask, io_in_0_bits_vpu_isMove, io_in_0_bits_vpu_isDependOldVd, io_in_0_bits_vpu_isWritePartVd, io_in_0_bits_vpu_isVleff, io_in_0_bits_vlsInstr, io_in_0_bits_wfflags, io_in_0_bits_isMove, io_in_0_bits_uopIdx, io_in_0_bits_isVset, io_in_0_bits_firstUop, io_in_0_bits_lastUop, io_in_0_bits_numUops, io_in_0_bits_numWB, io_in_0_bits_commitType, io_in_0_bits_psrc_0, io_in_0_bits_psrc_1, io_in_0_bits_psrc_2, io_in_0_bits_psrc_3, io_in_0_bits_psrc_4, io_in_0_bits_pdest, io_in_0_bits_robIdx_flag, io_in_0_bits_robIdx_value, io_in_0_bits_instrSize, io_in_0_bits_dirtyFs, io_in_0_bits_dirtyVs, io_in_0_bits_traceBlockInPipe_itype, io_in_0_bits_traceBlockInPipe_iretire, io_in_0_bits_traceBlockInPipe_ilastsize, io_in_0_bits_eliminatedMove, io_in_0_bits_snapshot, io_in_0_bits_debugInfo_renameTime, io_in_0_bits_debug_seqNum_seqNum, io_in_0_bits_debug_seqNum_uopIdx, io_in_0_bits_debug_fuType, io_in_0_bits_debug_sim_trig, io_in_0_bits_numLsElem};
  logic [733:0] por_1 = '0, pand_1 = '1;
  wire  [733:0] pcat_1 = {io_in_1_bits_instr, io_in_1_bits_pc, io_in_1_bits_foldpc, io_in_1_bits_exceptionVec_0, io_in_1_bits_exceptionVec_1, io_in_1_bits_exceptionVec_2, io_in_1_bits_exceptionVec_3, io_in_1_bits_exceptionVec_4, io_in_1_bits_exceptionVec_5, io_in_1_bits_exceptionVec_6, io_in_1_bits_exceptionVec_7, io_in_1_bits_exceptionVec_8, io_in_1_bits_exceptionVec_9, io_in_1_bits_exceptionVec_10, io_in_1_bits_exceptionVec_11, io_in_1_bits_exceptionVec_12, io_in_1_bits_exceptionVec_13, io_in_1_bits_exceptionVec_14, io_in_1_bits_exceptionVec_15, io_in_1_bits_exceptionVec_16, io_in_1_bits_exceptionVec_17, io_in_1_bits_exceptionVec_18, io_in_1_bits_exceptionVec_19, io_in_1_bits_exceptionVec_20, io_in_1_bits_exceptionVec_21, io_in_1_bits_exceptionVec_22, io_in_1_bits_exceptionVec_23, io_in_1_bits_isFetchMalAddr, io_in_1_bits_hasException, io_in_1_bits_trigger, io_in_1_bits_preDecodeInfo_valid, io_in_1_bits_preDecodeInfo_isRVC, io_in_1_bits_preDecodeInfo_brType, io_in_1_bits_preDecodeInfo_isCall, io_in_1_bits_preDecodeInfo_isRet, io_in_1_bits_pred_taken, io_in_1_bits_crossPageIPFFix, io_in_1_bits_ftqPtr_flag, io_in_1_bits_ftqPtr_value, io_in_1_bits_ftqOffset, io_in_1_bits_satpFlushFirstFetchFault, io_in_1_bits_srcType_0, io_in_1_bits_srcType_1, io_in_1_bits_srcType_2, io_in_1_bits_srcType_3, io_in_1_bits_srcType_4, io_in_1_bits_ldest, io_in_1_bits_fuType, io_in_1_bits_fuOpType, io_in_1_bits_rfWen, io_in_1_bits_fpWen, io_in_1_bits_vecWen, io_in_1_bits_v0Wen, io_in_1_bits_vlWen, io_in_1_bits_isXSTrap, io_in_1_bits_waitForward, io_in_1_bits_blockBackward, io_in_1_bits_flushPipe, io_in_1_bits_canRobCompress, io_in_1_bits_selImm, io_in_1_bits_imm, io_in_1_bits_fpu_typeTagOut, io_in_1_bits_fpu_wflags, io_in_1_bits_fpu_typ, io_in_1_bits_fpu_fmt, io_in_1_bits_fpu_rm, io_in_1_bits_vpu_vill, io_in_1_bits_vpu_vma, io_in_1_bits_vpu_vta, io_in_1_bits_vpu_vsew, io_in_1_bits_vpu_vlmul, io_in_1_bits_vpu_specVill, io_in_1_bits_vpu_specVma, io_in_1_bits_vpu_specVta, io_in_1_bits_vpu_specVsew, io_in_1_bits_vpu_specVlmul, io_in_1_bits_vpu_vm, io_in_1_bits_vpu_vstart, io_in_1_bits_vpu_frm, io_in_1_bits_vpu_fpu_isFpToVecInst, io_in_1_bits_vpu_fpu_isFP32Instr, io_in_1_bits_vpu_fpu_isFP64Instr, io_in_1_bits_vpu_fpu_isReduction, io_in_1_bits_vpu_fpu_isFoldTo1_2, io_in_1_bits_vpu_fpu_isFoldTo1_4, io_in_1_bits_vpu_fpu_isFoldTo1_8, io_in_1_bits_vpu_vxrm, io_in_1_bits_vpu_vuopIdx, io_in_1_bits_vpu_lastUop, io_in_1_bits_vpu_vmask, io_in_1_bits_vpu_vl, io_in_1_bits_vpu_nf, io_in_1_bits_vpu_veew, io_in_1_bits_vpu_isReverse, io_in_1_bits_vpu_isExt, io_in_1_bits_vpu_isNarrow, io_in_1_bits_vpu_isDstMask, io_in_1_bits_vpu_isOpMask, io_in_1_bits_vpu_isMove, io_in_1_bits_vpu_isDependOldVd, io_in_1_bits_vpu_isWritePartVd, io_in_1_bits_vpu_isVleff, io_in_1_bits_vlsInstr, io_in_1_bits_wfflags, io_in_1_bits_isMove, io_in_1_bits_uopIdx, io_in_1_bits_isVset, io_in_1_bits_firstUop, io_in_1_bits_lastUop, io_in_1_bits_numUops, io_in_1_bits_numWB, io_in_1_bits_commitType, io_in_1_bits_psrc_0, io_in_1_bits_psrc_1, io_in_1_bits_psrc_2, io_in_1_bits_psrc_3, io_in_1_bits_psrc_4, io_in_1_bits_pdest, io_in_1_bits_robIdx_flag, io_in_1_bits_robIdx_value, io_in_1_bits_instrSize, io_in_1_bits_dirtyFs, io_in_1_bits_dirtyVs, io_in_1_bits_traceBlockInPipe_itype, io_in_1_bits_traceBlockInPipe_iretire, io_in_1_bits_traceBlockInPipe_ilastsize, io_in_1_bits_eliminatedMove, io_in_1_bits_debugInfo_renameTime, io_in_1_bits_debug_seqNum_seqNum, io_in_1_bits_debug_seqNum_uopIdx, io_in_1_bits_debug_fuType, io_in_1_bits_debug_sim_trig, io_in_1_bits_numLsElem};
  logic [733:0] por_2 = '0, pand_2 = '1;
  wire  [733:0] pcat_2 = {io_in_2_bits_instr, io_in_2_bits_pc, io_in_2_bits_foldpc, io_in_2_bits_exceptionVec_0, io_in_2_bits_exceptionVec_1, io_in_2_bits_exceptionVec_2, io_in_2_bits_exceptionVec_3, io_in_2_bits_exceptionVec_4, io_in_2_bits_exceptionVec_5, io_in_2_bits_exceptionVec_6, io_in_2_bits_exceptionVec_7, io_in_2_bits_exceptionVec_8, io_in_2_bits_exceptionVec_9, io_in_2_bits_exceptionVec_10, io_in_2_bits_exceptionVec_11, io_in_2_bits_exceptionVec_12, io_in_2_bits_exceptionVec_13, io_in_2_bits_exceptionVec_14, io_in_2_bits_exceptionVec_15, io_in_2_bits_exceptionVec_16, io_in_2_bits_exceptionVec_17, io_in_2_bits_exceptionVec_18, io_in_2_bits_exceptionVec_19, io_in_2_bits_exceptionVec_20, io_in_2_bits_exceptionVec_21, io_in_2_bits_exceptionVec_22, io_in_2_bits_exceptionVec_23, io_in_2_bits_isFetchMalAddr, io_in_2_bits_hasException, io_in_2_bits_trigger, io_in_2_bits_preDecodeInfo_valid, io_in_2_bits_preDecodeInfo_isRVC, io_in_2_bits_preDecodeInfo_brType, io_in_2_bits_preDecodeInfo_isCall, io_in_2_bits_preDecodeInfo_isRet, io_in_2_bits_pred_taken, io_in_2_bits_crossPageIPFFix, io_in_2_bits_ftqPtr_flag, io_in_2_bits_ftqPtr_value, io_in_2_bits_ftqOffset, io_in_2_bits_satpFlushFirstFetchFault, io_in_2_bits_srcType_0, io_in_2_bits_srcType_1, io_in_2_bits_srcType_2, io_in_2_bits_srcType_3, io_in_2_bits_srcType_4, io_in_2_bits_ldest, io_in_2_bits_fuType, io_in_2_bits_fuOpType, io_in_2_bits_rfWen, io_in_2_bits_fpWen, io_in_2_bits_vecWen, io_in_2_bits_v0Wen, io_in_2_bits_vlWen, io_in_2_bits_isXSTrap, io_in_2_bits_waitForward, io_in_2_bits_blockBackward, io_in_2_bits_flushPipe, io_in_2_bits_canRobCompress, io_in_2_bits_selImm, io_in_2_bits_imm, io_in_2_bits_fpu_typeTagOut, io_in_2_bits_fpu_wflags, io_in_2_bits_fpu_typ, io_in_2_bits_fpu_fmt, io_in_2_bits_fpu_rm, io_in_2_bits_vpu_vill, io_in_2_bits_vpu_vma, io_in_2_bits_vpu_vta, io_in_2_bits_vpu_vsew, io_in_2_bits_vpu_vlmul, io_in_2_bits_vpu_specVill, io_in_2_bits_vpu_specVma, io_in_2_bits_vpu_specVta, io_in_2_bits_vpu_specVsew, io_in_2_bits_vpu_specVlmul, io_in_2_bits_vpu_vm, io_in_2_bits_vpu_vstart, io_in_2_bits_vpu_frm, io_in_2_bits_vpu_fpu_isFpToVecInst, io_in_2_bits_vpu_fpu_isFP32Instr, io_in_2_bits_vpu_fpu_isFP64Instr, io_in_2_bits_vpu_fpu_isReduction, io_in_2_bits_vpu_fpu_isFoldTo1_2, io_in_2_bits_vpu_fpu_isFoldTo1_4, io_in_2_bits_vpu_fpu_isFoldTo1_8, io_in_2_bits_vpu_vxrm, io_in_2_bits_vpu_vuopIdx, io_in_2_bits_vpu_lastUop, io_in_2_bits_vpu_vmask, io_in_2_bits_vpu_vl, io_in_2_bits_vpu_nf, io_in_2_bits_vpu_veew, io_in_2_bits_vpu_isReverse, io_in_2_bits_vpu_isExt, io_in_2_bits_vpu_isNarrow, io_in_2_bits_vpu_isDstMask, io_in_2_bits_vpu_isOpMask, io_in_2_bits_vpu_isMove, io_in_2_bits_vpu_isDependOldVd, io_in_2_bits_vpu_isWritePartVd, io_in_2_bits_vpu_isVleff, io_in_2_bits_vlsInstr, io_in_2_bits_wfflags, io_in_2_bits_isMove, io_in_2_bits_uopIdx, io_in_2_bits_isVset, io_in_2_bits_firstUop, io_in_2_bits_lastUop, io_in_2_bits_numUops, io_in_2_bits_numWB, io_in_2_bits_commitType, io_in_2_bits_psrc_0, io_in_2_bits_psrc_1, io_in_2_bits_psrc_2, io_in_2_bits_psrc_3, io_in_2_bits_psrc_4, io_in_2_bits_pdest, io_in_2_bits_robIdx_flag, io_in_2_bits_robIdx_value, io_in_2_bits_instrSize, io_in_2_bits_dirtyFs, io_in_2_bits_dirtyVs, io_in_2_bits_traceBlockInPipe_itype, io_in_2_bits_traceBlockInPipe_iretire, io_in_2_bits_traceBlockInPipe_ilastsize, io_in_2_bits_eliminatedMove, io_in_2_bits_debugInfo_renameTime, io_in_2_bits_debug_seqNum_seqNum, io_in_2_bits_debug_seqNum_uopIdx, io_in_2_bits_debug_fuType, io_in_2_bits_debug_sim_trig, io_in_2_bits_numLsElem};
  logic [733:0] por_3 = '0, pand_3 = '1;
  wire  [733:0] pcat_3 = {io_in_3_bits_instr, io_in_3_bits_pc, io_in_3_bits_foldpc, io_in_3_bits_exceptionVec_0, io_in_3_bits_exceptionVec_1, io_in_3_bits_exceptionVec_2, io_in_3_bits_exceptionVec_3, io_in_3_bits_exceptionVec_4, io_in_3_bits_exceptionVec_5, io_in_3_bits_exceptionVec_6, io_in_3_bits_exceptionVec_7, io_in_3_bits_exceptionVec_8, io_in_3_bits_exceptionVec_9, io_in_3_bits_exceptionVec_10, io_in_3_bits_exceptionVec_11, io_in_3_bits_exceptionVec_12, io_in_3_bits_exceptionVec_13, io_in_3_bits_exceptionVec_14, io_in_3_bits_exceptionVec_15, io_in_3_bits_exceptionVec_16, io_in_3_bits_exceptionVec_17, io_in_3_bits_exceptionVec_18, io_in_3_bits_exceptionVec_19, io_in_3_bits_exceptionVec_20, io_in_3_bits_exceptionVec_21, io_in_3_bits_exceptionVec_22, io_in_3_bits_exceptionVec_23, io_in_3_bits_isFetchMalAddr, io_in_3_bits_hasException, io_in_3_bits_trigger, io_in_3_bits_preDecodeInfo_valid, io_in_3_bits_preDecodeInfo_isRVC, io_in_3_bits_preDecodeInfo_brType, io_in_3_bits_preDecodeInfo_isCall, io_in_3_bits_preDecodeInfo_isRet, io_in_3_bits_pred_taken, io_in_3_bits_crossPageIPFFix, io_in_3_bits_ftqPtr_flag, io_in_3_bits_ftqPtr_value, io_in_3_bits_ftqOffset, io_in_3_bits_satpFlushFirstFetchFault, io_in_3_bits_srcType_0, io_in_3_bits_srcType_1, io_in_3_bits_srcType_2, io_in_3_bits_srcType_3, io_in_3_bits_srcType_4, io_in_3_bits_ldest, io_in_3_bits_fuType, io_in_3_bits_fuOpType, io_in_3_bits_rfWen, io_in_3_bits_fpWen, io_in_3_bits_vecWen, io_in_3_bits_v0Wen, io_in_3_bits_vlWen, io_in_3_bits_isXSTrap, io_in_3_bits_waitForward, io_in_3_bits_blockBackward, io_in_3_bits_flushPipe, io_in_3_bits_canRobCompress, io_in_3_bits_selImm, io_in_3_bits_imm, io_in_3_bits_fpu_typeTagOut, io_in_3_bits_fpu_wflags, io_in_3_bits_fpu_typ, io_in_3_bits_fpu_fmt, io_in_3_bits_fpu_rm, io_in_3_bits_vpu_vill, io_in_3_bits_vpu_vma, io_in_3_bits_vpu_vta, io_in_3_bits_vpu_vsew, io_in_3_bits_vpu_vlmul, io_in_3_bits_vpu_specVill, io_in_3_bits_vpu_specVma, io_in_3_bits_vpu_specVta, io_in_3_bits_vpu_specVsew, io_in_3_bits_vpu_specVlmul, io_in_3_bits_vpu_vm, io_in_3_bits_vpu_vstart, io_in_3_bits_vpu_frm, io_in_3_bits_vpu_fpu_isFpToVecInst, io_in_3_bits_vpu_fpu_isFP32Instr, io_in_3_bits_vpu_fpu_isFP64Instr, io_in_3_bits_vpu_fpu_isReduction, io_in_3_bits_vpu_fpu_isFoldTo1_2, io_in_3_bits_vpu_fpu_isFoldTo1_4, io_in_3_bits_vpu_fpu_isFoldTo1_8, io_in_3_bits_vpu_vxrm, io_in_3_bits_vpu_vuopIdx, io_in_3_bits_vpu_lastUop, io_in_3_bits_vpu_vmask, io_in_3_bits_vpu_vl, io_in_3_bits_vpu_nf, io_in_3_bits_vpu_veew, io_in_3_bits_vpu_isReverse, io_in_3_bits_vpu_isExt, io_in_3_bits_vpu_isNarrow, io_in_3_bits_vpu_isDstMask, io_in_3_bits_vpu_isOpMask, io_in_3_bits_vpu_isMove, io_in_3_bits_vpu_isDependOldVd, io_in_3_bits_vpu_isWritePartVd, io_in_3_bits_vpu_isVleff, io_in_3_bits_vlsInstr, io_in_3_bits_wfflags, io_in_3_bits_isMove, io_in_3_bits_uopIdx, io_in_3_bits_isVset, io_in_3_bits_firstUop, io_in_3_bits_lastUop, io_in_3_bits_numUops, io_in_3_bits_numWB, io_in_3_bits_commitType, io_in_3_bits_psrc_0, io_in_3_bits_psrc_1, io_in_3_bits_psrc_2, io_in_3_bits_psrc_3, io_in_3_bits_psrc_4, io_in_3_bits_pdest, io_in_3_bits_robIdx_flag, io_in_3_bits_robIdx_value, io_in_3_bits_instrSize, io_in_3_bits_dirtyFs, io_in_3_bits_dirtyVs, io_in_3_bits_traceBlockInPipe_itype, io_in_3_bits_traceBlockInPipe_iretire, io_in_3_bits_traceBlockInPipe_ilastsize, io_in_3_bits_eliminatedMove, io_in_3_bits_debugInfo_renameTime, io_in_3_bits_debug_seqNum_seqNum, io_in_3_bits_debug_seqNum_uopIdx, io_in_3_bits_debug_fuType, io_in_3_bits_debug_sim_trig, io_in_3_bits_numLsElem};
  logic [733:0] por_4 = '0, pand_4 = '1;
  wire  [733:0] pcat_4 = {io_in_4_bits_instr, io_in_4_bits_pc, io_in_4_bits_foldpc, io_in_4_bits_exceptionVec_0, io_in_4_bits_exceptionVec_1, io_in_4_bits_exceptionVec_2, io_in_4_bits_exceptionVec_3, io_in_4_bits_exceptionVec_4, io_in_4_bits_exceptionVec_5, io_in_4_bits_exceptionVec_6, io_in_4_bits_exceptionVec_7, io_in_4_bits_exceptionVec_8, io_in_4_bits_exceptionVec_9, io_in_4_bits_exceptionVec_10, io_in_4_bits_exceptionVec_11, io_in_4_bits_exceptionVec_12, io_in_4_bits_exceptionVec_13, io_in_4_bits_exceptionVec_14, io_in_4_bits_exceptionVec_15, io_in_4_bits_exceptionVec_16, io_in_4_bits_exceptionVec_17, io_in_4_bits_exceptionVec_18, io_in_4_bits_exceptionVec_19, io_in_4_bits_exceptionVec_20, io_in_4_bits_exceptionVec_21, io_in_4_bits_exceptionVec_22, io_in_4_bits_exceptionVec_23, io_in_4_bits_isFetchMalAddr, io_in_4_bits_hasException, io_in_4_bits_trigger, io_in_4_bits_preDecodeInfo_valid, io_in_4_bits_preDecodeInfo_isRVC, io_in_4_bits_preDecodeInfo_brType, io_in_4_bits_preDecodeInfo_isCall, io_in_4_bits_preDecodeInfo_isRet, io_in_4_bits_pred_taken, io_in_4_bits_crossPageIPFFix, io_in_4_bits_ftqPtr_flag, io_in_4_bits_ftqPtr_value, io_in_4_bits_ftqOffset, io_in_4_bits_satpFlushFirstFetchFault, io_in_4_bits_srcType_0, io_in_4_bits_srcType_1, io_in_4_bits_srcType_2, io_in_4_bits_srcType_3, io_in_4_bits_srcType_4, io_in_4_bits_ldest, io_in_4_bits_fuType, io_in_4_bits_fuOpType, io_in_4_bits_rfWen, io_in_4_bits_fpWen, io_in_4_bits_vecWen, io_in_4_bits_v0Wen, io_in_4_bits_vlWen, io_in_4_bits_isXSTrap, io_in_4_bits_waitForward, io_in_4_bits_blockBackward, io_in_4_bits_flushPipe, io_in_4_bits_canRobCompress, io_in_4_bits_selImm, io_in_4_bits_imm, io_in_4_bits_fpu_typeTagOut, io_in_4_bits_fpu_wflags, io_in_4_bits_fpu_typ, io_in_4_bits_fpu_fmt, io_in_4_bits_fpu_rm, io_in_4_bits_vpu_vill, io_in_4_bits_vpu_vma, io_in_4_bits_vpu_vta, io_in_4_bits_vpu_vsew, io_in_4_bits_vpu_vlmul, io_in_4_bits_vpu_specVill, io_in_4_bits_vpu_specVma, io_in_4_bits_vpu_specVta, io_in_4_bits_vpu_specVsew, io_in_4_bits_vpu_specVlmul, io_in_4_bits_vpu_vm, io_in_4_bits_vpu_vstart, io_in_4_bits_vpu_frm, io_in_4_bits_vpu_fpu_isFpToVecInst, io_in_4_bits_vpu_fpu_isFP32Instr, io_in_4_bits_vpu_fpu_isFP64Instr, io_in_4_bits_vpu_fpu_isReduction, io_in_4_bits_vpu_fpu_isFoldTo1_2, io_in_4_bits_vpu_fpu_isFoldTo1_4, io_in_4_bits_vpu_fpu_isFoldTo1_8, io_in_4_bits_vpu_vxrm, io_in_4_bits_vpu_vuopIdx, io_in_4_bits_vpu_lastUop, io_in_4_bits_vpu_vmask, io_in_4_bits_vpu_vl, io_in_4_bits_vpu_nf, io_in_4_bits_vpu_veew, io_in_4_bits_vpu_isReverse, io_in_4_bits_vpu_isExt, io_in_4_bits_vpu_isNarrow, io_in_4_bits_vpu_isDstMask, io_in_4_bits_vpu_isOpMask, io_in_4_bits_vpu_isMove, io_in_4_bits_vpu_isDependOldVd, io_in_4_bits_vpu_isWritePartVd, io_in_4_bits_vpu_isVleff, io_in_4_bits_vlsInstr, io_in_4_bits_wfflags, io_in_4_bits_isMove, io_in_4_bits_uopIdx, io_in_4_bits_isVset, io_in_4_bits_firstUop, io_in_4_bits_lastUop, io_in_4_bits_numUops, io_in_4_bits_numWB, io_in_4_bits_commitType, io_in_4_bits_psrc_0, io_in_4_bits_psrc_1, io_in_4_bits_psrc_2, io_in_4_bits_psrc_3, io_in_4_bits_psrc_4, io_in_4_bits_pdest, io_in_4_bits_robIdx_flag, io_in_4_bits_robIdx_value, io_in_4_bits_instrSize, io_in_4_bits_dirtyFs, io_in_4_bits_dirtyVs, io_in_4_bits_traceBlockInPipe_itype, io_in_4_bits_traceBlockInPipe_iretire, io_in_4_bits_traceBlockInPipe_ilastsize, io_in_4_bits_eliminatedMove, io_in_4_bits_debugInfo_renameTime, io_in_4_bits_debug_seqNum_seqNum, io_in_4_bits_debug_seqNum_uopIdx, io_in_4_bits_debug_fuType, io_in_4_bits_debug_sim_trig, io_in_4_bits_numLsElem};
  logic [733:0] por_5 = '0, pand_5 = '1;
  wire  [733:0] pcat_5 = {io_in_5_bits_instr, io_in_5_bits_pc, io_in_5_bits_foldpc, io_in_5_bits_exceptionVec_0, io_in_5_bits_exceptionVec_1, io_in_5_bits_exceptionVec_2, io_in_5_bits_exceptionVec_3, io_in_5_bits_exceptionVec_4, io_in_5_bits_exceptionVec_5, io_in_5_bits_exceptionVec_6, io_in_5_bits_exceptionVec_7, io_in_5_bits_exceptionVec_8, io_in_5_bits_exceptionVec_9, io_in_5_bits_exceptionVec_10, io_in_5_bits_exceptionVec_11, io_in_5_bits_exceptionVec_12, io_in_5_bits_exceptionVec_13, io_in_5_bits_exceptionVec_14, io_in_5_bits_exceptionVec_15, io_in_5_bits_exceptionVec_16, io_in_5_bits_exceptionVec_17, io_in_5_bits_exceptionVec_18, io_in_5_bits_exceptionVec_19, io_in_5_bits_exceptionVec_20, io_in_5_bits_exceptionVec_21, io_in_5_bits_exceptionVec_22, io_in_5_bits_exceptionVec_23, io_in_5_bits_isFetchMalAddr, io_in_5_bits_hasException, io_in_5_bits_trigger, io_in_5_bits_preDecodeInfo_valid, io_in_5_bits_preDecodeInfo_isRVC, io_in_5_bits_preDecodeInfo_brType, io_in_5_bits_preDecodeInfo_isCall, io_in_5_bits_preDecodeInfo_isRet, io_in_5_bits_pred_taken, io_in_5_bits_crossPageIPFFix, io_in_5_bits_ftqPtr_flag, io_in_5_bits_ftqPtr_value, io_in_5_bits_ftqOffset, io_in_5_bits_satpFlushFirstFetchFault, io_in_5_bits_srcType_0, io_in_5_bits_srcType_1, io_in_5_bits_srcType_2, io_in_5_bits_srcType_3, io_in_5_bits_srcType_4, io_in_5_bits_ldest, io_in_5_bits_fuType, io_in_5_bits_fuOpType, io_in_5_bits_rfWen, io_in_5_bits_fpWen, io_in_5_bits_vecWen, io_in_5_bits_v0Wen, io_in_5_bits_vlWen, io_in_5_bits_isXSTrap, io_in_5_bits_waitForward, io_in_5_bits_blockBackward, io_in_5_bits_flushPipe, io_in_5_bits_canRobCompress, io_in_5_bits_selImm, io_in_5_bits_imm, io_in_5_bits_fpu_typeTagOut, io_in_5_bits_fpu_wflags, io_in_5_bits_fpu_typ, io_in_5_bits_fpu_fmt, io_in_5_bits_fpu_rm, io_in_5_bits_vpu_vill, io_in_5_bits_vpu_vma, io_in_5_bits_vpu_vta, io_in_5_bits_vpu_vsew, io_in_5_bits_vpu_vlmul, io_in_5_bits_vpu_specVill, io_in_5_bits_vpu_specVma, io_in_5_bits_vpu_specVta, io_in_5_bits_vpu_specVsew, io_in_5_bits_vpu_specVlmul, io_in_5_bits_vpu_vm, io_in_5_bits_vpu_vstart, io_in_5_bits_vpu_frm, io_in_5_bits_vpu_fpu_isFpToVecInst, io_in_5_bits_vpu_fpu_isFP32Instr, io_in_5_bits_vpu_fpu_isFP64Instr, io_in_5_bits_vpu_fpu_isReduction, io_in_5_bits_vpu_fpu_isFoldTo1_2, io_in_5_bits_vpu_fpu_isFoldTo1_4, io_in_5_bits_vpu_fpu_isFoldTo1_8, io_in_5_bits_vpu_vxrm, io_in_5_bits_vpu_vuopIdx, io_in_5_bits_vpu_lastUop, io_in_5_bits_vpu_vmask, io_in_5_bits_vpu_vl, io_in_5_bits_vpu_nf, io_in_5_bits_vpu_veew, io_in_5_bits_vpu_isReverse, io_in_5_bits_vpu_isExt, io_in_5_bits_vpu_isNarrow, io_in_5_bits_vpu_isDstMask, io_in_5_bits_vpu_isOpMask, io_in_5_bits_vpu_isMove, io_in_5_bits_vpu_isDependOldVd, io_in_5_bits_vpu_isWritePartVd, io_in_5_bits_vpu_isVleff, io_in_5_bits_vlsInstr, io_in_5_bits_wfflags, io_in_5_bits_isMove, io_in_5_bits_uopIdx, io_in_5_bits_isVset, io_in_5_bits_firstUop, io_in_5_bits_lastUop, io_in_5_bits_numUops, io_in_5_bits_numWB, io_in_5_bits_commitType, io_in_5_bits_psrc_0, io_in_5_bits_psrc_1, io_in_5_bits_psrc_2, io_in_5_bits_psrc_3, io_in_5_bits_psrc_4, io_in_5_bits_pdest, io_in_5_bits_robIdx_flag, io_in_5_bits_robIdx_value, io_in_5_bits_instrSize, io_in_5_bits_dirtyFs, io_in_5_bits_dirtyVs, io_in_5_bits_traceBlockInPipe_itype, io_in_5_bits_traceBlockInPipe_iretire, io_in_5_bits_traceBlockInPipe_ilastsize, io_in_5_bits_eliminatedMove, io_in_5_bits_debugInfo_renameTime, io_in_5_bits_debug_seqNum_seqNum, io_in_5_bits_debug_seqNum_uopIdx, io_in_5_bits_debug_fuType, io_in_5_bits_debug_sim_trig, io_in_5_bits_numLsElem};

  PipeGroupConnect u_golden (
    .clock(clock), .reset(reset),
    .io_flush(io_flush), .io_outAllFire(io_outAllFire),
    .io_in_0_valid(io_in_0_valid), .io_in_0_ready(g_l0_io_in_ready),
    .io_out_0_ready(io_out_0_ready), .io_out_0_valid(g_l0_io_out_valid),
    .io_in_0_bits_instr(io_in_0_bits_instr),
    .io_in_0_bits_pc(io_in_0_bits_pc),
    .io_in_0_bits_foldpc(io_in_0_bits_foldpc),
    .io_in_0_bits_exceptionVec_0(io_in_0_bits_exceptionVec_0),
    .io_in_0_bits_exceptionVec_1(io_in_0_bits_exceptionVec_1),
    .io_in_0_bits_exceptionVec_2(io_in_0_bits_exceptionVec_2),
    .io_in_0_bits_exceptionVec_3(io_in_0_bits_exceptionVec_3),
    .io_in_0_bits_exceptionVec_4(io_in_0_bits_exceptionVec_4),
    .io_in_0_bits_exceptionVec_5(io_in_0_bits_exceptionVec_5),
    .io_in_0_bits_exceptionVec_6(io_in_0_bits_exceptionVec_6),
    .io_in_0_bits_exceptionVec_7(io_in_0_bits_exceptionVec_7),
    .io_in_0_bits_exceptionVec_8(io_in_0_bits_exceptionVec_8),
    .io_in_0_bits_exceptionVec_9(io_in_0_bits_exceptionVec_9),
    .io_in_0_bits_exceptionVec_10(io_in_0_bits_exceptionVec_10),
    .io_in_0_bits_exceptionVec_11(io_in_0_bits_exceptionVec_11),
    .io_in_0_bits_exceptionVec_12(io_in_0_bits_exceptionVec_12),
    .io_in_0_bits_exceptionVec_13(io_in_0_bits_exceptionVec_13),
    .io_in_0_bits_exceptionVec_14(io_in_0_bits_exceptionVec_14),
    .io_in_0_bits_exceptionVec_15(io_in_0_bits_exceptionVec_15),
    .io_in_0_bits_exceptionVec_16(io_in_0_bits_exceptionVec_16),
    .io_in_0_bits_exceptionVec_17(io_in_0_bits_exceptionVec_17),
    .io_in_0_bits_exceptionVec_18(io_in_0_bits_exceptionVec_18),
    .io_in_0_bits_exceptionVec_19(io_in_0_bits_exceptionVec_19),
    .io_in_0_bits_exceptionVec_20(io_in_0_bits_exceptionVec_20),
    .io_in_0_bits_exceptionVec_21(io_in_0_bits_exceptionVec_21),
    .io_in_0_bits_exceptionVec_22(io_in_0_bits_exceptionVec_22),
    .io_in_0_bits_exceptionVec_23(io_in_0_bits_exceptionVec_23),
    .io_in_0_bits_isFetchMalAddr(io_in_0_bits_isFetchMalAddr),
    .io_in_0_bits_hasException(io_in_0_bits_hasException),
    .io_in_0_bits_trigger(io_in_0_bits_trigger),
    .io_in_0_bits_preDecodeInfo_valid(io_in_0_bits_preDecodeInfo_valid),
    .io_in_0_bits_preDecodeInfo_isRVC(io_in_0_bits_preDecodeInfo_isRVC),
    .io_in_0_bits_preDecodeInfo_brType(io_in_0_bits_preDecodeInfo_brType),
    .io_in_0_bits_preDecodeInfo_isCall(io_in_0_bits_preDecodeInfo_isCall),
    .io_in_0_bits_preDecodeInfo_isRet(io_in_0_bits_preDecodeInfo_isRet),
    .io_in_0_bits_pred_taken(io_in_0_bits_pred_taken),
    .io_in_0_bits_crossPageIPFFix(io_in_0_bits_crossPageIPFFix),
    .io_in_0_bits_ftqPtr_flag(io_in_0_bits_ftqPtr_flag),
    .io_in_0_bits_ftqPtr_value(io_in_0_bits_ftqPtr_value),
    .io_in_0_bits_ftqOffset(io_in_0_bits_ftqOffset),
    .io_in_0_bits_satpFlushFirstFetchFault(io_in_0_bits_satpFlushFirstFetchFault),
    .io_in_0_bits_srcType_0(io_in_0_bits_srcType_0),
    .io_in_0_bits_srcType_1(io_in_0_bits_srcType_1),
    .io_in_0_bits_srcType_2(io_in_0_bits_srcType_2),
    .io_in_0_bits_srcType_3(io_in_0_bits_srcType_3),
    .io_in_0_bits_srcType_4(io_in_0_bits_srcType_4),
    .io_in_0_bits_ldest(io_in_0_bits_ldest),
    .io_in_0_bits_fuType(io_in_0_bits_fuType),
    .io_in_0_bits_fuOpType(io_in_0_bits_fuOpType),
    .io_in_0_bits_rfWen(io_in_0_bits_rfWen),
    .io_in_0_bits_fpWen(io_in_0_bits_fpWen),
    .io_in_0_bits_vecWen(io_in_0_bits_vecWen),
    .io_in_0_bits_v0Wen(io_in_0_bits_v0Wen),
    .io_in_0_bits_vlWen(io_in_0_bits_vlWen),
    .io_in_0_bits_isXSTrap(io_in_0_bits_isXSTrap),
    .io_in_0_bits_waitForward(io_in_0_bits_waitForward),
    .io_in_0_bits_blockBackward(io_in_0_bits_blockBackward),
    .io_in_0_bits_flushPipe(io_in_0_bits_flushPipe),
    .io_in_0_bits_canRobCompress(io_in_0_bits_canRobCompress),
    .io_in_0_bits_selImm(io_in_0_bits_selImm),
    .io_in_0_bits_imm(io_in_0_bits_imm),
    .io_in_0_bits_fpu_typeTagOut(io_in_0_bits_fpu_typeTagOut),
    .io_in_0_bits_fpu_wflags(io_in_0_bits_fpu_wflags),
    .io_in_0_bits_fpu_typ(io_in_0_bits_fpu_typ),
    .io_in_0_bits_fpu_fmt(io_in_0_bits_fpu_fmt),
    .io_in_0_bits_fpu_rm(io_in_0_bits_fpu_rm),
    .io_in_0_bits_vpu_vill(io_in_0_bits_vpu_vill),
    .io_in_0_bits_vpu_vma(io_in_0_bits_vpu_vma),
    .io_in_0_bits_vpu_vta(io_in_0_bits_vpu_vta),
    .io_in_0_bits_vpu_vsew(io_in_0_bits_vpu_vsew),
    .io_in_0_bits_vpu_vlmul(io_in_0_bits_vpu_vlmul),
    .io_in_0_bits_vpu_specVill(io_in_0_bits_vpu_specVill),
    .io_in_0_bits_vpu_specVma(io_in_0_bits_vpu_specVma),
    .io_in_0_bits_vpu_specVta(io_in_0_bits_vpu_specVta),
    .io_in_0_bits_vpu_specVsew(io_in_0_bits_vpu_specVsew),
    .io_in_0_bits_vpu_specVlmul(io_in_0_bits_vpu_specVlmul),
    .io_in_0_bits_vpu_vm(io_in_0_bits_vpu_vm),
    .io_in_0_bits_vpu_vstart(io_in_0_bits_vpu_vstart),
    .io_in_0_bits_vpu_frm(io_in_0_bits_vpu_frm),
    .io_in_0_bits_vpu_fpu_isFpToVecInst(io_in_0_bits_vpu_fpu_isFpToVecInst),
    .io_in_0_bits_vpu_fpu_isFP32Instr(io_in_0_bits_vpu_fpu_isFP32Instr),
    .io_in_0_bits_vpu_fpu_isFP64Instr(io_in_0_bits_vpu_fpu_isFP64Instr),
    .io_in_0_bits_vpu_fpu_isReduction(io_in_0_bits_vpu_fpu_isReduction),
    .io_in_0_bits_vpu_fpu_isFoldTo1_2(io_in_0_bits_vpu_fpu_isFoldTo1_2),
    .io_in_0_bits_vpu_fpu_isFoldTo1_4(io_in_0_bits_vpu_fpu_isFoldTo1_4),
    .io_in_0_bits_vpu_fpu_isFoldTo1_8(io_in_0_bits_vpu_fpu_isFoldTo1_8),
    .io_in_0_bits_vpu_vxrm(io_in_0_bits_vpu_vxrm),
    .io_in_0_bits_vpu_vuopIdx(io_in_0_bits_vpu_vuopIdx),
    .io_in_0_bits_vpu_lastUop(io_in_0_bits_vpu_lastUop),
    .io_in_0_bits_vpu_vmask(io_in_0_bits_vpu_vmask),
    .io_in_0_bits_vpu_vl(io_in_0_bits_vpu_vl),
    .io_in_0_bits_vpu_nf(io_in_0_bits_vpu_nf),
    .io_in_0_bits_vpu_veew(io_in_0_bits_vpu_veew),
    .io_in_0_bits_vpu_isReverse(io_in_0_bits_vpu_isReverse),
    .io_in_0_bits_vpu_isExt(io_in_0_bits_vpu_isExt),
    .io_in_0_bits_vpu_isNarrow(io_in_0_bits_vpu_isNarrow),
    .io_in_0_bits_vpu_isDstMask(io_in_0_bits_vpu_isDstMask),
    .io_in_0_bits_vpu_isOpMask(io_in_0_bits_vpu_isOpMask),
    .io_in_0_bits_vpu_isMove(io_in_0_bits_vpu_isMove),
    .io_in_0_bits_vpu_isDependOldVd(io_in_0_bits_vpu_isDependOldVd),
    .io_in_0_bits_vpu_isWritePartVd(io_in_0_bits_vpu_isWritePartVd),
    .io_in_0_bits_vpu_isVleff(io_in_0_bits_vpu_isVleff),
    .io_in_0_bits_vlsInstr(io_in_0_bits_vlsInstr),
    .io_in_0_bits_wfflags(io_in_0_bits_wfflags),
    .io_in_0_bits_isMove(io_in_0_bits_isMove),
    .io_in_0_bits_uopIdx(io_in_0_bits_uopIdx),
    .io_in_0_bits_isVset(io_in_0_bits_isVset),
    .io_in_0_bits_firstUop(io_in_0_bits_firstUop),
    .io_in_0_bits_lastUop(io_in_0_bits_lastUop),
    .io_in_0_bits_numUops(io_in_0_bits_numUops),
    .io_in_0_bits_numWB(io_in_0_bits_numWB),
    .io_in_0_bits_commitType(io_in_0_bits_commitType),
    .io_in_0_bits_psrc_0(io_in_0_bits_psrc_0),
    .io_in_0_bits_psrc_1(io_in_0_bits_psrc_1),
    .io_in_0_bits_psrc_2(io_in_0_bits_psrc_2),
    .io_in_0_bits_psrc_3(io_in_0_bits_psrc_3),
    .io_in_0_bits_psrc_4(io_in_0_bits_psrc_4),
    .io_in_0_bits_pdest(io_in_0_bits_pdest),
    .io_in_0_bits_robIdx_flag(io_in_0_bits_robIdx_flag),
    .io_in_0_bits_robIdx_value(io_in_0_bits_robIdx_value),
    .io_in_0_bits_instrSize(io_in_0_bits_instrSize),
    .io_in_0_bits_dirtyFs(io_in_0_bits_dirtyFs),
    .io_in_0_bits_dirtyVs(io_in_0_bits_dirtyVs),
    .io_in_0_bits_traceBlockInPipe_itype(io_in_0_bits_traceBlockInPipe_itype),
    .io_in_0_bits_traceBlockInPipe_iretire(io_in_0_bits_traceBlockInPipe_iretire),
    .io_in_0_bits_traceBlockInPipe_ilastsize(io_in_0_bits_traceBlockInPipe_ilastsize),
    .io_in_0_bits_eliminatedMove(io_in_0_bits_eliminatedMove),
    .io_in_0_bits_snapshot(io_in_0_bits_snapshot),
    .io_in_0_bits_debugInfo_renameTime(io_in_0_bits_debugInfo_renameTime),
    .io_in_0_bits_debug_seqNum_seqNum(io_in_0_bits_debug_seqNum_seqNum),
    .io_in_0_bits_debug_seqNum_uopIdx(io_in_0_bits_debug_seqNum_uopIdx),
    .io_in_0_bits_debug_fuType(io_in_0_bits_debug_fuType),
    .io_in_0_bits_debug_sim_trig(io_in_0_bits_debug_sim_trig),
    .io_in_0_bits_numLsElem(io_in_0_bits_numLsElem),
    .io_out_0_bits_instr(g_l0_io_out_bits_instr),
    .io_out_0_bits_pc(g_l0_io_out_bits_pc),
    .io_out_0_bits_foldpc(g_l0_io_out_bits_foldpc),
    .io_out_0_bits_exceptionVec_0(g_l0_io_out_bits_exceptionVec_0),
    .io_out_0_bits_exceptionVec_1(g_l0_io_out_bits_exceptionVec_1),
    .io_out_0_bits_exceptionVec_2(g_l0_io_out_bits_exceptionVec_2),
    .io_out_0_bits_exceptionVec_3(g_l0_io_out_bits_exceptionVec_3),
    .io_out_0_bits_exceptionVec_4(g_l0_io_out_bits_exceptionVec_4),
    .io_out_0_bits_exceptionVec_5(g_l0_io_out_bits_exceptionVec_5),
    .io_out_0_bits_exceptionVec_6(g_l0_io_out_bits_exceptionVec_6),
    .io_out_0_bits_exceptionVec_7(g_l0_io_out_bits_exceptionVec_7),
    .io_out_0_bits_exceptionVec_8(g_l0_io_out_bits_exceptionVec_8),
    .io_out_0_bits_exceptionVec_9(g_l0_io_out_bits_exceptionVec_9),
    .io_out_0_bits_exceptionVec_10(g_l0_io_out_bits_exceptionVec_10),
    .io_out_0_bits_exceptionVec_11(g_l0_io_out_bits_exceptionVec_11),
    .io_out_0_bits_exceptionVec_12(g_l0_io_out_bits_exceptionVec_12),
    .io_out_0_bits_exceptionVec_13(g_l0_io_out_bits_exceptionVec_13),
    .io_out_0_bits_exceptionVec_14(g_l0_io_out_bits_exceptionVec_14),
    .io_out_0_bits_exceptionVec_15(g_l0_io_out_bits_exceptionVec_15),
    .io_out_0_bits_exceptionVec_16(g_l0_io_out_bits_exceptionVec_16),
    .io_out_0_bits_exceptionVec_17(g_l0_io_out_bits_exceptionVec_17),
    .io_out_0_bits_exceptionVec_18(g_l0_io_out_bits_exceptionVec_18),
    .io_out_0_bits_exceptionVec_19(g_l0_io_out_bits_exceptionVec_19),
    .io_out_0_bits_exceptionVec_20(g_l0_io_out_bits_exceptionVec_20),
    .io_out_0_bits_exceptionVec_21(g_l0_io_out_bits_exceptionVec_21),
    .io_out_0_bits_exceptionVec_22(g_l0_io_out_bits_exceptionVec_22),
    .io_out_0_bits_exceptionVec_23(g_l0_io_out_bits_exceptionVec_23),
    .io_out_0_bits_isFetchMalAddr(g_l0_io_out_bits_isFetchMalAddr),
    .io_out_0_bits_hasException(g_l0_io_out_bits_hasException),
    .io_out_0_bits_trigger(g_l0_io_out_bits_trigger),
    .io_out_0_bits_preDecodeInfo_valid(g_l0_io_out_bits_preDecodeInfo_valid),
    .io_out_0_bits_preDecodeInfo_isRVC(g_l0_io_out_bits_preDecodeInfo_isRVC),
    .io_out_0_bits_preDecodeInfo_brType(g_l0_io_out_bits_preDecodeInfo_brType),
    .io_out_0_bits_preDecodeInfo_isCall(g_l0_io_out_bits_preDecodeInfo_isCall),
    .io_out_0_bits_preDecodeInfo_isRet(g_l0_io_out_bits_preDecodeInfo_isRet),
    .io_out_0_bits_pred_taken(g_l0_io_out_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(g_l0_io_out_bits_crossPageIPFFix),
    .io_out_0_bits_ftqPtr_flag(g_l0_io_out_bits_ftqPtr_flag),
    .io_out_0_bits_ftqPtr_value(g_l0_io_out_bits_ftqPtr_value),
    .io_out_0_bits_ftqOffset(g_l0_io_out_bits_ftqOffset),
    .io_out_0_bits_satpFlushFirstFetchFault(g_l0_io_out_bits_satpFlushFirstFetchFault),
    .io_out_0_bits_srcType_0(g_l0_io_out_bits_srcType_0),
    .io_out_0_bits_srcType_1(g_l0_io_out_bits_srcType_1),
    .io_out_0_bits_srcType_2(g_l0_io_out_bits_srcType_2),
    .io_out_0_bits_srcType_3(g_l0_io_out_bits_srcType_3),
    .io_out_0_bits_srcType_4(g_l0_io_out_bits_srcType_4),
    .io_out_0_bits_ldest(g_l0_io_out_bits_ldest),
    .io_out_0_bits_fuType(g_l0_io_out_bits_fuType),
    .io_out_0_bits_fuOpType(g_l0_io_out_bits_fuOpType),
    .io_out_0_bits_rfWen(g_l0_io_out_bits_rfWen),
    .io_out_0_bits_fpWen(g_l0_io_out_bits_fpWen),
    .io_out_0_bits_vecWen(g_l0_io_out_bits_vecWen),
    .io_out_0_bits_v0Wen(g_l0_io_out_bits_v0Wen),
    .io_out_0_bits_vlWen(g_l0_io_out_bits_vlWen),
    .io_out_0_bits_isXSTrap(g_l0_io_out_bits_isXSTrap),
    .io_out_0_bits_waitForward(g_l0_io_out_bits_waitForward),
    .io_out_0_bits_blockBackward(g_l0_io_out_bits_blockBackward),
    .io_out_0_bits_flushPipe(g_l0_io_out_bits_flushPipe),
    .io_out_0_bits_canRobCompress(g_l0_io_out_bits_canRobCompress),
    .io_out_0_bits_selImm(g_l0_io_out_bits_selImm),
    .io_out_0_bits_imm(g_l0_io_out_bits_imm),
    .io_out_0_bits_fpu_typeTagOut(g_l0_io_out_bits_fpu_typeTagOut),
    .io_out_0_bits_fpu_wflags(g_l0_io_out_bits_fpu_wflags),
    .io_out_0_bits_fpu_typ(g_l0_io_out_bits_fpu_typ),
    .io_out_0_bits_fpu_fmt(g_l0_io_out_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm(g_l0_io_out_bits_fpu_rm),
    .io_out_0_bits_vpu_vill(g_l0_io_out_bits_vpu_vill),
    .io_out_0_bits_vpu_vma(g_l0_io_out_bits_vpu_vma),
    .io_out_0_bits_vpu_vta(g_l0_io_out_bits_vpu_vta),
    .io_out_0_bits_vpu_vsew(g_l0_io_out_bits_vpu_vsew),
    .io_out_0_bits_vpu_vlmul(g_l0_io_out_bits_vpu_vlmul),
    .io_out_0_bits_vpu_specVill(g_l0_io_out_bits_vpu_specVill),
    .io_out_0_bits_vpu_specVma(g_l0_io_out_bits_vpu_specVma),
    .io_out_0_bits_vpu_specVta(g_l0_io_out_bits_vpu_specVta),
    .io_out_0_bits_vpu_specVsew(g_l0_io_out_bits_vpu_specVsew),
    .io_out_0_bits_vpu_specVlmul(g_l0_io_out_bits_vpu_specVlmul),
    .io_out_0_bits_vpu_vm(g_l0_io_out_bits_vpu_vm),
    .io_out_0_bits_vpu_vstart(g_l0_io_out_bits_vpu_vstart),
    .io_out_0_bits_vpu_frm(g_l0_io_out_bits_vpu_frm),
    .io_out_0_bits_vpu_fpu_isFpToVecInst(g_l0_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_0_bits_vpu_fpu_isFP32Instr(g_l0_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_0_bits_vpu_fpu_isFP64Instr(g_l0_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_0_bits_vpu_fpu_isReduction(g_l0_io_out_bits_vpu_fpu_isReduction),
    .io_out_0_bits_vpu_fpu_isFoldTo1_2(g_l0_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_0_bits_vpu_fpu_isFoldTo1_4(g_l0_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_0_bits_vpu_fpu_isFoldTo1_8(g_l0_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_0_bits_vpu_vxrm(g_l0_io_out_bits_vpu_vxrm),
    .io_out_0_bits_vpu_vuopIdx(g_l0_io_out_bits_vpu_vuopIdx),
    .io_out_0_bits_vpu_lastUop(g_l0_io_out_bits_vpu_lastUop),
    .io_out_0_bits_vpu_vmask(g_l0_io_out_bits_vpu_vmask),
    .io_out_0_bits_vpu_vl(g_l0_io_out_bits_vpu_vl),
    .io_out_0_bits_vpu_nf(g_l0_io_out_bits_vpu_nf),
    .io_out_0_bits_vpu_veew(g_l0_io_out_bits_vpu_veew),
    .io_out_0_bits_vpu_isReverse(g_l0_io_out_bits_vpu_isReverse),
    .io_out_0_bits_vpu_isExt(g_l0_io_out_bits_vpu_isExt),
    .io_out_0_bits_vpu_isNarrow(g_l0_io_out_bits_vpu_isNarrow),
    .io_out_0_bits_vpu_isDstMask(g_l0_io_out_bits_vpu_isDstMask),
    .io_out_0_bits_vpu_isOpMask(g_l0_io_out_bits_vpu_isOpMask),
    .io_out_0_bits_vpu_isMove(g_l0_io_out_bits_vpu_isMove),
    .io_out_0_bits_vpu_isDependOldVd(g_l0_io_out_bits_vpu_isDependOldVd),
    .io_out_0_bits_vpu_isWritePartVd(g_l0_io_out_bits_vpu_isWritePartVd),
    .io_out_0_bits_vpu_isVleff(g_l0_io_out_bits_vpu_isVleff),
    .io_out_0_bits_vlsInstr(g_l0_io_out_bits_vlsInstr),
    .io_out_0_bits_wfflags(g_l0_io_out_bits_wfflags),
    .io_out_0_bits_isMove(g_l0_io_out_bits_isMove),
    .io_out_0_bits_uopIdx(g_l0_io_out_bits_uopIdx),
    .io_out_0_bits_isVset(g_l0_io_out_bits_isVset),
    .io_out_0_bits_firstUop(g_l0_io_out_bits_firstUop),
    .io_out_0_bits_lastUop(g_l0_io_out_bits_lastUop),
    .io_out_0_bits_numUops(g_l0_io_out_bits_numUops),
    .io_out_0_bits_numWB(g_l0_io_out_bits_numWB),
    .io_out_0_bits_commitType(g_l0_io_out_bits_commitType),
    .io_out_0_bits_psrc_0(g_l0_io_out_bits_psrc_0),
    .io_out_0_bits_psrc_1(g_l0_io_out_bits_psrc_1),
    .io_out_0_bits_psrc_2(g_l0_io_out_bits_psrc_2),
    .io_out_0_bits_psrc_3(g_l0_io_out_bits_psrc_3),
    .io_out_0_bits_psrc_4(g_l0_io_out_bits_psrc_4),
    .io_out_0_bits_pdest(g_l0_io_out_bits_pdest),
    .io_out_0_bits_robIdx_flag(g_l0_io_out_bits_robIdx_flag),
    .io_out_0_bits_robIdx_value(g_l0_io_out_bits_robIdx_value),
    .io_out_0_bits_instrSize(g_l0_io_out_bits_instrSize),
    .io_out_0_bits_dirtyFs(g_l0_io_out_bits_dirtyFs),
    .io_out_0_bits_dirtyVs(g_l0_io_out_bits_dirtyVs),
    .io_out_0_bits_traceBlockInPipe_itype(g_l0_io_out_bits_traceBlockInPipe_itype),
    .io_out_0_bits_traceBlockInPipe_iretire(g_l0_io_out_bits_traceBlockInPipe_iretire),
    .io_out_0_bits_traceBlockInPipe_ilastsize(g_l0_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_0_bits_eliminatedMove(g_l0_io_out_bits_eliminatedMove),
    .io_out_0_bits_snapshot(g_l0_io_out_bits_snapshot),
    .io_out_0_bits_debugInfo_renameTime(g_l0_io_out_bits_debugInfo_renameTime),
    .io_out_0_bits_debug_seqNum_seqNum(g_l0_io_out_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx(g_l0_io_out_bits_debug_seqNum_uopIdx),
    .io_out_0_bits_debug_fuType(g_l0_io_out_bits_debug_fuType),
    .io_out_0_bits_debug_sim_trig(g_l0_io_out_bits_debug_sim_trig),
    .io_out_0_bits_numLsElem(g_l0_io_out_bits_numLsElem),
    .io_in_1_valid(io_in_1_valid), .io_in_1_ready(g_l1_io_in_ready),
    .io_out_1_ready(io_out_1_ready), .io_out_1_valid(g_l1_io_out_valid),
    .io_in_1_bits_instr(io_in_1_bits_instr),
    .io_in_1_bits_pc(io_in_1_bits_pc),
    .io_in_1_bits_foldpc(io_in_1_bits_foldpc),
    .io_in_1_bits_exceptionVec_0(io_in_1_bits_exceptionVec_0),
    .io_in_1_bits_exceptionVec_1(io_in_1_bits_exceptionVec_1),
    .io_in_1_bits_exceptionVec_2(io_in_1_bits_exceptionVec_2),
    .io_in_1_bits_exceptionVec_3(io_in_1_bits_exceptionVec_3),
    .io_in_1_bits_exceptionVec_4(io_in_1_bits_exceptionVec_4),
    .io_in_1_bits_exceptionVec_5(io_in_1_bits_exceptionVec_5),
    .io_in_1_bits_exceptionVec_6(io_in_1_bits_exceptionVec_6),
    .io_in_1_bits_exceptionVec_7(io_in_1_bits_exceptionVec_7),
    .io_in_1_bits_exceptionVec_8(io_in_1_bits_exceptionVec_8),
    .io_in_1_bits_exceptionVec_9(io_in_1_bits_exceptionVec_9),
    .io_in_1_bits_exceptionVec_10(io_in_1_bits_exceptionVec_10),
    .io_in_1_bits_exceptionVec_11(io_in_1_bits_exceptionVec_11),
    .io_in_1_bits_exceptionVec_12(io_in_1_bits_exceptionVec_12),
    .io_in_1_bits_exceptionVec_13(io_in_1_bits_exceptionVec_13),
    .io_in_1_bits_exceptionVec_14(io_in_1_bits_exceptionVec_14),
    .io_in_1_bits_exceptionVec_15(io_in_1_bits_exceptionVec_15),
    .io_in_1_bits_exceptionVec_16(io_in_1_bits_exceptionVec_16),
    .io_in_1_bits_exceptionVec_17(io_in_1_bits_exceptionVec_17),
    .io_in_1_bits_exceptionVec_18(io_in_1_bits_exceptionVec_18),
    .io_in_1_bits_exceptionVec_19(io_in_1_bits_exceptionVec_19),
    .io_in_1_bits_exceptionVec_20(io_in_1_bits_exceptionVec_20),
    .io_in_1_bits_exceptionVec_21(io_in_1_bits_exceptionVec_21),
    .io_in_1_bits_exceptionVec_22(io_in_1_bits_exceptionVec_22),
    .io_in_1_bits_exceptionVec_23(io_in_1_bits_exceptionVec_23),
    .io_in_1_bits_isFetchMalAddr(io_in_1_bits_isFetchMalAddr),
    .io_in_1_bits_hasException(io_in_1_bits_hasException),
    .io_in_1_bits_trigger(io_in_1_bits_trigger),
    .io_in_1_bits_preDecodeInfo_valid(io_in_1_bits_preDecodeInfo_valid),
    .io_in_1_bits_preDecodeInfo_isRVC(io_in_1_bits_preDecodeInfo_isRVC),
    .io_in_1_bits_preDecodeInfo_brType(io_in_1_bits_preDecodeInfo_brType),
    .io_in_1_bits_preDecodeInfo_isCall(io_in_1_bits_preDecodeInfo_isCall),
    .io_in_1_bits_preDecodeInfo_isRet(io_in_1_bits_preDecodeInfo_isRet),
    .io_in_1_bits_pred_taken(io_in_1_bits_pred_taken),
    .io_in_1_bits_crossPageIPFFix(io_in_1_bits_crossPageIPFFix),
    .io_in_1_bits_ftqPtr_flag(io_in_1_bits_ftqPtr_flag),
    .io_in_1_bits_ftqPtr_value(io_in_1_bits_ftqPtr_value),
    .io_in_1_bits_ftqOffset(io_in_1_bits_ftqOffset),
    .io_in_1_bits_satpFlushFirstFetchFault(io_in_1_bits_satpFlushFirstFetchFault),
    .io_in_1_bits_srcType_0(io_in_1_bits_srcType_0),
    .io_in_1_bits_srcType_1(io_in_1_bits_srcType_1),
    .io_in_1_bits_srcType_2(io_in_1_bits_srcType_2),
    .io_in_1_bits_srcType_3(io_in_1_bits_srcType_3),
    .io_in_1_bits_srcType_4(io_in_1_bits_srcType_4),
    .io_in_1_bits_ldest(io_in_1_bits_ldest),
    .io_in_1_bits_fuType(io_in_1_bits_fuType),
    .io_in_1_bits_fuOpType(io_in_1_bits_fuOpType),
    .io_in_1_bits_rfWen(io_in_1_bits_rfWen),
    .io_in_1_bits_fpWen(io_in_1_bits_fpWen),
    .io_in_1_bits_vecWen(io_in_1_bits_vecWen),
    .io_in_1_bits_v0Wen(io_in_1_bits_v0Wen),
    .io_in_1_bits_vlWen(io_in_1_bits_vlWen),
    .io_in_1_bits_isXSTrap(io_in_1_bits_isXSTrap),
    .io_in_1_bits_waitForward(io_in_1_bits_waitForward),
    .io_in_1_bits_blockBackward(io_in_1_bits_blockBackward),
    .io_in_1_bits_flushPipe(io_in_1_bits_flushPipe),
    .io_in_1_bits_canRobCompress(io_in_1_bits_canRobCompress),
    .io_in_1_bits_selImm(io_in_1_bits_selImm),
    .io_in_1_bits_imm(io_in_1_bits_imm),
    .io_in_1_bits_fpu_typeTagOut(io_in_1_bits_fpu_typeTagOut),
    .io_in_1_bits_fpu_wflags(io_in_1_bits_fpu_wflags),
    .io_in_1_bits_fpu_typ(io_in_1_bits_fpu_typ),
    .io_in_1_bits_fpu_fmt(io_in_1_bits_fpu_fmt),
    .io_in_1_bits_fpu_rm(io_in_1_bits_fpu_rm),
    .io_in_1_bits_vpu_vill(io_in_1_bits_vpu_vill),
    .io_in_1_bits_vpu_vma(io_in_1_bits_vpu_vma),
    .io_in_1_bits_vpu_vta(io_in_1_bits_vpu_vta),
    .io_in_1_bits_vpu_vsew(io_in_1_bits_vpu_vsew),
    .io_in_1_bits_vpu_vlmul(io_in_1_bits_vpu_vlmul),
    .io_in_1_bits_vpu_specVill(io_in_1_bits_vpu_specVill),
    .io_in_1_bits_vpu_specVma(io_in_1_bits_vpu_specVma),
    .io_in_1_bits_vpu_specVta(io_in_1_bits_vpu_specVta),
    .io_in_1_bits_vpu_specVsew(io_in_1_bits_vpu_specVsew),
    .io_in_1_bits_vpu_specVlmul(io_in_1_bits_vpu_specVlmul),
    .io_in_1_bits_vpu_vm(io_in_1_bits_vpu_vm),
    .io_in_1_bits_vpu_vstart(io_in_1_bits_vpu_vstart),
    .io_in_1_bits_vpu_frm(io_in_1_bits_vpu_frm),
    .io_in_1_bits_vpu_fpu_isFpToVecInst(io_in_1_bits_vpu_fpu_isFpToVecInst),
    .io_in_1_bits_vpu_fpu_isFP32Instr(io_in_1_bits_vpu_fpu_isFP32Instr),
    .io_in_1_bits_vpu_fpu_isFP64Instr(io_in_1_bits_vpu_fpu_isFP64Instr),
    .io_in_1_bits_vpu_fpu_isReduction(io_in_1_bits_vpu_fpu_isReduction),
    .io_in_1_bits_vpu_fpu_isFoldTo1_2(io_in_1_bits_vpu_fpu_isFoldTo1_2),
    .io_in_1_bits_vpu_fpu_isFoldTo1_4(io_in_1_bits_vpu_fpu_isFoldTo1_4),
    .io_in_1_bits_vpu_fpu_isFoldTo1_8(io_in_1_bits_vpu_fpu_isFoldTo1_8),
    .io_in_1_bits_vpu_vxrm(io_in_1_bits_vpu_vxrm),
    .io_in_1_bits_vpu_vuopIdx(io_in_1_bits_vpu_vuopIdx),
    .io_in_1_bits_vpu_lastUop(io_in_1_bits_vpu_lastUop),
    .io_in_1_bits_vpu_vmask(io_in_1_bits_vpu_vmask),
    .io_in_1_bits_vpu_vl(io_in_1_bits_vpu_vl),
    .io_in_1_bits_vpu_nf(io_in_1_bits_vpu_nf),
    .io_in_1_bits_vpu_veew(io_in_1_bits_vpu_veew),
    .io_in_1_bits_vpu_isReverse(io_in_1_bits_vpu_isReverse),
    .io_in_1_bits_vpu_isExt(io_in_1_bits_vpu_isExt),
    .io_in_1_bits_vpu_isNarrow(io_in_1_bits_vpu_isNarrow),
    .io_in_1_bits_vpu_isDstMask(io_in_1_bits_vpu_isDstMask),
    .io_in_1_bits_vpu_isOpMask(io_in_1_bits_vpu_isOpMask),
    .io_in_1_bits_vpu_isMove(io_in_1_bits_vpu_isMove),
    .io_in_1_bits_vpu_isDependOldVd(io_in_1_bits_vpu_isDependOldVd),
    .io_in_1_bits_vpu_isWritePartVd(io_in_1_bits_vpu_isWritePartVd),
    .io_in_1_bits_vpu_isVleff(io_in_1_bits_vpu_isVleff),
    .io_in_1_bits_vlsInstr(io_in_1_bits_vlsInstr),
    .io_in_1_bits_wfflags(io_in_1_bits_wfflags),
    .io_in_1_bits_isMove(io_in_1_bits_isMove),
    .io_in_1_bits_uopIdx(io_in_1_bits_uopIdx),
    .io_in_1_bits_isVset(io_in_1_bits_isVset),
    .io_in_1_bits_firstUop(io_in_1_bits_firstUop),
    .io_in_1_bits_lastUop(io_in_1_bits_lastUop),
    .io_in_1_bits_numUops(io_in_1_bits_numUops),
    .io_in_1_bits_numWB(io_in_1_bits_numWB),
    .io_in_1_bits_commitType(io_in_1_bits_commitType),
    .io_in_1_bits_psrc_0(io_in_1_bits_psrc_0),
    .io_in_1_bits_psrc_1(io_in_1_bits_psrc_1),
    .io_in_1_bits_psrc_2(io_in_1_bits_psrc_2),
    .io_in_1_bits_psrc_3(io_in_1_bits_psrc_3),
    .io_in_1_bits_psrc_4(io_in_1_bits_psrc_4),
    .io_in_1_bits_pdest(io_in_1_bits_pdest),
    .io_in_1_bits_robIdx_flag(io_in_1_bits_robIdx_flag),
    .io_in_1_bits_robIdx_value(io_in_1_bits_robIdx_value),
    .io_in_1_bits_instrSize(io_in_1_bits_instrSize),
    .io_in_1_bits_dirtyFs(io_in_1_bits_dirtyFs),
    .io_in_1_bits_dirtyVs(io_in_1_bits_dirtyVs),
    .io_in_1_bits_traceBlockInPipe_itype(io_in_1_bits_traceBlockInPipe_itype),
    .io_in_1_bits_traceBlockInPipe_iretire(io_in_1_bits_traceBlockInPipe_iretire),
    .io_in_1_bits_traceBlockInPipe_ilastsize(io_in_1_bits_traceBlockInPipe_ilastsize),
    .io_in_1_bits_eliminatedMove(io_in_1_bits_eliminatedMove),
    .io_in_1_bits_debugInfo_renameTime(io_in_1_bits_debugInfo_renameTime),
    .io_in_1_bits_debug_seqNum_seqNum(io_in_1_bits_debug_seqNum_seqNum),
    .io_in_1_bits_debug_seqNum_uopIdx(io_in_1_bits_debug_seqNum_uopIdx),
    .io_in_1_bits_debug_fuType(io_in_1_bits_debug_fuType),
    .io_in_1_bits_debug_sim_trig(io_in_1_bits_debug_sim_trig),
    .io_in_1_bits_numLsElem(io_in_1_bits_numLsElem),
    .io_out_1_bits_instr(g_l1_io_out_bits_instr),
    .io_out_1_bits_pc(g_l1_io_out_bits_pc),
    .io_out_1_bits_foldpc(g_l1_io_out_bits_foldpc),
    .io_out_1_bits_exceptionVec_0(g_l1_io_out_bits_exceptionVec_0),
    .io_out_1_bits_exceptionVec_1(g_l1_io_out_bits_exceptionVec_1),
    .io_out_1_bits_exceptionVec_2(g_l1_io_out_bits_exceptionVec_2),
    .io_out_1_bits_exceptionVec_3(g_l1_io_out_bits_exceptionVec_3),
    .io_out_1_bits_exceptionVec_4(g_l1_io_out_bits_exceptionVec_4),
    .io_out_1_bits_exceptionVec_5(g_l1_io_out_bits_exceptionVec_5),
    .io_out_1_bits_exceptionVec_6(g_l1_io_out_bits_exceptionVec_6),
    .io_out_1_bits_exceptionVec_7(g_l1_io_out_bits_exceptionVec_7),
    .io_out_1_bits_exceptionVec_8(g_l1_io_out_bits_exceptionVec_8),
    .io_out_1_bits_exceptionVec_9(g_l1_io_out_bits_exceptionVec_9),
    .io_out_1_bits_exceptionVec_10(g_l1_io_out_bits_exceptionVec_10),
    .io_out_1_bits_exceptionVec_11(g_l1_io_out_bits_exceptionVec_11),
    .io_out_1_bits_exceptionVec_12(g_l1_io_out_bits_exceptionVec_12),
    .io_out_1_bits_exceptionVec_13(g_l1_io_out_bits_exceptionVec_13),
    .io_out_1_bits_exceptionVec_14(g_l1_io_out_bits_exceptionVec_14),
    .io_out_1_bits_exceptionVec_15(g_l1_io_out_bits_exceptionVec_15),
    .io_out_1_bits_exceptionVec_16(g_l1_io_out_bits_exceptionVec_16),
    .io_out_1_bits_exceptionVec_17(g_l1_io_out_bits_exceptionVec_17),
    .io_out_1_bits_exceptionVec_18(g_l1_io_out_bits_exceptionVec_18),
    .io_out_1_bits_exceptionVec_19(g_l1_io_out_bits_exceptionVec_19),
    .io_out_1_bits_exceptionVec_20(g_l1_io_out_bits_exceptionVec_20),
    .io_out_1_bits_exceptionVec_21(g_l1_io_out_bits_exceptionVec_21),
    .io_out_1_bits_exceptionVec_22(g_l1_io_out_bits_exceptionVec_22),
    .io_out_1_bits_exceptionVec_23(g_l1_io_out_bits_exceptionVec_23),
    .io_out_1_bits_isFetchMalAddr(g_l1_io_out_bits_isFetchMalAddr),
    .io_out_1_bits_hasException(g_l1_io_out_bits_hasException),
    .io_out_1_bits_trigger(g_l1_io_out_bits_trigger),
    .io_out_1_bits_preDecodeInfo_valid(g_l1_io_out_bits_preDecodeInfo_valid),
    .io_out_1_bits_preDecodeInfo_isRVC(g_l1_io_out_bits_preDecodeInfo_isRVC),
    .io_out_1_bits_preDecodeInfo_brType(g_l1_io_out_bits_preDecodeInfo_brType),
    .io_out_1_bits_preDecodeInfo_isCall(g_l1_io_out_bits_preDecodeInfo_isCall),
    .io_out_1_bits_preDecodeInfo_isRet(g_l1_io_out_bits_preDecodeInfo_isRet),
    .io_out_1_bits_pred_taken(g_l1_io_out_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(g_l1_io_out_bits_crossPageIPFFix),
    .io_out_1_bits_ftqPtr_flag(g_l1_io_out_bits_ftqPtr_flag),
    .io_out_1_bits_ftqPtr_value(g_l1_io_out_bits_ftqPtr_value),
    .io_out_1_bits_ftqOffset(g_l1_io_out_bits_ftqOffset),
    .io_out_1_bits_satpFlushFirstFetchFault(g_l1_io_out_bits_satpFlushFirstFetchFault),
    .io_out_1_bits_srcType_0(g_l1_io_out_bits_srcType_0),
    .io_out_1_bits_srcType_1(g_l1_io_out_bits_srcType_1),
    .io_out_1_bits_srcType_2(g_l1_io_out_bits_srcType_2),
    .io_out_1_bits_srcType_3(g_l1_io_out_bits_srcType_3),
    .io_out_1_bits_srcType_4(g_l1_io_out_bits_srcType_4),
    .io_out_1_bits_ldest(g_l1_io_out_bits_ldest),
    .io_out_1_bits_fuType(g_l1_io_out_bits_fuType),
    .io_out_1_bits_fuOpType(g_l1_io_out_bits_fuOpType),
    .io_out_1_bits_rfWen(g_l1_io_out_bits_rfWen),
    .io_out_1_bits_fpWen(g_l1_io_out_bits_fpWen),
    .io_out_1_bits_vecWen(g_l1_io_out_bits_vecWen),
    .io_out_1_bits_v0Wen(g_l1_io_out_bits_v0Wen),
    .io_out_1_bits_vlWen(g_l1_io_out_bits_vlWen),
    .io_out_1_bits_isXSTrap(g_l1_io_out_bits_isXSTrap),
    .io_out_1_bits_waitForward(g_l1_io_out_bits_waitForward),
    .io_out_1_bits_blockBackward(g_l1_io_out_bits_blockBackward),
    .io_out_1_bits_flushPipe(g_l1_io_out_bits_flushPipe),
    .io_out_1_bits_canRobCompress(g_l1_io_out_bits_canRobCompress),
    .io_out_1_bits_selImm(g_l1_io_out_bits_selImm),
    .io_out_1_bits_imm(g_l1_io_out_bits_imm),
    .io_out_1_bits_fpu_typeTagOut(g_l1_io_out_bits_fpu_typeTagOut),
    .io_out_1_bits_fpu_wflags(g_l1_io_out_bits_fpu_wflags),
    .io_out_1_bits_fpu_typ(g_l1_io_out_bits_fpu_typ),
    .io_out_1_bits_fpu_fmt(g_l1_io_out_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm(g_l1_io_out_bits_fpu_rm),
    .io_out_1_bits_vpu_vill(g_l1_io_out_bits_vpu_vill),
    .io_out_1_bits_vpu_vma(g_l1_io_out_bits_vpu_vma),
    .io_out_1_bits_vpu_vta(g_l1_io_out_bits_vpu_vta),
    .io_out_1_bits_vpu_vsew(g_l1_io_out_bits_vpu_vsew),
    .io_out_1_bits_vpu_vlmul(g_l1_io_out_bits_vpu_vlmul),
    .io_out_1_bits_vpu_specVill(g_l1_io_out_bits_vpu_specVill),
    .io_out_1_bits_vpu_specVma(g_l1_io_out_bits_vpu_specVma),
    .io_out_1_bits_vpu_specVta(g_l1_io_out_bits_vpu_specVta),
    .io_out_1_bits_vpu_specVsew(g_l1_io_out_bits_vpu_specVsew),
    .io_out_1_bits_vpu_specVlmul(g_l1_io_out_bits_vpu_specVlmul),
    .io_out_1_bits_vpu_vm(g_l1_io_out_bits_vpu_vm),
    .io_out_1_bits_vpu_vstart(g_l1_io_out_bits_vpu_vstart),
    .io_out_1_bits_vpu_frm(g_l1_io_out_bits_vpu_frm),
    .io_out_1_bits_vpu_fpu_isFpToVecInst(g_l1_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_1_bits_vpu_fpu_isFP32Instr(g_l1_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_1_bits_vpu_fpu_isFP64Instr(g_l1_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_1_bits_vpu_fpu_isReduction(g_l1_io_out_bits_vpu_fpu_isReduction),
    .io_out_1_bits_vpu_fpu_isFoldTo1_2(g_l1_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_1_bits_vpu_fpu_isFoldTo1_4(g_l1_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_1_bits_vpu_fpu_isFoldTo1_8(g_l1_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_1_bits_vpu_vxrm(g_l1_io_out_bits_vpu_vxrm),
    .io_out_1_bits_vpu_vuopIdx(g_l1_io_out_bits_vpu_vuopIdx),
    .io_out_1_bits_vpu_lastUop(g_l1_io_out_bits_vpu_lastUop),
    .io_out_1_bits_vpu_vmask(g_l1_io_out_bits_vpu_vmask),
    .io_out_1_bits_vpu_vl(g_l1_io_out_bits_vpu_vl),
    .io_out_1_bits_vpu_nf(g_l1_io_out_bits_vpu_nf),
    .io_out_1_bits_vpu_veew(g_l1_io_out_bits_vpu_veew),
    .io_out_1_bits_vpu_isReverse(g_l1_io_out_bits_vpu_isReverse),
    .io_out_1_bits_vpu_isExt(g_l1_io_out_bits_vpu_isExt),
    .io_out_1_bits_vpu_isNarrow(g_l1_io_out_bits_vpu_isNarrow),
    .io_out_1_bits_vpu_isDstMask(g_l1_io_out_bits_vpu_isDstMask),
    .io_out_1_bits_vpu_isOpMask(g_l1_io_out_bits_vpu_isOpMask),
    .io_out_1_bits_vpu_isMove(g_l1_io_out_bits_vpu_isMove),
    .io_out_1_bits_vpu_isDependOldVd(g_l1_io_out_bits_vpu_isDependOldVd),
    .io_out_1_bits_vpu_isWritePartVd(g_l1_io_out_bits_vpu_isWritePartVd),
    .io_out_1_bits_vpu_isVleff(g_l1_io_out_bits_vpu_isVleff),
    .io_out_1_bits_vlsInstr(g_l1_io_out_bits_vlsInstr),
    .io_out_1_bits_wfflags(g_l1_io_out_bits_wfflags),
    .io_out_1_bits_isMove(g_l1_io_out_bits_isMove),
    .io_out_1_bits_uopIdx(g_l1_io_out_bits_uopIdx),
    .io_out_1_bits_isVset(g_l1_io_out_bits_isVset),
    .io_out_1_bits_firstUop(g_l1_io_out_bits_firstUop),
    .io_out_1_bits_lastUop(g_l1_io_out_bits_lastUop),
    .io_out_1_bits_numUops(g_l1_io_out_bits_numUops),
    .io_out_1_bits_numWB(g_l1_io_out_bits_numWB),
    .io_out_1_bits_commitType(g_l1_io_out_bits_commitType),
    .io_out_1_bits_psrc_0(g_l1_io_out_bits_psrc_0),
    .io_out_1_bits_psrc_1(g_l1_io_out_bits_psrc_1),
    .io_out_1_bits_psrc_2(g_l1_io_out_bits_psrc_2),
    .io_out_1_bits_psrc_3(g_l1_io_out_bits_psrc_3),
    .io_out_1_bits_psrc_4(g_l1_io_out_bits_psrc_4),
    .io_out_1_bits_pdest(g_l1_io_out_bits_pdest),
    .io_out_1_bits_robIdx_flag(g_l1_io_out_bits_robIdx_flag),
    .io_out_1_bits_robIdx_value(g_l1_io_out_bits_robIdx_value),
    .io_out_1_bits_instrSize(g_l1_io_out_bits_instrSize),
    .io_out_1_bits_dirtyFs(g_l1_io_out_bits_dirtyFs),
    .io_out_1_bits_dirtyVs(g_l1_io_out_bits_dirtyVs),
    .io_out_1_bits_traceBlockInPipe_itype(g_l1_io_out_bits_traceBlockInPipe_itype),
    .io_out_1_bits_traceBlockInPipe_iretire(g_l1_io_out_bits_traceBlockInPipe_iretire),
    .io_out_1_bits_traceBlockInPipe_ilastsize(g_l1_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_1_bits_eliminatedMove(g_l1_io_out_bits_eliminatedMove),
    .io_out_1_bits_debugInfo_renameTime(g_l1_io_out_bits_debugInfo_renameTime),
    .io_out_1_bits_debug_seqNum_seqNum(g_l1_io_out_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx(g_l1_io_out_bits_debug_seqNum_uopIdx),
    .io_out_1_bits_debug_fuType(g_l1_io_out_bits_debug_fuType),
    .io_out_1_bits_debug_sim_trig(g_l1_io_out_bits_debug_sim_trig),
    .io_out_1_bits_numLsElem(g_l1_io_out_bits_numLsElem),
    .io_in_2_valid(io_in_2_valid), .io_in_2_ready(g_l2_io_in_ready),
    .io_out_2_ready(io_out_2_ready), .io_out_2_valid(g_l2_io_out_valid),
    .io_in_2_bits_instr(io_in_2_bits_instr),
    .io_in_2_bits_pc(io_in_2_bits_pc),
    .io_in_2_bits_foldpc(io_in_2_bits_foldpc),
    .io_in_2_bits_exceptionVec_0(io_in_2_bits_exceptionVec_0),
    .io_in_2_bits_exceptionVec_1(io_in_2_bits_exceptionVec_1),
    .io_in_2_bits_exceptionVec_2(io_in_2_bits_exceptionVec_2),
    .io_in_2_bits_exceptionVec_3(io_in_2_bits_exceptionVec_3),
    .io_in_2_bits_exceptionVec_4(io_in_2_bits_exceptionVec_4),
    .io_in_2_bits_exceptionVec_5(io_in_2_bits_exceptionVec_5),
    .io_in_2_bits_exceptionVec_6(io_in_2_bits_exceptionVec_6),
    .io_in_2_bits_exceptionVec_7(io_in_2_bits_exceptionVec_7),
    .io_in_2_bits_exceptionVec_8(io_in_2_bits_exceptionVec_8),
    .io_in_2_bits_exceptionVec_9(io_in_2_bits_exceptionVec_9),
    .io_in_2_bits_exceptionVec_10(io_in_2_bits_exceptionVec_10),
    .io_in_2_bits_exceptionVec_11(io_in_2_bits_exceptionVec_11),
    .io_in_2_bits_exceptionVec_12(io_in_2_bits_exceptionVec_12),
    .io_in_2_bits_exceptionVec_13(io_in_2_bits_exceptionVec_13),
    .io_in_2_bits_exceptionVec_14(io_in_2_bits_exceptionVec_14),
    .io_in_2_bits_exceptionVec_15(io_in_2_bits_exceptionVec_15),
    .io_in_2_bits_exceptionVec_16(io_in_2_bits_exceptionVec_16),
    .io_in_2_bits_exceptionVec_17(io_in_2_bits_exceptionVec_17),
    .io_in_2_bits_exceptionVec_18(io_in_2_bits_exceptionVec_18),
    .io_in_2_bits_exceptionVec_19(io_in_2_bits_exceptionVec_19),
    .io_in_2_bits_exceptionVec_20(io_in_2_bits_exceptionVec_20),
    .io_in_2_bits_exceptionVec_21(io_in_2_bits_exceptionVec_21),
    .io_in_2_bits_exceptionVec_22(io_in_2_bits_exceptionVec_22),
    .io_in_2_bits_exceptionVec_23(io_in_2_bits_exceptionVec_23),
    .io_in_2_bits_isFetchMalAddr(io_in_2_bits_isFetchMalAddr),
    .io_in_2_bits_hasException(io_in_2_bits_hasException),
    .io_in_2_bits_trigger(io_in_2_bits_trigger),
    .io_in_2_bits_preDecodeInfo_valid(io_in_2_bits_preDecodeInfo_valid),
    .io_in_2_bits_preDecodeInfo_isRVC(io_in_2_bits_preDecodeInfo_isRVC),
    .io_in_2_bits_preDecodeInfo_brType(io_in_2_bits_preDecodeInfo_brType),
    .io_in_2_bits_preDecodeInfo_isCall(io_in_2_bits_preDecodeInfo_isCall),
    .io_in_2_bits_preDecodeInfo_isRet(io_in_2_bits_preDecodeInfo_isRet),
    .io_in_2_bits_pred_taken(io_in_2_bits_pred_taken),
    .io_in_2_bits_crossPageIPFFix(io_in_2_bits_crossPageIPFFix),
    .io_in_2_bits_ftqPtr_flag(io_in_2_bits_ftqPtr_flag),
    .io_in_2_bits_ftqPtr_value(io_in_2_bits_ftqPtr_value),
    .io_in_2_bits_ftqOffset(io_in_2_bits_ftqOffset),
    .io_in_2_bits_satpFlushFirstFetchFault(io_in_2_bits_satpFlushFirstFetchFault),
    .io_in_2_bits_srcType_0(io_in_2_bits_srcType_0),
    .io_in_2_bits_srcType_1(io_in_2_bits_srcType_1),
    .io_in_2_bits_srcType_2(io_in_2_bits_srcType_2),
    .io_in_2_bits_srcType_3(io_in_2_bits_srcType_3),
    .io_in_2_bits_srcType_4(io_in_2_bits_srcType_4),
    .io_in_2_bits_ldest(io_in_2_bits_ldest),
    .io_in_2_bits_fuType(io_in_2_bits_fuType),
    .io_in_2_bits_fuOpType(io_in_2_bits_fuOpType),
    .io_in_2_bits_rfWen(io_in_2_bits_rfWen),
    .io_in_2_bits_fpWen(io_in_2_bits_fpWen),
    .io_in_2_bits_vecWen(io_in_2_bits_vecWen),
    .io_in_2_bits_v0Wen(io_in_2_bits_v0Wen),
    .io_in_2_bits_vlWen(io_in_2_bits_vlWen),
    .io_in_2_bits_isXSTrap(io_in_2_bits_isXSTrap),
    .io_in_2_bits_waitForward(io_in_2_bits_waitForward),
    .io_in_2_bits_blockBackward(io_in_2_bits_blockBackward),
    .io_in_2_bits_flushPipe(io_in_2_bits_flushPipe),
    .io_in_2_bits_canRobCompress(io_in_2_bits_canRobCompress),
    .io_in_2_bits_selImm(io_in_2_bits_selImm),
    .io_in_2_bits_imm(io_in_2_bits_imm),
    .io_in_2_bits_fpu_typeTagOut(io_in_2_bits_fpu_typeTagOut),
    .io_in_2_bits_fpu_wflags(io_in_2_bits_fpu_wflags),
    .io_in_2_bits_fpu_typ(io_in_2_bits_fpu_typ),
    .io_in_2_bits_fpu_fmt(io_in_2_bits_fpu_fmt),
    .io_in_2_bits_fpu_rm(io_in_2_bits_fpu_rm),
    .io_in_2_bits_vpu_vill(io_in_2_bits_vpu_vill),
    .io_in_2_bits_vpu_vma(io_in_2_bits_vpu_vma),
    .io_in_2_bits_vpu_vta(io_in_2_bits_vpu_vta),
    .io_in_2_bits_vpu_vsew(io_in_2_bits_vpu_vsew),
    .io_in_2_bits_vpu_vlmul(io_in_2_bits_vpu_vlmul),
    .io_in_2_bits_vpu_specVill(io_in_2_bits_vpu_specVill),
    .io_in_2_bits_vpu_specVma(io_in_2_bits_vpu_specVma),
    .io_in_2_bits_vpu_specVta(io_in_2_bits_vpu_specVta),
    .io_in_2_bits_vpu_specVsew(io_in_2_bits_vpu_specVsew),
    .io_in_2_bits_vpu_specVlmul(io_in_2_bits_vpu_specVlmul),
    .io_in_2_bits_vpu_vm(io_in_2_bits_vpu_vm),
    .io_in_2_bits_vpu_vstart(io_in_2_bits_vpu_vstart),
    .io_in_2_bits_vpu_frm(io_in_2_bits_vpu_frm),
    .io_in_2_bits_vpu_fpu_isFpToVecInst(io_in_2_bits_vpu_fpu_isFpToVecInst),
    .io_in_2_bits_vpu_fpu_isFP32Instr(io_in_2_bits_vpu_fpu_isFP32Instr),
    .io_in_2_bits_vpu_fpu_isFP64Instr(io_in_2_bits_vpu_fpu_isFP64Instr),
    .io_in_2_bits_vpu_fpu_isReduction(io_in_2_bits_vpu_fpu_isReduction),
    .io_in_2_bits_vpu_fpu_isFoldTo1_2(io_in_2_bits_vpu_fpu_isFoldTo1_2),
    .io_in_2_bits_vpu_fpu_isFoldTo1_4(io_in_2_bits_vpu_fpu_isFoldTo1_4),
    .io_in_2_bits_vpu_fpu_isFoldTo1_8(io_in_2_bits_vpu_fpu_isFoldTo1_8),
    .io_in_2_bits_vpu_vxrm(io_in_2_bits_vpu_vxrm),
    .io_in_2_bits_vpu_vuopIdx(io_in_2_bits_vpu_vuopIdx),
    .io_in_2_bits_vpu_lastUop(io_in_2_bits_vpu_lastUop),
    .io_in_2_bits_vpu_vmask(io_in_2_bits_vpu_vmask),
    .io_in_2_bits_vpu_vl(io_in_2_bits_vpu_vl),
    .io_in_2_bits_vpu_nf(io_in_2_bits_vpu_nf),
    .io_in_2_bits_vpu_veew(io_in_2_bits_vpu_veew),
    .io_in_2_bits_vpu_isReverse(io_in_2_bits_vpu_isReverse),
    .io_in_2_bits_vpu_isExt(io_in_2_bits_vpu_isExt),
    .io_in_2_bits_vpu_isNarrow(io_in_2_bits_vpu_isNarrow),
    .io_in_2_bits_vpu_isDstMask(io_in_2_bits_vpu_isDstMask),
    .io_in_2_bits_vpu_isOpMask(io_in_2_bits_vpu_isOpMask),
    .io_in_2_bits_vpu_isMove(io_in_2_bits_vpu_isMove),
    .io_in_2_bits_vpu_isDependOldVd(io_in_2_bits_vpu_isDependOldVd),
    .io_in_2_bits_vpu_isWritePartVd(io_in_2_bits_vpu_isWritePartVd),
    .io_in_2_bits_vpu_isVleff(io_in_2_bits_vpu_isVleff),
    .io_in_2_bits_vlsInstr(io_in_2_bits_vlsInstr),
    .io_in_2_bits_wfflags(io_in_2_bits_wfflags),
    .io_in_2_bits_isMove(io_in_2_bits_isMove),
    .io_in_2_bits_uopIdx(io_in_2_bits_uopIdx),
    .io_in_2_bits_isVset(io_in_2_bits_isVset),
    .io_in_2_bits_firstUop(io_in_2_bits_firstUop),
    .io_in_2_bits_lastUop(io_in_2_bits_lastUop),
    .io_in_2_bits_numUops(io_in_2_bits_numUops),
    .io_in_2_bits_numWB(io_in_2_bits_numWB),
    .io_in_2_bits_commitType(io_in_2_bits_commitType),
    .io_in_2_bits_psrc_0(io_in_2_bits_psrc_0),
    .io_in_2_bits_psrc_1(io_in_2_bits_psrc_1),
    .io_in_2_bits_psrc_2(io_in_2_bits_psrc_2),
    .io_in_2_bits_psrc_3(io_in_2_bits_psrc_3),
    .io_in_2_bits_psrc_4(io_in_2_bits_psrc_4),
    .io_in_2_bits_pdest(io_in_2_bits_pdest),
    .io_in_2_bits_robIdx_flag(io_in_2_bits_robIdx_flag),
    .io_in_2_bits_robIdx_value(io_in_2_bits_robIdx_value),
    .io_in_2_bits_instrSize(io_in_2_bits_instrSize),
    .io_in_2_bits_dirtyFs(io_in_2_bits_dirtyFs),
    .io_in_2_bits_dirtyVs(io_in_2_bits_dirtyVs),
    .io_in_2_bits_traceBlockInPipe_itype(io_in_2_bits_traceBlockInPipe_itype),
    .io_in_2_bits_traceBlockInPipe_iretire(io_in_2_bits_traceBlockInPipe_iretire),
    .io_in_2_bits_traceBlockInPipe_ilastsize(io_in_2_bits_traceBlockInPipe_ilastsize),
    .io_in_2_bits_eliminatedMove(io_in_2_bits_eliminatedMove),
    .io_in_2_bits_debugInfo_renameTime(io_in_2_bits_debugInfo_renameTime),
    .io_in_2_bits_debug_seqNum_seqNum(io_in_2_bits_debug_seqNum_seqNum),
    .io_in_2_bits_debug_seqNum_uopIdx(io_in_2_bits_debug_seqNum_uopIdx),
    .io_in_2_bits_debug_fuType(io_in_2_bits_debug_fuType),
    .io_in_2_bits_debug_sim_trig(io_in_2_bits_debug_sim_trig),
    .io_in_2_bits_numLsElem(io_in_2_bits_numLsElem),
    .io_out_2_bits_instr(g_l2_io_out_bits_instr),
    .io_out_2_bits_pc(g_l2_io_out_bits_pc),
    .io_out_2_bits_foldpc(g_l2_io_out_bits_foldpc),
    .io_out_2_bits_exceptionVec_0(g_l2_io_out_bits_exceptionVec_0),
    .io_out_2_bits_exceptionVec_1(g_l2_io_out_bits_exceptionVec_1),
    .io_out_2_bits_exceptionVec_2(g_l2_io_out_bits_exceptionVec_2),
    .io_out_2_bits_exceptionVec_3(g_l2_io_out_bits_exceptionVec_3),
    .io_out_2_bits_exceptionVec_4(g_l2_io_out_bits_exceptionVec_4),
    .io_out_2_bits_exceptionVec_5(g_l2_io_out_bits_exceptionVec_5),
    .io_out_2_bits_exceptionVec_6(g_l2_io_out_bits_exceptionVec_6),
    .io_out_2_bits_exceptionVec_7(g_l2_io_out_bits_exceptionVec_7),
    .io_out_2_bits_exceptionVec_8(g_l2_io_out_bits_exceptionVec_8),
    .io_out_2_bits_exceptionVec_9(g_l2_io_out_bits_exceptionVec_9),
    .io_out_2_bits_exceptionVec_10(g_l2_io_out_bits_exceptionVec_10),
    .io_out_2_bits_exceptionVec_11(g_l2_io_out_bits_exceptionVec_11),
    .io_out_2_bits_exceptionVec_12(g_l2_io_out_bits_exceptionVec_12),
    .io_out_2_bits_exceptionVec_13(g_l2_io_out_bits_exceptionVec_13),
    .io_out_2_bits_exceptionVec_14(g_l2_io_out_bits_exceptionVec_14),
    .io_out_2_bits_exceptionVec_15(g_l2_io_out_bits_exceptionVec_15),
    .io_out_2_bits_exceptionVec_16(g_l2_io_out_bits_exceptionVec_16),
    .io_out_2_bits_exceptionVec_17(g_l2_io_out_bits_exceptionVec_17),
    .io_out_2_bits_exceptionVec_18(g_l2_io_out_bits_exceptionVec_18),
    .io_out_2_bits_exceptionVec_19(g_l2_io_out_bits_exceptionVec_19),
    .io_out_2_bits_exceptionVec_20(g_l2_io_out_bits_exceptionVec_20),
    .io_out_2_bits_exceptionVec_21(g_l2_io_out_bits_exceptionVec_21),
    .io_out_2_bits_exceptionVec_22(g_l2_io_out_bits_exceptionVec_22),
    .io_out_2_bits_exceptionVec_23(g_l2_io_out_bits_exceptionVec_23),
    .io_out_2_bits_isFetchMalAddr(g_l2_io_out_bits_isFetchMalAddr),
    .io_out_2_bits_hasException(g_l2_io_out_bits_hasException),
    .io_out_2_bits_trigger(g_l2_io_out_bits_trigger),
    .io_out_2_bits_preDecodeInfo_valid(g_l2_io_out_bits_preDecodeInfo_valid),
    .io_out_2_bits_preDecodeInfo_isRVC(g_l2_io_out_bits_preDecodeInfo_isRVC),
    .io_out_2_bits_preDecodeInfo_brType(g_l2_io_out_bits_preDecodeInfo_brType),
    .io_out_2_bits_preDecodeInfo_isCall(g_l2_io_out_bits_preDecodeInfo_isCall),
    .io_out_2_bits_preDecodeInfo_isRet(g_l2_io_out_bits_preDecodeInfo_isRet),
    .io_out_2_bits_pred_taken(g_l2_io_out_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(g_l2_io_out_bits_crossPageIPFFix),
    .io_out_2_bits_ftqPtr_flag(g_l2_io_out_bits_ftqPtr_flag),
    .io_out_2_bits_ftqPtr_value(g_l2_io_out_bits_ftqPtr_value),
    .io_out_2_bits_ftqOffset(g_l2_io_out_bits_ftqOffset),
    .io_out_2_bits_satpFlushFirstFetchFault(g_l2_io_out_bits_satpFlushFirstFetchFault),
    .io_out_2_bits_srcType_0(g_l2_io_out_bits_srcType_0),
    .io_out_2_bits_srcType_1(g_l2_io_out_bits_srcType_1),
    .io_out_2_bits_srcType_2(g_l2_io_out_bits_srcType_2),
    .io_out_2_bits_srcType_3(g_l2_io_out_bits_srcType_3),
    .io_out_2_bits_srcType_4(g_l2_io_out_bits_srcType_4),
    .io_out_2_bits_ldest(g_l2_io_out_bits_ldest),
    .io_out_2_bits_fuType(g_l2_io_out_bits_fuType),
    .io_out_2_bits_fuOpType(g_l2_io_out_bits_fuOpType),
    .io_out_2_bits_rfWen(g_l2_io_out_bits_rfWen),
    .io_out_2_bits_fpWen(g_l2_io_out_bits_fpWen),
    .io_out_2_bits_vecWen(g_l2_io_out_bits_vecWen),
    .io_out_2_bits_v0Wen(g_l2_io_out_bits_v0Wen),
    .io_out_2_bits_vlWen(g_l2_io_out_bits_vlWen),
    .io_out_2_bits_isXSTrap(g_l2_io_out_bits_isXSTrap),
    .io_out_2_bits_waitForward(g_l2_io_out_bits_waitForward),
    .io_out_2_bits_blockBackward(g_l2_io_out_bits_blockBackward),
    .io_out_2_bits_flushPipe(g_l2_io_out_bits_flushPipe),
    .io_out_2_bits_canRobCompress(g_l2_io_out_bits_canRobCompress),
    .io_out_2_bits_selImm(g_l2_io_out_bits_selImm),
    .io_out_2_bits_imm(g_l2_io_out_bits_imm),
    .io_out_2_bits_fpu_typeTagOut(g_l2_io_out_bits_fpu_typeTagOut),
    .io_out_2_bits_fpu_wflags(g_l2_io_out_bits_fpu_wflags),
    .io_out_2_bits_fpu_typ(g_l2_io_out_bits_fpu_typ),
    .io_out_2_bits_fpu_fmt(g_l2_io_out_bits_fpu_fmt),
    .io_out_2_bits_fpu_rm(g_l2_io_out_bits_fpu_rm),
    .io_out_2_bits_vpu_vill(g_l2_io_out_bits_vpu_vill),
    .io_out_2_bits_vpu_vma(g_l2_io_out_bits_vpu_vma),
    .io_out_2_bits_vpu_vta(g_l2_io_out_bits_vpu_vta),
    .io_out_2_bits_vpu_vsew(g_l2_io_out_bits_vpu_vsew),
    .io_out_2_bits_vpu_vlmul(g_l2_io_out_bits_vpu_vlmul),
    .io_out_2_bits_vpu_specVill(g_l2_io_out_bits_vpu_specVill),
    .io_out_2_bits_vpu_specVma(g_l2_io_out_bits_vpu_specVma),
    .io_out_2_bits_vpu_specVta(g_l2_io_out_bits_vpu_specVta),
    .io_out_2_bits_vpu_specVsew(g_l2_io_out_bits_vpu_specVsew),
    .io_out_2_bits_vpu_specVlmul(g_l2_io_out_bits_vpu_specVlmul),
    .io_out_2_bits_vpu_vm(g_l2_io_out_bits_vpu_vm),
    .io_out_2_bits_vpu_vstart(g_l2_io_out_bits_vpu_vstart),
    .io_out_2_bits_vpu_frm(g_l2_io_out_bits_vpu_frm),
    .io_out_2_bits_vpu_fpu_isFpToVecInst(g_l2_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_2_bits_vpu_fpu_isFP32Instr(g_l2_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_2_bits_vpu_fpu_isFP64Instr(g_l2_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_2_bits_vpu_fpu_isReduction(g_l2_io_out_bits_vpu_fpu_isReduction),
    .io_out_2_bits_vpu_fpu_isFoldTo1_2(g_l2_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_2_bits_vpu_fpu_isFoldTo1_4(g_l2_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_2_bits_vpu_fpu_isFoldTo1_8(g_l2_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_2_bits_vpu_vxrm(g_l2_io_out_bits_vpu_vxrm),
    .io_out_2_bits_vpu_vuopIdx(g_l2_io_out_bits_vpu_vuopIdx),
    .io_out_2_bits_vpu_lastUop(g_l2_io_out_bits_vpu_lastUop),
    .io_out_2_bits_vpu_vmask(g_l2_io_out_bits_vpu_vmask),
    .io_out_2_bits_vpu_vl(g_l2_io_out_bits_vpu_vl),
    .io_out_2_bits_vpu_nf(g_l2_io_out_bits_vpu_nf),
    .io_out_2_bits_vpu_veew(g_l2_io_out_bits_vpu_veew),
    .io_out_2_bits_vpu_isReverse(g_l2_io_out_bits_vpu_isReverse),
    .io_out_2_bits_vpu_isExt(g_l2_io_out_bits_vpu_isExt),
    .io_out_2_bits_vpu_isNarrow(g_l2_io_out_bits_vpu_isNarrow),
    .io_out_2_bits_vpu_isDstMask(g_l2_io_out_bits_vpu_isDstMask),
    .io_out_2_bits_vpu_isOpMask(g_l2_io_out_bits_vpu_isOpMask),
    .io_out_2_bits_vpu_isMove(g_l2_io_out_bits_vpu_isMove),
    .io_out_2_bits_vpu_isDependOldVd(g_l2_io_out_bits_vpu_isDependOldVd),
    .io_out_2_bits_vpu_isWritePartVd(g_l2_io_out_bits_vpu_isWritePartVd),
    .io_out_2_bits_vpu_isVleff(g_l2_io_out_bits_vpu_isVleff),
    .io_out_2_bits_vlsInstr(g_l2_io_out_bits_vlsInstr),
    .io_out_2_bits_wfflags(g_l2_io_out_bits_wfflags),
    .io_out_2_bits_isMove(g_l2_io_out_bits_isMove),
    .io_out_2_bits_uopIdx(g_l2_io_out_bits_uopIdx),
    .io_out_2_bits_isVset(g_l2_io_out_bits_isVset),
    .io_out_2_bits_firstUop(g_l2_io_out_bits_firstUop),
    .io_out_2_bits_lastUop(g_l2_io_out_bits_lastUop),
    .io_out_2_bits_numUops(g_l2_io_out_bits_numUops),
    .io_out_2_bits_numWB(g_l2_io_out_bits_numWB),
    .io_out_2_bits_commitType(g_l2_io_out_bits_commitType),
    .io_out_2_bits_psrc_0(g_l2_io_out_bits_psrc_0),
    .io_out_2_bits_psrc_1(g_l2_io_out_bits_psrc_1),
    .io_out_2_bits_psrc_2(g_l2_io_out_bits_psrc_2),
    .io_out_2_bits_psrc_3(g_l2_io_out_bits_psrc_3),
    .io_out_2_bits_psrc_4(g_l2_io_out_bits_psrc_4),
    .io_out_2_bits_pdest(g_l2_io_out_bits_pdest),
    .io_out_2_bits_robIdx_flag(g_l2_io_out_bits_robIdx_flag),
    .io_out_2_bits_robIdx_value(g_l2_io_out_bits_robIdx_value),
    .io_out_2_bits_instrSize(g_l2_io_out_bits_instrSize),
    .io_out_2_bits_dirtyFs(g_l2_io_out_bits_dirtyFs),
    .io_out_2_bits_dirtyVs(g_l2_io_out_bits_dirtyVs),
    .io_out_2_bits_traceBlockInPipe_itype(g_l2_io_out_bits_traceBlockInPipe_itype),
    .io_out_2_bits_traceBlockInPipe_iretire(g_l2_io_out_bits_traceBlockInPipe_iretire),
    .io_out_2_bits_traceBlockInPipe_ilastsize(g_l2_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_2_bits_eliminatedMove(g_l2_io_out_bits_eliminatedMove),
    .io_out_2_bits_debugInfo_renameTime(g_l2_io_out_bits_debugInfo_renameTime),
    .io_out_2_bits_debug_seqNum_seqNum(g_l2_io_out_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx(g_l2_io_out_bits_debug_seqNum_uopIdx),
    .io_out_2_bits_debug_fuType(g_l2_io_out_bits_debug_fuType),
    .io_out_2_bits_debug_sim_trig(g_l2_io_out_bits_debug_sim_trig),
    .io_out_2_bits_numLsElem(g_l2_io_out_bits_numLsElem),
    .io_in_3_valid(io_in_3_valid), .io_in_3_ready(g_l3_io_in_ready),
    .io_out_3_ready(io_out_3_ready), .io_out_3_valid(g_l3_io_out_valid),
    .io_in_3_bits_instr(io_in_3_bits_instr),
    .io_in_3_bits_pc(io_in_3_bits_pc),
    .io_in_3_bits_foldpc(io_in_3_bits_foldpc),
    .io_in_3_bits_exceptionVec_0(io_in_3_bits_exceptionVec_0),
    .io_in_3_bits_exceptionVec_1(io_in_3_bits_exceptionVec_1),
    .io_in_3_bits_exceptionVec_2(io_in_3_bits_exceptionVec_2),
    .io_in_3_bits_exceptionVec_3(io_in_3_bits_exceptionVec_3),
    .io_in_3_bits_exceptionVec_4(io_in_3_bits_exceptionVec_4),
    .io_in_3_bits_exceptionVec_5(io_in_3_bits_exceptionVec_5),
    .io_in_3_bits_exceptionVec_6(io_in_3_bits_exceptionVec_6),
    .io_in_3_bits_exceptionVec_7(io_in_3_bits_exceptionVec_7),
    .io_in_3_bits_exceptionVec_8(io_in_3_bits_exceptionVec_8),
    .io_in_3_bits_exceptionVec_9(io_in_3_bits_exceptionVec_9),
    .io_in_3_bits_exceptionVec_10(io_in_3_bits_exceptionVec_10),
    .io_in_3_bits_exceptionVec_11(io_in_3_bits_exceptionVec_11),
    .io_in_3_bits_exceptionVec_12(io_in_3_bits_exceptionVec_12),
    .io_in_3_bits_exceptionVec_13(io_in_3_bits_exceptionVec_13),
    .io_in_3_bits_exceptionVec_14(io_in_3_bits_exceptionVec_14),
    .io_in_3_bits_exceptionVec_15(io_in_3_bits_exceptionVec_15),
    .io_in_3_bits_exceptionVec_16(io_in_3_bits_exceptionVec_16),
    .io_in_3_bits_exceptionVec_17(io_in_3_bits_exceptionVec_17),
    .io_in_3_bits_exceptionVec_18(io_in_3_bits_exceptionVec_18),
    .io_in_3_bits_exceptionVec_19(io_in_3_bits_exceptionVec_19),
    .io_in_3_bits_exceptionVec_20(io_in_3_bits_exceptionVec_20),
    .io_in_3_bits_exceptionVec_21(io_in_3_bits_exceptionVec_21),
    .io_in_3_bits_exceptionVec_22(io_in_3_bits_exceptionVec_22),
    .io_in_3_bits_exceptionVec_23(io_in_3_bits_exceptionVec_23),
    .io_in_3_bits_isFetchMalAddr(io_in_3_bits_isFetchMalAddr),
    .io_in_3_bits_hasException(io_in_3_bits_hasException),
    .io_in_3_bits_trigger(io_in_3_bits_trigger),
    .io_in_3_bits_preDecodeInfo_valid(io_in_3_bits_preDecodeInfo_valid),
    .io_in_3_bits_preDecodeInfo_isRVC(io_in_3_bits_preDecodeInfo_isRVC),
    .io_in_3_bits_preDecodeInfo_brType(io_in_3_bits_preDecodeInfo_brType),
    .io_in_3_bits_preDecodeInfo_isCall(io_in_3_bits_preDecodeInfo_isCall),
    .io_in_3_bits_preDecodeInfo_isRet(io_in_3_bits_preDecodeInfo_isRet),
    .io_in_3_bits_pred_taken(io_in_3_bits_pred_taken),
    .io_in_3_bits_crossPageIPFFix(io_in_3_bits_crossPageIPFFix),
    .io_in_3_bits_ftqPtr_flag(io_in_3_bits_ftqPtr_flag),
    .io_in_3_bits_ftqPtr_value(io_in_3_bits_ftqPtr_value),
    .io_in_3_bits_ftqOffset(io_in_3_bits_ftqOffset),
    .io_in_3_bits_satpFlushFirstFetchFault(io_in_3_bits_satpFlushFirstFetchFault),
    .io_in_3_bits_srcType_0(io_in_3_bits_srcType_0),
    .io_in_3_bits_srcType_1(io_in_3_bits_srcType_1),
    .io_in_3_bits_srcType_2(io_in_3_bits_srcType_2),
    .io_in_3_bits_srcType_3(io_in_3_bits_srcType_3),
    .io_in_3_bits_srcType_4(io_in_3_bits_srcType_4),
    .io_in_3_bits_ldest(io_in_3_bits_ldest),
    .io_in_3_bits_fuType(io_in_3_bits_fuType),
    .io_in_3_bits_fuOpType(io_in_3_bits_fuOpType),
    .io_in_3_bits_rfWen(io_in_3_bits_rfWen),
    .io_in_3_bits_fpWen(io_in_3_bits_fpWen),
    .io_in_3_bits_vecWen(io_in_3_bits_vecWen),
    .io_in_3_bits_v0Wen(io_in_3_bits_v0Wen),
    .io_in_3_bits_vlWen(io_in_3_bits_vlWen),
    .io_in_3_bits_isXSTrap(io_in_3_bits_isXSTrap),
    .io_in_3_bits_waitForward(io_in_3_bits_waitForward),
    .io_in_3_bits_blockBackward(io_in_3_bits_blockBackward),
    .io_in_3_bits_flushPipe(io_in_3_bits_flushPipe),
    .io_in_3_bits_canRobCompress(io_in_3_bits_canRobCompress),
    .io_in_3_bits_selImm(io_in_3_bits_selImm),
    .io_in_3_bits_imm(io_in_3_bits_imm),
    .io_in_3_bits_fpu_typeTagOut(io_in_3_bits_fpu_typeTagOut),
    .io_in_3_bits_fpu_wflags(io_in_3_bits_fpu_wflags),
    .io_in_3_bits_fpu_typ(io_in_3_bits_fpu_typ),
    .io_in_3_bits_fpu_fmt(io_in_3_bits_fpu_fmt),
    .io_in_3_bits_fpu_rm(io_in_3_bits_fpu_rm),
    .io_in_3_bits_vpu_vill(io_in_3_bits_vpu_vill),
    .io_in_3_bits_vpu_vma(io_in_3_bits_vpu_vma),
    .io_in_3_bits_vpu_vta(io_in_3_bits_vpu_vta),
    .io_in_3_bits_vpu_vsew(io_in_3_bits_vpu_vsew),
    .io_in_3_bits_vpu_vlmul(io_in_3_bits_vpu_vlmul),
    .io_in_3_bits_vpu_specVill(io_in_3_bits_vpu_specVill),
    .io_in_3_bits_vpu_specVma(io_in_3_bits_vpu_specVma),
    .io_in_3_bits_vpu_specVta(io_in_3_bits_vpu_specVta),
    .io_in_3_bits_vpu_specVsew(io_in_3_bits_vpu_specVsew),
    .io_in_3_bits_vpu_specVlmul(io_in_3_bits_vpu_specVlmul),
    .io_in_3_bits_vpu_vm(io_in_3_bits_vpu_vm),
    .io_in_3_bits_vpu_vstart(io_in_3_bits_vpu_vstart),
    .io_in_3_bits_vpu_frm(io_in_3_bits_vpu_frm),
    .io_in_3_bits_vpu_fpu_isFpToVecInst(io_in_3_bits_vpu_fpu_isFpToVecInst),
    .io_in_3_bits_vpu_fpu_isFP32Instr(io_in_3_bits_vpu_fpu_isFP32Instr),
    .io_in_3_bits_vpu_fpu_isFP64Instr(io_in_3_bits_vpu_fpu_isFP64Instr),
    .io_in_3_bits_vpu_fpu_isReduction(io_in_3_bits_vpu_fpu_isReduction),
    .io_in_3_bits_vpu_fpu_isFoldTo1_2(io_in_3_bits_vpu_fpu_isFoldTo1_2),
    .io_in_3_bits_vpu_fpu_isFoldTo1_4(io_in_3_bits_vpu_fpu_isFoldTo1_4),
    .io_in_3_bits_vpu_fpu_isFoldTo1_8(io_in_3_bits_vpu_fpu_isFoldTo1_8),
    .io_in_3_bits_vpu_vxrm(io_in_3_bits_vpu_vxrm),
    .io_in_3_bits_vpu_vuopIdx(io_in_3_bits_vpu_vuopIdx),
    .io_in_3_bits_vpu_lastUop(io_in_3_bits_vpu_lastUop),
    .io_in_3_bits_vpu_vmask(io_in_3_bits_vpu_vmask),
    .io_in_3_bits_vpu_vl(io_in_3_bits_vpu_vl),
    .io_in_3_bits_vpu_nf(io_in_3_bits_vpu_nf),
    .io_in_3_bits_vpu_veew(io_in_3_bits_vpu_veew),
    .io_in_3_bits_vpu_isReverse(io_in_3_bits_vpu_isReverse),
    .io_in_3_bits_vpu_isExt(io_in_3_bits_vpu_isExt),
    .io_in_3_bits_vpu_isNarrow(io_in_3_bits_vpu_isNarrow),
    .io_in_3_bits_vpu_isDstMask(io_in_3_bits_vpu_isDstMask),
    .io_in_3_bits_vpu_isOpMask(io_in_3_bits_vpu_isOpMask),
    .io_in_3_bits_vpu_isMove(io_in_3_bits_vpu_isMove),
    .io_in_3_bits_vpu_isDependOldVd(io_in_3_bits_vpu_isDependOldVd),
    .io_in_3_bits_vpu_isWritePartVd(io_in_3_bits_vpu_isWritePartVd),
    .io_in_3_bits_vpu_isVleff(io_in_3_bits_vpu_isVleff),
    .io_in_3_bits_vlsInstr(io_in_3_bits_vlsInstr),
    .io_in_3_bits_wfflags(io_in_3_bits_wfflags),
    .io_in_3_bits_isMove(io_in_3_bits_isMove),
    .io_in_3_bits_uopIdx(io_in_3_bits_uopIdx),
    .io_in_3_bits_isVset(io_in_3_bits_isVset),
    .io_in_3_bits_firstUop(io_in_3_bits_firstUop),
    .io_in_3_bits_lastUop(io_in_3_bits_lastUop),
    .io_in_3_bits_numUops(io_in_3_bits_numUops),
    .io_in_3_bits_numWB(io_in_3_bits_numWB),
    .io_in_3_bits_commitType(io_in_3_bits_commitType),
    .io_in_3_bits_psrc_0(io_in_3_bits_psrc_0),
    .io_in_3_bits_psrc_1(io_in_3_bits_psrc_1),
    .io_in_3_bits_psrc_2(io_in_3_bits_psrc_2),
    .io_in_3_bits_psrc_3(io_in_3_bits_psrc_3),
    .io_in_3_bits_psrc_4(io_in_3_bits_psrc_4),
    .io_in_3_bits_pdest(io_in_3_bits_pdest),
    .io_in_3_bits_robIdx_flag(io_in_3_bits_robIdx_flag),
    .io_in_3_bits_robIdx_value(io_in_3_bits_robIdx_value),
    .io_in_3_bits_instrSize(io_in_3_bits_instrSize),
    .io_in_3_bits_dirtyFs(io_in_3_bits_dirtyFs),
    .io_in_3_bits_dirtyVs(io_in_3_bits_dirtyVs),
    .io_in_3_bits_traceBlockInPipe_itype(io_in_3_bits_traceBlockInPipe_itype),
    .io_in_3_bits_traceBlockInPipe_iretire(io_in_3_bits_traceBlockInPipe_iretire),
    .io_in_3_bits_traceBlockInPipe_ilastsize(io_in_3_bits_traceBlockInPipe_ilastsize),
    .io_in_3_bits_eliminatedMove(io_in_3_bits_eliminatedMove),
    .io_in_3_bits_debugInfo_renameTime(io_in_3_bits_debugInfo_renameTime),
    .io_in_3_bits_debug_seqNum_seqNum(io_in_3_bits_debug_seqNum_seqNum),
    .io_in_3_bits_debug_seqNum_uopIdx(io_in_3_bits_debug_seqNum_uopIdx),
    .io_in_3_bits_debug_fuType(io_in_3_bits_debug_fuType),
    .io_in_3_bits_debug_sim_trig(io_in_3_bits_debug_sim_trig),
    .io_in_3_bits_numLsElem(io_in_3_bits_numLsElem),
    .io_out_3_bits_instr(g_l3_io_out_bits_instr),
    .io_out_3_bits_pc(g_l3_io_out_bits_pc),
    .io_out_3_bits_foldpc(g_l3_io_out_bits_foldpc),
    .io_out_3_bits_exceptionVec_0(g_l3_io_out_bits_exceptionVec_0),
    .io_out_3_bits_exceptionVec_1(g_l3_io_out_bits_exceptionVec_1),
    .io_out_3_bits_exceptionVec_2(g_l3_io_out_bits_exceptionVec_2),
    .io_out_3_bits_exceptionVec_3(g_l3_io_out_bits_exceptionVec_3),
    .io_out_3_bits_exceptionVec_4(g_l3_io_out_bits_exceptionVec_4),
    .io_out_3_bits_exceptionVec_5(g_l3_io_out_bits_exceptionVec_5),
    .io_out_3_bits_exceptionVec_6(g_l3_io_out_bits_exceptionVec_6),
    .io_out_3_bits_exceptionVec_7(g_l3_io_out_bits_exceptionVec_7),
    .io_out_3_bits_exceptionVec_8(g_l3_io_out_bits_exceptionVec_8),
    .io_out_3_bits_exceptionVec_9(g_l3_io_out_bits_exceptionVec_9),
    .io_out_3_bits_exceptionVec_10(g_l3_io_out_bits_exceptionVec_10),
    .io_out_3_bits_exceptionVec_11(g_l3_io_out_bits_exceptionVec_11),
    .io_out_3_bits_exceptionVec_12(g_l3_io_out_bits_exceptionVec_12),
    .io_out_3_bits_exceptionVec_13(g_l3_io_out_bits_exceptionVec_13),
    .io_out_3_bits_exceptionVec_14(g_l3_io_out_bits_exceptionVec_14),
    .io_out_3_bits_exceptionVec_15(g_l3_io_out_bits_exceptionVec_15),
    .io_out_3_bits_exceptionVec_16(g_l3_io_out_bits_exceptionVec_16),
    .io_out_3_bits_exceptionVec_17(g_l3_io_out_bits_exceptionVec_17),
    .io_out_3_bits_exceptionVec_18(g_l3_io_out_bits_exceptionVec_18),
    .io_out_3_bits_exceptionVec_19(g_l3_io_out_bits_exceptionVec_19),
    .io_out_3_bits_exceptionVec_20(g_l3_io_out_bits_exceptionVec_20),
    .io_out_3_bits_exceptionVec_21(g_l3_io_out_bits_exceptionVec_21),
    .io_out_3_bits_exceptionVec_22(g_l3_io_out_bits_exceptionVec_22),
    .io_out_3_bits_exceptionVec_23(g_l3_io_out_bits_exceptionVec_23),
    .io_out_3_bits_isFetchMalAddr(g_l3_io_out_bits_isFetchMalAddr),
    .io_out_3_bits_hasException(g_l3_io_out_bits_hasException),
    .io_out_3_bits_trigger(g_l3_io_out_bits_trigger),
    .io_out_3_bits_preDecodeInfo_valid(g_l3_io_out_bits_preDecodeInfo_valid),
    .io_out_3_bits_preDecodeInfo_isRVC(g_l3_io_out_bits_preDecodeInfo_isRVC),
    .io_out_3_bits_preDecodeInfo_brType(g_l3_io_out_bits_preDecodeInfo_brType),
    .io_out_3_bits_preDecodeInfo_isCall(g_l3_io_out_bits_preDecodeInfo_isCall),
    .io_out_3_bits_preDecodeInfo_isRet(g_l3_io_out_bits_preDecodeInfo_isRet),
    .io_out_3_bits_pred_taken(g_l3_io_out_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(g_l3_io_out_bits_crossPageIPFFix),
    .io_out_3_bits_ftqPtr_flag(g_l3_io_out_bits_ftqPtr_flag),
    .io_out_3_bits_ftqPtr_value(g_l3_io_out_bits_ftqPtr_value),
    .io_out_3_bits_ftqOffset(g_l3_io_out_bits_ftqOffset),
    .io_out_3_bits_satpFlushFirstFetchFault(g_l3_io_out_bits_satpFlushFirstFetchFault),
    .io_out_3_bits_srcType_0(g_l3_io_out_bits_srcType_0),
    .io_out_3_bits_srcType_1(g_l3_io_out_bits_srcType_1),
    .io_out_3_bits_srcType_2(g_l3_io_out_bits_srcType_2),
    .io_out_3_bits_srcType_3(g_l3_io_out_bits_srcType_3),
    .io_out_3_bits_srcType_4(g_l3_io_out_bits_srcType_4),
    .io_out_3_bits_ldest(g_l3_io_out_bits_ldest),
    .io_out_3_bits_fuType(g_l3_io_out_bits_fuType),
    .io_out_3_bits_fuOpType(g_l3_io_out_bits_fuOpType),
    .io_out_3_bits_rfWen(g_l3_io_out_bits_rfWen),
    .io_out_3_bits_fpWen(g_l3_io_out_bits_fpWen),
    .io_out_3_bits_vecWen(g_l3_io_out_bits_vecWen),
    .io_out_3_bits_v0Wen(g_l3_io_out_bits_v0Wen),
    .io_out_3_bits_vlWen(g_l3_io_out_bits_vlWen),
    .io_out_3_bits_isXSTrap(g_l3_io_out_bits_isXSTrap),
    .io_out_3_bits_waitForward(g_l3_io_out_bits_waitForward),
    .io_out_3_bits_blockBackward(g_l3_io_out_bits_blockBackward),
    .io_out_3_bits_flushPipe(g_l3_io_out_bits_flushPipe),
    .io_out_3_bits_canRobCompress(g_l3_io_out_bits_canRobCompress),
    .io_out_3_bits_selImm(g_l3_io_out_bits_selImm),
    .io_out_3_bits_imm(g_l3_io_out_bits_imm),
    .io_out_3_bits_fpu_typeTagOut(g_l3_io_out_bits_fpu_typeTagOut),
    .io_out_3_bits_fpu_wflags(g_l3_io_out_bits_fpu_wflags),
    .io_out_3_bits_fpu_typ(g_l3_io_out_bits_fpu_typ),
    .io_out_3_bits_fpu_fmt(g_l3_io_out_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm(g_l3_io_out_bits_fpu_rm),
    .io_out_3_bits_vpu_vill(g_l3_io_out_bits_vpu_vill),
    .io_out_3_bits_vpu_vma(g_l3_io_out_bits_vpu_vma),
    .io_out_3_bits_vpu_vta(g_l3_io_out_bits_vpu_vta),
    .io_out_3_bits_vpu_vsew(g_l3_io_out_bits_vpu_vsew),
    .io_out_3_bits_vpu_vlmul(g_l3_io_out_bits_vpu_vlmul),
    .io_out_3_bits_vpu_specVill(g_l3_io_out_bits_vpu_specVill),
    .io_out_3_bits_vpu_specVma(g_l3_io_out_bits_vpu_specVma),
    .io_out_3_bits_vpu_specVta(g_l3_io_out_bits_vpu_specVta),
    .io_out_3_bits_vpu_specVsew(g_l3_io_out_bits_vpu_specVsew),
    .io_out_3_bits_vpu_specVlmul(g_l3_io_out_bits_vpu_specVlmul),
    .io_out_3_bits_vpu_vm(g_l3_io_out_bits_vpu_vm),
    .io_out_3_bits_vpu_vstart(g_l3_io_out_bits_vpu_vstart),
    .io_out_3_bits_vpu_frm(g_l3_io_out_bits_vpu_frm),
    .io_out_3_bits_vpu_fpu_isFpToVecInst(g_l3_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_3_bits_vpu_fpu_isFP32Instr(g_l3_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_3_bits_vpu_fpu_isFP64Instr(g_l3_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_3_bits_vpu_fpu_isReduction(g_l3_io_out_bits_vpu_fpu_isReduction),
    .io_out_3_bits_vpu_fpu_isFoldTo1_2(g_l3_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_3_bits_vpu_fpu_isFoldTo1_4(g_l3_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_3_bits_vpu_fpu_isFoldTo1_8(g_l3_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_3_bits_vpu_vxrm(g_l3_io_out_bits_vpu_vxrm),
    .io_out_3_bits_vpu_vuopIdx(g_l3_io_out_bits_vpu_vuopIdx),
    .io_out_3_bits_vpu_lastUop(g_l3_io_out_bits_vpu_lastUop),
    .io_out_3_bits_vpu_vmask(g_l3_io_out_bits_vpu_vmask),
    .io_out_3_bits_vpu_vl(g_l3_io_out_bits_vpu_vl),
    .io_out_3_bits_vpu_nf(g_l3_io_out_bits_vpu_nf),
    .io_out_3_bits_vpu_veew(g_l3_io_out_bits_vpu_veew),
    .io_out_3_bits_vpu_isReverse(g_l3_io_out_bits_vpu_isReverse),
    .io_out_3_bits_vpu_isExt(g_l3_io_out_bits_vpu_isExt),
    .io_out_3_bits_vpu_isNarrow(g_l3_io_out_bits_vpu_isNarrow),
    .io_out_3_bits_vpu_isDstMask(g_l3_io_out_bits_vpu_isDstMask),
    .io_out_3_bits_vpu_isOpMask(g_l3_io_out_bits_vpu_isOpMask),
    .io_out_3_bits_vpu_isMove(g_l3_io_out_bits_vpu_isMove),
    .io_out_3_bits_vpu_isDependOldVd(g_l3_io_out_bits_vpu_isDependOldVd),
    .io_out_3_bits_vpu_isWritePartVd(g_l3_io_out_bits_vpu_isWritePartVd),
    .io_out_3_bits_vpu_isVleff(g_l3_io_out_bits_vpu_isVleff),
    .io_out_3_bits_vlsInstr(g_l3_io_out_bits_vlsInstr),
    .io_out_3_bits_wfflags(g_l3_io_out_bits_wfflags),
    .io_out_3_bits_isMove(g_l3_io_out_bits_isMove),
    .io_out_3_bits_uopIdx(g_l3_io_out_bits_uopIdx),
    .io_out_3_bits_isVset(g_l3_io_out_bits_isVset),
    .io_out_3_bits_firstUop(g_l3_io_out_bits_firstUop),
    .io_out_3_bits_lastUop(g_l3_io_out_bits_lastUop),
    .io_out_3_bits_numUops(g_l3_io_out_bits_numUops),
    .io_out_3_bits_numWB(g_l3_io_out_bits_numWB),
    .io_out_3_bits_commitType(g_l3_io_out_bits_commitType),
    .io_out_3_bits_psrc_0(g_l3_io_out_bits_psrc_0),
    .io_out_3_bits_psrc_1(g_l3_io_out_bits_psrc_1),
    .io_out_3_bits_psrc_2(g_l3_io_out_bits_psrc_2),
    .io_out_3_bits_psrc_3(g_l3_io_out_bits_psrc_3),
    .io_out_3_bits_psrc_4(g_l3_io_out_bits_psrc_4),
    .io_out_3_bits_pdest(g_l3_io_out_bits_pdest),
    .io_out_3_bits_robIdx_flag(g_l3_io_out_bits_robIdx_flag),
    .io_out_3_bits_robIdx_value(g_l3_io_out_bits_robIdx_value),
    .io_out_3_bits_instrSize(g_l3_io_out_bits_instrSize),
    .io_out_3_bits_dirtyFs(g_l3_io_out_bits_dirtyFs),
    .io_out_3_bits_dirtyVs(g_l3_io_out_bits_dirtyVs),
    .io_out_3_bits_traceBlockInPipe_itype(g_l3_io_out_bits_traceBlockInPipe_itype),
    .io_out_3_bits_traceBlockInPipe_iretire(g_l3_io_out_bits_traceBlockInPipe_iretire),
    .io_out_3_bits_traceBlockInPipe_ilastsize(g_l3_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_3_bits_eliminatedMove(g_l3_io_out_bits_eliminatedMove),
    .io_out_3_bits_debugInfo_renameTime(g_l3_io_out_bits_debugInfo_renameTime),
    .io_out_3_bits_debug_seqNum_seqNum(g_l3_io_out_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx(g_l3_io_out_bits_debug_seqNum_uopIdx),
    .io_out_3_bits_debug_fuType(g_l3_io_out_bits_debug_fuType),
    .io_out_3_bits_debug_sim_trig(g_l3_io_out_bits_debug_sim_trig),
    .io_out_3_bits_numLsElem(g_l3_io_out_bits_numLsElem),
    .io_in_4_valid(io_in_4_valid), .io_in_4_ready(g_l4_io_in_ready),
    .io_out_4_ready(io_out_4_ready), .io_out_4_valid(g_l4_io_out_valid),
    .io_in_4_bits_instr(io_in_4_bits_instr),
    .io_in_4_bits_pc(io_in_4_bits_pc),
    .io_in_4_bits_foldpc(io_in_4_bits_foldpc),
    .io_in_4_bits_exceptionVec_0(io_in_4_bits_exceptionVec_0),
    .io_in_4_bits_exceptionVec_1(io_in_4_bits_exceptionVec_1),
    .io_in_4_bits_exceptionVec_2(io_in_4_bits_exceptionVec_2),
    .io_in_4_bits_exceptionVec_3(io_in_4_bits_exceptionVec_3),
    .io_in_4_bits_exceptionVec_4(io_in_4_bits_exceptionVec_4),
    .io_in_4_bits_exceptionVec_5(io_in_4_bits_exceptionVec_5),
    .io_in_4_bits_exceptionVec_6(io_in_4_bits_exceptionVec_6),
    .io_in_4_bits_exceptionVec_7(io_in_4_bits_exceptionVec_7),
    .io_in_4_bits_exceptionVec_8(io_in_4_bits_exceptionVec_8),
    .io_in_4_bits_exceptionVec_9(io_in_4_bits_exceptionVec_9),
    .io_in_4_bits_exceptionVec_10(io_in_4_bits_exceptionVec_10),
    .io_in_4_bits_exceptionVec_11(io_in_4_bits_exceptionVec_11),
    .io_in_4_bits_exceptionVec_12(io_in_4_bits_exceptionVec_12),
    .io_in_4_bits_exceptionVec_13(io_in_4_bits_exceptionVec_13),
    .io_in_4_bits_exceptionVec_14(io_in_4_bits_exceptionVec_14),
    .io_in_4_bits_exceptionVec_15(io_in_4_bits_exceptionVec_15),
    .io_in_4_bits_exceptionVec_16(io_in_4_bits_exceptionVec_16),
    .io_in_4_bits_exceptionVec_17(io_in_4_bits_exceptionVec_17),
    .io_in_4_bits_exceptionVec_18(io_in_4_bits_exceptionVec_18),
    .io_in_4_bits_exceptionVec_19(io_in_4_bits_exceptionVec_19),
    .io_in_4_bits_exceptionVec_20(io_in_4_bits_exceptionVec_20),
    .io_in_4_bits_exceptionVec_21(io_in_4_bits_exceptionVec_21),
    .io_in_4_bits_exceptionVec_22(io_in_4_bits_exceptionVec_22),
    .io_in_4_bits_exceptionVec_23(io_in_4_bits_exceptionVec_23),
    .io_in_4_bits_isFetchMalAddr(io_in_4_bits_isFetchMalAddr),
    .io_in_4_bits_hasException(io_in_4_bits_hasException),
    .io_in_4_bits_trigger(io_in_4_bits_trigger),
    .io_in_4_bits_preDecodeInfo_valid(io_in_4_bits_preDecodeInfo_valid),
    .io_in_4_bits_preDecodeInfo_isRVC(io_in_4_bits_preDecodeInfo_isRVC),
    .io_in_4_bits_preDecodeInfo_brType(io_in_4_bits_preDecodeInfo_brType),
    .io_in_4_bits_preDecodeInfo_isCall(io_in_4_bits_preDecodeInfo_isCall),
    .io_in_4_bits_preDecodeInfo_isRet(io_in_4_bits_preDecodeInfo_isRet),
    .io_in_4_bits_pred_taken(io_in_4_bits_pred_taken),
    .io_in_4_bits_crossPageIPFFix(io_in_4_bits_crossPageIPFFix),
    .io_in_4_bits_ftqPtr_flag(io_in_4_bits_ftqPtr_flag),
    .io_in_4_bits_ftqPtr_value(io_in_4_bits_ftqPtr_value),
    .io_in_4_bits_ftqOffset(io_in_4_bits_ftqOffset),
    .io_in_4_bits_satpFlushFirstFetchFault(io_in_4_bits_satpFlushFirstFetchFault),
    .io_in_4_bits_srcType_0(io_in_4_bits_srcType_0),
    .io_in_4_bits_srcType_1(io_in_4_bits_srcType_1),
    .io_in_4_bits_srcType_2(io_in_4_bits_srcType_2),
    .io_in_4_bits_srcType_3(io_in_4_bits_srcType_3),
    .io_in_4_bits_srcType_4(io_in_4_bits_srcType_4),
    .io_in_4_bits_ldest(io_in_4_bits_ldest),
    .io_in_4_bits_fuType(io_in_4_bits_fuType),
    .io_in_4_bits_fuOpType(io_in_4_bits_fuOpType),
    .io_in_4_bits_rfWen(io_in_4_bits_rfWen),
    .io_in_4_bits_fpWen(io_in_4_bits_fpWen),
    .io_in_4_bits_vecWen(io_in_4_bits_vecWen),
    .io_in_4_bits_v0Wen(io_in_4_bits_v0Wen),
    .io_in_4_bits_vlWen(io_in_4_bits_vlWen),
    .io_in_4_bits_isXSTrap(io_in_4_bits_isXSTrap),
    .io_in_4_bits_waitForward(io_in_4_bits_waitForward),
    .io_in_4_bits_blockBackward(io_in_4_bits_blockBackward),
    .io_in_4_bits_flushPipe(io_in_4_bits_flushPipe),
    .io_in_4_bits_canRobCompress(io_in_4_bits_canRobCompress),
    .io_in_4_bits_selImm(io_in_4_bits_selImm),
    .io_in_4_bits_imm(io_in_4_bits_imm),
    .io_in_4_bits_fpu_typeTagOut(io_in_4_bits_fpu_typeTagOut),
    .io_in_4_bits_fpu_wflags(io_in_4_bits_fpu_wflags),
    .io_in_4_bits_fpu_typ(io_in_4_bits_fpu_typ),
    .io_in_4_bits_fpu_fmt(io_in_4_bits_fpu_fmt),
    .io_in_4_bits_fpu_rm(io_in_4_bits_fpu_rm),
    .io_in_4_bits_vpu_vill(io_in_4_bits_vpu_vill),
    .io_in_4_bits_vpu_vma(io_in_4_bits_vpu_vma),
    .io_in_4_bits_vpu_vta(io_in_4_bits_vpu_vta),
    .io_in_4_bits_vpu_vsew(io_in_4_bits_vpu_vsew),
    .io_in_4_bits_vpu_vlmul(io_in_4_bits_vpu_vlmul),
    .io_in_4_bits_vpu_specVill(io_in_4_bits_vpu_specVill),
    .io_in_4_bits_vpu_specVma(io_in_4_bits_vpu_specVma),
    .io_in_4_bits_vpu_specVta(io_in_4_bits_vpu_specVta),
    .io_in_4_bits_vpu_specVsew(io_in_4_bits_vpu_specVsew),
    .io_in_4_bits_vpu_specVlmul(io_in_4_bits_vpu_specVlmul),
    .io_in_4_bits_vpu_vm(io_in_4_bits_vpu_vm),
    .io_in_4_bits_vpu_vstart(io_in_4_bits_vpu_vstart),
    .io_in_4_bits_vpu_frm(io_in_4_bits_vpu_frm),
    .io_in_4_bits_vpu_fpu_isFpToVecInst(io_in_4_bits_vpu_fpu_isFpToVecInst),
    .io_in_4_bits_vpu_fpu_isFP32Instr(io_in_4_bits_vpu_fpu_isFP32Instr),
    .io_in_4_bits_vpu_fpu_isFP64Instr(io_in_4_bits_vpu_fpu_isFP64Instr),
    .io_in_4_bits_vpu_fpu_isReduction(io_in_4_bits_vpu_fpu_isReduction),
    .io_in_4_bits_vpu_fpu_isFoldTo1_2(io_in_4_bits_vpu_fpu_isFoldTo1_2),
    .io_in_4_bits_vpu_fpu_isFoldTo1_4(io_in_4_bits_vpu_fpu_isFoldTo1_4),
    .io_in_4_bits_vpu_fpu_isFoldTo1_8(io_in_4_bits_vpu_fpu_isFoldTo1_8),
    .io_in_4_bits_vpu_vxrm(io_in_4_bits_vpu_vxrm),
    .io_in_4_bits_vpu_vuopIdx(io_in_4_bits_vpu_vuopIdx),
    .io_in_4_bits_vpu_lastUop(io_in_4_bits_vpu_lastUop),
    .io_in_4_bits_vpu_vmask(io_in_4_bits_vpu_vmask),
    .io_in_4_bits_vpu_vl(io_in_4_bits_vpu_vl),
    .io_in_4_bits_vpu_nf(io_in_4_bits_vpu_nf),
    .io_in_4_bits_vpu_veew(io_in_4_bits_vpu_veew),
    .io_in_4_bits_vpu_isReverse(io_in_4_bits_vpu_isReverse),
    .io_in_4_bits_vpu_isExt(io_in_4_bits_vpu_isExt),
    .io_in_4_bits_vpu_isNarrow(io_in_4_bits_vpu_isNarrow),
    .io_in_4_bits_vpu_isDstMask(io_in_4_bits_vpu_isDstMask),
    .io_in_4_bits_vpu_isOpMask(io_in_4_bits_vpu_isOpMask),
    .io_in_4_bits_vpu_isMove(io_in_4_bits_vpu_isMove),
    .io_in_4_bits_vpu_isDependOldVd(io_in_4_bits_vpu_isDependOldVd),
    .io_in_4_bits_vpu_isWritePartVd(io_in_4_bits_vpu_isWritePartVd),
    .io_in_4_bits_vpu_isVleff(io_in_4_bits_vpu_isVleff),
    .io_in_4_bits_vlsInstr(io_in_4_bits_vlsInstr),
    .io_in_4_bits_wfflags(io_in_4_bits_wfflags),
    .io_in_4_bits_isMove(io_in_4_bits_isMove),
    .io_in_4_bits_uopIdx(io_in_4_bits_uopIdx),
    .io_in_4_bits_isVset(io_in_4_bits_isVset),
    .io_in_4_bits_firstUop(io_in_4_bits_firstUop),
    .io_in_4_bits_lastUop(io_in_4_bits_lastUop),
    .io_in_4_bits_numUops(io_in_4_bits_numUops),
    .io_in_4_bits_numWB(io_in_4_bits_numWB),
    .io_in_4_bits_commitType(io_in_4_bits_commitType),
    .io_in_4_bits_psrc_0(io_in_4_bits_psrc_0),
    .io_in_4_bits_psrc_1(io_in_4_bits_psrc_1),
    .io_in_4_bits_psrc_2(io_in_4_bits_psrc_2),
    .io_in_4_bits_psrc_3(io_in_4_bits_psrc_3),
    .io_in_4_bits_psrc_4(io_in_4_bits_psrc_4),
    .io_in_4_bits_pdest(io_in_4_bits_pdest),
    .io_in_4_bits_robIdx_flag(io_in_4_bits_robIdx_flag),
    .io_in_4_bits_robIdx_value(io_in_4_bits_robIdx_value),
    .io_in_4_bits_instrSize(io_in_4_bits_instrSize),
    .io_in_4_bits_dirtyFs(io_in_4_bits_dirtyFs),
    .io_in_4_bits_dirtyVs(io_in_4_bits_dirtyVs),
    .io_in_4_bits_traceBlockInPipe_itype(io_in_4_bits_traceBlockInPipe_itype),
    .io_in_4_bits_traceBlockInPipe_iretire(io_in_4_bits_traceBlockInPipe_iretire),
    .io_in_4_bits_traceBlockInPipe_ilastsize(io_in_4_bits_traceBlockInPipe_ilastsize),
    .io_in_4_bits_eliminatedMove(io_in_4_bits_eliminatedMove),
    .io_in_4_bits_debugInfo_renameTime(io_in_4_bits_debugInfo_renameTime),
    .io_in_4_bits_debug_seqNum_seqNum(io_in_4_bits_debug_seqNum_seqNum),
    .io_in_4_bits_debug_seqNum_uopIdx(io_in_4_bits_debug_seqNum_uopIdx),
    .io_in_4_bits_debug_fuType(io_in_4_bits_debug_fuType),
    .io_in_4_bits_debug_sim_trig(io_in_4_bits_debug_sim_trig),
    .io_in_4_bits_numLsElem(io_in_4_bits_numLsElem),
    .io_out_4_bits_instr(g_l4_io_out_bits_instr),
    .io_out_4_bits_pc(g_l4_io_out_bits_pc),
    .io_out_4_bits_foldpc(g_l4_io_out_bits_foldpc),
    .io_out_4_bits_exceptionVec_0(g_l4_io_out_bits_exceptionVec_0),
    .io_out_4_bits_exceptionVec_1(g_l4_io_out_bits_exceptionVec_1),
    .io_out_4_bits_exceptionVec_2(g_l4_io_out_bits_exceptionVec_2),
    .io_out_4_bits_exceptionVec_3(g_l4_io_out_bits_exceptionVec_3),
    .io_out_4_bits_exceptionVec_4(g_l4_io_out_bits_exceptionVec_4),
    .io_out_4_bits_exceptionVec_5(g_l4_io_out_bits_exceptionVec_5),
    .io_out_4_bits_exceptionVec_6(g_l4_io_out_bits_exceptionVec_6),
    .io_out_4_bits_exceptionVec_7(g_l4_io_out_bits_exceptionVec_7),
    .io_out_4_bits_exceptionVec_8(g_l4_io_out_bits_exceptionVec_8),
    .io_out_4_bits_exceptionVec_9(g_l4_io_out_bits_exceptionVec_9),
    .io_out_4_bits_exceptionVec_10(g_l4_io_out_bits_exceptionVec_10),
    .io_out_4_bits_exceptionVec_11(g_l4_io_out_bits_exceptionVec_11),
    .io_out_4_bits_exceptionVec_12(g_l4_io_out_bits_exceptionVec_12),
    .io_out_4_bits_exceptionVec_13(g_l4_io_out_bits_exceptionVec_13),
    .io_out_4_bits_exceptionVec_14(g_l4_io_out_bits_exceptionVec_14),
    .io_out_4_bits_exceptionVec_15(g_l4_io_out_bits_exceptionVec_15),
    .io_out_4_bits_exceptionVec_16(g_l4_io_out_bits_exceptionVec_16),
    .io_out_4_bits_exceptionVec_17(g_l4_io_out_bits_exceptionVec_17),
    .io_out_4_bits_exceptionVec_18(g_l4_io_out_bits_exceptionVec_18),
    .io_out_4_bits_exceptionVec_19(g_l4_io_out_bits_exceptionVec_19),
    .io_out_4_bits_exceptionVec_20(g_l4_io_out_bits_exceptionVec_20),
    .io_out_4_bits_exceptionVec_21(g_l4_io_out_bits_exceptionVec_21),
    .io_out_4_bits_exceptionVec_22(g_l4_io_out_bits_exceptionVec_22),
    .io_out_4_bits_exceptionVec_23(g_l4_io_out_bits_exceptionVec_23),
    .io_out_4_bits_isFetchMalAddr(g_l4_io_out_bits_isFetchMalAddr),
    .io_out_4_bits_hasException(g_l4_io_out_bits_hasException),
    .io_out_4_bits_trigger(g_l4_io_out_bits_trigger),
    .io_out_4_bits_preDecodeInfo_valid(g_l4_io_out_bits_preDecodeInfo_valid),
    .io_out_4_bits_preDecodeInfo_isRVC(g_l4_io_out_bits_preDecodeInfo_isRVC),
    .io_out_4_bits_preDecodeInfo_brType(g_l4_io_out_bits_preDecodeInfo_brType),
    .io_out_4_bits_preDecodeInfo_isCall(g_l4_io_out_bits_preDecodeInfo_isCall),
    .io_out_4_bits_preDecodeInfo_isRet(g_l4_io_out_bits_preDecodeInfo_isRet),
    .io_out_4_bits_pred_taken(g_l4_io_out_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(g_l4_io_out_bits_crossPageIPFFix),
    .io_out_4_bits_ftqPtr_flag(g_l4_io_out_bits_ftqPtr_flag),
    .io_out_4_bits_ftqPtr_value(g_l4_io_out_bits_ftqPtr_value),
    .io_out_4_bits_ftqOffset(g_l4_io_out_bits_ftqOffset),
    .io_out_4_bits_satpFlushFirstFetchFault(g_l4_io_out_bits_satpFlushFirstFetchFault),
    .io_out_4_bits_srcType_0(g_l4_io_out_bits_srcType_0),
    .io_out_4_bits_srcType_1(g_l4_io_out_bits_srcType_1),
    .io_out_4_bits_srcType_2(g_l4_io_out_bits_srcType_2),
    .io_out_4_bits_srcType_3(g_l4_io_out_bits_srcType_3),
    .io_out_4_bits_srcType_4(g_l4_io_out_bits_srcType_4),
    .io_out_4_bits_ldest(g_l4_io_out_bits_ldest),
    .io_out_4_bits_fuType(g_l4_io_out_bits_fuType),
    .io_out_4_bits_fuOpType(g_l4_io_out_bits_fuOpType),
    .io_out_4_bits_rfWen(g_l4_io_out_bits_rfWen),
    .io_out_4_bits_fpWen(g_l4_io_out_bits_fpWen),
    .io_out_4_bits_vecWen(g_l4_io_out_bits_vecWen),
    .io_out_4_bits_v0Wen(g_l4_io_out_bits_v0Wen),
    .io_out_4_bits_vlWen(g_l4_io_out_bits_vlWen),
    .io_out_4_bits_isXSTrap(g_l4_io_out_bits_isXSTrap),
    .io_out_4_bits_waitForward(g_l4_io_out_bits_waitForward),
    .io_out_4_bits_blockBackward(g_l4_io_out_bits_blockBackward),
    .io_out_4_bits_flushPipe(g_l4_io_out_bits_flushPipe),
    .io_out_4_bits_canRobCompress(g_l4_io_out_bits_canRobCompress),
    .io_out_4_bits_selImm(g_l4_io_out_bits_selImm),
    .io_out_4_bits_imm(g_l4_io_out_bits_imm),
    .io_out_4_bits_fpu_typeTagOut(g_l4_io_out_bits_fpu_typeTagOut),
    .io_out_4_bits_fpu_wflags(g_l4_io_out_bits_fpu_wflags),
    .io_out_4_bits_fpu_typ(g_l4_io_out_bits_fpu_typ),
    .io_out_4_bits_fpu_fmt(g_l4_io_out_bits_fpu_fmt),
    .io_out_4_bits_fpu_rm(g_l4_io_out_bits_fpu_rm),
    .io_out_4_bits_vpu_vill(g_l4_io_out_bits_vpu_vill),
    .io_out_4_bits_vpu_vma(g_l4_io_out_bits_vpu_vma),
    .io_out_4_bits_vpu_vta(g_l4_io_out_bits_vpu_vta),
    .io_out_4_bits_vpu_vsew(g_l4_io_out_bits_vpu_vsew),
    .io_out_4_bits_vpu_vlmul(g_l4_io_out_bits_vpu_vlmul),
    .io_out_4_bits_vpu_specVill(g_l4_io_out_bits_vpu_specVill),
    .io_out_4_bits_vpu_specVma(g_l4_io_out_bits_vpu_specVma),
    .io_out_4_bits_vpu_specVta(g_l4_io_out_bits_vpu_specVta),
    .io_out_4_bits_vpu_specVsew(g_l4_io_out_bits_vpu_specVsew),
    .io_out_4_bits_vpu_specVlmul(g_l4_io_out_bits_vpu_specVlmul),
    .io_out_4_bits_vpu_vm(g_l4_io_out_bits_vpu_vm),
    .io_out_4_bits_vpu_vstart(g_l4_io_out_bits_vpu_vstart),
    .io_out_4_bits_vpu_frm(g_l4_io_out_bits_vpu_frm),
    .io_out_4_bits_vpu_fpu_isFpToVecInst(g_l4_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_4_bits_vpu_fpu_isFP32Instr(g_l4_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_4_bits_vpu_fpu_isFP64Instr(g_l4_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_4_bits_vpu_fpu_isReduction(g_l4_io_out_bits_vpu_fpu_isReduction),
    .io_out_4_bits_vpu_fpu_isFoldTo1_2(g_l4_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_4_bits_vpu_fpu_isFoldTo1_4(g_l4_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_4_bits_vpu_fpu_isFoldTo1_8(g_l4_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_4_bits_vpu_vxrm(g_l4_io_out_bits_vpu_vxrm),
    .io_out_4_bits_vpu_vuopIdx(g_l4_io_out_bits_vpu_vuopIdx),
    .io_out_4_bits_vpu_lastUop(g_l4_io_out_bits_vpu_lastUop),
    .io_out_4_bits_vpu_vmask(g_l4_io_out_bits_vpu_vmask),
    .io_out_4_bits_vpu_vl(g_l4_io_out_bits_vpu_vl),
    .io_out_4_bits_vpu_nf(g_l4_io_out_bits_vpu_nf),
    .io_out_4_bits_vpu_veew(g_l4_io_out_bits_vpu_veew),
    .io_out_4_bits_vpu_isReverse(g_l4_io_out_bits_vpu_isReverse),
    .io_out_4_bits_vpu_isExt(g_l4_io_out_bits_vpu_isExt),
    .io_out_4_bits_vpu_isNarrow(g_l4_io_out_bits_vpu_isNarrow),
    .io_out_4_bits_vpu_isDstMask(g_l4_io_out_bits_vpu_isDstMask),
    .io_out_4_bits_vpu_isOpMask(g_l4_io_out_bits_vpu_isOpMask),
    .io_out_4_bits_vpu_isMove(g_l4_io_out_bits_vpu_isMove),
    .io_out_4_bits_vpu_isDependOldVd(g_l4_io_out_bits_vpu_isDependOldVd),
    .io_out_4_bits_vpu_isWritePartVd(g_l4_io_out_bits_vpu_isWritePartVd),
    .io_out_4_bits_vpu_isVleff(g_l4_io_out_bits_vpu_isVleff),
    .io_out_4_bits_vlsInstr(g_l4_io_out_bits_vlsInstr),
    .io_out_4_bits_wfflags(g_l4_io_out_bits_wfflags),
    .io_out_4_bits_isMove(g_l4_io_out_bits_isMove),
    .io_out_4_bits_uopIdx(g_l4_io_out_bits_uopIdx),
    .io_out_4_bits_isVset(g_l4_io_out_bits_isVset),
    .io_out_4_bits_firstUop(g_l4_io_out_bits_firstUop),
    .io_out_4_bits_lastUop(g_l4_io_out_bits_lastUop),
    .io_out_4_bits_numUops(g_l4_io_out_bits_numUops),
    .io_out_4_bits_numWB(g_l4_io_out_bits_numWB),
    .io_out_4_bits_commitType(g_l4_io_out_bits_commitType),
    .io_out_4_bits_psrc_0(g_l4_io_out_bits_psrc_0),
    .io_out_4_bits_psrc_1(g_l4_io_out_bits_psrc_1),
    .io_out_4_bits_psrc_2(g_l4_io_out_bits_psrc_2),
    .io_out_4_bits_psrc_3(g_l4_io_out_bits_psrc_3),
    .io_out_4_bits_psrc_4(g_l4_io_out_bits_psrc_4),
    .io_out_4_bits_pdest(g_l4_io_out_bits_pdest),
    .io_out_4_bits_robIdx_flag(g_l4_io_out_bits_robIdx_flag),
    .io_out_4_bits_robIdx_value(g_l4_io_out_bits_robIdx_value),
    .io_out_4_bits_instrSize(g_l4_io_out_bits_instrSize),
    .io_out_4_bits_dirtyFs(g_l4_io_out_bits_dirtyFs),
    .io_out_4_bits_dirtyVs(g_l4_io_out_bits_dirtyVs),
    .io_out_4_bits_traceBlockInPipe_itype(g_l4_io_out_bits_traceBlockInPipe_itype),
    .io_out_4_bits_traceBlockInPipe_iretire(g_l4_io_out_bits_traceBlockInPipe_iretire),
    .io_out_4_bits_traceBlockInPipe_ilastsize(g_l4_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_4_bits_eliminatedMove(g_l4_io_out_bits_eliminatedMove),
    .io_out_4_bits_debugInfo_renameTime(g_l4_io_out_bits_debugInfo_renameTime),
    .io_out_4_bits_debug_seqNum_seqNum(g_l4_io_out_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx(g_l4_io_out_bits_debug_seqNum_uopIdx),
    .io_out_4_bits_debug_fuType(g_l4_io_out_bits_debug_fuType),
    .io_out_4_bits_debug_sim_trig(g_l4_io_out_bits_debug_sim_trig),
    .io_out_4_bits_numLsElem(g_l4_io_out_bits_numLsElem),
    .io_in_5_valid(io_in_5_valid), .io_in_5_ready(g_l5_io_in_ready),
    .io_out_5_ready(io_out_5_ready), .io_out_5_valid(g_l5_io_out_valid),
    .io_in_5_bits_instr(io_in_5_bits_instr),
    .io_in_5_bits_pc(io_in_5_bits_pc),
    .io_in_5_bits_foldpc(io_in_5_bits_foldpc),
    .io_in_5_bits_exceptionVec_0(io_in_5_bits_exceptionVec_0),
    .io_in_5_bits_exceptionVec_1(io_in_5_bits_exceptionVec_1),
    .io_in_5_bits_exceptionVec_2(io_in_5_bits_exceptionVec_2),
    .io_in_5_bits_exceptionVec_3(io_in_5_bits_exceptionVec_3),
    .io_in_5_bits_exceptionVec_4(io_in_5_bits_exceptionVec_4),
    .io_in_5_bits_exceptionVec_5(io_in_5_bits_exceptionVec_5),
    .io_in_5_bits_exceptionVec_6(io_in_5_bits_exceptionVec_6),
    .io_in_5_bits_exceptionVec_7(io_in_5_bits_exceptionVec_7),
    .io_in_5_bits_exceptionVec_8(io_in_5_bits_exceptionVec_8),
    .io_in_5_bits_exceptionVec_9(io_in_5_bits_exceptionVec_9),
    .io_in_5_bits_exceptionVec_10(io_in_5_bits_exceptionVec_10),
    .io_in_5_bits_exceptionVec_11(io_in_5_bits_exceptionVec_11),
    .io_in_5_bits_exceptionVec_12(io_in_5_bits_exceptionVec_12),
    .io_in_5_bits_exceptionVec_13(io_in_5_bits_exceptionVec_13),
    .io_in_5_bits_exceptionVec_14(io_in_5_bits_exceptionVec_14),
    .io_in_5_bits_exceptionVec_15(io_in_5_bits_exceptionVec_15),
    .io_in_5_bits_exceptionVec_16(io_in_5_bits_exceptionVec_16),
    .io_in_5_bits_exceptionVec_17(io_in_5_bits_exceptionVec_17),
    .io_in_5_bits_exceptionVec_18(io_in_5_bits_exceptionVec_18),
    .io_in_5_bits_exceptionVec_19(io_in_5_bits_exceptionVec_19),
    .io_in_5_bits_exceptionVec_20(io_in_5_bits_exceptionVec_20),
    .io_in_5_bits_exceptionVec_21(io_in_5_bits_exceptionVec_21),
    .io_in_5_bits_exceptionVec_22(io_in_5_bits_exceptionVec_22),
    .io_in_5_bits_exceptionVec_23(io_in_5_bits_exceptionVec_23),
    .io_in_5_bits_isFetchMalAddr(io_in_5_bits_isFetchMalAddr),
    .io_in_5_bits_hasException(io_in_5_bits_hasException),
    .io_in_5_bits_trigger(io_in_5_bits_trigger),
    .io_in_5_bits_preDecodeInfo_valid(io_in_5_bits_preDecodeInfo_valid),
    .io_in_5_bits_preDecodeInfo_isRVC(io_in_5_bits_preDecodeInfo_isRVC),
    .io_in_5_bits_preDecodeInfo_brType(io_in_5_bits_preDecodeInfo_brType),
    .io_in_5_bits_preDecodeInfo_isCall(io_in_5_bits_preDecodeInfo_isCall),
    .io_in_5_bits_preDecodeInfo_isRet(io_in_5_bits_preDecodeInfo_isRet),
    .io_in_5_bits_pred_taken(io_in_5_bits_pred_taken),
    .io_in_5_bits_crossPageIPFFix(io_in_5_bits_crossPageIPFFix),
    .io_in_5_bits_ftqPtr_flag(io_in_5_bits_ftqPtr_flag),
    .io_in_5_bits_ftqPtr_value(io_in_5_bits_ftqPtr_value),
    .io_in_5_bits_ftqOffset(io_in_5_bits_ftqOffset),
    .io_in_5_bits_satpFlushFirstFetchFault(io_in_5_bits_satpFlushFirstFetchFault),
    .io_in_5_bits_srcType_0(io_in_5_bits_srcType_0),
    .io_in_5_bits_srcType_1(io_in_5_bits_srcType_1),
    .io_in_5_bits_srcType_2(io_in_5_bits_srcType_2),
    .io_in_5_bits_srcType_3(io_in_5_bits_srcType_3),
    .io_in_5_bits_srcType_4(io_in_5_bits_srcType_4),
    .io_in_5_bits_ldest(io_in_5_bits_ldest),
    .io_in_5_bits_fuType(io_in_5_bits_fuType),
    .io_in_5_bits_fuOpType(io_in_5_bits_fuOpType),
    .io_in_5_bits_rfWen(io_in_5_bits_rfWen),
    .io_in_5_bits_fpWen(io_in_5_bits_fpWen),
    .io_in_5_bits_vecWen(io_in_5_bits_vecWen),
    .io_in_5_bits_v0Wen(io_in_5_bits_v0Wen),
    .io_in_5_bits_vlWen(io_in_5_bits_vlWen),
    .io_in_5_bits_isXSTrap(io_in_5_bits_isXSTrap),
    .io_in_5_bits_waitForward(io_in_5_bits_waitForward),
    .io_in_5_bits_blockBackward(io_in_5_bits_blockBackward),
    .io_in_5_bits_flushPipe(io_in_5_bits_flushPipe),
    .io_in_5_bits_canRobCompress(io_in_5_bits_canRobCompress),
    .io_in_5_bits_selImm(io_in_5_bits_selImm),
    .io_in_5_bits_imm(io_in_5_bits_imm),
    .io_in_5_bits_fpu_typeTagOut(io_in_5_bits_fpu_typeTagOut),
    .io_in_5_bits_fpu_wflags(io_in_5_bits_fpu_wflags),
    .io_in_5_bits_fpu_typ(io_in_5_bits_fpu_typ),
    .io_in_5_bits_fpu_fmt(io_in_5_bits_fpu_fmt),
    .io_in_5_bits_fpu_rm(io_in_5_bits_fpu_rm),
    .io_in_5_bits_vpu_vill(io_in_5_bits_vpu_vill),
    .io_in_5_bits_vpu_vma(io_in_5_bits_vpu_vma),
    .io_in_5_bits_vpu_vta(io_in_5_bits_vpu_vta),
    .io_in_5_bits_vpu_vsew(io_in_5_bits_vpu_vsew),
    .io_in_5_bits_vpu_vlmul(io_in_5_bits_vpu_vlmul),
    .io_in_5_bits_vpu_specVill(io_in_5_bits_vpu_specVill),
    .io_in_5_bits_vpu_specVma(io_in_5_bits_vpu_specVma),
    .io_in_5_bits_vpu_specVta(io_in_5_bits_vpu_specVta),
    .io_in_5_bits_vpu_specVsew(io_in_5_bits_vpu_specVsew),
    .io_in_5_bits_vpu_specVlmul(io_in_5_bits_vpu_specVlmul),
    .io_in_5_bits_vpu_vm(io_in_5_bits_vpu_vm),
    .io_in_5_bits_vpu_vstart(io_in_5_bits_vpu_vstart),
    .io_in_5_bits_vpu_frm(io_in_5_bits_vpu_frm),
    .io_in_5_bits_vpu_fpu_isFpToVecInst(io_in_5_bits_vpu_fpu_isFpToVecInst),
    .io_in_5_bits_vpu_fpu_isFP32Instr(io_in_5_bits_vpu_fpu_isFP32Instr),
    .io_in_5_bits_vpu_fpu_isFP64Instr(io_in_5_bits_vpu_fpu_isFP64Instr),
    .io_in_5_bits_vpu_fpu_isReduction(io_in_5_bits_vpu_fpu_isReduction),
    .io_in_5_bits_vpu_fpu_isFoldTo1_2(io_in_5_bits_vpu_fpu_isFoldTo1_2),
    .io_in_5_bits_vpu_fpu_isFoldTo1_4(io_in_5_bits_vpu_fpu_isFoldTo1_4),
    .io_in_5_bits_vpu_fpu_isFoldTo1_8(io_in_5_bits_vpu_fpu_isFoldTo1_8),
    .io_in_5_bits_vpu_vxrm(io_in_5_bits_vpu_vxrm),
    .io_in_5_bits_vpu_vuopIdx(io_in_5_bits_vpu_vuopIdx),
    .io_in_5_bits_vpu_lastUop(io_in_5_bits_vpu_lastUop),
    .io_in_5_bits_vpu_vmask(io_in_5_bits_vpu_vmask),
    .io_in_5_bits_vpu_vl(io_in_5_bits_vpu_vl),
    .io_in_5_bits_vpu_nf(io_in_5_bits_vpu_nf),
    .io_in_5_bits_vpu_veew(io_in_5_bits_vpu_veew),
    .io_in_5_bits_vpu_isReverse(io_in_5_bits_vpu_isReverse),
    .io_in_5_bits_vpu_isExt(io_in_5_bits_vpu_isExt),
    .io_in_5_bits_vpu_isNarrow(io_in_5_bits_vpu_isNarrow),
    .io_in_5_bits_vpu_isDstMask(io_in_5_bits_vpu_isDstMask),
    .io_in_5_bits_vpu_isOpMask(io_in_5_bits_vpu_isOpMask),
    .io_in_5_bits_vpu_isMove(io_in_5_bits_vpu_isMove),
    .io_in_5_bits_vpu_isDependOldVd(io_in_5_bits_vpu_isDependOldVd),
    .io_in_5_bits_vpu_isWritePartVd(io_in_5_bits_vpu_isWritePartVd),
    .io_in_5_bits_vpu_isVleff(io_in_5_bits_vpu_isVleff),
    .io_in_5_bits_vlsInstr(io_in_5_bits_vlsInstr),
    .io_in_5_bits_wfflags(io_in_5_bits_wfflags),
    .io_in_5_bits_isMove(io_in_5_bits_isMove),
    .io_in_5_bits_uopIdx(io_in_5_bits_uopIdx),
    .io_in_5_bits_isVset(io_in_5_bits_isVset),
    .io_in_5_bits_firstUop(io_in_5_bits_firstUop),
    .io_in_5_bits_lastUop(io_in_5_bits_lastUop),
    .io_in_5_bits_numUops(io_in_5_bits_numUops),
    .io_in_5_bits_numWB(io_in_5_bits_numWB),
    .io_in_5_bits_commitType(io_in_5_bits_commitType),
    .io_in_5_bits_psrc_0(io_in_5_bits_psrc_0),
    .io_in_5_bits_psrc_1(io_in_5_bits_psrc_1),
    .io_in_5_bits_psrc_2(io_in_5_bits_psrc_2),
    .io_in_5_bits_psrc_3(io_in_5_bits_psrc_3),
    .io_in_5_bits_psrc_4(io_in_5_bits_psrc_4),
    .io_in_5_bits_pdest(io_in_5_bits_pdest),
    .io_in_5_bits_robIdx_flag(io_in_5_bits_robIdx_flag),
    .io_in_5_bits_robIdx_value(io_in_5_bits_robIdx_value),
    .io_in_5_bits_instrSize(io_in_5_bits_instrSize),
    .io_in_5_bits_dirtyFs(io_in_5_bits_dirtyFs),
    .io_in_5_bits_dirtyVs(io_in_5_bits_dirtyVs),
    .io_in_5_bits_traceBlockInPipe_itype(io_in_5_bits_traceBlockInPipe_itype),
    .io_in_5_bits_traceBlockInPipe_iretire(io_in_5_bits_traceBlockInPipe_iretire),
    .io_in_5_bits_traceBlockInPipe_ilastsize(io_in_5_bits_traceBlockInPipe_ilastsize),
    .io_in_5_bits_eliminatedMove(io_in_5_bits_eliminatedMove),
    .io_in_5_bits_debugInfo_renameTime(io_in_5_bits_debugInfo_renameTime),
    .io_in_5_bits_debug_seqNum_seqNum(io_in_5_bits_debug_seqNum_seqNum),
    .io_in_5_bits_debug_seqNum_uopIdx(io_in_5_bits_debug_seqNum_uopIdx),
    .io_in_5_bits_debug_fuType(io_in_5_bits_debug_fuType),
    .io_in_5_bits_debug_sim_trig(io_in_5_bits_debug_sim_trig),
    .io_in_5_bits_numLsElem(io_in_5_bits_numLsElem),
    .io_out_5_bits_instr(g_l5_io_out_bits_instr),
    .io_out_5_bits_pc(g_l5_io_out_bits_pc),
    .io_out_5_bits_foldpc(g_l5_io_out_bits_foldpc),
    .io_out_5_bits_exceptionVec_0(g_l5_io_out_bits_exceptionVec_0),
    .io_out_5_bits_exceptionVec_1(g_l5_io_out_bits_exceptionVec_1),
    .io_out_5_bits_exceptionVec_2(g_l5_io_out_bits_exceptionVec_2),
    .io_out_5_bits_exceptionVec_3(g_l5_io_out_bits_exceptionVec_3),
    .io_out_5_bits_exceptionVec_4(g_l5_io_out_bits_exceptionVec_4),
    .io_out_5_bits_exceptionVec_5(g_l5_io_out_bits_exceptionVec_5),
    .io_out_5_bits_exceptionVec_6(g_l5_io_out_bits_exceptionVec_6),
    .io_out_5_bits_exceptionVec_7(g_l5_io_out_bits_exceptionVec_7),
    .io_out_5_bits_exceptionVec_8(g_l5_io_out_bits_exceptionVec_8),
    .io_out_5_bits_exceptionVec_9(g_l5_io_out_bits_exceptionVec_9),
    .io_out_5_bits_exceptionVec_10(g_l5_io_out_bits_exceptionVec_10),
    .io_out_5_bits_exceptionVec_11(g_l5_io_out_bits_exceptionVec_11),
    .io_out_5_bits_exceptionVec_12(g_l5_io_out_bits_exceptionVec_12),
    .io_out_5_bits_exceptionVec_13(g_l5_io_out_bits_exceptionVec_13),
    .io_out_5_bits_exceptionVec_14(g_l5_io_out_bits_exceptionVec_14),
    .io_out_5_bits_exceptionVec_15(g_l5_io_out_bits_exceptionVec_15),
    .io_out_5_bits_exceptionVec_16(g_l5_io_out_bits_exceptionVec_16),
    .io_out_5_bits_exceptionVec_17(g_l5_io_out_bits_exceptionVec_17),
    .io_out_5_bits_exceptionVec_18(g_l5_io_out_bits_exceptionVec_18),
    .io_out_5_bits_exceptionVec_19(g_l5_io_out_bits_exceptionVec_19),
    .io_out_5_bits_exceptionVec_20(g_l5_io_out_bits_exceptionVec_20),
    .io_out_5_bits_exceptionVec_21(g_l5_io_out_bits_exceptionVec_21),
    .io_out_5_bits_exceptionVec_22(g_l5_io_out_bits_exceptionVec_22),
    .io_out_5_bits_exceptionVec_23(g_l5_io_out_bits_exceptionVec_23),
    .io_out_5_bits_isFetchMalAddr(g_l5_io_out_bits_isFetchMalAddr),
    .io_out_5_bits_hasException(g_l5_io_out_bits_hasException),
    .io_out_5_bits_trigger(g_l5_io_out_bits_trigger),
    .io_out_5_bits_preDecodeInfo_valid(g_l5_io_out_bits_preDecodeInfo_valid),
    .io_out_5_bits_preDecodeInfo_isRVC(g_l5_io_out_bits_preDecodeInfo_isRVC),
    .io_out_5_bits_preDecodeInfo_brType(g_l5_io_out_bits_preDecodeInfo_brType),
    .io_out_5_bits_preDecodeInfo_isCall(g_l5_io_out_bits_preDecodeInfo_isCall),
    .io_out_5_bits_preDecodeInfo_isRet(g_l5_io_out_bits_preDecodeInfo_isRet),
    .io_out_5_bits_pred_taken(g_l5_io_out_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(g_l5_io_out_bits_crossPageIPFFix),
    .io_out_5_bits_ftqPtr_flag(g_l5_io_out_bits_ftqPtr_flag),
    .io_out_5_bits_ftqPtr_value(g_l5_io_out_bits_ftqPtr_value),
    .io_out_5_bits_ftqOffset(g_l5_io_out_bits_ftqOffset),
    .io_out_5_bits_satpFlushFirstFetchFault(g_l5_io_out_bits_satpFlushFirstFetchFault),
    .io_out_5_bits_srcType_0(g_l5_io_out_bits_srcType_0),
    .io_out_5_bits_srcType_1(g_l5_io_out_bits_srcType_1),
    .io_out_5_bits_srcType_2(g_l5_io_out_bits_srcType_2),
    .io_out_5_bits_srcType_3(g_l5_io_out_bits_srcType_3),
    .io_out_5_bits_srcType_4(g_l5_io_out_bits_srcType_4),
    .io_out_5_bits_ldest(g_l5_io_out_bits_ldest),
    .io_out_5_bits_fuType(g_l5_io_out_bits_fuType),
    .io_out_5_bits_fuOpType(g_l5_io_out_bits_fuOpType),
    .io_out_5_bits_rfWen(g_l5_io_out_bits_rfWen),
    .io_out_5_bits_fpWen(g_l5_io_out_bits_fpWen),
    .io_out_5_bits_vecWen(g_l5_io_out_bits_vecWen),
    .io_out_5_bits_v0Wen(g_l5_io_out_bits_v0Wen),
    .io_out_5_bits_vlWen(g_l5_io_out_bits_vlWen),
    .io_out_5_bits_isXSTrap(g_l5_io_out_bits_isXSTrap),
    .io_out_5_bits_waitForward(g_l5_io_out_bits_waitForward),
    .io_out_5_bits_blockBackward(g_l5_io_out_bits_blockBackward),
    .io_out_5_bits_flushPipe(g_l5_io_out_bits_flushPipe),
    .io_out_5_bits_canRobCompress(g_l5_io_out_bits_canRobCompress),
    .io_out_5_bits_selImm(g_l5_io_out_bits_selImm),
    .io_out_5_bits_imm(g_l5_io_out_bits_imm),
    .io_out_5_bits_fpu_typeTagOut(g_l5_io_out_bits_fpu_typeTagOut),
    .io_out_5_bits_fpu_wflags(g_l5_io_out_bits_fpu_wflags),
    .io_out_5_bits_fpu_typ(g_l5_io_out_bits_fpu_typ),
    .io_out_5_bits_fpu_fmt(g_l5_io_out_bits_fpu_fmt),
    .io_out_5_bits_fpu_rm(g_l5_io_out_bits_fpu_rm),
    .io_out_5_bits_vpu_vill(g_l5_io_out_bits_vpu_vill),
    .io_out_5_bits_vpu_vma(g_l5_io_out_bits_vpu_vma),
    .io_out_5_bits_vpu_vta(g_l5_io_out_bits_vpu_vta),
    .io_out_5_bits_vpu_vsew(g_l5_io_out_bits_vpu_vsew),
    .io_out_5_bits_vpu_vlmul(g_l5_io_out_bits_vpu_vlmul),
    .io_out_5_bits_vpu_specVill(g_l5_io_out_bits_vpu_specVill),
    .io_out_5_bits_vpu_specVma(g_l5_io_out_bits_vpu_specVma),
    .io_out_5_bits_vpu_specVta(g_l5_io_out_bits_vpu_specVta),
    .io_out_5_bits_vpu_specVsew(g_l5_io_out_bits_vpu_specVsew),
    .io_out_5_bits_vpu_specVlmul(g_l5_io_out_bits_vpu_specVlmul),
    .io_out_5_bits_vpu_vm(g_l5_io_out_bits_vpu_vm),
    .io_out_5_bits_vpu_vstart(g_l5_io_out_bits_vpu_vstart),
    .io_out_5_bits_vpu_frm(g_l5_io_out_bits_vpu_frm),
    .io_out_5_bits_vpu_fpu_isFpToVecInst(g_l5_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_5_bits_vpu_fpu_isFP32Instr(g_l5_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_5_bits_vpu_fpu_isFP64Instr(g_l5_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_5_bits_vpu_fpu_isReduction(g_l5_io_out_bits_vpu_fpu_isReduction),
    .io_out_5_bits_vpu_fpu_isFoldTo1_2(g_l5_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_5_bits_vpu_fpu_isFoldTo1_4(g_l5_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_5_bits_vpu_fpu_isFoldTo1_8(g_l5_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_5_bits_vpu_vxrm(g_l5_io_out_bits_vpu_vxrm),
    .io_out_5_bits_vpu_vuopIdx(g_l5_io_out_bits_vpu_vuopIdx),
    .io_out_5_bits_vpu_lastUop(g_l5_io_out_bits_vpu_lastUop),
    .io_out_5_bits_vpu_vmask(g_l5_io_out_bits_vpu_vmask),
    .io_out_5_bits_vpu_vl(g_l5_io_out_bits_vpu_vl),
    .io_out_5_bits_vpu_nf(g_l5_io_out_bits_vpu_nf),
    .io_out_5_bits_vpu_veew(g_l5_io_out_bits_vpu_veew),
    .io_out_5_bits_vpu_isReverse(g_l5_io_out_bits_vpu_isReverse),
    .io_out_5_bits_vpu_isExt(g_l5_io_out_bits_vpu_isExt),
    .io_out_5_bits_vpu_isNarrow(g_l5_io_out_bits_vpu_isNarrow),
    .io_out_5_bits_vpu_isDstMask(g_l5_io_out_bits_vpu_isDstMask),
    .io_out_5_bits_vpu_isOpMask(g_l5_io_out_bits_vpu_isOpMask),
    .io_out_5_bits_vpu_isMove(g_l5_io_out_bits_vpu_isMove),
    .io_out_5_bits_vpu_isDependOldVd(g_l5_io_out_bits_vpu_isDependOldVd),
    .io_out_5_bits_vpu_isWritePartVd(g_l5_io_out_bits_vpu_isWritePartVd),
    .io_out_5_bits_vpu_isVleff(g_l5_io_out_bits_vpu_isVleff),
    .io_out_5_bits_vlsInstr(g_l5_io_out_bits_vlsInstr),
    .io_out_5_bits_wfflags(g_l5_io_out_bits_wfflags),
    .io_out_5_bits_isMove(g_l5_io_out_bits_isMove),
    .io_out_5_bits_uopIdx(g_l5_io_out_bits_uopIdx),
    .io_out_5_bits_isVset(g_l5_io_out_bits_isVset),
    .io_out_5_bits_firstUop(g_l5_io_out_bits_firstUop),
    .io_out_5_bits_lastUop(g_l5_io_out_bits_lastUop),
    .io_out_5_bits_numUops(g_l5_io_out_bits_numUops),
    .io_out_5_bits_numWB(g_l5_io_out_bits_numWB),
    .io_out_5_bits_commitType(g_l5_io_out_bits_commitType),
    .io_out_5_bits_psrc_0(g_l5_io_out_bits_psrc_0),
    .io_out_5_bits_psrc_1(g_l5_io_out_bits_psrc_1),
    .io_out_5_bits_psrc_2(g_l5_io_out_bits_psrc_2),
    .io_out_5_bits_psrc_3(g_l5_io_out_bits_psrc_3),
    .io_out_5_bits_psrc_4(g_l5_io_out_bits_psrc_4),
    .io_out_5_bits_pdest(g_l5_io_out_bits_pdest),
    .io_out_5_bits_robIdx_flag(g_l5_io_out_bits_robIdx_flag),
    .io_out_5_bits_robIdx_value(g_l5_io_out_bits_robIdx_value),
    .io_out_5_bits_instrSize(g_l5_io_out_bits_instrSize),
    .io_out_5_bits_dirtyFs(g_l5_io_out_bits_dirtyFs),
    .io_out_5_bits_dirtyVs(g_l5_io_out_bits_dirtyVs),
    .io_out_5_bits_traceBlockInPipe_itype(g_l5_io_out_bits_traceBlockInPipe_itype),
    .io_out_5_bits_traceBlockInPipe_iretire(g_l5_io_out_bits_traceBlockInPipe_iretire),
    .io_out_5_bits_traceBlockInPipe_ilastsize(g_l5_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_5_bits_eliminatedMove(g_l5_io_out_bits_eliminatedMove),
    .io_out_5_bits_debugInfo_renameTime(g_l5_io_out_bits_debugInfo_renameTime),
    .io_out_5_bits_debug_seqNum_seqNum(g_l5_io_out_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx(g_l5_io_out_bits_debug_seqNum_uopIdx),
    .io_out_5_bits_debug_fuType(g_l5_io_out_bits_debug_fuType),
    .io_out_5_bits_debug_sim_trig(g_l5_io_out_bits_debug_sim_trig),
    .io_out_5_bits_numLsElem(g_l5_io_out_bits_numLsElem)
  );

  PipeGroupConnect_xs u_impl (
    .clock(clock), .reset(reset),
    .io_flush(io_flush), .io_outAllFire(io_outAllFire),
    .io_in_0_valid(io_in_0_valid), .io_in_0_ready(i_l0_io_in_ready),
    .io_out_0_ready(io_out_0_ready), .io_out_0_valid(i_l0_io_out_valid),
    .io_in_0_bits_instr(io_in_0_bits_instr),
    .io_in_0_bits_pc(io_in_0_bits_pc),
    .io_in_0_bits_foldpc(io_in_0_bits_foldpc),
    .io_in_0_bits_exceptionVec_0(io_in_0_bits_exceptionVec_0),
    .io_in_0_bits_exceptionVec_1(io_in_0_bits_exceptionVec_1),
    .io_in_0_bits_exceptionVec_2(io_in_0_bits_exceptionVec_2),
    .io_in_0_bits_exceptionVec_3(io_in_0_bits_exceptionVec_3),
    .io_in_0_bits_exceptionVec_4(io_in_0_bits_exceptionVec_4),
    .io_in_0_bits_exceptionVec_5(io_in_0_bits_exceptionVec_5),
    .io_in_0_bits_exceptionVec_6(io_in_0_bits_exceptionVec_6),
    .io_in_0_bits_exceptionVec_7(io_in_0_bits_exceptionVec_7),
    .io_in_0_bits_exceptionVec_8(io_in_0_bits_exceptionVec_8),
    .io_in_0_bits_exceptionVec_9(io_in_0_bits_exceptionVec_9),
    .io_in_0_bits_exceptionVec_10(io_in_0_bits_exceptionVec_10),
    .io_in_0_bits_exceptionVec_11(io_in_0_bits_exceptionVec_11),
    .io_in_0_bits_exceptionVec_12(io_in_0_bits_exceptionVec_12),
    .io_in_0_bits_exceptionVec_13(io_in_0_bits_exceptionVec_13),
    .io_in_0_bits_exceptionVec_14(io_in_0_bits_exceptionVec_14),
    .io_in_0_bits_exceptionVec_15(io_in_0_bits_exceptionVec_15),
    .io_in_0_bits_exceptionVec_16(io_in_0_bits_exceptionVec_16),
    .io_in_0_bits_exceptionVec_17(io_in_0_bits_exceptionVec_17),
    .io_in_0_bits_exceptionVec_18(io_in_0_bits_exceptionVec_18),
    .io_in_0_bits_exceptionVec_19(io_in_0_bits_exceptionVec_19),
    .io_in_0_bits_exceptionVec_20(io_in_0_bits_exceptionVec_20),
    .io_in_0_bits_exceptionVec_21(io_in_0_bits_exceptionVec_21),
    .io_in_0_bits_exceptionVec_22(io_in_0_bits_exceptionVec_22),
    .io_in_0_bits_exceptionVec_23(io_in_0_bits_exceptionVec_23),
    .io_in_0_bits_isFetchMalAddr(io_in_0_bits_isFetchMalAddr),
    .io_in_0_bits_hasException(io_in_0_bits_hasException),
    .io_in_0_bits_trigger(io_in_0_bits_trigger),
    .io_in_0_bits_preDecodeInfo_valid(io_in_0_bits_preDecodeInfo_valid),
    .io_in_0_bits_preDecodeInfo_isRVC(io_in_0_bits_preDecodeInfo_isRVC),
    .io_in_0_bits_preDecodeInfo_brType(io_in_0_bits_preDecodeInfo_brType),
    .io_in_0_bits_preDecodeInfo_isCall(io_in_0_bits_preDecodeInfo_isCall),
    .io_in_0_bits_preDecodeInfo_isRet(io_in_0_bits_preDecodeInfo_isRet),
    .io_in_0_bits_pred_taken(io_in_0_bits_pred_taken),
    .io_in_0_bits_crossPageIPFFix(io_in_0_bits_crossPageIPFFix),
    .io_in_0_bits_ftqPtr_flag(io_in_0_bits_ftqPtr_flag),
    .io_in_0_bits_ftqPtr_value(io_in_0_bits_ftqPtr_value),
    .io_in_0_bits_ftqOffset(io_in_0_bits_ftqOffset),
    .io_in_0_bits_satpFlushFirstFetchFault(io_in_0_bits_satpFlushFirstFetchFault),
    .io_in_0_bits_srcType_0(io_in_0_bits_srcType_0),
    .io_in_0_bits_srcType_1(io_in_0_bits_srcType_1),
    .io_in_0_bits_srcType_2(io_in_0_bits_srcType_2),
    .io_in_0_bits_srcType_3(io_in_0_bits_srcType_3),
    .io_in_0_bits_srcType_4(io_in_0_bits_srcType_4),
    .io_in_0_bits_ldest(io_in_0_bits_ldest),
    .io_in_0_bits_fuType(io_in_0_bits_fuType),
    .io_in_0_bits_fuOpType(io_in_0_bits_fuOpType),
    .io_in_0_bits_rfWen(io_in_0_bits_rfWen),
    .io_in_0_bits_fpWen(io_in_0_bits_fpWen),
    .io_in_0_bits_vecWen(io_in_0_bits_vecWen),
    .io_in_0_bits_v0Wen(io_in_0_bits_v0Wen),
    .io_in_0_bits_vlWen(io_in_0_bits_vlWen),
    .io_in_0_bits_isXSTrap(io_in_0_bits_isXSTrap),
    .io_in_0_bits_waitForward(io_in_0_bits_waitForward),
    .io_in_0_bits_blockBackward(io_in_0_bits_blockBackward),
    .io_in_0_bits_flushPipe(io_in_0_bits_flushPipe),
    .io_in_0_bits_canRobCompress(io_in_0_bits_canRobCompress),
    .io_in_0_bits_selImm(io_in_0_bits_selImm),
    .io_in_0_bits_imm(io_in_0_bits_imm),
    .io_in_0_bits_fpu_typeTagOut(io_in_0_bits_fpu_typeTagOut),
    .io_in_0_bits_fpu_wflags(io_in_0_bits_fpu_wflags),
    .io_in_0_bits_fpu_typ(io_in_0_bits_fpu_typ),
    .io_in_0_bits_fpu_fmt(io_in_0_bits_fpu_fmt),
    .io_in_0_bits_fpu_rm(io_in_0_bits_fpu_rm),
    .io_in_0_bits_vpu_vill(io_in_0_bits_vpu_vill),
    .io_in_0_bits_vpu_vma(io_in_0_bits_vpu_vma),
    .io_in_0_bits_vpu_vta(io_in_0_bits_vpu_vta),
    .io_in_0_bits_vpu_vsew(io_in_0_bits_vpu_vsew),
    .io_in_0_bits_vpu_vlmul(io_in_0_bits_vpu_vlmul),
    .io_in_0_bits_vpu_specVill(io_in_0_bits_vpu_specVill),
    .io_in_0_bits_vpu_specVma(io_in_0_bits_vpu_specVma),
    .io_in_0_bits_vpu_specVta(io_in_0_bits_vpu_specVta),
    .io_in_0_bits_vpu_specVsew(io_in_0_bits_vpu_specVsew),
    .io_in_0_bits_vpu_specVlmul(io_in_0_bits_vpu_specVlmul),
    .io_in_0_bits_vpu_vm(io_in_0_bits_vpu_vm),
    .io_in_0_bits_vpu_vstart(io_in_0_bits_vpu_vstart),
    .io_in_0_bits_vpu_frm(io_in_0_bits_vpu_frm),
    .io_in_0_bits_vpu_fpu_isFpToVecInst(io_in_0_bits_vpu_fpu_isFpToVecInst),
    .io_in_0_bits_vpu_fpu_isFP32Instr(io_in_0_bits_vpu_fpu_isFP32Instr),
    .io_in_0_bits_vpu_fpu_isFP64Instr(io_in_0_bits_vpu_fpu_isFP64Instr),
    .io_in_0_bits_vpu_fpu_isReduction(io_in_0_bits_vpu_fpu_isReduction),
    .io_in_0_bits_vpu_fpu_isFoldTo1_2(io_in_0_bits_vpu_fpu_isFoldTo1_2),
    .io_in_0_bits_vpu_fpu_isFoldTo1_4(io_in_0_bits_vpu_fpu_isFoldTo1_4),
    .io_in_0_bits_vpu_fpu_isFoldTo1_8(io_in_0_bits_vpu_fpu_isFoldTo1_8),
    .io_in_0_bits_vpu_vxrm(io_in_0_bits_vpu_vxrm),
    .io_in_0_bits_vpu_vuopIdx(io_in_0_bits_vpu_vuopIdx),
    .io_in_0_bits_vpu_lastUop(io_in_0_bits_vpu_lastUop),
    .io_in_0_bits_vpu_vmask(io_in_0_bits_vpu_vmask),
    .io_in_0_bits_vpu_vl(io_in_0_bits_vpu_vl),
    .io_in_0_bits_vpu_nf(io_in_0_bits_vpu_nf),
    .io_in_0_bits_vpu_veew(io_in_0_bits_vpu_veew),
    .io_in_0_bits_vpu_isReverse(io_in_0_bits_vpu_isReverse),
    .io_in_0_bits_vpu_isExt(io_in_0_bits_vpu_isExt),
    .io_in_0_bits_vpu_isNarrow(io_in_0_bits_vpu_isNarrow),
    .io_in_0_bits_vpu_isDstMask(io_in_0_bits_vpu_isDstMask),
    .io_in_0_bits_vpu_isOpMask(io_in_0_bits_vpu_isOpMask),
    .io_in_0_bits_vpu_isMove(io_in_0_bits_vpu_isMove),
    .io_in_0_bits_vpu_isDependOldVd(io_in_0_bits_vpu_isDependOldVd),
    .io_in_0_bits_vpu_isWritePartVd(io_in_0_bits_vpu_isWritePartVd),
    .io_in_0_bits_vpu_isVleff(io_in_0_bits_vpu_isVleff),
    .io_in_0_bits_vlsInstr(io_in_0_bits_vlsInstr),
    .io_in_0_bits_wfflags(io_in_0_bits_wfflags),
    .io_in_0_bits_isMove(io_in_0_bits_isMove),
    .io_in_0_bits_uopIdx(io_in_0_bits_uopIdx),
    .io_in_0_bits_isVset(io_in_0_bits_isVset),
    .io_in_0_bits_firstUop(io_in_0_bits_firstUop),
    .io_in_0_bits_lastUop(io_in_0_bits_lastUop),
    .io_in_0_bits_numUops(io_in_0_bits_numUops),
    .io_in_0_bits_numWB(io_in_0_bits_numWB),
    .io_in_0_bits_commitType(io_in_0_bits_commitType),
    .io_in_0_bits_psrc_0(io_in_0_bits_psrc_0),
    .io_in_0_bits_psrc_1(io_in_0_bits_psrc_1),
    .io_in_0_bits_psrc_2(io_in_0_bits_psrc_2),
    .io_in_0_bits_psrc_3(io_in_0_bits_psrc_3),
    .io_in_0_bits_psrc_4(io_in_0_bits_psrc_4),
    .io_in_0_bits_pdest(io_in_0_bits_pdest),
    .io_in_0_bits_robIdx_flag(io_in_0_bits_robIdx_flag),
    .io_in_0_bits_robIdx_value(io_in_0_bits_robIdx_value),
    .io_in_0_bits_instrSize(io_in_0_bits_instrSize),
    .io_in_0_bits_dirtyFs(io_in_0_bits_dirtyFs),
    .io_in_0_bits_dirtyVs(io_in_0_bits_dirtyVs),
    .io_in_0_bits_traceBlockInPipe_itype(io_in_0_bits_traceBlockInPipe_itype),
    .io_in_0_bits_traceBlockInPipe_iretire(io_in_0_bits_traceBlockInPipe_iretire),
    .io_in_0_bits_traceBlockInPipe_ilastsize(io_in_0_bits_traceBlockInPipe_ilastsize),
    .io_in_0_bits_eliminatedMove(io_in_0_bits_eliminatedMove),
    .io_in_0_bits_snapshot(io_in_0_bits_snapshot),
    .io_in_0_bits_debugInfo_renameTime(io_in_0_bits_debugInfo_renameTime),
    .io_in_0_bits_debug_seqNum_seqNum(io_in_0_bits_debug_seqNum_seqNum),
    .io_in_0_bits_debug_seqNum_uopIdx(io_in_0_bits_debug_seqNum_uopIdx),
    .io_in_0_bits_debug_fuType(io_in_0_bits_debug_fuType),
    .io_in_0_bits_debug_sim_trig(io_in_0_bits_debug_sim_trig),
    .io_in_0_bits_numLsElem(io_in_0_bits_numLsElem),
    .io_out_0_bits_instr(i_l0_io_out_bits_instr),
    .io_out_0_bits_pc(i_l0_io_out_bits_pc),
    .io_out_0_bits_foldpc(i_l0_io_out_bits_foldpc),
    .io_out_0_bits_exceptionVec_0(i_l0_io_out_bits_exceptionVec_0),
    .io_out_0_bits_exceptionVec_1(i_l0_io_out_bits_exceptionVec_1),
    .io_out_0_bits_exceptionVec_2(i_l0_io_out_bits_exceptionVec_2),
    .io_out_0_bits_exceptionVec_3(i_l0_io_out_bits_exceptionVec_3),
    .io_out_0_bits_exceptionVec_4(i_l0_io_out_bits_exceptionVec_4),
    .io_out_0_bits_exceptionVec_5(i_l0_io_out_bits_exceptionVec_5),
    .io_out_0_bits_exceptionVec_6(i_l0_io_out_bits_exceptionVec_6),
    .io_out_0_bits_exceptionVec_7(i_l0_io_out_bits_exceptionVec_7),
    .io_out_0_bits_exceptionVec_8(i_l0_io_out_bits_exceptionVec_8),
    .io_out_0_bits_exceptionVec_9(i_l0_io_out_bits_exceptionVec_9),
    .io_out_0_bits_exceptionVec_10(i_l0_io_out_bits_exceptionVec_10),
    .io_out_0_bits_exceptionVec_11(i_l0_io_out_bits_exceptionVec_11),
    .io_out_0_bits_exceptionVec_12(i_l0_io_out_bits_exceptionVec_12),
    .io_out_0_bits_exceptionVec_13(i_l0_io_out_bits_exceptionVec_13),
    .io_out_0_bits_exceptionVec_14(i_l0_io_out_bits_exceptionVec_14),
    .io_out_0_bits_exceptionVec_15(i_l0_io_out_bits_exceptionVec_15),
    .io_out_0_bits_exceptionVec_16(i_l0_io_out_bits_exceptionVec_16),
    .io_out_0_bits_exceptionVec_17(i_l0_io_out_bits_exceptionVec_17),
    .io_out_0_bits_exceptionVec_18(i_l0_io_out_bits_exceptionVec_18),
    .io_out_0_bits_exceptionVec_19(i_l0_io_out_bits_exceptionVec_19),
    .io_out_0_bits_exceptionVec_20(i_l0_io_out_bits_exceptionVec_20),
    .io_out_0_bits_exceptionVec_21(i_l0_io_out_bits_exceptionVec_21),
    .io_out_0_bits_exceptionVec_22(i_l0_io_out_bits_exceptionVec_22),
    .io_out_0_bits_exceptionVec_23(i_l0_io_out_bits_exceptionVec_23),
    .io_out_0_bits_isFetchMalAddr(i_l0_io_out_bits_isFetchMalAddr),
    .io_out_0_bits_hasException(i_l0_io_out_bits_hasException),
    .io_out_0_bits_trigger(i_l0_io_out_bits_trigger),
    .io_out_0_bits_preDecodeInfo_valid(i_l0_io_out_bits_preDecodeInfo_valid),
    .io_out_0_bits_preDecodeInfo_isRVC(i_l0_io_out_bits_preDecodeInfo_isRVC),
    .io_out_0_bits_preDecodeInfo_brType(i_l0_io_out_bits_preDecodeInfo_brType),
    .io_out_0_bits_preDecodeInfo_isCall(i_l0_io_out_bits_preDecodeInfo_isCall),
    .io_out_0_bits_preDecodeInfo_isRet(i_l0_io_out_bits_preDecodeInfo_isRet),
    .io_out_0_bits_pred_taken(i_l0_io_out_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(i_l0_io_out_bits_crossPageIPFFix),
    .io_out_0_bits_ftqPtr_flag(i_l0_io_out_bits_ftqPtr_flag),
    .io_out_0_bits_ftqPtr_value(i_l0_io_out_bits_ftqPtr_value),
    .io_out_0_bits_ftqOffset(i_l0_io_out_bits_ftqOffset),
    .io_out_0_bits_satpFlushFirstFetchFault(i_l0_io_out_bits_satpFlushFirstFetchFault),
    .io_out_0_bits_srcType_0(i_l0_io_out_bits_srcType_0),
    .io_out_0_bits_srcType_1(i_l0_io_out_bits_srcType_1),
    .io_out_0_bits_srcType_2(i_l0_io_out_bits_srcType_2),
    .io_out_0_bits_srcType_3(i_l0_io_out_bits_srcType_3),
    .io_out_0_bits_srcType_4(i_l0_io_out_bits_srcType_4),
    .io_out_0_bits_ldest(i_l0_io_out_bits_ldest),
    .io_out_0_bits_fuType(i_l0_io_out_bits_fuType),
    .io_out_0_bits_fuOpType(i_l0_io_out_bits_fuOpType),
    .io_out_0_bits_rfWen(i_l0_io_out_bits_rfWen),
    .io_out_0_bits_fpWen(i_l0_io_out_bits_fpWen),
    .io_out_0_bits_vecWen(i_l0_io_out_bits_vecWen),
    .io_out_0_bits_v0Wen(i_l0_io_out_bits_v0Wen),
    .io_out_0_bits_vlWen(i_l0_io_out_bits_vlWen),
    .io_out_0_bits_isXSTrap(i_l0_io_out_bits_isXSTrap),
    .io_out_0_bits_waitForward(i_l0_io_out_bits_waitForward),
    .io_out_0_bits_blockBackward(i_l0_io_out_bits_blockBackward),
    .io_out_0_bits_flushPipe(i_l0_io_out_bits_flushPipe),
    .io_out_0_bits_canRobCompress(i_l0_io_out_bits_canRobCompress),
    .io_out_0_bits_selImm(i_l0_io_out_bits_selImm),
    .io_out_0_bits_imm(i_l0_io_out_bits_imm),
    .io_out_0_bits_fpu_typeTagOut(i_l0_io_out_bits_fpu_typeTagOut),
    .io_out_0_bits_fpu_wflags(i_l0_io_out_bits_fpu_wflags),
    .io_out_0_bits_fpu_typ(i_l0_io_out_bits_fpu_typ),
    .io_out_0_bits_fpu_fmt(i_l0_io_out_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm(i_l0_io_out_bits_fpu_rm),
    .io_out_0_bits_vpu_vill(i_l0_io_out_bits_vpu_vill),
    .io_out_0_bits_vpu_vma(i_l0_io_out_bits_vpu_vma),
    .io_out_0_bits_vpu_vta(i_l0_io_out_bits_vpu_vta),
    .io_out_0_bits_vpu_vsew(i_l0_io_out_bits_vpu_vsew),
    .io_out_0_bits_vpu_vlmul(i_l0_io_out_bits_vpu_vlmul),
    .io_out_0_bits_vpu_specVill(i_l0_io_out_bits_vpu_specVill),
    .io_out_0_bits_vpu_specVma(i_l0_io_out_bits_vpu_specVma),
    .io_out_0_bits_vpu_specVta(i_l0_io_out_bits_vpu_specVta),
    .io_out_0_bits_vpu_specVsew(i_l0_io_out_bits_vpu_specVsew),
    .io_out_0_bits_vpu_specVlmul(i_l0_io_out_bits_vpu_specVlmul),
    .io_out_0_bits_vpu_vm(i_l0_io_out_bits_vpu_vm),
    .io_out_0_bits_vpu_vstart(i_l0_io_out_bits_vpu_vstart),
    .io_out_0_bits_vpu_frm(i_l0_io_out_bits_vpu_frm),
    .io_out_0_bits_vpu_fpu_isFpToVecInst(i_l0_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_0_bits_vpu_fpu_isFP32Instr(i_l0_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_0_bits_vpu_fpu_isFP64Instr(i_l0_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_0_bits_vpu_fpu_isReduction(i_l0_io_out_bits_vpu_fpu_isReduction),
    .io_out_0_bits_vpu_fpu_isFoldTo1_2(i_l0_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_0_bits_vpu_fpu_isFoldTo1_4(i_l0_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_0_bits_vpu_fpu_isFoldTo1_8(i_l0_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_0_bits_vpu_vxrm(i_l0_io_out_bits_vpu_vxrm),
    .io_out_0_bits_vpu_vuopIdx(i_l0_io_out_bits_vpu_vuopIdx),
    .io_out_0_bits_vpu_lastUop(i_l0_io_out_bits_vpu_lastUop),
    .io_out_0_bits_vpu_vmask(i_l0_io_out_bits_vpu_vmask),
    .io_out_0_bits_vpu_vl(i_l0_io_out_bits_vpu_vl),
    .io_out_0_bits_vpu_nf(i_l0_io_out_bits_vpu_nf),
    .io_out_0_bits_vpu_veew(i_l0_io_out_bits_vpu_veew),
    .io_out_0_bits_vpu_isReverse(i_l0_io_out_bits_vpu_isReverse),
    .io_out_0_bits_vpu_isExt(i_l0_io_out_bits_vpu_isExt),
    .io_out_0_bits_vpu_isNarrow(i_l0_io_out_bits_vpu_isNarrow),
    .io_out_0_bits_vpu_isDstMask(i_l0_io_out_bits_vpu_isDstMask),
    .io_out_0_bits_vpu_isOpMask(i_l0_io_out_bits_vpu_isOpMask),
    .io_out_0_bits_vpu_isMove(i_l0_io_out_bits_vpu_isMove),
    .io_out_0_bits_vpu_isDependOldVd(i_l0_io_out_bits_vpu_isDependOldVd),
    .io_out_0_bits_vpu_isWritePartVd(i_l0_io_out_bits_vpu_isWritePartVd),
    .io_out_0_bits_vpu_isVleff(i_l0_io_out_bits_vpu_isVleff),
    .io_out_0_bits_vlsInstr(i_l0_io_out_bits_vlsInstr),
    .io_out_0_bits_wfflags(i_l0_io_out_bits_wfflags),
    .io_out_0_bits_isMove(i_l0_io_out_bits_isMove),
    .io_out_0_bits_uopIdx(i_l0_io_out_bits_uopIdx),
    .io_out_0_bits_isVset(i_l0_io_out_bits_isVset),
    .io_out_0_bits_firstUop(i_l0_io_out_bits_firstUop),
    .io_out_0_bits_lastUop(i_l0_io_out_bits_lastUop),
    .io_out_0_bits_numUops(i_l0_io_out_bits_numUops),
    .io_out_0_bits_numWB(i_l0_io_out_bits_numWB),
    .io_out_0_bits_commitType(i_l0_io_out_bits_commitType),
    .io_out_0_bits_psrc_0(i_l0_io_out_bits_psrc_0),
    .io_out_0_bits_psrc_1(i_l0_io_out_bits_psrc_1),
    .io_out_0_bits_psrc_2(i_l0_io_out_bits_psrc_2),
    .io_out_0_bits_psrc_3(i_l0_io_out_bits_psrc_3),
    .io_out_0_bits_psrc_4(i_l0_io_out_bits_psrc_4),
    .io_out_0_bits_pdest(i_l0_io_out_bits_pdest),
    .io_out_0_bits_robIdx_flag(i_l0_io_out_bits_robIdx_flag),
    .io_out_0_bits_robIdx_value(i_l0_io_out_bits_robIdx_value),
    .io_out_0_bits_instrSize(i_l0_io_out_bits_instrSize),
    .io_out_0_bits_dirtyFs(i_l0_io_out_bits_dirtyFs),
    .io_out_0_bits_dirtyVs(i_l0_io_out_bits_dirtyVs),
    .io_out_0_bits_traceBlockInPipe_itype(i_l0_io_out_bits_traceBlockInPipe_itype),
    .io_out_0_bits_traceBlockInPipe_iretire(i_l0_io_out_bits_traceBlockInPipe_iretire),
    .io_out_0_bits_traceBlockInPipe_ilastsize(i_l0_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_0_bits_eliminatedMove(i_l0_io_out_bits_eliminatedMove),
    .io_out_0_bits_snapshot(i_l0_io_out_bits_snapshot),
    .io_out_0_bits_debugInfo_renameTime(i_l0_io_out_bits_debugInfo_renameTime),
    .io_out_0_bits_debug_seqNum_seqNum(i_l0_io_out_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx(i_l0_io_out_bits_debug_seqNum_uopIdx),
    .io_out_0_bits_debug_fuType(i_l0_io_out_bits_debug_fuType),
    .io_out_0_bits_debug_sim_trig(i_l0_io_out_bits_debug_sim_trig),
    .io_out_0_bits_numLsElem(i_l0_io_out_bits_numLsElem),
    .io_in_1_valid(io_in_1_valid), .io_in_1_ready(i_l1_io_in_ready),
    .io_out_1_ready(io_out_1_ready), .io_out_1_valid(i_l1_io_out_valid),
    .io_in_1_bits_instr(io_in_1_bits_instr),
    .io_in_1_bits_pc(io_in_1_bits_pc),
    .io_in_1_bits_foldpc(io_in_1_bits_foldpc),
    .io_in_1_bits_exceptionVec_0(io_in_1_bits_exceptionVec_0),
    .io_in_1_bits_exceptionVec_1(io_in_1_bits_exceptionVec_1),
    .io_in_1_bits_exceptionVec_2(io_in_1_bits_exceptionVec_2),
    .io_in_1_bits_exceptionVec_3(io_in_1_bits_exceptionVec_3),
    .io_in_1_bits_exceptionVec_4(io_in_1_bits_exceptionVec_4),
    .io_in_1_bits_exceptionVec_5(io_in_1_bits_exceptionVec_5),
    .io_in_1_bits_exceptionVec_6(io_in_1_bits_exceptionVec_6),
    .io_in_1_bits_exceptionVec_7(io_in_1_bits_exceptionVec_7),
    .io_in_1_bits_exceptionVec_8(io_in_1_bits_exceptionVec_8),
    .io_in_1_bits_exceptionVec_9(io_in_1_bits_exceptionVec_9),
    .io_in_1_bits_exceptionVec_10(io_in_1_bits_exceptionVec_10),
    .io_in_1_bits_exceptionVec_11(io_in_1_bits_exceptionVec_11),
    .io_in_1_bits_exceptionVec_12(io_in_1_bits_exceptionVec_12),
    .io_in_1_bits_exceptionVec_13(io_in_1_bits_exceptionVec_13),
    .io_in_1_bits_exceptionVec_14(io_in_1_bits_exceptionVec_14),
    .io_in_1_bits_exceptionVec_15(io_in_1_bits_exceptionVec_15),
    .io_in_1_bits_exceptionVec_16(io_in_1_bits_exceptionVec_16),
    .io_in_1_bits_exceptionVec_17(io_in_1_bits_exceptionVec_17),
    .io_in_1_bits_exceptionVec_18(io_in_1_bits_exceptionVec_18),
    .io_in_1_bits_exceptionVec_19(io_in_1_bits_exceptionVec_19),
    .io_in_1_bits_exceptionVec_20(io_in_1_bits_exceptionVec_20),
    .io_in_1_bits_exceptionVec_21(io_in_1_bits_exceptionVec_21),
    .io_in_1_bits_exceptionVec_22(io_in_1_bits_exceptionVec_22),
    .io_in_1_bits_exceptionVec_23(io_in_1_bits_exceptionVec_23),
    .io_in_1_bits_isFetchMalAddr(io_in_1_bits_isFetchMalAddr),
    .io_in_1_bits_hasException(io_in_1_bits_hasException),
    .io_in_1_bits_trigger(io_in_1_bits_trigger),
    .io_in_1_bits_preDecodeInfo_valid(io_in_1_bits_preDecodeInfo_valid),
    .io_in_1_bits_preDecodeInfo_isRVC(io_in_1_bits_preDecodeInfo_isRVC),
    .io_in_1_bits_preDecodeInfo_brType(io_in_1_bits_preDecodeInfo_brType),
    .io_in_1_bits_preDecodeInfo_isCall(io_in_1_bits_preDecodeInfo_isCall),
    .io_in_1_bits_preDecodeInfo_isRet(io_in_1_bits_preDecodeInfo_isRet),
    .io_in_1_bits_pred_taken(io_in_1_bits_pred_taken),
    .io_in_1_bits_crossPageIPFFix(io_in_1_bits_crossPageIPFFix),
    .io_in_1_bits_ftqPtr_flag(io_in_1_bits_ftqPtr_flag),
    .io_in_1_bits_ftqPtr_value(io_in_1_bits_ftqPtr_value),
    .io_in_1_bits_ftqOffset(io_in_1_bits_ftqOffset),
    .io_in_1_bits_satpFlushFirstFetchFault(io_in_1_bits_satpFlushFirstFetchFault),
    .io_in_1_bits_srcType_0(io_in_1_bits_srcType_0),
    .io_in_1_bits_srcType_1(io_in_1_bits_srcType_1),
    .io_in_1_bits_srcType_2(io_in_1_bits_srcType_2),
    .io_in_1_bits_srcType_3(io_in_1_bits_srcType_3),
    .io_in_1_bits_srcType_4(io_in_1_bits_srcType_4),
    .io_in_1_bits_ldest(io_in_1_bits_ldest),
    .io_in_1_bits_fuType(io_in_1_bits_fuType),
    .io_in_1_bits_fuOpType(io_in_1_bits_fuOpType),
    .io_in_1_bits_rfWen(io_in_1_bits_rfWen),
    .io_in_1_bits_fpWen(io_in_1_bits_fpWen),
    .io_in_1_bits_vecWen(io_in_1_bits_vecWen),
    .io_in_1_bits_v0Wen(io_in_1_bits_v0Wen),
    .io_in_1_bits_vlWen(io_in_1_bits_vlWen),
    .io_in_1_bits_isXSTrap(io_in_1_bits_isXSTrap),
    .io_in_1_bits_waitForward(io_in_1_bits_waitForward),
    .io_in_1_bits_blockBackward(io_in_1_bits_blockBackward),
    .io_in_1_bits_flushPipe(io_in_1_bits_flushPipe),
    .io_in_1_bits_canRobCompress(io_in_1_bits_canRobCompress),
    .io_in_1_bits_selImm(io_in_1_bits_selImm),
    .io_in_1_bits_imm(io_in_1_bits_imm),
    .io_in_1_bits_fpu_typeTagOut(io_in_1_bits_fpu_typeTagOut),
    .io_in_1_bits_fpu_wflags(io_in_1_bits_fpu_wflags),
    .io_in_1_bits_fpu_typ(io_in_1_bits_fpu_typ),
    .io_in_1_bits_fpu_fmt(io_in_1_bits_fpu_fmt),
    .io_in_1_bits_fpu_rm(io_in_1_bits_fpu_rm),
    .io_in_1_bits_vpu_vill(io_in_1_bits_vpu_vill),
    .io_in_1_bits_vpu_vma(io_in_1_bits_vpu_vma),
    .io_in_1_bits_vpu_vta(io_in_1_bits_vpu_vta),
    .io_in_1_bits_vpu_vsew(io_in_1_bits_vpu_vsew),
    .io_in_1_bits_vpu_vlmul(io_in_1_bits_vpu_vlmul),
    .io_in_1_bits_vpu_specVill(io_in_1_bits_vpu_specVill),
    .io_in_1_bits_vpu_specVma(io_in_1_bits_vpu_specVma),
    .io_in_1_bits_vpu_specVta(io_in_1_bits_vpu_specVta),
    .io_in_1_bits_vpu_specVsew(io_in_1_bits_vpu_specVsew),
    .io_in_1_bits_vpu_specVlmul(io_in_1_bits_vpu_specVlmul),
    .io_in_1_bits_vpu_vm(io_in_1_bits_vpu_vm),
    .io_in_1_bits_vpu_vstart(io_in_1_bits_vpu_vstart),
    .io_in_1_bits_vpu_frm(io_in_1_bits_vpu_frm),
    .io_in_1_bits_vpu_fpu_isFpToVecInst(io_in_1_bits_vpu_fpu_isFpToVecInst),
    .io_in_1_bits_vpu_fpu_isFP32Instr(io_in_1_bits_vpu_fpu_isFP32Instr),
    .io_in_1_bits_vpu_fpu_isFP64Instr(io_in_1_bits_vpu_fpu_isFP64Instr),
    .io_in_1_bits_vpu_fpu_isReduction(io_in_1_bits_vpu_fpu_isReduction),
    .io_in_1_bits_vpu_fpu_isFoldTo1_2(io_in_1_bits_vpu_fpu_isFoldTo1_2),
    .io_in_1_bits_vpu_fpu_isFoldTo1_4(io_in_1_bits_vpu_fpu_isFoldTo1_4),
    .io_in_1_bits_vpu_fpu_isFoldTo1_8(io_in_1_bits_vpu_fpu_isFoldTo1_8),
    .io_in_1_bits_vpu_vxrm(io_in_1_bits_vpu_vxrm),
    .io_in_1_bits_vpu_vuopIdx(io_in_1_bits_vpu_vuopIdx),
    .io_in_1_bits_vpu_lastUop(io_in_1_bits_vpu_lastUop),
    .io_in_1_bits_vpu_vmask(io_in_1_bits_vpu_vmask),
    .io_in_1_bits_vpu_vl(io_in_1_bits_vpu_vl),
    .io_in_1_bits_vpu_nf(io_in_1_bits_vpu_nf),
    .io_in_1_bits_vpu_veew(io_in_1_bits_vpu_veew),
    .io_in_1_bits_vpu_isReverse(io_in_1_bits_vpu_isReverse),
    .io_in_1_bits_vpu_isExt(io_in_1_bits_vpu_isExt),
    .io_in_1_bits_vpu_isNarrow(io_in_1_bits_vpu_isNarrow),
    .io_in_1_bits_vpu_isDstMask(io_in_1_bits_vpu_isDstMask),
    .io_in_1_bits_vpu_isOpMask(io_in_1_bits_vpu_isOpMask),
    .io_in_1_bits_vpu_isMove(io_in_1_bits_vpu_isMove),
    .io_in_1_bits_vpu_isDependOldVd(io_in_1_bits_vpu_isDependOldVd),
    .io_in_1_bits_vpu_isWritePartVd(io_in_1_bits_vpu_isWritePartVd),
    .io_in_1_bits_vpu_isVleff(io_in_1_bits_vpu_isVleff),
    .io_in_1_bits_vlsInstr(io_in_1_bits_vlsInstr),
    .io_in_1_bits_wfflags(io_in_1_bits_wfflags),
    .io_in_1_bits_isMove(io_in_1_bits_isMove),
    .io_in_1_bits_uopIdx(io_in_1_bits_uopIdx),
    .io_in_1_bits_isVset(io_in_1_bits_isVset),
    .io_in_1_bits_firstUop(io_in_1_bits_firstUop),
    .io_in_1_bits_lastUop(io_in_1_bits_lastUop),
    .io_in_1_bits_numUops(io_in_1_bits_numUops),
    .io_in_1_bits_numWB(io_in_1_bits_numWB),
    .io_in_1_bits_commitType(io_in_1_bits_commitType),
    .io_in_1_bits_psrc_0(io_in_1_bits_psrc_0),
    .io_in_1_bits_psrc_1(io_in_1_bits_psrc_1),
    .io_in_1_bits_psrc_2(io_in_1_bits_psrc_2),
    .io_in_1_bits_psrc_3(io_in_1_bits_psrc_3),
    .io_in_1_bits_psrc_4(io_in_1_bits_psrc_4),
    .io_in_1_bits_pdest(io_in_1_bits_pdest),
    .io_in_1_bits_robIdx_flag(io_in_1_bits_robIdx_flag),
    .io_in_1_bits_robIdx_value(io_in_1_bits_robIdx_value),
    .io_in_1_bits_instrSize(io_in_1_bits_instrSize),
    .io_in_1_bits_dirtyFs(io_in_1_bits_dirtyFs),
    .io_in_1_bits_dirtyVs(io_in_1_bits_dirtyVs),
    .io_in_1_bits_traceBlockInPipe_itype(io_in_1_bits_traceBlockInPipe_itype),
    .io_in_1_bits_traceBlockInPipe_iretire(io_in_1_bits_traceBlockInPipe_iretire),
    .io_in_1_bits_traceBlockInPipe_ilastsize(io_in_1_bits_traceBlockInPipe_ilastsize),
    .io_in_1_bits_eliminatedMove(io_in_1_bits_eliminatedMove),
    .io_in_1_bits_debugInfo_renameTime(io_in_1_bits_debugInfo_renameTime),
    .io_in_1_bits_debug_seqNum_seqNum(io_in_1_bits_debug_seqNum_seqNum),
    .io_in_1_bits_debug_seqNum_uopIdx(io_in_1_bits_debug_seqNum_uopIdx),
    .io_in_1_bits_debug_fuType(io_in_1_bits_debug_fuType),
    .io_in_1_bits_debug_sim_trig(io_in_1_bits_debug_sim_trig),
    .io_in_1_bits_numLsElem(io_in_1_bits_numLsElem),
    .io_out_1_bits_instr(i_l1_io_out_bits_instr),
    .io_out_1_bits_pc(i_l1_io_out_bits_pc),
    .io_out_1_bits_foldpc(i_l1_io_out_bits_foldpc),
    .io_out_1_bits_exceptionVec_0(i_l1_io_out_bits_exceptionVec_0),
    .io_out_1_bits_exceptionVec_1(i_l1_io_out_bits_exceptionVec_1),
    .io_out_1_bits_exceptionVec_2(i_l1_io_out_bits_exceptionVec_2),
    .io_out_1_bits_exceptionVec_3(i_l1_io_out_bits_exceptionVec_3),
    .io_out_1_bits_exceptionVec_4(i_l1_io_out_bits_exceptionVec_4),
    .io_out_1_bits_exceptionVec_5(i_l1_io_out_bits_exceptionVec_5),
    .io_out_1_bits_exceptionVec_6(i_l1_io_out_bits_exceptionVec_6),
    .io_out_1_bits_exceptionVec_7(i_l1_io_out_bits_exceptionVec_7),
    .io_out_1_bits_exceptionVec_8(i_l1_io_out_bits_exceptionVec_8),
    .io_out_1_bits_exceptionVec_9(i_l1_io_out_bits_exceptionVec_9),
    .io_out_1_bits_exceptionVec_10(i_l1_io_out_bits_exceptionVec_10),
    .io_out_1_bits_exceptionVec_11(i_l1_io_out_bits_exceptionVec_11),
    .io_out_1_bits_exceptionVec_12(i_l1_io_out_bits_exceptionVec_12),
    .io_out_1_bits_exceptionVec_13(i_l1_io_out_bits_exceptionVec_13),
    .io_out_1_bits_exceptionVec_14(i_l1_io_out_bits_exceptionVec_14),
    .io_out_1_bits_exceptionVec_15(i_l1_io_out_bits_exceptionVec_15),
    .io_out_1_bits_exceptionVec_16(i_l1_io_out_bits_exceptionVec_16),
    .io_out_1_bits_exceptionVec_17(i_l1_io_out_bits_exceptionVec_17),
    .io_out_1_bits_exceptionVec_18(i_l1_io_out_bits_exceptionVec_18),
    .io_out_1_bits_exceptionVec_19(i_l1_io_out_bits_exceptionVec_19),
    .io_out_1_bits_exceptionVec_20(i_l1_io_out_bits_exceptionVec_20),
    .io_out_1_bits_exceptionVec_21(i_l1_io_out_bits_exceptionVec_21),
    .io_out_1_bits_exceptionVec_22(i_l1_io_out_bits_exceptionVec_22),
    .io_out_1_bits_exceptionVec_23(i_l1_io_out_bits_exceptionVec_23),
    .io_out_1_bits_isFetchMalAddr(i_l1_io_out_bits_isFetchMalAddr),
    .io_out_1_bits_hasException(i_l1_io_out_bits_hasException),
    .io_out_1_bits_trigger(i_l1_io_out_bits_trigger),
    .io_out_1_bits_preDecodeInfo_valid(i_l1_io_out_bits_preDecodeInfo_valid),
    .io_out_1_bits_preDecodeInfo_isRVC(i_l1_io_out_bits_preDecodeInfo_isRVC),
    .io_out_1_bits_preDecodeInfo_brType(i_l1_io_out_bits_preDecodeInfo_brType),
    .io_out_1_bits_preDecodeInfo_isCall(i_l1_io_out_bits_preDecodeInfo_isCall),
    .io_out_1_bits_preDecodeInfo_isRet(i_l1_io_out_bits_preDecodeInfo_isRet),
    .io_out_1_bits_pred_taken(i_l1_io_out_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(i_l1_io_out_bits_crossPageIPFFix),
    .io_out_1_bits_ftqPtr_flag(i_l1_io_out_bits_ftqPtr_flag),
    .io_out_1_bits_ftqPtr_value(i_l1_io_out_bits_ftqPtr_value),
    .io_out_1_bits_ftqOffset(i_l1_io_out_bits_ftqOffset),
    .io_out_1_bits_satpFlushFirstFetchFault(i_l1_io_out_bits_satpFlushFirstFetchFault),
    .io_out_1_bits_srcType_0(i_l1_io_out_bits_srcType_0),
    .io_out_1_bits_srcType_1(i_l1_io_out_bits_srcType_1),
    .io_out_1_bits_srcType_2(i_l1_io_out_bits_srcType_2),
    .io_out_1_bits_srcType_3(i_l1_io_out_bits_srcType_3),
    .io_out_1_bits_srcType_4(i_l1_io_out_bits_srcType_4),
    .io_out_1_bits_ldest(i_l1_io_out_bits_ldest),
    .io_out_1_bits_fuType(i_l1_io_out_bits_fuType),
    .io_out_1_bits_fuOpType(i_l1_io_out_bits_fuOpType),
    .io_out_1_bits_rfWen(i_l1_io_out_bits_rfWen),
    .io_out_1_bits_fpWen(i_l1_io_out_bits_fpWen),
    .io_out_1_bits_vecWen(i_l1_io_out_bits_vecWen),
    .io_out_1_bits_v0Wen(i_l1_io_out_bits_v0Wen),
    .io_out_1_bits_vlWen(i_l1_io_out_bits_vlWen),
    .io_out_1_bits_isXSTrap(i_l1_io_out_bits_isXSTrap),
    .io_out_1_bits_waitForward(i_l1_io_out_bits_waitForward),
    .io_out_1_bits_blockBackward(i_l1_io_out_bits_blockBackward),
    .io_out_1_bits_flushPipe(i_l1_io_out_bits_flushPipe),
    .io_out_1_bits_canRobCompress(i_l1_io_out_bits_canRobCompress),
    .io_out_1_bits_selImm(i_l1_io_out_bits_selImm),
    .io_out_1_bits_imm(i_l1_io_out_bits_imm),
    .io_out_1_bits_fpu_typeTagOut(i_l1_io_out_bits_fpu_typeTagOut),
    .io_out_1_bits_fpu_wflags(i_l1_io_out_bits_fpu_wflags),
    .io_out_1_bits_fpu_typ(i_l1_io_out_bits_fpu_typ),
    .io_out_1_bits_fpu_fmt(i_l1_io_out_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm(i_l1_io_out_bits_fpu_rm),
    .io_out_1_bits_vpu_vill(i_l1_io_out_bits_vpu_vill),
    .io_out_1_bits_vpu_vma(i_l1_io_out_bits_vpu_vma),
    .io_out_1_bits_vpu_vta(i_l1_io_out_bits_vpu_vta),
    .io_out_1_bits_vpu_vsew(i_l1_io_out_bits_vpu_vsew),
    .io_out_1_bits_vpu_vlmul(i_l1_io_out_bits_vpu_vlmul),
    .io_out_1_bits_vpu_specVill(i_l1_io_out_bits_vpu_specVill),
    .io_out_1_bits_vpu_specVma(i_l1_io_out_bits_vpu_specVma),
    .io_out_1_bits_vpu_specVta(i_l1_io_out_bits_vpu_specVta),
    .io_out_1_bits_vpu_specVsew(i_l1_io_out_bits_vpu_specVsew),
    .io_out_1_bits_vpu_specVlmul(i_l1_io_out_bits_vpu_specVlmul),
    .io_out_1_bits_vpu_vm(i_l1_io_out_bits_vpu_vm),
    .io_out_1_bits_vpu_vstart(i_l1_io_out_bits_vpu_vstart),
    .io_out_1_bits_vpu_frm(i_l1_io_out_bits_vpu_frm),
    .io_out_1_bits_vpu_fpu_isFpToVecInst(i_l1_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_1_bits_vpu_fpu_isFP32Instr(i_l1_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_1_bits_vpu_fpu_isFP64Instr(i_l1_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_1_bits_vpu_fpu_isReduction(i_l1_io_out_bits_vpu_fpu_isReduction),
    .io_out_1_bits_vpu_fpu_isFoldTo1_2(i_l1_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_1_bits_vpu_fpu_isFoldTo1_4(i_l1_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_1_bits_vpu_fpu_isFoldTo1_8(i_l1_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_1_bits_vpu_vxrm(i_l1_io_out_bits_vpu_vxrm),
    .io_out_1_bits_vpu_vuopIdx(i_l1_io_out_bits_vpu_vuopIdx),
    .io_out_1_bits_vpu_lastUop(i_l1_io_out_bits_vpu_lastUop),
    .io_out_1_bits_vpu_vmask(i_l1_io_out_bits_vpu_vmask),
    .io_out_1_bits_vpu_vl(i_l1_io_out_bits_vpu_vl),
    .io_out_1_bits_vpu_nf(i_l1_io_out_bits_vpu_nf),
    .io_out_1_bits_vpu_veew(i_l1_io_out_bits_vpu_veew),
    .io_out_1_bits_vpu_isReverse(i_l1_io_out_bits_vpu_isReverse),
    .io_out_1_bits_vpu_isExt(i_l1_io_out_bits_vpu_isExt),
    .io_out_1_bits_vpu_isNarrow(i_l1_io_out_bits_vpu_isNarrow),
    .io_out_1_bits_vpu_isDstMask(i_l1_io_out_bits_vpu_isDstMask),
    .io_out_1_bits_vpu_isOpMask(i_l1_io_out_bits_vpu_isOpMask),
    .io_out_1_bits_vpu_isMove(i_l1_io_out_bits_vpu_isMove),
    .io_out_1_bits_vpu_isDependOldVd(i_l1_io_out_bits_vpu_isDependOldVd),
    .io_out_1_bits_vpu_isWritePartVd(i_l1_io_out_bits_vpu_isWritePartVd),
    .io_out_1_bits_vpu_isVleff(i_l1_io_out_bits_vpu_isVleff),
    .io_out_1_bits_vlsInstr(i_l1_io_out_bits_vlsInstr),
    .io_out_1_bits_wfflags(i_l1_io_out_bits_wfflags),
    .io_out_1_bits_isMove(i_l1_io_out_bits_isMove),
    .io_out_1_bits_uopIdx(i_l1_io_out_bits_uopIdx),
    .io_out_1_bits_isVset(i_l1_io_out_bits_isVset),
    .io_out_1_bits_firstUop(i_l1_io_out_bits_firstUop),
    .io_out_1_bits_lastUop(i_l1_io_out_bits_lastUop),
    .io_out_1_bits_numUops(i_l1_io_out_bits_numUops),
    .io_out_1_bits_numWB(i_l1_io_out_bits_numWB),
    .io_out_1_bits_commitType(i_l1_io_out_bits_commitType),
    .io_out_1_bits_psrc_0(i_l1_io_out_bits_psrc_0),
    .io_out_1_bits_psrc_1(i_l1_io_out_bits_psrc_1),
    .io_out_1_bits_psrc_2(i_l1_io_out_bits_psrc_2),
    .io_out_1_bits_psrc_3(i_l1_io_out_bits_psrc_3),
    .io_out_1_bits_psrc_4(i_l1_io_out_bits_psrc_4),
    .io_out_1_bits_pdest(i_l1_io_out_bits_pdest),
    .io_out_1_bits_robIdx_flag(i_l1_io_out_bits_robIdx_flag),
    .io_out_1_bits_robIdx_value(i_l1_io_out_bits_robIdx_value),
    .io_out_1_bits_instrSize(i_l1_io_out_bits_instrSize),
    .io_out_1_bits_dirtyFs(i_l1_io_out_bits_dirtyFs),
    .io_out_1_bits_dirtyVs(i_l1_io_out_bits_dirtyVs),
    .io_out_1_bits_traceBlockInPipe_itype(i_l1_io_out_bits_traceBlockInPipe_itype),
    .io_out_1_bits_traceBlockInPipe_iretire(i_l1_io_out_bits_traceBlockInPipe_iretire),
    .io_out_1_bits_traceBlockInPipe_ilastsize(i_l1_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_1_bits_eliminatedMove(i_l1_io_out_bits_eliminatedMove),
    .io_out_1_bits_debugInfo_renameTime(i_l1_io_out_bits_debugInfo_renameTime),
    .io_out_1_bits_debug_seqNum_seqNum(i_l1_io_out_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx(i_l1_io_out_bits_debug_seqNum_uopIdx),
    .io_out_1_bits_debug_fuType(i_l1_io_out_bits_debug_fuType),
    .io_out_1_bits_debug_sim_trig(i_l1_io_out_bits_debug_sim_trig),
    .io_out_1_bits_numLsElem(i_l1_io_out_bits_numLsElem),
    .io_in_2_valid(io_in_2_valid), .io_in_2_ready(i_l2_io_in_ready),
    .io_out_2_ready(io_out_2_ready), .io_out_2_valid(i_l2_io_out_valid),
    .io_in_2_bits_instr(io_in_2_bits_instr),
    .io_in_2_bits_pc(io_in_2_bits_pc),
    .io_in_2_bits_foldpc(io_in_2_bits_foldpc),
    .io_in_2_bits_exceptionVec_0(io_in_2_bits_exceptionVec_0),
    .io_in_2_bits_exceptionVec_1(io_in_2_bits_exceptionVec_1),
    .io_in_2_bits_exceptionVec_2(io_in_2_bits_exceptionVec_2),
    .io_in_2_bits_exceptionVec_3(io_in_2_bits_exceptionVec_3),
    .io_in_2_bits_exceptionVec_4(io_in_2_bits_exceptionVec_4),
    .io_in_2_bits_exceptionVec_5(io_in_2_bits_exceptionVec_5),
    .io_in_2_bits_exceptionVec_6(io_in_2_bits_exceptionVec_6),
    .io_in_2_bits_exceptionVec_7(io_in_2_bits_exceptionVec_7),
    .io_in_2_bits_exceptionVec_8(io_in_2_bits_exceptionVec_8),
    .io_in_2_bits_exceptionVec_9(io_in_2_bits_exceptionVec_9),
    .io_in_2_bits_exceptionVec_10(io_in_2_bits_exceptionVec_10),
    .io_in_2_bits_exceptionVec_11(io_in_2_bits_exceptionVec_11),
    .io_in_2_bits_exceptionVec_12(io_in_2_bits_exceptionVec_12),
    .io_in_2_bits_exceptionVec_13(io_in_2_bits_exceptionVec_13),
    .io_in_2_bits_exceptionVec_14(io_in_2_bits_exceptionVec_14),
    .io_in_2_bits_exceptionVec_15(io_in_2_bits_exceptionVec_15),
    .io_in_2_bits_exceptionVec_16(io_in_2_bits_exceptionVec_16),
    .io_in_2_bits_exceptionVec_17(io_in_2_bits_exceptionVec_17),
    .io_in_2_bits_exceptionVec_18(io_in_2_bits_exceptionVec_18),
    .io_in_2_bits_exceptionVec_19(io_in_2_bits_exceptionVec_19),
    .io_in_2_bits_exceptionVec_20(io_in_2_bits_exceptionVec_20),
    .io_in_2_bits_exceptionVec_21(io_in_2_bits_exceptionVec_21),
    .io_in_2_bits_exceptionVec_22(io_in_2_bits_exceptionVec_22),
    .io_in_2_bits_exceptionVec_23(io_in_2_bits_exceptionVec_23),
    .io_in_2_bits_isFetchMalAddr(io_in_2_bits_isFetchMalAddr),
    .io_in_2_bits_hasException(io_in_2_bits_hasException),
    .io_in_2_bits_trigger(io_in_2_bits_trigger),
    .io_in_2_bits_preDecodeInfo_valid(io_in_2_bits_preDecodeInfo_valid),
    .io_in_2_bits_preDecodeInfo_isRVC(io_in_2_bits_preDecodeInfo_isRVC),
    .io_in_2_bits_preDecodeInfo_brType(io_in_2_bits_preDecodeInfo_brType),
    .io_in_2_bits_preDecodeInfo_isCall(io_in_2_bits_preDecodeInfo_isCall),
    .io_in_2_bits_preDecodeInfo_isRet(io_in_2_bits_preDecodeInfo_isRet),
    .io_in_2_bits_pred_taken(io_in_2_bits_pred_taken),
    .io_in_2_bits_crossPageIPFFix(io_in_2_bits_crossPageIPFFix),
    .io_in_2_bits_ftqPtr_flag(io_in_2_bits_ftqPtr_flag),
    .io_in_2_bits_ftqPtr_value(io_in_2_bits_ftqPtr_value),
    .io_in_2_bits_ftqOffset(io_in_2_bits_ftqOffset),
    .io_in_2_bits_satpFlushFirstFetchFault(io_in_2_bits_satpFlushFirstFetchFault),
    .io_in_2_bits_srcType_0(io_in_2_bits_srcType_0),
    .io_in_2_bits_srcType_1(io_in_2_bits_srcType_1),
    .io_in_2_bits_srcType_2(io_in_2_bits_srcType_2),
    .io_in_2_bits_srcType_3(io_in_2_bits_srcType_3),
    .io_in_2_bits_srcType_4(io_in_2_bits_srcType_4),
    .io_in_2_bits_ldest(io_in_2_bits_ldest),
    .io_in_2_bits_fuType(io_in_2_bits_fuType),
    .io_in_2_bits_fuOpType(io_in_2_bits_fuOpType),
    .io_in_2_bits_rfWen(io_in_2_bits_rfWen),
    .io_in_2_bits_fpWen(io_in_2_bits_fpWen),
    .io_in_2_bits_vecWen(io_in_2_bits_vecWen),
    .io_in_2_bits_v0Wen(io_in_2_bits_v0Wen),
    .io_in_2_bits_vlWen(io_in_2_bits_vlWen),
    .io_in_2_bits_isXSTrap(io_in_2_bits_isXSTrap),
    .io_in_2_bits_waitForward(io_in_2_bits_waitForward),
    .io_in_2_bits_blockBackward(io_in_2_bits_blockBackward),
    .io_in_2_bits_flushPipe(io_in_2_bits_flushPipe),
    .io_in_2_bits_canRobCompress(io_in_2_bits_canRobCompress),
    .io_in_2_bits_selImm(io_in_2_bits_selImm),
    .io_in_2_bits_imm(io_in_2_bits_imm),
    .io_in_2_bits_fpu_typeTagOut(io_in_2_bits_fpu_typeTagOut),
    .io_in_2_bits_fpu_wflags(io_in_2_bits_fpu_wflags),
    .io_in_2_bits_fpu_typ(io_in_2_bits_fpu_typ),
    .io_in_2_bits_fpu_fmt(io_in_2_bits_fpu_fmt),
    .io_in_2_bits_fpu_rm(io_in_2_bits_fpu_rm),
    .io_in_2_bits_vpu_vill(io_in_2_bits_vpu_vill),
    .io_in_2_bits_vpu_vma(io_in_2_bits_vpu_vma),
    .io_in_2_bits_vpu_vta(io_in_2_bits_vpu_vta),
    .io_in_2_bits_vpu_vsew(io_in_2_bits_vpu_vsew),
    .io_in_2_bits_vpu_vlmul(io_in_2_bits_vpu_vlmul),
    .io_in_2_bits_vpu_specVill(io_in_2_bits_vpu_specVill),
    .io_in_2_bits_vpu_specVma(io_in_2_bits_vpu_specVma),
    .io_in_2_bits_vpu_specVta(io_in_2_bits_vpu_specVta),
    .io_in_2_bits_vpu_specVsew(io_in_2_bits_vpu_specVsew),
    .io_in_2_bits_vpu_specVlmul(io_in_2_bits_vpu_specVlmul),
    .io_in_2_bits_vpu_vm(io_in_2_bits_vpu_vm),
    .io_in_2_bits_vpu_vstart(io_in_2_bits_vpu_vstart),
    .io_in_2_bits_vpu_frm(io_in_2_bits_vpu_frm),
    .io_in_2_bits_vpu_fpu_isFpToVecInst(io_in_2_bits_vpu_fpu_isFpToVecInst),
    .io_in_2_bits_vpu_fpu_isFP32Instr(io_in_2_bits_vpu_fpu_isFP32Instr),
    .io_in_2_bits_vpu_fpu_isFP64Instr(io_in_2_bits_vpu_fpu_isFP64Instr),
    .io_in_2_bits_vpu_fpu_isReduction(io_in_2_bits_vpu_fpu_isReduction),
    .io_in_2_bits_vpu_fpu_isFoldTo1_2(io_in_2_bits_vpu_fpu_isFoldTo1_2),
    .io_in_2_bits_vpu_fpu_isFoldTo1_4(io_in_2_bits_vpu_fpu_isFoldTo1_4),
    .io_in_2_bits_vpu_fpu_isFoldTo1_8(io_in_2_bits_vpu_fpu_isFoldTo1_8),
    .io_in_2_bits_vpu_vxrm(io_in_2_bits_vpu_vxrm),
    .io_in_2_bits_vpu_vuopIdx(io_in_2_bits_vpu_vuopIdx),
    .io_in_2_bits_vpu_lastUop(io_in_2_bits_vpu_lastUop),
    .io_in_2_bits_vpu_vmask(io_in_2_bits_vpu_vmask),
    .io_in_2_bits_vpu_vl(io_in_2_bits_vpu_vl),
    .io_in_2_bits_vpu_nf(io_in_2_bits_vpu_nf),
    .io_in_2_bits_vpu_veew(io_in_2_bits_vpu_veew),
    .io_in_2_bits_vpu_isReverse(io_in_2_bits_vpu_isReverse),
    .io_in_2_bits_vpu_isExt(io_in_2_bits_vpu_isExt),
    .io_in_2_bits_vpu_isNarrow(io_in_2_bits_vpu_isNarrow),
    .io_in_2_bits_vpu_isDstMask(io_in_2_bits_vpu_isDstMask),
    .io_in_2_bits_vpu_isOpMask(io_in_2_bits_vpu_isOpMask),
    .io_in_2_bits_vpu_isMove(io_in_2_bits_vpu_isMove),
    .io_in_2_bits_vpu_isDependOldVd(io_in_2_bits_vpu_isDependOldVd),
    .io_in_2_bits_vpu_isWritePartVd(io_in_2_bits_vpu_isWritePartVd),
    .io_in_2_bits_vpu_isVleff(io_in_2_bits_vpu_isVleff),
    .io_in_2_bits_vlsInstr(io_in_2_bits_vlsInstr),
    .io_in_2_bits_wfflags(io_in_2_bits_wfflags),
    .io_in_2_bits_isMove(io_in_2_bits_isMove),
    .io_in_2_bits_uopIdx(io_in_2_bits_uopIdx),
    .io_in_2_bits_isVset(io_in_2_bits_isVset),
    .io_in_2_bits_firstUop(io_in_2_bits_firstUop),
    .io_in_2_bits_lastUop(io_in_2_bits_lastUop),
    .io_in_2_bits_numUops(io_in_2_bits_numUops),
    .io_in_2_bits_numWB(io_in_2_bits_numWB),
    .io_in_2_bits_commitType(io_in_2_bits_commitType),
    .io_in_2_bits_psrc_0(io_in_2_bits_psrc_0),
    .io_in_2_bits_psrc_1(io_in_2_bits_psrc_1),
    .io_in_2_bits_psrc_2(io_in_2_bits_psrc_2),
    .io_in_2_bits_psrc_3(io_in_2_bits_psrc_3),
    .io_in_2_bits_psrc_4(io_in_2_bits_psrc_4),
    .io_in_2_bits_pdest(io_in_2_bits_pdest),
    .io_in_2_bits_robIdx_flag(io_in_2_bits_robIdx_flag),
    .io_in_2_bits_robIdx_value(io_in_2_bits_robIdx_value),
    .io_in_2_bits_instrSize(io_in_2_bits_instrSize),
    .io_in_2_bits_dirtyFs(io_in_2_bits_dirtyFs),
    .io_in_2_bits_dirtyVs(io_in_2_bits_dirtyVs),
    .io_in_2_bits_traceBlockInPipe_itype(io_in_2_bits_traceBlockInPipe_itype),
    .io_in_2_bits_traceBlockInPipe_iretire(io_in_2_bits_traceBlockInPipe_iretire),
    .io_in_2_bits_traceBlockInPipe_ilastsize(io_in_2_bits_traceBlockInPipe_ilastsize),
    .io_in_2_bits_eliminatedMove(io_in_2_bits_eliminatedMove),
    .io_in_2_bits_debugInfo_renameTime(io_in_2_bits_debugInfo_renameTime),
    .io_in_2_bits_debug_seqNum_seqNum(io_in_2_bits_debug_seqNum_seqNum),
    .io_in_2_bits_debug_seqNum_uopIdx(io_in_2_bits_debug_seqNum_uopIdx),
    .io_in_2_bits_debug_fuType(io_in_2_bits_debug_fuType),
    .io_in_2_bits_debug_sim_trig(io_in_2_bits_debug_sim_trig),
    .io_in_2_bits_numLsElem(io_in_2_bits_numLsElem),
    .io_out_2_bits_instr(i_l2_io_out_bits_instr),
    .io_out_2_bits_pc(i_l2_io_out_bits_pc),
    .io_out_2_bits_foldpc(i_l2_io_out_bits_foldpc),
    .io_out_2_bits_exceptionVec_0(i_l2_io_out_bits_exceptionVec_0),
    .io_out_2_bits_exceptionVec_1(i_l2_io_out_bits_exceptionVec_1),
    .io_out_2_bits_exceptionVec_2(i_l2_io_out_bits_exceptionVec_2),
    .io_out_2_bits_exceptionVec_3(i_l2_io_out_bits_exceptionVec_3),
    .io_out_2_bits_exceptionVec_4(i_l2_io_out_bits_exceptionVec_4),
    .io_out_2_bits_exceptionVec_5(i_l2_io_out_bits_exceptionVec_5),
    .io_out_2_bits_exceptionVec_6(i_l2_io_out_bits_exceptionVec_6),
    .io_out_2_bits_exceptionVec_7(i_l2_io_out_bits_exceptionVec_7),
    .io_out_2_bits_exceptionVec_8(i_l2_io_out_bits_exceptionVec_8),
    .io_out_2_bits_exceptionVec_9(i_l2_io_out_bits_exceptionVec_9),
    .io_out_2_bits_exceptionVec_10(i_l2_io_out_bits_exceptionVec_10),
    .io_out_2_bits_exceptionVec_11(i_l2_io_out_bits_exceptionVec_11),
    .io_out_2_bits_exceptionVec_12(i_l2_io_out_bits_exceptionVec_12),
    .io_out_2_bits_exceptionVec_13(i_l2_io_out_bits_exceptionVec_13),
    .io_out_2_bits_exceptionVec_14(i_l2_io_out_bits_exceptionVec_14),
    .io_out_2_bits_exceptionVec_15(i_l2_io_out_bits_exceptionVec_15),
    .io_out_2_bits_exceptionVec_16(i_l2_io_out_bits_exceptionVec_16),
    .io_out_2_bits_exceptionVec_17(i_l2_io_out_bits_exceptionVec_17),
    .io_out_2_bits_exceptionVec_18(i_l2_io_out_bits_exceptionVec_18),
    .io_out_2_bits_exceptionVec_19(i_l2_io_out_bits_exceptionVec_19),
    .io_out_2_bits_exceptionVec_20(i_l2_io_out_bits_exceptionVec_20),
    .io_out_2_bits_exceptionVec_21(i_l2_io_out_bits_exceptionVec_21),
    .io_out_2_bits_exceptionVec_22(i_l2_io_out_bits_exceptionVec_22),
    .io_out_2_bits_exceptionVec_23(i_l2_io_out_bits_exceptionVec_23),
    .io_out_2_bits_isFetchMalAddr(i_l2_io_out_bits_isFetchMalAddr),
    .io_out_2_bits_hasException(i_l2_io_out_bits_hasException),
    .io_out_2_bits_trigger(i_l2_io_out_bits_trigger),
    .io_out_2_bits_preDecodeInfo_valid(i_l2_io_out_bits_preDecodeInfo_valid),
    .io_out_2_bits_preDecodeInfo_isRVC(i_l2_io_out_bits_preDecodeInfo_isRVC),
    .io_out_2_bits_preDecodeInfo_brType(i_l2_io_out_bits_preDecodeInfo_brType),
    .io_out_2_bits_preDecodeInfo_isCall(i_l2_io_out_bits_preDecodeInfo_isCall),
    .io_out_2_bits_preDecodeInfo_isRet(i_l2_io_out_bits_preDecodeInfo_isRet),
    .io_out_2_bits_pred_taken(i_l2_io_out_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(i_l2_io_out_bits_crossPageIPFFix),
    .io_out_2_bits_ftqPtr_flag(i_l2_io_out_bits_ftqPtr_flag),
    .io_out_2_bits_ftqPtr_value(i_l2_io_out_bits_ftqPtr_value),
    .io_out_2_bits_ftqOffset(i_l2_io_out_bits_ftqOffset),
    .io_out_2_bits_satpFlushFirstFetchFault(i_l2_io_out_bits_satpFlushFirstFetchFault),
    .io_out_2_bits_srcType_0(i_l2_io_out_bits_srcType_0),
    .io_out_2_bits_srcType_1(i_l2_io_out_bits_srcType_1),
    .io_out_2_bits_srcType_2(i_l2_io_out_bits_srcType_2),
    .io_out_2_bits_srcType_3(i_l2_io_out_bits_srcType_3),
    .io_out_2_bits_srcType_4(i_l2_io_out_bits_srcType_4),
    .io_out_2_bits_ldest(i_l2_io_out_bits_ldest),
    .io_out_2_bits_fuType(i_l2_io_out_bits_fuType),
    .io_out_2_bits_fuOpType(i_l2_io_out_bits_fuOpType),
    .io_out_2_bits_rfWen(i_l2_io_out_bits_rfWen),
    .io_out_2_bits_fpWen(i_l2_io_out_bits_fpWen),
    .io_out_2_bits_vecWen(i_l2_io_out_bits_vecWen),
    .io_out_2_bits_v0Wen(i_l2_io_out_bits_v0Wen),
    .io_out_2_bits_vlWen(i_l2_io_out_bits_vlWen),
    .io_out_2_bits_isXSTrap(i_l2_io_out_bits_isXSTrap),
    .io_out_2_bits_waitForward(i_l2_io_out_bits_waitForward),
    .io_out_2_bits_blockBackward(i_l2_io_out_bits_blockBackward),
    .io_out_2_bits_flushPipe(i_l2_io_out_bits_flushPipe),
    .io_out_2_bits_canRobCompress(i_l2_io_out_bits_canRobCompress),
    .io_out_2_bits_selImm(i_l2_io_out_bits_selImm),
    .io_out_2_bits_imm(i_l2_io_out_bits_imm),
    .io_out_2_bits_fpu_typeTagOut(i_l2_io_out_bits_fpu_typeTagOut),
    .io_out_2_bits_fpu_wflags(i_l2_io_out_bits_fpu_wflags),
    .io_out_2_bits_fpu_typ(i_l2_io_out_bits_fpu_typ),
    .io_out_2_bits_fpu_fmt(i_l2_io_out_bits_fpu_fmt),
    .io_out_2_bits_fpu_rm(i_l2_io_out_bits_fpu_rm),
    .io_out_2_bits_vpu_vill(i_l2_io_out_bits_vpu_vill),
    .io_out_2_bits_vpu_vma(i_l2_io_out_bits_vpu_vma),
    .io_out_2_bits_vpu_vta(i_l2_io_out_bits_vpu_vta),
    .io_out_2_bits_vpu_vsew(i_l2_io_out_bits_vpu_vsew),
    .io_out_2_bits_vpu_vlmul(i_l2_io_out_bits_vpu_vlmul),
    .io_out_2_bits_vpu_specVill(i_l2_io_out_bits_vpu_specVill),
    .io_out_2_bits_vpu_specVma(i_l2_io_out_bits_vpu_specVma),
    .io_out_2_bits_vpu_specVta(i_l2_io_out_bits_vpu_specVta),
    .io_out_2_bits_vpu_specVsew(i_l2_io_out_bits_vpu_specVsew),
    .io_out_2_bits_vpu_specVlmul(i_l2_io_out_bits_vpu_specVlmul),
    .io_out_2_bits_vpu_vm(i_l2_io_out_bits_vpu_vm),
    .io_out_2_bits_vpu_vstart(i_l2_io_out_bits_vpu_vstart),
    .io_out_2_bits_vpu_frm(i_l2_io_out_bits_vpu_frm),
    .io_out_2_bits_vpu_fpu_isFpToVecInst(i_l2_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_2_bits_vpu_fpu_isFP32Instr(i_l2_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_2_bits_vpu_fpu_isFP64Instr(i_l2_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_2_bits_vpu_fpu_isReduction(i_l2_io_out_bits_vpu_fpu_isReduction),
    .io_out_2_bits_vpu_fpu_isFoldTo1_2(i_l2_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_2_bits_vpu_fpu_isFoldTo1_4(i_l2_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_2_bits_vpu_fpu_isFoldTo1_8(i_l2_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_2_bits_vpu_vxrm(i_l2_io_out_bits_vpu_vxrm),
    .io_out_2_bits_vpu_vuopIdx(i_l2_io_out_bits_vpu_vuopIdx),
    .io_out_2_bits_vpu_lastUop(i_l2_io_out_bits_vpu_lastUop),
    .io_out_2_bits_vpu_vmask(i_l2_io_out_bits_vpu_vmask),
    .io_out_2_bits_vpu_vl(i_l2_io_out_bits_vpu_vl),
    .io_out_2_bits_vpu_nf(i_l2_io_out_bits_vpu_nf),
    .io_out_2_bits_vpu_veew(i_l2_io_out_bits_vpu_veew),
    .io_out_2_bits_vpu_isReverse(i_l2_io_out_bits_vpu_isReverse),
    .io_out_2_bits_vpu_isExt(i_l2_io_out_bits_vpu_isExt),
    .io_out_2_bits_vpu_isNarrow(i_l2_io_out_bits_vpu_isNarrow),
    .io_out_2_bits_vpu_isDstMask(i_l2_io_out_bits_vpu_isDstMask),
    .io_out_2_bits_vpu_isOpMask(i_l2_io_out_bits_vpu_isOpMask),
    .io_out_2_bits_vpu_isMove(i_l2_io_out_bits_vpu_isMove),
    .io_out_2_bits_vpu_isDependOldVd(i_l2_io_out_bits_vpu_isDependOldVd),
    .io_out_2_bits_vpu_isWritePartVd(i_l2_io_out_bits_vpu_isWritePartVd),
    .io_out_2_bits_vpu_isVleff(i_l2_io_out_bits_vpu_isVleff),
    .io_out_2_bits_vlsInstr(i_l2_io_out_bits_vlsInstr),
    .io_out_2_bits_wfflags(i_l2_io_out_bits_wfflags),
    .io_out_2_bits_isMove(i_l2_io_out_bits_isMove),
    .io_out_2_bits_uopIdx(i_l2_io_out_bits_uopIdx),
    .io_out_2_bits_isVset(i_l2_io_out_bits_isVset),
    .io_out_2_bits_firstUop(i_l2_io_out_bits_firstUop),
    .io_out_2_bits_lastUop(i_l2_io_out_bits_lastUop),
    .io_out_2_bits_numUops(i_l2_io_out_bits_numUops),
    .io_out_2_bits_numWB(i_l2_io_out_bits_numWB),
    .io_out_2_bits_commitType(i_l2_io_out_bits_commitType),
    .io_out_2_bits_psrc_0(i_l2_io_out_bits_psrc_0),
    .io_out_2_bits_psrc_1(i_l2_io_out_bits_psrc_1),
    .io_out_2_bits_psrc_2(i_l2_io_out_bits_psrc_2),
    .io_out_2_bits_psrc_3(i_l2_io_out_bits_psrc_3),
    .io_out_2_bits_psrc_4(i_l2_io_out_bits_psrc_4),
    .io_out_2_bits_pdest(i_l2_io_out_bits_pdest),
    .io_out_2_bits_robIdx_flag(i_l2_io_out_bits_robIdx_flag),
    .io_out_2_bits_robIdx_value(i_l2_io_out_bits_robIdx_value),
    .io_out_2_bits_instrSize(i_l2_io_out_bits_instrSize),
    .io_out_2_bits_dirtyFs(i_l2_io_out_bits_dirtyFs),
    .io_out_2_bits_dirtyVs(i_l2_io_out_bits_dirtyVs),
    .io_out_2_bits_traceBlockInPipe_itype(i_l2_io_out_bits_traceBlockInPipe_itype),
    .io_out_2_bits_traceBlockInPipe_iretire(i_l2_io_out_bits_traceBlockInPipe_iretire),
    .io_out_2_bits_traceBlockInPipe_ilastsize(i_l2_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_2_bits_eliminatedMove(i_l2_io_out_bits_eliminatedMove),
    .io_out_2_bits_debugInfo_renameTime(i_l2_io_out_bits_debugInfo_renameTime),
    .io_out_2_bits_debug_seqNum_seqNum(i_l2_io_out_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx(i_l2_io_out_bits_debug_seqNum_uopIdx),
    .io_out_2_bits_debug_fuType(i_l2_io_out_bits_debug_fuType),
    .io_out_2_bits_debug_sim_trig(i_l2_io_out_bits_debug_sim_trig),
    .io_out_2_bits_numLsElem(i_l2_io_out_bits_numLsElem),
    .io_in_3_valid(io_in_3_valid), .io_in_3_ready(i_l3_io_in_ready),
    .io_out_3_ready(io_out_3_ready), .io_out_3_valid(i_l3_io_out_valid),
    .io_in_3_bits_instr(io_in_3_bits_instr),
    .io_in_3_bits_pc(io_in_3_bits_pc),
    .io_in_3_bits_foldpc(io_in_3_bits_foldpc),
    .io_in_3_bits_exceptionVec_0(io_in_3_bits_exceptionVec_0),
    .io_in_3_bits_exceptionVec_1(io_in_3_bits_exceptionVec_1),
    .io_in_3_bits_exceptionVec_2(io_in_3_bits_exceptionVec_2),
    .io_in_3_bits_exceptionVec_3(io_in_3_bits_exceptionVec_3),
    .io_in_3_bits_exceptionVec_4(io_in_3_bits_exceptionVec_4),
    .io_in_3_bits_exceptionVec_5(io_in_3_bits_exceptionVec_5),
    .io_in_3_bits_exceptionVec_6(io_in_3_bits_exceptionVec_6),
    .io_in_3_bits_exceptionVec_7(io_in_3_bits_exceptionVec_7),
    .io_in_3_bits_exceptionVec_8(io_in_3_bits_exceptionVec_8),
    .io_in_3_bits_exceptionVec_9(io_in_3_bits_exceptionVec_9),
    .io_in_3_bits_exceptionVec_10(io_in_3_bits_exceptionVec_10),
    .io_in_3_bits_exceptionVec_11(io_in_3_bits_exceptionVec_11),
    .io_in_3_bits_exceptionVec_12(io_in_3_bits_exceptionVec_12),
    .io_in_3_bits_exceptionVec_13(io_in_3_bits_exceptionVec_13),
    .io_in_3_bits_exceptionVec_14(io_in_3_bits_exceptionVec_14),
    .io_in_3_bits_exceptionVec_15(io_in_3_bits_exceptionVec_15),
    .io_in_3_bits_exceptionVec_16(io_in_3_bits_exceptionVec_16),
    .io_in_3_bits_exceptionVec_17(io_in_3_bits_exceptionVec_17),
    .io_in_3_bits_exceptionVec_18(io_in_3_bits_exceptionVec_18),
    .io_in_3_bits_exceptionVec_19(io_in_3_bits_exceptionVec_19),
    .io_in_3_bits_exceptionVec_20(io_in_3_bits_exceptionVec_20),
    .io_in_3_bits_exceptionVec_21(io_in_3_bits_exceptionVec_21),
    .io_in_3_bits_exceptionVec_22(io_in_3_bits_exceptionVec_22),
    .io_in_3_bits_exceptionVec_23(io_in_3_bits_exceptionVec_23),
    .io_in_3_bits_isFetchMalAddr(io_in_3_bits_isFetchMalAddr),
    .io_in_3_bits_hasException(io_in_3_bits_hasException),
    .io_in_3_bits_trigger(io_in_3_bits_trigger),
    .io_in_3_bits_preDecodeInfo_valid(io_in_3_bits_preDecodeInfo_valid),
    .io_in_3_bits_preDecodeInfo_isRVC(io_in_3_bits_preDecodeInfo_isRVC),
    .io_in_3_bits_preDecodeInfo_brType(io_in_3_bits_preDecodeInfo_brType),
    .io_in_3_bits_preDecodeInfo_isCall(io_in_3_bits_preDecodeInfo_isCall),
    .io_in_3_bits_preDecodeInfo_isRet(io_in_3_bits_preDecodeInfo_isRet),
    .io_in_3_bits_pred_taken(io_in_3_bits_pred_taken),
    .io_in_3_bits_crossPageIPFFix(io_in_3_bits_crossPageIPFFix),
    .io_in_3_bits_ftqPtr_flag(io_in_3_bits_ftqPtr_flag),
    .io_in_3_bits_ftqPtr_value(io_in_3_bits_ftqPtr_value),
    .io_in_3_bits_ftqOffset(io_in_3_bits_ftqOffset),
    .io_in_3_bits_satpFlushFirstFetchFault(io_in_3_bits_satpFlushFirstFetchFault),
    .io_in_3_bits_srcType_0(io_in_3_bits_srcType_0),
    .io_in_3_bits_srcType_1(io_in_3_bits_srcType_1),
    .io_in_3_bits_srcType_2(io_in_3_bits_srcType_2),
    .io_in_3_bits_srcType_3(io_in_3_bits_srcType_3),
    .io_in_3_bits_srcType_4(io_in_3_bits_srcType_4),
    .io_in_3_bits_ldest(io_in_3_bits_ldest),
    .io_in_3_bits_fuType(io_in_3_bits_fuType),
    .io_in_3_bits_fuOpType(io_in_3_bits_fuOpType),
    .io_in_3_bits_rfWen(io_in_3_bits_rfWen),
    .io_in_3_bits_fpWen(io_in_3_bits_fpWen),
    .io_in_3_bits_vecWen(io_in_3_bits_vecWen),
    .io_in_3_bits_v0Wen(io_in_3_bits_v0Wen),
    .io_in_3_bits_vlWen(io_in_3_bits_vlWen),
    .io_in_3_bits_isXSTrap(io_in_3_bits_isXSTrap),
    .io_in_3_bits_waitForward(io_in_3_bits_waitForward),
    .io_in_3_bits_blockBackward(io_in_3_bits_blockBackward),
    .io_in_3_bits_flushPipe(io_in_3_bits_flushPipe),
    .io_in_3_bits_canRobCompress(io_in_3_bits_canRobCompress),
    .io_in_3_bits_selImm(io_in_3_bits_selImm),
    .io_in_3_bits_imm(io_in_3_bits_imm),
    .io_in_3_bits_fpu_typeTagOut(io_in_3_bits_fpu_typeTagOut),
    .io_in_3_bits_fpu_wflags(io_in_3_bits_fpu_wflags),
    .io_in_3_bits_fpu_typ(io_in_3_bits_fpu_typ),
    .io_in_3_bits_fpu_fmt(io_in_3_bits_fpu_fmt),
    .io_in_3_bits_fpu_rm(io_in_3_bits_fpu_rm),
    .io_in_3_bits_vpu_vill(io_in_3_bits_vpu_vill),
    .io_in_3_bits_vpu_vma(io_in_3_bits_vpu_vma),
    .io_in_3_bits_vpu_vta(io_in_3_bits_vpu_vta),
    .io_in_3_bits_vpu_vsew(io_in_3_bits_vpu_vsew),
    .io_in_3_bits_vpu_vlmul(io_in_3_bits_vpu_vlmul),
    .io_in_3_bits_vpu_specVill(io_in_3_bits_vpu_specVill),
    .io_in_3_bits_vpu_specVma(io_in_3_bits_vpu_specVma),
    .io_in_3_bits_vpu_specVta(io_in_3_bits_vpu_specVta),
    .io_in_3_bits_vpu_specVsew(io_in_3_bits_vpu_specVsew),
    .io_in_3_bits_vpu_specVlmul(io_in_3_bits_vpu_specVlmul),
    .io_in_3_bits_vpu_vm(io_in_3_bits_vpu_vm),
    .io_in_3_bits_vpu_vstart(io_in_3_bits_vpu_vstart),
    .io_in_3_bits_vpu_frm(io_in_3_bits_vpu_frm),
    .io_in_3_bits_vpu_fpu_isFpToVecInst(io_in_3_bits_vpu_fpu_isFpToVecInst),
    .io_in_3_bits_vpu_fpu_isFP32Instr(io_in_3_bits_vpu_fpu_isFP32Instr),
    .io_in_3_bits_vpu_fpu_isFP64Instr(io_in_3_bits_vpu_fpu_isFP64Instr),
    .io_in_3_bits_vpu_fpu_isReduction(io_in_3_bits_vpu_fpu_isReduction),
    .io_in_3_bits_vpu_fpu_isFoldTo1_2(io_in_3_bits_vpu_fpu_isFoldTo1_2),
    .io_in_3_bits_vpu_fpu_isFoldTo1_4(io_in_3_bits_vpu_fpu_isFoldTo1_4),
    .io_in_3_bits_vpu_fpu_isFoldTo1_8(io_in_3_bits_vpu_fpu_isFoldTo1_8),
    .io_in_3_bits_vpu_vxrm(io_in_3_bits_vpu_vxrm),
    .io_in_3_bits_vpu_vuopIdx(io_in_3_bits_vpu_vuopIdx),
    .io_in_3_bits_vpu_lastUop(io_in_3_bits_vpu_lastUop),
    .io_in_3_bits_vpu_vmask(io_in_3_bits_vpu_vmask),
    .io_in_3_bits_vpu_vl(io_in_3_bits_vpu_vl),
    .io_in_3_bits_vpu_nf(io_in_3_bits_vpu_nf),
    .io_in_3_bits_vpu_veew(io_in_3_bits_vpu_veew),
    .io_in_3_bits_vpu_isReverse(io_in_3_bits_vpu_isReverse),
    .io_in_3_bits_vpu_isExt(io_in_3_bits_vpu_isExt),
    .io_in_3_bits_vpu_isNarrow(io_in_3_bits_vpu_isNarrow),
    .io_in_3_bits_vpu_isDstMask(io_in_3_bits_vpu_isDstMask),
    .io_in_3_bits_vpu_isOpMask(io_in_3_bits_vpu_isOpMask),
    .io_in_3_bits_vpu_isMove(io_in_3_bits_vpu_isMove),
    .io_in_3_bits_vpu_isDependOldVd(io_in_3_bits_vpu_isDependOldVd),
    .io_in_3_bits_vpu_isWritePartVd(io_in_3_bits_vpu_isWritePartVd),
    .io_in_3_bits_vpu_isVleff(io_in_3_bits_vpu_isVleff),
    .io_in_3_bits_vlsInstr(io_in_3_bits_vlsInstr),
    .io_in_3_bits_wfflags(io_in_3_bits_wfflags),
    .io_in_3_bits_isMove(io_in_3_bits_isMove),
    .io_in_3_bits_uopIdx(io_in_3_bits_uopIdx),
    .io_in_3_bits_isVset(io_in_3_bits_isVset),
    .io_in_3_bits_firstUop(io_in_3_bits_firstUop),
    .io_in_3_bits_lastUop(io_in_3_bits_lastUop),
    .io_in_3_bits_numUops(io_in_3_bits_numUops),
    .io_in_3_bits_numWB(io_in_3_bits_numWB),
    .io_in_3_bits_commitType(io_in_3_bits_commitType),
    .io_in_3_bits_psrc_0(io_in_3_bits_psrc_0),
    .io_in_3_bits_psrc_1(io_in_3_bits_psrc_1),
    .io_in_3_bits_psrc_2(io_in_3_bits_psrc_2),
    .io_in_3_bits_psrc_3(io_in_3_bits_psrc_3),
    .io_in_3_bits_psrc_4(io_in_3_bits_psrc_4),
    .io_in_3_bits_pdest(io_in_3_bits_pdest),
    .io_in_3_bits_robIdx_flag(io_in_3_bits_robIdx_flag),
    .io_in_3_bits_robIdx_value(io_in_3_bits_robIdx_value),
    .io_in_3_bits_instrSize(io_in_3_bits_instrSize),
    .io_in_3_bits_dirtyFs(io_in_3_bits_dirtyFs),
    .io_in_3_bits_dirtyVs(io_in_3_bits_dirtyVs),
    .io_in_3_bits_traceBlockInPipe_itype(io_in_3_bits_traceBlockInPipe_itype),
    .io_in_3_bits_traceBlockInPipe_iretire(io_in_3_bits_traceBlockInPipe_iretire),
    .io_in_3_bits_traceBlockInPipe_ilastsize(io_in_3_bits_traceBlockInPipe_ilastsize),
    .io_in_3_bits_eliminatedMove(io_in_3_bits_eliminatedMove),
    .io_in_3_bits_debugInfo_renameTime(io_in_3_bits_debugInfo_renameTime),
    .io_in_3_bits_debug_seqNum_seqNum(io_in_3_bits_debug_seqNum_seqNum),
    .io_in_3_bits_debug_seqNum_uopIdx(io_in_3_bits_debug_seqNum_uopIdx),
    .io_in_3_bits_debug_fuType(io_in_3_bits_debug_fuType),
    .io_in_3_bits_debug_sim_trig(io_in_3_bits_debug_sim_trig),
    .io_in_3_bits_numLsElem(io_in_3_bits_numLsElem),
    .io_out_3_bits_instr(i_l3_io_out_bits_instr),
    .io_out_3_bits_pc(i_l3_io_out_bits_pc),
    .io_out_3_bits_foldpc(i_l3_io_out_bits_foldpc),
    .io_out_3_bits_exceptionVec_0(i_l3_io_out_bits_exceptionVec_0),
    .io_out_3_bits_exceptionVec_1(i_l3_io_out_bits_exceptionVec_1),
    .io_out_3_bits_exceptionVec_2(i_l3_io_out_bits_exceptionVec_2),
    .io_out_3_bits_exceptionVec_3(i_l3_io_out_bits_exceptionVec_3),
    .io_out_3_bits_exceptionVec_4(i_l3_io_out_bits_exceptionVec_4),
    .io_out_3_bits_exceptionVec_5(i_l3_io_out_bits_exceptionVec_5),
    .io_out_3_bits_exceptionVec_6(i_l3_io_out_bits_exceptionVec_6),
    .io_out_3_bits_exceptionVec_7(i_l3_io_out_bits_exceptionVec_7),
    .io_out_3_bits_exceptionVec_8(i_l3_io_out_bits_exceptionVec_8),
    .io_out_3_bits_exceptionVec_9(i_l3_io_out_bits_exceptionVec_9),
    .io_out_3_bits_exceptionVec_10(i_l3_io_out_bits_exceptionVec_10),
    .io_out_3_bits_exceptionVec_11(i_l3_io_out_bits_exceptionVec_11),
    .io_out_3_bits_exceptionVec_12(i_l3_io_out_bits_exceptionVec_12),
    .io_out_3_bits_exceptionVec_13(i_l3_io_out_bits_exceptionVec_13),
    .io_out_3_bits_exceptionVec_14(i_l3_io_out_bits_exceptionVec_14),
    .io_out_3_bits_exceptionVec_15(i_l3_io_out_bits_exceptionVec_15),
    .io_out_3_bits_exceptionVec_16(i_l3_io_out_bits_exceptionVec_16),
    .io_out_3_bits_exceptionVec_17(i_l3_io_out_bits_exceptionVec_17),
    .io_out_3_bits_exceptionVec_18(i_l3_io_out_bits_exceptionVec_18),
    .io_out_3_bits_exceptionVec_19(i_l3_io_out_bits_exceptionVec_19),
    .io_out_3_bits_exceptionVec_20(i_l3_io_out_bits_exceptionVec_20),
    .io_out_3_bits_exceptionVec_21(i_l3_io_out_bits_exceptionVec_21),
    .io_out_3_bits_exceptionVec_22(i_l3_io_out_bits_exceptionVec_22),
    .io_out_3_bits_exceptionVec_23(i_l3_io_out_bits_exceptionVec_23),
    .io_out_3_bits_isFetchMalAddr(i_l3_io_out_bits_isFetchMalAddr),
    .io_out_3_bits_hasException(i_l3_io_out_bits_hasException),
    .io_out_3_bits_trigger(i_l3_io_out_bits_trigger),
    .io_out_3_bits_preDecodeInfo_valid(i_l3_io_out_bits_preDecodeInfo_valid),
    .io_out_3_bits_preDecodeInfo_isRVC(i_l3_io_out_bits_preDecodeInfo_isRVC),
    .io_out_3_bits_preDecodeInfo_brType(i_l3_io_out_bits_preDecodeInfo_brType),
    .io_out_3_bits_preDecodeInfo_isCall(i_l3_io_out_bits_preDecodeInfo_isCall),
    .io_out_3_bits_preDecodeInfo_isRet(i_l3_io_out_bits_preDecodeInfo_isRet),
    .io_out_3_bits_pred_taken(i_l3_io_out_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(i_l3_io_out_bits_crossPageIPFFix),
    .io_out_3_bits_ftqPtr_flag(i_l3_io_out_bits_ftqPtr_flag),
    .io_out_3_bits_ftqPtr_value(i_l3_io_out_bits_ftqPtr_value),
    .io_out_3_bits_ftqOffset(i_l3_io_out_bits_ftqOffset),
    .io_out_3_bits_satpFlushFirstFetchFault(i_l3_io_out_bits_satpFlushFirstFetchFault),
    .io_out_3_bits_srcType_0(i_l3_io_out_bits_srcType_0),
    .io_out_3_bits_srcType_1(i_l3_io_out_bits_srcType_1),
    .io_out_3_bits_srcType_2(i_l3_io_out_bits_srcType_2),
    .io_out_3_bits_srcType_3(i_l3_io_out_bits_srcType_3),
    .io_out_3_bits_srcType_4(i_l3_io_out_bits_srcType_4),
    .io_out_3_bits_ldest(i_l3_io_out_bits_ldest),
    .io_out_3_bits_fuType(i_l3_io_out_bits_fuType),
    .io_out_3_bits_fuOpType(i_l3_io_out_bits_fuOpType),
    .io_out_3_bits_rfWen(i_l3_io_out_bits_rfWen),
    .io_out_3_bits_fpWen(i_l3_io_out_bits_fpWen),
    .io_out_3_bits_vecWen(i_l3_io_out_bits_vecWen),
    .io_out_3_bits_v0Wen(i_l3_io_out_bits_v0Wen),
    .io_out_3_bits_vlWen(i_l3_io_out_bits_vlWen),
    .io_out_3_bits_isXSTrap(i_l3_io_out_bits_isXSTrap),
    .io_out_3_bits_waitForward(i_l3_io_out_bits_waitForward),
    .io_out_3_bits_blockBackward(i_l3_io_out_bits_blockBackward),
    .io_out_3_bits_flushPipe(i_l3_io_out_bits_flushPipe),
    .io_out_3_bits_canRobCompress(i_l3_io_out_bits_canRobCompress),
    .io_out_3_bits_selImm(i_l3_io_out_bits_selImm),
    .io_out_3_bits_imm(i_l3_io_out_bits_imm),
    .io_out_3_bits_fpu_typeTagOut(i_l3_io_out_bits_fpu_typeTagOut),
    .io_out_3_bits_fpu_wflags(i_l3_io_out_bits_fpu_wflags),
    .io_out_3_bits_fpu_typ(i_l3_io_out_bits_fpu_typ),
    .io_out_3_bits_fpu_fmt(i_l3_io_out_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm(i_l3_io_out_bits_fpu_rm),
    .io_out_3_bits_vpu_vill(i_l3_io_out_bits_vpu_vill),
    .io_out_3_bits_vpu_vma(i_l3_io_out_bits_vpu_vma),
    .io_out_3_bits_vpu_vta(i_l3_io_out_bits_vpu_vta),
    .io_out_3_bits_vpu_vsew(i_l3_io_out_bits_vpu_vsew),
    .io_out_3_bits_vpu_vlmul(i_l3_io_out_bits_vpu_vlmul),
    .io_out_3_bits_vpu_specVill(i_l3_io_out_bits_vpu_specVill),
    .io_out_3_bits_vpu_specVma(i_l3_io_out_bits_vpu_specVma),
    .io_out_3_bits_vpu_specVta(i_l3_io_out_bits_vpu_specVta),
    .io_out_3_bits_vpu_specVsew(i_l3_io_out_bits_vpu_specVsew),
    .io_out_3_bits_vpu_specVlmul(i_l3_io_out_bits_vpu_specVlmul),
    .io_out_3_bits_vpu_vm(i_l3_io_out_bits_vpu_vm),
    .io_out_3_bits_vpu_vstart(i_l3_io_out_bits_vpu_vstart),
    .io_out_3_bits_vpu_frm(i_l3_io_out_bits_vpu_frm),
    .io_out_3_bits_vpu_fpu_isFpToVecInst(i_l3_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_3_bits_vpu_fpu_isFP32Instr(i_l3_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_3_bits_vpu_fpu_isFP64Instr(i_l3_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_3_bits_vpu_fpu_isReduction(i_l3_io_out_bits_vpu_fpu_isReduction),
    .io_out_3_bits_vpu_fpu_isFoldTo1_2(i_l3_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_3_bits_vpu_fpu_isFoldTo1_4(i_l3_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_3_bits_vpu_fpu_isFoldTo1_8(i_l3_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_3_bits_vpu_vxrm(i_l3_io_out_bits_vpu_vxrm),
    .io_out_3_bits_vpu_vuopIdx(i_l3_io_out_bits_vpu_vuopIdx),
    .io_out_3_bits_vpu_lastUop(i_l3_io_out_bits_vpu_lastUop),
    .io_out_3_bits_vpu_vmask(i_l3_io_out_bits_vpu_vmask),
    .io_out_3_bits_vpu_vl(i_l3_io_out_bits_vpu_vl),
    .io_out_3_bits_vpu_nf(i_l3_io_out_bits_vpu_nf),
    .io_out_3_bits_vpu_veew(i_l3_io_out_bits_vpu_veew),
    .io_out_3_bits_vpu_isReverse(i_l3_io_out_bits_vpu_isReverse),
    .io_out_3_bits_vpu_isExt(i_l3_io_out_bits_vpu_isExt),
    .io_out_3_bits_vpu_isNarrow(i_l3_io_out_bits_vpu_isNarrow),
    .io_out_3_bits_vpu_isDstMask(i_l3_io_out_bits_vpu_isDstMask),
    .io_out_3_bits_vpu_isOpMask(i_l3_io_out_bits_vpu_isOpMask),
    .io_out_3_bits_vpu_isMove(i_l3_io_out_bits_vpu_isMove),
    .io_out_3_bits_vpu_isDependOldVd(i_l3_io_out_bits_vpu_isDependOldVd),
    .io_out_3_bits_vpu_isWritePartVd(i_l3_io_out_bits_vpu_isWritePartVd),
    .io_out_3_bits_vpu_isVleff(i_l3_io_out_bits_vpu_isVleff),
    .io_out_3_bits_vlsInstr(i_l3_io_out_bits_vlsInstr),
    .io_out_3_bits_wfflags(i_l3_io_out_bits_wfflags),
    .io_out_3_bits_isMove(i_l3_io_out_bits_isMove),
    .io_out_3_bits_uopIdx(i_l3_io_out_bits_uopIdx),
    .io_out_3_bits_isVset(i_l3_io_out_bits_isVset),
    .io_out_3_bits_firstUop(i_l3_io_out_bits_firstUop),
    .io_out_3_bits_lastUop(i_l3_io_out_bits_lastUop),
    .io_out_3_bits_numUops(i_l3_io_out_bits_numUops),
    .io_out_3_bits_numWB(i_l3_io_out_bits_numWB),
    .io_out_3_bits_commitType(i_l3_io_out_bits_commitType),
    .io_out_3_bits_psrc_0(i_l3_io_out_bits_psrc_0),
    .io_out_3_bits_psrc_1(i_l3_io_out_bits_psrc_1),
    .io_out_3_bits_psrc_2(i_l3_io_out_bits_psrc_2),
    .io_out_3_bits_psrc_3(i_l3_io_out_bits_psrc_3),
    .io_out_3_bits_psrc_4(i_l3_io_out_bits_psrc_4),
    .io_out_3_bits_pdest(i_l3_io_out_bits_pdest),
    .io_out_3_bits_robIdx_flag(i_l3_io_out_bits_robIdx_flag),
    .io_out_3_bits_robIdx_value(i_l3_io_out_bits_robIdx_value),
    .io_out_3_bits_instrSize(i_l3_io_out_bits_instrSize),
    .io_out_3_bits_dirtyFs(i_l3_io_out_bits_dirtyFs),
    .io_out_3_bits_dirtyVs(i_l3_io_out_bits_dirtyVs),
    .io_out_3_bits_traceBlockInPipe_itype(i_l3_io_out_bits_traceBlockInPipe_itype),
    .io_out_3_bits_traceBlockInPipe_iretire(i_l3_io_out_bits_traceBlockInPipe_iretire),
    .io_out_3_bits_traceBlockInPipe_ilastsize(i_l3_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_3_bits_eliminatedMove(i_l3_io_out_bits_eliminatedMove),
    .io_out_3_bits_debugInfo_renameTime(i_l3_io_out_bits_debugInfo_renameTime),
    .io_out_3_bits_debug_seqNum_seqNum(i_l3_io_out_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx(i_l3_io_out_bits_debug_seqNum_uopIdx),
    .io_out_3_bits_debug_fuType(i_l3_io_out_bits_debug_fuType),
    .io_out_3_bits_debug_sim_trig(i_l3_io_out_bits_debug_sim_trig),
    .io_out_3_bits_numLsElem(i_l3_io_out_bits_numLsElem),
    .io_in_4_valid(io_in_4_valid), .io_in_4_ready(i_l4_io_in_ready),
    .io_out_4_ready(io_out_4_ready), .io_out_4_valid(i_l4_io_out_valid),
    .io_in_4_bits_instr(io_in_4_bits_instr),
    .io_in_4_bits_pc(io_in_4_bits_pc),
    .io_in_4_bits_foldpc(io_in_4_bits_foldpc),
    .io_in_4_bits_exceptionVec_0(io_in_4_bits_exceptionVec_0),
    .io_in_4_bits_exceptionVec_1(io_in_4_bits_exceptionVec_1),
    .io_in_4_bits_exceptionVec_2(io_in_4_bits_exceptionVec_2),
    .io_in_4_bits_exceptionVec_3(io_in_4_bits_exceptionVec_3),
    .io_in_4_bits_exceptionVec_4(io_in_4_bits_exceptionVec_4),
    .io_in_4_bits_exceptionVec_5(io_in_4_bits_exceptionVec_5),
    .io_in_4_bits_exceptionVec_6(io_in_4_bits_exceptionVec_6),
    .io_in_4_bits_exceptionVec_7(io_in_4_bits_exceptionVec_7),
    .io_in_4_bits_exceptionVec_8(io_in_4_bits_exceptionVec_8),
    .io_in_4_bits_exceptionVec_9(io_in_4_bits_exceptionVec_9),
    .io_in_4_bits_exceptionVec_10(io_in_4_bits_exceptionVec_10),
    .io_in_4_bits_exceptionVec_11(io_in_4_bits_exceptionVec_11),
    .io_in_4_bits_exceptionVec_12(io_in_4_bits_exceptionVec_12),
    .io_in_4_bits_exceptionVec_13(io_in_4_bits_exceptionVec_13),
    .io_in_4_bits_exceptionVec_14(io_in_4_bits_exceptionVec_14),
    .io_in_4_bits_exceptionVec_15(io_in_4_bits_exceptionVec_15),
    .io_in_4_bits_exceptionVec_16(io_in_4_bits_exceptionVec_16),
    .io_in_4_bits_exceptionVec_17(io_in_4_bits_exceptionVec_17),
    .io_in_4_bits_exceptionVec_18(io_in_4_bits_exceptionVec_18),
    .io_in_4_bits_exceptionVec_19(io_in_4_bits_exceptionVec_19),
    .io_in_4_bits_exceptionVec_20(io_in_4_bits_exceptionVec_20),
    .io_in_4_bits_exceptionVec_21(io_in_4_bits_exceptionVec_21),
    .io_in_4_bits_exceptionVec_22(io_in_4_bits_exceptionVec_22),
    .io_in_4_bits_exceptionVec_23(io_in_4_bits_exceptionVec_23),
    .io_in_4_bits_isFetchMalAddr(io_in_4_bits_isFetchMalAddr),
    .io_in_4_bits_hasException(io_in_4_bits_hasException),
    .io_in_4_bits_trigger(io_in_4_bits_trigger),
    .io_in_4_bits_preDecodeInfo_valid(io_in_4_bits_preDecodeInfo_valid),
    .io_in_4_bits_preDecodeInfo_isRVC(io_in_4_bits_preDecodeInfo_isRVC),
    .io_in_4_bits_preDecodeInfo_brType(io_in_4_bits_preDecodeInfo_brType),
    .io_in_4_bits_preDecodeInfo_isCall(io_in_4_bits_preDecodeInfo_isCall),
    .io_in_4_bits_preDecodeInfo_isRet(io_in_4_bits_preDecodeInfo_isRet),
    .io_in_4_bits_pred_taken(io_in_4_bits_pred_taken),
    .io_in_4_bits_crossPageIPFFix(io_in_4_bits_crossPageIPFFix),
    .io_in_4_bits_ftqPtr_flag(io_in_4_bits_ftqPtr_flag),
    .io_in_4_bits_ftqPtr_value(io_in_4_bits_ftqPtr_value),
    .io_in_4_bits_ftqOffset(io_in_4_bits_ftqOffset),
    .io_in_4_bits_satpFlushFirstFetchFault(io_in_4_bits_satpFlushFirstFetchFault),
    .io_in_4_bits_srcType_0(io_in_4_bits_srcType_0),
    .io_in_4_bits_srcType_1(io_in_4_bits_srcType_1),
    .io_in_4_bits_srcType_2(io_in_4_bits_srcType_2),
    .io_in_4_bits_srcType_3(io_in_4_bits_srcType_3),
    .io_in_4_bits_srcType_4(io_in_4_bits_srcType_4),
    .io_in_4_bits_ldest(io_in_4_bits_ldest),
    .io_in_4_bits_fuType(io_in_4_bits_fuType),
    .io_in_4_bits_fuOpType(io_in_4_bits_fuOpType),
    .io_in_4_bits_rfWen(io_in_4_bits_rfWen),
    .io_in_4_bits_fpWen(io_in_4_bits_fpWen),
    .io_in_4_bits_vecWen(io_in_4_bits_vecWen),
    .io_in_4_bits_v0Wen(io_in_4_bits_v0Wen),
    .io_in_4_bits_vlWen(io_in_4_bits_vlWen),
    .io_in_4_bits_isXSTrap(io_in_4_bits_isXSTrap),
    .io_in_4_bits_waitForward(io_in_4_bits_waitForward),
    .io_in_4_bits_blockBackward(io_in_4_bits_blockBackward),
    .io_in_4_bits_flushPipe(io_in_4_bits_flushPipe),
    .io_in_4_bits_canRobCompress(io_in_4_bits_canRobCompress),
    .io_in_4_bits_selImm(io_in_4_bits_selImm),
    .io_in_4_bits_imm(io_in_4_bits_imm),
    .io_in_4_bits_fpu_typeTagOut(io_in_4_bits_fpu_typeTagOut),
    .io_in_4_bits_fpu_wflags(io_in_4_bits_fpu_wflags),
    .io_in_4_bits_fpu_typ(io_in_4_bits_fpu_typ),
    .io_in_4_bits_fpu_fmt(io_in_4_bits_fpu_fmt),
    .io_in_4_bits_fpu_rm(io_in_4_bits_fpu_rm),
    .io_in_4_bits_vpu_vill(io_in_4_bits_vpu_vill),
    .io_in_4_bits_vpu_vma(io_in_4_bits_vpu_vma),
    .io_in_4_bits_vpu_vta(io_in_4_bits_vpu_vta),
    .io_in_4_bits_vpu_vsew(io_in_4_bits_vpu_vsew),
    .io_in_4_bits_vpu_vlmul(io_in_4_bits_vpu_vlmul),
    .io_in_4_bits_vpu_specVill(io_in_4_bits_vpu_specVill),
    .io_in_4_bits_vpu_specVma(io_in_4_bits_vpu_specVma),
    .io_in_4_bits_vpu_specVta(io_in_4_bits_vpu_specVta),
    .io_in_4_bits_vpu_specVsew(io_in_4_bits_vpu_specVsew),
    .io_in_4_bits_vpu_specVlmul(io_in_4_bits_vpu_specVlmul),
    .io_in_4_bits_vpu_vm(io_in_4_bits_vpu_vm),
    .io_in_4_bits_vpu_vstart(io_in_4_bits_vpu_vstart),
    .io_in_4_bits_vpu_frm(io_in_4_bits_vpu_frm),
    .io_in_4_bits_vpu_fpu_isFpToVecInst(io_in_4_bits_vpu_fpu_isFpToVecInst),
    .io_in_4_bits_vpu_fpu_isFP32Instr(io_in_4_bits_vpu_fpu_isFP32Instr),
    .io_in_4_bits_vpu_fpu_isFP64Instr(io_in_4_bits_vpu_fpu_isFP64Instr),
    .io_in_4_bits_vpu_fpu_isReduction(io_in_4_bits_vpu_fpu_isReduction),
    .io_in_4_bits_vpu_fpu_isFoldTo1_2(io_in_4_bits_vpu_fpu_isFoldTo1_2),
    .io_in_4_bits_vpu_fpu_isFoldTo1_4(io_in_4_bits_vpu_fpu_isFoldTo1_4),
    .io_in_4_bits_vpu_fpu_isFoldTo1_8(io_in_4_bits_vpu_fpu_isFoldTo1_8),
    .io_in_4_bits_vpu_vxrm(io_in_4_bits_vpu_vxrm),
    .io_in_4_bits_vpu_vuopIdx(io_in_4_bits_vpu_vuopIdx),
    .io_in_4_bits_vpu_lastUop(io_in_4_bits_vpu_lastUop),
    .io_in_4_bits_vpu_vmask(io_in_4_bits_vpu_vmask),
    .io_in_4_bits_vpu_vl(io_in_4_bits_vpu_vl),
    .io_in_4_bits_vpu_nf(io_in_4_bits_vpu_nf),
    .io_in_4_bits_vpu_veew(io_in_4_bits_vpu_veew),
    .io_in_4_bits_vpu_isReverse(io_in_4_bits_vpu_isReverse),
    .io_in_4_bits_vpu_isExt(io_in_4_bits_vpu_isExt),
    .io_in_4_bits_vpu_isNarrow(io_in_4_bits_vpu_isNarrow),
    .io_in_4_bits_vpu_isDstMask(io_in_4_bits_vpu_isDstMask),
    .io_in_4_bits_vpu_isOpMask(io_in_4_bits_vpu_isOpMask),
    .io_in_4_bits_vpu_isMove(io_in_4_bits_vpu_isMove),
    .io_in_4_bits_vpu_isDependOldVd(io_in_4_bits_vpu_isDependOldVd),
    .io_in_4_bits_vpu_isWritePartVd(io_in_4_bits_vpu_isWritePartVd),
    .io_in_4_bits_vpu_isVleff(io_in_4_bits_vpu_isVleff),
    .io_in_4_bits_vlsInstr(io_in_4_bits_vlsInstr),
    .io_in_4_bits_wfflags(io_in_4_bits_wfflags),
    .io_in_4_bits_isMove(io_in_4_bits_isMove),
    .io_in_4_bits_uopIdx(io_in_4_bits_uopIdx),
    .io_in_4_bits_isVset(io_in_4_bits_isVset),
    .io_in_4_bits_firstUop(io_in_4_bits_firstUop),
    .io_in_4_bits_lastUop(io_in_4_bits_lastUop),
    .io_in_4_bits_numUops(io_in_4_bits_numUops),
    .io_in_4_bits_numWB(io_in_4_bits_numWB),
    .io_in_4_bits_commitType(io_in_4_bits_commitType),
    .io_in_4_bits_psrc_0(io_in_4_bits_psrc_0),
    .io_in_4_bits_psrc_1(io_in_4_bits_psrc_1),
    .io_in_4_bits_psrc_2(io_in_4_bits_psrc_2),
    .io_in_4_bits_psrc_3(io_in_4_bits_psrc_3),
    .io_in_4_bits_psrc_4(io_in_4_bits_psrc_4),
    .io_in_4_bits_pdest(io_in_4_bits_pdest),
    .io_in_4_bits_robIdx_flag(io_in_4_bits_robIdx_flag),
    .io_in_4_bits_robIdx_value(io_in_4_bits_robIdx_value),
    .io_in_4_bits_instrSize(io_in_4_bits_instrSize),
    .io_in_4_bits_dirtyFs(io_in_4_bits_dirtyFs),
    .io_in_4_bits_dirtyVs(io_in_4_bits_dirtyVs),
    .io_in_4_bits_traceBlockInPipe_itype(io_in_4_bits_traceBlockInPipe_itype),
    .io_in_4_bits_traceBlockInPipe_iretire(io_in_4_bits_traceBlockInPipe_iretire),
    .io_in_4_bits_traceBlockInPipe_ilastsize(io_in_4_bits_traceBlockInPipe_ilastsize),
    .io_in_4_bits_eliminatedMove(io_in_4_bits_eliminatedMove),
    .io_in_4_bits_debugInfo_renameTime(io_in_4_bits_debugInfo_renameTime),
    .io_in_4_bits_debug_seqNum_seqNum(io_in_4_bits_debug_seqNum_seqNum),
    .io_in_4_bits_debug_seqNum_uopIdx(io_in_4_bits_debug_seqNum_uopIdx),
    .io_in_4_bits_debug_fuType(io_in_4_bits_debug_fuType),
    .io_in_4_bits_debug_sim_trig(io_in_4_bits_debug_sim_trig),
    .io_in_4_bits_numLsElem(io_in_4_bits_numLsElem),
    .io_out_4_bits_instr(i_l4_io_out_bits_instr),
    .io_out_4_bits_pc(i_l4_io_out_bits_pc),
    .io_out_4_bits_foldpc(i_l4_io_out_bits_foldpc),
    .io_out_4_bits_exceptionVec_0(i_l4_io_out_bits_exceptionVec_0),
    .io_out_4_bits_exceptionVec_1(i_l4_io_out_bits_exceptionVec_1),
    .io_out_4_bits_exceptionVec_2(i_l4_io_out_bits_exceptionVec_2),
    .io_out_4_bits_exceptionVec_3(i_l4_io_out_bits_exceptionVec_3),
    .io_out_4_bits_exceptionVec_4(i_l4_io_out_bits_exceptionVec_4),
    .io_out_4_bits_exceptionVec_5(i_l4_io_out_bits_exceptionVec_5),
    .io_out_4_bits_exceptionVec_6(i_l4_io_out_bits_exceptionVec_6),
    .io_out_4_bits_exceptionVec_7(i_l4_io_out_bits_exceptionVec_7),
    .io_out_4_bits_exceptionVec_8(i_l4_io_out_bits_exceptionVec_8),
    .io_out_4_bits_exceptionVec_9(i_l4_io_out_bits_exceptionVec_9),
    .io_out_4_bits_exceptionVec_10(i_l4_io_out_bits_exceptionVec_10),
    .io_out_4_bits_exceptionVec_11(i_l4_io_out_bits_exceptionVec_11),
    .io_out_4_bits_exceptionVec_12(i_l4_io_out_bits_exceptionVec_12),
    .io_out_4_bits_exceptionVec_13(i_l4_io_out_bits_exceptionVec_13),
    .io_out_4_bits_exceptionVec_14(i_l4_io_out_bits_exceptionVec_14),
    .io_out_4_bits_exceptionVec_15(i_l4_io_out_bits_exceptionVec_15),
    .io_out_4_bits_exceptionVec_16(i_l4_io_out_bits_exceptionVec_16),
    .io_out_4_bits_exceptionVec_17(i_l4_io_out_bits_exceptionVec_17),
    .io_out_4_bits_exceptionVec_18(i_l4_io_out_bits_exceptionVec_18),
    .io_out_4_bits_exceptionVec_19(i_l4_io_out_bits_exceptionVec_19),
    .io_out_4_bits_exceptionVec_20(i_l4_io_out_bits_exceptionVec_20),
    .io_out_4_bits_exceptionVec_21(i_l4_io_out_bits_exceptionVec_21),
    .io_out_4_bits_exceptionVec_22(i_l4_io_out_bits_exceptionVec_22),
    .io_out_4_bits_exceptionVec_23(i_l4_io_out_bits_exceptionVec_23),
    .io_out_4_bits_isFetchMalAddr(i_l4_io_out_bits_isFetchMalAddr),
    .io_out_4_bits_hasException(i_l4_io_out_bits_hasException),
    .io_out_4_bits_trigger(i_l4_io_out_bits_trigger),
    .io_out_4_bits_preDecodeInfo_valid(i_l4_io_out_bits_preDecodeInfo_valid),
    .io_out_4_bits_preDecodeInfo_isRVC(i_l4_io_out_bits_preDecodeInfo_isRVC),
    .io_out_4_bits_preDecodeInfo_brType(i_l4_io_out_bits_preDecodeInfo_brType),
    .io_out_4_bits_preDecodeInfo_isCall(i_l4_io_out_bits_preDecodeInfo_isCall),
    .io_out_4_bits_preDecodeInfo_isRet(i_l4_io_out_bits_preDecodeInfo_isRet),
    .io_out_4_bits_pred_taken(i_l4_io_out_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(i_l4_io_out_bits_crossPageIPFFix),
    .io_out_4_bits_ftqPtr_flag(i_l4_io_out_bits_ftqPtr_flag),
    .io_out_4_bits_ftqPtr_value(i_l4_io_out_bits_ftqPtr_value),
    .io_out_4_bits_ftqOffset(i_l4_io_out_bits_ftqOffset),
    .io_out_4_bits_satpFlushFirstFetchFault(i_l4_io_out_bits_satpFlushFirstFetchFault),
    .io_out_4_bits_srcType_0(i_l4_io_out_bits_srcType_0),
    .io_out_4_bits_srcType_1(i_l4_io_out_bits_srcType_1),
    .io_out_4_bits_srcType_2(i_l4_io_out_bits_srcType_2),
    .io_out_4_bits_srcType_3(i_l4_io_out_bits_srcType_3),
    .io_out_4_bits_srcType_4(i_l4_io_out_bits_srcType_4),
    .io_out_4_bits_ldest(i_l4_io_out_bits_ldest),
    .io_out_4_bits_fuType(i_l4_io_out_bits_fuType),
    .io_out_4_bits_fuOpType(i_l4_io_out_bits_fuOpType),
    .io_out_4_bits_rfWen(i_l4_io_out_bits_rfWen),
    .io_out_4_bits_fpWen(i_l4_io_out_bits_fpWen),
    .io_out_4_bits_vecWen(i_l4_io_out_bits_vecWen),
    .io_out_4_bits_v0Wen(i_l4_io_out_bits_v0Wen),
    .io_out_4_bits_vlWen(i_l4_io_out_bits_vlWen),
    .io_out_4_bits_isXSTrap(i_l4_io_out_bits_isXSTrap),
    .io_out_4_bits_waitForward(i_l4_io_out_bits_waitForward),
    .io_out_4_bits_blockBackward(i_l4_io_out_bits_blockBackward),
    .io_out_4_bits_flushPipe(i_l4_io_out_bits_flushPipe),
    .io_out_4_bits_canRobCompress(i_l4_io_out_bits_canRobCompress),
    .io_out_4_bits_selImm(i_l4_io_out_bits_selImm),
    .io_out_4_bits_imm(i_l4_io_out_bits_imm),
    .io_out_4_bits_fpu_typeTagOut(i_l4_io_out_bits_fpu_typeTagOut),
    .io_out_4_bits_fpu_wflags(i_l4_io_out_bits_fpu_wflags),
    .io_out_4_bits_fpu_typ(i_l4_io_out_bits_fpu_typ),
    .io_out_4_bits_fpu_fmt(i_l4_io_out_bits_fpu_fmt),
    .io_out_4_bits_fpu_rm(i_l4_io_out_bits_fpu_rm),
    .io_out_4_bits_vpu_vill(i_l4_io_out_bits_vpu_vill),
    .io_out_4_bits_vpu_vma(i_l4_io_out_bits_vpu_vma),
    .io_out_4_bits_vpu_vta(i_l4_io_out_bits_vpu_vta),
    .io_out_4_bits_vpu_vsew(i_l4_io_out_bits_vpu_vsew),
    .io_out_4_bits_vpu_vlmul(i_l4_io_out_bits_vpu_vlmul),
    .io_out_4_bits_vpu_specVill(i_l4_io_out_bits_vpu_specVill),
    .io_out_4_bits_vpu_specVma(i_l4_io_out_bits_vpu_specVma),
    .io_out_4_bits_vpu_specVta(i_l4_io_out_bits_vpu_specVta),
    .io_out_4_bits_vpu_specVsew(i_l4_io_out_bits_vpu_specVsew),
    .io_out_4_bits_vpu_specVlmul(i_l4_io_out_bits_vpu_specVlmul),
    .io_out_4_bits_vpu_vm(i_l4_io_out_bits_vpu_vm),
    .io_out_4_bits_vpu_vstart(i_l4_io_out_bits_vpu_vstart),
    .io_out_4_bits_vpu_frm(i_l4_io_out_bits_vpu_frm),
    .io_out_4_bits_vpu_fpu_isFpToVecInst(i_l4_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_4_bits_vpu_fpu_isFP32Instr(i_l4_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_4_bits_vpu_fpu_isFP64Instr(i_l4_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_4_bits_vpu_fpu_isReduction(i_l4_io_out_bits_vpu_fpu_isReduction),
    .io_out_4_bits_vpu_fpu_isFoldTo1_2(i_l4_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_4_bits_vpu_fpu_isFoldTo1_4(i_l4_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_4_bits_vpu_fpu_isFoldTo1_8(i_l4_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_4_bits_vpu_vxrm(i_l4_io_out_bits_vpu_vxrm),
    .io_out_4_bits_vpu_vuopIdx(i_l4_io_out_bits_vpu_vuopIdx),
    .io_out_4_bits_vpu_lastUop(i_l4_io_out_bits_vpu_lastUop),
    .io_out_4_bits_vpu_vmask(i_l4_io_out_bits_vpu_vmask),
    .io_out_4_bits_vpu_vl(i_l4_io_out_bits_vpu_vl),
    .io_out_4_bits_vpu_nf(i_l4_io_out_bits_vpu_nf),
    .io_out_4_bits_vpu_veew(i_l4_io_out_bits_vpu_veew),
    .io_out_4_bits_vpu_isReverse(i_l4_io_out_bits_vpu_isReverse),
    .io_out_4_bits_vpu_isExt(i_l4_io_out_bits_vpu_isExt),
    .io_out_4_bits_vpu_isNarrow(i_l4_io_out_bits_vpu_isNarrow),
    .io_out_4_bits_vpu_isDstMask(i_l4_io_out_bits_vpu_isDstMask),
    .io_out_4_bits_vpu_isOpMask(i_l4_io_out_bits_vpu_isOpMask),
    .io_out_4_bits_vpu_isMove(i_l4_io_out_bits_vpu_isMove),
    .io_out_4_bits_vpu_isDependOldVd(i_l4_io_out_bits_vpu_isDependOldVd),
    .io_out_4_bits_vpu_isWritePartVd(i_l4_io_out_bits_vpu_isWritePartVd),
    .io_out_4_bits_vpu_isVleff(i_l4_io_out_bits_vpu_isVleff),
    .io_out_4_bits_vlsInstr(i_l4_io_out_bits_vlsInstr),
    .io_out_4_bits_wfflags(i_l4_io_out_bits_wfflags),
    .io_out_4_bits_isMove(i_l4_io_out_bits_isMove),
    .io_out_4_bits_uopIdx(i_l4_io_out_bits_uopIdx),
    .io_out_4_bits_isVset(i_l4_io_out_bits_isVset),
    .io_out_4_bits_firstUop(i_l4_io_out_bits_firstUop),
    .io_out_4_bits_lastUop(i_l4_io_out_bits_lastUop),
    .io_out_4_bits_numUops(i_l4_io_out_bits_numUops),
    .io_out_4_bits_numWB(i_l4_io_out_bits_numWB),
    .io_out_4_bits_commitType(i_l4_io_out_bits_commitType),
    .io_out_4_bits_psrc_0(i_l4_io_out_bits_psrc_0),
    .io_out_4_bits_psrc_1(i_l4_io_out_bits_psrc_1),
    .io_out_4_bits_psrc_2(i_l4_io_out_bits_psrc_2),
    .io_out_4_bits_psrc_3(i_l4_io_out_bits_psrc_3),
    .io_out_4_bits_psrc_4(i_l4_io_out_bits_psrc_4),
    .io_out_4_bits_pdest(i_l4_io_out_bits_pdest),
    .io_out_4_bits_robIdx_flag(i_l4_io_out_bits_robIdx_flag),
    .io_out_4_bits_robIdx_value(i_l4_io_out_bits_robIdx_value),
    .io_out_4_bits_instrSize(i_l4_io_out_bits_instrSize),
    .io_out_4_bits_dirtyFs(i_l4_io_out_bits_dirtyFs),
    .io_out_4_bits_dirtyVs(i_l4_io_out_bits_dirtyVs),
    .io_out_4_bits_traceBlockInPipe_itype(i_l4_io_out_bits_traceBlockInPipe_itype),
    .io_out_4_bits_traceBlockInPipe_iretire(i_l4_io_out_bits_traceBlockInPipe_iretire),
    .io_out_4_bits_traceBlockInPipe_ilastsize(i_l4_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_4_bits_eliminatedMove(i_l4_io_out_bits_eliminatedMove),
    .io_out_4_bits_debugInfo_renameTime(i_l4_io_out_bits_debugInfo_renameTime),
    .io_out_4_bits_debug_seqNum_seqNum(i_l4_io_out_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx(i_l4_io_out_bits_debug_seqNum_uopIdx),
    .io_out_4_bits_debug_fuType(i_l4_io_out_bits_debug_fuType),
    .io_out_4_bits_debug_sim_trig(i_l4_io_out_bits_debug_sim_trig),
    .io_out_4_bits_numLsElem(i_l4_io_out_bits_numLsElem),
    .io_in_5_valid(io_in_5_valid), .io_in_5_ready(i_l5_io_in_ready),
    .io_out_5_ready(io_out_5_ready), .io_out_5_valid(i_l5_io_out_valid),
    .io_in_5_bits_instr(io_in_5_bits_instr),
    .io_in_5_bits_pc(io_in_5_bits_pc),
    .io_in_5_bits_foldpc(io_in_5_bits_foldpc),
    .io_in_5_bits_exceptionVec_0(io_in_5_bits_exceptionVec_0),
    .io_in_5_bits_exceptionVec_1(io_in_5_bits_exceptionVec_1),
    .io_in_5_bits_exceptionVec_2(io_in_5_bits_exceptionVec_2),
    .io_in_5_bits_exceptionVec_3(io_in_5_bits_exceptionVec_3),
    .io_in_5_bits_exceptionVec_4(io_in_5_bits_exceptionVec_4),
    .io_in_5_bits_exceptionVec_5(io_in_5_bits_exceptionVec_5),
    .io_in_5_bits_exceptionVec_6(io_in_5_bits_exceptionVec_6),
    .io_in_5_bits_exceptionVec_7(io_in_5_bits_exceptionVec_7),
    .io_in_5_bits_exceptionVec_8(io_in_5_bits_exceptionVec_8),
    .io_in_5_bits_exceptionVec_9(io_in_5_bits_exceptionVec_9),
    .io_in_5_bits_exceptionVec_10(io_in_5_bits_exceptionVec_10),
    .io_in_5_bits_exceptionVec_11(io_in_5_bits_exceptionVec_11),
    .io_in_5_bits_exceptionVec_12(io_in_5_bits_exceptionVec_12),
    .io_in_5_bits_exceptionVec_13(io_in_5_bits_exceptionVec_13),
    .io_in_5_bits_exceptionVec_14(io_in_5_bits_exceptionVec_14),
    .io_in_5_bits_exceptionVec_15(io_in_5_bits_exceptionVec_15),
    .io_in_5_bits_exceptionVec_16(io_in_5_bits_exceptionVec_16),
    .io_in_5_bits_exceptionVec_17(io_in_5_bits_exceptionVec_17),
    .io_in_5_bits_exceptionVec_18(io_in_5_bits_exceptionVec_18),
    .io_in_5_bits_exceptionVec_19(io_in_5_bits_exceptionVec_19),
    .io_in_5_bits_exceptionVec_20(io_in_5_bits_exceptionVec_20),
    .io_in_5_bits_exceptionVec_21(io_in_5_bits_exceptionVec_21),
    .io_in_5_bits_exceptionVec_22(io_in_5_bits_exceptionVec_22),
    .io_in_5_bits_exceptionVec_23(io_in_5_bits_exceptionVec_23),
    .io_in_5_bits_isFetchMalAddr(io_in_5_bits_isFetchMalAddr),
    .io_in_5_bits_hasException(io_in_5_bits_hasException),
    .io_in_5_bits_trigger(io_in_5_bits_trigger),
    .io_in_5_bits_preDecodeInfo_valid(io_in_5_bits_preDecodeInfo_valid),
    .io_in_5_bits_preDecodeInfo_isRVC(io_in_5_bits_preDecodeInfo_isRVC),
    .io_in_5_bits_preDecodeInfo_brType(io_in_5_bits_preDecodeInfo_brType),
    .io_in_5_bits_preDecodeInfo_isCall(io_in_5_bits_preDecodeInfo_isCall),
    .io_in_5_bits_preDecodeInfo_isRet(io_in_5_bits_preDecodeInfo_isRet),
    .io_in_5_bits_pred_taken(io_in_5_bits_pred_taken),
    .io_in_5_bits_crossPageIPFFix(io_in_5_bits_crossPageIPFFix),
    .io_in_5_bits_ftqPtr_flag(io_in_5_bits_ftqPtr_flag),
    .io_in_5_bits_ftqPtr_value(io_in_5_bits_ftqPtr_value),
    .io_in_5_bits_ftqOffset(io_in_5_bits_ftqOffset),
    .io_in_5_bits_satpFlushFirstFetchFault(io_in_5_bits_satpFlushFirstFetchFault),
    .io_in_5_bits_srcType_0(io_in_5_bits_srcType_0),
    .io_in_5_bits_srcType_1(io_in_5_bits_srcType_1),
    .io_in_5_bits_srcType_2(io_in_5_bits_srcType_2),
    .io_in_5_bits_srcType_3(io_in_5_bits_srcType_3),
    .io_in_5_bits_srcType_4(io_in_5_bits_srcType_4),
    .io_in_5_bits_ldest(io_in_5_bits_ldest),
    .io_in_5_bits_fuType(io_in_5_bits_fuType),
    .io_in_5_bits_fuOpType(io_in_5_bits_fuOpType),
    .io_in_5_bits_rfWen(io_in_5_bits_rfWen),
    .io_in_5_bits_fpWen(io_in_5_bits_fpWen),
    .io_in_5_bits_vecWen(io_in_5_bits_vecWen),
    .io_in_5_bits_v0Wen(io_in_5_bits_v0Wen),
    .io_in_5_bits_vlWen(io_in_5_bits_vlWen),
    .io_in_5_bits_isXSTrap(io_in_5_bits_isXSTrap),
    .io_in_5_bits_waitForward(io_in_5_bits_waitForward),
    .io_in_5_bits_blockBackward(io_in_5_bits_blockBackward),
    .io_in_5_bits_flushPipe(io_in_5_bits_flushPipe),
    .io_in_5_bits_canRobCompress(io_in_5_bits_canRobCompress),
    .io_in_5_bits_selImm(io_in_5_bits_selImm),
    .io_in_5_bits_imm(io_in_5_bits_imm),
    .io_in_5_bits_fpu_typeTagOut(io_in_5_bits_fpu_typeTagOut),
    .io_in_5_bits_fpu_wflags(io_in_5_bits_fpu_wflags),
    .io_in_5_bits_fpu_typ(io_in_5_bits_fpu_typ),
    .io_in_5_bits_fpu_fmt(io_in_5_bits_fpu_fmt),
    .io_in_5_bits_fpu_rm(io_in_5_bits_fpu_rm),
    .io_in_5_bits_vpu_vill(io_in_5_bits_vpu_vill),
    .io_in_5_bits_vpu_vma(io_in_5_bits_vpu_vma),
    .io_in_5_bits_vpu_vta(io_in_5_bits_vpu_vta),
    .io_in_5_bits_vpu_vsew(io_in_5_bits_vpu_vsew),
    .io_in_5_bits_vpu_vlmul(io_in_5_bits_vpu_vlmul),
    .io_in_5_bits_vpu_specVill(io_in_5_bits_vpu_specVill),
    .io_in_5_bits_vpu_specVma(io_in_5_bits_vpu_specVma),
    .io_in_5_bits_vpu_specVta(io_in_5_bits_vpu_specVta),
    .io_in_5_bits_vpu_specVsew(io_in_5_bits_vpu_specVsew),
    .io_in_5_bits_vpu_specVlmul(io_in_5_bits_vpu_specVlmul),
    .io_in_5_bits_vpu_vm(io_in_5_bits_vpu_vm),
    .io_in_5_bits_vpu_vstart(io_in_5_bits_vpu_vstart),
    .io_in_5_bits_vpu_frm(io_in_5_bits_vpu_frm),
    .io_in_5_bits_vpu_fpu_isFpToVecInst(io_in_5_bits_vpu_fpu_isFpToVecInst),
    .io_in_5_bits_vpu_fpu_isFP32Instr(io_in_5_bits_vpu_fpu_isFP32Instr),
    .io_in_5_bits_vpu_fpu_isFP64Instr(io_in_5_bits_vpu_fpu_isFP64Instr),
    .io_in_5_bits_vpu_fpu_isReduction(io_in_5_bits_vpu_fpu_isReduction),
    .io_in_5_bits_vpu_fpu_isFoldTo1_2(io_in_5_bits_vpu_fpu_isFoldTo1_2),
    .io_in_5_bits_vpu_fpu_isFoldTo1_4(io_in_5_bits_vpu_fpu_isFoldTo1_4),
    .io_in_5_bits_vpu_fpu_isFoldTo1_8(io_in_5_bits_vpu_fpu_isFoldTo1_8),
    .io_in_5_bits_vpu_vxrm(io_in_5_bits_vpu_vxrm),
    .io_in_5_bits_vpu_vuopIdx(io_in_5_bits_vpu_vuopIdx),
    .io_in_5_bits_vpu_lastUop(io_in_5_bits_vpu_lastUop),
    .io_in_5_bits_vpu_vmask(io_in_5_bits_vpu_vmask),
    .io_in_5_bits_vpu_vl(io_in_5_bits_vpu_vl),
    .io_in_5_bits_vpu_nf(io_in_5_bits_vpu_nf),
    .io_in_5_bits_vpu_veew(io_in_5_bits_vpu_veew),
    .io_in_5_bits_vpu_isReverse(io_in_5_bits_vpu_isReverse),
    .io_in_5_bits_vpu_isExt(io_in_5_bits_vpu_isExt),
    .io_in_5_bits_vpu_isNarrow(io_in_5_bits_vpu_isNarrow),
    .io_in_5_bits_vpu_isDstMask(io_in_5_bits_vpu_isDstMask),
    .io_in_5_bits_vpu_isOpMask(io_in_5_bits_vpu_isOpMask),
    .io_in_5_bits_vpu_isMove(io_in_5_bits_vpu_isMove),
    .io_in_5_bits_vpu_isDependOldVd(io_in_5_bits_vpu_isDependOldVd),
    .io_in_5_bits_vpu_isWritePartVd(io_in_5_bits_vpu_isWritePartVd),
    .io_in_5_bits_vpu_isVleff(io_in_5_bits_vpu_isVleff),
    .io_in_5_bits_vlsInstr(io_in_5_bits_vlsInstr),
    .io_in_5_bits_wfflags(io_in_5_bits_wfflags),
    .io_in_5_bits_isMove(io_in_5_bits_isMove),
    .io_in_5_bits_uopIdx(io_in_5_bits_uopIdx),
    .io_in_5_bits_isVset(io_in_5_bits_isVset),
    .io_in_5_bits_firstUop(io_in_5_bits_firstUop),
    .io_in_5_bits_lastUop(io_in_5_bits_lastUop),
    .io_in_5_bits_numUops(io_in_5_bits_numUops),
    .io_in_5_bits_numWB(io_in_5_bits_numWB),
    .io_in_5_bits_commitType(io_in_5_bits_commitType),
    .io_in_5_bits_psrc_0(io_in_5_bits_psrc_0),
    .io_in_5_bits_psrc_1(io_in_5_bits_psrc_1),
    .io_in_5_bits_psrc_2(io_in_5_bits_psrc_2),
    .io_in_5_bits_psrc_3(io_in_5_bits_psrc_3),
    .io_in_5_bits_psrc_4(io_in_5_bits_psrc_4),
    .io_in_5_bits_pdest(io_in_5_bits_pdest),
    .io_in_5_bits_robIdx_flag(io_in_5_bits_robIdx_flag),
    .io_in_5_bits_robIdx_value(io_in_5_bits_robIdx_value),
    .io_in_5_bits_instrSize(io_in_5_bits_instrSize),
    .io_in_5_bits_dirtyFs(io_in_5_bits_dirtyFs),
    .io_in_5_bits_dirtyVs(io_in_5_bits_dirtyVs),
    .io_in_5_bits_traceBlockInPipe_itype(io_in_5_bits_traceBlockInPipe_itype),
    .io_in_5_bits_traceBlockInPipe_iretire(io_in_5_bits_traceBlockInPipe_iretire),
    .io_in_5_bits_traceBlockInPipe_ilastsize(io_in_5_bits_traceBlockInPipe_ilastsize),
    .io_in_5_bits_eliminatedMove(io_in_5_bits_eliminatedMove),
    .io_in_5_bits_debugInfo_renameTime(io_in_5_bits_debugInfo_renameTime),
    .io_in_5_bits_debug_seqNum_seqNum(io_in_5_bits_debug_seqNum_seqNum),
    .io_in_5_bits_debug_seqNum_uopIdx(io_in_5_bits_debug_seqNum_uopIdx),
    .io_in_5_bits_debug_fuType(io_in_5_bits_debug_fuType),
    .io_in_5_bits_debug_sim_trig(io_in_5_bits_debug_sim_trig),
    .io_in_5_bits_numLsElem(io_in_5_bits_numLsElem),
    .io_out_5_bits_instr(i_l5_io_out_bits_instr),
    .io_out_5_bits_pc(i_l5_io_out_bits_pc),
    .io_out_5_bits_foldpc(i_l5_io_out_bits_foldpc),
    .io_out_5_bits_exceptionVec_0(i_l5_io_out_bits_exceptionVec_0),
    .io_out_5_bits_exceptionVec_1(i_l5_io_out_bits_exceptionVec_1),
    .io_out_5_bits_exceptionVec_2(i_l5_io_out_bits_exceptionVec_2),
    .io_out_5_bits_exceptionVec_3(i_l5_io_out_bits_exceptionVec_3),
    .io_out_5_bits_exceptionVec_4(i_l5_io_out_bits_exceptionVec_4),
    .io_out_5_bits_exceptionVec_5(i_l5_io_out_bits_exceptionVec_5),
    .io_out_5_bits_exceptionVec_6(i_l5_io_out_bits_exceptionVec_6),
    .io_out_5_bits_exceptionVec_7(i_l5_io_out_bits_exceptionVec_7),
    .io_out_5_bits_exceptionVec_8(i_l5_io_out_bits_exceptionVec_8),
    .io_out_5_bits_exceptionVec_9(i_l5_io_out_bits_exceptionVec_9),
    .io_out_5_bits_exceptionVec_10(i_l5_io_out_bits_exceptionVec_10),
    .io_out_5_bits_exceptionVec_11(i_l5_io_out_bits_exceptionVec_11),
    .io_out_5_bits_exceptionVec_12(i_l5_io_out_bits_exceptionVec_12),
    .io_out_5_bits_exceptionVec_13(i_l5_io_out_bits_exceptionVec_13),
    .io_out_5_bits_exceptionVec_14(i_l5_io_out_bits_exceptionVec_14),
    .io_out_5_bits_exceptionVec_15(i_l5_io_out_bits_exceptionVec_15),
    .io_out_5_bits_exceptionVec_16(i_l5_io_out_bits_exceptionVec_16),
    .io_out_5_bits_exceptionVec_17(i_l5_io_out_bits_exceptionVec_17),
    .io_out_5_bits_exceptionVec_18(i_l5_io_out_bits_exceptionVec_18),
    .io_out_5_bits_exceptionVec_19(i_l5_io_out_bits_exceptionVec_19),
    .io_out_5_bits_exceptionVec_20(i_l5_io_out_bits_exceptionVec_20),
    .io_out_5_bits_exceptionVec_21(i_l5_io_out_bits_exceptionVec_21),
    .io_out_5_bits_exceptionVec_22(i_l5_io_out_bits_exceptionVec_22),
    .io_out_5_bits_exceptionVec_23(i_l5_io_out_bits_exceptionVec_23),
    .io_out_5_bits_isFetchMalAddr(i_l5_io_out_bits_isFetchMalAddr),
    .io_out_5_bits_hasException(i_l5_io_out_bits_hasException),
    .io_out_5_bits_trigger(i_l5_io_out_bits_trigger),
    .io_out_5_bits_preDecodeInfo_valid(i_l5_io_out_bits_preDecodeInfo_valid),
    .io_out_5_bits_preDecodeInfo_isRVC(i_l5_io_out_bits_preDecodeInfo_isRVC),
    .io_out_5_bits_preDecodeInfo_brType(i_l5_io_out_bits_preDecodeInfo_brType),
    .io_out_5_bits_preDecodeInfo_isCall(i_l5_io_out_bits_preDecodeInfo_isCall),
    .io_out_5_bits_preDecodeInfo_isRet(i_l5_io_out_bits_preDecodeInfo_isRet),
    .io_out_5_bits_pred_taken(i_l5_io_out_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(i_l5_io_out_bits_crossPageIPFFix),
    .io_out_5_bits_ftqPtr_flag(i_l5_io_out_bits_ftqPtr_flag),
    .io_out_5_bits_ftqPtr_value(i_l5_io_out_bits_ftqPtr_value),
    .io_out_5_bits_ftqOffset(i_l5_io_out_bits_ftqOffset),
    .io_out_5_bits_satpFlushFirstFetchFault(i_l5_io_out_bits_satpFlushFirstFetchFault),
    .io_out_5_bits_srcType_0(i_l5_io_out_bits_srcType_0),
    .io_out_5_bits_srcType_1(i_l5_io_out_bits_srcType_1),
    .io_out_5_bits_srcType_2(i_l5_io_out_bits_srcType_2),
    .io_out_5_bits_srcType_3(i_l5_io_out_bits_srcType_3),
    .io_out_5_bits_srcType_4(i_l5_io_out_bits_srcType_4),
    .io_out_5_bits_ldest(i_l5_io_out_bits_ldest),
    .io_out_5_bits_fuType(i_l5_io_out_bits_fuType),
    .io_out_5_bits_fuOpType(i_l5_io_out_bits_fuOpType),
    .io_out_5_bits_rfWen(i_l5_io_out_bits_rfWen),
    .io_out_5_bits_fpWen(i_l5_io_out_bits_fpWen),
    .io_out_5_bits_vecWen(i_l5_io_out_bits_vecWen),
    .io_out_5_bits_v0Wen(i_l5_io_out_bits_v0Wen),
    .io_out_5_bits_vlWen(i_l5_io_out_bits_vlWen),
    .io_out_5_bits_isXSTrap(i_l5_io_out_bits_isXSTrap),
    .io_out_5_bits_waitForward(i_l5_io_out_bits_waitForward),
    .io_out_5_bits_blockBackward(i_l5_io_out_bits_blockBackward),
    .io_out_5_bits_flushPipe(i_l5_io_out_bits_flushPipe),
    .io_out_5_bits_canRobCompress(i_l5_io_out_bits_canRobCompress),
    .io_out_5_bits_selImm(i_l5_io_out_bits_selImm),
    .io_out_5_bits_imm(i_l5_io_out_bits_imm),
    .io_out_5_bits_fpu_typeTagOut(i_l5_io_out_bits_fpu_typeTagOut),
    .io_out_5_bits_fpu_wflags(i_l5_io_out_bits_fpu_wflags),
    .io_out_5_bits_fpu_typ(i_l5_io_out_bits_fpu_typ),
    .io_out_5_bits_fpu_fmt(i_l5_io_out_bits_fpu_fmt),
    .io_out_5_bits_fpu_rm(i_l5_io_out_bits_fpu_rm),
    .io_out_5_bits_vpu_vill(i_l5_io_out_bits_vpu_vill),
    .io_out_5_bits_vpu_vma(i_l5_io_out_bits_vpu_vma),
    .io_out_5_bits_vpu_vta(i_l5_io_out_bits_vpu_vta),
    .io_out_5_bits_vpu_vsew(i_l5_io_out_bits_vpu_vsew),
    .io_out_5_bits_vpu_vlmul(i_l5_io_out_bits_vpu_vlmul),
    .io_out_5_bits_vpu_specVill(i_l5_io_out_bits_vpu_specVill),
    .io_out_5_bits_vpu_specVma(i_l5_io_out_bits_vpu_specVma),
    .io_out_5_bits_vpu_specVta(i_l5_io_out_bits_vpu_specVta),
    .io_out_5_bits_vpu_specVsew(i_l5_io_out_bits_vpu_specVsew),
    .io_out_5_bits_vpu_specVlmul(i_l5_io_out_bits_vpu_specVlmul),
    .io_out_5_bits_vpu_vm(i_l5_io_out_bits_vpu_vm),
    .io_out_5_bits_vpu_vstart(i_l5_io_out_bits_vpu_vstart),
    .io_out_5_bits_vpu_frm(i_l5_io_out_bits_vpu_frm),
    .io_out_5_bits_vpu_fpu_isFpToVecInst(i_l5_io_out_bits_vpu_fpu_isFpToVecInst),
    .io_out_5_bits_vpu_fpu_isFP32Instr(i_l5_io_out_bits_vpu_fpu_isFP32Instr),
    .io_out_5_bits_vpu_fpu_isFP64Instr(i_l5_io_out_bits_vpu_fpu_isFP64Instr),
    .io_out_5_bits_vpu_fpu_isReduction(i_l5_io_out_bits_vpu_fpu_isReduction),
    .io_out_5_bits_vpu_fpu_isFoldTo1_2(i_l5_io_out_bits_vpu_fpu_isFoldTo1_2),
    .io_out_5_bits_vpu_fpu_isFoldTo1_4(i_l5_io_out_bits_vpu_fpu_isFoldTo1_4),
    .io_out_5_bits_vpu_fpu_isFoldTo1_8(i_l5_io_out_bits_vpu_fpu_isFoldTo1_8),
    .io_out_5_bits_vpu_vxrm(i_l5_io_out_bits_vpu_vxrm),
    .io_out_5_bits_vpu_vuopIdx(i_l5_io_out_bits_vpu_vuopIdx),
    .io_out_5_bits_vpu_lastUop(i_l5_io_out_bits_vpu_lastUop),
    .io_out_5_bits_vpu_vmask(i_l5_io_out_bits_vpu_vmask),
    .io_out_5_bits_vpu_vl(i_l5_io_out_bits_vpu_vl),
    .io_out_5_bits_vpu_nf(i_l5_io_out_bits_vpu_nf),
    .io_out_5_bits_vpu_veew(i_l5_io_out_bits_vpu_veew),
    .io_out_5_bits_vpu_isReverse(i_l5_io_out_bits_vpu_isReverse),
    .io_out_5_bits_vpu_isExt(i_l5_io_out_bits_vpu_isExt),
    .io_out_5_bits_vpu_isNarrow(i_l5_io_out_bits_vpu_isNarrow),
    .io_out_5_bits_vpu_isDstMask(i_l5_io_out_bits_vpu_isDstMask),
    .io_out_5_bits_vpu_isOpMask(i_l5_io_out_bits_vpu_isOpMask),
    .io_out_5_bits_vpu_isMove(i_l5_io_out_bits_vpu_isMove),
    .io_out_5_bits_vpu_isDependOldVd(i_l5_io_out_bits_vpu_isDependOldVd),
    .io_out_5_bits_vpu_isWritePartVd(i_l5_io_out_bits_vpu_isWritePartVd),
    .io_out_5_bits_vpu_isVleff(i_l5_io_out_bits_vpu_isVleff),
    .io_out_5_bits_vlsInstr(i_l5_io_out_bits_vlsInstr),
    .io_out_5_bits_wfflags(i_l5_io_out_bits_wfflags),
    .io_out_5_bits_isMove(i_l5_io_out_bits_isMove),
    .io_out_5_bits_uopIdx(i_l5_io_out_bits_uopIdx),
    .io_out_5_bits_isVset(i_l5_io_out_bits_isVset),
    .io_out_5_bits_firstUop(i_l5_io_out_bits_firstUop),
    .io_out_5_bits_lastUop(i_l5_io_out_bits_lastUop),
    .io_out_5_bits_numUops(i_l5_io_out_bits_numUops),
    .io_out_5_bits_numWB(i_l5_io_out_bits_numWB),
    .io_out_5_bits_commitType(i_l5_io_out_bits_commitType),
    .io_out_5_bits_psrc_0(i_l5_io_out_bits_psrc_0),
    .io_out_5_bits_psrc_1(i_l5_io_out_bits_psrc_1),
    .io_out_5_bits_psrc_2(i_l5_io_out_bits_psrc_2),
    .io_out_5_bits_psrc_3(i_l5_io_out_bits_psrc_3),
    .io_out_5_bits_psrc_4(i_l5_io_out_bits_psrc_4),
    .io_out_5_bits_pdest(i_l5_io_out_bits_pdest),
    .io_out_5_bits_robIdx_flag(i_l5_io_out_bits_robIdx_flag),
    .io_out_5_bits_robIdx_value(i_l5_io_out_bits_robIdx_value),
    .io_out_5_bits_instrSize(i_l5_io_out_bits_instrSize),
    .io_out_5_bits_dirtyFs(i_l5_io_out_bits_dirtyFs),
    .io_out_5_bits_dirtyVs(i_l5_io_out_bits_dirtyVs),
    .io_out_5_bits_traceBlockInPipe_itype(i_l5_io_out_bits_traceBlockInPipe_itype),
    .io_out_5_bits_traceBlockInPipe_iretire(i_l5_io_out_bits_traceBlockInPipe_iretire),
    .io_out_5_bits_traceBlockInPipe_ilastsize(i_l5_io_out_bits_traceBlockInPipe_ilastsize),
    .io_out_5_bits_eliminatedMove(i_l5_io_out_bits_eliminatedMove),
    .io_out_5_bits_debugInfo_renameTime(i_l5_io_out_bits_debugInfo_renameTime),
    .io_out_5_bits_debug_seqNum_seqNum(i_l5_io_out_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx(i_l5_io_out_bits_debug_seqNum_uopIdx),
    .io_out_5_bits_debug_fuType(i_l5_io_out_bits_debug_fuType),
    .io_out_5_bits_debug_sim_trig(i_l5_io_out_bits_debug_sim_trig),
    .io_out_5_bits_numLsElem(i_l5_io_out_bits_numLsElem)
  );

  task automatic drive_all();
    io_flush      = ($urandom % 512) == 0;
    io_outAllFire = ($urandom % 100) < 40;
    io_in_0_valid  = ($urandom % 100) < 70;
    io_out_0_ready = ($urandom % 100) < 55;
    io_in_0_bits_instr = 32'($urandom);
    io_in_0_bits_pc = 50'({$urandom, $urandom});
    io_in_0_bits_foldpc = 10'($urandom);
    io_in_0_bits_exceptionVec_0 = 1'($urandom);
    io_in_0_bits_exceptionVec_1 = 1'($urandom);
    io_in_0_bits_exceptionVec_2 = 1'($urandom);
    io_in_0_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_0_bits_exceptionVec_22 = 1'($urandom);
    io_in_0_bits_exceptionVec_23 = 1'($urandom);
    io_in_0_bits_isFetchMalAddr = 1'($urandom);
    io_in_0_bits_hasException = 1'($urandom);
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
    io_in_0_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_0_bits_srcType_0 = 4'($urandom);
    io_in_0_bits_srcType_1 = 4'($urandom);
    io_in_0_bits_srcType_2 = 4'($urandom);
    io_in_0_bits_srcType_3 = 4'($urandom);
    io_in_0_bits_srcType_4 = 4'($urandom);
    io_in_0_bits_ldest = 6'($urandom);
    io_in_0_bits_fuType = 35'({$urandom, $urandom});
    io_in_0_bits_fuOpType = 9'($urandom);
    io_in_0_bits_rfWen = 1'($urandom);
    io_in_0_bits_fpWen = 1'($urandom);
    io_in_0_bits_vecWen = 1'($urandom);
    io_in_0_bits_v0Wen = 1'($urandom);
    io_in_0_bits_vlWen = 1'($urandom);
    io_in_0_bits_isXSTrap = 1'($urandom);
    io_in_0_bits_waitForward = 1'($urandom);
    io_in_0_bits_blockBackward = 1'($urandom);
    io_in_0_bits_flushPipe = 1'($urandom);
    io_in_0_bits_canRobCompress = 1'($urandom);
    io_in_0_bits_selImm = 4'($urandom);
    io_in_0_bits_imm = 32'($urandom);
    io_in_0_bits_fpu_typeTagOut = 2'($urandom);
    io_in_0_bits_fpu_wflags = 1'($urandom);
    io_in_0_bits_fpu_typ = 2'($urandom);
    io_in_0_bits_fpu_fmt = 2'($urandom);
    io_in_0_bits_fpu_rm = 3'($urandom);
    io_in_0_bits_vpu_vill = 1'($urandom);
    io_in_0_bits_vpu_vma = 1'($urandom);
    io_in_0_bits_vpu_vta = 1'($urandom);
    io_in_0_bits_vpu_vsew = 2'($urandom);
    io_in_0_bits_vpu_vlmul = 3'($urandom);
    io_in_0_bits_vpu_specVill = 1'($urandom);
    io_in_0_bits_vpu_specVma = 1'($urandom);
    io_in_0_bits_vpu_specVta = 1'($urandom);
    io_in_0_bits_vpu_specVsew = 2'($urandom);
    io_in_0_bits_vpu_specVlmul = 3'($urandom);
    io_in_0_bits_vpu_vm = 1'($urandom);
    io_in_0_bits_vpu_vstart = 8'($urandom);
    io_in_0_bits_vpu_frm = 3'($urandom);
    io_in_0_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_0_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_0_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_0_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_0_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_0_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_0_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_0_bits_vpu_vxrm = 2'($urandom);
    io_in_0_bits_vpu_vuopIdx = 7'($urandom);
    io_in_0_bits_vpu_lastUop = 1'($urandom);
    io_in_0_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_0_bits_vpu_vl = 8'($urandom);
    io_in_0_bits_vpu_nf = 3'($urandom);
    io_in_0_bits_vpu_veew = 2'($urandom);
    io_in_0_bits_vpu_isReverse = 1'($urandom);
    io_in_0_bits_vpu_isExt = 1'($urandom);
    io_in_0_bits_vpu_isNarrow = 1'($urandom);
    io_in_0_bits_vpu_isDstMask = 1'($urandom);
    io_in_0_bits_vpu_isOpMask = 1'($urandom);
    io_in_0_bits_vpu_isMove = 1'($urandom);
    io_in_0_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_0_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_0_bits_vpu_isVleff = 1'($urandom);
    io_in_0_bits_vlsInstr = 1'($urandom);
    io_in_0_bits_wfflags = 1'($urandom);
    io_in_0_bits_isMove = 1'($urandom);
    io_in_0_bits_uopIdx = 7'($urandom);
    io_in_0_bits_isVset = 1'($urandom);
    io_in_0_bits_firstUop = 1'($urandom);
    io_in_0_bits_lastUop = 1'($urandom);
    io_in_0_bits_numUops = 7'($urandom);
    io_in_0_bits_numWB = 7'($urandom);
    io_in_0_bits_commitType = 3'($urandom);
    io_in_0_bits_psrc_0 = 8'($urandom);
    io_in_0_bits_psrc_1 = 8'($urandom);
    io_in_0_bits_psrc_2 = 8'($urandom);
    io_in_0_bits_psrc_3 = 8'($urandom);
    io_in_0_bits_psrc_4 = 8'($urandom);
    io_in_0_bits_pdest = 8'($urandom);
    io_in_0_bits_robIdx_flag = 1'($urandom);
    io_in_0_bits_robIdx_value = 8'($urandom);
    io_in_0_bits_instrSize = 3'($urandom);
    io_in_0_bits_dirtyFs = 1'($urandom);
    io_in_0_bits_dirtyVs = 1'($urandom);
    io_in_0_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_0_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_0_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_0_bits_eliminatedMove = 1'($urandom);
    io_in_0_bits_snapshot = 1'($urandom);
    io_in_0_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_0_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_0_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_0_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_0_bits_debug_sim_trig = 1'($urandom);
    io_in_0_bits_numLsElem = 5'($urandom);
    io_in_1_valid  = ($urandom % 100) < 70;
    io_out_1_ready = ($urandom % 100) < 55;
    io_in_1_bits_instr = 32'($urandom);
    io_in_1_bits_pc = 50'({$urandom, $urandom});
    io_in_1_bits_foldpc = 10'($urandom);
    io_in_1_bits_exceptionVec_0 = 1'($urandom);
    io_in_1_bits_exceptionVec_1 = 1'($urandom);
    io_in_1_bits_exceptionVec_2 = 1'($urandom);
    io_in_1_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_1_bits_exceptionVec_22 = 1'($urandom);
    io_in_1_bits_exceptionVec_23 = 1'($urandom);
    io_in_1_bits_isFetchMalAddr = 1'($urandom);
    io_in_1_bits_hasException = 1'($urandom);
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
    io_in_1_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_1_bits_srcType_0 = 4'($urandom);
    io_in_1_bits_srcType_1 = 4'($urandom);
    io_in_1_bits_srcType_2 = 4'($urandom);
    io_in_1_bits_srcType_3 = 4'($urandom);
    io_in_1_bits_srcType_4 = 4'($urandom);
    io_in_1_bits_ldest = 6'($urandom);
    io_in_1_bits_fuType = 35'({$urandom, $urandom});
    io_in_1_bits_fuOpType = 9'($urandom);
    io_in_1_bits_rfWen = 1'($urandom);
    io_in_1_bits_fpWen = 1'($urandom);
    io_in_1_bits_vecWen = 1'($urandom);
    io_in_1_bits_v0Wen = 1'($urandom);
    io_in_1_bits_vlWen = 1'($urandom);
    io_in_1_bits_isXSTrap = 1'($urandom);
    io_in_1_bits_waitForward = 1'($urandom);
    io_in_1_bits_blockBackward = 1'($urandom);
    io_in_1_bits_flushPipe = 1'($urandom);
    io_in_1_bits_canRobCompress = 1'($urandom);
    io_in_1_bits_selImm = 4'($urandom);
    io_in_1_bits_imm = 32'($urandom);
    io_in_1_bits_fpu_typeTagOut = 2'($urandom);
    io_in_1_bits_fpu_wflags = 1'($urandom);
    io_in_1_bits_fpu_typ = 2'($urandom);
    io_in_1_bits_fpu_fmt = 2'($urandom);
    io_in_1_bits_fpu_rm = 3'($urandom);
    io_in_1_bits_vpu_vill = 1'($urandom);
    io_in_1_bits_vpu_vma = 1'($urandom);
    io_in_1_bits_vpu_vta = 1'($urandom);
    io_in_1_bits_vpu_vsew = 2'($urandom);
    io_in_1_bits_vpu_vlmul = 3'($urandom);
    io_in_1_bits_vpu_specVill = 1'($urandom);
    io_in_1_bits_vpu_specVma = 1'($urandom);
    io_in_1_bits_vpu_specVta = 1'($urandom);
    io_in_1_bits_vpu_specVsew = 2'($urandom);
    io_in_1_bits_vpu_specVlmul = 3'($urandom);
    io_in_1_bits_vpu_vm = 1'($urandom);
    io_in_1_bits_vpu_vstart = 8'($urandom);
    io_in_1_bits_vpu_frm = 3'($urandom);
    io_in_1_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_1_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_1_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_1_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_1_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_1_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_1_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_1_bits_vpu_vxrm = 2'($urandom);
    io_in_1_bits_vpu_vuopIdx = 7'($urandom);
    io_in_1_bits_vpu_lastUop = 1'($urandom);
    io_in_1_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_1_bits_vpu_vl = 8'($urandom);
    io_in_1_bits_vpu_nf = 3'($urandom);
    io_in_1_bits_vpu_veew = 2'($urandom);
    io_in_1_bits_vpu_isReverse = 1'($urandom);
    io_in_1_bits_vpu_isExt = 1'($urandom);
    io_in_1_bits_vpu_isNarrow = 1'($urandom);
    io_in_1_bits_vpu_isDstMask = 1'($urandom);
    io_in_1_bits_vpu_isOpMask = 1'($urandom);
    io_in_1_bits_vpu_isMove = 1'($urandom);
    io_in_1_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_1_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_1_bits_vpu_isVleff = 1'($urandom);
    io_in_1_bits_vlsInstr = 1'($urandom);
    io_in_1_bits_wfflags = 1'($urandom);
    io_in_1_bits_isMove = 1'($urandom);
    io_in_1_bits_uopIdx = 7'($urandom);
    io_in_1_bits_isVset = 1'($urandom);
    io_in_1_bits_firstUop = 1'($urandom);
    io_in_1_bits_lastUop = 1'($urandom);
    io_in_1_bits_numUops = 7'($urandom);
    io_in_1_bits_numWB = 7'($urandom);
    io_in_1_bits_commitType = 3'($urandom);
    io_in_1_bits_psrc_0 = 8'($urandom);
    io_in_1_bits_psrc_1 = 8'($urandom);
    io_in_1_bits_psrc_2 = 8'($urandom);
    io_in_1_bits_psrc_3 = 8'($urandom);
    io_in_1_bits_psrc_4 = 8'($urandom);
    io_in_1_bits_pdest = 8'($urandom);
    io_in_1_bits_robIdx_flag = 1'($urandom);
    io_in_1_bits_robIdx_value = 8'($urandom);
    io_in_1_bits_instrSize = 3'($urandom);
    io_in_1_bits_dirtyFs = 1'($urandom);
    io_in_1_bits_dirtyVs = 1'($urandom);
    io_in_1_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_1_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_1_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_1_bits_eliminatedMove = 1'($urandom);
    io_in_1_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_1_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_1_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_1_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_1_bits_debug_sim_trig = 1'($urandom);
    io_in_1_bits_numLsElem = 5'($urandom);
    io_in_2_valid  = ($urandom % 100) < 70;
    io_out_2_ready = ($urandom % 100) < 55;
    io_in_2_bits_instr = 32'($urandom);
    io_in_2_bits_pc = 50'({$urandom, $urandom});
    io_in_2_bits_foldpc = 10'($urandom);
    io_in_2_bits_exceptionVec_0 = 1'($urandom);
    io_in_2_bits_exceptionVec_1 = 1'($urandom);
    io_in_2_bits_exceptionVec_2 = 1'($urandom);
    io_in_2_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_2_bits_exceptionVec_22 = 1'($urandom);
    io_in_2_bits_exceptionVec_23 = 1'($urandom);
    io_in_2_bits_isFetchMalAddr = 1'($urandom);
    io_in_2_bits_hasException = 1'($urandom);
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
    io_in_2_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_2_bits_srcType_0 = 4'($urandom);
    io_in_2_bits_srcType_1 = 4'($urandom);
    io_in_2_bits_srcType_2 = 4'($urandom);
    io_in_2_bits_srcType_3 = 4'($urandom);
    io_in_2_bits_srcType_4 = 4'($urandom);
    io_in_2_bits_ldest = 6'($urandom);
    io_in_2_bits_fuType = 35'({$urandom, $urandom});
    io_in_2_bits_fuOpType = 9'($urandom);
    io_in_2_bits_rfWen = 1'($urandom);
    io_in_2_bits_fpWen = 1'($urandom);
    io_in_2_bits_vecWen = 1'($urandom);
    io_in_2_bits_v0Wen = 1'($urandom);
    io_in_2_bits_vlWen = 1'($urandom);
    io_in_2_bits_isXSTrap = 1'($urandom);
    io_in_2_bits_waitForward = 1'($urandom);
    io_in_2_bits_blockBackward = 1'($urandom);
    io_in_2_bits_flushPipe = 1'($urandom);
    io_in_2_bits_canRobCompress = 1'($urandom);
    io_in_2_bits_selImm = 4'($urandom);
    io_in_2_bits_imm = 32'($urandom);
    io_in_2_bits_fpu_typeTagOut = 2'($urandom);
    io_in_2_bits_fpu_wflags = 1'($urandom);
    io_in_2_bits_fpu_typ = 2'($urandom);
    io_in_2_bits_fpu_fmt = 2'($urandom);
    io_in_2_bits_fpu_rm = 3'($urandom);
    io_in_2_bits_vpu_vill = 1'($urandom);
    io_in_2_bits_vpu_vma = 1'($urandom);
    io_in_2_bits_vpu_vta = 1'($urandom);
    io_in_2_bits_vpu_vsew = 2'($urandom);
    io_in_2_bits_vpu_vlmul = 3'($urandom);
    io_in_2_bits_vpu_specVill = 1'($urandom);
    io_in_2_bits_vpu_specVma = 1'($urandom);
    io_in_2_bits_vpu_specVta = 1'($urandom);
    io_in_2_bits_vpu_specVsew = 2'($urandom);
    io_in_2_bits_vpu_specVlmul = 3'($urandom);
    io_in_2_bits_vpu_vm = 1'($urandom);
    io_in_2_bits_vpu_vstart = 8'($urandom);
    io_in_2_bits_vpu_frm = 3'($urandom);
    io_in_2_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_2_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_2_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_2_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_2_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_2_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_2_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_2_bits_vpu_vxrm = 2'($urandom);
    io_in_2_bits_vpu_vuopIdx = 7'($urandom);
    io_in_2_bits_vpu_lastUop = 1'($urandom);
    io_in_2_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_2_bits_vpu_vl = 8'($urandom);
    io_in_2_bits_vpu_nf = 3'($urandom);
    io_in_2_bits_vpu_veew = 2'($urandom);
    io_in_2_bits_vpu_isReverse = 1'($urandom);
    io_in_2_bits_vpu_isExt = 1'($urandom);
    io_in_2_bits_vpu_isNarrow = 1'($urandom);
    io_in_2_bits_vpu_isDstMask = 1'($urandom);
    io_in_2_bits_vpu_isOpMask = 1'($urandom);
    io_in_2_bits_vpu_isMove = 1'($urandom);
    io_in_2_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_2_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_2_bits_vpu_isVleff = 1'($urandom);
    io_in_2_bits_vlsInstr = 1'($urandom);
    io_in_2_bits_wfflags = 1'($urandom);
    io_in_2_bits_isMove = 1'($urandom);
    io_in_2_bits_uopIdx = 7'($urandom);
    io_in_2_bits_isVset = 1'($urandom);
    io_in_2_bits_firstUop = 1'($urandom);
    io_in_2_bits_lastUop = 1'($urandom);
    io_in_2_bits_numUops = 7'($urandom);
    io_in_2_bits_numWB = 7'($urandom);
    io_in_2_bits_commitType = 3'($urandom);
    io_in_2_bits_psrc_0 = 8'($urandom);
    io_in_2_bits_psrc_1 = 8'($urandom);
    io_in_2_bits_psrc_2 = 8'($urandom);
    io_in_2_bits_psrc_3 = 8'($urandom);
    io_in_2_bits_psrc_4 = 8'($urandom);
    io_in_2_bits_pdest = 8'($urandom);
    io_in_2_bits_robIdx_flag = 1'($urandom);
    io_in_2_bits_robIdx_value = 8'($urandom);
    io_in_2_bits_instrSize = 3'($urandom);
    io_in_2_bits_dirtyFs = 1'($urandom);
    io_in_2_bits_dirtyVs = 1'($urandom);
    io_in_2_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_2_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_2_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_2_bits_eliminatedMove = 1'($urandom);
    io_in_2_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_2_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_2_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_2_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_2_bits_debug_sim_trig = 1'($urandom);
    io_in_2_bits_numLsElem = 5'($urandom);
    io_in_3_valid  = ($urandom % 100) < 70;
    io_out_3_ready = ($urandom % 100) < 55;
    io_in_3_bits_instr = 32'($urandom);
    io_in_3_bits_pc = 50'({$urandom, $urandom});
    io_in_3_bits_foldpc = 10'($urandom);
    io_in_3_bits_exceptionVec_0 = 1'($urandom);
    io_in_3_bits_exceptionVec_1 = 1'($urandom);
    io_in_3_bits_exceptionVec_2 = 1'($urandom);
    io_in_3_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_3_bits_exceptionVec_22 = 1'($urandom);
    io_in_3_bits_exceptionVec_23 = 1'($urandom);
    io_in_3_bits_isFetchMalAddr = 1'($urandom);
    io_in_3_bits_hasException = 1'($urandom);
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
    io_in_3_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_3_bits_srcType_0 = 4'($urandom);
    io_in_3_bits_srcType_1 = 4'($urandom);
    io_in_3_bits_srcType_2 = 4'($urandom);
    io_in_3_bits_srcType_3 = 4'($urandom);
    io_in_3_bits_srcType_4 = 4'($urandom);
    io_in_3_bits_ldest = 6'($urandom);
    io_in_3_bits_fuType = 35'({$urandom, $urandom});
    io_in_3_bits_fuOpType = 9'($urandom);
    io_in_3_bits_rfWen = 1'($urandom);
    io_in_3_bits_fpWen = 1'($urandom);
    io_in_3_bits_vecWen = 1'($urandom);
    io_in_3_bits_v0Wen = 1'($urandom);
    io_in_3_bits_vlWen = 1'($urandom);
    io_in_3_bits_isXSTrap = 1'($urandom);
    io_in_3_bits_waitForward = 1'($urandom);
    io_in_3_bits_blockBackward = 1'($urandom);
    io_in_3_bits_flushPipe = 1'($urandom);
    io_in_3_bits_canRobCompress = 1'($urandom);
    io_in_3_bits_selImm = 4'($urandom);
    io_in_3_bits_imm = 32'($urandom);
    io_in_3_bits_fpu_typeTagOut = 2'($urandom);
    io_in_3_bits_fpu_wflags = 1'($urandom);
    io_in_3_bits_fpu_typ = 2'($urandom);
    io_in_3_bits_fpu_fmt = 2'($urandom);
    io_in_3_bits_fpu_rm = 3'($urandom);
    io_in_3_bits_vpu_vill = 1'($urandom);
    io_in_3_bits_vpu_vma = 1'($urandom);
    io_in_3_bits_vpu_vta = 1'($urandom);
    io_in_3_bits_vpu_vsew = 2'($urandom);
    io_in_3_bits_vpu_vlmul = 3'($urandom);
    io_in_3_bits_vpu_specVill = 1'($urandom);
    io_in_3_bits_vpu_specVma = 1'($urandom);
    io_in_3_bits_vpu_specVta = 1'($urandom);
    io_in_3_bits_vpu_specVsew = 2'($urandom);
    io_in_3_bits_vpu_specVlmul = 3'($urandom);
    io_in_3_bits_vpu_vm = 1'($urandom);
    io_in_3_bits_vpu_vstart = 8'($urandom);
    io_in_3_bits_vpu_frm = 3'($urandom);
    io_in_3_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_3_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_3_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_3_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_3_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_3_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_3_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_3_bits_vpu_vxrm = 2'($urandom);
    io_in_3_bits_vpu_vuopIdx = 7'($urandom);
    io_in_3_bits_vpu_lastUop = 1'($urandom);
    io_in_3_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_3_bits_vpu_vl = 8'($urandom);
    io_in_3_bits_vpu_nf = 3'($urandom);
    io_in_3_bits_vpu_veew = 2'($urandom);
    io_in_3_bits_vpu_isReverse = 1'($urandom);
    io_in_3_bits_vpu_isExt = 1'($urandom);
    io_in_3_bits_vpu_isNarrow = 1'($urandom);
    io_in_3_bits_vpu_isDstMask = 1'($urandom);
    io_in_3_bits_vpu_isOpMask = 1'($urandom);
    io_in_3_bits_vpu_isMove = 1'($urandom);
    io_in_3_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_3_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_3_bits_vpu_isVleff = 1'($urandom);
    io_in_3_bits_vlsInstr = 1'($urandom);
    io_in_3_bits_wfflags = 1'($urandom);
    io_in_3_bits_isMove = 1'($urandom);
    io_in_3_bits_uopIdx = 7'($urandom);
    io_in_3_bits_isVset = 1'($urandom);
    io_in_3_bits_firstUop = 1'($urandom);
    io_in_3_bits_lastUop = 1'($urandom);
    io_in_3_bits_numUops = 7'($urandom);
    io_in_3_bits_numWB = 7'($urandom);
    io_in_3_bits_commitType = 3'($urandom);
    io_in_3_bits_psrc_0 = 8'($urandom);
    io_in_3_bits_psrc_1 = 8'($urandom);
    io_in_3_bits_psrc_2 = 8'($urandom);
    io_in_3_bits_psrc_3 = 8'($urandom);
    io_in_3_bits_psrc_4 = 8'($urandom);
    io_in_3_bits_pdest = 8'($urandom);
    io_in_3_bits_robIdx_flag = 1'($urandom);
    io_in_3_bits_robIdx_value = 8'($urandom);
    io_in_3_bits_instrSize = 3'($urandom);
    io_in_3_bits_dirtyFs = 1'($urandom);
    io_in_3_bits_dirtyVs = 1'($urandom);
    io_in_3_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_3_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_3_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_3_bits_eliminatedMove = 1'($urandom);
    io_in_3_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_3_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_3_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_3_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_3_bits_debug_sim_trig = 1'($urandom);
    io_in_3_bits_numLsElem = 5'($urandom);
    io_in_4_valid  = ($urandom % 100) < 70;
    io_out_4_ready = ($urandom % 100) < 55;
    io_in_4_bits_instr = 32'($urandom);
    io_in_4_bits_pc = 50'({$urandom, $urandom});
    io_in_4_bits_foldpc = 10'($urandom);
    io_in_4_bits_exceptionVec_0 = 1'($urandom);
    io_in_4_bits_exceptionVec_1 = 1'($urandom);
    io_in_4_bits_exceptionVec_2 = 1'($urandom);
    io_in_4_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_4_bits_exceptionVec_22 = 1'($urandom);
    io_in_4_bits_exceptionVec_23 = 1'($urandom);
    io_in_4_bits_isFetchMalAddr = 1'($urandom);
    io_in_4_bits_hasException = 1'($urandom);
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
    io_in_4_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_4_bits_srcType_0 = 4'($urandom);
    io_in_4_bits_srcType_1 = 4'($urandom);
    io_in_4_bits_srcType_2 = 4'($urandom);
    io_in_4_bits_srcType_3 = 4'($urandom);
    io_in_4_bits_srcType_4 = 4'($urandom);
    io_in_4_bits_ldest = 6'($urandom);
    io_in_4_bits_fuType = 35'({$urandom, $urandom});
    io_in_4_bits_fuOpType = 9'($urandom);
    io_in_4_bits_rfWen = 1'($urandom);
    io_in_4_bits_fpWen = 1'($urandom);
    io_in_4_bits_vecWen = 1'($urandom);
    io_in_4_bits_v0Wen = 1'($urandom);
    io_in_4_bits_vlWen = 1'($urandom);
    io_in_4_bits_isXSTrap = 1'($urandom);
    io_in_4_bits_waitForward = 1'($urandom);
    io_in_4_bits_blockBackward = 1'($urandom);
    io_in_4_bits_flushPipe = 1'($urandom);
    io_in_4_bits_canRobCompress = 1'($urandom);
    io_in_4_bits_selImm = 4'($urandom);
    io_in_4_bits_imm = 32'($urandom);
    io_in_4_bits_fpu_typeTagOut = 2'($urandom);
    io_in_4_bits_fpu_wflags = 1'($urandom);
    io_in_4_bits_fpu_typ = 2'($urandom);
    io_in_4_bits_fpu_fmt = 2'($urandom);
    io_in_4_bits_fpu_rm = 3'($urandom);
    io_in_4_bits_vpu_vill = 1'($urandom);
    io_in_4_bits_vpu_vma = 1'($urandom);
    io_in_4_bits_vpu_vta = 1'($urandom);
    io_in_4_bits_vpu_vsew = 2'($urandom);
    io_in_4_bits_vpu_vlmul = 3'($urandom);
    io_in_4_bits_vpu_specVill = 1'($urandom);
    io_in_4_bits_vpu_specVma = 1'($urandom);
    io_in_4_bits_vpu_specVta = 1'($urandom);
    io_in_4_bits_vpu_specVsew = 2'($urandom);
    io_in_4_bits_vpu_specVlmul = 3'($urandom);
    io_in_4_bits_vpu_vm = 1'($urandom);
    io_in_4_bits_vpu_vstart = 8'($urandom);
    io_in_4_bits_vpu_frm = 3'($urandom);
    io_in_4_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_4_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_4_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_4_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_4_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_4_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_4_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_4_bits_vpu_vxrm = 2'($urandom);
    io_in_4_bits_vpu_vuopIdx = 7'($urandom);
    io_in_4_bits_vpu_lastUop = 1'($urandom);
    io_in_4_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_4_bits_vpu_vl = 8'($urandom);
    io_in_4_bits_vpu_nf = 3'($urandom);
    io_in_4_bits_vpu_veew = 2'($urandom);
    io_in_4_bits_vpu_isReverse = 1'($urandom);
    io_in_4_bits_vpu_isExt = 1'($urandom);
    io_in_4_bits_vpu_isNarrow = 1'($urandom);
    io_in_4_bits_vpu_isDstMask = 1'($urandom);
    io_in_4_bits_vpu_isOpMask = 1'($urandom);
    io_in_4_bits_vpu_isMove = 1'($urandom);
    io_in_4_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_4_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_4_bits_vpu_isVleff = 1'($urandom);
    io_in_4_bits_vlsInstr = 1'($urandom);
    io_in_4_bits_wfflags = 1'($urandom);
    io_in_4_bits_isMove = 1'($urandom);
    io_in_4_bits_uopIdx = 7'($urandom);
    io_in_4_bits_isVset = 1'($urandom);
    io_in_4_bits_firstUop = 1'($urandom);
    io_in_4_bits_lastUop = 1'($urandom);
    io_in_4_bits_numUops = 7'($urandom);
    io_in_4_bits_numWB = 7'($urandom);
    io_in_4_bits_commitType = 3'($urandom);
    io_in_4_bits_psrc_0 = 8'($urandom);
    io_in_4_bits_psrc_1 = 8'($urandom);
    io_in_4_bits_psrc_2 = 8'($urandom);
    io_in_4_bits_psrc_3 = 8'($urandom);
    io_in_4_bits_psrc_4 = 8'($urandom);
    io_in_4_bits_pdest = 8'($urandom);
    io_in_4_bits_robIdx_flag = 1'($urandom);
    io_in_4_bits_robIdx_value = 8'($urandom);
    io_in_4_bits_instrSize = 3'($urandom);
    io_in_4_bits_dirtyFs = 1'($urandom);
    io_in_4_bits_dirtyVs = 1'($urandom);
    io_in_4_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_4_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_4_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_4_bits_eliminatedMove = 1'($urandom);
    io_in_4_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_4_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_4_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_4_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_4_bits_debug_sim_trig = 1'($urandom);
    io_in_4_bits_numLsElem = 5'($urandom);
    io_in_5_valid  = ($urandom % 100) < 70;
    io_out_5_ready = ($urandom % 100) < 55;
    io_in_5_bits_instr = 32'($urandom);
    io_in_5_bits_pc = 50'({$urandom, $urandom});
    io_in_5_bits_foldpc = 10'($urandom);
    io_in_5_bits_exceptionVec_0 = 1'($urandom);
    io_in_5_bits_exceptionVec_1 = 1'($urandom);
    io_in_5_bits_exceptionVec_2 = 1'($urandom);
    io_in_5_bits_exceptionVec_3 = 1'($urandom);
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
    io_in_5_bits_exceptionVec_22 = 1'($urandom);
    io_in_5_bits_exceptionVec_23 = 1'($urandom);
    io_in_5_bits_isFetchMalAddr = 1'($urandom);
    io_in_5_bits_hasException = 1'($urandom);
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
    io_in_5_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_in_5_bits_srcType_0 = 4'($urandom);
    io_in_5_bits_srcType_1 = 4'($urandom);
    io_in_5_bits_srcType_2 = 4'($urandom);
    io_in_5_bits_srcType_3 = 4'($urandom);
    io_in_5_bits_srcType_4 = 4'($urandom);
    io_in_5_bits_ldest = 6'($urandom);
    io_in_5_bits_fuType = 35'({$urandom, $urandom});
    io_in_5_bits_fuOpType = 9'($urandom);
    io_in_5_bits_rfWen = 1'($urandom);
    io_in_5_bits_fpWen = 1'($urandom);
    io_in_5_bits_vecWen = 1'($urandom);
    io_in_5_bits_v0Wen = 1'($urandom);
    io_in_5_bits_vlWen = 1'($urandom);
    io_in_5_bits_isXSTrap = 1'($urandom);
    io_in_5_bits_waitForward = 1'($urandom);
    io_in_5_bits_blockBackward = 1'($urandom);
    io_in_5_bits_flushPipe = 1'($urandom);
    io_in_5_bits_canRobCompress = 1'($urandom);
    io_in_5_bits_selImm = 4'($urandom);
    io_in_5_bits_imm = 32'($urandom);
    io_in_5_bits_fpu_typeTagOut = 2'($urandom);
    io_in_5_bits_fpu_wflags = 1'($urandom);
    io_in_5_bits_fpu_typ = 2'($urandom);
    io_in_5_bits_fpu_fmt = 2'($urandom);
    io_in_5_bits_fpu_rm = 3'($urandom);
    io_in_5_bits_vpu_vill = 1'($urandom);
    io_in_5_bits_vpu_vma = 1'($urandom);
    io_in_5_bits_vpu_vta = 1'($urandom);
    io_in_5_bits_vpu_vsew = 2'($urandom);
    io_in_5_bits_vpu_vlmul = 3'($urandom);
    io_in_5_bits_vpu_specVill = 1'($urandom);
    io_in_5_bits_vpu_specVma = 1'($urandom);
    io_in_5_bits_vpu_specVta = 1'($urandom);
    io_in_5_bits_vpu_specVsew = 2'($urandom);
    io_in_5_bits_vpu_specVlmul = 3'($urandom);
    io_in_5_bits_vpu_vm = 1'($urandom);
    io_in_5_bits_vpu_vstart = 8'($urandom);
    io_in_5_bits_vpu_frm = 3'($urandom);
    io_in_5_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_5_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_5_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_5_bits_vpu_fpu_isReduction = 1'($urandom);
    io_in_5_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_5_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_5_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_5_bits_vpu_vxrm = 2'($urandom);
    io_in_5_bits_vpu_vuopIdx = 7'($urandom);
    io_in_5_bits_vpu_lastUop = 1'($urandom);
    io_in_5_bits_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_5_bits_vpu_vl = 8'($urandom);
    io_in_5_bits_vpu_nf = 3'($urandom);
    io_in_5_bits_vpu_veew = 2'($urandom);
    io_in_5_bits_vpu_isReverse = 1'($urandom);
    io_in_5_bits_vpu_isExt = 1'($urandom);
    io_in_5_bits_vpu_isNarrow = 1'($urandom);
    io_in_5_bits_vpu_isDstMask = 1'($urandom);
    io_in_5_bits_vpu_isOpMask = 1'($urandom);
    io_in_5_bits_vpu_isMove = 1'($urandom);
    io_in_5_bits_vpu_isDependOldVd = 1'($urandom);
    io_in_5_bits_vpu_isWritePartVd = 1'($urandom);
    io_in_5_bits_vpu_isVleff = 1'($urandom);
    io_in_5_bits_vlsInstr = 1'($urandom);
    io_in_5_bits_wfflags = 1'($urandom);
    io_in_5_bits_isMove = 1'($urandom);
    io_in_5_bits_uopIdx = 7'($urandom);
    io_in_5_bits_isVset = 1'($urandom);
    io_in_5_bits_firstUop = 1'($urandom);
    io_in_5_bits_lastUop = 1'($urandom);
    io_in_5_bits_numUops = 7'($urandom);
    io_in_5_bits_numWB = 7'($urandom);
    io_in_5_bits_commitType = 3'($urandom);
    io_in_5_bits_psrc_0 = 8'($urandom);
    io_in_5_bits_psrc_1 = 8'($urandom);
    io_in_5_bits_psrc_2 = 8'($urandom);
    io_in_5_bits_psrc_3 = 8'($urandom);
    io_in_5_bits_psrc_4 = 8'($urandom);
    io_in_5_bits_pdest = 8'($urandom);
    io_in_5_bits_robIdx_flag = 1'($urandom);
    io_in_5_bits_robIdx_value = 8'($urandom);
    io_in_5_bits_instrSize = 3'($urandom);
    io_in_5_bits_dirtyFs = 1'($urandom);
    io_in_5_bits_dirtyVs = 1'($urandom);
    io_in_5_bits_traceBlockInPipe_itype = 4'($urandom);
    io_in_5_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_in_5_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_5_bits_eliminatedMove = 1'($urandom);
    io_in_5_bits_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_5_bits_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_5_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_in_5_bits_debug_fuType = 35'({$urandom, $urandom});
    io_in_5_bits_debug_sim_trig = 1'($urandom);
    io_in_5_bits_numLsElem = 5'($urandom);
  endtask

  task automatic check_all();
    `CHECK(l0,io_in_ready)
    `CHECK(l0,io_out_valid)
    `CHECK(l0,io_out_bits_instr)
    `CHECK(l0,io_out_bits_pc)
    `CHECK(l0,io_out_bits_foldpc)
    `CHECK(l0,io_out_bits_exceptionVec_0)
    `CHECK(l0,io_out_bits_exceptionVec_1)
    `CHECK(l0,io_out_bits_exceptionVec_2)
    `CHECK(l0,io_out_bits_exceptionVec_3)
    `CHECK(l0,io_out_bits_exceptionVec_4)
    `CHECK(l0,io_out_bits_exceptionVec_5)
    `CHECK(l0,io_out_bits_exceptionVec_6)
    `CHECK(l0,io_out_bits_exceptionVec_7)
    `CHECK(l0,io_out_bits_exceptionVec_8)
    `CHECK(l0,io_out_bits_exceptionVec_9)
    `CHECK(l0,io_out_bits_exceptionVec_10)
    `CHECK(l0,io_out_bits_exceptionVec_11)
    `CHECK(l0,io_out_bits_exceptionVec_12)
    `CHECK(l0,io_out_bits_exceptionVec_13)
    `CHECK(l0,io_out_bits_exceptionVec_14)
    `CHECK(l0,io_out_bits_exceptionVec_15)
    `CHECK(l0,io_out_bits_exceptionVec_16)
    `CHECK(l0,io_out_bits_exceptionVec_17)
    `CHECK(l0,io_out_bits_exceptionVec_18)
    `CHECK(l0,io_out_bits_exceptionVec_19)
    `CHECK(l0,io_out_bits_exceptionVec_20)
    `CHECK(l0,io_out_bits_exceptionVec_21)
    `CHECK(l0,io_out_bits_exceptionVec_22)
    `CHECK(l0,io_out_bits_exceptionVec_23)
    `CHECK(l0,io_out_bits_isFetchMalAddr)
    `CHECK(l0,io_out_bits_hasException)
    `CHECK(l0,io_out_bits_trigger)
    `CHECK(l0,io_out_bits_preDecodeInfo_valid)
    `CHECK(l0,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l0,io_out_bits_preDecodeInfo_brType)
    `CHECK(l0,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l0,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l0,io_out_bits_pred_taken)
    `CHECK(l0,io_out_bits_crossPageIPFFix)
    `CHECK(l0,io_out_bits_ftqPtr_flag)
    `CHECK(l0,io_out_bits_ftqPtr_value)
    `CHECK(l0,io_out_bits_ftqOffset)
    `CHECK(l0,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l0,io_out_bits_srcType_0)
    `CHECK(l0,io_out_bits_srcType_1)
    `CHECK(l0,io_out_bits_srcType_2)
    `CHECK(l0,io_out_bits_srcType_3)
    `CHECK(l0,io_out_bits_srcType_4)
    `CHECK(l0,io_out_bits_ldest)
    `CHECK(l0,io_out_bits_fuType)
    `CHECK(l0,io_out_bits_fuOpType)
    `CHECK(l0,io_out_bits_rfWen)
    `CHECK(l0,io_out_bits_fpWen)
    `CHECK(l0,io_out_bits_vecWen)
    `CHECK(l0,io_out_bits_v0Wen)
    `CHECK(l0,io_out_bits_vlWen)
    `CHECK(l0,io_out_bits_isXSTrap)
    `CHECK(l0,io_out_bits_waitForward)
    `CHECK(l0,io_out_bits_blockBackward)
    `CHECK(l0,io_out_bits_flushPipe)
    `CHECK(l0,io_out_bits_canRobCompress)
    `CHECK(l0,io_out_bits_selImm)
    `CHECK(l0,io_out_bits_imm)
    `CHECK(l0,io_out_bits_fpu_typeTagOut)
    `CHECK(l0,io_out_bits_fpu_wflags)
    `CHECK(l0,io_out_bits_fpu_typ)
    `CHECK(l0,io_out_bits_fpu_fmt)
    `CHECK(l0,io_out_bits_fpu_rm)
    `CHECK(l0,io_out_bits_vpu_vill)
    `CHECK(l0,io_out_bits_vpu_vma)
    `CHECK(l0,io_out_bits_vpu_vta)
    `CHECK(l0,io_out_bits_vpu_vsew)
    `CHECK(l0,io_out_bits_vpu_vlmul)
    `CHECK(l0,io_out_bits_vpu_specVill)
    `CHECK(l0,io_out_bits_vpu_specVma)
    `CHECK(l0,io_out_bits_vpu_specVta)
    `CHECK(l0,io_out_bits_vpu_specVsew)
    `CHECK(l0,io_out_bits_vpu_specVlmul)
    `CHECK(l0,io_out_bits_vpu_vm)
    `CHECK(l0,io_out_bits_vpu_vstart)
    `CHECK(l0,io_out_bits_vpu_frm)
    `CHECK(l0,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l0,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l0,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l0,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l0,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l0,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l0,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l0,io_out_bits_vpu_vxrm)
    `CHECK(l0,io_out_bits_vpu_vuopIdx)
    `CHECK(l0,io_out_bits_vpu_lastUop)
    `CHECK(l0,io_out_bits_vpu_vmask)
    `CHECK(l0,io_out_bits_vpu_vl)
    `CHECK(l0,io_out_bits_vpu_nf)
    `CHECK(l0,io_out_bits_vpu_veew)
    `CHECK(l0,io_out_bits_vpu_isReverse)
    `CHECK(l0,io_out_bits_vpu_isExt)
    `CHECK(l0,io_out_bits_vpu_isNarrow)
    `CHECK(l0,io_out_bits_vpu_isDstMask)
    `CHECK(l0,io_out_bits_vpu_isOpMask)
    `CHECK(l0,io_out_bits_vpu_isMove)
    `CHECK(l0,io_out_bits_vpu_isDependOldVd)
    `CHECK(l0,io_out_bits_vpu_isWritePartVd)
    `CHECK(l0,io_out_bits_vpu_isVleff)
    `CHECK(l0,io_out_bits_vlsInstr)
    `CHECK(l0,io_out_bits_wfflags)
    `CHECK(l0,io_out_bits_isMove)
    `CHECK(l0,io_out_bits_uopIdx)
    `CHECK(l0,io_out_bits_isVset)
    `CHECK(l0,io_out_bits_firstUop)
    `CHECK(l0,io_out_bits_lastUop)
    `CHECK(l0,io_out_bits_numUops)
    `CHECK(l0,io_out_bits_numWB)
    `CHECK(l0,io_out_bits_commitType)
    `CHECK(l0,io_out_bits_psrc_0)
    `CHECK(l0,io_out_bits_psrc_1)
    `CHECK(l0,io_out_bits_psrc_2)
    `CHECK(l0,io_out_bits_psrc_3)
    `CHECK(l0,io_out_bits_psrc_4)
    `CHECK(l0,io_out_bits_pdest)
    `CHECK(l0,io_out_bits_robIdx_flag)
    `CHECK(l0,io_out_bits_robIdx_value)
    `CHECK(l0,io_out_bits_instrSize)
    `CHECK(l0,io_out_bits_dirtyFs)
    `CHECK(l0,io_out_bits_dirtyVs)
    `CHECK(l0,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l0,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l0,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l0,io_out_bits_eliminatedMove)
    `CHECK(l0,io_out_bits_snapshot)
    `CHECK(l0,io_out_bits_debugInfo_renameTime)
    `CHECK(l0,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l0,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l0,io_out_bits_debug_fuType)
    `CHECK(l0,io_out_bits_debug_sim_trig)
    `CHECK(l0,io_out_bits_numLsElem)
    `CHECK(l1,io_in_ready)
    `CHECK(l1,io_out_valid)
    `CHECK(l1,io_out_bits_instr)
    `CHECK(l1,io_out_bits_pc)
    `CHECK(l1,io_out_bits_foldpc)
    `CHECK(l1,io_out_bits_exceptionVec_0)
    `CHECK(l1,io_out_bits_exceptionVec_1)
    `CHECK(l1,io_out_bits_exceptionVec_2)
    `CHECK(l1,io_out_bits_exceptionVec_3)
    `CHECK(l1,io_out_bits_exceptionVec_4)
    `CHECK(l1,io_out_bits_exceptionVec_5)
    `CHECK(l1,io_out_bits_exceptionVec_6)
    `CHECK(l1,io_out_bits_exceptionVec_7)
    `CHECK(l1,io_out_bits_exceptionVec_8)
    `CHECK(l1,io_out_bits_exceptionVec_9)
    `CHECK(l1,io_out_bits_exceptionVec_10)
    `CHECK(l1,io_out_bits_exceptionVec_11)
    `CHECK(l1,io_out_bits_exceptionVec_12)
    `CHECK(l1,io_out_bits_exceptionVec_13)
    `CHECK(l1,io_out_bits_exceptionVec_14)
    `CHECK(l1,io_out_bits_exceptionVec_15)
    `CHECK(l1,io_out_bits_exceptionVec_16)
    `CHECK(l1,io_out_bits_exceptionVec_17)
    `CHECK(l1,io_out_bits_exceptionVec_18)
    `CHECK(l1,io_out_bits_exceptionVec_19)
    `CHECK(l1,io_out_bits_exceptionVec_20)
    `CHECK(l1,io_out_bits_exceptionVec_21)
    `CHECK(l1,io_out_bits_exceptionVec_22)
    `CHECK(l1,io_out_bits_exceptionVec_23)
    `CHECK(l1,io_out_bits_isFetchMalAddr)
    `CHECK(l1,io_out_bits_hasException)
    `CHECK(l1,io_out_bits_trigger)
    `CHECK(l1,io_out_bits_preDecodeInfo_valid)
    `CHECK(l1,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l1,io_out_bits_preDecodeInfo_brType)
    `CHECK(l1,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l1,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l1,io_out_bits_pred_taken)
    `CHECK(l1,io_out_bits_crossPageIPFFix)
    `CHECK(l1,io_out_bits_ftqPtr_flag)
    `CHECK(l1,io_out_bits_ftqPtr_value)
    `CHECK(l1,io_out_bits_ftqOffset)
    `CHECK(l1,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l1,io_out_bits_srcType_0)
    `CHECK(l1,io_out_bits_srcType_1)
    `CHECK(l1,io_out_bits_srcType_2)
    `CHECK(l1,io_out_bits_srcType_3)
    `CHECK(l1,io_out_bits_srcType_4)
    `CHECK(l1,io_out_bits_ldest)
    `CHECK(l1,io_out_bits_fuType)
    `CHECK(l1,io_out_bits_fuOpType)
    `CHECK(l1,io_out_bits_rfWen)
    `CHECK(l1,io_out_bits_fpWen)
    `CHECK(l1,io_out_bits_vecWen)
    `CHECK(l1,io_out_bits_v0Wen)
    `CHECK(l1,io_out_bits_vlWen)
    `CHECK(l1,io_out_bits_isXSTrap)
    `CHECK(l1,io_out_bits_waitForward)
    `CHECK(l1,io_out_bits_blockBackward)
    `CHECK(l1,io_out_bits_flushPipe)
    `CHECK(l1,io_out_bits_canRobCompress)
    `CHECK(l1,io_out_bits_selImm)
    `CHECK(l1,io_out_bits_imm)
    `CHECK(l1,io_out_bits_fpu_typeTagOut)
    `CHECK(l1,io_out_bits_fpu_wflags)
    `CHECK(l1,io_out_bits_fpu_typ)
    `CHECK(l1,io_out_bits_fpu_fmt)
    `CHECK(l1,io_out_bits_fpu_rm)
    `CHECK(l1,io_out_bits_vpu_vill)
    `CHECK(l1,io_out_bits_vpu_vma)
    `CHECK(l1,io_out_bits_vpu_vta)
    `CHECK(l1,io_out_bits_vpu_vsew)
    `CHECK(l1,io_out_bits_vpu_vlmul)
    `CHECK(l1,io_out_bits_vpu_specVill)
    `CHECK(l1,io_out_bits_vpu_specVma)
    `CHECK(l1,io_out_bits_vpu_specVta)
    `CHECK(l1,io_out_bits_vpu_specVsew)
    `CHECK(l1,io_out_bits_vpu_specVlmul)
    `CHECK(l1,io_out_bits_vpu_vm)
    `CHECK(l1,io_out_bits_vpu_vstart)
    `CHECK(l1,io_out_bits_vpu_frm)
    `CHECK(l1,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l1,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l1,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l1,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l1,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l1,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l1,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l1,io_out_bits_vpu_vxrm)
    `CHECK(l1,io_out_bits_vpu_vuopIdx)
    `CHECK(l1,io_out_bits_vpu_lastUop)
    `CHECK(l1,io_out_bits_vpu_vmask)
    `CHECK(l1,io_out_bits_vpu_vl)
    `CHECK(l1,io_out_bits_vpu_nf)
    `CHECK(l1,io_out_bits_vpu_veew)
    `CHECK(l1,io_out_bits_vpu_isReverse)
    `CHECK(l1,io_out_bits_vpu_isExt)
    `CHECK(l1,io_out_bits_vpu_isNarrow)
    `CHECK(l1,io_out_bits_vpu_isDstMask)
    `CHECK(l1,io_out_bits_vpu_isOpMask)
    `CHECK(l1,io_out_bits_vpu_isMove)
    `CHECK(l1,io_out_bits_vpu_isDependOldVd)
    `CHECK(l1,io_out_bits_vpu_isWritePartVd)
    `CHECK(l1,io_out_bits_vpu_isVleff)
    `CHECK(l1,io_out_bits_vlsInstr)
    `CHECK(l1,io_out_bits_wfflags)
    `CHECK(l1,io_out_bits_isMove)
    `CHECK(l1,io_out_bits_uopIdx)
    `CHECK(l1,io_out_bits_isVset)
    `CHECK(l1,io_out_bits_firstUop)
    `CHECK(l1,io_out_bits_lastUop)
    `CHECK(l1,io_out_bits_numUops)
    `CHECK(l1,io_out_bits_numWB)
    `CHECK(l1,io_out_bits_commitType)
    `CHECK(l1,io_out_bits_psrc_0)
    `CHECK(l1,io_out_bits_psrc_1)
    `CHECK(l1,io_out_bits_psrc_2)
    `CHECK(l1,io_out_bits_psrc_3)
    `CHECK(l1,io_out_bits_psrc_4)
    `CHECK(l1,io_out_bits_pdest)
    `CHECK(l1,io_out_bits_robIdx_flag)
    `CHECK(l1,io_out_bits_robIdx_value)
    `CHECK(l1,io_out_bits_instrSize)
    `CHECK(l1,io_out_bits_dirtyFs)
    `CHECK(l1,io_out_bits_dirtyVs)
    `CHECK(l1,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l1,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l1,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l1,io_out_bits_eliminatedMove)
    `CHECK(l1,io_out_bits_debugInfo_renameTime)
    `CHECK(l1,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l1,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l1,io_out_bits_debug_fuType)
    `CHECK(l1,io_out_bits_debug_sim_trig)
    `CHECK(l1,io_out_bits_numLsElem)
    `CHECK(l2,io_in_ready)
    `CHECK(l2,io_out_valid)
    `CHECK(l2,io_out_bits_instr)
    `CHECK(l2,io_out_bits_pc)
    `CHECK(l2,io_out_bits_foldpc)
    `CHECK(l2,io_out_bits_exceptionVec_0)
    `CHECK(l2,io_out_bits_exceptionVec_1)
    `CHECK(l2,io_out_bits_exceptionVec_2)
    `CHECK(l2,io_out_bits_exceptionVec_3)
    `CHECK(l2,io_out_bits_exceptionVec_4)
    `CHECK(l2,io_out_bits_exceptionVec_5)
    `CHECK(l2,io_out_bits_exceptionVec_6)
    `CHECK(l2,io_out_bits_exceptionVec_7)
    `CHECK(l2,io_out_bits_exceptionVec_8)
    `CHECK(l2,io_out_bits_exceptionVec_9)
    `CHECK(l2,io_out_bits_exceptionVec_10)
    `CHECK(l2,io_out_bits_exceptionVec_11)
    `CHECK(l2,io_out_bits_exceptionVec_12)
    `CHECK(l2,io_out_bits_exceptionVec_13)
    `CHECK(l2,io_out_bits_exceptionVec_14)
    `CHECK(l2,io_out_bits_exceptionVec_15)
    `CHECK(l2,io_out_bits_exceptionVec_16)
    `CHECK(l2,io_out_bits_exceptionVec_17)
    `CHECK(l2,io_out_bits_exceptionVec_18)
    `CHECK(l2,io_out_bits_exceptionVec_19)
    `CHECK(l2,io_out_bits_exceptionVec_20)
    `CHECK(l2,io_out_bits_exceptionVec_21)
    `CHECK(l2,io_out_bits_exceptionVec_22)
    `CHECK(l2,io_out_bits_exceptionVec_23)
    `CHECK(l2,io_out_bits_isFetchMalAddr)
    `CHECK(l2,io_out_bits_hasException)
    `CHECK(l2,io_out_bits_trigger)
    `CHECK(l2,io_out_bits_preDecodeInfo_valid)
    `CHECK(l2,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l2,io_out_bits_preDecodeInfo_brType)
    `CHECK(l2,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l2,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l2,io_out_bits_pred_taken)
    `CHECK(l2,io_out_bits_crossPageIPFFix)
    `CHECK(l2,io_out_bits_ftqPtr_flag)
    `CHECK(l2,io_out_bits_ftqPtr_value)
    `CHECK(l2,io_out_bits_ftqOffset)
    `CHECK(l2,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l2,io_out_bits_srcType_0)
    `CHECK(l2,io_out_bits_srcType_1)
    `CHECK(l2,io_out_bits_srcType_2)
    `CHECK(l2,io_out_bits_srcType_3)
    `CHECK(l2,io_out_bits_srcType_4)
    `CHECK(l2,io_out_bits_ldest)
    `CHECK(l2,io_out_bits_fuType)
    `CHECK(l2,io_out_bits_fuOpType)
    `CHECK(l2,io_out_bits_rfWen)
    `CHECK(l2,io_out_bits_fpWen)
    `CHECK(l2,io_out_bits_vecWen)
    `CHECK(l2,io_out_bits_v0Wen)
    `CHECK(l2,io_out_bits_vlWen)
    `CHECK(l2,io_out_bits_isXSTrap)
    `CHECK(l2,io_out_bits_waitForward)
    `CHECK(l2,io_out_bits_blockBackward)
    `CHECK(l2,io_out_bits_flushPipe)
    `CHECK(l2,io_out_bits_canRobCompress)
    `CHECK(l2,io_out_bits_selImm)
    `CHECK(l2,io_out_bits_imm)
    `CHECK(l2,io_out_bits_fpu_typeTagOut)
    `CHECK(l2,io_out_bits_fpu_wflags)
    `CHECK(l2,io_out_bits_fpu_typ)
    `CHECK(l2,io_out_bits_fpu_fmt)
    `CHECK(l2,io_out_bits_fpu_rm)
    `CHECK(l2,io_out_bits_vpu_vill)
    `CHECK(l2,io_out_bits_vpu_vma)
    `CHECK(l2,io_out_bits_vpu_vta)
    `CHECK(l2,io_out_bits_vpu_vsew)
    `CHECK(l2,io_out_bits_vpu_vlmul)
    `CHECK(l2,io_out_bits_vpu_specVill)
    `CHECK(l2,io_out_bits_vpu_specVma)
    `CHECK(l2,io_out_bits_vpu_specVta)
    `CHECK(l2,io_out_bits_vpu_specVsew)
    `CHECK(l2,io_out_bits_vpu_specVlmul)
    `CHECK(l2,io_out_bits_vpu_vm)
    `CHECK(l2,io_out_bits_vpu_vstart)
    `CHECK(l2,io_out_bits_vpu_frm)
    `CHECK(l2,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l2,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l2,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l2,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l2,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l2,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l2,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l2,io_out_bits_vpu_vxrm)
    `CHECK(l2,io_out_bits_vpu_vuopIdx)
    `CHECK(l2,io_out_bits_vpu_lastUop)
    `CHECK(l2,io_out_bits_vpu_vmask)
    `CHECK(l2,io_out_bits_vpu_vl)
    `CHECK(l2,io_out_bits_vpu_nf)
    `CHECK(l2,io_out_bits_vpu_veew)
    `CHECK(l2,io_out_bits_vpu_isReverse)
    `CHECK(l2,io_out_bits_vpu_isExt)
    `CHECK(l2,io_out_bits_vpu_isNarrow)
    `CHECK(l2,io_out_bits_vpu_isDstMask)
    `CHECK(l2,io_out_bits_vpu_isOpMask)
    `CHECK(l2,io_out_bits_vpu_isMove)
    `CHECK(l2,io_out_bits_vpu_isDependOldVd)
    `CHECK(l2,io_out_bits_vpu_isWritePartVd)
    `CHECK(l2,io_out_bits_vpu_isVleff)
    `CHECK(l2,io_out_bits_vlsInstr)
    `CHECK(l2,io_out_bits_wfflags)
    `CHECK(l2,io_out_bits_isMove)
    `CHECK(l2,io_out_bits_uopIdx)
    `CHECK(l2,io_out_bits_isVset)
    `CHECK(l2,io_out_bits_firstUop)
    `CHECK(l2,io_out_bits_lastUop)
    `CHECK(l2,io_out_bits_numUops)
    `CHECK(l2,io_out_bits_numWB)
    `CHECK(l2,io_out_bits_commitType)
    `CHECK(l2,io_out_bits_psrc_0)
    `CHECK(l2,io_out_bits_psrc_1)
    `CHECK(l2,io_out_bits_psrc_2)
    `CHECK(l2,io_out_bits_psrc_3)
    `CHECK(l2,io_out_bits_psrc_4)
    `CHECK(l2,io_out_bits_pdest)
    `CHECK(l2,io_out_bits_robIdx_flag)
    `CHECK(l2,io_out_bits_robIdx_value)
    `CHECK(l2,io_out_bits_instrSize)
    `CHECK(l2,io_out_bits_dirtyFs)
    `CHECK(l2,io_out_bits_dirtyVs)
    `CHECK(l2,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l2,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l2,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l2,io_out_bits_eliminatedMove)
    `CHECK(l2,io_out_bits_debugInfo_renameTime)
    `CHECK(l2,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l2,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l2,io_out_bits_debug_fuType)
    `CHECK(l2,io_out_bits_debug_sim_trig)
    `CHECK(l2,io_out_bits_numLsElem)
    `CHECK(l3,io_in_ready)
    `CHECK(l3,io_out_valid)
    `CHECK(l3,io_out_bits_instr)
    `CHECK(l3,io_out_bits_pc)
    `CHECK(l3,io_out_bits_foldpc)
    `CHECK(l3,io_out_bits_exceptionVec_0)
    `CHECK(l3,io_out_bits_exceptionVec_1)
    `CHECK(l3,io_out_bits_exceptionVec_2)
    `CHECK(l3,io_out_bits_exceptionVec_3)
    `CHECK(l3,io_out_bits_exceptionVec_4)
    `CHECK(l3,io_out_bits_exceptionVec_5)
    `CHECK(l3,io_out_bits_exceptionVec_6)
    `CHECK(l3,io_out_bits_exceptionVec_7)
    `CHECK(l3,io_out_bits_exceptionVec_8)
    `CHECK(l3,io_out_bits_exceptionVec_9)
    `CHECK(l3,io_out_bits_exceptionVec_10)
    `CHECK(l3,io_out_bits_exceptionVec_11)
    `CHECK(l3,io_out_bits_exceptionVec_12)
    `CHECK(l3,io_out_bits_exceptionVec_13)
    `CHECK(l3,io_out_bits_exceptionVec_14)
    `CHECK(l3,io_out_bits_exceptionVec_15)
    `CHECK(l3,io_out_bits_exceptionVec_16)
    `CHECK(l3,io_out_bits_exceptionVec_17)
    `CHECK(l3,io_out_bits_exceptionVec_18)
    `CHECK(l3,io_out_bits_exceptionVec_19)
    `CHECK(l3,io_out_bits_exceptionVec_20)
    `CHECK(l3,io_out_bits_exceptionVec_21)
    `CHECK(l3,io_out_bits_exceptionVec_22)
    `CHECK(l3,io_out_bits_exceptionVec_23)
    `CHECK(l3,io_out_bits_isFetchMalAddr)
    `CHECK(l3,io_out_bits_hasException)
    `CHECK(l3,io_out_bits_trigger)
    `CHECK(l3,io_out_bits_preDecodeInfo_valid)
    `CHECK(l3,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l3,io_out_bits_preDecodeInfo_brType)
    `CHECK(l3,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l3,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l3,io_out_bits_pred_taken)
    `CHECK(l3,io_out_bits_crossPageIPFFix)
    `CHECK(l3,io_out_bits_ftqPtr_flag)
    `CHECK(l3,io_out_bits_ftqPtr_value)
    `CHECK(l3,io_out_bits_ftqOffset)
    `CHECK(l3,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l3,io_out_bits_srcType_0)
    `CHECK(l3,io_out_bits_srcType_1)
    `CHECK(l3,io_out_bits_srcType_2)
    `CHECK(l3,io_out_bits_srcType_3)
    `CHECK(l3,io_out_bits_srcType_4)
    `CHECK(l3,io_out_bits_ldest)
    `CHECK(l3,io_out_bits_fuType)
    `CHECK(l3,io_out_bits_fuOpType)
    `CHECK(l3,io_out_bits_rfWen)
    `CHECK(l3,io_out_bits_fpWen)
    `CHECK(l3,io_out_bits_vecWen)
    `CHECK(l3,io_out_bits_v0Wen)
    `CHECK(l3,io_out_bits_vlWen)
    `CHECK(l3,io_out_bits_isXSTrap)
    `CHECK(l3,io_out_bits_waitForward)
    `CHECK(l3,io_out_bits_blockBackward)
    `CHECK(l3,io_out_bits_flushPipe)
    `CHECK(l3,io_out_bits_canRobCompress)
    `CHECK(l3,io_out_bits_selImm)
    `CHECK(l3,io_out_bits_imm)
    `CHECK(l3,io_out_bits_fpu_typeTagOut)
    `CHECK(l3,io_out_bits_fpu_wflags)
    `CHECK(l3,io_out_bits_fpu_typ)
    `CHECK(l3,io_out_bits_fpu_fmt)
    `CHECK(l3,io_out_bits_fpu_rm)
    `CHECK(l3,io_out_bits_vpu_vill)
    `CHECK(l3,io_out_bits_vpu_vma)
    `CHECK(l3,io_out_bits_vpu_vta)
    `CHECK(l3,io_out_bits_vpu_vsew)
    `CHECK(l3,io_out_bits_vpu_vlmul)
    `CHECK(l3,io_out_bits_vpu_specVill)
    `CHECK(l3,io_out_bits_vpu_specVma)
    `CHECK(l3,io_out_bits_vpu_specVta)
    `CHECK(l3,io_out_bits_vpu_specVsew)
    `CHECK(l3,io_out_bits_vpu_specVlmul)
    `CHECK(l3,io_out_bits_vpu_vm)
    `CHECK(l3,io_out_bits_vpu_vstart)
    `CHECK(l3,io_out_bits_vpu_frm)
    `CHECK(l3,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l3,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l3,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l3,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l3,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l3,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l3,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l3,io_out_bits_vpu_vxrm)
    `CHECK(l3,io_out_bits_vpu_vuopIdx)
    `CHECK(l3,io_out_bits_vpu_lastUop)
    `CHECK(l3,io_out_bits_vpu_vmask)
    `CHECK(l3,io_out_bits_vpu_vl)
    `CHECK(l3,io_out_bits_vpu_nf)
    `CHECK(l3,io_out_bits_vpu_veew)
    `CHECK(l3,io_out_bits_vpu_isReverse)
    `CHECK(l3,io_out_bits_vpu_isExt)
    `CHECK(l3,io_out_bits_vpu_isNarrow)
    `CHECK(l3,io_out_bits_vpu_isDstMask)
    `CHECK(l3,io_out_bits_vpu_isOpMask)
    `CHECK(l3,io_out_bits_vpu_isMove)
    `CHECK(l3,io_out_bits_vpu_isDependOldVd)
    `CHECK(l3,io_out_bits_vpu_isWritePartVd)
    `CHECK(l3,io_out_bits_vpu_isVleff)
    `CHECK(l3,io_out_bits_vlsInstr)
    `CHECK(l3,io_out_bits_wfflags)
    `CHECK(l3,io_out_bits_isMove)
    `CHECK(l3,io_out_bits_uopIdx)
    `CHECK(l3,io_out_bits_isVset)
    `CHECK(l3,io_out_bits_firstUop)
    `CHECK(l3,io_out_bits_lastUop)
    `CHECK(l3,io_out_bits_numUops)
    `CHECK(l3,io_out_bits_numWB)
    `CHECK(l3,io_out_bits_commitType)
    `CHECK(l3,io_out_bits_psrc_0)
    `CHECK(l3,io_out_bits_psrc_1)
    `CHECK(l3,io_out_bits_psrc_2)
    `CHECK(l3,io_out_bits_psrc_3)
    `CHECK(l3,io_out_bits_psrc_4)
    `CHECK(l3,io_out_bits_pdest)
    `CHECK(l3,io_out_bits_robIdx_flag)
    `CHECK(l3,io_out_bits_robIdx_value)
    `CHECK(l3,io_out_bits_instrSize)
    `CHECK(l3,io_out_bits_dirtyFs)
    `CHECK(l3,io_out_bits_dirtyVs)
    `CHECK(l3,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l3,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l3,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l3,io_out_bits_eliminatedMove)
    `CHECK(l3,io_out_bits_debugInfo_renameTime)
    `CHECK(l3,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l3,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l3,io_out_bits_debug_fuType)
    `CHECK(l3,io_out_bits_debug_sim_trig)
    `CHECK(l3,io_out_bits_numLsElem)
    `CHECK(l4,io_in_ready)
    `CHECK(l4,io_out_valid)
    `CHECK(l4,io_out_bits_instr)
    `CHECK(l4,io_out_bits_pc)
    `CHECK(l4,io_out_bits_foldpc)
    `CHECK(l4,io_out_bits_exceptionVec_0)
    `CHECK(l4,io_out_bits_exceptionVec_1)
    `CHECK(l4,io_out_bits_exceptionVec_2)
    `CHECK(l4,io_out_bits_exceptionVec_3)
    `CHECK(l4,io_out_bits_exceptionVec_4)
    `CHECK(l4,io_out_bits_exceptionVec_5)
    `CHECK(l4,io_out_bits_exceptionVec_6)
    `CHECK(l4,io_out_bits_exceptionVec_7)
    `CHECK(l4,io_out_bits_exceptionVec_8)
    `CHECK(l4,io_out_bits_exceptionVec_9)
    `CHECK(l4,io_out_bits_exceptionVec_10)
    `CHECK(l4,io_out_bits_exceptionVec_11)
    `CHECK(l4,io_out_bits_exceptionVec_12)
    `CHECK(l4,io_out_bits_exceptionVec_13)
    `CHECK(l4,io_out_bits_exceptionVec_14)
    `CHECK(l4,io_out_bits_exceptionVec_15)
    `CHECK(l4,io_out_bits_exceptionVec_16)
    `CHECK(l4,io_out_bits_exceptionVec_17)
    `CHECK(l4,io_out_bits_exceptionVec_18)
    `CHECK(l4,io_out_bits_exceptionVec_19)
    `CHECK(l4,io_out_bits_exceptionVec_20)
    `CHECK(l4,io_out_bits_exceptionVec_21)
    `CHECK(l4,io_out_bits_exceptionVec_22)
    `CHECK(l4,io_out_bits_exceptionVec_23)
    `CHECK(l4,io_out_bits_isFetchMalAddr)
    `CHECK(l4,io_out_bits_hasException)
    `CHECK(l4,io_out_bits_trigger)
    `CHECK(l4,io_out_bits_preDecodeInfo_valid)
    `CHECK(l4,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l4,io_out_bits_preDecodeInfo_brType)
    `CHECK(l4,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l4,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l4,io_out_bits_pred_taken)
    `CHECK(l4,io_out_bits_crossPageIPFFix)
    `CHECK(l4,io_out_bits_ftqPtr_flag)
    `CHECK(l4,io_out_bits_ftqPtr_value)
    `CHECK(l4,io_out_bits_ftqOffset)
    `CHECK(l4,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l4,io_out_bits_srcType_0)
    `CHECK(l4,io_out_bits_srcType_1)
    `CHECK(l4,io_out_bits_srcType_2)
    `CHECK(l4,io_out_bits_srcType_3)
    `CHECK(l4,io_out_bits_srcType_4)
    `CHECK(l4,io_out_bits_ldest)
    `CHECK(l4,io_out_bits_fuType)
    `CHECK(l4,io_out_bits_fuOpType)
    `CHECK(l4,io_out_bits_rfWen)
    `CHECK(l4,io_out_bits_fpWen)
    `CHECK(l4,io_out_bits_vecWen)
    `CHECK(l4,io_out_bits_v0Wen)
    `CHECK(l4,io_out_bits_vlWen)
    `CHECK(l4,io_out_bits_isXSTrap)
    `CHECK(l4,io_out_bits_waitForward)
    `CHECK(l4,io_out_bits_blockBackward)
    `CHECK(l4,io_out_bits_flushPipe)
    `CHECK(l4,io_out_bits_canRobCompress)
    `CHECK(l4,io_out_bits_selImm)
    `CHECK(l4,io_out_bits_imm)
    `CHECK(l4,io_out_bits_fpu_typeTagOut)
    `CHECK(l4,io_out_bits_fpu_wflags)
    `CHECK(l4,io_out_bits_fpu_typ)
    `CHECK(l4,io_out_bits_fpu_fmt)
    `CHECK(l4,io_out_bits_fpu_rm)
    `CHECK(l4,io_out_bits_vpu_vill)
    `CHECK(l4,io_out_bits_vpu_vma)
    `CHECK(l4,io_out_bits_vpu_vta)
    `CHECK(l4,io_out_bits_vpu_vsew)
    `CHECK(l4,io_out_bits_vpu_vlmul)
    `CHECK(l4,io_out_bits_vpu_specVill)
    `CHECK(l4,io_out_bits_vpu_specVma)
    `CHECK(l4,io_out_bits_vpu_specVta)
    `CHECK(l4,io_out_bits_vpu_specVsew)
    `CHECK(l4,io_out_bits_vpu_specVlmul)
    `CHECK(l4,io_out_bits_vpu_vm)
    `CHECK(l4,io_out_bits_vpu_vstart)
    `CHECK(l4,io_out_bits_vpu_frm)
    `CHECK(l4,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l4,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l4,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l4,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l4,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l4,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l4,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l4,io_out_bits_vpu_vxrm)
    `CHECK(l4,io_out_bits_vpu_vuopIdx)
    `CHECK(l4,io_out_bits_vpu_lastUop)
    `CHECK(l4,io_out_bits_vpu_vmask)
    `CHECK(l4,io_out_bits_vpu_vl)
    `CHECK(l4,io_out_bits_vpu_nf)
    `CHECK(l4,io_out_bits_vpu_veew)
    `CHECK(l4,io_out_bits_vpu_isReverse)
    `CHECK(l4,io_out_bits_vpu_isExt)
    `CHECK(l4,io_out_bits_vpu_isNarrow)
    `CHECK(l4,io_out_bits_vpu_isDstMask)
    `CHECK(l4,io_out_bits_vpu_isOpMask)
    `CHECK(l4,io_out_bits_vpu_isMove)
    `CHECK(l4,io_out_bits_vpu_isDependOldVd)
    `CHECK(l4,io_out_bits_vpu_isWritePartVd)
    `CHECK(l4,io_out_bits_vpu_isVleff)
    `CHECK(l4,io_out_bits_vlsInstr)
    `CHECK(l4,io_out_bits_wfflags)
    `CHECK(l4,io_out_bits_isMove)
    `CHECK(l4,io_out_bits_uopIdx)
    `CHECK(l4,io_out_bits_isVset)
    `CHECK(l4,io_out_bits_firstUop)
    `CHECK(l4,io_out_bits_lastUop)
    `CHECK(l4,io_out_bits_numUops)
    `CHECK(l4,io_out_bits_numWB)
    `CHECK(l4,io_out_bits_commitType)
    `CHECK(l4,io_out_bits_psrc_0)
    `CHECK(l4,io_out_bits_psrc_1)
    `CHECK(l4,io_out_bits_psrc_2)
    `CHECK(l4,io_out_bits_psrc_3)
    `CHECK(l4,io_out_bits_psrc_4)
    `CHECK(l4,io_out_bits_pdest)
    `CHECK(l4,io_out_bits_robIdx_flag)
    `CHECK(l4,io_out_bits_robIdx_value)
    `CHECK(l4,io_out_bits_instrSize)
    `CHECK(l4,io_out_bits_dirtyFs)
    `CHECK(l4,io_out_bits_dirtyVs)
    `CHECK(l4,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l4,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l4,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l4,io_out_bits_eliminatedMove)
    `CHECK(l4,io_out_bits_debugInfo_renameTime)
    `CHECK(l4,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l4,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l4,io_out_bits_debug_fuType)
    `CHECK(l4,io_out_bits_debug_sim_trig)
    `CHECK(l4,io_out_bits_numLsElem)
    `CHECK(l5,io_in_ready)
    `CHECK(l5,io_out_valid)
    `CHECK(l5,io_out_bits_instr)
    `CHECK(l5,io_out_bits_pc)
    `CHECK(l5,io_out_bits_foldpc)
    `CHECK(l5,io_out_bits_exceptionVec_0)
    `CHECK(l5,io_out_bits_exceptionVec_1)
    `CHECK(l5,io_out_bits_exceptionVec_2)
    `CHECK(l5,io_out_bits_exceptionVec_3)
    `CHECK(l5,io_out_bits_exceptionVec_4)
    `CHECK(l5,io_out_bits_exceptionVec_5)
    `CHECK(l5,io_out_bits_exceptionVec_6)
    `CHECK(l5,io_out_bits_exceptionVec_7)
    `CHECK(l5,io_out_bits_exceptionVec_8)
    `CHECK(l5,io_out_bits_exceptionVec_9)
    `CHECK(l5,io_out_bits_exceptionVec_10)
    `CHECK(l5,io_out_bits_exceptionVec_11)
    `CHECK(l5,io_out_bits_exceptionVec_12)
    `CHECK(l5,io_out_bits_exceptionVec_13)
    `CHECK(l5,io_out_bits_exceptionVec_14)
    `CHECK(l5,io_out_bits_exceptionVec_15)
    `CHECK(l5,io_out_bits_exceptionVec_16)
    `CHECK(l5,io_out_bits_exceptionVec_17)
    `CHECK(l5,io_out_bits_exceptionVec_18)
    `CHECK(l5,io_out_bits_exceptionVec_19)
    `CHECK(l5,io_out_bits_exceptionVec_20)
    `CHECK(l5,io_out_bits_exceptionVec_21)
    `CHECK(l5,io_out_bits_exceptionVec_22)
    `CHECK(l5,io_out_bits_exceptionVec_23)
    `CHECK(l5,io_out_bits_isFetchMalAddr)
    `CHECK(l5,io_out_bits_hasException)
    `CHECK(l5,io_out_bits_trigger)
    `CHECK(l5,io_out_bits_preDecodeInfo_valid)
    `CHECK(l5,io_out_bits_preDecodeInfo_isRVC)
    `CHECK(l5,io_out_bits_preDecodeInfo_brType)
    `CHECK(l5,io_out_bits_preDecodeInfo_isCall)
    `CHECK(l5,io_out_bits_preDecodeInfo_isRet)
    `CHECK(l5,io_out_bits_pred_taken)
    `CHECK(l5,io_out_bits_crossPageIPFFix)
    `CHECK(l5,io_out_bits_ftqPtr_flag)
    `CHECK(l5,io_out_bits_ftqPtr_value)
    `CHECK(l5,io_out_bits_ftqOffset)
    `CHECK(l5,io_out_bits_satpFlushFirstFetchFault)
    `CHECK(l5,io_out_bits_srcType_0)
    `CHECK(l5,io_out_bits_srcType_1)
    `CHECK(l5,io_out_bits_srcType_2)
    `CHECK(l5,io_out_bits_srcType_3)
    `CHECK(l5,io_out_bits_srcType_4)
    `CHECK(l5,io_out_bits_ldest)
    `CHECK(l5,io_out_bits_fuType)
    `CHECK(l5,io_out_bits_fuOpType)
    `CHECK(l5,io_out_bits_rfWen)
    `CHECK(l5,io_out_bits_fpWen)
    `CHECK(l5,io_out_bits_vecWen)
    `CHECK(l5,io_out_bits_v0Wen)
    `CHECK(l5,io_out_bits_vlWen)
    `CHECK(l5,io_out_bits_isXSTrap)
    `CHECK(l5,io_out_bits_waitForward)
    `CHECK(l5,io_out_bits_blockBackward)
    `CHECK(l5,io_out_bits_flushPipe)
    `CHECK(l5,io_out_bits_canRobCompress)
    `CHECK(l5,io_out_bits_selImm)
    `CHECK(l5,io_out_bits_imm)
    `CHECK(l5,io_out_bits_fpu_typeTagOut)
    `CHECK(l5,io_out_bits_fpu_wflags)
    `CHECK(l5,io_out_bits_fpu_typ)
    `CHECK(l5,io_out_bits_fpu_fmt)
    `CHECK(l5,io_out_bits_fpu_rm)
    `CHECK(l5,io_out_bits_vpu_vill)
    `CHECK(l5,io_out_bits_vpu_vma)
    `CHECK(l5,io_out_bits_vpu_vta)
    `CHECK(l5,io_out_bits_vpu_vsew)
    `CHECK(l5,io_out_bits_vpu_vlmul)
    `CHECK(l5,io_out_bits_vpu_specVill)
    `CHECK(l5,io_out_bits_vpu_specVma)
    `CHECK(l5,io_out_bits_vpu_specVta)
    `CHECK(l5,io_out_bits_vpu_specVsew)
    `CHECK(l5,io_out_bits_vpu_specVlmul)
    `CHECK(l5,io_out_bits_vpu_vm)
    `CHECK(l5,io_out_bits_vpu_vstart)
    `CHECK(l5,io_out_bits_vpu_frm)
    `CHECK(l5,io_out_bits_vpu_fpu_isFpToVecInst)
    `CHECK(l5,io_out_bits_vpu_fpu_isFP32Instr)
    `CHECK(l5,io_out_bits_vpu_fpu_isFP64Instr)
    `CHECK(l5,io_out_bits_vpu_fpu_isReduction)
    `CHECK(l5,io_out_bits_vpu_fpu_isFoldTo1_2)
    `CHECK(l5,io_out_bits_vpu_fpu_isFoldTo1_4)
    `CHECK(l5,io_out_bits_vpu_fpu_isFoldTo1_8)
    `CHECK(l5,io_out_bits_vpu_vxrm)
    `CHECK(l5,io_out_bits_vpu_vuopIdx)
    `CHECK(l5,io_out_bits_vpu_lastUop)
    `CHECK(l5,io_out_bits_vpu_vmask)
    `CHECK(l5,io_out_bits_vpu_vl)
    `CHECK(l5,io_out_bits_vpu_nf)
    `CHECK(l5,io_out_bits_vpu_veew)
    `CHECK(l5,io_out_bits_vpu_isReverse)
    `CHECK(l5,io_out_bits_vpu_isExt)
    `CHECK(l5,io_out_bits_vpu_isNarrow)
    `CHECK(l5,io_out_bits_vpu_isDstMask)
    `CHECK(l5,io_out_bits_vpu_isOpMask)
    `CHECK(l5,io_out_bits_vpu_isMove)
    `CHECK(l5,io_out_bits_vpu_isDependOldVd)
    `CHECK(l5,io_out_bits_vpu_isWritePartVd)
    `CHECK(l5,io_out_bits_vpu_isVleff)
    `CHECK(l5,io_out_bits_vlsInstr)
    `CHECK(l5,io_out_bits_wfflags)
    `CHECK(l5,io_out_bits_isMove)
    `CHECK(l5,io_out_bits_uopIdx)
    `CHECK(l5,io_out_bits_isVset)
    `CHECK(l5,io_out_bits_firstUop)
    `CHECK(l5,io_out_bits_lastUop)
    `CHECK(l5,io_out_bits_numUops)
    `CHECK(l5,io_out_bits_numWB)
    `CHECK(l5,io_out_bits_commitType)
    `CHECK(l5,io_out_bits_psrc_0)
    `CHECK(l5,io_out_bits_psrc_1)
    `CHECK(l5,io_out_bits_psrc_2)
    `CHECK(l5,io_out_bits_psrc_3)
    `CHECK(l5,io_out_bits_psrc_4)
    `CHECK(l5,io_out_bits_pdest)
    `CHECK(l5,io_out_bits_robIdx_flag)
    `CHECK(l5,io_out_bits_robIdx_value)
    `CHECK(l5,io_out_bits_instrSize)
    `CHECK(l5,io_out_bits_dirtyFs)
    `CHECK(l5,io_out_bits_dirtyVs)
    `CHECK(l5,io_out_bits_traceBlockInPipe_itype)
    `CHECK(l5,io_out_bits_traceBlockInPipe_iretire)
    `CHECK(l5,io_out_bits_traceBlockInPipe_ilastsize)
    `CHECK(l5,io_out_bits_eliminatedMove)
    `CHECK(l5,io_out_bits_debugInfo_renameTime)
    `CHECK(l5,io_out_bits_debug_seqNum_seqNum)
    `CHECK(l5,io_out_bits_debug_seqNum_uopIdx)
    `CHECK(l5,io_out_bits_debug_fuType)
    `CHECK(l5,io_out_bits_debug_sim_trig)
    `CHECK(l5,io_out_bits_numLsElem)
  endtask

  task automatic sample_cov();
    logic any_valid;
    any_valid = (g_l0_io_out_valid === 1'b1) || (g_l1_io_out_valid === 1'b1) || (g_l2_io_out_valid === 1'b1) || (g_l3_io_out_valid === 1'b1) || (g_l4_io_out_valid === 1'b1) || (g_l5_io_out_valid === 1'b1);
    if (io_outAllFire && any_valid && g_l0_io_in_ready === 1'b1) n_allfire++;
    if (io_in_0_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[0]++; por_0 |= pcat_0; pand_0 &= pcat_0;
      if (io_flush) n_flfire++;
      if (g_l0_io_out_valid === 1'b1) n_owr[0]++;
    end
    if (io_in_0_valid && g_l0_io_in_ready === 1'b0) n_bp[0]++;
    if (g_l0_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[0]++;
      if (io_out_0_ready) n_deq[0]++; else n_hold[0]++;
    end
    if (io_in_1_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[1]++; por_1 |= pcat_1; pand_1 &= pcat_1;
      if (io_flush) n_flfire++;
      if (g_l1_io_out_valid === 1'b1) n_owr[1]++;
    end
    if (io_in_1_valid && g_l0_io_in_ready === 1'b0) n_bp[1]++;
    if (g_l1_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[1]++;
      if (io_out_1_ready) n_deq[1]++; else n_hold[1]++;
    end
    if (io_in_2_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[2]++; por_2 |= pcat_2; pand_2 &= pcat_2;
      if (io_flush) n_flfire++;
      if (g_l2_io_out_valid === 1'b1) n_owr[2]++;
    end
    if (io_in_2_valid && g_l0_io_in_ready === 1'b0) n_bp[2]++;
    if (g_l2_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[2]++;
      if (io_out_2_ready) n_deq[2]++; else n_hold[2]++;
    end
    if (io_in_3_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[3]++; por_3 |= pcat_3; pand_3 &= pcat_3;
      if (io_flush) n_flfire++;
      if (g_l3_io_out_valid === 1'b1) n_owr[3]++;
    end
    if (io_in_3_valid && g_l0_io_in_ready === 1'b0) n_bp[3]++;
    if (g_l3_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[3]++;
      if (io_out_3_ready) n_deq[3]++; else n_hold[3]++;
    end
    if (io_in_4_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[4]++; por_4 |= pcat_4; pand_4 &= pcat_4;
      if (io_flush) n_flfire++;
      if (g_l4_io_out_valid === 1'b1) n_owr[4]++;
    end
    if (io_in_4_valid && g_l0_io_in_ready === 1'b0) n_bp[4]++;
    if (g_l4_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[4]++;
      if (io_out_4_ready) n_deq[4]++; else n_hold[4]++;
    end
    if (io_in_5_valid && g_l0_io_in_ready === 1'b1) begin
      n_fire[5]++; por_5 |= pcat_5; pand_5 &= pcat_5;
      if (io_flush) n_flfire++;
      if (g_l5_io_out_valid === 1'b1) n_owr[5]++;
    end
    if (io_in_5_valid && g_l0_io_in_ready === 1'b0) n_bp[5]++;
    if (g_l5_io_out_valid === 1'b1) begin
      if (io_flush) n_flush[5]++;
      if (io_out_5_ready) n_deq[5]++; else n_hold[5]++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    foreach (n_fire[k]) begin n_fire[k] = 0; n_bp[k] = 0; n_hold[k] = 0; n_deq[k] = 0; n_owr[k] = 0; n_flush[k] = 0; end
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
    $display("\n==== PipeGroupConnect: checks=%0d errors=%0d (ncycles=%0d) ====", checks, errors, NCYCLES);
    $display("group: canAcc-only-by-outAllFire=%0d flush&fire=%0d", n_allfire, n_flfire);
    $display("%-5s %9s %8s %8s %8s %8s %7s %6s", "lane", "fire", "backpr", "hold", "deq", "owrite", "flush", "payld");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l0", n_fire[0], n_bp[0], n_hold[0], n_deq[0], n_owr[0], n_flush[0],
             ((&por_0) && (pand_0 == '0)) ? "ok" : "HOLE");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l1", n_fire[1], n_bp[1], n_hold[1], n_deq[1], n_owr[1], n_flush[1],
             ((&por_1) && (pand_1 == '0)) ? "ok" : "HOLE");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l2", n_fire[2], n_bp[2], n_hold[2], n_deq[2], n_owr[2], n_flush[2],
             ((&por_2) && (pand_2 == '0)) ? "ok" : "HOLE");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l3", n_fire[3], n_bp[3], n_hold[3], n_deq[3], n_owr[3], n_flush[3],
             ((&por_3) && (pand_3 == '0)) ? "ok" : "HOLE");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l4", n_fire[4], n_bp[4], n_hold[4], n_deq[4], n_owr[4], n_flush[4],
             ((&por_4) && (pand_4 == '0)) ? "ok" : "HOLE");
    $display("%-5s %9d %8d %8d %8d %8d %7d %6s", "l5", n_fire[5], n_bp[5], n_hold[5], n_deq[5], n_owr[5], n_flush[5],
             ((&por_5) && (pand_5 == '0)) ? "ok" : "HOLE");
    gate("allfire",    n_allfire, 100, "canAcc 从没单靠 outAllFire 成立过（outAllFire 项没测到）");
    gate("flush&fire", n_flfire,   10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");
    gate("l0.fire",   n_fire[0],  1000, "从没锁进过数据");
    gate("l0.backpr", n_bp[0],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l0.hold",   n_hold[0],   100, "表项从没被压住过");
    gate("l0.deq",    n_deq[0],    100, "表项从没被下游取走过");
    gate("l0.owr",    n_owr[0],    100, "从没在占用中被新数据改写过");
    gate("l0.flush",  n_flush[0],   10, "flush 从没命中占用中的表项");
    if (!(&por_0)) begin $display("COVERAGE HOLE: lane 0 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_0 != '0) begin $display("COVERAGE HOLE: lane 0 入口 payload 有位从未取到 0"); cov_fail++; end
    gate("l1.fire",   n_fire[1],  1000, "从没锁进过数据");
    gate("l1.backpr", n_bp[1],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l1.hold",   n_hold[1],   100, "表项从没被压住过");
    gate("l1.deq",    n_deq[1],    100, "表项从没被下游取走过");
    gate("l1.owr",    n_owr[1],    100, "从没在占用中被新数据改写过");
    gate("l1.flush",  n_flush[1],   10, "flush 从没命中占用中的表项");
    if (!(&por_1)) begin $display("COVERAGE HOLE: lane 1 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_1 != '0) begin $display("COVERAGE HOLE: lane 1 入口 payload 有位从未取到 0"); cov_fail++; end
    gate("l2.fire",   n_fire[2],  1000, "从没锁进过数据");
    gate("l2.backpr", n_bp[2],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l2.hold",   n_hold[2],   100, "表项从没被压住过");
    gate("l2.deq",    n_deq[2],    100, "表项从没被下游取走过");
    gate("l2.owr",    n_owr[2],    100, "从没在占用中被新数据改写过");
    gate("l2.flush",  n_flush[2],   10, "flush 从没命中占用中的表项");
    if (!(&por_2)) begin $display("COVERAGE HOLE: lane 2 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_2 != '0) begin $display("COVERAGE HOLE: lane 2 入口 payload 有位从未取到 0"); cov_fail++; end
    gate("l3.fire",   n_fire[3],  1000, "从没锁进过数据");
    gate("l3.backpr", n_bp[3],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l3.hold",   n_hold[3],   100, "表项从没被压住过");
    gate("l3.deq",    n_deq[3],    100, "表项从没被下游取走过");
    gate("l3.owr",    n_owr[3],    100, "从没在占用中被新数据改写过");
    gate("l3.flush",  n_flush[3],   10, "flush 从没命中占用中的表项");
    if (!(&por_3)) begin $display("COVERAGE HOLE: lane 3 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_3 != '0) begin $display("COVERAGE HOLE: lane 3 入口 payload 有位从未取到 0"); cov_fail++; end
    gate("l4.fire",   n_fire[4],  1000, "从没锁进过数据");
    gate("l4.backpr", n_bp[4],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l4.hold",   n_hold[4],   100, "表项从没被压住过");
    gate("l4.deq",    n_deq[4],    100, "表项从没被下游取走过");
    gate("l4.owr",    n_owr[4],    100, "从没在占用中被新数据改写过");
    gate("l4.flush",  n_flush[4],   10, "flush 从没命中占用中的表项");
    if (!(&por_4)) begin $display("COVERAGE HOLE: lane 4 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_4 != '0) begin $display("COVERAGE HOLE: lane 4 入口 payload 有位从未取到 0"); cov_fail++; end
    gate("l5.fire",   n_fire[5],  1000, "从没锁进过数据");
    gate("l5.backpr", n_bp[5],     100, "上游从没被挡过（握手永远畅通=假绿）");
    gate("l5.hold",   n_hold[5],   100, "表项从没被压住过");
    gate("l5.deq",    n_deq[5],    100, "表项从没被下游取走过");
    gate("l5.owr",    n_owr[5],    100, "从没在占用中被新数据改写过");
    gate("l5.flush",  n_flush[5],   10, "flush 从没命中占用中的表项");
    if (!(&por_5)) begin $display("COVERAGE HOLE: lane 5 入口 payload 有位从未取到 1"); cov_fail++; end
    if (pand_5 != '0) begin $display("COVERAGE HOLE: lane 5 入口 payload 有位从未取到 0"); cov_fail++; end

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
