// FloatAdderWidenFormat.sv —— 向量浮点加法器的"加宽格式化"前级：把半宽操作数展开成全宽浮点
// -----------------------------------------------------------------------------
// 在哪一层：VectorFloatAdder（yunsuan/vector/VectorFloatAdder.scala）里例化 3 份，为 vfwadd/vfwsub
//   这类加宽指令把 64 位源寄存器里的半宽元素转成下一档宽度：
//     f16 → f32：widen_{a,b}_f32_0 / _f32_1（每份 64 位源里取两个 f16 元素）；
//     f32 → f64：widen_{a,b}_f64（取一个 f32 元素）。
//   uop_idx 选源寄存器的高半（=1，元素 2/3 或高 f32）还是低半（=0）。
// 机制（Scala 里的 Widen(in) 函数，每个输出一份）：
//   规格数：指数重新偏置 —— f16 的 e5 变成 8 位 {e[4] ? 4'b1000 : 4'b0111, e[3:0]}（即 e+112），
//           f32 的 e8 变成 11 位 {e[7] ? 4'b1000 : 4'b0111, e[6:0]}（即 e+896）；尾数原样左对齐，低位补 0。
//   非规格数（指数全 0）：用优先级左移器（child ShiftLeftPriorityWith{F32,F64}EXPResult）把尾数
//           最高的 1 移出隐含位，指数取 child 给的"偏置 - 移位量"。
// 怪癖（照 golden，bug-for-bug）：
//   - 指数全 1（Inf/NaN）也照"规格数"公式重偏置，不映射成目标格式的全 1 指数（f16 Inf → f32 指数 143）；
//     上游父级另有 NaN/Inf 的特判，这里只管格式。
//   - 尾数全 0 的"非规格数"（即 ±0）走非规格分支：child 移位结果 0、指数取 child 的兜底值（f32 102 / f64 0x369），
//     不是 0。
//   - Scala 里还有 frs1 / is_frs1（标量源 vfwadd.wf）一路，KunminghuV2Config 下父级没接，firtool 已消掉端口。
// 子模块：ShiftLeftPriorityWithF32EXPResult ×8、ShiftLeftPriorityWithF64EXPResult ×4（均已签核：
//   ref 读 golden 件、impl 读本仓重写件）。纯组合，无寄存器。
// golden 对照：G1-canonical/golden-rtl/FloatAdderWidenFormat.sv
// =============================================================================

