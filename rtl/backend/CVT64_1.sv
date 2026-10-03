// CVT64_1.sv —— 向量浮点转换 64 位通道的总装（yunsuan CVT64，isVectorCvt=true 实例，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvt 把 64 位源拆成 4 条通道，第 0 条（唯一能处理 64 位元素的那条）经 VCVT
//   壳进到这里。本层不做运算，只把同一组输入同拍送给三个子单元，第 2 拍末按操作类型三选一：
//     FP_INCVT  —— 源是浮点：f2i、f2f 变宽/变窄（含 cross：f16<->f64 的标量用法）；
//     INT2FP    —— 源是整数：i2f；
//     Estimate7 —— vfrec7 / vfrsqrt7。
// 操作类型由 opType 位段直接读出（yunsuan VfcvtType）：[7]=源是浮点 [6]=目的是浮点
//   [5]=估算类 [4:3]=宽度变化（01 widen / 10 narrow / 11 cross）。
// 本实例的三个标量专用输入（isFpToVecInst / isFround / isFcvtmod）在 VectorCvt 里恒接 0，
//   firtool 已把它们连同 fround/fcvtmod 的选择位、「标量转向量的规范 NaN」通路一起消掉；
//   这里照此只写向量用法，并把三个常 0 直接接给 FP_INCVT。
// 时序：s1 = fire 打一拍（各类型标志，带复位）；s2 = 再打一拍（fireReg_last_r 使能，不复位），
//   与三个子单元的结果寄存器同拍有效。三路选择是 Mux1H（与门后按位或）。
// 子模块：FP_INCVT（golden 原件，PROVEN_IN_CONE，两侧同源）、INT2FP、Estimate7（本 lane 重写）。
// golden 对照：G1-canonical/golden-rtl/CVT64_1.sv
// =============================================================================

module xs_CVT64_1_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] src,
  input  logic [7:0]  op_type,
  input  logic [2:0]  rm_in,
  input  logic [3:0]  in_width_1h,
  input  logic [3:0]  out_width_1h,
  output logic [63:0] result_out,
  output logic [4:0]  fflags_out
);

  // ===========================================================================
  // §0 第 0 拍：从 opType 读出操作类型
  // ===========================================================================
  logic in_is_fp, out_is_fp, is_widen, is_narrow, is_cross;
  assign in_is_fp  = op_type[7];
  assign out_is_fp = op_type[6];
  assign is_widen  = ~op_type[4] & op_type[3];
  assign is_narrow = op_type[4] & ~op_type[3];
  assign is_cross  = op_type[4] & op_type[3];   // f16<->f64 跨两档（只看目的格式区分方向）

  // ===========================================================================
  // §1 s1：类型标志（fire 使能，异步复位）
  // ===========================================================================
  logic fireReg_last_r;
  logic isFpWiden;        // f2f 变宽
  logic isFpNarrow;       // f2f 变窄
  logic isFp2Int;         // 目的是整数（源必是浮点）
  logic isFpCrossHigh;    // f2f 跨档到 f64
  logic isFpCrossLow;     // f2f 跨档到 f16
  logic s1_isInt2Fp;      // 源是整数
  logic s1_isEstimate7;   // 估算类

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r <= 1'b0;
      isFpWiden      <= 1'b0;
      isFpNarrow     <= 1'b0;
      isFp2Int       <= 1'b0;
      isFpCrossHigh  <= 1'b0;
      isFpCrossLow   <= 1'b0;
      s1_isInt2Fp    <= 1'b0;
      s1_isEstimate7 <= 1'b0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        isFpWiden      <= in_is_fp & out_is_fp & is_widen;
        isFpNarrow     <= in_is_fp & out_is_fp & is_narrow;
        isFp2Int       <= ~out_is_fp;
        isFpCrossHigh  <= in_is_fp & out_is_fp & is_cross & (out_is_fp & out_width_1h[3]);
        isFpCrossLow   <= in_is_fp & out_is_fp & is_cross & (out_is_fp & out_width_1h[1]);
        s1_isInt2Fp    <= ~in_is_fp;
        s1_isEstimate7 <= op_type[5];
      end
    end
  end

  // ===========================================================================
  // §2 s2：与子单元结果同拍的选择位（fireReg_last_r 使能，不复位）
  // ===========================================================================
  logic s2_isInt2Fp;
  logic s2_isEstimate7;
  logic s2_isFPsrc;       // 结果取 FP_INCVT（浮点源的各类转换）

  always_ff @(posedge clock) begin
    if (fireReg_last_r) begin
      s2_isInt2Fp    <= s1_isInt2Fp;
      s2_isEstimate7 <= s1_isEstimate7;
      s2_isFPsrc     <= isFpWiden | isFpNarrow | isFpCrossHigh | isFpCrossLow | isFp2Int;
    end
  end

  // ===========================================================================
  // §3 三个子单元（同拍收同一组输入）与第 2 拍末的三选一
  // ===========================================================================
  logic [63:0] fpcvt_result, int2fp_result, est7_result;
  logic [4:0]  fpcvt_fflags, int2fp_fflags, est7_fflags;

  FP_INCVT fpcvt (
    .clock            (clock),
    .reset            (reset),
    .io_fire          (fire),
    .io_src           (src),
    .io_opType        (op_type),
    .io_rm            (rm_in),
    .io_input1H       (in_width_1h),
    .io_output1H      (out_width_1h),
    .io_isFpToVecInst (1'b0),
    .io_isFround      (2'b00),
    .io_isFcvtmod     (1'b0),
    .io_result        (fpcvt_result),
    .io_fflags        (fpcvt_fflags)
  );

  INT2FP int2fp (
    .clock       (clock),
    .reset       (reset),
    .io_fire     (fire),
    .io_src      (src),
    .io_opType   (op_type),
    .io_rm       (rm_in),
    .io_input1H  (in_width_1h),
    .io_output1H (out_width_1h),
    .io_result   (int2fp_result),
    .io_fflags   (int2fp_fflags)
  );

  Estimate7 estmate7 (
    .clock       (clock),
    .reset       (reset),
    .io_fire     (fire),
    .io_src      (src),
    .io_opType   (op_type),
    .io_rm       (rm_in),
    .io_input1H  (in_width_1h),
    .io_output1H (out_width_1h),
    .io_result   (est7_result),
    .io_fflags   (est7_fflags)
  );

  assign result_out = (s2_isInt2Fp    ? int2fp_result : 64'h0)
                    | (s2_isFPsrc     ? fpcvt_result  : 64'h0)
                    | (s2_isEstimate7 ? est7_result   : 64'h0);
  assign fflags_out = (s2_isInt2Fp    ? int2fp_fflags : 5'h0)
                    | (s2_isFPsrc     ? fpcvt_fflags  : 5'h0)
                    | (s2_isEstimate7 ? est7_fflags   : 5'h0);

endmodule

module CVT64_1(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [2:0]  io_rm,
  input  [3:0]  io_input1H,
  input  [3:0]  io_output1H,
  output [63:0] io_result,
  output [4:0]  io_fflags
);

  xs_CVT64_1_core u_core (
    .clock        (clock),
    .reset        (reset),
    .fire         (io_fire),
    .src          (io_src),
    .op_type      (io_opType),
    .rm_in        (io_rm),
    .in_width_1h  (io_input1H),
    .out_width_1h (io_output1H),
    .result_out   (io_result),
    .fflags_out   (io_fflags)
  );

endmodule
