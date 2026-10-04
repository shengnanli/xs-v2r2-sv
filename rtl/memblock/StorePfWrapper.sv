// =============================================================================
// StorePfWrapper.sv —— Sbuffer 的 store 预取（SPB）外壳：本配置下只剩一个被关掉的 Serializer
//
// 在哪一层：Sbuffer → StorePfWrapper（mem/sbuffer/StorePrefetchBursts.scala `class StorePfWrapper`）。
// 设计意图：把每拍进 sbuffer 的 store 经 Serializer 串成一拍一个，训练 StorePrefetchBursts（spb），
//   再由 spb 发出 store 预取请求 prefetch_req。
// ★本配置（KunminghuV2Config）下它是空壳★：ENABLE_SPB = false，于是
//   * Serializer 的入队 valid 被接成 `sbuffer_enq(i).valid && false` ⇒ 恒 0；
//   * spb.io.enable = false，spb 永远不发请求，firtool 把整个 spb 与 prefetch_req / sbuffer_enq /
//     memSetPattenDetected 端口全部删掉；
//   * golden 只剩 clock / reset 两个端口和一个 Serializer 实例（它内部还留着一个零扇出的死指针，
//     见 rtl/memblock/Serializer.sv 文件头）。
// 所以本模块就是把 clock / reset 透传给 Serializer —— 照 golden 保留这一层，实例名 serializer 与 golden 一致。
// 子模块：Serializer（本仓重写件，已签核）。golden 对照：G1-canonical/golden-rtl/StorePfWrapper.sv（97 行）
// =============================================================================
module StorePfWrapper (
  input  logic clock,
  input  logic reset
);

  // 入队路恒关（ENABLE_SPB=false）的串行化 FIFO：没有数据端口，只剩时钟与异步复位
  Serializer serializer (
    .clock (clock),
    .reset (reset)
  );

endmodule
