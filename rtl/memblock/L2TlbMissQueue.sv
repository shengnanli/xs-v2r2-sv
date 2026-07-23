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

  // 队列存储：实例化与 golden 完全相同的 ram_40x47 厂商 RAM 叶子（40 深 × 47 位，
  // 组合读端口 R0 + 时序写端口 W0）。
  //
  // 为什么用 ram_40x47 而不是 inline `mem [39:0]`：
  //   golden 的 ram_40x47 用 6 位地址寻址 40 深数组（0..39 环回，指针可证不越界），
  //   但 Formality 静态 elaboration 无法证明 6 位地址 ≤ 39，会对 golden 的组合读
  //   `Memory[R0_addr]` 抛 FMR_ELAB-147（“Index may take values outside array bound”），
  //   在 link 阶段升级为 unsuppressed error → golden set_top 失败 → 整个 SEC 中止。
  //   inline `mem [39:0]` 的组合读 `mem[deq_ptr]` 同样会触发 ELAB-147（本核旧版
  //   L2TlbMissQueue.sv:53 实证）。
  //   把存储折叠成与 golden 同名的 ram_40x47 厂商 RAM 叶子后，双侧都不提供其 body，
  //   经 hdlin_unresolved_modules=black_box 成为**对称匹配黑盒**（同 array_ext 厂商叶子
  //   方法学）：RAM 阵列不 elaborate → 无 ELAB-147；两侧同名同端口 → matched blackbox；
  //   环形指针/满空/flush 控制逻辑仍为可读 RTL、照常参与等价比对。
  //
  // W0_data / R0_data 位布局与 golden 逐位一致（见 Queue40_L2TlbMQBundle.sv ram_ext）：
  //   [46:44]=hptwId(=0) [43]=isLLptw [42]=isHptwReq(=0) [41:40]=source
  //   [39:38]=s2xlate    [37:0]=vpn
  localparam int RAM_W = VPN_W + 2 /*s2xlate*/ + SOURCE_W + 1 /*isHptwReq*/
                       + 1 /*isLLptw*/ + HPTWID_W;  // = 47

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

  // 入队 payload 打包成 golden ram_40x47 的 47 位布局。
  wire [RAM_W-1:0] ram_w0_data = { enq_bits.hptw_id,      // [46:44]
                                   enq_bits.is_llptw,     // [43]
                                   enq_bits.is_hptw_req,  // [42]
                                   enq_bits.source,       // [41:40]
                                   enq_bits.s2xlate,      // [39:38]
                                   enq_bits.vpn };        // [37:0]
  wire [RAM_W-1:0] ram_r0_data;

  ram_40x47 mem_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ram_r0_data),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data (ram_w0_data)
  );

  // 出队 payload 从 47 位布局解包回结构。
  assign deq_bits.hptw_id     = ram_r0_data[46:44];
  assign deq_bits.is_llptw    = ram_r0_data[43];
  assign deq_bits.is_hptw_req = ram_r0_data[42];
  assign deq_bits.source      = ram_r0_data[41:40];
  assign deq_bits.s2xlate     = ram_r0_data[39:38];
  assign deq_bits.vpn         = ram_r0_data[37:0];

  // 指针环回辅助：到队尾（QUEUE_SIZE-1）则回 0，否则 +1。
  function automatic logic [PTR_W-1:0] ptr_next(input logic [PTR_W-1:0] p);
    return (p == PTR_W'(QUEUE_SIZE-1)) ? '0 : p + 1'b1;
  endfunction

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
