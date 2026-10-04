// =============================================================================
// tb —— VIAluFix UT：golden VIAluFix（含 golden 子树）与重写件 VIAluFix_xs（子树全是重写件：VIAluSrcTypeModule、
// VecDataSplitModule ×2、VIntFixpAlu64b ×2（+ VIntAdder64b / VIntMisc64b / VFixPoint64b / CLZ / Adder_chain_rnd）、Mgu、Mgtu）
// 双例化，同时钟同激励逐拍比全部输出。
//
// 激励：每拍造一个 uop（op_t），第 0 级端口取本拍的 uop，第 1 级端口（ctrlPipe_1 / dataPipe_1 / validPipe_1）取上一拍的 uop
//   —— 模拟发射级预打好的流水（VIntFixpAlu64b 每拍随 fire 前进一级）。validPipe_0 = 本拍 valid（九成），偶尔翻转以覆盖
//   outEewVs1 寄存器的使能条件。in_valid 3/4；out_ready 7/8；fuOpType 七成取 oracle 覆盖的编码（见下），其余取 VialuFixType 的
//   全部合法编码或随机；isExt / isNarrow / isDstMask / isOpMask 按 fuOpType 的格式给出（偶尔随机）；七成以上合法 RVV 配置。
// 差分比较：in_ready / out_valid 每拍比；其余输出在第一次 in_valid 之后 1 拍起每拍比。
// 独立按元素 oracle（tb 内整数算术），对第 1 级上合法、有效的下列 uop（isExt / isNarrow / isDstMask = 0）：
//   - 同宽：vadd / vsub / vand / vor / vxor / vsll / vsrl / vsra / vmin(u) / vmax(u) / vmerge / vmv.v.v（SEW 8/16/32/64；
//     只用 VialuFixType 的合法编码——有符号位错配的非法编码如 0x059 不在 Mgu 的 needNoMask 表里，只做差分）；
//   - 加宽：vwadd(u) / vwsub(u) 的 .vv / .wv（源 SEW 8/16/32，结果 2·SEW；源元素 = vuopIdx[0]·(128/结果SEW) + i）；
//   - Mgu：vstart >= vl → 整个 vd 保持旧值；否则 < vstart 旧值；>= vl → vta ? 全 1 : 旧值；掩码关（vmerge 例外：不用掩码）
//     → vma ? 全 1 : 旧值；vxsat 应为 0。
//   其余（比较 / vmadc 等产生掩码、定点饱和平均与缩放移位、变窄、vext、Zvbb、vmv.s.x）只做差分。
// 覆盖（写进 PASS 判据）：oracle 比对 >= 30000；14 个同宽编码各 >= 500；加宽 .vv / .wv 各 >= 1000；4 种 SEW 各 >= 3000；
//   掩码关 / 尾部（ta 0/1）/ vstart 前部 / vstart>=vl 各 >= 100；isDstMask / isNarrow / isExt 的差分拍各 >= 3000；
//   res_data 每位、res_vxsat 都见过 0 和 1。
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
  logic           g_io_in_ready, i_io_in_ready;
  logic           io_in_valid;
  logic [8:0]     io_in_bits_ctrl_fuOpType;
  logic           io_in_bits_ctrl_vpu_vma;
  logic [1:0]     io_in_bits_ctrl_vpu_vsew;
  logic           io_in_bits_ctrl_vpu_vm;
  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx;
  logic           io_in_bits_ctrl_vpu_isExt;
  logic           io_in_bits_ctrl_vpu_isNarrow;
  logic           io_in_bits_ctrl_vpu_isDstMask;
  logic [8:0]     io_in_bits_ctrlPipe_1_fuOpType;
  logic           io_in_bits_ctrlPipe_1_robIdx_flag;
  logic [7:0]     io_in_bits_ctrlPipe_1_robIdx_value;
  logic [7:0]     io_in_bits_ctrlPipe_1_pdest;
  logic           io_in_bits_ctrlPipe_1_vecWen;
  logic           io_in_bits_ctrlPipe_1_v0Wen;
  logic           io_in_bits_ctrlPipe_1_vpu_vma;
  logic           io_in_bits_ctrlPipe_1_vpu_vta;
  logic [1:0]     io_in_bits_ctrlPipe_1_vpu_vsew;
  logic           io_in_bits_ctrlPipe_1_vpu_vm;
  logic [7:0]     io_in_bits_ctrlPipe_1_vpu_vstart;
  logic [6:0]     io_in_bits_ctrlPipe_1_vpu_vuopIdx;
  logic           io_in_bits_ctrlPipe_1_vpu_isExt;
  logic           io_in_bits_ctrlPipe_1_vpu_isNarrow;
  logic           io_in_bits_ctrlPipe_1_vpu_isDstMask;
  logic           io_in_bits_ctrlPipe_1_vpu_isOpMask;
  logic           io_in_bits_validPipe_0;
  logic           io_in_bits_validPipe_1;
  logic [127:0]   io_in_bits_data_src_3;
  logic [127:0]   io_in_bits_data_src_2;
  logic [127:0]   io_in_bits_data_src_1;
  logic [127:0]   io_in_bits_data_src_0;
  logic [7:0]     io_in_bits_dataPipe_1_src_4;
  logic [127:0]   io_in_bits_dataPipe_1_src_3;
  logic [127:0]   io_in_bits_dataPipe_1_src_2;
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
  logic [127:0]   g_io_out_bits_res_data, i_io_out_bits_res_data;
  logic           g_io_out_bits_res_vxsat, i_io_out_bits_res_vxsat;
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
  logic [1:0]     io_vxrm;
  VIAluFix u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vma(io_in_bits_ctrl_vpu_vma),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isExt(io_in_bits_ctrl_vpu_isExt),
    .io_in_bits_ctrl_vpu_isNarrow(io_in_bits_ctrl_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask(io_in_bits_ctrl_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_fuOpType(io_in_bits_ctrlPipe_1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest),
    .io_in_bits_ctrlPipe_1_vecWen(io_in_bits_ctrlPipe_1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen(io_in_bits_ctrlPipe_1_v0Wen),
    .io_in_bits_ctrlPipe_1_vpu_vma(io_in_bits_ctrlPipe_1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta(io_in_bits_ctrlPipe_1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew(io_in_bits_ctrlPipe_1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vm(io_in_bits_ctrlPipe_1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart(io_in_bits_ctrlPipe_1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx(io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_isExt(io_in_bits_ctrlPipe_1_vpu_isExt),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow(io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask(io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_vpu_isOpMask(io_in_bits_ctrlPipe_1_vpu_isOpMask),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_1_src_4(io_in_bits_dataPipe_1_src_4),
    .io_in_bits_dataPipe_1_src_3(io_in_bits_dataPipe_1_src_3),
    .io_in_bits_dataPipe_1_src_2(io_in_bits_dataPipe_1_src_2),
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
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_res_vxsat(g_io_out_bits_res_vxsat),
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
    .io_vxrm(io_vxrm)
  );
  VIAluFix_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vma(io_in_bits_ctrl_vpu_vma),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrl_vpu_isExt(io_in_bits_ctrl_vpu_isExt),
    .io_in_bits_ctrl_vpu_isNarrow(io_in_bits_ctrl_vpu_isNarrow),
    .io_in_bits_ctrl_vpu_isDstMask(io_in_bits_ctrl_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_fuOpType(io_in_bits_ctrlPipe_1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest),
    .io_in_bits_ctrlPipe_1_vecWen(io_in_bits_ctrlPipe_1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen(io_in_bits_ctrlPipe_1_v0Wen),
    .io_in_bits_ctrlPipe_1_vpu_vma(io_in_bits_ctrlPipe_1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta(io_in_bits_ctrlPipe_1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew(io_in_bits_ctrlPipe_1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vm(io_in_bits_ctrlPipe_1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart(io_in_bits_ctrlPipe_1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx(io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_isExt(io_in_bits_ctrlPipe_1_vpu_isExt),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow(io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask(io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .io_in_bits_ctrlPipe_1_vpu_isOpMask(io_in_bits_ctrlPipe_1_vpu_isOpMask),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_1_src_4(io_in_bits_dataPipe_1_src_4),
    .io_in_bits_dataPipe_1_src_3(io_in_bits_dataPipe_1_src_3),
    .io_in_bits_dataPipe_1_src_2(io_in_bits_dataPipe_1_src_2),
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
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_res_vxsat(i_io_out_bits_res_vxsat),
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
    .io_vxrm(io_vxrm)
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
    if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin n++; if (verbose) $display("  MISMATCH io_out_bits_res_data g=%h i=%h", g_io_out_bits_res_data, i_io_out_bits_res_data); end
    if (g_io_out_bits_res_vxsat !== i_io_out_bits_res_vxsat) begin n++; if (verbose) $display("  MISMATCH io_out_bits_res_vxsat g=%h i=%h", g_io_out_bits_res_vxsat, i_io_out_bits_res_vxsat); end
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

  typedef struct {
    bit           valid, valid0, legal;
    logic [8:0]   fu;
    logic [1:0]   sew;
    logic [6:0]   uop;
    logic [7:0]   vl, vstart;
    bit           vm, vta, vma, isext, isnarrow, isdstmask, isopmask;
    logic [127:0] v0, old, vs1, vs2;
    bit           robf, vecwen, v0wen;
    logic [7:0]   robv, pdest;
    logic [1:0]   vxrm;
  } op_t;
  op_t pipe [0:1];

  // oracle 覆盖的同宽编码（VialuFixType 的合法 9 位 fuOpType：格式 2 位 + 有符号 1 位 + opcode 6 位）
  localparam int NVVV = 14;
  logic [8:0] VVV_OPS [NVVV] = '{9'h040, 9'h041, 9'h007, 9'h00B, 9'h00A, 9'h00F, 9'h010, 9'h051,
                                 9'h017, 9'h057, 9'h018, 9'h058, 9'h019, 9'h01A};

  function automatic logic [127:0] rand_vec();
    logic [127:0] v = {$urandom, $urandom, $urandom, $urandom};
    case ($urandom_range(0, 7))
      0: v = '0;
      1: v = '1;
      2: v = v & {$urandom, $urandom, $urandom, $urandom};
      3: v = {16{8'($urandom_range(0, 1) ? 8'h80 : 8'h7F)}} ^ (v & {16{8'h01}});
      default: ;
    endcase
    return v;
  endfunction

  function automatic op_t gen_op();
    op_t o;
    int n, vlmax, nreg, base, k;
    bit widen;
    o.valid  = ($urandom_range(0, 3) != 0);
    o.valid0 = ($urandom_range(0, 9) != 0) ? o.valid : $urandom;
    o.sew    = $urandom;
    o.isext = 0; o.isnarrow = 0; o.isdstmask = 0; o.isopmask = 0;
    k = $urandom_range(0, 9);
    if (k < 5) begin                                  // 同宽 oracle 编码
      o.fu = VVV_OPS[$urandom_range(0, NVVV - 1)];
    end else if (k < 7) begin                         // 加宽加减 .vv / .wv
      o.fu  = {$urandom_range(0, 1) ? 2'b01 : 2'b10, 1'($urandom), 6'($urandom_range(0, 1))};
      o.sew = $urandom_range(0, 2);
    end else if (k < 9) begin                         // 其余合法编码：比较 / 进位 / 定点 / 变窄 / vext / 掩码运算 / Zvbb
      case ($urandom_range(0, 7))
        0: begin o.fu = {2'b01, 1'($urandom), 6'($urandom_range(18, 22))}; o.isdstmask = 1; end   // vms*
        1: begin o.fu = {2'($urandom_range(1, 2)), 1'b0, $urandom_range(0, 1) ? 6'h04 : 6'h06}; o.isdstmask = 1; end // vmadc/vmsbc
        2: o.fu = {2'b00, 1'b0, $urandom_range(0, 1) ? 6'h03 : 6'h05};                          // vadc / vsbc
        3: o.fu = {2'b00, 1'($urandom), 6'($urandom_range(27, 32))};                             // 定点
        4: begin o.fu = {2'b11, 1'($urandom), $urandom_range(0, 1) ? 6'h10 : 6'h1F}; o.isnarrow = 1; o.sew = $urandom_range(0, 2); end
        5: begin o.fu = {2'($urandom_range(0, 2)), 1'($urandom), 6'h02}; o.isext = 1; o.sew = $urandom_range(1, 3); end
        6: begin o.fu = {2'b11, 1'b0, 6'($urandom_range(7, 14))}; o.isdstmask = 1; o.isopmask = 1; end
        default: o.fu = {$urandom_range(0, 1) ? 2'b10 : 2'b00, 1'b0, 6'($urandom_range(47, 55))};
      endcase
    end else begin
      o.fu = $urandom;
      o.isext = $urandom; o.isnarrow = $urandom; o.isdstmask = $urandom; o.isopmask = $urandom;
    end
    if (o.fu[5:0] == 6'h2E) o.fu[8:7] = 0;
    widen = (o.fu[8:7] == 2'b01 || o.fu[8:7] == 2'b10) && !o.isext && !o.isdstmask;
    o.vm = $urandom; o.vta = $urandom; o.vma = $urandom;
    // 合法配置：结果元素宽 = sew + 加宽；LMUL 1..4 / 分数；寄存器组 = ceil(VLMAX / 每寄存器结果元素数)
    n     = 128 >> (3 + o.sew + widen);
    k     = $urandom_range(0, 3) == 0 ? -$urandom_range(1, 3) : $urandom_range(0, widen ? 2 : 3);
    vlmax = (k >= 0) ? ((128 >> (3 + o.sew)) << k) : ((128 >> (3 + o.sew)) >> (-k));
    if (vlmax < 1) vlmax = 1;
    nreg  = (vlmax + n - 1) / n;
    o.uop = 7'($urandom_range(0, nreg - 1));
    base  = int'(o.uop) * n;
    o.vl  = ($urandom_range(0, 1)) ? 8'((base + $urandom_range(0, n) > vlmax) ? vlmax : base + $urandom_range(0, n))
                                   : 8'($urandom_range(0, vlmax));
    o.vstart = ($urandom_range(0, 9) < 7) ? 8'd0 : 8'($urandom_range(0, o.vl));
    o.legal = 1;
    if ($urandom_range(0, 7) == 0) begin o.uop = $urandom; o.vl = $urandom; o.vstart = $urandom; o.legal = 0; end
    o.v0  = rand_vec();
    if ($urandom_range(0, 3) == 0) o.v0 = '1;
    o.vs1 = rand_vec(); o.vs2 = rand_vec(); o.old = rand_vec();
    if ($urandom_range(0, 3) == 0) o.vs1 = o.vs2 ^ (128'($urandom) & {16{8'h03}});
    o.robf = $urandom; o.robv = $urandom; o.pdest = $urandom; o.vecwen = $urandom; o.v0wen = $urandom;
    o.vxrm = $urandom;
    return o;
  endfunction

  task automatic drive_ports();
    io_in_valid                    = pipe[0].valid;
    io_in_bits_ctrl_fuOpType       = pipe[0].fu;
    io_in_bits_ctrl_vpu_vma        = pipe[0].vma;
    io_in_bits_ctrl_vpu_vsew       = pipe[0].sew;
    io_in_bits_ctrl_vpu_vm         = pipe[0].vm;
    io_in_bits_ctrl_vpu_vuopIdx    = pipe[0].uop;
    io_in_bits_ctrl_vpu_isExt      = pipe[0].isext;
    io_in_bits_ctrl_vpu_isNarrow   = pipe[0].isnarrow;
    io_in_bits_ctrl_vpu_isDstMask  = pipe[0].isdstmask;
    io_in_bits_validPipe_0         = pipe[0].valid0;
    io_in_bits_data_src_3          = pipe[0].v0;
    io_in_bits_data_src_2          = pipe[0].old;
    io_in_bits_data_src_1          = pipe[0].vs2;
    io_in_bits_data_src_0          = pipe[0].vs1;
    io_vxrm                        = pipe[0].vxrm;
    io_in_bits_ctrlPipe_1_fuOpType       = pipe[1].fu;
    io_in_bits_ctrlPipe_1_robIdx_flag    = pipe[1].robf;
    io_in_bits_ctrlPipe_1_robIdx_value   = pipe[1].robv;
    io_in_bits_ctrlPipe_1_pdest          = pipe[1].pdest;
    io_in_bits_ctrlPipe_1_vecWen         = pipe[1].vecwen;
    io_in_bits_ctrlPipe_1_v0Wen          = pipe[1].v0wen;
    io_in_bits_ctrlPipe_1_vpu_vma        = pipe[1].vma;
    io_in_bits_ctrlPipe_1_vpu_vta        = pipe[1].vta;
    io_in_bits_ctrlPipe_1_vpu_vsew       = pipe[1].sew;
    io_in_bits_ctrlPipe_1_vpu_vm         = pipe[1].vm;
    io_in_bits_ctrlPipe_1_vpu_vstart     = pipe[1].vstart;
    io_in_bits_ctrlPipe_1_vpu_vuopIdx    = pipe[1].uop;
    io_in_bits_ctrlPipe_1_vpu_isExt      = pipe[1].isext;
    io_in_bits_ctrlPipe_1_vpu_isNarrow   = pipe[1].isnarrow;
    io_in_bits_ctrlPipe_1_vpu_isDstMask  = pipe[1].isdstmask;
    io_in_bits_ctrlPipe_1_vpu_isOpMask   = pipe[1].isopmask;
    io_in_bits_validPipe_1               = pipe[1].valid;
    io_in_bits_dataPipe_1_src_4          = pipe[1].vl;
    io_in_bits_dataPipe_1_src_3          = pipe[1].v0;
    io_in_bits_dataPipe_1_src_2          = pipe[1].old;
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
    io_out_ready = ($urandom_range(0, 7) != 0);
  endtask

  // ---------------------------------------------------------------------------
  // 按元素 oracle
  // ---------------------------------------------------------------------------
  int cov_vvv [96], cov_wvv = 0, cov_wwv = 0, cov_sew [4];
  int cov_masked = 0, cov_tail [2], cov_prestart = 0, cov_vge = 0;
  int cov_dstmask = 0, cov_narrow = 0, cov_ext = 0;

  function automatic bit oracle_ok(input op_t o);
    bit widen = (o.fu[8:7] == 2'b01 || o.fu[8:7] == 2'b10);
    if (!o.valid || !o.legal || o.isext || o.isnarrow || o.isdstmask) return 0;
    if (widen) return (o.fu[5:0] <= 6'h01) && (o.sew != 3);
    if (o.fu[8:7] != 0) return 0;
    foreach (VVV_OPS[k]) if (o.fu == VVV_OPS[k]) return 1;
    return 0;
  endfunction

  function automatic longint unsigned sext_w(input longint unsigned x, input int w);
    return (w == 64) ? x : ((x & ((64'd1 << (w - 1)))) ? (x | ~((64'd1 << w) - 1)) : x);
  endfunction

  task automatic shell_oracle(input op_t o, output logic [127:0] exp_vd);
    bit widen, wv, sgn;
    int w, ws, n, gi, sh;
    logic [63:0] em, ems, a, b, r, ov, ev;
    widen = (o.fu[8:7] == 2'b01 || o.fu[8:7] == 2'b10);
    wv    = (o.fu[8:7] == 2'b10);                       // .wv：vs2 已是 2·SEW
    sgn   = o.fu[6];
    ws    = 8 << o.sew;
    w     = widen ? 2 * ws : ws;
    n     = 128 / w;
    em    = (w == 64) ? '1 : ((64'd1 << w) - 1);
    ems   = (ws == 64) ? '1 : ((64'd1 << ws) - 1);
    exp_vd = '0;
    for (int i = 0; i < n; i++) begin
      if (widen) begin
        int si = int'(o.uop[0]) * n + i;                 // 源元素号
        b = 64'(o.vs1 >> (ws * si)) & ems;
        b = sgn ? (sext_w(b, ws) & em) : b;
        if (wv) a = 64'(o.vs2 >> (w * i)) & em;
        else begin a = 64'(o.vs2 >> (ws * si)) & ems; a = sgn ? (sext_w(a, ws) & em) : a; end
        r = (o.fu[0] ? (a - b) : (a + b)) & em;
      end else begin
        a  = 64'(o.vs2 >> (w * i)) & em;
        b  = 64'(o.vs1 >> (w * i)) & em;
        sh = int'(b & (w - 1));
        gi = int'(o.uop[2:0]) * n + i;
        case (o.fu[5:0])
          6'h00: r = (a + b) & em;
          6'h01: r = (a - b) & em;
          6'h07: r = a & b;
          6'h0B: r = a | b;
          6'h0A: r = a ^ b;
          6'h0F: r = (a << sh) & em;
          6'h10: r = a >> sh;
          6'h11: r = 64'($signed(sext_w(a, w)) >>> sh) & em;
          6'h17: r = (sgn ? ($signed(sext_w(a, w)) < $signed(sext_w(b, w))) : (a < b)) ? a : b;
          6'h18: r = (sgn ? ($signed(sext_w(a, w)) > $signed(sext_w(b, w))) : (a > b)) ? a : b;
          6'h19: r = (o.vm || o.v0[gi]) ? b : a;           // vmerge：v0 选 vs1，否则 vs2
          default: r = b;                                  // vmv.v.v
        endcase
      end
      // Mgu
      gi = int'(o.uop[2:0]) * n + i;
      ov = 64'(o.old >> (w * i)) & em;
      if (o.vstart >= o.vl) begin ev = ov; cov_vge++; end
      else if (gi < int'(o.vstart)) begin ev = ov; cov_prestart++; end
      else if (gi >= int'(o.vl)) begin ev = o.vta ? em : ov; cov_tail[o.vta]++; end
      else if (o.fu[5:0] == 6'h19 || o.vm || o.v0[gi]) ev = r;
      else begin ev = o.vma ? em : ov; cov_masked++; end
      exp_vd |= 128'(ev) << (w * i);
    end
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  logic [127:0] seen0_vd = '0, seen1_vd = '0;
  bit seen0_sat = 0, seen1_sat = 0;
  int first_valid = -1;

  initial begin
    int bad, nd;
    logic [127:0] ev;
    op_t o1;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int k = 0; k < 2; k++) begin pipe[k] = gen_op(); pipe[k].valid = 0; end
    reset = 1;
    drive_ports();
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      pipe[1] = pipe[0];
      pipe[0] = gen_op();
      drive_ports();
      if (first_valid < 0 && pipe[0].valid) first_valid = cyc;
      #1;
      checks++;
      nd = int'(g_io_in_ready !== i_io_in_ready) + int'(g_io_out_valid !== i_io_out_valid);
      if (first_valid >= 0 && cyc >= first_valid + 1) nd = diff_outputs(0);
      if (nd > 0) begin
        errors++;
        if (errors <= 20) begin $display("[%0d] MISMATCH fu=%h", cyc, pipe[1].fu); void'(diff_outputs(1)); end
      end
      o1 = pipe[1];
      if (first_valid >= 0 && cyc >= first_valid + 1) begin
        seen1_vd |= g_io_out_bits_res_data; seen0_vd |= ~g_io_out_bits_res_data;
        if (g_io_out_bits_res_vxsat) seen1_sat = 1; else seen0_sat = 1;
        if (o1.valid && o1.isdstmask) cov_dstmask++;
        if (o1.valid && o1.isnarrow) cov_narrow++;
        if (o1.valid && o1.isext) cov_ext++;
      end
      if (oracle_ok(o1) && g_io_out_valid) begin
        shell_oracle(o1, ev);
        oracle_checks++;
        if (o1.fu[8:7] == 2'b01) cov_wvv++;
        else if (o1.fu[8:7] == 2'b10) cov_wwv++;
        else cov_vvv[o1.fu[5:0] + (o1.fu[6] ? 32 : 0)]++;
        cov_sew[o1.sew]++;
        if (i_io_out_bits_res_data !== ev || i_io_out_bits_res_vxsat !== 1'b0) begin
          oracle_err++;
          if (oracle_err <= 30)
            $display("[%0d] ORACLE fu=%h sew=%0d uop=%0d vl=%0d vstart=%0d vm=%0d ta=%0d ma=%0d\n   vs2=%h vs1=%h old=%h v0=%h\n   exp vd=%h\n   got vd=%h sat=%0d",
                     cyc, o1.fu, o1.sew, o1.uop, o1.vl, o1.vstart, o1.vm, o1.vta, o1.vma, o1.vs2, o1.vs1, o1.old, o1.v0,
                     ev, i_io_out_bits_res_data, i_io_out_bits_res_vxsat);
        end
      end
    end
    bad = 0;
    if (oracle_checks < 30000) bad++;
    foreach (VVV_OPS[k]) if (cov_vvv[VVV_OPS[k][5:0] + (VVV_OPS[k][6] ? 32 : 0)] < 500) begin
      bad++; $display("COV FAIL op %h = %0d", VVV_OPS[k], cov_vvv[VVV_OPS[k][5:0] + (VVV_OPS[k][6] ? 32 : 0)]);
    end
    if (cov_wvv < 1000 || cov_wwv < 1000) begin bad++; $display("COV FAIL widen vv/wv = %0d/%0d", cov_wvv, cov_wwv); end
    for (int s = 0; s < 4; s++) if (cov_sew[s] < 3000) begin bad++; $display("COV FAIL sew%0d=%0d", s, cov_sew[s]); end
    if (cov_masked < 100 || cov_tail[0] < 100 || cov_tail[1] < 100 || cov_prestart < 100 || cov_vge < 100) bad++;
    if (cov_dstmask < 3000 || cov_narrow < 3000 || cov_ext < 3000) begin bad++; $display("COV FAIL dstmask/narrow/ext=%0d/%0d/%0d", cov_dstmask, cov_narrow, cov_ext); end
    if (seen0_vd !== '1 || seen1_vd !== '1 || !seen0_sat || !seen1_sat) begin bad++; $display("COV FAIL toggle vd 0=%h 1=%h sat %0d%0d", seen0_vd, seen1_vd, seen0_sat, seen1_sat); end
    $display("COVERAGE oracle=%0d widen vv/wv=%0d/%0d sew0..3=%0d/%0d/%0d/%0d masked=%0d tail ta0/1=%0d/%0d prestart=%0d vstart>=vl=%0d dstmask/narrow/ext=%0d/%0d/%0d",
             oracle_checks, cov_wvv, cov_wwv, cov_sew[0], cov_sew[1], cov_sew[2], cov_sew[3], cov_masked, cov_tail[0], cov_tail[1],
             cov_prestart, cov_vge, cov_dstmask, cov_narrow, cov_ext);
    $display("ORACLE oracle_errors=%0d", oracle_err);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_err == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
