// =============================================================================
// L2TlbMissQueue.sv —— L2TLB 的 miss 回灌队列：40 项、带 flush 的 FIFO
//
// 对应 Chisel: xiangshan.cache.mmu.L2TlbMissQueue（src/main/scala/xiangshan/cache/mmu/L2TLBMissQueue.scala）
//     io.out <> Queue(io.in, MissQueueSize, flush = Some(sfence | satp/vsatp/hgatp/priv.virt changed))
//
// 在 L2TLB 里的位置：page cache 查完没命中、又暂时进不了 PTW/LLPTW 的请求（mq_arb 出口）进本队列
// 排队，出队后回到 arb2 第 2 路（Arbiter5_L2TlbWithHptwIdBundle）重新查 page cache。
// MissQueueSize = ifilterSize + dfilterSize = 40，保证 TLB 侧所有在途请求都能放下、不会死锁。
//
// 结构 = golden 的两层（L2TlbMissQueue 套 Queue40_L2TlbMQBundle 套 ram_40x47）压成一层：
//   * 控制：标准 chisel3 Queue（pipe=false/flow=false）—— enq_ptr/deq_ptr 在 0..39 回绕，maybe_full 区分
//     指针相等时的空/满；外加 flush：一拍把两个指针归零、maybe_full 清零（在途请求全丢）。
//     ★为什么不复用 rtl/common/xs_ChiselQueue_core.sv★：那个核没有 flush 口；给它加口会让共用它的
//     16 个已签目标（scripts/check_shared_impl_impact.py 实测）全部 STALE 重证。G1 golden 里带 flush 的
//     Queue 只有本模块一个，所以在这里就地写控制，语义与那个核逐条一致、只多 flush 一项。
//   * 存储：照 golden 例化同名 ram_40x47（40 深 × 47 位，组合读 R0 / 时序写 W0）。它在 FM 里是两侧对称
//     黑盒（不能 inline：6 位地址寻址 40 深数组，FMR_ELAB-147 会让 golden 侧 link 失败；
//     裁定与审计见 verif/vendor_boundary.tsv 的 ram_40x47 行、verif/ut/L2TlbMissQueue/Makefile 头注）。
//   * 47 位字的布局与 golden 逐位相同；isHptwReq / hptwId 入队恒 0（mq_arb 两路都是 false.B / DontCare，
//     firtool 删了这两个入口端口），但出口照样从 ram 读出来 —— 照抄 golden，不省。
//
// golden 133 行（+ Queue40_L2TlbMQBundle 194 行）/ 22 端口。
// =============================================================================

package l2tlbmissqueue_pkg;

  localparam int VPN_W    = 38;  // vpnLen
  localparam int SOURCE_W = 2;   // bSourceWidth
  localparam int HPTWID_W = 3;   // log2Up(llptwsize)
  localparam int DEPTH    = 40;  // MissQueueSize
  localparam int PTR_W    = 6;   // 0..39

  // L2TlbWithHptwIdBundle（isLLptw 在 Scala 里也属于它）；字段顺序 = ram 字里从高到低
  typedef struct packed {
    logic [HPTWID_W-1:0] hptw_id;      // [46:44]
    logic                is_llptw;     // [43]
    logic                is_hptw_req;  // [42]
    logic [SOURCE_W-1:0] source;       // [41:40]
    logic [1:0]          s2xlate;      // [39:38]
    logic [VPN_W-1:0]    vpn;          // [37:0]
  } mq_entry_t;

endpackage

module xs_L2TlbMissQueue_core
  import l2tlbmissqueue_pkg::*;
