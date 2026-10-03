// =============================================================================
// StrideMetaArray —— L1 stride 预取器的"PC 步长表"（L1Prefetcher 的 stride 组件）
//
// 位置：L1Prefetcher 里，收 TrainFilter 过滤后的训练访问 {vaddr, pc}，按 pc 哈希查一张
//   10 项的步长表；同一条 load 指令连续访问的地址差（stride）稳定到最高置信度后，
//   就发出 vaddr + stride×4 的 L1 预取与 vaddr + stride×32 的 L2 预取。
//
// 流水：
//   s0  pc 哈希 CAM 全表（valid 且 hash_pc 相等）；命中取命中项下标，未命中取 PLRU 替换项；
//       同拍 touch PLRU。train_req.ready = !(s1 有效且 s1 的 pc 哈希与 s0 相同)（防背靠背同 pc）。
//       stream_lookup_req 原样把训练地址带出（给 stream 组件查询；本配置不看回答）。
//   s1  未命中 → 分配（pre_vaddr=当前地址，stride=0，conf=0，hash_pc）；
//       命中 → 更新：new_stride = vaddr[15:0] - pre_vaddr；
//              stride_valid = new_stride 的块号 ∉ {0,1} 且 new_stride 非负（bit15=0）；
//              stride_valid 时：stride_match（== 旧 stride）则 conf 饱和 +1，否则 conf 饱和 -1
//              且 conf<=1 时改写 stride；pre_vaddr 总是更新（ALWAYS_UPDATE_PRE_VADDR=true）。
//       can_send_pf = 更新 且 stride_valid 且 stride_match 且 conf 已是 3。
//   s2  算 L1/L2 预取地址（ratio 常量 2 / 5）。
//   s3  region = 地址[49:10]，bit_vec = 1 << 地址[9:6]；本拍发 L1 预取。
//   s4  L2 预取再延一拍发出。
//
// 怪癖（照 golden，bug-for-bug）：
//   1. s1_index 是 4 位，10..15 越界读第 0 项（表项字段）；写时没有任何项被写。
//   2. CAM 多命中时下标按 OHToUInt 的"按位或"编码（golden 只有非综合断言）。
//   3. 10 路 PLRU 不是 2 的幂：根 state[8] 在 {0..7}（state[6:0] 一棵 8 路树）与 {8,9}（state[7]）
//      之间选择；根为 1 指向 {8,9}。编码与 rocket-chip PseudoLRU 一致（见 plru_* 两个函数）。
//   4. io.flush 在本配置被接 0，golden 留下 10 个 RegNext(flush)（有复位、恒 0）各清一项 valid；
//      io.enable / dynamic_depth / stream_lookup_resp 端口被整个裁掉。
//   5. 表项字段、s1/s2/s3/s4 的数据寄存器不复位；valid 链、PLRU 状态、flush 打拍异步复位。
// =============================================================================