// -----------------------------------------------------------------------------
// 单个元素的加宽：IS_F16=1 时 f16→f32（输出 32 位），IS_F16=0 时 f32→f64（输出 64 位）
// -----------------------------------------------------------------------------
module xs_FloatAdderWidenFormat_widen #(
  parameter bit IS_F16 = 1'b1,
  localparam int IN_W   = IS_F16 ? 16 : 32,   // 源格式总宽
  localparam int EXP_W  = IS_F16 ? 5  : 8,    // 源指数宽
  localparam int MANT_W = IS_F16 ? 10 : 23,   // 源尾数宽（不含隐含位）
  localparam int OUT_W  = IS_F16 ? 32 : 64,   // 目标格式总宽
  localparam int DEXP_W = IS_F16 ? 8  : 11,   // 目标指数宽
  localparam int PAD_W  = IS_F16 ? 13 : 29    // 目标尾数比源尾数多出的低位（补 0）
) (
  input  logic [IN_W-1:0]  in,
  output logic [OUT_W-1:0] out
);
  logic              sign;
  logic [EXP_W-1:0]  exp_in;
  logic [MANT_W-1:0] mant_in;
  assign {sign, exp_in, mant_in} = in;

  // 非规格数归一化：优先级左移器（最高位的 1 决定移位量），同时给出目标格式下的指数
  logic [MANT_W-1:0] norm_shifted;
  logic [DEXP_W-1:0] norm_exp;
  generate
    if (IS_F16) begin : g_f16
      ShiftLeftPriorityWithF32EXPResult u_norm (
        .io_src(mant_in),
        .io_priority_shiftValue(mant_in),
        .io_lshift_result(norm_shifted),
        .io_exp_result(norm_exp)
      );
    end else begin : g_f32
      ShiftLeftPriorityWithF64EXPResult u_norm (
        .io_src(mant_in),
        .io_priority_shiftValue(mant_in),
        .io_lshift_result(norm_shifted),
        .io_exp_result(norm_exp)
      );
    end
  endgenerate

  logic              is_denormal;
  logic [DEXP_W-1:0] widened_exp;
  logic [MANT_W-1:0] widened_mant;
  always_comb begin
    is_denormal = (exp_in == '0);
    if (is_denormal) begin
      widened_exp  = norm_exp;
      widened_mant = {norm_shifted[MANT_W-2:0], 1'b0};   // 移出的最高位成了隐含位，丢掉
    end else begin
      // 重偏置：最高位为 1 → 4'b1000 前缀，为 0 → 4'b0111 前缀，其余位照抄
      widened_exp  = {(exp_in[EXP_W-1] ? 4'b1000 : 4'b0111), exp_in[EXP_W-2:0]};
      widened_mant = mant_in;
    end
    out = {sign, widened_exp, widened_mant, {PAD_W{1'b0}}};
  end
endmodule

// -----------------------------------------------------------------------------
// 可读核：两个源各取 2 个 f16 + 1 个 f32 元素，按 uop_idx 选高/低半
// -----------------------------------------------------------------------------
module xs_FloatAdderWidenFormat_core (
  input  logic [63:0] widen_a,
  input  logic [63:0] widen_b,
  input  logic        uop_idx,      // 1 = 取源寄存器高 32 位里的元素，0 = 低 32 位
  output logic [31:0] widen_a_f32 [2],
  output logic [31:0] widen_b_f32 [2],
  output logic [63:0] widen_a_f64,
  output logic [63:0] widen_b_f64
);
  // 两个源 × {低半, 高半} 各展开一次，再按 uop_idx 选；与 Scala 的 Mux(uop_idx, Widen(hi), Widen(lo)) 同构
  logic [63:0] src [2];
  assign src[0] = widen_a;
  assign src[1] = widen_b;

  logic [31:0] f32_lo [2][2];   // [源][元素]：低半两个 f16（[15:0]、[31:16]）的加宽结果
  logic [31:0] f32_hi [2][2];   // [源][元素]：高半两个 f16（[47:32]、[63:48]）
  logic [63:0] f64_lo [2];      // [源]：低半 f32（[31:0]）
  logic [63:0] f64_hi [2];      // [源]：高半 f32（[63:32]）

  for (genvar s = 0; s < 2; s++) begin : g_src
    for (genvar e = 0; e < 2; e++) begin : g_f16_elem
      xs_FloatAdderWidenFormat_widen #(.IS_F16(1'b1)) u_lo (
        .in(src[s][16*e +: 16]),
        .out(f32_lo[s][e])
      );
      xs_FloatAdderWidenFormat_widen #(.IS_F16(1'b1)) u_hi (
        .in(src[s][32 + 16*e +: 16]),
        .out(f32_hi[s][e])
      );
    end
    xs_FloatAdderWidenFormat_widen #(.IS_F16(1'b0)) u_f64_lo (
      .in(src[s][31:0]),
      .out(f64_lo[s])
    );
    xs_FloatAdderWidenFormat_widen #(.IS_F16(1'b0)) u_f64_hi (
      .in(src[s][63:32]),
      .out(f64_hi[s])
    );
  end

  always_comb begin
    for (int e = 0; e < 2; e++) begin
      widen_a_f32[e] = uop_idx ? f32_hi[0][e] : f32_lo[0][e];
      widen_b_f32[e] = uop_idx ? f32_hi[1][e] : f32_lo[1][e];
    end
    widen_a_f64 = uop_idx ? f64_hi[0] : f64_lo[0];
    widen_b_f64 = uop_idx ? f64_hi[1] : f64_lo[1];
  end
endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位同名
// -----------------------------------------------------------------------------
module FloatAdderWidenFormat (
  input  logic [63:0] io_widen_a,
  input  logic [63:0] io_widen_b,
  input  logic        io_uop_idx,
  output logic [31:0] io_widen_a_f32_0,
  output logic [31:0] io_widen_b_f32_0,
  output logic [31:0] io_widen_a_f32_1,
  output logic [31:0] io_widen_b_f32_1,
  output logic [63:0] io_widen_a_f64,
  output logic [63:0] io_widen_b_f64
);
  logic [31:0] widen_a_f32 [2];
  logic [31:0] widen_b_f32 [2];

  xs_FloatAdderWidenFormat_core u_core (
    .widen_a(io_widen_a),
    .widen_b(io_widen_b),
    .uop_idx(io_uop_idx),
    .widen_a_f32(widen_a_f32),
    .widen_b_f32(widen_b_f32),
    .widen_a_f64(io_widen_a_f64),
    .widen_b_f64(io_widen_b_f64)
  );

  assign io_widen_a_f32_0 = widen_a_f32[0];
  assign io_widen_a_f32_1 = widen_a_f32[1];
  assign io_widen_b_f32_0 = widen_b_f32[0];
  assign io_widen_b_f32_1 = widen_b_f32[1];
endmodule
