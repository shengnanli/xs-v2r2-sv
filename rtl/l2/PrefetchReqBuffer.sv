// ============================================================================
// PrefetchReqBuffer —— L2 (v)BOP prefetch TLB-request filter buffer
//                       (可读手写核 xs_PrefetchReqBuffer_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden PrefetchReqBuffer.sv(firtool 展平的 16 条目 filter buffer +
// 两个 RRArbiterInit 轮转仲裁器)。逻辑等价 bug-for-bug。
//
// 功能:
//   * REQ_FILTER_SIZE=16 条目 buffer, 每条目存 BopReqBufferEntry:
//       paddrValid / vaddrNoOffset(44b) / baseVaddr(44b) / paddrNoOffset(50b) /
//       replayEn / replayCnt(4b) / needT / source(7b), 外加 valids 位。
//   * s0 look-up: 入站 BOP 请求先做去重/合并过滤:
//       - s0_conflict_prev: 与上一拍入站请求同 block flag(full_vaddr[49:6]) → 丢弃;
//       - s0_match: 与任一 valid 条目 {vaddrNoOffset,baseVaddr,needT,source} 全同 → 合并丢弃;
//       - s0_has_invalid_way: 无空槽 → 丢弃(满则丢新请求, 无替换);
//       s0_req_valid = valid & ~conflict & ~match & has_invalid_way。
//   * 分配: s0 选首个空槽(PriorityEncoderOH) → s1 打拍(s1_invalid_oh) → 写入条目。
//   * tlb 流水: s0 仲裁(tlb_req_arb) → RegNext 一拍送 tlb 请求 → s2 收 resp → s3 收 pmp;
//       tlb_fired → update_paddr(填 paddrNoOffset, 置 paddrValid);
//       miss & replayEn → 丢弃(miss_drop);
//       miss & ~replayEn → 首次重试(replayCnt=10, replayEn=1, 计数器倒数暂停 tlb 发送);
//       excp(pf/gpf/af/pmp.ld/pmp.mmio/pbmt-uncache) → 丢弃(exp_drop)。
//   * 发射: paddrValid 条目送 pf_req_arb 仲裁 → io_out_req;
//       pf_fired(io_out fire 对应条目) → 清 valid(发完即释放)。
//   * replayCnt: valid & replayCnt!=0 时每拍倒数减 1(暂缓该条目 tlb 重发)。
//
// 位宽(与 golden 逐位一致):
//   full_vaddr[49:0](fullVAddrBits=50) base_vaddr[43:0](=50-offsetBits(6)=44)
//   source[6:0](sourceIdBits=7) out.tag[32:0](fullTagBits=33) out.set[8:0](setBits=9)
//   out.vaddr[43:0] tlb.vaddr[49:0] paddr_resp[47:0]
//   out.tag = paddrNoOffset[41:9]  out.set = paddrNoOffset[8:0]
//   update_paddr: paddrNoOffset <= {8'h0, resp.paddr[47:6]}(=paddr(47,6) 零扩到 50)
//   firstTlbReplayCnt = 10(golden Constantin 展开常量 4'hA)
//
// 两个 RRArbiterInit(tlb_req_arb=RRArbiterInit_12, pf_req_arb=RRArbiterInit_13)
// 在 FM 两侧 elaborate(确定性轮转逻辑, 非厂商宏)——impl 与 ref 同读同一子模块。
// ============================================================================

package xs_prefetchreqbuf_pkg;
  localparam int unsigned N          = 16;   // REQ_FILTER_SIZE
  localparam int unsigned FULLVA_W   = 50;   // fullVAddrBits
  localparam int unsigned OFFSET_W   = 6;    // offsetBits
  localparam int unsigned BLKVA_W    = FULLVA_W - OFFSET_W; // 44 = vaddrNoOffset/baseVaddr
  localparam int unsigned PADDRNO_W  = 50;   // paddrNoOffset(golden reg 宽 50)
  localparam int unsigned SRC_W      = 7;    // sourceIdBits
  localparam int unsigned TAG_W      = 33;   // fullTagBits(out.tag)
  localparam int unsigned SET_W      = 9;    // setBits(out.set)
  localparam int unsigned CNT_W      = 4;    // replayCnt
  localparam int unsigned PADDR_W    = 48;   // tlb resp paddr
  localparam int unsigned PBMT_W     = 2;
  localparam int unsigned TLBVA_W    = 50;   // tlb req vaddr = {vaddrNoOffset, 6'h0}
  localparam int unsigned CMD_W      = 3;

  // 首次 tlb miss 重试计数(golden Constantin 展开常量 = 10)
  localparam logic [CNT_W-1:0] FIRST_TLB_REPLAY_CNT = 4'hA;

  // buffer 条目(与 golden BopReqBufferEntry 字段/位宽逐位一致)
  typedef struct packed {
    logic                  paddrValid;
    logic [BLKVA_W-1:0]    vaddrNoOffset;
    logic [BLKVA_W-1:0]    baseVaddr;
    logic [PADDRNO_W-1:0]  paddrNoOffset;
    logic                  replayEn;
    logic [CNT_W-1:0]      replayCnt;
    logic                  needT;
    logic [SRC_W-1:0]      source;
  } bop_entry_t;