module xs_StrideMetaArray_core #(
  parameter int unsigned VADDR_W  = 50,
  parameter int unsigned ENTRIES  = 10,
  parameter int unsigned SV_W     = 16,   // STRIDE_VADDR_BITS = STRIDE_BITS = 10 + 6
  parameter int unsigned HASH_W   = 15,
  parameter int unsigned CONF_W   = 2,
  parameter int unsigned L1_RATIO = 2,    // L1 深度 = stride << 2
  parameter int unsigned L2_RATIO = 5     // L2 深度 = stride << 5
) (
  input  logic               clock,
  input  logic               reset,
  output logic               train_ready,
  input  logic               train_valid,
  input  logic [VADDR_W-1:0] train_vaddr,
  input  logic [VADDR_W-1:0] train_pc,
  output logic               l1_pf_valid,
  output logic [39:0]        l1_pf_region,
  output logic [15:0]        l1_pf_bit_vec,
  output logic               l2_pf_valid,
  output logic [39:0]        l2_pf_region,
  output logic [15:0]        l2_pf_bit_vec,
  output logic               stream_lookup_valid,
  output logic [VADDR_W-1:0] stream_lookup_vaddr
);

  localparam int unsigned IDX_W    = 4;              // log2Up(10)
  localparam logic [CONF_W-1:0] MAX_CONF = '1;

  function automatic logic [HASH_W-1:0] pc_hash_tag(input logic [VADDR_W-1:0] pc);
    return {pc[14:10] ^ pc[19:15] ^ pc[24:20], pc[9:0]};
  endfunction

  // ---------------------------------------------------------------------------
  // 10 路 PLRU（怪癖 3）：state[8] 根；state[7] 管 {8,9}；state[6:0] 是 {0..7} 的 8 路树
  //   8 路树：state[6] 根，state[5:3] 管 {4..7}，state[2:0] 管 {0..3}；每棵 4 路树同构。
  // ---------------------------------------------------------------------------
  function automatic logic [1:0] plru4_way(input logic [2:0] s);
    return {s[2], s[2] ? s[1] : s[0]};
  endfunction
  function automatic logic [2:0] plru4_next(input logic [2:0] s, input logic [1:0] w);
    return {~w[1], w[1] ? ~w[0] : s[1], w[1] ? s[0] : ~w[0]};
  endfunction
  function automatic logic [IDX_W-1:0] plru10_way(input logic [8:0] s);
    logic [2:0] w8;
    w8 = {s[6], s[6] ? plru4_way(s[5:3]) : plru4_way(s[2:0])};
    return s[8] ? {3'b100, s[7]} : {1'b0, w8};
  endfunction
  function automatic logic [8:0] plru10_next(input logic [8:0] s, input logic [IDX_W-1:0] w);
    logic [6:0] n8;
    n8 = {~w[2], w[2] ? plru4_next(s[5:3], w[1:0]) : s[5:3], w[2] ? s[2:0] : plru4_next(s[2:0], w[1:0])};
    return {~w[3], w[3] ? ~w[0] : s[7], w[3] ? s[6:0] : n8};
  endfunction

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------
  logic [SV_W-1:0]   ent_pre_vaddr  [ENTRIES];   // 不复位
  logic [SV_W-1:0]   ent_stride     [ENTRIES];
  logic [CONF_W-1:0] ent_confidence [ENTRIES];
  logic [HASH_W-1:0] ent_hash_pc    [ENTRIES];
  logic              ent_valid      [ENTRIES];
  logic [8:0]        plru_state;
  logic              flush_q        [ENTRIES];   // RegNext(io.flush)，恒 0（怪癖 4）

  // ---------------------------------------------------------------------------
  // s0：CAM
  // ---------------------------------------------------------------------------
  logic              s0_valid;
  logic [HASH_W-1:0] s0_pc_hash;
  logic              s0_match [ENTRIES];
  logic              s0_hit;
  logic [IDX_W-1:0]  s0_hit_index;
  logic [IDX_W-1:0]  s0_index;

  assign s0_pc_hash = pc_hash_tag(train_pc);
  assign s0_valid   = train_ready & train_valid;

  always_comb begin
    s0_hit       = 1'b0;
    s0_hit_index = '0;
    for (int i = 0; i < ENTRIES; i++) begin
      s0_match[i] = ent_valid[i] & s0_valid & (ent_hash_pc[i] == s0_pc_hash);
      if (s0_match[i]) begin
        s0_hit       = 1'b1;
        s0_hit_index = s0_hit_index | IDX_W'(i);   // OHToUInt：多命中按位或（怪癖 2）
      end
    end
    s0_index = s0_hit ? s0_hit_index : plru10_way(plru_state);
  end

  assign stream_lookup_valid = s0_valid;
  assign stream_lookup_vaddr = train_vaddr;

  // ---------------------------------------------------------------------------
  // s1：分配 / 更新
  // ---------------------------------------------------------------------------
  logic              s1_valid;
  logic [IDX_W-1:0]  s1_index;
  logic [HASH_W-1:0] s1_pc_hash;
  logic [VADDR_W-1:0] s1_vaddr;
  logic              s1_hit;
  logic              s1_alloc;
  logic              s1_update;

  assign s1_alloc    = s1_valid & ~s1_hit;
  assign s1_update   = s1_valid &  s1_hit;
  assign train_ready = ~(s1_valid & (s1_pc_hash == s0_pc_hash));

  // 被更新项的旧值（下标越界读第 0 项，怪癖 1）
  logic [SV_W-1:0]   s1_old_pre_vaddr;
  logic [SV_W-1:0]   s1_old_stride;
  logic [CONF_W-1:0] s1_old_conf;
  always_comb begin
    s1_old_pre_vaddr = ent_pre_vaddr[0];
    s1_old_stride    = ent_stride[0];
    s1_old_conf      = ent_confidence[0];
    for (int i = 1; i < ENTRIES; i++)
      if (s1_index == IDX_W'(i)) begin
        s1_old_pre_vaddr = ent_pre_vaddr[i];
        s1_old_stride    = ent_stride[i];
        s1_old_conf      = ent_confidence[i];
      end
  end

  logic [SV_W-1:0]   s1_new_stride;
  logic              s1_stride_valid;
  logic              s1_stride_match;
  logic [CONF_W-1:0] s1_new_conf;
  logic              s1_can_send_pf;

  assign s1_new_stride   = s1_vaddr[SV_W-1:0] - s1_old_pre_vaddr;
  assign s1_stride_valid = (s1_new_stride[SV_W-1:6] != '0) & (s1_new_stride[SV_W-1:6] != 10'd1) & ~s1_new_stride[SV_W-1];
  assign s1_stride_match = (s1_new_stride == s1_old_stride);
  assign s1_new_conf     = s1_stride_match ? ((s1_old_conf == MAX_CONF) ? s1_old_conf : s1_old_conf + 1'b1)
                                           : ((s1_old_conf == '0)       ? s1_old_conf : s1_old_conf - 1'b1);
  assign s1_can_send_pf  = s1_update & s1_stride_valid & s1_stride_match & (s1_old_conf == MAX_CONF);

  for (genvar i = 0; i < ENTRIES; i++) begin : g_entry
    logic sel;
    assign sel = (s1_index == IDX_W'(i));
    always_ff @(posedge clock) begin
      if (s1_alloc) begin
        if (sel) begin
          ent_pre_vaddr[i]  <= s1_vaddr[SV_W-1:0];
          ent_stride[i]     <= '0;
          ent_confidence[i] <= '0;
        end
      end else if (s1_update && sel) begin
        ent_pre_vaddr[i] <= s1_vaddr[SV_W-1:0];
        if (s1_stride_valid) begin
          ent_confidence[i] <= s1_new_conf;
          if (!s1_stride_match && !s1_old_conf[1]) ent_stride[i] <= s1_new_stride;
        end
      end
      if (s1_alloc && sel) ent_hash_pc[i] <= s1_pc_hash;
    end
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        ent_valid[i] <= 1'b0;
        flush_q[i]   <= 1'b0;
      end else begin
        ent_valid[i] <= ~flush_q[i] & ((s1_alloc & sel) | ent_valid[i]);
        flush_q[i]   <= 1'b0;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (s0_valid) begin
      s1_index   <= s0_index;
      s1_pc_hash <= s0_pc_hash;
      s1_vaddr   <= train_vaddr;
      s1_hit     <= s0_hit;
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid   <= 1'b0;
      plru_state <= '0;
    end else begin
      s1_valid <= s0_valid;
      if (s0_valid) plru_state <= plru10_next(plru_state, s0_index);
    end
  end

  // ---------------------------------------------------------------------------
  // s2：预取地址
  // ---------------------------------------------------------------------------
  logic               s2_valid;
  logic [VADDR_W-1:0] s2_vaddr;
  logic [SV_W-1:0]    s2_stride;
  logic [VADDR_W-1:0] s2_l1_pf_vaddr;
  logic [VADDR_W-1:0] s2_l2_pf_vaddr;

  assign s2_l1_pf_vaddr = s2_vaddr + (VADDR_W'(s2_stride) << L1_RATIO);
  assign s2_l2_pf_vaddr = s2_vaddr + (VADDR_W'(s2_stride) << L2_RATIO);

  always_ff @(posedge clock) begin
    if (s1_can_send_pf) begin
      s2_vaddr  <= s1_vaddr;
      s2_stride <= s1_old_stride;
    end
  end

  // ---------------------------------------------------------------------------
  // s3 / s4：发出
  // ---------------------------------------------------------------------------
  logic        s3_valid, s4_valid;
  logic [39:0] s3_l1_region, s3_l2_region, s4_l2_region;
  logic [15:0] s3_l1_bit_vec, s3_l2_bit_vec, s4_l2_bit_vec;

  always_ff @(posedge clock) begin
    if (s2_valid) begin
      s3_l1_region  <= s2_l1_pf_vaddr[49:10];
      s3_l1_bit_vec <= 16'h1 << s2_l1_pf_vaddr[9:6];
      s3_l2_region  <= s2_l2_pf_vaddr[49:10];
      s3_l2_bit_vec <= 16'h1 << s2_l2_pf_vaddr[9:6];
    end
    if (s3_valid) begin
      s4_l2_region  <= s3_l2_region;
      s4_l2_bit_vec <= s3_l2_bit_vec;
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid <= 1'b0;
      s3_valid <= 1'b0;
      s4_valid <= 1'b0;
    end else begin
      s2_valid <= s1_can_send_pf;
      s3_valid <= s2_valid;
      s4_valid <= s3_valid;
    end
  end

  assign l1_pf_valid   = s3_valid;
  assign l1_pf_region  = s3_l1_region;
  assign l1_pf_bit_vec = s3_l1_bit_vec;
  assign l2_pf_valid   = s4_valid;
  assign l2_pf_region  = s4_l2_region;
  assign l2_pf_bit_vec = s4_l2_bit_vec;

endmodule

module StrideMetaArray(
  input         clock,
  input         reset,
  output        io_train_req_ready,
  input         io_train_req_valid,
  input  [49:0] io_train_req_bits_vaddr,
  input  [49:0] io_train_req_bits_pc,
  output        io_l1_prefetch_req_valid,
  output [39:0] io_l1_prefetch_req_bits_region,
  output [15:0] io_l1_prefetch_req_bits_bit_vec,
  output        io_l2_l3_prefetch_req_valid,
  output [39:0] io_l2_l3_prefetch_req_bits_region,
  output [15:0] io_l2_l3_prefetch_req_bits_bit_vec,
  output        io_stream_lookup_req_valid,
  output [49:0] io_stream_lookup_req_bits_vaddr
);

  xs_StrideMetaArray_core #(
    .VADDR_W (50),
    .ENTRIES (10),
    .SV_W    (16),
    .HASH_W  (15),
    .CONF_W  (2),
    .L1_RATIO(2),
    .L2_RATIO(5)
  ) u_core (
    .clock              (clock),
    .reset              (reset),
    .train_ready        (io_train_req_ready),
    .train_valid        (io_train_req_valid),
    .train_vaddr        (io_train_req_bits_vaddr),
    .train_pc           (io_train_req_bits_pc),
    .l1_pf_valid        (io_l1_prefetch_req_valid),
    .l1_pf_region       (io_l1_prefetch_req_bits_region),
    .l1_pf_bit_vec      (io_l1_prefetch_req_bits_bit_vec),
    .l2_pf_valid        (io_l2_l3_prefetch_req_valid),
    .l2_pf_region       (io_l2_l3_prefetch_req_bits_region),
    .l2_pf_bit_vec      (io_l2_l3_prefetch_req_bits_bit_vec),
    .stream_lookup_valid(io_stream_lookup_req_valid),
    .stream_lookup_vaddr(io_stream_lookup_req_bits_vaddr)
  );

endmodule
