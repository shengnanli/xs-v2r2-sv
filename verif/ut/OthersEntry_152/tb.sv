// OthersEntry_152 UT —— golden OthersEntry_152 与重写 OthersEntry_152_xs 双例化，逐拍比对全部 91 个输出。
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
//     ignore_old_vd
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
// 自动生成：verif/ut/OthersEntry_152/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
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
  int cov_ignore_old_vd = 0;
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
  logic io_commonIn_enq_bits_status_fuType_19;
  logic io_commonIn_enq_bits_status_fuType_24;
  logic io_commonIn_enq_bits_status_fuType_25;
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
  logic io_commonIn_enq_bits_status_blocked;
  logic io_commonIn_enq_bits_status_issued;
  logic io_commonIn_enq_bits_status_firstIssue;
  logic [1:0] io_commonIn_enq_bits_status_issueTimer;
  logic io_commonIn_enq_bits_status_deqPortIdx;
  logic [8:0] io_commonIn_enq_bits_payload_fuOpType;
  logic io_commonIn_enq_bits_payload_fpWen;
  logic io_commonIn_enq_bits_payload_vecWen;
  logic io_commonIn_enq_bits_payload_v0Wen;
  logic [3:0] io_commonIn_enq_bits_payload_selImm;
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
  logic [6:0] io_commonIn_enq_bits_payload_uopIdx;
  logic io_commonIn_enq_bits_payload_lastUop;
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
  wire g_io_commonOut_entry_bits_status_fuType_19;
  wire i_io_commonOut_entry_bits_status_fuType_19;
  wire g_io_commonOut_entry_bits_status_fuType_24;
  wire i_io_commonOut_entry_bits_status_fuType_24;
  wire g_io_commonOut_entry_bits_status_fuType_25;
  wire i_io_commonOut_entry_bits_status_fuType_25;
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
  wire [8:0] g_io_commonOut_entry_bits_payload_fuOpType;
  wire [8:0] i_io_commonOut_entry_bits_payload_fuOpType;
  wire g_io_commonOut_entry_bits_payload_fpWen;
  wire i_io_commonOut_entry_bits_payload_fpWen;
  wire g_io_commonOut_entry_bits_payload_vecWen;
  wire i_io_commonOut_entry_bits_payload_vecWen;
  wire g_io_commonOut_entry_bits_payload_v0Wen;
  wire i_io_commonOut_entry_bits_payload_v0Wen;
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
  wire g_io_commonOut_entryInValid;
  wire i_io_commonOut_entryInValid;
  wire g_io_commonOut_entryOutDeqValid;
  wire i_io_commonOut_entryOutDeqValid;
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

  OthersEntry_152 u_g (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_19(io_commonIn_enq_bits_status_fuType_19),
    .io_commonIn_enq_bits_status_fuType_24(io_commonIn_enq_bits_status_fuType_24),
    .io_commonIn_enq_bits_status_fuType_25(io_commonIn_enq_bits_status_fuType_25),
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
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_vecWen(io_commonIn_enq_bits_payload_vecWen),
    .io_commonIn_enq_bits_payload_v0Wen(io_commonIn_enq_bits_payload_v0Wen),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
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
    .io_commonIn_enq_bits_payload_uopIdx(io_commonIn_enq_bits_payload_uopIdx),
    .io_commonIn_enq_bits_payload_lastUop(io_commonIn_enq_bits_payload_lastUop),
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
    .io_commonOut_entry_bits_status_fuType_19(g_io_commonOut_entry_bits_status_fuType_19),
    .io_commonOut_entry_bits_status_fuType_24(g_io_commonOut_entry_bits_status_fuType_24),
    .io_commonOut_entry_bits_status_fuType_25(g_io_commonOut_entry_bits_status_fuType_25),
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
    .io_commonOut_entry_bits_payload_fuOpType(g_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_fpWen(g_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_vecWen(g_io_commonOut_entry_bits_payload_vecWen),
    .io_commonOut_entry_bits_payload_v0Wen(g_io_commonOut_entry_bits_payload_v0Wen),
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
    .io_commonOut_entryInValid(g_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(g_io_commonOut_entryOutDeqValid),
    .io_commonOut_perfWakeupByWB_0(g_io_commonOut_perfWakeupByWB_0),
    .io_commonOut_perfWakeupByWB_1(g_io_commonOut_perfWakeupByWB_1),
    .io_commonOut_perfWakeupByWB_2(g_io_commonOut_perfWakeupByWB_2),
    .io_commonOut_perfWakeupByWB_3(g_io_commonOut_perfWakeupByWB_3),
    .io_commonOut_perfWakeupByWB_4(g_io_commonOut_perfWakeupByWB_4)
  );

  OthersEntry_152_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_commonIn_flush_valid(io_commonIn_flush_valid),
    .io_commonIn_flush_bits_robIdx_flag(io_commonIn_flush_bits_robIdx_flag),
    .io_commonIn_flush_bits_robIdx_value(io_commonIn_flush_bits_robIdx_value),
    .io_commonIn_flush_bits_level(io_commonIn_flush_bits_level),
    .io_commonIn_enq_valid(io_commonIn_enq_valid),
    .io_commonIn_enq_bits_status_robIdx_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .io_commonIn_enq_bits_status_robIdx_value(io_commonIn_enq_bits_status_robIdx_value),
    .io_commonIn_enq_bits_status_fuType_19(io_commonIn_enq_bits_status_fuType_19),
    .io_commonIn_enq_bits_status_fuType_24(io_commonIn_enq_bits_status_fuType_24),
    .io_commonIn_enq_bits_status_fuType_25(io_commonIn_enq_bits_status_fuType_25),
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
    .io_commonIn_enq_bits_status_blocked(io_commonIn_enq_bits_status_blocked),
    .io_commonIn_enq_bits_status_issued(io_commonIn_enq_bits_status_issued),
    .io_commonIn_enq_bits_status_firstIssue(io_commonIn_enq_bits_status_firstIssue),
    .io_commonIn_enq_bits_status_issueTimer(io_commonIn_enq_bits_status_issueTimer),
    .io_commonIn_enq_bits_status_deqPortIdx(io_commonIn_enq_bits_status_deqPortIdx),
    .io_commonIn_enq_bits_payload_fuOpType(io_commonIn_enq_bits_payload_fuOpType),
    .io_commonIn_enq_bits_payload_fpWen(io_commonIn_enq_bits_payload_fpWen),
    .io_commonIn_enq_bits_payload_vecWen(io_commonIn_enq_bits_payload_vecWen),
    .io_commonIn_enq_bits_payload_v0Wen(io_commonIn_enq_bits_payload_v0Wen),
    .io_commonIn_enq_bits_payload_selImm(io_commonIn_enq_bits_payload_selImm),
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
    .io_commonIn_enq_bits_payload_uopIdx(io_commonIn_enq_bits_payload_uopIdx),
    .io_commonIn_enq_bits_payload_lastUop(io_commonIn_enq_bits_payload_lastUop),
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
    .io_commonOut_entry_bits_status_fuType_19(i_io_commonOut_entry_bits_status_fuType_19),
    .io_commonOut_entry_bits_status_fuType_24(i_io_commonOut_entry_bits_status_fuType_24),
    .io_commonOut_entry_bits_status_fuType_25(i_io_commonOut_entry_bits_status_fuType_25),
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
    .io_commonOut_entry_bits_payload_fuOpType(i_io_commonOut_entry_bits_payload_fuOpType),
    .io_commonOut_entry_bits_payload_fpWen(i_io_commonOut_entry_bits_payload_fpWen),
    .io_commonOut_entry_bits_payload_vecWen(i_io_commonOut_entry_bits_payload_vecWen),
    .io_commonOut_entry_bits_payload_v0Wen(i_io_commonOut_entry_bits_payload_v0Wen),
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
    .io_commonOut_entryInValid(i_io_commonOut_entryInValid),
    .io_commonOut_entryOutDeqValid(i_io_commonOut_entryOutDeqValid),
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
    `CHK(io_commonOut_entry_bits_status_fuType_19)
    `CHK(io_commonOut_entry_bits_status_fuType_24)
    `CHK(io_commonOut_entry_bits_status_fuType_25)
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
    `CHK(io_commonOut_entry_bits_payload_fuOpType)
    `CHK(io_commonOut_entry_bits_payload_fpWen)
    `CHK(io_commonOut_entry_bits_payload_vecWen)
    `CHK(io_commonOut_entry_bits_payload_v0Wen)
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
    `CHK(io_commonOut_entryInValid)
    `CHK(io_commonOut_entryOutDeqValid)
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
  //   它证明的是「闸看得见激励塌陷」，与变异体证明「自己改了电路」
  //   互为对偶。正常跑不给这个 plusarg；负测由 check_cov_gate.py 驱动。
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
    io_commonIn_enq_bits_status_fuType_19 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_24 <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_fuType_25 <= $urandom_range(0, 1);
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
    io_commonIn_enq_bits_status_blocked <= ($urandom_range(0, 99) < 10);
    io_commonIn_enq_bits_status_issued <= ($urandom_range(0, 99) < 20);
    io_commonIn_enq_bits_status_firstIssue <= $urandom_range(0, 1);
    io_commonIn_enq_bits_status_issueTimer <= 2'($urandom_range(0, 3));
    io_commonIn_enq_bits_status_deqPortIdx <= $urandom_range(0, 1);
    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）
    io_commonIn_enq_bits_payload_fuOpType <= 9'($urandom());
    io_commonIn_enq_bits_payload_fpWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_vecWen <= 1'($urandom());
    io_commonIn_enq_bits_payload_v0Wen <= 1'($urandom());
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
    io_commonIn_vlFromIntIsZero <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromIntIsVlmax <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromVfIsZero <= ($urandom_range(0, 99) < 35);
    io_commonIn_vlFromVfIsVlmax <= ($urandom_range(0, 99) < 35);
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
    if (g_io_commonOut_perfWakeupByWB_0 || g_io_commonOut_perfWakeupByWB_1 || g_io_commonOut_perfWakeupByWB_2 || g_io_commonOut_perfWakeupByWB_3 || g_io_commonOut_perfWakeupByWB_4) cov_wb_wake++;
    // ignoreOldVd 走的是 vl 写回那两路；这里只统计条件成立的拍数
    if (io_commonIn_vlFromIntIsZero || io_commonIn_vlFromVfIsZero) cov_ignore_old_vd++;
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
    MINCOV["ignore_old_vd"] = ((NCYCLES * 1) / 200000) > 0 ? ((NCYCLES * 1) / 200000) : 1;
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
        covchk("ignore_old_vd", cov_ignore_old_vd);
        if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
        else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);
        $finish;
      end
    end
  end
endmodule
