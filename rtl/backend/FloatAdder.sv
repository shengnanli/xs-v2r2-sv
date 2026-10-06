// =============================================================================
// FloatAdder.sv —— 标量浮点加法器顶层（yunsuan fpu/FloatAdder.scala）
//
// 两条已签核流水线并行收同一请求：F64Adder（FloatAdderF64Pipeline）算 f64，F32Adder
// （FloatAdderF32F16MixedPipeline）算 f32/f16。本层只做三件事：
//   §1 fire 时登记结果格式 fp_format_reg 与“结果要 NaN-box”标志 resultNeedBox（Scala 同名 RegEnable）；
//   §2 例化两条流水线（F32 侧的格式编码比外部少 1：f16=0、f32=1）；
//   §3 按登记的格式三选一输出结果与 fflags。golden 是 Mux1H（按位或），格式 0 时输出 0，这里照写。
// 机制：NaN-box —— 窄格式结果写进 64 位寄存器时高位填 1；只有产生浮点数的运算（加减、min/max、
// 符号注入）需要，比较类（feq/flt/fle）结果是整数 0/1，高位填 0。
// =============================================================================
module FloatAdder (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [63:0] io_fp_a,
  input  logic [63:0] io_fp_b,
  input  logic [2:0]  io_round_mode,
  input  logic [1:0]  io_fp_format,
  input  logic [4:0]  io_op_code,
  input  logic        io_fp_aIsFpCanonicalNAN,
  input  logic        io_fp_bIsFpCanonicalNAN,
  output logic [63:0] io_fp_result,
  output logic [4:0]  io_fflags
);
  // FaddOpCode（yunsuan/package.scala）里结果是浮点数、需要 NaN-box 的那些
  localparam logic [4:0] OP_FADD   = 5'b00000;
  localparam logic [4:0] OP_FSUB   = 5'b00001;
  localparam logic [4:0] OP_FMIN   = 5'b00010;
  localparam logic [4:0] OP_FMAX   = 5'b00011;
  localparam logic [4:0] OP_FSGNJ  = 5'b00110;
  localparam logic [4:0] OP_FSGNJN = 5'b00111;
  localparam logic [4:0] OP_FSGNJX = 5'b01000;
  localparam logic [4:0] OP_FMINM  = 5'b11110;
  localparam logic [4:0] OP_FMAXM  = 5'b10011;

  // ---- §1 登记格式与 NaN-box 标志 ----
  logic [1:0] fp_format_reg;   // 1 = f16, 2 = f32, 3 = f64
  logic       resultNeedBox;
  logic       op_yields_float;

  assign op_yields_float = (io_op_code == OP_FADD)  | (io_op_code == OP_FSUB)   |
                           (io_op_code == OP_FMIN)  | (io_op_code == OP_FMAX)   |
                           (io_op_code == OP_FSGNJ) | (io_op_code == OP_FSGNJN) |
                           (io_op_code == OP_FSGNJX)| (io_op_code == OP_FMINM)  |
                           (io_op_code == OP_FMAXM);

  always_ff @(posedge clock) begin
    if (io_fire) begin
      fp_format_reg <= io_fp_format;
      resultNeedBox <= op_yields_float;
    end
  end

  // ---- §2 两条流水线 ----
  logic [63:0] f64_result;
  logic [4:0]  f64_fflags;
  logic [31:0] f32_result;     // f16 结果在低 16 位
  logic [4:0]  f32_fflags;

  FloatAdderF64Pipeline F64Adder (
    .clock                   (clock),
    .io_fire                 (io_fire),
    .io_fp_a                 (io_fp_a),
    .io_fp_b                 (io_fp_b),
    .io_fp_c                 (f64_result),
    .io_is_sub               (io_op_code[0]),
    .io_round_mode           (io_round_mode),
    .io_fflags               (f64_fflags),
    .io_op_code              (io_op_code),
    .io_fp_aIsFpCanonicalNAN (io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN (io_fp_bIsFpCanonicalNAN)
  );

  FloatAdderF32F16MixedPipeline F32Adder (
    .clock                   (clock),
    .io_fire                 (io_fire),
    .io_fp_a                 (io_fp_a[31:0]),
    .io_fp_b                 (io_fp_b[31:0]),
    .io_fp_c                 (f32_result),
    .io_is_sub               (io_op_code[0]),
    .io_round_mode           (io_round_mode),
    .io_fflags               (f32_fflags),
    .io_fp_format            (2'(io_fp_format - 2'h1)),   // 子流水线编码：f16=0、f32=1
    .io_op_code              (io_op_code),
    .io_fp_aIsFpCanonicalNAN (io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN (io_fp_bIsFpCanonicalNAN)
  );

  // ---- §3 按登记格式选输出（Mux1H：按位或，格式 0 时全 0）----
  logic res_is_f16, res_is_f32, res_is_f64;
  assign res_is_f16 = fp_format_reg == 2'h1;
  assign res_is_f32 = fp_format_reg == 2'h2;
  assign res_is_f64 = fp_format_reg == 2'h3;

  always_comb begin
    io_fp_result = (res_is_f16 ? {{48{resultNeedBox}}, f32_result[15:0]} : 64'h0) |
                   (res_is_f32 ? {{32{resultNeedBox}}, f32_result}       : 64'h0) |
                   (res_is_f64 ? f64_result                              : 64'h0);
    io_fflags    = ((res_is_f16 | res_is_f32) ? f32_fflags : 5'h0) |
                   (res_is_f64                ? f64_fflags : 5'h0);
  end
endmodule
