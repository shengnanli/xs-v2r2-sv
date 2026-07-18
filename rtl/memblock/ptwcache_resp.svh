// =============================================================================
// ptwcache_resp.svh —— stageResp 输出汇总（resp_res → io.resp.bits）
//
// 三大去向：hit（叶子直接翻译）、toFsm（给 PTW 串行 walker）、toHptw（给 HPTW）、
// stage1（PtwMergeResp 8 sector，回 TLB 填充）。bypassed：refill 正写同项时置位。
// 对应 Scala 697~818 行。
// =============================================================================

  wire isAllStage   = (stageResp_bits.req_info.s2xlate == ALL_STAGE);
  wire isOnlyStage2 = (stageResp_bits.req_info.s2xlate == ONLY_STAGE2);
  wire [SECTOR_W-1:0] idx = stageResp_bits.req_info.vpn[SECTOR_W-1:0];

  wire stage1Hit = (resp_res.l0.hit || resp_res.sp.hit) && isAllStage;
  // stage1Pf = !(l0.hit ? l0.v[idx] : sp.v)
  wire stage1Pf  = ~(resp_res.l0.hit ? resp_res.l0.v[idx] : resp_res.sp.v);

  // bypassed（resp 出口）：ValidHoldBypass(refill_bypass(resp.vpn,i), OneCycleValid(stageCheck1.fire)||refill.valid)
  // 这里用 stageResp.bits.bypassed（在途累积）| 当前 refill_bypass 命中并保持。
  wire [3:0] rbv_resp = refill_bypass_vec(stageResp_bits.req_info.vpn, stageResp_bits.req_info.s2xlate,
                                          refill_valid, refill_level_dup_0, refill_req_info_dup_0.vpn, refill_h0);
  // ValidHoldBypass：trigger=rbv_resp，hold 直到 release(=OneCycleValid(stageCheck1.fire)||refill.valid)
  logic [3:0] bypassed_hold, hptw_bypassed_hold;
  // golden 每个通道各有一份 OneCycleValid 副本 bypassed_{0..3}_valid（4 个重复寄存器，
  // 同 D=stageResp_ready&valid_1）——1:1 复刻成 [3:0] 数组供 FM 按位配对（修法⑥）。
  logic [3:0] stageCheck1_fire_1cycle;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) stageCheck1_fire_1cycle <= '0;
    else       stageCheck1_fire_1cycle <= {4{stageCheck1_fire}};   // OneCycleValid(_, false)
  end
  // ValidHoldBypass(set, clr)：held' = ~clr & (set | held)（clr 优先于 set，与 golden 同）；
  //   输出再 OR 上当拍组合 set（rbv_resp），使 clr&set 同拍输出仍为 1。
  wire clr_hptw = resp_valid && resp_ready;   // io.resp.fire（hptw_bypassed 的 clr 不含 refill）
  for (gi = 0; gi < 4; gi++) begin : g_bypass_hold
    always_ff @(posedge clock or posedge reset) begin
      if (reset) bypassed_hold[gi] <= 1'b0;
      else       bypassed_hold[gi] <= ~(stageCheck1_fire_1cycle[gi] | refill_valid)
                                      & (rbv_resp[gi] | bypassed_hold[gi]);
    end
    always_ff @(posedge clock or posedge reset) begin
      if (reset) hptw_bypassed_hold[gi] <= 1'b0;
      else       hptw_bypassed_hold[gi] <= ~clr_hptw & (rbv_resp[gi] | hptw_bypassed_hold[gi]);
    end
  end
  wire [3:0] bypassed      = stageResp_bits.bypassed | rbv_resp | bypassed_hold;
  wire [3:0] hptw_bypassed = stageResp_bits.bypassed | rbv_resp | hptw_bypassed_hold;

  // toFsm.ppn / toHptw.ppn 选择（l1>l2>l3）
  wire [GVPN_W-1:0] nonleaf_ppn = resp_res.l1.hit ? resp_res.l1.ppn :
                                  (resp_res.l2.hit ? resp_res.l2.ppn : resp_res.l3.ppn);
  // toHptw.resp.entry.ppn 全宽（l0 命中取该 sector，否则 sp）
  wire [GVPN_W-1:0] hptw_entry_ppn_full = resp_res.l0.hit ? resp_res.l0.ppn[idx] : resp_res.sp.ppn;

  always_comb begin
    resp_bits = '0;
    resp_bits.req_info  = stageResp_bits.req_info;
    resp_bits.isFirst   = stageResp_bits.isFirst;
    resp_bits.hit       = (resp_res.l0.hit || resp_res.sp.hit) && (~isAllStage || (isAllStage && stage1Pf));
    resp_bits.bypassed  = ((bypassed[0] && ~resp_res.l0.hit) || (bypassed[1] && ~resp_res.l1.hit)
                         || (bypassed[2] && ~resp_res.l2.hit) || (bypassed[3] && ~resp_res.l3.hit)) && ~isAllStage;
    resp_bits.prefetch  = (resp_res.l0.pre && resp_res.l0.hit) || (resp_res.sp.pre && resp_res.sp.hit);

    // toFsm
    resp_bits.toFsm_l3Hit = resp_res.l3.hit && ~stage1Hit && ~isOnlyStage2 && ~stageResp_bits.isHptwReq;
    resp_bits.toFsm_l2Hit = resp_res.l2.hit && ~stage1Hit && ~isOnlyStage2 && ~stageResp_bits.isHptwReq;
    resp_bits.toFsm_l1Hit = resp_res.l1.hit && ~stage1Hit && ~isOnlyStage2 && ~stageResp_bits.isHptwReq;
    resp_bits.toFsm_ppn   = nonleaf_ppn;
    resp_bits.toFsm_stage1Hit = stage1Hit;

    // hptw
    resp_bits.isHptwReq    = stageResp_bits.isHptwReq;
    resp_bits.toHptw_bypassed = ((hptw_bypassed[0] && ~resp_res.l0.hit) || (hptw_bypassed[1] && ~resp_res.l1.hit)
                              || (hptw_bypassed[2] && ~resp_res.l2.hit) || (hptw_bypassed[3] && ~resp_res.l3.hit))
                              && stageResp_bits.isHptwReq;
    resp_bits.toHptw_id    = stageResp_bits.hptwId;
    resp_bits.toHptw_l3Hit = resp_res.l3.hit && stageResp_bits.isHptwReq;
    resp_bits.toHptw_l2Hit = resp_res.l2.hit && stageResp_bits.isHptwReq;
    resp_bits.toHptw_l1Hit = resp_res.l1.hit && stageResp_bits.isHptwReq;
    resp_bits.toHptw_ppn   = nonleaf_ppn[TOHPTW_PPN_W-1:0];
    resp_bits.toHptw_entry.tag   = stageResp_bits.req_info.vpn;
    resp_bits.toHptw_entry.vmid  = csr_hgatp_vmid[0];
    resp_bits.toHptw_entry.level = resp_res.l0.hit ? 2'h0 : resp_res.sp.level;
    resp_bits.toHptw_entry.ppn   = hptw_entry_ppn_full[TOHPTW_PPN_W-1:0];
    resp_bits.toHptw_entry.pbmt  = resp_res.l0.hit ? resp_res.l0.pbmt[idx] : resp_res.sp.pbmt;
    resp_bits.toHptw_entry.n     = resp_res.sp.hit ? resp_res.sp.n : 1'b0;
    resp_bits.toHptw_entry.perm  = resp_res.l0.hit ? resp_res.l0.perm[idx] : resp_res.sp.perm;
    resp_bits.toHptw_gpf = ~(resp_res.l0.hit ? resp_res.l0.v[idx] : resp_res.sp.v);

    // stage1：8 个 sector entry
    for (int s = 0; s < CONTIGUOUS; s++) begin
      resp_bits.stage1_entry[s].tag   = stageResp_bits.req_info.vpn[VPN_W-1:3];
      resp_bits.stage1_entry[s].asid  = (stageResp_bits.req_info.s2xlate != NO_S2XLATE) ? csr_vsatp_asid[0] : csr_satp_asid[0];
      resp_bits.stage1_entry[s].vmid  = csr_hgatp_vmid[0];
      resp_bits.stage1_entry[s].level = resp_res.l0.hit ? 2'h0 :
                                        (resp_res.sp.hit ? resp_res.sp.level :
                                        (resp_res.l1.hit ? 2'h1 :
                                        (resp_res.l2.hit ? 2'h2 : 2'h3)));
      // ppn（sectorgvpn 高位段 [37:3]，放入 41 位字段低 35 位，高位 0）
      resp_bits.stage1_entry[s].ppn   = {6'h0,
        (resp_res.l0.hit ? resp_res.l0.ppn[s][GVPN_W-1:SECTOR_W] :
        (resp_res.sp.hit ? resp_res.sp.ppn[GVPN_W-1:SECTOR_W] :
        (resp_res.l1.hit ? resp_res.l1.ppn[GVPN_W-1:SECTOR_W] :
        (resp_res.l2.hit ? resp_res.l2.ppn[GVPN_W-1:SECTOR_W] :
                           resp_res.l3.ppn[GVPN_W-1:SECTOR_W]))))};
      resp_bits.stage1_entry[s].ppn_low =
        (resp_res.l0.hit ? resp_res.l0.ppn[s][SECTOR_W-1:0] :
        (resp_res.sp.hit ? resp_res.sp.ppn[SECTOR_W-1:0] :
        (resp_res.l1.hit ? resp_res.l1.ppn[SECTOR_W-1:0] :
        (resp_res.l2.hit ? resp_res.l2.ppn[SECTOR_W-1:0] :
                           resp_res.l3.ppn[SECTOR_W-1:0]))));
      // golden 折叠：check_res.l{1,2,3}.v 恒 1（常量），firtool 已把这三个寄存器位
      // 消去并把 mux 折成 (~sp.hit | sp.v)。照抄折叠式，使 impl 的 resp_res.l{1,2,3}.v
      // 寄存器位无读者（FM Unread 不比对），且 X 行为与 golden 一致（golden 恒给 1）。
      resp_bits.stage1_entry[s].v =
        resp_res.l0.hit ? resp_res.l0.v[s] : (~resp_res.sp.hit | resp_res.sp.v);
      resp_bits.stage1_entry[s].pbmt =
        (resp_res.l0.hit ? resp_res.l0.pbmt[s] :
        (resp_res.sp.hit ? resp_res.sp.pbmt :
        (resp_res.l1.hit ? resp_res.l1.pbmt : resp_res.l2.pbmt)));
      resp_bits.stage1_entry[s].n    = resp_res.sp.hit ? resp_res.sp.n : 1'b0;
      resp_bits.stage1_entry[s].perm = resp_res.l0.hit ? resp_res.l0.perm[s] :
                                       (resp_res.sp.hit ? resp_res.sp.perm : '0);
      resp_bits.stage1_entry[s].pf   = ~resp_bits.stage1_entry[s].v;
    end
    // pteidx = UIntToOH(idx)
    resp_bits.stage1_pteidx = (8'h1 << idx);
    resp_bits.stage1_not_super = resp_res.l0.hit;
  end

  assign resp_valid = stageResp_valid_r;
