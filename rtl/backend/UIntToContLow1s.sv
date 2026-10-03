// =============================================================================
// UIntToContLow1s.sv —— 温度计码：把 8 位无符号数 n 展成「低 n 位全 1」的 255 位向量
//
// 在哪一层：向量掩码/尾部生成 ByteMaskTailGen 的叶子（VldMergeUnit → VldMgu →
//   ByteMaskTailGen → 本件）。ByteMaskTailGen 用它把「起始字节号 / vl 字节数」变成
//   按字节的前缀掩码：dataOut[i] = 1 ⇔ i < dataIn（i = 0..254）。
//
// Scala（fu/vector/utils/UIntToCont1s.scala）用「看最高位、递归拼一半全 1」的写法
//   生成这张表；firtool 把递归展开成 475 行嵌套条件拼接。这里直接写它的定义式：
//   每一位就是一次比较。dataIn=0 → 全 0；dataIn=255 → 全 1。
// 对偶件：UIntToContLow0s（dataOut[i] = 1 ⇔ i >= dataIn，正好是本件的按位取反）。
//
// golden 对照：G1-canonical/golden-rtl/UIntToContLow1s.sv
// =============================================================================
module UIntToContLow1s (
  input  [7:0]   io_dataIn,
  output [254:0] io_dataOut
);
  for (genvar i = 0; i < 255; i++) begin : g_bit
    assign io_dataOut[i] = (i < io_dataIn);
  end
endmodule
