// EntriesVfdivVidiv UT —— golden EntriesVfdivVidiv 与重写 EntriesVfdivVidiv_xs 双例化，逐拍比对全部 138 个输出。
// 端口表从 G1 golden 机械提取，比对用 `CHK 宏逐端口展开，杜绝手抄漏项。
//
// ★ 调度类模块最容易出的假绿：激励根本推不动队列 —— 条目填满后没人发射，
//   200k 拍 errors=0 其实只测了「入队后卡住」这一种状态。本 tb 第一版正是这样：
//   deq_fire 在 200k 拍里只有 2 次。所以除逐拍比对外还守一组覆盖闸，任一为 0 判 FAIL：
//     enq_fire      条目真入过队
//     wb_wake       写回唤醒真的把某个未就绪的源翻成就绪（探 golden 内部线）
//     can_issue     出现过全源就绪
//     deq_fire      真发射过（时钟沿前采样：沿上 issued 一置位 canIssue 就掉了）
//     resp_succ/block/uncertain  三种发射响应都回过
//     deq_clear     发射成功真的把条目清空过
//     trans2simp / trans2comp / simp2comp  三条转移路径都走过
//     ignore_old_vd 向量专属「旧 vd 可忽略」通路被打中过
//     full / flush  阵列填满过、冲刷过
//
// 激励要点：
//   1) pdest/psrc 共用 8 值小池，否则唤醒永远打不中在队 uop 的源；
//   2) srcType 按各源真实的门控位给（src3 走 v0 的 bit3，其余走 bit2），
//      给错了那一路唤醒就整条哑掉；
//   3) deqSelOH 由 tb 从 golden 当拍已落定的 canIssue 里挑（纯随机 one-hot
//      命中概率 ~0），且要在时钟沿**之前**用阻塞赋值算，否则慢一拍全打空。
//
// 自动生成：verif/ut/EntriesVfdivVidiv/gen.py —— 勿手改
`timescale 1ns/1ps

`define CHK(P) begin \
  checks++; \
  if (!$isunknown(g_``P) && g_``P !== i_``P) begin \
    errors++; \
    if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, `"P`", g_``P, i_``P); \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  longint checks = 0;
  always #5 clock = ~clock;

  int cov_enq_fire = 0, cov_wb_wake = 0, cov_can_issue = 0, cov_deq_fire = 0;
  int cov_deq_clear = 0, cov_first_issue = 0;
  int cov_resp_succ = 0, cov_resp_block = 0, cov_resp_uncertain = 0;
  int cov_trans2simp = 0, cov_trans2comp = 0, cov_simp2comp = 0;
  int cov_ignore_old_vd = 0, cov_full = 0, cov_flush = 0;
  int cov_fail = 0;
  task automatic covchk(string nm, int c);
    $display("  cov %-20s = %0d", nm, c);
    if (c == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: %s == 0", nm); end
  endtask

  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_enq_0_valid;
  logic io_enq_0_bits_status_robIdx_flag;
  logic [7:0] io_enq_0_bits_status_robIdx_value;
  logic io_enq_0_bits_status_fuType_22;
  logic io_enq_0_bits_status_fuType_26;
  logic [6:0] io_enq_0_bits_status_srcStatus_0_psrc;
  logic [3:0] io_enq_0_bits_status_srcStatus_0_srcType;
  logic io_enq_0_bits_status_srcStatus_0_srcState;
  logic [3:0] io_enq_0_bits_status_srcStatus_0_dataSources_value;
  logic [6:0] io_enq_0_bits_status_srcStatus_1_psrc;
  logic [3:0] io_enq_0_bits_status_srcStatus_1_srcType;
  logic io_enq_0_bits_status_srcStatus_1_srcState;
  logic [3:0] io_enq_0_bits_status_srcStatus_1_dataSources_value;
  logic [6:0] io_enq_0_bits_status_srcStatus_2_psrc;
  logic [3:0] io_enq_0_bits_status_srcStatus_2_srcType;
  logic io_enq_0_bits_status_srcStatus_2_srcState;
  logic [3:0] io_enq_0_bits_status_srcStatus_2_dataSources_value;
  logic [6:0] io_enq_0_bits_status_srcStatus_3_psrc;
  logic [3:0] io_enq_0_bits_status_srcStatus_3_srcType;
  logic io_enq_0_bits_status_srcStatus_3_srcState;
  logic [3:0] io_enq_0_bits_status_srcStatus_3_dataSources_value;
  logic [6:0] io_enq_0_bits_status_srcStatus_4_psrc;
  logic [3:0] io_enq_0_bits_status_srcStatus_4_srcType;
  logic io_enq_0_bits_status_srcStatus_4_srcState;
  logic [3:0] io_enq_0_bits_status_srcStatus_4_dataSources_value;
  logic [31:0] io_enq_0_bits_payload_instr;
  logic [49:0] io_enq_0_bits_payload_pc;
  logic [9:0] io_enq_0_bits_payload_foldpc;
  logic io_enq_0_bits_payload_exceptionVec_0;
  logic io_enq_0_bits_payload_exceptionVec_1;
  logic io_enq_0_bits_payload_exceptionVec_2;
  logic io_enq_0_bits_payload_exceptionVec_3;
  logic io_enq_0_bits_payload_exceptionVec_4;
  logic io_enq_0_bits_payload_exceptionVec_5;
  logic io_enq_0_bits_payload_exceptionVec_6;
  logic io_enq_0_bits_payload_exceptionVec_7;
  logic io_enq_0_bits_payload_exceptionVec_8;
  logic io_enq_0_bits_payload_exceptionVec_9;
  logic io_enq_0_bits_payload_exceptionVec_10;
  logic io_enq_0_bits_payload_exceptionVec_11;
  logic io_enq_0_bits_payload_exceptionVec_12;
  logic io_enq_0_bits_payload_exceptionVec_13;
  logic io_enq_0_bits_payload_exceptionVec_14;
  logic io_enq_0_bits_payload_exceptionVec_15;
  logic io_enq_0_bits_payload_exceptionVec_16;
  logic io_enq_0_bits_payload_exceptionVec_17;
  logic io_enq_0_bits_payload_exceptionVec_18;
  logic io_enq_0_bits_payload_exceptionVec_19;
  logic io_enq_0_bits_payload_exceptionVec_20;
  logic io_enq_0_bits_payload_exceptionVec_21;
  logic io_enq_0_bits_payload_exceptionVec_22;
  logic io_enq_0_bits_payload_exceptionVec_23;
  logic io_enq_0_bits_payload_isFetchMalAddr;
  logic io_enq_0_bits_payload_hasException;
  logic [3:0] io_enq_0_bits_payload_trigger;
  logic io_enq_0_bits_payload_preDecodeInfo_valid;
  logic io_enq_0_bits_payload_preDecodeInfo_isRVC;
  logic [1:0] io_enq_0_bits_payload_preDecodeInfo_brType;
  logic io_enq_0_bits_payload_preDecodeInfo_isCall;
  logic io_enq_0_bits_payload_preDecodeInfo_isRet;
  logic io_enq_0_bits_payload_pred_taken;
  logic io_enq_0_bits_payload_crossPageIPFFix;
  logic io_enq_0_bits_payload_ftqPtr_flag;
  logic [5:0] io_enq_0_bits_payload_ftqPtr_value;
  logic [3:0] io_enq_0_bits_payload_ftqOffset;
  logic io_enq_0_bits_payload_satpFlushFirstFetchFault;
  logic [3:0] io_enq_0_bits_payload_srcType_0;
  logic [3:0] io_enq_0_bits_payload_srcType_1;
  logic [3:0] io_enq_0_bits_payload_srcType_2;
  logic [3:0] io_enq_0_bits_payload_srcType_3;
  logic [3:0] io_enq_0_bits_payload_srcType_4;
  logic [5:0] io_enq_0_bits_payload_ldest;
  logic [34:0] io_enq_0_bits_payload_fuType;
  logic [8:0] io_enq_0_bits_payload_fuOpType;
  logic io_enq_0_bits_payload_rfWen;
  logic io_enq_0_bits_payload_fpWen;
  logic io_enq_0_bits_payload_vecWen;
  logic io_enq_0_bits_payload_v0Wen;
  logic io_enq_0_bits_payload_vlWen;
  logic io_enq_0_bits_payload_isXSTrap;
  logic io_enq_0_bits_payload_waitForward;
  logic io_enq_0_bits_payload_blockBackward;
  logic io_enq_0_bits_payload_flushPipe;
  logic io_enq_0_bits_payload_canRobCompress;
  logic [3:0] io_enq_0_bits_payload_selImm;
  logic [31:0] io_enq_0_bits_payload_imm;
  logic [1:0] io_enq_0_bits_payload_fpu_typeTagOut;
  logic io_enq_0_bits_payload_fpu_wflags;
  logic [1:0] io_enq_0_bits_payload_fpu_typ;
  logic [1:0] io_enq_0_bits_payload_fpu_fmt;
  logic [2:0] io_enq_0_bits_payload_fpu_rm;
  logic io_enq_0_bits_payload_vpu_vill;
  logic io_enq_0_bits_payload_vpu_vma;
  logic io_enq_0_bits_payload_vpu_vta;
  logic [1:0] io_enq_0_bits_payload_vpu_vsew;
  logic [2:0] io_enq_0_bits_payload_vpu_vlmul;
  logic io_enq_0_bits_payload_vpu_specVill;
  logic io_enq_0_bits_payload_vpu_specVma;
  logic io_enq_0_bits_payload_vpu_specVta;
  logic [1:0] io_enq_0_bits_payload_vpu_specVsew;
  logic [2:0] io_enq_0_bits_payload_vpu_specVlmul;
  logic io_enq_0_bits_payload_vpu_vm;
  logic [7:0] io_enq_0_bits_payload_vpu_vstart;
  logic [2:0] io_enq_0_bits_payload_vpu_frm;
  logic io_enq_0_bits_payload_vpu_fpu_isFpToVecInst;
  logic io_enq_0_bits_payload_vpu_fpu_isFP32Instr;
  logic io_enq_0_bits_payload_vpu_fpu_isFP64Instr;
  logic io_enq_0_bits_payload_vpu_fpu_isReduction;
  logic io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2;
  logic io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4;
  logic io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_enq_0_bits_payload_vpu_vxrm;
  logic [6:0] io_enq_0_bits_payload_vpu_vuopIdx;
  logic io_enq_0_bits_payload_vpu_lastUop;
  logic [127:0] io_enq_0_bits_payload_vpu_vmask;
  logic [7:0] io_enq_0_bits_payload_vpu_vl;
  logic [2:0] io_enq_0_bits_payload_vpu_nf;
  logic [1:0] io_enq_0_bits_payload_vpu_veew;
  logic io_enq_0_bits_payload_vpu_isReverse;
  logic io_enq_0_bits_payload_vpu_isExt;
  logic io_enq_0_bits_payload_vpu_isNarrow;
  logic io_enq_0_bits_payload_vpu_isDstMask;
  logic io_enq_0_bits_payload_vpu_isOpMask;
  logic io_enq_0_bits_payload_vpu_isMove;
  logic io_enq_0_bits_payload_vpu_isDependOldVd;
  logic io_enq_0_bits_payload_vpu_isWritePartVd;
  logic io_enq_0_bits_payload_vpu_isVleff;
  logic io_enq_0_bits_payload_vlsInstr;
  logic io_enq_0_bits_payload_wfflags;
  logic io_enq_0_bits_payload_isMove;
  logic io_enq_0_bits_payload_isDropAmocasSta;
  logic [6:0] io_enq_0_bits_payload_uopIdx;
  logic io_enq_0_bits_payload_isVset;
  logic io_enq_0_bits_payload_firstUop;
  logic io_enq_0_bits_payload_lastUop;
  logic [6:0] io_enq_0_bits_payload_numUops;
  logic [6:0] io_enq_0_bits_payload_numWB;
  logic [2:0] io_enq_0_bits_payload_commitType;
  logic io_enq_0_bits_payload_srcState_0;
  logic io_enq_0_bits_payload_srcState_1;
  logic io_enq_0_bits_payload_srcState_2;
  logic io_enq_0_bits_payload_srcState_3;
  logic io_enq_0_bits_payload_srcState_4;
  logic [7:0] io_enq_0_bits_payload_psrc_0;
  logic [7:0] io_enq_0_bits_payload_psrc_1;
  logic [7:0] io_enq_0_bits_payload_psrc_2;
  logic [7:0] io_enq_0_bits_payload_psrc_3;
  logic [7:0] io_enq_0_bits_payload_psrc_4;
  logic [7:0] io_enq_0_bits_payload_pdest;
  logic io_enq_0_bits_payload_useRegCache_0;
  logic io_enq_0_bits_payload_useRegCache_1;
  logic [4:0] io_enq_0_bits_payload_regCacheIdx_0;
  logic [4:0] io_enq_0_bits_payload_regCacheIdx_1;
  logic io_enq_0_bits_payload_robIdx_flag;
  logic [7:0] io_enq_0_bits_payload_robIdx_value;
  logic [2:0] io_enq_0_bits_payload_instrSize;
  logic io_enq_0_bits_payload_dirtyFs;
  logic io_enq_0_bits_payload_dirtyVs;
  logic [3:0] io_enq_0_bits_payload_traceBlockInPipe_itype;
  logic [3:0] io_enq_0_bits_payload_traceBlockInPipe_iretire;
  logic io_enq_0_bits_payload_traceBlockInPipe_ilastsize;
  logic io_enq_0_bits_payload_eliminatedMove;
  logic io_enq_0_bits_payload_snapshot;
  logic io_enq_0_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] io_enq_0_bits_payload_debugInfo_renameTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_dispatchTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_enqRsTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_selectTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_issueTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_writebackTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_0_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_0_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] io_enq_0_bits_payload_debug_seqNum_seqNum;
  logic [7:0] io_enq_0_bits_payload_debug_seqNum_uopIdx;
  logic io_enq_0_bits_payload_storeSetHit;
  logic io_enq_0_bits_payload_waitForRobIdx_flag;
  logic [7:0] io_enq_0_bits_payload_waitForRobIdx_value;
  logic io_enq_0_bits_payload_loadWaitBit;
  logic io_enq_0_bits_payload_loadWaitStrict;
  logic [4:0] io_enq_0_bits_payload_ssid;
  logic io_enq_0_bits_payload_lqIdx_flag;
  logic [6:0] io_enq_0_bits_payload_lqIdx_value;
  logic io_enq_0_bits_payload_sqIdx_flag;
  logic [5:0] io_enq_0_bits_payload_sqIdx_value;
  logic io_enq_0_bits_payload_singleStep;
  logic io_enq_0_bits_payload_replayInst;
  logic [34:0] io_enq_0_bits_payload_debug_fuType;
  logic io_enq_0_bits_payload_debug_sim_trig;
  logic [4:0] io_enq_0_bits_payload_numLsElem;
  logic io_enq_1_valid;
  logic io_enq_1_bits_status_robIdx_flag;
  logic [7:0] io_enq_1_bits_status_robIdx_value;
  logic io_enq_1_bits_status_fuType_22;
  logic io_enq_1_bits_status_fuType_26;
  logic [6:0] io_enq_1_bits_status_srcStatus_0_psrc;
  logic [3:0] io_enq_1_bits_status_srcStatus_0_srcType;
  logic io_enq_1_bits_status_srcStatus_0_srcState;
  logic [3:0] io_enq_1_bits_status_srcStatus_0_dataSources_value;
  logic [6:0] io_enq_1_bits_status_srcStatus_1_psrc;
  logic [3:0] io_enq_1_bits_status_srcStatus_1_srcType;
  logic io_enq_1_bits_status_srcStatus_1_srcState;
  logic [3:0] io_enq_1_bits_status_srcStatus_1_dataSources_value;
  logic [6:0] io_enq_1_bits_status_srcStatus_2_psrc;
  logic [3:0] io_enq_1_bits_status_srcStatus_2_srcType;
  logic io_enq_1_bits_status_srcStatus_2_srcState;
  logic [3:0] io_enq_1_bits_status_srcStatus_2_dataSources_value;
  logic [6:0] io_enq_1_bits_status_srcStatus_3_psrc;
  logic [3:0] io_enq_1_bits_status_srcStatus_3_srcType;
  logic io_enq_1_bits_status_srcStatus_3_srcState;
  logic [3:0] io_enq_1_bits_status_srcStatus_3_dataSources_value;
  logic [6:0] io_enq_1_bits_status_srcStatus_4_psrc;
  logic [3:0] io_enq_1_bits_status_srcStatus_4_srcType;
  logic io_enq_1_bits_status_srcStatus_4_srcState;
  logic [3:0] io_enq_1_bits_status_srcStatus_4_dataSources_value;
  logic [31:0] io_enq_1_bits_payload_instr;
  logic [49:0] io_enq_1_bits_payload_pc;
  logic [9:0] io_enq_1_bits_payload_foldpc;
  logic io_enq_1_bits_payload_exceptionVec_0;
  logic io_enq_1_bits_payload_exceptionVec_1;
  logic io_enq_1_bits_payload_exceptionVec_2;
  logic io_enq_1_bits_payload_exceptionVec_3;
  logic io_enq_1_bits_payload_exceptionVec_4;
  logic io_enq_1_bits_payload_exceptionVec_5;
  logic io_enq_1_bits_payload_exceptionVec_6;
  logic io_enq_1_bits_payload_exceptionVec_7;
  logic io_enq_1_bits_payload_exceptionVec_8;
  logic io_enq_1_bits_payload_exceptionVec_9;
  logic io_enq_1_bits_payload_exceptionVec_10;
  logic io_enq_1_bits_payload_exceptionVec_11;
  logic io_enq_1_bits_payload_exceptionVec_12;
  logic io_enq_1_bits_payload_exceptionVec_13;
  logic io_enq_1_bits_payload_exceptionVec_14;
  logic io_enq_1_bits_payload_exceptionVec_15;
  logic io_enq_1_bits_payload_exceptionVec_16;
  logic io_enq_1_bits_payload_exceptionVec_17;
  logic io_enq_1_bits_payload_exceptionVec_18;
  logic io_enq_1_bits_payload_exceptionVec_19;
  logic io_enq_1_bits_payload_exceptionVec_20;
  logic io_enq_1_bits_payload_exceptionVec_21;
  logic io_enq_1_bits_payload_exceptionVec_22;
  logic io_enq_1_bits_payload_exceptionVec_23;
  logic io_enq_1_bits_payload_isFetchMalAddr;
  logic io_enq_1_bits_payload_hasException;
  logic [3:0] io_enq_1_bits_payload_trigger;
  logic io_enq_1_bits_payload_preDecodeInfo_valid;
  logic io_enq_1_bits_payload_preDecodeInfo_isRVC;
  logic [1:0] io_enq_1_bits_payload_preDecodeInfo_brType;
  logic io_enq_1_bits_payload_preDecodeInfo_isCall;
  logic io_enq_1_bits_payload_preDecodeInfo_isRet;
  logic io_enq_1_bits_payload_pred_taken;
  logic io_enq_1_bits_payload_crossPageIPFFix;
  logic io_enq_1_bits_payload_ftqPtr_flag;
  logic [5:0] io_enq_1_bits_payload_ftqPtr_value;
  logic [3:0] io_enq_1_bits_payload_ftqOffset;
  logic io_enq_1_bits_payload_satpFlushFirstFetchFault;
  logic [3:0] io_enq_1_bits_payload_srcType_0;
  logic [3:0] io_enq_1_bits_payload_srcType_1;
  logic [3:0] io_enq_1_bits_payload_srcType_2;
  logic [3:0] io_enq_1_bits_payload_srcType_3;
  logic [3:0] io_enq_1_bits_payload_srcType_4;
  logic [5:0] io_enq_1_bits_payload_ldest;
  logic [34:0] io_enq_1_bits_payload_fuType;
  logic [8:0] io_enq_1_bits_payload_fuOpType;
  logic io_enq_1_bits_payload_rfWen;
  logic io_enq_1_bits_payload_fpWen;
  logic io_enq_1_bits_payload_vecWen;
  logic io_enq_1_bits_payload_v0Wen;
  logic io_enq_1_bits_payload_vlWen;
  logic io_enq_1_bits_payload_isXSTrap;
  logic io_enq_1_bits_payload_waitForward;
  logic io_enq_1_bits_payload_blockBackward;
  logic io_enq_1_bits_payload_flushPipe;
  logic io_enq_1_bits_payload_canRobCompress;
  logic [3:0] io_enq_1_bits_payload_selImm;
  logic [31:0] io_enq_1_bits_payload_imm;
  logic [1:0] io_enq_1_bits_payload_fpu_typeTagOut;
  logic io_enq_1_bits_payload_fpu_wflags;
  logic [1:0] io_enq_1_bits_payload_fpu_typ;
  logic [1:0] io_enq_1_bits_payload_fpu_fmt;
  logic [2:0] io_enq_1_bits_payload_fpu_rm;
  logic io_enq_1_bits_payload_vpu_vill;
  logic io_enq_1_bits_payload_vpu_vma;
  logic io_enq_1_bits_payload_vpu_vta;
  logic [1:0] io_enq_1_bits_payload_vpu_vsew;
  logic [2:0] io_enq_1_bits_payload_vpu_vlmul;
  logic io_enq_1_bits_payload_vpu_specVill;
  logic io_enq_1_bits_payload_vpu_specVma;
  logic io_enq_1_bits_payload_vpu_specVta;
  logic [1:0] io_enq_1_bits_payload_vpu_specVsew;
  logic [2:0] io_enq_1_bits_payload_vpu_specVlmul;
  logic io_enq_1_bits_payload_vpu_vm;
  logic [7:0] io_enq_1_bits_payload_vpu_vstart;
  logic [2:0] io_enq_1_bits_payload_vpu_frm;
  logic io_enq_1_bits_payload_vpu_fpu_isFpToVecInst;
  logic io_enq_1_bits_payload_vpu_fpu_isFP32Instr;
  logic io_enq_1_bits_payload_vpu_fpu_isFP64Instr;
  logic io_enq_1_bits_payload_vpu_fpu_isReduction;
  logic io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2;
  logic io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4;
  logic io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_enq_1_bits_payload_vpu_vxrm;
  logic [6:0] io_enq_1_bits_payload_vpu_vuopIdx;
  logic io_enq_1_bits_payload_vpu_lastUop;
  logic [127:0] io_enq_1_bits_payload_vpu_vmask;
  logic [7:0] io_enq_1_bits_payload_vpu_vl;
  logic [2:0] io_enq_1_bits_payload_vpu_nf;
  logic [1:0] io_enq_1_bits_payload_vpu_veew;
  logic io_enq_1_bits_payload_vpu_isReverse;
  logic io_enq_1_bits_payload_vpu_isExt;
  logic io_enq_1_bits_payload_vpu_isNarrow;
  logic io_enq_1_bits_payload_vpu_isDstMask;
  logic io_enq_1_bits_payload_vpu_isOpMask;
  logic io_enq_1_bits_payload_vpu_isMove;
  logic io_enq_1_bits_payload_vpu_isDependOldVd;
  logic io_enq_1_bits_payload_vpu_isWritePartVd;
  logic io_enq_1_bits_payload_vpu_isVleff;
  logic io_enq_1_bits_payload_vlsInstr;
  logic io_enq_1_bits_payload_wfflags;
  logic io_enq_1_bits_payload_isMove;
  logic io_enq_1_bits_payload_isDropAmocasSta;
  logic [6:0] io_enq_1_bits_payload_uopIdx;
  logic io_enq_1_bits_payload_isVset;
  logic io_enq_1_bits_payload_firstUop;
  logic io_enq_1_bits_payload_lastUop;
  logic [6:0] io_enq_1_bits_payload_numUops;
  logic [6:0] io_enq_1_bits_payload_numWB;
  logic [2:0] io_enq_1_bits_payload_commitType;
  logic io_enq_1_bits_payload_srcState_0;
  logic io_enq_1_bits_payload_srcState_1;
  logic io_enq_1_bits_payload_srcState_2;
  logic io_enq_1_bits_payload_srcState_3;
  logic io_enq_1_bits_payload_srcState_4;
  logic [7:0] io_enq_1_bits_payload_psrc_0;
  logic [7:0] io_enq_1_bits_payload_psrc_1;
  logic [7:0] io_enq_1_bits_payload_psrc_2;
  logic [7:0] io_enq_1_bits_payload_psrc_3;
  logic [7:0] io_enq_1_bits_payload_psrc_4;
  logic [7:0] io_enq_1_bits_payload_pdest;
  logic io_enq_1_bits_payload_useRegCache_0;
  logic io_enq_1_bits_payload_useRegCache_1;
  logic [4:0] io_enq_1_bits_payload_regCacheIdx_0;
  logic [4:0] io_enq_1_bits_payload_regCacheIdx_1;
  logic io_enq_1_bits_payload_robIdx_flag;
  logic [7:0] io_enq_1_bits_payload_robIdx_value;
  logic [2:0] io_enq_1_bits_payload_instrSize;
  logic io_enq_1_bits_payload_dirtyFs;
  logic io_enq_1_bits_payload_dirtyVs;
  logic [3:0] io_enq_1_bits_payload_traceBlockInPipe_itype;
  logic [3:0] io_enq_1_bits_payload_traceBlockInPipe_iretire;
  logic io_enq_1_bits_payload_traceBlockInPipe_ilastsize;
  logic io_enq_1_bits_payload_eliminatedMove;
  logic io_enq_1_bits_payload_snapshot;
  logic io_enq_1_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] io_enq_1_bits_payload_debugInfo_renameTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_dispatchTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_enqRsTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_selectTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_issueTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_writebackTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_1_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_1_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] io_enq_1_bits_payload_debug_seqNum_seqNum;
  logic [7:0] io_enq_1_bits_payload_debug_seqNum_uopIdx;
  logic io_enq_1_bits_payload_storeSetHit;
  logic io_enq_1_bits_payload_waitForRobIdx_flag;
  logic [7:0] io_enq_1_bits_payload_waitForRobIdx_value;
  logic io_enq_1_bits_payload_loadWaitBit;
  logic io_enq_1_bits_payload_loadWaitStrict;
  logic [4:0] io_enq_1_bits_payload_ssid;
  logic io_enq_1_bits_payload_lqIdx_flag;
  logic [6:0] io_enq_1_bits_payload_lqIdx_value;
  logic io_enq_1_bits_payload_sqIdx_flag;
  logic [5:0] io_enq_1_bits_payload_sqIdx_value;
  logic io_enq_1_bits_payload_singleStep;
  logic io_enq_1_bits_payload_replayInst;
  logic [34:0] io_enq_1_bits_payload_debug_fuType;
  logic io_enq_1_bits_payload_debug_sim_trig;
  logic [4:0] io_enq_1_bits_payload_numLsElem;
  logic io_og0Resp_0_valid;
  logic io_og1Resp_0_valid;
  logic io_og2Resp_0_valid;
  logic [1:0] io_og2Resp_0_bits_resp;
  logic io_deqReady_0;
  logic io_deqSelOH_0_valid;
  logic [9:0] io_deqSelOH_0_bits;
  logic [1:0] io_enqEntryOldestSel_0_bits;
  logic io_simpEntryOldestSel_0_valid;
  logic [1:0] io_simpEntryOldestSel_0_bits;
  logic io_compEntryOldestSel_0_valid;
  logic [5:0] io_compEntryOldestSel_0_bits;
  logic io_wakeUpFromWB_15_valid;
  logic io_wakeUpFromWB_15_bits_vlWen;
  logic [7:0] io_wakeUpFromWB_15_bits_pdest;
  logic io_wakeUpFromWB_14_valid;
  logic io_wakeUpFromWB_14_bits_vlWen;
  logic [7:0] io_wakeUpFromWB_14_bits_pdest;
  logic io_wakeUpFromWB_13_valid;
  logic io_wakeUpFromWB_13_bits_vlWen;
  logic [7:0] io_wakeUpFromWB_13_bits_pdest;
  logic io_wakeUpFromWB_12_valid;
  logic io_wakeUpFromWB_12_bits_vlWen;
  logic [7:0] io_wakeUpFromWB_12_bits_pdest;
  logic io_wakeUpFromWB_11_valid;
  logic io_wakeUpFromWB_11_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_11_bits_pdest;
  logic io_wakeUpFromWB_10_valid;
  logic io_wakeUpFromWB_10_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_10_bits_pdest;
  logic io_wakeUpFromWB_9_valid;
  logic io_wakeUpFromWB_9_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_9_bits_pdest;
  logic io_wakeUpFromWB_8_valid;
  logic io_wakeUpFromWB_8_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_8_bits_pdest;
  logic io_wakeUpFromWB_7_valid;
  logic io_wakeUpFromWB_7_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_7_bits_pdest;
  logic io_wakeUpFromWB_6_valid;
  logic io_wakeUpFromWB_6_bits_v0Wen;
  logic [7:0] io_wakeUpFromWB_6_bits_pdest;
  logic io_wakeUpFromWB_5_valid;
  logic io_wakeUpFromWB_5_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_5_bits_pdest;
  logic io_wakeUpFromWB_4_valid;
  logic io_wakeUpFromWB_4_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_4_bits_pdest;
  logic io_wakeUpFromWB_3_valid;
  logic io_wakeUpFromWB_3_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_3_bits_pdest;
  logic io_wakeUpFromWB_2_valid;
  logic io_wakeUpFromWB_2_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_2_bits_pdest;
  logic io_wakeUpFromWB_1_valid;
  logic io_wakeUpFromWB_1_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_1_bits_pdest;
  logic io_wakeUpFromWB_0_valid;
  logic io_wakeUpFromWB_0_bits_vecWen;
  logic [7:0] io_wakeUpFromWB_0_bits_pdest;
  logic io_wakeUpFromWBDelayed_15_valid;
  logic io_wakeUpFromWBDelayed_15_bits_vlWen;
  logic [7:0] io_wakeUpFromWBDelayed_15_bits_pdest;
  logic io_wakeUpFromWBDelayed_14_valid;
  logic io_wakeUpFromWBDelayed_14_bits_vlWen;
  logic [7:0] io_wakeUpFromWBDelayed_14_bits_pdest;
  logic io_wakeUpFromWBDelayed_13_valid;
  logic io_wakeUpFromWBDelayed_13_bits_vlWen;
  logic [7:0] io_wakeUpFromWBDelayed_13_bits_pdest;
  logic io_wakeUpFromWBDelayed_12_valid;
  logic io_wakeUpFromWBDelayed_12_bits_vlWen;
  logic [7:0] io_wakeUpFromWBDelayed_12_bits_pdest;
  logic io_wakeUpFromWBDelayed_11_valid;
  logic io_wakeUpFromWBDelayed_11_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_11_bits_pdest;
  logic io_wakeUpFromWBDelayed_10_valid;
  logic io_wakeUpFromWBDelayed_10_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_10_bits_pdest;
  logic io_wakeUpFromWBDelayed_9_valid;
  logic io_wakeUpFromWBDelayed_9_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_9_bits_pdest;
  logic io_wakeUpFromWBDelayed_8_valid;
  logic io_wakeUpFromWBDelayed_8_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_8_bits_pdest;
  logic io_wakeUpFromWBDelayed_7_valid;
  logic io_wakeUpFromWBDelayed_7_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_7_bits_pdest;
  logic io_wakeUpFromWBDelayed_6_valid;
  logic io_wakeUpFromWBDelayed_6_bits_v0Wen;
  logic [7:0] io_wakeUpFromWBDelayed_6_bits_pdest;
  logic io_wakeUpFromWBDelayed_5_valid;
  logic io_wakeUpFromWBDelayed_5_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_5_bits_pdest;
  logic io_wakeUpFromWBDelayed_4_valid;
  logic io_wakeUpFromWBDelayed_4_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_4_bits_pdest;
  logic io_wakeUpFromWBDelayed_3_valid;
  logic io_wakeUpFromWBDelayed_3_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_3_bits_pdest;
  logic io_wakeUpFromWBDelayed_2_valid;
  logic io_wakeUpFromWBDelayed_2_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_2_bits_pdest;
  logic io_wakeUpFromWBDelayed_1_valid;
  logic io_wakeUpFromWBDelayed_1_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_1_bits_pdest;
  logic io_wakeUpFromWBDelayed_0_valid;
  logic io_wakeUpFromWBDelayed_0_bits_vecWen;
  logic [7:0] io_wakeUpFromWBDelayed_0_bits_pdest;
  logic io_vlFromIntIsZero;
  logic io_vlFromIntIsVlmax;
  logic io_vlFromVfIsZero;
  logic io_vlFromVfIsVlmax;
  logic [1:0] io_simpEntryDeqSelVec_0;
  logic [1:0] io_simpEntryDeqSelVec_1;
  wire [9:0] g_io_valid;
  wire [9:0] i_io_valid;
  wire [9:0] g_io_issued;
  wire [9:0] i_io_issued;
  wire [9:0] g_io_canIssue;
  wire [9:0] i_io_canIssue;
  wire [34:0] g_io_fuType_0;
  wire [34:0] i_io_fuType_0;
  wire [34:0] g_io_fuType_1;
  wire [34:0] i_io_fuType_1;
  wire [34:0] g_io_fuType_2;
  wire [34:0] i_io_fuType_2;
  wire [34:0] g_io_fuType_3;
  wire [34:0] i_io_fuType_3;
  wire [34:0] g_io_fuType_4;
  wire [34:0] i_io_fuType_4;
  wire [34:0] g_io_fuType_5;
  wire [34:0] i_io_fuType_5;
  wire [34:0] g_io_fuType_6;
  wire [34:0] i_io_fuType_6;
  wire [34:0] g_io_fuType_7;
  wire [34:0] i_io_fuType_7;
  wire [34:0] g_io_fuType_8;
  wire [34:0] i_io_fuType_8;
  wire [34:0] g_io_fuType_9;
  wire [34:0] i_io_fuType_9;
  wire [3:0] g_io_dataSources_0_0_value;
  wire [3:0] i_io_dataSources_0_0_value;
  wire [3:0] g_io_dataSources_0_1_value;
  wire [3:0] i_io_dataSources_0_1_value;
  wire [3:0] g_io_dataSources_0_2_value;
  wire [3:0] i_io_dataSources_0_2_value;
  wire [3:0] g_io_dataSources_0_3_value;
  wire [3:0] i_io_dataSources_0_3_value;
  wire [3:0] g_io_dataSources_0_4_value;
  wire [3:0] i_io_dataSources_0_4_value;
  wire [3:0] g_io_dataSources_1_0_value;
  wire [3:0] i_io_dataSources_1_0_value;
  wire [3:0] g_io_dataSources_1_1_value;
  wire [3:0] i_io_dataSources_1_1_value;
  wire [3:0] g_io_dataSources_1_2_value;
  wire [3:0] i_io_dataSources_1_2_value;
  wire [3:0] g_io_dataSources_1_3_value;
  wire [3:0] i_io_dataSources_1_3_value;
  wire [3:0] g_io_dataSources_1_4_value;
  wire [3:0] i_io_dataSources_1_4_value;
  wire [3:0] g_io_dataSources_2_0_value;
  wire [3:0] i_io_dataSources_2_0_value;
  wire [3:0] g_io_dataSources_2_1_value;
  wire [3:0] i_io_dataSources_2_1_value;
  wire [3:0] g_io_dataSources_2_2_value;
  wire [3:0] i_io_dataSources_2_2_value;
  wire [3:0] g_io_dataSources_2_3_value;
  wire [3:0] i_io_dataSources_2_3_value;
  wire [3:0] g_io_dataSources_2_4_value;
  wire [3:0] i_io_dataSources_2_4_value;
  wire [3:0] g_io_dataSources_3_0_value;
  wire [3:0] i_io_dataSources_3_0_value;
  wire [3:0] g_io_dataSources_3_1_value;
  wire [3:0] i_io_dataSources_3_1_value;
  wire [3:0] g_io_dataSources_3_2_value;
  wire [3:0] i_io_dataSources_3_2_value;
  wire [3:0] g_io_dataSources_3_3_value;
  wire [3:0] i_io_dataSources_3_3_value;
  wire [3:0] g_io_dataSources_3_4_value;
  wire [3:0] i_io_dataSources_3_4_value;
  wire [3:0] g_io_dataSources_4_0_value;
  wire [3:0] i_io_dataSources_4_0_value;
  wire [3:0] g_io_dataSources_4_1_value;
  wire [3:0] i_io_dataSources_4_1_value;
  wire [3:0] g_io_dataSources_4_2_value;
  wire [3:0] i_io_dataSources_4_2_value;
  wire [3:0] g_io_dataSources_4_3_value;
  wire [3:0] i_io_dataSources_4_3_value;
  wire [3:0] g_io_dataSources_4_4_value;
  wire [3:0] i_io_dataSources_4_4_value;
  wire [3:0] g_io_dataSources_5_0_value;
  wire [3:0] i_io_dataSources_5_0_value;
  wire [3:0] g_io_dataSources_5_1_value;
  wire [3:0] i_io_dataSources_5_1_value;
  wire [3:0] g_io_dataSources_5_2_value;
  wire [3:0] i_io_dataSources_5_2_value;
  wire [3:0] g_io_dataSources_5_3_value;
  wire [3:0] i_io_dataSources_5_3_value;
  wire [3:0] g_io_dataSources_5_4_value;
  wire [3:0] i_io_dataSources_5_4_value;
  wire [3:0] g_io_dataSources_6_0_value;
  wire [3:0] i_io_dataSources_6_0_value;
  wire [3:0] g_io_dataSources_6_1_value;
  wire [3:0] i_io_dataSources_6_1_value;
  wire [3:0] g_io_dataSources_6_2_value;
  wire [3:0] i_io_dataSources_6_2_value;
  wire [3:0] g_io_dataSources_6_3_value;
  wire [3:0] i_io_dataSources_6_3_value;
  wire [3:0] g_io_dataSources_6_4_value;
  wire [3:0] i_io_dataSources_6_4_value;
  wire [3:0] g_io_dataSources_7_0_value;
  wire [3:0] i_io_dataSources_7_0_value;
  wire [3:0] g_io_dataSources_7_1_value;
  wire [3:0] i_io_dataSources_7_1_value;
  wire [3:0] g_io_dataSources_7_2_value;
  wire [3:0] i_io_dataSources_7_2_value;
  wire [3:0] g_io_dataSources_7_3_value;
  wire [3:0] i_io_dataSources_7_3_value;
  wire [3:0] g_io_dataSources_7_4_value;
  wire [3:0] i_io_dataSources_7_4_value;
  wire [3:0] g_io_dataSources_8_0_value;
  wire [3:0] i_io_dataSources_8_0_value;
  wire [3:0] g_io_dataSources_8_1_value;
  wire [3:0] i_io_dataSources_8_1_value;
  wire [3:0] g_io_dataSources_8_2_value;
  wire [3:0] i_io_dataSources_8_2_value;
  wire [3:0] g_io_dataSources_8_3_value;
  wire [3:0] i_io_dataSources_8_3_value;
  wire [3:0] g_io_dataSources_8_4_value;
  wire [3:0] i_io_dataSources_8_4_value;
  wire [3:0] g_io_dataSources_9_0_value;
  wire [3:0] i_io_dataSources_9_0_value;
  wire [3:0] g_io_dataSources_9_1_value;
  wire [3:0] i_io_dataSources_9_1_value;
  wire [3:0] g_io_dataSources_9_2_value;
  wire [3:0] i_io_dataSources_9_2_value;
  wire [3:0] g_io_dataSources_9_3_value;
  wire [3:0] i_io_dataSources_9_3_value;
  wire [3:0] g_io_dataSources_9_4_value;
  wire [3:0] i_io_dataSources_9_4_value;
  wire g_io_isFirstIssue_0;
  wire i_io_isFirstIssue_0;
  wire g_io_deqEntry_0_bits_status_robIdx_flag;
  wire i_io_deqEntry_0_bits_status_robIdx_flag;
  wire [7:0] g_io_deqEntry_0_bits_status_robIdx_value;
  wire [7:0] i_io_deqEntry_0_bits_status_robIdx_value;
  wire g_io_deqEntry_0_bits_status_fuType_22;
  wire i_io_deqEntry_0_bits_status_fuType_22;
  wire g_io_deqEntry_0_bits_status_fuType_26;
  wire i_io_deqEntry_0_bits_status_fuType_26;
  wire [6:0] g_io_deqEntry_0_bits_status_srcStatus_0_psrc;
  wire [6:0] i_io_deqEntry_0_bits_status_srcStatus_0_psrc;
  wire [3:0] g_io_deqEntry_0_bits_status_srcStatus_0_srcType;
  wire [3:0] i_io_deqEntry_0_bits_status_srcStatus_0_srcType;
  wire [6:0] g_io_deqEntry_0_bits_status_srcStatus_1_psrc;
  wire [6:0] i_io_deqEntry_0_bits_status_srcStatus_1_psrc;
  wire [3:0] g_io_deqEntry_0_bits_status_srcStatus_1_srcType;
  wire [3:0] i_io_deqEntry_0_bits_status_srcStatus_1_srcType;
  wire [6:0] g_io_deqEntry_0_bits_status_srcStatus_2_psrc;
  wire [6:0] i_io_deqEntry_0_bits_status_srcStatus_2_psrc;
  wire [3:0] g_io_deqEntry_0_bits_status_srcStatus_2_srcType;
  wire [3:0] i_io_deqEntry_0_bits_status_srcStatus_2_srcType;
  wire [6:0] g_io_deqEntry_0_bits_status_srcStatus_3_psrc;
  wire [6:0] i_io_deqEntry_0_bits_status_srcStatus_3_psrc;
  wire [3:0] g_io_deqEntry_0_bits_status_srcStatus_3_srcType;
  wire [3:0] i_io_deqEntry_0_bits_status_srcStatus_3_srcType;
  wire [6:0] g_io_deqEntry_0_bits_status_srcStatus_4_psrc;
  wire [6:0] i_io_deqEntry_0_bits_status_srcStatus_4_psrc;
  wire [3:0] g_io_deqEntry_0_bits_status_srcStatus_4_srcType;
  wire [3:0] i_io_deqEntry_0_bits_status_srcStatus_4_srcType;
  wire [8:0] g_io_deqEntry_0_bits_payload_fuOpType;
  wire [8:0] i_io_deqEntry_0_bits_payload_fuOpType;
  wire g_io_deqEntry_0_bits_payload_vecWen;
  wire i_io_deqEntry_0_bits_payload_vecWen;
  wire g_io_deqEntry_0_bits_payload_v0Wen;
  wire i_io_deqEntry_0_bits_payload_v0Wen;
  wire [3:0] g_io_deqEntry_0_bits_payload_selImm;
  wire [3:0] i_io_deqEntry_0_bits_payload_selImm;
  wire [1:0] g_io_deqEntry_0_bits_payload_fpu_typeTagOut;
  wire [1:0] i_io_deqEntry_0_bits_payload_fpu_typeTagOut;
  wire g_io_deqEntry_0_bits_payload_fpu_wflags;
  wire i_io_deqEntry_0_bits_payload_fpu_wflags;
  wire [1:0] g_io_deqEntry_0_bits_payload_fpu_typ;
  wire [1:0] i_io_deqEntry_0_bits_payload_fpu_typ;
  wire [1:0] g_io_deqEntry_0_bits_payload_fpu_fmt;
  wire [1:0] i_io_deqEntry_0_bits_payload_fpu_fmt;
  wire [2:0] g_io_deqEntry_0_bits_payload_fpu_rm;
  wire [2:0] i_io_deqEntry_0_bits_payload_fpu_rm;
  wire g_io_deqEntry_0_bits_payload_vpu_vill;
  wire i_io_deqEntry_0_bits_payload_vpu_vill;
  wire g_io_deqEntry_0_bits_payload_vpu_vma;
  wire i_io_deqEntry_0_bits_payload_vpu_vma;
  wire g_io_deqEntry_0_bits_payload_vpu_vta;
  wire i_io_deqEntry_0_bits_payload_vpu_vta;
  wire [1:0] g_io_deqEntry_0_bits_payload_vpu_vsew;
  wire [1:0] i_io_deqEntry_0_bits_payload_vpu_vsew;
  wire [2:0] g_io_deqEntry_0_bits_payload_vpu_vlmul;
  wire [2:0] i_io_deqEntry_0_bits_payload_vpu_vlmul;
  wire g_io_deqEntry_0_bits_payload_vpu_specVill;
  wire i_io_deqEntry_0_bits_payload_vpu_specVill;
  wire g_io_deqEntry_0_bits_payload_vpu_specVma;
  wire i_io_deqEntry_0_bits_payload_vpu_specVma;
  wire g_io_deqEntry_0_bits_payload_vpu_specVta;
  wire i_io_deqEntry_0_bits_payload_vpu_specVta;
  wire [1:0] g_io_deqEntry_0_bits_payload_vpu_specVsew;
  wire [1:0] i_io_deqEntry_0_bits_payload_vpu_specVsew;
  wire [2:0] g_io_deqEntry_0_bits_payload_vpu_specVlmul;
  wire [2:0] i_io_deqEntry_0_bits_payload_vpu_specVlmul;
  wire g_io_deqEntry_0_bits_payload_vpu_vm;
  wire i_io_deqEntry_0_bits_payload_vpu_vm;
  wire [7:0] g_io_deqEntry_0_bits_payload_vpu_vstart;
  wire [7:0] i_io_deqEntry_0_bits_payload_vpu_vstart;
  wire [2:0] g_io_deqEntry_0_bits_payload_vpu_frm;
  wire [2:0] i_io_deqEntry_0_bits_payload_vpu_frm;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isReduction;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isReduction;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4;
  wire g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8;
  wire i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8;
  wire [1:0] g_io_deqEntry_0_bits_payload_vpu_vxrm;
  wire [1:0] i_io_deqEntry_0_bits_payload_vpu_vxrm;
  wire [127:0] g_io_deqEntry_0_bits_payload_vpu_vmask;
  wire [127:0] i_io_deqEntry_0_bits_payload_vpu_vmask;
  wire [7:0] g_io_deqEntry_0_bits_payload_vpu_vl;
  wire [7:0] i_io_deqEntry_0_bits_payload_vpu_vl;
  wire [2:0] g_io_deqEntry_0_bits_payload_vpu_nf;
  wire [2:0] i_io_deqEntry_0_bits_payload_vpu_nf;
  wire [1:0] g_io_deqEntry_0_bits_payload_vpu_veew;
  wire [1:0] i_io_deqEntry_0_bits_payload_vpu_veew;
  wire g_io_deqEntry_0_bits_payload_vpu_isReverse;
  wire i_io_deqEntry_0_bits_payload_vpu_isReverse;
  wire g_io_deqEntry_0_bits_payload_vpu_isExt;
  wire i_io_deqEntry_0_bits_payload_vpu_isExt;
  wire g_io_deqEntry_0_bits_payload_vpu_isNarrow;
  wire i_io_deqEntry_0_bits_payload_vpu_isNarrow;
  wire g_io_deqEntry_0_bits_payload_vpu_isDstMask;
  wire i_io_deqEntry_0_bits_payload_vpu_isDstMask;
  wire g_io_deqEntry_0_bits_payload_vpu_isOpMask;
  wire i_io_deqEntry_0_bits_payload_vpu_isOpMask;
  wire g_io_deqEntry_0_bits_payload_vpu_isMove;
  wire i_io_deqEntry_0_bits_payload_vpu_isMove;
  wire g_io_deqEntry_0_bits_payload_vpu_isDependOldVd;
  wire i_io_deqEntry_0_bits_payload_vpu_isDependOldVd;
  wire g_io_deqEntry_0_bits_payload_vpu_isWritePartVd;
  wire i_io_deqEntry_0_bits_payload_vpu_isWritePartVd;
  wire g_io_deqEntry_0_bits_payload_vpu_isVleff;
  wire i_io_deqEntry_0_bits_payload_vpu_isVleff;
  wire [6:0] g_io_deqEntry_0_bits_payload_uopIdx;
  wire [6:0] i_io_deqEntry_0_bits_payload_uopIdx;
  wire g_io_deqEntry_0_bits_payload_lastUop;
  wire i_io_deqEntry_0_bits_payload_lastUop;
  wire [7:0] g_io_deqEntry_0_bits_payload_pdest;
  wire [7:0] i_io_deqEntry_0_bits_payload_pdest;
  wire g_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove;
  wire i_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_renameTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_renameTime;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_dispatchTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_dispatchTime;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_enqRsTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_enqRsTime;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_writebackTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_writebackTime;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] g_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime;
  wire [63:0] i_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime;
  wire [55:0] g_io_deqEntry_0_bits_payload_debug_seqNum_seqNum;
  wire [55:0] i_io_deqEntry_0_bits_payload_debug_seqNum_seqNum;
  wire [7:0] g_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx;
  wire [7:0] i_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx;
  wire [1:0] g_io_simpEntryEnqSelVec_0;
  wire [1:0] i_io_simpEntryEnqSelVec_0;
  wire [1:0] g_io_simpEntryEnqSelVec_1;
  wire [1:0] i_io_simpEntryEnqSelVec_1;
  wire [5:0] g_io_compEntryEnqSelVec_0;
  wire [5:0] i_io_compEntryEnqSelVec_0;
  wire [5:0] g_io_compEntryEnqSelVec_1;
  wire [5:0] i_io_compEntryEnqSelVec_1;

  EntriesVfdivVidiv u_g (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_status_robIdx_flag(io_enq_0_bits_status_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value(io_enq_0_bits_status_robIdx_value),
    .io_enq_0_bits_status_fuType_22(io_enq_0_bits_status_fuType_22),
    .io_enq_0_bits_status_fuType_26(io_enq_0_bits_status_fuType_26),
    .io_enq_0_bits_status_srcStatus_0_psrc(io_enq_0_bits_status_srcStatus_0_psrc),
    .io_enq_0_bits_status_srcStatus_0_srcType(io_enq_0_bits_status_srcStatus_0_srcType),
    .io_enq_0_bits_status_srcStatus_0_srcState(io_enq_0_bits_status_srcStatus_0_srcState),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value(io_enq_0_bits_status_srcStatus_0_dataSources_value),
    .io_enq_0_bits_status_srcStatus_1_psrc(io_enq_0_bits_status_srcStatus_1_psrc),
    .io_enq_0_bits_status_srcStatus_1_srcType(io_enq_0_bits_status_srcStatus_1_srcType),
    .io_enq_0_bits_status_srcStatus_1_srcState(io_enq_0_bits_status_srcStatus_1_srcState),
    .io_enq_0_bits_status_srcStatus_1_dataSources_value(io_enq_0_bits_status_srcStatus_1_dataSources_value),
    .io_enq_0_bits_status_srcStatus_2_psrc(io_enq_0_bits_status_srcStatus_2_psrc),
    .io_enq_0_bits_status_srcStatus_2_srcType(io_enq_0_bits_status_srcStatus_2_srcType),
    .io_enq_0_bits_status_srcStatus_2_srcState(io_enq_0_bits_status_srcStatus_2_srcState),
    .io_enq_0_bits_status_srcStatus_2_dataSources_value(io_enq_0_bits_status_srcStatus_2_dataSources_value),
    .io_enq_0_bits_status_srcStatus_3_psrc(io_enq_0_bits_status_srcStatus_3_psrc),
    .io_enq_0_bits_status_srcStatus_3_srcType(io_enq_0_bits_status_srcStatus_3_srcType),
    .io_enq_0_bits_status_srcStatus_3_srcState(io_enq_0_bits_status_srcStatus_3_srcState),
    .io_enq_0_bits_status_srcStatus_3_dataSources_value(io_enq_0_bits_status_srcStatus_3_dataSources_value),
    .io_enq_0_bits_status_srcStatus_4_psrc(io_enq_0_bits_status_srcStatus_4_psrc),
    .io_enq_0_bits_status_srcStatus_4_srcType(io_enq_0_bits_status_srcStatus_4_srcType),
    .io_enq_0_bits_status_srcStatus_4_srcState(io_enq_0_bits_status_srcStatus_4_srcState),
    .io_enq_0_bits_status_srcStatus_4_dataSources_value(io_enq_0_bits_status_srcStatus_4_dataSources_value),
    .io_enq_0_bits_payload_instr(io_enq_0_bits_payload_instr),
    .io_enq_0_bits_payload_pc(io_enq_0_bits_payload_pc),
    .io_enq_0_bits_payload_foldpc(io_enq_0_bits_payload_foldpc),
    .io_enq_0_bits_payload_exceptionVec_0(io_enq_0_bits_payload_exceptionVec_0),
    .io_enq_0_bits_payload_exceptionVec_1(io_enq_0_bits_payload_exceptionVec_1),
    .io_enq_0_bits_payload_exceptionVec_2(io_enq_0_bits_payload_exceptionVec_2),
    .io_enq_0_bits_payload_exceptionVec_3(io_enq_0_bits_payload_exceptionVec_3),
    .io_enq_0_bits_payload_exceptionVec_4(io_enq_0_bits_payload_exceptionVec_4),
    .io_enq_0_bits_payload_exceptionVec_5(io_enq_0_bits_payload_exceptionVec_5),
    .io_enq_0_bits_payload_exceptionVec_6(io_enq_0_bits_payload_exceptionVec_6),
    .io_enq_0_bits_payload_exceptionVec_7(io_enq_0_bits_payload_exceptionVec_7),
    .io_enq_0_bits_payload_exceptionVec_8(io_enq_0_bits_payload_exceptionVec_8),
    .io_enq_0_bits_payload_exceptionVec_9(io_enq_0_bits_payload_exceptionVec_9),
    .io_enq_0_bits_payload_exceptionVec_10(io_enq_0_bits_payload_exceptionVec_10),
    .io_enq_0_bits_payload_exceptionVec_11(io_enq_0_bits_payload_exceptionVec_11),
    .io_enq_0_bits_payload_exceptionVec_12(io_enq_0_bits_payload_exceptionVec_12),
    .io_enq_0_bits_payload_exceptionVec_13(io_enq_0_bits_payload_exceptionVec_13),
    .io_enq_0_bits_payload_exceptionVec_14(io_enq_0_bits_payload_exceptionVec_14),
    .io_enq_0_bits_payload_exceptionVec_15(io_enq_0_bits_payload_exceptionVec_15),
    .io_enq_0_bits_payload_exceptionVec_16(io_enq_0_bits_payload_exceptionVec_16),
    .io_enq_0_bits_payload_exceptionVec_17(io_enq_0_bits_payload_exceptionVec_17),
    .io_enq_0_bits_payload_exceptionVec_18(io_enq_0_bits_payload_exceptionVec_18),
    .io_enq_0_bits_payload_exceptionVec_19(io_enq_0_bits_payload_exceptionVec_19),
    .io_enq_0_bits_payload_exceptionVec_20(io_enq_0_bits_payload_exceptionVec_20),
    .io_enq_0_bits_payload_exceptionVec_21(io_enq_0_bits_payload_exceptionVec_21),
    .io_enq_0_bits_payload_exceptionVec_22(io_enq_0_bits_payload_exceptionVec_22),
    .io_enq_0_bits_payload_exceptionVec_23(io_enq_0_bits_payload_exceptionVec_23),
    .io_enq_0_bits_payload_isFetchMalAddr(io_enq_0_bits_payload_isFetchMalAddr),
    .io_enq_0_bits_payload_hasException(io_enq_0_bits_payload_hasException),
    .io_enq_0_bits_payload_trigger(io_enq_0_bits_payload_trigger),
    .io_enq_0_bits_payload_preDecodeInfo_valid(io_enq_0_bits_payload_preDecodeInfo_valid),
    .io_enq_0_bits_payload_preDecodeInfo_isRVC(io_enq_0_bits_payload_preDecodeInfo_isRVC),
    .io_enq_0_bits_payload_preDecodeInfo_brType(io_enq_0_bits_payload_preDecodeInfo_brType),
    .io_enq_0_bits_payload_preDecodeInfo_isCall(io_enq_0_bits_payload_preDecodeInfo_isCall),
    .io_enq_0_bits_payload_preDecodeInfo_isRet(io_enq_0_bits_payload_preDecodeInfo_isRet),
    .io_enq_0_bits_payload_pred_taken(io_enq_0_bits_payload_pred_taken),
    .io_enq_0_bits_payload_crossPageIPFFix(io_enq_0_bits_payload_crossPageIPFFix),
    .io_enq_0_bits_payload_ftqPtr_flag(io_enq_0_bits_payload_ftqPtr_flag),
    .io_enq_0_bits_payload_ftqPtr_value(io_enq_0_bits_payload_ftqPtr_value),
    .io_enq_0_bits_payload_ftqOffset(io_enq_0_bits_payload_ftqOffset),
    .io_enq_0_bits_payload_satpFlushFirstFetchFault(io_enq_0_bits_payload_satpFlushFirstFetchFault),
    .io_enq_0_bits_payload_srcType_0(io_enq_0_bits_payload_srcType_0),
    .io_enq_0_bits_payload_srcType_1(io_enq_0_bits_payload_srcType_1),
    .io_enq_0_bits_payload_srcType_2(io_enq_0_bits_payload_srcType_2),
    .io_enq_0_bits_payload_srcType_3(io_enq_0_bits_payload_srcType_3),
    .io_enq_0_bits_payload_srcType_4(io_enq_0_bits_payload_srcType_4),
    .io_enq_0_bits_payload_ldest(io_enq_0_bits_payload_ldest),
    .io_enq_0_bits_payload_fuType(io_enq_0_bits_payload_fuType),
    .io_enq_0_bits_payload_fuOpType(io_enq_0_bits_payload_fuOpType),
    .io_enq_0_bits_payload_rfWen(io_enq_0_bits_payload_rfWen),
    .io_enq_0_bits_payload_fpWen(io_enq_0_bits_payload_fpWen),
    .io_enq_0_bits_payload_vecWen(io_enq_0_bits_payload_vecWen),
    .io_enq_0_bits_payload_v0Wen(io_enq_0_bits_payload_v0Wen),
    .io_enq_0_bits_payload_vlWen(io_enq_0_bits_payload_vlWen),
    .io_enq_0_bits_payload_isXSTrap(io_enq_0_bits_payload_isXSTrap),
    .io_enq_0_bits_payload_waitForward(io_enq_0_bits_payload_waitForward),
    .io_enq_0_bits_payload_blockBackward(io_enq_0_bits_payload_blockBackward),
    .io_enq_0_bits_payload_flushPipe(io_enq_0_bits_payload_flushPipe),
    .io_enq_0_bits_payload_canRobCompress(io_enq_0_bits_payload_canRobCompress),
    .io_enq_0_bits_payload_selImm(io_enq_0_bits_payload_selImm),
    .io_enq_0_bits_payload_imm(io_enq_0_bits_payload_imm),
    .io_enq_0_bits_payload_fpu_typeTagOut(io_enq_0_bits_payload_fpu_typeTagOut),
    .io_enq_0_bits_payload_fpu_wflags(io_enq_0_bits_payload_fpu_wflags),
    .io_enq_0_bits_payload_fpu_typ(io_enq_0_bits_payload_fpu_typ),
    .io_enq_0_bits_payload_fpu_fmt(io_enq_0_bits_payload_fpu_fmt),
    .io_enq_0_bits_payload_fpu_rm(io_enq_0_bits_payload_fpu_rm),
    .io_enq_0_bits_payload_vpu_vill(io_enq_0_bits_payload_vpu_vill),
    .io_enq_0_bits_payload_vpu_vma(io_enq_0_bits_payload_vpu_vma),
    .io_enq_0_bits_payload_vpu_vta(io_enq_0_bits_payload_vpu_vta),
    .io_enq_0_bits_payload_vpu_vsew(io_enq_0_bits_payload_vpu_vsew),
    .io_enq_0_bits_payload_vpu_vlmul(io_enq_0_bits_payload_vpu_vlmul),
    .io_enq_0_bits_payload_vpu_specVill(io_enq_0_bits_payload_vpu_specVill),
    .io_enq_0_bits_payload_vpu_specVma(io_enq_0_bits_payload_vpu_specVma),
    .io_enq_0_bits_payload_vpu_specVta(io_enq_0_bits_payload_vpu_specVta),
    .io_enq_0_bits_payload_vpu_specVsew(io_enq_0_bits_payload_vpu_specVsew),
    .io_enq_0_bits_payload_vpu_specVlmul(io_enq_0_bits_payload_vpu_specVlmul),
    .io_enq_0_bits_payload_vpu_vm(io_enq_0_bits_payload_vpu_vm),
    .io_enq_0_bits_payload_vpu_vstart(io_enq_0_bits_payload_vpu_vstart),
    .io_enq_0_bits_payload_vpu_frm(io_enq_0_bits_payload_vpu_frm),
    .io_enq_0_bits_payload_vpu_fpu_isFpToVecInst(io_enq_0_bits_payload_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_payload_vpu_fpu_isFP32Instr(io_enq_0_bits_payload_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_payload_vpu_fpu_isFP64Instr(io_enq_0_bits_payload_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_payload_vpu_fpu_isReduction(io_enq_0_bits_payload_vpu_fpu_isReduction),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_payload_vpu_vxrm(io_enq_0_bits_payload_vpu_vxrm),
    .io_enq_0_bits_payload_vpu_vuopIdx(io_enq_0_bits_payload_vpu_vuopIdx),
    .io_enq_0_bits_payload_vpu_lastUop(io_enq_0_bits_payload_vpu_lastUop),
    .io_enq_0_bits_payload_vpu_vmask(io_enq_0_bits_payload_vpu_vmask),
    .io_enq_0_bits_payload_vpu_vl(io_enq_0_bits_payload_vpu_vl),
    .io_enq_0_bits_payload_vpu_nf(io_enq_0_bits_payload_vpu_nf),
    .io_enq_0_bits_payload_vpu_veew(io_enq_0_bits_payload_vpu_veew),
    .io_enq_0_bits_payload_vpu_isReverse(io_enq_0_bits_payload_vpu_isReverse),
    .io_enq_0_bits_payload_vpu_isExt(io_enq_0_bits_payload_vpu_isExt),
    .io_enq_0_bits_payload_vpu_isNarrow(io_enq_0_bits_payload_vpu_isNarrow),
    .io_enq_0_bits_payload_vpu_isDstMask(io_enq_0_bits_payload_vpu_isDstMask),
    .io_enq_0_bits_payload_vpu_isOpMask(io_enq_0_bits_payload_vpu_isOpMask),
    .io_enq_0_bits_payload_vpu_isMove(io_enq_0_bits_payload_vpu_isMove),
    .io_enq_0_bits_payload_vpu_isDependOldVd(io_enq_0_bits_payload_vpu_isDependOldVd),
    .io_enq_0_bits_payload_vpu_isWritePartVd(io_enq_0_bits_payload_vpu_isWritePartVd),
    .io_enq_0_bits_payload_vpu_isVleff(io_enq_0_bits_payload_vpu_isVleff),
    .io_enq_0_bits_payload_vlsInstr(io_enq_0_bits_payload_vlsInstr),
    .io_enq_0_bits_payload_wfflags(io_enq_0_bits_payload_wfflags),
    .io_enq_0_bits_payload_isMove(io_enq_0_bits_payload_isMove),
    .io_enq_0_bits_payload_isDropAmocasSta(io_enq_0_bits_payload_isDropAmocasSta),
    .io_enq_0_bits_payload_uopIdx(io_enq_0_bits_payload_uopIdx),
    .io_enq_0_bits_payload_isVset(io_enq_0_bits_payload_isVset),
    .io_enq_0_bits_payload_firstUop(io_enq_0_bits_payload_firstUop),
    .io_enq_0_bits_payload_lastUop(io_enq_0_bits_payload_lastUop),
    .io_enq_0_bits_payload_numUops(io_enq_0_bits_payload_numUops),
    .io_enq_0_bits_payload_numWB(io_enq_0_bits_payload_numWB),
    .io_enq_0_bits_payload_commitType(io_enq_0_bits_payload_commitType),
    .io_enq_0_bits_payload_srcState_0(io_enq_0_bits_payload_srcState_0),
    .io_enq_0_bits_payload_srcState_1(io_enq_0_bits_payload_srcState_1),
    .io_enq_0_bits_payload_srcState_2(io_enq_0_bits_payload_srcState_2),
    .io_enq_0_bits_payload_srcState_3(io_enq_0_bits_payload_srcState_3),
    .io_enq_0_bits_payload_srcState_4(io_enq_0_bits_payload_srcState_4),
    .io_enq_0_bits_payload_psrc_0(io_enq_0_bits_payload_psrc_0),
    .io_enq_0_bits_payload_psrc_1(io_enq_0_bits_payload_psrc_1),
    .io_enq_0_bits_payload_psrc_2(io_enq_0_bits_payload_psrc_2),
    .io_enq_0_bits_payload_psrc_3(io_enq_0_bits_payload_psrc_3),
    .io_enq_0_bits_payload_psrc_4(io_enq_0_bits_payload_psrc_4),
    .io_enq_0_bits_payload_pdest(io_enq_0_bits_payload_pdest),
    .io_enq_0_bits_payload_useRegCache_0(io_enq_0_bits_payload_useRegCache_0),
    .io_enq_0_bits_payload_useRegCache_1(io_enq_0_bits_payload_useRegCache_1),
    .io_enq_0_bits_payload_regCacheIdx_0(io_enq_0_bits_payload_regCacheIdx_0),
    .io_enq_0_bits_payload_regCacheIdx_1(io_enq_0_bits_payload_regCacheIdx_1),
    .io_enq_0_bits_payload_robIdx_flag(io_enq_0_bits_payload_robIdx_flag),
    .io_enq_0_bits_payload_robIdx_value(io_enq_0_bits_payload_robIdx_value),
    .io_enq_0_bits_payload_instrSize(io_enq_0_bits_payload_instrSize),
    .io_enq_0_bits_payload_dirtyFs(io_enq_0_bits_payload_dirtyFs),
    .io_enq_0_bits_payload_dirtyVs(io_enq_0_bits_payload_dirtyVs),
    .io_enq_0_bits_payload_traceBlockInPipe_itype(io_enq_0_bits_payload_traceBlockInPipe_itype),
    .io_enq_0_bits_payload_traceBlockInPipe_iretire(io_enq_0_bits_payload_traceBlockInPipe_iretire),
    .io_enq_0_bits_payload_traceBlockInPipe_ilastsize(io_enq_0_bits_payload_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_payload_eliminatedMove(io_enq_0_bits_payload_eliminatedMove),
    .io_enq_0_bits_payload_snapshot(io_enq_0_bits_payload_snapshot),
    .io_enq_0_bits_payload_debugInfo_eliminatedMove(io_enq_0_bits_payload_debugInfo_eliminatedMove),
    .io_enq_0_bits_payload_debugInfo_renameTime(io_enq_0_bits_payload_debugInfo_renameTime),
    .io_enq_0_bits_payload_debugInfo_dispatchTime(io_enq_0_bits_payload_debugInfo_dispatchTime),
    .io_enq_0_bits_payload_debugInfo_enqRsTime(io_enq_0_bits_payload_debugInfo_enqRsTime),
    .io_enq_0_bits_payload_debugInfo_selectTime(io_enq_0_bits_payload_debugInfo_selectTime),
    .io_enq_0_bits_payload_debugInfo_issueTime(io_enq_0_bits_payload_debugInfo_issueTime),
    .io_enq_0_bits_payload_debugInfo_writebackTime(io_enq_0_bits_payload_debugInfo_writebackTime),
    .io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id(io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_payload_debugInfo_tlbFirstReqTime(io_enq_0_bits_payload_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_payload_debugInfo_tlbRespTime(io_enq_0_bits_payload_debugInfo_tlbRespTime),
    .io_enq_0_bits_payload_debug_seqNum_seqNum(io_enq_0_bits_payload_debug_seqNum_seqNum),
    .io_enq_0_bits_payload_debug_seqNum_uopIdx(io_enq_0_bits_payload_debug_seqNum_uopIdx),
    .io_enq_0_bits_payload_storeSetHit(io_enq_0_bits_payload_storeSetHit),
    .io_enq_0_bits_payload_waitForRobIdx_flag(io_enq_0_bits_payload_waitForRobIdx_flag),
    .io_enq_0_bits_payload_waitForRobIdx_value(io_enq_0_bits_payload_waitForRobIdx_value),
    .io_enq_0_bits_payload_loadWaitBit(io_enq_0_bits_payload_loadWaitBit),
    .io_enq_0_bits_payload_loadWaitStrict(io_enq_0_bits_payload_loadWaitStrict),
    .io_enq_0_bits_payload_ssid(io_enq_0_bits_payload_ssid),
    .io_enq_0_bits_payload_lqIdx_flag(io_enq_0_bits_payload_lqIdx_flag),
    .io_enq_0_bits_payload_lqIdx_value(io_enq_0_bits_payload_lqIdx_value),
    .io_enq_0_bits_payload_sqIdx_flag(io_enq_0_bits_payload_sqIdx_flag),
    .io_enq_0_bits_payload_sqIdx_value(io_enq_0_bits_payload_sqIdx_value),
    .io_enq_0_bits_payload_singleStep(io_enq_0_bits_payload_singleStep),
    .io_enq_0_bits_payload_replayInst(io_enq_0_bits_payload_replayInst),
    .io_enq_0_bits_payload_debug_fuType(io_enq_0_bits_payload_debug_fuType),
    .io_enq_0_bits_payload_debug_sim_trig(io_enq_0_bits_payload_debug_sim_trig),
    .io_enq_0_bits_payload_numLsElem(io_enq_0_bits_payload_numLsElem),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_status_robIdx_flag(io_enq_1_bits_status_robIdx_flag),
    .io_enq_1_bits_status_robIdx_value(io_enq_1_bits_status_robIdx_value),
    .io_enq_1_bits_status_fuType_22(io_enq_1_bits_status_fuType_22),
    .io_enq_1_bits_status_fuType_26(io_enq_1_bits_status_fuType_26),
    .io_enq_1_bits_status_srcStatus_0_psrc(io_enq_1_bits_status_srcStatus_0_psrc),
    .io_enq_1_bits_status_srcStatus_0_srcType(io_enq_1_bits_status_srcStatus_0_srcType),
    .io_enq_1_bits_status_srcStatus_0_srcState(io_enq_1_bits_status_srcStatus_0_srcState),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value(io_enq_1_bits_status_srcStatus_0_dataSources_value),
    .io_enq_1_bits_status_srcStatus_1_psrc(io_enq_1_bits_status_srcStatus_1_psrc),
    .io_enq_1_bits_status_srcStatus_1_srcType(io_enq_1_bits_status_srcStatus_1_srcType),
    .io_enq_1_bits_status_srcStatus_1_srcState(io_enq_1_bits_status_srcStatus_1_srcState),
    .io_enq_1_bits_status_srcStatus_1_dataSources_value(io_enq_1_bits_status_srcStatus_1_dataSources_value),
    .io_enq_1_bits_status_srcStatus_2_psrc(io_enq_1_bits_status_srcStatus_2_psrc),
    .io_enq_1_bits_status_srcStatus_2_srcType(io_enq_1_bits_status_srcStatus_2_srcType),
    .io_enq_1_bits_status_srcStatus_2_srcState(io_enq_1_bits_status_srcStatus_2_srcState),
    .io_enq_1_bits_status_srcStatus_2_dataSources_value(io_enq_1_bits_status_srcStatus_2_dataSources_value),
    .io_enq_1_bits_status_srcStatus_3_psrc(io_enq_1_bits_status_srcStatus_3_psrc),
    .io_enq_1_bits_status_srcStatus_3_srcType(io_enq_1_bits_status_srcStatus_3_srcType),
    .io_enq_1_bits_status_srcStatus_3_srcState(io_enq_1_bits_status_srcStatus_3_srcState),
    .io_enq_1_bits_status_srcStatus_3_dataSources_value(io_enq_1_bits_status_srcStatus_3_dataSources_value),
    .io_enq_1_bits_status_srcStatus_4_psrc(io_enq_1_bits_status_srcStatus_4_psrc),
    .io_enq_1_bits_status_srcStatus_4_srcType(io_enq_1_bits_status_srcStatus_4_srcType),
    .io_enq_1_bits_status_srcStatus_4_srcState(io_enq_1_bits_status_srcStatus_4_srcState),
    .io_enq_1_bits_status_srcStatus_4_dataSources_value(io_enq_1_bits_status_srcStatus_4_dataSources_value),
    .io_enq_1_bits_payload_instr(io_enq_1_bits_payload_instr),
    .io_enq_1_bits_payload_pc(io_enq_1_bits_payload_pc),
    .io_enq_1_bits_payload_foldpc(io_enq_1_bits_payload_foldpc),
    .io_enq_1_bits_payload_exceptionVec_0(io_enq_1_bits_payload_exceptionVec_0),
    .io_enq_1_bits_payload_exceptionVec_1(io_enq_1_bits_payload_exceptionVec_1),
    .io_enq_1_bits_payload_exceptionVec_2(io_enq_1_bits_payload_exceptionVec_2),
    .io_enq_1_bits_payload_exceptionVec_3(io_enq_1_bits_payload_exceptionVec_3),
    .io_enq_1_bits_payload_exceptionVec_4(io_enq_1_bits_payload_exceptionVec_4),
    .io_enq_1_bits_payload_exceptionVec_5(io_enq_1_bits_payload_exceptionVec_5),
    .io_enq_1_bits_payload_exceptionVec_6(io_enq_1_bits_payload_exceptionVec_6),
    .io_enq_1_bits_payload_exceptionVec_7(io_enq_1_bits_payload_exceptionVec_7),
    .io_enq_1_bits_payload_exceptionVec_8(io_enq_1_bits_payload_exceptionVec_8),
    .io_enq_1_bits_payload_exceptionVec_9(io_enq_1_bits_payload_exceptionVec_9),
    .io_enq_1_bits_payload_exceptionVec_10(io_enq_1_bits_payload_exceptionVec_10),
    .io_enq_1_bits_payload_exceptionVec_11(io_enq_1_bits_payload_exceptionVec_11),
    .io_enq_1_bits_payload_exceptionVec_12(io_enq_1_bits_payload_exceptionVec_12),
    .io_enq_1_bits_payload_exceptionVec_13(io_enq_1_bits_payload_exceptionVec_13),
    .io_enq_1_bits_payload_exceptionVec_14(io_enq_1_bits_payload_exceptionVec_14),
    .io_enq_1_bits_payload_exceptionVec_15(io_enq_1_bits_payload_exceptionVec_15),
    .io_enq_1_bits_payload_exceptionVec_16(io_enq_1_bits_payload_exceptionVec_16),
    .io_enq_1_bits_payload_exceptionVec_17(io_enq_1_bits_payload_exceptionVec_17),
    .io_enq_1_bits_payload_exceptionVec_18(io_enq_1_bits_payload_exceptionVec_18),
    .io_enq_1_bits_payload_exceptionVec_19(io_enq_1_bits_payload_exceptionVec_19),
    .io_enq_1_bits_payload_exceptionVec_20(io_enq_1_bits_payload_exceptionVec_20),
    .io_enq_1_bits_payload_exceptionVec_21(io_enq_1_bits_payload_exceptionVec_21),
    .io_enq_1_bits_payload_exceptionVec_22(io_enq_1_bits_payload_exceptionVec_22),
    .io_enq_1_bits_payload_exceptionVec_23(io_enq_1_bits_payload_exceptionVec_23),
    .io_enq_1_bits_payload_isFetchMalAddr(io_enq_1_bits_payload_isFetchMalAddr),
    .io_enq_1_bits_payload_hasException(io_enq_1_bits_payload_hasException),
    .io_enq_1_bits_payload_trigger(io_enq_1_bits_payload_trigger),
    .io_enq_1_bits_payload_preDecodeInfo_valid(io_enq_1_bits_payload_preDecodeInfo_valid),
    .io_enq_1_bits_payload_preDecodeInfo_isRVC(io_enq_1_bits_payload_preDecodeInfo_isRVC),
    .io_enq_1_bits_payload_preDecodeInfo_brType(io_enq_1_bits_payload_preDecodeInfo_brType),
    .io_enq_1_bits_payload_preDecodeInfo_isCall(io_enq_1_bits_payload_preDecodeInfo_isCall),
    .io_enq_1_bits_payload_preDecodeInfo_isRet(io_enq_1_bits_payload_preDecodeInfo_isRet),
    .io_enq_1_bits_payload_pred_taken(io_enq_1_bits_payload_pred_taken),
    .io_enq_1_bits_payload_crossPageIPFFix(io_enq_1_bits_payload_crossPageIPFFix),
    .io_enq_1_bits_payload_ftqPtr_flag(io_enq_1_bits_payload_ftqPtr_flag),
    .io_enq_1_bits_payload_ftqPtr_value(io_enq_1_bits_payload_ftqPtr_value),
    .io_enq_1_bits_payload_ftqOffset(io_enq_1_bits_payload_ftqOffset),
    .io_enq_1_bits_payload_satpFlushFirstFetchFault(io_enq_1_bits_payload_satpFlushFirstFetchFault),
    .io_enq_1_bits_payload_srcType_0(io_enq_1_bits_payload_srcType_0),
    .io_enq_1_bits_payload_srcType_1(io_enq_1_bits_payload_srcType_1),
    .io_enq_1_bits_payload_srcType_2(io_enq_1_bits_payload_srcType_2),
    .io_enq_1_bits_payload_srcType_3(io_enq_1_bits_payload_srcType_3),
    .io_enq_1_bits_payload_srcType_4(io_enq_1_bits_payload_srcType_4),
    .io_enq_1_bits_payload_ldest(io_enq_1_bits_payload_ldest),
    .io_enq_1_bits_payload_fuType(io_enq_1_bits_payload_fuType),
    .io_enq_1_bits_payload_fuOpType(io_enq_1_bits_payload_fuOpType),
    .io_enq_1_bits_payload_rfWen(io_enq_1_bits_payload_rfWen),
    .io_enq_1_bits_payload_fpWen(io_enq_1_bits_payload_fpWen),
    .io_enq_1_bits_payload_vecWen(io_enq_1_bits_payload_vecWen),
    .io_enq_1_bits_payload_v0Wen(io_enq_1_bits_payload_v0Wen),
    .io_enq_1_bits_payload_vlWen(io_enq_1_bits_payload_vlWen),
    .io_enq_1_bits_payload_isXSTrap(io_enq_1_bits_payload_isXSTrap),
    .io_enq_1_bits_payload_waitForward(io_enq_1_bits_payload_waitForward),
    .io_enq_1_bits_payload_blockBackward(io_enq_1_bits_payload_blockBackward),
    .io_enq_1_bits_payload_flushPipe(io_enq_1_bits_payload_flushPipe),
    .io_enq_1_bits_payload_canRobCompress(io_enq_1_bits_payload_canRobCompress),
    .io_enq_1_bits_payload_selImm(io_enq_1_bits_payload_selImm),
    .io_enq_1_bits_payload_imm(io_enq_1_bits_payload_imm),
    .io_enq_1_bits_payload_fpu_typeTagOut(io_enq_1_bits_payload_fpu_typeTagOut),
    .io_enq_1_bits_payload_fpu_wflags(io_enq_1_bits_payload_fpu_wflags),
    .io_enq_1_bits_payload_fpu_typ(io_enq_1_bits_payload_fpu_typ),
    .io_enq_1_bits_payload_fpu_fmt(io_enq_1_bits_payload_fpu_fmt),
    .io_enq_1_bits_payload_fpu_rm(io_enq_1_bits_payload_fpu_rm),
    .io_enq_1_bits_payload_vpu_vill(io_enq_1_bits_payload_vpu_vill),
    .io_enq_1_bits_payload_vpu_vma(io_enq_1_bits_payload_vpu_vma),
    .io_enq_1_bits_payload_vpu_vta(io_enq_1_bits_payload_vpu_vta),
    .io_enq_1_bits_payload_vpu_vsew(io_enq_1_bits_payload_vpu_vsew),
    .io_enq_1_bits_payload_vpu_vlmul(io_enq_1_bits_payload_vpu_vlmul),
    .io_enq_1_bits_payload_vpu_specVill(io_enq_1_bits_payload_vpu_specVill),
    .io_enq_1_bits_payload_vpu_specVma(io_enq_1_bits_payload_vpu_specVma),
    .io_enq_1_bits_payload_vpu_specVta(io_enq_1_bits_payload_vpu_specVta),
    .io_enq_1_bits_payload_vpu_specVsew(io_enq_1_bits_payload_vpu_specVsew),
    .io_enq_1_bits_payload_vpu_specVlmul(io_enq_1_bits_payload_vpu_specVlmul),
    .io_enq_1_bits_payload_vpu_vm(io_enq_1_bits_payload_vpu_vm),
    .io_enq_1_bits_payload_vpu_vstart(io_enq_1_bits_payload_vpu_vstart),
    .io_enq_1_bits_payload_vpu_frm(io_enq_1_bits_payload_vpu_frm),
    .io_enq_1_bits_payload_vpu_fpu_isFpToVecInst(io_enq_1_bits_payload_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_payload_vpu_fpu_isFP32Instr(io_enq_1_bits_payload_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_payload_vpu_fpu_isFP64Instr(io_enq_1_bits_payload_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_payload_vpu_fpu_isReduction(io_enq_1_bits_payload_vpu_fpu_isReduction),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_payload_vpu_vxrm(io_enq_1_bits_payload_vpu_vxrm),
    .io_enq_1_bits_payload_vpu_vuopIdx(io_enq_1_bits_payload_vpu_vuopIdx),
    .io_enq_1_bits_payload_vpu_lastUop(io_enq_1_bits_payload_vpu_lastUop),
    .io_enq_1_bits_payload_vpu_vmask(io_enq_1_bits_payload_vpu_vmask),
    .io_enq_1_bits_payload_vpu_vl(io_enq_1_bits_payload_vpu_vl),
    .io_enq_1_bits_payload_vpu_nf(io_enq_1_bits_payload_vpu_nf),
    .io_enq_1_bits_payload_vpu_veew(io_enq_1_bits_payload_vpu_veew),
    .io_enq_1_bits_payload_vpu_isReverse(io_enq_1_bits_payload_vpu_isReverse),
    .io_enq_1_bits_payload_vpu_isExt(io_enq_1_bits_payload_vpu_isExt),
    .io_enq_1_bits_payload_vpu_isNarrow(io_enq_1_bits_payload_vpu_isNarrow),
    .io_enq_1_bits_payload_vpu_isDstMask(io_enq_1_bits_payload_vpu_isDstMask),
    .io_enq_1_bits_payload_vpu_isOpMask(io_enq_1_bits_payload_vpu_isOpMask),
    .io_enq_1_bits_payload_vpu_isMove(io_enq_1_bits_payload_vpu_isMove),
    .io_enq_1_bits_payload_vpu_isDependOldVd(io_enq_1_bits_payload_vpu_isDependOldVd),
    .io_enq_1_bits_payload_vpu_isWritePartVd(io_enq_1_bits_payload_vpu_isWritePartVd),
    .io_enq_1_bits_payload_vpu_isVleff(io_enq_1_bits_payload_vpu_isVleff),
    .io_enq_1_bits_payload_vlsInstr(io_enq_1_bits_payload_vlsInstr),
    .io_enq_1_bits_payload_wfflags(io_enq_1_bits_payload_wfflags),
    .io_enq_1_bits_payload_isMove(io_enq_1_bits_payload_isMove),
    .io_enq_1_bits_payload_isDropAmocasSta(io_enq_1_bits_payload_isDropAmocasSta),
    .io_enq_1_bits_payload_uopIdx(io_enq_1_bits_payload_uopIdx),
    .io_enq_1_bits_payload_isVset(io_enq_1_bits_payload_isVset),
    .io_enq_1_bits_payload_firstUop(io_enq_1_bits_payload_firstUop),
    .io_enq_1_bits_payload_lastUop(io_enq_1_bits_payload_lastUop),
    .io_enq_1_bits_payload_numUops(io_enq_1_bits_payload_numUops),
    .io_enq_1_bits_payload_numWB(io_enq_1_bits_payload_numWB),
    .io_enq_1_bits_payload_commitType(io_enq_1_bits_payload_commitType),
    .io_enq_1_bits_payload_srcState_0(io_enq_1_bits_payload_srcState_0),
    .io_enq_1_bits_payload_srcState_1(io_enq_1_bits_payload_srcState_1),
    .io_enq_1_bits_payload_srcState_2(io_enq_1_bits_payload_srcState_2),
    .io_enq_1_bits_payload_srcState_3(io_enq_1_bits_payload_srcState_3),
    .io_enq_1_bits_payload_srcState_4(io_enq_1_bits_payload_srcState_4),
    .io_enq_1_bits_payload_psrc_0(io_enq_1_bits_payload_psrc_0),
    .io_enq_1_bits_payload_psrc_1(io_enq_1_bits_payload_psrc_1),
    .io_enq_1_bits_payload_psrc_2(io_enq_1_bits_payload_psrc_2),
    .io_enq_1_bits_payload_psrc_3(io_enq_1_bits_payload_psrc_3),
    .io_enq_1_bits_payload_psrc_4(io_enq_1_bits_payload_psrc_4),
    .io_enq_1_bits_payload_pdest(io_enq_1_bits_payload_pdest),
    .io_enq_1_bits_payload_useRegCache_0(io_enq_1_bits_payload_useRegCache_0),
    .io_enq_1_bits_payload_useRegCache_1(io_enq_1_bits_payload_useRegCache_1),
    .io_enq_1_bits_payload_regCacheIdx_0(io_enq_1_bits_payload_regCacheIdx_0),
    .io_enq_1_bits_payload_regCacheIdx_1(io_enq_1_bits_payload_regCacheIdx_1),
    .io_enq_1_bits_payload_robIdx_flag(io_enq_1_bits_payload_robIdx_flag),
    .io_enq_1_bits_payload_robIdx_value(io_enq_1_bits_payload_robIdx_value),
    .io_enq_1_bits_payload_instrSize(io_enq_1_bits_payload_instrSize),
    .io_enq_1_bits_payload_dirtyFs(io_enq_1_bits_payload_dirtyFs),
    .io_enq_1_bits_payload_dirtyVs(io_enq_1_bits_payload_dirtyVs),
    .io_enq_1_bits_payload_traceBlockInPipe_itype(io_enq_1_bits_payload_traceBlockInPipe_itype),
    .io_enq_1_bits_payload_traceBlockInPipe_iretire(io_enq_1_bits_payload_traceBlockInPipe_iretire),
    .io_enq_1_bits_payload_traceBlockInPipe_ilastsize(io_enq_1_bits_payload_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_payload_eliminatedMove(io_enq_1_bits_payload_eliminatedMove),
    .io_enq_1_bits_payload_snapshot(io_enq_1_bits_payload_snapshot),
    .io_enq_1_bits_payload_debugInfo_eliminatedMove(io_enq_1_bits_payload_debugInfo_eliminatedMove),
    .io_enq_1_bits_payload_debugInfo_renameTime(io_enq_1_bits_payload_debugInfo_renameTime),
    .io_enq_1_bits_payload_debugInfo_dispatchTime(io_enq_1_bits_payload_debugInfo_dispatchTime),
    .io_enq_1_bits_payload_debugInfo_enqRsTime(io_enq_1_bits_payload_debugInfo_enqRsTime),
    .io_enq_1_bits_payload_debugInfo_selectTime(io_enq_1_bits_payload_debugInfo_selectTime),
    .io_enq_1_bits_payload_debugInfo_issueTime(io_enq_1_bits_payload_debugInfo_issueTime),
    .io_enq_1_bits_payload_debugInfo_writebackTime(io_enq_1_bits_payload_debugInfo_writebackTime),
    .io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id(io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_payload_debugInfo_tlbFirstReqTime(io_enq_1_bits_payload_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_payload_debugInfo_tlbRespTime(io_enq_1_bits_payload_debugInfo_tlbRespTime),
    .io_enq_1_bits_payload_debug_seqNum_seqNum(io_enq_1_bits_payload_debug_seqNum_seqNum),
    .io_enq_1_bits_payload_debug_seqNum_uopIdx(io_enq_1_bits_payload_debug_seqNum_uopIdx),
    .io_enq_1_bits_payload_storeSetHit(io_enq_1_bits_payload_storeSetHit),
    .io_enq_1_bits_payload_waitForRobIdx_flag(io_enq_1_bits_payload_waitForRobIdx_flag),
    .io_enq_1_bits_payload_waitForRobIdx_value(io_enq_1_bits_payload_waitForRobIdx_value),
    .io_enq_1_bits_payload_loadWaitBit(io_enq_1_bits_payload_loadWaitBit),
    .io_enq_1_bits_payload_loadWaitStrict(io_enq_1_bits_payload_loadWaitStrict),
    .io_enq_1_bits_payload_ssid(io_enq_1_bits_payload_ssid),
    .io_enq_1_bits_payload_lqIdx_flag(io_enq_1_bits_payload_lqIdx_flag),
    .io_enq_1_bits_payload_lqIdx_value(io_enq_1_bits_payload_lqIdx_value),
    .io_enq_1_bits_payload_sqIdx_flag(io_enq_1_bits_payload_sqIdx_flag),
    .io_enq_1_bits_payload_sqIdx_value(io_enq_1_bits_payload_sqIdx_value),
    .io_enq_1_bits_payload_singleStep(io_enq_1_bits_payload_singleStep),
    .io_enq_1_bits_payload_replayInst(io_enq_1_bits_payload_replayInst),
    .io_enq_1_bits_payload_debug_fuType(io_enq_1_bits_payload_debug_fuType),
    .io_enq_1_bits_payload_debug_sim_trig(io_enq_1_bits_payload_debug_sim_trig),
    .io_enq_1_bits_payload_numLsElem(io_enq_1_bits_payload_numLsElem),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og2Resp_0_valid(io_og2Resp_0_valid),
    .io_og2Resp_0_bits_resp(io_og2Resp_0_bits_resp),
    .io_deqReady_0(io_deqReady_0),
    .io_deqSelOH_0_valid(io_deqSelOH_0_valid),
    .io_deqSelOH_0_bits(io_deqSelOH_0_bits),
    .io_enqEntryOldestSel_0_bits(io_enqEntryOldestSel_0_bits),
    .io_simpEntryOldestSel_0_valid(io_simpEntryOldestSel_0_valid),
    .io_simpEntryOldestSel_0_bits(io_simpEntryOldestSel_0_bits),
    .io_compEntryOldestSel_0_valid(io_compEntryOldestSel_0_valid),
    .io_compEntryOldestSel_0_bits(io_compEntryOldestSel_0_bits),
    .io_wakeUpFromWB_15_valid(io_wakeUpFromWB_15_valid),
    .io_wakeUpFromWB_15_bits_vlWen(io_wakeUpFromWB_15_bits_vlWen),
    .io_wakeUpFromWB_15_bits_pdest(io_wakeUpFromWB_15_bits_pdest),
    .io_wakeUpFromWB_14_valid(io_wakeUpFromWB_14_valid),
    .io_wakeUpFromWB_14_bits_vlWen(io_wakeUpFromWB_14_bits_vlWen),
    .io_wakeUpFromWB_14_bits_pdest(io_wakeUpFromWB_14_bits_pdest),
    .io_wakeUpFromWB_13_valid(io_wakeUpFromWB_13_valid),
    .io_wakeUpFromWB_13_bits_vlWen(io_wakeUpFromWB_13_bits_vlWen),
    .io_wakeUpFromWB_13_bits_pdest(io_wakeUpFromWB_13_bits_pdest),
    .io_wakeUpFromWB_12_valid(io_wakeUpFromWB_12_valid),
    .io_wakeUpFromWB_12_bits_vlWen(io_wakeUpFromWB_12_bits_vlWen),
    .io_wakeUpFromWB_12_bits_pdest(io_wakeUpFromWB_12_bits_pdest),
    .io_wakeUpFromWB_11_valid(io_wakeUpFromWB_11_valid),
    .io_wakeUpFromWB_11_bits_v0Wen(io_wakeUpFromWB_11_bits_v0Wen),
    .io_wakeUpFromWB_11_bits_pdest(io_wakeUpFromWB_11_bits_pdest),
    .io_wakeUpFromWB_10_valid(io_wakeUpFromWB_10_valid),
    .io_wakeUpFromWB_10_bits_v0Wen(io_wakeUpFromWB_10_bits_v0Wen),
    .io_wakeUpFromWB_10_bits_pdest(io_wakeUpFromWB_10_bits_pdest),
    .io_wakeUpFromWB_9_valid(io_wakeUpFromWB_9_valid),
    .io_wakeUpFromWB_9_bits_v0Wen(io_wakeUpFromWB_9_bits_v0Wen),
    .io_wakeUpFromWB_9_bits_pdest(io_wakeUpFromWB_9_bits_pdest),
    .io_wakeUpFromWB_8_valid(io_wakeUpFromWB_8_valid),
    .io_wakeUpFromWB_8_bits_v0Wen(io_wakeUpFromWB_8_bits_v0Wen),
    .io_wakeUpFromWB_8_bits_pdest(io_wakeUpFromWB_8_bits_pdest),
    .io_wakeUpFromWB_7_valid(io_wakeUpFromWB_7_valid),
    .io_wakeUpFromWB_7_bits_v0Wen(io_wakeUpFromWB_7_bits_v0Wen),
    .io_wakeUpFromWB_7_bits_pdest(io_wakeUpFromWB_7_bits_pdest),
    .io_wakeUpFromWB_6_valid(io_wakeUpFromWB_6_valid),
    .io_wakeUpFromWB_6_bits_v0Wen(io_wakeUpFromWB_6_bits_v0Wen),
    .io_wakeUpFromWB_6_bits_pdest(io_wakeUpFromWB_6_bits_pdest),
    .io_wakeUpFromWB_5_valid(io_wakeUpFromWB_5_valid),
    .io_wakeUpFromWB_5_bits_vecWen(io_wakeUpFromWB_5_bits_vecWen),
    .io_wakeUpFromWB_5_bits_pdest(io_wakeUpFromWB_5_bits_pdest),
    .io_wakeUpFromWB_4_valid(io_wakeUpFromWB_4_valid),
    .io_wakeUpFromWB_4_bits_vecWen(io_wakeUpFromWB_4_bits_vecWen),
    .io_wakeUpFromWB_4_bits_pdest(io_wakeUpFromWB_4_bits_pdest),
    .io_wakeUpFromWB_3_valid(io_wakeUpFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_vecWen(io_wakeUpFromWB_3_bits_vecWen),
    .io_wakeUpFromWB_3_bits_pdest(io_wakeUpFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid(io_wakeUpFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_vecWen(io_wakeUpFromWB_2_bits_vecWen),
    .io_wakeUpFromWB_2_bits_pdest(io_wakeUpFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid(io_wakeUpFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_vecWen(io_wakeUpFromWB_1_bits_vecWen),
    .io_wakeUpFromWB_1_bits_pdest(io_wakeUpFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid(io_wakeUpFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_vecWen(io_wakeUpFromWB_0_bits_vecWen),
    .io_wakeUpFromWB_0_bits_pdest(io_wakeUpFromWB_0_bits_pdest),
    .io_wakeUpFromWBDelayed_15_valid(io_wakeUpFromWBDelayed_15_valid),
    .io_wakeUpFromWBDelayed_15_bits_vlWen(io_wakeUpFromWBDelayed_15_bits_vlWen),
    .io_wakeUpFromWBDelayed_15_bits_pdest(io_wakeUpFromWBDelayed_15_bits_pdest),
    .io_wakeUpFromWBDelayed_14_valid(io_wakeUpFromWBDelayed_14_valid),
    .io_wakeUpFromWBDelayed_14_bits_vlWen(io_wakeUpFromWBDelayed_14_bits_vlWen),
    .io_wakeUpFromWBDelayed_14_bits_pdest(io_wakeUpFromWBDelayed_14_bits_pdest),
    .io_wakeUpFromWBDelayed_13_valid(io_wakeUpFromWBDelayed_13_valid),
    .io_wakeUpFromWBDelayed_13_bits_vlWen(io_wakeUpFromWBDelayed_13_bits_vlWen),
    .io_wakeUpFromWBDelayed_13_bits_pdest(io_wakeUpFromWBDelayed_13_bits_pdest),
    .io_wakeUpFromWBDelayed_12_valid(io_wakeUpFromWBDelayed_12_valid),
    .io_wakeUpFromWBDelayed_12_bits_vlWen(io_wakeUpFromWBDelayed_12_bits_vlWen),
    .io_wakeUpFromWBDelayed_12_bits_pdest(io_wakeUpFromWBDelayed_12_bits_pdest),
    .io_wakeUpFromWBDelayed_11_valid(io_wakeUpFromWBDelayed_11_valid),
    .io_wakeUpFromWBDelayed_11_bits_v0Wen(io_wakeUpFromWBDelayed_11_bits_v0Wen),
    .io_wakeUpFromWBDelayed_11_bits_pdest(io_wakeUpFromWBDelayed_11_bits_pdest),
    .io_wakeUpFromWBDelayed_10_valid(io_wakeUpFromWBDelayed_10_valid),
    .io_wakeUpFromWBDelayed_10_bits_v0Wen(io_wakeUpFromWBDelayed_10_bits_v0Wen),
    .io_wakeUpFromWBDelayed_10_bits_pdest(io_wakeUpFromWBDelayed_10_bits_pdest),
    .io_wakeUpFromWBDelayed_9_valid(io_wakeUpFromWBDelayed_9_valid),
    .io_wakeUpFromWBDelayed_9_bits_v0Wen(io_wakeUpFromWBDelayed_9_bits_v0Wen),
    .io_wakeUpFromWBDelayed_9_bits_pdest(io_wakeUpFromWBDelayed_9_bits_pdest),
    .io_wakeUpFromWBDelayed_8_valid(io_wakeUpFromWBDelayed_8_valid),
    .io_wakeUpFromWBDelayed_8_bits_v0Wen(io_wakeUpFromWBDelayed_8_bits_v0Wen),
    .io_wakeUpFromWBDelayed_8_bits_pdest(io_wakeUpFromWBDelayed_8_bits_pdest),
    .io_wakeUpFromWBDelayed_7_valid(io_wakeUpFromWBDelayed_7_valid),
    .io_wakeUpFromWBDelayed_7_bits_v0Wen(io_wakeUpFromWBDelayed_7_bits_v0Wen),
    .io_wakeUpFromWBDelayed_7_bits_pdest(io_wakeUpFromWBDelayed_7_bits_pdest),
    .io_wakeUpFromWBDelayed_6_valid(io_wakeUpFromWBDelayed_6_valid),
    .io_wakeUpFromWBDelayed_6_bits_v0Wen(io_wakeUpFromWBDelayed_6_bits_v0Wen),
    .io_wakeUpFromWBDelayed_6_bits_pdest(io_wakeUpFromWBDelayed_6_bits_pdest),
    .io_wakeUpFromWBDelayed_5_valid(io_wakeUpFromWBDelayed_5_valid),
    .io_wakeUpFromWBDelayed_5_bits_vecWen(io_wakeUpFromWBDelayed_5_bits_vecWen),
    .io_wakeUpFromWBDelayed_5_bits_pdest(io_wakeUpFromWBDelayed_5_bits_pdest),
    .io_wakeUpFromWBDelayed_4_valid(io_wakeUpFromWBDelayed_4_valid),
    .io_wakeUpFromWBDelayed_4_bits_vecWen(io_wakeUpFromWBDelayed_4_bits_vecWen),
    .io_wakeUpFromWBDelayed_4_bits_pdest(io_wakeUpFromWBDelayed_4_bits_pdest),
    .io_wakeUpFromWBDelayed_3_valid(io_wakeUpFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_vecWen(io_wakeUpFromWBDelayed_3_bits_vecWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest(io_wakeUpFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid(io_wakeUpFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_vecWen(io_wakeUpFromWBDelayed_2_bits_vecWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest(io_wakeUpFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid(io_wakeUpFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_vecWen(io_wakeUpFromWBDelayed_1_bits_vecWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest(io_wakeUpFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid(io_wakeUpFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_vecWen(io_wakeUpFromWBDelayed_0_bits_vecWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest(io_wakeUpFromWBDelayed_0_bits_pdest),
    .io_vlFromIntIsZero(io_vlFromIntIsZero),
    .io_vlFromIntIsVlmax(io_vlFromIntIsVlmax),
    .io_vlFromVfIsZero(io_vlFromVfIsZero),
    .io_vlFromVfIsVlmax(io_vlFromVfIsVlmax),
    .io_simpEntryDeqSelVec_0(io_simpEntryDeqSelVec_0),
    .io_simpEntryDeqSelVec_1(io_simpEntryDeqSelVec_1),
    .io_valid(g_io_valid),
    .io_issued(g_io_issued),
    .io_canIssue(g_io_canIssue),
    .io_fuType_0(g_io_fuType_0),
    .io_fuType_1(g_io_fuType_1),
    .io_fuType_2(g_io_fuType_2),
    .io_fuType_3(g_io_fuType_3),
    .io_fuType_4(g_io_fuType_4),
    .io_fuType_5(g_io_fuType_5),
    .io_fuType_6(g_io_fuType_6),
    .io_fuType_7(g_io_fuType_7),
    .io_fuType_8(g_io_fuType_8),
    .io_fuType_9(g_io_fuType_9),
    .io_dataSources_0_0_value(g_io_dataSources_0_0_value),
    .io_dataSources_0_1_value(g_io_dataSources_0_1_value),
    .io_dataSources_0_2_value(g_io_dataSources_0_2_value),
    .io_dataSources_0_3_value(g_io_dataSources_0_3_value),
    .io_dataSources_0_4_value(g_io_dataSources_0_4_value),
    .io_dataSources_1_0_value(g_io_dataSources_1_0_value),
    .io_dataSources_1_1_value(g_io_dataSources_1_1_value),
    .io_dataSources_1_2_value(g_io_dataSources_1_2_value),
    .io_dataSources_1_3_value(g_io_dataSources_1_3_value),
    .io_dataSources_1_4_value(g_io_dataSources_1_4_value),
    .io_dataSources_2_0_value(g_io_dataSources_2_0_value),
    .io_dataSources_2_1_value(g_io_dataSources_2_1_value),
    .io_dataSources_2_2_value(g_io_dataSources_2_2_value),
    .io_dataSources_2_3_value(g_io_dataSources_2_3_value),
    .io_dataSources_2_4_value(g_io_dataSources_2_4_value),
    .io_dataSources_3_0_value(g_io_dataSources_3_0_value),
    .io_dataSources_3_1_value(g_io_dataSources_3_1_value),
    .io_dataSources_3_2_value(g_io_dataSources_3_2_value),
    .io_dataSources_3_3_value(g_io_dataSources_3_3_value),
    .io_dataSources_3_4_value(g_io_dataSources_3_4_value),
    .io_dataSources_4_0_value(g_io_dataSources_4_0_value),
    .io_dataSources_4_1_value(g_io_dataSources_4_1_value),
    .io_dataSources_4_2_value(g_io_dataSources_4_2_value),
    .io_dataSources_4_3_value(g_io_dataSources_4_3_value),
    .io_dataSources_4_4_value(g_io_dataSources_4_4_value),
    .io_dataSources_5_0_value(g_io_dataSources_5_0_value),
    .io_dataSources_5_1_value(g_io_dataSources_5_1_value),
    .io_dataSources_5_2_value(g_io_dataSources_5_2_value),
    .io_dataSources_5_3_value(g_io_dataSources_5_3_value),
    .io_dataSources_5_4_value(g_io_dataSources_5_4_value),
    .io_dataSources_6_0_value(g_io_dataSources_6_0_value),
    .io_dataSources_6_1_value(g_io_dataSources_6_1_value),
    .io_dataSources_6_2_value(g_io_dataSources_6_2_value),
    .io_dataSources_6_3_value(g_io_dataSources_6_3_value),
    .io_dataSources_6_4_value(g_io_dataSources_6_4_value),
    .io_dataSources_7_0_value(g_io_dataSources_7_0_value),
    .io_dataSources_7_1_value(g_io_dataSources_7_1_value),
    .io_dataSources_7_2_value(g_io_dataSources_7_2_value),
    .io_dataSources_7_3_value(g_io_dataSources_7_3_value),
    .io_dataSources_7_4_value(g_io_dataSources_7_4_value),
    .io_dataSources_8_0_value(g_io_dataSources_8_0_value),
    .io_dataSources_8_1_value(g_io_dataSources_8_1_value),
    .io_dataSources_8_2_value(g_io_dataSources_8_2_value),
    .io_dataSources_8_3_value(g_io_dataSources_8_3_value),
    .io_dataSources_8_4_value(g_io_dataSources_8_4_value),
    .io_dataSources_9_0_value(g_io_dataSources_9_0_value),
    .io_dataSources_9_1_value(g_io_dataSources_9_1_value),
    .io_dataSources_9_2_value(g_io_dataSources_9_2_value),
    .io_dataSources_9_3_value(g_io_dataSources_9_3_value),
    .io_dataSources_9_4_value(g_io_dataSources_9_4_value),
    .io_isFirstIssue_0(g_io_isFirstIssue_0),
    .io_deqEntry_0_bits_status_robIdx_flag(g_io_deqEntry_0_bits_status_robIdx_flag),
    .io_deqEntry_0_bits_status_robIdx_value(g_io_deqEntry_0_bits_status_robIdx_value),
    .io_deqEntry_0_bits_status_fuType_22(g_io_deqEntry_0_bits_status_fuType_22),
    .io_deqEntry_0_bits_status_fuType_26(g_io_deqEntry_0_bits_status_fuType_26),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc(g_io_deqEntry_0_bits_status_srcStatus_0_psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType(g_io_deqEntry_0_bits_status_srcStatus_0_srcType),
    .io_deqEntry_0_bits_status_srcStatus_1_psrc(g_io_deqEntry_0_bits_status_srcStatus_1_psrc),
    .io_deqEntry_0_bits_status_srcStatus_1_srcType(g_io_deqEntry_0_bits_status_srcStatus_1_srcType),
    .io_deqEntry_0_bits_status_srcStatus_2_psrc(g_io_deqEntry_0_bits_status_srcStatus_2_psrc),
    .io_deqEntry_0_bits_status_srcStatus_2_srcType(g_io_deqEntry_0_bits_status_srcStatus_2_srcType),
    .io_deqEntry_0_bits_status_srcStatus_3_psrc(g_io_deqEntry_0_bits_status_srcStatus_3_psrc),
    .io_deqEntry_0_bits_status_srcStatus_3_srcType(g_io_deqEntry_0_bits_status_srcStatus_3_srcType),
    .io_deqEntry_0_bits_status_srcStatus_4_psrc(g_io_deqEntry_0_bits_status_srcStatus_4_psrc),
    .io_deqEntry_0_bits_status_srcStatus_4_srcType(g_io_deqEntry_0_bits_status_srcStatus_4_srcType),
    .io_deqEntry_0_bits_payload_fuOpType(g_io_deqEntry_0_bits_payload_fuOpType),
    .io_deqEntry_0_bits_payload_vecWen(g_io_deqEntry_0_bits_payload_vecWen),
    .io_deqEntry_0_bits_payload_v0Wen(g_io_deqEntry_0_bits_payload_v0Wen),
    .io_deqEntry_0_bits_payload_selImm(g_io_deqEntry_0_bits_payload_selImm),
    .io_deqEntry_0_bits_payload_fpu_typeTagOut(g_io_deqEntry_0_bits_payload_fpu_typeTagOut),
    .io_deqEntry_0_bits_payload_fpu_wflags(g_io_deqEntry_0_bits_payload_fpu_wflags),
    .io_deqEntry_0_bits_payload_fpu_typ(g_io_deqEntry_0_bits_payload_fpu_typ),
    .io_deqEntry_0_bits_payload_fpu_fmt(g_io_deqEntry_0_bits_payload_fpu_fmt),
    .io_deqEntry_0_bits_payload_fpu_rm(g_io_deqEntry_0_bits_payload_fpu_rm),
    .io_deqEntry_0_bits_payload_vpu_vill(g_io_deqEntry_0_bits_payload_vpu_vill),
    .io_deqEntry_0_bits_payload_vpu_vma(g_io_deqEntry_0_bits_payload_vpu_vma),
    .io_deqEntry_0_bits_payload_vpu_vta(g_io_deqEntry_0_bits_payload_vpu_vta),
    .io_deqEntry_0_bits_payload_vpu_vsew(g_io_deqEntry_0_bits_payload_vpu_vsew),
    .io_deqEntry_0_bits_payload_vpu_vlmul(g_io_deqEntry_0_bits_payload_vpu_vlmul),
    .io_deqEntry_0_bits_payload_vpu_specVill(g_io_deqEntry_0_bits_payload_vpu_specVill),
    .io_deqEntry_0_bits_payload_vpu_specVma(g_io_deqEntry_0_bits_payload_vpu_specVma),
    .io_deqEntry_0_bits_payload_vpu_specVta(g_io_deqEntry_0_bits_payload_vpu_specVta),
    .io_deqEntry_0_bits_payload_vpu_specVsew(g_io_deqEntry_0_bits_payload_vpu_specVsew),
    .io_deqEntry_0_bits_payload_vpu_specVlmul(g_io_deqEntry_0_bits_payload_vpu_specVlmul),
    .io_deqEntry_0_bits_payload_vpu_vm(g_io_deqEntry_0_bits_payload_vpu_vm),
    .io_deqEntry_0_bits_payload_vpu_vstart(g_io_deqEntry_0_bits_payload_vpu_vstart),
    .io_deqEntry_0_bits_payload_vpu_frm(g_io_deqEntry_0_bits_payload_vpu_frm),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst(g_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr(g_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr(g_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isReduction(g_io_deqEntry_0_bits_payload_vpu_fpu_isReduction),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2(g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4(g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8(g_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_deqEntry_0_bits_payload_vpu_vxrm(g_io_deqEntry_0_bits_payload_vpu_vxrm),
    .io_deqEntry_0_bits_payload_vpu_vmask(g_io_deqEntry_0_bits_payload_vpu_vmask),
    .io_deqEntry_0_bits_payload_vpu_vl(g_io_deqEntry_0_bits_payload_vpu_vl),
    .io_deqEntry_0_bits_payload_vpu_nf(g_io_deqEntry_0_bits_payload_vpu_nf),
    .io_deqEntry_0_bits_payload_vpu_veew(g_io_deqEntry_0_bits_payload_vpu_veew),
    .io_deqEntry_0_bits_payload_vpu_isReverse(g_io_deqEntry_0_bits_payload_vpu_isReverse),
    .io_deqEntry_0_bits_payload_vpu_isExt(g_io_deqEntry_0_bits_payload_vpu_isExt),
    .io_deqEntry_0_bits_payload_vpu_isNarrow(g_io_deqEntry_0_bits_payload_vpu_isNarrow),
    .io_deqEntry_0_bits_payload_vpu_isDstMask(g_io_deqEntry_0_bits_payload_vpu_isDstMask),
    .io_deqEntry_0_bits_payload_vpu_isOpMask(g_io_deqEntry_0_bits_payload_vpu_isOpMask),
    .io_deqEntry_0_bits_payload_vpu_isMove(g_io_deqEntry_0_bits_payload_vpu_isMove),
    .io_deqEntry_0_bits_payload_vpu_isDependOldVd(g_io_deqEntry_0_bits_payload_vpu_isDependOldVd),
    .io_deqEntry_0_bits_payload_vpu_isWritePartVd(g_io_deqEntry_0_bits_payload_vpu_isWritePartVd),
    .io_deqEntry_0_bits_payload_vpu_isVleff(g_io_deqEntry_0_bits_payload_vpu_isVleff),
    .io_deqEntry_0_bits_payload_uopIdx(g_io_deqEntry_0_bits_payload_uopIdx),
    .io_deqEntry_0_bits_payload_lastUop(g_io_deqEntry_0_bits_payload_lastUop),
    .io_deqEntry_0_bits_payload_pdest(g_io_deqEntry_0_bits_payload_pdest),
    .io_deqEntry_0_bits_payload_debugInfo_eliminatedMove(g_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove),
    .io_deqEntry_0_bits_payload_debugInfo_renameTime(g_io_deqEntry_0_bits_payload_debugInfo_renameTime),
    .io_deqEntry_0_bits_payload_debugInfo_dispatchTime(g_io_deqEntry_0_bits_payload_debugInfo_dispatchTime),
    .io_deqEntry_0_bits_payload_debugInfo_enqRsTime(g_io_deqEntry_0_bits_payload_debugInfo_enqRsTime),
    .io_deqEntry_0_bits_payload_debugInfo_writebackTime(g_io_deqEntry_0_bits_payload_debugInfo_writebackTime),
    .io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id(g_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime(g_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime),
    .io_deqEntry_0_bits_payload_debugInfo_tlbRespTime(g_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime),
    .io_deqEntry_0_bits_payload_debug_seqNum_seqNum(g_io_deqEntry_0_bits_payload_debug_seqNum_seqNum),
    .io_deqEntry_0_bits_payload_debug_seqNum_uopIdx(g_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx),
    .io_simpEntryEnqSelVec_0(g_io_simpEntryEnqSelVec_0),
    .io_simpEntryEnqSelVec_1(g_io_simpEntryEnqSelVec_1),
    .io_compEntryEnqSelVec_0(g_io_compEntryEnqSelVec_0),
    .io_compEntryEnqSelVec_1(g_io_compEntryEnqSelVec_1)
  );

  EntriesVfdivVidiv_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_status_robIdx_flag(io_enq_0_bits_status_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value(io_enq_0_bits_status_robIdx_value),
    .io_enq_0_bits_status_fuType_22(io_enq_0_bits_status_fuType_22),
    .io_enq_0_bits_status_fuType_26(io_enq_0_bits_status_fuType_26),
    .io_enq_0_bits_status_srcStatus_0_psrc(io_enq_0_bits_status_srcStatus_0_psrc),
    .io_enq_0_bits_status_srcStatus_0_srcType(io_enq_0_bits_status_srcStatus_0_srcType),
    .io_enq_0_bits_status_srcStatus_0_srcState(io_enq_0_bits_status_srcStatus_0_srcState),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value(io_enq_0_bits_status_srcStatus_0_dataSources_value),
    .io_enq_0_bits_status_srcStatus_1_psrc(io_enq_0_bits_status_srcStatus_1_psrc),
    .io_enq_0_bits_status_srcStatus_1_srcType(io_enq_0_bits_status_srcStatus_1_srcType),
    .io_enq_0_bits_status_srcStatus_1_srcState(io_enq_0_bits_status_srcStatus_1_srcState),
    .io_enq_0_bits_status_srcStatus_1_dataSources_value(io_enq_0_bits_status_srcStatus_1_dataSources_value),
    .io_enq_0_bits_status_srcStatus_2_psrc(io_enq_0_bits_status_srcStatus_2_psrc),
    .io_enq_0_bits_status_srcStatus_2_srcType(io_enq_0_bits_status_srcStatus_2_srcType),
    .io_enq_0_bits_status_srcStatus_2_srcState(io_enq_0_bits_status_srcStatus_2_srcState),
    .io_enq_0_bits_status_srcStatus_2_dataSources_value(io_enq_0_bits_status_srcStatus_2_dataSources_value),
    .io_enq_0_bits_status_srcStatus_3_psrc(io_enq_0_bits_status_srcStatus_3_psrc),
    .io_enq_0_bits_status_srcStatus_3_srcType(io_enq_0_bits_status_srcStatus_3_srcType),
    .io_enq_0_bits_status_srcStatus_3_srcState(io_enq_0_bits_status_srcStatus_3_srcState),
    .io_enq_0_bits_status_srcStatus_3_dataSources_value(io_enq_0_bits_status_srcStatus_3_dataSources_value),
    .io_enq_0_bits_status_srcStatus_4_psrc(io_enq_0_bits_status_srcStatus_4_psrc),
    .io_enq_0_bits_status_srcStatus_4_srcType(io_enq_0_bits_status_srcStatus_4_srcType),
    .io_enq_0_bits_status_srcStatus_4_srcState(io_enq_0_bits_status_srcStatus_4_srcState),
    .io_enq_0_bits_status_srcStatus_4_dataSources_value(io_enq_0_bits_status_srcStatus_4_dataSources_value),
    .io_enq_0_bits_payload_instr(io_enq_0_bits_payload_instr),
    .io_enq_0_bits_payload_pc(io_enq_0_bits_payload_pc),
    .io_enq_0_bits_payload_foldpc(io_enq_0_bits_payload_foldpc),
    .io_enq_0_bits_payload_exceptionVec_0(io_enq_0_bits_payload_exceptionVec_0),
    .io_enq_0_bits_payload_exceptionVec_1(io_enq_0_bits_payload_exceptionVec_1),
    .io_enq_0_bits_payload_exceptionVec_2(io_enq_0_bits_payload_exceptionVec_2),
    .io_enq_0_bits_payload_exceptionVec_3(io_enq_0_bits_payload_exceptionVec_3),
    .io_enq_0_bits_payload_exceptionVec_4(io_enq_0_bits_payload_exceptionVec_4),
    .io_enq_0_bits_payload_exceptionVec_5(io_enq_0_bits_payload_exceptionVec_5),
    .io_enq_0_bits_payload_exceptionVec_6(io_enq_0_bits_payload_exceptionVec_6),
    .io_enq_0_bits_payload_exceptionVec_7(io_enq_0_bits_payload_exceptionVec_7),
    .io_enq_0_bits_payload_exceptionVec_8(io_enq_0_bits_payload_exceptionVec_8),
    .io_enq_0_bits_payload_exceptionVec_9(io_enq_0_bits_payload_exceptionVec_9),
    .io_enq_0_bits_payload_exceptionVec_10(io_enq_0_bits_payload_exceptionVec_10),
    .io_enq_0_bits_payload_exceptionVec_11(io_enq_0_bits_payload_exceptionVec_11),
    .io_enq_0_bits_payload_exceptionVec_12(io_enq_0_bits_payload_exceptionVec_12),
    .io_enq_0_bits_payload_exceptionVec_13(io_enq_0_bits_payload_exceptionVec_13),
    .io_enq_0_bits_payload_exceptionVec_14(io_enq_0_bits_payload_exceptionVec_14),
    .io_enq_0_bits_payload_exceptionVec_15(io_enq_0_bits_payload_exceptionVec_15),
    .io_enq_0_bits_payload_exceptionVec_16(io_enq_0_bits_payload_exceptionVec_16),
    .io_enq_0_bits_payload_exceptionVec_17(io_enq_0_bits_payload_exceptionVec_17),
    .io_enq_0_bits_payload_exceptionVec_18(io_enq_0_bits_payload_exceptionVec_18),
    .io_enq_0_bits_payload_exceptionVec_19(io_enq_0_bits_payload_exceptionVec_19),
    .io_enq_0_bits_payload_exceptionVec_20(io_enq_0_bits_payload_exceptionVec_20),
    .io_enq_0_bits_payload_exceptionVec_21(io_enq_0_bits_payload_exceptionVec_21),
    .io_enq_0_bits_payload_exceptionVec_22(io_enq_0_bits_payload_exceptionVec_22),
    .io_enq_0_bits_payload_exceptionVec_23(io_enq_0_bits_payload_exceptionVec_23),
    .io_enq_0_bits_payload_isFetchMalAddr(io_enq_0_bits_payload_isFetchMalAddr),
    .io_enq_0_bits_payload_hasException(io_enq_0_bits_payload_hasException),
    .io_enq_0_bits_payload_trigger(io_enq_0_bits_payload_trigger),
    .io_enq_0_bits_payload_preDecodeInfo_valid(io_enq_0_bits_payload_preDecodeInfo_valid),
    .io_enq_0_bits_payload_preDecodeInfo_isRVC(io_enq_0_bits_payload_preDecodeInfo_isRVC),
    .io_enq_0_bits_payload_preDecodeInfo_brType(io_enq_0_bits_payload_preDecodeInfo_brType),
    .io_enq_0_bits_payload_preDecodeInfo_isCall(io_enq_0_bits_payload_preDecodeInfo_isCall),
    .io_enq_0_bits_payload_preDecodeInfo_isRet(io_enq_0_bits_payload_preDecodeInfo_isRet),
    .io_enq_0_bits_payload_pred_taken(io_enq_0_bits_payload_pred_taken),
    .io_enq_0_bits_payload_crossPageIPFFix(io_enq_0_bits_payload_crossPageIPFFix),
    .io_enq_0_bits_payload_ftqPtr_flag(io_enq_0_bits_payload_ftqPtr_flag),
    .io_enq_0_bits_payload_ftqPtr_value(io_enq_0_bits_payload_ftqPtr_value),
    .io_enq_0_bits_payload_ftqOffset(io_enq_0_bits_payload_ftqOffset),
    .io_enq_0_bits_payload_satpFlushFirstFetchFault(io_enq_0_bits_payload_satpFlushFirstFetchFault),
    .io_enq_0_bits_payload_srcType_0(io_enq_0_bits_payload_srcType_0),
    .io_enq_0_bits_payload_srcType_1(io_enq_0_bits_payload_srcType_1),
    .io_enq_0_bits_payload_srcType_2(io_enq_0_bits_payload_srcType_2),
    .io_enq_0_bits_payload_srcType_3(io_enq_0_bits_payload_srcType_3),
    .io_enq_0_bits_payload_srcType_4(io_enq_0_bits_payload_srcType_4),
    .io_enq_0_bits_payload_ldest(io_enq_0_bits_payload_ldest),
    .io_enq_0_bits_payload_fuType(io_enq_0_bits_payload_fuType),
    .io_enq_0_bits_payload_fuOpType(io_enq_0_bits_payload_fuOpType),
    .io_enq_0_bits_payload_rfWen(io_enq_0_bits_payload_rfWen),
    .io_enq_0_bits_payload_fpWen(io_enq_0_bits_payload_fpWen),
    .io_enq_0_bits_payload_vecWen(io_enq_0_bits_payload_vecWen),
    .io_enq_0_bits_payload_v0Wen(io_enq_0_bits_payload_v0Wen),
    .io_enq_0_bits_payload_vlWen(io_enq_0_bits_payload_vlWen),
    .io_enq_0_bits_payload_isXSTrap(io_enq_0_bits_payload_isXSTrap),
    .io_enq_0_bits_payload_waitForward(io_enq_0_bits_payload_waitForward),
    .io_enq_0_bits_payload_blockBackward(io_enq_0_bits_payload_blockBackward),
    .io_enq_0_bits_payload_flushPipe(io_enq_0_bits_payload_flushPipe),
    .io_enq_0_bits_payload_canRobCompress(io_enq_0_bits_payload_canRobCompress),
    .io_enq_0_bits_payload_selImm(io_enq_0_bits_payload_selImm),
    .io_enq_0_bits_payload_imm(io_enq_0_bits_payload_imm),
    .io_enq_0_bits_payload_fpu_typeTagOut(io_enq_0_bits_payload_fpu_typeTagOut),
    .io_enq_0_bits_payload_fpu_wflags(io_enq_0_bits_payload_fpu_wflags),
    .io_enq_0_bits_payload_fpu_typ(io_enq_0_bits_payload_fpu_typ),
    .io_enq_0_bits_payload_fpu_fmt(io_enq_0_bits_payload_fpu_fmt),
    .io_enq_0_bits_payload_fpu_rm(io_enq_0_bits_payload_fpu_rm),
    .io_enq_0_bits_payload_vpu_vill(io_enq_0_bits_payload_vpu_vill),
    .io_enq_0_bits_payload_vpu_vma(io_enq_0_bits_payload_vpu_vma),
    .io_enq_0_bits_payload_vpu_vta(io_enq_0_bits_payload_vpu_vta),
    .io_enq_0_bits_payload_vpu_vsew(io_enq_0_bits_payload_vpu_vsew),
    .io_enq_0_bits_payload_vpu_vlmul(io_enq_0_bits_payload_vpu_vlmul),
    .io_enq_0_bits_payload_vpu_specVill(io_enq_0_bits_payload_vpu_specVill),
    .io_enq_0_bits_payload_vpu_specVma(io_enq_0_bits_payload_vpu_specVma),
    .io_enq_0_bits_payload_vpu_specVta(io_enq_0_bits_payload_vpu_specVta),
    .io_enq_0_bits_payload_vpu_specVsew(io_enq_0_bits_payload_vpu_specVsew),
    .io_enq_0_bits_payload_vpu_specVlmul(io_enq_0_bits_payload_vpu_specVlmul),
    .io_enq_0_bits_payload_vpu_vm(io_enq_0_bits_payload_vpu_vm),
    .io_enq_0_bits_payload_vpu_vstart(io_enq_0_bits_payload_vpu_vstart),
    .io_enq_0_bits_payload_vpu_frm(io_enq_0_bits_payload_vpu_frm),
    .io_enq_0_bits_payload_vpu_fpu_isFpToVecInst(io_enq_0_bits_payload_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_payload_vpu_fpu_isFP32Instr(io_enq_0_bits_payload_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_payload_vpu_fpu_isFP64Instr(io_enq_0_bits_payload_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_payload_vpu_fpu_isReduction(io_enq_0_bits_payload_vpu_fpu_isReduction),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8(io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_payload_vpu_vxrm(io_enq_0_bits_payload_vpu_vxrm),
    .io_enq_0_bits_payload_vpu_vuopIdx(io_enq_0_bits_payload_vpu_vuopIdx),
    .io_enq_0_bits_payload_vpu_lastUop(io_enq_0_bits_payload_vpu_lastUop),
    .io_enq_0_bits_payload_vpu_vmask(io_enq_0_bits_payload_vpu_vmask),
    .io_enq_0_bits_payload_vpu_vl(io_enq_0_bits_payload_vpu_vl),
    .io_enq_0_bits_payload_vpu_nf(io_enq_0_bits_payload_vpu_nf),
    .io_enq_0_bits_payload_vpu_veew(io_enq_0_bits_payload_vpu_veew),
    .io_enq_0_bits_payload_vpu_isReverse(io_enq_0_bits_payload_vpu_isReverse),
    .io_enq_0_bits_payload_vpu_isExt(io_enq_0_bits_payload_vpu_isExt),
    .io_enq_0_bits_payload_vpu_isNarrow(io_enq_0_bits_payload_vpu_isNarrow),
    .io_enq_0_bits_payload_vpu_isDstMask(io_enq_0_bits_payload_vpu_isDstMask),
    .io_enq_0_bits_payload_vpu_isOpMask(io_enq_0_bits_payload_vpu_isOpMask),
    .io_enq_0_bits_payload_vpu_isMove(io_enq_0_bits_payload_vpu_isMove),
    .io_enq_0_bits_payload_vpu_isDependOldVd(io_enq_0_bits_payload_vpu_isDependOldVd),
    .io_enq_0_bits_payload_vpu_isWritePartVd(io_enq_0_bits_payload_vpu_isWritePartVd),
    .io_enq_0_bits_payload_vpu_isVleff(io_enq_0_bits_payload_vpu_isVleff),
    .io_enq_0_bits_payload_vlsInstr(io_enq_0_bits_payload_vlsInstr),
    .io_enq_0_bits_payload_wfflags(io_enq_0_bits_payload_wfflags),
    .io_enq_0_bits_payload_isMove(io_enq_0_bits_payload_isMove),
    .io_enq_0_bits_payload_isDropAmocasSta(io_enq_0_bits_payload_isDropAmocasSta),
    .io_enq_0_bits_payload_uopIdx(io_enq_0_bits_payload_uopIdx),
    .io_enq_0_bits_payload_isVset(io_enq_0_bits_payload_isVset),
    .io_enq_0_bits_payload_firstUop(io_enq_0_bits_payload_firstUop),
    .io_enq_0_bits_payload_lastUop(io_enq_0_bits_payload_lastUop),
    .io_enq_0_bits_payload_numUops(io_enq_0_bits_payload_numUops),
    .io_enq_0_bits_payload_numWB(io_enq_0_bits_payload_numWB),
    .io_enq_0_bits_payload_commitType(io_enq_0_bits_payload_commitType),
    .io_enq_0_bits_payload_srcState_0(io_enq_0_bits_payload_srcState_0),
    .io_enq_0_bits_payload_srcState_1(io_enq_0_bits_payload_srcState_1),
    .io_enq_0_bits_payload_srcState_2(io_enq_0_bits_payload_srcState_2),
    .io_enq_0_bits_payload_srcState_3(io_enq_0_bits_payload_srcState_3),
    .io_enq_0_bits_payload_srcState_4(io_enq_0_bits_payload_srcState_4),
    .io_enq_0_bits_payload_psrc_0(io_enq_0_bits_payload_psrc_0),
    .io_enq_0_bits_payload_psrc_1(io_enq_0_bits_payload_psrc_1),
    .io_enq_0_bits_payload_psrc_2(io_enq_0_bits_payload_psrc_2),
    .io_enq_0_bits_payload_psrc_3(io_enq_0_bits_payload_psrc_3),
    .io_enq_0_bits_payload_psrc_4(io_enq_0_bits_payload_psrc_4),
    .io_enq_0_bits_payload_pdest(io_enq_0_bits_payload_pdest),
    .io_enq_0_bits_payload_useRegCache_0(io_enq_0_bits_payload_useRegCache_0),
    .io_enq_0_bits_payload_useRegCache_1(io_enq_0_bits_payload_useRegCache_1),
    .io_enq_0_bits_payload_regCacheIdx_0(io_enq_0_bits_payload_regCacheIdx_0),
    .io_enq_0_bits_payload_regCacheIdx_1(io_enq_0_bits_payload_regCacheIdx_1),
    .io_enq_0_bits_payload_robIdx_flag(io_enq_0_bits_payload_robIdx_flag),
    .io_enq_0_bits_payload_robIdx_value(io_enq_0_bits_payload_robIdx_value),
    .io_enq_0_bits_payload_instrSize(io_enq_0_bits_payload_instrSize),
    .io_enq_0_bits_payload_dirtyFs(io_enq_0_bits_payload_dirtyFs),
    .io_enq_0_bits_payload_dirtyVs(io_enq_0_bits_payload_dirtyVs),
    .io_enq_0_bits_payload_traceBlockInPipe_itype(io_enq_0_bits_payload_traceBlockInPipe_itype),
    .io_enq_0_bits_payload_traceBlockInPipe_iretire(io_enq_0_bits_payload_traceBlockInPipe_iretire),
    .io_enq_0_bits_payload_traceBlockInPipe_ilastsize(io_enq_0_bits_payload_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_payload_eliminatedMove(io_enq_0_bits_payload_eliminatedMove),
    .io_enq_0_bits_payload_snapshot(io_enq_0_bits_payload_snapshot),
    .io_enq_0_bits_payload_debugInfo_eliminatedMove(io_enq_0_bits_payload_debugInfo_eliminatedMove),
    .io_enq_0_bits_payload_debugInfo_renameTime(io_enq_0_bits_payload_debugInfo_renameTime),
    .io_enq_0_bits_payload_debugInfo_dispatchTime(io_enq_0_bits_payload_debugInfo_dispatchTime),
    .io_enq_0_bits_payload_debugInfo_enqRsTime(io_enq_0_bits_payload_debugInfo_enqRsTime),
    .io_enq_0_bits_payload_debugInfo_selectTime(io_enq_0_bits_payload_debugInfo_selectTime),
    .io_enq_0_bits_payload_debugInfo_issueTime(io_enq_0_bits_payload_debugInfo_issueTime),
    .io_enq_0_bits_payload_debugInfo_writebackTime(io_enq_0_bits_payload_debugInfo_writebackTime),
    .io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id(io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_payload_debugInfo_tlbFirstReqTime(io_enq_0_bits_payload_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_payload_debugInfo_tlbRespTime(io_enq_0_bits_payload_debugInfo_tlbRespTime),
    .io_enq_0_bits_payload_debug_seqNum_seqNum(io_enq_0_bits_payload_debug_seqNum_seqNum),
    .io_enq_0_bits_payload_debug_seqNum_uopIdx(io_enq_0_bits_payload_debug_seqNum_uopIdx),
    .io_enq_0_bits_payload_storeSetHit(io_enq_0_bits_payload_storeSetHit),
    .io_enq_0_bits_payload_waitForRobIdx_flag(io_enq_0_bits_payload_waitForRobIdx_flag),
    .io_enq_0_bits_payload_waitForRobIdx_value(io_enq_0_bits_payload_waitForRobIdx_value),
    .io_enq_0_bits_payload_loadWaitBit(io_enq_0_bits_payload_loadWaitBit),
    .io_enq_0_bits_payload_loadWaitStrict(io_enq_0_bits_payload_loadWaitStrict),
    .io_enq_0_bits_payload_ssid(io_enq_0_bits_payload_ssid),
    .io_enq_0_bits_payload_lqIdx_flag(io_enq_0_bits_payload_lqIdx_flag),
    .io_enq_0_bits_payload_lqIdx_value(io_enq_0_bits_payload_lqIdx_value),
    .io_enq_0_bits_payload_sqIdx_flag(io_enq_0_bits_payload_sqIdx_flag),
    .io_enq_0_bits_payload_sqIdx_value(io_enq_0_bits_payload_sqIdx_value),
    .io_enq_0_bits_payload_singleStep(io_enq_0_bits_payload_singleStep),
    .io_enq_0_bits_payload_replayInst(io_enq_0_bits_payload_replayInst),
    .io_enq_0_bits_payload_debug_fuType(io_enq_0_bits_payload_debug_fuType),
    .io_enq_0_bits_payload_debug_sim_trig(io_enq_0_bits_payload_debug_sim_trig),
    .io_enq_0_bits_payload_numLsElem(io_enq_0_bits_payload_numLsElem),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_status_robIdx_flag(io_enq_1_bits_status_robIdx_flag),
    .io_enq_1_bits_status_robIdx_value(io_enq_1_bits_status_robIdx_value),
    .io_enq_1_bits_status_fuType_22(io_enq_1_bits_status_fuType_22),
    .io_enq_1_bits_status_fuType_26(io_enq_1_bits_status_fuType_26),
    .io_enq_1_bits_status_srcStatus_0_psrc(io_enq_1_bits_status_srcStatus_0_psrc),
    .io_enq_1_bits_status_srcStatus_0_srcType(io_enq_1_bits_status_srcStatus_0_srcType),
    .io_enq_1_bits_status_srcStatus_0_srcState(io_enq_1_bits_status_srcStatus_0_srcState),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value(io_enq_1_bits_status_srcStatus_0_dataSources_value),
    .io_enq_1_bits_status_srcStatus_1_psrc(io_enq_1_bits_status_srcStatus_1_psrc),
    .io_enq_1_bits_status_srcStatus_1_srcType(io_enq_1_bits_status_srcStatus_1_srcType),
    .io_enq_1_bits_status_srcStatus_1_srcState(io_enq_1_bits_status_srcStatus_1_srcState),
    .io_enq_1_bits_status_srcStatus_1_dataSources_value(io_enq_1_bits_status_srcStatus_1_dataSources_value),
    .io_enq_1_bits_status_srcStatus_2_psrc(io_enq_1_bits_status_srcStatus_2_psrc),
    .io_enq_1_bits_status_srcStatus_2_srcType(io_enq_1_bits_status_srcStatus_2_srcType),
    .io_enq_1_bits_status_srcStatus_2_srcState(io_enq_1_bits_status_srcStatus_2_srcState),
    .io_enq_1_bits_status_srcStatus_2_dataSources_value(io_enq_1_bits_status_srcStatus_2_dataSources_value),
    .io_enq_1_bits_status_srcStatus_3_psrc(io_enq_1_bits_status_srcStatus_3_psrc),
    .io_enq_1_bits_status_srcStatus_3_srcType(io_enq_1_bits_status_srcStatus_3_srcType),
    .io_enq_1_bits_status_srcStatus_3_srcState(io_enq_1_bits_status_srcStatus_3_srcState),
    .io_enq_1_bits_status_srcStatus_3_dataSources_value(io_enq_1_bits_status_srcStatus_3_dataSources_value),
    .io_enq_1_bits_status_srcStatus_4_psrc(io_enq_1_bits_status_srcStatus_4_psrc),
    .io_enq_1_bits_status_srcStatus_4_srcType(io_enq_1_bits_status_srcStatus_4_srcType),
    .io_enq_1_bits_status_srcStatus_4_srcState(io_enq_1_bits_status_srcStatus_4_srcState),
    .io_enq_1_bits_status_srcStatus_4_dataSources_value(io_enq_1_bits_status_srcStatus_4_dataSources_value),
    .io_enq_1_bits_payload_instr(io_enq_1_bits_payload_instr),
    .io_enq_1_bits_payload_pc(io_enq_1_bits_payload_pc),
    .io_enq_1_bits_payload_foldpc(io_enq_1_bits_payload_foldpc),
    .io_enq_1_bits_payload_exceptionVec_0(io_enq_1_bits_payload_exceptionVec_0),
    .io_enq_1_bits_payload_exceptionVec_1(io_enq_1_bits_payload_exceptionVec_1),
    .io_enq_1_bits_payload_exceptionVec_2(io_enq_1_bits_payload_exceptionVec_2),
    .io_enq_1_bits_payload_exceptionVec_3(io_enq_1_bits_payload_exceptionVec_3),
    .io_enq_1_bits_payload_exceptionVec_4(io_enq_1_bits_payload_exceptionVec_4),
    .io_enq_1_bits_payload_exceptionVec_5(io_enq_1_bits_payload_exceptionVec_5),
    .io_enq_1_bits_payload_exceptionVec_6(io_enq_1_bits_payload_exceptionVec_6),
    .io_enq_1_bits_payload_exceptionVec_7(io_enq_1_bits_payload_exceptionVec_7),
    .io_enq_1_bits_payload_exceptionVec_8(io_enq_1_bits_payload_exceptionVec_8),
    .io_enq_1_bits_payload_exceptionVec_9(io_enq_1_bits_payload_exceptionVec_9),
    .io_enq_1_bits_payload_exceptionVec_10(io_enq_1_bits_payload_exceptionVec_10),
    .io_enq_1_bits_payload_exceptionVec_11(io_enq_1_bits_payload_exceptionVec_11),
    .io_enq_1_bits_payload_exceptionVec_12(io_enq_1_bits_payload_exceptionVec_12),
    .io_enq_1_bits_payload_exceptionVec_13(io_enq_1_bits_payload_exceptionVec_13),
    .io_enq_1_bits_payload_exceptionVec_14(io_enq_1_bits_payload_exceptionVec_14),
    .io_enq_1_bits_payload_exceptionVec_15(io_enq_1_bits_payload_exceptionVec_15),
    .io_enq_1_bits_payload_exceptionVec_16(io_enq_1_bits_payload_exceptionVec_16),
    .io_enq_1_bits_payload_exceptionVec_17(io_enq_1_bits_payload_exceptionVec_17),
    .io_enq_1_bits_payload_exceptionVec_18(io_enq_1_bits_payload_exceptionVec_18),
    .io_enq_1_bits_payload_exceptionVec_19(io_enq_1_bits_payload_exceptionVec_19),
    .io_enq_1_bits_payload_exceptionVec_20(io_enq_1_bits_payload_exceptionVec_20),
    .io_enq_1_bits_payload_exceptionVec_21(io_enq_1_bits_payload_exceptionVec_21),
    .io_enq_1_bits_payload_exceptionVec_22(io_enq_1_bits_payload_exceptionVec_22),
    .io_enq_1_bits_payload_exceptionVec_23(io_enq_1_bits_payload_exceptionVec_23),
    .io_enq_1_bits_payload_isFetchMalAddr(io_enq_1_bits_payload_isFetchMalAddr),
    .io_enq_1_bits_payload_hasException(io_enq_1_bits_payload_hasException),
    .io_enq_1_bits_payload_trigger(io_enq_1_bits_payload_trigger),
    .io_enq_1_bits_payload_preDecodeInfo_valid(io_enq_1_bits_payload_preDecodeInfo_valid),
    .io_enq_1_bits_payload_preDecodeInfo_isRVC(io_enq_1_bits_payload_preDecodeInfo_isRVC),
    .io_enq_1_bits_payload_preDecodeInfo_brType(io_enq_1_bits_payload_preDecodeInfo_brType),
    .io_enq_1_bits_payload_preDecodeInfo_isCall(io_enq_1_bits_payload_preDecodeInfo_isCall),
    .io_enq_1_bits_payload_preDecodeInfo_isRet(io_enq_1_bits_payload_preDecodeInfo_isRet),
    .io_enq_1_bits_payload_pred_taken(io_enq_1_bits_payload_pred_taken),
    .io_enq_1_bits_payload_crossPageIPFFix(io_enq_1_bits_payload_crossPageIPFFix),
    .io_enq_1_bits_payload_ftqPtr_flag(io_enq_1_bits_payload_ftqPtr_flag),
    .io_enq_1_bits_payload_ftqPtr_value(io_enq_1_bits_payload_ftqPtr_value),
    .io_enq_1_bits_payload_ftqOffset(io_enq_1_bits_payload_ftqOffset),
    .io_enq_1_bits_payload_satpFlushFirstFetchFault(io_enq_1_bits_payload_satpFlushFirstFetchFault),
    .io_enq_1_bits_payload_srcType_0(io_enq_1_bits_payload_srcType_0),
    .io_enq_1_bits_payload_srcType_1(io_enq_1_bits_payload_srcType_1),
    .io_enq_1_bits_payload_srcType_2(io_enq_1_bits_payload_srcType_2),
    .io_enq_1_bits_payload_srcType_3(io_enq_1_bits_payload_srcType_3),
    .io_enq_1_bits_payload_srcType_4(io_enq_1_bits_payload_srcType_4),
    .io_enq_1_bits_payload_ldest(io_enq_1_bits_payload_ldest),
    .io_enq_1_bits_payload_fuType(io_enq_1_bits_payload_fuType),
    .io_enq_1_bits_payload_fuOpType(io_enq_1_bits_payload_fuOpType),
    .io_enq_1_bits_payload_rfWen(io_enq_1_bits_payload_rfWen),
    .io_enq_1_bits_payload_fpWen(io_enq_1_bits_payload_fpWen),
    .io_enq_1_bits_payload_vecWen(io_enq_1_bits_payload_vecWen),
    .io_enq_1_bits_payload_v0Wen(io_enq_1_bits_payload_v0Wen),
    .io_enq_1_bits_payload_vlWen(io_enq_1_bits_payload_vlWen),
    .io_enq_1_bits_payload_isXSTrap(io_enq_1_bits_payload_isXSTrap),
    .io_enq_1_bits_payload_waitForward(io_enq_1_bits_payload_waitForward),
    .io_enq_1_bits_payload_blockBackward(io_enq_1_bits_payload_blockBackward),
    .io_enq_1_bits_payload_flushPipe(io_enq_1_bits_payload_flushPipe),
    .io_enq_1_bits_payload_canRobCompress(io_enq_1_bits_payload_canRobCompress),
    .io_enq_1_bits_payload_selImm(io_enq_1_bits_payload_selImm),
    .io_enq_1_bits_payload_imm(io_enq_1_bits_payload_imm),
    .io_enq_1_bits_payload_fpu_typeTagOut(io_enq_1_bits_payload_fpu_typeTagOut),
    .io_enq_1_bits_payload_fpu_wflags(io_enq_1_bits_payload_fpu_wflags),
    .io_enq_1_bits_payload_fpu_typ(io_enq_1_bits_payload_fpu_typ),
    .io_enq_1_bits_payload_fpu_fmt(io_enq_1_bits_payload_fpu_fmt),
    .io_enq_1_bits_payload_fpu_rm(io_enq_1_bits_payload_fpu_rm),
    .io_enq_1_bits_payload_vpu_vill(io_enq_1_bits_payload_vpu_vill),
    .io_enq_1_bits_payload_vpu_vma(io_enq_1_bits_payload_vpu_vma),
    .io_enq_1_bits_payload_vpu_vta(io_enq_1_bits_payload_vpu_vta),
    .io_enq_1_bits_payload_vpu_vsew(io_enq_1_bits_payload_vpu_vsew),
    .io_enq_1_bits_payload_vpu_vlmul(io_enq_1_bits_payload_vpu_vlmul),
    .io_enq_1_bits_payload_vpu_specVill(io_enq_1_bits_payload_vpu_specVill),
    .io_enq_1_bits_payload_vpu_specVma(io_enq_1_bits_payload_vpu_specVma),
    .io_enq_1_bits_payload_vpu_specVta(io_enq_1_bits_payload_vpu_specVta),
    .io_enq_1_bits_payload_vpu_specVsew(io_enq_1_bits_payload_vpu_specVsew),
    .io_enq_1_bits_payload_vpu_specVlmul(io_enq_1_bits_payload_vpu_specVlmul),
    .io_enq_1_bits_payload_vpu_vm(io_enq_1_bits_payload_vpu_vm),
    .io_enq_1_bits_payload_vpu_vstart(io_enq_1_bits_payload_vpu_vstart),
    .io_enq_1_bits_payload_vpu_frm(io_enq_1_bits_payload_vpu_frm),
    .io_enq_1_bits_payload_vpu_fpu_isFpToVecInst(io_enq_1_bits_payload_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_payload_vpu_fpu_isFP32Instr(io_enq_1_bits_payload_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_payload_vpu_fpu_isFP64Instr(io_enq_1_bits_payload_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_payload_vpu_fpu_isReduction(io_enq_1_bits_payload_vpu_fpu_isReduction),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8(io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_payload_vpu_vxrm(io_enq_1_bits_payload_vpu_vxrm),
    .io_enq_1_bits_payload_vpu_vuopIdx(io_enq_1_bits_payload_vpu_vuopIdx),
    .io_enq_1_bits_payload_vpu_lastUop(io_enq_1_bits_payload_vpu_lastUop),
    .io_enq_1_bits_payload_vpu_vmask(io_enq_1_bits_payload_vpu_vmask),
    .io_enq_1_bits_payload_vpu_vl(io_enq_1_bits_payload_vpu_vl),
    .io_enq_1_bits_payload_vpu_nf(io_enq_1_bits_payload_vpu_nf),
    .io_enq_1_bits_payload_vpu_veew(io_enq_1_bits_payload_vpu_veew),
    .io_enq_1_bits_payload_vpu_isReverse(io_enq_1_bits_payload_vpu_isReverse),
    .io_enq_1_bits_payload_vpu_isExt(io_enq_1_bits_payload_vpu_isExt),
    .io_enq_1_bits_payload_vpu_isNarrow(io_enq_1_bits_payload_vpu_isNarrow),
    .io_enq_1_bits_payload_vpu_isDstMask(io_enq_1_bits_payload_vpu_isDstMask),
    .io_enq_1_bits_payload_vpu_isOpMask(io_enq_1_bits_payload_vpu_isOpMask),
    .io_enq_1_bits_payload_vpu_isMove(io_enq_1_bits_payload_vpu_isMove),
    .io_enq_1_bits_payload_vpu_isDependOldVd(io_enq_1_bits_payload_vpu_isDependOldVd),
    .io_enq_1_bits_payload_vpu_isWritePartVd(io_enq_1_bits_payload_vpu_isWritePartVd),
    .io_enq_1_bits_payload_vpu_isVleff(io_enq_1_bits_payload_vpu_isVleff),
    .io_enq_1_bits_payload_vlsInstr(io_enq_1_bits_payload_vlsInstr),
    .io_enq_1_bits_payload_wfflags(io_enq_1_bits_payload_wfflags),
    .io_enq_1_bits_payload_isMove(io_enq_1_bits_payload_isMove),
    .io_enq_1_bits_payload_isDropAmocasSta(io_enq_1_bits_payload_isDropAmocasSta),
    .io_enq_1_bits_payload_uopIdx(io_enq_1_bits_payload_uopIdx),
    .io_enq_1_bits_payload_isVset(io_enq_1_bits_payload_isVset),
    .io_enq_1_bits_payload_firstUop(io_enq_1_bits_payload_firstUop),
    .io_enq_1_bits_payload_lastUop(io_enq_1_bits_payload_lastUop),
    .io_enq_1_bits_payload_numUops(io_enq_1_bits_payload_numUops),
    .io_enq_1_bits_payload_numWB(io_enq_1_bits_payload_numWB),
    .io_enq_1_bits_payload_commitType(io_enq_1_bits_payload_commitType),
    .io_enq_1_bits_payload_srcState_0(io_enq_1_bits_payload_srcState_0),
    .io_enq_1_bits_payload_srcState_1(io_enq_1_bits_payload_srcState_1),
    .io_enq_1_bits_payload_srcState_2(io_enq_1_bits_payload_srcState_2),
    .io_enq_1_bits_payload_srcState_3(io_enq_1_bits_payload_srcState_3),
    .io_enq_1_bits_payload_srcState_4(io_enq_1_bits_payload_srcState_4),
    .io_enq_1_bits_payload_psrc_0(io_enq_1_bits_payload_psrc_0),
    .io_enq_1_bits_payload_psrc_1(io_enq_1_bits_payload_psrc_1),
    .io_enq_1_bits_payload_psrc_2(io_enq_1_bits_payload_psrc_2),
    .io_enq_1_bits_payload_psrc_3(io_enq_1_bits_payload_psrc_3),
    .io_enq_1_bits_payload_psrc_4(io_enq_1_bits_payload_psrc_4),
    .io_enq_1_bits_payload_pdest(io_enq_1_bits_payload_pdest),
    .io_enq_1_bits_payload_useRegCache_0(io_enq_1_bits_payload_useRegCache_0),
    .io_enq_1_bits_payload_useRegCache_1(io_enq_1_bits_payload_useRegCache_1),
    .io_enq_1_bits_payload_regCacheIdx_0(io_enq_1_bits_payload_regCacheIdx_0),
    .io_enq_1_bits_payload_regCacheIdx_1(io_enq_1_bits_payload_regCacheIdx_1),
    .io_enq_1_bits_payload_robIdx_flag(io_enq_1_bits_payload_robIdx_flag),
    .io_enq_1_bits_payload_robIdx_value(io_enq_1_bits_payload_robIdx_value),
    .io_enq_1_bits_payload_instrSize(io_enq_1_bits_payload_instrSize),
    .io_enq_1_bits_payload_dirtyFs(io_enq_1_bits_payload_dirtyFs),
    .io_enq_1_bits_payload_dirtyVs(io_enq_1_bits_payload_dirtyVs),
    .io_enq_1_bits_payload_traceBlockInPipe_itype(io_enq_1_bits_payload_traceBlockInPipe_itype),
    .io_enq_1_bits_payload_traceBlockInPipe_iretire(io_enq_1_bits_payload_traceBlockInPipe_iretire),
    .io_enq_1_bits_payload_traceBlockInPipe_ilastsize(io_enq_1_bits_payload_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_payload_eliminatedMove(io_enq_1_bits_payload_eliminatedMove),
    .io_enq_1_bits_payload_snapshot(io_enq_1_bits_payload_snapshot),
    .io_enq_1_bits_payload_debugInfo_eliminatedMove(io_enq_1_bits_payload_debugInfo_eliminatedMove),
    .io_enq_1_bits_payload_debugInfo_renameTime(io_enq_1_bits_payload_debugInfo_renameTime),
    .io_enq_1_bits_payload_debugInfo_dispatchTime(io_enq_1_bits_payload_debugInfo_dispatchTime),
    .io_enq_1_bits_payload_debugInfo_enqRsTime(io_enq_1_bits_payload_debugInfo_enqRsTime),
    .io_enq_1_bits_payload_debugInfo_selectTime(io_enq_1_bits_payload_debugInfo_selectTime),
    .io_enq_1_bits_payload_debugInfo_issueTime(io_enq_1_bits_payload_debugInfo_issueTime),
    .io_enq_1_bits_payload_debugInfo_writebackTime(io_enq_1_bits_payload_debugInfo_writebackTime),
    .io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id(io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_payload_debugInfo_tlbFirstReqTime(io_enq_1_bits_payload_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_payload_debugInfo_tlbRespTime(io_enq_1_bits_payload_debugInfo_tlbRespTime),
    .io_enq_1_bits_payload_debug_seqNum_seqNum(io_enq_1_bits_payload_debug_seqNum_seqNum),
    .io_enq_1_bits_payload_debug_seqNum_uopIdx(io_enq_1_bits_payload_debug_seqNum_uopIdx),
    .io_enq_1_bits_payload_storeSetHit(io_enq_1_bits_payload_storeSetHit),
    .io_enq_1_bits_payload_waitForRobIdx_flag(io_enq_1_bits_payload_waitForRobIdx_flag),
    .io_enq_1_bits_payload_waitForRobIdx_value(io_enq_1_bits_payload_waitForRobIdx_value),
    .io_enq_1_bits_payload_loadWaitBit(io_enq_1_bits_payload_loadWaitBit),
    .io_enq_1_bits_payload_loadWaitStrict(io_enq_1_bits_payload_loadWaitStrict),
    .io_enq_1_bits_payload_ssid(io_enq_1_bits_payload_ssid),
    .io_enq_1_bits_payload_lqIdx_flag(io_enq_1_bits_payload_lqIdx_flag),
    .io_enq_1_bits_payload_lqIdx_value(io_enq_1_bits_payload_lqIdx_value),
    .io_enq_1_bits_payload_sqIdx_flag(io_enq_1_bits_payload_sqIdx_flag),
    .io_enq_1_bits_payload_sqIdx_value(io_enq_1_bits_payload_sqIdx_value),
    .io_enq_1_bits_payload_singleStep(io_enq_1_bits_payload_singleStep),
    .io_enq_1_bits_payload_replayInst(io_enq_1_bits_payload_replayInst),
    .io_enq_1_bits_payload_debug_fuType(io_enq_1_bits_payload_debug_fuType),
    .io_enq_1_bits_payload_debug_sim_trig(io_enq_1_bits_payload_debug_sim_trig),
    .io_enq_1_bits_payload_numLsElem(io_enq_1_bits_payload_numLsElem),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og2Resp_0_valid(io_og2Resp_0_valid),
    .io_og2Resp_0_bits_resp(io_og2Resp_0_bits_resp),
    .io_deqReady_0(io_deqReady_0),
    .io_deqSelOH_0_valid(io_deqSelOH_0_valid),
    .io_deqSelOH_0_bits(io_deqSelOH_0_bits),
    .io_enqEntryOldestSel_0_bits(io_enqEntryOldestSel_0_bits),
    .io_simpEntryOldestSel_0_valid(io_simpEntryOldestSel_0_valid),
    .io_simpEntryOldestSel_0_bits(io_simpEntryOldestSel_0_bits),
    .io_compEntryOldestSel_0_valid(io_compEntryOldestSel_0_valid),
    .io_compEntryOldestSel_0_bits(io_compEntryOldestSel_0_bits),
    .io_wakeUpFromWB_15_valid(io_wakeUpFromWB_15_valid),
    .io_wakeUpFromWB_15_bits_vlWen(io_wakeUpFromWB_15_bits_vlWen),
    .io_wakeUpFromWB_15_bits_pdest(io_wakeUpFromWB_15_bits_pdest),
    .io_wakeUpFromWB_14_valid(io_wakeUpFromWB_14_valid),
    .io_wakeUpFromWB_14_bits_vlWen(io_wakeUpFromWB_14_bits_vlWen),
    .io_wakeUpFromWB_14_bits_pdest(io_wakeUpFromWB_14_bits_pdest),
    .io_wakeUpFromWB_13_valid(io_wakeUpFromWB_13_valid),
    .io_wakeUpFromWB_13_bits_vlWen(io_wakeUpFromWB_13_bits_vlWen),
    .io_wakeUpFromWB_13_bits_pdest(io_wakeUpFromWB_13_bits_pdest),
    .io_wakeUpFromWB_12_valid(io_wakeUpFromWB_12_valid),
    .io_wakeUpFromWB_12_bits_vlWen(io_wakeUpFromWB_12_bits_vlWen),
    .io_wakeUpFromWB_12_bits_pdest(io_wakeUpFromWB_12_bits_pdest),
    .io_wakeUpFromWB_11_valid(io_wakeUpFromWB_11_valid),
    .io_wakeUpFromWB_11_bits_v0Wen(io_wakeUpFromWB_11_bits_v0Wen),
    .io_wakeUpFromWB_11_bits_pdest(io_wakeUpFromWB_11_bits_pdest),
    .io_wakeUpFromWB_10_valid(io_wakeUpFromWB_10_valid),
    .io_wakeUpFromWB_10_bits_v0Wen(io_wakeUpFromWB_10_bits_v0Wen),
    .io_wakeUpFromWB_10_bits_pdest(io_wakeUpFromWB_10_bits_pdest),
    .io_wakeUpFromWB_9_valid(io_wakeUpFromWB_9_valid),
    .io_wakeUpFromWB_9_bits_v0Wen(io_wakeUpFromWB_9_bits_v0Wen),
    .io_wakeUpFromWB_9_bits_pdest(io_wakeUpFromWB_9_bits_pdest),
    .io_wakeUpFromWB_8_valid(io_wakeUpFromWB_8_valid),
    .io_wakeUpFromWB_8_bits_v0Wen(io_wakeUpFromWB_8_bits_v0Wen),
    .io_wakeUpFromWB_8_bits_pdest(io_wakeUpFromWB_8_bits_pdest),
    .io_wakeUpFromWB_7_valid(io_wakeUpFromWB_7_valid),
    .io_wakeUpFromWB_7_bits_v0Wen(io_wakeUpFromWB_7_bits_v0Wen),
    .io_wakeUpFromWB_7_bits_pdest(io_wakeUpFromWB_7_bits_pdest),
    .io_wakeUpFromWB_6_valid(io_wakeUpFromWB_6_valid),
    .io_wakeUpFromWB_6_bits_v0Wen(io_wakeUpFromWB_6_bits_v0Wen),
    .io_wakeUpFromWB_6_bits_pdest(io_wakeUpFromWB_6_bits_pdest),
    .io_wakeUpFromWB_5_valid(io_wakeUpFromWB_5_valid),
    .io_wakeUpFromWB_5_bits_vecWen(io_wakeUpFromWB_5_bits_vecWen),
    .io_wakeUpFromWB_5_bits_pdest(io_wakeUpFromWB_5_bits_pdest),
    .io_wakeUpFromWB_4_valid(io_wakeUpFromWB_4_valid),
    .io_wakeUpFromWB_4_bits_vecWen(io_wakeUpFromWB_4_bits_vecWen),
    .io_wakeUpFromWB_4_bits_pdest(io_wakeUpFromWB_4_bits_pdest),
    .io_wakeUpFromWB_3_valid(io_wakeUpFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_vecWen(io_wakeUpFromWB_3_bits_vecWen),
    .io_wakeUpFromWB_3_bits_pdest(io_wakeUpFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid(io_wakeUpFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_vecWen(io_wakeUpFromWB_2_bits_vecWen),
    .io_wakeUpFromWB_2_bits_pdest(io_wakeUpFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid(io_wakeUpFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_vecWen(io_wakeUpFromWB_1_bits_vecWen),
    .io_wakeUpFromWB_1_bits_pdest(io_wakeUpFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid(io_wakeUpFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_vecWen(io_wakeUpFromWB_0_bits_vecWen),
    .io_wakeUpFromWB_0_bits_pdest(io_wakeUpFromWB_0_bits_pdest),
    .io_wakeUpFromWBDelayed_15_valid(io_wakeUpFromWBDelayed_15_valid),
    .io_wakeUpFromWBDelayed_15_bits_vlWen(io_wakeUpFromWBDelayed_15_bits_vlWen),
    .io_wakeUpFromWBDelayed_15_bits_pdest(io_wakeUpFromWBDelayed_15_bits_pdest),
    .io_wakeUpFromWBDelayed_14_valid(io_wakeUpFromWBDelayed_14_valid),
    .io_wakeUpFromWBDelayed_14_bits_vlWen(io_wakeUpFromWBDelayed_14_bits_vlWen),
    .io_wakeUpFromWBDelayed_14_bits_pdest(io_wakeUpFromWBDelayed_14_bits_pdest),
    .io_wakeUpFromWBDelayed_13_valid(io_wakeUpFromWBDelayed_13_valid),
    .io_wakeUpFromWBDelayed_13_bits_vlWen(io_wakeUpFromWBDelayed_13_bits_vlWen),
    .io_wakeUpFromWBDelayed_13_bits_pdest(io_wakeUpFromWBDelayed_13_bits_pdest),
    .io_wakeUpFromWBDelayed_12_valid(io_wakeUpFromWBDelayed_12_valid),
    .io_wakeUpFromWBDelayed_12_bits_vlWen(io_wakeUpFromWBDelayed_12_bits_vlWen),
    .io_wakeUpFromWBDelayed_12_bits_pdest(io_wakeUpFromWBDelayed_12_bits_pdest),
    .io_wakeUpFromWBDelayed_11_valid(io_wakeUpFromWBDelayed_11_valid),
    .io_wakeUpFromWBDelayed_11_bits_v0Wen(io_wakeUpFromWBDelayed_11_bits_v0Wen),
    .io_wakeUpFromWBDelayed_11_bits_pdest(io_wakeUpFromWBDelayed_11_bits_pdest),
    .io_wakeUpFromWBDelayed_10_valid(io_wakeUpFromWBDelayed_10_valid),
    .io_wakeUpFromWBDelayed_10_bits_v0Wen(io_wakeUpFromWBDelayed_10_bits_v0Wen),
    .io_wakeUpFromWBDelayed_10_bits_pdest(io_wakeUpFromWBDelayed_10_bits_pdest),
    .io_wakeUpFromWBDelayed_9_valid(io_wakeUpFromWBDelayed_9_valid),
    .io_wakeUpFromWBDelayed_9_bits_v0Wen(io_wakeUpFromWBDelayed_9_bits_v0Wen),
    .io_wakeUpFromWBDelayed_9_bits_pdest(io_wakeUpFromWBDelayed_9_bits_pdest),
    .io_wakeUpFromWBDelayed_8_valid(io_wakeUpFromWBDelayed_8_valid),
    .io_wakeUpFromWBDelayed_8_bits_v0Wen(io_wakeUpFromWBDelayed_8_bits_v0Wen),
    .io_wakeUpFromWBDelayed_8_bits_pdest(io_wakeUpFromWBDelayed_8_bits_pdest),
    .io_wakeUpFromWBDelayed_7_valid(io_wakeUpFromWBDelayed_7_valid),
    .io_wakeUpFromWBDelayed_7_bits_v0Wen(io_wakeUpFromWBDelayed_7_bits_v0Wen),
    .io_wakeUpFromWBDelayed_7_bits_pdest(io_wakeUpFromWBDelayed_7_bits_pdest),
    .io_wakeUpFromWBDelayed_6_valid(io_wakeUpFromWBDelayed_6_valid),
    .io_wakeUpFromWBDelayed_6_bits_v0Wen(io_wakeUpFromWBDelayed_6_bits_v0Wen),
    .io_wakeUpFromWBDelayed_6_bits_pdest(io_wakeUpFromWBDelayed_6_bits_pdest),
    .io_wakeUpFromWBDelayed_5_valid(io_wakeUpFromWBDelayed_5_valid),
    .io_wakeUpFromWBDelayed_5_bits_vecWen(io_wakeUpFromWBDelayed_5_bits_vecWen),
    .io_wakeUpFromWBDelayed_5_bits_pdest(io_wakeUpFromWBDelayed_5_bits_pdest),
    .io_wakeUpFromWBDelayed_4_valid(io_wakeUpFromWBDelayed_4_valid),
    .io_wakeUpFromWBDelayed_4_bits_vecWen(io_wakeUpFromWBDelayed_4_bits_vecWen),
    .io_wakeUpFromWBDelayed_4_bits_pdest(io_wakeUpFromWBDelayed_4_bits_pdest),
    .io_wakeUpFromWBDelayed_3_valid(io_wakeUpFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_vecWen(io_wakeUpFromWBDelayed_3_bits_vecWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest(io_wakeUpFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid(io_wakeUpFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_vecWen(io_wakeUpFromWBDelayed_2_bits_vecWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest(io_wakeUpFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid(io_wakeUpFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_vecWen(io_wakeUpFromWBDelayed_1_bits_vecWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest(io_wakeUpFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid(io_wakeUpFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_vecWen(io_wakeUpFromWBDelayed_0_bits_vecWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest(io_wakeUpFromWBDelayed_0_bits_pdest),
    .io_vlFromIntIsZero(io_vlFromIntIsZero),
    .io_vlFromIntIsVlmax(io_vlFromIntIsVlmax),
    .io_vlFromVfIsZero(io_vlFromVfIsZero),
    .io_vlFromVfIsVlmax(io_vlFromVfIsVlmax),
    .io_simpEntryDeqSelVec_0(io_simpEntryDeqSelVec_0),
    .io_simpEntryDeqSelVec_1(io_simpEntryDeqSelVec_1),
    .io_valid(i_io_valid),
    .io_issued(i_io_issued),
    .io_canIssue(i_io_canIssue),
    .io_fuType_0(i_io_fuType_0),
    .io_fuType_1(i_io_fuType_1),
    .io_fuType_2(i_io_fuType_2),
    .io_fuType_3(i_io_fuType_3),
    .io_fuType_4(i_io_fuType_4),
    .io_fuType_5(i_io_fuType_5),
    .io_fuType_6(i_io_fuType_6),
    .io_fuType_7(i_io_fuType_7),
    .io_fuType_8(i_io_fuType_8),
    .io_fuType_9(i_io_fuType_9),
    .io_dataSources_0_0_value(i_io_dataSources_0_0_value),
    .io_dataSources_0_1_value(i_io_dataSources_0_1_value),
    .io_dataSources_0_2_value(i_io_dataSources_0_2_value),
    .io_dataSources_0_3_value(i_io_dataSources_0_3_value),
    .io_dataSources_0_4_value(i_io_dataSources_0_4_value),
    .io_dataSources_1_0_value(i_io_dataSources_1_0_value),
    .io_dataSources_1_1_value(i_io_dataSources_1_1_value),
    .io_dataSources_1_2_value(i_io_dataSources_1_2_value),
    .io_dataSources_1_3_value(i_io_dataSources_1_3_value),
    .io_dataSources_1_4_value(i_io_dataSources_1_4_value),
    .io_dataSources_2_0_value(i_io_dataSources_2_0_value),
    .io_dataSources_2_1_value(i_io_dataSources_2_1_value),
    .io_dataSources_2_2_value(i_io_dataSources_2_2_value),
    .io_dataSources_2_3_value(i_io_dataSources_2_3_value),
    .io_dataSources_2_4_value(i_io_dataSources_2_4_value),
    .io_dataSources_3_0_value(i_io_dataSources_3_0_value),
    .io_dataSources_3_1_value(i_io_dataSources_3_1_value),
    .io_dataSources_3_2_value(i_io_dataSources_3_2_value),
    .io_dataSources_3_3_value(i_io_dataSources_3_3_value),
    .io_dataSources_3_4_value(i_io_dataSources_3_4_value),
    .io_dataSources_4_0_value(i_io_dataSources_4_0_value),
    .io_dataSources_4_1_value(i_io_dataSources_4_1_value),
    .io_dataSources_4_2_value(i_io_dataSources_4_2_value),
    .io_dataSources_4_3_value(i_io_dataSources_4_3_value),
    .io_dataSources_4_4_value(i_io_dataSources_4_4_value),
    .io_dataSources_5_0_value(i_io_dataSources_5_0_value),
    .io_dataSources_5_1_value(i_io_dataSources_5_1_value),
    .io_dataSources_5_2_value(i_io_dataSources_5_2_value),
    .io_dataSources_5_3_value(i_io_dataSources_5_3_value),
    .io_dataSources_5_4_value(i_io_dataSources_5_4_value),
    .io_dataSources_6_0_value(i_io_dataSources_6_0_value),
    .io_dataSources_6_1_value(i_io_dataSources_6_1_value),
    .io_dataSources_6_2_value(i_io_dataSources_6_2_value),
    .io_dataSources_6_3_value(i_io_dataSources_6_3_value),
    .io_dataSources_6_4_value(i_io_dataSources_6_4_value),
    .io_dataSources_7_0_value(i_io_dataSources_7_0_value),
    .io_dataSources_7_1_value(i_io_dataSources_7_1_value),
    .io_dataSources_7_2_value(i_io_dataSources_7_2_value),
    .io_dataSources_7_3_value(i_io_dataSources_7_3_value),
    .io_dataSources_7_4_value(i_io_dataSources_7_4_value),
    .io_dataSources_8_0_value(i_io_dataSources_8_0_value),
    .io_dataSources_8_1_value(i_io_dataSources_8_1_value),
    .io_dataSources_8_2_value(i_io_dataSources_8_2_value),
    .io_dataSources_8_3_value(i_io_dataSources_8_3_value),
    .io_dataSources_8_4_value(i_io_dataSources_8_4_value),
    .io_dataSources_9_0_value(i_io_dataSources_9_0_value),
    .io_dataSources_9_1_value(i_io_dataSources_9_1_value),
    .io_dataSources_9_2_value(i_io_dataSources_9_2_value),
    .io_dataSources_9_3_value(i_io_dataSources_9_3_value),
    .io_dataSources_9_4_value(i_io_dataSources_9_4_value),
    .io_isFirstIssue_0(i_io_isFirstIssue_0),
    .io_deqEntry_0_bits_status_robIdx_flag(i_io_deqEntry_0_bits_status_robIdx_flag),
    .io_deqEntry_0_bits_status_robIdx_value(i_io_deqEntry_0_bits_status_robIdx_value),
    .io_deqEntry_0_bits_status_fuType_22(i_io_deqEntry_0_bits_status_fuType_22),
    .io_deqEntry_0_bits_status_fuType_26(i_io_deqEntry_0_bits_status_fuType_26),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc(i_io_deqEntry_0_bits_status_srcStatus_0_psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType(i_io_deqEntry_0_bits_status_srcStatus_0_srcType),
    .io_deqEntry_0_bits_status_srcStatus_1_psrc(i_io_deqEntry_0_bits_status_srcStatus_1_psrc),
    .io_deqEntry_0_bits_status_srcStatus_1_srcType(i_io_deqEntry_0_bits_status_srcStatus_1_srcType),
    .io_deqEntry_0_bits_status_srcStatus_2_psrc(i_io_deqEntry_0_bits_status_srcStatus_2_psrc),
    .io_deqEntry_0_bits_status_srcStatus_2_srcType(i_io_deqEntry_0_bits_status_srcStatus_2_srcType),
    .io_deqEntry_0_bits_status_srcStatus_3_psrc(i_io_deqEntry_0_bits_status_srcStatus_3_psrc),
    .io_deqEntry_0_bits_status_srcStatus_3_srcType(i_io_deqEntry_0_bits_status_srcStatus_3_srcType),
    .io_deqEntry_0_bits_status_srcStatus_4_psrc(i_io_deqEntry_0_bits_status_srcStatus_4_psrc),
    .io_deqEntry_0_bits_status_srcStatus_4_srcType(i_io_deqEntry_0_bits_status_srcStatus_4_srcType),
    .io_deqEntry_0_bits_payload_fuOpType(i_io_deqEntry_0_bits_payload_fuOpType),
    .io_deqEntry_0_bits_payload_vecWen(i_io_deqEntry_0_bits_payload_vecWen),
    .io_deqEntry_0_bits_payload_v0Wen(i_io_deqEntry_0_bits_payload_v0Wen),
    .io_deqEntry_0_bits_payload_selImm(i_io_deqEntry_0_bits_payload_selImm),
    .io_deqEntry_0_bits_payload_fpu_typeTagOut(i_io_deqEntry_0_bits_payload_fpu_typeTagOut),
    .io_deqEntry_0_bits_payload_fpu_wflags(i_io_deqEntry_0_bits_payload_fpu_wflags),
    .io_deqEntry_0_bits_payload_fpu_typ(i_io_deqEntry_0_bits_payload_fpu_typ),
    .io_deqEntry_0_bits_payload_fpu_fmt(i_io_deqEntry_0_bits_payload_fpu_fmt),
    .io_deqEntry_0_bits_payload_fpu_rm(i_io_deqEntry_0_bits_payload_fpu_rm),
    .io_deqEntry_0_bits_payload_vpu_vill(i_io_deqEntry_0_bits_payload_vpu_vill),
    .io_deqEntry_0_bits_payload_vpu_vma(i_io_deqEntry_0_bits_payload_vpu_vma),
    .io_deqEntry_0_bits_payload_vpu_vta(i_io_deqEntry_0_bits_payload_vpu_vta),
    .io_deqEntry_0_bits_payload_vpu_vsew(i_io_deqEntry_0_bits_payload_vpu_vsew),
    .io_deqEntry_0_bits_payload_vpu_vlmul(i_io_deqEntry_0_bits_payload_vpu_vlmul),
    .io_deqEntry_0_bits_payload_vpu_specVill(i_io_deqEntry_0_bits_payload_vpu_specVill),
    .io_deqEntry_0_bits_payload_vpu_specVma(i_io_deqEntry_0_bits_payload_vpu_specVma),
    .io_deqEntry_0_bits_payload_vpu_specVta(i_io_deqEntry_0_bits_payload_vpu_specVta),
    .io_deqEntry_0_bits_payload_vpu_specVsew(i_io_deqEntry_0_bits_payload_vpu_specVsew),
    .io_deqEntry_0_bits_payload_vpu_specVlmul(i_io_deqEntry_0_bits_payload_vpu_specVlmul),
    .io_deqEntry_0_bits_payload_vpu_vm(i_io_deqEntry_0_bits_payload_vpu_vm),
    .io_deqEntry_0_bits_payload_vpu_vstart(i_io_deqEntry_0_bits_payload_vpu_vstart),
    .io_deqEntry_0_bits_payload_vpu_frm(i_io_deqEntry_0_bits_payload_vpu_frm),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst(i_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr(i_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr(i_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isReduction(i_io_deqEntry_0_bits_payload_vpu_fpu_isReduction),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2(i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4(i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8(i_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_deqEntry_0_bits_payload_vpu_vxrm(i_io_deqEntry_0_bits_payload_vpu_vxrm),
    .io_deqEntry_0_bits_payload_vpu_vmask(i_io_deqEntry_0_bits_payload_vpu_vmask),
    .io_deqEntry_0_bits_payload_vpu_vl(i_io_deqEntry_0_bits_payload_vpu_vl),
    .io_deqEntry_0_bits_payload_vpu_nf(i_io_deqEntry_0_bits_payload_vpu_nf),
    .io_deqEntry_0_bits_payload_vpu_veew(i_io_deqEntry_0_bits_payload_vpu_veew),
    .io_deqEntry_0_bits_payload_vpu_isReverse(i_io_deqEntry_0_bits_payload_vpu_isReverse),
    .io_deqEntry_0_bits_payload_vpu_isExt(i_io_deqEntry_0_bits_payload_vpu_isExt),
    .io_deqEntry_0_bits_payload_vpu_isNarrow(i_io_deqEntry_0_bits_payload_vpu_isNarrow),
    .io_deqEntry_0_bits_payload_vpu_isDstMask(i_io_deqEntry_0_bits_payload_vpu_isDstMask),
    .io_deqEntry_0_bits_payload_vpu_isOpMask(i_io_deqEntry_0_bits_payload_vpu_isOpMask),
    .io_deqEntry_0_bits_payload_vpu_isMove(i_io_deqEntry_0_bits_payload_vpu_isMove),
    .io_deqEntry_0_bits_payload_vpu_isDependOldVd(i_io_deqEntry_0_bits_payload_vpu_isDependOldVd),
    .io_deqEntry_0_bits_payload_vpu_isWritePartVd(i_io_deqEntry_0_bits_payload_vpu_isWritePartVd),
    .io_deqEntry_0_bits_payload_vpu_isVleff(i_io_deqEntry_0_bits_payload_vpu_isVleff),
    .io_deqEntry_0_bits_payload_uopIdx(i_io_deqEntry_0_bits_payload_uopIdx),
    .io_deqEntry_0_bits_payload_lastUop(i_io_deqEntry_0_bits_payload_lastUop),
    .io_deqEntry_0_bits_payload_pdest(i_io_deqEntry_0_bits_payload_pdest),
    .io_deqEntry_0_bits_payload_debugInfo_eliminatedMove(i_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove),
    .io_deqEntry_0_bits_payload_debugInfo_renameTime(i_io_deqEntry_0_bits_payload_debugInfo_renameTime),
    .io_deqEntry_0_bits_payload_debugInfo_dispatchTime(i_io_deqEntry_0_bits_payload_debugInfo_dispatchTime),
    .io_deqEntry_0_bits_payload_debugInfo_enqRsTime(i_io_deqEntry_0_bits_payload_debugInfo_enqRsTime),
    .io_deqEntry_0_bits_payload_debugInfo_writebackTime(i_io_deqEntry_0_bits_payload_debugInfo_writebackTime),
    .io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id(i_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime(i_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime),
    .io_deqEntry_0_bits_payload_debugInfo_tlbRespTime(i_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime),
    .io_deqEntry_0_bits_payload_debug_seqNum_seqNum(i_io_deqEntry_0_bits_payload_debug_seqNum_seqNum),
    .io_deqEntry_0_bits_payload_debug_seqNum_uopIdx(i_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx),
    .io_simpEntryEnqSelVec_0(i_io_simpEntryEnqSelVec_0),
    .io_simpEntryEnqSelVec_1(i_io_simpEntryEnqSelVec_1),
    .io_compEntryEnqSelVec_0(i_io_compEntryEnqSelVec_0),
    .io_compEntryEnqSelVec_1(i_io_compEntryEnqSelVec_1)
  );

  task automatic check_outputs();
    `CHK(io_valid)
    `CHK(io_issued)
    `CHK(io_canIssue)
    `CHK(io_fuType_0)
    `CHK(io_fuType_1)
    `CHK(io_fuType_2)
    `CHK(io_fuType_3)
    `CHK(io_fuType_4)
    `CHK(io_fuType_5)
    `CHK(io_fuType_6)
    `CHK(io_fuType_7)
    `CHK(io_fuType_8)
    `CHK(io_fuType_9)
    `CHK(io_dataSources_0_0_value)
    `CHK(io_dataSources_0_1_value)
    `CHK(io_dataSources_0_2_value)
    `CHK(io_dataSources_0_3_value)
    `CHK(io_dataSources_0_4_value)
    `CHK(io_dataSources_1_0_value)
    `CHK(io_dataSources_1_1_value)
    `CHK(io_dataSources_1_2_value)
    `CHK(io_dataSources_1_3_value)
    `CHK(io_dataSources_1_4_value)
    `CHK(io_dataSources_2_0_value)
    `CHK(io_dataSources_2_1_value)
    `CHK(io_dataSources_2_2_value)
    `CHK(io_dataSources_2_3_value)
    `CHK(io_dataSources_2_4_value)
    `CHK(io_dataSources_3_0_value)
    `CHK(io_dataSources_3_1_value)
    `CHK(io_dataSources_3_2_value)
    `CHK(io_dataSources_3_3_value)
    `CHK(io_dataSources_3_4_value)
    `CHK(io_dataSources_4_0_value)
    `CHK(io_dataSources_4_1_value)
    `CHK(io_dataSources_4_2_value)
    `CHK(io_dataSources_4_3_value)
    `CHK(io_dataSources_4_4_value)
    `CHK(io_dataSources_5_0_value)
    `CHK(io_dataSources_5_1_value)
    `CHK(io_dataSources_5_2_value)
    `CHK(io_dataSources_5_3_value)
    `CHK(io_dataSources_5_4_value)
    `CHK(io_dataSources_6_0_value)
    `CHK(io_dataSources_6_1_value)
    `CHK(io_dataSources_6_2_value)
    `CHK(io_dataSources_6_3_value)
    `CHK(io_dataSources_6_4_value)
    `CHK(io_dataSources_7_0_value)
    `CHK(io_dataSources_7_1_value)
    `CHK(io_dataSources_7_2_value)
    `CHK(io_dataSources_7_3_value)
    `CHK(io_dataSources_7_4_value)
    `CHK(io_dataSources_8_0_value)
    `CHK(io_dataSources_8_1_value)
    `CHK(io_dataSources_8_2_value)
    `CHK(io_dataSources_8_3_value)
    `CHK(io_dataSources_8_4_value)
    `CHK(io_dataSources_9_0_value)
    `CHK(io_dataSources_9_1_value)
    `CHK(io_dataSources_9_2_value)
    `CHK(io_dataSources_9_3_value)
    `CHK(io_dataSources_9_4_value)
    `CHK(io_isFirstIssue_0)
    `CHK(io_deqEntry_0_bits_status_robIdx_flag)
    `CHK(io_deqEntry_0_bits_status_robIdx_value)
    `CHK(io_deqEntry_0_bits_status_fuType_22)
    `CHK(io_deqEntry_0_bits_status_fuType_26)
    `CHK(io_deqEntry_0_bits_status_srcStatus_0_psrc)
    `CHK(io_deqEntry_0_bits_status_srcStatus_0_srcType)
    `CHK(io_deqEntry_0_bits_status_srcStatus_1_psrc)
    `CHK(io_deqEntry_0_bits_status_srcStatus_1_srcType)
    `CHK(io_deqEntry_0_bits_status_srcStatus_2_psrc)
    `CHK(io_deqEntry_0_bits_status_srcStatus_2_srcType)
    `CHK(io_deqEntry_0_bits_status_srcStatus_3_psrc)
    `CHK(io_deqEntry_0_bits_status_srcStatus_3_srcType)
    `CHK(io_deqEntry_0_bits_status_srcStatus_4_psrc)
    `CHK(io_deqEntry_0_bits_status_srcStatus_4_srcType)
    `CHK(io_deqEntry_0_bits_payload_fuOpType)
    `CHK(io_deqEntry_0_bits_payload_vecWen)
    `CHK(io_deqEntry_0_bits_payload_v0Wen)
    `CHK(io_deqEntry_0_bits_payload_selImm)
    `CHK(io_deqEntry_0_bits_payload_fpu_typeTagOut)
    `CHK(io_deqEntry_0_bits_payload_fpu_wflags)
    `CHK(io_deqEntry_0_bits_payload_fpu_typ)
    `CHK(io_deqEntry_0_bits_payload_fpu_fmt)
    `CHK(io_deqEntry_0_bits_payload_fpu_rm)
    `CHK(io_deqEntry_0_bits_payload_vpu_vill)
    `CHK(io_deqEntry_0_bits_payload_vpu_vma)
    `CHK(io_deqEntry_0_bits_payload_vpu_vta)
    `CHK(io_deqEntry_0_bits_payload_vpu_vsew)
    `CHK(io_deqEntry_0_bits_payload_vpu_vlmul)
    `CHK(io_deqEntry_0_bits_payload_vpu_specVill)
    `CHK(io_deqEntry_0_bits_payload_vpu_specVma)
    `CHK(io_deqEntry_0_bits_payload_vpu_specVta)
    `CHK(io_deqEntry_0_bits_payload_vpu_specVsew)
    `CHK(io_deqEntry_0_bits_payload_vpu_specVlmul)
    `CHK(io_deqEntry_0_bits_payload_vpu_vm)
    `CHK(io_deqEntry_0_bits_payload_vpu_vstart)
    `CHK(io_deqEntry_0_bits_payload_vpu_frm)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isReduction)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4)
    `CHK(io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8)
    `CHK(io_deqEntry_0_bits_payload_vpu_vxrm)
    `CHK(io_deqEntry_0_bits_payload_vpu_vmask)
    `CHK(io_deqEntry_0_bits_payload_vpu_vl)
    `CHK(io_deqEntry_0_bits_payload_vpu_nf)
    `CHK(io_deqEntry_0_bits_payload_vpu_veew)
    `CHK(io_deqEntry_0_bits_payload_vpu_isReverse)
    `CHK(io_deqEntry_0_bits_payload_vpu_isExt)
    `CHK(io_deqEntry_0_bits_payload_vpu_isNarrow)
    `CHK(io_deqEntry_0_bits_payload_vpu_isDstMask)
    `CHK(io_deqEntry_0_bits_payload_vpu_isOpMask)
    `CHK(io_deqEntry_0_bits_payload_vpu_isMove)
    `CHK(io_deqEntry_0_bits_payload_vpu_isDependOldVd)
    `CHK(io_deqEntry_0_bits_payload_vpu_isWritePartVd)
    `CHK(io_deqEntry_0_bits_payload_vpu_isVleff)
    `CHK(io_deqEntry_0_bits_payload_uopIdx)
    `CHK(io_deqEntry_0_bits_payload_lastUop)
    `CHK(io_deqEntry_0_bits_payload_pdest)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_eliminatedMove)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_renameTime)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_dispatchTime)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_enqRsTime)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_writebackTime)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime)
    `CHK(io_deqEntry_0_bits_payload_debugInfo_tlbRespTime)
    `CHK(io_deqEntry_0_bits_payload_debug_seqNum_seqNum)
    `CHK(io_deqEntry_0_bits_payload_debug_seqNum_uopIdx)
    `CHK(io_simpEntryEnqSelVec_0)
    `CHK(io_simpEntryEnqSelVec_1)
    `CHK(io_compEntryEnqSelVec_0)
    `CHK(io_compEntryEnqSelVec_1)
  endtask

  localparam int POOL = 8;   // pdest/psrc 共用的小池，保证唤醒能打中
  function automatic int rnd_reg(); return $urandom_range(0, POOL-1); endfunction

  // ---- 每拍激励（负沿下非阻塞给出）----
  task automatic drive();
    io_flush_valid             <= ($urandom_range(0, 999) < 3);
    io_flush_bits_robIdx_flag  <= $urandom_range(0, 1);
    io_flush_bits_robIdx_value <= 8'($urandom_range(0, 255));
    io_flush_bits_level        <= $urandom_range(0, 1);
    // enq 槽 0：入队率压到 30%%，否则阵列永远满、发射通路测不到
    io_enq_0_valid <= ($urandom_range(0, 99) < 30);
    io_enq_0_bits_status_robIdx_flag  <= $urandom_range(0, 1);
    io_enq_0_bits_status_robIdx_value <= 8'($urandom_range(0, 255));
    io_enq_0_bits_status_fuType_22 <= $urandom_range(0, 1);
    io_enq_0_bits_status_fuType_26 <= $urandom_range(0, 1);
    io_enq_0_bits_status_srcStatus_0_psrc <= 7'(rnd_reg());
    // src0 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_0_bits_status_srcStatus_0_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_0_bits_status_srcStatus_0_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_0_bits_status_srcStatus_0_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_0_bits_status_srcStatus_1_psrc <= 7'(rnd_reg());
    // src1 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_0_bits_status_srcStatus_1_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_0_bits_status_srcStatus_1_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_0_bits_status_srcStatus_1_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_0_bits_status_srcStatus_2_psrc <= 7'(rnd_reg());
    // src2 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_0_bits_status_srcStatus_2_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_0_bits_status_srcStatus_2_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_0_bits_status_srcStatus_2_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_0_bits_status_srcStatus_3_psrc <= 7'(rnd_reg());
    // src3 的唤醒门控位是 srcType[3]，绝大多数时候给对
    io_enq_0_bits_status_srcStatus_3_srcType <= ($urandom_range(0,99) < 88) ? 4'h8 : 4'($urandom_range(0,15));
    io_enq_0_bits_status_srcStatus_3_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_0_bits_status_srcStatus_3_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_0_bits_status_srcStatus_4_psrc <= 7'(rnd_reg());
    // src4 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_0_bits_status_srcStatus_4_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_0_bits_status_srcStatus_4_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_0_bits_status_srcStatus_4_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_0_bits_payload_fuOpType <= 9'({$urandom});
    io_enq_0_bits_payload_vecWen <= $urandom_range(0, 1);
    io_enq_0_bits_payload_v0Wen <= $urandom_range(0, 1);
    io_enq_0_bits_payload_selImm <= 4'({$urandom});
    io_enq_0_bits_payload_fpu_typeTagOut <= 2'({$urandom});
    io_enq_0_bits_payload_fpu_wflags <= $urandom_range(0, 1);
    io_enq_0_bits_payload_fpu_typ <= 2'({$urandom});
    io_enq_0_bits_payload_fpu_fmt <= 2'({$urandom});
    io_enq_0_bits_payload_fpu_rm <= 3'({$urandom});
    io_enq_0_bits_payload_vpu_vill <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_vma <= ($urandom_range(0, 99) < 60);
    io_enq_0_bits_payload_vpu_vta <= ($urandom_range(0, 99) < 60);
    io_enq_0_bits_payload_vpu_vsew <= 2'({$urandom});
    io_enq_0_bits_payload_vpu_vlmul <= 3'({$urandom});
    io_enq_0_bits_payload_vpu_specVill <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_specVma <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_specVta <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_specVsew <= 2'({$urandom});
    io_enq_0_bits_payload_vpu_specVlmul <= 3'({$urandom});
    io_enq_0_bits_payload_vpu_vm <= ($urandom_range(0, 99) < 60);
    io_enq_0_bits_payload_vpu_vstart <= 8'({$urandom});
    io_enq_0_bits_payload_vpu_frm <= 3'({$urandom});
    io_enq_0_bits_payload_vpu_fpu_isFpToVecInst <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isFP32Instr <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isFP64Instr <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isReduction <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_vxrm <= 2'({$urandom});
    io_enq_0_bits_payload_vpu_vmask <= 128'({$urandom, $urandom, $urandom, $urandom});
    io_enq_0_bits_payload_vpu_vl <= 8'({$urandom});
    io_enq_0_bits_payload_vpu_nf <= 3'({$urandom});
    io_enq_0_bits_payload_vpu_veew <= 2'({$urandom});
    io_enq_0_bits_payload_vpu_isReverse <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isExt <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isNarrow <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isDstMask <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isOpMask <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isMove <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vpu_isDependOldVd <= ($urandom_range(0, 99) < 12);
    io_enq_0_bits_payload_vpu_isWritePartVd <= ($urandom_range(0, 99) < 20);
    io_enq_0_bits_payload_vpu_isVleff <= $urandom_range(0, 1);
    io_enq_0_bits_payload_uopIdx <= 7'({$urandom});
    io_enq_0_bits_payload_lastUop <= $urandom_range(0, 1);
    io_enq_0_bits_payload_pdest <= 8'({$urandom});
    io_enq_0_bits_payload_debugInfo_eliminatedMove <= $urandom_range(0, 1);
    io_enq_0_bits_payload_debugInfo_renameTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_dispatchTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_enqRsTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_writebackTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_tlbFirstReqTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_tlbRespTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debug_seqNum_seqNum <= 56'({$urandom, $urandom});
    io_enq_0_bits_payload_debug_seqNum_uopIdx <= 8'({$urandom});
    io_enq_0_bits_payload_instr <= 32'({$urandom});
    io_enq_0_bits_payload_pc <= 50'({$urandom, $urandom});
    io_enq_0_bits_payload_foldpc <= 10'({$urandom});
    io_enq_0_bits_payload_exceptionVec_0 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_1 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_2 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_3 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_4 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_5 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_6 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_7 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_8 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_9 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_10 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_11 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_12 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_13 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_14 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_15 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_16 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_17 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_18 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_19 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_20 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_21 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_22 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_exceptionVec_23 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_isFetchMalAddr <= $urandom_range(0, 1);
    io_enq_0_bits_payload_hasException <= $urandom_range(0, 1);
    io_enq_0_bits_payload_trigger <= 4'({$urandom});
    io_enq_0_bits_payload_preDecodeInfo_valid <= $urandom_range(0, 1);
    io_enq_0_bits_payload_preDecodeInfo_isRVC <= $urandom_range(0, 1);
    io_enq_0_bits_payload_preDecodeInfo_brType <= 2'({$urandom});
    io_enq_0_bits_payload_preDecodeInfo_isCall <= $urandom_range(0, 1);
    io_enq_0_bits_payload_preDecodeInfo_isRet <= $urandom_range(0, 1);
    io_enq_0_bits_payload_pred_taken <= $urandom_range(0, 1);
    io_enq_0_bits_payload_crossPageIPFFix <= $urandom_range(0, 1);
    io_enq_0_bits_payload_ftqPtr_flag <= $urandom_range(0, 1);
    io_enq_0_bits_payload_ftqPtr_value <= 6'({$urandom});
    io_enq_0_bits_payload_ftqOffset <= 4'({$urandom});
    io_enq_0_bits_payload_satpFlushFirstFetchFault <= $urandom_range(0, 1);
    io_enq_0_bits_payload_srcType_0 <= 4'({$urandom});
    io_enq_0_bits_payload_srcType_1 <= 4'({$urandom});
    io_enq_0_bits_payload_srcType_2 <= 4'({$urandom});
    io_enq_0_bits_payload_srcType_3 <= 4'({$urandom});
    io_enq_0_bits_payload_srcType_4 <= 4'({$urandom});
    io_enq_0_bits_payload_ldest <= 6'({$urandom});
    io_enq_0_bits_payload_fuType <= 35'({$urandom, $urandom});
    io_enq_0_bits_payload_rfWen <= $urandom_range(0, 1);
    io_enq_0_bits_payload_fpWen <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vlWen <= $urandom_range(0, 1);
    io_enq_0_bits_payload_isXSTrap <= $urandom_range(0, 1);
    io_enq_0_bits_payload_waitForward <= $urandom_range(0, 1);
    io_enq_0_bits_payload_blockBackward <= $urandom_range(0, 1);
    io_enq_0_bits_payload_flushPipe <= $urandom_range(0, 1);
    io_enq_0_bits_payload_canRobCompress <= $urandom_range(0, 1);
    io_enq_0_bits_payload_imm <= 32'({$urandom});
    io_enq_0_bits_payload_vpu_vuopIdx <= 7'({$urandom});
    io_enq_0_bits_payload_vpu_lastUop <= $urandom_range(0, 1);
    io_enq_0_bits_payload_vlsInstr <= $urandom_range(0, 1);
    io_enq_0_bits_payload_wfflags <= $urandom_range(0, 1);
    io_enq_0_bits_payload_isMove <= $urandom_range(0, 1);
    io_enq_0_bits_payload_isDropAmocasSta <= $urandom_range(0, 1);
    io_enq_0_bits_payload_isVset <= $urandom_range(0, 1);
    io_enq_0_bits_payload_firstUop <= $urandom_range(0, 1);
    io_enq_0_bits_payload_numUops <= 7'({$urandom});
    io_enq_0_bits_payload_numWB <= 7'({$urandom});
    io_enq_0_bits_payload_commitType <= 3'({$urandom});
    io_enq_0_bits_payload_srcState_0 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_srcState_1 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_srcState_2 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_srcState_3 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_srcState_4 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_psrc_0 <= 8'({$urandom});
    io_enq_0_bits_payload_psrc_1 <= 8'({$urandom});
    io_enq_0_bits_payload_psrc_2 <= 8'({$urandom});
    io_enq_0_bits_payload_psrc_3 <= 8'({$urandom});
    io_enq_0_bits_payload_psrc_4 <= 8'({$urandom});
    io_enq_0_bits_payload_useRegCache_0 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_useRegCache_1 <= $urandom_range(0, 1);
    io_enq_0_bits_payload_regCacheIdx_0 <= 5'({$urandom});
    io_enq_0_bits_payload_regCacheIdx_1 <= 5'({$urandom});
    io_enq_0_bits_payload_robIdx_flag <= $urandom_range(0, 1);
    io_enq_0_bits_payload_robIdx_value <= 8'({$urandom});
    io_enq_0_bits_payload_instrSize <= 3'({$urandom});
    io_enq_0_bits_payload_dirtyFs <= $urandom_range(0, 1);
    io_enq_0_bits_payload_dirtyVs <= $urandom_range(0, 1);
    io_enq_0_bits_payload_traceBlockInPipe_itype <= 4'({$urandom});
    io_enq_0_bits_payload_traceBlockInPipe_iretire <= 4'({$urandom});
    io_enq_0_bits_payload_traceBlockInPipe_ilastsize <= $urandom_range(0, 1);
    io_enq_0_bits_payload_eliminatedMove <= $urandom_range(0, 1);
    io_enq_0_bits_payload_snapshot <= $urandom_range(0, 1);
    io_enq_0_bits_payload_debugInfo_selectTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_debugInfo_issueTime <= 64'({$urandom, $urandom});
    io_enq_0_bits_payload_storeSetHit <= $urandom_range(0, 1);
    io_enq_0_bits_payload_waitForRobIdx_flag <= $urandom_range(0, 1);
    io_enq_0_bits_payload_waitForRobIdx_value <= 8'({$urandom});
    io_enq_0_bits_payload_loadWaitBit <= $urandom_range(0, 1);
    io_enq_0_bits_payload_loadWaitStrict <= $urandom_range(0, 1);
    io_enq_0_bits_payload_ssid <= 5'({$urandom});
    io_enq_0_bits_payload_lqIdx_flag <= $urandom_range(0, 1);
    io_enq_0_bits_payload_lqIdx_value <= 7'({$urandom});
    io_enq_0_bits_payload_sqIdx_flag <= $urandom_range(0, 1);
    io_enq_0_bits_payload_sqIdx_value <= 6'({$urandom});
    io_enq_0_bits_payload_singleStep <= $urandom_range(0, 1);
    io_enq_0_bits_payload_replayInst <= $urandom_range(0, 1);
    io_enq_0_bits_payload_debug_fuType <= 35'({$urandom, $urandom});
    io_enq_0_bits_payload_debug_sim_trig <= $urandom_range(0, 1);
    io_enq_0_bits_payload_numLsElem <= 5'({$urandom});
    // enq 槽 1：入队率压到 30%%，否则阵列永远满、发射通路测不到
    io_enq_1_valid <= ($urandom_range(0, 99) < 30);
    io_enq_1_bits_status_robIdx_flag  <= $urandom_range(0, 1);
    io_enq_1_bits_status_robIdx_value <= 8'($urandom_range(0, 255));
    io_enq_1_bits_status_fuType_22 <= $urandom_range(0, 1);
    io_enq_1_bits_status_fuType_26 <= $urandom_range(0, 1);
    io_enq_1_bits_status_srcStatus_0_psrc <= 7'(rnd_reg());
    // src0 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_1_bits_status_srcStatus_0_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_1_bits_status_srcStatus_0_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_1_bits_status_srcStatus_0_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_1_bits_status_srcStatus_1_psrc <= 7'(rnd_reg());
    // src1 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_1_bits_status_srcStatus_1_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_1_bits_status_srcStatus_1_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_1_bits_status_srcStatus_1_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_1_bits_status_srcStatus_2_psrc <= 7'(rnd_reg());
    // src2 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_1_bits_status_srcStatus_2_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_1_bits_status_srcStatus_2_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_1_bits_status_srcStatus_2_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_1_bits_status_srcStatus_3_psrc <= 7'(rnd_reg());
    // src3 的唤醒门控位是 srcType[3]，绝大多数时候给对
    io_enq_1_bits_status_srcStatus_3_srcType <= ($urandom_range(0,99) < 88) ? 4'h8 : 4'($urandom_range(0,15));
    io_enq_1_bits_status_srcStatus_3_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_1_bits_status_srcStatus_3_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_1_bits_status_srcStatus_4_psrc <= 7'(rnd_reg());
    // src4 的唤醒门控位是 srcType[2]，绝大多数时候给对
    io_enq_1_bits_status_srcStatus_4_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_enq_1_bits_status_srcStatus_4_srcState <= ($urandom_range(0, 99) < 72);
    io_enq_1_bits_status_srcStatus_4_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_enq_1_bits_payload_fuOpType <= 9'({$urandom});
    io_enq_1_bits_payload_vecWen <= $urandom_range(0, 1);
    io_enq_1_bits_payload_v0Wen <= $urandom_range(0, 1);
    io_enq_1_bits_payload_selImm <= 4'({$urandom});
    io_enq_1_bits_payload_fpu_typeTagOut <= 2'({$urandom});
    io_enq_1_bits_payload_fpu_wflags <= $urandom_range(0, 1);
    io_enq_1_bits_payload_fpu_typ <= 2'({$urandom});
    io_enq_1_bits_payload_fpu_fmt <= 2'({$urandom});
    io_enq_1_bits_payload_fpu_rm <= 3'({$urandom});
    io_enq_1_bits_payload_vpu_vill <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_vma <= ($urandom_range(0, 99) < 60);
    io_enq_1_bits_payload_vpu_vta <= ($urandom_range(0, 99) < 60);
    io_enq_1_bits_payload_vpu_vsew <= 2'({$urandom});
    io_enq_1_bits_payload_vpu_vlmul <= 3'({$urandom});
    io_enq_1_bits_payload_vpu_specVill <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_specVma <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_specVta <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_specVsew <= 2'({$urandom});
    io_enq_1_bits_payload_vpu_specVlmul <= 3'({$urandom});
    io_enq_1_bits_payload_vpu_vm <= ($urandom_range(0, 99) < 60);
    io_enq_1_bits_payload_vpu_vstart <= 8'({$urandom});
    io_enq_1_bits_payload_vpu_frm <= 3'({$urandom});
    io_enq_1_bits_payload_vpu_fpu_isFpToVecInst <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isFP32Instr <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isFP64Instr <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isReduction <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_vxrm <= 2'({$urandom});
    io_enq_1_bits_payload_vpu_vmask <= 128'({$urandom, $urandom, $urandom, $urandom});
    io_enq_1_bits_payload_vpu_vl <= 8'({$urandom});
    io_enq_1_bits_payload_vpu_nf <= 3'({$urandom});
    io_enq_1_bits_payload_vpu_veew <= 2'({$urandom});
    io_enq_1_bits_payload_vpu_isReverse <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isExt <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isNarrow <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isDstMask <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isOpMask <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isMove <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vpu_isDependOldVd <= ($urandom_range(0, 99) < 12);
    io_enq_1_bits_payload_vpu_isWritePartVd <= ($urandom_range(0, 99) < 20);
    io_enq_1_bits_payload_vpu_isVleff <= $urandom_range(0, 1);
    io_enq_1_bits_payload_uopIdx <= 7'({$urandom});
    io_enq_1_bits_payload_lastUop <= $urandom_range(0, 1);
    io_enq_1_bits_payload_pdest <= 8'({$urandom});
    io_enq_1_bits_payload_debugInfo_eliminatedMove <= $urandom_range(0, 1);
    io_enq_1_bits_payload_debugInfo_renameTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_dispatchTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_enqRsTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_writebackTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_tlbFirstReqTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_tlbRespTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debug_seqNum_seqNum <= 56'({$urandom, $urandom});
    io_enq_1_bits_payload_debug_seqNum_uopIdx <= 8'({$urandom});
    io_enq_1_bits_payload_instr <= 32'({$urandom});
    io_enq_1_bits_payload_pc <= 50'({$urandom, $urandom});
    io_enq_1_bits_payload_foldpc <= 10'({$urandom});
    io_enq_1_bits_payload_exceptionVec_0 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_1 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_2 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_3 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_4 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_5 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_6 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_7 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_8 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_9 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_10 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_11 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_12 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_13 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_14 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_15 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_16 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_17 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_18 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_19 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_20 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_21 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_22 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_exceptionVec_23 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_isFetchMalAddr <= $urandom_range(0, 1);
    io_enq_1_bits_payload_hasException <= $urandom_range(0, 1);
    io_enq_1_bits_payload_trigger <= 4'({$urandom});
    io_enq_1_bits_payload_preDecodeInfo_valid <= $urandom_range(0, 1);
    io_enq_1_bits_payload_preDecodeInfo_isRVC <= $urandom_range(0, 1);
    io_enq_1_bits_payload_preDecodeInfo_brType <= 2'({$urandom});
    io_enq_1_bits_payload_preDecodeInfo_isCall <= $urandom_range(0, 1);
    io_enq_1_bits_payload_preDecodeInfo_isRet <= $urandom_range(0, 1);
    io_enq_1_bits_payload_pred_taken <= $urandom_range(0, 1);
    io_enq_1_bits_payload_crossPageIPFFix <= $urandom_range(0, 1);
    io_enq_1_bits_payload_ftqPtr_flag <= $urandom_range(0, 1);
    io_enq_1_bits_payload_ftqPtr_value <= 6'({$urandom});
    io_enq_1_bits_payload_ftqOffset <= 4'({$urandom});
    io_enq_1_bits_payload_satpFlushFirstFetchFault <= $urandom_range(0, 1);
    io_enq_1_bits_payload_srcType_0 <= 4'({$urandom});
    io_enq_1_bits_payload_srcType_1 <= 4'({$urandom});
    io_enq_1_bits_payload_srcType_2 <= 4'({$urandom});
    io_enq_1_bits_payload_srcType_3 <= 4'({$urandom});
    io_enq_1_bits_payload_srcType_4 <= 4'({$urandom});
    io_enq_1_bits_payload_ldest <= 6'({$urandom});
    io_enq_1_bits_payload_fuType <= 35'({$urandom, $urandom});
    io_enq_1_bits_payload_rfWen <= $urandom_range(0, 1);
    io_enq_1_bits_payload_fpWen <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vlWen <= $urandom_range(0, 1);
    io_enq_1_bits_payload_isXSTrap <= $urandom_range(0, 1);
    io_enq_1_bits_payload_waitForward <= $urandom_range(0, 1);
    io_enq_1_bits_payload_blockBackward <= $urandom_range(0, 1);
    io_enq_1_bits_payload_flushPipe <= $urandom_range(0, 1);
    io_enq_1_bits_payload_canRobCompress <= $urandom_range(0, 1);
    io_enq_1_bits_payload_imm <= 32'({$urandom});
    io_enq_1_bits_payload_vpu_vuopIdx <= 7'({$urandom});
    io_enq_1_bits_payload_vpu_lastUop <= $urandom_range(0, 1);
    io_enq_1_bits_payload_vlsInstr <= $urandom_range(0, 1);
    io_enq_1_bits_payload_wfflags <= $urandom_range(0, 1);
    io_enq_1_bits_payload_isMove <= $urandom_range(0, 1);
    io_enq_1_bits_payload_isDropAmocasSta <= $urandom_range(0, 1);
    io_enq_1_bits_payload_isVset <= $urandom_range(0, 1);
    io_enq_1_bits_payload_firstUop <= $urandom_range(0, 1);
    io_enq_1_bits_payload_numUops <= 7'({$urandom});
    io_enq_1_bits_payload_numWB <= 7'({$urandom});
    io_enq_1_bits_payload_commitType <= 3'({$urandom});
    io_enq_1_bits_payload_srcState_0 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_srcState_1 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_srcState_2 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_srcState_3 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_srcState_4 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_psrc_0 <= 8'({$urandom});
    io_enq_1_bits_payload_psrc_1 <= 8'({$urandom});
    io_enq_1_bits_payload_psrc_2 <= 8'({$urandom});
    io_enq_1_bits_payload_psrc_3 <= 8'({$urandom});
    io_enq_1_bits_payload_psrc_4 <= 8'({$urandom});
    io_enq_1_bits_payload_useRegCache_0 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_useRegCache_1 <= $urandom_range(0, 1);
    io_enq_1_bits_payload_regCacheIdx_0 <= 5'({$urandom});
    io_enq_1_bits_payload_regCacheIdx_1 <= 5'({$urandom});
    io_enq_1_bits_payload_robIdx_flag <= $urandom_range(0, 1);
    io_enq_1_bits_payload_robIdx_value <= 8'({$urandom});
    io_enq_1_bits_payload_instrSize <= 3'({$urandom});
    io_enq_1_bits_payload_dirtyFs <= $urandom_range(0, 1);
    io_enq_1_bits_payload_dirtyVs <= $urandom_range(0, 1);
    io_enq_1_bits_payload_traceBlockInPipe_itype <= 4'({$urandom});
    io_enq_1_bits_payload_traceBlockInPipe_iretire <= 4'({$urandom});
    io_enq_1_bits_payload_traceBlockInPipe_ilastsize <= $urandom_range(0, 1);
    io_enq_1_bits_payload_eliminatedMove <= $urandom_range(0, 1);
    io_enq_1_bits_payload_snapshot <= $urandom_range(0, 1);
    io_enq_1_bits_payload_debugInfo_selectTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_debugInfo_issueTime <= 64'({$urandom, $urandom});
    io_enq_1_bits_payload_storeSetHit <= $urandom_range(0, 1);
    io_enq_1_bits_payload_waitForRobIdx_flag <= $urandom_range(0, 1);
    io_enq_1_bits_payload_waitForRobIdx_value <= 8'({$urandom});
    io_enq_1_bits_payload_loadWaitBit <= $urandom_range(0, 1);
    io_enq_1_bits_payload_loadWaitStrict <= $urandom_range(0, 1);
    io_enq_1_bits_payload_ssid <= 5'({$urandom});
    io_enq_1_bits_payload_lqIdx_flag <= $urandom_range(0, 1);
    io_enq_1_bits_payload_lqIdx_value <= 7'({$urandom});
    io_enq_1_bits_payload_sqIdx_flag <= $urandom_range(0, 1);
    io_enq_1_bits_payload_sqIdx_value <= 6'({$urandom});
    io_enq_1_bits_payload_singleStep <= $urandom_range(0, 1);
    io_enq_1_bits_payload_replayInst <= $urandom_range(0, 1);
    io_enq_1_bits_payload_debug_fuType <= 35'({$urandom, $urandom});
    io_enq_1_bits_payload_debug_sim_trig <= $urandom_range(0, 1);
    io_enq_1_bits_payload_numLsElem <= 5'({$urandom});
    // 唤醒总线：pdest 取自小池，写使能高概率有效
    io_wakeUpFromWB_0_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_0_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_0_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_1_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_1_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_1_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_2_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_2_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_2_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_3_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_3_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_3_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_4_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_4_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_4_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_5_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_5_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_5_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_6_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_6_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_6_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_7_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_7_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_7_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_8_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_8_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_8_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_9_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_9_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_9_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_10_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_10_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_10_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_11_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_11_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_11_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_12_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_12_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_12_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_13_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_13_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_13_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_14_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_14_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_14_bits_pdest <= 8'(rnd_reg());
    io_wakeUpFromWB_15_valid <= ($urandom_range(0, 99) < 35);
    io_wakeUpFromWB_15_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_wakeUpFromWB_15_bits_pdest <= 8'(rnd_reg());
    io_vlFromIntIsZero  <= ($urandom_range(0, 99) < 15);
    io_vlFromIntIsVlmax <= ($urandom_range(0, 99) < 55);
    io_vlFromVfIsZero   <= ($urandom_range(0, 99) < 15);
    io_vlFromVfIsVlmax  <= ($urandom_range(0, 99) < 55);
  endtask

  // wakeUpFromWBDelayed = wakeUpFromWB 打一拍（golden 上层 IssueQueue 就是这么接的）
  always @(posedge clock) begin
    io_wakeUpFromWBDelayed_0_valid <= io_wakeUpFromWB_0_valid;
    io_wakeUpFromWBDelayed_0_bits_vecWen <= io_wakeUpFromWB_0_bits_vecWen;
    io_wakeUpFromWBDelayed_0_bits_pdest <= io_wakeUpFromWB_0_bits_pdest;
    io_wakeUpFromWBDelayed_1_valid <= io_wakeUpFromWB_1_valid;
    io_wakeUpFromWBDelayed_1_bits_vecWen <= io_wakeUpFromWB_1_bits_vecWen;
    io_wakeUpFromWBDelayed_1_bits_pdest <= io_wakeUpFromWB_1_bits_pdest;
    io_wakeUpFromWBDelayed_2_valid <= io_wakeUpFromWB_2_valid;
    io_wakeUpFromWBDelayed_2_bits_vecWen <= io_wakeUpFromWB_2_bits_vecWen;
    io_wakeUpFromWBDelayed_2_bits_pdest <= io_wakeUpFromWB_2_bits_pdest;
    io_wakeUpFromWBDelayed_3_valid <= io_wakeUpFromWB_3_valid;
    io_wakeUpFromWBDelayed_3_bits_vecWen <= io_wakeUpFromWB_3_bits_vecWen;
    io_wakeUpFromWBDelayed_3_bits_pdest <= io_wakeUpFromWB_3_bits_pdest;
    io_wakeUpFromWBDelayed_4_valid <= io_wakeUpFromWB_4_valid;
    io_wakeUpFromWBDelayed_4_bits_vecWen <= io_wakeUpFromWB_4_bits_vecWen;
    io_wakeUpFromWBDelayed_4_bits_pdest <= io_wakeUpFromWB_4_bits_pdest;
    io_wakeUpFromWBDelayed_5_valid <= io_wakeUpFromWB_5_valid;
    io_wakeUpFromWBDelayed_5_bits_vecWen <= io_wakeUpFromWB_5_bits_vecWen;
    io_wakeUpFromWBDelayed_5_bits_pdest <= io_wakeUpFromWB_5_bits_pdest;
    io_wakeUpFromWBDelayed_6_valid <= io_wakeUpFromWB_6_valid;
    io_wakeUpFromWBDelayed_6_bits_v0Wen <= io_wakeUpFromWB_6_bits_v0Wen;
    io_wakeUpFromWBDelayed_6_bits_pdest <= io_wakeUpFromWB_6_bits_pdest;
    io_wakeUpFromWBDelayed_7_valid <= io_wakeUpFromWB_7_valid;
    io_wakeUpFromWBDelayed_7_bits_v0Wen <= io_wakeUpFromWB_7_bits_v0Wen;
    io_wakeUpFromWBDelayed_7_bits_pdest <= io_wakeUpFromWB_7_bits_pdest;
    io_wakeUpFromWBDelayed_8_valid <= io_wakeUpFromWB_8_valid;
    io_wakeUpFromWBDelayed_8_bits_v0Wen <= io_wakeUpFromWB_8_bits_v0Wen;
    io_wakeUpFromWBDelayed_8_bits_pdest <= io_wakeUpFromWB_8_bits_pdest;
    io_wakeUpFromWBDelayed_9_valid <= io_wakeUpFromWB_9_valid;
    io_wakeUpFromWBDelayed_9_bits_v0Wen <= io_wakeUpFromWB_9_bits_v0Wen;
    io_wakeUpFromWBDelayed_9_bits_pdest <= io_wakeUpFromWB_9_bits_pdest;
    io_wakeUpFromWBDelayed_10_valid <= io_wakeUpFromWB_10_valid;
    io_wakeUpFromWBDelayed_10_bits_v0Wen <= io_wakeUpFromWB_10_bits_v0Wen;
    io_wakeUpFromWBDelayed_10_bits_pdest <= io_wakeUpFromWB_10_bits_pdest;
    io_wakeUpFromWBDelayed_11_valid <= io_wakeUpFromWB_11_valid;
    io_wakeUpFromWBDelayed_11_bits_v0Wen <= io_wakeUpFromWB_11_bits_v0Wen;
    io_wakeUpFromWBDelayed_11_bits_pdest <= io_wakeUpFromWB_11_bits_pdest;
    io_wakeUpFromWBDelayed_12_valid <= io_wakeUpFromWB_12_valid;
    io_wakeUpFromWBDelayed_12_bits_vlWen <= io_wakeUpFromWB_12_bits_vlWen;
    io_wakeUpFromWBDelayed_12_bits_pdest <= io_wakeUpFromWB_12_bits_pdest;
    io_wakeUpFromWBDelayed_13_valid <= io_wakeUpFromWB_13_valid;
    io_wakeUpFromWBDelayed_13_bits_vlWen <= io_wakeUpFromWB_13_bits_vlWen;
    io_wakeUpFromWBDelayed_13_bits_pdest <= io_wakeUpFromWB_13_bits_pdest;
    io_wakeUpFromWBDelayed_14_valid <= io_wakeUpFromWB_14_valid;
    io_wakeUpFromWBDelayed_14_bits_vlWen <= io_wakeUpFromWB_14_bits_vlWen;
    io_wakeUpFromWBDelayed_14_bits_pdest <= io_wakeUpFromWB_14_bits_pdest;
    io_wakeUpFromWBDelayed_15_valid <= io_wakeUpFromWB_15_valid;
    io_wakeUpFromWBDelayed_15_bits_vlWen <= io_wakeUpFromWB_15_bits_vlWen;
    io_wakeUpFromWBDelayed_15_bits_pdest <= io_wakeUpFromWB_15_bits_pdest;
  end

  // ---- 发射/年龄选择：在输入落定之后、时钟沿之前用阻塞赋值算 ----
  task automatic drive_deq();
    logic [9:0] ci;
    int pick, cnt;
    ci  = g_io_canIssue;
    cnt = $countones(ci);
    io_deqSelOH_0_valid = 1'b0;
    io_deqSelOH_0_bits  = 10'h0;
    if (cnt > 0 && $urandom_range(0, 99) < 80) begin
      pick = $urandom_range(0, cnt-1);
      for (int k = 0; k < 10; k++)
        if (ci[k]) begin
          if (pick == 0) begin io_deqSelOH_0_valid = 1'b1; io_deqSelOH_0_bits = 10'(1) << k; end
          pick--;
        end
    end
    io_deqReady_0          = ($urandom_range(0, 99) < 90);
    io_og0Resp_0_valid     = ($urandom_range(0, 99) < 15);
    io_og1Resp_0_valid     = ($urandom_range(0, 99) < 15);
    io_og2Resp_0_valid     = ($urandom_range(0, 99) < 70);
    io_og2Resp_0_bits_resp = ($urandom_range(0,99) < 65) ? 2'b11 : (($urandom_range(0,1)) ? 2'b00 : 2'b01);
    io_enqEntryOldestSel_0_bits   = 2'(1) << $urandom_range(0, 1);
    io_simpEntryOldestSel_0_valid = |g_io_valid[3:2];
    io_simpEntryOldestSel_0_bits  = 2'(1) << $urandom_range(0, 1);
    io_compEntryOldestSel_0_valid = |g_io_valid[9:4];
    io_compEntryOldestSel_0_bits  = 6'(1) << $urandom_range(0, 5);
    io_simpEntryDeqSelVec_0 = ($urandom_range(0,99) < 65) ? (2'(1) << $urandom_range(0, 1)) : 2'h0;
    io_simpEntryDeqSelVec_1 = ($urandom_range(0,99) < 65) ? (2'(1) << $urandom_range(0, 1)) : 2'h0;
  endtask

  // ---- 覆盖采样：全在**时钟沿之前**，采的是这一拍将要生效的激励与当前状态。
  //      发射类事件必须这样采：沿上 issued 一置位，canIssue 立刻掉，事后采不到。----
  task automatic sample_cov();
    if (|{io_enq_0_valid, io_enq_1_valid}) cov_enq_fire++;
    if (|g_io_canIssue) cov_can_issue++;
    if (io_deqSelOH_0_valid && io_deqReady_0 && (g_io_canIssue & io_deqSelOH_0_bits)) cov_deq_fire++;
    if (g_io_isFirstIssue_0) cov_first_issue++;
    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b11) cov_resp_succ++;
    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b00) cov_resp_block++;
    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b01) cov_resp_uncertain++;
    if (|{g_io_simpEntryEnqSelVec_0, g_io_simpEntryEnqSelVec_1}) cov_trans2simp++;
    if (|{g_io_compEntryEnqSelVec_0, g_io_compEntryEnqSelVec_1}) cov_trans2comp++;
    if (&g_io_valid) cov_full++;
    if (io_flush_valid) cov_flush++;
    // 白盒探针（只探 golden 侧；impl 侧的一致性由逐拍输出比对保证）
    if (u_g.enqEntries_0.ignoreOldVd_2 === 1'b1 || u_g.enqEntries_1.ignoreOldVd_2 === 1'b1) cov_ignore_old_vd++;
    if (u_g.othersEntriesSimp_0.io_commonIn_transSel === 1'b1 || u_g.othersEntriesSimp_1.io_commonIn_transSel === 1'b1) cov_simp2comp++;
    // wb_wake：某个「原本未就绪」的源本拍被唤醒翻成就绪
    if ((u_g.enqEntries_0.entryUpdate_status_srcStatus_0_srcState === 1'b1 && u_g.enqEntries_0.entryReg_status_srcStatus_0_srcState === 1'b0) || (u_g.enqEntries_1.entryUpdate_status_srcStatus_0_srcState === 1'b1 && u_g.enqEntries_1.entryReg_status_srcStatus_0_srcState === 1'b0) || (u_g.othersEntriesSimp_0.entryUpdate_status_srcStatus_0_srcState === 1'b1 && u_g.othersEntriesSimp_0.entryReg_status_srcStatus_0_srcState === 1'b0) || (u_g.othersEntriesSimp_1.entryUpdate_status_srcStatus_0_srcState === 1'b1 && u_g.othersEntriesSimp_1.entryReg_status_srcStatus_0_srcState === 1'b0)) cov_wb_wake++;
    // deq_clear：发射成功把条目清空（validReg 由 1 变 0 且不是被冲刷/转移）
    if ((u_g.othersEntriesComp_0.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_0.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_0.io_commonIn_issueResp_bits_resp === 2'b11) || (u_g.othersEntriesComp_1.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_1.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_1.io_commonIn_issueResp_bits_resp === 2'b11) || (u_g.othersEntriesComp_2.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_2.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_2.io_commonIn_issueResp_bits_resp === 2'b11) || (u_g.othersEntriesComp_3.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_3.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_3.io_commonIn_issueResp_bits_resp === 2'b11) || (u_g.othersEntriesComp_4.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_4.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_4.io_commonIn_issueResp_bits_resp === 2'b11) || (u_g.othersEntriesComp_5.validReg_last_REG === 1'b1 && u_g.othersEntriesComp_5.io_commonIn_issueResp_valid === 1'b1 && u_g.othersEntriesComp_5.io_commonIn_issueResp_bits_resp === 2'b11)) cov_deq_clear++;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1'b1;
    io_flush_valid = '0;
    io_flush_bits_robIdx_flag = '0;
    io_flush_bits_robIdx_value = '0;
    io_flush_bits_level = '0;
    io_enq_0_valid = '0;
    io_enq_0_bits_status_robIdx_flag = '0;
    io_enq_0_bits_status_robIdx_value = '0;
    io_enq_0_bits_status_fuType_22 = '0;
    io_enq_0_bits_status_fuType_26 = '0;
    io_enq_0_bits_status_srcStatus_0_psrc = '0;
    io_enq_0_bits_status_srcStatus_0_srcType = '0;
    io_enq_0_bits_status_srcStatus_0_srcState = '0;
    io_enq_0_bits_status_srcStatus_0_dataSources_value = '0;
    io_enq_0_bits_status_srcStatus_1_psrc = '0;
    io_enq_0_bits_status_srcStatus_1_srcType = '0;
    io_enq_0_bits_status_srcStatus_1_srcState = '0;
    io_enq_0_bits_status_srcStatus_1_dataSources_value = '0;
    io_enq_0_bits_status_srcStatus_2_psrc = '0;
    io_enq_0_bits_status_srcStatus_2_srcType = '0;
    io_enq_0_bits_status_srcStatus_2_srcState = '0;
    io_enq_0_bits_status_srcStatus_2_dataSources_value = '0;
    io_enq_0_bits_status_srcStatus_3_psrc = '0;
    io_enq_0_bits_status_srcStatus_3_srcType = '0;
    io_enq_0_bits_status_srcStatus_3_srcState = '0;
    io_enq_0_bits_status_srcStatus_3_dataSources_value = '0;
    io_enq_0_bits_status_srcStatus_4_psrc = '0;
    io_enq_0_bits_status_srcStatus_4_srcType = '0;
    io_enq_0_bits_status_srcStatus_4_srcState = '0;
    io_enq_0_bits_status_srcStatus_4_dataSources_value = '0;
    io_enq_0_bits_payload_instr = '0;
    io_enq_0_bits_payload_pc = '0;
    io_enq_0_bits_payload_foldpc = '0;
    io_enq_0_bits_payload_exceptionVec_0 = '0;
    io_enq_0_bits_payload_exceptionVec_1 = '0;
    io_enq_0_bits_payload_exceptionVec_2 = '0;
    io_enq_0_bits_payload_exceptionVec_3 = '0;
    io_enq_0_bits_payload_exceptionVec_4 = '0;
    io_enq_0_bits_payload_exceptionVec_5 = '0;
    io_enq_0_bits_payload_exceptionVec_6 = '0;
    io_enq_0_bits_payload_exceptionVec_7 = '0;
    io_enq_0_bits_payload_exceptionVec_8 = '0;
    io_enq_0_bits_payload_exceptionVec_9 = '0;
    io_enq_0_bits_payload_exceptionVec_10 = '0;
    io_enq_0_bits_payload_exceptionVec_11 = '0;
    io_enq_0_bits_payload_exceptionVec_12 = '0;
    io_enq_0_bits_payload_exceptionVec_13 = '0;
    io_enq_0_bits_payload_exceptionVec_14 = '0;
    io_enq_0_bits_payload_exceptionVec_15 = '0;
    io_enq_0_bits_payload_exceptionVec_16 = '0;
    io_enq_0_bits_payload_exceptionVec_17 = '0;
    io_enq_0_bits_payload_exceptionVec_18 = '0;
    io_enq_0_bits_payload_exceptionVec_19 = '0;
    io_enq_0_bits_payload_exceptionVec_20 = '0;
    io_enq_0_bits_payload_exceptionVec_21 = '0;
    io_enq_0_bits_payload_exceptionVec_22 = '0;
    io_enq_0_bits_payload_exceptionVec_23 = '0;
    io_enq_0_bits_payload_isFetchMalAddr = '0;
    io_enq_0_bits_payload_hasException = '0;
    io_enq_0_bits_payload_trigger = '0;
    io_enq_0_bits_payload_preDecodeInfo_valid = '0;
    io_enq_0_bits_payload_preDecodeInfo_isRVC = '0;
    io_enq_0_bits_payload_preDecodeInfo_brType = '0;
    io_enq_0_bits_payload_preDecodeInfo_isCall = '0;
    io_enq_0_bits_payload_preDecodeInfo_isRet = '0;
    io_enq_0_bits_payload_pred_taken = '0;
    io_enq_0_bits_payload_crossPageIPFFix = '0;
    io_enq_0_bits_payload_ftqPtr_flag = '0;
    io_enq_0_bits_payload_ftqPtr_value = '0;
    io_enq_0_bits_payload_ftqOffset = '0;
    io_enq_0_bits_payload_satpFlushFirstFetchFault = '0;
    io_enq_0_bits_payload_srcType_0 = '0;
    io_enq_0_bits_payload_srcType_1 = '0;
    io_enq_0_bits_payload_srcType_2 = '0;
    io_enq_0_bits_payload_srcType_3 = '0;
    io_enq_0_bits_payload_srcType_4 = '0;
    io_enq_0_bits_payload_ldest = '0;
    io_enq_0_bits_payload_fuType = '0;
    io_enq_0_bits_payload_fuOpType = '0;
    io_enq_0_bits_payload_rfWen = '0;
    io_enq_0_bits_payload_fpWen = '0;
    io_enq_0_bits_payload_vecWen = '0;
    io_enq_0_bits_payload_v0Wen = '0;
    io_enq_0_bits_payload_vlWen = '0;
    io_enq_0_bits_payload_isXSTrap = '0;
    io_enq_0_bits_payload_waitForward = '0;
    io_enq_0_bits_payload_blockBackward = '0;
    io_enq_0_bits_payload_flushPipe = '0;
    io_enq_0_bits_payload_canRobCompress = '0;
    io_enq_0_bits_payload_selImm = '0;
    io_enq_0_bits_payload_imm = '0;
    io_enq_0_bits_payload_fpu_typeTagOut = '0;
    io_enq_0_bits_payload_fpu_wflags = '0;
    io_enq_0_bits_payload_fpu_typ = '0;
    io_enq_0_bits_payload_fpu_fmt = '0;
    io_enq_0_bits_payload_fpu_rm = '0;
    io_enq_0_bits_payload_vpu_vill = '0;
    io_enq_0_bits_payload_vpu_vma = '0;
    io_enq_0_bits_payload_vpu_vta = '0;
    io_enq_0_bits_payload_vpu_vsew = '0;
    io_enq_0_bits_payload_vpu_vlmul = '0;
    io_enq_0_bits_payload_vpu_specVill = '0;
    io_enq_0_bits_payload_vpu_specVma = '0;
    io_enq_0_bits_payload_vpu_specVta = '0;
    io_enq_0_bits_payload_vpu_specVsew = '0;
    io_enq_0_bits_payload_vpu_specVlmul = '0;
    io_enq_0_bits_payload_vpu_vm = '0;
    io_enq_0_bits_payload_vpu_vstart = '0;
    io_enq_0_bits_payload_vpu_frm = '0;
    io_enq_0_bits_payload_vpu_fpu_isFpToVecInst = '0;
    io_enq_0_bits_payload_vpu_fpu_isFP32Instr = '0;
    io_enq_0_bits_payload_vpu_fpu_isFP64Instr = '0;
    io_enq_0_bits_payload_vpu_fpu_isReduction = '0;
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2 = '0;
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4 = '0;
    io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8 = '0;
    io_enq_0_bits_payload_vpu_vxrm = '0;
    io_enq_0_bits_payload_vpu_vuopIdx = '0;
    io_enq_0_bits_payload_vpu_lastUop = '0;
    io_enq_0_bits_payload_vpu_vmask = '0;
    io_enq_0_bits_payload_vpu_vl = '0;
    io_enq_0_bits_payload_vpu_nf = '0;
    io_enq_0_bits_payload_vpu_veew = '0;
    io_enq_0_bits_payload_vpu_isReverse = '0;
    io_enq_0_bits_payload_vpu_isExt = '0;
    io_enq_0_bits_payload_vpu_isNarrow = '0;
    io_enq_0_bits_payload_vpu_isDstMask = '0;
    io_enq_0_bits_payload_vpu_isOpMask = '0;
    io_enq_0_bits_payload_vpu_isMove = '0;
    io_enq_0_bits_payload_vpu_isDependOldVd = '0;
    io_enq_0_bits_payload_vpu_isWritePartVd = '0;
    io_enq_0_bits_payload_vpu_isVleff = '0;
    io_enq_0_bits_payload_vlsInstr = '0;
    io_enq_0_bits_payload_wfflags = '0;
    io_enq_0_bits_payload_isMove = '0;
    io_enq_0_bits_payload_isDropAmocasSta = '0;
    io_enq_0_bits_payload_uopIdx = '0;
    io_enq_0_bits_payload_isVset = '0;
    io_enq_0_bits_payload_firstUop = '0;
    io_enq_0_bits_payload_lastUop = '0;
    io_enq_0_bits_payload_numUops = '0;
    io_enq_0_bits_payload_numWB = '0;
    io_enq_0_bits_payload_commitType = '0;
    io_enq_0_bits_payload_srcState_0 = '0;
    io_enq_0_bits_payload_srcState_1 = '0;
    io_enq_0_bits_payload_srcState_2 = '0;
    io_enq_0_bits_payload_srcState_3 = '0;
    io_enq_0_bits_payload_srcState_4 = '0;
    io_enq_0_bits_payload_psrc_0 = '0;
    io_enq_0_bits_payload_psrc_1 = '0;
    io_enq_0_bits_payload_psrc_2 = '0;
    io_enq_0_bits_payload_psrc_3 = '0;
    io_enq_0_bits_payload_psrc_4 = '0;
    io_enq_0_bits_payload_pdest = '0;
    io_enq_0_bits_payload_useRegCache_0 = '0;
    io_enq_0_bits_payload_useRegCache_1 = '0;
    io_enq_0_bits_payload_regCacheIdx_0 = '0;
    io_enq_0_bits_payload_regCacheIdx_1 = '0;
    io_enq_0_bits_payload_robIdx_flag = '0;
    io_enq_0_bits_payload_robIdx_value = '0;
    io_enq_0_bits_payload_instrSize = '0;
    io_enq_0_bits_payload_dirtyFs = '0;
    io_enq_0_bits_payload_dirtyVs = '0;
    io_enq_0_bits_payload_traceBlockInPipe_itype = '0;
    io_enq_0_bits_payload_traceBlockInPipe_iretire = '0;
    io_enq_0_bits_payload_traceBlockInPipe_ilastsize = '0;
    io_enq_0_bits_payload_eliminatedMove = '0;
    io_enq_0_bits_payload_snapshot = '0;
    io_enq_0_bits_payload_debugInfo_eliminatedMove = '0;
    io_enq_0_bits_payload_debugInfo_renameTime = '0;
    io_enq_0_bits_payload_debugInfo_dispatchTime = '0;
    io_enq_0_bits_payload_debugInfo_enqRsTime = '0;
    io_enq_0_bits_payload_debugInfo_selectTime = '0;
    io_enq_0_bits_payload_debugInfo_issueTime = '0;
    io_enq_0_bits_payload_debugInfo_writebackTime = '0;
    io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id = '0;
    io_enq_0_bits_payload_debugInfo_tlbFirstReqTime = '0;
    io_enq_0_bits_payload_debugInfo_tlbRespTime = '0;
    io_enq_0_bits_payload_debug_seqNum_seqNum = '0;
    io_enq_0_bits_payload_debug_seqNum_uopIdx = '0;
    io_enq_0_bits_payload_storeSetHit = '0;
    io_enq_0_bits_payload_waitForRobIdx_flag = '0;
    io_enq_0_bits_payload_waitForRobIdx_value = '0;
    io_enq_0_bits_payload_loadWaitBit = '0;
    io_enq_0_bits_payload_loadWaitStrict = '0;
    io_enq_0_bits_payload_ssid = '0;
    io_enq_0_bits_payload_lqIdx_flag = '0;
    io_enq_0_bits_payload_lqIdx_value = '0;
    io_enq_0_bits_payload_sqIdx_flag = '0;
    io_enq_0_bits_payload_sqIdx_value = '0;
    io_enq_0_bits_payload_singleStep = '0;
    io_enq_0_bits_payload_replayInst = '0;
    io_enq_0_bits_payload_debug_fuType = '0;
    io_enq_0_bits_payload_debug_sim_trig = '0;
    io_enq_0_bits_payload_numLsElem = '0;
    io_enq_1_valid = '0;
    io_enq_1_bits_status_robIdx_flag = '0;
    io_enq_1_bits_status_robIdx_value = '0;
    io_enq_1_bits_status_fuType_22 = '0;
    io_enq_1_bits_status_fuType_26 = '0;
    io_enq_1_bits_status_srcStatus_0_psrc = '0;
    io_enq_1_bits_status_srcStatus_0_srcType = '0;
    io_enq_1_bits_status_srcStatus_0_srcState = '0;
    io_enq_1_bits_status_srcStatus_0_dataSources_value = '0;
    io_enq_1_bits_status_srcStatus_1_psrc = '0;
    io_enq_1_bits_status_srcStatus_1_srcType = '0;
    io_enq_1_bits_status_srcStatus_1_srcState = '0;
    io_enq_1_bits_status_srcStatus_1_dataSources_value = '0;
    io_enq_1_bits_status_srcStatus_2_psrc = '0;
    io_enq_1_bits_status_srcStatus_2_srcType = '0;
    io_enq_1_bits_status_srcStatus_2_srcState = '0;
    io_enq_1_bits_status_srcStatus_2_dataSources_value = '0;
    io_enq_1_bits_status_srcStatus_3_psrc = '0;
    io_enq_1_bits_status_srcStatus_3_srcType = '0;
    io_enq_1_bits_status_srcStatus_3_srcState = '0;
    io_enq_1_bits_status_srcStatus_3_dataSources_value = '0;
    io_enq_1_bits_status_srcStatus_4_psrc = '0;
    io_enq_1_bits_status_srcStatus_4_srcType = '0;
    io_enq_1_bits_status_srcStatus_4_srcState = '0;
    io_enq_1_bits_status_srcStatus_4_dataSources_value = '0;
    io_enq_1_bits_payload_instr = '0;
    io_enq_1_bits_payload_pc = '0;
    io_enq_1_bits_payload_foldpc = '0;
    io_enq_1_bits_payload_exceptionVec_0 = '0;
    io_enq_1_bits_payload_exceptionVec_1 = '0;
    io_enq_1_bits_payload_exceptionVec_2 = '0;
    io_enq_1_bits_payload_exceptionVec_3 = '0;
    io_enq_1_bits_payload_exceptionVec_4 = '0;
    io_enq_1_bits_payload_exceptionVec_5 = '0;
    io_enq_1_bits_payload_exceptionVec_6 = '0;
    io_enq_1_bits_payload_exceptionVec_7 = '0;
    io_enq_1_bits_payload_exceptionVec_8 = '0;
    io_enq_1_bits_payload_exceptionVec_9 = '0;
    io_enq_1_bits_payload_exceptionVec_10 = '0;
    io_enq_1_bits_payload_exceptionVec_11 = '0;
    io_enq_1_bits_payload_exceptionVec_12 = '0;
    io_enq_1_bits_payload_exceptionVec_13 = '0;
    io_enq_1_bits_payload_exceptionVec_14 = '0;
    io_enq_1_bits_payload_exceptionVec_15 = '0;
    io_enq_1_bits_payload_exceptionVec_16 = '0;
    io_enq_1_bits_payload_exceptionVec_17 = '0;
    io_enq_1_bits_payload_exceptionVec_18 = '0;
    io_enq_1_bits_payload_exceptionVec_19 = '0;
    io_enq_1_bits_payload_exceptionVec_20 = '0;
    io_enq_1_bits_payload_exceptionVec_21 = '0;
    io_enq_1_bits_payload_exceptionVec_22 = '0;
    io_enq_1_bits_payload_exceptionVec_23 = '0;
    io_enq_1_bits_payload_isFetchMalAddr = '0;
    io_enq_1_bits_payload_hasException = '0;
    io_enq_1_bits_payload_trigger = '0;
    io_enq_1_bits_payload_preDecodeInfo_valid = '0;
    io_enq_1_bits_payload_preDecodeInfo_isRVC = '0;
    io_enq_1_bits_payload_preDecodeInfo_brType = '0;
    io_enq_1_bits_payload_preDecodeInfo_isCall = '0;
    io_enq_1_bits_payload_preDecodeInfo_isRet = '0;
    io_enq_1_bits_payload_pred_taken = '0;
    io_enq_1_bits_payload_crossPageIPFFix = '0;
    io_enq_1_bits_payload_ftqPtr_flag = '0;
    io_enq_1_bits_payload_ftqPtr_value = '0;
    io_enq_1_bits_payload_ftqOffset = '0;
    io_enq_1_bits_payload_satpFlushFirstFetchFault = '0;
    io_enq_1_bits_payload_srcType_0 = '0;
    io_enq_1_bits_payload_srcType_1 = '0;
    io_enq_1_bits_payload_srcType_2 = '0;
    io_enq_1_bits_payload_srcType_3 = '0;
    io_enq_1_bits_payload_srcType_4 = '0;
    io_enq_1_bits_payload_ldest = '0;
    io_enq_1_bits_payload_fuType = '0;
    io_enq_1_bits_payload_fuOpType = '0;
    io_enq_1_bits_payload_rfWen = '0;
    io_enq_1_bits_payload_fpWen = '0;
    io_enq_1_bits_payload_vecWen = '0;
    io_enq_1_bits_payload_v0Wen = '0;
    io_enq_1_bits_payload_vlWen = '0;
    io_enq_1_bits_payload_isXSTrap = '0;
    io_enq_1_bits_payload_waitForward = '0;
    io_enq_1_bits_payload_blockBackward = '0;
    io_enq_1_bits_payload_flushPipe = '0;
    io_enq_1_bits_payload_canRobCompress = '0;
    io_enq_1_bits_payload_selImm = '0;
    io_enq_1_bits_payload_imm = '0;
    io_enq_1_bits_payload_fpu_typeTagOut = '0;
    io_enq_1_bits_payload_fpu_wflags = '0;
    io_enq_1_bits_payload_fpu_typ = '0;
    io_enq_1_bits_payload_fpu_fmt = '0;
    io_enq_1_bits_payload_fpu_rm = '0;
    io_enq_1_bits_payload_vpu_vill = '0;
    io_enq_1_bits_payload_vpu_vma = '0;
    io_enq_1_bits_payload_vpu_vta = '0;
    io_enq_1_bits_payload_vpu_vsew = '0;
    io_enq_1_bits_payload_vpu_vlmul = '0;
    io_enq_1_bits_payload_vpu_specVill = '0;
    io_enq_1_bits_payload_vpu_specVma = '0;
    io_enq_1_bits_payload_vpu_specVta = '0;
    io_enq_1_bits_payload_vpu_specVsew = '0;
    io_enq_1_bits_payload_vpu_specVlmul = '0;
    io_enq_1_bits_payload_vpu_vm = '0;
    io_enq_1_bits_payload_vpu_vstart = '0;
    io_enq_1_bits_payload_vpu_frm = '0;
    io_enq_1_bits_payload_vpu_fpu_isFpToVecInst = '0;
    io_enq_1_bits_payload_vpu_fpu_isFP32Instr = '0;
    io_enq_1_bits_payload_vpu_fpu_isFP64Instr = '0;
    io_enq_1_bits_payload_vpu_fpu_isReduction = '0;
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2 = '0;
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4 = '0;
    io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8 = '0;
    io_enq_1_bits_payload_vpu_vxrm = '0;
    io_enq_1_bits_payload_vpu_vuopIdx = '0;
    io_enq_1_bits_payload_vpu_lastUop = '0;
    io_enq_1_bits_payload_vpu_vmask = '0;
    io_enq_1_bits_payload_vpu_vl = '0;
    io_enq_1_bits_payload_vpu_nf = '0;
    io_enq_1_bits_payload_vpu_veew = '0;
    io_enq_1_bits_payload_vpu_isReverse = '0;
    io_enq_1_bits_payload_vpu_isExt = '0;
    io_enq_1_bits_payload_vpu_isNarrow = '0;
    io_enq_1_bits_payload_vpu_isDstMask = '0;
    io_enq_1_bits_payload_vpu_isOpMask = '0;
    io_enq_1_bits_payload_vpu_isMove = '0;
    io_enq_1_bits_payload_vpu_isDependOldVd = '0;
    io_enq_1_bits_payload_vpu_isWritePartVd = '0;
    io_enq_1_bits_payload_vpu_isVleff = '0;
    io_enq_1_bits_payload_vlsInstr = '0;
    io_enq_1_bits_payload_wfflags = '0;
    io_enq_1_bits_payload_isMove = '0;
    io_enq_1_bits_payload_isDropAmocasSta = '0;
    io_enq_1_bits_payload_uopIdx = '0;
    io_enq_1_bits_payload_isVset = '0;
    io_enq_1_bits_payload_firstUop = '0;
    io_enq_1_bits_payload_lastUop = '0;
    io_enq_1_bits_payload_numUops = '0;
    io_enq_1_bits_payload_numWB = '0;
    io_enq_1_bits_payload_commitType = '0;
    io_enq_1_bits_payload_srcState_0 = '0;
    io_enq_1_bits_payload_srcState_1 = '0;
    io_enq_1_bits_payload_srcState_2 = '0;
    io_enq_1_bits_payload_srcState_3 = '0;
    io_enq_1_bits_payload_srcState_4 = '0;
    io_enq_1_bits_payload_psrc_0 = '0;
    io_enq_1_bits_payload_psrc_1 = '0;
    io_enq_1_bits_payload_psrc_2 = '0;
    io_enq_1_bits_payload_psrc_3 = '0;
    io_enq_1_bits_payload_psrc_4 = '0;
    io_enq_1_bits_payload_pdest = '0;
    io_enq_1_bits_payload_useRegCache_0 = '0;
    io_enq_1_bits_payload_useRegCache_1 = '0;
    io_enq_1_bits_payload_regCacheIdx_0 = '0;
    io_enq_1_bits_payload_regCacheIdx_1 = '0;
    io_enq_1_bits_payload_robIdx_flag = '0;
    io_enq_1_bits_payload_robIdx_value = '0;
    io_enq_1_bits_payload_instrSize = '0;
    io_enq_1_bits_payload_dirtyFs = '0;
    io_enq_1_bits_payload_dirtyVs = '0;
    io_enq_1_bits_payload_traceBlockInPipe_itype = '0;
    io_enq_1_bits_payload_traceBlockInPipe_iretire = '0;
    io_enq_1_bits_payload_traceBlockInPipe_ilastsize = '0;
    io_enq_1_bits_payload_eliminatedMove = '0;
    io_enq_1_bits_payload_snapshot = '0;
    io_enq_1_bits_payload_debugInfo_eliminatedMove = '0;
    io_enq_1_bits_payload_debugInfo_renameTime = '0;
    io_enq_1_bits_payload_debugInfo_dispatchTime = '0;
    io_enq_1_bits_payload_debugInfo_enqRsTime = '0;
    io_enq_1_bits_payload_debugInfo_selectTime = '0;
    io_enq_1_bits_payload_debugInfo_issueTime = '0;
    io_enq_1_bits_payload_debugInfo_writebackTime = '0;
    io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id = '0;
    io_enq_1_bits_payload_debugInfo_tlbFirstReqTime = '0;
    io_enq_1_bits_payload_debugInfo_tlbRespTime = '0;
    io_enq_1_bits_payload_debug_seqNum_seqNum = '0;
    io_enq_1_bits_payload_debug_seqNum_uopIdx = '0;
    io_enq_1_bits_payload_storeSetHit = '0;
    io_enq_1_bits_payload_waitForRobIdx_flag = '0;
    io_enq_1_bits_payload_waitForRobIdx_value = '0;
    io_enq_1_bits_payload_loadWaitBit = '0;
    io_enq_1_bits_payload_loadWaitStrict = '0;
    io_enq_1_bits_payload_ssid = '0;
    io_enq_1_bits_payload_lqIdx_flag = '0;
    io_enq_1_bits_payload_lqIdx_value = '0;
    io_enq_1_bits_payload_sqIdx_flag = '0;
    io_enq_1_bits_payload_sqIdx_value = '0;
    io_enq_1_bits_payload_singleStep = '0;
    io_enq_1_bits_payload_replayInst = '0;
    io_enq_1_bits_payload_debug_fuType = '0;
    io_enq_1_bits_payload_debug_sim_trig = '0;
    io_enq_1_bits_payload_numLsElem = '0;
    io_og0Resp_0_valid = '0;
    io_og1Resp_0_valid = '0;
    io_og2Resp_0_valid = '0;
    io_og2Resp_0_bits_resp = '0;
    io_deqReady_0 = '0;
    io_deqSelOH_0_valid = '0;
    io_deqSelOH_0_bits = '0;
    io_enqEntryOldestSel_0_bits = '0;
    io_simpEntryOldestSel_0_valid = '0;
    io_simpEntryOldestSel_0_bits = '0;
    io_compEntryOldestSel_0_valid = '0;
    io_compEntryOldestSel_0_bits = '0;
    io_wakeUpFromWB_15_valid = '0;
    io_wakeUpFromWB_15_bits_vlWen = '0;
    io_wakeUpFromWB_15_bits_pdest = '0;
    io_wakeUpFromWB_14_valid = '0;
    io_wakeUpFromWB_14_bits_vlWen = '0;
    io_wakeUpFromWB_14_bits_pdest = '0;
    io_wakeUpFromWB_13_valid = '0;
    io_wakeUpFromWB_13_bits_vlWen = '0;
    io_wakeUpFromWB_13_bits_pdest = '0;
    io_wakeUpFromWB_12_valid = '0;
    io_wakeUpFromWB_12_bits_vlWen = '0;
    io_wakeUpFromWB_12_bits_pdest = '0;
    io_wakeUpFromWB_11_valid = '0;
    io_wakeUpFromWB_11_bits_v0Wen = '0;
    io_wakeUpFromWB_11_bits_pdest = '0;
    io_wakeUpFromWB_10_valid = '0;
    io_wakeUpFromWB_10_bits_v0Wen = '0;
    io_wakeUpFromWB_10_bits_pdest = '0;
    io_wakeUpFromWB_9_valid = '0;
    io_wakeUpFromWB_9_bits_v0Wen = '0;
    io_wakeUpFromWB_9_bits_pdest = '0;
    io_wakeUpFromWB_8_valid = '0;
    io_wakeUpFromWB_8_bits_v0Wen = '0;
    io_wakeUpFromWB_8_bits_pdest = '0;
    io_wakeUpFromWB_7_valid = '0;
    io_wakeUpFromWB_7_bits_v0Wen = '0;
    io_wakeUpFromWB_7_bits_pdest = '0;
    io_wakeUpFromWB_6_valid = '0;
    io_wakeUpFromWB_6_bits_v0Wen = '0;
    io_wakeUpFromWB_6_bits_pdest = '0;
    io_wakeUpFromWB_5_valid = '0;
    io_wakeUpFromWB_5_bits_vecWen = '0;
    io_wakeUpFromWB_5_bits_pdest = '0;
    io_wakeUpFromWB_4_valid = '0;
    io_wakeUpFromWB_4_bits_vecWen = '0;
    io_wakeUpFromWB_4_bits_pdest = '0;
    io_wakeUpFromWB_3_valid = '0;
    io_wakeUpFromWB_3_bits_vecWen = '0;
    io_wakeUpFromWB_3_bits_pdest = '0;
    io_wakeUpFromWB_2_valid = '0;
    io_wakeUpFromWB_2_bits_vecWen = '0;
    io_wakeUpFromWB_2_bits_pdest = '0;
    io_wakeUpFromWB_1_valid = '0;
    io_wakeUpFromWB_1_bits_vecWen = '0;
    io_wakeUpFromWB_1_bits_pdest = '0;
    io_wakeUpFromWB_0_valid = '0;
    io_wakeUpFromWB_0_bits_vecWen = '0;
    io_wakeUpFromWB_0_bits_pdest = '0;
    io_wakeUpFromWBDelayed_15_valid = '0;
    io_wakeUpFromWBDelayed_15_bits_vlWen = '0;
    io_wakeUpFromWBDelayed_15_bits_pdest = '0;
    io_wakeUpFromWBDelayed_14_valid = '0;
    io_wakeUpFromWBDelayed_14_bits_vlWen = '0;
    io_wakeUpFromWBDelayed_14_bits_pdest = '0;
    io_wakeUpFromWBDelayed_13_valid = '0;
    io_wakeUpFromWBDelayed_13_bits_vlWen = '0;
    io_wakeUpFromWBDelayed_13_bits_pdest = '0;
    io_wakeUpFromWBDelayed_12_valid = '0;
    io_wakeUpFromWBDelayed_12_bits_vlWen = '0;
    io_wakeUpFromWBDelayed_12_bits_pdest = '0;
    io_wakeUpFromWBDelayed_11_valid = '0;
    io_wakeUpFromWBDelayed_11_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_11_bits_pdest = '0;
    io_wakeUpFromWBDelayed_10_valid = '0;
    io_wakeUpFromWBDelayed_10_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_10_bits_pdest = '0;
    io_wakeUpFromWBDelayed_9_valid = '0;
    io_wakeUpFromWBDelayed_9_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_9_bits_pdest = '0;
    io_wakeUpFromWBDelayed_8_valid = '0;
    io_wakeUpFromWBDelayed_8_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_8_bits_pdest = '0;
    io_wakeUpFromWBDelayed_7_valid = '0;
    io_wakeUpFromWBDelayed_7_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_7_bits_pdest = '0;
    io_wakeUpFromWBDelayed_6_valid = '0;
    io_wakeUpFromWBDelayed_6_bits_v0Wen = '0;
    io_wakeUpFromWBDelayed_6_bits_pdest = '0;
    io_wakeUpFromWBDelayed_5_valid = '0;
    io_wakeUpFromWBDelayed_5_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_5_bits_pdest = '0;
    io_wakeUpFromWBDelayed_4_valid = '0;
    io_wakeUpFromWBDelayed_4_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_4_bits_pdest = '0;
    io_wakeUpFromWBDelayed_3_valid = '0;
    io_wakeUpFromWBDelayed_3_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_3_bits_pdest = '0;
    io_wakeUpFromWBDelayed_2_valid = '0;
    io_wakeUpFromWBDelayed_2_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_2_bits_pdest = '0;
    io_wakeUpFromWBDelayed_1_valid = '0;
    io_wakeUpFromWBDelayed_1_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_1_bits_pdest = '0;
    io_wakeUpFromWBDelayed_0_valid = '0;
    io_wakeUpFromWBDelayed_0_bits_vecWen = '0;
    io_wakeUpFromWBDelayed_0_bits_pdest = '0;
    io_vlFromIntIsZero = '0;
    io_vlFromIntIsVlmax = '0;
    io_vlFromVfIsZero = '0;
    io_vlFromVfIsVlmax = '0;
    io_simpEntryDeqSelVec_0 = '0;
    io_simpEntryDeqSelVec_1 = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive();        // 非阻塞：本拍激励
      #1;             // 输入落定
      drive_deq();    // 阻塞：读已落定的 canIssue 再挑发射目标
      #1;             // 组合输出稳定
      sample_cov();   // 时钟沿之前采样
      @(posedge clock);
      #1;
      check_outputs();
    end

    $display("EntriesVfdivVidiv checks=%0d errors=%0d", checks, errors);
    $display("---- 功能覆盖 ----");
    covchk("enq_fire", cov_enq_fire);
    covchk("wb_wake", cov_wb_wake);
    covchk("can_issue", cov_can_issue);
    covchk("deq_fire", cov_deq_fire);
    covchk("deq_clear", cov_deq_clear);
    covchk("first_issue", cov_first_issue);
    covchk("resp_succ", cov_resp_succ);
    covchk("resp_block", cov_resp_block);
    covchk("resp_uncertain", cov_resp_uncertain);
    covchk("trans2simp", cov_trans2simp);
    covchk("trans2comp", cov_trans2comp);
    covchk("simp2comp", cov_simp2comp);
    covchk("ignore_old_vd", cov_ignore_old_vd);
    covchk("full", cov_full);
    covchk("flush", cov_flush);
    if (errors != 0) begin $display("TEST FAILED"); $fatal(1); end
    if (cov_fail != 0) begin $display("TEST FAILED (覆盖不足)"); $fatal(1); end
    if (checks < 1000) begin $display("TEST FAILED (比对次数过少)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
`undef CHK
