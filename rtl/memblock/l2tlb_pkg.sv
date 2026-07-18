// ============================================================================
// l2tlb_pkg —— L2TLB 顶层（共享 MMU 总集成）的公共类型 / 参数 / 纯函数
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/cache/mmu/L2TLB.scala（class L2TLBImp）
//
// L2TLB 把 PTW / LLPTW / HPTW / PtwCache / L2TlbMissQueue / L2TlbPrefetch / PMP /
// 多个 Arbiter / DelayN / BlockHelper 组装成完整的页表遍历器。本层是仲裁 / 路由 /
// 分发 / 访存数据通路的 glue，遍历算法在各子模块内（对本层是 golden 黑盒）。
//
// 本 pkg 复用 xs_ptw_pkg 里的 PTE / merge-resp / sector / hptw 等类型与 fault 纯函数
// （PTW/HPTW/LLPTW 已用同一套定义），只补充 L2TLB 顶层 glue 专属的：
//   * 配置参数（MemReqWidth/llptwsize/PtwWidth 等，由本配置 firtool 展开确定）；
//   * CSR / sfence 复制结构（DelayN+RegNext 复制扇出）；
//   * sector PtwResp 结构（顶层输出给 ITLB/DTLB）；
//   * 访存数据通路用的小函数（get_part / sel_data / addr_low_*）；
//   * 两个核心组合变换函数：
//       contiguous_pte_to_merge_ptwResp —— 8 个连续 PTE → PtwMergeResp（LLPTW 出口）
//       merge_ptwResp_to_sector_ptwResp —— PtwMergeResp → PtwSectorResp（顶层出口）
// ============================================================================
package l2tlb_pkg;
  import xs_ptw_pkg::*;   // 复用 pte_t / pte_perm_t / ptw_perm_t / ptw_merge_*_t /
                          // hptw_resp_t / ptw_req_info_t 及 pte_is_leaf/pte_page_fault/...

  // ---- 配置参数（HasBitmapCheck=false, enablePrefetch=true, HasHExtension=true,
  //      EnableSv48=true；由 golden L2TLB.sv 的 firtool 展开确定）----
  localparam int PTW_WIDTH      = 2;   // ITLB(0) / DTLB(1)
  localparam int LLPTW_SIZE     = 6;   // LLPTW 表项数（mem id 0..5）
  localparam int MEM_REQ_WIDTH  = 8;   // 访存源 id 路数：LLPTW(0..5)+PTW(6)+HPTW(7)
  localparam int PTW_MEM_ID      = 6;  // PTW   占用的 mem 源 id
  localparam int HPTW_MEM_ID     = 7;  // HPTW  占用的 mem 源 id
  localparam int L1_BUS_DATA_W  = 256; // 一拍总线数据宽（TileLink beat）
  localparam int BLOCK_BITS     = 512; // 一次访存取回的 PTE 块（2 beat）
  localparam int BEATS          = BLOCK_BITS / L1_BUS_DATA_W; // 2
  localparam int CONTIG         = CONTIGUOUS;  // 8（sector 连续 PTE 数）
  localparam int PERF_NUM       = 19; // io_perf_0..18

  // mem 源 id 宽度
  localparam int MEM_ID_W       = $clog2(MEM_REQ_WIDTH); // 3

  // arb2（page cache 入口仲裁）输入端口编号（与 Scala 一致）
  localparam int IN_ARB_HPTW    = 0;
  localparam int IN_ARB_PTW     = 1;
  localparam int IN_ARB_MQ      = 2;
  localparam int IN_ARB_TLB     = 3;
  localparam int IN_ARB_PREF    = 4;

  // mergeArb（每条 PtwWidth）输入端口编号
  localparam int OUT_ARB_CACHE  = 0;
  localparam int OUT_ARB_FSM    = 1;
  localparam int OUT_ARB_MQ     = 2;

  localparam int FSM_REQ_ID     = LLPTW_SIZE; // hptw resp 给 PTW 的 id（= llptwsize）

  // ==========================================================================
  // CSR / sfence 复制（DelayN 1 拍后再 RegNext 一拍，得到 csr_dup / sfence_dup）。
  // 用 struct 表达单份 CSR / sfence，复制只是多份同值寄存器（降低长扇出）。
  // ==========================================================================
  typedef struct packed {
    logic [3:0]  satp_mode;
    logic [15:0] satp_asid;
    logic [43:0] satp_ppn;
    logic        satp_changed;
    logic [3:0]  vsatp_mode;
    logic [15:0] vsatp_asid;
    logic [43:0] vsatp_ppn;
    logic        vsatp_changed;
    logic [3:0]  hgatp_mode;
    logic [15:0] hgatp_vmid;
    logic [43:0] hgatp_ppn;
    logic        hgatp_changed;
    logic        priv_mxr;
    logic        priv_virt;
    logic        mPBMTE;
    logic        hPBMTE;
  } l2tlb_csr_t;

  typedef struct packed {
    logic        valid;
    logic        rs1;
    logic        rs2;
    logic [49:0] addr;
    logic [15:0] id;
    logic        hv;
    logic        hg;
  } l2tlb_sfence_t;

  // ==========================================================================
  // 顶层输出给 ITLB/DTLB 的 sector PtwResp（PtwSectorResp）。
  // ==========================================================================
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
  } sector_entry_t;

  typedef struct packed {
    sector_entry_t            entry;
    logic [SECTOR_BITS-1:0]   addr_low;
    logic [CONTIG-1:0][SECTOR_BITS-1:0] ppn_low;
    logic [CONTIG-1:0]        valididx;
    logic [CONTIG-1:0]        pteidx;
    logic                     pf;
    logic                     af;
  } sector_resp_t;

  // ==========================================================================
  // 访存数据通路小函数
  // ==========================================================================
  // 一次访存取回的 512bit 块切成 8 个 64bit PTE，取第 index 个。
  function automatic logic [63:0] get_part(input logic [BLOCK_BITS-1:0] data,
                                           input logic [2:0] index);
    return data[index*64 +: 64];
  endfunction

  // 由 vpn 低位算出该请求在 512bit 块里的 PTE 下标（addr_low）。
  function automatic logic [2:0] addr_low_from_vpn(input logic [VPN_W-1:0] vpn);
    return vpn[2:0];
  endfunction
  // 由物理地址算出 addr_low（块内 64bit 粒度偏移）。
  function automatic logic [2:0] addr_low_from_paddr(input logic [47:0] paddr);
    return paddr[5:3];
  endfunction

  // ==========================================================================
  // OHToUInt：把 one-hot pteidx 译码为下标（保留 Chisel 的 OR-归约语义，
  // 输入非 one-hot 时也确定，避免 FM 无约束下的假 failing）。
  // ==========================================================================
  function automatic logic [2:0] oh_to_uint8(input logic [7:0] oh);
    logic [2:0] r;
    r[0] = oh[1] | oh[3] | oh[5] | oh[7];
    r[1] = oh[2] | oh[3] | oh[6] | oh[7];
    r[2] = oh[4] | oh[5] | oh[6] | oh[7];
    return r;
  endfunction

  // ==========================================================================
  // contiguous_pte_to_merge_ptwResp（Scala L2TLB.scala:688）
  // 把 8 个连续 64bit PTE（一次访存取回的 sector）合成一个 PtwMergeResp（LLPTW 出口）。
  // af_first 固定为 true（顶层调用处），not_super 固定为 true。
  //   - pf 规则：!af && isPf，isPf = pte_page_fault || !isLeaf；
  //   - af 规则：af || (isAf && (s2xlate∈{noS2,onlyS1}) && !isPf)，且 af_first ⇒ 优先 af；
  //   - v = !pf；asid 取 vsatp/satp；vmid 取 hgatp.vmid；tag = vpn 高位。
  //   - not_super：napot（取 vpn 选中条目的 n）取反与 not_super 相与。
  //   - not_merge = (s2xlate != noS2xlate)。
  // ==========================================================================
  function automatic ptw_merge_resp_t contiguous_pte_to_merge(
    input logic [BLOCK_BITS-1:0] pte_blk,
    input logic [VPN_W-1:0]      vpn,
    input logic                  af,
    input logic [1:0]            s2xlate,
    input logic                  mPBMTE,
    input logic                  hPBMTE,
    input logic [15:0]           satp_asid,
    input logic [15:0]           vsatp_asid,
    input logic [VMID_W-1:0]     hgatp_vmid
  );
    ptw_merge_resp_t r;
    logic            has_s2;
    logic            pbmte;
    pte_t            pte_in;
    logic            is_pf, is_af;
    ptw_merge_entry_t e;
    logic [2:0]      sel;
    logic [PTE_PPN_W-1:0] full_ppn;  // pte_ppn 结果暂存（FM 不接受对函数调用直接位选）
    has_s2 = (s2xlate != NO_S2XLATE);
    // pbmte：onlyStage1 或 allStage 用 hPBMTE，否则 mPBMTE
    pbmte  = (s2xlate == ONLY_STAGE1 || s2xlate == ALL_STAGE) ? hPBMTE : mPBMTE;
    for (int i = 0; i < CONTIG; i++) begin
      pte_in = pte_t'(pte_blk[i*64 +: 64]);
      // isPf = pte_page_fault(level=0) || !isLeaf
      is_pf = pte_page_fault(pte_in, 2'h0, pbmte) || !pte_is_leaf(pte_in);
      // isAf = pte.isAf && (noS2||onlyS1) && !isPf
      is_af = pte_access_fault(pte_in)
              && (s2xlate == NO_S2XLATE || s2xlate == ONLY_STAGE1) && !is_pf;
      e = '0;
      full_ppn  = pte_ppn(pte_in);
      e.ppn     = full_ppn[PTE_PPN_W-1:SECTOR_BITS]; // ppn(ptePPNLen-1, sectortlbwidth)
      e.ppn_low = full_ppn[SECTOR_BITS-1:0];
      e.level   = 2'h0;
      e.pbmt    = pte_in.pbmt;
      e.n       = pte_in.n;
      e.perm    = '{d:pte_in.perm.d, a:pte_in.perm.a, g:pte_in.perm.g,
                    u:pte_in.perm.u, x:pte_in.perm.x, w:pte_in.perm.w, r:pte_in.perm.r};
      e.tag     = vpn[VPN_W-1:SECTOR_BITS];
      e.pf      = (~af) & is_pf;          // af_first=true ⇒ pf = !af && isPf
      e.af      = (af | is_af);           // af_first=true ⇒ af = true && (af||isAf)
      e.v       = ~e.pf;
      e.asid    = has_s2 ? vsatp_asid : satp_asid;
      e.vmid    = hgatp_vmid;
      r.entry[i] = e;
    end
    // pteidx = UIntToOH(vpn[2:0])
    sel = vpn[SECTOR_BITS-1:0];
    r.pteidx = (8'h1 << sel);
    // not_super = true && !napot；napot = entry[sel].n
    r.not_super = ~r.entry[sel].n;
    return r;
  endfunction

  // ==========================================================================
  // merge_ptwResp_to_sector_ptwResp（Scala L2TLB.scala:726）
  // 把 PtwMergeResp（8 条目 + pteidx one-hot）压成 PtwSectorResp（顶层输出）。
  // 选中条目 sel = OHToUInt(pteidx)；valididx[i] 表示第 i 条目与选中条目是否“同段”
  // （ppn/pbmt/perm/v/af/pf 全等 或 是 super page）且 not_merge 为假。
  // 入参 not_merge 来自 merge_resp 的 not_merge（这里用 s2xlate!=noS2 单独传入）。
  // ==========================================================================
  function automatic sector_resp_t merge_to_sector(
    input ptw_merge_resp_t mr,
    input logic            not_merge
  );
    sector_resp_t s;
    logic [2:0]   sel;
    ptw_merge_entry_t es;
    logic         eq;
    sel = oh_to_uint8(mr.pteidx);
    es  = mr.entry[sel];
    s.entry.tag   = es.tag;
    s.entry.asid  = es.asid;
    s.entry.vmid  = es.vmid;
    s.entry.ppn   = es.ppn;
    s.entry.pbmt  = es.pbmt;
    s.entry.n     = es.n;
    s.entry.perm  = es.perm;
    s.entry.level = es.level;
    s.entry.v     = es.v;
    s.af          = es.af;
    s.pf          = es.pf;
    s.addr_low    = sel;
    s.pteidx      = mr.pteidx;
    for (int i = 0; i < CONTIG; i++) begin
      eq = (mr.entry[i].ppn  == es.ppn)  &&
           (mr.entry[i].pbmt == es.pbmt) &&
           (mr.entry[i].perm == es.perm) &&
           (mr.entry[i].v    == es.v)    &&
           (mr.entry[i].af   == es.af)   &&
           (mr.entry[i].pf   == es.pf);
      // valididx = ((eq) || !not_super) && !not_merge
      s.valididx[i] = ((eq) || ~mr.not_super) & ~not_merge;
      s.ppn_low[i]  = mr.entry[i].ppn_low;
    end
    s.valididx[sel] = 1'b1; // 选中条目恒有效
    return s;
  endfunction

endpackage
