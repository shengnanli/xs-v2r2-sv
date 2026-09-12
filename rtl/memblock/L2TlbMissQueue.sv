// =============================================================================
// xs_l2tlbmissqueue_pkg —— L2TlbMissQueue 可读重写的类型与参数
//
// 设计来源：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/L2TLBMissQueue.scala
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala L2TlbWithHptwIdBundle
// =============================================================================
package xs_l2tlbmissqueue_pkg;

  localparam int VPN_W     = 38;  // vpnLen
  localparam int SOURCE_W  = 2;   // bSourceWidth
  localparam int HPTWID_W  = 3;   // log2Up(llptwsize)

  // MissQueueSize = ifilterSize + dfilterSize = 40（见 MMUConst.scala）。
  localparam int QUEUE_SIZE = 40;
  localparam int PTR_W      = 6;   // log2 上取整可寻址 0..39（环回点 39）

  // L2TlbWithHptwIdBundle：请求信息 + L2TLB 内部路由标记。
  // 注意：MissQueue 入队侧仅提供 vpn/s2xlate/source/isLLptw；isHptwReq 与
  // hptwId 入队恒为 0（golden firtool 据此裁剪了对应入端口）。
  typedef struct packed {
    logic [VPN_W-1:0]    vpn;
    logic [1:0]          s2xlate;
    logic [SOURCE_W-1:0] source;
    logic                is_hptw_req;
    logic                is_llptw;
    logic [HPTWID_W-1:0] hptw_id;
  } l2tlb_mq_bundle_t;

endpackage

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

// 自动生成：scripts/gen_l2tlbmissqueue.py —— 仅机械端口适配，核心逻辑在 xs_L2TlbMissQueue_core

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module L2TlbMissQueue import xs_l2tlbmissqueue_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  io_csr_satp_changed,
  input  io_csr_vsatp_changed,
  input  io_csr_hgatp_changed,
  output io_in_ready,
  input  io_in_valid,
  input  [37:0] io_in_bits_req_info_vpn,
  input  [1:0] io_in_bits_req_info_s2xlate,
  input  [1:0] io_in_bits_req_info_source,
  input  io_in_bits_isLLptw,
  input  io_out_ready,
  output io_out_valid,
  output [37:0] io_out_bits_req_info_vpn,
  output [1:0] io_out_bits_req_info_s2xlate,
  output [1:0] io_out_bits_req_info_source,
  output io_out_bits_isHptwReq,
  output io_out_bits_isLLptw,
  output [2:0] io_out_bits_hptwId
);

  l2tlb_mq_bundle_t enq_bits_bus;
  l2tlb_mq_bundle_t deq_bits_bus;

  // 入队 payload：isHptwReq / hptwId 入队恒为 0（与 golden 一致）。
  assign enq_bits_bus.vpn         = io_in_bits_req_info_vpn;
  assign enq_bits_bus.s2xlate     = io_in_bits_req_info_s2xlate;
  assign enq_bits_bus.source      = io_in_bits_req_info_source;
  assign enq_bits_bus.is_hptw_req = 1'b0;
  assign enq_bits_bus.is_llptw    = io_in_bits_isLLptw;
  assign enq_bits_bus.hptw_id     = 3'h0;

  xs_L2TlbMissQueue_core u_core (
    .clock(clock),
    .reset(reset),
    .flush(io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed | io_csr_hgatp_changed),
    .enq_ready(io_in_ready),
    .enq_valid(io_in_valid),
    .enq_bits(enq_bits_bus),
    .deq_ready(io_out_ready),
    .deq_valid(io_out_valid),
    .deq_bits(deq_bits_bus)
  );

  assign io_out_bits_req_info_vpn     = deq_bits_bus.vpn;
  assign io_out_bits_req_info_s2xlate = deq_bits_bus.s2xlate;
  assign io_out_bits_req_info_source  = deq_bits_bus.source;
  assign io_out_bits_isHptwReq        = deq_bits_bus.is_hptw_req;
  assign io_out_bits_isLLptw          = deq_bits_bus.is_llptw;
  assign io_out_bits_hptwId           = deq_bits_bus.hptw_id;

endmodule
