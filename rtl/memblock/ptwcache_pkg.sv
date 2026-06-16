// =============================================================================
// xs_ptwcache_pkg —— PtwCache（L2TLB 页表 Cache）可读重写的类型/参数/纯函数
//
// 设计来源（从 Scala 设计意图重写，不是 firtool golden 转写）：
//   XiangShan/src/main/scala/xiangshan/cache/mmu/PageTableCache.scala  (class PtwCache)
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUBundle.scala       (PtwEntry / PtwEntries / PageCache*RespBundle)
//   XiangShan/src/main/scala/xiangshan/cache/mmu/MMUConst.scala        (HasPtwConst / genPtwL*SetIdx / replaceWrapper)
//
// 角色：PtwCache 缓存四级页表（昆明湖 EnableSv48=true：L3/L2/L1/L0 非叶 + L0 叶 +
//       超级页 SP），接收来自 PTW/LLPTW/HPTW 的页表项查询，三级流水（Req→Delay→Check→Resp）
//       内并行比较各级 tag 命中，命中即返回对应 PTE / 给 FSM 的 ppn；miss 由上游继续 walk。
//       refill 写入新页表项（PLRU/setPLRU 选 victim），sfence/hfence 按 asid/vmid/vpn 无效化。
//
// 本工程的硬性配置（取自 golden PtwCache.sv 实测，对应默认 L2TLBParameters）：
//   EnableSv48 = true   → 4 级（含 L3），Level=3
//   HasBitmapCheck = false → 无 bitmap 唤醒/检查端口
//   enablePTWECC  = false  → SRAM 不含 ecc 字段，eccError 恒 0
//
// 各级容量/组织（默认参数）：
//   L3: 16 项 全相联   tag=11b   (vpnn + 2 扩展位)
//   L2: 16 项 全相联   tag=20b
//   L1:  8 set × 2 way tag=23b   (SRAM, num=8 sector)
//   L0: 32 set × 4 way tag=24b   (SRAM, num=8 sector, 带 perm —— 叶子)
//   SP: 16 项 全相联   tag=38b   (带 level/napot/perm —— 超级页/svnapot 叶子)
// =============================================================================
package xs_ptwcache_pkg;

  // ---------------------------------------------------------------------------
  // 基本宽度参数（与 HasTlbConst / HasPtwConst 对齐）
  // ---------------------------------------------------------------------------
  localparam int XLEN        = 64;
  localparam int VPN_W       = 38;  // vpnLen = VAddrBits(50)-12，H 扩展再 +2
  localparam int GVPN_W      = 38;  // gvpnLen = GPAddrBits(50)-12
  localparam int PPN_W       = 36;  // ppnLen = PAddrBits(48)-12
  localparam int VPNN_W      = 9;   // 单级 VPN 段
  localparam int ASID_W      = 16;
  localparam int VMID_W      = 14;
  localparam int PBMT_W      = 2;
  localparam int OFF_W       = 12;
  localparam int SECTOR_W    = 3;   // log2(tlbcontiguous=8)
  localparam int CONTIGUOUS  = 8;   // 一个 L0/L1 cacheline 含 8 个连续 PTE（sector）
  localparam int LEVEL_W     = 2;   // level 0..3 需 2 位
  localparam int NAPOT_BITS  = 4;
  localparam int BLOCK_BITS  = 512; // blockBytes(64)*8 —— refill 一次带回 8 个 PTE
  localparam int HASH_ASID_W = 3;   // L0/L1 SRAM 内 asid/vmid 用异或折叠后存储
  localparam int HASH_VPN_W  = 6;   // L0 SRAM 内额外存的折叠 vpn 高位（sfence 加速）

  // sectorppnLen = ppnLen - sectortlbwidth：stage1 返回 entry 的 ppn 高位段
  localparam int SECTOR_PPN_W = PPN_W - SECTOR_W; // 33；但 stage1.entry.ppn 端口宽 41 = gvpn 段
  localparam int STAGE1_PPN_W = GVPN_W - SECTOR_W; // 35 -> golden 端口 41? 见下方说明
  localparam int PPN_LOW_W    = SECTOR_W;          // 3

  // 各级容量
  localparam int L3_SIZE  = 16;
  localparam int L2_SIZE  = 16;
  localparam int L1_SETS  = 8;
  localparam int L1_WAYS  = 2;
  localparam int L0_SETS  = 32;
  localparam int L0_WAYS  = 4;
  localparam int SP_SIZE  = 16;

  // tag 宽度（取自 PtwL*TagLen，EnableSv48 分支）
  localparam int L3_TAG_W = 11; // vpnnLen(9) + extendVpnnBits(2)
  localparam int L2_TAG_W = 20; // vpnnLen*2 + 2
  localparam int L1_TAG_W = 23; // vpnnLen*3 - PtwL1IdxLen(6) + 2
  localparam int L0_TAG_W = 30; // vpnnLen*4 - PtwL0IdxLen(8) + 2 = 36-8+2（SRAM tag 字段 30b）
  localparam int SP_TAG_W = 38; // vpnnLen*4 + 2

  // set / sector 索引位宽
  localparam int L1_SET_IDX_W = 3; // log2(8)
  localparam int L0_SET_IDX_W = 5; // log2(32)

  // s2xlate 编码
  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0, // 普通单级 satp
    ONLY_STAGE1 = 2'h1, // 仅 VS-stage
    ONLY_STAGE2 = 2'h2, // 仅 G-stage（输入 vpn 已是 gvpn）
    ALL_STAGE   = 2'h3  // VS + G
  } s2xlate_e;

  // sfence/hfence 类型（PtwEntry.hit 的 sfence 参数）
  localparam logic [1:0] NO_SFENCE = 2'h0;
  localparam logic [1:0] IS_SFENCE = 2'h1;
  localparam logic [1:0] IS_VSFENCE = 2'h2;
  localparam logic [1:0] IS_GSFENCE = 2'h3;

  // ---------------------------------------------------------------------------
  // 公共子 bundle
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic d, a, g, u, x, w, r;
  } ptw_perm_t;                       // PtePermBundle 去掉 v（v 单独存）

  // 进入 cache 的请求信息（L2TlbInnerBundle 的 cache 关心字段）
  typedef struct packed {
    logic [VPN_W-1:0] vpn;
    logic [1:0]       s2xlate;
    logic [1:0]       source;         // sourceWidth = PtwWidth+1 = 3 -> 2 位
  } req_info_t;

  // RISC-V Sv39/48 PTE 物理布局（与 PteBundle 等价，[63:0]）
  typedef struct packed {
    logic         n;          // [63]   svnapot
    logic [1:0]   pbmt;       // [62:61]
    logic [6:0]   reserved;   // [60:54]
    logic [7:0]   ppn_high;   // [53:46] 超出 ppnLen 的高位
    logic [PPN_W-1:0] ppn;    // [45:10]
    logic [1:0]   rsw;        // [9:8]
    logic         d, a, g, u, x, w, r, v; // [7:0]
  } pte_t;

  // sfence/hfence 输入 bits（dup0 完整）
  typedef struct packed {
    logic        valid;
    logic        rs1;       // 指定 va
    logic        rs2;       // 指定 asid
    logic [49:0] addr;
    logic [15:0] id;        // rs2 时的 asid / hfence-g 时的 vmid
    logic        hv;        // hfence.vvma
    logic        hg;        // hfence.gvma
  } sfence_bits_t;

  // ---------------------------------------------------------------------------
  // 全相联级（L3/L2）单条目：PtwEntry(hasPerm=false, hasLevel=false)
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [L2_TAG_W-1:0] tag;   // L3 只用低 11 位
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic [PBMT_W-1:0]   pbmt;
    logic [GVPN_W-1:0]   ppn;
    logic                prefetch;
    logic                v;
  } nonleaf_entry_t;            // L2 用全部，L3 复用结构但 tag 截 11 位

  // ---------------------------------------------------------------------------
  // 超级页 SP 条目：PtwEntry(hasPerm,hasLevel,hasNapot)，存 1G/2M/512G 叶子
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [SP_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic                n;       // napot
    logic [PBMT_W-1:0]   pbmt;
    logic [GVPN_W-1:0]   ppn;
    ptw_perm_t           perm;
    logic [LEVEL_W-1:0]  level;
    logic                prefetch;
    logic                v;
  } sp_entry_t;

  // ---------------------------------------------------------------------------
  // L1/L0 SRAM 的一“行”（一 way）：PtwEntries(num=8)。
  // l1 hasPerm=false（非叶），l0 hasPerm=true（叶，带 perm）。
  // vs：对 l1 是“有效位”，对 l0 是“page-fault 标记”（onlypf 时仍 vs=1）。
  // 注意：本配置 enablePTWECC=false，故 SRAM 行不含 ecc。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [L1_TAG_W-1:0]                 tag;
    logic [ASID_W-1:0]                   asid;
    logic [VMID_W-1:0]                   vmid;
    logic [CONTIGUOUS-1:0][PBMT_W-1:0]   pbmts;
    logic [CONTIGUOUS-1:0][GVPN_W-1:0]   ppns;
    logic [CONTIGUOUS-1:0]               vs;
    logic [CONTIGUOUS-1:0]               onlypf;
    logic                                prefetch;
  } l1_sram_entry_t;

  typedef struct packed {
    logic [L0_TAG_W-1:0]                 tag;
    logic [ASID_W-1:0]                   asid;
    logic [VMID_W-1:0]                   vmid;
    logic [CONTIGUOUS-1:0][PBMT_W-1:0]   pbmts;
    logic [CONTIGUOUS-1:0][GVPN_W-1:0]   ppns;
    logic [CONTIGUOUS-1:0]               vs;
    logic [CONTIGUOUS-1:0]               onlypf;
    logic [CONTIGUOUS-1:0]               perm_d, perm_a, perm_g, perm_u, perm_x, perm_w, perm_r;
    logic                                prefetch;
  } l0_sram_entry_t;

  // ---------------------------------------------------------------------------
  // 命中结果中间 bundle（PageCachePerPespBundle / PageCacheMergePespBundle 等价）
  // 各级命中后汇总到这里，再寄存成 resp_res 在 stageResp 用。
  // ---------------------------------------------------------------------------
  // 单级命中（L3/L2/L1/SP）：广播一个 ppn
  typedef struct packed {
    logic               hit;
    logic               pre;       // prefetch
    logic [GVPN_W-1:0]  ppn;
    logic [PBMT_W-1:0]  pbmt;
    ptw_perm_t          perm;      // 仅 SP 有意义
    logic               n;         // 仅 SP（napot）
    logic               ecc;       // 本配置恒 0
    logic [LEVEL_W-1:0] level;     // 仅 SP
    logic               v;
  } pc_per_t;

  // L0 行命中：8 个 sector 各有 ppn/pbmt/perm/v
  typedef struct packed {
    logic                              hit;
    logic                              pre;
    logic [CONTIGUOUS-1:0][GVPN_W-1:0] ppn;
    logic [CONTIGUOUS-1:0][PBMT_W-1:0] pbmt;
    ptw_perm_t [CONTIGUOUS-1:0]        perm;
    logic                              ecc;
    logic [LEVEL_W-1:0]                level;
    logic [CONTIGUOUS-1:0]             v;
  } pc_merge_t;

  typedef struct packed {
    pc_per_t   l3;
    pc_per_t   l2;
    pc_per_t   l1;
    pc_merge_t l0;
    pc_per_t   sp;
  } pagecache_resp_t;

  // ---------------------------------------------------------------------------
  // 一个 stage1 sector entry（PtwMergeEntry）—— resp 回 TLB 的 8 项之一
  // ---------------------------------------------------------------------------
  localparam int S1_TAG_W     = 35; // sectorvpnLen = vpnLen-3
  localparam int S1_PPN_W     = 41; // sectorptePPNLen = ptePPNLen-3
  localparam int TOHPTW_PPN_W = 36; // ppnLen
  localparam int TOFSM_PPN_W  = 38; // gvpnLen

  typedef struct packed {
    logic [S1_TAG_W-1:0] tag;
    logic [ASID_W-1:0]   asid;
    logic [VMID_W-1:0]   vmid;
    logic                n;
    logic [PBMT_W-1:0]   pbmt;
    ptw_perm_t           perm;
    logic [LEVEL_W-1:0]  level;
    logic                v;
    logic [S1_PPN_W-1:0] ppn;
    logic [SECTOR_W-1:0] ppn_low;
    logic                pf;
  } s1_entry_t;

  // toHptw.resp.entry（HptwResp 的 entry，ppn=ppnLen=36）
  typedef struct packed {
    logic [VPN_W-1:0]    tag;
    logic [VMID_W-1:0]   vmid;
    logic                n;
    logic [PBMT_W-1:0]   pbmt;
    logic [TOHPTW_PPN_W-1:0] ppn;
    ptw_perm_t           perm;
    logic [LEVEL_W-1:0]  level;
  } hptw_entry_t;

  // 完整 resp 输出 bundle（wrapper 扁平化到 io_resp_bits_*）
  typedef struct packed {
    req_info_t  req_info;
    logic       isFirst;
    logic       hit;
    logic       prefetch;
    logic       bypassed;
    // toFsm
    logic       toFsm_l3Hit, toFsm_l2Hit, toFsm_l1Hit;
    logic [TOFSM_PPN_W-1:0] toFsm_ppn;
    logic       toFsm_stage1Hit;
    // stage1：8 个 sector entry + pteidx + not_super
    s1_entry_t [CONTIGUOUS-1:0] stage1_entry;
    logic [CONTIGUOUS-1:0]      stage1_pteidx;
    logic                       stage1_not_super;
    // hptw
    logic       isHptwReq;
    logic       toHptw_l3Hit, toHptw_l2Hit, toHptw_l1Hit;
    logic [TOHPTW_PPN_W-1:0] toHptw_ppn;
    logic [2:0] toHptw_id;
    hptw_entry_t toHptw_entry;
    logic       toHptw_gpf;
    logic       toHptw_bypassed;
  } ptwcache_resp_t;

  // ===========================================================================
  // 索引/分段纯函数（genPtwL*SetIdx / getVpnn 等）
  // ===========================================================================
  // 单级 VPN 段：vpn[9*(idx+1)-1 : 9*idx]
  function automatic logic [VPNN_W-1:0] get_vpnn(input logic [VPN_W-1:0] vpn, input int idx);
    return vpn[VPNN_W*idx +: VPNN_W];
  endfunction

  // L1：vpn(vpnLen-1,vpnnLen)=vpn[37:9]，取低 6 位为 idx，高 3 位为 setIdx，低 3 位为 sectorIdx
  function automatic logic [L1_SET_IDX_W-1:0] l1_set_idx(input logic [VPN_W-1:0] vpn);
    return vpn[VPNN_W + SECTOR_W +: L1_SET_IDX_W]; // vpn[14:12]
  endfunction
  function automatic logic [SECTOR_W-1:0] l1_sector_idx(input logic [VPN_W-1:0] vpn);
    return vpn[VPNN_W +: SECTOR_W];                // vpn[11:9]
  endfunction
  // L1 tag = vpn[vpnLen-1 : vpnLen-tagLen] = vpn[37:15]
  function automatic logic [L1_TAG_W-1:0] l1_tag_clip(input logic [VPN_W-1:0] vpn);
    return vpn[VPN_W-1 -: L1_TAG_W];
  endfunction

  // L0：vpn[7:0] 为 idx，高 5 位 setIdx，低 3 位 sectorIdx
  function automatic logic [L0_SET_IDX_W-1:0] l0_set_idx(input logic [VPN_W-1:0] vpn);
    return vpn[SECTOR_W +: L0_SET_IDX_W];          // vpn[7:3]
  endfunction
  function automatic logic [SECTOR_W-1:0] l0_sector_idx(input logic [VPN_W-1:0] vpn);
    return vpn[0 +: SECTOR_W];                     // vpn[2:0]
  endfunction
  function automatic logic [L0_TAG_W-1:0] l0_tag_clip(input logic [VPN_W-1:0] vpn);
    return vpn[VPN_W-1 -: L0_TAG_W];
  endfunction

  // ===========================================================================
  // hit 比较（PtwEntry.hit / PtwEntries.hit / SP allType hit）
  // ===========================================================================
  // s2xlate -> 比较时的 h（allStage 折算成 onlyStage1，其它原样），见 change_h。
  function automatic logic [1:0] change_h(input logic [1:0] s2x);
    case (s2x)
      ALL_STAGE:   return ONLY_STAGE1;
      ONLY_STAGE1: return ONLY_STAGE1;
      ONLY_STAGE2: return ONLY_STAGE2;
      default:     return NO_S2XLATE;
    endcase
  endfunction

  // 非叶级（L3/L2）的 asid/vmid 命中（PtwEntry.hit, allType=false）。
  //   tag_hit 由调用者用各级常量 tag 宽度算好传入（SV 函数不能用变量做 part-select），
  //   need_asid_check：非 onlyStage2 时检查 asid（L3/L2 无 perm，is_global 恒 0）
  //   need_vmid_check：有 s2xlate 时检查 vmid
  function automatic logic nonleaf_hit(
    input logic                tag_hit,
    input logic [ASID_W-1:0]   easid,
    input logic [VMID_W-1:0]   evmid,
    input logic [ASID_W-1:0]   satp_asid,
    input logic [ASID_W-1:0]   vsatp_asid,
    input logic [VMID_W-1:0]   hgatp_vmid,
    input logic [1:0]          h           // change_h 后的 s2xlate
  );
    logic [ASID_W-1:0] asid_value;
    logic asid_hit, vmid_hit;
    asid_value = (h != NO_S2XLATE) ? vsatp_asid : satp_asid;
    asid_hit   = (h == ONLY_STAGE2) ? 1'b1 : (easid == asid_value);
    vmid_hit   = (h != NO_S2XLATE) ? (evmid == hgatp_vmid) : 1'b1;
    return asid_hit && vmid_hit && tag_hit;
  endfunction

  // L1/L0 SRAM 行命中（PtwEntries.hit）。is_global 仅 l0（有 perm，看该 sector 的 g）。
  // tag_hit/evs 由调用者用常量宽度算好。
  function automatic logic sram_hit(
    input logic                tag_hit,
    input logic [ASID_W-1:0]   easid,
    input logic [VMID_W-1:0]   evmid,
    input logic                evs,       // 该 sector 的 vs
    input logic                is_global,
    input logic [ASID_W-1:0]   satp_asid,
    input logic [ASID_W-1:0]   vsatp_asid,
    input logic [VMID_W-1:0]   hgatp_vmid,
    input logic [1:0]          h
  );
    logic [ASID_W-1:0] asid_value;
    logic asid_hit, vmid_hit;
    asid_value = (h != NO_S2XLATE) ? vsatp_asid : satp_asid;
    asid_hit   = (h == ONLY_STAGE2) ? 1'b1 : ((easid == asid_value) || is_global);
    vmid_hit   = (h != NO_S2XLATE) ? (evmid == hgatp_vmid) : 1'b1;
    return asid_hit && vmid_hit && tag_hit && evs;
  endfunction

  // 异或折叠（XORFold）：把 inW 位宽折叠到 outW 位。L0/L1 SRAM 的 asid/vmid/vpn
  // 用折叠后窄值存储以省面积；sfence 比对也用折叠值。
  // XORFold(input, resW)：先零扩展到 resW 的整数倍（ceil(inW/resW) 段），再逐段异或。
  // asid 16b → 3b：6 段（零扩展到 18b）。
  function automatic logic [HASH_ASID_W-1:0] xorfold_asid(input logic [ASID_W-1:0] x);
    logic [HASH_ASID_W*6-1:0] xe; // 18 位
    logic [HASH_ASID_W-1:0] r;
    integer i;
    xe = {2'b00, x};
    r  = '0;
    for (i = 0; i < 6; i = i + 1)
      r = r ^ xe[i*HASH_ASID_W +: HASH_ASID_W];
    return r;
  endfunction

  // vpn 折叠：输入 30b（L0_TAG_W）→ 6b：5 段（30=5*6，无需补零）。
  function automatic logic [HASH_VPN_W-1:0] xorfold_vpn(input logic [L0_TAG_W-1:0] x);
    logic [HASH_VPN_W-1:0] r;
    integer i;
    r = '0;
    for (i = 0; i < L0_TAG_W/HASH_VPN_W; i = i + 1)
      r = r ^ x[i*HASH_VPN_W +: HASH_VPN_W];
    return r;
  endfunction

  // ===========================================================================
  // PTE 解析（refill 时判断 leaf/可填/svnapot/onlyPf）—— 来自 PteBundle
  // ===========================================================================
  function automatic logic pte_is_leaf(input pte_t pte);
    return pte.v && (pte.r || pte.w || pte.x);
  endfunction
  // isNapot(level) = isLeaf() && n   （注意：与 level 无关，level 参数仅为与 Scala 签名对齐）
  function automatic logic pte_is_napot(input pte_t pte, input logic [1:0] level);
    return pte_is_leaf(pte) && pte.n;
  endfunction
  // getPPN 取 gvpnLen(38) 位：PPN_W=36，高位用 ppn_high 的低 2 位补齐。
  function automatic logic [GVPN_W-1:0] pte_get_ppn(input pte_t pte);
    return {pte.ppn_high[1:0], pte.ppn};
  endfunction

  // canRefill：合法可缓存（非保留位错、PBMT 合法、对齐）。简化自 PteBundle.canRefill，
  // 实际命中正确性主要靠 UT 逐拍比对 golden 背书；此处给出结构化判据。
  // OHToUInt(16)：FIRRTL 对多热输入是各命中下标按位 OR，不是 priority encoder。
  function automatic logic [3:0] oh16_to_idx(input logic [15:0] oh);
    logic [3:0] r;
    integer i;
    r = '0;
    for (i = 0; i < 16; i = i + 1) if (oh[i]) r |= i[3:0];
    return r;
  endfunction

  // SP allType hit：按 level 比较 vpn 的若干段；napot 时第 0 段只比高位。
  // 复刻 PtwEntry.hit(allType=true)：asid/vmid 检查同 nonleaf，level_match 由 tag 各段决定。
  function automatic logic sp_alltype_hit(
    input sp_entry_t      e,
    input logic [VPN_W-1:0] vpn,
    input logic [ASID_W-1:0] satp_asid,
    input logic [ASID_W-1:0] vsatp_asid,
    input logic [VMID_W-1:0] hgatp_vmid,
    input logic [1:0]     h
  );
    logic [ASID_W-1:0] asid_value;
    logic asid_hit, vmid_hit, is_global;
    logic [3:0] tag_match;       // 512G/1G/2M/4K(含napot) 四段
    logic level_match;
    is_global  = e.perm.g;
    asid_value = (h != NO_S2XLATE) ? vsatp_asid : satp_asid;
    asid_hit   = (h == ONLY_STAGE2) ? 1'b1 : ((e.asid == asid_value) || is_global);
    vmid_hit   = (h != NO_S2XLATE) ? (e.vmid == hgatp_vmid) : 1'b1;
    // tag_match(0)：napot 时 tag[8:napotBits]==vpn[8:napotBits]，否则 tag[8:0]==vpn[8:0]
    if (e.n)
      tag_match[0] = (e.tag[VPNN_W-1:NAPOT_BITS] == vpn[VPNN_W-1:NAPOT_BITS]);
    else
      tag_match[0] = (e.tag[VPNN_W-1:0] == vpn[VPNN_W-1:0]);
    tag_match[1] = (e.tag[VPNN_W*2-1 -: VPNN_W] == vpn[VPNN_W*2-1 -: VPNN_W]);
    tag_match[2] = (e.tag[VPNN_W*3-1 -: VPNN_W] == vpn[VPNN_W*3-1 -: VPNN_W]);
    // tag(tagLen-1, vpnnLen*3) == vpn(tagLen-1, vpnnLen*3)；SP_TAG_W=38, vpnnLen*3=27 → 11 位
    tag_match[3] = (e.tag[SP_TAG_W-1 : VPNN_W*3] == vpn[SP_TAG_W-1 : VPNN_W*3]);
    case (e.level)
      2'h3:    level_match = tag_match[3];
      2'h2:    level_match = tag_match[3] && tag_match[2];
      2'h1:    level_match = tag_match[3] && tag_match[2] && tag_match[1];
      2'h0:    level_match = tag_match[3] && tag_match[2] && tag_match[1] && tag_match[0];
      default: level_match = 1'b0;
    endcase
    return asid_hit && vmid_hit && level_match;
  endfunction

  // SP 命中（sfence 变体）：allType=true，带 sfence 类型与 ignoreID（PtwEntry.hit）。
  //   sfence: isSfence/isVSfence/isGSfence 决定 not_virt/onlyS* 语义；ignoreID 忽略 asid(/vmid)。
  function automatic logic sp_sfence_hit(
    input sp_entry_t      e,
    input logic [VPN_W-1:0] vpn,
    input logic [ASID_W-1:0] asid_in,   // sfence id（asid 或 vmid 复用）
    input logic [VMID_W-1:0] vmid_in,
    input logic [1:0]     sfence,
    input logic           ignoreID
  );
    logic not_sfence, sfv, hfv, hfg, not_virt, is_global;
    logic ignoreAsid, ignoreVmid, need_asid_check, need_vmid_check;
    logic [ASID_W-1:0] asid_value;
    logic asid_hit, vmid_hit;
    logic [3:0] tag_match; logic level_match;
    not_sfence = (sfence == NO_SFENCE);
    sfv = (sfence == IS_SFENCE);
    hfv = (sfence == IS_VSFENCE);
    hfg = (sfence == IS_GSFENCE);
    not_virt   = sfv;   // sfence 路径恒带 sfence!=noSfence；这里 s2xlate 不参与（调用方只用于 va 指定）
    ignoreAsid = ignoreID;
    ignoreVmid = ignoreID && hfg;
    need_asid_check = !ignoreAsid && !hfg;     // onlyS2 不出现于 sfence 路径
    need_vmid_check = !ignoreVmid && !not_virt && !sfv;
    is_global  = e.perm.g;
    asid_value = not_virt ? asid_in : asid_in;  // sfence 路径 asid/vasid 同传 id
    asid_hit   = need_asid_check ? ((e.asid == asid_value) || is_global) : 1'b1;
    vmid_hit   = need_vmid_check ? (e.vmid == vmid_in) : 1'b1;
    if (e.n)
      tag_match[0] = (e.tag[VPNN_W-1:NAPOT_BITS] == vpn[VPNN_W-1:NAPOT_BITS]);
    else
      tag_match[0] = (e.tag[VPNN_W-1:0] == vpn[VPNN_W-1:0]);
    tag_match[1] = (e.tag[VPNN_W*2-1 -: VPNN_W] == vpn[VPNN_W*2-1 -: VPNN_W]);
    tag_match[2] = (e.tag[VPNN_W*3-1 -: VPNN_W] == vpn[VPNN_W*3-1 -: VPNN_W]);
    tag_match[3] = (e.tag[SP_TAG_W-1 : VPNN_W*3] == vpn[SP_TAG_W-1 : VPNN_W*3]);
    case (e.level)
      2'h3:    level_match = tag_match[3];
      2'h2:    level_match = tag_match[3] && tag_match[2];
      2'h1:    level_match = tag_match[3] && tag_match[2] && tag_match[1];
      2'h0:    level_match = tag_match[3] && tag_match[2] && tag_match[1] && tag_match[0];
      default: level_match = 1'b0;
    endcase
    return asid_hit && vmid_hit && level_match;
  endfunction

  // ===========================================================================
  // 二叉树 PLRU（utility.ReplacementPolicy tree-plru）—— L3/L2/SP 用 16 路树，
  // L1 用 2 路树（1 bit），L0 用 4 路树（3 bit）。每路 N 的树有 N-1 个节点状态位。
  // 编码：state 高位是 root，root=1 指向「左子树更近被用→victim 走右」语义由 way()/access()
  //   一致维护。本工程直接复刻 golden firtool 形态：
  //     way():  从 root 往下走，node? 取右子树 : 取左子树，逐位拼出 victim way。
  //     access(touch): 把命中路径上各节点写成「指向另一侧」（~方向），其余节点保持。
  // ---------------------------------------------------------------------------
  // 16 路树（15 bit state）求 victim way。布局与 golden 完全一致：
  //   way = {s[14], s[14]? {s[13],...} : {s[6],...}}
  function automatic logic [3:0] plru16_way(input logic [14:0] s);
    return {s[14],
            s[14] ? {s[13], s[13] ? {s[12], s[12] ? s[11] : s[10]}
                                  : {s[9],  s[9]  ? s[8]  : s[7]}}
                  : {s[6],  s[6]  ? {s[5],  s[5]  ? s[4]  : s[3]}
                                  : {s[2],  s[2]  ? s[1]  : s[0]}}};
  endfunction

  // 16 路树 access：命中 way=t 时把路径上 4 个节点改写为指向「另一侧」。
  // 路径节点索引（自 root）：root=14；level1=t[3]?13:6；level2 在该子树内；level3 叶节点。
  // 直接按 golden 的嵌套三元展开（与 spRefill 形态同构，t 即 touched way）。
  function automatic logic [14:0] plru16_access(input logic [14:0] s, input logic [3:0] t);
    return {~t[3],
            t[3] ? {~t[2],
                    t[2] ? {~t[1], t[1] ? ~t[0] : s[11], t[1] ? s[10] : ~t[0]}
                         : s[12:10],
                    t[2] ? s[9:7]
                         : {~t[1], t[1] ? ~t[0] : s[8],  t[1] ? s[7]  : ~t[0]}}
                 : s[13:7],
            t[3] ? s[6:0]
                 : {~t[2],
                    t[2] ? {~t[1], t[1] ? ~t[0] : s[4],  t[1] ? s[3]  : ~t[0]}
                         : s[5:3],
                    t[2] ? s[2:0]
                         : {~t[1], t[1] ? ~t[0] : s[1],  t[1] ? s[0]  : ~t[0]}}};
  endfunction

  // 4 路树（3 bit state）：s[2]=root，s[1]=左子树节点，s[0]=右子树节点（L0 per-set）。
  function automatic logic [1:0] plru4_way(input logic [2:0] s);
    return {s[2], s[2] ? s[1] : s[0]};
  endfunction
  function automatic logic [2:0] plru4_access(input logic [2:0] s, input logic [1:0] t);
    return {~t[1],
            t[1] ? ~t[0] : s[1],
            t[1] ? s[0]  : ~t[0]};
  endfunction

  // 2 路树（1 bit state）：L1 per-set。way=s；access(touch)=~touch。
  function automatic logic plru2_way(input logic s);
    return s;
  endfunction
  function automatic logic plru2_access(input logic t);
    return ~t;
  endfunction

  // replaceWrapper：全相联 16 项「先空位后 PLRU」victim 选择。
  //   有 !v 的位则优先返回最低空位下标（ParallelPriorityEncoder 形态），全满才用 plruWay。
  function automatic logic [3:0] replace16(input logic [15:0] v, input logic [3:0] plru_way);
    logic [3:0] idx;
    integer i;
    idx = plru_way;
    if (!(&v)) begin
      idx = 4'hF;
      for (i = 15; i >= 0; i = i - 1)
        if (!v[i]) idx = i[3:0];
    end
    return idx;
  endfunction

  // L1 per-set（2 way）：先空位后 PLRU。
  function automatic logic replace2(input logic [1:0] v, input logic plru_way);
    if (!v[0]) return 1'b0;
    else if (!v[1]) return 1'b1;
    else return plru_way;
  endfunction

  // L0 per-set（4 way）：先空位后 PLRU。
  function automatic logic [1:0] replace4(input logic [3:0] v, input logic [1:0] plru_way);
    logic [1:0] idx;
    integer i;
    idx = plru_way;
    if (!(&v)) begin
      idx = 2'h3;
      for (i = 3; i >= 0; i = i - 1)
        if (!v[i]) idx = i[1:0];
    end
    return idx;
  endfunction

  // ---------------------------------------------------------------------------
  // 以下 PTE 合法性判据严格复刻 Chisel PteBundle（MMUBundle.scala）：
  //   isNext / unaligned / isPf / isGpf / isAf / isStage1Gpf，
  // canRefill/onlyPf 再由它们组合。早期版本的 canRefill 用单一 illegal 公式，
  // 漏掉了 isPf 的 isNext 分支（非叶项 v=1&&!(r|w|x) 时若 a/d/u/n/pbmt 任一置位即 page-fault），
  // 导致 L3/L2/L1 非叶项 canRefill 与 golden 分叉（l3v seed1 偏差根因）。
  // ---------------------------------------------------------------------------
  // isNext：非叶编码（v 且 r/w/x 全 0）
  function automatic logic pte_is_next(input pte_t pte);
    return ~(pte.r || pte.w || pte.x) && pte.v;
  endfunction
  // unaligned(level)：叶子但 ppn 低位未按 level 对齐（vpnnLen=9）
  function automatic logic pte_unaligned(input pte_t pte, input logic [1:0] level);
    return pte_is_leaf(pte) &&
      !(level == 2'h0 ||
        (level == 2'h1 && pte.ppn[8:0]  == 9'h0) ||
        (level == 2'h2 && pte.ppn[17:0] == 18'h0) ||
        (level == 2'h3 && pte.ppn[26:0] == 27'h0));
  endfunction
  // isPf：S1 page-fault（Scala isPf）
  function automatic logic pte_is_pf(input pte_t pte, input logic [1:0] level, input logic pbmte);
    if (pte.reserved != 7'h0)                               return 1'b1;
    else if (pte.pbmt == 2'h3 || (!pbmte && pte.pbmt != 2'h0)) return 1'b1;
    else if (pte_is_next(pte))
      return (pte.u || pte.a || pte.d || pte.n || (pte.pbmt != 2'h0));
    else if (!pte.v || (!pte.r && pte.w))                   return 1'b1;
    else if (pte.n && (pte.ppn[3:0] != 4'h8 || level != 2'h0)) return 1'b1;
    else                                                    return pte_unaligned(pte, level);
  endfunction
  // isGpf：G-stage page-fault（Scala isGpf）—— 比 isPf 多 u/a 检查（LOAD 语义）
  function automatic logic pte_is_gpf(input pte_t pte, input logic [1:0] level, input logic pbmte);
    if (pte.reserved != 7'h0)                               return 1'b1;
    else if (pte.pbmt == 2'h3 || (!pbmte && pte.pbmt != 2'h0)) return 1'b1;
    else if (pte_is_next(pte))
      return (pte.u || pte.a || pte.d || pte.n || (pte.pbmt != 2'h0));
    else if (!pte.v || (!pte.r && pte.w))                   return 1'b1;
    else if (!pte.u)                                        return 1'b1;
    else if (pte.n && pte.ppn[3:0] != 4'h8)                 return 1'b1;
    else if (pte_unaligned(pte, level))                     return 1'b1;
    else if (!pte.a)                                        return 1'b1;
    else                                                    return 1'b0;
  endfunction
  // isAf：ppn 超出 ppnLen（access fault）
  function automatic logic pte_is_af(input pte_t pte);
    return (|pte.ppn_high) && pte.v;
  endfunction
  // isStage1Gpf(mode)：allStage 下 S1 ppn 高位超出 GPAddr 范围
  //   Cat(ppn_high,ppn) 对应 PTE[53:10]；Sv39 >>29 取 [53:39]，Sv48 >>38 取 [53:48]
  function automatic logic pte_is_stage1_gpf(input pte_t pte, input logic [3:0] mode);
    logic hi;
    unique case (mode)
      4'h8:    hi = |{pte.ppn_high, pte.ppn[35:29]};  // Sv39
      4'h9:    hi = |pte.ppn_high[7:2];               // Sv48
      default: hi = 1'b0;
    endcase
    return hi && pte.v;
  endfunction

  // canRefill：Scala PteBundle.canRefill —— 按 s2xlate 选 isPf/isGpf/isAf/isStage1Gpf 组合
  function automatic logic pte_can_refill(
    input pte_t pte, input logic [1:0] level, input logic [1:0] s2xlate, input logic pbmte, input logic [3:0] mode
  );
    unique case (s2xlate)
      ALL_STAGE:    return ~pte_is_stage1_gpf(pte, mode) && ~pte_is_pf(pte, level, pbmte);
      ONLY_STAGE1:  return ~pte_is_af(pte) && ~pte_is_pf(pte, level, pbmte);
      ONLY_STAGE2:  return ~pte_is_af(pte) && ~pte_is_gpf(pte, level, pbmte);
      default:      return ~pte_is_af(pte) && ~pte_is_pf(pte, level, pbmte);  // NO_S2XLATE
    endcase
  endfunction

  // onlyPf：Scala PteBundle.onlyPf —— noS2xlate && isPf && !isAf
  function automatic logic pte_only_pf(
    input pte_t pte, input logic [1:0] level, input logic [1:0] s2xlate, input logic pbmte
  );
    return (s2xlate == NO_S2XLATE) && pte_is_pf(pte, level, pbmte) && ~pte_is_af(pte);
  endfunction

endpackage
