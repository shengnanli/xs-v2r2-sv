// PTWFilter.sv —— TLB miss 请求的去重队列（golden 模块 PTWFilter 的重写）
//
// 对应 Chisel: xiangshan.cache.mmu.PTWFilter（Repeater.scala），本配置下只用于前端 ITLB：
// Width=3（ITLB 的 3 个 ptw 请求口），Size=8，FenceDelay=2；vpnLen=38，H 扩展打开。
//
// 位置：ITLB 与 L2TLB（页表遍历器 PTW）之间。ITLB 每次 miss 都会发 ptw 请求，同一页往往被
// 连续多条取指请求、多个端口重复问到。本模块把请求去重后排队，逐个发给 L2TLB；L2TLB 的回应
// 广播回 ITLB，并顺手把队列里所有「问的是同一页」的项一起消掉。
//
// 数据通路（请求侧打一拍后入队，所以是两段）：
//   第 0 拍  io.tlb.req[w] 到达。与三样东西比：刚回来的 ptw 回应（已经有答案了）、上一拍刚寄存
//            的请求（同一页连问两拍）、队列里已有的项（oldMatch）、同拍更靠前的端口（newMatch）。
//            前两样直接决定「这拍要不要寄存 valid」，后两样把比较结果寄存起来留到下一拍用。
//   第 1 拍  寄存后的请求 tlb_req[w]：没被合并掉的入队（reqs_valid），占用 enqPtr 起的连续槽。
//   队列     8 项环形队列，三个指针：enqPtr 入队、issPtr 发给 L2TLB、deqPtr 回收。
//            项的 valid 位 v 被 ptw 回应清掉（请求得到了答案）；deqPtr/issPtr 遇到 v=0 的项就跳过。
//   回应侧   io.ptw.resp 打一拍成 ptwResp；只有它命中了队列里的某一项才向 ITLB 报 valid。
//
// 「命中」的含义（ptw_resp_hit）：ptw 回应是一个「扇区」表项（一次带回同一页表页里相邻的 8 个 PTE，
// 也可能是大页 / Svnapot 64KB 页），请求的 vpn 落在它覆盖的范围内就算命中；两级地址翻译
// （s2xlate）不同，比较的 tag / asid / vmid 也不同，见函数注释。
//
// 怪癖（照搬 golden，不要「修」）：
//   - io.tlb.req.ready 是「假 ready」：按「这拍三个口都收」的最坏情况估容量（canEnqueue_fake）。
//     真正入队看的是 canEnqueue（寄存后、去重后的数目）；估不准时请求会被丢掉，由 ITLB 重发。
//   - 入队同时若 ptw 回应正好命中这条请求，它「假入队」：占槽、但 v 写 0（tlb_req_flushed）。
//   - 发给 L2TLB 时若这一项已被上一拍的 ptw 回应覆盖（issue_filtered），不发请求、直接把 v 清掉，
//     但 issPtr 照样前进（issue_fire_fake 仍按 ready 算）。
//   - 复位域：控制位异步复位；队列内容（vpn/s2xlate/getGpa）、ptwResp、寄存的请求 bits 不复位。
//   - flush（sfence / satp / vsatp / hgatp / 虚拟化模式变化，延迟 2 拍）清空队列，并把当拍的
//     ptwResp_valid 也压掉。
//   - Scala 里的 ports / memidx / resp vector 在本配置下没有读者，golden 里已被 firtool 消掉。

