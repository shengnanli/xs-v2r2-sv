// =============================================================================
//  StreamBitVectorArray.sv —— L1 流式预取器的「区域位向量表」（stream 训练与触发）
// -----------------------------------------------------------------------------
//  位置：MemBlock / L1Prefetcher(L1PrefetcherSMS 之外的 stream 部分) 里的 stream_bit_vec_array。
//  输入：io_train_req —— load 流水线送来的训练访问（虚地址 vaddr、是否 miss、是否命中过 stream 预取）；
//        io_stream_lookup_req —— stride 预取器来问「这个地址所在区域是不是已经被 stream 接管了」。
//  输出：io_l1_prefetch_req（预取进 L1）、io_l2_l3_prefetch_req（预取进 L2，L3 那路在本配置关掉）、
//        io_stream_lookup_resp（三拍后回答 stride）。下游是 MutiLevelPrefetchFilter。
//
//  核心机制：
//    · 把虚地址按 1KB 切成区域（region = vaddr[49:10]），区域里 16 条 64B cacheline 用一个
//      16 位 bit_vec 记「哪些行被访问过」，cnt 记访问过的不同行数。表有 16 项，PLRU 替换。
//    · 区域里访问过的行数 ≥ 12（ACTIVE_THRESHOLD）→ 该区域 active（判定为流）；
//      或者新区域入表/更新时，它的「前一个 / 后一个」区域已经 active 且 cnt ≥ 12 → 直接 active
//      （流从相邻区域延续过来）。
//    · 训练访问命中 active 区域、且访问的是一条新行（或新分配）、且是 miss / 命中预取（strict 触发）
//      → 发预取：L1 预取 = 当前块地址 + 64 行（4KB 之外），宽 2 行；L2 预取 = + 640 行，宽 4 行。
//
//  流水线（训练路径）：
//    s0 区域哈希 CAM（本区域 / +1 区域 / -1 区域三路并行），选项号（命中项或 PLRU 替换项），
//       与 s1 同哈希的请求反压（ready=0，避免同一区域两拍连续入表造成重复项）
//    s1 写表：不中则 alloc 整项覆盖，命中则 update（并 bit_vec、cnt 计数、可能置 active）；
//       同拍算好三个预取目标地址
//    s2 读本项 active，决定是否发预取（受 io_enable 门控）
//    s3 发 L1 预取；s4 发 L2 预取；s5 的 L3 预取在本配置恒不发（enableL3StreamPrefetch=false）
//  查询路径（stride 来问）：s1 CAM → s2 读 active → s3 回答。
//
//  怪癖（都照 golden 写）：
//    · 区域哈希只用 region 的低 25 位（{[24:20]^[19:15]^[14:10], [9:0]}），哈希冲突的两个区域
//      被当成同一项；表项 tag 仍存满 40 位（高 15 位没有读者）。
//    · OHToUInt 在多命中时返回各命中下标的按位 OR（不是最低位）。
//    · decr_mode 恒 false（ENABLE_DECR_MODE=false）：只有「向前」预取，decr 地址在 golden 里已被删。
//    · io.flush 被上层接成常 0（golden 无此端口），但每项一份「打一拍再清 valid」寄存器仍在（D 恒 0）。
//    · 3 个只喂断言的寄存器（RegNext(s0_valid) / RegEnable(s0_hit) / RegEnable(PLRU 替换路)）、
//      s2_region_tag（只喂 hash_conflict 性能计数器）在综合口径下都无读者，照抄。
//    · 预取地址寄存器存满 50 位，低 6 位恒 0。
//
//  文件结构（单文件规范）：streambitvectorarray_pkg → xs_StreamBitVectorArray_core（可读核）
//    → StreamBitVectorArray（golden 同名 wrapper，端口逐位同名同序）。
//  子模块：无（golden 0 child）。PLRU 用共享辅助件 rtl/common/xs_PlruReplacer.sv（与 rocket-chip
//    PseudoLRU 状态编码一致；golden 里它被内联成 state_reg）。
//  设计源：src/main/scala/xiangshan/mem/prefetch/L1StreamPrefetcher.scala（class StreamBitVectorArray）
// =============================================================================

