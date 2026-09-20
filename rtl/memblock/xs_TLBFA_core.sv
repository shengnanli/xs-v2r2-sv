// =============================================================================
// xs_TLBFA_core —— L1 TLB 全相联存储阵列（TLBFA 家族的参数化可读核）
//
// 位置：每个 L1 TLB（itlb / dtlb-load / dtlb-store / dtlb-prefetch）的
//       TlbStorageWrapper 内各例化一个。上层管 PTW 握手与替换算法（Tree-PLRU），
//       本层是"页表项真正住的地方"，只做三件事：
//         · 并行查   ——  PORTS 路请求各自与 48 条 entry 全比较（全相联 CAM）
//         · refill 写 —— PTW 回填一条 entry（way 由上层替换器给）
//         · 失效     ——  sfence.vma / hfence.vvma / hfence.gvma 清 valid 位
//
// 时序（读代码前必须知道）：查询是"请求拍比较、下一拍出结果"。
//       命中向量 hit_vec 在请求拍组合算出 → 打一拍成 hit_vec_q → 响应拍用它
//       Mux1H 选出 ppn/perm/…。entry 内容本身**不打拍**，所以响应拍读到的是
//       响应拍当时的 entries[]（这是 golden 的真实行为，不是笔误，见 §读路径）。
//
// 四个必须先懂的结构概念：
//   1) sector entry：一条 entry 覆盖 8 个连续 4KB 页（tlbcontiguous=8）。tag 只存
//      vpn[37:3]；低 3 位用 valididx（这 8 个页里哪几个真有 PTE）与 pteidx
//      （两级翻译时 s1 的 PTE 落在哪一格）两个 8 位向量表达。ppn 同理按 sector 存，
//      每页各自的低 3 位放在 ppn_low[8]。
//   2) 两级地址翻译（H 扩展）：一条 entry 同时装 VS-stage(s1) 与 G-stage(s2) 的
//      结果，s2xlate∈{00 无, 01 只 s1, 10 只 s2, 11 两级} 记录它是哪种组合；
//      查询时 s2xlate 必须**完全相等**才算命中（不是"兼容"，是相等）。
//   3) 超页 / NAPOT：level>0 表示 2MB/1GB/512GB 超页，比 tag 时高位比中就算命中；
//      n=1 表示 Svnapot 64KB 页，最低段按 4 位对齐比较。
//   4) 本拍正在 refill 的 way 不参与命中（refill_mask），否则会读到半旧半新的项。
//
// 两条容易想当然、因此**机械核对过**的事实（脚本在 verif/ut/TLBFA/ 下，可复跑）：
//   · 复位域：golden 每个变体只有 48 个 v 位带复位，而且是**异步**
//     （always @(posedge clock or posedge reset)）；entries / hitVecReg / reqVpn /
//     resp_valid / refill 打拍寄存器**一个都不复位**。照抄成全复位是真 bug，
//     而 elaborate 和 lint 都不会报 —— 由 reset_domain_check.py 结构核对。
//   · nDups：TLBFA_1 的 dup1 输出（ppn_1 / perm_1_*）与 dup0 是**逐字同一份方程**
//     （21 对全部展开到寄存器后逐字符相同），所以本核只算一份、由薄文件扇出到两个
//     端口。这是**证明**出来的，不是看了两眼像就假设的 —— 由 dup_equiv_check.py 核对。
//
// 判据是 golden RTL（G1-canonical/golden-rtl/TLBFA*.sv），Chisel
// （XiangShan src/main/scala/xiangshan/cache/mmu/TLBStorage.scala + MMUBundle.scala）
// 只用来解释"为什么"。几处"Chisel 读起来像 A、展开成 B"的地方已就地注明，以 golden 为准：
//   · reqVpn 是**无条件** RegNext，而同一段里的 hitVecReg 是 req.valid 使能的
//     RegEnable —— 两者在 req.valid=0 的拍会错位（见 §读路径）。
//   · resp.bits.* 的 Mux1H 在多命中时是**按位或**，不是优先选择；OHToUInt 同理
//     （见 §读路径的 sel_*）。sector TLB 确实会多命中，Chisel 注释自己写了。
//   · refill 与 sfence 同拍时 entry 照写、v 不置位（两个 always 块，见 §失效）。
//
// 家族四变体（差异全部实测自 golden 端口/寄存器，不是从 Chisel 默认值推的）：
//   模块      父 TLB   PORTS  nDups  KEEP_WPERM  golden 行数
//   TLBFA     itlb       3      1        0         21303
//   TLBFA_1   ldtlb      4      2        1         27196
//   TLBFA_2   sttlb      2      1        1         20067
//   TLBFA_3   pftlb      2      1        1         19972
//   四者 nWays 都是 48（48 组 entry 寄存器逐个数出来的），entry 结构也完全相同，
//   唯一的结构差异就是 KEEP_WPERM（见 §可选字段）。nDups 不进核，理由见变体薄文件。
// =============================================================================
package tlbfa_pkg;

  // ---- KunminghuV2Config 下的页表常量 ----
  // 这些值不是抄 Chisel 默认值，而是从 golden 端口/寄存器位宽反推、再与
  // MMUConst.scala 对账过的：VAddrBits=50 / PAddrBits=48 / GPAddrBits=50 / EnableSv48。
  localparam int VADDR_W    = 50;  // VAddrBits（sfence.bits.addr 宽度）
  localparam int OFF_LEN    = 12;  // 页内偏移位数
  localparam int VPN_W      = 38;  // vpnLen      = VADDR_W - OFF_LEN
  localparam int SECT_W     = 3;   // sectortlbwidth = log2(SECT_N)
  localparam int SECT_N     = 8;   // tlbcontiguous：一条 entry 覆盖 8 个连续 4KB 页
  localparam int SVPN_W     = 35;  // sectorvpnLen = VPN_W - SECT_W（entry.tag 宽度）
  localparam int PPN_W      = 36;  // ppnLen      = PAddrBits - OFF_LEN（响应 ppn 宽度）
  localparam int SPPN_W     = 33;  // sectorppnLen = PPN_W - SECT_W（entry.ppn 宽度）
  localparam int GVPN_W     = 38;  // gvpnLen     = GPAddrBits - OFF_LEN（s2 tag/ppn 宽度）
  localparam int PTE_SPPN_W = 41;  // sectorptePPNLen = ptePPNLen(44) - SECT_W
  localparam int ASID_W     = 16;
  localparam int VMID_W     = 14;  // 比 ASID 窄：和 16 位的 CSR 比较时要零扩展
  localparam int VPNN_W     = 9;   // 一级页表索引位数
  localparam int LEVELS     = 3;   // Level：sv48 有 4 段 vpn，段间 3 个"可超页"边界
  localparam int NAPOT_BITS = 4;   // Svnapot 64KB = 16 页
  localparam int PBMT_W     = 2;
  localparam int NWAYS      = 48;  // 全相联条数（四个变体一致，实测）
  localparam int WAY_W      = 6;   // log2Up(48)

  // s2xlate 编码（MMUConst.scala）
  localparam logic [1:0] NO_S2XLATE = 2'b00;  // 无 H 扩展翻译
  localparam logic [1:0] ONLY_S1    = 2'b01;  // 只做 VS-stage
  localparam logic [1:0] ONLY_S2    = 2'b10;  // 只做 G-stage
  localparam logic [1:0] ALL_STAGE  = 2'b11;  // 两级都做

  // TLB entry 里的 s1 权限位（TlbSectorPermBundle）。
  // pf/af/v 是"这条翻译本身出没出事"的标记，不是 PTE 位：
  //   pf = 触发 page fault、af = access fault、v = s1 PTE 有效（fake PTE 时为 0）。
  // d 不在这里：它是 KEEP_WPERM 管的可选字段，见 §可选字段。
  typedef struct packed {
    logic pf, af, v, a, g, u, x, w, r;
  } tlb_perm_t;

  // G-stage 权限位里"四个变体都保留"的部分。
  // 注意 golden 里 g_perm 没有 v/g/u 三位：v 在 Chisel 里被赋成 DontCare，
  // g/u 则没有任何下游读者，firtool 把三者一起消了。这里照搬 golden 的取舍。
  typedef struct packed {
    logic pf, af, a, x;
  } tlb_gperm_t;

  // 与写权限相关的 4 位：见 §可选字段（itlb 变体里 golden 根本没有这 4×48 个寄存器）。
  typedef struct packed {
    logic perm_d, g_perm_d, g_perm_w, g_perm_r;
  } tlb_wperm_t;

  // 一条 TLB entry（= Chisel TlbSectorEntry 去掉被 firtool 消掉的字段）。
  typedef struct packed {
    logic [SVPN_W-1:0]             tag;       // vpn[37:3]
    logic [ASID_W-1:0]             asid;
    logic [1:0]                    level;     // 0=4KB 1=2MB 2=1GB 3=512GB
    logic [SPPN_W-1:0]             ppn;       // ppn[35:3]
    logic                          n;         // Svnapot 64KB
    logic [PBMT_W-1:0]             pbmt;
    logic [PBMT_W-1:0]             g_pbmt;
    tlb_perm_t                     perm;
    logic [SECT_N-1:0]             valididx;  // 8 个页里哪些有 PTE
    logic [SECT_N-1:0]             pteidx;    // 两级翻译时 s1 PTE 落在哪一格
    logic [SECT_N-1:0][SECT_W-1:0] ppn_low;   // 每页 ppn 的低 3 位
    tlb_gperm_t                    g_perm;
    logic [VMID_W-1:0]             vmid;
    logic [1:0]                    s2xlate;
  } tlb_entry_t;

  // ---- entry 命中判定（Chisel TlbSectorEntry.hit）----
  // 读端口与 sfence 都用它，区别只在几个入参：sfence 走 ignore_asid / has_s2=virt。
  // 全部依赖都从入参进来，不捕获模块级信号（本仓规范：generate-for 内用 function
  // 捕获模块级信号在仿真里会返 X）。
  function automatic logic entry_hit(
      input tlb_entry_t        e,
      input logic [VPN_W-1:0]  vpn,
      input logic [ASID_W-1:0] asid,        // hasS2xlate 时上层已选成 vsatp.asid
      input logic [ASID_W-1:0] vmid,        // CSR 侧 16 位；entry 侧 14 位要零扩展
      input logic              has_s2,
      input logic              only_s2,
      input logic              only_s1,
      input logic              ignore_asid  // sfence rs2=1（"所有 asid"）时置 1
  );
    logic              asid_hit, addr_low_hit, vmid_hit, pteidx_hit, is_super;
    logic [LEVELS:0]   tag_match, level_match;
    begin
      // 只翻 G-stage 时 entry 里的 asid 没有意义，直接放行；否则 asid 相等或该页 global。
      asid_hit = (has_s2 && only_s2) ? 1'b1
               : (ignore_asid        ? 1'b1
                                     : ((e.asid == asid) || e.perm.g));
      // sector 内这一页到底有没有 PTE
      addr_low_hit = e.valididx[vpn[SECT_W-1:0]];
      vmid_hit     = has_s2 ? ({{(ASID_W-VMID_W){1'b0}}, e.vmid} == vmid) : 1'b1;
      is_super     = (e.level != 2'd0);
      // pteidx 只在"两级翻译 + 4KB 非 NAPOT + 不是 only-s1"时才有区分度：
      // 那种情况下一条 entry 的 8 格里只有 pteidx 指的那格装着 s1 的 PTE。
      pteidx_hit   = (has_s2 && !is_super && !only_s1 && !e.n) ? e.pteidx[vpn[SECT_W-1:0]]
                                                               : 1'b1;

      // 最低段：NAPOT 页按 16 页对齐比（低 4 位不比），否则整段比。
      tag_match[0] = e.n ? (e.tag[VPNN_W-SECT_W-1 -: (VPNN_W-NAPOT_BITS)]
                            == vpn[VPNN_W-1 -: (VPNN_W-NAPOT_BITS)])
                         : (e.tag[VPNN_W-SECT_W-1 : 0] == vpn[VPNN_W-1 : SECT_W]);
      // 中间各段：tag 因为去掉了 sector 低位，比 vpn 整体右移 SECT_W。
      for (int i = 1; i < LEVELS; i++)
        tag_match[i] = e.tag[VPNN_W*(i+1)-SECT_W-1 -: VPNN_W] == vpn[VPNN_W*(i+1)-1 -: VPNN_W];
      // 最高段（sv48 的 vpn[3]，11 位）：任何页大小都必须比中。
      tag_match[LEVELS] = e.tag[SVPN_W-1 : VPNN_W*LEVELS-SECT_W]
                          == vpn[VPN_W-1 : VPNN_W*LEVELS];

      // 页越大，越低的段越不用比：level>=i+1 就直接放行第 i 段。
      for (int i = 0; i < LEVELS; i++)
        level_match[i] = tag_match[i] || (e.level >= 2'(i + 1));
      level_match[LEVELS] = tag_match[LEVELS];

      entry_hit = asid_hit && (&level_match) && addr_low_hit && vmid_hit && pteidx_hit;
    end
  endfunction

  // ---- 由 entry + 查询 vpn 拼出物理页号（Chisel TlbSectorEntry.genPPN）----
  // 超页时低段直接取 vpn（页内偏移的一部分），4KB 时取 entry 存的 ppn。
  // saveLevel=false（TlbStorageWrapper 没传），所以这里是纯组合，没有 RegEnable。
  function automatic logic [PPN_W-1:0] entry_gen_ppn(
      input tlb_entry_t e, input logic [VPN_W-1:0] vpn);
    logic [VPNN_W-1:0] seg0;
    begin
      if (e.level >= 2'd1)
        seg0 = vpn[VPNN_W-1:0];                                   // ≥2MB：整段来自 vpn
      else if (!e.n)
        seg0 = {e.ppn[VPNN_W-SECT_W-1:0], e.ppn_low[vpn[SECT_W-1:0]]}; // 4KB：sector + 本页低 3 位
      else
        seg0 = {e.ppn[VPNN_W-SECT_W-1 -: (VPNN_W-NAPOT_BITS)], vpn[NAPOT_BITS-1:0]}; // 64KB NAPOT
      entry_gen_ppn = {e.ppn[SPPN_W-1 : VPNN_W*3-SECT_W],
                       (e.level >= 2'd3) ? vpn[VPNN_W*3-1 -: VPNN_W]
                                         : e.ppn[VPNN_W*3-SECT_W-1 -: VPNN_W],
                       (e.level >= 2'd2) ? vpn[VPNN_W*2-1 -: VPNN_W]
                                         : e.ppn[VPNN_W*2-SECT_W-1 -: VPNN_W],
                       seg0};
    end
  endfunction

endpackage

module xs_TLBFA_core
  import tlbfa_pkg::*;
#(
  // 查询端口数：itlb 3 / ldtlb 4 / sttlb 2 / pftlb 2（实测 golden 端口）
  parameter int PORTS      = 3,
  // 是否保留写权限相关的 4 位（见 §可选字段）。itlb 变体为 0。
  parameter bit KEEP_WPERM = 1'b1
)(
  input  logic                          clock,
  input  logic                          reset,

  // ---- sfence.vma / hfence.vvma / hfence.gvma ----
  input  logic                          sfence_valid,
  input  logic                          sfence_rs1,      // 1 = 不指定地址（全部地址）
  input  logic                          sfence_rs2,      // 1 = 不指定 asid（全部 asid）
  input  logic [VADDR_W-1:0]            sfence_addr,
  input  logic [ASID_W-1:0]             sfence_id,       // asid 或 vmid，看是哪条指令
  input  logic                          sfence_hv,       // hfence.vvma
  input  logic                          sfence_hg,       // hfence.gvma

  // ---- CSR 现场 ----
  input  logic [ASID_W-1:0]             csr_satp_asid,
  input  logic [ASID_W-1:0]             csr_vsatp_asid,
  input  logic [ASID_W-1:0]             csr_hgatp_vmid,
  input  logic                          csr_mbmc_bme,    // bitmap check 使能
  input  logic                          csr_mbmc_cmode,
  input  logic                          csr_priv_virt,   // 当前在 VS/VU 模式

  // ---- 查询请求（req.ready 恒 1，故 golden 里没有 ready 端口）----
  input  logic [PORTS-1:0]              req_valid,
  input  logic [PORTS-1:0][VPN_W-1:0]   req_vpn,
  input  logic [PORTS-1:0][1:0]         req_s2xlate,

  // ---- 查询响应（请求的下一拍）----
  output logic [PORTS-1:0]              resp_hit,
  output logic [PORTS-1:0][PPN_W-1:0]   resp_ppn,
  output logic [PORTS-1:0][PBMT_W-1:0]  resp_pbmt,
  output logic [PORTS-1:0][PBMT_W-1:0]  resp_g_pbmt,
  output logic [PORTS-1:0]              resp_perm_pf,
  output logic [PORTS-1:0]              resp_perm_af,
  output logic [PORTS-1:0]              resp_perm_v,
  output logic [PORTS-1:0]              resp_perm_d,
  output logic [PORTS-1:0]              resp_perm_a,
  output logic [PORTS-1:0]              resp_perm_g,
  output logic [PORTS-1:0]              resp_perm_u,
  output logic [PORTS-1:0]              resp_perm_x,
  output logic [PORTS-1:0]              resp_perm_w,
  output logic [PORTS-1:0]              resp_perm_r,
  output logic [PORTS-1:0]              resp_g_perm_pf,
  output logic [PORTS-1:0]              resp_g_perm_af,
  output logic [PORTS-1:0]              resp_g_perm_d,
  output logic [PORTS-1:0]              resp_g_perm_a,
  output logic [PORTS-1:0]              resp_g_perm_x,
  output logic [PORTS-1:0]              resp_g_perm_w,
  output logic [PORTS-1:0]              resp_g_perm_r,
  output logic [PORTS-1:0][1:0]         resp_s2xlate,

  // ---- refill 写（way 由上层 PLRU 给）----
  input  logic                          w_valid,
  input  logic [WAY_W-1:0]              w_way,
  input  logic [1:0]                    w_s2xlate,
  // VS-stage（s1）回填数据
  input  logic [SVPN_W-1:0]             w_s1_entry_tag,
  input  logic [ASID_W-1:0]             w_s1_entry_asid,
  input  logic [VMID_W-1:0]             w_s1_entry_vmid,
  input  logic                          w_s1_entry_n,
  input  logic [PBMT_W-1:0]             w_s1_entry_pbmt,
  input  logic                          w_s1_entry_perm_d,
  input  logic                          w_s1_entry_perm_a,
  input  logic                          w_s1_entry_perm_g,
  input  logic                          w_s1_entry_perm_u,
  input  logic                          w_s1_entry_perm_x,
  input  logic                          w_s1_entry_perm_w,
  input  logic                          w_s1_entry_perm_r,
  input  logic [1:0]                    w_s1_entry_level,
  input  logic                          w_s1_entry_v,
  input  logic [PTE_SPPN_W-1:0]         w_s1_entry_ppn,
  input  logic [SECT_N-1:0][SECT_W-1:0] w_s1_ppn_low,
  input  logic [SECT_N-1:0]             w_s1_valididx,
  input  logic [SECT_N-1:0]             w_s1_pteidx,
  input  logic                          w_s1_pf,
  input  logic                          w_s1_af,
  // G-stage（s2）回填数据
  input  logic [GVPN_W-1:0]             w_s2_entry_tag,
  input  logic [VMID_W-1:0]             w_s2_entry_vmid,
  input  logic                          w_s2_entry_n,
  input  logic [PBMT_W-1:0]             w_s2_entry_pbmt,
  input  logic [GVPN_W-1:0]             w_s2_entry_ppn,
  input  logic                          w_s2_entry_perm_d,
  input  logic                          w_s2_entry_perm_a,
  input  logic                          w_s2_entry_perm_g,
  input  logic                          w_s2_entry_perm_u,
  input  logic                          w_s2_entry_perm_x,
  input  logic                          w_s2_entry_perm_w,
  input  logic                          w_s2_entry_perm_r,
  input  logic [1:0]                    w_s2_entry_level,
  input  logic                          w_s2_gpf,
  input  logic                          w_s2_gaf,

  // ---- 给上层替换器的访问反馈 ----
  output logic [PORTS-1:0]              access_touch_valid,
  output logic [PORTS-1:0][WAY_W-1:0]   access_touch_way
);

  // ===========================================================================
  // 存储
  // ===========================================================================
  logic [NWAYS-1:0] v;          // ★唯一带复位的寄存器，且是**异步**复位（照搬 golden）★
  tlb_entry_t       entries [NWAYS];   // 无复位：靠 v 保证没写过的 entry 读不出来

  // --- §可选字段 ---------------------------------------------------------
  // perm.d / g_perm.{d,w,r} 这 4 位只有"会写内存"的 TLB 才用得上。itlb（TLBFA）
  // 的父级只取指，从不读这 4 位，于是 firtool 把这 4×48 个寄存器连同对应端口
  // 一起消掉了——golden TLBFA.sv 里确实一个 entries_*_perm_d 都没有。
  // 这里用 KEEP_WPERM 精确复刻这个取舍：
  //   1 → 真寄存器（TLBFA_1/_2/_3 = ld/st/pf TLB）
  //   0 → 根本不存在，读出恒 0（TLBFA = itlb）
  // 为什么不图省事"总是存、让 wrapper 不接"：那会在 impl 侧留下 192 个只写不读的
  // 死寄存器，golden 侧没有对应物可配对，FM 签核会因 unread 判 PARTIAL。
  tlb_wperm_t       wperm [NWAYS];

  // ===========================================================================
  // refill 写：把 PTW 送来的两级结果合并成一条 TLB entry
  // （Chisel TlbSectorEntry.apply(item: PtwRespS2)）
  // ===========================================================================
  logic [NWAYS-1:0] refill_oh;          // 本拍要写的 way（one-hot，w_valid 才有效）
  tlb_entry_t       refill_entry;
  tlb_wperm_t       refill_wperm;

  always_comb begin
    refill_oh = '0;
    if (w_valid) refill_oh[w_way] = 1'b1;
  end

  // 合并后的页大小：两级都做时取"更小的那一级"（谁的 level 小谁说了算）。
  logic [1:0] merge_level;
  logic       s1_is_fake_pte, s1_exception, s2_exception, s1_is_leaf;
  logic [1:0] all_stage_level, inner_level;
  logic       all_stage_napot, inner_n, is_super_page;

  always_comb begin
    case (w_s2xlate)
      ONLY_S1:   merge_level = w_s1_entry_level;
      ONLY_S2:   merge_level = w_s2_entry_level;
      ALL_STAGE: merge_level = (w_s1_entry_level < w_s2_entry_level) ? w_s1_entry_level
                                                                     : w_s2_entry_level;
      default:   merge_level = w_s1_entry_level;   // NO_S2XLATE
    endcase
  end

  // fake PTE = "s1 既没出异常、PTE 又无效"，表示 vsatp 关着（VS-stage 其实没走）。
  assign s1_is_fake_pte = !w_s1_pf && !w_s1_entry_v && !w_s1_af;
  assign s1_exception   = (w_s1_pf || w_s1_af) && !s1_is_fake_pte;
  assign s2_exception   = w_s2_gpf || w_s2_gaf;
  assign s1_is_leaf     = (w_s1_entry_perm_r || w_s1_entry_perm_x || w_s1_entry_perm_w)
                          && w_s1_entry_v;

  // 两级翻译且有异常时，level 不能取 min：那会把大页记成小页，sfence 就刷不掉它
  // （Chisel 注释里那段 bug 复盘）。规则：
  //   s1 出异常 / s2 出异常但 s1 非叶子 → 记 s1 的 level；
  //   s2 出异常且 s1 是 fake PTE      → 记最大页（3），表示 vsatp 配错了；
  //   其余                            → merge_level。
  assign all_stage_level = (s1_exception || (s2_exception && !s1_is_leaf)) ? w_s1_entry_level
                         : (s2_exception && s1_is_fake_pte)               ? 2'd3
                                                                          : merge_level;
  assign inner_level = (w_s2xlate != ALL_STAGE) ? merge_level : all_stage_level;

  // 合并后的 NAPOT：两级都做时，只要一级是 64KB 而另一级不小于它，合起来就是 64KB。
  assign all_stage_napot = (w_s1_entry_n && (w_s2_entry_level != 2'd0))
                        || (w_s2_entry_n && (w_s1_entry_level != 2'd0))
                        || (w_s1_entry_n && w_s2_entry_n);

  always_comb begin
    case (w_s2xlate)
      ONLY_S1:   inner_n = w_s1_entry_n;
      ONLY_S2:   inner_n = w_s2_entry_n;
      ALL_STAGE: inner_n = all_stage_napot;
      default:   inner_n = w_s1_entry_n;           // NO_S2XLATE
    endcase
  end

  assign is_super_page = (inner_level != 2'd0) || inner_n;

  // 只翻 G-stage 时，"vpn" 其实是 guest 物理页号，tag/vmid/valididx 都取 s2 的。
  logic use_s2_tag;
  assign use_s2_tag = (w_s2xlate == ONLY_S2);

  // s2 的 ppn 要按 s2 自己的页大小与 s2 tag 拼：s2 页比 s1 大时，低位来自 tag。
  logic [SPPN_W-1:0] s2_sector_ppn;
  logic [PPN_W-1:0]  s2_full_ppn;      // 同一个拼法但保留低 3 位，用来喂 ppn_low
  logic [SECT_N-1:0] s2_tag_onehot;    // UIntToOH(s2.tag[2:0])

  always_comb begin
    case (w_s2_entry_level)
      2'd3:    s2_sector_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W*3],
                                w_s2_entry_tag[VPNN_W*3-1 : SECT_W]};
      2'd2:    s2_sector_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W*2],
                                w_s2_entry_tag[VPNN_W*2-1 : SECT_W]};
      2'd1:    s2_sector_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W],
                                w_s2_entry_tag[VPNN_W-1 : SECT_W]};
      default: s2_sector_ppn = w_s2_entry_n
                               ? {w_s2_entry_ppn[PPN_W-1 : NAPOT_BITS],
                                  w_s2_entry_tag[NAPOT_BITS-1 : SECT_W]}
                               : w_s2_entry_ppn[PPN_W-1 : SECT_W];
    endcase
    case (w_s2_entry_level)
      2'd3:    s2_full_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W*3], w_s2_entry_tag[VPNN_W*3-1 : 0]};
      2'd2:    s2_full_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W*2], w_s2_entry_tag[VPNN_W*2-1 : 0]};
      2'd1:    s2_full_ppn = {w_s2_entry_ppn[PPN_W-1 : VPNN_W],   w_s2_entry_tag[VPNN_W-1 : 0]};
      default: s2_full_ppn = w_s2_entry_n
                             ? {w_s2_entry_ppn[PPN_W-1 : NAPOT_BITS], w_s2_entry_tag[NAPOT_BITS-1 : 0]}
                             : w_s2_entry_ppn[PPN_W-1 : 0];
    endcase
    s2_tag_onehot = '0;
    s2_tag_onehot[w_s2_entry_tag[SECT_W-1:0]] = 1'b1;
  end

  always_comb begin
    refill_entry.tag      = use_s2_tag ? w_s2_entry_tag[GVPN_W-1 : SECT_W] : w_s1_entry_tag;
    refill_entry.asid     = w_s1_entry_asid;
    refill_entry.level    = inner_level;
    // s1 的 ppn 端口有 41 位（ptePPN），TLB 只存低 33 位
    refill_entry.ppn      = (w_s2xlate == NO_S2XLATE || w_s2xlate == ONLY_S1)
                            ? w_s1_entry_ppn[SPPN_W-1:0] : s2_sector_ppn;
    refill_entry.n        = inner_n;
    refill_entry.pbmt     = w_s1_entry_pbmt;
    refill_entry.g_pbmt   = w_s2_entry_pbmt;
    refill_entry.perm     = '{pf: w_s1_pf,          af: w_s1_af,         v: w_s1_entry_v,
                              a:  w_s1_entry_perm_a, g: w_s1_entry_perm_g,
                              u:  w_s1_entry_perm_u, x: w_s1_entry_perm_x,
                              w:  w_s1_entry_perm_w, r: w_s1_entry_perm_r};
    // 超页整条都算有效（8 格全 1）；只翻 G-stage 时只有 tag 指的那格有效。
    refill_entry.valididx = is_super_page ? '1
                          : (use_s2_tag ? s2_tag_onehot : w_s1_valididx);
    refill_entry.pteidx   = use_s2_tag ? s2_tag_onehot : w_s1_pteidx;
    for (int k = 0; k < SECT_N; k++)
      refill_entry.ppn_low[k] = (w_s2xlate == NO_S2XLATE || w_s2xlate == ONLY_S1)
                                ? w_s1_ppn_low[k] : s2_full_ppn[SECT_W-1:0];
    refill_entry.g_perm   = '{pf: w_s2_gpf, af: w_s2_gaf,
                              a:  w_s2_entry_perm_a, x: w_s2_entry_perm_x};
    refill_entry.vmid     = use_s2_tag ? w_s2_entry_vmid : w_s1_entry_vmid;
    refill_entry.s2xlate  = w_s2xlate;

    refill_wperm = '{perm_d:   w_s1_entry_perm_d, g_perm_d: w_s2_entry_perm_d,
                     g_perm_w: w_s2_entry_perm_w, g_perm_r: w_s2_entry_perm_r};
  end

  // entry 本体：无复位，按 way one-hot 写入。
  // ★注意 entries 与 v 分属两个 always 块（golden 也是两块）：sfence 与 refill 同拍时，
  //   entry 数据照写不误，只是 v 被 sfence 那一支盖掉、不置 1 —— 见下面的 v 更新。
  always_ff @(posedge clock) begin
    for (int way = 0; way < NWAYS; way++)
      if (refill_oh[way]) entries[way] <= refill_entry;
  end

  generate
    if (KEEP_WPERM) begin : g_wperm_kept
      tlb_wperm_t wperm_q [NWAYS];
      always_ff @(posedge clock) begin
        for (int way = 0; way < NWAYS; way++)
          if (refill_oh[way]) wperm_q[way] <= refill_wperm;
      end
      for (genvar way = 0; way < NWAYS; way++) assign wperm[way] = wperm_q[way];
    end else begin : g_wperm_pruned
      // itlb：golden 里这 4 位根本没有寄存器，读出就是常 0。
      for (genvar way = 0; way < NWAYS; way++) assign wperm[way] = '0;
    end
  endgenerate

  // refill 打一拍：用来把"刚填的 way"当作一次访问喂给上层替换器（见 §读路径末尾）。
  // golden 里就是 REG / refill_wayIdx_reg 这两个寄存器，同样无复位。
  logic [WAY_W-1:0] refill_way_q;
  logic             refill_valid_q;
  always_ff @(posedge clock) begin
    if (w_valid) refill_way_q <= w_way;
    refill_valid_q <= w_valid;
  end

  // ===========================================================================
  // §读路径：PORTS 路并行查询
  // ===========================================================================
  // 本拍正在 refill 的 way 不许命中（数据还没落，命中就会读到旧内容配新 v）。
  // golden 里这根线按端口复制了 PORTS 份（refill_mask / refill_mask_1 / _2，表达式
  // 一字不差）。这里只留一份：它是**纯组合线**，不是比较点，合并对 FM 不可见。
  // ★"别合并 golden 的冗余结构"这条规矩针对的是**状态**（寄存器/计数器）★ ——
  // 本核里凡是 golden 按端口分份的寄存器（hitVecReg / reqVpn / resp_valid）都逐份保留，
  // 凡是 golden 只有一份的（refill_wayIdx_reg / REG）也只有一份；
  // 逐组位数由 verif/ut/TLBFA/reset_domain_check.py 的判据 D 钉住。
  logic [NWAYS-1:0] refill_mask;
  assign refill_mask = refill_oh;

  for (genvar p = 0; p < PORTS; p++) begin : g_port
    logic [NWAYS-1:0] hit_vec;        // 请求拍组合算出的命中向量
    logic [NWAYS-1:0] hit_vec_q;      // RegEnable(hitVec, req.valid)
    logic             resp_valid_q;   // RegNext(req.valid)
    logic [VPN_W-1:0] req_vpn_q;      // ★RegNext(vpn)，不是 RegEnable★
    logic             has_s2, only_s2, only_s1;
    logic [ASID_W-1:0] cmp_asid;

    assign has_s2   = (req_s2xlate[p] != NO_S2XLATE);
    assign only_s2  = (req_s2xlate[p] == ONLY_S2);
    assign only_s1  = (req_s2xlate[p] == ONLY_S1);
    // 有 H 扩展翻译时用 vsatp 的 asid（客户机的），否则用 satp 的。
    assign cmp_asid = has_s2 ? csr_vsatp_asid : csr_satp_asid;

    always_comb begin
      for (int way = 0; way < NWAYS; way++)
        hit_vec[way] = (entries[way].s2xlate == req_s2xlate[p])
                    && entry_hit(entries[way], req_vpn[p], cmp_asid, csr_hgatp_vmid,
                                 has_s2, only_s2, only_s1, 1'b0)
                    && v[way] && !refill_mask[way];
    end

    // ★ reqVpn 是无条件 RegNext，而 hitVecReg 是 req.valid 使能的 RegEnable ★
    //   —— 两者在 req.valid=0 的拍会"错位"：hit 还留着上次的，vpn 已经换成本拍的。
    //   golden 就是这样（reg reqVpn 在 always 里无条件更新），照搬。上层保证只在
    //   resp.valid（= RegNext(req.valid)）为真时才看响应，所以看不到这个错位。
    always_ff @(posedge clock) begin
      if (req_valid[p]) hit_vec_q <= hit_vec;
      resp_valid_q <= req_valid[p];
      req_vpn_q    <= req_vpn[p];
    end

    // Mux1H：注意**不是**优先选择。sector TLB 允许多命中（Chisel 注释 "may trigger
    // multi-hit, see def wbhit"），多命中时 golden 给出的是各字段按位或，这里照搬。
    logic [PPN_W-1:0]  sel_ppn;
    logic [PBMT_W-1:0] sel_pbmt, sel_g_pbmt;
    tlb_perm_t         sel_perm;
    tlb_gperm_t        sel_g_perm;
    tlb_wperm_t        sel_wperm;
    logic [1:0]        sel_s2xlate;
    logic [WAY_W-1:0]  sel_way;

    always_comb begin
      sel_ppn     = '0;
      sel_pbmt    = '0;
      sel_g_pbmt  = '0;
      sel_perm    = '0;
      sel_g_perm  = '0;
      sel_wperm   = '0;
      sel_s2xlate = '0;
      sel_way     = '0;
      for (int way = 0; way < NWAYS; way++) begin
        if (hit_vec_q[way]) begin
          sel_ppn     = sel_ppn     | entry_gen_ppn(entries[way], req_vpn_q);
          sel_pbmt    = sel_pbmt    | entries[way].pbmt;
          sel_g_pbmt  = sel_g_pbmt  | entries[way].g_pbmt;
          sel_perm    = sel_perm    | entries[way].perm;
          sel_g_perm  = sel_g_perm  | entries[way].g_perm;
          sel_wperm   = sel_wperm   | wperm[way];
          sel_s2xlate = sel_s2xlate | entries[way].s2xlate;
          sel_way     = sel_way     | WAY_W'(way);   // OHToUInt，同样是按位或
        end
      end
    end

    assign resp_hit[p]       = |hit_vec_q;
    assign resp_ppn[p]       = sel_ppn;
    assign resp_pbmt[p]      = sel_pbmt;
    assign resp_g_pbmt[p]    = sel_g_pbmt;
    assign resp_perm_pf[p]   = sel_perm.pf;
    assign resp_perm_af[p]   = sel_perm.af;
    assign resp_perm_v[p]    = sel_perm.v;
    assign resp_perm_d[p]    = sel_wperm.perm_d;
    assign resp_perm_a[p]    = sel_perm.a;
    assign resp_perm_g[p]    = sel_perm.g;
    assign resp_perm_u[p]    = sel_perm.u;
    assign resp_perm_x[p]    = sel_perm.x;
    assign resp_perm_w[p]    = sel_perm.w;
    assign resp_perm_r[p]    = sel_perm.r;
    assign resp_g_perm_pf[p] = sel_g_perm.pf;
    assign resp_g_perm_af[p] = sel_g_perm.af;
    assign resp_g_perm_d[p]  = sel_wperm.g_perm_d;
    assign resp_g_perm_a[p]  = sel_g_perm.a;
    assign resp_g_perm_x[p]  = sel_g_perm.x;
    assign resp_g_perm_w[p]  = sel_wperm.g_perm_w;
    assign resp_g_perm_r[p]  = sel_wperm.g_perm_r;
    assign resp_s2xlate[p]   = sel_s2xlate;

    // 替换器反馈：平时报"本拍命中的 way"；refill 的下一拍改报"刚写进去的 way"
    // （所有端口一起改，见上面的 refill_way_q / refill_valid_q）。
    assign access_touch_valid[p] = refill_valid_q || (resp_valid_q && (|hit_vec_q));
    assign access_touch_way[p]   = refill_valid_q ? refill_way_q : sel_way;
  end

  // ===========================================================================
  // §失效：sfence.vma / hfence.vvma / hfence.gvma
  // ===========================================================================
  // 三条指令共用 sfence 端口，由 hv/hg 区分；rs1/rs2 的语义是"该字段是否为 x0"，
  // 即 rs1=1 表示**不指定地址**（刷全部地址），rs2=1 表示**不指定 asid**。
  logic [VPN_W-1:0] sfence_vpn;
  assign sfence_vpn = sfence_addr[VADDR_W-1 : OFF_LEN];

  logic [NWAYS-1:0] sfence_hit, sfence_hit_noasid, entry_has_s2, entry_vmid_eq_hgatp;
  logic [NWAYS-1:0] entry_asid_eq_id, entry_vmid_eq_id, entry_global;

  always_comb begin
    for (int way = 0; way < NWAYS; way++) begin
      sfence_hit[way]          = entry_hit(entries[way], sfence_vpn, sfence_id,
                                           csr_hgatp_vmid, csr_priv_virt, 1'b0, 1'b0, 1'b0);
      sfence_hit_noasid[way]   = entry_hit(entries[way], sfence_vpn, sfence_id,
                                           csr_hgatp_vmid, csr_priv_virt, 1'b0, 1'b0, 1'b1);
      entry_has_s2[way]        = (entries[way].s2xlate != NO_S2XLATE);
      entry_vmid_eq_hgatp[way] = ({{(ASID_W-VMID_W){1'b0}}, entries[way].vmid} == csr_hgatp_vmid);
      entry_vmid_eq_id[way]    = ({{(ASID_W-VMID_W){1'b0}}, entries[way].vmid} == sfence_id);
      entry_asid_eq_id[way]    = (entries[way].asid == sfence_id);
      entry_global[way]        = entries[way].perm.g;
    end
  end

  // 地址不参与匹配的那一支："虚拟化打开时一律刷全部地址"（hfence.vvma 的注释），
  // 以及 bitmap check 打开（BME=1 且 CMODE=0）时也一律刷全部地址。
  logic sfence_flush_all_addr;
  assign sfence_flush_all_addr = sfence_rs1 || csr_priv_virt || (csr_mbmc_bme && !csr_mbmc_cmode);

  // v 是全模块唯一带复位的寄存器，且**异步**复位（golden: posedge clock or posedge reset）。
  // 分支优先级照搬 golden 的 else-if 链 = Chisel 里 when 的**后写者胜**顺序：
  //   hfence.gvma > hfence.vvma > sfence.vma > refill 置位。
  // 于是 sfence 与 refill 同拍时，refill 写进了 entry 却不置 v ——> 这条 entry 作废。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      v <= '0;
    end else if (sfence_valid && sfence_hg) begin
      // hfence.gvma：按 vmid 刷所有"带 G-stage"的项（rs2=1 则不挑 vmid）
      for (int way = 0; way < NWAYS; way++)
        v[way] <= v[way] && !(entry_has_s2[way] && (sfence_rs2 || entry_vmid_eq_id[way]));
    end else if (sfence_valid && sfence_hv) begin
      // hfence.vvma：只刷当前 vmid 下"带 G-stage"的项；rs2=0 时再挑 asid（global 页不刷）
      for (int way = 0; way < NWAYS; way++)
        v[way] <= v[way] && !(entry_has_s2[way] && entry_vmid_eq_hgatp[way]
                              && (sfence_rs2 || (!entry_global[way] && entry_asid_eq_id[way])));
    end else if (sfence_valid && !sfence_hg && !sfence_hv) begin
      if (sfence_flush_all_addr) begin
        if (sfence_rs2) begin
          // 所有地址 + 所有 asid：非虚拟化态刷"无 G-stage"的项，虚拟化态刷本 vmid 的项
          for (int way = 0; way < NWAYS; way++)
            v[way] <= v[way] && !((!csr_priv_virt && !entry_has_s2[way])
                                  || (csr_priv_virt && entry_has_s2[way]
                                      && entry_vmid_eq_hgatp[way]));
        end else begin
          // 所有地址 + 指定 asid（global 页不刷）
          for (int way = 0; way < NWAYS; way++)
            v[way] <= v[way] && !(!entry_global[way]
                                  && ((!csr_priv_virt && !entry_has_s2[way]
                                       && entry_asid_eq_id[way])
                                      || (csr_priv_virt && entry_has_s2[way]
                                          && entry_asid_eq_id[way]
                                          && entry_vmid_eq_hgatp[way])));
        end
      end else begin
        if (sfence_rs2) begin
          // 指定地址 + 所有 asid
          for (int way = 0; way < NWAYS; way++) v[way] <= v[way] && !sfence_hit_noasid[way];
        end else begin
          // 指定地址 + 指定 asid（global 页不刷）
          for (int way = 0; way < NWAYS; way++)
            v[way] <= v[way] && !(sfence_hit[way] && !entry_global[way]);
        end
      end
    end else begin
      v <= v | refill_oh;
    end
  end

  // ===========================================================================
  // golden 里有、这里**故意没有**的东西（免得读者对着 golden 找不到对应物）：
  //   · XSError("refill, duplicate with existing entries")：整段 wbhit 比较逻辑只喂
  //     一条断言，golden 把它关在 `ifndef SYNTHESIS 里，综合/FM/UT（都带 SYNTHESIS）
  //     一侧都不存在，所以本核不实现。
  //   · XSPerfAccumulate 的一堆 perf 表达式：golden 里是**没有任何读者的悬空 wire**
  //     （io_perfEvents 端口早被消掉了），不是逻辑。
  //   · access.sets / resp.valid / vpn_reg：Chisel 里有，父级不读，firtool 连端口
  //     一起消了；resp.valid 在本核里仍以 resp_valid_q 存在，因为 touch_ways 要用它。
  // ===========================================================================

endmodule
