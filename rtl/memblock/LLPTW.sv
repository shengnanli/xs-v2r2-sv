// =============================================================================
// xs_LLPTW_core —— Last Level Page Table Walker（最后一级页表遍历器，可读 SV 重写）
//
// 设计意图来自 PageTableWalker.scala class LLPTW。LLPTW 与“串行上层 walker”PTW
// 互补：PTW 走高层页表，走到最后一级仍是 non-leaf 时把请求交给 LLPTW；page cache
// 在 L0 命中需要复检时也走 LLPTW。LLPTW 内部是一个 llptwsize=6 的【条目池】，
// 每个条目是一台独立小状态机，多个请求可【并发】遍历，但【共享一个访存口】。
//
// 微架构要点（阅读重点）：
//   1. 条目池 + per-entry 状态机：state[i]/entries[i]，入队选第一个 idle 槽。
//   2. 访存去重（dedup）：同一条 cacheline 内的多个 4KB 请求只发一次访存。
//      - 与“正在等待响应”的条目重复 → 本条目直接进 mem_waiting，共用对方 wait_id；
//      - 与“响应正巧本拍回来/在做 hptw/cache”的条目重复 → 进 cache 重读 page cache；
//      - 发访存的那一拍，把所有同 cacheline 的条目也一起拨到 mem_waiting。
//   3. 访存仲裁：mem_arb（RR）在所有 mem_req 条目里选一个发往 page cache。
//   4. G-stage（H 扩展）：首次 hptw 把页表页 GPA 译成 HPA；最后一次 hptw 把
//      VS leaf 的 GPA 译成最终 HPA。两类 hptw 各用一个 RR 仲裁器，再经 2 入仲裁器
//      汇到唯一的 hptw.req 口；hptw 串行处理（有 hptw_resp 在途时阻塞新 hptw_req）。
//   5. 输出仲裁：mem_out 的条目按优先级选 mem_ptr 输出回填；cache 的条目走 io.cache。
//
// 黑盒子模块（与 golden 共用，UT/FM 两侧一致）：
//   RRArbiterInit       —— 轮询仲裁器（带初始指针），用于 mem/hptw 选择。
//   Arbiter2_LLPTW_Anon —— 2 入固定优先仲裁器，合并首次/最后一次 hptw 请求。
//
// 本配置：EnableSv48 + HasHExtension，HasBitmapCheck=false（与 golden 一致，无
// bitmap 通路）。
// =============================================================================
module xs_LLPTW_core
  import xs_llptw_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  input  llptw_csr_t  csr,

  // in：来自 PTW / page cache 的最后一级遍历请求
  output logic        in_ready,
  input  logic        in_valid,
  input  req_info_t   in_req_info,
  input  logic [PTE_PPN_W-1:0] in_ppn,

  // out：回填上游（L2TLB）的遍历结果
  input  logic        out_ready,
  output logic        out_valid,
  output req_info_t   out_req_info,
  output logic [ID_W-1:0] out_id,
  output hptw_resp_t  out_h_resp,
  output logic        out_first_s2xlate_fault,
  output logic        out_af,

  // mem：共享访存口（page cache）
  input  logic        mem_req_ready,
  output logic        mem_req_valid,
  output logic [PADDR_W-1:0] mem_req_addr,
  output logic [ID_W-1:0]    mem_req_id,
  input  logic        mem_resp_valid,
  input  logic [ID_W-1:0] mem_resp_id,
  input  logic [BLOCK_BITS-1:0] mem_resp_value,
  output logic [ID_W-1:0] mem_enq_ptr,
  output logic [LLPTW_SIZE-1:0] mem_buffer_it,
  output req_info_t   mem_refill,
  input  logic [LLPTW_SIZE-1:0] mem_req_mask,
  input  logic [LLPTW_SIZE-1:0] mem_flush_latch,

  // cache：去重后回送 page cache 重读
  input  logic        cache_ready,
  output logic        cache_valid,
  output req_info_t   cache_req_info,

  // pmp：与 addr_check 同拍的物理内存保护检查
  output logic [PADDR_W-1:0] pmp_req_addr,
  input  logic        pmp_resp_ld,
  input  logic        pmp_resp_mmio,

  // hptw：G-stage 翻译请求/响应
  input  logic        hptw_req_ready,
  output logic        hptw_req_valid,
  output logic [SOURCE_W-1:0] hptw_req_source,
  output logic [ID_W-1:0] hptw_req_id,
  output logic [PTE_PPN_W-1:0] hptw_req_gvpn,
  input  logic        hptw_resp_valid,
  input  logic [ID_W-1:0] hptw_resp_id,
  input  hptw_resp_t  hptw_resp_h,

  output logic [3:0][5:0] perf
);

  genvar gi;

  wire flush = csr.sfence_valid || csr.satp_changed || csr.vsatp_changed || csr.hgatp_changed;

  // ---------------------------------------------------------------------------
  // 条目池与状态机寄存器
  // ---------------------------------------------------------------------------
  llptw_entry_t entries [LLPTW_SIZE-1:0];
  llptw_state_e state   [LLPTW_SIZE-1:0];
  logic [LLPTW_SIZE-1:0] mem_resp_hit;        // 本拍刚拿到 mem 数据的条目（送 mem buffer）

  // 各状态的 one-hot 视图，便于阅读与仲裁/去重表达。
  logic [LLPTW_SIZE-1:0] is_idle, is_mem_req, is_waiting, is_having, is_cache;
  logic [LLPTW_SIZE-1:0] is_hptw_req, is_last_hptw_req, is_hptw_resp, is_last_hptw_resp;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_state_view
    assign is_idle[gi]           = state[gi] == S_IDLE;
    assign is_mem_req[gi]        = state[gi] == S_MEM_REQ;
    assign is_waiting[gi]        = state[gi] == S_MEM_WAITING;
    assign is_having[gi]         = state[gi] == S_MEM_OUT;
    assign is_cache[gi]          = state[gi] == S_CACHE;
    assign is_hptw_req[gi]       = state[gi] == S_HPTW_REQ;
    assign is_last_hptw_req[gi]  = state[gi] == S_LAST_HPTW_REQ;
    assign is_hptw_resp[gi]      = state[gi] == S_HPTW_RESP;
    assign is_last_hptw_resp[gi] = state[gi] == S_LAST_HPTW_RESP;
  end

  wire full = !(|is_idle);
  assign in_ready = !full;

  // ParallelPriorityEncoder：选 oh 中最低的置位下标；全 0 时返回最高下标（5）。
  // 这正是 firtool 对 ParallelPriorityEncoder(6) 生成的形态——其“无置位”默认值
  // 决定了 enq/mem 指针在不可达分支下的取值，必须复刻以使逐拍/FM 比对一致。
  // 写成 s0?0:s1?1:...:s4?4:5，避免 unique 在 0-hot 时报 FMR_ELAB-116。
  // hptw_resp 整体写入时折叠 gpf 字段(替代"struct 写+字段覆盖"的部分写序列, 消 FM DC)。
  function automatic hptw_resp_t hr_set_gpf(input hptw_resp_t h, input logic g);
    hr_set_gpf = h;
    hr_set_gpf.gpf = g;
  endfunction

  // 单一 return(嵌套三元): 多 return 早退会被 Formality 建成带 DC 缺省支路的优先
  // mux(X 源), 见 llptw_pkg 同类改写。
  function automatic logic [ID_W-1:0] ppe6(input logic [LLPTW_SIZE-1:0] oh);
    return oh[0] ? 3'h0
         : oh[1] ? 3'h1
         : oh[2] ? 3'h2
         : oh[3] ? 3'h3
         : oh[4] ? 3'h4
         : 3'h5;
  endfunction

  // cache_ptr 在 golden 里是 ParallelMux(is_cache, idx)（各下标 OR），全 0 时为 0；
  // 而 cache_bits 同样是 OR-gated ParallelMux，全 0 时输出 0（非 entries[0]）。
  function automatic logic [ID_W-1:0] parmux_idx(input logic [LLPTW_SIZE-1:0] oh);
    parmux_idx = '0;
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (oh[i]) parmux_idx = parmux_idx | ID_W'(i);
    return parmux_idx;
  endfunction

  wire [ID_W-1:0] enq_ptr   = ppe6(is_idle);
  wire [ID_W-1:0] mem_ptr   = ppe6(is_having);
  wire [ID_W-1:0] cache_ptr = parmux_idx(is_cache);

  assign mem_enq_ptr = enq_ptr;

  // ===========================================================================
  // 入队（io.in.fire）时的“去重/落点”分析（纯组合）
  //   决定新请求落到哪个状态：是否与在途条目重复、是否直接 mem_out、是否需 hptw。
  // ===========================================================================
  // 与每个条目“同一 cacheline 且同 s2xlate”——重复判定的基础。
  logic [LLPTW_SIZE-1:0] dup_vec;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_dup
    assign dup_vec[gi] = vpn_dup(in_req_info.vpn, entries[gi].req_info.vpn) &&
                         (in_req_info.s2xlate == entries[gi].req_info.s2xlate);
  end

  // 本拍 mem_arb 选出的条目是否与新请求重复（说明访存请求正好这拍发出去）。
  wire [SOURCE_W-1:0] dummy_src;       // mem_arb out 的 source 输出不使用
  wire        mem_arb_out_valid;
  wire [VPN_W-1:0] mem_arb_out_vpn;
  wire [1:0]  mem_arb_out_s2xlate;
  wire [PTE_PPN_W-1:0] mem_arb_out_ppn;
  wire        mem_arb_out_hr_n;
  wire [GVPN_W-1:0] mem_arb_out_hr_ppn;
  wire [1:0]  mem_arb_out_hr_level;
  wire [ID_W-1:0] mem_arb_chosen;
  wire        mem_arb_out_fire = mem_arb_out_valid && mem_req_ready;

  wire dup_req_fire = mem_arb_out_fire &&
                      vpn_dup(in_req_info.vpn, mem_arb_out_vpn) &&
                      (in_req_info.s2xlate == mem_arb_out_s2xlate);

  logic [LLPTW_SIZE-1:0] dup_vec_wait;      // 与“已发访存、正在 waiting”的条目重复
  logic [LLPTW_SIZE-1:0] dup_vec_having;    // 与“本拍刚拿到数据(mem_out)”的条目重复
  logic [LLPTW_SIZE-1:0] dup_vec_last_hptw; // 与“正在做最后一次 hptw”的条目重复
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_dup_class
    assign dup_vec_wait[gi]      = dup_vec[gi] && is_waiting[gi];
    assign dup_vec_having[gi]    = dup_vec[gi] && is_having[gi];
    assign dup_vec_last_hptw[gi] = dup_vec[gi] && (is_last_hptw_req[gi] || is_last_hptw_resp[gi]);
  end

  // 按“跟随向量”选条目的 wait_id（OR-mux：one-hot 时即对应条目，全 0 时为 0）。
  // 不在 function 内引用模块级 entries（避免 Formality FMR_VLOG-091/FM-089），
  // 用 always_comb 在模块作用域内做选择。
  logic [ID_W-1:0] sel_wait_id_dup, sel_wait_id_need;
  always_comb begin
    sel_wait_id_dup = '0;
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (dup_vec_wait[i]) sel_wait_id_dup = sel_wait_id_dup | entries[i].wait_id;
  end
  wire [ID_W-1:0] wait_id = dup_req_fire ? mem_arb_chosen : sel_wait_id_dup;

  // wait_id_hptw_resp / chosen_hptw_resp 安全选择
  //（3 位索引可越界 6/7，折回 entries[0]，与 golden 一致、消除 X）。
  hptw_resp_t wait_id_hptw_resp;
  hptw_resp_t chosen_hptw_resp;
  always_comb begin
    wait_id_hptw_resp = entries[0].hptw_resp;
    chosen_hptw_resp  = entries[0].hptw_resp;
    for (int i = 0; i < LLPTW_SIZE; i++) begin
      if (wait_id        == ID_W'(i)) wait_id_hptw_resp = entries[i].hptw_resp;
      if (mem_arb_chosen == ID_W'(i)) chosen_hptw_resp  = entries[i].hptw_resp;
    end
  end

  // entries[resp_id] 的安全选择：resp_id 是 3 位、可能取 6/7 越界。golden 的
  // firtool 把 8 深 mux 的 6/7 槽折回 entries[0]，这里复刻同一折叠以消除 X 并对齐。
  llptw_entry_t resp_id_entry; // = entries[mem_resp_id]（6/7→entries[0]）
  llptw_entry_t hptw_id_entry; // = entries[hptw_resp_id]（6/7→entries[0]）
  logic         resp_id_dup_wait; // = dup_vec_wait[mem_resp_id]（6/7→0）
  logic         resp_id_flush;    // = mem_flush_latch[mem_resp_id]（6/7→0）
  always_comb begin
    resp_id_entry = entries[0];
    hptw_id_entry = entries[0];
    // golden 的 8 深数组 6/7 槽折回下标 0 的“值”（dup_vec_wait_0/flush_latch_0），
    // 不是常量 0（_GEN/_GEN_0 的 {..,x0,x0,x5..x0} 填充）——默认必须取 [0] 项。
    resp_id_dup_wait = dup_vec_wait[0];
    resp_id_flush = mem_flush_latch[0];
    for (int i = 0; i < LLPTW_SIZE; i++) begin
      if (mem_resp_id  == ID_W'(i)) begin
        resp_id_entry    = entries[i];
        resp_id_dup_wait = dup_vec_wait[i];
        resp_id_flush    = mem_flush_latch[i];
      end
      if (hptw_resp_id == ID_W'(i)) hptw_id_entry = entries[i];
    end
  end

  // mem 响应这拍命中本条目所等待的 id（且未被 flush）——表示数据现在可用。
  wire dup_wait_resp = mem_resp_valid && resp_id_dup_wait && !resp_id_flush;
  wire to_wait = (|dup_vec_wait) || dup_req_fire;

  // 当“跟随的访存数据这拍回来”时，要立刻判断这级 PTE 是 leaf/fault 还是要做最后
  // 一次 G-stage。下面这套和 io.mem.resp.fire 里 per-entry 的判断是同一套逻辑，
  // 只是这里用于“新入队条目恰好赶上响应”的快路径。
  wire [PADDR_W-1:0] enq_req_paddr  = make_addr(in_ppn[PPN_W-1:0], get_vpnn0(in_req_info.vpn));
  wire [GVPN_W-1:0]  enq_req_hppn    = gen_ppn_s2(resp_id_entry.hptw_resp, enq_req_paddr[PADDR_W-1:OFF_W]);
  wire [PADDR_W-1:0] enq_req_hpaddr = make_addr(enq_req_hppn[PPN_W-1:0], get_vpnn0(in_req_info.vpn));
  wire [IDX_HI-IDX_LO:0] enq_index =
    (resp_id_entry.req_info.s2xlate == ALL_STAGE) ? enq_req_hpaddr[IDX_HI:IDX_LO]
                                                         : enq_req_paddr[IDX_HI:IDX_LO];
  pte_t enq_pte;
  assign enq_pte = pte_t'(mem_resp_value[enq_index*XLEN +: XLEN]);
  wire [PTE_PPN_W-1:0] enq_last_ppn = last_ppn(enq_pte, in_req_info.vpn);
  wire enq_vs_pf = pte_is_pf(enq_pte, 2'h0, csr.h_pbmt_enable) || !pte_is_leaf(enq_pte);
  wire enq_g_pf  = pte_is_stage1_gpf(enq_pte, csr.hgatp_mode) && !enq_vs_pf;

  // noStage2：无需 G-stage 即可定稿（普通/onlyStage1，或 allStage 但已 fault）。
  wire enq_no_stage2 =
    (resp_id_entry.req_info.s2xlate == NO_S2XLATE) ||
    (resp_id_entry.req_info.s2xlate == ONLY_STAGE1) ||
    ((resp_id_entry.req_info.s2xlate == ALL_STAGE) && (enq_vs_pf || enq_g_pf));

  wire to_mem_out      = dup_wait_resp && enq_no_stage2;
  wire to_cache        = (|dup_vec_having) || (|dup_vec_last_hptw);
  wire to_hptw_req     = in_req_info.s2xlate == ALL_STAGE;
  wire to_last_hptw_req = dup_wait_resp &&
                          (resp_id_entry.req_info.s2xlate == ALL_STAGE) &&
                          !(enq_vs_pf || enq_g_pf);
  wire last_hptw_excp  = dup_wait_resp &&
                          (resp_id_entry.req_info.s2xlate == ALL_STAGE) &&
                          (enq_vs_pf || enq_g_pf);

  // 入队落点优先级（对应 Scala MuxCase）：mem_out > last_hptw_req > wait > cache >
  // hptw_req > addr_check（默认）。预取请求若不落在 addr_check，则直接丢弃回 idle。
  llptw_state_e enq_state_normal, enq_state;
  always_comb begin
    if      (to_mem_out)       enq_state_normal = S_MEM_OUT;
    else if (to_last_hptw_req) enq_state_normal = S_LAST_HPTW_REQ;
    else if (to_wait)          enq_state_normal = S_MEM_WAITING;
    else if (to_cache)         enq_state_normal = S_CACHE;
    else if (to_hptw_req)      enq_state_normal = S_HPTW_REQ;
    else                       enq_state_normal = S_ADDR_CHECK;

    enq_state = (from_pre(in_req_info.source) && (enq_state_normal != S_ADDR_CHECK))
                ? S_IDLE : enq_state_normal;
  end

  wire in_fire = in_valid && in_ready;

  // ===========================================================================
  // 访存仲裁 RRArbiterInit（黑盒）：在所有 is_mem_req 且未被 mask 的条目中轮询选一。
  // ===========================================================================
  // 打平条目数组送入黑盒（黑盒端口是 firtool 展平命名）。
  wire [LLPTW_SIZE-1:0] mem_arb_in_valid;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_memarb_v
    assign mem_arb_in_valid[gi] = is_mem_req[gi] && !mem_req_mask[gi];
  end

  RRArbiterInit mem_arb (
    .clock(clock), .reset(reset),
    .io_in_0_valid(mem_arb_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn),
    .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source),
    .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.n),
    .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.level),
    .io_in_1_valid(mem_arb_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn),
    .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source),
    .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.n),
    .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.level),
    .io_in_2_valid(mem_arb_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn),
    .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source),
    .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.n),
    .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.level),
    .io_in_3_valid(mem_arb_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn),
    .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source),
    .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.n),
    .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.level),
    .io_in_4_valid(mem_arb_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn),
    .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source),
    .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.n),
    .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.level),
    .io_in_5_valid(mem_arb_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn),
    .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source),
    .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.n),
    .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.level),
    .io_out_ready(mem_req_ready),
    .io_out_valid(mem_arb_out_valid),
    .io_out_bits_req_info_vpn(mem_arb_out_vpn),
    .io_out_bits_req_info_s2xlate(mem_arb_out_s2xlate),
    .io_out_bits_req_info_source(dummy_src),
    .io_out_bits_ppn(mem_arb_out_ppn),
    .io_out_bits_hptw_resp_entry_n(mem_arb_out_hr_n),
    .io_out_bits_hptw_resp_entry_ppn(mem_arb_out_hr_ppn),
    .io_out_bits_hptw_resp_entry_level(mem_arb_out_hr_level),
    .io_chosen(mem_arb_chosen)
  );

  // 发访存的 cacheline 内 PTE：allStage 用 hptw 译出的 HPA，否则用 GPA/PA。
  hptw_resp_t mem_arb_out_hr;
  always_comb begin
    mem_arb_out_hr = '0;
    mem_arb_out_hr.n = mem_arb_out_hr_n;
    mem_arb_out_hr.ppn = mem_arb_out_hr_ppn;
    mem_arb_out_hr.level = mem_arb_out_hr_level;
  end
  wire [PADDR_W-1:0] mem_paddr  = make_addr(mem_arb_out_ppn[PPN_W-1:0], get_vpnn0(mem_arb_out_vpn));
  wire [GVPN_W-1:0]  mem_hppn   = gen_ppn_s2(mem_arb_out_hr, mem_paddr[PADDR_W-1:OFF_W]);
  wire [PADDR_W-1:0] mem_hpaddr = make_addr(mem_hppn[PPN_W-1:0], get_vpnn0(mem_arb_out_vpn));

  assign mem_req_valid = mem_arb_out_valid && !flush;
  assign mem_req_addr  = (mem_arb_out_s2xlate == ALL_STAGE) ? mem_hpaddr : mem_paddr;
  assign mem_req_id    = mem_arb_chosen;
  assign mem_buffer_it = mem_resp_hit;

  // ===========================================================================
  // G-stage 仲裁：hyper_arb1（首次）/ hyper_arb2（最后一次），均为 RR；当任何
  // 条目处于 hptw_resp/last_hptw_resp 时阻塞，保证 hptw 串行（一次只一笔在途）。
  // ===========================================================================
  wire any_hptw_resp      = |is_hptw_resp;
  wire any_last_hptw_resp = |is_last_hptw_resp;
  // 发访存那拍被一起拨到 mem_waiting 的条目，要顺带屏蔽其 hptw_req（见时序段）。
  logic [LLPTW_SIZE-1:0] block_hptw_req;

  logic [LLPTW_SIZE-1:0] harb1_in_valid, harb2_in_valid;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_harb_v
    assign harb1_in_valid[gi] = is_hptw_req[gi] && !any_hptw_resp && !any_last_hptw_resp && !block_hptw_req[gi];
    assign harb2_in_valid[gi] = is_last_hptw_req[gi] && !any_hptw_resp && !any_last_hptw_resp;
  end

  wire        harb1_out_valid;
  wire [SOURCE_W-1:0] harb1_out_source;
  wire [PTE_PPN_W-1:0] harb1_out_ppn;
  wire [ID_W-1:0] harb1_chosen;
  wire        harb1_out_ready;
  wire        harb2_out_valid;
  wire [SOURCE_W-1:0] harb2_out_source;
  wire [PTE_PPN_W-1:0] harb2_out_ppn;
  wire [ID_W-1:0] harb2_chosen;
  wire        harb2_out_ready;

  // hyper_arb1/2 只用到 out 的 req_info.source / ppn / chosen，其余输出悬空。
  RRArbiterInit hyper_arb1 (
    .clock(clock), .reset(reset),
    .io_in_0_valid(harb1_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn),
    .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source),
    .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.n),
    .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.level),
    .io_in_1_valid(harb1_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn),
    .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source),
    .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.n),
    .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.level),
    .io_in_2_valid(harb1_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn),
    .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source),
    .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.n),
    .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.level),
    .io_in_3_valid(harb1_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn),
    .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source),
    .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.n),
    .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.level),
    .io_in_4_valid(harb1_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn),
    .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source),
    .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.n),
    .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.level),
    .io_in_5_valid(harb1_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn),
    .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source),
    .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.n),
    .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.level),
    .io_out_ready(harb1_out_ready),
    .io_out_valid(harb1_out_valid),
    .io_out_bits_req_info_vpn(/* unused */),
    .io_out_bits_req_info_s2xlate(/* unused */),
    .io_out_bits_req_info_source(harb1_out_source),
    .io_out_bits_ppn(harb1_out_ppn),
    .io_out_bits_hptw_resp_entry_n(/* unused */),
    .io_out_bits_hptw_resp_entry_ppn(/* unused */),
    .io_out_bits_hptw_resp_entry_level(/* unused */),
    .io_chosen(harb1_chosen)
  );

  RRArbiterInit hyper_arb2 (
    .clock(clock), .reset(reset),
    .io_in_0_valid(harb2_in_valid[0]),
    .io_in_0_bits_req_info_vpn(entries[0].req_info.vpn),
    .io_in_0_bits_req_info_s2xlate(entries[0].req_info.s2xlate),
    .io_in_0_bits_req_info_source(entries[0].req_info.source),
    .io_in_0_bits_ppn(entries[0].ppn),
    .io_in_0_bits_hptw_resp_entry_n(entries[0].hptw_resp.n),
    .io_in_0_bits_hptw_resp_entry_ppn(entries[0].hptw_resp.ppn),
    .io_in_0_bits_hptw_resp_entry_level(entries[0].hptw_resp.level),
    .io_in_1_valid(harb2_in_valid[1]),
    .io_in_1_bits_req_info_vpn(entries[1].req_info.vpn),
    .io_in_1_bits_req_info_s2xlate(entries[1].req_info.s2xlate),
    .io_in_1_bits_req_info_source(entries[1].req_info.source),
    .io_in_1_bits_ppn(entries[1].ppn),
    .io_in_1_bits_hptw_resp_entry_n(entries[1].hptw_resp.n),
    .io_in_1_bits_hptw_resp_entry_ppn(entries[1].hptw_resp.ppn),
    .io_in_1_bits_hptw_resp_entry_level(entries[1].hptw_resp.level),
    .io_in_2_valid(harb2_in_valid[2]),
    .io_in_2_bits_req_info_vpn(entries[2].req_info.vpn),
    .io_in_2_bits_req_info_s2xlate(entries[2].req_info.s2xlate),
    .io_in_2_bits_req_info_source(entries[2].req_info.source),
    .io_in_2_bits_ppn(entries[2].ppn),
    .io_in_2_bits_hptw_resp_entry_n(entries[2].hptw_resp.n),
    .io_in_2_bits_hptw_resp_entry_ppn(entries[2].hptw_resp.ppn),
    .io_in_2_bits_hptw_resp_entry_level(entries[2].hptw_resp.level),
    .io_in_3_valid(harb2_in_valid[3]),
    .io_in_3_bits_req_info_vpn(entries[3].req_info.vpn),
    .io_in_3_bits_req_info_s2xlate(entries[3].req_info.s2xlate),
    .io_in_3_bits_req_info_source(entries[3].req_info.source),
    .io_in_3_bits_ppn(entries[3].ppn),
    .io_in_3_bits_hptw_resp_entry_n(entries[3].hptw_resp.n),
    .io_in_3_bits_hptw_resp_entry_ppn(entries[3].hptw_resp.ppn),
    .io_in_3_bits_hptw_resp_entry_level(entries[3].hptw_resp.level),
    .io_in_4_valid(harb2_in_valid[4]),
    .io_in_4_bits_req_info_vpn(entries[4].req_info.vpn),
    .io_in_4_bits_req_info_s2xlate(entries[4].req_info.s2xlate),
    .io_in_4_bits_req_info_source(entries[4].req_info.source),
    .io_in_4_bits_ppn(entries[4].ppn),
    .io_in_4_bits_hptw_resp_entry_n(entries[4].hptw_resp.n),
    .io_in_4_bits_hptw_resp_entry_ppn(entries[4].hptw_resp.ppn),
    .io_in_4_bits_hptw_resp_entry_level(entries[4].hptw_resp.level),
    .io_in_5_valid(harb2_in_valid[5]),
    .io_in_5_bits_req_info_vpn(entries[5].req_info.vpn),
    .io_in_5_bits_req_info_s2xlate(entries[5].req_info.s2xlate),
    .io_in_5_bits_req_info_source(entries[5].req_info.source),
    .io_in_5_bits_ppn(entries[5].ppn),
    .io_in_5_bits_hptw_resp_entry_n(entries[5].hptw_resp.n),
    .io_in_5_bits_hptw_resp_entry_ppn(entries[5].hptw_resp.ppn),
    .io_in_5_bits_hptw_resp_entry_level(entries[5].hptw_resp.level),
    .io_out_ready(harb2_out_ready),
    .io_out_valid(harb2_out_valid),
    .io_out_bits_req_info_vpn(/* unused */),
    .io_out_bits_req_info_s2xlate(/* unused */),
    .io_out_bits_req_info_source(harb2_out_source),
    .io_out_bits_ppn(harb2_out_ppn),
    .io_out_bits_hptw_resp_entry_n(/* unused */),
    .io_out_bits_hptw_resp_entry_ppn(/* unused */),
    .io_out_bits_hptw_resp_entry_level(/* unused */),
    .io_chosen(harb2_chosen)
  );

  // 2 入固定优先仲裁器：in0=首次 hptw，in1=最后一次 hptw，合并到唯一 hptw.req。
  Arbiter2_LLPTW_Anon hptw_req_arb (
    .io_in_0_ready(harb1_out_ready),
    .io_in_0_valid(harb1_out_valid),
    .io_in_0_bits_source(harb1_out_source),
    .io_in_0_bits_id(harb1_chosen),
    .io_in_0_bits_ppn(harb1_out_ppn),
    .io_in_1_ready(harb2_out_ready),
    .io_in_1_valid(harb2_out_valid),
    .io_in_1_bits_source(harb2_out_source),
    .io_in_1_bits_id(harb2_chosen),
    .io_in_1_bits_ppn(harb2_out_ppn),
    .io_out_ready(hptw_req_ready),
    .io_out_valid(/* internal */),
    .io_out_bits_source(hptw_req_source),
    .io_out_bits_id(hptw_req_id),
    .io_out_bits_ppn(hptw_req_gvpn)
  );
  // golden: io_hptw_req_valid = io_hptw_req_ready & arb_out_valid & ~flush。
  wire hptw_arb_out_valid;
  assign hptw_arb_out_valid = harb1_out_valid || harb2_out_valid; // 2 入 OR 即 out.valid
  assign hptw_req_valid = hptw_req_ready && hptw_arb_out_valid && !flush;

  // ===========================================================================
  // PMP / addr_check：need_addr_check 与 hptw_need_addr_check 同拍发起 PMP。
  //   - 普通 addr_check：上一拍刚入队到 addr_check（用 addr 寄存器）。
  //   - hptw 回来后转 addr_check：用 hpaddr。
  // ===========================================================================
  logic [ID_W-1:0] enq_ptr_reg;
  logic            need_addr_check;
  logic [PADDR_W-1:0] addr_reg;        // RegEnable(MakeAddr(in.ppn, vpnn0), in.fire)
  logic [ID_W-1:0] hptw_resp_ptr_reg;
  logic            hptw_need_addr_check_q;

  wire any_hptw_resp_state = |is_hptw_resp;
  // entries[hptw_resp_ptr_reg] / state[...] 的安全选择（3 位指针可取 6/7 越界，
  // 折回 entries[0]/state[0]，与 golden firtool 的 8 深 mux 填充一致、消除 X）。
  llptw_entry_t hptw_ptr_entry;
  llptw_state_e hptw_ptr_state;
  always_comb begin
    hptw_ptr_entry = entries[0];
    hptw_ptr_state = state[0];
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (hptw_resp_ptr_reg == ID_W'(i)) begin
        hptw_ptr_entry = entries[i];
        hptw_ptr_state = state[i];
      end
  end
  // hpaddr：用 hptw_resp 条目的 ppn 生成 GPA，再经其 hptw_resp 译成 HPA。
  // MakeGPAddr(ppn, off9) = (Cat(ppn,0_off) + Cat(off,0_3))[GPAddrBits-1:0]
  wire [GPADDR_W-1:0] gpaddr_calc =
    ({hptw_ptr_entry.ppn[GVPN_W-1:0], {OFF_W{1'b0}}}) +
    ({get_vpnn0(hptw_ptr_entry.req_info.vpn), 3'b000});
  wire [GVPN_W-1:0] hpaddr_ppn =
    gen_ppn_s2(hptw_ptr_entry.hptw_resp, gpaddr_calc[GPADDR_W-1:OFF_W]);
  wire [PADDR_W-1:0] hpaddr = {hpaddr_ppn[PPN_W-1:0], gpaddr_calc[OFF_W-1:0]};

  wire hptw_need_addr_check = hptw_need_addr_check_q && (hptw_ptr_state == S_ADDR_CHECK);

  wire pmp_req_valid = need_addr_check || hptw_need_addr_check;
  assign pmp_req_addr = hptw_need_addr_check ? hpaddr : addr_reg;
  wire access_fault = pmp_resp_ld || pmp_resp_mmio;
  wire [ID_W-1:0] pmp_ptr = hptw_need_addr_check ? hptw_resp_ptr_reg : enq_ptr_reg;

  // ===========================================================================
  // 输出端口
  // ===========================================================================
  // entries[mem_ptr] 安全选择（mem_ptr 由 ppe6 必 ≤5；6/7→entries[0] 与 golden 一致）。
  llptw_entry_t mem_ptr_entry;
  always_comb begin
    mem_ptr_entry = entries[0];
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (mem_ptr == ID_W'(i)) mem_ptr_entry = entries[i];
  end
  assign out_valid = |is_having;
  assign out_req_info = mem_ptr_entry.req_info;
  assign out_id = mem_ptr;
  assign out_h_resp = mem_ptr_entry.hptw_resp;
  assign out_first_s2xlate_fault = mem_ptr_entry.first_s2xlate_fault;
  assign out_af = mem_ptr_entry.af;
  wire out_fire = out_valid && out_ready;

  assign cache_valid = |is_cache;
  // ParallelMux：仅在某条目 is_cache 时贡献其 req_info，全无则输出 0（与 golden 一致）。
  always_comb begin
    cache_req_info = '0;
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (is_cache[i]) cache_req_info = cache_req_info | entries[i].req_info;
  end
  wire cache_fire = cache_valid && cache_ready;

  logic [ID_W-1:0] mem_refill_id;
  // entries[mem_refill_id].req_info 安全选择（6/7→entries[0]，与 golden 一致）。
  always_comb begin
    mem_refill = entries[0].req_info;
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (mem_refill_id == ID_W'(i)) mem_refill = entries[i].req_info;
  end

  // ===========================================================================
  // mem 响应这拍，对每个“正在 waiting 且 id 匹配”的条目独立判 PTE（per-entry）。
  //   与入队快路径同一套：算 index → 取 PTE → vsStagePf/gStagePf → 下一状态。
  // ===========================================================================
  pte_t resp_pte [LLPTW_SIZE-1:0];
  logic [PTE_PPN_W-1:0] resp_last_ppn [LLPTW_SIZE-1:0];
  logic resp_vs_pf [LLPTW_SIZE-1:0];
  logic resp_g_pf  [LLPTW_SIZE-1:0];
  logic resp_match [LLPTW_SIZE-1:0];
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_resp_pte
    wire [PADDR_W-1:0] rp_paddr  = make_addr(entries[gi].ppn[PPN_W-1:0], get_vpnn0(entries[gi].req_info.vpn));
    wire [GVPN_W-1:0]  rp_hppn   = gen_ppn_s2(entries[gi].hptw_resp, rp_paddr[PADDR_W-1:OFF_W]);
    wire [PADDR_W-1:0] rp_hpaddr = make_addr(rp_hppn[PPN_W-1:0], get_vpnn0(entries[gi].req_info.vpn));
    wire [IDX_HI-IDX_LO:0] rp_index =
      (entries[gi].req_info.s2xlate == ALL_STAGE) ? rp_hpaddr[IDX_HI:IDX_LO] : rp_paddr[IDX_HI:IDX_LO];
    wire en_s2 = entries[gi].req_info.s2xlate != NO_S2XLATE;
    wire s1pbmte = en_s2 ? csr.h_pbmt_enable : csr.m_pbmt_enable;
    assign resp_pte[gi] = pte_t'(mem_resp_value[rp_index*XLEN +: XLEN]);
    assign resp_vs_pf[gi] = pte_is_pf(resp_pte[gi], 2'h0, s1pbmte) || !pte_is_leaf(resp_pte[gi]);
    assign resp_g_pf[gi]  = pte_is_stage1_gpf(resp_pte[gi], csr.hgatp_mode) && !resp_vs_pf[gi];
    assign resp_last_ppn[gi] = last_ppn(resp_pte[gi], entries[gi].req_info.vpn);
    assign resp_match[gi] = mem_resp_valid && is_waiting[gi] && (mem_resp_id == entries[gi].wait_id);
  end

  // hptw 响应这拍，对每个 hptw_resp/last_hptw_resp 且 id+tag 匹配的条目处理。
  wire hptw_resp_fire = hptw_resp_valid; // io.hptw.resp 是 Valid（无 ready）
  wire hr_perm_fail = !hptw_resp_h.gaf && (!hptw_resp_h.perm.r && !(csr.priv_mxr && hptw_resp_h.perm.x));

  // “首次 hptw 正常返回后”是否要把本条目转回 mem_waiting（与某 waiting 条目重复）。
  // 对 hptw.resp.id 这个被响应的条目，找是否有同 cacheline 的 waiting 条目。
  logic [LLPTW_SIZE-1:0] need_to_waiting_vec;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_need_wait
    assign need_to_waiting_vec[gi] = is_waiting[gi] &&
      vpn_dup(entries[gi].req_info.vpn, hptw_id_entry.req_info.vpn) &&
      (entries[gi].req_info.s2xlate == hptw_id_entry.req_info.s2xlate);
  end
  wire any_need_to_waiting = |need_to_waiting_vec;
  always_comb begin
    sel_wait_id_need = '0;
    for (int i = 0; i < LLPTW_SIZE; i++)
      if (need_to_waiting_vec[i]) sel_wait_id_need = sel_wait_id_need | entries[i].wait_id;
  end
  wire [ID_W-1:0] waiting_index = sel_wait_id_need;

  // perf 事件源（与 XSPerfAccumulate 一致，输出再延迟两拍）。
  wire perf_ev0 = in_fire;                       // io.in.fire
  wire perf_ev1 = in_valid && !in_ready;         // io.in.valid && !io.in.ready
  wire perf_ev2 = mem_req_ready && mem_req_valid; // io.mem.req.fire（mem_req_valid 已含 ~flush）
  wire [2:0] perf_ev3 = 3'(is_waiting[0]) + 3'(is_waiting[1]) + 3'(is_waiting[2])
                      + 3'(is_waiting[3]) + 3'(is_waiting[4]) + 3'(is_waiting[5]); // PopCount(is_waiting)
  // 两级流水寄存（golden：REG → REG_1，输出取 REG_1）。
  //   仅寄存「有效位」(perf0/1/2=1 位, perf3=3 位), 输出端的高位常数 0 走组合
  //   拼接(assign perf[k] = {5'h0, ...}) 而非进 always_ff, 以精确镜像 golden
  //   `assign io_perf_k_value = {5'h0, io_perf_k_value_REG_1}` 的寄存边界——
  //   否则整 6 位 perf[k] 进 always_ff 会把高位常数 0 也推成寄存器(impl-only 死位)。
  logic perf0_s1, perf1_s1, perf2_s1;
  logic [2:0] perf3_s1;
  logic perf0_s2, perf1_s2, perf2_s2;
  logic [2:0] perf3_s2;

  // ===========================================================================
  // 主时序：写者优先级与 Scala when 书写顺序一致（后写覆盖先写）。
  //   FM 收敛关键改写：每个寄存器字（state[k]/entries[k]/mem_resp_hit[k]）的完整
  //   次态在 always_comb 里按「先低优先级、后高优先级覆盖」一次算好（st_nxt/
  //   ent_nxt/mrh_nxt），always_ff 只做单一无条件写。原先散写多 if 块会让
  //   Formality 的 word-level 抽取对同字多写者建成假定 one-hot 的 WMUX，写者
  //   条件可同拍重叠（如 mem_arb 拨 waiting 与 hptw 首响应同拍）时留 DC 缺省支
  //   路（X 源），entries_1..5 大片误判不等价。语义与原散写完全相同（UT 逐拍等）。
  // ===========================================================================
  // ---- 各写者命中条件（组合，逐条目）----
  logic [LLPTW_SIZE-1:0] w_enq, w_pmp, w_memarb, w_harb1, w_harb2, w_hfirst, w_hlast;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_wr_cond
    // 入队 io.in.fire 落到 enq_ptr
    assign w_enq[gi] = in_fire && (enq_ptr == ID_W'(gi));
    // PMP 同拍结果写回（addr_check → mem_req / mem_out）
    assign w_pmp[gi] = pmp_req_valid && (pmp_ptr == ID_W'(gi));
    // 发访存那拍：所有同 cacheline 的“在途”条目一起拨到 mem_waiting
    assign w_memarb[gi] = mem_arb_out_fire &&
        state[gi] != S_IDLE && state[gi] != S_MEM_OUT &&
        state[gi] != S_LAST_HPTW_REQ && state[gi] != S_LAST_HPTW_RESP &&
        entries[gi].req_info.s2xlate == mem_arb_out_s2xlate &&
        vpn_dup(entries[gi].req_info.vpn, mem_arb_out_vpn);
    // 首次 hptw 仲裁发出：被选中条目转 hptw_resp
    assign w_harb1[gi] = harb1_out_valid && harb1_out_ready &&
        state[gi] == S_HPTW_REQ && entries[gi].ppn == harb1_out_ppn &&
        entries[gi].req_info.s2xlate == ALL_STAGE && (harb1_chosen == ID_W'(gi));
    // 最后一次 hptw 仲裁发出：被选中条目转 last_hptw_resp
    assign w_harb2[gi] = harb2_out_valid && harb2_out_ready &&
        state[gi] == S_LAST_HPTW_REQ && entries[gi].ppn == harb2_out_ppn &&
        entries[gi].req_info.s2xlate == ALL_STAGE && (harb2_chosen == ID_W'(gi));
    // 首/末次 hptw 响应命中（id+44 位全宽 tag 比较：{6'h0,tag}==ppn，golden _GEN_219/225）
    assign w_hfirst[gi] = hptw_resp_fire && state[gi] == S_HPTW_RESP &&
        hptw_resp_id == entries[gi].wait_id && {6'h0, hptw_resp_h.tag} == entries[gi].ppn;
    assign w_hlast[gi] = hptw_resp_fire && state[gi] == S_LAST_HPTW_RESP &&
        hptw_resp_id == entries[gi].wait_id && {6'h0, hptw_resp_h.tag} == entries[gi].ppn;
  end

  // ---- 完整次态（组合；赋值顺序 = 原 Scala when 顺序，后覆盖先）----
  llptw_state_e st_nxt  [LLPTW_SIZE-1:0];
  llptw_entry_t ent_nxt [LLPTW_SIZE-1:0];
  logic [LLPTW_SIZE-1:0] mrh_nxt;
  for (gi = 0; gi < LLPTW_SIZE; gi++) begin : g_nxt
    always_comb begin
      st_nxt[gi]  = state[gi];
      ent_nxt[gi] = entries[gi];
      // mem_resp_hit 每拍默认清零（Scala: mem_resp_hit.map(when(a){a:=0})）；
      // golden 次态 = ~old & (set...)：置位都要 && !mem_resp_hit[gi] 逐位对齐。
      mrh_nxt[gi] = 1'b0;

      // --- 入队 io.in.fire ---------------------------------------------------
      if (w_enq[gi]) begin
        st_nxt[gi] = enq_state;
        ent_nxt[gi].req_info = in_req_info;
        ent_nxt[gi].ppn = (to_last_hptw_req || last_hptw_excp) ? enq_last_ppn : in_ppn;
        ent_nxt[gi].wait_id = to_wait ? wait_id : enq_ptr;
        ent_nxt[gi].af = 1'b0;
        // hptw_resp 继承：last_hptw_req 继承被响应条目；to_wait 继承所跟随条目；否则保持。
        // 整 struct 一次性写入（gpf 折叠进数据，经 hr_set_gpf）。
        ent_nxt[gi].hptw_resp = hr_set_gpf(
            to_last_hptw_req ? resp_id_entry.hptw_resp
          : to_wait          ? wait_id_hptw_resp
          :                    entries[gi].hptw_resp,
            last_hptw_excp ? enq_g_pf : 1'b0);
        ent_nxt[gi].first_s2xlate_fault = 1'b0;
        mrh_nxt[gi] = (to_mem_out || to_last_hptw_req) && !mem_resp_hit[gi];
      end

      // --- PMP 同拍结果写回 --------------------------------------------------
      if (w_pmp[gi]) begin
        ent_nxt[gi].af = access_fault;
        st_nxt[gi] = access_fault ? S_MEM_OUT : S_MEM_REQ;
      end

      // --- 发访存那拍：同 cacheline 在途条目拨到 mem_waiting ------------------
      if (w_memarb[gi]) begin
        st_nxt[gi] = S_MEM_WAITING;
        ent_nxt[gi].hptw_resp = chosen_hptw_resp;
        ent_nxt[gi].wait_id = mem_arb_chosen;
      end

      // --- mem 响应：唤醒所有 waiting 且 id 匹配的条目 ------------------------
      if (resp_match[gi]) begin
        st_nxt[gi] = (entries[gi].req_info.s2xlate == ALL_STAGE && !(resp_vs_pf[gi] || resp_g_pf[gi]))
                       ? S_LAST_HPTW_REQ : S_MEM_OUT;
        mrh_nxt[gi] = !mem_resp_hit[gi];
        ent_nxt[gi].ppn = resp_last_ppn[gi];
        ent_nxt[gi].hptw_resp.gpf = (entries[gi].req_info.s2xlate == ALL_STAGE) ? resp_g_pf[gi] : 1'b0;
      end

      // --- 首/末次 hptw 仲裁发出 ---------------------------------------------
      if (w_harb1[gi]) begin
        st_nxt[gi] = S_HPTW_RESP;
        ent_nxt[gi].wait_id = harb1_chosen;
      end
      if (w_harb2[gi]) begin
        st_nxt[gi] = S_LAST_HPTW_RESP;
        ent_nxt[gi].wait_id = harb2_chosen;
      end

      // --- 首次 hptw 响应 ----------------------------------------------------
      if (w_hfirst[gi]) begin
        // 整 struct 一次性写入（gpf 折叠：fault 时 gpf|=perm_fail；正常路 hr_perm_fail 恒 0）。
        ent_nxt[gi].hptw_resp = hr_set_gpf(hptw_resp_h, hptw_resp_h.gpf || hr_perm_fail);
        if (hr_perm_fail || hptw_resp_h.gaf || hptw_resp_h.gpf) begin
          // G-stage fault：直接出错，转 mem_out
          st_nxt[gi] = S_MEM_OUT;
          ent_nxt[gi].first_s2xlate_fault = hptw_resp_h.gaf || hptw_resp_h.gpf || hr_perm_fail;
        end else begin
          // 正常：若有同 cacheline 的 waiting 条目则跟随它，否则进 addr_check。
          // wait_id：golden 此路径整体屏蔽 harb/memarb/enq 的低优先级写——
          // 无 need_to_waiting 时必须回写“寄存器旧值”（hold），不能留下低优先级写。
          st_nxt[gi] = any_need_to_waiting ? S_MEM_WAITING : S_ADDR_CHECK;
          ent_nxt[gi].wait_id = any_need_to_waiting ? waiting_index
                                                    : entries[gi].wait_id;
        end
      end

      // --- 最后一次 hptw 响应：填 hptw_resp 后转 mem_out ----------------------
      if (w_hlast[gi]) begin
        st_nxt[gi] = S_MEM_OUT;
        ent_nxt[gi].hptw_resp = hptw_resp_h;
      end

      // --- 输出/去重/flush 释放（优先级最高，与原写序一致）--------------------
      if (out_fire && (mem_ptr == ID_W'(gi)))     st_nxt[gi] = S_IDLE;
      if (cache_fire && (cache_ptr == ID_W'(gi))) st_nxt[gi] = S_IDLE;
      if (flush)                                  st_nxt[gi] = S_IDLE;
    end
  end

  integer k;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (k = 0; k < LLPTW_SIZE; k++) begin
        state[k] <= S_IDLE;
        entries[k] <= '0;
        mem_resp_hit[k] <= 1'b0;
      end
      // 复位域与 golden 对齐: golden 只复位 state/entries/mem_resp_hit/
      // need_addr_check_last_REG(=need_addr_check); enq_ptr_reg/addr/
      // hptw_resp_ptr_reg/hptw_need_addr_check_REG/mem_refill_id/io_perf_* 无复位
      // (见下方独立无复位块)。
      need_addr_check <= 1'b0;
    end else begin
      for (k = 0; k < LLPTW_SIZE; k++) begin
        state[k]        <= st_nxt[k];
        entries[k]      <= ent_nxt[k];
        mem_resp_hit[k] <= mrh_nxt[k];
      end
      // --- addr_check 流水寄存（RegNext）-------------------------------------
      need_addr_check <= (enq_state == S_ADDR_CHECK) && in_fire && !flush;
    end
  end

  // ===========================================================================
  // 无复位寄存器(golden 3018 行 always @(posedge clock) 块): 流水打拍/perf。
  // ===========================================================================
  always_ff @(posedge clock) begin
    enq_ptr_reg <= enq_ptr;
    if (in_fire) addr_reg <= make_addr(in_ppn[PPN_W-1:0], get_vpnn0(in_req_info.vpn));
    hptw_resp_ptr_reg <= hptw_resp_id;
    hptw_need_addr_check_q <= any_hptw_resp_state && hptw_resp_fire && !flush;
    // --- refill id：RegNext(mem.resp.id) ----------------------------------
    mem_refill_id <= mem_resp_id;
    // --- perf：事件打两拍（与 XSPerfAccumulate 的 FIRRTL 形态一致：REG→REG_1）-
    //   0: in.fire   1: in.valid&&!ready   2: mem.req.fire   3: PopCount(is_waiting)
    //   两级都只寄有效位; 高位常数 0 由下方组合 assign 拼接(镜像 golden)。
    perf0_s1 <= perf_ev0; perf0_s2 <= perf0_s1;
    perf1_s1 <= perf_ev1; perf1_s2 <= perf1_s1;
    perf2_s1 <= perf_ev2; perf2_s2 <= perf2_s1;
    perf3_s1 <= perf_ev3; perf3_s2 <= perf3_s1;
  end

  // perf 输出：stage-2 有效位 + 常数 0 高位组合拼接(镜像 golden 的
  //   `assign io_perf_k_value = {5'h0, io_perf_k_value_REG_1}`)。
  assign perf[0] = {5'h0, perf0_s2};
  assign perf[1] = {5'h0, perf1_s2};
  assign perf[2] = {5'h0, perf2_s2};
  assign perf[3] = {3'h0, perf3_s2};

  // block_hptw_req：发访存那拍被一起拨到 mem_waiting 的条目，本拍屏蔽其 hptw_req。
  always_comb begin
    block_hptw_req = '0;
    if (mem_arb_out_fire) begin
      for (int i = 0; i < LLPTW_SIZE; i++) begin
        if (state[i] != S_IDLE && state[i] != S_MEM_OUT &&
            state[i] != S_LAST_HPTW_REQ && state[i] != S_LAST_HPTW_RESP &&
            entries[i].req_info.s2xlate == mem_arb_out_s2xlate &&
            vpn_dup(entries[i].req_info.vpn, mem_arb_out_vpn))
          block_hptw_req[i] = 1'b1;
      end
    end
  end

  // 抑制未使用输出端口的 lint（mem_arb 的 hptw_resp 输出未用，dummy_src 仅占位）。
  wire _unused = &{1'b0, dummy_src, 1'b0};

endmodule