// =============================================================================
//  streambitvectorarray_pkg —— 位宽常量 / 纯函数
// =============================================================================
package streambitvectorarray_pkg;

  // ---- 地址切分 ---------------------------------------------------------------
  //  vaddr(50 位) = | region(40) | 区域内行号(4) | 行内偏移(6) |
  localparam int VADDR_W   = 50;
  localparam int REGION_W  = 40;                 // REGION_TAG_BITS
  localparam int LINE_W    = 4;                  // REGION_BITS：区域内 16 行
  localparam int BITVEC_W  = 16;                 // BIT_VEC_WITDH
  localparam int BLK_OFF_W = 6;                  // log2(64B)
  localparam int BLK_W     = REGION_W + LINE_W;  // 块地址（vaddr[49:6]）44 位
  localparam int HASH_W    = 15;                 // HASH_TAG_WIDTH = 5(哈希) + 10(原样低位)

  // ---- 容量与阈值 --------------------------------------------------------------
  localparam int ARRAY_SIZE = 16;                // BIT_VEC_ARRAY_SIZE
  localparam int IDX_W      = 4;
  localparam int CNT_W      = 5;                 // log2Up(16)+1
  localparam logic [CNT_W-1:0] ACTIVE_THRESHOLD = 5'd12;   // BIT_VEC_WITDH - 4

  // ---- 预取深度/宽度（USE_STREAM_FIXED_DEPTH：Constantin 初值，综合口径下是常量）----
  localparam logic [BLK_W-1:0] L1_DEPTH = 44'd64;    // streamL1Depth：向前 64 行 = 4KB
  localparam logic [BLK_W-1:0] L2_DEPTH = 44'd640;   // streamL2Depth
  localparam logic [BLK_W-1:0] L3_DEPTH = 44'd640;   // streamL3Depth
  localparam int L1_WIDTH = 2;                       // WIDTH_BYTES 128B / 64B
  localparam int L2_WIDTH = 4;                       // 256B
  localparam int L3_WIDTH = 8;                       // 512B

  // ---- sink：预取目标层级 -------------------------------------------------------
  localparam logic [1:0] SINK_L2 = 2'd1;
  localparam logic [1:0] SINK_L3 = 2'd2;

  // ---- 纯函数 ------------------------------------------------------------------
  // 区域哈希（region_hash_tag）：低 10 位原样，再把 [24:10] 三段 5 位异或成 5 位。
  //   region[39:25] 不参与 —— 只差高位的两个区域哈希相同，在表里被当成「同一项」。
  function automatic logic [HASH_W-1:0] region_hash_tag(input logic [REGION_W-1:0] r);
    return {r[14:10] ^ r[19:15] ^ r[24:20], r[9:0]};
  endfunction

  // OHToUInt：Chisel 的实现是「高低半折叠 OR」，展开后 = 所有置位下标按位 OR。
  function automatic logic [IDX_W-1:0] oh_to_uint(input logic [ARRAY_SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < ARRAY_SIZE; k++)
      if (oh[k]) r |= IDX_W'(k);
    return r;
  endfunction

  // 区域内第 line 行的独热码（UIntToOH(region_bits)）
  function automatic logic [BITVEC_W-1:0] line_oh(input logic [LINE_W-1:0] line);
    return BITVEC_W'(1) << line;
  endfunction

  // 预取位向量（getStreamPrefetchReqBundle，incr 模式）：从目标行起向高地址连续 width 行，
  //   超出区域（第 15 行之后）的部分直接截掉，不会跨到下一个区域。
  function automatic logic [BITVEC_W-1:0] pf_bit_vec(input logic [LINE_W-1:0] line, input int width);
    logic [BITVEC_W-1:0] v;
    v = '0;
    for (int k = 0; k < width; k++)
      v |= line_oh(line) << k;
    return v;
  endfunction

endpackage

// =============================================================================
//  xs_StreamBitVectorArray_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 表项  §2 s0 查表与选项号  §3 s1 写表  §4 s2 触发判定  §5 s3~s5 发出
//        §6 stride 查询  §7 只喂断言/性能计数器的寄存器
//  表项用 generate 块 array[i] 表达（golden 展平名 array_<i>_<字段>），逐项寄存器与 golden 一一对应。
// =============================================================================
module xs_StreamBitVectorArray_core
  import streambitvectorarray_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  input  logic                enable,          // 预取总开关：只门控「发预取」，不门控训练
  input  logic                flush,           // 清表（本配置上层接常 0，见 wrapper）
  // 训练访问
  output logic                train_req_ready,
  input  logic                train_req_valid,
  input  logic [VADDR_W-1:0]  train_req_vaddr,
  input  logic                train_req_miss,          // 这次访问 DCache miss
  input  logic                train_req_pfHitStream,   // 这次访问命中了 stream 预取进来的行
  // 预取请求
  output logic                l1_pf_valid,
  output logic [REGION_W-1:0] l1_pf_region,
  output logic [BITVEC_W-1:0] l1_pf_bit_vec,
  output logic                l2_l3_pf_valid,
  output logic [REGION_W-1:0] l2_l3_pf_region,
  output logic [BITVEC_W-1:0] l2_l3_pf_bit_vec,
  output logic [1:0]          l2_l3_pf_sink,
  // stride 查询
  input  logic                lookup_valid,
  input  logic [VADDR_W-1:0]  lookup_vaddr,
  output logic                lookup_resp
);

  // ---------------------------------------------------------------------------
  //  跨节信号
  // ---------------------------------------------------------------------------
  logic                  s0_valid;                    // 训练请求本拍真的进流水（= train_req.fire）
  logic [HASH_W-1:0]     s0_hash, s0_plus_one_hash, s0_minus_one_hash;
  logic [IDX_W-1:0]      s0_index;
  logic                  s0_hit, s0_plus_one_hit, s0_minus_one_hit;
  logic [IDX_W-1:0]      s0_plus_one_index, s0_minus_one_index;
  logic [IDX_W-1:0]      plru_way;                    // PLRU 建议替换的项

  logic                  s1_valid_last_REG;           // s1 有效
  logic [IDX_W-1:0]      s1_index;
  logic                  s1_miss, s1_pfHit, s1_hit;
  logic [IDX_W-1:0]      s1_plus_one_index, s1_minus_one_index;
  logic                  s1_plus_one_hit_r, s1_minus_one_hit_r;   // s0 的邻区命中，打一拍
  logic [REGION_W-1:0]   s1_region_tag;
  logic [LINE_W-1:0]     s1_region_bits;
  logic                  s1_alloc, s1_update;
  logic                  s1_neighbor_active;          // 相邻区域已是活跃流 → 本项直接 active
  logic [BITVEC_W-1:0]   s1_line_oh;

  logic                  s1_lookup_valid_last_REG;
  logic [REGION_W-1:0]   s1_lookup_tag;

  // 每一项对外导出的视图
  logic                  valids        [ARRAY_SIZE];
  logic [ARRAY_SIZE-1:0] e_active;
  logic [CNT_W-1:0]      e_cnt         [ARRAY_SIZE];
  logic [BITVEC_W-1:0]   e_bit_vec     [ARRAY_SIZE];
  logic [ARRAY_SIZE-1:0] s0_match_vec, s0_plus_one_match_vec, s0_minus_one_match_vec;
  logic [ARRAY_SIZE-1:0] s1_lookup_match_vec;

  // ===========================================================================
  //  §1 表项（StreamBitVectorBundle）
  // ---------------------------------------------------------------------------
  //    tag      区域地址（40 位存满，CAM 只比它的 15 位哈希）
  //    bit_vec  区域里访问过的行
  //    active   这个区域被判定为一条流
  //    cnt      访问过的不同行数（5 位，最多 16）
  //  valid 异步复位；其余字段不复位（valid=0 时不被看）。decr_mode/trigger_full_va 在本配置被删。
  //  last_REG = RegNext(flush)，每项一份（golden 的 for 循环里各生成一份），下一拍清本项 valid。
  // ===========================================================================
  for (genvar i = 0; i < ARRAY_SIZE; i++) begin : array
    logic [REGION_W-1:0] tag;
    logic [BITVEC_W-1:0] bit_vec;
    logic                active;
    logic [CNT_W-1:0]    cnt;
    logic                last_REG;     // golden 名 last_REG（i=0）/ last_REG_<i>

    wire s1_is_me = (s1_index == IDX_W'(i));

    // update：这一行之前没访问过才计数；计数到阈值或邻区活跃就置 active（只置不清）
    wire             cnt_en   = ~|(bit_vec & s1_line_oh);
    wire [CNT_W-1:0] cnt_next = cnt_en ? CNT_W'(cnt + 1'b1) : cnt;

    always_ff @(posedge clock) begin
      if (s1_alloc & s1_is_me) begin
        tag     <= s1_region_tag;
        bit_vec <= s1_line_oh;
        active  <= s1_neighbor_active;
        cnt     <= CNT_W'(1);
      end else if (s1_update & s1_is_me) begin
        bit_vec <= bit_vec | s1_line_oh;
        cnt     <= cnt_next;
        if ((cnt_next >= ACTIVE_THRESHOLD) | s1_neighbor_active)
          active <= 1'b1;
      end
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        valids[i] <= 1'b0;
        last_REG  <= 1'b0;
      end else begin
        last_REG <= flush;
        // 冲刷（打一拍）优先于分配
        valids[i] <= ~last_REG & ((s1_alloc & s1_is_me) | valids[i]);
      end
    end

    // ---- 本项对外的视图 ----
    assign e_active[i]  = active;
    assign e_cnt[i]     = cnt;
    assign e_bit_vec[i] = bit_vec;
    // tag_match：valid && 请求有效 && 哈希相等
    assign s0_match_vec[i]           = valids[i] & s0_valid & (region_hash_tag(tag) == s0_hash);
    assign s0_plus_one_match_vec[i]  = valids[i] & s0_valid & (region_hash_tag(tag) == s0_plus_one_hash);
    assign s0_minus_one_match_vec[i] = valids[i] & s0_valid & (region_hash_tag(tag) == s0_minus_one_hash);
    assign s1_lookup_match_vec[i]    = valids[i] & s1_lookup_valid_last_REG
                                       & (region_hash_tag(tag) == region_hash_tag(s1_lookup_tag));
  end

  // ===========================================================================
  //  §2 s0：区域哈希 CAM（本区域 / +1 / -1），选项号，反压
  // ---------------------------------------------------------------------------
  //  s1 正在写的区域与本请求哈希相同 → 本拍不收（ready=0）：否则 s1 还没写进表，
  //  s0 查不到，会给同一区域再分配一项。
  //  不中时用 PLRU 的替换路；只要 s0 有效就 touch PLRU（命中也 touch）。
  // ===========================================================================
  wire [REGION_W-1:0] s0_region_tag = train_req_vaddr[VADDR_W-1 -: REGION_W];

  assign train_req_ready = ~(s1_valid_last_REG & (region_hash_tag(s1_region_tag) == region_hash_tag(s0_region_tag)));
  assign s0_valid        = train_req_valid & train_req_ready;

  assign s0_hash           = region_hash_tag(s0_region_tag);
  assign s0_plus_one_hash  = region_hash_tag(REGION_W'(s0_region_tag + 1'b1));
  assign s0_minus_one_hash = region_hash_tag(REGION_W'(s0_region_tag - 1'b1));

  assign s0_hit             = |s0_match_vec;
  assign s0_plus_one_hit    = |s0_plus_one_match_vec;
  assign s0_minus_one_hit   = |s0_minus_one_match_vec;
  assign s0_index           = s0_hit ? oh_to_uint(s0_match_vec) : plru_way;
  assign s0_plus_one_index  = oh_to_uint(s0_plus_one_match_vec);
  assign s0_minus_one_index = oh_to_uint(s0_minus_one_match_vec);

  // golden 名 state_reg：15 位 PLRU 树，异步复位成 0
  xs_PlruReplacer #(.NUM_WAYS(ARRAY_SIZE)) u_plru (
    .clock       (clock),
    .reset       (reset),
    .touch_valid (s0_valid),
    .touch_way   (s0_index),
    .replace_way (plru_way)
  );

  // ===========================================================================
  //  §3 s1：写表
  // ---------------------------------------------------------------------------
  //  邻区命中要在 s1 再确认一次「邻区那一项现在 active 且 cnt ≥ 阈值」（ENABLE_STRICT_ACTIVE_DETECTION）。
  //  alloc：valid 置 1、整项覆盖、cnt=1；update：见 §1。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid_last_REG <= 1'b0;
    else       s1_valid_last_REG <= s0_valid;
  end

  always_ff @(posedge clock) begin
    if (s0_valid) begin
      s1_index           <= s0_index;
      s1_miss            <= train_req_miss;
      s1_pfHit           <= train_req_pfHitStream;
      s1_plus_one_index  <= s0_plus_one_index;
      s1_minus_one_index <= s0_minus_one_index;
      s1_hit             <= s0_hit;
      s1_plus_one_hit_r  <= s0_plus_one_hit;
      s1_minus_one_hit_r <= s0_minus_one_hit;
      s1_region_tag      <= s0_region_tag;
      s1_region_bits     <= train_req_vaddr[BLK_OFF_W +: LINE_W];
    end
  end

  wire s1_plus_one_hit  = s1_plus_one_hit_r  & e_active[s1_plus_one_index]
                          & (e_cnt[s1_plus_one_index]  >= ACTIVE_THRESHOLD);
  wire s1_minus_one_hit = s1_minus_one_hit_r & e_active[s1_minus_one_index]
                          & (e_cnt[s1_minus_one_index] >= ACTIVE_THRESHOLD);

  assign s1_neighbor_active = s1_plus_one_hit | s1_minus_one_hit;
  assign s1_alloc           = s1_valid_last_REG & ~s1_hit;
  assign s1_update          = s1_valid_last_REG & s1_hit;
  assign s1_line_oh         = line_oh(s1_region_bits);

  // 三个预取目标：当前块地址向前 depth 行，再补 6 位行内偏移 0
  wire [BLK_W-1:0] s1_blk_addr = {s1_region_tag, s1_region_bits};

  // 能否触发：update 时要求这一行是新访问的（老行不再重复触发）；
  //   strict 触发（StreamStrictTrigger=1）：只有 miss 或命中 stream 预取的访问才触发
  wire s1_can_trigger = s1_miss | s1_pfHit;
  wire s1_can_send_pf = (~s1_update | ~|(e_bit_vec[s1_index] & s1_line_oh)) & s1_can_trigger;

  // ===========================================================================
  //  §4 s2：读本项 active，决定发不发
  // ===========================================================================
  logic                 s2_valid_last_REG;
  logic [IDX_W-1:0]     s2_index;
  logic [REGION_W-1:0]  s2_region_tag;          // 只喂 hash_conflict 性能计数器（§7）
  logic [VADDR_W-1:0]   s2_pf_l1_incr_vaddr, s2_pf_l2_incr_vaddr, s2_pf_l3_incr_vaddr;
  logic                 s2_can_send_pf;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_valid_last_REG <= 1'b0;
    else       s2_valid_last_REG <= s1_valid_last_REG;
  end

  always_ff @(posedge clock) begin
    if (s1_valid_last_REG) begin
      s2_index            <= s1_index;
      s2_region_tag       <= s1_region_tag;
      s2_pf_l1_incr_vaddr <= {BLK_W'(s1_blk_addr + L1_DEPTH), {BLK_OFF_W{1'b0}}};
      s2_pf_l2_incr_vaddr <= {BLK_W'(s1_blk_addr + L2_DEPTH), {BLK_OFF_W{1'b0}}};
      s2_pf_l3_incr_vaddr <= {BLK_W'(s1_blk_addr + L3_DEPTH), {BLK_OFF_W{1'b0}}};
      s2_can_send_pf      <= s1_can_send_pf;
    end
  end

  wire s2_will_send_pf = s2_valid_last_REG & e_active[s2_index] & s2_can_send_pf;
  wire s2_pf_req_valid = s2_will_send_pf & enable;

  // ===========================================================================
  //  §5 s3~s5：发出
  // ---------------------------------------------------------------------------
  //  s3 发 L1；L2/L3 两份载荷一起往后打：s4 发 L2；s5 的 L3 valid 恒 0（enableL3StreamPrefetch
  //  初值 false），但 s5 的载荷寄存器仍在，且在 s4 不发时出现在 l2_l3 的 bits 上。
  //  s3_pf_l1_valid 与 s3_pf_l2_valid 是同一个值的两份寄存器（golden 如此）。
  // ===========================================================================
  logic                s3_pf_l1_valid_last_REG, s3_pf_l2_valid_last_REG, s4_pf_l2_valid_last_REG;
  logic [REGION_W-1:0] s3_pf_l1_bits_region, s3_pf_l2_bits_region, s3_pf_l3_bits_region;
  logic [BITVEC_W-1:0] s3_pf_l1_bits_bit_vec, s3_pf_l2_bits_bit_vec, s3_pf_l3_bits_bit_vec;
  logic [REGION_W-1:0] s4_pf_l2_bits_region, s4_pf_l3_bits_region, s5_pf_l3_bits_region;
  logic [BITVEC_W-1:0] s4_pf_l2_bits_bit_vec, s4_pf_l3_bits_bit_vec, s5_pf_l3_bits_bit_vec;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s3_pf_l1_valid_last_REG <= 1'b0;
      s3_pf_l2_valid_last_REG <= 1'b0;
      s4_pf_l2_valid_last_REG <= 1'b0;
    end else begin
      s3_pf_l1_valid_last_REG <= s2_pf_req_valid;
      s3_pf_l2_valid_last_REG <= s2_pf_req_valid;
      s4_pf_l2_valid_last_REG <= s3_pf_l2_valid_last_REG;
    end
  end

  always_ff @(posedge clock) begin
    if (s2_pf_req_valid) begin
      s3_pf_l1_bits_region  <= s2_pf_l1_incr_vaddr[VADDR_W-1 -: REGION_W];
      s3_pf_l1_bits_bit_vec <= pf_bit_vec(s2_pf_l1_incr_vaddr[BLK_OFF_W +: LINE_W], L1_WIDTH);
      s3_pf_l2_bits_region  <= s2_pf_l2_incr_vaddr[VADDR_W-1 -: REGION_W];
      s3_pf_l2_bits_bit_vec <= pf_bit_vec(s2_pf_l2_incr_vaddr[BLK_OFF_W +: LINE_W], L2_WIDTH);
      s3_pf_l3_bits_region  <= s2_pf_l3_incr_vaddr[VADDR_W-1 -: REGION_W];
      s3_pf_l3_bits_bit_vec <= pf_bit_vec(s2_pf_l3_incr_vaddr[BLK_OFF_W +: LINE_W], L3_WIDTH);
    end
    if (s3_pf_l2_valid_last_REG) begin
      s4_pf_l2_bits_region  <= s3_pf_l2_bits_region;
      s4_pf_l2_bits_bit_vec <= s3_pf_l2_bits_bit_vec;
      s4_pf_l3_bits_region  <= s3_pf_l3_bits_region;
      s4_pf_l3_bits_bit_vec <= s3_pf_l3_bits_bit_vec;
    end
    if (s4_pf_l2_valid_last_REG) begin
      s5_pf_l3_bits_region  <= s4_pf_l3_bits_region;
      s5_pf_l3_bits_bit_vec <= s4_pf_l3_bits_bit_vec;
    end
  end

  assign l1_pf_valid      = s3_pf_l1_valid_last_REG;
  assign l1_pf_region     = s3_pf_l1_bits_region;
  assign l1_pf_bit_vec    = s3_pf_l1_bits_bit_vec;
  assign l2_l3_pf_valid   = s4_pf_l2_valid_last_REG;      // || s5_pf_l3_valid（恒 0）
  assign l2_l3_pf_region  = s4_pf_l2_valid_last_REG ? s4_pf_l2_bits_region  : s5_pf_l3_bits_region;
  assign l2_l3_pf_bit_vec = s4_pf_l2_valid_last_REG ? s4_pf_l2_bits_bit_vec : s5_pf_l3_bits_bit_vec;
  assign l2_l3_pf_sink    = s4_pf_l2_valid_last_REG ? SINK_L2 : SINK_L3;

  // ===========================================================================
  //  §6 stride 查询：s1 CAM（匹配向量由各项在 §1 算）→ s2 读 active → s3 回答
  // ===========================================================================
  logic             s2_lookup_valid_last_REG, s3_lookup_valid_last_REG;
  logic             s2_lookup_hit, s3_lookup_hit, s3_lookup_active;
  logic [IDX_W-1:0] s2_lookup_index;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_lookup_valid_last_REG <= 1'b0;
      s2_lookup_valid_last_REG <= 1'b0;
      s3_lookup_valid_last_REG <= 1'b0;
    end else begin
      s1_lookup_valid_last_REG <= lookup_valid;
      s2_lookup_valid_last_REG <= s1_lookup_valid_last_REG;
      s3_lookup_valid_last_REG <= s2_lookup_valid_last_REG;
    end
  end

  always_ff @(posedge clock) begin
    if (lookup_valid)
      s1_lookup_tag <= lookup_vaddr[VADDR_W-1 -: REGION_W];
    if (s1_lookup_valid_last_REG) begin
      s2_lookup_hit   <= |s1_lookup_match_vec;
      s2_lookup_index <= oh_to_uint(s1_lookup_match_vec);
    end
    if (s2_lookup_valid_last_REG) begin
      s3_lookup_hit    <= s2_lookup_hit;
      s3_lookup_active <= e_active[s2_lookup_index];
    end
  end

  assign lookup_resp = s3_lookup_valid_last_REG & s3_lookup_hit & s3_lookup_active;

  // ===========================================================================
  //  §7 只喂断言的寄存器（综合口径下无读者，golden 仍保留，照抄）
  // ---------------------------------------------------------------------------
  //  golden 名 REG / r / r_1：断言 "replacement error" 用的 RegNext(s0_valid)、
  //  RegEnable(s0_hit, s0_valid)、RegEnable(replacement.way, s0_valid)。不复位。
  // ===========================================================================
  logic             assert_s0_valid_d1;   // golden REG
  logic             assert_s0_hit_d1;     // golden r
  logic [IDX_W-1:0] assert_plru_way_d1;   // golden r_1

  always_ff @(posedge clock) begin
    assert_s0_valid_d1 <= s0_valid;
    if (s0_valid) begin
      assert_s0_hit_d1   <= s0_hit;
      assert_plru_way_d1 <= plru_way;
    end
  end

