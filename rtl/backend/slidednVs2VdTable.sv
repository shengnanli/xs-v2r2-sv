// =============================================================================
// slidednVs2VdTable.sv —— vslidedown 的 uop 拆分表：uopIdx -> (vs2 偏移, vd 偏移, 是否该 vd 的第一个 uop)
//
// 位置：Permutation（yunsuan 向量置换单元）stage 0，纯组合查表。
// 背景：LMUL = L 的 vslidedown 拆成 L(L+1)/2 个 uop。第 i 个 vd 可能从 vs2 组的第 i..L-1 个寄存器
//   滑下来，需要 L-i 个 uop。uop 按 vd 递增排，第 i 个 vd 的 uop 从 prev(i) = L*i - i(i-1)/2 开始：
//     uopIdx = prev(i) + (L - i - 1 - j)   (0 <= j <= L-i-1)  ->  vs2 偏移 = j，vd 偏移 = i，
//     isFirst = (j == L - i - 1)
//   即同一个 vd 先读离得最远的 vs2（j 最大，isFirst=1：这一拍负责把越界元素清 0），再往近处读。
// 输入 src = {lmul[1:0], uopIdx[5:0]}；不在表里的组合输出全 0（TruthTable 缺省值 BitPat.N，非 don't-care）。
// Chisel 源：yunsuan/src/main/scala/yunsuan/vector/VectorPerm/Permutation.scala（yunsuan@9559211）。
// golden 对照：G1-canonical/golden-rtl/slidednVs2VdTable.sv（无子模块）。
// =============================================================================
module xs_slidednVs2VdTable_core (
  input  logic [1:0] lmul,          // L = 1 << lmul
  input  logic [5:0] uop_idx,
  output logic [2:0] vs2_offset,
  output logic [2:0] vd_offset,
  output logic       is_first
);
  always_comb begin
    vs2_offset = '0;
    vd_offset  = '0;
    is_first   = 1'b0;
    for (int l = 0; l < 4; l++) begin
      for (int i = 0; i < (1 << l); i++) begin
        for (int j = 0; j < (1 << l) - i; j++) begin
          if ((lmul == 2'(l)) &&
              (uop_idx == 6'((1 << l) * i - i * (i - 1) / 2 + (1 << l) - i - j - 1))) begin
            vs2_offset = 3'(j);
            vd_offset  = 3'(i);
            is_first   = (j == (1 << l) - i - 1);
          end
        end
      end
    end
  end
endmodule

module slidednVs2VdTable (
  input  [7:0] src,
  output [2:0] outOffsetVs2,
  output [2:0] outOffsetVd,
  output       outIsFirst
);
  xs_slidednVs2VdTable_core u_core (
    .lmul       (src[7:6]),
    .uop_idx    (src[5:0]),
    .vs2_offset (outOffsetVs2),
    .vd_offset  (outOffsetVd),
    .is_first   (outIsFirst)
  );
endmodule