package ptwfilter_pkg;
  localparam int unsigned WIDTH      = 3;    // ITLB 请求口数
  localparam int unsigned SIZE       = 8;    // 队列深度
  localparam int unsigned PTR_W      = 3;
  localparam int unsigned CNT_W      = 4;    // 0..SIZE
  localparam int unsigned VPN_W      = 38;   // vpnLen（Sv48x4 的 gvpn 也是 38 位）
  localparam int unsigned VPNN_W     = 9;    // 每级页表索引 9 位
  localparam int unsigned SECTOR_W   = 3;    // 一个扇区 8 个相邻 PTE
  localparam int unsigned NAPOT_BITS = 4;    // Svnapot 64KB = 16 个 4KB 页

  // s2xlate 编码
  localparam logic [1:0] NO_S2XLATE  = 2'b00;
  localparam logic [1:0] ONLY_STAGE1 = 2'b01;
  localparam logic [1:0] ONLY_STAGE2 = 2'b10;
  localparam logic [1:0] ALL_STAGE   = 2'b11;

  // L2TLB 的回应（PtwRespS2）。字段名与 golden 寄存器 ptwResp_<字段> 的后缀一致。
  typedef struct packed {
    logic [1:0]      s2xlate;
    // ---- s1：第一级（VS / 无虚拟化）翻译结果，扇区表项 ----
    logic [34:0]     s1_entry_tag;     // vpn[37:3]
    logic [15:0]     s1_entry_asid;
    logic [13:0]     s1_entry_vmid;
    logic            s1_entry_n;       // Svnapot
    logic [1:0]      s1_entry_pbmt;
    logic            s1_entry_perm_d;
    logic            s1_entry_perm_a;
    logic            s1_entry_perm_g;
    logic            s1_entry_perm_u;
    logic            s1_entry_perm_x;
    logic            s1_entry_perm_w;
    logic            s1_entry_perm_r;
    logic [1:0]      s1_entry_level;   // 0 = 4KB，1 = 2MB，2 = 1GB，3 = 512GB
    logic            s1_entry_v;
    logic [40:0]     s1_entry_ppn;
    logic [2:0]      s1_addr_low;      // 本次请求在扇区里的下标
    logic [7:0][2:0] s1_ppn_low;
    logic [7:0]      s1_valididx;      // 扇区里哪几个 PTE 与请求的那个同属性、可合并
    logic [7:0]      s1_pteidx;
    logic            s1_pf;
    logic            s1_af;
    // ---- s2：第二级（G-stage）翻译结果 ----
    logic [37:0]     s2_entry_tag;     // gvpn
    logic [13:0]     s2_entry_vmid;
    logic            s2_entry_n;
    logic [1:0]      s2_entry_pbmt;
    logic [37:0]     s2_entry_ppn;
    logic            s2_entry_perm_d;
    logic            s2_entry_perm_a;
    logic            s2_entry_perm_g;
    logic            s2_entry_perm_u;
    logic            s2_entry_perm_x;
    logic            s2_entry_perm_w;
    logic            s2_entry_perm_r;
    logic [1:0]      s2_entry_level;
    logic            s2_gpf;
    logic            s2_gaf;
  } ptw_resp_t;

  // 按页大小逐级比 vpn：level 越大页越大，比的高位段越少
  //   tag_match[3..1] 是三段高位，tag_match0 是最低 9 位那一段（4KB / 64KB 页才比）
  function automatic logic level_match(input logic [1:0] level,
                                       input logic m3, input logic m2, input logic m1, input logic m0);
    unique case (level)
      2'd3: return m3;
      2'd2: return m3 & m2;
      2'd1: return m3 & m2 & m1;
      2'd0: return m3 & m2 & m1 & m0;
    endcase
  endfunction

  // ptwResp_hit：请求 (vpn, req_s2xlate) 是否被回应 r 覆盖
  //   noS2xlate  —— 用 s1（扇区）比，asid = satp.asid；4KB 页还要求请求的那个 PTE 在 valididx 里
  //   onlyStage2 —— 用 s2 比（tag 是完整 gvpn），vmid = hgatp.vmid
  //   onlyStage1 / allStage —— 用 s1 的 {tag, addr_low} 比完整 vpn；页大小取两级里较小的；
  //                 asid = vsatp.asid，还要 vmid 相等
  function automatic logic ptw_resp_hit(
      input logic [VPN_W-1:0] vpn,
      input logic [1:0]       req_s2xlate,
      input ptw_resp_t        r,
      input logic [15:0]      satp_asid,
      input logic [15:0]      vsatp_asid,
      input logic [15:0]      hgatp_vmid);
    logic        noS2_hit, onlyS2_hit, all_onlyS1_hit;
    logic        s1_m3, s1_m2, s1_m1, s1_m0_sector, s1_m0_full;
    logic        s2_m3, s2_m2, s2_m1, s2_m0;
    logic        s1_super, allStage_n, n;
    logic [1:0]  level;

    // s1 的 tag 是 vpn[37:3]：三段高位对所有 s1 型比较都一样
    s1_m3 = r.s1_entry_tag[34:24] == vpn[37:27];
    s1_m2 = r.s1_entry_tag[23:15] == vpn[26:18];
    s1_m1 = r.s1_entry_tag[14:6]  == vpn[17:9];

    // ---- noS2xlate：扇区命中（最低段只比到扇区粒度 vpn[8:3]；napot 时比到 vpn[8:4]）----
    s1_m0_sector = r.s1_entry_n ? (r.s1_entry_tag[5:1] == vpn[8:4])
                                : (r.s1_entry_tag[5:0] == vpn[8:3]);
    s1_super     = (r.s1_entry_level != 2'd0) | r.s1_entry_n;
    noS2_hit     = ((r.s1_entry_asid == satp_asid) | r.s1_entry_perm_g)
                 & level_match(r.s1_entry_level, s1_m3, s1_m2, s1_m1, s1_m0_sector)
                 & (s1_super | r.s1_valididx[vpn[SECTOR_W-1:0]]);

    // ---- onlyStage2：G-stage 表项，tag 是完整 gvpn ----
    s2_m3 = r.s2_entry_tag[37:27] == vpn[37:27];
    s2_m2 = r.s2_entry_tag[26:18] == vpn[26:18];
    s2_m1 = r.s2_entry_tag[17:9]  == vpn[17:9];
    s2_m0 = r.s2_entry_n ? (r.s2_entry_tag[8:4] == vpn[8:4])
                         : (r.s2_entry_tag[8:0] == vpn[8:0]);
    onlyS2_hit = ({2'b0, r.s2_entry_vmid} == hgatp_vmid)
               & level_match(r.s2_entry_level, s2_m3, s2_m2, s2_m1, s2_m0);

    // ---- onlyStage1 / allStage：精确到单个 PTE（{tag, addr_low} 是完整 vpn）----
    // allStage 时页大小取两级里较小的；两级合成后仍是 64KB 页的三种情形见 Scala 注释
    level      = ((r.s2xlate == ONLY_STAGE1) | (r.s1_entry_level < r.s2_entry_level))
               ? r.s1_entry_level : r.s2_entry_level;
    allStage_n = (r.s1_entry_n & (r.s2_entry_level != 2'd0))
               | (r.s2_entry_n & (r.s1_entry_level != 2'd0))
               | (r.s1_entry_n & r.s2_entry_n);
    n          = (r.s2xlate == ONLY_STAGE1) ? r.s1_entry_n : allStage_n;
    s1_m0_full = n ? (vpn[8:4] == r.s1_entry_tag[5:1])
                   : (vpn[8:0] == {r.s1_entry_tag[5:0], r.s1_addr_low});
    all_onlyS1_hit = level_match(level, s1_m3, s1_m2, s1_m1, s1_m0_full)
                   & ({2'b0, r.s1_entry_vmid} == hgatp_vmid)
                   & ((r.s1_entry_asid == vsatp_asid) | r.s1_entry_perm_g);

    return (req_s2xlate == r.s2xlate)
         & ((r.s2xlate == NO_S2XLATE)  ? noS2_hit
          : (r.s2xlate == ONLY_STAGE2) ? onlyS2_hit
          :                              all_onlyS1_hit);
  endfunction
endpackage

module xs_PTWFilter_core
  import ptwfilter_pkg::*;
(
  input  logic                        clock,
  input  logic                        reset,
  // ---- 冲刷源与 CSR ----
  input  logic                        io_sfence_valid,
  input  logic [15:0]                 io_csr_satp_asid,
  input  logic                        io_csr_satp_changed,
  input  logic [15:0]                 io_csr_vsatp_asid,
  input  logic                        io_csr_vsatp_changed,
  input  logic [15:0]                 io_csr_hgatp_vmid,
  input  logic                        io_csr_hgatp_changed,
  input  logic                        io_csr_priv_virt_changed,
  // ---- ITLB → Filter：miss 请求（3 个口）----
  output logic [WIDTH-1:0]            io_tlb_req_ready,
  input  logic [WIDTH-1:0]            io_tlb_req_valid,
  input  logic [WIDTH-1:0][VPN_W-1:0] io_tlb_req_bits_vpn,
  input  logic [WIDTH-1:0][1:0]       io_tlb_req_bits_s2xlate,
  input  logic [WIDTH-1:0]            io_tlb_req_bits_getGpa,
  // ---- Filter → ITLB：回应（广播）----
  output logic                        io_tlb_resp_valid,
  output logic [1:0]                  io_tlb_resp_bits_data_s2xlate,
  output logic [34:0]                 io_tlb_resp_bits_data_s1_entry_tag,
  output logic [15:0]                 io_tlb_resp_bits_data_s1_entry_asid,
  output logic [13:0]                 io_tlb_resp_bits_data_s1_entry_vmid,
  output logic                        io_tlb_resp_bits_data_s1_entry_n,
  output logic [1:0]                  io_tlb_resp_bits_data_s1_entry_pbmt,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_d,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_a,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_g,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_u,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_x,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_w,
  output logic                        io_tlb_resp_bits_data_s1_entry_perm_r,
  output logic [1:0]                  io_tlb_resp_bits_data_s1_entry_level,
  output logic                        io_tlb_resp_bits_data_s1_entry_v,
  output logic [40:0]                 io_tlb_resp_bits_data_s1_entry_ppn,
  output logic [2:0]                  io_tlb_resp_bits_data_s1_addr_low,
  output logic [7:0][2:0]             io_tlb_resp_bits_data_s1_ppn_low,
  output logic [7:0]                  io_tlb_resp_bits_data_s1_valididx,
  output logic [7:0]                  io_tlb_resp_bits_data_s1_pteidx,
  output logic                        io_tlb_resp_bits_data_s1_pf,
  output logic                        io_tlb_resp_bits_data_s1_af,
  output logic [37:0]                 io_tlb_resp_bits_data_s2_entry_tag,
  output logic [13:0]                 io_tlb_resp_bits_data_s2_entry_vmid,
  output logic                        io_tlb_resp_bits_data_s2_entry_n,
  output logic [1:0]                  io_tlb_resp_bits_data_s2_entry_pbmt,
  output logic [37:0]                 io_tlb_resp_bits_data_s2_entry_ppn,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_d,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_a,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_g,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_u,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_x,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_w,
  output logic                        io_tlb_resp_bits_data_s2_entry_perm_r,
  output logic [1:0]                  io_tlb_resp_bits_data_s2_entry_level,
  output logic                        io_tlb_resp_bits_data_s2_gpf,
  output logic                        io_tlb_resp_bits_data_s2_gaf,
  output logic                        io_tlb_resp_bits_data_getGpa,
  // ---- Filter → L2TLB：请求（1 个口）----
  input  logic                        io_ptw_req_0_ready,
  output logic                        io_ptw_req_0_valid,
  output logic [VPN_W-1:0]            io_ptw_req_0_bits_vpn,
  output logic [1:0]                  io_ptw_req_0_bits_s2xlate,
  // ---- L2TLB → Filter：回应（ready 恒 1）----
  input  logic                        io_ptw_resp_valid,
  input  logic [1:0]                  io_ptw_resp_bits_s2xlate,
  input  logic [34:0]                 io_ptw_resp_bits_s1_entry_tag,
  input  logic [15:0]                 io_ptw_resp_bits_s1_entry_asid,
  input  logic [13:0]                 io_ptw_resp_bits_s1_entry_vmid,
  input  logic                        io_ptw_resp_bits_s1_entry_n,
  input  logic [1:0]                  io_ptw_resp_bits_s1_entry_pbmt,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_d,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_a,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_g,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_u,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_x,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_w,
  input  logic                        io_ptw_resp_bits_s1_entry_perm_r,
  input  logic [1:0]                  io_ptw_resp_bits_s1_entry_level,
  input  logic                        io_ptw_resp_bits_s1_entry_v,
  input  logic [40:0]                 io_ptw_resp_bits_s1_entry_ppn,
  input  logic [2:0]                  io_ptw_resp_bits_s1_addr_low,
  input  logic [7:0][2:0]             io_ptw_resp_bits_s1_ppn_low,
  input  logic [7:0]                  io_ptw_resp_bits_s1_valididx,
  input  logic [7:0]                  io_ptw_resp_bits_s1_pteidx,
  input  logic                        io_ptw_resp_bits_s1_pf,
  input  logic                        io_ptw_resp_bits_s1_af,
  input  logic [37:0]                 io_ptw_resp_bits_s2_entry_tag,
  input  logic [13:0]                 io_ptw_resp_bits_s2_entry_vmid,
  input  logic                        io_ptw_resp_bits_s2_entry_n,
  input  logic [1:0]                  io_ptw_resp_bits_s2_entry_pbmt,
  input  logic [37:0]                 io_ptw_resp_bits_s2_entry_ppn,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_d,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_a,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_g,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_u,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_x,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_w,
  input  logic                        io_ptw_resp_bits_s2_entry_perm_r,
  input  logic [1:0]                  io_ptw_resp_bits_s2_entry_level,
  input  logic                        io_ptw_resp_bits_s2_gpf,
  input  logic                        io_ptw_resp_bits_s2_gaf
);

  // ===========================================================================
  // §0 冲刷：任一地址空间变化，延迟 2 拍（FenceDelay）后清空队列
  // ===========================================================================
  logic flush;
  DelayN_1 flush_delay (
    .clock  (clock),
    .io_in  (io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
             | io_csr_hgatp_changed | io_csr_priv_virt_changed),
    .io_out (flush)
  );

  // L2TLB 回应：端口 → 结构体
  ptw_resp_t ptw_resp_in;
  assign ptw_resp_in = '{
    s2xlate:         io_ptw_resp_bits_s2xlate,
    s1_entry_tag:    io_ptw_resp_bits_s1_entry_tag,
    s1_entry_asid:   io_ptw_resp_bits_s1_entry_asid,
    s1_entry_vmid:   io_ptw_resp_bits_s1_entry_vmid,
    s1_entry_n:      io_ptw_resp_bits_s1_entry_n,
    s1_entry_pbmt:   io_ptw_resp_bits_s1_entry_pbmt,
    s1_entry_perm_d: io_ptw_resp_bits_s1_entry_perm_d,
    s1_entry_perm_a: io_ptw_resp_bits_s1_entry_perm_a,
    s1_entry_perm_g: io_ptw_resp_bits_s1_entry_perm_g,
    s1_entry_perm_u: io_ptw_resp_bits_s1_entry_perm_u,
    s1_entry_perm_x: io_ptw_resp_bits_s1_entry_perm_x,
    s1_entry_perm_w: io_ptw_resp_bits_s1_entry_perm_w,
    s1_entry_perm_r: io_ptw_resp_bits_s1_entry_perm_r,
    s1_entry_level:  io_ptw_resp_bits_s1_entry_level,
    s1_entry_v:      io_ptw_resp_bits_s1_entry_v,
    s1_entry_ppn:    io_ptw_resp_bits_s1_entry_ppn,
    s1_addr_low:     io_ptw_resp_bits_s1_addr_low,
    s1_ppn_low:      io_ptw_resp_bits_s1_ppn_low,
    s1_valididx:     io_ptw_resp_bits_s1_valididx,
    s1_pteidx:       io_ptw_resp_bits_s1_pteidx,
    s1_pf:           io_ptw_resp_bits_s1_pf,
    s1_af:           io_ptw_resp_bits_s1_af,
    s2_entry_tag:    io_ptw_resp_bits_s2_entry_tag,
    s2_entry_vmid:   io_ptw_resp_bits_s2_entry_vmid,
    s2_entry_n:      io_ptw_resp_bits_s2_entry_n,
    s2_entry_pbmt:   io_ptw_resp_bits_s2_entry_pbmt,
    s2_entry_ppn:    io_ptw_resp_bits_s2_entry_ppn,
    s2_entry_perm_d: io_ptw_resp_bits_s2_entry_perm_d,
    s2_entry_perm_a: io_ptw_resp_bits_s2_entry_perm_a,
    s2_entry_perm_g: io_ptw_resp_bits_s2_entry_perm_g,
    s2_entry_perm_u: io_ptw_resp_bits_s2_entry_perm_u,
    s2_entry_perm_x: io_ptw_resp_bits_s2_entry_perm_x,
    s2_entry_perm_w: io_ptw_resp_bits_s2_entry_perm_w,
    s2_entry_perm_r: io_ptw_resp_bits_s2_entry_perm_r,
    s2_entry_level:  io_ptw_resp_bits_s2_entry_level,
    s2_gpf:          io_ptw_resp_bits_s2_gpf,
    s2_gaf:          io_ptw_resp_bits_s2_gaf
  };

  // ===========================================================================
  // §1 状态
  // ===========================================================================
  // 队列：valid 位异步复位，内容不复位
  logic [SIZE-1:0]            v_q;
  logic [SIZE-1:0][VPN_W-1:0] vpn_q;
  logic [SIZE-1:0][1:0]       s2xlate_q;
  logic [SIZE-1:0]            getGpa_q;
  logic [PTR_W-1:0]           enqPtr_q, issPtr_q, deqPtr_q;
  logic                       mayFullDeq_q, mayFullIss_q;   // 指针相等时区分空/满
  logic [CNT_W-1:0]           counter_q;                    // 占用的槽数（含 v=0 尚未回收的）
  logic [CNT_W-1:0]           inflight_counter_q;           // 已发给 L2TLB、还没回应的请求数

  // 回应侧：L2TLB 回应打一拍
  ptw_resp_t                  ptwResp_q;                    // 不复位
  logic                       ptwResp_valid_q;
  logic                       resp_getGpa_q;                // 不复位

  // 请求侧：ITLB 请求打一拍，以及与之同拍寄存的比较结果
  logic [WIDTH-1:0]            tlb_req_valid_q;
  logic [WIDTH-1:0][VPN_W-1:0] tlb_req_vpn_q;               // 不复位
  logic [WIDTH-1:0][1:0]       tlb_req_s2xlate_q;           // 不复位
  logic [WIDTH-1:0]            tlb_req_getGpa_q;            // 不复位
  logic [WIDTH-1:0]            oldMatch_q;                  // 与队列里某项问的是同一页
  logic                        newMatch10_q;                // 口 1 与口 0 问的是同一页
  logic                        newMatch20_q;                // 口 2 与口 0
  logic                        newMatch21_q;                // 口 2 与口 1

  // flush 当拍把回应也压掉
  wire ptwResp_valid = ~flush & ptwResp_valid_q;

  // ===========================================================================
  // §2 回应侧：L2TLB 回应命中队列里的哪些项
  // ===========================================================================
  logic [SIZE-1:0] resp_old_match;
  for (genvar i = 0; i < SIZE; i++) begin : g_resp_match
    assign resp_old_match[i] = v_q[i]
                             & ptw_resp_hit(vpn_q[i], s2xlate_q[i], ptw_resp_in,
                                            io_csr_satp_asid, io_csr_vsatp_asid, io_csr_hgatp_vmid);
  end

  // 命中的第一项的 getGpa 随回应带回（PriorityMux，全不命中时落到最后一项）
  logic resp_getGpa_sel;
  always_comb begin
    resp_getGpa_sel = getGpa_q[SIZE-1];
    for (int i = SIZE - 2; i >= 0; i--) if (resp_old_match[i]) resp_getGpa_sel = getGpa_q[i];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) ptwResp_valid_q <= 1'b0;
    else       ptwResp_valid_q <= io_ptw_resp_valid & (|resp_old_match);
  end
  always_ff @(posedge clock) begin
    if (io_ptw_resp_valid) ptwResp_q <= ptw_resp_in;
    resp_getGpa_q <= resp_getGpa_sel;
  end

  // ===========================================================================
  // §3 请求侧第 0 拍：到达的请求与「已有答案 / 上一拍请求 / 队列 / 同拍别的口」比较后寄存
  // ===========================================================================
  logic canEnqueue;

  for (genvar w = 0; w < WIDTH; w++) begin : g_req_s0
    wire [VPN_W-1:0] in_vpn     = io_tlb_req_bits_vpn[w];
    wire [1:0]       in_s2xlate = io_tlb_req_bits_s2xlate[w];

    // 上一拍的回应正好覆盖这条请求：已经有答案，不必再问
    wire hit_last_resp = ptwResp_valid
                       & ptw_resp_hit(in_vpn, in_s2xlate, ptwResp_q,
                                      io_csr_satp_asid, io_csr_vsatp_asid, io_csr_hgatp_vmid);
    // 与上一拍寄存的某条请求相同，且那条这拍确实入队：同一页连问两拍
    logic [WIDTH-1:0] same_as_last_req;
    for (genvar b = 0; b < WIDTH; b++) begin : g_last
      assign same_as_last_req[b] = tlb_req_valid_q[b] & (tlb_req_vpn_q[b] == in_vpn)
                                 & canEnqueue & (tlb_req_s2xlate_q[b] == in_s2xlate);
    end
    // 与队列里某个有效项相同
    logic [SIZE-1:0] same_as_entry;
    for (genvar i = 0; i < SIZE; i++) begin : g_old
      assign same_as_entry[i] = v_q[i] & (vpn_q[i] == in_vpn) & (s2xlate_q[i] == in_s2xlate);
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        tlb_req_valid_q[w] <= 1'b0;
        oldMatch_q[w]      <= 1'b0;
      end
      else begin
        tlb_req_valid_q[w] <= io_tlb_req_valid[w] & ~hit_last_resp & ~(|same_as_last_req);
        oldMatch_q[w]      <= |same_as_entry;
      end
    end
    always_ff @(posedge clock) begin
      if (io_tlb_req_valid[w]) begin
        tlb_req_vpn_q[w]     <= in_vpn;
        tlb_req_s2xlate_q[w] <= in_s2xlate;
        tlb_req_getGpa_q[w]  <= io_tlb_req_bits_getGpa[w];
      end
    end
  end

  // 同拍端口之间：只需要「与更靠前的口相同」这 3 个比较（靠后的那个被合并掉）
  function automatic logic same_req(input logic [VPN_W-1:0] vpn_a, input logic [1:0] s2x_a,
                                    input logic [VPN_W-1:0] vpn_b, input logic [1:0] s2x_b);
    return (vpn_a == vpn_b) & (s2x_a == s2x_b);
  endfunction
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      newMatch10_q <= 1'b0;
      newMatch20_q <= 1'b0;
      newMatch21_q <= 1'b0;
    end
    else begin
      newMatch10_q <= same_req(io_tlb_req_bits_vpn[1], io_tlb_req_bits_s2xlate[1],
                               io_tlb_req_bits_vpn[0], io_tlb_req_bits_s2xlate[0]);
      newMatch20_q <= same_req(io_tlb_req_bits_vpn[2], io_tlb_req_bits_s2xlate[2],
                               io_tlb_req_bits_vpn[0], io_tlb_req_bits_s2xlate[0]);
      newMatch21_q <= same_req(io_tlb_req_bits_vpn[2], io_tlb_req_bits_s2xlate[2],
                               io_tlb_req_bits_vpn[1], io_tlb_req_bits_s2xlate[1]);
    end
  end

  // ===========================================================================
  // §4 请求侧第 1 拍：去重（canMerge）后入队
  // ===========================================================================
  // 被更靠前的、这拍同样有效的口合并
  logic [WIDTH-1:0] merged_by_earlier_port;
  assign merged_by_earlier_port[0] = 1'b0;
  assign merged_by_earlier_port[1] = newMatch10_q & tlb_req_valid_q[0];
  assign merged_by_earlier_port[2] = (newMatch20_q & tlb_req_valid_q[0]) | (newMatch21_q & tlb_req_valid_q[1]);

  logic [WIDTH-1:0] reqs_valid;         // 真要入队的
  logic [WIDTH-1:0] tlb_req_flushed;    // 入队当拍被正在到来的回应覆盖：占槽但 v 写 0
  for (genvar w = 0; w < WIDTH; w++) begin : g_req_s1
    wire hit_last_resp = ptwResp_valid
                       & ptw_resp_hit(tlb_req_vpn_q[w], tlb_req_s2xlate_q[w], ptwResp_q,
                                      io_csr_satp_asid, io_csr_vsatp_asid, io_csr_hgatp_vmid);
    wire can_merge     = hit_last_resp | oldMatch_q[w] | merged_by_earlier_port[w];
    assign reqs_valid[w]      = ~can_merge & tlb_req_valid_q[w];
    assign tlb_req_flushed[w] = io_ptw_resp_valid
                              & ptw_resp_hit(tlb_req_vpn_q[w], tlb_req_s2xlate_q[w], ptw_resp_in,
                                             io_csr_satp_asid, io_csr_vsatp_asid, io_csr_hgatp_vmid);
  end

  // 入队槽位：enqPtr 起连续分配，口 w 的偏移 = 它前面有几个口真入队
  wire [1:0] enqNum      = 2'(reqs_valid[0]) + 2'(reqs_valid[1]) + 2'(reqs_valid[2]);
  wire [1:0] enqNum_fake = 2'(io_tlb_req_valid[0]) + 2'(io_tlb_req_valid[1]) + 2'(io_tlb_req_valid[2]);
  logic [WIDTH-1:0][PTR_W-1:0] enq_slot;
  assign enq_slot[0] = enqPtr_q;
  assign enq_slot[1] = enqPtr_q + PTR_W'(reqs_valid[0]);
  assign enq_slot[2] = enqPtr_q + PTR_W'(2'(reqs_valid[0]) + 2'(reqs_valid[1]));

  assign canEnqueue           = ({1'b0, counter_q} + 5'(enqNum))      <= 5'(SIZE);
  wire   canEnqueue_fake      = ({1'b0, counter_q} + 5'(enqNum_fake)) <= 5'(SIZE);
  assign io_tlb_req_ready     = {WIDTH{canEnqueue_fake}};

  // ===========================================================================
  // §5 发给 L2TLB
  // ===========================================================================
  wire isEmptyDeq = (enqPtr_q == deqPtr_q) & ~mayFullDeq_q;
  wire isEmptyIss = (enqPtr_q == issPtr_q) & ~mayFullIss_q;
  wire inflight_full = inflight_counter_q == CNT_W'(SIZE);

  wire issue_valid     = v_q[issPtr_q] & ~isEmptyIss & ~inflight_full;
  // 要发的这一项已被上一拍的回应覆盖：不发，直接作废
  wire issue_filtered  = ptwResp_valid
                       & ptw_resp_hit(vpn_q[issPtr_q], s2xlate_q[issPtr_q], ptwResp_q,
                                      io_csr_satp_asid, io_csr_vsatp_asid, io_csr_hgatp_vmid);
  wire issue_fire_fake = issue_valid & io_ptw_req_0_ready;

  assign io_ptw_req_0_valid        = issue_valid & ~issue_filtered;
  assign io_ptw_req_0_bits_vpn     = vpn_q[issPtr_q];
  assign io_ptw_req_0_bits_s2xlate = s2xlate_q[issPtr_q];
  wire   ptw_req_fire              = io_ptw_req_0_ready & io_ptw_req_0_valid;

  // ===========================================================================
  // §6 队列更新
  // ===========================================================================
  wire do_enq = canEnqueue & (|reqs_valid);
  wire do_deq = ~v_q[deqPtr_q] & ~isEmptyDeq;                       // 队头已作废：回收
  wire do_iss = issue_fire_fake | (~v_q[issPtr_q] & ~isEmptyIss);   // 发出去了，或该项已作废：跳过

  // valid 位：入队置位（假入队写 0）→ 发射时被过滤则清 → 回应命中则清 → flush 全清
  logic [SIZE-1:0] v_d;
  always_comb begin
    v_d = v_q;
    for (int w = 0; w < WIDTH; w++)
      if (reqs_valid[w] & canEnqueue) v_d[enq_slot[w]] = ~tlb_req_flushed[w];
    if (issue_fire_fake & issue_filtered) v_d[issPtr_q] = 1'b0;
    if (io_ptw_resp_valid)                v_d = v_d & ~resp_old_match;
    if (flush)                            v_d = '0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      v_q                <= '0;
      enqPtr_q           <= '0;
      issPtr_q           <= '0;
      deqPtr_q           <= '0;
      mayFullDeq_q       <= 1'b0;
      mayFullIss_q       <= 1'b0;
      counter_q          <= '0;
      inflight_counter_q <= '0;
    end
    else begin
      v_q <= v_d;
      if (flush) begin
        enqPtr_q           <= '0;
        issPtr_q           <= '0;
        deqPtr_q           <= '0;
        mayFullDeq_q       <= 1'b0;
        mayFullIss_q       <= 1'b0;
        counter_q          <= '0;
        inflight_counter_q <= '0;
      end
      else begin
        if (do_enq) enqPtr_q <= enqPtr_q + PTR_W'(enqNum);
        if (do_iss) issPtr_q <= issPtr_q + 1'b1;
        if (do_deq) deqPtr_q <= deqPtr_q + 1'b1;
        if (do_enq != do_deq) mayFullDeq_q <= do_enq;
        if (do_enq != do_iss) mayFullIss_q <= do_enq;
        counter_q <= counter_q - CNT_W'(do_deq) + CNT_W'(do_enq ? enqNum : 2'd0);
        if (ptw_req_fire != io_ptw_resp_valid)
          inflight_counter_q <= ptw_req_fire ? inflight_counter_q + 1'b1 : inflight_counter_q - 1'b1;
      end
    end
  end

  // 队列内容：靠后的口优先（三个口的槽位本来就互不相同）
  always_ff @(posedge clock) begin
    for (int w = 0; w < WIDTH; w++) begin
      if (reqs_valid[w] & canEnqueue) begin
        vpn_q[enq_slot[w]]     <= tlb_req_vpn_q[w];
        s2xlate_q[enq_slot[w]] <= tlb_req_s2xlate_q[w];
        getGpa_q[enq_slot[w]]  <= tlb_req_getGpa_q[w];
      end
    end
  end

  // ===========================================================================
  // §7 回应 ITLB：寄存的 L2TLB 回应原样广播
  // ===========================================================================
  assign io_tlb_resp_valid                     = ptwResp_valid;
  assign io_tlb_resp_bits_data_s2xlate         = ptwResp_q.s2xlate;
  assign io_tlb_resp_bits_data_s1_entry_tag    = ptwResp_q.s1_entry_tag;
  assign io_tlb_resp_bits_data_s1_entry_asid   = ptwResp_q.s1_entry_asid;
  assign io_tlb_resp_bits_data_s1_entry_vmid   = ptwResp_q.s1_entry_vmid;
  assign io_tlb_resp_bits_data_s1_entry_n      = ptwResp_q.s1_entry_n;
  assign io_tlb_resp_bits_data_s1_entry_pbmt   = ptwResp_q.s1_entry_pbmt;
  assign io_tlb_resp_bits_data_s1_entry_perm_d = ptwResp_q.s1_entry_perm_d;
  assign io_tlb_resp_bits_data_s1_entry_perm_a = ptwResp_q.s1_entry_perm_a;
  assign io_tlb_resp_bits_data_s1_entry_perm_g = ptwResp_q.s1_entry_perm_g;
  assign io_tlb_resp_bits_data_s1_entry_perm_u = ptwResp_q.s1_entry_perm_u;
  assign io_tlb_resp_bits_data_s1_entry_perm_x = ptwResp_q.s1_entry_perm_x;
  assign io_tlb_resp_bits_data_s1_entry_perm_w = ptwResp_q.s1_entry_perm_w;
  assign io_tlb_resp_bits_data_s1_entry_perm_r = ptwResp_q.s1_entry_perm_r;
  assign io_tlb_resp_bits_data_s1_entry_level  = ptwResp_q.s1_entry_level;
  assign io_tlb_resp_bits_data_s1_entry_v      = ptwResp_q.s1_entry_v;
  assign io_tlb_resp_bits_data_s1_entry_ppn    = ptwResp_q.s1_entry_ppn;
  assign io_tlb_resp_bits_data_s1_addr_low     = ptwResp_q.s1_addr_low;
  assign io_tlb_resp_bits_data_s1_ppn_low      = ptwResp_q.s1_ppn_low;
  assign io_tlb_resp_bits_data_s1_valididx     = ptwResp_q.s1_valididx;
  assign io_tlb_resp_bits_data_s1_pteidx       = ptwResp_q.s1_pteidx;
  assign io_tlb_resp_bits_data_s1_pf           = ptwResp_q.s1_pf;
  assign io_tlb_resp_bits_data_s1_af           = ptwResp_q.s1_af;
  assign io_tlb_resp_bits_data_s2_entry_tag    = ptwResp_q.s2_entry_tag;
  assign io_tlb_resp_bits_data_s2_entry_vmid   = ptwResp_q.s2_entry_vmid;
  assign io_tlb_resp_bits_data_s2_entry_n      = ptwResp_q.s2_entry_n;
  assign io_tlb_resp_bits_data_s2_entry_pbmt   = ptwResp_q.s2_entry_pbmt;
  assign io_tlb_resp_bits_data_s2_entry_ppn    = ptwResp_q.s2_entry_ppn;
  assign io_tlb_resp_bits_data_s2_entry_perm_d = ptwResp_q.s2_entry_perm_d;
  assign io_tlb_resp_bits_data_s2_entry_perm_a = ptwResp_q.s2_entry_perm_a;
  assign io_tlb_resp_bits_data_s2_entry_perm_g = ptwResp_q.s2_entry_perm_g;
  assign io_tlb_resp_bits_data_s2_entry_perm_u = ptwResp_q.s2_entry_perm_u;
  assign io_tlb_resp_bits_data_s2_entry_perm_x = ptwResp_q.s2_entry_perm_x;
  assign io_tlb_resp_bits_data_s2_entry_perm_w = ptwResp_q.s2_entry_perm_w;
  assign io_tlb_resp_bits_data_s2_entry_perm_r = ptwResp_q.s2_entry_perm_r;
  assign io_tlb_resp_bits_data_s2_entry_level  = ptwResp_q.s2_entry_level;
  assign io_tlb_resp_bits_data_s2_gpf          = ptwResp_q.s2_gpf;
  assign io_tlb_resp_bits_data_s2_gaf          = ptwResp_q.s2_gaf;
  assign io_tlb_resp_bits_data_getGpa          = resp_getGpa_q;

endmodule

// BEGIN GENERATED(wrapper)
// 自动生成：scripts/gen_newifu_lane.py —— 勿手改（端口表照抄 G1 golden，体里只做打包/拆包）
module PTWFilter (
  input         clock,
  input         reset,
  input         io_sfence_valid,
  input  [15:0] io_csr_satp_asid,
  input         io_csr_satp_changed,
  input  [15:0] io_csr_vsatp_asid,
  input         io_csr_vsatp_changed,
  input  [15:0] io_csr_hgatp_vmid,
  input         io_csr_hgatp_changed,
  input         io_csr_priv_virt_changed,
  output        io_tlb_req_0_ready,
  input         io_tlb_req_0_valid,
  input  [37:0] io_tlb_req_0_bits_vpn,
  input  [1:0]  io_tlb_req_0_bits_s2xlate,
  input         io_tlb_req_0_bits_getGpa,
  output        io_tlb_req_1_ready,
  input         io_tlb_req_1_valid,
  input  [37:0] io_tlb_req_1_bits_vpn,
  input  [1:0]  io_tlb_req_1_bits_s2xlate,
  input         io_tlb_req_1_bits_getGpa,
  output        io_tlb_req_2_ready,
  input         io_tlb_req_2_valid,
  input  [37:0] io_tlb_req_2_bits_vpn,
  input  [1:0]  io_tlb_req_2_bits_s2xlate,
  input         io_tlb_req_2_bits_getGpa,
  output        io_tlb_resp_valid,
  output [1:0]  io_tlb_resp_bits_data_s2xlate,
  output [34:0] io_tlb_resp_bits_data_s1_entry_tag,
  output [15:0] io_tlb_resp_bits_data_s1_entry_asid,
  output [13:0] io_tlb_resp_bits_data_s1_entry_vmid,
  output        io_tlb_resp_bits_data_s1_entry_n,
  output [1:0]  io_tlb_resp_bits_data_s1_entry_pbmt,
  output        io_tlb_resp_bits_data_s1_entry_perm_d,
  output        io_tlb_resp_bits_data_s1_entry_perm_a,
  output        io_tlb_resp_bits_data_s1_entry_perm_g,
  output        io_tlb_resp_bits_data_s1_entry_perm_u,
  output        io_tlb_resp_bits_data_s1_entry_perm_x,
  output        io_tlb_resp_bits_data_s1_entry_perm_w,
  output        io_tlb_resp_bits_data_s1_entry_perm_r,
  output [1:0]  io_tlb_resp_bits_data_s1_entry_level,
  output        io_tlb_resp_bits_data_s1_entry_v,
  output [40:0] io_tlb_resp_bits_data_s1_entry_ppn,
  output [2:0]  io_tlb_resp_bits_data_s1_addr_low,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_0,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_1,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_2,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_3,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_4,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_5,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_6,
  output [2:0]  io_tlb_resp_bits_data_s1_ppn_low_7,
  output        io_tlb_resp_bits_data_s1_valididx_0,
  output        io_tlb_resp_bits_data_s1_valididx_1,
  output        io_tlb_resp_bits_data_s1_valididx_2,
  output        io_tlb_resp_bits_data_s1_valididx_3,
  output        io_tlb_resp_bits_data_s1_valididx_4,
  output        io_tlb_resp_bits_data_s1_valididx_5,
  output        io_tlb_resp_bits_data_s1_valididx_6,
  output        io_tlb_resp_bits_data_s1_valididx_7,
  output        io_tlb_resp_bits_data_s1_pteidx_0,
  output        io_tlb_resp_bits_data_s1_pteidx_1,
  output        io_tlb_resp_bits_data_s1_pteidx_2,
  output        io_tlb_resp_bits_data_s1_pteidx_3,
  output        io_tlb_resp_bits_data_s1_pteidx_4,
  output        io_tlb_resp_bits_data_s1_pteidx_5,
  output        io_tlb_resp_bits_data_s1_pteidx_6,
  output        io_tlb_resp_bits_data_s1_pteidx_7,
  output        io_tlb_resp_bits_data_s1_pf,
  output        io_tlb_resp_bits_data_s1_af,
  output [37:0] io_tlb_resp_bits_data_s2_entry_tag,
  output [13:0] io_tlb_resp_bits_data_s2_entry_vmid,
  output        io_tlb_resp_bits_data_s2_entry_n,
  output [1:0]  io_tlb_resp_bits_data_s2_entry_pbmt,
  output [37:0] io_tlb_resp_bits_data_s2_entry_ppn,
  output        io_tlb_resp_bits_data_s2_entry_perm_d,
  output        io_tlb_resp_bits_data_s2_entry_perm_a,
  output        io_tlb_resp_bits_data_s2_entry_perm_g,
  output        io_tlb_resp_bits_data_s2_entry_perm_u,
  output        io_tlb_resp_bits_data_s2_entry_perm_x,
  output        io_tlb_resp_bits_data_s2_entry_perm_w,
  output        io_tlb_resp_bits_data_s2_entry_perm_r,
  output [1:0]  io_tlb_resp_bits_data_s2_entry_level,
  output        io_tlb_resp_bits_data_s2_gpf,
  output        io_tlb_resp_bits_data_s2_gaf,
  output        io_tlb_resp_bits_data_getGpa,
  input         io_ptw_req_0_ready,
  output        io_ptw_req_0_valid,
  output [37:0] io_ptw_req_0_bits_vpn,
  output [1:0]  io_ptw_req_0_bits_s2xlate,
  input         io_ptw_resp_valid,
  input  [1:0]  io_ptw_resp_bits_s2xlate,
  input  [34:0] io_ptw_resp_bits_s1_entry_tag,
  input  [15:0] io_ptw_resp_bits_s1_entry_asid,
  input  [13:0] io_ptw_resp_bits_s1_entry_vmid,
  input         io_ptw_resp_bits_s1_entry_n,
  input  [1:0]  io_ptw_resp_bits_s1_entry_pbmt,
  input         io_ptw_resp_bits_s1_entry_perm_d,
  input         io_ptw_resp_bits_s1_entry_perm_a,
  input         io_ptw_resp_bits_s1_entry_perm_g,
  input         io_ptw_resp_bits_s1_entry_perm_u,
  input         io_ptw_resp_bits_s1_entry_perm_x,
  input         io_ptw_resp_bits_s1_entry_perm_w,
  input         io_ptw_resp_bits_s1_entry_perm_r,
  input  [1:0]  io_ptw_resp_bits_s1_entry_level,
  input         io_ptw_resp_bits_s1_entry_v,
  input  [40:0] io_ptw_resp_bits_s1_entry_ppn,
  input  [2:0]  io_ptw_resp_bits_s1_addr_low,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_0,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_1,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_2,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_3,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_4,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_5,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_6,
  input  [2:0]  io_ptw_resp_bits_s1_ppn_low_7,
  input         io_ptw_resp_bits_s1_valididx_0,
  input         io_ptw_resp_bits_s1_valididx_1,
  input         io_ptw_resp_bits_s1_valididx_2,
  input         io_ptw_resp_bits_s1_valididx_3,
  input         io_ptw_resp_bits_s1_valididx_4,
  input         io_ptw_resp_bits_s1_valididx_5,
  input         io_ptw_resp_bits_s1_valididx_6,
  input         io_ptw_resp_bits_s1_valididx_7,
  input         io_ptw_resp_bits_s1_pteidx_0,
  input         io_ptw_resp_bits_s1_pteidx_1,
  input         io_ptw_resp_bits_s1_pteidx_2,
  input         io_ptw_resp_bits_s1_pteidx_3,
  input         io_ptw_resp_bits_s1_pteidx_4,
  input         io_ptw_resp_bits_s1_pteidx_5,
  input         io_ptw_resp_bits_s1_pteidx_6,
  input         io_ptw_resp_bits_s1_pteidx_7,
  input         io_ptw_resp_bits_s1_pf,
  input         io_ptw_resp_bits_s1_af,
  input  [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input         io_ptw_resp_bits_s2_entry_n,
  input  [1:0]  io_ptw_resp_bits_s2_entry_pbmt,
  input  [37:0] io_ptw_resp_bits_s2_entry_ppn,
  input         io_ptw_resp_bits_s2_entry_perm_d,
  input         io_ptw_resp_bits_s2_entry_perm_a,
  input         io_ptw_resp_bits_s2_entry_perm_g,
  input         io_ptw_resp_bits_s2_entry_perm_u,
  input         io_ptw_resp_bits_s2_entry_perm_x,
  input         io_ptw_resp_bits_s2_entry_perm_w,
  input         io_ptw_resp_bits_s2_entry_perm_r,
  input  [1:0]  io_ptw_resp_bits_s2_entry_level,
  input         io_ptw_resp_bits_s2_gpf,
  input         io_ptw_resp_bits_s2_gaf
);
  wire [2:0] io_tlb_req_ready;
  wire [2:0] io_tlb_req_valid = {
    io_tlb_req_2_valid, io_tlb_req_1_valid, io_tlb_req_0_valid};
  wire [2:0][37:0] io_tlb_req_bits_vpn = {
    io_tlb_req_2_bits_vpn, io_tlb_req_1_bits_vpn, io_tlb_req_0_bits_vpn};
  wire [2:0][1:0] io_tlb_req_bits_s2xlate = {
    io_tlb_req_2_bits_s2xlate, io_tlb_req_1_bits_s2xlate, io_tlb_req_0_bits_s2xlate};
  wire [2:0] io_tlb_req_bits_getGpa = {
    io_tlb_req_2_bits_getGpa, io_tlb_req_1_bits_getGpa, io_tlb_req_0_bits_getGpa};
  wire [7:0][2:0] io_tlb_resp_bits_data_s1_ppn_low;
  wire [7:0] io_tlb_resp_bits_data_s1_valididx;
  wire [7:0] io_tlb_resp_bits_data_s1_pteidx;
  wire [7:0][2:0] io_ptw_resp_bits_s1_ppn_low = {
    io_ptw_resp_bits_s1_ppn_low_7, io_ptw_resp_bits_s1_ppn_low_6, io_ptw_resp_bits_s1_ppn_low_5,
    io_ptw_resp_bits_s1_ppn_low_4, io_ptw_resp_bits_s1_ppn_low_3, io_ptw_resp_bits_s1_ppn_low_2,
    io_ptw_resp_bits_s1_ppn_low_1, io_ptw_resp_bits_s1_ppn_low_0};
  wire [7:0] io_ptw_resp_bits_s1_valididx = {
    io_ptw_resp_bits_s1_valididx_7, io_ptw_resp_bits_s1_valididx_6, io_ptw_resp_bits_s1_valididx_5,
    io_ptw_resp_bits_s1_valididx_4, io_ptw_resp_bits_s1_valididx_3, io_ptw_resp_bits_s1_valididx_2,
    io_ptw_resp_bits_s1_valididx_1, io_ptw_resp_bits_s1_valididx_0};
  wire [7:0] io_ptw_resp_bits_s1_pteidx = {
    io_ptw_resp_bits_s1_pteidx_7, io_ptw_resp_bits_s1_pteidx_6, io_ptw_resp_bits_s1_pteidx_5,
    io_ptw_resp_bits_s1_pteidx_4, io_ptw_resp_bits_s1_pteidx_3, io_ptw_resp_bits_s1_pteidx_2,
    io_ptw_resp_bits_s1_pteidx_1, io_ptw_resp_bits_s1_pteidx_0};

  xs_PTWFilter_core u_core (
    .clock                                 (clock),
    .reset                                 (reset),
    .io_sfence_valid                       (io_sfence_valid),
    .io_csr_satp_asid                      (io_csr_satp_asid),
    .io_csr_satp_changed                   (io_csr_satp_changed),
    .io_csr_vsatp_asid                     (io_csr_vsatp_asid),
    .io_csr_vsatp_changed                  (io_csr_vsatp_changed),
    .io_csr_hgatp_vmid                     (io_csr_hgatp_vmid),
    .io_csr_hgatp_changed                  (io_csr_hgatp_changed),
    .io_csr_priv_virt_changed              (io_csr_priv_virt_changed),
    .io_tlb_req_ready                      (io_tlb_req_ready),
    .io_tlb_req_valid                      (io_tlb_req_valid),
    .io_tlb_req_bits_vpn                   (io_tlb_req_bits_vpn),
    .io_tlb_req_bits_s2xlate               (io_tlb_req_bits_s2xlate),
    .io_tlb_req_bits_getGpa                (io_tlb_req_bits_getGpa),
    .io_tlb_resp_valid                     (io_tlb_resp_valid),
    .io_tlb_resp_bits_data_s2xlate         (io_tlb_resp_bits_data_s2xlate),
    .io_tlb_resp_bits_data_s1_entry_tag    (io_tlb_resp_bits_data_s1_entry_tag),
    .io_tlb_resp_bits_data_s1_entry_asid   (io_tlb_resp_bits_data_s1_entry_asid),
    .io_tlb_resp_bits_data_s1_entry_vmid   (io_tlb_resp_bits_data_s1_entry_vmid),
    .io_tlb_resp_bits_data_s1_entry_n      (io_tlb_resp_bits_data_s1_entry_n),
    .io_tlb_resp_bits_data_s1_entry_pbmt   (io_tlb_resp_bits_data_s1_entry_pbmt),
    .io_tlb_resp_bits_data_s1_entry_perm_d (io_tlb_resp_bits_data_s1_entry_perm_d),
    .io_tlb_resp_bits_data_s1_entry_perm_a (io_tlb_resp_bits_data_s1_entry_perm_a),
    .io_tlb_resp_bits_data_s1_entry_perm_g (io_tlb_resp_bits_data_s1_entry_perm_g),
    .io_tlb_resp_bits_data_s1_entry_perm_u (io_tlb_resp_bits_data_s1_entry_perm_u),
    .io_tlb_resp_bits_data_s1_entry_perm_x (io_tlb_resp_bits_data_s1_entry_perm_x),
    .io_tlb_resp_bits_data_s1_entry_perm_w (io_tlb_resp_bits_data_s1_entry_perm_w),
    .io_tlb_resp_bits_data_s1_entry_perm_r (io_tlb_resp_bits_data_s1_entry_perm_r),
    .io_tlb_resp_bits_data_s1_entry_level  (io_tlb_resp_bits_data_s1_entry_level),
    .io_tlb_resp_bits_data_s1_entry_v      (io_tlb_resp_bits_data_s1_entry_v),
    .io_tlb_resp_bits_data_s1_entry_ppn    (io_tlb_resp_bits_data_s1_entry_ppn),
    .io_tlb_resp_bits_data_s1_addr_low     (io_tlb_resp_bits_data_s1_addr_low),
    .io_tlb_resp_bits_data_s1_ppn_low      (io_tlb_resp_bits_data_s1_ppn_low),
    .io_tlb_resp_bits_data_s1_valididx     (io_tlb_resp_bits_data_s1_valididx),
    .io_tlb_resp_bits_data_s1_pteidx       (io_tlb_resp_bits_data_s1_pteidx),
    .io_tlb_resp_bits_data_s1_pf           (io_tlb_resp_bits_data_s1_pf),
    .io_tlb_resp_bits_data_s1_af           (io_tlb_resp_bits_data_s1_af),
    .io_tlb_resp_bits_data_s2_entry_tag    (io_tlb_resp_bits_data_s2_entry_tag),
    .io_tlb_resp_bits_data_s2_entry_vmid   (io_tlb_resp_bits_data_s2_entry_vmid),
    .io_tlb_resp_bits_data_s2_entry_n      (io_tlb_resp_bits_data_s2_entry_n),
    .io_tlb_resp_bits_data_s2_entry_pbmt   (io_tlb_resp_bits_data_s2_entry_pbmt),
    .io_tlb_resp_bits_data_s2_entry_ppn    (io_tlb_resp_bits_data_s2_entry_ppn),
    .io_tlb_resp_bits_data_s2_entry_perm_d (io_tlb_resp_bits_data_s2_entry_perm_d),
    .io_tlb_resp_bits_data_s2_entry_perm_a (io_tlb_resp_bits_data_s2_entry_perm_a),
    .io_tlb_resp_bits_data_s2_entry_perm_g (io_tlb_resp_bits_data_s2_entry_perm_g),
    .io_tlb_resp_bits_data_s2_entry_perm_u (io_tlb_resp_bits_data_s2_entry_perm_u),
    .io_tlb_resp_bits_data_s2_entry_perm_x (io_tlb_resp_bits_data_s2_entry_perm_x),
    .io_tlb_resp_bits_data_s2_entry_perm_w (io_tlb_resp_bits_data_s2_entry_perm_w),
    .io_tlb_resp_bits_data_s2_entry_perm_r (io_tlb_resp_bits_data_s2_entry_perm_r),
    .io_tlb_resp_bits_data_s2_entry_level  (io_tlb_resp_bits_data_s2_entry_level),
    .io_tlb_resp_bits_data_s2_gpf          (io_tlb_resp_bits_data_s2_gpf),
    .io_tlb_resp_bits_data_s2_gaf          (io_tlb_resp_bits_data_s2_gaf),
    .io_tlb_resp_bits_data_getGpa          (io_tlb_resp_bits_data_getGpa),
    .io_ptw_req_0_ready                    (io_ptw_req_0_ready),
    .io_ptw_req_0_valid                    (io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn                 (io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate             (io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_valid                     (io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate              (io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag         (io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid        (io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid        (io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n           (io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt        (io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d      (io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a      (io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g      (io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u      (io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x      (io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w      (io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r      (io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level       (io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v           (io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn         (io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low          (io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low           (io_ptw_resp_bits_s1_ppn_low),
    .io_ptw_resp_bits_s1_valididx          (io_ptw_resp_bits_s1_valididx),
    .io_ptw_resp_bits_s1_pteidx            (io_ptw_resp_bits_s1_pteidx),
    .io_ptw_resp_bits_s1_pf                (io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af                (io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag         (io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid        (io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n           (io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt        (io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn         (io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d      (io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a      (io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g      (io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u      (io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x      (io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w      (io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r      (io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level       (io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf               (io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf               (io_ptw_resp_bits_s2_gaf)
  );

  assign io_tlb_req_0_ready = io_tlb_req_ready[0];
  assign io_tlb_req_1_ready = io_tlb_req_ready[1];
  assign io_tlb_req_2_ready = io_tlb_req_ready[2];
  assign io_tlb_resp_bits_data_s1_ppn_low_0 = io_tlb_resp_bits_data_s1_ppn_low[0];
  assign io_tlb_resp_bits_data_s1_ppn_low_1 = io_tlb_resp_bits_data_s1_ppn_low[1];
  assign io_tlb_resp_bits_data_s1_ppn_low_2 = io_tlb_resp_bits_data_s1_ppn_low[2];
  assign io_tlb_resp_bits_data_s1_ppn_low_3 = io_tlb_resp_bits_data_s1_ppn_low[3];
  assign io_tlb_resp_bits_data_s1_ppn_low_4 = io_tlb_resp_bits_data_s1_ppn_low[4];
  assign io_tlb_resp_bits_data_s1_ppn_low_5 = io_tlb_resp_bits_data_s1_ppn_low[5];
  assign io_tlb_resp_bits_data_s1_ppn_low_6 = io_tlb_resp_bits_data_s1_ppn_low[6];
  assign io_tlb_resp_bits_data_s1_ppn_low_7 = io_tlb_resp_bits_data_s1_ppn_low[7];
  assign io_tlb_resp_bits_data_s1_valididx_0 = io_tlb_resp_bits_data_s1_valididx[0];
  assign io_tlb_resp_bits_data_s1_valididx_1 = io_tlb_resp_bits_data_s1_valididx[1];
  assign io_tlb_resp_bits_data_s1_valididx_2 = io_tlb_resp_bits_data_s1_valididx[2];
  assign io_tlb_resp_bits_data_s1_valididx_3 = io_tlb_resp_bits_data_s1_valididx[3];
  assign io_tlb_resp_bits_data_s1_valididx_4 = io_tlb_resp_bits_data_s1_valididx[4];
  assign io_tlb_resp_bits_data_s1_valididx_5 = io_tlb_resp_bits_data_s1_valididx[5];
  assign io_tlb_resp_bits_data_s1_valididx_6 = io_tlb_resp_bits_data_s1_valididx[6];
  assign io_tlb_resp_bits_data_s1_valididx_7 = io_tlb_resp_bits_data_s1_valididx[7];
  assign io_tlb_resp_bits_data_s1_pteidx_0 = io_tlb_resp_bits_data_s1_pteidx[0];
  assign io_tlb_resp_bits_data_s1_pteidx_1 = io_tlb_resp_bits_data_s1_pteidx[1];
  assign io_tlb_resp_bits_data_s1_pteidx_2 = io_tlb_resp_bits_data_s1_pteidx[2];
  assign io_tlb_resp_bits_data_s1_pteidx_3 = io_tlb_resp_bits_data_s1_pteidx[3];
  assign io_tlb_resp_bits_data_s1_pteidx_4 = io_tlb_resp_bits_data_s1_pteidx[4];
  assign io_tlb_resp_bits_data_s1_pteidx_5 = io_tlb_resp_bits_data_s1_pteidx[5];
  assign io_tlb_resp_bits_data_s1_pteidx_6 = io_tlb_resp_bits_data_s1_pteidx[6];
  assign io_tlb_resp_bits_data_s1_pteidx_7 = io_tlb_resp_bits_data_s1_pteidx[7];
endmodule
// END GENERATED(wrapper)
