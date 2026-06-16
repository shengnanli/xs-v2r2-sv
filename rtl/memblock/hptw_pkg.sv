// =============================================================================
// xs_hptw_pkg —— HPTW（Hypervisor Page Table Walker）可读重写的类型与纯函数
//
// 设计来源：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/PageTableWalker.scala class HPTW
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala PteBundle/HptwResp
//
// HPTW 是 H 扩展下专用的 G-stage（second-stage）页表遍历器。当 PTW/LLPTW
// 在 VS-stage 走表得到一个 GPA（guest physical address）后，需要再经 G-stage
// 把 GPA 翻译成 HPA（host physical address）。HPTW 接到一个 gvpn 请求后，
// 用 hgatp 作为根，按 Sv39x4/Sv48x4 逐级走 G-stage 页表，最终返回一个
// HptwResp（G-stage TLB entry + gpf/gaf）。
//
// 与 PTW 不同点：
//   1. HPTW 走“整条”G-stage（包括最后一级 leaf），所以 level 会一直降到 0；
//      PTW 只走上层、把最后一级交给 LLPTW。
//   2. 根地址用 MakeGPAddr（hgatp.ppn + gvpnn），而后续层用 MakeAddr（pte.ppn）。
//      G-stage 第一级地址比普通级宽一些（x4：多 2 位索引）。
//   3. fault 语义：gpf（guest page fault）/gaf（guest access fault）。
// =============================================================================
package xs_hptw_pkg;

  localparam int XLEN        = 64;
  localparam int PADDR_W     = 48;  // PAddrBits
  localparam int GPADDR_W    = 50;  // GPAddrBits = Sv48x4 的 50 位
  localparam int OFF_W       = 12;  // offLen
  localparam int VPNN_W      = 9;   // 每级页表索引位宽
  localparam int PPN_W       = 36;  // ppnLen  = PAddrBits - offLen
  localparam int PTE_PPN_W   = 44;  // ptePPNLen
  localparam int H_PPN_W     = 38;  // HptwResp.entry.ppn / tag 宽度 = gvpnLen
  localparam int VMID_W      = 14;  // HptwResp 实际只用 14 位 vmid
  localparam int SOURCE_W    = 2;   // bSourceWidth
  localparam int ID_W        = 3;   // log2Up(llptwsize) ⇒ resp.id/req.id
  localparam int LEVEL_W     = 2;   // log2Up(Level+1)
  localparam int NAPOT_BITS  = 4;

  localparam logic [3:0] HGATP_BARE = 4'h0;
  localparam logic [3:0] HGATP_SV39 = 4'h8;  // Sv39x4
  localparam logic [3:0] HGATP_SV48 = 4'h9;  // Sv48x4

  // HPTW 用到的 CSR 字段。hgatp 变化、satp/vsatp 变化、sfence 都会冲刷。
  typedef struct packed {
    logic [3:0]       hgatp_mode;
    logic [15:0]      hgatp_vmid_raw; // 端口 16 位，内部只用低 14 位
    logic [PTE_PPN_W-1:0] hgatp_ppn;
    logic             hgatp_changed;
    logic             satp_changed;
    logic             vsatp_changed;
    logic             m_pbmt_enable;  // mPBMTE：G-stage 用 M 态 PBMT 使能
  } hptw_csr_t;

  // HPTW 请求：gvpn 为要翻译的 guest VPN；l1/l2/l3Hit 表示 page-cache 命中级别，
  // 命中后可以从对应级开始走表（用 req_ppn 作为该级的页基址）。
  typedef struct packed {
    logic [SOURCE_W-1:0]   source;
    logic [ID_W-1:0]       id;
    logic [H_PPN_W-1:0]    gvpn;     // gvpnLen=38
    logic [PPN_W-1:0]      ppn;      // ppnLen=36
    logic                  l3_hit;
    logic                  l2_hit;
    logic                  l1_hit;
    logic                  bypassed; // bypass 不回填 page cache
  } hptw_req_t;

  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } ptw_perm_t;

  // RISC-V PTE 物理布局（bit[63:0]），高位到低位声明使 packed struct 等价 UInt。
  typedef struct packed {
    logic                 n;          // [63] NAPOT
    logic [1:0]           pbmt;       // [62:61]
    logic [6:0]           reserved;   // [60:54]
    logic [7:0]           ppn_high;   // [53:46]
    logic [PPN_W-1:0]     ppn;        // [45:10]
    logic [1:0]           rsw;        // [9:8]
    logic                 perm_d;     // [7]
    logic                 perm_a;     // [6]
    logic                 perm_g;     // [5]
    logic                 perm_u;     // [4]
    logic                 perm_x;     // [3]
    logic                 perm_w;     // [2]
    logic                 perm_r;     // [1]
    logic                 perm_v;     // [0]
  } pte_t;

  // G-stage TLB entry + fault。HPTW 的 resp 输出。
  typedef struct packed {
    logic [H_PPN_W-1:0] tag;    // = gvpn
    logic [VMID_W-1:0]  vmid;
    logic               n;
    logic [1:0]         pbmt;
    logic [H_PPN_W-1:0] ppn;
    ptw_perm_t          perm;
    logic [1:0]         level;
    logic               gpf;
    logic               gaf;
  } hptw_resp_t;

  // ---- 纯函数：PTE 解析 ----

  function automatic logic pte_is_leaf(input pte_t pte);
    return pte.perm_v && (pte.perm_r || pte.perm_w || pte.perm_x);
  endfunction

  function automatic logic pte_is_next(input pte_t pte);
    return pte.perm_v && !(pte.perm_r || pte.perm_w || pte.perm_x);
  endfunction

  function automatic logic [PTE_PPN_W-1:0] pte_ppn(input pte_t pte);
    return {pte.ppn_high, pte.ppn};
  endfunction

  // 超级页对齐检查（unaligned）：leaf 在非 0 级时低位 PPN 必须对齐。
  function automatic logic pte_unaligned(input pte_t pte, input logic [1:0] level);
    return pte_is_leaf(pte) &&
      !(level == 2'h0 ||
        (level == 2'h1 && pte.ppn[8:0]  == 9'h0) ||
        (level == 2'h2 && pte.ppn[17:0] == 18'h0) ||
        (level == 2'h3 && pte.ppn[26:0] == 27'h0));
  endfunction

  // G-stage page fault（PteBundle.isGpf）。与 S-stage isPf 的关键区别：
  //   G-stage 为支持 VS-stage 是 LOAD 型访问，叶子项必须 U=1（!perm.u → gpf），
  //   且必须 A=1（!perm.a → gpf，D 位检查留给 L1TLB）；NAPOT 检查不带 level 条件。
  function automatic logic pte_is_gpf(
    input pte_t       pte,
    input logic [1:0] level,
    input logic       pbmt_enable
  );
    if (pte.reserved != 7'h0) return 1'b1;
    if (pte.pbmt == 2'h3 || (!pbmt_enable && pte.pbmt != 2'h0)) return 1'b1;
    if (pte_is_next(pte)) return pte.perm_u || pte.perm_a || pte.perm_d || pte.n || (pte.pbmt != 2'h0);
    if (!pte.perm_v || (!pte.perm_r && pte.perm_w)) return 1'b1;
    if (!pte.perm_u) return 1'b1;
    if (pte.n && pte.ppn[3:0] != 4'h8) return 1'b1;
    if (pte_unaligned(pte, level)) return 1'b1;
    if (!pte.perm_a) return 1'b1;
    return 1'b0;
  endfunction

  function automatic logic pte_access_fault(input pte_t pte);
    // 香山物理地址 48 位；PTE[53:46] 非零且有效作为 access fault。
    return (pte.ppn_high != 8'h0) && pte.perm_v;
  endfunction

  // 取 gvpn 的第 idx 级 9-bit 索引。
  function automatic logic [VPNN_W-1:0] get_vpnn(
    input logic [H_PPN_W-1:0] vpn, input logic [1:0] idx
  );
    priority case (idx)
      2'h0:    return vpn[8:0];
      2'h1:    return vpn[17:9];
      2'h2:    return vpn[26:18];
      default: return vpn[35:27];
    endcase
  endfunction

endpackage