(
  input  logic      clock,
  input  logic      reset,
  input  logic      flush,
  // 入队
  input  logic      enq_valid,
  output logic      enq_ready,
  input  mq_entry_t enq_bits,
  // 出队
  output logic      deq_valid,
  input  logic      deq_ready,
  output mq_entry_t deq_bits
);

  // ---------------------------------------------------------------------------
  // 指针、空满、握手
  // ---------------------------------------------------------------------------
  logic [PTR_W-1:0] enq_ptr;     // 下一个写入槽
  logic [PTR_W-1:0] deq_ptr;     // 队头
  logic             maybe_full;  // 指针相等时：1 = 满，0 = 空
  logic             ptr_match, empty, full, do_enq, do_deq;

  assign ptr_match = (enq_ptr == deq_ptr);
  assign empty     = ptr_match && !maybe_full;
  assign full      = ptr_match &&  maybe_full;

  assign enq_ready = !full;
  assign deq_valid = !empty;
  assign do_enq    = enq_valid && enq_ready;
  assign do_deq    = deq_ready && deq_valid;

  // 深度 40 不是 2 的幂：到 39 显式回 0
  function automatic logic [PTR_W-1:0] next_ptr(input logic [PTR_W-1:0] p);
    return (p == PTR_W'(DEPTH - 1)) ? '0 : p + 1'b1;
  endfunction

  // flush 优先：两个指针归零（不论这拍有没有进出），maybe_full 清零 —— 队列整体作废。
  // maybe_full 只在"只进不出"那拍置 1、"只出不进"那拍清 0。
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
        if (do_enq) enq_ptr <= next_ptr(enq_ptr);
        if (do_deq) deq_ptr <= next_ptr(deq_ptr);
      end
      maybe_full <= !flush && ((do_enq != do_deq) ? do_enq : maybe_full);
    end
  end

  // ---------------------------------------------------------------------------
  // 存储：golden 同名 ram_40x47（组合读队头，入队那拍写 enq_ptr 槽）
  // ---------------------------------------------------------------------------
  // 注意 W0_en 用的是 do_enq，flush 那拍若同时入队，数据照写（随后指针被归零，等于丢掉）—— golden 同。
  logic [$bits(mq_entry_t)-1:0] ram_rdata;

  ram_40x47 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ram_rdata),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data (enq_bits)
  );

  assign deq_bits = mq_entry_t'(ram_rdata);

endmodule

// golden 同名 wrapper：端口逐名逐宽同 golden；flush 五项 OR、入队补两个恒 0 字段。
module L2TlbMissQueue
  import l2tlbmissqueue_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  input  logic        io_sfence_valid,
  input  logic        io_csr_satp_changed,
  input  logic        io_csr_vsatp_changed,
  input  logic        io_csr_hgatp_changed,
  input  logic        io_csr_priv_virt_changed,
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic [37:0] io_in_bits_req_info_vpn,
  input  logic [1:0]  io_in_bits_req_info_s2xlate,
  input  logic [1:0]  io_in_bits_req_info_source,
  input  logic        io_in_bits_isLLptw,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_req_info_vpn,
  output logic [1:0]  io_out_bits_req_info_s2xlate,
  output logic [1:0]  io_out_bits_req_info_source,
  output logic        io_out_bits_isHptwReq,
  output logic        io_out_bits_isLLptw,
  output logic [2:0]  io_out_bits_hptwId
);

  mq_entry_t enq_entry, deq_entry;

  assign enq_entry = '{hptw_id:     '0,   // mq_arb 两路都是 DontCare（firtool 取 0）
                       is_llptw:    io_in_bits_isLLptw,
                       is_hptw_req: 1'b0, // mq_arb 两路都是 false.B
                       source:      io_in_bits_req_info_source,
                       s2xlate:     io_in_bits_req_info_s2xlate,
                       vpn:         io_in_bits_req_info_vpn};

  xs_L2TlbMissQueue_core u_core (
    .clock     (clock),
    .reset     (reset),
    .flush     (io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
                | io_csr_hgatp_changed | io_csr_priv_virt_changed),
    .enq_valid (io_in_valid),
    .enq_ready (io_in_ready),
    .enq_bits  (enq_entry),
    .deq_valid (io_out_valid),
    .deq_ready (io_out_ready),
    .deq_bits  (deq_entry)
  );

  assign io_out_bits_req_info_vpn     = deq_entry.vpn;
  assign io_out_bits_req_info_s2xlate = deq_entry.s2xlate;
  assign io_out_bits_req_info_source  = deq_entry.source;
  assign io_out_bits_isHptwReq        = deq_entry.is_hptw_req;
  assign io_out_bits_isLLptw          = deq_entry.is_llptw;
  assign io_out_bits_hptwId           = deq_entry.hptw_id;

endmodule
