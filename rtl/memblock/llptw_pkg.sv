// =============================================================================
// xs_llptw_pkg —— LLPTW（Last Level Page Table Walker）可读重写的类型与纯函数
//
// 设计来源：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/PageTableWalker.scala
//     class LLPTW / class LLPTWEntry / class LLPTWIO
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala  PteBundle/HptwResp
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUConst.scala   MakeAddr/getVpnn/dup...
//
// LLPTW 负责 L2TLB 的“最后一级（4KB）页表遍历”。当上层 PTW 已经走到最后一级、
// 或 page cache 在 L0 命中需要复检时，请求会进入 LLPTW。它维护一个 llptwsize=6
// 的条目池，多请求并发遍历，共享一个访存口（mem.req/resp），命中后填充上游。
// H 扩展下还需要把 GPA 经 HPTW 做 G-stage 翻译（首次 + 最后一次）。
//
// 本配置（与 golden LLPTW.sv 对齐）：
//   * EnableSv48 = true  → Level=3，GPAddrBits=50，gvpnLen=38，vpnLen=38。
//   * HasHExtension = true → 支持 allStage / onlyStage1 / onlyStage2。
//   * HasBitmapCheck = false → golden 不含 bitmap 通路，本重写同样省略。
// =============================================================================
package xs_llptw_pkg;

  // ---- 几何参数（全部取自 MMUConst.scala，注明物理含义）----------------------
  localparam int XLEN          = 64;
  localparam int LLPTW_SIZE    = 6;            // l2tlbParams.llptwsize：条目池深度
  localparam int ID_W          = 3;            // log2Up(MemReqWidth=8)=bMemID，亦覆盖 llptwsize
  localparam int VPN_W         = 38;           // vpnLen（H 扩展下 = GPAddrBits-offLen）
  localparam int PTE_PPN_W     = 44;           // ptePPNLen：PTE 中 PPN 全宽
  localparam int PPN_W         = 36;           // ppnLen = PAddrBits(48)-offLen(12)
  localparam int GVPN_W        = 38;           // gvpnLen = GPAddrBits(50)-offLen(12)
  localparam int OFF_W         = 12;           // offLen
  localparam int VPNN_W        = 9;            // vpnnLen：每级页表 VPN 段宽
  localparam int VMID_W        = 14;
  localparam int SOURCE_W      = 2;            // bSourceWidth
  localparam int NAPOT_BITS    = 4;            // pteNapotBits
  localparam int PADDR_W       = 48;           // PAddrBits
  localparam int GPADDR_W      = 50;           // GPAddrBits（Sv48x4）
  localparam int BLOCK_BITS    = 512;          // blockBits：一次访存返回的 cacheline
  localparam int PTE_PER_BLK   = BLOCK_BITS/XLEN; // 8：cacheline 中 PTE 个数
  localparam int CONTIGUOUS    = 8;            // tlbcontiguous
  localparam int SECTOR_W      = 3;            // sectortlbwidth = log2(tlbcontiguous)
  localparam int PREFETCH_ID   = 2;            // prefetchID（source==2 表示预取）

  // 选择 cacheline 内 PTE 的索引位段：addr[log2(blockBytes)-1 : log2(XLEN/8)]
  //   blockBytes=64 → 高位 = 5；XLEN/8=8 → 低位 = 3；即 addr[5:3]。
  localparam int IDX_HI = $clog2(BLOCK_BITS/8) - 1; // 5
  localparam int IDX_LO = $clog2(XLEN/8);           // 3

  // ---- s2xlate 模式 -----------------------------------------------------------
  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0, // 普通 satp，无 G-stage
    ONLY_STAGE1 = 2'h1, // 仅 VS-stage（结果即 GPA，本级不再 G-stage）
    ONLY_STAGE2 = 2'h2, // 仅 G-stage
    ALL_STAGE   = 2'h3  // VS-stage + G-stage
  } s2xlate_e;

  // ---- 条目状态机（对应 Scala 的 Enum(12)，本配置无 bitmap，只用其中 9 个）----
  //   Scala 顺序：idle, hptw_req, hptw_resp, addr_check, mem_req, mem_waiting,
  //               mem_out, last_hptw_req, last_hptw_resp, cache, bitmap_check,
  //               bitmap_resp。这里保持相同编码值，bitmap 两态省略（恒不进入）。
  typedef enum logic [3:0] {
    S_IDLE           = 4'h0, // 空闲：可被新请求占用
    S_HPTW_REQ       = 4'h1, // 等待发出首次 G-stage 翻译（页表页 GPA→HPA）
    S_HPTW_RESP      = 4'h2, // 等待首次 G-stage 响应
    S_ADDR_CHECK     = 4'h3, // 等待 PMP 同拍检查访存地址
    S_MEM_REQ        = 4'h4, // 等待向 page cache 发出 PTE 读请求（参与 mem_arb 仲裁）
    S_MEM_WAITING    = 4'h5, // 已发/被代发访存请求，等待 cacheline 返回
    S_MEM_OUT        = 4'h6, // PTE 已就绪，等待向上游 out 输出并回填
    S_LAST_HPTW_REQ  = 4'h7, // VS leaf 后还需最后一次 G-stage 翻译
    S_LAST_HPTW_RESP = 4'h8, // 等待最后一次 G-stage 响应
    S_CACHE          = 4'h9  // 与在途条目重复，转去重读 page cache
  } llptw_state_e;

  // ---- CSR 中 LLPTW 实际用到的字段 -------------------------------------------
  typedef struct packed {
    logic       sfence_valid;
    logic       satp_changed;
    logic       vsatp_changed;
    logic [3:0] hgatp_mode;
    logic       hgatp_changed;
    logic       priv_mxr;
    logic       m_pbmt_enable; // mPBMTE
    logic       h_pbmt_enable; // hPBMTE
  } llptw_csr_t;

  // ---- L2TlbInnerBundle：请求基本信息 ----------------------------------------
  typedef struct packed {
    logic [VPN_W-1:0]    vpn;
    logic [1:0]          s2xlate;
    logic [SOURCE_W-1:0] source;
  } req_info_t;

  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } hptw_perm_t;

  // ---- HptwResp：G-stage TLB entry + gpf/gaf ---------------------------------
  typedef struct packed {
    logic [GVPN_W-1:0] tag;
    logic [VMID_W-1:0] vmid;
    logic              n;
    logic [1:0]        pbmt;
    logic [GVPN_W-1:0] ppn;
    hptw_perm_t        perm;
    logic [1:0]        level;
    logic              gpf;
    logic              gaf;
  } hptw_resp_t;

  // ---- RISC-V PTE 位布局（高位到低位，使 packed struct ≡ UInt[63:0]）---------
  typedef struct packed {
    logic d, a, g, u, x, w, r, v;
  } pte_perm_t;

  typedef struct packed {
    logic             n;
    logic [1:0]       pbmt;
    logic [6:0]       reserved;
    logic [7:0]       ppn_high;
    logic [PPN_W-1:0] ppn;
    logic [1:0]       rsw;
    pte_perm_t        perm;
  } pte_t;

  // ---- 条目（LLPTWEntry）：bitmap 字段在本配置下省略 -------------------------
  typedef struct packed {
    req_info_t          req_info;
    logic [PTE_PPN_W-1:0] ppn;
    logic [ID_W-1:0]    wait_id;            // 去重时记录所等待的“代发”条目号
    logic               af;                 // PMP access fault
    hptw_resp_t         hptw_resp;
    logic               first_s2xlate_fault; // 首次 G-stage 即出现 gpf/gaf
  } llptw_entry_t;

  // ===========================================================================
  // 纯函数：地址生成 / PTE 解析 / 去重判断（全部对应 MMUConst/MMUBundle 的 def）
  // ===========================================================================

  // getVpnn(vpn, idx)：取第 idx 级的 9-bit VPN 段。LLPTW 只用 idx=0（最后一级）。
  function automatic logic [VPNN_W-1:0] get_vpnn0(input logic [VPN_W-1:0] vpn);
    return vpn[VPNN_W-1:0];
  endfunction

  // MakeAddr(ppn, off9) = {ppn, off, 3'b000}。LLPTW 用 ppnLen=36 位 ppn。
  function automatic logic [PADDR_W-1:0] make_addr(
    input logic [PPN_W-1:0]  ppn,
    input logic [VPNN_W-1:0] vpnn
  );
    return {ppn, vpnn, 3'b000};
  endfunction

  // getPPN() = {ppn_high, ppn}
  function automatic logic [PTE_PPN_W-1:0] pte_get_ppn(input pte_t pte);
    return {pte.ppn_high, pte.ppn};
  endfunction

  function automatic logic pte_is_leaf(input pte_t pte);
    return (pte.perm.r || pte.perm.x || pte.perm.w) && pte.perm.v;
  endfunction

  function automatic logic pte_is_next(input pte_t pte);
    return !(pte.perm.r || pte.perm.x || pte.perm.w) && pte.perm.v;
  endfunction

  // PteBundle.isPf：最后一级页表项的 page fault 判定（level 此处恒为 0）。
  function automatic logic pte_is_pf(input pte_t pte, input logic [1:0] level, input logic pbmte);
    logic unaligned;
    unaligned =
      pte_is_leaf(pte) &&
      !(level == 2'h0 ||
        (level == 2'h1 && pte.ppn[VPNN_W-1:0]     == '0) ||
        (level == 2'h2 && pte.ppn[VPNN_W*2-1:0]   == '0) ||
        (level == 2'h3 && pte.ppn[VPNN_W*3-1:0]   == '0));
    // 单一 return(嵌套三元): 多 return 早退结构会被 Formality 建成带 DC 缺省支路的
    // 优先级 mux, X 传染导致大片 failing —— 与 IMSIC 的 generate 内函数教训同族。
    return (pte.reserved != '0)                                ? 1'b1
         : (pte.pbmt == 2'h3 || (!pbmte && pte.pbmt != 2'h0))  ? 1'b1
         : pte_is_next(pte) ? (pte.perm.u || pte.perm.a || pte.perm.d || pte.n || (pte.pbmt != 2'h0))
         : (!pte.perm.v || (!pte.perm.r && pte.perm.w))        ? 1'b1
         : (pte.n && (pte.ppn[3:0] != 4'h8 || level != 2'h0))  ? 1'b1
         : unaligned;
  endfunction

  // PteBundle.isStage1Gpf：PPN 高位越过 G-stage 地址空间时的 gpf（v 有效才算）。
  function automatic logic pte_is_stage1_gpf(input pte_t pte, input logic [3:0] hgatp_mode);
    logic [PTE_PPN_W-1:0] full_ppn;
    full_ppn = pte_get_ppn(pte);
    // GPAddrBitsSv39x4=41 → 高位段 = full_ppn >> (41-12)=29
    // GPAddrBitsSv48x4=50 → 高位段 = full_ppn >> (50-12)=38
    // 单一 return: 消 FM 多 return DC 支路。
    return (hgatp_mode == 4'h8) ? ((|full_ppn[PTE_PPN_W-1:29]) && pte.perm.v)
         : (hgatp_mode == 4'h9) ? ((|full_ppn[PTE_PPN_W-1:38]) && pte.perm.v)
         : 1'b0;
  endfunction

  // 最后一级 PPN：非 NAPOT 直接取 PTE.ppn；NAPOT 用 vpn 低 NAPOT_BITS 位拼接。
  function automatic logic [PTE_PPN_W-1:0] last_ppn(
    input pte_t pte, input logic [VPN_W-1:0] vpn
  );
    logic [PTE_PPN_W-1:0] full_ppn;
    full_ppn = pte_get_ppn(pte);
    // 单一 return: 消 FM 多 return DC 支路。
    return (!pte.n) ? full_ppn
                    : {full_ppn[PTE_PPN_W-1:NAPOT_BITS], vpn[NAPOT_BITS-1:0]};
  endfunction

  // HptwResp.genPPNS2：按 G-stage entry level 把 GPA 页内 VPN 补回，得到 host PPN。
  function automatic logic [GVPN_W-1:0] gen_ppn_s2(
    input hptw_resp_t resp, input logic [GVPN_W-1:0] gvpn
  );
    // 单一 return(嵌套三元, 替代 priority case+return): 消 FM DC 支路。
    return (resp.level == 2'h3) ? {resp.ppn[GVPN_W-1:VPNN_W*3], gvpn[VPNN_W*3-1:0]}
         : (resp.level == 2'h2) ? {resp.ppn[GVPN_W-1:VPNN_W*2], gvpn[VPNN_W*2-1:0]}
         : (resp.level == 2'h1) ? {resp.ppn[GVPN_W-1:VPNN_W],   gvpn[VPNN_W-1:0]}
         : (resp.n ? {resp.ppn[GVPN_W-1:NAPOT_BITS], gvpn[NAPOT_BITS-1:0]}
                   : resp.ppn);
  endfunction

  // dup：两个 vpn 是否落在同一条 L0 cacheline（去掉 sector 位后相等）。
  //   dropL0SectorBits(vpn) = vpn[VPN_W-1 : SECTOR_W]。
  function automatic logic vpn_dup(input logic [VPN_W-1:0] a, input logic [VPN_W-1:0] b);
    return a[VPN_W-1:SECTOR_W] == b[VPN_W-1:SECTOR_W];
  endfunction

  // from_pre：source 为预取 ID。预取请求若不需要访存就直接丢弃（回 idle）。
  function automatic logic from_pre(input logic [SOURCE_W-1:0] source);
    return source == SOURCE_W'(PREFETCH_ID);
  endfunction

endpackage
