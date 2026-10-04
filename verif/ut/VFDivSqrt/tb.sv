// =============================================================================
// tb —— VFDivSqrt UT：golden VFDivSqrt（含 golden 子树）与重写件 VFDivSqrt_xs（子树全是重写件：VectorFloatDivider ×2、
// VecDataSplitModule ×2、Mgu，以及共享辅助件 xs_VecFflagsElemMask）双例化，同时钟同激励逐拍比全部 34 个输出。
//
// 激励（每拍在下降沿换输入）：
//   七成以上取合法 RVV 配置（vl <= VLMAX(SEW,LMUL)、vuopIdx < 寄存器组大小、vstart <= vl），1/8 全随机（只做差分，
//   因为 Mgu 的字节计数 vl<<SEW 截 8 位，非法 vl 下没有 RVV 语义可比）；
//   in_valid：in_ready=1 时 3/4，=0 时 1/60（违规发起：两个除法器各看自己的 ready —— golden 行为照比，oracle 暂停到
//   两者都空闲，同 verif/ut/VectorFloatDivider 的口径）；fuOpType 随机 9 位（bit0 = is_sqrt），1/32 取 0x84/0x86
//   （公共外壳的清掩码编码）；vsew 九成 1..3（f16/f32/f64）；vlmul 0..3 / 4..7；vuopIdx 九成 0..7；vl 偏向本 uop 的元素窗口；
//   vstart 七成 0；vm / vta / vma 随机；isNarrow / isDstMask 各 1/16；v0 / 旧 vd 随机；vs1 / vs2 按格式造（除法沿用
//   VectorFloatDivider UT 的 make_vec：特殊值 / 上溢 / 非规格边界；开方用 make_sqrt_vec）；rm 九成合法；
//   out_ready 3/4；flush 1/150（robIdx 随机，level 随机）。调试 / 控制透传字段随机。
// 差分比较：in_ready / out_valid 每拍比；其余输出在第一次 in.fire 之后每拍比（握手拍锁存、无复位），其中
//   res_data / res_fflags 要等两个除法器的除法、开方子单元都各自完整走过一次（此前结果寄存器是上电值）。
// 独立按元素 oracle（tb 内整数算术：除法 / 开方 IEEE 参考照抄 verif/ut/VectorFloatDivider），对每个被接收、未被冲刷、
//   合法（vsew≠0、非 narrow / dstMask）的 uop，在它的 out 握手拍比：
//   - res_data：vstart >= vl 时整个 vd 保持旧值（ByteMaskTailGen 的整条不写）；否则按 SEW 逐元素
//     （全局下标 = vuopIdx[2:0]·(128/SEW) + i）：< vstart → 旧值；>= vl → vta ? 全 1 : 旧值；
//     其余：掩码位（vm ? 1 : v0[全局下标]；fuOpType 为清掩码编码时 0）为 1 → IEEE 结果，否则 vma ? 全 1 : 旧值。
//   - res_fflags：计入元素 i 当且仅当 i < 本 uop 元素上限（分数 LMUL 时按 vlmul 收窄）、uop·上限 + i < vl 且掩码位为 1
//     （fflags 不看 vstart），各元素的 IEEE 标志按位或。
// 覆盖（写进 PASS 判据）：oracle 比对 >= 3000（除 / 开方各 >= 1000，3 种 SEW 各 >= 500）；oracle 里出现过
//   掩码关元素、尾部元素（ta=0 / 1）、vstart>0 前部元素、vstart>=vl 整条不写、分数 LMUL 各 >= 100 个；flush 打断 >= 20；out 反压 >= 100；
//   res_data / res_fflags 每位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_err = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;
  logic reset;

  // ---- 端口信号（由 golden 端口表机械生成）----
  logic           io_flush_valid;
  logic           io_flush_bits_robIdx_flag;
  logic [7:0]     io_flush_bits_robIdx_value;
  logic           io_flush_bits_level;
  logic           g_io_in_ready, i_io_in_ready;
  logic           io_in_valid;
  logic [8:0]     io_in_bits_ctrl_fuOpType;
  logic           io_in_bits_ctrl_robIdx_flag;
  logic [7:0]     io_in_bits_ctrl_robIdx_value;
  logic [7:0]     io_in_bits_ctrl_pdest;
  logic           io_in_bits_ctrl_vecWen;
  logic           io_in_bits_ctrl_v0Wen;
  logic           io_in_bits_ctrl_fpu_wflags;
  logic           io_in_bits_ctrl_vpu_vma;
  logic           io_in_bits_ctrl_vpu_vta;
  logic [1:0]     io_in_bits_ctrl_vpu_vsew;
  logic [2:0]     io_in_bits_ctrl_vpu_vlmul;
  logic           io_in_bits_ctrl_vpu_vm;
  logic [7:0]     io_in_bits_ctrl_vpu_vstart;
  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx;
  logic           io_in_bits_ctrl_vpu_isNarrow;
  logic           io_in_bits_ctrl_vpu_isDstMask;
  logic [7:0]     io_in_bits_data_src_4;
  logic [127:0]   io_in_bits_data_src_3;
  logic [127:0]   io_in_bits_data_src_2;
  logic [127:0]   io_in_bits_data_src_1;
  logic [127:0]   io_in_bits_data_src_0;
  logic           io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]    io_in_bits_perfDebugInfo_renameTime;
  logic [63:0]    io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0]    io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]    io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]    io_in_bits_perfDebugInfo_issueTime;
  logic [63:0]    io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0]    io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]    io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]    io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]    io_in_bits_debug_seqNum_seqNum;
  logic [7:0]     io_in_bits_debug_seqNum_uopIdx;
  logic           io_out_ready;
  logic           g_io_out_valid, i_io_out_valid;
  logic           g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  logic [7:0]     g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  logic [7:0]     g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  logic           g_io_out_bits_ctrl_vecWen, i_io_out_bits_ctrl_vecWen;
  logic           g_io_out_bits_ctrl_v0Wen, i_io_out_bits_ctrl_v0Wen;
  logic           g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags;
  logic [127:0]   g_io_out_bits_res_data, i_io_out_bits_res_data;
  logic [4:0]     g_io_out_bits_res_fflags, i_io_out_bits_res_fflags;
  logic           g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]    g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]    g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]    g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]    g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  logic [7:0]     g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;
  logic [2:0]     io_frm;
  VFDivSqrt u_g (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_vecWen(io_in_bits_ctrl_vecWen),
    .io_in_bits_ctrl_v0Wen(io_in_bits_ctrl_v0Wen),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_vpu_vma(io_in_bits_ctrl_vpu_vma),
    .io_in_bits_ctrl_vpu_vta(io_in_bits_ctrl_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart(io_in_bits_ctrl_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isNarrow(io_in_bits_ctrl_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask(io_in_bits_ctrl_vpu_isDstMask),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen(g_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen(g_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags(g_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_res_fflags(g_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx),
    .io_frm(io_frm)
  );
  VFDivSqrt_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_vecWen(io_in_bits_ctrl_vecWen),
    .io_in_bits_ctrl_v0Wen(io_in_bits_ctrl_v0Wen),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_vpu_vma(io_in_bits_ctrl_vpu_vma),
    .io_in_bits_ctrl_vpu_vta(io_in_bits_ctrl_vpu_vta),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vstart(io_in_bits_ctrl_vpu_vstart),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isNarrow(io_in_bits_ctrl_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask(io_in_bits_ctrl_vpu_isDstMask),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vecWen(i_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen(i_io_out_bits_ctrl_v0Wen),
    .io_out_bits_ctrl_fpu_wflags(i_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_res_fflags(i_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx),
    .io_frm(io_frm)
  );
  // ---- 全部输出逐拍比（返回本拍失配的输出个数）----
  function automatic int diff_outputs(input bit verbose);
    int n = 0;
    if (g_io_in_ready !== i_io_in_ready) begin n++; if (verbose) $display("  MISMATCH io_in_ready g=%h i=%h", g_io_in_ready, i_io_in_ready); end
    if (g_io_out_valid !== i_io_out_valid) begin n++; if (verbose) $display("  MISMATCH io_out_valid g=%h i=%h", g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_robIdx_flag g=%h i=%h", g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
    if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_robIdx_value g=%h i=%h", g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
    if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_pdest g=%h i=%h", g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
    if (g_io_out_bits_ctrl_vecWen !== i_io_out_bits_ctrl_vecWen) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_vecWen g=%h i=%h", g_io_out_bits_ctrl_vecWen, i_io_out_bits_ctrl_vecWen); end
    if (g_io_out_bits_ctrl_v0Wen !== i_io_out_bits_ctrl_v0Wen) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_v0Wen g=%h i=%h", g_io_out_bits_ctrl_v0Wen, i_io_out_bits_ctrl_v0Wen); end
    if (g_io_out_bits_ctrl_fpu_wflags !== i_io_out_bits_ctrl_fpu_wflags) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_fpu_wflags g=%h i=%h", g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags); end
    if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin n++; if (verbose) $display("  MISMATCH io_out_bits_res_data g=%h i=%h", g_io_out_bits_res_data, i_io_out_bits_res_data); end
    if (g_io_out_bits_res_fflags !== i_io_out_bits_res_fflags) begin n++; if (verbose) $display("  MISMATCH io_out_bits_res_fflags g=%h i=%h", g_io_out_bits_res_fflags, i_io_out_bits_res_fflags); end
    if (g_io_out_bits_perfDebugInfo_eliminatedMove !== i_io_out_bits_perfDebugInfo_eliminatedMove) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_eliminatedMove g=%h i=%h", g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove); end
    if (g_io_out_bits_perfDebugInfo_renameTime !== i_io_out_bits_perfDebugInfo_renameTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_renameTime g=%h i=%h", g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime); end
    if (g_io_out_bits_perfDebugInfo_dispatchTime !== i_io_out_bits_perfDebugInfo_dispatchTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_dispatchTime g=%h i=%h", g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime); end
    if (g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_enqRsTime g=%h i=%h", g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_selectTime g=%h i=%h", g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime); end
    if (g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_issueTime g=%h i=%h", g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime); end
    if (g_io_out_bits_perfDebugInfo_writebackTime !== i_io_out_bits_perfDebugInfo_writebackTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_writebackTime g=%h i=%h", g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime); end
    if (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id !== i_io_out_bits_perfDebugInfo_runahead_checkpoint_id) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_runahead_checkpoint_id g=%h i=%h", g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id); end
    if (g_io_out_bits_perfDebugInfo_tlbFirstReqTime !== i_io_out_bits_perfDebugInfo_tlbFirstReqTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_tlbFirstReqTime g=%h i=%h", g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime); end
    if (g_io_out_bits_perfDebugInfo_tlbRespTime !== i_io_out_bits_perfDebugInfo_tlbRespTime) begin n++; if (verbose) $display("  MISMATCH io_out_bits_perfDebugInfo_tlbRespTime g=%h i=%h", g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime); end
    if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin n++; if (verbose) $display("  MISMATCH io_out_bits_debug_seqNum_seqNum g=%h i=%h", g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
    if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin n++; if (verbose) $display("  MISMATCH io_out_bits_debug_seqNum_uopIdx g=%h i=%h", g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
    return n;
  endfunction



  // ---------------------------------------------------------------------------
  // IEEE 754 除法 oracle（fmt：0 f16 / 1 f32 / 2 f64）
  // ---------------------------------------------------------------------------
  localparam int FL_NV = 4, FL_DZ = 3, FL_OF = 2, FL_UF = 1, FL_NX = 0;
  function automatic bit rup(input logic [2:0] mode, input bit sign, input bit lsb, input bit rnd, input bit stk);
    case (mode)
      3'd0: return rnd & (stk | lsb);
      3'd2: return (rnd | stk) & sign;
      3'd3: return (rnd | stk) & ~sign;
      3'd4: return rnd;
      default: return 0;          // RTZ（及 5..7）
    endcase
  endfunction

  int res_class [6];   // 0 规格 1 非规格 2 上溢 3 NaN 4 ∞ 5 零
  function automatic void ref_div(input int fmt, input logic [63:0] a, input logic [63:0] b, input logic [2:0] mode,
                                  output logic [63:0] res, output logic [4:0] fl);
    int ew, mw, bias, emax_b;
    bit sa, sb, sign, a_nan, b_nan, a_snan, b_snan, a_inf, b_inf, a_zero, b_zero;
    longint ea, eb, xa, xb, e, ebiased, shift;
    logic [127:0] ma, mb, num, q, tmp, sig;
    bit sticky, lost, r, st, up, inexact, tiny;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    bias = (1 << (ew - 1)) - 1;
    emax_b = (1 << ew) - 1;
    sa = a[ew + mw]; sb = b[ew + mw]; sign = sa ^ sb;
    ea = (a >> mw) & ((64'd1 << ew) - 1);  eb = (b >> mw) & ((64'd1 << ew) - 1);
    ma = a & ((128'd1 << mw) - 1);         mb = b & ((128'd1 << mw) - 1);
    a_nan = (ea == emax_b) && (ma != 0);   b_nan = (eb == emax_b) && (mb != 0);
    a_snan = a_nan && !ma[mw - 1];         b_snan = b_nan && !mb[mw - 1];
    a_inf = (ea == emax_b) && (ma == 0);   b_inf = (eb == emax_b) && (mb == 0);
    a_zero = (ea == 0) && (ma == 0);       b_zero = (eb == 0) && (mb == 0);
    fl = '0;
    if (a_nan || b_nan || (a_inf && b_inf) || (a_zero && b_zero)) begin
      res = (64'(emax_b) << mw) | (64'd1 << (mw - 1));      // 正号 quiet NaN
      fl[FL_NV] = a_snan | b_snan | (a_inf & b_inf) | (a_zero & b_zero);
      res_class[3]++;
      return;
    end
    if (a_inf || b_zero) begin
      res = (64'(sign) << (ew + mw)) | (64'(emax_b) << mw);
      fl[FL_DZ] = b_zero & ~a_inf;
      res_class[4]++;
      return;
    end
    if (a_zero || b_inf) begin
      res = 64'(sign) << (ew + mw);
      res_class[5]++;
      return;
    end
    // 有限非零：规格化成 1.xxx（ma/mb 的最高位在 bit mw）
    xa = (ea == 0) ? 1 - bias : ea - bias;  if (ea != 0) ma |= 128'd1 << mw;
    xb = (eb == 0) ? 1 - bias : eb - bias;  if (eb != 0) mb |= 128'd1 << mw;
    while (ma < (128'd1 << mw)) begin ma <<= 1; xa--; end
    while (mb < (128'd1 << mw)) begin mb <<= 1; xb--; end
    e = xa - xb;
    if (ma < mb) begin num = ma << (mw + 5); e--; end
    else         num = ma << (mw + 4);
    q = num / mb;                 // 商在 [2^(mw+4), 2^(mw+5))：p = mw+1 个有效位 + 4 个额外位
    sticky = (num % mb) != 0;
    ebiased = e + bias;
    if (ebiased >= 1) begin
      sig = q >> 4;  r = q[3];  st = (q[2:0] != 0) | sticky;
      up = rup(mode, sign, sig[0], r, st);
      sig += up;
      inexact = r | st;
      if (sig == (128'd1 << (mw + 1))) begin sig >>= 1; ebiased++; end
      if (ebiased >= emax_b) begin
        fl[FL_OF] = 1; fl[FL_NX] = 1;
        if (mode == 0 || mode == 4 || (mode == 3 && !sign) || (mode == 2 && sign))
          res = (64'(sign) << (ew + mw)) | (64'(emax_b) << mw);
        else
          res = (64'(sign) << (ew + mw)) | (64'(emax_b - 1) << mw) | ((64'd1 << mw) - 1);
        res_class[2]++;
        return;
      end
      res = (64'(sign) << (ew + mw)) | (64'(ebiased) << mw) | 64'(sig & ((128'd1 << mw) - 1));
      fl[FL_NX] = inexact;
      res_class[0]++;
      return;
    end
    // 非规格数结果：右移 1−E 位后舍入
    shift = 1 - ebiased;
    if (shift > mw + 8) begin
      tmp = 0; lost = 1;
    end else begin
      tmp  = q >> shift;
      lost = (q & ((128'd1 << shift) - 1)) != 0;
    end
    sig = tmp >> 4;  r = tmp[3];  st = (tmp[2:0] != 0) | lost | sticky;
    up = rup(mode, sign, sig[0], r, st);
    sig += up;
    inexact = r | st;
    // tiny 判定（舍入后、指数无界）：E<0 必 tiny；E==0 时看按 p 位舍入是否进位到 2^emin
    if (ebiased < 0) tiny = 1;
    else tiny = !(((q >> 4) + rup(mode, sign, q[4], q[3], (q[2:0] != 0) | sticky)) == (128'd1 << (mw + 1)));
    fl[FL_UF] = tiny & inexact;
    fl[FL_NX] = inexact;
    res = (64'(sign) << (ew + mw)) | (64'(sig >> mw) << mw) | 64'(sig & ((128'd1 << mw) - 1));
    res_class[1]++;
  endfunction

  // 一次向量操作的期望结果
  function automatic void ref_vec(input logic [1:0] f, input logic [63:0] a, input logic [63:0] b, input logic [2:0] mode,
                                  output logic [63:0] res, output logic [19:0] fl);
    logic [63:0] r;
    logic [4:0]  x;
    res = '0; fl = '0;
    case (f)
      2'd3: begin ref_div(2, a, b, mode, r, x); res = r; fl[4:0] = x; end
      2'd2: for (int k = 0; k < 2; k++) begin
              ref_div(1, 64'(a[32*k +: 32]), 64'(b[32*k +: 32]), mode, r, x);
              res[32*k +: 32] = r[31:0]; fl[5*k +: 5] = x;
            end
      default: for (int k = 0; k < 4; k++) begin
              ref_div(0, 64'(a[16*k +: 16]), 64'(b[16*k +: 16]), mode, r, x);
              res[16*k +: 16] = r[15:0]; fl[5*k +: 5] = x;
            end
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 操作数构造
  // ---------------------------------------------------------------------------
  int cls_hist [8];
  function automatic logic [63:0] make_fp(input int fmt, input int cls, input int exp_hint);
    int ew, mw, emax_b;
    logic [63:0] m, e, s;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    emax_b = (1 << ew) - 1;
    s = $urandom & 1;
    m = {$urandom, $urandom} & ((64'd1 << mw) - 1);
    case ($urandom_range(0, 7))
      0: m = '0;
      1: m = (64'd1 << mw) - 1;
      2: m = m & {$urandom, $urandom};
      default: ;
    endcase
    case (cls)
      0: begin e = 0; m = 0; end                                  // ±0
      1: begin e = 0; if (m == 0) m = 1; end                       // 非规格数
      2: e = 1;                                                    // 最小规格数附近
      3: begin e = emax_b - 1; end                                 // 最大有限数附近
      4: begin e = emax_b; m = 0; end                              // ±∞
      5: begin e = emax_b; m = m | (64'd1 << (mw - 1)); end        // qNaN
      6: begin e = emax_b; m = m & ~(64'd1 << (mw - 1)); if (m == 0) m = 1; end   // sNaN
      default: begin                                               // 规格数，指数按提示
        if (exp_hint < 1) e = 1; else if (exp_hint > emax_b - 1) e = emax_b - 1; else e = exp_hint;
      end
    endcase
    return (s << (ew + mw)) | (e << mw) | m;
  endfunction

  // 生成一对元素（a, b），偏置指数关系与尾数关系
  task automatic make_pair(input int fmt, output logic [63:0] a, output logic [63:0] b);
    int ew, mw, emax_b, bias, ca, cb, ea, eb, mw_mask;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    emax_b = (1 << ew) - 1;
    bias = (1 << (ew - 1)) - 1;
    ca = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 6) : 7;
    cb = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 6) : 7;
    cls_hist[ca]++;
    eb = $urandom_range(1, emax_b - 1);
    case ($urandom_range(0, 5))
      0: ea = eb + bias + $urandom_range(0, 3) - 1;          // 商指数在上溢边界
      1: ea = eb - bias + 1 - $urandom_range(0, mw + 3);     // 商落入非规格数区
      2: ea = eb - bias - $urandom_range(0, 3);              // 商在最小规格数边界
      default: ea = $urandom_range(1, emax_b - 1);
    endcase
    a = make_fp(fmt, ca, ea);
    b = make_fp(fmt, cb, eb);
    if (cb == 7 && $urandom_range(0, 7) == 0) b &= ~((64'd1 << mw) - 1);                       // 除数 2 的幂
    if (ca == 7 && cb == 7 && $urandom_range(0, 15) == 0)                                      // 尾数相同
      a = (a & ~((64'd1 << mw) - 1)) | (b & ((64'd1 << mw) - 1));
  endtask

  task automatic make_vec(input logic [1:0] f, output logic [63:0] a, output logic [63:0] b);
    logic [63:0] x, y;
    a = {$urandom, $urandom}; b = {$urandom, $urandom};
    case (f)
      2'd3: begin make_pair(2, x, y); a = x; b = y; end
      2'd2: for (int k = 0; k < 2; k++) begin make_pair(1, x, y); a[32*k +: 32] = x[31:0]; b[32*k +: 32] = y[31:0]; end
      2'd1: for (int k = 0; k < 4; k++) begin make_pair(0, x, y); a[16*k +: 16] = x[15:0]; b[16*k +: 16] = y[15:0]; end
      default: ;
    endcase
  endtask


  // ---------------------------------------------------------------------------
  // IEEE 754 开方 oracle（fmt：0 f16 / 1 f32 / 2 f64）
  // ---------------------------------------------------------------------------
  int sq_class [4];   // 0 规格 1 NaN 2 ∞ 3 零
  function automatic logic [255:0] isqrt256(input logic [255:0] n, output bit exact);
    logic [255:0] r, bit_, x;
    x = n; r = 0; bit_ = 256'd1 << 254;
    while (bit_ > x) bit_ >>= 2;
    while (bit_ != 0) begin
      if (x >= r + bit_) begin x -= r + bit_; r = (r >> 1) + bit_; end
      else r >>= 1;
      bit_ >>= 2;
    end
    exact = (x == 0);
    return r;
  endfunction

  function automatic void ref_sqrt(input int fmt, input logic [63:0] a, input logic [2:0] mode,
                                   output logic [63:0] res, output logic [4:0] fl);
    int ew, mw, bias, emax_b, nb, sh;
    bit sa, a_nan, a_snan, a_inf, a_zero, exact, r, st, up;
    longint ea, e;
    logic [255:0] m, root, sig;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    bias = (1 << (ew - 1)) - 1;
    emax_b = (1 << ew) - 1;
    sa = a[ew + mw];
    ea = (a >> mw) & ((64'd1 << ew) - 1);
    m  = a & ((256'd1 << mw) - 1);
    a_nan = (ea == emax_b) && (m != 0);  a_snan = a_nan && !m[mw - 1];
    a_inf = (ea == emax_b) && (m == 0);  a_zero = (ea == 0) && (m == 0);
    fl = '0;
    if (a_nan || (sa && !a_zero)) begin
      res = (64'(emax_b) << mw) | (64'd1 << (mw - 1));      // 正号 quiet NaN
      fl[FL_NV] = a_snan | (sa & !a_nan);
      sq_class[1]++;
      return;
    end
    if (a_zero) begin res = 64'(sa) << (ew + mw); sq_class[3]++; return; end
    if (a_inf)  begin res = 64'(emax_b) << mw;    sq_class[2]++; return; end
    // 有限正数：值 = m * 2^(e)，m 为整数尾数（规格数补隐含位）
    if (ea == 0) e = 1 - bias - mw; else begin e = ea - bias - mw; m |= 256'd1 << mw; end
    if (e % 2 != 0) begin m <<= 1; e -= 1; end             // 指数凑偶
    // root = floor(sqrt(m * 4^(mw+6)))，值 = root * 2^(e/2 - (mw+6))
    root = isqrt256(m << (2 * (mw + 6)), exact);
    nb = 0; for (int k = 0; k < 256; k++) if (root[k]) nb = k + 1;
    sh = nb - (mw + 5);                                    // 归一到 mw+1 个有效位 + 4 位额外位
    st = !exact;
    if (sh > 0) begin st |= (root & ((256'd1 << sh) - 1)) != 0; sig = root >> sh; end
    else sig = root << (-sh);
    // 最高位的指数：(nb-1) + e/2 - (mw+6)
    e = (nb - 1) + e / 2 - (mw + 6) + bias;
    r = sig[3]; st |= (sig[2:0] != 0);
    sig >>= 4;
    up = rup(mode, 1'b0, sig[0], r, st);
    sig += up;
    if (sig == (256'd1 << (mw + 1))) begin sig >>= 1; e++; end
    res = (64'(e) << mw) | 64'(sig & ((256'd1 << mw) - 1));
    fl[FL_NX] = r | st;
    sq_class[0]++;
  endfunction

  function automatic void ref_sqrt_vec(input logic [1:0] f, input logic [63:0] a, input logic [2:0] mode,
                                       output logic [63:0] res, output logic [19:0] fl);
    logic [63:0] r;
    logic [4:0]  x;
    res = '0; fl = '0;
    case (f)
      2'd3: begin ref_sqrt(2, a, mode, r, x); res = r; fl[4:0] = x; end
      2'd2: for (int k = 0; k < 2; k++) begin
              ref_sqrt(1, 64'(a[32*k +: 32]), mode, r, x);
              res[32*k +: 32] = r[31:0]; fl[5*k +: 5] = x;
            end
      default: for (int k = 0; k < 4; k++) begin
              ref_sqrt(0, 64'(a[16*k +: 16]), mode, r, x);
              res[16*k +: 16] = r[15:0]; fl[5*k +: 5] = x;
            end
    endcase
  endfunction

  task automatic make_sqrt_vec(input logic [1:0] f, output logic [63:0] a);
    logic [63:0] x;
    int fmt, w, n, cls, ew, emax_b;
    a = {$urandom, $urandom};
    fmt = (f == 2'd3) ? 2 : (f == 2'd2) ? 1 : 0;
    w = (fmt == 2) ? 64 : (fmt == 1) ? 32 : 16;
    n = 64 / w;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    emax_b = (1 << ew) - 1;
    if (f == 2'd0) return;
    for (int k = 0; k < n; k++) begin
      cls = ($urandom_range(0, 2) == 0) ? $urandom_range(0, 6) : 7;
      x = make_fp(fmt, cls, $urandom_range(1, emax_b - 1));
      if (cls == 7 && $urandom_range(0, 3) != 0) x[w - 1] = 1'b0;   // 规格数大多取正（负数另有 1/4）
      case (fmt)
        2: a = x;
        1: a[32*k +: 32] = x[31:0];
        default: a[16*k +: 16] = x[15:0];
      endcase
    end
  endtask

  // ---------------------------------------------------------------------------
  // 外壳层 oracle：Mgu（mask / tail / vstart）+ fflags 元素选择
  // ---------------------------------------------------------------------------
  typedef struct {
    bit           sqrt;
    logic [8:0]   fu;
    logic [1:0]   sew;
    logic [2:0]   vlmul, rm;
    logic [2:0]   uop;
    logic [7:0]   vl, vstart;
    bit           vm, vta, vma;
    logic [127:0] v0, old, vs1, vs2;
  } op_t;
  int cov_sew [4], cov_kind [2], cov_masked = 0, cov_tail [2], cov_prestart = 0, cov_frac = 0, cov_vstart_ge_vl = 0;

  task automatic shell_oracle(input op_t o, output logic [127:0] exp_vd, output logic [4:0] exp_ff);
    logic [63:0]  r [2];
    logic [19:0]  f [2];
    logic [127:0] new_vd;
    logic [63:0]  nv, ov, ev, em;
    int w, n, gi, n_this, sh;
    bit mbit, clear;
    logic [4:0] vlmax;
    for (int h = 0; h < 2; h++) begin
      if (o.sqrt) ref_sqrt_vec(o.sew, o.vs2[64*h +: 64], o.rm, r[h], f[h]);
      else        ref_vec(o.sew, o.vs2[64*h +: 64], o.vs1[64*h +: 64], o.rm, r[h], f[h]);
    end
    new_vd = {r[1], r[0]};
    w  = 8 << o.sew;
    n  = 128 / w;
    em = (w == 64) ? '1 : ((64'd1 << w) - 1);
    clear  = (o.fu == 9'h084) || (o.fu == 9'h086);
    vlmax  = 5'd16 >> o.sew;
    sh     = o.vlmul[2] ? int'(2'(~o.vlmul[1:0] + 2'd1)) : 0;
    n_this = o.vlmul[2] ? (int'(vlmax) >> sh) : int'(vlmax);
    exp_vd = '0;
    exp_ff = '0;
    for (int i = 0; i < n; i++) begin
      gi   = int'(o.uop) * n + i;
      mbit = clear ? 1'b0 : (o.vm ? 1'b1 : o.v0[gi]);
      nv   = 64'(new_vd >> (w * i)) & em;
      ov   = 64'(o.old >> (w * i)) & em;
      if (o.vstart >= o.vl) begin ev = ov; cov_vstart_ge_vl++; end      // ByteMaskTailGen：vstart>=vl 整条不写
      else if (gi < int'(o.vstart)) begin ev = ov; cov_prestart++; end
      else if (gi >= int'(o.vl)) begin ev = o.vta ? em : ov; cov_tail[o.vta]++; end
      else if (mbit) ev = nv;
      else begin ev = o.vma ? em : ov; cov_masked++; end
      exp_vd |= 128'(ev) << (w * i);
      // fflags：元素 i 落在第 i/(n/2) 个 64 位半边、半边内第 i%(n/2) 组
      if (i < n_this && int'(o.uop) * n_this + i < int'(o.vl) &&
          (clear ? 1'b0 : (o.vm ? 1'b1 : o.v0[int'(o.uop) * int'(vlmax) + i])))
        exp_ff |= f[i / (n / 2)][5 * (i % (n / 2)) +: 5];
    end
    if (o.vlmul[2]) cov_frac++;
  endtask

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  bit cfg_legal;
  task automatic drive();
    logic [63:0]  a, b;
    logic [127:0] va, vb;
    int n, base, vlmax, nreg;
    io_flush_valid             = ($urandom_range(0, 149) == 0);
    io_flush_bits_robIdx_flag  = $urandom;
    io_flush_bits_robIdx_value = $urandom;
    io_flush_bits_level        = $urandom;
    io_in_valid  = g_io_in_ready ? ($urandom_range(0, 3) != 0) : ($urandom_range(0, 59) == 0);
    io_in_bits_ctrl_fuOpType = $urandom;
    if ($urandom_range(0, 31) == 0) io_in_bits_ctrl_fuOpType = $urandom_range(0, 1) ? 9'h084 : 9'h086;
    io_in_bits_ctrl_robIdx_flag   = $urandom;
    io_in_bits_ctrl_robIdx_value  = $urandom;
    io_in_bits_ctrl_pdest         = $urandom;
    io_in_bits_ctrl_vecWen        = $urandom;
    io_in_bits_ctrl_v0Wen         = $urandom;
    io_in_bits_ctrl_fpu_wflags    = $urandom;
    io_in_bits_ctrl_vpu_vma       = $urandom;
    io_in_bits_ctrl_vpu_vta       = $urandom;
    io_in_bits_ctrl_vpu_vsew      = ($urandom_range(0, 9) == 0) ? 2'd0 : 2'($urandom_range(1, 3));
    io_in_bits_ctrl_vpu_vlmul     = ($urandom_range(0, 3) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 3));
    io_in_bits_ctrl_vpu_vm        = $urandom;
    io_in_bits_ctrl_vpu_isNarrow  = ($urandom_range(0, 15) == 0);
    io_in_bits_ctrl_vpu_isDstMask = ($urandom_range(0, 15) == 0);
    // 合法 RVV 配置（7/8）：vl <= VLMAX(SEW, LMUL)、uop < 寄存器组大小、vstart <= vl；其余 1/8 全随机（只做差分）
    n     = 128 >> (3 + io_in_bits_ctrl_vpu_vsew);                     // 一个寄存器的元素数
    vlmax = io_in_bits_ctrl_vpu_vlmul[2] ? (n >> (4 - int'(io_in_bits_ctrl_vpu_vlmul[1:0]))) : (n << io_in_bits_ctrl_vpu_vlmul[1:0]);
    nreg  = io_in_bits_ctrl_vpu_vlmul[2] ? 1 : (1 << io_in_bits_ctrl_vpu_vlmul[1:0]);
    io_in_bits_ctrl_vpu_vuopIdx = 7'($urandom_range(0, nreg - 1));
    base = int'(io_in_bits_ctrl_vpu_vuopIdx) * n;
    case ($urandom_range(0, 3))
      0, 1: io_in_bits_data_src_4 = 8'((base + $urandom_range(0, n) > vlmax) ? vlmax : base + $urandom_range(0, n));
      default: io_in_bits_data_src_4 = 8'($urandom_range(0, vlmax));
    endcase
    io_in_bits_ctrl_vpu_vstart = ($urandom_range(0, 9) < 7) ? 8'd0 : 8'($urandom_range(0, io_in_bits_data_src_4));
    cfg_legal = 1;
    if ($urandom_range(0, 7) == 0) begin
      io_in_bits_ctrl_vpu_vlmul   = $urandom;
      io_in_bits_ctrl_vpu_vuopIdx = $urandom;
      io_in_bits_data_src_4       = $urandom;
      io_in_bits_ctrl_vpu_vstart  = $urandom;
      cfg_legal = 0;
    end
    io_in_bits_data_src_3 = {$urandom, $urandom, $urandom, $urandom};
    io_in_bits_data_src_2 = {$urandom, $urandom, $urandom, $urandom};
    for (int h = 0; h < 2; h++) begin
      if (io_in_bits_ctrl_fuOpType[0]) begin make_sqrt_vec(io_in_bits_ctrl_vpu_vsew, a); b = {$urandom, $urandom}; end
      else make_vec(io_in_bits_ctrl_vpu_vsew, a, b);
      va[64*h +: 64] = a; vb[64*h +: 64] = b;
    end
    io_in_bits_data_src_1 = va;
    io_in_bits_data_src_0 = vb;
    io_in_bits_perfDebugInfo_eliminatedMove         = $urandom;
    io_in_bits_perfDebugInfo_renameTime             = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_dispatchTime           = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_enqRsTime              = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_selectTime             = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_issueTime              = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_writebackTime          = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_tlbFirstReqTime        = {$urandom, $urandom};
    io_in_bits_perfDebugInfo_tlbRespTime            = {$urandom, $urandom};
    io_in_bits_debug_seqNum_seqNum                  = {$urandom, $urandom};
    io_in_bits_debug_seqNum_uopIdx                  = $urandom;
    io_out_ready = ($urandom_range(0, 3) != 0);
    io_frm       = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  bit  op_live = 0, op_legal, taint = 0, fired_once = 0, armed = 0;
  bit  done_div [2], done_sqrt [2];
  op_t op;
  int  n_flush_mid = 0, n_backpressure = 0, n_violate = 0;
  logic [127:0] seen0_vd = '0, seen1_vd = '0;
  logic [4:0]   seen0_ff = '0, seen1_ff = '0;

  initial begin
    int bad, nd;
    bit bad_now;
    logic [127:0] ev; logic [4:0] ef;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    done_div = '{0, 0}; done_sqrt = '{0, 0};
    reset = 1;
    drive();
    io_in_valid = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      #1;
      // ---- 武装：两个除法器各自的除法 / 开方子单元都完整走过一次 ----
      if (u_g.vfdivs_0.u_vector_float_divider_r64.fsm_q[4]) done_div[0] = 1;
      if (u_g.vfdivs_1.u_vector_float_divider_r64.fsm_q[4]) done_div[1] = 1;
      if (u_g.vfdivs_0.u_vector_float_sqrt_r16.finish_valid_o) done_sqrt[0] = 1;
      if (u_g.vfdivs_1.u_vector_float_sqrt_r16.finish_valid_o) done_sqrt[1] = 1;
      armed = done_div[0] & done_div[1] & done_sqrt[0] & done_sqrt[1];
      // ---- 差分 ----
      checks++;
      bad_now = (g_io_in_ready !== i_io_in_ready) || (g_io_out_valid !== i_io_out_valid);
      if (fired_once) begin
        nd = diff_outputs(0);
        if (!armed) nd = nd - int'(g_io_out_bits_res_data !== i_io_out_bits_res_data)
                           - int'(g_io_out_bits_res_fflags !== i_io_out_bits_res_fflags);
        if (nd > 0) bad_now = 1;
      end
      if (bad_now) begin
        errors++;
        if (errors <= 20) begin $display("[%0d] MISMATCH (armed=%0d)", cyc, armed); void'(diff_outputs(1)); end
      end
      if (armed) begin
        seen1_vd |= g_io_out_bits_res_data;   seen0_vd |= ~g_io_out_bits_res_data;
        seen1_ff |= g_io_out_bits_res_fflags; seen0_ff |= ~g_io_out_bits_res_fflags;
      end
      // ---- oracle：本 uop 的 out 握手拍 ----
      if (g_io_out_valid && io_out_ready && !io_flush_valid && op_live && op_legal && !taint && armed) begin
        shell_oracle(op, ev, ef);
        oracle_checks++;
        cov_sew[op.sew]++; cov_kind[op.sqrt]++;
        if (i_io_out_bits_res_data !== ev || i_io_out_bits_res_fflags !== ef) begin
          oracle_err++;
          if (oracle_err <= 30)
            $display("[%0d] ORACLE %s sew=%0d vlmul=%0d uop=%0d vl=%0d vstart=%0d vm=%0d ta=%0d ma=%0d fu=%h\n   exp vd=%h ff=%b\n   got vd=%h ff=%b",
                     cyc, op.sqrt ? "sqrt" : "div", op.sew, op.vlmul, op.uop, op.vl, op.vstart, op.vm, op.vta, op.vma, op.fu,
                     ev, ef, i_io_out_bits_res_data, i_io_out_bits_res_fflags);
        end
      end
      // ---- 记录本拍上升沿将发生的握手 ----
      if (op_live && !g_io_out_valid && io_flush_valid) n_flush_mid++;
      if (g_io_out_valid && !io_out_ready) n_backpressure++;
      if (io_flush_valid) op_live = 0;
      else if (g_io_out_valid && io_out_ready) op_live = 0;
      if (io_in_valid && !g_io_in_ready) begin taint = 1; op_live = 0; n_violate++; end
      else if (g_io_in_ready) taint = 0;
      if (g_io_in_ready && io_in_valid) fired_once = 1;
      if (!io_flush_valid && g_io_in_ready && io_in_valid) begin
        op_live  = 1;
        op_legal = cfg_legal && (io_in_bits_ctrl_vpu_vsew != 2'd0) && !io_in_bits_ctrl_vpu_isNarrow && !io_in_bits_ctrl_vpu_isDstMask;
        op.sqrt  = io_in_bits_ctrl_fuOpType[0];   op.fu     = io_in_bits_ctrl_fuOpType;
        op.sew   = io_in_bits_ctrl_vpu_vsew;      op.vlmul  = io_in_bits_ctrl_vpu_vlmul;
        op.rm    = io_frm;                        op.uop    = io_in_bits_ctrl_vpu_vuopIdx[2:0];
        op.vl    = io_in_bits_data_src_4;         op.vstart = io_in_bits_ctrl_vpu_vstart;
        op.vm    = io_in_bits_ctrl_vpu_vm;        op.vta    = io_in_bits_ctrl_vpu_vta;
        op.vma   = io_in_bits_ctrl_vpu_vma;       op.v0     = io_in_bits_data_src_3;
        op.old   = io_in_bits_data_src_2;         op.vs1    = io_in_bits_data_src_0;
        op.vs2   = io_in_bits_data_src_1;
      end
    end
    // ---- 判据 ----
    bad = 0;
    if (oracle_checks < 3000 || cov_kind[0] < 1000 || cov_kind[1] < 1000) bad++;
    for (int s = 1; s < 4; s++) if (cov_sew[s] < 500) bad++;
    if (cov_masked < 100 || cov_tail[0] < 100 || cov_tail[1] < 100 || cov_prestart < 100 || cov_frac < 100 || cov_vstart_ge_vl < 100) bad++;
    if (n_flush_mid < 20 || n_backpressure < 100) bad++;
    if (seen0_vd !== '1 || seen1_vd !== '1) begin bad++; $display("res_data not toggled: 0=%h 1=%h", seen0_vd, seen1_vd); end
    if (seen0_ff !== '1 || seen1_ff !== '1) begin bad++; $display("res_fflags not toggled: 0=%b 1=%b", seen0_ff, seen1_ff); end
    $display("COVERAGE oracle=%0d div/sqrt=%0d/%0d sew1/2/3=%0d/%0d/%0d masked=%0d tail ta0/1=%0d/%0d prestart=%0d vstart>=vl=%0d frac=%0d flush_mid=%0d backpressure=%0d violate=%0d",
             oracle_checks, cov_kind[0], cov_kind[1], cov_sew[1], cov_sew[2], cov_sew[3], cov_masked, cov_tail[0], cov_tail[1],
             cov_prestart, cov_vstart_ge_vl, cov_frac, n_flush_mid, n_backpressure, n_violate);
    $display("ORACLE oracle_errors=%0d", oracle_err);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_err == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
