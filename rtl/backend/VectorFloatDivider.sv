// =============================================================================
// VectorFloatDivider.sv —— 向量浮点除法 / 开方单元的外壳：按 is_sqrt 把一次操作派给两个迭代器之一
//
// 在哪一层：后端向量浮点除法功能单元（VFDivSqrt）里真正做运算的部件。
//   Chisel 源 yunsuan/vector/VectorFloatDivider.scala `class VectorFloatDivider`。
// 两个迭代器（都是"发起 → 迭代若干拍 → finish_valid 握手"的多拍单元，同一时刻只有一个在忙）：
//   * VectorFloatDividerR64  基 64 SRT 除法，opa / opb（fp_format：1 f16×4 / 2 f32×2 / 3 f64×1）；
//   * fpsqrt_vector_r16      基 16 开方，只吃 opa；它的格式编码比本层小 1（0 f16 / 1 f32 / 2 f64），
//                            所以送 fp_format - 1（本层 fp_format=0 是非法编码，减一后成 3，同样非法）。
// 派发与汇合（照 Scala 逐句）：
//   start_valid 只送给 is_sqrt 选中的那一个；start_ready 要两个都空闲才为 1（保证同一时刻只有一个在忙）；
//   finish_valid 取两者之或；结果 / fflags 用 Mux1H（按位与-或）—— 两个都没 finish 时输出 0。
// 子模块：VectorFloatDividerR64 / fpsqrt_vector_r16（本仓重写件，已签核；实例名与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/VectorFloatDivider.sv（161 行）。golden 端口表里没有 Scala 的
//   frs1/frs2/is_frs*/is_vec/CanonicalNAN 这些输入 —— 两个子模块在本配置下都不读它们，firtool 已删。
// =============================================================================
module VectorFloatDivider (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_start_valid_i,
  output logic        io_start_ready_o,
  input  logic        io_flush_i,
  input  logic [1:0]  io_fp_format_i,
  input  logic [63:0] io_opa_i,
  input  logic [63:0] io_opb_i,
  input  logic        io_is_sqrt_i,
  input  logic [2:0]  io_rm_i,
  output logic        io_finish_valid_o,
  input  logic        io_finish_ready_i,
  output logic [63:0] io_fpdiv_res_o,
  output logic [19:0] io_fflags_o
);

  // ---- 开方迭代器（is_sqrt=1 的操作）----
  logic        sqrt_start_ready;
  logic        sqrt_finish_valid;
  logic [63:0] sqrt_res;
  logic [19:0] sqrt_fflags;

  fpsqrt_vector_r16 u_vector_float_sqrt_r16 (
    .clock          (clock),
    .reset          (reset),
    .start_valid_i  (io_is_sqrt_i & io_start_valid_i),
    .start_ready_o  (sqrt_start_ready),
    .flush_i        (io_flush_i),
    .fp_format_i    (io_fp_format_i - 2'd1),   // 本层 1/2/3 → 开方器 0/1/2
    .op_i           (io_opa_i),
    .rm_i           (io_rm_i),
    .finish_valid_o (sqrt_finish_valid),
    .finish_ready_i (io_finish_ready_i),
    .fpsqrt_res_o   (sqrt_res),
    .fflags_o       (sqrt_fflags)
  );

  // ---- 除法迭代器（is_sqrt=0 的操作）----
  logic        div_start_ready;
  logic        div_finish_valid;
  logic [63:0] div_res;
  logic [19:0] div_fflags;

  VectorFloatDividerR64 u_vector_float_divider_r64 (
    .clock             (clock),
    .reset             (reset),
    .io_start_valid_i  (~io_is_sqrt_i & io_start_valid_i),
    .io_start_ready_o  (div_start_ready),
    .io_flush_i        (io_flush_i),
    .io_fp_format_i    (io_fp_format_i),
    .io_opa_i          (io_opa_i),
    .io_opb_i          (io_opb_i),
    .io_rm_i           (io_rm_i),
    .io_finish_valid_o (div_finish_valid),
    .io_finish_ready_i (io_finish_ready_i),
    .io_fpdiv_res_o    (div_res),
    .io_fflags_o       (div_fflags)
  );

  // ---- 汇合：两个都空闲才接新操作；完成信号取或；结果按 finish 一位热选（都不 finish 时为 0）----
  assign io_start_ready_o  = div_start_ready & sqrt_start_ready;
  assign io_finish_valid_o = div_finish_valid | sqrt_finish_valid;
  assign io_fpdiv_res_o    = ({64{div_finish_valid}}  & div_res)
                           | ({64{sqrt_finish_valid}} & sqrt_res);
  assign io_fflags_o       = ({20{div_finish_valid}}  & div_fflags)
                           | ({20{sqrt_finish_valid}} & sqrt_fflags);

endmodule
