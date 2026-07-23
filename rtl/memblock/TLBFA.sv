// =============================================================================
// xs_TLBFA_core —— 全相联 TLB 存储核（可读重写）
//
// 对应 Chisel: xiangshan.cache.mmu.TLBStorage.scala  class TLBFA
//
// 在访存/取指流水中的位置：ITLB / DTLB(load/store) 把待翻译 vpn 送进来，本模块
//   作为“全相联页表项缓存”：第 0 拍接受 nWays 条目并行 CAM 匹配，第 1 拍输出
//   命中(hit) + 物理页号(ppn) + 权限(perm/g_perm) + 内存类型(pbmt) 等给上层 TLB 顶。
//   未命中由 TLB 顶发起 PTW，回填(refill)一条到本模块；sfence/hfence 负责按需刷新。
//
// 流水时序（与 golden 一致，1 拍读延迟）：
//   T0(req.fire): 算 hitVec(组合) → 寄存 hitVecReg；寄存 reqVpn；寄存 resp.valid
//   T1          : resp.hit = |hitVecReg；ppn/perm/pbmt = Mux1H(hitVecReg, 各条目)
//   genPPN 为组合(saveLevel=false)，用寄存后的 reqVpn 与（未变的）条目算出。
//
// 三个核心算子封装在 xs_tlbfa_pkg 的纯函数里：
//   xs_tlb_hit / xs_tlb_genppn / xs_tlb_refill。
// 本模块只负责：寄存器、N 条目数组、ports 路并行查询、refill 写、sfence/hfence 刷新、
//   替换访问(access)反馈。全部用 for/genvar 表达，行数远小于 golden(展平 2.3 万行)。
//
// 参数化覆盖两个 golden 变体：
//   TLBFA   : PORTS=3 NDUPS=1 NWAYS=48
//   TLBFA_1 : PORTS=4 NDUPS=2 NWAYS=48
// （nDups 只是把同一份结果复制 nDups 份输出，供下游分发，存储/匹配与 dup 无关。）
// =============================================================================
module xs_TLBFA_core import xs_tlbfa_pkg::*; #(
  parameter int PORTS  = 3,
  parameter int NDUPS  = 1,
  parameter int NWAYS  = 48,
  parameter int WAY_W  = 6,           // log2Up(NWAYS)
  // ---- 变体相关的“存储位裁剪”参数（与 golden 逐变体 DCE 对齐）----------------
  //   golden 对不同 TLBFA 实例的条目权限做了不同裁剪：ITLB(取指) 只需 x/a，故不存
  //   perm.d 与 g_perm 的写侧位(d/r/w)；DTLB(load/store) 需要 d/r/w，故全存。
  //   下列参数控制“是否在条目寄存器里物化这些位”——为 0 时把对应存储位钉成常量 0，
  //   使其被前端常量传播+死码消除掉（等价于 golden 里根本没有该寄存器）。
  //   注意：这些位在“被保留的那个变体里”是架构活状态，绝不能对两个变体一律删除。
  parameter bit KEEP_PERM_D    = 1'b1, // perm.d  : TLBFA=0(死) TLBFA_1=1(活)
  parameter bit KEEP_GPERM_DRW = 1'b1  // g_perm.{d,r,w}: TLBFA=0(死) TLBFA_1=1(活)
)(
  input  logic                          clock,
  input  logic                          reset,

  // sfence / hfence 刷新请求
  input  logic                          io_sfence_valid,
  input  logic                          io_sfence_bits_rs1,   // rs1==0(刷全部地址)
  input  logic                          io_sfence_bits_rs2,   // rs2==0(刷全部 asid/vmid)
  input  logic [49:0]                   io_sfence_bits_addr,
  input  logic [15:0]                   io_sfence_bits_id,    // asid / vmid
  input  logic                          io_sfence_bits_hv,    // hfence.vvma
  input  logic                          io_sfence_bits_hg,    // hfence.gvma

  // CSR 现场
  input  logic [ASID_LEN-1:0]           io_csr_satp_asid,
  input  logic [ASID_LEN-1:0]           io_csr_vsatp_asid,
  input  logic [15:0]                   io_csr_hgatp_vmid,  // golden 端口为 16 位
  input  logic                          io_csr_priv_virt,

  // 查询端口
  input  tlb_req_t                      io_r_req       [PORTS],
  input  logic                          io_r_req_valid [PORTS],
  output logic                          io_r_resp_valid[PORTS],
  output logic                          io_r_resp_hit  [PORTS],
  output logic [PPN_LEN-1:0]            io_r_resp_ppn    [PORTS][NDUPS],
  output logic [PBMT_LEN-1:0]           io_r_resp_pbmt   [PORTS][NDUPS],
  output logic [PBMT_LEN-1:0]           io_r_resp_g_pbmt [PORTS][NDUPS],
  output tlb_perm_t                     io_r_resp_perm   [PORTS][NDUPS],
  output tlb_gperm_t                    io_r_resp_g_perm [PORTS][NDUPS],
  output logic [1:0]                    io_r_resp_s2xlate[PORTS][NDUPS],

  // refill 写
  input  logic                          io_w_valid,
  input  logic [WAY_W-1:0]              io_w_bits_wayIdx,
  input  tlb_refill_t                   io_w_bits_data,

  // 替换访问反馈（touch_ways）
  output logic                          io_access_touch_ways_valid [PORTS],
  output logic [WAY_W-1:0]              io_access_touch_ways_bits  [PORTS]
);

  // =========================================================================
  // 架构状态：valid 位向量 + 条目数组（条目本体不复位，valid 复位清 0）
  // =========================================================================
  //   entries_q 是【寄存的】主体条目。entries 是【组合】读出视图。
  //   golden 对 ITLB(TLBFA) 不物化 perm.d / g_perm.{d,r,w}（零扇出），DTLB(TLBFA_1) 才有。
  //   为逐位对齐：KEEP=1 时 entries==entries_q（这 4 位是真寄存器，匹配 golden entries_N_*）；
  //   KEEP=0 时 entries 覆盖这 4 位为组合常量 0，且写入侧【根本不给这 4 位赋值】(见 g_entry_reg
  //   的 generate 分支)——从而它们不是触发器、无扇出，前端不生成任何寄存器（与 golden 一致）。
  logic       v        [NWAYS];
  tlb_entry_t entries_q [NWAYS];   // 寄存主体
  tlb_entry_t entries  [NWAYS];    // 组合读出视图（KEEP=0 时把可选 4 位钉 0）
  for (genvar w = 0; w < NWAYS; w++) begin : g_rdview
    always_comb begin
      entries[w] = entries_q[w];
      if (!KEEP_PERM_D)    entries[w].perm.d   = 1'b0;
      if (!KEEP_GPERM_DRW) begin
        entries[w].g_perm.d = 1'b0;
        entries[w].g_perm.r = 1'b0;
        entries[w].g_perm.w = 1'b0;
      end
    end
  end

  // refill 命中向量（one-hot of wayIdx），用于查询时屏蔽“本拍正在被写”的条目
  logic [NWAYS-1:0] refill_mask;
  always_comb begin
    refill_mask = '0;
    if (io_w_valid) refill_mask[io_w_bits_wayIdx] = 1'b1;
  end

  // =========================================================================
  // 查询路径：每端口 N 条目并行匹配 → 寄存 → Mux1H 输出
  // =========================================================================
  // 组合匹配向量（T0），按端口/条目
  logic [NWAYS-1:0] hitVec      [PORTS];
  // 寄存后的匹配向量与 vpn（T1）
  logic [NWAYS-1:0] hitVecReg   [PORTS];
  // reqVpn 只被 genPPN 用于拼大页/sector 低位，最高读到 bit26（&level 的 Sv48 段 vpn[26:18]）；
  //   bit[37:27] 在 Sv39 下【零扇出】(golden 端也是死位——unread_ref)。故只寄存被读到的低 27 位，
  //   impl 侧不物化任何死寄存器位（golden 仍保留 38 位的高段冗余=golden-only dead-ref）。
  localparam int RVPN_W = 27;            // genPPN 实际读到的 vpn 位宽 [26:0]
  logic [RVPN_W-1:0]  reqVpn    [PORTS];
  logic               respValid [PORTS];

  // 每端口的 asid / 模式派生
  for (genvar p = 0; p < PORTS; p++) begin : g_match
    wire        has_s2  = (io_r_req[p].s2xlate != NO_S2);
    wire        only_s2 = (io_r_req[p].s2xlate == ONLY_S2);
    wire        only_s1 = (io_r_req[p].s2xlate == ONLY_S1);
    // onlyS2 用 satp.asid；其余有 s2 时用 vsatp.asid，无 s2 用 satp.asid（实际 asid_hit
    // 在 onlyS2 时被忽略，这里取值与 golden 一致即可）
    wire [ASID_LEN-1:0] use_asid = has_s2 ? io_csr_vsatp_asid : io_csr_satp_asid;
    for (genvar w = 0; w < NWAYS; w++) begin : g_way
      always_comb begin
        // s2xlate_hit && hit() && valid && !被本拍 refill
        automatic logic s2x_hit = (entries[w].s2xlate == io_r_req[p].s2xlate);
        automatic logic h = xs_tlb_hit(entries[w], io_r_req[p].vpn, use_asid,
                                       io_csr_hgatp_vmid, has_s2, only_s2, only_s1,
                                       /*ignore_asid*/ 1'b0);
        hitVec[p][w] = s2x_hit & h & v[w] & ~refill_mask[w];
      end
    end
  end

  // T0→T1 寄存。hitVecReg 无复位（valid 门控）；reqVpn 异步复位清 0（与 golden
  // RegEnable(vpn, 0.U, req.fire) 一致——genPPN 用 reqVpn，故其复位值参与等价比对）。
  // resp.valid = RegNext(req.valid)，异步复位清 0。复位类型与 golden(async) 对齐以利 FM。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int p = 0; p < PORTS; p++) begin
        reqVpn[p]    <= '0;
        respValid[p] <= 1'b0;
      end
    end else begin
      for (int p = 0; p < PORTS; p++) begin
        respValid[p] <= io_r_req_valid[p];
        if (io_r_req_valid[p]) reqVpn[p] <= io_r_req[p].vpn[RVPN_W-1:0];
      end
    end
  end
  always_ff @(posedge clock) begin
    for (int p = 0; p < PORTS; p++)
      if (io_r_req_valid[p]) hitVecReg[p] <= hitVec[p];
  end

  // T1 输出：Mux1H(hitVecReg, 条目) + genPPN。nDups 份完全相同。
  for (genvar p = 0; p < PORTS; p++) begin : g_resp
    // Mux1H 累加（OR-of-AND，与 golden Mux1H 同构）
    logic [PPN_LEN-1:0]  ppn_sel;
    logic [PBMT_LEN-1:0] pbmt_sel, gpbmt_sel;
    tlb_perm_t           perm_sel;
    tlb_gperm_t          gperm_sel;
    logic [1:0]          s2x_sel;
    always_comb begin
      ppn_sel = '0; pbmt_sel = '0; gpbmt_sel = '0;
      perm_sel = '0; gperm_sel = '0; s2x_sel = '0;
      for (int w = 0; w < NWAYS; w++) begin
        if (hitVecReg[p][w]) begin
          // reqVpn 只存低 27 位；genPPN 形参是全 38 位，高位补 0（那些位 genPPN 从不读）。
          ppn_sel   |= xs_tlb_genppn(entries[w], {{(VPN_LEN-RVPN_W){1'b0}}, reqVpn[p]});
          pbmt_sel  |= entries[w].pbmt;
          gpbmt_sel |= entries[w].g_pbmt;
          perm_sel  |= entries[w].perm;
          gperm_sel |= entries[w].g_perm;
          s2x_sel   |= entries[w].s2xlate;
        end
      end
    end
    always_comb begin
      io_r_resp_valid[p] = respValid[p];
      io_r_resp_hit[p]   = |hitVecReg[p];
      for (int d = 0; d < NDUPS; d++) begin
        io_r_resp_ppn[p][d]     = ppn_sel;
        io_r_resp_pbmt[p][d]    = pbmt_sel;
        io_r_resp_g_pbmt[p][d]  = gpbmt_sel;
        io_r_resp_perm[p][d]    = perm_sel;
        io_r_resp_g_perm[p][d]  = gperm_sel;
        io_r_resp_s2xlate[p][d] = s2x_sel;
      end
    end
  end

  // =========================================================================
  // 替换访问反馈（access.touch_ways）
  //   平时：命中则报告命中 way（OHToUInt(hitVecReg)）。
  //   refill 后一拍(last_REG)：所有端口报告刚写入的 way，供替换器更新（PLRU/随机）。
  // =========================================================================
  logic             last_refill;          // RegNext(io_w_valid)，异步复位
  logic [WAY_W-1:0] refill_way_reg;        // RegEnable(wayIdx, io_w_valid)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) last_refill <= 1'b0;
    else       last_refill <= io_w_valid;
  end
  always_ff @(posedge clock) begin
    if (io_w_valid) refill_way_reg <= io_w_bits_wayIdx;
  end

  for (genvar p = 0; p < PORTS; p++) begin : g_access
    always_comb begin
      automatic logic [5:0] hit_way = xs_oh_to_uint({{(64-NWAYS){1'b0}}, hitVecReg[p]}, NWAYS);
      io_access_touch_ways_valid[p] = last_refill | (respValid[p] & (|hitVecReg[p]));
      io_access_touch_ways_bits[p]  = last_refill ? refill_way_reg : hit_way[WAY_W-1:0];
    end
  end

  // =========================================================================
  // refill 写：valid 时把 wayIdx 条目写为解包后的新条目，并置 valid。
  // =========================================================================
  tlb_entry_t refill_entry;
  always_comb refill_entry = xs_tlb_refill(io_w_bits_data);

  // =========================================================================
  // sfence / hfence 刷新（与 Scala 三个互斥 when 同构：hg → hv → 普通 sfence）
  //   下面把“对每个条目 valid 的下一拍值”算成纯组合 next_v，再统一寄存。
  // =========================================================================
  // sfence 用的 vpn（addr 高位 = addr[VAddrBits-1:offLen] = addr[49:12]），与 read 路 hit 同函数复用
  wire [VPN_LEN-1:0] sfence_vpn = io_sfence_bits_addr[49:12];

  logic v_next [NWAYS];
  for (genvar w = 0; w < NWAYS; w++) begin : g_flush
    always_comb begin
      automatic logic        cur   = v[w];
      automatic tlb_entry_t  e     = entries[w];
      automatic logic        has_s2 = (e.s2xlate != NO_S2);
      automatic logic        is_g   = (e.perm.g);
      // 复用 hit() 做“地址命中”：sfence 用 sfence_vpn+id(asid)+hgatp.vmid，
      //   hasS2 取 priv.virt（与 Scala sfenceHit 调用一致）。
      automatic logic addr_hit_asid =
          xs_tlb_hit(e, sfence_vpn, io_sfence_bits_id[ASID_LEN-1:0], io_csr_hgatp_vmid,
                     io_csr_priv_virt, 1'b0, 1'b0, /*ignore_asid*/1'b0);
      automatic logic addr_hit_noasid =
          xs_tlb_hit(e, sfence_vpn, '0, io_csr_hgatp_vmid,
                     io_csr_priv_virt, 1'b0, 1'b0, /*ignore_asid*/1'b1);
      // hfence.vvma：强制 hasS2=1（两级），vmid 用 hgatp.vmid
      automatic logic hv_hit_asid =
          xs_tlb_hit(e, sfence_vpn, io_sfence_bits_id[ASID_LEN-1:0], io_csr_hgatp_vmid,
                     1'b1, 1'b0, 1'b0, 1'b0);
      automatic logic hv_hit_noasid =
          xs_tlb_hit(e, sfence_vpn, '0, io_csr_hgatp_vmid,
                     1'b1, 1'b0, 1'b0, 1'b1);

      v_next[w] = cur;  // 默认保持

      if (io_sfence_valid && io_sfence_bits_hg) begin
        // ---- hfence.gvma：刷掉所有“有 s2xlate”的条目（rs2=1 全部 vmid；否则匹配 vmid==id）----
        if (io_sfence_bits_rs2)
          v_next[w] = cur & ~has_s2;
        else
          // 与 golden 一致：{2'b0,vmid} 与 16 位 id 全比较
          v_next[w] = cur & ~(has_s2 & ({2'b0, e.vmid} == io_sfence_bits_id));
      end else if (io_sfence_valid && io_sfence_bits_hv) begin
        // ---- hfence.vvma ----
        if (io_sfence_bits_rs1) begin
          if (io_sfence_bits_rs2)        // 全地址全 asid（限本 vmid 的 s2 条目）
            v_next[w] = cur & ~(has_s2 & ({2'b0, e.vmid} == io_csr_hgatp_vmid));
          else                            // 全地址特定 asid
            v_next[w] = cur & ~(~is_g & has_s2 &
                                (e.asid == io_sfence_bits_id[ASID_LEN-1:0]) &
                                ({2'b0, e.vmid} == io_csr_hgatp_vmid));
        end else begin
          if (io_sfence_bits_rs2)         // 特定地址全 asid
            v_next[w] = cur & ~hv_hit_noasid;
          else                            // 特定地址特定 asid
            v_next[w] = cur & ~(hv_hit_asid & ~is_g);
        end
      end else if (io_sfence_valid) begin
        // ---- 普通 sfence.vma ----
        if (io_sfence_bits_rs1) begin
          if (io_sfence_bits_rs2) begin   // 全地址全 asid
            // 非 virt 模式刷 noS2 条目；virt 模式刷本 vmid 的 s2 条目
            v_next[w] = cur & ~((~io_csr_priv_virt & ~has_s2) |
                                (io_csr_priv_virt & has_s2 & ({2'b0, e.vmid} == io_csr_hgatp_vmid)));
          end else begin                  // 全地址特定 asid（非 global）
            v_next[w] = cur & ~(~is_g &
                ((~io_csr_priv_virt & ~has_s2 & (e.asid == io_sfence_bits_id[ASID_LEN-1:0])) |
                 (io_csr_priv_virt & has_s2 & (e.asid == io_sfence_bits_id[ASID_LEN-1:0]) &
                  ({2'b0, e.vmid} == io_csr_hgatp_vmid))));
          end
        end else begin
          if (io_sfence_bits_rs2)         // 特定地址全 asid
            v_next[w] = cur & ~addr_hit_noasid;
          else                            // 特定地址特定 asid（非 global）
            v_next[w] = cur & ~(addr_hit_asid & ~is_g);
        end
      end
    end
  end

  // =========================================================================
  // 条目 + valid 的统一寄存。
  // valid 更新优先级（与 golden 合并后的 always 结构一致）：
  //   有任一 sfence/hfence 时 → 一律取 flush 结果 v_next（即便本拍也在 refill，
  //     refill 的“置 valid”被丢弃——但条目本体仍写入）；
  //   无 sfence 时 → refill 命中的 way 置 valid，其余保持。
  // 条目本体：只要 io_w_valid 命中本 way 就写入（与 sfence 无关，独立 always）。
  // 复位为异步（与 golden posedge reset 一致），仅清 valid。
  // =========================================================================
  wire any_sfence = io_sfence_valid;  // hg/hv/普通 sfence 都在 v_next 里处理
  for (genvar w = 0; w < NWAYS; w++) begin : g_entry_reg
    wire refill_hit = io_w_valid && (io_w_bits_wayIdx == w[WAY_W-1:0]);
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        v[w] <= 1'b0;
      end else if (any_sfence) begin
        v[w] <= v_next[w];                 // sfence 优先：丢弃本拍 refill 的置位
      end else begin
        v[w] <= refill_hit ? 1'b1 : v[w];  // 无 sfence：refill 命中置位
      end
    end
    // 条目本体（寄存）：refill 命中时写入解包后的新条目字段。为了在 KEEP=0 时让
    //   perm.d / g_perm.{d,r,w} 这 4 位【根本不成为触发器】，逐字段写 entries_q，并把这
    //   4 位放进 generate-if(KEEP)——KEEP=0 时它们从不被赋值→非触发器、无寄存器（对齐
    //   golden 该变体无此寄存器）；KEEP=1 时正常随 refill 寄存（DTLB 活状态，匹配 golden）。
    always_ff @(posedge clock) begin
      if (refill_hit) begin
        entries_q[w].tag      <= refill_entry.tag;
        entries_q[w].asid     <= refill_entry.asid;
        entries_q[w].level    <= refill_entry.level;
        entries_q[w].ppn      <= refill_entry.ppn;
        entries_q[w].n        <= refill_entry.n;
        entries_q[w].pbmt     <= refill_entry.pbmt;
        entries_q[w].g_pbmt   <= refill_entry.g_pbmt;
        entries_q[w].valididx <= refill_entry.valididx;
        entries_q[w].pteidx   <= refill_entry.pteidx;
        entries_q[w].ppn_low  <= refill_entry.ppn_low;
        entries_q[w].vmid     <= refill_entry.vmid;
        entries_q[w].s2xlate  <= refill_entry.s2xlate;
        // perm：除 d 外的位总寄存；d 位仅 KEEP_PERM_D 时寄存（见下 generate）。
        entries_q[w].perm.pf  <= refill_entry.perm.pf;
        entries_q[w].perm.af  <= refill_entry.perm.af;
        entries_q[w].perm.v   <= refill_entry.perm.v;
        entries_q[w].perm.a   <= refill_entry.perm.a;
        entries_q[w].perm.g   <= refill_entry.perm.g;
        entries_q[w].perm.u   <= refill_entry.perm.u;
        entries_q[w].perm.x   <= refill_entry.perm.x;
        entries_q[w].perm.w   <= refill_entry.perm.w;
        entries_q[w].perm.r   <= refill_entry.perm.r;
        // g_perm：pf/af/a/x 总寄存；d/r/w 仅 KEEP_GPERM_DRW 时寄存（见下 generate）。
        entries_q[w].g_perm.pf <= refill_entry.g_perm.pf;
        entries_q[w].g_perm.af <= refill_entry.g_perm.af;
        entries_q[w].g_perm.a  <= refill_entry.g_perm.a;
        entries_q[w].g_perm.x  <= refill_entry.g_perm.x;
      end
    end
    if (KEEP_PERM_D) begin : g_keep_perm_d
      always_ff @(posedge clock) if (refill_hit) entries_q[w].perm.d <= refill_entry.perm.d;
    end
    if (KEEP_GPERM_DRW) begin : g_keep_gperm_drw
      always_ff @(posedge clock) if (refill_hit) begin
        entries_q[w].g_perm.d <= refill_entry.g_perm.d;
        entries_q[w].g_perm.r <= refill_entry.g_perm.r;
        entries_q[w].g_perm.w <= refill_entry.g_perm.w;
      end
    end
  end

endmodule
