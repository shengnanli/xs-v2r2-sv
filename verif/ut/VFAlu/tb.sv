// =============================================================================
// tb —— VFAlu UT：golden VFAlu（含 golden 子树）与重写件 VFAlu_xs（子树全是重写件：VectorFloatAdder ×2（含其全部 lane）、
// VecDataSplitModule ×2、Mgu、Mgtu，以及共享辅助件 xs_VecFflagsElemMask）双例化，同时钟同激励逐拍比全部输出。
//
// 激励：每拍造一个 uop（op_t）；第 0 级端口（ctrl、ctrlPipe_0、data_src_*、dataPipe_0_src_4）取本拍的 uop，第 1 级端口
//   （ctrlPipe_1 / dataPipe_1 / validPipe_1）取上一拍的 uop。fuOpType：一半取 oracle 覆盖的元素运算（vfadd / vfsub / vfmin / vfmax /
//   vfmerge，以及加宽 vfwadd/vfwsub 的 .vv / .wv），其余散到归约（vfredusum / max / min / osum / vfwredosum，随机折叠标志与
//   lastUop）、比较（dstMask）、vfmv.f.s / vfmv.s.f、sgnj / fclass 与随机编码；七成以上合法 RVV 配置；操作数按 SEW 逐元素造
//   （特殊值 / 同量级 / 上溢 / 非规格数）。in_valid 3/4、out_ready 7/8。
// 差分比较：in_ready / out_valid 每拍比；其余输出在第一次 in_valid 之后 1 拍起每拍比。
// 独立按元素 oracle（tb 内整数算术，元素级 IEEE 加法 / min / max 照抄 verif/ut/VectorFloatAdder 的 oracle），对第 1 级上合法、
//   有效、在第 0 级真正握手（in.fire；被反压时第 0 级寄存器不更新，golden 行为，只做差分）、非归约、非比较的 vfadd / vfsub / vfmin / vfmax / vfmerge / 加宽加减 uop：
//   - 元素 i 的结果按 RVV 语义（加宽源元素 = vuopIdx[0]·(128/结果SEW) + i；.wv 的 a 取 vs2 的结果格式元素）；
//   - 写回：vl = 0 → 整个 vd 保持旧值、fflags 0；否则 Mgu：vstart >= vl 整个保持；< vstart 旧值；>= vl → vta ? 全 1 : 旧值；
//     掩码关（vfmerge 例外）→ vma ? 全 1 : 旧值；
//   - fflags：元素 i 计入当且仅当 i < 本 uop 元素上限（分数 LMUL 按加宽修正 vlmul 收窄）、uop·上限 + i < vl、掩码位为 1。
// 覆盖（写进 PASS 判据）：oracle 比对 >= 20000（加减 / minmax / merge / 加宽 .vv / .wv 各 >= 1000，3 种结果 SEW 各 >= 3000）；
//   掩码关 / 尾部（ta 0/1）/ vstart 前部 / vstart>=vl / vl=0 各 >= 100；归约 5 种 × {折叠, 不折叠} 与比较类、vfmv 两种的差分拍
//   各 >= 300；res_data / res_fflags 每位都见过 0 和 1（DZ / UF 位加法不产生，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
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
  logic [1:0]     io_in_bits_ctrl_vpu_vsew;
  logic [2:0]     io_in_bits_ctrl_vpu_vlmul;
  logic           io_in_bits_ctrl_vpu_vm;
  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_2;
  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_4;
  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_8;
  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx;
  logic [8:0]     io_in_bits_ctrlPipe_0_fuOpType;
  logic [1:0]     io_in_bits_ctrlPipe_0_vpu_vsew;
  logic [2:0]     io_in_bits_ctrlPipe_0_vpu_vlmul;
  logic [6:0]     io_in_bits_ctrlPipe_0_vpu_vuopIdx;
  logic [8:0]     io_in_bits_ctrlPipe_1_fuOpType;
  logic           io_in_bits_ctrlPipe_1_robIdx_flag;
  logic [7:0]     io_in_bits_ctrlPipe_1_robIdx_value;
  logic [7:0]     io_in_bits_ctrlPipe_1_pdest;
  logic           io_in_bits_ctrlPipe_1_fpWen;
  logic           io_in_bits_ctrlPipe_1_vecWen;
  logic           io_in_bits_ctrlPipe_1_v0Wen;
  logic           io_in_bits_ctrlPipe_1_fpu_wflags;
  logic           io_in_bits_ctrlPipe_1_vpu_vma;
  logic           io_in_bits_ctrlPipe_1_vpu_vta;
  logic [1:0]     io_in_bits_ctrlPipe_1_vpu_vsew;
  logic [2:0]     io_in_bits_ctrlPipe_1_vpu_vlmul;
  logic           io_in_bits_ctrlPipe_1_vpu_vm;
  logic [7:0]     io_in_bits_ctrlPipe_1_vpu_vstart;
  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2;
  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4;
  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8;
  logic [6:0]     io_in_bits_ctrlPipe_1_vpu_vuopIdx;
  logic           io_in_bits_ctrlPipe_1_vpu_lastUop;
  logic           io_in_bits_ctrlPipe_1_vpu_isNarrow;
  logic           io_in_bits_ctrlPipe_1_vpu_isDstMask;
  logic           io_in_bits_validPipe_1;
  logic [7:0]     io_in_bits_data_src_4;
  logic [127:0]   io_in_bits_data_src_3;
  logic [127:0]   io_in_bits_data_src_1;
  logic [127:0]   io_in_bits_data_src_0;
  logic [7:0]     io_in_bits_dataPipe_0_src_4;
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
  logic           g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen;
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
  VFAlu u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_2(io_in_bits_ctrl_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_4(io_in_bits_ctrl_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_8(io_in_bits_ctrl_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_0_fuOpType(io_in_bits_ctrlPipe_0_fuOpType),
    .io_in_bits_ctrlPipe_0_vpu_vsew(io_in_bits_ctrlPipe_0_vpu_vsew),
    .io_in_bits_ctrlPipe_0_vpu_vlmul(io_in_bits_ctrlPipe_0_vpu_vlmul),
    .io_in_bits_ctrlPipe_0_vpu_vuopIdx(io_in_bits_ctrlPipe_0_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_fuOpType(io_in_bits_ctrlPipe_1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest),
    .io_in_bits_ctrlPipe_1_fpWen(io_in_bits_ctrlPipe_1_fpWen),
    .io_in_bits_ctrlPipe_1_vecWen(io_in_bits_ctrlPipe_1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen(io_in_bits_ctrlPipe_1_v0Wen),
    .io_in_bits_ctrlPipe_1_fpu_wflags(io_in_bits_ctrlPipe_1_fpu_wflags),
    .io_in_bits_ctrlPipe_1_vpu_vma(io_in_bits_ctrlPipe_1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta(io_in_bits_ctrlPipe_1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew(io_in_bits_ctrlPipe_1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vlmul(io_in_bits_ctrlPipe_1_vpu_vlmul),
    .io_in_bits_ctrlPipe_1_vpu_vm(io_in_bits_ctrlPipe_1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart(io_in_bits_ctrlPipe_1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx(io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_lastUop(io_in_bits_ctrlPipe_1_vpu_lastUop),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow(io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask(io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_0_src_4(io_in_bits_dataPipe_0_src_4),
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
    .io_out_bits_ctrl_fpWen(g_io_out_bits_ctrl_fpWen),
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
  VFAlu_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vlmul(io_in_bits_ctrl_vpu_vlmul),
    .io_in_bits_ctrl_vpu_vm(io_in_bits_ctrl_vpu_vm),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_2(io_in_bits_ctrl_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_4(io_in_bits_ctrl_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrl_vpu_fpu_isFoldTo1_8(io_in_bits_ctrl_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_0_fuOpType(io_in_bits_ctrlPipe_0_fuOpType),
    .io_in_bits_ctrlPipe_0_vpu_vsew(io_in_bits_ctrlPipe_0_vpu_vsew),
    .io_in_bits_ctrlPipe_0_vpu_vlmul(io_in_bits_ctrlPipe_0_vpu_vlmul),
    .io_in_bits_ctrlPipe_0_vpu_vuopIdx(io_in_bits_ctrlPipe_0_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_fuOpType(io_in_bits_ctrlPipe_1_fuOpType),
    .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest),
    .io_in_bits_ctrlPipe_1_fpWen(io_in_bits_ctrlPipe_1_fpWen),
    .io_in_bits_ctrlPipe_1_vecWen(io_in_bits_ctrlPipe_1_vecWen),
    .io_in_bits_ctrlPipe_1_v0Wen(io_in_bits_ctrlPipe_1_v0Wen),
    .io_in_bits_ctrlPipe_1_fpu_wflags(io_in_bits_ctrlPipe_1_fpu_wflags),
    .io_in_bits_ctrlPipe_1_vpu_vma(io_in_bits_ctrlPipe_1_vpu_vma),
    .io_in_bits_ctrlPipe_1_vpu_vta(io_in_bits_ctrlPipe_1_vpu_vta),
    .io_in_bits_ctrlPipe_1_vpu_vsew(io_in_bits_ctrlPipe_1_vpu_vsew),
    .io_in_bits_ctrlPipe_1_vpu_vlmul(io_in_bits_ctrlPipe_1_vpu_vlmul),
    .io_in_bits_ctrlPipe_1_vpu_vm(io_in_bits_ctrlPipe_1_vpu_vm),
    .io_in_bits_ctrlPipe_1_vpu_vstart(io_in_bits_ctrlPipe_1_vpu_vstart),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4),
    .io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8(io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8),
    .io_in_bits_ctrlPipe_1_vpu_vuopIdx(io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_1_vpu_lastUop(io_in_bits_ctrlPipe_1_vpu_lastUop),
    .io_in_bits_ctrlPipe_1_vpu_isNarrow(io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .io_in_bits_ctrlPipe_1_vpu_isDstMask(io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_3(io_in_bits_data_src_3),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_0_src_4(io_in_bits_dataPipe_0_src_4),
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
    .io_out_bits_ctrl_fpWen(i_io_out_bits_ctrl_fpWen),
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
    if (g_io_out_bits_ctrl_fpWen !== i_io_out_bits_ctrl_fpWen) begin n++; if (verbose) $display("  MISMATCH io_out_bits_ctrl_fpWen g=%h i=%h", g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen); end
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

  typedef struct {
    bit           valid, legal, fired;
    logic [8:0]   fu;
    logic [1:0]   sew;
    logic [2:0]   vlmul, fold, rm;
    logic [6:0]   uop;
    logic [7:0]   vl, vstart;
    bit           vm, vta, vma, last, narrow, dstmask;
    logic [127:0] v0, old, vs1, vs2;
    bit           robf, fpwen, vecwen, v0wen, wflags;
    logic [7:0]   robv, pdest;
  } op_t;
  op_t pipe [0:1];

  // ---- 按格式的元素工具（f: 1=f16 2=f32 3=f64；元素右对齐放在 64 位里）----
  function automatic int EW(input logic [1:0] f); return (f == 1) ? 5 : (f == 2) ? 8 : 11; endfunction
  function automatic int MW(input logic [1:0] f); return (f == 1) ? 10 : (f == 2) ? 23 : 52; endfunction
  function automatic int SEW(input logic [1:0] f); return (f == 1) ? 16 : (f == 2) ? 32 : 64; endfunction
  function automatic longint unsigned emax(input logic [1:0] f); return (64'd1 << EW(f)) - 1; endfunction
  function automatic longint unsigned e_of(input logic [63:0] x, input logic [1:0] f); return (x >> MW(f)) & emax(f); endfunction
  function automatic longint unsigned m_of(input logic [63:0] x, input logic [1:0] f); return x & ((64'd1 << MW(f)) - 1); endfunction
  function automatic bit s_of(input logic [63:0] x, input logic [1:0] f); return x[EW(f) + MW(f)]; endfunction
  function automatic bit f_nan (input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == emax(f) && m_of(x, f) != 0; endfunction
  function automatic bit f_snan(input logic [63:0] x, input logic [1:0] f); return f_nan(x, f) && !x[MW(f) - 1]; endfunction
  function automatic bit f_inf (input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == emax(f) && m_of(x, f) == 0; endfunction
  function automatic bit f_zero(input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == 0 && m_of(x, f) == 0; endfunction
  function automatic logic [63:0] qnan(input logic [1:0] f); return (emax(f) << MW(f)) | (64'd1 << (MW(f) - 1)); endfunction
  function automatic logic [63:0] mag(input logic [63:0] x, input logic [1:0] f); return x & ((64'd1 << (EW(f) + MW(f))) - 1); endfunction
  function automatic bit f_lt(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f);
    if (f_zero(a, f) && f_zero(b, f)) return 0;
    if (s_of(a, f) != s_of(b, f)) return s_of(a, f);
    if (!s_of(a, f)) return mag(a, f) < mag(b, f);
    return mag(a, f) > mag(b, f);
  endfunction
  function automatic bit f_eq(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f);
    if (f_zero(a, f) && f_zero(b, f)) return 1;
    return a == b;
  endfunction
  function automatic logic [63:0] f_minmax(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f, input bit want_max);
    if (f_nan(a, f) && f_nan(b, f)) return qnan(f);
    if (f_nan(a, f)) return b;
    if (f_nan(b, f)) return a;
    if (f_zero(a, f) && f_zero(b, f)) return want_max ? (s_of(a, f) ? b : a) : (s_of(a, f) ? a : b);
    if (want_max) return f_lt(a, b, f) ? b : a;
    return f_lt(b, a, f) ? b : a;
  endfunction
  // 精确加宽：f（1/2）格式的 x → 下一档格式（2/3）
  function automatic logic [63:0] widen_exact(input logic [63:0] x, input logic [1:0] f);
    logic [1:0] t = f + 1;
    longint unsigned e = e_of(x, f), m = m_of(x, f);
    int bias_s = (1 << (EW(f) - 1)) - 1, bias_t = (1 << (EW(t) - 1)) - 1;
    int ee;
    bit s = s_of(x, f);
    if (e == emax(f)) return (64'(s) << (EW(t) + MW(t))) | (emax(t) << MW(t)) | (m << (MW(t) - MW(f)));
    if (e == 0 && m == 0) return 64'(s) << (EW(t) + MW(t));
    ee = (e == 0) ? 1 : int'(e);
    if (e == 0) while (m[MW(f)] == 0) begin m = m << 1; ee--; end    // 非规格数规格化
    m = m & ((64'd1 << MW(f)) - 1);
    return (64'(s) << (EW(t) + MW(t))) | (64'(ee - bias_s + bias_t) << MW(t)) | (m << (MW(t) - MW(f)));
  endfunction
  // 一个元素的 IEEE 加法：返回 {结果, fflags}
  task automatic elem_add(input logic [63:0] a, input logic [63:0] b, input bit sub, input logic [2:0] r,
                          input logic [1:0] f, output logic [63:0] res, output logic [4:0] fl);
    logic [63:0] bb;
    fp_res_t x;
    bit nv;
    bb = b ^ (64'(sub) << (EW(f) + MW(f)));
    fl = 0;
    if (f_nan(a, f) || f_nan(b, f) || (f_inf(a, f) && f_inf(bb, f) && s_of(a, f) != s_of(bb, f))) begin
      res = qnan(f);
      nv  = f_snan(a, f) || f_snan(b, f) || (f_inf(a, f) && f_inf(bb, f) && s_of(a, f) != s_of(bb, f));
      fl  = {nv, 4'b0};
    end else if (f_inf(a, f) || f_inf(bb, f)) begin
      res = f_inf(a, f) ? a : bb;
    end else begin
      x   = exact_add(MW(f) + 1, EW(f), s_of(a, f), 11'(e_of(a, f)), 52'(m_of(a, f)),
                      s_of(bb, f), 11'(e_of(bb, f)), 52'(m_of(bb, f)), r);
      res = x.bits;
      fl  = {2'b0, x.of, 1'b0, x.nx};
    end
  endtask

  function automatic logic [127:0] pack_elems(input logic [1:0] f, input logic [127:0] ref_v);
    int w = SEW(f), n = 128 / w;
    logic [127:0] r = '0;
    for (int k = 0; k < n; k++) r |= 128'(pick_elem(f, 64'(ref_v >> (w * k)))) << (w * k);
    return r;
  endfunction
  function automatic logic [63:0] pick_elem(input logic [1:0] f, input logic [63:0] near);
    longint unsigned e, m, em = emax(f);
    bit s = $urandom;
    m = {$urandom, $urandom} & ((64'd1 << MW(f)) - 1);
    case ($urandom_range(0, 15))
      0: begin e = 0; m = 0; end
      1: begin e = em; m = 0; end
      2: begin e = em; m = m | (64'd1 << (MW(f) - 1)); end
      3: begin e = em; m = m & ~(64'd1 << (MW(f) - 1)); if (m == 0) m = 1; end
      4: e = 0;
      5: e = em - 1;
      6, 7, 8, 9: begin
        e = e_of(near, f) + $urandom_range(0, 2) - 1;
        if (e >= em) e = em - 1;
        if ($urandom_range(0, 1)) m = m_of(near, f) ^ ($urandom_range(0, 7));
        s = $urandom_range(0, 1) ? s_of(near, f) : s;
      end
      default: e = $urandom_range(0, em - 1);
    endcase
    return (64'(s) << (EW(f) + MW(f))) | (64'(e) << MW(f)) | 64'(m);
  endfunction

  localparam int NOPS = 5;
  logic [4:0] ELEM_OPS [NOPS] = '{5'h00, 5'h01, 5'h02, 5'h03, 5'h04};
  logic [8:0] RED_OPS [5] = '{9'h01A, 9'h015, 9'h014, 9'h016, 9'h036};

  function automatic op_t gen_op();
    op_t o;
    int n, vlmax, nreg, base, k, lmul_sh;
    bit widen;
    o.valid = ($urandom_range(0, 3) != 0);
    o.fold = 0; o.narrow = 0; o.dstmask = 0;
    o.last = $urandom;
    o.sew  = $urandom_range(1, 3);
    k = $urandom_range(0, 9);
    if (k < 4)       o.fu = {4'b0000, ELEM_OPS[$urandom_range(0, NOPS - 1)]};
    else if (k < 6) begin                                           // 加宽加减 .vv / .wv
      o.fu  = {2'b00, 1'($urandom), 1'b1, 5'($urandom_range(0, 1))};
      o.sew = $urandom_range(1, 2);
    end else if (k < 8) begin                                       // 归约
      o.fu = RED_OPS[$urandom_range(0, 4)];
      if ($urandom_range(0, 1)) o.fold = 3'(1) << $urandom_range(0, 2);
      if (o.fu == 9'h036) o.sew = $urandom_range(1, 2);
    end else if (k < 9) begin                                       // 比较（结果是掩码）
      o.fu = {4'b0000, 5'($urandom_range(9, 14))};
      o.dstmask = 1;
    end else begin
      case ($urandom_range(0, 3))
        0: o.fu = 9'h011;
        1: o.fu = 9'h012;
        2: o.fu = {4'b0000, 5'($urandom_range(5, 15))};
        default: begin o.fu = $urandom; o.fold = $urandom; o.narrow = $urandom; o.dstmask = $urandom; end
      endcase
    end
    if ($urandom_range(0, 31) == 0) o.sew = 0;
    widen   = o.fu[5];
    o.vlmul = ($urandom_range(0, 3) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, widen ? 2 : 3));
    o.rm    = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    o.vm = $urandom; o.vta = $urandom; o.vma = $urandom;
    n       = 128 >> (3 + o.sew + widen);
    lmul_sh = o.vlmul[2] ? -(4 - int'(o.vlmul[1:0])) : int'(o.vlmul[1:0]);
    vlmax   = (lmul_sh >= 0) ? ((128 >> (3 + o.sew)) << lmul_sh) : ((128 >> (3 + o.sew)) >> (-lmul_sh));
    if (vlmax < 1) vlmax = 1;
    nreg    = (vlmax + n - 1) / n;
    o.uop   = 7'($urandom_range(0, nreg - 1));
    if (o.fu inside {9'h01A, 9'h015, 9'h014, 9'h016, 9'h036}) o.uop = $urandom_range(0, 10);
    base    = int'(o.uop) * n;
    case ($urandom_range(0, 7))
      0:       o.vl = 0;
      1, 2, 3: o.vl = 8'((base + $urandom_range(0, n) > vlmax) ? vlmax : base + $urandom_range(0, n));
      default: o.vl = 8'($urandom_range(0, vlmax));
    endcase
    o.vstart = ($urandom_range(0, 9) < 7) ? 8'd0 : 8'($urandom_range(0, o.vl));
    o.legal = 1;
    if ($urandom_range(0, 7) == 0) begin o.vlmul = $urandom; o.uop = $urandom; o.vl = $urandom; o.vstart = $urandom; o.legal = 0; end
    o.v0  = {$urandom, $urandom, $urandom, $urandom};
    if ($urandom_range(0, 3) == 0) o.v0 = '1;
    if ($urandom_range(0, 7) == 0) o.v0 = '0;
    if (o.sew == 0) begin
      o.vs2 = {$urandom, $urandom, $urandom, $urandom}; o.vs1 = {$urandom, $urandom, $urandom, $urandom};
      o.old = {$urandom, $urandom, $urandom, $urandom};
    end else begin
      o.vs2 = pack_elems(widen && o.fu[6] ? o.sew + 1 : o.sew, {$urandom, $urandom, $urandom, $urandom});
      o.vs1 = pack_elems(o.sew, o.vs2);
      o.old = pack_elems(o.sew + widen, {$urandom, $urandom, $urandom, $urandom});
    end
    o.robf = $urandom; o.robv = $urandom; o.pdest = $urandom; o.fpwen = $urandom; o.vecwen = $urandom;
    o.v0wen = $urandom; o.wflags = $urandom;
    return o;
  endfunction

  task automatic drive_ports();
    io_in_valid                          = pipe[0].valid;
    io_in_bits_ctrl_fuOpType             = pipe[0].fu;
    io_in_bits_ctrl_vpu_vsew             = pipe[0].sew;
    io_in_bits_ctrl_vpu_vlmul            = pipe[0].vlmul;
    io_in_bits_ctrl_vpu_vm               = pipe[0].vm;
    io_in_bits_ctrl_vpu_fpu_isFoldTo1_2  = pipe[0].fold[0];
    io_in_bits_ctrl_vpu_fpu_isFoldTo1_4  = pipe[0].fold[1];
    io_in_bits_ctrl_vpu_fpu_isFoldTo1_8  = pipe[0].fold[2];
    io_in_bits_ctrl_vpu_vuopIdx          = pipe[0].uop;
    io_in_bits_ctrlPipe_0_fuOpType       = pipe[0].fu;
    io_in_bits_ctrlPipe_0_vpu_vsew       = pipe[0].sew;
    io_in_bits_ctrlPipe_0_vpu_vlmul      = pipe[0].vlmul;
    io_in_bits_ctrlPipe_0_vpu_vuopIdx    = pipe[0].uop;
    io_in_bits_data_src_4                = pipe[0].vl;
    io_in_bits_data_src_3                = pipe[0].v0;
    io_in_bits_data_src_1                = pipe[0].vs2;
    io_in_bits_data_src_0                = pipe[0].vs1;
    io_in_bits_dataPipe_0_src_4          = pipe[0].vl;
    io_frm                               = pipe[0].rm;
    io_in_bits_ctrlPipe_1_fuOpType            = pipe[1].fu;
    io_in_bits_ctrlPipe_1_robIdx_flag         = pipe[1].robf;
    io_in_bits_ctrlPipe_1_robIdx_value        = pipe[1].robv;
    io_in_bits_ctrlPipe_1_pdest               = pipe[1].pdest;
    io_in_bits_ctrlPipe_1_fpWen               = pipe[1].fpwen;
    io_in_bits_ctrlPipe_1_vecWen              = pipe[1].vecwen;
    io_in_bits_ctrlPipe_1_v0Wen               = pipe[1].v0wen;
    io_in_bits_ctrlPipe_1_fpu_wflags          = pipe[1].wflags;
    io_in_bits_ctrlPipe_1_vpu_vma             = pipe[1].vma;
    io_in_bits_ctrlPipe_1_vpu_vta             = pipe[1].vta;
    io_in_bits_ctrlPipe_1_vpu_vsew            = pipe[1].sew;
    io_in_bits_ctrlPipe_1_vpu_vlmul           = pipe[1].vlmul;
    io_in_bits_ctrlPipe_1_vpu_vm              = pipe[1].vm;
    io_in_bits_ctrlPipe_1_vpu_vstart          = pipe[1].vstart;
    io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2 = pipe[1].fold[0];
    io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4 = pipe[1].fold[1];
    io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8 = pipe[1].fold[2];
    io_in_bits_ctrlPipe_1_vpu_vuopIdx         = pipe[1].uop;
    io_in_bits_ctrlPipe_1_vpu_lastUop         = pipe[1].last;
    io_in_bits_ctrlPipe_1_vpu_isNarrow        = pipe[1].narrow;
    io_in_bits_ctrlPipe_1_vpu_isDstMask       = pipe[1].dstmask;
    io_in_bits_validPipe_1                    = pipe[1].valid;
    io_in_bits_dataPipe_1_src_4               = pipe[1].vl;
    io_in_bits_dataPipe_1_src_3               = pipe[1].v0;
    io_in_bits_dataPipe_1_src_2               = pipe[1].old;
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
  int cov_op [5], cov_wvv = 0, cov_wwv = 0, cov_sew [4];
  int cov_masked = 0, cov_tail [2], cov_prestart = 0, cov_vge = 0, cov_vl0 = 0;
  int cov_red [5][2], cov_cmp = 0, cov_fmv [2];

  function automatic bit oracle_ok(input op_t o);
    if (!o.valid || !o.fired || !o.legal || o.narrow || o.dstmask || o.fold != 0 || o.sew == 0 || o.rm > 3'd4) return 0;
    if (o.fu[8:7] != 0) return 0;
    if (o.fu[5]) return (o.fu[4:0] <= 5'h01) && (o.sew != 3);
    if (o.fu[6]) return 0;
    return o.fu[4:0] <= 5'h04;
  endfunction

  task automatic shell_oracle(input op_t o, output logic [127:0] exp_vd, output logic [4:0] exp_ff);
    bit widen, wv, mbit;
    logic [1:0] rf, sf;
    int w, ws, n, gi, n_this, sh, vlmax_i;
    logic [63:0] em, ems, a, b, r, ov, ev;
    logic [4:0]  fl;
    logic [2:0]  vfix;
    widen = o.fu[5];
    wv    = o.fu[6];
    sf    = o.sew;
    rf    = o.sew + widen;
    w     = SEW(rf);
    ws    = SEW(sf);
    n     = 128 / w;
    em    = (w == 64) ? '1 : ((64'd1 << w) - 1);
    ems   = (ws == 64) ? '1 : ((64'd1 << ws) - 1);
    vfix  = widen ? 3'(o.vlmul + 3'd1) : o.vlmul;
    vlmax_i = 16 >> rf;
    sh     = vfix[2] ? int'(2'(~vfix[1:0] + 2'd1)) : int'(vfix[1:0]);
    n_this = o.vlmul[2] ? (vlmax_i >> sh) : vlmax_i;
    exp_vd = '0;
    exp_ff = '0;
    if (o.vl == 0) begin exp_vd = o.old; cov_vl0++; return; end
    for (int i = 0; i < n; i++) begin
      gi   = int'(o.uop[2:0]) * n + i;
      mbit = o.vm ? 1'b1 : o.v0[gi];
      if (widen) begin
        int si = int'(o.uop[0]) * n + i;
        b = widen_exact(64'(o.vs1 >> (ws * si)) & ems, sf);
        a = wv ? (64'(o.vs2 >> (w * i)) & em) : widen_exact(64'(o.vs2 >> (ws * si)) & ems, sf);
      end else begin
        a = 64'(o.vs2 >> (w * i)) & em;
        b = 64'(o.vs1 >> (w * i)) & em;
      end
      fl = 0;
      case (o.fu[4:0])
        5'h00, 5'h01: elem_add(a, b, o.fu[0], o.rm, rf, r, fl);
        5'h02, 5'h03: begin r = f_minmax(a, b, rf, o.fu[0]); fl = {f_snan(a, rf) || f_snan(b, rf), 4'b0}; end
        default:      r = mbit ? b : a;                     // vfmerge：v0 选 vs1，否则 vs2
      endcase
      ov = 64'(o.old >> (w * i)) & em;
      if (o.vstart >= o.vl) begin ev = ov; cov_vge++; end
      else if (gi < int'(o.vstart)) begin ev = ov; cov_prestart++; end
      else if (gi >= int'(o.vl)) begin ev = o.vta ? em : ov; cov_tail[o.vta]++; end
      else if (o.fu[4:0] == 5'h04 || mbit) ev = r & em;
      else begin ev = o.vma ? em : ov; cov_masked++; end
      exp_vd |= 128'(ev) << (w * i);
      if (i < n_this && int'(o.uop[2:0]) * n_this + i < int'(o.vl) &&
          (o.fu[4:0] == 5'h04 || o.vm || o.v0[int'(o.uop[2:0]) * vlmax_i + i]))
        exp_ff |= fl;
    end
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  logic [127:0] seen0_vd = '0, seen1_vd = '0;
  logic [4:0]   seen0_ff = '0, seen1_ff = '0;
  int first_valid = -1;

  initial begin
    int bad, nd;
    logic [127:0] ev; logic [4:0] ef;
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
      pipe[0].fired = pipe[0].valid & g_io_in_ready;     // 第 0 级寄存器（outVlFix / eew / vdIdx …）只在 in.fire 时更新
      checks++;
      nd = int'(g_io_in_ready !== i_io_in_ready) + int'(g_io_out_valid !== i_io_out_valid);
      if (first_valid >= 0 && cyc >= first_valid + 1) nd = diff_outputs(0);
      if (nd > 0) begin
        errors++;
        if (errors <= 20) begin $display("[%0d] MISMATCH fu=%h", cyc, pipe[1].fu); void'(diff_outputs(1)); end
      end
      o1 = pipe[1];
      if (first_valid >= 0 && cyc >= first_valid + 1) begin
        seen1_vd |= g_io_out_bits_res_data;   seen0_vd |= ~g_io_out_bits_res_data;
        seen1_ff |= g_io_out_bits_res_fflags; seen0_ff |= ~g_io_out_bits_res_fflags;
        if (o1.valid) begin
          foreach (RED_OPS[k]) if (o1.fu == RED_OPS[k]) cov_red[k][o1.fold != 0]++;
          if (o1.dstmask) cov_cmp++;
          if (o1.fu == 9'h011) cov_fmv[0]++;
          if (o1.fu == 9'h012) cov_fmv[1]++;
        end
      end
      if (oracle_ok(o1) && g_io_out_valid) begin
        shell_oracle(o1, ev, ef);
        oracle_checks++;
        if (o1.fu[5]) begin if (o1.fu[6]) cov_wwv++; else cov_wvv++; end
        else cov_op[o1.fu[2:0]]++;
        cov_sew[o1.sew + o1.fu[5]]++;
        if (i_io_out_bits_res_data !== ev || i_io_out_bits_res_fflags !== ef) begin
          oracle_err++;
          if (oracle_err <= 30)
            $display("[%0d] ORACLE fu=%h sew=%0d vlmul=%0d uop=%0d vl=%0d vstart=%0d vm=%0d ta=%0d ma=%0d rm=%0d\n   vs2=%h vs1=%h old=%h v0=%h\n   exp vd=%h ff=%b\n   got vd=%h ff=%b",
                     cyc, o1.fu, o1.sew, o1.vlmul, o1.uop, o1.vl, o1.vstart, o1.vm, o1.vta, o1.vma, o1.rm, o1.vs2, o1.vs1,
                     o1.old, o1.v0, ev, ef, i_io_out_bits_res_data, i_io_out_bits_res_fflags);
        end
      end
    end
    bad = 0;
    if (oracle_checks < 20000) bad++;
    for (int k = 0; k < 5; k++) if (cov_op[k] < 1000) begin bad++; $display("COV FAIL op%0d=%0d", k, cov_op[k]); end
    if (cov_wvv < 1000 || cov_wwv < 1000) begin bad++; $display("COV FAIL widen vv/wv=%0d/%0d", cov_wvv, cov_wwv); end
    for (int s = 1; s < 4; s++) if (cov_sew[s] < 3000) begin bad++; $display("COV FAIL sew%0d=%0d", s, cov_sew[s]); end
    if (cov_masked < 100 || cov_tail[0] < 100 || cov_tail[1] < 100 || cov_prestart < 100 || cov_vge < 100 || cov_vl0 < 100) bad++;
    foreach (cov_red[k, f]) if (cov_red[k][f] < 300) begin bad++; $display("COV FAIL red %h fold=%0d : %0d", RED_OPS[k], f, cov_red[k][f]); end
    if (cov_cmp < 300 || cov_fmv[0] < 300 || cov_fmv[1] < 300) begin bad++; $display("COV FAIL cmp=%0d fmv=%0d/%0d", cov_cmp, cov_fmv[0], cov_fmv[1]); end
    if (seen0_vd !== '1 || seen1_vd !== '1) begin bad++; $display("res_data not toggled: 0=%h 1=%h", seen0_vd, seen1_vd); end
    if (seen0_ff !== '1 || seen1_ff !== 5'b10101) begin bad++; $display("res_fflags not toggled: 0=%b 1=%b", seen0_ff, seen1_ff); end
    $display("COVERAGE oracle=%0d op0..4=%0d/%0d/%0d/%0d/%0d widen vv/wv=%0d/%0d sew1..3=%0d/%0d/%0d masked=%0d tail=%0d/%0d prestart=%0d vge=%0d vl0=%0d cmp=%0d fmv=%0d/%0d",
             oracle_checks, cov_op[0], cov_op[1], cov_op[2], cov_op[3], cov_op[4], cov_wvv, cov_wwv, cov_sew[1], cov_sew[2], cov_sew[3],
             cov_masked, cov_tail[0], cov_tail[1], cov_prestart, cov_vge, cov_vl0, cov_cmp, cov_fmv[0], cov_fmv[1]);
    $display("ORACLE oracle_errors=%0d", oracle_err);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_err == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