endpackage

// ----------------------------------------------------------------------------
// 可读核: struct 化条目数组 + generate 展开 16 条目 + 两个 RRArbiterInit 仲裁器
// ----------------------------------------------------------------------------
module xs_PrefetchReqBuffer_core
  import xs_prefetchreqbuf_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // 入站 BOP 请求(ValidIO)
  input  logic                io_in_req_valid,
  input  logic [FULLVA_W-1:0] io_in_req_bits_full_vaddr,
  input  logic [BLKVA_W-1:0]  io_in_req_bits_base_vaddr,
  input  logic                io_in_req_bits_needT,
  input  logic [SRC_W-1:0]    io_in_req_bits_source,

  // TLB 请求/响应(L2ToL1TlbIO)
  output logic                io_tlb_req_req_valid,
  output logic [TLBVA_W-1:0]  io_tlb_req_req_bits_vaddr,
  output logic [CMD_W-1:0]    io_tlb_req_req_bits_cmd,
  output logic                io_tlb_req_req_bits_kill,
  output logic                io_tlb_req_req_bits_no_translate,
  input  logic                io_tlb_req_resp_valid,
  input  logic [PADDR_W-1:0]  io_tlb_req_resp_bits_paddr_0,
  input  logic [PBMT_W-1:0]   io_tlb_req_resp_bits_pbmt,
  input  logic                io_tlb_req_resp_bits_miss,
  input  logic                io_tlb_req_resp_bits_excp_0_gpf_ld,
  input  logic                io_tlb_req_resp_bits_excp_0_pf_ld,
  input  logic                io_tlb_req_resp_bits_excp_0_af_ld,
  input  logic                io_tlb_req_pmp_resp_ld,
  input  logic                io_tlb_req_pmp_resp_mmio,

  // 出站 prefetch 请求(DecoupledIO)
  input  logic                io_out_req_ready,
  output logic                io_out_req_valid,
  output logic [TAG_W-1:0]    io_out_req_bits_tag,
  output logic [SET_W-1:0]    io_out_req_bits_set,
  output logic [BLKVA_W-1:0]  io_out_req_bits_vaddr,
  output logic                io_out_req_bits_needT,
  output logic [SRC_W-1:0]    io_out_req_bits_source
);

  // ======================= buffer 状态寄存器 =======================
  logic       valids  [N];
  bop_entry_t entries [N];

  // ======================= s0: 入站请求过滤(look-up) =======================
  // block flag = full_vaddr[49:6](去掉 6 位块偏移)
  logic [BLKVA_W-1:0] s0_in_flag;
  assign s0_in_flag = io_in_req_bits_full_vaddr[FULLVA_W-1:OFFSET_W];

  // 上一拍入站请求(用于相邻拍去重)
  logic               prev_in_valid;
  logic [FULLVA_W-1:0] prev_in_req_full_vaddr;
  logic               s0_conflict_prev;
  assign s0_conflict_prev =
      prev_in_valid
    & (io_in_req_bits_full_vaddr[FULLVA_W-1:OFFSET_W]
       == prev_in_req_full_vaddr[FULLVA_W-1:OFFSET_W]);

  // 与已有 valid 条目全字段相同 → 合并
  logic [N-1:0] s0_match_oh;
  for (genvar i = 0; i < N; i++) begin : g_match
    assign s0_match_oh[i] =
        valids[i]
      & (entries[i].vaddrNoOffset == s0_in_flag)
      & (entries[i].needT        == io_in_req_bits_needT)
      & (entries[i].source       == io_in_req_bits_source)
      & (entries[i].baseVaddr    == io_in_req_bits_base_vaddr);
  end
  logic s0_match;
  assign s0_match = |s0_match_oh;

  // 空槽向量(排除本拍已在分配途中的槽 alloc)
  logic [N-1:0] alloc;
  logic [N-1:0] s0_invalid_vec;
  for (genvar i = 0; i < N; i++) begin : g_invalid
    assign s0_invalid_vec[i] = ~valids[i] & ~alloc[i];
  end
  logic s0_has_invalid_way;
  assign s0_has_invalid_way = |s0_invalid_vec;

  // 首个空槽 one-hot(PriorityEncoderOH: 最低置位优先)
  logic [N-1:0] s0_invalid_oh;
  always_comb begin
    s0_invalid_oh = '0;
    for (int i = 0; i < N; i++) begin
      if (s0_invalid_vec[i]) begin
        s0_invalid_oh = '0;
        s0_invalid_oh[i] = 1'b1;
        break;
      end
    end
  end

  logic s0_req_valid;
  assign s0_req_valid =
      io_in_req_valid & ~s0_conflict_prev & ~s0_match & s0_has_invalid_way;

  // ======================= 仲裁器输入的 fire 向量 =======================
  logic [N-1:0] pf_arb_in_ready;
  logic [N-1:0] pf_arb_in_valid;
  logic [N-1:0] tlb_arb_in_ready;
  logic [N-1:0] tlb_arb_in_valid;

  logic [N-1:0] s0_pf_fire_oh;
  logic [N-1:0] s0_tlb_fire_oh;
  for (genvar i = 0; i < N; i++) begin : g_fire
    assign s0_pf_fire_oh[i]  = pf_arb_in_ready[i]  & pf_arb_in_valid[i];
    assign s0_tlb_fire_oh[i] = tlb_arb_in_ready[i] & tlb_arb_in_valid[i];
  end

  // ======================= s1: 分配打拍 =======================
  logic               s1_valid;
  logic [FULLVA_W-1:0] s1_in_req_full_vaddr;
  logic [BLKVA_W-1:0]  s1_in_req_base_vaddr;
  logic               s1_in_req_needT;
  logic [SRC_W-1:0]   s1_in_req_source;
  logic [N-1:0]       s1_invalid_oh;
  logic [N-1:0]       s1_tlb_fire_oh;

  // ======================= s2/s3: tlb 流水 =======================
  logic [N-1:0]       s2_tlb_fire_oh;
  logic [N-1:0]       s3_tlb_fire_oh;
  logic               s3_tlb_resp_valid;
  logic [PADDR_W-1:0] s3_tlb_resp_paddr_0;
  logic [PBMT_W-1:0]  s3_tlb_resp_pbmt;
  logic               s3_tlb_resp_miss;
  logic               s3_tlb_resp_excp_0_gpf_ld;
  logic               s3_tlb_resp_excp_0_pf_ld;
  logic               s3_tlb_resp_excp_0_af_ld;

  // s3 阶段共享的异常判定(与地址无关的公共项)
  logic s3_excp_common;
  assign s3_excp_common =
      s3_tlb_resp_excp_0_pf_ld | s3_tlb_resp_excp_0_gpf_ld
    | s3_tlb_resp_excp_0_af_ld | io_tlb_req_pmp_resp_ld
    | io_tlb_req_pmp_resp_mmio
    | (s3_tlb_resp_pbmt == 2'h1) | (s3_tlb_resp_pbmt == 2'h2); // Pbmt.isUncache

  // ======================= 每条目组合判定 =======================
  logic [N-1:0] exp_drop;
  logic [N-1:0] miss_drop;
  logic [N-1:0] miss_first_replay;
  logic [N-1:0] tlb_fired;
  for (genvar i = 0; i < N; i++) begin : g_entry_comb
    logic miss;
    assign alloc[i]     = s1_valid & s1_invalid_oh[i];
    assign exp_drop[i]  =
        s3_tlb_fire_oh[i] & s3_tlb_resp_valid & ~s3_tlb_resp_miss & s3_excp_common;
    assign miss         = s3_tlb_fire_oh[i] & s3_tlb_resp_valid & s3_tlb_resp_miss;
    assign tlb_fired[i] =
        s3_tlb_fire_oh[i] & s3_tlb_resp_valid & ~s3_tlb_resp_miss & ~exp_drop[i];
    assign miss_drop[i]         = miss & entries[i].replayEn;
    assign miss_first_replay[i] = miss & ~entries[i].replayEn;
  end

  // ======================= 条目状态更新(时序) =======================
  // valids: 异步复位(golden 首个 always @(posedge clock or posedge reset))
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N; i++) valids[i] <= 1'b0;
      prev_in_valid  <= 1'b0;
      s1_valid       <= 1'b0;
      s1_invalid_oh  <= '0;
      s1_tlb_fire_oh <= '0;
      s2_tlb_fire_oh <= '0;
      s3_tlb_fire_oh <= '0;
    end else begin
      for (int i = 0; i < N; i++) begin
        // 优先级: alloc 置 1; 否则 pf_fired 清 0; 否则 miss_drop/exp_drop 清 0;
        //         其余(tlb_fired / miss_first_replay / 无事)保持。
        // golden 展开式: alloc | ~pf_fire & (tlb_fired | ~miss_drop &
        //                (miss_first_replay | ~exp_drop)) & valids
        valids[i] <=
            alloc[i]
          | (~s0_pf_fire_oh[i]
             & (tlb_fired[i]
                | (~miss_drop[i] & (miss_first_replay[i] | ~exp_drop[i])))
             & valids[i]);
      end
      prev_in_valid  <= io_in_req_valid;
      s1_valid       <= s0_req_valid;
      if (s0_req_valid) s1_invalid_oh <= s0_invalid_oh;
      s1_tlb_fire_oh <= s0_tlb_fire_oh;
      s2_tlb_fire_oh <= s1_tlb_fire_oh;
      s3_tlb_fire_oh <= s2_tlb_fire_oh;
    end
  end

  // 条目 payload / paddr / replay(golden 第二个 always @(posedge clock), 无复位)
  always_ff @(posedge clock) begin
    for (int i = 0; i < N; i++) begin
      // paddrValid: alloc 清 0(新分配无 paddr); tlb_fired 置 1; 否则保持
      entries[i].paddrValid <= ~alloc[i] & (tlb_fired[i] | entries[i].paddrValid);

      // payload: 分配时写入; 否则 tlb_fired 更新 paddr
      if (alloc[i]) begin
        entries[i].vaddrNoOffset <= s1_in_req_full_vaddr[FULLVA_W-1:OFFSET_W];
        entries[i].baseVaddr     <= s1_in_req_base_vaddr;
        entries[i].paddrNoOffset <= '0;
        entries[i].needT         <= s1_in_req_needT;
        entries[i].source        <= s1_in_req_source;
      end else if (tlb_fired[i]) begin
        // update_paddr: paddr(47,6) 零扩到 50 位
        entries[i].paddrNoOffset <=
            {{(PADDRNO_W-(PADDR_W-OFFSET_W)){1'b0}}, s3_tlb_resp_paddr_0[PADDR_W-1:OFFSET_W]};
      end

      // replayEn: alloc/tlb_fired 清 0; 首次 miss-replay 置 1; 否则保持
      entries[i].replayEn <=
          ~(alloc[i] | tlb_fired[i])
        & ((~miss_drop[i] & miss_first_replay[i]) | entries[i].replayEn);

      // replayCnt: alloc/tlb_fired 清 0; 首次 miss-replay 装 10; 否则 valid 时倒数
      if (alloc[i] | tlb_fired[i]) begin
        entries[i].replayCnt <= 4'h0;
      end else if (miss_drop[i] | ~miss_first_replay[i]) begin
        if (valids[i] & (|entries[i].replayCnt))
          entries[i].replayCnt <= entries[i].replayCnt - 4'h1;
      end else begin
        entries[i].replayCnt <= FIRST_TLB_REPLAY_CNT;
      end
    end
  end

  // ======================= s1/s3 流水寄存器(无复位) =======================
  always_ff @(posedge clock) begin
    if (io_in_req_valid) prev_in_req_full_vaddr <= io_in_req_bits_full_vaddr;
    if (s0_req_valid) begin
      s1_in_req_full_vaddr <= io_in_req_bits_full_vaddr;
      s1_in_req_base_vaddr <= io_in_req_bits_base_vaddr;
      s1_in_req_needT      <= io_in_req_bits_needT;
      s1_in_req_source     <= io_in_req_bits_source;
    end
    s3_tlb_resp_valid <= io_tlb_req_resp_valid;
    if (io_tlb_req_resp_valid) begin
      s3_tlb_resp_paddr_0       <= io_tlb_req_resp_bits_paddr_0;
      s3_tlb_resp_pbmt          <= io_tlb_req_resp_bits_pbmt;
      s3_tlb_resp_miss          <= io_tlb_req_resp_bits_miss;
      s3_tlb_resp_excp_0_gpf_ld <= io_tlb_req_resp_bits_excp_0_gpf_ld;
      s3_tlb_resp_excp_0_pf_ld  <= io_tlb_req_resp_bits_excp_0_pf_ld;
      s3_tlb_resp_excp_0_af_ld  <= io_tlb_req_resp_bits_excp_0_af_ld;
    end
  end

  // ======================= tlb / pf 仲裁器输入 =======================
  logic [TLBVA_W-1:0] tlb_arb_in_vaddr [N];
  logic [TAG_W-1:0]   pf_arb_in_tag    [N];
  logic [SET_W-1:0]   pf_arb_in_set    [N];
  logic [BLKVA_W-1:0] pf_arb_in_vaddr  [N];
  logic               pf_arb_in_needT  [N];
  logic [SRC_W-1:0]   pf_arb_in_source [N];
  for (genvar i = 0; i < N; i++) begin : g_arb_in
    // tlb 请求: 条目 valid 且尚无 paddr 且 tlb 流水各级都没有正在处理它 且不在重试暂停
    assign tlb_arb_in_valid[i] =
        valids[i] & ~entries[i].paddrValid
      & ~s1_tlb_fire_oh[i] & ~s2_tlb_fire_oh[i] & ~s3_tlb_fire_oh[i]
      & ~(|entries[i].replayCnt);
    assign tlb_arb_in_vaddr[i] = {entries[i].vaddrNoOffset, {OFFSET_W{1'b0}}};

    // pf 请求: 条目 valid 且已拿到 paddr(can_send_pf)
    assign pf_arb_in_valid[i]  = valids[i] & entries[i].paddrValid;
    assign pf_arb_in_tag[i]    = entries[i].paddrNoOffset[41:9];
    assign pf_arb_in_set[i]    = entries[i].paddrNoOffset[8:0];
    assign pf_arb_in_vaddr[i]  = entries[i].baseVaddr;
    assign pf_arb_in_needT[i]  = entries[i].needT;
    assign pf_arb_in_source[i] = entries[i].source;
  end

  // ======================= tlb 请求输出寄存器(加一拍打拍) =======================
  logic               tlb_arb_out_valid;
  logic [TLBVA_W-1:0] tlb_arb_out_vaddr;

  logic               io_tlb_req_req_valid_REG;
  logic [TLBVA_W-1:0] io_tlb_req_req_bits_r_vaddr;
  logic [CMD_W-1:0]   io_tlb_req_req_bits_r_cmd;
  logic               io_tlb_req_req_bits_r_kill;
  logic               io_tlb_req_req_bits_r_no_translate;

  always_ff @(posedge clock) begin
    io_tlb_req_req_valid_REG <= tlb_arb_out_valid;
    if (tlb_arb_out_valid) begin
      io_tlb_req_req_bits_r_vaddr <= tlb_arb_out_vaddr;
      io_tlb_req_req_bits_r_cmd   <= 3'h0; // TlbCmd.read
    end
    io_tlb_req_req_bits_r_kill <=
        ~tlb_arb_out_valid & io_tlb_req_req_bits_r_kill;
    io_tlb_req_req_bits_r_no_translate <=
        ~tlb_arb_out_valid & io_tlb_req_req_bits_r_no_translate;
  end

  assign io_tlb_req_req_valid         = io_tlb_req_req_valid_REG;
  assign io_tlb_req_req_bits_vaddr    = io_tlb_req_req_bits_r_vaddr;
  assign io_tlb_req_req_bits_cmd      = io_tlb_req_req_bits_r_cmd;
  assign io_tlb_req_req_bits_kill     = io_tlb_req_req_bits_r_kill;
  assign io_tlb_req_req_bits_no_translate = io_tlb_req_req_bits_r_no_translate;

  // ======================= RRArbiterInit 实例化 =======================
  // tlb_req_arb: RRArbiterInit_12(仅 vaddr 字段, out.ready 恒 1 由内部固定)
  RRArbiterInit_12 tlb_req_arb (
    .clock               (clock),
    .reset               (reset),
    .io_in_0_ready       (tlb_arb_in_ready[0]),
    .io_in_0_valid       (tlb_arb_in_valid[0]),
    .io_in_0_bits_vaddr  (tlb_arb_in_vaddr[0]),
    .io_in_1_ready       (tlb_arb_in_ready[1]),
    .io_in_1_valid       (tlb_arb_in_valid[1]),
    .io_in_1_bits_vaddr  (tlb_arb_in_vaddr[1]),
    .io_in_2_ready       (tlb_arb_in_ready[2]),
    .io_in_2_valid       (tlb_arb_in_valid[2]),
    .io_in_2_bits_vaddr  (tlb_arb_in_vaddr[2]),
    .io_in_3_ready       (tlb_arb_in_ready[3]),
    .io_in_3_valid       (tlb_arb_in_valid[3]),
    .io_in_3_bits_vaddr  (tlb_arb_in_vaddr[3]),
    .io_in_4_ready       (tlb_arb_in_ready[4]),
    .io_in_4_valid       (tlb_arb_in_valid[4]),
    .io_in_4_bits_vaddr  (tlb_arb_in_vaddr[4]),
    .io_in_5_ready       (tlb_arb_in_ready[5]),
    .io_in_5_valid       (tlb_arb_in_valid[5]),
    .io_in_5_bits_vaddr  (tlb_arb_in_vaddr[5]),
    .io_in_6_ready       (tlb_arb_in_ready[6]),
    .io_in_6_valid       (tlb_arb_in_valid[6]),
    .io_in_6_bits_vaddr  (tlb_arb_in_vaddr[6]),
    .io_in_7_ready       (tlb_arb_in_ready[7]),
    .io_in_7_valid       (tlb_arb_in_valid[7]),
    .io_in_7_bits_vaddr  (tlb_arb_in_vaddr[7]),
    .io_in_8_ready       (tlb_arb_in_ready[8]),
    .io_in_8_valid       (tlb_arb_in_valid[8]),
    .io_in_8_bits_vaddr  (tlb_arb_in_vaddr[8]),
    .io_in_9_ready       (tlb_arb_in_ready[9]),
    .io_in_9_valid       (tlb_arb_in_valid[9]),
    .io_in_9_bits_vaddr  (tlb_arb_in_vaddr[9]),
    .io_in_10_ready      (tlb_arb_in_ready[10]),
    .io_in_10_valid      (tlb_arb_in_valid[10]),
    .io_in_10_bits_vaddr (tlb_arb_in_vaddr[10]),
    .io_in_11_ready      (tlb_arb_in_ready[11]),
    .io_in_11_valid      (tlb_arb_in_valid[11]),
    .io_in_11_bits_vaddr (tlb_arb_in_vaddr[11]),
    .io_in_12_ready      (tlb_arb_in_ready[12]),
    .io_in_12_valid      (tlb_arb_in_valid[12]),
    .io_in_12_bits_vaddr (tlb_arb_in_vaddr[12]),
    .io_in_13_ready      (tlb_arb_in_ready[13]),
    .io_in_13_valid      (tlb_arb_in_valid[13]),
    .io_in_13_bits_vaddr (tlb_arb_in_vaddr[13]),
    .io_in_14_ready      (tlb_arb_in_ready[14]),
    .io_in_14_valid      (tlb_arb_in_valid[14]),
    .io_in_14_bits_vaddr (tlb_arb_in_vaddr[14]),
    .io_in_15_ready      (tlb_arb_in_ready[15]),
    .io_in_15_valid      (tlb_arb_in_valid[15]),
    .io_in_15_bits_vaddr (tlb_arb_in_vaddr[15]),
    .io_out_valid        (tlb_arb_out_valid),
    .io_out_bits_vaddr   (tlb_arb_out_vaddr)
  );

  // pf_req_arb: RRArbiterInit_13(全 5 字段, 直接驱动 io_out_req)
  RRArbiterInit_13 pf_req_arb (
    .clock                (clock),
    .reset                (reset),
    .io_in_0_ready        (pf_arb_in_ready[0]),
    .io_in_0_valid        (pf_arb_in_valid[0]),
    .io_in_0_bits_tag     (pf_arb_in_tag[0]),
    .io_in_0_bits_set     (pf_arb_in_set[0]),
    .io_in_0_bits_vaddr   (pf_arb_in_vaddr[0]),
    .io_in_0_bits_needT   (pf_arb_in_needT[0]),
    .io_in_0_bits_source  (pf_arb_in_source[0]),
    .io_in_1_ready        (pf_arb_in_ready[1]),
    .io_in_1_valid        (pf_arb_in_valid[1]),
    .io_in_1_bits_tag     (pf_arb_in_tag[1]),
    .io_in_1_bits_set     (pf_arb_in_set[1]),
    .io_in_1_bits_vaddr   (pf_arb_in_vaddr[1]),
    .io_in_1_bits_needT   (pf_arb_in_needT[1]),
    .io_in_1_bits_source  (pf_arb_in_source[1]),
    .io_in_2_ready        (pf_arb_in_ready[2]),
    .io_in_2_valid        (pf_arb_in_valid[2]),
    .io_in_2_bits_tag     (pf_arb_in_tag[2]),
    .io_in_2_bits_set     (pf_arb_in_set[2]),
    .io_in_2_bits_vaddr   (pf_arb_in_vaddr[2]),
    .io_in_2_bits_needT   (pf_arb_in_needT[2]),
    .io_in_2_bits_source  (pf_arb_in_source[2]),
    .io_in_3_ready        (pf_arb_in_ready[3]),
    .io_in_3_valid        (pf_arb_in_valid[3]),
    .io_in_3_bits_tag     (pf_arb_in_tag[3]),
    .io_in_3_bits_set     (pf_arb_in_set[3]),
    .io_in_3_bits_vaddr   (pf_arb_in_vaddr[3]),
    .io_in_3_bits_needT   (pf_arb_in_needT[3]),
    .io_in_3_bits_source  (pf_arb_in_source[3]),
    .io_in_4_ready        (pf_arb_in_ready[4]),
    .io_in_4_valid        (pf_arb_in_valid[4]),
    .io_in_4_bits_tag     (pf_arb_in_tag[4]),
    .io_in_4_bits_set     (pf_arb_in_set[4]),
    .io_in_4_bits_vaddr   (pf_arb_in_vaddr[4]),
    .io_in_4_bits_needT   (pf_arb_in_needT[4]),
    .io_in_4_bits_source  (pf_arb_in_source[4]),
    .io_in_5_ready        (pf_arb_in_ready[5]),
    .io_in_5_valid        (pf_arb_in_valid[5]),
    .io_in_5_bits_tag     (pf_arb_in_tag[5]),
    .io_in_5_bits_set     (pf_arb_in_set[5]),
    .io_in_5_bits_vaddr   (pf_arb_in_vaddr[5]),
    .io_in_5_bits_needT   (pf_arb_in_needT[5]),
    .io_in_5_bits_source  (pf_arb_in_source[5]),
    .io_in_6_ready        (pf_arb_in_ready[6]),
    .io_in_6_valid        (pf_arb_in_valid[6]),
    .io_in_6_bits_tag     (pf_arb_in_tag[6]),
    .io_in_6_bits_set     (pf_arb_in_set[6]),
    .io_in_6_bits_vaddr   (pf_arb_in_vaddr[6]),
    .io_in_6_bits_needT   (pf_arb_in_needT[6]),
    .io_in_6_bits_source  (pf_arb_in_source[6]),
    .io_in_7_ready        (pf_arb_in_ready[7]),
    .io_in_7_valid        (pf_arb_in_valid[7]),
    .io_in_7_bits_tag     (pf_arb_in_tag[7]),
    .io_in_7_bits_set     (pf_arb_in_set[7]),
    .io_in_7_bits_vaddr   (pf_arb_in_vaddr[7]),
    .io_in_7_bits_needT   (pf_arb_in_needT[7]),
    .io_in_7_bits_source  (pf_arb_in_source[7]),
    .io_in_8_ready        (pf_arb_in_ready[8]),
    .io_in_8_valid        (pf_arb_in_valid[8]),
    .io_in_8_bits_tag     (pf_arb_in_tag[8]),
    .io_in_8_bits_set     (pf_arb_in_set[8]),
    .io_in_8_bits_vaddr   (pf_arb_in_vaddr[8]),
    .io_in_8_bits_needT   (pf_arb_in_needT[8]),
    .io_in_8_bits_source  (pf_arb_in_source[8]),
    .io_in_9_ready        (pf_arb_in_ready[9]),
    .io_in_9_valid        (pf_arb_in_valid[9]),
    .io_in_9_bits_tag     (pf_arb_in_tag[9]),
    .io_in_9_bits_set     (pf_arb_in_set[9]),
    .io_in_9_bits_vaddr   (pf_arb_in_vaddr[9]),
    .io_in_9_bits_needT   (pf_arb_in_needT[9]),
    .io_in_9_bits_source  (pf_arb_in_source[9]),
    .io_in_10_ready       (pf_arb_in_ready[10]),
    .io_in_10_valid       (pf_arb_in_valid[10]),
    .io_in_10_bits_tag    (pf_arb_in_tag[10]),
    .io_in_10_bits_set    (pf_arb_in_set[10]),
    .io_in_10_bits_vaddr  (pf_arb_in_vaddr[10]),
    .io_in_10_bits_needT  (pf_arb_in_needT[10]),
    .io_in_10_bits_source (pf_arb_in_source[10]),
    .io_in_11_ready       (pf_arb_in_ready[11]),
    .io_in_11_valid       (pf_arb_in_valid[11]),
    .io_in_11_bits_tag    (pf_arb_in_tag[11]),
    .io_in_11_bits_set    (pf_arb_in_set[11]),
    .io_in_11_bits_vaddr  (pf_arb_in_vaddr[11]),
    .io_in_11_bits_needT  (pf_arb_in_needT[11]),
    .io_in_11_bits_source (pf_arb_in_source[11]),
    .io_in_12_ready       (pf_arb_in_ready[12]),
    .io_in_12_valid       (pf_arb_in_valid[12]),
    .io_in_12_bits_tag    (pf_arb_in_tag[12]),
    .io_in_12_bits_set    (pf_arb_in_set[12]),
    .io_in_12_bits_vaddr  (pf_arb_in_vaddr[12]),
    .io_in_12_bits_needT  (pf_arb_in_needT[12]),
    .io_in_12_bits_source (pf_arb_in_source[12]),
    .io_in_13_ready       (pf_arb_in_ready[13]),
    .io_in_13_valid       (pf_arb_in_valid[13]),
    .io_in_13_bits_tag    (pf_arb_in_tag[13]),
    .io_in_13_bits_set    (pf_arb_in_set[13]),
    .io_in_13_bits_vaddr  (pf_arb_in_vaddr[13]),
    .io_in_13_bits_needT  (pf_arb_in_needT[13]),
    .io_in_13_bits_source (pf_arb_in_source[13]),
    .io_in_14_ready       (pf_arb_in_ready[14]),
    .io_in_14_valid       (pf_arb_in_valid[14]),
    .io_in_14_bits_tag    (pf_arb_in_tag[14]),
    .io_in_14_bits_set    (pf_arb_in_set[14]),
    .io_in_14_bits_vaddr  (pf_arb_in_vaddr[14]),
    .io_in_14_bits_needT  (pf_arb_in_needT[14]),
    .io_in_14_bits_source (pf_arb_in_source[14]),
    .io_in_15_ready       (pf_arb_in_ready[15]),
    .io_in_15_valid       (pf_arb_in_valid[15]),
    .io_in_15_bits_tag    (pf_arb_in_tag[15]),
    .io_in_15_bits_set    (pf_arb_in_set[15]),
    .io_in_15_bits_vaddr  (pf_arb_in_vaddr[15]),
    .io_in_15_bits_needT  (pf_arb_in_needT[15]),
    .io_in_15_bits_source (pf_arb_in_source[15]),
    .io_out_ready         (io_out_req_ready),
    .io_out_valid         (io_out_req_valid),
    .io_out_bits_tag      (io_out_req_bits_tag),
    .io_out_bits_set      (io_out_req_bits_set),
    .io_out_bits_vaddr    (io_out_req_bits_vaddr),
    .io_out_bits_needT    (io_out_req_bits_needT),
    .io_out_bits_source   (io_out_req_bits_source)
  );

endmodule
