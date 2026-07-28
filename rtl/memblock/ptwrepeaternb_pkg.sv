// =============================================================================
// xs_ptwrepeaternb_pkg —— PTWRepeaterNB 的类型
//
// 对应 Chisel: src/main/scala/xiangshan/cache/mmu/Repeater.scala
//   class PTWRepeaterNB(passReady=false, Width=1)
//
// PTWRepeaterNB = 单请求（Width=1）非阻塞 PTW 请求/响应中继器。
//   它在 L1 TLB（itlb / dtlb）与共享 L2 TLB（PTW）之间转发一次页表游走请求，
//   缓冲“一个在途请求 + 一个在途响应”（sent/recv 两个状态位 + 一份 req/resp 寄存）。
//   sfence / csr 变更经 DelayN_1（2 拍）延迟后清空 sent/recv（flush 在途请求）。
//
// 数据流：
//   - tlb 侧 req 进来（~sent 时接收）→ 锁存 {vpn,s2xlate}，置 sent；
//   - sent=1 时向 ptw 侧发 req；ptw 接收（ptw_req_ready）后清 sent；
//   - ptw 侧 resp 回来（~recv 时接收）→ 锁存整包 resp，置 recv；
//   - recv=1 时向 tlb 侧发 resp；tlb 接收（tlb_resp_ready）后清 recv；
//   - flush（DelayN_1 输出）同时清 sent 和 recv。
// =============================================================================
package xs_ptwrepeaternb_pkg;

  // PTW 响应整包（io_ptw_resp_bits / io_tlb_resp_bits 的 payload）——纯打拍锁存。
  // 字段顺序/位宽对齐 golden io_ptw_resp_bits_*。
  typedef struct packed {
    logic [1:0]  s2xlate;
    // s1_entry
    logic [34:0] s1_entry_tag;
    logic [15:0] s1_entry_asid;
    logic [13:0] s1_entry_vmid;
    logic        s1_entry_n;
    logic [1:0]  s1_entry_pbmt;
    logic        s1_entry_perm_d, s1_entry_perm_a, s1_entry_perm_g, s1_entry_perm_u;
    logic        s1_entry_perm_x, s1_entry_perm_w, s1_entry_perm_r;
    logic [1:0]  s1_entry_level;
    logic        s1_entry_v;
    logic [40:0] s1_entry_ppn;
    logic [2:0]  s1_addr_low;
    logic [2:0]  s1_ppn_low_0, s1_ppn_low_1, s1_ppn_low_2, s1_ppn_low_3;
    logic [2:0]  s1_ppn_low_4, s1_ppn_low_5, s1_ppn_low_6, s1_ppn_low_7;
    logic        s1_valididx_0, s1_valididx_1, s1_valididx_2, s1_valididx_3;
    logic        s1_valididx_4, s1_valididx_5, s1_valididx_6, s1_valididx_7;
    logic        s1_pteidx_0, s1_pteidx_1, s1_pteidx_2, s1_pteidx_3;
    logic        s1_pteidx_4, s1_pteidx_5, s1_pteidx_6, s1_pteidx_7;
    logic        s1_pf, s1_af;
    // s2_entry
    logic [37:0] s2_entry_tag;
    logic [13:0] s2_entry_vmid;
    logic        s2_entry_n;
    logic [1:0]  s2_entry_pbmt;
    logic [37:0] s2_entry_ppn;
    logic        s2_entry_perm_d, s2_entry_perm_a, s2_entry_perm_g, s2_entry_perm_u;
    logic        s2_entry_perm_x, s2_entry_perm_w, s2_entry_perm_r;
    logic [1:0]  s2_entry_level;
    logic        s2_gpf, s2_gaf;
  } ptw_resp_t;

endpackage
