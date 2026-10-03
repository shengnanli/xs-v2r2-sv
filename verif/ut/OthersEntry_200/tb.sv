// OthersEntry_200 UT —— golden OthersEntry_200 与重写 OthersEntry_200_xs 双例化，逐拍比对全部 266 个输出。
// 端口表从 G1 golden 机械提取，比对用 `CHK 宏逐端口展开，杜绝手抄漏项。
//
// ★ 单条目最容易出的假绿：激励根本没让它动 ★
//   条目不入队 / 不被唤醒 / 不发射时，两边输出都是「空条目」的平凡相等，
//   200k 拍 errors=0 什么也证明不了。所以除逐拍比对外还守一组覆盖闸
//   （见文件末 finish 里的 covchk），任一为 0 判 FAIL：
//     enq_fire
//     wb_wake
//     can_issue
//     deq_fire
//     resp_succ
//     resp_block
//     resp_uncertain
//     deq_clear
//     flush_hit
//     trans_fire
//     enq_while_valid
//     iq_wake
//     og0_cancel_hit
//     ld_cancel_hit
//     rc_hit
//
// ★ 第二个坑（+vcs+initreg+random 才暴露）★
//   io_commonOut_issued / fuType / dataSources 是条目寄存器的**裸读**，
//   没有被 valid 门控。条目被写过之前，golden 的 entryReg_* 与重写核的 r_*
//   是两组不同的寄存器，随机初值下必然不同 —— 不开 initreg 时 golden 是 X、
//   被 $isunknown 跳过，看不出来；一开 initreg+random 就是一片错。
//   所以本 tb 等条目**被写过至少一次**（warm）才开始比对，
//   并且若整轮都没等到就判 FAIL（等不到 = 这一轮什么也没测）。
//
// 激励要点：
//   1) pdest/psrc 共用 8 值小池，否则唤醒永远打不中在队 uop 的源；
//   2) srcType 按各源真实的门控位给，给错了那一路唤醒整条哑掉；
//   3) deqSel / transSel 在时钟沿**之前**用阻塞赋值从 golden 当拍已落定的
//      canIssue 算出来，否则慢一拍全打空（纯随机命中概率极低）。
//
// 自动生成：verif/ut/OthersEntry_200/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
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

  int cov_enq_fire = 0;
  int cov_wb_wake = 0;
  int cov_can_issue = 0;
  int cov_deq_fire = 0;
  int cov_resp_succ = 0;
  int cov_resp_block = 0;
  int cov_resp_uncertain = 0;
  int cov_deq_clear = 0;
  int cov_flush_hit = 0;
  int cov_trans_fire = 0;
  int cov_enq_while_valid = 0;
  int cov_iq_wake = 0;
  int cov_og0_cancel_hit = 0;
  int cov_ld_cancel_hit = 0;
  int cov_rc_hit = 0;
  int cov_fail = 0;
  // *** 覆盖桶的下限断言 ***（CONVENTIONS「判据也必须先自证看得见改变」）：
  //   只判「!= 0」不够 —— 激励退化成「几乎打不到」时计数会掉到个位数，
  //   而那仍然是非零，闸照样绿。所以按 NCYCLES/1000 设下限。
  //   量级依据：闸要抓的是「激励整条打不到了」这种数量级的塌陷，不是
  //   2 倍以内的抖动。本族 72 次实跑里最紧的桶是 flush_hit=456（200k 拍），
  //   下限 200 留了一倍余量；它真的会红由 +nopool 负测证明（见下）。
  int MINCOV[string];   // 逐桶下限（见 othersentry_gen.py 的 COV_MIN_200K）
  bit warm = 0;              // 条目被写过 -> 进入比对
  longint warm_cycle = -1;
  task automatic covchk(string nm, int c);
    int lo = MINCOV[nm];
    $display("  cov %-20s = %0d  (min %0d)", nm, c, lo);
    if (c < lo) begin
      cov_fail++;
      $display("  *** COVERAGE HOLE: %s = %0d < %0d", nm, c, lo);
    end
  endtask

  logic io_commonIn_flush_valid;
  logic io_commonIn_flush_bits_robIdx_flag;
  logic [7:0] io_commonIn_flush_bits_robIdx_value;
  logic io_commonIn_flush_bits_level;
  logic io_commonIn_enq_valid;
  logic io_commonIn_enq_bits_status_robIdx_flag;
  logic [7:0] io_commonIn_enq_bits_status_robIdx_value;
  logic io_commonIn_enq_bits_status_fuType_15;
  logic [7:0] io_commonIn_enq_bits_status_srcStatus_0_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_0_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_dataSources_value;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2;
  logic [2:0] io_commonIn_enq_bits_status_srcStatus_0_exuSources_value;
  logic io_commonIn_enq_bits_status_srcStatus_0_useRegCache;
  logic [4:0] io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx;
  logic io_commonIn_enq_bits_status_blocked;
  logic io_commonIn_enq_bits_status_issued;
  logic io_commonIn_enq_bits_status_firstIssue;
  logic [1:0] io_commonIn_enq_bits_status_issueTimer;
  logic io_commonIn_enq_bits_status_deqPortIdx;
  logic [31:0] io_commonIn_enq_bits_imm;
  logic [31:0] io_commonIn_enq_bits_payload_instr;
  logic [49:0] io_commonIn_enq_bits_payload_pc;
  logic [9:0] io_commonIn_enq_bits_payload_foldpc;
  logic io_commonIn_enq_bits_payload_exceptionVec_0;
  logic io_commonIn_enq_bits_payload_exceptionVec_1;
  logic io_commonIn_enq_bits_payload_exceptionVec_2;
  logic io_commonIn_enq_bits_payload_exceptionVec_3;
  logic io_commonIn_enq_bits_payload_exceptionVec_4;
  logic io_commonIn_enq_bits_payload_exceptionVec_5;
  logic io_commonIn_enq_bits_payload_exceptionVec_6;
  logic io_commonIn_enq_bits_payload_exceptionVec_7;
  logic io_commonIn_enq_bits_payload_exceptionVec_8;
  logic io_commonIn_enq_bits_payload_exceptionVec_9;
  logic io_commonIn_enq_bits_payload_exceptionVec_10;
  logic io_commonIn_enq_bits_payload_exceptionVec_11;
  logic io_commonIn_enq_bits_payload_exceptionVec_12;
  logic io_commonIn_enq_bits_payload_exceptionVec_13;
  logic io_commonIn_enq_bits_payload_exceptionVec_14;
  logic io_commonIn_enq_bits_payload_exceptionVec_15;
  logic io_commonIn_enq_bits_payload_exceptionVec_16;
  logic io_commonIn_enq_bits_payload_exceptionVec_17;
  logic io_commonIn_enq_bits_payload_exceptionVec_18;
  logic io_commonIn_enq_bits_payload_exceptionVec_19;
  logic io_commonIn_enq_bits_payload_exceptionVec_20;
  logic io_commonIn_enq_bits_payload_exceptionVec_21;
  logic io_commonIn_enq_bits_payload_exceptionVec_22;
  logic io_commonIn_enq_bits_payload_exceptionVec_23;
  logic io_commonIn_enq_bits_payload_isFetchMalAddr;
  logic io_commonIn_enq_bits_payload_hasException;
  logic [3:0] io_commonIn_enq_bits_payload_trigger;
  logic io_commonIn_enq_bits_payload_preDecodeInfo_valid;
  logic io_commonIn_enq_bits_payload_preDecodeInfo_isRVC;
  logic [1:0] io_commonIn_enq_bits_payload_preDecodeInfo_brType;
  logic io_commonIn_enq_bits_payload_preDecodeInfo_isCall;
  logic io_commonIn_enq_bits_payload_preDecodeInfo_isRet;
  logic io_commonIn_enq_bits_payload_pred_taken;
  logic io_commonIn_enq_bits_payload_crossPageIPFFix;
  logic io_commonIn_enq_bits_payload_ftqPtr_flag;
  logic [5:0] io_commonIn_enq_bits_payload_ftqPtr_value;
  logic [3:0] io_commonIn_enq_bits_payload_ftqOffset;
  logic io_commonIn_enq_bits_payload_satpFlushFirstFetchFault;
  logic [3:0] io_commonIn_enq_bits_payload_srcType_0;
  logic [3:0] io_commonIn_enq_bits_payload_srcType_1;
  logic [3:0] io_commonIn_enq_bits_payload_srcType_2;
  logic [3:0] io_commonIn_enq_bits_payload_srcType_3;
  logic [3:0] io_commonIn_enq_bits_payload_srcType_4;
  logic [5:0] io_commonIn_enq_bits_payload_ldest;
  logic [34:0] io_commonIn_enq_bits_payload_fuType;
  logic [8:0] io_commonIn_enq_bits_payload_fuOpType;
  logic io_commonIn_enq_bits_payload_rfWen;
  logic io_commonIn_enq_bits_payload_fpWen;
  logic io_commonIn_enq_bits_payload_vecWen;
  logic io_commonIn_enq_bits_payload_v0Wen;
  logic io_commonIn_enq_bits_payload_vlWen;
  logic io_commonIn_enq_bits_payload_isXSTrap;
  logic io_commonIn_enq_bits_payload_waitForward;
  logic io_commonIn_enq_bits_payload_blockBackward;
  logic io_commonIn_enq_bits_payload_flushPipe;
  logic io_commonIn_enq_bits_payload_canRobCompress;
  logic [3:0] io_commonIn_enq_bits_payload_selImm;
  logic [31:0] io_commonIn_enq_bits_payload_imm;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_typeTagOut;
  logic io_commonIn_enq_bits_payload_fpu_wflags;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_typ;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_fmt;
  logic [2:0] io_commonIn_enq_bits_payload_fpu_rm;
  logic io_commonIn_enq_bits_payload_vpu_vill;
  logic io_commonIn_enq_bits_payload_vpu_vma;
  logic io_commonIn_enq_bits_payload_vpu_vta;
  logic [1:0] io_commonIn_enq_bits_payload_vpu_vsew;
  logic [2:0] io_commonIn_enq_bits_payload_vpu_vlmul;
  logic io_commonIn_enq_bits_payload_vpu_specVill;
  logic io_commonIn_enq_bits_payload_vpu_specVma;
  logic io_commonIn_enq_bits_payload_vpu_specVta;
  logic [1:0] io_commonIn_enq_bits_payload_vpu_specVsew;
  logic [2:0] io_commonIn_enq_bits_payload_vpu_specVlmul;
  logic io_commonIn_enq_bits_payload_vpu_vm;
  logic [7:0] io_commonIn_enq_bits_payload_vpu_vstart;
  logic [2:0] io_commonIn_enq_bits_payload_vpu_frm;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isReduction;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4;
  logic io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_commonIn_enq_bits_payload_vpu_vxrm;
  logic [6:0] io_commonIn_enq_bits_payload_vpu_vuopIdx;
  logic io_commonIn_enq_bits_payload_vpu_lastUop;
  logic [127:0] io_commonIn_enq_bits_payload_vpu_vmask;
  logic [7:0] io_commonIn_enq_bits_payload_vpu_vl;
  logic [2:0] io_commonIn_enq_bits_payload_vpu_nf;
  logic [1:0] io_commonIn_enq_bits_payload_vpu_veew;
  logic io_commonIn_enq_bits_payload_vpu_isReverse;
  logic io_commonIn_enq_bits_payload_vpu_isExt;
  logic io_commonIn_enq_bits_payload_vpu_isNarrow;
  logic io_commonIn_enq_bits_payload_vpu_isDstMask;
  logic io_commonIn_enq_bits_payload_vpu_isOpMask;
  logic io_commonIn_enq_bits_payload_vpu_isMove;
  logic io_commonIn_enq_bits_payload_vpu_isDependOldVd;
  logic io_commonIn_enq_bits_payload_vpu_isWritePartVd;
  logic io_commonIn_enq_bits_payload_vpu_isVleff;
  logic io_commonIn_enq_bits_payload_vlsInstr;
  logic io_commonIn_enq_bits_payload_wfflags;
  logic io_commonIn_enq_bits_payload_isMove;
  logic io_commonIn_enq_bits_payload_isDropAmocasSta;
  logic [6:0] io_commonIn_enq_bits_payload_uopIdx;
  logic io_commonIn_enq_bits_payload_isVset;
  logic io_commonIn_enq_bits_payload_firstUop;
  logic io_commonIn_enq_bits_payload_lastUop;
  logic [6:0] io_commonIn_enq_bits_payload_numUops;
  logic [6:0] io_commonIn_enq_bits_payload_numWB;
  logic [2:0] io_commonIn_enq_bits_payload_commitType;
  logic io_commonIn_enq_bits_payload_srcState_0;
  logic io_commonIn_enq_bits_payload_srcState_1;
  logic io_commonIn_enq_bits_payload_srcState_2;
  logic io_commonIn_enq_bits_payload_srcState_3;
  logic io_commonIn_enq_bits_payload_srcState_4;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_0_0;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_0_1;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_0_2;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_1_0;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_1_1;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_1_2;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_2_0;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_2_1;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_2_2;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_3_0;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_3_1;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_3_2;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_4_0;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_4_1;
  logic [1:0] io_commonIn_enq_bits_payload_srcLoadDependency_4_2;
  logic [7:0] io_commonIn_enq_bits_payload_psrc_0;
  logic [7:0] io_commonIn_enq_bits_payload_psrc_1;
  logic [7:0] io_commonIn_enq_bits_payload_psrc_2;
  logic [7:0] io_commonIn_enq_bits_payload_psrc_3;
  logic [7:0] io_commonIn_enq_bits_payload_psrc_4;
  logic [7:0] io_commonIn_enq_bits_payload_pdest;
  logic io_commonIn_enq_bits_payload_useRegCache_0;
  logic io_commonIn_enq_bits_payload_useRegCache_1;
  logic [4:0] io_commonIn_enq_bits_payload_regCacheIdx_0;
  logic [4:0] io_commonIn_enq_bits_payload_regCacheIdx_1;
  logic io_commonIn_enq_bits_payload_robIdx_flag;
  logic [7:0] io_commonIn_enq_bits_payload_robIdx_value;
  logic [2:0] io_commonIn_enq_bits_payload_instrSize;
  logic io_commonIn_enq_bits_payload_dirtyFs;
  logic io_commonIn_enq_bits_payload_dirtyVs;
  logic [3:0] io_commonIn_enq_bits_payload_traceBlockInPipe_itype;
  logic [3:0] io_commonIn_enq_bits_payload_traceBlockInPipe_iretire;
  logic io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize;
  logic io_commonIn_enq_bits_payload_eliminatedMove;
  logic io_commonIn_enq_bits_payload_snapshot;
  logic io_commonIn_enq_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_renameTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_dispatchTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_enqRsTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_selectTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_issueTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_writebackTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] io_commonIn_enq_bits_payload_debug_seqNum_seqNum;
  logic [7:0] io_commonIn_enq_bits_payload_debug_seqNum_uopIdx;
  logic io_commonIn_enq_bits_payload_storeSetHit;
  logic io_commonIn_enq_bits_payload_waitForRobIdx_flag;
  logic [7:0] io_commonIn_enq_bits_payload_waitForRobIdx_value;
  logic io_commonIn_enq_bits_payload_loadWaitBit;
  logic io_commonIn_enq_bits_payload_loadWaitStrict;
  logic [4:0] io_commonIn_enq_bits_payload_ssid;
  logic io_commonIn_enq_bits_payload_lqIdx_flag;
  logic [6:0] io_commonIn_enq_bits_payload_lqIdx_value;
  logic io_commonIn_enq_bits_payload_sqIdx_flag;
  logic [5:0] io_commonIn_enq_bits_payload_sqIdx_value;
  logic io_commonIn_enq_bits_payload_singleStep;
  logic io_commonIn_enq_bits_payload_replayInst;
  logic [34:0] io_commonIn_enq_bits_payload_debug_fuType;
  logic io_commonIn_enq_bits_payload_debug_sim_trig;
  logic [4:0] io_commonIn_enq_bits_payload_numLsElem;
  logic io_commonIn_wakeUpFromWB_3_valid;
  logic io_commonIn_wakeUpFromWB_3_bits_rfWen;
  logic io_commonIn_wakeUpFromWB_3_bits_fpWen;
  logic io_commonIn_wakeUpFromWB_3_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_3_bits_pdest;
  logic io_commonIn_wakeUpFromWB_2_valid;
  logic io_commonIn_wakeUpFromWB_2_bits_rfWen;
  logic io_commonIn_wakeUpFromWB_2_bits_fpWen;
  logic io_commonIn_wakeUpFromWB_2_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_2_bits_pdest;
  logic io_commonIn_wakeUpFromWB_1_valid;
  logic io_commonIn_wakeUpFromWB_1_bits_rfWen;
  logic io_commonIn_wakeUpFromWB_1_bits_fpWen;
  logic io_commonIn_wakeUpFromWB_1_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_1_bits_pdest;
  logic io_commonIn_wakeUpFromWB_0_valid;
  logic io_commonIn_wakeUpFromWB_0_bits_rfWen;
  logic io_commonIn_wakeUpFromWB_0_bits_fpWen;
  logic io_commonIn_wakeUpFromWB_0_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_0_bits_pdest;
  logic io_commonIn_wakeUpFromIQ_6_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_6_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_6_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_6_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_5_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_5_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_5_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_5_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_4_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_4_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_4_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_4_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_3_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_3_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_3_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_3_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_2_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_2_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_2_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_2_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_1_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_1_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_1_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_1_bits_rcDest;
  logic io_commonIn_wakeUpFromIQ_0_bits_rfWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_0_bits_pdest;
  logic [1:0] io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0;
  logic [1:0] io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1;
  logic [1:0] io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2;
  logic io_commonIn_wakeUpFromIQ_0_bits_is0Lat;
  logic [4:0] io_commonIn_wakeUpFromIQ_0_bits_rcDest;
  logic io_commonIn_og0Cancel_0;
  logic io_commonIn_og0Cancel_2;
  logic io_commonIn_og0Cancel_4;
  logic io_commonIn_og0Cancel_6;
  logic io_commonIn_og0Cancel_20;
  logic io_commonIn_og0Cancel_21;
  logic io_commonIn_og0Cancel_22;
  logic io_commonIn_ldCancel_0_ld1Cancel;
  logic io_commonIn_ldCancel_0_ld2Cancel;
  logic io_commonIn_ldCancel_1_ld1Cancel;
  logic io_commonIn_ldCancel_1_ld2Cancel;
  logic io_commonIn_ldCancel_2_ld1Cancel;
  logic io_commonIn_ldCancel_2_ld2Cancel;
  logic io_commonIn_deqSel;
  logic io_commonIn_issueResp_valid;
  logic [1:0] io_commonIn_issueResp_bits_resp;
  logic io_commonIn_transSel;
  wire g_io_commonOut_valid;
  wire i_io_commonOut_valid;
  wire g_io_commonOut_issued;
  wire i_io_commonOut_issued;
  wire g_io_commonOut_canIssue;
  wire i_io_commonOut_canIssue;
  wire [34:0] g_io_commonOut_fuType;
  wire [34:0] i_io_commonOut_fuType;
  wire [3:0] g_io_commonOut_dataSources_0_value;
  wire [3:0] i_io_commonOut_dataSources_0_value;
  wire [2:0] g_io_commonOut_exuSources_0_value;
  wire [2:0] i_io_commonOut_exuSources_0_value;
  wire g_io_commonOut_isFirstIssue;
  wire i_io_commonOut_isFirstIssue;
  wire g_io_commonOut_entry_bits_status_robIdx_flag;
  wire i_io_commonOut_entry_bits_status_robIdx_flag;
  wire [7:0] g_io_commonOut_entry_bits_status_robIdx_value;
  wire [7:0] i_io_commonOut_entry_bits_status_robIdx_value;
  wire g_io_commonOut_entry_bits_status_fuType_15;
  wire i_io_commonOut_entry_bits_status_fuType_15;
  wire [7:0] g_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [7:0] i_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [1:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2;
  wire [4:0] g_io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx;
  wire [4:0] i_io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx;
  wire [31:0] g_io_commonOut_entry_bits_imm;
  wire [31:0] i_io_commonOut_entry_bits_imm;
  wire g_io_commonOut_entry_bits_payload_preDecodeInfo_valid;
  wire i_io_commonOut_entry_bits_payload_preDecodeInfo_valid;
  wire g_io_commonOut_entry_bits_payload_preDecodeInfo_isRVC;
  wire i_io_commonOut_entry_bits_payload_preDecodeInfo_isRVC;
  wire [1:0] g_io_commonOut_entry_bits_payload_preDecodeInfo_brType;
  wire [1:0] i_io_commonOut_entry_bits_payload_preDecodeInfo_brType;
  wire g_io_commonOut_entry_bits_payload_preDecodeInfo_isCall;
  wire i_io_commonOut_entry_bits_payload_preDecodeInfo_isCall;
  wire g_io_commonOut_entry_bits_payload_preDecodeInfo_isRet;
  wire i_io_commonOut_entry_bits_payload_preDecodeInfo_isRet;
  wire g_io_commonOut_entry_bits_payload_ftqPtr_flag;
  wire i_io_commonOut_entry_bits_payload_ftqPtr_flag;
  wire [5:0] g_io_commonOut_entry_bits_payload_ftqPtr_value;
  wire [5:0] i_io_commonOut_entry_bits_payload_ftqPtr_value;
  wire [3:0] g_io_commonOut_entry_bits_payload_ftqOffset;
  wire [3:0] i_io_commonOut_entry_bits_payload_ftqOffset;
  wire [8:0] g_io_commonOut_entry_bits_payload_fuOpType;
  wire [8:0] i_io_commonOut_entry_bits_payload_fuOpType;
  wire g_io_commonOut_entry_bits_payload_rfWen;
  wire i_io_commonOut_entry_bits_payload_rfWen;
  wire g_io_commonOut_entry_bits_payload_fpWen;
  wire i_io_commonOut_entry_bits_payload_fpWen;
  wire g_io_commonOut_entry_bits_payload_flushPipe;
  wire i_io_commonOut_entry_bits_payload_flushPipe;
  wire [3:0] g_io_commonOut_entry_bits_payload_selImm;
  wire [3:0] i_io_commonOut_entry_bits_payload_selImm;
  wire [7:0] g_io_commonOut_entry_bits_payload_pdest;
  wire [7:0] i_io_commonOut_entry_bits_payload_pdest;
  wire g_io_commonOut_entry_bits_payload_debugInfo_eliminatedMove;
  wire i_io_commonOut_entry_bits_payload_debugInfo_eliminatedMove;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_renameTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_renameTime;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_dispatchTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_dispatchTime;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_enqRsTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_enqRsTime;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_writebackTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_writebackTime;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] g_io_commonOut_entry_bits_payload_debugInfo_tlbRespTime;
  wire [63:0] i_io_commonOut_entry_bits_payload_debugInfo_tlbRespTime;
  wire [55:0] g_io_commonOut_entry_bits_payload_debug_seqNum_seqNum;
  wire [55:0] i_io_commonOut_entry_bits_payload_debug_seqNum_seqNum;
  wire [7:0] g_io_commonOut_entry_bits_payload_debug_seqNum_uopIdx;
  wire [7:0] i_io_commonOut_entry_bits_payload_debug_seqNum_uopIdx;
  wire g_io_commonOut_entry_bits_payload_storeSetHit;
  wire i_io_commonOut_entry_bits_payload_storeSetHit;
  wire g_io_commonOut_entry_bits_payload_waitForRobIdx_flag;
  wire i_io_commonOut_entry_bits_payload_waitForRobIdx_flag;
  wire [7:0] g_io_commonOut_entry_bits_payload_waitForRobIdx_value;
  wire [7:0] i_io_commonOut_entry_bits_payload_waitForRobIdx_value;
  wire g_io_commonOut_entry_bits_payload_loadWaitBit;
  wire i_io_commonOut_entry_bits_payload_loadWaitBit;
  wire g_io_commonOut_entry_bits_payload_loadWaitStrict;
  wire i_io_commonOut_entry_bits_payload_loadWaitStrict;
  wire [4:0] g_io_commonOut_entry_bits_payload_ssid;
  wire [4:0] i_io_commonOut_entry_bits_payload_ssid;
  wire g_io_commonOut_entry_bits_payload_lqIdx_flag;
  wire i_io_commonOut_entry_bits_payload_lqIdx_flag;
  wire [6:0] g_io_commonOut_entry_bits_payload_lqIdx_value;
  wire [6:0] i_io_commonOut_entry_bits_payload_lqIdx_value;
  wire g_io_commonOut_entry_bits_payload_sqIdx_flag;
  wire i_io_commonOut_entry_bits_payload_sqIdx_flag;
  wire [5:0] g_io_commonOut_entry_bits_payload_sqIdx_value;
  wire [5:0] i_io_commonOut_entry_bits_payload_sqIdx_value;
  wire g_io_commonOut_cancelBypass;
  wire i_io_commonOut_cancelBypass;
  wire [1:0] g_io_commonOut_issueTimerRead;
  wire [1:0] i_io_commonOut_issueTimerRead;
  wire g_io_commonOut_enqReady;
  wire i_io_commonOut_enqReady;
  wire g_io_commonOut_transEntry_valid;
  wire i_io_commonOut_transEntry_valid;
  wire g_io_commonOut_transEntry_bits_status_robIdx_flag;
  wire i_io_commonOut_transEntry_bits_status_robIdx_flag;
  wire [7:0] g_io_commonOut_transEntry_bits_status_robIdx_value;
  wire [7:0] i_io_commonOut_transEntry_bits_status_robIdx_value;
  wire g_io_commonOut_transEntry_bits_status_fuType_15;
  wire i_io_commonOut_transEntry_bits_status_fuType_15;
  wire [7:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_psrc;
  wire [7:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_psrc;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_srcType;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_srcType;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_0_srcState;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_0_srcState;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2;
  wire [2:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value;
  wire [2:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache;
  wire [4:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx;
  wire [4:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx;
  wire g_io_commonOut_transEntry_bits_status_issued;
  wire i_io_commonOut_transEntry_bits_status_issued;
  wire g_io_commonOut_transEntry_bits_status_firstIssue;
  wire i_io_commonOut_transEntry_bits_status_firstIssue;
  wire [1:0] g_io_commonOut_transEntry_bits_status_issueTimer;
  wire [1:0] i_io_commonOut_transEntry_bits_status_issueTimer;
  wire g_io_commonOut_transEntry_bits_status_deqPortIdx;
  wire i_io_commonOut_transEntry_bits_status_deqPortIdx;
  wire [31:0] g_io_commonOut_transEntry_bits_imm;
  wire [31:0] i_io_commonOut_transEntry_bits_imm;
  wire [31:0] g_io_commonOut_transEntry_bits_payload_instr;
  wire [31:0] i_io_commonOut_transEntry_bits_payload_instr;
  wire [49:0] g_io_commonOut_transEntry_bits_payload_pc;
  wire [49:0] i_io_commonOut_transEntry_bits_payload_pc;
  wire [9:0] g_io_commonOut_transEntry_bits_payload_foldpc;
  wire [9:0] i_io_commonOut_transEntry_bits_payload_foldpc;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_0;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_0;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_1;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_1;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_2;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_2;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_3;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_3;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_4;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_4;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_5;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_5;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_6;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_6;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_7;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_7;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_8;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_8;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_9;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_9;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_10;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_10;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_11;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_11;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_12;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_12;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_13;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_13;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_14;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_14;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_15;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_15;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_16;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_16;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_17;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_17;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_18;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_18;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_19;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_19;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_20;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_20;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_21;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_21;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_22;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_22;
  wire g_io_commonOut_transEntry_bits_payload_exceptionVec_23;
  wire i_io_commonOut_transEntry_bits_payload_exceptionVec_23;
  wire g_io_commonOut_transEntry_bits_payload_isFetchMalAddr;
  wire i_io_commonOut_transEntry_bits_payload_isFetchMalAddr;
  wire g_io_commonOut_transEntry_bits_payload_hasException;
  wire i_io_commonOut_transEntry_bits_payload_hasException;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_trigger;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_trigger;
  wire g_io_commonOut_transEntry_bits_payload_preDecodeInfo_valid;
  wire i_io_commonOut_transEntry_bits_payload_preDecodeInfo_valid;
  wire g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC;
  wire i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_preDecodeInfo_brType;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_preDecodeInfo_brType;
  wire g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall;
  wire i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall;
  wire g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet;
  wire i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet;
  wire g_io_commonOut_transEntry_bits_payload_pred_taken;
  wire i_io_commonOut_transEntry_bits_payload_pred_taken;
  wire g_io_commonOut_transEntry_bits_payload_crossPageIPFFix;
  wire i_io_commonOut_transEntry_bits_payload_crossPageIPFFix;
  wire g_io_commonOut_transEntry_bits_payload_ftqPtr_flag;
  wire i_io_commonOut_transEntry_bits_payload_ftqPtr_flag;
  wire [5:0] g_io_commonOut_transEntry_bits_payload_ftqPtr_value;
  wire [5:0] i_io_commonOut_transEntry_bits_payload_ftqPtr_value;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_ftqOffset;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_ftqOffset;
  wire g_io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault;
  wire i_io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_srcType_0;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_srcType_0;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_srcType_1;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_srcType_1;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_srcType_2;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_srcType_2;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_srcType_3;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_srcType_3;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_srcType_4;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_srcType_4;
  wire [5:0] g_io_commonOut_transEntry_bits_payload_ldest;
  wire [5:0] i_io_commonOut_transEntry_bits_payload_ldest;
  wire [34:0] g_io_commonOut_transEntry_bits_payload_fuType;
  wire [34:0] i_io_commonOut_transEntry_bits_payload_fuType;
  wire [8:0] g_io_commonOut_transEntry_bits_payload_fuOpType;
  wire [8:0] i_io_commonOut_transEntry_bits_payload_fuOpType;
  wire g_io_commonOut_transEntry_bits_payload_rfWen;
  wire i_io_commonOut_transEntry_bits_payload_rfWen;
  wire g_io_commonOut_transEntry_bits_payload_fpWen;
  wire i_io_commonOut_transEntry_bits_payload_fpWen;
  wire g_io_commonOut_transEntry_bits_payload_vecWen;
  wire i_io_commonOut_transEntry_bits_payload_vecWen;
  wire g_io_commonOut_transEntry_bits_payload_v0Wen;
  wire i_io_commonOut_transEntry_bits_payload_v0Wen;
  wire g_io_commonOut_transEntry_bits_payload_vlWen;
  wire i_io_commonOut_transEntry_bits_payload_vlWen;
  wire g_io_commonOut_transEntry_bits_payload_isXSTrap;
  wire i_io_commonOut_transEntry_bits_payload_isXSTrap;
  wire g_io_commonOut_transEntry_bits_payload_waitForward;
  wire i_io_commonOut_transEntry_bits_payload_waitForward;
  wire g_io_commonOut_transEntry_bits_payload_blockBackward;
  wire i_io_commonOut_transEntry_bits_payload_blockBackward;
  wire g_io_commonOut_transEntry_bits_payload_flushPipe;
  wire i_io_commonOut_transEntry_bits_payload_flushPipe;
  wire g_io_commonOut_transEntry_bits_payload_canRobCompress;
  wire i_io_commonOut_transEntry_bits_payload_canRobCompress;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_selImm;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_selImm;
  wire [31:0] g_io_commonOut_transEntry_bits_payload_imm;
  wire [31:0] i_io_commonOut_transEntry_bits_payload_imm;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_fpu_typeTagOut;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_fpu_typeTagOut;
  wire g_io_commonOut_transEntry_bits_payload_fpu_wflags;
  wire i_io_commonOut_transEntry_bits_payload_fpu_wflags;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_fpu_typ;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_fpu_typ;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_fpu_fmt;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_fpu_fmt;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_fpu_rm;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_fpu_rm;
  wire g_io_commonOut_transEntry_bits_payload_vpu_vill;
  wire i_io_commonOut_transEntry_bits_payload_vpu_vill;
  wire g_io_commonOut_transEntry_bits_payload_vpu_vma;
  wire i_io_commonOut_transEntry_bits_payload_vpu_vma;
  wire g_io_commonOut_transEntry_bits_payload_vpu_vta;
  wire i_io_commonOut_transEntry_bits_payload_vpu_vta;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_vpu_vsew;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_vpu_vsew;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_vpu_vlmul;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_vpu_vlmul;
  wire g_io_commonOut_transEntry_bits_payload_vpu_specVill;
  wire i_io_commonOut_transEntry_bits_payload_vpu_specVill;
  wire g_io_commonOut_transEntry_bits_payload_vpu_specVma;
  wire i_io_commonOut_transEntry_bits_payload_vpu_specVma;
  wire g_io_commonOut_transEntry_bits_payload_vpu_specVta;
  wire i_io_commonOut_transEntry_bits_payload_vpu_specVta;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_vpu_specVsew;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_vpu_specVsew;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_vpu_specVlmul;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_vpu_specVlmul;
  wire g_io_commonOut_transEntry_bits_payload_vpu_vm;
  wire i_io_commonOut_transEntry_bits_payload_vpu_vm;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_vpu_vstart;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_vpu_vstart;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_vpu_frm;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_vpu_frm;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4;
  wire g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8;
  wire i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_vpu_vxrm;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_vpu_vxrm;
  wire [6:0] g_io_commonOut_transEntry_bits_payload_vpu_vuopIdx;
  wire [6:0] i_io_commonOut_transEntry_bits_payload_vpu_vuopIdx;
  wire g_io_commonOut_transEntry_bits_payload_vpu_lastUop;
  wire i_io_commonOut_transEntry_bits_payload_vpu_lastUop;
  wire [127:0] g_io_commonOut_transEntry_bits_payload_vpu_vmask;
  wire [127:0] i_io_commonOut_transEntry_bits_payload_vpu_vmask;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_vpu_vl;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_vpu_vl;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_vpu_nf;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_vpu_nf;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_vpu_veew;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_vpu_veew;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isReverse;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isReverse;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isExt;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isExt;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isNarrow;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isNarrow;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isDstMask;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isDstMask;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isOpMask;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isOpMask;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isMove;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isMove;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isDependOldVd;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isDependOldVd;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isWritePartVd;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isWritePartVd;
  wire g_io_commonOut_transEntry_bits_payload_vpu_isVleff;
  wire i_io_commonOut_transEntry_bits_payload_vpu_isVleff;
  wire g_io_commonOut_transEntry_bits_payload_vlsInstr;
  wire i_io_commonOut_transEntry_bits_payload_vlsInstr;
  wire g_io_commonOut_transEntry_bits_payload_wfflags;
  wire i_io_commonOut_transEntry_bits_payload_wfflags;
  wire g_io_commonOut_transEntry_bits_payload_isMove;
  wire i_io_commonOut_transEntry_bits_payload_isMove;
  wire g_io_commonOut_transEntry_bits_payload_isDropAmocasSta;
  wire i_io_commonOut_transEntry_bits_payload_isDropAmocasSta;
  wire [6:0] g_io_commonOut_transEntry_bits_payload_uopIdx;
  wire [6:0] i_io_commonOut_transEntry_bits_payload_uopIdx;
  wire g_io_commonOut_transEntry_bits_payload_isVset;
  wire i_io_commonOut_transEntry_bits_payload_isVset;
  wire g_io_commonOut_transEntry_bits_payload_firstUop;
  wire i_io_commonOut_transEntry_bits_payload_firstUop;
  wire g_io_commonOut_transEntry_bits_payload_lastUop;
  wire i_io_commonOut_transEntry_bits_payload_lastUop;
  wire [6:0] g_io_commonOut_transEntry_bits_payload_numUops;
  wire [6:0] i_io_commonOut_transEntry_bits_payload_numUops;
  wire [6:0] g_io_commonOut_transEntry_bits_payload_numWB;
  wire [6:0] i_io_commonOut_transEntry_bits_payload_numWB;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_commitType;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_commitType;
  wire g_io_commonOut_transEntry_bits_payload_srcState_0;
  wire i_io_commonOut_transEntry_bits_payload_srcState_0;
  wire g_io_commonOut_transEntry_bits_payload_srcState_1;
  wire i_io_commonOut_transEntry_bits_payload_srcState_1;
  wire g_io_commonOut_transEntry_bits_payload_srcState_2;
  wire i_io_commonOut_transEntry_bits_payload_srcState_2;
  wire g_io_commonOut_transEntry_bits_payload_srcState_3;
  wire i_io_commonOut_transEntry_bits_payload_srcState_3;
  wire g_io_commonOut_transEntry_bits_payload_srcState_4;
  wire i_io_commonOut_transEntry_bits_payload_srcState_4;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1;
  wire [1:0] g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2;
  wire [1:0] i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_psrc_0;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_psrc_0;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_psrc_1;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_psrc_1;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_psrc_2;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_psrc_2;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_psrc_3;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_psrc_3;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_psrc_4;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_psrc_4;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_pdest;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_pdest;
  wire g_io_commonOut_transEntry_bits_payload_useRegCache_0;
  wire i_io_commonOut_transEntry_bits_payload_useRegCache_0;
  wire g_io_commonOut_transEntry_bits_payload_useRegCache_1;
  wire i_io_commonOut_transEntry_bits_payload_useRegCache_1;
  wire [4:0] g_io_commonOut_transEntry_bits_payload_regCacheIdx_0;
  wire [4:0] i_io_commonOut_transEntry_bits_payload_regCacheIdx_0;
  wire [4:0] g_io_commonOut_transEntry_bits_payload_regCacheIdx_1;
  wire [4:0] i_io_commonOut_transEntry_bits_payload_regCacheIdx_1;
  wire g_io_commonOut_transEntry_bits_payload_robIdx_flag;
  wire i_io_commonOut_transEntry_bits_payload_robIdx_flag;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_robIdx_value;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_robIdx_value;
  wire [2:0] g_io_commonOut_transEntry_bits_payload_instrSize;
  wire [2:0] i_io_commonOut_transEntry_bits_payload_instrSize;
  wire g_io_commonOut_transEntry_bits_payload_dirtyFs;
  wire i_io_commonOut_transEntry_bits_payload_dirtyFs;
  wire g_io_commonOut_transEntry_bits_payload_dirtyVs;
  wire i_io_commonOut_transEntry_bits_payload_dirtyVs;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype;
  wire [3:0] g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire;
  wire [3:0] i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire;
  wire g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize;
  wire i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize;
  wire g_io_commonOut_transEntry_bits_payload_eliminatedMove;
  wire i_io_commonOut_transEntry_bits_payload_eliminatedMove;
  wire g_io_commonOut_transEntry_bits_payload_snapshot;
  wire i_io_commonOut_transEntry_bits_payload_snapshot;
  wire g_io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove;
  wire i_io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_renameTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_renameTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_selectTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_selectTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_issueTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_issueTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_writebackTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_writebackTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime;
  wire [63:0] g_io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime;
  wire [63:0] i_io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime;
  wire [55:0] g_io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum;
  wire [55:0] i_io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx;
  wire g_io_commonOut_transEntry_bits_payload_storeSetHit;
  wire i_io_commonOut_transEntry_bits_payload_storeSetHit;
  wire g_io_commonOut_transEntry_bits_payload_waitForRobIdx_flag;
  wire i_io_commonOut_transEntry_bits_payload_waitForRobIdx_flag;
  wire [7:0] g_io_commonOut_transEntry_bits_payload_waitForRobIdx_value;
  wire [7:0] i_io_commonOut_transEntry_bits_payload_waitForRobIdx_value;
  wire g_io_commonOut_transEntry_bits_payload_loadWaitBit;
  wire i_io_commonOut_transEntry_bits_payload_loadWaitBit;
  wire g_io_commonOut_transEntry_bits_payload_loadWaitStrict;
  wire i_io_commonOut_transEntry_bits_payload_loadWaitStrict;
  wire [4:0] g_io_commonOut_transEntry_bits_payload_ssid;
  wire [4:0] i_io_commonOut_transEntry_bits_payload_ssid;
  wire g_io_commonOut_transEntry_bits_payload_lqIdx_flag;
  wire i_io_commonOut_transEntry_bits_payload_lqIdx_flag;
  wire [6:0] g_io_commonOut_transEntry_bits_payload_lqIdx_value;
  wire [6:0] i_io_commonOut_transEntry_bits_payload_lqIdx_value;
  wire g_io_commonOut_transEntry_bits_payload_sqIdx_flag;
  wire i_io_commonOut_transEntry_bits_payload_sqIdx_flag;
  wire [5:0] g_io_commonOut_transEntry_bits_payload_sqIdx_value;
  wire [5:0] i_io_commonOut_transEntry_bits_payload_sqIdx_value;
  wire g_io_commonOut_transEntry_bits_payload_singleStep;
  wire i_io_commonOut_transEntry_bits_payload_singleStep;
  wire g_io_commonOut_transEntry_bits_payload_replayInst;
  wire i_io_commonOut_transEntry_bits_payload_replayInst;
  wire [34:0] g_io_commonOut_transEntry_bits_payload_debug_fuType;
  wire [34:0] i_io_commonOut_transEntry_bits_payload_debug_fuType;
  wire g_io_commonOut_transEntry_bits_payload_debug_sim_trig;
  wire i_io_commonOut_transEntry_bits_payload_debug_sim_trig;
  wire [4:0] g_io_commonOut_transEntry_bits_payload_numLsElem;
  wire [4:0] i_io_commonOut_transEntry_bits_payload_numLsElem;
  wire g_io_commonOut_entryInValid;
  wire i_io_commonOut_entryInValid;
  wire g_io_commonOut_entryOutDeqValid;
  wire i_io_commonOut_entryOutDeqValid;
  wire g_io_commonOut_entryOutTransValid;
  wire i_io_commonOut_entryOutTransValid;
  wire g_io_commonOut_perfLdCancel_0;
  wire i_io_commonOut_perfLdCancel_0;
  wire g_io_commonOut_perfOg0Cancel_0;
  wire i_io_commonOut_perfOg0Cancel_0;
  wire g_io_commonOut_perfWakeupByWB_0;
  wire i_io_commonOut_perfWakeupByWB_0;
  wire g_io_commonOut_perfWakeupByIQ_0_0;
  wire i_io_commonOut_perfWakeupByIQ_0_0;
  wire g_io_commonOut_perfWakeupByIQ_0_1;
  wire i_io_commonOut_perfWakeupByIQ_0_1;
  wire g_io_commonOut_perfWakeupByIQ_0_2;
  wire i_io_commonOut_perfWakeupByIQ_0_2;
  wire g_io_commonOut_perfWakeupByIQ_0_3;
  wire i_io_commonOut_perfWakeupByIQ_0_3;
  wire g_io_commonOut_perfWakeupByIQ_0_4;
  wire i_io_commonOut_perfWakeupByIQ_0_4;
  wire g_io_commonOut_perfWakeupByIQ_0_5;
  wire i_io_commonOut_perfWakeupByIQ_0_5;
  wire g_io_commonOut_perfWakeupByIQ_0_6;
  wire i_io_commonOut_perfWakeupByIQ_0_6;

  OthersEntry_200 u_g (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_15(io_commonIn_enq_bits_status_fuType_15),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonIn_enq_bits_status_srcStatus_0_exuSources_value(io_commonIn_enq_bits_status_srcStatus_0_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_useRegCache(io_commonIn_enq_bits_status_srcStatus_0_useRegCache),
    .io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx(io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx),
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_imm(io_commonIn_enq_bits_imm),
    .io_commonIn_enq_bits_payload_instr(io_commonIn_enq_bits_payload_instr),
    .io_commonIn_enq_bits_payload_pc(io_commonIn_enq_bits_payload_pc),
    .io_commonIn_enq_bits_payload_foldpc(io_commonIn_enq_bits_payload_foldpc),
    .io_commonIn_enq_bits_payload_exceptionVec_0(io_commonIn_enq_bits_payload_exceptionVec_0),
    .io_commonIn_enq_bits_payload_exceptionVec_1(io_commonIn_enq_bits_payload_exceptionVec_1),
    .io_commonIn_enq_bits_payload_exceptionVec_2(io_commonIn_enq_bits_payload_exceptionVec_2),
    .io_commonIn_enq_bits_payload_exceptionVec_3(io_commonIn_enq_bits_payload_exceptionVec_3),
    .io_commonIn_enq_bits_payload_exceptionVec_4(io_commonIn_enq_bits_payload_exceptionVec_4),
    .io_commonIn_enq_bits_payload_exceptionVec_5(io_commonIn_enq_bits_payload_exceptionVec_5),
    .io_commonIn_enq_bits_payload_exceptionVec_6(io_commonIn_enq_bits_payload_exceptionVec_6),
    .io_commonIn_enq_bits_payload_exceptionVec_7(io_commonIn_enq_bits_payload_exceptionVec_7),
    .io_commonIn_enq_bits_payload_exceptionVec_8(io_commonIn_enq_bits_payload_exceptionVec_8),
    .io_commonIn_enq_bits_payload_exceptionVec_9(io_commonIn_enq_bits_payload_exceptionVec_9),
    .io_commonIn_enq_bits_payload_exceptionVec_10(io_commonIn_enq_bits_payload_exceptionVec_10),
    .io_commonIn_enq_bits_payload_exceptionVec_11(io_commonIn_enq_bits_payload_exceptionVec_11),
    .io_commonIn_enq_bits_payload_exceptionVec_12(io_commonIn_enq_bits_payload_exceptionVec_12),
    .io_commonIn_enq_bits_payload_exceptionVec_13(io_commonIn_enq_bits_payload_exceptionVec_13),
    .io_commonIn_enq_bits_payload_exceptionVec_14(io_commonIn_enq_bits_payload_exceptionVec_14),
    .io_commonIn_enq_bits_payload_exceptionVec_15(io_commonIn_enq_bits_payload_exceptionVec_15),
    .io_commonIn_enq_bits_payload_exceptionVec_16(io_commonIn_enq_bits_payload_exceptionVec_16),
    .io_commonIn_enq_bits_payload_exceptionVec_17(io_commonIn_enq_bits_payload_exceptionVec_17),
    .io_commonIn_enq_bits_payload_exceptionVec_18(io_commonIn_enq_bits_payload_exceptionVec_18),
    .io_commonIn_enq_bits_payload_exceptionVec_19(io_commonIn_enq_bits_payload_exceptionVec_19),
    .io_commonIn_enq_bits_payload_exceptionVec_20(io_commonIn_enq_bits_payload_exceptionVec_20),
    .io_commonIn_enq_bits_payload_exceptionVec_21(io_commonIn_enq_bits_payload_exceptionVec_21),
    .io_commonIn_enq_bits_payload_exceptionVec_22(io_commonIn_enq_bits_payload_exceptionVec_22),
    .io_commonIn_enq_bits_payload_exceptionVec_23(io_commonIn_enq_bits_payload_exceptionVec_23),
    .io_commonIn_enq_bits_payload_isFetchMalAddr(io_commonIn_enq_bits_payload_isFetchMalAddr),
    .io_commonIn_enq_bits_payload_hasException(io_commonIn_enq_bits_payload_hasException),
    .io_commonIn_enq_bits_payload_trigger(io_commonIn_enq_bits_payload_trigger),
    .io_commonIn_enq_bits_payload_preDecodeInfo_valid(io_commonIn_enq_bits_payload_preDecodeInfo_valid),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isRVC(io_commonIn_enq_bits_payload_preDecodeInfo_isRVC),
    .io_commonIn_enq_bits_payload_preDecodeInfo_brType(io_commonIn_enq_bits_payload_preDecodeInfo_brType),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isCall(io_commonIn_enq_bits_payload_preDecodeInfo_isCall),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isRet(io_commonIn_enq_bits_payload_preDecodeInfo_isRet),
    .io_commonIn_enq_bits_payload_pred_taken(io_commonIn_enq_bits_payload_pred_taken),
    .io_commonIn_enq_bits_payload_crossPageIPFFix(io_commonIn_enq_bits_payload_crossPageIPFFix),
    .io_commonIn_enq_bits_payload_ftqPtr_flag(io_commonIn_enq_bits_payload_ftqPtr_flag),
    .io_commonIn_enq_bits_payload_ftqPtr_value(io_commonIn_enq_bits_payload_ftqPtr_value),
    .io_commonIn_enq_bits_payload_ftqOffset(io_commonIn_enq_bits_payload_ftqOffset),
    .io_commonIn_enq_bits_payload_satpFlushFirstFetchFault(io_commonIn_enq_bits_payload_satpFlushFirstFetchFault),
    .io_commonIn_enq_bits_payload_srcType_0(io_commonIn_enq_bits_payload_srcType_0),
    .io_commonIn_enq_bits_payload_srcType_1(io_commonIn_enq_bits_payload_srcType_1),
    .io_commonIn_enq_bits_payload_srcType_2(io_commonIn_enq_bits_payload_srcType_2),
    .io_commonIn_enq_bits_payload_srcType_3(io_commonIn_enq_bits_payload_srcType_3),
    .io_commonIn_enq_bits_payload_srcType_4(io_commonIn_enq_bits_payload_srcType_4),
    .io_commonIn_enq_bits_payload_ldest(io_commonIn_enq_bits_payload_ldest),
    .io_commonIn_enq_bits_payload_fuType(io_commonIn_enq_bits_payload_fuType),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_rfWen(io_commonIn_enq_bits_payload_rfWen),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_vecWen(io_commonIn_enq_bits_payload_vecWen),
    .io_commonIn_enq_bits_payload_v0Wen(io_commonIn_enq_bits_payload_v0Wen),
    .io_commonIn_enq_bits_payload_vlWen(io_commonIn_enq_bits_payload_vlWen),
    .io_commonIn_enq_bits_payload_isXSTrap(io_commonIn_enq_bits_payload_isXSTrap),
    .io_commonIn_enq_bits_payload_waitForward(io_commonIn_enq_bits_payload_waitForward),
    .io_commonIn_enq_bits_payload_blockBackward(io_commonIn_enq_bits_payload_blockBackward),
    .io_commonIn_enq_bits_payload_flushPipe(io_commonIn_enq_bits_payload_flushPipe),
    .io_commonIn_enq_bits_payload_canRobCompress(io_commonIn_enq_bits_payload_canRobCompress),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
    .io_commonIn_enq_bits_payload_imm(io_commonIn_enq_bits_payload_imm),
    .io_commonIn_enq_bits_payload_fpu_typeTagOut(io_commonIn_enq_bits_payload_fpu_typeTagOut),
    .io_commonIn_enq_bits_payload_fpu_wflags(io_commonIn_enq_bits_payload_fpu_wflags),
    .io_commonIn_enq_bits_payload_fpu_typ(io_commonIn_enq_bits_payload_fpu_typ),
    .io_commonIn_enq_bits_payload_fpu_fmt(io_commonIn_enq_bits_payload_fpu_fmt),
    .io_commonIn_enq_bits_payload_fpu_rm(io_commonIn_enq_bits_payload_fpu_rm),
    .io_commonIn_enq_bits_payload_vpu_vill(io_commonIn_enq_bits_payload_vpu_vill),
    .io_commonIn_enq_bits_payload_vpu_vma(io_commonIn_enq_bits_payload_vpu_vma),
    .io_commonIn_enq_bits_payload_vpu_vta(io_commonIn_enq_bits_payload_vpu_vta),
    .io_commonIn_enq_bits_payload_vpu_vsew(io_commonIn_enq_bits_payload_vpu_vsew),
    .io_commonIn_enq_bits_payload_vpu_vlmul(io_commonIn_enq_bits_payload_vpu_vlmul),
    .io_commonIn_enq_bits_payload_vpu_specVill(io_commonIn_enq_bits_payload_vpu_specVill),
    .io_commonIn_enq_bits_payload_vpu_specVma(io_commonIn_enq_bits_payload_vpu_specVma),
    .io_commonIn_enq_bits_payload_vpu_specVta(io_commonIn_enq_bits_payload_vpu_specVta),
    .io_commonIn_enq_bits_payload_vpu_specVsew(io_commonIn_enq_bits_payload_vpu_specVsew),
    .io_commonIn_enq_bits_payload_vpu_specVlmul(io_commonIn_enq_bits_payload_vpu_specVlmul),
    .io_commonIn_enq_bits_payload_vpu_vm(io_commonIn_enq_bits_payload_vpu_vm),
    .io_commonIn_enq_bits_payload_vpu_vstart(io_commonIn_enq_bits_payload_vpu_vstart),
    .io_commonIn_enq_bits_payload_vpu_frm(io_commonIn_enq_bits_payload_vpu_frm),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst(io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr(io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr(io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonIn_enq_bits_payload_vpu_fpu_isReduction(io_commonIn_enq_bits_payload_vpu_fpu_isReduction),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonIn_enq_bits_payload_vpu_vxrm(io_commonIn_enq_bits_payload_vpu_vxrm),
    .io_commonIn_enq_bits_payload_vpu_vuopIdx(io_commonIn_enq_bits_payload_vpu_vuopIdx),
    .io_commonIn_enq_bits_payload_vpu_lastUop(io_commonIn_enq_bits_payload_vpu_lastUop),
    .io_commonIn_enq_bits_payload_vpu_vmask(io_commonIn_enq_bits_payload_vpu_vmask),
    .io_commonIn_enq_bits_payload_vpu_vl(io_commonIn_enq_bits_payload_vpu_vl),
    .io_commonIn_enq_bits_payload_vpu_nf(io_commonIn_enq_bits_payload_vpu_nf),
    .io_commonIn_enq_bits_payload_vpu_veew(io_commonIn_enq_bits_payload_vpu_veew),
    .io_commonIn_enq_bits_payload_vpu_isReverse(io_commonIn_enq_bits_payload_vpu_isReverse),
    .io_commonIn_enq_bits_payload_vpu_isExt(io_commonIn_enq_bits_payload_vpu_isExt),
    .io_commonIn_enq_bits_payload_vpu_isNarrow(io_commonIn_enq_bits_payload_vpu_isNarrow),
    .io_commonIn_enq_bits_payload_vpu_isDstMask(io_commonIn_enq_bits_payload_vpu_isDstMask),
    .io_commonIn_enq_bits_payload_vpu_isOpMask(io_commonIn_enq_bits_payload_vpu_isOpMask),
    .io_commonIn_enq_bits_payload_vpu_isMove(io_commonIn_enq_bits_payload_vpu_isMove),
    .io_commonIn_enq_bits_payload_vpu_isDependOldVd(io_commonIn_enq_bits_payload_vpu_isDependOldVd),
    .io_commonIn_enq_bits_payload_vpu_isWritePartVd(io_commonIn_enq_bits_payload_vpu_isWritePartVd),
    .io_commonIn_enq_bits_payload_vpu_isVleff(io_commonIn_enq_bits_payload_vpu_isVleff),
    .io_commonIn_enq_bits_payload_vlsInstr(io_commonIn_enq_bits_payload_vlsInstr),
    .io_commonIn_enq_bits_payload_wfflags(io_commonIn_enq_bits_payload_wfflags),
    .io_commonIn_enq_bits_payload_isMove(io_commonIn_enq_bits_payload_isMove),
    .io_commonIn_enq_bits_payload_isDropAmocasSta(io_commonIn_enq_bits_payload_isDropAmocasSta),
    .io_commonIn_enq_bits_payload_uopIdx(io_commonIn_enq_bits_payload_uopIdx),
    .io_commonIn_enq_bits_payload_isVset(io_commonIn_enq_bits_payload_isVset),
    .io_commonIn_enq_bits_payload_firstUop(io_commonIn_enq_bits_payload_firstUop),
    .io_commonIn_enq_bits_payload_lastUop(io_commonIn_enq_bits_payload_lastUop),
    .io_commonIn_enq_bits_payload_numUops(io_commonIn_enq_bits_payload_numUops),
    .io_commonIn_enq_bits_payload_numWB(io_commonIn_enq_bits_payload_numWB),
    .io_commonIn_enq_bits_payload_commitType(io_commonIn_enq_bits_payload_commitType),
    .io_commonIn_enq_bits_payload_srcState_0(io_commonIn_enq_bits_payload_srcState_0),
    .io_commonIn_enq_bits_payload_srcState_1(io_commonIn_enq_bits_payload_srcState_1),
    .io_commonIn_enq_bits_payload_srcState_2(io_commonIn_enq_bits_payload_srcState_2),
    .io_commonIn_enq_bits_payload_srcState_3(io_commonIn_enq_bits_payload_srcState_3),
    .io_commonIn_enq_bits_payload_srcState_4(io_commonIn_enq_bits_payload_srcState_4),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_0(io_commonIn_enq_bits_payload_srcLoadDependency_0_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_1(io_commonIn_enq_bits_payload_srcLoadDependency_0_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_2(io_commonIn_enq_bits_payload_srcLoadDependency_0_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_0(io_commonIn_enq_bits_payload_srcLoadDependency_1_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_1(io_commonIn_enq_bits_payload_srcLoadDependency_1_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_2(io_commonIn_enq_bits_payload_srcLoadDependency_1_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_0(io_commonIn_enq_bits_payload_srcLoadDependency_2_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_1(io_commonIn_enq_bits_payload_srcLoadDependency_2_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_2(io_commonIn_enq_bits_payload_srcLoadDependency_2_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_0(io_commonIn_enq_bits_payload_srcLoadDependency_3_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_1(io_commonIn_enq_bits_payload_srcLoadDependency_3_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_2(io_commonIn_enq_bits_payload_srcLoadDependency_3_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_0(io_commonIn_enq_bits_payload_srcLoadDependency_4_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_1(io_commonIn_enq_bits_payload_srcLoadDependency_4_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_2(io_commonIn_enq_bits_payload_srcLoadDependency_4_2),
    .io_commonIn_enq_bits_payload_psrc_0(io_commonIn_enq_bits_payload_psrc_0),
    .io_commonIn_enq_bits_payload_psrc_1(io_commonIn_enq_bits_payload_psrc_1),
    .io_commonIn_enq_bits_payload_psrc_2(io_commonIn_enq_bits_payload_psrc_2),
    .io_commonIn_enq_bits_payload_psrc_3(io_commonIn_enq_bits_payload_psrc_3),
    .io_commonIn_enq_bits_payload_psrc_4(io_commonIn_enq_bits_payload_psrc_4),
    .io_commonIn_enq_bits_payload_pdest(io_commonIn_enq_bits_payload_pdest),
    .io_commonIn_enq_bits_payload_useRegCache_0(io_commonIn_enq_bits_payload_useRegCache_0),
    .io_commonIn_enq_bits_payload_useRegCache_1(io_commonIn_enq_bits_payload_useRegCache_1),
    .io_commonIn_enq_bits_payload_regCacheIdx_0(io_commonIn_enq_bits_payload_regCacheIdx_0),
    .io_commonIn_enq_bits_payload_regCacheIdx_1(io_commonIn_enq_bits_payload_regCacheIdx_1),
    .io_commonIn_enq_bits_payload_robIdx_flag(io_commonIn_enq_bits_payload_robIdx_flag),
    .io_commonIn_enq_bits_payload_robIdx_value(io_commonIn_enq_bits_payload_robIdx_value),
    .io_commonIn_enq_bits_payload_instrSize(io_commonIn_enq_bits_payload_instrSize),
    .io_commonIn_enq_bits_payload_dirtyFs(io_commonIn_enq_bits_payload_dirtyFs),
    .io_commonIn_enq_bits_payload_dirtyVs(io_commonIn_enq_bits_payload_dirtyVs),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_itype(io_commonIn_enq_bits_payload_traceBlockInPipe_itype),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_iretire(io_commonIn_enq_bits_payload_traceBlockInPipe_iretire),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize(io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize),
    .io_commonIn_enq_bits_payload_eliminatedMove(io_commonIn_enq_bits_payload_eliminatedMove),
    .io_commonIn_enq_bits_payload_snapshot(io_commonIn_enq_bits_payload_snapshot),
    .io_commonIn_enq_bits_payload_debugInfo_eliminatedMove(io_commonIn_enq_bits_payload_debugInfo_eliminatedMove),
    .io_commonIn_enq_bits_payload_debugInfo_renameTime(io_commonIn_enq_bits_payload_debugInfo_renameTime),
    .io_commonIn_enq_bits_payload_debugInfo_dispatchTime(io_commonIn_enq_bits_payload_debugInfo_dispatchTime),
    .io_commonIn_enq_bits_payload_debugInfo_enqRsTime(io_commonIn_enq_bits_payload_debugInfo_enqRsTime),
    .io_commonIn_enq_bits_payload_debugInfo_selectTime(io_commonIn_enq_bits_payload_debugInfo_selectTime),
    .io_commonIn_enq_bits_payload_debugInfo_issueTime(io_commonIn_enq_bits_payload_debugInfo_issueTime),
    .io_commonIn_enq_bits_payload_debugInfo_writebackTime(io_commonIn_enq_bits_payload_debugInfo_writebackTime),
    .io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id(io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime(io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonIn_enq_bits_payload_debugInfo_tlbRespTime(io_commonIn_enq_bits_payload_debugInfo_tlbRespTime),
    .io_commonIn_enq_bits_payload_debug_seqNum_seqNum(io_commonIn_enq_bits_payload_debug_seqNum_seqNum),
    .io_commonIn_enq_bits_payload_debug_seqNum_uopIdx(io_commonIn_enq_bits_payload_debug_seqNum_uopIdx),
    .io_commonIn_enq_bits_payload_storeSetHit(io_commonIn_enq_bits_payload_storeSetHit),
    .io_commonIn_enq_bits_payload_waitForRobIdx_flag(io_commonIn_enq_bits_payload_waitForRobIdx_flag),
    .io_commonIn_enq_bits_payload_waitForRobIdx_value(io_commonIn_enq_bits_payload_waitForRobIdx_value),
    .io_commonIn_enq_bits_payload_loadWaitBit(io_commonIn_enq_bits_payload_loadWaitBit),
    .io_commonIn_enq_bits_payload_loadWaitStrict(io_commonIn_enq_bits_payload_loadWaitStrict),
    .io_commonIn_enq_bits_payload_ssid(io_commonIn_enq_bits_payload_ssid),
    .io_commonIn_enq_bits_payload_lqIdx_flag(io_commonIn_enq_bits_payload_lqIdx_flag),
    .io_commonIn_enq_bits_payload_lqIdx_value(io_commonIn_enq_bits_payload_lqIdx_value),
    .io_commonIn_enq_bits_payload_sqIdx_flag(io_commonIn_enq_bits_payload_sqIdx_flag),
    .io_commonIn_enq_bits_payload_sqIdx_value(io_commonIn_enq_bits_payload_sqIdx_value),
    .io_commonIn_enq_bits_payload_singleStep(io_commonIn_enq_bits_payload_singleStep),
    .io_commonIn_enq_bits_payload_replayInst(io_commonIn_enq_bits_payload_replayInst),
    .io_commonIn_enq_bits_payload_debug_fuType(io_commonIn_enq_bits_payload_debug_fuType),
    .io_commonIn_enq_bits_payload_debug_sim_trig(io_commonIn_enq_bits_payload_debug_sim_trig),
    .io_commonIn_enq_bits_payload_numLsElem(io_commonIn_enq_bits_payload_numLsElem),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_rfWen(io_commonIn_wakeUpFromWB_3_bits_rfWen),
    .io_commonIn_wakeUpFromWB_3_bits_fpWen(io_commonIn_wakeUpFromWB_3_bits_fpWen),
    .io_commonIn_wakeUpFromWB_3_bits_vecWen(io_commonIn_wakeUpFromWB_3_bits_vecWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_rfWen(io_commonIn_wakeUpFromWB_2_bits_rfWen),
    .io_commonIn_wakeUpFromWB_2_bits_fpWen(io_commonIn_wakeUpFromWB_2_bits_fpWen),
    .io_commonIn_wakeUpFromWB_2_bits_vecWen(io_commonIn_wakeUpFromWB_2_bits_vecWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_rfWen(io_commonIn_wakeUpFromWB_1_bits_rfWen),
    .io_commonIn_wakeUpFromWB_1_bits_fpWen(io_commonIn_wakeUpFromWB_1_bits_fpWen),
    .io_commonIn_wakeUpFromWB_1_bits_vecWen(io_commonIn_wakeUpFromWB_1_bits_vecWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_rfWen(io_commonIn_wakeUpFromWB_0_bits_rfWen),
    .io_commonIn_wakeUpFromWB_0_bits_fpWen(io_commonIn_wakeUpFromWB_0_bits_fpWen),
    .io_commonIn_wakeUpFromWB_0_bits_vecWen(io_commonIn_wakeUpFromWB_0_bits_vecWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_6_bits_rfWen(io_commonIn_wakeUpFromIQ_6_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_6_bits_pdest(io_commonIn_wakeUpFromIQ_6_bits_pdest),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_6_bits_is0Lat(io_commonIn_wakeUpFromIQ_6_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_6_bits_rcDest(io_commonIn_wakeUpFromIQ_6_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_5_bits_rfWen(io_commonIn_wakeUpFromIQ_5_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_5_bits_pdest(io_commonIn_wakeUpFromIQ_5_bits_pdest),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_5_bits_is0Lat(io_commonIn_wakeUpFromIQ_5_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_5_bits_rcDest(io_commonIn_wakeUpFromIQ_5_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_4_bits_rfWen(io_commonIn_wakeUpFromIQ_4_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_4_bits_pdest(io_commonIn_wakeUpFromIQ_4_bits_pdest),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_4_bits_is0Lat(io_commonIn_wakeUpFromIQ_4_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_4_bits_rcDest(io_commonIn_wakeUpFromIQ_4_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_3_bits_rfWen(io_commonIn_wakeUpFromIQ_3_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_3_bits_pdest(io_commonIn_wakeUpFromIQ_3_bits_pdest),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_3_bits_is0Lat(io_commonIn_wakeUpFromIQ_3_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_3_bits_rcDest(io_commonIn_wakeUpFromIQ_3_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_2_bits_rfWen(io_commonIn_wakeUpFromIQ_2_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_2_bits_pdest(io_commonIn_wakeUpFromIQ_2_bits_pdest),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_2_bits_is0Lat(io_commonIn_wakeUpFromIQ_2_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_2_bits_rcDest(io_commonIn_wakeUpFromIQ_2_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_1_bits_rfWen(io_commonIn_wakeUpFromIQ_1_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_1_bits_pdest(io_commonIn_wakeUpFromIQ_1_bits_pdest),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_1_bits_is0Lat(io_commonIn_wakeUpFromIQ_1_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_1_bits_rcDest(io_commonIn_wakeUpFromIQ_1_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_0_bits_rfWen(io_commonIn_wakeUpFromIQ_0_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_0_bits_pdest(io_commonIn_wakeUpFromIQ_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_0_bits_is0Lat(io_commonIn_wakeUpFromIQ_0_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_0_bits_rcDest(io_commonIn_wakeUpFromIQ_0_bits_rcDest),
    .io_commonIn_og0Cancel_0(io_commonIn_og0Cancel_0),
    .io_commonIn_og0Cancel_2(io_commonIn_og0Cancel_2),
    .io_commonIn_og0Cancel_4(io_commonIn_og0Cancel_4),
    .io_commonIn_og0Cancel_6(io_commonIn_og0Cancel_6),
    .io_commonIn_og0Cancel_20(io_commonIn_og0Cancel_20),
    .io_commonIn_og0Cancel_21(io_commonIn_og0Cancel_21),
    .io_commonIn_og0Cancel_22(io_commonIn_og0Cancel_22),
    .io_commonIn_ldCancel_0_ld1Cancel(io_commonIn_ldCancel_0_ld1Cancel),
    .io_commonIn_ldCancel_0_ld2Cancel(io_commonIn_ldCancel_0_ld2Cancel),
    .io_commonIn_ldCancel_1_ld1Cancel(io_commonIn_ldCancel_1_ld1Cancel),
    .io_commonIn_ldCancel_1_ld2Cancel(io_commonIn_ldCancel_1_ld2Cancel),
    .io_commonIn_ldCancel_2_ld1Cancel(io_commonIn_ldCancel_2_ld1Cancel),
    .io_commonIn_ldCancel_2_ld2Cancel(io_commonIn_ldCancel_2_ld2Cancel),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonIn_transSel(io_commonIn_transSel),
    .io_commonOut_valid(g_io_commonOut_valid),
    .io_commonOut_issued(g_io_commonOut_issued),
    .io_commonOut_canIssue(g_io_commonOut_canIssue),
    .io_commonOut_fuType(g_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(g_io_commonOut_dataSources_0_value),
    .io_commonOut_exuSources_0_value(g_io_commonOut_exuSources_0_value),
    .io_commonOut_isFirstIssue(g_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(g_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(g_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_15(g_io_commonOut_entry_bits_status_fuType_15),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(g_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(g_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0(g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1(g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2(g_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx(g_io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx),
    .io_commonOut_entry_bits_imm(g_io_commonOut_entry_bits_imm),
    .io_commonOut_entry_bits_payload_preDecodeInfo_valid(g_io_commonOut_entry_bits_payload_preDecodeInfo_valid),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isRVC(g_io_commonOut_entry_bits_payload_preDecodeInfo_isRVC),
    .io_commonOut_entry_bits_payload_preDecodeInfo_brType(g_io_commonOut_entry_bits_payload_preDecodeInfo_brType),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isCall(g_io_commonOut_entry_bits_payload_preDecodeInfo_isCall),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isRet(g_io_commonOut_entry_bits_payload_preDecodeInfo_isRet),
    .io_commonOut_entry_bits_payload_ftqPtr_flag(g_io_commonOut_entry_bits_payload_ftqPtr_flag),
    .io_commonOut_entry_bits_payload_ftqPtr_value(g_io_commonOut_entry_bits_payload_ftqPtr_value),
    .io_commonOut_entry_bits_payload_ftqOffset(g_io_commonOut_entry_bits_payload_ftqOffset),
    .io_commonOut_entry_bits_payload_fuOpType(g_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(g_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(g_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_flushPipe(g_io_commonOut_entry_bits_payload_flushPipe),
    .io_commonOut_entry_bits_payload_selImm(g_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_pdest(g_io_commonOut_entry_bits_payload_pdest),
    .io_commonOut_entry_bits_payload_debugInfo_eliminatedMove(g_io_commonOut_entry_bits_payload_debugInfo_eliminatedMove),
    .io_commonOut_entry_bits_payload_debugInfo_renameTime(g_io_commonOut_entry_bits_payload_debugInfo_renameTime),
    .io_commonOut_entry_bits_payload_debugInfo_dispatchTime(g_io_commonOut_entry_bits_payload_debugInfo_dispatchTime),
    .io_commonOut_entry_bits_payload_debugInfo_enqRsTime(g_io_commonOut_entry_bits_payload_debugInfo_enqRsTime),
    .io_commonOut_entry_bits_payload_debugInfo_writebackTime(g_io_commonOut_entry_bits_payload_debugInfo_writebackTime),
    .io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id(g_io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime(g_io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonOut_entry_bits_payload_debugInfo_tlbRespTime(g_io_commonOut_entry_bits_payload_debugInfo_tlbRespTime),
    .io_commonOut_entry_bits_payload_debug_seqNum_seqNum(g_io_commonOut_entry_bits_payload_debug_seqNum_seqNum),
    .io_commonOut_entry_bits_payload_debug_seqNum_uopIdx(g_io_commonOut_entry_bits_payload_debug_seqNum_uopIdx),
    .io_commonOut_entry_bits_payload_storeSetHit(g_io_commonOut_entry_bits_payload_storeSetHit),
    .io_commonOut_entry_bits_payload_waitForRobIdx_flag(g_io_commonOut_entry_bits_payload_waitForRobIdx_flag),
    .io_commonOut_entry_bits_payload_waitForRobIdx_value(g_io_commonOut_entry_bits_payload_waitForRobIdx_value),
    .io_commonOut_entry_bits_payload_loadWaitBit(g_io_commonOut_entry_bits_payload_loadWaitBit),
    .io_commonOut_entry_bits_payload_loadWaitStrict(g_io_commonOut_entry_bits_payload_loadWaitStrict),
    .io_commonOut_entry_bits_payload_ssid(g_io_commonOut_entry_bits_payload_ssid),
    .io_commonOut_entry_bits_payload_lqIdx_flag(g_io_commonOut_entry_bits_payload_lqIdx_flag),
    .io_commonOut_entry_bits_payload_lqIdx_value(g_io_commonOut_entry_bits_payload_lqIdx_value),
    .io_commonOut_entry_bits_payload_sqIdx_flag(g_io_commonOut_entry_bits_payload_sqIdx_flag),
    .io_commonOut_entry_bits_payload_sqIdx_value(g_io_commonOut_entry_bits_payload_sqIdx_value),
    .io_commonOut_cancelBypass(g_io_commonOut_cancelBypass),
    .io_commonOut_issueTimerRead(g_io_commonOut_issueTimerRead),
    .io_commonOut_enqReady(g_io_commonOut_enqReady),
    .io_commonOut_transEntry_valid(g_io_commonOut_transEntry_valid),
    .io_commonOut_transEntry_bits_status_robIdx_flag(g_io_commonOut_transEntry_bits_status_robIdx_flag),
    .io_commonOut_transEntry_bits_status_robIdx_value(g_io_commonOut_transEntry_bits_status_robIdx_value),
    .io_commonOut_transEntry_bits_status_fuType_15(g_io_commonOut_transEntry_bits_status_fuType_15),
    .io_commonOut_transEntry_bits_status_srcStatus_0_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_0_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache(g_io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache),
    .io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx(g_io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx),
    .io_commonOut_transEntry_bits_status_issued(g_io_commonOut_transEntry_bits_status_issued),
    .io_commonOut_transEntry_bits_status_firstIssue(g_io_commonOut_transEntry_bits_status_firstIssue),
    .io_commonOut_transEntry_bits_status_issueTimer(g_io_commonOut_transEntry_bits_status_issueTimer),
    .io_commonOut_transEntry_bits_status_deqPortIdx(g_io_commonOut_transEntry_bits_status_deqPortIdx),
    .io_commonOut_transEntry_bits_imm(g_io_commonOut_transEntry_bits_imm),
    .io_commonOut_transEntry_bits_payload_instr(g_io_commonOut_transEntry_bits_payload_instr),
    .io_commonOut_transEntry_bits_payload_pc(g_io_commonOut_transEntry_bits_payload_pc),
    .io_commonOut_transEntry_bits_payload_foldpc(g_io_commonOut_transEntry_bits_payload_foldpc),
    .io_commonOut_transEntry_bits_payload_exceptionVec_0(g_io_commonOut_transEntry_bits_payload_exceptionVec_0),
    .io_commonOut_transEntry_bits_payload_exceptionVec_1(g_io_commonOut_transEntry_bits_payload_exceptionVec_1),
    .io_commonOut_transEntry_bits_payload_exceptionVec_2(g_io_commonOut_transEntry_bits_payload_exceptionVec_2),
    .io_commonOut_transEntry_bits_payload_exceptionVec_3(g_io_commonOut_transEntry_bits_payload_exceptionVec_3),
    .io_commonOut_transEntry_bits_payload_exceptionVec_4(g_io_commonOut_transEntry_bits_payload_exceptionVec_4),
    .io_commonOut_transEntry_bits_payload_exceptionVec_5(g_io_commonOut_transEntry_bits_payload_exceptionVec_5),
    .io_commonOut_transEntry_bits_payload_exceptionVec_6(g_io_commonOut_transEntry_bits_payload_exceptionVec_6),
    .io_commonOut_transEntry_bits_payload_exceptionVec_7(g_io_commonOut_transEntry_bits_payload_exceptionVec_7),
    .io_commonOut_transEntry_bits_payload_exceptionVec_8(g_io_commonOut_transEntry_bits_payload_exceptionVec_8),
    .io_commonOut_transEntry_bits_payload_exceptionVec_9(g_io_commonOut_transEntry_bits_payload_exceptionVec_9),
    .io_commonOut_transEntry_bits_payload_exceptionVec_10(g_io_commonOut_transEntry_bits_payload_exceptionVec_10),
    .io_commonOut_transEntry_bits_payload_exceptionVec_11(g_io_commonOut_transEntry_bits_payload_exceptionVec_11),
    .io_commonOut_transEntry_bits_payload_exceptionVec_12(g_io_commonOut_transEntry_bits_payload_exceptionVec_12),
    .io_commonOut_transEntry_bits_payload_exceptionVec_13(g_io_commonOut_transEntry_bits_payload_exceptionVec_13),
    .io_commonOut_transEntry_bits_payload_exceptionVec_14(g_io_commonOut_transEntry_bits_payload_exceptionVec_14),
    .io_commonOut_transEntry_bits_payload_exceptionVec_15(g_io_commonOut_transEntry_bits_payload_exceptionVec_15),
    .io_commonOut_transEntry_bits_payload_exceptionVec_16(g_io_commonOut_transEntry_bits_payload_exceptionVec_16),
    .io_commonOut_transEntry_bits_payload_exceptionVec_17(g_io_commonOut_transEntry_bits_payload_exceptionVec_17),
    .io_commonOut_transEntry_bits_payload_exceptionVec_18(g_io_commonOut_transEntry_bits_payload_exceptionVec_18),
    .io_commonOut_transEntry_bits_payload_exceptionVec_19(g_io_commonOut_transEntry_bits_payload_exceptionVec_19),
    .io_commonOut_transEntry_bits_payload_exceptionVec_20(g_io_commonOut_transEntry_bits_payload_exceptionVec_20),
    .io_commonOut_transEntry_bits_payload_exceptionVec_21(g_io_commonOut_transEntry_bits_payload_exceptionVec_21),
    .io_commonOut_transEntry_bits_payload_exceptionVec_22(g_io_commonOut_transEntry_bits_payload_exceptionVec_22),
    .io_commonOut_transEntry_bits_payload_exceptionVec_23(g_io_commonOut_transEntry_bits_payload_exceptionVec_23),
    .io_commonOut_transEntry_bits_payload_isFetchMalAddr(g_io_commonOut_transEntry_bits_payload_isFetchMalAddr),
    .io_commonOut_transEntry_bits_payload_hasException(g_io_commonOut_transEntry_bits_payload_hasException),
    .io_commonOut_transEntry_bits_payload_trigger(g_io_commonOut_transEntry_bits_payload_trigger),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_valid(g_io_commonOut_transEntry_bits_payload_preDecodeInfo_valid),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC(g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_brType(g_io_commonOut_transEntry_bits_payload_preDecodeInfo_brType),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall(g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet(g_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet),
    .io_commonOut_transEntry_bits_payload_pred_taken(g_io_commonOut_transEntry_bits_payload_pred_taken),
    .io_commonOut_transEntry_bits_payload_crossPageIPFFix(g_io_commonOut_transEntry_bits_payload_crossPageIPFFix),
    .io_commonOut_transEntry_bits_payload_ftqPtr_flag(g_io_commonOut_transEntry_bits_payload_ftqPtr_flag),
    .io_commonOut_transEntry_bits_payload_ftqPtr_value(g_io_commonOut_transEntry_bits_payload_ftqPtr_value),
    .io_commonOut_transEntry_bits_payload_ftqOffset(g_io_commonOut_transEntry_bits_payload_ftqOffset),
    .io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault(g_io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault),
    .io_commonOut_transEntry_bits_payload_srcType_0(g_io_commonOut_transEntry_bits_payload_srcType_0),
    .io_commonOut_transEntry_bits_payload_srcType_1(g_io_commonOut_transEntry_bits_payload_srcType_1),
    .io_commonOut_transEntry_bits_payload_srcType_2(g_io_commonOut_transEntry_bits_payload_srcType_2),
    .io_commonOut_transEntry_bits_payload_srcType_3(g_io_commonOut_transEntry_bits_payload_srcType_3),
    .io_commonOut_transEntry_bits_payload_srcType_4(g_io_commonOut_transEntry_bits_payload_srcType_4),
    .io_commonOut_transEntry_bits_payload_ldest(g_io_commonOut_transEntry_bits_payload_ldest),
    .io_commonOut_transEntry_bits_payload_fuType(g_io_commonOut_transEntry_bits_payload_fuType),
    .io_commonOut_transEntry_bits_payload_fuOpType(g_io_commonOut_transEntry_bits_payload_fuOpType),
    .io_commonOut_transEntry_bits_payload_rfWen(g_io_commonOut_transEntry_bits_payload_rfWen),
    .io_commonOut_transEntry_bits_payload_fpWen(g_io_commonOut_transEntry_bits_payload_fpWen),
    .io_commonOut_transEntry_bits_payload_vecWen(g_io_commonOut_transEntry_bits_payload_vecWen),
    .io_commonOut_transEntry_bits_payload_v0Wen(g_io_commonOut_transEntry_bits_payload_v0Wen),
    .io_commonOut_transEntry_bits_payload_vlWen(g_io_commonOut_transEntry_bits_payload_vlWen),
    .io_commonOut_transEntry_bits_payload_isXSTrap(g_io_commonOut_transEntry_bits_payload_isXSTrap),
    .io_commonOut_transEntry_bits_payload_waitForward(g_io_commonOut_transEntry_bits_payload_waitForward),
    .io_commonOut_transEntry_bits_payload_blockBackward(g_io_commonOut_transEntry_bits_payload_blockBackward),
    .io_commonOut_transEntry_bits_payload_flushPipe(g_io_commonOut_transEntry_bits_payload_flushPipe),
    .io_commonOut_transEntry_bits_payload_canRobCompress(g_io_commonOut_transEntry_bits_payload_canRobCompress),
    .io_commonOut_transEntry_bits_payload_selImm(g_io_commonOut_transEntry_bits_payload_selImm),
    .io_commonOut_transEntry_bits_payload_imm(g_io_commonOut_transEntry_bits_payload_imm),
    .io_commonOut_transEntry_bits_payload_fpu_typeTagOut(g_io_commonOut_transEntry_bits_payload_fpu_typeTagOut),
    .io_commonOut_transEntry_bits_payload_fpu_wflags(g_io_commonOut_transEntry_bits_payload_fpu_wflags),
    .io_commonOut_transEntry_bits_payload_fpu_typ(g_io_commonOut_transEntry_bits_payload_fpu_typ),
    .io_commonOut_transEntry_bits_payload_fpu_fmt(g_io_commonOut_transEntry_bits_payload_fpu_fmt),
    .io_commonOut_transEntry_bits_payload_fpu_rm(g_io_commonOut_transEntry_bits_payload_fpu_rm),
    .io_commonOut_transEntry_bits_payload_vpu_vill(g_io_commonOut_transEntry_bits_payload_vpu_vill),
    .io_commonOut_transEntry_bits_payload_vpu_vma(g_io_commonOut_transEntry_bits_payload_vpu_vma),
    .io_commonOut_transEntry_bits_payload_vpu_vta(g_io_commonOut_transEntry_bits_payload_vpu_vta),
    .io_commonOut_transEntry_bits_payload_vpu_vsew(g_io_commonOut_transEntry_bits_payload_vpu_vsew),
    .io_commonOut_transEntry_bits_payload_vpu_vlmul(g_io_commonOut_transEntry_bits_payload_vpu_vlmul),
    .io_commonOut_transEntry_bits_payload_vpu_specVill(g_io_commonOut_transEntry_bits_payload_vpu_specVill),
    .io_commonOut_transEntry_bits_payload_vpu_specVma(g_io_commonOut_transEntry_bits_payload_vpu_specVma),
    .io_commonOut_transEntry_bits_payload_vpu_specVta(g_io_commonOut_transEntry_bits_payload_vpu_specVta),
    .io_commonOut_transEntry_bits_payload_vpu_specVsew(g_io_commonOut_transEntry_bits_payload_vpu_specVsew),
    .io_commonOut_transEntry_bits_payload_vpu_specVlmul(g_io_commonOut_transEntry_bits_payload_vpu_specVlmul),
    .io_commonOut_transEntry_bits_payload_vpu_vm(g_io_commonOut_transEntry_bits_payload_vpu_vm),
    .io_commonOut_transEntry_bits_payload_vpu_vstart(g_io_commonOut_transEntry_bits_payload_vpu_vstart),
    .io_commonOut_transEntry_bits_payload_vpu_frm(g_io_commonOut_transEntry_bits_payload_vpu_frm),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8(g_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonOut_transEntry_bits_payload_vpu_vxrm(g_io_commonOut_transEntry_bits_payload_vpu_vxrm),
    .io_commonOut_transEntry_bits_payload_vpu_vuopIdx(g_io_commonOut_transEntry_bits_payload_vpu_vuopIdx),
    .io_commonOut_transEntry_bits_payload_vpu_lastUop(g_io_commonOut_transEntry_bits_payload_vpu_lastUop),
    .io_commonOut_transEntry_bits_payload_vpu_vmask(g_io_commonOut_transEntry_bits_payload_vpu_vmask),
    .io_commonOut_transEntry_bits_payload_vpu_vl(g_io_commonOut_transEntry_bits_payload_vpu_vl),
    .io_commonOut_transEntry_bits_payload_vpu_nf(g_io_commonOut_transEntry_bits_payload_vpu_nf),
    .io_commonOut_transEntry_bits_payload_vpu_veew(g_io_commonOut_transEntry_bits_payload_vpu_veew),
    .io_commonOut_transEntry_bits_payload_vpu_isReverse(g_io_commonOut_transEntry_bits_payload_vpu_isReverse),
    .io_commonOut_transEntry_bits_payload_vpu_isExt(g_io_commonOut_transEntry_bits_payload_vpu_isExt),
    .io_commonOut_transEntry_bits_payload_vpu_isNarrow(g_io_commonOut_transEntry_bits_payload_vpu_isNarrow),
    .io_commonOut_transEntry_bits_payload_vpu_isDstMask(g_io_commonOut_transEntry_bits_payload_vpu_isDstMask),
    .io_commonOut_transEntry_bits_payload_vpu_isOpMask(g_io_commonOut_transEntry_bits_payload_vpu_isOpMask),
    .io_commonOut_transEntry_bits_payload_vpu_isMove(g_io_commonOut_transEntry_bits_payload_vpu_isMove),
    .io_commonOut_transEntry_bits_payload_vpu_isDependOldVd(g_io_commonOut_transEntry_bits_payload_vpu_isDependOldVd),
    .io_commonOut_transEntry_bits_payload_vpu_isWritePartVd(g_io_commonOut_transEntry_bits_payload_vpu_isWritePartVd),
    .io_commonOut_transEntry_bits_payload_vpu_isVleff(g_io_commonOut_transEntry_bits_payload_vpu_isVleff),
    .io_commonOut_transEntry_bits_payload_vlsInstr(g_io_commonOut_transEntry_bits_payload_vlsInstr),
    .io_commonOut_transEntry_bits_payload_wfflags(g_io_commonOut_transEntry_bits_payload_wfflags),
    .io_commonOut_transEntry_bits_payload_isMove(g_io_commonOut_transEntry_bits_payload_isMove),
    .io_commonOut_transEntry_bits_payload_isDropAmocasSta(g_io_commonOut_transEntry_bits_payload_isDropAmocasSta),
    .io_commonOut_transEntry_bits_payload_uopIdx(g_io_commonOut_transEntry_bits_payload_uopIdx),
    .io_commonOut_transEntry_bits_payload_isVset(g_io_commonOut_transEntry_bits_payload_isVset),
    .io_commonOut_transEntry_bits_payload_firstUop(g_io_commonOut_transEntry_bits_payload_firstUop),
    .io_commonOut_transEntry_bits_payload_lastUop(g_io_commonOut_transEntry_bits_payload_lastUop),
    .io_commonOut_transEntry_bits_payload_numUops(g_io_commonOut_transEntry_bits_payload_numUops),
    .io_commonOut_transEntry_bits_payload_numWB(g_io_commonOut_transEntry_bits_payload_numWB),
    .io_commonOut_transEntry_bits_payload_commitType(g_io_commonOut_transEntry_bits_payload_commitType),
    .io_commonOut_transEntry_bits_payload_srcState_0(g_io_commonOut_transEntry_bits_payload_srcState_0),
    .io_commonOut_transEntry_bits_payload_srcState_1(g_io_commonOut_transEntry_bits_payload_srcState_1),
    .io_commonOut_transEntry_bits_payload_srcState_2(g_io_commonOut_transEntry_bits_payload_srcState_2),
    .io_commonOut_transEntry_bits_payload_srcState_3(g_io_commonOut_transEntry_bits_payload_srcState_3),
    .io_commonOut_transEntry_bits_payload_srcState_4(g_io_commonOut_transEntry_bits_payload_srcState_4),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2(g_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2),
    .io_commonOut_transEntry_bits_payload_psrc_0(g_io_commonOut_transEntry_bits_payload_psrc_0),
    .io_commonOut_transEntry_bits_payload_psrc_1(g_io_commonOut_transEntry_bits_payload_psrc_1),
    .io_commonOut_transEntry_bits_payload_psrc_2(g_io_commonOut_transEntry_bits_payload_psrc_2),
    .io_commonOut_transEntry_bits_payload_psrc_3(g_io_commonOut_transEntry_bits_payload_psrc_3),
    .io_commonOut_transEntry_bits_payload_psrc_4(g_io_commonOut_transEntry_bits_payload_psrc_4),
    .io_commonOut_transEntry_bits_payload_pdest(g_io_commonOut_transEntry_bits_payload_pdest),
    .io_commonOut_transEntry_bits_payload_useRegCache_0(g_io_commonOut_transEntry_bits_payload_useRegCache_0),
    .io_commonOut_transEntry_bits_payload_useRegCache_1(g_io_commonOut_transEntry_bits_payload_useRegCache_1),
    .io_commonOut_transEntry_bits_payload_regCacheIdx_0(g_io_commonOut_transEntry_bits_payload_regCacheIdx_0),
    .io_commonOut_transEntry_bits_payload_regCacheIdx_1(g_io_commonOut_transEntry_bits_payload_regCacheIdx_1),
    .io_commonOut_transEntry_bits_payload_robIdx_flag(g_io_commonOut_transEntry_bits_payload_robIdx_flag),
    .io_commonOut_transEntry_bits_payload_robIdx_value(g_io_commonOut_transEntry_bits_payload_robIdx_value),
    .io_commonOut_transEntry_bits_payload_instrSize(g_io_commonOut_transEntry_bits_payload_instrSize),
    .io_commonOut_transEntry_bits_payload_dirtyFs(g_io_commonOut_transEntry_bits_payload_dirtyFs),
    .io_commonOut_transEntry_bits_payload_dirtyVs(g_io_commonOut_transEntry_bits_payload_dirtyVs),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype(g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire(g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize(g_io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize),
    .io_commonOut_transEntry_bits_payload_eliminatedMove(g_io_commonOut_transEntry_bits_payload_eliminatedMove),
    .io_commonOut_transEntry_bits_payload_snapshot(g_io_commonOut_transEntry_bits_payload_snapshot),
    .io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove(g_io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove),
    .io_commonOut_transEntry_bits_payload_debugInfo_renameTime(g_io_commonOut_transEntry_bits_payload_debugInfo_renameTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime(g_io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime(g_io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_selectTime(g_io_commonOut_transEntry_bits_payload_debugInfo_selectTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_issueTime(g_io_commonOut_transEntry_bits_payload_debugInfo_issueTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_writebackTime(g_io_commonOut_transEntry_bits_payload_debugInfo_writebackTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id(g_io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime(g_io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime(g_io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime),
    .io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum(g_io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum),
    .io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx(g_io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx),
    .io_commonOut_transEntry_bits_payload_storeSetHit(g_io_commonOut_transEntry_bits_payload_storeSetHit),
    .io_commonOut_transEntry_bits_payload_waitForRobIdx_flag(g_io_commonOut_transEntry_bits_payload_waitForRobIdx_flag),
    .io_commonOut_transEntry_bits_payload_waitForRobIdx_value(g_io_commonOut_transEntry_bits_payload_waitForRobIdx_value),
    .io_commonOut_transEntry_bits_payload_loadWaitBit(g_io_commonOut_transEntry_bits_payload_loadWaitBit),
    .io_commonOut_transEntry_bits_payload_loadWaitStrict(g_io_commonOut_transEntry_bits_payload_loadWaitStrict),
    .io_commonOut_transEntry_bits_payload_ssid(g_io_commonOut_transEntry_bits_payload_ssid),
    .io_commonOut_transEntry_bits_payload_lqIdx_flag(g_io_commonOut_transEntry_bits_payload_lqIdx_flag),
    .io_commonOut_transEntry_bits_payload_lqIdx_value(g_io_commonOut_transEntry_bits_payload_lqIdx_value),
    .io_commonOut_transEntry_bits_payload_sqIdx_flag(g_io_commonOut_transEntry_bits_payload_sqIdx_flag),
    .io_commonOut_transEntry_bits_payload_sqIdx_value(g_io_commonOut_transEntry_bits_payload_sqIdx_value),
    .io_commonOut_transEntry_bits_payload_singleStep(g_io_commonOut_transEntry_bits_payload_singleStep),
    .io_commonOut_transEntry_bits_payload_replayInst(g_io_commonOut_transEntry_bits_payload_replayInst),
    .io_commonOut_transEntry_bits_payload_debug_fuType(g_io_commonOut_transEntry_bits_payload_debug_fuType),
    .io_commonOut_transEntry_bits_payload_debug_sim_trig(g_io_commonOut_transEntry_bits_payload_debug_sim_trig),
    .io_commonOut_transEntry_bits_payload_numLsElem(g_io_commonOut_transEntry_bits_payload_numLsElem),
    .io_commonOut_entryInValid(g_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(g_io_commonOut_entryOutDeqValid),
    .io_commonOut_entryOutTransValid(g_io_commonOut_entryOutTransValid),
    .io_commonOut_perfLdCancel_0(g_io_commonOut_perfLdCancel_0),
    .io_commonOut_perfOg0Cancel_0(g_io_commonOut_perfOg0Cancel_0),
    .io_commonOut_perfWakeupByWB_0(g_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByIQ_0_0(g_io_commonOut_perfWakeupByIQ_0_0),
    .io_commonOut_perfWakeupByIQ_0_1(g_io_commonOut_perfWakeupByIQ_0_1),
    .io_commonOut_perfWakeupByIQ_0_2(g_io_commonOut_perfWakeupByIQ_0_2),
    .io_commonOut_perfWakeupByIQ_0_3(g_io_commonOut_perfWakeupByIQ_0_3),
    .io_commonOut_perfWakeupByIQ_0_4(g_io_commonOut_perfWakeupByIQ_0_4),
    .io_commonOut_perfWakeupByIQ_0_5(g_io_commonOut_perfWakeupByIQ_0_5),
    .io_commonOut_perfWakeupByIQ_0_6(g_io_commonOut_perfWakeupByIQ_0_6)
  );

  OthersEntry_200_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_15(io_commonIn_enq_bits_status_fuType_15),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2(io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonIn_enq_bits_status_srcStatus_0_exuSources_value(io_commonIn_enq_bits_status_srcStatus_0_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_useRegCache(io_commonIn_enq_bits_status_srcStatus_0_useRegCache),
    .io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx(io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx),
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_imm(io_commonIn_enq_bits_imm),
    .io_commonIn_enq_bits_payload_instr(io_commonIn_enq_bits_payload_instr),
    .io_commonIn_enq_bits_payload_pc(io_commonIn_enq_bits_payload_pc),
    .io_commonIn_enq_bits_payload_foldpc(io_commonIn_enq_bits_payload_foldpc),
    .io_commonIn_enq_bits_payload_exceptionVec_0(io_commonIn_enq_bits_payload_exceptionVec_0),
    .io_commonIn_enq_bits_payload_exceptionVec_1(io_commonIn_enq_bits_payload_exceptionVec_1),
    .io_commonIn_enq_bits_payload_exceptionVec_2(io_commonIn_enq_bits_payload_exceptionVec_2),
    .io_commonIn_enq_bits_payload_exceptionVec_3(io_commonIn_enq_bits_payload_exceptionVec_3),
    .io_commonIn_enq_bits_payload_exceptionVec_4(io_commonIn_enq_bits_payload_exceptionVec_4),
    .io_commonIn_enq_bits_payload_exceptionVec_5(io_commonIn_enq_bits_payload_exceptionVec_5),
    .io_commonIn_enq_bits_payload_exceptionVec_6(io_commonIn_enq_bits_payload_exceptionVec_6),
    .io_commonIn_enq_bits_payload_exceptionVec_7(io_commonIn_enq_bits_payload_exceptionVec_7),
    .io_commonIn_enq_bits_payload_exceptionVec_8(io_commonIn_enq_bits_payload_exceptionVec_8),
    .io_commonIn_enq_bits_payload_exceptionVec_9(io_commonIn_enq_bits_payload_exceptionVec_9),
    .io_commonIn_enq_bits_payload_exceptionVec_10(io_commonIn_enq_bits_payload_exceptionVec_10),
    .io_commonIn_enq_bits_payload_exceptionVec_11(io_commonIn_enq_bits_payload_exceptionVec_11),
    .io_commonIn_enq_bits_payload_exceptionVec_12(io_commonIn_enq_bits_payload_exceptionVec_12),
    .io_commonIn_enq_bits_payload_exceptionVec_13(io_commonIn_enq_bits_payload_exceptionVec_13),
    .io_commonIn_enq_bits_payload_exceptionVec_14(io_commonIn_enq_bits_payload_exceptionVec_14),
    .io_commonIn_enq_bits_payload_exceptionVec_15(io_commonIn_enq_bits_payload_exceptionVec_15),
    .io_commonIn_enq_bits_payload_exceptionVec_16(io_commonIn_enq_bits_payload_exceptionVec_16),
    .io_commonIn_enq_bits_payload_exceptionVec_17(io_commonIn_enq_bits_payload_exceptionVec_17),
    .io_commonIn_enq_bits_payload_exceptionVec_18(io_commonIn_enq_bits_payload_exceptionVec_18),
    .io_commonIn_enq_bits_payload_exceptionVec_19(io_commonIn_enq_bits_payload_exceptionVec_19),
    .io_commonIn_enq_bits_payload_exceptionVec_20(io_commonIn_enq_bits_payload_exceptionVec_20),
    .io_commonIn_enq_bits_payload_exceptionVec_21(io_commonIn_enq_bits_payload_exceptionVec_21),
    .io_commonIn_enq_bits_payload_exceptionVec_22(io_commonIn_enq_bits_payload_exceptionVec_22),
    .io_commonIn_enq_bits_payload_exceptionVec_23(io_commonIn_enq_bits_payload_exceptionVec_23),
    .io_commonIn_enq_bits_payload_isFetchMalAddr(io_commonIn_enq_bits_payload_isFetchMalAddr),
    .io_commonIn_enq_bits_payload_hasException(io_commonIn_enq_bits_payload_hasException),
    .io_commonIn_enq_bits_payload_trigger(io_commonIn_enq_bits_payload_trigger),
    .io_commonIn_enq_bits_payload_preDecodeInfo_valid(io_commonIn_enq_bits_payload_preDecodeInfo_valid),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isRVC(io_commonIn_enq_bits_payload_preDecodeInfo_isRVC),
    .io_commonIn_enq_bits_payload_preDecodeInfo_brType(io_commonIn_enq_bits_payload_preDecodeInfo_brType),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isCall(io_commonIn_enq_bits_payload_preDecodeInfo_isCall),
    .io_commonIn_enq_bits_payload_preDecodeInfo_isRet(io_commonIn_enq_bits_payload_preDecodeInfo_isRet),
    .io_commonIn_enq_bits_payload_pred_taken(io_commonIn_enq_bits_payload_pred_taken),
    .io_commonIn_enq_bits_payload_crossPageIPFFix(io_commonIn_enq_bits_payload_crossPageIPFFix),
    .io_commonIn_enq_bits_payload_ftqPtr_flag(io_commonIn_enq_bits_payload_ftqPtr_flag),
    .io_commonIn_enq_bits_payload_ftqPtr_value(io_commonIn_enq_bits_payload_ftqPtr_value),
    .io_commonIn_enq_bits_payload_ftqOffset(io_commonIn_enq_bits_payload_ftqOffset),
    .io_commonIn_enq_bits_payload_satpFlushFirstFetchFault(io_commonIn_enq_bits_payload_satpFlushFirstFetchFault),
    .io_commonIn_enq_bits_payload_srcType_0(io_commonIn_enq_bits_payload_srcType_0),
    .io_commonIn_enq_bits_payload_srcType_1(io_commonIn_enq_bits_payload_srcType_1),
    .io_commonIn_enq_bits_payload_srcType_2(io_commonIn_enq_bits_payload_srcType_2),
    .io_commonIn_enq_bits_payload_srcType_3(io_commonIn_enq_bits_payload_srcType_3),
    .io_commonIn_enq_bits_payload_srcType_4(io_commonIn_enq_bits_payload_srcType_4),
    .io_commonIn_enq_bits_payload_ldest(io_commonIn_enq_bits_payload_ldest),
    .io_commonIn_enq_bits_payload_fuType(io_commonIn_enq_bits_payload_fuType),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_rfWen(io_commonIn_enq_bits_payload_rfWen),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_vecWen(io_commonIn_enq_bits_payload_vecWen),
    .io_commonIn_enq_bits_payload_v0Wen(io_commonIn_enq_bits_payload_v0Wen),
    .io_commonIn_enq_bits_payload_vlWen(io_commonIn_enq_bits_payload_vlWen),
    .io_commonIn_enq_bits_payload_isXSTrap(io_commonIn_enq_bits_payload_isXSTrap),
    .io_commonIn_enq_bits_payload_waitForward(io_commonIn_enq_bits_payload_waitForward),
    .io_commonIn_enq_bits_payload_blockBackward(io_commonIn_enq_bits_payload_blockBackward),
    .io_commonIn_enq_bits_payload_flushPipe(io_commonIn_enq_bits_payload_flushPipe),
    .io_commonIn_enq_bits_payload_canRobCompress(io_commonIn_enq_bits_payload_canRobCompress),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
    .io_commonIn_enq_bits_payload_imm(io_commonIn_enq_bits_payload_imm),
    .io_commonIn_enq_bits_payload_fpu_typeTagOut(io_commonIn_enq_bits_payload_fpu_typeTagOut),
    .io_commonIn_enq_bits_payload_fpu_wflags(io_commonIn_enq_bits_payload_fpu_wflags),
    .io_commonIn_enq_bits_payload_fpu_typ(io_commonIn_enq_bits_payload_fpu_typ),
    .io_commonIn_enq_bits_payload_fpu_fmt(io_commonIn_enq_bits_payload_fpu_fmt),
    .io_commonIn_enq_bits_payload_fpu_rm(io_commonIn_enq_bits_payload_fpu_rm),
    .io_commonIn_enq_bits_payload_vpu_vill(io_commonIn_enq_bits_payload_vpu_vill),
    .io_commonIn_enq_bits_payload_vpu_vma(io_commonIn_enq_bits_payload_vpu_vma),
    .io_commonIn_enq_bits_payload_vpu_vta(io_commonIn_enq_bits_payload_vpu_vta),
    .io_commonIn_enq_bits_payload_vpu_vsew(io_commonIn_enq_bits_payload_vpu_vsew),
    .io_commonIn_enq_bits_payload_vpu_vlmul(io_commonIn_enq_bits_payload_vpu_vlmul),
    .io_commonIn_enq_bits_payload_vpu_specVill(io_commonIn_enq_bits_payload_vpu_specVill),
    .io_commonIn_enq_bits_payload_vpu_specVma(io_commonIn_enq_bits_payload_vpu_specVma),
    .io_commonIn_enq_bits_payload_vpu_specVta(io_commonIn_enq_bits_payload_vpu_specVta),
    .io_commonIn_enq_bits_payload_vpu_specVsew(io_commonIn_enq_bits_payload_vpu_specVsew),
    .io_commonIn_enq_bits_payload_vpu_specVlmul(io_commonIn_enq_bits_payload_vpu_specVlmul),
    .io_commonIn_enq_bits_payload_vpu_vm(io_commonIn_enq_bits_payload_vpu_vm),
    .io_commonIn_enq_bits_payload_vpu_vstart(io_commonIn_enq_bits_payload_vpu_vstart),
    .io_commonIn_enq_bits_payload_vpu_frm(io_commonIn_enq_bits_payload_vpu_frm),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst(io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr(io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr(io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonIn_enq_bits_payload_vpu_fpu_isReduction(io_commonIn_enq_bits_payload_vpu_fpu_isReduction),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8(io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonIn_enq_bits_payload_vpu_vxrm(io_commonIn_enq_bits_payload_vpu_vxrm),
    .io_commonIn_enq_bits_payload_vpu_vuopIdx(io_commonIn_enq_bits_payload_vpu_vuopIdx),
    .io_commonIn_enq_bits_payload_vpu_lastUop(io_commonIn_enq_bits_payload_vpu_lastUop),
    .io_commonIn_enq_bits_payload_vpu_vmask(io_commonIn_enq_bits_payload_vpu_vmask),
    .io_commonIn_enq_bits_payload_vpu_vl(io_commonIn_enq_bits_payload_vpu_vl),
    .io_commonIn_enq_bits_payload_vpu_nf(io_commonIn_enq_bits_payload_vpu_nf),
    .io_commonIn_enq_bits_payload_vpu_veew(io_commonIn_enq_bits_payload_vpu_veew),
    .io_commonIn_enq_bits_payload_vpu_isReverse(io_commonIn_enq_bits_payload_vpu_isReverse),
    .io_commonIn_enq_bits_payload_vpu_isExt(io_commonIn_enq_bits_payload_vpu_isExt),
    .io_commonIn_enq_bits_payload_vpu_isNarrow(io_commonIn_enq_bits_payload_vpu_isNarrow),
    .io_commonIn_enq_bits_payload_vpu_isDstMask(io_commonIn_enq_bits_payload_vpu_isDstMask),
    .io_commonIn_enq_bits_payload_vpu_isOpMask(io_commonIn_enq_bits_payload_vpu_isOpMask),
    .io_commonIn_enq_bits_payload_vpu_isMove(io_commonIn_enq_bits_payload_vpu_isMove),
    .io_commonIn_enq_bits_payload_vpu_isDependOldVd(io_commonIn_enq_bits_payload_vpu_isDependOldVd),
    .io_commonIn_enq_bits_payload_vpu_isWritePartVd(io_commonIn_enq_bits_payload_vpu_isWritePartVd),
    .io_commonIn_enq_bits_payload_vpu_isVleff(io_commonIn_enq_bits_payload_vpu_isVleff),
    .io_commonIn_enq_bits_payload_vlsInstr(io_commonIn_enq_bits_payload_vlsInstr),
    .io_commonIn_enq_bits_payload_wfflags(io_commonIn_enq_bits_payload_wfflags),
    .io_commonIn_enq_bits_payload_isMove(io_commonIn_enq_bits_payload_isMove),
    .io_commonIn_enq_bits_payload_isDropAmocasSta(io_commonIn_enq_bits_payload_isDropAmocasSta),
    .io_commonIn_enq_bits_payload_uopIdx(io_commonIn_enq_bits_payload_uopIdx),
    .io_commonIn_enq_bits_payload_isVset(io_commonIn_enq_bits_payload_isVset),
    .io_commonIn_enq_bits_payload_firstUop(io_commonIn_enq_bits_payload_firstUop),
    .io_commonIn_enq_bits_payload_lastUop(io_commonIn_enq_bits_payload_lastUop),
    .io_commonIn_enq_bits_payload_numUops(io_commonIn_enq_bits_payload_numUops),
    .io_commonIn_enq_bits_payload_numWB(io_commonIn_enq_bits_payload_numWB),
    .io_commonIn_enq_bits_payload_commitType(io_commonIn_enq_bits_payload_commitType),
    .io_commonIn_enq_bits_payload_srcState_0(io_commonIn_enq_bits_payload_srcState_0),
    .io_commonIn_enq_bits_payload_srcState_1(io_commonIn_enq_bits_payload_srcState_1),
    .io_commonIn_enq_bits_payload_srcState_2(io_commonIn_enq_bits_payload_srcState_2),
    .io_commonIn_enq_bits_payload_srcState_3(io_commonIn_enq_bits_payload_srcState_3),
    .io_commonIn_enq_bits_payload_srcState_4(io_commonIn_enq_bits_payload_srcState_4),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_0(io_commonIn_enq_bits_payload_srcLoadDependency_0_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_1(io_commonIn_enq_bits_payload_srcLoadDependency_0_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_0_2(io_commonIn_enq_bits_payload_srcLoadDependency_0_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_0(io_commonIn_enq_bits_payload_srcLoadDependency_1_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_1(io_commonIn_enq_bits_payload_srcLoadDependency_1_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_1_2(io_commonIn_enq_bits_payload_srcLoadDependency_1_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_0(io_commonIn_enq_bits_payload_srcLoadDependency_2_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_1(io_commonIn_enq_bits_payload_srcLoadDependency_2_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_2_2(io_commonIn_enq_bits_payload_srcLoadDependency_2_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_0(io_commonIn_enq_bits_payload_srcLoadDependency_3_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_1(io_commonIn_enq_bits_payload_srcLoadDependency_3_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_3_2(io_commonIn_enq_bits_payload_srcLoadDependency_3_2),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_0(io_commonIn_enq_bits_payload_srcLoadDependency_4_0),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_1(io_commonIn_enq_bits_payload_srcLoadDependency_4_1),
    .io_commonIn_enq_bits_payload_srcLoadDependency_4_2(io_commonIn_enq_bits_payload_srcLoadDependency_4_2),
    .io_commonIn_enq_bits_payload_psrc_0(io_commonIn_enq_bits_payload_psrc_0),
    .io_commonIn_enq_bits_payload_psrc_1(io_commonIn_enq_bits_payload_psrc_1),
    .io_commonIn_enq_bits_payload_psrc_2(io_commonIn_enq_bits_payload_psrc_2),
    .io_commonIn_enq_bits_payload_psrc_3(io_commonIn_enq_bits_payload_psrc_3),
    .io_commonIn_enq_bits_payload_psrc_4(io_commonIn_enq_bits_payload_psrc_4),
    .io_commonIn_enq_bits_payload_pdest(io_commonIn_enq_bits_payload_pdest),
    .io_commonIn_enq_bits_payload_useRegCache_0(io_commonIn_enq_bits_payload_useRegCache_0),
    .io_commonIn_enq_bits_payload_useRegCache_1(io_commonIn_enq_bits_payload_useRegCache_1),
    .io_commonIn_enq_bits_payload_regCacheIdx_0(io_commonIn_enq_bits_payload_regCacheIdx_0),
    .io_commonIn_enq_bits_payload_regCacheIdx_1(io_commonIn_enq_bits_payload_regCacheIdx_1),
    .io_commonIn_enq_bits_payload_robIdx_flag(io_commonIn_enq_bits_payload_robIdx_flag),
    .io_commonIn_enq_bits_payload_robIdx_value(io_commonIn_enq_bits_payload_robIdx_value),
    .io_commonIn_enq_bits_payload_instrSize(io_commonIn_enq_bits_payload_instrSize),
    .io_commonIn_enq_bits_payload_dirtyFs(io_commonIn_enq_bits_payload_dirtyFs),
    .io_commonIn_enq_bits_payload_dirtyVs(io_commonIn_enq_bits_payload_dirtyVs),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_itype(io_commonIn_enq_bits_payload_traceBlockInPipe_itype),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_iretire(io_commonIn_enq_bits_payload_traceBlockInPipe_iretire),
    .io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize(io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize),
    .io_commonIn_enq_bits_payload_eliminatedMove(io_commonIn_enq_bits_payload_eliminatedMove),
    .io_commonIn_enq_bits_payload_snapshot(io_commonIn_enq_bits_payload_snapshot),
    .io_commonIn_enq_bits_payload_debugInfo_eliminatedMove(io_commonIn_enq_bits_payload_debugInfo_eliminatedMove),
    .io_commonIn_enq_bits_payload_debugInfo_renameTime(io_commonIn_enq_bits_payload_debugInfo_renameTime),
    .io_commonIn_enq_bits_payload_debugInfo_dispatchTime(io_commonIn_enq_bits_payload_debugInfo_dispatchTime),
    .io_commonIn_enq_bits_payload_debugInfo_enqRsTime(io_commonIn_enq_bits_payload_debugInfo_enqRsTime),
    .io_commonIn_enq_bits_payload_debugInfo_selectTime(io_commonIn_enq_bits_payload_debugInfo_selectTime),
    .io_commonIn_enq_bits_payload_debugInfo_issueTime(io_commonIn_enq_bits_payload_debugInfo_issueTime),
    .io_commonIn_enq_bits_payload_debugInfo_writebackTime(io_commonIn_enq_bits_payload_debugInfo_writebackTime),
    .io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id(io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime(io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonIn_enq_bits_payload_debugInfo_tlbRespTime(io_commonIn_enq_bits_payload_debugInfo_tlbRespTime),
    .io_commonIn_enq_bits_payload_debug_seqNum_seqNum(io_commonIn_enq_bits_payload_debug_seqNum_seqNum),
    .io_commonIn_enq_bits_payload_debug_seqNum_uopIdx(io_commonIn_enq_bits_payload_debug_seqNum_uopIdx),
    .io_commonIn_enq_bits_payload_storeSetHit(io_commonIn_enq_bits_payload_storeSetHit),
    .io_commonIn_enq_bits_payload_waitForRobIdx_flag(io_commonIn_enq_bits_payload_waitForRobIdx_flag),
    .io_commonIn_enq_bits_payload_waitForRobIdx_value(io_commonIn_enq_bits_payload_waitForRobIdx_value),
    .io_commonIn_enq_bits_payload_loadWaitBit(io_commonIn_enq_bits_payload_loadWaitBit),
    .io_commonIn_enq_bits_payload_loadWaitStrict(io_commonIn_enq_bits_payload_loadWaitStrict),
    .io_commonIn_enq_bits_payload_ssid(io_commonIn_enq_bits_payload_ssid),
    .io_commonIn_enq_bits_payload_lqIdx_flag(io_commonIn_enq_bits_payload_lqIdx_flag),
    .io_commonIn_enq_bits_payload_lqIdx_value(io_commonIn_enq_bits_payload_lqIdx_value),
    .io_commonIn_enq_bits_payload_sqIdx_flag(io_commonIn_enq_bits_payload_sqIdx_flag),
    .io_commonIn_enq_bits_payload_sqIdx_value(io_commonIn_enq_bits_payload_sqIdx_value),
    .io_commonIn_enq_bits_payload_singleStep(io_commonIn_enq_bits_payload_singleStep),
    .io_commonIn_enq_bits_payload_replayInst(io_commonIn_enq_bits_payload_replayInst),
    .io_commonIn_enq_bits_payload_debug_fuType(io_commonIn_enq_bits_payload_debug_fuType),
    .io_commonIn_enq_bits_payload_debug_sim_trig(io_commonIn_enq_bits_payload_debug_sim_trig),
    .io_commonIn_enq_bits_payload_numLsElem(io_commonIn_enq_bits_payload_numLsElem),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_rfWen(io_commonIn_wakeUpFromWB_3_bits_rfWen),
    .io_commonIn_wakeUpFromWB_3_bits_fpWen(io_commonIn_wakeUpFromWB_3_bits_fpWen),
    .io_commonIn_wakeUpFromWB_3_bits_vecWen(io_commonIn_wakeUpFromWB_3_bits_vecWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_rfWen(io_commonIn_wakeUpFromWB_2_bits_rfWen),
    .io_commonIn_wakeUpFromWB_2_bits_fpWen(io_commonIn_wakeUpFromWB_2_bits_fpWen),
    .io_commonIn_wakeUpFromWB_2_bits_vecWen(io_commonIn_wakeUpFromWB_2_bits_vecWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_rfWen(io_commonIn_wakeUpFromWB_1_bits_rfWen),
    .io_commonIn_wakeUpFromWB_1_bits_fpWen(io_commonIn_wakeUpFromWB_1_bits_fpWen),
    .io_commonIn_wakeUpFromWB_1_bits_vecWen(io_commonIn_wakeUpFromWB_1_bits_vecWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_rfWen(io_commonIn_wakeUpFromWB_0_bits_rfWen),
    .io_commonIn_wakeUpFromWB_0_bits_fpWen(io_commonIn_wakeUpFromWB_0_bits_fpWen),
    .io_commonIn_wakeUpFromWB_0_bits_vecWen(io_commonIn_wakeUpFromWB_0_bits_vecWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_6_bits_rfWen(io_commonIn_wakeUpFromIQ_6_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_6_bits_pdest(io_commonIn_wakeUpFromIQ_6_bits_pdest),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_6_bits_is0Lat(io_commonIn_wakeUpFromIQ_6_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_6_bits_rcDest(io_commonIn_wakeUpFromIQ_6_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_5_bits_rfWen(io_commonIn_wakeUpFromIQ_5_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_5_bits_pdest(io_commonIn_wakeUpFromIQ_5_bits_pdest),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_5_bits_is0Lat(io_commonIn_wakeUpFromIQ_5_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_5_bits_rcDest(io_commonIn_wakeUpFromIQ_5_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_4_bits_rfWen(io_commonIn_wakeUpFromIQ_4_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_4_bits_pdest(io_commonIn_wakeUpFromIQ_4_bits_pdest),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_4_bits_is0Lat(io_commonIn_wakeUpFromIQ_4_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_4_bits_rcDest(io_commonIn_wakeUpFromIQ_4_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_3_bits_rfWen(io_commonIn_wakeUpFromIQ_3_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_3_bits_pdest(io_commonIn_wakeUpFromIQ_3_bits_pdest),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_3_bits_is0Lat(io_commonIn_wakeUpFromIQ_3_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_3_bits_rcDest(io_commonIn_wakeUpFromIQ_3_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_2_bits_rfWen(io_commonIn_wakeUpFromIQ_2_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_2_bits_pdest(io_commonIn_wakeUpFromIQ_2_bits_pdest),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_2_bits_is0Lat(io_commonIn_wakeUpFromIQ_2_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_2_bits_rcDest(io_commonIn_wakeUpFromIQ_2_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_1_bits_rfWen(io_commonIn_wakeUpFromIQ_1_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_1_bits_pdest(io_commonIn_wakeUpFromIQ_1_bits_pdest),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_1_bits_is0Lat(io_commonIn_wakeUpFromIQ_1_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_1_bits_rcDest(io_commonIn_wakeUpFromIQ_1_bits_rcDest),
    .io_commonIn_wakeUpFromIQ_0_bits_rfWen(io_commonIn_wakeUpFromIQ_0_bits_rfWen),
    .io_commonIn_wakeUpFromIQ_0_bits_pdest(io_commonIn_wakeUpFromIQ_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1),
    .io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2),
    .io_commonIn_wakeUpFromIQ_0_bits_is0Lat(io_commonIn_wakeUpFromIQ_0_bits_is0Lat),
    .io_commonIn_wakeUpFromIQ_0_bits_rcDest(io_commonIn_wakeUpFromIQ_0_bits_rcDest),
    .io_commonIn_og0Cancel_0(io_commonIn_og0Cancel_0),
    .io_commonIn_og0Cancel_2(io_commonIn_og0Cancel_2),
    .io_commonIn_og0Cancel_4(io_commonIn_og0Cancel_4),
    .io_commonIn_og0Cancel_6(io_commonIn_og0Cancel_6),
    .io_commonIn_og0Cancel_20(io_commonIn_og0Cancel_20),
    .io_commonIn_og0Cancel_21(io_commonIn_og0Cancel_21),
    .io_commonIn_og0Cancel_22(io_commonIn_og0Cancel_22),
    .io_commonIn_ldCancel_0_ld1Cancel(io_commonIn_ldCancel_0_ld1Cancel),
    .io_commonIn_ldCancel_0_ld2Cancel(io_commonIn_ldCancel_0_ld2Cancel),
    .io_commonIn_ldCancel_1_ld1Cancel(io_commonIn_ldCancel_1_ld1Cancel),
    .io_commonIn_ldCancel_1_ld2Cancel(io_commonIn_ldCancel_1_ld2Cancel),
    .io_commonIn_ldCancel_2_ld1Cancel(io_commonIn_ldCancel_2_ld1Cancel),
    .io_commonIn_ldCancel_2_ld2Cancel(io_commonIn_ldCancel_2_ld2Cancel),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonIn_transSel(io_commonIn_transSel),
    .io_commonOut_valid(i_io_commonOut_valid),
    .io_commonOut_issued(i_io_commonOut_issued),
    .io_commonOut_canIssue(i_io_commonOut_canIssue),
    .io_commonOut_fuType(i_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(i_io_commonOut_dataSources_0_value),
    .io_commonOut_exuSources_0_value(i_io_commonOut_exuSources_0_value),
    .io_commonOut_isFirstIssue(i_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(i_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(i_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_15(i_io_commonOut_entry_bits_status_fuType_15),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(i_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(i_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0(i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1(i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2(i_io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx(i_io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx),
    .io_commonOut_entry_bits_imm(i_io_commonOut_entry_bits_imm),
    .io_commonOut_entry_bits_payload_preDecodeInfo_valid(i_io_commonOut_entry_bits_payload_preDecodeInfo_valid),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isRVC(i_io_commonOut_entry_bits_payload_preDecodeInfo_isRVC),
    .io_commonOut_entry_bits_payload_preDecodeInfo_brType(i_io_commonOut_entry_bits_payload_preDecodeInfo_brType),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isCall(i_io_commonOut_entry_bits_payload_preDecodeInfo_isCall),
    .io_commonOut_entry_bits_payload_preDecodeInfo_isRet(i_io_commonOut_entry_bits_payload_preDecodeInfo_isRet),
    .io_commonOut_entry_bits_payload_ftqPtr_flag(i_io_commonOut_entry_bits_payload_ftqPtr_flag),
    .io_commonOut_entry_bits_payload_ftqPtr_value(i_io_commonOut_entry_bits_payload_ftqPtr_value),
    .io_commonOut_entry_bits_payload_ftqOffset(i_io_commonOut_entry_bits_payload_ftqOffset),
    .io_commonOut_entry_bits_payload_fuOpType(i_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(i_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(i_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_flushPipe(i_io_commonOut_entry_bits_payload_flushPipe),
    .io_commonOut_entry_bits_payload_selImm(i_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_pdest(i_io_commonOut_entry_bits_payload_pdest),
    .io_commonOut_entry_bits_payload_debugInfo_eliminatedMove(i_io_commonOut_entry_bits_payload_debugInfo_eliminatedMove),
    .io_commonOut_entry_bits_payload_debugInfo_renameTime(i_io_commonOut_entry_bits_payload_debugInfo_renameTime),
    .io_commonOut_entry_bits_payload_debugInfo_dispatchTime(i_io_commonOut_entry_bits_payload_debugInfo_dispatchTime),
    .io_commonOut_entry_bits_payload_debugInfo_enqRsTime(i_io_commonOut_entry_bits_payload_debugInfo_enqRsTime),
    .io_commonOut_entry_bits_payload_debugInfo_writebackTime(i_io_commonOut_entry_bits_payload_debugInfo_writebackTime),
    .io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id(i_io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime(i_io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonOut_entry_bits_payload_debugInfo_tlbRespTime(i_io_commonOut_entry_bits_payload_debugInfo_tlbRespTime),
    .io_commonOut_entry_bits_payload_debug_seqNum_seqNum(i_io_commonOut_entry_bits_payload_debug_seqNum_seqNum),
    .io_commonOut_entry_bits_payload_debug_seqNum_uopIdx(i_io_commonOut_entry_bits_payload_debug_seqNum_uopIdx),
    .io_commonOut_entry_bits_payload_storeSetHit(i_io_commonOut_entry_bits_payload_storeSetHit),
    .io_commonOut_entry_bits_payload_waitForRobIdx_flag(i_io_commonOut_entry_bits_payload_waitForRobIdx_flag),
    .io_commonOut_entry_bits_payload_waitForRobIdx_value(i_io_commonOut_entry_bits_payload_waitForRobIdx_value),
    .io_commonOut_entry_bits_payload_loadWaitBit(i_io_commonOut_entry_bits_payload_loadWaitBit),
    .io_commonOut_entry_bits_payload_loadWaitStrict(i_io_commonOut_entry_bits_payload_loadWaitStrict),
    .io_commonOut_entry_bits_payload_ssid(i_io_commonOut_entry_bits_payload_ssid),
    .io_commonOut_entry_bits_payload_lqIdx_flag(i_io_commonOut_entry_bits_payload_lqIdx_flag),
    .io_commonOut_entry_bits_payload_lqIdx_value(i_io_commonOut_entry_bits_payload_lqIdx_value),
    .io_commonOut_entry_bits_payload_sqIdx_flag(i_io_commonOut_entry_bits_payload_sqIdx_flag),
    .io_commonOut_entry_bits_payload_sqIdx_value(i_io_commonOut_entry_bits_payload_sqIdx_value),
    .io_commonOut_cancelBypass(i_io_commonOut_cancelBypass),
    .io_commonOut_issueTimerRead(i_io_commonOut_issueTimerRead),
    .io_commonOut_enqReady(i_io_commonOut_enqReady),
    .io_commonOut_transEntry_valid(i_io_commonOut_transEntry_valid),
    .io_commonOut_transEntry_bits_status_robIdx_flag(i_io_commonOut_transEntry_bits_status_robIdx_flag),
    .io_commonOut_transEntry_bits_status_robIdx_value(i_io_commonOut_transEntry_bits_status_robIdx_value),
    .io_commonOut_transEntry_bits_status_fuType_15(i_io_commonOut_transEntry_bits_status_fuType_15),
    .io_commonOut_transEntry_bits_status_srcStatus_0_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_0_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache(i_io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache),
    .io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx(i_io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx),
    .io_commonOut_transEntry_bits_status_issued(i_io_commonOut_transEntry_bits_status_issued),
    .io_commonOut_transEntry_bits_status_firstIssue(i_io_commonOut_transEntry_bits_status_firstIssue),
    .io_commonOut_transEntry_bits_status_issueTimer(i_io_commonOut_transEntry_bits_status_issueTimer),
    .io_commonOut_transEntry_bits_status_deqPortIdx(i_io_commonOut_transEntry_bits_status_deqPortIdx),
    .io_commonOut_transEntry_bits_imm(i_io_commonOut_transEntry_bits_imm),
    .io_commonOut_transEntry_bits_payload_instr(i_io_commonOut_transEntry_bits_payload_instr),
    .io_commonOut_transEntry_bits_payload_pc(i_io_commonOut_transEntry_bits_payload_pc),
    .io_commonOut_transEntry_bits_payload_foldpc(i_io_commonOut_transEntry_bits_payload_foldpc),
    .io_commonOut_transEntry_bits_payload_exceptionVec_0(i_io_commonOut_transEntry_bits_payload_exceptionVec_0),
    .io_commonOut_transEntry_bits_payload_exceptionVec_1(i_io_commonOut_transEntry_bits_payload_exceptionVec_1),
    .io_commonOut_transEntry_bits_payload_exceptionVec_2(i_io_commonOut_transEntry_bits_payload_exceptionVec_2),
    .io_commonOut_transEntry_bits_payload_exceptionVec_3(i_io_commonOut_transEntry_bits_payload_exceptionVec_3),
    .io_commonOut_transEntry_bits_payload_exceptionVec_4(i_io_commonOut_transEntry_bits_payload_exceptionVec_4),
    .io_commonOut_transEntry_bits_payload_exceptionVec_5(i_io_commonOut_transEntry_bits_payload_exceptionVec_5),
    .io_commonOut_transEntry_bits_payload_exceptionVec_6(i_io_commonOut_transEntry_bits_payload_exceptionVec_6),
    .io_commonOut_transEntry_bits_payload_exceptionVec_7(i_io_commonOut_transEntry_bits_payload_exceptionVec_7),
    .io_commonOut_transEntry_bits_payload_exceptionVec_8(i_io_commonOut_transEntry_bits_payload_exceptionVec_8),
    .io_commonOut_transEntry_bits_payload_exceptionVec_9(i_io_commonOut_transEntry_bits_payload_exceptionVec_9),
    .io_commonOut_transEntry_bits_payload_exceptionVec_10(i_io_commonOut_transEntry_bits_payload_exceptionVec_10),
    .io_commonOut_transEntry_bits_payload_exceptionVec_11(i_io_commonOut_transEntry_bits_payload_exceptionVec_11),
    .io_commonOut_transEntry_bits_payload_exceptionVec_12(i_io_commonOut_transEntry_bits_payload_exceptionVec_12),
    .io_commonOut_transEntry_bits_payload_exceptionVec_13(i_io_commonOut_transEntry_bits_payload_exceptionVec_13),
    .io_commonOut_transEntry_bits_payload_exceptionVec_14(i_io_commonOut_transEntry_bits_payload_exceptionVec_14),
    .io_commonOut_transEntry_bits_payload_exceptionVec_15(i_io_commonOut_transEntry_bits_payload_exceptionVec_15),
    .io_commonOut_transEntry_bits_payload_exceptionVec_16(i_io_commonOut_transEntry_bits_payload_exceptionVec_16),
    .io_commonOut_transEntry_bits_payload_exceptionVec_17(i_io_commonOut_transEntry_bits_payload_exceptionVec_17),
    .io_commonOut_transEntry_bits_payload_exceptionVec_18(i_io_commonOut_transEntry_bits_payload_exceptionVec_18),
    .io_commonOut_transEntry_bits_payload_exceptionVec_19(i_io_commonOut_transEntry_bits_payload_exceptionVec_19),
    .io_commonOut_transEntry_bits_payload_exceptionVec_20(i_io_commonOut_transEntry_bits_payload_exceptionVec_20),
    .io_commonOut_transEntry_bits_payload_exceptionVec_21(i_io_commonOut_transEntry_bits_payload_exceptionVec_21),
    .io_commonOut_transEntry_bits_payload_exceptionVec_22(i_io_commonOut_transEntry_bits_payload_exceptionVec_22),
    .io_commonOut_transEntry_bits_payload_exceptionVec_23(i_io_commonOut_transEntry_bits_payload_exceptionVec_23),
    .io_commonOut_transEntry_bits_payload_isFetchMalAddr(i_io_commonOut_transEntry_bits_payload_isFetchMalAddr),
    .io_commonOut_transEntry_bits_payload_hasException(i_io_commonOut_transEntry_bits_payload_hasException),
    .io_commonOut_transEntry_bits_payload_trigger(i_io_commonOut_transEntry_bits_payload_trigger),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_valid(i_io_commonOut_transEntry_bits_payload_preDecodeInfo_valid),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC(i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_brType(i_io_commonOut_transEntry_bits_payload_preDecodeInfo_brType),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall(i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall),
    .io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet(i_io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet),
    .io_commonOut_transEntry_bits_payload_pred_taken(i_io_commonOut_transEntry_bits_payload_pred_taken),
    .io_commonOut_transEntry_bits_payload_crossPageIPFFix(i_io_commonOut_transEntry_bits_payload_crossPageIPFFix),
    .io_commonOut_transEntry_bits_payload_ftqPtr_flag(i_io_commonOut_transEntry_bits_payload_ftqPtr_flag),
    .io_commonOut_transEntry_bits_payload_ftqPtr_value(i_io_commonOut_transEntry_bits_payload_ftqPtr_value),
    .io_commonOut_transEntry_bits_payload_ftqOffset(i_io_commonOut_transEntry_bits_payload_ftqOffset),
    .io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault(i_io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault),
    .io_commonOut_transEntry_bits_payload_srcType_0(i_io_commonOut_transEntry_bits_payload_srcType_0),
    .io_commonOut_transEntry_bits_payload_srcType_1(i_io_commonOut_transEntry_bits_payload_srcType_1),
    .io_commonOut_transEntry_bits_payload_srcType_2(i_io_commonOut_transEntry_bits_payload_srcType_2),
    .io_commonOut_transEntry_bits_payload_srcType_3(i_io_commonOut_transEntry_bits_payload_srcType_3),
    .io_commonOut_transEntry_bits_payload_srcType_4(i_io_commonOut_transEntry_bits_payload_srcType_4),
    .io_commonOut_transEntry_bits_payload_ldest(i_io_commonOut_transEntry_bits_payload_ldest),
    .io_commonOut_transEntry_bits_payload_fuType(i_io_commonOut_transEntry_bits_payload_fuType),
    .io_commonOut_transEntry_bits_payload_fuOpType(i_io_commonOut_transEntry_bits_payload_fuOpType),
    .io_commonOut_transEntry_bits_payload_rfWen(i_io_commonOut_transEntry_bits_payload_rfWen),
    .io_commonOut_transEntry_bits_payload_fpWen(i_io_commonOut_transEntry_bits_payload_fpWen),
    .io_commonOut_transEntry_bits_payload_vecWen(i_io_commonOut_transEntry_bits_payload_vecWen),
    .io_commonOut_transEntry_bits_payload_v0Wen(i_io_commonOut_transEntry_bits_payload_v0Wen),
    .io_commonOut_transEntry_bits_payload_vlWen(i_io_commonOut_transEntry_bits_payload_vlWen),
    .io_commonOut_transEntry_bits_payload_isXSTrap(i_io_commonOut_transEntry_bits_payload_isXSTrap),
    .io_commonOut_transEntry_bits_payload_waitForward(i_io_commonOut_transEntry_bits_payload_waitForward),
    .io_commonOut_transEntry_bits_payload_blockBackward(i_io_commonOut_transEntry_bits_payload_blockBackward),
    .io_commonOut_transEntry_bits_payload_flushPipe(i_io_commonOut_transEntry_bits_payload_flushPipe),
    .io_commonOut_transEntry_bits_payload_canRobCompress(i_io_commonOut_transEntry_bits_payload_canRobCompress),
    .io_commonOut_transEntry_bits_payload_selImm(i_io_commonOut_transEntry_bits_payload_selImm),
    .io_commonOut_transEntry_bits_payload_imm(i_io_commonOut_transEntry_bits_payload_imm),
    .io_commonOut_transEntry_bits_payload_fpu_typeTagOut(i_io_commonOut_transEntry_bits_payload_fpu_typeTagOut),
    .io_commonOut_transEntry_bits_payload_fpu_wflags(i_io_commonOut_transEntry_bits_payload_fpu_wflags),
    .io_commonOut_transEntry_bits_payload_fpu_typ(i_io_commonOut_transEntry_bits_payload_fpu_typ),
    .io_commonOut_transEntry_bits_payload_fpu_fmt(i_io_commonOut_transEntry_bits_payload_fpu_fmt),
    .io_commonOut_transEntry_bits_payload_fpu_rm(i_io_commonOut_transEntry_bits_payload_fpu_rm),
    .io_commonOut_transEntry_bits_payload_vpu_vill(i_io_commonOut_transEntry_bits_payload_vpu_vill),
    .io_commonOut_transEntry_bits_payload_vpu_vma(i_io_commonOut_transEntry_bits_payload_vpu_vma),
    .io_commonOut_transEntry_bits_payload_vpu_vta(i_io_commonOut_transEntry_bits_payload_vpu_vta),
    .io_commonOut_transEntry_bits_payload_vpu_vsew(i_io_commonOut_transEntry_bits_payload_vpu_vsew),
    .io_commonOut_transEntry_bits_payload_vpu_vlmul(i_io_commonOut_transEntry_bits_payload_vpu_vlmul),
    .io_commonOut_transEntry_bits_payload_vpu_specVill(i_io_commonOut_transEntry_bits_payload_vpu_specVill),
    .io_commonOut_transEntry_bits_payload_vpu_specVma(i_io_commonOut_transEntry_bits_payload_vpu_specVma),
    .io_commonOut_transEntry_bits_payload_vpu_specVta(i_io_commonOut_transEntry_bits_payload_vpu_specVta),
    .io_commonOut_transEntry_bits_payload_vpu_specVsew(i_io_commonOut_transEntry_bits_payload_vpu_specVsew),
    .io_commonOut_transEntry_bits_payload_vpu_specVlmul(i_io_commonOut_transEntry_bits_payload_vpu_specVlmul),
    .io_commonOut_transEntry_bits_payload_vpu_vm(i_io_commonOut_transEntry_bits_payload_vpu_vm),
    .io_commonOut_transEntry_bits_payload_vpu_vstart(i_io_commonOut_transEntry_bits_payload_vpu_vstart),
    .io_commonOut_transEntry_bits_payload_vpu_frm(i_io_commonOut_transEntry_bits_payload_vpu_frm),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8(i_io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonOut_transEntry_bits_payload_vpu_vxrm(i_io_commonOut_transEntry_bits_payload_vpu_vxrm),
    .io_commonOut_transEntry_bits_payload_vpu_vuopIdx(i_io_commonOut_transEntry_bits_payload_vpu_vuopIdx),
    .io_commonOut_transEntry_bits_payload_vpu_lastUop(i_io_commonOut_transEntry_bits_payload_vpu_lastUop),
    .io_commonOut_transEntry_bits_payload_vpu_vmask(i_io_commonOut_transEntry_bits_payload_vpu_vmask),
    .io_commonOut_transEntry_bits_payload_vpu_vl(i_io_commonOut_transEntry_bits_payload_vpu_vl),
    .io_commonOut_transEntry_bits_payload_vpu_nf(i_io_commonOut_transEntry_bits_payload_vpu_nf),
    .io_commonOut_transEntry_bits_payload_vpu_veew(i_io_commonOut_transEntry_bits_payload_vpu_veew),
    .io_commonOut_transEntry_bits_payload_vpu_isReverse(i_io_commonOut_transEntry_bits_payload_vpu_isReverse),
    .io_commonOut_transEntry_bits_payload_vpu_isExt(i_io_commonOut_transEntry_bits_payload_vpu_isExt),
    .io_commonOut_transEntry_bits_payload_vpu_isNarrow(i_io_commonOut_transEntry_bits_payload_vpu_isNarrow),
    .io_commonOut_transEntry_bits_payload_vpu_isDstMask(i_io_commonOut_transEntry_bits_payload_vpu_isDstMask),
    .io_commonOut_transEntry_bits_payload_vpu_isOpMask(i_io_commonOut_transEntry_bits_payload_vpu_isOpMask),
    .io_commonOut_transEntry_bits_payload_vpu_isMove(i_io_commonOut_transEntry_bits_payload_vpu_isMove),
    .io_commonOut_transEntry_bits_payload_vpu_isDependOldVd(i_io_commonOut_transEntry_bits_payload_vpu_isDependOldVd),
    .io_commonOut_transEntry_bits_payload_vpu_isWritePartVd(i_io_commonOut_transEntry_bits_payload_vpu_isWritePartVd),
    .io_commonOut_transEntry_bits_payload_vpu_isVleff(i_io_commonOut_transEntry_bits_payload_vpu_isVleff),
    .io_commonOut_transEntry_bits_payload_vlsInstr(i_io_commonOut_transEntry_bits_payload_vlsInstr),
    .io_commonOut_transEntry_bits_payload_wfflags(i_io_commonOut_transEntry_bits_payload_wfflags),
    .io_commonOut_transEntry_bits_payload_isMove(i_io_commonOut_transEntry_bits_payload_isMove),
    .io_commonOut_transEntry_bits_payload_isDropAmocasSta(i_io_commonOut_transEntry_bits_payload_isDropAmocasSta),
    .io_commonOut_transEntry_bits_payload_uopIdx(i_io_commonOut_transEntry_bits_payload_uopIdx),
    .io_commonOut_transEntry_bits_payload_isVset(i_io_commonOut_transEntry_bits_payload_isVset),
    .io_commonOut_transEntry_bits_payload_firstUop(i_io_commonOut_transEntry_bits_payload_firstUop),
    .io_commonOut_transEntry_bits_payload_lastUop(i_io_commonOut_transEntry_bits_payload_lastUop),
    .io_commonOut_transEntry_bits_payload_numUops(i_io_commonOut_transEntry_bits_payload_numUops),
    .io_commonOut_transEntry_bits_payload_numWB(i_io_commonOut_transEntry_bits_payload_numWB),
    .io_commonOut_transEntry_bits_payload_commitType(i_io_commonOut_transEntry_bits_payload_commitType),
    .io_commonOut_transEntry_bits_payload_srcState_0(i_io_commonOut_transEntry_bits_payload_srcState_0),
    .io_commonOut_transEntry_bits_payload_srcState_1(i_io_commonOut_transEntry_bits_payload_srcState_1),
    .io_commonOut_transEntry_bits_payload_srcState_2(i_io_commonOut_transEntry_bits_payload_srcState_2),
    .io_commonOut_transEntry_bits_payload_srcState_3(i_io_commonOut_transEntry_bits_payload_srcState_3),
    .io_commonOut_transEntry_bits_payload_srcState_4(i_io_commonOut_transEntry_bits_payload_srcState_4),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1),
    .io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2(i_io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2),
    .io_commonOut_transEntry_bits_payload_psrc_0(i_io_commonOut_transEntry_bits_payload_psrc_0),
    .io_commonOut_transEntry_bits_payload_psrc_1(i_io_commonOut_transEntry_bits_payload_psrc_1),
    .io_commonOut_transEntry_bits_payload_psrc_2(i_io_commonOut_transEntry_bits_payload_psrc_2),
    .io_commonOut_transEntry_bits_payload_psrc_3(i_io_commonOut_transEntry_bits_payload_psrc_3),
    .io_commonOut_transEntry_bits_payload_psrc_4(i_io_commonOut_transEntry_bits_payload_psrc_4),
    .io_commonOut_transEntry_bits_payload_pdest(i_io_commonOut_transEntry_bits_payload_pdest),
    .io_commonOut_transEntry_bits_payload_useRegCache_0(i_io_commonOut_transEntry_bits_payload_useRegCache_0),
    .io_commonOut_transEntry_bits_payload_useRegCache_1(i_io_commonOut_transEntry_bits_payload_useRegCache_1),
    .io_commonOut_transEntry_bits_payload_regCacheIdx_0(i_io_commonOut_transEntry_bits_payload_regCacheIdx_0),
    .io_commonOut_transEntry_bits_payload_regCacheIdx_1(i_io_commonOut_transEntry_bits_payload_regCacheIdx_1),
    .io_commonOut_transEntry_bits_payload_robIdx_flag(i_io_commonOut_transEntry_bits_payload_robIdx_flag),
    .io_commonOut_transEntry_bits_payload_robIdx_value(i_io_commonOut_transEntry_bits_payload_robIdx_value),
    .io_commonOut_transEntry_bits_payload_instrSize(i_io_commonOut_transEntry_bits_payload_instrSize),
    .io_commonOut_transEntry_bits_payload_dirtyFs(i_io_commonOut_transEntry_bits_payload_dirtyFs),
    .io_commonOut_transEntry_bits_payload_dirtyVs(i_io_commonOut_transEntry_bits_payload_dirtyVs),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype(i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire(i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire),
    .io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize(i_io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize),
    .io_commonOut_transEntry_bits_payload_eliminatedMove(i_io_commonOut_transEntry_bits_payload_eliminatedMove),
    .io_commonOut_transEntry_bits_payload_snapshot(i_io_commonOut_transEntry_bits_payload_snapshot),
    .io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove(i_io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove),
    .io_commonOut_transEntry_bits_payload_debugInfo_renameTime(i_io_commonOut_transEntry_bits_payload_debugInfo_renameTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime(i_io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime(i_io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_selectTime(i_io_commonOut_transEntry_bits_payload_debugInfo_selectTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_issueTime(i_io_commonOut_transEntry_bits_payload_debugInfo_issueTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_writebackTime(i_io_commonOut_transEntry_bits_payload_debugInfo_writebackTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id(i_io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime(i_io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime(i_io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime),
    .io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum(i_io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum),
    .io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx(i_io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx),
    .io_commonOut_transEntry_bits_payload_storeSetHit(i_io_commonOut_transEntry_bits_payload_storeSetHit),
    .io_commonOut_transEntry_bits_payload_waitForRobIdx_flag(i_io_commonOut_transEntry_bits_payload_waitForRobIdx_flag),
    .io_commonOut_transEntry_bits_payload_waitForRobIdx_value(i_io_commonOut_transEntry_bits_payload_waitForRobIdx_value),
    .io_commonOut_transEntry_bits_payload_loadWaitBit(i_io_commonOut_transEntry_bits_payload_loadWaitBit),
    .io_commonOut_transEntry_bits_payload_loadWaitStrict(i_io_commonOut_transEntry_bits_payload_loadWaitStrict),
    .io_commonOut_transEntry_bits_payload_ssid(i_io_commonOut_transEntry_bits_payload_ssid),
    .io_commonOut_transEntry_bits_payload_lqIdx_flag(i_io_commonOut_transEntry_bits_payload_lqIdx_flag),
    .io_commonOut_transEntry_bits_payload_lqIdx_value(i_io_commonOut_transEntry_bits_payload_lqIdx_value),
    .io_commonOut_transEntry_bits_payload_sqIdx_flag(i_io_commonOut_transEntry_bits_payload_sqIdx_flag),
    .io_commonOut_transEntry_bits_payload_sqIdx_value(i_io_commonOut_transEntry_bits_payload_sqIdx_value),
    .io_commonOut_transEntry_bits_payload_singleStep(i_io_commonOut_transEntry_bits_payload_singleStep),
    .io_commonOut_transEntry_bits_payload_replayInst(i_io_commonOut_transEntry_bits_payload_replayInst),
    .io_commonOut_transEntry_bits_payload_debug_fuType(i_io_commonOut_transEntry_bits_payload_debug_fuType),
    .io_commonOut_transEntry_bits_payload_debug_sim_trig(i_io_commonOut_transEntry_bits_payload_debug_sim_trig),
    .io_commonOut_transEntry_bits_payload_numLsElem(i_io_commonOut_transEntry_bits_payload_numLsElem),
    .io_commonOut_entryInValid(i_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(i_io_commonOut_entryOutDeqValid),
    .io_commonOut_entryOutTransValid(i_io_commonOut_entryOutTransValid),
    .io_commonOut_perfLdCancel_0(i_io_commonOut_perfLdCancel_0),
    .io_commonOut_perfOg0Cancel_0(i_io_commonOut_perfOg0Cancel_0),
    .io_commonOut_perfWakeupByWB_0(i_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByIQ_0_0(i_io_commonOut_perfWakeupByIQ_0_0),
    .io_commonOut_perfWakeupByIQ_0_1(i_io_commonOut_perfWakeupByIQ_0_1),
    .io_commonOut_perfWakeupByIQ_0_2(i_io_commonOut_perfWakeupByIQ_0_2),
    .io_commonOut_perfWakeupByIQ_0_3(i_io_commonOut_perfWakeupByIQ_0_3),
    .io_commonOut_perfWakeupByIQ_0_4(i_io_commonOut_perfWakeupByIQ_0_4),
    .io_commonOut_perfWakeupByIQ_0_5(i_io_commonOut_perfWakeupByIQ_0_5),
    .io_commonOut_perfWakeupByIQ_0_6(i_io_commonOut_perfWakeupByIQ_0_6)
  );

  task automatic check_outputs();
    `CHK(io_commonOut_valid)
    `CHK(io_commonOut_issued)
    `CHK(io_commonOut_canIssue)
    `CHK(io_commonOut_fuType)
    `CHK(io_commonOut_dataSources_0_value)
    `CHK(io_commonOut_exuSources_0_value)
    `CHK(io_commonOut_isFirstIssue)
    `CHK(io_commonOut_entry_bits_status_robIdx_flag)
    `CHK(io_commonOut_entry_bits_status_robIdx_value)
    `CHK(io_commonOut_entry_bits_status_fuType_15)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx)
    `CHK(io_commonOut_entry_bits_imm)
    `CHK(io_commonOut_entry_bits_payload_preDecodeInfo_valid)
    `CHK(io_commonOut_entry_bits_payload_preDecodeInfo_isRVC)
    `CHK(io_commonOut_entry_bits_payload_preDecodeInfo_brType)
    `CHK(io_commonOut_entry_bits_payload_preDecodeInfo_isCall)
    `CHK(io_commonOut_entry_bits_payload_preDecodeInfo_isRet)
    `CHK(io_commonOut_entry_bits_payload_ftqPtr_flag)
    `CHK(io_commonOut_entry_bits_payload_ftqPtr_value)
    `CHK(io_commonOut_entry_bits_payload_ftqOffset)
    `CHK(io_commonOut_entry_bits_payload_fuOpType)
    `CHK(io_commonOut_entry_bits_payload_rfWen)
    `CHK(io_commonOut_entry_bits_payload_fpWen)
    `CHK(io_commonOut_entry_bits_payload_flushPipe)
    `CHK(io_commonOut_entry_bits_payload_selImm)
    `CHK(io_commonOut_entry_bits_payload_pdest)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_eliminatedMove)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_renameTime)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_dispatchTime)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_enqRsTime)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_writebackTime)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime)
    `CHK(io_commonOut_entry_bits_payload_debugInfo_tlbRespTime)
    `CHK(io_commonOut_entry_bits_payload_debug_seqNum_seqNum)
    `CHK(io_commonOut_entry_bits_payload_debug_seqNum_uopIdx)
    `CHK(io_commonOut_entry_bits_payload_storeSetHit)
    `CHK(io_commonOut_entry_bits_payload_waitForRobIdx_flag)
    `CHK(io_commonOut_entry_bits_payload_waitForRobIdx_value)
    `CHK(io_commonOut_entry_bits_payload_loadWaitBit)
    `CHK(io_commonOut_entry_bits_payload_loadWaitStrict)
    `CHK(io_commonOut_entry_bits_payload_ssid)
    `CHK(io_commonOut_entry_bits_payload_lqIdx_flag)
    `CHK(io_commonOut_entry_bits_payload_lqIdx_value)
    `CHK(io_commonOut_entry_bits_payload_sqIdx_flag)
    `CHK(io_commonOut_entry_bits_payload_sqIdx_value)
    `CHK(io_commonOut_cancelBypass)
    `CHK(io_commonOut_issueTimerRead)
    `CHK(io_commonOut_enqReady)
    `CHK(io_commonOut_transEntry_valid)
    `CHK(io_commonOut_transEntry_bits_status_robIdx_flag)
    `CHK(io_commonOut_transEntry_bits_status_robIdx_value)
    `CHK(io_commonOut_transEntry_bits_status_fuType_15)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx)
    `CHK(io_commonOut_transEntry_bits_status_issued)
    `CHK(io_commonOut_transEntry_bits_status_firstIssue)
    `CHK(io_commonOut_transEntry_bits_status_issueTimer)
    `CHK(io_commonOut_transEntry_bits_status_deqPortIdx)
    `CHK(io_commonOut_transEntry_bits_imm)
    `CHK(io_commonOut_transEntry_bits_payload_instr)
    `CHK(io_commonOut_transEntry_bits_payload_pc)
    `CHK(io_commonOut_transEntry_bits_payload_foldpc)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_0)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_1)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_2)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_3)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_4)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_5)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_6)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_7)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_8)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_9)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_10)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_11)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_12)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_13)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_14)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_15)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_16)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_17)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_18)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_19)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_20)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_21)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_22)
    `CHK(io_commonOut_transEntry_bits_payload_exceptionVec_23)
    `CHK(io_commonOut_transEntry_bits_payload_isFetchMalAddr)
    `CHK(io_commonOut_transEntry_bits_payload_hasException)
    `CHK(io_commonOut_transEntry_bits_payload_trigger)
    `CHK(io_commonOut_transEntry_bits_payload_preDecodeInfo_valid)
    `CHK(io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC)
    `CHK(io_commonOut_transEntry_bits_payload_preDecodeInfo_brType)
    `CHK(io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall)
    `CHK(io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet)
    `CHK(io_commonOut_transEntry_bits_payload_pred_taken)
    `CHK(io_commonOut_transEntry_bits_payload_crossPageIPFFix)
    `CHK(io_commonOut_transEntry_bits_payload_ftqPtr_flag)
    `CHK(io_commonOut_transEntry_bits_payload_ftqPtr_value)
    `CHK(io_commonOut_transEntry_bits_payload_ftqOffset)
    `CHK(io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault)
    `CHK(io_commonOut_transEntry_bits_payload_srcType_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcType_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcType_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcType_3)
    `CHK(io_commonOut_transEntry_bits_payload_srcType_4)
    `CHK(io_commonOut_transEntry_bits_payload_ldest)
    `CHK(io_commonOut_transEntry_bits_payload_fuType)
    `CHK(io_commonOut_transEntry_bits_payload_fuOpType)
    `CHK(io_commonOut_transEntry_bits_payload_rfWen)
    `CHK(io_commonOut_transEntry_bits_payload_fpWen)
    `CHK(io_commonOut_transEntry_bits_payload_vecWen)
    `CHK(io_commonOut_transEntry_bits_payload_v0Wen)
    `CHK(io_commonOut_transEntry_bits_payload_vlWen)
    `CHK(io_commonOut_transEntry_bits_payload_isXSTrap)
    `CHK(io_commonOut_transEntry_bits_payload_waitForward)
    `CHK(io_commonOut_transEntry_bits_payload_blockBackward)
    `CHK(io_commonOut_transEntry_bits_payload_flushPipe)
    `CHK(io_commonOut_transEntry_bits_payload_canRobCompress)
    `CHK(io_commonOut_transEntry_bits_payload_selImm)
    `CHK(io_commonOut_transEntry_bits_payload_imm)
    `CHK(io_commonOut_transEntry_bits_payload_fpu_typeTagOut)
    `CHK(io_commonOut_transEntry_bits_payload_fpu_wflags)
    `CHK(io_commonOut_transEntry_bits_payload_fpu_typ)
    `CHK(io_commonOut_transEntry_bits_payload_fpu_fmt)
    `CHK(io_commonOut_transEntry_bits_payload_fpu_rm)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vill)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vma)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vta)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vsew)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vlmul)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_specVill)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_specVma)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_specVta)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_specVsew)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_specVlmul)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vm)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vstart)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_frm)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vxrm)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vuopIdx)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_lastUop)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vmask)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_vl)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_nf)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_veew)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isReverse)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isExt)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isNarrow)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isDstMask)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isOpMask)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isMove)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isDependOldVd)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isWritePartVd)
    `CHK(io_commonOut_transEntry_bits_payload_vpu_isVleff)
    `CHK(io_commonOut_transEntry_bits_payload_vlsInstr)
    `CHK(io_commonOut_transEntry_bits_payload_wfflags)
    `CHK(io_commonOut_transEntry_bits_payload_isMove)
    `CHK(io_commonOut_transEntry_bits_payload_isDropAmocasSta)
    `CHK(io_commonOut_transEntry_bits_payload_uopIdx)
    `CHK(io_commonOut_transEntry_bits_payload_isVset)
    `CHK(io_commonOut_transEntry_bits_payload_firstUop)
    `CHK(io_commonOut_transEntry_bits_payload_lastUop)
    `CHK(io_commonOut_transEntry_bits_payload_numUops)
    `CHK(io_commonOut_transEntry_bits_payload_numWB)
    `CHK(io_commonOut_transEntry_bits_payload_commitType)
    `CHK(io_commonOut_transEntry_bits_payload_srcState_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcState_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcState_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcState_3)
    `CHK(io_commonOut_transEntry_bits_payload_srcState_4)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1)
    `CHK(io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2)
    `CHK(io_commonOut_transEntry_bits_payload_psrc_0)
    `CHK(io_commonOut_transEntry_bits_payload_psrc_1)
    `CHK(io_commonOut_transEntry_bits_payload_psrc_2)
    `CHK(io_commonOut_transEntry_bits_payload_psrc_3)
    `CHK(io_commonOut_transEntry_bits_payload_psrc_4)
    `CHK(io_commonOut_transEntry_bits_payload_pdest)
    `CHK(io_commonOut_transEntry_bits_payload_useRegCache_0)
    `CHK(io_commonOut_transEntry_bits_payload_useRegCache_1)
    `CHK(io_commonOut_transEntry_bits_payload_regCacheIdx_0)
    `CHK(io_commonOut_transEntry_bits_payload_regCacheIdx_1)
    `CHK(io_commonOut_transEntry_bits_payload_robIdx_flag)
    `CHK(io_commonOut_transEntry_bits_payload_robIdx_value)
    `CHK(io_commonOut_transEntry_bits_payload_instrSize)
    `CHK(io_commonOut_transEntry_bits_payload_dirtyFs)
    `CHK(io_commonOut_transEntry_bits_payload_dirtyVs)
    `CHK(io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype)
    `CHK(io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire)
    `CHK(io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize)
    `CHK(io_commonOut_transEntry_bits_payload_eliminatedMove)
    `CHK(io_commonOut_transEntry_bits_payload_snapshot)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_renameTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_selectTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_issueTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_writebackTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime)
    `CHK(io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime)
    `CHK(io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum)
    `CHK(io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx)
    `CHK(io_commonOut_transEntry_bits_payload_storeSetHit)
    `CHK(io_commonOut_transEntry_bits_payload_waitForRobIdx_flag)
    `CHK(io_commonOut_transEntry_bits_payload_waitForRobIdx_value)
    `CHK(io_commonOut_transEntry_bits_payload_loadWaitBit)
    `CHK(io_commonOut_transEntry_bits_payload_loadWaitStrict)
    `CHK(io_commonOut_transEntry_bits_payload_ssid)
    `CHK(io_commonOut_transEntry_bits_payload_lqIdx_flag)
    `CHK(io_commonOut_transEntry_bits_payload_lqIdx_value)
    `CHK(io_commonOut_transEntry_bits_payload_sqIdx_flag)
    `CHK(io_commonOut_transEntry_bits_payload_sqIdx_value)
    `CHK(io_commonOut_transEntry_bits_payload_singleStep)
    `CHK(io_commonOut_transEntry_bits_payload_replayInst)
    `CHK(io_commonOut_transEntry_bits_payload_debug_fuType)
    `CHK(io_commonOut_transEntry_bits_payload_debug_sim_trig)
    `CHK(io_commonOut_transEntry_bits_payload_numLsElem)
    `CHK(io_commonOut_entryInValid)
    `CHK(io_commonOut_entryOutDeqValid)
    `CHK(io_commonOut_entryOutTransValid)
    `CHK(io_commonOut_perfLdCancel_0)
    `CHK(io_commonOut_perfOg0Cancel_0)
    `CHK(io_commonOut_perfWakeupByWB_0)
    `CHK(io_commonOut_perfWakeupByIQ_0_0)
    `CHK(io_commonOut_perfWakeupByIQ_0_1)
    `CHK(io_commonOut_perfWakeupByIQ_0_2)
    `CHK(io_commonOut_perfWakeupByIQ_0_3)
    `CHK(io_commonOut_perfWakeupByIQ_0_4)
    `CHK(io_commonOut_perfWakeupByIQ_0_5)
    `CHK(io_commonOut_perfWakeupByIQ_0_6)
  endtask

  localparam int POOL = 8;   // pdest/psrc 共用的小池，保证唤醒能打中
  // *** +nopool：覆盖闸的双向负测开关 ***
  //   把小池换成整个 psrc 空间，唤醒就几乎永远打不中在队 uop 的源。
  //   电路一个字没改，只是激励退化 —— 这一轮**必须**把覆盖闸打红。
  //   它证明的是「闸看得见激励塌陷」，与变异体证明「自己改了电路」
  //   互为对偶。正常跑不给这个 plusarg；负测由 check_cov_gate.py 驱动。
  bit nopool = 0;
  function automatic int rnd_reg();
    return nopool ? $urandom_range(0, 255)
                  : $urandom_range(0, POOL-1);
  endfunction
  localparam int RCPOOL = 4;  // regCacheIdx 小池，让 replaceRC 打得中
  function automatic int rnd_rc(); return $urandom_range(0, RCPOOL-1); endfunction

  // ---- 每拍激励（负沿下非阻塞给出）----
  task automatic drive();
    io_commonIn_flush_valid            <= ($urandom_range(0, 999) < 4);
    io_commonIn_flush_bits_robIdx_flag <= $urandom_range(0, 1);
    io_commonIn_flush_bits_robIdx_value <= 8'($urandom_range(0, 255));
    io_commonIn_flush_bits_level       <= $urandom_range(0, 1);
    // 入队率 35%：太高则条目永远刚写过，唤醒/发射通路测不到
    io_commonIn_enq_valid <= ($urandom_range(0, 99) < 35);
    io_commonIn_enq_bits_status_robIdx_flag  <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_robIdx_value <= 8'($urandom_range(0, 255));
    io_commonIn_enq_bits_status_fuType_15 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_srcStatus_0_psrc <= 8'(rnd_reg());
    // src0 的 WB 唤醒门控位是 srcType[0]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_0_srcType <= ($urandom_range(0,99) < 88) ? 4'h1 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_0_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_0_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0 <= ($urandom_range(0,99) < 25) ? 2'($urandom_range(1, 3)) : 2'h0;
    io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1 <= ($urandom_range(0,99) < 25) ? 2'($urandom_range(1, 3)) : 2'h0;
    io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2 <= ($urandom_range(0,99) < 25) ? 2'($urandom_range(1, 3)) : 2'h0;
    io_commonIn_enq_bits_status_srcStatus_0_exuSources_value <= 3'($urandom_range(0, 7));
    io_commonIn_enq_bits_status_srcStatus_0_useRegCache <= ($urandom_range(0, 99) < 40);
    io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx <= 5'(rnd_rc());
    io_commonIn_enq_bits_status_blocked <= ($urandom_range(0, 99) < 10);
    io_commonIn_enq_bits_status_issued <= ($urandom_range(0, 99) < 20);
    io_commonIn_enq_bits_status_firstIssue <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_issueTimer <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_deqPortIdx <= $urandom_range(0, 1);
    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）
    io_commonIn_enq_bits_imm <= 32'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_valid <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isRVC <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_brType <= 2'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isCall <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isRet <= 1'($urandom());
    io_commonIn_enq_bits_payload_ftqPtr_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_ftqPtr_value <= 6'($urandom());
    io_commonIn_enq_bits_payload_ftqOffset <= 4'($urandom());
    io_commonIn_enq_bits_payload_fuOpType <= 9'($urandom());
    io_commonIn_enq_bits_payload_rfWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_fpWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_flushPipe <= 1'($urandom());
    io_commonIn_enq_bits_payload_selImm <= 4'($urandom());
    io_commonIn_enq_bits_payload_pdest <= 8'($urandom());
    io_commonIn_enq_bits_payload_debugInfo_eliminatedMove <= 1'($urandom());
    io_commonIn_enq_bits_payload_debugInfo_renameTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_dispatchTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_enqRsTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_writebackTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_tlbRespTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debug_seqNum_seqNum <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debug_seqNum_uopIdx <= 8'($urandom());
    io_commonIn_enq_bits_payload_storeSetHit <= 1'($urandom());
    io_commonIn_enq_bits_payload_waitForRobIdx_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_waitForRobIdx_value <= 8'($urandom());
    io_commonIn_enq_bits_payload_loadWaitBit <= 1'($urandom());
    io_commonIn_enq_bits_payload_loadWaitStrict <= 1'($urandom());
    io_commonIn_enq_bits_payload_ssid <= 5'($urandom());
    io_commonIn_enq_bits_payload_lqIdx_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_lqIdx_value <= 7'($urandom());
    io_commonIn_enq_bits_payload_sqIdx_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_sqIdx_value <= 6'($urandom());
    io_commonIn_enq_bits_payload_instr <= 32'($urandom());
    io_commonIn_enq_bits_payload_pc <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_foldpc <= 10'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_0 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_1 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_2 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_3 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_4 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_5 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_6 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_7 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_8 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_9 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_10 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_11 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_12 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_13 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_14 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_15 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_16 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_17 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_18 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_19 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_20 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_21 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_22 <= 1'($urandom());
    io_commonIn_enq_bits_payload_exceptionVec_23 <= 1'($urandom());
    io_commonIn_enq_bits_payload_isFetchMalAddr <= 1'($urandom());
    io_commonIn_enq_bits_payload_hasException <= 1'($urandom());
    io_commonIn_enq_bits_payload_trigger <= 4'($urandom());
    io_commonIn_enq_bits_payload_pred_taken <= 1'($urandom());
    io_commonIn_enq_bits_payload_crossPageIPFFix <= 1'($urandom());
    io_commonIn_enq_bits_payload_satpFlushFirstFetchFault <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcType_0 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_1 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_2 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_3 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_4 <= 4'($urandom());
    io_commonIn_enq_bits_payload_ldest <= 6'($urandom());
    io_commonIn_enq_bits_payload_fuType <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_vecWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_v0Wen <= 1'($urandom());
    io_commonIn_enq_bits_payload_vlWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_isXSTrap <= 1'($urandom());
    io_commonIn_enq_bits_payload_waitForward <= 1'($urandom());
    io_commonIn_enq_bits_payload_blockBackward <= 1'($urandom());
    io_commonIn_enq_bits_payload_canRobCompress <= 1'($urandom());
    io_commonIn_enq_bits_payload_imm <= 32'($urandom());
    io_commonIn_enq_bits_payload_fpu_typeTagOut <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_wflags <= 1'($urandom());
    io_commonIn_enq_bits_payload_fpu_typ <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_fmt <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_rm <= 3'($urandom());
    io_commonIn_enq_bits_payload_vpu_vill <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vma <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vta <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vsew <= 2'($urandom());
    io_commonIn_enq_bits_payload_vpu_vlmul <= 3'($urandom());
    io_commonIn_enq_bits_payload_vpu_specVill <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_specVma <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_specVta <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_specVsew <= 2'($urandom());
    io_commonIn_enq_bits_payload_vpu_specVlmul <= 3'($urandom());
    io_commonIn_enq_bits_payload_vpu_vm <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vstart <= 8'($urandom());
    io_commonIn_enq_bits_payload_vpu_frm <= 3'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isReduction <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2 <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4 <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8 <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vxrm <= 2'($urandom());
    io_commonIn_enq_bits_payload_vpu_vuopIdx <= 7'($urandom());
    io_commonIn_enq_bits_payload_vpu_lastUop <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_vmask <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_vpu_vl <= 8'($urandom());
    io_commonIn_enq_bits_payload_vpu_nf <= 3'($urandom());
    io_commonIn_enq_bits_payload_vpu_veew <= 2'($urandom());
    io_commonIn_enq_bits_payload_vpu_isReverse <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isExt <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isNarrow <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isDstMask <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isOpMask <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isMove <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isDependOldVd <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isWritePartVd <= 1'($urandom());
    io_commonIn_enq_bits_payload_vpu_isVleff <= 1'($urandom());
    io_commonIn_enq_bits_payload_vlsInstr <= 1'($urandom());
    io_commonIn_enq_bits_payload_wfflags <= 1'($urandom());
    io_commonIn_enq_bits_payload_isMove <= 1'($urandom());
    io_commonIn_enq_bits_payload_isDropAmocasSta <= 1'($urandom());
    io_commonIn_enq_bits_payload_uopIdx <= 7'($urandom());
    io_commonIn_enq_bits_payload_isVset <= 1'($urandom());
    io_commonIn_enq_bits_payload_firstUop <= 1'($urandom());
    io_commonIn_enq_bits_payload_lastUop <= 1'($urandom());
    io_commonIn_enq_bits_payload_numUops <= 7'($urandom());
    io_commonIn_enq_bits_payload_numWB <= 7'($urandom());
    io_commonIn_enq_bits_payload_commitType <= 3'($urandom());
    io_commonIn_enq_bits_payload_srcState_0 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_1 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_2 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_3 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_4 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_0_0 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_0_1 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_0_2 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_1_0 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_1_1 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_1_2 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_2_0 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_2_1 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_2_2 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_3_0 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_3_1 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_3_2 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_4_0 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_4_1 <= 2'($urandom());
    io_commonIn_enq_bits_payload_srcLoadDependency_4_2 <= 2'($urandom());
    io_commonIn_enq_bits_payload_psrc_0 <= 8'($urandom());
    io_commonIn_enq_bits_payload_psrc_1 <= 8'($urandom());
    io_commonIn_enq_bits_payload_psrc_2 <= 8'($urandom());
    io_commonIn_enq_bits_payload_psrc_3 <= 8'($urandom());
    io_commonIn_enq_bits_payload_psrc_4 <= 8'($urandom());
    io_commonIn_enq_bits_payload_useRegCache_0 <= 1'($urandom());
    io_commonIn_enq_bits_payload_useRegCache_1 <= 1'($urandom());
    io_commonIn_enq_bits_payload_regCacheIdx_0 <= 5'($urandom());
    io_commonIn_enq_bits_payload_regCacheIdx_1 <= 5'($urandom());
    io_commonIn_enq_bits_payload_robIdx_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_robIdx_value <= 8'($urandom());
    io_commonIn_enq_bits_payload_instrSize <= 3'($urandom());
    io_commonIn_enq_bits_payload_dirtyFs <= 1'($urandom());
    io_commonIn_enq_bits_payload_dirtyVs <= 1'($urandom());
    io_commonIn_enq_bits_payload_traceBlockInPipe_itype <= 4'($urandom());
    io_commonIn_enq_bits_payload_traceBlockInPipe_iretire <= 4'($urandom());
    io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize <= 1'($urandom());
    io_commonIn_enq_bits_payload_eliminatedMove <= 1'($urandom());
    io_commonIn_enq_bits_payload_snapshot <= 1'($urandom());
    io_commonIn_enq_bits_payload_debugInfo_selectTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debugInfo_issueTime <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_singleStep <= 1'($urandom());
    io_commonIn_enq_bits_payload_replayInst <= 1'($urandom());
    io_commonIn_enq_bits_payload_debug_fuType <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debug_sim_trig <= 1'($urandom());
    io_commonIn_enq_bits_payload_numLsElem <= 5'($urandom());
    io_commonIn_wakeUpFromWB_0_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_0_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_0_bits_rfWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_0_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_0_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_1_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_1_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_1_bits_rfWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_1_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_1_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_2_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_2_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_2_bits_rfWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_2_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_2_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_3_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_3_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_3_bits_rfWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_3_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_3_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_0_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_0_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_0_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_0_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_1_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_1_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_1_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_1_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_2_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_2_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_2_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_2_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_3_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_3_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_3_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_3_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_4_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_4_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_4_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_4_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_5_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_5_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_5_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_5_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_wakeUpFromIQ_6_bits_rfWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_6_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2 <= 2'($urandom_range(0, 3));
    io_commonIn_wakeUpFromIQ_6_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_6_bits_rcDest <= 5'(rnd_rc());
    io_commonIn_og0Cancel_0 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_2 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_4 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_6 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_20 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_21 <= ($urandom_range(0, 99) < 20);
    io_commonIn_og0Cancel_22 <= ($urandom_range(0, 99) < 20);
    io_commonIn_ldCancel_0_ld1Cancel <= ($urandom_range(0, 99) < 15);
    io_commonIn_ldCancel_0_ld2Cancel <= ($urandom_range(0, 99) < 15);
    io_commonIn_ldCancel_1_ld1Cancel <= ($urandom_range(0, 99) < 15);
    io_commonIn_ldCancel_1_ld2Cancel <= ($urandom_range(0, 99) < 15);
    io_commonIn_ldCancel_2_ld1Cancel <= ($urandom_range(0, 99) < 15);
    io_commonIn_ldCancel_2_ld2Cancel <= ($urandom_range(0, 99) < 15);
    // issueResp：三种响应都要回到（BLOCK=0 / UNCERTAIN=1 / SUCCESS=3）
    io_commonIn_issueResp_valid <= ($urandom_range(0, 99) < 35);
    io_commonIn_issueResp_bits_resp <= (2'($urandom_range(0, 2)) == 2'd2) ? 2'd3 : 2'($urandom_range(0, 1));
  endtask

  // ---- deqSel / transSel：必须在时钟沿之前按 golden 当拍的 canIssue 算 ----
  // 纯随机给的话命中 canIssue 的概率极低，发射通路整轮不动（假绿的头号来源）。
  task automatic drive_sel();
    io_commonIn_deqSel = g_io_commonOut_canIssue && ($urandom_range(0, 99) < 70);
    io_commonIn_transSel = g_io_commonOut_valid && ($urandom_range(0, 99) < 25);
  endtask

  // ---- 覆盖统计（在时钟沿前采样，"沿上一变就看不见了"）----
  task automatic sample_cov();
    if (io_commonIn_enq_valid) cov_enq_fire++;
    if (g_io_commonOut_canIssue) cov_can_issue++;
    if (io_commonIn_deqSel && g_io_commonOut_canIssue) cov_deq_fire++;
    if (io_commonIn_issueResp_valid) begin
      case (io_commonIn_issueResp_bits_resp)
        2'd3: cov_resp_succ++;
        2'd0: cov_resp_block++;
        2'd1: cov_resp_uncertain++;
        default: ;
      endcase
    end
    if (g_io_commonOut_entryOutDeqValid) cov_deq_clear++;
    if (io_commonIn_flush_valid && g_io_commonOut_valid) cov_flush_hit++;
    // wb_wake：写回唤醒真把一个**未就绪**的源翻成就绪（探 golden 的 perf 出口，
    //   它的定义正是 srcWakeupByWB && isBusy(srcState) && validReg）
    if (g_io_commonOut_perfWakeupByWB_0) cov_wb_wake++;
    if (g_io_commonOut_entryOutTransValid) cov_trans_fire++;
    if (io_commonIn_enq_valid && g_io_commonOut_valid) cov_enq_while_valid++;
    if (g_io_commonOut_perfWakeupByIQ_0_0 || g_io_commonOut_perfWakeupByIQ_0_1 || g_io_commonOut_perfWakeupByIQ_0_2 || g_io_commonOut_perfWakeupByIQ_0_3 || g_io_commonOut_perfWakeupByIQ_0_4 || g_io_commonOut_perfWakeupByIQ_0_5 || g_io_commonOut_perfWakeupByIQ_0_6) cov_iq_wake++;
    if (g_io_commonOut_perfOg0Cancel_0) cov_og0_cancel_hit++;
    if (g_io_commonOut_perfLdCancel_0) cov_ld_cancel_hit++;
    if (io_commonIn_enq_bits_status_srcStatus_0_useRegCache) cov_rc_hit++;
  endtask

  longint cyc = 0;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    nopool = $test$plusargs("nopool");
    MINCOV["enq_fire"] = ((NCYCLES * 17390) / 200000) > 0 ? ((NCYCLES * 17390) / 200000) : 1;
    MINCOV["wb_wake"] = ((NCYCLES * 3996) / 200000) > 0 ? ((NCYCLES * 3996) / 200000) : 1;
    MINCOV["can_issue"] = ((NCYCLES * 5681) / 200000) > 0 ? ((NCYCLES * 5681) / 200000) : 1;
    MINCOV["deq_fire"] = ((NCYCLES * 3936) / 200000) > 0 ? ((NCYCLES * 3936) / 200000) : 1;
    MINCOV["resp_succ"] = ((NCYCLES * 5738) / 200000) > 0 ? ((NCYCLES * 5738) / 200000) : 1;
    MINCOV["resp_block"] = ((NCYCLES * 5772) / 200000) > 0 ? ((NCYCLES * 5772) / 200000) : 1;
    MINCOV["resp_uncertain"] = ((NCYCLES * 5747) / 200000) > 0 ? ((NCYCLES * 5747) / 200000) : 1;
    MINCOV["deq_clear"] = ((NCYCLES * 3177) / 200000) > 0 ? ((NCYCLES * 3177) / 200000) : 1;
    MINCOV["flush_hit"] = ((NCYCLES * 114) / 200000) > 0 ? ((NCYCLES * 114) / 200000) : 1;
    MINCOV["trans_fire"] = ((NCYCLES * 2305) / 200000) > 0 ? ((NCYCLES * 2305) / 200000) : 1;
    MINCOV["enq_while_valid"] = ((NCYCLES * 10598) / 200000) > 0 ? ((NCYCLES * 10598) / 200000) : 1;
    MINCOV["iq_wake"] = ((NCYCLES * 7502) / 200000) > 0 ? ((NCYCLES * 7502) / 200000) : 1;
    MINCOV["og0_cancel_hit"] = ((NCYCLES * 335) / 200000) > 0 ? ((NCYCLES * 335) / 200000) : 1;
    MINCOV["ld_cancel_hit"] = ((NCYCLES * 5674) / 200000) > 0 ? ((NCYCLES * 5674) / 200000) : 1;
    MINCOV["rc_hit"] = ((NCYCLES * 31909) / 200000) > 0 ? ((NCYCLES * 31909) / 200000) : 1;
    if (nopool) $display("*** +nopool: 覆盖闸负测模式（激励退化，闸必须红）***");
    reset = 1;
    drive();
    io_commonIn_deqSel = 1'b0;
    io_commonIn_transSel = 1'b0;
    repeat (4) @(posedge clock);
    reset = 0;
    forever begin
      @(negedge clock);
      drive();
      #1 drive_sel();     // 用当拍已落定的 golden 输出算选择信号
      sample_cov();
      @(posedge clock);
      #1;
      cyc++;
      // warm：条目被写过之后，裸读输出才有可比性（见文件头第二个坑）
      // drive() 用非阻塞在负沿给值，到这里 io_commonIn_enq_valid 仍是刚才
      // 那一拍的取值 —— 它为 1 就说明本拍沿上条目被整份写过了。
      if (!warm && io_commonIn_enq_valid) begin warm = 1; warm_cycle = cyc; end
      if (warm) check_outputs();
      if (cyc >= NCYCLES) begin
        $display("=== %0d cycles, checks=%0d, errors=%0d ===", cyc, checks, errors);
        $display("  warm_cycle = %0d", warm_cycle);
        if (warm_cycle < 0) begin
          $display("  *** 整轮都没等到条目被写过 —— 这一轮什么也没测");
          cov_fail++;
        end
        covchk("enq_fire", cov_enq_fire);
        covchk("wb_wake", cov_wb_wake);
        covchk("can_issue", cov_can_issue);
        covchk("deq_fire", cov_deq_fire);
        covchk("resp_succ", cov_resp_succ);
        covchk("resp_block", cov_resp_block);
        covchk("resp_uncertain", cov_resp_uncertain);
        covchk("deq_clear", cov_deq_clear);
        covchk("flush_hit", cov_flush_hit);
        covchk("trans_fire", cov_trans_fire);
        covchk("enq_while_valid", cov_enq_while_valid);
        covchk("iq_wake", cov_iq_wake);
        covchk("og0_cancel_hit", cov_og0_cancel_hit);
        covchk("ld_cancel_hit", cov_ld_cancel_hit);
        covchk("rc_hit", cov_rc_hit);
        if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
        else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);
        $finish;
      end
    end
  end
endmodule
