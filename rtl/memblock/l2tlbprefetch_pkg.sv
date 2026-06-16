// =============================================================================
// xs_l2tlbprefetch_pkg —— L2TlbPrefetch 可读重写的类型与参数
//
// 设计来源：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/L2TlbPrefetch.scala class L2TlbPrefetch
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala L2TlbWithHptwIdBundle
// =============================================================================
package xs_l2tlbprefetch_pkg;

  localparam int VPN_W        = 38;  // vpnLen
  localparam int SECTOR_BITS  = 3;   // PtwL0SectorIdxLen：sector 内 4KB PTE 索引位宽
  localparam int LINE_VPN_W   = VPN_W - SECTOR_BITS; // 去掉 sector 位后的“行 VPN” = 35
  localparam int SOURCE_W     = 2;   // bSourceWidth
  localparam int OLD_REC_N    = 4;   // 最近预取记录条数（去重窗口）
  localparam int OLD_IDX_W    = 2;   // log2Ceil(OLD_REC_N)

  // prefetchID = PtwWidth = 2（见 MMUConst.scala）。预取请求的 source 标记。
  localparam logic [SOURCE_W-1:0] PREFETCH_ID = 2'h2;

  // s2xlate 模式编码（与 ptw 一致）。
  localparam logic [1:0] NO_S2XLATE  = 2'h0;
  localparam logic [1:0] ONLY_STAGE1 = 2'h1;
  localparam logic [1:0] ONLY_STAGE2 = 2'h2;
  localparam logic [1:0] ALL_STAGE   = 2'h3;

  // L2TLB 内部请求 bundle（L2TlbWithHptwIdBundle 中 prefetch 用到的字段）。
  typedef struct packed {
    logic [VPN_W-1:0]    vpn;
    logic [1:0]          s2xlate;
    logic [SOURCE_W-1:0] source;
  } l2tlb_req_info_t;

  // 取“下一行”的行首 VPN：把 VPN 去掉 sector 位后 +1，再补回 sector 位为 0。
  // 预取下一条 cacheline 的页表项（顺序流预取）。
  function automatic logic [VPN_W-1:0] get_next_line(input logic [VPN_W-1:0] vpn);
    return {vpn[VPN_W-1:SECTOR_BITS] + 1'b1, {SECTOR_BITS{1'b0}}};
  endfunction

  // 两个 VPN 是否落在同一 cacheline（去 sector 位后相等）。用于去重。
  function automatic logic same_line(
    input logic [VPN_W-1:0] a, input logic [VPN_W-1:0] b
  );
    return a[VPN_W-1:SECTOR_BITS] == b[VPN_W-1:SECTOR_BITS];
  endfunction

endpackage
