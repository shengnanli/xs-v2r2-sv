// =============================================================================
// VFMA.sv —— 向量浮点乘加功能单元外壳（vfmacc / vfnmacc / vfmsac / vfmul / vfwmacc …，3 拍流水）
//
// 在哪一层：ExeUnit（向量浮点 FMA 执行单元）的 FU。一条 uop 的 128 位向量拆成低 / 高两个 64 位半边，各交给一个
//   VectorFloatFMA（每个内部按 SEW 并行 1×f64 / 2×f32 / 4×f16，三拍出结果）；结果在第 3 拍按 RVV 的 vstart / vl /
//   掩码 / vta / vma 语义经 Mgu 与旧 vd 合并，并把活跃元素的 fflags 合并成 5 位。
//   Scala：VFMA extends VecPipedFuncUnit（流水 FU 的公共外壳：控制 / 数据的第 3 级寄存器由发射级预打好，从
//   io.in.bits.ctrlPipe_3 / dataPipe_3 / validPipe_3 进来）。
//
// 数据流：
//   §1 本 FU 的 valid 移位链（validVecThisFu_1..3，异步复位，不受 ready 门控）与反压链（rdy：第 s 级空或下一级能收）；
//      调试 / 性能信息随流水搬 3 级（受 ready 门控）。
//   §2 两个 VectorFloatFMA：fire = in_valid（★直接用 valid，不看 ready★）；a = vs2、b = vs1、c = 旧 vd（src_2）的各自半边；
//      加宽指令（fuOpType[4]）：结果格式 = vsew+1，源元素来自 widen_a / widen_b——低半边 lane 取 vs2/vs1 的 32 位块 0、2，
//      高半边 lane 取块 1、3（uop_idx = vuopIdx[0] 再在 lane 内选高低 f16）；op_code = fuOpType[3:0]。
//   §3 写回（第 3 级）：结果元素宽度 outEew = 加宽 ? vsew+1 : vsew；掩码 = vm ? 全 1 : v0；Mgu 合并；
//      fflags 用 xs_VecFflagsElemMask 选活跃元素（加宽时 vlmul 也 +1 再收窄 vlMax）后按位或。
// ★bug-for-bug 要点★
//   · out_valid = validPipe_3 & validVecThisFu_3；写回控制全部来自 ctrlPipe_3（本层不打控制寄存器）。
//   · 分数 LMUL 的判断看的是原始 vlmul[2]，收窄量用的是加宽修正后的 vlmulFix（golden 原样）。
//   · fuOpType==0xFF 的 assert 只在非 SYNTHESIS 下存在，本核不写。
// 子模块（两侧白盒）：VectorFloatFMA vfmas_0 / vfmas_1、VecDataSplitModule vs2Split / vs1Split / oldVdSplit、Mgu mgu
//   （实例名与 golden 一致；本仓已签核重写件）；共享辅助件 xs_VecFflagsElemMask（rtl/common）。
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VFMA.scala、fu/vector/VecPipedFuncUnit.scala
// golden 对照：G1-canonical/golden-rtl/VFMA.sv
// =============================================================================

package vfma_pkg;
  localparam int unsigned LAT = 3;    // 本 FU 的流水级数

  // 随流水搬运的调试/性能采样信息
  typedef struct packed {
    logic        eliminatedMove;
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } perf_dbg_t;

  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;
endpackage

