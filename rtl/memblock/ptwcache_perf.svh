// =============================================================================
// ptwcache_perf.svh —— 8 个 perf 输出（HasPerfEvents 的 perfEvents Seq）
//
// golden：每个 perf_value = 事件脉冲延迟 2 拍后零扩展到 6 位（REG -> REG_1）。
// 事件（与 generatePerfEvent 对齐）：
//   0 access     = !from_pre(resp.source) && io.resp.fire
//   1 l2_hit     = check_res.l2.hit（stageCheck 级）
//   2 l1_hit     = check_res.l1.hit
//   3 l0_hit     = check_res.l0.hit
//   4 sp_hit     = spHit
//   5 pte_hit    = l0.hit | spHit
//   6 rwHarzad   = io.req.valid && !io.req.ready
//   7 out_blocked= stageResp.valid && !io.resp.ready
// =============================================================================

  wire base_valid_access_0 = (stageResp_bits.req_info.source != 2'h2) && stageResp_fire;
  logic [7:0] perf_event;
  assign perf_event[0] = base_valid_access_0;
  assign perf_event[1] = check_res.l2.hit;
  assign perf_event[2] = check_res.l1.hit;
  assign perf_event[3] = check_res.l0.hit;
  assign perf_event[4] = spHit;
  assign perf_event[5] = check_res.l0.hit | spHit;
  assign perf_event[6] = req_valid && ~req_ready;
  assign perf_event[7] = stageResp_valid_r && ~resp_ready;

  logic [7:0] perf_reg, perf_reg_1;
  always_ff @(posedge clock) begin
    perf_reg   <= perf_event;
    perf_reg_1 <= perf_reg;
  end
  for (gi = 0; gi < 8; gi++) begin : g_perf
    assign perf[gi] = {5'h0, perf_reg_1[gi]};
  end

  // SRAM 时钟门控使能（l0/l1_masked_clock 的 en）：
  //   l1_en = stageReq.fire | (!flush_dup[1] && refill.levelOH.l1)
  //   l0_en = stageReq.fire | (!flush_dup[0] && refill.levelOH.l0)
  assign l1_clock_en = stageReq_fire | (~flush_dup[1] & refill_levelOH_l1);
  assign l0_clock_en = stageReq_fire | (~flush_dup[0] & refill_levelOH_l0);
