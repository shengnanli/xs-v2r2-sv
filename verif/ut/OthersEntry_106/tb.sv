// OthersEntry_106 UT —— golden OthersEntry_106 与重写 OthersEntry_106_xs 双例化，逐拍比对全部 61 个输出。
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
//     iq_wake
//     og0_cancel_hit
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
// 自动生成：verif/ut/OthersEntry_106/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
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
  int cov_iq_wake = 0;
  int cov_og0_cancel_hit = 0;
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
  logic io_commonIn_enq_bits_status_fuType_11;
  logic io_commonIn_enq_bits_status_fuType_12;
  logic io_commonIn_enq_bits_status_fuType_14;
  logic [7:0] io_commonIn_enq_bits_status_srcStatus_0_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_0_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_0_dataSources_value;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_0_exuSources_value;
  logic [7:0] io_commonIn_enq_bits_status_srcStatus_1_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_1_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_1_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_1_dataSources_value;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_1_exuSources_value;
  logic [7:0] io_commonIn_enq_bits_status_srcStatus_2_psrc;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_2_srcType;
  logic io_commonIn_enq_bits_status_srcStatus_2_srcState;
  logic [3:0] io_commonIn_enq_bits_status_srcStatus_2_dataSources_value;
  logic [1:0] io_commonIn_enq_bits_status_srcStatus_2_exuSources_value;
  logic io_commonIn_enq_bits_status_blocked;
  logic io_commonIn_enq_bits_status_issued;
  logic io_commonIn_enq_bits_status_firstIssue;
  logic [1:0] io_commonIn_enq_bits_status_issueTimer;
  logic io_commonIn_enq_bits_status_deqPortIdx;
  logic [8:0] io_commonIn_enq_bits_payload_fuOpType;
  logic io_commonIn_enq_bits_payload_rfWen;
  logic io_commonIn_enq_bits_payload_fpWen;
  logic [3:0] io_commonIn_enq_bits_payload_selImm;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_typeTagOut;
  logic io_commonIn_enq_bits_payload_fpu_wflags;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_typ;
  logic [1:0] io_commonIn_enq_bits_payload_fpu_fmt;
  logic [2:0] io_commonIn_enq_bits_payload_fpu_rm;
  logic [7:0] io_commonIn_enq_bits_payload_pdest;
  logic io_commonIn_enq_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_renameTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_dispatchTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_enqRsTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_writebackTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] io_commonIn_enq_bits_payload_debug_seqNum_seqNum;
  logic [7:0] io_commonIn_enq_bits_payload_debug_seqNum_uopIdx;
  logic io_commonIn_wakeUpFromWB_5_valid;
  logic io_commonIn_wakeUpFromWB_5_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_5_bits_pdest;
  logic io_commonIn_wakeUpFromWB_4_valid;
  logic io_commonIn_wakeUpFromWB_4_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_4_bits_pdest;
  logic io_commonIn_wakeUpFromWB_3_valid;
  logic io_commonIn_wakeUpFromWB_3_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_3_bits_pdest;
  logic io_commonIn_wakeUpFromWB_2_valid;
  logic io_commonIn_wakeUpFromWB_2_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_2_bits_pdest;
  logic io_commonIn_wakeUpFromWB_1_valid;
  logic io_commonIn_wakeUpFromWB_1_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_1_bits_pdest;
  logic io_commonIn_wakeUpFromWB_0_valid;
  logic io_commonIn_wakeUpFromWB_0_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromWB_0_bits_pdest;
  logic io_commonIn_wakeUpFromIQ_2_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_2_bits_pdest;
  logic io_commonIn_wakeUpFromIQ_1_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_1_bits_pdest;
  logic io_commonIn_wakeUpFromIQ_0_bits_fpWen;
  logic [7:0] io_commonIn_wakeUpFromIQ_0_bits_pdest;
  logic io_commonIn_wakeUpFromIQ_0_bits_is0Lat;
  logic io_commonIn_og0Cancel_8;
  logic io_commonIn_deqSel;
  logic io_commonIn_deqPortIdxWrite;
  logic io_commonIn_issueResp_valid;
  logic [1:0] io_commonIn_issueResp_bits_resp;
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
  wire [1:0] g_io_commonOut_exuSources_0_value;
  wire [1:0] i_io_commonOut_exuSources_0_value;
  wire [1:0] g_io_commonOut_exuSources_1_value;
  wire [1:0] i_io_commonOut_exuSources_1_value;
  wire [1:0] g_io_commonOut_exuSources_2_value;
  wire [1:0] i_io_commonOut_exuSources_2_value;
  wire g_io_commonOut_isFirstIssue;
  wire i_io_commonOut_isFirstIssue;
  wire g_io_commonOut_entry_bits_status_robIdx_flag;
  wire i_io_commonOut_entry_bits_status_robIdx_flag;
  wire [7:0] g_io_commonOut_entry_bits_status_robIdx_value;
  wire [7:0] i_io_commonOut_entry_bits_status_robIdx_value;
  wire g_io_commonOut_entry_bits_status_fuType_11;
  wire i_io_commonOut_entry_bits_status_fuType_11;
  wire g_io_commonOut_entry_bits_status_fuType_12;
  wire i_io_commonOut_entry_bits_status_fuType_12;
  wire g_io_commonOut_entry_bits_status_fuType_14;
  wire i_io_commonOut_entry_bits_status_fuType_14;
  wire [7:0] g_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [7:0] i_io_commonOut_entry_bits_status_srcStatus_0_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_0_srcType;
  wire [7:0] g_io_commonOut_entry_bits_status_srcStatus_1_psrc;
  wire [7:0] i_io_commonOut_entry_bits_status_srcStatus_1_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_1_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_1_srcType;
  wire [7:0] g_io_commonOut_entry_bits_status_srcStatus_2_psrc;
  wire [7:0] i_io_commonOut_entry_bits_status_srcStatus_2_psrc;
  wire [3:0] g_io_commonOut_entry_bits_status_srcStatus_2_srcType;
  wire [3:0] i_io_commonOut_entry_bits_status_srcStatus_2_srcType;
  wire [8:0] g_io_commonOut_entry_bits_payload_fuOpType;
  wire [8:0] i_io_commonOut_entry_bits_payload_fuOpType;
  wire g_io_commonOut_entry_bits_payload_rfWen;
  wire i_io_commonOut_entry_bits_payload_rfWen;
  wire g_io_commonOut_entry_bits_payload_fpWen;
  wire i_io_commonOut_entry_bits_payload_fpWen;
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
  wire g_io_commonOut_entryInValid;
  wire i_io_commonOut_entryInValid;
  wire g_io_commonOut_entryOutDeqValid;
  wire i_io_commonOut_entryOutDeqValid;
  wire g_io_commonOut_perfOg0Cancel_0;
  wire i_io_commonOut_perfOg0Cancel_0;
  wire g_io_commonOut_perfOg0Cancel_1;
  wire i_io_commonOut_perfOg0Cancel_1;
  wire g_io_commonOut_perfOg0Cancel_2;
  wire i_io_commonOut_perfOg0Cancel_2;
  wire g_io_commonOut_perfWakeupByWB_0;
  wire i_io_commonOut_perfWakeupByWB_0;
  wire g_io_commonOut_perfWakeupByWB_1;
  wire i_io_commonOut_perfWakeupByWB_1;
  wire g_io_commonOut_perfWakeupByWB_2;
  wire i_io_commonOut_perfWakeupByWB_2;
  wire g_io_commonOut_perfWakeupByIQ_0_0;
  wire i_io_commonOut_perfWakeupByIQ_0_0;
  wire g_io_commonOut_perfWakeupByIQ_0_1;
  wire i_io_commonOut_perfWakeupByIQ_0_1;
  wire g_io_commonOut_perfWakeupByIQ_0_2;
  wire i_io_commonOut_perfWakeupByIQ_0_2;
  wire g_io_commonOut_perfWakeupByIQ_1_0;
  wire i_io_commonOut_perfWakeupByIQ_1_0;
  wire g_io_commonOut_perfWakeupByIQ_1_1;
  wire i_io_commonOut_perfWakeupByIQ_1_1;
  wire g_io_commonOut_perfWakeupByIQ_1_2;
  wire i_io_commonOut_perfWakeupByIQ_1_2;
  wire g_io_commonOut_perfWakeupByIQ_2_0;
  wire i_io_commonOut_perfWakeupByIQ_2_0;
  wire g_io_commonOut_perfWakeupByIQ_2_1;
  wire i_io_commonOut_perfWakeupByIQ_2_1;
  wire g_io_commonOut_perfWakeupByIQ_2_2;
  wire i_io_commonOut_perfWakeupByIQ_2_2;

  OthersEntry_106 u_g (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_11(io_commonIn_enq_bits_status_fuType_11),
    .io_commonIn_enq_bits_status_fuType_12(io_commonIn_enq_bits_status_fuType_12),
    .io_commonIn_enq_bits_status_fuType_14(io_commonIn_enq_bits_status_fuType_14),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_exuSources_value(io_commonIn_enq_bits_status_srcStatus_0_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_psrc(io_commonIn_enq_bits_status_srcStatus_1_psrc),
    .io_commonIn_enq_bits_status_srcStatus_1_srcType(io_commonIn_enq_bits_status_srcStatus_1_srcType),
    .io_commonIn_enq_bits_status_srcStatus_1_srcState(io_commonIn_enq_bits_status_srcStatus_1_srcState),
    .io_commonIn_enq_bits_status_srcStatus_1_dataSources_value(io_commonIn_enq_bits_status_srcStatus_1_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_exuSources_value(io_commonIn_enq_bits_status_srcStatus_1_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_psrc(io_commonIn_enq_bits_status_srcStatus_2_psrc),
    .io_commonIn_enq_bits_status_srcStatus_2_srcType(io_commonIn_enq_bits_status_srcStatus_2_srcType),
    .io_commonIn_enq_bits_status_srcStatus_2_srcState(io_commonIn_enq_bits_status_srcStatus_2_srcState),
    .io_commonIn_enq_bits_status_srcStatus_2_dataSources_value(io_commonIn_enq_bits_status_srcStatus_2_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_exuSources_value(io_commonIn_enq_bits_status_srcStatus_2_exuSources_value),
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_rfWen(io_commonIn_enq_bits_payload_rfWen),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
    .io_commonIn_enq_bits_payload_fpu_typeTagOut(io_commonIn_enq_bits_payload_fpu_typeTagOut),
    .io_commonIn_enq_bits_payload_fpu_wflags(io_commonIn_enq_bits_payload_fpu_wflags),
    .io_commonIn_enq_bits_payload_fpu_typ(io_commonIn_enq_bits_payload_fpu_typ),
    .io_commonIn_enq_bits_payload_fpu_fmt(io_commonIn_enq_bits_payload_fpu_fmt),
    .io_commonIn_enq_bits_payload_fpu_rm(io_commonIn_enq_bits_payload_fpu_rm),
    .io_commonIn_enq_bits_payload_pdest(io_commonIn_enq_bits_payload_pdest),
    .io_commonIn_enq_bits_payload_debugInfo_eliminatedMove(io_commonIn_enq_bits_payload_debugInfo_eliminatedMove),
    .io_commonIn_enq_bits_payload_debugInfo_renameTime(io_commonIn_enq_bits_payload_debugInfo_renameTime),
    .io_commonIn_enq_bits_payload_debugInfo_dispatchTime(io_commonIn_enq_bits_payload_debugInfo_dispatchTime),
    .io_commonIn_enq_bits_payload_debugInfo_enqRsTime(io_commonIn_enq_bits_payload_debugInfo_enqRsTime),
    .io_commonIn_enq_bits_payload_debugInfo_writebackTime(io_commonIn_enq_bits_payload_debugInfo_writebackTime),
    .io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id(io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime(io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonIn_enq_bits_payload_debugInfo_tlbRespTime(io_commonIn_enq_bits_payload_debugInfo_tlbRespTime),
    .io_commonIn_enq_bits_payload_debug_seqNum_seqNum(io_commonIn_enq_bits_payload_debug_seqNum_seqNum),
    .io_commonIn_enq_bits_payload_debug_seqNum_uopIdx(io_commonIn_enq_bits_payload_debug_seqNum_uopIdx),
    .io_commonIn_wakeUpFromWB_5_valid(io_commonIn_wakeUpFromWB_5_valid),
    .io_commonIn_wakeUpFromWB_5_bits_fpWen(io_commonIn_wakeUpFromWB_5_bits_fpWen),
    .io_commonIn_wakeUpFromWB_5_bits_pdest(io_commonIn_wakeUpFromWB_5_bits_pdest),
    .io_commonIn_wakeUpFromWB_4_valid(io_commonIn_wakeUpFromWB_4_valid),
    .io_commonIn_wakeUpFromWB_4_bits_fpWen(io_commonIn_wakeUpFromWB_4_bits_fpWen),
    .io_commonIn_wakeUpFromWB_4_bits_pdest(io_commonIn_wakeUpFromWB_4_bits_pdest),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_fpWen(io_commonIn_wakeUpFromWB_3_bits_fpWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_fpWen(io_commonIn_wakeUpFromWB_2_bits_fpWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_fpWen(io_commonIn_wakeUpFromWB_1_bits_fpWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_fpWen(io_commonIn_wakeUpFromWB_0_bits_fpWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_2_bits_fpWen(io_commonIn_wakeUpFromIQ_2_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_2_bits_pdest(io_commonIn_wakeUpFromIQ_2_bits_pdest),
    .io_commonIn_wakeUpFromIQ_1_bits_fpWen(io_commonIn_wakeUpFromIQ_1_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_1_bits_pdest(io_commonIn_wakeUpFromIQ_1_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_fpWen(io_commonIn_wakeUpFromIQ_0_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_0_bits_pdest(io_commonIn_wakeUpFromIQ_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_is0Lat(io_commonIn_wakeUpFromIQ_0_bits_is0Lat),
    .io_commonIn_og0Cancel_8(io_commonIn_og0Cancel_8),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_deqPortIdxWrite(io_commonIn_deqPortIdxWrite),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonOut_valid(g_io_commonOut_valid),
    .io_commonOut_issued(g_io_commonOut_issued),
    .io_commonOut_canIssue(g_io_commonOut_canIssue),
    .io_commonOut_fuType(g_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(g_io_commonOut_dataSources_0_value),
    .io_commonOut_dataSources_1_value(g_io_commonOut_dataSources_1_value),
    .io_commonOut_dataSources_2_value(g_io_commonOut_dataSources_2_value),
    .io_commonOut_exuSources_0_value(g_io_commonOut_exuSources_0_value),
    .io_commonOut_exuSources_1_value(g_io_commonOut_exuSources_1_value),
    .io_commonOut_exuSources_2_value(g_io_commonOut_exuSources_2_value),
    .io_commonOut_isFirstIssue(g_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(g_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(g_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_11(g_io_commonOut_entry_bits_status_fuType_11),
    .io_commonOut_entry_bits_status_fuType_12(g_io_commonOut_entry_bits_status_fuType_12),
    .io_commonOut_entry_bits_status_fuType_14(g_io_commonOut_entry_bits_status_fuType_14),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(g_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(g_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_1_psrc(g_io_commonOut_entry_bits_status_srcStatus_1_psrc),
    .io_commonOut_entry_bits_status_srcStatus_1_srcType(g_io_commonOut_entry_bits_status_srcStatus_1_srcType),
    .io_commonOut_entry_bits_status_srcStatus_2_psrc(g_io_commonOut_entry_bits_status_srcStatus_2_psrc),
    .io_commonOut_entry_bits_status_srcStatus_2_srcType(g_io_commonOut_entry_bits_status_srcStatus_2_srcType),
    .io_commonOut_entry_bits_payload_fuOpType(g_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(g_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(g_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_selImm(g_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_fpu_typeTagOut(g_io_commonOut_entry_bits_payload_fpu_typeTagOut),
    .io_commonOut_entry_bits_payload_fpu_wflags(g_io_commonOut_entry_bits_payload_fpu_wflags),
    .io_commonOut_entry_bits_payload_fpu_typ(g_io_commonOut_entry_bits_payload_fpu_typ),
    .io_commonOut_entry_bits_payload_fpu_fmt(g_io_commonOut_entry_bits_payload_fpu_fmt),
    .io_commonOut_entry_bits_payload_fpu_rm(g_io_commonOut_entry_bits_payload_fpu_rm),
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
    .io_commonOut_entryInValid(g_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(g_io_commonOut_entryOutDeqValid),
    .io_commonOut_perfOg0Cancel_0(g_io_commonOut_perfOg0Cancel_0),
    .io_commonOut_perfOg0Cancel_1(g_io_commonOut_perfOg0Cancel_1),
    .io_commonOut_perfOg0Cancel_2(g_io_commonOut_perfOg0Cancel_2),
    .io_commonOut_perfWakeupByWB_0(g_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByWB_1(g_io_commonOut_perfWakeupByWB_1),
    .io_commonOut_perfWakeupByWB_2(g_io_commonOut_perfWakeupByWB_2),
    .io_commonOut_perfWakeupByIQ_0_0(g_io_commonOut_perfWakeupByIQ_0_0),
    .io_commonOut_perfWakeupByIQ_0_1(g_io_commonOut_perfWakeupByIQ_0_1),
    .io_commonOut_perfWakeupByIQ_0_2(g_io_commonOut_perfWakeupByIQ_0_2),
    .io_commonOut_perfWakeupByIQ_1_0(g_io_commonOut_perfWakeupByIQ_1_0),
    .io_commonOut_perfWakeupByIQ_1_1(g_io_commonOut_perfWakeupByIQ_1_1),
    .io_commonOut_perfWakeupByIQ_1_2(g_io_commonOut_perfWakeupByIQ_1_2),
    .io_commonOut_perfWakeupByIQ_2_0(g_io_commonOut_perfWakeupByIQ_2_0),
    .io_commonOut_perfWakeupByIQ_2_1(g_io_commonOut_perfWakeupByIQ_2_1),
    .io_commonOut_perfWakeupByIQ_2_2(g_io_commonOut_perfWakeupByIQ_2_2)
  );

  OthersEntry_106_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_11(io_commonIn_enq_bits_status_fuType_11),
    .io_commonIn_enq_bits_status_fuType_12(io_commonIn_enq_bits_status_fuType_12),
    .io_commonIn_enq_bits_status_fuType_14(io_commonIn_enq_bits_status_fuType_14),
    .io_commonIn_enq_bits_status_srcStatus_0_psrc(io_commonIn_enq_bits_status_srcStatus_0_psrc),
    .io_commonIn_enq_bits_status_srcStatus_0_srcType(io_commonIn_enq_bits_status_srcStatus_0_srcType),
    .io_commonIn_enq_bits_status_srcStatus_0_srcState(io_commonIn_enq_bits_status_srcStatus_0_srcState),
    .io_commonIn_enq_bits_status_srcStatus_0_dataSources_value(io_commonIn_enq_bits_status_srcStatus_0_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_0_exuSources_value(io_commonIn_enq_bits_status_srcStatus_0_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_psrc(io_commonIn_enq_bits_status_srcStatus_1_psrc),
    .io_commonIn_enq_bits_status_srcStatus_1_srcType(io_commonIn_enq_bits_status_srcStatus_1_srcType),
    .io_commonIn_enq_bits_status_srcStatus_1_srcState(io_commonIn_enq_bits_status_srcStatus_1_srcState),
    .io_commonIn_enq_bits_status_srcStatus_1_dataSources_value(io_commonIn_enq_bits_status_srcStatus_1_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_1_exuSources_value(io_commonIn_enq_bits_status_srcStatus_1_exuSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_psrc(io_commonIn_enq_bits_status_srcStatus_2_psrc),
    .io_commonIn_enq_bits_status_srcStatus_2_srcType(io_commonIn_enq_bits_status_srcStatus_2_srcType),
    .io_commonIn_enq_bits_status_srcStatus_2_srcState(io_commonIn_enq_bits_status_srcStatus_2_srcState),
    .io_commonIn_enq_bits_status_srcStatus_2_dataSources_value(io_commonIn_enq_bits_status_srcStatus_2_dataSources_value),
    .io_commonIn_enq_bits_status_srcStatus_2_exuSources_value(io_commonIn_enq_bits_status_srcStatus_2_exuSources_value),
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_rfWen(io_commonIn_enq_bits_payload_rfWen),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
    .io_commonIn_enq_bits_payload_fpu_typeTagOut(io_commonIn_enq_bits_payload_fpu_typeTagOut),
    .io_commonIn_enq_bits_payload_fpu_wflags(io_commonIn_enq_bits_payload_fpu_wflags),
    .io_commonIn_enq_bits_payload_fpu_typ(io_commonIn_enq_bits_payload_fpu_typ),
    .io_commonIn_enq_bits_payload_fpu_fmt(io_commonIn_enq_bits_payload_fpu_fmt),
    .io_commonIn_enq_bits_payload_fpu_rm(io_commonIn_enq_bits_payload_fpu_rm),
    .io_commonIn_enq_bits_payload_pdest(io_commonIn_enq_bits_payload_pdest),
    .io_commonIn_enq_bits_payload_debugInfo_eliminatedMove(io_commonIn_enq_bits_payload_debugInfo_eliminatedMove),
    .io_commonIn_enq_bits_payload_debugInfo_renameTime(io_commonIn_enq_bits_payload_debugInfo_renameTime),
    .io_commonIn_enq_bits_payload_debugInfo_dispatchTime(io_commonIn_enq_bits_payload_debugInfo_dispatchTime),
    .io_commonIn_enq_bits_payload_debugInfo_enqRsTime(io_commonIn_enq_bits_payload_debugInfo_enqRsTime),
    .io_commonIn_enq_bits_payload_debugInfo_writebackTime(io_commonIn_enq_bits_payload_debugInfo_writebackTime),
    .io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id(io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime(io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime),
    .io_commonIn_enq_bits_payload_debugInfo_tlbRespTime(io_commonIn_enq_bits_payload_debugInfo_tlbRespTime),
    .io_commonIn_enq_bits_payload_debug_seqNum_seqNum(io_commonIn_enq_bits_payload_debug_seqNum_seqNum),
    .io_commonIn_enq_bits_payload_debug_seqNum_uopIdx(io_commonIn_enq_bits_payload_debug_seqNum_uopIdx),
    .io_commonIn_wakeUpFromWB_5_valid(io_commonIn_wakeUpFromWB_5_valid),
    .io_commonIn_wakeUpFromWB_5_bits_fpWen(io_commonIn_wakeUpFromWB_5_bits_fpWen),
    .io_commonIn_wakeUpFromWB_5_bits_pdest(io_commonIn_wakeUpFromWB_5_bits_pdest),
    .io_commonIn_wakeUpFromWB_4_valid(io_commonIn_wakeUpFromWB_4_valid),
    .io_commonIn_wakeUpFromWB_4_bits_fpWen(io_commonIn_wakeUpFromWB_4_bits_fpWen),
    .io_commonIn_wakeUpFromWB_4_bits_pdest(io_commonIn_wakeUpFromWB_4_bits_pdest),
    .io_commonIn_wakeUpFromWB_3_valid(io_commonIn_wakeUpFromWB_3_valid),
    .io_commonIn_wakeUpFromWB_3_bits_fpWen(io_commonIn_wakeUpFromWB_3_bits_fpWen),
    .io_commonIn_wakeUpFromWB_3_bits_pdest(io_commonIn_wakeUpFromWB_3_bits_pdest),
    .io_commonIn_wakeUpFromWB_2_valid(io_commonIn_wakeUpFromWB_2_valid),
    .io_commonIn_wakeUpFromWB_2_bits_fpWen(io_commonIn_wakeUpFromWB_2_bits_fpWen),
    .io_commonIn_wakeUpFromWB_2_bits_pdest(io_commonIn_wakeUpFromWB_2_bits_pdest),
    .io_commonIn_wakeUpFromWB_1_valid(io_commonIn_wakeUpFromWB_1_valid),
    .io_commonIn_wakeUpFromWB_1_bits_fpWen(io_commonIn_wakeUpFromWB_1_bits_fpWen),
    .io_commonIn_wakeUpFromWB_1_bits_pdest(io_commonIn_wakeUpFromWB_1_bits_pdest),
    .io_commonIn_wakeUpFromWB_0_valid(io_commonIn_wakeUpFromWB_0_valid),
    .io_commonIn_wakeUpFromWB_0_bits_fpWen(io_commonIn_wakeUpFromWB_0_bits_fpWen),
    .io_commonIn_wakeUpFromWB_0_bits_pdest(io_commonIn_wakeUpFromWB_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_2_bits_fpWen(io_commonIn_wakeUpFromIQ_2_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_2_bits_pdest(io_commonIn_wakeUpFromIQ_2_bits_pdest),
    .io_commonIn_wakeUpFromIQ_1_bits_fpWen(io_commonIn_wakeUpFromIQ_1_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_1_bits_pdest(io_commonIn_wakeUpFromIQ_1_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_fpWen(io_commonIn_wakeUpFromIQ_0_bits_fpWen),
    .io_commonIn_wakeUpFromIQ_0_bits_pdest(io_commonIn_wakeUpFromIQ_0_bits_pdest),
    .io_commonIn_wakeUpFromIQ_0_bits_is0Lat(io_commonIn_wakeUpFromIQ_0_bits_is0Lat),
    .io_commonIn_og0Cancel_8(io_commonIn_og0Cancel_8),
    .io_commonIn_deqSel(io_commonIn_deqSel),
    .io_commonIn_deqPortIdxWrite(io_commonIn_deqPortIdxWrite),
    .io_commonIn_issueResp_valid(io_commonIn_issueResp_valid),
    .io_commonIn_issueResp_bits_resp(io_commonIn_issueResp_bits_resp),
    .io_commonOut_valid(i_io_commonOut_valid),
    .io_commonOut_issued(i_io_commonOut_issued),
    .io_commonOut_canIssue(i_io_commonOut_canIssue),
    .io_commonOut_fuType(i_io_commonOut_fuType),
    .io_commonOut_dataSources_0_value(i_io_commonOut_dataSources_0_value),
    .io_commonOut_dataSources_1_value(i_io_commonOut_dataSources_1_value),
    .io_commonOut_dataSources_2_value(i_io_commonOut_dataSources_2_value),
    .io_commonOut_exuSources_0_value(i_io_commonOut_exuSources_0_value),
    .io_commonOut_exuSources_1_value(i_io_commonOut_exuSources_1_value),
    .io_commonOut_exuSources_2_value(i_io_commonOut_exuSources_2_value),
    .io_commonOut_isFirstIssue(i_io_commonOut_isFirstIssue),
    .io_commonOut_entry_bits_status_robIdx_flag(i_io_commonOut_entry_bits_status_robIdx_flag),
    .io_commonOut_entry_bits_status_robIdx_value(i_io_commonOut_entry_bits_status_robIdx_value),
    .io_commonOut_entry_bits_status_fuType_11(i_io_commonOut_entry_bits_status_fuType_11),
    .io_commonOut_entry_bits_status_fuType_12(i_io_commonOut_entry_bits_status_fuType_12),
    .io_commonOut_entry_bits_status_fuType_14(i_io_commonOut_entry_bits_status_fuType_14),
    .io_commonOut_entry_bits_status_srcStatus_0_psrc(i_io_commonOut_entry_bits_status_srcStatus_0_psrc),
    .io_commonOut_entry_bits_status_srcStatus_0_srcType(i_io_commonOut_entry_bits_status_srcStatus_0_srcType),
    .io_commonOut_entry_bits_status_srcStatus_1_psrc(i_io_commonOut_entry_bits_status_srcStatus_1_psrc),
    .io_commonOut_entry_bits_status_srcStatus_1_srcType(i_io_commonOut_entry_bits_status_srcStatus_1_srcType),
    .io_commonOut_entry_bits_status_srcStatus_2_psrc(i_io_commonOut_entry_bits_status_srcStatus_2_psrc),
    .io_commonOut_entry_bits_status_srcStatus_2_srcType(i_io_commonOut_entry_bits_status_srcStatus_2_srcType),
    .io_commonOut_entry_bits_payload_fuOpType(i_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_rfWen(i_io_commonOut_entry_bits_payload_rfWen),
    .io_commonOut_entry_bits_payload_fpWen(i_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_selImm(i_io_commonOut_entry_bits_payload_selImm),
    .io_commonOut_entry_bits_payload_fpu_typeTagOut(i_io_commonOut_entry_bits_payload_fpu_typeTagOut),
    .io_commonOut_entry_bits_payload_fpu_wflags(i_io_commonOut_entry_bits_payload_fpu_wflags),
    .io_commonOut_entry_bits_payload_fpu_typ(i_io_commonOut_entry_bits_payload_fpu_typ),
    .io_commonOut_entry_bits_payload_fpu_fmt(i_io_commonOut_entry_bits_payload_fpu_fmt),
    .io_commonOut_entry_bits_payload_fpu_rm(i_io_commonOut_entry_bits_payload_fpu_rm),
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
    .io_commonOut_entryInValid(i_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(i_io_commonOut_entryOutDeqValid),
    .io_commonOut_perfOg0Cancel_0(i_io_commonOut_perfOg0Cancel_0),
    .io_commonOut_perfOg0Cancel_1(i_io_commonOut_perfOg0Cancel_1),
    .io_commonOut_perfOg0Cancel_2(i_io_commonOut_perfOg0Cancel_2),
    .io_commonOut_perfWakeupByWB_0(i_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByWB_1(i_io_commonOut_perfWakeupByWB_1),
    .io_commonOut_perfWakeupByWB_2(i_io_commonOut_perfWakeupByWB_2),
    .io_commonOut_perfWakeupByIQ_0_0(i_io_commonOut_perfWakeupByIQ_0_0),
    .io_commonOut_perfWakeupByIQ_0_1(i_io_commonOut_perfWakeupByIQ_0_1),
    .io_commonOut_perfWakeupByIQ_0_2(i_io_commonOut_perfWakeupByIQ_0_2),
    .io_commonOut_perfWakeupByIQ_1_0(i_io_commonOut_perfWakeupByIQ_1_0),
    .io_commonOut_perfWakeupByIQ_1_1(i_io_commonOut_perfWakeupByIQ_1_1),
    .io_commonOut_perfWakeupByIQ_1_2(i_io_commonOut_perfWakeupByIQ_1_2),
    .io_commonOut_perfWakeupByIQ_2_0(i_io_commonOut_perfWakeupByIQ_2_0),
    .io_commonOut_perfWakeupByIQ_2_1(i_io_commonOut_perfWakeupByIQ_2_1),
    .io_commonOut_perfWakeupByIQ_2_2(i_io_commonOut_perfWakeupByIQ_2_2)
  );

  task automatic check_outputs();
    `CHK(io_commonOut_valid)
    `CHK(io_commonOut_issued)
    `CHK(io_commonOut_canIssue)
    `CHK(io_commonOut_fuType)
    `CHK(io_commonOut_dataSources_0_value)
    `CHK(io_commonOut_dataSources_1_value)
    `CHK(io_commonOut_dataSources_2_value)
    `CHK(io_commonOut_exuSources_0_value)
    `CHK(io_commonOut_exuSources_1_value)
    `CHK(io_commonOut_exuSources_2_value)
    `CHK(io_commonOut_isFirstIssue)
    `CHK(io_commonOut_entry_bits_status_robIdx_flag)
    `CHK(io_commonOut_entry_bits_status_robIdx_value)
    `CHK(io_commonOut_entry_bits_status_fuType_11)
    `CHK(io_commonOut_entry_bits_status_fuType_12)
    `CHK(io_commonOut_entry_bits_status_fuType_14)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_0_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_1_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_1_srcType)
    `CHK(io_commonOut_entry_bits_status_srcStatus_2_psrc)
    `CHK(io_commonOut_entry_bits_status_srcStatus_2_srcType)
    `CHK(io_commonOut_entry_bits_payload_fuOpType)
    `CHK(io_commonOut_entry_bits_payload_rfWen)
    `CHK(io_commonOut_entry_bits_payload_fpWen)
    `CHK(io_commonOut_entry_bits_payload_selImm)
    `CHK(io_commonOut_entry_bits_payload_fpu_typeTagOut)
    `CHK(io_commonOut_entry_bits_payload_fpu_wflags)
    `CHK(io_commonOut_entry_bits_payload_fpu_typ)
    `CHK(io_commonOut_entry_bits_payload_fpu_fmt)
    `CHK(io_commonOut_entry_bits_payload_fpu_rm)
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
    `CHK(io_commonOut_entryInValid)
    `CHK(io_commonOut_entryOutDeqValid)
    `CHK(io_commonOut_perfOg0Cancel_0)
    `CHK(io_commonOut_perfOg0Cancel_1)
    `CHK(io_commonOut_perfOg0Cancel_2)
    `CHK(io_commonOut_perfWakeupByWB_0)
    `CHK(io_commonOut_perfWakeupByWB_1)
    `CHK(io_commonOut_perfWakeupByWB_2)
    `CHK(io_commonOut_perfWakeupByIQ_0_0)
    `CHK(io_commonOut_perfWakeupByIQ_0_1)
    `CHK(io_commonOut_perfWakeupByIQ_0_2)
    `CHK(io_commonOut_perfWakeupByIQ_1_0)
    `CHK(io_commonOut_perfWakeupByIQ_1_1)
    `CHK(io_commonOut_perfWakeupByIQ_1_2)
    `CHK(io_commonOut_perfWakeupByIQ_2_0)
    `CHK(io_commonOut_perfWakeupByIQ_2_1)
    `CHK(io_commonOut_perfWakeupByIQ_2_2)
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
    io_commonIn_enq_bits_status_fuType_11 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_12 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_14 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_srcStatus_0_psrc <= 8'(rnd_reg());
    // src0 的 WB 唤醒门控位是 srcType[1]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_0_srcType <= ($urandom_range(0,99) < 88) ? 4'h2 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_0_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_0_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_0_exuSources_value <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_srcStatus_1_psrc <= 8'(rnd_reg());
    // src1 的 WB 唤醒门控位是 srcType[1]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_1_srcType <= ($urandom_range(0,99) < 88) ? 4'h2 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_1_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_1_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_1_exuSources_value <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_srcStatus_2_psrc <= 8'(rnd_reg());
    // src2 的 WB 唤醒门控位是 srcType[1]，绝大多数时候给对
    io_commonIn_enq_bits_status_srcStatus_2_srcType <= ($urandom_range(0,99) < 88) ? 4'h2 : 4'($urandom_range(0,15));
    io_commonIn_enq_bits_status_srcStatus_2_srcState <= ($urandom_range(0, 99) < 60);
    io_commonIn_enq_bits_status_srcStatus_2_dataSources_value <= ($urandom_range(0,1)) ? 4'h2 : 4'h8;
    io_commonIn_enq_bits_status_srcStatus_2_exuSources_value <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_blocked <= ($urandom_range(0, 99) < 10);
    io_commonIn_enq_bits_status_issued <= ($urandom_range(0, 99) < 20);
    io_commonIn_enq_bits_status_firstIssue <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_issueTimer <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_deqPortIdx <= $urandom_range(0, 1);
    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）
    io_commonIn_enq_bits_payload_fuOpType <= 9'($urandom());
    io_commonIn_enq_bits_payload_rfWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_fpWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_selImm <= 4'($urandom());
    io_commonIn_enq_bits_payload_fpu_typeTagOut <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_wflags <= 1'($urandom());
    io_commonIn_enq_bits_payload_fpu_typ <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_fmt <= 2'($urandom());
    io_commonIn_enq_bits_payload_fpu_rm <= 3'($urandom());
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
    io_commonIn_wakeUpFromWB_0_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_0_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_0_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_1_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_1_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_1_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_2_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_2_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_2_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_3_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_3_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_3_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_4_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_4_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_4_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromWB_5_valid <= ($urandom_range(0, 99) < 55);
    io_commonIn_wakeUpFromWB_5_bits_fpWen <= ($urandom_range(0, 99) < 85);
    io_commonIn_wakeUpFromWB_5_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_0_bits_fpWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_0_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_0_bits_is0Lat <= ($urandom_range(0, 99) < 60);
    io_commonIn_wakeUpFromIQ_1_bits_fpWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_1_bits_pdest <= 8'(rnd_reg());
    io_commonIn_wakeUpFromIQ_2_bits_fpWen <= ($urandom_range(0, 99) < 30);
    io_commonIn_wakeUpFromIQ_2_bits_pdest <= 8'(rnd_reg());
    io_commonIn_og0Cancel_8 <= ($urandom_range(0, 99) < 20);
    io_commonIn_deqPortIdxWrite <= ($urandom_range(0, 99) < 30);
    // issueResp：三种响应都要回到（BLOCK=0 / UNCERTAIN=1 / SUCCESS=3）
    io_commonIn_issueResp_valid <= ($urandom_range(0, 99) < 35);
    io_commonIn_issueResp_bits_resp <= (2'($urandom_range(0, 2)) == 2'd2) ? 2'd3 : 2'($urandom_range(0, 1));
  endtask

  // ---- deqSel / transSel：必须在时钟沿之前按 golden 当拍的 canIssue 算 ----
  // 纯随机给的话命中 canIssue 的概率极低，发射通路整轮不动（假绿的头号来源）。
  task automatic drive_sel();
    io_commonIn_deqSel = g_io_commonOut_canIssue && ($urandom_range(0, 99) < 70);
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
    if (g_io_commonOut_perfWakeupByWB_0 || g_io_commonOut_perfWakeupByWB_1 || g_io_commonOut_perfWakeupByWB_2) cov_wb_wake++;
    if (g_io_commonOut_perfWakeupByIQ_0_0 || g_io_commonOut_perfWakeupByIQ_0_1 || g_io_commonOut_perfWakeupByIQ_0_2 || g_io_commonOut_perfWakeupByIQ_1_0 || g_io_commonOut_perfWakeupByIQ_1_1 || g_io_commonOut_perfWakeupByIQ_1_2 || g_io_commonOut_perfWakeupByIQ_2_0 || g_io_commonOut_perfWakeupByIQ_2_1 || g_io_commonOut_perfWakeupByIQ_2_2) cov_iq_wake++;
    if (g_io_commonOut_perfOg0Cancel_0 || g_io_commonOut_perfOg0Cancel_1 || g_io_commonOut_perfOg0Cancel_2) cov_og0_cancel_hit++;
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
    MINCOV["iq_wake"] = ((NCYCLES * 7502) / 200000) > 0 ? ((NCYCLES * 7502) / 200000) : 1;
    MINCOV["og0_cancel_hit"] = ((NCYCLES * 335) / 200000) > 0 ? ((NCYCLES * 335) / 200000) : 1;
    if (nopool) $display("*** +nopool: 覆盖闸负测模式（激励退化，闸必须红）***");
    reset = 1;
    drive();
    io_commonIn_deqSel = 1'b0;
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
        covchk("iq_wake", cov_iq_wake);
        covchk("og0_cancel_hit", cov_og0_cancel_hit);
        if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
        else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);
        $finish;
      end
    end
  end
endmodule
