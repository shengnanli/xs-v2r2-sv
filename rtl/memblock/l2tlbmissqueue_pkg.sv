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
