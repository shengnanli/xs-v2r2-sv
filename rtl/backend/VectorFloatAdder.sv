// =============================================================================
// VectorFloatAdder.sv —— 向量浮点加法单元（64 位一组：1×f64 / 2×f32 / 4×f16 并行，两拍流水）
//
// 在哪一层：向量浮点 ALU 外壳 VFAlu（每个 VFAlu 两份，各管 128 位向量的一半）的运算核。vfadd/vfsub/vfmin/vfmax/
//   比较/符号注入/fclass/merge/move/归约 以及加宽（vfwadd 等）都在这里。
// 设计源：yunsuan/vector/VectorFloatAdder.scala class VectorFloatAdder（VLEN=128）。
//
// 结构（五条运算 lane + 三个加宽格式化件）：
//   lane 分工（按 64 位里的位置）：
//     U_F64_Widen_0   —— [63:0]  的 f64（或 f32→f64 加宽结果）；
//     U_F32_Mixed_0   —— [31:0]  的 f32，或 [15:0] 的 f16（f16→f32 加宽也在这）；
//     U_F32_Mixed_1   —— [63:32] 的 f32，或 [47:32] 的 f16；
//     U_F16_1/U_F16_3 —— [31:16] / [63:48] 的 f16（纯 f16 lane）。
//   五条 lane 都同时在算，第 1 拍按锁存的结果格式（fp_format_reg）挑出对应 lane 拼成 64 位结果、20 位 fflags。
//   §1 格式化件：U_Widen_Fotmat 给普通加宽指令把 widen_a / widen_b 里的半宽元素换成全宽（uop_idx 选高/低半）；
//      U_Widen_Fotmat_64_fold / _32_fold 给有序归约「折叠」用（把 vs2 高半的 f32 / f16 元素加宽）。
//   §2 折叠（is_fold，归约树的逐级对半折）：fold[0] 把 vs2_fold 高 64 位折下来，fold[1] 折 [63:32]，fold[2] 折 [31:16]；
//      各 lane 的 a 操作数按 Scala 注释里的表从 vs2_fold 取，不折时取 fp_a 对应位段。
//   §3 lane 的掩码 / 归约掩码分配：f16 时 U_F32_Mixed_1 管的是第 2 个 f16 元素位置 → 用 mask[1]、maskForReduction{5,1}；
//      否则（f32）用 mask[2]、maskForReduction{6,2}。（Scala 原样：f16 结果拼位里 U_F32_Mixed_1 给的是 [47:32]。）
//   §4 第 1 拍结果拼接（按 fp_format_reg：1=f16 / 2=f32 / 3=f64，0 = 结果全 0）。
// 怪癖（照 golden）：
//   - 送给 32 位 lane 的格式码是 fp_format - 1（2 位截断）。
//   - 实例名 U_Widen_Fotmat* 的拼写错误照抄（golden 层次名）。
//   - fflags[14:10] 只在 f16 时取 U_F32_Mixed_1（f32 时为 0）；fflags[9:5] 非 f64 时 f32 取 U_F32_Mixed_1、f16 取 U_F16_1，
//     即 f32 时 U_F32_Mixed_1 的标志放在 [9:5] 而不是 [14:10]。
//   - Scala 里的 frs1 / is_frs1 / canonical NaN 输入在本配置未接，firtool 已消掉端口。
// 子模块（实例名与 golden 一致；本仓已签核重写件）：FloatAdderWidenFormat ×3、FloatAdderF32WidenF16MixedPipeline ×2、
//   FloatAdderF64WidenPipeline ×1、FloatAdderF16Pipeline ×2。本层唯一的寄存器是 fp_format_reg（fire 使能、不复位）。
// golden 对照：G1-canonical/golden-rtl/VectorFloatAdder.sv
// =============================================================================
module xs_VectorFloatAdder_core (
  input  logic         clock,
  input  logic         fire,
  input  logic [63:0]  fp_a,              // vs2 的 64 位一组
  input  logic [63:0]  fp_b,              // vs1 的 64 位一组
  input  logic [63:0]  widen_a,           // 加宽指令的半宽源（两个 32 位块拼成）
  input  logic [63:0]  widen_b,
  input  logic [3:0]   mask,              // fmerge 的逐元素选择位
  input  logic         uop_idx,           // 加宽：取半宽源的高半（1）还是低半（0）
  input  logic [2:0]   round_mode,
  input  logic [1:0]   fp_format,         // 结果格式：1=f16 2=f32 3=f64
  input  logic         opb_widening,
  input  logic         res_widening,
  input  logic [4:0]   op_code,
  input  logic [7:0]   mask_for_reduction,
  input  logic         is_vfwredosum,
  input  logic [2:0]   is_fold,           // 归约折叠：bit0 折高 64、bit1 折 [63:32]、bit2 折 [31:16]
  input  logic [127:0] vs2_fold,
  output logic [63:0]  fp_result,
  output logic [19:0]  fflags             // 每 5 位一组 {NV,DZ,OF,UF,NX}
);
  logic       is_sub;
  logic [1:0] lane_fp_format;       // 32 位 lane 的格式码（结果格式 - 1）
  logic       lane_fmt_is_f16;
  assign is_sub          = op_code[0];          // fsub 的编码是 1（fadd 0）
  assign lane_fp_format  = fp_format - 2'd1;
  assign lane_fmt_is_f16 = (lane_fp_format == 2'd1);

  // ---------------------------------------------------------------------------
  // §1 加宽格式化件
  // ---------------------------------------------------------------------------
  logic [31:0] widen_a_f32_0, widen_b_f32_0, widen_a_f32_1, widen_b_f32_1;
  logic [63:0] widen_a_f64, widen_b_f64;
  FloatAdderWidenFormat U_Widen_Fotmat (
    .io_widen_a       (widen_a),
    .io_widen_b       (widen_b),
    .io_uop_idx       (uop_idx),
    .io_widen_a_f32_0 (widen_a_f32_0),
    .io_widen_b_f32_0 (widen_b_f32_0),
    .io_widen_a_f32_1 (widen_a_f32_1),
    .io_widen_b_f32_1 (widen_b_f32_1),
    .io_widen_a_f64   (widen_a_f64),
    .io_widen_b_f64   (widen_b_f64)
  );

  logic [63:0] fold_widen_a_f64;       // vs2_fold 高 64 位里的 f32 → f64（有序加宽归约折叠）
  FloatAdderWidenFormat U_Widen_Fotmat_64_fold (
    .io_widen_a       (vs2_fold[127:64]),
    .io_widen_b       (64'h0),
    .io_uop_idx       (1'b0),
    .io_widen_a_f32_0 (),
    .io_widen_b_f32_0 (),
    .io_widen_a_f32_1 (),
    .io_widen_b_f32_1 (),
    .io_widen_a_f64   (fold_widen_a_f64),
    .io_widen_b_f64   ()
  );

  logic [31:0] fold_widen_a_f32;       // vs2_fold[63:32] 里的 f16 → f32
  FloatAdderWidenFormat U_Widen_Fotmat_32_fold (
    .io_widen_a       ({32'h0, vs2_fold[63:32]}),
    .io_widen_b       (64'h0),
    .io_uop_idx       (1'b0),
    .io_widen_a_f32_0 (fold_widen_a_f32),
    .io_widen_b_f32_0 (),
    .io_widen_a_f32_1 (),
    .io_widen_b_f32_1 (),
    .io_widen_a_f64   (),
    .io_widen_b_f64   ()
  );

  // ---------------------------------------------------------------------------
  // §2 各 lane 的 a 操作数（折叠时从 vs2_fold 取；Mux1H 按位或，与 golden 同）
  // ---------------------------------------------------------------------------
  logic        not_fold;
  logic [63:0] f64_fp_a;
  logic [31:0] f32_0_fp_a, f32_1_fp_a;
  logic [15:0] f16_1_fp_a, f16_3_fp_a;
  assign not_fold   = ~(|is_fold);
  assign f64_fp_a   = is_fold[0] ? vs2_fold[127:64] : fp_a;
  assign f32_0_fp_a = (is_fold[0] ? vs2_fold[95:64]         : 32'h0)
                    | (is_fold[1] ? vs2_fold[63:32]         : 32'h0)
                    | (is_fold[2] ? {16'h0, vs2_fold[31:16]} : 32'h0)
                    | (not_fold   ? fp_a[31:0]              : 32'h0);
  assign f32_1_fp_a = (is_fold[0] ? vs2_fold[127:96] : 32'h0)
                    | (not_fold   ? fp_a[63:32]      : 32'h0);
  assign f16_1_fp_a = is_fold[1] ? vs2_fold[63:48] : (is_fold[0] ? vs2_fold[95:80] : fp_a[31:16]);
  assign f16_3_fp_a = is_fold[0] ? vs2_fold[127:112] : fp_a[63:48];

  // ---------------------------------------------------------------------------
  // §3 五条运算 lane
  // ---------------------------------------------------------------------------
  logic [31:0] f32_0_fp_c, f32_1_fp_c;
  logic [63:0] f64_fp_c;
  logic [15:0] f16_1_fp_c, f16_3_fp_c;
  logic [4:0]  f32_0_fflags, f32_1_fflags, f64_fflags, f16_1_fflags, f16_3_fflags;

  FloatAdderF32WidenF16MixedPipeline U_F32_Mixed_0 (
    .clock               (clock),
    .io_fire             (fire),
    .io_fp_a             (f32_0_fp_a),
    .io_fp_b             (fp_b[31:0]),
    .io_widen_a          (is_fold[1] ? fold_widen_a_f32 : widen_a_f32_0),
    .io_widen_b          (widen_b_f32_0),
    .io_fp_c             (f32_0_fp_c),
    .io_is_sub           (is_sub),
    .io_mask             (mask[0]),
    .io_round_mode       (round_mode),
    .io_fflags           (f32_0_fflags),
    .io_fp_format        (lane_fp_format),
    .io_opb_widening     (opb_widening),
    .io_res_widening     (res_widening),
    .io_op_code          (op_code),
    .io_maskForReduction ({mask_for_reduction[4], mask_for_reduction[0]}),
    .io_is_vfwredosum    (is_vfwredosum)
  );

  FloatAdderF32WidenF16MixedPipeline U_F32_Mixed_1 (
    .clock               (clock),
    .io_fire             (fire),
    .io_fp_a             (f32_1_fp_a),
    .io_fp_b             (fp_b[63:32]),
    .io_widen_a          (widen_a_f32_1),
    .io_widen_b          (widen_b_f32_1),
    .io_fp_c             (f32_1_fp_c),
    .io_is_sub           (is_sub),
    .io_mask             (lane_fmt_is_f16 ? mask[1] : mask[2]),
    .io_round_mode       (round_mode),
    .io_fflags           (f32_1_fflags),
    .io_fp_format        (lane_fp_format),
    .io_opb_widening     (opb_widening),
    .io_res_widening     (res_widening),
    .io_op_code          (op_code),
    .io_maskForReduction (lane_fmt_is_f16 ? {mask_for_reduction[5], mask_for_reduction[1]}
                                          : {mask_for_reduction[6], mask_for_reduction[2]}),
    .io_is_vfwredosum    (is_vfwredosum)
  );

  FloatAdderF64WidenPipeline U_F64_Widen_0 (
    .clock               (clock),
    .io_fire             (fire),
    .io_fp_a             (f64_fp_a),
    .io_fp_b             (fp_b),
    .io_widen_a          (is_fold[0] ? fold_widen_a_f64 : widen_a_f64),
    .io_widen_b          (widen_b_f64),
    .io_fp_c             (f64_fp_c),
    .io_mask             (mask[0]),
    .io_is_sub           (is_sub),
    .io_round_mode       (round_mode),
    .io_fflags           (f64_fflags),
    .io_opb_widening     (opb_widening),
    .io_res_widening     (res_widening),
    .io_op_code          (op_code),
    .io_maskForReduction ({mask_for_reduction[4], mask_for_reduction[0]}),
    .io_is_vfwredosum    (is_vfwredosum)
  );

  FloatAdderF16Pipeline U_F16_1 (
    .clock               (clock),
    .io_fire             (fire),
    .io_fp_a             (f16_1_fp_a),
    .io_fp_b             (fp_b[31:16]),
    .io_fp_c             (f16_1_fp_c),
    .io_is_sub           (is_sub),
    .io_mask             (mask[1]),
    .io_round_mode       (round_mode),
    .io_fflags           (f16_1_fflags),
    .io_op_code          (op_code),
    .io_maskForReduction ({mask_for_reduction[5], mask_for_reduction[1]})
  );

  FloatAdderF16Pipeline U_F16_3 (
    .clock               (clock),
    .io_fire             (fire),
    .io_fp_a             (f16_3_fp_a),
    .io_fp_b             (fp_b[63:48]),
    .io_fp_c             (f16_3_fp_c),
    .io_is_sub           (is_sub),
    .io_mask             (mask[3]),
    .io_round_mode       (round_mode),
    .io_fflags           (f16_3_fflags),
    .io_op_code          (op_code),
    .io_maskForReduction ({mask_for_reduction[7], mask_for_reduction[3]})
  );

  // ---------------------------------------------------------------------------
  // §4 第 1 拍：按锁存的结果格式挑 lane 拼结果
  // ---------------------------------------------------------------------------
  logic [1:0] fp_format_reg;        // golden fp_format_reg：fire 使能，不复位
  always_ff @(posedge clock) begin
    if (fire) fp_format_reg <= fp_format;
  end

  logic res_is_f16, res_is_f32, res_is_f64;
  assign res_is_f16 = (fp_format_reg == 2'd1);
  assign res_is_f32 = (fp_format_reg == 2'd2);
  assign res_is_f64 = (fp_format_reg == 2'd3);

  assign fp_result = (res_is_f16 ? {f16_3_fp_c, f32_1_fp_c[15:0], f16_1_fp_c, f32_0_fp_c[15:0]} : 64'h0)
                   | (res_is_f32 ? {f32_1_fp_c, f32_0_fp_c}                                     : 64'h0)
                   | (res_is_f64 ? f64_fp_c                                                     : 64'h0);
  assign fflags[19:15] = res_is_f16 ? f16_3_fflags : 5'h0;
  assign fflags[14:10] = res_is_f16 ? f32_1_fflags : 5'h0;
  assign fflags[9:5]   = res_is_f64 ? 5'h0 : (res_is_f32 ? f32_1_fflags : f16_1_fflags);
  assign fflags[4:0]   = res_is_f64 ? f64_fflags : f32_0_fflags;
endmodule

module VectorFloatAdder (
  input  logic         clock,
  input  logic         io_fire,
  input  logic [63:0]  io_fp_a,
  input  logic [63:0]  io_fp_b,
  input  logic [63:0]  io_widen_a,
  input  logic [63:0]  io_widen_b,
  input  logic [3:0]   io_mask,
  input  logic         io_uop_idx,
  input  logic [2:0]   io_round_mode,
  input  logic [1:0]   io_fp_format,
  input  logic         io_opb_widening,
  input  logic         io_res_widening,
  input  logic [4:0]   io_op_code,
  input  logic [7:0]   io_maskForReduction,
  input  logic         io_is_vfwredosum,
  input  logic [2:0]   io_is_fold,
  input  logic [127:0] io_vs2_fold,
  output logic [63:0]  io_fp_result,
  output logic [19:0]  io_fflags
);
  xs_VectorFloatAdder_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .widen_a            (io_widen_a),
    .widen_b            (io_widen_b),
    .mask               (io_mask),
    .uop_idx            (io_uop_idx),
    .round_mode         (io_round_mode),
    .fp_format          (io_fp_format),
    .opb_widening       (io_opb_widening),
    .res_widening       (io_res_widening),
    .op_code            (io_op_code),
    .mask_for_reduction (io_maskForReduction),
    .is_vfwredosum      (io_is_vfwredosum),
    .is_fold            (io_is_fold),
    .vs2_fold           (io_vs2_fold),
    .fp_result          (io_fp_result),
    .fflags             (io_fflags)
  );
endmodule
