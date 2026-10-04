// =============================================================================
// tb —— VFMA UT：golden VFMA（含 golden 子树）与重写件 VFMA_xs（子树全是重写件：VectorFloatFMA ×2、VecDataSplitModule ×3、
// Mgu，以及共享辅助件 xs_VecFflagsElemMask）双例化，同时钟同激励逐拍比全部输出。
//
// 激励：每拍造一个 uop（op_t：fuOpType / vsew / vlmul / vuopIdx / vl / vstart / vm / vta / vma / v0 / 三个源 / 控制透传 / 调试），
//   第 0 级端口（ctrl_fuOpType / vsew / vuopIdx、data_src_0..2、perf / seqNum）取本拍的 uop；第 3 级端口（ctrlPipe_3 /
//   dataPipe_3 / validPipe_3）取 3 拍前的 uop —— 模拟发射级预打好的流水（与 VectorFloatFMA 的「每拍无条件前进」一致）。
//   in_valid 3/4；out_ready 7/8（反压只影响调试信息的搬运门控，差分照比）；fuOpType：九成取 9 个 FMA 运算码（低 4 位），
//   bit4 = 加宽（f16→f32 / f32→f64，约 1/4），一成随机；vsew 加宽时 1..2、否则 1..3；七成以上合法 RVV 配置
//   （vl <= VLMAX、vuopIdx < 寄存器组大小、vstart <= vl），1/8 全随机（只做差分：Mgu 的字节计数 vl<<SEW 截 8 位，
//   非法 vl 下没有 RVV 语义可比）；操作数按 SEW 逐元素造：特殊值 / 同量级（大量抵消）/ 上溢 / 非规格数边界；frm 九成合法。
// 差分比较：in_ready / out_valid 每拍比；res_data / res_fflags / 控制透传在第一次 in_valid 后 3 拍起每拍比
//   （VectorFloatFMA 的各级寄存器每次 fire 全写）；调试信息（受 ready 门控搬运、无复位）同上。
// 独立按元素 oracle（tb 内整数算术 fp_fma_oracle_pkg），对第 3 级上合法、有效的 uop：
//   - 每个结果元素 i：非加宽取 vs2 / vs1 / 旧 vd 的元素 i；加宽取 vs2 / vs1 的源元素 vuopIdx[0]·(128/结果SEW) + i（源格式），
//     加数取旧 vd 元素 i（结果格式）；按运算码定乘数 / 加数与取反（vfmacc a·b+c、vfnmacc −a·b−c、vfmsac a·b−c、
//     vfnmsac −a·b+c、vfmadd c·b+a、vfnmadd −c·b−a、vfmsub c·b−a、vfnmsub −c·b+a、vfmul a·b），IEEE 舍入与标志；
//   - Mgu：vstart >= vl 整个 vd 保持旧值；否则 < vstart 旧值；>= vl → vta ? 全 1 : 旧值；掩码关 → vma ? 全 1 : 旧值；
//   - fflags：元素 i 计入当且仅当 i < 本 uop 元素上限（分数 LMUL 按加宽修正后的 vlmul 收窄）、uop·上限 + i < vl、掩码位为 1。
// 覆盖（写进 PASS 判据）：oracle 比对 >= 20000；9 个运算码各 >= 1000、加宽 f32 / f64 结果各 >= 1000；3 种结果 SEW 各 >= 3000；
//   NV / OF / UF / NX 元素级各 >= 100；掩码关 / 尾部（ta 0/1）/ vstart 前部 / vstart>=vl / 分数 LMUL 各 >= 100；
//   res_data / res_fflags 每位都见过 0 和 1（DZ 位乘加不产生，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_fma_oracle_pkg::*;
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
  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx;
  logic [8:0]     io_in_bits_ctrlPipe_3_fuOpType;
  logic           io_in_bits_ctrlPipe_3_robIdx_flag;
  logic [7:0]     io_in_bits_ctrlPipe_3_robIdx_value;
  logic [7:0]     io_in_bits_ctrlPipe_3_pdest;
  logic           io_in_bits_ctrlPipe_3_vecWen;
  logic           io_in_bits_ctrlPipe_3_v0Wen;
  logic           io_in_bits_ctrlPipe_3_fpu_wflags;
  logic           io_in_bits_ctrlPipe_3_vpu_vma;
  logic           io_in_bits_ctrlPipe_3_vpu_vta;
  logic [1:0]     io_in_bits_ctrlPipe_3_vpu_vsew;
  logic [2:0]     io_in_bits_ctrlPipe_3_vpu_vlmul;
  logic           io_in_bits_ctrlPipe_3_vpu_vm;
  logic [7:0]     io_in_bits_ctrlPipe_3_vpu_vstart;
  logic [6:0]     io_in_bits_ctrlPipe_3_vpu_vuopIdx;
  logic           io_in_bits_ctrlPipe_3_vpu_isNarrow;
  logic           io_in_bits_ctrlPipe_3_vpu_isDstMask;
  logic           io_in_bits_validPipe_3;
  logic [127:0]   io_in_bits_data_src_2;
  logic [127:0]   io_in_bits_data_src_1;
  logic [127:0]   io_in_bits_data_src_0;
  logic [7:0]     io_in_bits_dataPipe_3_src_4;
  logic [127:0]   io_in_bits_dataPipe_3_src_3;
  logic [127:0]   io_in_bits_dataPipe_3_src_2;
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
  VFMA u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_fuOpType(io_in_bits_ctrlPipe_3_fuOpType),
    .io_in_bits_ctrlPipe_3_robIdx_flag(io_in_bits_ctrlPipe_3_robIdx_flag),
    .io_in_bits_ctrlPipe_3_robIdx_value(io_in_bits_ctrlPipe_3_robIdx_value),
    .io_in_bits_ctrlPipe_3_pdest(io_in_bits_ctrlPipe_3_pdest),
    .io_in_bits_ctrlPipe_3_vecWen(io_in_bits_ctrlPipe_3_vecWen),
    .io_in_bits_ctrlPipe_3_v0Wen(io_in_bits_ctrlPipe_3_v0Wen),
    .io_in_bits_ctrlPipe_3_fpu_wflags(io_in_bits_ctrlPipe_3_fpu_wflags),
    .io_in_bits_ctrlPipe_3_vpu_vma(io_in_bits_ctrlPipe_3_vpu_vma),
    .io_in_bits_ctrlPipe_3_vpu_vta(io_in_bits_ctrlPipe_3_vpu_vta),
    .io_in_bits_ctrlPipe_3_vpu_vsew(io_in_bits_ctrlPipe_3_vpu_vsew),
    .io_in_bits_ctrlPipe_3_vpu_vlmul(io_in_bits_ctrlPipe_3_vpu_vlmul),
    .io_in_bits_ctrlPipe_3_vpu_vm(io_in_bits_ctrlPipe_3_vpu_vm),
    .io_in_bits_ctrlPipe_3_vpu_vstart(io_in_bits_ctrlPipe_3_vpu_vstart),
    .io_in_bits_ctrlPipe_3_vpu_vuopIdx(io_in_bits_ctrlPipe_3_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_vpu_isNarrow(io_in_bits_ctrlPipe_3_vpu_isNarrow),
    .io_in_bits_ctrlPipe_3_vpu_isDstMask(io_in_bits_ctrlPipe_3_vpu_isDstMask),
    .io_in_bits_validPipe_3(io_in_bits_validPipe_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_3_src_4(io_in_bits_dataPipe_3_src_4),
    .io_in_bits_dataPipe_3_src_3(io_in_bits_dataPipe_3_src_3),
    .io_in_bits_dataPipe_3_src_2(io_in_bits_dataPipe_3_src_2),
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
  VFMA_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_vpu_vsew(io_in_bits_ctrl_vpu_vsew),
    .io_in_bits_ctrl_vpu_vuopIdx(io_in_bits_ctrl_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_fuOpType(io_in_bits_ctrlPipe_3_fuOpType),
    .io_in_bits_ctrlPipe_3_robIdx_flag(io_in_bits_ctrlPipe_3_robIdx_flag),
    .io_in_bits_ctrlPipe_3_robIdx_value(io_in_bits_ctrlPipe_3_robIdx_value),
    .io_in_bits_ctrlPipe_3_pdest(io_in_bits_ctrlPipe_3_pdest),
    .io_in_bits_ctrlPipe_3_vecWen(io_in_bits_ctrlPipe_3_vecWen),
    .io_in_bits_ctrlPipe_3_v0Wen(io_in_bits_ctrlPipe_3_v0Wen),
    .io_in_bits_ctrlPipe_3_fpu_wflags(io_in_bits_ctrlPipe_3_fpu_wflags),
    .io_in_bits_ctrlPipe_3_vpu_vma(io_in_bits_ctrlPipe_3_vpu_vma),
    .io_in_bits_ctrlPipe_3_vpu_vta(io_in_bits_ctrlPipe_3_vpu_vta),
    .io_in_bits_ctrlPipe_3_vpu_vsew(io_in_bits_ctrlPipe_3_vpu_vsew),
    .io_in_bits_ctrlPipe_3_vpu_vlmul(io_in_bits_ctrlPipe_3_vpu_vlmul),
    .io_in_bits_ctrlPipe_3_vpu_vm(io_in_bits_ctrlPipe_3_vpu_vm),
    .io_in_bits_ctrlPipe_3_vpu_vstart(io_in_bits_ctrlPipe_3_vpu_vstart),
    .io_in_bits_ctrlPipe_3_vpu_vuopIdx(io_in_bits_ctrlPipe_3_vpu_vuopIdx),
    .io_in_bits_ctrlPipe_3_vpu_isNarrow(io_in_bits_ctrlPipe_3_vpu_isNarrow),
    .io_in_bits_ctrlPipe_3_vpu_isDstMask(io_in_bits_ctrlPipe_3_vpu_isDstMask),
    .io_in_bits_validPipe_3(io_in_bits_validPipe_3),
    .io_in_bits_data_src_2(io_in_bits_data_src_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_dataPipe_3_src_4(io_in_bits_dataPipe_3_src_4),
    .io_in_bits_dataPipe_3_src_3(io_in_bits_dataPipe_3_src_3),
    .io_in_bits_dataPipe_3_src_2(io_in_bits_dataPipe_3_src_2),
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
  // 一个 uop 的全部激励
  // ---------------------------------------------------------------------------
  typedef struct {
    bit           valid, legal;
    logic [8:0]   fu;
    logic [1:0]   sew;
    logic [2:0]   vlmul, rm;
    logic [6:0]   uop;
    logic [7:0]   vl, vstart;
    bit           vm, vta, vma, narrow, dstmask;
    logic [127:0] v0, old, vs1, vs2;
    bit           robf, vecwen, v0wen, wflags;
    logic [7:0]   robv, pdest;
  } op_t;
  op_t pipe [0:3];   // pipe[0] = 本拍入口，pipe[3] = 第 3 级

  // ---- 按格式造一个元素 ----
  function automatic logic [63:0] pick_elem(input logic [1:0] f, input logic [63:0] near);
    int ew = EWf(f), mw = MWf(f);
    longint unsigned e, m, em = (64'd1 << ew) - 1, ne;
    bit s = $urandom;
    m  = {$urandom, $urandom} & ((64'd1 << mw) - 1);
    ne = (near >> mw) & em;
    case ($urandom_range(0, 15))
      0: begin e = 0; m = 0; end
      1: begin e = em; m = 0; end
      2: begin e = em; m = m | (64'd1 << (mw - 1)); end
      3: begin e = em; m = m & ~(64'd1 << (mw - 1)); if (m == 0) m = 1; end
      4: e = 0;
      5: e = em - 1;
      6: e = $urandom_range(1, 3);
      7, 8, 9: begin e = ne + $urandom_range(0, 2) - 1; if (e >= em) e = em - 1; end
      default: e = $urandom_range(1, em - 1);
    endcase
    return (64'(s) << (ew + mw)) | (64'(e) << mw) | 64'(m);
  endfunction
  function automatic logic [127:0] pack128(input logic [1:0] f, input logic [127:0] ref_v);
    int w = 8 << f, n = 128 / w;
    logic [127:0] r = '0;
    for (int k = 0; k < n; k++)
      r |= 128'(pick_elem(f, 64'(ref_v >> (w * k)))) << (w * k);
    return r;
  endfunction

  function automatic op_t gen_op();
    op_t o;
    int n, vlmax, nreg, base, lmul_sh;
    bit widen;
    o.valid = ($urandom_range(0, 3) != 0);
    o.fu    = ($urandom_range(0, 9) == 0) ? 9'($urandom) : {4'b0010, 1'b0, 4'($urandom_range(0, 8))};
    widen   = ($urandom_range(0, 3) == 0);
    if (o.fu[8:5] == 4'b0010) o.fu[4] = widen;
    o.sew   = o.fu[4] ? 2'($urandom_range(1, 2)) : 2'($urandom_range(1, 3));
    if ($urandom_range(0, 31) == 0) o.sew = 0;
    o.vlmul = ($urandom_range(0, 3) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, o.fu[4] ? 2 : 3));
    o.rm    = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    o.vm = $urandom; o.vta = $urandom; o.vma = $urandom;
    o.narrow  = ($urandom_range(0, 15) == 0);
    o.dstmask = ($urandom_range(0, 15) == 0);
    // 合法配置：结果元素宽 = sew + 加宽；VLMAX 按源 SEW 与 LMUL；结果寄存器组 = ceil(VLMAX / 每寄存器结果元素数)
    n       = 128 >> (3 + o.sew + o.fu[4]);
    lmul_sh = o.vlmul[2] ? -(4 - int'(o.vlmul[1:0])) : int'(o.vlmul[1:0]);
    vlmax   = (lmul_sh >= 0) ? ((128 >> (3 + o.sew)) << lmul_sh) : ((128 >> (3 + o.sew)) >> (-lmul_sh));
    nreg    = (vlmax + n - 1) / n;
    if (nreg < 1) nreg = 1;
    o.uop   = 7'($urandom_range(0, nreg - 1));
    base    = int'(o.uop) * n;
    o.vl    = ($urandom_range(0, 1)) ? 8'((base + $urandom_range(0, n) > vlmax) ? vlmax : base + $urandom_range(0, n))
                                     : 8'($urandom_range(0, vlmax));
    o.vstart = ($urandom_range(0, 9) < 7) ? 8'd0 : 8'($urandom_range(0, o.vl));
    o.legal = 1;
    if ($urandom_range(0, 7) == 0) begin
      o.vlmul = $urandom; o.uop = $urandom; o.vl = $urandom; o.vstart = $urandom; o.legal = 0;
    end
    o.v0  = {$urandom, $urandom, $urandom, $urandom};
    if ($urandom_range(0, 3) == 0) o.v0 = '1;
    o.vs2 = pack128(o.fu[4] ? o.sew : o.sew, {$urandom, $urandom, $urandom, $urandom});
    o.vs1 = pack128(o.sew, o.vs2);
    o.old = pack128(o.sew + o.fu[4], o.fu[4] ? {$urandom, $urandom, $urandom, $urandom} : o.vs2);
    if ($urandom_range(0, 7) == 0) begin o.vs2 = {$urandom, $urandom, $urandom, $urandom}; o.vs1 = {$urandom, $urandom, $urandom, $urandom}; end
    o.robf = $urandom; o.robv = $urandom; o.pdest = $urandom; o.vecwen = $urandom; o.v0wen = $urandom; o.wflags = $urandom;
    return o;
  endfunction

  task automatic drive_ports();
    io_in_valid                     = pipe[0].valid;
    io_in_bits_ctrl_fuOpType        = pipe[0].fu;
    io_in_bits_ctrl_vpu_vsew        = pipe[0].sew;
    io_in_bits_ctrl_vpu_vuopIdx     = pipe[0].uop;
    io_in_bits_data_src_2           = pipe[0].old;
    io_in_bits_data_src_1           = pipe[0].vs2;
    io_in_bits_data_src_0           = pipe[0].vs1;
    io_frm                          = pipe[0].rm;
    io_in_bits_ctrlPipe_3_fuOpType      = pipe[3].fu;
    io_in_bits_ctrlPipe_3_robIdx_flag   = pipe[3].robf;
    io_in_bits_ctrlPipe_3_robIdx_value  = pipe[3].robv;
    io_in_bits_ctrlPipe_3_pdest         = pipe[3].pdest;
    io_in_bits_ctrlPipe_3_vecWen        = pipe[3].vecwen;
    io_in_bits_ctrlPipe_3_v0Wen         = pipe[3].v0wen;
    io_in_bits_ctrlPipe_3_fpu_wflags    = pipe[3].wflags;
    io_in_bits_ctrlPipe_3_vpu_vma       = pipe[3].vma;
    io_in_bits_ctrlPipe_3_vpu_vta       = pipe[3].vta;
    io_in_bits_ctrlPipe_3_vpu_vsew      = pipe[3].sew;
    io_in_bits_ctrlPipe_3_vpu_vlmul     = pipe[3].vlmul;
    io_in_bits_ctrlPipe_3_vpu_vm        = pipe[3].vm;
    io_in_bits_ctrlPipe_3_vpu_vstart    = pipe[3].vstart;
    io_in_bits_ctrlPipe_3_vpu_vuopIdx   = pipe[3].uop;
    io_in_bits_ctrlPipe_3_vpu_isNarrow  = pipe[3].narrow;
    io_in_bits_ctrlPipe_3_vpu_isDstMask = pipe[3].dstmask;
    io_in_bits_validPipe_3              = pipe[3].valid;
    io_in_bits_dataPipe_3_src_4         = pipe[3].vl;
    io_in_bits_dataPipe_3_src_3         = pipe[3].v0;
    io_in_bits_dataPipe_3_src_2         = pipe[3].old;
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
  // 外壳层 oracle
  // ---------------------------------------------------------------------------
  int cov_op [16], cov_widen [4], cov_sew [4], cov_fl [5];
  int cov_masked = 0, cov_tail [2], cov_prestart = 0, cov_vge = 0, cov_frac = 0;

  task automatic shell_oracle(input op_t o, output logic [127:0] exp_vd, output logic [4:0] exp_ff);
    logic [1:0]  rf, sf;      // 结果 / 源格式
    logic [3:0]  opc;
    int w, ws, n, gi, n_this, sh, vlmax_i;
    logic [63:0] em, nv, ov, ev, r;
    logic [4:0]  fl;
    fpv_t a, b, c, x, y, z;
    bit widen, mbit;
    logic [2:0] vfix;
    widen = o.fu[4];
    opc   = o.fu[3:0];
    sf    = o.sew;
    rf    = o.sew + widen;
    w     = 8 << rf;
    ws    = 8 << sf;
    n     = 128 / w;
    em    = (w == 64) ? '1 : ((64'd1 << w) - 1);
    vfix  = widen ? 3'(o.vlmul + 3'd1) : o.vlmul;
    vlmax_i = 16 >> rf;
    sh     = vfix[2] ? int'(2'(~vfix[1:0] + 2'd1)) : int'(vfix[1:0]);
    n_this = o.vlmul[2] ? (vlmax_i >> sh) : vlmax_i;
    exp_vd = '0;
    exp_ff = '0;
    for (int i = 0; i < n; i++) begin
      // ---- 本元素的 IEEE 结果 ----
      if (widen) begin
        a = decode(64'(o.vs2 >> (ws * (int'(o.uop[0]) * n + i))) & ((64'd1 << ws) - 1), sf);
        b = decode(64'(o.vs1 >> (ws * (int'(o.uop[0]) * n + i))) & ((64'd1 << ws) - 1), sf);
      end else begin
        a = decode(64'(o.vs2 >> (w * i)) & em, rf);
        b = decode(64'(o.vs1 >> (w * i)) & em, rf);
      end
      c = decode(64'(o.old >> (w * i)) & em, rf);
      case (opc)
        4'd0: begin x = a; y = b; end
        4'd1: begin x = a; y = b; z = c; end
        4'd2: begin x = a; x.sign = ~a.sign; y = b; z = c; z.sign = ~c.sign; end
        4'd3: begin x = a; y = b; z = c; z.sign = ~c.sign; end
        4'd4: begin x = a; x.sign = ~a.sign; y = b; z = c; end
        4'd5: begin x = c; y = b; z = a; end
        4'd6: begin x = c; x.sign = ~c.sign; y = b; z = a; z.sign = ~a.sign; end
        4'd7: begin x = c; y = b; z = a; z.sign = ~a.sign; end
        default: begin x = c; x.sign = ~c.sign; y = b; z = a; end
      endcase
      if (opc == 4'd0) mul_ref(x, y, rf, o.rm, r, fl);
      else             fma_ref(x, y, z, rf, o.rm, r, fl);
      // ---- Mgu ----
      gi   = int'(o.uop[2:0]) * n + i;
      mbit = o.vm ? 1'b1 : o.v0[gi];
      nv   = r & em;
      ov   = 64'(o.old >> (w * i)) & em;
      if (o.vstart >= o.vl) begin ev = ov; cov_vge++; end
      else if (gi < int'(o.vstart)) begin ev = ov; cov_prestart++; end
      else if (gi >= int'(o.vl)) begin ev = o.vta ? em : ov; cov_tail[o.vta]++; end
      else if (mbit) ev = nv;
      else begin ev = o.vma ? em : ov; cov_masked++; end
      exp_vd |= 128'(ev) << (w * i);
      // ---- fflags ----
      if (i < n_this && int'(o.uop[2:0]) * n_this + i < int'(o.vl) &&
          (o.vm ? 1'b1 : o.v0[int'(o.uop[2:0]) * vlmax_i + i])) begin
        exp_ff |= fl;
        for (int k = 0; k < 5; k++) if (fl[k]) cov_fl[k]++;
      end
    end
    if (o.vlmul[2]) cov_frac++;
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
    op_t o3;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int k = 0; k < 4; k++) begin pipe[k] = gen_op(); pipe[k].valid = 0; end
    reset = 1;
    drive_ports();
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      // 流水前进：pipe[k] <= pipe[k-1]，pipe[0] 新造
      for (int k = 3; k > 0; k--) pipe[k] = pipe[k-1];
      pipe[0] = gen_op();
      drive_ports();
      if (first_valid < 0 && pipe[0].valid) first_valid = cyc;
      #1;
      checks++;
      nd = int'(g_io_in_ready !== i_io_in_ready) + int'(g_io_out_valid !== i_io_out_valid);
      if (first_valid >= 0 && cyc >= first_valid + 3) nd = diff_outputs(0);
      if (nd > 0) begin
        errors++;
        if (errors <= 20) begin $display("[%0d] MISMATCH", cyc); void'(diff_outputs(1)); end
      end
      if (first_valid >= 0 && cyc >= first_valid + 3) begin
        seen1_vd |= g_io_out_bits_res_data;   seen0_vd |= ~g_io_out_bits_res_data;
        seen1_ff |= g_io_out_bits_res_fflags; seen0_ff |= ~g_io_out_bits_res_fflags;
      end
      // ---- oracle：第 3 级的 uop（它在 3 拍前进入两个 FMA）----
      o3 = pipe[3];
      if (o3.valid && o3.legal && g_io_out_valid && o3.fu[8:5] == 4'b0010 && o3.fu[3:0] <= 4'd8 &&
          o3.sew != 0 && !(o3.fu[4] && (o3.sew == 3 || o3.fu[3:0] >= 4'd5)) && o3.rm <= 3'd4 &&
          !o3.narrow && !o3.dstmask) begin
        shell_oracle(o3, ev, ef);
        oracle_checks++;
        cov_op[o3.fu[3:0]]++;
        if (o3.fu[4]) cov_widen[o3.sew + 1]++;
        cov_sew[o3.sew + o3.fu[4]]++;
        if (i_io_out_bits_res_data !== ev || i_io_out_bits_res_fflags !== ef) begin
          oracle_err++;
          if (oracle_err <= 30)
            $display("[%0d] ORACLE op=%0d widen=%0d sew=%0d vlmul=%0d uop=%0d vl=%0d vstart=%0d vm=%0d ta=%0d ma=%0d rm=%0d\n   vs2=%h vs1=%h old=%h\n   exp vd=%h ff=%b\n   got vd=%h ff=%b",
                     cyc, o3.fu[3:0], o3.fu[4], o3.sew, o3.vlmul, o3.uop, o3.vl, o3.vstart, o3.vm, o3.vta, o3.vma, o3.rm,
                     o3.vs2, o3.vs1, o3.old, ev, ef, i_io_out_bits_res_data, i_io_out_bits_res_fflags);
        end
      end
    end
    // ---- 判据 ----
    bad = 0;
    if (oracle_checks < 20000) bad++;
    for (int k = 0; k <= 8; k++) if (cov_op[k] < 1000) begin bad++; $display("COV FAIL op%0d=%0d", k, cov_op[k]); end
    if (cov_widen[2] < 1000 || cov_widen[3] < 1000) begin bad++; $display("COV FAIL widen f32/f64=%0d/%0d", cov_widen[2], cov_widen[3]); end
    for (int s = 1; s < 4; s++) if (cov_sew[s] < 3000) begin bad++; $display("COV FAIL sew%0d=%0d", s, cov_sew[s]); end
    if (cov_fl[4] < 100 || cov_fl[2] < 100 || cov_fl[1] < 100 || cov_fl[0] < 100) begin
      bad++; $display("COV FAIL flags NV/OF/UF/NX=%0d/%0d/%0d/%0d", cov_fl[4], cov_fl[2], cov_fl[1], cov_fl[0]);
    end
    if (cov_masked < 100 || cov_tail[0] < 100 || cov_tail[1] < 100 || cov_prestart < 100 || cov_vge < 100 || cov_frac < 100) bad++;
    if (seen0_vd !== '1 || seen1_vd !== '1) begin bad++; $display("res_data not toggled: 0=%h 1=%h", seen0_vd, seen1_vd); end
    if (seen0_ff !== '1 || seen1_ff !== 5'b10111) begin bad++; $display("res_fflags not toggled: 0=%b 1=%b", seen0_ff, seen1_ff); end
    $display("COVERAGE oracle=%0d op0..8=%0d/%0d/%0d/%0d/%0d/%0d/%0d/%0d/%0d widen f32/f64=%0d/%0d sew1/2/3=%0d/%0d/%0d",
             oracle_checks, cov_op[0], cov_op[1], cov_op[2], cov_op[3], cov_op[4], cov_op[5], cov_op[6], cov_op[7], cov_op[8],
             cov_widen[2], cov_widen[3], cov_sew[1], cov_sew[2], cov_sew[3]);
    $display("COVERAGE flags NV/OF/UF/NX=%0d/%0d/%0d/%0d masked=%0d tail ta0/1=%0d/%0d prestart=%0d vstart>=vl=%0d frac=%0d",
             cov_fl[4], cov_fl[2], cov_fl[1], cov_fl[0], cov_masked, cov_tail[0], cov_tail[1], cov_prestart, cov_vge, cov_frac);
    $display("ORACLE oracle_errors=%0d", oracle_err);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_err == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