endmodule

// =============================================================================
//  StreamBitVectorArray —— golden 同名 wrapper：端口逐位同名同序，只做改名/接常量
// =============================================================================
module StreamBitVectorArray (
  input         clock,
  input         reset,
  input         io_enable,
  output        io_train_req_ready,
  input         io_train_req_valid,
  input  [49:0] io_train_req_bits_vaddr,
  input         io_train_req_bits_miss,
  input         io_train_req_bits_pfHitStream,
  output        io_l1_prefetch_req_valid,
  output [39:0] io_l1_prefetch_req_bits_region,
  output [15:0] io_l1_prefetch_req_bits_bit_vec,
  output        io_l2_l3_prefetch_req_valid,
  output [39:0] io_l2_l3_prefetch_req_bits_region,
  output [15:0] io_l2_l3_prefetch_req_bits_bit_vec,
  output [1:0]  io_l2_l3_prefetch_req_bits_sink,
  input         io_stream_lookup_req_valid,
  input  [49:0] io_stream_lookup_req_bits_vaddr,
  output        io_stream_lookup_resp
);

  xs_StreamBitVectorArray_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .enable                (io_enable),
    .flush                 (1'b0),       // 上层在本配置把 io.flush 接成 false，firtool 删了端口
    .train_req_ready       (io_train_req_ready),
    .train_req_valid       (io_train_req_valid),
    .train_req_vaddr       (io_train_req_bits_vaddr),
    .train_req_miss        (io_train_req_bits_miss),
    .train_req_pfHitStream (io_train_req_bits_pfHitStream),
    .l1_pf_valid           (io_l1_prefetch_req_valid),
    .l1_pf_region          (io_l1_prefetch_req_bits_region),
    .l1_pf_bit_vec         (io_l1_prefetch_req_bits_bit_vec),
    .l2_l3_pf_valid        (io_l2_l3_prefetch_req_valid),
    .l2_l3_pf_region       (io_l2_l3_prefetch_req_bits_region),
    .l2_l3_pf_bit_vec      (io_l2_l3_prefetch_req_bits_bit_vec),
    .l2_l3_pf_sink         (io_l2_l3_prefetch_req_bits_sink),
    .lookup_valid          (io_stream_lookup_req_valid),
    .lookup_vaddr          (io_stream_lookup_req_bits_vaddr),
    .lookup_resp           (io_stream_lookup_resp)
  );

endmodule
