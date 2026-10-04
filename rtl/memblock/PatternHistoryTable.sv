// =============================================================================
// PatternHistoryTable —— SMS 预取器的模式历史表（PHT）
//
// Scala：src/main/scala/xiangshan/mem/prefetch/SMSPrefetcher.scala，class PatternHistoryTable。
// 位置：MemBlock → L1Prefetcher(SMSPrefetcher) → pht。SMS（Spatial Memory Streaming）把访存按
//   1KB 的"区域"（16 个 64B 块）记录"这个区域里哪些块被访问过"的位图；区域在 AGT（active
//   generation table）里活跃时累积位图，被逐出时把位图交给 PHT 学习（agt_update）；之后某条
//   load 在 AGT 里没命中时（s2_agt_lookup），按 PC 哈希查 PHT，命中就按学到的模式发预取。
//
// 表的组织：32 组 × 2 路，存在 SRAMTemplate_145（pht_ram）里；每项 = 13 位 tag + decr_mode +
//   30 个 2 位饱和计数器 hist[0..29]。30 = 2×15：以触发块为中心，hist[15..29] 记"前方" 15 个块，
//   hist[0..14] 记"后方" 15 个块（跨到相邻区域）。valid 位与 2 路 PLRU 状态不在 SRAM 里，是寄存器。
//
// 流水（一次只做一件事：要么学习一条 evict，要么查一次 lookup，evict 优先）：
//   §1 s0 选择：两个入口队列（lookup_queue / evict_queue，OverrideableQueue）里挑一个，evict 优先；
//   §2 s1 读 RAM：锁存请求，发 SRAM 读；按区域内偏移把位图"对齐"成 30 位 hist 视图；
//        若 s2 正要写同一组、或 s3 正在写 RAM（单口），s1 停住（s1_wait）；
//   §3 s2 比较 / 算新计数：tag 比较得命中路；evict 时把命中路的计数器按新位图加减，没命中就用新位图建项；
//   §4 s3 写回：写 SRAM（evict 才写）、置 valid、更新 PLRU；lookup 命中则由 hist 高位生成预取位图，
//        拆成"本区域 / 下一区域 / 上一区域"三个请求；
//   §5 s4 预取请求寄存器：三个请求各一项，经 pf_gen_req_arb（固定优先）发出；下一/上一区域的请求
//        被仲裁挡住时保持。
//
// 怪癖（照 golden）：
//   * 计数器更新规则（evict，single_update=0）：位图该位为 1 → +1 饱和；为 0 → -1 饱和到 0；
//     但若该项曾被"单次更新"过（has_been_signal_updated），为 1 时**不加**，只做减法。
//     single_update=1（AGT 中途的单次更新）：位图该位为 1 → 计数为 0 时一下 +2，否则 +1 饱和；为 0 不变。
//   * single_update 且没命中、访问计数 <= 4 时，整个 s3 不生效（不写表、不发预取）。
//   * 两路同时命中（不该发生，Scala 只有 assert）时，命中路的选择是"按位或"（Mux1H）。
//   * 预取地址：跨 4KB 页时只给虚地址（paddr_valid=0）；同页时用 s3 的物理页号拼上新区域在页内的 2 位。
//   * 本区域请求不需要 ready（仲裁器 0 号口最高优先，且 out.ready 恒 1）。
//
// child（实例名同 golden，均已签核，两侧白盒）：
//   pht_ram = SRAMTemplate_145（rtl/common/SRAMTemplate_145.sv，内含 MbistClockGateCell 与厂商宏）、
//   lookup_queue = OverrideableQueue、evict_queue = OverrideableQueue_1（rtl/frontend/）、
//   pf_gen_req_arb = Arbiter3_PfGenReq（rtl/frontend/Arbiter3_PfGenReq.sv）。
// 文件后半部的 golden 同名 wrapper 由 scripts/gen_pht.py 从 golden 端口表机械生成。
//
// 本文件导航：
//   xs_PatternHistoryTable_core …… §1 s0 选择  §2 s1 读 RAM  §3 s2 比较与计数  §4 s3 写回与预取位图  §5 s4 预取请求
//   PatternHistoryTable（wrapper）… golden 端口表 / 核 / 4 个 child 的逐端口连线（scripts/gen_pht.py 生成）
// =============================================================================

