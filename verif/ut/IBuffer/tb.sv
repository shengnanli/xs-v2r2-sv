// =============================================================================
// IBuffer UT —— golden IBuffer 与重写 IBuffer_xs 双例化同激励，逐拍比对全部
// 160 根输出端口。★本文件由 gen.py 生成，改激励请改 gen.py 再重跑★
//
// ★ 激励为什么不是「每个输入每拍独立均匀随机」★
// IBuffer 是 48 项的循环队列 + 6 路输出寄存器。它的判别力全在**边界状态**上，
// 而边界状态纯随机走不到：
//   · 队列满（allowEnq 落 0、in_ready 落 0）：要连续很多拍只进不出；
//   · 指针绕圈（48 项 / 6 个 bank / bank 内 8 项，三组指针各有各的绕法）：
//     要累计进出上百条指令；
//   · 输出寄存器**部分填充**（outputEntriesValidNum ∈ 1..5）：要 decodeCanAccept
//     忽高忽低、且每拍出队条数小于 6 —— 这正是「i - validNum」那个会越界的
//     移位读唯一被用到的场合（见 rtl 的 §8）；
//   · 旁路（队列空 + Decode 能收 + 本拍来了 >6 条）：要队列**恰好空**。
// 所以激励走一个**相位状态机**：FILL（只进不出）/ DRAIN（只出不进）/
// TRICKLE（少量进 + decodeCanAccept 抖动，专打部分填充）/ BYPASS（保持空 + 大块进）/
// RANDOM（全随机兜底），外加随机 flush。每个相位随机长度，循环切换。
// 相位是否真的把这些状态打到了，由文件末尾的 COVERAGE 段判定 —— 任何一项为 0
// 就判 TEST FAILED，不承认「随机跑了 200k 拍所以一定测到了」。
//
// ★ 覆盖统计读的是 golden 的内部状态（层次引用 u_golden.*）★
// 用端口反推「队列现在多满」既绕又不准。这里直接读 golden 内部的 numValid_probe /
// allowEnq / useBypass / outputEntriesValidNum / 各指针 flag。**只读 golden，
// 不读重写侧** —— 否则就是拿被测件证明自己。
//
// ★ 不复位寄存器与比对窗口 ★
// golden 只有 18 个 perf 打拍寄存器不复位（io_perf_*_value_REG/REG_1），且它们
// **每拍无条件更新**，两拍就与激励同步。所以：
//   · 前 4 拍不比（让两侧的 perf 寄存器从随机初值收敛）；
//   · 之后**连复位期间也一起比** —— 这样「给 perf 寄存器加复位」这种复位域
//     变异才抓得住（见 mutants.py 的 M6）。为此复位期间照样打激励，不清零。
// =============================================================================
`timescale 1ns/1ps

module tb;

  localparam int RESETS = 8;   // 运行中插入的异步复位次数（理由见 initial 块）

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int   errors  = 0;
  longint checks = 0;
  longint cyc    = 0;

  always #5 clk = ~clk;


  // ---- 激励信号（两侧共用）----
  logic           io_flush;
  logic           io_ControlRedirect;
  logic           io_ControlBTBMissBubble;
  logic           io_TAGEMissBubble;
  logic           io_SCMissBubble;
  logic           io_ITTAGEMissBubble;
  logic           io_RASMissBubble;
  logic           io_MemVioRedirect;
  logic           io_in_valid;
  logic [31:0]    io_in_bits_instrs_0;
  logic [31:0]    io_in_bits_instrs_1;
  logic [31:0]    io_in_bits_instrs_2;
  logic [31:0]    io_in_bits_instrs_3;
  logic [31:0]    io_in_bits_instrs_4;
  logic [31:0]    io_in_bits_instrs_5;
  logic [31:0]    io_in_bits_instrs_6;
  logic [31:0]    io_in_bits_instrs_7;
  logic [31:0]    io_in_bits_instrs_8;
  logic [31:0]    io_in_bits_instrs_9;
  logic [31:0]    io_in_bits_instrs_10;
  logic [31:0]    io_in_bits_instrs_11;
  logic [31:0]    io_in_bits_instrs_12;
  logic [31:0]    io_in_bits_instrs_13;
  logic [31:0]    io_in_bits_instrs_14;
  logic [31:0]    io_in_bits_instrs_15;
  logic [15:0]    io_in_bits_valid;
  logic [15:0]    io_in_bits_enqEnable;
  logic           io_in_bits_pd_0_isRVC;
  logic [1:0]     io_in_bits_pd_0_brType;
  logic           io_in_bits_pd_0_isCall;
  logic           io_in_bits_pd_0_isRet;
  logic           io_in_bits_pd_1_valid;
  logic           io_in_bits_pd_1_isRVC;
  logic [1:0]     io_in_bits_pd_1_brType;
  logic           io_in_bits_pd_1_isCall;
  logic           io_in_bits_pd_1_isRet;
  logic           io_in_bits_pd_2_valid;
  logic           io_in_bits_pd_2_isRVC;
  logic [1:0]     io_in_bits_pd_2_brType;
  logic           io_in_bits_pd_2_isCall;
  logic           io_in_bits_pd_2_isRet;
  logic           io_in_bits_pd_3_valid;
  logic           io_in_bits_pd_3_isRVC;
  logic [1:0]     io_in_bits_pd_3_brType;
  logic           io_in_bits_pd_3_isCall;
  logic           io_in_bits_pd_3_isRet;
  logic           io_in_bits_pd_4_valid;
  logic           io_in_bits_pd_4_isRVC;
  logic [1:0]     io_in_bits_pd_4_brType;
  logic           io_in_bits_pd_4_isCall;
  logic           io_in_bits_pd_4_isRet;
  logic           io_in_bits_pd_5_valid;
  logic           io_in_bits_pd_5_isRVC;
  logic [1:0]     io_in_bits_pd_5_brType;
  logic           io_in_bits_pd_5_isCall;
  logic           io_in_bits_pd_5_isRet;
  logic           io_in_bits_pd_6_valid;
  logic           io_in_bits_pd_6_isRVC;
  logic [1:0]     io_in_bits_pd_6_brType;
  logic           io_in_bits_pd_6_isCall;
  logic           io_in_bits_pd_6_isRet;
  logic           io_in_bits_pd_7_valid;
  logic           io_in_bits_pd_7_isRVC;
  logic [1:0]     io_in_bits_pd_7_brType;
  logic           io_in_bits_pd_7_isCall;
  logic           io_in_bits_pd_7_isRet;
  logic           io_in_bits_pd_8_valid;
  logic           io_in_bits_pd_8_isRVC;
  logic [1:0]     io_in_bits_pd_8_brType;
  logic           io_in_bits_pd_8_isCall;
  logic           io_in_bits_pd_8_isRet;
  logic           io_in_bits_pd_9_valid;
  logic           io_in_bits_pd_9_isRVC;
  logic [1:0]     io_in_bits_pd_9_brType;
  logic           io_in_bits_pd_9_isCall;
  logic           io_in_bits_pd_9_isRet;
  logic           io_in_bits_pd_10_valid;
  logic           io_in_bits_pd_10_isRVC;
  logic [1:0]     io_in_bits_pd_10_brType;
  logic           io_in_bits_pd_10_isCall;
  logic           io_in_bits_pd_10_isRet;
  logic           io_in_bits_pd_11_valid;
  logic           io_in_bits_pd_11_isRVC;
  logic [1:0]     io_in_bits_pd_11_brType;
  logic           io_in_bits_pd_11_isCall;
  logic           io_in_bits_pd_11_isRet;
  logic           io_in_bits_pd_12_valid;
  logic           io_in_bits_pd_12_isRVC;
  logic [1:0]     io_in_bits_pd_12_brType;
  logic           io_in_bits_pd_12_isCall;
  logic           io_in_bits_pd_12_isRet;
  logic           io_in_bits_pd_13_valid;
  logic           io_in_bits_pd_13_isRVC;
  logic [1:0]     io_in_bits_pd_13_brType;
  logic           io_in_bits_pd_13_isCall;
  logic           io_in_bits_pd_13_isRet;
  logic           io_in_bits_pd_14_valid;
  logic           io_in_bits_pd_14_isRVC;
  logic [1:0]     io_in_bits_pd_14_brType;
  logic           io_in_bits_pd_14_isCall;
  logic           io_in_bits_pd_14_isRet;
  logic           io_in_bits_pd_15_valid;
  logic           io_in_bits_pd_15_isRVC;
  logic [1:0]     io_in_bits_pd_15_brType;
  logic           io_in_bits_pd_15_isCall;
  logic           io_in_bits_pd_15_isRet;
  logic [9:0]     io_in_bits_foldpc_0;
  logic [9:0]     io_in_bits_foldpc_1;
  logic [9:0]     io_in_bits_foldpc_2;
  logic [9:0]     io_in_bits_foldpc_3;
  logic [9:0]     io_in_bits_foldpc_4;
  logic [9:0]     io_in_bits_foldpc_5;
  logic [9:0]     io_in_bits_foldpc_6;
  logic [9:0]     io_in_bits_foldpc_7;
  logic [9:0]     io_in_bits_foldpc_8;
  logic [9:0]     io_in_bits_foldpc_9;
  logic [9:0]     io_in_bits_foldpc_10;
  logic [9:0]     io_in_bits_foldpc_11;
  logic [9:0]     io_in_bits_foldpc_12;
  logic [9:0]     io_in_bits_foldpc_13;
  logic [9:0]     io_in_bits_foldpc_14;
  logic [9:0]     io_in_bits_foldpc_15;
  logic           io_in_bits_ftqOffset_0_valid;
  logic           io_in_bits_ftqOffset_1_valid;
  logic           io_in_bits_ftqOffset_2_valid;
  logic           io_in_bits_ftqOffset_3_valid;
  logic           io_in_bits_ftqOffset_4_valid;
  logic           io_in_bits_ftqOffset_5_valid;
  logic           io_in_bits_ftqOffset_6_valid;
  logic           io_in_bits_ftqOffset_7_valid;
  logic           io_in_bits_ftqOffset_8_valid;
  logic           io_in_bits_ftqOffset_9_valid;
  logic           io_in_bits_ftqOffset_10_valid;
  logic           io_in_bits_ftqOffset_11_valid;
  logic           io_in_bits_ftqOffset_12_valid;
  logic           io_in_bits_ftqOffset_13_valid;
  logic           io_in_bits_ftqOffset_14_valid;
  logic           io_in_bits_ftqOffset_15_valid;
  logic           io_in_bits_backendException_0;
  logic           io_in_bits_satpFlushFirstFetchFault_0;
  logic [1:0]     io_in_bits_exceptionType_0;
  logic [1:0]     io_in_bits_exceptionType_1;
  logic [1:0]     io_in_bits_exceptionType_2;
  logic [1:0]     io_in_bits_exceptionType_3;
  logic [1:0]     io_in_bits_exceptionType_4;
  logic [1:0]     io_in_bits_exceptionType_5;
  logic [1:0]     io_in_bits_exceptionType_6;
  logic [1:0]     io_in_bits_exceptionType_7;
  logic [1:0]     io_in_bits_exceptionType_8;
  logic [1:0]     io_in_bits_exceptionType_9;
  logic [1:0]     io_in_bits_exceptionType_10;
  logic [1:0]     io_in_bits_exceptionType_11;
  logic [1:0]     io_in_bits_exceptionType_12;
  logic [1:0]     io_in_bits_exceptionType_13;
  logic [1:0]     io_in_bits_exceptionType_14;
  logic [1:0]     io_in_bits_exceptionType_15;
  logic           io_in_bits_crossPageIPFFix_0;
  logic           io_in_bits_crossPageIPFFix_1;
  logic           io_in_bits_crossPageIPFFix_2;
  logic           io_in_bits_crossPageIPFFix_3;
  logic           io_in_bits_crossPageIPFFix_4;
  logic           io_in_bits_crossPageIPFFix_5;
  logic           io_in_bits_crossPageIPFFix_6;
  logic           io_in_bits_crossPageIPFFix_7;
  logic           io_in_bits_crossPageIPFFix_8;
  logic           io_in_bits_crossPageIPFFix_9;
  logic           io_in_bits_crossPageIPFFix_10;
  logic           io_in_bits_crossPageIPFFix_11;
  logic           io_in_bits_crossPageIPFFix_12;
  logic           io_in_bits_crossPageIPFFix_13;
  logic           io_in_bits_crossPageIPFFix_14;
  logic           io_in_bits_crossPageIPFFix_15;
  logic           io_in_bits_illegalInstr_0;
  logic           io_in_bits_illegalInstr_1;
  logic           io_in_bits_illegalInstr_2;
  logic           io_in_bits_illegalInstr_3;
  logic           io_in_bits_illegalInstr_4;
  logic           io_in_bits_illegalInstr_5;
  logic           io_in_bits_illegalInstr_6;
  logic           io_in_bits_illegalInstr_7;
  logic           io_in_bits_illegalInstr_8;
  logic           io_in_bits_illegalInstr_9;
  logic           io_in_bits_illegalInstr_10;
  logic           io_in_bits_illegalInstr_11;
  logic           io_in_bits_illegalInstr_12;
  logic           io_in_bits_illegalInstr_13;
  logic           io_in_bits_illegalInstr_14;
  logic           io_in_bits_illegalInstr_15;
  logic [3:0]     io_in_bits_triggered_0;
  logic [3:0]     io_in_bits_triggered_1;
  logic [3:0]     io_in_bits_triggered_2;
  logic [3:0]     io_in_bits_triggered_3;
  logic [3:0]     io_in_bits_triggered_4;
  logic [3:0]     io_in_bits_triggered_5;
  logic [3:0]     io_in_bits_triggered_6;
  logic [3:0]     io_in_bits_triggered_7;
  logic [3:0]     io_in_bits_triggered_8;
  logic [3:0]     io_in_bits_triggered_9;
  logic [3:0]     io_in_bits_triggered_10;
  logic [3:0]     io_in_bits_triggered_11;
  logic [3:0]     io_in_bits_triggered_12;
  logic [3:0]     io_in_bits_triggered_13;
  logic [3:0]     io_in_bits_triggered_14;
  logic [3:0]     io_in_bits_triggered_15;
  logic           io_in_bits_isLastInFtqEntry_0;
  logic           io_in_bits_isLastInFtqEntry_1;
  logic           io_in_bits_isLastInFtqEntry_2;
  logic           io_in_bits_isLastInFtqEntry_3;
  logic           io_in_bits_isLastInFtqEntry_4;
  logic           io_in_bits_isLastInFtqEntry_5;
  logic           io_in_bits_isLastInFtqEntry_6;
  logic           io_in_bits_isLastInFtqEntry_7;
  logic           io_in_bits_isLastInFtqEntry_8;
  logic           io_in_bits_isLastInFtqEntry_9;
  logic           io_in_bits_isLastInFtqEntry_10;
  logic           io_in_bits_isLastInFtqEntry_11;
  logic           io_in_bits_isLastInFtqEntry_12;
  logic           io_in_bits_isLastInFtqEntry_13;
  logic           io_in_bits_isLastInFtqEntry_14;
  logic           io_in_bits_isLastInFtqEntry_15;
  logic [49:0]    io_in_bits_pc_0;
  logic [49:0]    io_in_bits_pc_1;
  logic [49:0]    io_in_bits_pc_2;
  logic [49:0]    io_in_bits_pc_3;
  logic [49:0]    io_in_bits_pc_4;
  logic [49:0]    io_in_bits_pc_5;
  logic [49:0]    io_in_bits_pc_6;
  logic [49:0]    io_in_bits_pc_7;
  logic [49:0]    io_in_bits_pc_8;
  logic [49:0]    io_in_bits_pc_9;
  logic [49:0]    io_in_bits_pc_10;
  logic [49:0]    io_in_bits_pc_11;
  logic [49:0]    io_in_bits_pc_12;
  logic [49:0]    io_in_bits_pc_13;
  logic [49:0]    io_in_bits_pc_14;
  logic [49:0]    io_in_bits_pc_15;
  logic           io_in_bits_ftqPtr_flag;
  logic [5:0]     io_in_bits_ftqPtr_value;
  logic           io_in_bits_topdown_info_reasons_0;
  logic           io_in_bits_topdown_info_reasons_1;
  logic           io_in_bits_topdown_info_reasons_2;
  logic           io_in_bits_topdown_info_reasons_3;
  logic           io_in_bits_topdown_info_reasons_4;
  logic           io_in_bits_topdown_info_reasons_5;
  logic           io_in_bits_topdown_info_reasons_6;
  logic           io_in_bits_topdown_info_reasons_7;
  logic           io_in_bits_topdown_info_reasons_8;
  logic           io_in_bits_topdown_info_reasons_9;
  logic           io_in_bits_topdown_info_reasons_10;
  logic           io_in_bits_topdown_info_reasons_11;
  logic           io_in_bits_topdown_info_reasons_12;
  logic           io_in_bits_topdown_info_reasons_13;
  logic           io_in_bits_topdown_info_reasons_14;
  logic           io_in_bits_topdown_info_reasons_15;
  logic           io_in_bits_topdown_info_reasons_16;
  logic           io_in_bits_topdown_info_reasons_17;
  logic           io_in_bits_topdown_info_reasons_18;
  logic           io_in_bits_topdown_info_reasons_19;
  logic           io_in_bits_topdown_info_reasons_20;
  logic           io_in_bits_topdown_info_reasons_21;
  logic           io_in_bits_topdown_info_reasons_22;
  logic           io_in_bits_topdown_info_reasons_23;
  logic           io_in_bits_topdown_info_reasons_24;
  logic           io_in_bits_topdown_info_reasons_25;
  logic           io_in_bits_topdown_info_reasons_26;
  logic           io_in_bits_topdown_info_reasons_27;
  logic           io_in_bits_topdown_info_reasons_28;
  logic           io_in_bits_topdown_info_reasons_29;
  logic           io_in_bits_topdown_info_reasons_30;
  logic           io_in_bits_topdown_info_reasons_31;
  logic           io_in_bits_topdown_info_reasons_32;
  logic           io_in_bits_topdown_info_reasons_33;
  logic           io_in_bits_topdown_info_reasons_34;
  logic           io_in_bits_topdown_info_reasons_35;
  logic           io_in_bits_topdown_info_reasons_36;
  logic           io_in_bits_topdown_info_reasons_37;
  logic           io_decodeCanAccept;
  logic           io_stallReason_backReason_valid;
  logic [5:0]     io_stallReason_backReason_bits;

  // ---- golden 侧输出 ----
  logic           g_io_in_ready;
  logic           g_io_out_0_valid;
  logic [31:0]    g_io_out_0_bits_instr;
  logic [49:0]    g_io_out_0_bits_pc;
  logic [9:0]     g_io_out_0_bits_foldpc;
  logic           g_io_out_0_bits_exceptionVec_1;
  logic           g_io_out_0_bits_exceptionVec_2;
  logic           g_io_out_0_bits_exceptionVec_12;
  logic           g_io_out_0_bits_exceptionVec_20;
  logic           g_io_out_0_bits_backendException;
  logic           g_io_out_0_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_0_bits_trigger;
  logic           g_io_out_0_bits_pd_valid;
  logic           g_io_out_0_bits_pd_isRVC;
  logic [1:0]     g_io_out_0_bits_pd_brType;
  logic           g_io_out_0_bits_pd_isCall;
  logic           g_io_out_0_bits_pd_isRet;
  logic           g_io_out_0_bits_pred_taken;
  logic           g_io_out_0_bits_crossPageIPFFix;
  logic           g_io_out_0_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_0_bits_ftqPtr_value;
  logic [3:0]     g_io_out_0_bits_ftqOffset;
  logic           g_io_out_0_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_0_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_0_bits_debug_seqNum_uopIdx;
  logic           g_io_out_1_valid;
  logic [31:0]    g_io_out_1_bits_instr;
  logic [49:0]    g_io_out_1_bits_pc;
  logic [9:0]     g_io_out_1_bits_foldpc;
  logic           g_io_out_1_bits_exceptionVec_1;
  logic           g_io_out_1_bits_exceptionVec_2;
  logic           g_io_out_1_bits_exceptionVec_12;
  logic           g_io_out_1_bits_exceptionVec_20;
  logic           g_io_out_1_bits_backendException;
  logic           g_io_out_1_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_1_bits_trigger;
  logic           g_io_out_1_bits_pd_valid;
  logic           g_io_out_1_bits_pd_isRVC;
  logic [1:0]     g_io_out_1_bits_pd_brType;
  logic           g_io_out_1_bits_pd_isCall;
  logic           g_io_out_1_bits_pd_isRet;
  logic           g_io_out_1_bits_pred_taken;
  logic           g_io_out_1_bits_crossPageIPFFix;
  logic           g_io_out_1_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_1_bits_ftqPtr_value;
  logic [3:0]     g_io_out_1_bits_ftqOffset;
  logic           g_io_out_1_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_1_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_1_bits_debug_seqNum_uopIdx;
  logic           g_io_out_2_valid;
  logic [31:0]    g_io_out_2_bits_instr;
  logic [49:0]    g_io_out_2_bits_pc;
  logic [9:0]     g_io_out_2_bits_foldpc;
  logic           g_io_out_2_bits_exceptionVec_1;
  logic           g_io_out_2_bits_exceptionVec_2;
  logic           g_io_out_2_bits_exceptionVec_12;
  logic           g_io_out_2_bits_exceptionVec_20;
  logic           g_io_out_2_bits_backendException;
  logic           g_io_out_2_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_2_bits_trigger;
  logic           g_io_out_2_bits_pd_valid;
  logic           g_io_out_2_bits_pd_isRVC;
  logic [1:0]     g_io_out_2_bits_pd_brType;
  logic           g_io_out_2_bits_pd_isCall;
  logic           g_io_out_2_bits_pd_isRet;
  logic           g_io_out_2_bits_pred_taken;
  logic           g_io_out_2_bits_crossPageIPFFix;
  logic           g_io_out_2_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_2_bits_ftqPtr_value;
  logic [3:0]     g_io_out_2_bits_ftqOffset;
  logic           g_io_out_2_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_2_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_2_bits_debug_seqNum_uopIdx;
  logic           g_io_out_3_valid;
  logic [31:0]    g_io_out_3_bits_instr;
  logic [49:0]    g_io_out_3_bits_pc;
  logic [9:0]     g_io_out_3_bits_foldpc;
  logic           g_io_out_3_bits_exceptionVec_1;
  logic           g_io_out_3_bits_exceptionVec_2;
  logic           g_io_out_3_bits_exceptionVec_12;
  logic           g_io_out_3_bits_exceptionVec_20;
  logic           g_io_out_3_bits_backendException;
  logic           g_io_out_3_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_3_bits_trigger;
  logic           g_io_out_3_bits_pd_valid;
  logic           g_io_out_3_bits_pd_isRVC;
  logic [1:0]     g_io_out_3_bits_pd_brType;
  logic           g_io_out_3_bits_pd_isCall;
  logic           g_io_out_3_bits_pd_isRet;
  logic           g_io_out_3_bits_pred_taken;
  logic           g_io_out_3_bits_crossPageIPFFix;
  logic           g_io_out_3_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_3_bits_ftqPtr_value;
  logic [3:0]     g_io_out_3_bits_ftqOffset;
  logic           g_io_out_3_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_3_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_3_bits_debug_seqNum_uopIdx;
  logic           g_io_out_4_valid;
  logic [31:0]    g_io_out_4_bits_instr;
  logic [49:0]    g_io_out_4_bits_pc;
  logic [9:0]     g_io_out_4_bits_foldpc;
  logic           g_io_out_4_bits_exceptionVec_1;
  logic           g_io_out_4_bits_exceptionVec_2;
  logic           g_io_out_4_bits_exceptionVec_12;
  logic           g_io_out_4_bits_exceptionVec_20;
  logic           g_io_out_4_bits_backendException;
  logic           g_io_out_4_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_4_bits_trigger;
  logic           g_io_out_4_bits_pd_valid;
  logic           g_io_out_4_bits_pd_isRVC;
  logic [1:0]     g_io_out_4_bits_pd_brType;
  logic           g_io_out_4_bits_pd_isCall;
  logic           g_io_out_4_bits_pd_isRet;
  logic           g_io_out_4_bits_pred_taken;
  logic           g_io_out_4_bits_crossPageIPFFix;
  logic           g_io_out_4_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_4_bits_ftqPtr_value;
  logic [3:0]     g_io_out_4_bits_ftqOffset;
  logic           g_io_out_4_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_4_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_4_bits_debug_seqNum_uopIdx;
  logic           g_io_out_5_valid;
  logic [31:0]    g_io_out_5_bits_instr;
  logic [49:0]    g_io_out_5_bits_pc;
  logic [9:0]     g_io_out_5_bits_foldpc;
  logic           g_io_out_5_bits_exceptionVec_1;
  logic           g_io_out_5_bits_exceptionVec_2;
  logic           g_io_out_5_bits_exceptionVec_12;
  logic           g_io_out_5_bits_exceptionVec_20;
  logic           g_io_out_5_bits_backendException;
  logic           g_io_out_5_bits_satpFlushFirstFetchFault;
  logic [3:0]     g_io_out_5_bits_trigger;
  logic           g_io_out_5_bits_pd_valid;
  logic           g_io_out_5_bits_pd_isRVC;
  logic [1:0]     g_io_out_5_bits_pd_brType;
  logic           g_io_out_5_bits_pd_isCall;
  logic           g_io_out_5_bits_pd_isRet;
  logic           g_io_out_5_bits_pred_taken;
  logic           g_io_out_5_bits_crossPageIPFFix;
  logic           g_io_out_5_bits_ftqPtr_flag;
  logic [5:0]     g_io_out_5_bits_ftqPtr_value;
  logic [3:0]     g_io_out_5_bits_ftqOffset;
  logic           g_io_out_5_bits_isLastInFtqEntry;
  logic [55:0]    g_io_out_5_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_5_bits_debug_seqNum_uopIdx;
  logic [5:0]     g_io_stallReason_reason_0;
  logic [5:0]     g_io_stallReason_reason_1;
  logic [5:0]     g_io_stallReason_reason_2;
  logic [5:0]     g_io_stallReason_reason_3;
  logic [5:0]     g_io_stallReason_reason_4;
  logic [5:0]     g_io_stallReason_reason_5;
  logic [5:0]     g_io_perf_0_value;
  logic [5:0]     g_io_perf_1_value;
  logic [5:0]     g_io_perf_2_value;
  logic [5:0]     g_io_perf_3_value;
  logic [5:0]     g_io_perf_4_value;
  logic [5:0]     g_io_perf_5_value;
  logic [5:0]     g_io_perf_6_value;
  logic [5:0]     g_io_perf_7_value;
  logic [5:0]     g_io_perf_8_value;
  // ---- 重写侧输出 ----
  logic           i_io_in_ready;
  logic           i_io_out_0_valid;
  logic [31:0]    i_io_out_0_bits_instr;
  logic [49:0]    i_io_out_0_bits_pc;
  logic [9:0]     i_io_out_0_bits_foldpc;
  logic           i_io_out_0_bits_exceptionVec_1;
  logic           i_io_out_0_bits_exceptionVec_2;
  logic           i_io_out_0_bits_exceptionVec_12;
  logic           i_io_out_0_bits_exceptionVec_20;
  logic           i_io_out_0_bits_backendException;
  logic           i_io_out_0_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_0_bits_trigger;
  logic           i_io_out_0_bits_pd_valid;
  logic           i_io_out_0_bits_pd_isRVC;
  logic [1:0]     i_io_out_0_bits_pd_brType;
  logic           i_io_out_0_bits_pd_isCall;
  logic           i_io_out_0_bits_pd_isRet;
  logic           i_io_out_0_bits_pred_taken;
  logic           i_io_out_0_bits_crossPageIPFFix;
  logic           i_io_out_0_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_0_bits_ftqPtr_value;
  logic [3:0]     i_io_out_0_bits_ftqOffset;
  logic           i_io_out_0_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_0_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_0_bits_debug_seqNum_uopIdx;
  logic           i_io_out_1_valid;
  logic [31:0]    i_io_out_1_bits_instr;
  logic [49:0]    i_io_out_1_bits_pc;
  logic [9:0]     i_io_out_1_bits_foldpc;
  logic           i_io_out_1_bits_exceptionVec_1;
  logic           i_io_out_1_bits_exceptionVec_2;
  logic           i_io_out_1_bits_exceptionVec_12;
  logic           i_io_out_1_bits_exceptionVec_20;
  logic           i_io_out_1_bits_backendException;
  logic           i_io_out_1_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_1_bits_trigger;
  logic           i_io_out_1_bits_pd_valid;
  logic           i_io_out_1_bits_pd_isRVC;
  logic [1:0]     i_io_out_1_bits_pd_brType;
  logic           i_io_out_1_bits_pd_isCall;
  logic           i_io_out_1_bits_pd_isRet;
  logic           i_io_out_1_bits_pred_taken;
  logic           i_io_out_1_bits_crossPageIPFFix;
  logic           i_io_out_1_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_1_bits_ftqPtr_value;
  logic [3:0]     i_io_out_1_bits_ftqOffset;
  logic           i_io_out_1_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_1_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_1_bits_debug_seqNum_uopIdx;
  logic           i_io_out_2_valid;
  logic [31:0]    i_io_out_2_bits_instr;
  logic [49:0]    i_io_out_2_bits_pc;
  logic [9:0]     i_io_out_2_bits_foldpc;
  logic           i_io_out_2_bits_exceptionVec_1;
  logic           i_io_out_2_bits_exceptionVec_2;
  logic           i_io_out_2_bits_exceptionVec_12;
  logic           i_io_out_2_bits_exceptionVec_20;
  logic           i_io_out_2_bits_backendException;
  logic           i_io_out_2_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_2_bits_trigger;
  logic           i_io_out_2_bits_pd_valid;
  logic           i_io_out_2_bits_pd_isRVC;
  logic [1:0]     i_io_out_2_bits_pd_brType;
  logic           i_io_out_2_bits_pd_isCall;
  logic           i_io_out_2_bits_pd_isRet;
  logic           i_io_out_2_bits_pred_taken;
  logic           i_io_out_2_bits_crossPageIPFFix;
  logic           i_io_out_2_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_2_bits_ftqPtr_value;
  logic [3:0]     i_io_out_2_bits_ftqOffset;
  logic           i_io_out_2_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_2_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_2_bits_debug_seqNum_uopIdx;
  logic           i_io_out_3_valid;
  logic [31:0]    i_io_out_3_bits_instr;
  logic [49:0]    i_io_out_3_bits_pc;
  logic [9:0]     i_io_out_3_bits_foldpc;
  logic           i_io_out_3_bits_exceptionVec_1;
  logic           i_io_out_3_bits_exceptionVec_2;
  logic           i_io_out_3_bits_exceptionVec_12;
  logic           i_io_out_3_bits_exceptionVec_20;
  logic           i_io_out_3_bits_backendException;
  logic           i_io_out_3_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_3_bits_trigger;
  logic           i_io_out_3_bits_pd_valid;
  logic           i_io_out_3_bits_pd_isRVC;
  logic [1:0]     i_io_out_3_bits_pd_brType;
  logic           i_io_out_3_bits_pd_isCall;
  logic           i_io_out_3_bits_pd_isRet;
  logic           i_io_out_3_bits_pred_taken;
  logic           i_io_out_3_bits_crossPageIPFFix;
  logic           i_io_out_3_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_3_bits_ftqPtr_value;
  logic [3:0]     i_io_out_3_bits_ftqOffset;
  logic           i_io_out_3_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_3_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_3_bits_debug_seqNum_uopIdx;
  logic           i_io_out_4_valid;
  logic [31:0]    i_io_out_4_bits_instr;
  logic [49:0]    i_io_out_4_bits_pc;
  logic [9:0]     i_io_out_4_bits_foldpc;
  logic           i_io_out_4_bits_exceptionVec_1;
  logic           i_io_out_4_bits_exceptionVec_2;
  logic           i_io_out_4_bits_exceptionVec_12;
  logic           i_io_out_4_bits_exceptionVec_20;
  logic           i_io_out_4_bits_backendException;
  logic           i_io_out_4_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_4_bits_trigger;
  logic           i_io_out_4_bits_pd_valid;
  logic           i_io_out_4_bits_pd_isRVC;
  logic [1:0]     i_io_out_4_bits_pd_brType;
  logic           i_io_out_4_bits_pd_isCall;
  logic           i_io_out_4_bits_pd_isRet;
  logic           i_io_out_4_bits_pred_taken;
  logic           i_io_out_4_bits_crossPageIPFFix;
  logic           i_io_out_4_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_4_bits_ftqPtr_value;
  logic [3:0]     i_io_out_4_bits_ftqOffset;
  logic           i_io_out_4_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_4_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_4_bits_debug_seqNum_uopIdx;
  logic           i_io_out_5_valid;
  logic [31:0]    i_io_out_5_bits_instr;
  logic [49:0]    i_io_out_5_bits_pc;
  logic [9:0]     i_io_out_5_bits_foldpc;
  logic           i_io_out_5_bits_exceptionVec_1;
  logic           i_io_out_5_bits_exceptionVec_2;
  logic           i_io_out_5_bits_exceptionVec_12;
  logic           i_io_out_5_bits_exceptionVec_20;
  logic           i_io_out_5_bits_backendException;
  logic           i_io_out_5_bits_satpFlushFirstFetchFault;
  logic [3:0]     i_io_out_5_bits_trigger;
  logic           i_io_out_5_bits_pd_valid;
  logic           i_io_out_5_bits_pd_isRVC;
  logic [1:0]     i_io_out_5_bits_pd_brType;
  logic           i_io_out_5_bits_pd_isCall;
  logic           i_io_out_5_bits_pd_isRet;
  logic           i_io_out_5_bits_pred_taken;
  logic           i_io_out_5_bits_crossPageIPFFix;
  logic           i_io_out_5_bits_ftqPtr_flag;
  logic [5:0]     i_io_out_5_bits_ftqPtr_value;
  logic [3:0]     i_io_out_5_bits_ftqOffset;
  logic           i_io_out_5_bits_isLastInFtqEntry;
  logic [55:0]    i_io_out_5_bits_debug_seqNum_seqNum;
  logic [7:0]     i_io_out_5_bits_debug_seqNum_uopIdx;
  logic [5:0]     i_io_stallReason_reason_0;
  logic [5:0]     i_io_stallReason_reason_1;
  logic [5:0]     i_io_stallReason_reason_2;
  logic [5:0]     i_io_stallReason_reason_3;
  logic [5:0]     i_io_stallReason_reason_4;
  logic [5:0]     i_io_stallReason_reason_5;
  logic [5:0]     i_io_perf_0_value;
  logic [5:0]     i_io_perf_1_value;
  logic [5:0]     i_io_perf_2_value;
  logic [5:0]     i_io_perf_3_value;
  logic [5:0]     i_io_perf_4_value;
  logic [5:0]     i_io_perf_5_value;
  logic [5:0]     i_io_perf_6_value;
  logic [5:0]     i_io_perf_7_value;
  logic [5:0]     i_io_perf_8_value;

  IBuffer u_golden (
    .clock(clk), .reset(rst),
    .io_flush(io_flush),
    .io_ControlRedirect(io_ControlRedirect),
    .io_ControlBTBMissBubble(io_ControlBTBMissBubble),
    .io_TAGEMissBubble(io_TAGEMissBubble),
    .io_SCMissBubble(io_SCMissBubble),
    .io_ITTAGEMissBubble(io_ITTAGEMissBubble),
    .io_RASMissBubble(io_RASMissBubble),
    .io_MemVioRedirect(io_MemVioRedirect),
    .io_in_valid(io_in_valid),
    .io_in_bits_instrs_0(io_in_bits_instrs_0),
    .io_in_bits_instrs_1(io_in_bits_instrs_1),
    .io_in_bits_instrs_2(io_in_bits_instrs_2),
    .io_in_bits_instrs_3(io_in_bits_instrs_3),
    .io_in_bits_instrs_4(io_in_bits_instrs_4),
    .io_in_bits_instrs_5(io_in_bits_instrs_5),
    .io_in_bits_instrs_6(io_in_bits_instrs_6),
    .io_in_bits_instrs_7(io_in_bits_instrs_7),
    .io_in_bits_instrs_8(io_in_bits_instrs_8),
    .io_in_bits_instrs_9(io_in_bits_instrs_9),
    .io_in_bits_instrs_10(io_in_bits_instrs_10),
    .io_in_bits_instrs_11(io_in_bits_instrs_11),
    .io_in_bits_instrs_12(io_in_bits_instrs_12),
    .io_in_bits_instrs_13(io_in_bits_instrs_13),
    .io_in_bits_instrs_14(io_in_bits_instrs_14),
    .io_in_bits_instrs_15(io_in_bits_instrs_15),
    .io_in_bits_valid(io_in_bits_valid),
    .io_in_bits_enqEnable(io_in_bits_enqEnable),
    .io_in_bits_pd_0_isRVC(io_in_bits_pd_0_isRVC),
    .io_in_bits_pd_0_brType(io_in_bits_pd_0_brType),
    .io_in_bits_pd_0_isCall(io_in_bits_pd_0_isCall),
    .io_in_bits_pd_0_isRet(io_in_bits_pd_0_isRet),
    .io_in_bits_pd_1_valid(io_in_bits_pd_1_valid),
    .io_in_bits_pd_1_isRVC(io_in_bits_pd_1_isRVC),
    .io_in_bits_pd_1_brType(io_in_bits_pd_1_brType),
    .io_in_bits_pd_1_isCall(io_in_bits_pd_1_isCall),
    .io_in_bits_pd_1_isRet(io_in_bits_pd_1_isRet),
    .io_in_bits_pd_2_valid(io_in_bits_pd_2_valid),
    .io_in_bits_pd_2_isRVC(io_in_bits_pd_2_isRVC),
    .io_in_bits_pd_2_brType(io_in_bits_pd_2_brType),
    .io_in_bits_pd_2_isCall(io_in_bits_pd_2_isCall),
    .io_in_bits_pd_2_isRet(io_in_bits_pd_2_isRet),
    .io_in_bits_pd_3_valid(io_in_bits_pd_3_valid),
    .io_in_bits_pd_3_isRVC(io_in_bits_pd_3_isRVC),
    .io_in_bits_pd_3_brType(io_in_bits_pd_3_brType),
    .io_in_bits_pd_3_isCall(io_in_bits_pd_3_isCall),
    .io_in_bits_pd_3_isRet(io_in_bits_pd_3_isRet),
    .io_in_bits_pd_4_valid(io_in_bits_pd_4_valid),
    .io_in_bits_pd_4_isRVC(io_in_bits_pd_4_isRVC),
    .io_in_bits_pd_4_brType(io_in_bits_pd_4_brType),
    .io_in_bits_pd_4_isCall(io_in_bits_pd_4_isCall),
    .io_in_bits_pd_4_isRet(io_in_bits_pd_4_isRet),
    .io_in_bits_pd_5_valid(io_in_bits_pd_5_valid),
    .io_in_bits_pd_5_isRVC(io_in_bits_pd_5_isRVC),
    .io_in_bits_pd_5_brType(io_in_bits_pd_5_brType),
    .io_in_bits_pd_5_isCall(io_in_bits_pd_5_isCall),
    .io_in_bits_pd_5_isRet(io_in_bits_pd_5_isRet),
    .io_in_bits_pd_6_valid(io_in_bits_pd_6_valid),
    .io_in_bits_pd_6_isRVC(io_in_bits_pd_6_isRVC),
    .io_in_bits_pd_6_brType(io_in_bits_pd_6_brType),
    .io_in_bits_pd_6_isCall(io_in_bits_pd_6_isCall),
    .io_in_bits_pd_6_isRet(io_in_bits_pd_6_isRet),
    .io_in_bits_pd_7_valid(io_in_bits_pd_7_valid),
    .io_in_bits_pd_7_isRVC(io_in_bits_pd_7_isRVC),
    .io_in_bits_pd_7_brType(io_in_bits_pd_7_brType),
    .io_in_bits_pd_7_isCall(io_in_bits_pd_7_isCall),
    .io_in_bits_pd_7_isRet(io_in_bits_pd_7_isRet),
    .io_in_bits_pd_8_valid(io_in_bits_pd_8_valid),
    .io_in_bits_pd_8_isRVC(io_in_bits_pd_8_isRVC),
    .io_in_bits_pd_8_brType(io_in_bits_pd_8_brType),
    .io_in_bits_pd_8_isCall(io_in_bits_pd_8_isCall),
    .io_in_bits_pd_8_isRet(io_in_bits_pd_8_isRet),
    .io_in_bits_pd_9_valid(io_in_bits_pd_9_valid),
    .io_in_bits_pd_9_isRVC(io_in_bits_pd_9_isRVC),
    .io_in_bits_pd_9_brType(io_in_bits_pd_9_brType),
    .io_in_bits_pd_9_isCall(io_in_bits_pd_9_isCall),
    .io_in_bits_pd_9_isRet(io_in_bits_pd_9_isRet),
    .io_in_bits_pd_10_valid(io_in_bits_pd_10_valid),
    .io_in_bits_pd_10_isRVC(io_in_bits_pd_10_isRVC),
    .io_in_bits_pd_10_brType(io_in_bits_pd_10_brType),
    .io_in_bits_pd_10_isCall(io_in_bits_pd_10_isCall),
    .io_in_bits_pd_10_isRet(io_in_bits_pd_10_isRet),
    .io_in_bits_pd_11_valid(io_in_bits_pd_11_valid),
    .io_in_bits_pd_11_isRVC(io_in_bits_pd_11_isRVC),
    .io_in_bits_pd_11_brType(io_in_bits_pd_11_brType),
    .io_in_bits_pd_11_isCall(io_in_bits_pd_11_isCall),
    .io_in_bits_pd_11_isRet(io_in_bits_pd_11_isRet),
    .io_in_bits_pd_12_valid(io_in_bits_pd_12_valid),
    .io_in_bits_pd_12_isRVC(io_in_bits_pd_12_isRVC),
    .io_in_bits_pd_12_brType(io_in_bits_pd_12_brType),
    .io_in_bits_pd_12_isCall(io_in_bits_pd_12_isCall),
    .io_in_bits_pd_12_isRet(io_in_bits_pd_12_isRet),
    .io_in_bits_pd_13_valid(io_in_bits_pd_13_valid),
    .io_in_bits_pd_13_isRVC(io_in_bits_pd_13_isRVC),
    .io_in_bits_pd_13_brType(io_in_bits_pd_13_brType),
    .io_in_bits_pd_13_isCall(io_in_bits_pd_13_isCall),
    .io_in_bits_pd_13_isRet(io_in_bits_pd_13_isRet),
    .io_in_bits_pd_14_valid(io_in_bits_pd_14_valid),
    .io_in_bits_pd_14_isRVC(io_in_bits_pd_14_isRVC),
    .io_in_bits_pd_14_brType(io_in_bits_pd_14_brType),
    .io_in_bits_pd_14_isCall(io_in_bits_pd_14_isCall),
    .io_in_bits_pd_14_isRet(io_in_bits_pd_14_isRet),
    .io_in_bits_pd_15_valid(io_in_bits_pd_15_valid),
    .io_in_bits_pd_15_isRVC(io_in_bits_pd_15_isRVC),
    .io_in_bits_pd_15_brType(io_in_bits_pd_15_brType),
    .io_in_bits_pd_15_isCall(io_in_bits_pd_15_isCall),
    .io_in_bits_pd_15_isRet(io_in_bits_pd_15_isRet),
    .io_in_bits_foldpc_0(io_in_bits_foldpc_0),
    .io_in_bits_foldpc_1(io_in_bits_foldpc_1),
    .io_in_bits_foldpc_2(io_in_bits_foldpc_2),
    .io_in_bits_foldpc_3(io_in_bits_foldpc_3),
    .io_in_bits_foldpc_4(io_in_bits_foldpc_4),
    .io_in_bits_foldpc_5(io_in_bits_foldpc_5),
    .io_in_bits_foldpc_6(io_in_bits_foldpc_6),
    .io_in_bits_foldpc_7(io_in_bits_foldpc_7),
    .io_in_bits_foldpc_8(io_in_bits_foldpc_8),
    .io_in_bits_foldpc_9(io_in_bits_foldpc_9),
    .io_in_bits_foldpc_10(io_in_bits_foldpc_10),
    .io_in_bits_foldpc_11(io_in_bits_foldpc_11),
    .io_in_bits_foldpc_12(io_in_bits_foldpc_12),
    .io_in_bits_foldpc_13(io_in_bits_foldpc_13),
    .io_in_bits_foldpc_14(io_in_bits_foldpc_14),
    .io_in_bits_foldpc_15(io_in_bits_foldpc_15),
    .io_in_bits_ftqOffset_0_valid(io_in_bits_ftqOffset_0_valid),
    .io_in_bits_ftqOffset_1_valid(io_in_bits_ftqOffset_1_valid),
    .io_in_bits_ftqOffset_2_valid(io_in_bits_ftqOffset_2_valid),
    .io_in_bits_ftqOffset_3_valid(io_in_bits_ftqOffset_3_valid),
    .io_in_bits_ftqOffset_4_valid(io_in_bits_ftqOffset_4_valid),
    .io_in_bits_ftqOffset_5_valid(io_in_bits_ftqOffset_5_valid),
    .io_in_bits_ftqOffset_6_valid(io_in_bits_ftqOffset_6_valid),
    .io_in_bits_ftqOffset_7_valid(io_in_bits_ftqOffset_7_valid),
    .io_in_bits_ftqOffset_8_valid(io_in_bits_ftqOffset_8_valid),
    .io_in_bits_ftqOffset_9_valid(io_in_bits_ftqOffset_9_valid),
    .io_in_bits_ftqOffset_10_valid(io_in_bits_ftqOffset_10_valid),
    .io_in_bits_ftqOffset_11_valid(io_in_bits_ftqOffset_11_valid),
    .io_in_bits_ftqOffset_12_valid(io_in_bits_ftqOffset_12_valid),
    .io_in_bits_ftqOffset_13_valid(io_in_bits_ftqOffset_13_valid),
    .io_in_bits_ftqOffset_14_valid(io_in_bits_ftqOffset_14_valid),
    .io_in_bits_ftqOffset_15_valid(io_in_bits_ftqOffset_15_valid),
    .io_in_bits_backendException_0(io_in_bits_backendException_0),
    .io_in_bits_satpFlushFirstFetchFault_0(io_in_bits_satpFlushFirstFetchFault_0),
    .io_in_bits_exceptionType_0(io_in_bits_exceptionType_0),
    .io_in_bits_exceptionType_1(io_in_bits_exceptionType_1),
    .io_in_bits_exceptionType_2(io_in_bits_exceptionType_2),
    .io_in_bits_exceptionType_3(io_in_bits_exceptionType_3),
    .io_in_bits_exceptionType_4(io_in_bits_exceptionType_4),
    .io_in_bits_exceptionType_5(io_in_bits_exceptionType_5),
    .io_in_bits_exceptionType_6(io_in_bits_exceptionType_6),
    .io_in_bits_exceptionType_7(io_in_bits_exceptionType_7),
    .io_in_bits_exceptionType_8(io_in_bits_exceptionType_8),
    .io_in_bits_exceptionType_9(io_in_bits_exceptionType_9),
    .io_in_bits_exceptionType_10(io_in_bits_exceptionType_10),
    .io_in_bits_exceptionType_11(io_in_bits_exceptionType_11),
    .io_in_bits_exceptionType_12(io_in_bits_exceptionType_12),
    .io_in_bits_exceptionType_13(io_in_bits_exceptionType_13),
    .io_in_bits_exceptionType_14(io_in_bits_exceptionType_14),
    .io_in_bits_exceptionType_15(io_in_bits_exceptionType_15),
    .io_in_bits_crossPageIPFFix_0(io_in_bits_crossPageIPFFix_0),
    .io_in_bits_crossPageIPFFix_1(io_in_bits_crossPageIPFFix_1),
    .io_in_bits_crossPageIPFFix_2(io_in_bits_crossPageIPFFix_2),
    .io_in_bits_crossPageIPFFix_3(io_in_bits_crossPageIPFFix_3),
    .io_in_bits_crossPageIPFFix_4(io_in_bits_crossPageIPFFix_4),
    .io_in_bits_crossPageIPFFix_5(io_in_bits_crossPageIPFFix_5),
    .io_in_bits_crossPageIPFFix_6(io_in_bits_crossPageIPFFix_6),
    .io_in_bits_crossPageIPFFix_7(io_in_bits_crossPageIPFFix_7),
    .io_in_bits_crossPageIPFFix_8(io_in_bits_crossPageIPFFix_8),
    .io_in_bits_crossPageIPFFix_9(io_in_bits_crossPageIPFFix_9),
    .io_in_bits_crossPageIPFFix_10(io_in_bits_crossPageIPFFix_10),
    .io_in_bits_crossPageIPFFix_11(io_in_bits_crossPageIPFFix_11),
    .io_in_bits_crossPageIPFFix_12(io_in_bits_crossPageIPFFix_12),
    .io_in_bits_crossPageIPFFix_13(io_in_bits_crossPageIPFFix_13),
    .io_in_bits_crossPageIPFFix_14(io_in_bits_crossPageIPFFix_14),
    .io_in_bits_crossPageIPFFix_15(io_in_bits_crossPageIPFFix_15),
    .io_in_bits_illegalInstr_0(io_in_bits_illegalInstr_0),
    .io_in_bits_illegalInstr_1(io_in_bits_illegalInstr_1),
    .io_in_bits_illegalInstr_2(io_in_bits_illegalInstr_2),
    .io_in_bits_illegalInstr_3(io_in_bits_illegalInstr_3),
    .io_in_bits_illegalInstr_4(io_in_bits_illegalInstr_4),
    .io_in_bits_illegalInstr_5(io_in_bits_illegalInstr_5),
    .io_in_bits_illegalInstr_6(io_in_bits_illegalInstr_6),
    .io_in_bits_illegalInstr_7(io_in_bits_illegalInstr_7),
    .io_in_bits_illegalInstr_8(io_in_bits_illegalInstr_8),
    .io_in_bits_illegalInstr_9(io_in_bits_illegalInstr_9),
    .io_in_bits_illegalInstr_10(io_in_bits_illegalInstr_10),
    .io_in_bits_illegalInstr_11(io_in_bits_illegalInstr_11),
    .io_in_bits_illegalInstr_12(io_in_bits_illegalInstr_12),
    .io_in_bits_illegalInstr_13(io_in_bits_illegalInstr_13),
    .io_in_bits_illegalInstr_14(io_in_bits_illegalInstr_14),
    .io_in_bits_illegalInstr_15(io_in_bits_illegalInstr_15),
    .io_in_bits_triggered_0(io_in_bits_triggered_0),
    .io_in_bits_triggered_1(io_in_bits_triggered_1),
    .io_in_bits_triggered_2(io_in_bits_triggered_2),
    .io_in_bits_triggered_3(io_in_bits_triggered_3),
    .io_in_bits_triggered_4(io_in_bits_triggered_4),
    .io_in_bits_triggered_5(io_in_bits_triggered_5),
    .io_in_bits_triggered_6(io_in_bits_triggered_6),
    .io_in_bits_triggered_7(io_in_bits_triggered_7),
    .io_in_bits_triggered_8(io_in_bits_triggered_8),
    .io_in_bits_triggered_9(io_in_bits_triggered_9),
    .io_in_bits_triggered_10(io_in_bits_triggered_10),
    .io_in_bits_triggered_11(io_in_bits_triggered_11),
    .io_in_bits_triggered_12(io_in_bits_triggered_12),
    .io_in_bits_triggered_13(io_in_bits_triggered_13),
    .io_in_bits_triggered_14(io_in_bits_triggered_14),
    .io_in_bits_triggered_15(io_in_bits_triggered_15),
    .io_in_bits_isLastInFtqEntry_0(io_in_bits_isLastInFtqEntry_0),
    .io_in_bits_isLastInFtqEntry_1(io_in_bits_isLastInFtqEntry_1),
    .io_in_bits_isLastInFtqEntry_2(io_in_bits_isLastInFtqEntry_2),
    .io_in_bits_isLastInFtqEntry_3(io_in_bits_isLastInFtqEntry_3),
    .io_in_bits_isLastInFtqEntry_4(io_in_bits_isLastInFtqEntry_4),
    .io_in_bits_isLastInFtqEntry_5(io_in_bits_isLastInFtqEntry_5),
    .io_in_bits_isLastInFtqEntry_6(io_in_bits_isLastInFtqEntry_6),
    .io_in_bits_isLastInFtqEntry_7(io_in_bits_isLastInFtqEntry_7),
    .io_in_bits_isLastInFtqEntry_8(io_in_bits_isLastInFtqEntry_8),
    .io_in_bits_isLastInFtqEntry_9(io_in_bits_isLastInFtqEntry_9),
    .io_in_bits_isLastInFtqEntry_10(io_in_bits_isLastInFtqEntry_10),
    .io_in_bits_isLastInFtqEntry_11(io_in_bits_isLastInFtqEntry_11),
    .io_in_bits_isLastInFtqEntry_12(io_in_bits_isLastInFtqEntry_12),
    .io_in_bits_isLastInFtqEntry_13(io_in_bits_isLastInFtqEntry_13),
    .io_in_bits_isLastInFtqEntry_14(io_in_bits_isLastInFtqEntry_14),
    .io_in_bits_isLastInFtqEntry_15(io_in_bits_isLastInFtqEntry_15),
    .io_in_bits_pc_0(io_in_bits_pc_0),
    .io_in_bits_pc_1(io_in_bits_pc_1),
    .io_in_bits_pc_2(io_in_bits_pc_2),
    .io_in_bits_pc_3(io_in_bits_pc_3),
    .io_in_bits_pc_4(io_in_bits_pc_4),
    .io_in_bits_pc_5(io_in_bits_pc_5),
    .io_in_bits_pc_6(io_in_bits_pc_6),
    .io_in_bits_pc_7(io_in_bits_pc_7),
    .io_in_bits_pc_8(io_in_bits_pc_8),
    .io_in_bits_pc_9(io_in_bits_pc_9),
    .io_in_bits_pc_10(io_in_bits_pc_10),
    .io_in_bits_pc_11(io_in_bits_pc_11),
    .io_in_bits_pc_12(io_in_bits_pc_12),
    .io_in_bits_pc_13(io_in_bits_pc_13),
    .io_in_bits_pc_14(io_in_bits_pc_14),
    .io_in_bits_pc_15(io_in_bits_pc_15),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_topdown_info_reasons_0(io_in_bits_topdown_info_reasons_0),
    .io_in_bits_topdown_info_reasons_1(io_in_bits_topdown_info_reasons_1),
    .io_in_bits_topdown_info_reasons_2(io_in_bits_topdown_info_reasons_2),
    .io_in_bits_topdown_info_reasons_3(io_in_bits_topdown_info_reasons_3),
    .io_in_bits_topdown_info_reasons_4(io_in_bits_topdown_info_reasons_4),
    .io_in_bits_topdown_info_reasons_5(io_in_bits_topdown_info_reasons_5),
    .io_in_bits_topdown_info_reasons_6(io_in_bits_topdown_info_reasons_6),
    .io_in_bits_topdown_info_reasons_7(io_in_bits_topdown_info_reasons_7),
    .io_in_bits_topdown_info_reasons_8(io_in_bits_topdown_info_reasons_8),
    .io_in_bits_topdown_info_reasons_9(io_in_bits_topdown_info_reasons_9),
    .io_in_bits_topdown_info_reasons_10(io_in_bits_topdown_info_reasons_10),
    .io_in_bits_topdown_info_reasons_11(io_in_bits_topdown_info_reasons_11),
    .io_in_bits_topdown_info_reasons_12(io_in_bits_topdown_info_reasons_12),
    .io_in_bits_topdown_info_reasons_13(io_in_bits_topdown_info_reasons_13),
    .io_in_bits_topdown_info_reasons_14(io_in_bits_topdown_info_reasons_14),
    .io_in_bits_topdown_info_reasons_15(io_in_bits_topdown_info_reasons_15),
    .io_in_bits_topdown_info_reasons_16(io_in_bits_topdown_info_reasons_16),
    .io_in_bits_topdown_info_reasons_17(io_in_bits_topdown_info_reasons_17),
    .io_in_bits_topdown_info_reasons_18(io_in_bits_topdown_info_reasons_18),
    .io_in_bits_topdown_info_reasons_19(io_in_bits_topdown_info_reasons_19),
    .io_in_bits_topdown_info_reasons_20(io_in_bits_topdown_info_reasons_20),
    .io_in_bits_topdown_info_reasons_21(io_in_bits_topdown_info_reasons_21),
    .io_in_bits_topdown_info_reasons_22(io_in_bits_topdown_info_reasons_22),
    .io_in_bits_topdown_info_reasons_23(io_in_bits_topdown_info_reasons_23),
    .io_in_bits_topdown_info_reasons_24(io_in_bits_topdown_info_reasons_24),
    .io_in_bits_topdown_info_reasons_25(io_in_bits_topdown_info_reasons_25),
    .io_in_bits_topdown_info_reasons_26(io_in_bits_topdown_info_reasons_26),
    .io_in_bits_topdown_info_reasons_27(io_in_bits_topdown_info_reasons_27),
    .io_in_bits_topdown_info_reasons_28(io_in_bits_topdown_info_reasons_28),
    .io_in_bits_topdown_info_reasons_29(io_in_bits_topdown_info_reasons_29),
    .io_in_bits_topdown_info_reasons_30(io_in_bits_topdown_info_reasons_30),
    .io_in_bits_topdown_info_reasons_31(io_in_bits_topdown_info_reasons_31),
    .io_in_bits_topdown_info_reasons_32(io_in_bits_topdown_info_reasons_32),
    .io_in_bits_topdown_info_reasons_33(io_in_bits_topdown_info_reasons_33),
    .io_in_bits_topdown_info_reasons_34(io_in_bits_topdown_info_reasons_34),
    .io_in_bits_topdown_info_reasons_35(io_in_bits_topdown_info_reasons_35),
    .io_in_bits_topdown_info_reasons_36(io_in_bits_topdown_info_reasons_36),
    .io_in_bits_topdown_info_reasons_37(io_in_bits_topdown_info_reasons_37),
    .io_decodeCanAccept(io_decodeCanAccept),
    .io_stallReason_backReason_valid(io_stallReason_backReason_valid),
    .io_stallReason_backReason_bits(io_stallReason_backReason_bits),
    .io_in_ready(g_io_in_ready),
    .io_out_0_valid(g_io_out_0_valid),
    .io_out_0_bits_instr(g_io_out_0_bits_instr),
    .io_out_0_bits_pc(g_io_out_0_bits_pc),
    .io_out_0_bits_foldpc(g_io_out_0_bits_foldpc),
    .io_out_0_bits_exceptionVec_1(g_io_out_0_bits_exceptionVec_1),
    .io_out_0_bits_exceptionVec_2(g_io_out_0_bits_exceptionVec_2),
    .io_out_0_bits_exceptionVec_12(g_io_out_0_bits_exceptionVec_12),
    .io_out_0_bits_exceptionVec_20(g_io_out_0_bits_exceptionVec_20),
    .io_out_0_bits_backendException(g_io_out_0_bits_backendException),
    .io_out_0_bits_satpFlushFirstFetchFault(g_io_out_0_bits_satpFlushFirstFetchFault),
    .io_out_0_bits_trigger(g_io_out_0_bits_trigger),
    .io_out_0_bits_pd_valid(g_io_out_0_bits_pd_valid),
    .io_out_0_bits_pd_isRVC(g_io_out_0_bits_pd_isRVC),
    .io_out_0_bits_pd_brType(g_io_out_0_bits_pd_brType),
    .io_out_0_bits_pd_isCall(g_io_out_0_bits_pd_isCall),
    .io_out_0_bits_pd_isRet(g_io_out_0_bits_pd_isRet),
    .io_out_0_bits_pred_taken(g_io_out_0_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(g_io_out_0_bits_crossPageIPFFix),
    .io_out_0_bits_ftqPtr_flag(g_io_out_0_bits_ftqPtr_flag),
    .io_out_0_bits_ftqPtr_value(g_io_out_0_bits_ftqPtr_value),
    .io_out_0_bits_ftqOffset(g_io_out_0_bits_ftqOffset),
    .io_out_0_bits_isLastInFtqEntry(g_io_out_0_bits_isLastInFtqEntry),
    .io_out_0_bits_debug_seqNum_seqNum(g_io_out_0_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx(g_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_valid(g_io_out_1_valid),
    .io_out_1_bits_instr(g_io_out_1_bits_instr),
    .io_out_1_bits_pc(g_io_out_1_bits_pc),
    .io_out_1_bits_foldpc(g_io_out_1_bits_foldpc),
    .io_out_1_bits_exceptionVec_1(g_io_out_1_bits_exceptionVec_1),
    .io_out_1_bits_exceptionVec_2(g_io_out_1_bits_exceptionVec_2),
    .io_out_1_bits_exceptionVec_12(g_io_out_1_bits_exceptionVec_12),
    .io_out_1_bits_exceptionVec_20(g_io_out_1_bits_exceptionVec_20),
    .io_out_1_bits_backendException(g_io_out_1_bits_backendException),
    .io_out_1_bits_satpFlushFirstFetchFault(g_io_out_1_bits_satpFlushFirstFetchFault),
    .io_out_1_bits_trigger(g_io_out_1_bits_trigger),
    .io_out_1_bits_pd_valid(g_io_out_1_bits_pd_valid),
    .io_out_1_bits_pd_isRVC(g_io_out_1_bits_pd_isRVC),
    .io_out_1_bits_pd_brType(g_io_out_1_bits_pd_brType),
    .io_out_1_bits_pd_isCall(g_io_out_1_bits_pd_isCall),
    .io_out_1_bits_pd_isRet(g_io_out_1_bits_pd_isRet),
    .io_out_1_bits_pred_taken(g_io_out_1_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(g_io_out_1_bits_crossPageIPFFix),
    .io_out_1_bits_ftqPtr_flag(g_io_out_1_bits_ftqPtr_flag),
    .io_out_1_bits_ftqPtr_value(g_io_out_1_bits_ftqPtr_value),
    .io_out_1_bits_ftqOffset(g_io_out_1_bits_ftqOffset),
    .io_out_1_bits_isLastInFtqEntry(g_io_out_1_bits_isLastInFtqEntry),
    .io_out_1_bits_debug_seqNum_seqNum(g_io_out_1_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx(g_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_valid(g_io_out_2_valid),
    .io_out_2_bits_instr(g_io_out_2_bits_instr),
    .io_out_2_bits_pc(g_io_out_2_bits_pc),
    .io_out_2_bits_foldpc(g_io_out_2_bits_foldpc),
    .io_out_2_bits_exceptionVec_1(g_io_out_2_bits_exceptionVec_1),
    .io_out_2_bits_exceptionVec_2(g_io_out_2_bits_exceptionVec_2),
    .io_out_2_bits_exceptionVec_12(g_io_out_2_bits_exceptionVec_12),
    .io_out_2_bits_exceptionVec_20(g_io_out_2_bits_exceptionVec_20),
    .io_out_2_bits_backendException(g_io_out_2_bits_backendException),
    .io_out_2_bits_satpFlushFirstFetchFault(g_io_out_2_bits_satpFlushFirstFetchFault),
    .io_out_2_bits_trigger(g_io_out_2_bits_trigger),
    .io_out_2_bits_pd_valid(g_io_out_2_bits_pd_valid),
    .io_out_2_bits_pd_isRVC(g_io_out_2_bits_pd_isRVC),
    .io_out_2_bits_pd_brType(g_io_out_2_bits_pd_brType),
    .io_out_2_bits_pd_isCall(g_io_out_2_bits_pd_isCall),
    .io_out_2_bits_pd_isRet(g_io_out_2_bits_pd_isRet),
    .io_out_2_bits_pred_taken(g_io_out_2_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(g_io_out_2_bits_crossPageIPFFix),
    .io_out_2_bits_ftqPtr_flag(g_io_out_2_bits_ftqPtr_flag),
    .io_out_2_bits_ftqPtr_value(g_io_out_2_bits_ftqPtr_value),
    .io_out_2_bits_ftqOffset(g_io_out_2_bits_ftqOffset),
    .io_out_2_bits_isLastInFtqEntry(g_io_out_2_bits_isLastInFtqEntry),
    .io_out_2_bits_debug_seqNum_seqNum(g_io_out_2_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx(g_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_valid(g_io_out_3_valid),
    .io_out_3_bits_instr(g_io_out_3_bits_instr),
    .io_out_3_bits_pc(g_io_out_3_bits_pc),
    .io_out_3_bits_foldpc(g_io_out_3_bits_foldpc),
    .io_out_3_bits_exceptionVec_1(g_io_out_3_bits_exceptionVec_1),
    .io_out_3_bits_exceptionVec_2(g_io_out_3_bits_exceptionVec_2),
    .io_out_3_bits_exceptionVec_12(g_io_out_3_bits_exceptionVec_12),
    .io_out_3_bits_exceptionVec_20(g_io_out_3_bits_exceptionVec_20),
    .io_out_3_bits_backendException(g_io_out_3_bits_backendException),
    .io_out_3_bits_satpFlushFirstFetchFault(g_io_out_3_bits_satpFlushFirstFetchFault),
    .io_out_3_bits_trigger(g_io_out_3_bits_trigger),
    .io_out_3_bits_pd_valid(g_io_out_3_bits_pd_valid),
    .io_out_3_bits_pd_isRVC(g_io_out_3_bits_pd_isRVC),
    .io_out_3_bits_pd_brType(g_io_out_3_bits_pd_brType),
    .io_out_3_bits_pd_isCall(g_io_out_3_bits_pd_isCall),
    .io_out_3_bits_pd_isRet(g_io_out_3_bits_pd_isRet),
    .io_out_3_bits_pred_taken(g_io_out_3_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(g_io_out_3_bits_crossPageIPFFix),
    .io_out_3_bits_ftqPtr_flag(g_io_out_3_bits_ftqPtr_flag),
    .io_out_3_bits_ftqPtr_value(g_io_out_3_bits_ftqPtr_value),
    .io_out_3_bits_ftqOffset(g_io_out_3_bits_ftqOffset),
    .io_out_3_bits_isLastInFtqEntry(g_io_out_3_bits_isLastInFtqEntry),
    .io_out_3_bits_debug_seqNum_seqNum(g_io_out_3_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx(g_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_4_valid(g_io_out_4_valid),
    .io_out_4_bits_instr(g_io_out_4_bits_instr),
    .io_out_4_bits_pc(g_io_out_4_bits_pc),
    .io_out_4_bits_foldpc(g_io_out_4_bits_foldpc),
    .io_out_4_bits_exceptionVec_1(g_io_out_4_bits_exceptionVec_1),
    .io_out_4_bits_exceptionVec_2(g_io_out_4_bits_exceptionVec_2),
    .io_out_4_bits_exceptionVec_12(g_io_out_4_bits_exceptionVec_12),
    .io_out_4_bits_exceptionVec_20(g_io_out_4_bits_exceptionVec_20),
    .io_out_4_bits_backendException(g_io_out_4_bits_backendException),
    .io_out_4_bits_satpFlushFirstFetchFault(g_io_out_4_bits_satpFlushFirstFetchFault),
    .io_out_4_bits_trigger(g_io_out_4_bits_trigger),
    .io_out_4_bits_pd_valid(g_io_out_4_bits_pd_valid),
    .io_out_4_bits_pd_isRVC(g_io_out_4_bits_pd_isRVC),
    .io_out_4_bits_pd_brType(g_io_out_4_bits_pd_brType),
    .io_out_4_bits_pd_isCall(g_io_out_4_bits_pd_isCall),
    .io_out_4_bits_pd_isRet(g_io_out_4_bits_pd_isRet),
    .io_out_4_bits_pred_taken(g_io_out_4_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(g_io_out_4_bits_crossPageIPFFix),
    .io_out_4_bits_ftqPtr_flag(g_io_out_4_bits_ftqPtr_flag),
    .io_out_4_bits_ftqPtr_value(g_io_out_4_bits_ftqPtr_value),
    .io_out_4_bits_ftqOffset(g_io_out_4_bits_ftqOffset),
    .io_out_4_bits_isLastInFtqEntry(g_io_out_4_bits_isLastInFtqEntry),
    .io_out_4_bits_debug_seqNum_seqNum(g_io_out_4_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx(g_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_5_valid(g_io_out_5_valid),
    .io_out_5_bits_instr(g_io_out_5_bits_instr),
    .io_out_5_bits_pc(g_io_out_5_bits_pc),
    .io_out_5_bits_foldpc(g_io_out_5_bits_foldpc),
    .io_out_5_bits_exceptionVec_1(g_io_out_5_bits_exceptionVec_1),
    .io_out_5_bits_exceptionVec_2(g_io_out_5_bits_exceptionVec_2),
    .io_out_5_bits_exceptionVec_12(g_io_out_5_bits_exceptionVec_12),
    .io_out_5_bits_exceptionVec_20(g_io_out_5_bits_exceptionVec_20),
    .io_out_5_bits_backendException(g_io_out_5_bits_backendException),
    .io_out_5_bits_satpFlushFirstFetchFault(g_io_out_5_bits_satpFlushFirstFetchFault),
    .io_out_5_bits_trigger(g_io_out_5_bits_trigger),
    .io_out_5_bits_pd_valid(g_io_out_5_bits_pd_valid),
    .io_out_5_bits_pd_isRVC(g_io_out_5_bits_pd_isRVC),
    .io_out_5_bits_pd_brType(g_io_out_5_bits_pd_brType),
    .io_out_5_bits_pd_isCall(g_io_out_5_bits_pd_isCall),
    .io_out_5_bits_pd_isRet(g_io_out_5_bits_pd_isRet),
    .io_out_5_bits_pred_taken(g_io_out_5_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(g_io_out_5_bits_crossPageIPFFix),
    .io_out_5_bits_ftqPtr_flag(g_io_out_5_bits_ftqPtr_flag),
    .io_out_5_bits_ftqPtr_value(g_io_out_5_bits_ftqPtr_value),
    .io_out_5_bits_ftqOffset(g_io_out_5_bits_ftqOffset),
    .io_out_5_bits_isLastInFtqEntry(g_io_out_5_bits_isLastInFtqEntry),
    .io_out_5_bits_debug_seqNum_seqNum(g_io_out_5_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx(g_io_out_5_bits_debug_seqNum_uopIdx),
    .io_stallReason_reason_0(g_io_stallReason_reason_0),
    .io_stallReason_reason_1(g_io_stallReason_reason_1),
    .io_stallReason_reason_2(g_io_stallReason_reason_2),
    .io_stallReason_reason_3(g_io_stallReason_reason_3),
    .io_stallReason_reason_4(g_io_stallReason_reason_4),
    .io_stallReason_reason_5(g_io_stallReason_reason_5),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value),
    .io_perf_8_value(g_io_perf_8_value)
  );

  IBuffer_xs u_impl (
    .clock(clk), .reset(rst),
    .io_flush(io_flush),
    .io_ControlRedirect(io_ControlRedirect),
    .io_ControlBTBMissBubble(io_ControlBTBMissBubble),
    .io_TAGEMissBubble(io_TAGEMissBubble),
    .io_SCMissBubble(io_SCMissBubble),
    .io_ITTAGEMissBubble(io_ITTAGEMissBubble),
    .io_RASMissBubble(io_RASMissBubble),
    .io_MemVioRedirect(io_MemVioRedirect),
    .io_in_valid(io_in_valid),
    .io_in_bits_instrs_0(io_in_bits_instrs_0),
    .io_in_bits_instrs_1(io_in_bits_instrs_1),
    .io_in_bits_instrs_2(io_in_bits_instrs_2),
    .io_in_bits_instrs_3(io_in_bits_instrs_3),
    .io_in_bits_instrs_4(io_in_bits_instrs_4),
    .io_in_bits_instrs_5(io_in_bits_instrs_5),
    .io_in_bits_instrs_6(io_in_bits_instrs_6),
    .io_in_bits_instrs_7(io_in_bits_instrs_7),
    .io_in_bits_instrs_8(io_in_bits_instrs_8),
    .io_in_bits_instrs_9(io_in_bits_instrs_9),
    .io_in_bits_instrs_10(io_in_bits_instrs_10),
    .io_in_bits_instrs_11(io_in_bits_instrs_11),
    .io_in_bits_instrs_12(io_in_bits_instrs_12),
    .io_in_bits_instrs_13(io_in_bits_instrs_13),
    .io_in_bits_instrs_14(io_in_bits_instrs_14),
    .io_in_bits_instrs_15(io_in_bits_instrs_15),
    .io_in_bits_valid(io_in_bits_valid),
    .io_in_bits_enqEnable(io_in_bits_enqEnable),
    .io_in_bits_pd_0_isRVC(io_in_bits_pd_0_isRVC),
    .io_in_bits_pd_0_brType(io_in_bits_pd_0_brType),
    .io_in_bits_pd_0_isCall(io_in_bits_pd_0_isCall),
    .io_in_bits_pd_0_isRet(io_in_bits_pd_0_isRet),
    .io_in_bits_pd_1_valid(io_in_bits_pd_1_valid),
    .io_in_bits_pd_1_isRVC(io_in_bits_pd_1_isRVC),
    .io_in_bits_pd_1_brType(io_in_bits_pd_1_brType),
    .io_in_bits_pd_1_isCall(io_in_bits_pd_1_isCall),
    .io_in_bits_pd_1_isRet(io_in_bits_pd_1_isRet),
    .io_in_bits_pd_2_valid(io_in_bits_pd_2_valid),
    .io_in_bits_pd_2_isRVC(io_in_bits_pd_2_isRVC),
    .io_in_bits_pd_2_brType(io_in_bits_pd_2_brType),
    .io_in_bits_pd_2_isCall(io_in_bits_pd_2_isCall),
    .io_in_bits_pd_2_isRet(io_in_bits_pd_2_isRet),
    .io_in_bits_pd_3_valid(io_in_bits_pd_3_valid),
    .io_in_bits_pd_3_isRVC(io_in_bits_pd_3_isRVC),
    .io_in_bits_pd_3_brType(io_in_bits_pd_3_brType),
    .io_in_bits_pd_3_isCall(io_in_bits_pd_3_isCall),
    .io_in_bits_pd_3_isRet(io_in_bits_pd_3_isRet),
    .io_in_bits_pd_4_valid(io_in_bits_pd_4_valid),
    .io_in_bits_pd_4_isRVC(io_in_bits_pd_4_isRVC),
    .io_in_bits_pd_4_brType(io_in_bits_pd_4_brType),
    .io_in_bits_pd_4_isCall(io_in_bits_pd_4_isCall),
    .io_in_bits_pd_4_isRet(io_in_bits_pd_4_isRet),
    .io_in_bits_pd_5_valid(io_in_bits_pd_5_valid),
    .io_in_bits_pd_5_isRVC(io_in_bits_pd_5_isRVC),
    .io_in_bits_pd_5_brType(io_in_bits_pd_5_brType),
    .io_in_bits_pd_5_isCall(io_in_bits_pd_5_isCall),
    .io_in_bits_pd_5_isRet(io_in_bits_pd_5_isRet),
    .io_in_bits_pd_6_valid(io_in_bits_pd_6_valid),
    .io_in_bits_pd_6_isRVC(io_in_bits_pd_6_isRVC),
    .io_in_bits_pd_6_brType(io_in_bits_pd_6_brType),
    .io_in_bits_pd_6_isCall(io_in_bits_pd_6_isCall),
    .io_in_bits_pd_6_isRet(io_in_bits_pd_6_isRet),
    .io_in_bits_pd_7_valid(io_in_bits_pd_7_valid),
    .io_in_bits_pd_7_isRVC(io_in_bits_pd_7_isRVC),
    .io_in_bits_pd_7_brType(io_in_bits_pd_7_brType),
    .io_in_bits_pd_7_isCall(io_in_bits_pd_7_isCall),
    .io_in_bits_pd_7_isRet(io_in_bits_pd_7_isRet),
    .io_in_bits_pd_8_valid(io_in_bits_pd_8_valid),
    .io_in_bits_pd_8_isRVC(io_in_bits_pd_8_isRVC),
    .io_in_bits_pd_8_brType(io_in_bits_pd_8_brType),
    .io_in_bits_pd_8_isCall(io_in_bits_pd_8_isCall),
    .io_in_bits_pd_8_isRet(io_in_bits_pd_8_isRet),
    .io_in_bits_pd_9_valid(io_in_bits_pd_9_valid),
    .io_in_bits_pd_9_isRVC(io_in_bits_pd_9_isRVC),
    .io_in_bits_pd_9_brType(io_in_bits_pd_9_brType),
    .io_in_bits_pd_9_isCall(io_in_bits_pd_9_isCall),
    .io_in_bits_pd_9_isRet(io_in_bits_pd_9_isRet),
    .io_in_bits_pd_10_valid(io_in_bits_pd_10_valid),
    .io_in_bits_pd_10_isRVC(io_in_bits_pd_10_isRVC),
    .io_in_bits_pd_10_brType(io_in_bits_pd_10_brType),
    .io_in_bits_pd_10_isCall(io_in_bits_pd_10_isCall),
    .io_in_bits_pd_10_isRet(io_in_bits_pd_10_isRet),
    .io_in_bits_pd_11_valid(io_in_bits_pd_11_valid),
    .io_in_bits_pd_11_isRVC(io_in_bits_pd_11_isRVC),
    .io_in_bits_pd_11_brType(io_in_bits_pd_11_brType),
    .io_in_bits_pd_11_isCall(io_in_bits_pd_11_isCall),
    .io_in_bits_pd_11_isRet(io_in_bits_pd_11_isRet),
    .io_in_bits_pd_12_valid(io_in_bits_pd_12_valid),
    .io_in_bits_pd_12_isRVC(io_in_bits_pd_12_isRVC),
    .io_in_bits_pd_12_brType(io_in_bits_pd_12_brType),
    .io_in_bits_pd_12_isCall(io_in_bits_pd_12_isCall),
    .io_in_bits_pd_12_isRet(io_in_bits_pd_12_isRet),
    .io_in_bits_pd_13_valid(io_in_bits_pd_13_valid),
    .io_in_bits_pd_13_isRVC(io_in_bits_pd_13_isRVC),
    .io_in_bits_pd_13_brType(io_in_bits_pd_13_brType),
    .io_in_bits_pd_13_isCall(io_in_bits_pd_13_isCall),
    .io_in_bits_pd_13_isRet(io_in_bits_pd_13_isRet),
    .io_in_bits_pd_14_valid(io_in_bits_pd_14_valid),
    .io_in_bits_pd_14_isRVC(io_in_bits_pd_14_isRVC),
    .io_in_bits_pd_14_brType(io_in_bits_pd_14_brType),
    .io_in_bits_pd_14_isCall(io_in_bits_pd_14_isCall),
    .io_in_bits_pd_14_isRet(io_in_bits_pd_14_isRet),
    .io_in_bits_pd_15_valid(io_in_bits_pd_15_valid),
    .io_in_bits_pd_15_isRVC(io_in_bits_pd_15_isRVC),
    .io_in_bits_pd_15_brType(io_in_bits_pd_15_brType),
    .io_in_bits_pd_15_isCall(io_in_bits_pd_15_isCall),
    .io_in_bits_pd_15_isRet(io_in_bits_pd_15_isRet),
    .io_in_bits_foldpc_0(io_in_bits_foldpc_0),
    .io_in_bits_foldpc_1(io_in_bits_foldpc_1),
    .io_in_bits_foldpc_2(io_in_bits_foldpc_2),
    .io_in_bits_foldpc_3(io_in_bits_foldpc_3),
    .io_in_bits_foldpc_4(io_in_bits_foldpc_4),
    .io_in_bits_foldpc_5(io_in_bits_foldpc_5),
    .io_in_bits_foldpc_6(io_in_bits_foldpc_6),
    .io_in_bits_foldpc_7(io_in_bits_foldpc_7),
    .io_in_bits_foldpc_8(io_in_bits_foldpc_8),
    .io_in_bits_foldpc_9(io_in_bits_foldpc_9),
    .io_in_bits_foldpc_10(io_in_bits_foldpc_10),
    .io_in_bits_foldpc_11(io_in_bits_foldpc_11),
    .io_in_bits_foldpc_12(io_in_bits_foldpc_12),
    .io_in_bits_foldpc_13(io_in_bits_foldpc_13),
    .io_in_bits_foldpc_14(io_in_bits_foldpc_14),
    .io_in_bits_foldpc_15(io_in_bits_foldpc_15),
    .io_in_bits_ftqOffset_0_valid(io_in_bits_ftqOffset_0_valid),
    .io_in_bits_ftqOffset_1_valid(io_in_bits_ftqOffset_1_valid),
    .io_in_bits_ftqOffset_2_valid(io_in_bits_ftqOffset_2_valid),
    .io_in_bits_ftqOffset_3_valid(io_in_bits_ftqOffset_3_valid),
    .io_in_bits_ftqOffset_4_valid(io_in_bits_ftqOffset_4_valid),
    .io_in_bits_ftqOffset_5_valid(io_in_bits_ftqOffset_5_valid),
    .io_in_bits_ftqOffset_6_valid(io_in_bits_ftqOffset_6_valid),
    .io_in_bits_ftqOffset_7_valid(io_in_bits_ftqOffset_7_valid),
    .io_in_bits_ftqOffset_8_valid(io_in_bits_ftqOffset_8_valid),
    .io_in_bits_ftqOffset_9_valid(io_in_bits_ftqOffset_9_valid),
    .io_in_bits_ftqOffset_10_valid(io_in_bits_ftqOffset_10_valid),
    .io_in_bits_ftqOffset_11_valid(io_in_bits_ftqOffset_11_valid),
    .io_in_bits_ftqOffset_12_valid(io_in_bits_ftqOffset_12_valid),
    .io_in_bits_ftqOffset_13_valid(io_in_bits_ftqOffset_13_valid),
    .io_in_bits_ftqOffset_14_valid(io_in_bits_ftqOffset_14_valid),
    .io_in_bits_ftqOffset_15_valid(io_in_bits_ftqOffset_15_valid),
    .io_in_bits_backendException_0(io_in_bits_backendException_0),
    .io_in_bits_satpFlushFirstFetchFault_0(io_in_bits_satpFlushFirstFetchFault_0),
    .io_in_bits_exceptionType_0(io_in_bits_exceptionType_0),
    .io_in_bits_exceptionType_1(io_in_bits_exceptionType_1),
    .io_in_bits_exceptionType_2(io_in_bits_exceptionType_2),
    .io_in_bits_exceptionType_3(io_in_bits_exceptionType_3),
    .io_in_bits_exceptionType_4(io_in_bits_exceptionType_4),
    .io_in_bits_exceptionType_5(io_in_bits_exceptionType_5),
    .io_in_bits_exceptionType_6(io_in_bits_exceptionType_6),
    .io_in_bits_exceptionType_7(io_in_bits_exceptionType_7),
    .io_in_bits_exceptionType_8(io_in_bits_exceptionType_8),
    .io_in_bits_exceptionType_9(io_in_bits_exceptionType_9),
    .io_in_bits_exceptionType_10(io_in_bits_exceptionType_10),
    .io_in_bits_exceptionType_11(io_in_bits_exceptionType_11),
    .io_in_bits_exceptionType_12(io_in_bits_exceptionType_12),
    .io_in_bits_exceptionType_13(io_in_bits_exceptionType_13),
    .io_in_bits_exceptionType_14(io_in_bits_exceptionType_14),
    .io_in_bits_exceptionType_15(io_in_bits_exceptionType_15),
    .io_in_bits_crossPageIPFFix_0(io_in_bits_crossPageIPFFix_0),
    .io_in_bits_crossPageIPFFix_1(io_in_bits_crossPageIPFFix_1),
    .io_in_bits_crossPageIPFFix_2(io_in_bits_crossPageIPFFix_2),
    .io_in_bits_crossPageIPFFix_3(io_in_bits_crossPageIPFFix_3),
    .io_in_bits_crossPageIPFFix_4(io_in_bits_crossPageIPFFix_4),
    .io_in_bits_crossPageIPFFix_5(io_in_bits_crossPageIPFFix_5),
    .io_in_bits_crossPageIPFFix_6(io_in_bits_crossPageIPFFix_6),
    .io_in_bits_crossPageIPFFix_7(io_in_bits_crossPageIPFFix_7),
    .io_in_bits_crossPageIPFFix_8(io_in_bits_crossPageIPFFix_8),
    .io_in_bits_crossPageIPFFix_9(io_in_bits_crossPageIPFFix_9),
    .io_in_bits_crossPageIPFFix_10(io_in_bits_crossPageIPFFix_10),
    .io_in_bits_crossPageIPFFix_11(io_in_bits_crossPageIPFFix_11),
    .io_in_bits_crossPageIPFFix_12(io_in_bits_crossPageIPFFix_12),
    .io_in_bits_crossPageIPFFix_13(io_in_bits_crossPageIPFFix_13),
    .io_in_bits_crossPageIPFFix_14(io_in_bits_crossPageIPFFix_14),
    .io_in_bits_crossPageIPFFix_15(io_in_bits_crossPageIPFFix_15),
    .io_in_bits_illegalInstr_0(io_in_bits_illegalInstr_0),
    .io_in_bits_illegalInstr_1(io_in_bits_illegalInstr_1),
    .io_in_bits_illegalInstr_2(io_in_bits_illegalInstr_2),
    .io_in_bits_illegalInstr_3(io_in_bits_illegalInstr_3),
    .io_in_bits_illegalInstr_4(io_in_bits_illegalInstr_4),
    .io_in_bits_illegalInstr_5(io_in_bits_illegalInstr_5),
    .io_in_bits_illegalInstr_6(io_in_bits_illegalInstr_6),
    .io_in_bits_illegalInstr_7(io_in_bits_illegalInstr_7),
    .io_in_bits_illegalInstr_8(io_in_bits_illegalInstr_8),
    .io_in_bits_illegalInstr_9(io_in_bits_illegalInstr_9),
    .io_in_bits_illegalInstr_10(io_in_bits_illegalInstr_10),
    .io_in_bits_illegalInstr_11(io_in_bits_illegalInstr_11),
    .io_in_bits_illegalInstr_12(io_in_bits_illegalInstr_12),
    .io_in_bits_illegalInstr_13(io_in_bits_illegalInstr_13),
    .io_in_bits_illegalInstr_14(io_in_bits_illegalInstr_14),
    .io_in_bits_illegalInstr_15(io_in_bits_illegalInstr_15),
    .io_in_bits_triggered_0(io_in_bits_triggered_0),
    .io_in_bits_triggered_1(io_in_bits_triggered_1),
    .io_in_bits_triggered_2(io_in_bits_triggered_2),
    .io_in_bits_triggered_3(io_in_bits_triggered_3),
    .io_in_bits_triggered_4(io_in_bits_triggered_4),
    .io_in_bits_triggered_5(io_in_bits_triggered_5),
    .io_in_bits_triggered_6(io_in_bits_triggered_6),
    .io_in_bits_triggered_7(io_in_bits_triggered_7),
    .io_in_bits_triggered_8(io_in_bits_triggered_8),
    .io_in_bits_triggered_9(io_in_bits_triggered_9),
    .io_in_bits_triggered_10(io_in_bits_triggered_10),
    .io_in_bits_triggered_11(io_in_bits_triggered_11),
    .io_in_bits_triggered_12(io_in_bits_triggered_12),
    .io_in_bits_triggered_13(io_in_bits_triggered_13),
    .io_in_bits_triggered_14(io_in_bits_triggered_14),
    .io_in_bits_triggered_15(io_in_bits_triggered_15),
    .io_in_bits_isLastInFtqEntry_0(io_in_bits_isLastInFtqEntry_0),
    .io_in_bits_isLastInFtqEntry_1(io_in_bits_isLastInFtqEntry_1),
    .io_in_bits_isLastInFtqEntry_2(io_in_bits_isLastInFtqEntry_2),
    .io_in_bits_isLastInFtqEntry_3(io_in_bits_isLastInFtqEntry_3),
    .io_in_bits_isLastInFtqEntry_4(io_in_bits_isLastInFtqEntry_4),
    .io_in_bits_isLastInFtqEntry_5(io_in_bits_isLastInFtqEntry_5),
    .io_in_bits_isLastInFtqEntry_6(io_in_bits_isLastInFtqEntry_6),
    .io_in_bits_isLastInFtqEntry_7(io_in_bits_isLastInFtqEntry_7),
    .io_in_bits_isLastInFtqEntry_8(io_in_bits_isLastInFtqEntry_8),
    .io_in_bits_isLastInFtqEntry_9(io_in_bits_isLastInFtqEntry_9),
    .io_in_bits_isLastInFtqEntry_10(io_in_bits_isLastInFtqEntry_10),
    .io_in_bits_isLastInFtqEntry_11(io_in_bits_isLastInFtqEntry_11),
    .io_in_bits_isLastInFtqEntry_12(io_in_bits_isLastInFtqEntry_12),
    .io_in_bits_isLastInFtqEntry_13(io_in_bits_isLastInFtqEntry_13),
    .io_in_bits_isLastInFtqEntry_14(io_in_bits_isLastInFtqEntry_14),
    .io_in_bits_isLastInFtqEntry_15(io_in_bits_isLastInFtqEntry_15),
    .io_in_bits_pc_0(io_in_bits_pc_0),
    .io_in_bits_pc_1(io_in_bits_pc_1),
    .io_in_bits_pc_2(io_in_bits_pc_2),
    .io_in_bits_pc_3(io_in_bits_pc_3),
    .io_in_bits_pc_4(io_in_bits_pc_4),
    .io_in_bits_pc_5(io_in_bits_pc_5),
    .io_in_bits_pc_6(io_in_bits_pc_6),
    .io_in_bits_pc_7(io_in_bits_pc_7),
    .io_in_bits_pc_8(io_in_bits_pc_8),
    .io_in_bits_pc_9(io_in_bits_pc_9),
    .io_in_bits_pc_10(io_in_bits_pc_10),
    .io_in_bits_pc_11(io_in_bits_pc_11),
    .io_in_bits_pc_12(io_in_bits_pc_12),
    .io_in_bits_pc_13(io_in_bits_pc_13),
    .io_in_bits_pc_14(io_in_bits_pc_14),
    .io_in_bits_pc_15(io_in_bits_pc_15),
    .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value),
    .io_in_bits_topdown_info_reasons_0(io_in_bits_topdown_info_reasons_0),
    .io_in_bits_topdown_info_reasons_1(io_in_bits_topdown_info_reasons_1),
    .io_in_bits_topdown_info_reasons_2(io_in_bits_topdown_info_reasons_2),
    .io_in_bits_topdown_info_reasons_3(io_in_bits_topdown_info_reasons_3),
    .io_in_bits_topdown_info_reasons_4(io_in_bits_topdown_info_reasons_4),
    .io_in_bits_topdown_info_reasons_5(io_in_bits_topdown_info_reasons_5),
    .io_in_bits_topdown_info_reasons_6(io_in_bits_topdown_info_reasons_6),
    .io_in_bits_topdown_info_reasons_7(io_in_bits_topdown_info_reasons_7),
    .io_in_bits_topdown_info_reasons_8(io_in_bits_topdown_info_reasons_8),
    .io_in_bits_topdown_info_reasons_9(io_in_bits_topdown_info_reasons_9),
    .io_in_bits_topdown_info_reasons_10(io_in_bits_topdown_info_reasons_10),
    .io_in_bits_topdown_info_reasons_11(io_in_bits_topdown_info_reasons_11),
    .io_in_bits_topdown_info_reasons_12(io_in_bits_topdown_info_reasons_12),
    .io_in_bits_topdown_info_reasons_13(io_in_bits_topdown_info_reasons_13),
    .io_in_bits_topdown_info_reasons_14(io_in_bits_topdown_info_reasons_14),
    .io_in_bits_topdown_info_reasons_15(io_in_bits_topdown_info_reasons_15),
    .io_in_bits_topdown_info_reasons_16(io_in_bits_topdown_info_reasons_16),
    .io_in_bits_topdown_info_reasons_17(io_in_bits_topdown_info_reasons_17),
    .io_in_bits_topdown_info_reasons_18(io_in_bits_topdown_info_reasons_18),
    .io_in_bits_topdown_info_reasons_19(io_in_bits_topdown_info_reasons_19),
    .io_in_bits_topdown_info_reasons_20(io_in_bits_topdown_info_reasons_20),
    .io_in_bits_topdown_info_reasons_21(io_in_bits_topdown_info_reasons_21),
    .io_in_bits_topdown_info_reasons_22(io_in_bits_topdown_info_reasons_22),
    .io_in_bits_topdown_info_reasons_23(io_in_bits_topdown_info_reasons_23),
    .io_in_bits_topdown_info_reasons_24(io_in_bits_topdown_info_reasons_24),
    .io_in_bits_topdown_info_reasons_25(io_in_bits_topdown_info_reasons_25),
    .io_in_bits_topdown_info_reasons_26(io_in_bits_topdown_info_reasons_26),
    .io_in_bits_topdown_info_reasons_27(io_in_bits_topdown_info_reasons_27),
    .io_in_bits_topdown_info_reasons_28(io_in_bits_topdown_info_reasons_28),
    .io_in_bits_topdown_info_reasons_29(io_in_bits_topdown_info_reasons_29),
    .io_in_bits_topdown_info_reasons_30(io_in_bits_topdown_info_reasons_30),
    .io_in_bits_topdown_info_reasons_31(io_in_bits_topdown_info_reasons_31),
    .io_in_bits_topdown_info_reasons_32(io_in_bits_topdown_info_reasons_32),
    .io_in_bits_topdown_info_reasons_33(io_in_bits_topdown_info_reasons_33),
    .io_in_bits_topdown_info_reasons_34(io_in_bits_topdown_info_reasons_34),
    .io_in_bits_topdown_info_reasons_35(io_in_bits_topdown_info_reasons_35),
    .io_in_bits_topdown_info_reasons_36(io_in_bits_topdown_info_reasons_36),
    .io_in_bits_topdown_info_reasons_37(io_in_bits_topdown_info_reasons_37),
    .io_decodeCanAccept(io_decodeCanAccept),
    .io_stallReason_backReason_valid(io_stallReason_backReason_valid),
    .io_stallReason_backReason_bits(io_stallReason_backReason_bits),
    .io_in_ready(i_io_in_ready),
    .io_out_0_valid(i_io_out_0_valid),
    .io_out_0_bits_instr(i_io_out_0_bits_instr),
    .io_out_0_bits_pc(i_io_out_0_bits_pc),
    .io_out_0_bits_foldpc(i_io_out_0_bits_foldpc),
    .io_out_0_bits_exceptionVec_1(i_io_out_0_bits_exceptionVec_1),
    .io_out_0_bits_exceptionVec_2(i_io_out_0_bits_exceptionVec_2),
    .io_out_0_bits_exceptionVec_12(i_io_out_0_bits_exceptionVec_12),
    .io_out_0_bits_exceptionVec_20(i_io_out_0_bits_exceptionVec_20),
    .io_out_0_bits_backendException(i_io_out_0_bits_backendException),
    .io_out_0_bits_satpFlushFirstFetchFault(i_io_out_0_bits_satpFlushFirstFetchFault),
    .io_out_0_bits_trigger(i_io_out_0_bits_trigger),
    .io_out_0_bits_pd_valid(i_io_out_0_bits_pd_valid),
    .io_out_0_bits_pd_isRVC(i_io_out_0_bits_pd_isRVC),
    .io_out_0_bits_pd_brType(i_io_out_0_bits_pd_brType),
    .io_out_0_bits_pd_isCall(i_io_out_0_bits_pd_isCall),
    .io_out_0_bits_pd_isRet(i_io_out_0_bits_pd_isRet),
    .io_out_0_bits_pred_taken(i_io_out_0_bits_pred_taken),
    .io_out_0_bits_crossPageIPFFix(i_io_out_0_bits_crossPageIPFFix),
    .io_out_0_bits_ftqPtr_flag(i_io_out_0_bits_ftqPtr_flag),
    .io_out_0_bits_ftqPtr_value(i_io_out_0_bits_ftqPtr_value),
    .io_out_0_bits_ftqOffset(i_io_out_0_bits_ftqOffset),
    .io_out_0_bits_isLastInFtqEntry(i_io_out_0_bits_isLastInFtqEntry),
    .io_out_0_bits_debug_seqNum_seqNum(i_io_out_0_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx(i_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_valid(i_io_out_1_valid),
    .io_out_1_bits_instr(i_io_out_1_bits_instr),
    .io_out_1_bits_pc(i_io_out_1_bits_pc),
    .io_out_1_bits_foldpc(i_io_out_1_bits_foldpc),
    .io_out_1_bits_exceptionVec_1(i_io_out_1_bits_exceptionVec_1),
    .io_out_1_bits_exceptionVec_2(i_io_out_1_bits_exceptionVec_2),
    .io_out_1_bits_exceptionVec_12(i_io_out_1_bits_exceptionVec_12),
    .io_out_1_bits_exceptionVec_20(i_io_out_1_bits_exceptionVec_20),
    .io_out_1_bits_backendException(i_io_out_1_bits_backendException),
    .io_out_1_bits_satpFlushFirstFetchFault(i_io_out_1_bits_satpFlushFirstFetchFault),
    .io_out_1_bits_trigger(i_io_out_1_bits_trigger),
    .io_out_1_bits_pd_valid(i_io_out_1_bits_pd_valid),
    .io_out_1_bits_pd_isRVC(i_io_out_1_bits_pd_isRVC),
    .io_out_1_bits_pd_brType(i_io_out_1_bits_pd_brType),
    .io_out_1_bits_pd_isCall(i_io_out_1_bits_pd_isCall),
    .io_out_1_bits_pd_isRet(i_io_out_1_bits_pd_isRet),
    .io_out_1_bits_pred_taken(i_io_out_1_bits_pred_taken),
    .io_out_1_bits_crossPageIPFFix(i_io_out_1_bits_crossPageIPFFix),
    .io_out_1_bits_ftqPtr_flag(i_io_out_1_bits_ftqPtr_flag),
    .io_out_1_bits_ftqPtr_value(i_io_out_1_bits_ftqPtr_value),
    .io_out_1_bits_ftqOffset(i_io_out_1_bits_ftqOffset),
    .io_out_1_bits_isLastInFtqEntry(i_io_out_1_bits_isLastInFtqEntry),
    .io_out_1_bits_debug_seqNum_seqNum(i_io_out_1_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx(i_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_valid(i_io_out_2_valid),
    .io_out_2_bits_instr(i_io_out_2_bits_instr),
    .io_out_2_bits_pc(i_io_out_2_bits_pc),
    .io_out_2_bits_foldpc(i_io_out_2_bits_foldpc),
    .io_out_2_bits_exceptionVec_1(i_io_out_2_bits_exceptionVec_1),
    .io_out_2_bits_exceptionVec_2(i_io_out_2_bits_exceptionVec_2),
    .io_out_2_bits_exceptionVec_12(i_io_out_2_bits_exceptionVec_12),
    .io_out_2_bits_exceptionVec_20(i_io_out_2_bits_exceptionVec_20),
    .io_out_2_bits_backendException(i_io_out_2_bits_backendException),
    .io_out_2_bits_satpFlushFirstFetchFault(i_io_out_2_bits_satpFlushFirstFetchFault),
    .io_out_2_bits_trigger(i_io_out_2_bits_trigger),
    .io_out_2_bits_pd_valid(i_io_out_2_bits_pd_valid),
    .io_out_2_bits_pd_isRVC(i_io_out_2_bits_pd_isRVC),
    .io_out_2_bits_pd_brType(i_io_out_2_bits_pd_brType),
    .io_out_2_bits_pd_isCall(i_io_out_2_bits_pd_isCall),
    .io_out_2_bits_pd_isRet(i_io_out_2_bits_pd_isRet),
    .io_out_2_bits_pred_taken(i_io_out_2_bits_pred_taken),
    .io_out_2_bits_crossPageIPFFix(i_io_out_2_bits_crossPageIPFFix),
    .io_out_2_bits_ftqPtr_flag(i_io_out_2_bits_ftqPtr_flag),
    .io_out_2_bits_ftqPtr_value(i_io_out_2_bits_ftqPtr_value),
    .io_out_2_bits_ftqOffset(i_io_out_2_bits_ftqOffset),
    .io_out_2_bits_isLastInFtqEntry(i_io_out_2_bits_isLastInFtqEntry),
    .io_out_2_bits_debug_seqNum_seqNum(i_io_out_2_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx(i_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_valid(i_io_out_3_valid),
    .io_out_3_bits_instr(i_io_out_3_bits_instr),
    .io_out_3_bits_pc(i_io_out_3_bits_pc),
    .io_out_3_bits_foldpc(i_io_out_3_bits_foldpc),
    .io_out_3_bits_exceptionVec_1(i_io_out_3_bits_exceptionVec_1),
    .io_out_3_bits_exceptionVec_2(i_io_out_3_bits_exceptionVec_2),
    .io_out_3_bits_exceptionVec_12(i_io_out_3_bits_exceptionVec_12),
    .io_out_3_bits_exceptionVec_20(i_io_out_3_bits_exceptionVec_20),
    .io_out_3_bits_backendException(i_io_out_3_bits_backendException),
    .io_out_3_bits_satpFlushFirstFetchFault(i_io_out_3_bits_satpFlushFirstFetchFault),
    .io_out_3_bits_trigger(i_io_out_3_bits_trigger),
    .io_out_3_bits_pd_valid(i_io_out_3_bits_pd_valid),
    .io_out_3_bits_pd_isRVC(i_io_out_3_bits_pd_isRVC),
    .io_out_3_bits_pd_brType(i_io_out_3_bits_pd_brType),
    .io_out_3_bits_pd_isCall(i_io_out_3_bits_pd_isCall),
    .io_out_3_bits_pd_isRet(i_io_out_3_bits_pd_isRet),
    .io_out_3_bits_pred_taken(i_io_out_3_bits_pred_taken),
    .io_out_3_bits_crossPageIPFFix(i_io_out_3_bits_crossPageIPFFix),
    .io_out_3_bits_ftqPtr_flag(i_io_out_3_bits_ftqPtr_flag),
    .io_out_3_bits_ftqPtr_value(i_io_out_3_bits_ftqPtr_value),
    .io_out_3_bits_ftqOffset(i_io_out_3_bits_ftqOffset),
    .io_out_3_bits_isLastInFtqEntry(i_io_out_3_bits_isLastInFtqEntry),
    .io_out_3_bits_debug_seqNum_seqNum(i_io_out_3_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx(i_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_4_valid(i_io_out_4_valid),
    .io_out_4_bits_instr(i_io_out_4_bits_instr),
    .io_out_4_bits_pc(i_io_out_4_bits_pc),
    .io_out_4_bits_foldpc(i_io_out_4_bits_foldpc),
    .io_out_4_bits_exceptionVec_1(i_io_out_4_bits_exceptionVec_1),
    .io_out_4_bits_exceptionVec_2(i_io_out_4_bits_exceptionVec_2),
    .io_out_4_bits_exceptionVec_12(i_io_out_4_bits_exceptionVec_12),
    .io_out_4_bits_exceptionVec_20(i_io_out_4_bits_exceptionVec_20),
    .io_out_4_bits_backendException(i_io_out_4_bits_backendException),
    .io_out_4_bits_satpFlushFirstFetchFault(i_io_out_4_bits_satpFlushFirstFetchFault),
    .io_out_4_bits_trigger(i_io_out_4_bits_trigger),
    .io_out_4_bits_pd_valid(i_io_out_4_bits_pd_valid),
    .io_out_4_bits_pd_isRVC(i_io_out_4_bits_pd_isRVC),
    .io_out_4_bits_pd_brType(i_io_out_4_bits_pd_brType),
    .io_out_4_bits_pd_isCall(i_io_out_4_bits_pd_isCall),
    .io_out_4_bits_pd_isRet(i_io_out_4_bits_pd_isRet),
    .io_out_4_bits_pred_taken(i_io_out_4_bits_pred_taken),
    .io_out_4_bits_crossPageIPFFix(i_io_out_4_bits_crossPageIPFFix),
    .io_out_4_bits_ftqPtr_flag(i_io_out_4_bits_ftqPtr_flag),
    .io_out_4_bits_ftqPtr_value(i_io_out_4_bits_ftqPtr_value),
    .io_out_4_bits_ftqOffset(i_io_out_4_bits_ftqOffset),
    .io_out_4_bits_isLastInFtqEntry(i_io_out_4_bits_isLastInFtqEntry),
    .io_out_4_bits_debug_seqNum_seqNum(i_io_out_4_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx(i_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_5_valid(i_io_out_5_valid),
    .io_out_5_bits_instr(i_io_out_5_bits_instr),
    .io_out_5_bits_pc(i_io_out_5_bits_pc),
    .io_out_5_bits_foldpc(i_io_out_5_bits_foldpc),
    .io_out_5_bits_exceptionVec_1(i_io_out_5_bits_exceptionVec_1),
    .io_out_5_bits_exceptionVec_2(i_io_out_5_bits_exceptionVec_2),
    .io_out_5_bits_exceptionVec_12(i_io_out_5_bits_exceptionVec_12),
    .io_out_5_bits_exceptionVec_20(i_io_out_5_bits_exceptionVec_20),
    .io_out_5_bits_backendException(i_io_out_5_bits_backendException),
    .io_out_5_bits_satpFlushFirstFetchFault(i_io_out_5_bits_satpFlushFirstFetchFault),
    .io_out_5_bits_trigger(i_io_out_5_bits_trigger),
    .io_out_5_bits_pd_valid(i_io_out_5_bits_pd_valid),
    .io_out_5_bits_pd_isRVC(i_io_out_5_bits_pd_isRVC),
    .io_out_5_bits_pd_brType(i_io_out_5_bits_pd_brType),
    .io_out_5_bits_pd_isCall(i_io_out_5_bits_pd_isCall),
    .io_out_5_bits_pd_isRet(i_io_out_5_bits_pd_isRet),
    .io_out_5_bits_pred_taken(i_io_out_5_bits_pred_taken),
    .io_out_5_bits_crossPageIPFFix(i_io_out_5_bits_crossPageIPFFix),
    .io_out_5_bits_ftqPtr_flag(i_io_out_5_bits_ftqPtr_flag),
    .io_out_5_bits_ftqPtr_value(i_io_out_5_bits_ftqPtr_value),
    .io_out_5_bits_ftqOffset(i_io_out_5_bits_ftqOffset),
    .io_out_5_bits_isLastInFtqEntry(i_io_out_5_bits_isLastInFtqEntry),
    .io_out_5_bits_debug_seqNum_seqNum(i_io_out_5_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx(i_io_out_5_bits_debug_seqNum_uopIdx),
    .io_stallReason_reason_0(i_io_stallReason_reason_0),
    .io_stallReason_reason_1(i_io_stallReason_reason_1),
    .io_stallReason_reason_2(i_io_stallReason_reason_2),
    .io_stallReason_reason_3(i_io_stallReason_reason_3),
    .io_stallReason_reason_4(i_io_stallReason_reason_4),
    .io_stallReason_reason_5(i_io_stallReason_reason_5),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value),
    .io_perf_8_value(i_io_perf_8_value)
  );

  // ---------------------------------------------------------------------------
  // 激励：相位状态机
  // ---------------------------------------------------------------------------
  typedef enum int { P_RANDOM = 0, P_FILL = 1, P_DRAIN = 2,
                     P_TRICKLE = 3, P_BYPASS = 4 } phase_e;
  phase_e phase = P_RANDOM;
  int     phase_left = 20;

  function automatic logic [15:0] rand_mask(input int max_bits);
    logic [15:0] m = '0;
    int n = $urandom_range(1, max_bits);
    for (int k = 0; k < n; k++) m[$urandom_range(0, 15)] = 1'b1;
    return m;
  endfunction

  task automatic drive_payload();
    // 数据通路：每拍全随机。它们只是被搬运，不参与控制，随机就够。
    for (int i = 0; i < 16; i++) begin
      case (i)
        0: begin
          io_in_bits_instrs_0 = 32'($urandom);
          io_in_bits_pc_0 = 50'($urandom);
          io_in_bits_foldpc_0 = 10'($urandom);
          io_in_bits_pd_0_isRVC = $urandom;
          io_in_bits_pd_0_brType = 2'($urandom);
          io_in_bits_pd_0_isCall = $urandom;
          io_in_bits_pd_0_isRet = $urandom;
          io_in_bits_ftqOffset_0_valid = $urandom;
          io_in_bits_exceptionType_0 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_0 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_0 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_0 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_0 = $urandom;
        end
        1: begin
          io_in_bits_instrs_1 = 32'($urandom);
          io_in_bits_pc_1 = 50'($urandom);
          io_in_bits_foldpc_1 = 10'($urandom);
          io_in_bits_pd_1_valid = $urandom;
          io_in_bits_pd_1_isRVC = $urandom;
          io_in_bits_pd_1_brType = 2'($urandom);
          io_in_bits_pd_1_isCall = $urandom;
          io_in_bits_pd_1_isRet = $urandom;
          io_in_bits_ftqOffset_1_valid = $urandom;
          io_in_bits_exceptionType_1 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_1 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_1 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_1 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_1 = $urandom;
        end
        2: begin
          io_in_bits_instrs_2 = 32'($urandom);
          io_in_bits_pc_2 = 50'($urandom);
          io_in_bits_foldpc_2 = 10'($urandom);
          io_in_bits_pd_2_valid = $urandom;
          io_in_bits_pd_2_isRVC = $urandom;
          io_in_bits_pd_2_brType = 2'($urandom);
          io_in_bits_pd_2_isCall = $urandom;
          io_in_bits_pd_2_isRet = $urandom;
          io_in_bits_ftqOffset_2_valid = $urandom;
          io_in_bits_exceptionType_2 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_2 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_2 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_2 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_2 = $urandom;
        end
        3: begin
          io_in_bits_instrs_3 = 32'($urandom);
          io_in_bits_pc_3 = 50'($urandom);
          io_in_bits_foldpc_3 = 10'($urandom);
          io_in_bits_pd_3_valid = $urandom;
          io_in_bits_pd_3_isRVC = $urandom;
          io_in_bits_pd_3_brType = 2'($urandom);
          io_in_bits_pd_3_isCall = $urandom;
          io_in_bits_pd_3_isRet = $urandom;
          io_in_bits_ftqOffset_3_valid = $urandom;
          io_in_bits_exceptionType_3 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_3 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_3 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_3 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_3 = $urandom;
        end
        4: begin
          io_in_bits_instrs_4 = 32'($urandom);
          io_in_bits_pc_4 = 50'($urandom);
          io_in_bits_foldpc_4 = 10'($urandom);
          io_in_bits_pd_4_valid = $urandom;
          io_in_bits_pd_4_isRVC = $urandom;
          io_in_bits_pd_4_brType = 2'($urandom);
          io_in_bits_pd_4_isCall = $urandom;
          io_in_bits_pd_4_isRet = $urandom;
          io_in_bits_ftqOffset_4_valid = $urandom;
          io_in_bits_exceptionType_4 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_4 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_4 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_4 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_4 = $urandom;
        end
        5: begin
          io_in_bits_instrs_5 = 32'($urandom);
          io_in_bits_pc_5 = 50'($urandom);
          io_in_bits_foldpc_5 = 10'($urandom);
          io_in_bits_pd_5_valid = $urandom;
          io_in_bits_pd_5_isRVC = $urandom;
          io_in_bits_pd_5_brType = 2'($urandom);
          io_in_bits_pd_5_isCall = $urandom;
          io_in_bits_pd_5_isRet = $urandom;
          io_in_bits_ftqOffset_5_valid = $urandom;
          io_in_bits_exceptionType_5 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_5 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_5 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_5 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_5 = $urandom;
        end
        6: begin
          io_in_bits_instrs_6 = 32'($urandom);
          io_in_bits_pc_6 = 50'($urandom);
          io_in_bits_foldpc_6 = 10'($urandom);
          io_in_bits_pd_6_valid = $urandom;
          io_in_bits_pd_6_isRVC = $urandom;
          io_in_bits_pd_6_brType = 2'($urandom);
          io_in_bits_pd_6_isCall = $urandom;
          io_in_bits_pd_6_isRet = $urandom;
          io_in_bits_ftqOffset_6_valid = $urandom;
          io_in_bits_exceptionType_6 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_6 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_6 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_6 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_6 = $urandom;
        end
        7: begin
          io_in_bits_instrs_7 = 32'($urandom);
          io_in_bits_pc_7 = 50'($urandom);
          io_in_bits_foldpc_7 = 10'($urandom);
          io_in_bits_pd_7_valid = $urandom;
          io_in_bits_pd_7_isRVC = $urandom;
          io_in_bits_pd_7_brType = 2'($urandom);
          io_in_bits_pd_7_isCall = $urandom;
          io_in_bits_pd_7_isRet = $urandom;
          io_in_bits_ftqOffset_7_valid = $urandom;
          io_in_bits_exceptionType_7 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_7 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_7 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_7 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_7 = $urandom;
        end
        8: begin
          io_in_bits_instrs_8 = 32'($urandom);
          io_in_bits_pc_8 = 50'($urandom);
          io_in_bits_foldpc_8 = 10'($urandom);
          io_in_bits_pd_8_valid = $urandom;
          io_in_bits_pd_8_isRVC = $urandom;
          io_in_bits_pd_8_brType = 2'($urandom);
          io_in_bits_pd_8_isCall = $urandom;
          io_in_bits_pd_8_isRet = $urandom;
          io_in_bits_ftqOffset_8_valid = $urandom;
          io_in_bits_exceptionType_8 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_8 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_8 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_8 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_8 = $urandom;
        end
        9: begin
          io_in_bits_instrs_9 = 32'($urandom);
          io_in_bits_pc_9 = 50'($urandom);
          io_in_bits_foldpc_9 = 10'($urandom);
          io_in_bits_pd_9_valid = $urandom;
          io_in_bits_pd_9_isRVC = $urandom;
          io_in_bits_pd_9_brType = 2'($urandom);
          io_in_bits_pd_9_isCall = $urandom;
          io_in_bits_pd_9_isRet = $urandom;
          io_in_bits_ftqOffset_9_valid = $urandom;
          io_in_bits_exceptionType_9 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_9 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_9 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_9 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_9 = $urandom;
        end
        10: begin
          io_in_bits_instrs_10 = 32'($urandom);
          io_in_bits_pc_10 = 50'($urandom);
          io_in_bits_foldpc_10 = 10'($urandom);
          io_in_bits_pd_10_valid = $urandom;
          io_in_bits_pd_10_isRVC = $urandom;
          io_in_bits_pd_10_brType = 2'($urandom);
          io_in_bits_pd_10_isCall = $urandom;
          io_in_bits_pd_10_isRet = $urandom;
          io_in_bits_ftqOffset_10_valid = $urandom;
          io_in_bits_exceptionType_10 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_10 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_10 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_10 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_10 = $urandom;
        end
        11: begin
          io_in_bits_instrs_11 = 32'($urandom);
          io_in_bits_pc_11 = 50'($urandom);
          io_in_bits_foldpc_11 = 10'($urandom);
          io_in_bits_pd_11_valid = $urandom;
          io_in_bits_pd_11_isRVC = $urandom;
          io_in_bits_pd_11_brType = 2'($urandom);
          io_in_bits_pd_11_isCall = $urandom;
          io_in_bits_pd_11_isRet = $urandom;
          io_in_bits_ftqOffset_11_valid = $urandom;
          io_in_bits_exceptionType_11 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_11 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_11 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_11 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_11 = $urandom;
        end
        12: begin
          io_in_bits_instrs_12 = 32'($urandom);
          io_in_bits_pc_12 = 50'($urandom);
          io_in_bits_foldpc_12 = 10'($urandom);
          io_in_bits_pd_12_valid = $urandom;
          io_in_bits_pd_12_isRVC = $urandom;
          io_in_bits_pd_12_brType = 2'($urandom);
          io_in_bits_pd_12_isCall = $urandom;
          io_in_bits_pd_12_isRet = $urandom;
          io_in_bits_ftqOffset_12_valid = $urandom;
          io_in_bits_exceptionType_12 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_12 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_12 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_12 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_12 = $urandom;
        end
        13: begin
          io_in_bits_instrs_13 = 32'($urandom);
          io_in_bits_pc_13 = 50'($urandom);
          io_in_bits_foldpc_13 = 10'($urandom);
          io_in_bits_pd_13_valid = $urandom;
          io_in_bits_pd_13_isRVC = $urandom;
          io_in_bits_pd_13_brType = 2'($urandom);
          io_in_bits_pd_13_isCall = $urandom;
          io_in_bits_pd_13_isRet = $urandom;
          io_in_bits_ftqOffset_13_valid = $urandom;
          io_in_bits_exceptionType_13 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_13 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_13 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_13 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_13 = $urandom;
        end
        14: begin
          io_in_bits_instrs_14 = 32'($urandom);
          io_in_bits_pc_14 = 50'($urandom);
          io_in_bits_foldpc_14 = 10'($urandom);
          io_in_bits_pd_14_valid = $urandom;
          io_in_bits_pd_14_isRVC = $urandom;
          io_in_bits_pd_14_brType = 2'($urandom);
          io_in_bits_pd_14_isCall = $urandom;
          io_in_bits_pd_14_isRet = $urandom;
          io_in_bits_ftqOffset_14_valid = $urandom;
          io_in_bits_exceptionType_14 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_14 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_14 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_14 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_14 = $urandom;
        end
        15: begin
          io_in_bits_instrs_15 = 32'($urandom);
          io_in_bits_pc_15 = 50'($urandom);
          io_in_bits_foldpc_15 = 10'($urandom);
          io_in_bits_pd_15_valid = $urandom;
          io_in_bits_pd_15_isRVC = $urandom;
          io_in_bits_pd_15_brType = 2'($urandom);
          io_in_bits_pd_15_isCall = $urandom;
          io_in_bits_pd_15_isRet = $urandom;
          io_in_bits_ftqOffset_15_valid = $urandom;
          io_in_bits_exceptionType_15 = ($urandom_range(0,2)==0) ? 2'($urandom_range(1,3)) : 2'b00;
          io_in_bits_crossPageIPFFix_15 = ($urandom_range(0,3)==0);
          io_in_bits_illegalInstr_15 = ($urandom_range(0,3)==0);
          io_in_bits_triggered_15 = 4'($urandom);
          io_in_bits_isLastInFtqEntry_15 = $urandom;
        end
      endcase
    end
    io_in_bits_ftqPtr_flag  = $urandom;
    io_in_bits_ftqPtr_value = 6'($urandom);
    io_in_bits_backendException_0         = ($urandom_range(0, 9) == 0);
    io_in_bits_satpFlushFirstFetchFault_0 = ($urandom_range(0, 9) == 0);
    // topdown：多数拍全 0（这样 stallReason 会走 FetchFragBubble 分支），
    // 少数拍置 1~3 个随机位（走 matchBubble 分支，且要能区分「最高位优先」）。
    for (int r = 0; r < 38; r++) set_topdown(r, 1'b0);
    if ($urandom_range(0, 3) == 0)
      for (int k = 0; k < $urandom_range(1, 3); k++)
        set_topdown($urandom_range(0, 37), 1'b1);
    io_stallReason_backReason_valid = ($urandom_range(0, 9) < 2);
    io_stallReason_backReason_bits  = 6'($urandom);
  endtask

  task automatic drive();
    logic [15:0] vmask, emask;
    if (phase_left == 0) begin
      phase      = phase_e'($urandom_range(0, 4));
      phase_left = $urandom_range(8, 120);
    end
    phase_left--;

    drive_payload();
    io_flush = ($urandom_range(0, 249) == 0);
    // flush 归因：五种 ControlRedirect 子因 + MemVioRedirect + 其它，轮着来，
    // 保证 topdown 的 when/elsewhen 优先级链每一档都被走到。
    io_ControlRedirect      = ($urandom_range(0, 2) != 0);
    io_ControlBTBMissBubble = ($urandom_range(0, 2) == 0);
    io_TAGEMissBubble       = ($urandom_range(0, 2) == 0);
    io_SCMissBubble         = ($urandom_range(0, 2) == 0);
    io_ITTAGEMissBubble     = ($urandom_range(0, 2) == 0);
    io_RASMissBubble        = ($urandom_range(0, 2) == 0);
    io_MemVioRedirect       = ($urandom_range(0, 2) == 0);

    case (phase)
      P_FILL: begin      // 只进不出：打到队列满、allowEnq 落 0
        io_decodeCanAccept = 1'b0;
        io_in_valid        = 1'b1;
        vmask = 16'hFFFF;  emask = 16'hFFFF;
      end
      P_DRAIN: begin     // 只出不进：打到队列空、指针绕圈
        io_decodeCanAccept = 1'b1;
        io_in_valid        = ($urandom_range(0, 9) < 2);
        vmask = rand_mask(16); emask = vmask;
      end
      P_TRICKLE: begin   // 少量进 + Decode 抖动：打输出寄存器的部分填充
        io_decodeCanAccept = ($urandom_range(0, 1) == 0);
        io_in_valid        = ($urandom_range(0, 9) < 7);
        vmask = rand_mask(3);  emask = vmask;
      end
      P_BYPASS: begin    // 保持空 + 大块进：打旁路（含 enqOffset >= 6 的那一半）
        io_decodeCanAccept = 1'b1;
        io_in_valid        = ($urandom_range(0, 9) < 8);
        vmask = rand_mask(16); emask = vmask;
      end
      default: begin     // 全随机兜底
        io_decodeCanAccept = ($urandom_range(0, 9) < 6);
        io_in_valid        = ($urandom_range(0, 9) < 7);
        vmask = 16'($urandom);
        // 大多数拍 enqEnable ⊆ valid（真实情形）；少数拍故意越出，
        // 压一压「numFromFetch 只数 enqEnable、写选择却要 valid&enqEnable」这条缝。
        emask = ($urandom_range(0, 9) < 8) ? (vmask & 16'($urandom)) : 16'($urandom);
      end
    endcase
    io_in_bits_valid     = vmask;
    io_in_bits_enqEnable = emask;
  endtask

  always @(negedge clk) drive();   // 复位期间也照打，理由见文件头

  // ---------------------------------------------------------------------------
  // 逐拍比对：160 根输出全比。前 4 拍不比（不复位的 perf 寄存器要两拍收敛）。
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 40) $display("[%0t] cyc=%0d %s mismatch: g=%h i=%h", \
                                $time, cyc, nm, (g), (i)); \
    end end

  always @(posedge clk) begin
    #1;
    if (cyc >= 4) begin
      `CHK("io_in_ready", g_io_in_ready, i_io_in_ready)
      `CHK("io_out_0_valid", g_io_out_0_valid, i_io_out_0_valid)
      `CHK("io_out_0_bits_instr", g_io_out_0_bits_instr, i_io_out_0_bits_instr)
      `CHK("io_out_0_bits_pc", g_io_out_0_bits_pc, i_io_out_0_bits_pc)
      `CHK("io_out_0_bits_foldpc", g_io_out_0_bits_foldpc, i_io_out_0_bits_foldpc)
      `CHK("io_out_0_bits_exceptionVec_1", g_io_out_0_bits_exceptionVec_1, i_io_out_0_bits_exceptionVec_1)
      `CHK("io_out_0_bits_exceptionVec_2", g_io_out_0_bits_exceptionVec_2, i_io_out_0_bits_exceptionVec_2)
      `CHK("io_out_0_bits_exceptionVec_12", g_io_out_0_bits_exceptionVec_12, i_io_out_0_bits_exceptionVec_12)
      `CHK("io_out_0_bits_exceptionVec_20", g_io_out_0_bits_exceptionVec_20, i_io_out_0_bits_exceptionVec_20)
      `CHK("io_out_0_bits_backendException", g_io_out_0_bits_backendException, i_io_out_0_bits_backendException)
      `CHK("io_out_0_bits_satpFlushFirstFetchFault", g_io_out_0_bits_satpFlushFirstFetchFault, i_io_out_0_bits_satpFlushFirstFetchFault)
      `CHK("io_out_0_bits_trigger", g_io_out_0_bits_trigger, i_io_out_0_bits_trigger)
      `CHK("io_out_0_bits_pd_valid", g_io_out_0_bits_pd_valid, i_io_out_0_bits_pd_valid)
      `CHK("io_out_0_bits_pd_isRVC", g_io_out_0_bits_pd_isRVC, i_io_out_0_bits_pd_isRVC)
      `CHK("io_out_0_bits_pd_brType", g_io_out_0_bits_pd_brType, i_io_out_0_bits_pd_brType)
      `CHK("io_out_0_bits_pd_isCall", g_io_out_0_bits_pd_isCall, i_io_out_0_bits_pd_isCall)
      `CHK("io_out_0_bits_pd_isRet", g_io_out_0_bits_pd_isRet, i_io_out_0_bits_pd_isRet)
      `CHK("io_out_0_bits_pred_taken", g_io_out_0_bits_pred_taken, i_io_out_0_bits_pred_taken)
      `CHK("io_out_0_bits_crossPageIPFFix", g_io_out_0_bits_crossPageIPFFix, i_io_out_0_bits_crossPageIPFFix)
      `CHK("io_out_0_bits_ftqPtr_flag", g_io_out_0_bits_ftqPtr_flag, i_io_out_0_bits_ftqPtr_flag)
      `CHK("io_out_0_bits_ftqPtr_value", g_io_out_0_bits_ftqPtr_value, i_io_out_0_bits_ftqPtr_value)
      `CHK("io_out_0_bits_ftqOffset", g_io_out_0_bits_ftqOffset, i_io_out_0_bits_ftqOffset)
      `CHK("io_out_0_bits_isLastInFtqEntry", g_io_out_0_bits_isLastInFtqEntry, i_io_out_0_bits_isLastInFtqEntry)
      `CHK("io_out_0_bits_debug_seqNum_seqNum", g_io_out_0_bits_debug_seqNum_seqNum, i_io_out_0_bits_debug_seqNum_seqNum)
      `CHK("io_out_0_bits_debug_seqNum_uopIdx", g_io_out_0_bits_debug_seqNum_uopIdx, i_io_out_0_bits_debug_seqNum_uopIdx)
      `CHK("io_out_1_valid", g_io_out_1_valid, i_io_out_1_valid)
      `CHK("io_out_1_bits_instr", g_io_out_1_bits_instr, i_io_out_1_bits_instr)
      `CHK("io_out_1_bits_pc", g_io_out_1_bits_pc, i_io_out_1_bits_pc)
      `CHK("io_out_1_bits_foldpc", g_io_out_1_bits_foldpc, i_io_out_1_bits_foldpc)
      `CHK("io_out_1_bits_exceptionVec_1", g_io_out_1_bits_exceptionVec_1, i_io_out_1_bits_exceptionVec_1)
      `CHK("io_out_1_bits_exceptionVec_2", g_io_out_1_bits_exceptionVec_2, i_io_out_1_bits_exceptionVec_2)
      `CHK("io_out_1_bits_exceptionVec_12", g_io_out_1_bits_exceptionVec_12, i_io_out_1_bits_exceptionVec_12)
      `CHK("io_out_1_bits_exceptionVec_20", g_io_out_1_bits_exceptionVec_20, i_io_out_1_bits_exceptionVec_20)
      `CHK("io_out_1_bits_backendException", g_io_out_1_bits_backendException, i_io_out_1_bits_backendException)
      `CHK("io_out_1_bits_satpFlushFirstFetchFault", g_io_out_1_bits_satpFlushFirstFetchFault, i_io_out_1_bits_satpFlushFirstFetchFault)
      `CHK("io_out_1_bits_trigger", g_io_out_1_bits_trigger, i_io_out_1_bits_trigger)
      `CHK("io_out_1_bits_pd_valid", g_io_out_1_bits_pd_valid, i_io_out_1_bits_pd_valid)
      `CHK("io_out_1_bits_pd_isRVC", g_io_out_1_bits_pd_isRVC, i_io_out_1_bits_pd_isRVC)
      `CHK("io_out_1_bits_pd_brType", g_io_out_1_bits_pd_brType, i_io_out_1_bits_pd_brType)
      `CHK("io_out_1_bits_pd_isCall", g_io_out_1_bits_pd_isCall, i_io_out_1_bits_pd_isCall)
      `CHK("io_out_1_bits_pd_isRet", g_io_out_1_bits_pd_isRet, i_io_out_1_bits_pd_isRet)
      `CHK("io_out_1_bits_pred_taken", g_io_out_1_bits_pred_taken, i_io_out_1_bits_pred_taken)
      `CHK("io_out_1_bits_crossPageIPFFix", g_io_out_1_bits_crossPageIPFFix, i_io_out_1_bits_crossPageIPFFix)
      `CHK("io_out_1_bits_ftqPtr_flag", g_io_out_1_bits_ftqPtr_flag, i_io_out_1_bits_ftqPtr_flag)
      `CHK("io_out_1_bits_ftqPtr_value", g_io_out_1_bits_ftqPtr_value, i_io_out_1_bits_ftqPtr_value)
      `CHK("io_out_1_bits_ftqOffset", g_io_out_1_bits_ftqOffset, i_io_out_1_bits_ftqOffset)
      `CHK("io_out_1_bits_isLastInFtqEntry", g_io_out_1_bits_isLastInFtqEntry, i_io_out_1_bits_isLastInFtqEntry)
      `CHK("io_out_1_bits_debug_seqNum_seqNum", g_io_out_1_bits_debug_seqNum_seqNum, i_io_out_1_bits_debug_seqNum_seqNum)
      `CHK("io_out_1_bits_debug_seqNum_uopIdx", g_io_out_1_bits_debug_seqNum_uopIdx, i_io_out_1_bits_debug_seqNum_uopIdx)
      `CHK("io_out_2_valid", g_io_out_2_valid, i_io_out_2_valid)
      `CHK("io_out_2_bits_instr", g_io_out_2_bits_instr, i_io_out_2_bits_instr)
      `CHK("io_out_2_bits_pc", g_io_out_2_bits_pc, i_io_out_2_bits_pc)
      `CHK("io_out_2_bits_foldpc", g_io_out_2_bits_foldpc, i_io_out_2_bits_foldpc)
      `CHK("io_out_2_bits_exceptionVec_1", g_io_out_2_bits_exceptionVec_1, i_io_out_2_bits_exceptionVec_1)
      `CHK("io_out_2_bits_exceptionVec_2", g_io_out_2_bits_exceptionVec_2, i_io_out_2_bits_exceptionVec_2)
      `CHK("io_out_2_bits_exceptionVec_12", g_io_out_2_bits_exceptionVec_12, i_io_out_2_bits_exceptionVec_12)
      `CHK("io_out_2_bits_exceptionVec_20", g_io_out_2_bits_exceptionVec_20, i_io_out_2_bits_exceptionVec_20)
      `CHK("io_out_2_bits_backendException", g_io_out_2_bits_backendException, i_io_out_2_bits_backendException)
      `CHK("io_out_2_bits_satpFlushFirstFetchFault", g_io_out_2_bits_satpFlushFirstFetchFault, i_io_out_2_bits_satpFlushFirstFetchFault)
      `CHK("io_out_2_bits_trigger", g_io_out_2_bits_trigger, i_io_out_2_bits_trigger)
      `CHK("io_out_2_bits_pd_valid", g_io_out_2_bits_pd_valid, i_io_out_2_bits_pd_valid)
      `CHK("io_out_2_bits_pd_isRVC", g_io_out_2_bits_pd_isRVC, i_io_out_2_bits_pd_isRVC)
      `CHK("io_out_2_bits_pd_brType", g_io_out_2_bits_pd_brType, i_io_out_2_bits_pd_brType)
      `CHK("io_out_2_bits_pd_isCall", g_io_out_2_bits_pd_isCall, i_io_out_2_bits_pd_isCall)
      `CHK("io_out_2_bits_pd_isRet", g_io_out_2_bits_pd_isRet, i_io_out_2_bits_pd_isRet)
      `CHK("io_out_2_bits_pred_taken", g_io_out_2_bits_pred_taken, i_io_out_2_bits_pred_taken)
      `CHK("io_out_2_bits_crossPageIPFFix", g_io_out_2_bits_crossPageIPFFix, i_io_out_2_bits_crossPageIPFFix)
      `CHK("io_out_2_bits_ftqPtr_flag", g_io_out_2_bits_ftqPtr_flag, i_io_out_2_bits_ftqPtr_flag)
      `CHK("io_out_2_bits_ftqPtr_value", g_io_out_2_bits_ftqPtr_value, i_io_out_2_bits_ftqPtr_value)
      `CHK("io_out_2_bits_ftqOffset", g_io_out_2_bits_ftqOffset, i_io_out_2_bits_ftqOffset)
      `CHK("io_out_2_bits_isLastInFtqEntry", g_io_out_2_bits_isLastInFtqEntry, i_io_out_2_bits_isLastInFtqEntry)
      `CHK("io_out_2_bits_debug_seqNum_seqNum", g_io_out_2_bits_debug_seqNum_seqNum, i_io_out_2_bits_debug_seqNum_seqNum)
      `CHK("io_out_2_bits_debug_seqNum_uopIdx", g_io_out_2_bits_debug_seqNum_uopIdx, i_io_out_2_bits_debug_seqNum_uopIdx)
      `CHK("io_out_3_valid", g_io_out_3_valid, i_io_out_3_valid)
      `CHK("io_out_3_bits_instr", g_io_out_3_bits_instr, i_io_out_3_bits_instr)
      `CHK("io_out_3_bits_pc", g_io_out_3_bits_pc, i_io_out_3_bits_pc)
      `CHK("io_out_3_bits_foldpc", g_io_out_3_bits_foldpc, i_io_out_3_bits_foldpc)
      `CHK("io_out_3_bits_exceptionVec_1", g_io_out_3_bits_exceptionVec_1, i_io_out_3_bits_exceptionVec_1)
      `CHK("io_out_3_bits_exceptionVec_2", g_io_out_3_bits_exceptionVec_2, i_io_out_3_bits_exceptionVec_2)
      `CHK("io_out_3_bits_exceptionVec_12", g_io_out_3_bits_exceptionVec_12, i_io_out_3_bits_exceptionVec_12)
      `CHK("io_out_3_bits_exceptionVec_20", g_io_out_3_bits_exceptionVec_20, i_io_out_3_bits_exceptionVec_20)
      `CHK("io_out_3_bits_backendException", g_io_out_3_bits_backendException, i_io_out_3_bits_backendException)
      `CHK("io_out_3_bits_satpFlushFirstFetchFault", g_io_out_3_bits_satpFlushFirstFetchFault, i_io_out_3_bits_satpFlushFirstFetchFault)
      `CHK("io_out_3_bits_trigger", g_io_out_3_bits_trigger, i_io_out_3_bits_trigger)
      `CHK("io_out_3_bits_pd_valid", g_io_out_3_bits_pd_valid, i_io_out_3_bits_pd_valid)
      `CHK("io_out_3_bits_pd_isRVC", g_io_out_3_bits_pd_isRVC, i_io_out_3_bits_pd_isRVC)
      `CHK("io_out_3_bits_pd_brType", g_io_out_3_bits_pd_brType, i_io_out_3_bits_pd_brType)
      `CHK("io_out_3_bits_pd_isCall", g_io_out_3_bits_pd_isCall, i_io_out_3_bits_pd_isCall)
      `CHK("io_out_3_bits_pd_isRet", g_io_out_3_bits_pd_isRet, i_io_out_3_bits_pd_isRet)
      `CHK("io_out_3_bits_pred_taken", g_io_out_3_bits_pred_taken, i_io_out_3_bits_pred_taken)
      `CHK("io_out_3_bits_crossPageIPFFix", g_io_out_3_bits_crossPageIPFFix, i_io_out_3_bits_crossPageIPFFix)
      `CHK("io_out_3_bits_ftqPtr_flag", g_io_out_3_bits_ftqPtr_flag, i_io_out_3_bits_ftqPtr_flag)
      `CHK("io_out_3_bits_ftqPtr_value", g_io_out_3_bits_ftqPtr_value, i_io_out_3_bits_ftqPtr_value)
      `CHK("io_out_3_bits_ftqOffset", g_io_out_3_bits_ftqOffset, i_io_out_3_bits_ftqOffset)
      `CHK("io_out_3_bits_isLastInFtqEntry", g_io_out_3_bits_isLastInFtqEntry, i_io_out_3_bits_isLastInFtqEntry)
      `CHK("io_out_3_bits_debug_seqNum_seqNum", g_io_out_3_bits_debug_seqNum_seqNum, i_io_out_3_bits_debug_seqNum_seqNum)
      `CHK("io_out_3_bits_debug_seqNum_uopIdx", g_io_out_3_bits_debug_seqNum_uopIdx, i_io_out_3_bits_debug_seqNum_uopIdx)
      `CHK("io_out_4_valid", g_io_out_4_valid, i_io_out_4_valid)
      `CHK("io_out_4_bits_instr", g_io_out_4_bits_instr, i_io_out_4_bits_instr)
      `CHK("io_out_4_bits_pc", g_io_out_4_bits_pc, i_io_out_4_bits_pc)
      `CHK("io_out_4_bits_foldpc", g_io_out_4_bits_foldpc, i_io_out_4_bits_foldpc)
      `CHK("io_out_4_bits_exceptionVec_1", g_io_out_4_bits_exceptionVec_1, i_io_out_4_bits_exceptionVec_1)
      `CHK("io_out_4_bits_exceptionVec_2", g_io_out_4_bits_exceptionVec_2, i_io_out_4_bits_exceptionVec_2)
      `CHK("io_out_4_bits_exceptionVec_12", g_io_out_4_bits_exceptionVec_12, i_io_out_4_bits_exceptionVec_12)
      `CHK("io_out_4_bits_exceptionVec_20", g_io_out_4_bits_exceptionVec_20, i_io_out_4_bits_exceptionVec_20)
      `CHK("io_out_4_bits_backendException", g_io_out_4_bits_backendException, i_io_out_4_bits_backendException)
      `CHK("io_out_4_bits_satpFlushFirstFetchFault", g_io_out_4_bits_satpFlushFirstFetchFault, i_io_out_4_bits_satpFlushFirstFetchFault)
      `CHK("io_out_4_bits_trigger", g_io_out_4_bits_trigger, i_io_out_4_bits_trigger)
      `CHK("io_out_4_bits_pd_valid", g_io_out_4_bits_pd_valid, i_io_out_4_bits_pd_valid)
      `CHK("io_out_4_bits_pd_isRVC", g_io_out_4_bits_pd_isRVC, i_io_out_4_bits_pd_isRVC)
      `CHK("io_out_4_bits_pd_brType", g_io_out_4_bits_pd_brType, i_io_out_4_bits_pd_brType)
      `CHK("io_out_4_bits_pd_isCall", g_io_out_4_bits_pd_isCall, i_io_out_4_bits_pd_isCall)
      `CHK("io_out_4_bits_pd_isRet", g_io_out_4_bits_pd_isRet, i_io_out_4_bits_pd_isRet)
      `CHK("io_out_4_bits_pred_taken", g_io_out_4_bits_pred_taken, i_io_out_4_bits_pred_taken)
      `CHK("io_out_4_bits_crossPageIPFFix", g_io_out_4_bits_crossPageIPFFix, i_io_out_4_bits_crossPageIPFFix)
      `CHK("io_out_4_bits_ftqPtr_flag", g_io_out_4_bits_ftqPtr_flag, i_io_out_4_bits_ftqPtr_flag)
      `CHK("io_out_4_bits_ftqPtr_value", g_io_out_4_bits_ftqPtr_value, i_io_out_4_bits_ftqPtr_value)
      `CHK("io_out_4_bits_ftqOffset", g_io_out_4_bits_ftqOffset, i_io_out_4_bits_ftqOffset)
      `CHK("io_out_4_bits_isLastInFtqEntry", g_io_out_4_bits_isLastInFtqEntry, i_io_out_4_bits_isLastInFtqEntry)
      `CHK("io_out_4_bits_debug_seqNum_seqNum", g_io_out_4_bits_debug_seqNum_seqNum, i_io_out_4_bits_debug_seqNum_seqNum)
      `CHK("io_out_4_bits_debug_seqNum_uopIdx", g_io_out_4_bits_debug_seqNum_uopIdx, i_io_out_4_bits_debug_seqNum_uopIdx)
      `CHK("io_out_5_valid", g_io_out_5_valid, i_io_out_5_valid)
      `CHK("io_out_5_bits_instr", g_io_out_5_bits_instr, i_io_out_5_bits_instr)
      `CHK("io_out_5_bits_pc", g_io_out_5_bits_pc, i_io_out_5_bits_pc)
      `CHK("io_out_5_bits_foldpc", g_io_out_5_bits_foldpc, i_io_out_5_bits_foldpc)
      `CHK("io_out_5_bits_exceptionVec_1", g_io_out_5_bits_exceptionVec_1, i_io_out_5_bits_exceptionVec_1)
      `CHK("io_out_5_bits_exceptionVec_2", g_io_out_5_bits_exceptionVec_2, i_io_out_5_bits_exceptionVec_2)
      `CHK("io_out_5_bits_exceptionVec_12", g_io_out_5_bits_exceptionVec_12, i_io_out_5_bits_exceptionVec_12)
      `CHK("io_out_5_bits_exceptionVec_20", g_io_out_5_bits_exceptionVec_20, i_io_out_5_bits_exceptionVec_20)
      `CHK("io_out_5_bits_backendException", g_io_out_5_bits_backendException, i_io_out_5_bits_backendException)
      `CHK("io_out_5_bits_satpFlushFirstFetchFault", g_io_out_5_bits_satpFlushFirstFetchFault, i_io_out_5_bits_satpFlushFirstFetchFault)
      `CHK("io_out_5_bits_trigger", g_io_out_5_bits_trigger, i_io_out_5_bits_trigger)
      `CHK("io_out_5_bits_pd_valid", g_io_out_5_bits_pd_valid, i_io_out_5_bits_pd_valid)
      `CHK("io_out_5_bits_pd_isRVC", g_io_out_5_bits_pd_isRVC, i_io_out_5_bits_pd_isRVC)
      `CHK("io_out_5_bits_pd_brType", g_io_out_5_bits_pd_brType, i_io_out_5_bits_pd_brType)
      `CHK("io_out_5_bits_pd_isCall", g_io_out_5_bits_pd_isCall, i_io_out_5_bits_pd_isCall)
      `CHK("io_out_5_bits_pd_isRet", g_io_out_5_bits_pd_isRet, i_io_out_5_bits_pd_isRet)
      `CHK("io_out_5_bits_pred_taken", g_io_out_5_bits_pred_taken, i_io_out_5_bits_pred_taken)
      `CHK("io_out_5_bits_crossPageIPFFix", g_io_out_5_bits_crossPageIPFFix, i_io_out_5_bits_crossPageIPFFix)
      `CHK("io_out_5_bits_ftqPtr_flag", g_io_out_5_bits_ftqPtr_flag, i_io_out_5_bits_ftqPtr_flag)
      `CHK("io_out_5_bits_ftqPtr_value", g_io_out_5_bits_ftqPtr_value, i_io_out_5_bits_ftqPtr_value)
      `CHK("io_out_5_bits_ftqOffset", g_io_out_5_bits_ftqOffset, i_io_out_5_bits_ftqOffset)
      `CHK("io_out_5_bits_isLastInFtqEntry", g_io_out_5_bits_isLastInFtqEntry, i_io_out_5_bits_isLastInFtqEntry)
      `CHK("io_out_5_bits_debug_seqNum_seqNum", g_io_out_5_bits_debug_seqNum_seqNum, i_io_out_5_bits_debug_seqNum_seqNum)
      `CHK("io_out_5_bits_debug_seqNum_uopIdx", g_io_out_5_bits_debug_seqNum_uopIdx, i_io_out_5_bits_debug_seqNum_uopIdx)
      `CHK("io_stallReason_reason_0", g_io_stallReason_reason_0, i_io_stallReason_reason_0)
      `CHK("io_stallReason_reason_1", g_io_stallReason_reason_1, i_io_stallReason_reason_1)
      `CHK("io_stallReason_reason_2", g_io_stallReason_reason_2, i_io_stallReason_reason_2)
      `CHK("io_stallReason_reason_3", g_io_stallReason_reason_3, i_io_stallReason_reason_3)
      `CHK("io_stallReason_reason_4", g_io_stallReason_reason_4, i_io_stallReason_reason_4)
      `CHK("io_stallReason_reason_5", g_io_stallReason_reason_5, i_io_stallReason_reason_5)
      `CHK("io_perf_0_value", g_io_perf_0_value, i_io_perf_0_value)
      `CHK("io_perf_1_value", g_io_perf_1_value, i_io_perf_1_value)
      `CHK("io_perf_2_value", g_io_perf_2_value, i_io_perf_2_value)
      `CHK("io_perf_3_value", g_io_perf_3_value, i_io_perf_3_value)
      `CHK("io_perf_4_value", g_io_perf_4_value, i_io_perf_4_value)
      `CHK("io_perf_5_value", g_io_perf_5_value, i_io_perf_5_value)
      `CHK("io_perf_6_value", g_io_perf_6_value, i_io_perf_6_value)
      `CHK("io_perf_7_value", g_io_perf_7_value, i_io_perf_7_value)
      `CHK("io_perf_8_value", g_io_perf_8_value, i_io_perf_8_value)
    end
    cyc++;
  end


  task automatic set_topdown(input int r, input logic v);
    case (r)
      0: io_in_bits_topdown_info_reasons_0 = v;
      1: io_in_bits_topdown_info_reasons_1 = v;
      2: io_in_bits_topdown_info_reasons_2 = v;
      3: io_in_bits_topdown_info_reasons_3 = v;
      4: io_in_bits_topdown_info_reasons_4 = v;
      5: io_in_bits_topdown_info_reasons_5 = v;
      6: io_in_bits_topdown_info_reasons_6 = v;
      7: io_in_bits_topdown_info_reasons_7 = v;
      8: io_in_bits_topdown_info_reasons_8 = v;
      9: io_in_bits_topdown_info_reasons_9 = v;
      10: io_in_bits_topdown_info_reasons_10 = v;
      11: io_in_bits_topdown_info_reasons_11 = v;
      12: io_in_bits_topdown_info_reasons_12 = v;
      13: io_in_bits_topdown_info_reasons_13 = v;
      14: io_in_bits_topdown_info_reasons_14 = v;
      15: io_in_bits_topdown_info_reasons_15 = v;
      16: io_in_bits_topdown_info_reasons_16 = v;
      17: io_in_bits_topdown_info_reasons_17 = v;
      18: io_in_bits_topdown_info_reasons_18 = v;
      19: io_in_bits_topdown_info_reasons_19 = v;
      20: io_in_bits_topdown_info_reasons_20 = v;
      21: io_in_bits_topdown_info_reasons_21 = v;
      22: io_in_bits_topdown_info_reasons_22 = v;
      23: io_in_bits_topdown_info_reasons_23 = v;
      24: io_in_bits_topdown_info_reasons_24 = v;
      25: io_in_bits_topdown_info_reasons_25 = v;
      26: io_in_bits_topdown_info_reasons_26 = v;
      27: io_in_bits_topdown_info_reasons_27 = v;
      28: io_in_bits_topdown_info_reasons_28 = v;
      29: io_in_bits_topdown_info_reasons_29 = v;
      30: io_in_bits_topdown_info_reasons_30 = v;
      31: io_in_bits_topdown_info_reasons_31 = v;
      32: io_in_bits_topdown_info_reasons_32 = v;
      33: io_in_bits_topdown_info_reasons_33 = v;
      34: io_in_bits_topdown_info_reasons_34 = v;
      35: io_in_bits_topdown_info_reasons_35 = v;
      36: io_in_bits_topdown_info_reasons_36 = v;
      37: io_in_bits_topdown_info_reasons_37 = v;
      default: ;
    endcase
  endtask

  // ---------------------------------------------------------------------------
  // 覆盖事件（每项必须 > 0，否则对应状态根本没走到，这一轮 errors=0 不作数）
  // 全部用层次引用读 **golden** 内部状态。
  // ---------------------------------------------------------------------------
  longint cov_full          = 0;  // allowEnq 落 0（队列快满，in_ready 反压）
  longint cov_deep          = 0;  // numValid >= 32（真的填到 IBufSize-PredictWidth）
  longint cov_empty         = 0;  // numValid == 0
  longint cov_bypass        = 0;  // 走旁路（空 + Decode 能收 + 本拍有输入）
  longint cov_bypass_big    = 0;  // 且本块 > 6 条 —— 旁路的 useBypassMatch 那一支
  longint cov_partial[6];         // outputEntriesValidNum == k 的拍数（k=1..5 须 > 0）
  longint cov_shift_read    = 0;  // Decode 不收、寄存器没满、已有有效项 > 0
                                  // → 走「i - validNum」移位读（含越界补第 0 项）
  longint cov_out_full      = 0;  // 输出寄存器 6 条全满（整组保持的分支）
  longint cov_enq_wrap      = 0;  // 入队指针绕过 48（enqPtrVec_0_flag 翻转）
  longint cov_deq_wrap      = 0;  // 出队指针绕过 48
  longint cov_inbank_wrap   = 0;  // bank 内指针绕过 8（deqInBankPtr flag 翻转）
  longint cov_flush_nonempty= 0;  // 非空时 flush
  longint cov_flush_ctrl    = 0;  // ControlRedirect 归因
  longint cov_flush_memvio  = 0;  // MemVioRedirect 归因
  longint cov_flush_other   = 0;  // 其它重定向归因
  longint cov_stall_frag    = 0;  // stallReason 走 FetchFragBubble（无 topdown 归因）
  longint cov_stall_match   = 0;  // stallReason 走 matchBubble（有 topdown 归因）
  longint cov_stall_back    = 0;  // 后端 backReason 覆盖
  longint cov_reset_mid     = 0;  // 运行中异步复位次数
  int     max_numvalid      = 0;

  logic prev_enq_flag, prev_deq_flag;
  logic [5:0] prev_inbank_flag;

  initial for (int k = 0; k < 6; k++) cov_partial[k] = 0;

  // ★ 采样点必须在 negedge 之后、posedge 之前 ★
  // 一开始写在 posedge+2，结果「非空时 flush」恒为 0 —— 因为那一刻 flush 已经
  // 生效、指针已经被清成空了，量到的是**结果**而不是**条件**。同理 useBypass /
  // outputEntriesValidNum 也必须与激励同相位。negedge+2 时激励已驱动、DUT 还是
  // 本拍将要被采样的那个状态，两边对齐。
  always @(negedge clk) begin
    #2;
    if (!rst && cyc > 4) begin
      if (!u_golden.allowEnq)                       cov_full++;
      if (u_golden.numValid_probe >= 6'd32)         cov_deep++;
      if (u_golden.numValid_probe == 6'd0)          cov_empty++;
      if (int'(u_golden.numValid_probe) > max_numvalid)
        max_numvalid = int'(u_golden.numValid_probe);
      if (u_golden.useBypass && io_in_valid) begin
        cov_bypass++;
        if (u_golden.numFromFetch > 5'd6) cov_bypass_big++;
      end
      cov_partial[u_golden.outputEntriesValidNum]++;
      if (u_golden.outputEntries_5_valid) cov_out_full++;
      if (!io_decodeCanAccept && !u_golden.outputEntries_5_valid
          && u_golden.outputEntriesValidNum != 3'd0) cov_shift_read++;
      if (u_golden.enqPtrVec_0_flag !== prev_enq_flag)   cov_enq_wrap++;
      if (u_golden.deqPtr_flag      !== prev_deq_flag)   cov_deq_wrap++;
      for (int b = 0; b < 6; b++)
        if (inbank_flag(b) !== prev_inbank_flag[b])      cov_inbank_wrap++;
      if (io_flush) begin
        if (u_golden.numValid_probe != 6'd0) cov_flush_nonempty++;
        if (io_ControlRedirect)        cov_flush_ctrl++;
        else if (io_MemVioRedirect)    cov_flush_memvio++;
        else                           cov_flush_other++;
      end
      if (io_stallReason_backReason_valid) cov_stall_back++;
      else if (g_io_stallReason_reason_5 == 6'd13) cov_stall_frag++;
      else if (g_io_stallReason_reason_5 != 6'd0)  cov_stall_match++;
    end
    prev_enq_flag = u_golden.enqPtrVec_0_flag;
    prev_deq_flag = u_golden.deqPtr_flag;
    for (int b = 0; b < 6; b++) prev_inbank_flag[b] = inbank_flag(b);
  end

  function automatic logic inbank_flag(input int b);
    case (b)
      0: return u_golden.deqInBankPtr_0_flag;
      1: return u_golden.deqInBankPtr_1_flag;
      2: return u_golden.deqInBankPtr_2_flag;
      3: return u_golden.deqInBankPtr_3_flag;
      4: return u_golden.deqInBankPtr_4_flag;
      default: return u_golden.deqInBankPtr_5_flag;
    endcase
  endfunction

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (6) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    // 运行中多次异步复位：验证「大块异步复位 + perf 两拍链不复位」这个结构。
    // ★ 为什么是多次而不是一次 ★：复位窗口是「perf 链不复位」这条判据**唯一**的
    // 可观测窗口（perf 寄存器每拍无条件更新，复位一放开两拍就重新收敛）。姊妹模块
    // BloomFilter 实测：只打一次时同类变异只差出 5 个比对点，离 0 太近。所以打
    // RESETS 次、每次长度 2/3/4 轮换，让判据有余量。
    for (int k = 0; k < RESETS; k++) begin
      repeat (NCYCLES / (RESETS + 1)) @(posedge clk);
      @(negedge clk) rst = 1'b1; cov_reset_mid++;
      repeat (2 + (k % 3)) @(posedge clk);
      @(negedge clk) rst = 1'b0;
    end
    repeat (NCYCLES / (RESETS + 1)) @(posedge clk);

    $display("--- COVERAGE (标 * 的每项必须 > 0) ---");
    $display("* allowEnq 落 0(满)        : %0d", cov_full);
    $display("* numValid >= 32           : %0d", cov_deep);
    $display("  numValid 峰值            : %0d", max_numvalid);
    $display("* numValid == 0(空)        : %0d", cov_empty);
    $display("* 旁路                     : %0d", cov_bypass);
    $display("* 旁路且本块 > 6 条        : %0d", cov_bypass_big);
    for (int k = 1; k <= 5; k++)
      $display("* 输出寄存器部分填充 = %0d  : %0d", k, cov_partial[k]);
    $display("* 输出寄存器 6 条全满      : %0d", cov_out_full);
    $display("* 移位读(i - validNum)     : %0d", cov_shift_read);
    $display("* 入队指针绕圈             : %0d", cov_enq_wrap);
    $display("* 出队指针绕圈             : %0d", cov_deq_wrap);
    $display("* bank 内指针绕圈          : %0d", cov_inbank_wrap);
    $display("* 非空时 flush             : %0d", cov_flush_nonempty);
    $display("* flush 归因 Control       : %0d", cov_flush_ctrl);
    $display("* flush 归因 MemVio        : %0d", cov_flush_memvio);
    $display("* flush 归因 其它          : %0d", cov_flush_other);
    $display("* stall = FetchFragBubble  : %0d", cov_stall_frag);
    $display("* stall = matchBubble      : %0d", cov_stall_match);
    $display("* stall = backReason       : %0d", cov_stall_back);
    $display("* 运行中异步复位           : %0d", cov_reset_mid);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_full > 0 && cov_deep > 0 && cov_empty > 0 &&
        cov_bypass > 0 && cov_bypass_big > 0 &&
        cov_partial[1] > 0 && cov_partial[2] > 0 && cov_partial[3] > 0 &&
        cov_partial[4] > 0 && cov_partial[5] > 0 &&
        cov_out_full > 0 && cov_shift_read > 0 &&
        cov_enq_wrap > 0 && cov_deq_wrap > 0 && cov_inbank_wrap > 0 &&
        cov_flush_nonempty > 0 && cov_flush_ctrl > 0 && cov_flush_memvio > 0 &&
        cov_flush_other > 0 && cov_stall_frag > 0 && cov_stall_match > 0 &&
        cov_stall_back > 0 && cov_reset_mid >= RESETS)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule

