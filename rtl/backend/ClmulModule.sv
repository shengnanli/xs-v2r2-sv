// =============================================================================
// ClmulModule.sv —— Bku 的无进位乘子块：clmul / clmulh / clmulr（Zbc / Zbkc）
//
// 位置：Bku（rtl/backend/Bku.sv）里四个并联子块之一，吃 rs1 / rs2。
//   Chisel 源 src/main/scala/xiangshan/backend/fu/Bku.scala `class ClmulModule`。
//   Bku 给它的 io_regEnable 是 regEnable(1)：本块内部打一拍，结果在 s1 组合输出。
//
// 无进位乘（GF(2) 上的多项式乘法）：64×64 → 128 位积
//     prod = XOR_{i: rs1[i]=1} (rs2 << i)
//   与普通乘法唯一的区别是部分积用异或而不是加法累加，所以没有进位链。
//   指令取积的哪一段（BKUOpType clmul=0 / clmulh=1 / clmulr=2）：
//     clmul  = prod[63:0]，clmulh = prod[127:64]，clmulr = prod[126:63]。
//
// 流水切分（与 Chisel 一致）：64 个部分积在 s0 两两异或三层，压成 8 个
//   128 位中间和 mul3[0..7]（第 j 个覆盖 rs1 的第 8j..8j+7 位）存寄存器；
//   s1 把 8 个异或成 prod，再按拍下来的 func 取段。
//
// 怪癖（照抄 golden）：取段判的是**整个 9 位 funcReg** 是否等于 1 / 2，
//   其余任何编码都给 clmul 段（LookupTreeDefault 的默认值）。
// =============================================================================

module xs_ClmulModule_core (
  input  logic        clock,
  input  logic [63:0] src1,          // rs1：乘数，逐位决定是否累加 rs2 << i
  input  logic [63:0] src2,          // rs2：被乘数
  input  logic [8:0]  func,
  input  logic        reg_enable,
  output logic [63:0] out
);

  localparam logic [8:0] FUNC_CLMULH = 9'd1;
  localparam logic [8:0] FUNC_CLMULR = 9'd2;

  // ===========================================================================
  // s0：64 个部分积按 8 个一组异或，得到 8 个组和
  // ===========================================================================
  logic [127:0] group_xor [8];
  always_comb begin
    for (int g = 0; g < 8; g++) begin
      group_xor[g] = '0;
      for (int b = 8*g; b < 8*g + 8; b++)
        if (src1[b]) group_xor[g] ^= 128'(src2) << b;
    end
  end

  // ---- s0 → s1 流水寄存器（RegEnable，不复位）----
  logic [8:0]   funcReg;
  logic [127:0] mul3 [8];
  always_ff @(posedge clock) begin
    if (reg_enable) begin
      funcReg <= func;
      for (int g = 0; g < 8; g++) mul3[g] <= group_xor[g];
    end
  end

  // ===========================================================================
  // s1：8 组异或成 128 位积，按 func 取段
  // ===========================================================================
  logic [127:0] prod;
  always_comb begin
    prod = '0;
    for (int g = 0; g < 8; g++) prod ^= mul3[g];
  end

  always_comb begin
    if (funcReg == FUNC_CLMULR)      out = prod[126:63];
    else if (funcReg == FUNC_CLMULH) out = prod[127:64];
    else                             out = prod[63:0];
  end

endmodule


// =============================================================================
// ClmulModule —— golden 同名 wrapper（端口逐位同 golden）
// =============================================================================
module ClmulModule (
  input         clock,
  input  [63:0] io_src_0,
  input  [63:0] io_src_1,
  input  [8:0]  io_func,
  input         io_regEnable,
  output [63:0] io_out
);

  xs_ClmulModule_core u_core (
    .clock      (clock),
    .src1       (io_src_0),
    .src2       (io_src_1),
    .func       (io_func),
    .reg_enable (io_regEnable),
    .out        (io_out)
  );

endmodule
