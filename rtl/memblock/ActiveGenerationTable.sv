// =============================================================================
// ActiveGenerationTable.sv —— SMS 预取器的"活跃代表"（AGT，Active Generation Table）
//
// 位置：SMS（Spatial Memory Streaming）预取器的第一张表。训练流（load/store 的访问地址）
//   先查 AGT；AGT 记录"当前正在被访问的各个区域（region，1KB = 16 个 cache 块）里
//   哪些块被碰过"。一个区域的记录被换出时，它积累的访问位图送去 PHT（模式历史表）学习；
//   AGT 没法直接给出预取时，把这次访问转给 PHT 去查历史模式。
//   Scala：xiangshan/mem/prefetch/SMSPrefetcher.scala（class ActiveGenerationTable）。
//
// 三级流水：
//   §S0  用 lookup 的区域 tag 全相联查 16 项：
//          命中           -> update（下一拍把本次访问的块位或进该项的位图，访问计数 +1）
//          不命中         -> alloc （下一拍按 PLRU 选一项覆盖；与上一拍同一区域则不重复分配）
//        同时查相邻区域（tag±1，允许跨区时）是否有记录，用来判断访问方向（decr_mode）。
//        dcache 换出一个块时（s0_dcache_evict），若其所在区域有记录，也把该项"驱逐"去 PHT。
//   §S1  执行 update / alloc；从被覆盖 / 被驱逐 / 被更新的那一项里取出内容准备送 PHT；
//        判断"这个区域是否已经足够活跃"（访问计数 > act_threshold）：
//          活跃   -> 本该由 AGT 直接生成预取（本配置下该输出口没人接，只剩"不查 PHT"这一效果）
//          不活跃 -> s1_sel_stride 让 stride 预取器接手；并在下一拍发 PHT 查询
//   §S2  输出 s2_evict（送 PHT 学习的项）与 s2_pht_lookup（PHT 查询请求）。
//
// 怪癖（都照 golden，不"修"）：
//   1. valid 位只置不清：dcache 驱逐只是把该项内容送去 PHT，并不释放该项。
//   2. PLRU 访问的路号用 OHToUInt（各位或编码）从命中向量得到 —— 多项同时命中时得到的是
//      各下标的按位或，不是优先级编码。
//   3. alloc 写进去的访问计数恒为 1、has_been_signal_updated 恒为 0（S0 就定了，不占寄存器）。
//   4. s1 里 region_bits 与 region_bit_single 两个寄存器装的是同一个值、region_offset 也存了
//      两份（一份在待写项里、一份跟着 PHT 查询走）—— golden 就是两份，这里一份不少。
//   5. s2_do_evict_q 在 golden 里只喂性能计数器，计数器被删后它成了没人读的寄存器；
//      golden 保留了它，这里也保留（FM 两侧对称的死寄存器）。
//   6. 父模块把 s2_stride_hit 接成常量 0、没接 s2_pf_gen_req 与 s0_dcache_evict.ready，
//      所以这些端口在 golden 里不存在；ready 的逻辑仍在内部决定 evict 是否 fire。
//   7. 只有 valid 类寄存器、PLRU 状态带异步复位；所有数据寄存器不复位。
// =============================================================================

package activegenerationtable_pkg;
  localparam int unsigned NUM_ENTRY     = 16;  // active_gen_table_size
  localparam int unsigned WAY_W         = 4;
  localparam int unsigned REGION_BLKS   = 16;  // 一个区域 1KB = 16 个 64B 块
  localparam int unsigned OFFSET_W      = 4;   // 块在区域内的偏移
  localparam int unsigned REGION_TAG_W  = 11;  // 区域 tag：5 位高位哈希 + 区域地址低 6 位
  localparam int unsigned REGION_ADDR_W = 40;  // 区域地址 = VAddrBits(50) - 10
  localparam int unsigned PHT_INDEX_W   = 5;
  localparam int unsigned PHT_TAG_W     = 13;
  localparam int unsigned HASH_W        = 5;   // vaddr_hash_width

  // 送 PHT 学习的一项（AGTEntry 里 golden 实际保留到 S2 的字段）
  typedef struct packed {
    logic [PHT_INDEX_W-1:0] pht_index;
    logic [PHT_TAG_W-1:0]   pht_tag;
    logic [REGION_BLKS-1:0] region_bits;        // 该区域被访问过的块位图
    logic [REGION_BLKS-1:0] region_bit_single;  // 最近一次访问的那一块（one-hot）
    logic [OFFSET_W-1:0]    region_offset;      // 建项时触发访问的块偏移
    logic [OFFSET_W-1:0]    access_cnt;         // 访问过的不同块数（15 封顶）
    logic                   decr_mode;          // 访问方向向低地址
    logic                   has_been_signal_updated;
  } agt_evict_t;
