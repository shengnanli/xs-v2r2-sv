// =============================================================================
// PrefetchReqBuffer —— VBOP（按虚地址训练的 Best-Offset 预取器）的"虚地址预取请求缓冲"
//
// 位置：VBestOffsetPrefetch 里。BOP 用虚地址算出 X+D 后不能直接发给 L2（L2 要物理地址），
//   请求先进本缓冲：查 TLB 拿到物理地址（paddrValid）后再经轮转仲裁器发往 L2 预取队列。
//   16 项；满则丢新请求（不做替换）。
//
// 流水（照 Scala 注释）：
//   entry   s0 查表（去重/找空位），s1 写入
//   tlb     s0 仲裁，s1 发 TLB 请求（打一拍），s2 收 TLB 回答，s3 收 PMP 回答后更新条目
//   pf      s0 仲裁并发出
//
// s0：丢弃三种新请求 —— 与上一拍同块（conflict_prev）、与表中有效项完全相同（vaddrNoOffset/
//     baseVaddr/needT/source 四项全等）、没有空位（空位 = !valid 且本拍不被 s1 分配）。
//     空位按最低下标优先（PriorityEncoderOH）选，打一拍到 s1 写入。
// TLB：valid 且还没拿到 paddr 且最近 3 拍没发过 TLB 请求（s1/s2/s3_tlb_fire_oh 三级 one-hot 记账）
//     且 replayCnt==0 的条目参与仲裁；仲裁结果打一拍发出（valid 与 bits 都寄存）。
//     TLB 回答再打一拍（s3）后与同拍到达的 PMP 回答一起判：
//       exp_drop  = 命中但有异常（pf/gpf/af/pmp ld/pmp mmio/pbmt 为 NC 或 IO）→ 作废；
//       tlb_fired = 命中无异常 → 写 paddr，paddrValid=1；
//       miss      = 第一次 miss → replayCnt=10、replayEn=1（等 10 拍再问）；再 miss → 作废。
//     replayCnt 每拍自减到 0。
// PF：valid 且 paddrValid 的条目参与仲裁，被选中即作废；tag/set 由 paddrNoOffset 切出
//     （tag=[41:9]、set=[8:0]），vaddr 带 baseVaddr。
//
// 怪癖（照 golden）：
//   1. 条目字段、prev_in_req、s1_in_req、s1_invalid_oh、s3_tlb_resp*、TLB 发出寄存器都不复位；
//      valids、prev_in_valid、s1_valid、三级 tlb_fire_oh 异步复位。
//   2. TLB 发出的 bits 寄存器是 RegEnable(常量)：cmd 在 valid 时写 0；isPrefetch 在 valid 时置 1 后粘住；
//      kill/no_translate 在 valid 时清 0 其余保持 —— 上电初值在首个请求前可观测，核照写。
//   3. 条目更新优先级：alloc > tlb_fired > miss_drop > miss_first_replay > exp_drop；pf_fired 清 valid
//      但 alloc 可同拍把它重新置 1（golden `alloc | ~pf_fired & ... & valid`）。
//   4. replayCnt 自减条件里带 valid（无效项不减）；alloc/tlb_fired 清零优先于自减。
//   5. 两个仲裁器是独立 golden 模块 RRArbiterInit_14（TLB）/ RRArbiterInit_15（PF），
//      impl 用 rtl/common 的重写件，两侧白盒；pf 仲裁器的 pfSource 常量端口已被 firtool 裁掉。
// =============================================================================

