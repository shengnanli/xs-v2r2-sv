// =============================================================================
// xs_tlbfa_pkg —— 全相联 TLB 存储（TLBFA）的共享类型与纯函数
//
// 对应 Chisel: xiangshan.cache.mmu.TLBStorage.scala  (class TLBFA)
//   条目类型      : MMUBundle.scala  class TlbSectorEntry
//   匹配/取PPN    : TlbSectorEntry.hit() / genPPN()
//   refill 解包   : TlbSectorEntry.apply(PtwRespS2)
//
// 角色：TLBFA 是 ITLB / DTLB(load/store) 内部的“全相联页表项缓存”。它存放 nWays 条
//   翻译条目，每条记录一个（可能是大页 / 64KB napot / sector）的 vpn→ppn 映射及权限。
//   - 查询(read)  ：输入 vpn + asid/vmid + s2xlate，N 条目并行 CAM 匹配，命中则用
//                   Mux1H 选出 ppn(经 genPPN 拼接大页低位)、perm、pbmt 等。
//   - 填充(refill)：PTW 回填一条 PtwRespS2，按替换器给的 wayIdx 写入对应条目。
//   - 刷新(sfence/hfence)：按 vpn/asid/vmid 选择性或整体把条目 valid 清 0。
//
// 设计要点（“sector TLB”）：一条目用一个 tag 覆盖 tlbcontiguous(=8) 个连续 4KB 页，
//   每个子页有独立的 valididx/pteidx/ppn_low。命中除 tag 匹配外还要 valididx[vpn 低位]，
//   故同一条目可能多子页命中（multi-hit，见 Scala wbhit 注释）。
//
// 关键参数（香山 KunmingHu V2R2，Sv39+H 扩展，见 MMUConst.scala）：
//   vpnLen=38 ppnLen=36 sectortlbwidth=3 tlbcontiguous=8 vpnnLen=9 Level=2
//   sectorvpnLen=35 sectorppnLen=33 asidLen=16 vmidLen=14
//   s2xlate 编码：noS2xlate=0 onlyStage1=1 onlyStage2=2 allStage=3
//
// 这里把 golden(firtool) 展平成几万行的“N 条目 × 宽匹配”逻辑，收敛成：
//   条目 struct + 三个纯函数(hit/genppn/refill) + 上层用 for/genvar 并行实例化。
// =============================================================================
package xs_tlbfa_pkg;

  // ---------------- 物理参数（来自 MMUConst.scala 的具体配置取值）----------------
  localparam int VPN_LEN        = 38;  // vpnLen   = VAddrBits(50)-offLen(12)
  localparam int PPN_LEN        = 36;  // ppnLen   = PAddrBits(48)-offLen(12)
  localparam int VPNN_LEN       = 9;   // 每级页号位宽
  localparam int LEVEL          = 2;   // Sv39: 0=4KB 1=2MB 2=1GB（level 字段 2 位）
  localparam int SECTOR_W       = 3;   // sectortlbwidth = log2(tlbcontiguous)
  localparam int TLB_CONTIG     = 8;   // 一条目覆盖的连续 4KB 子页数
  localparam int SECTORVPN_LEN  = VPN_LEN - SECTOR_W;   // 35  条目 tag 宽
  localparam int SECTORPPN_LEN  = PPN_LEN - SECTOR_W;   // 33  条目 ppn 宽
  localparam int ASID_LEN       = 16;
  localparam int VMID_LEN       = 14;
  localparam int PBMT_LEN       = 2;
  localparam int S1PPN_LEN      = 41;  // s1.entry.ppn (io_w_bits_data_s1_entry_ppn)
  localparam int S2TAG_LEN      = 38;  // s2.entry.tag (gvpnLen)
  localparam int S2PPN_LEN      = 38;  // s2.entry.ppn
  localparam int PTE_NAPOT_BITS = 4;   // 64KB napot 占用的低位数

  // s2xlate 两级翻译模式编码
  localparam logic [1:0] NO_S2     = 2'd0;  // 无第二阶段（纯 stage1 / 关 H）
  localparam logic [1:0] ONLY_S1   = 2'd1;  // 仅 stage1
  localparam logic [1:0] ONLY_S2   = 2'd2;  // 仅 stage2（G-stage）
  localparam logic [1:0] ALL_STAGE = 2'd3;  // 两级都做

  // ---------------- 权限位 bundle ----------------
  // stage1 权限（软件页表项 perm）。pf/af 是缺页/访问错误标志；v 为 stage1 是否有效。
  typedef struct packed {
    logic pf; logic af; logic v;
    logic d; logic a; logic g; logic u; logic x; logic w; logic r;
  } tlb_perm_t;

  // stage2(G-stage) 权限：与 stage1 同为完整 TlbPermBundle（pf/af/v/d/a/g/u/x/w/r）。
  //   不同 TLBFA 变体下游只用其中一部分，firtool 因此对 golden 各端口做了不同裁剪；
  //   可读核统一算全字段，wrapper 只驱动 golden 实际暴露的端口。
  typedef tlb_perm_t tlb_gperm_t;

  // ---------------- 一条全相联 TLB 条目（= TlbSectorEntry）----------------
  // valid 单独放在条目数组外（v 寄存器，复位清 0、sfence 可清），其余字段不复位。
  typedef struct packed {
    logic [SECTORVPN_LEN-1:0]     tag;       // sector vpn（高 35 位）
    logic [ASID_LEN-1:0]          asid;
    logic [1:0]                   level;     // 0:4KB 1:2MB 2:1GB（3 仅 Sv48）
    logic [SECTORPPN_LEN-1:0]     ppn;       // sector ppn（高 33 位）
    logic                         n;         // 1: 64KB napot 页
    logic [PBMT_LEN-1:0]          pbmt;      // stage1 内存类型
    logic [PBMT_LEN-1:0]          g_pbmt;    // stage2 内存类型
    tlb_perm_t                    perm;      // stage1 权限
    logic [TLB_CONTIG-1:0]        valididx;  // 各子页是否有效（命中需查此位）
    logic [TLB_CONTIG-1:0]        pteidx;    // 各子页是否为 stage1 末级 pte
    logic [TLB_CONTIG-1:0][SECTOR_W-1:0] ppn_low; // 各子页的 ppn 低位（packed）
    tlb_gperm_t                   g_perm;    // stage2 权限
    logic [VMID_LEN-1:0]          vmid;
    logic [1:0]                   s2xlate;   // 本条目所属翻译模式
  } tlb_entry_t;

  // ---------------- 查询请求 / refill 写数据（聚合 golden 扁平端口）----------------
  typedef struct packed {
    logic [VPN_LEN-1:0] vpn;
    logic [1:0]         s2xlate;
  } tlb_req_t;

  // refill 写入的原始数据 = PtwRespS2（stage1 + stage2 两份页表项）。
  // 这里只保留 TLBFA.apply 实际读取的字段（其余 PtwRespS2 字段不影响存储结果）。
  typedef struct packed {
    // stage1
    logic [34:0]            s1_entry_tag;
    logic [ASID_LEN-1:0]    s1_entry_asid;
    logic [VMID_LEN-1:0]    s1_entry_vmid;
    logic                   s1_entry_n;
    logic [PBMT_LEN-1:0]    s1_entry_pbmt;
    tlb_perm_t              s1_entry_perm;   // {pf?..} 实际只用 d/a/g/u/x/w/r + v
    logic [1:0]             s1_entry_level;
    logic                   s1_entry_v;
    logic [S1PPN_LEN-1:0]   s1_entry_ppn;
    logic [TLB_CONTIG-1:0][SECTOR_W-1:0] s1_ppn_low;  // packed
    logic [TLB_CONTIG-1:0]  s1_valididx;
    logic [TLB_CONTIG-1:0]  s1_pteidx;
    logic                   s1_pf;
    logic                   s1_af;
    // stage2
    logic [S2TAG_LEN-1:0]   s2_entry_tag;
    logic [VMID_LEN-1:0]    s2_entry_vmid;
    logic                   s2_entry_n;
    logic [PBMT_LEN-1:0]    s2_entry_pbmt;
    logic [S2PPN_LEN-1:0]   s2_entry_ppn;
    tlb_perm_t              s2_entry_perm;   // s2 软件页表权限（d/a/g/u/x/w/r 用于 g_perm）
    logic [1:0]             s2_entry_level;
    logic                   s2_gpf;
    logic                   s2_gaf;
    // 顶层 s2xlate
    logic [1:0]             s2xlate;
  } tlb_refill_t;

  // =========================================================================
  // hit —— 单条目并行 CAM 匹配（= TlbSectorEntry.hit）
  //   返回该条目对 (vpn, asid, vmid, s2xlate) 是否命中（不含 valid / s2xlate_hit，
  //   那两项由调用者另算，便于复用于 sfence）。具体包含：
  //     asid_hit  : onlyS2 时忽略 asid；否则 asid 相等或 global(perm.g)
  //     tag_match : 分级匹配，超出本条目 level 的高位级不要求匹配
  //     low_hit   : valididx[vpn 低 3 位]（sector 子页有效）
  //     vmid_hit  : 有 s2xlate 时 vmid 相等
  //     pteidx_hit: 4KB 非超页且有 s2xlate 且 stage1 末级，需 pteidx[vpn 低 3 位]
  // =========================================================================
  function automatic logic xs_tlb_hit(
      input tlb_entry_t          e,
      input logic [VPN_LEN-1:0]  vpn,
      input logic [ASID_LEN-1:0] asid,    // onlyS2 取 satp.asid，否则按 hasS2 取 v/satp
      input logic [15:0]         vmid,    // hgatp.vmid（16 位：golden 端口为 [15:0]）
      input logic                has_s2,  // s2xlate != noS2
      input logic                only_s2, // s2xlate == onlyStage2
      input logic                only_s1, // s2xlate == onlyStage1
      input logic                ignore_asid);
    automatic logic [SECTOR_W-1:0] low = vpn[SECTOR_W-1:0];
    automatic logic asid_hit;
    automatic logic tag_hi, tag_m1, tag_m2, tag_lo, tag_match;
    automatic logic addr_low_hit, vmid_hit, pteidx_hit;
    automatic logic is_super;

    asid_hit = (has_s2 && only_s2) ? 1'b1
             : ignore_asid         ? 1'b1
             : ((e.asid == asid) || e.perm.g);

    // 分级 tag 匹配：高位级总要匹配；中/低级若条目 level 已覆盖则免匹配。
    //   level>=1(非4KB) → 最低级页内偏移不比；level>=2 → 次低级也不比；level==3(Sv48) → 再上一级。
    tag_hi = (e.tag[34:24] == vpn[37:27]);                              // 顶级 vpnn（总比）
    tag_m1 = (e.tag[23:15] == vpn[26:18]) || (&e.level);               // level>=3
    tag_m2 = (e.tag[14:6]  == vpn[17:9])  || e.level[1];               // level>=2
    tag_lo = (e.n ? (e.tag[5:1] == vpn[8:4])                          // 64KB：比 5 位
                  : (e.tag[5:0] == vpn[8:3]))                          // 4KB：比 6 位
             || (|e.level);                                            // level>=1
    tag_match = tag_hi & tag_m1 & tag_m2 & tag_lo;

    addr_low_hit = e.valididx[low];
    // vmid 比较按 golden：{2'b0, 条目14位vmid} 与 16 位 hgatp.vmid 全比较
    vmid_hit     = has_s2 ? ({2'b0, e.vmid} == vmid) : 1'b1;
    is_super     = (e.level != 2'd0);
    // 仅“有 s2 翻译 + 非超页 + 非 onlyS1 + 非 napot”时才校验 pteidx
    pteidx_hit   = (has_s2 && !is_super && !only_s1 && !e.n) ? e.pteidx[low] : 1'b1;

    return asid_hit & tag_match & addr_low_hit & vmid_hit & pteidx_hit;
  endfunction

  // =========================================================================
  // genppn —— 命中条目按 level/n 把存储 ppn 与请求 vpn 拼成最终 PPN（= genPPN）
  //   大页(level>0)的页内高位用 vpn 取代 ppn；4KB 非 napot 时低 3 位用 ppn_low[vpn 低位]。
  // =========================================================================
  function automatic logic [PPN_LEN-1:0] xs_tlb_genppn(
      input tlb_entry_t e, input logic [VPN_LEN-1:0] vpn);
    automatic logic [VPNN_LEN-1:0] mid1, mid2, lo9;
    mid1 = (&e.level)   ? vpn[26:18] : e.ppn[23:15];   // level>=3
    mid2 = e.level[1]   ? vpn[17:9]  : e.ppn[14:6];    // level>=2
    lo9  = (|e.level)   ? vpn[8:0]                      // level>=1：整 9 位用 vpn
         : e.n          ? {e.ppn[5:1], vpn[3:0]}        // 4KB napot：低 4 位用 vpn
         :                {e.ppn[5:0], e.ppn_low[vpn[SECTOR_W-1:0]]}; // 4KB：补 ppn_low
    return {e.ppn[32:24], mid1, mid2, lo9};
  endfunction

  // =========================================================================
  // refill —— 把 PtwRespS2 解包成一条 tlb_entry_t（= TlbSectorEntry.apply）
  //   依 s2xlate 选 stage1/stage2 的 level/tag/ppn/vmid，并按两级合成 napot(n)、
  //   valididx、pteidx。是该模块最绕的一段，逐字段对照 Scala apply 实现。
  // =========================================================================
  function automatic tlb_entry_t xs_tlb_refill(input tlb_refill_t d);
    automatic tlb_entry_t e;
    automatic logic       has_s2  = (|d.s2xlate);
    automatic logic       all_st  = (&d.s2xlate);            // allStage
    automatic logic       is_s2   = (d.s2xlate == ONLY_S2);
    automatic logic [1:0] s2lv    = d.s2_entry_level;
    automatic logic       super_p;
    automatic logic [SECTOR_W-1:0] s2sub = d.s2_entry_tag[SECTOR_W-1:0];
    automatic logic [SECTORPPN_LEN-1:0] s2ppn;
    automatic logic [SECTOR_W-1:0] s2ppn_low3;
    automatic logic       s1_or_none;
    automatic logic       s2_napot_idx;

    // ---- level：取两级中较小页（较小 level）；onlyS2 取 s2，onlyS1/noS2 取 s1 ----
    e.level = has_s2 ? (all_st ? ((d.s1_entry_level < s2lv) ? d.s1_entry_level : s2lv)
                               : (is_s2 ? s2lv : d.s1_entry_level))
                     : d.s1_entry_level;

    // ---- n(64KB napot)：allStage 三种 napot 组合，否则按阶段取 ----
    e.n = has_s2 ? (all_st ? ((d.s1_entry_n & (|s2lv))
                              | (d.s2_entry_n & (|d.s1_entry_level))
                              | (d.s1_entry_n & d.s2_entry_n))
                           : (is_s2 ? d.s2_entry_n : d.s1_entry_n))
                 : d.s1_entry_n;

    super_p = (|e.level) | e.n;   // 是否超页/napot（决定 valididx 全置）

    // ---- tag：onlyS2 用 s2.tag 高位，否则 s1.tag ----
    e.tag  = is_s2 ? d.s2_entry_tag[37:3] : d.s1_entry_tag;
    e.asid = d.s1_entry_asid;
    e.pbmt   = d.s1_entry_pbmt;
    e.g_pbmt = d.s2_entry_pbmt;
    e.vmid   = is_s2 ? d.s2_entry_vmid : d.s1_entry_vmid;
    e.s2xlate = d.s2xlate;

    // stage1 perm 直接搬运（v 来自 s1.entry.v）
    e.perm = '{ pf:d.s1_pf, af:d.s1_af, v:d.s1_entry_v,
                d:d.s1_entry_perm.d, a:d.s1_entry_perm.a, g:d.s1_entry_perm.g,
                u:d.s1_entry_perm.u, x:d.s1_entry_perm.x, w:d.s1_entry_perm.w,
                r:d.s1_entry_perm.r };
    // stage2 perm(applyS2)：pf/af 来自 gpf/gaf，v 无意义置 0，其余取 s2.entry.perm
    e.g_perm = '{ pf:d.s2_gpf, af:d.s2_gaf, v:1'b0,
                  d:d.s2_entry_perm.d, a:d.s2_entry_perm.a, g:d.s2_entry_perm.g,
                  u:d.s2_entry_perm.u, x:d.s2_entry_perm.x, w:d.s2_entry_perm.w,
                  r:d.s2_entry_perm.r };

    // ---- ppn / ppn_low ----
    // s2ppn(sector,33位)：按 s2 level 把 s2.ppn 高位与 s2.tag 的“sector 对齐”低位拼接，
    //   写入 this.ppn。level 3/2/1 各保留不同高位；level0 时看 s2.n 决定 napot 拼接。
    unique case (s2lv)
      2'd3: s2ppn = {d.s2_entry_ppn[35:27], d.s2_entry_tag[26:3]};
      2'd2: s2ppn = {d.s2_entry_ppn[35:18], d.s2_entry_tag[17:3]};
      2'd1: s2ppn = {d.s2_entry_ppn[35:9],  d.s2_entry_tag[8:3]};
      default: s2ppn = d.s2_entry_n ? {d.s2_entry_ppn[35:4], d.s2_entry_tag[3]}
                                    : d.s2_entry_ppn[35:3];
    endcase
    // s2ppn_tmp(full,36位)：与 s2ppn 同结构但保留 tag 的“未对齐低位”，仅取其低 3 位作
    //   onlyS2 时各子页的 ppn_low（对应 Scala 的 s2ppn_tmp 低 sectortlbwidth 位）。
    unique case (s2lv)
      2'd3: s2ppn_low3 = d.s2_entry_tag[2:0];                  // {ppn[35:27],tag[26:0]}[2:0]
      2'd2: s2ppn_low3 = d.s2_entry_tag[2:0];                  // {ppn[35:18],tag[17:0]}[2:0]
      2'd1: s2ppn_low3 = d.s2_entry_tag[2:0];                  // {ppn[35:9], tag[8:0] }[2:0]
      default: s2ppn_low3 = d.s2_entry_n ? d.s2_entry_tag[2:0] // {ppn[35:4],tag[3:0]}[2:0]
                                         : d.s2_entry_ppn[2:0]; // ppn[35:0][2:0]
    endcase
    s1_or_none = (!has_s2) | (d.s2xlate == ONLY_S1);   // 用 stage1 的 ppn
    e.ppn = s1_or_none ? d.s1_entry_ppn[32:0] : s2ppn;
    // ppn_low：stage1 用 s1.ppn_low[i]；stage2 各子页同值（s2ppn_tmp 的低 3 位）
    for (int i = 0; i < TLB_CONTIG; i++)
      e.ppn_low[i] = s1_or_none ? d.s1_ppn_low[i] : s2ppn_low3;

    // ---- valididx / pteidx ----
    // 超页：所有子页有效；onlyS2：仅 s2.tag 低位指向的子页(one-hot)；否则用 s1.valididx
    s2_napot_idx = is_s2;  // onlyS2 时 valididx/pteidx 都来自 s2.tag 低位 one-hot
    for (int i = 0; i < TLB_CONTIG; i++) begin
      automatic logic s2_oh = (s2sub == i[SECTOR_W-1:0]);  // UIntToOH(s2.tag 低 3 位)
      e.valididx[i] = super_p | (s2_napot_idx ? s2_oh : d.s1_valididx[i]);
      e.pteidx[i]   =            s2_napot_idx ? s2_oh : d.s1_pteidx[i];
    end
    return e;
  endfunction

  // OHToUInt：把 one-hot 命中向量编码成 way 索引（参数化宽度）。
  function automatic logic [5:0] xs_oh_to_uint(input logic [63:0] oh, input int n);
    automatic logic [5:0] idx = '0;
    for (int i = 0; i < n; i++)
      if (oh[i]) idx |= i[5:0];
    return idx;
  endfunction

endpackage
