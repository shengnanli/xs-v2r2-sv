// =============================================================================
//  PrefetchQueue —— L2 预取请求队列可读核 (xs_PrefetchQueue_core)
// -----------------------------------------------------------------------------
//  Prefetcher(L2 预取器顶层)的子模块: 32 深环形 FIFO, 缓存 BOP/receiver 汇入的
//  预取训练请求, 逐个吐给下游 pipe。空时旁路(bypass): io_deq 直接透传 io_enq。
//
//  payload = {tag(33)|set(9)|vaddr(44)|needT(1)|source(7)|pfSource(5)}。
//
//  环形指针语义(忠实 golden PrefetchQueue bug-for-bug):
//    empty = (head==tail) & ~valids[31]
//    full  = (head==tail) &  valids[31]
//    deq_valid = ~empty | enq_valid                    (空时旁路 enq)
//    deq_bits  = empty ? enq_bits : queue[head]
//    enq: enq_valid & tail==i  → 写 queue[i], valids[i] <= (~empty | ~deq_ready)
//    deq: (~empty & deq_ready) & head==i → valids[i] 清 0
//    head 前进: (enq & full & ~deq_ready) | (~empty & deq_ready)
//    tail 前进: enq_valid ? +(~empty | ~deq_ready) : +0
//
//  golden 内的 _GEN_5.._14 为 pfSource 分类/valids 计数的性能统计组合线, 无输出
//  端口消费 → firtool 死码消除, 本核不复刻(与 golden 逐位等价, 无观测差异)。
//
//  与 golden PrefetchQueue 逐位等价。
// =============================================================================
module xs_PrefetchQueue_core (
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_tag,
  input  [8:0]  io_enq_bits_set,
  input  [43:0] io_enq_bits_vaddr,
  input         io_enq_bits_needT,
  input  [6:0]  io_enq_bits_source,
  input  [4:0]  io_enq_bits_pfSource,
  input         io_deq_ready,
  output        io_deq_valid,
  output [32:0] io_deq_bits_tag,
  output [8:0]  io_deq_bits_set,
  output [43:0] io_deq_bits_vaddr,
  output        io_deq_bits_needT,
  output [6:0]  io_deq_bits_source,
  output [4:0]  io_deq_bits_pfSource
);

  localparam int DEPTH = 32;

  // ---- 存储阵列 (32 深, 每条 payload 六字段) ----
  reg  [32:0] queue_tag    [DEPTH];
  reg  [8:0]  queue_set    [DEPTH];
  reg  [43:0] queue_vaddr  [DEPTH];
  reg         queue_needT  [DEPTH];
  reg  [6:0]  queue_source [DEPTH];
  reg  [4:0]  queue_pfSource[DEPTH];
  reg         valids       [DEPTH];

  reg  [4:0]  head;
  reg  [4:0]  tail;

  // ---- 空/满探测 ----
  wire        _full_T     = (head == tail);
  wire        empty_probe = _full_T & ~valids[31];
  wire        full_probe  = _full_T &  valids[31];

  // ---- 出队(空时旁路 enq) ----
  wire        io_deq_valid_0 = ~empty_probe | io_enq_valid;

  assign io_deq_valid       = io_deq_valid_0;
  assign io_deq_bits_tag      = empty_probe ? io_enq_bits_tag      : queue_tag[head];
  assign io_deq_bits_set      = empty_probe ? io_enq_bits_set      : queue_set[head];
  assign io_deq_bits_vaddr    = empty_probe ? io_enq_bits_vaddr    : queue_vaddr[head];
  assign io_deq_bits_needT    = empty_probe ? io_enq_bits_needT    : queue_needT[head];
  assign io_deq_bits_source   = empty_probe ? io_enq_bits_source   : queue_source[head];
  assign io_deq_bits_pfSource = empty_probe ? io_enq_bits_pfSource : queue_pfSource[head];

  // ---- valids 更新条件(忠实 golden) ----
  wire        _GEN_15      = ~empty_probe & io_deq_ready;   // 本拍真正出队一条
  wire        _valids_T_2  = ~empty_probe | ~io_deq_ready;  // 新写入条目的 valid 值

  integer i;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      for (i = 0; i < DEPTH; i = i + 1) begin
        queue_tag[i]     <= 33'h0;
        queue_set[i]     <= 9'h0;
        queue_vaddr[i]   <= 44'h0;
        queue_needT[i]   <= 1'h0;
        queue_source[i]  <= 7'h0;
        queue_pfSource[i]<= 5'h0;
        valids[i]        <= 1'h0;
      end
      head <= 5'h0;
      tail <= 5'h0;
    end
    else begin
      for (i = 0; i < DEPTH; i = i + 1) begin
        if (io_enq_valid & (tail == i[4:0])) begin
          // 入队: 写入 tail 指向的槽
          queue_tag[i]      <= io_enq_bits_tag;
          queue_set[i]      <= io_enq_bits_set;
          queue_vaddr[i]    <= io_enq_bits_vaddr;
          queue_needT[i]    <= io_enq_bits_needT;
          queue_source[i]   <= io_enq_bits_source;
          queue_pfSource[i] <= io_enq_bits_pfSource;
          valids[i]         <= _valids_T_2;
        end
        else begin
          // 非入队槽: 若本拍从 head 出队且命中该槽则清 valid, 否则保持
          valids[i] <= ~(_GEN_15 & (head == i[4:0])) & valids[i];
        end
      end

      // head 前进: 满且入队却无法出队时也推进(覆盖旧头), 或正常出队
      if (io_enq_valid & full_probe & ~io_deq_ready)
        head <= 5'(head + 5'h1);
      else if (_GEN_15)
        head <= 5'(head + 5'h1);

      // tail 前进: 入队时 +(~empty | ~deq_ready), 否则不动
      if (io_enq_valid)
        tail <= 5'(tail + {4'h0, (~empty_probe | ~io_deq_ready)});
    end
  end

endmodule
