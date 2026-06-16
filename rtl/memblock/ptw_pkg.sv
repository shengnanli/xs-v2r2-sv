// =============================================================================
// xs_ptw_pkg —— PTW（Page Table Walker）可读重写的类型与纯函数
//
// 设计来源：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/PageTableWalker.scala class PTW
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala Pte/PtwMergeResp/HptwResp
//
// PTW 在 L2TLB miss 后负责“非最后一级”的页表遍历：先按 satp/vsatp/hgatp
// 生成页表项地址，经过 PMP/page-cache 读出 PTE；若读到 1GB/2MB/512GB 等
// superpage 或 fault 就直接返回，若走到最后一级则把请求交给 LLPTW 并释放 FSM。
// H 扩展下还要把 VS-stage 产生的 GPA 交给 HPTW 做 G-stage 翻译。
// =============================================================================
package xs_ptw_pkg;

  localparam int XLEN             = 64;
  localparam int LEVEL_MAX        = 3;   // EnableSv48=true：level 3/2/1/0
  localparam int CONTIGUOUS       = 8;   // sector TLB 连续 8 个 4KB PTE
  localparam int SECTOR_BITS      = 3;
  localparam int VPN_W            = 38;
  localparam int SECTOR_VPN_W     = 35;
  localparam int PTE_PPN_W        = 44;
  localparam int PPN_W            = 36;  // PAddrBits(48)-offLen(12)
  localparam int SECTOR_PTE_PPN_W = 41;
  localparam int H_ENTRY_PPN_W    = 38;  // gvpnLen = GPAddrBits(50)-12
  localparam int PADDR_W          = 48;
  localparam int PTE_ADDR_W       = 56;
  localparam int OFF_W            = 12;
  localparam int VPNN_W           = 9;
  localparam int ASID_W           = 16;
  localparam int VMID_W           = 14;
  localparam int SOURCE_W         = 2;
  localparam int NAPOT_BITS       = 4;

  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0, // 仅 S-stage/普通 satp
    ONLY_STAGE1 = 2'h1, // 仅 VS-stage：结果是 GPA，不再进 G-stage
    ONLY_STAGE2 = 2'h2, // 仅 G-stage：输入 vpn 已是 gvpn
    ALL_STAGE   = 2'h3  // VS-stage + G-stage
  } ptw_s2xlate_e;

  typedef enum logic [3:0] {
    PTW_IDLE,          // 空闲，可接收 L2TLB miss 请求
    PTW_HPTW_REQ,      // 等待发送首次 G-stage 翻译请求
    PTW_HPTW_WAIT,     // 等待首次 G-stage 响应，用于翻译页表页地址
    PTW_PMP_CHECK,     // 同拍 PMP 检查页表项读取地址
    PTW_MEM_REQ,       // 向 page cache 发送 PTE 读请求
    PTW_MEM_WAIT,      // 等待 page cache 返回 PTE
    PTW_EVAL_PTE,      // 解析 PTE：leaf/fault/non-leaf
    PTW_LAST_HPTW_REQ, // VS leaf 后还需要最后一次 G-stage 翻译
    PTW_LAST_HPTW_WAIT,
    PTW_LLPTW_REQ,     // 到达最后一级，交给 LLPTW 并释放本 FSM
    PTW_RESP_WAIT      // 等待上游接收 PTW 响应
  } ptw_state_e;

  // CSR 中 PTW 真正使用的字段。satp/vsatp/hgatp 变化或 sfence 会冲刷流水。
  typedef struct packed {
    logic [3:0]       satp_mode;
    logic [ASID_W-1:0] satp_asid;
    logic [PTE_PPN_W-1:0] satp_ppn;
    logic             satp_changed;
    logic [3:0]       vsatp_mode;
    logic [ASID_W-1:0] vsatp_asid;
    logic [PTE_PPN_W-1:0] vsatp_ppn;
    logic             vsatp_changed;
    logic [3:0]       hgatp_mode;
    logic [15:0]      hgatp_vmid_raw;
    logic             hgatp_changed;
    logic             priv_mxr;
    logic             m_pbmt_enable;
    logic             h_pbmt_enable;
  } ptw_csr_t;

  typedef struct packed {
    logic [VPN_W-1:0]    vpn;
    logic [1:0]          s2xlate;
    logic [SOURCE_W-1:0] source;
  } ptw_req_info_t;

  typedef struct packed {
    logic d, a, g, u, x, w, r, v;
  } pte_perm_t;

  // RISC-V PTE 物理布局：高位到低位声明，使 packed struct 与 UInt[63:0] 等价。
  typedef struct packed {
    logic                 n;
    logic [1:0]           pbmt;
    logic [6:0]           reserved;
    logic [7:0]           ppn_high;
    logic [PPN_W-1:0]     ppn;
    logic [1:0]           rsw;
    pte_perm_t            perm;
  } pte_t;

  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } ptw_perm_t;

  typedef struct packed {
    logic [SECTOR_VPN_W-1:0]     tag;
    logic [ASID_W-1:0]           asid;
    logic [VMID_W-1:0]           vmid;
    logic                        n;
    logic [1:0]                  pbmt;
    ptw_perm_t                   perm;
    logic [1:0]                  level;
    logic                        v;
    logic [SECTOR_PTE_PPN_W-1:0] ppn;
    logic [SECTOR_BITS-1:0]      ppn_low;
    logic                        af;
    logic                        pf;
  } ptw_merge_entry_t;

  typedef struct packed {
    ptw_merge_entry_t [CONTIGUOUS-1:0] entry;
    logic [CONTIGUOUS-1:0]       pteidx;
    logic                        not_super;
  } ptw_merge_resp_t;

  typedef struct packed {
    logic [H_ENTRY_PPN_W-1:0] tag;
    logic [VMID_W-1:0]        vmid;
    logic                     n;
    logic [1:0]               pbmt;
    logic [H_ENTRY_PPN_W-1:0] ppn;
    ptw_perm_t                perm;
    logic [1:0]               level;
    logic                     gpf;
    logic                     gaf;
  } hptw_resp_t;

  function automatic logic [8:0] get_vpnn(input logic [VPN_W-1:0] vpn, input logic [1:0] idx);
    priority case (idx)
      2'h0:    return vpn[8:0];
      2'h1:    return vpn[17:9];
      2'h2:    return vpn[26:18];
      default: return vpn[35:27];
    endcase
  endfunction

  function automatic logic [PTE_ADDR_W-1:0] make_pte_addr(
    input logic [PTE_PPN_W-1:0] ppn,
    input logic [8:0]           vpnn
  );
    return {ppn, vpnn, 3'b000};
  endfunction

  function automatic logic pte_is_leaf(input pte_t pte);
    return pte.perm.v && (pte.perm.r || pte.perm.w || pte.perm.x);
  endfunction

  function automatic logic pte_is_next(input pte_t pte);
    return pte.perm.v && !(pte.perm.r || pte.perm.w || pte.perm.x);
  endfunction

  function automatic logic [PTE_PPN_W-1:0] pte_ppn(input pte_t pte);
    return {pte.ppn_high, pte.ppn};
  endfunction

  // PTE page fault 规则来自 PteBundle.isPf：reserved/PBMT/非叶子脏位/非法权限/
  // NAPOT 规格/超级页对齐。PTW 只判断页表结构合法性，具体 load/store/exec 权限在 TLB 侧完成。
  function automatic logic pte_page_fault(
    input pte_t       pte,
    input logic [1:0] level,
    input logic       pbmt_enable
  );
    logic unaligned;
    unaligned =
      pte_is_leaf(pte) &&
      !(level == 2'h0 ||
        (level == 2'h1 && pte.ppn[8:0] == 9'h0) ||
        (level == 2'h2 && pte.ppn[17:0] == 18'h0) ||
        (level == 2'h3 && pte.ppn[26:0] == 27'h0));

    if (pte.reserved != 7'h0) return 1'b1;
    if (pte.pbmt == 2'h3 || (!pbmt_enable && pte.pbmt != 2'h0)) return 1'b1;
    if (pte_is_next(pte)) return pte.perm.u || pte.perm.a || pte.perm.d || pte.n || (pte.pbmt != 2'h0);
    if (!pte.perm.v || (!pte.perm.r && pte.perm.w)) return 1'b1;
    if (pte.n && (pte.ppn[3:0] != 4'h8 || level != 2'h0)) return 1'b1;
    return unaligned;
  endfunction

  function automatic logic pte_access_fault(input pte_t pte);
    // 香山物理地址只有 48 位；PTE[53:46] 非零且 PTE 有效时作为 access fault。
    return (pte.ppn_high != 8'h0) && pte.perm.v;
  endfunction

  function automatic logic pte_stage1_gpf(input pte_t pte, input logic [3:0] hgatp_mode);
    logic [PTE_PPN_W-1:0] full_ppn;
    logic sv39_high;
    logic sv48_high;
    full_ppn = pte_ppn(pte);
    sv39_high = |full_ppn[PTE_PPN_W-1:29];
    sv48_high = |full_ppn[PTE_PPN_W-1:38];
    if (hgatp_mode == 4'h8) return sv39_high && pte.perm.v;
    if (hgatp_mode == 4'h9) return sv48_high && pte.perm.v;
    return 1'b0;
  endfunction

  // HPTW 返回的是 G-stage TLB entry。按 level 把 guest PPN 中页内 VPN 段补回，
  // 得到真正访问 page cache 的 host PPN。
  function automatic logic [H_ENTRY_PPN_W-1:0] hptw_gen_ppn_s2(
    input hptw_resp_t resp,
    input logic [H_ENTRY_PPN_W-1:0] gvpn
  );
    priority case (resp.level)
      2'h3:    return {resp.ppn[H_ENTRY_PPN_W-1:27], gvpn[26:0]};
      2'h2:    return {resp.ppn[H_ENTRY_PPN_W-1:18], gvpn[17:0]};
      2'h1:    return {resp.ppn[H_ENTRY_PPN_W-1:9],  gvpn[8:0]};
      default: return resp.n ? {resp.ppn[H_ENTRY_PPN_W-1:NAPOT_BITS], gvpn[NAPOT_BITS-1:0]}
                             : resp.ppn;
    endcase
  endfunction

  function automatic logic [PTE_PPN_W-1:0] merge_resp_gen_ppn(input ptw_merge_resp_t resp);
    logic [2:0] idx;
    logic [37:0] tag;
    // Chisel OHToUInt 在输入不是 one-hot 时不是 priority encoder，而是各 bit
    // 位置的 OR 归约。真实 PtwMergeResp 会给 one-hot；FM 无约束时必须保留
    // 这个 multi-hot 行为，避免 full_gvpn_r 出现假 failing。
    idx[0] = resp.pteidx[1] | resp.pteidx[3] | resp.pteidx[5] | resp.pteidx[7];
    idx[1] = resp.pteidx[2] | resp.pteidx[3] | resp.pteidx[6] | resp.pteidx[7];
    idx[2] = resp.pteidx[4] | resp.pteidx[5] | resp.pteidx[6] | resp.pteidx[7];
    tag = {resp.entry[idx].tag, idx};
    priority case (resp.entry[idx].level)
      2'h3:    return {resp.entry[idx].ppn[40:24], tag[26:0]};
      2'h2:    return {resp.entry[idx].ppn[40:15], tag[17:0]};
      2'h1:    return {resp.entry[idx].ppn[40:6],  tag[8:0]};
      default: return resp.entry[idx].n ? {resp.entry[idx].ppn[40:1], tag[3:0]}
                                        : {resp.entry[idx].ppn, resp.entry[idx].ppn_low};
    endcase
  endfunction

endpackage
