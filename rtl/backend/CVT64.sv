// =============================================================================
// CVT64 —— 标量浮点转换的 64 位总装（yunsuan CVT64，isVectorCvt=false 实例，2 拍流水）
// -----------------------------------------------------------------------------
// 设计源：XiangShan/yunsuan/src/main/scala/yunsuan/vector/VectorConvert/CVT64.scala。
// 在哪一层：标量 FCVT 功能单元 → FPCVT → 本模块。FPCVT 把 isFpToVecInst 恒接 1（标量指令），
//   本实例只例化 FP_INCVT（浮点源的 f2i / f2f / fround / fcvtmod，以及 i2f——标量的 i2f
//   也走 FP_INCVT 的整数侧通路）；向量实例（CVT64_1）才另带 INT2FP / Estimate7。
// 本层自己只做一件事 ——「源不是合法 NaN-box 时给规范 NaN」：
//   标量浮点寄存器里的 f16 / f32 必须是 NaN-box（高位全 1）；若浮点源（opType[7]）的宽度是
//   f16（input1H[1]）而高 48 位不全 1，或是 f32（input1H[2]）而高 32 位不全 1，按 RISC-V
//   规定把源当成规范 NaN：结果直接给「目的格式的规范 NaN / 整数目的的饱和值」，fflags 在
//   整数目的时给 NV（0b10000），fround 时清零，否则沿用 FP_INCVT 的 fflags。
//   规范值表（与目的格式 one-hot 对应，按位或成一个 64 位）：
//     f64 0x7FF8_0000_0000_0000   f32 0x7FC0_0000   f16 0x7E00
//     u32/u64 全 1                s32 0x7FFF_FFFF   s64 0x7FFF_FFFF_FFFF_FFFF
// 时序（与 FP_INCVT 的两级寄存器同拍）：
//   s1 = fire 打一拍：目的格式标志、NaN-box 判定（不复位）；isFroundReg 带复位；
//   s2 = 再打一拍（fireReg 使能 = GatedValidRegNext(fire)，带复位）：选择位与规范值（不复位）。
//   firtool 把只在向量实例用到的 isFpWiden / isFpNarrow / s1_isInt2Fp 等寄存器全部消掉了，
//   这里也只写标量实例真正读到的那几个。寄存器名与 Scala / golden 同名（便于对照，也让
//   FM 在上层（FCVT / ExeUnit_8）按名字直接配上）。
// 子模块：FP_INCVT（已签核重写件，两侧白盒）。
// golden 对照：G1-canonical/golden-rtl/CVT64.sv
// =============================================================================

