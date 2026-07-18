// =============================================================================
// ptwcache_query.svh —— 各级 tag/asid/vmid 命中匹配（三级流水相位对齐）
//
// 相位（最易错处，见 docs）：
//   L3/L2/SP（寄存器堆）：hitVecT 在 stageReq 组合算出 → hitVec=RegEnable(_,stageReq.fire)
//     → ppn/pbmt/pre/hit 用 DataHoldBypass(_, stageDelay_valid_1cycle) 在 stageDelay 锁存
//     → l*Hit*/= RegEnable(_, stageDelay[1].fire) 对齐到 check_res。
//   L1/L0（SRAM）：stageReq.fire 发 SRAM 读；vVec/hVec/gVec=RegEnable(_,stageReq.fire)；
//     SRAM 读出 data_resp=DataHoldBypass(_,stageDelay_valid_1cycle)；hitVec_delay 在
//     stageDelay 用 delay_vpn 算 → hitVec=RegEnable(_,stageDelay[1].fire)；
//     hit/ppn 在 stageCheck 用 check_vpn 选 sector。
//
// 所有级最终汇总到 check_res（在 stageCheck），再寄存成 resp_res（stageResp）。
// =============================================================================

  // ---- 各 stage 的 vpn / h ----
  wire [VPN_W-1:0] delay_vpn = stageDelay_bits[0].req_info.vpn;
  wire [1:0]       delay_h   = change_h(stageDelay_bits[0].req_info.s2xlate);
  wire [VPN_W-1:0] check_vpn = stageCheck_bits[0].req_info.vpn;

  // refill_bypass 各 level（按某个 stage 的 vpn 算）：
  //   refill 正写 && level 相同 && vpn 在该 level 对齐 && change_h 相同
  wire [1:0] refill_h0 = change_h(refill_req_info_dup_0.s2xlate);
  function automatic logic vpn_match_lv(input logic [VPN_W-1:0] a, input logic [VPN_W-1:0] b, input int lvl);
    // vpn(vpnLen-1, vpnnLen*level+3) 相等。用显式 bit-slice（与 golden 一致），
    // 避免 [VPN_W-1:0]>>变量 在 VCS 下的求值歧义。
    logic [VPN_W-1:0] msk;
    msk = ('1 << (VPNN_W*lvl + 3));   // 高位段掩码
    return ((a & msk) == (b & msk));
  endfunction
  // 注意：refill_* / refill_h0 必须作为「显式入参」传入。否则 VCS 对
  //   `wire = refill_bypass_vec(stage_vpn, stage_s2x)` 只按函数实参建敏感表，
  //   refill 侧信号变化时不重算 → bypass 漏置（实测 toHptw_bypassed g=1/i=0 根因）。
  function automatic logic [3:0] refill_bypass_vec(
      input logic [VPN_W-1:0] vpn, input logic [1:0] s2x,
      input logic rfv, input logic [1:0] rlvl,
      input logic [VPN_W-1:0] rvpn, input logic [1:0] rh0);
    logic [3:0] r;
    logic same_h;
    same_h = (change_h(s2x) == rh0);
    r[0] = rfv & (rlvl == 2'h0) & vpn_match_lv(rvpn, vpn, 0) & same_h;
    r[1] = rfv & (rlvl == 2'h1) & vpn_match_lv(rvpn, vpn, 1) & same_h;
    r[2] = rfv & (rlvl == 2'h2) & vpn_match_lv(rvpn, vpn, 2) & same_h;
    r[3] = rfv & (rlvl == 2'h3) & vpn_match_lv(rvpn, vpn, 3) & same_h;
    return r;
  endfunction

  // 给 pipe.svh 用的 InsideStageConnect bypass（注意：pipe 里已乘 refill_valid，这里给「无 refill_valid 门」的纯 level 命中？
  // Scala refill_bypass 本身含 io.refill.valid，pipe 里 bypass_wire = refill_bypass(...) && io.refill.valid。
  // 由于 refill_bypass_vec 已含 refill_valid，pipe 再 &refill_valid 等价，保持一致。）
  wire [3:0] rbv_delay = refill_bypass_vec(stageDelay_bits[0].req_info.vpn, stageDelay_bits[0].req_info.s2xlate,
                                           refill_valid, refill_level_dup_0, refill_req_info_dup_0.vpn, refill_h0);
  assign {refill_bypass_l3_in, refill_bypass_l2_in, refill_bypass_l1_in, refill_bypass_l0_in} = rbv_delay;
  assign bypass_check_lv = refill_bypass_vec(stageCheck_bits[0].req_info.vpn, stageCheck_bits[0].req_info.s2xlate,
                                             refill_valid, refill_level_dup_0, refill_req_info_dup_0.vpn, refill_h0);

  // ===========================================================================
  // L3：16 项全相联非叶
  // ===========================================================================
  logic [L3_SIZE-1:0] l3_hitVecT, l3_hitVec;
  for (gi = 0; gi < L3_SIZE; gi++) begin : g_l3_hit
    // golden: l3_i_tag(11b)=refill vpn[37:27]；refill 侧已改为把 vpn[37:27] 存进
    // tag[10:0]（高 9 位补 0 无读者），命中比低 11 位即 golden 语义。
    wire l3_tag_hit = (l3[gi].tag[L3_TAG_W-1:0] == vpn_search[VPN_W-1 -: L3_TAG_W]);
    assign l3_hitVecT[gi] = nonleaf_hit(l3_tag_hit, l3[gi].asid, l3[gi].vmid, l3g[gi],
                              csr_satp_asid[2], csr_vsatp_asid[2], csr_hgatp_vmid[2], h_search)
                            && l3v[gi] && (h_search == l3h[gi]);
  end
  always_ff @(posedge clock) if (stageReq_fire) l3_hitVec <= l3_hitVecT;

  // stageDelay：ParallelPriorityMux + DataHoldBypass
  //   DataHoldBypass(x, en)：en 拍组合直通 x，否则保持上一次 en 拍锁存值。
  //   故 l3_hit_d 等在 stageDelay_valid_1cycle 拍即为新值（与 golden 同相），供 stageDelay1_fire 锁存。
  logic [GVPN_W-1:0] l3_hitPPN_h;  logic [PBMT_W-1:0] l3_hitPbmt_h;
  logic l3_hitPre_h, l3_hit_h;     // held 寄存器
  logic [GVPN_W-1:0] l3_hitPPN_d;  logic [PBMT_W-1:0] l3_hitPbmt_d;
  logic l3_hitPre_d, l3_hit_d;     // DataHoldBypass 输出（组合）
  logic [GVPN_W-1:0] l3_ppn_mux;   logic [PBMT_W-1:0] l3_pbmt_mux;  logic l3_pre_mux;
  always_comb begin
    // ParallelPriorityMux：最低命中下标优先；全 0 时默认取最后一项（golden firtool 形态）。
    l3_ppn_mux = l3[L3_SIZE-1].ppn; l3_pbmt_mux = l3[L3_SIZE-1].pbmt; l3_pre_mux = l3[L3_SIZE-1].prefetch;
    for (int i = L3_SIZE-1; i >= 0; i--) if (l3_hitVec[i]) begin
      l3_ppn_mux = l3[i].ppn; l3_pbmt_mux = l3[i].pbmt; l3_pre_mux = l3[i].prefetch;
    end
  end
  always_ff @(posedge clock) if (stageDelay_valid_1cycle) begin
    l3_hitPPN_h <= l3_ppn_mux; l3_hitPbmt_h <= l3_pbmt_mux; l3_hitPre_h <= l3_pre_mux; l3_hit_h <= |l3_hitVec;
  end
  assign l3_hit_d     = stageDelay_valid_1cycle ? (|l3_hitVec) : l3_hit_h;
  assign l3_hitPPN_d  = stageDelay_valid_1cycle ? l3_ppn_mux   : l3_hitPPN_h;
  assign l3_hitPbmt_d = stageDelay_valid_1cycle ? l3_pbmt_mux  : l3_hitPbmt_h;
  assign l3_hitPre_d  = stageDelay_valid_1cycle ? l3_pre_mux   : l3_hitPre_h;
  // stageCheck 对齐
  logic l3Hit; logic [GVPN_W-1:0] l3HitPPN; logic [PBMT_W-1:0] l3HitPbmt; logic l3Pre;
  always_ff @(posedge clock) if (stageDelay1_fire) begin
    l3Hit <= l3_hit_d; l3HitPPN <= l3_hitPPN_d; l3HitPbmt <= l3_hitPbmt_d; l3Pre <= l3_hitPre_d;
  end
  // PLRU access：命中且 stageDelay_valid_1cycle
  wire l3_access_en = l3_hit_d && stageDelay_valid_1cycle;
  wire [3:0] l3_hitWay_d = oh16_to_idx(l3_hitVec);

  // ===========================================================================
  // L2：16 项全相联非叶（结构同 L3）
  // ===========================================================================
  logic [L2_SIZE-1:0] l2_hitVecT, l2_hitVec;
  for (gi = 0; gi < L2_SIZE; gi++) begin : g_l2_hit
    wire l2_tag_hit = (l2[gi].tag[L2_TAG_W-1:0] == vpn_search[VPN_W-1 -: L2_TAG_W]);
    assign l2_hitVecT[gi] = nonleaf_hit(l2_tag_hit, l2[gi].asid, l2[gi].vmid, l2g[gi],
                              csr_satp_asid[2], csr_vsatp_asid[2], csr_hgatp_vmid[2], h_search)
                            && l2v[gi] && (h_search == l2h[gi]);
  end
  always_ff @(posedge clock) if (stageReq_fire) l2_hitVec <= l2_hitVecT;
  logic [GVPN_W-1:0] l2_hitPPN_h; logic [PBMT_W-1:0] l2_hitPbmt_h; logic l2_hitPre_h, l2_hit_h;
  logic [GVPN_W-1:0] l2_hitPPN_d; logic [PBMT_W-1:0] l2_hitPbmt_d; logic l2_hitPre_d, l2_hit_d;
  logic [GVPN_W-1:0] l2_ppn_mux; logic [PBMT_W-1:0] l2_pbmt_mux; logic l2_pre_mux;
  always_comb begin
    l2_ppn_mux = l2[L2_SIZE-1].ppn; l2_pbmt_mux = l2[L2_SIZE-1].pbmt; l2_pre_mux = l2[L2_SIZE-1].prefetch;
    for (int i = L2_SIZE-1; i >= 0; i--) if (l2_hitVec[i]) begin
      l2_ppn_mux = l2[i].ppn; l2_pbmt_mux = l2[i].pbmt; l2_pre_mux = l2[i].prefetch;
    end
  end
  always_ff @(posedge clock) if (stageDelay_valid_1cycle) begin
    l2_hitPPN_h <= l2_ppn_mux; l2_hitPbmt_h <= l2_pbmt_mux; l2_hitPre_h <= l2_pre_mux; l2_hit_h <= |l2_hitVec;
  end
  assign l2_hit_d     = stageDelay_valid_1cycle ? (|l2_hitVec) : l2_hit_h;
  assign l2_hitPPN_d  = stageDelay_valid_1cycle ? l2_ppn_mux   : l2_hitPPN_h;
  assign l2_hitPbmt_d = stageDelay_valid_1cycle ? l2_pbmt_mux  : l2_hitPbmt_h;
  assign l2_hitPre_d  = stageDelay_valid_1cycle ? l2_pre_mux   : l2_hitPre_h;
  logic l2Hit; logic [GVPN_W-1:0] l2HitPPN; logic [PBMT_W-1:0] l2HitPbmt; logic l2Pre;
  always_ff @(posedge clock) if (stageDelay1_fire) begin
    l2Hit <= l2_hit_d; l2HitPPN <= l2_hitPPN_d; l2HitPbmt <= l2_hitPbmt_d; l2Pre <= l2_hitPre_d;
  end
  wire l2_access_en = l2_hit_d && stageDelay_valid_1cycle;
  wire [3:0] l2_hitWay_d = oh16_to_idx(l2_hitVec);

  // ===========================================================================
  // L1：8 set × 2 way（SRAM）。vVec/hVec/gVec 取本 set 的 way 向量。
  // ===========================================================================
  // stageReq：取 set 的 v/h/g 向量
  wire [L1_SET_IDX_W-1:0] l1_ridx = l1_set_idx(vpn_search);
  logic [L1_WAYS-1:0] l1vVec_req, l1gVec_req;
  logic [1:0] l1hVec_req [L1_WAYS];
  always_comb begin
    for (int w = 0; w < L1_WAYS; w++) begin
      l1vVec_req[w] = l1v[l1_ridx*L1_WAYS + w];
      l1gVec_req[w] = l1g[l1_ridx*L1_WAYS + w];
      l1hVec_req[w] = l1h[l1_ridx][w];
    end
  end
  logic [L1_WAYS-1:0] l1vVec_delay, l1gVec_delay;
  logic [1:0] l1hVec_delay [L1_WAYS];
  always_ff @(posedge clock) if (stageReq_fire) begin
    l1vVec_delay <= l1vVec_req; l1gVec_delay <= l1gVec_req;
    for (int w = 0; w < L1_WAYS; w++) l1hVec_delay[w] <= l1hVec_req[w];
  end
  // SRAM 读出锁存（DataHoldBypass）
  l1_sram_entry_t l1_data_resp [L1_WAYS];
  logic l1_dhb_en;
  always_ff @(posedge clock) if (stageDelay_valid_1cycle) for (int w=0; w<L1_WAYS; w++) l1_data_resp[w] <= l1_r_resp_data[w];
  // 注：DataHoldBypass = stageDelay_valid_1cycle 拍直通 io 读出，否则用上一拍锁存。
  l1_sram_entry_t l1_data_use [L1_WAYS];
  always_comb for (int w=0; w<L1_WAYS; w++) l1_data_use[w] = stageDelay_valid_1cycle ? l1_r_resp_data[w] : l1_data_resp[w];

  // stageDelay：hitVec_delay
  logic [L1_WAYS-1:0] l1_hitVec_delay;
  always_comb begin
    for (int w = 0; w < L1_WAYS; w++) begin
      automatic logic tag_hit = (l1_data_use[w].tag == delay_vpn[VPN_W-1 -: L1_TAG_W]);
      automatic logic evs      = l1_data_use[w].vs[l1_sector_idx(delay_vpn)];
      // L1 非叶：is_global = 本 way 的 g 位寄存器打拍值（golden gVec_delay[w] 旁路 asid 检查）；
      //          asid/vmid 用 SRAM 行里存的完整字段比对（PtwEntries.hit）
      l1_hitVec_delay[w] = sram_hit(tag_hit, l1_data_use[w].asid, l1_data_use[w].vmid, evs, l1gVec_delay[w],
                              csr_satp_asid[1], csr_vsatp_asid[1], csr_hgatp_vmid[1], delay_h)
                           && l1vVec_delay[w] && (delay_h == l1hVec_delay[w]);
    end
  end
  // stageCheck：RegEnable(hitVec_delay), ramDatas, vVec
  logic [L1_WAYS-1:0] l1_hitVec;
  l1_sram_entry_t l1_ramDatas [L1_WAYS];
  always_ff @(posedge clock) if (stageDelay1_fire) begin
    l1_hitVec <= l1_hitVec_delay;
    for (int w=0; w<L1_WAYS; w++) l1_ramDatas[w] <= l1_data_use[w];
  end
  l1_sram_entry_t l1_hitWayData;
  always_comb begin
    l1_hitWayData = l1_ramDatas[L1_WAYS-1];   // 默认最后一 way
    for (int w=L1_WAYS-1; w>=0; w--) if (l1_hitVec[w]) l1_hitWayData = l1_ramDatas[w];
  end
  wire l1Hit  = |l1_hitVec;
  wire l1_hitWay = l1_hitVec[0] ? 1'b0 : 1'b1; // ParallelPriorityMux(way idx)：way0 优先，否则 way1
  wire [GVPN_W-1:0] l1HitPPN  = l1_hitWayData.ppns[l1_sector_idx(check_vpn)];
  wire [PBMT_W-1:0] l1HitPbmt = l1_hitWayData.pbmts[l1_sector_idx(check_vpn)];
  wire l1Pre = l1_hitWayData.prefetch;
  wire l1_access_en = l1Hit && stageCheck_valid_1cycle;

  // ===========================================================================
  // L0：32 set × 4 way（SRAM，叶子带 perm）
  // ===========================================================================
  wire [L0_SET_IDX_W-1:0] l0_ridx = l0_set_idx(vpn_search);
  logic [L0_WAYS-1:0] l0vVec_req;
  logic [1:0] l0hVec_req [L0_WAYS];
  always_comb begin
    for (int w = 0; w < L0_WAYS; w++) begin
      l0vVec_req[w] = l0v[l0_ridx*L0_WAYS + w];
      l0hVec_req[w] = l0h[l0_ridx][w];
    end
  end
  logic [L0_WAYS-1:0] l0vVec_delay;
  logic [1:0] l0hVec_delay [L0_WAYS];
  always_ff @(posedge clock) if (stageReq_fire) begin
    l0vVec_delay <= l0vVec_req;
    for (int w = 0; w < L0_WAYS; w++) l0hVec_delay[w] <= l0hVec_req[w];
  end
  l0_sram_entry_t l0_data_resp [L0_WAYS];
  always_ff @(posedge clock) if (stageDelay_valid_1cycle) for (int w=0; w<L0_WAYS; w++) l0_data_resp[w] <= l0_r_resp_data[w];
  l0_sram_entry_t l0_data_use [L0_WAYS];
  always_comb for (int w=0; w<L0_WAYS; w++) l0_data_use[w] = stageDelay_valid_1cycle ? l0_r_resp_data[w] : l0_data_resp[w];

  logic [L0_WAYS-1:0] l0_hitVec_delay;
  always_comb begin
    for (int w = 0; w < L0_WAYS; w++) begin
      automatic logic tag_hit = (l0_data_use[w].tag == delay_vpn[VPN_W-1 -: L0_TAG_W]);
      automatic logic [SECTOR_W-1:0] sidx = l0_sector_idx(delay_vpn);
      automatic logic evs    = l0_data_use[w].vs[sidx];
      automatic logic is_glb = l0_data_use[w].perm_g[sidx];
      // L0 叶子：is_global = 该 sector 的 perm.g；asid/vmid 用 SRAM 行完整字段
      l0_hitVec_delay[w] = sram_hit(tag_hit, l0_data_use[w].asid, l0_data_use[w].vmid, evs, is_glb,
                              csr_satp_asid[0], csr_vsatp_asid[0], csr_hgatp_vmid[0], delay_h)
                           && l0vVec_delay[w] && (delay_h == l0hVec_delay[w]);
    end
  end
  logic [L0_WAYS-1:0] l0_hitVec;
  l0_sram_entry_t l0_ramDatas [L0_WAYS];
  always_ff @(posedge clock) if (stageDelay1_fire) begin
    l0_hitVec <= l0_hitVec_delay;
    for (int w=0; w<L0_WAYS; w++) l0_ramDatas[w] <= l0_data_use[w];
  end
  l0_sram_entry_t l0_hitWayData;
  always_comb begin
    l0_hitWayData = l0_ramDatas[L0_WAYS-1];   // 默认最后一 way
    for (int w=L0_WAYS-1; w>=0; w--) if (l0_hitVec[w]) l0_hitWayData = l0_ramDatas[w];
  end
  wire l0Hit = |l0_hitVec;
  logic [1:0] l0_hitWay;
  always_comb begin
    // ParallelPriorityMux(way idx)：最低命中 way 优先，全 0 默认取最后 way 号(3)
    l0_hitWay = 2'd3;
    for (int w=L0_WAYS-1; w>=0; w--) if (l0_hitVec[w]) l0_hitWay = w[1:0];
  end
  wire l0Pre = l0_hitWayData.prefetch;
  wire l0_access_en = l0Hit && stageCheck_valid_1cycle;

  // ===========================================================================
  // SP：16 项全相联超级页（allType hit，按 level 比较 vpn 各段；napot 第0段比高位）
  // ===========================================================================
  logic [SP_SIZE-1:0] sp_hitVecT, sp_hitVec;
  for (gi = 0; gi < SP_SIZE; gi++) begin : g_sp_hit
    assign sp_hitVecT[gi] = sp_alltype_hit(sp[gi], vpn_search,
                              csr_satp_asid[0], csr_vsatp_asid[0], csr_hgatp_vmid[0], h_search)
                            && spv[gi] && (sph[gi] == h_search);
  end
  always_ff @(posedge clock) if (stageReq_fire) sp_hitVec <= sp_hitVecT;
  sp_entry_t sp_hitData_d;
  always_comb begin
    sp_hitData_d = sp[SP_SIZE-1];   // ParallelPriorityMux 默认取最后一项
    for (int i=SP_SIZE-1; i>=0; i--) if (sp_hitVec[i]) sp_hitData_d = sp[i];
  end
  wire sp_hit_d = |sp_hitVec;
  // stageCheck 对齐
  logic spHit; sp_entry_t spHitData; logic spPre, spValid;
  always_ff @(posedge clock) if (stageDelay1_fire) begin
    spHit <= sp_hit_d; spHitData <= sp_hitData_d; spPre <= sp_hitData_d.prefetch; spValid <= sp_hitData_d.v;
  end
  wire sp_access_en = sp_hit_d && stageDelay_valid_1cycle;
  wire [3:0] sp_hitWay_d = oh16_to_idx(sp_hitVec);

  // ===========================================================================
  // 汇总到 check_res（stageCheck 级）
  // ===========================================================================
  always_comb begin
    check_res = '0;
    // l3
    check_res.l3.hit = l3Hit; check_res.l3.pre = l3Pre; check_res.l3.ppn = l3HitPPN; check_res.l3.pbmt = l3HitPbmt;
    check_res.l3.v = 1'b1;
    // l2
    check_res.l2.hit = l2Hit; check_res.l2.pre = l2Pre; check_res.l2.ppn = l2HitPPN; check_res.l2.pbmt = l2HitPbmt;
    check_res.l2.v = 1'b1;
    // l1
    check_res.l1.hit = l1Hit; check_res.l1.pre = l1Pre; check_res.l1.ppn = l1HitPPN; check_res.l1.pbmt = l1HitPbmt;
    check_res.l1.ecc = 1'b0; check_res.l1.v = 1'b1;
    // l0（整行 8 sector）
    check_res.l0.hit = l0Hit; check_res.l0.pre = l0Pre;
    check_res.l0.ecc = 1'b0; check_res.l0.level = 2'h0;
    for (int s=0; s<CONTIGUOUS; s++) begin
      check_res.l0.ppn[s]  = l0_hitWayData.ppns[s];
      check_res.l0.pbmt[s] = l0_hitWayData.pbmts[s];
      check_res.l0.perm[s].d = l0_hitWayData.perm_d[s];
      check_res.l0.perm[s].a = l0_hitWayData.perm_a[s];
      check_res.l0.perm[s].g = l0_hitWayData.perm_g[s];
      check_res.l0.perm[s].u = l0_hitWayData.perm_u[s];
      check_res.l0.perm[s].x = l0_hitWayData.perm_x[s];
      check_res.l0.perm[s].w = l0_hitWayData.perm_w[s];
      check_res.l0.perm[s].r = l0_hitWayData.perm_r[s];
      check_res.l0.v[s]    = ~l0_hitWayData.onlypf[s];   // valid = !onlypf
    end
    // sp
    check_res.sp.hit = spHit; check_res.sp.pre = spPre; check_res.sp.ppn = spHitData.ppn; check_res.sp.pbmt = spHitData.pbmt;
    check_res.sp.n = spHitData.n; check_res.sp.perm = spHitData.perm; check_res.sp.level = spHitData.level;
    check_res.sp.ecc = 1'b0; check_res.sp.v = spValid;
  end

  // resp_res：stageCheck[1].fire 锁存
  always_ff @(posedge clock) if (stageCheck1_fire) resp_res <= check_res;
