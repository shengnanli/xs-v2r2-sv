// mmu_common_pkg.sv —— MMU（L2TLB 走表器家族）子系统的公共包文件：跨模块共享类型/函数的唯一落点
//
// 规范依据（CONVENTIONS.md「单文件规范」）：包只在各自的 .sv 文件内私有，**跨模块共享**
// 的类型/参数/函数是明确的例外，放 `rtl/<subsys>/<subsys>_common_pkg.sv`，每个子系统至多
// 一个。本文件就是 mmu 子系统的那一个。
//
// 当前收录：
//   xs_mmu_common_pkg —— RISC-V Sv39/Sv48 页表项（PTE）的位图、L2TLB 内部的常量、
//                        以及 PTW / LLPTW / HPTW / Bitmap 走表器共用的 PTE 判定纯函数
//                        （isLeaf / isNext / unaligned / isPf / isGpf / isAf / isStage1Gpf）。
// 新增共享包时追加到本文件，不要再开第二个 mmu 公共包文件。
// （rtl/mmu/PtwCache.sv 早于本文件落地，自带私有 xs_ptwcache_pkg，不在此重构。）
//
// 对应 Chisel: xiangshan.cache.mmu.MMUBundle.scala  class PteBundle
//             xiangshan.cache.mmu.MMUConst.scala   trait HasPtwConst
//
// ★判定函数按 golden（firtool 折叠后的三目/或链）写成表达式而不是 if 链★：
//   Chisel 源是 when/elsewhen 优先链，firtool 折叠后的形状是
//   `c1 | c2 | (isNext ? X : (c4 | c5 | unaligned))`。两者在二值语义下恒等；
//   这里选表达式形，是为了让 X（未初始化 SRAM 读出）在两侧以同样的方式传播——
//   `if (x)` 遇 X 按假走，三目遇 X 吐 X，仿真里会在那些拍上产生假失配或假通过。
// =============================================================================
package xs_mmu_common_pkg;

  // ---- 几何常量（KunminghuV2Config：PAddrBits=48, GPAddrBits=50, EnableSv48=true）----
  localparam int XLEN_W     = 64;
  localparam int OFF_W      = 12;                 // 页内偏移
  localparam int PADDR_W    = 48;                 // PAddrBits
  localparam int PPN_W      = PADDR_W - OFF_W;    // 36 = ppnLen
  localparam int GPADDR_W   = 50;                 // GPAddrBits（Sv48x4）
  localparam int GVPN_W     = GPADDR_W - OFF_W;   // 38 = gvpnLen = vpnLen
  localparam int VPNN_W     = 9;                  // 每级 9 位 vpn 片
  localparam int LEVEL_W    = 2;                  // level ∈ 0..3（Sv48：3 = 根级）
  localparam int SECTOR_N   = 8;                  // tlbcontiguous：一次访存带回 8 个相邻 PTE
  localparam int SECTOR_W   = 3;                  // log2(SECTOR_N) = sectortlbwidth
  localparam int PTE_NAPOT_BITS = 4;              // Svnapot 64KB：ppn[3:0] == 4'b1000

  // hgatp/satp/vsatp 的 mode 编码
  localparam logic [3:0] MODE_SV39 = 4'h8;
  localparam logic [3:0] MODE_SV48 = 4'h9;

  // s2xlate（两阶段翻译模式）编码
  localparam logic [1:0] NO_S2XLATE  = 2'b00;
  localparam logic [1:0] ONLY_STAGE1 = 2'b01;
  localparam logic [1:0] ONLY_STAGE2 = 2'b10;
  localparam logic [1:0] ALL_STAGE   = 2'b11;

  // L2TLB 访存 id 分配：llptwsize=6 个 LLPTW 条目占 0..5，PTW 占 6，HPTW 占 7
  localparam int MEM_ID_W    = 4;                 // bMemID
  localparam int LLPTW_SIZE  = 6;
  localparam int PTW_REQ_ID  = LLPTW_SIZE;        // 6
  localparam int HPTW_REQ_ID = LLPTW_SIZE + 1;    // 7

  // ---- 页表项位图（RISC-V 特权规范 + Svpbmt/Svnapot 扩展）----
  typedef struct packed {
    logic d;   // dirty
    logic a;   // accessed
    logic g;   // global
    logic u;   // user
    logic x;   // execute
    logic w;   // write
    logic r;   // read
    logic v;   // valid
  } pte_perm_t;

  typedef struct packed {
    logic        n;         // [63]    Svnapot
    logic [1:0]  pbmt;      // [62:61] Svpbmt
    logic [6:0]  reserved;  // [60:54] 必须为 0
    logic [7:0]  ppn_high;  // [53:46] 超出 PAddrBits 的 ppn 高位（非 0 = access fault）
    logic [35:0] ppn;       // [45:10]
    logic [1:0]  rsw;       // [9:8]   软件保留
    pte_perm_t   perm;      // [7:0]   d a g u x w r v
  } pte_t;

  // 叶子：r/w/x 任一有效且 v
  function automatic logic pte_is_leaf(input pte_t p);
    return (p.perm.r | p.perm.x | p.perm.w) & p.perm.v;
  endfunction

  // 非叶子（指向下一级页表）：r/w/x 全 0 且 v
  function automatic logic pte_is_next(input pte_t p);
    return ~(p.perm.r | p.perm.x | p.perm.w) & p.perm.v;
  endfunction

  // 大页对齐检查：level 级叶子的 ppn 低 9*level 位必须为 0
  function automatic logic pte_unaligned(input pte_t p, input logic [1:0] level);
    return pte_is_leaf(p)
         & ~( (level == 2'd0)
            | (level == 2'd1 & p.ppn[VPNN_W-1:0]   == '0)
            | (level == 2'd2 & p.ppn[2*VPNN_W-1:0] == '0)
            | (level == 2'd3 & p.ppn[3*VPNN_W-1:0] == '0));
  endfunction

  // 页故障（VS/S 阶段）：PteBundle.isPf(level, pbmte)
  function automatic logic pte_is_pf(input pte_t p, input logic [1:0] level, input logic pbmte);
    return (p.reserved != '0)
         | (p.pbmt == 2'd3) | (~pbmte & (p.pbmt != '0))
         | (pte_is_next(p)
              ? (p.perm.u | p.perm.a | p.perm.d | p.n | (p.pbmt != '0))
              : ( ~p.perm.v | (~p.perm.r & p.perm.w)
                // 只支持 64KB napot（ppn[3:0]==8），且大页（level!=0）上 n 必须为 0
                | (p.n & (p.ppn[3:0] != 4'd8 | level != 2'd0))
                | pte_unaligned(p, level)));
  endfunction

  // G 阶段页故障：PteBundle.isGpf(level, pbmte)
  //   G 阶段为支持 VS 阶段只按 LOAD 检查：多查 u 位与 a 位，不查 d 位（d 在 L1 TLB 查）
  function automatic logic pte_is_gpf(input pte_t p, input logic [1:0] level, input logic pbmte);
    return (p.reserved != '0)
         | (p.pbmt == 2'd3) | (~pbmte & (p.pbmt != '0))
         | (pte_is_next(p)
              ? (p.perm.u | p.perm.a | p.perm.d | p.n | (p.pbmt != '0))
              : ( ~p.perm.v | (~p.perm.r & p.perm.w)
                | ~p.perm.u
                | (p.n & (p.ppn[3:0] != 4'd8))
                | pte_unaligned(p, level)
                | ~p.perm.a));
  endfunction

  // 访问故障：物理地址超出 PAddrBits（ppn_high 非 0）且 v
  function automatic logic pte_is_af(input pte_t p);
    return (p.ppn_high != '0) & p.perm.v;
  endfunction

  // 第一阶段（VS）翻译产出的 GPA 超出 hgatp 模式允许的位宽：PteBundle.isStage1Gpf(mode)
  //   Sv39x4 的 GPA 41 位 → {ppn_high,ppn} >> 29 非 0 即越界；Sv48x4 的 GPA 50 位 → >> 38。
  function automatic logic pte_is_stage1_gpf(input pte_t p, input logic [3:0] mode);
    logic [43:0] full_ppn;
    logic sv39_high, sv48_high;
    full_ppn  = {p.ppn_high, p.ppn};
    sv39_high = |full_ppn[43:29];
    sv48_high = |full_ppn[43:38];
    return ((mode == MODE_SV39) ? sv39_high : (mode == MODE_SV48) ? sv48_high : 1'b0) & p.perm.v;
  endfunction

  // 取 vpn 的第 idx 级 9 位片（idx 由信号给）：getVpnn(vpn, idx)
  function automatic logic [VPNN_W-1:0] vpn_slice(input logic [GVPN_W-1:0] vpn, input logic [1:0] idx);
    return (idx == 2'd3) ? vpn[4*VPNN_W-1:3*VPNN_W]
         : (idx == 2'd2) ? vpn[3*VPNN_W-1:2*VPNN_W]
         : (idx == 2'd1) ? vpn[2*VPNN_W-1:1*VPNN_W]
         :                 vpn[1*VPNN_W-1:0];
  endfunction

endpackage