module xs_PatternHistoryTable_core #(
  parameter int unsigned PHT_SETS = 32,   // 组数
  parameter int unsigned WAYS     = 2,    // 路数（PLRU 状态按 2 路写死：1 位）
  parameter int unsigned HIST_N   = 30,   // 每项计数器个数 = 2 × (REGION_BLKS - 1)
  parameter int unsigned TAG_W    = 13,
  parameter int unsigned RADDR_W  = 40    // 区域地址宽（VAddrBits 50 - log2(1KB)）
) (
  input  logic                clock,
  input  logic                reset,
  // ---- s0：两个入口队列的出口 ----
  input  logic                lookup_valid,
  output logic                lookup_ready,
  input  logic [4:0]          lookup_phtIndex,
  input  logic [TAG_W-1:0]    lookup_phtTag,
  input  logic [RADDR_W-1:0]  lookup_regionPaddr,
  input  logic [RADDR_W-1:0]  lookup_regionVaddr,
  input  logic [3:0]          lookup_regionOffset,
  input  logic                evict_valid,
  output logic                evict_ready,
  input  logic [4:0]          evict_phtIndex,
  input  logic [TAG_W-1:0]    evict_phtTag,
  input  logic [15:0]         evict_regionBits,
  input  logic [15:0]         evict_regionBitSingle,
  input  logic [3:0]          evict_regionOffset,
  input  logic [3:0]          evict_accessCnt,
  input  logic                evict_decrMode,
  input  logic                evict_singleUpdate,
  input  logic                evict_hasBeenSingleUpdated,
  // ---- pht_ram（单口 SRAM，32 组 × 2 路）----
  output logic                ramRdValid,
  output logic [4:0]          ramRdSet,
  input  logic [1:0]          ramRdHist [WAYS][HIST_N],
  input  logic [TAG_W-1:0]    ramRdTag [WAYS],
  output logic                ramWrValid,
  output logic [4:0]          ramWrSet,
  output logic [1:0]          ramWrHist [HIST_N],     // 两路写同一份数据，靠 waymask 选路
  output logic [TAG_W-1:0]    ramWrTag,
  output logic                ramWrDecrMode,
  output logic [WAYS-1:0]     ramWrWayMask,
  // ---- 预取请求 → pf_gen_req_arb（0 = 本区域，1 = 下一区域，2 = 上一区域）----
  output logic                curValid,
  output logic [10:0]         curTag,
  output logic [RADDR_W-1:0]  curAddr,
  output logic [15:0]         curBits,
  input  logic                incrReady,
  output logic                incrValid,
  output logic [10:0]         incrTag,
  output logic [RADDR_W-1:0]  incrAddr,
  output logic [15:0]         incrBits,
  output logic                incrPaddrValid,
  input  logic                decrReady,
  output logic                decrValid,
  output logic [10:0]         decrTag,
  output logic [RADDR_W-1:0]  decrAddr,
  output logic [15:0]         decrBits,
  output logic                decrPaddrValid
);

  localparam int unsigned HALF = HIST_N / 2;      // 15：一侧的块数
  localparam int unsigned PAGE_BIT = 2;           // 区域地址里 4KB 页内的位数（4KB / 1KB = 4 → 2 位）

  // 区域地址的哈希 tag：低 6 位原样，高 15 位三段异或成 5 位（region_hash_tag）
  function automatic logic [10:0] region_hash_tag(input logic [RADDR_W-1:0] a);
    return {a[10:6] ^ a[15:11] ^ a[20:16], a[5:0]};
  endfunction

  // ---- 表的寄存器部分：valid 位与 PLRU（2 路 PLRU = 1 位：下次替换哪一路）----
  logic                pht_valids [WAYS][PHT_SETS];
  logic [PHT_SETS-1:0] plru_state;

  // ---- 级间寄存器（名字照 Scala）----
  logic                s1_valid;
  logic [4:0]          s1_ram_raddr;
  logic [TAG_W-1:0]    s1_tag;
  logic [3:0]          s1_access_cnt;
  logic [15:0]         s1_region_bits;
  logic                s1_decr_mode;
  logic [RADDR_W-1:0]  s1_region_paddr;
  logic [RADDR_W-1:0]  s1_region_vaddr;
  logic [3:0]          s1_region_offset;
  logic                s1_single_update;
  logic                s1_has_been_single_update;
  logic [15:0]         s1_region_bit_single;
  logic                s1_evict;

  logic                s2_valid;
  logic [HIST_N-1:0]   s2_hist_update_mask;
  logic                s2_single_update;
  logic                s2_has_been_single_update;
  logic [HIST_N-1:0]   s2_hist_bits;
  logic [HIST_N-1:0]   s2_hist_bit_single;
  logic [TAG_W-1:0]    s2_tag;
  logic                s2_decr_mode;
  logic [RADDR_W-1:0]  s2_region_paddr;
  logic [RADDR_W-1:0]  s2_region_vaddr;
  logic [3:0]          s2_region_offset;
  logic                s2_evict;
  logic [WAYS-1:0]     s2_pht_valids;
  logic                s2_replace_way;
  logic [4:0]          s2_ram_waddr;
  logic [3:0]          s2_access_cnt;

  logic                s3_valid;
  logic                s3_evict;
  logic [1:0]          s3_hist [HIST_N];
  logic [HIST_N-1:0]   s3_hist_pf_gen;
  logic [HIST_N-1:0]   s3_hist_update_mask;
  logic [3:0]          s3_region_offset;
  logic                s3_decr_mode;
  logic [RADDR_W-1:0]  s3_region_paddr;
  logic [RADDR_W-1:0]  s3_region_vaddr;
  logic [TAG_W-1:0]    s3_pht_tag;
  logic [WAYS-1:0]     s3_hit_vec;
  logic                s3_repl_way;
  logic [WAYS-1:0]     s3_repl_way_mask;
  logic [PHT_SETS-1:0] s3_repl_update_mask;     // s2_ram_waddr 的独热译码（打一拍）
  logic [4:0]          s3_ram_waddr;
  logic [RADDR_W-1:0]  s3_incr_region_vaddr;
  logic [RADDR_W-1:0]  s3_decr_region_vaddr;

  // ===========================================================================
  // §1 s0：选一个请求（evict 优先）。s1 停住时两个队列都不出。
  // ===========================================================================
  logic s1_wait;      // s1 本拍不能前进
  logic s0_valid;
  logic s1_reg_en;    // s1 寄存器装入

  assign s0_valid     = lookup_valid | evict_valid;
  assign evict_ready  = ~s1_valid | ~s1_wait;
  assign lookup_ready = evict_ready & ~evict_valid;
  assign s1_reg_en    = s0_valid & (~s1_wait | ~s1_valid);

  always_ff @(posedge clock) begin
    if (s1_reg_en) begin
      s1_ram_raddr              <= evict_valid ? evict_phtIndex : lookup_phtIndex;
      s1_tag                    <= evict_valid ? evict_phtTag : lookup_phtTag;
      s1_region_offset          <= evict_valid ? evict_regionOffset : lookup_regionOffset;
      s1_access_cnt             <= evict_accessCnt;          // 以下只有 evict 用
      s1_region_bits            <= evict_regionBits;
      s1_decr_mode              <= evict_decrMode;
      s1_single_update          <= evict_singleUpdate;
      s1_has_been_single_update <= evict_hasBeenSingleUpdated;
      s1_region_bit_single      <= evict_regionBitSingle;
      s1_region_paddr           <= lookup_regionPaddr;       // 以下只有 lookup 用
      s1_region_vaddr           <= lookup_regionVaddr;
      s1_evict                  <= evict_valid;
    end
  end

  // ===========================================================================
  // §2 s1：读 RAM；把 16 位区域位图按触发块偏移对齐成 30 位 hist 视图
  //   hist[15..29] = 位图[15:1] >> offset（触发块之后）；hist[0..14] = ({位图[14:0], 15'b0} >> offset)[14:0]
  //   update_mask：只有落在 [offset-15, offset+15) 窗口里的计数器才更新。
  // ===========================================================================
  logic                s2_reg_en;
  logic [HIST_N-1:0]   s1_hist_update_mask;
  logic [HIST_N-1:0]   s1_hist_bits;
  logic [HIST_N-1:0]   s1_hist_bit_single;
  logic [HIST_N-1:0]   s1_lo_bits;          // {位图[14:0], 15'b0} >> offset
  logic [HIST_N-1:0]   s1_lo_bit_single;

  assign s2_reg_en           = s1_valid & ~s1_wait;
  assign s1_hist_update_mask = {{HALF{1'b1}}, {HALF{1'b0}}} >> s1_region_offset;
  assign s1_lo_bits          = {s1_region_bits[HALF-1:0], {HALF{1'b0}}} >> s1_region_offset;
  assign s1_lo_bit_single    = {s1_region_bit_single[HALF-1:0], {HALF{1'b0}}} >> s1_region_offset;
  assign s1_hist_bits        = {s1_region_bits[HALF:1] >> s1_region_offset, s1_lo_bits[HALF-1:0]};
  assign s1_hist_bit_single  = {s1_region_bit_single[HALF:1] >> s1_region_offset, s1_lo_bit_single[HALF-1:0]};

  assign ramRdValid = s1_valid;
  assign ramRdSet   = s1_ram_raddr;

  always_ff @(posedge clock) begin
    if (s2_reg_en) begin
      s2_hist_update_mask       <= s1_hist_update_mask;
      s2_single_update          <= s1_single_update;
      s2_has_been_single_update <= s1_has_been_single_update;
      s2_hist_bits              <= s1_hist_bits;
      s2_hist_bit_single        <= s1_hist_bit_single;
      s2_tag                    <= s1_tag;
      s2_decr_mode              <= s1_decr_mode;
      s2_region_paddr           <= s1_region_paddr;
      s2_region_vaddr           <= s1_region_vaddr;
      s2_region_offset          <= s1_region_offset;
      s2_evict                  <= s1_evict;
      for (int w = 0; w < WAYS; w++)
        s2_pht_valids[w]        <= pht_valids[w][s1_ram_raddr];
      s2_replace_way            <= plru_state[s1_ram_raddr];
      s2_ram_waddr              <= s1_ram_raddr;
      s2_access_cnt             <= s1_access_cnt;
    end
  end

  // ===========================================================================
  // §3 s2：tag 比较；算每路每个计数器的新值；选出写回的 hist 与预取用的 hist 高位
  // ===========================================================================
  logic [WAYS-1:0]   s2_hit_vec;
  logic              s2_pht_hit;
  logic [1:0]        s2_hist_updated [WAYS][HIST_N];   // 每路按规则更新后的计数器
  logic [1:0]        s2_hist [HIST_N];                 // 写回 s3 的计数器
  logic [HIST_N-1:0] s2_hist_pf_gen;                   // 命中路每个计数器的高位（>=2 视为"会访问"）
  logic              s2_write_enable;                  // signal_update_write

  always_comb begin
    for (int w = 0; w < WAYS; w++)
      s2_hit_vec[w] = s2_pht_valids[w] & (ramRdTag[w] == s2_tag);
  end
  assign s2_pht_hit = |s2_hit_vec;

  // 一个计数器的新值（do_update 之外原样保留）
  function automatic logic [1:0] hist_next(
    input logic [1:0] h, input logic do_update, input logic single_update,
    input logic has_been_single_update, input logic bit_v, input logic bit_single);
    logic [1:0] incr_sat;   // +1 饱和
    logic [1:0] decr_sat;   // -1 饱和到 0
    logic [1:0] upd;
    incr_sat = (&h) ? h : h + 2'd1;
    decr_sat = (h == 2'd0) ? 2'd0 : h - 2'd1;
    if (!single_update) begin
      if (has_been_single_update)
        upd = bit_v ? h : decr_sat;
      else
        upd = bit_v ? incr_sat : decr_sat;
    end else begin
      upd = !bit_single ? h : (&h) ? h : (h == 2'd0) ? h + 2'd2 : h + 2'd1;
    end
    return do_update ? upd : h;
  endfunction

  always_comb begin
    for (int w = 0; w < WAYS; w++)
      for (int i = 0; i < HIST_N; i++)
        s2_hist_updated[w][i] = hist_next(ramRdHist[w][i], s2_hist_update_mask[i], s2_single_update,
                                          s2_has_been_single_update, s2_hist_bits[i], s2_hist_bit_single[i]);
    for (int i = 0; i < HIST_N; i++) begin
      if (s2_pht_hit) begin
        s2_hist[i] = '0;                                   // Mux1H：命中路按位或
        for (int w = 0; w < WAYS; w++)
          if (s2_hit_vec[w]) s2_hist[i] |= s2_hist_updated[w][i];
      end else begin
        s2_hist[i] = {1'b0, s2_single_update ? s2_hist_bit_single[i] : s2_hist_bits[i]};   // 新建项
      end
      s2_hist_pf_gen[i] = 1'b0;
      for (int w = 0; w < WAYS; w++)
        if (s2_hit_vec[w]) s2_hist_pf_gen[i] |= ramRdHist[w][i][1];
    end
  end

  // 单次更新且没命中、访问计数 <= 4：这次不生效
  assign s2_write_enable = ~s2_single_update | s2_pht_hit | (s2_single_update & (s2_access_cnt > 4'd4));

  always_ff @(posedge clock) begin
    if (s2_valid) begin
      s3_evict             <= s2_evict;
      s3_hist              <= s2_hist;
      s3_hist_pf_gen       <= s2_hist_pf_gen;
      s3_hist_update_mask  <= s2_hist_update_mask;
      s3_region_offset     <= s2_region_offset;
      s3_decr_mode         <= s2_decr_mode;
      s3_region_paddr      <= s2_region_paddr;
      s3_region_vaddr      <= s2_region_vaddr;
      s3_pht_tag           <= s2_tag;
      s3_hit_vec           <= s2_hit_vec;
      s3_repl_way          <= s2_replace_way;
      s3_repl_way_mask     <= WAYS'(1) << s2_replace_way;
      s3_repl_update_mask  <= PHT_SETS'(1) << s2_ram_waddr;
      s3_ram_waddr         <= s2_ram_waddr;
      s3_incr_region_vaddr <= s2_region_vaddr + RADDR_W'(1);
      s3_decr_region_vaddr <= s2_region_vaddr - RADDR_W'(1);
    end
  end

  // ===========================================================================
  // §4 s3：写回 RAM（只有 evict 写）、valid 置位、PLRU 更新；lookup 命中则生成预取位图
  // ===========================================================================
  logic              s3_hit;
  logic              s3_ram_en;

  assign s3_hit    = |s3_hit_vec;
  assign s3_ram_en = s3_valid & s3_evict;
  // s1 停住：s2 正要写的组就是 s1 要读的组（读到的是旧数据），或 s3 本拍占着单口 RAM 在写
  assign s1_wait   = (s2_valid & s2_evict & (s2_ram_waddr == s1_ram_raddr)) | s3_ram_en;

  assign ramWrValid    = s3_ram_en;
  assign ramWrSet      = s3_ram_waddr;
  assign ramWrHist     = s3_hist;
  assign ramWrTag      = s3_pht_tag;
  assign ramWrDecrMode = s3_decr_mode;
  assign ramWrWayMask  = s3_hit ? s3_hit_vec : s3_repl_way_mask;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < WAYS; w++)
        for (int s = 0; s < PHT_SETS; s++)
          pht_valids[w][s] <= 1'b0;
      plru_state <= '0;
      s1_valid   <= 1'b0;
      s2_valid   <= 1'b0;
      s3_valid   <= 1'b0;
    end else begin
      // 新建项：evict 没命中时，被替换路在该组置 valid
      for (int w = 0; w < WAYS; w++)
        for (int s = 0; s < PHT_SETS; s++)
          if (s3_ram_en & ~s3_hit & s3_repl_update_mask[s] & s3_repl_way_mask[w])
            pht_valids[w][s] <= 1'b1;
      // PLRU（2 路）：访问了哪一路，下次就换另一路
      for (int s = 0; s < PHT_SETS; s++)
        if (s3_valid & s3_repl_update_mask[s]) begin
          if (s3_hit)
            plru_state[s] <= ~s3_hit_vec[1];
          else if (s3_evict)
            plru_state[s] <= ~s3_repl_way;
        end
      s1_valid <= (s1_valid & s1_wait) | s0_valid;
      s2_valid <= s1_valid & ~s1_wait;
      s3_valid <= s2_valid & s2_write_enable;
    end
  end

  // 预取位图：命中路 hist 高位按触发块偏移"反对齐"回区域坐标
  logic              s3_pf_gen_valid;
  logic              s3_cur_valid;
  logic              s3_incr_valid;
  logic              s3_decr_valid;
  logic [HIST_N-1:0] s3_hi_shifted;     // ({15'b0, hist_pf_gen[29:15]} << offset)[29:0]
  logic [HIST_N-1:0] s3_lo_shifted;     // ({15'b0, hist_pf_gen[14:0]}  << offset)[29:0]
  logic [15:0]       s3_cur_bits;
  logic              s3_incr_crosspage;
  logic              s3_decr_crosspage;

  assign s3_pf_gen_valid = s3_valid & s3_hit & ~s3_evict;
  assign s3_cur_valid    = s3_pf_gen_valid & |(s3_hist_pf_gen & s3_hist_update_mask);
  assign s3_incr_valid   = s3_pf_gen_valid & |(s3_hist_pf_gen[HIST_N-1:HALF] & ~s3_hist_update_mask[HIST_N-1:HALF]);
  assign s3_decr_valid   = s3_pf_gen_valid & |(s3_hist_pf_gen[HALF-1:0] & ~s3_hist_update_mask[HALF-1:0]);
  assign s3_hi_shifted   = {{HALF{1'b0}}, s3_hist_pf_gen[HIST_N-1:HALF]} << s3_region_offset;
  assign s3_lo_shifted   = {{HALF{1'b0}}, s3_hist_pf_gen[HALF-1:0]} << s3_region_offset;
  assign s3_cur_bits     = {s3_hi_shifted[HALF-1:0], 1'b0} | {1'b0, s3_lo_shifted[HIST_N-1:HALF]};
  assign s3_incr_crosspage = s3_incr_region_vaddr[PAGE_BIT] != s3_region_vaddr[PAGE_BIT];
  assign s3_decr_crosspage = s3_decr_region_vaddr[PAGE_BIT] != s3_region_vaddr[PAGE_BIT];

  // ===========================================================================
  // §5 s4：三个预取请求寄存器
  //   本区域：每拍刷新（仲裁 0 号口最高优先，一拍必出）；下一/上一区域：被挡住时保持。
  // ===========================================================================
  logic                s4_cur_valid;
  logic [10:0]         s4_cur_tag;
  logic [RADDR_W-1:0]  s4_cur_addr;
  logic [15:0]         s4_cur_bits;
  logic                s4_incr_valid;
  logic [10:0]         s4_incr_tag;
  logic [RADDR_W-1:0]  s4_incr_addr;
  logic [15:0]         s4_incr_bits;
  logic                s4_incr_paddr_valid;
  logic                s4_decr_valid;
  logic [10:0]         s4_decr_tag;
  logic [RADDR_W-1:0]  s4_decr_addr;
  logic [15:0]         s4_decr_bits;
  logic                s4_decr_paddr_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s4_cur_valid  <= 1'b0;
      s4_incr_valid <= 1'b0;
      s4_decr_valid <= 1'b0;
    end else begin
      s4_cur_valid  <= s3_cur_valid;
      s4_incr_valid <= s3_incr_valid | (~incrReady & s4_incr_valid);
      s4_decr_valid <= s3_decr_valid | (~decrReady & s4_decr_valid);
    end
  end

  always_ff @(posedge clock) begin
    if (s3_cur_valid) begin
      s4_cur_tag  <= region_hash_tag(s3_region_vaddr);
      s4_cur_addr <= s3_region_paddr;
      s4_cur_bits <= s3_cur_bits;
    end
    if (s3_incr_valid) begin
      s4_incr_tag         <= region_hash_tag(s3_incr_region_vaddr);
      s4_incr_addr        <= s3_incr_crosspage ? s3_incr_region_vaddr
                                               : {s3_region_paddr[RADDR_W-1:PAGE_BIT], s3_incr_region_vaddr[PAGE_BIT-1:0]};
      s4_incr_bits        <= {1'b0, s3_hi_shifted[HIST_N-1:HALF]};
      s4_incr_paddr_valid <= ~s3_incr_crosspage;
    end
    if (s3_decr_valid) begin
      s4_decr_tag         <= region_hash_tag(s3_decr_region_vaddr);
      s4_decr_addr        <= s3_decr_crosspage ? s3_decr_region_vaddr
                                               : {s3_region_paddr[RADDR_W-1:PAGE_BIT], s3_decr_region_vaddr[PAGE_BIT-1:0]};
      s4_decr_bits        <= {s3_lo_shifted[HALF-1:0], 1'b0};
      s4_decr_paddr_valid <= ~s3_decr_crosspage;
    end
  end

  assign curValid       = s4_cur_valid;
  assign curTag         = s4_cur_tag;
  assign curAddr        = s4_cur_addr;
  assign curBits        = s4_cur_bits;
  assign incrValid      = s4_incr_valid;
  assign incrTag        = s4_incr_tag;
  assign incrAddr       = s4_incr_addr;
  assign incrBits       = s4_incr_bits;
  assign incrPaddrValid = s4_incr_paddr_valid;
  assign decrValid      = s4_decr_valid;
  assign decrTag        = s4_decr_tag;
  assign decrAddr       = s4_decr_addr;
  assign decrBits       = s4_decr_bits;
  assign decrPaddrValid = s4_decr_paddr_valid;

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序；4 个 child 按 golden 实例名例化
// （scripts/gen_pht.py 生成，勿手改）
// -----------------------------------------------------------------------------
// BEGIN GENERATED(pht-wrapper)
module PatternHistoryTable (
  input           clock,
  input           reset,
  input           io_agt_update_valid,
  input  [4:0]    io_agt_update_bits_pht_index,
  input  [12:0]   io_agt_update_bits_pht_tag,
  input  [15:0]   io_agt_update_bits_region_bits,
  input  [15:0]   io_agt_update_bits_region_bit_single,
  input  [3:0]    io_agt_update_bits_region_offset,
  input  [3:0]    io_agt_update_bits_access_cnt,
  input           io_agt_update_bits_decr_mode,
  input           io_agt_update_bits_single_update,
  input           io_agt_update_bits_has_been_signal_updated,
  input           io_s2_agt_lookup_valid,
  input  [4:0]    io_s2_agt_lookup_bits_pht_index,
  input  [12:0]   io_s2_agt_lookup_bits_pht_tag,
  input  [39:0]   io_s2_agt_lookup_bits_region_paddr,
  input  [39:0]   io_s2_agt_lookup_bits_region_vaddr,
  input  [3:0]    io_s2_agt_lookup_bits_region_offset,
  output          io_pf_gen_req_valid,
  output [10:0]   io_pf_gen_req_bits_region_tag,
  output [39:0]   io_pf_gen_req_bits_region_addr,
  output [15:0]   io_pf_gen_req_bits_region_bits,
  output          io_pf_gen_req_bits_paddr_valid,
  output          io_pf_gen_req_bits_decr_mode,
  input  [5:0]    boreChildrenBd_bore_addr,
  input  [5:0]    boreChildrenBd_bore_addr_rd,
  input  [147:0]  boreChildrenBd_bore_wdata,
  input  [1:0]    boreChildrenBd_bore_wmask,
  input           boreChildrenBd_bore_re,
  input           boreChildrenBd_bore_we,
  output [147:0]  boreChildrenBd_bore_rdata,
  input           boreChildrenBd_bore_ack,
  input           boreChildrenBd_bore_selectedOH,
  input  [6:0]    boreChildrenBd_bore_array,
  input           sigFromSrams_bore_ram_hold,
  input           sigFromSrams_bore_ram_bypass,
  input           sigFromSrams_bore_ram_bp_clken,
  input           sigFromSrams_bore_ram_aux_clk,
  input           sigFromSrams_bore_ram_aux_ckbp,
  input           sigFromSrams_bore_ram_mcp_hold,
  input           sigFromSrams_bore_cgen
);

  // ---- 核与 child 之间的线（名字取 golden 字段名；数组下标 = 路 / 计数器号）----
  logic           lq_out_valid;
  logic           lq_out_ready;
  logic [4:0]     lq_out_pht_index;
  logic [12:0]    lq_out_pht_tag;
  logic [39:0]    lq_out_region_paddr;
  logic [39:0]    lq_out_region_vaddr;
  logic [3:0]     lq_out_region_offset;
  logic           eq_out_valid;
  logic           eq_out_ready;
  logic [4:0]     eq_out_pht_index;
  logic [12:0]    eq_out_pht_tag;
  logic [15:0]    eq_out_region_bits;
  logic [15:0]    eq_out_region_bit_single;
  logic [3:0]     eq_out_region_offset;
  logic [3:0]     eq_out_access_cnt;
  logic           eq_out_decr_mode;
  logic           eq_out_single_update;
  logic           eq_out_has_been_signal_updated;
  logic           ramRdValid;
  logic [4:0]     ramRdSet;
  logic [1:0]     ramRdHist [2] [30];
  logic [12:0]    ramRdTag [2];
  logic           ramWrValid;
  logic [4:0]     ramWrSet;
  logic [1:0]     ramWrHist [30];
  logic [12:0]    ramWrTag;
  logic           ramWrDecrMode;
  logic [1:0]     ramWrWayMask;
  logic           pf_cur_valid;
  logic [10:0]    pf_cur_region_tag;
  logic [39:0]    pf_cur_region_addr;
  logic [15:0]    pf_cur_region_bits;
  logic           pf_incr_ready;
  logic           pf_incr_valid;
  logic [10:0]    pf_incr_region_tag;
  logic [39:0]    pf_incr_region_addr;
  logic [15:0]    pf_incr_region_bits;
  logic           pf_incr_paddr_valid;
  logic           pf_decr_ready;
  logic           pf_decr_valid;
  logic [10:0]    pf_decr_region_tag;
  logic [39:0]    pf_decr_region_addr;
  logic [15:0]    pf_decr_region_bits;
  logic           pf_decr_paddr_valid;

  xs_PatternHistoryTable_core u_core (
    .clock                      (clock),
    .reset                      (reset),
    .lookup_valid               (lq_out_valid),
    .lookup_ready               (lq_out_ready),
    .lookup_phtIndex            (lq_out_pht_index),
    .lookup_phtTag              (lq_out_pht_tag),
    .lookup_regionPaddr         (lq_out_region_paddr),
    .lookup_regionVaddr         (lq_out_region_vaddr),
    .lookup_regionOffset        (lq_out_region_offset),
    .evict_valid                (eq_out_valid),
    .evict_ready                (eq_out_ready),
    .evict_phtIndex             (eq_out_pht_index),
    .evict_phtTag               (eq_out_pht_tag),
    .evict_regionBits           (eq_out_region_bits),
    .evict_regionBitSingle      (eq_out_region_bit_single),
    .evict_regionOffset         (eq_out_region_offset),
    .evict_accessCnt            (eq_out_access_cnt),
    .evict_decrMode             (eq_out_decr_mode),
    .evict_singleUpdate         (eq_out_single_update),
    .evict_hasBeenSingleUpdated (eq_out_has_been_signal_updated),
    .ramRdValid                 (ramRdValid),
    .ramRdSet                   (ramRdSet),
    .ramRdHist                  (ramRdHist),
    .ramRdTag                   (ramRdTag),
    .ramWrValid                 (ramWrValid),
    .ramWrSet                   (ramWrSet),
    .ramWrHist                  (ramWrHist),
    .ramWrTag                   (ramWrTag),
    .ramWrDecrMode              (ramWrDecrMode),
    .ramWrWayMask               (ramWrWayMask),
    .curValid                   (pf_cur_valid),
    .curTag                     (pf_cur_region_tag),
    .curAddr                    (pf_cur_region_addr),
    .curBits                    (pf_cur_region_bits),
    .incrReady                  (pf_incr_ready),
    .incrValid                  (pf_incr_valid),
    .incrTag                    (pf_incr_region_tag),
    .incrAddr                   (pf_incr_region_addr),
    .incrBits                   (pf_incr_region_bits),
    .incrPaddrValid             (pf_incr_paddr_valid),
    .decrReady                  (pf_decr_ready),
    .decrValid                  (pf_decr_valid),
    .decrTag                    (pf_decr_region_tag),
    .decrAddr                   (pf_decr_region_addr),
    .decrBits                   (pf_decr_region_bits),
    .decrPaddrValid             (pf_decr_paddr_valid)
  );

  SRAMTemplate_145 pht_ram (
    .clock                           (clock),
    .reset                           (reset),
    .io_r_req_valid                  (ramRdValid),
    .io_r_req_bits_setIdx            (ramRdSet),
    .io_r_resp_data_0_hist_0         (ramRdHist[0][0]),
    .io_r_resp_data_0_hist_1         (ramRdHist[0][1]),
    .io_r_resp_data_0_hist_2         (ramRdHist[0][2]),
    .io_r_resp_data_0_hist_3         (ramRdHist[0][3]),
    .io_r_resp_data_0_hist_4         (ramRdHist[0][4]),
    .io_r_resp_data_0_hist_5         (ramRdHist[0][5]),
    .io_r_resp_data_0_hist_6         (ramRdHist[0][6]),
    .io_r_resp_data_0_hist_7         (ramRdHist[0][7]),
    .io_r_resp_data_0_hist_8         (ramRdHist[0][8]),
    .io_r_resp_data_0_hist_9         (ramRdHist[0][9]),
    .io_r_resp_data_0_hist_10        (ramRdHist[0][10]),
    .io_r_resp_data_0_hist_11        (ramRdHist[0][11]),
    .io_r_resp_data_0_hist_12        (ramRdHist[0][12]),
    .io_r_resp_data_0_hist_13        (ramRdHist[0][13]),
    .io_r_resp_data_0_hist_14        (ramRdHist[0][14]),
    .io_r_resp_data_0_hist_15        (ramRdHist[0][15]),
    .io_r_resp_data_0_hist_16        (ramRdHist[0][16]),
    .io_r_resp_data_0_hist_17        (ramRdHist[0][17]),
    .io_r_resp_data_0_hist_18        (ramRdHist[0][18]),
    .io_r_resp_data_0_hist_19        (ramRdHist[0][19]),
    .io_r_resp_data_0_hist_20        (ramRdHist[0][20]),
    .io_r_resp_data_0_hist_21        (ramRdHist[0][21]),
    .io_r_resp_data_0_hist_22        (ramRdHist[0][22]),
    .io_r_resp_data_0_hist_23        (ramRdHist[0][23]),
    .io_r_resp_data_0_hist_24        (ramRdHist[0][24]),
    .io_r_resp_data_0_hist_25        (ramRdHist[0][25]),
    .io_r_resp_data_0_hist_26        (ramRdHist[0][26]),
    .io_r_resp_data_0_hist_27        (ramRdHist[0][27]),
    .io_r_resp_data_0_hist_28        (ramRdHist[0][28]),
    .io_r_resp_data_0_hist_29        (ramRdHist[0][29]),
    .io_r_resp_data_0_tag            (ramRdTag[0]),
    .io_r_resp_data_1_hist_0         (ramRdHist[1][0]),
    .io_r_resp_data_1_hist_1         (ramRdHist[1][1]),
    .io_r_resp_data_1_hist_2         (ramRdHist[1][2]),
    .io_r_resp_data_1_hist_3         (ramRdHist[1][3]),
    .io_r_resp_data_1_hist_4         (ramRdHist[1][4]),
    .io_r_resp_data_1_hist_5         (ramRdHist[1][5]),
    .io_r_resp_data_1_hist_6         (ramRdHist[1][6]),
    .io_r_resp_data_1_hist_7         (ramRdHist[1][7]),
    .io_r_resp_data_1_hist_8         (ramRdHist[1][8]),
    .io_r_resp_data_1_hist_9         (ramRdHist[1][9]),
    .io_r_resp_data_1_hist_10        (ramRdHist[1][10]),
    .io_r_resp_data_1_hist_11        (ramRdHist[1][11]),
    .io_r_resp_data_1_hist_12        (ramRdHist[1][12]),
    .io_r_resp_data_1_hist_13        (ramRdHist[1][13]),
    .io_r_resp_data_1_hist_14        (ramRdHist[1][14]),
    .io_r_resp_data_1_hist_15        (ramRdHist[1][15]),
    .io_r_resp_data_1_hist_16        (ramRdHist[1][16]),
    .io_r_resp_data_1_hist_17        (ramRdHist[1][17]),
    .io_r_resp_data_1_hist_18        (ramRdHist[1][18]),
    .io_r_resp_data_1_hist_19        (ramRdHist[1][19]),
    .io_r_resp_data_1_hist_20        (ramRdHist[1][20]),
    .io_r_resp_data_1_hist_21        (ramRdHist[1][21]),
    .io_r_resp_data_1_hist_22        (ramRdHist[1][22]),
    .io_r_resp_data_1_hist_23        (ramRdHist[1][23]),
    .io_r_resp_data_1_hist_24        (ramRdHist[1][24]),
    .io_r_resp_data_1_hist_25        (ramRdHist[1][25]),
    .io_r_resp_data_1_hist_26        (ramRdHist[1][26]),
    .io_r_resp_data_1_hist_27        (ramRdHist[1][27]),
    .io_r_resp_data_1_hist_28        (ramRdHist[1][28]),
    .io_r_resp_data_1_hist_29        (ramRdHist[1][29]),
    .io_r_resp_data_1_tag            (ramRdTag[1]),
    .io_w_req_valid                  (ramWrValid),
    .io_w_req_bits_setIdx            (ramWrSet),
    .io_w_req_bits_data_0_hist_0     (ramWrHist[0]),
    .io_w_req_bits_data_0_hist_1     (ramWrHist[1]),
    .io_w_req_bits_data_0_hist_2     (ramWrHist[2]),
    .io_w_req_bits_data_0_hist_3     (ramWrHist[3]),
    .io_w_req_bits_data_0_hist_4     (ramWrHist[4]),
    .io_w_req_bits_data_0_hist_5     (ramWrHist[5]),
    .io_w_req_bits_data_0_hist_6     (ramWrHist[6]),
    .io_w_req_bits_data_0_hist_7     (ramWrHist[7]),
    .io_w_req_bits_data_0_hist_8     (ramWrHist[8]),
    .io_w_req_bits_data_0_hist_9     (ramWrHist[9]),
    .io_w_req_bits_data_0_hist_10    (ramWrHist[10]),
    .io_w_req_bits_data_0_hist_11    (ramWrHist[11]),
    .io_w_req_bits_data_0_hist_12    (ramWrHist[12]),
    .io_w_req_bits_data_0_hist_13    (ramWrHist[13]),
    .io_w_req_bits_data_0_hist_14    (ramWrHist[14]),
    .io_w_req_bits_data_0_hist_15    (ramWrHist[15]),
    .io_w_req_bits_data_0_hist_16    (ramWrHist[16]),
    .io_w_req_bits_data_0_hist_17    (ramWrHist[17]),
    .io_w_req_bits_data_0_hist_18    (ramWrHist[18]),
    .io_w_req_bits_data_0_hist_19    (ramWrHist[19]),
    .io_w_req_bits_data_0_hist_20    (ramWrHist[20]),
    .io_w_req_bits_data_0_hist_21    (ramWrHist[21]),
    .io_w_req_bits_data_0_hist_22    (ramWrHist[22]),
    .io_w_req_bits_data_0_hist_23    (ramWrHist[23]),
    .io_w_req_bits_data_0_hist_24    (ramWrHist[24]),
    .io_w_req_bits_data_0_hist_25    (ramWrHist[25]),
    .io_w_req_bits_data_0_hist_26    (ramWrHist[26]),
    .io_w_req_bits_data_0_hist_27    (ramWrHist[27]),
    .io_w_req_bits_data_0_hist_28    (ramWrHist[28]),
    .io_w_req_bits_data_0_hist_29    (ramWrHist[29]),
    .io_w_req_bits_data_0_tag        (ramWrTag),
    .io_w_req_bits_data_0_decr_mode  (ramWrDecrMode),
    .io_w_req_bits_data_1_hist_0     (ramWrHist[0]),
    .io_w_req_bits_data_1_hist_1     (ramWrHist[1]),
    .io_w_req_bits_data_1_hist_2     (ramWrHist[2]),
    .io_w_req_bits_data_1_hist_3     (ramWrHist[3]),
    .io_w_req_bits_data_1_hist_4     (ramWrHist[4]),
    .io_w_req_bits_data_1_hist_5     (ramWrHist[5]),
    .io_w_req_bits_data_1_hist_6     (ramWrHist[6]),
    .io_w_req_bits_data_1_hist_7     (ramWrHist[7]),
    .io_w_req_bits_data_1_hist_8     (ramWrHist[8]),
    .io_w_req_bits_data_1_hist_9     (ramWrHist[9]),
    .io_w_req_bits_data_1_hist_10    (ramWrHist[10]),
    .io_w_req_bits_data_1_hist_11    (ramWrHist[11]),
    .io_w_req_bits_data_1_hist_12    (ramWrHist[12]),
    .io_w_req_bits_data_1_hist_13    (ramWrHist[13]),
    .io_w_req_bits_data_1_hist_14    (ramWrHist[14]),
    .io_w_req_bits_data_1_hist_15    (ramWrHist[15]),
    .io_w_req_bits_data_1_hist_16    (ramWrHist[16]),
    .io_w_req_bits_data_1_hist_17    (ramWrHist[17]),
    .io_w_req_bits_data_1_hist_18    (ramWrHist[18]),
    .io_w_req_bits_data_1_hist_19    (ramWrHist[19]),
    .io_w_req_bits_data_1_hist_20    (ramWrHist[20]),
    .io_w_req_bits_data_1_hist_21    (ramWrHist[21]),
    .io_w_req_bits_data_1_hist_22    (ramWrHist[22]),
    .io_w_req_bits_data_1_hist_23    (ramWrHist[23]),
    .io_w_req_bits_data_1_hist_24    (ramWrHist[24]),
    .io_w_req_bits_data_1_hist_25    (ramWrHist[25]),
    .io_w_req_bits_data_1_hist_26    (ramWrHist[26]),
    .io_w_req_bits_data_1_hist_27    (ramWrHist[27]),
    .io_w_req_bits_data_1_hist_28    (ramWrHist[28]),
    .io_w_req_bits_data_1_hist_29    (ramWrHist[29]),
    .io_w_req_bits_data_1_tag        (ramWrTag),
    .io_w_req_bits_data_1_decr_mode  (ramWrDecrMode),
    .io_w_req_bits_waymask           (ramWrWayMask),
    .io_broadcast_ram_hold           (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass         (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken       (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk        (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp       (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold       (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl            (64'h0),
    .io_broadcast_cgen               (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr        (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd     (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata       (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask       (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re          (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we          (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata       (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack         (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH  (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array       (boreChildrenBd_bore_array)
  );

  OverrideableQueue lookup_queue (
    .clock                           (clock),
    .reset                           (reset),
    .io_in_valid                     (io_s2_agt_lookup_valid),
    .io_in_bits_pht_index            (io_s2_agt_lookup_bits_pht_index),
    .io_in_bits_pht_tag              (io_s2_agt_lookup_bits_pht_tag),
    .io_in_bits_region_paddr         (io_s2_agt_lookup_bits_region_paddr),
    .io_in_bits_region_vaddr         (io_s2_agt_lookup_bits_region_vaddr),
    .io_in_bits_region_offset        (io_s2_agt_lookup_bits_region_offset),
    .io_out_ready                    (lq_out_ready),
    .io_out_valid                    (lq_out_valid),
    .io_out_bits_pht_index           (lq_out_pht_index),
    .io_out_bits_pht_tag             (lq_out_pht_tag),
    .io_out_bits_region_paddr        (lq_out_region_paddr),
    .io_out_bits_region_vaddr        (lq_out_region_vaddr),
    .io_out_bits_region_offset       (lq_out_region_offset)
  );

  OverrideableQueue_1 evict_queue (
    .clock                           (clock),
    .reset                           (reset),
    .io_in_valid                     (io_agt_update_valid),
    .io_in_bits_pht_index            (io_agt_update_bits_pht_index),
    .io_in_bits_pht_tag              (io_agt_update_bits_pht_tag),
    .io_in_bits_region_bits          (io_agt_update_bits_region_bits),
    .io_in_bits_region_bit_single    (io_agt_update_bits_region_bit_single),
    .io_in_bits_region_offset        (io_agt_update_bits_region_offset),
    .io_in_bits_access_cnt           (io_agt_update_bits_access_cnt),
    .io_in_bits_decr_mode            (io_agt_update_bits_decr_mode),
    .io_in_bits_single_update        (io_agt_update_bits_single_update),
    .io_in_bits_has_been_signal_updated (io_agt_update_bits_has_been_signal_updated),
    .io_out_ready                    (eq_out_ready),
    .io_out_valid                    (eq_out_valid),
    .io_out_bits_pht_index           (eq_out_pht_index),
    .io_out_bits_pht_tag             (eq_out_pht_tag),
    .io_out_bits_region_bits         (eq_out_region_bits),
    .io_out_bits_region_bit_single   (eq_out_region_bit_single),
    .io_out_bits_region_offset       (eq_out_region_offset),
    .io_out_bits_access_cnt          (eq_out_access_cnt),
    .io_out_bits_decr_mode           (eq_out_decr_mode),
    .io_out_bits_single_update       (eq_out_single_update),
    .io_out_bits_has_been_signal_updated (eq_out_has_been_signal_updated)
  );

  Arbiter3_PfGenReq pf_gen_req_arb (
    .io_in_0_valid                   (pf_cur_valid),
    .io_in_0_bits_region_tag         (pf_cur_region_tag),
    .io_in_0_bits_region_addr        (pf_cur_region_addr),
    .io_in_0_bits_region_bits        (pf_cur_region_bits),
    .io_in_1_ready                   (pf_incr_ready),
    .io_in_1_valid                   (pf_incr_valid),
    .io_in_1_bits_region_tag         (pf_incr_region_tag),
    .io_in_1_bits_region_addr        (pf_incr_region_addr),
    .io_in_1_bits_region_bits        (pf_incr_region_bits),
    .io_in_1_bits_paddr_valid        (pf_incr_paddr_valid),
    .io_in_2_ready                   (pf_decr_ready),
    .io_in_2_valid                   (pf_decr_valid),
    .io_in_2_bits_region_tag         (pf_decr_region_tag),
    .io_in_2_bits_region_addr        (pf_decr_region_addr),
    .io_in_2_bits_region_bits        (pf_decr_region_bits),
    .io_in_2_bits_paddr_valid        (pf_decr_paddr_valid),
    .io_out_valid                    (io_pf_gen_req_valid),
    .io_out_bits_region_tag          (io_pf_gen_req_bits_region_tag),
    .io_out_bits_region_addr         (io_pf_gen_req_bits_region_addr),
    .io_out_bits_region_bits         (io_pf_gen_req_bits_region_bits),
    .io_out_bits_paddr_valid         (io_pf_gen_req_bits_paddr_valid),
    .io_out_bits_decr_mode           (io_pf_gen_req_bits_decr_mode)
  );

endmodule
// END GENERATED
