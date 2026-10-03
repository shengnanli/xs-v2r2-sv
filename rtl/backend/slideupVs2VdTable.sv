// =============================================================================
// slideupVs2VdTable.sv —— vslideup 的 uop 拆分表：uopIdx -> (读第几个 vs2 寄存器, 写第几个 vd 寄存器)
//
// 位置：Permutation（yunsuan 向量置换单元）stage 0，纯组合查表。
// 背景：LMUL = L 的 vslideup.vx/vi 被拆成 L(L+1)/2 个 uop。目的寄存器组的第 i 个 vd
//   可能从 vs2 组的第 0..i 个寄存器滑进来，于是第 i 个 vd 需要 i+1 个 uop。uop 按 vd 递增排：
//     uopIdx = i(i+1)/2 + j   (0 <= j <= i)   ->   vs2 偏移 = i - j，vd 偏移 = i
//   即同一个 vd 先读最近的 vs2（i），再一路往前读到 vs2[0]。
// 输入 src = {lmul[1:0], uopIdx[5:0]}（lmul 0..3 表示 L = 1/2/4/8；分数 LMUL 由上层折成 0）。
// 不在表里的组合（uopIdx >= L(L+1)/2）输出 0 —— Scala 用 TruthTable(..., BitPat.N) 定义的缺省值，
// 不是 don't-care，所以 golden 的 QMC 化简结果对任意 src 都是确定值，这里逐项照算。
// Chisel 源：yunsuan/src/main/scala/yunsuan/vector/VectorPerm/Permutation.scala（yunsuan@9559211）。
// golden 对照：G1-canonical/golden-rtl/slideupVs2VdTable.sv（无子模块）。
// =============================================================================
module xs_slideupVs2VdTable_core (
  input  logic [1:0] lmul,          // L = 1 << lmul
  input  logic [5:0] uop_idx,
  output logic [2:0] vs2_offset,
  output logic [2:0] vd_offset
);
  always_comb begin
    vs2_offset = '0;
    vd_offset  = '0;
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j <= i; j++) begin
        if ((i < (1 << lmul)) && (uop_idx == 6'(i * (i + 1) / 2 + j))) begin
          vs2_offset = 3'(i - j);
          vd_offset  = 3'(i);
        end
      end
    end
  end
endmodule

module slideupVs2VdTable (
  input  [7:0] src,
  output [2:0] outOffsetVs2,
  output [2:0] outOffsetVd
);
  xs_slideupVs2VdTable_core u_core (
    .lmul       (src[7:6]),
    .uop_idx    (src[5:0]),
    .vs2_offset (outOffsetVs2),
    .vd_offset  (outOffsetVd)
  );
endmodule