// -----------------------------------------------------------------------------
// xs_VFMA_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VFMA_core
  import vfma_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // ---- 入口（第 0 级：送进两个 FMA）----
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic [1:0]   in_vsew,
  input  logic [6:0]   in_vuopIdx,
  input  logic [127:0] in_oldVd,          // src_2
  input  logic [127:0] in_vs2,            // src_1
  input  logic [127:0] in_vs1,            // src_0
  input  perf_dbg_t    in_perf,
  input  seq_num_t     in_seq,
  input  logic [2:0]   frm,
  // ---- 第 3 级（发射级预打好的控制 / 数据）----
  input  logic [8:0]   s3_fuOpType,
  input  logic         s3_robIdx_flag,
  input  logic [7:0]   s3_robIdx_value,
  input  logic [7:0]   s3_pdest,
  input  logic         s3_vecWen,
  input  logic         s3_v0Wen,
  input  logic         s3_fpu_wflags,
  input  logic         s3_vma,
  input  logic         s3_vta,
  input  logic [1:0]   s3_vsew,
  input  logic [2:0]   s3_vlmul,
  input  logic         s3_vm,
  input  logic [7:0]   s3_vstart,
  input  logic [6:0]   s3_vuopIdx,
  input  logic         s3_isNarrow,
  input  logic         s3_isDstMask,
  input  logic         s3_valid,          // validPipe_3
  input  logic [7:0]   s3_vl,             // dataPipe_3 src_4
  input  logic [127:0] s3_v0,             // dataPipe_3 src_3
  input  logic [127:0] s3_oldVd,          // dataPipe_3 src_2
  // ---- 出口 ----
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic         out_fpu_wflags,
  output logic [127:0] out_res_data,
  output logic [4:0]   out_res_fflags,
  output perf_dbg_t    out_perf,
  output seq_num_t     out_seq
);
  // ---------------------------------------------------------------------------
  // §1 valid 移位链 + 反压链；调试信息随流水搬运
  // ---------------------------------------------------------------------------
  logic [LAT:1] vldThisFu;        // vldThisFu[s] = s 拍前接了一个请求
  logic [LAT:0] rdy;              // rdy[s] = 第 s 级能接新活；rdy[0] = in_ready
  always_comb begin
    rdy[LAT] = out_ready;
    for (int s = LAT - 1; s >= 0; s--) rdy[s] = ~vldThisFu[s+1] | rdy[s+1];
  end
  assign in_ready = rdy[0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      vldThisFu <= '0;
    else begin
      vldThisFu[1] <= in_valid;                                     // 不受 ready 门控（照 golden）
      for (int s = 2; s <= LAT; s++) vldThisFu[s] <= vldThisFu[s-1];
    end
  end

  perf_dbg_t perfVec   [1:LAT];
  seq_num_t  seqNumVec [1:LAT];
  always_ff @(posedge clock) begin
    if (rdy[0] & in_valid) begin
      perfVec[1]   <= in_perf;
      seqNumVec[1] <= in_seq;
    end
    for (int s = 2; s <= LAT; s++) begin
      if (rdy[s-1] & vldThisFu[s-1]) begin
        perfVec[s]   <= perfVec[s-1];
        seqNumVec[s] <= seqNumVec[s-1];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2 两个向量 FMA（各管 64 位）
  // ---------------------------------------------------------------------------
  logic [63:0] vs2_64 [2], vs1_64 [2], old_64 [2];
  logic [31:0] vs2_32 [4], vs1_32 [4];
  VecDataSplitModule vs2Split (
    .io_inVecData   (in_vs2),
    .io_outVec8b_0  (), .io_outVec8b_1  (), .io_outVec8b_2  (), .io_outVec8b_3  (),
    .io_outVec8b_4  (), .io_outVec8b_5  (), .io_outVec8b_6  (), .io_outVec8b_7  (),
    .io_outVec8b_8  (), .io_outVec8b_9  (), .io_outVec8b_10 (), .io_outVec8b_11 (),
    .io_outVec8b_12 (), .io_outVec8b_13 (), .io_outVec8b_14 (), .io_outVec8b_15 (),
    .io_outVec16b_0 (), .io_outVec16b_1 (), .io_outVec16b_2 (), .io_outVec16b_3 (),
    .io_outVec16b_4 (), .io_outVec16b_5 (), .io_outVec16b_6 (), .io_outVec16b_7 (),
    .io_outVec32b_0 (vs2_32[0]), .io_outVec32b_1 (vs2_32[1]), .io_outVec32b_2 (vs2_32[2]), .io_outVec32b_3 (vs2_32[3]),
    .io_outVec64b_0 (vs2_64[0]),
    .io_outVec64b_1 (vs2_64[1])
  );
  VecDataSplitModule vs1Split (
    .io_inVecData   (in_vs1),
    .io_outVec8b_0  (), .io_outVec8b_1  (), .io_outVec8b_2  (), .io_outVec8b_3  (),
    .io_outVec8b_4  (), .io_outVec8b_5  (), .io_outVec8b_6  (), .io_outVec8b_7  (),
    .io_outVec8b_8  (), .io_outVec8b_9  (), .io_outVec8b_10 (), .io_outVec8b_11 (),
    .io_outVec8b_12 (), .io_outVec8b_13 (), .io_outVec8b_14 (), .io_outVec8b_15 (),
    .io_outVec16b_0 (), .io_outVec16b_1 (), .io_outVec16b_2 (), .io_outVec16b_3 (),
    .io_outVec16b_4 (), .io_outVec16b_5 (), .io_outVec16b_6 (), .io_outVec16b_7 (),
    .io_outVec32b_0 (vs1_32[0]), .io_outVec32b_1 (vs1_32[1]), .io_outVec32b_2 (vs1_32[2]), .io_outVec32b_3 (vs1_32[3]),
    .io_outVec64b_0 (vs1_64[0]),
    .io_outVec64b_1 (vs1_64[1])
  );
  VecDataSplitModule oldVdSplit (
    .io_inVecData   (in_oldVd),
    .io_outVec8b_0  (), .io_outVec8b_1  (), .io_outVec8b_2  (), .io_outVec8b_3  (),
    .io_outVec8b_4  (), .io_outVec8b_5  (), .io_outVec8b_6  (), .io_outVec8b_7  (),
    .io_outVec8b_8  (), .io_outVec8b_9  (), .io_outVec8b_10 (), .io_outVec8b_11 (),
    .io_outVec8b_12 (), .io_outVec8b_13 (), .io_outVec8b_14 (), .io_outVec8b_15 (),
    .io_outVec16b_0 (), .io_outVec16b_1 (), .io_outVec16b_2 (), .io_outVec16b_3 (),
    .io_outVec16b_4 (), .io_outVec16b_5 (), .io_outVec16b_6 (), .io_outVec16b_7 (),
    .io_outVec32b_0 (), .io_outVec32b_1 (), .io_outVec32b_2 (), .io_outVec32b_3 (),
    .io_outVec64b_0 (old_64[0]),
    .io_outVec64b_1 (old_64[1])
  );

  logic       res_widening;
  logic [1:0] fma_fp_format;            // 结果格式（加宽时 vsew+1）
  assign res_widening  = in_fuOpType[4];
  assign fma_fp_format = res_widening ? 2'(in_vsew + 2'd1) : in_vsew;

  logic [63:0] fma_result [2];
  logic [19:0] fma_fflags [2];
  VectorFloatFMA vfmas_0 (
    .clock           (clock),
    .reset           (reset),
    .io_fire         (in_valid),
    .io_fp_a         (vs2_64[0]),
    .io_fp_b         (vs1_64[0]),
    .io_fp_c         (old_64[0]),
    .io_uop_idx      (in_vuopIdx[0]),
    .io_widen_a      ({vs2_32[2], vs2_32[0]}),
    .io_widen_b      ({vs1_32[2], vs1_32[0]}),
    .io_round_mode   (frm),
    .io_fp_format    (fma_fp_format),
    .io_op_code      (in_fuOpType[3:0]),
    .io_res_widening (res_widening),
    .io_fp_result    (fma_result[0]),
    .io_fflags       (fma_fflags[0])
  );
  VectorFloatFMA vfmas_1 (
    .clock           (clock),
    .reset           (reset),
    .io_fire         (in_valid),
    .io_fp_a         (vs2_64[1]),
    .io_fp_b         (vs1_64[1]),
    .io_fp_c         (old_64[1]),
    .io_uop_idx      (in_vuopIdx[0]),
    .io_widen_a      ({vs2_32[3], vs2_32[1]}),
    .io_widen_b      ({vs1_32[3], vs1_32[1]}),
    .io_round_mode   (frm),
    .io_fp_format    (fma_fp_format),
    .io_op_code      (in_fuOpType[3:0]),
    .io_res_widening (res_widening),
    .io_fp_result    (fma_result[1]),
    .io_fflags       (fma_fflags[1])
  );

  // ---------------------------------------------------------------------------
  // §3 写回（第 3 级）：Mgu 合并 + 活跃元素的 fflags 合并
  // ---------------------------------------------------------------------------
  logic         s3_widen;
  logic [1:0]   out_eew;
  logic [2:0]   out_vlmul_fix;
  logic [127:0] mask_to_mgu;
  assign s3_widen      = s3_fuOpType[4];
  assign out_eew       = s3_widen ? 2'(s3_vsew + 2'd1)  : s3_vsew;
  assign out_vlmul_fix = s3_widen ? 3'(s3_vlmul + 3'd1) : s3_vlmul;
  assign mask_to_mgu   = s3_vm ? '1 : s3_v0;

  Mgu mgu (
    .io_in_vd           ({fma_result[1], fma_result[0]}),
    .io_in_oldVd        (s3_oldVd),
    .io_in_mask         (mask_to_mgu),
    .io_in_info_ta      (s3_vta),
    .io_in_info_ma      (s3_vma),
    .io_in_info_vl      (s3_vl),
    .io_in_info_vstart  (s3_vstart),
    .io_in_info_eew     (out_eew),
    .io_in_info_vdIdx   (s3_vuopIdx[2:0]),
    .io_in_info_narrow  (s3_isNarrow),
    .io_in_info_dstMask (s3_isDstMask),
    .io_out_vd          (out_res_data),
    .io_out_active      ()
  );

  logic [7:0]  fflags_en;
  logic [39:0] all_fflags;       // 8 组：{高 64 位的 4 组, 低 64 位的 4 组}
  xs_VecFflagsElemMask u_fflags_en (
    .eew        (out_eew),
    .vlmul_frac (s3_vlmul[2]),
    .vlmul_fix  (out_vlmul_fix),
    .uop_idx    (s3_vuopIdx[2:0]),
    .vl         (s3_vl),
    .mask       (mask_to_mgu),
    .elem_en    (fflags_en)
  );
  assign all_fflags = {fma_fflags[1], fma_fflags[0]};
  always_comb begin
    out_res_fflags = 5'h0;
    for (int k = 0; k < 8; k++)
      if (fflags_en[k]) out_res_fflags |= all_fflags[5*k +: 5];
  end

  assign out_valid        = s3_valid & vldThisFu[LAT];
  assign out_robIdx_flag  = s3_robIdx_flag;
  assign out_robIdx_value = s3_robIdx_value;
  assign out_pdest        = s3_pdest;
  assign out_vecWen       = s3_vecWen;
  assign out_v0Wen        = s3_v0Wen;
  assign out_fpu_wflags   = s3_fpu_wflags;
  assign out_perf         = perfVec[LAT];
  assign out_seq          = seqNumVec[LAT];
