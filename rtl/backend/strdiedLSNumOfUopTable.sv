// =============================================================================
// strdiedLSNumOfUopTable —— 跨步（strided）向量访存的 uop 数查表（纯组合，UopInfoGen 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/decode/UopInfoGen.scala（class strdiedLSNumOfUopTable，
//         名字里的 "strdied" 是 Scala 原文拼写）。
//
// 查表：src = {emul[1:0], nf[2:0]}（emul = log2(EMUL)，nf = 段数-1）。
//   uop 数 = EMUL × (nf+1)；若超过 8（每条指令最多占 8 个向量寄存器）则为 0（非法组合）。
//   Scala 用 TruthTable + QMCMinimizer 生成与或阵列，32 个输入全部有定义（无 don't-care），
//   故直接按定义计算与 golden 的与或阵列逐值相等。
// =============================================================================
module xs_strdiedLSNumOfUopTable_core (
  input  logic [1:0] emul,   // log2(EMUL)：0..3 ⇒ EMUL = 1/2/4/8
  input  logic [2:0] nf,     // 段数 - 1
  output logic [3:0] num_uop
);

  always_comb begin
    int unsigned uops;
    uops    = (1 << emul) * (nf + 1);
    num_uop = (uops <= 8) ? 4'(uops) : 4'd0;
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden strdiedLSNumOfUopTable.sv 逐位一致
// ---------------------------------------------------------------------------
module strdiedLSNumOfUopTable (
  input  [4:0] src,
  output [3:0] out
);

  xs_strdiedLSNumOfUopTable_core u_core (
    .emul    (src[4:3]),
    .nf      (src[2:0]),
    .num_uop (out)
  );

endmodule
