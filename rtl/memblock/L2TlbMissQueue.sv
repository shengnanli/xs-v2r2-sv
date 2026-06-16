// =============================================================================
// xs_L2TlbMissQueue_core —— L2TLB Miss 队列（可读 SystemVerilog 重写）
//
// 设计意图来自 L2TLBMissQueue.scala class L2TlbMissQueue：
//   io.out <> Queue(io.in, MissQueueSize, flush = sfence|satp|vsatp|hgatp changed)
//
// 它本质上就是一个深度 MissQueueSize=40、带 flush 的 FIFO，作为“在 page cache
// 里 pde miss 的请求”的延迟槽（delay slot）：这些请求需要重新访问 page cache，
// 队列给它们排队缓冲；若 pde 在 page cache 命中，则不进本队列而直接走 LLPTW。
// require(MissQueueSize >= ifilterSize + dfilterSize) 保证不会死锁。
//
// 微架构要点（对照 Chisel Queue 的展开实现）：
//   1. 环形缓冲：enq_ptr/deq_ptr 在 0..39 间环回（到 39 回 0），maybe_full
//      区分 ptr 相等时是满还是空。
//   2. 读组合、写时序：deq 数据是当拍组合读 mem[deq_ptr]（与 golden 的
//      ram_40x47 组合读端口一致），写入在 enq 拍后可见。
//   3. flush 一拍清空：enq_ptr/deq_ptr 归零、maybe_full 清零，丢弃全部在途请求。
// =============================================================================
module xs_L2TlbMissQueue_core
  import xs_l2tlbmissqueue_pkg::*;
(
  input  logic              clock,
  input  logic              reset,

  input  logic              flush,        // sfence / satp / vsatp / hgatp changed

  output logic              enq_ready,
  input  logic              enq_valid,
  input  l2tlb_mq_bundle_t  enq_bits,

  input  logic              deq_ready,
  output logic              deq_valid,
  output l2tlb_mq_bundle_t  deq_bits
);

  // 队列存储（组合读、时序写，等价 golden 的 ram_40x47）。
  l2tlb_mq_bundle_t mem [QUEUE_SIZE-1:0];

  logic [PTR_W-1:0] enq_ptr;
  logic [PTR_W-1:0] deq_ptr;
  logic             maybe_full;

  // ptr 相等时由 maybe_full 区分满/空。
  wire ptr_match = (enq_ptr == deq_ptr);
  wire empty     = ptr_match && !maybe_full;
  wire full      = ptr_match &&  maybe_full;

  wire do_enq = !full  && enq_valid;
  wire do_deq = deq_ready && !empty;

  assign enq_ready = !full;
  assign deq_valid = !empty;
  assign deq_bits  = mem[deq_ptr];

  // 指针环回辅助：到队尾（QUEUE_SIZE-1）则回 0，否则 +1。
  function automatic logic [PTR_W-1:0] ptr_next(input logic [PTR_W-1:0] p);
    return (p == PTR_W'(QUEUE_SIZE-1)) ? '0 : p + 1'b1;
  endfunction

  // 写入：do_enq 时把 enq_bits 写到 enq_ptr（同步）。
  always_ff @(posedge clock) begin
    if (do_enq)
      mem[enq_ptr] <= enq_bits;
  end

  // 指针与 maybe_full：flush 优先清零。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr    <= '0;
      deq_ptr    <= '0;
      maybe_full <= 1'b0;
    end else begin
      if (flush) begin
        enq_ptr <= '0;
        deq_ptr <= '0;
      end else begin
        if (do_enq) enq_ptr <= ptr_next(enq_ptr);
        if (do_deq) deq_ptr <= ptr_next(deq_ptr);
      end
      // 只有 enq/deq 数目不等时才改变满标志：单独 enq→可能满，单独 deq→不满。
      maybe_full <= !flush && ((do_enq == do_deq) ? maybe_full : do_enq);
    end
  end

endmodule