endmodule

// -----------------------------------------------------------------------------
// VFMA —— golden 同名 wrapper：端口逐位同名，打包结构体后例化核
// -----------------------------------------------------------------------------
module VFMA
  import vfma_pkg::*;
(
  input  logic           clock,
  input  logic           reset,
  output logic           io_in_ready,
  input  logic           io_in_valid,
  input  logic [8:0]     io_in_bits_ctrl_fuOpType,
  input  logic [1:0]     io_in_bits_ctrl_vpu_vsew,
  input  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx,
  input  logic [8:0]     io_in_bits_ctrlPipe_3_fuOpType,
  input  logic           io_in_bits_ctrlPipe_3_robIdx_flag,
  input  logic [7:0]     io_in_bits_ctrlPipe_3_robIdx_value,
  input  logic [7:0]     io_in_bits_ctrlPipe_3_pdest,
  input  logic           io_in_bits_ctrlPipe_3_vecWen,
  input  logic           io_in_bits_ctrlPipe_3_v0Wen,
  input  logic           io_in_bits_ctrlPipe_3_fpu_wflags,
  input  logic           io_in_bits_ctrlPipe_3_vpu_vma,
  input  logic           io_in_bits_ctrlPipe_3_vpu_vta,
  input  logic [1:0]     io_in_bits_ctrlPipe_3_vpu_vsew,
  input  logic [2:0]     io_in_bits_ctrlPipe_3_vpu_vlmul,
  input  logic           io_in_bits_ctrlPipe_3_vpu_vm,
  input  logic [7:0]     io_in_bits_ctrlPipe_3_vpu_vstart,
  input  logic [6:0]     io_in_bits_ctrlPipe_3_vpu_vuopIdx,
  input  logic           io_in_bits_ctrlPipe_3_vpu_isNarrow,
  input  logic           io_in_bits_ctrlPipe_3_vpu_isDstMask,
  input  logic           io_in_bits_validPipe_3,
  input  logic [127:0]   io_in_bits_data_src_2,
  input  logic [127:0]   io_in_bits_data_src_1,
  input  logic [127:0]   io_in_bits_data_src_0,
  input  logic [7:0]     io_in_bits_dataPipe_3_src_4,
  input  logic [127:0]   io_in_bits_dataPipe_3_src_3,
  input  logic [127:0]   io_in_bits_dataPipe_3_src_2,
  input  logic           io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0]    io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0]    io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0]    io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0]    io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0]     io_in_bits_debug_seqNum_uopIdx,
  input  logic           io_out_ready,
  output logic           io_out_valid,
  output logic           io_out_bits_ctrl_robIdx_flag,
  output logic [7:0]     io_out_bits_ctrl_robIdx_value,
  output logic [7:0]     io_out_bits_ctrl_pdest,
  output logic           io_out_bits_ctrl_vecWen,
  output logic           io_out_bits_ctrl_v0Wen,
  output logic           io_out_bits_ctrl_fpu_wflags,
  output logic [127:0]   io_out_bits_res_data,
  output logic [4:0]     io_out_bits_res_fflags,
  output logic           io_out_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0]    io_out_bits_perfDebugInfo_renameTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_dispatchTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_enqRsTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_selectTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_issueTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_writebackTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0]    io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0]    io_out_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0]    io_out_bits_debug_seqNum_seqNum,
  output logic [7:0]     io_out_bits_debug_seqNum_uopIdx,
  input  logic [2:0]     io_frm
);
  perf_dbg_t in_perf, out_perf;
  seq_num_t  in_seq, out_seq;
  assign in_perf = '{
    eliminatedMove:         io_in_bits_perfDebugInfo_eliminatedMove,
    renameTime:             io_in_bits_perfDebugInfo_renameTime,
    dispatchTime:           io_in_bits_perfDebugInfo_dispatchTime,
    enqRsTime:              io_in_bits_perfDebugInfo_enqRsTime,
    selectTime:             io_in_bits_perfDebugInfo_selectTime,
    issueTime:              io_in_bits_perfDebugInfo_issueTime,
    writebackTime:          io_in_bits_perfDebugInfo_writebackTime,
    runahead_checkpoint_id: io_in_bits_perfDebugInfo_runahead_checkpoint_id,
    tlbFirstReqTime:        io_in_bits_perfDebugInfo_tlbFirstReqTime,
    tlbRespTime:            io_in_bits_perfDebugInfo_tlbRespTime
  };
  assign in_seq = '{seqNum: io_in_bits_debug_seqNum_seqNum, uopIdx: io_in_bits_debug_seqNum_uopIdx};

  xs_VFMA_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_fuOpType      (io_in_bits_ctrl_fuOpType),
    .in_vsew          (io_in_bits_ctrl_vpu_vsew),
    .in_vuopIdx       (io_in_bits_ctrl_vpu_vuopIdx),
    .in_oldVd         (io_in_bits_data_src_2),
    .in_vs2           (io_in_bits_data_src_1),
    .in_vs1           (io_in_bits_data_src_0),
    .in_perf          (in_perf),
    .in_seq           (in_seq),
    .frm              (io_frm),
    .s3_fuOpType      (io_in_bits_ctrlPipe_3_fuOpType),
    .s3_robIdx_flag   (io_in_bits_ctrlPipe_3_robIdx_flag),
    .s3_robIdx_value  (io_in_bits_ctrlPipe_3_robIdx_value),
    .s3_pdest         (io_in_bits_ctrlPipe_3_pdest),
    .s3_vecWen        (io_in_bits_ctrlPipe_3_vecWen),
    .s3_v0Wen         (io_in_bits_ctrlPipe_3_v0Wen),
    .s3_fpu_wflags    (io_in_bits_ctrlPipe_3_fpu_wflags),
    .s3_vma           (io_in_bits_ctrlPipe_3_vpu_vma),
    .s3_vta           (io_in_bits_ctrlPipe_3_vpu_vta),
    .s3_vsew          (io_in_bits_ctrlPipe_3_vpu_vsew),
    .s3_vlmul         (io_in_bits_ctrlPipe_3_vpu_vlmul),
    .s3_vm            (io_in_bits_ctrlPipe_3_vpu_vm),
    .s3_vstart        (io_in_bits_ctrlPipe_3_vpu_vstart),
    .s3_vuopIdx       (io_in_bits_ctrlPipe_3_vpu_vuopIdx),
    .s3_isNarrow      (io_in_bits_ctrlPipe_3_vpu_isNarrow),
    .s3_isDstMask     (io_in_bits_ctrlPipe_3_vpu_isDstMask),
    .s3_valid         (io_in_bits_validPipe_3),
    .s3_vl            (io_in_bits_dataPipe_3_src_4),
    .s3_v0            (io_in_bits_dataPipe_3_src_3),
    .s3_oldVd         (io_in_bits_dataPipe_3_src_2),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_robIdx_flag  (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value (io_out_bits_ctrl_robIdx_value),
    .out_pdest        (io_out_bits_ctrl_pdest),
    .out_vecWen       (io_out_bits_ctrl_vecWen),
    .out_v0Wen        (io_out_bits_ctrl_v0Wen),
    .out_fpu_wflags   (io_out_bits_ctrl_fpu_wflags),
    .out_res_data     (io_out_bits_res_data),
    .out_res_fflags   (io_out_bits_res_fflags),
    .out_perf         (out_perf),
    .out_seq          (out_seq)
  );

  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_perf.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_perf.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_perf.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_perf.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_perf.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_perf.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_perf.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_perf.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_perf.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_perf.tlbRespTime;
  assign io_out_bits_debug_seqNum_seqNum                  = out_seq.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx                  = out_seq.uopIdx;
endmodule
