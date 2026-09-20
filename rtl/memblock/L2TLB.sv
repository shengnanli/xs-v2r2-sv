// ============================================================================
// L2TLB.sv —— 共享 MMU 顶层（页表遍历器总集成）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/cache/mmu/L2TLB.scala（class L2TLBImp）
//
// L2TLB 接收 ITLB/DTLB 的 miss 请求：先查 page cache，命中就直接回；未命中按命中深度
// 分给三个遍历器 —— PTW（非叶级）/ LLPTW（叶级，6 条并行）/ HPTW（G-stage）—— 由它们
// 向 L2 发访存读 64B PTE 块，回填 page cache，最后把 8 个连续 PTE 合并成一个
// sector PtwResp 送回 TLB。
//
// 本层只做 **仲裁 / 路由 / 分发 / 访存数据通路的 glue**；遍历、缓存、仲裁算法都在子模块
// 里（对本层是黑盒，UT/FM 两侧共用同一份 golden 定义）。手写 glue 按功能分节：
//   1  CSR / sfence 复制扇出（DelayN 1 拍 + RegNext 1 拍 → 10 份 csr / 11 份 sfence）
//   2  ITLB/DTLB 请求计数与节流（tlbCounter，防 miss queue 溢出）
//   3  page cache 入口仲裁(arb2) 输入装配 + miss queue 仲裁(mq_arb)
//   4  PTW / LLPTW / HPTW 请求分发
//   5  page cache resp.ready 多路选择
//   6  访存数据通路：mem_arb 4 路 → TileLink A；D 通道 2-beat 拼 512bit；
//      waiting_resp / flush_latch 在途跟踪；resp_pte 各 id 暂存
//   6b cache.refill 装配
//   7  HPTW 响应分发
//   8  输出合并：mergeArb 三路 + outArb → ITLB/DTLB resp
//   9  PMP checker 请求装配 + prefetch 触发
//   10 顶层输出直驱
//   11 性能事件两级打拍
//   12 Bitmap 检查引擎接线（G1 新增）
//
// ★ 相对 kunminghu-v1(G0) 的变化 ★（差异归类见 scripts/diag_l2tlb_g0g1.py）
//   G1 在 G0 之上**加了 bitmap 检查特性**，主体结构一行没动：
//     · 新增 5 个实例：Bitmap / BitmapCache / bitmap_arb / PMPChecker_3 / PMPChecker_4
//     · 访存 id 由 8 扩到 16：0..5 LLPTW、6 PTW、7 HPTW（原样不动）、**8..15 全归 Bitmap**
//     · PtwMergeEntry 多出一位 cf（bitmap check failed）
//     · CSR 多出 mbmc（bitmap 内存控制寄存器）与 priv_debug / priv_virt_changed，
//       去掉 priv_mxr
//     · LLPTW 的 PMP 口由 1 个变 2 个（故 PMPChecker 由 3 个变 5 个）
//     · G0 里被常量折叠掉的 toFsm_toLLPTW / toFsm_toPTW 在 G1 是真信号
// ============================================================================
// 本文件导航（共 11565 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L59    设计意图来源：src/main/scala/xiangshan/cache/mmu/L2TLB.scala
//   L95    l2tlb_pkg —— 本模块私有的参数 / 类型 / 纯函数
//   L97    参数值由本配置
//   L145   CSR / sfence 副本
//   L147   io.csr.tlb / io.sfence 先过 DelayN(1)，再 RegNext 一拍得到多份**同值**副本，
//   L187   PTE 与合并响应类型
//   L274   顶层输出给 ITLB/DTLB 的 sector PtwResp
//   L300   访存数据通路小函数
//   L302   512bit 块切成 8 个 64bit PTE，取第 index 个
//   L326   PTE 判定
//   L370   contiguous_pte_to_merge —— 8 个连续 PTE → PtwMergeResp
//   L372   顶层调用处 af_first / not_super 都固定为 true，故：
//   L439   merge_to_sector —— PtwMergeResp → PtwSectorResp
//   L441   选中条目 sel = OHToUInt(pteidx)
//   L446   ★G1 新增：bitmap 开启且本次翻译没有 G-stage 时，S1 就是**最终一级**★
//   L506   difftest 探针打包
//   L508   L2TLB 往 difftest gateway 送三条探针，每条是一长串定宽字段的拼接：
//   L571   xs_L2TLB_core —— 可读核
//   L573   端口与 golden L2TLB 逐位同名
//   L3252  1. CSR / sfence 复制扇出
//   L3254  io.csr.tlb / io.sfence 先过 DelayN(1) 得到 csr_tmp / sfence_tmp，再各 R
//   L3423  2. ITLB/DTLB 请求计数与节流
//   L3425  每拍 进入(req fire) - 离开(resp fire)；flush 清零
//   L3444  page cache 响应的常用字段
//   L3446  ★G1★ toFsm_toLLPTW / toFsm_toPTW 在 G0 里被常量折叠成 0
//   L3466  3. page cache 入口仲裁(arb2) 输入装配 + miss queue 仲裁(mq_arb)
//   L3468  arb2 五路：HPTW(0) / PTW(1) / MissQueue(2) / TLB(3) / Prefetch(4)
//   L3517  4. PTW / LLPTW / HPTW 请求分发
//   L3519  按 cache.resp 的命中深度把 miss 请求送往三个遍历器：
//   L3537  5. page cache resp.ready 多路选择
//   L3539  MuxCase：按 hit / isHptwReq / toLLPTW / bypassed 决定 cache 这拍能否被消费
//   L3553  6. 访存数据通路
//   L3555  mem_arb 四路
//   L3734  6b. cache.refill 装配
//   L3736  访存回来且不丢弃时置 refill_valid，打一拍给 cache.refill.valid；bits 在
//   L3841  7. HPTW 响应分发
//   L3843  hptw_resp_arb：in(0)=page cache 命中的 hptw 响应，in(1)=HPTW 自己的响应
//   L3853  8. 输出合并：mergeArb 三路 + outArb → ITLB/DTLB resp
//   L3855  每条 PtwWidth(ITLB/DTLB) 各一组 mergeArb(3 路)+outArb(1 路)：
//   L3860  -- llptw_stage1：LLPTW 入队那拍按 enq_ptr 锁存 cache.resp.stage1，供
//   L4897  9. PMP checker 请求装配 + prefetch 触发
//   L4899  ★G1★ 5 个 PMPChecker：ptw / llptw 口0 / llptw 口1 / hptw / bitmap
//   L4903  mode(ModeS=2'h1) 与 cmd(read) 在 golden 里就是写死的常量，实例区已直接给；
//   L4915  12. Bitmap 检查引擎接线
//   L4917  Bitmap 引擎按 PTE 的物理页号去查一张位图，判断该页是否可用
//   L4933  10. 顶层输出直驱
//   L5049  10b. difftest 探针
//   L5051  这三条只给 difftest gateway 看，不进功能通路，但它们是**实打实的顶层输出**
//   L5181  11. 性能事件两级打拍
//   L5183  19 路：0..3 ← LLPTW，4..11 ← PtwCache，12..18 ← PTW
//   L5235  子模块实例
//   L5237  BEGIN GENERATED(inst)
//   L10803 L2TLB —— 与 golden 端口逐位同名的外壳，直通到可读核
//

// ============================================================================
// l2tlb_pkg —— 本模块私有的参数 / 类型 / 纯函数
// ----------------------------------------------------------------------------
// 参数值由本配置（KunminghuV2Config：HasBitmapCheck=true、enablePrefetch=true、
// HasHExtension=true、EnableSv48=true）下的 golden L2TLB.sv 展开确定。
// ============================================================================
package l2tlb_pkg;

  // ---- 基本位宽（RISC-V Sv48 + H 扩展）----
  localparam int CONTIG           = 8;   // 一个 sector 的连续 PTE 数
  localparam int SECTOR_BITS      = 3;   // $clog2(CONTIG)
  localparam int VPN_W            = 38;
  localparam int SECTOR_VPN_W     = 35;  // VPN_W - SECTOR_BITS
  localparam int PTE_PPN_W        = 44;
  localparam int PPN_W            = 36;  // PAddrBits(48) - offLen(12)
  localparam int SECTOR_PTE_PPN_W = 41;  // PTE_PPN_W - SECTOR_BITS
  localparam int ASID_W           = 16;
  localparam int VMID_W           = 14;
  localparam int SOURCE_W         = 2;

  // ---- 结构规模 ----
  localparam int PTW_WIDTH      = 2;   // ITLB(0) / DTLB(1)
  localparam int LLPTW_SIZE     = 6;   // LLPTW 表项数
  localparam int BITMAP_SIZE    = 8;   // Bitmap 引擎在途表项数（G1 新增）
  // 访存源 id 分配：LLPTW 0..5 / PTW 6 / HPTW 7 / Bitmap 8..15。
  localparam int PTW_MEM_ID     = LLPTW_SIZE;      // 6
  localparam int HPTW_MEM_ID    = LLPTW_SIZE + 1;  // 7
  localparam int BITMAP_MEM_BASE= 8;
  localparam int MEM_REQ_WIDTH  = BITMAP_MEM_BASE + BITMAP_SIZE;  // 16
  localparam int MEM_ID_W       = 4;   // $clog2(16)
  localparam int L1_BUS_DATA_W  = 256; // TileLink 一个 beat
  localparam int BLOCK_BITS     = 512; // 一次访存取回的 PTE 块
  localparam int BEATS          = BLOCK_BITS / L1_BUS_DATA_W;  // 2
  localparam int PERF_NUM       = 19;  // io_perf_0..18
  localparam int MISS_QUEUE_SIZE= 40;  // tlbCounter 节流阈值

  // arb2（page cache 入口仲裁）输入端口编号（与 Scala 一致）
  localparam int IN_ARB_HPTW = 0, IN_ARB_PTW = 1, IN_ARB_MQ = 2,
                 IN_ARB_TLB  = 3, IN_ARB_PREF = 4;
  // mergeArb（每条 PtwWidth 一组）输入端口编号
  localparam int OUT_ARB_CACHE = 0, OUT_ARB_FSM = 1, OUT_ARB_MQ = 2;
  localparam int FSM_REQ_ID   = LLPTW_SIZE;  // hptw resp 回给 PTW 时用的 id

  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0,  // 仅 S-stage（普通 satp）
    ONLY_STAGE1 = 2'h1,  // 仅 VS-stage：结果是 GPA，不再进 G-stage
    ONLY_STAGE2 = 2'h2,  // 仅 G-stage：输入 vpn 已是 gvpn
    ALL_STAGE   = 2'h3   // VS-stage + G-stage
  } ptw_s2xlate_e;

  // ==========================================================================
  // CSR / sfence 副本
  // --------------------------------------------------------------------------
  // io.csr.tlb / io.sfence 先过 DelayN(1)，再 RegNext 一拍得到多份**同值**副本，
  // 纯粹为了降低长扇出。各子模块按固定下标取用；复制不改变任何逻辑值。
  // mbmc 是 G1 新增的 bitmap 内存控制寄存器（BMA=bitmap 基址，BME=使能，
  // CMODE=旁路模式，BCLEAR=清 bitmap cache）。
  // ==========================================================================
  typedef struct packed {
    logic [3:0]            satp_mode;
    logic [ASID_W-1:0]     satp_asid;
    logic [PTE_PPN_W-1:0]  satp_ppn;
    logic                  satp_changed;
    logic [3:0]            vsatp_mode;
    logic [ASID_W-1:0]     vsatp_asid;
    logic [PTE_PPN_W-1:0]  vsatp_ppn;
    logic                  vsatp_changed;
    logic [3:0]            hgatp_mode;
    logic [ASID_W-1:0]     hgatp_vmid;   // 端口 16bit，内部只用低 VMID_W 位
    logic [PTE_PPN_W-1:0]  hgatp_ppn;
    logic                  hgatp_changed;
    logic [57:0]           mbmc_BMA;     // G1 新增
    logic                  mbmc_BME;
    logic                  mbmc_CMODE;
    logic                  mbmc_BCLEAR;
    logic                  priv_virt;
    logic                  priv_virt_changed;  // G1 新增
    logic                  priv_debug;         // G1 新增
    logic                  mPBMTE;
    logic                  hPBMTE;
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
  // PTE 与合并响应类型
  // ==========================================================================
  typedef struct packed { logic d, a, g, u, x, w, r, v; } pte_perm_t;

  // RISC-V PTE 的物理布局（高位在前，packed struct 与 UInt[63:0] 逐位等价）。
  typedef struct packed {
    logic             n;         // Svnapot
    logic [1:0]       pbmt;      // Svpbmt
    logic [6:0]       reserved;
    logic [7:0]       ppn_high;
    logic [PPN_W-1:0] ppn;
    logic [1:0]       rsw;
    pte_perm_t        perm;
  } pte_t;

  typedef struct packed { logic d, a, g, u, x, w, r; } ptw_perm_t;

  typedef struct packed {
    logic [VPN_W-1:0]    vpn;
    logic [1:0]          s2xlate;
    logic [SOURCE_W-1:0] source;
  } ptw_req_info_t;

  // PtwMergeResp 的单条目。★cf 是 G1 新增的 bitmap check failed 位，排在 pf 之后★
  // （与 golden 扁平端口 ..._entry_<i>_cf 的声明次序一致）。
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
    logic                        cf;
  } ptw_merge_entry_t;

  typedef struct packed {
    ptw_merge_entry_t [CONTIG-1:0] entry;
    logic [CONTIG-1:0]             pteidx;
    logic                          not_super;
  } ptw_merge_resp_t;

  // ---- llptw_stage1 的存储型：不含 entry.af ----
  // golden 里 stage1 回放路径的 af 被恒门控为 0，因此**没有**对应寄存器。存储侧同样
  // 不保留 af（读出时钉 0），避免造出 golden 没有的 impl-only 触发器。
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
    logic                        pf;
    logic                        cf;
  } ptw_merge_entry_noaf_t;

  typedef struct packed {
    ptw_merge_entry_noaf_t [CONTIG-1:0] entry;
    logic [CONTIG-1:0]                  pteidx;
    logic                               not_super;
  } ptw_merge_resp_noaf_t;

  function automatic ptw_merge_resp_t mrg_from_noaf(input ptw_merge_resp_noaf_t m);
    ptw_merge_resp_t r;
    r.pteidx = m.pteidx;  r.not_super = m.not_super;
    for (int k = 0; k < CONTIG; k++) begin
      r.entry[k].tag  = m.entry[k].tag;   r.entry[k].asid    = m.entry[k].asid;
      r.entry[k].vmid = m.entry[k].vmid;  r.entry[k].n       = m.entry[k].n;
      r.entry[k].pbmt = m.entry[k].pbmt;  r.entry[k].perm    = m.entry[k].perm;
      r.entry[k].level= m.entry[k].level; r.entry[k].v       = m.entry[k].v;
      r.entry[k].ppn  = m.entry[k].ppn;   r.entry[k].ppn_low = m.entry[k].ppn_low;
      r.entry[k].pf   = m.entry[k].pf;    r.entry[k].cf      = m.entry[k].cf;
      r.entry[k].af   = 1'b0;             // golden 门控恒 0
    end
    return r;
  endfunction

  // ==========================================================================
  // 顶层输出给 ITLB/DTLB 的 sector PtwResp
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
    sector_entry_t                      entry;
    logic [SECTOR_BITS-1:0]             addr_low;
    logic [CONTIG-1:0][SECTOR_BITS-1:0] ppn_low;
    logic [CONTIG-1:0]                  valididx;
    logic [CONTIG-1:0]                  pteidx;
    logic                               pf;
    logic                               af;
    logic                               cf;
  } sector_resp_t;

  // ==========================================================================
  // 访存数据通路小函数
  // ==========================================================================
  // 512bit 块切成 8 个 64bit PTE，取第 index 个。
  function automatic logic [63:0] get_part(input logic [BLOCK_BITS-1:0] data,
                                           input logic [SECTOR_BITS-1:0] index);
    return data[index*64 +: 64];
  endfunction
  // 请求在块内的 PTE 下标：LLPTW 入队时由 vpn 低位算，访存发出时由物理地址算。
  function automatic logic [SECTOR_BITS-1:0] addr_low_from_vpn(input logic [VPN_W-1:0] vpn);
    return vpn[SECTOR_BITS-1:0];
  endfunction
  function automatic logic [SECTOR_BITS-1:0] addr_low_from_paddr(input logic [47:0] paddr);
    return paddr[5:3];
  endfunction

  // OHToUInt：one-hot pteidx → 下标。保留 Chisel 的 OR 归约语义（输入非 one-hot 时
  // 也有确定结果），避免 FM 在无约束输入下推出假分叉。
  function automatic logic [SECTOR_BITS-1:0] oh_to_uint8(input logic [CONTIG-1:0] oh);
    logic [SECTOR_BITS-1:0] r;
    r[0] = oh[1] | oh[3] | oh[5] | oh[7];
    r[1] = oh[2] | oh[3] | oh[6] | oh[7];
    r[2] = oh[4] | oh[5] | oh[6] | oh[7];
    return r;
  endfunction

  // ==========================================================================
  // PTE 判定（Sv48 + Svpbmt + Svnapot）
  // ==========================================================================
  function automatic logic pte_is_leaf(input pte_t pte);
    return pte.perm.v && (pte.perm.r || pte.perm.w || pte.perm.x);
  endfunction
  // 指向下一级页表（有效但不是叶子）。
  function automatic logic pte_is_next(input pte_t pte);
    return pte.perm.v && !(pte.perm.r || pte.perm.w || pte.perm.x);
  endfunction
  function automatic logic [PTE_PPN_W-1:0] pte_ppn(input pte_t pte);
    return {pte.ppn_high, pte.ppn};
  endfunction

  // page fault 判定（Sv48 + Svpbmt + Svnapot），逐条对齐 golden：
  //   保留位非 0 / pbmt 非法或未使能 / 非叶级带了 u,a,d,n,pbmt /
  //   无效或 w 而不 r / napot 但 ppn[3:0]!=8 或不在末级 / superpage 未对齐。
  function automatic logic pte_page_fault(
    input pte_t       pte,
    input logic [1:0] level,
    input logic       pbmt_enable
  );
    logic unaligned;
    unaligned =
      pte_is_leaf(pte) &&
      !(level == 2'h0 ||
        (level == 2'h1 && pte.ppn[8:0]  == 9'h0)  ||
        (level == 2'h2 && pte.ppn[17:0] == 18'h0) ||
        (level == 2'h3 && pte.ppn[26:0] == 27'h0));

    if (pte.reserved != 7'h0) return 1'b1;
    if (pte.pbmt == 2'h3 || (!pbmt_enable && pte.pbmt != 2'h0)) return 1'b1;
    if (pte_is_next(pte))
      return pte.perm.u || pte.perm.a || pte.perm.d || pte.n || (pte.pbmt != 2'h0);
    if (!pte.perm.v || (!pte.perm.r && pte.perm.w)) return 1'b1;
    if (pte.n && (pte.ppn[3:0] != 4'h8 || level != 2'h0)) return 1'b1;
    return unaligned;
  endfunction

  // 香山物理地址只有 48 位；PTE[53:46] 非零且 PTE 有效时算 access fault。
  function automatic logic pte_access_fault(input pte_t pte);
    return (pte.ppn_high != 8'h0) && pte.perm.v;
  endfunction

  // ==========================================================================
  // contiguous_pte_to_merge —— 8 个连续 PTE → PtwMergeResp（LLPTW 出口）
  // --------------------------------------------------------------------------
  // 顶层调用处 af_first / not_super 都固定为 true，故：
  //   pf = !af && isPf            （isPf = 末级 page fault 或根本不是叶子）
  //   af = af || isAf             （isAf 只在 noS2/onlyS1 且非 pf 时成立）
  //   v  = !pf；asid 有 G-stage 时取 vsatp 否则 satp；vmid 取 hgatp.vmid
  //   not_super = !napot，napot 取 vpn 选中那一条的 n 位
  // ★G1 新增★ cf（bitmap check failed）：每条取 bitmap 引擎返回的 cfs 数组，
  //   下标是**该条 PTE 自己的 ppn[2:0]**（对齐 golden 的 cfs 查表下标）。
  // ==========================================================================
  function automatic ptw_merge_resp_t contiguous_pte_to_merge(
    input logic [BLOCK_BITS-1:0] pte_blk,
    input logic [CONTIG-1:0]     cfs,          // G1：bitmap 检查结果
    input logic [VPN_W-1:0]      vpn,
    input logic                  af,
    input logic [1:0]            s2xlate,
    input logic                  mPBMTE,
    input logic                  hPBMTE,
    input logic [ASID_W-1:0]     satp_asid,
    input logic [ASID_W-1:0]     vsatp_asid,
    input logic [VMID_W-1:0]     hgatp_vmid
  );
    ptw_merge_resp_t        r;
    logic                   has_s2, pbmte, is_pf, is_af;
    pte_t                   pte_in;
    ptw_merge_entry_t       e;
    logic [SECTOR_BITS-1:0] sel;
    logic [PTE_PPN_W-1:0]   full_ppn;   // 暂存：FM 不接受对函数调用结果直接位选

    has_s2 = (s2xlate != NO_S2XLATE);
    pbmte  = (s2xlate == ONLY_STAGE1 || s2xlate == ALL_STAGE) ? hPBMTE : mPBMTE;
    for (int i = 0; i < CONTIG; i++) begin
      pte_in = pte_t'(pte_blk[i*64 +: 64]);
      is_pf  = pte_page_fault(pte_in, 2'h0, pbmte) || !pte_is_leaf(pte_in);
      is_af  = pte_access_fault(pte_in)
               && (s2xlate == NO_S2XLATE || s2xlate == ONLY_STAGE1) && !is_pf;
      e         = '0;
      full_ppn  = pte_ppn(pte_in);
      e.ppn     = full_ppn[PTE_PPN_W-1:SECTOR_BITS];
      e.ppn_low = full_ppn[SECTOR_BITS-1:0];
      e.level   = 2'h0;
      e.pbmt    = pte_in.pbmt;
      // ★n（napot）不是 PTE 第 63 位原样抄★：golden 这里带 ppn[3:0]==8 的门控
      //   golden L2TLB.sv:3676  wire ptw_resp_n = x1[63] & x1[13:10] == 4'h8;
      //   （x1 是这 8 条 PTE 的原文，x1[13:10] 就是本条 PTE 的 ppn[3:0]）
      // Svnapot 规定只有 ppn[3:0]==8 才是合法的 64KB napot 编码，不合法的
      // n 位当作没有。这一位会顺着 r.not_super = ~entry[sel].n 一路走到
      // valididx 的"同段"判据，漏了门控 ⇒ FM 报 io_tlb_0_resp_bits_s1_valididx_*
      // 不等价（2026-09-20 首跑：failing 20，全在 valididx 与它的 difftest 打包位）。
      e.n       = pte_in.n & (full_ppn[3:0] == 4'h8);
      e.perm    = '{d: pte_in.perm.d, a: pte_in.perm.a, g: pte_in.perm.g,
                    u: pte_in.perm.u, x: pte_in.perm.x, w: pte_in.perm.w,
                    r: pte_in.perm.r};
      e.tag     = vpn[VPN_W-1:SECTOR_BITS];
      e.pf      = (~af) & is_pf;
      e.af      = (af | is_af);
      e.v       = ~e.pf;
      e.asid    = has_s2 ? vsatp_asid : satp_asid;
      e.vmid    = hgatp_vmid;
      e.cf      = cfs[full_ppn[SECTOR_BITS-1:0]];   // 按本条 PTE 的 ppn[2:0] 取
      r.entry[i] = e;
    end
    sel        = vpn[SECTOR_BITS-1:0];
    r.pteidx   = (8'h1 << sel);            // UIntToOH(vpn[2:0])
    r.not_super= ~r.entry[sel].n;
    return r;
  endfunction

  // ==========================================================================
  // merge_to_sector —— PtwMergeResp → PtwSectorResp（顶层出口）
  // --------------------------------------------------------------------------
  // 选中条目 sel = OHToUInt(pteidx)。valididx[i] 表示第 i 条与选中条“同段”
  // （ppn/pbmt/perm/v/af/pf/cf 全等）或本身就是 superpage，且 not_merge 为假。
  // not_merge 由调用方从 mergeArb 输出的 s1.not_merge 传入（仅 llptw 路且有
  // G-stage 时才为真；cache/ptw 路胜出恒合并）。
  // ==========================================================================
  // ★G1 新增：bitmap 开启且本次翻译没有 G-stage 时，S1 就是**最终一级**★
  // 这时选中条目要按它自己的 level / napot 位"拍平"到 4KB 粒度：高位保留 PPN，
  // 低位换成 VPN(tag) 的对应位。和下面 s2 侧的 hptw_gen_ppn_s2 是同一套算法，
  // 只是这里作用在 **sector** 口径上（ppn/tag 都已经去掉了 3 位 sector 下标），
  // 所以每个切点都比 s2 侧小 3。
  function automatic logic [SECTOR_PTE_PPN_W-1:0] sector_gen_ppn(
    input logic [SECTOR_PTE_PPN_W-1:0] ppn,
    input logic [SECTOR_VPN_W-1:0]     tag,
    input logic [1:0]                  level,
    input logic                        n
  );
    case (level)
      2'h1:    return {ppn[SECTOR_PTE_PPN_W-1:6],  tag[5:0]};    // 2MB
      2'h2:    return {ppn[SECTOR_PTE_PPN_W-1:15], tag[14:0]};   // 1GB
      2'h3:    return {ppn[SECTOR_PTE_PPN_W-1:24], tag[23:0]};   // 512GB
      default: return n ? {ppn[SECTOR_PTE_PPN_W-1:1], tag[0]}    // 64KB napot
                        : ppn;                                    // 4KB，原样
    endcase
  endfunction

  // bm_final：bitmap_enable && 本次没有 G-stage（s2xlate ∈ {noS2, onlyS1}）。
  // 为真时 level/n 归 0、ppn 拍平，且 valididx 的"同段"判据变严（见函数体）。
  function automatic sector_resp_t merge_to_sector(
    input ptw_merge_resp_t mr,
    input logic            not_merge,
    input logic            bm_final
  );
    sector_resp_t           s;
    logic [SECTOR_BITS-1:0] sel;
    ptw_merge_entry_t       es;
    logic                   eq;
    sel = oh_to_uint8(mr.pteidx);
    es  = mr.entry[sel];
    s.entry.tag = es.tag;  s.entry.asid = es.asid;  s.entry.vmid = es.vmid;
    s.entry.pbmt = es.pbmt; s.entry.perm = es.perm;  s.entry.v    = es.v;
    // ★bm_final 只改这三项★（golden 逐字段核对过：tag/asid/vmid/pbmt/perm/v/
    //   addr_low/af/pf 两个分支的表达式完全相同，不许顺手也改）
    s.entry.ppn   = bm_final ? sector_gen_ppn(es.ppn, es.tag, es.level, es.n) : es.ppn;
    s.entry.level = bm_final ? 2'h0 : es.level;
    s.entry.n     = bm_final ? 1'b0 : es.n;
    s.af = es.af;  s.pf = es.pf;  s.cf = es.cf;
    s.addr_low = sel;  s.pteidx = mr.pteidx;
    for (int i = 0; i < CONTIG; i++) begin
      eq = (mr.entry[i].ppn  == es.ppn)  && (mr.entry[i].pbmt == es.pbmt) &&
           (mr.entry[i].perm == es.perm) && (mr.entry[i].v    == es.v)    &&
           (mr.entry[i].af   == es.af)   && (mr.entry[i].pf   == es.pf)   &&
           (mr.entry[i].cf   == es.cf);
      // ★两套"同段"判据★：
      //   常规      —— 等值 **或** 选中条目是 superpage（整片都算同段）
      //   bm_final  —— 必须 not_super **且** 等值。拍平之后 superpage 那条捷径
      //                不再成立（ppn 已经被改写），golden 在这里换了判据。
      s.valididx[i] = bm_final ? (mr.not_super & eq & ~not_merge)
                               : ((eq | ~mr.not_super) & ~not_merge);
      s.ppn_low[i]  = mr.entry[i].ppn_low;
    end
    s.valididx[sel] = 1'b1;   // 选中条目恒有效（两套判据都是 `i==sel |` 打头）
    return s;
  endfunction

  // ==========================================================================
  // difftest 探针打包
  // --------------------------------------------------------------------------
  // L2TLB 往 difftest gateway 送三条探针，每条是一长串定宽字段的拼接：
  //   refill 探针  601 bit —— 一次 page-table 行填充（地址 + 64B 数据）
  //   l2tlb 探针   969 bit × 2 —— 两个 TLB 口各一条，内容是这拍发出的 sector 响应
  // 打包顺序/零扩展宽度就是 difftest 的协议，必须与 golden 逐位一致，故两条
  // l2tlb 探针共用同一个纯函数，调用处只喂各自那个口的信号（不许各写一遍）。
  // ★纯函数★：需要的信号全部走形参，函数体内不读任何模块级信号 ——
  // 否则 FM 报 FMR_VLOG-091（见 CONVENTIONS「Formality elaborate 四条硬约束」）。
  // ==========================================================================
  localparam int REFILL_PROBE_W = 601;
  localparam int L2TLB_PROBE_W  = 969;

  function automatic logic [REFILL_PROBE_W-1:0] pack_refill_probe(
    input logic                       valid,
    input logic [47:0]                addr,      // 64B 对齐的 PTE 行地址
    input logic [CONTIG-1:0][63:0]    ptes,      // 行内 8 条 PTE，低位在前
    input logic [7:0]                 mask,
    input logic [7:0]                 coreid,
    input logic [7:0]                 index
  );
    // ptes 是 packed 数组，拼接时**元素 [7] 自然在高位**，正好就是探针要的
    // data_7..data_0 次序 —— 不要再翻一次（第一版翻了，UT 当场抓到）。
    return {valid, {16'h0, addr}, ptes, mask, coreid, index};
  endfunction

  function automatic logic [L2TLB_PROBE_W-1:0] pack_l2tlb_probe(
    input logic                                 valid,
    input logic [CONTIG-1:0]                    valididx,
    input logic [63:0]                          satp,
    input logic [SECTOR_VPN_W-1:0]              s1_tag,
    input logic [1:0]                           pbmt,
    input logic [1:0]                           g_pbmt,
    input logic [SECTOR_PTE_PPN_W-1:0]          s1_ppn,
    input logic [CONTIG-1:0][SECTOR_BITS-1:0]   ppn_low,
    input ptw_perm_t                            perm,
    input logic [1:0]                           level,
    input logic                                 pf,
    input logic [CONTIG-1:0]                    pteidx,
    input logic [63:0]                          vsatp,
    input logic [63:0]                          hgatp,
    input logic [37:0]                          s2_tag,
    input ptw_perm_t                            g_perm,
    input logic [1:0]                           g_level,
    input logic [37:0]                          s2_ppn,
    input logic                                 gpf,
    input logic [1:0]                           s2xlate,
    input logic [7:0]                           coreid,
    input logic [7:0]                           index
  );
    // 探针里按条目的三族字段都是 7..0 高位在前；packed 数组拼接时元素 [7] 本来
    // 就落在高位，所以**直接拼**即可。
    // ★第一版在这里多翻了一次（写成 ppn_low[CONTIG-1-i]），UT seed=1 当场报
    //   gatewayIn_packed_44/45 差在第 291/298 位——正是 pteidx 那 8 位，一眼定位。★
    logic [CONTIG-1:0][63:0] ppn_full;
    for (int i = 0; i < CONTIG; i++) ppn_full[i] = {20'h0, s1_ppn, ppn_low[i]};
    return {valid, valididx, satp, {26'h0, s1_tag, 3'h0}, pbmt, g_pbmt,
            ppn_full, {1'h0, perm}, {6'h0, level}, pf, pteidx,
            vsatp, hgatp, {26'h0, s2_tag}, {1'h0, g_perm}, {6'h0, g_level},
            {26'h0, s2_ppn}, gpf, s2xlate, coreid, index};
  endfunction

endpackage

// ============================================================================
// xs_L2TLB_core —— 可读核
// ----------------------------------------------------------------------------
// 端口与 golden L2TLB 逐位同名（扁平）。子模块实例、实例输出网声明、以及 struct 与
// golden 扁平网之间的对应关系都是纯机械派生，由 scripts/gen_l2tlb.py 生成并用
// `// BEGIN GENERATED(<tag>)` / `// END GENERATED` 原地标记；手写逻辑只在标记之外。
// ============================================================================
module xs_L2TLB_core
  import l2tlb_pkg::*;
(
  // BEGIN GENERATED(ports)
  input clock,
  input reset,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_source,
  output [47:0] auto_out_a_bits_address,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [2:0] auto_out_d_bits_size,
  input [3:0] auto_out_d_bits_source,
  input [255:0] auto_out_d_bits_data,
  input [5:0] io_hartId,
  output io_tlb_0_req_0_ready,
  input io_tlb_0_req_0_valid,
  input [37:0] io_tlb_0_req_0_bits_vpn,
  input [1:0] io_tlb_0_req_0_bits_s2xlate,
  input io_tlb_0_resp_ready,
  output io_tlb_0_resp_valid,
  output [1:0] io_tlb_0_resp_bits_s2xlate,
  output [34:0] io_tlb_0_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_0_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_0_resp_bits_s1_entry_vmid,
  output io_tlb_0_resp_bits_s1_entry_n,
  output [1:0] io_tlb_0_resp_bits_s1_entry_pbmt,
  output io_tlb_0_resp_bits_s1_entry_perm_d,
  output io_tlb_0_resp_bits_s1_entry_perm_a,
  output io_tlb_0_resp_bits_s1_entry_perm_g,
  output io_tlb_0_resp_bits_s1_entry_perm_u,
  output io_tlb_0_resp_bits_s1_entry_perm_x,
  output io_tlb_0_resp_bits_s1_entry_perm_w,
  output io_tlb_0_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s1_entry_level,
  output io_tlb_0_resp_bits_s1_entry_v,
  output [40:0] io_tlb_0_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_0_resp_bits_s1_addr_low,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_7,
  output io_tlb_0_resp_bits_s1_valididx_0,
  output io_tlb_0_resp_bits_s1_valididx_1,
  output io_tlb_0_resp_bits_s1_valididx_2,
  output io_tlb_0_resp_bits_s1_valididx_3,
  output io_tlb_0_resp_bits_s1_valididx_4,
  output io_tlb_0_resp_bits_s1_valididx_5,
  output io_tlb_0_resp_bits_s1_valididx_6,
  output io_tlb_0_resp_bits_s1_valididx_7,
  output io_tlb_0_resp_bits_s1_pteidx_0,
  output io_tlb_0_resp_bits_s1_pteidx_1,
  output io_tlb_0_resp_bits_s1_pteidx_2,
  output io_tlb_0_resp_bits_s1_pteidx_3,
  output io_tlb_0_resp_bits_s1_pteidx_4,
  output io_tlb_0_resp_bits_s1_pteidx_5,
  output io_tlb_0_resp_bits_s1_pteidx_6,
  output io_tlb_0_resp_bits_s1_pteidx_7,
  output io_tlb_0_resp_bits_s1_pf,
  output io_tlb_0_resp_bits_s1_af,
  output [37:0] io_tlb_0_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_0_resp_bits_s2_entry_vmid,
  output io_tlb_0_resp_bits_s2_entry_n,
  output [1:0] io_tlb_0_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_0_resp_bits_s2_entry_ppn,
  output io_tlb_0_resp_bits_s2_entry_perm_d,
  output io_tlb_0_resp_bits_s2_entry_perm_a,
  output io_tlb_0_resp_bits_s2_entry_perm_g,
  output io_tlb_0_resp_bits_s2_entry_perm_u,
  output io_tlb_0_resp_bits_s2_entry_perm_x,
  output io_tlb_0_resp_bits_s2_entry_perm_w,
  output io_tlb_0_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s2_entry_level,
  output io_tlb_0_resp_bits_s2_gpf,
  output io_tlb_0_resp_bits_s2_gaf,
  output io_tlb_1_req_0_ready,
  input io_tlb_1_req_0_valid,
  input [37:0] io_tlb_1_req_0_bits_vpn,
  input [1:0] io_tlb_1_req_0_bits_s2xlate,
  output io_tlb_1_resp_valid,
  output [1:0] io_tlb_1_resp_bits_s2xlate,
  output [34:0] io_tlb_1_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_1_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_1_resp_bits_s1_entry_vmid,
  output io_tlb_1_resp_bits_s1_entry_n,
  output [1:0] io_tlb_1_resp_bits_s1_entry_pbmt,
  output io_tlb_1_resp_bits_s1_entry_perm_d,
  output io_tlb_1_resp_bits_s1_entry_perm_a,
  output io_tlb_1_resp_bits_s1_entry_perm_g,
  output io_tlb_1_resp_bits_s1_entry_perm_u,
  output io_tlb_1_resp_bits_s1_entry_perm_x,
  output io_tlb_1_resp_bits_s1_entry_perm_w,
  output io_tlb_1_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s1_entry_level,
  output io_tlb_1_resp_bits_s1_entry_v,
  output [40:0] io_tlb_1_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_1_resp_bits_s1_addr_low,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_7,
  output io_tlb_1_resp_bits_s1_valididx_0,
  output io_tlb_1_resp_bits_s1_valididx_1,
  output io_tlb_1_resp_bits_s1_valididx_2,
  output io_tlb_1_resp_bits_s1_valididx_3,
  output io_tlb_1_resp_bits_s1_valididx_4,
  output io_tlb_1_resp_bits_s1_valididx_5,
  output io_tlb_1_resp_bits_s1_valididx_6,
  output io_tlb_1_resp_bits_s1_valididx_7,
  output io_tlb_1_resp_bits_s1_pteidx_0,
  output io_tlb_1_resp_bits_s1_pteidx_1,
  output io_tlb_1_resp_bits_s1_pteidx_2,
  output io_tlb_1_resp_bits_s1_pteidx_3,
  output io_tlb_1_resp_bits_s1_pteidx_4,
  output io_tlb_1_resp_bits_s1_pteidx_5,
  output io_tlb_1_resp_bits_s1_pteidx_6,
  output io_tlb_1_resp_bits_s1_pteidx_7,
  output io_tlb_1_resp_bits_s1_pf,
  output io_tlb_1_resp_bits_s1_af,
  output [37:0] io_tlb_1_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_1_resp_bits_s2_entry_vmid,
  output io_tlb_1_resp_bits_s2_entry_n,
  output [1:0] io_tlb_1_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_1_resp_bits_s2_entry_ppn,
  output io_tlb_1_resp_bits_s2_entry_perm_d,
  output io_tlb_1_resp_bits_s2_entry_perm_a,
  output io_tlb_1_resp_bits_s2_entry_perm_g,
  output io_tlb_1_resp_bits_s2_entry_perm_u,
  output io_tlb_1_resp_bits_s2_entry_perm_x,
  output io_tlb_1_resp_bits_s2_entry_perm_w,
  output io_tlb_1_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s2_entry_level,
  output io_tlb_1_resp_bits_s2_gpf,
  output io_tlb_1_resp_bits_s2_gaf,
  input io_sfence_valid,
  input io_sfence_bits_rs1,
  input io_sfence_bits_rs2,
  input [49:0] io_sfence_bits_addr,
  input [15:0] io_sfence_bits_id,
  input io_sfence_bits_hv,
  input io_sfence_bits_hg,
  input io_wfi_wfiReq,
  output io_wfi_wfiSafe,
  input [3:0] io_csr_tlb_satp_mode,
  input [15:0] io_csr_tlb_satp_asid,
  input [43:0] io_csr_tlb_satp_ppn,
  input io_csr_tlb_satp_changed,
  input [3:0] io_csr_tlb_vsatp_mode,
  input [15:0] io_csr_tlb_vsatp_asid,
  input [43:0] io_csr_tlb_vsatp_ppn,
  input io_csr_tlb_vsatp_changed,
  input [3:0] io_csr_tlb_hgatp_mode,
  input [15:0] io_csr_tlb_hgatp_vmid,
  input [43:0] io_csr_tlb_hgatp_ppn,
  input io_csr_tlb_hgatp_changed,
  input io_csr_tlb_mbmc_BME,
  input io_csr_tlb_mbmc_CMODE,
  input io_csr_tlb_mbmc_BCLEAR,
  input [57:0] io_csr_tlb_mbmc_BMA,
  input io_csr_tlb_priv_virt,
  input io_csr_tlb_priv_virt_changed,
  input io_csr_tlb_priv_debug,
  input io_csr_tlb_mPBMTE,
  input io_csr_tlb_hPBMTE,
  input io_csr_distribute_csr_w_valid,
  input [11:0] io_csr_distribute_csr_w_bits_addr,
  input [63:0] io_csr_distribute_csr_w_bits_data,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  input [5:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [1:0] boreChildrenBd_bore_be,
  input [5:0] boreChildrenBd_bore_addr,
  input [89:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [5:0] boreChildrenBd_bore_addr_rd,
  output [89:0] boreChildrenBd_bore_outdata,
  input [5:0] boreChildrenBd_bore_1_array,
  input boreChildrenBd_bore_1_all,
  input boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_writeen,
  input boreChildrenBd_bore_1_be,
  input [2:0] boreChildrenBd_bore_1_addr,
  input [130:0] boreChildrenBd_bore_1_indata,
  input boreChildrenBd_bore_1_readen,
  input [2:0] boreChildrenBd_bore_1_addr_rd,
  output [130:0] boreChildrenBd_bore_1_outdata,
  input [6:0] boreChildrenBd_bore_2_array,
  input boreChildrenBd_bore_2_all,
  input boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_writeen,
  input [1:0] boreChildrenBd_bore_2_be,
  input [6:0] boreChildrenBd_bore_2_addr,
  input [113:0] boreChildrenBd_bore_2_indata,
  input boreChildrenBd_bore_2_readen,
  input [6:0] boreChildrenBd_bore_2_addr_rd,
  output [113:0] boreChildrenBd_bore_2_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen,
  input sigFromSrams_bore_2_ram_hold,
  input sigFromSrams_bore_2_ram_bypass,
  input sigFromSrams_bore_2_ram_bp_clken,
  input sigFromSrams_bore_2_ram_aux_clk,
  input sigFromSrams_bore_2_ram_aux_ckbp,
  input sigFromSrams_bore_2_ram_mcp_hold,
  input sigFromSrams_bore_2_cgen,
  input sigFromSrams_bore_3_ram_hold,
  input sigFromSrams_bore_3_ram_bypass,
  input sigFromSrams_bore_3_ram_bp_clken,
  input sigFromSrams_bore_3_ram_aux_clk,
  input sigFromSrams_bore_3_ram_aux_ckbp,
  input sigFromSrams_bore_3_ram_mcp_hold,
  input sigFromSrams_bore_3_cgen,
  input sigFromSrams_bore_4_ram_hold,
  input sigFromSrams_bore_4_ram_bypass,
  input sigFromSrams_bore_4_ram_bp_clken,
  input sigFromSrams_bore_4_ram_aux_clk,
  input sigFromSrams_bore_4_ram_aux_ckbp,
  input sigFromSrams_bore_4_ram_mcp_hold,
  input sigFromSrams_bore_4_cgen,
  input sigFromSrams_bore_5_ram_hold,
  input sigFromSrams_bore_5_ram_bypass,
  input sigFromSrams_bore_5_ram_bp_clken,
  input sigFromSrams_bore_5_ram_aux_clk,
  input sigFromSrams_bore_5_ram_aux_ckbp,
  input sigFromSrams_bore_5_ram_mcp_hold,
  input sigFromSrams_bore_5_cgen,
  input sigFromSrams_bore_6_ram_hold,
  input sigFromSrams_bore_6_ram_bypass,
  input sigFromSrams_bore_6_ram_bp_clken,
  input sigFromSrams_bore_6_ram_aux_clk,
  input sigFromSrams_bore_6_ram_aux_ckbp,
  input sigFromSrams_bore_6_ram_mcp_hold,
  input sigFromSrams_bore_6_cgen,
  input sigFromSrams_bore_7_ram_hold,
  input sigFromSrams_bore_7_ram_bypass,
  input sigFromSrams_bore_7_ram_bp_clken,
  input sigFromSrams_bore_7_ram_aux_clk,
  input sigFromSrams_bore_7_ram_aux_ckbp,
  input sigFromSrams_bore_7_ram_mcp_hold,
  input sigFromSrams_bore_7_cgen,
  input sigFromSrams_bore_8_ram_hold,
  input sigFromSrams_bore_8_ram_bypass,
  input sigFromSrams_bore_8_ram_bp_clken,
  input sigFromSrams_bore_8_ram_aux_clk,
  input sigFromSrams_bore_8_ram_aux_ckbp,
  input sigFromSrams_bore_8_ram_mcp_hold,
  input sigFromSrams_bore_8_cgen,
  input sigFromSrams_bore_9_ram_hold,
  input sigFromSrams_bore_9_ram_bypass,
  input sigFromSrams_bore_9_ram_bp_clken,
  input sigFromSrams_bore_9_ram_aux_clk,
  input sigFromSrams_bore_9_ram_aux_ckbp,
  input sigFromSrams_bore_9_ram_mcp_hold,
  input sigFromSrams_bore_9_cgen,
  input sigFromSrams_bore_10_ram_hold,
  input sigFromSrams_bore_10_ram_bypass,
  input sigFromSrams_bore_10_ram_bp_clken,
  input sigFromSrams_bore_10_ram_aux_clk,
  input sigFromSrams_bore_10_ram_aux_ckbp,
  input sigFromSrams_bore_10_ram_mcp_hold,
  input sigFromSrams_bore_10_cgen,
  input sigFromSrams_bore_11_ram_hold,
  input sigFromSrams_bore_11_ram_bypass,
  input sigFromSrams_bore_11_ram_bp_clken,
  input sigFromSrams_bore_11_ram_aux_clk,
  input sigFromSrams_bore_11_ram_aux_ckbp,
  input sigFromSrams_bore_11_ram_mcp_hold,
  input sigFromSrams_bore_11_cgen,
  input sigFromSrams_bore_12_ram_hold,
  input sigFromSrams_bore_12_ram_bypass,
  input sigFromSrams_bore_12_ram_bp_clken,
  input sigFromSrams_bore_12_ram_aux_clk,
  input sigFromSrams_bore_12_ram_aux_ckbp,
  input sigFromSrams_bore_12_ram_mcp_hold,
  input sigFromSrams_bore_12_cgen,
  input sigFromSrams_bore_13_ram_hold,
  input sigFromSrams_bore_13_ram_bypass,
  input sigFromSrams_bore_13_ram_bp_clken,
  input sigFromSrams_bore_13_ram_aux_clk,
  input sigFromSrams_bore_13_ram_aux_ckbp,
  input sigFromSrams_bore_13_ram_mcp_hold,
  input sigFromSrams_bore_13_cgen,
  input sigFromSrams_bore_14_ram_hold,
  input sigFromSrams_bore_14_ram_bypass,
  input sigFromSrams_bore_14_ram_bp_clken,
  input sigFromSrams_bore_14_ram_aux_clk,
  input sigFromSrams_bore_14_ram_aux_ckbp,
  input sigFromSrams_bore_14_ram_mcp_hold,
  input sigFromSrams_bore_14_cgen,
  input sigFromSrams_bore_15_ram_hold,
  input sigFromSrams_bore_15_ram_bypass,
  input sigFromSrams_bore_15_ram_bp_clken,
  input sigFromSrams_bore_15_ram_aux_clk,
  input sigFromSrams_bore_15_ram_aux_ckbp,
  input sigFromSrams_bore_15_ram_mcp_hold,
  input sigFromSrams_bore_15_cgen,
  input sigFromSrams_bore_16_ram_hold,
  input sigFromSrams_bore_16_ram_bypass,
  input sigFromSrams_bore_16_ram_bp_clken,
  input sigFromSrams_bore_16_ram_aux_clk,
  input sigFromSrams_bore_16_ram_aux_ckbp,
  input sigFromSrams_bore_16_ram_mcp_hold,
  input sigFromSrams_bore_16_cgen,
  input sigFromSrams_bore_17_ram_hold,
  input sigFromSrams_bore_17_ram_bypass,
  input sigFromSrams_bore_17_ram_bp_clken,
  input sigFromSrams_bore_17_ram_aux_clk,
  input sigFromSrams_bore_17_ram_aux_ckbp,
  input sigFromSrams_bore_17_ram_mcp_hold,
  input sigFromSrams_bore_17_cgen,
  input sigFromSrams_bore_18_ram_hold,
  input sigFromSrams_bore_18_ram_bypass,
  input sigFromSrams_bore_18_ram_bp_clken,
  input sigFromSrams_bore_18_ram_aux_clk,
  input sigFromSrams_bore_18_ram_aux_ckbp,
  input sigFromSrams_bore_18_ram_mcp_hold,
  input sigFromSrams_bore_18_cgen,
  input sigFromSrams_bore_19_ram_hold,
  input sigFromSrams_bore_19_ram_bypass,
  input sigFromSrams_bore_19_ram_bp_clken,
  input sigFromSrams_bore_19_ram_aux_clk,
  input sigFromSrams_bore_19_ram_aux_ckbp,
  input sigFromSrams_bore_19_ram_mcp_hold,
  input sigFromSrams_bore_19_cgen,
  input sigFromSrams_bore_20_ram_hold,
  input sigFromSrams_bore_20_ram_bypass,
  input sigFromSrams_bore_20_ram_bp_clken,
  input sigFromSrams_bore_20_ram_aux_clk,
  input sigFromSrams_bore_20_ram_aux_ckbp,
  input sigFromSrams_bore_20_ram_mcp_hold,
  input sigFromSrams_bore_20_cgen,
  input cg_bore_cgen,
  input cg_bore_1_cgen,
  output [600:0] gatewayIn_packed_43_bore,
  output [968:0] gatewayIn_packed_44_bore,
  output [968:0] gatewayIn_packed_45_bore
  // END GENERATED
);

  // 子模块输出网（由下方实例区的 output 端口驱动）。
  // BEGIN GENERATED(wires)
  wire [2:0] u_arb_cache_in_chosen;
  wire u_arb_cache_in_in_0_ready;
  wire u_arb_cache_in_in_1_ready;
  wire u_arb_cache_in_in_2_ready;
  wire u_arb_cache_in_in_3_ready;
  wire u_arb_cache_in_in_4_ready;
  wire [2:0] u_arb_cache_in_out_bits_hptwId;
  wire u_arb_cache_in_out_bits_isHptwReq;
  wire [1:0] u_arb_cache_in_out_bits_req_info_s2xlate;
  wire [1:0] u_arb_cache_in_out_bits_req_info_source;
  wire [37:0] u_arb_cache_in_out_bits_req_info_vpn;
  wire u_arb_cache_in_out_valid;
  wire u_arb_hptw_req_in_0_ready;
  wire u_arb_hptw_req_in_1_ready;
  wire [37:0] u_arb_hptw_req_out_bits_gvpn;
  wire [2:0] u_arb_hptw_req_out_bits_id;
  wire [1:0] u_arb_hptw_req_out_bits_source;
  wire u_arb_hptw_req_out_valid;
  wire u_arb_hptw_resp_in_1_ready;
  wire [2:0] u_arb_hptw_resp_out_bits_id;
  wire [1:0] u_arb_hptw_resp_out_bits_resp_entry_level;
  wire u_arb_hptw_resp_out_bits_resp_entry_n;
  wire [1:0] u_arb_hptw_resp_out_bits_resp_entry_pbmt;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_a;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_d;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_g;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_r;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_u;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_w;
  wire u_arb_hptw_resp_out_bits_resp_entry_perm_x;
  wire [37:0] u_arb_hptw_resp_out_bits_resp_entry_ppn;
  wire [37:0] u_arb_hptw_resp_out_bits_resp_entry_tag;
  wire [13:0] u_arb_hptw_resp_out_bits_resp_entry_vmid;
  wire u_arb_hptw_resp_out_bits_resp_gaf;
  wire u_arb_hptw_resp_out_bits_resp_gpf;
  wire u_arb_hptw_resp_out_valid;
  wire u_arb_mq_in_0_ready;
  wire u_arb_mq_in_1_ready;
  wire u_arb_mq_out_bits_isLLptw;
  wire [1:0] u_arb_mq_out_bits_req_info_s2xlate;
  wire [1:0] u_arb_mq_out_bits_req_info_source;
  wire [37:0] u_arb_mq_out_bits_req_info_vpn;
  wire u_arb_mq_out_valid;
  wire u_arb_tlb_chosen;
  wire u_arb_tlb_in_0_ready;
  wire u_arb_tlb_in_1_ready;
  wire [1:0] u_arb_tlb_out_bits_s2xlate;
  wire [37:0] u_arb_tlb_out_bits_vpn;
  wire u_arb_tlb_out_valid;
  wire u_bitmap_arb_in_0_ready;
  wire u_bitmap_arb_in_1_ready;
  wire u_bitmap_arb_in_2_ready;
  wire [35:0] u_bitmap_arb_out_bits_bmppn;
  wire u_bitmap_arb_out_bits_hptw_bypassed;
  wire [2:0] u_bitmap_arb_out_bits_id;
  wire [1:0] u_bitmap_arb_out_bits_level;
  wire u_bitmap_arb_out_bits_n;
  wire [1:0] u_bitmap_arb_out_bits_s2xlate;
  wire [37:0] u_bitmap_arb_out_bits_vpn;
  wire [3:0] u_bitmap_arb_out_bits_way_info;
  wire u_bitmap_arb_out_valid;
  wire u_bitmap_cache_boreChildrenBd_bore_ack;
  wire [89:0] u_bitmap_cache_boreChildrenBd_bore_outdata;
  wire [7:0] u_bitmap_cache_req_bits_order;
  wire [35:0] u_bitmap_cache_req_bits_tag;
  wire u_bitmap_cache_req_ready;
  wire u_bitmap_cache_req_valid;
  wire u_bitmap_cache_resp_bits_cfs_0;
  wire u_bitmap_cache_resp_bits_cfs_1;
  wire u_bitmap_cache_resp_bits_cfs_2;
  wire u_bitmap_cache_resp_bits_cfs_3;
  wire u_bitmap_cache_resp_bits_cfs_4;
  wire u_bitmap_cache_resp_bits_cfs_5;
  wire u_bitmap_cache_resp_bits_cfs_6;
  wire u_bitmap_cache_resp_bits_cfs_7;
  wire u_bitmap_cache_resp_bits_hit;
  wire [7:0] u_bitmap_cache_resp_bits_order;
  wire u_bitmap_cache_resp_ready;
  wire u_bitmap_cache_resp_valid;
  wire [47:0] u_bitmap_mem_req_bits_addr;
  wire [3:0] u_bitmap_mem_req_bits_id;
  wire u_bitmap_mem_req_valid;
  wire [47:0] u_bitmap_pmp_req_bits_addr;
  wire [63:0] u_bitmap_refill_bits_data;
  wire [35:0] u_bitmap_refill_bits_tag;
  wire u_bitmap_refill_valid;
  wire u_bitmap_req_ready;
  wire u_bitmap_resp_bits_cf;
  wire u_bitmap_resp_bits_cfs_0;
  wire u_bitmap_resp_bits_cfs_1;
  wire u_bitmap_resp_bits_cfs_2;
  wire u_bitmap_resp_bits_cfs_3;
  wire u_bitmap_resp_bits_cfs_4;
  wire u_bitmap_resp_bits_cfs_5;
  wire u_bitmap_resp_bits_cfs_6;
  wire u_bitmap_resp_bits_cfs_7;
  wire [2:0] u_bitmap_resp_bits_id;
  wire u_bitmap_resp_valid;
  wire u_bitmap_wakeup_bits_check_success;
  wire [2:0] u_bitmap_wakeup_bits_pte_index;
  wire [1:0] u_bitmap_wakeup_bits_s2xlate;
  wire [5:0] u_bitmap_wakeup_bits_setIndex;
  wire [37:0] u_bitmap_wakeup_bits_tag;
  wire [3:0] u_bitmap_wakeup_bits_way_info;
  wire u_bitmap_wakeup_valid;
  wire u_csr_delay_out_hPBMTE;
  wire u_csr_delay_out_hgatp_changed;
  wire [3:0] u_csr_delay_out_hgatp_mode;
  wire [43:0] u_csr_delay_out_hgatp_ppn;
  wire [15:0] u_csr_delay_out_hgatp_vmid;
  wire u_csr_delay_out_mPBMTE;
  wire u_csr_delay_out_mbmc_BCLEAR;
  wire [57:0] u_csr_delay_out_mbmc_BMA;
  wire u_csr_delay_out_mbmc_BME;
  wire u_csr_delay_out_mbmc_CMODE;
  wire u_csr_delay_out_priv_debug;
  wire u_csr_delay_out_priv_virt;
  wire u_csr_delay_out_priv_virt_changed;
  wire [15:0] u_csr_delay_out_satp_asid;
  wire u_csr_delay_out_satp_changed;
  wire [3:0] u_csr_delay_out_satp_mode;
  wire [43:0] u_csr_delay_out_satp_ppn;
  wire [15:0] u_csr_delay_out_vsatp_asid;
  wire u_csr_delay_out_vsatp_changed;
  wire [3:0] u_csr_delay_out_vsatp_mode;
  wire [43:0] u_csr_delay_out_vsatp_ppn;
  wire [35:0] u_hptw_bitmap_req_bits_bmppn;
  wire u_hptw_bitmap_req_bits_hptw_bypassed;
  wire [1:0] u_hptw_bitmap_req_bits_level;
  wire u_hptw_bitmap_req_bits_n;
  wire [37:0] u_hptw_bitmap_req_bits_vpn;
  wire [3:0] u_hptw_bitmap_req_bits_way_info;
  wire u_hptw_bitmap_req_valid;
  wire u_hptw_bitmap_resp_ready;
  wire [47:0] u_hptw_mem_req_bits_addr;
  wire u_hptw_mem_req_bits_hptw_bypassed;
  wire u_hptw_mem_req_valid;
  wire [47:0] u_hptw_pmp_req_bits_addr;
  wire [1:0] u_hptw_refill_level;
  wire [1:0] u_hptw_refill_req_info_source;
  wire [37:0] u_hptw_refill_req_info_vpn;
  wire u_hptw_req_ready;
  wire [3:0] u_hptw_resp_bits_id;
  wire [1:0] u_hptw_resp_bits_resp_entry_level;
  wire u_hptw_resp_bits_resp_entry_n;
  wire [1:0] u_hptw_resp_bits_resp_entry_pbmt;
  wire u_hptw_resp_bits_resp_entry_perm_a;
  wire u_hptw_resp_bits_resp_entry_perm_d;
  wire u_hptw_resp_bits_resp_entry_perm_g;
  wire u_hptw_resp_bits_resp_entry_perm_r;
  wire u_hptw_resp_bits_resp_entry_perm_u;
  wire u_hptw_resp_bits_resp_entry_perm_w;
  wire u_hptw_resp_bits_resp_entry_perm_x;
  wire [37:0] u_hptw_resp_bits_resp_entry_ppn;
  wire [37:0] u_hptw_resp_bits_resp_entry_tag;
  wire [13:0] u_hptw_resp_bits_resp_entry_vmid;
  wire u_hptw_resp_bits_resp_gaf;
  wire u_hptw_resp_bits_resp_gpf;
  wire u_hptw_resp_valid;
  wire [35:0] u_llptw_bitmap_req_bits_bmppn;
  wire [2:0] u_llptw_bitmap_req_bits_id;
  wire u_llptw_bitmap_req_bits_n;
  wire [1:0] u_llptw_bitmap_req_bits_s2xlate;
  wire [37:0] u_llptw_bitmap_req_bits_vpn;
  wire [3:0] u_llptw_bitmap_req_bits_way_info;
  wire u_llptw_bitmap_req_valid;
  wire u_llptw_bitmap_resp_ready;
  wire [1:0] u_llptw_cache_bits_s2xlate;
  wire [1:0] u_llptw_cache_bits_source;
  wire [37:0] u_llptw_cache_bits_vpn;
  wire u_llptw_cache_valid;
  wire [43:0] u_llptw_hptw_req_bits_gvpn;
  wire [2:0] u_llptw_hptw_req_bits_id;
  wire [1:0] u_llptw_hptw_req_bits_source;
  wire u_llptw_hptw_req_valid;
  wire u_llptw_in_ready;
  wire u_llptw_mem_buffer_it_0;
  wire u_llptw_mem_buffer_it_1;
  wire u_llptw_mem_buffer_it_2;
  wire u_llptw_mem_buffer_it_3;
  wire u_llptw_mem_buffer_it_4;
  wire u_llptw_mem_buffer_it_5;
  wire [2:0] u_llptw_mem_enq_ptr;
  wire [1:0] u_llptw_mem_refill_s2xlate;
  wire [1:0] u_llptw_mem_refill_source;
  wire [37:0] u_llptw_mem_refill_vpn;
  wire [47:0] u_llptw_mem_req_bits_addr;
  wire [3:0] u_llptw_mem_req_bits_id;
  wire u_llptw_mem_req_valid;
  wire u_llptw_out_bits_af;
  wire u_llptw_out_bits_bitmapCheck_cfs_0;
  wire u_llptw_out_bits_bitmapCheck_cfs_1;
  wire u_llptw_out_bits_bitmapCheck_cfs_2;
  wire u_llptw_out_bits_bitmapCheck_cfs_3;
  wire u_llptw_out_bits_bitmapCheck_cfs_4;
  wire u_llptw_out_bits_bitmapCheck_cfs_5;
  wire u_llptw_out_bits_bitmapCheck_cfs_6;
  wire u_llptw_out_bits_bitmapCheck_cfs_7;
  wire u_llptw_out_bits_bitmapCheck_jmp_bitmap_check;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_0;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_1;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_2;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_3;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_4;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_5;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_6;
  wire [63:0] u_llptw_out_bits_bitmapCheck_ptes_7;
  wire u_llptw_out_bits_first_s2xlate_fault;
  wire [1:0] u_llptw_out_bits_h_resp_entry_level;
  wire u_llptw_out_bits_h_resp_entry_n;
  wire [1:0] u_llptw_out_bits_h_resp_entry_pbmt;
  wire u_llptw_out_bits_h_resp_entry_perm_a;
  wire u_llptw_out_bits_h_resp_entry_perm_d;
  wire u_llptw_out_bits_h_resp_entry_perm_g;
  wire u_llptw_out_bits_h_resp_entry_perm_r;
  wire u_llptw_out_bits_h_resp_entry_perm_u;
  wire u_llptw_out_bits_h_resp_entry_perm_w;
  wire u_llptw_out_bits_h_resp_entry_perm_x;
  wire [37:0] u_llptw_out_bits_h_resp_entry_ppn;
  wire [37:0] u_llptw_out_bits_h_resp_entry_tag;
  wire [13:0] u_llptw_out_bits_h_resp_entry_vmid;
  wire u_llptw_out_bits_h_resp_gaf;
  wire u_llptw_out_bits_h_resp_gpf;
  wire [3:0] u_llptw_out_bits_id;
  wire [1:0] u_llptw_out_bits_req_info_s2xlate;
  wire [1:0] u_llptw_out_bits_req_info_source;
  wire [37:0] u_llptw_out_bits_req_info_vpn;
  wire u_llptw_out_valid;
  wire [5:0] u_llptw_perf_0_value;
  wire [5:0] u_llptw_perf_1_value;
  wire [5:0] u_llptw_perf_2_value;
  wire [5:0] u_llptw_perf_3_value;
  wire [47:0] u_llptw_pmp_0_req_bits_addr;
  wire [47:0] u_llptw_pmp_1_req_bits_addr;
  wire u_mem_arb_in_0_ready;
  wire u_mem_arb_in_1_ready;
  wire u_mem_arb_in_2_ready;
  wire u_mem_arb_in_3_ready;
  wire [47:0] u_mem_arb_out_bits_addr;
  wire u_mem_arb_out_bits_hptw_bypassed;
  wire [3:0] u_mem_arb_out_bits_id;
  wire u_mem_arb_out_valid;
  wire u_merge_arb_0_in_0_ready;
  wire u_merge_arb_0_in_1_ready;
  wire u_merge_arb_0_in_2_ready;
  wire u_merge_arb_0_out_bits_s1_entry_0_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_0_asid;
  wire u_merge_arb_0_out_bits_s1_entry_0_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_0_level;
  wire u_merge_arb_0_out_bits_s1_entry_0_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_0_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_0_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_0_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_0_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_0_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_0_tag;
  wire u_merge_arb_0_out_bits_s1_entry_0_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_0_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_1_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_1_asid;
  wire u_merge_arb_0_out_bits_s1_entry_1_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_1_level;
  wire u_merge_arb_0_out_bits_s1_entry_1_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_1_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_1_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_1_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_1_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_1_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_1_tag;
  wire u_merge_arb_0_out_bits_s1_entry_1_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_1_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_2_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_2_asid;
  wire u_merge_arb_0_out_bits_s1_entry_2_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_2_level;
  wire u_merge_arb_0_out_bits_s1_entry_2_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_2_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_2_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_2_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_2_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_2_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_2_tag;
  wire u_merge_arb_0_out_bits_s1_entry_2_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_2_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_3_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_3_asid;
  wire u_merge_arb_0_out_bits_s1_entry_3_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_3_level;
  wire u_merge_arb_0_out_bits_s1_entry_3_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_3_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_3_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_3_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_3_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_3_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_3_tag;
  wire u_merge_arb_0_out_bits_s1_entry_3_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_3_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_4_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_4_asid;
  wire u_merge_arb_0_out_bits_s1_entry_4_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_4_level;
  wire u_merge_arb_0_out_bits_s1_entry_4_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_4_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_4_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_4_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_4_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_4_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_4_tag;
  wire u_merge_arb_0_out_bits_s1_entry_4_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_4_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_5_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_5_asid;
  wire u_merge_arb_0_out_bits_s1_entry_5_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_5_level;
  wire u_merge_arb_0_out_bits_s1_entry_5_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_5_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_5_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_5_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_5_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_5_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_5_tag;
  wire u_merge_arb_0_out_bits_s1_entry_5_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_5_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_6_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_6_asid;
  wire u_merge_arb_0_out_bits_s1_entry_6_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_6_level;
  wire u_merge_arb_0_out_bits_s1_entry_6_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_6_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_6_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_6_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_6_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_6_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_6_tag;
  wire u_merge_arb_0_out_bits_s1_entry_6_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_6_vmid;
  wire u_merge_arb_0_out_bits_s1_entry_7_af;
  wire [15:0] u_merge_arb_0_out_bits_s1_entry_7_asid;
  wire u_merge_arb_0_out_bits_s1_entry_7_cf;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_7_level;
  wire u_merge_arb_0_out_bits_s1_entry_7_n;
  wire [1:0] u_merge_arb_0_out_bits_s1_entry_7_pbmt;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_a;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_d;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_g;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_r;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_u;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_w;
  wire u_merge_arb_0_out_bits_s1_entry_7_perm_x;
  wire u_merge_arb_0_out_bits_s1_entry_7_pf;
  wire [40:0] u_merge_arb_0_out_bits_s1_entry_7_ppn;
  wire [2:0] u_merge_arb_0_out_bits_s1_entry_7_ppn_low;
  wire [34:0] u_merge_arb_0_out_bits_s1_entry_7_tag;
  wire u_merge_arb_0_out_bits_s1_entry_7_v;
  wire [13:0] u_merge_arb_0_out_bits_s1_entry_7_vmid;
  wire u_merge_arb_0_out_bits_s1_not_merge;
  wire u_merge_arb_0_out_bits_s1_not_super;
  wire u_merge_arb_0_out_bits_s1_pteidx_0;
  wire u_merge_arb_0_out_bits_s1_pteidx_1;
  wire u_merge_arb_0_out_bits_s1_pteidx_2;
  wire u_merge_arb_0_out_bits_s1_pteidx_3;
  wire u_merge_arb_0_out_bits_s1_pteidx_4;
  wire u_merge_arb_0_out_bits_s1_pteidx_5;
  wire u_merge_arb_0_out_bits_s1_pteidx_6;
  wire u_merge_arb_0_out_bits_s1_pteidx_7;
  wire [1:0] u_merge_arb_0_out_bits_s2_entry_level;
  wire u_merge_arb_0_out_bits_s2_entry_n;
  wire [1:0] u_merge_arb_0_out_bits_s2_entry_pbmt;
  wire u_merge_arb_0_out_bits_s2_entry_perm_a;
  wire u_merge_arb_0_out_bits_s2_entry_perm_d;
  wire u_merge_arb_0_out_bits_s2_entry_perm_g;
  wire u_merge_arb_0_out_bits_s2_entry_perm_r;
  wire u_merge_arb_0_out_bits_s2_entry_perm_u;
  wire u_merge_arb_0_out_bits_s2_entry_perm_w;
  wire u_merge_arb_0_out_bits_s2_entry_perm_x;
  wire [37:0] u_merge_arb_0_out_bits_s2_entry_ppn;
  wire [37:0] u_merge_arb_0_out_bits_s2_entry_tag;
  wire [13:0] u_merge_arb_0_out_bits_s2_entry_vmid;
  wire u_merge_arb_0_out_bits_s2_gaf;
  wire u_merge_arb_0_out_bits_s2_gpf;
  wire [1:0] u_merge_arb_0_out_bits_s2xlate;
  wire u_merge_arb_0_out_valid;
  wire u_merge_arb_1_in_0_ready;
  wire u_merge_arb_1_in_1_ready;
  wire u_merge_arb_1_in_2_ready;
  wire u_merge_arb_1_out_bits_s1_entry_0_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_0_asid;
  wire u_merge_arb_1_out_bits_s1_entry_0_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_0_level;
  wire u_merge_arb_1_out_bits_s1_entry_0_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_0_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_0_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_0_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_0_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_0_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_0_tag;
  wire u_merge_arb_1_out_bits_s1_entry_0_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_0_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_1_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_1_asid;
  wire u_merge_arb_1_out_bits_s1_entry_1_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_1_level;
  wire u_merge_arb_1_out_bits_s1_entry_1_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_1_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_1_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_1_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_1_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_1_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_1_tag;
  wire u_merge_arb_1_out_bits_s1_entry_1_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_1_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_2_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_2_asid;
  wire u_merge_arb_1_out_bits_s1_entry_2_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_2_level;
  wire u_merge_arb_1_out_bits_s1_entry_2_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_2_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_2_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_2_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_2_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_2_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_2_tag;
  wire u_merge_arb_1_out_bits_s1_entry_2_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_2_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_3_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_3_asid;
  wire u_merge_arb_1_out_bits_s1_entry_3_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_3_level;
  wire u_merge_arb_1_out_bits_s1_entry_3_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_3_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_3_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_3_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_3_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_3_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_3_tag;
  wire u_merge_arb_1_out_bits_s1_entry_3_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_3_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_4_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_4_asid;
  wire u_merge_arb_1_out_bits_s1_entry_4_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_4_level;
  wire u_merge_arb_1_out_bits_s1_entry_4_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_4_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_4_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_4_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_4_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_4_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_4_tag;
  wire u_merge_arb_1_out_bits_s1_entry_4_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_4_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_5_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_5_asid;
  wire u_merge_arb_1_out_bits_s1_entry_5_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_5_level;
  wire u_merge_arb_1_out_bits_s1_entry_5_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_5_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_5_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_5_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_5_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_5_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_5_tag;
  wire u_merge_arb_1_out_bits_s1_entry_5_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_5_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_6_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_6_asid;
  wire u_merge_arb_1_out_bits_s1_entry_6_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_6_level;
  wire u_merge_arb_1_out_bits_s1_entry_6_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_6_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_6_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_6_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_6_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_6_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_6_tag;
  wire u_merge_arb_1_out_bits_s1_entry_6_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_6_vmid;
  wire u_merge_arb_1_out_bits_s1_entry_7_af;
  wire [15:0] u_merge_arb_1_out_bits_s1_entry_7_asid;
  wire u_merge_arb_1_out_bits_s1_entry_7_cf;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_7_level;
  wire u_merge_arb_1_out_bits_s1_entry_7_n;
  wire [1:0] u_merge_arb_1_out_bits_s1_entry_7_pbmt;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_a;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_d;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_g;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_r;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_u;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_w;
  wire u_merge_arb_1_out_bits_s1_entry_7_perm_x;
  wire u_merge_arb_1_out_bits_s1_entry_7_pf;
  wire [40:0] u_merge_arb_1_out_bits_s1_entry_7_ppn;
  wire [2:0] u_merge_arb_1_out_bits_s1_entry_7_ppn_low;
  wire [34:0] u_merge_arb_1_out_bits_s1_entry_7_tag;
  wire u_merge_arb_1_out_bits_s1_entry_7_v;
  wire [13:0] u_merge_arb_1_out_bits_s1_entry_7_vmid;
  wire u_merge_arb_1_out_bits_s1_not_merge;
  wire u_merge_arb_1_out_bits_s1_not_super;
  wire u_merge_arb_1_out_bits_s1_pteidx_0;
  wire u_merge_arb_1_out_bits_s1_pteidx_1;
  wire u_merge_arb_1_out_bits_s1_pteidx_2;
  wire u_merge_arb_1_out_bits_s1_pteidx_3;
  wire u_merge_arb_1_out_bits_s1_pteidx_4;
  wire u_merge_arb_1_out_bits_s1_pteidx_5;
  wire u_merge_arb_1_out_bits_s1_pteidx_6;
  wire u_merge_arb_1_out_bits_s1_pteidx_7;
  wire [1:0] u_merge_arb_1_out_bits_s2_entry_level;
  wire u_merge_arb_1_out_bits_s2_entry_n;
  wire [1:0] u_merge_arb_1_out_bits_s2_entry_pbmt;
  wire u_merge_arb_1_out_bits_s2_entry_perm_a;
  wire u_merge_arb_1_out_bits_s2_entry_perm_d;
  wire u_merge_arb_1_out_bits_s2_entry_perm_g;
  wire u_merge_arb_1_out_bits_s2_entry_perm_r;
  wire u_merge_arb_1_out_bits_s2_entry_perm_u;
  wire u_merge_arb_1_out_bits_s2_entry_perm_w;
  wire u_merge_arb_1_out_bits_s2_entry_perm_x;
  wire [37:0] u_merge_arb_1_out_bits_s2_entry_ppn;
  wire [37:0] u_merge_arb_1_out_bits_s2_entry_tag;
  wire [13:0] u_merge_arb_1_out_bits_s2_entry_vmid;
  wire u_merge_arb_1_out_bits_s2_gaf;
  wire u_merge_arb_1_out_bits_s2_gpf;
  wire [1:0] u_merge_arb_1_out_bits_s2xlate;
  wire u_merge_arb_1_out_valid;
  wire u_miss_queue_in_ready;
  wire [2:0] u_miss_queue_out_bits_hptwId;
  wire u_miss_queue_out_bits_isHptwReq;
  wire u_miss_queue_out_bits_isLLptw;
  wire [1:0] u_miss_queue_out_bits_req_info_s2xlate;
  wire [1:0] u_miss_queue_out_bits_req_info_source;
  wire [37:0] u_miss_queue_out_bits_req_info_vpn;
  wire u_miss_queue_out_valid;
  wire u_out_arb_0_in_0_ready;
  wire [2:0] u_out_arb_0_out_bits_s1_addr_low;
  wire u_out_arb_0_out_bits_s1_af;
  wire [15:0] u_out_arb_0_out_bits_s1_entry_asid;
  wire [1:0] u_out_arb_0_out_bits_s1_entry_level;
  wire u_out_arb_0_out_bits_s1_entry_n;
  wire [1:0] u_out_arb_0_out_bits_s1_entry_pbmt;
  wire u_out_arb_0_out_bits_s1_entry_perm_a;
  wire u_out_arb_0_out_bits_s1_entry_perm_d;
  wire u_out_arb_0_out_bits_s1_entry_perm_g;
  wire u_out_arb_0_out_bits_s1_entry_perm_r;
  wire u_out_arb_0_out_bits_s1_entry_perm_u;
  wire u_out_arb_0_out_bits_s1_entry_perm_w;
  wire u_out_arb_0_out_bits_s1_entry_perm_x;
  wire [40:0] u_out_arb_0_out_bits_s1_entry_ppn;
  wire [34:0] u_out_arb_0_out_bits_s1_entry_tag;
  wire u_out_arb_0_out_bits_s1_entry_v;
  wire [13:0] u_out_arb_0_out_bits_s1_entry_vmid;
  wire u_out_arb_0_out_bits_s1_pf;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_0;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_1;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_2;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_3;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_4;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_5;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_6;
  wire [2:0] u_out_arb_0_out_bits_s1_ppn_low_7;
  wire u_out_arb_0_out_bits_s1_pteidx_0;
  wire u_out_arb_0_out_bits_s1_pteidx_1;
  wire u_out_arb_0_out_bits_s1_pteidx_2;
  wire u_out_arb_0_out_bits_s1_pteidx_3;
  wire u_out_arb_0_out_bits_s1_pteidx_4;
  wire u_out_arb_0_out_bits_s1_pteidx_5;
  wire u_out_arb_0_out_bits_s1_pteidx_6;
  wire u_out_arb_0_out_bits_s1_pteidx_7;
  wire u_out_arb_0_out_bits_s1_valididx_0;
  wire u_out_arb_0_out_bits_s1_valididx_1;
  wire u_out_arb_0_out_bits_s1_valididx_2;
  wire u_out_arb_0_out_bits_s1_valididx_3;
  wire u_out_arb_0_out_bits_s1_valididx_4;
  wire u_out_arb_0_out_bits_s1_valididx_5;
  wire u_out_arb_0_out_bits_s1_valididx_6;
  wire u_out_arb_0_out_bits_s1_valididx_7;
  wire [1:0] u_out_arb_0_out_bits_s2_entry_level;
  wire u_out_arb_0_out_bits_s2_entry_n;
  wire [1:0] u_out_arb_0_out_bits_s2_entry_pbmt;
  wire u_out_arb_0_out_bits_s2_entry_perm_a;
  wire u_out_arb_0_out_bits_s2_entry_perm_d;
  wire u_out_arb_0_out_bits_s2_entry_perm_g;
  wire u_out_arb_0_out_bits_s2_entry_perm_r;
  wire u_out_arb_0_out_bits_s2_entry_perm_u;
  wire u_out_arb_0_out_bits_s2_entry_perm_w;
  wire u_out_arb_0_out_bits_s2_entry_perm_x;
  wire [37:0] u_out_arb_0_out_bits_s2_entry_ppn;
  wire [37:0] u_out_arb_0_out_bits_s2_entry_tag;
  wire [13:0] u_out_arb_0_out_bits_s2_entry_vmid;
  wire u_out_arb_0_out_bits_s2_gaf;
  wire u_out_arb_0_out_bits_s2_gpf;
  wire [1:0] u_out_arb_0_out_bits_s2xlate;
  wire u_out_arb_0_out_valid;
  wire u_out_arb_1_in_0_ready;
  wire [2:0] u_out_arb_1_out_bits_s1_addr_low;
  wire u_out_arb_1_out_bits_s1_af;
  wire [15:0] u_out_arb_1_out_bits_s1_entry_asid;
  wire [1:0] u_out_arb_1_out_bits_s1_entry_level;
  wire u_out_arb_1_out_bits_s1_entry_n;
  wire [1:0] u_out_arb_1_out_bits_s1_entry_pbmt;
  wire u_out_arb_1_out_bits_s1_entry_perm_a;
  wire u_out_arb_1_out_bits_s1_entry_perm_d;
  wire u_out_arb_1_out_bits_s1_entry_perm_g;
  wire u_out_arb_1_out_bits_s1_entry_perm_r;
  wire u_out_arb_1_out_bits_s1_entry_perm_u;
  wire u_out_arb_1_out_bits_s1_entry_perm_w;
  wire u_out_arb_1_out_bits_s1_entry_perm_x;
  wire [40:0] u_out_arb_1_out_bits_s1_entry_ppn;
  wire [34:0] u_out_arb_1_out_bits_s1_entry_tag;
  wire u_out_arb_1_out_bits_s1_entry_v;
  wire [13:0] u_out_arb_1_out_bits_s1_entry_vmid;
  wire u_out_arb_1_out_bits_s1_pf;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_0;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_1;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_2;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_3;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_4;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_5;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_6;
  wire [2:0] u_out_arb_1_out_bits_s1_ppn_low_7;
  wire u_out_arb_1_out_bits_s1_pteidx_0;
  wire u_out_arb_1_out_bits_s1_pteidx_1;
  wire u_out_arb_1_out_bits_s1_pteidx_2;
  wire u_out_arb_1_out_bits_s1_pteidx_3;
  wire u_out_arb_1_out_bits_s1_pteidx_4;
  wire u_out_arb_1_out_bits_s1_pteidx_5;
  wire u_out_arb_1_out_bits_s1_pteidx_6;
  wire u_out_arb_1_out_bits_s1_pteidx_7;
  wire u_out_arb_1_out_bits_s1_valididx_0;
  wire u_out_arb_1_out_bits_s1_valididx_1;
  wire u_out_arb_1_out_bits_s1_valididx_2;
  wire u_out_arb_1_out_bits_s1_valididx_3;
  wire u_out_arb_1_out_bits_s1_valididx_4;
  wire u_out_arb_1_out_bits_s1_valididx_5;
  wire u_out_arb_1_out_bits_s1_valididx_6;
  wire u_out_arb_1_out_bits_s1_valididx_7;
  wire [1:0] u_out_arb_1_out_bits_s2_entry_level;
  wire u_out_arb_1_out_bits_s2_entry_n;
  wire [1:0] u_out_arb_1_out_bits_s2_entry_pbmt;
  wire u_out_arb_1_out_bits_s2_entry_perm_a;
  wire u_out_arb_1_out_bits_s2_entry_perm_d;
  wire u_out_arb_1_out_bits_s2_entry_perm_g;
  wire u_out_arb_1_out_bits_s2_entry_perm_r;
  wire u_out_arb_1_out_bits_s2_entry_perm_u;
  wire u_out_arb_1_out_bits_s2_entry_perm_w;
  wire u_out_arb_1_out_bits_s2_entry_perm_x;
  wire [37:0] u_out_arb_1_out_bits_s2_entry_ppn;
  wire [37:0] u_out_arb_1_out_bits_s2_entry_tag;
  wire [13:0] u_out_arb_1_out_bits_s2_entry_vmid;
  wire u_out_arb_1_out_bits_s2_gaf;
  wire u_out_arb_1_out_bits_s2_gpf;
  wire [1:0] u_out_arb_1_out_bits_s2xlate;
  wire u_out_arb_1_out_valid;
  wire u_page_cache_bitmap_wakeup_ready;
  wire u_page_cache_boreChildrenBd_bore_1_ack;
  wire [113:0] u_page_cache_boreChildrenBd_bore_1_outdata;
  wire u_page_cache_boreChildrenBd_bore_ack;
  wire [130:0] u_page_cache_boreChildrenBd_bore_outdata;
  wire [3:0] u_page_cache_l0_way_info;
  wire [5:0] u_page_cache_perf_0_value;
  wire [5:0] u_page_cache_perf_1_value;
  wire [5:0] u_page_cache_perf_2_value;
  wire [5:0] u_page_cache_perf_3_value;
  wire [5:0] u_page_cache_perf_4_value;
  wire [5:0] u_page_cache_perf_5_value;
  wire [5:0] u_page_cache_perf_6_value;
  wire [5:0] u_page_cache_perf_7_value;
  wire u_page_cache_req_ready;
  wire u_page_cache_resp_bits_bypassed;
  wire u_page_cache_resp_bits_hit;
  wire u_page_cache_resp_bits_isFirst;
  wire u_page_cache_resp_bits_isHptwReq;
  wire u_page_cache_resp_bits_prefetch;
  wire [1:0] u_page_cache_resp_bits_req_info_s2xlate;
  wire [1:0] u_page_cache_resp_bits_req_info_source;
  wire [37:0] u_page_cache_resp_bits_req_info_vpn;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_0_asid;
  wire u_page_cache_resp_bits_stage1_entry_0_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_0_level;
  wire u_page_cache_resp_bits_stage1_entry_0_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_0_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_0_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_0_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_0_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_0_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_0_tag;
  wire u_page_cache_resp_bits_stage1_entry_0_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_0_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_1_asid;
  wire u_page_cache_resp_bits_stage1_entry_1_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_1_level;
  wire u_page_cache_resp_bits_stage1_entry_1_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_1_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_1_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_1_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_1_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_1_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_1_tag;
  wire u_page_cache_resp_bits_stage1_entry_1_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_1_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_2_asid;
  wire u_page_cache_resp_bits_stage1_entry_2_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_2_level;
  wire u_page_cache_resp_bits_stage1_entry_2_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_2_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_2_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_2_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_2_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_2_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_2_tag;
  wire u_page_cache_resp_bits_stage1_entry_2_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_2_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_3_asid;
  wire u_page_cache_resp_bits_stage1_entry_3_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_3_level;
  wire u_page_cache_resp_bits_stage1_entry_3_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_3_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_3_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_3_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_3_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_3_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_3_tag;
  wire u_page_cache_resp_bits_stage1_entry_3_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_3_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_4_asid;
  wire u_page_cache_resp_bits_stage1_entry_4_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_4_level;
  wire u_page_cache_resp_bits_stage1_entry_4_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_4_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_4_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_4_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_4_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_4_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_4_tag;
  wire u_page_cache_resp_bits_stage1_entry_4_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_4_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_5_asid;
  wire u_page_cache_resp_bits_stage1_entry_5_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_5_level;
  wire u_page_cache_resp_bits_stage1_entry_5_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_5_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_5_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_5_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_5_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_5_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_5_tag;
  wire u_page_cache_resp_bits_stage1_entry_5_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_5_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_6_asid;
  wire u_page_cache_resp_bits_stage1_entry_6_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_6_level;
  wire u_page_cache_resp_bits_stage1_entry_6_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_6_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_6_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_6_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_6_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_6_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_6_tag;
  wire u_page_cache_resp_bits_stage1_entry_6_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_6_vmid;
  wire [15:0] u_page_cache_resp_bits_stage1_entry_7_asid;
  wire u_page_cache_resp_bits_stage1_entry_7_cf;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_7_level;
  wire u_page_cache_resp_bits_stage1_entry_7_n;
  wire [1:0] u_page_cache_resp_bits_stage1_entry_7_pbmt;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_a;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_d;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_g;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_r;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_u;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_w;
  wire u_page_cache_resp_bits_stage1_entry_7_perm_x;
  wire u_page_cache_resp_bits_stage1_entry_7_pf;
  wire [40:0] u_page_cache_resp_bits_stage1_entry_7_ppn;
  wire [2:0] u_page_cache_resp_bits_stage1_entry_7_ppn_low;
  wire [34:0] u_page_cache_resp_bits_stage1_entry_7_tag;
  wire u_page_cache_resp_bits_stage1_entry_7_v;
  wire [13:0] u_page_cache_resp_bits_stage1_entry_7_vmid;
  wire u_page_cache_resp_bits_stage1_not_super;
  wire u_page_cache_resp_bits_stage1_pteidx_0;
  wire u_page_cache_resp_bits_stage1_pteidx_1;
  wire u_page_cache_resp_bits_stage1_pteidx_2;
  wire u_page_cache_resp_bits_stage1_pteidx_3;
  wire u_page_cache_resp_bits_stage1_pteidx_4;
  wire u_page_cache_resp_bits_stage1_pteidx_5;
  wire u_page_cache_resp_bits_stage1_pteidx_6;
  wire u_page_cache_resp_bits_stage1_pteidx_7;
  wire [1:0] u_page_cache_resp_bits_toFsm_bitmapCheck_SPlevel;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_0;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_1;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_2;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_3;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_4;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_5;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_6;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_7;
  wire [3:0] u_page_cache_resp_bits_toFsm_bitmapCheck_hitway;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_pte;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_0;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_1;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_2;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_3;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_4;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_5;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_6;
  wire [63:0] u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_7;
  wire u_page_cache_resp_bits_toFsm_bitmapCheck_toLLPTW;
  wire u_page_cache_resp_bits_toFsm_l1Hit;
  wire u_page_cache_resp_bits_toFsm_l2Hit;
  wire u_page_cache_resp_bits_toFsm_l3Hit;
  wire [37:0] u_page_cache_resp_bits_toFsm_ppn;
  wire u_page_cache_resp_bits_toFsm_stage1Hit;
  wire [1:0] u_page_cache_resp_bits_toHptw_bitmapCheck_SPlevel;
  wire u_page_cache_resp_bits_toHptw_bitmapCheck_fromSP;
  wire [3:0] u_page_cache_resp_bits_toHptw_bitmapCheck_hitway;
  wire u_page_cache_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_pte;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_0;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_1;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_2;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_3;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_4;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_5;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_6;
  wire [63:0] u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_7;
  wire u_page_cache_resp_bits_toHptw_bypassed;
  wire [2:0] u_page_cache_resp_bits_toHptw_id;
  wire u_page_cache_resp_bits_toHptw_l1Hit;
  wire u_page_cache_resp_bits_toHptw_l2Hit;
  wire u_page_cache_resp_bits_toHptw_l3Hit;
  wire [35:0] u_page_cache_resp_bits_toHptw_ppn;
  wire [1:0] u_page_cache_resp_bits_toHptw_resp_entry_level;
  wire u_page_cache_resp_bits_toHptw_resp_entry_n;
  wire [1:0] u_page_cache_resp_bits_toHptw_resp_entry_pbmt;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_a;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_d;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_g;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_r;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_u;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_w;
  wire u_page_cache_resp_bits_toHptw_resp_entry_perm_x;
  wire [37:0] u_page_cache_resp_bits_toHptw_resp_entry_ppn;
  wire [37:0] u_page_cache_resp_bits_toHptw_resp_entry_tag;
  wire [13:0] u_page_cache_resp_bits_toHptw_resp_entry_vmid;
  wire u_page_cache_resp_bits_toHptw_resp_gpf;
  wire u_page_cache_resp_valid;
  wire u_pmp_chk_bitmap_resp_atomic;
  wire u_pmp_chk_bitmap_resp_ld;
  wire u_pmp_chk_bitmap_resp_mmio;
  wire u_pmp_chk_hptw_resp_atomic;
  wire u_pmp_chk_hptw_resp_ld;
  wire u_pmp_chk_hptw_resp_mmio;
  wire u_pmp_chk_llptw0_resp_atomic;
  wire u_pmp_chk_llptw0_resp_ld;
  wire u_pmp_chk_llptw0_resp_mmio;
  wire u_pmp_chk_llptw1_resp_atomic;
  wire u_pmp_chk_llptw1_resp_ld;
  wire u_pmp_chk_llptw1_resp_mmio;
  wire u_pmp_chk_ptw_resp_atomic;
  wire u_pmp_chk_ptw_resp_ld;
  wire u_pmp_chk_ptw_resp_mmio;
  wire [45:0] u_pmp_pma_0_addr;
  wire [1:0] u_pmp_pma_0_cfg_a;
  wire u_pmp_pma_0_cfg_atomic;
  wire u_pmp_pma_0_cfg_c;
  wire u_pmp_pma_0_cfg_r;
  wire u_pmp_pma_0_cfg_w;
  wire u_pmp_pma_0_cfg_x;
  wire [47:0] u_pmp_pma_0_mask;
  wire [45:0] u_pmp_pma_10_addr;
  wire [1:0] u_pmp_pma_10_cfg_a;
  wire u_pmp_pma_10_cfg_atomic;
  wire u_pmp_pma_10_cfg_c;
  wire u_pmp_pma_10_cfg_r;
  wire u_pmp_pma_10_cfg_w;
  wire u_pmp_pma_10_cfg_x;
  wire [47:0] u_pmp_pma_10_mask;
  wire [45:0] u_pmp_pma_11_addr;
  wire [1:0] u_pmp_pma_11_cfg_a;
  wire u_pmp_pma_11_cfg_atomic;
  wire u_pmp_pma_11_cfg_c;
  wire u_pmp_pma_11_cfg_r;
  wire u_pmp_pma_11_cfg_w;
  wire u_pmp_pma_11_cfg_x;
  wire [47:0] u_pmp_pma_11_mask;
  wire [45:0] u_pmp_pma_12_addr;
  wire [1:0] u_pmp_pma_12_cfg_a;
  wire u_pmp_pma_12_cfg_atomic;
  wire u_pmp_pma_12_cfg_c;
  wire u_pmp_pma_12_cfg_r;
  wire u_pmp_pma_12_cfg_w;
  wire u_pmp_pma_12_cfg_x;
  wire [47:0] u_pmp_pma_12_mask;
  wire [45:0] u_pmp_pma_13_addr;
  wire [1:0] u_pmp_pma_13_cfg_a;
  wire u_pmp_pma_13_cfg_atomic;
  wire u_pmp_pma_13_cfg_c;
  wire u_pmp_pma_13_cfg_r;
  wire u_pmp_pma_13_cfg_w;
  wire u_pmp_pma_13_cfg_x;
  wire [47:0] u_pmp_pma_13_mask;
  wire [45:0] u_pmp_pma_14_addr;
  wire [1:0] u_pmp_pma_14_cfg_a;
  wire u_pmp_pma_14_cfg_atomic;
  wire u_pmp_pma_14_cfg_c;
  wire u_pmp_pma_14_cfg_r;
  wire u_pmp_pma_14_cfg_w;
  wire u_pmp_pma_14_cfg_x;
  wire [47:0] u_pmp_pma_14_mask;
  wire [45:0] u_pmp_pma_15_addr;
  wire [1:0] u_pmp_pma_15_cfg_a;
  wire u_pmp_pma_15_cfg_atomic;
  wire u_pmp_pma_15_cfg_c;
  wire u_pmp_pma_15_cfg_r;
  wire u_pmp_pma_15_cfg_w;
  wire u_pmp_pma_15_cfg_x;
  wire [47:0] u_pmp_pma_15_mask;
  wire [45:0] u_pmp_pma_16_addr;
  wire [1:0] u_pmp_pma_16_cfg_a;
  wire u_pmp_pma_16_cfg_atomic;
  wire u_pmp_pma_16_cfg_c;
  wire u_pmp_pma_16_cfg_r;
  wire u_pmp_pma_16_cfg_w;
  wire u_pmp_pma_16_cfg_x;
  wire [47:0] u_pmp_pma_16_mask;
  wire [45:0] u_pmp_pma_17_addr;
  wire [1:0] u_pmp_pma_17_cfg_a;
  wire u_pmp_pma_17_cfg_atomic;
  wire u_pmp_pma_17_cfg_c;
  wire u_pmp_pma_17_cfg_r;
  wire u_pmp_pma_17_cfg_w;
  wire u_pmp_pma_17_cfg_x;
  wire [47:0] u_pmp_pma_17_mask;
  wire [45:0] u_pmp_pma_18_addr;
  wire [1:0] u_pmp_pma_18_cfg_a;
  wire u_pmp_pma_18_cfg_atomic;
  wire u_pmp_pma_18_cfg_c;
  wire u_pmp_pma_18_cfg_r;
  wire u_pmp_pma_18_cfg_w;
  wire u_pmp_pma_18_cfg_x;
  wire [47:0] u_pmp_pma_18_mask;
  wire [45:0] u_pmp_pma_19_addr;
  wire [1:0] u_pmp_pma_19_cfg_a;
  wire u_pmp_pma_19_cfg_atomic;
  wire u_pmp_pma_19_cfg_c;
  wire u_pmp_pma_19_cfg_r;
  wire u_pmp_pma_19_cfg_w;
  wire u_pmp_pma_19_cfg_x;
  wire [47:0] u_pmp_pma_19_mask;
  wire [45:0] u_pmp_pma_1_addr;
  wire [1:0] u_pmp_pma_1_cfg_a;
  wire u_pmp_pma_1_cfg_atomic;
  wire u_pmp_pma_1_cfg_c;
  wire u_pmp_pma_1_cfg_r;
  wire u_pmp_pma_1_cfg_w;
  wire u_pmp_pma_1_cfg_x;
  wire [47:0] u_pmp_pma_1_mask;
  wire [45:0] u_pmp_pma_20_addr;
  wire [1:0] u_pmp_pma_20_cfg_a;
  wire u_pmp_pma_20_cfg_atomic;
  wire u_pmp_pma_20_cfg_c;
  wire u_pmp_pma_20_cfg_r;
  wire u_pmp_pma_20_cfg_w;
  wire u_pmp_pma_20_cfg_x;
  wire [47:0] u_pmp_pma_20_mask;
  wire [45:0] u_pmp_pma_21_addr;
  wire [1:0] u_pmp_pma_21_cfg_a;
  wire u_pmp_pma_21_cfg_atomic;
  wire u_pmp_pma_21_cfg_c;
  wire u_pmp_pma_21_cfg_r;
  wire u_pmp_pma_21_cfg_w;
  wire u_pmp_pma_21_cfg_x;
  wire [47:0] u_pmp_pma_21_mask;
  wire [45:0] u_pmp_pma_22_addr;
  wire [1:0] u_pmp_pma_22_cfg_a;
  wire u_pmp_pma_22_cfg_atomic;
  wire u_pmp_pma_22_cfg_c;
  wire u_pmp_pma_22_cfg_r;
  wire u_pmp_pma_22_cfg_w;
  wire u_pmp_pma_22_cfg_x;
  wire [47:0] u_pmp_pma_22_mask;
  wire [45:0] u_pmp_pma_23_addr;
  wire [1:0] u_pmp_pma_23_cfg_a;
  wire u_pmp_pma_23_cfg_atomic;
  wire u_pmp_pma_23_cfg_c;
  wire u_pmp_pma_23_cfg_r;
  wire u_pmp_pma_23_cfg_w;
  wire u_pmp_pma_23_cfg_x;
  wire [47:0] u_pmp_pma_23_mask;
  wire [45:0] u_pmp_pma_24_addr;
  wire [1:0] u_pmp_pma_24_cfg_a;
  wire u_pmp_pma_24_cfg_atomic;
  wire u_pmp_pma_24_cfg_c;
  wire u_pmp_pma_24_cfg_r;
  wire u_pmp_pma_24_cfg_w;
  wire u_pmp_pma_24_cfg_x;
  wire [47:0] u_pmp_pma_24_mask;
  wire [45:0] u_pmp_pma_25_addr;
  wire [1:0] u_pmp_pma_25_cfg_a;
  wire u_pmp_pma_25_cfg_atomic;
  wire u_pmp_pma_25_cfg_c;
  wire u_pmp_pma_25_cfg_r;
  wire u_pmp_pma_25_cfg_w;
  wire u_pmp_pma_25_cfg_x;
  wire [47:0] u_pmp_pma_25_mask;
  wire [45:0] u_pmp_pma_26_addr;
  wire [1:0] u_pmp_pma_26_cfg_a;
  wire u_pmp_pma_26_cfg_atomic;
  wire u_pmp_pma_26_cfg_c;
  wire u_pmp_pma_26_cfg_r;
  wire u_pmp_pma_26_cfg_w;
  wire u_pmp_pma_26_cfg_x;
  wire [47:0] u_pmp_pma_26_mask;
  wire [45:0] u_pmp_pma_27_addr;
  wire [1:0] u_pmp_pma_27_cfg_a;
  wire u_pmp_pma_27_cfg_atomic;
  wire u_pmp_pma_27_cfg_c;
  wire u_pmp_pma_27_cfg_r;
  wire u_pmp_pma_27_cfg_w;
  wire u_pmp_pma_27_cfg_x;
  wire [47:0] u_pmp_pma_27_mask;
  wire [45:0] u_pmp_pma_28_addr;
  wire [1:0] u_pmp_pma_28_cfg_a;
  wire u_pmp_pma_28_cfg_atomic;
  wire u_pmp_pma_28_cfg_c;
  wire u_pmp_pma_28_cfg_r;
  wire u_pmp_pma_28_cfg_w;
  wire u_pmp_pma_28_cfg_x;
  wire [47:0] u_pmp_pma_28_mask;
  wire [45:0] u_pmp_pma_29_addr;
  wire [1:0] u_pmp_pma_29_cfg_a;
  wire u_pmp_pma_29_cfg_atomic;
  wire u_pmp_pma_29_cfg_c;
  wire u_pmp_pma_29_cfg_r;
  wire u_pmp_pma_29_cfg_w;
  wire u_pmp_pma_29_cfg_x;
  wire [47:0] u_pmp_pma_29_mask;
  wire [45:0] u_pmp_pma_2_addr;
  wire [1:0] u_pmp_pma_2_cfg_a;
  wire u_pmp_pma_2_cfg_atomic;
  wire u_pmp_pma_2_cfg_c;
  wire u_pmp_pma_2_cfg_r;
  wire u_pmp_pma_2_cfg_w;
  wire u_pmp_pma_2_cfg_x;
  wire [47:0] u_pmp_pma_2_mask;
  wire [45:0] u_pmp_pma_30_addr;
  wire [1:0] u_pmp_pma_30_cfg_a;
  wire u_pmp_pma_30_cfg_atomic;
  wire u_pmp_pma_30_cfg_c;
  wire u_pmp_pma_30_cfg_r;
  wire u_pmp_pma_30_cfg_w;
  wire u_pmp_pma_30_cfg_x;
  wire [47:0] u_pmp_pma_30_mask;
  wire [45:0] u_pmp_pma_31_addr;
  wire [1:0] u_pmp_pma_31_cfg_a;
  wire u_pmp_pma_31_cfg_atomic;
  wire u_pmp_pma_31_cfg_c;
  wire u_pmp_pma_31_cfg_r;
  wire u_pmp_pma_31_cfg_w;
  wire u_pmp_pma_31_cfg_x;
  wire [47:0] u_pmp_pma_31_mask;
  wire [45:0] u_pmp_pma_3_addr;
  wire [1:0] u_pmp_pma_3_cfg_a;
  wire u_pmp_pma_3_cfg_atomic;
  wire u_pmp_pma_3_cfg_c;
  wire u_pmp_pma_3_cfg_r;
  wire u_pmp_pma_3_cfg_w;
  wire u_pmp_pma_3_cfg_x;
  wire [47:0] u_pmp_pma_3_mask;
  wire [45:0] u_pmp_pma_4_addr;
  wire [1:0] u_pmp_pma_4_cfg_a;
  wire u_pmp_pma_4_cfg_atomic;
  wire u_pmp_pma_4_cfg_c;
  wire u_pmp_pma_4_cfg_r;
  wire u_pmp_pma_4_cfg_w;
  wire u_pmp_pma_4_cfg_x;
  wire [47:0] u_pmp_pma_4_mask;
  wire [45:0] u_pmp_pma_5_addr;
  wire [1:0] u_pmp_pma_5_cfg_a;
  wire u_pmp_pma_5_cfg_atomic;
  wire u_pmp_pma_5_cfg_c;
  wire u_pmp_pma_5_cfg_r;
  wire u_pmp_pma_5_cfg_w;
  wire u_pmp_pma_5_cfg_x;
  wire [47:0] u_pmp_pma_5_mask;
  wire [45:0] u_pmp_pma_6_addr;
  wire [1:0] u_pmp_pma_6_cfg_a;
  wire u_pmp_pma_6_cfg_atomic;
  wire u_pmp_pma_6_cfg_c;
  wire u_pmp_pma_6_cfg_r;
  wire u_pmp_pma_6_cfg_w;
  wire u_pmp_pma_6_cfg_x;
  wire [47:0] u_pmp_pma_6_mask;
  wire [45:0] u_pmp_pma_7_addr;
  wire [1:0] u_pmp_pma_7_cfg_a;
  wire u_pmp_pma_7_cfg_atomic;
  wire u_pmp_pma_7_cfg_c;
  wire u_pmp_pma_7_cfg_r;
  wire u_pmp_pma_7_cfg_w;
  wire u_pmp_pma_7_cfg_x;
  wire [47:0] u_pmp_pma_7_mask;
  wire [45:0] u_pmp_pma_8_addr;
  wire [1:0] u_pmp_pma_8_cfg_a;
  wire u_pmp_pma_8_cfg_atomic;
  wire u_pmp_pma_8_cfg_c;
  wire u_pmp_pma_8_cfg_r;
  wire u_pmp_pma_8_cfg_w;
  wire u_pmp_pma_8_cfg_x;
  wire [47:0] u_pmp_pma_8_mask;
  wire [45:0] u_pmp_pma_9_addr;
  wire [1:0] u_pmp_pma_9_cfg_a;
  wire u_pmp_pma_9_cfg_atomic;
  wire u_pmp_pma_9_cfg_c;
  wire u_pmp_pma_9_cfg_r;
  wire u_pmp_pma_9_cfg_w;
  wire u_pmp_pma_9_cfg_x;
  wire [47:0] u_pmp_pma_9_mask;
  wire [45:0] u_pmp_pmp_0_addr;
  wire [1:0] u_pmp_pmp_0_cfg_a;
  wire u_pmp_pmp_0_cfg_l;
  wire u_pmp_pmp_0_cfg_r;
  wire u_pmp_pmp_0_cfg_w;
  wire u_pmp_pmp_0_cfg_x;
  wire [47:0] u_pmp_pmp_0_mask;
  wire [45:0] u_pmp_pmp_10_addr;
  wire [1:0] u_pmp_pmp_10_cfg_a;
  wire u_pmp_pmp_10_cfg_l;
  wire u_pmp_pmp_10_cfg_r;
  wire u_pmp_pmp_10_cfg_w;
  wire u_pmp_pmp_10_cfg_x;
  wire [47:0] u_pmp_pmp_10_mask;
  wire [45:0] u_pmp_pmp_11_addr;
  wire [1:0] u_pmp_pmp_11_cfg_a;
  wire u_pmp_pmp_11_cfg_l;
  wire u_pmp_pmp_11_cfg_r;
  wire u_pmp_pmp_11_cfg_w;
  wire u_pmp_pmp_11_cfg_x;
  wire [47:0] u_pmp_pmp_11_mask;
  wire [45:0] u_pmp_pmp_12_addr;
  wire [1:0] u_pmp_pmp_12_cfg_a;
  wire u_pmp_pmp_12_cfg_l;
  wire u_pmp_pmp_12_cfg_r;
  wire u_pmp_pmp_12_cfg_w;
  wire u_pmp_pmp_12_cfg_x;
  wire [47:0] u_pmp_pmp_12_mask;
  wire [45:0] u_pmp_pmp_13_addr;
  wire [1:0] u_pmp_pmp_13_cfg_a;
  wire u_pmp_pmp_13_cfg_l;
  wire u_pmp_pmp_13_cfg_r;
  wire u_pmp_pmp_13_cfg_w;
  wire u_pmp_pmp_13_cfg_x;
  wire [47:0] u_pmp_pmp_13_mask;
  wire [45:0] u_pmp_pmp_14_addr;
  wire [1:0] u_pmp_pmp_14_cfg_a;
  wire u_pmp_pmp_14_cfg_l;
  wire u_pmp_pmp_14_cfg_r;
  wire u_pmp_pmp_14_cfg_w;
  wire u_pmp_pmp_14_cfg_x;
  wire [47:0] u_pmp_pmp_14_mask;
  wire [45:0] u_pmp_pmp_15_addr;
  wire [1:0] u_pmp_pmp_15_cfg_a;
  wire u_pmp_pmp_15_cfg_l;
  wire u_pmp_pmp_15_cfg_r;
  wire u_pmp_pmp_15_cfg_w;
  wire u_pmp_pmp_15_cfg_x;
  wire [47:0] u_pmp_pmp_15_mask;
  wire [45:0] u_pmp_pmp_16_addr;
  wire [1:0] u_pmp_pmp_16_cfg_a;
  wire u_pmp_pmp_16_cfg_l;
  wire u_pmp_pmp_16_cfg_r;
  wire u_pmp_pmp_16_cfg_w;
  wire u_pmp_pmp_16_cfg_x;
  wire [47:0] u_pmp_pmp_16_mask;
  wire [45:0] u_pmp_pmp_17_addr;
  wire [1:0] u_pmp_pmp_17_cfg_a;
  wire u_pmp_pmp_17_cfg_l;
  wire u_pmp_pmp_17_cfg_r;
  wire u_pmp_pmp_17_cfg_w;
  wire u_pmp_pmp_17_cfg_x;
  wire [47:0] u_pmp_pmp_17_mask;
  wire [45:0] u_pmp_pmp_18_addr;
  wire [1:0] u_pmp_pmp_18_cfg_a;
  wire u_pmp_pmp_18_cfg_l;
  wire u_pmp_pmp_18_cfg_r;
  wire u_pmp_pmp_18_cfg_w;
  wire u_pmp_pmp_18_cfg_x;
  wire [47:0] u_pmp_pmp_18_mask;
  wire [45:0] u_pmp_pmp_19_addr;
  wire [1:0] u_pmp_pmp_19_cfg_a;
  wire u_pmp_pmp_19_cfg_l;
  wire u_pmp_pmp_19_cfg_r;
  wire u_pmp_pmp_19_cfg_w;
  wire u_pmp_pmp_19_cfg_x;
  wire [47:0] u_pmp_pmp_19_mask;
  wire [45:0] u_pmp_pmp_1_addr;
  wire [1:0] u_pmp_pmp_1_cfg_a;
  wire u_pmp_pmp_1_cfg_l;
  wire u_pmp_pmp_1_cfg_r;
  wire u_pmp_pmp_1_cfg_w;
  wire u_pmp_pmp_1_cfg_x;
  wire [47:0] u_pmp_pmp_1_mask;
  wire [45:0] u_pmp_pmp_20_addr;
  wire [1:0] u_pmp_pmp_20_cfg_a;
  wire u_pmp_pmp_20_cfg_l;
  wire u_pmp_pmp_20_cfg_r;
  wire u_pmp_pmp_20_cfg_w;
  wire u_pmp_pmp_20_cfg_x;
  wire [47:0] u_pmp_pmp_20_mask;
  wire [45:0] u_pmp_pmp_21_addr;
  wire [1:0] u_pmp_pmp_21_cfg_a;
  wire u_pmp_pmp_21_cfg_l;
  wire u_pmp_pmp_21_cfg_r;
  wire u_pmp_pmp_21_cfg_w;
  wire u_pmp_pmp_21_cfg_x;
  wire [47:0] u_pmp_pmp_21_mask;
  wire [45:0] u_pmp_pmp_22_addr;
  wire [1:0] u_pmp_pmp_22_cfg_a;
  wire u_pmp_pmp_22_cfg_l;
  wire u_pmp_pmp_22_cfg_r;
  wire u_pmp_pmp_22_cfg_w;
  wire u_pmp_pmp_22_cfg_x;
  wire [47:0] u_pmp_pmp_22_mask;
  wire [45:0] u_pmp_pmp_23_addr;
  wire [1:0] u_pmp_pmp_23_cfg_a;
  wire u_pmp_pmp_23_cfg_l;
  wire u_pmp_pmp_23_cfg_r;
  wire u_pmp_pmp_23_cfg_w;
  wire u_pmp_pmp_23_cfg_x;
  wire [47:0] u_pmp_pmp_23_mask;
  wire [45:0] u_pmp_pmp_24_addr;
  wire [1:0] u_pmp_pmp_24_cfg_a;
  wire u_pmp_pmp_24_cfg_l;
  wire u_pmp_pmp_24_cfg_r;
  wire u_pmp_pmp_24_cfg_w;
  wire u_pmp_pmp_24_cfg_x;
  wire [47:0] u_pmp_pmp_24_mask;
  wire [45:0] u_pmp_pmp_25_addr;
  wire [1:0] u_pmp_pmp_25_cfg_a;
  wire u_pmp_pmp_25_cfg_l;
  wire u_pmp_pmp_25_cfg_r;
  wire u_pmp_pmp_25_cfg_w;
  wire u_pmp_pmp_25_cfg_x;
  wire [47:0] u_pmp_pmp_25_mask;
  wire [45:0] u_pmp_pmp_26_addr;
  wire [1:0] u_pmp_pmp_26_cfg_a;
  wire u_pmp_pmp_26_cfg_l;
  wire u_pmp_pmp_26_cfg_r;
  wire u_pmp_pmp_26_cfg_w;
  wire u_pmp_pmp_26_cfg_x;
  wire [47:0] u_pmp_pmp_26_mask;
  wire [45:0] u_pmp_pmp_27_addr;
  wire [1:0] u_pmp_pmp_27_cfg_a;
  wire u_pmp_pmp_27_cfg_l;
  wire u_pmp_pmp_27_cfg_r;
  wire u_pmp_pmp_27_cfg_w;
  wire u_pmp_pmp_27_cfg_x;
  wire [47:0] u_pmp_pmp_27_mask;
  wire [45:0] u_pmp_pmp_28_addr;
  wire [1:0] u_pmp_pmp_28_cfg_a;
  wire u_pmp_pmp_28_cfg_l;
  wire u_pmp_pmp_28_cfg_r;
  wire u_pmp_pmp_28_cfg_w;
  wire u_pmp_pmp_28_cfg_x;
  wire [47:0] u_pmp_pmp_28_mask;
  wire [45:0] u_pmp_pmp_29_addr;
  wire [1:0] u_pmp_pmp_29_cfg_a;
  wire u_pmp_pmp_29_cfg_l;
  wire u_pmp_pmp_29_cfg_r;
  wire u_pmp_pmp_29_cfg_w;
  wire u_pmp_pmp_29_cfg_x;
  wire [47:0] u_pmp_pmp_29_mask;
  wire [45:0] u_pmp_pmp_2_addr;
  wire [1:0] u_pmp_pmp_2_cfg_a;
  wire u_pmp_pmp_2_cfg_l;
  wire u_pmp_pmp_2_cfg_r;
  wire u_pmp_pmp_2_cfg_w;
  wire u_pmp_pmp_2_cfg_x;
  wire [47:0] u_pmp_pmp_2_mask;
  wire [45:0] u_pmp_pmp_30_addr;
  wire [1:0] u_pmp_pmp_30_cfg_a;
  wire u_pmp_pmp_30_cfg_l;
  wire u_pmp_pmp_30_cfg_r;
  wire u_pmp_pmp_30_cfg_w;
  wire u_pmp_pmp_30_cfg_x;
  wire [47:0] u_pmp_pmp_30_mask;
  wire [45:0] u_pmp_pmp_31_addr;
  wire [1:0] u_pmp_pmp_31_cfg_a;
  wire u_pmp_pmp_31_cfg_l;
  wire u_pmp_pmp_31_cfg_r;
  wire u_pmp_pmp_31_cfg_w;
  wire u_pmp_pmp_31_cfg_x;
  wire [47:0] u_pmp_pmp_31_mask;
  wire [45:0] u_pmp_pmp_3_addr;
  wire [1:0] u_pmp_pmp_3_cfg_a;
  wire u_pmp_pmp_3_cfg_l;
  wire u_pmp_pmp_3_cfg_r;
  wire u_pmp_pmp_3_cfg_w;
  wire u_pmp_pmp_3_cfg_x;
  wire [47:0] u_pmp_pmp_3_mask;
  wire [45:0] u_pmp_pmp_4_addr;
  wire [1:0] u_pmp_pmp_4_cfg_a;
  wire u_pmp_pmp_4_cfg_l;
  wire u_pmp_pmp_4_cfg_r;
  wire u_pmp_pmp_4_cfg_w;
  wire u_pmp_pmp_4_cfg_x;
  wire [47:0] u_pmp_pmp_4_mask;
  wire [45:0] u_pmp_pmp_5_addr;
  wire [1:0] u_pmp_pmp_5_cfg_a;
  wire u_pmp_pmp_5_cfg_l;
  wire u_pmp_pmp_5_cfg_r;
  wire u_pmp_pmp_5_cfg_w;
  wire u_pmp_pmp_5_cfg_x;
  wire [47:0] u_pmp_pmp_5_mask;
  wire [45:0] u_pmp_pmp_6_addr;
  wire [1:0] u_pmp_pmp_6_cfg_a;
  wire u_pmp_pmp_6_cfg_l;
  wire u_pmp_pmp_6_cfg_r;
  wire u_pmp_pmp_6_cfg_w;
  wire u_pmp_pmp_6_cfg_x;
  wire [47:0] u_pmp_pmp_6_mask;
  wire [45:0] u_pmp_pmp_7_addr;
  wire [1:0] u_pmp_pmp_7_cfg_a;
  wire u_pmp_pmp_7_cfg_l;
  wire u_pmp_pmp_7_cfg_r;
  wire u_pmp_pmp_7_cfg_w;
  wire u_pmp_pmp_7_cfg_x;
  wire [47:0] u_pmp_pmp_7_mask;
  wire [45:0] u_pmp_pmp_8_addr;
  wire [1:0] u_pmp_pmp_8_cfg_a;
  wire u_pmp_pmp_8_cfg_l;
  wire u_pmp_pmp_8_cfg_r;
  wire u_pmp_pmp_8_cfg_w;
  wire u_pmp_pmp_8_cfg_x;
  wire [47:0] u_pmp_pmp_8_mask;
  wire [45:0] u_pmp_pmp_9_addr;
  wire [1:0] u_pmp_pmp_9_cfg_a;
  wire u_pmp_pmp_9_cfg_l;
  wire u_pmp_pmp_9_cfg_r;
  wire u_pmp_pmp_9_cfg_w;
  wire u_pmp_pmp_9_cfg_x;
  wire [47:0] u_pmp_pmp_9_mask;
  wire [1:0] u_prefetch_out_bits_req_info_s2xlate;
  wire [37:0] u_prefetch_out_bits_req_info_vpn;
  wire u_prefetch_out_valid;
  wire [35:0] u_ptw_bitmap_req_bits_bmppn;
  wire [1:0] u_ptw_bitmap_req_bits_level;
  wire u_ptw_bitmap_req_bits_n;
  wire [1:0] u_ptw_bitmap_req_bits_s2xlate;
  wire [37:0] u_ptw_bitmap_req_bits_vpn;
  wire u_ptw_bitmap_req_valid;
  wire u_ptw_bitmap_resp_ready;
  wire [43:0] u_ptw_hptw_req_bits_gvpn;
  wire [1:0] u_ptw_hptw_req_bits_source;
  wire u_ptw_hptw_req_valid;
  wire [1:0] u_ptw_llptw_bits_req_info_s2xlate;
  wire [1:0] u_ptw_llptw_bits_req_info_source;
  wire [37:0] u_ptw_llptw_bits_req_info_vpn;
  wire u_ptw_llptw_valid;
  wire [47:0] u_ptw_mem_req_bits_addr;
  wire u_ptw_mem_req_valid;
  wire [5:0] u_ptw_perf_0_value;
  wire [5:0] u_ptw_perf_1_value;
  wire [5:0] u_ptw_perf_2_value;
  wire [5:0] u_ptw_perf_3_value;
  wire [5:0] u_ptw_perf_4_value;
  wire [5:0] u_ptw_perf_5_value;
  wire [5:0] u_ptw_perf_6_value;
  wire [47:0] u_ptw_pmp_req_bits_addr;
  wire [1:0] u_ptw_refill_level;
  wire [1:0] u_ptw_refill_req_info_s2xlate;
  wire [1:0] u_ptw_refill_req_info_source;
  wire [37:0] u_ptw_refill_req_info_vpn;
  wire u_ptw_req_ready;
  wire [1:0] u_ptw_resp_bits_h_resp_entry_level;
  wire u_ptw_resp_bits_h_resp_entry_n;
  wire [1:0] u_ptw_resp_bits_h_resp_entry_pbmt;
  wire u_ptw_resp_bits_h_resp_entry_perm_a;
  wire u_ptw_resp_bits_h_resp_entry_perm_d;
  wire u_ptw_resp_bits_h_resp_entry_perm_g;
  wire u_ptw_resp_bits_h_resp_entry_perm_r;
  wire u_ptw_resp_bits_h_resp_entry_perm_u;
  wire u_ptw_resp_bits_h_resp_entry_perm_w;
  wire u_ptw_resp_bits_h_resp_entry_perm_x;
  wire [37:0] u_ptw_resp_bits_h_resp_entry_ppn;
  wire [37:0] u_ptw_resp_bits_h_resp_entry_tag;
  wire [13:0] u_ptw_resp_bits_h_resp_entry_vmid;
  wire u_ptw_resp_bits_h_resp_gaf;
  wire u_ptw_resp_bits_h_resp_gpf;
  wire u_ptw_resp_bits_resp_entry_0_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_0_asid;
  wire u_ptw_resp_bits_resp_entry_0_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_0_level;
  wire u_ptw_resp_bits_resp_entry_0_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_0_pbmt;
  wire u_ptw_resp_bits_resp_entry_0_perm_a;
  wire u_ptw_resp_bits_resp_entry_0_perm_d;
  wire u_ptw_resp_bits_resp_entry_0_perm_g;
  wire u_ptw_resp_bits_resp_entry_0_perm_r;
  wire u_ptw_resp_bits_resp_entry_0_perm_u;
  wire u_ptw_resp_bits_resp_entry_0_perm_w;
  wire u_ptw_resp_bits_resp_entry_0_perm_x;
  wire u_ptw_resp_bits_resp_entry_0_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_0_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_0_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_0_tag;
  wire u_ptw_resp_bits_resp_entry_0_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_0_vmid;
  wire u_ptw_resp_bits_resp_entry_1_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_1_asid;
  wire u_ptw_resp_bits_resp_entry_1_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_1_level;
  wire u_ptw_resp_bits_resp_entry_1_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_1_pbmt;
  wire u_ptw_resp_bits_resp_entry_1_perm_a;
  wire u_ptw_resp_bits_resp_entry_1_perm_d;
  wire u_ptw_resp_bits_resp_entry_1_perm_g;
  wire u_ptw_resp_bits_resp_entry_1_perm_r;
  wire u_ptw_resp_bits_resp_entry_1_perm_u;
  wire u_ptw_resp_bits_resp_entry_1_perm_w;
  wire u_ptw_resp_bits_resp_entry_1_perm_x;
  wire u_ptw_resp_bits_resp_entry_1_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_1_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_1_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_1_tag;
  wire u_ptw_resp_bits_resp_entry_1_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_1_vmid;
  wire u_ptw_resp_bits_resp_entry_2_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_2_asid;
  wire u_ptw_resp_bits_resp_entry_2_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_2_level;
  wire u_ptw_resp_bits_resp_entry_2_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_2_pbmt;
  wire u_ptw_resp_bits_resp_entry_2_perm_a;
  wire u_ptw_resp_bits_resp_entry_2_perm_d;
  wire u_ptw_resp_bits_resp_entry_2_perm_g;
  wire u_ptw_resp_bits_resp_entry_2_perm_r;
  wire u_ptw_resp_bits_resp_entry_2_perm_u;
  wire u_ptw_resp_bits_resp_entry_2_perm_w;
  wire u_ptw_resp_bits_resp_entry_2_perm_x;
  wire u_ptw_resp_bits_resp_entry_2_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_2_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_2_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_2_tag;
  wire u_ptw_resp_bits_resp_entry_2_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_2_vmid;
  wire u_ptw_resp_bits_resp_entry_3_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_3_asid;
  wire u_ptw_resp_bits_resp_entry_3_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_3_level;
  wire u_ptw_resp_bits_resp_entry_3_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_3_pbmt;
  wire u_ptw_resp_bits_resp_entry_3_perm_a;
  wire u_ptw_resp_bits_resp_entry_3_perm_d;
  wire u_ptw_resp_bits_resp_entry_3_perm_g;
  wire u_ptw_resp_bits_resp_entry_3_perm_r;
  wire u_ptw_resp_bits_resp_entry_3_perm_u;
  wire u_ptw_resp_bits_resp_entry_3_perm_w;
  wire u_ptw_resp_bits_resp_entry_3_perm_x;
  wire u_ptw_resp_bits_resp_entry_3_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_3_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_3_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_3_tag;
  wire u_ptw_resp_bits_resp_entry_3_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_3_vmid;
  wire u_ptw_resp_bits_resp_entry_4_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_4_asid;
  wire u_ptw_resp_bits_resp_entry_4_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_4_level;
  wire u_ptw_resp_bits_resp_entry_4_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_4_pbmt;
  wire u_ptw_resp_bits_resp_entry_4_perm_a;
  wire u_ptw_resp_bits_resp_entry_4_perm_d;
  wire u_ptw_resp_bits_resp_entry_4_perm_g;
  wire u_ptw_resp_bits_resp_entry_4_perm_r;
  wire u_ptw_resp_bits_resp_entry_4_perm_u;
  wire u_ptw_resp_bits_resp_entry_4_perm_w;
  wire u_ptw_resp_bits_resp_entry_4_perm_x;
  wire u_ptw_resp_bits_resp_entry_4_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_4_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_4_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_4_tag;
  wire u_ptw_resp_bits_resp_entry_4_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_4_vmid;
  wire u_ptw_resp_bits_resp_entry_5_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_5_asid;
  wire u_ptw_resp_bits_resp_entry_5_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_5_level;
  wire u_ptw_resp_bits_resp_entry_5_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_5_pbmt;
  wire u_ptw_resp_bits_resp_entry_5_perm_a;
  wire u_ptw_resp_bits_resp_entry_5_perm_d;
  wire u_ptw_resp_bits_resp_entry_5_perm_g;
  wire u_ptw_resp_bits_resp_entry_5_perm_r;
  wire u_ptw_resp_bits_resp_entry_5_perm_u;
  wire u_ptw_resp_bits_resp_entry_5_perm_w;
  wire u_ptw_resp_bits_resp_entry_5_perm_x;
  wire u_ptw_resp_bits_resp_entry_5_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_5_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_5_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_5_tag;
  wire u_ptw_resp_bits_resp_entry_5_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_5_vmid;
  wire u_ptw_resp_bits_resp_entry_6_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_6_asid;
  wire u_ptw_resp_bits_resp_entry_6_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_6_level;
  wire u_ptw_resp_bits_resp_entry_6_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_6_pbmt;
  wire u_ptw_resp_bits_resp_entry_6_perm_a;
  wire u_ptw_resp_bits_resp_entry_6_perm_d;
  wire u_ptw_resp_bits_resp_entry_6_perm_g;
  wire u_ptw_resp_bits_resp_entry_6_perm_r;
  wire u_ptw_resp_bits_resp_entry_6_perm_u;
  wire u_ptw_resp_bits_resp_entry_6_perm_w;
  wire u_ptw_resp_bits_resp_entry_6_perm_x;
  wire u_ptw_resp_bits_resp_entry_6_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_6_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_6_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_6_tag;
  wire u_ptw_resp_bits_resp_entry_6_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_6_vmid;
  wire u_ptw_resp_bits_resp_entry_7_af;
  wire [15:0] u_ptw_resp_bits_resp_entry_7_asid;
  wire u_ptw_resp_bits_resp_entry_7_cf;
  wire [1:0] u_ptw_resp_bits_resp_entry_7_level;
  wire u_ptw_resp_bits_resp_entry_7_n;
  wire [1:0] u_ptw_resp_bits_resp_entry_7_pbmt;
  wire u_ptw_resp_bits_resp_entry_7_perm_a;
  wire u_ptw_resp_bits_resp_entry_7_perm_d;
  wire u_ptw_resp_bits_resp_entry_7_perm_g;
  wire u_ptw_resp_bits_resp_entry_7_perm_r;
  wire u_ptw_resp_bits_resp_entry_7_perm_u;
  wire u_ptw_resp_bits_resp_entry_7_perm_w;
  wire u_ptw_resp_bits_resp_entry_7_perm_x;
  wire u_ptw_resp_bits_resp_entry_7_pf;
  wire [40:0] u_ptw_resp_bits_resp_entry_7_ppn;
  wire [2:0] u_ptw_resp_bits_resp_entry_7_ppn_low;
  wire [34:0] u_ptw_resp_bits_resp_entry_7_tag;
  wire u_ptw_resp_bits_resp_entry_7_v;
  wire [13:0] u_ptw_resp_bits_resp_entry_7_vmid;
  wire u_ptw_resp_bits_resp_not_super;
  wire u_ptw_resp_bits_resp_pteidx_0;
  wire u_ptw_resp_bits_resp_pteidx_1;
  wire u_ptw_resp_bits_resp_pteidx_2;
  wire u_ptw_resp_bits_resp_pteidx_3;
  wire u_ptw_resp_bits_resp_pteidx_4;
  wire u_ptw_resp_bits_resp_pteidx_5;
  wire u_ptw_resp_bits_resp_pteidx_6;
  wire u_ptw_resp_bits_resp_pteidx_7;
  wire [1:0] u_ptw_resp_bits_s2xlate;
  wire [1:0] u_ptw_resp_bits_source;
  wire u_ptw_resp_valid;
  wire [49:0] u_sfence_delay_out_bits_addr;
  wire u_sfence_delay_out_bits_hg;
  wire u_sfence_delay_out_bits_hv;
  wire [15:0] u_sfence_delay_out_bits_id;
  wire u_sfence_delay_out_bits_rs1;
  wire u_sfence_delay_out_bits_rs2;
  wire u_sfence_delay_out_valid;
  wire u_wfi_req_delay_out;
  wire u_wfi_safe_delay_out;
  // END GENERATED

  // 本核手写逻辑必须驱动的 glue 输入网（名 <实例>__<端口尾巴>）。
  // BEGIN GENERATED(driven)
  logic u_arb_cache_in__in_2_valid;
  logic [1:0] u_arb_cache_in__in_3_bits_req_info_source;
  logic u_arb_cache_in__in_3_valid;
  logic [37:0] u_arb_hptw_req__in_0_bits_gvpn;
  logic [37:0] u_arb_hptw_req__in_1_bits_gvpn;
  logic u_arb_hptw_resp__in_0_valid;
  logic [2:0] u_arb_hptw_resp__in_1_bits_id;
  logic u_arb_mq__in_0_bits_isLLptw;
  logic u_arb_mq__in_0_valid;
  logic u_arb_tlb__out_ready;
  logic u_bitmap__csr_hgatp_changed;
  logic [57:0] u_bitmap__csr_mbmc_BMA;
  logic u_bitmap__csr_priv_virt_changed;
  logic u_bitmap__csr_satp_changed;
  logic u_bitmap__csr_vsatp_changed;
  logic u_bitmap__mem_req_mask_0;
  logic u_bitmap__mem_req_mask_1;
  logic u_bitmap__mem_req_mask_2;
  logic u_bitmap__mem_req_mask_3;
  logic u_bitmap__mem_req_mask_4;
  logic u_bitmap__mem_req_mask_5;
  logic u_bitmap__mem_req_mask_6;
  logic u_bitmap__mem_req_mask_7;
  logic [3:0] u_bitmap__mem_resp_bits_id;
  logic [511:0] u_bitmap__mem_resp_bits_value;
  logic u_bitmap__mem_resp_valid;
  logic u_bitmap__resp_ready;
  logic u_bitmap__sfence_valid;
  logic u_bitmap_cache__csr_hgatp_changed;
  logic u_bitmap_cache__csr_mbmc_BCLEAR;
  logic u_bitmap_cache__csr_priv_virt_changed;
  logic u_bitmap_cache__csr_satp_changed;
  logic u_bitmap_cache__csr_vsatp_changed;
  logic u_bitmap_cache__sfence_valid;
  logic u_hptw__bitmap_resp_valid;
  logic u_hptw__csr_hgatp_changed;
  logic [3:0] u_hptw__csr_hgatp_mode;
  logic [43:0] u_hptw__csr_hgatp_ppn;
  logic [15:0] u_hptw__csr_hgatp_vmid;
  logic u_hptw__csr_mPBMTE;
  logic u_hptw__csr_mbmc_BME;
  logic u_hptw__csr_mbmc_CMODE;
  logic u_hptw__csr_priv_virt_changed;
  logic u_hptw__csr_satp_changed;
  logic u_hptw__csr_vsatp_changed;
  logic u_hptw__mem_mask;
  logic [63:0] u_hptw__mem_resp_bits;
  logic u_hptw__mem_resp_valid;
  logic u_hptw__req_valid;
  logic u_hptw__sfence_valid;
  logic u_llptw__bitmap_resp_valid;
  logic u_llptw__csr_hPBMTE;
  logic u_llptw__csr_hgatp_changed;
  logic [3:0] u_llptw__csr_hgatp_mode;
  logic u_llptw__csr_mPBMTE;
  logic u_llptw__csr_mbmc_BME;
  logic u_llptw__csr_mbmc_CMODE;
  logic u_llptw__csr_priv_virt_changed;
  logic u_llptw__csr_satp_changed;
  logic u_llptw__csr_vsatp_changed;
  logic u_llptw__hptw_resp_valid;
  logic [43:0] u_llptw__in_bits_ppn;
  logic u_llptw__in_valid;
  logic u_llptw__mem_flush_latch_0;
  logic u_llptw__mem_flush_latch_1;
  logic u_llptw__mem_flush_latch_2;
  logic u_llptw__mem_flush_latch_3;
  logic u_llptw__mem_flush_latch_4;
  logic u_llptw__mem_flush_latch_5;
  logic u_llptw__mem_req_mask_0;
  logic u_llptw__mem_req_mask_1;
  logic u_llptw__mem_req_mask_2;
  logic u_llptw__mem_req_mask_3;
  logic u_llptw__mem_req_mask_4;
  logic u_llptw__mem_req_mask_5;
  logic [2:0] u_llptw__mem_resp_bits_id;
  logic [511:0] u_llptw__mem_resp_bits_value;
  logic u_llptw__mem_resp_valid;
  logic u_llptw__out_ready;
  logic u_llptw__sfence_valid;
  logic u_mem_arb__out_ready;
  logic u_merge_arb_0__in_0_valid;
  logic u_merge_arb_0__in_1_valid;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_0_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_0_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_0_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_0_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_0_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_0_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_0_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_0_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_1_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_1_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_1_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_1_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_1_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_1_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_1_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_1_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_2_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_2_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_2_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_2_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_2_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_2_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_2_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_2_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_3_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_3_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_3_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_3_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_3_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_3_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_3_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_3_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_4_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_4_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_4_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_4_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_4_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_4_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_4_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_4_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_5_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_5_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_5_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_5_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_5_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_5_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_5_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_5_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_6_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_6_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_6_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_6_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_6_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_6_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_6_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_6_vmid;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_af;
  logic [15:0] u_merge_arb_0__in_2_bits_s1_entry_7_asid;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_cf;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_7_level;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_n;
  logic [1:0] u_merge_arb_0__in_2_bits_s1_entry_7_pbmt;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_a;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_d;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_g;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_r;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_u;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_w;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_perm_x;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_pf;
  logic [40:0] u_merge_arb_0__in_2_bits_s1_entry_7_ppn;
  logic [2:0] u_merge_arb_0__in_2_bits_s1_entry_7_ppn_low;
  logic [34:0] u_merge_arb_0__in_2_bits_s1_entry_7_tag;
  logic u_merge_arb_0__in_2_bits_s1_entry_7_v;
  logic [13:0] u_merge_arb_0__in_2_bits_s1_entry_7_vmid;
  logic u_merge_arb_0__in_2_bits_s1_not_merge;
  logic u_merge_arb_0__in_2_bits_s1_not_super;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_0;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_1;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_2;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_3;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_4;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_5;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_6;
  logic u_merge_arb_0__in_2_bits_s1_pteidx_7;
  logic u_merge_arb_0__in_2_valid;
  logic u_merge_arb_1__in_0_valid;
  logic u_merge_arb_1__in_1_valid;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_0_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_0_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_0_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_0_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_0_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_0_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_0_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_0_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_1_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_1_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_1_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_1_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_1_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_1_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_1_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_1_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_2_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_2_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_2_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_2_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_2_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_2_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_2_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_2_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_3_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_3_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_3_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_3_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_3_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_3_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_3_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_3_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_4_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_4_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_4_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_4_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_4_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_4_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_4_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_4_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_5_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_5_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_5_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_5_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_5_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_5_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_5_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_5_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_6_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_6_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_6_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_6_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_6_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_6_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_6_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_6_vmid;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_af;
  logic [15:0] u_merge_arb_1__in_2_bits_s1_entry_7_asid;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_cf;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_7_level;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_n;
  logic [1:0] u_merge_arb_1__in_2_bits_s1_entry_7_pbmt;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_a;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_d;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_g;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_r;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_u;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_w;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_perm_x;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_pf;
  logic [40:0] u_merge_arb_1__in_2_bits_s1_entry_7_ppn;
  logic [2:0] u_merge_arb_1__in_2_bits_s1_entry_7_ppn_low;
  logic [34:0] u_merge_arb_1__in_2_bits_s1_entry_7_tag;
  logic u_merge_arb_1__in_2_bits_s1_entry_7_v;
  logic [13:0] u_merge_arb_1__in_2_bits_s1_entry_7_vmid;
  logic u_merge_arb_1__in_2_bits_s1_not_merge;
  logic u_merge_arb_1__in_2_bits_s1_not_super;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_0;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_1;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_2;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_3;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_4;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_5;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_6;
  logic u_merge_arb_1__in_2_bits_s1_pteidx_7;
  logic u_merge_arb_1__in_2_valid;
  logic u_miss_queue__csr_hgatp_changed;
  logic u_miss_queue__csr_priv_virt_changed;
  logic u_miss_queue__csr_satp_changed;
  logic u_miss_queue__csr_vsatp_changed;
  logic u_miss_queue__out_ready;
  logic u_miss_queue__sfence_valid;
  logic [2:0] u_out_arb_0__in_0_bits_s1_addr_low;
  logic u_out_arb_0__in_0_bits_s1_af;
  logic [15:0] u_out_arb_0__in_0_bits_s1_entry_asid;
  logic [1:0] u_out_arb_0__in_0_bits_s1_entry_level;
  logic u_out_arb_0__in_0_bits_s1_entry_n;
  logic [1:0] u_out_arb_0__in_0_bits_s1_entry_pbmt;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_a;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_d;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_g;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_r;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_u;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_w;
  logic u_out_arb_0__in_0_bits_s1_entry_perm_x;
  logic [40:0] u_out_arb_0__in_0_bits_s1_entry_ppn;
  logic [34:0] u_out_arb_0__in_0_bits_s1_entry_tag;
  logic u_out_arb_0__in_0_bits_s1_entry_v;
  logic [13:0] u_out_arb_0__in_0_bits_s1_entry_vmid;
  logic u_out_arb_0__in_0_bits_s1_pf;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_0;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_1;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_2;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_3;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_4;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_5;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_6;
  logic [2:0] u_out_arb_0__in_0_bits_s1_ppn_low_7;
  logic u_out_arb_0__in_0_bits_s1_valididx_0;
  logic u_out_arb_0__in_0_bits_s1_valididx_1;
  logic u_out_arb_0__in_0_bits_s1_valididx_2;
  logic u_out_arb_0__in_0_bits_s1_valididx_3;
  logic u_out_arb_0__in_0_bits_s1_valididx_4;
  logic u_out_arb_0__in_0_bits_s1_valididx_5;
  logic u_out_arb_0__in_0_bits_s1_valididx_6;
  logic u_out_arb_0__in_0_bits_s1_valididx_7;
  logic [1:0] u_out_arb_0__in_0_bits_s2_entry_level;
  logic u_out_arb_0__in_0_bits_s2_entry_n;
  logic [37:0] u_out_arb_0__in_0_bits_s2_entry_ppn;
  logic [2:0] u_out_arb_1__in_0_bits_s1_addr_low;
  logic u_out_arb_1__in_0_bits_s1_af;
  logic [15:0] u_out_arb_1__in_0_bits_s1_entry_asid;
  logic [1:0] u_out_arb_1__in_0_bits_s1_entry_level;
  logic u_out_arb_1__in_0_bits_s1_entry_n;
  logic [1:0] u_out_arb_1__in_0_bits_s1_entry_pbmt;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_a;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_d;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_g;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_r;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_u;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_w;
  logic u_out_arb_1__in_0_bits_s1_entry_perm_x;
  logic [40:0] u_out_arb_1__in_0_bits_s1_entry_ppn;
  logic [34:0] u_out_arb_1__in_0_bits_s1_entry_tag;
  logic u_out_arb_1__in_0_bits_s1_entry_v;
  logic [13:0] u_out_arb_1__in_0_bits_s1_entry_vmid;
  logic u_out_arb_1__in_0_bits_s1_pf;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_0;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_1;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_2;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_3;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_4;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_5;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_6;
  logic [2:0] u_out_arb_1__in_0_bits_s1_ppn_low_7;
  logic u_out_arb_1__in_0_bits_s1_valididx_0;
  logic u_out_arb_1__in_0_bits_s1_valididx_1;
  logic u_out_arb_1__in_0_bits_s1_valididx_2;
  logic u_out_arb_1__in_0_bits_s1_valididx_3;
  logic u_out_arb_1__in_0_bits_s1_valididx_4;
  logic u_out_arb_1__in_0_bits_s1_valididx_5;
  logic u_out_arb_1__in_0_bits_s1_valididx_6;
  logic u_out_arb_1__in_0_bits_s1_valididx_7;
  logic [1:0] u_out_arb_1__in_0_bits_s2_entry_level;
  logic u_out_arb_1__in_0_bits_s2_entry_n;
  logic [37:0] u_out_arb_1__in_0_bits_s2_entry_ppn;
  logic u_page_cache__csr_dup_0_hgatp_changed;
  logic [3:0] u_page_cache__csr_dup_0_hgatp_mode;
  logic [15:0] u_page_cache__csr_dup_0_hgatp_vmid;
  logic u_page_cache__csr_dup_0_mbmc_BME;
  logic u_page_cache__csr_dup_0_mbmc_CMODE;
  logic u_page_cache__csr_dup_0_priv_virt;
  logic u_page_cache__csr_dup_0_priv_virt_changed;
  logic [15:0] u_page_cache__csr_dup_0_satp_asid;
  logic u_page_cache__csr_dup_0_satp_changed;
  logic [15:0] u_page_cache__csr_dup_0_vsatp_asid;
  logic u_page_cache__csr_dup_0_vsatp_changed;
  logic u_page_cache__csr_dup_1_hgatp_changed;
  logic [3:0] u_page_cache__csr_dup_1_hgatp_mode;
  logic [15:0] u_page_cache__csr_dup_1_hgatp_vmid;
  logic u_page_cache__csr_dup_1_priv_virt;
  logic u_page_cache__csr_dup_1_priv_virt_changed;
  logic [15:0] u_page_cache__csr_dup_1_satp_asid;
  logic u_page_cache__csr_dup_1_satp_changed;
  logic [15:0] u_page_cache__csr_dup_1_vsatp_asid;
  logic u_page_cache__csr_dup_1_vsatp_changed;
  logic u_page_cache__csr_dup_2_hgatp_changed;
  logic [3:0] u_page_cache__csr_dup_2_hgatp_mode;
  logic [15:0] u_page_cache__csr_dup_2_hgatp_vmid;
  logic u_page_cache__csr_dup_2_priv_virt;
  logic u_page_cache__csr_dup_2_priv_virt_changed;
  logic [15:0] u_page_cache__csr_dup_2_satp_asid;
  logic u_page_cache__csr_dup_2_satp_changed;
  logic [15:0] u_page_cache__csr_dup_2_vsatp_asid;
  logic u_page_cache__csr_dup_2_vsatp_changed;
  logic u_page_cache__csr_hPBMTE;
  logic u_page_cache__csr_mPBMTE;
  logic u_page_cache__refill_bits_levelOH_l0;
  logic u_page_cache__refill_bits_levelOH_l1;
  logic u_page_cache__refill_bits_levelOH_l2;
  logic u_page_cache__refill_bits_levelOH_l3;
  logic u_page_cache__refill_bits_levelOH_sp;
  logic [1:0] u_page_cache__refill_bits_level_dup_0;
  logic [1:0] u_page_cache__refill_bits_level_dup_2;
  logic [511:0] u_page_cache__refill_bits_ptes;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_0_s2xlate;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_0_source;
  logic [37:0] u_page_cache__refill_bits_req_info_dup_0_vpn;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_1_s2xlate;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_1_source;
  logic [37:0] u_page_cache__refill_bits_req_info_dup_1_vpn;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_2_s2xlate;
  logic [1:0] u_page_cache__refill_bits_req_info_dup_2_source;
  logic [37:0] u_page_cache__refill_bits_req_info_dup_2_vpn;
  logic [63:0] u_page_cache__refill_bits_sel_pte_dup_0;
  logic [63:0] u_page_cache__refill_bits_sel_pte_dup_2;
  logic u_page_cache__refill_valid;
  logic u_page_cache__req_bits_isFirst;
  logic u_page_cache__req_valid;
  logic u_page_cache__resp_ready;
  logic [49:0] u_page_cache__sfence_dup_0_bits_addr;
  logic u_page_cache__sfence_dup_0_bits_hg;
  logic u_page_cache__sfence_dup_0_bits_hv;
  logic [15:0] u_page_cache__sfence_dup_0_bits_id;
  logic u_page_cache__sfence_dup_0_bits_rs1;
  logic u_page_cache__sfence_dup_0_bits_rs2;
  logic u_page_cache__sfence_dup_0_valid;
  logic [15:0] u_page_cache__sfence_dup_1_bits_id;
  logic u_page_cache__sfence_dup_1_valid;
  logic [15:0] u_page_cache__sfence_dup_2_bits_id;
  logic u_page_cache__sfence_dup_2_bits_rs1;
  logic u_page_cache__sfence_dup_2_bits_rs2;
  logic u_page_cache__sfence_dup_2_valid;
  logic u_pmp_chk_bitmap__check_env_debug;
  logic u_pmp_chk_hptw__check_env_debug;
  logic u_pmp_chk_llptw0__check_env_debug;
  logic u_pmp_chk_llptw1__check_env_debug;
  logic u_pmp_chk_ptw__check_env_debug;
  logic u_prefetch__csr_hgatp_changed;
  logic [3:0] u_prefetch__csr_hgatp_mode;
  logic u_prefetch__csr_priv_virt;
  logic u_prefetch__csr_priv_virt_changed;
  logic u_prefetch__csr_satp_changed;
  logic u_prefetch__csr_vsatp_changed;
  logic [3:0] u_prefetch__csr_vsatp_mode;
  logic u_prefetch__in_valid;
  logic u_prefetch__sfence_valid;
  logic u_ptw__bitmap_resp_valid;
  logic u_ptw__csr_hPBMTE;
  logic u_ptw__csr_hgatp_changed;
  logic [3:0] u_ptw__csr_hgatp_mode;
  logic [15:0] u_ptw__csr_hgatp_vmid;
  logic u_ptw__csr_mPBMTE;
  logic u_ptw__csr_mbmc_BME;
  logic u_ptw__csr_mbmc_CMODE;
  logic u_ptw__csr_priv_virt_changed;
  logic [15:0] u_ptw__csr_satp_asid;
  logic u_ptw__csr_satp_changed;
  logic [3:0] u_ptw__csr_satp_mode;
  logic [43:0] u_ptw__csr_satp_ppn;
  logic [15:0] u_ptw__csr_vsatp_asid;
  logic u_ptw__csr_vsatp_changed;
  logic [3:0] u_ptw__csr_vsatp_mode;
  logic [43:0] u_ptw__csr_vsatp_ppn;
  logic u_ptw__hptw_resp_valid;
  logic u_ptw__mem_mask;
  logic [63:0] u_ptw__mem_resp_bits;
  logic u_ptw__mem_resp_valid;
  logic [43:0] u_ptw__req_bits_ppn;
  logic u_ptw__req_valid;
  logic u_ptw__resp_ready;
  logic u_ptw__sfence_valid;
  logic u_wfi_safe_delay__in;
  // END GENERATED

  // ==========================================================================
  // 1. CSR / sfence 复制扇出
  // --------------------------------------------------------------------------
  // io.csr.tlb / io.sfence 先过 DelayN(1) 得到 csr_tmp / sfence_tmp，再各 RegNext
  // 一拍得到 10 份 csr / 11 份 sfence 同值副本。复制只为降低长扇出。各子模块按固定
  // 下标取用：prefetch/flush=0，llptw=1，cache=2/3/4，missQueue csr=5 sfence=6，
  // ptw csr=6 sfence=7，hptw csr=7 sfence=8，bitmap csr=8 sfence=9，
  // bitmapcache csr=9 sfence=10。csr_dup[0] 还用于 flush 判定。
  // ★ golden 里 sfence_dup_5 被整份消掉（没有消费者），这里数组照留一格不用；
  //   不许为了"对称"去补一个 golden 没有的消费者。★
  // ==========================================================================
  localparam int CSR_DUP_NUM    = 10;
  localparam int SFENCE_DUP_NUM = 11;

  l2tlb_csr_t    csr_tmp;
  l2tlb_sfence_t sfence_tmp;

  assign csr_tmp = '{
    satp_mode:   u_csr_delay_out_satp_mode,   satp_asid:    u_csr_delay_out_satp_asid,
    satp_ppn:    u_csr_delay_out_satp_ppn,    satp_changed: u_csr_delay_out_satp_changed,
    vsatp_mode:  u_csr_delay_out_vsatp_mode,  vsatp_asid:   u_csr_delay_out_vsatp_asid,
    vsatp_ppn:   u_csr_delay_out_vsatp_ppn,   vsatp_changed:u_csr_delay_out_vsatp_changed,
    hgatp_mode:  u_csr_delay_out_hgatp_mode,  hgatp_vmid:   u_csr_delay_out_hgatp_vmid,
    hgatp_ppn:   u_csr_delay_out_hgatp_ppn,   hgatp_changed:u_csr_delay_out_hgatp_changed,
    mbmc_BMA:    u_csr_delay_out_mbmc_BMA,    mbmc_BME:     u_csr_delay_out_mbmc_BME,
    mbmc_CMODE:  u_csr_delay_out_mbmc_CMODE,  mbmc_BCLEAR:  u_csr_delay_out_mbmc_BCLEAR,
    priv_virt:   u_csr_delay_out_priv_virt,
    priv_virt_changed: u_csr_delay_out_priv_virt_changed,
    priv_debug:  u_csr_delay_out_priv_debug,
    mPBMTE:      u_csr_delay_out_mPBMTE,      hPBMTE:       u_csr_delay_out_hPBMTE };

  assign sfence_tmp = '{
    valid: u_sfence_delay_out_valid,    rs1:  u_sfence_delay_out_bits_rs1,
    rs2:   u_sfence_delay_out_bits_rs2, addr: u_sfence_delay_out_bits_addr,
    id:    u_sfence_delay_out_bits_id,  hv:   u_sfence_delay_out_bits_hv,
    hg:    u_sfence_delay_out_bits_hg };

  l2tlb_csr_t    csr_dup    [CSR_DUP_NUM];
  l2tlb_sfence_t sfence_dup [SFENCE_DUP_NUM];
  for (genvar i = 0; i < CSR_DUP_NUM; i++) begin : g_csr_dup
    always_ff @(posedge clock) csr_dup[i] <= csr_tmp;
  end
  for (genvar i = 0; i < SFENCE_DUP_NUM; i++) begin : g_sfence_dup
    always_ff @(posedge clock) sfence_dup[i] <= sfence_tmp;
  end

  // flush：sfence 有效，或 satp/vsatp/hgatp/virt 任一变化。
  wire flush = sfence_dup[0].valid | csr_dup[0].satp_changed
             | csr_dup[0].vsatp_changed | csr_dup[0].hgatp_changed
             | csr_dup[0].priv_virt_changed;

  // bitmap 特性总开关（G1 新增）：BME 使能且不在 CMODE 旁路模式。
  wire bitmap_enable = csr_dup[0].mbmc_BME & ~csr_dup[0].mbmc_CMODE;

  // -- 各子模块的 csr / sfence 输入接到对应副本 --
  // prefetch ← csr/sfence 0
  assign u_prefetch__csr_satp_changed      = csr_dup[0].satp_changed;
  assign u_prefetch__csr_vsatp_changed     = csr_dup[0].vsatp_changed;
  assign u_prefetch__csr_vsatp_mode        = csr_dup[0].vsatp_mode;
  assign u_prefetch__csr_hgatp_changed     = csr_dup[0].hgatp_changed;
  assign u_prefetch__csr_hgatp_mode        = csr_dup[0].hgatp_mode;
  assign u_prefetch__csr_priv_virt         = csr_dup[0].priv_virt;
  assign u_prefetch__csr_priv_virt_changed = csr_dup[0].priv_virt_changed;
  assign u_prefetch__sfence_valid          = sfence_dup[0].valid;
  // llptw ← csr/sfence 1
  assign u_llptw__csr_satp_changed      = csr_dup[1].satp_changed;
  assign u_llptw__csr_vsatp_changed     = csr_dup[1].vsatp_changed;
  assign u_llptw__csr_hgatp_changed     = csr_dup[1].hgatp_changed;
  assign u_llptw__csr_hgatp_mode        = csr_dup[1].hgatp_mode;
  assign u_llptw__csr_mbmc_BME          = csr_dup[1].mbmc_BME;
  assign u_llptw__csr_mbmc_CMODE        = csr_dup[1].mbmc_CMODE;
  assign u_llptw__csr_priv_virt_changed = csr_dup[1].priv_virt_changed;
  assign u_llptw__csr_mPBMTE            = csr_dup[1].mPBMTE;
  assign u_llptw__csr_hPBMTE            = csr_dup[1].hPBMTE;
  assign u_llptw__sfence_valid          = sfence_dup[1].valid;
  // page cache 自带三份 csr/sfence 副本 ← csr_dup 2/3/4、sfence_dup 2/3/4
  assign u_page_cache__csr_dup_0_satp_asid         = csr_dup[2].satp_asid;
  assign u_page_cache__csr_dup_0_satp_changed      = csr_dup[2].satp_changed;
  assign u_page_cache__csr_dup_0_vsatp_asid        = csr_dup[2].vsatp_asid;
  assign u_page_cache__csr_dup_0_vsatp_changed     = csr_dup[2].vsatp_changed;
  assign u_page_cache__csr_dup_0_hgatp_vmid        = csr_dup[2].hgatp_vmid;
  assign u_page_cache__csr_dup_0_hgatp_mode        = csr_dup[2].hgatp_mode;
  assign u_page_cache__csr_dup_0_hgatp_changed     = csr_dup[2].hgatp_changed;
  assign u_page_cache__csr_dup_0_priv_virt         = csr_dup[2].priv_virt;
  assign u_page_cache__csr_dup_0_priv_virt_changed = csr_dup[2].priv_virt_changed;
  assign u_page_cache__csr_dup_0_mbmc_BME          = csr_dup[2].mbmc_BME;
  assign u_page_cache__csr_dup_0_mbmc_CMODE        = csr_dup[2].mbmc_CMODE;
  assign u_page_cache__csr_dup_1_satp_asid         = csr_dup[3].satp_asid;
  assign u_page_cache__csr_dup_1_satp_changed      = csr_dup[3].satp_changed;
  assign u_page_cache__csr_dup_1_vsatp_asid        = csr_dup[3].vsatp_asid;
  assign u_page_cache__csr_dup_1_vsatp_changed     = csr_dup[3].vsatp_changed;
  assign u_page_cache__csr_dup_1_hgatp_vmid        = csr_dup[3].hgatp_vmid;
  assign u_page_cache__csr_dup_1_hgatp_mode        = csr_dup[3].hgatp_mode;
  assign u_page_cache__csr_dup_1_hgatp_changed     = csr_dup[3].hgatp_changed;
  assign u_page_cache__csr_dup_1_priv_virt         = csr_dup[3].priv_virt;
  assign u_page_cache__csr_dup_1_priv_virt_changed = csr_dup[3].priv_virt_changed;
  assign u_page_cache__csr_dup_2_satp_asid         = csr_dup[4].satp_asid;
  assign u_page_cache__csr_dup_2_satp_changed      = csr_dup[4].satp_changed;
  assign u_page_cache__csr_dup_2_vsatp_asid        = csr_dup[4].vsatp_asid;
  assign u_page_cache__csr_dup_2_vsatp_changed     = csr_dup[4].vsatp_changed;
  assign u_page_cache__csr_dup_2_hgatp_vmid        = csr_dup[4].hgatp_vmid;
  assign u_page_cache__csr_dup_2_hgatp_mode        = csr_dup[4].hgatp_mode;
  assign u_page_cache__csr_dup_2_hgatp_changed     = csr_dup[4].hgatp_changed;
  assign u_page_cache__csr_dup_2_priv_virt         = csr_dup[4].priv_virt;
  assign u_page_cache__csr_dup_2_priv_virt_changed = csr_dup[4].priv_virt_changed;
  assign u_page_cache__csr_mPBMTE = csr_dup[2].mPBMTE;
  assign u_page_cache__csr_hPBMTE = csr_dup[2].hPBMTE;
  assign u_page_cache__sfence_dup_0_valid     = sfence_dup[2].valid;
  assign u_page_cache__sfence_dup_0_bits_rs1  = sfence_dup[2].rs1;
  assign u_page_cache__sfence_dup_0_bits_rs2  = sfence_dup[2].rs2;
  assign u_page_cache__sfence_dup_0_bits_addr = sfence_dup[2].addr;
  assign u_page_cache__sfence_dup_0_bits_id   = sfence_dup[2].id;
  assign u_page_cache__sfence_dup_0_bits_hv   = sfence_dup[2].hv;
  assign u_page_cache__sfence_dup_0_bits_hg   = sfence_dup[2].hg;
  assign u_page_cache__sfence_dup_1_valid     = sfence_dup[3].valid;
  assign u_page_cache__sfence_dup_1_bits_id   = sfence_dup[3].id;
  assign u_page_cache__sfence_dup_2_valid     = sfence_dup[4].valid;
  assign u_page_cache__sfence_dup_2_bits_id   = sfence_dup[4].id;
  assign u_page_cache__sfence_dup_2_bits_rs1  = sfence_dup[4].rs1;
  assign u_page_cache__sfence_dup_2_bits_rs2  = sfence_dup[4].rs2;
  // missQueue ← csr 5 / sfence 6
  assign u_miss_queue__csr_satp_changed      = csr_dup[5].satp_changed;
  assign u_miss_queue__csr_vsatp_changed     = csr_dup[5].vsatp_changed;
  assign u_miss_queue__csr_hgatp_changed     = csr_dup[5].hgatp_changed;
  assign u_miss_queue__csr_priv_virt_changed = csr_dup[5].priv_virt_changed;
  assign u_miss_queue__sfence_valid          = sfence_dup[6].valid;
  // ptw ← csr 6 / sfence 7  （G1 去掉了 priv_mxr，加了 mbmc_BME/CMODE、priv_virt_changed）
  assign u_ptw__csr_satp_mode          = csr_dup[6].satp_mode;
  assign u_ptw__csr_satp_asid          = csr_dup[6].satp_asid;
  assign u_ptw__csr_satp_ppn           = csr_dup[6].satp_ppn;
  assign u_ptw__csr_satp_changed       = csr_dup[6].satp_changed;
  assign u_ptw__csr_vsatp_mode         = csr_dup[6].vsatp_mode;
  assign u_ptw__csr_vsatp_asid         = csr_dup[6].vsatp_asid;
  assign u_ptw__csr_vsatp_ppn          = csr_dup[6].vsatp_ppn;
  assign u_ptw__csr_vsatp_changed      = csr_dup[6].vsatp_changed;
  assign u_ptw__csr_hgatp_mode         = csr_dup[6].hgatp_mode;
  assign u_ptw__csr_hgatp_vmid         = csr_dup[6].hgatp_vmid;
  assign u_ptw__csr_hgatp_changed      = csr_dup[6].hgatp_changed;
  assign u_ptw__csr_mbmc_BME           = csr_dup[6].mbmc_BME;
  assign u_ptw__csr_mbmc_CMODE         = csr_dup[6].mbmc_CMODE;
  assign u_ptw__csr_priv_virt_changed  = csr_dup[6].priv_virt_changed;
  assign u_ptw__csr_mPBMTE             = csr_dup[6].mPBMTE;
  assign u_ptw__csr_hPBMTE             = csr_dup[6].hPBMTE;
  assign u_ptw__sfence_valid           = sfence_dup[7].valid;
  // hptw ← csr 7 / sfence 8
  assign u_hptw__csr_satp_changed      = csr_dup[7].satp_changed;
  assign u_hptw__csr_vsatp_changed     = csr_dup[7].vsatp_changed;
  assign u_hptw__csr_hgatp_mode        = csr_dup[7].hgatp_mode;
  assign u_hptw__csr_hgatp_vmid        = csr_dup[7].hgatp_vmid;
  assign u_hptw__csr_hgatp_ppn         = csr_dup[7].hgatp_ppn;
  assign u_hptw__csr_hgatp_changed     = csr_dup[7].hgatp_changed;
  assign u_hptw__csr_mbmc_BME          = csr_dup[7].mbmc_BME;
  assign u_hptw__csr_mbmc_CMODE        = csr_dup[7].mbmc_CMODE;
  assign u_hptw__csr_priv_virt_changed = csr_dup[7].priv_virt_changed;
  assign u_hptw__csr_mPBMTE            = csr_dup[7].mPBMTE;
  assign u_hptw__sfence_valid          = sfence_dup[8].valid;
  // bitmap ← csr 8 / sfence 9（G1 新增）
  assign u_bitmap__csr_satp_changed      = csr_dup[8].satp_changed;
  assign u_bitmap__csr_vsatp_changed     = csr_dup[8].vsatp_changed;
  assign u_bitmap__csr_hgatp_changed     = csr_dup[8].hgatp_changed;
  assign u_bitmap__csr_priv_virt_changed = csr_dup[8].priv_virt_changed;
  assign u_bitmap__csr_mbmc_BMA          = csr_dup[8].mbmc_BMA;
  assign u_bitmap__sfence_valid          = sfence_dup[9].valid;
  // bitmapcache ← csr 9 / sfence 10（G1 新增）
  assign u_bitmap_cache__csr_satp_changed      = csr_dup[9].satp_changed;
  assign u_bitmap_cache__csr_vsatp_changed     = csr_dup[9].vsatp_changed;
  assign u_bitmap_cache__csr_hgatp_changed     = csr_dup[9].hgatp_changed;
  assign u_bitmap_cache__csr_priv_virt_changed = csr_dup[9].priv_virt_changed;
  assign u_bitmap_cache__csr_mbmc_BCLEAR       = csr_dup[9].mbmc_BCLEAR;
  assign u_bitmap_cache__sfence_valid          = sfence_dup[10].valid;

  // ==========================================================================
  // 2. ITLB/DTLB 请求计数与节流（tlbCounter）
  // --------------------------------------------------------------------------
  // 每拍 进入(req fire) - 离开(resp fire)；flush 清零。arb1.out 只在
  // tlbCounter < MissQueueSize(40) 时放行，防 miss queue 溢出。
  // ==========================================================================
  logic [5:0] tlb_counter;
  wire tlb0_req_fire  = u_arb_tlb_in_0_ready & io_tlb_0_req_0_valid;
  wire tlb1_req_fire  = u_arb_tlb_in_1_ready & io_tlb_1_req_0_valid;
  wire tlb0_resp_fire = io_tlb_0_resp_valid & io_tlb_0_resp_ready;
  // tlb_1 的 resp 通道在 golden 里 outArb_1.out.ready 恒 1（顶层没有 resp_ready 端口）。
  wire tlb1_resp_fire = io_tlb_1_resp_valid;
  wire [1:0] n_req  = {1'b0, tlb0_req_fire}  + {1'b0, tlb1_req_fire};
  wire [1:0] n_resp = {1'b0, tlb0_resp_fire} + {1'b0, tlb1_resp_fire};
  always_ff @(posedge clock or posedge reset) begin
    if (reset)      tlb_counter <= '0;
    else if (flush) tlb_counter <= '0;
    else            tlb_counter <= tlb_counter + {4'b0, n_req} - {4'b0, n_resp};
  end
  assign u_arb_tlb__out_ready = u_arb_cache_in_in_3_ready & (tlb_counter < MISS_QUEUE_SIZE);

  // ==========================================================================
  // page cache 响应的常用字段（下面多节共用）
  // --------------------------------------------------------------------------
  // ★G1★ toFsm_toLLPTW / toFsm_toPTW 在 G0 里被常量折叠成 0（bitmap 特性关闭），
  //   G1 是真信号：bitmap 检查跳转时按 toLLPTW 决定回 LLPTW 还是回 PTW。
  // ==========================================================================
  wire       cr_valid     = u_page_cache_resp_valid;
  wire       cr_hit       = u_page_cache_resp_bits_hit;
  wire       cr_isHptwReq = u_page_cache_resp_bits_isHptwReq;
  wire       cr_isFirst   = u_page_cache_resp_bits_isFirst;
  wire       cr_bypassed  = u_page_cache_resp_bits_bypassed;
  wire       cr_l1Hit     = u_page_cache_resp_bits_toFsm_l1Hit;
  wire       cr_stage1Hit = u_page_cache_resp_bits_toFsm_stage1Hit;
  wire [1:0] cr_source    = u_page_cache_resp_bits_req_info_source;
  wire       cr_prefetch  = u_page_cache_resp_bits_prefetch;
  wire       cr_jmp_bm    = u_page_cache_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check;
  wire       cr_bm_toLLPTW= u_page_cache_resp_bits_toFsm_bitmapCheck_toLLPTW;
  wire       toFsm_toLLPTW = cr_jmp_bm &  cr_bm_toLLPTW;
  wire       toFsm_toPTW   = cr_jmp_bm & ~cr_bm_toLLPTW;
  // from_pre：source==2 表示请求来自预取器，用于门控 mq_arb.in_0 与 prefetch.in。
  wire       from_pre     = (cr_source == 2'h2);

  // ==========================================================================
  // 3. page cache 入口仲裁(arb2) 输入装配 + miss queue 仲裁(mq_arb)
  // --------------------------------------------------------------------------
  // arb2 五路：HPTW(0) / PTW(1) / MissQueue(2) / TLB(3) / Prefetch(4)。
  // missQueue 那一路经 block_decoupled：它想进 cache 时，若目标遍历器（按 isLLptw
  // 选 LLPTW 还是 PTW）没 ready 就整路挡住。
  // ==========================================================================
  assign u_arb_cache_in__in_3_valid = tlb0_req_fire | tlb1_req_fire;   // arb1.out.fire
  assign u_arb_cache_in__in_3_bits_req_info_source = {1'b0, u_arb_tlb_chosen};

  wire mq_block = u_miss_queue_out_bits_isLLptw ? ~u_llptw_in_ready : ~u_ptw_req_ready;
  assign u_arb_cache_in__in_2_valid = u_miss_queue_out_valid & ~mq_block;
  assign u_miss_queue__out_ready    = u_arb_cache_in_in_2_ready & ~mq_block;

  // arb2.out → cache.req
  assign u_page_cache__req_valid = u_arb_cache_in_out_valid & u_page_cache_req_ready;
  assign u_page_cache__req_bits_isFirst =
      (u_arb_cache_in_chosen != IN_ARB_MQ[2:0]) & ~u_arb_cache_in_out_bits_isHptwReq;

  // mq_arb.in(0)：cache miss、非预取来源、非 hptwReq，且（被旁路 或 该去的遍历器忙）。
  // ★四处都要带 toFsm_toPTW★（2026-09-20 FM 第二轮逼出来的，见本节末尾的注记）
  wire mq0_cond_ptw   = ((~cr_l1Hit & ~toFsm_toLLPTW) | toFsm_toPTW | cr_stage1Hit)
                        & ~cr_isHptwReq & (cr_isFirst | ~u_ptw_req_ready);
  wire mq0_cond_llptw = ((cr_l1Hit & ~toFsm_toPTW) | toFsm_toLLPTW) & ~u_llptw_in_ready;
  assign u_arb_mq__in_0_valid = cr_valid & ~cr_hit & ~from_pre & ~cr_isHptwReq
                              & (cr_bypassed | mq0_cond_ptw | mq0_cond_llptw);
  // ★G1★ isLLptw：l1Hit 且不是 bitmap 跳转回 PTW，或 bitmap 跳转指明回 LLPTW。
  assign u_arb_mq__in_0_bits_isLLptw = (cr_l1Hit & ~toFsm_toPTW) | toFsm_toLLPTW;

  // ★注记：toFsm_toPTW 在本层一共出现 4 处，一处都不能少★
  // golden L2TLB.sv 里 toFsm_toPTW 除定义外被读 6 次（grep 得 7 行），对应本层 4 个式子
  // （其中两个 golden 写了两遍，是 out/in 各一份）：
  //   golden:13140 ptw.io_req_valid       (~l1Hit & ~toLLPTW | **toPTW**)
  //   golden:19694 mq_arb.in_0_valid      (~l1Hit & ~toLLPTW | **toPTW** | stage1Hit)
  //   golden:19697 mq_arb.in_0_valid      (l1Hit & **~toPTW** | toLLPTW) & ~llptw_in_ready
  //   golden:19703 mq_arb.in_0_isLLptw    (l1Hit & **~toPTW** | toLLPTW)
  //   golden:2144  llptw.io_in_valid      (toLLPTW | l1Hit & **~toPTW**)
  //   golden:3074  cache.io_resp_ready    (toLLPTW | l1Hit & **~toPTW**)
  // 本核起初只在后两处带了它，另外四处按"l1Hit 决定去 LLPTW"写 —— 于是
  // bitmap 跳转指明"回 PTW"（jmp_bitmap_check & ~toLLPTW）且恰好 l1Hit 时，
  // 请求被派给 LLPTW、cache.resp.ready 也跟着错。
  // FM 第二轮（evidence/2eb3d25b6e3e）报的就是这一簇：
  //   cache/io_resp_ready, llptw/io_cache_ready, ptw/io_req_valid,
  //   missQueue/io_in_valid, missQueue/io_in_bits_req_info_vpn[...]
  // ★UT 抓不到★：toFsm_toPTW 要 bitmap 引擎真的发起过跳转检查，而本 tb 里
  // bitmap 路 200k 拍只握手 5 次（a_fire_by_id bitmap=5），如实记在覆盖洞里。

  // hptw_req_arb：in(0)=PTW.hptw.req，in(1)=LLPTW.hptw.req
  assign u_arb_hptw_req__in_0_bits_gvpn = u_ptw_hptw_req_bits_gvpn;
  assign u_arb_hptw_req__in_1_bits_gvpn = u_llptw_hptw_req_bits_gvpn;

  // ==========================================================================
  // 4. PTW / LLPTW / HPTW 请求分发
  // --------------------------------------------------------------------------
  // 按 cache.resp 的命中深度把 miss 请求送往三个遍历器：
  //   LLPTW：已走到倒数第二级（l1Hit）或 bitmap 跳转指明回 LLPTW
  //   PTW  ：还要从更高层走（非 l1Hit），且不是首拍旁路
  //   HPTW ：G-stage 请求
  // ==========================================================================
  assign u_llptw__in_valid = cr_valid & ~cr_hit
                           & (toFsm_toLLPTW | (cr_l1Hit & ~toFsm_toPTW))
                           & ~cr_bypassed & ~cr_isHptwReq;
  assign u_llptw__in_bits_ppn = {6'h0, u_page_cache_resp_bits_toFsm_ppn};

  assign u_ptw__req_valid = cr_valid & ~cr_hit
                          & ((~cr_l1Hit & ~toFsm_toLLPTW) | toFsm_toPTW)
                          & ~cr_bypassed & ~cr_isFirst & ~cr_isHptwReq;
  assign u_ptw__req_bits_ppn = {6'h0, u_page_cache_resp_bits_toFsm_ppn};

  assign u_hptw__req_valid = cr_valid & ~cr_hit & cr_isHptwReq;

  // ==========================================================================
  // 5. page cache resp.ready 多路选择
  // --------------------------------------------------------------------------
  // MuxCase：按 hit / isHptwReq / toLLPTW / bypassed 决定 cache 这拍能否被消费。
  // hptw_resp_arb.in(CACHE).ready 在 golden 恒 1（固定优先级 + out.ready 恒 1）。
  // ==========================================================================
  wire out_ready_cache_s = (cr_source == 2'h1) ? u_merge_arb_1_in_0_ready
                                               : ((|cr_source) | u_merge_arb_0_in_0_ready);
  assign u_page_cache__resp_ready =
      (~cr_hit & cr_isHptwReq) ? u_hptw_req_ready :
      (cr_hit & cr_isHptwReq)  ? 1'b1 :
      cr_hit                   ? out_ready_cache_s :
      (((toFsm_toLLPTW | (cr_l1Hit & ~toFsm_toPTW)) & ~cr_bypassed) & u_llptw_in_ready)
                               ? u_llptw_in_ready :
      (~(cr_bypassed | cr_isFirst) & u_ptw_req_ready) | u_arb_mq_in_0_ready;

  // ==========================================================================
  // 6. 访存数据通路（mem）
  // --------------------------------------------------------------------------
  // mem_arb 四路（PTW(0)/LLPTW(1)/HPTW(2)/Bitmap(3)，★in_3 是 G1 新增★）仲裁后
  // 发往 TileLink A，读 64B PTE 块。D 通道每次 2 个 256bit beat，拼成 512bit。
  // 在途跟踪按 16 个 mem id 展开：0..5 LLPTW / 6 PTW / 7 HPTW / 8..15 Bitmap。
  //   waiting_resp[id]：该 id 有请求在途
  //   flush_latch[id] ：在途期间来过 flush，回来的数据要丢弃
  // ==========================================================================
  wire wfi_req = u_wfi_req_delay_out;
  assign u_mem_arb__out_ready = auto_out_a_ready & ~flush & ~wfi_req;

  wire mem_a_fire = u_mem_arb_out_valid & ~flush & ~wfi_req;
  assign auto_out_a_valid        = mem_a_fire;
  assign auto_out_a_bits_source  = u_mem_arb_out_bits_id;
  assign auto_out_a_bits_address = {u_mem_arb_out_bits_addr[47:6], 6'h0};  // 64B 对齐
  assign auto_out_d_ready        = 1'b1;
  // 登记类寄存器用"握手"而不是 valid：golden 的使能是 out_ready & out_valid，
  // 少了 a_ready 会在对端未 ready 的拍误登记。
  wire mem_a_hs = mem_a_fire & auto_out_a_ready;

  logic [MEM_REQ_WIDTH-1:0]     waiting_resp;
  logic [MEM_REQ_WIDTH-1:0]     flush_latch;
  logic [SECTOR_BITS-1:0]       req_addr_low [MEM_REQ_WIDTH];
  logic                         hptw_bypassed;

  // -- D 通道 beat 跟踪 --
  wire        d_valid   = auto_out_d_valid;
  wire [12:0] beats_dec = 13'h3F << auto_out_d_bits_size;
  wire        beats1    = auto_out_d_bits_opcode[0] & ~beats_dec[5];  // 多 beat（Grant 类）
  logic       beat_cnt;                       // 0=首 beat，1=末 beat
  wire        cnt_m1        = beat_cnt - 1'b1;
  wire        mem_resp_done = (beat_cnt | ~beats1) & d_valid;
  wire        beat_idx      = beats1 & ~cnt_m1; // 本拍数据写入哪一半（1=高半）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)        beat_cnt <= 1'b0;
    else if (d_valid) beat_cnt <= beat_cnt ? (beat_cnt - 1'b1) : beats1;
  end

  wire [MEM_ID_W-1:0] d_src = auto_out_d_bits_source;
  wire mem_resp_from_llptw  = d_src < MEM_ID_W'(LLPTW_SIZE);       // id 0..5
  wire mem_resp_from_ptw    = (d_src == MEM_ID_W'(PTW_MEM_ID));    // id 6
  wire mem_resp_from_hptw   = (d_src == MEM_ID_W'(HPTW_MEM_ID));   // id 7
  wire mem_resp_from_bitmap = d_src[MEM_ID_W-1];                   // id 8..15（G1）

  // refill_data：两个 256bit beat 拼成一块。
  logic [L1_BUS_DATA_W-1:0] refill_data [BEATS];
  for (genvar b = 0; b < BEATS; b++) begin : g_refill_data
    always_ff @(posedge clock or posedge reset)
      if (reset)                             refill_data[b] <= '0;
      else if (d_valid && (beat_idx == b[0])) refill_data[b] <= auto_out_d_bits_data;
  end
  // 当拍旁路视图（比寄存器早一拍），ptw/hptw/bitmap 取 PTE 都用它。
  logic [BLOCK_BITS-1:0] refill_data_tmp;
  always_comb begin
    for (int b = 0; b < BEATS; b++)
      refill_data_tmp[b*L1_BUS_DATA_W +: L1_BUS_DATA_W] =
        (beat_idx == b[0]) ? auto_out_d_bits_data : refill_data[b];
  end
  wire [BLOCK_BITS-1:0] refill_data_flat = {refill_data[1], refill_data[0]};

  // resp_pte：PTW(id6) / HPTW(id7) 各暂存一个 64bit PTE。
  logic [63:0] resp_pte_ptw, resp_pte_hptw;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_pte_ptw <= '0;  resp_pte_hptw <= '0;
    end else begin
      if (mem_resp_done & mem_resp_from_ptw)
        resp_pte_ptw  <= get_part(refill_data_tmp, req_addr_low[PTW_MEM_ID]);
      if (mem_resp_done & mem_resp_from_hptw)
        resp_pte_hptw <= get_part(refill_data_tmp, req_addr_low[HPTW_MEM_ID]);
    end
  end

  // resp_pte_sector：只有 id 0..7 有整块暂存（golden 只给这 8 个 id 建了寄存器；
  // bitmap 的 8..15 走自己的 value 保持寄存器，不进这张表）。
  localparam int SECTOR_ID_NUM = HPTW_MEM_ID + 1;   // 8
  logic [BLOCK_BITS-1:0] resp_pte_sector [SECTOR_ID_NUM];
  wire [LLPTW_SIZE-1:0] llptw_buffer_it =
      {u_llptw_mem_buffer_it_5, u_llptw_mem_buffer_it_4, u_llptw_mem_buffer_it_3,
       u_llptw_mem_buffer_it_2, u_llptw_mem_buffer_it_1, u_llptw_mem_buffer_it_0};
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_resp_sector
    always_ff @(posedge clock or posedge reset)
      if (reset)                   resp_pte_sector[i] <= '0;
      else if (llptw_buffer_it[i]) resp_pte_sector[i] <= refill_data_flat;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_pte_sector[PTW_MEM_ID] <= '0;  resp_pte_sector[HPTW_MEM_ID] <= '0;
    end else begin
      if (mem_resp_done & mem_resp_from_ptw)  resp_pte_sector[PTW_MEM_ID]  <= refill_data_tmp;
      if (mem_resp_done & mem_resp_from_hptw) resp_pte_sector[HPTW_MEM_ID] <= refill_data_tmp;
    end
  end
  // LLPTW 出口选中的块：0..5 在 buffer_it 拍取当拍数据，否则取暂存；6/7 直接取暂存。
  // 用显式 8 路建表而不是变址读，让 FM 两侧都是全定义的 mux（变址读会对不可达下标推 X）。
  logic [BLOCK_BITS-1:0] sector_rd_tbl [SECTOR_ID_NUM];
  always_comb begin
    for (int i = 0; i < LLPTW_SIZE; i++)
      sector_rd_tbl[i] = llptw_buffer_it[i] ? refill_data_flat : resp_pte_sector[i];
    sector_rd_tbl[PTW_MEM_ID]  = resp_pte_sector[PTW_MEM_ID];
    sector_rd_tbl[HPTW_MEM_ID] = resp_pte_sector[HPTW_MEM_ID];
  end
  wire [BLOCK_BITS-1:0] llptw_out_blk = sector_rd_tbl[u_llptw_out_bits_id[SECTOR_BITS-1:0]];

  // -- 在途登记 --
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hptw_bypassed <= 1'b0;
    else if (mem_a_hs)
      hptw_bypassed <= (u_mem_arb_out_bits_id == MEM_ID_W'(HPTW_MEM_ID))
                     & u_mem_arb_out_bits_hptw_bypassed;
  end
  // req_addr_low 在 golden 里是**无复位**寄存器，不能挂到 reset 分支下
  // （否则复位期间的登记被吞掉，与 golden 分叉）。
  always_ff @(posedge clock) begin
    if (u_llptw_in_ready & u_llptw__in_valid)
      req_addr_low[u_llptw_mem_enq_ptr] <=
          addr_low_from_vpn(u_page_cache_resp_bits_req_info_vpn);
    if (mem_a_hs)
      req_addr_low[u_mem_arb_out_bits_id] <= addr_low_from_paddr(u_mem_arb_out_bits_addr);
  end
  for (genvar i = 0; i < MEM_REQ_WIDTH; i++) begin : g_waiting
    // golden 语义：next = ~clear & (set | old) —— 清位优先，同拍清位赢。
    wire wr_set   = mem_a_hs      && (u_mem_arb_out_bits_id == MEM_ID_W'(i));
    wire wr_clear = mem_resp_done && (d_src                 == MEM_ID_W'(i));
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        waiting_resp[i] <= 1'b0;  flush_latch[i] <= 1'b0;
      end else begin
        waiting_resp[i] <= ~wr_clear & (wr_set                   | waiting_resp[i]);
        flush_latch[i]  <= ~wr_clear & ((flush & waiting_resp[i]) | flush_latch[i]);
      end
    end
  end

  // -- mem resp 分发到 llptw / ptw / hptw / bitmap --
  // llptw / bitmap 的 id 与 value 在 golden 里是 holdUnless(d_valid) 保持寄存器，
  // 1:1 镜像以便 FM 配平（resp_valid 时 d_valid 恒 1，行为与直通一致）。
  logic [MEM_ID_W-1:0]   llptw_resp_id_r,  bitmap_resp_id_r;
  logic [BLOCK_BITS-1:0] llptw_resp_val_r, bitmap_resp_val_r;
  always_ff @(posedge clock) if (d_valid) begin
    llptw_resp_id_r   <= d_src;   llptw_resp_val_r  <= refill_data_tmp;
    bitmap_resp_id_r  <= d_src;   bitmap_resp_val_r <= refill_data_tmp;
  end
  assign u_llptw__mem_resp_valid      = mem_resp_done & mem_resp_from_llptw;
  assign u_llptw__mem_resp_bits_id    = d_valid ? d_src : llptw_resp_id_r;
  assign u_llptw__mem_resp_bits_value = d_valid ? refill_data_tmp : llptw_resp_val_r;
  assign u_ptw__mem_resp_valid        = mem_resp_done & mem_resp_from_ptw;
  assign u_ptw__mem_resp_bits         = resp_pte_ptw;
  assign u_ptw__mem_mask              = waiting_resp[PTW_MEM_ID];
  assign u_hptw__mem_resp_valid       = mem_resp_done & mem_resp_from_hptw;
  assign u_hptw__mem_resp_bits        = resp_pte_hptw;
  assign u_hptw__mem_mask             = waiting_resp[HPTW_MEM_ID];
  // ★G1★ bitmap 走自己的 8 个 id（8..15）
  assign u_bitmap__mem_resp_valid      = mem_resp_done & mem_resp_from_bitmap;
  assign u_bitmap__mem_resp_bits_id    = d_valid ? d_src : bitmap_resp_id_r;
  assign u_bitmap__mem_resp_bits_value = d_valid ? refill_data_tmp : bitmap_resp_val_r;
  assign u_llptw__mem_req_mask_0 = waiting_resp[0];
  assign u_llptw__mem_req_mask_1 = waiting_resp[1];
  assign u_llptw__mem_req_mask_2 = waiting_resp[2];
  assign u_llptw__mem_req_mask_3 = waiting_resp[3];
  assign u_llptw__mem_req_mask_4 = waiting_resp[4];
  assign u_llptw__mem_req_mask_5 = waiting_resp[5];
  assign u_llptw__mem_flush_latch_0 = flush_latch[0];
  assign u_llptw__mem_flush_latch_1 = flush_latch[1];
  assign u_llptw__mem_flush_latch_2 = flush_latch[2];
  assign u_llptw__mem_flush_latch_3 = flush_latch[3];
  assign u_llptw__mem_flush_latch_4 = flush_latch[4];
  assign u_llptw__mem_flush_latch_5 = flush_latch[5];
  assign u_bitmap__mem_req_mask_0 = waiting_resp[BITMAP_MEM_BASE + 0];
  assign u_bitmap__mem_req_mask_1 = waiting_resp[BITMAP_MEM_BASE + 1];
  assign u_bitmap__mem_req_mask_2 = waiting_resp[BITMAP_MEM_BASE + 2];
  assign u_bitmap__mem_req_mask_3 = waiting_resp[BITMAP_MEM_BASE + 3];
  assign u_bitmap__mem_req_mask_4 = waiting_resp[BITMAP_MEM_BASE + 4];
  assign u_bitmap__mem_req_mask_5 = waiting_resp[BITMAP_MEM_BASE + 5];
  assign u_bitmap__mem_req_mask_6 = waiting_resp[BITMAP_MEM_BASE + 6];
  assign u_bitmap__mem_req_mask_7 = waiting_resp[BITMAP_MEM_BASE + 7];

  // wfi：等所有 mem id 都不在途才算安全。
  assign u_wfi_safe_delay__in = wfi_req & ~(|waiting_resp);

  // ==========================================================================
  // 6b. cache.refill 装配
  // --------------------------------------------------------------------------
  // 访存回来且不丢弃时置 refill_valid，打一拍给 cache.refill.valid；bits 在
  // refill_valid 那拍锁存。golden 为每个 dup 端口各留一份同值锁存副本（req_info×3 /
  // level×2 / sel_pte×2），这里 1:1 镜像以便 FM 配平，行为与单份完全一致。
  // ==========================================================================
  logic [1:0] ptw_refill_level_r, hptw_refill_level_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ptw_refill_level_r <= 2'h0;  hptw_refill_level_r <= 2'h0;
    end else begin
      if (u_ptw_mem_req_valid  & u_mem_arb_in_0_ready) ptw_refill_level_r  <= u_ptw_refill_level;
      if (u_hptw_mem_req_valid & u_mem_arb_in_2_ready) hptw_refill_level_r <= u_hptw_refill_level;
    end
  end
  wire [1:0] refill_level = mem_resp_from_llptw ? 2'h0
                          : mem_resp_from_ptw   ? ptw_refill_level_r : hptw_refill_level_r;
  // ★bitmap 的访存响应(id 8..15)不算 page cache 的 refill★
  // golden: refill_helper_3 & **~auto_out_d_bits_source[3]** & ~flush & ...
  // 漏了这一项 ⇒ bitmap 引擎取回的 bitmap 行会被当成 PTE 灌进 page cache。
  // 这个 bug 一直没被 UT 抓到，因为改进 PTE 激励之前 bitmap 引擎**一次访存都没发过**
  // （探针实测 bmmem=0）；把 napot/pbmt 造进 PTE 之后第 3141 拍当场现形。
  wire refill_valid = mem_resp_done & ~mem_resp_from_bitmap & ~flush & ~flush_latch[d_src]
                    & ~(mem_resp_from_hptw & hptw_bypassed);
  logic refill_valid_d;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) refill_valid_d <= 1'b0;
    else       refill_valid_d <= refill_valid;
  end
  assign u_page_cache__refill_valid     = refill_valid_d;
  assign u_page_cache__refill_bits_ptes = refill_data_flat;

  ptw_req_info_t refill_req_info_sel;
  always_comb begin
    if (mem_resp_from_llptw)
      refill_req_info_sel = '{vpn:     u_llptw_mem_refill_vpn,
                              s2xlate: u_llptw_mem_refill_s2xlate,
                              source:  u_llptw_mem_refill_source};
    else if (mem_resp_from_ptw)
      refill_req_info_sel = '{vpn:     u_ptw_refill_req_info_vpn,
                              s2xlate: u_ptw_refill_req_info_s2xlate,
                              source:  u_ptw_refill_req_info_source};
    else
      refill_req_info_sel = '{vpn:     u_hptw_refill_req_info_vpn,
                              s2xlate: ONLY_STAGE2,
                              source:  u_hptw_refill_req_info_source};
  end

  ptw_req_info_t refill_req_info_r [3];
  // ★名字不能叫 refill_level_r★（2026-09-20 FM 实测的坑，改名不是美观问题）
  // golden 里有两个**语义完全不同**的寄存器：refill_level_r（PTW 发访存时锁存的
  // 级数）和 refill_level_r_1（HPTW 的那份）。本核把它们叫 ptw_/hptw_refill_level_r。
  // 如果下面这个「送进 page cache 的 level 复制流水」再叫 refill_level_r[2]，
  // fm_eq.tcl 的 auto_match_flattened_arrays 会按命名规则把
  //   golden refill_level_r_1_reg[b]  ←→  impl refill_level_r_reg[1][b]
  // 强行 set_user_match 上 —— 两个不相干的寄存器配成一对，之后整条 refill
  // level 通路（level_dup_0/2 的 BBPin、5 个 levelOH、连带 cache/llptw/missQueue
  // 的握手）全线报不等价。实测 evidence/2eb3d25b6e3e/L2TLB/sidecar/failing_points.txt：
  //   Ref r:/WORK/L2TLB/refill_level_r_1_reg[0]
  //   Impl i:/WORK/L2TLB/u_core/refill_level_r_reg[1][0]        ← 错配
  //   Ref r:/WORK/L2TLB/cache_io_refill_bits_level_dup_0_r_reg[0]
  //   Impl i:/WORK/L2TLB/u_core/hptw_refill_level_r_reg[0]      ← 跟着错配
  logic [1:0]    cache_level_dup_r [2];
  logic [63:0]   refill_sel_pte_r  [2];
  always_ff @(posedge clock) if (refill_valid) begin
    for (int j = 0; j < 3; j++) refill_req_info_r[j] <= refill_req_info_sel;
    for (int j = 0; j < 2; j++) begin
      cache_level_dup_r[j] <= refill_level;
      refill_sel_pte_r[j] <= get_part(refill_data_tmp, req_addr_low[d_src]);
    end
  end
  assign u_page_cache__refill_bits_req_info_dup_0_vpn     = refill_req_info_r[0].vpn;
  assign u_page_cache__refill_bits_req_info_dup_0_s2xlate = refill_req_info_r[0].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_0_source  = refill_req_info_r[0].source;
  assign u_page_cache__refill_bits_req_info_dup_1_vpn     = refill_req_info_r[1].vpn;
  assign u_page_cache__refill_bits_req_info_dup_1_s2xlate = refill_req_info_r[1].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_1_source  = refill_req_info_r[1].source;
  assign u_page_cache__refill_bits_req_info_dup_2_vpn     = refill_req_info_r[2].vpn;
  assign u_page_cache__refill_bits_req_info_dup_2_s2xlate = refill_req_info_r[2].s2xlate;
  assign u_page_cache__refill_bits_req_info_dup_2_source  = refill_req_info_r[2].source;
  assign u_page_cache__refill_bits_level_dup_0   = cache_level_dup_r[0];
  assign u_page_cache__refill_bits_level_dup_2   = cache_level_dup_r[1];
  assign u_page_cache__refill_bits_sel_pte_dup_0 = refill_sel_pte_r[0];
  assign u_page_cache__refill_bits_sel_pte_dup_2 = refill_sel_pte_r[1];

  // levelOH：把 refill_level 译成 5 路独热打一拍。golden 每拍**无条件**赋
  // (cond & refill_valid)（非 refill 拍归 0，不是"保持"），且有复位到 0。
  logic lvOH_l0_r, lvOH_l1_r, lvOH_l2_r, lvOH_l3_r, lvOH_sp_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lvOH_l0_r <= 1'b0; lvOH_l1_r <= 1'b0; lvOH_l2_r <= 1'b0;
      lvOH_l3_r <= 1'b0; lvOH_sp_r <= 1'b0;
    end else begin
      lvOH_l0_r <= (refill_level == 2'h0) & refill_valid;
      lvOH_l1_r <= (refill_level == 2'h1) & refill_valid;
      lvOH_l2_r <= (refill_level == 2'h2) & refill_valid;
      lvOH_l3_r <= (refill_level == 2'h3) & refill_valid;
      lvOH_sp_r <= (refill_level != 2'h0) & refill_valid;
    end
  end
  assign u_page_cache__refill_bits_levelOH_l0 = lvOH_l0_r;
  assign u_page_cache__refill_bits_levelOH_l1 = lvOH_l1_r;
  assign u_page_cache__refill_bits_levelOH_l2 = lvOH_l2_r;
  assign u_page_cache__refill_bits_levelOH_l3 = lvOH_l3_r;
  assign u_page_cache__refill_bits_levelOH_sp = lvOH_sp_r;

  // ==========================================================================
  // 7. HPTW 响应分发
  // --------------------------------------------------------------------------
  // hptw_resp_arb：in(0)=page cache 命中的 hptw 响应，in(1)=HPTW 自己的响应。
  // 仲裁后按 id 分发：id==FsmReqID(6) 回 PTW，否则回 LLPTW。
  // ==========================================================================
  assign u_arb_hptw_resp__in_0_valid   = cr_valid & cr_hit & cr_isHptwReq;
  assign u_arb_hptw_resp__in_1_bits_id = u_hptw_resp_bits_id[SECTOR_BITS-1:0];
  wire hresp_to_ptw = (u_arb_hptw_resp_out_bits_id == SECTOR_BITS'(FSM_REQ_ID));
  assign u_ptw__hptw_resp_valid   = u_arb_hptw_resp_out_valid &  hresp_to_ptw;
  assign u_llptw__hptw_resp_valid = u_arb_hptw_resp_out_valid & ~hresp_to_ptw;

  // ==========================================================================
  // 8. 输出合并：mergeArb 三路 + outArb → ITLB/DTLB resp
  // --------------------------------------------------------------------------
  // 每条 PtwWidth(ITLB/DTLB) 各一组 mergeArb(3 路)+outArb(1 路)：
  //   in(CACHE)=page cache 命中，in(FSM)=PTW 响应，in(MQ)=LLPTW 响应。
  // cache/ptw 两路的 bits 在实例区直连；本核只驱动三路 valid 和 in(MQ) 的 s1。
  // outArb.in(0).s1 = merge_to_sector(mergeArb.out.s1)。
  // ==========================================================================
  // -- llptw_stage1：LLPTW 入队那拍按 enq_ptr 锁存 cache.resp.stage1，供
  //    first_s2xlate_fault 时回放。golden 无复位（纯 enable 锁存），照搬。
  // ★类型用 noaf 版★：PtwCache 的 stage1 输出**没有 af 端口**（golden 里这条路的 af
  // 恒 0，firtool 把端口消掉了，Arbiter3 的 io_in_0_bits_s1_entry_*_af 也不存在）。
  // 用带 af 的 ptw_merge_resp_t 声明会留下 8 个**没人驱动**的位 —— 仿真里被
  // 丢 af 的转换里看不出来，但 Formality 会把它认成 X 源：
  //   analyze_points: "Found 1 X Source  i:/WORK/L2TLB/u_core/C5098
  //                    Propagates 'X' to the impl compare point ... 20 compare points"
  // 实测（+vcs+initreg+0 下 $isunknown，寄存器全 0，X 只可能来自悬空线）：
  //   XPROBE cs1=1  cs1.entry[0..7] x=1   而 sec0/mq_s1/marb0/ls1q 全是 0
  ptw_merge_resp_noaf_t cache_stage1;
  // BEGIN GENERATED(cache_stage1)
  assign cache_stage1.entry[0].tag     = u_page_cache_resp_bits_stage1_entry_0_tag;
  assign cache_stage1.entry[0].asid    = u_page_cache_resp_bits_stage1_entry_0_asid;
  assign cache_stage1.entry[0].vmid    = u_page_cache_resp_bits_stage1_entry_0_vmid;
  assign cache_stage1.entry[0].n       = u_page_cache_resp_bits_stage1_entry_0_n;
  assign cache_stage1.entry[0].pbmt    = u_page_cache_resp_bits_stage1_entry_0_pbmt;
  assign cache_stage1.entry[0].perm.d  = u_page_cache_resp_bits_stage1_entry_0_perm_d;
  assign cache_stage1.entry[0].perm.a  = u_page_cache_resp_bits_stage1_entry_0_perm_a;
  assign cache_stage1.entry[0].perm.g  = u_page_cache_resp_bits_stage1_entry_0_perm_g;
  assign cache_stage1.entry[0].perm.u  = u_page_cache_resp_bits_stage1_entry_0_perm_u;
  assign cache_stage1.entry[0].perm.x  = u_page_cache_resp_bits_stage1_entry_0_perm_x;
  assign cache_stage1.entry[0].perm.w  = u_page_cache_resp_bits_stage1_entry_0_perm_w;
  assign cache_stage1.entry[0].perm.r  = u_page_cache_resp_bits_stage1_entry_0_perm_r;
  assign cache_stage1.entry[0].level   = u_page_cache_resp_bits_stage1_entry_0_level;
  assign cache_stage1.entry[0].v       = u_page_cache_resp_bits_stage1_entry_0_v;
  assign cache_stage1.entry[0].ppn     = u_page_cache_resp_bits_stage1_entry_0_ppn;
  assign cache_stage1.entry[0].ppn_low = u_page_cache_resp_bits_stage1_entry_0_ppn_low;
  assign cache_stage1.entry[0].pf      = u_page_cache_resp_bits_stage1_entry_0_pf;
  assign cache_stage1.entry[0].cf      = u_page_cache_resp_bits_stage1_entry_0_cf;
  assign cache_stage1.entry[1].tag     = u_page_cache_resp_bits_stage1_entry_1_tag;
  assign cache_stage1.entry[1].asid    = u_page_cache_resp_bits_stage1_entry_1_asid;
  assign cache_stage1.entry[1].vmid    = u_page_cache_resp_bits_stage1_entry_1_vmid;
  assign cache_stage1.entry[1].n       = u_page_cache_resp_bits_stage1_entry_1_n;
  assign cache_stage1.entry[1].pbmt    = u_page_cache_resp_bits_stage1_entry_1_pbmt;
  assign cache_stage1.entry[1].perm.d  = u_page_cache_resp_bits_stage1_entry_1_perm_d;
  assign cache_stage1.entry[1].perm.a  = u_page_cache_resp_bits_stage1_entry_1_perm_a;
  assign cache_stage1.entry[1].perm.g  = u_page_cache_resp_bits_stage1_entry_1_perm_g;
  assign cache_stage1.entry[1].perm.u  = u_page_cache_resp_bits_stage1_entry_1_perm_u;
  assign cache_stage1.entry[1].perm.x  = u_page_cache_resp_bits_stage1_entry_1_perm_x;
  assign cache_stage1.entry[1].perm.w  = u_page_cache_resp_bits_stage1_entry_1_perm_w;
  assign cache_stage1.entry[1].perm.r  = u_page_cache_resp_bits_stage1_entry_1_perm_r;
  assign cache_stage1.entry[1].level   = u_page_cache_resp_bits_stage1_entry_1_level;
  assign cache_stage1.entry[1].v       = u_page_cache_resp_bits_stage1_entry_1_v;
  assign cache_stage1.entry[1].ppn     = u_page_cache_resp_bits_stage1_entry_1_ppn;
  assign cache_stage1.entry[1].ppn_low = u_page_cache_resp_bits_stage1_entry_1_ppn_low;
  assign cache_stage1.entry[1].pf      = u_page_cache_resp_bits_stage1_entry_1_pf;
  assign cache_stage1.entry[1].cf      = u_page_cache_resp_bits_stage1_entry_1_cf;
  assign cache_stage1.entry[2].tag     = u_page_cache_resp_bits_stage1_entry_2_tag;
  assign cache_stage1.entry[2].asid    = u_page_cache_resp_bits_stage1_entry_2_asid;
  assign cache_stage1.entry[2].vmid    = u_page_cache_resp_bits_stage1_entry_2_vmid;
  assign cache_stage1.entry[2].n       = u_page_cache_resp_bits_stage1_entry_2_n;
  assign cache_stage1.entry[2].pbmt    = u_page_cache_resp_bits_stage1_entry_2_pbmt;
  assign cache_stage1.entry[2].perm.d  = u_page_cache_resp_bits_stage1_entry_2_perm_d;
  assign cache_stage1.entry[2].perm.a  = u_page_cache_resp_bits_stage1_entry_2_perm_a;
  assign cache_stage1.entry[2].perm.g  = u_page_cache_resp_bits_stage1_entry_2_perm_g;
  assign cache_stage1.entry[2].perm.u  = u_page_cache_resp_bits_stage1_entry_2_perm_u;
  assign cache_stage1.entry[2].perm.x  = u_page_cache_resp_bits_stage1_entry_2_perm_x;
  assign cache_stage1.entry[2].perm.w  = u_page_cache_resp_bits_stage1_entry_2_perm_w;
  assign cache_stage1.entry[2].perm.r  = u_page_cache_resp_bits_stage1_entry_2_perm_r;
  assign cache_stage1.entry[2].level   = u_page_cache_resp_bits_stage1_entry_2_level;
  assign cache_stage1.entry[2].v       = u_page_cache_resp_bits_stage1_entry_2_v;
  assign cache_stage1.entry[2].ppn     = u_page_cache_resp_bits_stage1_entry_2_ppn;
  assign cache_stage1.entry[2].ppn_low = u_page_cache_resp_bits_stage1_entry_2_ppn_low;
  assign cache_stage1.entry[2].pf      = u_page_cache_resp_bits_stage1_entry_2_pf;
  assign cache_stage1.entry[2].cf      = u_page_cache_resp_bits_stage1_entry_2_cf;
  assign cache_stage1.entry[3].tag     = u_page_cache_resp_bits_stage1_entry_3_tag;
  assign cache_stage1.entry[3].asid    = u_page_cache_resp_bits_stage1_entry_3_asid;
  assign cache_stage1.entry[3].vmid    = u_page_cache_resp_bits_stage1_entry_3_vmid;
  assign cache_stage1.entry[3].n       = u_page_cache_resp_bits_stage1_entry_3_n;
  assign cache_stage1.entry[3].pbmt    = u_page_cache_resp_bits_stage1_entry_3_pbmt;
  assign cache_stage1.entry[3].perm.d  = u_page_cache_resp_bits_stage1_entry_3_perm_d;
  assign cache_stage1.entry[3].perm.a  = u_page_cache_resp_bits_stage1_entry_3_perm_a;
  assign cache_stage1.entry[3].perm.g  = u_page_cache_resp_bits_stage1_entry_3_perm_g;
  assign cache_stage1.entry[3].perm.u  = u_page_cache_resp_bits_stage1_entry_3_perm_u;
  assign cache_stage1.entry[3].perm.x  = u_page_cache_resp_bits_stage1_entry_3_perm_x;
  assign cache_stage1.entry[3].perm.w  = u_page_cache_resp_bits_stage1_entry_3_perm_w;
  assign cache_stage1.entry[3].perm.r  = u_page_cache_resp_bits_stage1_entry_3_perm_r;
  assign cache_stage1.entry[3].level   = u_page_cache_resp_bits_stage1_entry_3_level;
  assign cache_stage1.entry[3].v       = u_page_cache_resp_bits_stage1_entry_3_v;
  assign cache_stage1.entry[3].ppn     = u_page_cache_resp_bits_stage1_entry_3_ppn;
  assign cache_stage1.entry[3].ppn_low = u_page_cache_resp_bits_stage1_entry_3_ppn_low;
  assign cache_stage1.entry[3].pf      = u_page_cache_resp_bits_stage1_entry_3_pf;
  assign cache_stage1.entry[3].cf      = u_page_cache_resp_bits_stage1_entry_3_cf;
  assign cache_stage1.entry[4].tag     = u_page_cache_resp_bits_stage1_entry_4_tag;
  assign cache_stage1.entry[4].asid    = u_page_cache_resp_bits_stage1_entry_4_asid;
  assign cache_stage1.entry[4].vmid    = u_page_cache_resp_bits_stage1_entry_4_vmid;
  assign cache_stage1.entry[4].n       = u_page_cache_resp_bits_stage1_entry_4_n;
  assign cache_stage1.entry[4].pbmt    = u_page_cache_resp_bits_stage1_entry_4_pbmt;
  assign cache_stage1.entry[4].perm.d  = u_page_cache_resp_bits_stage1_entry_4_perm_d;
  assign cache_stage1.entry[4].perm.a  = u_page_cache_resp_bits_stage1_entry_4_perm_a;
  assign cache_stage1.entry[4].perm.g  = u_page_cache_resp_bits_stage1_entry_4_perm_g;
  assign cache_stage1.entry[4].perm.u  = u_page_cache_resp_bits_stage1_entry_4_perm_u;
  assign cache_stage1.entry[4].perm.x  = u_page_cache_resp_bits_stage1_entry_4_perm_x;
  assign cache_stage1.entry[4].perm.w  = u_page_cache_resp_bits_stage1_entry_4_perm_w;
  assign cache_stage1.entry[4].perm.r  = u_page_cache_resp_bits_stage1_entry_4_perm_r;
  assign cache_stage1.entry[4].level   = u_page_cache_resp_bits_stage1_entry_4_level;
  assign cache_stage1.entry[4].v       = u_page_cache_resp_bits_stage1_entry_4_v;
  assign cache_stage1.entry[4].ppn     = u_page_cache_resp_bits_stage1_entry_4_ppn;
  assign cache_stage1.entry[4].ppn_low = u_page_cache_resp_bits_stage1_entry_4_ppn_low;
  assign cache_stage1.entry[4].pf      = u_page_cache_resp_bits_stage1_entry_4_pf;
  assign cache_stage1.entry[4].cf      = u_page_cache_resp_bits_stage1_entry_4_cf;
  assign cache_stage1.entry[5].tag     = u_page_cache_resp_bits_stage1_entry_5_tag;
  assign cache_stage1.entry[5].asid    = u_page_cache_resp_bits_stage1_entry_5_asid;
  assign cache_stage1.entry[5].vmid    = u_page_cache_resp_bits_stage1_entry_5_vmid;
  assign cache_stage1.entry[5].n       = u_page_cache_resp_bits_stage1_entry_5_n;
  assign cache_stage1.entry[5].pbmt    = u_page_cache_resp_bits_stage1_entry_5_pbmt;
  assign cache_stage1.entry[5].perm.d  = u_page_cache_resp_bits_stage1_entry_5_perm_d;
  assign cache_stage1.entry[5].perm.a  = u_page_cache_resp_bits_stage1_entry_5_perm_a;
  assign cache_stage1.entry[5].perm.g  = u_page_cache_resp_bits_stage1_entry_5_perm_g;
  assign cache_stage1.entry[5].perm.u  = u_page_cache_resp_bits_stage1_entry_5_perm_u;
  assign cache_stage1.entry[5].perm.x  = u_page_cache_resp_bits_stage1_entry_5_perm_x;
  assign cache_stage1.entry[5].perm.w  = u_page_cache_resp_bits_stage1_entry_5_perm_w;
  assign cache_stage1.entry[5].perm.r  = u_page_cache_resp_bits_stage1_entry_5_perm_r;
  assign cache_stage1.entry[5].level   = u_page_cache_resp_bits_stage1_entry_5_level;
  assign cache_stage1.entry[5].v       = u_page_cache_resp_bits_stage1_entry_5_v;
  assign cache_stage1.entry[5].ppn     = u_page_cache_resp_bits_stage1_entry_5_ppn;
  assign cache_stage1.entry[5].ppn_low = u_page_cache_resp_bits_stage1_entry_5_ppn_low;
  assign cache_stage1.entry[5].pf      = u_page_cache_resp_bits_stage1_entry_5_pf;
  assign cache_stage1.entry[5].cf      = u_page_cache_resp_bits_stage1_entry_5_cf;
  assign cache_stage1.entry[6].tag     = u_page_cache_resp_bits_stage1_entry_6_tag;
  assign cache_stage1.entry[6].asid    = u_page_cache_resp_bits_stage1_entry_6_asid;
  assign cache_stage1.entry[6].vmid    = u_page_cache_resp_bits_stage1_entry_6_vmid;
  assign cache_stage1.entry[6].n       = u_page_cache_resp_bits_stage1_entry_6_n;
  assign cache_stage1.entry[6].pbmt    = u_page_cache_resp_bits_stage1_entry_6_pbmt;
  assign cache_stage1.entry[6].perm.d  = u_page_cache_resp_bits_stage1_entry_6_perm_d;
  assign cache_stage1.entry[6].perm.a  = u_page_cache_resp_bits_stage1_entry_6_perm_a;
  assign cache_stage1.entry[6].perm.g  = u_page_cache_resp_bits_stage1_entry_6_perm_g;
  assign cache_stage1.entry[6].perm.u  = u_page_cache_resp_bits_stage1_entry_6_perm_u;
  assign cache_stage1.entry[6].perm.x  = u_page_cache_resp_bits_stage1_entry_6_perm_x;
  assign cache_stage1.entry[6].perm.w  = u_page_cache_resp_bits_stage1_entry_6_perm_w;
  assign cache_stage1.entry[6].perm.r  = u_page_cache_resp_bits_stage1_entry_6_perm_r;
  assign cache_stage1.entry[6].level   = u_page_cache_resp_bits_stage1_entry_6_level;
  assign cache_stage1.entry[6].v       = u_page_cache_resp_bits_stage1_entry_6_v;
  assign cache_stage1.entry[6].ppn     = u_page_cache_resp_bits_stage1_entry_6_ppn;
  assign cache_stage1.entry[6].ppn_low = u_page_cache_resp_bits_stage1_entry_6_ppn_low;
  assign cache_stage1.entry[6].pf      = u_page_cache_resp_bits_stage1_entry_6_pf;
  assign cache_stage1.entry[6].cf      = u_page_cache_resp_bits_stage1_entry_6_cf;
  assign cache_stage1.entry[7].tag     = u_page_cache_resp_bits_stage1_entry_7_tag;
  assign cache_stage1.entry[7].asid    = u_page_cache_resp_bits_stage1_entry_7_asid;
  assign cache_stage1.entry[7].vmid    = u_page_cache_resp_bits_stage1_entry_7_vmid;
  assign cache_stage1.entry[7].n       = u_page_cache_resp_bits_stage1_entry_7_n;
  assign cache_stage1.entry[7].pbmt    = u_page_cache_resp_bits_stage1_entry_7_pbmt;
  assign cache_stage1.entry[7].perm.d  = u_page_cache_resp_bits_stage1_entry_7_perm_d;
  assign cache_stage1.entry[7].perm.a  = u_page_cache_resp_bits_stage1_entry_7_perm_a;
  assign cache_stage1.entry[7].perm.g  = u_page_cache_resp_bits_stage1_entry_7_perm_g;
  assign cache_stage1.entry[7].perm.u  = u_page_cache_resp_bits_stage1_entry_7_perm_u;
  assign cache_stage1.entry[7].perm.x  = u_page_cache_resp_bits_stage1_entry_7_perm_x;
  assign cache_stage1.entry[7].perm.w  = u_page_cache_resp_bits_stage1_entry_7_perm_w;
  assign cache_stage1.entry[7].perm.r  = u_page_cache_resp_bits_stage1_entry_7_perm_r;
  assign cache_stage1.entry[7].level   = u_page_cache_resp_bits_stage1_entry_7_level;
  assign cache_stage1.entry[7].v       = u_page_cache_resp_bits_stage1_entry_7_v;
  assign cache_stage1.entry[7].ppn     = u_page_cache_resp_bits_stage1_entry_7_ppn;
  assign cache_stage1.entry[7].ppn_low = u_page_cache_resp_bits_stage1_entry_7_ppn_low;
  assign cache_stage1.entry[7].pf      = u_page_cache_resp_bits_stage1_entry_7_pf;
  assign cache_stage1.entry[7].cf      = u_page_cache_resp_bits_stage1_entry_7_cf;
  assign cache_stage1.pteidx[0]        = u_page_cache_resp_bits_stage1_pteidx_0;
  assign cache_stage1.pteidx[1]        = u_page_cache_resp_bits_stage1_pteidx_1;
  assign cache_stage1.pteidx[2]        = u_page_cache_resp_bits_stage1_pteidx_2;
  assign cache_stage1.pteidx[3]        = u_page_cache_resp_bits_stage1_pteidx_3;
  assign cache_stage1.pteidx[4]        = u_page_cache_resp_bits_stage1_pteidx_4;
  assign cache_stage1.pteidx[5]        = u_page_cache_resp_bits_stage1_pteidx_5;
  assign cache_stage1.pteidx[6]        = u_page_cache_resp_bits_stage1_pteidx_6;
  assign cache_stage1.pteidx[7]        = u_page_cache_resp_bits_stage1_pteidx_7;
  assign cache_stage1.not_super        = u_page_cache_resp_bits_stage1_not_super;
  // END GENERATED

  ptw_merge_resp_noaf_t llptw_stage1_q [LLPTW_SIZE];
  ptw_merge_resp_t      llptw_stage1   [LLPTW_SIZE];
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_stage1_rd
    assign llptw_stage1[i] = mrg_from_noaf(llptw_stage1_q[i]);
  end
  for (genvar i = 0; i < LLPTW_SIZE; i++) begin : g_llptw_stage1
    always_ff @(posedge clock)
      if ((u_llptw_in_ready & u_llptw__in_valid)
          && (u_llptw_mem_enq_ptr == SECTOR_BITS'(i)))
        llptw_stage1_q[i] <= cache_stage1;   // 类型已是 noaf，无需再转
  end

  // -- mergeArb 三路 valid --
  wire [1:0] llptw_out_src = u_llptw_out_bits_req_info_source;
  assign u_merge_arb_0__in_2_valid = u_llptw_out_valid & (llptw_out_src == 2'h0);
  assign u_merge_arb_1__in_2_valid = u_llptw_out_valid & (llptw_out_src == 2'h1);
  assign u_merge_arb_0__in_1_valid = u_ptw_resp_valid & (u_ptw_resp_bits_source == 2'h0);
  assign u_merge_arb_1__in_1_valid = u_ptw_resp_valid & (u_ptw_resp_bits_source == 2'h1);
  assign u_merge_arb_0__in_0_valid = cr_valid & cr_hit & (cr_source == 2'h0) & ~cr_isHptwReq;
  assign u_merge_arb_1__in_0_valid = cr_valid & cr_hit & (cr_source == 2'h1) & ~cr_isHptwReq;

  // ptw.resp.ready / llptw.out.ready：按 source 选对应那组 mergeArb 的 in.ready；
  // source∈{2,3}（预取等）时 golden 恒 ready=1，故 else 分支要带 (|source) 项。
  assign u_ptw__resp_ready = (u_ptw_resp_bits_source == 2'h1)
                           ? u_merge_arb_1_in_1_ready
                           : ((|u_ptw_resp_bits_source) | u_merge_arb_0_in_1_ready);
  assign u_llptw__out_ready = (llptw_out_src == 2'h1)
                            ? u_merge_arb_1_in_2_ready
                            : ((|llptw_out_src) | u_merge_arb_0_in_2_ready);

  // -- in(MQ).bits.s1 --
  // ★G1★ 合并用的 PTE 块有两个来源：bitmap 检查跳转时用 LLPTW 随响应带回的 8 条
  //   ptes，否则用访存回来的 sector 块。
  wire [BLOCK_BITS-1:0] llptw_bm_ptes =
      {u_llptw_out_bits_bitmapCheck_ptes_7, u_llptw_out_bits_bitmapCheck_ptes_6,
       u_llptw_out_bits_bitmapCheck_ptes_5, u_llptw_out_bits_bitmapCheck_ptes_4,
       u_llptw_out_bits_bitmapCheck_ptes_3, u_llptw_out_bits_bitmapCheck_ptes_2,
       u_llptw_out_bits_bitmapCheck_ptes_1, u_llptw_out_bits_bitmapCheck_ptes_0};
  wire [CONTIG-1:0] llptw_bm_cfs =
      {u_llptw_out_bits_bitmapCheck_cfs_7, u_llptw_out_bits_bitmapCheck_cfs_6,
       u_llptw_out_bits_bitmapCheck_cfs_5, u_llptw_out_bits_bitmapCheck_cfs_4,
       u_llptw_out_bits_bitmapCheck_cfs_3, u_llptw_out_bits_bitmapCheck_cfs_2,
       u_llptw_out_bits_bitmapCheck_cfs_1, u_llptw_out_bits_bitmapCheck_cfs_0};
  wire [BLOCK_BITS-1:0] merge_pte_blk =
      u_llptw_out_bits_bitmapCheck_jmp_bitmap_check ? llptw_bm_ptes : llptw_out_blk;

  // llptw 的 id 是 3bit(0..7) 但 stage1 只有 6 项。golden 的选择表把 id 6/7 回绕到
  // stage1[0]；这里用显式 8 路 mux 照搬（变址读会让 FM 对 6/7 推 X，出假分叉）。
  ptw_merge_resp_t llptw_stage1_sel;
  always_comb begin
    unique case (u_llptw_out_bits_id[SECTOR_BITS-1:0])
      3'd0:    llptw_stage1_sel = llptw_stage1[0];
      3'd1:    llptw_stage1_sel = llptw_stage1[1];
      3'd2:    llptw_stage1_sel = llptw_stage1[2];
      3'd3:    llptw_stage1_sel = llptw_stage1[3];
      3'd4:    llptw_stage1_sel = llptw_stage1[4];
      3'd5:    llptw_stage1_sel = llptw_stage1[5];
      default: llptw_stage1_sel = llptw_stage1[0];   // id 6/7 回绕，对齐 golden
    endcase
  end
  ptw_merge_resp_t mq_s1;
  always_comb begin
    if (u_llptw_out_bits_first_s2xlate_fault)
      mq_s1 = llptw_stage1_sel;
    else
      mq_s1 = contiguous_pte_to_merge(
          merge_pte_blk, llptw_bm_cfs,
          u_llptw_out_bits_req_info_vpn, u_llptw_out_bits_af,
          u_llptw_out_bits_req_info_s2xlate,
          csr_dup[0].mPBMTE, csr_dup[0].hPBMTE,
          csr_dup[0].satp_asid, csr_dup[0].vsatp_asid, csr_dup[0].hgatp_vmid);
  end
  // not_merge 不是 mq_s1 的字段，是本层现算的：只有 llptw 这一路、且确实带 G-stage
  // （s2xlate 非 0）、且不是在回放 stage1 时，才"不合并"。
  wire mq_not_merge = ~u_llptw_out_bits_first_s2xlate_fault
                    & (|u_llptw_out_bits_req_info_s2xlate);
  assign u_merge_arb_0__in_2_bits_s1_not_merge = mq_not_merge;
  assign u_merge_arb_1__in_2_bits_s1_not_merge = mq_not_merge;
  // BEGIN GENERATED(merge_in2)
  assign u_merge_arb_0__in_2_bits_s1_entry_0_tag     = mq_s1.entry[0].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_asid    = mq_s1.entry[0].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_vmid    = mq_s1.entry[0].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_n       = mq_s1.entry[0].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_pbmt    = mq_s1.entry[0].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_d  = mq_s1.entry[0].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_a  = mq_s1.entry[0].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_g  = mq_s1.entry[0].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_u  = mq_s1.entry[0].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_x  = mq_s1.entry[0].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_w  = mq_s1.entry[0].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_perm_r  = mq_s1.entry[0].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_level   = mq_s1.entry[0].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_v       = mq_s1.entry[0].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_ppn     = mq_s1.entry[0].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_ppn_low = mq_s1.entry[0].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_af      = mq_s1.entry[0].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_pf      = mq_s1.entry[0].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_0_cf      = mq_s1.entry[0].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_tag     = mq_s1.entry[1].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_asid    = mq_s1.entry[1].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_vmid    = mq_s1.entry[1].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_n       = mq_s1.entry[1].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_pbmt    = mq_s1.entry[1].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_d  = mq_s1.entry[1].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_a  = mq_s1.entry[1].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_g  = mq_s1.entry[1].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_u  = mq_s1.entry[1].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_x  = mq_s1.entry[1].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_w  = mq_s1.entry[1].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_perm_r  = mq_s1.entry[1].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_level   = mq_s1.entry[1].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_v       = mq_s1.entry[1].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_ppn     = mq_s1.entry[1].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_ppn_low = mq_s1.entry[1].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_af      = mq_s1.entry[1].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_pf      = mq_s1.entry[1].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_1_cf      = mq_s1.entry[1].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_tag     = mq_s1.entry[2].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_asid    = mq_s1.entry[2].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_vmid    = mq_s1.entry[2].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_n       = mq_s1.entry[2].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_pbmt    = mq_s1.entry[2].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_d  = mq_s1.entry[2].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_a  = mq_s1.entry[2].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_g  = mq_s1.entry[2].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_u  = mq_s1.entry[2].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_x  = mq_s1.entry[2].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_w  = mq_s1.entry[2].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_perm_r  = mq_s1.entry[2].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_level   = mq_s1.entry[2].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_v       = mq_s1.entry[2].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_ppn     = mq_s1.entry[2].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_ppn_low = mq_s1.entry[2].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_af      = mq_s1.entry[2].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_pf      = mq_s1.entry[2].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_2_cf      = mq_s1.entry[2].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_tag     = mq_s1.entry[3].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_asid    = mq_s1.entry[3].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_vmid    = mq_s1.entry[3].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_n       = mq_s1.entry[3].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_pbmt    = mq_s1.entry[3].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_d  = mq_s1.entry[3].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_a  = mq_s1.entry[3].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_g  = mq_s1.entry[3].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_u  = mq_s1.entry[3].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_x  = mq_s1.entry[3].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_w  = mq_s1.entry[3].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_perm_r  = mq_s1.entry[3].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_level   = mq_s1.entry[3].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_v       = mq_s1.entry[3].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_ppn     = mq_s1.entry[3].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_ppn_low = mq_s1.entry[3].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_af      = mq_s1.entry[3].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_pf      = mq_s1.entry[3].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_3_cf      = mq_s1.entry[3].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_tag     = mq_s1.entry[4].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_asid    = mq_s1.entry[4].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_vmid    = mq_s1.entry[4].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_n       = mq_s1.entry[4].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_pbmt    = mq_s1.entry[4].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_d  = mq_s1.entry[4].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_a  = mq_s1.entry[4].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_g  = mq_s1.entry[4].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_u  = mq_s1.entry[4].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_x  = mq_s1.entry[4].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_w  = mq_s1.entry[4].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_perm_r  = mq_s1.entry[4].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_level   = mq_s1.entry[4].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_v       = mq_s1.entry[4].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_ppn     = mq_s1.entry[4].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_ppn_low = mq_s1.entry[4].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_af      = mq_s1.entry[4].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_pf      = mq_s1.entry[4].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_4_cf      = mq_s1.entry[4].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_tag     = mq_s1.entry[5].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_asid    = mq_s1.entry[5].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_vmid    = mq_s1.entry[5].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_n       = mq_s1.entry[5].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_pbmt    = mq_s1.entry[5].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_d  = mq_s1.entry[5].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_a  = mq_s1.entry[5].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_g  = mq_s1.entry[5].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_u  = mq_s1.entry[5].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_x  = mq_s1.entry[5].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_w  = mq_s1.entry[5].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_perm_r  = mq_s1.entry[5].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_level   = mq_s1.entry[5].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_v       = mq_s1.entry[5].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_ppn     = mq_s1.entry[5].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_ppn_low = mq_s1.entry[5].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_af      = mq_s1.entry[5].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_pf      = mq_s1.entry[5].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_5_cf      = mq_s1.entry[5].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_tag     = mq_s1.entry[6].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_asid    = mq_s1.entry[6].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_vmid    = mq_s1.entry[6].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_n       = mq_s1.entry[6].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_pbmt    = mq_s1.entry[6].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_d  = mq_s1.entry[6].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_a  = mq_s1.entry[6].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_g  = mq_s1.entry[6].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_u  = mq_s1.entry[6].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_x  = mq_s1.entry[6].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_w  = mq_s1.entry[6].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_perm_r  = mq_s1.entry[6].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_level   = mq_s1.entry[6].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_v       = mq_s1.entry[6].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_ppn     = mq_s1.entry[6].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_ppn_low = mq_s1.entry[6].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_af      = mq_s1.entry[6].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_pf      = mq_s1.entry[6].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_6_cf      = mq_s1.entry[6].cf;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_tag     = mq_s1.entry[7].tag;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_asid    = mq_s1.entry[7].asid;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_vmid    = mq_s1.entry[7].vmid;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_n       = mq_s1.entry[7].n;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_pbmt    = mq_s1.entry[7].pbmt;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_d  = mq_s1.entry[7].perm.d;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_a  = mq_s1.entry[7].perm.a;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_g  = mq_s1.entry[7].perm.g;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_u  = mq_s1.entry[7].perm.u;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_x  = mq_s1.entry[7].perm.x;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_w  = mq_s1.entry[7].perm.w;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_perm_r  = mq_s1.entry[7].perm.r;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_level   = mq_s1.entry[7].level;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_v       = mq_s1.entry[7].v;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_ppn     = mq_s1.entry[7].ppn;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_ppn_low = mq_s1.entry[7].ppn_low;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_af      = mq_s1.entry[7].af;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_pf      = mq_s1.entry[7].pf;
  assign u_merge_arb_0__in_2_bits_s1_entry_7_cf      = mq_s1.entry[7].cf;
  assign u_merge_arb_0__in_2_bits_s1_pteidx_0        = mq_s1.pteidx[0];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_1        = mq_s1.pteidx[1];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_2        = mq_s1.pteidx[2];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_3        = mq_s1.pteidx[3];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_4        = mq_s1.pteidx[4];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_5        = mq_s1.pteidx[5];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_6        = mq_s1.pteidx[6];
  assign u_merge_arb_0__in_2_bits_s1_pteidx_7        = mq_s1.pteidx[7];
  assign u_merge_arb_0__in_2_bits_s1_not_super       = mq_s1.not_super;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_tag     = mq_s1.entry[0].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_asid    = mq_s1.entry[0].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_vmid    = mq_s1.entry[0].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_n       = mq_s1.entry[0].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_pbmt    = mq_s1.entry[0].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_d  = mq_s1.entry[0].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_a  = mq_s1.entry[0].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_g  = mq_s1.entry[0].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_u  = mq_s1.entry[0].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_x  = mq_s1.entry[0].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_w  = mq_s1.entry[0].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_perm_r  = mq_s1.entry[0].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_level   = mq_s1.entry[0].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_v       = mq_s1.entry[0].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_ppn     = mq_s1.entry[0].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_ppn_low = mq_s1.entry[0].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_af      = mq_s1.entry[0].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_pf      = mq_s1.entry[0].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_0_cf      = mq_s1.entry[0].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_tag     = mq_s1.entry[1].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_asid    = mq_s1.entry[1].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_vmid    = mq_s1.entry[1].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_n       = mq_s1.entry[1].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_pbmt    = mq_s1.entry[1].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_d  = mq_s1.entry[1].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_a  = mq_s1.entry[1].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_g  = mq_s1.entry[1].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_u  = mq_s1.entry[1].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_x  = mq_s1.entry[1].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_w  = mq_s1.entry[1].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_perm_r  = mq_s1.entry[1].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_level   = mq_s1.entry[1].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_v       = mq_s1.entry[1].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_ppn     = mq_s1.entry[1].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_ppn_low = mq_s1.entry[1].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_af      = mq_s1.entry[1].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_pf      = mq_s1.entry[1].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_1_cf      = mq_s1.entry[1].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_tag     = mq_s1.entry[2].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_asid    = mq_s1.entry[2].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_vmid    = mq_s1.entry[2].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_n       = mq_s1.entry[2].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_pbmt    = mq_s1.entry[2].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_d  = mq_s1.entry[2].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_a  = mq_s1.entry[2].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_g  = mq_s1.entry[2].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_u  = mq_s1.entry[2].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_x  = mq_s1.entry[2].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_w  = mq_s1.entry[2].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_perm_r  = mq_s1.entry[2].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_level   = mq_s1.entry[2].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_v       = mq_s1.entry[2].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_ppn     = mq_s1.entry[2].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_ppn_low = mq_s1.entry[2].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_af      = mq_s1.entry[2].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_pf      = mq_s1.entry[2].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_2_cf      = mq_s1.entry[2].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_tag     = mq_s1.entry[3].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_asid    = mq_s1.entry[3].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_vmid    = mq_s1.entry[3].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_n       = mq_s1.entry[3].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_pbmt    = mq_s1.entry[3].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_d  = mq_s1.entry[3].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_a  = mq_s1.entry[3].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_g  = mq_s1.entry[3].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_u  = mq_s1.entry[3].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_x  = mq_s1.entry[3].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_w  = mq_s1.entry[3].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_perm_r  = mq_s1.entry[3].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_level   = mq_s1.entry[3].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_v       = mq_s1.entry[3].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_ppn     = mq_s1.entry[3].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_ppn_low = mq_s1.entry[3].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_af      = mq_s1.entry[3].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_pf      = mq_s1.entry[3].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_3_cf      = mq_s1.entry[3].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_tag     = mq_s1.entry[4].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_asid    = mq_s1.entry[4].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_vmid    = mq_s1.entry[4].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_n       = mq_s1.entry[4].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_pbmt    = mq_s1.entry[4].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_d  = mq_s1.entry[4].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_a  = mq_s1.entry[4].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_g  = mq_s1.entry[4].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_u  = mq_s1.entry[4].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_x  = mq_s1.entry[4].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_w  = mq_s1.entry[4].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_perm_r  = mq_s1.entry[4].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_level   = mq_s1.entry[4].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_v       = mq_s1.entry[4].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_ppn     = mq_s1.entry[4].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_ppn_low = mq_s1.entry[4].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_af      = mq_s1.entry[4].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_pf      = mq_s1.entry[4].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_4_cf      = mq_s1.entry[4].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_tag     = mq_s1.entry[5].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_asid    = mq_s1.entry[5].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_vmid    = mq_s1.entry[5].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_n       = mq_s1.entry[5].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_pbmt    = mq_s1.entry[5].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_d  = mq_s1.entry[5].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_a  = mq_s1.entry[5].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_g  = mq_s1.entry[5].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_u  = mq_s1.entry[5].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_x  = mq_s1.entry[5].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_w  = mq_s1.entry[5].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_perm_r  = mq_s1.entry[5].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_level   = mq_s1.entry[5].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_v       = mq_s1.entry[5].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_ppn     = mq_s1.entry[5].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_ppn_low = mq_s1.entry[5].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_af      = mq_s1.entry[5].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_pf      = mq_s1.entry[5].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_5_cf      = mq_s1.entry[5].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_tag     = mq_s1.entry[6].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_asid    = mq_s1.entry[6].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_vmid    = mq_s1.entry[6].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_n       = mq_s1.entry[6].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_pbmt    = mq_s1.entry[6].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_d  = mq_s1.entry[6].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_a  = mq_s1.entry[6].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_g  = mq_s1.entry[6].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_u  = mq_s1.entry[6].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_x  = mq_s1.entry[6].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_w  = mq_s1.entry[6].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_perm_r  = mq_s1.entry[6].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_level   = mq_s1.entry[6].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_v       = mq_s1.entry[6].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_ppn     = mq_s1.entry[6].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_ppn_low = mq_s1.entry[6].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_af      = mq_s1.entry[6].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_pf      = mq_s1.entry[6].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_6_cf      = mq_s1.entry[6].cf;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_tag     = mq_s1.entry[7].tag;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_asid    = mq_s1.entry[7].asid;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_vmid    = mq_s1.entry[7].vmid;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_n       = mq_s1.entry[7].n;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_pbmt    = mq_s1.entry[7].pbmt;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_d  = mq_s1.entry[7].perm.d;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_a  = mq_s1.entry[7].perm.a;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_g  = mq_s1.entry[7].perm.g;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_u  = mq_s1.entry[7].perm.u;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_x  = mq_s1.entry[7].perm.x;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_w  = mq_s1.entry[7].perm.w;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_perm_r  = mq_s1.entry[7].perm.r;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_level   = mq_s1.entry[7].level;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_v       = mq_s1.entry[7].v;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_ppn     = mq_s1.entry[7].ppn;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_ppn_low = mq_s1.entry[7].ppn_low;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_af      = mq_s1.entry[7].af;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_pf      = mq_s1.entry[7].pf;
  assign u_merge_arb_1__in_2_bits_s1_entry_7_cf      = mq_s1.entry[7].cf;
  assign u_merge_arb_1__in_2_bits_s1_pteidx_0        = mq_s1.pteidx[0];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_1        = mq_s1.pteidx[1];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_2        = mq_s1.pteidx[2];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_3        = mq_s1.pteidx[3];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_4        = mq_s1.pteidx[4];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_5        = mq_s1.pteidx[5];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_6        = mq_s1.pteidx[6];
  assign u_merge_arb_1__in_2_bits_s1_pteidx_7        = mq_s1.pteidx[7];
  assign u_merge_arb_1__in_2_bits_s1_not_super       = mq_s1.not_super;
  // END GENERATED

  // -- outArb.in(0).s1 = merge_to_sector(mergeArb.out.s1) --
  ptw_merge_resp_t marb0_out_s1, marb1_out_s1;
  // BEGIN GENERATED(marb_out)
  assign marb0_out_s1.entry[0].tag     = u_merge_arb_0_out_bits_s1_entry_0_tag;
  assign marb0_out_s1.entry[0].asid    = u_merge_arb_0_out_bits_s1_entry_0_asid;
  assign marb0_out_s1.entry[0].vmid    = u_merge_arb_0_out_bits_s1_entry_0_vmid;
  assign marb0_out_s1.entry[0].n       = u_merge_arb_0_out_bits_s1_entry_0_n;
  assign marb0_out_s1.entry[0].pbmt    = u_merge_arb_0_out_bits_s1_entry_0_pbmt;
  assign marb0_out_s1.entry[0].perm.d  = u_merge_arb_0_out_bits_s1_entry_0_perm_d;
  assign marb0_out_s1.entry[0].perm.a  = u_merge_arb_0_out_bits_s1_entry_0_perm_a;
  assign marb0_out_s1.entry[0].perm.g  = u_merge_arb_0_out_bits_s1_entry_0_perm_g;
  assign marb0_out_s1.entry[0].perm.u  = u_merge_arb_0_out_bits_s1_entry_0_perm_u;
  assign marb0_out_s1.entry[0].perm.x  = u_merge_arb_0_out_bits_s1_entry_0_perm_x;
  assign marb0_out_s1.entry[0].perm.w  = u_merge_arb_0_out_bits_s1_entry_0_perm_w;
  assign marb0_out_s1.entry[0].perm.r  = u_merge_arb_0_out_bits_s1_entry_0_perm_r;
  assign marb0_out_s1.entry[0].level   = u_merge_arb_0_out_bits_s1_entry_0_level;
  assign marb0_out_s1.entry[0].v       = u_merge_arb_0_out_bits_s1_entry_0_v;
  assign marb0_out_s1.entry[0].ppn     = u_merge_arb_0_out_bits_s1_entry_0_ppn;
  assign marb0_out_s1.entry[0].ppn_low = u_merge_arb_0_out_bits_s1_entry_0_ppn_low;
  assign marb0_out_s1.entry[0].af      = u_merge_arb_0_out_bits_s1_entry_0_af;
  assign marb0_out_s1.entry[0].pf      = u_merge_arb_0_out_bits_s1_entry_0_pf;
  assign marb0_out_s1.entry[0].cf      = u_merge_arb_0_out_bits_s1_entry_0_cf;
  assign marb0_out_s1.entry[1].tag     = u_merge_arb_0_out_bits_s1_entry_1_tag;
  assign marb0_out_s1.entry[1].asid    = u_merge_arb_0_out_bits_s1_entry_1_asid;
  assign marb0_out_s1.entry[1].vmid    = u_merge_arb_0_out_bits_s1_entry_1_vmid;
  assign marb0_out_s1.entry[1].n       = u_merge_arb_0_out_bits_s1_entry_1_n;
  assign marb0_out_s1.entry[1].pbmt    = u_merge_arb_0_out_bits_s1_entry_1_pbmt;
  assign marb0_out_s1.entry[1].perm.d  = u_merge_arb_0_out_bits_s1_entry_1_perm_d;
  assign marb0_out_s1.entry[1].perm.a  = u_merge_arb_0_out_bits_s1_entry_1_perm_a;
  assign marb0_out_s1.entry[1].perm.g  = u_merge_arb_0_out_bits_s1_entry_1_perm_g;
  assign marb0_out_s1.entry[1].perm.u  = u_merge_arb_0_out_bits_s1_entry_1_perm_u;
  assign marb0_out_s1.entry[1].perm.x  = u_merge_arb_0_out_bits_s1_entry_1_perm_x;
  assign marb0_out_s1.entry[1].perm.w  = u_merge_arb_0_out_bits_s1_entry_1_perm_w;
  assign marb0_out_s1.entry[1].perm.r  = u_merge_arb_0_out_bits_s1_entry_1_perm_r;
  assign marb0_out_s1.entry[1].level   = u_merge_arb_0_out_bits_s1_entry_1_level;
  assign marb0_out_s1.entry[1].v       = u_merge_arb_0_out_bits_s1_entry_1_v;
  assign marb0_out_s1.entry[1].ppn     = u_merge_arb_0_out_bits_s1_entry_1_ppn;
  assign marb0_out_s1.entry[1].ppn_low = u_merge_arb_0_out_bits_s1_entry_1_ppn_low;
  assign marb0_out_s1.entry[1].af      = u_merge_arb_0_out_bits_s1_entry_1_af;
  assign marb0_out_s1.entry[1].pf      = u_merge_arb_0_out_bits_s1_entry_1_pf;
  assign marb0_out_s1.entry[1].cf      = u_merge_arb_0_out_bits_s1_entry_1_cf;
  assign marb0_out_s1.entry[2].tag     = u_merge_arb_0_out_bits_s1_entry_2_tag;
  assign marb0_out_s1.entry[2].asid    = u_merge_arb_0_out_bits_s1_entry_2_asid;
  assign marb0_out_s1.entry[2].vmid    = u_merge_arb_0_out_bits_s1_entry_2_vmid;
  assign marb0_out_s1.entry[2].n       = u_merge_arb_0_out_bits_s1_entry_2_n;
  assign marb0_out_s1.entry[2].pbmt    = u_merge_arb_0_out_bits_s1_entry_2_pbmt;
  assign marb0_out_s1.entry[2].perm.d  = u_merge_arb_0_out_bits_s1_entry_2_perm_d;
  assign marb0_out_s1.entry[2].perm.a  = u_merge_arb_0_out_bits_s1_entry_2_perm_a;
  assign marb0_out_s1.entry[2].perm.g  = u_merge_arb_0_out_bits_s1_entry_2_perm_g;
  assign marb0_out_s1.entry[2].perm.u  = u_merge_arb_0_out_bits_s1_entry_2_perm_u;
  assign marb0_out_s1.entry[2].perm.x  = u_merge_arb_0_out_bits_s1_entry_2_perm_x;
  assign marb0_out_s1.entry[2].perm.w  = u_merge_arb_0_out_bits_s1_entry_2_perm_w;
  assign marb0_out_s1.entry[2].perm.r  = u_merge_arb_0_out_bits_s1_entry_2_perm_r;
  assign marb0_out_s1.entry[2].level   = u_merge_arb_0_out_bits_s1_entry_2_level;
  assign marb0_out_s1.entry[2].v       = u_merge_arb_0_out_bits_s1_entry_2_v;
  assign marb0_out_s1.entry[2].ppn     = u_merge_arb_0_out_bits_s1_entry_2_ppn;
  assign marb0_out_s1.entry[2].ppn_low = u_merge_arb_0_out_bits_s1_entry_2_ppn_low;
  assign marb0_out_s1.entry[2].af      = u_merge_arb_0_out_bits_s1_entry_2_af;
  assign marb0_out_s1.entry[2].pf      = u_merge_arb_0_out_bits_s1_entry_2_pf;
  assign marb0_out_s1.entry[2].cf      = u_merge_arb_0_out_bits_s1_entry_2_cf;
  assign marb0_out_s1.entry[3].tag     = u_merge_arb_0_out_bits_s1_entry_3_tag;
  assign marb0_out_s1.entry[3].asid    = u_merge_arb_0_out_bits_s1_entry_3_asid;
  assign marb0_out_s1.entry[3].vmid    = u_merge_arb_0_out_bits_s1_entry_3_vmid;
  assign marb0_out_s1.entry[3].n       = u_merge_arb_0_out_bits_s1_entry_3_n;
  assign marb0_out_s1.entry[3].pbmt    = u_merge_arb_0_out_bits_s1_entry_3_pbmt;
  assign marb0_out_s1.entry[3].perm.d  = u_merge_arb_0_out_bits_s1_entry_3_perm_d;
  assign marb0_out_s1.entry[3].perm.a  = u_merge_arb_0_out_bits_s1_entry_3_perm_a;
  assign marb0_out_s1.entry[3].perm.g  = u_merge_arb_0_out_bits_s1_entry_3_perm_g;
  assign marb0_out_s1.entry[3].perm.u  = u_merge_arb_0_out_bits_s1_entry_3_perm_u;
  assign marb0_out_s1.entry[3].perm.x  = u_merge_arb_0_out_bits_s1_entry_3_perm_x;
  assign marb0_out_s1.entry[3].perm.w  = u_merge_arb_0_out_bits_s1_entry_3_perm_w;
  assign marb0_out_s1.entry[3].perm.r  = u_merge_arb_0_out_bits_s1_entry_3_perm_r;
  assign marb0_out_s1.entry[3].level   = u_merge_arb_0_out_bits_s1_entry_3_level;
  assign marb0_out_s1.entry[3].v       = u_merge_arb_0_out_bits_s1_entry_3_v;
  assign marb0_out_s1.entry[3].ppn     = u_merge_arb_0_out_bits_s1_entry_3_ppn;
  assign marb0_out_s1.entry[3].ppn_low = u_merge_arb_0_out_bits_s1_entry_3_ppn_low;
  assign marb0_out_s1.entry[3].af      = u_merge_arb_0_out_bits_s1_entry_3_af;
  assign marb0_out_s1.entry[3].pf      = u_merge_arb_0_out_bits_s1_entry_3_pf;
  assign marb0_out_s1.entry[3].cf      = u_merge_arb_0_out_bits_s1_entry_3_cf;
  assign marb0_out_s1.entry[4].tag     = u_merge_arb_0_out_bits_s1_entry_4_tag;
  assign marb0_out_s1.entry[4].asid    = u_merge_arb_0_out_bits_s1_entry_4_asid;
  assign marb0_out_s1.entry[4].vmid    = u_merge_arb_0_out_bits_s1_entry_4_vmid;
  assign marb0_out_s1.entry[4].n       = u_merge_arb_0_out_bits_s1_entry_4_n;
  assign marb0_out_s1.entry[4].pbmt    = u_merge_arb_0_out_bits_s1_entry_4_pbmt;
  assign marb0_out_s1.entry[4].perm.d  = u_merge_arb_0_out_bits_s1_entry_4_perm_d;
  assign marb0_out_s1.entry[4].perm.a  = u_merge_arb_0_out_bits_s1_entry_4_perm_a;
  assign marb0_out_s1.entry[4].perm.g  = u_merge_arb_0_out_bits_s1_entry_4_perm_g;
  assign marb0_out_s1.entry[4].perm.u  = u_merge_arb_0_out_bits_s1_entry_4_perm_u;
  assign marb0_out_s1.entry[4].perm.x  = u_merge_arb_0_out_bits_s1_entry_4_perm_x;
  assign marb0_out_s1.entry[4].perm.w  = u_merge_arb_0_out_bits_s1_entry_4_perm_w;
  assign marb0_out_s1.entry[4].perm.r  = u_merge_arb_0_out_bits_s1_entry_4_perm_r;
  assign marb0_out_s1.entry[4].level   = u_merge_arb_0_out_bits_s1_entry_4_level;
  assign marb0_out_s1.entry[4].v       = u_merge_arb_0_out_bits_s1_entry_4_v;
  assign marb0_out_s1.entry[4].ppn     = u_merge_arb_0_out_bits_s1_entry_4_ppn;
  assign marb0_out_s1.entry[4].ppn_low = u_merge_arb_0_out_bits_s1_entry_4_ppn_low;
  assign marb0_out_s1.entry[4].af      = u_merge_arb_0_out_bits_s1_entry_4_af;
  assign marb0_out_s1.entry[4].pf      = u_merge_arb_0_out_bits_s1_entry_4_pf;
  assign marb0_out_s1.entry[4].cf      = u_merge_arb_0_out_bits_s1_entry_4_cf;
  assign marb0_out_s1.entry[5].tag     = u_merge_arb_0_out_bits_s1_entry_5_tag;
  assign marb0_out_s1.entry[5].asid    = u_merge_arb_0_out_bits_s1_entry_5_asid;
  assign marb0_out_s1.entry[5].vmid    = u_merge_arb_0_out_bits_s1_entry_5_vmid;
  assign marb0_out_s1.entry[5].n       = u_merge_arb_0_out_bits_s1_entry_5_n;
  assign marb0_out_s1.entry[5].pbmt    = u_merge_arb_0_out_bits_s1_entry_5_pbmt;
  assign marb0_out_s1.entry[5].perm.d  = u_merge_arb_0_out_bits_s1_entry_5_perm_d;
  assign marb0_out_s1.entry[5].perm.a  = u_merge_arb_0_out_bits_s1_entry_5_perm_a;
  assign marb0_out_s1.entry[5].perm.g  = u_merge_arb_0_out_bits_s1_entry_5_perm_g;
  assign marb0_out_s1.entry[5].perm.u  = u_merge_arb_0_out_bits_s1_entry_5_perm_u;
  assign marb0_out_s1.entry[5].perm.x  = u_merge_arb_0_out_bits_s1_entry_5_perm_x;
  assign marb0_out_s1.entry[5].perm.w  = u_merge_arb_0_out_bits_s1_entry_5_perm_w;
  assign marb0_out_s1.entry[5].perm.r  = u_merge_arb_0_out_bits_s1_entry_5_perm_r;
  assign marb0_out_s1.entry[5].level   = u_merge_arb_0_out_bits_s1_entry_5_level;
  assign marb0_out_s1.entry[5].v       = u_merge_arb_0_out_bits_s1_entry_5_v;
  assign marb0_out_s1.entry[5].ppn     = u_merge_arb_0_out_bits_s1_entry_5_ppn;
  assign marb0_out_s1.entry[5].ppn_low = u_merge_arb_0_out_bits_s1_entry_5_ppn_low;
  assign marb0_out_s1.entry[5].af      = u_merge_arb_0_out_bits_s1_entry_5_af;
  assign marb0_out_s1.entry[5].pf      = u_merge_arb_0_out_bits_s1_entry_5_pf;
  assign marb0_out_s1.entry[5].cf      = u_merge_arb_0_out_bits_s1_entry_5_cf;
  assign marb0_out_s1.entry[6].tag     = u_merge_arb_0_out_bits_s1_entry_6_tag;
  assign marb0_out_s1.entry[6].asid    = u_merge_arb_0_out_bits_s1_entry_6_asid;
  assign marb0_out_s1.entry[6].vmid    = u_merge_arb_0_out_bits_s1_entry_6_vmid;
  assign marb0_out_s1.entry[6].n       = u_merge_arb_0_out_bits_s1_entry_6_n;
  assign marb0_out_s1.entry[6].pbmt    = u_merge_arb_0_out_bits_s1_entry_6_pbmt;
  assign marb0_out_s1.entry[6].perm.d  = u_merge_arb_0_out_bits_s1_entry_6_perm_d;
  assign marb0_out_s1.entry[6].perm.a  = u_merge_arb_0_out_bits_s1_entry_6_perm_a;
  assign marb0_out_s1.entry[6].perm.g  = u_merge_arb_0_out_bits_s1_entry_6_perm_g;
  assign marb0_out_s1.entry[6].perm.u  = u_merge_arb_0_out_bits_s1_entry_6_perm_u;
  assign marb0_out_s1.entry[6].perm.x  = u_merge_arb_0_out_bits_s1_entry_6_perm_x;
  assign marb0_out_s1.entry[6].perm.w  = u_merge_arb_0_out_bits_s1_entry_6_perm_w;
  assign marb0_out_s1.entry[6].perm.r  = u_merge_arb_0_out_bits_s1_entry_6_perm_r;
  assign marb0_out_s1.entry[6].level   = u_merge_arb_0_out_bits_s1_entry_6_level;
  assign marb0_out_s1.entry[6].v       = u_merge_arb_0_out_bits_s1_entry_6_v;
  assign marb0_out_s1.entry[6].ppn     = u_merge_arb_0_out_bits_s1_entry_6_ppn;
  assign marb0_out_s1.entry[6].ppn_low = u_merge_arb_0_out_bits_s1_entry_6_ppn_low;
  assign marb0_out_s1.entry[6].af      = u_merge_arb_0_out_bits_s1_entry_6_af;
  assign marb0_out_s1.entry[6].pf      = u_merge_arb_0_out_bits_s1_entry_6_pf;
  assign marb0_out_s1.entry[6].cf      = u_merge_arb_0_out_bits_s1_entry_6_cf;
  assign marb0_out_s1.entry[7].tag     = u_merge_arb_0_out_bits_s1_entry_7_tag;
  assign marb0_out_s1.entry[7].asid    = u_merge_arb_0_out_bits_s1_entry_7_asid;
  assign marb0_out_s1.entry[7].vmid    = u_merge_arb_0_out_bits_s1_entry_7_vmid;
  assign marb0_out_s1.entry[7].n       = u_merge_arb_0_out_bits_s1_entry_7_n;
  assign marb0_out_s1.entry[7].pbmt    = u_merge_arb_0_out_bits_s1_entry_7_pbmt;
  assign marb0_out_s1.entry[7].perm.d  = u_merge_arb_0_out_bits_s1_entry_7_perm_d;
  assign marb0_out_s1.entry[7].perm.a  = u_merge_arb_0_out_bits_s1_entry_7_perm_a;
  assign marb0_out_s1.entry[7].perm.g  = u_merge_arb_0_out_bits_s1_entry_7_perm_g;
  assign marb0_out_s1.entry[7].perm.u  = u_merge_arb_0_out_bits_s1_entry_7_perm_u;
  assign marb0_out_s1.entry[7].perm.x  = u_merge_arb_0_out_bits_s1_entry_7_perm_x;
  assign marb0_out_s1.entry[7].perm.w  = u_merge_arb_0_out_bits_s1_entry_7_perm_w;
  assign marb0_out_s1.entry[7].perm.r  = u_merge_arb_0_out_bits_s1_entry_7_perm_r;
  assign marb0_out_s1.entry[7].level   = u_merge_arb_0_out_bits_s1_entry_7_level;
  assign marb0_out_s1.entry[7].v       = u_merge_arb_0_out_bits_s1_entry_7_v;
  assign marb0_out_s1.entry[7].ppn     = u_merge_arb_0_out_bits_s1_entry_7_ppn;
  assign marb0_out_s1.entry[7].ppn_low = u_merge_arb_0_out_bits_s1_entry_7_ppn_low;
  assign marb0_out_s1.entry[7].af      = u_merge_arb_0_out_bits_s1_entry_7_af;
  assign marb0_out_s1.entry[7].pf      = u_merge_arb_0_out_bits_s1_entry_7_pf;
  assign marb0_out_s1.entry[7].cf      = u_merge_arb_0_out_bits_s1_entry_7_cf;
  assign marb0_out_s1.pteidx[0]        = u_merge_arb_0_out_bits_s1_pteidx_0;
  assign marb0_out_s1.pteidx[1]        = u_merge_arb_0_out_bits_s1_pteidx_1;
  assign marb0_out_s1.pteidx[2]        = u_merge_arb_0_out_bits_s1_pteidx_2;
  assign marb0_out_s1.pteidx[3]        = u_merge_arb_0_out_bits_s1_pteidx_3;
  assign marb0_out_s1.pteidx[4]        = u_merge_arb_0_out_bits_s1_pteidx_4;
  assign marb0_out_s1.pteidx[5]        = u_merge_arb_0_out_bits_s1_pteidx_5;
  assign marb0_out_s1.pteidx[6]        = u_merge_arb_0_out_bits_s1_pteidx_6;
  assign marb0_out_s1.pteidx[7]        = u_merge_arb_0_out_bits_s1_pteidx_7;
  assign marb0_out_s1.not_super        = u_merge_arb_0_out_bits_s1_not_super;
  assign marb1_out_s1.entry[0].tag     = u_merge_arb_1_out_bits_s1_entry_0_tag;
  assign marb1_out_s1.entry[0].asid    = u_merge_arb_1_out_bits_s1_entry_0_asid;
  assign marb1_out_s1.entry[0].vmid    = u_merge_arb_1_out_bits_s1_entry_0_vmid;
  assign marb1_out_s1.entry[0].n       = u_merge_arb_1_out_bits_s1_entry_0_n;
  assign marb1_out_s1.entry[0].pbmt    = u_merge_arb_1_out_bits_s1_entry_0_pbmt;
  assign marb1_out_s1.entry[0].perm.d  = u_merge_arb_1_out_bits_s1_entry_0_perm_d;
  assign marb1_out_s1.entry[0].perm.a  = u_merge_arb_1_out_bits_s1_entry_0_perm_a;
  assign marb1_out_s1.entry[0].perm.g  = u_merge_arb_1_out_bits_s1_entry_0_perm_g;
  assign marb1_out_s1.entry[0].perm.u  = u_merge_arb_1_out_bits_s1_entry_0_perm_u;
  assign marb1_out_s1.entry[0].perm.x  = u_merge_arb_1_out_bits_s1_entry_0_perm_x;
  assign marb1_out_s1.entry[0].perm.w  = u_merge_arb_1_out_bits_s1_entry_0_perm_w;
  assign marb1_out_s1.entry[0].perm.r  = u_merge_arb_1_out_bits_s1_entry_0_perm_r;
  assign marb1_out_s1.entry[0].level   = u_merge_arb_1_out_bits_s1_entry_0_level;
  assign marb1_out_s1.entry[0].v       = u_merge_arb_1_out_bits_s1_entry_0_v;
  assign marb1_out_s1.entry[0].ppn     = u_merge_arb_1_out_bits_s1_entry_0_ppn;
  assign marb1_out_s1.entry[0].ppn_low = u_merge_arb_1_out_bits_s1_entry_0_ppn_low;
  assign marb1_out_s1.entry[0].af      = u_merge_arb_1_out_bits_s1_entry_0_af;
  assign marb1_out_s1.entry[0].pf      = u_merge_arb_1_out_bits_s1_entry_0_pf;
  assign marb1_out_s1.entry[0].cf      = u_merge_arb_1_out_bits_s1_entry_0_cf;
  assign marb1_out_s1.entry[1].tag     = u_merge_arb_1_out_bits_s1_entry_1_tag;
  assign marb1_out_s1.entry[1].asid    = u_merge_arb_1_out_bits_s1_entry_1_asid;
  assign marb1_out_s1.entry[1].vmid    = u_merge_arb_1_out_bits_s1_entry_1_vmid;
  assign marb1_out_s1.entry[1].n       = u_merge_arb_1_out_bits_s1_entry_1_n;
  assign marb1_out_s1.entry[1].pbmt    = u_merge_arb_1_out_bits_s1_entry_1_pbmt;
  assign marb1_out_s1.entry[1].perm.d  = u_merge_arb_1_out_bits_s1_entry_1_perm_d;
  assign marb1_out_s1.entry[1].perm.a  = u_merge_arb_1_out_bits_s1_entry_1_perm_a;
  assign marb1_out_s1.entry[1].perm.g  = u_merge_arb_1_out_bits_s1_entry_1_perm_g;
  assign marb1_out_s1.entry[1].perm.u  = u_merge_arb_1_out_bits_s1_entry_1_perm_u;
  assign marb1_out_s1.entry[1].perm.x  = u_merge_arb_1_out_bits_s1_entry_1_perm_x;
  assign marb1_out_s1.entry[1].perm.w  = u_merge_arb_1_out_bits_s1_entry_1_perm_w;
  assign marb1_out_s1.entry[1].perm.r  = u_merge_arb_1_out_bits_s1_entry_1_perm_r;
  assign marb1_out_s1.entry[1].level   = u_merge_arb_1_out_bits_s1_entry_1_level;
  assign marb1_out_s1.entry[1].v       = u_merge_arb_1_out_bits_s1_entry_1_v;
  assign marb1_out_s1.entry[1].ppn     = u_merge_arb_1_out_bits_s1_entry_1_ppn;
  assign marb1_out_s1.entry[1].ppn_low = u_merge_arb_1_out_bits_s1_entry_1_ppn_low;
  assign marb1_out_s1.entry[1].af      = u_merge_arb_1_out_bits_s1_entry_1_af;
  assign marb1_out_s1.entry[1].pf      = u_merge_arb_1_out_bits_s1_entry_1_pf;
  assign marb1_out_s1.entry[1].cf      = u_merge_arb_1_out_bits_s1_entry_1_cf;
  assign marb1_out_s1.entry[2].tag     = u_merge_arb_1_out_bits_s1_entry_2_tag;
  assign marb1_out_s1.entry[2].asid    = u_merge_arb_1_out_bits_s1_entry_2_asid;
  assign marb1_out_s1.entry[2].vmid    = u_merge_arb_1_out_bits_s1_entry_2_vmid;
  assign marb1_out_s1.entry[2].n       = u_merge_arb_1_out_bits_s1_entry_2_n;
  assign marb1_out_s1.entry[2].pbmt    = u_merge_arb_1_out_bits_s1_entry_2_pbmt;
  assign marb1_out_s1.entry[2].perm.d  = u_merge_arb_1_out_bits_s1_entry_2_perm_d;
  assign marb1_out_s1.entry[2].perm.a  = u_merge_arb_1_out_bits_s1_entry_2_perm_a;
  assign marb1_out_s1.entry[2].perm.g  = u_merge_arb_1_out_bits_s1_entry_2_perm_g;
  assign marb1_out_s1.entry[2].perm.u  = u_merge_arb_1_out_bits_s1_entry_2_perm_u;
  assign marb1_out_s1.entry[2].perm.x  = u_merge_arb_1_out_bits_s1_entry_2_perm_x;
  assign marb1_out_s1.entry[2].perm.w  = u_merge_arb_1_out_bits_s1_entry_2_perm_w;
  assign marb1_out_s1.entry[2].perm.r  = u_merge_arb_1_out_bits_s1_entry_2_perm_r;
  assign marb1_out_s1.entry[2].level   = u_merge_arb_1_out_bits_s1_entry_2_level;
  assign marb1_out_s1.entry[2].v       = u_merge_arb_1_out_bits_s1_entry_2_v;
  assign marb1_out_s1.entry[2].ppn     = u_merge_arb_1_out_bits_s1_entry_2_ppn;
  assign marb1_out_s1.entry[2].ppn_low = u_merge_arb_1_out_bits_s1_entry_2_ppn_low;
  assign marb1_out_s1.entry[2].af      = u_merge_arb_1_out_bits_s1_entry_2_af;
  assign marb1_out_s1.entry[2].pf      = u_merge_arb_1_out_bits_s1_entry_2_pf;
  assign marb1_out_s1.entry[2].cf      = u_merge_arb_1_out_bits_s1_entry_2_cf;
  assign marb1_out_s1.entry[3].tag     = u_merge_arb_1_out_bits_s1_entry_3_tag;
  assign marb1_out_s1.entry[3].asid    = u_merge_arb_1_out_bits_s1_entry_3_asid;
  assign marb1_out_s1.entry[3].vmid    = u_merge_arb_1_out_bits_s1_entry_3_vmid;
  assign marb1_out_s1.entry[3].n       = u_merge_arb_1_out_bits_s1_entry_3_n;
  assign marb1_out_s1.entry[3].pbmt    = u_merge_arb_1_out_bits_s1_entry_3_pbmt;
  assign marb1_out_s1.entry[3].perm.d  = u_merge_arb_1_out_bits_s1_entry_3_perm_d;
  assign marb1_out_s1.entry[3].perm.a  = u_merge_arb_1_out_bits_s1_entry_3_perm_a;
  assign marb1_out_s1.entry[3].perm.g  = u_merge_arb_1_out_bits_s1_entry_3_perm_g;
  assign marb1_out_s1.entry[3].perm.u  = u_merge_arb_1_out_bits_s1_entry_3_perm_u;
  assign marb1_out_s1.entry[3].perm.x  = u_merge_arb_1_out_bits_s1_entry_3_perm_x;
  assign marb1_out_s1.entry[3].perm.w  = u_merge_arb_1_out_bits_s1_entry_3_perm_w;
  assign marb1_out_s1.entry[3].perm.r  = u_merge_arb_1_out_bits_s1_entry_3_perm_r;
  assign marb1_out_s1.entry[3].level   = u_merge_arb_1_out_bits_s1_entry_3_level;
  assign marb1_out_s1.entry[3].v       = u_merge_arb_1_out_bits_s1_entry_3_v;
  assign marb1_out_s1.entry[3].ppn     = u_merge_arb_1_out_bits_s1_entry_3_ppn;
  assign marb1_out_s1.entry[3].ppn_low = u_merge_arb_1_out_bits_s1_entry_3_ppn_low;
  assign marb1_out_s1.entry[3].af      = u_merge_arb_1_out_bits_s1_entry_3_af;
  assign marb1_out_s1.entry[3].pf      = u_merge_arb_1_out_bits_s1_entry_3_pf;
  assign marb1_out_s1.entry[3].cf      = u_merge_arb_1_out_bits_s1_entry_3_cf;
  assign marb1_out_s1.entry[4].tag     = u_merge_arb_1_out_bits_s1_entry_4_tag;
  assign marb1_out_s1.entry[4].asid    = u_merge_arb_1_out_bits_s1_entry_4_asid;
  assign marb1_out_s1.entry[4].vmid    = u_merge_arb_1_out_bits_s1_entry_4_vmid;
  assign marb1_out_s1.entry[4].n       = u_merge_arb_1_out_bits_s1_entry_4_n;
  assign marb1_out_s1.entry[4].pbmt    = u_merge_arb_1_out_bits_s1_entry_4_pbmt;
  assign marb1_out_s1.entry[4].perm.d  = u_merge_arb_1_out_bits_s1_entry_4_perm_d;
  assign marb1_out_s1.entry[4].perm.a  = u_merge_arb_1_out_bits_s1_entry_4_perm_a;
  assign marb1_out_s1.entry[4].perm.g  = u_merge_arb_1_out_bits_s1_entry_4_perm_g;
  assign marb1_out_s1.entry[4].perm.u  = u_merge_arb_1_out_bits_s1_entry_4_perm_u;
  assign marb1_out_s1.entry[4].perm.x  = u_merge_arb_1_out_bits_s1_entry_4_perm_x;
  assign marb1_out_s1.entry[4].perm.w  = u_merge_arb_1_out_bits_s1_entry_4_perm_w;
  assign marb1_out_s1.entry[4].perm.r  = u_merge_arb_1_out_bits_s1_entry_4_perm_r;
  assign marb1_out_s1.entry[4].level   = u_merge_arb_1_out_bits_s1_entry_4_level;
  assign marb1_out_s1.entry[4].v       = u_merge_arb_1_out_bits_s1_entry_4_v;
  assign marb1_out_s1.entry[4].ppn     = u_merge_arb_1_out_bits_s1_entry_4_ppn;
  assign marb1_out_s1.entry[4].ppn_low = u_merge_arb_1_out_bits_s1_entry_4_ppn_low;
  assign marb1_out_s1.entry[4].af      = u_merge_arb_1_out_bits_s1_entry_4_af;
  assign marb1_out_s1.entry[4].pf      = u_merge_arb_1_out_bits_s1_entry_4_pf;
  assign marb1_out_s1.entry[4].cf      = u_merge_arb_1_out_bits_s1_entry_4_cf;
  assign marb1_out_s1.entry[5].tag     = u_merge_arb_1_out_bits_s1_entry_5_tag;
  assign marb1_out_s1.entry[5].asid    = u_merge_arb_1_out_bits_s1_entry_5_asid;
  assign marb1_out_s1.entry[5].vmid    = u_merge_arb_1_out_bits_s1_entry_5_vmid;
  assign marb1_out_s1.entry[5].n       = u_merge_arb_1_out_bits_s1_entry_5_n;
  assign marb1_out_s1.entry[5].pbmt    = u_merge_arb_1_out_bits_s1_entry_5_pbmt;
  assign marb1_out_s1.entry[5].perm.d  = u_merge_arb_1_out_bits_s1_entry_5_perm_d;
  assign marb1_out_s1.entry[5].perm.a  = u_merge_arb_1_out_bits_s1_entry_5_perm_a;
  assign marb1_out_s1.entry[5].perm.g  = u_merge_arb_1_out_bits_s1_entry_5_perm_g;
  assign marb1_out_s1.entry[5].perm.u  = u_merge_arb_1_out_bits_s1_entry_5_perm_u;
  assign marb1_out_s1.entry[5].perm.x  = u_merge_arb_1_out_bits_s1_entry_5_perm_x;
  assign marb1_out_s1.entry[5].perm.w  = u_merge_arb_1_out_bits_s1_entry_5_perm_w;
  assign marb1_out_s1.entry[5].perm.r  = u_merge_arb_1_out_bits_s1_entry_5_perm_r;
  assign marb1_out_s1.entry[5].level   = u_merge_arb_1_out_bits_s1_entry_5_level;
  assign marb1_out_s1.entry[5].v       = u_merge_arb_1_out_bits_s1_entry_5_v;
  assign marb1_out_s1.entry[5].ppn     = u_merge_arb_1_out_bits_s1_entry_5_ppn;
  assign marb1_out_s1.entry[5].ppn_low = u_merge_arb_1_out_bits_s1_entry_5_ppn_low;
  assign marb1_out_s1.entry[5].af      = u_merge_arb_1_out_bits_s1_entry_5_af;
  assign marb1_out_s1.entry[5].pf      = u_merge_arb_1_out_bits_s1_entry_5_pf;
  assign marb1_out_s1.entry[5].cf      = u_merge_arb_1_out_bits_s1_entry_5_cf;
  assign marb1_out_s1.entry[6].tag     = u_merge_arb_1_out_bits_s1_entry_6_tag;
  assign marb1_out_s1.entry[6].asid    = u_merge_arb_1_out_bits_s1_entry_6_asid;
  assign marb1_out_s1.entry[6].vmid    = u_merge_arb_1_out_bits_s1_entry_6_vmid;
  assign marb1_out_s1.entry[6].n       = u_merge_arb_1_out_bits_s1_entry_6_n;
  assign marb1_out_s1.entry[6].pbmt    = u_merge_arb_1_out_bits_s1_entry_6_pbmt;
  assign marb1_out_s1.entry[6].perm.d  = u_merge_arb_1_out_bits_s1_entry_6_perm_d;
  assign marb1_out_s1.entry[6].perm.a  = u_merge_arb_1_out_bits_s1_entry_6_perm_a;
  assign marb1_out_s1.entry[6].perm.g  = u_merge_arb_1_out_bits_s1_entry_6_perm_g;
  assign marb1_out_s1.entry[6].perm.u  = u_merge_arb_1_out_bits_s1_entry_6_perm_u;
  assign marb1_out_s1.entry[6].perm.x  = u_merge_arb_1_out_bits_s1_entry_6_perm_x;
  assign marb1_out_s1.entry[6].perm.w  = u_merge_arb_1_out_bits_s1_entry_6_perm_w;
  assign marb1_out_s1.entry[6].perm.r  = u_merge_arb_1_out_bits_s1_entry_6_perm_r;
  assign marb1_out_s1.entry[6].level   = u_merge_arb_1_out_bits_s1_entry_6_level;
  assign marb1_out_s1.entry[6].v       = u_merge_arb_1_out_bits_s1_entry_6_v;
  assign marb1_out_s1.entry[6].ppn     = u_merge_arb_1_out_bits_s1_entry_6_ppn;
  assign marb1_out_s1.entry[6].ppn_low = u_merge_arb_1_out_bits_s1_entry_6_ppn_low;
  assign marb1_out_s1.entry[6].af      = u_merge_arb_1_out_bits_s1_entry_6_af;
  assign marb1_out_s1.entry[6].pf      = u_merge_arb_1_out_bits_s1_entry_6_pf;
  assign marb1_out_s1.entry[6].cf      = u_merge_arb_1_out_bits_s1_entry_6_cf;
  assign marb1_out_s1.entry[7].tag     = u_merge_arb_1_out_bits_s1_entry_7_tag;
  assign marb1_out_s1.entry[7].asid    = u_merge_arb_1_out_bits_s1_entry_7_asid;
  assign marb1_out_s1.entry[7].vmid    = u_merge_arb_1_out_bits_s1_entry_7_vmid;
  assign marb1_out_s1.entry[7].n       = u_merge_arb_1_out_bits_s1_entry_7_n;
  assign marb1_out_s1.entry[7].pbmt    = u_merge_arb_1_out_bits_s1_entry_7_pbmt;
  assign marb1_out_s1.entry[7].perm.d  = u_merge_arb_1_out_bits_s1_entry_7_perm_d;
  assign marb1_out_s1.entry[7].perm.a  = u_merge_arb_1_out_bits_s1_entry_7_perm_a;
  assign marb1_out_s1.entry[7].perm.g  = u_merge_arb_1_out_bits_s1_entry_7_perm_g;
  assign marb1_out_s1.entry[7].perm.u  = u_merge_arb_1_out_bits_s1_entry_7_perm_u;
  assign marb1_out_s1.entry[7].perm.x  = u_merge_arb_1_out_bits_s1_entry_7_perm_x;
  assign marb1_out_s1.entry[7].perm.w  = u_merge_arb_1_out_bits_s1_entry_7_perm_w;
  assign marb1_out_s1.entry[7].perm.r  = u_merge_arb_1_out_bits_s1_entry_7_perm_r;
  assign marb1_out_s1.entry[7].level   = u_merge_arb_1_out_bits_s1_entry_7_level;
  assign marb1_out_s1.entry[7].v       = u_merge_arb_1_out_bits_s1_entry_7_v;
  assign marb1_out_s1.entry[7].ppn     = u_merge_arb_1_out_bits_s1_entry_7_ppn;
  assign marb1_out_s1.entry[7].ppn_low = u_merge_arb_1_out_bits_s1_entry_7_ppn_low;
  assign marb1_out_s1.entry[7].af      = u_merge_arb_1_out_bits_s1_entry_7_af;
  assign marb1_out_s1.entry[7].pf      = u_merge_arb_1_out_bits_s1_entry_7_pf;
  assign marb1_out_s1.entry[7].cf      = u_merge_arb_1_out_bits_s1_entry_7_cf;
  assign marb1_out_s1.pteidx[0]        = u_merge_arb_1_out_bits_s1_pteidx_0;
  assign marb1_out_s1.pteidx[1]        = u_merge_arb_1_out_bits_s1_pteidx_1;
  assign marb1_out_s1.pteidx[2]        = u_merge_arb_1_out_bits_s1_pteidx_2;
  assign marb1_out_s1.pteidx[3]        = u_merge_arb_1_out_bits_s1_pteidx_3;
  assign marb1_out_s1.pteidx[4]        = u_merge_arb_1_out_bits_s1_pteidx_4;
  assign marb1_out_s1.pteidx[5]        = u_merge_arb_1_out_bits_s1_pteidx_5;
  assign marb1_out_s1.pteidx[6]        = u_merge_arb_1_out_bits_s1_pteidx_6;
  assign marb1_out_s1.pteidx[7]        = u_merge_arb_1_out_bits_s1_pteidx_7;
  assign marb1_out_s1.not_super        = u_merge_arb_1_out_bits_s1_not_super;
  // END GENERATED
  // 本次翻译有没有 G-stage：s2xlate ∈ {noS2, onlyS1} 就是"没有"。
  wire [1:0] marb0_s2x   = u_merge_arb_0_out_bits_s2xlate;
  wire [1:0] marb1_s2x   = u_merge_arb_1_out_bits_s2xlate;
  wire       marb0_nos2  = (marb0_s2x == NO_S2XLATE) | (marb0_s2x == ONLY_STAGE1);
  wire       marb1_nos2  = (marb1_s2x == NO_S2XLATE) | (marb1_s2x == ONLY_STAGE1);
  // bitmap 开 + 没有 G-stage ⇒ S1 是最终一级，要拍平（见 merge_to_sector 的 bm_final）。
  wire       bm_final_0  = bitmap_enable & marb0_nos2;
  wire       bm_final_1  = bitmap_enable & marb1_nos2;

  sector_resp_t sec0, sec1;
  assign sec0 = merge_to_sector(marb0_out_s1, u_merge_arb_0_out_bits_s1_not_merge, bm_final_0);
  assign sec1 = merge_to_sector(marb1_out_s1, u_merge_arb_1_out_bits_s1_not_merge, bm_final_1);
  // BEGIN GENERATED(outarb_in)
  assign u_out_arb_0__in_0_bits_s1_entry_tag    = sec0.entry.tag;
  assign u_out_arb_0__in_0_bits_s1_entry_asid   = sec0.entry.asid;
  assign u_out_arb_0__in_0_bits_s1_entry_vmid   = sec0.entry.vmid;
  assign u_out_arb_0__in_0_bits_s1_entry_n      = sec0.entry.n;
  assign u_out_arb_0__in_0_bits_s1_entry_pbmt   = sec0.entry.pbmt;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_d = sec0.entry.perm.d;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_a = sec0.entry.perm.a;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_g = sec0.entry.perm.g;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_u = sec0.entry.perm.u;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_x = sec0.entry.perm.x;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_w = sec0.entry.perm.w;
  assign u_out_arb_0__in_0_bits_s1_entry_perm_r = sec0.entry.perm.r;
  assign u_out_arb_0__in_0_bits_s1_entry_level  = sec0.entry.level;
  assign u_out_arb_0__in_0_bits_s1_entry_v      = sec0.entry.v;
  assign u_out_arb_0__in_0_bits_s1_entry_ppn    = sec0.entry.ppn;
  assign u_out_arb_0__in_0_bits_s1_addr_low     = sec0.addr_low;
  assign u_out_arb_0__in_0_bits_s1_valididx_0   = sec0.valididx[0];
  assign u_out_arb_0__in_0_bits_s1_valididx_1   = sec0.valididx[1];
  assign u_out_arb_0__in_0_bits_s1_valididx_2   = sec0.valididx[2];
  assign u_out_arb_0__in_0_bits_s1_valididx_3   = sec0.valididx[3];
  assign u_out_arb_0__in_0_bits_s1_valididx_4   = sec0.valididx[4];
  assign u_out_arb_0__in_0_bits_s1_valididx_5   = sec0.valididx[5];
  assign u_out_arb_0__in_0_bits_s1_valididx_6   = sec0.valididx[6];
  assign u_out_arb_0__in_0_bits_s1_valididx_7   = sec0.valididx[7];
  assign u_out_arb_0__in_0_bits_s1_pf           = sec0.pf;
  assign u_out_arb_0__in_0_bits_s1_af           = sec0.af;
  assign u_out_arb_1__in_0_bits_s1_entry_tag    = sec1.entry.tag;
  assign u_out_arb_1__in_0_bits_s1_entry_asid   = sec1.entry.asid;
  assign u_out_arb_1__in_0_bits_s1_entry_vmid   = sec1.entry.vmid;
  assign u_out_arb_1__in_0_bits_s1_entry_n      = sec1.entry.n;
  assign u_out_arb_1__in_0_bits_s1_entry_pbmt   = sec1.entry.pbmt;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_d = sec1.entry.perm.d;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_a = sec1.entry.perm.a;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_g = sec1.entry.perm.g;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_u = sec1.entry.perm.u;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_x = sec1.entry.perm.x;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_w = sec1.entry.perm.w;
  assign u_out_arb_1__in_0_bits_s1_entry_perm_r = sec1.entry.perm.r;
  assign u_out_arb_1__in_0_bits_s1_entry_level  = sec1.entry.level;
  assign u_out_arb_1__in_0_bits_s1_entry_v      = sec1.entry.v;
  assign u_out_arb_1__in_0_bits_s1_entry_ppn    = sec1.entry.ppn;
  assign u_out_arb_1__in_0_bits_s1_addr_low     = sec1.addr_low;
  assign u_out_arb_1__in_0_bits_s1_valididx_0   = sec1.valididx[0];
  assign u_out_arb_1__in_0_bits_s1_valididx_1   = sec1.valididx[1];
  assign u_out_arb_1__in_0_bits_s1_valididx_2   = sec1.valididx[2];
  assign u_out_arb_1__in_0_bits_s1_valididx_3   = sec1.valididx[3];
  assign u_out_arb_1__in_0_bits_s1_valididx_4   = sec1.valididx[4];
  assign u_out_arb_1__in_0_bits_s1_valididx_5   = sec1.valididx[5];
  assign u_out_arb_1__in_0_bits_s1_valididx_6   = sec1.valididx[6];
  assign u_out_arb_1__in_0_bits_s1_valididx_7   = sec1.valididx[7];
  assign u_out_arb_1__in_0_bits_s1_pf           = sec1.pf;
  assign u_out_arb_1__in_0_bits_s1_af           = sec1.af;
  // END GENERATED

  // ★G1 新增：napot / superpage 改写★
  //   开了 bitmap 且本次翻译不含 G-stage（s2xlate 是 noS2 或 onlyS1）且选中条目是
  //   superpage 时，8 条 ppn_low 全部改成"选中条目的 sector 下标"；
  //   s2（G-stage）那侧则反过来：不满足该条件时，用 level 把 ppn 低位换成 tag 低位。
  wire       keep_low_0 = ~bm_final_0 | u_merge_arb_0_out_bits_s1_not_super;
  wire       keep_low_1 = ~bm_final_1 | u_merge_arb_1_out_bits_s1_not_super;
  wire [SECTOR_BITS-1:0] sec0_idx = oh_to_uint8(marb0_out_s1.pteidx);
  wire [SECTOR_BITS-1:0] sec1_idx = oh_to_uint8(marb1_out_s1.pteidx);
  assign u_out_arb_0__in_0_bits_s1_ppn_low_0 =
      keep_low_0 ? sec0.ppn_low[0] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_1 =
      keep_low_0 ? sec0.ppn_low[1] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_2 =
      keep_low_0 ? sec0.ppn_low[2] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_3 =
      keep_low_0 ? sec0.ppn_low[3] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_4 =
      keep_low_0 ? sec0.ppn_low[4] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_5 =
      keep_low_0 ? sec0.ppn_low[5] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_6 =
      keep_low_0 ? sec0.ppn_low[6] : sec0_idx;
  assign u_out_arb_0__in_0_bits_s1_ppn_low_7 =
      keep_low_0 ? sec0.ppn_low[7] : sec0_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_0 =
      keep_low_1 ? sec1.ppn_low[0] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_1 =
      keep_low_1 ? sec1.ppn_low[1] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_2 =
      keep_low_1 ? sec1.ppn_low[2] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_3 =
      keep_low_1 ? sec1.ppn_low[3] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_4 =
      keep_low_1 ? sec1.ppn_low[4] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_5 =
      keep_low_1 ? sec1.ppn_low[5] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_6 =
      keep_low_1 ? sec1.ppn_low[6] : sec1_idx;
  assign u_out_arb_1__in_0_bits_s1_ppn_low_7 =
      keep_low_1 ? sec1.ppn_low[7] : sec1_idx;

  // s2（G-stage）entry：hptw_gen_ppn_s2 —— 按 level 把 ppn 低位换成 vpn(tag) 低位。
  function automatic logic [37:0] hptw_gen_ppn_s2(
    input logic [37:0] ppn, input logic [37:0] tag,
    input logic [1:0] level, input logic n);
    case (level)
      2'h1:    return {ppn[37:9],  tag[8:0]};
      2'h2:    return {ppn[37:18], tag[17:0]};
      2'h3:    return {ppn[37:27], tag[26:0]};
      default: return n ? {ppn[37:4], tag[3:0]} : ppn;
    endcase
  endfunction
  wire keep_s2_0 = ~bitmap_enable | marb0_nos2;
  wire keep_s2_1 = ~bitmap_enable | marb1_nos2;
  assign u_out_arb_0__in_0_bits_s2_entry_n = keep_s2_0 & u_merge_arb_0_out_bits_s2_entry_n;
  assign u_out_arb_1__in_0_bits_s2_entry_n = keep_s2_1 & u_merge_arb_1_out_bits_s2_entry_n;
  assign u_out_arb_0__in_0_bits_s2_entry_level =
      keep_s2_0 ? u_merge_arb_0_out_bits_s2_entry_level : 2'h0;
  assign u_out_arb_1__in_0_bits_s2_entry_level =
      keep_s2_1 ? u_merge_arb_1_out_bits_s2_entry_level : 2'h0;
  assign u_out_arb_0__in_0_bits_s2_entry_ppn =
      keep_s2_0 ? u_merge_arb_0_out_bits_s2_entry_ppn
                : hptw_gen_ppn_s2(u_merge_arb_0_out_bits_s2_entry_ppn,
                                  u_merge_arb_0_out_bits_s2_entry_tag,
                                  u_merge_arb_0_out_bits_s2_entry_level,
                                  u_merge_arb_0_out_bits_s2_entry_n);
  assign u_out_arb_1__in_0_bits_s2_entry_ppn =
      keep_s2_1 ? u_merge_arb_1_out_bits_s2_entry_ppn
                : hptw_gen_ppn_s2(u_merge_arb_1_out_bits_s2_entry_ppn,
                                  u_merge_arb_1_out_bits_s2_entry_tag,
                                  u_merge_arb_1_out_bits_s2_entry_level,
                                  u_merge_arb_1_out_bits_s2_entry_n);

  // ==========================================================================
  // 9. PMP checker 请求装配 + prefetch 触发
  // --------------------------------------------------------------------------
  // ★G1★ 5 个 PMPChecker：ptw / llptw 口0 / llptw 口1 / hptw / bitmap
  //   （G0 只有 3 个：LLPTW 的 PMP 口在 G1 由 1 个变成 2 个，再加 bitmap 一个）。
  // check_env.mode 恒 ModeS(=1)，cmd 恒 read(=0)，debug 取 csr_dup[0].priv_debug。
  // ==========================================================================
  // mode(ModeS=2'h1) 与 cmd(read) 在 golden 里就是写死的常量，实例区已直接给；
  // 本核只驱动 debug 这一条。★不要再在这里重复 assign，那是多驱动。★
  assign u_pmp_chk_ptw__check_env_debug    = csr_dup[0].priv_debug;
  assign u_pmp_chk_llptw0__check_env_debug = csr_dup[0].priv_debug;
  assign u_pmp_chk_llptw1__check_env_debug = csr_dup[0].priv_debug;
  assign u_pmp_chk_hptw__check_env_debug   = csr_dup[0].priv_debug;
  assign u_pmp_chk_bitmap__check_env_debug = csr_dup[0].priv_debug;

  wire cache_resp_fire = cr_valid & u_page_cache__resp_ready;
  assign u_prefetch__in_valid = cache_resp_fire & ~from_pre & (~cr_hit | cr_prefetch) & cr_isFirst;

  // ==========================================================================
  // 12. Bitmap 检查引擎接线（G1 新增）
  // --------------------------------------------------------------------------
  // Bitmap 引擎按 PTE 的物理页号去查一张位图，判断该页是否可用（cf = check failed）。
  // 三个遍历器经 bitmap_arb 轮流发请求（实例区直连），响应按 id 分回：
  //   id 0..5 → LLPTW，id 6 → PTW，id 7 → HPTW。
  // ==========================================================================
  wire [2:0] bm_resp_id      = u_bitmap_resp_bits_id;
  wire       bmresp_to_llptw = (bm_resp_id < 3'h6);
  wire       bmresp_to_ptw   = (bm_resp_id == 3'h6);
  wire       bmresp_to_hptw  = (&bm_resp_id);          // id 7
  assign u_llptw__bitmap_resp_valid = u_bitmap_resp_valid & bmresp_to_llptw;
  assign u_ptw__bitmap_resp_valid   = u_bitmap_resp_valid & bmresp_to_ptw;
  assign u_hptw__bitmap_resp_valid  = u_bitmap_resp_valid & bmresp_to_hptw;
  assign u_bitmap__resp_ready = (u_llptw_bitmap_resp_ready & bmresp_to_llptw)
                              | (u_hptw_bitmap_resp_ready & bmresp_to_hptw)
                              | (u_ptw_bitmap_resp_ready  & bmresp_to_ptw);

  // ==========================================================================
  // 10. 顶层输出直驱
  // ==========================================================================
  assign io_tlb_0_req_0_ready     = u_arb_tlb_in_0_ready;
  assign io_tlb_1_req_0_ready     = u_arb_tlb_in_1_ready;
  assign io_tlb_0_resp_valid      = u_out_arb_0_out_valid;
  assign io_tlb_1_resp_valid      = u_out_arb_1_out_valid;

  // resp.bits 全族（s1/s2/s2xlate 共 102 条）是 outArb 输出的 1:1 直驱，没有逻辑，
  // 故整块机械生成。另有 14 条 golden 直接把 arbiter 的 output pin 连到顶层端口，
  // 已在实例区连好，本区按 golden 的分法跳过（不许"补齐成对称"）。
  // BEGIN GENERATED(tlb_resp_out)
  assign io_tlb_0_resp_bits_s2xlate         = u_out_arb_0_out_bits_s2xlate;
  assign io_tlb_0_resp_bits_s1_entry_tag    = u_out_arb_0_out_bits_s1_entry_tag;
  assign io_tlb_0_resp_bits_s1_entry_pbmt   = u_out_arb_0_out_bits_s1_entry_pbmt;
  assign io_tlb_0_resp_bits_s1_entry_perm_d = u_out_arb_0_out_bits_s1_entry_perm_d;
  assign io_tlb_0_resp_bits_s1_entry_perm_a = u_out_arb_0_out_bits_s1_entry_perm_a;
  assign io_tlb_0_resp_bits_s1_entry_perm_g = u_out_arb_0_out_bits_s1_entry_perm_g;
  assign io_tlb_0_resp_bits_s1_entry_perm_u = u_out_arb_0_out_bits_s1_entry_perm_u;
  assign io_tlb_0_resp_bits_s1_entry_perm_x = u_out_arb_0_out_bits_s1_entry_perm_x;
  assign io_tlb_0_resp_bits_s1_entry_perm_w = u_out_arb_0_out_bits_s1_entry_perm_w;
  assign io_tlb_0_resp_bits_s1_entry_perm_r = u_out_arb_0_out_bits_s1_entry_perm_r;
  assign io_tlb_0_resp_bits_s1_entry_level  = u_out_arb_0_out_bits_s1_entry_level;
  assign io_tlb_0_resp_bits_s1_entry_ppn    = u_out_arb_0_out_bits_s1_entry_ppn;
  assign io_tlb_0_resp_bits_s1_ppn_low_0    = u_out_arb_0_out_bits_s1_ppn_low_0;
  assign io_tlb_0_resp_bits_s1_ppn_low_1    = u_out_arb_0_out_bits_s1_ppn_low_1;
  assign io_tlb_0_resp_bits_s1_ppn_low_2    = u_out_arb_0_out_bits_s1_ppn_low_2;
  assign io_tlb_0_resp_bits_s1_ppn_low_3    = u_out_arb_0_out_bits_s1_ppn_low_3;
  assign io_tlb_0_resp_bits_s1_ppn_low_4    = u_out_arb_0_out_bits_s1_ppn_low_4;
  assign io_tlb_0_resp_bits_s1_ppn_low_5    = u_out_arb_0_out_bits_s1_ppn_low_5;
  assign io_tlb_0_resp_bits_s1_ppn_low_6    = u_out_arb_0_out_bits_s1_ppn_low_6;
  assign io_tlb_0_resp_bits_s1_ppn_low_7    = u_out_arb_0_out_bits_s1_ppn_low_7;
  assign io_tlb_0_resp_bits_s1_valididx_0   = u_out_arb_0_out_bits_s1_valididx_0;
  assign io_tlb_0_resp_bits_s1_valididx_1   = u_out_arb_0_out_bits_s1_valididx_1;
  assign io_tlb_0_resp_bits_s1_valididx_2   = u_out_arb_0_out_bits_s1_valididx_2;
  assign io_tlb_0_resp_bits_s1_valididx_3   = u_out_arb_0_out_bits_s1_valididx_3;
  assign io_tlb_0_resp_bits_s1_valididx_4   = u_out_arb_0_out_bits_s1_valididx_4;
  assign io_tlb_0_resp_bits_s1_valididx_5   = u_out_arb_0_out_bits_s1_valididx_5;
  assign io_tlb_0_resp_bits_s1_valididx_6   = u_out_arb_0_out_bits_s1_valididx_6;
  assign io_tlb_0_resp_bits_s1_valididx_7   = u_out_arb_0_out_bits_s1_valididx_7;
  assign io_tlb_0_resp_bits_s1_pteidx_0     = u_out_arb_0_out_bits_s1_pteidx_0;
  assign io_tlb_0_resp_bits_s1_pteidx_1     = u_out_arb_0_out_bits_s1_pteidx_1;
  assign io_tlb_0_resp_bits_s1_pteidx_2     = u_out_arb_0_out_bits_s1_pteidx_2;
  assign io_tlb_0_resp_bits_s1_pteidx_3     = u_out_arb_0_out_bits_s1_pteidx_3;
  assign io_tlb_0_resp_bits_s1_pteidx_4     = u_out_arb_0_out_bits_s1_pteidx_4;
  assign io_tlb_0_resp_bits_s1_pteidx_5     = u_out_arb_0_out_bits_s1_pteidx_5;
  assign io_tlb_0_resp_bits_s1_pteidx_6     = u_out_arb_0_out_bits_s1_pteidx_6;
  assign io_tlb_0_resp_bits_s1_pteidx_7     = u_out_arb_0_out_bits_s1_pteidx_7;
  assign io_tlb_0_resp_bits_s1_pf           = u_out_arb_0_out_bits_s1_pf;
  assign io_tlb_0_resp_bits_s1_af           = u_out_arb_0_out_bits_s1_af;
  assign io_tlb_0_resp_bits_s2_entry_tag    = u_out_arb_0_out_bits_s2_entry_tag;
  assign io_tlb_0_resp_bits_s2_entry_pbmt   = u_out_arb_0_out_bits_s2_entry_pbmt;
  assign io_tlb_0_resp_bits_s2_entry_ppn    = u_out_arb_0_out_bits_s2_entry_ppn;
  assign io_tlb_0_resp_bits_s2_entry_perm_d = u_out_arb_0_out_bits_s2_entry_perm_d;
  assign io_tlb_0_resp_bits_s2_entry_perm_a = u_out_arb_0_out_bits_s2_entry_perm_a;
  assign io_tlb_0_resp_bits_s2_entry_perm_g = u_out_arb_0_out_bits_s2_entry_perm_g;
  assign io_tlb_0_resp_bits_s2_entry_perm_u = u_out_arb_0_out_bits_s2_entry_perm_u;
  assign io_tlb_0_resp_bits_s2_entry_perm_x = u_out_arb_0_out_bits_s2_entry_perm_x;
  assign io_tlb_0_resp_bits_s2_entry_perm_w = u_out_arb_0_out_bits_s2_entry_perm_w;
  assign io_tlb_0_resp_bits_s2_entry_perm_r = u_out_arb_0_out_bits_s2_entry_perm_r;
  assign io_tlb_0_resp_bits_s2_entry_level  = u_out_arb_0_out_bits_s2_entry_level;
  assign io_tlb_0_resp_bits_s2_gpf          = u_out_arb_0_out_bits_s2_gpf;
  assign io_tlb_0_resp_bits_s2_gaf          = u_out_arb_0_out_bits_s2_gaf;
  assign io_tlb_1_resp_bits_s2xlate         = u_out_arb_1_out_bits_s2xlate;
  assign io_tlb_1_resp_bits_s1_entry_tag    = u_out_arb_1_out_bits_s1_entry_tag;
  assign io_tlb_1_resp_bits_s1_entry_pbmt   = u_out_arb_1_out_bits_s1_entry_pbmt;
  assign io_tlb_1_resp_bits_s1_entry_perm_d = u_out_arb_1_out_bits_s1_entry_perm_d;
  assign io_tlb_1_resp_bits_s1_entry_perm_a = u_out_arb_1_out_bits_s1_entry_perm_a;
  assign io_tlb_1_resp_bits_s1_entry_perm_g = u_out_arb_1_out_bits_s1_entry_perm_g;
  assign io_tlb_1_resp_bits_s1_entry_perm_u = u_out_arb_1_out_bits_s1_entry_perm_u;
  assign io_tlb_1_resp_bits_s1_entry_perm_x = u_out_arb_1_out_bits_s1_entry_perm_x;
  assign io_tlb_1_resp_bits_s1_entry_perm_w = u_out_arb_1_out_bits_s1_entry_perm_w;
  assign io_tlb_1_resp_bits_s1_entry_perm_r = u_out_arb_1_out_bits_s1_entry_perm_r;
  assign io_tlb_1_resp_bits_s1_entry_level  = u_out_arb_1_out_bits_s1_entry_level;
  assign io_tlb_1_resp_bits_s1_entry_ppn    = u_out_arb_1_out_bits_s1_entry_ppn;
  assign io_tlb_1_resp_bits_s1_ppn_low_0    = u_out_arb_1_out_bits_s1_ppn_low_0;
  assign io_tlb_1_resp_bits_s1_ppn_low_1    = u_out_arb_1_out_bits_s1_ppn_low_1;
  assign io_tlb_1_resp_bits_s1_ppn_low_2    = u_out_arb_1_out_bits_s1_ppn_low_2;
  assign io_tlb_1_resp_bits_s1_ppn_low_3    = u_out_arb_1_out_bits_s1_ppn_low_3;
  assign io_tlb_1_resp_bits_s1_ppn_low_4    = u_out_arb_1_out_bits_s1_ppn_low_4;
  assign io_tlb_1_resp_bits_s1_ppn_low_5    = u_out_arb_1_out_bits_s1_ppn_low_5;
  assign io_tlb_1_resp_bits_s1_ppn_low_6    = u_out_arb_1_out_bits_s1_ppn_low_6;
  assign io_tlb_1_resp_bits_s1_ppn_low_7    = u_out_arb_1_out_bits_s1_ppn_low_7;
  assign io_tlb_1_resp_bits_s1_valididx_0   = u_out_arb_1_out_bits_s1_valididx_0;
  assign io_tlb_1_resp_bits_s1_valididx_1   = u_out_arb_1_out_bits_s1_valididx_1;
  assign io_tlb_1_resp_bits_s1_valididx_2   = u_out_arb_1_out_bits_s1_valididx_2;
  assign io_tlb_1_resp_bits_s1_valididx_3   = u_out_arb_1_out_bits_s1_valididx_3;
  assign io_tlb_1_resp_bits_s1_valididx_4   = u_out_arb_1_out_bits_s1_valididx_4;
  assign io_tlb_1_resp_bits_s1_valididx_5   = u_out_arb_1_out_bits_s1_valididx_5;
  assign io_tlb_1_resp_bits_s1_valididx_6   = u_out_arb_1_out_bits_s1_valididx_6;
  assign io_tlb_1_resp_bits_s1_valididx_7   = u_out_arb_1_out_bits_s1_valididx_7;
  assign io_tlb_1_resp_bits_s1_pteidx_0     = u_out_arb_1_out_bits_s1_pteidx_0;
  assign io_tlb_1_resp_bits_s1_pteidx_1     = u_out_arb_1_out_bits_s1_pteidx_1;
  assign io_tlb_1_resp_bits_s1_pteidx_2     = u_out_arb_1_out_bits_s1_pteidx_2;
  assign io_tlb_1_resp_bits_s1_pteidx_3     = u_out_arb_1_out_bits_s1_pteidx_3;
  assign io_tlb_1_resp_bits_s1_pteidx_4     = u_out_arb_1_out_bits_s1_pteidx_4;
  assign io_tlb_1_resp_bits_s1_pteidx_5     = u_out_arb_1_out_bits_s1_pteidx_5;
  assign io_tlb_1_resp_bits_s1_pteidx_6     = u_out_arb_1_out_bits_s1_pteidx_6;
  assign io_tlb_1_resp_bits_s1_pteidx_7     = u_out_arb_1_out_bits_s1_pteidx_7;
  assign io_tlb_1_resp_bits_s1_pf           = u_out_arb_1_out_bits_s1_pf;
  assign io_tlb_1_resp_bits_s1_af           = u_out_arb_1_out_bits_s1_af;
  assign io_tlb_1_resp_bits_s2_entry_tag    = u_out_arb_1_out_bits_s2_entry_tag;
  assign io_tlb_1_resp_bits_s2_entry_pbmt   = u_out_arb_1_out_bits_s2_entry_pbmt;
  assign io_tlb_1_resp_bits_s2_entry_ppn    = u_out_arb_1_out_bits_s2_entry_ppn;
  assign io_tlb_1_resp_bits_s2_entry_perm_d = u_out_arb_1_out_bits_s2_entry_perm_d;
  assign io_tlb_1_resp_bits_s2_entry_perm_a = u_out_arb_1_out_bits_s2_entry_perm_a;
  assign io_tlb_1_resp_bits_s2_entry_perm_g = u_out_arb_1_out_bits_s2_entry_perm_g;
  assign io_tlb_1_resp_bits_s2_entry_perm_u = u_out_arb_1_out_bits_s2_entry_perm_u;
  assign io_tlb_1_resp_bits_s2_entry_perm_x = u_out_arb_1_out_bits_s2_entry_perm_x;
  assign io_tlb_1_resp_bits_s2_entry_perm_w = u_out_arb_1_out_bits_s2_entry_perm_w;
  assign io_tlb_1_resp_bits_s2_entry_perm_r = u_out_arb_1_out_bits_s2_entry_perm_r;
  assign io_tlb_1_resp_bits_s2_entry_level  = u_out_arb_1_out_bits_s2_entry_level;
  assign io_tlb_1_resp_bits_s2_gpf          = u_out_arb_1_out_bits_s2_gpf;
  assign io_tlb_1_resp_bits_s2_gaf          = u_out_arb_1_out_bits_s2_gaf;
  // END GENERATED

  // ==========================================================================
  // 10b. difftest 探针（refill 一条 + 每个 TLB 口一条）
  // --------------------------------------------------------------------------
  // 这三条只给 difftest gateway 看，不进功能通路，但它们是**实打实的顶层输出**
  // （gatewayIn_packed_43/44/45_bore，601/969/969 bit），golden 里有，这里必须有。
  //
  // refill 探针答的是"刚刚填进 page cache 的那一行 PTE 是从哪个物理地址取回来的"：
  //   · 发请求那拍，按 mem id 把地址存进 difftest_ptw_addr[id]（16 个 id 各一格）；
  //   · 收到 D 通道响应那拍，把 source 记进 difftest_addr_r；
  //   · refill 打一拍生效时，用 difftest_addr_r 回查地址。
  // 也就是说地址表是按 **发** 的 id 写、按 **收** 的 id 读，中间隔着访存延迟。
  //
  // ★两条 l2tlb 探针的 valid 条件不对称，是 golden 就这样，照抄不补齐★：
  //   口 0 用 valid & ready（响应真被 ITLB 取走），口 1 只用 valid。
  //   本核上面算请求计数时用的 tlb0_resp_fire / tlb1_resp_fire 正是这两个式子。
  // ==========================================================================
  wire [7:0] difftest_coreid = {2'h0, io_hartId};

  // 按 mem id 存的 PTE 行地址表。打包数组 + 循环变量下标：非打包数组配信号下标
  // 会踩 FMR_ELAB-147（见 CONVENTIONS 的 Rob canary 实测表）。
  logic [15:0][47:0] difftest_ptw_addr;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      difftest_ptw_addr <= '0;
    end else begin
      for (int i = 0; i < 16; i++)
        if (mem_a_fire && (u_mem_arb_out_bits_id == 4'(i)))
          difftest_ptw_addr[i] <= auto_out_a_bits_address;
    end
  end

  // ★无复位★：golden 的 difftest_addr_r 就在无复位的 always 块里，照搬。
  logic [3:0] difftest_addr_r;
  always_ff @(posedge clock)
    if (d_valid) difftest_addr_r <= d_src;

  logic [CONTIG-1:0][63:0] refill_probe_ptes;
  always_comb
    for (int i = 0; i < CONTIG; i++)
      refill_probe_ptes[i] = refill_data_flat[i*64 +: 64];

  assign gatewayIn_packed_43_bore = pack_refill_probe(
    .valid  (refill_valid_d),
    .addr   (difftest_ptw_addr[difftest_addr_r]),
    .ptes   (refill_probe_ptes),
    .mask   (8'hFF),
    .coreid (difftest_coreid),
    .index  (8'h2));

  // 两个口除了 valid 条件外完全同构，用同一个打包函数，只喂各自口的信号。
  wire [63:0] csr_satp_probe  = {io_csr_tlb_satp_mode,  io_csr_tlb_satp_asid,  io_csr_tlb_satp_ppn};
  wire [63:0] csr_vsatp_probe = {io_csr_tlb_vsatp_mode, io_csr_tlb_vsatp_asid, io_csr_tlb_vsatp_ppn};
  wire [63:0] csr_hgatp_probe = {io_csr_tlb_hgatp_mode, io_csr_tlb_hgatp_vmid, io_csr_tlb_hgatp_ppn};

  assign gatewayIn_packed_44_bore = pack_l2tlb_probe(
    .valid   (tlb0_resp_fire & ~io_tlb_0_resp_bits_s1_af & ~io_tlb_0_resp_bits_s2_gaf),
    .valididx({io_tlb_0_resp_bits_s1_valididx_7, io_tlb_0_resp_bits_s1_valididx_6,
               io_tlb_0_resp_bits_s1_valididx_5, io_tlb_0_resp_bits_s1_valididx_4,
               io_tlb_0_resp_bits_s1_valididx_3, io_tlb_0_resp_bits_s1_valididx_2,
               io_tlb_0_resp_bits_s1_valididx_1, io_tlb_0_resp_bits_s1_valididx_0}),
    .satp    (csr_satp_probe),
    .s1_tag  (io_tlb_0_resp_bits_s1_entry_tag),
    .pbmt    (io_tlb_0_resp_bits_s1_entry_pbmt),
    .g_pbmt  (io_tlb_0_resp_bits_s2_entry_pbmt),
    .s1_ppn  (io_tlb_0_resp_bits_s1_entry_ppn),
    .ppn_low ({io_tlb_0_resp_bits_s1_ppn_low_7, io_tlb_0_resp_bits_s1_ppn_low_6,
               io_tlb_0_resp_bits_s1_ppn_low_5, io_tlb_0_resp_bits_s1_ppn_low_4,
               io_tlb_0_resp_bits_s1_ppn_low_3, io_tlb_0_resp_bits_s1_ppn_low_2,
               io_tlb_0_resp_bits_s1_ppn_low_1, io_tlb_0_resp_bits_s1_ppn_low_0}),
    .perm    ({io_tlb_0_resp_bits_s1_entry_perm_d, io_tlb_0_resp_bits_s1_entry_perm_a,
               io_tlb_0_resp_bits_s1_entry_perm_g, io_tlb_0_resp_bits_s1_entry_perm_u,
               io_tlb_0_resp_bits_s1_entry_perm_x, io_tlb_0_resp_bits_s1_entry_perm_w,
               io_tlb_0_resp_bits_s1_entry_perm_r}),
    .level   (io_tlb_0_resp_bits_s1_entry_level),
    .pf      (io_tlb_0_resp_bits_s1_pf),
    .pteidx  ({io_tlb_0_resp_bits_s1_pteidx_7, io_tlb_0_resp_bits_s1_pteidx_6,
               io_tlb_0_resp_bits_s1_pteidx_5, io_tlb_0_resp_bits_s1_pteidx_4,
               io_tlb_0_resp_bits_s1_pteidx_3, io_tlb_0_resp_bits_s1_pteidx_2,
               io_tlb_0_resp_bits_s1_pteidx_1, io_tlb_0_resp_bits_s1_pteidx_0}),
    .vsatp   (csr_vsatp_probe),
    .hgatp   (csr_hgatp_probe),
    .s2_tag  (io_tlb_0_resp_bits_s2_entry_tag),
    .g_perm  ({io_tlb_0_resp_bits_s2_entry_perm_d, io_tlb_0_resp_bits_s2_entry_perm_a,
               io_tlb_0_resp_bits_s2_entry_perm_g, io_tlb_0_resp_bits_s2_entry_perm_u,
               io_tlb_0_resp_bits_s2_entry_perm_x, io_tlb_0_resp_bits_s2_entry_perm_w,
               io_tlb_0_resp_bits_s2_entry_perm_r}),
    .g_level (io_tlb_0_resp_bits_s2_entry_level),
    .s2_ppn  (io_tlb_0_resp_bits_s2_entry_ppn),
    .gpf     (io_tlb_0_resp_bits_s2_gpf),
    .s2xlate (io_tlb_0_resp_bits_s2xlate),
    .coreid  (difftest_coreid),
    .index   (8'h0));

  assign gatewayIn_packed_45_bore = pack_l2tlb_probe(
    .valid   (tlb1_resp_fire & ~io_tlb_1_resp_bits_s1_af & ~io_tlb_1_resp_bits_s2_gaf),
    .valididx({io_tlb_1_resp_bits_s1_valididx_7, io_tlb_1_resp_bits_s1_valididx_6,
               io_tlb_1_resp_bits_s1_valididx_5, io_tlb_1_resp_bits_s1_valididx_4,
               io_tlb_1_resp_bits_s1_valididx_3, io_tlb_1_resp_bits_s1_valididx_2,
               io_tlb_1_resp_bits_s1_valididx_1, io_tlb_1_resp_bits_s1_valididx_0}),
    .satp    (csr_satp_probe),
    .s1_tag  (io_tlb_1_resp_bits_s1_entry_tag),
    .pbmt    (io_tlb_1_resp_bits_s1_entry_pbmt),
    .g_pbmt  (io_tlb_1_resp_bits_s2_entry_pbmt),
    .s1_ppn  (io_tlb_1_resp_bits_s1_entry_ppn),
    .ppn_low ({io_tlb_1_resp_bits_s1_ppn_low_7, io_tlb_1_resp_bits_s1_ppn_low_6,
               io_tlb_1_resp_bits_s1_ppn_low_5, io_tlb_1_resp_bits_s1_ppn_low_4,
               io_tlb_1_resp_bits_s1_ppn_low_3, io_tlb_1_resp_bits_s1_ppn_low_2,
               io_tlb_1_resp_bits_s1_ppn_low_1, io_tlb_1_resp_bits_s1_ppn_low_0}),
    .perm    ({io_tlb_1_resp_bits_s1_entry_perm_d, io_tlb_1_resp_bits_s1_entry_perm_a,
               io_tlb_1_resp_bits_s1_entry_perm_g, io_tlb_1_resp_bits_s1_entry_perm_u,
               io_tlb_1_resp_bits_s1_entry_perm_x, io_tlb_1_resp_bits_s1_entry_perm_w,
               io_tlb_1_resp_bits_s1_entry_perm_r}),
    .level   (io_tlb_1_resp_bits_s1_entry_level),
    .pf      (io_tlb_1_resp_bits_s1_pf),
    .pteidx  ({io_tlb_1_resp_bits_s1_pteidx_7, io_tlb_1_resp_bits_s1_pteidx_6,
               io_tlb_1_resp_bits_s1_pteidx_5, io_tlb_1_resp_bits_s1_pteidx_4,
               io_tlb_1_resp_bits_s1_pteidx_3, io_tlb_1_resp_bits_s1_pteidx_2,
               io_tlb_1_resp_bits_s1_pteidx_1, io_tlb_1_resp_bits_s1_pteidx_0}),
    .vsatp   (csr_vsatp_probe),
    .hgatp   (csr_hgatp_probe),
    .s2_tag  (io_tlb_1_resp_bits_s2_entry_tag),
    .g_perm  ({io_tlb_1_resp_bits_s2_entry_perm_d, io_tlb_1_resp_bits_s2_entry_perm_a,
               io_tlb_1_resp_bits_s2_entry_perm_g, io_tlb_1_resp_bits_s2_entry_perm_u,
               io_tlb_1_resp_bits_s2_entry_perm_x, io_tlb_1_resp_bits_s2_entry_perm_w,
               io_tlb_1_resp_bits_s2_entry_perm_r}),
    .g_level (io_tlb_1_resp_bits_s2_entry_level),
    .s2_ppn  (io_tlb_1_resp_bits_s2_entry_ppn),
    .gpf     (io_tlb_1_resp_bits_s2_gpf),
    .s2xlate (io_tlb_1_resp_bits_s2xlate),
    .coreid  (difftest_coreid),
    .index   (8'h1));

  // ==========================================================================
  // 11. 性能事件两级打拍
  // --------------------------------------------------------------------------
  // 19 路：0..3 ← LLPTW，4..11 ← PtwCache，12..18 ← PTW。打两拍对齐输出。
  // ==========================================================================
  logic [5:0] perf_src [PERF_NUM];
  assign perf_src[0]  = u_llptw_perf_0_value;
  assign perf_src[1]  = u_llptw_perf_1_value;
  assign perf_src[2]  = u_llptw_perf_2_value;
  assign perf_src[3]  = u_llptw_perf_3_value;
  assign perf_src[4]  = u_page_cache_perf_0_value;
  assign perf_src[5]  = u_page_cache_perf_1_value;
  assign perf_src[6]  = u_page_cache_perf_2_value;
  assign perf_src[7]  = u_page_cache_perf_3_value;
  assign perf_src[8]  = u_page_cache_perf_4_value;
  assign perf_src[9]  = u_page_cache_perf_5_value;
  assign perf_src[10] = u_page_cache_perf_6_value;
  assign perf_src[11] = u_page_cache_perf_7_value;
  assign perf_src[12] = u_ptw_perf_0_value;
  assign perf_src[13] = u_ptw_perf_1_value;
  assign perf_src[14] = u_ptw_perf_2_value;
  assign perf_src[15] = u_ptw_perf_3_value;
  assign perf_src[16] = u_ptw_perf_4_value;
  assign perf_src[17] = u_ptw_perf_5_value;
  assign perf_src[18] = u_ptw_perf_6_value;
  logic [5:0] perf_s1 [PERF_NUM], perf_s2 [PERF_NUM];
  for (genvar i = 0; i < PERF_NUM; i++) begin : g_perf
    always_ff @(posedge clock) begin
      perf_s1[i] <= perf_src[i];
      perf_s2[i] <= perf_s1[i];
    end
  end
  // BEGIN GENERATED(perf_out)
  assign io_perf_0_value  = perf_s2[0];
  assign io_perf_1_value  = perf_s2[1];
  assign io_perf_2_value  = perf_s2[2];
  assign io_perf_3_value  = perf_s2[3];
  assign io_perf_4_value  = perf_s2[4];
  assign io_perf_5_value  = perf_s2[5];
  assign io_perf_6_value  = perf_s2[6];
  assign io_perf_7_value  = perf_s2[7];
  assign io_perf_8_value  = perf_s2[8];
  assign io_perf_9_value  = perf_s2[9];
  assign io_perf_10_value = perf_s2[10];
  assign io_perf_11_value = perf_s2[11];
  assign io_perf_12_value = perf_s2[12];
  assign io_perf_13_value = perf_s2[13];
  assign io_perf_14_value = perf_s2[14];
  assign io_perf_15_value = perf_s2[15];
  assign io_perf_16_value = perf_s2[16];
  assign io_perf_17_value = perf_s2[17];
  assign io_perf_18_value = perf_s2[18];
  // END GENERATED

  // ==========================================================================
  // 子模块实例（与 golden 同名同结构；对本层是黑盒）
  // ==========================================================================
  // BEGIN GENERATED(inst)
  DelayN_220 u_sfence_delay (
    .clock                           (clock),
    .io_in_valid                     (io_sfence_valid),
    .io_in_bits_rs1                  (io_sfence_bits_rs1),
    .io_in_bits_rs2                  (io_sfence_bits_rs2),
    .io_in_bits_addr                 (io_sfence_bits_addr),
    .io_in_bits_id                   (io_sfence_bits_id),
    .io_in_bits_hv                   (io_sfence_bits_hv),
    .io_in_bits_hg                   (io_sfence_bits_hg),
    .io_out_valid                    (u_sfence_delay_out_valid),
    .io_out_bits_rs1                 (u_sfence_delay_out_bits_rs1),
    .io_out_bits_rs2                 (u_sfence_delay_out_bits_rs2),
    .io_out_bits_addr                (u_sfence_delay_out_bits_addr),
    .io_out_bits_id                  (u_sfence_delay_out_bits_id),
    .io_out_bits_hv                  (u_sfence_delay_out_bits_hv),
    .io_out_bits_hg                  (u_sfence_delay_out_bits_hg)
  );

  DelayN_221 u_csr_delay (
    .clock                           (clock),
    .io_in_satp_mode                 (io_csr_tlb_satp_mode),
    .io_in_satp_asid                 (io_csr_tlb_satp_asid),
    .io_in_satp_ppn                  (io_csr_tlb_satp_ppn),
    .io_in_satp_changed              (io_csr_tlb_satp_changed),
    .io_in_vsatp_mode                (io_csr_tlb_vsatp_mode),
    .io_in_vsatp_asid                (io_csr_tlb_vsatp_asid),
    .io_in_vsatp_ppn                 (io_csr_tlb_vsatp_ppn),
    .io_in_vsatp_changed             (io_csr_tlb_vsatp_changed),
    .io_in_hgatp_mode                (io_csr_tlb_hgatp_mode),
    .io_in_hgatp_vmid                (io_csr_tlb_hgatp_vmid),
    .io_in_hgatp_ppn                 (io_csr_tlb_hgatp_ppn),
    .io_in_hgatp_changed             (io_csr_tlb_hgatp_changed),
    .io_in_mbmc_BME                  (io_csr_tlb_mbmc_BME),
    .io_in_mbmc_CMODE                (io_csr_tlb_mbmc_CMODE),
    .io_in_mbmc_BCLEAR               (io_csr_tlb_mbmc_BCLEAR),
    .io_in_mbmc_BMA                  (io_csr_tlb_mbmc_BMA),
    .io_in_priv_virt                 (io_csr_tlb_priv_virt),
    .io_in_priv_virt_changed         (io_csr_tlb_priv_virt_changed),
    .io_in_priv_debug                (io_csr_tlb_priv_debug),
    .io_in_mPBMTE                    (io_csr_tlb_mPBMTE),
    .io_in_hPBMTE                    (io_csr_tlb_hPBMTE),
    .io_out_satp_mode                (u_csr_delay_out_satp_mode),
    .io_out_satp_asid                (u_csr_delay_out_satp_asid),
    .io_out_satp_ppn                 (u_csr_delay_out_satp_ppn),
    .io_out_satp_changed             (u_csr_delay_out_satp_changed),
    .io_out_vsatp_mode               (u_csr_delay_out_vsatp_mode),
    .io_out_vsatp_asid               (u_csr_delay_out_vsatp_asid),
    .io_out_vsatp_ppn                (u_csr_delay_out_vsatp_ppn),
    .io_out_vsatp_changed            (u_csr_delay_out_vsatp_changed),
    .io_out_hgatp_mode               (u_csr_delay_out_hgatp_mode),
    .io_out_hgatp_vmid               (u_csr_delay_out_hgatp_vmid),
    .io_out_hgatp_ppn                (u_csr_delay_out_hgatp_ppn),
    .io_out_hgatp_changed            (u_csr_delay_out_hgatp_changed),
    .io_out_mbmc_BME                 (u_csr_delay_out_mbmc_BME),
    .io_out_mbmc_CMODE               (u_csr_delay_out_mbmc_CMODE),
    .io_out_mbmc_BCLEAR              (u_csr_delay_out_mbmc_BCLEAR),
    .io_out_mbmc_BMA                 (u_csr_delay_out_mbmc_BMA),
    .io_out_priv_virt                (u_csr_delay_out_priv_virt),
    .io_out_priv_virt_changed        (u_csr_delay_out_priv_virt_changed),
    .io_out_priv_debug               (u_csr_delay_out_priv_debug),
    .io_out_mPBMTE                   (u_csr_delay_out_mPBMTE),
    .io_out_hPBMTE                   (u_csr_delay_out_hPBMTE)
  );

  PMP u_pmp (
    .clock                           (clock),
    .reset                           (reset),
    .io_distribute_csr_w_valid       (io_csr_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr   (io_csr_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data   (io_csr_distribute_csr_w_bits_data),
    .io_pmp_0_cfg_l                  (u_pmp_pmp_0_cfg_l),
    .io_pmp_0_cfg_a                  (u_pmp_pmp_0_cfg_a),
    .io_pmp_0_cfg_x                  (/* unused */),
    .io_pmp_0_cfg_w                  (/* unused */),
    .io_pmp_0_cfg_r                  (u_pmp_pmp_0_cfg_r),
    .io_pmp_0_addr                   (u_pmp_pmp_0_addr),
    .io_pmp_0_mask                   (u_pmp_pmp_0_mask),
    .io_pmp_1_cfg_l                  (u_pmp_pmp_1_cfg_l),
    .io_pmp_1_cfg_a                  (u_pmp_pmp_1_cfg_a),
    .io_pmp_1_cfg_x                  (/* unused */),
    .io_pmp_1_cfg_w                  (/* unused */),
    .io_pmp_1_cfg_r                  (u_pmp_pmp_1_cfg_r),
    .io_pmp_1_addr                   (u_pmp_pmp_1_addr),
    .io_pmp_1_mask                   (u_pmp_pmp_1_mask),
    .io_pmp_2_cfg_l                  (u_pmp_pmp_2_cfg_l),
    .io_pmp_2_cfg_a                  (u_pmp_pmp_2_cfg_a),
    .io_pmp_2_cfg_x                  (/* unused */),
    .io_pmp_2_cfg_w                  (/* unused */),
    .io_pmp_2_cfg_r                  (u_pmp_pmp_2_cfg_r),
    .io_pmp_2_addr                   (u_pmp_pmp_2_addr),
    .io_pmp_2_mask                   (u_pmp_pmp_2_mask),
    .io_pmp_3_cfg_l                  (u_pmp_pmp_3_cfg_l),
    .io_pmp_3_cfg_a                  (u_pmp_pmp_3_cfg_a),
    .io_pmp_3_cfg_x                  (/* unused */),
    .io_pmp_3_cfg_w                  (/* unused */),
    .io_pmp_3_cfg_r                  (u_pmp_pmp_3_cfg_r),
    .io_pmp_3_addr                   (u_pmp_pmp_3_addr),
    .io_pmp_3_mask                   (u_pmp_pmp_3_mask),
    .io_pmp_4_cfg_l                  (u_pmp_pmp_4_cfg_l),
    .io_pmp_4_cfg_a                  (u_pmp_pmp_4_cfg_a),
    .io_pmp_4_cfg_x                  (/* unused */),
    .io_pmp_4_cfg_w                  (/* unused */),
    .io_pmp_4_cfg_r                  (u_pmp_pmp_4_cfg_r),
    .io_pmp_4_addr                   (u_pmp_pmp_4_addr),
    .io_pmp_4_mask                   (u_pmp_pmp_4_mask),
    .io_pmp_5_cfg_l                  (u_pmp_pmp_5_cfg_l),
    .io_pmp_5_cfg_a                  (u_pmp_pmp_5_cfg_a),
    .io_pmp_5_cfg_x                  (/* unused */),
    .io_pmp_5_cfg_w                  (/* unused */),
    .io_pmp_5_cfg_r                  (u_pmp_pmp_5_cfg_r),
    .io_pmp_5_addr                   (u_pmp_pmp_5_addr),
    .io_pmp_5_mask                   (u_pmp_pmp_5_mask),
    .io_pmp_6_cfg_l                  (u_pmp_pmp_6_cfg_l),
    .io_pmp_6_cfg_a                  (u_pmp_pmp_6_cfg_a),
    .io_pmp_6_cfg_x                  (/* unused */),
    .io_pmp_6_cfg_w                  (/* unused */),
    .io_pmp_6_cfg_r                  (u_pmp_pmp_6_cfg_r),
    .io_pmp_6_addr                   (u_pmp_pmp_6_addr),
    .io_pmp_6_mask                   (u_pmp_pmp_6_mask),
    .io_pmp_7_cfg_l                  (u_pmp_pmp_7_cfg_l),
    .io_pmp_7_cfg_a                  (u_pmp_pmp_7_cfg_a),
    .io_pmp_7_cfg_x                  (/* unused */),
    .io_pmp_7_cfg_w                  (/* unused */),
    .io_pmp_7_cfg_r                  (u_pmp_pmp_7_cfg_r),
    .io_pmp_7_addr                   (u_pmp_pmp_7_addr),
    .io_pmp_7_mask                   (u_pmp_pmp_7_mask),
    .io_pmp_8_cfg_l                  (u_pmp_pmp_8_cfg_l),
    .io_pmp_8_cfg_a                  (u_pmp_pmp_8_cfg_a),
    .io_pmp_8_cfg_x                  (/* unused */),
    .io_pmp_8_cfg_w                  (/* unused */),
    .io_pmp_8_cfg_r                  (u_pmp_pmp_8_cfg_r),
    .io_pmp_8_addr                   (u_pmp_pmp_8_addr),
    .io_pmp_8_mask                   (u_pmp_pmp_8_mask),
    .io_pmp_9_cfg_l                  (u_pmp_pmp_9_cfg_l),
    .io_pmp_9_cfg_a                  (u_pmp_pmp_9_cfg_a),
    .io_pmp_9_cfg_x                  (/* unused */),
    .io_pmp_9_cfg_w                  (/* unused */),
    .io_pmp_9_cfg_r                  (u_pmp_pmp_9_cfg_r),
    .io_pmp_9_addr                   (u_pmp_pmp_9_addr),
    .io_pmp_9_mask                   (u_pmp_pmp_9_mask),
    .io_pmp_10_cfg_l                 (u_pmp_pmp_10_cfg_l),
    .io_pmp_10_cfg_a                 (u_pmp_pmp_10_cfg_a),
    .io_pmp_10_cfg_x                 (/* unused */),
    .io_pmp_10_cfg_w                 (/* unused */),
    .io_pmp_10_cfg_r                 (u_pmp_pmp_10_cfg_r),
    .io_pmp_10_addr                  (u_pmp_pmp_10_addr),
    .io_pmp_10_mask                  (u_pmp_pmp_10_mask),
    .io_pmp_11_cfg_l                 (u_pmp_pmp_11_cfg_l),
    .io_pmp_11_cfg_a                 (u_pmp_pmp_11_cfg_a),
    .io_pmp_11_cfg_x                 (/* unused */),
    .io_pmp_11_cfg_w                 (/* unused */),
    .io_pmp_11_cfg_r                 (u_pmp_pmp_11_cfg_r),
    .io_pmp_11_addr                  (u_pmp_pmp_11_addr),
    .io_pmp_11_mask                  (u_pmp_pmp_11_mask),
    .io_pmp_12_cfg_l                 (u_pmp_pmp_12_cfg_l),
    .io_pmp_12_cfg_a                 (u_pmp_pmp_12_cfg_a),
    .io_pmp_12_cfg_x                 (/* unused */),
    .io_pmp_12_cfg_w                 (/* unused */),
    .io_pmp_12_cfg_r                 (u_pmp_pmp_12_cfg_r),
    .io_pmp_12_addr                  (u_pmp_pmp_12_addr),
    .io_pmp_12_mask                  (u_pmp_pmp_12_mask),
    .io_pmp_13_cfg_l                 (u_pmp_pmp_13_cfg_l),
    .io_pmp_13_cfg_a                 (u_pmp_pmp_13_cfg_a),
    .io_pmp_13_cfg_x                 (/* unused */),
    .io_pmp_13_cfg_w                 (/* unused */),
    .io_pmp_13_cfg_r                 (u_pmp_pmp_13_cfg_r),
    .io_pmp_13_addr                  (u_pmp_pmp_13_addr),
    .io_pmp_13_mask                  (u_pmp_pmp_13_mask),
    .io_pmp_14_cfg_l                 (u_pmp_pmp_14_cfg_l),
    .io_pmp_14_cfg_a                 (u_pmp_pmp_14_cfg_a),
    .io_pmp_14_cfg_x                 (/* unused */),
    .io_pmp_14_cfg_w                 (/* unused */),
    .io_pmp_14_cfg_r                 (u_pmp_pmp_14_cfg_r),
    .io_pmp_14_addr                  (u_pmp_pmp_14_addr),
    .io_pmp_14_mask                  (u_pmp_pmp_14_mask),
    .io_pmp_15_cfg_l                 (u_pmp_pmp_15_cfg_l),
    .io_pmp_15_cfg_a                 (u_pmp_pmp_15_cfg_a),
    .io_pmp_15_cfg_x                 (/* unused */),
    .io_pmp_15_cfg_w                 (/* unused */),
    .io_pmp_15_cfg_r                 (u_pmp_pmp_15_cfg_r),
    .io_pmp_15_addr                  (u_pmp_pmp_15_addr),
    .io_pmp_15_mask                  (u_pmp_pmp_15_mask),
    .io_pmp_16_cfg_l                 (u_pmp_pmp_16_cfg_l),
    .io_pmp_16_cfg_a                 (u_pmp_pmp_16_cfg_a),
    .io_pmp_16_cfg_x                 (/* unused */),
    .io_pmp_16_cfg_w                 (/* unused */),
    .io_pmp_16_cfg_r                 (u_pmp_pmp_16_cfg_r),
    .io_pmp_16_addr                  (u_pmp_pmp_16_addr),
    .io_pmp_16_mask                  (u_pmp_pmp_16_mask),
    .io_pmp_17_cfg_l                 (u_pmp_pmp_17_cfg_l),
    .io_pmp_17_cfg_a                 (u_pmp_pmp_17_cfg_a),
    .io_pmp_17_cfg_x                 (/* unused */),
    .io_pmp_17_cfg_w                 (/* unused */),
    .io_pmp_17_cfg_r                 (u_pmp_pmp_17_cfg_r),
    .io_pmp_17_addr                  (u_pmp_pmp_17_addr),
    .io_pmp_17_mask                  (u_pmp_pmp_17_mask),
    .io_pmp_18_cfg_l                 (u_pmp_pmp_18_cfg_l),
    .io_pmp_18_cfg_a                 (u_pmp_pmp_18_cfg_a),
    .io_pmp_18_cfg_x                 (/* unused */),
    .io_pmp_18_cfg_w                 (/* unused */),
    .io_pmp_18_cfg_r                 (u_pmp_pmp_18_cfg_r),
    .io_pmp_18_addr                  (u_pmp_pmp_18_addr),
    .io_pmp_18_mask                  (u_pmp_pmp_18_mask),
    .io_pmp_19_cfg_l                 (u_pmp_pmp_19_cfg_l),
    .io_pmp_19_cfg_a                 (u_pmp_pmp_19_cfg_a),
    .io_pmp_19_cfg_x                 (/* unused */),
    .io_pmp_19_cfg_w                 (/* unused */),
    .io_pmp_19_cfg_r                 (u_pmp_pmp_19_cfg_r),
    .io_pmp_19_addr                  (u_pmp_pmp_19_addr),
    .io_pmp_19_mask                  (u_pmp_pmp_19_mask),
    .io_pmp_20_cfg_l                 (u_pmp_pmp_20_cfg_l),
    .io_pmp_20_cfg_a                 (u_pmp_pmp_20_cfg_a),
    .io_pmp_20_cfg_x                 (/* unused */),
    .io_pmp_20_cfg_w                 (/* unused */),
    .io_pmp_20_cfg_r                 (u_pmp_pmp_20_cfg_r),
    .io_pmp_20_addr                  (u_pmp_pmp_20_addr),
    .io_pmp_20_mask                  (u_pmp_pmp_20_mask),
    .io_pmp_21_cfg_l                 (u_pmp_pmp_21_cfg_l),
    .io_pmp_21_cfg_a                 (u_pmp_pmp_21_cfg_a),
    .io_pmp_21_cfg_x                 (/* unused */),
    .io_pmp_21_cfg_w                 (/* unused */),
    .io_pmp_21_cfg_r                 (u_pmp_pmp_21_cfg_r),
    .io_pmp_21_addr                  (u_pmp_pmp_21_addr),
    .io_pmp_21_mask                  (u_pmp_pmp_21_mask),
    .io_pmp_22_cfg_l                 (u_pmp_pmp_22_cfg_l),
    .io_pmp_22_cfg_a                 (u_pmp_pmp_22_cfg_a),
    .io_pmp_22_cfg_x                 (/* unused */),
    .io_pmp_22_cfg_w                 (/* unused */),
    .io_pmp_22_cfg_r                 (u_pmp_pmp_22_cfg_r),
    .io_pmp_22_addr                  (u_pmp_pmp_22_addr),
    .io_pmp_22_mask                  (u_pmp_pmp_22_mask),
    .io_pmp_23_cfg_l                 (u_pmp_pmp_23_cfg_l),
    .io_pmp_23_cfg_a                 (u_pmp_pmp_23_cfg_a),
    .io_pmp_23_cfg_x                 (/* unused */),
    .io_pmp_23_cfg_w                 (/* unused */),
    .io_pmp_23_cfg_r                 (u_pmp_pmp_23_cfg_r),
    .io_pmp_23_addr                  (u_pmp_pmp_23_addr),
    .io_pmp_23_mask                  (u_pmp_pmp_23_mask),
    .io_pmp_24_cfg_l                 (u_pmp_pmp_24_cfg_l),
    .io_pmp_24_cfg_a                 (u_pmp_pmp_24_cfg_a),
    .io_pmp_24_cfg_x                 (/* unused */),
    .io_pmp_24_cfg_w                 (/* unused */),
    .io_pmp_24_cfg_r                 (u_pmp_pmp_24_cfg_r),
    .io_pmp_24_addr                  (u_pmp_pmp_24_addr),
    .io_pmp_24_mask                  (u_pmp_pmp_24_mask),
    .io_pmp_25_cfg_l                 (u_pmp_pmp_25_cfg_l),
    .io_pmp_25_cfg_a                 (u_pmp_pmp_25_cfg_a),
    .io_pmp_25_cfg_x                 (/* unused */),
    .io_pmp_25_cfg_w                 (/* unused */),
    .io_pmp_25_cfg_r                 (u_pmp_pmp_25_cfg_r),
    .io_pmp_25_addr                  (u_pmp_pmp_25_addr),
    .io_pmp_25_mask                  (u_pmp_pmp_25_mask),
    .io_pmp_26_cfg_l                 (u_pmp_pmp_26_cfg_l),
    .io_pmp_26_cfg_a                 (u_pmp_pmp_26_cfg_a),
    .io_pmp_26_cfg_x                 (/* unused */),
    .io_pmp_26_cfg_w                 (/* unused */),
    .io_pmp_26_cfg_r                 (u_pmp_pmp_26_cfg_r),
    .io_pmp_26_addr                  (u_pmp_pmp_26_addr),
    .io_pmp_26_mask                  (u_pmp_pmp_26_mask),
    .io_pmp_27_cfg_l                 (u_pmp_pmp_27_cfg_l),
    .io_pmp_27_cfg_a                 (u_pmp_pmp_27_cfg_a),
    .io_pmp_27_cfg_x                 (/* unused */),
    .io_pmp_27_cfg_w                 (/* unused */),
    .io_pmp_27_cfg_r                 (u_pmp_pmp_27_cfg_r),
    .io_pmp_27_addr                  (u_pmp_pmp_27_addr),
    .io_pmp_27_mask                  (u_pmp_pmp_27_mask),
    .io_pmp_28_cfg_l                 (u_pmp_pmp_28_cfg_l),
    .io_pmp_28_cfg_a                 (u_pmp_pmp_28_cfg_a),
    .io_pmp_28_cfg_x                 (/* unused */),
    .io_pmp_28_cfg_w                 (/* unused */),
    .io_pmp_28_cfg_r                 (u_pmp_pmp_28_cfg_r),
    .io_pmp_28_addr                  (u_pmp_pmp_28_addr),
    .io_pmp_28_mask                  (u_pmp_pmp_28_mask),
    .io_pmp_29_cfg_l                 (u_pmp_pmp_29_cfg_l),
    .io_pmp_29_cfg_a                 (u_pmp_pmp_29_cfg_a),
    .io_pmp_29_cfg_x                 (/* unused */),
    .io_pmp_29_cfg_w                 (/* unused */),
    .io_pmp_29_cfg_r                 (u_pmp_pmp_29_cfg_r),
    .io_pmp_29_addr                  (u_pmp_pmp_29_addr),
    .io_pmp_29_mask                  (u_pmp_pmp_29_mask),
    .io_pmp_30_cfg_l                 (u_pmp_pmp_30_cfg_l),
    .io_pmp_30_cfg_a                 (u_pmp_pmp_30_cfg_a),
    .io_pmp_30_cfg_x                 (/* unused */),
    .io_pmp_30_cfg_w                 (/* unused */),
    .io_pmp_30_cfg_r                 (u_pmp_pmp_30_cfg_r),
    .io_pmp_30_addr                  (u_pmp_pmp_30_addr),
    .io_pmp_30_mask                  (u_pmp_pmp_30_mask),
    .io_pmp_31_cfg_l                 (u_pmp_pmp_31_cfg_l),
    .io_pmp_31_cfg_a                 (u_pmp_pmp_31_cfg_a),
    .io_pmp_31_cfg_x                 (/* unused */),
    .io_pmp_31_cfg_w                 (/* unused */),
    .io_pmp_31_cfg_r                 (u_pmp_pmp_31_cfg_r),
    .io_pmp_31_addr                  (u_pmp_pmp_31_addr),
    .io_pmp_31_mask                  (u_pmp_pmp_31_mask),
    .io_pma_0_cfg_c                  (u_pmp_pma_0_cfg_c),
    .io_pma_0_cfg_atomic             (u_pmp_pma_0_cfg_atomic),
    .io_pma_0_cfg_a                  (u_pmp_pma_0_cfg_a),
    .io_pma_0_cfg_x                  (/* unused */),
    .io_pma_0_cfg_w                  (/* unused */),
    .io_pma_0_cfg_r                  (u_pmp_pma_0_cfg_r),
    .io_pma_0_addr                   (u_pmp_pma_0_addr),
    .io_pma_0_mask                   (u_pmp_pma_0_mask),
    .io_pma_1_cfg_c                  (u_pmp_pma_1_cfg_c),
    .io_pma_1_cfg_atomic             (u_pmp_pma_1_cfg_atomic),
    .io_pma_1_cfg_a                  (u_pmp_pma_1_cfg_a),
    .io_pma_1_cfg_x                  (/* unused */),
    .io_pma_1_cfg_w                  (/* unused */),
    .io_pma_1_cfg_r                  (u_pmp_pma_1_cfg_r),
    .io_pma_1_addr                   (u_pmp_pma_1_addr),
    .io_pma_1_mask                   (u_pmp_pma_1_mask),
    .io_pma_2_cfg_c                  (u_pmp_pma_2_cfg_c),
    .io_pma_2_cfg_atomic             (u_pmp_pma_2_cfg_atomic),
    .io_pma_2_cfg_a                  (u_pmp_pma_2_cfg_a),
    .io_pma_2_cfg_x                  (/* unused */),
    .io_pma_2_cfg_w                  (/* unused */),
    .io_pma_2_cfg_r                  (u_pmp_pma_2_cfg_r),
    .io_pma_2_addr                   (u_pmp_pma_2_addr),
    .io_pma_2_mask                   (u_pmp_pma_2_mask),
    .io_pma_3_cfg_c                  (u_pmp_pma_3_cfg_c),
    .io_pma_3_cfg_atomic             (u_pmp_pma_3_cfg_atomic),
    .io_pma_3_cfg_a                  (u_pmp_pma_3_cfg_a),
    .io_pma_3_cfg_x                  (/* unused */),
    .io_pma_3_cfg_w                  (/* unused */),
    .io_pma_3_cfg_r                  (u_pmp_pma_3_cfg_r),
    .io_pma_3_addr                   (u_pmp_pma_3_addr),
    .io_pma_3_mask                   (u_pmp_pma_3_mask),
    .io_pma_4_cfg_c                  (u_pmp_pma_4_cfg_c),
    .io_pma_4_cfg_atomic             (u_pmp_pma_4_cfg_atomic),
    .io_pma_4_cfg_a                  (u_pmp_pma_4_cfg_a),
    .io_pma_4_cfg_x                  (/* unused */),
    .io_pma_4_cfg_w                  (/* unused */),
    .io_pma_4_cfg_r                  (u_pmp_pma_4_cfg_r),
    .io_pma_4_addr                   (u_pmp_pma_4_addr),
    .io_pma_4_mask                   (u_pmp_pma_4_mask),
    .io_pma_5_cfg_c                  (u_pmp_pma_5_cfg_c),
    .io_pma_5_cfg_atomic             (u_pmp_pma_5_cfg_atomic),
    .io_pma_5_cfg_a                  (u_pmp_pma_5_cfg_a),
    .io_pma_5_cfg_x                  (/* unused */),
    .io_pma_5_cfg_w                  (/* unused */),
    .io_pma_5_cfg_r                  (u_pmp_pma_5_cfg_r),
    .io_pma_5_addr                   (u_pmp_pma_5_addr),
    .io_pma_5_mask                   (u_pmp_pma_5_mask),
    .io_pma_6_cfg_c                  (u_pmp_pma_6_cfg_c),
    .io_pma_6_cfg_atomic             (u_pmp_pma_6_cfg_atomic),
    .io_pma_6_cfg_a                  (u_pmp_pma_6_cfg_a),
    .io_pma_6_cfg_x                  (/* unused */),
    .io_pma_6_cfg_w                  (/* unused */),
    .io_pma_6_cfg_r                  (u_pmp_pma_6_cfg_r),
    .io_pma_6_addr                   (u_pmp_pma_6_addr),
    .io_pma_6_mask                   (u_pmp_pma_6_mask),
    .io_pma_7_cfg_c                  (u_pmp_pma_7_cfg_c),
    .io_pma_7_cfg_atomic             (u_pmp_pma_7_cfg_atomic),
    .io_pma_7_cfg_a                  (u_pmp_pma_7_cfg_a),
    .io_pma_7_cfg_x                  (/* unused */),
    .io_pma_7_cfg_w                  (/* unused */),
    .io_pma_7_cfg_r                  (u_pmp_pma_7_cfg_r),
    .io_pma_7_addr                   (u_pmp_pma_7_addr),
    .io_pma_7_mask                   (u_pmp_pma_7_mask),
    .io_pma_8_cfg_c                  (u_pmp_pma_8_cfg_c),
    .io_pma_8_cfg_atomic             (u_pmp_pma_8_cfg_atomic),
    .io_pma_8_cfg_a                  (u_pmp_pma_8_cfg_a),
    .io_pma_8_cfg_x                  (/* unused */),
    .io_pma_8_cfg_w                  (/* unused */),
    .io_pma_8_cfg_r                  (u_pmp_pma_8_cfg_r),
    .io_pma_8_addr                   (u_pmp_pma_8_addr),
    .io_pma_8_mask                   (u_pmp_pma_8_mask),
    .io_pma_9_cfg_c                  (u_pmp_pma_9_cfg_c),
    .io_pma_9_cfg_atomic             (u_pmp_pma_9_cfg_atomic),
    .io_pma_9_cfg_a                  (u_pmp_pma_9_cfg_a),
    .io_pma_9_cfg_x                  (/* unused */),
    .io_pma_9_cfg_w                  (/* unused */),
    .io_pma_9_cfg_r                  (u_pmp_pma_9_cfg_r),
    .io_pma_9_addr                   (u_pmp_pma_9_addr),
    .io_pma_9_mask                   (u_pmp_pma_9_mask),
    .io_pma_10_cfg_c                 (u_pmp_pma_10_cfg_c),
    .io_pma_10_cfg_atomic            (u_pmp_pma_10_cfg_atomic),
    .io_pma_10_cfg_a                 (u_pmp_pma_10_cfg_a),
    .io_pma_10_cfg_x                 (/* unused */),
    .io_pma_10_cfg_w                 (/* unused */),
    .io_pma_10_cfg_r                 (u_pmp_pma_10_cfg_r),
    .io_pma_10_addr                  (u_pmp_pma_10_addr),
    .io_pma_10_mask                  (u_pmp_pma_10_mask),
    .io_pma_11_cfg_c                 (u_pmp_pma_11_cfg_c),
    .io_pma_11_cfg_atomic            (u_pmp_pma_11_cfg_atomic),
    .io_pma_11_cfg_a                 (u_pmp_pma_11_cfg_a),
    .io_pma_11_cfg_x                 (/* unused */),
    .io_pma_11_cfg_w                 (/* unused */),
    .io_pma_11_cfg_r                 (u_pmp_pma_11_cfg_r),
    .io_pma_11_addr                  (u_pmp_pma_11_addr),
    .io_pma_11_mask                  (u_pmp_pma_11_mask),
    .io_pma_12_cfg_c                 (u_pmp_pma_12_cfg_c),
    .io_pma_12_cfg_atomic            (u_pmp_pma_12_cfg_atomic),
    .io_pma_12_cfg_a                 (u_pmp_pma_12_cfg_a),
    .io_pma_12_cfg_x                 (/* unused */),
    .io_pma_12_cfg_w                 (/* unused */),
    .io_pma_12_cfg_r                 (u_pmp_pma_12_cfg_r),
    .io_pma_12_addr                  (u_pmp_pma_12_addr),
    .io_pma_12_mask                  (u_pmp_pma_12_mask),
    .io_pma_13_cfg_c                 (u_pmp_pma_13_cfg_c),
    .io_pma_13_cfg_atomic            (u_pmp_pma_13_cfg_atomic),
    .io_pma_13_cfg_a                 (u_pmp_pma_13_cfg_a),
    .io_pma_13_cfg_x                 (/* unused */),
    .io_pma_13_cfg_w                 (/* unused */),
    .io_pma_13_cfg_r                 (u_pmp_pma_13_cfg_r),
    .io_pma_13_addr                  (u_pmp_pma_13_addr),
    .io_pma_13_mask                  (u_pmp_pma_13_mask),
    .io_pma_14_cfg_c                 (u_pmp_pma_14_cfg_c),
    .io_pma_14_cfg_atomic            (u_pmp_pma_14_cfg_atomic),
    .io_pma_14_cfg_a                 (u_pmp_pma_14_cfg_a),
    .io_pma_14_cfg_x                 (/* unused */),
    .io_pma_14_cfg_w                 (/* unused */),
    .io_pma_14_cfg_r                 (u_pmp_pma_14_cfg_r),
    .io_pma_14_addr                  (u_pmp_pma_14_addr),
    .io_pma_14_mask                  (u_pmp_pma_14_mask),
    .io_pma_15_cfg_c                 (u_pmp_pma_15_cfg_c),
    .io_pma_15_cfg_atomic            (u_pmp_pma_15_cfg_atomic),
    .io_pma_15_cfg_a                 (u_pmp_pma_15_cfg_a),
    .io_pma_15_cfg_x                 (/* unused */),
    .io_pma_15_cfg_w                 (/* unused */),
    .io_pma_15_cfg_r                 (u_pmp_pma_15_cfg_r),
    .io_pma_15_addr                  (u_pmp_pma_15_addr),
    .io_pma_15_mask                  (u_pmp_pma_15_mask),
    .io_pma_16_cfg_c                 (u_pmp_pma_16_cfg_c),
    .io_pma_16_cfg_atomic            (u_pmp_pma_16_cfg_atomic),
    .io_pma_16_cfg_a                 (u_pmp_pma_16_cfg_a),
    .io_pma_16_cfg_x                 (/* unused */),
    .io_pma_16_cfg_w                 (/* unused */),
    .io_pma_16_cfg_r                 (u_pmp_pma_16_cfg_r),
    .io_pma_16_addr                  (u_pmp_pma_16_addr),
    .io_pma_16_mask                  (u_pmp_pma_16_mask),
    .io_pma_17_cfg_c                 (u_pmp_pma_17_cfg_c),
    .io_pma_17_cfg_atomic            (u_pmp_pma_17_cfg_atomic),
    .io_pma_17_cfg_a                 (u_pmp_pma_17_cfg_a),
    .io_pma_17_cfg_x                 (/* unused */),
    .io_pma_17_cfg_w                 (/* unused */),
    .io_pma_17_cfg_r                 (u_pmp_pma_17_cfg_r),
    .io_pma_17_addr                  (u_pmp_pma_17_addr),
    .io_pma_17_mask                  (u_pmp_pma_17_mask),
    .io_pma_18_cfg_c                 (u_pmp_pma_18_cfg_c),
    .io_pma_18_cfg_atomic            (u_pmp_pma_18_cfg_atomic),
    .io_pma_18_cfg_a                 (u_pmp_pma_18_cfg_a),
    .io_pma_18_cfg_x                 (/* unused */),
    .io_pma_18_cfg_w                 (/* unused */),
    .io_pma_18_cfg_r                 (u_pmp_pma_18_cfg_r),
    .io_pma_18_addr                  (u_pmp_pma_18_addr),
    .io_pma_18_mask                  (u_pmp_pma_18_mask),
    .io_pma_19_cfg_c                 (u_pmp_pma_19_cfg_c),
    .io_pma_19_cfg_atomic            (u_pmp_pma_19_cfg_atomic),
    .io_pma_19_cfg_a                 (u_pmp_pma_19_cfg_a),
    .io_pma_19_cfg_x                 (/* unused */),
    .io_pma_19_cfg_w                 (/* unused */),
    .io_pma_19_cfg_r                 (u_pmp_pma_19_cfg_r),
    .io_pma_19_addr                  (u_pmp_pma_19_addr),
    .io_pma_19_mask                  (u_pmp_pma_19_mask),
    .io_pma_20_cfg_c                 (u_pmp_pma_20_cfg_c),
    .io_pma_20_cfg_atomic            (u_pmp_pma_20_cfg_atomic),
    .io_pma_20_cfg_a                 (u_pmp_pma_20_cfg_a),
    .io_pma_20_cfg_x                 (/* unused */),
    .io_pma_20_cfg_w                 (/* unused */),
    .io_pma_20_cfg_r                 (u_pmp_pma_20_cfg_r),
    .io_pma_20_addr                  (u_pmp_pma_20_addr),
    .io_pma_20_mask                  (u_pmp_pma_20_mask),
    .io_pma_21_cfg_c                 (u_pmp_pma_21_cfg_c),
    .io_pma_21_cfg_atomic            (u_pmp_pma_21_cfg_atomic),
    .io_pma_21_cfg_a                 (u_pmp_pma_21_cfg_a),
    .io_pma_21_cfg_x                 (/* unused */),
    .io_pma_21_cfg_w                 (/* unused */),
    .io_pma_21_cfg_r                 (u_pmp_pma_21_cfg_r),
    .io_pma_21_addr                  (u_pmp_pma_21_addr),
    .io_pma_21_mask                  (u_pmp_pma_21_mask),
    .io_pma_22_cfg_c                 (u_pmp_pma_22_cfg_c),
    .io_pma_22_cfg_atomic            (u_pmp_pma_22_cfg_atomic),
    .io_pma_22_cfg_a                 (u_pmp_pma_22_cfg_a),
    .io_pma_22_cfg_x                 (/* unused */),
    .io_pma_22_cfg_w                 (/* unused */),
    .io_pma_22_cfg_r                 (u_pmp_pma_22_cfg_r),
    .io_pma_22_addr                  (u_pmp_pma_22_addr),
    .io_pma_22_mask                  (u_pmp_pma_22_mask),
    .io_pma_23_cfg_c                 (u_pmp_pma_23_cfg_c),
    .io_pma_23_cfg_atomic            (u_pmp_pma_23_cfg_atomic),
    .io_pma_23_cfg_a                 (u_pmp_pma_23_cfg_a),
    .io_pma_23_cfg_x                 (/* unused */),
    .io_pma_23_cfg_w                 (/* unused */),
    .io_pma_23_cfg_r                 (u_pmp_pma_23_cfg_r),
    .io_pma_23_addr                  (u_pmp_pma_23_addr),
    .io_pma_23_mask                  (u_pmp_pma_23_mask),
    .io_pma_24_cfg_c                 (u_pmp_pma_24_cfg_c),
    .io_pma_24_cfg_atomic            (u_pmp_pma_24_cfg_atomic),
    .io_pma_24_cfg_a                 (u_pmp_pma_24_cfg_a),
    .io_pma_24_cfg_x                 (/* unused */),
    .io_pma_24_cfg_w                 (/* unused */),
    .io_pma_24_cfg_r                 (u_pmp_pma_24_cfg_r),
    .io_pma_24_addr                  (u_pmp_pma_24_addr),
    .io_pma_24_mask                  (u_pmp_pma_24_mask),
    .io_pma_25_cfg_c                 (u_pmp_pma_25_cfg_c),
    .io_pma_25_cfg_atomic            (u_pmp_pma_25_cfg_atomic),
    .io_pma_25_cfg_a                 (u_pmp_pma_25_cfg_a),
    .io_pma_25_cfg_x                 (/* unused */),
    .io_pma_25_cfg_w                 (/* unused */),
    .io_pma_25_cfg_r                 (u_pmp_pma_25_cfg_r),
    .io_pma_25_addr                  (u_pmp_pma_25_addr),
    .io_pma_25_mask                  (u_pmp_pma_25_mask),
    .io_pma_26_cfg_c                 (u_pmp_pma_26_cfg_c),
    .io_pma_26_cfg_atomic            (u_pmp_pma_26_cfg_atomic),
    .io_pma_26_cfg_a                 (u_pmp_pma_26_cfg_a),
    .io_pma_26_cfg_x                 (/* unused */),
    .io_pma_26_cfg_w                 (/* unused */),
    .io_pma_26_cfg_r                 (u_pmp_pma_26_cfg_r),
    .io_pma_26_addr                  (u_pmp_pma_26_addr),
    .io_pma_26_mask                  (u_pmp_pma_26_mask),
    .io_pma_27_cfg_c                 (u_pmp_pma_27_cfg_c),
    .io_pma_27_cfg_atomic            (u_pmp_pma_27_cfg_atomic),
    .io_pma_27_cfg_a                 (u_pmp_pma_27_cfg_a),
    .io_pma_27_cfg_x                 (/* unused */),
    .io_pma_27_cfg_w                 (/* unused */),
    .io_pma_27_cfg_r                 (u_pmp_pma_27_cfg_r),
    .io_pma_27_addr                  (u_pmp_pma_27_addr),
    .io_pma_27_mask                  (u_pmp_pma_27_mask),
    .io_pma_28_cfg_c                 (u_pmp_pma_28_cfg_c),
    .io_pma_28_cfg_atomic            (u_pmp_pma_28_cfg_atomic),
    .io_pma_28_cfg_a                 (u_pmp_pma_28_cfg_a),
    .io_pma_28_cfg_x                 (/* unused */),
    .io_pma_28_cfg_w                 (/* unused */),
    .io_pma_28_cfg_r                 (u_pmp_pma_28_cfg_r),
    .io_pma_28_addr                  (u_pmp_pma_28_addr),
    .io_pma_28_mask                  (u_pmp_pma_28_mask),
    .io_pma_29_cfg_c                 (u_pmp_pma_29_cfg_c),
    .io_pma_29_cfg_atomic            (u_pmp_pma_29_cfg_atomic),
    .io_pma_29_cfg_a                 (u_pmp_pma_29_cfg_a),
    .io_pma_29_cfg_x                 (/* unused */),
    .io_pma_29_cfg_w                 (/* unused */),
    .io_pma_29_cfg_r                 (u_pmp_pma_29_cfg_r),
    .io_pma_29_addr                  (u_pmp_pma_29_addr),
    .io_pma_29_mask                  (u_pmp_pma_29_mask),
    .io_pma_30_cfg_c                 (u_pmp_pma_30_cfg_c),
    .io_pma_30_cfg_atomic            (u_pmp_pma_30_cfg_atomic),
    .io_pma_30_cfg_a                 (u_pmp_pma_30_cfg_a),
    .io_pma_30_cfg_x                 (/* unused */),
    .io_pma_30_cfg_w                 (/* unused */),
    .io_pma_30_cfg_r                 (u_pmp_pma_30_cfg_r),
    .io_pma_30_addr                  (u_pmp_pma_30_addr),
    .io_pma_30_mask                  (u_pmp_pma_30_mask),
    .io_pma_31_cfg_c                 (u_pmp_pma_31_cfg_c),
    .io_pma_31_cfg_atomic            (u_pmp_pma_31_cfg_atomic),
    .io_pma_31_cfg_a                 (u_pmp_pma_31_cfg_a),
    .io_pma_31_cfg_x                 (/* unused */),
    .io_pma_31_cfg_w                 (/* unused */),
    .io_pma_31_cfg_r                 (u_pmp_pma_31_cfg_r),
    .io_pma_31_addr                  (u_pmp_pma_31_addr),
    .io_pma_31_mask                  (u_pmp_pma_31_mask)
  );

  PMPChecker u_pmp_chk_ptw (
    .io_check_env_mode               (2'h1),
    .io_check_env_debug              (u_pmp_chk_ptw__check_env_debug),
    .io_check_env_pmp_0_cfg_l        (u_pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a        (u_pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_r        (u_pmp_pmp_0_cfg_r),
    .io_check_env_pmp_0_addr         (u_pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask         (u_pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l        (u_pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a        (u_pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_r        (u_pmp_pmp_1_cfg_r),
    .io_check_env_pmp_1_addr         (u_pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask         (u_pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l        (u_pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a        (u_pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_r        (u_pmp_pmp_2_cfg_r),
    .io_check_env_pmp_2_addr         (u_pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask         (u_pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l        (u_pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a        (u_pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_r        (u_pmp_pmp_3_cfg_r),
    .io_check_env_pmp_3_addr         (u_pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask         (u_pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l        (u_pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a        (u_pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_r        (u_pmp_pmp_4_cfg_r),
    .io_check_env_pmp_4_addr         (u_pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask         (u_pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l        (u_pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a        (u_pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_r        (u_pmp_pmp_5_cfg_r),
    .io_check_env_pmp_5_addr         (u_pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask         (u_pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l        (u_pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a        (u_pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_r        (u_pmp_pmp_6_cfg_r),
    .io_check_env_pmp_6_addr         (u_pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask         (u_pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l        (u_pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a        (u_pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_r        (u_pmp_pmp_7_cfg_r),
    .io_check_env_pmp_7_addr         (u_pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask         (u_pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l        (u_pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a        (u_pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_r        (u_pmp_pmp_8_cfg_r),
    .io_check_env_pmp_8_addr         (u_pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask         (u_pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l        (u_pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a        (u_pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_r        (u_pmp_pmp_9_cfg_r),
    .io_check_env_pmp_9_addr         (u_pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask         (u_pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l       (u_pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a       (u_pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_r       (u_pmp_pmp_10_cfg_r),
    .io_check_env_pmp_10_addr        (u_pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask        (u_pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l       (u_pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a       (u_pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_r       (u_pmp_pmp_11_cfg_r),
    .io_check_env_pmp_11_addr        (u_pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask        (u_pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l       (u_pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a       (u_pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_r       (u_pmp_pmp_12_cfg_r),
    .io_check_env_pmp_12_addr        (u_pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask        (u_pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l       (u_pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a       (u_pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_r       (u_pmp_pmp_13_cfg_r),
    .io_check_env_pmp_13_addr        (u_pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask        (u_pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l       (u_pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a       (u_pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_r       (u_pmp_pmp_14_cfg_r),
    .io_check_env_pmp_14_addr        (u_pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask        (u_pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l       (u_pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a       (u_pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_r       (u_pmp_pmp_15_cfg_r),
    .io_check_env_pmp_15_addr        (u_pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask        (u_pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l       (u_pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a       (u_pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_r       (u_pmp_pmp_16_cfg_r),
    .io_check_env_pmp_16_addr        (u_pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask        (u_pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l       (u_pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a       (u_pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_r       (u_pmp_pmp_17_cfg_r),
    .io_check_env_pmp_17_addr        (u_pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask        (u_pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l       (u_pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a       (u_pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_r       (u_pmp_pmp_18_cfg_r),
    .io_check_env_pmp_18_addr        (u_pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask        (u_pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l       (u_pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a       (u_pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_r       (u_pmp_pmp_19_cfg_r),
    .io_check_env_pmp_19_addr        (u_pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask        (u_pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l       (u_pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a       (u_pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_r       (u_pmp_pmp_20_cfg_r),
    .io_check_env_pmp_20_addr        (u_pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask        (u_pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l       (u_pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a       (u_pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_r       (u_pmp_pmp_21_cfg_r),
    .io_check_env_pmp_21_addr        (u_pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask        (u_pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l       (u_pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a       (u_pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_r       (u_pmp_pmp_22_cfg_r),
    .io_check_env_pmp_22_addr        (u_pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask        (u_pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l       (u_pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a       (u_pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_r       (u_pmp_pmp_23_cfg_r),
    .io_check_env_pmp_23_addr        (u_pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask        (u_pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l       (u_pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a       (u_pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_r       (u_pmp_pmp_24_cfg_r),
    .io_check_env_pmp_24_addr        (u_pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask        (u_pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l       (u_pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a       (u_pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_r       (u_pmp_pmp_25_cfg_r),
    .io_check_env_pmp_25_addr        (u_pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask        (u_pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l       (u_pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a       (u_pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_r       (u_pmp_pmp_26_cfg_r),
    .io_check_env_pmp_26_addr        (u_pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask        (u_pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l       (u_pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a       (u_pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_r       (u_pmp_pmp_27_cfg_r),
    .io_check_env_pmp_27_addr        (u_pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask        (u_pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l       (u_pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a       (u_pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_r       (u_pmp_pmp_28_cfg_r),
    .io_check_env_pmp_28_addr        (u_pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask        (u_pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l       (u_pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a       (u_pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_r       (u_pmp_pmp_29_cfg_r),
    .io_check_env_pmp_29_addr        (u_pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask        (u_pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l       (u_pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a       (u_pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_r       (u_pmp_pmp_30_cfg_r),
    .io_check_env_pmp_30_addr        (u_pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask        (u_pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l       (u_pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a       (u_pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_r       (u_pmp_pmp_31_cfg_r),
    .io_check_env_pmp_31_addr        (u_pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask        (u_pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c        (u_pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_atomic   (u_pmp_pma_0_cfg_atomic),
    .io_check_env_pma_0_cfg_a        (u_pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_r        (u_pmp_pma_0_cfg_r),
    .io_check_env_pma_0_addr         (u_pmp_pma_0_addr),
    .io_check_env_pma_0_mask         (u_pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c        (u_pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_atomic   (u_pmp_pma_1_cfg_atomic),
    .io_check_env_pma_1_cfg_a        (u_pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_r        (u_pmp_pma_1_cfg_r),
    .io_check_env_pma_1_addr         (u_pmp_pma_1_addr),
    .io_check_env_pma_1_mask         (u_pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c        (u_pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_atomic   (u_pmp_pma_2_cfg_atomic),
    .io_check_env_pma_2_cfg_a        (u_pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_r        (u_pmp_pma_2_cfg_r),
    .io_check_env_pma_2_addr         (u_pmp_pma_2_addr),
    .io_check_env_pma_2_mask         (u_pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c        (u_pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_atomic   (u_pmp_pma_3_cfg_atomic),
    .io_check_env_pma_3_cfg_a        (u_pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_r        (u_pmp_pma_3_cfg_r),
    .io_check_env_pma_3_addr         (u_pmp_pma_3_addr),
    .io_check_env_pma_3_mask         (u_pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c        (u_pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_atomic   (u_pmp_pma_4_cfg_atomic),
    .io_check_env_pma_4_cfg_a        (u_pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_r        (u_pmp_pma_4_cfg_r),
    .io_check_env_pma_4_addr         (u_pmp_pma_4_addr),
    .io_check_env_pma_4_mask         (u_pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c        (u_pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_atomic   (u_pmp_pma_5_cfg_atomic),
    .io_check_env_pma_5_cfg_a        (u_pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_r        (u_pmp_pma_5_cfg_r),
    .io_check_env_pma_5_addr         (u_pmp_pma_5_addr),
    .io_check_env_pma_5_mask         (u_pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c        (u_pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_atomic   (u_pmp_pma_6_cfg_atomic),
    .io_check_env_pma_6_cfg_a        (u_pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_r        (u_pmp_pma_6_cfg_r),
    .io_check_env_pma_6_addr         (u_pmp_pma_6_addr),
    .io_check_env_pma_6_mask         (u_pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c        (u_pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_atomic   (u_pmp_pma_7_cfg_atomic),
    .io_check_env_pma_7_cfg_a        (u_pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_r        (u_pmp_pma_7_cfg_r),
    .io_check_env_pma_7_addr         (u_pmp_pma_7_addr),
    .io_check_env_pma_7_mask         (u_pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c        (u_pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_atomic   (u_pmp_pma_8_cfg_atomic),
    .io_check_env_pma_8_cfg_a        (u_pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_r        (u_pmp_pma_8_cfg_r),
    .io_check_env_pma_8_addr         (u_pmp_pma_8_addr),
    .io_check_env_pma_8_mask         (u_pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c        (u_pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_atomic   (u_pmp_pma_9_cfg_atomic),
    .io_check_env_pma_9_cfg_a        (u_pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_r        (u_pmp_pma_9_cfg_r),
    .io_check_env_pma_9_addr         (u_pmp_pma_9_addr),
    .io_check_env_pma_9_mask         (u_pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c       (u_pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_atomic  (u_pmp_pma_10_cfg_atomic),
    .io_check_env_pma_10_cfg_a       (u_pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_r       (u_pmp_pma_10_cfg_r),
    .io_check_env_pma_10_addr        (u_pmp_pma_10_addr),
    .io_check_env_pma_10_mask        (u_pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c       (u_pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_atomic  (u_pmp_pma_11_cfg_atomic),
    .io_check_env_pma_11_cfg_a       (u_pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_r       (u_pmp_pma_11_cfg_r),
    .io_check_env_pma_11_addr        (u_pmp_pma_11_addr),
    .io_check_env_pma_11_mask        (u_pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c       (u_pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_atomic  (u_pmp_pma_12_cfg_atomic),
    .io_check_env_pma_12_cfg_a       (u_pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_r       (u_pmp_pma_12_cfg_r),
    .io_check_env_pma_12_addr        (u_pmp_pma_12_addr),
    .io_check_env_pma_12_mask        (u_pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c       (u_pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_atomic  (u_pmp_pma_13_cfg_atomic),
    .io_check_env_pma_13_cfg_a       (u_pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_r       (u_pmp_pma_13_cfg_r),
    .io_check_env_pma_13_addr        (u_pmp_pma_13_addr),
    .io_check_env_pma_13_mask        (u_pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c       (u_pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_atomic  (u_pmp_pma_14_cfg_atomic),
    .io_check_env_pma_14_cfg_a       (u_pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_r       (u_pmp_pma_14_cfg_r),
    .io_check_env_pma_14_addr        (u_pmp_pma_14_addr),
    .io_check_env_pma_14_mask        (u_pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c       (u_pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_atomic  (u_pmp_pma_15_cfg_atomic),
    .io_check_env_pma_15_cfg_a       (u_pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_r       (u_pmp_pma_15_cfg_r),
    .io_check_env_pma_15_addr        (u_pmp_pma_15_addr),
    .io_check_env_pma_15_mask        (u_pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c       (u_pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_atomic  (u_pmp_pma_16_cfg_atomic),
    .io_check_env_pma_16_cfg_a       (u_pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_r       (u_pmp_pma_16_cfg_r),
    .io_check_env_pma_16_addr        (u_pmp_pma_16_addr),
    .io_check_env_pma_16_mask        (u_pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c       (u_pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_atomic  (u_pmp_pma_17_cfg_atomic),
    .io_check_env_pma_17_cfg_a       (u_pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_r       (u_pmp_pma_17_cfg_r),
    .io_check_env_pma_17_addr        (u_pmp_pma_17_addr),
    .io_check_env_pma_17_mask        (u_pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c       (u_pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_atomic  (u_pmp_pma_18_cfg_atomic),
    .io_check_env_pma_18_cfg_a       (u_pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_r       (u_pmp_pma_18_cfg_r),
    .io_check_env_pma_18_addr        (u_pmp_pma_18_addr),
    .io_check_env_pma_18_mask        (u_pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c       (u_pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_atomic  (u_pmp_pma_19_cfg_atomic),
    .io_check_env_pma_19_cfg_a       (u_pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_r       (u_pmp_pma_19_cfg_r),
    .io_check_env_pma_19_addr        (u_pmp_pma_19_addr),
    .io_check_env_pma_19_mask        (u_pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c       (u_pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_atomic  (u_pmp_pma_20_cfg_atomic),
    .io_check_env_pma_20_cfg_a       (u_pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_r       (u_pmp_pma_20_cfg_r),
    .io_check_env_pma_20_addr        (u_pmp_pma_20_addr),
    .io_check_env_pma_20_mask        (u_pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c       (u_pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_atomic  (u_pmp_pma_21_cfg_atomic),
    .io_check_env_pma_21_cfg_a       (u_pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_r       (u_pmp_pma_21_cfg_r),
    .io_check_env_pma_21_addr        (u_pmp_pma_21_addr),
    .io_check_env_pma_21_mask        (u_pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c       (u_pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_atomic  (u_pmp_pma_22_cfg_atomic),
    .io_check_env_pma_22_cfg_a       (u_pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_r       (u_pmp_pma_22_cfg_r),
    .io_check_env_pma_22_addr        (u_pmp_pma_22_addr),
    .io_check_env_pma_22_mask        (u_pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c       (u_pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_atomic  (u_pmp_pma_23_cfg_atomic),
    .io_check_env_pma_23_cfg_a       (u_pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_r       (u_pmp_pma_23_cfg_r),
    .io_check_env_pma_23_addr        (u_pmp_pma_23_addr),
    .io_check_env_pma_23_mask        (u_pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c       (u_pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_atomic  (u_pmp_pma_24_cfg_atomic),
    .io_check_env_pma_24_cfg_a       (u_pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_r       (u_pmp_pma_24_cfg_r),
    .io_check_env_pma_24_addr        (u_pmp_pma_24_addr),
    .io_check_env_pma_24_mask        (u_pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c       (u_pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_atomic  (u_pmp_pma_25_cfg_atomic),
    .io_check_env_pma_25_cfg_a       (u_pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_r       (u_pmp_pma_25_cfg_r),
    .io_check_env_pma_25_addr        (u_pmp_pma_25_addr),
    .io_check_env_pma_25_mask        (u_pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c       (u_pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_atomic  (u_pmp_pma_26_cfg_atomic),
    .io_check_env_pma_26_cfg_a       (u_pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_r       (u_pmp_pma_26_cfg_r),
    .io_check_env_pma_26_addr        (u_pmp_pma_26_addr),
    .io_check_env_pma_26_mask        (u_pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c       (u_pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_atomic  (u_pmp_pma_27_cfg_atomic),
    .io_check_env_pma_27_cfg_a       (u_pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_r       (u_pmp_pma_27_cfg_r),
    .io_check_env_pma_27_addr        (u_pmp_pma_27_addr),
    .io_check_env_pma_27_mask        (u_pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c       (u_pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_atomic  (u_pmp_pma_28_cfg_atomic),
    .io_check_env_pma_28_cfg_a       (u_pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_r       (u_pmp_pma_28_cfg_r),
    .io_check_env_pma_28_addr        (u_pmp_pma_28_addr),
    .io_check_env_pma_28_mask        (u_pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c       (u_pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_atomic  (u_pmp_pma_29_cfg_atomic),
    .io_check_env_pma_29_cfg_a       (u_pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_r       (u_pmp_pma_29_cfg_r),
    .io_check_env_pma_29_addr        (u_pmp_pma_29_addr),
    .io_check_env_pma_29_mask        (u_pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c       (u_pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_atomic  (u_pmp_pma_30_cfg_atomic),
    .io_check_env_pma_30_cfg_a       (u_pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_r       (u_pmp_pma_30_cfg_r),
    .io_check_env_pma_30_addr        (u_pmp_pma_30_addr),
    .io_check_env_pma_30_mask        (u_pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c       (u_pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_atomic  (u_pmp_pma_31_cfg_atomic),
    .io_check_env_pma_31_cfg_a       (u_pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_r       (u_pmp_pma_31_cfg_r),
    .io_check_env_pma_31_addr        (u_pmp_pma_31_addr),
    .io_check_env_pma_31_mask        (u_pmp_pma_31_mask),
    .io_req_bits_addr                (u_ptw_pmp_req_bits_addr),
    .io_resp_ld                      (u_pmp_chk_ptw_resp_ld),
    .io_resp_mmio                    (u_pmp_chk_ptw_resp_mmio),
    .io_resp_atomic                  (/* unused */)
  );

  PMPChecker u_pmp_chk_llptw0 (
    .io_check_env_mode               (2'h1),
    .io_check_env_debug              (u_pmp_chk_llptw0__check_env_debug),
    .io_check_env_pmp_0_cfg_l        (u_pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a        (u_pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_r        (u_pmp_pmp_0_cfg_r),
    .io_check_env_pmp_0_addr         (u_pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask         (u_pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l        (u_pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a        (u_pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_r        (u_pmp_pmp_1_cfg_r),
    .io_check_env_pmp_1_addr         (u_pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask         (u_pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l        (u_pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a        (u_pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_r        (u_pmp_pmp_2_cfg_r),
    .io_check_env_pmp_2_addr         (u_pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask         (u_pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l        (u_pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a        (u_pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_r        (u_pmp_pmp_3_cfg_r),
    .io_check_env_pmp_3_addr         (u_pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask         (u_pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l        (u_pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a        (u_pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_r        (u_pmp_pmp_4_cfg_r),
    .io_check_env_pmp_4_addr         (u_pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask         (u_pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l        (u_pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a        (u_pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_r        (u_pmp_pmp_5_cfg_r),
    .io_check_env_pmp_5_addr         (u_pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask         (u_pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l        (u_pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a        (u_pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_r        (u_pmp_pmp_6_cfg_r),
    .io_check_env_pmp_6_addr         (u_pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask         (u_pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l        (u_pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a        (u_pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_r        (u_pmp_pmp_7_cfg_r),
    .io_check_env_pmp_7_addr         (u_pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask         (u_pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l        (u_pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a        (u_pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_r        (u_pmp_pmp_8_cfg_r),
    .io_check_env_pmp_8_addr         (u_pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask         (u_pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l        (u_pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a        (u_pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_r        (u_pmp_pmp_9_cfg_r),
    .io_check_env_pmp_9_addr         (u_pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask         (u_pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l       (u_pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a       (u_pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_r       (u_pmp_pmp_10_cfg_r),
    .io_check_env_pmp_10_addr        (u_pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask        (u_pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l       (u_pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a       (u_pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_r       (u_pmp_pmp_11_cfg_r),
    .io_check_env_pmp_11_addr        (u_pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask        (u_pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l       (u_pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a       (u_pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_r       (u_pmp_pmp_12_cfg_r),
    .io_check_env_pmp_12_addr        (u_pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask        (u_pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l       (u_pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a       (u_pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_r       (u_pmp_pmp_13_cfg_r),
    .io_check_env_pmp_13_addr        (u_pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask        (u_pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l       (u_pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a       (u_pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_r       (u_pmp_pmp_14_cfg_r),
    .io_check_env_pmp_14_addr        (u_pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask        (u_pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l       (u_pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a       (u_pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_r       (u_pmp_pmp_15_cfg_r),
    .io_check_env_pmp_15_addr        (u_pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask        (u_pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l       (u_pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a       (u_pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_r       (u_pmp_pmp_16_cfg_r),
    .io_check_env_pmp_16_addr        (u_pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask        (u_pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l       (u_pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a       (u_pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_r       (u_pmp_pmp_17_cfg_r),
    .io_check_env_pmp_17_addr        (u_pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask        (u_pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l       (u_pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a       (u_pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_r       (u_pmp_pmp_18_cfg_r),
    .io_check_env_pmp_18_addr        (u_pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask        (u_pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l       (u_pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a       (u_pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_r       (u_pmp_pmp_19_cfg_r),
    .io_check_env_pmp_19_addr        (u_pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask        (u_pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l       (u_pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a       (u_pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_r       (u_pmp_pmp_20_cfg_r),
    .io_check_env_pmp_20_addr        (u_pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask        (u_pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l       (u_pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a       (u_pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_r       (u_pmp_pmp_21_cfg_r),
    .io_check_env_pmp_21_addr        (u_pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask        (u_pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l       (u_pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a       (u_pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_r       (u_pmp_pmp_22_cfg_r),
    .io_check_env_pmp_22_addr        (u_pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask        (u_pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l       (u_pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a       (u_pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_r       (u_pmp_pmp_23_cfg_r),
    .io_check_env_pmp_23_addr        (u_pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask        (u_pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l       (u_pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a       (u_pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_r       (u_pmp_pmp_24_cfg_r),
    .io_check_env_pmp_24_addr        (u_pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask        (u_pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l       (u_pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a       (u_pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_r       (u_pmp_pmp_25_cfg_r),
    .io_check_env_pmp_25_addr        (u_pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask        (u_pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l       (u_pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a       (u_pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_r       (u_pmp_pmp_26_cfg_r),
    .io_check_env_pmp_26_addr        (u_pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask        (u_pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l       (u_pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a       (u_pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_r       (u_pmp_pmp_27_cfg_r),
    .io_check_env_pmp_27_addr        (u_pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask        (u_pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l       (u_pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a       (u_pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_r       (u_pmp_pmp_28_cfg_r),
    .io_check_env_pmp_28_addr        (u_pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask        (u_pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l       (u_pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a       (u_pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_r       (u_pmp_pmp_29_cfg_r),
    .io_check_env_pmp_29_addr        (u_pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask        (u_pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l       (u_pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a       (u_pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_r       (u_pmp_pmp_30_cfg_r),
    .io_check_env_pmp_30_addr        (u_pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask        (u_pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l       (u_pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a       (u_pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_r       (u_pmp_pmp_31_cfg_r),
    .io_check_env_pmp_31_addr        (u_pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask        (u_pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c        (u_pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_atomic   (u_pmp_pma_0_cfg_atomic),
    .io_check_env_pma_0_cfg_a        (u_pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_r        (u_pmp_pma_0_cfg_r),
    .io_check_env_pma_0_addr         (u_pmp_pma_0_addr),
    .io_check_env_pma_0_mask         (u_pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c        (u_pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_atomic   (u_pmp_pma_1_cfg_atomic),
    .io_check_env_pma_1_cfg_a        (u_pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_r        (u_pmp_pma_1_cfg_r),
    .io_check_env_pma_1_addr         (u_pmp_pma_1_addr),
    .io_check_env_pma_1_mask         (u_pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c        (u_pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_atomic   (u_pmp_pma_2_cfg_atomic),
    .io_check_env_pma_2_cfg_a        (u_pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_r        (u_pmp_pma_2_cfg_r),
    .io_check_env_pma_2_addr         (u_pmp_pma_2_addr),
    .io_check_env_pma_2_mask         (u_pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c        (u_pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_atomic   (u_pmp_pma_3_cfg_atomic),
    .io_check_env_pma_3_cfg_a        (u_pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_r        (u_pmp_pma_3_cfg_r),
    .io_check_env_pma_3_addr         (u_pmp_pma_3_addr),
    .io_check_env_pma_3_mask         (u_pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c        (u_pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_atomic   (u_pmp_pma_4_cfg_atomic),
    .io_check_env_pma_4_cfg_a        (u_pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_r        (u_pmp_pma_4_cfg_r),
    .io_check_env_pma_4_addr         (u_pmp_pma_4_addr),
    .io_check_env_pma_4_mask         (u_pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c        (u_pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_atomic   (u_pmp_pma_5_cfg_atomic),
    .io_check_env_pma_5_cfg_a        (u_pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_r        (u_pmp_pma_5_cfg_r),
    .io_check_env_pma_5_addr         (u_pmp_pma_5_addr),
    .io_check_env_pma_5_mask         (u_pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c        (u_pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_atomic   (u_pmp_pma_6_cfg_atomic),
    .io_check_env_pma_6_cfg_a        (u_pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_r        (u_pmp_pma_6_cfg_r),
    .io_check_env_pma_6_addr         (u_pmp_pma_6_addr),
    .io_check_env_pma_6_mask         (u_pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c        (u_pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_atomic   (u_pmp_pma_7_cfg_atomic),
    .io_check_env_pma_7_cfg_a        (u_pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_r        (u_pmp_pma_7_cfg_r),
    .io_check_env_pma_7_addr         (u_pmp_pma_7_addr),
    .io_check_env_pma_7_mask         (u_pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c        (u_pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_atomic   (u_pmp_pma_8_cfg_atomic),
    .io_check_env_pma_8_cfg_a        (u_pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_r        (u_pmp_pma_8_cfg_r),
    .io_check_env_pma_8_addr         (u_pmp_pma_8_addr),
    .io_check_env_pma_8_mask         (u_pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c        (u_pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_atomic   (u_pmp_pma_9_cfg_atomic),
    .io_check_env_pma_9_cfg_a        (u_pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_r        (u_pmp_pma_9_cfg_r),
    .io_check_env_pma_9_addr         (u_pmp_pma_9_addr),
    .io_check_env_pma_9_mask         (u_pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c       (u_pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_atomic  (u_pmp_pma_10_cfg_atomic),
    .io_check_env_pma_10_cfg_a       (u_pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_r       (u_pmp_pma_10_cfg_r),
    .io_check_env_pma_10_addr        (u_pmp_pma_10_addr),
    .io_check_env_pma_10_mask        (u_pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c       (u_pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_atomic  (u_pmp_pma_11_cfg_atomic),
    .io_check_env_pma_11_cfg_a       (u_pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_r       (u_pmp_pma_11_cfg_r),
    .io_check_env_pma_11_addr        (u_pmp_pma_11_addr),
    .io_check_env_pma_11_mask        (u_pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c       (u_pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_atomic  (u_pmp_pma_12_cfg_atomic),
    .io_check_env_pma_12_cfg_a       (u_pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_r       (u_pmp_pma_12_cfg_r),
    .io_check_env_pma_12_addr        (u_pmp_pma_12_addr),
    .io_check_env_pma_12_mask        (u_pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c       (u_pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_atomic  (u_pmp_pma_13_cfg_atomic),
    .io_check_env_pma_13_cfg_a       (u_pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_r       (u_pmp_pma_13_cfg_r),
    .io_check_env_pma_13_addr        (u_pmp_pma_13_addr),
    .io_check_env_pma_13_mask        (u_pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c       (u_pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_atomic  (u_pmp_pma_14_cfg_atomic),
    .io_check_env_pma_14_cfg_a       (u_pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_r       (u_pmp_pma_14_cfg_r),
    .io_check_env_pma_14_addr        (u_pmp_pma_14_addr),
    .io_check_env_pma_14_mask        (u_pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c       (u_pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_atomic  (u_pmp_pma_15_cfg_atomic),
    .io_check_env_pma_15_cfg_a       (u_pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_r       (u_pmp_pma_15_cfg_r),
    .io_check_env_pma_15_addr        (u_pmp_pma_15_addr),
    .io_check_env_pma_15_mask        (u_pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c       (u_pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_atomic  (u_pmp_pma_16_cfg_atomic),
    .io_check_env_pma_16_cfg_a       (u_pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_r       (u_pmp_pma_16_cfg_r),
    .io_check_env_pma_16_addr        (u_pmp_pma_16_addr),
    .io_check_env_pma_16_mask        (u_pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c       (u_pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_atomic  (u_pmp_pma_17_cfg_atomic),
    .io_check_env_pma_17_cfg_a       (u_pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_r       (u_pmp_pma_17_cfg_r),
    .io_check_env_pma_17_addr        (u_pmp_pma_17_addr),
    .io_check_env_pma_17_mask        (u_pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c       (u_pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_atomic  (u_pmp_pma_18_cfg_atomic),
    .io_check_env_pma_18_cfg_a       (u_pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_r       (u_pmp_pma_18_cfg_r),
    .io_check_env_pma_18_addr        (u_pmp_pma_18_addr),
    .io_check_env_pma_18_mask        (u_pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c       (u_pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_atomic  (u_pmp_pma_19_cfg_atomic),
    .io_check_env_pma_19_cfg_a       (u_pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_r       (u_pmp_pma_19_cfg_r),
    .io_check_env_pma_19_addr        (u_pmp_pma_19_addr),
    .io_check_env_pma_19_mask        (u_pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c       (u_pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_atomic  (u_pmp_pma_20_cfg_atomic),
    .io_check_env_pma_20_cfg_a       (u_pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_r       (u_pmp_pma_20_cfg_r),
    .io_check_env_pma_20_addr        (u_pmp_pma_20_addr),
    .io_check_env_pma_20_mask        (u_pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c       (u_pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_atomic  (u_pmp_pma_21_cfg_atomic),
    .io_check_env_pma_21_cfg_a       (u_pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_r       (u_pmp_pma_21_cfg_r),
    .io_check_env_pma_21_addr        (u_pmp_pma_21_addr),
    .io_check_env_pma_21_mask        (u_pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c       (u_pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_atomic  (u_pmp_pma_22_cfg_atomic),
    .io_check_env_pma_22_cfg_a       (u_pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_r       (u_pmp_pma_22_cfg_r),
    .io_check_env_pma_22_addr        (u_pmp_pma_22_addr),
    .io_check_env_pma_22_mask        (u_pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c       (u_pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_atomic  (u_pmp_pma_23_cfg_atomic),
    .io_check_env_pma_23_cfg_a       (u_pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_r       (u_pmp_pma_23_cfg_r),
    .io_check_env_pma_23_addr        (u_pmp_pma_23_addr),
    .io_check_env_pma_23_mask        (u_pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c       (u_pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_atomic  (u_pmp_pma_24_cfg_atomic),
    .io_check_env_pma_24_cfg_a       (u_pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_r       (u_pmp_pma_24_cfg_r),
    .io_check_env_pma_24_addr        (u_pmp_pma_24_addr),
    .io_check_env_pma_24_mask        (u_pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c       (u_pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_atomic  (u_pmp_pma_25_cfg_atomic),
    .io_check_env_pma_25_cfg_a       (u_pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_r       (u_pmp_pma_25_cfg_r),
    .io_check_env_pma_25_addr        (u_pmp_pma_25_addr),
    .io_check_env_pma_25_mask        (u_pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c       (u_pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_atomic  (u_pmp_pma_26_cfg_atomic),
    .io_check_env_pma_26_cfg_a       (u_pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_r       (u_pmp_pma_26_cfg_r),
    .io_check_env_pma_26_addr        (u_pmp_pma_26_addr),
    .io_check_env_pma_26_mask        (u_pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c       (u_pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_atomic  (u_pmp_pma_27_cfg_atomic),
    .io_check_env_pma_27_cfg_a       (u_pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_r       (u_pmp_pma_27_cfg_r),
    .io_check_env_pma_27_addr        (u_pmp_pma_27_addr),
    .io_check_env_pma_27_mask        (u_pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c       (u_pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_atomic  (u_pmp_pma_28_cfg_atomic),
    .io_check_env_pma_28_cfg_a       (u_pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_r       (u_pmp_pma_28_cfg_r),
    .io_check_env_pma_28_addr        (u_pmp_pma_28_addr),
    .io_check_env_pma_28_mask        (u_pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c       (u_pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_atomic  (u_pmp_pma_29_cfg_atomic),
    .io_check_env_pma_29_cfg_a       (u_pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_r       (u_pmp_pma_29_cfg_r),
    .io_check_env_pma_29_addr        (u_pmp_pma_29_addr),
    .io_check_env_pma_29_mask        (u_pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c       (u_pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_atomic  (u_pmp_pma_30_cfg_atomic),
    .io_check_env_pma_30_cfg_a       (u_pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_r       (u_pmp_pma_30_cfg_r),
    .io_check_env_pma_30_addr        (u_pmp_pma_30_addr),
    .io_check_env_pma_30_mask        (u_pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c       (u_pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_atomic  (u_pmp_pma_31_cfg_atomic),
    .io_check_env_pma_31_cfg_a       (u_pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_r       (u_pmp_pma_31_cfg_r),
    .io_check_env_pma_31_addr        (u_pmp_pma_31_addr),
    .io_check_env_pma_31_mask        (u_pmp_pma_31_mask),
    .io_req_bits_addr                (u_llptw_pmp_0_req_bits_addr),
    .io_resp_ld                      (u_pmp_chk_llptw0_resp_ld),
    .io_resp_mmio                    (u_pmp_chk_llptw0_resp_mmio),
    .io_resp_atomic                  (/* unused */)
  );

  PMPChecker u_pmp_chk_llptw1 (
    .io_check_env_mode               (2'h1),
    .io_check_env_debug              (u_pmp_chk_llptw1__check_env_debug),
    .io_check_env_pmp_0_cfg_l        (u_pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a        (u_pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_r        (u_pmp_pmp_0_cfg_r),
    .io_check_env_pmp_0_addr         (u_pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask         (u_pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l        (u_pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a        (u_pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_r        (u_pmp_pmp_1_cfg_r),
    .io_check_env_pmp_1_addr         (u_pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask         (u_pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l        (u_pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a        (u_pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_r        (u_pmp_pmp_2_cfg_r),
    .io_check_env_pmp_2_addr         (u_pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask         (u_pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l        (u_pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a        (u_pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_r        (u_pmp_pmp_3_cfg_r),
    .io_check_env_pmp_3_addr         (u_pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask         (u_pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l        (u_pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a        (u_pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_r        (u_pmp_pmp_4_cfg_r),
    .io_check_env_pmp_4_addr         (u_pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask         (u_pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l        (u_pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a        (u_pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_r        (u_pmp_pmp_5_cfg_r),
    .io_check_env_pmp_5_addr         (u_pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask         (u_pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l        (u_pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a        (u_pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_r        (u_pmp_pmp_6_cfg_r),
    .io_check_env_pmp_6_addr         (u_pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask         (u_pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l        (u_pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a        (u_pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_r        (u_pmp_pmp_7_cfg_r),
    .io_check_env_pmp_7_addr         (u_pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask         (u_pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l        (u_pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a        (u_pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_r        (u_pmp_pmp_8_cfg_r),
    .io_check_env_pmp_8_addr         (u_pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask         (u_pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l        (u_pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a        (u_pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_r        (u_pmp_pmp_9_cfg_r),
    .io_check_env_pmp_9_addr         (u_pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask         (u_pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l       (u_pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a       (u_pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_r       (u_pmp_pmp_10_cfg_r),
    .io_check_env_pmp_10_addr        (u_pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask        (u_pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l       (u_pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a       (u_pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_r       (u_pmp_pmp_11_cfg_r),
    .io_check_env_pmp_11_addr        (u_pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask        (u_pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l       (u_pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a       (u_pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_r       (u_pmp_pmp_12_cfg_r),
    .io_check_env_pmp_12_addr        (u_pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask        (u_pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l       (u_pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a       (u_pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_r       (u_pmp_pmp_13_cfg_r),
    .io_check_env_pmp_13_addr        (u_pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask        (u_pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l       (u_pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a       (u_pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_r       (u_pmp_pmp_14_cfg_r),
    .io_check_env_pmp_14_addr        (u_pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask        (u_pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l       (u_pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a       (u_pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_r       (u_pmp_pmp_15_cfg_r),
    .io_check_env_pmp_15_addr        (u_pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask        (u_pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l       (u_pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a       (u_pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_r       (u_pmp_pmp_16_cfg_r),
    .io_check_env_pmp_16_addr        (u_pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask        (u_pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l       (u_pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a       (u_pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_r       (u_pmp_pmp_17_cfg_r),
    .io_check_env_pmp_17_addr        (u_pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask        (u_pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l       (u_pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a       (u_pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_r       (u_pmp_pmp_18_cfg_r),
    .io_check_env_pmp_18_addr        (u_pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask        (u_pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l       (u_pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a       (u_pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_r       (u_pmp_pmp_19_cfg_r),
    .io_check_env_pmp_19_addr        (u_pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask        (u_pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l       (u_pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a       (u_pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_r       (u_pmp_pmp_20_cfg_r),
    .io_check_env_pmp_20_addr        (u_pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask        (u_pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l       (u_pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a       (u_pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_r       (u_pmp_pmp_21_cfg_r),
    .io_check_env_pmp_21_addr        (u_pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask        (u_pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l       (u_pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a       (u_pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_r       (u_pmp_pmp_22_cfg_r),
    .io_check_env_pmp_22_addr        (u_pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask        (u_pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l       (u_pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a       (u_pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_r       (u_pmp_pmp_23_cfg_r),
    .io_check_env_pmp_23_addr        (u_pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask        (u_pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l       (u_pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a       (u_pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_r       (u_pmp_pmp_24_cfg_r),
    .io_check_env_pmp_24_addr        (u_pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask        (u_pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l       (u_pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a       (u_pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_r       (u_pmp_pmp_25_cfg_r),
    .io_check_env_pmp_25_addr        (u_pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask        (u_pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l       (u_pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a       (u_pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_r       (u_pmp_pmp_26_cfg_r),
    .io_check_env_pmp_26_addr        (u_pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask        (u_pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l       (u_pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a       (u_pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_r       (u_pmp_pmp_27_cfg_r),
    .io_check_env_pmp_27_addr        (u_pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask        (u_pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l       (u_pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a       (u_pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_r       (u_pmp_pmp_28_cfg_r),
    .io_check_env_pmp_28_addr        (u_pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask        (u_pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l       (u_pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a       (u_pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_r       (u_pmp_pmp_29_cfg_r),
    .io_check_env_pmp_29_addr        (u_pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask        (u_pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l       (u_pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a       (u_pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_r       (u_pmp_pmp_30_cfg_r),
    .io_check_env_pmp_30_addr        (u_pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask        (u_pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l       (u_pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a       (u_pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_r       (u_pmp_pmp_31_cfg_r),
    .io_check_env_pmp_31_addr        (u_pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask        (u_pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c        (u_pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_atomic   (u_pmp_pma_0_cfg_atomic),
    .io_check_env_pma_0_cfg_a        (u_pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_r        (u_pmp_pma_0_cfg_r),
    .io_check_env_pma_0_addr         (u_pmp_pma_0_addr),
    .io_check_env_pma_0_mask         (u_pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c        (u_pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_atomic   (u_pmp_pma_1_cfg_atomic),
    .io_check_env_pma_1_cfg_a        (u_pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_r        (u_pmp_pma_1_cfg_r),
    .io_check_env_pma_1_addr         (u_pmp_pma_1_addr),
    .io_check_env_pma_1_mask         (u_pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c        (u_pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_atomic   (u_pmp_pma_2_cfg_atomic),
    .io_check_env_pma_2_cfg_a        (u_pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_r        (u_pmp_pma_2_cfg_r),
    .io_check_env_pma_2_addr         (u_pmp_pma_2_addr),
    .io_check_env_pma_2_mask         (u_pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c        (u_pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_atomic   (u_pmp_pma_3_cfg_atomic),
    .io_check_env_pma_3_cfg_a        (u_pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_r        (u_pmp_pma_3_cfg_r),
    .io_check_env_pma_3_addr         (u_pmp_pma_3_addr),
    .io_check_env_pma_3_mask         (u_pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c        (u_pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_atomic   (u_pmp_pma_4_cfg_atomic),
    .io_check_env_pma_4_cfg_a        (u_pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_r        (u_pmp_pma_4_cfg_r),
    .io_check_env_pma_4_addr         (u_pmp_pma_4_addr),
    .io_check_env_pma_4_mask         (u_pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c        (u_pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_atomic   (u_pmp_pma_5_cfg_atomic),
    .io_check_env_pma_5_cfg_a        (u_pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_r        (u_pmp_pma_5_cfg_r),
    .io_check_env_pma_5_addr         (u_pmp_pma_5_addr),
    .io_check_env_pma_5_mask         (u_pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c        (u_pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_atomic   (u_pmp_pma_6_cfg_atomic),
    .io_check_env_pma_6_cfg_a        (u_pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_r        (u_pmp_pma_6_cfg_r),
    .io_check_env_pma_6_addr         (u_pmp_pma_6_addr),
    .io_check_env_pma_6_mask         (u_pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c        (u_pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_atomic   (u_pmp_pma_7_cfg_atomic),
    .io_check_env_pma_7_cfg_a        (u_pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_r        (u_pmp_pma_7_cfg_r),
    .io_check_env_pma_7_addr         (u_pmp_pma_7_addr),
    .io_check_env_pma_7_mask         (u_pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c        (u_pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_atomic   (u_pmp_pma_8_cfg_atomic),
    .io_check_env_pma_8_cfg_a        (u_pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_r        (u_pmp_pma_8_cfg_r),
    .io_check_env_pma_8_addr         (u_pmp_pma_8_addr),
    .io_check_env_pma_8_mask         (u_pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c        (u_pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_atomic   (u_pmp_pma_9_cfg_atomic),
    .io_check_env_pma_9_cfg_a        (u_pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_r        (u_pmp_pma_9_cfg_r),
    .io_check_env_pma_9_addr         (u_pmp_pma_9_addr),
    .io_check_env_pma_9_mask         (u_pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c       (u_pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_atomic  (u_pmp_pma_10_cfg_atomic),
    .io_check_env_pma_10_cfg_a       (u_pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_r       (u_pmp_pma_10_cfg_r),
    .io_check_env_pma_10_addr        (u_pmp_pma_10_addr),
    .io_check_env_pma_10_mask        (u_pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c       (u_pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_atomic  (u_pmp_pma_11_cfg_atomic),
    .io_check_env_pma_11_cfg_a       (u_pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_r       (u_pmp_pma_11_cfg_r),
    .io_check_env_pma_11_addr        (u_pmp_pma_11_addr),
    .io_check_env_pma_11_mask        (u_pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c       (u_pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_atomic  (u_pmp_pma_12_cfg_atomic),
    .io_check_env_pma_12_cfg_a       (u_pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_r       (u_pmp_pma_12_cfg_r),
    .io_check_env_pma_12_addr        (u_pmp_pma_12_addr),
    .io_check_env_pma_12_mask        (u_pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c       (u_pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_atomic  (u_pmp_pma_13_cfg_atomic),
    .io_check_env_pma_13_cfg_a       (u_pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_r       (u_pmp_pma_13_cfg_r),
    .io_check_env_pma_13_addr        (u_pmp_pma_13_addr),
    .io_check_env_pma_13_mask        (u_pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c       (u_pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_atomic  (u_pmp_pma_14_cfg_atomic),
    .io_check_env_pma_14_cfg_a       (u_pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_r       (u_pmp_pma_14_cfg_r),
    .io_check_env_pma_14_addr        (u_pmp_pma_14_addr),
    .io_check_env_pma_14_mask        (u_pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c       (u_pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_atomic  (u_pmp_pma_15_cfg_atomic),
    .io_check_env_pma_15_cfg_a       (u_pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_r       (u_pmp_pma_15_cfg_r),
    .io_check_env_pma_15_addr        (u_pmp_pma_15_addr),
    .io_check_env_pma_15_mask        (u_pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c       (u_pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_atomic  (u_pmp_pma_16_cfg_atomic),
    .io_check_env_pma_16_cfg_a       (u_pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_r       (u_pmp_pma_16_cfg_r),
    .io_check_env_pma_16_addr        (u_pmp_pma_16_addr),
    .io_check_env_pma_16_mask        (u_pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c       (u_pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_atomic  (u_pmp_pma_17_cfg_atomic),
    .io_check_env_pma_17_cfg_a       (u_pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_r       (u_pmp_pma_17_cfg_r),
    .io_check_env_pma_17_addr        (u_pmp_pma_17_addr),
    .io_check_env_pma_17_mask        (u_pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c       (u_pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_atomic  (u_pmp_pma_18_cfg_atomic),
    .io_check_env_pma_18_cfg_a       (u_pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_r       (u_pmp_pma_18_cfg_r),
    .io_check_env_pma_18_addr        (u_pmp_pma_18_addr),
    .io_check_env_pma_18_mask        (u_pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c       (u_pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_atomic  (u_pmp_pma_19_cfg_atomic),
    .io_check_env_pma_19_cfg_a       (u_pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_r       (u_pmp_pma_19_cfg_r),
    .io_check_env_pma_19_addr        (u_pmp_pma_19_addr),
    .io_check_env_pma_19_mask        (u_pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c       (u_pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_atomic  (u_pmp_pma_20_cfg_atomic),
    .io_check_env_pma_20_cfg_a       (u_pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_r       (u_pmp_pma_20_cfg_r),
    .io_check_env_pma_20_addr        (u_pmp_pma_20_addr),
    .io_check_env_pma_20_mask        (u_pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c       (u_pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_atomic  (u_pmp_pma_21_cfg_atomic),
    .io_check_env_pma_21_cfg_a       (u_pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_r       (u_pmp_pma_21_cfg_r),
    .io_check_env_pma_21_addr        (u_pmp_pma_21_addr),
    .io_check_env_pma_21_mask        (u_pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c       (u_pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_atomic  (u_pmp_pma_22_cfg_atomic),
    .io_check_env_pma_22_cfg_a       (u_pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_r       (u_pmp_pma_22_cfg_r),
    .io_check_env_pma_22_addr        (u_pmp_pma_22_addr),
    .io_check_env_pma_22_mask        (u_pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c       (u_pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_atomic  (u_pmp_pma_23_cfg_atomic),
    .io_check_env_pma_23_cfg_a       (u_pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_r       (u_pmp_pma_23_cfg_r),
    .io_check_env_pma_23_addr        (u_pmp_pma_23_addr),
    .io_check_env_pma_23_mask        (u_pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c       (u_pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_atomic  (u_pmp_pma_24_cfg_atomic),
    .io_check_env_pma_24_cfg_a       (u_pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_r       (u_pmp_pma_24_cfg_r),
    .io_check_env_pma_24_addr        (u_pmp_pma_24_addr),
    .io_check_env_pma_24_mask        (u_pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c       (u_pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_atomic  (u_pmp_pma_25_cfg_atomic),
    .io_check_env_pma_25_cfg_a       (u_pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_r       (u_pmp_pma_25_cfg_r),
    .io_check_env_pma_25_addr        (u_pmp_pma_25_addr),
    .io_check_env_pma_25_mask        (u_pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c       (u_pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_atomic  (u_pmp_pma_26_cfg_atomic),
    .io_check_env_pma_26_cfg_a       (u_pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_r       (u_pmp_pma_26_cfg_r),
    .io_check_env_pma_26_addr        (u_pmp_pma_26_addr),
    .io_check_env_pma_26_mask        (u_pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c       (u_pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_atomic  (u_pmp_pma_27_cfg_atomic),
    .io_check_env_pma_27_cfg_a       (u_pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_r       (u_pmp_pma_27_cfg_r),
    .io_check_env_pma_27_addr        (u_pmp_pma_27_addr),
    .io_check_env_pma_27_mask        (u_pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c       (u_pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_atomic  (u_pmp_pma_28_cfg_atomic),
    .io_check_env_pma_28_cfg_a       (u_pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_r       (u_pmp_pma_28_cfg_r),
    .io_check_env_pma_28_addr        (u_pmp_pma_28_addr),
    .io_check_env_pma_28_mask        (u_pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c       (u_pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_atomic  (u_pmp_pma_29_cfg_atomic),
    .io_check_env_pma_29_cfg_a       (u_pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_r       (u_pmp_pma_29_cfg_r),
    .io_check_env_pma_29_addr        (u_pmp_pma_29_addr),
    .io_check_env_pma_29_mask        (u_pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c       (u_pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_atomic  (u_pmp_pma_30_cfg_atomic),
    .io_check_env_pma_30_cfg_a       (u_pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_r       (u_pmp_pma_30_cfg_r),
    .io_check_env_pma_30_addr        (u_pmp_pma_30_addr),
    .io_check_env_pma_30_mask        (u_pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c       (u_pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_atomic  (u_pmp_pma_31_cfg_atomic),
    .io_check_env_pma_31_cfg_a       (u_pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_r       (u_pmp_pma_31_cfg_r),
    .io_check_env_pma_31_addr        (u_pmp_pma_31_addr),
    .io_check_env_pma_31_mask        (u_pmp_pma_31_mask),
    .io_req_bits_addr                (u_llptw_pmp_1_req_bits_addr),
    .io_resp_ld                      (u_pmp_chk_llptw1_resp_ld),
    .io_resp_mmio                    (u_pmp_chk_llptw1_resp_mmio),
    .io_resp_atomic                  (/* unused */)
  );

  PMPChecker u_pmp_chk_hptw (
    .io_check_env_mode               (2'h1),
    .io_check_env_debug              (u_pmp_chk_hptw__check_env_debug),
    .io_check_env_pmp_0_cfg_l        (u_pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a        (u_pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_r        (u_pmp_pmp_0_cfg_r),
    .io_check_env_pmp_0_addr         (u_pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask         (u_pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l        (u_pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a        (u_pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_r        (u_pmp_pmp_1_cfg_r),
    .io_check_env_pmp_1_addr         (u_pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask         (u_pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l        (u_pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a        (u_pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_r        (u_pmp_pmp_2_cfg_r),
    .io_check_env_pmp_2_addr         (u_pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask         (u_pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l        (u_pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a        (u_pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_r        (u_pmp_pmp_3_cfg_r),
    .io_check_env_pmp_3_addr         (u_pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask         (u_pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l        (u_pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a        (u_pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_r        (u_pmp_pmp_4_cfg_r),
    .io_check_env_pmp_4_addr         (u_pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask         (u_pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l        (u_pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a        (u_pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_r        (u_pmp_pmp_5_cfg_r),
    .io_check_env_pmp_5_addr         (u_pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask         (u_pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l        (u_pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a        (u_pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_r        (u_pmp_pmp_6_cfg_r),
    .io_check_env_pmp_6_addr         (u_pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask         (u_pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l        (u_pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a        (u_pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_r        (u_pmp_pmp_7_cfg_r),
    .io_check_env_pmp_7_addr         (u_pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask         (u_pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l        (u_pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a        (u_pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_r        (u_pmp_pmp_8_cfg_r),
    .io_check_env_pmp_8_addr         (u_pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask         (u_pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l        (u_pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a        (u_pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_r        (u_pmp_pmp_9_cfg_r),
    .io_check_env_pmp_9_addr         (u_pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask         (u_pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l       (u_pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a       (u_pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_r       (u_pmp_pmp_10_cfg_r),
    .io_check_env_pmp_10_addr        (u_pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask        (u_pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l       (u_pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a       (u_pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_r       (u_pmp_pmp_11_cfg_r),
    .io_check_env_pmp_11_addr        (u_pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask        (u_pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l       (u_pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a       (u_pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_r       (u_pmp_pmp_12_cfg_r),
    .io_check_env_pmp_12_addr        (u_pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask        (u_pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l       (u_pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a       (u_pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_r       (u_pmp_pmp_13_cfg_r),
    .io_check_env_pmp_13_addr        (u_pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask        (u_pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l       (u_pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a       (u_pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_r       (u_pmp_pmp_14_cfg_r),
    .io_check_env_pmp_14_addr        (u_pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask        (u_pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l       (u_pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a       (u_pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_r       (u_pmp_pmp_15_cfg_r),
    .io_check_env_pmp_15_addr        (u_pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask        (u_pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l       (u_pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a       (u_pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_r       (u_pmp_pmp_16_cfg_r),
    .io_check_env_pmp_16_addr        (u_pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask        (u_pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l       (u_pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a       (u_pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_r       (u_pmp_pmp_17_cfg_r),
    .io_check_env_pmp_17_addr        (u_pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask        (u_pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l       (u_pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a       (u_pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_r       (u_pmp_pmp_18_cfg_r),
    .io_check_env_pmp_18_addr        (u_pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask        (u_pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l       (u_pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a       (u_pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_r       (u_pmp_pmp_19_cfg_r),
    .io_check_env_pmp_19_addr        (u_pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask        (u_pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l       (u_pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a       (u_pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_r       (u_pmp_pmp_20_cfg_r),
    .io_check_env_pmp_20_addr        (u_pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask        (u_pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l       (u_pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a       (u_pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_r       (u_pmp_pmp_21_cfg_r),
    .io_check_env_pmp_21_addr        (u_pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask        (u_pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l       (u_pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a       (u_pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_r       (u_pmp_pmp_22_cfg_r),
    .io_check_env_pmp_22_addr        (u_pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask        (u_pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l       (u_pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a       (u_pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_r       (u_pmp_pmp_23_cfg_r),
    .io_check_env_pmp_23_addr        (u_pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask        (u_pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l       (u_pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a       (u_pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_r       (u_pmp_pmp_24_cfg_r),
    .io_check_env_pmp_24_addr        (u_pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask        (u_pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l       (u_pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a       (u_pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_r       (u_pmp_pmp_25_cfg_r),
    .io_check_env_pmp_25_addr        (u_pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask        (u_pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l       (u_pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a       (u_pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_r       (u_pmp_pmp_26_cfg_r),
    .io_check_env_pmp_26_addr        (u_pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask        (u_pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l       (u_pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a       (u_pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_r       (u_pmp_pmp_27_cfg_r),
    .io_check_env_pmp_27_addr        (u_pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask        (u_pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l       (u_pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a       (u_pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_r       (u_pmp_pmp_28_cfg_r),
    .io_check_env_pmp_28_addr        (u_pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask        (u_pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l       (u_pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a       (u_pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_r       (u_pmp_pmp_29_cfg_r),
    .io_check_env_pmp_29_addr        (u_pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask        (u_pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l       (u_pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a       (u_pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_r       (u_pmp_pmp_30_cfg_r),
    .io_check_env_pmp_30_addr        (u_pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask        (u_pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l       (u_pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a       (u_pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_r       (u_pmp_pmp_31_cfg_r),
    .io_check_env_pmp_31_addr        (u_pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask        (u_pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c        (u_pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_atomic   (u_pmp_pma_0_cfg_atomic),
    .io_check_env_pma_0_cfg_a        (u_pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_r        (u_pmp_pma_0_cfg_r),
    .io_check_env_pma_0_addr         (u_pmp_pma_0_addr),
    .io_check_env_pma_0_mask         (u_pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c        (u_pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_atomic   (u_pmp_pma_1_cfg_atomic),
    .io_check_env_pma_1_cfg_a        (u_pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_r        (u_pmp_pma_1_cfg_r),
    .io_check_env_pma_1_addr         (u_pmp_pma_1_addr),
    .io_check_env_pma_1_mask         (u_pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c        (u_pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_atomic   (u_pmp_pma_2_cfg_atomic),
    .io_check_env_pma_2_cfg_a        (u_pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_r        (u_pmp_pma_2_cfg_r),
    .io_check_env_pma_2_addr         (u_pmp_pma_2_addr),
    .io_check_env_pma_2_mask         (u_pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c        (u_pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_atomic   (u_pmp_pma_3_cfg_atomic),
    .io_check_env_pma_3_cfg_a        (u_pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_r        (u_pmp_pma_3_cfg_r),
    .io_check_env_pma_3_addr         (u_pmp_pma_3_addr),
    .io_check_env_pma_3_mask         (u_pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c        (u_pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_atomic   (u_pmp_pma_4_cfg_atomic),
    .io_check_env_pma_4_cfg_a        (u_pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_r        (u_pmp_pma_4_cfg_r),
    .io_check_env_pma_4_addr         (u_pmp_pma_4_addr),
    .io_check_env_pma_4_mask         (u_pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c        (u_pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_atomic   (u_pmp_pma_5_cfg_atomic),
    .io_check_env_pma_5_cfg_a        (u_pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_r        (u_pmp_pma_5_cfg_r),
    .io_check_env_pma_5_addr         (u_pmp_pma_5_addr),
    .io_check_env_pma_5_mask         (u_pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c        (u_pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_atomic   (u_pmp_pma_6_cfg_atomic),
    .io_check_env_pma_6_cfg_a        (u_pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_r        (u_pmp_pma_6_cfg_r),
    .io_check_env_pma_6_addr         (u_pmp_pma_6_addr),
    .io_check_env_pma_6_mask         (u_pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c        (u_pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_atomic   (u_pmp_pma_7_cfg_atomic),
    .io_check_env_pma_7_cfg_a        (u_pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_r        (u_pmp_pma_7_cfg_r),
    .io_check_env_pma_7_addr         (u_pmp_pma_7_addr),
    .io_check_env_pma_7_mask         (u_pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c        (u_pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_atomic   (u_pmp_pma_8_cfg_atomic),
    .io_check_env_pma_8_cfg_a        (u_pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_r        (u_pmp_pma_8_cfg_r),
    .io_check_env_pma_8_addr         (u_pmp_pma_8_addr),
    .io_check_env_pma_8_mask         (u_pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c        (u_pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_atomic   (u_pmp_pma_9_cfg_atomic),
    .io_check_env_pma_9_cfg_a        (u_pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_r        (u_pmp_pma_9_cfg_r),
    .io_check_env_pma_9_addr         (u_pmp_pma_9_addr),
    .io_check_env_pma_9_mask         (u_pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c       (u_pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_atomic  (u_pmp_pma_10_cfg_atomic),
    .io_check_env_pma_10_cfg_a       (u_pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_r       (u_pmp_pma_10_cfg_r),
    .io_check_env_pma_10_addr        (u_pmp_pma_10_addr),
    .io_check_env_pma_10_mask        (u_pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c       (u_pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_atomic  (u_pmp_pma_11_cfg_atomic),
    .io_check_env_pma_11_cfg_a       (u_pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_r       (u_pmp_pma_11_cfg_r),
    .io_check_env_pma_11_addr        (u_pmp_pma_11_addr),
    .io_check_env_pma_11_mask        (u_pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c       (u_pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_atomic  (u_pmp_pma_12_cfg_atomic),
    .io_check_env_pma_12_cfg_a       (u_pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_r       (u_pmp_pma_12_cfg_r),
    .io_check_env_pma_12_addr        (u_pmp_pma_12_addr),
    .io_check_env_pma_12_mask        (u_pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c       (u_pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_atomic  (u_pmp_pma_13_cfg_atomic),
    .io_check_env_pma_13_cfg_a       (u_pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_r       (u_pmp_pma_13_cfg_r),
    .io_check_env_pma_13_addr        (u_pmp_pma_13_addr),
    .io_check_env_pma_13_mask        (u_pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c       (u_pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_atomic  (u_pmp_pma_14_cfg_atomic),
    .io_check_env_pma_14_cfg_a       (u_pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_r       (u_pmp_pma_14_cfg_r),
    .io_check_env_pma_14_addr        (u_pmp_pma_14_addr),
    .io_check_env_pma_14_mask        (u_pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c       (u_pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_atomic  (u_pmp_pma_15_cfg_atomic),
    .io_check_env_pma_15_cfg_a       (u_pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_r       (u_pmp_pma_15_cfg_r),
    .io_check_env_pma_15_addr        (u_pmp_pma_15_addr),
    .io_check_env_pma_15_mask        (u_pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c       (u_pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_atomic  (u_pmp_pma_16_cfg_atomic),
    .io_check_env_pma_16_cfg_a       (u_pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_r       (u_pmp_pma_16_cfg_r),
    .io_check_env_pma_16_addr        (u_pmp_pma_16_addr),
    .io_check_env_pma_16_mask        (u_pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c       (u_pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_atomic  (u_pmp_pma_17_cfg_atomic),
    .io_check_env_pma_17_cfg_a       (u_pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_r       (u_pmp_pma_17_cfg_r),
    .io_check_env_pma_17_addr        (u_pmp_pma_17_addr),
    .io_check_env_pma_17_mask        (u_pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c       (u_pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_atomic  (u_pmp_pma_18_cfg_atomic),
    .io_check_env_pma_18_cfg_a       (u_pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_r       (u_pmp_pma_18_cfg_r),
    .io_check_env_pma_18_addr        (u_pmp_pma_18_addr),
    .io_check_env_pma_18_mask        (u_pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c       (u_pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_atomic  (u_pmp_pma_19_cfg_atomic),
    .io_check_env_pma_19_cfg_a       (u_pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_r       (u_pmp_pma_19_cfg_r),
    .io_check_env_pma_19_addr        (u_pmp_pma_19_addr),
    .io_check_env_pma_19_mask        (u_pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c       (u_pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_atomic  (u_pmp_pma_20_cfg_atomic),
    .io_check_env_pma_20_cfg_a       (u_pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_r       (u_pmp_pma_20_cfg_r),
    .io_check_env_pma_20_addr        (u_pmp_pma_20_addr),
    .io_check_env_pma_20_mask        (u_pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c       (u_pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_atomic  (u_pmp_pma_21_cfg_atomic),
    .io_check_env_pma_21_cfg_a       (u_pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_r       (u_pmp_pma_21_cfg_r),
    .io_check_env_pma_21_addr        (u_pmp_pma_21_addr),
    .io_check_env_pma_21_mask        (u_pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c       (u_pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_atomic  (u_pmp_pma_22_cfg_atomic),
    .io_check_env_pma_22_cfg_a       (u_pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_r       (u_pmp_pma_22_cfg_r),
    .io_check_env_pma_22_addr        (u_pmp_pma_22_addr),
    .io_check_env_pma_22_mask        (u_pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c       (u_pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_atomic  (u_pmp_pma_23_cfg_atomic),
    .io_check_env_pma_23_cfg_a       (u_pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_r       (u_pmp_pma_23_cfg_r),
    .io_check_env_pma_23_addr        (u_pmp_pma_23_addr),
    .io_check_env_pma_23_mask        (u_pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c       (u_pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_atomic  (u_pmp_pma_24_cfg_atomic),
    .io_check_env_pma_24_cfg_a       (u_pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_r       (u_pmp_pma_24_cfg_r),
    .io_check_env_pma_24_addr        (u_pmp_pma_24_addr),
    .io_check_env_pma_24_mask        (u_pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c       (u_pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_atomic  (u_pmp_pma_25_cfg_atomic),
    .io_check_env_pma_25_cfg_a       (u_pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_r       (u_pmp_pma_25_cfg_r),
    .io_check_env_pma_25_addr        (u_pmp_pma_25_addr),
    .io_check_env_pma_25_mask        (u_pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c       (u_pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_atomic  (u_pmp_pma_26_cfg_atomic),
    .io_check_env_pma_26_cfg_a       (u_pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_r       (u_pmp_pma_26_cfg_r),
    .io_check_env_pma_26_addr        (u_pmp_pma_26_addr),
    .io_check_env_pma_26_mask        (u_pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c       (u_pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_atomic  (u_pmp_pma_27_cfg_atomic),
    .io_check_env_pma_27_cfg_a       (u_pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_r       (u_pmp_pma_27_cfg_r),
    .io_check_env_pma_27_addr        (u_pmp_pma_27_addr),
    .io_check_env_pma_27_mask        (u_pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c       (u_pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_atomic  (u_pmp_pma_28_cfg_atomic),
    .io_check_env_pma_28_cfg_a       (u_pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_r       (u_pmp_pma_28_cfg_r),
    .io_check_env_pma_28_addr        (u_pmp_pma_28_addr),
    .io_check_env_pma_28_mask        (u_pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c       (u_pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_atomic  (u_pmp_pma_29_cfg_atomic),
    .io_check_env_pma_29_cfg_a       (u_pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_r       (u_pmp_pma_29_cfg_r),
    .io_check_env_pma_29_addr        (u_pmp_pma_29_addr),
    .io_check_env_pma_29_mask        (u_pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c       (u_pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_atomic  (u_pmp_pma_30_cfg_atomic),
    .io_check_env_pma_30_cfg_a       (u_pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_r       (u_pmp_pma_30_cfg_r),
    .io_check_env_pma_30_addr        (u_pmp_pma_30_addr),
    .io_check_env_pma_30_mask        (u_pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c       (u_pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_atomic  (u_pmp_pma_31_cfg_atomic),
    .io_check_env_pma_31_cfg_a       (u_pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_r       (u_pmp_pma_31_cfg_r),
    .io_check_env_pma_31_addr        (u_pmp_pma_31_addr),
    .io_check_env_pma_31_mask        (u_pmp_pma_31_mask),
    .io_req_bits_addr                (u_hptw_pmp_req_bits_addr),
    .io_resp_ld                      (u_pmp_chk_hptw_resp_ld),
    .io_resp_mmio                    (u_pmp_chk_hptw_resp_mmio),
    .io_resp_atomic                  (/* unused */)
  );

  PMPChecker u_pmp_chk_bitmap (
    .io_check_env_mode               (2'h1),
    .io_check_env_debug              (u_pmp_chk_bitmap__check_env_debug),
    .io_check_env_pmp_0_cfg_l        (u_pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a        (u_pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_r        (u_pmp_pmp_0_cfg_r),
    .io_check_env_pmp_0_addr         (u_pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask         (u_pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l        (u_pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a        (u_pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_r        (u_pmp_pmp_1_cfg_r),
    .io_check_env_pmp_1_addr         (u_pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask         (u_pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l        (u_pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a        (u_pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_r        (u_pmp_pmp_2_cfg_r),
    .io_check_env_pmp_2_addr         (u_pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask         (u_pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l        (u_pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a        (u_pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_r        (u_pmp_pmp_3_cfg_r),
    .io_check_env_pmp_3_addr         (u_pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask         (u_pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l        (u_pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a        (u_pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_r        (u_pmp_pmp_4_cfg_r),
    .io_check_env_pmp_4_addr         (u_pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask         (u_pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l        (u_pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a        (u_pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_r        (u_pmp_pmp_5_cfg_r),
    .io_check_env_pmp_5_addr         (u_pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask         (u_pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l        (u_pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a        (u_pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_r        (u_pmp_pmp_6_cfg_r),
    .io_check_env_pmp_6_addr         (u_pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask         (u_pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l        (u_pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a        (u_pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_r        (u_pmp_pmp_7_cfg_r),
    .io_check_env_pmp_7_addr         (u_pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask         (u_pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l        (u_pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a        (u_pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_r        (u_pmp_pmp_8_cfg_r),
    .io_check_env_pmp_8_addr         (u_pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask         (u_pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l        (u_pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a        (u_pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_r        (u_pmp_pmp_9_cfg_r),
    .io_check_env_pmp_9_addr         (u_pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask         (u_pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l       (u_pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a       (u_pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_r       (u_pmp_pmp_10_cfg_r),
    .io_check_env_pmp_10_addr        (u_pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask        (u_pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l       (u_pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a       (u_pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_r       (u_pmp_pmp_11_cfg_r),
    .io_check_env_pmp_11_addr        (u_pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask        (u_pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l       (u_pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a       (u_pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_r       (u_pmp_pmp_12_cfg_r),
    .io_check_env_pmp_12_addr        (u_pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask        (u_pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l       (u_pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a       (u_pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_r       (u_pmp_pmp_13_cfg_r),
    .io_check_env_pmp_13_addr        (u_pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask        (u_pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l       (u_pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a       (u_pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_r       (u_pmp_pmp_14_cfg_r),
    .io_check_env_pmp_14_addr        (u_pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask        (u_pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l       (u_pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a       (u_pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_r       (u_pmp_pmp_15_cfg_r),
    .io_check_env_pmp_15_addr        (u_pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask        (u_pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l       (u_pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a       (u_pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_r       (u_pmp_pmp_16_cfg_r),
    .io_check_env_pmp_16_addr        (u_pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask        (u_pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l       (u_pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a       (u_pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_r       (u_pmp_pmp_17_cfg_r),
    .io_check_env_pmp_17_addr        (u_pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask        (u_pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l       (u_pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a       (u_pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_r       (u_pmp_pmp_18_cfg_r),
    .io_check_env_pmp_18_addr        (u_pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask        (u_pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l       (u_pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a       (u_pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_r       (u_pmp_pmp_19_cfg_r),
    .io_check_env_pmp_19_addr        (u_pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask        (u_pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l       (u_pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a       (u_pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_r       (u_pmp_pmp_20_cfg_r),
    .io_check_env_pmp_20_addr        (u_pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask        (u_pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l       (u_pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a       (u_pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_r       (u_pmp_pmp_21_cfg_r),
    .io_check_env_pmp_21_addr        (u_pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask        (u_pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l       (u_pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a       (u_pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_r       (u_pmp_pmp_22_cfg_r),
    .io_check_env_pmp_22_addr        (u_pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask        (u_pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l       (u_pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a       (u_pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_r       (u_pmp_pmp_23_cfg_r),
    .io_check_env_pmp_23_addr        (u_pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask        (u_pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l       (u_pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a       (u_pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_r       (u_pmp_pmp_24_cfg_r),
    .io_check_env_pmp_24_addr        (u_pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask        (u_pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l       (u_pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a       (u_pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_r       (u_pmp_pmp_25_cfg_r),
    .io_check_env_pmp_25_addr        (u_pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask        (u_pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l       (u_pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a       (u_pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_r       (u_pmp_pmp_26_cfg_r),
    .io_check_env_pmp_26_addr        (u_pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask        (u_pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l       (u_pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a       (u_pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_r       (u_pmp_pmp_27_cfg_r),
    .io_check_env_pmp_27_addr        (u_pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask        (u_pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l       (u_pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a       (u_pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_r       (u_pmp_pmp_28_cfg_r),
    .io_check_env_pmp_28_addr        (u_pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask        (u_pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l       (u_pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a       (u_pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_r       (u_pmp_pmp_29_cfg_r),
    .io_check_env_pmp_29_addr        (u_pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask        (u_pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l       (u_pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a       (u_pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_r       (u_pmp_pmp_30_cfg_r),
    .io_check_env_pmp_30_addr        (u_pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask        (u_pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l       (u_pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a       (u_pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_r       (u_pmp_pmp_31_cfg_r),
    .io_check_env_pmp_31_addr        (u_pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask        (u_pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c        (u_pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_atomic   (u_pmp_pma_0_cfg_atomic),
    .io_check_env_pma_0_cfg_a        (u_pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_r        (u_pmp_pma_0_cfg_r),
    .io_check_env_pma_0_addr         (u_pmp_pma_0_addr),
    .io_check_env_pma_0_mask         (u_pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c        (u_pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_atomic   (u_pmp_pma_1_cfg_atomic),
    .io_check_env_pma_1_cfg_a        (u_pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_r        (u_pmp_pma_1_cfg_r),
    .io_check_env_pma_1_addr         (u_pmp_pma_1_addr),
    .io_check_env_pma_1_mask         (u_pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c        (u_pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_atomic   (u_pmp_pma_2_cfg_atomic),
    .io_check_env_pma_2_cfg_a        (u_pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_r        (u_pmp_pma_2_cfg_r),
    .io_check_env_pma_2_addr         (u_pmp_pma_2_addr),
    .io_check_env_pma_2_mask         (u_pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c        (u_pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_atomic   (u_pmp_pma_3_cfg_atomic),
    .io_check_env_pma_3_cfg_a        (u_pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_r        (u_pmp_pma_3_cfg_r),
    .io_check_env_pma_3_addr         (u_pmp_pma_3_addr),
    .io_check_env_pma_3_mask         (u_pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c        (u_pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_atomic   (u_pmp_pma_4_cfg_atomic),
    .io_check_env_pma_4_cfg_a        (u_pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_r        (u_pmp_pma_4_cfg_r),
    .io_check_env_pma_4_addr         (u_pmp_pma_4_addr),
    .io_check_env_pma_4_mask         (u_pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c        (u_pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_atomic   (u_pmp_pma_5_cfg_atomic),
    .io_check_env_pma_5_cfg_a        (u_pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_r        (u_pmp_pma_5_cfg_r),
    .io_check_env_pma_5_addr         (u_pmp_pma_5_addr),
    .io_check_env_pma_5_mask         (u_pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c        (u_pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_atomic   (u_pmp_pma_6_cfg_atomic),
    .io_check_env_pma_6_cfg_a        (u_pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_r        (u_pmp_pma_6_cfg_r),
    .io_check_env_pma_6_addr         (u_pmp_pma_6_addr),
    .io_check_env_pma_6_mask         (u_pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c        (u_pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_atomic   (u_pmp_pma_7_cfg_atomic),
    .io_check_env_pma_7_cfg_a        (u_pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_r        (u_pmp_pma_7_cfg_r),
    .io_check_env_pma_7_addr         (u_pmp_pma_7_addr),
    .io_check_env_pma_7_mask         (u_pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c        (u_pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_atomic   (u_pmp_pma_8_cfg_atomic),
    .io_check_env_pma_8_cfg_a        (u_pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_r        (u_pmp_pma_8_cfg_r),
    .io_check_env_pma_8_addr         (u_pmp_pma_8_addr),
    .io_check_env_pma_8_mask         (u_pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c        (u_pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_atomic   (u_pmp_pma_9_cfg_atomic),
    .io_check_env_pma_9_cfg_a        (u_pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_r        (u_pmp_pma_9_cfg_r),
    .io_check_env_pma_9_addr         (u_pmp_pma_9_addr),
    .io_check_env_pma_9_mask         (u_pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c       (u_pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_atomic  (u_pmp_pma_10_cfg_atomic),
    .io_check_env_pma_10_cfg_a       (u_pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_r       (u_pmp_pma_10_cfg_r),
    .io_check_env_pma_10_addr        (u_pmp_pma_10_addr),
    .io_check_env_pma_10_mask        (u_pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c       (u_pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_atomic  (u_pmp_pma_11_cfg_atomic),
    .io_check_env_pma_11_cfg_a       (u_pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_r       (u_pmp_pma_11_cfg_r),
    .io_check_env_pma_11_addr        (u_pmp_pma_11_addr),
    .io_check_env_pma_11_mask        (u_pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c       (u_pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_atomic  (u_pmp_pma_12_cfg_atomic),
    .io_check_env_pma_12_cfg_a       (u_pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_r       (u_pmp_pma_12_cfg_r),
    .io_check_env_pma_12_addr        (u_pmp_pma_12_addr),
    .io_check_env_pma_12_mask        (u_pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c       (u_pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_atomic  (u_pmp_pma_13_cfg_atomic),
    .io_check_env_pma_13_cfg_a       (u_pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_r       (u_pmp_pma_13_cfg_r),
    .io_check_env_pma_13_addr        (u_pmp_pma_13_addr),
    .io_check_env_pma_13_mask        (u_pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c       (u_pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_atomic  (u_pmp_pma_14_cfg_atomic),
    .io_check_env_pma_14_cfg_a       (u_pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_r       (u_pmp_pma_14_cfg_r),
    .io_check_env_pma_14_addr        (u_pmp_pma_14_addr),
    .io_check_env_pma_14_mask        (u_pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c       (u_pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_atomic  (u_pmp_pma_15_cfg_atomic),
    .io_check_env_pma_15_cfg_a       (u_pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_r       (u_pmp_pma_15_cfg_r),
    .io_check_env_pma_15_addr        (u_pmp_pma_15_addr),
    .io_check_env_pma_15_mask        (u_pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c       (u_pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_atomic  (u_pmp_pma_16_cfg_atomic),
    .io_check_env_pma_16_cfg_a       (u_pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_r       (u_pmp_pma_16_cfg_r),
    .io_check_env_pma_16_addr        (u_pmp_pma_16_addr),
    .io_check_env_pma_16_mask        (u_pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c       (u_pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_atomic  (u_pmp_pma_17_cfg_atomic),
    .io_check_env_pma_17_cfg_a       (u_pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_r       (u_pmp_pma_17_cfg_r),
    .io_check_env_pma_17_addr        (u_pmp_pma_17_addr),
    .io_check_env_pma_17_mask        (u_pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c       (u_pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_atomic  (u_pmp_pma_18_cfg_atomic),
    .io_check_env_pma_18_cfg_a       (u_pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_r       (u_pmp_pma_18_cfg_r),
    .io_check_env_pma_18_addr        (u_pmp_pma_18_addr),
    .io_check_env_pma_18_mask        (u_pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c       (u_pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_atomic  (u_pmp_pma_19_cfg_atomic),
    .io_check_env_pma_19_cfg_a       (u_pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_r       (u_pmp_pma_19_cfg_r),
    .io_check_env_pma_19_addr        (u_pmp_pma_19_addr),
    .io_check_env_pma_19_mask        (u_pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c       (u_pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_atomic  (u_pmp_pma_20_cfg_atomic),
    .io_check_env_pma_20_cfg_a       (u_pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_r       (u_pmp_pma_20_cfg_r),
    .io_check_env_pma_20_addr        (u_pmp_pma_20_addr),
    .io_check_env_pma_20_mask        (u_pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c       (u_pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_atomic  (u_pmp_pma_21_cfg_atomic),
    .io_check_env_pma_21_cfg_a       (u_pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_r       (u_pmp_pma_21_cfg_r),
    .io_check_env_pma_21_addr        (u_pmp_pma_21_addr),
    .io_check_env_pma_21_mask        (u_pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c       (u_pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_atomic  (u_pmp_pma_22_cfg_atomic),
    .io_check_env_pma_22_cfg_a       (u_pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_r       (u_pmp_pma_22_cfg_r),
    .io_check_env_pma_22_addr        (u_pmp_pma_22_addr),
    .io_check_env_pma_22_mask        (u_pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c       (u_pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_atomic  (u_pmp_pma_23_cfg_atomic),
    .io_check_env_pma_23_cfg_a       (u_pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_r       (u_pmp_pma_23_cfg_r),
    .io_check_env_pma_23_addr        (u_pmp_pma_23_addr),
    .io_check_env_pma_23_mask        (u_pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c       (u_pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_atomic  (u_pmp_pma_24_cfg_atomic),
    .io_check_env_pma_24_cfg_a       (u_pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_r       (u_pmp_pma_24_cfg_r),
    .io_check_env_pma_24_addr        (u_pmp_pma_24_addr),
    .io_check_env_pma_24_mask        (u_pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c       (u_pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_atomic  (u_pmp_pma_25_cfg_atomic),
    .io_check_env_pma_25_cfg_a       (u_pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_r       (u_pmp_pma_25_cfg_r),
    .io_check_env_pma_25_addr        (u_pmp_pma_25_addr),
    .io_check_env_pma_25_mask        (u_pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c       (u_pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_atomic  (u_pmp_pma_26_cfg_atomic),
    .io_check_env_pma_26_cfg_a       (u_pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_r       (u_pmp_pma_26_cfg_r),
    .io_check_env_pma_26_addr        (u_pmp_pma_26_addr),
    .io_check_env_pma_26_mask        (u_pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c       (u_pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_atomic  (u_pmp_pma_27_cfg_atomic),
    .io_check_env_pma_27_cfg_a       (u_pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_r       (u_pmp_pma_27_cfg_r),
    .io_check_env_pma_27_addr        (u_pmp_pma_27_addr),
    .io_check_env_pma_27_mask        (u_pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c       (u_pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_atomic  (u_pmp_pma_28_cfg_atomic),
    .io_check_env_pma_28_cfg_a       (u_pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_r       (u_pmp_pma_28_cfg_r),
    .io_check_env_pma_28_addr        (u_pmp_pma_28_addr),
    .io_check_env_pma_28_mask        (u_pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c       (u_pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_atomic  (u_pmp_pma_29_cfg_atomic),
    .io_check_env_pma_29_cfg_a       (u_pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_r       (u_pmp_pma_29_cfg_r),
    .io_check_env_pma_29_addr        (u_pmp_pma_29_addr),
    .io_check_env_pma_29_mask        (u_pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c       (u_pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_atomic  (u_pmp_pma_30_cfg_atomic),
    .io_check_env_pma_30_cfg_a       (u_pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_r       (u_pmp_pma_30_cfg_r),
    .io_check_env_pma_30_addr        (u_pmp_pma_30_addr),
    .io_check_env_pma_30_mask        (u_pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c       (u_pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_atomic  (u_pmp_pma_31_cfg_atomic),
    .io_check_env_pma_31_cfg_a       (u_pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_r       (u_pmp_pma_31_cfg_r),
    .io_check_env_pma_31_addr        (u_pmp_pma_31_addr),
    .io_check_env_pma_31_mask        (u_pmp_pma_31_mask),
    .io_req_bits_addr                (u_bitmap_pmp_req_bits_addr),
    .io_resp_ld                      (u_pmp_chk_bitmap_resp_ld),
    .io_resp_mmio                    (u_pmp_chk_bitmap_resp_mmio),
    .io_resp_atomic                  (/* unused */)
  );

  Bitmap u_bitmap (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_bitmap__sfence_valid),
    .io_csr_satp_changed             (u_bitmap__csr_satp_changed),
    .io_csr_vsatp_changed            (u_bitmap__csr_vsatp_changed),
    .io_csr_hgatp_changed            (u_bitmap__csr_hgatp_changed),
    .io_csr_mbmc_BMA                 (u_bitmap__csr_mbmc_BMA),
    .io_csr_priv_virt_changed        (u_bitmap__csr_priv_virt_changed),
    .io_mem_req_ready                (u_mem_arb_in_3_ready),
    .io_mem_req_valid                (u_bitmap_mem_req_valid),
    .io_mem_req_bits_addr            (u_bitmap_mem_req_bits_addr),
    .io_mem_req_bits_id              (u_bitmap_mem_req_bits_id),
    .io_mem_resp_valid               (u_bitmap__mem_resp_valid),
    .io_mem_resp_bits_id             (u_bitmap__mem_resp_bits_id),
    .io_mem_resp_bits_value          (u_bitmap__mem_resp_bits_value),
    .io_mem_req_mask_0               (u_bitmap__mem_req_mask_0),
    .io_mem_req_mask_1               (u_bitmap__mem_req_mask_1),
    .io_mem_req_mask_2               (u_bitmap__mem_req_mask_2),
    .io_mem_req_mask_3               (u_bitmap__mem_req_mask_3),
    .io_mem_req_mask_4               (u_bitmap__mem_req_mask_4),
    .io_mem_req_mask_5               (u_bitmap__mem_req_mask_5),
    .io_mem_req_mask_6               (u_bitmap__mem_req_mask_6),
    .io_mem_req_mask_7               (u_bitmap__mem_req_mask_7),
    .io_req_ready                    (u_bitmap_req_ready),
    .io_req_valid                    (u_bitmap_arb_out_valid),
    .io_req_bits_bmppn               (u_bitmap_arb_out_bits_bmppn),
    .io_req_bits_id                  (u_bitmap_arb_out_bits_id),
    .io_req_bits_vpn                 (u_bitmap_arb_out_bits_vpn),
    .io_req_bits_level               (u_bitmap_arb_out_bits_level),
    .io_req_bits_way_info            (u_bitmap_arb_out_bits_way_info),
    .io_req_bits_hptw_bypassed       (u_bitmap_arb_out_bits_hptw_bypassed),
    .io_req_bits_s2xlate             (u_bitmap_arb_out_bits_s2xlate),
    .io_req_bits_n                   (u_bitmap_arb_out_bits_n),
    .io_resp_ready                   (u_bitmap__resp_ready),
    .io_resp_valid                   (u_bitmap_resp_valid),
    .io_resp_bits_cf                 (u_bitmap_resp_bits_cf),
    .io_resp_bits_cfs_0              (u_bitmap_resp_bits_cfs_0),
    .io_resp_bits_cfs_1              (u_bitmap_resp_bits_cfs_1),
    .io_resp_bits_cfs_2              (u_bitmap_resp_bits_cfs_2),
    .io_resp_bits_cfs_3              (u_bitmap_resp_bits_cfs_3),
    .io_resp_bits_cfs_4              (u_bitmap_resp_bits_cfs_4),
    .io_resp_bits_cfs_5              (u_bitmap_resp_bits_cfs_5),
    .io_resp_bits_cfs_6              (u_bitmap_resp_bits_cfs_6),
    .io_resp_bits_cfs_7              (u_bitmap_resp_bits_cfs_7),
    .io_resp_bits_id                 (u_bitmap_resp_bits_id),
    .io_pmp_req_bits_addr            (u_bitmap_pmp_req_bits_addr),
    .io_pmp_resp_ld                  (u_pmp_chk_bitmap_resp_ld),
    .io_pmp_resp_mmio                (u_pmp_chk_bitmap_resp_mmio),
    .io_wakeup_ready                 (u_page_cache_bitmap_wakeup_ready),
    .io_wakeup_valid                 (u_bitmap_wakeup_valid),
    .io_wakeup_bits_setIndex         (u_bitmap_wakeup_bits_setIndex),
    .io_wakeup_bits_tag              (u_bitmap_wakeup_bits_tag),
    .io_wakeup_bits_way_info         (u_bitmap_wakeup_bits_way_info),
    .io_wakeup_bits_pte_index        (u_bitmap_wakeup_bits_pte_index),
    .io_wakeup_bits_check_success    (u_bitmap_wakeup_bits_check_success),
    .io_wakeup_bits_s2xlate          (u_bitmap_wakeup_bits_s2xlate),
    .io_cache_req_ready              (u_bitmap_cache_req_ready),
    .io_cache_req_valid              (u_bitmap_cache_req_valid),
    .io_cache_req_bits_order         (u_bitmap_cache_req_bits_order),
    .io_cache_req_bits_tag           (u_bitmap_cache_req_bits_tag),
    .io_cache_resp_ready             (u_bitmap_cache_resp_ready),
    .io_cache_resp_valid             (u_bitmap_cache_resp_valid),
    .io_cache_resp_bits_hit          (u_bitmap_cache_resp_bits_hit),
    .io_cache_resp_bits_cfs_0        (u_bitmap_cache_resp_bits_cfs_0),
    .io_cache_resp_bits_cfs_1        (u_bitmap_cache_resp_bits_cfs_1),
    .io_cache_resp_bits_cfs_2        (u_bitmap_cache_resp_bits_cfs_2),
    .io_cache_resp_bits_cfs_3        (u_bitmap_cache_resp_bits_cfs_3),
    .io_cache_resp_bits_cfs_4        (u_bitmap_cache_resp_bits_cfs_4),
    .io_cache_resp_bits_cfs_5        (u_bitmap_cache_resp_bits_cfs_5),
    .io_cache_resp_bits_cfs_6        (u_bitmap_cache_resp_bits_cfs_6),
    .io_cache_resp_bits_cfs_7        (u_bitmap_cache_resp_bits_cfs_7),
    .io_cache_resp_bits_order        (u_bitmap_cache_resp_bits_order),
    .io_refill_valid                 (u_bitmap_refill_valid),
    .io_refill_bits_tag              (u_bitmap_refill_bits_tag),
    .io_refill_bits_data             (u_bitmap_refill_bits_data)
  );

  BitmapCache u_bitmap_cache (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_bitmap_cache__sfence_valid),
    .io_csr_satp_changed             (u_bitmap_cache__csr_satp_changed),
    .io_csr_vsatp_changed            (u_bitmap_cache__csr_vsatp_changed),
    .io_csr_hgatp_changed            (u_bitmap_cache__csr_hgatp_changed),
    .io_csr_mbmc_BCLEAR              (u_bitmap_cache__csr_mbmc_BCLEAR),
    .io_csr_priv_virt_changed        (u_bitmap_cache__csr_priv_virt_changed),
    .io_req_ready                    (u_bitmap_cache_req_ready),
    .io_req_valid                    (u_bitmap_cache_req_valid),
    .io_req_bits_order               (u_bitmap_cache_req_bits_order),
    .io_req_bits_tag                 (u_bitmap_cache_req_bits_tag),
    .io_resp_ready                   (u_bitmap_cache_resp_ready),
    .io_resp_valid                   (u_bitmap_cache_resp_valid),
    .io_resp_bits_hit                (u_bitmap_cache_resp_bits_hit),
    .io_resp_bits_cfs_0              (u_bitmap_cache_resp_bits_cfs_0),
    .io_resp_bits_cfs_1              (u_bitmap_cache_resp_bits_cfs_1),
    .io_resp_bits_cfs_2              (u_bitmap_cache_resp_bits_cfs_2),
    .io_resp_bits_cfs_3              (u_bitmap_cache_resp_bits_cfs_3),
    .io_resp_bits_cfs_4              (u_bitmap_cache_resp_bits_cfs_4),
    .io_resp_bits_cfs_5              (u_bitmap_cache_resp_bits_cfs_5),
    .io_resp_bits_cfs_6              (u_bitmap_cache_resp_bits_cfs_6),
    .io_resp_bits_cfs_7              (u_bitmap_cache_resp_bits_cfs_7),
    .io_resp_bits_order              (u_bitmap_cache_resp_bits_order),
    .io_refill_valid                 (u_bitmap_refill_valid),
    .io_refill_bits_tag              (u_bitmap_refill_bits_tag),
    .io_refill_bits_data             (u_bitmap_refill_bits_data),
    .boreChildrenBd_bore_array       (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all         (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req         (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack         (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen     (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be          (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr        (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata      (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen      (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd     (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata     (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold      (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass    (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken  (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk   (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp  (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold  (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen          (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold    (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass  (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen        (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold    (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass  (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen        (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold    (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass  (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen        (sigFromSrams_bore_3_cgen),
    .cg_bore_cgen                    (cg_bore_cgen)
  );

  L2TlbMissQueue u_miss_queue (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_miss_queue__sfence_valid),
    .io_csr_satp_changed             (u_miss_queue__csr_satp_changed),
    .io_csr_vsatp_changed            (u_miss_queue__csr_vsatp_changed),
    .io_csr_hgatp_changed            (u_miss_queue__csr_hgatp_changed),
    .io_csr_priv_virt_changed        (u_miss_queue__csr_priv_virt_changed),
    .io_in_ready                     (u_miss_queue_in_ready),
    .io_in_valid                     (u_arb_mq_out_valid),
    .io_in_bits_req_info_vpn         (u_arb_mq_out_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate     (u_arb_mq_out_bits_req_info_s2xlate),
    .io_in_bits_req_info_source      (u_arb_mq_out_bits_req_info_source),
    .io_in_bits_isLLptw              (u_arb_mq_out_bits_isLLptw),
    .io_out_ready                    (u_miss_queue__out_ready),
    .io_out_valid                    (u_miss_queue_out_valid),
    .io_out_bits_req_info_vpn        (u_miss_queue_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate    (u_miss_queue_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source     (u_miss_queue_out_bits_req_info_source),
    .io_out_bits_isHptwReq           (u_miss_queue_out_bits_isHptwReq),
    .io_out_bits_isLLptw             (u_miss_queue_out_bits_isLLptw),
    .io_out_bits_hptwId              (u_miss_queue_out_bits_hptwId)
  );

  PtwCache u_page_cache (
    .clock                           (clock),
    .reset                           (reset),
    .io_csr_mPBMTE                   (u_page_cache__csr_mPBMTE),
    .io_csr_hPBMTE                   (u_page_cache__csr_hPBMTE),
    .io_req_ready                    (u_page_cache_req_ready),
    .io_req_valid                    (u_page_cache__req_valid),
    .io_req_bits_req_info_vpn        (u_arb_cache_in_out_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate    (u_arb_cache_in_out_bits_req_info_s2xlate),
    .io_req_bits_req_info_source     (u_arb_cache_in_out_bits_req_info_source),
    .io_req_bits_isFirst             (u_page_cache__req_bits_isFirst),
    .io_req_bits_isHptwReq           (u_arb_cache_in_out_bits_isHptwReq),
    .io_req_bits_hptwId              (u_arb_cache_in_out_bits_hptwId),
    .io_resp_ready                   (u_page_cache__resp_ready),
    .io_resp_valid                   (u_page_cache_resp_valid),
    .io_resp_bits_req_info_vpn       (u_page_cache_resp_bits_req_info_vpn),
    .io_resp_bits_req_info_s2xlate   (u_page_cache_resp_bits_req_info_s2xlate),
    .io_resp_bits_req_info_source    (u_page_cache_resp_bits_req_info_source),
    .io_resp_bits_isFirst            (u_page_cache_resp_bits_isFirst),
    .io_resp_bits_hit                (u_page_cache_resp_bits_hit),
    .io_resp_bits_prefetch           (u_page_cache_resp_bits_prefetch),
    .io_resp_bits_bypassed           (u_page_cache_resp_bits_bypassed),
    .io_resp_bits_toFsm_l3Hit        (u_page_cache_resp_bits_toFsm_l3Hit),
    .io_resp_bits_toFsm_l2Hit        (u_page_cache_resp_bits_toFsm_l2Hit),
    .io_resp_bits_toFsm_l1Hit        (u_page_cache_resp_bits_toFsm_l1Hit),
    .io_resp_bits_toFsm_ppn          (u_page_cache_resp_bits_toFsm_ppn),
    .io_resp_bits_toFsm_stage1Hit    (u_page_cache_resp_bits_toFsm_stage1Hit),
    .io_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check(u_page_cache_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toFsm_bitmapCheck_toLLPTW(u_page_cache_resp_bits_toFsm_bitmapCheck_toLLPTW),
    .io_resp_bits_toFsm_bitmapCheck_hitway(u_page_cache_resp_bits_toFsm_bitmapCheck_hitway),
    .io_resp_bits_toFsm_bitmapCheck_pte(u_page_cache_resp_bits_toFsm_bitmapCheck_pte),
    .io_resp_bits_toFsm_bitmapCheck_ptes_0(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_resp_bits_toFsm_bitmapCheck_ptes_1(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_resp_bits_toFsm_bitmapCheck_ptes_2(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_resp_bits_toFsm_bitmapCheck_ptes_3(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_resp_bits_toFsm_bitmapCheck_ptes_4(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_resp_bits_toFsm_bitmapCheck_ptes_5(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_resp_bits_toFsm_bitmapCheck_ptes_6(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_resp_bits_toFsm_bitmapCheck_ptes_7(u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_resp_bits_toFsm_bitmapCheck_cfs_0(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_resp_bits_toFsm_bitmapCheck_cfs_1(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_resp_bits_toFsm_bitmapCheck_cfs_2(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_resp_bits_toFsm_bitmapCheck_cfs_3(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_resp_bits_toFsm_bitmapCheck_cfs_4(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_resp_bits_toFsm_bitmapCheck_cfs_5(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_resp_bits_toFsm_bitmapCheck_cfs_6(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_resp_bits_toFsm_bitmapCheck_cfs_7(u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_resp_bits_toFsm_bitmapCheck_SPlevel(u_page_cache_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_bits_stage1_entry_0_tag (u_page_cache_resp_bits_stage1_entry_0_tag),
    .io_resp_bits_stage1_entry_0_asid(u_page_cache_resp_bits_stage1_entry_0_asid),
    .io_resp_bits_stage1_entry_0_vmid(u_page_cache_resp_bits_stage1_entry_0_vmid),
    .io_resp_bits_stage1_entry_0_n   (u_page_cache_resp_bits_stage1_entry_0_n),
    .io_resp_bits_stage1_entry_0_pbmt(u_page_cache_resp_bits_stage1_entry_0_pbmt),
    .io_resp_bits_stage1_entry_0_perm_d(u_page_cache_resp_bits_stage1_entry_0_perm_d),
    .io_resp_bits_stage1_entry_0_perm_a(u_page_cache_resp_bits_stage1_entry_0_perm_a),
    .io_resp_bits_stage1_entry_0_perm_g(u_page_cache_resp_bits_stage1_entry_0_perm_g),
    .io_resp_bits_stage1_entry_0_perm_u(u_page_cache_resp_bits_stage1_entry_0_perm_u),
    .io_resp_bits_stage1_entry_0_perm_x(u_page_cache_resp_bits_stage1_entry_0_perm_x),
    .io_resp_bits_stage1_entry_0_perm_w(u_page_cache_resp_bits_stage1_entry_0_perm_w),
    .io_resp_bits_stage1_entry_0_perm_r(u_page_cache_resp_bits_stage1_entry_0_perm_r),
    .io_resp_bits_stage1_entry_0_level(u_page_cache_resp_bits_stage1_entry_0_level),
    .io_resp_bits_stage1_entry_0_v   (u_page_cache_resp_bits_stage1_entry_0_v),
    .io_resp_bits_stage1_entry_0_ppn (u_page_cache_resp_bits_stage1_entry_0_ppn),
    .io_resp_bits_stage1_entry_0_ppn_low(u_page_cache_resp_bits_stage1_entry_0_ppn_low),
    .io_resp_bits_stage1_entry_0_pf  (u_page_cache_resp_bits_stage1_entry_0_pf),
    .io_resp_bits_stage1_entry_0_cf  (u_page_cache_resp_bits_stage1_entry_0_cf),
    .io_resp_bits_stage1_entry_1_tag (u_page_cache_resp_bits_stage1_entry_1_tag),
    .io_resp_bits_stage1_entry_1_asid(u_page_cache_resp_bits_stage1_entry_1_asid),
    .io_resp_bits_stage1_entry_1_vmid(u_page_cache_resp_bits_stage1_entry_1_vmid),
    .io_resp_bits_stage1_entry_1_n   (u_page_cache_resp_bits_stage1_entry_1_n),
    .io_resp_bits_stage1_entry_1_pbmt(u_page_cache_resp_bits_stage1_entry_1_pbmt),
    .io_resp_bits_stage1_entry_1_perm_d(u_page_cache_resp_bits_stage1_entry_1_perm_d),
    .io_resp_bits_stage1_entry_1_perm_a(u_page_cache_resp_bits_stage1_entry_1_perm_a),
    .io_resp_bits_stage1_entry_1_perm_g(u_page_cache_resp_bits_stage1_entry_1_perm_g),
    .io_resp_bits_stage1_entry_1_perm_u(u_page_cache_resp_bits_stage1_entry_1_perm_u),
    .io_resp_bits_stage1_entry_1_perm_x(u_page_cache_resp_bits_stage1_entry_1_perm_x),
    .io_resp_bits_stage1_entry_1_perm_w(u_page_cache_resp_bits_stage1_entry_1_perm_w),
    .io_resp_bits_stage1_entry_1_perm_r(u_page_cache_resp_bits_stage1_entry_1_perm_r),
    .io_resp_bits_stage1_entry_1_level(u_page_cache_resp_bits_stage1_entry_1_level),
    .io_resp_bits_stage1_entry_1_v   (u_page_cache_resp_bits_stage1_entry_1_v),
    .io_resp_bits_stage1_entry_1_ppn (u_page_cache_resp_bits_stage1_entry_1_ppn),
    .io_resp_bits_stage1_entry_1_ppn_low(u_page_cache_resp_bits_stage1_entry_1_ppn_low),
    .io_resp_bits_stage1_entry_1_pf  (u_page_cache_resp_bits_stage1_entry_1_pf),
    .io_resp_bits_stage1_entry_1_cf  (u_page_cache_resp_bits_stage1_entry_1_cf),
    .io_resp_bits_stage1_entry_2_tag (u_page_cache_resp_bits_stage1_entry_2_tag),
    .io_resp_bits_stage1_entry_2_asid(u_page_cache_resp_bits_stage1_entry_2_asid),
    .io_resp_bits_stage1_entry_2_vmid(u_page_cache_resp_bits_stage1_entry_2_vmid),
    .io_resp_bits_stage1_entry_2_n   (u_page_cache_resp_bits_stage1_entry_2_n),
    .io_resp_bits_stage1_entry_2_pbmt(u_page_cache_resp_bits_stage1_entry_2_pbmt),
    .io_resp_bits_stage1_entry_2_perm_d(u_page_cache_resp_bits_stage1_entry_2_perm_d),
    .io_resp_bits_stage1_entry_2_perm_a(u_page_cache_resp_bits_stage1_entry_2_perm_a),
    .io_resp_bits_stage1_entry_2_perm_g(u_page_cache_resp_bits_stage1_entry_2_perm_g),
    .io_resp_bits_stage1_entry_2_perm_u(u_page_cache_resp_bits_stage1_entry_2_perm_u),
    .io_resp_bits_stage1_entry_2_perm_x(u_page_cache_resp_bits_stage1_entry_2_perm_x),
    .io_resp_bits_stage1_entry_2_perm_w(u_page_cache_resp_bits_stage1_entry_2_perm_w),
    .io_resp_bits_stage1_entry_2_perm_r(u_page_cache_resp_bits_stage1_entry_2_perm_r),
    .io_resp_bits_stage1_entry_2_level(u_page_cache_resp_bits_stage1_entry_2_level),
    .io_resp_bits_stage1_entry_2_v   (u_page_cache_resp_bits_stage1_entry_2_v),
    .io_resp_bits_stage1_entry_2_ppn (u_page_cache_resp_bits_stage1_entry_2_ppn),
    .io_resp_bits_stage1_entry_2_ppn_low(u_page_cache_resp_bits_stage1_entry_2_ppn_low),
    .io_resp_bits_stage1_entry_2_pf  (u_page_cache_resp_bits_stage1_entry_2_pf),
    .io_resp_bits_stage1_entry_2_cf  (u_page_cache_resp_bits_stage1_entry_2_cf),
    .io_resp_bits_stage1_entry_3_tag (u_page_cache_resp_bits_stage1_entry_3_tag),
    .io_resp_bits_stage1_entry_3_asid(u_page_cache_resp_bits_stage1_entry_3_asid),
    .io_resp_bits_stage1_entry_3_vmid(u_page_cache_resp_bits_stage1_entry_3_vmid),
    .io_resp_bits_stage1_entry_3_n   (u_page_cache_resp_bits_stage1_entry_3_n),
    .io_resp_bits_stage1_entry_3_pbmt(u_page_cache_resp_bits_stage1_entry_3_pbmt),
    .io_resp_bits_stage1_entry_3_perm_d(u_page_cache_resp_bits_stage1_entry_3_perm_d),
    .io_resp_bits_stage1_entry_3_perm_a(u_page_cache_resp_bits_stage1_entry_3_perm_a),
    .io_resp_bits_stage1_entry_3_perm_g(u_page_cache_resp_bits_stage1_entry_3_perm_g),
    .io_resp_bits_stage1_entry_3_perm_u(u_page_cache_resp_bits_stage1_entry_3_perm_u),
    .io_resp_bits_stage1_entry_3_perm_x(u_page_cache_resp_bits_stage1_entry_3_perm_x),
    .io_resp_bits_stage1_entry_3_perm_w(u_page_cache_resp_bits_stage1_entry_3_perm_w),
    .io_resp_bits_stage1_entry_3_perm_r(u_page_cache_resp_bits_stage1_entry_3_perm_r),
    .io_resp_bits_stage1_entry_3_level(u_page_cache_resp_bits_stage1_entry_3_level),
    .io_resp_bits_stage1_entry_3_v   (u_page_cache_resp_bits_stage1_entry_3_v),
    .io_resp_bits_stage1_entry_3_ppn (u_page_cache_resp_bits_stage1_entry_3_ppn),
    .io_resp_bits_stage1_entry_3_ppn_low(u_page_cache_resp_bits_stage1_entry_3_ppn_low),
    .io_resp_bits_stage1_entry_3_pf  (u_page_cache_resp_bits_stage1_entry_3_pf),
    .io_resp_bits_stage1_entry_3_cf  (u_page_cache_resp_bits_stage1_entry_3_cf),
    .io_resp_bits_stage1_entry_4_tag (u_page_cache_resp_bits_stage1_entry_4_tag),
    .io_resp_bits_stage1_entry_4_asid(u_page_cache_resp_bits_stage1_entry_4_asid),
    .io_resp_bits_stage1_entry_4_vmid(u_page_cache_resp_bits_stage1_entry_4_vmid),
    .io_resp_bits_stage1_entry_4_n   (u_page_cache_resp_bits_stage1_entry_4_n),
    .io_resp_bits_stage1_entry_4_pbmt(u_page_cache_resp_bits_stage1_entry_4_pbmt),
    .io_resp_bits_stage1_entry_4_perm_d(u_page_cache_resp_bits_stage1_entry_4_perm_d),
    .io_resp_bits_stage1_entry_4_perm_a(u_page_cache_resp_bits_stage1_entry_4_perm_a),
    .io_resp_bits_stage1_entry_4_perm_g(u_page_cache_resp_bits_stage1_entry_4_perm_g),
    .io_resp_bits_stage1_entry_4_perm_u(u_page_cache_resp_bits_stage1_entry_4_perm_u),
    .io_resp_bits_stage1_entry_4_perm_x(u_page_cache_resp_bits_stage1_entry_4_perm_x),
    .io_resp_bits_stage1_entry_4_perm_w(u_page_cache_resp_bits_stage1_entry_4_perm_w),
    .io_resp_bits_stage1_entry_4_perm_r(u_page_cache_resp_bits_stage1_entry_4_perm_r),
    .io_resp_bits_stage1_entry_4_level(u_page_cache_resp_bits_stage1_entry_4_level),
    .io_resp_bits_stage1_entry_4_v   (u_page_cache_resp_bits_stage1_entry_4_v),
    .io_resp_bits_stage1_entry_4_ppn (u_page_cache_resp_bits_stage1_entry_4_ppn),
    .io_resp_bits_stage1_entry_4_ppn_low(u_page_cache_resp_bits_stage1_entry_4_ppn_low),
    .io_resp_bits_stage1_entry_4_pf  (u_page_cache_resp_bits_stage1_entry_4_pf),
    .io_resp_bits_stage1_entry_4_cf  (u_page_cache_resp_bits_stage1_entry_4_cf),
    .io_resp_bits_stage1_entry_5_tag (u_page_cache_resp_bits_stage1_entry_5_tag),
    .io_resp_bits_stage1_entry_5_asid(u_page_cache_resp_bits_stage1_entry_5_asid),
    .io_resp_bits_stage1_entry_5_vmid(u_page_cache_resp_bits_stage1_entry_5_vmid),
    .io_resp_bits_stage1_entry_5_n   (u_page_cache_resp_bits_stage1_entry_5_n),
    .io_resp_bits_stage1_entry_5_pbmt(u_page_cache_resp_bits_stage1_entry_5_pbmt),
    .io_resp_bits_stage1_entry_5_perm_d(u_page_cache_resp_bits_stage1_entry_5_perm_d),
    .io_resp_bits_stage1_entry_5_perm_a(u_page_cache_resp_bits_stage1_entry_5_perm_a),
    .io_resp_bits_stage1_entry_5_perm_g(u_page_cache_resp_bits_stage1_entry_5_perm_g),
    .io_resp_bits_stage1_entry_5_perm_u(u_page_cache_resp_bits_stage1_entry_5_perm_u),
    .io_resp_bits_stage1_entry_5_perm_x(u_page_cache_resp_bits_stage1_entry_5_perm_x),
    .io_resp_bits_stage1_entry_5_perm_w(u_page_cache_resp_bits_stage1_entry_5_perm_w),
    .io_resp_bits_stage1_entry_5_perm_r(u_page_cache_resp_bits_stage1_entry_5_perm_r),
    .io_resp_bits_stage1_entry_5_level(u_page_cache_resp_bits_stage1_entry_5_level),
    .io_resp_bits_stage1_entry_5_v   (u_page_cache_resp_bits_stage1_entry_5_v),
    .io_resp_bits_stage1_entry_5_ppn (u_page_cache_resp_bits_stage1_entry_5_ppn),
    .io_resp_bits_stage1_entry_5_ppn_low(u_page_cache_resp_bits_stage1_entry_5_ppn_low),
    .io_resp_bits_stage1_entry_5_pf  (u_page_cache_resp_bits_stage1_entry_5_pf),
    .io_resp_bits_stage1_entry_5_cf  (u_page_cache_resp_bits_stage1_entry_5_cf),
    .io_resp_bits_stage1_entry_6_tag (u_page_cache_resp_bits_stage1_entry_6_tag),
    .io_resp_bits_stage1_entry_6_asid(u_page_cache_resp_bits_stage1_entry_6_asid),
    .io_resp_bits_stage1_entry_6_vmid(u_page_cache_resp_bits_stage1_entry_6_vmid),
    .io_resp_bits_stage1_entry_6_n   (u_page_cache_resp_bits_stage1_entry_6_n),
    .io_resp_bits_stage1_entry_6_pbmt(u_page_cache_resp_bits_stage1_entry_6_pbmt),
    .io_resp_bits_stage1_entry_6_perm_d(u_page_cache_resp_bits_stage1_entry_6_perm_d),
    .io_resp_bits_stage1_entry_6_perm_a(u_page_cache_resp_bits_stage1_entry_6_perm_a),
    .io_resp_bits_stage1_entry_6_perm_g(u_page_cache_resp_bits_stage1_entry_6_perm_g),
    .io_resp_bits_stage1_entry_6_perm_u(u_page_cache_resp_bits_stage1_entry_6_perm_u),
    .io_resp_bits_stage1_entry_6_perm_x(u_page_cache_resp_bits_stage1_entry_6_perm_x),
    .io_resp_bits_stage1_entry_6_perm_w(u_page_cache_resp_bits_stage1_entry_6_perm_w),
    .io_resp_bits_stage1_entry_6_perm_r(u_page_cache_resp_bits_stage1_entry_6_perm_r),
    .io_resp_bits_stage1_entry_6_level(u_page_cache_resp_bits_stage1_entry_6_level),
    .io_resp_bits_stage1_entry_6_v   (u_page_cache_resp_bits_stage1_entry_6_v),
    .io_resp_bits_stage1_entry_6_ppn (u_page_cache_resp_bits_stage1_entry_6_ppn),
    .io_resp_bits_stage1_entry_6_ppn_low(u_page_cache_resp_bits_stage1_entry_6_ppn_low),
    .io_resp_bits_stage1_entry_6_pf  (u_page_cache_resp_bits_stage1_entry_6_pf),
    .io_resp_bits_stage1_entry_6_cf  (u_page_cache_resp_bits_stage1_entry_6_cf),
    .io_resp_bits_stage1_entry_7_tag (u_page_cache_resp_bits_stage1_entry_7_tag),
    .io_resp_bits_stage1_entry_7_asid(u_page_cache_resp_bits_stage1_entry_7_asid),
    .io_resp_bits_stage1_entry_7_vmid(u_page_cache_resp_bits_stage1_entry_7_vmid),
    .io_resp_bits_stage1_entry_7_n   (u_page_cache_resp_bits_stage1_entry_7_n),
    .io_resp_bits_stage1_entry_7_pbmt(u_page_cache_resp_bits_stage1_entry_7_pbmt),
    .io_resp_bits_stage1_entry_7_perm_d(u_page_cache_resp_bits_stage1_entry_7_perm_d),
    .io_resp_bits_stage1_entry_7_perm_a(u_page_cache_resp_bits_stage1_entry_7_perm_a),
    .io_resp_bits_stage1_entry_7_perm_g(u_page_cache_resp_bits_stage1_entry_7_perm_g),
    .io_resp_bits_stage1_entry_7_perm_u(u_page_cache_resp_bits_stage1_entry_7_perm_u),
    .io_resp_bits_stage1_entry_7_perm_x(u_page_cache_resp_bits_stage1_entry_7_perm_x),
    .io_resp_bits_stage1_entry_7_perm_w(u_page_cache_resp_bits_stage1_entry_7_perm_w),
    .io_resp_bits_stage1_entry_7_perm_r(u_page_cache_resp_bits_stage1_entry_7_perm_r),
    .io_resp_bits_stage1_entry_7_level(u_page_cache_resp_bits_stage1_entry_7_level),
    .io_resp_bits_stage1_entry_7_v   (u_page_cache_resp_bits_stage1_entry_7_v),
    .io_resp_bits_stage1_entry_7_ppn (u_page_cache_resp_bits_stage1_entry_7_ppn),
    .io_resp_bits_stage1_entry_7_ppn_low(u_page_cache_resp_bits_stage1_entry_7_ppn_low),
    .io_resp_bits_stage1_entry_7_pf  (u_page_cache_resp_bits_stage1_entry_7_pf),
    .io_resp_bits_stage1_entry_7_cf  (u_page_cache_resp_bits_stage1_entry_7_cf),
    .io_resp_bits_stage1_pteidx_0    (u_page_cache_resp_bits_stage1_pteidx_0),
    .io_resp_bits_stage1_pteidx_1    (u_page_cache_resp_bits_stage1_pteidx_1),
    .io_resp_bits_stage1_pteidx_2    (u_page_cache_resp_bits_stage1_pteidx_2),
    .io_resp_bits_stage1_pteidx_3    (u_page_cache_resp_bits_stage1_pteidx_3),
    .io_resp_bits_stage1_pteidx_4    (u_page_cache_resp_bits_stage1_pteidx_4),
    .io_resp_bits_stage1_pteidx_5    (u_page_cache_resp_bits_stage1_pteidx_5),
    .io_resp_bits_stage1_pteidx_6    (u_page_cache_resp_bits_stage1_pteidx_6),
    .io_resp_bits_stage1_pteidx_7    (u_page_cache_resp_bits_stage1_pteidx_7),
    .io_resp_bits_stage1_not_super   (u_page_cache_resp_bits_stage1_not_super),
    .io_resp_bits_isHptwReq          (u_page_cache_resp_bits_isHptwReq),
    .io_resp_bits_toHptw_l3Hit       (u_page_cache_resp_bits_toHptw_l3Hit),
    .io_resp_bits_toHptw_l2Hit       (u_page_cache_resp_bits_toHptw_l2Hit),
    .io_resp_bits_toHptw_l1Hit       (u_page_cache_resp_bits_toHptw_l1Hit),
    .io_resp_bits_toHptw_ppn         (u_page_cache_resp_bits_toHptw_ppn),
    .io_resp_bits_toHptw_id          (u_page_cache_resp_bits_toHptw_id),
    .io_resp_bits_toHptw_resp_entry_tag(u_page_cache_resp_bits_toHptw_resp_entry_tag),
    .io_resp_bits_toHptw_resp_entry_vmid(u_page_cache_resp_bits_toHptw_resp_entry_vmid),
    .io_resp_bits_toHptw_resp_entry_n(u_page_cache_resp_bits_toHptw_resp_entry_n),
    .io_resp_bits_toHptw_resp_entry_pbmt(u_page_cache_resp_bits_toHptw_resp_entry_pbmt),
    .io_resp_bits_toHptw_resp_entry_ppn(u_page_cache_resp_bits_toHptw_resp_entry_ppn),
    .io_resp_bits_toHptw_resp_entry_perm_d(u_page_cache_resp_bits_toHptw_resp_entry_perm_d),
    .io_resp_bits_toHptw_resp_entry_perm_a(u_page_cache_resp_bits_toHptw_resp_entry_perm_a),
    .io_resp_bits_toHptw_resp_entry_perm_g(u_page_cache_resp_bits_toHptw_resp_entry_perm_g),
    .io_resp_bits_toHptw_resp_entry_perm_u(u_page_cache_resp_bits_toHptw_resp_entry_perm_u),
    .io_resp_bits_toHptw_resp_entry_perm_x(u_page_cache_resp_bits_toHptw_resp_entry_perm_x),
    .io_resp_bits_toHptw_resp_entry_perm_w(u_page_cache_resp_bits_toHptw_resp_entry_perm_w),
    .io_resp_bits_toHptw_resp_entry_perm_r(u_page_cache_resp_bits_toHptw_resp_entry_perm_r),
    .io_resp_bits_toHptw_resp_entry_level(u_page_cache_resp_bits_toHptw_resp_entry_level),
    .io_resp_bits_toHptw_resp_gpf    (u_page_cache_resp_bits_toHptw_resp_gpf),
    .io_resp_bits_toHptw_bypassed    (u_page_cache_resp_bits_toHptw_bypassed),
    .io_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check(u_page_cache_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_resp_bits_toHptw_bitmapCheck_hitway(u_page_cache_resp_bits_toHptw_bitmapCheck_hitway),
    .io_resp_bits_toHptw_bitmapCheck_pte(u_page_cache_resp_bits_toHptw_bitmapCheck_pte),
    .io_resp_bits_toHptw_bitmapCheck_ptes_0(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_resp_bits_toHptw_bitmapCheck_ptes_1(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_resp_bits_toHptw_bitmapCheck_ptes_2(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_resp_bits_toHptw_bitmapCheck_ptes_3(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_resp_bits_toHptw_bitmapCheck_ptes_4(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_resp_bits_toHptw_bitmapCheck_ptes_5(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_resp_bits_toHptw_bitmapCheck_ptes_6(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_resp_bits_toHptw_bitmapCheck_ptes_7(u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_resp_bits_toHptw_bitmapCheck_fromSP(u_page_cache_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_resp_bits_toHptw_bitmapCheck_SPlevel(u_page_cache_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_refill_valid                 (u_page_cache__refill_valid),
    .io_refill_bits_ptes             (u_page_cache__refill_bits_ptes),
    .io_refill_bits_levelOH_sp       (u_page_cache__refill_bits_levelOH_sp),
    .io_refill_bits_levelOH_l0       (u_page_cache__refill_bits_levelOH_l0),
    .io_refill_bits_levelOH_l1       (u_page_cache__refill_bits_levelOH_l1),
    .io_refill_bits_levelOH_l2       (u_page_cache__refill_bits_levelOH_l2),
    .io_refill_bits_levelOH_l3       (u_page_cache__refill_bits_levelOH_l3),
    .io_refill_bits_req_info_dup_0_vpn(u_page_cache__refill_bits_req_info_dup_0_vpn),
    .io_refill_bits_req_info_dup_0_s2xlate(u_page_cache__refill_bits_req_info_dup_0_s2xlate),
    .io_refill_bits_req_info_dup_0_source(u_page_cache__refill_bits_req_info_dup_0_source),
    .io_refill_bits_req_info_dup_1_vpn(u_page_cache__refill_bits_req_info_dup_1_vpn),
    .io_refill_bits_req_info_dup_1_s2xlate(u_page_cache__refill_bits_req_info_dup_1_s2xlate),
    .io_refill_bits_req_info_dup_1_source(u_page_cache__refill_bits_req_info_dup_1_source),
    .io_refill_bits_req_info_dup_2_vpn(u_page_cache__refill_bits_req_info_dup_2_vpn),
    .io_refill_bits_req_info_dup_2_s2xlate(u_page_cache__refill_bits_req_info_dup_2_s2xlate),
    .io_refill_bits_req_info_dup_2_source(u_page_cache__refill_bits_req_info_dup_2_source),
    .io_refill_bits_level_dup_0      (u_page_cache__refill_bits_level_dup_0),
    .io_refill_bits_level_dup_2      (u_page_cache__refill_bits_level_dup_2),
    .io_refill_bits_sel_pte_dup_0    (u_page_cache__refill_bits_sel_pte_dup_0),
    .io_refill_bits_sel_pte_dup_2    (u_page_cache__refill_bits_sel_pte_dup_2),
    .io_l0_way_info                  (u_page_cache_l0_way_info),
    .io_sfence_dup_0_valid           (u_page_cache__sfence_dup_0_valid),
    .io_sfence_dup_0_bits_rs1        (u_page_cache__sfence_dup_0_bits_rs1),
    .io_sfence_dup_0_bits_rs2        (u_page_cache__sfence_dup_0_bits_rs2),
    .io_sfence_dup_0_bits_addr       (u_page_cache__sfence_dup_0_bits_addr),
    .io_sfence_dup_0_bits_id         (u_page_cache__sfence_dup_0_bits_id),
    .io_sfence_dup_0_bits_hv         (u_page_cache__sfence_dup_0_bits_hv),
    .io_sfence_dup_0_bits_hg         (u_page_cache__sfence_dup_0_bits_hg),
    .io_sfence_dup_1_valid           (u_page_cache__sfence_dup_1_valid),
    .io_sfence_dup_1_bits_id         (u_page_cache__sfence_dup_1_bits_id),
    .io_sfence_dup_2_valid           (u_page_cache__sfence_dup_2_valid),
    .io_sfence_dup_2_bits_rs1        (u_page_cache__sfence_dup_2_bits_rs1),
    .io_sfence_dup_2_bits_rs2        (u_page_cache__sfence_dup_2_bits_rs2),
    .io_sfence_dup_2_bits_id         (u_page_cache__sfence_dup_2_bits_id),
    .io_csr_dup_0_satp_asid          (u_page_cache__csr_dup_0_satp_asid),
    .io_csr_dup_0_satp_changed       (u_page_cache__csr_dup_0_satp_changed),
    .io_csr_dup_0_vsatp_asid         (u_page_cache__csr_dup_0_vsatp_asid),
    .io_csr_dup_0_vsatp_changed      (u_page_cache__csr_dup_0_vsatp_changed),
    .io_csr_dup_0_hgatp_mode         (u_page_cache__csr_dup_0_hgatp_mode),
    .io_csr_dup_0_hgatp_vmid         (u_page_cache__csr_dup_0_hgatp_vmid),
    .io_csr_dup_0_hgatp_changed      (u_page_cache__csr_dup_0_hgatp_changed),
    .io_csr_dup_0_mbmc_BME           (u_page_cache__csr_dup_0_mbmc_BME),
    .io_csr_dup_0_mbmc_CMODE         (u_page_cache__csr_dup_0_mbmc_CMODE),
    .io_csr_dup_0_priv_virt          (u_page_cache__csr_dup_0_priv_virt),
    .io_csr_dup_0_priv_virt_changed  (u_page_cache__csr_dup_0_priv_virt_changed),
    .io_csr_dup_1_satp_asid          (u_page_cache__csr_dup_1_satp_asid),
    .io_csr_dup_1_satp_changed       (u_page_cache__csr_dup_1_satp_changed),
    .io_csr_dup_1_vsatp_asid         (u_page_cache__csr_dup_1_vsatp_asid),
    .io_csr_dup_1_vsatp_changed      (u_page_cache__csr_dup_1_vsatp_changed),
    .io_csr_dup_1_hgatp_mode         (u_page_cache__csr_dup_1_hgatp_mode),
    .io_csr_dup_1_hgatp_vmid         (u_page_cache__csr_dup_1_hgatp_vmid),
    .io_csr_dup_1_hgatp_changed      (u_page_cache__csr_dup_1_hgatp_changed),
    .io_csr_dup_1_priv_virt          (u_page_cache__csr_dup_1_priv_virt),
    .io_csr_dup_1_priv_virt_changed  (u_page_cache__csr_dup_1_priv_virt_changed),
    .io_csr_dup_2_satp_asid          (u_page_cache__csr_dup_2_satp_asid),
    .io_csr_dup_2_satp_changed       (u_page_cache__csr_dup_2_satp_changed),
    .io_csr_dup_2_vsatp_asid         (u_page_cache__csr_dup_2_vsatp_asid),
    .io_csr_dup_2_vsatp_changed      (u_page_cache__csr_dup_2_vsatp_changed),
    .io_csr_dup_2_hgatp_mode         (u_page_cache__csr_dup_2_hgatp_mode),
    .io_csr_dup_2_hgatp_vmid         (u_page_cache__csr_dup_2_hgatp_vmid),
    .io_csr_dup_2_hgatp_changed      (u_page_cache__csr_dup_2_hgatp_changed),
    .io_csr_dup_2_priv_virt          (u_page_cache__csr_dup_2_priv_virt),
    .io_csr_dup_2_priv_virt_changed  (u_page_cache__csr_dup_2_priv_virt_changed),
    .io_bitmap_wakeup_ready          (u_page_cache_bitmap_wakeup_ready),
    .io_bitmap_wakeup_valid          (u_bitmap_wakeup_valid),
    .io_bitmap_wakeup_bits_setIndex  (u_bitmap_wakeup_bits_setIndex),
    .io_bitmap_wakeup_bits_tag       (u_bitmap_wakeup_bits_tag),
    .io_bitmap_wakeup_bits_way_info  (u_bitmap_wakeup_bits_way_info),
    .io_bitmap_wakeup_bits_pte_index (u_bitmap_wakeup_bits_pte_index),
    .io_bitmap_wakeup_bits_check_success(u_bitmap_wakeup_bits_check_success),
    .io_bitmap_wakeup_bits_s2xlate   (u_bitmap_wakeup_bits_s2xlate),
    .io_perf_0_value                 (u_page_cache_perf_0_value),
    .io_perf_1_value                 (u_page_cache_perf_1_value),
    .io_perf_2_value                 (u_page_cache_perf_2_value),
    .io_perf_3_value                 (u_page_cache_perf_3_value),
    .io_perf_4_value                 (u_page_cache_perf_4_value),
    .io_perf_5_value                 (u_page_cache_perf_5_value),
    .io_perf_6_value                 (u_page_cache_perf_6_value),
    .io_perf_7_value                 (u_page_cache_perf_7_value),
    .boreChildrenBd_bore_array       (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all         (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req         (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack         (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen     (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be          (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr        (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata      (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen      (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd     (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata     (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_1_array     (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_1_all       (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_1_req       (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_1_ack       (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_1_writeen   (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_1_be        (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_1_addr      (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_1_indata    (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_1_readen    (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_1_addr_rd   (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_1_outdata   (boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold      (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass    (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken  (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk   (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp  (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold  (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen          (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold    (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass  (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen        (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_2_ram_hold    (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_2_ram_bypass  (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen        (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_3_ram_hold    (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_3_ram_bypass  (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen        (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_4_ram_hold    (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_4_ram_bypass  (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen        (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_5_ram_hold    (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_5_ram_bypass  (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen        (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_6_ram_hold    (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_6_ram_bypass  (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen        (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_7_ram_hold    (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_7_ram_bypass  (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen        (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_8_ram_hold    (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_8_ram_bypass  (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen        (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_9_ram_hold    (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_9_ram_bypass  (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen        (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_10_ram_hold   (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_10_ram_bypass (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen       (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_11_ram_hold   (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_11_ram_bypass (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen       (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_12_ram_hold   (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_12_ram_bypass (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen       (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_13_ram_hold   (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_13_ram_bypass (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen       (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_14_ram_hold   (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_14_ram_bypass (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen       (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_15_ram_hold   (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_15_ram_bypass (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen       (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_16_ram_hold   (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_16_ram_bypass (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen       (sigFromSrams_bore_20_cgen),
    .cg_bore_cgen                    (cg_bore_1_cgen)
  );

  PTW u_ptw (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_ptw__sfence_valid),
    .io_csr_satp_mode                (u_ptw__csr_satp_mode),
    .io_csr_satp_asid                (u_ptw__csr_satp_asid),
    .io_csr_satp_ppn                 (u_ptw__csr_satp_ppn),
    .io_csr_satp_changed             (u_ptw__csr_satp_changed),
    .io_csr_vsatp_mode               (u_ptw__csr_vsatp_mode),
    .io_csr_vsatp_asid               (u_ptw__csr_vsatp_asid),
    .io_csr_vsatp_ppn                (u_ptw__csr_vsatp_ppn),
    .io_csr_vsatp_changed            (u_ptw__csr_vsatp_changed),
    .io_csr_hgatp_mode               (u_ptw__csr_hgatp_mode),
    .io_csr_hgatp_vmid               (u_ptw__csr_hgatp_vmid),
    .io_csr_hgatp_changed            (u_ptw__csr_hgatp_changed),
    .io_csr_mbmc_BME                 (u_ptw__csr_mbmc_BME),
    .io_csr_mbmc_CMODE               (u_ptw__csr_mbmc_CMODE),
    .io_csr_priv_virt_changed        (u_ptw__csr_priv_virt_changed),
    .io_csr_mPBMTE                   (u_ptw__csr_mPBMTE),
    .io_csr_hPBMTE                   (u_ptw__csr_hPBMTE),
    .io_req_ready                    (u_ptw_req_ready),
    .io_req_valid                    (u_ptw__req_valid),
    .io_req_bits_req_info_vpn        (u_page_cache_resp_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate    (u_page_cache_resp_bits_req_info_s2xlate),
    .io_req_bits_req_info_source     (u_page_cache_resp_bits_req_info_source),
    .io_req_bits_l3Hit               (u_page_cache_resp_bits_toFsm_l3Hit),
    .io_req_bits_l2Hit               (u_page_cache_resp_bits_toFsm_l2Hit),
    .io_req_bits_ppn                 (u_ptw__req_bits_ppn),
    .io_req_bits_stage1Hit           (u_page_cache_resp_bits_toFsm_stage1Hit),
    .io_req_bits_stage1_entry_0_tag  (u_page_cache_resp_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid (u_page_cache_resp_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid (u_page_cache_resp_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n    (u_page_cache_resp_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt (u_page_cache_resp_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d(u_page_cache_resp_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a(u_page_cache_resp_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g(u_page_cache_resp_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u(u_page_cache_resp_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x(u_page_cache_resp_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w(u_page_cache_resp_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r(u_page_cache_resp_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level(u_page_cache_resp_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v    (u_page_cache_resp_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn  (u_page_cache_resp_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low(u_page_cache_resp_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf   (u_page_cache_resp_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_0_cf   (u_page_cache_resp_bits_stage1_entry_0_cf),
    .io_req_bits_stage1_entry_1_tag  (u_page_cache_resp_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid (u_page_cache_resp_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid (u_page_cache_resp_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n    (u_page_cache_resp_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt (u_page_cache_resp_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d(u_page_cache_resp_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a(u_page_cache_resp_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g(u_page_cache_resp_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u(u_page_cache_resp_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x(u_page_cache_resp_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w(u_page_cache_resp_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r(u_page_cache_resp_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level(u_page_cache_resp_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v    (u_page_cache_resp_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn  (u_page_cache_resp_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low(u_page_cache_resp_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf   (u_page_cache_resp_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_1_cf   (u_page_cache_resp_bits_stage1_entry_1_cf),
    .io_req_bits_stage1_entry_2_tag  (u_page_cache_resp_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid (u_page_cache_resp_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid (u_page_cache_resp_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n    (u_page_cache_resp_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt (u_page_cache_resp_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d(u_page_cache_resp_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a(u_page_cache_resp_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g(u_page_cache_resp_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u(u_page_cache_resp_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x(u_page_cache_resp_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w(u_page_cache_resp_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r(u_page_cache_resp_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level(u_page_cache_resp_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v    (u_page_cache_resp_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn  (u_page_cache_resp_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low(u_page_cache_resp_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf   (u_page_cache_resp_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_2_cf   (u_page_cache_resp_bits_stage1_entry_2_cf),
    .io_req_bits_stage1_entry_3_tag  (u_page_cache_resp_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid (u_page_cache_resp_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid (u_page_cache_resp_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n    (u_page_cache_resp_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt (u_page_cache_resp_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d(u_page_cache_resp_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a(u_page_cache_resp_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g(u_page_cache_resp_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u(u_page_cache_resp_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x(u_page_cache_resp_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w(u_page_cache_resp_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r(u_page_cache_resp_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level(u_page_cache_resp_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v    (u_page_cache_resp_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn  (u_page_cache_resp_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low(u_page_cache_resp_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf   (u_page_cache_resp_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_3_cf   (u_page_cache_resp_bits_stage1_entry_3_cf),
    .io_req_bits_stage1_entry_4_tag  (u_page_cache_resp_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid (u_page_cache_resp_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid (u_page_cache_resp_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n    (u_page_cache_resp_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt (u_page_cache_resp_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d(u_page_cache_resp_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a(u_page_cache_resp_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g(u_page_cache_resp_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u(u_page_cache_resp_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x(u_page_cache_resp_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w(u_page_cache_resp_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r(u_page_cache_resp_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level(u_page_cache_resp_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v    (u_page_cache_resp_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn  (u_page_cache_resp_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low(u_page_cache_resp_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf   (u_page_cache_resp_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_4_cf   (u_page_cache_resp_bits_stage1_entry_4_cf),
    .io_req_bits_stage1_entry_5_tag  (u_page_cache_resp_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid (u_page_cache_resp_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid (u_page_cache_resp_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n    (u_page_cache_resp_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt (u_page_cache_resp_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d(u_page_cache_resp_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a(u_page_cache_resp_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g(u_page_cache_resp_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u(u_page_cache_resp_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x(u_page_cache_resp_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w(u_page_cache_resp_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r(u_page_cache_resp_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level(u_page_cache_resp_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v    (u_page_cache_resp_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn  (u_page_cache_resp_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low(u_page_cache_resp_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf   (u_page_cache_resp_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_5_cf   (u_page_cache_resp_bits_stage1_entry_5_cf),
    .io_req_bits_stage1_entry_6_tag  (u_page_cache_resp_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid (u_page_cache_resp_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid (u_page_cache_resp_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n    (u_page_cache_resp_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt (u_page_cache_resp_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d(u_page_cache_resp_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a(u_page_cache_resp_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g(u_page_cache_resp_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u(u_page_cache_resp_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x(u_page_cache_resp_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w(u_page_cache_resp_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r(u_page_cache_resp_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level(u_page_cache_resp_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v    (u_page_cache_resp_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn  (u_page_cache_resp_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low(u_page_cache_resp_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf   (u_page_cache_resp_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_6_cf   (u_page_cache_resp_bits_stage1_entry_6_cf),
    .io_req_bits_stage1_entry_7_tag  (u_page_cache_resp_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid (u_page_cache_resp_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid (u_page_cache_resp_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n    (u_page_cache_resp_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt (u_page_cache_resp_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d(u_page_cache_resp_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a(u_page_cache_resp_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g(u_page_cache_resp_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u(u_page_cache_resp_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x(u_page_cache_resp_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w(u_page_cache_resp_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r(u_page_cache_resp_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level(u_page_cache_resp_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v    (u_page_cache_resp_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn  (u_page_cache_resp_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low(u_page_cache_resp_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf   (u_page_cache_resp_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_entry_7_cf   (u_page_cache_resp_bits_stage1_entry_7_cf),
    .io_req_bits_stage1_pteidx_0     (u_page_cache_resp_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1     (u_page_cache_resp_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2     (u_page_cache_resp_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3     (u_page_cache_resp_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4     (u_page_cache_resp_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5     (u_page_cache_resp_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6     (u_page_cache_resp_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7     (u_page_cache_resp_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super    (u_page_cache_resp_bits_stage1_not_super),
    .io_req_bits_bitmapCheck_jmp_bitmap_check(u_page_cache_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte     (u_page_cache_resp_bits_toFsm_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_SPlevel (u_page_cache_resp_bits_toFsm_bitmapCheck_SPlevel),
    .io_resp_ready                   (u_ptw__resp_ready),
    .io_resp_valid                   (u_ptw_resp_valid),
    .io_resp_bits_source             (u_ptw_resp_bits_source),
    .io_resp_bits_s2xlate            (u_ptw_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag   (u_ptw_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid  (u_ptw_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid  (u_ptw_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n     (u_ptw_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt  (u_ptw_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d(u_ptw_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a(u_ptw_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g(u_ptw_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u(u_ptw_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x(u_ptw_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w(u_ptw_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r(u_ptw_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level (u_ptw_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v     (u_ptw_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn   (u_ptw_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low(u_ptw_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af    (u_ptw_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf    (u_ptw_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_0_cf    (u_ptw_resp_bits_resp_entry_0_cf),
    .io_resp_bits_resp_entry_1_tag   (u_ptw_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid  (u_ptw_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid  (u_ptw_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n     (u_ptw_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt  (u_ptw_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d(u_ptw_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a(u_ptw_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g(u_ptw_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u(u_ptw_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x(u_ptw_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w(u_ptw_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r(u_ptw_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level (u_ptw_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v     (u_ptw_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn   (u_ptw_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low(u_ptw_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af    (u_ptw_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf    (u_ptw_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_1_cf    (u_ptw_resp_bits_resp_entry_1_cf),
    .io_resp_bits_resp_entry_2_tag   (u_ptw_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid  (u_ptw_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid  (u_ptw_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n     (u_ptw_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt  (u_ptw_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d(u_ptw_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a(u_ptw_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g(u_ptw_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u(u_ptw_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x(u_ptw_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w(u_ptw_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r(u_ptw_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level (u_ptw_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v     (u_ptw_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn   (u_ptw_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low(u_ptw_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af    (u_ptw_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf    (u_ptw_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_2_cf    (u_ptw_resp_bits_resp_entry_2_cf),
    .io_resp_bits_resp_entry_3_tag   (u_ptw_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid  (u_ptw_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid  (u_ptw_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n     (u_ptw_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt  (u_ptw_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d(u_ptw_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a(u_ptw_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g(u_ptw_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u(u_ptw_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x(u_ptw_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w(u_ptw_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r(u_ptw_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level (u_ptw_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v     (u_ptw_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn   (u_ptw_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low(u_ptw_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af    (u_ptw_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf    (u_ptw_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_3_cf    (u_ptw_resp_bits_resp_entry_3_cf),
    .io_resp_bits_resp_entry_4_tag   (u_ptw_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid  (u_ptw_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid  (u_ptw_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n     (u_ptw_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt  (u_ptw_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d(u_ptw_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a(u_ptw_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g(u_ptw_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u(u_ptw_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x(u_ptw_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w(u_ptw_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r(u_ptw_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level (u_ptw_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v     (u_ptw_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn   (u_ptw_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low(u_ptw_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af    (u_ptw_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf    (u_ptw_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_4_cf    (u_ptw_resp_bits_resp_entry_4_cf),
    .io_resp_bits_resp_entry_5_tag   (u_ptw_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid  (u_ptw_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid  (u_ptw_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n     (u_ptw_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt  (u_ptw_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d(u_ptw_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a(u_ptw_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g(u_ptw_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u(u_ptw_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x(u_ptw_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w(u_ptw_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r(u_ptw_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level (u_ptw_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v     (u_ptw_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn   (u_ptw_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low(u_ptw_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af    (u_ptw_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf    (u_ptw_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_5_cf    (u_ptw_resp_bits_resp_entry_5_cf),
    .io_resp_bits_resp_entry_6_tag   (u_ptw_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid  (u_ptw_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid  (u_ptw_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n     (u_ptw_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt  (u_ptw_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d(u_ptw_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a(u_ptw_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g(u_ptw_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u(u_ptw_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x(u_ptw_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w(u_ptw_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r(u_ptw_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level (u_ptw_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v     (u_ptw_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn   (u_ptw_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low(u_ptw_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af    (u_ptw_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf    (u_ptw_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_6_cf    (u_ptw_resp_bits_resp_entry_6_cf),
    .io_resp_bits_resp_entry_7_tag   (u_ptw_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid  (u_ptw_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid  (u_ptw_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n     (u_ptw_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt  (u_ptw_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d(u_ptw_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a(u_ptw_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g(u_ptw_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u(u_ptw_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x(u_ptw_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w(u_ptw_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r(u_ptw_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level (u_ptw_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v     (u_ptw_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn   (u_ptw_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low(u_ptw_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af    (u_ptw_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf    (u_ptw_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_entry_7_cf    (u_ptw_resp_bits_resp_entry_7_cf),
    .io_resp_bits_resp_pteidx_0      (u_ptw_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1      (u_ptw_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2      (u_ptw_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3      (u_ptw_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4      (u_ptw_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5      (u_ptw_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6      (u_ptw_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7      (u_ptw_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super     (u_ptw_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag   (u_ptw_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid  (u_ptw_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n     (u_ptw_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt  (u_ptw_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn   (u_ptw_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d(u_ptw_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a(u_ptw_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g(u_ptw_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u(u_ptw_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x(u_ptw_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w(u_ptw_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r(u_ptw_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level (u_ptw_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf         (u_ptw_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf         (u_ptw_resp_bits_h_resp_gaf),
    .io_llptw_ready                  (u_arb_cache_in_in_1_ready),
    .io_llptw_valid                  (u_ptw_llptw_valid),
    .io_llptw_bits_req_info_vpn      (u_ptw_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate  (u_ptw_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source   (u_ptw_llptw_bits_req_info_source),
    .io_hptw_req_ready               (u_arb_hptw_req_in_0_ready),
    .io_hptw_req_valid               (u_ptw_hptw_req_valid),
    .io_hptw_req_bits_source         (u_ptw_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn           (u_ptw_hptw_req_bits_gvpn),
    .io_hptw_resp_valid              (u_ptw__hptw_resp_valid),
    .io_hptw_resp_bits_h_resp_entry_tag(u_arb_hptw_resp_out_bits_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid(u_arb_hptw_resp_out_bits_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n(u_arb_hptw_resp_out_bits_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt(u_arb_hptw_resp_out_bits_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn(u_arb_hptw_resp_out_bits_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d(u_arb_hptw_resp_out_bits_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a(u_arb_hptw_resp_out_bits_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g(u_arb_hptw_resp_out_bits_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u(u_arb_hptw_resp_out_bits_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x(u_arb_hptw_resp_out_bits_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w(u_arb_hptw_resp_out_bits_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r(u_arb_hptw_resp_out_bits_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level(u_arb_hptw_resp_out_bits_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf    (u_arb_hptw_resp_out_bits_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf    (u_arb_hptw_resp_out_bits_resp_gaf),
    .io_mem_req_ready                (u_mem_arb_in_0_ready),
    .io_mem_req_valid                (u_ptw_mem_req_valid),
    .io_mem_req_bits_addr            (u_ptw_mem_req_bits_addr),
    .io_mem_resp_valid               (u_ptw__mem_resp_valid),
    .io_mem_resp_bits                (u_ptw__mem_resp_bits),
    .io_mem_mask                     (u_ptw__mem_mask),
    .io_pmp_req_bits_addr            (u_ptw_pmp_req_bits_addr),
    .io_pmp_resp_ld                  (u_pmp_chk_ptw_resp_ld),
    .io_pmp_resp_mmio                (u_pmp_chk_ptw_resp_mmio),
    .io_refill_req_info_vpn          (u_ptw_refill_req_info_vpn),
    .io_refill_req_info_s2xlate      (u_ptw_refill_req_info_s2xlate),
    .io_refill_req_info_source       (u_ptw_refill_req_info_source),
    .io_refill_level                 (u_ptw_refill_level),
    .io_bitmap_req_ready             (u_bitmap_arb_in_0_ready),
    .io_bitmap_req_valid             (u_ptw_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn        (u_ptw_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn          (u_ptw_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level        (u_ptw_bitmap_req_bits_level),
    .io_bitmap_req_bits_s2xlate      (u_ptw_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n            (u_ptw_bitmap_req_bits_n),
    .io_bitmap_resp_ready            (u_ptw_bitmap_resp_ready),
    .io_bitmap_resp_valid            (u_ptw__bitmap_resp_valid),
    .io_bitmap_resp_bits_cf          (u_bitmap_resp_bits_cf),
    .io_perf_0_value                 (u_ptw_perf_0_value),
    .io_perf_1_value                 (u_ptw_perf_1_value),
    .io_perf_2_value                 (u_ptw_perf_2_value),
    .io_perf_3_value                 (u_ptw_perf_3_value),
    .io_perf_4_value                 (u_ptw_perf_4_value),
    .io_perf_5_value                 (u_ptw_perf_5_value),
    .io_perf_6_value                 (u_ptw_perf_6_value)
  );

  HPTW u_hptw (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_hptw__sfence_valid),
    .io_csr_satp_changed             (u_hptw__csr_satp_changed),
    .io_csr_vsatp_changed            (u_hptw__csr_vsatp_changed),
    .io_csr_hgatp_mode               (u_hptw__csr_hgatp_mode),
    .io_csr_hgatp_vmid               (u_hptw__csr_hgatp_vmid),
    .io_csr_hgatp_ppn                (u_hptw__csr_hgatp_ppn),
    .io_csr_hgatp_changed            (u_hptw__csr_hgatp_changed),
    .io_csr_mbmc_BME                 (u_hptw__csr_mbmc_BME),
    .io_csr_mbmc_CMODE               (u_hptw__csr_mbmc_CMODE),
    .io_csr_priv_virt_changed        (u_hptw__csr_priv_virt_changed),
    .io_csr_mPBMTE                   (u_hptw__csr_mPBMTE),
    .io_req_ready                    (u_hptw_req_ready),
    .io_req_valid                    (u_hptw__req_valid),
    .io_req_bits_source              (u_page_cache_resp_bits_req_info_source),
    .io_req_bits_id                  (u_page_cache_resp_bits_toHptw_id),
    .io_req_bits_gvpn                (u_page_cache_resp_bits_req_info_vpn),
    .io_req_bits_ppn                 (u_page_cache_resp_bits_toHptw_ppn),
    .io_req_bits_l3Hit               (u_page_cache_resp_bits_toHptw_l3Hit),
    .io_req_bits_l2Hit               (u_page_cache_resp_bits_toHptw_l2Hit),
    .io_req_bits_l1Hit               (u_page_cache_resp_bits_toHptw_l1Hit),
    .io_req_bits_bypassed            (u_page_cache_resp_bits_toHptw_bypassed),
    .io_req_bits_bitmapCheck_jmp_bitmap_check(u_page_cache_resp_bits_toHptw_bitmapCheck_jmp_bitmap_check),
    .io_req_bits_bitmapCheck_pte     (u_page_cache_resp_bits_toHptw_bitmapCheck_pte),
    .io_req_bits_bitmapCheck_ptes_0  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_0),
    .io_req_bits_bitmapCheck_ptes_1  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_1),
    .io_req_bits_bitmapCheck_ptes_2  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_2),
    .io_req_bits_bitmapCheck_ptes_3  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_3),
    .io_req_bits_bitmapCheck_ptes_4  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_4),
    .io_req_bits_bitmapCheck_ptes_5  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_5),
    .io_req_bits_bitmapCheck_ptes_6  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_6),
    .io_req_bits_bitmapCheck_ptes_7  (u_page_cache_resp_bits_toHptw_bitmapCheck_ptes_7),
    .io_req_bits_bitmapCheck_hitway  (u_page_cache_resp_bits_toHptw_bitmapCheck_hitway),
    .io_req_bits_bitmapCheck_fromSP  (u_page_cache_resp_bits_toHptw_bitmapCheck_fromSP),
    .io_req_bits_bitmapCheck_SPlevel (u_page_cache_resp_bits_toHptw_bitmapCheck_SPlevel),
    .io_resp_ready                   (u_arb_hptw_resp_in_1_ready),
    .io_resp_valid                   (u_hptw_resp_valid),
    .io_resp_bits_resp_entry_tag     (u_hptw_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid    (u_hptw_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n       (u_hptw_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt    (u_hptw_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn     (u_hptw_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d  (u_hptw_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a  (u_hptw_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g  (u_hptw_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u  (u_hptw_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x  (u_hptw_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w  (u_hptw_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r  (u_hptw_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level   (u_hptw_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf           (u_hptw_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf           (u_hptw_resp_bits_resp_gaf),
    .io_resp_bits_id                 (u_hptw_resp_bits_id),
    .io_mem_req_ready                (u_mem_arb_in_2_ready),
    .io_mem_req_valid                (u_hptw_mem_req_valid),
    .io_mem_req_bits_addr            (u_hptw_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed   (u_hptw_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid               (u_hptw__mem_resp_valid),
    .io_mem_resp_bits                (u_hptw__mem_resp_bits),
    .io_mem_mask                     (u_hptw__mem_mask),
    .io_refill_req_info_vpn          (u_hptw_refill_req_info_vpn),
    .io_refill_req_info_source       (u_hptw_refill_req_info_source),
    .io_refill_level                 (u_hptw_refill_level),
    .io_pmp_req_bits_addr            (u_hptw_pmp_req_bits_addr),
    .io_pmp_resp_ld                  (u_pmp_chk_hptw_resp_ld),
    .io_pmp_resp_mmio                (u_pmp_chk_hptw_resp_mmio),
    .io_bitmap_req_ready             (u_bitmap_arb_in_2_ready),
    .io_bitmap_req_valid             (u_hptw_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn        (u_hptw_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_vpn          (u_hptw_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_level        (u_hptw_bitmap_req_bits_level),
    .io_bitmap_req_bits_way_info     (u_hptw_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_hptw_bypassed(u_hptw_bitmap_req_bits_hptw_bypassed),
    .io_bitmap_req_bits_n            (u_hptw_bitmap_req_bits_n),
    .io_bitmap_resp_ready            (u_hptw_bitmap_resp_ready),
    .io_bitmap_resp_valid            (u_hptw__bitmap_resp_valid),
    .io_bitmap_resp_bits_cf          (u_bitmap_resp_bits_cf),
    .io_l0_way_info                  (u_page_cache_l0_way_info)
  );

  LLPTW u_llptw (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_llptw__sfence_valid),
    .io_csr_satp_changed             (u_llptw__csr_satp_changed),
    .io_csr_vsatp_changed            (u_llptw__csr_vsatp_changed),
    .io_csr_hgatp_mode               (u_llptw__csr_hgatp_mode),
    .io_csr_hgatp_changed            (u_llptw__csr_hgatp_changed),
    .io_csr_mbmc_BME                 (u_llptw__csr_mbmc_BME),
    .io_csr_mbmc_CMODE               (u_llptw__csr_mbmc_CMODE),
    .io_csr_priv_virt_changed        (u_llptw__csr_priv_virt_changed),
    .io_csr_mPBMTE                   (u_llptw__csr_mPBMTE),
    .io_csr_hPBMTE                   (u_llptw__csr_hPBMTE),
    .io_in_ready                     (u_llptw_in_ready),
    .io_in_valid                     (u_llptw__in_valid),
    .io_in_bits_req_info_vpn         (u_page_cache_resp_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate     (u_page_cache_resp_bits_req_info_s2xlate),
    .io_in_bits_req_info_source      (u_page_cache_resp_bits_req_info_source),
    .io_in_bits_ppn                  (u_llptw__in_bits_ppn),
    .io_in_bits_bitmapCheck_jmp_bitmap_check(u_page_cache_resp_bits_toFsm_bitmapCheck_jmp_bitmap_check),
    .io_in_bits_bitmapCheck_ptes_0   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_0),
    .io_in_bits_bitmapCheck_ptes_1   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_1),
    .io_in_bits_bitmapCheck_ptes_2   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_2),
    .io_in_bits_bitmapCheck_ptes_3   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_3),
    .io_in_bits_bitmapCheck_ptes_4   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_4),
    .io_in_bits_bitmapCheck_ptes_5   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_5),
    .io_in_bits_bitmapCheck_ptes_6   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_6),
    .io_in_bits_bitmapCheck_ptes_7   (u_page_cache_resp_bits_toFsm_bitmapCheck_ptes_7),
    .io_in_bits_bitmapCheck_cfs_0    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_0),
    .io_in_bits_bitmapCheck_cfs_1    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_1),
    .io_in_bits_bitmapCheck_cfs_2    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_2),
    .io_in_bits_bitmapCheck_cfs_3    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_3),
    .io_in_bits_bitmapCheck_cfs_4    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_4),
    .io_in_bits_bitmapCheck_cfs_5    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_5),
    .io_in_bits_bitmapCheck_cfs_6    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_6),
    .io_in_bits_bitmapCheck_cfs_7    (u_page_cache_resp_bits_toFsm_bitmapCheck_cfs_7),
    .io_in_bits_bitmapCheck_hitway   (u_page_cache_resp_bits_toFsm_bitmapCheck_hitway),
    .io_out_ready                    (u_llptw__out_ready),
    .io_out_valid                    (u_llptw_out_valid),
    .io_out_bits_req_info_vpn        (u_llptw_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate    (u_llptw_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source     (u_llptw_out_bits_req_info_source),
    .io_out_bits_id                  (u_llptw_out_bits_id),
    .io_out_bits_h_resp_entry_tag    (u_llptw_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid   (u_llptw_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n      (u_llptw_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt   (u_llptw_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn    (u_llptw_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d (u_llptw_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a (u_llptw_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g (u_llptw_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u (u_llptw_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x (u_llptw_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w (u_llptw_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r (u_llptw_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level  (u_llptw_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf          (u_llptw_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf          (u_llptw_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault (u_llptw_out_bits_first_s2xlate_fault),
    .io_out_bits_af                  (u_llptw_out_bits_af),
    .io_out_bits_bitmapCheck_jmp_bitmap_check(u_llptw_out_bits_bitmapCheck_jmp_bitmap_check),
    .io_out_bits_bitmapCheck_ptes_0  (u_llptw_out_bits_bitmapCheck_ptes_0),
    .io_out_bits_bitmapCheck_ptes_1  (u_llptw_out_bits_bitmapCheck_ptes_1),
    .io_out_bits_bitmapCheck_ptes_2  (u_llptw_out_bits_bitmapCheck_ptes_2),
    .io_out_bits_bitmapCheck_ptes_3  (u_llptw_out_bits_bitmapCheck_ptes_3),
    .io_out_bits_bitmapCheck_ptes_4  (u_llptw_out_bits_bitmapCheck_ptes_4),
    .io_out_bits_bitmapCheck_ptes_5  (u_llptw_out_bits_bitmapCheck_ptes_5),
    .io_out_bits_bitmapCheck_ptes_6  (u_llptw_out_bits_bitmapCheck_ptes_6),
    .io_out_bits_bitmapCheck_ptes_7  (u_llptw_out_bits_bitmapCheck_ptes_7),
    .io_out_bits_bitmapCheck_cfs_0   (u_llptw_out_bits_bitmapCheck_cfs_0),
    .io_out_bits_bitmapCheck_cfs_1   (u_llptw_out_bits_bitmapCheck_cfs_1),
    .io_out_bits_bitmapCheck_cfs_2   (u_llptw_out_bits_bitmapCheck_cfs_2),
    .io_out_bits_bitmapCheck_cfs_3   (u_llptw_out_bits_bitmapCheck_cfs_3),
    .io_out_bits_bitmapCheck_cfs_4   (u_llptw_out_bits_bitmapCheck_cfs_4),
    .io_out_bits_bitmapCheck_cfs_5   (u_llptw_out_bits_bitmapCheck_cfs_5),
    .io_out_bits_bitmapCheck_cfs_6   (u_llptw_out_bits_bitmapCheck_cfs_6),
    .io_out_bits_bitmapCheck_cfs_7   (u_llptw_out_bits_bitmapCheck_cfs_7),
    .io_mem_req_ready                (u_mem_arb_in_1_ready),
    .io_mem_req_valid                (u_llptw_mem_req_valid),
    .io_mem_req_bits_addr            (u_llptw_mem_req_bits_addr),
    .io_mem_req_bits_id              (u_llptw_mem_req_bits_id),
    .io_mem_resp_valid               (u_llptw__mem_resp_valid),
    .io_mem_resp_bits_id             (u_llptw__mem_resp_bits_id),
    .io_mem_resp_bits_value          (u_llptw__mem_resp_bits_value),
    .io_mem_enq_ptr                  (u_llptw_mem_enq_ptr),
    .io_mem_buffer_it_0              (u_llptw_mem_buffer_it_0),
    .io_mem_buffer_it_1              (u_llptw_mem_buffer_it_1),
    .io_mem_buffer_it_2              (u_llptw_mem_buffer_it_2),
    .io_mem_buffer_it_3              (u_llptw_mem_buffer_it_3),
    .io_mem_buffer_it_4              (u_llptw_mem_buffer_it_4),
    .io_mem_buffer_it_5              (u_llptw_mem_buffer_it_5),
    .io_mem_refill_vpn               (u_llptw_mem_refill_vpn),
    .io_mem_refill_s2xlate           (u_llptw_mem_refill_s2xlate),
    .io_mem_refill_source            (u_llptw_mem_refill_source),
    .io_mem_req_mask_0               (u_llptw__mem_req_mask_0),
    .io_mem_req_mask_1               (u_llptw__mem_req_mask_1),
    .io_mem_req_mask_2               (u_llptw__mem_req_mask_2),
    .io_mem_req_mask_3               (u_llptw__mem_req_mask_3),
    .io_mem_req_mask_4               (u_llptw__mem_req_mask_4),
    .io_mem_req_mask_5               (u_llptw__mem_req_mask_5),
    .io_mem_flush_latch_0            (u_llptw__mem_flush_latch_0),
    .io_mem_flush_latch_1            (u_llptw__mem_flush_latch_1),
    .io_mem_flush_latch_2            (u_llptw__mem_flush_latch_2),
    .io_mem_flush_latch_3            (u_llptw__mem_flush_latch_3),
    .io_mem_flush_latch_4            (u_llptw__mem_flush_latch_4),
    .io_mem_flush_latch_5            (u_llptw__mem_flush_latch_5),
    .io_cache_ready                  (u_arb_mq_in_1_ready),
    .io_cache_valid                  (u_llptw_cache_valid),
    .io_cache_bits_vpn               (u_llptw_cache_bits_vpn),
    .io_cache_bits_s2xlate           (u_llptw_cache_bits_s2xlate),
    .io_cache_bits_source            (u_llptw_cache_bits_source),
    .io_pmp_0_req_bits_addr          (u_llptw_pmp_0_req_bits_addr),
    .io_pmp_0_resp_ld                (u_pmp_chk_llptw0_resp_ld),
    .io_pmp_0_resp_mmio              (u_pmp_chk_llptw0_resp_mmio),
    .io_pmp_1_req_bits_addr          (u_llptw_pmp_1_req_bits_addr),
    .io_pmp_1_resp_ld                (u_pmp_chk_llptw1_resp_ld),
    .io_pmp_1_resp_mmio              (u_pmp_chk_llptw1_resp_mmio),
    .io_hptw_req_ready               (u_arb_hptw_req_in_1_ready),
    .io_hptw_req_valid               (u_llptw_hptw_req_valid),
    .io_hptw_req_bits_source         (u_llptw_hptw_req_bits_source),
    .io_hptw_req_bits_id             (u_llptw_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn           (u_llptw_hptw_req_bits_gvpn),
    .io_hptw_resp_valid              (u_llptw__hptw_resp_valid),
    .io_hptw_resp_bits_id            (u_arb_hptw_resp_out_bits_id),
    .io_hptw_resp_bits_h_resp_entry_tag(u_arb_hptw_resp_out_bits_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid(u_arb_hptw_resp_out_bits_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n(u_arb_hptw_resp_out_bits_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt(u_arb_hptw_resp_out_bits_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn(u_arb_hptw_resp_out_bits_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d(u_arb_hptw_resp_out_bits_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a(u_arb_hptw_resp_out_bits_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g(u_arb_hptw_resp_out_bits_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u(u_arb_hptw_resp_out_bits_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x(u_arb_hptw_resp_out_bits_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w(u_arb_hptw_resp_out_bits_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r(u_arb_hptw_resp_out_bits_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level(u_arb_hptw_resp_out_bits_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf    (u_arb_hptw_resp_out_bits_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf    (u_arb_hptw_resp_out_bits_resp_gaf),
    .io_bitmap_req_ready             (u_bitmap_arb_in_1_ready),
    .io_bitmap_req_valid             (u_llptw_bitmap_req_valid),
    .io_bitmap_req_bits_bmppn        (u_llptw_bitmap_req_bits_bmppn),
    .io_bitmap_req_bits_id           (u_llptw_bitmap_req_bits_id),
    .io_bitmap_req_bits_vpn          (u_llptw_bitmap_req_bits_vpn),
    .io_bitmap_req_bits_way_info     (u_llptw_bitmap_req_bits_way_info),
    .io_bitmap_req_bits_s2xlate      (u_llptw_bitmap_req_bits_s2xlate),
    .io_bitmap_req_bits_n            (u_llptw_bitmap_req_bits_n),
    .io_bitmap_resp_ready            (u_llptw_bitmap_resp_ready),
    .io_bitmap_resp_valid            (u_llptw__bitmap_resp_valid),
    .io_bitmap_resp_bits_cf          (u_bitmap_resp_bits_cf),
    .io_bitmap_resp_bits_cfs_0       (u_bitmap_resp_bits_cfs_0),
    .io_bitmap_resp_bits_cfs_1       (u_bitmap_resp_bits_cfs_1),
    .io_bitmap_resp_bits_cfs_2       (u_bitmap_resp_bits_cfs_2),
    .io_bitmap_resp_bits_cfs_3       (u_bitmap_resp_bits_cfs_3),
    .io_bitmap_resp_bits_cfs_4       (u_bitmap_resp_bits_cfs_4),
    .io_bitmap_resp_bits_cfs_5       (u_bitmap_resp_bits_cfs_5),
    .io_bitmap_resp_bits_cfs_6       (u_bitmap_resp_bits_cfs_6),
    .io_bitmap_resp_bits_cfs_7       (u_bitmap_resp_bits_cfs_7),
    .io_bitmap_resp_bits_id          (u_bitmap_resp_bits_id),
    .io_l0_way_info                  (u_page_cache_l0_way_info),
    .io_perf_0_value                 (u_llptw_perf_0_value),
    .io_perf_1_value                 (u_llptw_perf_1_value),
    .io_perf_2_value                 (u_llptw_perf_2_value),
    .io_perf_3_value                 (u_llptw_perf_3_value)
  );

  Arbiter2_PtwReq u_arb_tlb (
    .io_in_0_ready                   (u_arb_tlb_in_0_ready),
    .io_in_0_valid                   (io_tlb_0_req_0_valid),
    .io_in_0_bits_vpn                (io_tlb_0_req_0_bits_vpn),
    .io_in_0_bits_s2xlate            (io_tlb_0_req_0_bits_s2xlate),
    .io_in_1_ready                   (u_arb_tlb_in_1_ready),
    .io_in_1_valid                   (io_tlb_1_req_0_valid),
    .io_in_1_bits_vpn                (io_tlb_1_req_0_bits_vpn),
    .io_in_1_bits_s2xlate            (io_tlb_1_req_0_bits_s2xlate),
    .io_out_ready                    (u_arb_tlb__out_ready),
    .io_out_valid                    (u_arb_tlb_out_valid),
    .io_out_bits_vpn                 (u_arb_tlb_out_bits_vpn),
    .io_out_bits_s2xlate             (u_arb_tlb_out_bits_s2xlate),
    .io_chosen                       (u_arb_tlb_chosen)
  );

  Arbiter5_L2TlbWithHptwIdBundle u_arb_cache_in (
    .io_in_0_ready                   (u_arb_cache_in_in_0_ready),
    .io_in_0_valid                   (u_arb_hptw_req_out_valid),
    .io_in_0_bits_req_info_vpn       (u_arb_hptw_req_out_bits_gvpn),
    .io_in_0_bits_req_info_source    (u_arb_hptw_req_out_bits_source),
    .io_in_0_bits_hptwId             (u_arb_hptw_req_out_bits_id),
    .io_in_1_ready                   (u_arb_cache_in_in_1_ready),
    .io_in_1_valid                   (u_ptw_llptw_valid),
    .io_in_1_bits_req_info_vpn       (u_ptw_llptw_bits_req_info_vpn),
    .io_in_1_bits_req_info_s2xlate   (u_ptw_llptw_bits_req_info_s2xlate),
    .io_in_1_bits_req_info_source    (u_ptw_llptw_bits_req_info_source),
    .io_in_2_ready                   (u_arb_cache_in_in_2_ready),
    .io_in_2_valid                   (u_arb_cache_in__in_2_valid),
    .io_in_2_bits_req_info_vpn       (u_miss_queue_out_bits_req_info_vpn),
    .io_in_2_bits_req_info_s2xlate   (u_miss_queue_out_bits_req_info_s2xlate),
    .io_in_2_bits_req_info_source    (u_miss_queue_out_bits_req_info_source),
    .io_in_2_bits_isHptwReq          (u_miss_queue_out_bits_isHptwReq),
    .io_in_2_bits_hptwId             (u_miss_queue_out_bits_hptwId),
    .io_in_3_ready                   (u_arb_cache_in_in_3_ready),
    .io_in_3_valid                   (u_arb_cache_in__in_3_valid),
    .io_in_3_bits_req_info_vpn       (u_arb_tlb_out_bits_vpn),
    .io_in_3_bits_req_info_s2xlate   (u_arb_tlb_out_bits_s2xlate),
    .io_in_3_bits_req_info_source    (u_arb_cache_in__in_3_bits_req_info_source),
    .io_in_4_ready                   (u_arb_cache_in_in_4_ready),
    .io_in_4_valid                   (u_prefetch_out_valid),
    .io_in_4_bits_req_info_vpn       (u_prefetch_out_bits_req_info_vpn),
    .io_in_4_bits_req_info_s2xlate   (u_prefetch_out_bits_req_info_s2xlate),
    .io_out_ready                    (u_page_cache_req_ready),
    .io_out_valid                    (u_arb_cache_in_out_valid),
    .io_out_bits_req_info_vpn        (u_arb_cache_in_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate    (u_arb_cache_in_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source     (u_arb_cache_in_out_bits_req_info_source),
    .io_out_bits_isHptwReq           (u_arb_cache_in_out_bits_isHptwReq),
    .io_out_bits_hptwId              (u_arb_cache_in_out_bits_hptwId),
    .io_chosen                       (u_arb_cache_in_chosen)
  );

  Arbiter2_L2TLBImp_Anon u_arb_hptw_req (
    .io_in_0_ready                   (u_arb_hptw_req_in_0_ready),
    .io_in_0_valid                   (u_ptw_hptw_req_valid),
    .io_in_0_bits_source             (u_ptw_hptw_req_bits_source),
    .io_in_0_bits_gvpn               (u_arb_hptw_req__in_0_bits_gvpn),
    .io_in_1_ready                   (u_arb_hptw_req_in_1_ready),
    .io_in_1_valid                   (u_llptw_hptw_req_valid),
    .io_in_1_bits_id                 (u_llptw_hptw_req_bits_id),
    .io_in_1_bits_source             (u_llptw_hptw_req_bits_source),
    .io_in_1_bits_gvpn               (u_arb_hptw_req__in_1_bits_gvpn),
    .io_out_ready                    (u_arb_cache_in_in_0_ready),
    .io_out_valid                    (u_arb_hptw_req_out_valid),
    .io_out_bits_id                  (u_arb_hptw_req_out_bits_id),
    .io_out_bits_source              (u_arb_hptw_req_out_bits_source),
    .io_out_bits_gvpn                (u_arb_hptw_req_out_bits_gvpn)
  );

  Arbiter2_L2TLBImp_Anon_1 u_arb_hptw_resp (
    .io_in_0_valid                   (u_arb_hptw_resp__in_0_valid),
    .io_in_0_bits_resp_entry_tag     (u_page_cache_resp_bits_toHptw_resp_entry_tag),
    .io_in_0_bits_resp_entry_vmid    (u_page_cache_resp_bits_toHptw_resp_entry_vmid),
    .io_in_0_bits_resp_entry_n       (u_page_cache_resp_bits_toHptw_resp_entry_n),
    .io_in_0_bits_resp_entry_pbmt    (u_page_cache_resp_bits_toHptw_resp_entry_pbmt),
    .io_in_0_bits_resp_entry_ppn     (u_page_cache_resp_bits_toHptw_resp_entry_ppn),
    .io_in_0_bits_resp_entry_perm_d  (u_page_cache_resp_bits_toHptw_resp_entry_perm_d),
    .io_in_0_bits_resp_entry_perm_a  (u_page_cache_resp_bits_toHptw_resp_entry_perm_a),
    .io_in_0_bits_resp_entry_perm_g  (u_page_cache_resp_bits_toHptw_resp_entry_perm_g),
    .io_in_0_bits_resp_entry_perm_u  (u_page_cache_resp_bits_toHptw_resp_entry_perm_u),
    .io_in_0_bits_resp_entry_perm_x  (u_page_cache_resp_bits_toHptw_resp_entry_perm_x),
    .io_in_0_bits_resp_entry_perm_w  (u_page_cache_resp_bits_toHptw_resp_entry_perm_w),
    .io_in_0_bits_resp_entry_perm_r  (u_page_cache_resp_bits_toHptw_resp_entry_perm_r),
    .io_in_0_bits_resp_entry_level   (u_page_cache_resp_bits_toHptw_resp_entry_level),
    .io_in_0_bits_resp_gpf           (u_page_cache_resp_bits_toHptw_resp_gpf),
    .io_in_0_bits_id                 (u_page_cache_resp_bits_toHptw_id),
    .io_in_1_ready                   (u_arb_hptw_resp_in_1_ready),
    .io_in_1_valid                   (u_hptw_resp_valid),
    .io_in_1_bits_resp_entry_tag     (u_hptw_resp_bits_resp_entry_tag),
    .io_in_1_bits_resp_entry_vmid    (u_hptw_resp_bits_resp_entry_vmid),
    .io_in_1_bits_resp_entry_n       (u_hptw_resp_bits_resp_entry_n),
    .io_in_1_bits_resp_entry_pbmt    (u_hptw_resp_bits_resp_entry_pbmt),
    .io_in_1_bits_resp_entry_ppn     (u_hptw_resp_bits_resp_entry_ppn),
    .io_in_1_bits_resp_entry_perm_d  (u_hptw_resp_bits_resp_entry_perm_d),
    .io_in_1_bits_resp_entry_perm_a  (u_hptw_resp_bits_resp_entry_perm_a),
    .io_in_1_bits_resp_entry_perm_g  (u_hptw_resp_bits_resp_entry_perm_g),
    .io_in_1_bits_resp_entry_perm_u  (u_hptw_resp_bits_resp_entry_perm_u),
    .io_in_1_bits_resp_entry_perm_x  (u_hptw_resp_bits_resp_entry_perm_x),
    .io_in_1_bits_resp_entry_perm_w  (u_hptw_resp_bits_resp_entry_perm_w),
    .io_in_1_bits_resp_entry_perm_r  (u_hptw_resp_bits_resp_entry_perm_r),
    .io_in_1_bits_resp_entry_level   (u_hptw_resp_bits_resp_entry_level),
    .io_in_1_bits_resp_gpf           (u_hptw_resp_bits_resp_gpf),
    .io_in_1_bits_resp_gaf           (u_hptw_resp_bits_resp_gaf),
    .io_in_1_bits_id                 (u_arb_hptw_resp__in_1_bits_id),
    .io_out_valid                    (u_arb_hptw_resp_out_valid),
    .io_out_bits_resp_entry_tag      (u_arb_hptw_resp_out_bits_resp_entry_tag),
    .io_out_bits_resp_entry_vmid     (u_arb_hptw_resp_out_bits_resp_entry_vmid),
    .io_out_bits_resp_entry_n        (u_arb_hptw_resp_out_bits_resp_entry_n),
    .io_out_bits_resp_entry_pbmt     (u_arb_hptw_resp_out_bits_resp_entry_pbmt),
    .io_out_bits_resp_entry_ppn      (u_arb_hptw_resp_out_bits_resp_entry_ppn),
    .io_out_bits_resp_entry_perm_d   (u_arb_hptw_resp_out_bits_resp_entry_perm_d),
    .io_out_bits_resp_entry_perm_a   (u_arb_hptw_resp_out_bits_resp_entry_perm_a),
    .io_out_bits_resp_entry_perm_g   (u_arb_hptw_resp_out_bits_resp_entry_perm_g),
    .io_out_bits_resp_entry_perm_u   (u_arb_hptw_resp_out_bits_resp_entry_perm_u),
    .io_out_bits_resp_entry_perm_x   (u_arb_hptw_resp_out_bits_resp_entry_perm_x),
    .io_out_bits_resp_entry_perm_w   (u_arb_hptw_resp_out_bits_resp_entry_perm_w),
    .io_out_bits_resp_entry_perm_r   (u_arb_hptw_resp_out_bits_resp_entry_perm_r),
    .io_out_bits_resp_entry_level    (u_arb_hptw_resp_out_bits_resp_entry_level),
    .io_out_bits_resp_gpf            (u_arb_hptw_resp_out_bits_resp_gpf),
    .io_out_bits_resp_gaf            (u_arb_hptw_resp_out_bits_resp_gaf),
    .io_out_bits_id                  (u_arb_hptw_resp_out_bits_id)
  );

  Arbiter1_L2TLBImp_Anon u_out_arb_0 (
    .io_in_0_ready                   (u_out_arb_0_in_0_ready),
    .io_in_0_valid                   (u_merge_arb_0_out_valid),
    .io_in_0_bits_s2xlate            (u_merge_arb_0_out_bits_s2xlate),
    .io_in_0_bits_s1_entry_tag       (u_out_arb_0__in_0_bits_s1_entry_tag),
    .io_in_0_bits_s1_entry_asid      (u_out_arb_0__in_0_bits_s1_entry_asid),
    .io_in_0_bits_s1_entry_vmid      (u_out_arb_0__in_0_bits_s1_entry_vmid),
    .io_in_0_bits_s1_entry_n         (u_out_arb_0__in_0_bits_s1_entry_n),
    .io_in_0_bits_s1_entry_pbmt      (u_out_arb_0__in_0_bits_s1_entry_pbmt),
    .io_in_0_bits_s1_entry_perm_d    (u_out_arb_0__in_0_bits_s1_entry_perm_d),
    .io_in_0_bits_s1_entry_perm_a    (u_out_arb_0__in_0_bits_s1_entry_perm_a),
    .io_in_0_bits_s1_entry_perm_g    (u_out_arb_0__in_0_bits_s1_entry_perm_g),
    .io_in_0_bits_s1_entry_perm_u    (u_out_arb_0__in_0_bits_s1_entry_perm_u),
    .io_in_0_bits_s1_entry_perm_x    (u_out_arb_0__in_0_bits_s1_entry_perm_x),
    .io_in_0_bits_s1_entry_perm_w    (u_out_arb_0__in_0_bits_s1_entry_perm_w),
    .io_in_0_bits_s1_entry_perm_r    (u_out_arb_0__in_0_bits_s1_entry_perm_r),
    .io_in_0_bits_s1_entry_level     (u_out_arb_0__in_0_bits_s1_entry_level),
    .io_in_0_bits_s1_entry_v         (u_out_arb_0__in_0_bits_s1_entry_v),
    .io_in_0_bits_s1_entry_ppn       (u_out_arb_0__in_0_bits_s1_entry_ppn),
    .io_in_0_bits_s1_addr_low        (u_out_arb_0__in_0_bits_s1_addr_low),
    .io_in_0_bits_s1_ppn_low_0       (u_out_arb_0__in_0_bits_s1_ppn_low_0),
    .io_in_0_bits_s1_ppn_low_1       (u_out_arb_0__in_0_bits_s1_ppn_low_1),
    .io_in_0_bits_s1_ppn_low_2       (u_out_arb_0__in_0_bits_s1_ppn_low_2),
    .io_in_0_bits_s1_ppn_low_3       (u_out_arb_0__in_0_bits_s1_ppn_low_3),
    .io_in_0_bits_s1_ppn_low_4       (u_out_arb_0__in_0_bits_s1_ppn_low_4),
    .io_in_0_bits_s1_ppn_low_5       (u_out_arb_0__in_0_bits_s1_ppn_low_5),
    .io_in_0_bits_s1_ppn_low_6       (u_out_arb_0__in_0_bits_s1_ppn_low_6),
    .io_in_0_bits_s1_ppn_low_7       (u_out_arb_0__in_0_bits_s1_ppn_low_7),
    .io_in_0_bits_s1_valididx_0      (u_out_arb_0__in_0_bits_s1_valididx_0),
    .io_in_0_bits_s1_valididx_1      (u_out_arb_0__in_0_bits_s1_valididx_1),
    .io_in_0_bits_s1_valididx_2      (u_out_arb_0__in_0_bits_s1_valididx_2),
    .io_in_0_bits_s1_valididx_3      (u_out_arb_0__in_0_bits_s1_valididx_3),
    .io_in_0_bits_s1_valididx_4      (u_out_arb_0__in_0_bits_s1_valididx_4),
    .io_in_0_bits_s1_valididx_5      (u_out_arb_0__in_0_bits_s1_valididx_5),
    .io_in_0_bits_s1_valididx_6      (u_out_arb_0__in_0_bits_s1_valididx_6),
    .io_in_0_bits_s1_valididx_7      (u_out_arb_0__in_0_bits_s1_valididx_7),
    .io_in_0_bits_s1_pteidx_0        (u_merge_arb_0_out_bits_s1_pteidx_0),
    .io_in_0_bits_s1_pteidx_1        (u_merge_arb_0_out_bits_s1_pteidx_1),
    .io_in_0_bits_s1_pteidx_2        (u_merge_arb_0_out_bits_s1_pteidx_2),
    .io_in_0_bits_s1_pteidx_3        (u_merge_arb_0_out_bits_s1_pteidx_3),
    .io_in_0_bits_s1_pteidx_4        (u_merge_arb_0_out_bits_s1_pteidx_4),
    .io_in_0_bits_s1_pteidx_5        (u_merge_arb_0_out_bits_s1_pteidx_5),
    .io_in_0_bits_s1_pteidx_6        (u_merge_arb_0_out_bits_s1_pteidx_6),
    .io_in_0_bits_s1_pteidx_7        (u_merge_arb_0_out_bits_s1_pteidx_7),
    .io_in_0_bits_s1_pf              (u_out_arb_0__in_0_bits_s1_pf),
    .io_in_0_bits_s1_af              (u_out_arb_0__in_0_bits_s1_af),
    .io_in_0_bits_s2_entry_tag       (u_merge_arb_0_out_bits_s2_entry_tag),
    .io_in_0_bits_s2_entry_vmid      (u_merge_arb_0_out_bits_s2_entry_vmid),
    .io_in_0_bits_s2_entry_n         (u_out_arb_0__in_0_bits_s2_entry_n),
    .io_in_0_bits_s2_entry_pbmt      (u_merge_arb_0_out_bits_s2_entry_pbmt),
    .io_in_0_bits_s2_entry_ppn       (u_out_arb_0__in_0_bits_s2_entry_ppn),
    .io_in_0_bits_s2_entry_perm_d    (u_merge_arb_0_out_bits_s2_entry_perm_d),
    .io_in_0_bits_s2_entry_perm_a    (u_merge_arb_0_out_bits_s2_entry_perm_a),
    .io_in_0_bits_s2_entry_perm_g    (u_merge_arb_0_out_bits_s2_entry_perm_g),
    .io_in_0_bits_s2_entry_perm_u    (u_merge_arb_0_out_bits_s2_entry_perm_u),
    .io_in_0_bits_s2_entry_perm_x    (u_merge_arb_0_out_bits_s2_entry_perm_x),
    .io_in_0_bits_s2_entry_perm_w    (u_merge_arb_0_out_bits_s2_entry_perm_w),
    .io_in_0_bits_s2_entry_perm_r    (u_merge_arb_0_out_bits_s2_entry_perm_r),
    .io_in_0_bits_s2_entry_level     (u_out_arb_0__in_0_bits_s2_entry_level),
    .io_in_0_bits_s2_gpf             (u_merge_arb_0_out_bits_s2_gpf),
    .io_in_0_bits_s2_gaf             (u_merge_arb_0_out_bits_s2_gaf),
    .io_out_ready                    (io_tlb_0_resp_ready),
    .io_out_valid                    (u_out_arb_0_out_valid),
    .io_out_bits_s2xlate             (u_out_arb_0_out_bits_s2xlate),
    .io_out_bits_s1_entry_tag        (u_out_arb_0_out_bits_s1_entry_tag),
    .io_out_bits_s1_entry_asid       (io_tlb_0_resp_bits_s1_entry_asid),
    .io_out_bits_s1_entry_vmid       (io_tlb_0_resp_bits_s1_entry_vmid),
    .io_out_bits_s1_entry_n          (io_tlb_0_resp_bits_s1_entry_n),
    .io_out_bits_s1_entry_pbmt       (u_out_arb_0_out_bits_s1_entry_pbmt),
    .io_out_bits_s1_entry_perm_d     (u_out_arb_0_out_bits_s1_entry_perm_d),
    .io_out_bits_s1_entry_perm_a     (u_out_arb_0_out_bits_s1_entry_perm_a),
    .io_out_bits_s1_entry_perm_g     (u_out_arb_0_out_bits_s1_entry_perm_g),
    .io_out_bits_s1_entry_perm_u     (u_out_arb_0_out_bits_s1_entry_perm_u),
    .io_out_bits_s1_entry_perm_x     (u_out_arb_0_out_bits_s1_entry_perm_x),
    .io_out_bits_s1_entry_perm_w     (u_out_arb_0_out_bits_s1_entry_perm_w),
    .io_out_bits_s1_entry_perm_r     (u_out_arb_0_out_bits_s1_entry_perm_r),
    .io_out_bits_s1_entry_level      (u_out_arb_0_out_bits_s1_entry_level),
    .io_out_bits_s1_entry_v          (io_tlb_0_resp_bits_s1_entry_v),
    .io_out_bits_s1_entry_ppn        (u_out_arb_0_out_bits_s1_entry_ppn),
    .io_out_bits_s1_addr_low         (io_tlb_0_resp_bits_s1_addr_low),
    .io_out_bits_s1_ppn_low_0        (u_out_arb_0_out_bits_s1_ppn_low_0),
    .io_out_bits_s1_ppn_low_1        (u_out_arb_0_out_bits_s1_ppn_low_1),
    .io_out_bits_s1_ppn_low_2        (u_out_arb_0_out_bits_s1_ppn_low_2),
    .io_out_bits_s1_ppn_low_3        (u_out_arb_0_out_bits_s1_ppn_low_3),
    .io_out_bits_s1_ppn_low_4        (u_out_arb_0_out_bits_s1_ppn_low_4),
    .io_out_bits_s1_ppn_low_5        (u_out_arb_0_out_bits_s1_ppn_low_5),
    .io_out_bits_s1_ppn_low_6        (u_out_arb_0_out_bits_s1_ppn_low_6),
    .io_out_bits_s1_ppn_low_7        (u_out_arb_0_out_bits_s1_ppn_low_7),
    .io_out_bits_s1_valididx_0       (u_out_arb_0_out_bits_s1_valididx_0),
    .io_out_bits_s1_valididx_1       (u_out_arb_0_out_bits_s1_valididx_1),
    .io_out_bits_s1_valididx_2       (u_out_arb_0_out_bits_s1_valididx_2),
    .io_out_bits_s1_valididx_3       (u_out_arb_0_out_bits_s1_valididx_3),
    .io_out_bits_s1_valididx_4       (u_out_arb_0_out_bits_s1_valididx_4),
    .io_out_bits_s1_valididx_5       (u_out_arb_0_out_bits_s1_valididx_5),
    .io_out_bits_s1_valididx_6       (u_out_arb_0_out_bits_s1_valididx_6),
    .io_out_bits_s1_valididx_7       (u_out_arb_0_out_bits_s1_valididx_7),
    .io_out_bits_s1_pteidx_0         (u_out_arb_0_out_bits_s1_pteidx_0),
    .io_out_bits_s1_pteidx_1         (u_out_arb_0_out_bits_s1_pteidx_1),
    .io_out_bits_s1_pteidx_2         (u_out_arb_0_out_bits_s1_pteidx_2),
    .io_out_bits_s1_pteidx_3         (u_out_arb_0_out_bits_s1_pteidx_3),
    .io_out_bits_s1_pteidx_4         (u_out_arb_0_out_bits_s1_pteidx_4),
    .io_out_bits_s1_pteidx_5         (u_out_arb_0_out_bits_s1_pteidx_5),
    .io_out_bits_s1_pteidx_6         (u_out_arb_0_out_bits_s1_pteidx_6),
    .io_out_bits_s1_pteidx_7         (u_out_arb_0_out_bits_s1_pteidx_7),
    .io_out_bits_s1_pf               (u_out_arb_0_out_bits_s1_pf),
    .io_out_bits_s1_af               (u_out_arb_0_out_bits_s1_af),
    .io_out_bits_s2_entry_tag        (u_out_arb_0_out_bits_s2_entry_tag),
    .io_out_bits_s2_entry_vmid       (io_tlb_0_resp_bits_s2_entry_vmid),
    .io_out_bits_s2_entry_n          (io_tlb_0_resp_bits_s2_entry_n),
    .io_out_bits_s2_entry_pbmt       (u_out_arb_0_out_bits_s2_entry_pbmt),
    .io_out_bits_s2_entry_ppn        (u_out_arb_0_out_bits_s2_entry_ppn),
    .io_out_bits_s2_entry_perm_d     (u_out_arb_0_out_bits_s2_entry_perm_d),
    .io_out_bits_s2_entry_perm_a     (u_out_arb_0_out_bits_s2_entry_perm_a),
    .io_out_bits_s2_entry_perm_g     (u_out_arb_0_out_bits_s2_entry_perm_g),
    .io_out_bits_s2_entry_perm_u     (u_out_arb_0_out_bits_s2_entry_perm_u),
    .io_out_bits_s2_entry_perm_x     (u_out_arb_0_out_bits_s2_entry_perm_x),
    .io_out_bits_s2_entry_perm_w     (u_out_arb_0_out_bits_s2_entry_perm_w),
    .io_out_bits_s2_entry_perm_r     (u_out_arb_0_out_bits_s2_entry_perm_r),
    .io_out_bits_s2_entry_level      (u_out_arb_0_out_bits_s2_entry_level),
    .io_out_bits_s2_gpf              (u_out_arb_0_out_bits_s2_gpf),
    .io_out_bits_s2_gaf              (u_out_arb_0_out_bits_s2_gaf)
  );

  Arbiter1_L2TLBImp_Anon u_out_arb_1 (
    .io_in_0_ready                   (u_out_arb_1_in_0_ready),
    .io_in_0_valid                   (u_merge_arb_1_out_valid),
    .io_in_0_bits_s2xlate            (u_merge_arb_1_out_bits_s2xlate),
    .io_in_0_bits_s1_entry_tag       (u_out_arb_1__in_0_bits_s1_entry_tag),
    .io_in_0_bits_s1_entry_asid      (u_out_arb_1__in_0_bits_s1_entry_asid),
    .io_in_0_bits_s1_entry_vmid      (u_out_arb_1__in_0_bits_s1_entry_vmid),
    .io_in_0_bits_s1_entry_n         (u_out_arb_1__in_0_bits_s1_entry_n),
    .io_in_0_bits_s1_entry_pbmt      (u_out_arb_1__in_0_bits_s1_entry_pbmt),
    .io_in_0_bits_s1_entry_perm_d    (u_out_arb_1__in_0_bits_s1_entry_perm_d),
    .io_in_0_bits_s1_entry_perm_a    (u_out_arb_1__in_0_bits_s1_entry_perm_a),
    .io_in_0_bits_s1_entry_perm_g    (u_out_arb_1__in_0_bits_s1_entry_perm_g),
    .io_in_0_bits_s1_entry_perm_u    (u_out_arb_1__in_0_bits_s1_entry_perm_u),
    .io_in_0_bits_s1_entry_perm_x    (u_out_arb_1__in_0_bits_s1_entry_perm_x),
    .io_in_0_bits_s1_entry_perm_w    (u_out_arb_1__in_0_bits_s1_entry_perm_w),
    .io_in_0_bits_s1_entry_perm_r    (u_out_arb_1__in_0_bits_s1_entry_perm_r),
    .io_in_0_bits_s1_entry_level     (u_out_arb_1__in_0_bits_s1_entry_level),
    .io_in_0_bits_s1_entry_v         (u_out_arb_1__in_0_bits_s1_entry_v),
    .io_in_0_bits_s1_entry_ppn       (u_out_arb_1__in_0_bits_s1_entry_ppn),
    .io_in_0_bits_s1_addr_low        (u_out_arb_1__in_0_bits_s1_addr_low),
    .io_in_0_bits_s1_ppn_low_0       (u_out_arb_1__in_0_bits_s1_ppn_low_0),
    .io_in_0_bits_s1_ppn_low_1       (u_out_arb_1__in_0_bits_s1_ppn_low_1),
    .io_in_0_bits_s1_ppn_low_2       (u_out_arb_1__in_0_bits_s1_ppn_low_2),
    .io_in_0_bits_s1_ppn_low_3       (u_out_arb_1__in_0_bits_s1_ppn_low_3),
    .io_in_0_bits_s1_ppn_low_4       (u_out_arb_1__in_0_bits_s1_ppn_low_4),
    .io_in_0_bits_s1_ppn_low_5       (u_out_arb_1__in_0_bits_s1_ppn_low_5),
    .io_in_0_bits_s1_ppn_low_6       (u_out_arb_1__in_0_bits_s1_ppn_low_6),
    .io_in_0_bits_s1_ppn_low_7       (u_out_arb_1__in_0_bits_s1_ppn_low_7),
    .io_in_0_bits_s1_valididx_0      (u_out_arb_1__in_0_bits_s1_valididx_0),
    .io_in_0_bits_s1_valididx_1      (u_out_arb_1__in_0_bits_s1_valididx_1),
    .io_in_0_bits_s1_valididx_2      (u_out_arb_1__in_0_bits_s1_valididx_2),
    .io_in_0_bits_s1_valididx_3      (u_out_arb_1__in_0_bits_s1_valididx_3),
    .io_in_0_bits_s1_valididx_4      (u_out_arb_1__in_0_bits_s1_valididx_4),
    .io_in_0_bits_s1_valididx_5      (u_out_arb_1__in_0_bits_s1_valididx_5),
    .io_in_0_bits_s1_valididx_6      (u_out_arb_1__in_0_bits_s1_valididx_6),
    .io_in_0_bits_s1_valididx_7      (u_out_arb_1__in_0_bits_s1_valididx_7),
    .io_in_0_bits_s1_pteidx_0        (u_merge_arb_1_out_bits_s1_pteidx_0),
    .io_in_0_bits_s1_pteidx_1        (u_merge_arb_1_out_bits_s1_pteidx_1),
    .io_in_0_bits_s1_pteidx_2        (u_merge_arb_1_out_bits_s1_pteidx_2),
    .io_in_0_bits_s1_pteidx_3        (u_merge_arb_1_out_bits_s1_pteidx_3),
    .io_in_0_bits_s1_pteidx_4        (u_merge_arb_1_out_bits_s1_pteidx_4),
    .io_in_0_bits_s1_pteidx_5        (u_merge_arb_1_out_bits_s1_pteidx_5),
    .io_in_0_bits_s1_pteidx_6        (u_merge_arb_1_out_bits_s1_pteidx_6),
    .io_in_0_bits_s1_pteidx_7        (u_merge_arb_1_out_bits_s1_pteidx_7),
    .io_in_0_bits_s1_pf              (u_out_arb_1__in_0_bits_s1_pf),
    .io_in_0_bits_s1_af              (u_out_arb_1__in_0_bits_s1_af),
    .io_in_0_bits_s2_entry_tag       (u_merge_arb_1_out_bits_s2_entry_tag),
    .io_in_0_bits_s2_entry_vmid      (u_merge_arb_1_out_bits_s2_entry_vmid),
    .io_in_0_bits_s2_entry_n         (u_out_arb_1__in_0_bits_s2_entry_n),
    .io_in_0_bits_s2_entry_pbmt      (u_merge_arb_1_out_bits_s2_entry_pbmt),
    .io_in_0_bits_s2_entry_ppn       (u_out_arb_1__in_0_bits_s2_entry_ppn),
    .io_in_0_bits_s2_entry_perm_d    (u_merge_arb_1_out_bits_s2_entry_perm_d),
    .io_in_0_bits_s2_entry_perm_a    (u_merge_arb_1_out_bits_s2_entry_perm_a),
    .io_in_0_bits_s2_entry_perm_g    (u_merge_arb_1_out_bits_s2_entry_perm_g),
    .io_in_0_bits_s2_entry_perm_u    (u_merge_arb_1_out_bits_s2_entry_perm_u),
    .io_in_0_bits_s2_entry_perm_x    (u_merge_arb_1_out_bits_s2_entry_perm_x),
    .io_in_0_bits_s2_entry_perm_w    (u_merge_arb_1_out_bits_s2_entry_perm_w),
    .io_in_0_bits_s2_entry_perm_r    (u_merge_arb_1_out_bits_s2_entry_perm_r),
    .io_in_0_bits_s2_entry_level     (u_out_arb_1__in_0_bits_s2_entry_level),
    .io_in_0_bits_s2_gpf             (u_merge_arb_1_out_bits_s2_gpf),
    .io_in_0_bits_s2_gaf             (u_merge_arb_1_out_bits_s2_gaf),
    .io_out_ready                    (1'h1),
    .io_out_valid                    (u_out_arb_1_out_valid),
    .io_out_bits_s2xlate             (u_out_arb_1_out_bits_s2xlate),
    .io_out_bits_s1_entry_tag        (u_out_arb_1_out_bits_s1_entry_tag),
    .io_out_bits_s1_entry_asid       (io_tlb_1_resp_bits_s1_entry_asid),
    .io_out_bits_s1_entry_vmid       (io_tlb_1_resp_bits_s1_entry_vmid),
    .io_out_bits_s1_entry_n          (io_tlb_1_resp_bits_s1_entry_n),
    .io_out_bits_s1_entry_pbmt       (u_out_arb_1_out_bits_s1_entry_pbmt),
    .io_out_bits_s1_entry_perm_d     (u_out_arb_1_out_bits_s1_entry_perm_d),
    .io_out_bits_s1_entry_perm_a     (u_out_arb_1_out_bits_s1_entry_perm_a),
    .io_out_bits_s1_entry_perm_g     (u_out_arb_1_out_bits_s1_entry_perm_g),
    .io_out_bits_s1_entry_perm_u     (u_out_arb_1_out_bits_s1_entry_perm_u),
    .io_out_bits_s1_entry_perm_x     (u_out_arb_1_out_bits_s1_entry_perm_x),
    .io_out_bits_s1_entry_perm_w     (u_out_arb_1_out_bits_s1_entry_perm_w),
    .io_out_bits_s1_entry_perm_r     (u_out_arb_1_out_bits_s1_entry_perm_r),
    .io_out_bits_s1_entry_level      (u_out_arb_1_out_bits_s1_entry_level),
    .io_out_bits_s1_entry_v          (io_tlb_1_resp_bits_s1_entry_v),
    .io_out_bits_s1_entry_ppn        (u_out_arb_1_out_bits_s1_entry_ppn),
    .io_out_bits_s1_addr_low         (io_tlb_1_resp_bits_s1_addr_low),
    .io_out_bits_s1_ppn_low_0        (u_out_arb_1_out_bits_s1_ppn_low_0),
    .io_out_bits_s1_ppn_low_1        (u_out_arb_1_out_bits_s1_ppn_low_1),
    .io_out_bits_s1_ppn_low_2        (u_out_arb_1_out_bits_s1_ppn_low_2),
    .io_out_bits_s1_ppn_low_3        (u_out_arb_1_out_bits_s1_ppn_low_3),
    .io_out_bits_s1_ppn_low_4        (u_out_arb_1_out_bits_s1_ppn_low_4),
    .io_out_bits_s1_ppn_low_5        (u_out_arb_1_out_bits_s1_ppn_low_5),
    .io_out_bits_s1_ppn_low_6        (u_out_arb_1_out_bits_s1_ppn_low_6),
    .io_out_bits_s1_ppn_low_7        (u_out_arb_1_out_bits_s1_ppn_low_7),
    .io_out_bits_s1_valididx_0       (u_out_arb_1_out_bits_s1_valididx_0),
    .io_out_bits_s1_valididx_1       (u_out_arb_1_out_bits_s1_valididx_1),
    .io_out_bits_s1_valididx_2       (u_out_arb_1_out_bits_s1_valididx_2),
    .io_out_bits_s1_valididx_3       (u_out_arb_1_out_bits_s1_valididx_3),
    .io_out_bits_s1_valididx_4       (u_out_arb_1_out_bits_s1_valididx_4),
    .io_out_bits_s1_valididx_5       (u_out_arb_1_out_bits_s1_valididx_5),
    .io_out_bits_s1_valididx_6       (u_out_arb_1_out_bits_s1_valididx_6),
    .io_out_bits_s1_valididx_7       (u_out_arb_1_out_bits_s1_valididx_7),
    .io_out_bits_s1_pteidx_0         (u_out_arb_1_out_bits_s1_pteidx_0),
    .io_out_bits_s1_pteidx_1         (u_out_arb_1_out_bits_s1_pteidx_1),
    .io_out_bits_s1_pteidx_2         (u_out_arb_1_out_bits_s1_pteidx_2),
    .io_out_bits_s1_pteidx_3         (u_out_arb_1_out_bits_s1_pteidx_3),
    .io_out_bits_s1_pteidx_4         (u_out_arb_1_out_bits_s1_pteidx_4),
    .io_out_bits_s1_pteidx_5         (u_out_arb_1_out_bits_s1_pteidx_5),
    .io_out_bits_s1_pteidx_6         (u_out_arb_1_out_bits_s1_pteidx_6),
    .io_out_bits_s1_pteidx_7         (u_out_arb_1_out_bits_s1_pteidx_7),
    .io_out_bits_s1_pf               (u_out_arb_1_out_bits_s1_pf),
    .io_out_bits_s1_af               (u_out_arb_1_out_bits_s1_af),
    .io_out_bits_s2_entry_tag        (u_out_arb_1_out_bits_s2_entry_tag),
    .io_out_bits_s2_entry_vmid       (io_tlb_1_resp_bits_s2_entry_vmid),
    .io_out_bits_s2_entry_n          (io_tlb_1_resp_bits_s2_entry_n),
    .io_out_bits_s2_entry_pbmt       (u_out_arb_1_out_bits_s2_entry_pbmt),
    .io_out_bits_s2_entry_ppn        (u_out_arb_1_out_bits_s2_entry_ppn),
    .io_out_bits_s2_entry_perm_d     (u_out_arb_1_out_bits_s2_entry_perm_d),
    .io_out_bits_s2_entry_perm_a     (u_out_arb_1_out_bits_s2_entry_perm_a),
    .io_out_bits_s2_entry_perm_g     (u_out_arb_1_out_bits_s2_entry_perm_g),
    .io_out_bits_s2_entry_perm_u     (u_out_arb_1_out_bits_s2_entry_perm_u),
    .io_out_bits_s2_entry_perm_x     (u_out_arb_1_out_bits_s2_entry_perm_x),
    .io_out_bits_s2_entry_perm_w     (u_out_arb_1_out_bits_s2_entry_perm_w),
    .io_out_bits_s2_entry_perm_r     (u_out_arb_1_out_bits_s2_entry_perm_r),
    .io_out_bits_s2_entry_level      (u_out_arb_1_out_bits_s2_entry_level),
    .io_out_bits_s2_gpf              (u_out_arb_1_out_bits_s2_gpf),
    .io_out_bits_s2_gaf              (u_out_arb_1_out_bits_s2_gaf)
  );

  Arbiter3_L2TLBImp_Anon u_merge_arb_0 (
    .io_in_0_ready                   (u_merge_arb_0_in_0_ready),
    .io_in_0_valid                   (u_merge_arb_0__in_0_valid),
    .io_in_0_bits_s2xlate            (u_page_cache_resp_bits_req_info_s2xlate),
    .io_in_0_bits_s1_entry_0_tag     (u_page_cache_resp_bits_stage1_entry_0_tag),
    .io_in_0_bits_s1_entry_0_asid    (u_page_cache_resp_bits_stage1_entry_0_asid),
    .io_in_0_bits_s1_entry_0_vmid    (u_page_cache_resp_bits_stage1_entry_0_vmid),
    .io_in_0_bits_s1_entry_0_n       (u_page_cache_resp_bits_stage1_entry_0_n),
    .io_in_0_bits_s1_entry_0_pbmt    (u_page_cache_resp_bits_stage1_entry_0_pbmt),
    .io_in_0_bits_s1_entry_0_perm_d  (u_page_cache_resp_bits_stage1_entry_0_perm_d),
    .io_in_0_bits_s1_entry_0_perm_a  (u_page_cache_resp_bits_stage1_entry_0_perm_a),
    .io_in_0_bits_s1_entry_0_perm_g  (u_page_cache_resp_bits_stage1_entry_0_perm_g),
    .io_in_0_bits_s1_entry_0_perm_u  (u_page_cache_resp_bits_stage1_entry_0_perm_u),
    .io_in_0_bits_s1_entry_0_perm_x  (u_page_cache_resp_bits_stage1_entry_0_perm_x),
    .io_in_0_bits_s1_entry_0_perm_w  (u_page_cache_resp_bits_stage1_entry_0_perm_w),
    .io_in_0_bits_s1_entry_0_perm_r  (u_page_cache_resp_bits_stage1_entry_0_perm_r),
    .io_in_0_bits_s1_entry_0_level   (u_page_cache_resp_bits_stage1_entry_0_level),
    .io_in_0_bits_s1_entry_0_v       (u_page_cache_resp_bits_stage1_entry_0_v),
    .io_in_0_bits_s1_entry_0_ppn     (u_page_cache_resp_bits_stage1_entry_0_ppn),
    .io_in_0_bits_s1_entry_0_ppn_low (u_page_cache_resp_bits_stage1_entry_0_ppn_low),
    .io_in_0_bits_s1_entry_0_pf      (u_page_cache_resp_bits_stage1_entry_0_pf),
    .io_in_0_bits_s1_entry_0_cf      (u_page_cache_resp_bits_stage1_entry_0_cf),
    .io_in_0_bits_s1_entry_1_tag     (u_page_cache_resp_bits_stage1_entry_1_tag),
    .io_in_0_bits_s1_entry_1_asid    (u_page_cache_resp_bits_stage1_entry_1_asid),
    .io_in_0_bits_s1_entry_1_vmid    (u_page_cache_resp_bits_stage1_entry_1_vmid),
    .io_in_0_bits_s1_entry_1_n       (u_page_cache_resp_bits_stage1_entry_1_n),
    .io_in_0_bits_s1_entry_1_pbmt    (u_page_cache_resp_bits_stage1_entry_1_pbmt),
    .io_in_0_bits_s1_entry_1_perm_d  (u_page_cache_resp_bits_stage1_entry_1_perm_d),
    .io_in_0_bits_s1_entry_1_perm_a  (u_page_cache_resp_bits_stage1_entry_1_perm_a),
    .io_in_0_bits_s1_entry_1_perm_g  (u_page_cache_resp_bits_stage1_entry_1_perm_g),
    .io_in_0_bits_s1_entry_1_perm_u  (u_page_cache_resp_bits_stage1_entry_1_perm_u),
    .io_in_0_bits_s1_entry_1_perm_x  (u_page_cache_resp_bits_stage1_entry_1_perm_x),
    .io_in_0_bits_s1_entry_1_perm_w  (u_page_cache_resp_bits_stage1_entry_1_perm_w),
    .io_in_0_bits_s1_entry_1_perm_r  (u_page_cache_resp_bits_stage1_entry_1_perm_r),
    .io_in_0_bits_s1_entry_1_level   (u_page_cache_resp_bits_stage1_entry_1_level),
    .io_in_0_bits_s1_entry_1_v       (u_page_cache_resp_bits_stage1_entry_1_v),
    .io_in_0_bits_s1_entry_1_ppn     (u_page_cache_resp_bits_stage1_entry_1_ppn),
    .io_in_0_bits_s1_entry_1_ppn_low (u_page_cache_resp_bits_stage1_entry_1_ppn_low),
    .io_in_0_bits_s1_entry_1_pf      (u_page_cache_resp_bits_stage1_entry_1_pf),
    .io_in_0_bits_s1_entry_1_cf      (u_page_cache_resp_bits_stage1_entry_1_cf),
    .io_in_0_bits_s1_entry_2_tag     (u_page_cache_resp_bits_stage1_entry_2_tag),
    .io_in_0_bits_s1_entry_2_asid    (u_page_cache_resp_bits_stage1_entry_2_asid),
    .io_in_0_bits_s1_entry_2_vmid    (u_page_cache_resp_bits_stage1_entry_2_vmid),
    .io_in_0_bits_s1_entry_2_n       (u_page_cache_resp_bits_stage1_entry_2_n),
    .io_in_0_bits_s1_entry_2_pbmt    (u_page_cache_resp_bits_stage1_entry_2_pbmt),
    .io_in_0_bits_s1_entry_2_perm_d  (u_page_cache_resp_bits_stage1_entry_2_perm_d),
    .io_in_0_bits_s1_entry_2_perm_a  (u_page_cache_resp_bits_stage1_entry_2_perm_a),
    .io_in_0_bits_s1_entry_2_perm_g  (u_page_cache_resp_bits_stage1_entry_2_perm_g),
    .io_in_0_bits_s1_entry_2_perm_u  (u_page_cache_resp_bits_stage1_entry_2_perm_u),
    .io_in_0_bits_s1_entry_2_perm_x  (u_page_cache_resp_bits_stage1_entry_2_perm_x),
    .io_in_0_bits_s1_entry_2_perm_w  (u_page_cache_resp_bits_stage1_entry_2_perm_w),
    .io_in_0_bits_s1_entry_2_perm_r  (u_page_cache_resp_bits_stage1_entry_2_perm_r),
    .io_in_0_bits_s1_entry_2_level   (u_page_cache_resp_bits_stage1_entry_2_level),
    .io_in_0_bits_s1_entry_2_v       (u_page_cache_resp_bits_stage1_entry_2_v),
    .io_in_0_bits_s1_entry_2_ppn     (u_page_cache_resp_bits_stage1_entry_2_ppn),
    .io_in_0_bits_s1_entry_2_ppn_low (u_page_cache_resp_bits_stage1_entry_2_ppn_low),
    .io_in_0_bits_s1_entry_2_pf      (u_page_cache_resp_bits_stage1_entry_2_pf),
    .io_in_0_bits_s1_entry_2_cf      (u_page_cache_resp_bits_stage1_entry_2_cf),
    .io_in_0_bits_s1_entry_3_tag     (u_page_cache_resp_bits_stage1_entry_3_tag),
    .io_in_0_bits_s1_entry_3_asid    (u_page_cache_resp_bits_stage1_entry_3_asid),
    .io_in_0_bits_s1_entry_3_vmid    (u_page_cache_resp_bits_stage1_entry_3_vmid),
    .io_in_0_bits_s1_entry_3_n       (u_page_cache_resp_bits_stage1_entry_3_n),
    .io_in_0_bits_s1_entry_3_pbmt    (u_page_cache_resp_bits_stage1_entry_3_pbmt),
    .io_in_0_bits_s1_entry_3_perm_d  (u_page_cache_resp_bits_stage1_entry_3_perm_d),
    .io_in_0_bits_s1_entry_3_perm_a  (u_page_cache_resp_bits_stage1_entry_3_perm_a),
    .io_in_0_bits_s1_entry_3_perm_g  (u_page_cache_resp_bits_stage1_entry_3_perm_g),
    .io_in_0_bits_s1_entry_3_perm_u  (u_page_cache_resp_bits_stage1_entry_3_perm_u),
    .io_in_0_bits_s1_entry_3_perm_x  (u_page_cache_resp_bits_stage1_entry_3_perm_x),
    .io_in_0_bits_s1_entry_3_perm_w  (u_page_cache_resp_bits_stage1_entry_3_perm_w),
    .io_in_0_bits_s1_entry_3_perm_r  (u_page_cache_resp_bits_stage1_entry_3_perm_r),
    .io_in_0_bits_s1_entry_3_level   (u_page_cache_resp_bits_stage1_entry_3_level),
    .io_in_0_bits_s1_entry_3_v       (u_page_cache_resp_bits_stage1_entry_3_v),
    .io_in_0_bits_s1_entry_3_ppn     (u_page_cache_resp_bits_stage1_entry_3_ppn),
    .io_in_0_bits_s1_entry_3_ppn_low (u_page_cache_resp_bits_stage1_entry_3_ppn_low),
    .io_in_0_bits_s1_entry_3_pf      (u_page_cache_resp_bits_stage1_entry_3_pf),
    .io_in_0_bits_s1_entry_3_cf      (u_page_cache_resp_bits_stage1_entry_3_cf),
    .io_in_0_bits_s1_entry_4_tag     (u_page_cache_resp_bits_stage1_entry_4_tag),
    .io_in_0_bits_s1_entry_4_asid    (u_page_cache_resp_bits_stage1_entry_4_asid),
    .io_in_0_bits_s1_entry_4_vmid    (u_page_cache_resp_bits_stage1_entry_4_vmid),
    .io_in_0_bits_s1_entry_4_n       (u_page_cache_resp_bits_stage1_entry_4_n),
    .io_in_0_bits_s1_entry_4_pbmt    (u_page_cache_resp_bits_stage1_entry_4_pbmt),
    .io_in_0_bits_s1_entry_4_perm_d  (u_page_cache_resp_bits_stage1_entry_4_perm_d),
    .io_in_0_bits_s1_entry_4_perm_a  (u_page_cache_resp_bits_stage1_entry_4_perm_a),
    .io_in_0_bits_s1_entry_4_perm_g  (u_page_cache_resp_bits_stage1_entry_4_perm_g),
    .io_in_0_bits_s1_entry_4_perm_u  (u_page_cache_resp_bits_stage1_entry_4_perm_u),
    .io_in_0_bits_s1_entry_4_perm_x  (u_page_cache_resp_bits_stage1_entry_4_perm_x),
    .io_in_0_bits_s1_entry_4_perm_w  (u_page_cache_resp_bits_stage1_entry_4_perm_w),
    .io_in_0_bits_s1_entry_4_perm_r  (u_page_cache_resp_bits_stage1_entry_4_perm_r),
    .io_in_0_bits_s1_entry_4_level   (u_page_cache_resp_bits_stage1_entry_4_level),
    .io_in_0_bits_s1_entry_4_v       (u_page_cache_resp_bits_stage1_entry_4_v),
    .io_in_0_bits_s1_entry_4_ppn     (u_page_cache_resp_bits_stage1_entry_4_ppn),
    .io_in_0_bits_s1_entry_4_ppn_low (u_page_cache_resp_bits_stage1_entry_4_ppn_low),
    .io_in_0_bits_s1_entry_4_pf      (u_page_cache_resp_bits_stage1_entry_4_pf),
    .io_in_0_bits_s1_entry_4_cf      (u_page_cache_resp_bits_stage1_entry_4_cf),
    .io_in_0_bits_s1_entry_5_tag     (u_page_cache_resp_bits_stage1_entry_5_tag),
    .io_in_0_bits_s1_entry_5_asid    (u_page_cache_resp_bits_stage1_entry_5_asid),
    .io_in_0_bits_s1_entry_5_vmid    (u_page_cache_resp_bits_stage1_entry_5_vmid),
    .io_in_0_bits_s1_entry_5_n       (u_page_cache_resp_bits_stage1_entry_5_n),
    .io_in_0_bits_s1_entry_5_pbmt    (u_page_cache_resp_bits_stage1_entry_5_pbmt),
    .io_in_0_bits_s1_entry_5_perm_d  (u_page_cache_resp_bits_stage1_entry_5_perm_d),
    .io_in_0_bits_s1_entry_5_perm_a  (u_page_cache_resp_bits_stage1_entry_5_perm_a),
    .io_in_0_bits_s1_entry_5_perm_g  (u_page_cache_resp_bits_stage1_entry_5_perm_g),
    .io_in_0_bits_s1_entry_5_perm_u  (u_page_cache_resp_bits_stage1_entry_5_perm_u),
    .io_in_0_bits_s1_entry_5_perm_x  (u_page_cache_resp_bits_stage1_entry_5_perm_x),
    .io_in_0_bits_s1_entry_5_perm_w  (u_page_cache_resp_bits_stage1_entry_5_perm_w),
    .io_in_0_bits_s1_entry_5_perm_r  (u_page_cache_resp_bits_stage1_entry_5_perm_r),
    .io_in_0_bits_s1_entry_5_level   (u_page_cache_resp_bits_stage1_entry_5_level),
    .io_in_0_bits_s1_entry_5_v       (u_page_cache_resp_bits_stage1_entry_5_v),
    .io_in_0_bits_s1_entry_5_ppn     (u_page_cache_resp_bits_stage1_entry_5_ppn),
    .io_in_0_bits_s1_entry_5_ppn_low (u_page_cache_resp_bits_stage1_entry_5_ppn_low),
    .io_in_0_bits_s1_entry_5_pf      (u_page_cache_resp_bits_stage1_entry_5_pf),
    .io_in_0_bits_s1_entry_5_cf      (u_page_cache_resp_bits_stage1_entry_5_cf),
    .io_in_0_bits_s1_entry_6_tag     (u_page_cache_resp_bits_stage1_entry_6_tag),
    .io_in_0_bits_s1_entry_6_asid    (u_page_cache_resp_bits_stage1_entry_6_asid),
    .io_in_0_bits_s1_entry_6_vmid    (u_page_cache_resp_bits_stage1_entry_6_vmid),
    .io_in_0_bits_s1_entry_6_n       (u_page_cache_resp_bits_stage1_entry_6_n),
    .io_in_0_bits_s1_entry_6_pbmt    (u_page_cache_resp_bits_stage1_entry_6_pbmt),
    .io_in_0_bits_s1_entry_6_perm_d  (u_page_cache_resp_bits_stage1_entry_6_perm_d),
    .io_in_0_bits_s1_entry_6_perm_a  (u_page_cache_resp_bits_stage1_entry_6_perm_a),
    .io_in_0_bits_s1_entry_6_perm_g  (u_page_cache_resp_bits_stage1_entry_6_perm_g),
    .io_in_0_bits_s1_entry_6_perm_u  (u_page_cache_resp_bits_stage1_entry_6_perm_u),
    .io_in_0_bits_s1_entry_6_perm_x  (u_page_cache_resp_bits_stage1_entry_6_perm_x),
    .io_in_0_bits_s1_entry_6_perm_w  (u_page_cache_resp_bits_stage1_entry_6_perm_w),
    .io_in_0_bits_s1_entry_6_perm_r  (u_page_cache_resp_bits_stage1_entry_6_perm_r),
    .io_in_0_bits_s1_entry_6_level   (u_page_cache_resp_bits_stage1_entry_6_level),
    .io_in_0_bits_s1_entry_6_v       (u_page_cache_resp_bits_stage1_entry_6_v),
    .io_in_0_bits_s1_entry_6_ppn     (u_page_cache_resp_bits_stage1_entry_6_ppn),
    .io_in_0_bits_s1_entry_6_ppn_low (u_page_cache_resp_bits_stage1_entry_6_ppn_low),
    .io_in_0_bits_s1_entry_6_pf      (u_page_cache_resp_bits_stage1_entry_6_pf),
    .io_in_0_bits_s1_entry_6_cf      (u_page_cache_resp_bits_stage1_entry_6_cf),
    .io_in_0_bits_s1_entry_7_tag     (u_page_cache_resp_bits_stage1_entry_7_tag),
    .io_in_0_bits_s1_entry_7_asid    (u_page_cache_resp_bits_stage1_entry_7_asid),
    .io_in_0_bits_s1_entry_7_vmid    (u_page_cache_resp_bits_stage1_entry_7_vmid),
    .io_in_0_bits_s1_entry_7_n       (u_page_cache_resp_bits_stage1_entry_7_n),
    .io_in_0_bits_s1_entry_7_pbmt    (u_page_cache_resp_bits_stage1_entry_7_pbmt),
    .io_in_0_bits_s1_entry_7_perm_d  (u_page_cache_resp_bits_stage1_entry_7_perm_d),
    .io_in_0_bits_s1_entry_7_perm_a  (u_page_cache_resp_bits_stage1_entry_7_perm_a),
    .io_in_0_bits_s1_entry_7_perm_g  (u_page_cache_resp_bits_stage1_entry_7_perm_g),
    .io_in_0_bits_s1_entry_7_perm_u  (u_page_cache_resp_bits_stage1_entry_7_perm_u),
    .io_in_0_bits_s1_entry_7_perm_x  (u_page_cache_resp_bits_stage1_entry_7_perm_x),
    .io_in_0_bits_s1_entry_7_perm_w  (u_page_cache_resp_bits_stage1_entry_7_perm_w),
    .io_in_0_bits_s1_entry_7_perm_r  (u_page_cache_resp_bits_stage1_entry_7_perm_r),
    .io_in_0_bits_s1_entry_7_level   (u_page_cache_resp_bits_stage1_entry_7_level),
    .io_in_0_bits_s1_entry_7_v       (u_page_cache_resp_bits_stage1_entry_7_v),
    .io_in_0_bits_s1_entry_7_ppn     (u_page_cache_resp_bits_stage1_entry_7_ppn),
    .io_in_0_bits_s1_entry_7_ppn_low (u_page_cache_resp_bits_stage1_entry_7_ppn_low),
    .io_in_0_bits_s1_entry_7_pf      (u_page_cache_resp_bits_stage1_entry_7_pf),
    .io_in_0_bits_s1_entry_7_cf      (u_page_cache_resp_bits_stage1_entry_7_cf),
    .io_in_0_bits_s1_pteidx_0        (u_page_cache_resp_bits_stage1_pteidx_0),
    .io_in_0_bits_s1_pteidx_1        (u_page_cache_resp_bits_stage1_pteidx_1),
    .io_in_0_bits_s1_pteidx_2        (u_page_cache_resp_bits_stage1_pteidx_2),
    .io_in_0_bits_s1_pteidx_3        (u_page_cache_resp_bits_stage1_pteidx_3),
    .io_in_0_bits_s1_pteidx_4        (u_page_cache_resp_bits_stage1_pteidx_4),
    .io_in_0_bits_s1_pteidx_5        (u_page_cache_resp_bits_stage1_pteidx_5),
    .io_in_0_bits_s1_pteidx_6        (u_page_cache_resp_bits_stage1_pteidx_6),
    .io_in_0_bits_s1_pteidx_7        (u_page_cache_resp_bits_stage1_pteidx_7),
    .io_in_0_bits_s1_not_super       (u_page_cache_resp_bits_stage1_not_super),
    .io_in_0_bits_s2_entry_tag       (u_page_cache_resp_bits_toHptw_resp_entry_tag),
    .io_in_0_bits_s2_entry_vmid      (u_page_cache_resp_bits_toHptw_resp_entry_vmid),
    .io_in_0_bits_s2_entry_n         (u_page_cache_resp_bits_toHptw_resp_entry_n),
    .io_in_0_bits_s2_entry_pbmt      (u_page_cache_resp_bits_toHptw_resp_entry_pbmt),
    .io_in_0_bits_s2_entry_ppn       (u_page_cache_resp_bits_toHptw_resp_entry_ppn),
    .io_in_0_bits_s2_entry_perm_d    (u_page_cache_resp_bits_toHptw_resp_entry_perm_d),
    .io_in_0_bits_s2_entry_perm_a    (u_page_cache_resp_bits_toHptw_resp_entry_perm_a),
    .io_in_0_bits_s2_entry_perm_g    (u_page_cache_resp_bits_toHptw_resp_entry_perm_g),
    .io_in_0_bits_s2_entry_perm_u    (u_page_cache_resp_bits_toHptw_resp_entry_perm_u),
    .io_in_0_bits_s2_entry_perm_x    (u_page_cache_resp_bits_toHptw_resp_entry_perm_x),
    .io_in_0_bits_s2_entry_perm_w    (u_page_cache_resp_bits_toHptw_resp_entry_perm_w),
    .io_in_0_bits_s2_entry_perm_r    (u_page_cache_resp_bits_toHptw_resp_entry_perm_r),
    .io_in_0_bits_s2_entry_level     (u_page_cache_resp_bits_toHptw_resp_entry_level),
    .io_in_0_bits_s2_gpf             (u_page_cache_resp_bits_toHptw_resp_gpf),
    .io_in_1_ready                   (u_merge_arb_0_in_1_ready),
    .io_in_1_valid                   (u_merge_arb_0__in_1_valid),
    .io_in_1_bits_s2xlate            (u_ptw_resp_bits_s2xlate),
    .io_in_1_bits_s1_entry_0_tag     (u_ptw_resp_bits_resp_entry_0_tag),
    .io_in_1_bits_s1_entry_0_asid    (u_ptw_resp_bits_resp_entry_0_asid),
    .io_in_1_bits_s1_entry_0_vmid    (u_ptw_resp_bits_resp_entry_0_vmid),
    .io_in_1_bits_s1_entry_0_n       (u_ptw_resp_bits_resp_entry_0_n),
    .io_in_1_bits_s1_entry_0_pbmt    (u_ptw_resp_bits_resp_entry_0_pbmt),
    .io_in_1_bits_s1_entry_0_perm_d  (u_ptw_resp_bits_resp_entry_0_perm_d),
    .io_in_1_bits_s1_entry_0_perm_a  (u_ptw_resp_bits_resp_entry_0_perm_a),
    .io_in_1_bits_s1_entry_0_perm_g  (u_ptw_resp_bits_resp_entry_0_perm_g),
    .io_in_1_bits_s1_entry_0_perm_u  (u_ptw_resp_bits_resp_entry_0_perm_u),
    .io_in_1_bits_s1_entry_0_perm_x  (u_ptw_resp_bits_resp_entry_0_perm_x),
    .io_in_1_bits_s1_entry_0_perm_w  (u_ptw_resp_bits_resp_entry_0_perm_w),
    .io_in_1_bits_s1_entry_0_perm_r  (u_ptw_resp_bits_resp_entry_0_perm_r),
    .io_in_1_bits_s1_entry_0_level   (u_ptw_resp_bits_resp_entry_0_level),
    .io_in_1_bits_s1_entry_0_v       (u_ptw_resp_bits_resp_entry_0_v),
    .io_in_1_bits_s1_entry_0_ppn     (u_ptw_resp_bits_resp_entry_0_ppn),
    .io_in_1_bits_s1_entry_0_ppn_low (u_ptw_resp_bits_resp_entry_0_ppn_low),
    .io_in_1_bits_s1_entry_0_af      (u_ptw_resp_bits_resp_entry_0_af),
    .io_in_1_bits_s1_entry_0_pf      (u_ptw_resp_bits_resp_entry_0_pf),
    .io_in_1_bits_s1_entry_0_cf      (u_ptw_resp_bits_resp_entry_0_cf),
    .io_in_1_bits_s1_entry_1_tag     (u_ptw_resp_bits_resp_entry_1_tag),
    .io_in_1_bits_s1_entry_1_asid    (u_ptw_resp_bits_resp_entry_1_asid),
    .io_in_1_bits_s1_entry_1_vmid    (u_ptw_resp_bits_resp_entry_1_vmid),
    .io_in_1_bits_s1_entry_1_n       (u_ptw_resp_bits_resp_entry_1_n),
    .io_in_1_bits_s1_entry_1_pbmt    (u_ptw_resp_bits_resp_entry_1_pbmt),
    .io_in_1_bits_s1_entry_1_perm_d  (u_ptw_resp_bits_resp_entry_1_perm_d),
    .io_in_1_bits_s1_entry_1_perm_a  (u_ptw_resp_bits_resp_entry_1_perm_a),
    .io_in_1_bits_s1_entry_1_perm_g  (u_ptw_resp_bits_resp_entry_1_perm_g),
    .io_in_1_bits_s1_entry_1_perm_u  (u_ptw_resp_bits_resp_entry_1_perm_u),
    .io_in_1_bits_s1_entry_1_perm_x  (u_ptw_resp_bits_resp_entry_1_perm_x),
    .io_in_1_bits_s1_entry_1_perm_w  (u_ptw_resp_bits_resp_entry_1_perm_w),
    .io_in_1_bits_s1_entry_1_perm_r  (u_ptw_resp_bits_resp_entry_1_perm_r),
    .io_in_1_bits_s1_entry_1_level   (u_ptw_resp_bits_resp_entry_1_level),
    .io_in_1_bits_s1_entry_1_v       (u_ptw_resp_bits_resp_entry_1_v),
    .io_in_1_bits_s1_entry_1_ppn     (u_ptw_resp_bits_resp_entry_1_ppn),
    .io_in_1_bits_s1_entry_1_ppn_low (u_ptw_resp_bits_resp_entry_1_ppn_low),
    .io_in_1_bits_s1_entry_1_af      (u_ptw_resp_bits_resp_entry_1_af),
    .io_in_1_bits_s1_entry_1_pf      (u_ptw_resp_bits_resp_entry_1_pf),
    .io_in_1_bits_s1_entry_1_cf      (u_ptw_resp_bits_resp_entry_1_cf),
    .io_in_1_bits_s1_entry_2_tag     (u_ptw_resp_bits_resp_entry_2_tag),
    .io_in_1_bits_s1_entry_2_asid    (u_ptw_resp_bits_resp_entry_2_asid),
    .io_in_1_bits_s1_entry_2_vmid    (u_ptw_resp_bits_resp_entry_2_vmid),
    .io_in_1_bits_s1_entry_2_n       (u_ptw_resp_bits_resp_entry_2_n),
    .io_in_1_bits_s1_entry_2_pbmt    (u_ptw_resp_bits_resp_entry_2_pbmt),
    .io_in_1_bits_s1_entry_2_perm_d  (u_ptw_resp_bits_resp_entry_2_perm_d),
    .io_in_1_bits_s1_entry_2_perm_a  (u_ptw_resp_bits_resp_entry_2_perm_a),
    .io_in_1_bits_s1_entry_2_perm_g  (u_ptw_resp_bits_resp_entry_2_perm_g),
    .io_in_1_bits_s1_entry_2_perm_u  (u_ptw_resp_bits_resp_entry_2_perm_u),
    .io_in_1_bits_s1_entry_2_perm_x  (u_ptw_resp_bits_resp_entry_2_perm_x),
    .io_in_1_bits_s1_entry_2_perm_w  (u_ptw_resp_bits_resp_entry_2_perm_w),
    .io_in_1_bits_s1_entry_2_perm_r  (u_ptw_resp_bits_resp_entry_2_perm_r),
    .io_in_1_bits_s1_entry_2_level   (u_ptw_resp_bits_resp_entry_2_level),
    .io_in_1_bits_s1_entry_2_v       (u_ptw_resp_bits_resp_entry_2_v),
    .io_in_1_bits_s1_entry_2_ppn     (u_ptw_resp_bits_resp_entry_2_ppn),
    .io_in_1_bits_s1_entry_2_ppn_low (u_ptw_resp_bits_resp_entry_2_ppn_low),
    .io_in_1_bits_s1_entry_2_af      (u_ptw_resp_bits_resp_entry_2_af),
    .io_in_1_bits_s1_entry_2_pf      (u_ptw_resp_bits_resp_entry_2_pf),
    .io_in_1_bits_s1_entry_2_cf      (u_ptw_resp_bits_resp_entry_2_cf),
    .io_in_1_bits_s1_entry_3_tag     (u_ptw_resp_bits_resp_entry_3_tag),
    .io_in_1_bits_s1_entry_3_asid    (u_ptw_resp_bits_resp_entry_3_asid),
    .io_in_1_bits_s1_entry_3_vmid    (u_ptw_resp_bits_resp_entry_3_vmid),
    .io_in_1_bits_s1_entry_3_n       (u_ptw_resp_bits_resp_entry_3_n),
    .io_in_1_bits_s1_entry_3_pbmt    (u_ptw_resp_bits_resp_entry_3_pbmt),
    .io_in_1_bits_s1_entry_3_perm_d  (u_ptw_resp_bits_resp_entry_3_perm_d),
    .io_in_1_bits_s1_entry_3_perm_a  (u_ptw_resp_bits_resp_entry_3_perm_a),
    .io_in_1_bits_s1_entry_3_perm_g  (u_ptw_resp_bits_resp_entry_3_perm_g),
    .io_in_1_bits_s1_entry_3_perm_u  (u_ptw_resp_bits_resp_entry_3_perm_u),
    .io_in_1_bits_s1_entry_3_perm_x  (u_ptw_resp_bits_resp_entry_3_perm_x),
    .io_in_1_bits_s1_entry_3_perm_w  (u_ptw_resp_bits_resp_entry_3_perm_w),
    .io_in_1_bits_s1_entry_3_perm_r  (u_ptw_resp_bits_resp_entry_3_perm_r),
    .io_in_1_bits_s1_entry_3_level   (u_ptw_resp_bits_resp_entry_3_level),
    .io_in_1_bits_s1_entry_3_v       (u_ptw_resp_bits_resp_entry_3_v),
    .io_in_1_bits_s1_entry_3_ppn     (u_ptw_resp_bits_resp_entry_3_ppn),
    .io_in_1_bits_s1_entry_3_ppn_low (u_ptw_resp_bits_resp_entry_3_ppn_low),
    .io_in_1_bits_s1_entry_3_af      (u_ptw_resp_bits_resp_entry_3_af),
    .io_in_1_bits_s1_entry_3_pf      (u_ptw_resp_bits_resp_entry_3_pf),
    .io_in_1_bits_s1_entry_3_cf      (u_ptw_resp_bits_resp_entry_3_cf),
    .io_in_1_bits_s1_entry_4_tag     (u_ptw_resp_bits_resp_entry_4_tag),
    .io_in_1_bits_s1_entry_4_asid    (u_ptw_resp_bits_resp_entry_4_asid),
    .io_in_1_bits_s1_entry_4_vmid    (u_ptw_resp_bits_resp_entry_4_vmid),
    .io_in_1_bits_s1_entry_4_n       (u_ptw_resp_bits_resp_entry_4_n),
    .io_in_1_bits_s1_entry_4_pbmt    (u_ptw_resp_bits_resp_entry_4_pbmt),
    .io_in_1_bits_s1_entry_4_perm_d  (u_ptw_resp_bits_resp_entry_4_perm_d),
    .io_in_1_bits_s1_entry_4_perm_a  (u_ptw_resp_bits_resp_entry_4_perm_a),
    .io_in_1_bits_s1_entry_4_perm_g  (u_ptw_resp_bits_resp_entry_4_perm_g),
    .io_in_1_bits_s1_entry_4_perm_u  (u_ptw_resp_bits_resp_entry_4_perm_u),
    .io_in_1_bits_s1_entry_4_perm_x  (u_ptw_resp_bits_resp_entry_4_perm_x),
    .io_in_1_bits_s1_entry_4_perm_w  (u_ptw_resp_bits_resp_entry_4_perm_w),
    .io_in_1_bits_s1_entry_4_perm_r  (u_ptw_resp_bits_resp_entry_4_perm_r),
    .io_in_1_bits_s1_entry_4_level   (u_ptw_resp_bits_resp_entry_4_level),
    .io_in_1_bits_s1_entry_4_v       (u_ptw_resp_bits_resp_entry_4_v),
    .io_in_1_bits_s1_entry_4_ppn     (u_ptw_resp_bits_resp_entry_4_ppn),
    .io_in_1_bits_s1_entry_4_ppn_low (u_ptw_resp_bits_resp_entry_4_ppn_low),
    .io_in_1_bits_s1_entry_4_af      (u_ptw_resp_bits_resp_entry_4_af),
    .io_in_1_bits_s1_entry_4_pf      (u_ptw_resp_bits_resp_entry_4_pf),
    .io_in_1_bits_s1_entry_4_cf      (u_ptw_resp_bits_resp_entry_4_cf),
    .io_in_1_bits_s1_entry_5_tag     (u_ptw_resp_bits_resp_entry_5_tag),
    .io_in_1_bits_s1_entry_5_asid    (u_ptw_resp_bits_resp_entry_5_asid),
    .io_in_1_bits_s1_entry_5_vmid    (u_ptw_resp_bits_resp_entry_5_vmid),
    .io_in_1_bits_s1_entry_5_n       (u_ptw_resp_bits_resp_entry_5_n),
    .io_in_1_bits_s1_entry_5_pbmt    (u_ptw_resp_bits_resp_entry_5_pbmt),
    .io_in_1_bits_s1_entry_5_perm_d  (u_ptw_resp_bits_resp_entry_5_perm_d),
    .io_in_1_bits_s1_entry_5_perm_a  (u_ptw_resp_bits_resp_entry_5_perm_a),
    .io_in_1_bits_s1_entry_5_perm_g  (u_ptw_resp_bits_resp_entry_5_perm_g),
    .io_in_1_bits_s1_entry_5_perm_u  (u_ptw_resp_bits_resp_entry_5_perm_u),
    .io_in_1_bits_s1_entry_5_perm_x  (u_ptw_resp_bits_resp_entry_5_perm_x),
    .io_in_1_bits_s1_entry_5_perm_w  (u_ptw_resp_bits_resp_entry_5_perm_w),
    .io_in_1_bits_s1_entry_5_perm_r  (u_ptw_resp_bits_resp_entry_5_perm_r),
    .io_in_1_bits_s1_entry_5_level   (u_ptw_resp_bits_resp_entry_5_level),
    .io_in_1_bits_s1_entry_5_v       (u_ptw_resp_bits_resp_entry_5_v),
    .io_in_1_bits_s1_entry_5_ppn     (u_ptw_resp_bits_resp_entry_5_ppn),
    .io_in_1_bits_s1_entry_5_ppn_low (u_ptw_resp_bits_resp_entry_5_ppn_low),
    .io_in_1_bits_s1_entry_5_af      (u_ptw_resp_bits_resp_entry_5_af),
    .io_in_1_bits_s1_entry_5_pf      (u_ptw_resp_bits_resp_entry_5_pf),
    .io_in_1_bits_s1_entry_5_cf      (u_ptw_resp_bits_resp_entry_5_cf),
    .io_in_1_bits_s1_entry_6_tag     (u_ptw_resp_bits_resp_entry_6_tag),
    .io_in_1_bits_s1_entry_6_asid    (u_ptw_resp_bits_resp_entry_6_asid),
    .io_in_1_bits_s1_entry_6_vmid    (u_ptw_resp_bits_resp_entry_6_vmid),
    .io_in_1_bits_s1_entry_6_n       (u_ptw_resp_bits_resp_entry_6_n),
    .io_in_1_bits_s1_entry_6_pbmt    (u_ptw_resp_bits_resp_entry_6_pbmt),
    .io_in_1_bits_s1_entry_6_perm_d  (u_ptw_resp_bits_resp_entry_6_perm_d),
    .io_in_1_bits_s1_entry_6_perm_a  (u_ptw_resp_bits_resp_entry_6_perm_a),
    .io_in_1_bits_s1_entry_6_perm_g  (u_ptw_resp_bits_resp_entry_6_perm_g),
    .io_in_1_bits_s1_entry_6_perm_u  (u_ptw_resp_bits_resp_entry_6_perm_u),
    .io_in_1_bits_s1_entry_6_perm_x  (u_ptw_resp_bits_resp_entry_6_perm_x),
    .io_in_1_bits_s1_entry_6_perm_w  (u_ptw_resp_bits_resp_entry_6_perm_w),
    .io_in_1_bits_s1_entry_6_perm_r  (u_ptw_resp_bits_resp_entry_6_perm_r),
    .io_in_1_bits_s1_entry_6_level   (u_ptw_resp_bits_resp_entry_6_level),
    .io_in_1_bits_s1_entry_6_v       (u_ptw_resp_bits_resp_entry_6_v),
    .io_in_1_bits_s1_entry_6_ppn     (u_ptw_resp_bits_resp_entry_6_ppn),
    .io_in_1_bits_s1_entry_6_ppn_low (u_ptw_resp_bits_resp_entry_6_ppn_low),
    .io_in_1_bits_s1_entry_6_af      (u_ptw_resp_bits_resp_entry_6_af),
    .io_in_1_bits_s1_entry_6_pf      (u_ptw_resp_bits_resp_entry_6_pf),
    .io_in_1_bits_s1_entry_6_cf      (u_ptw_resp_bits_resp_entry_6_cf),
    .io_in_1_bits_s1_entry_7_tag     (u_ptw_resp_bits_resp_entry_7_tag),
    .io_in_1_bits_s1_entry_7_asid    (u_ptw_resp_bits_resp_entry_7_asid),
    .io_in_1_bits_s1_entry_7_vmid    (u_ptw_resp_bits_resp_entry_7_vmid),
    .io_in_1_bits_s1_entry_7_n       (u_ptw_resp_bits_resp_entry_7_n),
    .io_in_1_bits_s1_entry_7_pbmt    (u_ptw_resp_bits_resp_entry_7_pbmt),
    .io_in_1_bits_s1_entry_7_perm_d  (u_ptw_resp_bits_resp_entry_7_perm_d),
    .io_in_1_bits_s1_entry_7_perm_a  (u_ptw_resp_bits_resp_entry_7_perm_a),
    .io_in_1_bits_s1_entry_7_perm_g  (u_ptw_resp_bits_resp_entry_7_perm_g),
    .io_in_1_bits_s1_entry_7_perm_u  (u_ptw_resp_bits_resp_entry_7_perm_u),
    .io_in_1_bits_s1_entry_7_perm_x  (u_ptw_resp_bits_resp_entry_7_perm_x),
    .io_in_1_bits_s1_entry_7_perm_w  (u_ptw_resp_bits_resp_entry_7_perm_w),
    .io_in_1_bits_s1_entry_7_perm_r  (u_ptw_resp_bits_resp_entry_7_perm_r),
    .io_in_1_bits_s1_entry_7_level   (u_ptw_resp_bits_resp_entry_7_level),
    .io_in_1_bits_s1_entry_7_v       (u_ptw_resp_bits_resp_entry_7_v),
    .io_in_1_bits_s1_entry_7_ppn     (u_ptw_resp_bits_resp_entry_7_ppn),
    .io_in_1_bits_s1_entry_7_ppn_low (u_ptw_resp_bits_resp_entry_7_ppn_low),
    .io_in_1_bits_s1_entry_7_af      (u_ptw_resp_bits_resp_entry_7_af),
    .io_in_1_bits_s1_entry_7_pf      (u_ptw_resp_bits_resp_entry_7_pf),
    .io_in_1_bits_s1_entry_7_cf      (u_ptw_resp_bits_resp_entry_7_cf),
    .io_in_1_bits_s1_pteidx_0        (u_ptw_resp_bits_resp_pteidx_0),
    .io_in_1_bits_s1_pteidx_1        (u_ptw_resp_bits_resp_pteidx_1),
    .io_in_1_bits_s1_pteidx_2        (u_ptw_resp_bits_resp_pteidx_2),
    .io_in_1_bits_s1_pteidx_3        (u_ptw_resp_bits_resp_pteidx_3),
    .io_in_1_bits_s1_pteidx_4        (u_ptw_resp_bits_resp_pteidx_4),
    .io_in_1_bits_s1_pteidx_5        (u_ptw_resp_bits_resp_pteidx_5),
    .io_in_1_bits_s1_pteidx_6        (u_ptw_resp_bits_resp_pteidx_6),
    .io_in_1_bits_s1_pteidx_7        (u_ptw_resp_bits_resp_pteidx_7),
    .io_in_1_bits_s1_not_super       (u_ptw_resp_bits_resp_not_super),
    .io_in_1_bits_s2_entry_tag       (u_ptw_resp_bits_h_resp_entry_tag),
    .io_in_1_bits_s2_entry_vmid      (u_ptw_resp_bits_h_resp_entry_vmid),
    .io_in_1_bits_s2_entry_n         (u_ptw_resp_bits_h_resp_entry_n),
    .io_in_1_bits_s2_entry_pbmt      (u_ptw_resp_bits_h_resp_entry_pbmt),
    .io_in_1_bits_s2_entry_ppn       (u_ptw_resp_bits_h_resp_entry_ppn),
    .io_in_1_bits_s2_entry_perm_d    (u_ptw_resp_bits_h_resp_entry_perm_d),
    .io_in_1_bits_s2_entry_perm_a    (u_ptw_resp_bits_h_resp_entry_perm_a),
    .io_in_1_bits_s2_entry_perm_g    (u_ptw_resp_bits_h_resp_entry_perm_g),
    .io_in_1_bits_s2_entry_perm_u    (u_ptw_resp_bits_h_resp_entry_perm_u),
    .io_in_1_bits_s2_entry_perm_x    (u_ptw_resp_bits_h_resp_entry_perm_x),
    .io_in_1_bits_s2_entry_perm_w    (u_ptw_resp_bits_h_resp_entry_perm_w),
    .io_in_1_bits_s2_entry_perm_r    (u_ptw_resp_bits_h_resp_entry_perm_r),
    .io_in_1_bits_s2_entry_level     (u_ptw_resp_bits_h_resp_entry_level),
    .io_in_1_bits_s2_gpf             (u_ptw_resp_bits_h_resp_gpf),
    .io_in_1_bits_s2_gaf             (u_ptw_resp_bits_h_resp_gaf),
    .io_in_2_ready                   (u_merge_arb_0_in_2_ready),
    .io_in_2_valid                   (u_merge_arb_0__in_2_valid),
    .io_in_2_bits_s2xlate            (u_llptw_out_bits_req_info_s2xlate),
    .io_in_2_bits_s1_entry_0_tag     (u_merge_arb_0__in_2_bits_s1_entry_0_tag),
    .io_in_2_bits_s1_entry_0_asid    (u_merge_arb_0__in_2_bits_s1_entry_0_asid),
    .io_in_2_bits_s1_entry_0_vmid    (u_merge_arb_0__in_2_bits_s1_entry_0_vmid),
    .io_in_2_bits_s1_entry_0_n       (u_merge_arb_0__in_2_bits_s1_entry_0_n),
    .io_in_2_bits_s1_entry_0_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_0_pbmt),
    .io_in_2_bits_s1_entry_0_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_d),
    .io_in_2_bits_s1_entry_0_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_a),
    .io_in_2_bits_s1_entry_0_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_g),
    .io_in_2_bits_s1_entry_0_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_u),
    .io_in_2_bits_s1_entry_0_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_x),
    .io_in_2_bits_s1_entry_0_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_w),
    .io_in_2_bits_s1_entry_0_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_0_perm_r),
    .io_in_2_bits_s1_entry_0_level   (u_merge_arb_0__in_2_bits_s1_entry_0_level),
    .io_in_2_bits_s1_entry_0_v       (u_merge_arb_0__in_2_bits_s1_entry_0_v),
    .io_in_2_bits_s1_entry_0_ppn     (u_merge_arb_0__in_2_bits_s1_entry_0_ppn),
    .io_in_2_bits_s1_entry_0_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_0_ppn_low),
    .io_in_2_bits_s1_entry_0_af      (u_merge_arb_0__in_2_bits_s1_entry_0_af),
    .io_in_2_bits_s1_entry_0_pf      (u_merge_arb_0__in_2_bits_s1_entry_0_pf),
    .io_in_2_bits_s1_entry_0_cf      (u_merge_arb_0__in_2_bits_s1_entry_0_cf),
    .io_in_2_bits_s1_entry_1_tag     (u_merge_arb_0__in_2_bits_s1_entry_1_tag),
    .io_in_2_bits_s1_entry_1_asid    (u_merge_arb_0__in_2_bits_s1_entry_1_asid),
    .io_in_2_bits_s1_entry_1_vmid    (u_merge_arb_0__in_2_bits_s1_entry_1_vmid),
    .io_in_2_bits_s1_entry_1_n       (u_merge_arb_0__in_2_bits_s1_entry_1_n),
    .io_in_2_bits_s1_entry_1_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_1_pbmt),
    .io_in_2_bits_s1_entry_1_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_d),
    .io_in_2_bits_s1_entry_1_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_a),
    .io_in_2_bits_s1_entry_1_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_g),
    .io_in_2_bits_s1_entry_1_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_u),
    .io_in_2_bits_s1_entry_1_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_x),
    .io_in_2_bits_s1_entry_1_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_w),
    .io_in_2_bits_s1_entry_1_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_1_perm_r),
    .io_in_2_bits_s1_entry_1_level   (u_merge_arb_0__in_2_bits_s1_entry_1_level),
    .io_in_2_bits_s1_entry_1_v       (u_merge_arb_0__in_2_bits_s1_entry_1_v),
    .io_in_2_bits_s1_entry_1_ppn     (u_merge_arb_0__in_2_bits_s1_entry_1_ppn),
    .io_in_2_bits_s1_entry_1_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_1_ppn_low),
    .io_in_2_bits_s1_entry_1_af      (u_merge_arb_0__in_2_bits_s1_entry_1_af),
    .io_in_2_bits_s1_entry_1_pf      (u_merge_arb_0__in_2_bits_s1_entry_1_pf),
    .io_in_2_bits_s1_entry_1_cf      (u_merge_arb_0__in_2_bits_s1_entry_1_cf),
    .io_in_2_bits_s1_entry_2_tag     (u_merge_arb_0__in_2_bits_s1_entry_2_tag),
    .io_in_2_bits_s1_entry_2_asid    (u_merge_arb_0__in_2_bits_s1_entry_2_asid),
    .io_in_2_bits_s1_entry_2_vmid    (u_merge_arb_0__in_2_bits_s1_entry_2_vmid),
    .io_in_2_bits_s1_entry_2_n       (u_merge_arb_0__in_2_bits_s1_entry_2_n),
    .io_in_2_bits_s1_entry_2_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_2_pbmt),
    .io_in_2_bits_s1_entry_2_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_d),
    .io_in_2_bits_s1_entry_2_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_a),
    .io_in_2_bits_s1_entry_2_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_g),
    .io_in_2_bits_s1_entry_2_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_u),
    .io_in_2_bits_s1_entry_2_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_x),
    .io_in_2_bits_s1_entry_2_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_w),
    .io_in_2_bits_s1_entry_2_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_2_perm_r),
    .io_in_2_bits_s1_entry_2_level   (u_merge_arb_0__in_2_bits_s1_entry_2_level),
    .io_in_2_bits_s1_entry_2_v       (u_merge_arb_0__in_2_bits_s1_entry_2_v),
    .io_in_2_bits_s1_entry_2_ppn     (u_merge_arb_0__in_2_bits_s1_entry_2_ppn),
    .io_in_2_bits_s1_entry_2_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_2_ppn_low),
    .io_in_2_bits_s1_entry_2_af      (u_merge_arb_0__in_2_bits_s1_entry_2_af),
    .io_in_2_bits_s1_entry_2_pf      (u_merge_arb_0__in_2_bits_s1_entry_2_pf),
    .io_in_2_bits_s1_entry_2_cf      (u_merge_arb_0__in_2_bits_s1_entry_2_cf),
    .io_in_2_bits_s1_entry_3_tag     (u_merge_arb_0__in_2_bits_s1_entry_3_tag),
    .io_in_2_bits_s1_entry_3_asid    (u_merge_arb_0__in_2_bits_s1_entry_3_asid),
    .io_in_2_bits_s1_entry_3_vmid    (u_merge_arb_0__in_2_bits_s1_entry_3_vmid),
    .io_in_2_bits_s1_entry_3_n       (u_merge_arb_0__in_2_bits_s1_entry_3_n),
    .io_in_2_bits_s1_entry_3_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_3_pbmt),
    .io_in_2_bits_s1_entry_3_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_d),
    .io_in_2_bits_s1_entry_3_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_a),
    .io_in_2_bits_s1_entry_3_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_g),
    .io_in_2_bits_s1_entry_3_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_u),
    .io_in_2_bits_s1_entry_3_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_x),
    .io_in_2_bits_s1_entry_3_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_w),
    .io_in_2_bits_s1_entry_3_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_3_perm_r),
    .io_in_2_bits_s1_entry_3_level   (u_merge_arb_0__in_2_bits_s1_entry_3_level),
    .io_in_2_bits_s1_entry_3_v       (u_merge_arb_0__in_2_bits_s1_entry_3_v),
    .io_in_2_bits_s1_entry_3_ppn     (u_merge_arb_0__in_2_bits_s1_entry_3_ppn),
    .io_in_2_bits_s1_entry_3_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_3_ppn_low),
    .io_in_2_bits_s1_entry_3_af      (u_merge_arb_0__in_2_bits_s1_entry_3_af),
    .io_in_2_bits_s1_entry_3_pf      (u_merge_arb_0__in_2_bits_s1_entry_3_pf),
    .io_in_2_bits_s1_entry_3_cf      (u_merge_arb_0__in_2_bits_s1_entry_3_cf),
    .io_in_2_bits_s1_entry_4_tag     (u_merge_arb_0__in_2_bits_s1_entry_4_tag),
    .io_in_2_bits_s1_entry_4_asid    (u_merge_arb_0__in_2_bits_s1_entry_4_asid),
    .io_in_2_bits_s1_entry_4_vmid    (u_merge_arb_0__in_2_bits_s1_entry_4_vmid),
    .io_in_2_bits_s1_entry_4_n       (u_merge_arb_0__in_2_bits_s1_entry_4_n),
    .io_in_2_bits_s1_entry_4_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_4_pbmt),
    .io_in_2_bits_s1_entry_4_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_d),
    .io_in_2_bits_s1_entry_4_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_a),
    .io_in_2_bits_s1_entry_4_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_g),
    .io_in_2_bits_s1_entry_4_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_u),
    .io_in_2_bits_s1_entry_4_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_x),
    .io_in_2_bits_s1_entry_4_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_w),
    .io_in_2_bits_s1_entry_4_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_4_perm_r),
    .io_in_2_bits_s1_entry_4_level   (u_merge_arb_0__in_2_bits_s1_entry_4_level),
    .io_in_2_bits_s1_entry_4_v       (u_merge_arb_0__in_2_bits_s1_entry_4_v),
    .io_in_2_bits_s1_entry_4_ppn     (u_merge_arb_0__in_2_bits_s1_entry_4_ppn),
    .io_in_2_bits_s1_entry_4_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_4_ppn_low),
    .io_in_2_bits_s1_entry_4_af      (u_merge_arb_0__in_2_bits_s1_entry_4_af),
    .io_in_2_bits_s1_entry_4_pf      (u_merge_arb_0__in_2_bits_s1_entry_4_pf),
    .io_in_2_bits_s1_entry_4_cf      (u_merge_arb_0__in_2_bits_s1_entry_4_cf),
    .io_in_2_bits_s1_entry_5_tag     (u_merge_arb_0__in_2_bits_s1_entry_5_tag),
    .io_in_2_bits_s1_entry_5_asid    (u_merge_arb_0__in_2_bits_s1_entry_5_asid),
    .io_in_2_bits_s1_entry_5_vmid    (u_merge_arb_0__in_2_bits_s1_entry_5_vmid),
    .io_in_2_bits_s1_entry_5_n       (u_merge_arb_0__in_2_bits_s1_entry_5_n),
    .io_in_2_bits_s1_entry_5_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_5_pbmt),
    .io_in_2_bits_s1_entry_5_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_d),
    .io_in_2_bits_s1_entry_5_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_a),
    .io_in_2_bits_s1_entry_5_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_g),
    .io_in_2_bits_s1_entry_5_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_u),
    .io_in_2_bits_s1_entry_5_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_x),
    .io_in_2_bits_s1_entry_5_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_w),
    .io_in_2_bits_s1_entry_5_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_5_perm_r),
    .io_in_2_bits_s1_entry_5_level   (u_merge_arb_0__in_2_bits_s1_entry_5_level),
    .io_in_2_bits_s1_entry_5_v       (u_merge_arb_0__in_2_bits_s1_entry_5_v),
    .io_in_2_bits_s1_entry_5_ppn     (u_merge_arb_0__in_2_bits_s1_entry_5_ppn),
    .io_in_2_bits_s1_entry_5_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_5_ppn_low),
    .io_in_2_bits_s1_entry_5_af      (u_merge_arb_0__in_2_bits_s1_entry_5_af),
    .io_in_2_bits_s1_entry_5_pf      (u_merge_arb_0__in_2_bits_s1_entry_5_pf),
    .io_in_2_bits_s1_entry_5_cf      (u_merge_arb_0__in_2_bits_s1_entry_5_cf),
    .io_in_2_bits_s1_entry_6_tag     (u_merge_arb_0__in_2_bits_s1_entry_6_tag),
    .io_in_2_bits_s1_entry_6_asid    (u_merge_arb_0__in_2_bits_s1_entry_6_asid),
    .io_in_2_bits_s1_entry_6_vmid    (u_merge_arb_0__in_2_bits_s1_entry_6_vmid),
    .io_in_2_bits_s1_entry_6_n       (u_merge_arb_0__in_2_bits_s1_entry_6_n),
    .io_in_2_bits_s1_entry_6_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_6_pbmt),
    .io_in_2_bits_s1_entry_6_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_d),
    .io_in_2_bits_s1_entry_6_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_a),
    .io_in_2_bits_s1_entry_6_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_g),
    .io_in_2_bits_s1_entry_6_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_u),
    .io_in_2_bits_s1_entry_6_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_x),
    .io_in_2_bits_s1_entry_6_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_w),
    .io_in_2_bits_s1_entry_6_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_6_perm_r),
    .io_in_2_bits_s1_entry_6_level   (u_merge_arb_0__in_2_bits_s1_entry_6_level),
    .io_in_2_bits_s1_entry_6_v       (u_merge_arb_0__in_2_bits_s1_entry_6_v),
    .io_in_2_bits_s1_entry_6_ppn     (u_merge_arb_0__in_2_bits_s1_entry_6_ppn),
    .io_in_2_bits_s1_entry_6_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_6_ppn_low),
    .io_in_2_bits_s1_entry_6_af      (u_merge_arb_0__in_2_bits_s1_entry_6_af),
    .io_in_2_bits_s1_entry_6_pf      (u_merge_arb_0__in_2_bits_s1_entry_6_pf),
    .io_in_2_bits_s1_entry_6_cf      (u_merge_arb_0__in_2_bits_s1_entry_6_cf),
    .io_in_2_bits_s1_entry_7_tag     (u_merge_arb_0__in_2_bits_s1_entry_7_tag),
    .io_in_2_bits_s1_entry_7_asid    (u_merge_arb_0__in_2_bits_s1_entry_7_asid),
    .io_in_2_bits_s1_entry_7_vmid    (u_merge_arb_0__in_2_bits_s1_entry_7_vmid),
    .io_in_2_bits_s1_entry_7_n       (u_merge_arb_0__in_2_bits_s1_entry_7_n),
    .io_in_2_bits_s1_entry_7_pbmt    (u_merge_arb_0__in_2_bits_s1_entry_7_pbmt),
    .io_in_2_bits_s1_entry_7_perm_d  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_d),
    .io_in_2_bits_s1_entry_7_perm_a  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_a),
    .io_in_2_bits_s1_entry_7_perm_g  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_g),
    .io_in_2_bits_s1_entry_7_perm_u  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_u),
    .io_in_2_bits_s1_entry_7_perm_x  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_x),
    .io_in_2_bits_s1_entry_7_perm_w  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_w),
    .io_in_2_bits_s1_entry_7_perm_r  (u_merge_arb_0__in_2_bits_s1_entry_7_perm_r),
    .io_in_2_bits_s1_entry_7_level   (u_merge_arb_0__in_2_bits_s1_entry_7_level),
    .io_in_2_bits_s1_entry_7_v       (u_merge_arb_0__in_2_bits_s1_entry_7_v),
    .io_in_2_bits_s1_entry_7_ppn     (u_merge_arb_0__in_2_bits_s1_entry_7_ppn),
    .io_in_2_bits_s1_entry_7_ppn_low (u_merge_arb_0__in_2_bits_s1_entry_7_ppn_low),
    .io_in_2_bits_s1_entry_7_af      (u_merge_arb_0__in_2_bits_s1_entry_7_af),
    .io_in_2_bits_s1_entry_7_pf      (u_merge_arb_0__in_2_bits_s1_entry_7_pf),
    .io_in_2_bits_s1_entry_7_cf      (u_merge_arb_0__in_2_bits_s1_entry_7_cf),
    .io_in_2_bits_s1_pteidx_0        (u_merge_arb_0__in_2_bits_s1_pteidx_0),
    .io_in_2_bits_s1_pteidx_1        (u_merge_arb_0__in_2_bits_s1_pteidx_1),
    .io_in_2_bits_s1_pteidx_2        (u_merge_arb_0__in_2_bits_s1_pteidx_2),
    .io_in_2_bits_s1_pteidx_3        (u_merge_arb_0__in_2_bits_s1_pteidx_3),
    .io_in_2_bits_s1_pteidx_4        (u_merge_arb_0__in_2_bits_s1_pteidx_4),
    .io_in_2_bits_s1_pteidx_5        (u_merge_arb_0__in_2_bits_s1_pteidx_5),
    .io_in_2_bits_s1_pteidx_6        (u_merge_arb_0__in_2_bits_s1_pteidx_6),
    .io_in_2_bits_s1_pteidx_7        (u_merge_arb_0__in_2_bits_s1_pteidx_7),
    .io_in_2_bits_s1_not_super       (u_merge_arb_0__in_2_bits_s1_not_super),
    .io_in_2_bits_s1_not_merge       (u_merge_arb_0__in_2_bits_s1_not_merge),
    .io_in_2_bits_s2_entry_tag       (u_llptw_out_bits_h_resp_entry_tag),
    .io_in_2_bits_s2_entry_vmid      (u_llptw_out_bits_h_resp_entry_vmid),
    .io_in_2_bits_s2_entry_n         (u_llptw_out_bits_h_resp_entry_n),
    .io_in_2_bits_s2_entry_pbmt      (u_llptw_out_bits_h_resp_entry_pbmt),
    .io_in_2_bits_s2_entry_ppn       (u_llptw_out_bits_h_resp_entry_ppn),
    .io_in_2_bits_s2_entry_perm_d    (u_llptw_out_bits_h_resp_entry_perm_d),
    .io_in_2_bits_s2_entry_perm_a    (u_llptw_out_bits_h_resp_entry_perm_a),
    .io_in_2_bits_s2_entry_perm_g    (u_llptw_out_bits_h_resp_entry_perm_g),
    .io_in_2_bits_s2_entry_perm_u    (u_llptw_out_bits_h_resp_entry_perm_u),
    .io_in_2_bits_s2_entry_perm_x    (u_llptw_out_bits_h_resp_entry_perm_x),
    .io_in_2_bits_s2_entry_perm_w    (u_llptw_out_bits_h_resp_entry_perm_w),
    .io_in_2_bits_s2_entry_perm_r    (u_llptw_out_bits_h_resp_entry_perm_r),
    .io_in_2_bits_s2_entry_level     (u_llptw_out_bits_h_resp_entry_level),
    .io_in_2_bits_s2_gpf             (u_llptw_out_bits_h_resp_gpf),
    .io_in_2_bits_s2_gaf             (u_llptw_out_bits_h_resp_gaf),
    .io_out_ready                    (u_out_arb_0_in_0_ready),
    .io_out_valid                    (u_merge_arb_0_out_valid),
    .io_out_bits_s2xlate             (u_merge_arb_0_out_bits_s2xlate),
    .io_out_bits_s1_entry_0_tag      (u_merge_arb_0_out_bits_s1_entry_0_tag),
    .io_out_bits_s1_entry_0_asid     (u_merge_arb_0_out_bits_s1_entry_0_asid),
    .io_out_bits_s1_entry_0_vmid     (u_merge_arb_0_out_bits_s1_entry_0_vmid),
    .io_out_bits_s1_entry_0_n        (u_merge_arb_0_out_bits_s1_entry_0_n),
    .io_out_bits_s1_entry_0_pbmt     (u_merge_arb_0_out_bits_s1_entry_0_pbmt),
    .io_out_bits_s1_entry_0_perm_d   (u_merge_arb_0_out_bits_s1_entry_0_perm_d),
    .io_out_bits_s1_entry_0_perm_a   (u_merge_arb_0_out_bits_s1_entry_0_perm_a),
    .io_out_bits_s1_entry_0_perm_g   (u_merge_arb_0_out_bits_s1_entry_0_perm_g),
    .io_out_bits_s1_entry_0_perm_u   (u_merge_arb_0_out_bits_s1_entry_0_perm_u),
    .io_out_bits_s1_entry_0_perm_x   (u_merge_arb_0_out_bits_s1_entry_0_perm_x),
    .io_out_bits_s1_entry_0_perm_w   (u_merge_arb_0_out_bits_s1_entry_0_perm_w),
    .io_out_bits_s1_entry_0_perm_r   (u_merge_arb_0_out_bits_s1_entry_0_perm_r),
    .io_out_bits_s1_entry_0_level    (u_merge_arb_0_out_bits_s1_entry_0_level),
    .io_out_bits_s1_entry_0_v        (u_merge_arb_0_out_bits_s1_entry_0_v),
    .io_out_bits_s1_entry_0_ppn      (u_merge_arb_0_out_bits_s1_entry_0_ppn),
    .io_out_bits_s1_entry_0_ppn_low  (u_merge_arb_0_out_bits_s1_entry_0_ppn_low),
    .io_out_bits_s1_entry_0_af       (u_merge_arb_0_out_bits_s1_entry_0_af),
    .io_out_bits_s1_entry_0_pf       (u_merge_arb_0_out_bits_s1_entry_0_pf),
    .io_out_bits_s1_entry_0_cf       (u_merge_arb_0_out_bits_s1_entry_0_cf),
    .io_out_bits_s1_entry_1_tag      (u_merge_arb_0_out_bits_s1_entry_1_tag),
    .io_out_bits_s1_entry_1_asid     (u_merge_arb_0_out_bits_s1_entry_1_asid),
    .io_out_bits_s1_entry_1_vmid     (u_merge_arb_0_out_bits_s1_entry_1_vmid),
    .io_out_bits_s1_entry_1_n        (u_merge_arb_0_out_bits_s1_entry_1_n),
    .io_out_bits_s1_entry_1_pbmt     (u_merge_arb_0_out_bits_s1_entry_1_pbmt),
    .io_out_bits_s1_entry_1_perm_d   (u_merge_arb_0_out_bits_s1_entry_1_perm_d),
    .io_out_bits_s1_entry_1_perm_a   (u_merge_arb_0_out_bits_s1_entry_1_perm_a),
    .io_out_bits_s1_entry_1_perm_g   (u_merge_arb_0_out_bits_s1_entry_1_perm_g),
    .io_out_bits_s1_entry_1_perm_u   (u_merge_arb_0_out_bits_s1_entry_1_perm_u),
    .io_out_bits_s1_entry_1_perm_x   (u_merge_arb_0_out_bits_s1_entry_1_perm_x),
    .io_out_bits_s1_entry_1_perm_w   (u_merge_arb_0_out_bits_s1_entry_1_perm_w),
    .io_out_bits_s1_entry_1_perm_r   (u_merge_arb_0_out_bits_s1_entry_1_perm_r),
    .io_out_bits_s1_entry_1_level    (u_merge_arb_0_out_bits_s1_entry_1_level),
    .io_out_bits_s1_entry_1_v        (u_merge_arb_0_out_bits_s1_entry_1_v),
    .io_out_bits_s1_entry_1_ppn      (u_merge_arb_0_out_bits_s1_entry_1_ppn),
    .io_out_bits_s1_entry_1_ppn_low  (u_merge_arb_0_out_bits_s1_entry_1_ppn_low),
    .io_out_bits_s1_entry_1_af       (u_merge_arb_0_out_bits_s1_entry_1_af),
    .io_out_bits_s1_entry_1_pf       (u_merge_arb_0_out_bits_s1_entry_1_pf),
    .io_out_bits_s1_entry_1_cf       (u_merge_arb_0_out_bits_s1_entry_1_cf),
    .io_out_bits_s1_entry_2_tag      (u_merge_arb_0_out_bits_s1_entry_2_tag),
    .io_out_bits_s1_entry_2_asid     (u_merge_arb_0_out_bits_s1_entry_2_asid),
    .io_out_bits_s1_entry_2_vmid     (u_merge_arb_0_out_bits_s1_entry_2_vmid),
    .io_out_bits_s1_entry_2_n        (u_merge_arb_0_out_bits_s1_entry_2_n),
    .io_out_bits_s1_entry_2_pbmt     (u_merge_arb_0_out_bits_s1_entry_2_pbmt),
    .io_out_bits_s1_entry_2_perm_d   (u_merge_arb_0_out_bits_s1_entry_2_perm_d),
    .io_out_bits_s1_entry_2_perm_a   (u_merge_arb_0_out_bits_s1_entry_2_perm_a),
    .io_out_bits_s1_entry_2_perm_g   (u_merge_arb_0_out_bits_s1_entry_2_perm_g),
    .io_out_bits_s1_entry_2_perm_u   (u_merge_arb_0_out_bits_s1_entry_2_perm_u),
    .io_out_bits_s1_entry_2_perm_x   (u_merge_arb_0_out_bits_s1_entry_2_perm_x),
    .io_out_bits_s1_entry_2_perm_w   (u_merge_arb_0_out_bits_s1_entry_2_perm_w),
    .io_out_bits_s1_entry_2_perm_r   (u_merge_arb_0_out_bits_s1_entry_2_perm_r),
    .io_out_bits_s1_entry_2_level    (u_merge_arb_0_out_bits_s1_entry_2_level),
    .io_out_bits_s1_entry_2_v        (u_merge_arb_0_out_bits_s1_entry_2_v),
    .io_out_bits_s1_entry_2_ppn      (u_merge_arb_0_out_bits_s1_entry_2_ppn),
    .io_out_bits_s1_entry_2_ppn_low  (u_merge_arb_0_out_bits_s1_entry_2_ppn_low),
    .io_out_bits_s1_entry_2_af       (u_merge_arb_0_out_bits_s1_entry_2_af),
    .io_out_bits_s1_entry_2_pf       (u_merge_arb_0_out_bits_s1_entry_2_pf),
    .io_out_bits_s1_entry_2_cf       (u_merge_arb_0_out_bits_s1_entry_2_cf),
    .io_out_bits_s1_entry_3_tag      (u_merge_arb_0_out_bits_s1_entry_3_tag),
    .io_out_bits_s1_entry_3_asid     (u_merge_arb_0_out_bits_s1_entry_3_asid),
    .io_out_bits_s1_entry_3_vmid     (u_merge_arb_0_out_bits_s1_entry_3_vmid),
    .io_out_bits_s1_entry_3_n        (u_merge_arb_0_out_bits_s1_entry_3_n),
    .io_out_bits_s1_entry_3_pbmt     (u_merge_arb_0_out_bits_s1_entry_3_pbmt),
    .io_out_bits_s1_entry_3_perm_d   (u_merge_arb_0_out_bits_s1_entry_3_perm_d),
    .io_out_bits_s1_entry_3_perm_a   (u_merge_arb_0_out_bits_s1_entry_3_perm_a),
    .io_out_bits_s1_entry_3_perm_g   (u_merge_arb_0_out_bits_s1_entry_3_perm_g),
    .io_out_bits_s1_entry_3_perm_u   (u_merge_arb_0_out_bits_s1_entry_3_perm_u),
    .io_out_bits_s1_entry_3_perm_x   (u_merge_arb_0_out_bits_s1_entry_3_perm_x),
    .io_out_bits_s1_entry_3_perm_w   (u_merge_arb_0_out_bits_s1_entry_3_perm_w),
    .io_out_bits_s1_entry_3_perm_r   (u_merge_arb_0_out_bits_s1_entry_3_perm_r),
    .io_out_bits_s1_entry_3_level    (u_merge_arb_0_out_bits_s1_entry_3_level),
    .io_out_bits_s1_entry_3_v        (u_merge_arb_0_out_bits_s1_entry_3_v),
    .io_out_bits_s1_entry_3_ppn      (u_merge_arb_0_out_bits_s1_entry_3_ppn),
    .io_out_bits_s1_entry_3_ppn_low  (u_merge_arb_0_out_bits_s1_entry_3_ppn_low),
    .io_out_bits_s1_entry_3_af       (u_merge_arb_0_out_bits_s1_entry_3_af),
    .io_out_bits_s1_entry_3_pf       (u_merge_arb_0_out_bits_s1_entry_3_pf),
    .io_out_bits_s1_entry_3_cf       (u_merge_arb_0_out_bits_s1_entry_3_cf),
    .io_out_bits_s1_entry_4_tag      (u_merge_arb_0_out_bits_s1_entry_4_tag),
    .io_out_bits_s1_entry_4_asid     (u_merge_arb_0_out_bits_s1_entry_4_asid),
    .io_out_bits_s1_entry_4_vmid     (u_merge_arb_0_out_bits_s1_entry_4_vmid),
    .io_out_bits_s1_entry_4_n        (u_merge_arb_0_out_bits_s1_entry_4_n),
    .io_out_bits_s1_entry_4_pbmt     (u_merge_arb_0_out_bits_s1_entry_4_pbmt),
    .io_out_bits_s1_entry_4_perm_d   (u_merge_arb_0_out_bits_s1_entry_4_perm_d),
    .io_out_bits_s1_entry_4_perm_a   (u_merge_arb_0_out_bits_s1_entry_4_perm_a),
    .io_out_bits_s1_entry_4_perm_g   (u_merge_arb_0_out_bits_s1_entry_4_perm_g),
    .io_out_bits_s1_entry_4_perm_u   (u_merge_arb_0_out_bits_s1_entry_4_perm_u),
    .io_out_bits_s1_entry_4_perm_x   (u_merge_arb_0_out_bits_s1_entry_4_perm_x),
    .io_out_bits_s1_entry_4_perm_w   (u_merge_arb_0_out_bits_s1_entry_4_perm_w),
    .io_out_bits_s1_entry_4_perm_r   (u_merge_arb_0_out_bits_s1_entry_4_perm_r),
    .io_out_bits_s1_entry_4_level    (u_merge_arb_0_out_bits_s1_entry_4_level),
    .io_out_bits_s1_entry_4_v        (u_merge_arb_0_out_bits_s1_entry_4_v),
    .io_out_bits_s1_entry_4_ppn      (u_merge_arb_0_out_bits_s1_entry_4_ppn),
    .io_out_bits_s1_entry_4_ppn_low  (u_merge_arb_0_out_bits_s1_entry_4_ppn_low),
    .io_out_bits_s1_entry_4_af       (u_merge_arb_0_out_bits_s1_entry_4_af),
    .io_out_bits_s1_entry_4_pf       (u_merge_arb_0_out_bits_s1_entry_4_pf),
    .io_out_bits_s1_entry_4_cf       (u_merge_arb_0_out_bits_s1_entry_4_cf),
    .io_out_bits_s1_entry_5_tag      (u_merge_arb_0_out_bits_s1_entry_5_tag),
    .io_out_bits_s1_entry_5_asid     (u_merge_arb_0_out_bits_s1_entry_5_asid),
    .io_out_bits_s1_entry_5_vmid     (u_merge_arb_0_out_bits_s1_entry_5_vmid),
    .io_out_bits_s1_entry_5_n        (u_merge_arb_0_out_bits_s1_entry_5_n),
    .io_out_bits_s1_entry_5_pbmt     (u_merge_arb_0_out_bits_s1_entry_5_pbmt),
    .io_out_bits_s1_entry_5_perm_d   (u_merge_arb_0_out_bits_s1_entry_5_perm_d),
    .io_out_bits_s1_entry_5_perm_a   (u_merge_arb_0_out_bits_s1_entry_5_perm_a),
    .io_out_bits_s1_entry_5_perm_g   (u_merge_arb_0_out_bits_s1_entry_5_perm_g),
    .io_out_bits_s1_entry_5_perm_u   (u_merge_arb_0_out_bits_s1_entry_5_perm_u),
    .io_out_bits_s1_entry_5_perm_x   (u_merge_arb_0_out_bits_s1_entry_5_perm_x),
    .io_out_bits_s1_entry_5_perm_w   (u_merge_arb_0_out_bits_s1_entry_5_perm_w),
    .io_out_bits_s1_entry_5_perm_r   (u_merge_arb_0_out_bits_s1_entry_5_perm_r),
    .io_out_bits_s1_entry_5_level    (u_merge_arb_0_out_bits_s1_entry_5_level),
    .io_out_bits_s1_entry_5_v        (u_merge_arb_0_out_bits_s1_entry_5_v),
    .io_out_bits_s1_entry_5_ppn      (u_merge_arb_0_out_bits_s1_entry_5_ppn),
    .io_out_bits_s1_entry_5_ppn_low  (u_merge_arb_0_out_bits_s1_entry_5_ppn_low),
    .io_out_bits_s1_entry_5_af       (u_merge_arb_0_out_bits_s1_entry_5_af),
    .io_out_bits_s1_entry_5_pf       (u_merge_arb_0_out_bits_s1_entry_5_pf),
    .io_out_bits_s1_entry_5_cf       (u_merge_arb_0_out_bits_s1_entry_5_cf),
    .io_out_bits_s1_entry_6_tag      (u_merge_arb_0_out_bits_s1_entry_6_tag),
    .io_out_bits_s1_entry_6_asid     (u_merge_arb_0_out_bits_s1_entry_6_asid),
    .io_out_bits_s1_entry_6_vmid     (u_merge_arb_0_out_bits_s1_entry_6_vmid),
    .io_out_bits_s1_entry_6_n        (u_merge_arb_0_out_bits_s1_entry_6_n),
    .io_out_bits_s1_entry_6_pbmt     (u_merge_arb_0_out_bits_s1_entry_6_pbmt),
    .io_out_bits_s1_entry_6_perm_d   (u_merge_arb_0_out_bits_s1_entry_6_perm_d),
    .io_out_bits_s1_entry_6_perm_a   (u_merge_arb_0_out_bits_s1_entry_6_perm_a),
    .io_out_bits_s1_entry_6_perm_g   (u_merge_arb_0_out_bits_s1_entry_6_perm_g),
    .io_out_bits_s1_entry_6_perm_u   (u_merge_arb_0_out_bits_s1_entry_6_perm_u),
    .io_out_bits_s1_entry_6_perm_x   (u_merge_arb_0_out_bits_s1_entry_6_perm_x),
    .io_out_bits_s1_entry_6_perm_w   (u_merge_arb_0_out_bits_s1_entry_6_perm_w),
    .io_out_bits_s1_entry_6_perm_r   (u_merge_arb_0_out_bits_s1_entry_6_perm_r),
    .io_out_bits_s1_entry_6_level    (u_merge_arb_0_out_bits_s1_entry_6_level),
    .io_out_bits_s1_entry_6_v        (u_merge_arb_0_out_bits_s1_entry_6_v),
    .io_out_bits_s1_entry_6_ppn      (u_merge_arb_0_out_bits_s1_entry_6_ppn),
    .io_out_bits_s1_entry_6_ppn_low  (u_merge_arb_0_out_bits_s1_entry_6_ppn_low),
    .io_out_bits_s1_entry_6_af       (u_merge_arb_0_out_bits_s1_entry_6_af),
    .io_out_bits_s1_entry_6_pf       (u_merge_arb_0_out_bits_s1_entry_6_pf),
    .io_out_bits_s1_entry_6_cf       (u_merge_arb_0_out_bits_s1_entry_6_cf),
    .io_out_bits_s1_entry_7_tag      (u_merge_arb_0_out_bits_s1_entry_7_tag),
    .io_out_bits_s1_entry_7_asid     (u_merge_arb_0_out_bits_s1_entry_7_asid),
    .io_out_bits_s1_entry_7_vmid     (u_merge_arb_0_out_bits_s1_entry_7_vmid),
    .io_out_bits_s1_entry_7_n        (u_merge_arb_0_out_bits_s1_entry_7_n),
    .io_out_bits_s1_entry_7_pbmt     (u_merge_arb_0_out_bits_s1_entry_7_pbmt),
    .io_out_bits_s1_entry_7_perm_d   (u_merge_arb_0_out_bits_s1_entry_7_perm_d),
    .io_out_bits_s1_entry_7_perm_a   (u_merge_arb_0_out_bits_s1_entry_7_perm_a),
    .io_out_bits_s1_entry_7_perm_g   (u_merge_arb_0_out_bits_s1_entry_7_perm_g),
    .io_out_bits_s1_entry_7_perm_u   (u_merge_arb_0_out_bits_s1_entry_7_perm_u),
    .io_out_bits_s1_entry_7_perm_x   (u_merge_arb_0_out_bits_s1_entry_7_perm_x),
    .io_out_bits_s1_entry_7_perm_w   (u_merge_arb_0_out_bits_s1_entry_7_perm_w),
    .io_out_bits_s1_entry_7_perm_r   (u_merge_arb_0_out_bits_s1_entry_7_perm_r),
    .io_out_bits_s1_entry_7_level    (u_merge_arb_0_out_bits_s1_entry_7_level),
    .io_out_bits_s1_entry_7_v        (u_merge_arb_0_out_bits_s1_entry_7_v),
    .io_out_bits_s1_entry_7_ppn      (u_merge_arb_0_out_bits_s1_entry_7_ppn),
    .io_out_bits_s1_entry_7_ppn_low  (u_merge_arb_0_out_bits_s1_entry_7_ppn_low),
    .io_out_bits_s1_entry_7_af       (u_merge_arb_0_out_bits_s1_entry_7_af),
    .io_out_bits_s1_entry_7_pf       (u_merge_arb_0_out_bits_s1_entry_7_pf),
    .io_out_bits_s1_entry_7_cf       (u_merge_arb_0_out_bits_s1_entry_7_cf),
    .io_out_bits_s1_pteidx_0         (u_merge_arb_0_out_bits_s1_pteidx_0),
    .io_out_bits_s1_pteidx_1         (u_merge_arb_0_out_bits_s1_pteidx_1),
    .io_out_bits_s1_pteidx_2         (u_merge_arb_0_out_bits_s1_pteidx_2),
    .io_out_bits_s1_pteidx_3         (u_merge_arb_0_out_bits_s1_pteidx_3),
    .io_out_bits_s1_pteidx_4         (u_merge_arb_0_out_bits_s1_pteidx_4),
    .io_out_bits_s1_pteidx_5         (u_merge_arb_0_out_bits_s1_pteidx_5),
    .io_out_bits_s1_pteidx_6         (u_merge_arb_0_out_bits_s1_pteidx_6),
    .io_out_bits_s1_pteidx_7         (u_merge_arb_0_out_bits_s1_pteidx_7),
    .io_out_bits_s1_not_super        (u_merge_arb_0_out_bits_s1_not_super),
    .io_out_bits_s1_not_merge        (u_merge_arb_0_out_bits_s1_not_merge),
    .io_out_bits_s2_entry_tag        (u_merge_arb_0_out_bits_s2_entry_tag),
    .io_out_bits_s2_entry_vmid       (u_merge_arb_0_out_bits_s2_entry_vmid),
    .io_out_bits_s2_entry_n          (u_merge_arb_0_out_bits_s2_entry_n),
    .io_out_bits_s2_entry_pbmt       (u_merge_arb_0_out_bits_s2_entry_pbmt),
    .io_out_bits_s2_entry_ppn        (u_merge_arb_0_out_bits_s2_entry_ppn),
    .io_out_bits_s2_entry_perm_d     (u_merge_arb_0_out_bits_s2_entry_perm_d),
    .io_out_bits_s2_entry_perm_a     (u_merge_arb_0_out_bits_s2_entry_perm_a),
    .io_out_bits_s2_entry_perm_g     (u_merge_arb_0_out_bits_s2_entry_perm_g),
    .io_out_bits_s2_entry_perm_u     (u_merge_arb_0_out_bits_s2_entry_perm_u),
    .io_out_bits_s2_entry_perm_x     (u_merge_arb_0_out_bits_s2_entry_perm_x),
    .io_out_bits_s2_entry_perm_w     (u_merge_arb_0_out_bits_s2_entry_perm_w),
    .io_out_bits_s2_entry_perm_r     (u_merge_arb_0_out_bits_s2_entry_perm_r),
    .io_out_bits_s2_entry_level      (u_merge_arb_0_out_bits_s2_entry_level),
    .io_out_bits_s2_gpf              (u_merge_arb_0_out_bits_s2_gpf),
    .io_out_bits_s2_gaf              (u_merge_arb_0_out_bits_s2_gaf)
  );

  Arbiter3_L2TLBImp_Anon u_merge_arb_1 (
    .io_in_0_ready                   (u_merge_arb_1_in_0_ready),
    .io_in_0_valid                   (u_merge_arb_1__in_0_valid),
    .io_in_0_bits_s2xlate            (u_page_cache_resp_bits_req_info_s2xlate),
    .io_in_0_bits_s1_entry_0_tag     (u_page_cache_resp_bits_stage1_entry_0_tag),
    .io_in_0_bits_s1_entry_0_asid    (u_page_cache_resp_bits_stage1_entry_0_asid),
    .io_in_0_bits_s1_entry_0_vmid    (u_page_cache_resp_bits_stage1_entry_0_vmid),
    .io_in_0_bits_s1_entry_0_n       (u_page_cache_resp_bits_stage1_entry_0_n),
    .io_in_0_bits_s1_entry_0_pbmt    (u_page_cache_resp_bits_stage1_entry_0_pbmt),
    .io_in_0_bits_s1_entry_0_perm_d  (u_page_cache_resp_bits_stage1_entry_0_perm_d),
    .io_in_0_bits_s1_entry_0_perm_a  (u_page_cache_resp_bits_stage1_entry_0_perm_a),
    .io_in_0_bits_s1_entry_0_perm_g  (u_page_cache_resp_bits_stage1_entry_0_perm_g),
    .io_in_0_bits_s1_entry_0_perm_u  (u_page_cache_resp_bits_stage1_entry_0_perm_u),
    .io_in_0_bits_s1_entry_0_perm_x  (u_page_cache_resp_bits_stage1_entry_0_perm_x),
    .io_in_0_bits_s1_entry_0_perm_w  (u_page_cache_resp_bits_stage1_entry_0_perm_w),
    .io_in_0_bits_s1_entry_0_perm_r  (u_page_cache_resp_bits_stage1_entry_0_perm_r),
    .io_in_0_bits_s1_entry_0_level   (u_page_cache_resp_bits_stage1_entry_0_level),
    .io_in_0_bits_s1_entry_0_v       (u_page_cache_resp_bits_stage1_entry_0_v),
    .io_in_0_bits_s1_entry_0_ppn     (u_page_cache_resp_bits_stage1_entry_0_ppn),
    .io_in_0_bits_s1_entry_0_ppn_low (u_page_cache_resp_bits_stage1_entry_0_ppn_low),
    .io_in_0_bits_s1_entry_0_pf      (u_page_cache_resp_bits_stage1_entry_0_pf),
    .io_in_0_bits_s1_entry_0_cf      (u_page_cache_resp_bits_stage1_entry_0_cf),
    .io_in_0_bits_s1_entry_1_tag     (u_page_cache_resp_bits_stage1_entry_1_tag),
    .io_in_0_bits_s1_entry_1_asid    (u_page_cache_resp_bits_stage1_entry_1_asid),
    .io_in_0_bits_s1_entry_1_vmid    (u_page_cache_resp_bits_stage1_entry_1_vmid),
    .io_in_0_bits_s1_entry_1_n       (u_page_cache_resp_bits_stage1_entry_1_n),
    .io_in_0_bits_s1_entry_1_pbmt    (u_page_cache_resp_bits_stage1_entry_1_pbmt),
    .io_in_0_bits_s1_entry_1_perm_d  (u_page_cache_resp_bits_stage1_entry_1_perm_d),
    .io_in_0_bits_s1_entry_1_perm_a  (u_page_cache_resp_bits_stage1_entry_1_perm_a),
    .io_in_0_bits_s1_entry_1_perm_g  (u_page_cache_resp_bits_stage1_entry_1_perm_g),
    .io_in_0_bits_s1_entry_1_perm_u  (u_page_cache_resp_bits_stage1_entry_1_perm_u),
    .io_in_0_bits_s1_entry_1_perm_x  (u_page_cache_resp_bits_stage1_entry_1_perm_x),
    .io_in_0_bits_s1_entry_1_perm_w  (u_page_cache_resp_bits_stage1_entry_1_perm_w),
    .io_in_0_bits_s1_entry_1_perm_r  (u_page_cache_resp_bits_stage1_entry_1_perm_r),
    .io_in_0_bits_s1_entry_1_level   (u_page_cache_resp_bits_stage1_entry_1_level),
    .io_in_0_bits_s1_entry_1_v       (u_page_cache_resp_bits_stage1_entry_1_v),
    .io_in_0_bits_s1_entry_1_ppn     (u_page_cache_resp_bits_stage1_entry_1_ppn),
    .io_in_0_bits_s1_entry_1_ppn_low (u_page_cache_resp_bits_stage1_entry_1_ppn_low),
    .io_in_0_bits_s1_entry_1_pf      (u_page_cache_resp_bits_stage1_entry_1_pf),
    .io_in_0_bits_s1_entry_1_cf      (u_page_cache_resp_bits_stage1_entry_1_cf),
    .io_in_0_bits_s1_entry_2_tag     (u_page_cache_resp_bits_stage1_entry_2_tag),
    .io_in_0_bits_s1_entry_2_asid    (u_page_cache_resp_bits_stage1_entry_2_asid),
    .io_in_0_bits_s1_entry_2_vmid    (u_page_cache_resp_bits_stage1_entry_2_vmid),
    .io_in_0_bits_s1_entry_2_n       (u_page_cache_resp_bits_stage1_entry_2_n),
    .io_in_0_bits_s1_entry_2_pbmt    (u_page_cache_resp_bits_stage1_entry_2_pbmt),
    .io_in_0_bits_s1_entry_2_perm_d  (u_page_cache_resp_bits_stage1_entry_2_perm_d),
    .io_in_0_bits_s1_entry_2_perm_a  (u_page_cache_resp_bits_stage1_entry_2_perm_a),
    .io_in_0_bits_s1_entry_2_perm_g  (u_page_cache_resp_bits_stage1_entry_2_perm_g),
    .io_in_0_bits_s1_entry_2_perm_u  (u_page_cache_resp_bits_stage1_entry_2_perm_u),
    .io_in_0_bits_s1_entry_2_perm_x  (u_page_cache_resp_bits_stage1_entry_2_perm_x),
    .io_in_0_bits_s1_entry_2_perm_w  (u_page_cache_resp_bits_stage1_entry_2_perm_w),
    .io_in_0_bits_s1_entry_2_perm_r  (u_page_cache_resp_bits_stage1_entry_2_perm_r),
    .io_in_0_bits_s1_entry_2_level   (u_page_cache_resp_bits_stage1_entry_2_level),
    .io_in_0_bits_s1_entry_2_v       (u_page_cache_resp_bits_stage1_entry_2_v),
    .io_in_0_bits_s1_entry_2_ppn     (u_page_cache_resp_bits_stage1_entry_2_ppn),
    .io_in_0_bits_s1_entry_2_ppn_low (u_page_cache_resp_bits_stage1_entry_2_ppn_low),
    .io_in_0_bits_s1_entry_2_pf      (u_page_cache_resp_bits_stage1_entry_2_pf),
    .io_in_0_bits_s1_entry_2_cf      (u_page_cache_resp_bits_stage1_entry_2_cf),
    .io_in_0_bits_s1_entry_3_tag     (u_page_cache_resp_bits_stage1_entry_3_tag),
    .io_in_0_bits_s1_entry_3_asid    (u_page_cache_resp_bits_stage1_entry_3_asid),
    .io_in_0_bits_s1_entry_3_vmid    (u_page_cache_resp_bits_stage1_entry_3_vmid),
    .io_in_0_bits_s1_entry_3_n       (u_page_cache_resp_bits_stage1_entry_3_n),
    .io_in_0_bits_s1_entry_3_pbmt    (u_page_cache_resp_bits_stage1_entry_3_pbmt),
    .io_in_0_bits_s1_entry_3_perm_d  (u_page_cache_resp_bits_stage1_entry_3_perm_d),
    .io_in_0_bits_s1_entry_3_perm_a  (u_page_cache_resp_bits_stage1_entry_3_perm_a),
    .io_in_0_bits_s1_entry_3_perm_g  (u_page_cache_resp_bits_stage1_entry_3_perm_g),
    .io_in_0_bits_s1_entry_3_perm_u  (u_page_cache_resp_bits_stage1_entry_3_perm_u),
    .io_in_0_bits_s1_entry_3_perm_x  (u_page_cache_resp_bits_stage1_entry_3_perm_x),
    .io_in_0_bits_s1_entry_3_perm_w  (u_page_cache_resp_bits_stage1_entry_3_perm_w),
    .io_in_0_bits_s1_entry_3_perm_r  (u_page_cache_resp_bits_stage1_entry_3_perm_r),
    .io_in_0_bits_s1_entry_3_level   (u_page_cache_resp_bits_stage1_entry_3_level),
    .io_in_0_bits_s1_entry_3_v       (u_page_cache_resp_bits_stage1_entry_3_v),
    .io_in_0_bits_s1_entry_3_ppn     (u_page_cache_resp_bits_stage1_entry_3_ppn),
    .io_in_0_bits_s1_entry_3_ppn_low (u_page_cache_resp_bits_stage1_entry_3_ppn_low),
    .io_in_0_bits_s1_entry_3_pf      (u_page_cache_resp_bits_stage1_entry_3_pf),
    .io_in_0_bits_s1_entry_3_cf      (u_page_cache_resp_bits_stage1_entry_3_cf),
    .io_in_0_bits_s1_entry_4_tag     (u_page_cache_resp_bits_stage1_entry_4_tag),
    .io_in_0_bits_s1_entry_4_asid    (u_page_cache_resp_bits_stage1_entry_4_asid),
    .io_in_0_bits_s1_entry_4_vmid    (u_page_cache_resp_bits_stage1_entry_4_vmid),
    .io_in_0_bits_s1_entry_4_n       (u_page_cache_resp_bits_stage1_entry_4_n),
    .io_in_0_bits_s1_entry_4_pbmt    (u_page_cache_resp_bits_stage1_entry_4_pbmt),
    .io_in_0_bits_s1_entry_4_perm_d  (u_page_cache_resp_bits_stage1_entry_4_perm_d),
    .io_in_0_bits_s1_entry_4_perm_a  (u_page_cache_resp_bits_stage1_entry_4_perm_a),
    .io_in_0_bits_s1_entry_4_perm_g  (u_page_cache_resp_bits_stage1_entry_4_perm_g),
    .io_in_0_bits_s1_entry_4_perm_u  (u_page_cache_resp_bits_stage1_entry_4_perm_u),
    .io_in_0_bits_s1_entry_4_perm_x  (u_page_cache_resp_bits_stage1_entry_4_perm_x),
    .io_in_0_bits_s1_entry_4_perm_w  (u_page_cache_resp_bits_stage1_entry_4_perm_w),
    .io_in_0_bits_s1_entry_4_perm_r  (u_page_cache_resp_bits_stage1_entry_4_perm_r),
    .io_in_0_bits_s1_entry_4_level   (u_page_cache_resp_bits_stage1_entry_4_level),
    .io_in_0_bits_s1_entry_4_v       (u_page_cache_resp_bits_stage1_entry_4_v),
    .io_in_0_bits_s1_entry_4_ppn     (u_page_cache_resp_bits_stage1_entry_4_ppn),
    .io_in_0_bits_s1_entry_4_ppn_low (u_page_cache_resp_bits_stage1_entry_4_ppn_low),
    .io_in_0_bits_s1_entry_4_pf      (u_page_cache_resp_bits_stage1_entry_4_pf),
    .io_in_0_bits_s1_entry_4_cf      (u_page_cache_resp_bits_stage1_entry_4_cf),
    .io_in_0_bits_s1_entry_5_tag     (u_page_cache_resp_bits_stage1_entry_5_tag),
    .io_in_0_bits_s1_entry_5_asid    (u_page_cache_resp_bits_stage1_entry_5_asid),
    .io_in_0_bits_s1_entry_5_vmid    (u_page_cache_resp_bits_stage1_entry_5_vmid),
    .io_in_0_bits_s1_entry_5_n       (u_page_cache_resp_bits_stage1_entry_5_n),
    .io_in_0_bits_s1_entry_5_pbmt    (u_page_cache_resp_bits_stage1_entry_5_pbmt),
    .io_in_0_bits_s1_entry_5_perm_d  (u_page_cache_resp_bits_stage1_entry_5_perm_d),
    .io_in_0_bits_s1_entry_5_perm_a  (u_page_cache_resp_bits_stage1_entry_5_perm_a),
    .io_in_0_bits_s1_entry_5_perm_g  (u_page_cache_resp_bits_stage1_entry_5_perm_g),
    .io_in_0_bits_s1_entry_5_perm_u  (u_page_cache_resp_bits_stage1_entry_5_perm_u),
    .io_in_0_bits_s1_entry_5_perm_x  (u_page_cache_resp_bits_stage1_entry_5_perm_x),
    .io_in_0_bits_s1_entry_5_perm_w  (u_page_cache_resp_bits_stage1_entry_5_perm_w),
    .io_in_0_bits_s1_entry_5_perm_r  (u_page_cache_resp_bits_stage1_entry_5_perm_r),
    .io_in_0_bits_s1_entry_5_level   (u_page_cache_resp_bits_stage1_entry_5_level),
    .io_in_0_bits_s1_entry_5_v       (u_page_cache_resp_bits_stage1_entry_5_v),
    .io_in_0_bits_s1_entry_5_ppn     (u_page_cache_resp_bits_stage1_entry_5_ppn),
    .io_in_0_bits_s1_entry_5_ppn_low (u_page_cache_resp_bits_stage1_entry_5_ppn_low),
    .io_in_0_bits_s1_entry_5_pf      (u_page_cache_resp_bits_stage1_entry_5_pf),
    .io_in_0_bits_s1_entry_5_cf      (u_page_cache_resp_bits_stage1_entry_5_cf),
    .io_in_0_bits_s1_entry_6_tag     (u_page_cache_resp_bits_stage1_entry_6_tag),
    .io_in_0_bits_s1_entry_6_asid    (u_page_cache_resp_bits_stage1_entry_6_asid),
    .io_in_0_bits_s1_entry_6_vmid    (u_page_cache_resp_bits_stage1_entry_6_vmid),
    .io_in_0_bits_s1_entry_6_n       (u_page_cache_resp_bits_stage1_entry_6_n),
    .io_in_0_bits_s1_entry_6_pbmt    (u_page_cache_resp_bits_stage1_entry_6_pbmt),
    .io_in_0_bits_s1_entry_6_perm_d  (u_page_cache_resp_bits_stage1_entry_6_perm_d),
    .io_in_0_bits_s1_entry_6_perm_a  (u_page_cache_resp_bits_stage1_entry_6_perm_a),
    .io_in_0_bits_s1_entry_6_perm_g  (u_page_cache_resp_bits_stage1_entry_6_perm_g),
    .io_in_0_bits_s1_entry_6_perm_u  (u_page_cache_resp_bits_stage1_entry_6_perm_u),
    .io_in_0_bits_s1_entry_6_perm_x  (u_page_cache_resp_bits_stage1_entry_6_perm_x),
    .io_in_0_bits_s1_entry_6_perm_w  (u_page_cache_resp_bits_stage1_entry_6_perm_w),
    .io_in_0_bits_s1_entry_6_perm_r  (u_page_cache_resp_bits_stage1_entry_6_perm_r),
    .io_in_0_bits_s1_entry_6_level   (u_page_cache_resp_bits_stage1_entry_6_level),
    .io_in_0_bits_s1_entry_6_v       (u_page_cache_resp_bits_stage1_entry_6_v),
    .io_in_0_bits_s1_entry_6_ppn     (u_page_cache_resp_bits_stage1_entry_6_ppn),
    .io_in_0_bits_s1_entry_6_ppn_low (u_page_cache_resp_bits_stage1_entry_6_ppn_low),
    .io_in_0_bits_s1_entry_6_pf      (u_page_cache_resp_bits_stage1_entry_6_pf),
    .io_in_0_bits_s1_entry_6_cf      (u_page_cache_resp_bits_stage1_entry_6_cf),
    .io_in_0_bits_s1_entry_7_tag     (u_page_cache_resp_bits_stage1_entry_7_tag),
    .io_in_0_bits_s1_entry_7_asid    (u_page_cache_resp_bits_stage1_entry_7_asid),
    .io_in_0_bits_s1_entry_7_vmid    (u_page_cache_resp_bits_stage1_entry_7_vmid),
    .io_in_0_bits_s1_entry_7_n       (u_page_cache_resp_bits_stage1_entry_7_n),
    .io_in_0_bits_s1_entry_7_pbmt    (u_page_cache_resp_bits_stage1_entry_7_pbmt),
    .io_in_0_bits_s1_entry_7_perm_d  (u_page_cache_resp_bits_stage1_entry_7_perm_d),
    .io_in_0_bits_s1_entry_7_perm_a  (u_page_cache_resp_bits_stage1_entry_7_perm_a),
    .io_in_0_bits_s1_entry_7_perm_g  (u_page_cache_resp_bits_stage1_entry_7_perm_g),
    .io_in_0_bits_s1_entry_7_perm_u  (u_page_cache_resp_bits_stage1_entry_7_perm_u),
    .io_in_0_bits_s1_entry_7_perm_x  (u_page_cache_resp_bits_stage1_entry_7_perm_x),
    .io_in_0_bits_s1_entry_7_perm_w  (u_page_cache_resp_bits_stage1_entry_7_perm_w),
    .io_in_0_bits_s1_entry_7_perm_r  (u_page_cache_resp_bits_stage1_entry_7_perm_r),
    .io_in_0_bits_s1_entry_7_level   (u_page_cache_resp_bits_stage1_entry_7_level),
    .io_in_0_bits_s1_entry_7_v       (u_page_cache_resp_bits_stage1_entry_7_v),
    .io_in_0_bits_s1_entry_7_ppn     (u_page_cache_resp_bits_stage1_entry_7_ppn),
    .io_in_0_bits_s1_entry_7_ppn_low (u_page_cache_resp_bits_stage1_entry_7_ppn_low),
    .io_in_0_bits_s1_entry_7_pf      (u_page_cache_resp_bits_stage1_entry_7_pf),
    .io_in_0_bits_s1_entry_7_cf      (u_page_cache_resp_bits_stage1_entry_7_cf),
    .io_in_0_bits_s1_pteidx_0        (u_page_cache_resp_bits_stage1_pteidx_0),
    .io_in_0_bits_s1_pteidx_1        (u_page_cache_resp_bits_stage1_pteidx_1),
    .io_in_0_bits_s1_pteidx_2        (u_page_cache_resp_bits_stage1_pteidx_2),
    .io_in_0_bits_s1_pteidx_3        (u_page_cache_resp_bits_stage1_pteidx_3),
    .io_in_0_bits_s1_pteidx_4        (u_page_cache_resp_bits_stage1_pteidx_4),
    .io_in_0_bits_s1_pteidx_5        (u_page_cache_resp_bits_stage1_pteidx_5),
    .io_in_0_bits_s1_pteidx_6        (u_page_cache_resp_bits_stage1_pteidx_6),
    .io_in_0_bits_s1_pteidx_7        (u_page_cache_resp_bits_stage1_pteidx_7),
    .io_in_0_bits_s1_not_super       (u_page_cache_resp_bits_stage1_not_super),
    .io_in_0_bits_s2_entry_tag       (u_page_cache_resp_bits_toHptw_resp_entry_tag),
    .io_in_0_bits_s2_entry_vmid      (u_page_cache_resp_bits_toHptw_resp_entry_vmid),
    .io_in_0_bits_s2_entry_n         (u_page_cache_resp_bits_toHptw_resp_entry_n),
    .io_in_0_bits_s2_entry_pbmt      (u_page_cache_resp_bits_toHptw_resp_entry_pbmt),
    .io_in_0_bits_s2_entry_ppn       (u_page_cache_resp_bits_toHptw_resp_entry_ppn),
    .io_in_0_bits_s2_entry_perm_d    (u_page_cache_resp_bits_toHptw_resp_entry_perm_d),
    .io_in_0_bits_s2_entry_perm_a    (u_page_cache_resp_bits_toHptw_resp_entry_perm_a),
    .io_in_0_bits_s2_entry_perm_g    (u_page_cache_resp_bits_toHptw_resp_entry_perm_g),
    .io_in_0_bits_s2_entry_perm_u    (u_page_cache_resp_bits_toHptw_resp_entry_perm_u),
    .io_in_0_bits_s2_entry_perm_x    (u_page_cache_resp_bits_toHptw_resp_entry_perm_x),
    .io_in_0_bits_s2_entry_perm_w    (u_page_cache_resp_bits_toHptw_resp_entry_perm_w),
    .io_in_0_bits_s2_entry_perm_r    (u_page_cache_resp_bits_toHptw_resp_entry_perm_r),
    .io_in_0_bits_s2_entry_level     (u_page_cache_resp_bits_toHptw_resp_entry_level),
    .io_in_0_bits_s2_gpf             (u_page_cache_resp_bits_toHptw_resp_gpf),
    .io_in_1_ready                   (u_merge_arb_1_in_1_ready),
    .io_in_1_valid                   (u_merge_arb_1__in_1_valid),
    .io_in_1_bits_s2xlate            (u_ptw_resp_bits_s2xlate),
    .io_in_1_bits_s1_entry_0_tag     (u_ptw_resp_bits_resp_entry_0_tag),
    .io_in_1_bits_s1_entry_0_asid    (u_ptw_resp_bits_resp_entry_0_asid),
    .io_in_1_bits_s1_entry_0_vmid    (u_ptw_resp_bits_resp_entry_0_vmid),
    .io_in_1_bits_s1_entry_0_n       (u_ptw_resp_bits_resp_entry_0_n),
    .io_in_1_bits_s1_entry_0_pbmt    (u_ptw_resp_bits_resp_entry_0_pbmt),
    .io_in_1_bits_s1_entry_0_perm_d  (u_ptw_resp_bits_resp_entry_0_perm_d),
    .io_in_1_bits_s1_entry_0_perm_a  (u_ptw_resp_bits_resp_entry_0_perm_a),
    .io_in_1_bits_s1_entry_0_perm_g  (u_ptw_resp_bits_resp_entry_0_perm_g),
    .io_in_1_bits_s1_entry_0_perm_u  (u_ptw_resp_bits_resp_entry_0_perm_u),
    .io_in_1_bits_s1_entry_0_perm_x  (u_ptw_resp_bits_resp_entry_0_perm_x),
    .io_in_1_bits_s1_entry_0_perm_w  (u_ptw_resp_bits_resp_entry_0_perm_w),
    .io_in_1_bits_s1_entry_0_perm_r  (u_ptw_resp_bits_resp_entry_0_perm_r),
    .io_in_1_bits_s1_entry_0_level   (u_ptw_resp_bits_resp_entry_0_level),
    .io_in_1_bits_s1_entry_0_v       (u_ptw_resp_bits_resp_entry_0_v),
    .io_in_1_bits_s1_entry_0_ppn     (u_ptw_resp_bits_resp_entry_0_ppn),
    .io_in_1_bits_s1_entry_0_ppn_low (u_ptw_resp_bits_resp_entry_0_ppn_low),
    .io_in_1_bits_s1_entry_0_af      (u_ptw_resp_bits_resp_entry_0_af),
    .io_in_1_bits_s1_entry_0_pf      (u_ptw_resp_bits_resp_entry_0_pf),
    .io_in_1_bits_s1_entry_0_cf      (u_ptw_resp_bits_resp_entry_0_cf),
    .io_in_1_bits_s1_entry_1_tag     (u_ptw_resp_bits_resp_entry_1_tag),
    .io_in_1_bits_s1_entry_1_asid    (u_ptw_resp_bits_resp_entry_1_asid),
    .io_in_1_bits_s1_entry_1_vmid    (u_ptw_resp_bits_resp_entry_1_vmid),
    .io_in_1_bits_s1_entry_1_n       (u_ptw_resp_bits_resp_entry_1_n),
    .io_in_1_bits_s1_entry_1_pbmt    (u_ptw_resp_bits_resp_entry_1_pbmt),
    .io_in_1_bits_s1_entry_1_perm_d  (u_ptw_resp_bits_resp_entry_1_perm_d),
    .io_in_1_bits_s1_entry_1_perm_a  (u_ptw_resp_bits_resp_entry_1_perm_a),
    .io_in_1_bits_s1_entry_1_perm_g  (u_ptw_resp_bits_resp_entry_1_perm_g),
    .io_in_1_bits_s1_entry_1_perm_u  (u_ptw_resp_bits_resp_entry_1_perm_u),
    .io_in_1_bits_s1_entry_1_perm_x  (u_ptw_resp_bits_resp_entry_1_perm_x),
    .io_in_1_bits_s1_entry_1_perm_w  (u_ptw_resp_bits_resp_entry_1_perm_w),
    .io_in_1_bits_s1_entry_1_perm_r  (u_ptw_resp_bits_resp_entry_1_perm_r),
    .io_in_1_bits_s1_entry_1_level   (u_ptw_resp_bits_resp_entry_1_level),
    .io_in_1_bits_s1_entry_1_v       (u_ptw_resp_bits_resp_entry_1_v),
    .io_in_1_bits_s1_entry_1_ppn     (u_ptw_resp_bits_resp_entry_1_ppn),
    .io_in_1_bits_s1_entry_1_ppn_low (u_ptw_resp_bits_resp_entry_1_ppn_low),
    .io_in_1_bits_s1_entry_1_af      (u_ptw_resp_bits_resp_entry_1_af),
    .io_in_1_bits_s1_entry_1_pf      (u_ptw_resp_bits_resp_entry_1_pf),
    .io_in_1_bits_s1_entry_1_cf      (u_ptw_resp_bits_resp_entry_1_cf),
    .io_in_1_bits_s1_entry_2_tag     (u_ptw_resp_bits_resp_entry_2_tag),
    .io_in_1_bits_s1_entry_2_asid    (u_ptw_resp_bits_resp_entry_2_asid),
    .io_in_1_bits_s1_entry_2_vmid    (u_ptw_resp_bits_resp_entry_2_vmid),
    .io_in_1_bits_s1_entry_2_n       (u_ptw_resp_bits_resp_entry_2_n),
    .io_in_1_bits_s1_entry_2_pbmt    (u_ptw_resp_bits_resp_entry_2_pbmt),
    .io_in_1_bits_s1_entry_2_perm_d  (u_ptw_resp_bits_resp_entry_2_perm_d),
    .io_in_1_bits_s1_entry_2_perm_a  (u_ptw_resp_bits_resp_entry_2_perm_a),
    .io_in_1_bits_s1_entry_2_perm_g  (u_ptw_resp_bits_resp_entry_2_perm_g),
    .io_in_1_bits_s1_entry_2_perm_u  (u_ptw_resp_bits_resp_entry_2_perm_u),
    .io_in_1_bits_s1_entry_2_perm_x  (u_ptw_resp_bits_resp_entry_2_perm_x),
    .io_in_1_bits_s1_entry_2_perm_w  (u_ptw_resp_bits_resp_entry_2_perm_w),
    .io_in_1_bits_s1_entry_2_perm_r  (u_ptw_resp_bits_resp_entry_2_perm_r),
    .io_in_1_bits_s1_entry_2_level   (u_ptw_resp_bits_resp_entry_2_level),
    .io_in_1_bits_s1_entry_2_v       (u_ptw_resp_bits_resp_entry_2_v),
    .io_in_1_bits_s1_entry_2_ppn     (u_ptw_resp_bits_resp_entry_2_ppn),
    .io_in_1_bits_s1_entry_2_ppn_low (u_ptw_resp_bits_resp_entry_2_ppn_low),
    .io_in_1_bits_s1_entry_2_af      (u_ptw_resp_bits_resp_entry_2_af),
    .io_in_1_bits_s1_entry_2_pf      (u_ptw_resp_bits_resp_entry_2_pf),
    .io_in_1_bits_s1_entry_2_cf      (u_ptw_resp_bits_resp_entry_2_cf),
    .io_in_1_bits_s1_entry_3_tag     (u_ptw_resp_bits_resp_entry_3_tag),
    .io_in_1_bits_s1_entry_3_asid    (u_ptw_resp_bits_resp_entry_3_asid),
    .io_in_1_bits_s1_entry_3_vmid    (u_ptw_resp_bits_resp_entry_3_vmid),
    .io_in_1_bits_s1_entry_3_n       (u_ptw_resp_bits_resp_entry_3_n),
    .io_in_1_bits_s1_entry_3_pbmt    (u_ptw_resp_bits_resp_entry_3_pbmt),
    .io_in_1_bits_s1_entry_3_perm_d  (u_ptw_resp_bits_resp_entry_3_perm_d),
    .io_in_1_bits_s1_entry_3_perm_a  (u_ptw_resp_bits_resp_entry_3_perm_a),
    .io_in_1_bits_s1_entry_3_perm_g  (u_ptw_resp_bits_resp_entry_3_perm_g),
    .io_in_1_bits_s1_entry_3_perm_u  (u_ptw_resp_bits_resp_entry_3_perm_u),
    .io_in_1_bits_s1_entry_3_perm_x  (u_ptw_resp_bits_resp_entry_3_perm_x),
    .io_in_1_bits_s1_entry_3_perm_w  (u_ptw_resp_bits_resp_entry_3_perm_w),
    .io_in_1_bits_s1_entry_3_perm_r  (u_ptw_resp_bits_resp_entry_3_perm_r),
    .io_in_1_bits_s1_entry_3_level   (u_ptw_resp_bits_resp_entry_3_level),
    .io_in_1_bits_s1_entry_3_v       (u_ptw_resp_bits_resp_entry_3_v),
    .io_in_1_bits_s1_entry_3_ppn     (u_ptw_resp_bits_resp_entry_3_ppn),
    .io_in_1_bits_s1_entry_3_ppn_low (u_ptw_resp_bits_resp_entry_3_ppn_low),
    .io_in_1_bits_s1_entry_3_af      (u_ptw_resp_bits_resp_entry_3_af),
    .io_in_1_bits_s1_entry_3_pf      (u_ptw_resp_bits_resp_entry_3_pf),
    .io_in_1_bits_s1_entry_3_cf      (u_ptw_resp_bits_resp_entry_3_cf),
    .io_in_1_bits_s1_entry_4_tag     (u_ptw_resp_bits_resp_entry_4_tag),
    .io_in_1_bits_s1_entry_4_asid    (u_ptw_resp_bits_resp_entry_4_asid),
    .io_in_1_bits_s1_entry_4_vmid    (u_ptw_resp_bits_resp_entry_4_vmid),
    .io_in_1_bits_s1_entry_4_n       (u_ptw_resp_bits_resp_entry_4_n),
    .io_in_1_bits_s1_entry_4_pbmt    (u_ptw_resp_bits_resp_entry_4_pbmt),
    .io_in_1_bits_s1_entry_4_perm_d  (u_ptw_resp_bits_resp_entry_4_perm_d),
    .io_in_1_bits_s1_entry_4_perm_a  (u_ptw_resp_bits_resp_entry_4_perm_a),
    .io_in_1_bits_s1_entry_4_perm_g  (u_ptw_resp_bits_resp_entry_4_perm_g),
    .io_in_1_bits_s1_entry_4_perm_u  (u_ptw_resp_bits_resp_entry_4_perm_u),
    .io_in_1_bits_s1_entry_4_perm_x  (u_ptw_resp_bits_resp_entry_4_perm_x),
    .io_in_1_bits_s1_entry_4_perm_w  (u_ptw_resp_bits_resp_entry_4_perm_w),
    .io_in_1_bits_s1_entry_4_perm_r  (u_ptw_resp_bits_resp_entry_4_perm_r),
    .io_in_1_bits_s1_entry_4_level   (u_ptw_resp_bits_resp_entry_4_level),
    .io_in_1_bits_s1_entry_4_v       (u_ptw_resp_bits_resp_entry_4_v),
    .io_in_1_bits_s1_entry_4_ppn     (u_ptw_resp_bits_resp_entry_4_ppn),
    .io_in_1_bits_s1_entry_4_ppn_low (u_ptw_resp_bits_resp_entry_4_ppn_low),
    .io_in_1_bits_s1_entry_4_af      (u_ptw_resp_bits_resp_entry_4_af),
    .io_in_1_bits_s1_entry_4_pf      (u_ptw_resp_bits_resp_entry_4_pf),
    .io_in_1_bits_s1_entry_4_cf      (u_ptw_resp_bits_resp_entry_4_cf),
    .io_in_1_bits_s1_entry_5_tag     (u_ptw_resp_bits_resp_entry_5_tag),
    .io_in_1_bits_s1_entry_5_asid    (u_ptw_resp_bits_resp_entry_5_asid),
    .io_in_1_bits_s1_entry_5_vmid    (u_ptw_resp_bits_resp_entry_5_vmid),
    .io_in_1_bits_s1_entry_5_n       (u_ptw_resp_bits_resp_entry_5_n),
    .io_in_1_bits_s1_entry_5_pbmt    (u_ptw_resp_bits_resp_entry_5_pbmt),
    .io_in_1_bits_s1_entry_5_perm_d  (u_ptw_resp_bits_resp_entry_5_perm_d),
    .io_in_1_bits_s1_entry_5_perm_a  (u_ptw_resp_bits_resp_entry_5_perm_a),
    .io_in_1_bits_s1_entry_5_perm_g  (u_ptw_resp_bits_resp_entry_5_perm_g),
    .io_in_1_bits_s1_entry_5_perm_u  (u_ptw_resp_bits_resp_entry_5_perm_u),
    .io_in_1_bits_s1_entry_5_perm_x  (u_ptw_resp_bits_resp_entry_5_perm_x),
    .io_in_1_bits_s1_entry_5_perm_w  (u_ptw_resp_bits_resp_entry_5_perm_w),
    .io_in_1_bits_s1_entry_5_perm_r  (u_ptw_resp_bits_resp_entry_5_perm_r),
    .io_in_1_bits_s1_entry_5_level   (u_ptw_resp_bits_resp_entry_5_level),
    .io_in_1_bits_s1_entry_5_v       (u_ptw_resp_bits_resp_entry_5_v),
    .io_in_1_bits_s1_entry_5_ppn     (u_ptw_resp_bits_resp_entry_5_ppn),
    .io_in_1_bits_s1_entry_5_ppn_low (u_ptw_resp_bits_resp_entry_5_ppn_low),
    .io_in_1_bits_s1_entry_5_af      (u_ptw_resp_bits_resp_entry_5_af),
    .io_in_1_bits_s1_entry_5_pf      (u_ptw_resp_bits_resp_entry_5_pf),
    .io_in_1_bits_s1_entry_5_cf      (u_ptw_resp_bits_resp_entry_5_cf),
    .io_in_1_bits_s1_entry_6_tag     (u_ptw_resp_bits_resp_entry_6_tag),
    .io_in_1_bits_s1_entry_6_asid    (u_ptw_resp_bits_resp_entry_6_asid),
    .io_in_1_bits_s1_entry_6_vmid    (u_ptw_resp_bits_resp_entry_6_vmid),
    .io_in_1_bits_s1_entry_6_n       (u_ptw_resp_bits_resp_entry_6_n),
    .io_in_1_bits_s1_entry_6_pbmt    (u_ptw_resp_bits_resp_entry_6_pbmt),
    .io_in_1_bits_s1_entry_6_perm_d  (u_ptw_resp_bits_resp_entry_6_perm_d),
    .io_in_1_bits_s1_entry_6_perm_a  (u_ptw_resp_bits_resp_entry_6_perm_a),
    .io_in_1_bits_s1_entry_6_perm_g  (u_ptw_resp_bits_resp_entry_6_perm_g),
    .io_in_1_bits_s1_entry_6_perm_u  (u_ptw_resp_bits_resp_entry_6_perm_u),
    .io_in_1_bits_s1_entry_6_perm_x  (u_ptw_resp_bits_resp_entry_6_perm_x),
    .io_in_1_bits_s1_entry_6_perm_w  (u_ptw_resp_bits_resp_entry_6_perm_w),
    .io_in_1_bits_s1_entry_6_perm_r  (u_ptw_resp_bits_resp_entry_6_perm_r),
    .io_in_1_bits_s1_entry_6_level   (u_ptw_resp_bits_resp_entry_6_level),
    .io_in_1_bits_s1_entry_6_v       (u_ptw_resp_bits_resp_entry_6_v),
    .io_in_1_bits_s1_entry_6_ppn     (u_ptw_resp_bits_resp_entry_6_ppn),
    .io_in_1_bits_s1_entry_6_ppn_low (u_ptw_resp_bits_resp_entry_6_ppn_low),
    .io_in_1_bits_s1_entry_6_af      (u_ptw_resp_bits_resp_entry_6_af),
    .io_in_1_bits_s1_entry_6_pf      (u_ptw_resp_bits_resp_entry_6_pf),
    .io_in_1_bits_s1_entry_6_cf      (u_ptw_resp_bits_resp_entry_6_cf),
    .io_in_1_bits_s1_entry_7_tag     (u_ptw_resp_bits_resp_entry_7_tag),
    .io_in_1_bits_s1_entry_7_asid    (u_ptw_resp_bits_resp_entry_7_asid),
    .io_in_1_bits_s1_entry_7_vmid    (u_ptw_resp_bits_resp_entry_7_vmid),
    .io_in_1_bits_s1_entry_7_n       (u_ptw_resp_bits_resp_entry_7_n),
    .io_in_1_bits_s1_entry_7_pbmt    (u_ptw_resp_bits_resp_entry_7_pbmt),
    .io_in_1_bits_s1_entry_7_perm_d  (u_ptw_resp_bits_resp_entry_7_perm_d),
    .io_in_1_bits_s1_entry_7_perm_a  (u_ptw_resp_bits_resp_entry_7_perm_a),
    .io_in_1_bits_s1_entry_7_perm_g  (u_ptw_resp_bits_resp_entry_7_perm_g),
    .io_in_1_bits_s1_entry_7_perm_u  (u_ptw_resp_bits_resp_entry_7_perm_u),
    .io_in_1_bits_s1_entry_7_perm_x  (u_ptw_resp_bits_resp_entry_7_perm_x),
    .io_in_1_bits_s1_entry_7_perm_w  (u_ptw_resp_bits_resp_entry_7_perm_w),
    .io_in_1_bits_s1_entry_7_perm_r  (u_ptw_resp_bits_resp_entry_7_perm_r),
    .io_in_1_bits_s1_entry_7_level   (u_ptw_resp_bits_resp_entry_7_level),
    .io_in_1_bits_s1_entry_7_v       (u_ptw_resp_bits_resp_entry_7_v),
    .io_in_1_bits_s1_entry_7_ppn     (u_ptw_resp_bits_resp_entry_7_ppn),
    .io_in_1_bits_s1_entry_7_ppn_low (u_ptw_resp_bits_resp_entry_7_ppn_low),
    .io_in_1_bits_s1_entry_7_af      (u_ptw_resp_bits_resp_entry_7_af),
    .io_in_1_bits_s1_entry_7_pf      (u_ptw_resp_bits_resp_entry_7_pf),
    .io_in_1_bits_s1_entry_7_cf      (u_ptw_resp_bits_resp_entry_7_cf),
    .io_in_1_bits_s1_pteidx_0        (u_ptw_resp_bits_resp_pteidx_0),
    .io_in_1_bits_s1_pteidx_1        (u_ptw_resp_bits_resp_pteidx_1),
    .io_in_1_bits_s1_pteidx_2        (u_ptw_resp_bits_resp_pteidx_2),
    .io_in_1_bits_s1_pteidx_3        (u_ptw_resp_bits_resp_pteidx_3),
    .io_in_1_bits_s1_pteidx_4        (u_ptw_resp_bits_resp_pteidx_4),
    .io_in_1_bits_s1_pteidx_5        (u_ptw_resp_bits_resp_pteidx_5),
    .io_in_1_bits_s1_pteidx_6        (u_ptw_resp_bits_resp_pteidx_6),
    .io_in_1_bits_s1_pteidx_7        (u_ptw_resp_bits_resp_pteidx_7),
    .io_in_1_bits_s1_not_super       (u_ptw_resp_bits_resp_not_super),
    .io_in_1_bits_s2_entry_tag       (u_ptw_resp_bits_h_resp_entry_tag),
    .io_in_1_bits_s2_entry_vmid      (u_ptw_resp_bits_h_resp_entry_vmid),
    .io_in_1_bits_s2_entry_n         (u_ptw_resp_bits_h_resp_entry_n),
    .io_in_1_bits_s2_entry_pbmt      (u_ptw_resp_bits_h_resp_entry_pbmt),
    .io_in_1_bits_s2_entry_ppn       (u_ptw_resp_bits_h_resp_entry_ppn),
    .io_in_1_bits_s2_entry_perm_d    (u_ptw_resp_bits_h_resp_entry_perm_d),
    .io_in_1_bits_s2_entry_perm_a    (u_ptw_resp_bits_h_resp_entry_perm_a),
    .io_in_1_bits_s2_entry_perm_g    (u_ptw_resp_bits_h_resp_entry_perm_g),
    .io_in_1_bits_s2_entry_perm_u    (u_ptw_resp_bits_h_resp_entry_perm_u),
    .io_in_1_bits_s2_entry_perm_x    (u_ptw_resp_bits_h_resp_entry_perm_x),
    .io_in_1_bits_s2_entry_perm_w    (u_ptw_resp_bits_h_resp_entry_perm_w),
    .io_in_1_bits_s2_entry_perm_r    (u_ptw_resp_bits_h_resp_entry_perm_r),
    .io_in_1_bits_s2_entry_level     (u_ptw_resp_bits_h_resp_entry_level),
    .io_in_1_bits_s2_gpf             (u_ptw_resp_bits_h_resp_gpf),
    .io_in_1_bits_s2_gaf             (u_ptw_resp_bits_h_resp_gaf),
    .io_in_2_ready                   (u_merge_arb_1_in_2_ready),
    .io_in_2_valid                   (u_merge_arb_1__in_2_valid),
    .io_in_2_bits_s2xlate            (u_llptw_out_bits_req_info_s2xlate),
    .io_in_2_bits_s1_entry_0_tag     (u_merge_arb_1__in_2_bits_s1_entry_0_tag),
    .io_in_2_bits_s1_entry_0_asid    (u_merge_arb_1__in_2_bits_s1_entry_0_asid),
    .io_in_2_bits_s1_entry_0_vmid    (u_merge_arb_1__in_2_bits_s1_entry_0_vmid),
    .io_in_2_bits_s1_entry_0_n       (u_merge_arb_1__in_2_bits_s1_entry_0_n),
    .io_in_2_bits_s1_entry_0_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_0_pbmt),
    .io_in_2_bits_s1_entry_0_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_d),
    .io_in_2_bits_s1_entry_0_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_a),
    .io_in_2_bits_s1_entry_0_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_g),
    .io_in_2_bits_s1_entry_0_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_u),
    .io_in_2_bits_s1_entry_0_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_x),
    .io_in_2_bits_s1_entry_0_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_w),
    .io_in_2_bits_s1_entry_0_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_0_perm_r),
    .io_in_2_bits_s1_entry_0_level   (u_merge_arb_1__in_2_bits_s1_entry_0_level),
    .io_in_2_bits_s1_entry_0_v       (u_merge_arb_1__in_2_bits_s1_entry_0_v),
    .io_in_2_bits_s1_entry_0_ppn     (u_merge_arb_1__in_2_bits_s1_entry_0_ppn),
    .io_in_2_bits_s1_entry_0_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_0_ppn_low),
    .io_in_2_bits_s1_entry_0_af      (u_merge_arb_1__in_2_bits_s1_entry_0_af),
    .io_in_2_bits_s1_entry_0_pf      (u_merge_arb_1__in_2_bits_s1_entry_0_pf),
    .io_in_2_bits_s1_entry_0_cf      (u_merge_arb_1__in_2_bits_s1_entry_0_cf),
    .io_in_2_bits_s1_entry_1_tag     (u_merge_arb_1__in_2_bits_s1_entry_1_tag),
    .io_in_2_bits_s1_entry_1_asid    (u_merge_arb_1__in_2_bits_s1_entry_1_asid),
    .io_in_2_bits_s1_entry_1_vmid    (u_merge_arb_1__in_2_bits_s1_entry_1_vmid),
    .io_in_2_bits_s1_entry_1_n       (u_merge_arb_1__in_2_bits_s1_entry_1_n),
    .io_in_2_bits_s1_entry_1_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_1_pbmt),
    .io_in_2_bits_s1_entry_1_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_d),
    .io_in_2_bits_s1_entry_1_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_a),
    .io_in_2_bits_s1_entry_1_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_g),
    .io_in_2_bits_s1_entry_1_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_u),
    .io_in_2_bits_s1_entry_1_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_x),
    .io_in_2_bits_s1_entry_1_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_w),
    .io_in_2_bits_s1_entry_1_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_1_perm_r),
    .io_in_2_bits_s1_entry_1_level   (u_merge_arb_1__in_2_bits_s1_entry_1_level),
    .io_in_2_bits_s1_entry_1_v       (u_merge_arb_1__in_2_bits_s1_entry_1_v),
    .io_in_2_bits_s1_entry_1_ppn     (u_merge_arb_1__in_2_bits_s1_entry_1_ppn),
    .io_in_2_bits_s1_entry_1_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_1_ppn_low),
    .io_in_2_bits_s1_entry_1_af      (u_merge_arb_1__in_2_bits_s1_entry_1_af),
    .io_in_2_bits_s1_entry_1_pf      (u_merge_arb_1__in_2_bits_s1_entry_1_pf),
    .io_in_2_bits_s1_entry_1_cf      (u_merge_arb_1__in_2_bits_s1_entry_1_cf),
    .io_in_2_bits_s1_entry_2_tag     (u_merge_arb_1__in_2_bits_s1_entry_2_tag),
    .io_in_2_bits_s1_entry_2_asid    (u_merge_arb_1__in_2_bits_s1_entry_2_asid),
    .io_in_2_bits_s1_entry_2_vmid    (u_merge_arb_1__in_2_bits_s1_entry_2_vmid),
    .io_in_2_bits_s1_entry_2_n       (u_merge_arb_1__in_2_bits_s1_entry_2_n),
    .io_in_2_bits_s1_entry_2_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_2_pbmt),
    .io_in_2_bits_s1_entry_2_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_d),
    .io_in_2_bits_s1_entry_2_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_a),
    .io_in_2_bits_s1_entry_2_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_g),
    .io_in_2_bits_s1_entry_2_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_u),
    .io_in_2_bits_s1_entry_2_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_x),
    .io_in_2_bits_s1_entry_2_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_w),
    .io_in_2_bits_s1_entry_2_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_2_perm_r),
    .io_in_2_bits_s1_entry_2_level   (u_merge_arb_1__in_2_bits_s1_entry_2_level),
    .io_in_2_bits_s1_entry_2_v       (u_merge_arb_1__in_2_bits_s1_entry_2_v),
    .io_in_2_bits_s1_entry_2_ppn     (u_merge_arb_1__in_2_bits_s1_entry_2_ppn),
    .io_in_2_bits_s1_entry_2_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_2_ppn_low),
    .io_in_2_bits_s1_entry_2_af      (u_merge_arb_1__in_2_bits_s1_entry_2_af),
    .io_in_2_bits_s1_entry_2_pf      (u_merge_arb_1__in_2_bits_s1_entry_2_pf),
    .io_in_2_bits_s1_entry_2_cf      (u_merge_arb_1__in_2_bits_s1_entry_2_cf),
    .io_in_2_bits_s1_entry_3_tag     (u_merge_arb_1__in_2_bits_s1_entry_3_tag),
    .io_in_2_bits_s1_entry_3_asid    (u_merge_arb_1__in_2_bits_s1_entry_3_asid),
    .io_in_2_bits_s1_entry_3_vmid    (u_merge_arb_1__in_2_bits_s1_entry_3_vmid),
    .io_in_2_bits_s1_entry_3_n       (u_merge_arb_1__in_2_bits_s1_entry_3_n),
    .io_in_2_bits_s1_entry_3_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_3_pbmt),
    .io_in_2_bits_s1_entry_3_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_d),
    .io_in_2_bits_s1_entry_3_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_a),
    .io_in_2_bits_s1_entry_3_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_g),
    .io_in_2_bits_s1_entry_3_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_u),
    .io_in_2_bits_s1_entry_3_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_x),
    .io_in_2_bits_s1_entry_3_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_w),
    .io_in_2_bits_s1_entry_3_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_3_perm_r),
    .io_in_2_bits_s1_entry_3_level   (u_merge_arb_1__in_2_bits_s1_entry_3_level),
    .io_in_2_bits_s1_entry_3_v       (u_merge_arb_1__in_2_bits_s1_entry_3_v),
    .io_in_2_bits_s1_entry_3_ppn     (u_merge_arb_1__in_2_bits_s1_entry_3_ppn),
    .io_in_2_bits_s1_entry_3_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_3_ppn_low),
    .io_in_2_bits_s1_entry_3_af      (u_merge_arb_1__in_2_bits_s1_entry_3_af),
    .io_in_2_bits_s1_entry_3_pf      (u_merge_arb_1__in_2_bits_s1_entry_3_pf),
    .io_in_2_bits_s1_entry_3_cf      (u_merge_arb_1__in_2_bits_s1_entry_3_cf),
    .io_in_2_bits_s1_entry_4_tag     (u_merge_arb_1__in_2_bits_s1_entry_4_tag),
    .io_in_2_bits_s1_entry_4_asid    (u_merge_arb_1__in_2_bits_s1_entry_4_asid),
    .io_in_2_bits_s1_entry_4_vmid    (u_merge_arb_1__in_2_bits_s1_entry_4_vmid),
    .io_in_2_bits_s1_entry_4_n       (u_merge_arb_1__in_2_bits_s1_entry_4_n),
    .io_in_2_bits_s1_entry_4_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_4_pbmt),
    .io_in_2_bits_s1_entry_4_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_d),
    .io_in_2_bits_s1_entry_4_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_a),
    .io_in_2_bits_s1_entry_4_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_g),
    .io_in_2_bits_s1_entry_4_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_u),
    .io_in_2_bits_s1_entry_4_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_x),
    .io_in_2_bits_s1_entry_4_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_w),
    .io_in_2_bits_s1_entry_4_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_4_perm_r),
    .io_in_2_bits_s1_entry_4_level   (u_merge_arb_1__in_2_bits_s1_entry_4_level),
    .io_in_2_bits_s1_entry_4_v       (u_merge_arb_1__in_2_bits_s1_entry_4_v),
    .io_in_2_bits_s1_entry_4_ppn     (u_merge_arb_1__in_2_bits_s1_entry_4_ppn),
    .io_in_2_bits_s1_entry_4_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_4_ppn_low),
    .io_in_2_bits_s1_entry_4_af      (u_merge_arb_1__in_2_bits_s1_entry_4_af),
    .io_in_2_bits_s1_entry_4_pf      (u_merge_arb_1__in_2_bits_s1_entry_4_pf),
    .io_in_2_bits_s1_entry_4_cf      (u_merge_arb_1__in_2_bits_s1_entry_4_cf),
    .io_in_2_bits_s1_entry_5_tag     (u_merge_arb_1__in_2_bits_s1_entry_5_tag),
    .io_in_2_bits_s1_entry_5_asid    (u_merge_arb_1__in_2_bits_s1_entry_5_asid),
    .io_in_2_bits_s1_entry_5_vmid    (u_merge_arb_1__in_2_bits_s1_entry_5_vmid),
    .io_in_2_bits_s1_entry_5_n       (u_merge_arb_1__in_2_bits_s1_entry_5_n),
    .io_in_2_bits_s1_entry_5_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_5_pbmt),
    .io_in_2_bits_s1_entry_5_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_d),
    .io_in_2_bits_s1_entry_5_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_a),
    .io_in_2_bits_s1_entry_5_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_g),
    .io_in_2_bits_s1_entry_5_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_u),
    .io_in_2_bits_s1_entry_5_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_x),
    .io_in_2_bits_s1_entry_5_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_w),
    .io_in_2_bits_s1_entry_5_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_5_perm_r),
    .io_in_2_bits_s1_entry_5_level   (u_merge_arb_1__in_2_bits_s1_entry_5_level),
    .io_in_2_bits_s1_entry_5_v       (u_merge_arb_1__in_2_bits_s1_entry_5_v),
    .io_in_2_bits_s1_entry_5_ppn     (u_merge_arb_1__in_2_bits_s1_entry_5_ppn),
    .io_in_2_bits_s1_entry_5_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_5_ppn_low),
    .io_in_2_bits_s1_entry_5_af      (u_merge_arb_1__in_2_bits_s1_entry_5_af),
    .io_in_2_bits_s1_entry_5_pf      (u_merge_arb_1__in_2_bits_s1_entry_5_pf),
    .io_in_2_bits_s1_entry_5_cf      (u_merge_arb_1__in_2_bits_s1_entry_5_cf),
    .io_in_2_bits_s1_entry_6_tag     (u_merge_arb_1__in_2_bits_s1_entry_6_tag),
    .io_in_2_bits_s1_entry_6_asid    (u_merge_arb_1__in_2_bits_s1_entry_6_asid),
    .io_in_2_bits_s1_entry_6_vmid    (u_merge_arb_1__in_2_bits_s1_entry_6_vmid),
    .io_in_2_bits_s1_entry_6_n       (u_merge_arb_1__in_2_bits_s1_entry_6_n),
    .io_in_2_bits_s1_entry_6_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_6_pbmt),
    .io_in_2_bits_s1_entry_6_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_d),
    .io_in_2_bits_s1_entry_6_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_a),
    .io_in_2_bits_s1_entry_6_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_g),
    .io_in_2_bits_s1_entry_6_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_u),
    .io_in_2_bits_s1_entry_6_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_x),
    .io_in_2_bits_s1_entry_6_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_w),
    .io_in_2_bits_s1_entry_6_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_6_perm_r),
    .io_in_2_bits_s1_entry_6_level   (u_merge_arb_1__in_2_bits_s1_entry_6_level),
    .io_in_2_bits_s1_entry_6_v       (u_merge_arb_1__in_2_bits_s1_entry_6_v),
    .io_in_2_bits_s1_entry_6_ppn     (u_merge_arb_1__in_2_bits_s1_entry_6_ppn),
    .io_in_2_bits_s1_entry_6_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_6_ppn_low),
    .io_in_2_bits_s1_entry_6_af      (u_merge_arb_1__in_2_bits_s1_entry_6_af),
    .io_in_2_bits_s1_entry_6_pf      (u_merge_arb_1__in_2_bits_s1_entry_6_pf),
    .io_in_2_bits_s1_entry_6_cf      (u_merge_arb_1__in_2_bits_s1_entry_6_cf),
    .io_in_2_bits_s1_entry_7_tag     (u_merge_arb_1__in_2_bits_s1_entry_7_tag),
    .io_in_2_bits_s1_entry_7_asid    (u_merge_arb_1__in_2_bits_s1_entry_7_asid),
    .io_in_2_bits_s1_entry_7_vmid    (u_merge_arb_1__in_2_bits_s1_entry_7_vmid),
    .io_in_2_bits_s1_entry_7_n       (u_merge_arb_1__in_2_bits_s1_entry_7_n),
    .io_in_2_bits_s1_entry_7_pbmt    (u_merge_arb_1__in_2_bits_s1_entry_7_pbmt),
    .io_in_2_bits_s1_entry_7_perm_d  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_d),
    .io_in_2_bits_s1_entry_7_perm_a  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_a),
    .io_in_2_bits_s1_entry_7_perm_g  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_g),
    .io_in_2_bits_s1_entry_7_perm_u  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_u),
    .io_in_2_bits_s1_entry_7_perm_x  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_x),
    .io_in_2_bits_s1_entry_7_perm_w  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_w),
    .io_in_2_bits_s1_entry_7_perm_r  (u_merge_arb_1__in_2_bits_s1_entry_7_perm_r),
    .io_in_2_bits_s1_entry_7_level   (u_merge_arb_1__in_2_bits_s1_entry_7_level),
    .io_in_2_bits_s1_entry_7_v       (u_merge_arb_1__in_2_bits_s1_entry_7_v),
    .io_in_2_bits_s1_entry_7_ppn     (u_merge_arb_1__in_2_bits_s1_entry_7_ppn),
    .io_in_2_bits_s1_entry_7_ppn_low (u_merge_arb_1__in_2_bits_s1_entry_7_ppn_low),
    .io_in_2_bits_s1_entry_7_af      (u_merge_arb_1__in_2_bits_s1_entry_7_af),
    .io_in_2_bits_s1_entry_7_pf      (u_merge_arb_1__in_2_bits_s1_entry_7_pf),
    .io_in_2_bits_s1_entry_7_cf      (u_merge_arb_1__in_2_bits_s1_entry_7_cf),
    .io_in_2_bits_s1_pteidx_0        (u_merge_arb_1__in_2_bits_s1_pteidx_0),
    .io_in_2_bits_s1_pteidx_1        (u_merge_arb_1__in_2_bits_s1_pteidx_1),
    .io_in_2_bits_s1_pteidx_2        (u_merge_arb_1__in_2_bits_s1_pteidx_2),
    .io_in_2_bits_s1_pteidx_3        (u_merge_arb_1__in_2_bits_s1_pteidx_3),
    .io_in_2_bits_s1_pteidx_4        (u_merge_arb_1__in_2_bits_s1_pteidx_4),
    .io_in_2_bits_s1_pteidx_5        (u_merge_arb_1__in_2_bits_s1_pteidx_5),
    .io_in_2_bits_s1_pteidx_6        (u_merge_arb_1__in_2_bits_s1_pteidx_6),
    .io_in_2_bits_s1_pteidx_7        (u_merge_arb_1__in_2_bits_s1_pteidx_7),
    .io_in_2_bits_s1_not_super       (u_merge_arb_1__in_2_bits_s1_not_super),
    .io_in_2_bits_s1_not_merge       (u_merge_arb_1__in_2_bits_s1_not_merge),
    .io_in_2_bits_s2_entry_tag       (u_llptw_out_bits_h_resp_entry_tag),
    .io_in_2_bits_s2_entry_vmid      (u_llptw_out_bits_h_resp_entry_vmid),
    .io_in_2_bits_s2_entry_n         (u_llptw_out_bits_h_resp_entry_n),
    .io_in_2_bits_s2_entry_pbmt      (u_llptw_out_bits_h_resp_entry_pbmt),
    .io_in_2_bits_s2_entry_ppn       (u_llptw_out_bits_h_resp_entry_ppn),
    .io_in_2_bits_s2_entry_perm_d    (u_llptw_out_bits_h_resp_entry_perm_d),
    .io_in_2_bits_s2_entry_perm_a    (u_llptw_out_bits_h_resp_entry_perm_a),
    .io_in_2_bits_s2_entry_perm_g    (u_llptw_out_bits_h_resp_entry_perm_g),
    .io_in_2_bits_s2_entry_perm_u    (u_llptw_out_bits_h_resp_entry_perm_u),
    .io_in_2_bits_s2_entry_perm_x    (u_llptw_out_bits_h_resp_entry_perm_x),
    .io_in_2_bits_s2_entry_perm_w    (u_llptw_out_bits_h_resp_entry_perm_w),
    .io_in_2_bits_s2_entry_perm_r    (u_llptw_out_bits_h_resp_entry_perm_r),
    .io_in_2_bits_s2_entry_level     (u_llptw_out_bits_h_resp_entry_level),
    .io_in_2_bits_s2_gpf             (u_llptw_out_bits_h_resp_gpf),
    .io_in_2_bits_s2_gaf             (u_llptw_out_bits_h_resp_gaf),
    .io_out_ready                    (u_out_arb_1_in_0_ready),
    .io_out_valid                    (u_merge_arb_1_out_valid),
    .io_out_bits_s2xlate             (u_merge_arb_1_out_bits_s2xlate),
    .io_out_bits_s1_entry_0_tag      (u_merge_arb_1_out_bits_s1_entry_0_tag),
    .io_out_bits_s1_entry_0_asid     (u_merge_arb_1_out_bits_s1_entry_0_asid),
    .io_out_bits_s1_entry_0_vmid     (u_merge_arb_1_out_bits_s1_entry_0_vmid),
    .io_out_bits_s1_entry_0_n        (u_merge_arb_1_out_bits_s1_entry_0_n),
    .io_out_bits_s1_entry_0_pbmt     (u_merge_arb_1_out_bits_s1_entry_0_pbmt),
    .io_out_bits_s1_entry_0_perm_d   (u_merge_arb_1_out_bits_s1_entry_0_perm_d),
    .io_out_bits_s1_entry_0_perm_a   (u_merge_arb_1_out_bits_s1_entry_0_perm_a),
    .io_out_bits_s1_entry_0_perm_g   (u_merge_arb_1_out_bits_s1_entry_0_perm_g),
    .io_out_bits_s1_entry_0_perm_u   (u_merge_arb_1_out_bits_s1_entry_0_perm_u),
    .io_out_bits_s1_entry_0_perm_x   (u_merge_arb_1_out_bits_s1_entry_0_perm_x),
    .io_out_bits_s1_entry_0_perm_w   (u_merge_arb_1_out_bits_s1_entry_0_perm_w),
    .io_out_bits_s1_entry_0_perm_r   (u_merge_arb_1_out_bits_s1_entry_0_perm_r),
    .io_out_bits_s1_entry_0_level    (u_merge_arb_1_out_bits_s1_entry_0_level),
    .io_out_bits_s1_entry_0_v        (u_merge_arb_1_out_bits_s1_entry_0_v),
    .io_out_bits_s1_entry_0_ppn      (u_merge_arb_1_out_bits_s1_entry_0_ppn),
    .io_out_bits_s1_entry_0_ppn_low  (u_merge_arb_1_out_bits_s1_entry_0_ppn_low),
    .io_out_bits_s1_entry_0_af       (u_merge_arb_1_out_bits_s1_entry_0_af),
    .io_out_bits_s1_entry_0_pf       (u_merge_arb_1_out_bits_s1_entry_0_pf),
    .io_out_bits_s1_entry_0_cf       (u_merge_arb_1_out_bits_s1_entry_0_cf),
    .io_out_bits_s1_entry_1_tag      (u_merge_arb_1_out_bits_s1_entry_1_tag),
    .io_out_bits_s1_entry_1_asid     (u_merge_arb_1_out_bits_s1_entry_1_asid),
    .io_out_bits_s1_entry_1_vmid     (u_merge_arb_1_out_bits_s1_entry_1_vmid),
    .io_out_bits_s1_entry_1_n        (u_merge_arb_1_out_bits_s1_entry_1_n),
    .io_out_bits_s1_entry_1_pbmt     (u_merge_arb_1_out_bits_s1_entry_1_pbmt),
    .io_out_bits_s1_entry_1_perm_d   (u_merge_arb_1_out_bits_s1_entry_1_perm_d),
    .io_out_bits_s1_entry_1_perm_a   (u_merge_arb_1_out_bits_s1_entry_1_perm_a),
    .io_out_bits_s1_entry_1_perm_g   (u_merge_arb_1_out_bits_s1_entry_1_perm_g),
    .io_out_bits_s1_entry_1_perm_u   (u_merge_arb_1_out_bits_s1_entry_1_perm_u),
    .io_out_bits_s1_entry_1_perm_x   (u_merge_arb_1_out_bits_s1_entry_1_perm_x),
    .io_out_bits_s1_entry_1_perm_w   (u_merge_arb_1_out_bits_s1_entry_1_perm_w),
    .io_out_bits_s1_entry_1_perm_r   (u_merge_arb_1_out_bits_s1_entry_1_perm_r),
    .io_out_bits_s1_entry_1_level    (u_merge_arb_1_out_bits_s1_entry_1_level),
    .io_out_bits_s1_entry_1_v        (u_merge_arb_1_out_bits_s1_entry_1_v),
    .io_out_bits_s1_entry_1_ppn      (u_merge_arb_1_out_bits_s1_entry_1_ppn),
    .io_out_bits_s1_entry_1_ppn_low  (u_merge_arb_1_out_bits_s1_entry_1_ppn_low),
    .io_out_bits_s1_entry_1_af       (u_merge_arb_1_out_bits_s1_entry_1_af),
    .io_out_bits_s1_entry_1_pf       (u_merge_arb_1_out_bits_s1_entry_1_pf),
    .io_out_bits_s1_entry_1_cf       (u_merge_arb_1_out_bits_s1_entry_1_cf),
    .io_out_bits_s1_entry_2_tag      (u_merge_arb_1_out_bits_s1_entry_2_tag),
    .io_out_bits_s1_entry_2_asid     (u_merge_arb_1_out_bits_s1_entry_2_asid),
    .io_out_bits_s1_entry_2_vmid     (u_merge_arb_1_out_bits_s1_entry_2_vmid),
    .io_out_bits_s1_entry_2_n        (u_merge_arb_1_out_bits_s1_entry_2_n),
    .io_out_bits_s1_entry_2_pbmt     (u_merge_arb_1_out_bits_s1_entry_2_pbmt),
    .io_out_bits_s1_entry_2_perm_d   (u_merge_arb_1_out_bits_s1_entry_2_perm_d),
    .io_out_bits_s1_entry_2_perm_a   (u_merge_arb_1_out_bits_s1_entry_2_perm_a),
    .io_out_bits_s1_entry_2_perm_g   (u_merge_arb_1_out_bits_s1_entry_2_perm_g),
    .io_out_bits_s1_entry_2_perm_u   (u_merge_arb_1_out_bits_s1_entry_2_perm_u),
    .io_out_bits_s1_entry_2_perm_x   (u_merge_arb_1_out_bits_s1_entry_2_perm_x),
    .io_out_bits_s1_entry_2_perm_w   (u_merge_arb_1_out_bits_s1_entry_2_perm_w),
    .io_out_bits_s1_entry_2_perm_r   (u_merge_arb_1_out_bits_s1_entry_2_perm_r),
    .io_out_bits_s1_entry_2_level    (u_merge_arb_1_out_bits_s1_entry_2_level),
    .io_out_bits_s1_entry_2_v        (u_merge_arb_1_out_bits_s1_entry_2_v),
    .io_out_bits_s1_entry_2_ppn      (u_merge_arb_1_out_bits_s1_entry_2_ppn),
    .io_out_bits_s1_entry_2_ppn_low  (u_merge_arb_1_out_bits_s1_entry_2_ppn_low),
    .io_out_bits_s1_entry_2_af       (u_merge_arb_1_out_bits_s1_entry_2_af),
    .io_out_bits_s1_entry_2_pf       (u_merge_arb_1_out_bits_s1_entry_2_pf),
    .io_out_bits_s1_entry_2_cf       (u_merge_arb_1_out_bits_s1_entry_2_cf),
    .io_out_bits_s1_entry_3_tag      (u_merge_arb_1_out_bits_s1_entry_3_tag),
    .io_out_bits_s1_entry_3_asid     (u_merge_arb_1_out_bits_s1_entry_3_asid),
    .io_out_bits_s1_entry_3_vmid     (u_merge_arb_1_out_bits_s1_entry_3_vmid),
    .io_out_bits_s1_entry_3_n        (u_merge_arb_1_out_bits_s1_entry_3_n),
    .io_out_bits_s1_entry_3_pbmt     (u_merge_arb_1_out_bits_s1_entry_3_pbmt),
    .io_out_bits_s1_entry_3_perm_d   (u_merge_arb_1_out_bits_s1_entry_3_perm_d),
    .io_out_bits_s1_entry_3_perm_a   (u_merge_arb_1_out_bits_s1_entry_3_perm_a),
    .io_out_bits_s1_entry_3_perm_g   (u_merge_arb_1_out_bits_s1_entry_3_perm_g),
    .io_out_bits_s1_entry_3_perm_u   (u_merge_arb_1_out_bits_s1_entry_3_perm_u),
    .io_out_bits_s1_entry_3_perm_x   (u_merge_arb_1_out_bits_s1_entry_3_perm_x),
    .io_out_bits_s1_entry_3_perm_w   (u_merge_arb_1_out_bits_s1_entry_3_perm_w),
    .io_out_bits_s1_entry_3_perm_r   (u_merge_arb_1_out_bits_s1_entry_3_perm_r),
    .io_out_bits_s1_entry_3_level    (u_merge_arb_1_out_bits_s1_entry_3_level),
    .io_out_bits_s1_entry_3_v        (u_merge_arb_1_out_bits_s1_entry_3_v),
    .io_out_bits_s1_entry_3_ppn      (u_merge_arb_1_out_bits_s1_entry_3_ppn),
    .io_out_bits_s1_entry_3_ppn_low  (u_merge_arb_1_out_bits_s1_entry_3_ppn_low),
    .io_out_bits_s1_entry_3_af       (u_merge_arb_1_out_bits_s1_entry_3_af),
    .io_out_bits_s1_entry_3_pf       (u_merge_arb_1_out_bits_s1_entry_3_pf),
    .io_out_bits_s1_entry_3_cf       (u_merge_arb_1_out_bits_s1_entry_3_cf),
    .io_out_bits_s1_entry_4_tag      (u_merge_arb_1_out_bits_s1_entry_4_tag),
    .io_out_bits_s1_entry_4_asid     (u_merge_arb_1_out_bits_s1_entry_4_asid),
    .io_out_bits_s1_entry_4_vmid     (u_merge_arb_1_out_bits_s1_entry_4_vmid),
    .io_out_bits_s1_entry_4_n        (u_merge_arb_1_out_bits_s1_entry_4_n),
    .io_out_bits_s1_entry_4_pbmt     (u_merge_arb_1_out_bits_s1_entry_4_pbmt),
    .io_out_bits_s1_entry_4_perm_d   (u_merge_arb_1_out_bits_s1_entry_4_perm_d),
    .io_out_bits_s1_entry_4_perm_a   (u_merge_arb_1_out_bits_s1_entry_4_perm_a),
    .io_out_bits_s1_entry_4_perm_g   (u_merge_arb_1_out_bits_s1_entry_4_perm_g),
    .io_out_bits_s1_entry_4_perm_u   (u_merge_arb_1_out_bits_s1_entry_4_perm_u),
    .io_out_bits_s1_entry_4_perm_x   (u_merge_arb_1_out_bits_s1_entry_4_perm_x),
    .io_out_bits_s1_entry_4_perm_w   (u_merge_arb_1_out_bits_s1_entry_4_perm_w),
    .io_out_bits_s1_entry_4_perm_r   (u_merge_arb_1_out_bits_s1_entry_4_perm_r),
    .io_out_bits_s1_entry_4_level    (u_merge_arb_1_out_bits_s1_entry_4_level),
    .io_out_bits_s1_entry_4_v        (u_merge_arb_1_out_bits_s1_entry_4_v),
    .io_out_bits_s1_entry_4_ppn      (u_merge_arb_1_out_bits_s1_entry_4_ppn),
    .io_out_bits_s1_entry_4_ppn_low  (u_merge_arb_1_out_bits_s1_entry_4_ppn_low),
    .io_out_bits_s1_entry_4_af       (u_merge_arb_1_out_bits_s1_entry_4_af),
    .io_out_bits_s1_entry_4_pf       (u_merge_arb_1_out_bits_s1_entry_4_pf),
    .io_out_bits_s1_entry_4_cf       (u_merge_arb_1_out_bits_s1_entry_4_cf),
    .io_out_bits_s1_entry_5_tag      (u_merge_arb_1_out_bits_s1_entry_5_tag),
    .io_out_bits_s1_entry_5_asid     (u_merge_arb_1_out_bits_s1_entry_5_asid),
    .io_out_bits_s1_entry_5_vmid     (u_merge_arb_1_out_bits_s1_entry_5_vmid),
    .io_out_bits_s1_entry_5_n        (u_merge_arb_1_out_bits_s1_entry_5_n),
    .io_out_bits_s1_entry_5_pbmt     (u_merge_arb_1_out_bits_s1_entry_5_pbmt),
    .io_out_bits_s1_entry_5_perm_d   (u_merge_arb_1_out_bits_s1_entry_5_perm_d),
    .io_out_bits_s1_entry_5_perm_a   (u_merge_arb_1_out_bits_s1_entry_5_perm_a),
    .io_out_bits_s1_entry_5_perm_g   (u_merge_arb_1_out_bits_s1_entry_5_perm_g),
    .io_out_bits_s1_entry_5_perm_u   (u_merge_arb_1_out_bits_s1_entry_5_perm_u),
    .io_out_bits_s1_entry_5_perm_x   (u_merge_arb_1_out_bits_s1_entry_5_perm_x),
    .io_out_bits_s1_entry_5_perm_w   (u_merge_arb_1_out_bits_s1_entry_5_perm_w),
    .io_out_bits_s1_entry_5_perm_r   (u_merge_arb_1_out_bits_s1_entry_5_perm_r),
    .io_out_bits_s1_entry_5_level    (u_merge_arb_1_out_bits_s1_entry_5_level),
    .io_out_bits_s1_entry_5_v        (u_merge_arb_1_out_bits_s1_entry_5_v),
    .io_out_bits_s1_entry_5_ppn      (u_merge_arb_1_out_bits_s1_entry_5_ppn),
    .io_out_bits_s1_entry_5_ppn_low  (u_merge_arb_1_out_bits_s1_entry_5_ppn_low),
    .io_out_bits_s1_entry_5_af       (u_merge_arb_1_out_bits_s1_entry_5_af),
    .io_out_bits_s1_entry_5_pf       (u_merge_arb_1_out_bits_s1_entry_5_pf),
    .io_out_bits_s1_entry_5_cf       (u_merge_arb_1_out_bits_s1_entry_5_cf),
    .io_out_bits_s1_entry_6_tag      (u_merge_arb_1_out_bits_s1_entry_6_tag),
    .io_out_bits_s1_entry_6_asid     (u_merge_arb_1_out_bits_s1_entry_6_asid),
    .io_out_bits_s1_entry_6_vmid     (u_merge_arb_1_out_bits_s1_entry_6_vmid),
    .io_out_bits_s1_entry_6_n        (u_merge_arb_1_out_bits_s1_entry_6_n),
    .io_out_bits_s1_entry_6_pbmt     (u_merge_arb_1_out_bits_s1_entry_6_pbmt),
    .io_out_bits_s1_entry_6_perm_d   (u_merge_arb_1_out_bits_s1_entry_6_perm_d),
    .io_out_bits_s1_entry_6_perm_a   (u_merge_arb_1_out_bits_s1_entry_6_perm_a),
    .io_out_bits_s1_entry_6_perm_g   (u_merge_arb_1_out_bits_s1_entry_6_perm_g),
    .io_out_bits_s1_entry_6_perm_u   (u_merge_arb_1_out_bits_s1_entry_6_perm_u),
    .io_out_bits_s1_entry_6_perm_x   (u_merge_arb_1_out_bits_s1_entry_6_perm_x),
    .io_out_bits_s1_entry_6_perm_w   (u_merge_arb_1_out_bits_s1_entry_6_perm_w),
    .io_out_bits_s1_entry_6_perm_r   (u_merge_arb_1_out_bits_s1_entry_6_perm_r),
    .io_out_bits_s1_entry_6_level    (u_merge_arb_1_out_bits_s1_entry_6_level),
    .io_out_bits_s1_entry_6_v        (u_merge_arb_1_out_bits_s1_entry_6_v),
    .io_out_bits_s1_entry_6_ppn      (u_merge_arb_1_out_bits_s1_entry_6_ppn),
    .io_out_bits_s1_entry_6_ppn_low  (u_merge_arb_1_out_bits_s1_entry_6_ppn_low),
    .io_out_bits_s1_entry_6_af       (u_merge_arb_1_out_bits_s1_entry_6_af),
    .io_out_bits_s1_entry_6_pf       (u_merge_arb_1_out_bits_s1_entry_6_pf),
    .io_out_bits_s1_entry_6_cf       (u_merge_arb_1_out_bits_s1_entry_6_cf),
    .io_out_bits_s1_entry_7_tag      (u_merge_arb_1_out_bits_s1_entry_7_tag),
    .io_out_bits_s1_entry_7_asid     (u_merge_arb_1_out_bits_s1_entry_7_asid),
    .io_out_bits_s1_entry_7_vmid     (u_merge_arb_1_out_bits_s1_entry_7_vmid),
    .io_out_bits_s1_entry_7_n        (u_merge_arb_1_out_bits_s1_entry_7_n),
    .io_out_bits_s1_entry_7_pbmt     (u_merge_arb_1_out_bits_s1_entry_7_pbmt),
    .io_out_bits_s1_entry_7_perm_d   (u_merge_arb_1_out_bits_s1_entry_7_perm_d),
    .io_out_bits_s1_entry_7_perm_a   (u_merge_arb_1_out_bits_s1_entry_7_perm_a),
    .io_out_bits_s1_entry_7_perm_g   (u_merge_arb_1_out_bits_s1_entry_7_perm_g),
    .io_out_bits_s1_entry_7_perm_u   (u_merge_arb_1_out_bits_s1_entry_7_perm_u),
    .io_out_bits_s1_entry_7_perm_x   (u_merge_arb_1_out_bits_s1_entry_7_perm_x),
    .io_out_bits_s1_entry_7_perm_w   (u_merge_arb_1_out_bits_s1_entry_7_perm_w),
    .io_out_bits_s1_entry_7_perm_r   (u_merge_arb_1_out_bits_s1_entry_7_perm_r),
    .io_out_bits_s1_entry_7_level    (u_merge_arb_1_out_bits_s1_entry_7_level),
    .io_out_bits_s1_entry_7_v        (u_merge_arb_1_out_bits_s1_entry_7_v),
    .io_out_bits_s1_entry_7_ppn      (u_merge_arb_1_out_bits_s1_entry_7_ppn),
    .io_out_bits_s1_entry_7_ppn_low  (u_merge_arb_1_out_bits_s1_entry_7_ppn_low),
    .io_out_bits_s1_entry_7_af       (u_merge_arb_1_out_bits_s1_entry_7_af),
    .io_out_bits_s1_entry_7_pf       (u_merge_arb_1_out_bits_s1_entry_7_pf),
    .io_out_bits_s1_entry_7_cf       (u_merge_arb_1_out_bits_s1_entry_7_cf),
    .io_out_bits_s1_pteidx_0         (u_merge_arb_1_out_bits_s1_pteidx_0),
    .io_out_bits_s1_pteidx_1         (u_merge_arb_1_out_bits_s1_pteidx_1),
    .io_out_bits_s1_pteidx_2         (u_merge_arb_1_out_bits_s1_pteidx_2),
    .io_out_bits_s1_pteidx_3         (u_merge_arb_1_out_bits_s1_pteidx_3),
    .io_out_bits_s1_pteidx_4         (u_merge_arb_1_out_bits_s1_pteidx_4),
    .io_out_bits_s1_pteidx_5         (u_merge_arb_1_out_bits_s1_pteidx_5),
    .io_out_bits_s1_pteidx_6         (u_merge_arb_1_out_bits_s1_pteidx_6),
    .io_out_bits_s1_pteidx_7         (u_merge_arb_1_out_bits_s1_pteidx_7),
    .io_out_bits_s1_not_super        (u_merge_arb_1_out_bits_s1_not_super),
    .io_out_bits_s1_not_merge        (u_merge_arb_1_out_bits_s1_not_merge),
    .io_out_bits_s2_entry_tag        (u_merge_arb_1_out_bits_s2_entry_tag),
    .io_out_bits_s2_entry_vmid       (u_merge_arb_1_out_bits_s2_entry_vmid),
    .io_out_bits_s2_entry_n          (u_merge_arb_1_out_bits_s2_entry_n),
    .io_out_bits_s2_entry_pbmt       (u_merge_arb_1_out_bits_s2_entry_pbmt),
    .io_out_bits_s2_entry_ppn        (u_merge_arb_1_out_bits_s2_entry_ppn),
    .io_out_bits_s2_entry_perm_d     (u_merge_arb_1_out_bits_s2_entry_perm_d),
    .io_out_bits_s2_entry_perm_a     (u_merge_arb_1_out_bits_s2_entry_perm_a),
    .io_out_bits_s2_entry_perm_g     (u_merge_arb_1_out_bits_s2_entry_perm_g),
    .io_out_bits_s2_entry_perm_u     (u_merge_arb_1_out_bits_s2_entry_perm_u),
    .io_out_bits_s2_entry_perm_x     (u_merge_arb_1_out_bits_s2_entry_perm_x),
    .io_out_bits_s2_entry_perm_w     (u_merge_arb_1_out_bits_s2_entry_perm_w),
    .io_out_bits_s2_entry_perm_r     (u_merge_arb_1_out_bits_s2_entry_perm_r),
    .io_out_bits_s2_entry_level      (u_merge_arb_1_out_bits_s2_entry_level),
    .io_out_bits_s2_gpf              (u_merge_arb_1_out_bits_s2_gpf),
    .io_out_bits_s2_gaf              (u_merge_arb_1_out_bits_s2_gaf)
  );

  L2TlbPrefetch u_prefetch (
    .clock                           (clock),
    .reset                           (reset),
    .io_sfence_valid                 (u_prefetch__sfence_valid),
    .io_csr_satp_changed             (u_prefetch__csr_satp_changed),
    .io_csr_vsatp_mode               (u_prefetch__csr_vsatp_mode),
    .io_csr_vsatp_changed            (u_prefetch__csr_vsatp_changed),
    .io_csr_hgatp_mode               (u_prefetch__csr_hgatp_mode),
    .io_csr_hgatp_changed            (u_prefetch__csr_hgatp_changed),
    .io_csr_priv_virt                (u_prefetch__csr_priv_virt),
    .io_csr_priv_virt_changed        (u_prefetch__csr_priv_virt_changed),
    .io_in_valid                     (u_prefetch__in_valid),
    .io_in_bits_vpn                  (u_page_cache_resp_bits_req_info_vpn),
    .io_out_ready                    (u_arb_cache_in_in_4_ready),
    .io_out_valid                    (u_prefetch_out_valid),
    .io_out_bits_req_info_vpn        (u_prefetch_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate    (u_prefetch_out_bits_req_info_s2xlate)
  );

  Arbiter2_L2TlbWithHptwIdBundle u_arb_mq (
    .io_in_0_ready                   (u_arb_mq_in_0_ready),
    .io_in_0_valid                   (u_arb_mq__in_0_valid),
    .io_in_0_bits_req_info_vpn       (u_page_cache_resp_bits_req_info_vpn),
    .io_in_0_bits_req_info_s2xlate   (u_page_cache_resp_bits_req_info_s2xlate),
    .io_in_0_bits_req_info_source    (u_page_cache_resp_bits_req_info_source),
    .io_in_0_bits_isLLptw            (u_arb_mq__in_0_bits_isLLptw),
    .io_in_1_ready                   (u_arb_mq_in_1_ready),
    .io_in_1_valid                   (u_llptw_cache_valid),
    .io_in_1_bits_req_info_vpn       (u_llptw_cache_bits_vpn),
    .io_in_1_bits_req_info_s2xlate   (u_llptw_cache_bits_s2xlate),
    .io_in_1_bits_req_info_source    (u_llptw_cache_bits_source),
    .io_out_ready                    (u_miss_queue_in_ready),
    .io_out_valid                    (u_arb_mq_out_valid),
    .io_out_bits_req_info_vpn        (u_arb_mq_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate    (u_arb_mq_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source     (u_arb_mq_out_bits_req_info_source),
    .io_out_bits_isLLptw             (u_arb_mq_out_bits_isLLptw)
  );

  DelayN_13 u_wfi_req_delay (
    .clock                           (clock),
    .io_in                           (io_wfi_wfiReq),
    .io_out                          (u_wfi_req_delay_out)
  );

  DelayN_13 u_wfi_safe_delay (
    .clock                           (clock),
    .io_in                           (u_wfi_safe_delay__in),
    .io_out                          (io_wfi_wfiSafe)
  );

  Arbiter4_L2TlbMemReqBundle u_mem_arb (
    .io_in_0_ready                   (u_mem_arb_in_0_ready),
    .io_in_0_valid                   (u_ptw_mem_req_valid),
    .io_in_0_bits_addr               (u_ptw_mem_req_bits_addr),
    .io_in_1_ready                   (u_mem_arb_in_1_ready),
    .io_in_1_valid                   (u_llptw_mem_req_valid),
    .io_in_1_bits_addr               (u_llptw_mem_req_bits_addr),
    .io_in_1_bits_id                 (u_llptw_mem_req_bits_id),
    .io_in_2_ready                   (u_mem_arb_in_2_ready),
    .io_in_2_valid                   (u_hptw_mem_req_valid),
    .io_in_2_bits_addr               (u_hptw_mem_req_bits_addr),
    .io_in_2_bits_hptw_bypassed      (u_hptw_mem_req_bits_hptw_bypassed),
    .io_in_3_ready                   (u_mem_arb_in_3_ready),
    .io_in_3_valid                   (u_bitmap_mem_req_valid),
    .io_in_3_bits_addr               (u_bitmap_mem_req_bits_addr),
    .io_in_3_bits_id                 (u_bitmap_mem_req_bits_id),
    .io_out_ready                    (u_mem_arb__out_ready),
    .io_out_valid                    (u_mem_arb_out_valid),
    .io_out_bits_addr                (u_mem_arb_out_bits_addr),
    .io_out_bits_id                  (u_mem_arb_out_bits_id),
    .io_out_bits_hptw_bypassed       (u_mem_arb_out_bits_hptw_bypassed)
  );

  Arbiter3_bitmapReqBundle u_bitmap_arb (
    .io_in_0_ready                   (u_bitmap_arb_in_0_ready),
    .io_in_0_valid                   (u_ptw_bitmap_req_valid),
    .io_in_0_bits_bmppn              (u_ptw_bitmap_req_bits_bmppn),
    .io_in_0_bits_vpn                (u_ptw_bitmap_req_bits_vpn),
    .io_in_0_bits_level              (u_ptw_bitmap_req_bits_level),
    .io_in_0_bits_s2xlate            (u_ptw_bitmap_req_bits_s2xlate),
    .io_in_0_bits_n                  (u_ptw_bitmap_req_bits_n),
    .io_in_1_ready                   (u_bitmap_arb_in_1_ready),
    .io_in_1_valid                   (u_llptw_bitmap_req_valid),
    .io_in_1_bits_bmppn              (u_llptw_bitmap_req_bits_bmppn),
    .io_in_1_bits_id                 (u_llptw_bitmap_req_bits_id),
    .io_in_1_bits_vpn                (u_llptw_bitmap_req_bits_vpn),
    .io_in_1_bits_way_info           (u_llptw_bitmap_req_bits_way_info),
    .io_in_1_bits_s2xlate            (u_llptw_bitmap_req_bits_s2xlate),
    .io_in_1_bits_n                  (u_llptw_bitmap_req_bits_n),
    .io_in_2_ready                   (u_bitmap_arb_in_2_ready),
    .io_in_2_valid                   (u_hptw_bitmap_req_valid),
    .io_in_2_bits_bmppn              (u_hptw_bitmap_req_bits_bmppn),
    .io_in_2_bits_vpn                (u_hptw_bitmap_req_bits_vpn),
    .io_in_2_bits_level              (u_hptw_bitmap_req_bits_level),
    .io_in_2_bits_way_info           (u_hptw_bitmap_req_bits_way_info),
    .io_in_2_bits_hptw_bypassed      (u_hptw_bitmap_req_bits_hptw_bypassed),
    .io_in_2_bits_n                  (u_hptw_bitmap_req_bits_n),
    .io_out_ready                    (u_bitmap_req_ready),
    .io_out_valid                    (u_bitmap_arb_out_valid),
    .io_out_bits_bmppn               (u_bitmap_arb_out_bits_bmppn),
    .io_out_bits_id                  (u_bitmap_arb_out_bits_id),
    .io_out_bits_vpn                 (u_bitmap_arb_out_bits_vpn),
    .io_out_bits_level               (u_bitmap_arb_out_bits_level),
    .io_out_bits_way_info            (u_bitmap_arb_out_bits_way_info),
    .io_out_bits_hptw_bypassed       (u_bitmap_arb_out_bits_hptw_bypassed),
    .io_out_bits_s2xlate             (u_bitmap_arb_out_bits_s2xlate),
    .io_out_bits_n                   (u_bitmap_arb_out_bits_n)
  );
  // END GENERATED

endmodule

// ============================================================================
// L2TLB —— 与 golden 端口逐位同名的外壳，直通到可读核。
// ============================================================================
module L2TLB (
  // BEGIN GENERATED(wrapper)
  input clock,
  input reset,
  input auto_out_a_ready,
  output auto_out_a_valid,
  output [3:0] auto_out_a_bits_source,
  output [47:0] auto_out_a_bits_address,
  input auto_out_d_valid,
  input [3:0] auto_out_d_bits_opcode,
  input [2:0] auto_out_d_bits_size,
  input [3:0] auto_out_d_bits_source,
  input [255:0] auto_out_d_bits_data,
  input [5:0] io_hartId,
  output io_tlb_0_req_0_ready,
  input io_tlb_0_req_0_valid,
  input [37:0] io_tlb_0_req_0_bits_vpn,
  input [1:0] io_tlb_0_req_0_bits_s2xlate,
  input io_tlb_0_resp_ready,
  output io_tlb_0_resp_valid,
  output [1:0] io_tlb_0_resp_bits_s2xlate,
  output [34:0] io_tlb_0_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_0_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_0_resp_bits_s1_entry_vmid,
  output io_tlb_0_resp_bits_s1_entry_n,
  output [1:0] io_tlb_0_resp_bits_s1_entry_pbmt,
  output io_tlb_0_resp_bits_s1_entry_perm_d,
  output io_tlb_0_resp_bits_s1_entry_perm_a,
  output io_tlb_0_resp_bits_s1_entry_perm_g,
  output io_tlb_0_resp_bits_s1_entry_perm_u,
  output io_tlb_0_resp_bits_s1_entry_perm_x,
  output io_tlb_0_resp_bits_s1_entry_perm_w,
  output io_tlb_0_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s1_entry_level,
  output io_tlb_0_resp_bits_s1_entry_v,
  output [40:0] io_tlb_0_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_0_resp_bits_s1_addr_low,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_7,
  output io_tlb_0_resp_bits_s1_valididx_0,
  output io_tlb_0_resp_bits_s1_valididx_1,
  output io_tlb_0_resp_bits_s1_valididx_2,
  output io_tlb_0_resp_bits_s1_valididx_3,
  output io_tlb_0_resp_bits_s1_valididx_4,
  output io_tlb_0_resp_bits_s1_valididx_5,
  output io_tlb_0_resp_bits_s1_valididx_6,
  output io_tlb_0_resp_bits_s1_valididx_7,
  output io_tlb_0_resp_bits_s1_pteidx_0,
  output io_tlb_0_resp_bits_s1_pteidx_1,
  output io_tlb_0_resp_bits_s1_pteidx_2,
  output io_tlb_0_resp_bits_s1_pteidx_3,
  output io_tlb_0_resp_bits_s1_pteidx_4,
  output io_tlb_0_resp_bits_s1_pteidx_5,
  output io_tlb_0_resp_bits_s1_pteidx_6,
  output io_tlb_0_resp_bits_s1_pteidx_7,
  output io_tlb_0_resp_bits_s1_pf,
  output io_tlb_0_resp_bits_s1_af,
  output [37:0] io_tlb_0_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_0_resp_bits_s2_entry_vmid,
  output io_tlb_0_resp_bits_s2_entry_n,
  output [1:0] io_tlb_0_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_0_resp_bits_s2_entry_ppn,
  output io_tlb_0_resp_bits_s2_entry_perm_d,
  output io_tlb_0_resp_bits_s2_entry_perm_a,
  output io_tlb_0_resp_bits_s2_entry_perm_g,
  output io_tlb_0_resp_bits_s2_entry_perm_u,
  output io_tlb_0_resp_bits_s2_entry_perm_x,
  output io_tlb_0_resp_bits_s2_entry_perm_w,
  output io_tlb_0_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s2_entry_level,
  output io_tlb_0_resp_bits_s2_gpf,
  output io_tlb_0_resp_bits_s2_gaf,
  output io_tlb_1_req_0_ready,
  input io_tlb_1_req_0_valid,
  input [37:0] io_tlb_1_req_0_bits_vpn,
  input [1:0] io_tlb_1_req_0_bits_s2xlate,
  output io_tlb_1_resp_valid,
  output [1:0] io_tlb_1_resp_bits_s2xlate,
  output [34:0] io_tlb_1_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_1_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_1_resp_bits_s1_entry_vmid,
  output io_tlb_1_resp_bits_s1_entry_n,
  output [1:0] io_tlb_1_resp_bits_s1_entry_pbmt,
  output io_tlb_1_resp_bits_s1_entry_perm_d,
  output io_tlb_1_resp_bits_s1_entry_perm_a,
  output io_tlb_1_resp_bits_s1_entry_perm_g,
  output io_tlb_1_resp_bits_s1_entry_perm_u,
  output io_tlb_1_resp_bits_s1_entry_perm_x,
  output io_tlb_1_resp_bits_s1_entry_perm_w,
  output io_tlb_1_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s1_entry_level,
  output io_tlb_1_resp_bits_s1_entry_v,
  output [40:0] io_tlb_1_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_1_resp_bits_s1_addr_low,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_7,
  output io_tlb_1_resp_bits_s1_valididx_0,
  output io_tlb_1_resp_bits_s1_valididx_1,
  output io_tlb_1_resp_bits_s1_valididx_2,
  output io_tlb_1_resp_bits_s1_valididx_3,
  output io_tlb_1_resp_bits_s1_valididx_4,
  output io_tlb_1_resp_bits_s1_valididx_5,
  output io_tlb_1_resp_bits_s1_valididx_6,
  output io_tlb_1_resp_bits_s1_valididx_7,
  output io_tlb_1_resp_bits_s1_pteidx_0,
  output io_tlb_1_resp_bits_s1_pteidx_1,
  output io_tlb_1_resp_bits_s1_pteidx_2,
  output io_tlb_1_resp_bits_s1_pteidx_3,
  output io_tlb_1_resp_bits_s1_pteidx_4,
  output io_tlb_1_resp_bits_s1_pteidx_5,
  output io_tlb_1_resp_bits_s1_pteidx_6,
  output io_tlb_1_resp_bits_s1_pteidx_7,
  output io_tlb_1_resp_bits_s1_pf,
  output io_tlb_1_resp_bits_s1_af,
  output [37:0] io_tlb_1_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_1_resp_bits_s2_entry_vmid,
  output io_tlb_1_resp_bits_s2_entry_n,
  output [1:0] io_tlb_1_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_1_resp_bits_s2_entry_ppn,
  output io_tlb_1_resp_bits_s2_entry_perm_d,
  output io_tlb_1_resp_bits_s2_entry_perm_a,
  output io_tlb_1_resp_bits_s2_entry_perm_g,
  output io_tlb_1_resp_bits_s2_entry_perm_u,
  output io_tlb_1_resp_bits_s2_entry_perm_x,
  output io_tlb_1_resp_bits_s2_entry_perm_w,
  output io_tlb_1_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s2_entry_level,
  output io_tlb_1_resp_bits_s2_gpf,
  output io_tlb_1_resp_bits_s2_gaf,
  input io_sfence_valid,
  input io_sfence_bits_rs1,
  input io_sfence_bits_rs2,
  input [49:0] io_sfence_bits_addr,
  input [15:0] io_sfence_bits_id,
  input io_sfence_bits_hv,
  input io_sfence_bits_hg,
  input io_wfi_wfiReq,
  output io_wfi_wfiSafe,
  input [3:0] io_csr_tlb_satp_mode,
  input [15:0] io_csr_tlb_satp_asid,
  input [43:0] io_csr_tlb_satp_ppn,
  input io_csr_tlb_satp_changed,
  input [3:0] io_csr_tlb_vsatp_mode,
  input [15:0] io_csr_tlb_vsatp_asid,
  input [43:0] io_csr_tlb_vsatp_ppn,
  input io_csr_tlb_vsatp_changed,
  input [3:0] io_csr_tlb_hgatp_mode,
  input [15:0] io_csr_tlb_hgatp_vmid,
  input [43:0] io_csr_tlb_hgatp_ppn,
  input io_csr_tlb_hgatp_changed,
  input io_csr_tlb_mbmc_BME,
  input io_csr_tlb_mbmc_CMODE,
  input io_csr_tlb_mbmc_BCLEAR,
  input [57:0] io_csr_tlb_mbmc_BMA,
  input io_csr_tlb_priv_virt,
  input io_csr_tlb_priv_virt_changed,
  input io_csr_tlb_priv_debug,
  input io_csr_tlb_mPBMTE,
  input io_csr_tlb_hPBMTE,
  input io_csr_distribute_csr_w_valid,
  input [11:0] io_csr_distribute_csr_w_bits_addr,
  input [63:0] io_csr_distribute_csr_w_bits_data,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  input [5:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_writeen,
  input [1:0] boreChildrenBd_bore_be,
  input [5:0] boreChildrenBd_bore_addr,
  input [89:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [5:0] boreChildrenBd_bore_addr_rd,
  output [89:0] boreChildrenBd_bore_outdata,
  input [5:0] boreChildrenBd_bore_1_array,
  input boreChildrenBd_bore_1_all,
  input boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_writeen,
  input boreChildrenBd_bore_1_be,
  input [2:0] boreChildrenBd_bore_1_addr,
  input [130:0] boreChildrenBd_bore_1_indata,
  input boreChildrenBd_bore_1_readen,
  input [2:0] boreChildrenBd_bore_1_addr_rd,
  output [130:0] boreChildrenBd_bore_1_outdata,
  input [6:0] boreChildrenBd_bore_2_array,
  input boreChildrenBd_bore_2_all,
  input boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_writeen,
  input [1:0] boreChildrenBd_bore_2_be,
  input [6:0] boreChildrenBd_bore_2_addr,
  input [113:0] boreChildrenBd_bore_2_indata,
  input boreChildrenBd_bore_2_readen,
  input [6:0] boreChildrenBd_bore_2_addr_rd,
  output [113:0] boreChildrenBd_bore_2_outdata,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen,
  input sigFromSrams_bore_2_ram_hold,
  input sigFromSrams_bore_2_ram_bypass,
  input sigFromSrams_bore_2_ram_bp_clken,
  input sigFromSrams_bore_2_ram_aux_clk,
  input sigFromSrams_bore_2_ram_aux_ckbp,
  input sigFromSrams_bore_2_ram_mcp_hold,
  input sigFromSrams_bore_2_cgen,
  input sigFromSrams_bore_3_ram_hold,
  input sigFromSrams_bore_3_ram_bypass,
  input sigFromSrams_bore_3_ram_bp_clken,
  input sigFromSrams_bore_3_ram_aux_clk,
  input sigFromSrams_bore_3_ram_aux_ckbp,
  input sigFromSrams_bore_3_ram_mcp_hold,
  input sigFromSrams_bore_3_cgen,
  input sigFromSrams_bore_4_ram_hold,
  input sigFromSrams_bore_4_ram_bypass,
  input sigFromSrams_bore_4_ram_bp_clken,
  input sigFromSrams_bore_4_ram_aux_clk,
  input sigFromSrams_bore_4_ram_aux_ckbp,
  input sigFromSrams_bore_4_ram_mcp_hold,
  input sigFromSrams_bore_4_cgen,
  input sigFromSrams_bore_5_ram_hold,
  input sigFromSrams_bore_5_ram_bypass,
  input sigFromSrams_bore_5_ram_bp_clken,
  input sigFromSrams_bore_5_ram_aux_clk,
  input sigFromSrams_bore_5_ram_aux_ckbp,
  input sigFromSrams_bore_5_ram_mcp_hold,
  input sigFromSrams_bore_5_cgen,
  input sigFromSrams_bore_6_ram_hold,
  input sigFromSrams_bore_6_ram_bypass,
  input sigFromSrams_bore_6_ram_bp_clken,
  input sigFromSrams_bore_6_ram_aux_clk,
  input sigFromSrams_bore_6_ram_aux_ckbp,
  input sigFromSrams_bore_6_ram_mcp_hold,
  input sigFromSrams_bore_6_cgen,
  input sigFromSrams_bore_7_ram_hold,
  input sigFromSrams_bore_7_ram_bypass,
  input sigFromSrams_bore_7_ram_bp_clken,
  input sigFromSrams_bore_7_ram_aux_clk,
  input sigFromSrams_bore_7_ram_aux_ckbp,
  input sigFromSrams_bore_7_ram_mcp_hold,
  input sigFromSrams_bore_7_cgen,
  input sigFromSrams_bore_8_ram_hold,
  input sigFromSrams_bore_8_ram_bypass,
  input sigFromSrams_bore_8_ram_bp_clken,
  input sigFromSrams_bore_8_ram_aux_clk,
  input sigFromSrams_bore_8_ram_aux_ckbp,
  input sigFromSrams_bore_8_ram_mcp_hold,
  input sigFromSrams_bore_8_cgen,
  input sigFromSrams_bore_9_ram_hold,
  input sigFromSrams_bore_9_ram_bypass,
  input sigFromSrams_bore_9_ram_bp_clken,
  input sigFromSrams_bore_9_ram_aux_clk,
  input sigFromSrams_bore_9_ram_aux_ckbp,
  input sigFromSrams_bore_9_ram_mcp_hold,
  input sigFromSrams_bore_9_cgen,
  input sigFromSrams_bore_10_ram_hold,
  input sigFromSrams_bore_10_ram_bypass,
  input sigFromSrams_bore_10_ram_bp_clken,
  input sigFromSrams_bore_10_ram_aux_clk,
  input sigFromSrams_bore_10_ram_aux_ckbp,
  input sigFromSrams_bore_10_ram_mcp_hold,
  input sigFromSrams_bore_10_cgen,
  input sigFromSrams_bore_11_ram_hold,
  input sigFromSrams_bore_11_ram_bypass,
  input sigFromSrams_bore_11_ram_bp_clken,
  input sigFromSrams_bore_11_ram_aux_clk,
  input sigFromSrams_bore_11_ram_aux_ckbp,
  input sigFromSrams_bore_11_ram_mcp_hold,
  input sigFromSrams_bore_11_cgen,
  input sigFromSrams_bore_12_ram_hold,
  input sigFromSrams_bore_12_ram_bypass,
  input sigFromSrams_bore_12_ram_bp_clken,
  input sigFromSrams_bore_12_ram_aux_clk,
  input sigFromSrams_bore_12_ram_aux_ckbp,
  input sigFromSrams_bore_12_ram_mcp_hold,
  input sigFromSrams_bore_12_cgen,
  input sigFromSrams_bore_13_ram_hold,
  input sigFromSrams_bore_13_ram_bypass,
  input sigFromSrams_bore_13_ram_bp_clken,
  input sigFromSrams_bore_13_ram_aux_clk,
  input sigFromSrams_bore_13_ram_aux_ckbp,
  input sigFromSrams_bore_13_ram_mcp_hold,
  input sigFromSrams_bore_13_cgen,
  input sigFromSrams_bore_14_ram_hold,
  input sigFromSrams_bore_14_ram_bypass,
  input sigFromSrams_bore_14_ram_bp_clken,
  input sigFromSrams_bore_14_ram_aux_clk,
  input sigFromSrams_bore_14_ram_aux_ckbp,
  input sigFromSrams_bore_14_ram_mcp_hold,
  input sigFromSrams_bore_14_cgen,
  input sigFromSrams_bore_15_ram_hold,
  input sigFromSrams_bore_15_ram_bypass,
  input sigFromSrams_bore_15_ram_bp_clken,
  input sigFromSrams_bore_15_ram_aux_clk,
  input sigFromSrams_bore_15_ram_aux_ckbp,
  input sigFromSrams_bore_15_ram_mcp_hold,
  input sigFromSrams_bore_15_cgen,
  input sigFromSrams_bore_16_ram_hold,
  input sigFromSrams_bore_16_ram_bypass,
  input sigFromSrams_bore_16_ram_bp_clken,
  input sigFromSrams_bore_16_ram_aux_clk,
  input sigFromSrams_bore_16_ram_aux_ckbp,
  input sigFromSrams_bore_16_ram_mcp_hold,
  input sigFromSrams_bore_16_cgen,
  input sigFromSrams_bore_17_ram_hold,
  input sigFromSrams_bore_17_ram_bypass,
  input sigFromSrams_bore_17_ram_bp_clken,
  input sigFromSrams_bore_17_ram_aux_clk,
  input sigFromSrams_bore_17_ram_aux_ckbp,
  input sigFromSrams_bore_17_ram_mcp_hold,
  input sigFromSrams_bore_17_cgen,
  input sigFromSrams_bore_18_ram_hold,
  input sigFromSrams_bore_18_ram_bypass,
  input sigFromSrams_bore_18_ram_bp_clken,
  input sigFromSrams_bore_18_ram_aux_clk,
  input sigFromSrams_bore_18_ram_aux_ckbp,
  input sigFromSrams_bore_18_ram_mcp_hold,
  input sigFromSrams_bore_18_cgen,
  input sigFromSrams_bore_19_ram_hold,
  input sigFromSrams_bore_19_ram_bypass,
  input sigFromSrams_bore_19_ram_bp_clken,
  input sigFromSrams_bore_19_ram_aux_clk,
  input sigFromSrams_bore_19_ram_aux_ckbp,
  input sigFromSrams_bore_19_ram_mcp_hold,
  input sigFromSrams_bore_19_cgen,
  input sigFromSrams_bore_20_ram_hold,
  input sigFromSrams_bore_20_ram_bypass,
  input sigFromSrams_bore_20_ram_bp_clken,
  input sigFromSrams_bore_20_ram_aux_clk,
  input sigFromSrams_bore_20_ram_aux_ckbp,
  input sigFromSrams_bore_20_ram_mcp_hold,
  input sigFromSrams_bore_20_cgen,
  input cg_bore_cgen,
  input cg_bore_1_cgen,
  output [600:0] gatewayIn_packed_43_bore,
  output [968:0] gatewayIn_packed_44_bore,
  output [968:0] gatewayIn_packed_45_bore
);

  xs_L2TLB_core u_core (
    .clock                                   (clock),
    .reset                                   (reset),
    .auto_out_a_ready                        (auto_out_a_ready),
    .auto_out_a_valid                        (auto_out_a_valid),
    .auto_out_a_bits_source                  (auto_out_a_bits_source),
    .auto_out_a_bits_address                 (auto_out_a_bits_address),
    .auto_out_d_valid                        (auto_out_d_valid),
    .auto_out_d_bits_opcode                  (auto_out_d_bits_opcode),
    .auto_out_d_bits_size                    (auto_out_d_bits_size),
    .auto_out_d_bits_source                  (auto_out_d_bits_source),
    .auto_out_d_bits_data                    (auto_out_d_bits_data),
    .io_hartId                               (io_hartId),
    .io_tlb_0_req_0_ready                    (io_tlb_0_req_0_ready),
    .io_tlb_0_req_0_valid                    (io_tlb_0_req_0_valid),
    .io_tlb_0_req_0_bits_vpn                 (io_tlb_0_req_0_bits_vpn),
    .io_tlb_0_req_0_bits_s2xlate             (io_tlb_0_req_0_bits_s2xlate),
    .io_tlb_0_resp_ready                     (io_tlb_0_resp_ready),
    .io_tlb_0_resp_valid                     (io_tlb_0_resp_valid),
    .io_tlb_0_resp_bits_s2xlate              (io_tlb_0_resp_bits_s2xlate),
    .io_tlb_0_resp_bits_s1_entry_tag         (io_tlb_0_resp_bits_s1_entry_tag),
    .io_tlb_0_resp_bits_s1_entry_asid        (io_tlb_0_resp_bits_s1_entry_asid),
    .io_tlb_0_resp_bits_s1_entry_vmid        (io_tlb_0_resp_bits_s1_entry_vmid),
    .io_tlb_0_resp_bits_s1_entry_n           (io_tlb_0_resp_bits_s1_entry_n),
    .io_tlb_0_resp_bits_s1_entry_pbmt        (io_tlb_0_resp_bits_s1_entry_pbmt),
    .io_tlb_0_resp_bits_s1_entry_perm_d      (io_tlb_0_resp_bits_s1_entry_perm_d),
    .io_tlb_0_resp_bits_s1_entry_perm_a      (io_tlb_0_resp_bits_s1_entry_perm_a),
    .io_tlb_0_resp_bits_s1_entry_perm_g      (io_tlb_0_resp_bits_s1_entry_perm_g),
    .io_tlb_0_resp_bits_s1_entry_perm_u      (io_tlb_0_resp_bits_s1_entry_perm_u),
    .io_tlb_0_resp_bits_s1_entry_perm_x      (io_tlb_0_resp_bits_s1_entry_perm_x),
    .io_tlb_0_resp_bits_s1_entry_perm_w      (io_tlb_0_resp_bits_s1_entry_perm_w),
    .io_tlb_0_resp_bits_s1_entry_perm_r      (io_tlb_0_resp_bits_s1_entry_perm_r),
    .io_tlb_0_resp_bits_s1_entry_level       (io_tlb_0_resp_bits_s1_entry_level),
    .io_tlb_0_resp_bits_s1_entry_v           (io_tlb_0_resp_bits_s1_entry_v),
    .io_tlb_0_resp_bits_s1_entry_ppn         (io_tlb_0_resp_bits_s1_entry_ppn),
    .io_tlb_0_resp_bits_s1_addr_low          (io_tlb_0_resp_bits_s1_addr_low),
    .io_tlb_0_resp_bits_s1_ppn_low_0         (io_tlb_0_resp_bits_s1_ppn_low_0),
    .io_tlb_0_resp_bits_s1_ppn_low_1         (io_tlb_0_resp_bits_s1_ppn_low_1),
    .io_tlb_0_resp_bits_s1_ppn_low_2         (io_tlb_0_resp_bits_s1_ppn_low_2),
    .io_tlb_0_resp_bits_s1_ppn_low_3         (io_tlb_0_resp_bits_s1_ppn_low_3),
    .io_tlb_0_resp_bits_s1_ppn_low_4         (io_tlb_0_resp_bits_s1_ppn_low_4),
    .io_tlb_0_resp_bits_s1_ppn_low_5         (io_tlb_0_resp_bits_s1_ppn_low_5),
    .io_tlb_0_resp_bits_s1_ppn_low_6         (io_tlb_0_resp_bits_s1_ppn_low_6),
    .io_tlb_0_resp_bits_s1_ppn_low_7         (io_tlb_0_resp_bits_s1_ppn_low_7),
    .io_tlb_0_resp_bits_s1_valididx_0        (io_tlb_0_resp_bits_s1_valididx_0),
    .io_tlb_0_resp_bits_s1_valididx_1        (io_tlb_0_resp_bits_s1_valididx_1),
    .io_tlb_0_resp_bits_s1_valididx_2        (io_tlb_0_resp_bits_s1_valididx_2),
    .io_tlb_0_resp_bits_s1_valididx_3        (io_tlb_0_resp_bits_s1_valididx_3),
    .io_tlb_0_resp_bits_s1_valididx_4        (io_tlb_0_resp_bits_s1_valididx_4),
    .io_tlb_0_resp_bits_s1_valididx_5        (io_tlb_0_resp_bits_s1_valididx_5),
    .io_tlb_0_resp_bits_s1_valididx_6        (io_tlb_0_resp_bits_s1_valididx_6),
    .io_tlb_0_resp_bits_s1_valididx_7        (io_tlb_0_resp_bits_s1_valididx_7),
    .io_tlb_0_resp_bits_s1_pteidx_0          (io_tlb_0_resp_bits_s1_pteidx_0),
    .io_tlb_0_resp_bits_s1_pteidx_1          (io_tlb_0_resp_bits_s1_pteidx_1),
    .io_tlb_0_resp_bits_s1_pteidx_2          (io_tlb_0_resp_bits_s1_pteidx_2),
    .io_tlb_0_resp_bits_s1_pteidx_3          (io_tlb_0_resp_bits_s1_pteidx_3),
    .io_tlb_0_resp_bits_s1_pteidx_4          (io_tlb_0_resp_bits_s1_pteidx_4),
    .io_tlb_0_resp_bits_s1_pteidx_5          (io_tlb_0_resp_bits_s1_pteidx_5),
    .io_tlb_0_resp_bits_s1_pteidx_6          (io_tlb_0_resp_bits_s1_pteidx_6),
    .io_tlb_0_resp_bits_s1_pteidx_7          (io_tlb_0_resp_bits_s1_pteidx_7),
    .io_tlb_0_resp_bits_s1_pf                (io_tlb_0_resp_bits_s1_pf),
    .io_tlb_0_resp_bits_s1_af                (io_tlb_0_resp_bits_s1_af),
    .io_tlb_0_resp_bits_s2_entry_tag         (io_tlb_0_resp_bits_s2_entry_tag),
    .io_tlb_0_resp_bits_s2_entry_vmid        (io_tlb_0_resp_bits_s2_entry_vmid),
    .io_tlb_0_resp_bits_s2_entry_n           (io_tlb_0_resp_bits_s2_entry_n),
    .io_tlb_0_resp_bits_s2_entry_pbmt        (io_tlb_0_resp_bits_s2_entry_pbmt),
    .io_tlb_0_resp_bits_s2_entry_ppn         (io_tlb_0_resp_bits_s2_entry_ppn),
    .io_tlb_0_resp_bits_s2_entry_perm_d      (io_tlb_0_resp_bits_s2_entry_perm_d),
    .io_tlb_0_resp_bits_s2_entry_perm_a      (io_tlb_0_resp_bits_s2_entry_perm_a),
    .io_tlb_0_resp_bits_s2_entry_perm_g      (io_tlb_0_resp_bits_s2_entry_perm_g),
    .io_tlb_0_resp_bits_s2_entry_perm_u      (io_tlb_0_resp_bits_s2_entry_perm_u),
    .io_tlb_0_resp_bits_s2_entry_perm_x      (io_tlb_0_resp_bits_s2_entry_perm_x),
    .io_tlb_0_resp_bits_s2_entry_perm_w      (io_tlb_0_resp_bits_s2_entry_perm_w),
    .io_tlb_0_resp_bits_s2_entry_perm_r      (io_tlb_0_resp_bits_s2_entry_perm_r),
    .io_tlb_0_resp_bits_s2_entry_level       (io_tlb_0_resp_bits_s2_entry_level),
    .io_tlb_0_resp_bits_s2_gpf               (io_tlb_0_resp_bits_s2_gpf),
    .io_tlb_0_resp_bits_s2_gaf               (io_tlb_0_resp_bits_s2_gaf),
    .io_tlb_1_req_0_ready                    (io_tlb_1_req_0_ready),
    .io_tlb_1_req_0_valid                    (io_tlb_1_req_0_valid),
    .io_tlb_1_req_0_bits_vpn                 (io_tlb_1_req_0_bits_vpn),
    .io_tlb_1_req_0_bits_s2xlate             (io_tlb_1_req_0_bits_s2xlate),
    .io_tlb_1_resp_valid                     (io_tlb_1_resp_valid),
    .io_tlb_1_resp_bits_s2xlate              (io_tlb_1_resp_bits_s2xlate),
    .io_tlb_1_resp_bits_s1_entry_tag         (io_tlb_1_resp_bits_s1_entry_tag),
    .io_tlb_1_resp_bits_s1_entry_asid        (io_tlb_1_resp_bits_s1_entry_asid),
    .io_tlb_1_resp_bits_s1_entry_vmid        (io_tlb_1_resp_bits_s1_entry_vmid),
    .io_tlb_1_resp_bits_s1_entry_n           (io_tlb_1_resp_bits_s1_entry_n),
    .io_tlb_1_resp_bits_s1_entry_pbmt        (io_tlb_1_resp_bits_s1_entry_pbmt),
    .io_tlb_1_resp_bits_s1_entry_perm_d      (io_tlb_1_resp_bits_s1_entry_perm_d),
    .io_tlb_1_resp_bits_s1_entry_perm_a      (io_tlb_1_resp_bits_s1_entry_perm_a),
    .io_tlb_1_resp_bits_s1_entry_perm_g      (io_tlb_1_resp_bits_s1_entry_perm_g),
    .io_tlb_1_resp_bits_s1_entry_perm_u      (io_tlb_1_resp_bits_s1_entry_perm_u),
    .io_tlb_1_resp_bits_s1_entry_perm_x      (io_tlb_1_resp_bits_s1_entry_perm_x),
    .io_tlb_1_resp_bits_s1_entry_perm_w      (io_tlb_1_resp_bits_s1_entry_perm_w),
    .io_tlb_1_resp_bits_s1_entry_perm_r      (io_tlb_1_resp_bits_s1_entry_perm_r),
    .io_tlb_1_resp_bits_s1_entry_level       (io_tlb_1_resp_bits_s1_entry_level),
    .io_tlb_1_resp_bits_s1_entry_v           (io_tlb_1_resp_bits_s1_entry_v),
    .io_tlb_1_resp_bits_s1_entry_ppn         (io_tlb_1_resp_bits_s1_entry_ppn),
    .io_tlb_1_resp_bits_s1_addr_low          (io_tlb_1_resp_bits_s1_addr_low),
    .io_tlb_1_resp_bits_s1_ppn_low_0         (io_tlb_1_resp_bits_s1_ppn_low_0),
    .io_tlb_1_resp_bits_s1_ppn_low_1         (io_tlb_1_resp_bits_s1_ppn_low_1),
    .io_tlb_1_resp_bits_s1_ppn_low_2         (io_tlb_1_resp_bits_s1_ppn_low_2),
    .io_tlb_1_resp_bits_s1_ppn_low_3         (io_tlb_1_resp_bits_s1_ppn_low_3),
    .io_tlb_1_resp_bits_s1_ppn_low_4         (io_tlb_1_resp_bits_s1_ppn_low_4),
    .io_tlb_1_resp_bits_s1_ppn_low_5         (io_tlb_1_resp_bits_s1_ppn_low_5),
    .io_tlb_1_resp_bits_s1_ppn_low_6         (io_tlb_1_resp_bits_s1_ppn_low_6),
    .io_tlb_1_resp_bits_s1_ppn_low_7         (io_tlb_1_resp_bits_s1_ppn_low_7),
    .io_tlb_1_resp_bits_s1_valididx_0        (io_tlb_1_resp_bits_s1_valididx_0),
    .io_tlb_1_resp_bits_s1_valididx_1        (io_tlb_1_resp_bits_s1_valididx_1),
    .io_tlb_1_resp_bits_s1_valididx_2        (io_tlb_1_resp_bits_s1_valididx_2),
    .io_tlb_1_resp_bits_s1_valididx_3        (io_tlb_1_resp_bits_s1_valididx_3),
    .io_tlb_1_resp_bits_s1_valididx_4        (io_tlb_1_resp_bits_s1_valididx_4),
    .io_tlb_1_resp_bits_s1_valididx_5        (io_tlb_1_resp_bits_s1_valididx_5),
    .io_tlb_1_resp_bits_s1_valididx_6        (io_tlb_1_resp_bits_s1_valididx_6),
    .io_tlb_1_resp_bits_s1_valididx_7        (io_tlb_1_resp_bits_s1_valididx_7),
    .io_tlb_1_resp_bits_s1_pteidx_0          (io_tlb_1_resp_bits_s1_pteidx_0),
    .io_tlb_1_resp_bits_s1_pteidx_1          (io_tlb_1_resp_bits_s1_pteidx_1),
    .io_tlb_1_resp_bits_s1_pteidx_2          (io_tlb_1_resp_bits_s1_pteidx_2),
    .io_tlb_1_resp_bits_s1_pteidx_3          (io_tlb_1_resp_bits_s1_pteidx_3),
    .io_tlb_1_resp_bits_s1_pteidx_4          (io_tlb_1_resp_bits_s1_pteidx_4),
    .io_tlb_1_resp_bits_s1_pteidx_5          (io_tlb_1_resp_bits_s1_pteidx_5),
    .io_tlb_1_resp_bits_s1_pteidx_6          (io_tlb_1_resp_bits_s1_pteidx_6),
    .io_tlb_1_resp_bits_s1_pteidx_7          (io_tlb_1_resp_bits_s1_pteidx_7),
    .io_tlb_1_resp_bits_s1_pf                (io_tlb_1_resp_bits_s1_pf),
    .io_tlb_1_resp_bits_s1_af                (io_tlb_1_resp_bits_s1_af),
    .io_tlb_1_resp_bits_s2_entry_tag         (io_tlb_1_resp_bits_s2_entry_tag),
    .io_tlb_1_resp_bits_s2_entry_vmid        (io_tlb_1_resp_bits_s2_entry_vmid),
    .io_tlb_1_resp_bits_s2_entry_n           (io_tlb_1_resp_bits_s2_entry_n),
    .io_tlb_1_resp_bits_s2_entry_pbmt        (io_tlb_1_resp_bits_s2_entry_pbmt),
    .io_tlb_1_resp_bits_s2_entry_ppn         (io_tlb_1_resp_bits_s2_entry_ppn),
    .io_tlb_1_resp_bits_s2_entry_perm_d      (io_tlb_1_resp_bits_s2_entry_perm_d),
    .io_tlb_1_resp_bits_s2_entry_perm_a      (io_tlb_1_resp_bits_s2_entry_perm_a),
    .io_tlb_1_resp_bits_s2_entry_perm_g      (io_tlb_1_resp_bits_s2_entry_perm_g),
    .io_tlb_1_resp_bits_s2_entry_perm_u      (io_tlb_1_resp_bits_s2_entry_perm_u),
    .io_tlb_1_resp_bits_s2_entry_perm_x      (io_tlb_1_resp_bits_s2_entry_perm_x),
    .io_tlb_1_resp_bits_s2_entry_perm_w      (io_tlb_1_resp_bits_s2_entry_perm_w),
    .io_tlb_1_resp_bits_s2_entry_perm_r      (io_tlb_1_resp_bits_s2_entry_perm_r),
    .io_tlb_1_resp_bits_s2_entry_level       (io_tlb_1_resp_bits_s2_entry_level),
    .io_tlb_1_resp_bits_s2_gpf               (io_tlb_1_resp_bits_s2_gpf),
    .io_tlb_1_resp_bits_s2_gaf               (io_tlb_1_resp_bits_s2_gaf),
    .io_sfence_valid                         (io_sfence_valid),
    .io_sfence_bits_rs1                      (io_sfence_bits_rs1),
    .io_sfence_bits_rs2                      (io_sfence_bits_rs2),
    .io_sfence_bits_addr                     (io_sfence_bits_addr),
    .io_sfence_bits_id                       (io_sfence_bits_id),
    .io_sfence_bits_hv                       (io_sfence_bits_hv),
    .io_sfence_bits_hg                       (io_sfence_bits_hg),
    .io_wfi_wfiReq                           (io_wfi_wfiReq),
    .io_wfi_wfiSafe                          (io_wfi_wfiSafe),
    .io_csr_tlb_satp_mode                    (io_csr_tlb_satp_mode),
    .io_csr_tlb_satp_asid                    (io_csr_tlb_satp_asid),
    .io_csr_tlb_satp_ppn                     (io_csr_tlb_satp_ppn),
    .io_csr_tlb_satp_changed                 (io_csr_tlb_satp_changed),
    .io_csr_tlb_vsatp_mode                   (io_csr_tlb_vsatp_mode),
    .io_csr_tlb_vsatp_asid                   (io_csr_tlb_vsatp_asid),
    .io_csr_tlb_vsatp_ppn                    (io_csr_tlb_vsatp_ppn),
    .io_csr_tlb_vsatp_changed                (io_csr_tlb_vsatp_changed),
    .io_csr_tlb_hgatp_mode                   (io_csr_tlb_hgatp_mode),
    .io_csr_tlb_hgatp_vmid                   (io_csr_tlb_hgatp_vmid),
    .io_csr_tlb_hgatp_ppn                    (io_csr_tlb_hgatp_ppn),
    .io_csr_tlb_hgatp_changed                (io_csr_tlb_hgatp_changed),
    .io_csr_tlb_mbmc_BME                     (io_csr_tlb_mbmc_BME),
    .io_csr_tlb_mbmc_CMODE                   (io_csr_tlb_mbmc_CMODE),
    .io_csr_tlb_mbmc_BCLEAR                  (io_csr_tlb_mbmc_BCLEAR),
    .io_csr_tlb_mbmc_BMA                     (io_csr_tlb_mbmc_BMA),
    .io_csr_tlb_priv_virt                    (io_csr_tlb_priv_virt),
    .io_csr_tlb_priv_virt_changed            (io_csr_tlb_priv_virt_changed),
    .io_csr_tlb_priv_debug                   (io_csr_tlb_priv_debug),
    .io_csr_tlb_mPBMTE                       (io_csr_tlb_mPBMTE),
    .io_csr_tlb_hPBMTE                       (io_csr_tlb_hPBMTE),
    .io_csr_distribute_csr_w_valid           (io_csr_distribute_csr_w_valid),
    .io_csr_distribute_csr_w_bits_addr       (io_csr_distribute_csr_w_bits_addr),
    .io_csr_distribute_csr_w_bits_data       (io_csr_distribute_csr_w_bits_data),
    .io_perf_0_value                         (io_perf_0_value),
    .io_perf_1_value                         (io_perf_1_value),
    .io_perf_2_value                         (io_perf_2_value),
    .io_perf_3_value                         (io_perf_3_value),
    .io_perf_4_value                         (io_perf_4_value),
    .io_perf_5_value                         (io_perf_5_value),
    .io_perf_6_value                         (io_perf_6_value),
    .io_perf_7_value                         (io_perf_7_value),
    .io_perf_8_value                         (io_perf_8_value),
    .io_perf_9_value                         (io_perf_9_value),
    .io_perf_10_value                        (io_perf_10_value),
    .io_perf_11_value                        (io_perf_11_value),
    .io_perf_12_value                        (io_perf_12_value),
    .io_perf_13_value                        (io_perf_13_value),
    .io_perf_14_value                        (io_perf_14_value),
    .io_perf_15_value                        (io_perf_15_value),
    .io_perf_16_value                        (io_perf_16_value),
    .io_perf_17_value                        (io_perf_17_value),
    .io_perf_18_value                        (io_perf_18_value),
    .boreChildrenBd_bore_array               (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                 (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                 (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                 (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen             (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                  (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata              (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen              (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd             (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata             (boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array             (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all               (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req               (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack               (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen           (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr              (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata            (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen            (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd           (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata           (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array             (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all               (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req               (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack               (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen           (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be                (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr              (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata            (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen            (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd           (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata           (boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold              (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass            (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken          (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk           (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp          (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold          (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                  (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold            (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass          (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken        (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk         (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp        (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold        (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold            (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass          (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken        (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk         (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp        (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold        (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold            (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass          (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken        (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk         (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp        (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold        (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold            (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass          (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken        (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk         (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp        (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold        (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold            (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass          (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken        (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk         (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp        (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold        (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold            (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass          (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken        (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk         (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp        (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold        (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold            (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass          (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken        (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk         (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp        (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold        (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold            (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass          (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken        (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk         (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp        (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold        (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold            (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass          (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken        (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk         (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp        (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold        (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold           (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass         (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken       (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk        (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp       (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold       (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen               (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold           (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass         (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken       (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk        (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp       (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold       (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen               (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold           (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass         (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken       (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk        (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp       (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold       (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen               (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold           (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass         (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken       (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk        (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp       (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold       (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen               (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold           (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass         (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken       (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk        (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp       (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold       (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen               (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold           (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass         (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken       (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk        (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp       (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold       (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen               (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold           (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass         (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken       (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk        (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp       (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold       (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen               (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold           (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass         (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken       (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk        (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp       (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold       (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen               (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold           (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass         (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken       (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk        (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp       (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold       (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen               (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold           (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass         (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken       (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk        (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp       (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold       (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen               (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold           (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass         (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken       (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk        (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp       (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold       (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen               (sigFromSrams_bore_20_cgen),
    .cg_bore_cgen                            (cg_bore_cgen),
    .cg_bore_1_cgen                          (cg_bore_1_cgen),
    .gatewayIn_packed_43_bore                (gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore                (gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore                (gatewayIn_packed_45_bore)
  );
  // END GENERATED

endmodule
