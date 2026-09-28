// =============================================================================
// UIntToContLow0s.sv —— 反温度计码：把 8 位无符号数 n 展成「低 n 位全 0、其余全 1」的 255 位向量
//
// 在哪一层：向量掩码/尾部生成 ByteMaskTailGen 的叶子（VldMergeUnit → VldMgu →
//   ByteMaskTailGen → 本件）。ByteMaskTailGen 用它标出「从某个字节号开始往后」的
//   区段：dataOut[i] = 1 ⇔ i >= dataIn（i = 0..254）。
//
// Scala（fu/vector/utils/UIntToCont0s.scala）用递归拼一半全 0 的写法生成；firtool
//   展开成 477 行嵌套条件拼接。这里直接写定义式：每一位一次比较。
//   dataIn=0 → 全 1；dataIn=255 → 全 0。
// 对偶件：UIntToContLow1s（dataOut[i] = 1 ⇔ i < dataIn）。
//
// golden 对照：G1-canonical/golden-rtl/UIntToContLow0s.sv
// =============================================================================
module UIntToContLow0s (
  input  [7:0]   io_dataIn,
  output [254:0] io_dataOut
);
  for (genvar i = 0; i < 255; i++) begin : g_bit
    assign io_dataOut[i] = (i >= io_dataIn);
  end
endmodule
