// EnqEntry_14 UT —— golden EnqEntry_14 与重写 EnqEntry_14_xs 双例化，逐拍比对全部 331 个输出。
// 端口表从 G1 golden 机械提取，比对用 `CHK 宏逐端口展开，杜绝手抄漏项。
//
// ★ 单条目最容易出的假绿：激励根本没让它动 ★
//   条目不入队 / 不被唤醒 / 不发射时，两边输出都是「空条目」的平凡相等，
//   200k 拍 errors=0 什么也证明不了。所以除逐拍比对外还守一组覆盖闸
//   （见文件末 finish 里的 covchk），低于下限判 FAIL：
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
//     enq_delay_win
//     enq_delay_wake
//     ignore_old_vd
//
// ★ 本族专属的闸：enq_delay_win / enq_delay_wake ★
//   入队延迟唤醒窗口是 EnqEntry 相对 OthersEntry 唯一的新逻辑。窗口只在
//   「入队成功」的下一拍开着（golden: enqDelayValidReg <= enq.valid && enqReady），
//   而 enqReady = 条目空 或 本拍被搬走。窗口开着时还得有一路延迟唤醒真打中
//   刚入队那个 uop 的源，这条通路才被走到 —— 两个闸分别守这两件事。
//   窗口条件由 tb 从 golden 的 commonOut.valid + 自己发的激励算出来（纯激励侧
//   记账，不是给 DUT 建模）。
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
//      当拍总线与延迟总线共用同一个池，否则延迟窗口那条通路照样打不中。
//   2) srcType 按各源真实的门控位给，给错了那一路唤醒整条哑掉；
//   3) deqSel / transSel 在时钟沿**之前**用阻塞赋值从 golden 当拍已落定的
//      canIssue / valid 算出来，否则慢一拍全打空。
// 自动生成：verif/ut/EnqEntry_14/gen.py（共享库 verif/ut/EnqEntry_common/enqentry_gen.py）—— 勿手改
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
  int cov_enq_delay_win = 0;
  int cov_enq_delay_wake = 0;
  int cov_ignore_old_vd = 0;
  int cov_fail = 0;
  int MINCOV[string];   // 逐桶下限（见 enqentry_gen.py 的 COV_MIN_200K）
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
  logic io_commonIn_enq_bits_status_fuType_18;
  logic io_commonIn_enq_bits_status_fuType_19;
  logic io_commonIn_enq_bits_status_fuType_20;
  logic io_commonIn_enq_bits_status_fuType_21;
  logic io_commonIn_enq_bits_status_fuType_24;
  logic io_commonIn_enq_bits_status_fuType_25;
  logic io_commonIn_enq_bits_status_fuType_27;
  logic io_commonIn_enq_bits_status_fuType_30;
  logic [6:0] io_commonIn_enq_bits_status_srcStatus_0_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_0_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_dataSources_value;
  logic [6:0] io_commonIn_enq_bits_status_srcStatus_1_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_1_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_1_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_1_dataSources_value;
  logic [6:0] io_commonIn_enq_bits_status_srcStatus_2_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_2_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_2_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_2_dataSources_value;
  logic [6:0] io_commonIn_enq_bits_status_srcStatus_3_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_3_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_3_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_3_dataSources_value;
  logic [6:0] io_commonIn_enq_bits_status_srcStatus_4_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_4_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_4_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_4_dataSources_value;
  logic [14:0] io_commonIn_enq_bits_imm;
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
  logic io_commonIn_wakeUpFromWB_15_valid;
  logic io_commonIn_wakeUpFromWB_15_bits_vlWen;
  logic [7:0] io_commonIn_wakeUpFromWB_15_bits_pdest;
  logic io_commonIn_wakeUpFromWB_14_valid;
  logic io_commonIn_wakeUpFromWB_14_bits_vlWen;
  logic [7:0] io_commonIn_wakeUpFromWB_14_bits_pdest;
  logic io_commonIn_wakeUpFromWB_13_valid;
  logic io_commonIn_wakeUpFromWB_13_bits_vlWen;
  logic [7:0] io_commonIn_wakeUpFromWB_13_bits_pdest;
  logic io_commonIn_wakeUpFromWB_12_valid;
  logic io_commonIn_wakeUpFromWB_12_bits_vlWen;
  logic [7:0] io_commonIn_wakeUpFromWB_12_bits_pdest;
  logic io_commonIn_wakeUpFromWB_11_valid;
  logic io_commonIn_wakeUpFromWB_11_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_11_bits_pdest;
  logic io_commonIn_wakeUpFromWB_10_valid;
  logic io_commonIn_wakeUpFromWB_10_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_10_bits_pdest;
  logic io_commonIn_wakeUpFromWB_9_valid;
  logic io_commonIn_wakeUpFromWB_9_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_9_bits_pdest;
  logic io_commonIn_wakeUpFromWB_8_valid;
  logic io_commonIn_wakeUpFromWB_8_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_8_bits_pdest;
  logic io_commonIn_wakeUpFromWB_7_valid;
  logic io_commonIn_wakeUpFromWB_7_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_7_bits_pdest;
  logic io_commonIn_wakeUpFromWB_6_valid;
  logic io_commonIn_wakeUpFromWB_6_bits_v0Wen;
  logic [7:0] io_commonIn_wakeUpFromWB_6_bits_pdest;
  logic io_commonIn_wakeUpFromWB_5_valid;
  logic io_commonIn_wakeUpFromWB_5_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_5_bits_pdest;
  logic io_commonIn_wakeUpFromWB_4_valid;
  logic io_commonIn_wakeUpFromWB_4_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_4_bits_pdest;
  logic io_commonIn_wakeUpFromWB_3_valid;
  logic io_commonIn_wakeUpFromWB_3_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_3_bits_pdest;
  logic io_commonIn_wakeUpFromWB_2_valid;
  logic io_commonIn_wakeUpFromWB_2_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_2_bits_pdest;
  logic io_commonIn_wakeUpFromWB_1_valid;
  logic io_commonIn_wakeUpFromWB_1_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_1_bits_pdest;
  logic io_commonIn_wakeUpFromWB_0_valid;
  logic io_commonIn_wakeUpFromWB_0_bits_vecWen;
  logic [7:0] io_commonIn_wakeUpFromWB_0_bits_pdest;
  logic io_commonIn_vlFromIntIsZero;
  logic io_commonIn_vlFromIntIsVlmax;
  logic io_commonIn_vlFromVfIsZero;
  logic io_commonIn_vlFromVfIsVlmax;
  logic io_commonIn_deqSel;
  logic io_commonIn_deqPortIdxWrite;
  logic io_commonIn_issueResp_valid;
  logic [1:0] io_commonIn_issueResp_bits_resp;
  logic io_commonIn_transSel;
  logic io_enqDelayIn1_wakeUpFromWB_15_valid;
  logic io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_15_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_14_valid;
  logic io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_14_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_13_valid;
  logic io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_13_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_12_valid;
  logic io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_12_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_11_valid;
  logic io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_11_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_10_valid;
  logic io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_10_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_9_valid;
  logic io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_9_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_8_valid;
  logic io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_8_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_7_valid;
  logic io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_7_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_6_valid;
  logic io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_6_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_5_valid;
  logic io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_5_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_4_valid;
  logic io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_4_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_3_valid;
  logic io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_3_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_2_valid;
  logic io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_2_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_1_valid;
  logic io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_1_bits_pdest;
  logic io_enqDelayIn1_wakeUpFromWB_0_valid;
  logic io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen;
  logic [7:0] io_enqDelayIn1_wakeUpFromWB_0_bits_pdest;
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
  wire [3:0] g_io_commonOut_dataSources_1_value;
  wire [3:0] i_io_commonOut_dataSources_1_value;
  wire [3:0] g_io_commonOut_dataSources_2_value;
  wire [3:0] i_io_commonOut_dataSources_2_value;
  wire [3:0] g_io_commonOut_dataSources_3_value;
  wire [3:0] i_io_commonOut_dataSources_3_value;
  wire [3:0] g_io_commonOut_dataSources_4_value;
  wire [3:0] i_io_commonOut_dataSources_4_value;
  wire g_io_commonOut_isFirstIssue;
  wire i_io_commonOut_isFirstIssue;
  wire g_io_commonOut_entry_bits_status_robIdx_flag;
  wire i_io_commonOut_entry_bits_status_robIdx_flag;
  wire [7:0] g_io_commonOut_entry_bits_status_robIdx_value;
  wire [7:0] i_io_commonOut_entry_bits_status_robIdx_value;
  wire g_io_commonOut_entry_bits_status_fuType_18;
  wire i_io_commonOut_entry_bits_status_fuType_18;
  wire g_io_commonOut_entry_bits_status_fuType_19;
  wire i_io_commonOut_entry_bits_status_fuType_19;
  wire g_io_commonOut_entry_bits_status_fuType_20;
  wire i_io_commonOut_entry_bits_status_fuType_20;
  wire g_io_commonOut_entry_bits_status_fuType_21;
  wire i_io_commonOut_entry_bits_status_fuType_21;
  wire g_io_commonOut_entry_bits_status_fuType_24;
  wire i_io_commonOut_entry_bits_status_fuType_24;
  wire g_io_commonOut_entry_bits_status_fuType_25;
  wire i_io_commonOut_entry_bits_status_fuType_25;
  wire g_io_commonOut_entry_bits_status_fuType_27;
  wire i_io_commonOut_entry_bits_status_fuType_27;
  wire g_io_commonOut_entry_bits_status_fuType_30;
  wire i_io_commonOut_entry_bits_status_fuType_30;
  wire [6:0] g_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [6:0] i_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [6:0] g_io_commonOut_entry_bits_status_srcStatus_1_psrc;
  wire [6:0] i_io_commonOut_entry_bits_status_srcStatus_1_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_1_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_1_srcType;
  wire [6:0] g_io_commonOut_entry_bits_status_srcStatus_2_psrc;
  wire [6:0] i_io_commonOut_entry_bits_status_srcStatus_2_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_2_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_2_srcType;
  wire [6:0] g_io_commonOut_entry_bits_status_srcStatus_3_psrc;
  wire [6:0] i_io_commonOut_entry_bits_status_srcStatus_3_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_3_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_3_srcType;
  wire [6:0] g_io_commonOut_entry_bits_status_srcStatus_4_psrc;
  wire [6:0] i_io_commonOut_entry_bits_status_srcStatus_4_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_4_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_4_srcType;
  wire [14:0] g_io_commonOut_entry_bits_imm;
  wire [14:0] i_io_commonOut_entry_bits_imm;
  wire [8:0] g_io_commonOut_entry_bits_payload_fuOpType;
  wire [8:0] i_io_commonOut_entry_bits_payload_fuOpType;
  wire g_io_commonOut_entry_bits_payload_rfWen;
  wire i_io_commonOut_entry_bits_payload_rfWen;
  wire g_io_commonOut_entry_bits_payload_fpWen;
  wire i_io_commonOut_entry_bits_payload_fpWen;
  wire g_io_commonOut_entry_bits_payload_vecWen;
  wire i_io_commonOut_entry_bits_payload_vecWen;
  wire g_io_commonOut_entry_bits_payload_v0Wen;
  wire i_io_commonOut_entry_bits_payload_v0Wen;
  wire g_io_commonOut_entry_bits_payload_vlWen;
  wire i_io_commonOut_entry_bits_payload_vlWen;
  wire [3:0] g_io_commonOut_entry_bits_payload_selImm;
  wire [3:0] i_io_commonOut_entry_bits_payload_selImm;
  wire [1:0] g_io_commonOut_entry_bits_payload_fpu_typeTagOut;
  wire [1:0] i_io_commonOut_entry_bits_payload_fpu_typeTagOut;
  wire g_io_commonOut_entry_bits_payload_fpu_wflags;
  wire i_io_commonOut_entry_bits_payload_fpu_wflags;
  wire [1:0] g_io_commonOut_entry_bits_payload_fpu_typ;
  wire [1:0] i_io_commonOut_entry_bits_payload_fpu_typ;
  wire [1:0] g_io_commonOut_entry_bits_payload_fpu_fmt;
  wire [1:0] i_io_commonOut_entry_bits_payload_fpu_fmt;
  wire [2:0] g_io_commonOut_entry_bits_payload_fpu_rm;
  wire [2:0] i_io_commonOut_entry_bits_payload_fpu_rm;
  wire g_io_commonOut_entry_bits_payload_vpu_vill;
  wire i_io_commonOut_entry_bits_payload_vpu_vill;
  wire g_io_commonOut_entry_bits_payload_vpu_vma;
  wire i_io_commonOut_entry_bits_payload_vpu_vma;
  wire g_io_commonOut_entry_bits_payload_vpu_vta;
  wire i_io_commonOut_entry_bits_payload_vpu_vta;
  wire [1:0] g_io_commonOut_entry_bits_payload_vpu_vsew;
  wire [1:0] i_io_commonOut_entry_bits_payload_vpu_vsew;
  wire [2:0] g_io_commonOut_entry_bits_payload_vpu_vlmul;
  wire [2:0] i_io_commonOut_entry_bits_payload_vpu_vlmul;
  wire g_io_commonOut_entry_bits_payload_vpu_specVill;
  wire i_io_commonOut_entry_bits_payload_vpu_specVill;
  wire g_io_commonOut_entry_bits_payload_vpu_specVma;
  wire i_io_commonOut_entry_bits_payload_vpu_specVma;
  wire g_io_commonOut_entry_bits_payload_vpu_specVta;
  wire i_io_commonOut_entry_bits_payload_vpu_specVta;
  wire [1:0] g_io_commonOut_entry_bits_payload_vpu_specVsew;
  wire [1:0] i_io_commonOut_entry_bits_payload_vpu_specVsew;
  wire [2:0] g_io_commonOut_entry_bits_payload_vpu_specVlmul;
  wire [2:0] i_io_commonOut_entry_bits_payload_vpu_specVlmul;
  wire g_io_commonOut_entry_bits_payload_vpu_vm;
  wire i_io_commonOut_entry_bits_payload_vpu_vm;
  wire [7:0] g_io_commonOut_entry_bits_payload_vpu_vstart;
  wire [7:0] i_io_commonOut_entry_bits_payload_vpu_vstart;
  wire [2:0] g_io_commonOut_entry_bits_payload_vpu_frm;
  wire [2:0] i_io_commonOut_entry_bits_payload_vpu_frm;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isReduction;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isReduction;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4;
  wire g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8;
  wire i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8;
  wire [1:0] g_io_commonOut_entry_bits_payload_vpu_vxrm;
  wire [1:0] i_io_commonOut_entry_bits_payload_vpu_vxrm;
  wire [127:0] g_io_commonOut_entry_bits_payload_vpu_vmask;
  wire [127:0] i_io_commonOut_entry_bits_payload_vpu_vmask;
  wire [7:0] g_io_commonOut_entry_bits_payload_vpu_vl;
  wire [7:0] i_io_commonOut_entry_bits_payload_vpu_vl;
  wire [2:0] g_io_commonOut_entry_bits_payload_vpu_nf;
  wire [2:0] i_io_commonOut_entry_bits_payload_vpu_nf;
  wire [1:0] g_io_commonOut_entry_bits_payload_vpu_veew;
  wire [1:0] i_io_commonOut_entry_bits_payload_vpu_veew;
  wire g_io_commonOut_entry_bits_payload_vpu_isReverse;
  wire i_io_commonOut_entry_bits_payload_vpu_isReverse;
  wire g_io_commonOut_entry_bits_payload_vpu_isExt;
  wire i_io_commonOut_entry_bits_payload_vpu_isExt;
  wire g_io_commonOut_entry_bits_payload_vpu_isNarrow;
  wire i_io_commonOut_entry_bits_payload_vpu_isNarrow;
  wire g_io_commonOut_entry_bits_payload_vpu_isDstMask;
  wire i_io_commonOut_entry_bits_payload_vpu_isDstMask;
  wire g_io_commonOut_entry_bits_payload_vpu_isOpMask;
  wire i_io_commonOut_entry_bits_payload_vpu_isOpMask;
  wire g_io_commonOut_entry_bits_payload_vpu_isMove;
  wire i_io_commonOut_entry_bits_payload_vpu_isMove;
  wire g_io_commonOut_entry_bits_payload_vpu_isDependOldVd;
  wire i_io_commonOut_entry_bits_payload_vpu_isDependOldVd;
  wire g_io_commonOut_entry_bits_payload_vpu_isWritePartVd;
  wire i_io_commonOut_entry_bits_payload_vpu_isWritePartVd;
  wire g_io_commonOut_entry_bits_payload_vpu_isVleff;
  wire i_io_commonOut_entry_bits_payload_vpu_isVleff;
  wire [6:0] g_io_commonOut_entry_bits_payload_uopIdx;
  wire [6:0] i_io_commonOut_entry_bits_payload_uopIdx;
  wire g_io_commonOut_entry_bits_payload_lastUop;
  wire i_io_commonOut_entry_bits_payload_lastUop;
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
  wire g_io_commonOut_deqPortIdxRead;
  wire i_io_commonOut_deqPortIdxRead;
  wire [1:0] g_io_commonOut_issueTimerRead;
  wire [1:0] i_io_commonOut_issueTimerRead;
  wire g_io_commonOut_transEntry_valid;
  wire i_io_commonOut_transEntry_valid;
  wire g_io_commonOut_transEntry_bits_status_robIdx_flag;
  wire i_io_commonOut_transEntry_bits_status_robIdx_flag;
  wire [7:0] g_io_commonOut_transEntry_bits_status_robIdx_value;
  wire [7:0] i_io_commonOut_transEntry_bits_status_robIdx_value;
  wire g_io_commonOut_transEntry_bits_status_fuType_18;
  wire i_io_commonOut_transEntry_bits_status_fuType_18;
  wire g_io_commonOut_transEntry_bits_status_fuType_19;
  wire i_io_commonOut_transEntry_bits_status_fuType_19;
  wire g_io_commonOut_transEntry_bits_status_fuType_20;
  wire i_io_commonOut_transEntry_bits_status_fuType_20;
  wire g_io_commonOut_transEntry_bits_status_fuType_21;
  wire i_io_commonOut_transEntry_bits_status_fuType_21;
  wire g_io_commonOut_transEntry_bits_status_fuType_24;
  wire i_io_commonOut_transEntry_bits_status_fuType_24;
  wire g_io_commonOut_transEntry_bits_status_fuType_25;
  wire i_io_commonOut_transEntry_bits_status_fuType_25;
  wire g_io_commonOut_transEntry_bits_status_fuType_27;
  wire i_io_commonOut_transEntry_bits_status_fuType_27;
  wire g_io_commonOut_transEntry_bits_status_fuType_30;
  wire i_io_commonOut_transEntry_bits_status_fuType_30;
  wire [6:0] g_io_commonOut_transEntry_bits_status_srcStatus_0_psrc;
  wire [6:0] i_io_commonOut_transEntry_bits_status_srcStatus_0_psrc;
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
  wire [6:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_psrc;
  wire [6:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_psrc;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_srcType;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_srcType;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_1_srcState;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_1_srcState;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2;
  wire [6:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_psrc;
  wire [6:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_psrc;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_srcType;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_srcType;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_2_srcState;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_2_srcState;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2;
  wire [6:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_psrc;
  wire [6:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_psrc;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_srcType;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_srcType;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_3_srcState;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_3_srcState;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2;
  wire [6:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_psrc;
  wire [6:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_psrc;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_srcType;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_srcType;
  wire g_io_commonOut_transEntry_bits_status_srcStatus_4_srcState;
  wire i_io_commonOut_transEntry_bits_status_srcStatus_4_srcState;
  wire [3:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value;
  wire [3:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1;
  wire [1:0] g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2;
  wire [1:0] i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2;
  wire g_io_commonOut_transEntry_bits_status_issued;
  wire i_io_commonOut_transEntry_bits_status_issued;
  wire g_io_commonOut_transEntry_bits_status_firstIssue;
  wire i_io_commonOut_transEntry_bits_status_firstIssue;
  wire [1:0] g_io_commonOut_transEntry_bits_status_issueTimer;
  wire [1:0] i_io_commonOut_transEntry_bits_status_issueTimer;
  wire g_io_commonOut_transEntry_bits_status_deqPortIdx;
  wire i_io_commonOut_transEntry_bits_status_deqPortIdx;
  wire [14:0] g_io_commonOut_transEntry_bits_imm;
  wire [14:0] i_io_commonOut_transEntry_bits_imm;
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
  wire g_io_commonOut_perfWakeupByWB_0;
  wire i_io_commonOut_perfWakeupByWB_0;
  wire g_io_commonOut_perfWakeupByWB_1;
  wire i_io_commonOut_perfWakeupByWB_1;
  wire g_io_commonOut_perfWakeupByWB_2;
  wire i_io_commonOut_perfWakeupByWB_2;
  wire g_io_commonOut_perfWakeupByWB_3;
  wire i_io_commonOut_perfWakeupByWB_3;
  wire g_io_commonOut_perfWakeupByWB_4;
  wire i_io_commonOut_perfWakeupByWB_4;

  EnqEntry_14 u_g (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_18(io_commonIn_enq_bits_status_fuType_18),
    .io_commonIn_enq_bits_status_fuType_19(io_commonIn_enq_bits_status_fuType_19),
    .io_commonIn_enq_bits_status_fuType_20(io_commonIn_enq_bits_status_fuType_20),
    .io_commonIn_enq_bits_status_fuType_21(io_commonIn_enq_bits_status_fuType_21),
    .io_commonIn_enq_bits_status_fuType_24(io_commonIn_enq_bits_status_fuType_24),
    .io_commonIn_enq_bits_status_fuType_25(io_commonIn_enq_bits_status_fuType_25),
    .io_commonIn_enq_bits_status_fuType_27(io_commonIn_enq_bits_status_fuType_27),
    .io_commonIn_enq_bits_status_fuType_30(io_commonIn_enq_bits_status_fuType_30),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_psrc(io_commonIn_enq_bits_status_srcStatus_1_psrc),
    .io_commonIn_enq_bits_status_srcStatus_1_srcType(io_commonIn_enq_bits_status_srcStatus_1_srcType),
    .io_commonIn_enq_bits_status_srcStatus_1_srcState(io_commonIn_enq_bits_status_srcStatus_1_srcState),
    .io_commonIn_enq_bits_status_srcStatus_1_dataSources_value(io_commonIn_enq_bits_status_srcStatus_1_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_psrc(io_commonIn_enq_bits_status_srcStatus_2_psrc),
    .io_commonIn_enq_bits_status_srcStatus_2_srcType(io_commonIn_enq_bits_status_srcStatus_2_srcType),
    .io_commonIn_enq_bits_status_srcStatus_2_srcState(io_commonIn_enq_bits_status_srcStatus_2_srcState),
    .io_commonIn_enq_bits_status_srcStatus_2_dataSources_value(io_commonIn_enq_bits_status_srcStatus_2_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_3_psrc(io_commonIn_enq_bits_status_srcStatus_3_psrc),
    .io_commonIn_enq_bits_status_srcStatus_3_srcType(io_commonIn_enq_bits_status_srcStatus_3_srcType),
    .io_commonIn_enq_bits_status_srcStatus_3_srcState(io_commonIn_enq_bits_status_srcStatus_3_srcState),
    .io_commonIn_enq_bits_status_srcStatus_3_dataSources_value(io_commonIn_enq_bits_status_srcStatus_3_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_4_psrc(io_commonIn_enq_bits_status_srcStatus_4_psrc),
    .io_commonIn_enq_bits_status_srcStatus_4_srcType(io_commonIn_enq_bits_status_srcStatus_4_srcType),
    .io_commonIn_enq_bits_status_srcStatus_4_srcState(io_commonIn_enq_bits_status_srcStatus_4_srcState),
    .io_commonIn_enq_bits_status_srcStatus_4_dataSources_value(io_commonIn_enq_bits_status_srcStatus_4_dataSources_value),
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
    .io_commonIn_wakeUpFromWB_15_valid(io_commonIn_wakeUpFromWB_15_valid),
    .io_commonIn_wakeUpFromWB_15_bits_vlWen(io_commonIn_wakeUpFromWB_15_bits_vlWen),
    .io_commonIn_wakeUpFromWB_15_bits_pdest(io_commonIn_wakeUpFromWB_15_bits_pdest),
    .io_commonIn_wakeUpFromWB_14_valid(io_commonIn_wakeUpFromWB_14_valid),
    .io_commonIn_wakeUpFromWB_14_bits_vlWen(io_commonIn_wakeUpFromWB_14_bits_vlWen),
    .io_commonIn_wakeUpFromWB_14_bits_pdest(io_commonIn_wakeUpFromWB_14_bits_pdest),
    .io_commonIn_wakeUpFromWB_13_valid(io_commonIn_wakeUpFromWB_13_valid),
    .io_commonIn_wakeUpFromWB_13_bits_vlWen(io_commonIn_wakeUpFromWB_13_bits_vlWen),
    .io_commonIn_wakeUpFromWB_13_bits_pdest(io_commonIn_wakeUpFromWB_13_bits_pdest),
    .io_commonIn_wakeUpFromWB_12_valid(io_commonIn_wakeUpFromWB_12_valid),
    .io_commonIn_wakeUpFromWB_12_bits_vlWen(io_commonIn_wakeUpFromWB_12_bits_vlWen),
    .io_commonIn_wakeUpFromWB_12_bits_pdest(io_commonIn_wakeUpFromWB_12_bits_pdest),
    .io_commonIn_wakeUpFromWB_11_valid(io_commonIn_wakeUpFromWB_11_valid),
    .io_commonIn_wakeUpFromWB_11_bits_v0Wen(io_commonIn_wakeUpFromWB_11_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_11_bits_pdest(io_commonIn_wakeUpFromWB_11_bits_pdest),
    .io_commonIn_wakeUpFromWB_10_valid(io_commonIn_wakeUpFromWB_10_valid),
    .io_commonIn_wakeUpFromWB_10_bits_v0Wen(io_commonIn_wakeUpFromWB_10_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_10_bits_pdest(io_commonIn_wakeUpFromWB_10_bits_pdest),
    .io_commonIn_wakeUpFromWB_9_valid(io_commonIn_wakeUpFromWB_9_valid),
    .io_commonIn_wakeUpFromWB_9_bits_v0Wen(io_commonIn_wakeUpFromWB_9_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_9_bits_pdest(io_commonIn_wakeUpFromWB_9_bits_pdest),
    .io_commonIn_wakeUpFromWB_8_valid(io_commonIn_wakeUpFromWB_8_valid),
    .io_commonIn_wakeUpFromWB_8_bits_v0Wen(io_commonIn_wakeUpFromWB_8_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_8_bits_pdest(io_commonIn_wakeUpFromWB_8_bits_pdest),
    .io_commonIn_wakeUpFromWB_7_valid(io_commonIn_wakeUpFromWB_7_valid),
    .io_commonIn_wakeUpFromWB_7_bits_v0Wen(io_commonIn_wakeUpFromWB_7_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_7_bits_pdest(io_commonIn_wakeUpFromWB_7_bits_pdest),
    .io_commonIn_wakeUpFromWB_6_valid(io_commonIn_wakeUpFromWB_6_valid),
    .io_commonIn_wakeUpFromWB_6_bits_v0Wen(io_commonIn_wakeUpFromWB_6_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_6_bits_pdest(io_commonIn_wakeUpFromWB_6_bits_pdest),
    .io_commonIn_wakeUpFromWB_5_valid(io_commonIn_wakeUpFromWB_5_valid),
    .io_commonIn_wakeUpFromWB_5_bits_vecWen(io_commonIn_wakeUpFromWB_5_bits_vecWen),
    .io_commonIn_wakeUpFromWB_5_bits_pdest(io_commonIn_wakeUpFromWB_5_bits_pdest),
    .io_commonIn_wakeUpFromWB_4_valid(io_commonIn_wakeUpFromWB_4_valid),
    .io_commonIn_wakeUpFromWB_4_bits_vecWen(io_commonIn_wakeUpFromWB_4_bits_vecWen),
    .io_commonIn_wakeUpFromWB_4_bits_pdest(io_commonIn_wakeUpFromWB_4_bits_pdest),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_vecWen(io_commonIn_wakeUpFromWB_3_bits_vecWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_vecWen(io_commonIn_wakeUpFromWB_2_bits_vecWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_vecWen(io_commonIn_wakeUpFromWB_1_bits_vecWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_vecWen(io_commonIn_wakeUpFromWB_0_bits_vecWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_vlFromIntIsZero(io_commonIn_vlFromIntIsZero),
    .io_commonIn_vlFromIntIsVlmax(io_commonIn_vlFromIntIsVlmax),
    .io_commonIn_vlFromVfIsZero(io_commonIn_vlFromVfIsZero),
    .io_commonIn_vlFromVfIsVlmax(io_commonIn_vlFromVfIsVlmax),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_deqPortIdxWrite(io_commonIn_deqPortIdxWrite),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonIn_transSel(io_commonIn_transSel),
    .io_enqDelayIn1_wakeUpFromWB_15_valid(io_enqDelayIn1_wakeUpFromWB_15_valid),
    .io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_15_bits_pdest(io_enqDelayIn1_wakeUpFromWB_15_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_14_valid(io_enqDelayIn1_wakeUpFromWB_14_valid),
    .io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_14_bits_pdest(io_enqDelayIn1_wakeUpFromWB_14_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_13_valid(io_enqDelayIn1_wakeUpFromWB_13_valid),
    .io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_13_bits_pdest(io_enqDelayIn1_wakeUpFromWB_13_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_12_valid(io_enqDelayIn1_wakeUpFromWB_12_valid),
    .io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_12_bits_pdest(io_enqDelayIn1_wakeUpFromWB_12_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_11_valid(io_enqDelayIn1_wakeUpFromWB_11_valid),
    .io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_11_bits_pdest(io_enqDelayIn1_wakeUpFromWB_11_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_10_valid(io_enqDelayIn1_wakeUpFromWB_10_valid),
    .io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_10_bits_pdest(io_enqDelayIn1_wakeUpFromWB_10_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_9_valid(io_enqDelayIn1_wakeUpFromWB_9_valid),
    .io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_9_bits_pdest(io_enqDelayIn1_wakeUpFromWB_9_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_8_valid(io_enqDelayIn1_wakeUpFromWB_8_valid),
    .io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_8_bits_pdest(io_enqDelayIn1_wakeUpFromWB_8_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_7_valid(io_enqDelayIn1_wakeUpFromWB_7_valid),
    .io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_7_bits_pdest(io_enqDelayIn1_wakeUpFromWB_7_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_6_valid(io_enqDelayIn1_wakeUpFromWB_6_valid),
    .io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_6_bits_pdest(io_enqDelayIn1_wakeUpFromWB_6_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_5_valid(io_enqDelayIn1_wakeUpFromWB_5_valid),
    .io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_5_bits_pdest(io_enqDelayIn1_wakeUpFromWB_5_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_4_valid(io_enqDelayIn1_wakeUpFromWB_4_valid),
    .io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_4_bits_pdest(io_enqDelayIn1_wakeUpFromWB_4_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_3_valid(io_enqDelayIn1_wakeUpFromWB_3_valid),
    .io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_3_bits_pdest(io_enqDelayIn1_wakeUpFromWB_3_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_2_valid(io_enqDelayIn1_wakeUpFromWB_2_valid),
    .io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_2_bits_pdest(io_enqDelayIn1_wakeUpFromWB_2_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_1_valid(io_enqDelayIn1_wakeUpFromWB_1_valid),
    .io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_1_bits_pdest(io_enqDelayIn1_wakeUpFromWB_1_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_0_valid(io_enqDelayIn1_wakeUpFromWB_0_valid),
    .io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_0_bits_pdest(io_enqDelayIn1_wakeUpFromWB_0_bits_pdest),
    .io_commonOut_valid(g_io_commonOut_valid),
    .io_commonOut_issued(g_io_commonOut_issued),
    .io_commonOut_canIssue(g_io_commonOut_canIssue),
    .io_commonOut_fuType(g_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(g_io_commonOut_dataSources_0_value),
    .io_commonOut_dataSources_1_value(g_io_commonOut_dataSources_1_value),
    .io_commonOut_dataSources_2_value(g_io_commonOut_dataSources_2_value),
    .io_commonOut_dataSources_3_value(g_io_commonOut_dataSources_3_value),
    .io_commonOut_dataSources_4_value(g_io_commonOut_dataSources_4_value),
    .io_commonOut_isFirstIssue(g_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(g_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(g_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_18(g_io_commonOut_entry_bits_status_fuType_18),
    .io_commonOut_entry_bits_status_fuType_19(g_io_commonOut_entry_bits_status_fuType_19),
    .io_commonOut_entry_bits_status_fuType_20(g_io_commonOut_entry_bits_status_fuType_20),
    .io_commonOut_entry_bits_status_fuType_21(g_io_commonOut_entry_bits_status_fuType_21),
    .io_commonOut_entry_bits_status_fuType_24(g_io_commonOut_entry_bits_status_fuType_24),
    .io_commonOut_entry_bits_status_fuType_25(g_io_commonOut_entry_bits_status_fuType_25),
    .io_commonOut_entry_bits_status_fuType_27(g_io_commonOut_entry_bits_status_fuType_27),
    .io_commonOut_entry_bits_status_fuType_30(g_io_commonOut_entry_bits_status_fuType_30),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(g_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(g_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_1_psrc(g_io_commonOut_entry_bits_status_srcStatus_1_psrc),
    .io_commonOut_entry_bits_status_srcStatus_1_srcType(g_io_commonOut_entry_bits_status_srcStatus_1_srcType),
    .io_commonOut_entry_bits_status_srcStatus_2_psrc(g_io_commonOut_entry_bits_status_srcStatus_2_psrc),
    .io_commonOut_entry_bits_status_srcStatus_2_srcType(g_io_commonOut_entry_bits_status_srcStatus_2_srcType),
    .io_commonOut_entry_bits_status_srcStatus_3_psrc(g_io_commonOut_entry_bits_status_srcStatus_3_psrc),
    .io_commonOut_entry_bits_status_srcStatus_3_srcType(g_io_commonOut_entry_bits_status_srcStatus_3_srcType),
    .io_commonOut_entry_bits_status_srcStatus_4_psrc(g_io_commonOut_entry_bits_status_srcStatus_4_psrc),
    .io_commonOut_entry_bits_status_srcStatus_4_srcType(g_io_commonOut_entry_bits_status_srcStatus_4_srcType),
    .io_commonOut_entry_bits_imm(g_io_commonOut_entry_bits_imm),
    .io_commonOut_entry_bits_payload_fuOpType(g_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(g_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(g_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_vecWen(g_io_commonOut_entry_bits_payload_vecWen),
    .io_commonOut_entry_bits_payload_v0Wen(g_io_commonOut_entry_bits_payload_v0Wen),
    .io_commonOut_entry_bits_payload_vlWen(g_io_commonOut_entry_bits_payload_vlWen),
    .io_commonOut_entry_bits_payload_selImm(g_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_fpu_typeTagOut(g_io_commonOut_entry_bits_payload_fpu_typeTagOut),
    .io_commonOut_entry_bits_payload_fpu_wflags(g_io_commonOut_entry_bits_payload_fpu_wflags),
    .io_commonOut_entry_bits_payload_fpu_typ(g_io_commonOut_entry_bits_payload_fpu_typ),
    .io_commonOut_entry_bits_payload_fpu_fmt(g_io_commonOut_entry_bits_payload_fpu_fmt),
    .io_commonOut_entry_bits_payload_fpu_rm(g_io_commonOut_entry_bits_payload_fpu_rm),
    .io_commonOut_entry_bits_payload_vpu_vill(g_io_commonOut_entry_bits_payload_vpu_vill),
    .io_commonOut_entry_bits_payload_vpu_vma(g_io_commonOut_entry_bits_payload_vpu_vma),
    .io_commonOut_entry_bits_payload_vpu_vta(g_io_commonOut_entry_bits_payload_vpu_vta),
    .io_commonOut_entry_bits_payload_vpu_vsew(g_io_commonOut_entry_bits_payload_vpu_vsew),
    .io_commonOut_entry_bits_payload_vpu_vlmul(g_io_commonOut_entry_bits_payload_vpu_vlmul),
    .io_commonOut_entry_bits_payload_vpu_specVill(g_io_commonOut_entry_bits_payload_vpu_specVill),
    .io_commonOut_entry_bits_payload_vpu_specVma(g_io_commonOut_entry_bits_payload_vpu_specVma),
    .io_commonOut_entry_bits_payload_vpu_specVta(g_io_commonOut_entry_bits_payload_vpu_specVta),
    .io_commonOut_entry_bits_payload_vpu_specVsew(g_io_commonOut_entry_bits_payload_vpu_specVsew),
    .io_commonOut_entry_bits_payload_vpu_specVlmul(g_io_commonOut_entry_bits_payload_vpu_specVlmul),
    .io_commonOut_entry_bits_payload_vpu_vm(g_io_commonOut_entry_bits_payload_vpu_vm),
    .io_commonOut_entry_bits_payload_vpu_vstart(g_io_commonOut_entry_bits_payload_vpu_vstart),
    .io_commonOut_entry_bits_payload_vpu_frm(g_io_commonOut_entry_bits_payload_vpu_frm),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst(g_io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr(g_io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr(g_io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonOut_entry_bits_payload_vpu_fpu_isReduction(g_io_commonOut_entry_bits_payload_vpu_fpu_isReduction),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2(g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4(g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8(g_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonOut_entry_bits_payload_vpu_vxrm(g_io_commonOut_entry_bits_payload_vpu_vxrm),
    .io_commonOut_entry_bits_payload_vpu_vmask(g_io_commonOut_entry_bits_payload_vpu_vmask),
    .io_commonOut_entry_bits_payload_vpu_vl(g_io_commonOut_entry_bits_payload_vpu_vl),
    .io_commonOut_entry_bits_payload_vpu_nf(g_io_commonOut_entry_bits_payload_vpu_nf),
    .io_commonOut_entry_bits_payload_vpu_veew(g_io_commonOut_entry_bits_payload_vpu_veew),
    .io_commonOut_entry_bits_payload_vpu_isReverse(g_io_commonOut_entry_bits_payload_vpu_isReverse),
    .io_commonOut_entry_bits_payload_vpu_isExt(g_io_commonOut_entry_bits_payload_vpu_isExt),
    .io_commonOut_entry_bits_payload_vpu_isNarrow(g_io_commonOut_entry_bits_payload_vpu_isNarrow),
    .io_commonOut_entry_bits_payload_vpu_isDstMask(g_io_commonOut_entry_bits_payload_vpu_isDstMask),
    .io_commonOut_entry_bits_payload_vpu_isOpMask(g_io_commonOut_entry_bits_payload_vpu_isOpMask),
    .io_commonOut_entry_bits_payload_vpu_isMove(g_io_commonOut_entry_bits_payload_vpu_isMove),
    .io_commonOut_entry_bits_payload_vpu_isDependOldVd(g_io_commonOut_entry_bits_payload_vpu_isDependOldVd),
    .io_commonOut_entry_bits_payload_vpu_isWritePartVd(g_io_commonOut_entry_bits_payload_vpu_isWritePartVd),
    .io_commonOut_entry_bits_payload_vpu_isVleff(g_io_commonOut_entry_bits_payload_vpu_isVleff),
    .io_commonOut_entry_bits_payload_uopIdx(g_io_commonOut_entry_bits_payload_uopIdx),
    .io_commonOut_entry_bits_payload_lastUop(g_io_commonOut_entry_bits_payload_lastUop),
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
    .io_commonOut_deqPortIdxRead(g_io_commonOut_deqPortIdxRead),
    .io_commonOut_issueTimerRead(g_io_commonOut_issueTimerRead),
    .io_commonOut_transEntry_valid(g_io_commonOut_transEntry_valid),
    .io_commonOut_transEntry_bits_status_robIdx_flag(g_io_commonOut_transEntry_bits_status_robIdx_flag),
    .io_commonOut_transEntry_bits_status_robIdx_value(g_io_commonOut_transEntry_bits_status_robIdx_value),
    .io_commonOut_transEntry_bits_status_fuType_18(g_io_commonOut_transEntry_bits_status_fuType_18),
    .io_commonOut_transEntry_bits_status_fuType_19(g_io_commonOut_transEntry_bits_status_fuType_19),
    .io_commonOut_transEntry_bits_status_fuType_20(g_io_commonOut_transEntry_bits_status_fuType_20),
    .io_commonOut_transEntry_bits_status_fuType_21(g_io_commonOut_transEntry_bits_status_fuType_21),
    .io_commonOut_transEntry_bits_status_fuType_24(g_io_commonOut_transEntry_bits_status_fuType_24),
    .io_commonOut_transEntry_bits_status_fuType_25(g_io_commonOut_transEntry_bits_status_fuType_25),
    .io_commonOut_transEntry_bits_status_fuType_27(g_io_commonOut_transEntry_bits_status_fuType_27),
    .io_commonOut_transEntry_bits_status_fuType_30(g_io_commonOut_transEntry_bits_status_fuType_30),
    .io_commonOut_transEntry_bits_status_srcStatus_0_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_0_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_1_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_1_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_1_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_1_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_2_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_2_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_2_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_2_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_3_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_3_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_3_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_3_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_4_psrc(g_io_commonOut_transEntry_bits_status_srcStatus_4_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcType(g_io_commonOut_transEntry_bits_status_srcStatus_4_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcState(g_io_commonOut_transEntry_bits_status_srcStatus_4_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value(g_io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0(g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1(g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2(g_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2),
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
    .io_commonOut_perfWakeupByWB_0(g_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByWB_1(g_io_commonOut_perfWakeupByWB_1),
    .io_commonOut_perfWakeupByWB_2(g_io_commonOut_perfWakeupByWB_2),
    .io_commonOut_perfWakeupByWB_3(g_io_commonOut_perfWakeupByWB_3),
    .io_commonOut_perfWakeupByWB_4(g_io_commonOut_perfWakeupByWB_4)
  );

  EnqEntry_14_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_18(io_commonIn_enq_bits_status_fuType_18),
    .io_commonIn_enq_bits_status_fuType_19(io_commonIn_enq_bits_status_fuType_19),
    .io_commonIn_enq_bits_status_fuType_20(io_commonIn_enq_bits_status_fuType_20),
    .io_commonIn_enq_bits_status_fuType_21(io_commonIn_enq_bits_status_fuType_21),
    .io_commonIn_enq_bits_status_fuType_24(io_commonIn_enq_bits_status_fuType_24),
    .io_commonIn_enq_bits_status_fuType_25(io_commonIn_enq_bits_status_fuType_25),
    .io_commonIn_enq_bits_status_fuType_27(io_commonIn_enq_bits_status_fuType_27),
    .io_commonIn_enq_bits_status_fuType_30(io_commonIn_enq_bits_status_fuType_30),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_psrc(io_commonIn_enq_bits_status_srcStatus_1_psrc),
    .io_commonIn_enq_bits_status_srcStatus_1_srcType(io_commonIn_enq_bits_status_srcStatus_1_srcType),
    .io_commonIn_enq_bits_status_srcStatus_1_srcState(io_commonIn_enq_bits_status_srcStatus_1_srcState),
    .io_commonIn_enq_bits_status_srcStatus_1_dataSources_value(io_commonIn_enq_bits_status_srcStatus_1_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_psrc(io_commonIn_enq_bits_status_srcStatus_2_psrc),
    .io_commonIn_enq_bits_status_srcStatus_2_srcType(io_commonIn_enq_bits_status_srcStatus_2_srcType),
    .io_commonIn_enq_bits_status_srcStatus_2_srcState(io_commonIn_enq_bits_status_srcStatus_2_srcState),
    .io_commonIn_enq_bits_status_srcStatus_2_dataSources_value(io_commonIn_enq_bits_status_srcStatus_2_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_3_psrc(io_commonIn_enq_bits_status_srcStatus_3_psrc),
    .io_commonIn_enq_bits_status_srcStatus_3_srcType(io_commonIn_enq_bits_status_srcStatus_3_srcType),
    .io_commonIn_enq_bits_status_srcStatus_3_srcState(io_commonIn_enq_bits_status_srcStatus_3_srcState),
    .io_commonIn_enq_bits_status_srcStatus_3_dataSources_value(io_commonIn_enq_bits_status_srcStatus_3_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_4_psrc(io_commonIn_enq_bits_status_srcStatus_4_psrc),
    .io_commonIn_enq_bits_status_srcStatus_4_srcType(io_commonIn_enq_bits_status_srcStatus_4_srcType),
    .io_commonIn_enq_bits_status_srcStatus_4_srcState(io_commonIn_enq_bits_status_srcStatus_4_srcState),
    .io_commonIn_enq_bits_status_srcStatus_4_dataSources_value(io_commonIn_enq_bits_status_srcStatus_4_dataSources_value),
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
    .io_commonIn_wakeUpFromWB_15_valid(io_commonIn_wakeUpFromWB_15_valid),
    .io_commonIn_wakeUpFromWB_15_bits_vlWen(io_commonIn_wakeUpFromWB_15_bits_vlWen),
    .io_commonIn_wakeUpFromWB_15_bits_pdest(io_commonIn_wakeUpFromWB_15_bits_pdest),
    .io_commonIn_wakeUpFromWB_14_valid(io_commonIn_wakeUpFromWB_14_valid),
    .io_commonIn_wakeUpFromWB_14_bits_vlWen(io_commonIn_wakeUpFromWB_14_bits_vlWen),
    .io_commonIn_wakeUpFromWB_14_bits_pdest(io_commonIn_wakeUpFromWB_14_bits_pdest),
    .io_commonIn_wakeUpFromWB_13_valid(io_commonIn_wakeUpFromWB_13_valid),
    .io_commonIn_wakeUpFromWB_13_bits_vlWen(io_commonIn_wakeUpFromWB_13_bits_vlWen),
    .io_commonIn_wakeUpFromWB_13_bits_pdest(io_commonIn_wakeUpFromWB_13_bits_pdest),
    .io_commonIn_wakeUpFromWB_12_valid(io_commonIn_wakeUpFromWB_12_valid),
    .io_commonIn_wakeUpFromWB_12_bits_vlWen(io_commonIn_wakeUpFromWB_12_bits_vlWen),
    .io_commonIn_wakeUpFromWB_12_bits_pdest(io_commonIn_wakeUpFromWB_12_bits_pdest),
    .io_commonIn_wakeUpFromWB_11_valid(io_commonIn_wakeUpFromWB_11_valid),
    .io_commonIn_wakeUpFromWB_11_bits_v0Wen(io_commonIn_wakeUpFromWB_11_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_11_bits_pdest(io_commonIn_wakeUpFromWB_11_bits_pdest),
    .io_commonIn_wakeUpFromWB_10_valid(io_commonIn_wakeUpFromWB_10_valid),
    .io_commonIn_wakeUpFromWB_10_bits_v0Wen(io_commonIn_wakeUpFromWB_10_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_10_bits_pdest(io_commonIn_wakeUpFromWB_10_bits_pdest),
    .io_commonIn_wakeUpFromWB_9_valid(io_commonIn_wakeUpFromWB_9_valid),
    .io_commonIn_wakeUpFromWB_9_bits_v0Wen(io_commonIn_wakeUpFromWB_9_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_9_bits_pdest(io_commonIn_wakeUpFromWB_9_bits_pdest),
    .io_commonIn_wakeUpFromWB_8_valid(io_commonIn_wakeUpFromWB_8_valid),
    .io_commonIn_wakeUpFromWB_8_bits_v0Wen(io_commonIn_wakeUpFromWB_8_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_8_bits_pdest(io_commonIn_wakeUpFromWB_8_bits_pdest),
    .io_commonIn_wakeUpFromWB_7_valid(io_commonIn_wakeUpFromWB_7_valid),
    .io_commonIn_wakeUpFromWB_7_bits_v0Wen(io_commonIn_wakeUpFromWB_7_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_7_bits_pdest(io_commonIn_wakeUpFromWB_7_bits_pdest),
    .io_commonIn_wakeUpFromWB_6_valid(io_commonIn_wakeUpFromWB_6_valid),
    .io_commonIn_wakeUpFromWB_6_bits_v0Wen(io_commonIn_wakeUpFromWB_6_bits_v0Wen),
    .io_commonIn_wakeUpFromWB_6_bits_pdest(io_commonIn_wakeUpFromWB_6_bits_pdest),
    .io_commonIn_wakeUpFromWB_5_valid(io_commonIn_wakeUpFromWB_5_valid),
    .io_commonIn_wakeUpFromWB_5_bits_vecWen(io_commonIn_wakeUpFromWB_5_bits_vecWen),
    .io_commonIn_wakeUpFromWB_5_bits_pdest(io_commonIn_wakeUpFromWB_5_bits_pdest),
    .io_commonIn_wakeUpFromWB_4_valid(io_commonIn_wakeUpFromWB_4_valid),
    .io_commonIn_wakeUpFromWB_4_bits_vecWen(io_commonIn_wakeUpFromWB_4_bits_vecWen),
    .io_commonIn_wakeUpFromWB_4_bits_pdest(io_commonIn_wakeUpFromWB_4_bits_pdest),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_vecWen(io_commonIn_wakeUpFromWB_3_bits_vecWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_vecWen(io_commonIn_wakeUpFromWB_2_bits_vecWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_vecWen(io_commonIn_wakeUpFromWB_1_bits_vecWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_vecWen(io_commonIn_wakeUpFromWB_0_bits_vecWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_vlFromIntIsZero(io_commonIn_vlFromIntIsZero),
    .io_commonIn_vlFromIntIsVlmax(io_commonIn_vlFromIntIsVlmax),
    .io_commonIn_vlFromVfIsZero(io_commonIn_vlFromVfIsZero),
    .io_commonIn_vlFromVfIsVlmax(io_commonIn_vlFromVfIsVlmax),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_deqPortIdxWrite(io_commonIn_deqPortIdxWrite),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonIn_transSel(io_commonIn_transSel),
    .io_enqDelayIn1_wakeUpFromWB_15_valid(io_enqDelayIn1_wakeUpFromWB_15_valid),
    .io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_15_bits_pdest(io_enqDelayIn1_wakeUpFromWB_15_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_14_valid(io_enqDelayIn1_wakeUpFromWB_14_valid),
    .io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_14_bits_pdest(io_enqDelayIn1_wakeUpFromWB_14_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_13_valid(io_enqDelayIn1_wakeUpFromWB_13_valid),
    .io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_13_bits_pdest(io_enqDelayIn1_wakeUpFromWB_13_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_12_valid(io_enqDelayIn1_wakeUpFromWB_12_valid),
    .io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen(io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen),
    .io_enqDelayIn1_wakeUpFromWB_12_bits_pdest(io_enqDelayIn1_wakeUpFromWB_12_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_11_valid(io_enqDelayIn1_wakeUpFromWB_11_valid),
    .io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_11_bits_pdest(io_enqDelayIn1_wakeUpFromWB_11_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_10_valid(io_enqDelayIn1_wakeUpFromWB_10_valid),
    .io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_10_bits_pdest(io_enqDelayIn1_wakeUpFromWB_10_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_9_valid(io_enqDelayIn1_wakeUpFromWB_9_valid),
    .io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_9_bits_pdest(io_enqDelayIn1_wakeUpFromWB_9_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_8_valid(io_enqDelayIn1_wakeUpFromWB_8_valid),
    .io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_8_bits_pdest(io_enqDelayIn1_wakeUpFromWB_8_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_7_valid(io_enqDelayIn1_wakeUpFromWB_7_valid),
    .io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_7_bits_pdest(io_enqDelayIn1_wakeUpFromWB_7_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_6_valid(io_enqDelayIn1_wakeUpFromWB_6_valid),
    .io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen(io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen),
    .io_enqDelayIn1_wakeUpFromWB_6_bits_pdest(io_enqDelayIn1_wakeUpFromWB_6_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_5_valid(io_enqDelayIn1_wakeUpFromWB_5_valid),
    .io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_5_bits_pdest(io_enqDelayIn1_wakeUpFromWB_5_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_4_valid(io_enqDelayIn1_wakeUpFromWB_4_valid),
    .io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_4_bits_pdest(io_enqDelayIn1_wakeUpFromWB_4_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_3_valid(io_enqDelayIn1_wakeUpFromWB_3_valid),
    .io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_3_bits_pdest(io_enqDelayIn1_wakeUpFromWB_3_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_2_valid(io_enqDelayIn1_wakeUpFromWB_2_valid),
    .io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_2_bits_pdest(io_enqDelayIn1_wakeUpFromWB_2_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_1_valid(io_enqDelayIn1_wakeUpFromWB_1_valid),
    .io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_1_bits_pdest(io_enqDelayIn1_wakeUpFromWB_1_bits_pdest),
    .io_enqDelayIn1_wakeUpFromWB_0_valid(io_enqDelayIn1_wakeUpFromWB_0_valid),
    .io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen(io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen),
    .io_enqDelayIn1_wakeUpFromWB_0_bits_pdest(io_enqDelayIn1_wakeUpFromWB_0_bits_pdest),
    .io_commonOut_valid(i_io_commonOut_valid),
    .io_commonOut_issued(i_io_commonOut_issued),
    .io_commonOut_canIssue(i_io_commonOut_canIssue),
    .io_commonOut_fuType(i_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(i_io_commonOut_dataSources_0_value),
    .io_commonOut_dataSources_1_value(i_io_commonOut_dataSources_1_value),
    .io_commonOut_dataSources_2_value(i_io_commonOut_dataSources_2_value),
    .io_commonOut_dataSources_3_value(i_io_commonOut_dataSources_3_value),
    .io_commonOut_dataSources_4_value(i_io_commonOut_dataSources_4_value),
    .io_commonOut_isFirstIssue(i_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(i_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(i_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_18(i_io_commonOut_entry_bits_status_fuType_18),
    .io_commonOut_entry_bits_status_fuType_19(i_io_commonOut_entry_bits_status_fuType_19),
    .io_commonOut_entry_bits_status_fuType_20(i_io_commonOut_entry_bits_status_fuType_20),
    .io_commonOut_entry_bits_status_fuType_21(i_io_commonOut_entry_bits_status_fuType_21),
    .io_commonOut_entry_bits_status_fuType_24(i_io_commonOut_entry_bits_status_fuType_24),
    .io_commonOut_entry_bits_status_fuType_25(i_io_commonOut_entry_bits_status_fuType_25),
    .io_commonOut_entry_bits_status_fuType_27(i_io_commonOut_entry_bits_status_fuType_27),
    .io_commonOut_entry_bits_status_fuType_30(i_io_commonOut_entry_bits_status_fuType_30),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(i_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(i_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_1_psrc(i_io_commonOut_entry_bits_status_srcStatus_1_psrc),
    .io_commonOut_entry_bits_status_srcStatus_1_srcType(i_io_commonOut_entry_bits_status_srcStatus_1_srcType),
    .io_commonOut_entry_bits_status_srcStatus_2_psrc(i_io_commonOut_entry_bits_status_srcStatus_2_psrc),
    .io_commonOut_entry_bits_status_srcStatus_2_srcType(i_io_commonOut_entry_bits_status_srcStatus_2_srcType),
    .io_commonOut_entry_bits_status_srcStatus_3_psrc(i_io_commonOut_entry_bits_status_srcStatus_3_psrc),
    .io_commonOut_entry_bits_status_srcStatus_3_srcType(i_io_commonOut_entry_bits_status_srcStatus_3_srcType),
    .io_commonOut_entry_bits_status_srcStatus_4_psrc(i_io_commonOut_entry_bits_status_srcStatus_4_psrc),
    .io_commonOut_entry_bits_status_srcStatus_4_srcType(i_io_commonOut_entry_bits_status_srcStatus_4_srcType),
    .io_commonOut_entry_bits_imm(i_io_commonOut_entry_bits_imm),
    .io_commonOut_entry_bits_payload_fuOpType(i_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(i_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(i_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_vecWen(i_io_commonOut_entry_bits_payload_vecWen),
    .io_commonOut_entry_bits_payload_v0Wen(i_io_commonOut_entry_bits_payload_v0Wen),
    .io_commonOut_entry_bits_payload_vlWen(i_io_commonOut_entry_bits_payload_vlWen),
    .io_commonOut_entry_bits_payload_selImm(i_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_fpu_typeTagOut(i_io_commonOut_entry_bits_payload_fpu_typeTagOut),
    .io_commonOut_entry_bits_payload_fpu_wflags(i_io_commonOut_entry_bits_payload_fpu_wflags),
    .io_commonOut_entry_bits_payload_fpu_typ(i_io_commonOut_entry_bits_payload_fpu_typ),
    .io_commonOut_entry_bits_payload_fpu_fmt(i_io_commonOut_entry_bits_payload_fpu_fmt),
    .io_commonOut_entry_bits_payload_fpu_rm(i_io_commonOut_entry_bits_payload_fpu_rm),
    .io_commonOut_entry_bits_payload_vpu_vill(i_io_commonOut_entry_bits_payload_vpu_vill),
    .io_commonOut_entry_bits_payload_vpu_vma(i_io_commonOut_entry_bits_payload_vpu_vma),
    .io_commonOut_entry_bits_payload_vpu_vta(i_io_commonOut_entry_bits_payload_vpu_vta),
    .io_commonOut_entry_bits_payload_vpu_vsew(i_io_commonOut_entry_bits_payload_vpu_vsew),
    .io_commonOut_entry_bits_payload_vpu_vlmul(i_io_commonOut_entry_bits_payload_vpu_vlmul),
    .io_commonOut_entry_bits_payload_vpu_specVill(i_io_commonOut_entry_bits_payload_vpu_specVill),
    .io_commonOut_entry_bits_payload_vpu_specVma(i_io_commonOut_entry_bits_payload_vpu_specVma),
    .io_commonOut_entry_bits_payload_vpu_specVta(i_io_commonOut_entry_bits_payload_vpu_specVta),
    .io_commonOut_entry_bits_payload_vpu_specVsew(i_io_commonOut_entry_bits_payload_vpu_specVsew),
    .io_commonOut_entry_bits_payload_vpu_specVlmul(i_io_commonOut_entry_bits_payload_vpu_specVlmul),
    .io_commonOut_entry_bits_payload_vpu_vm(i_io_commonOut_entry_bits_payload_vpu_vm),
    .io_commonOut_entry_bits_payload_vpu_vstart(i_io_commonOut_entry_bits_payload_vpu_vstart),
    .io_commonOut_entry_bits_payload_vpu_frm(i_io_commonOut_entry_bits_payload_vpu_frm),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst(i_io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr(i_io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr(i_io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr),
    .io_commonOut_entry_bits_payload_vpu_fpu_isReduction(i_io_commonOut_entry_bits_payload_vpu_fpu_isReduction),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2(i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4(i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8(i_io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_commonOut_entry_bits_payload_vpu_vxrm(i_io_commonOut_entry_bits_payload_vpu_vxrm),
    .io_commonOut_entry_bits_payload_vpu_vmask(i_io_commonOut_entry_bits_payload_vpu_vmask),
    .io_commonOut_entry_bits_payload_vpu_vl(i_io_commonOut_entry_bits_payload_vpu_vl),
    .io_commonOut_entry_bits_payload_vpu_nf(i_io_commonOut_entry_bits_payload_vpu_nf),
    .io_commonOut_entry_bits_payload_vpu_veew(i_io_commonOut_entry_bits_payload_vpu_veew),
    .io_commonOut_entry_bits_payload_vpu_isReverse(i_io_commonOut_entry_bits_payload_vpu_isReverse),
    .io_commonOut_entry_bits_payload_vpu_isExt(i_io_commonOut_entry_bits_payload_vpu_isExt),
    .io_commonOut_entry_bits_payload_vpu_isNarrow(i_io_commonOut_entry_bits_payload_vpu_isNarrow),
    .io_commonOut_entry_bits_payload_vpu_isDstMask(i_io_commonOut_entry_bits_payload_vpu_isDstMask),
    .io_commonOut_entry_bits_payload_vpu_isOpMask(i_io_commonOut_entry_bits_payload_vpu_isOpMask),
    .io_commonOut_entry_bits_payload_vpu_isMove(i_io_commonOut_entry_bits_payload_vpu_isMove),
    .io_commonOut_entry_bits_payload_vpu_isDependOldVd(i_io_commonOut_entry_bits_payload_vpu_isDependOldVd),
    .io_commonOut_entry_bits_payload_vpu_isWritePartVd(i_io_commonOut_entry_bits_payload_vpu_isWritePartVd),
    .io_commonOut_entry_bits_payload_vpu_isVleff(i_io_commonOut_entry_bits_payload_vpu_isVleff),
    .io_commonOut_entry_bits_payload_uopIdx(i_io_commonOut_entry_bits_payload_uopIdx),
    .io_commonOut_entry_bits_payload_lastUop(i_io_commonOut_entry_bits_payload_lastUop),
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
    .io_commonOut_deqPortIdxRead(i_io_commonOut_deqPortIdxRead),
    .io_commonOut_issueTimerRead(i_io_commonOut_issueTimerRead),
    .io_commonOut_transEntry_valid(i_io_commonOut_transEntry_valid),
    .io_commonOut_transEntry_bits_status_robIdx_flag(i_io_commonOut_transEntry_bits_status_robIdx_flag),
    .io_commonOut_transEntry_bits_status_robIdx_value(i_io_commonOut_transEntry_bits_status_robIdx_value),
    .io_commonOut_transEntry_bits_status_fuType_18(i_io_commonOut_transEntry_bits_status_fuType_18),
    .io_commonOut_transEntry_bits_status_fuType_19(i_io_commonOut_transEntry_bits_status_fuType_19),
    .io_commonOut_transEntry_bits_status_fuType_20(i_io_commonOut_transEntry_bits_status_fuType_20),
    .io_commonOut_transEntry_bits_status_fuType_21(i_io_commonOut_transEntry_bits_status_fuType_21),
    .io_commonOut_transEntry_bits_status_fuType_24(i_io_commonOut_transEntry_bits_status_fuType_24),
    .io_commonOut_transEntry_bits_status_fuType_25(i_io_commonOut_transEntry_bits_status_fuType_25),
    .io_commonOut_transEntry_bits_status_fuType_27(i_io_commonOut_transEntry_bits_status_fuType_27),
    .io_commonOut_transEntry_bits_status_fuType_30(i_io_commonOut_transEntry_bits_status_fuType_30),
    .io_commonOut_transEntry_bits_status_srcStatus_0_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_0_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_1_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_1_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_1_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_1_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_2_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_2_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_2_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_2_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_3_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_3_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_3_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_3_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2),
    .io_commonOut_transEntry_bits_status_srcStatus_4_psrc(i_io_commonOut_transEntry_bits_status_srcStatus_4_psrc),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcType(i_io_commonOut_transEntry_bits_status_srcStatus_4_srcType),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcState(i_io_commonOut_transEntry_bits_status_srcStatus_4_srcState),
    .io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value(i_io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0(i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1(i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1),
    .io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2(i_io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2),
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
    .io_commonOut_perfWakeupByWB_0(i_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByWB_1(i_io_commonOut_perfWakeupByWB_1),
    .io_commonOut_perfWakeupByWB_2(i_io_commonOut_perfWakeupByWB_2),
    .io_commonOut_perfWakeupByWB_3(i_io_commonOut_perfWakeupByWB_3),
    .io_commonOut_perfWakeupByWB_4(i_io_commonOut_perfWakeupByWB_4)
  );

  task automatic check_outputs();
    `CHK(io_commonOut_valid)
    `CHK(io_commonOut_issued)
    `CHK(io_commonOut_canIssue)
    `CHK(io_commonOut_fuType)
    `CHK(io_commonOut_dataSources_0_value)
    `CHK(io_commonOut_dataSources_1_value)
    `CHK(io_commonOut_dataSources_2_value)
    `CHK(io_commonOut_dataSources_3_value)
    `CHK(io_commonOut_dataSources_4_value)
    `CHK(io_commonOut_isFirstIssue)
    `CHK(io_commonOut_entry_bits_status_robIdx_flag)
    `CHK(io_commonOut_entry_bits_status_robIdx_value)
    `CHK(io_commonOut_entry_bits_status_fuType_18)
    `CHK(io_commonOut_entry_bits_status_fuType_19)
    `CHK(io_commonOut_entry_bits_status_fuType_20)
    `CHK(io_commonOut_entry_bits_status_fuType_21)
    `CHK(io_commonOut_entry_bits_status_fuType_24)
    `CHK(io_commonOut_entry_bits_status_fuType_25)
    `CHK(io_commonOut_entry_bits_status_fuType_27)
    `CHK(io_commonOut_entry_bits_status_fuType_30)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_1_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_1_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_2_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_2_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_3_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_3_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_4_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_4_srcType)
    `CHK(io_commonOut_entry_bits_imm)
    `CHK(io_commonOut_entry_bits_payload_fuOpType)
    `CHK(io_commonOut_entry_bits_payload_rfWen)
    `CHK(io_commonOut_entry_bits_payload_fpWen)
    `CHK(io_commonOut_entry_bits_payload_vecWen)
    `CHK(io_commonOut_entry_bits_payload_v0Wen)
    `CHK(io_commonOut_entry_bits_payload_vlWen)
    `CHK(io_commonOut_entry_bits_payload_selImm)
    `CHK(io_commonOut_entry_bits_payload_fpu_typeTagOut)
    `CHK(io_commonOut_entry_bits_payload_fpu_wflags)
    `CHK(io_commonOut_entry_bits_payload_fpu_typ)
    `CHK(io_commonOut_entry_bits_payload_fpu_fmt)
    `CHK(io_commonOut_entry_bits_payload_fpu_rm)
    `CHK(io_commonOut_entry_bits_payload_vpu_vill)
    `CHK(io_commonOut_entry_bits_payload_vpu_vma)
    `CHK(io_commonOut_entry_bits_payload_vpu_vta)
    `CHK(io_commonOut_entry_bits_payload_vpu_vsew)
    `CHK(io_commonOut_entry_bits_payload_vpu_vlmul)
    `CHK(io_commonOut_entry_bits_payload_vpu_specVill)
    `CHK(io_commonOut_entry_bits_payload_vpu_specVma)
    `CHK(io_commonOut_entry_bits_payload_vpu_specVta)
    `CHK(io_commonOut_entry_bits_payload_vpu_specVsew)
    `CHK(io_commonOut_entry_bits_payload_vpu_specVlmul)
    `CHK(io_commonOut_entry_bits_payload_vpu_vm)
    `CHK(io_commonOut_entry_bits_payload_vpu_vstart)
    `CHK(io_commonOut_entry_bits_payload_vpu_frm)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isReduction)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4)
    `CHK(io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8)
    `CHK(io_commonOut_entry_bits_payload_vpu_vxrm)
    `CHK(io_commonOut_entry_bits_payload_vpu_vmask)
    `CHK(io_commonOut_entry_bits_payload_vpu_vl)
    `CHK(io_commonOut_entry_bits_payload_vpu_nf)
    `CHK(io_commonOut_entry_bits_payload_vpu_veew)
    `CHK(io_commonOut_entry_bits_payload_vpu_isReverse)
    `CHK(io_commonOut_entry_bits_payload_vpu_isExt)
    `CHK(io_commonOut_entry_bits_payload_vpu_isNarrow)
    `CHK(io_commonOut_entry_bits_payload_vpu_isDstMask)
    `CHK(io_commonOut_entry_bits_payload_vpu_isOpMask)
    `CHK(io_commonOut_entry_bits_payload_vpu_isMove)
    `CHK(io_commonOut_entry_bits_payload_vpu_isDependOldVd)
    `CHK(io_commonOut_entry_bits_payload_vpu_isWritePartVd)
    `CHK(io_commonOut_entry_bits_payload_vpu_isVleff)
    `CHK(io_commonOut_entry_bits_payload_uopIdx)
    `CHK(io_commonOut_entry_bits_payload_lastUop)
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
    `CHK(io_commonOut_deqPortIdxRead)
    `CHK(io_commonOut_issueTimerRead)
    `CHK(io_commonOut_transEntry_valid)
    `CHK(io_commonOut_transEntry_bits_status_robIdx_flag)
    `CHK(io_commonOut_transEntry_bits_status_robIdx_value)
    `CHK(io_commonOut_transEntry_bits_status_fuType_18)
    `CHK(io_commonOut_transEntry_bits_status_fuType_19)
    `CHK(io_commonOut_transEntry_bits_status_fuType_20)
    `CHK(io_commonOut_transEntry_bits_status_fuType_21)
    `CHK(io_commonOut_transEntry_bits_status_fuType_24)
    `CHK(io_commonOut_transEntry_bits_status_fuType_25)
    `CHK(io_commonOut_transEntry_bits_status_fuType_27)
    `CHK(io_commonOut_transEntry_bits_status_fuType_30)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_psrc)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_srcType)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_srcState)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1)
    `CHK(io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2)
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
    `CHK(io_commonOut_perfWakeupByWB_0)
    `CHK(io_commonOut_perfWakeupByWB_1)
    `CHK(io_commonOut_perfWakeupByWB_2)
    `CHK(io_commonOut_perfWakeupByWB_3)
    `CHK(io_commonOut_perfWakeupByWB_4)
  endtask

  localparam int POOL = 8;   // pdest/psrc 共用的小池，保证唤醒能打中
  // *** +nopool：覆盖闸的双向负测开关 ***
  //   把小池换成整个 psrc 空间，唤醒就几乎永远打不中在队 uop 的源。
  //   电路一个字没改，只是激励退化 —— 这一轮**必须**把覆盖闸打红。
  bit nopool = 0;
  function automatic int rnd_reg();
    return nopool ? $urandom_range(0, 127)
                  : $urandom_range(0, POOL-1);
  endfunction

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
    io_commonIn_enq_bits_status_fuType_18 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_19 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_20 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_21 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_24 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_25 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_27 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_30 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_srcStatus_0_psrc <= 7'(rnd_reg());
    // src0 的 WB 唤醒门控位是 srcType[2]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_0_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_0_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_0_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_1_psrc <= 7'(rnd_reg());
    // src1 的 WB 唤醒门控位是 srcType[2]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_1_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_1_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_1_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_2_psrc <= 7'(rnd_reg());
    // src2 的 WB 唤醒门控位是 srcType[2]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_2_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_2_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_2_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_3_psrc <= 7'(rnd_reg());
    // src3 的 WB 唤醒门控位是 srcType[3]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_3_srcType <= ($urandom_range(0,99) < 88) ? 4'h8 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_3_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_3_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_4_psrc <= 7'(rnd_reg());
    // src4 的 WB 唤醒门控位是 srcType[2]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_4_srcType <= ($urandom_range(0,99) < 88) ? 4'h4 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_4_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_4_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）
    io_commonIn_enq_bits_imm <= 15'($urandom());
    io_commonIn_enq_bits_payload_fuOpType <= 9'($urandom());
    io_commonIn_enq_bits_payload_rfWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_fpWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_vecWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_v0Wen <= 1'($urandom());
    io_commonIn_enq_bits_payload_vlWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_selImm <= 4'($urandom());
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
    io_commonIn_enq_bits_payload_uopIdx <= 7'($urandom());
    io_commonIn_enq_bits_payload_lastUop <= 1'($urandom());
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
    io_commonIn_enq_bits_payload_preDecodeInfo_valid <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isRVC <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_brType <= 2'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isCall <= 1'($urandom());
    io_commonIn_enq_bits_payload_preDecodeInfo_isRet <= 1'($urandom());
    io_commonIn_enq_bits_payload_pred_taken <= 1'($urandom());
    io_commonIn_enq_bits_payload_crossPageIPFFix <= 1'($urandom());
    io_commonIn_enq_bits_payload_ftqPtr_flag <= 1'($urandom());
    io_commonIn_enq_bits_payload_ftqPtr_value <= 6'($urandom());
    io_commonIn_enq_bits_payload_ftqOffset <= 4'($urandom());
    io_commonIn_enq_bits_payload_satpFlushFirstFetchFault <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcType_0 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_1 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_2 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_3 <= 4'($urandom());
    io_commonIn_enq_bits_payload_srcType_4 <= 4'($urandom());
    io_commonIn_enq_bits_payload_ldest <= 6'($urandom());
    io_commonIn_enq_bits_payload_fuType <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_isXSTrap <= 1'($urandom());
    io_commonIn_enq_bits_payload_waitForward <= 1'($urandom());
    io_commonIn_enq_bits_payload_blockBackward <= 1'($urandom());
    io_commonIn_enq_bits_payload_flushPipe <= 1'($urandom());
    io_commonIn_enq_bits_payload_canRobCompress <= 1'($urandom());
    io_commonIn_enq_bits_payload_imm <= 32'($urandom());
    io_commonIn_enq_bits_payload_vpu_vuopIdx <= 7'($urandom());
    io_commonIn_enq_bits_payload_vpu_lastUop <= 1'($urandom());
    io_commonIn_enq_bits_payload_vlsInstr <= 1'($urandom());
    io_commonIn_enq_bits_payload_wfflags <= 1'($urandom());
    io_commonIn_enq_bits_payload_isMove <= 1'($urandom());
    io_commonIn_enq_bits_payload_isDropAmocasSta <= 1'($urandom());
    io_commonIn_enq_bits_payload_isVset <= 1'($urandom());
    io_commonIn_enq_bits_payload_firstUop <= 1'($urandom());
    io_commonIn_enq_bits_payload_numUops <= 7'($urandom());
    io_commonIn_enq_bits_payload_numWB <= 7'($urandom());
    io_commonIn_enq_bits_payload_commitType <= 3'($urandom());
    io_commonIn_enq_bits_payload_srcState_0 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_1 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_2 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_3 <= 1'($urandom());
    io_commonIn_enq_bits_payload_srcState_4 <= 1'($urandom());
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
    io_commonIn_enq_bits_payload_singleStep <= 1'($urandom());
    io_commonIn_enq_bits_payload_replayInst <= 1'($urandom());
    io_commonIn_enq_bits_payload_debug_fuType <= {$urandom(), $urandom(), $urandom()};
    io_commonIn_enq_bits_payload_debug_sim_trig <= 1'($urandom());
    io_commonIn_enq_bits_payload_numLsElem <= 5'($urandom());
    // 唤醒总线：当拍一组 + 入队延迟窗口一组（本族专属），两组共用同一个小池
    io_commonIn_wakeUpFromWB_0_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_0_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_0_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_1_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_1_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_1_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_2_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_2_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_2_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_3_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_3_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_3_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_4_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_4_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_4_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_5_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_5_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_5_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_6_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_6_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_6_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_7_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_7_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_7_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_8_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_8_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_8_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_9_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_9_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_9_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_10_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_10_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_10_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_11_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_11_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_11_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_12_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_12_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_12_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_13_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_13_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_13_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_14_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_14_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_14_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_15_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_15_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_15_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_0_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_0_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_1_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_1_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_2_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_2_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_3_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_3_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_4_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_4_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_5_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_5_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_6_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_6_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_7_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_7_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_8_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_8_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_9_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_9_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_10_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_10_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_11_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_11_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_12_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_12_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_13_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_13_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_14_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_14_bits_pdest <= 8'(rnd_reg());
    io_enqDelayIn1_wakeUpFromWB_15_valid <= ($urandom_range(0, 99) < 55);
    io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen <= ($urandom_range(0, 99) < 85);
    io_enqDelayIn1_wakeUpFromWB_15_bits_pdest <= 8'(rnd_reg());
    // enqDelayIn1.srcLoadDependency：Entries 在入队瞬间存下的那份影子
    io_commonIn_vlFromIntIsZero <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromIntIsVlmax <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromVfIsZero <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromVfIsVlmax <= ($urandom_range(0, 99) < 35);
    io_commonIn_deqPortIdxWrite <= ($urandom_range(0, 99) < 30);
    // issueResp：三种响应都要回到（BLOCK=0 / UNCERTAIN=1 / SUCCESS=3）
    io_commonIn_issueResp_valid <= ($urandom_range(0, 99) < 35);
    io_commonIn_issueResp_bits_resp <= (2'($urandom_range(0, 2)) == 2'd2) ? 2'd3 : 2'($urandom_range(0, 1));
  endtask

  // ---- deqSel / transSel：必须在时钟沿之前按 golden 当拍的输出算 ----
  // 纯随机给的话命中 canIssue 的概率极低，发射通路整轮不动（假绿的头号来源）。
  task automatic drive_sel();
    io_commonIn_deqSel = g_io_commonOut_canIssue && ($urandom_range(0, 99) < 70);
    io_commonIn_transSel = g_io_commonOut_valid && ($urandom_range(0, 99) < 25);
  endtask

  // ---- 入队延迟窗口的激励侧记账 ----
  // golden: enqDelayValidReg <= enq.valid && enqReady，enqReady = !valid || transSel。
  // valid 就是 commonOut.valid（golden 的输出），transSel/enq_valid 是本 tb 发的，
  // 所以窗口条件可以在 tb 里**从激励和 golden 输出**算出来，不需要给 DUT 建模。
  bit dly_win = 0;            // 本拍窗口开着
  bit will_load;              // 本拍沿上条目会被装载
  logic [6:0] eq_psrc  [5];   // 开窗那次入队的 psrc
  logic [3:0]            eq_stype [5];   // 开窗那次入队的 srcType
  bit dly_hit;

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
    if (g_io_commonOut_perfWakeupByWB_0 || g_io_commonOut_perfWakeupByWB_1 || g_io_commonOut_perfWakeupByWB_2 || g_io_commonOut_perfWakeupByWB_3 || g_io_commonOut_perfWakeupByWB_4) cov_wb_wake++;
    if (g_io_commonOut_entryOutTransValid) cov_trans_fire++;
    if (io_commonIn_enq_valid && g_io_commonOut_valid) cov_enq_while_valid++;
    if (io_commonIn_vlFromIntIsZero || io_commonIn_vlFromVfIsZero) cov_ignore_old_vd++;
    // --- 本族专属：入队延迟唤醒窗口 ---
    if (dly_win) begin
      cov_enq_delay_win++;
      dly_hit = 1'b0;
      // 延迟总线里有没有一路真打中刚入队那个 uop 的源（路由表与核的参数同源）
      if (io_enqDelayIn1_wakeUpFromWB_0_valid && io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_0_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_1_valid && io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_1_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_2_valid && io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_2_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_3_valid && io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_3_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_4_valid && io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_4_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_5_valid && io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen && eq_stype[0][2] && io_enqDelayIn1_wakeUpFromWB_5_bits_pdest == 8'(eq_psrc[0])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_0_valid && io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_0_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_1_valid && io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_1_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_2_valid && io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_2_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_3_valid && io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_3_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_4_valid && io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_4_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_5_valid && io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen && eq_stype[1][2] && io_enqDelayIn1_wakeUpFromWB_5_bits_pdest == 8'(eq_psrc[1])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_0_valid && io_enqDelayIn1_wakeUpFromWB_0_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_0_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_1_valid && io_enqDelayIn1_wakeUpFromWB_1_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_1_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_2_valid && io_enqDelayIn1_wakeUpFromWB_2_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_2_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_3_valid && io_enqDelayIn1_wakeUpFromWB_3_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_3_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_4_valid && io_enqDelayIn1_wakeUpFromWB_4_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_4_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_5_valid && io_enqDelayIn1_wakeUpFromWB_5_bits_vecWen && eq_stype[2][2] && io_enqDelayIn1_wakeUpFromWB_5_bits_pdest == 8'(eq_psrc[2])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_6_valid && io_enqDelayIn1_wakeUpFromWB_6_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_6_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_7_valid && io_enqDelayIn1_wakeUpFromWB_7_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_7_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_8_valid && io_enqDelayIn1_wakeUpFromWB_8_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_8_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_9_valid && io_enqDelayIn1_wakeUpFromWB_9_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_9_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_10_valid && io_enqDelayIn1_wakeUpFromWB_10_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_10_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_11_valid && io_enqDelayIn1_wakeUpFromWB_11_bits_v0Wen && eq_stype[3][3] && io_enqDelayIn1_wakeUpFromWB_11_bits_pdest == 8'(eq_psrc[3])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_12_valid && io_enqDelayIn1_wakeUpFromWB_12_bits_vlWen && eq_stype[4][2] && io_enqDelayIn1_wakeUpFromWB_12_bits_pdest == 8'(eq_psrc[4])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_13_valid && io_enqDelayIn1_wakeUpFromWB_13_bits_vlWen && eq_stype[4][2] && io_enqDelayIn1_wakeUpFromWB_13_bits_pdest == 8'(eq_psrc[4])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_14_valid && io_enqDelayIn1_wakeUpFromWB_14_bits_vlWen && eq_stype[4][2] && io_enqDelayIn1_wakeUpFromWB_14_bits_pdest == 8'(eq_psrc[4])) dly_hit = 1'b1;
      if (io_enqDelayIn1_wakeUpFromWB_15_valid && io_enqDelayIn1_wakeUpFromWB_15_bits_vlWen && eq_stype[4][2] && io_enqDelayIn1_wakeUpFromWB_15_bits_pdest == 8'(eq_psrc[4])) dly_hit = 1'b1;
      if (dly_hit) cov_enq_delay_wake++;
    end
    // 窗口寄存器的次态：本拍沿上装载成功 -> 下一拍开窗
    will_load = io_commonIn_enq_valid && (!g_io_commonOut_valid || io_commonIn_transSel);
    if (will_load) begin
      eq_psrc[0]  <= io_commonIn_enq_bits_status_srcStatus_0_psrc;
      eq_stype[0] <= io_commonIn_enq_bits_status_srcStatus_0_srcType;
      eq_psrc[1]  <= io_commonIn_enq_bits_status_srcStatus_1_psrc;
      eq_stype[1] <= io_commonIn_enq_bits_status_srcStatus_1_srcType;
      eq_psrc[2]  <= io_commonIn_enq_bits_status_srcStatus_2_psrc;
      eq_stype[2] <= io_commonIn_enq_bits_status_srcStatus_2_srcType;
      eq_psrc[3]  <= io_commonIn_enq_bits_status_srcStatus_3_psrc;
      eq_stype[3] <= io_commonIn_enq_bits_status_srcStatus_3_srcType;
      eq_psrc[4]  <= io_commonIn_enq_bits_status_srcStatus_4_psrc;
      eq_stype[4] <= io_commonIn_enq_bits_status_srcStatus_4_srcType;
    end
    dly_win = will_load;
  endtask

  longint cyc = 0;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    nopool = $test$plusargs("nopool");
    MINCOV["enq_fire"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["wb_wake"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["can_issue"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["deq_fire"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["resp_succ"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["resp_block"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["resp_uncertain"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["deq_clear"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["flush_hit"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["trans_fire"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["enq_while_valid"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["enq_delay_win"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["enq_delay_wake"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
    MINCOV["ignore_old_vd"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
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
        covchk("enq_delay_win", cov_enq_delay_win);
        covchk("enq_delay_wake", cov_enq_delay_wake);
        covchk("ignore_old_vd", cov_ignore_old_vd);
        if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
        else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);
        $finish;
      end
    end
  end
endmodule
