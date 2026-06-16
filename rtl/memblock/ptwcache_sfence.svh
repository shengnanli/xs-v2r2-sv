// =============================================================================
// ptwcache_sfence.svh —— sfence / hfence-v / hfence-g 无效化掩码
//
// 产生组合清除掩码 l*v_sfence_clr / spv_sfence_clr，供 refill.svh 的 valid 更新合并。
// 三类 fence 互斥（按 hv/hg），各自按 rs1(指定 va)/rs2(指定 asid) 四象限组合。
// 比较量全用 XORFold 折叠后的窄值（与 SRAM 内 l*asids/l*vmids/l0vpns 一致）。
// 对应 Scala 1087~1279 行。
// =============================================================================

  // 输出掩码 l*v_sfence_clr / spv_sfence_clr 在 PtwCache.sv 顶层声明（refill.svh 先用到）。

  // ---- 三类 fence 有效判定（hg/hv 同时为 1 时按 Chisel 优先走 hfence-g）----
  wire sfence_valid  = sfence_dup_0.valid && ~sfence_dup_0.hg && ~sfence_dup_0.hv;  // 普通 sfence
  wire hfencev_valid = sfence_dup_0.valid &&  sfence_dup_0.hv && ~sfence_dup_0.hg;
  wire hfenceg_valid = sfence_dup_0.valid &&  sfence_dup_0.hg;
  wire rs1 = sfence_dup_0.rs1;   // 指定 va（l0/l1/l2/sp 失效用 dup0）
  wire rs2 = sfence_dup_0.rs2;   // 指定 asid（同上）
  // l3v 失效在 golden 中用 sfence_dup_2 的 rs1/rs2（见 Scala 1243/1258/1271：sfence_dup(2).bits.rs1/rs2），
  // 与 l0/l1/l2/sp 的 dup0 解耦。TB 把 dup0/dup2 的 rs1/rs2 独立随机化，故必须分开。
  wire rs1_l3 = sfence_dup_2_rs1;
  wire rs2_l3 = sfence_dup_2_rs2;

  // ---- 折叠后的比较量 ----
  // asid（sfence 用 id；l1 用 dup1.id；l2 用 dup2.id 原值非折叠）
  wire [HASH_ASID_W-1:0] l0hashAsid = xorfold_asid(sfence_dup_0.id);
  wire [HASH_ASID_W-1:0] l1hashAsid = xorfold_asid(sfence_dup_1_id);
  // vmid 折叠（普通 sfence/hfencev 用 hgatp.vmid；hfenceg 用 sfence id 作 vmid）
  wire [HASH_ASID_W-1:0] l0hashVmid_s = xorfold_asid(csr_hgatp_vmid[0]);
  wire [HASH_ASID_W-1:0] l1hashVmid_s = xorfold_asid(csr_hgatp_vmid[1]);
  wire [HASH_ASID_W-1:0] l0hashVmid_g = xorfold_asid(sfence_dup_0.id);
  wire [HASH_ASID_W-1:0] l1hashVmid_g = xorfold_asid(sfence_dup_1_id);

  // va → vpn（sfence/hfencev：addr>>offLen；hfenceg：(addr<<2)>>offLen = addr>>10）
  wire [VPN_W-1:0] sfence_vpn  = sfence_dup_0.addr[49 -: VPN_W];          // addr[49:12]
  wire [VPN_W-1:0] hfenceg_gvpn = {sfence_dup_0.addr[47:0], 2'b00} >> OFF_W; // (addr<<2)[?:12]
  wire [HASH_VPN_W-1:0] l0hashVpn_s = xorfold_vpn(sfence_vpn[VPN_W-1 -: L0_TAG_W]);
  wire [HASH_VPN_W-1:0] l0hashVpn_g = xorfold_vpn(hfenceg_gvpn[VPN_W-1 -: L0_TAG_W]);
  wire [L0_SET_IDX_W-1:0] l0flushSet_s = l0_set_idx(sfence_vpn);
  wire [L0_SET_IDX_W-1:0] l0flushSet_g = l0_set_idx(hfenceg_gvpn);

  // ---- 折叠相等向量（asid / vmid / vpn）----
  logic [L0_SETS*L0_WAYS-1:0] l0asidhit, l0vmidhit_s, l0vmidhit_g, l0vpnhit_s, l0vpnhit_g;
  logic [L1_SETS*L1_WAYS-1:0] l1asidhit, l1vmidhit_s, l1vmidhit_g;
  logic [L2_SIZE-1:0]         l2asidhit, l2vmidhit;
  logic [SP_SIZE-1:0]         spasidhit, spvmidhit_s, spvmidhit_g;
  logic [L3_SIZE-1:0]         l3asidhit, l3vmidhit;
  always_comb begin
    for (int st=0; st<L0_SETS; st++) for (int w=0; w<L0_WAYS; w++) begin
      l0asidhit[st*L0_WAYS+w]   = (l0asids[st][w] == l0hashAsid);
      l0vmidhit_s[st*L0_WAYS+w] = (l0vmids[st][w] == l0hashVmid_s);
      l0vmidhit_g[st*L0_WAYS+w] = (l0vmids[st][w] == l0hashVmid_g);
      l0vpnhit_s[st*L0_WAYS+w]  = (l0vpns[st][w]  == l0hashVpn_s);
      l0vpnhit_g[st*L0_WAYS+w]  = (l0vpns[st][w]  == l0hashVpn_g);
    end
    for (int st=0; st<L1_SETS; st++) for (int w=0; w<L1_WAYS; w++) begin
      l1asidhit[st*L1_WAYS+w]   = (l1asids[st][w] == l1hashAsid);
      l1vmidhit_s[st*L1_WAYS+w] = (l1vmids[st][w] == l1hashVmid_s);
      l1vmidhit_g[st*L1_WAYS+w] = (l1vmids[st][w] == l1hashVmid_g);
    end
    for (int i=0; i<L2_SIZE; i++) begin
      l2asidhit[i] = (l2[i].asid == sfence_dup_2_id);
      l2vmidhit[i] = (l2[i].vmid == csr_hgatp_vmid[2]);   // 普通sfence/hfencev 用 hgatp；hfenceg 见下
    end
    for (int i=0; i<SP_SIZE; i++) begin
      spasidhit[i]   = (sp[i].asid == sfence_dup_0.id);
      spvmidhit_s[i] = (sp[i].vmid == csr_hgatp_vmid[0]);
      spvmidhit_g[i] = (sp[i].vmid == sfence_dup_0.id);
    end
    for (int i=0; i<L3_SIZE; i++) begin
      l3asidhit[i] = (l3[i].asid == sfence_dup_2_id);
      l3vmidhit[i] = (l3[i].vmid == csr_hgatp_vmid[2]);
    end
  end

  // ---- h 标记命中（按 priv.virt 与条目 l*h）----
  // 普通 sfence：virt? onlyStage1 : noS2xlate；hfencev：onlyStage1；hfenceg：onlyStage2
  function automatic logic hhit_sfence(input logic [1:0] eh, input logic virt);
    return (virt && eh == ONLY_STAGE1) || (~virt && eh == NO_S2XLATE);
  endfunction

  // ---- SP 的 va 指定命中（复用 sp_alltype_hit 的 sfence 变体）----
  // 普通sfence: sfence=virt?isVSfence:isSfence; hfencev: isVSfence; hfenceg: isGSfence
  // sp_alltype_hit 不含 sfence 参数；此处对 va 指定用 sp_sfence_hit（pkg 新增），rs2=1 时 ignoreID。
  logic [SP_SIZE-1:0] sp_va_hit_s, sp_va_hit_g, sp_va_hit_s_ig, sp_va_hit_g_ig;
  always_comb begin
    for (int i=0; i<SP_SIZE; i++) begin
      automatic logic [1:0] sf_s = csr_priv_virt[0] ? IS_VSFENCE : IS_SFENCE;
      sp_va_hit_s[i]    = sp_sfence_hit(sp[i], sfence_vpn,  sfence_dup_0.id, csr_hgatp_vmid[0], sf_s,      1'b0);
      sp_va_hit_s_ig[i] = sp_sfence_hit(sp[i], sfence_vpn,  sfence_dup_0.id, csr_hgatp_vmid[0], sf_s,      1'b1);
      sp_va_hit_g[i]    = sp_sfence_hit(sp[i], hfenceg_gvpn, sfence_dup_0.id, sfence_dup_0.id,  IS_GSFENCE, 1'b0);
      sp_va_hit_g_ig[i] = sp_sfence_hit(sp[i], hfenceg_gvpn, sfence_dup_0.id, sfence_dup_0.id,  IS_GSFENCE, 1'b1);
    end
  end

  // ===========================================================================
  // 组合清除掩码计算
  // ===========================================================================
  logic [L0_SETS*L0_WAYS-1:0] l0flushMask_s, l0flushMask_g;
  always_comb begin
    for (int st=0; st<L0_SETS; st++) for (int w=0; w<L0_WAYS; w++) begin
      l0flushMask_s[st*L0_WAYS+w] = (st[L0_SET_IDX_W-1:0] == l0flushSet_s);
      l0flushMask_g[st*L0_WAYS+w] = (st[L0_SET_IDX_W-1:0] == l0flushSet_g);
    end
  end

  always_comb begin
    l2v_sfence_clr = '0; l1v_sfence_clr = '0;
    l0v_sfence_clr = '0; spv_sfence_clr = '0;

    if (sfence_valid) begin
      // h 命中向量
      automatic logic [L0_SETS*L0_WAYS-1:0] l0hhit; automatic logic [L1_SETS*L1_WAYS-1:0] l1hhit;
      automatic logic [L2_SIZE-1:0] l2hhit; automatic logic [SP_SIZE-1:0] sphhit;
      automatic logic [L0_SETS*L0_WAYS-1:0] l0virt; automatic logic [L1_SETS*L1_WAYS-1:0] l1virt;
      automatic logic [L2_SIZE-1:0] l2virt; automatic logic [SP_SIZE-1:0] spvirt;
      for (int st=0; st<L0_SETS; st++) for (int w=0; w<L0_WAYS; w++) begin
        l0hhit[st*L0_WAYS+w] = hhit_sfence(l0h[st][w], csr_priv_virt[0]);
        l0virt[st*L0_WAYS+w] = l0hhit[st*L0_WAYS+w] & ((csr_priv_virt[0] & l0vmidhit_s[st*L0_WAYS+w]) | ~csr_priv_virt[0]);
      end
      for (int st=0; st<L1_SETS; st++) for (int w=0; w<L1_WAYS; w++) begin
        l1hhit[st*L1_WAYS+w] = hhit_sfence(l1h[st][w], csr_priv_virt[1]);
        l1virt[st*L1_WAYS+w] = l1hhit[st*L1_WAYS+w] & ((csr_priv_virt[1] & l1vmidhit_s[st*L1_WAYS+w]) | ~csr_priv_virt[1]);
      end
      for (int i=0; i<L2_SIZE; i++) begin
        l2hhit[i] = hhit_sfence(l2h[i], csr_priv_virt[2]);
        l2virt[i] = l2hhit[i] & ((csr_priv_virt[2] & l2vmidhit[i]) | ~csr_priv_virt[2]);
      end
      for (int i=0; i<SP_SIZE; i++) begin
        sphhit[i] = hhit_sfence(sph[i], csr_priv_virt[0]);
        spvirt[i] = sphhit[i] & ((csr_priv_virt[0] & spvmidhit_s[i]) | ~csr_priv_virt[0]);
      end
      if (rs1) begin
        if (rs2) begin // all va && all asid
          l0v_sfence_clr = l0virt; l1v_sfence_clr = l1virt; l2v_sfence_clr = l2virt; spv_sfence_clr = spvirt;
        end else begin // all va && specific asid except global
          l0v_sfence_clr = l0virt & ~l0g & l0asidhit;
          l1v_sfence_clr = l1virt & ~l1g & l1asidhit;
          l2v_sfence_clr = l2virt & ~l2g & l2asidhit;
          spv_sfence_clr = spvirt & ~spg & spasidhit;
        end
      end else begin
        if (rs2) begin // specific leaf of addr && all asid
          l0v_sfence_clr = l0virt & l0vpnhit_s & l0flushMask_s;
          spv_sfence_clr = sphhit & sp_va_hit_s_ig;
        end else begin // specific leaf of addr && specific asid
          l0v_sfence_clr = l0virt & ~l0g & l0asidhit & l0vpnhit_s & l0flushMask_s;
          spv_sfence_clr = ~spg & sphhit & sp_va_hit_s;
        end
      end
    end else if (hfencev_valid) begin
      // 只清 onlyStage1 项，比 vmid + asid/va
      automatic logic [L0_SETS*L0_WAYS-1:0] l0hhit; automatic logic [L1_SETS*L1_WAYS-1:0] l1hhit;
      automatic logic [L2_SIZE-1:0] l2hhit; automatic logic [SP_SIZE-1:0] sphhit;
      for (int st=0; st<L0_SETS; st++) for (int w=0; w<L0_WAYS; w++) l0hhit[st*L0_WAYS+w] = (l0h[st][w] == ONLY_STAGE1);
      for (int st=0; st<L1_SETS; st++) for (int w=0; w<L1_WAYS; w++) l1hhit[st*L1_WAYS+w] = (l1h[st][w] == ONLY_STAGE1);
      for (int i=0; i<L2_SIZE; i++) l2hhit[i] = (l2h[i] == ONLY_STAGE1);
      for (int i=0; i<SP_SIZE; i++) sphhit[i] = (sph[i] == ONLY_STAGE1);
      if (rs1) begin
        if (rs2) begin
          l0v_sfence_clr = l0hhit & l0vmidhit_s; l1v_sfence_clr = l1hhit & l1vmidhit_s;
          l2v_sfence_clr = l2hhit & l2vmidhit;   spv_sfence_clr = sphhit & spvmidhit_s;
        end else begin
          l0v_sfence_clr = l0hhit & l0vmidhit_s & ~l0g & l0asidhit;
          l1v_sfence_clr = l1hhit & l1vmidhit_s & ~l1g & l1asidhit;
          l2v_sfence_clr = l2hhit & l2vmidhit   & ~l2g & l2asidhit;
          spv_sfence_clr = sphhit & spvmidhit_s & ~spg & spasidhit;
        end
      end else begin
        if (rs2) begin
          l0v_sfence_clr = l0hhit & l0vmidhit_s & l0vpnhit_s & l0flushMask_s;
          spv_sfence_clr = sphhit & sp_va_hit_s_ig;   // hfencev: isVSfence ignoreID
        end else begin
          l0v_sfence_clr = l0hhit & l0vmidhit_s & ~l0g & l0asidhit & l0vpnhit_s & l0flushMask_s;
          spv_sfence_clr = ~spg & sphhit & sp_va_hit_s;
        end
      end
    end else if (hfenceg_valid) begin
      // 只清 onlyStage2 项，比 vmid/va，gvpn = addr<<2
      automatic logic [L0_SETS*L0_WAYS-1:0] l0hhit; automatic logic [L1_SETS*L1_WAYS-1:0] l1hhit;
      automatic logic [L2_SIZE-1:0] l2hhit; automatic logic [SP_SIZE-1:0] sphhit;
      automatic logic [L2_SIZE-1:0] l2vmidhit_g;
      for (int st=0; st<L0_SETS; st++) for (int w=0; w<L0_WAYS; w++) l0hhit[st*L0_WAYS+w] = (l0h[st][w] == ONLY_STAGE2);
      for (int st=0; st<L1_SETS; st++) for (int w=0; w<L1_WAYS; w++) l1hhit[st*L1_WAYS+w] = (l1h[st][w] == ONLY_STAGE2);
      for (int i=0; i<L2_SIZE; i++) begin l2hhit[i] = (l2h[i] == ONLY_STAGE2); l2vmidhit_g[i] = (l2[i].vmid == sfence_dup_2_id); end
      for (int i=0; i<SP_SIZE; i++) sphhit[i] = (sph[i] == ONLY_STAGE2);
      if (rs1) begin
        if (rs2) begin
          l0v_sfence_clr = l0hhit; l1v_sfence_clr = l1hhit; l2v_sfence_clr = l2hhit; spv_sfence_clr = sphhit;
        end else begin
          l0v_sfence_clr = l0hhit & l0vmidhit_g; l1v_sfence_clr = l1hhit & l1vmidhit_g;
          l2v_sfence_clr = l2hhit & l2vmidhit_g; spv_sfence_clr = sphhit & spvmidhit_g;
        end
      end else begin
        if (rs2) begin
          l0v_sfence_clr = l0hhit & l0vpnhit_g & l0flushMask_g;
          spv_sfence_clr = sphhit & sp_va_hit_g_ig;
        end else begin
          l0v_sfence_clr = l0hhit & l0vmidhit_g & l0vpnhit_g & l0flushMask_g;
          spv_sfence_clr = sphhit & sp_va_hit_g;
        end
      end
    end
  end

  // ===========================================================================
  // l3v 失效（Sv48）—— 独立 always_comb，按 sfence_dup_2 的 rs1/rs2（rs1_l3/rs2_l3）。
  // golden 中 l3v 仅在「fence 有效 && dup2.rs1」时清除；dup2.rs1=0 时 l3v 不动（保留 refill）。
  // 三类 fence 互斥同上。vmid：普通sfence/hfencev 用 csr_hgatp_vmid[2]（=l3vmidhit），
  // hfenceg 用 sfence_dup_2_id（=l3vmidhit_g）。asid 统一用 sfence_dup_2_id（=l3asidhit）。
  // 对应 Scala 1238~1278。
  // ===========================================================================
  always_comb begin
    l3v_sfence_clr = '0;
    if (sfence_valid) begin
      automatic logic [L3_SIZE-1:0] l3hhit; automatic logic [L3_SIZE-1:0] l3virt;
      for (int i=0; i<L3_SIZE; i++) begin
        l3hhit[i] = hhit_sfence(l3h[i], csr_priv_virt[2]);
        l3virt[i] = l3hhit[i] & ((csr_priv_virt[2] & l3vmidhit[i]) | ~csr_priv_virt[2]);
      end
      if (rs1_l3) begin
        if (rs2_l3) l3v_sfence_clr = l3virt;
        else        l3v_sfence_clr = l3virt & ~l3g & l3asidhit;
      end
    end else if (hfencev_valid) begin
      automatic logic [L3_SIZE-1:0] l3hhit;
      for (int i=0; i<L3_SIZE; i++) l3hhit[i] = (l3h[i] == ONLY_STAGE1);
      if (rs1_l3) begin
        if (rs2_l3) l3v_sfence_clr = l3hhit & l3vmidhit;
        else        l3v_sfence_clr = ~l3g & l3hhit & l3asidhit & l3vmidhit;
      end
    end else if (hfenceg_valid) begin
      automatic logic [L3_SIZE-1:0] l3hhit; automatic logic [L3_SIZE-1:0] l3vmidhit_g;
      for (int i=0; i<L3_SIZE; i++) begin
        l3hhit[i] = (l3h[i] == ONLY_STAGE2);
        l3vmidhit_g[i] = (l3[i].vmid == sfence_dup_2_id);
      end
      if (rs1_l3) begin
        if (rs2_l3) l3v_sfence_clr = l3hhit;
        else        l3v_sfence_clr = l3hhit & l3vmidhit_g;
      end
    end
  end