module xs_PrefetchReqBuffer_core #(
  parameter int unsigned ENTRIES      = 16,
  parameter int unsigned FULL_VADDR_W = 50,
  parameter int unsigned OFFSET_BITS  = 6,
  parameter int unsigned BLK_VADDR_W  = FULL_VADDR_W - OFFSET_BITS,  // 44
  parameter int unsigned PADDR_W      = 48,
  parameter int unsigned SOURCE_W     = 7,
  parameter int unsigned TAG_W        = 33,
  parameter int unsigned SET_W        = 9,
  parameter int unsigned REPLAY_CNT   = 10
) (
  input  logic                    clock,
  input  logic                    reset,
  // 来自 BOP 的虚地址预取请求
  input  logic                    in_valid,
  input  logic [FULL_VADDR_W-1:0] in_full_vaddr,
  input  logic [BLK_VADDR_W-1:0]  in_base_vaddr,
  input  logic                    in_needT,
  input  logic [SOURCE_W-1:0]     in_source,
  // TLB
  output logic                    tlb_req_valid,
  output logic [FULL_VADDR_W-1:0] tlb_req_vaddr,
  output logic [2:0]              tlb_req_cmd,
  output logic                    tlb_req_isPrefetch,
  output logic                    tlb_req_kill,
  output logic                    tlb_req_no_translate,
  input  logic                    tlb_resp_valid,
  input  logic [PADDR_W-1:0]      tlb_resp_paddr,
  input  logic [1:0]              tlb_resp_pbmt,
  input  logic                    tlb_resp_miss,
  input  logic                    tlb_resp_gpf_ld,
  input  logic                    tlb_resp_pf_ld,
  input  logic                    tlb_resp_af_ld,
  input  logic                    pmp_resp_ld,
  input  logic                    pmp_resp_mmio,
  // 发往 L2 的物理地址预取请求
  input  logic                    out_ready,
  output logic                    out_valid,
  output logic [TAG_W-1:0]        out_tag,
  output logic [SET_W-1:0]        out_set,
  output logic [BLK_VADDR_W-1:0]  out_vaddr,
  output logic                    out_needT,
  output logic [SOURCE_W-1:0]     out_source
);

  // ---------------------------------------------------------------------------
  // §1 条目
  // ---------------------------------------------------------------------------
  logic                    ent_valid         [ENTRIES];
  logic                    ent_paddrValid    [ENTRIES];
  logic [BLK_VADDR_W-1:0]  ent_vaddrNoOffset [ENTRIES];
  logic [BLK_VADDR_W-1:0]  ent_baseVaddr     [ENTRIES];
  logic [FULL_VADDR_W-1:0] ent_paddrNoOffset [ENTRIES];
  logic                    ent_replayEn      [ENTRIES];
  logic [3:0]              ent_replayCnt     [ENTRIES];
  logic                    ent_needT         [ENTRIES];
  logic [SOURCE_W-1:0]     ent_source        [ENTRIES];

  // ---------------------------------------------------------------------------
  // §2 s0：查表
  // ---------------------------------------------------------------------------
  logic                    prev_in_valid;
  logic [FULL_VADDR_W-1:0] prev_in_full_vaddr;
  logic                    s0_conflict_prev;
  logic [ENTRIES-1:0]      s0_match_oh;
  logic [ENTRIES-1:0]      s0_invalid_vec;
  logic [ENTRIES-1:0]      s0_invalid_oh;      // 最低下标优先的空位
  logic                    s0_req_valid;
  logic [ENTRIES-1:0]      alloc;              // s1 写入
  logic [BLK_VADDR_W-1:0]  s0_in_flag;

  assign s0_in_flag       = in_full_vaddr[FULL_VADDR_W-1:OFFSET_BITS];
  assign s0_conflict_prev = prev_in_valid & (s0_in_flag == prev_in_full_vaddr[FULL_VADDR_W-1:OFFSET_BITS]);

  always_comb begin
    s0_invalid_oh = '0;
    for (int i = 0; i < ENTRIES; i++) begin
      s0_match_oh[i]    = ent_valid[i] & (ent_vaddrNoOffset[i] == s0_in_flag)
                        & (ent_needT[i] == in_needT) & (ent_source[i] == in_source)
                        & (ent_baseVaddr[i] == in_base_vaddr);
      s0_invalid_vec[i] = ~ent_valid[i] & ~alloc[i];
    end
    for (int i = ENTRIES - 1; i >= 0; i--)
      if (s0_invalid_vec[i]) s0_invalid_oh = ENTRIES'(1) << i;
  end
  assign s0_req_valid = in_valid & ~s0_conflict_prev & ~(|s0_match_oh) & (|s0_invalid_vec);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) prev_in_valid <= 1'b0;
    else       prev_in_valid <= in_valid;
  end
  always_ff @(posedge clock) prev_in_full_vaddr <= in_full_vaddr;

  // ---------------------------------------------------------------------------
  // §3 s1：写入
  // ---------------------------------------------------------------------------
  logic                    s1_valid;
  logic [FULL_VADDR_W-1:0] s1_in_full_vaddr;
  logic [BLK_VADDR_W-1:0]  s1_in_base_vaddr;
  logic                    s1_in_needT;
  logic [SOURCE_W-1:0]     s1_in_source;
  logic [ENTRIES-1:0]      s1_invalid_oh;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_valid <= 1'b0;
    else       s1_valid <= s0_req_valid;
  end
  always_ff @(posedge clock) begin
    s1_in_full_vaddr <= in_full_vaddr;
    s1_in_base_vaddr <= in_base_vaddr;
    s1_in_needT      <= in_needT;
    s1_in_source     <= in_source;
    s1_invalid_oh    <= s0_invalid_oh;
  end
  assign alloc = {ENTRIES{s1_valid}} & s1_invalid_oh;

  // ---------------------------------------------------------------------------
  // §4 TLB 请求仲裁与三级记账
  // ---------------------------------------------------------------------------
  logic [ENTRIES-1:0]      tlb_in_valid;
  logic [ENTRIES-1:0]      tlb_in_ready;
  logic [ENTRIES-1:0]      s0_tlb_fire_oh, s1_tlb_fire_oh, s2_tlb_fire_oh, s3_tlb_fire_oh;
  logic                    tlb_arb_out_valid;
  logic [FULL_VADDR_W-1:0] tlb_arb_out_vaddr;

  for (genvar i = 0; i < ENTRIES; i++) begin : g_tlb_in
    assign tlb_in_valid[i] = ent_valid[i] & ~ent_paddrValid[i]
                           & ~s1_tlb_fire_oh[i] & ~s2_tlb_fire_oh[i] & ~s3_tlb_fire_oh[i]
                           & (ent_replayCnt[i] == '0);
  end
  assign s0_tlb_fire_oh = tlb_in_ready & tlb_in_valid;

  RRArbiterInit_14 tlb_req_arb (
    .clock(clock), .reset(reset),
    .io_in_0_ready (tlb_in_ready[0]),  .io_in_0_valid (tlb_in_valid[0]),  .io_in_0_bits_vaddr ({ent_vaddrNoOffset[0],  {OFFSET_BITS{1'b0}}}),
    .io_in_1_ready (tlb_in_ready[1]),  .io_in_1_valid (tlb_in_valid[1]),  .io_in_1_bits_vaddr ({ent_vaddrNoOffset[1],  {OFFSET_BITS{1'b0}}}),
    .io_in_2_ready (tlb_in_ready[2]),  .io_in_2_valid (tlb_in_valid[2]),  .io_in_2_bits_vaddr ({ent_vaddrNoOffset[2],  {OFFSET_BITS{1'b0}}}),
    .io_in_3_ready (tlb_in_ready[3]),  .io_in_3_valid (tlb_in_valid[3]),  .io_in_3_bits_vaddr ({ent_vaddrNoOffset[3],  {OFFSET_BITS{1'b0}}}),
    .io_in_4_ready (tlb_in_ready[4]),  .io_in_4_valid (tlb_in_valid[4]),  .io_in_4_bits_vaddr ({ent_vaddrNoOffset[4],  {OFFSET_BITS{1'b0}}}),
    .io_in_5_ready (tlb_in_ready[5]),  .io_in_5_valid (tlb_in_valid[5]),  .io_in_5_bits_vaddr ({ent_vaddrNoOffset[5],  {OFFSET_BITS{1'b0}}}),
    .io_in_6_ready (tlb_in_ready[6]),  .io_in_6_valid (tlb_in_valid[6]),  .io_in_6_bits_vaddr ({ent_vaddrNoOffset[6],  {OFFSET_BITS{1'b0}}}),
    .io_in_7_ready (tlb_in_ready[7]),  .io_in_7_valid (tlb_in_valid[7]),  .io_in_7_bits_vaddr ({ent_vaddrNoOffset[7],  {OFFSET_BITS{1'b0}}}),
    .io_in_8_ready (tlb_in_ready[8]),  .io_in_8_valid (tlb_in_valid[8]),  .io_in_8_bits_vaddr ({ent_vaddrNoOffset[8],  {OFFSET_BITS{1'b0}}}),
    .io_in_9_ready (tlb_in_ready[9]),  .io_in_9_valid (tlb_in_valid[9]),  .io_in_9_bits_vaddr ({ent_vaddrNoOffset[9],  {OFFSET_BITS{1'b0}}}),
    .io_in_10_ready(tlb_in_ready[10]), .io_in_10_valid(tlb_in_valid[10]), .io_in_10_bits_vaddr({ent_vaddrNoOffset[10], {OFFSET_BITS{1'b0}}}),
    .io_in_11_ready(tlb_in_ready[11]), .io_in_11_valid(tlb_in_valid[11]), .io_in_11_bits_vaddr({ent_vaddrNoOffset[11], {OFFSET_BITS{1'b0}}}),
    .io_in_12_ready(tlb_in_ready[12]), .io_in_12_valid(tlb_in_valid[12]), .io_in_12_bits_vaddr({ent_vaddrNoOffset[12], {OFFSET_BITS{1'b0}}}),
    .io_in_13_ready(tlb_in_ready[13]), .io_in_13_valid(tlb_in_valid[13]), .io_in_13_bits_vaddr({ent_vaddrNoOffset[13], {OFFSET_BITS{1'b0}}}),
    .io_in_14_ready(tlb_in_ready[14]), .io_in_14_valid(tlb_in_valid[14]), .io_in_14_bits_vaddr({ent_vaddrNoOffset[14], {OFFSET_BITS{1'b0}}}),
    .io_in_15_ready(tlb_in_ready[15]), .io_in_15_valid(tlb_in_valid[15]), .io_in_15_bits_vaddr({ent_vaddrNoOffset[15], {OFFSET_BITS{1'b0}}}),
    .io_out_valid     (tlb_arb_out_valid),
    .io_out_bits_vaddr(tlb_arb_out_vaddr)
  );

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_tlb_fire_oh <= '0;
      s2_tlb_fire_oh <= '0;
      s3_tlb_fire_oh <= '0;
    end else begin
      s1_tlb_fire_oh <= s0_tlb_fire_oh;
      s2_tlb_fire_oh <= s1_tlb_fire_oh;
      s3_tlb_fire_oh <= s2_tlb_fire_oh;
    end
  end

  // TLB 请求打一拍发出（怪癖 2）
  logic                    tlb_req_valid_q;
  logic [FULL_VADDR_W-1:0] tlb_req_vaddr_q;
  logic [2:0]              tlb_req_cmd_q;
  logic                    tlb_req_isPrefetch_q, tlb_req_kill_q, tlb_req_no_translate_q;
  always_ff @(posedge clock) begin
    tlb_req_valid_q <= tlb_arb_out_valid;
    if (tlb_arb_out_valid) begin
      tlb_req_vaddr_q <= tlb_arb_out_vaddr;
      tlb_req_cmd_q   <= 3'd0;                      // TlbCmd.read
    end
    tlb_req_isPrefetch_q   <= tlb_arb_out_valid | tlb_req_isPrefetch_q;
    tlb_req_kill_q         <= ~tlb_arb_out_valid & tlb_req_kill_q;
    tlb_req_no_translate_q <= ~tlb_arb_out_valid & tlb_req_no_translate_q;
  end
  assign tlb_req_valid        = tlb_req_valid_q;
  assign tlb_req_vaddr        = tlb_req_vaddr_q;
  assign tlb_req_cmd          = tlb_req_cmd_q;
  assign tlb_req_isPrefetch   = tlb_req_isPrefetch_q;
  assign tlb_req_kill         = tlb_req_kill_q;
  assign tlb_req_no_translate = tlb_req_no_translate_q;

  // ---------------------------------------------------------------------------
  // §5 s3：TLB 回答打一拍 + PMP 回答 → 条目判定
  // ---------------------------------------------------------------------------
  logic               s3_tlb_resp_valid;
  logic [PADDR_W-1:0] s3_tlb_resp_paddr;
  logic [1:0]         s3_tlb_resp_pbmt;
  logic               s3_tlb_resp_miss, s3_tlb_resp_gpf_ld, s3_tlb_resp_pf_ld, s3_tlb_resp_af_ld;
  logic               s3_resp_excp;       // 命中但有异常/不可缓存

  always_ff @(posedge clock) begin
    s3_tlb_resp_valid <= tlb_resp_valid;
    if (tlb_resp_valid) begin
      s3_tlb_resp_paddr  <= tlb_resp_paddr;
      s3_tlb_resp_pbmt   <= tlb_resp_pbmt;
      s3_tlb_resp_miss   <= tlb_resp_miss;
      s3_tlb_resp_gpf_ld <= tlb_resp_gpf_ld;
      s3_tlb_resp_pf_ld  <= tlb_resp_pf_ld;
      s3_tlb_resp_af_ld  <= tlb_resp_af_ld;
    end
  end
  assign s3_resp_excp = s3_tlb_resp_pf_ld | s3_tlb_resp_gpf_ld | s3_tlb_resp_af_ld
                      | pmp_resp_ld | pmp_resp_mmio
                      | (s3_tlb_resp_pbmt == 2'd1) | (s3_tlb_resp_pbmt == 2'd2);   // Pbmt.isUncache：NC / IO

  // ---------------------------------------------------------------------------
  // §6 PF 仲裁
  // ---------------------------------------------------------------------------
  logic [ENTRIES-1:0] pf_in_valid, pf_in_ready, pf_fired;
  for (genvar i = 0; i < ENTRIES; i++) begin : g_pf_in
    assign pf_in_valid[i] = ent_valid[i] & ent_paddrValid[i];
  end
  assign pf_fired = pf_in_ready & pf_in_valid;

  `define PRB_PF_IN(I) \
    .io_in_``I``_ready(pf_in_ready[I]), .io_in_``I``_valid(pf_in_valid[I]), \
    .io_in_``I``_bits_tag(ent_paddrNoOffset[I][TAG_W+SET_W-1:SET_W]), .io_in_``I``_bits_set(ent_paddrNoOffset[I][SET_W-1:0]), \
    .io_in_``I``_bits_vaddr(ent_baseVaddr[I]), .io_in_``I``_bits_needT(ent_needT[I]), .io_in_``I``_bits_source(ent_source[I])

  RRArbiterInit_15 pf_req_arb (
    .clock(clock), .reset(reset),
    `PRB_PF_IN(0),  `PRB_PF_IN(1),  `PRB_PF_IN(2),  `PRB_PF_IN(3),
    `PRB_PF_IN(4),  `PRB_PF_IN(5),  `PRB_PF_IN(6),  `PRB_PF_IN(7),
    `PRB_PF_IN(8),  `PRB_PF_IN(9),  `PRB_PF_IN(10), `PRB_PF_IN(11),
    `PRB_PF_IN(12), `PRB_PF_IN(13), `PRB_PF_IN(14), `PRB_PF_IN(15),
    .io_out_ready      (out_ready),
    .io_out_valid      (out_valid),
    .io_out_bits_tag   (out_tag),
    .io_out_bits_set   (out_set),
    .io_out_bits_vaddr (out_vaddr),
    .io_out_bits_needT (out_needT),
    .io_out_bits_source(out_source)
  );
  `undef PRB_PF_IN

  // ---------------------------------------------------------------------------
  // §7 条目更新
  // ---------------------------------------------------------------------------
  for (genvar i = 0; i < ENTRIES; i++) begin : g_entry
    logic resp_here, exp_drop, miss, tlb_fired, miss_drop, miss_first_replay;
    assign resp_here         = s3_tlb_fire_oh[i] & s3_tlb_resp_valid;
    assign exp_drop          = resp_here & ~s3_tlb_resp_miss & s3_resp_excp;
    assign miss              = resp_here &  s3_tlb_resp_miss;
    assign tlb_fired         = resp_here & ~s3_tlb_resp_miss & ~exp_drop;
    assign miss_drop         = miss &  ent_replayEn[i];
    assign miss_first_replay = miss & ~ent_replayEn[i];

    always_ff @(posedge clock or posedge reset) begin
      if (reset) ent_valid[i] <= 1'b0;
      else       ent_valid[i] <= alloc[i]
                               | (~pf_fired[i] & (tlb_fired | (~miss_drop & (miss_first_replay | ~exp_drop))) & ent_valid[i]);
    end

    always_ff @(posedge clock) begin
      ent_paddrValid[i] <= ~alloc[i] & (tlb_fired | ent_paddrValid[i]);
      if (alloc[i]) begin
        ent_vaddrNoOffset[i] <= s1_in_full_vaddr[FULL_VADDR_W-1:OFFSET_BITS];
        ent_baseVaddr[i]     <= s1_in_base_vaddr;
        ent_paddrNoOffset[i] <= '0;
        ent_needT[i]         <= s1_in_needT;
        ent_source[i]        <= s1_in_source;
      end else if (tlb_fired) begin
        ent_paddrNoOffset[i] <= FULL_VADDR_W'(s3_tlb_resp_paddr[PADDR_W-1:OFFSET_BITS]);
      end
      ent_replayEn[i] <= ~(alloc[i] | tlb_fired) & ((~miss_drop & miss_first_replay) | ent_replayEn[i]);
      if (alloc[i] | tlb_fired)
        ent_replayCnt[i] <= '0;
      else if (miss_drop | ~miss_first_replay) begin
        if (ent_valid[i] && ent_replayCnt[i] != '0) ent_replayCnt[i] <= ent_replayCnt[i] - 1'b1;
      end else
        ent_replayCnt[i] <= 4'(REPLAY_CNT);
    end
  end

endmodule

module PrefetchReqBuffer(
  input         clock,
  input         reset,
  input         io_in_req_valid,
  input  [49:0] io_in_req_bits_full_vaddr,
  input  [43:0] io_in_req_bits_base_vaddr,
  input         io_in_req_bits_needT,
  input  [6:0]  io_in_req_bits_source,
  output        io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [2:0]  io_tlb_req_req_bits_cmd,
  output        io_tlb_req_req_bits_isPrefetch,
  output        io_tlb_req_req_bits_kill,
  output        io_tlb_req_req_bits_no_translate,
  input         io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0]  io_tlb_req_resp_bits_pbmt,
  input         io_tlb_req_resp_bits_miss,
  input         io_tlb_req_resp_bits_excp_0_gpf_ld,
  input         io_tlb_req_resp_bits_excp_0_pf_ld,
  input         io_tlb_req_resp_bits_excp_0_af_ld,
  input         io_tlb_req_pmp_resp_ld,
  input         io_tlb_req_pmp_resp_mmio,
  input         io_out_req_ready,
  output        io_out_req_valid,
  output [32:0] io_out_req_bits_tag,
  output [8:0]  io_out_req_bits_set,
  output [43:0] io_out_req_bits_vaddr,
  output        io_out_req_bits_needT,
  output [6:0]  io_out_req_bits_source
);

  xs_PrefetchReqBuffer_core #(
    .ENTRIES     (16),
    .FULL_VADDR_W(50),
    .OFFSET_BITS (6),
    .PADDR_W     (48),
    .SOURCE_W    (7),
    .TAG_W       (33),
    .SET_W       (9),
    .REPLAY_CNT  (10)
  ) u_core (
    .clock               (clock),
    .reset               (reset),
    .in_valid            (io_in_req_valid),
    .in_full_vaddr       (io_in_req_bits_full_vaddr),
    .in_base_vaddr       (io_in_req_bits_base_vaddr),
    .in_needT            (io_in_req_bits_needT),
    .in_source           (io_in_req_bits_source),
    .tlb_req_valid       (io_tlb_req_req_valid),
    .tlb_req_vaddr       (io_tlb_req_req_bits_vaddr),
    .tlb_req_cmd         (io_tlb_req_req_bits_cmd),
    .tlb_req_isPrefetch  (io_tlb_req_req_bits_isPrefetch),
    .tlb_req_kill        (io_tlb_req_req_bits_kill),
    .tlb_req_no_translate(io_tlb_req_req_bits_no_translate),
    .tlb_resp_valid      (io_tlb_req_resp_valid),
    .tlb_resp_paddr      (io_tlb_req_resp_bits_paddr_0),
    .tlb_resp_pbmt       (io_tlb_req_resp_bits_pbmt),
    .tlb_resp_miss       (io_tlb_req_resp_bits_miss),
    .tlb_resp_gpf_ld     (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .tlb_resp_pf_ld      (io_tlb_req_resp_bits_excp_0_pf_ld),
    .tlb_resp_af_ld      (io_tlb_req_resp_bits_excp_0_af_ld),
    .pmp_resp_ld         (io_tlb_req_pmp_resp_ld),
    .pmp_resp_mmio       (io_tlb_req_pmp_resp_mmio),
    .out_ready           (io_out_req_ready),
    .out_valid           (io_out_req_valid),
    .out_tag             (io_out_req_bits_tag),
    .out_set             (io_out_req_bits_set),
    .out_vaddr           (io_out_req_bits_vaddr),
    .out_needT           (io_out_req_bits_needT),
    .out_source          (io_out_req_bits_source)
  );

endmodule