endpackage

module xs_ActiveGenerationTable_core
  import activegenerationtable_pkg::*;
(
  input  logic                      clock,
  input  logic                      reset,
  input  logic                      agt_en,
  input  logic [OFFSET_W-1:0]       act_threshold,   // 活跃判定门限
  input  logic [5:0]                act_stride,      // AGT 直接预取的步长（块数）
  // ---- S0：训练流查询 ----
  input  logic                      s0_lookup_valid,
  input  logic [REGION_TAG_W-1:0]   s0_region_tag,
  input  logic [REGION_TAG_W-1:0]   s0_region_p1_tag,
  input  logic [REGION_TAG_W-1:0]   s0_region_m1_tag,
  input  logic [OFFSET_W-1:0]       s0_region_offset,
  input  logic [PHT_INDEX_W-1:0]    s0_pht_index,
  input  logic [PHT_TAG_W-1:0]      s0_pht_tag,
  input  logic                      s0_allow_cross_region_p1,
  input  logic                      s0_allow_cross_region_m1,
  input  logic [REGION_ADDR_W-1:0]  s0_region_paddr,
  input  logic [REGION_ADDR_W-1:0]  s0_region_vaddr,
  // ---- S0：dcache 换出一个块 ----
  input  logic                      s0_dcache_evict_valid,
  input  logic [49:0]               s0_dcache_evict_vaddr,
  // ---- S1 / S2 输出 ----
  output logic                      s1_sel_stride,
  output logic                      s2_pht_lookup_valid,
  output logic [PHT_INDEX_W-1:0]    s2_pht_lookup_pht_index,
  output logic [PHT_TAG_W-1:0]      s2_pht_lookup_pht_tag,
  output logic [REGION_ADDR_W-1:0]  s2_pht_lookup_region_paddr,
  output logic [REGION_ADDR_W-1:0]  s2_pht_lookup_region_vaddr,
  output logic [OFFSET_W-1:0]       s2_pht_lookup_region_offset,
  output logic                      s2_evict_valid,
  output agt_evict_t                s2_evict,
  output logic                      s2_evict_single_update
);

  // ===========================================================================
  // 表项存储（按字段分开存；valid 异步复位，其余不复位）
  // ===========================================================================
  logic [NUM_ENTRY-1:0]    valid_q;
  logic [PHT_INDEX_W-1:0]  ent_pht_index_q         [NUM_ENTRY];
  logic [PHT_TAG_W-1:0]    ent_pht_tag_q           [NUM_ENTRY];
  logic [REGION_BLKS-1:0]  ent_region_bits_q       [NUM_ENTRY];
  logic [REGION_BLKS-1:0]  ent_region_bit_single_q [NUM_ENTRY];
  logic [REGION_TAG_W-1:0] ent_region_tag_q        [NUM_ENTRY];
  logic [OFFSET_W-1:0]     ent_region_offset_q     [NUM_ENTRY];
  logic [OFFSET_W-1:0]     ent_access_cnt_q        [NUM_ENTRY];
  logic [NUM_ENTRY-1:0]    ent_decr_mode_q;
  logic [NUM_ENTRY-1:0]    ent_signal_updated_q;

  // one-hot -> 下标，各位或编码（怪癖 2：多热时得到下标的按位或）
  function automatic logic [WAY_W-1:0] onehot_to_index(input logic [NUM_ENTRY-1:0] oh);
    logic [WAY_W-1:0] idx;
    idx = '0;
    for (int i = 0; i < NUM_ENTRY; i++)
      if (oh[i]) idx |= WAY_W'(i);
    return idx;
  endfunction

  // 按掩码"与或"选出一项送 PHT 的内容（Mux1H：多热时各项按位或）
  function automatic agt_evict_t pack_entry(
    input logic [PHT_INDEX_W-1:0] pht_index, input logic [PHT_TAG_W-1:0] pht_tag,
    input logic [REGION_BLKS-1:0] region_bits, input logic [REGION_BLKS-1:0] region_bit_single,
    input logic [OFFSET_W-1:0] region_offset, input logic [OFFSET_W-1:0] access_cnt,
    input logic decr_mode, input logic signal_updated);
    agt_evict_t e;
    e.pht_index               = pht_index;
    e.pht_tag                 = pht_tag;
    e.region_bits             = region_bits;
    e.region_bit_single       = region_bit_single;
    e.region_offset           = region_offset;
    e.access_cnt              = access_cnt;
    e.decr_mode               = decr_mode;
    e.has_been_signal_updated = signal_updated;
    return e;
  endfunction

  // ===========================================================================
  // §S0  查表
  // ===========================================================================
  // dcache 换出块的区域 tag：块地址高 15 位三段异或成 5 位哈希，拼上区域地址低 6 位
  logic [REGION_TAG_W-1:0] s0_evict_tag;
  assign s0_evict_tag = {s0_dcache_evict_vaddr[20:16] ^ s0_dcache_evict_vaddr[25:21]
                           ^ s0_dcache_evict_vaddr[30:26],
                         s0_dcache_evict_vaddr[15:10]};

  logic [NUM_ENTRY-1:0] s0_match, s0_p1_match, s0_m1_match, s0_evict_match;

  always_comb begin
    for (int i = 0; i < NUM_ENTRY; i++) begin
      s0_match[i]       = valid_q[i] && ent_region_tag_q[i] == s0_region_tag;
      s0_p1_match[i]    = valid_q[i] && ent_region_tag_q[i] == s0_region_p1_tag;
      s0_m1_match[i]    = valid_q[i] && ent_region_tag_q[i] == s0_region_m1_tag;
      s0_evict_match[i] = valid_q[i] && ent_region_tag_q[i] == s0_evict_tag;
    end
  end

  logic s0_region_hit, s0_p1_hit, s0_m1_hit;
  assign s0_region_hit = |s0_match;
  assign s0_p1_hit     = (|s0_p1_match) && s0_allow_cross_region_p1;
  assign s0_m1_hit     = (|s0_m1_match) && s0_allow_cross_region_m1;

  // S1 这一拍正要被覆盖 / 驱逐的项（后面 §S1 给出）：S0 不能再去更新或驱逐它
  logic [NUM_ENTRY-1:0] s1_replace_mask_active;

  // 与上一次查询同区域：上一拍已经为它分配过了（要下一拍才写进表），不重复分配
  logic                    prev_lookup_valid_q;
  logic [REGION_TAG_W-1:0] prev_lookup_tag_q;
  logic                    s0_match_prev;
  assign s0_match_prev = prev_lookup_valid_q && s0_region_tag == prev_lookup_tag_q;

  logic s0_alloc, s0_update;
  assign s0_alloc  = s0_lookup_valid && !s0_region_hit && !s0_match_prev;
  assign s0_update = s0_lookup_valid && s0_region_hit && !(|(s0_match & s1_replace_mask_active));

  // dcache 驱逐：查询优先；命中的项正在被 S1 处理时也不接
  logic s0_dcache_evict_ready, s0_do_dcache_evict;
  assign s0_dcache_evict_ready = !s0_lookup_valid && !(|(s0_evict_match & s1_replace_mask_active));
  assign s0_do_dcache_evict    = s0_dcache_evict_valid && s0_dcache_evict_ready && (|s0_evict_match);

  // 用哪一项的访问计数来判断"活跃"：本区域命中项，否则 -1 邻区命中项，否则 +1 邻区命中项
  logic [NUM_ENTRY-1:0] s0_pf_gen_match;
  assign s0_pf_gen_match = s0_region_hit ? s0_match : (s0_m1_hit ? s0_m1_match : s0_p1_match);

  // 新项的访问方向：本区域和 -1 邻区都没记录、+1 邻区有记录 -> 访问是从高往低走的
  logic s0_decr_mode;
  assign s0_decr_mode = !s0_region_hit && !s0_m1_hit && s0_p1_hit;

  // PLRU：update 触碰命中项，alloc 触碰被选中的替换项
  logic [WAY_W-1:0] s0_replace_way, s0_access_way;
  assign s0_access_way = ({WAY_W{s0_update}} & onehot_to_index(s0_match))
                       | ({WAY_W{s0_alloc}}  & s0_replace_way);

  xs_PlruReplacer #(.NUM_WAYS(NUM_ENTRY)) u_plru (
    .clock       (clock),
    .reset       (reset),
    .touch_valid (s0_update || s0_alloc),
    .touch_way   (s0_access_way),
    .replace_way (s0_replace_way)
  );

  // ===========================================================================
  // S0 -> S1 寄存器
  // ===========================================================================
  logic                     s1_update_q, s1_alloc_q, s1_do_dcache_evict_q;   // 异步复位
  logic [NUM_ENTRY-1:0]     s1_update_mask_q;       // 命中项（update 写谁）
  logic [NUM_ENTRY-1:0]     s1_plru_mask_q;         // PLRU 选中的替换项（alloc 写谁）
  logic [NUM_ENTRY-1:0]     s1_evict_mask_q;        // dcache 驱逐命中的项
  logic [NUM_ENTRY-1:0]     s1_pf_gen_match_q;
  logic                     s1_cross_region_match_q;
  // 待写入的新项（怪癖 3/4）
  logic [PHT_INDEX_W-1:0]   s1_ent_pht_index_q;
  logic [PHT_TAG_W-1:0]     s1_ent_pht_tag_q;
  logic [REGION_BLKS-1:0]   s1_ent_region_bits_q;
  logic [REGION_BLKS-1:0]   s1_ent_region_bit_single_q;
  logic [REGION_TAG_W-1:0]  s1_ent_region_tag_q;
  logic [OFFSET_W-1:0]      s1_ent_region_offset_q;
  logic                     s1_ent_decr_mode_q;
  // 跟着 PHT 查询走的地址
  logic [REGION_ADDR_W-1:0] s1_region_paddr_q, s1_region_vaddr_q;
  logic [OFFSET_W-1:0]      s1_region_offset_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      prev_lookup_valid_q  <= 1'b0;
      s1_update_q          <= 1'b0;
      s1_alloc_q           <= 1'b0;
      s1_do_dcache_evict_q <= 1'b0;
    end else begin
      prev_lookup_valid_q  <= s0_lookup_valid;
      s1_update_q          <= s0_update;
      s1_alloc_q           <= s0_alloc;
      s1_do_dcache_evict_q <= s0_do_dcache_evict;
    end
  end

  always_ff @(posedge clock) begin
    if (s0_lookup_valid) begin
      prev_lookup_tag_q          <= s0_region_tag;
      s1_update_mask_q           <= s0_match;
      s1_plru_mask_q             <= NUM_ENTRY'(1) << s0_replace_way;
      s1_pf_gen_match_q          <= s0_pf_gen_match;
      s1_cross_region_match_q    <= s0_m1_hit || s0_p1_hit;
      s1_ent_pht_index_q         <= s0_pht_index;
      s1_ent_pht_tag_q           <= s0_pht_tag;
      s1_ent_region_bits_q       <= REGION_BLKS'(1) << s0_region_offset;
      s1_ent_region_bit_single_q <= REGION_BLKS'(1) << s0_region_offset;
      s1_ent_region_tag_q        <= s0_region_tag;
      s1_ent_region_offset_q     <= s0_region_offset;
      s1_ent_decr_mode_q         <= s0_decr_mode;
      s1_region_paddr_q          <= s0_region_paddr;
      s1_region_vaddr_q          <= s0_region_vaddr;
      s1_region_offset_q         <= s0_region_offset;
    end
    if (s0_do_dcache_evict) s1_evict_mask_q <= s0_evict_match;
  end

  // ===========================================================================
  // §S1-a  执行 update / alloc
  // ===========================================================================
  logic [NUM_ENTRY-1:0] s1_replace_mask;
  logic                 s1_replacing;     // 本拍有项被覆盖（alloc）或被 dcache 驱逐
  logic                 s1_evict_valid;   // 被覆盖 / 驱逐的那一项原本有效 -> 它的内容要送 PHT

  assign s1_replace_mask        = s1_do_dcache_evict_q ? s1_evict_mask_q : s1_plru_mask_q;
  assign s1_replacing           = s1_alloc_q || s1_do_dcache_evict_q;
  assign s1_replace_mask_active = s1_replace_mask & {NUM_ENTRY{s1_replacing}};
  assign s1_evict_valid         = |(s1_replace_mask & valid_q);

  logic [NUM_ENTRY-1:0] s1_alloc_vec, s1_update_vec;
  assign s1_alloc_vec  = s1_replace_mask  & {NUM_ENTRY{s1_alloc_q}};
  assign s1_update_vec = s1_update_mask_q & {NUM_ENTRY{s1_update_q}};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid_q <= '0;
    else       valid_q <= valid_q | s1_alloc_vec;   // 怪癖 1：只置不清
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < NUM_ENTRY; i++) begin
      if (s1_alloc_vec[i]) begin
        // 分配：整项覆盖；访问计数从 1 起
        ent_pht_index_q[i]     <= s1_ent_pht_index_q;
        ent_pht_tag_q[i]       <= s1_ent_pht_tag_q;
        ent_region_bits_q[i]   <= s1_ent_region_bits_q;
        ent_region_tag_q[i]    <= s1_ent_region_tag_q;
        ent_region_offset_q[i] <= s1_ent_region_offset_q;
        ent_access_cnt_q[i]    <= OFFSET_W'(1);
        ent_decr_mode_q[i]     <= s1_ent_decr_mode_q;
      end else if (s1_update_vec[i]) begin
        // 更新：新块并入位图；碰到的是新块才计数，15 封顶
        ent_region_bits_q[i] <= ent_region_bits_q[i] | s1_ent_region_bits_q;
        if (ent_access_cnt_q[i] != '1)
          ent_access_cnt_q[i] <= ent_access_cnt_q[i]
                               + OFFSET_W'(|(s1_ent_region_bits_q & ~ent_region_bits_q[i]));
      end
      if (s1_alloc_vec[i] || s1_update_vec[i])
        ent_region_bit_single_q[i] <= s1_ent_region_bit_single_q;
      // "曾经被单次更新过"：update 且本拍没有别的有效项被换出去 PHT（那样 S2 口被占用）
      ent_signal_updated_q[i] <= !s1_alloc_vec[i]
                              && ((s1_update_vec[i] && !(s1_replacing && s1_evict_valid))
                                  || ent_signal_updated_q[i]);
    end
  end

  // ===========================================================================
  // §S1-b  活跃判定与 PHT 查询
  // ===========================================================================
  // 访问方向：update 用命中项记录的方向，alloc 用 S0 推断的方向
  logic s1_hit_entry_decr, s1_pf_gen_decr_mode;
  assign s1_hit_entry_decr   = |(s1_update_mask_q & ent_decr_mode_q);
  assign s1_pf_gen_decr_mode = s1_update_q ? s1_hit_entry_decr : s1_ent_decr_mode_q;

  // AGT 直接预取的目标块 = 当前块 ± act_stride，只在 tag 覆盖的地址范围内（11 位区域号 +
  // 4 位偏移）算；多拼的最高位用来看有没有越出这个范围（越出则不预取）
  logic [REGION_TAG_W+OFFSET_W:0] s1_blk, s1_blk_inc, s1_blk_dec;
  assign s1_blk     = {1'b0, s1_region_vaddr_q[REGION_TAG_W-1:0], s1_region_offset_q};
  assign s1_blk_inc = s1_blk + (REGION_TAG_W+OFFSET_W+1)'(act_stride);
  assign s1_blk_dec = s1_blk - (REGION_TAG_W+OFFSET_W+1)'(act_stride);

  logic s1_pf_gen_out_of_range;
  assign s1_pf_gen_out_of_range = s1_pf_gen_decr_mode ? s1_blk_dec[REGION_TAG_W+OFFSET_W]
                                                      : s1_blk_inc[REGION_TAG_W+OFFSET_W];

  logic [OFFSET_W-1:0] s1_pf_gen_access_cnt;
  logic                s1_in_active_page;

  always_comb begin
    s1_pf_gen_access_cnt = '0;
    for (int i = 0; i < NUM_ENTRY; i++)
      if (s1_pf_gen_match_q[i]) s1_pf_gen_access_cnt |= ent_access_cnt_q[i];
  end
  assign s1_in_active_page = s1_pf_gen_access_cnt > act_threshold;

  // 本次查询有可依据的记录：命中更新，或新分配但相邻区域有记录
  logic s1_has_history, s1_pf_gen_valid, s1_pht_lookup_valid;
  assign s1_has_history      = prev_lookup_valid_q && ((s1_alloc_q && s1_cross_region_match_q) || s1_update_q);
  assign s1_pf_gen_valid     = s1_has_history && !s1_pf_gen_out_of_range && s1_in_active_page && agt_en;
  assign s1_pht_lookup_valid = !s1_pf_gen_valid && prev_lookup_valid_q;
  assign s1_sel_stride       = s1_has_history && !s1_in_active_page;

  // ===========================================================================
  // §S1-c  送 PHT 学习的项：有效项被换出则送它，否则送本次被更新的项
  // ===========================================================================
  logic       s1_send_replaced;
  agt_evict_t s1_send_entry;

  assign s1_send_replaced = s1_replacing && s1_evict_valid;

  always_comb begin
    logic [NUM_ENTRY-1:0] sel;
    sel           = s1_send_replaced ? s1_replace_mask : s1_update_mask_q;
    s1_send_entry = '0;
    for (int i = 0; i < NUM_ENTRY; i++) begin
      if (sel[i])
        s1_send_entry |= pack_entry(ent_pht_index_q[i], ent_pht_tag_q[i], ent_region_bits_q[i],
                                    ent_region_bit_single_q[i], ent_region_offset_q[i],
                                    ent_access_cnt_q[i], ent_decr_mode_q[i], ent_signal_updated_q[i]);
    end
  end

  // ===========================================================================
  // S1 -> S2 寄存器与输出
  // ===========================================================================
  logic                     s2_evict_valid_q, s2_update_q, s2_real_update_q;   // 异步复位
  logic                     s2_pht_lookup_valid_q, s2_do_evict_q;              // 异步复位
  // 送 PHT 的项：按字段分开存（与 golden 的寄存器一一对应）
  logic [PHT_INDEX_W-1:0]   s2_evict_pht_index_q;
  logic [PHT_TAG_W-1:0]     s2_evict_pht_tag_q;
  logic [REGION_BLKS-1:0]   s2_evict_region_bits_q;
  logic [REGION_BLKS-1:0]   s2_evict_region_bit_single_q;
  logic [OFFSET_W-1:0]      s2_evict_region_offset_q;
  logic [OFFSET_W-1:0]      s2_evict_access_cnt_q;
  logic                     s2_evict_decr_mode_q;
  logic                     s2_evict_signal_updated_q;
  logic [PHT_INDEX_W-1:0]   s2_pht_index_q;
  logic [PHT_TAG_W-1:0]     s2_pht_tag_q;
  logic [REGION_ADDR_W-1:0] s2_region_paddr_q, s2_region_vaddr_q;
  logic [OFFSET_W-1:0]      s2_region_offset_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_do_evict_q         <= 1'b0;
      s2_evict_valid_q      <= 1'b0;
      s2_update_q           <= 1'b0;
      s2_real_update_q      <= 1'b0;
      s2_pht_lookup_valid_q <= 1'b0;
    end else begin
      s2_do_evict_q         <= s1_do_dcache_evict_q;   // 怪癖 5：没人读
      s2_evict_valid_q      <= s1_send_replaced || s1_update_q;
      s2_update_q           <= s1_update_q;
      s2_real_update_q      <= s1_send_replaced;
      s2_pht_lookup_valid_q <= s1_pht_lookup_valid;
    end
  end

  always_ff @(posedge clock) begin
    if (s1_replacing || s1_update_q) begin
      s2_evict_pht_index_q         <= s1_send_entry.pht_index;
      s2_evict_pht_tag_q           <= s1_send_entry.pht_tag;
      s2_evict_region_bits_q       <= s1_send_entry.region_bits;
      s2_evict_region_bit_single_q <= s1_send_entry.region_bit_single;
      s2_evict_region_offset_q     <= s1_send_entry.region_offset;
      s2_evict_access_cnt_q        <= s1_send_entry.access_cnt;
      s2_evict_decr_mode_q         <= s1_send_entry.decr_mode;
      s2_evict_signal_updated_q    <= s1_send_entry.has_been_signal_updated;
    end
    if (s1_pht_lookup_valid) begin
      s2_pht_index_q     <= s1_ent_pht_index_q;
      s2_pht_tag_q       <= s1_ent_pht_tag_q;
      s2_region_paddr_q  <= s1_region_paddr_q;
      s2_region_vaddr_q  <= s1_region_vaddr_q;
      s2_region_offset_q <= s1_region_offset_q;
    end
  end

  assign s2_pht_lookup_valid         = s2_pht_lookup_valid_q;
  assign s2_pht_lookup_pht_index     = s2_pht_index_q;
  assign s2_pht_lookup_pht_tag       = s2_pht_tag_q;
  assign s2_pht_lookup_region_paddr  = s2_region_paddr_q;
  assign s2_pht_lookup_region_vaddr  = s2_region_vaddr_q;
  assign s2_pht_lookup_region_offset = s2_region_offset_q;

  // 换出的项只访问过一个块（one-hot 位图）就不值得让 PHT 学；"更新"类的照送
  assign s2_evict_valid         = s2_evict_valid_q && (!s2_real_update_q || s2_evict_access_cnt_q > OFFSET_W'(1));
  assign s2_evict               = pack_entry(s2_evict_pht_index_q, s2_evict_pht_tag_q, s2_evict_region_bits_q,
                                             s2_evict_region_bit_single_q, s2_evict_region_offset_q,
                                             s2_evict_access_cnt_q, s2_evict_decr_mode_q,
                                             s2_evict_signal_updated_q);
  assign s2_evict_single_update = s2_update_q && !s2_real_update_q;

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位同 golden，只做改名与结构体拆装。
// -----------------------------------------------------------------------------
module ActiveGenerationTable
  import activegenerationtable_pkg::*;
(
  input         clock,
  input         reset,
  input         io_agt_en,
  input         io_s0_lookup_valid,
  input  [10:0] io_s0_lookup_bits_region_tag,
  input  [10:0] io_s0_lookup_bits_region_p1_tag,
  input  [10:0] io_s0_lookup_bits_region_m1_tag,
  input  [3:0]  io_s0_lookup_bits_region_offset,
  input  [4:0]  io_s0_lookup_bits_pht_index,
  input  [12:0] io_s0_lookup_bits_pht_tag,
  input         io_s0_lookup_bits_allow_cross_region_p1,
  input         io_s0_lookup_bits_allow_cross_region_m1,
  input  [39:0] io_s0_lookup_bits_region_paddr,
  input  [39:0] io_s0_lookup_bits_region_vaddr,
  input         io_s0_dcache_evict_valid,
  input  [49:0] io_s0_dcache_evict_bits_vaddr,
  output        io_s1_sel_stride,
  output        io_s2_pht_lookup_valid,
  output [4:0]  io_s2_pht_lookup_bits_pht_index,
  output [12:0] io_s2_pht_lookup_bits_pht_tag,
  output [39:0] io_s2_pht_lookup_bits_region_paddr,
  output [39:0] io_s2_pht_lookup_bits_region_vaddr,
  output [3:0]  io_s2_pht_lookup_bits_region_offset,
  output        io_s2_evict_valid,
  output [4:0]  io_s2_evict_bits_pht_index,
  output [12:0] io_s2_evict_bits_pht_tag,
  output [15:0] io_s2_evict_bits_region_bits,
  output [15:0] io_s2_evict_bits_region_bit_single,
  output [3:0]  io_s2_evict_bits_region_offset,
  output [3:0]  io_s2_evict_bits_access_cnt,
  output        io_s2_evict_bits_decr_mode,
  output        io_s2_evict_bits_single_update,
  output        io_s2_evict_bits_has_been_signal_updated,
  input  [3:0]  io_act_threshold,
  input  [5:0]  io_act_stride
);

  agt_evict_t s2_evict;

  xs_ActiveGenerationTable_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .agt_en                      (io_agt_en),
    .act_threshold               (io_act_threshold),
    .act_stride                  (io_act_stride),
    .s0_lookup_valid             (io_s0_lookup_valid),
    .s0_region_tag               (io_s0_lookup_bits_region_tag),
    .s0_region_p1_tag            (io_s0_lookup_bits_region_p1_tag),
    .s0_region_m1_tag            (io_s0_lookup_bits_region_m1_tag),
    .s0_region_offset            (io_s0_lookup_bits_region_offset),
    .s0_pht_index                (io_s0_lookup_bits_pht_index),
    .s0_pht_tag                  (io_s0_lookup_bits_pht_tag),
    .s0_allow_cross_region_p1    (io_s0_lookup_bits_allow_cross_region_p1),
    .s0_allow_cross_region_m1    (io_s0_lookup_bits_allow_cross_region_m1),
    .s0_region_paddr             (io_s0_lookup_bits_region_paddr),
    .s0_region_vaddr             (io_s0_lookup_bits_region_vaddr),
    .s0_dcache_evict_valid       (io_s0_dcache_evict_valid),
    .s0_dcache_evict_vaddr       (io_s0_dcache_evict_bits_vaddr),
    .s1_sel_stride               (io_s1_sel_stride),
    .s2_pht_lookup_valid         (io_s2_pht_lookup_valid),
    .s2_pht_lookup_pht_index     (io_s2_pht_lookup_bits_pht_index),
    .s2_pht_lookup_pht_tag       (io_s2_pht_lookup_bits_pht_tag),
    .s2_pht_lookup_region_paddr  (io_s2_pht_lookup_bits_region_paddr),
    .s2_pht_lookup_region_vaddr  (io_s2_pht_lookup_bits_region_vaddr),
    .s2_pht_lookup_region_offset (io_s2_pht_lookup_bits_region_offset),
    .s2_evict_valid              (io_s2_evict_valid),
    .s2_evict                    (s2_evict),
    .s2_evict_single_update      (io_s2_evict_bits_single_update)
  );

  assign io_s2_evict_bits_pht_index               = s2_evict.pht_index;
  assign io_s2_evict_bits_pht_tag                 = s2_evict.pht_tag;
  assign io_s2_evict_bits_region_bits             = s2_evict.region_bits;
  assign io_s2_evict_bits_region_bit_single       = s2_evict.region_bit_single;
  assign io_s2_evict_bits_region_offset           = s2_evict.region_offset;
  assign io_s2_evict_bits_access_cnt              = s2_evict.access_cnt;
  assign io_s2_evict_bits_decr_mode               = s2_evict.decr_mode;
  assign io_s2_evict_bits_has_been_signal_updated = s2_evict.has_been_signal_updated;

endmodule
