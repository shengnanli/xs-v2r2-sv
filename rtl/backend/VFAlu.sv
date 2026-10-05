// =============================================================================
// VFAlu.sv —— 向量浮点 ALU 功能单元外壳（vfadd/vfsub/vfmin/vfmax/比较/符号注入/vfclass/vfmerge/vfmv/归约/加宽，1 拍流水）
//
// 在哪一层：ExeUnit 里的向量浮点加法类 FU。一条 uop 的 128 位向量拆成低 / 高两个 64 位 lane，各交给一个 VectorFloatAdder；
//   结果在第 1 级按 RVV 的 vstart / vl / 掩码 / vta / vma 语义经 Mgu 合并（比较类结果是掩码，再经 Mgtu），fflags 只合并「该计」的元素。
//   归约（vfredusum / vfredmax / vfredmin / vfredosum / vfwredosum）由多个 uop 组成：先逐寄存器两两合并，再「折叠」（fold，
//   把寄存器高半对半折到低半），最后一个 uop 与标量 vs1[0] 合并——本外壳负责每个 uop 的掩码挑选、vl 修正、旧 vd 移位与 fflags 选择。
//   Scala：VFAlu extends VecPipedFuncUnit（第 0 / 1 级控制与数据由发射级预打好，从 ctrlPipe_0/1、dataPipe_0/1 进来）。
//
// 数据流：
//   §1 valid / 反压（LAT=1）；调试信息搬 1 级。
//   §2 第 0 级掩码：srcMask = vm ? 全 1 : v0。
//      · 普通指令：按 SEW 把本 uop 的掩码位右移出来，lane i 拿自己那几个元素的位（vfmerge 的选择位）；vfmv.f.s / vfmv.s.f 的
//        选择位是「vuopIdx 是否为 0」。
//      · 归约：先用 vl 截掉 vl 之外的掩码位，再按 uop 右移，然后按「有序归约 / 首组 uop / 是否折叠」三分支挑出每个 lane 两个
//        操作数（低 4 位给 vs2、高 4 位给 vs1）各自的有效位（genMaskForReduction）；有序归约每拍只做一个元素，只留第 0 位。
//   §3 两个 VectorFloatAdder：fire = in_valid；a = vs2 半边、b = vs1 半边；加宽源取同 lane 的 32 位块对；格式 = 加宽 ? vsew+1 : vsew；
//      op_code = fuOpType[4:0]，fuOpType[5] = 结果加宽、[6] = 只 b 加宽；折叠标志与整个 vs2 一起送进去。
//   §4 第 0 级寄存器（in.fire 使能，名字同 golden）：existMaskReg（vl 内是否有活跃掩码）、vs1Reg（无序归约全被掩码时的结果）、
//      outWiden、outVlFix（Mgu 用的 vl：vfmv.f.s → 1；vfmv.s.f → vl!=0；归约 → 有序 / 最后一个 uop 为 1，否则一整寄存器的元素数）、
//      allVmZero（v0 低 64 位第一个 1 的位置 >= vl，即 vl 内全被掩码）、Mgu 的 eew 与 vdIdx（归约时 vdIdx 恒 0）。
//   §5 第 1 级写回：
//      · 结果：无序归约的最后一个 uop 且 vl 内全被掩码 → vs1Reg，否则两 lane 拼接；比较类（dstMask）结果按 vsew 抽出每元素的
//        比较位，掩码关的位取 vma ? 1 : 旧 vd 对应位，vl 之外的位强制 1；
//      · 旧 vd：有序归约在非最后一个 uop 时要把旧 vd 右移一个元素（vfwredosum 另有折叠时的特殊对齐）；
//      · Mgu：vfmv.f.s 的 ta 当 1；有序归约非最后 uop 的 ta 当 0；vfmv.s.f 的 ma 当 1；
//      · fflags：归约时按「首组 uop / 无序求和非最后 uop / 折叠」选组，其余用 xs_VecFflagsElemMask（vl 内且掩码为 1 的元素）；
//      · vl = 0（且不是 vfmv.f.s）时整个 vd 保持旧值、fflags 为 0。
// ★bug-for-bug 要点★
//   · outEew_s0 的「加宽」位取自第 0 级的 ctrl.fuOpType[5]，而 vsew 取自 ctrlPipe_0（golden 原样）。
//   · 比较位的 vl 判断用 8 位截断加法 elementsComputed + i；归约 uop 计数的 4 位 / 3 位减法按 golden 位宽截断。
//   · Mgu 的 vdIdx 打的是 7 位寄存器（只读低 3 位，[6:3] 两侧都没有读者）。
//   · Scala 里的 canonical NaN（isFpToVecInst）通路在本配置恒 0，firtool 已消掉；fuOpType==0xFF 的 assert 只在非 SYNTHESIS 下存在。
// 子模块（两侧白盒）：VectorFloatAdder vfalus_0 / vfalus_1、VecDataSplitModule vs2Split / vs1Split、Mgu mgu、Mgtu mgtu
//   （实例名与 golden 一致；本仓已签核重写件）；共享辅助件 xs_VecFflagsElemMask（rtl/common）。
// 设计源：src/main/scala/xiangshan/backend/fu/wrapper/VFALU.scala、fu/vector/VecPipedFuncUnit.scala
// golden 对照：G1-canonical/golden-rtl/VFAlu.sv
// =============================================================================

