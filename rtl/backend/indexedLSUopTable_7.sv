// =============================================================================
// indexedLSUopTable_7.sv —— 索引访存 uop 偏移表的第 7 个 uop 变体
// -----------------------------------------------------------------------------
// 家族核：rtl/backend/xs_indexedLSUopTable_core.sv（算法与整体说明都在那里）
// golden 对照：G1-canonical/golden-rtl/indexedLSUopTable_7.sv
//
// 本变体参数与规模：UOP_IDX = 7；端口 3 根（src[3:0] 输入，
// outOffsetVs2[2:0] / outOffsetVd[2:0] 输出）；纯组合，无时钟无复位；
// 输入空间只有 2^4 = 16 种，UT 全穷举。
//
// ★ 本变体的完整真值表（EMUL/LMUL 为倍数的以 2 为底对数）★
//   src[3:2]=EMUL  src[1:0]=LMUL        uop 数   vs2 偏移  vd 偏移
//   src=4'h0  EMUL=1  LMUL=1       1         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h1  EMUL=1  LMUL=2       2         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h2  EMUL=1  LMUL=4       4         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h3  EMUL=1  LMUL=8       8         0         7
//   src=4'h4  EMUL=2  LMUL=1       2         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h5  EMUL=2  LMUL=2       2         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h6  EMUL=2  LMUL=4       4         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h7  EMUL=2  LMUL=8       8         1         7
//   src=4'h8  EMUL=4  LMUL=1       4         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'h9  EMUL=4  LMUL=2       4         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'hA  EMUL=4  LMUL=4       4         0         0   （本变体超出 uop 数，两个偏移都是 0）
//   src=4'hB  EMUL=4  LMUL=8       8         3         7
//   src=4'hC  EMUL=8  LMUL=1       8         7         0
//   src=4'hD  EMUL=8  LMUL=2       8         7         1
//   src=4'hE  EMUL=8  LMUL=4       8         7         3
//   src=4'hF  EMUL=8  LMUL=8       8         7         7
// =============================================================================

module indexedLSUopTable_7(
  input  [3:0] src,
  output [2:0] outOffsetVs2,
  output [2:0] outOffsetVd
);

  xs_indexedLSUopTable_core #(.UOP_IDX(7)) u_core (
    .src            (src),
    .out_offset_vs2 (outOffsetVs2),
    .out_offset_vd  (outOffsetVd)
  );

endmodule : indexedLSUopTable_7
