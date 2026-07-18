// =============================================================================
// ptwcache_pipe.svh —— 三级流水握手 + bypassed 在途累积（InsideStageConnect）
//
// 对应 Scala：
//   PipelineConnect(stageReq, stageDelay(0), stageDelay(1).ready, flush, rwHarzad)
//   InsideStageConnect(stageDelay(0), stageDelay(1), stageDelay_valid_1cycle)
//   PipelineConnect(stageDelay(1), stageCheck(0), stageCheck(1).ready, flush)
//   InsideStageConnect(stageCheck(0), stageCheck(1), stageCheck_valid_1cycle)
//   PipelineConnect(stageCheck(1), stageResp, io.resp.ready, flush)
//
// 关键：InsideStageConnect 把 stage(0)→stage(1) 做成组合直通（valid/ready/bits 相同），
// 只对 bypassed 向量逐位累积「refill 正写同项」的标记（refill_bypass && refill.valid）。
// 因此真正的流水寄存器只有三个：valid(stageDelay)、valid_1(stageCheck)、valid_2(stageResp)。
// =============================================================================

  // ---- InsideStageConnect 的 bypassed 累积寄存器（每级 4 位）----
  logic [3:0] bypassed_reg_delay, bypassed_reg_check;
  logic       stageResp_ready_int;
  logic [3:0] bypass_check_lv;     // 由 query.svh 赋值（按 stageCheck[0].bits.vpn）

  // refill_bypass(vpn, level)：把各 level 的命中条件按当前 stage 的 vpn/s2xlate 算好。
  // 在 query.svh 里给 refill_bypass_l*_in 赋真正的逐 level 值（与 stageReq/Delay/Check 对应）。
  // 这里 InsideStageConnect 用「该 stage in.bits.vpn」算 bypass，逻辑在 query.svh 中提供
  // 对应 wire：bypass_delay_in[3:0]（用 stageDelay[0].bits.vpn）。

  // ---- stageDelay[0]：PipelineConnect(stageReq -> stageDelay[0]) ----
  // in_ready = out_ready | ~valid ；这里 out=stageDelay[1]，但 InsideStageConnect 使
  // stageDelay[1].ready = ~valid | stageCheck[0].ready
  assign stageReq_ready    = stageDelay_ready[1] & ~rwHazard;
  wire leftFire_d = stageReq_valid & stageDelay_ready[1] & ~rwHazard;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageDelay_valid[0] <= 1'b0;
    else stageDelay_valid[0] <= ~flush & (leftFire_d | (~stageCheck_ready[0] & stageDelay_valid[0]));
  end
  always_ff @(posedge clock) begin
    if (leftFire_d) begin
      stageDelay_bits[0].req_info  <= stageReq_bits.req_info;
      stageDelay_bits[0].isFirst   <= stageReq_bits.isFirst;
      stageDelay_bits[0].isHptwReq <= stageReq_bits.isHptwReq;
      stageDelay_bits[0].hptwId    <= stageReq_bits.hptwId;
      stageDelay_bits[0].bypassed  <= stageReq_bits.bypassed;
    end
  end

  // ---- InsideStageConnect(stageDelay[0] -> stageDelay[1]) ----
  // 组合直通：valid/bits 相同，ready 反向；bypassed 累积。inFire = stageDelay_valid_1cycle
  assign stageDelay_ready[1] = ~stageDelay_valid[1] | stageCheck_ready[0];
  assign stageDelay_valid[1] = stageDelay_valid[0];
  assign stageDelay_ready[0] = ~stageDelay_valid[0] | stageCheck_ready[0];

  // bypassed 累积：bypass_wire = refill_bypass(in.vpn,i) && refill.valid
  // refill_bypass_*_in 是按 stageDelay[0].bits.vpn 算（见 query.svh）。
  logic [3:0] bypass_delay_wire;
  assign bypass_delay_wire = {refill_bypass_l3_in, refill_bypass_l2_in, refill_bypass_l1_in, refill_bypass_l0_in}
                             & {4{refill_valid}};
  always_ff @(posedge clock) begin
    if (stageDelay_valid_1cycle)      bypassed_reg_delay <= bypass_delay_wire;
    else if (refill_valid)            bypassed_reg_delay <= bypassed_reg_delay | bypass_delay_wire;
  end
  // out.bits.bypassed = in.bypassed | (bypass_wire | (bypassed_reg & !inFire))
  // 注：stageReq.bits.bypassed 恒 0（golden io.req 无该字段，firtool 已把
  //     stageDelay(0) 的 bypassed 载荷寄存器折叠消去），这里不读该常 0 寄存器字段
  //     （保持它无读者→FM Unread 不比对；X 行为也与 golden 折叠后一致）。
  always_comb begin
    stageDelay_bits[1] = stageDelay_bits[0];
    stageDelay_bits[1].bypassed =
        bypass_delay_wire | (bypassed_reg_delay & {4{~stageDelay_valid_1cycle}});
  end

  // ---- stageCheck[0]：PipelineConnect(stageDelay[1] -> stageCheck[0]) ----
  wire leftFire_c = stageDelay_valid[1] & stageCheck_ready[0];
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageCheck_valid[0] <= 1'b0;
    else stageCheck_valid[0] <= ~flush & (leftFire_c | (~stageResp_ready_int & stageCheck_valid[0]));
  end
  always_ff @(posedge clock) begin
    if (leftFire_c) begin
      stageCheck_bits[0].req_info  <= stageDelay_bits[1].req_info;
      stageCheck_bits[0].isFirst   <= stageDelay_bits[1].isFirst;
      stageCheck_bits[0].isHptwReq <= stageDelay_bits[1].isHptwReq;
      stageCheck_bits[0].hptwId    <= stageDelay_bits[1].hptwId;
      stageCheck_bits[0].bypassed  <= stageDelay_bits[1].bypassed;
    end
  end

  // ---- InsideStageConnect(stageCheck[0] -> stageCheck[1]) ----
  assign stageResp_ready_int = ~stageResp_valid_r | resp_ready;
  assign stageCheck_ready[1] = ~stageCheck_valid[1] | stageResp_ready_int;
  assign stageCheck_valid[1] = stageCheck_valid[0];
  assign stageCheck_ready[0] = ~stageCheck_valid[0] | stageResp_ready_int;

  logic [3:0] bypass_check_wire;
  // 按 stageCheck[0].bits.vpn 算的 refill_bypass（见 query.svh 提供 bypass_check_lv）
  assign bypass_check_wire = bypass_check_lv & {4{refill_valid}};
  always_ff @(posedge clock) begin
    if (stageCheck_valid_1cycle)      bypassed_reg_check <= bypass_check_wire;
    else if (refill_valid)            bypassed_reg_check <= bypassed_reg_check | bypass_check_wire;
  end
  always_comb begin
    stageCheck_bits[1] = stageCheck_bits[0];
    stageCheck_bits[1].bypassed = stageCheck_bits[0].bypassed
        | (bypass_check_wire | (bypassed_reg_check & {4{~stageCheck_valid_1cycle}}));
  end

  // ---- stageResp：PipelineConnect(stageCheck[1] -> stageResp) ----
  wire leftFire_r = stageCheck_valid[1] & stageResp_ready_int;
  assign stageResp_ready = stageResp_ready_int;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageResp_valid_r <= 1'b0;
    else stageResp_valid_r <= ~flush & (leftFire_r | (~resp_ready & stageResp_valid_r));
  end
  always_ff @(posedge clock) begin
    if (leftFire_r) begin
      stageResp_bits.req_info  <= stageCheck_bits[1].req_info;
      stageResp_bits.isFirst   <= stageCheck_bits[1].isFirst;
      stageResp_bits.isHptwReq <= stageCheck_bits[1].isHptwReq;
      stageResp_bits.hptwId    <= stageCheck_bits[1].hptwId;
      stageResp_bits.bypassed  <= stageCheck_bits[1].bypassed;
    end
  end

  // ---- 单拍 fire 脉冲（OneCycleValid：fire 寄存一拍，flush 清零）----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageDelay_valid_1cycle <= 1'b0;
    else       stageDelay_valid_1cycle <= ~flush & stageReq_fire;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageCheck_valid_1cycle <= 1'b0;
    else       stageCheck_valid_1cycle <= ~flush & stageDelay1_fire;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageResp_valid_1cycle_dup <= 2'b0;
    else begin
      stageResp_valid_1cycle_dup[0] <= ~flush & stageCheck1_fire;
      stageResp_valid_1cycle_dup[1] <= ~flush & stageCheck1_fire;
    end
  end
