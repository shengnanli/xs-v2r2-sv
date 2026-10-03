// =============================================================================
// CountModule.sv —— Bku 的计数子块：clz / clzw / ctz / ctzw / cpop / cpopw（Zbb）
//
// 位置：Bku（rtl/backend/Bku.sv）里四个并联子块之一，只吃 rs1（io_src）。
//   Chisel 源 src/main/scala/xiangshan/backend/fu/Bku.scala `class CountModule`。
//   Bku 给它的 io_regEnable 是 regEnable(1)：本块内部打一拍（s0 → s1），
//   结果在 s1 组合地出现在 io_out 上，Bku 顶层再选一次、打第二拍。
//
// func 用到的位（BKUOpType：clz=001000 clzw=001001 ctz=001010 ctzw=001011
//   cpop=001100 cpopw=001101）：
//   func[1] = ctz 类：先把 src 位序反转，ctz 就变成了 clz；
//   func[2] = cpop 类（否则是 clz/ctz）；
//   func[0] = W（32 位）变体。
//
// 核心机制 —— 前导零计数的二叉归并树（Chisel 的 encode + clzi）：
//   每个结点保存"本段从高位数起的前导零个数"，取值 0..2^k，宽 k+1 位，
//   最高位置 1 恰好表示"整段全 0"。两段合并 clz_merge(k, 高段, 低段)：
//   高段非全 0 → 结果就是高段；高段全 0 → 2^k + 低段，用位拼接实现
//   {高段[k]&低段[k], ~低段[k], 低段[k-1:0]}。
//   第 0 层把每 2 位编码成 0/1/2（00→2，01→1，1x→0），之后 5 层归并到 64 位。
//   s0 做到第 2 层（8 段 × 4 位）存进 c2；s1 再归并 3 层。clzw 取第 4 层的
//   某一半（低 32 位那半，ctzw 反转后在高半，所以按 func[1] 选 c4[1] / c4[0]）。
//   cpop：s0 先算 4 个 16 位段的 popcount 存进 cpopTmp，s1 相加。
//
// 怪癖（照抄 golden）：s1 的归并直接作用在寄存器 c2 上，c2 的值域在 FM 眼里是
//   任意 4 位值，所以归并必须逐位照 Chisel 的拼接式写，不能换成"相加"这种只在
//   合法值域内等价的写法。输出只有低 7 位可能非 0，高 57 位恒 0。
// =============================================================================

module xs_CountModule_core (
  input  logic        clock,
  input  logic [63:0] src,
  input  logic [8:0]  func,
  input  logic        reg_enable,
  output logic [63:0] out
);

  // 一层归并：left/right 是 k+1 位的段计数（装在 7 位容器的低位里，其余位为 0）
  function automatic logic [6:0] clz_merge(input int k, input logic [6:0] left, input logic [6:0] right);
    logic [6:0] merged;
    if (left[k]) begin
      merged      = right & ((7'd1 << k) - 7'd1);   // 低段的 right[k-1:0]
      merged[k]   = ~right[k];
      merged[k+1] = right[k];                       // = left[k] & right[k]
    end else begin
      merged = left;
    end
    return merged;
  endfunction

  // 第 0 层：每 2 位的前导零个数（00→2，01→1，1x→0）
  function automatic logic [1:0] clz_pair(input logic [1:0] bits);
    return (bits == 2'b01) ? 2'd1 : {bits == 2'b00, 1'b0};
  endfunction

  // ===========================================================================
  // s0：反转（ctz）→ 第 0..2 层归并；popcount 四段
  // ===========================================================================
  logic [63:0] count_src;
  always_comb begin
    for (int b = 0; b < 64; b++) count_src[b] = func[1] ? src[63 - b] : src[b];
  end

  logic [1:0] c0 [32];   // 每 2 位一段
  logic [2:0] c1 [16];   // 每 4 位一段
  always_comb begin
    for (int i = 0; i < 32; i++) c0[i] = clz_pair(count_src[2*i +: 2]);
    for (int i = 0; i < 16; i++) c1[i] = 3'(clz_merge(1, 7'(c0[2*i+1]), 7'(c0[2*i])));
  end

  // ---- s0 → s1 流水寄存器（RegEnable，不复位）----
  logic [8:0] funcReg;
  logic [3:0] c2      [8];   // 每 8 位一段的前导零个数
  logic [4:0] cpopTmp [4];   // 每 16 位一段的 1 的个数
  always_ff @(posedge clock) begin
    if (reg_enable) begin
      funcReg <= func;
      for (int i = 0; i < 8; i++) c2[i] <= 4'(clz_merge(2, 7'(c1[2*i+1]), 7'(c1[2*i])));
      for (int i = 0; i < 4; i++) cpopTmp[i] <= 5'($countones(src[16*i +: 16]));
    end
  end

  // ===========================================================================
  // s1：第 3..5 层归并、cpop 求和、按 func 选结果
  // ===========================================================================
  logic [4:0] c3 [4];    // 每 16 位一段
  logic [5:0] c4 [2];    // 每 32 位一段
  logic [6:0] clz64, clz32;
  logic [5:0] cpop_lo32, cpop_hi32;
  logic [6:0] cpop64;
  always_comb begin
    for (int i = 0; i < 4; i++) c3[i] = 5'(clz_merge(3, 7'(c2[2*i+1]), 7'(c2[2*i])));
    for (int i = 0; i < 2; i++) c4[i] = 6'(clz_merge(4, 7'(c3[2*i+1]), 7'(c3[2*i])));
    clz64 = clz_merge(5, 7'(c4[1]), 7'(c4[0]));
    // W 变体：clzw 看低 32 位（c4[0]）；ctzw 反转后原低 32 位到了高半（c4[1]）
    clz32 = 7'(funcReg[1] ? c4[1] : c4[0]);
    cpop_lo32 = 6'(cpopTmp[0]) + 6'(cpopTmp[1]);
    cpop_hi32 = 6'(cpopTmp[2]) + 6'(cpopTmp[3]);
    cpop64    = 7'(cpop_lo32) + 7'(cpop_hi32);
  end

  always_comb begin
    if (funcReg[2]) out = 64'(funcReg[0] ? 7'(cpop_lo32) : cpop64);
    else            out = 64'(funcReg[0] ? clz32 : clz64);
  end

endmodule


// =============================================================================
// CountModule —— golden 同名 wrapper（端口逐位同 golden）
// =============================================================================
module CountModule (
  input         clock,
  input  [63:0] io_src,
  input  [8:0]  io_func,
  input         io_regEnable,
  output [63:0] io_out
);

  xs_CountModule_core u_core (
    .clock      (clock),
    .src        (io_src),
    .func       (io_func),
    .reg_enable (io_regEnable),
    .out        (io_out)
  );

endmodule