package vfalu_pkg;
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

  // VfaluType 编码（只列本外壳要判的）
  localparam logic [8:0] OP_VFMERGE   = 9'h004;
  localparam logic [8:0] OP_VFMV_F_S  = 9'h011;
  localparam logic [8:0] OP_VFMV_S_F  = 9'h012;
  localparam logic [8:0] OP_VFREDMIN  = 9'h014;
  localparam logic [8:0] OP_VFREDMAX  = 9'h015;
  localparam logic [8:0] OP_VFREDOSUM = 9'h016;
  localparam logic [8:0] OP_VFREDUSUM = 9'h01A;
  localparam logic [8:0] OP_VFWREDOSUM = 9'h036;

  function automatic logic is_reduction(input logic [8:0] fu);
    return fu == OP_VFREDUSUM || fu == OP_VFREDMAX || fu == OP_VFREDMIN || fu == OP_VFREDOSUM || fu == OP_VFWREDOSUM;
  endfunction

  // 第 0 级：vfmerge 的选择位（genMaskForMerge）—— lane i 的 4 位：f16 4 个、f32 2 个、f64 1 个元素
  function automatic logic [3:0] merge_mask(input logic [7:0] m, input logic [1:0] sew, input int lane);
    return (sew == 2'd3 ? {3'b0, m[lane]}           : 4'h0)
         | (sew == 2'd2 ? {2'b0, m[2*lane +: 2]}    : 4'h0)
         | (sew == 2'd1 ? m[4*lane +: 4]            : 4'h0);
  endfunction

  // 第 0 级：归约时 lane i 两个操作数的有效位（genMaskForReduction；低 4 位 = vs2 一侧，高 4 位 = vs1 一侧）
  //   m：vl 截过、按 uop 右移后的掩码低 16 位；red_o：有序归约；first：首组 uop；fold 三位 = {1/8, 1/4, 1/2}
  function automatic logic [7:0] reduction_mask(input logic [15:0] m, input logic [1:0] sew, input int lane,
                                                input logic red_o, input logic first, input logic [2:0] fold);
    logic        f2, f4, f8, is_fold;
    logic [7:0]  f64_unord, f64_ord, f32_unord, f32_ord, f16_unord, f16_ord, f64_fold, f32_fold, f16_fold;
    logic [7:0]  f64_nf, f32_nf, f16_nf, f64_i, f32_i, f16_i, out;
    f2 = fold[0]; f4 = fold[1]; f8 = fold[2];
    is_fold = f2 | f4 | f8;
    // 折叠的首个 uop：vs2 被重排过，用高位（Unorder）；有序归约按原序（Order）
    // ★f64 只有 1/2 折叠一种，Scala 写成单项 Mux1H —— Chisel 的单项 Mux1H 直接返回该项、不按选择位门控★
    f64_unord = {3'b0, m[0], 3'b0, m[1]};
    f64_ord   = {3'b0, m[1], 3'b0, m[0]};
    f32_unord = (f2 ? {2'b0, m[1], m[0], 2'b0, m[3], m[2]} : 8'h0) | (f4 ? {3'b0, m[0], 3'b0, m[1]} : 8'h0);
    f32_ord   = (f2 ? {2'b0, m[3], m[2], 2'b0, m[1], m[0]} : 8'h0) | (f4 ? {3'b0, m[1], 3'b0, m[0]} : 8'h0);
    f16_unord = (f2 ? {m[3:0], m[7:4]} : 8'h0) | (f4 ? {2'b0, m[1], m[0], 2'b0, m[3], m[2]} : 8'h0)
              | (f8 ? {3'b0, m[0], 3'b0, m[1]} : 8'h0);
    f16_ord   = (f2 ? {m[7:4], m[3:0]} : 8'h0) | (f4 ? {2'b0, m[3], m[2], 2'b0, m[1], m[0]} : 8'h0)
              | (f8 ? {3'b0, m[1], 3'b0, m[0]} : 8'h0);
    // 非首组的折叠 uop：固定的有效位样式
    f64_fold  = 8'b0001_0001;                                        // 单项 Mux1H：不门控
    f32_fold  = (f2 ? 8'b0011_0011 : 8'h0) | (f4 ? 8'b0001_0001 : 8'h0);
    f16_fold  = (f2 ? 8'b1111_1111 : 8'h0) | (f4 ? 8'b0011_0011 : 8'h0) | (f8 ? 8'b0001_0001 : 8'h0);
    // 不折叠的首个 uop：lane i 的 vs2 元素 + vs1 元素（vs1 的在 m 的高半）
    f64_nf    = {3'b0, m[lane + 2], 3'b0, m[lane]};
    f32_nf    = {2'b0, m[2*lane + 5 -: 2], 2'b0, m[2*lane + 1 -: 2]};
    f16_nf    = {m[4*lane + 11 -: 4], m[4*lane + 3 -: 4]};
    f64_i = red_o ? (is_fold ? f64_ord : f64_nf) : (first ? (is_fold ? f64_unord : f64_nf) : (is_fold ? f64_fold : 8'hFF));
    f32_i = red_o ? (is_fold ? f32_ord : f32_nf) : (first ? (is_fold ? f32_unord : f32_nf) : (is_fold ? f32_fold : 8'hFF));
    f16_i = red_o ? (is_fold ? f16_ord : f16_nf) : (first ? (is_fold ? f16_unord : f16_nf) : (is_fold ? f16_fold : 8'hFF));
    out   = (sew == 2'd3 ? f64_i : 8'h0) | (sew == 2'd2 ? f32_i : 8'h0) | (sew == 2'd1 ? f16_i : 8'h0);
    return red_o ? {7'h0, out[0]} : out;
  endfunction

  // v0 低 64 位里第一个 1 的位置（全 0 给 64）—— Scala LZD(Reverse(mask))
  function automatic logic [6:0] first_one(input logic [63:0] m);
    for (int k = 0; k < 64; k++) if (m[k]) return 7'(k);
    return 7'd64;
  endfunction
endpackage

// -----------------------------------------------------------------------------
// xs_VFAlu_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VFAlu_core
  import vfalu_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // ---- 第 0 级 ----
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [8:0]   in_fuOpType,
  input  logic [1:0]   in_vsew,
  input  logic [2:0]   in_vlmul,
  input  logic         in_vm,
  input  logic [2:0]   in_fold,            // {isFoldTo1_8, isFoldTo1_4, isFoldTo1_2}
  input  logic [6:0]   in_vuopIdx,
  input  logic [7:0]   in_vl,              // data_src_4
  input  logic [127:0] in_v0,              // data_src_3
  input  logic [127:0] in_vs2,             // data_src_1
  input  logic [127:0] in_vs1,             // data_src_0
  input  perf_dbg_t    in_perf,
  input  seq_num_t     in_seq,
  input  logic [2:0]   frm,
  // ---- 第 0 级的发射级预打拍（ctrlPipe_0 / dataPipe_0）----
  input  logic [8:0]   p0_fuOpType,
  input  logic [1:0]   p0_vsew,
  input  logic [2:0]   p0_vlmul,
  input  logic [6:0]   p0_vuopIdx,
  input  logic [7:0]   p0_vl,
  // ---- 第 1 级（ctrlPipe_1 / dataPipe_1 / validPipe_1）----
  input  logic [8:0]   s1_fuOpType,
  input  logic         s1_robIdx_flag,
  input  logic [7:0]   s1_robIdx_value,
  input  logic [7:0]   s1_pdest,
  input  logic         s1_fpWen,
  input  logic         s1_vecWen,
  input  logic         s1_v0Wen,
  input  logic         s1_fpu_wflags,
  input  logic         s1_vma,
  input  logic         s1_vta,
  input  logic [1:0]   s1_vsew,
  input  logic [2:0]   s1_vlmul,
  input  logic         s1_vm,
  input  logic [7:0]   s1_vstart,
  input  logic [2:0]   s1_fold,            // {isFoldTo1_8, isFoldTo1_4, isFoldTo1_2}
  input  logic [6:0]   s1_vuopIdx,
  input  logic         s1_lastUop,
  input  logic         s1_isNarrow,
  input  logic         s1_isDstMask,
  input  logic         s1_valid,
  input  logic [7:0]   s1_vl,
  input  logic [127:0] s1_v0,
  input  logic [127:0] s1_oldVd,
  // ---- 出口 ----
  input  logic         out_ready,
  output logic         out_valid,
  output logic         out_robIdx_flag,
  output logic [7:0]   out_robIdx_value,
  output logic [7:0]   out_pdest,
  output logic         out_fpWen,
  output logic         out_vecWen,
  output logic         out_v0Wen,
  output logic         out_fpu_wflags,
  output logic [127:0] out_res_data,
  output logic [4:0]   out_res_fflags,
  output perf_dbg_t    out_perf,
  output seq_num_t     out_seq
);
  // ---------------------------------------------------------------------------
  // §1 valid / 反压（LAT=1）；调试信息搬 1 级
  // ---------------------------------------------------------------------------
  logic validVecThisFu_1, rdy0, in_fire;
  assign rdy0     = ~validVecThisFu_1 | out_ready;
  assign in_ready = rdy0;
  assign in_fire  = rdy0 & in_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) validVecThisFu_1 <= 1'b0;
    else       validVecThisFu_1 <= in_valid;                      // 不受 ready 门控（照 golden）
  end

  perf_dbg_t perf_s1;
  seq_num_t  seq_s1;
  always_ff @(posedge clock) begin
    if (in_fire) begin
      perf_s1 <= in_perf;
      seq_s1  <= in_seq;
    end
  end

  // ---------------------------------------------------------------------------
  // §2 第 0 级掩码
  // ---------------------------------------------------------------------------
  logic [127:0] src_mask, vl_mask, src_mask_in_vl;
  logic         red_o, is_scalar_move, first_group_uop;
  logic [5:0]   red_shift, merge_shift;
  logic [15:0]  red_mask_bits;
  logic [7:0]   merge_mask_bits;
  assign src_mask        = in_vm ? '1 : in_v0;
  assign red_o           = (in_fuOpType == OP_VFREDOSUM) || (in_fuOpType == OP_VFWREDOSUM);
  assign is_scalar_move  = (in_fuOpType == OP_VFMV_F_S) || (in_fuOpType == OP_VFMV_S_F);
  // 首组 uop：LMUL<=2 时第 0 个；LMUL=4 时第 0、1 个；LMUL=8 时第 0..3 个（它们两两合并 vs2 的原始寄存器）
  assign first_group_uop = (in_vuopIdx == 7'd0)
                         | ((in_vuopIdx == 7'd1) & (in_vlmul == 3'd2 || in_vlmul == 3'd3))
                         | ((in_vuopIdx == 7'd2 || in_vuopIdx == 7'd3) & (in_vlmul == 3'd3));

  // 归约：vl 之外的掩码位清 0，再按 uop 移到低位（有序归约每个 uop 只吃一个元素，直接按 uop 号移）
  assign vl_mask        = ~('1 << in_vl);
  assign src_mask_in_vl = src_mask & vl_mask;
  always_comb begin
    if (red_o) red_shift = in_vuopIdx[5:0];
    else case (in_vsew)
      2'd1:    red_shift = {in_vuopIdx[1:0], 4'b0};
      2'd2:    red_shift = {1'b0, in_vuopIdx[1:0], 3'b0};
      2'd3:    red_shift = {2'b0, in_vuopIdx[1:0], 2'b0};
      default: red_shift = 6'd0;
    endcase
    case (in_vsew)
      2'd1:    merge_shift = {in_vuopIdx[2:0], 3'b0};
      2'd2:    merge_shift = {1'b0, in_vuopIdx[2:0], 2'b0};
      2'd3:    merge_shift = {2'b0, in_vuopIdx[2:0], 1'b0};
      default: merge_shift = 6'd0;
    endcase
  end
  assign red_mask_bits   = 16'(src_mask_in_vl >> red_shift);
  assign merge_mask_bits = 8'(src_mask >> merge_shift);

  // ---------------------------------------------------------------------------
  // §3 两个向量浮点加法单元（各管 64 位）
  // ---------------------------------------------------------------------------
  logic [31:0] vs2_32 [4], vs1_32 [4];
  logic [63:0] vs2_64 [2], vs1_64 [2];
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

  logic [1:0]  alu_fp_format;
  logic [63:0] alu_result [2];
  logic [19:0] alu_fflags [2];
  assign alu_fp_format = in_fuOpType[5] ? 2'(in_vsew + 2'd1) : in_vsew;

  VectorFloatAdder vfalus_0 (
    .clock               (clock),
    .io_fire             (in_valid),
    .io_fp_a             (vs2_64[0]),
    .io_fp_b             (vs1_64[0]),
    .io_widen_a          ({vs2_32[2], vs2_32[0]}),
    .io_widen_b          ({vs1_32[2], vs1_32[0]}),
    .io_mask             (is_scalar_move ? {3'b0, ~(|in_vuopIdx)} : merge_mask(merge_mask_bits, in_vsew, 0)),
    .io_uop_idx          (in_vuopIdx[0]),
    .io_round_mode       (frm),
    .io_fp_format        (alu_fp_format),
    .io_opb_widening     (in_fuOpType[6]),
    .io_res_widening     (in_fuOpType[5]),
    .io_op_code          (in_fuOpType[4:0]),
    .io_maskForReduction (reduction_mask(red_mask_bits, in_vsew, 0, red_o, first_group_uop, in_fold)),
    .io_is_vfwredosum    (in_fuOpType == OP_VFWREDOSUM),
    .io_is_fold          (in_fold),
    .io_vs2_fold         (in_vs2),
    .io_fp_result        (alu_result[0]),
    .io_fflags           (alu_fflags[0])
  );
  VectorFloatAdder vfalus_1 (
    .clock               (clock),
    .io_fire             (in_valid),
    .io_fp_a             (vs2_64[1]),
    .io_fp_b             (vs1_64[1]),
    .io_widen_a          ({vs2_32[3], vs2_32[1]}),
    .io_widen_b          ({vs1_32[3], vs1_32[1]}),
    .io_mask             (is_scalar_move ? {3'b0, ~(|in_vuopIdx)} : merge_mask(merge_mask_bits, in_vsew, 1)),
    .io_uop_idx          (in_vuopIdx[0]),
    .io_round_mode       (frm),
    .io_fp_format        (alu_fp_format),
    .io_opb_widening     (in_fuOpType[6]),
    .io_res_widening     (in_fuOpType[5]),
    .io_op_code          (in_fuOpType[4:0]),
    .io_maskForReduction (reduction_mask(red_mask_bits, in_vsew, 1, red_o, first_group_uop, in_fold)),
    .io_is_vfwredosum    (in_fuOpType == OP_VFWREDOSUM),
    .io_is_fold          (in_fold),
    .io_vs2_fold         (in_vs2),
    .io_fp_result        (alu_result[1]),
    .io_fflags           (alu_fflags[1])
  );

  // ---------------------------------------------------------------------------
  // §4 第 0 级寄存器（in.fire 使能，无复位，名字同 golden）
  // ---------------------------------------------------------------------------
  logic [1:0] out_eew_s0;
  logic [2:0] fold_last_vlmul;
  logic       p0_is_red, p0_red_o;
  logic [3:0] add_time, num_uop_red;
  logic [2:0] fold_time;
  logic [7:0] vl_fix_s0;
  assign out_eew_s0 = in_fuOpType[5] ? 2'(p0_vsew + 2'd1) : p0_vsew;   // 加宽位取第 0 级 ctrl（golden 原样）
  assign p0_is_red  = is_reduction(p0_fuOpType);
  assign p0_red_o   = (p0_fuOpType == OP_VFREDOSUM) || (p0_fuOpType == OP_VFWREDOSUM);
  // 无序归约的 uop 数 = 寄存器两两合并次数（LMUL 1/2/4/8 → 1/2/4/8，含与标量合并）+ 折叠次数
  assign add_time    = (p0_vlmul == 3'd3) ? 4'd8 : (p0_vlmul == 3'd2) ? 4'd4 : (p0_vlmul == 3'd1) ? 4'd2 : 4'd1;
  always_comb begin
    case (p0_vsew)                      // 折到最后一个元素时的「等效 LMUL」编码：e16 → mf8(5)、e32 → mf4(6)、e64 → mf2(7)
      2'd1:    fold_last_vlmul = 3'd5;
      2'd2:    fold_last_vlmul = 3'd6;
      2'd3:    fold_last_vlmul = 3'd7;
      default: fold_last_vlmul = 3'd0;
    endcase
  end
  // 折叠次数 = 分数 LMUL 时 vlmul − 末档、否则 0 − 末档（3 位截断，golden 原样）
  assign fold_time   = 3'((p0_vlmul[2] ? p0_vlmul : 3'd0) - fold_last_vlmul);
  assign num_uop_red = 4'(add_time + {1'b0, fold_time});
  always_comb begin
    if (p0_fuOpType == OP_VFMV_F_S)      vl_fix_s0 = 8'd1;
    else if (p0_fuOpType == OP_VFMV_S_F) vl_fix_s0 = {7'h0, |p0_vl};
    else if (p0_is_red)
      vl_fix_s0 = ((p0_vuopIdx == {3'h0, 4'(num_uop_red - 4'd1)}) | p0_red_o) ? 8'd1 : {3'h0, 5'h10 >> out_eew_s0};
    else                                 vl_fix_s0 = p0_vl;
  end

  logic         existMaskReg, outWiden, allVmZero;
  logic [127:0] vs1Reg;
  logic [7:0]   outVlFix;
  logic [1:0]   mgu_io_in_info_eew_r;
  logic [6:0]   mgu_io_in_info_vdIdx_r;
  always_ff @(posedge clock) begin
    if (in_fire) begin
      existMaskReg           <= |src_mask_in_vl;
      vs1Reg                 <= in_vs1;
      outWiden               <= in_fuOpType[5];
      outVlFix               <= vl_fix_s0;
      allVmZero              <= {1'b0, first_one(src_mask[63:0])} >= p0_vl;
      mgu_io_in_info_eew_r   <= out_eew_s0;
      mgu_io_in_info_vdIdx_r <= p0_is_red ? 7'd0 : p0_vuopIdx;
    end
  end

  // ---------------------------------------------------------------------------
  // §5 第 1 级写回
  // ---------------------------------------------------------------------------
  logic s1_red_usum, s1_red_ucomp, s1_redo, s1_wredo, s1_is_red, s1_is_fold;
  assign s1_red_usum  = (s1_fuOpType == OP_VFREDUSUM);
  assign s1_red_ucomp = (s1_fuOpType == OP_VFREDMAX) || (s1_fuOpType == OP_VFREDMIN);
  assign s1_redo      = (s1_fuOpType == OP_VFREDOSUM);
  assign s1_wredo     = (s1_fuOpType == OP_VFWREDOSUM);
  assign s1_is_red    = is_reduction(s1_fuOpType);
  assign s1_is_fold   = |s1_fold;

  // 结果：无序归约最后一个 uop、vl 内全被掩码 → 直接给标量 vs1
  logic [127:0] result_data;
  assign result_data = ((s1_red_usum | s1_red_ucomp) & s1_lastUop & ~existMaskReg) ? vs1Reg
                                                                                  : {alu_result[1], alu_result[0]};

  // 元素宽度与 vl 窗口（加宽时 eew / vlmul 各 +1）
  logic [1:0]   out_eew;
  logic [2:0]   out_vlmul_fix;
  logic [4:0]   vl_max;
  logic [127:0] mask_to_mgu;
  logic [7:0]   out_src_mask_rshift, elem_en;
  assign out_eew       = outWiden ? 2'(s1_vsew + 2'd1)  : s1_vsew;
  assign out_vlmul_fix = outWiden ? 3'(s1_vlmul + 3'd1) : s1_vlmul;
  assign vl_max        = 5'h10 >> out_eew;
  // vfmerge / vfmv.s.f / 归约不用 v0 做写回掩码
  assign mask_to_mgu   = ((s1_fuOpType == OP_VFMERGE) | (s1_fuOpType == OP_VFMV_S_F) | s1_is_red | s1_vm) ? '1 : s1_v0;
  assign out_src_mask_rshift = 8'(mask_to_mgu >> 8'(s1_vuopIdx[2:0] * vl_max));

  xs_VecFflagsElemMask u_fflags_en (
    .eew        (out_eew),
    .vlmul_frac (s1_vlmul[2]),
    .vlmul_fix  (out_vlmul_fix),
    .uop_idx    (s1_vuopIdx[2:0]),
    .vl         (outVlFix),
    .mask       (mask_to_mgu),
    .elem_en    (elem_en)
  );

  // 比较类结果：每个元素一位（取结果元素的最低位），按 vsew 抽；掩码关 → vma ? 1 : 旧值；vl 之外 → 1
  logic [7:0] cmp_result, cmp_old_vd, cmp_for_mgu;
  logic [5:0] cmp_old_shift;
  logic [6:0] elems_in_uop;
  logic [7:0] elements_computed;
  always_comb begin
    for (int i = 0; i < 8; i++) begin
      if (i == 0)      cmp_result[i] = result_data[0];
      else if (i < 2)  cmp_result[i] = (s1_vsew == 2'd1 & result_data[i*16]) | (s1_vsew == 2'd2 & result_data[i*32])
                                     | (s1_vsew == 2'd3 & result_data[i*64]);
      else if (i < 4)  cmp_result[i] = (s1_vsew == 2'd1 & result_data[i*16]) | (s1_vsew == 2'd2 & result_data[i*32]);
      else             cmp_result[i] = (s1_vsew == 2'd1) & result_data[i*16];
    end
    case (s1_vsew)
      2'd1:    cmp_old_shift = {s1_vuopIdx[2:0], 3'b0};
      2'd2:    cmp_old_shift = {1'b0, s1_vuopIdx[2:0], 2'b0};
      2'd3:    cmp_old_shift = {2'b0, s1_vuopIdx[2:0], 1'b0};
      default: cmp_old_shift = 6'd0;
    endcase
  end
  assign cmp_old_vd        = 8'(s1_oldVd >> cmp_old_shift);
  assign elems_in_uop      = {3'b0, out_eew == 2'd1, out_eew == 2'd2, out_eew == 2'd3, 1'b0};   // 8 / 4 / 2
  assign elements_computed = 8'(s1_vuopIdx[2:0] * elems_in_uop);
  for (genvar i = 0; i < 8; i++) begin : g_cmp
    assign cmp_for_mgu[i] = (8'(elements_computed + 8'(i)) >= s1_vl)
                          | (out_src_mask_rshift[i] ? cmp_result[i] : (s1_vma | cmp_old_vd[i]));
  end

  // 有序归约（非最后一个 uop）：旧 vd 右移一个元素，作为下一个累加初值所在的位置
  logic [127:0] old_vd_redo, old_vd_wredo, mgu_old_vd;
  logic [3:0]   uvl_max;
  logic [6:0]   num_uop_redosum;
  assign old_vd_redo  = ((s1_vsew == 2'd1) ? (s1_oldVd >> 16) : 128'h0) | ((s1_vsew == 2'd2) ? (s1_oldVd >> 32) : 128'h0)
                      | ((s1_vsew == 2'd3) ? (s1_oldVd >> 64) : 128'h0);
  assign old_vd_wredo = !s1_is_fold ? ((s1_vsew == 2'd1) ? {s1_oldVd[111:16], 32'h0} : {s1_oldVd[95:32], 64'h0})
                      : (s1_vsew == 2'd1) ? ((s1_vuopIdx[2:0] == 3'd1) ? s1_oldVd : (s1_oldVd >> 16))
                                          : ((s1_vuopIdx[1:0] == 2'd1) ? s1_oldVd : (s1_oldVd >> 32));
  assign mgu_old_vd   = (((s1_redo & s1_is_fold) | s1_wredo) & ~s1_lastUop) ? (s1_redo ? old_vd_redo : old_vd_wredo)
                                                                           : s1_oldVd;
  // 有序归约的 uop 总数 = VLMAX（每个 uop 一个元素）；不是最后一个 uop 时 ta 当 0
  assign uvl_max         = (s1_vsew == 2'd3) ? 4'd2 : (s1_vsew == 2'd2) ? 4'd4 : (s1_vsew == 2'd1) ? 4'd8 : 4'd0;
  assign num_uop_redosum = s1_vlmul[2] ? {3'h0, uvl_max >> 2'(2'd0 - s1_vlmul[1:0])} : ({3'h0, uvl_max} << s1_vlmul[1:0]);

  logic         mgu_ta, mgu_ma, not_modify_vd;
  logic [127:0] mgu_out_vd, mgtu_out_vd;
  assign mgu_ta = (s1_fuOpType == OP_VFMV_F_S)
                | (~((s1_redo | s1_wredo) & (s1_vuopIdx != 7'(num_uop_redosum - 7'd1))) & s1_vta);
  assign mgu_ma = (s1_fuOpType == OP_VFMV_S_F) | s1_vma;

  Mgu mgu (
    .io_in_vd           (s1_isDstMask ? {120'h0, cmp_for_mgu} : result_data),
    .io_in_oldVd        (mgu_old_vd),
    .io_in_mask         (mask_to_mgu),
    .io_in_info_ta      (mgu_ta),
    .io_in_info_ma      (mgu_ma),
    .io_in_info_vl      (outVlFix),
    .io_in_info_vstart  (s1_vstart),
    .io_in_info_eew     (mgu_io_in_info_eew_r),
    .io_in_info_vdIdx   (mgu_io_in_info_vdIdx_r[2:0]),
    .io_in_info_narrow  (s1_isNarrow),
    .io_in_info_dstMask (s1_isDstMask),
    .io_out_vd          (mgu_out_vd),
    .io_out_active      ()
  );
  Mgtu mgtu (
    .io_in_vd  (s1_isDstMask ? mgu_out_vd : result_data),
    .io_in_vl  (s1_vl),
    .io_out_vd (mgtu_out_vd)
  );

  // fflags：归约按 uop 角色选组；其余按「vl 内且掩码为 1」的元素
  logic [7:0]  red_fflags_mask, fflags_en;
  logic        first_need_fflags, f32_fold;
  logic [39:0] all_fflags;
  assign f32_fold = s1_fold[0] | s1_fold[1];
  assign red_fflags_mask = ((s1_vsew == 2'd3) ? (s1_fold[0] ? 8'h01 : 8'hFF) : 8'h0)
                         | ((s1_vsew == 2'd2) ? (f32_fold ? {6'h0, s1_fold[0], s1_fold[0] | s1_fold[1]} : 8'hFF) : 8'h0)
                         | ((s1_vsew == 2'd1) ? ((f32_fold | s1_fold[2])
                                                 ? {4'h0, s1_fold[0], s1_fold[0], s1_fold[0] | s1_fold[1],
                                                    s1_fold[0] | s1_fold[1] | s1_fold[2]}
                                                 : 8'hFF) : 8'h0);
  assign first_need_fflags = ((s1_vuopIdx[3:0] == 4'd0)
                              | ((s1_vuopIdx[3:0] == 4'd1) & (s1_vlmul == 3'd2 || s1_vlmul == 3'd3))
                              | ((s1_vuopIdx[3:0] == 4'd2 || s1_vuopIdx[3:0] == 4'd3) & (s1_vlmul == 3'd3)))
                             & s1_red_ucomp;
  assign fflags_en = s1_is_red
    ? {{7{first_need_fflags | (s1_red_usum & ~s1_lastUop)}} & red_fflags_mask[7:1],
       ~allVmZero & ((s1_lastUop & s1_red_ucomp) | first_need_fflags | s1_redo | s1_wredo | s1_red_usum)}
    : elem_en;
  assign all_fflags    = {alu_fflags[1], alu_fflags[0]};
  assign not_modify_vd = (s1_fuOpType != OP_VFMV_F_S) & (s1_vl == 8'd0);
  always_comb begin
    out_res_fflags = 5'h0;
    if (!not_modify_vd)
      for (int k = 0; k < 8; k++)
        if (fflags_en[k]) out_res_fflags |= all_fflags[5*k +: 5];
  end

  assign out_res_data     = not_modify_vd ? s1_oldVd : (s1_isDstMask ? mgtu_out_vd : mgu_out_vd);
  assign out_valid        = s1_valid & validVecThisFu_1;
  assign out_robIdx_flag  = s1_robIdx_flag;
  assign out_robIdx_value = s1_robIdx_value;
  assign out_pdest        = s1_pdest;
  assign out_fpWen        = s1_fpWen;
  assign out_vecWen       = s1_vecWen;
  assign out_v0Wen        = s1_v0Wen;
  assign out_fpu_wflags   = s1_fpu_wflags;
  assign out_perf         = perf_s1;
  assign out_seq          = seq_s1;
endmodule

// -----------------------------------------------------------------------------
// VFAlu —— golden 同名 wrapper：端口逐位同名，打包结构体后例化核
// -----------------------------------------------------------------------------
module VFAlu
  import vfalu_pkg::*;
(
  input  logic           clock,
  input  logic           reset,
  output logic           io_in_ready,
  input  logic           io_in_valid,
  input  logic [8:0]     io_in_bits_ctrl_fuOpType,
  input  logic [1:0]     io_in_bits_ctrl_vpu_vsew,
  input  logic [2:0]     io_in_bits_ctrl_vpu_vlmul,
  input  logic           io_in_bits_ctrl_vpu_vm,
  input  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_2,
  input  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_4,
  input  logic           io_in_bits_ctrl_vpu_fpu_isFoldTo1_8,
  input  logic [6:0]     io_in_bits_ctrl_vpu_vuopIdx,
  input  logic [8:0]     io_in_bits_ctrlPipe_0_fuOpType,
  input  logic [1:0]     io_in_bits_ctrlPipe_0_vpu_vsew,
  input  logic [2:0]     io_in_bits_ctrlPipe_0_vpu_vlmul,
  input  logic [6:0]     io_in_bits_ctrlPipe_0_vpu_vuopIdx,
  input  logic [8:0]     io_in_bits_ctrlPipe_1_fuOpType,
  input  logic           io_in_bits_ctrlPipe_1_robIdx_flag,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_robIdx_value,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_pdest,
  input  logic           io_in_bits_ctrlPipe_1_fpWen,
  input  logic           io_in_bits_ctrlPipe_1_vecWen,
  input  logic           io_in_bits_ctrlPipe_1_v0Wen,
  input  logic           io_in_bits_ctrlPipe_1_fpu_wflags,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vma,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vta,
  input  logic [1:0]     io_in_bits_ctrlPipe_1_vpu_vsew,
  input  logic [2:0]     io_in_bits_ctrlPipe_1_vpu_vlmul,
  input  logic           io_in_bits_ctrlPipe_1_vpu_vm,
  input  logic [7:0]     io_in_bits_ctrlPipe_1_vpu_vstart,
  input  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2,
  input  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4,
  input  logic           io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8,
  input  logic [6:0]     io_in_bits_ctrlPipe_1_vpu_vuopIdx,
  input  logic           io_in_bits_ctrlPipe_1_vpu_lastUop,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isNarrow,
  input  logic           io_in_bits_ctrlPipe_1_vpu_isDstMask,
  input  logic           io_in_bits_validPipe_1,
  input  logic [7:0]     io_in_bits_data_src_4,
  input  logic [127:0]   io_in_bits_data_src_3,
  input  logic [127:0]   io_in_bits_data_src_1,
  input  logic [127:0]   io_in_bits_data_src_0,
  input  logic [7:0]     io_in_bits_dataPipe_0_src_4,
  input  logic [7:0]     io_in_bits_dataPipe_1_src_4,
  input  logic [127:0]   io_in_bits_dataPipe_1_src_3,
  input  logic [127:0]   io_in_bits_dataPipe_1_src_2,
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
  output logic           io_out_bits_ctrl_fpWen,
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

  xs_VFAlu_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_fuOpType      (io_in_bits_ctrl_fuOpType),
    .in_vsew          (io_in_bits_ctrl_vpu_vsew),
    .in_vlmul         (io_in_bits_ctrl_vpu_vlmul),
    .in_vm            (io_in_bits_ctrl_vpu_vm),
    .in_fold          ({io_in_bits_ctrl_vpu_fpu_isFoldTo1_8, io_in_bits_ctrl_vpu_fpu_isFoldTo1_4,
                        io_in_bits_ctrl_vpu_fpu_isFoldTo1_2}),
    .in_vuopIdx       (io_in_bits_ctrl_vpu_vuopIdx),
    .in_vl            (io_in_bits_data_src_4),
    .in_v0            (io_in_bits_data_src_3),
    .in_vs2           (io_in_bits_data_src_1),
    .in_vs1           (io_in_bits_data_src_0),
    .in_perf          (in_perf),
    .in_seq           (in_seq),
    .frm              (io_frm),
    .p0_fuOpType      (io_in_bits_ctrlPipe_0_fuOpType),
    .p0_vsew          (io_in_bits_ctrlPipe_0_vpu_vsew),
    .p0_vlmul         (io_in_bits_ctrlPipe_0_vpu_vlmul),
    .p0_vuopIdx       (io_in_bits_ctrlPipe_0_vpu_vuopIdx),
    .p0_vl            (io_in_bits_dataPipe_0_src_4),
    .s1_fuOpType      (io_in_bits_ctrlPipe_1_fuOpType),
    .s1_robIdx_flag   (io_in_bits_ctrlPipe_1_robIdx_flag),
    .s1_robIdx_value  (io_in_bits_ctrlPipe_1_robIdx_value),
    .s1_pdest         (io_in_bits_ctrlPipe_1_pdest),
    .s1_fpWen         (io_in_bits_ctrlPipe_1_fpWen),
    .s1_vecWen        (io_in_bits_ctrlPipe_1_vecWen),
    .s1_v0Wen         (io_in_bits_ctrlPipe_1_v0Wen),
    .s1_fpu_wflags    (io_in_bits_ctrlPipe_1_fpu_wflags),
    .s1_vma           (io_in_bits_ctrlPipe_1_vpu_vma),
    .s1_vta           (io_in_bits_ctrlPipe_1_vpu_vta),
    .s1_vsew          (io_in_bits_ctrlPipe_1_vpu_vsew),
    .s1_vlmul         (io_in_bits_ctrlPipe_1_vpu_vlmul),
    .s1_vm            (io_in_bits_ctrlPipe_1_vpu_vm),
    .s1_vstart        (io_in_bits_ctrlPipe_1_vpu_vstart),
    .s1_fold          ({io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_8, io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_4,
                        io_in_bits_ctrlPipe_1_vpu_fpu_isFoldTo1_2}),
    .s1_vuopIdx       (io_in_bits_ctrlPipe_1_vpu_vuopIdx),
    .s1_lastUop       (io_in_bits_ctrlPipe_1_vpu_lastUop),
    .s1_isNarrow      (io_in_bits_ctrlPipe_1_vpu_isNarrow),
    .s1_isDstMask     (io_in_bits_ctrlPipe_1_vpu_isDstMask),
    .s1_valid         (io_in_bits_validPipe_1),
    .s1_vl            (io_in_bits_dataPipe_1_src_4),
    .s1_v0            (io_in_bits_dataPipe_1_src_3),
    .s1_oldVd         (io_in_bits_dataPipe_1_src_2),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_robIdx_flag  (io_out_bits_ctrl_robIdx_flag),
    .out_robIdx_value (io_out_bits_ctrl_robIdx_value),
    .out_pdest        (io_out_bits_ctrl_pdest),
    .out_fpWen        (io_out_bits_ctrl_fpWen),
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
