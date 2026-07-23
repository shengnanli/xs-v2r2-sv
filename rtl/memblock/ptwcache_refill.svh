// =============================================================================
// ptwcache_refill.svh —— refill 写入各级 + replaceWrapper/PLRU victim 选择
//
// refill 带回一整条 cacheline（ptes=512b=8×PTE）+ levelOH（哪级填）+ 三份 dup
// 的 req_info/level/sel_pte。各级 victim：replaceWrapper(v, plru.way)（先空位后 PLRU）。
// g 位：memPte.perm.g && s2xlate != onlyStage2 才置。L0 napot 叶子改填 SP。
// 对应 Scala 832~1085 行。
// =============================================================================

  // memPte：从 cacheline 选出的 PTE（sel_pte dup0/dup2），及 8 个 sector 的 g 位
  wire pte_t memPte0 = refill_sel_pte_dup_0;
  wire pte_t memPte2 = refill_sel_pte_dup_2;
  // pbmte：onlyStage1/allStage 用 hPBMTE，否则 mPBMTE
  wire pbmte = (refill_req_info_dup_0.s2xlate == ONLY_STAGE1 || refill_req_info_dup_0.s2xlate == ALL_STAGE)
               ? csr_hPBMTE : csr_mPBMTE;
  // 8 个 sector 的 perm.g 全 1（L1/L0 g 位置位条件）
  logic all_g;
  always_comb begin
    all_g = 1'b1;
    for (int i = 0; i < CONTIGUOUS; i++) begin
      automatic pte_t p = refill_ptes[i*64 +: 64];
      all_g = all_g & p.g;
    end
  end

  wire [1:0] refill_h0_w = change_h(refill_req_info_dup_0.s2xlate);
  wire [1:0] refill_h1_w = change_h(refill_req_info_dup_1.s2xlate);
  wire [1:0] refill_h2_w = change_h(refill_req_info_dup_2.s2xlate);
  wire refill_pre0 = (refill_req_info_dup_0.source == 2'h2);
  wire refill_pre1 = (refill_req_info_dup_1.source == 2'h2);
  wire refill_pre2 = (refill_req_info_dup_2.source == 2'h2);

  wire [ASID_W-1:0] l3l2Wasid = (refill_req_info_dup_2.s2xlate != NO_S2XLATE) ? csr_vsatp_asid[2] : csr_satp_asid[2];
  wire [ASID_W-1:0] l1Wasid   = (refill_req_info_dup_1.s2xlate != NO_S2XLATE) ? csr_vsatp_asid[1] : csr_satp_asid[1];
  wire [ASID_W-1:0] l0Wasid   = (refill_req_info_dup_0.s2xlate != NO_S2XLATE) ? csr_vsatp_asid[0] : csr_satp_asid[0];

  // ===========================================================================
  // L3 refill
  // ===========================================================================
  wire l3Refill = ~flush_dup[2] && refill_levelOH_l3 && ~pte_is_leaf(memPte2)
                  && pte_can_refill(memPte2, refill_level_dup_2, refill_req_info_dup_2.s2xlate, pbmte, csr_hgatp_mode[2]);
  wire [3:0] l3RefillIdx = replace16(l3v, plru16_way(l3replace));
  wire [15:0] l3RfOH = 16'h1 << l3RefillIdx;

  // ===========================================================================
  // L2 refill
  // ===========================================================================
  wire l2Refill = ~flush_dup[2] && refill_levelOH_l2 && ~pte_is_leaf(memPte2)
                  && pte_can_refill(memPte2, refill_level_dup_2, refill_req_info_dup_2.s2xlate, pbmte, csr_hgatp_mode[2]);
  wire [3:0] l2RefillIdx = replace16(l2v, plru16_way(l2replace));
  wire [15:0] l2RfOH = 16'h1 << l2RefillIdx;

  // ===========================================================================
  // L1 refill（SRAM 写）
  // ===========================================================================
  wire l1Refill = ~flush_dup[1] && refill_levelOH_l1;
  wire [L1_SET_IDX_W-1:0] l1RefillIdx = l1_set_idx(refill_req_info_dup_1.vpn);
  logic [L1_WAYS-1:0] l1v_set;
  always_comb for (int w=0; w<L1_WAYS; w++) l1v_set[w] = l1v[l1RefillIdx*L1_WAYS + w];
  wire l1VictimWay = replace2(l1v_set, plru2_way(l1replace[l1RefillIdx]));
  wire [L1_WAYS-1:0] l1VictimWayOH = (2'h1 << l1VictimWay);
  // l1RfvOH：set*ways + way 的位
  wire [L1_SETS*L1_WAYS-1:0] l1RfvOH = ({{(L1_SETS*L1_WAYS-1){1'b0}},1'b1} << (l1RefillIdx*L1_WAYS + l1VictimWay));

  // L1 写数据：tag/asid/vmid/8 sector(pbmt/ppn/vs/onlypf)/prefetch
  always_comb begin
    l1_w_req_data = '0;
    l1_w_req_data.tag  = refill_req_info_dup_1.vpn[VPN_W-1 -: L1_TAG_W];
    l1_w_req_data.asid = l1Wasid;
    l1_w_req_data.vmid = csr_hgatp_vmid[1];
    l1_w_req_data.prefetch = refill_pre1;
    for (int i = 0; i < CONTIGUOUS; i++) begin
      automatic pte_t p = refill_ptes[i*64 +: 64];
      l1_w_req_data.pbmts[i] = p.pbmt;
      l1_w_req_data.ppns[i]  = pte_get_ppn(p);
      // L1 非叶：vs = canRefill && !isLeaf；onlypf 按 golden 照算存行
      // （golden l1Wdata_entries_ps_onlypf_i = onlyPf(level=1, dup1.s2xlate)，非常量 0）
      l1_w_req_data.vs[i]    = (pte_can_refill(p, 2'h1, refill_req_info_dup_1.s2xlate, pbmte, csr_hgatp_mode[1]) && ~pte_is_leaf(p));
      l1_w_req_data.onlypf[i]= pte_only_pf(p, 2'h1, refill_req_info_dup_1.s2xlate, pbmte);
    end
  end
  assign l1_w_req_valid  = l1Refill;
  assign l1_w_req_setIdx = l1RefillIdx;
  assign l1_w_req_waymask = l1VictimWayOH;

  // ===========================================================================
  // L0 refill（SRAM 写；napot 叶子改填 SP）
  // ===========================================================================
  wire l0Refill = ~flush_dup[0] && refill_levelOH_l0 && ~pte_is_napot(memPte0, refill_level_dup_0);
  wire [L0_SET_IDX_W-1:0] l0RefillIdx = l0_set_idx(refill_req_info_dup_0.vpn);
  logic [L0_WAYS-1:0] l0v_set;
  always_comb for (int w=0; w<L0_WAYS; w++) l0v_set[w] = l0v[l0RefillIdx*L0_WAYS + w];
  wire [1:0] l0VictimWay = replace4(l0v_set, plru4_way(l0replace[l0RefillIdx]));
  wire [L0_WAYS-1:0] l0VictimWayOH = (4'h1 << l0VictimWay);
  wire [L0_SETS*L0_WAYS-1:0] l0RfvOH = ({{(L0_SETS*L0_WAYS-1){1'b0}},1'b1} << (l0RefillIdx*L0_WAYS + l0VictimWay));

  always_comb begin
    l0_w_req_data = '0;
    l0_w_req_data.tag  = refill_req_info_dup_0.vpn[VPN_W-1 -: L0_TAG_W];
    l0_w_req_data.asid = l0Wasid;
    l0_w_req_data.vmid = csr_hgatp_vmid[0];
    l0_w_req_data.prefetch = refill_pre0;
    for (int i = 0; i < CONTIGUOUS; i++) begin
      automatic pte_t p = refill_ptes[i*64 +: 64];
      automatic logic leaf_refillable = pte_can_refill(p, 2'h0, refill_req_info_dup_0.s2xlate, pbmte, csr_hgatp_mode[0]) && pte_is_leaf(p);
      automatic logic onlypf = pte_only_pf(p, 2'h0, refill_req_info_dup_0.s2xlate, pbmte);
      l0_w_req_data.pbmts[i] = p.pbmt;
      l0_w_req_data.ppns[i]  = pte_get_ppn(p);
      l0_w_req_data.vs[i]    = leaf_refillable || onlypf;   // L0：vs = 非 page-fault
      l0_w_req_data.onlypf[i]= onlypf;
      // perm；onlyStage2 时 g 位清 0（G-stage 忽略 g）
      l0_w_req_data.perm_d[i] = p.d;
      l0_w_req_data.perm_a[i] = p.a;
      l0_w_req_data.perm_g[i] = (refill_req_info_dup_0.s2xlate == ONLY_STAGE2) ? 1'b0 : p.g;
      l0_w_req_data.perm_u[i] = p.u;
      l0_w_req_data.perm_x[i] = p.x;
      l0_w_req_data.perm_w[i] = p.w;
      l0_w_req_data.perm_r[i] = p.r;
    end
  end
  assign l0_w_req_valid  = l0Refill;
  assign l0_w_req_setIdx = l0RefillIdx;
  assign l0_w_req_waymask = l0VictimWayOH;

  // ===========================================================================
  // SP refill（叶子/svnapot/onlyPf）
  // ===========================================================================
  wire sp_leaf_ok  = pte_is_leaf(memPte0) && pte_can_refill(memPte0, refill_level_dup_0, refill_req_info_dup_0.s2xlate, pbmte, csr_hgatp_mode[0]);
  wire sp_onlypf   = pte_only_pf(memPte0, refill_level_dup_0, refill_req_info_dup_0.s2xlate, pbmte);
  wire spRefill = ~flush_dup[0]
                  && (refill_levelOH_sp || (refill_levelOH_l0 && pte_is_napot(memPte0, refill_level_dup_0)))
                  && (sp_leaf_ok || sp_onlypf);
  wire [3:0] spRefillIdx = plru16_way(spreplace);  // SP 直接用 PLRU way（无空位优先，golden 同）
  wire [15:0] spRfOH = 16'h1 << spRefillIdx;

  // L0 折叠 vpn 用的 tag 段：vpn(vpnLen-1, vpnLen-PtwL0TagLen) = vpn[37:14]（24b）
  wire [L0_TAG_W-1:0] l0Wvpn_tag = refill_req_info_dup_0.vpn[VPN_W-1 -: L0_TAG_W];

  // ===========================================================================
  // valid 向量统一更新（refill 置位 / sfence 清位）。sfence 清除掩码由 sfence.svh 给出
  // （组合 wire l*v_sfence_clr / spv_sfence_clr），在此单一 always_ff 里合并，避免多驱动。
  //
  // 关键：golden 中各级 v 是 Chisel last-connect 的 if/else 链——
  //   l1v/l2v: if (任一 fence 有效 && dup0.rs1) {clear} else {refill 置位}
  //   l3v:     if (任一 fence 有效 && dup2.rs1) {clear} else {refill 置位}
  //   l0v/spv: 各 fence 分支都给出（含 rs1=0），refill 仅在无 fence 时
  // 即「clear 分支命中那拍，refill 的 OR 必须被抑制」——不能像旧实现那样 (v&~clr)|refill 同拍并行，
  // 否则 sfence(dupX.rs1=1) 同拍若 l*Refill=1（l*Refill 仅看 flush_dup[i]=dup_i.valid，
  // 而 TB 把 dup0/1/2.valid 独立随机化，dup_i.valid 可能=0 → l*Refill=1）会错误置位。
  // 这正是 l1v/l3v 分叉根因：l1v/l2v 用 dup0.rs1 抑制，l3v 用 dup2.rs1 抑制。
  // l0v/spv 不抑制（其 refill 与 fence 的互斥已由 flush_dup[0] 完整覆盖）。
  // ===========================================================================
  // 「任一 fence 有效」= sfence_dup_0.valid（sfence/hfencev/hfenceg 并集）。
  wire any_fence       = sfence_dup_0.valid;
  wire l12_clr_active  = any_fence & sfence_dup_0.rs1;   // l1v/l2v 进入 clear 分支
  wire l3_clr_active   = any_fence & sfence_dup_2_rs1;   // l3v 进入 clear 分支
  wire l1Refill_v = l1Refill & ~l12_clr_active;
  wire l2Refill_v = l2Refill & ~l12_clr_active;
  wire l3Refill_v = l3Refill & ~l3_clr_active;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      l3v <= '0; l2v <= '0; l1v <= '0; l0v <= '0; spv <= '0;
    end else begin
      l3v <= (l3v & ~l3v_sfence_clr) | (l3Refill_v ? l3RfOH  : 16'h0);
      l2v <= (l2v & ~l2v_sfence_clr) | (l2Refill_v ? l2RfOH  : 16'h0);
      l1v <= (l1v & ~l1v_sfence_clr) | (l1Refill_v ? l1RfvOH : '0);
      l0v <= (l0v & ~l0v_sfence_clr) | (l0Refill   ? l0RfvOH : '0);
      spv <= (spv & ~spv_sfence_clr) | (spRefill   ? spRfOH  : 16'h0);
    end
  end

  // l3/l2/sp entry & g & h & PLRU
  always_ff @(posedge clock) begin
    if (l3Refill) begin
      // l3_entry_t.tag 现窄至 11b（=vpn[37:27]），与 golden l3_N_tag 位宽一致。
      // l3 无 pbmt/v 字段（golden 无对应寄存器，已从结构剪除）。
      l3[l3RefillIdx].tag  <= refill_req_info_dup_2.vpn[VPN_W-1 -: L3_TAG_W];
      l3[l3RefillIdx].asid <= l3l2Wasid;
      l3[l3RefillIdx].vmid <= csr_hgatp_vmid[2];
      l3[l3RefillIdx].ppn  <= pte_get_ppn(memPte2);
      l3[l3RefillIdx].prefetch <= refill_pre2;
      l3g <= (l3g & ~l3RfOH) | ((memPte2.g && refill_req_info_dup_2.s2xlate != ONLY_STAGE2) ? l3RfOH : 16'h0);
      l3h[l3RefillIdx] <= refill_h2_w;
    end
    if (l2Refill) begin
      // l2 无 v 字段（有效性走 l2v 向量；golden 无 l2_N_v 寄存器）。
      l2[l2RefillIdx].tag  <= refill_req_info_dup_2.vpn[VPN_W-1 -: L2_TAG_W];
      l2[l2RefillIdx].asid <= l3l2Wasid;
      l2[l2RefillIdx].vmid <= csr_hgatp_vmid[2];
      l2[l2RefillIdx].pbmt <= memPte2.pbmt;
      l2[l2RefillIdx].ppn  <= pte_get_ppn(memPte2);
      l2[l2RefillIdx].prefetch <= refill_pre2;
      l2g <= (l2g & ~l2RfOH) | ((memPte2.g && refill_req_info_dup_2.s2xlate != ONLY_STAGE2) ? l2RfOH : 16'h0);
      l2h[l2RefillIdx] <= refill_h2_w;
    end
    if (l1Refill) begin
      l1g <= (l1g & ~l1RfvOH) | ((all_g && refill_req_info_dup_1.s2xlate != ONLY_STAGE2) ? l1RfvOH : '0);
      l1h[l1RefillIdx][l1VictimWay]     <= refill_h1_w;
      l1asids[l1RefillIdx][l1VictimWay] <= xorfold_asid(l1Wasid);
      l1vmids[l1RefillIdx][l1VictimWay] <= xorfold_asid(csr_hgatp_vmid[1]);
    end
    if (l0Refill) begin
      l0g <= (l0g & ~l0RfvOH) | ((all_g && refill_req_info_dup_0.s2xlate != ONLY_STAGE2) ? l0RfvOH : '0);
      l0h[l0RefillIdx][l0VictimWay]     <= refill_h0_w;
      l0asids[l0RefillIdx][l0VictimWay] <= xorfold_asid(l0Wasid);
      l0vmids[l0RefillIdx][l0VictimWay] <= xorfold_asid(csr_hgatp_vmid[0]);
      l0vpns[l0RefillIdx][l0VictimWay]  <= xorfold_vpn(l0Wvpn_tag);
    end
    if (spRefill) begin
      sp[spRefillIdx].tag  <= refill_req_info_dup_0.vpn[VPN_W-1 -: SP_TAG_W];
      sp[spRefillIdx].asid <= l0Wasid;
      sp[spRefillIdx].vmid <= csr_hgatp_vmid[0];
      sp[spRefillIdx].n    <= memPte0.n;
      sp[spRefillIdx].pbmt <= memPte0.pbmt;
      sp[spRefillIdx].ppn  <= pte_get_ppn(memPte0);
      sp[spRefillIdx].perm.d <= memPte0.d; sp[spRefillIdx].perm.a <= memPte0.a;
      sp[spRefillIdx].perm.g <= (refill_req_info_dup_0.s2xlate == ONLY_STAGE2) ? 1'b0 : memPte0.g;
      sp[spRefillIdx].perm.u <= memPte0.u; sp[spRefillIdx].perm.x <= memPte0.x;
      sp[spRefillIdx].perm.w <= memPte0.w; sp[spRefillIdx].perm.r <= memPte0.r;
      sp[spRefillIdx].level <= refill_level_dup_0;
      sp[spRefillIdx].prefetch <= refill_pre0;
      sp[spRefillIdx].v    <= ~sp_onlypf;     // valid = !onlyPf
      spg <= (spg & ~spRfOH) | ((memPte0.g && refill_req_info_dup_0.s2xlate != ONLY_STAGE2) ? spRfOH : 16'h0);
      sph[spRefillIdx] <= refill_h0_w;
    end
  end

  // ===========================================================================
  // PLRU 状态更新（优先级/触点严格对齐 golden RTL——bug-for-bug）：
  //   L3 state_reg：只在查询命中 touch（golden 无 l3Refill access——Scala 里 refill
  //                 时 access 的是 ptwl2replace(l3RefillIdx)，见下 L2）。
  //   L2 state_reg_1：l2Refill > l3Refill(用 l3RefillIdx) > 命中 touch。
  //   SP state_reg_4：spRefill > 命中 touch。
  //   L1/L0 per-set：refill 与命中 touch 的 set 相互独立——golden 每个 set 各自
  //                 「if (refill&本set) else if (touch&本set)」；同拍 refill 到 set A、
  //                 命中 touch 到 set B(≠A) 时两个 set 都要更新（全局 else-if 是错的）。
  // ===========================================================================
  // L3（golden state_reg：复位到 0；仅命中 touch）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)               l3replace <= '0;
    else if (l3_access_en)   l3replace <= plru16_access(l3replace, l3_hitWay_d);
  end
  // L2（golden state_reg_1：l2Refill > l3Refill > hit；l3Refill 也 access l2replace
  //     —— 见 Scala ptwl2replace.access(l3RefillIdx)）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)               l2replace <= '0;
    else if (l2Refill)       l2replace <= plru16_access(l2replace, l2RefillIdx);
    else if (l3Refill)       l2replace <= plru16_access(l2replace, l3RefillIdx);
    else if (l2_access_en)   l2replace <= plru16_access(l2replace, l2_hitWay_d);
  end
  // SP
  always_ff @(posedge clock or posedge reset) begin
    if (reset)               spreplace <= '0;
    else if (spRefill)       spreplace <= plru16_access(spreplace, spRefillIdx);
    else if (sp_access_en)   spreplace <= plru16_access(spreplace, sp_hitWay_d);
  end
  // L1 per-set（golden state_vec_N：每 set 独立 if(refill&set==N)/else if(touch&set==N)）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int st = 0; st < L1_SETS; st++) l1replace[st] <= 1'b0;
    end else begin
      for (int st = 0; st < L1_SETS; st++) begin
        if (l1Refill && (l1RefillIdx == L1_SET_IDX_W'(st)))
          l1replace[st] <= plru2_access(l1VictimWay);
        else if (l1_access_en && (l1_set_idx(check_vpn) == L1_SET_IDX_W'(st)))
          l1replace[st] <= plru2_access(l1_hitWay);
      end
    end
  end
  // L0 per-set（同上；access 值取 refill/命中 set 的当前状态，与 golden 共享表达式一致）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int st = 0; st < L0_SETS; st++) l0replace[st] <= 3'b000;
    end else begin
      for (int st = 0; st < L0_SETS; st++) begin
        if (l0Refill && (l0RefillIdx == L0_SET_IDX_W'(st)))
          l0replace[st] <= plru4_access(l0replace[l0RefillIdx], l0VictimWay);
        else if (l0_access_en && (l0_set_idx(check_vpn) == L0_SET_IDX_W'(st)))
          l0replace[st] <= plru4_access(l0replace[l0_set_idx(check_vpn)], l0_hitWay);
      end
    end
  end

  // ===========================================================================
  // perf 事件（8 个 perf 输出对应 perfEvents Seq）—— 见 Scala generatePerfEvent。
  // 简化：本核给出 access/各级 hit 的事件脉冲（计数器在外层），与 golden io_perf_*_value 对齐。
  // ===========================================================================
  `include "ptwcache_perf.svh"
