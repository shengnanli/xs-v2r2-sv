// =============================================================================
// FloatDivider.sv —— 标量浮点除法 / 开方单元（f64 / f32 / f16，多拍非流水）
//
// 在哪一层：标量浮点除法 FU（FDivSqrt，ExeUnit_9 里）的运算核。一条 fdiv / fsqrt 进来，按 is_sqrt 只启动
//   两个子单元之一，等它算完再交出结果；两者共用一套 start / finish 握手。
// 设计源：yunsuan/fpu/FloatDivider.scala class FloatDivider（内部例化 FloatDividerR64 + fpsqrt_r16）。
//
// 机制：
//   §1 启动分派：start_valid 只送给被选中的那个子单元（除法 = ~is_sqrt，开方 = is_sqrt）；
//      对外 start_ready 要求**两个**子单元都空闲（任一在忙就不接新指令）。
//   §2 格式编码换算：除法器吃 fp_format 原值（1=f16 / 2=f32 / 3=f64）；开方器的编码少 1（0=f16 / 1=f32 / 2=f64），
//      所以送开方器的是 fp_format - 1（2 位截断，非法的 0 变成 3）。
//   §3 结果汇合：finish_valid = 两者之或；结果 / fflags 按各自 finish_valid 门控后按位或（同一时刻至多一个在出结果）。
//   flush / finish_ready / rm / canonical NaN 标志直接广播给两个子单元（开方只有一个操作数，只收 a 的标志）。
// 子模块：fpsqrt_r16 u_vector_float_sqrt_r16、FloatDividerR64 u_vector_float_divider_r64
//   （实例名与 golden 一致；本仓已签核重写件）。本层无寄存器。
// golden 对照：G1-canonical/golden-rtl/FloatDivider.sv
// =============================================================================
module xs_FloatDivider_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        start_valid,
  output logic        start_ready,
  input  logic        flush,
  input  logic [1:0]  fp_format,          // 1 = f16，2 = f32，3 = f64
  input  logic [63:0] opa,                // 被除数 / 被开方数
  input  logic [63:0] opb,                // 除数
  input  logic        is_sqrt,
  input  logic [2:0]  rm,
  input  logic        a_is_canonical_nan,
  input  logic        b_is_canonical_nan,
  output logic        finish_valid,
  input  logic        finish_ready,
  output logic [63:0] result,
  output logic [4:0]  fflags
);
  // ---------------------------------------------------------------------------
  // §1/§2 两个子单元：只启动被选中的那个；开方器的格式编码比除法器少 1
  // ---------------------------------------------------------------------------
  logic        sqrt_start_ready, sqrt_finish_valid;
  logic [63:0] sqrt_result;
  logic [4:0]  sqrt_fflags;
  logic [1:0]  sqrt_fp_format;
  assign sqrt_fp_format = fp_format - 2'd1;

  fpsqrt_r16 u_vector_float_sqrt_r16 (
    .clock                (clock),
    .reset                (reset),
    .start_valid_i        (is_sqrt & start_valid),
    .start_ready_o        (sqrt_start_ready),
    .flush_i              (flush),
    .fp_format_i          (sqrt_fp_format),
    .op_i                 (opa),
    .rm_i                 (rm),
    .finish_valid_o       (sqrt_finish_valid),
    .finish_ready_i       (finish_ready),
    .fpsqrt_res_o         (sqrt_result),
    .fflags_o             (sqrt_fflags),
    .fp_aIsFpCanonicalNAN (a_is_canonical_nan)
  );

  logic        div_start_ready, div_finish_valid;
  logic [63:0] div_result;
  logic [4:0]  div_fflags;
  FloatDividerR64 u_vector_float_divider_r64 (
    .clock                   (clock),
    .reset                   (reset),
    .io_start_valid_i        (~is_sqrt & start_valid),
    .io_start_ready_o        (div_start_ready),
    .io_flush_i              (flush),
    .io_fp_format_i          (fp_format),
    .io_opa_i                (opa),
    .io_opb_i                (opb),
    .io_rm_i                 (rm),
    .io_fp_aIsFpCanonicalNAN (a_is_canonical_nan),
    .io_fp_bIsFpCanonicalNAN (b_is_canonical_nan),
    .io_finish_valid_o       (div_finish_valid),
    .io_finish_ready_i       (finish_ready),
    .io_fpdiv_res_o          (div_result),
    .io_fflags_o             (div_fflags)
  );

  // ---------------------------------------------------------------------------
  // §3 握手与结果汇合
  // ---------------------------------------------------------------------------
  assign start_ready  = div_start_ready & sqrt_start_ready;
  assign finish_valid = div_finish_valid | sqrt_finish_valid;
  assign result       = (div_finish_valid ? div_result : 64'h0) | (sqrt_finish_valid ? sqrt_result : 64'h0);
  assign fflags       = (div_finish_valid ? div_fflags : 5'h0)  | (sqrt_finish_valid ? sqrt_fflags : 5'h0);
endmodule

module FloatDivider (
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
  input  logic        io_fp_aIsFpCanonicalNAN,
  input  logic        io_fp_bIsFpCanonicalNAN,
  output logic        io_finish_valid_o,
  input  logic        io_finish_ready_i,
  output logic [63:0] io_fpdiv_res_o,
  output logic [4:0]  io_fflags_o
);
  xs_FloatDivider_core u_core (
    .clock              (clock),
    .reset              (reset),
    .start_valid        (io_start_valid_i),
    .start_ready        (io_start_ready_o),
    .flush              (io_flush_i),
    .fp_format          (io_fp_format_i),
    .opa                (io_opa_i),
    .opb                (io_opb_i),
    .is_sqrt            (io_is_sqrt_i),
    .rm                 (io_rm_i),
    .a_is_canonical_nan (io_fp_aIsFpCanonicalNAN),
    .b_is_canonical_nan (io_fp_bIsFpCanonicalNAN),
    .finish_valid       (io_finish_valid_o),
    .finish_ready       (io_finish_ready_i),
    .result             (io_fpdiv_res_o),
    .fflags             (io_fflags_o)
  );
endmodule