module xs_CVT64_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] src,
  input  logic [7:0]  op_type,       // [7]=源是浮点 [6]=目的是浮点 [0]=整数有符号
  input  logic [2:0]  rm_in,
  input  logic [3:0]  in_width_1h,   // 源宽度 one-hot：[1]=16 [2]=32 [3]=64
  input  logic [3:0]  out_width_1h,  // 目的宽度 one-hot
  input  logic [1:0]  is_fround,     // {froundnx, fround}
  input  logic        is_fcvtmod,
  output logic [63:0] result_out,
  output logic [4:0]  fflags_out
);

  // ===========================================================================
  // §0 第 0 拍：目的格式 one-hot 与 NaN-box 判定
  // ===========================================================================
  logic out_is_fp, out_signed;
  assign out_is_fp  = op_type[6];
  assign out_signed = op_type[0];

  // 浮点源（标量）的 f16 / f32 不是合法 NaN-box ⇒ 当作规范 NaN 处理
  logic s0_fpCanonicalNAN;
  assign s0_fpCanonicalNAN = op_type[7]
                          & ((in_width_1h[1] & (src[63:16] != 48'hFFFF_FFFF_FFFF))
                           | (in_width_1h[2] & (src[63:32] != 32'hFFFF_FFFF)));

  // ===========================================================================
  // §1 s1：fire 打一拍
  // ===========================================================================
  logic fireReg_last_r;   // GatedValidRegNext(fire)：第 2 级的使能
  logic isFroundReg;      // fround / froundnx（带复位）

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r <= 1'b0;
      isFroundReg    <= 1'b0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire)
        isFroundReg <= |is_fround;
    end
  end

  // 目的格式标志（不复位）
  logic s1_outIsFP;
  logic s1_outIsF64, s1_outIsF32, s1_outIsF16;
  logic s1_outIsU32, s1_outIsS32, s1_outIsU64, s1_outIsS64;
  logic s1_fpCanonicalNAN;

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_outIsFP        <= out_is_fp;
      s1_outIsF64       <= out_is_fp & out_width_1h[3];
      s1_outIsF32       <= out_is_fp & out_width_1h[2];
      s1_outIsF16       <= out_is_fp & out_width_1h[1];
      s1_outIsU32       <= ~out_is_fp & out_width_1h[2] & ~out_signed;
      s1_outIsS32       <= ~out_is_fp & out_width_1h[2] &  out_signed;
      s1_outIsU64       <= ~out_is_fp & out_width_1h[3] & ~out_signed;
      s1_outIsS64       <= ~out_is_fp & out_width_1h[3] &  out_signed;
      s1_fpCanonicalNAN <= s0_fpCanonicalNAN;
    end
  end

  // 「源是规范 NaN」时的结果：按目的格式取规范值（Mux1H = 各项按位或）
  logic [63:0] s1_resultForfpCanonicalNAN;
  always_comb begin
    s1_resultForfpCanonicalNAN = '0;
    if (s1_outIsF64)               s1_resultForfpCanonicalNAN |= 64'h7FF8_0000_0000_0000;
    if (s1_outIsF32)               s1_resultForfpCanonicalNAN |= 64'h0000_0000_7FC0_0000;
    if (s1_outIsF16)               s1_resultForfpCanonicalNAN |= 64'h0000_0000_0000_7E00;
    if (s1_outIsU32 | s1_outIsU64) s1_resultForfpCanonicalNAN |= 64'hFFFF_FFFF_FFFF_FFFF;
    if (s1_outIsS32)               s1_resultForfpCanonicalNAN |= 64'h0000_0000_7FFF_FFFF;
    if (s1_outIsS64)               s1_resultForfpCanonicalNAN |= 64'h7FFF_FFFF_FFFF_FFFF;
  end

  // ===========================================================================
  // §2 s2：fireReg_last_r 打一拍，与 FP_INCVT 的结果同拍
  // ===========================================================================
  logic        s2_outIsFP;
  logic        s2_fpCanonicalNAN;
  logic        s2_isFround;
  logic [63:0] s2_resultForfpCanonicalNAN;

  always_ff @(posedge clock) begin
    if (fireReg_last_r) begin
      s2_outIsFP                 <= s1_outIsFP;
      s2_fpCanonicalNAN          <= s1_fpCanonicalNAN;
      s2_isFround                <= isFroundReg;
      s2_resultForfpCanonicalNAN <= s1_resultForfpCanonicalNAN;
    end
  end

  // ===========================================================================
  // §3 FP_INCVT 与输出选择
  // ===========================================================================
  logic [63:0] fpcvt_result;
  logic [4:0]  fpcvt_fflags;

  FP_INCVT fpcvt (
    .clock            (clock),
    .reset            (reset),
    .io_fire          (fire),
    .io_src           (src),
    .io_opType        (op_type),
    .io_rm            (rm_in),
    .io_input1H       (in_width_1h),
    .io_output1H      (out_width_1h),
    .io_isFpToVecInst (1'b1),            // 标量实例：FPCVT 恒接 1
    .io_isFround      (is_fround),
    .io_isFcvtmod     (is_fcvtmod),
    .io_result        (fpcvt_result),
    .io_fflags        (fpcvt_fflags)
  );

  assign result_out = s2_fpCanonicalNAN ? s2_resultForfpCanonicalNAN : fpcvt_result;
  assign fflags_out = (s2_fpCanonicalNAN & ~s2_outIsFP) ? 5'b10000      // 整数目的：NV
                    : (s2_fpCanonicalNAN &  s2_isFround) ? 5'b00000      // fround：不报异常
                    :                                      fpcvt_fflags;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden CVT64.sv 完全一致
// ---------------------------------------------------------------------------
module CVT64(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [2:0]  io_rm,
  input  [3:0]  io_input1H,
  input  [3:0]  io_output1H,
  input  [1:0]  io_isFround,
  input         io_isFcvtmod,
  output [63:0] io_result,
  output [4:0]  io_fflags
);

  xs_CVT64_core u_core (
    .clock        (clock),
    .reset        (reset),
    .fire         (io_fire),
    .src          (io_src),
    .op_type      (io_opType),
    .rm_in        (io_rm),
    .in_width_1h  (io_input1H),
    .out_width_1h (io_output1H),
    .is_fround    (io_isFround),
    .is_fcvtmod   (io_isFcvtmod),
    .result_out   (io_result),
    .fflags_out   (io_fflags)
  );

endmodule
