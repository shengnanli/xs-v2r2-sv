// Serializer.sv —— Sbuffer store 预取（SPB）的请求串行化 FIFO：在本配置下是一个被关掉的空壳
//
// 位置：Sbuffer → StorePfWrapper → Serializer（mem/sbuffer/StorePrefetchBursts.scala:208）。
//   设计意图：把每拍至多 EnsbufferWidth 个进 sbuffer 的 store 收进一个 SERIALIZER_SIZE=12 项的
//   环形队列，再每拍弹一个去训练 StorePrefetchBursts。
//
// ★本配置下它什么也不做，但还剩两个寄存器★：StorePfWrapper 把每路入队 valid 接成
//   `io.sbuffer_enq(i).valid && ENABLE_SPB.B`，而 ENABLE_SPB = false。firtool 把这个常数推进来后：
//     * 入队永远 0 路（count_vsreq = 0），reqs 永远不写、复位后全无效；
//     * 于是出队永不 fire，deqPtr 恒为 (flag 0, value 0)，被折叠成常数；
//     * 两个端口 prefetch_train / sbuffer_enq 全被删掉 —— golden 只剩 clock / reset 两个端口。
//   但 enqPtrExt(0) 的更新式 `when(canEnqueue) { ptr := ptr + count_vsreq }` 里，CircularQueuePtr
//   的加法（溢出就减 QueueSize 并翻 flag）在 count=0 时并不能被 firtool 化简掉，于是这一个指针
//   （flag 1 位 + value 4 位）留了下来。它没有任何读者，是纯粹的死状态；照 golden 逐式保留
//   （FM 里两侧对称的未读比较点）。
//
// 保留下来的两条式子（count_vsreq 已代入 0，deqPtr 已代入 (0,0)）：
//   distanceBetween(enq, deq) = enq.flag == deq.flag ? enq.value : QUEUE_SIZE + enq.value（4 位截断）
//   canEnqueue                = distance + 0 <= QUEUE_SIZE
//   enq + 0（CircularQueuePtr.+）：sum = value + 0；diff = sum - QUEUE_SIZE；
//                                 diff >= 0 时 value := diff 并翻 flag，否则 value := sum
// 复位后指针停在 (0,0)，从此 diff < 0、永远不动 —— 只有上电随机初值落在 value >= 12 时才会动一次。
// golden 134 行 / 2 端口；无子模块。

module xs_Serializer_core #(
  parameter int unsigned QUEUE_SIZE = 12,   // SERIALIZER_SIZE
  parameter int unsigned PTR_W      = 4     // log2Up(QUEUE_SIZE)
)(
  input  logic clock,
  input  logic reset
);

  localparam logic [PTR_W-1:0] COUNT_VSREQ = '0;   // 入队路数：ENABLE_SPB=false ⇒ 恒 0

  // 入队指针 enqPtrExt(0)（异步复位到 0；deqPtr 恒 (0,0) 不存）。
  // 名字照 Chisel 的 enqPtrExt(0).flag/.value 展平写：它们没有任何读者，FM 无法靠签名分析配对，
  // 只能按名字配（见 verif/fm_target_config/Serializer.tcl）。
  logic             enqPtrExt_0_flag;
  logic [PTR_W-1:0] enqPtrExt_0_value;

  // distanceBetween(enqPtr, deqPtr=(0,0))
  logic [PTR_W-1:0] distance;
  assign distance = enqPtrExt_0_flag ? PTR_W'(QUEUE_SIZE + enqPtrExt_0_value) : enqPtrExt_0_value;

  logic can_enqueue;
  assign can_enqueue = ({1'b0, distance} + {1'b0, COUNT_VSREQ}) <= (PTR_W+1)'(QUEUE_SIZE);

  // CircularQueuePtr 加法：sum 多留一位，减 QUEUE_SIZE 后非负即回绕
  logic [PTR_W:0]   sum;
  logic signed [PTR_W+1:0] diff;
  logic             wrap;
  assign sum  = {1'b0, enqPtrExt_0_value} + {1'b0, COUNT_VSREQ};
  assign diff = $signed({1'b0, sum}) - $signed((PTR_W+2)'(QUEUE_SIZE));
  assign wrap = (diff >= 0);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enqPtrExt_0_flag  <= 1'b0;
      enqPtrExt_0_value <= '0;
    end else if (can_enqueue) begin
      enqPtrExt_0_flag  <= enqPtrExt_0_flag ^ wrap;
      enqPtrExt_0_value <= wrap ? diff[PTR_W-1:0] : sum[PTR_W-1:0];
    end
  end

endmodule

module Serializer (
  input  logic clock,
  input  logic reset
);

  xs_Serializer_core u_core (
    .clock (clock),
    .reset (reset)
  );

endmodule
