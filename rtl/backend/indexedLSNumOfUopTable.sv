// =============================================================================
// indexedLSNumOfUopTable —— 索引（indexed）向量访存的 uop 数查表（纯组合，UopInfoGen 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/decode/UopInfoGen.scala（class indexedLSNumOfUopTable）。
//
// 查表：src = {emul[1:0], lmul[1:0], nf[2:0]}（emul = log2(索引 EMUL)，lmul = log2(数据 LMUL)，
//   nf = 段数-1）。索引访存一条指令要同时遍历索引寄存器组（EMUL 个）与数据寄存器组
//   （LMUL×(nf+1) 个），uop 数取两者大者：
//     nf == 0：max(EMUL, LMUL)；
//     nf  > 0：LMUL×(nf+1) ≤ 8 时 max(LMUL×(nf+1), EMUL)，否则 0（非法组合）。
//   Scala 的 TruthTable 对 128 个输入全部有定义（无 don't-care），故按定义计算与 golden
//   的与或阵列逐值相等。表项 4 位，端口 7 位，高 3 位恒 0（golden 同）。
// =============================================================================
module xs_indexedLSNumOfUopTable_core (
  input  logic [1:0] emul,   // log2(EMUL)
  input  logic [1:0] lmul,   // log2(LMUL)
  input  logic [2:0] nf,     // 段数 - 1
  output logic [3:0] num_uop
);

  always_comb begin
    int unsigned emul_val, lmul_val, data_regs;
    emul_val  = 1 << emul;
    lmul_val  = 1 << lmul;
    data_regs = lmul_val * (nf + 1);
    if (nf == 3'd0)
      num_uop = 4'((emul_val > lmul_val) ? emul_val : lmul_val);
    else if (data_regs <= 8)
      num_uop = 4'((data_regs > emul_val) ? data_regs : emul_val);
    else
      num_uop = 4'd0;
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden indexedLSNumOfUopTable.sv 逐位一致
// ---------------------------------------------------------------------------
module indexedLSNumOfUopTable (
  input  [6:0] src,
  output [6:0] out
);

  logic [3:0] num_uop;

  xs_indexedLSNumOfUopTable_core u_core (
    .emul    (src[6:5]),
    .lmul    (src[4:3]),
    .nf      (src[2:0]),
    .num_uop (num_uop)
  );

  assign out = {3'd0, num_uop};

endmodule
