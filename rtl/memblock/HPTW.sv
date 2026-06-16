// =============================================================================
// xs_HPTW_core —— Hypervisor Page Table Walker（G-stage 页表遍历器，可读重写）
//
// 设计意图来自 PageTableWalker.scala class HPTW。HPTW 是 H 扩展专用的串行
// G-stage walker：接到一个 gvpn 翻译请求后，以 hgatp 为根，按 Sv39x4/Sv48x4
// 逐级走第二级页表，一直走到最后一级 leaf（与 PTW 不同，HPTW 自己走完所有级），
// 最终把 gpf/gaf 与翻译出的 G-stage TLB entry 通过 resp 返回给调用者
// （PTW/LLPTW）。一次只服务一个请求，io_req_ready 等价于 idle。
//
// 微架构要点（对照 Scala）：
//   1. “s_* / w_*”握手位：s 表示请求已发送/无需发送，w 表示响应已回/无需等待，
//      复位为 1，清零表示有事要做。这里保留这套位级协议，并用 hptw_state_e 做
//      高层投影方便读波形。
//   2. 地址生成：根级（af_level 处于最高）用 MakeGPAddr(hgatp.ppn, gvpnn_root)，
//      gvpnn_root 是 x4 的 11-bit 索引；后续级用 MakeAddr(ppn, vpnn) 的 9-bit 索引。
//   3. level 在 mem_addr_update 且未命中 leaf/af 时逐级下降；af_level 在每次
//      mem.resp 回来时下降，用于 access fault 时回报正确级别。
//   4. fault 优先级（见 resp 装配）：accessFault > pageFault > ppn_af。
// =============================================================================
module xs_HPTW_core
  import xs_hptw_pkg::*;
(
  input  logic              clock,
  input  logic              reset,

  input  logic              sfence_valid,
  input  hptw_csr_t         csr,

  output logic              req_ready,
  input  logic              req_valid,
  input  hptw_req_t         req,

  input  logic              resp_ready,
  output logic              resp_valid,
  output logic [SOURCE_W-1:0] resp_source,
  output hptw_resp_t        resp,
  output logic [ID_W-1:0]   resp_id,

  input  logic              mem_req_ready,
  output logic              mem_req_valid,
  output logic [PADDR_W-1:0] mem_req_addr,
  output logic              mem_req_hptw_bypassed,
  input  logic              mem_resp_valid,
  input  logic [XLEN-1:0]   mem_resp_bits,
  input  logic              mem_mask,

  output logic [H_PPN_W-1:0] refill_vpn,
  output logic [SOURCE_W-1:0] refill_source,
  output logic [1:0]        refill_level,

  output logic [PADDR_W-1:0] pmp_addr,
  input  logic              pmp_resp_ld,
  input  logic              pmp_resp_mmio
);

  // ---------------------------------------------------------------------------
  // 请求上下文寄存
  // ---------------------------------------------------------------------------
  logic [1:0]            level;     // 当前遍历级（一直降到 0）
  logic [1:0]            af_level;  // access fault 回报级
  logic [GPADDR_W-1:0]   gpaddr;    // {gvpn, 12'b0}，被翻译的 guest 物理地址
  logic [PPN_W-1:0]      req_ppn;   // page-cache 命中级的页基址
  logic                  l3_hit_r, l2_hit_r, l1_hit_r;
  logic                  bypassed_r;
  logic [ID_W-1:0]       id_r;
  logic [SOURCE_W-1:0]   source_r;

  // Scala 握手位（1=空闲/已完成，0=待办）
  logic s_pmp_check;
  logic s_mem_req;
  logic w_mem_resp;
  logic idle;
  logic mem_addr_update;

  logic access_fault_r;

  wire flush = sfence_valid || csr.hgatp_changed || csr.satp_changed || csr.vsatp_changed;
  wire [3:0] mode = csr.hgatp_mode;
  wire is_sv48 = (mode == HGATP_SV48);

  // gpaddr 高 38 位即被翻译的 guest VPN（offset 之上）。
  wire [H_PPN_W-1:0] vpn = gpaddr[GPADDR_W-1:OFF_W];
  wire [1:0] level_next = level - 2'h1;

  wire req_fire = idle && req_valid;

  // ---------------------------------------------------------------------------
  // PTE 解析（来自 page cache 的 mem.resp）
  // ---------------------------------------------------------------------------
  wire pte_t pte = mem_resp_bits;

  // page fault / access fault / leaf 判定
  wire page_fault = pte_is_gpf(pte, level, csr.m_pbmt_enable) ||
                    (!pte_is_leaf(pte) && level == 2'h0);
  wire ppn_af     = pte_access_fault(pte);
  wire find_pte   = pte_is_leaf(pte) || ppn_af || page_fault;

  // ---------------------------------------------------------------------------
  // 走表地址生成
  //   根级（af_level==最高）：MakeGPAddr(hgatp.ppn, gvpnn_root)
  //     Sv48 根在 level/af_level=3，根索引 = vpn[37:27]（gpaddr[49:39]）
  //     Sv39 根在 level/af_level=2，根索引 = vpn[28:18]（gpaddr[40:30]）
  //   后续级：MakeAddr(ppn, getVpnn(vpn, level))，9-bit 索引。
  // ---------------------------------------------------------------------------
  // 当前级页基址 ppn：命中级用 req_ppn，否则用上一级 PTE 读出的 ppn。
  // af_level 标记“距离根还有几级”，据此选 l3/l2/l1 的命中信息。
  function automatic logic [PPN_W-1:0] gen_ppn(
    input logic [1:0]      af_lv,
    input logic            sv48,
    input logic            h3, h2, h1,
    input logic [PPN_W-1:0] rppn,
    input pte_t            cur_pte
  );
    logic hit;
    if (sv48)
      hit = (af_lv == 2'h2) ? h3 : (af_lv == 2'h1) ? h2 : h1;
    else
      hit = (af_lv == 2'h1) ? h2 : h1;
    return hit ? rppn : cur_pte.ppn;
  endfunction

  // 本级页基址（36-bit PPN）。
  wire [PPN_W-1:0] ppn = gen_ppn(af_level, is_sv48, l3_hit_r, l2_hit_r, l1_hit_r, req_ppn, pte);

  // 后续级地址：MakeAddr(ppn, getVpnn(vpn,level)) = {ppn[35:0], vpnn[8:0], 3'b0} = 48 位。
  wire [PADDR_W-1:0] p_pte = {ppn, get_vpnn(vpn, level), 3'b000};

  // 根级地址：hgatp.ppn<<12 + gvpnn_root<<3（x4 索引宽 11 位）。
  wire [10:0] gvpnn_root = is_sv48 ? gpaddr[49:39] : gpaddr[40:30];
  wire [PADDR_W-1:0] pg_base = {csr.hgatp_ppn[PPN_W-1:0], 12'h0} + {{(PADDR_W-14){1'b0}}, gvpnn_root, 3'h0};

  wire at_root = is_sv48 ? (af_level == 2'h3) : (af_level == 2'h2);
  wire [PADDR_W-1:0] mem_addr = at_root ? pg_base : p_pte;

  // ---------------------------------------------------------------------------
  // 状态投影（仅供读波形；控制仍用 s/w 位）
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    H_IDLE,       // 空闲，可接收请求
    H_PMP_CHECK,  // 同拍 PMP 检查页表项读地址
    H_MEM_REQ,    // 向 page cache 发 PTE 读请求
    H_MEM_WAIT,   // 等待 PTE 返回
    H_RESP_WAIT   // 走完，等待上游接收 resp
  } hptw_state_e;
  hptw_state_e state_q;
  always_comb begin
    if (idle)                 state_q = H_IDLE;
    else if (mem_addr_update) state_q = H_RESP_WAIT;
    else if (!s_pmp_check)    state_q = H_PMP_CHECK;
    else if (!s_mem_req)      state_q = H_MEM_REQ;
    else                      state_q = H_MEM_WAIT;
  end

  // ---------------------------------------------------------------------------
  // PMP / access fault
  //   sent_to_pmp：本拍向 PMP 提交读地址（同拍返回 ld/mmio）。
  //   accessFault：RegEnable，只在 sent_to_pmp 拍更新。
  // ---------------------------------------------------------------------------
  // resp_valid：走到 leaf/af（w_mem_resp&find_pte）或 PMP access fault。
  wire resp_valid_w = !idle && mem_addr_update &&
                      ((w_mem_resp && find_pte) || (s_pmp_check && access_fault_r));

  wire finish = mem_addr_update && (find_pte || access_fault_r) && resp_valid_w;
  wire sent_to_pmp = !idle && (!s_pmp_check || mem_addr_update) && !finish;

  wire resp_gaf = access_fault_r || (ppn_af && !page_fault);

  // ---------------------------------------------------------------------------
  // 输出装配
  // ---------------------------------------------------------------------------
  assign req_ready    = idle;
  assign resp_valid   = resp_valid_w;
  assign resp_source  = source_r;
  assign resp_id      = id_r;

  // HptwResp.apply：gaf 优先于 gpf 优先于 ppn_af；gaf 时清空 entry payload。
  assign resp.tag   = vpn;
  assign resp.vmid  = csr.hgatp_vmid_raw[VMID_W-1:0];
  assign resp.n     = !resp_gaf && pte.n;
  assign resp.pbmt  = resp_gaf ? 2'h0 : pte.pbmt;
  assign resp.ppn   = resp_gaf ? '0 : {2'h0, pte.ppn};
  assign resp.perm.d = !resp_gaf && pte.perm_d;
  assign resp.perm.a = !resp_gaf && pte.perm_a;
  assign resp.perm.g = !resp_gaf && pte.perm_g;
  assign resp.perm.u = !resp_gaf && pte.perm_u;
  assign resp.perm.x = !resp_gaf && pte.perm_x;
  assign resp.perm.w = !resp_gaf && pte.perm_w;
  assign resp.perm.r = !resp_gaf && pte.perm_r;
  assign resp.level = access_fault_r ? af_level : level;
  assign resp.gpf   = page_fault && !access_fault_r;
  assign resp.gaf   = resp_gaf;

  assign mem_req_valid        = !s_mem_req && !mem_mask && !access_fault_r && s_pmp_check;
  assign mem_req_addr         = mem_addr;
  assign mem_req_hptw_bypassed = bypassed_r;

  assign refill_vpn    = vpn;
  assign refill_source = source_r;
  assign refill_level  = level;

  assign pmp_addr = mem_addr;

  // ---------------------------------------------------------------------------
  // 起始级解码：命中 l1/l2/l3 时从对应级开始。
  //   l1Hit → level 0；l2Hit → level 1；
  //   Sv48: l3Hit → 2，否则 3；Sv39: 否则 2。
  // ---------------------------------------------------------------------------
  function automatic logic [1:0] start_level(
    input logic sv48, input logic l1h, input logic l2h, input logic l3h
  );
    if (l1h) return 2'h0;
    if (l2h) return 2'h1;
    if (sv48) return l3h ? 2'h2 : 2'h3;
    return 2'h2;
  endfunction
  wire [1:0] start_lv = start_level(is_sv48, req.l1_hit, req.l2_hit, req.l3_hit);

  // ---------------------------------------------------------------------------
  // 时序逻辑
  // ---------------------------------------------------------------------------
  // 与 mem.resp 同拍下降 af_level；req_fire 时初始化。
  // mem_addr_update 且未命中 leaf/af 时 level 逐级下降。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      level       <= 2'h3;
      af_level    <= 2'h3;
      s_pmp_check <= 1'b1;
      s_mem_req   <= 1'b1;
      w_mem_resp  <= 1'b1;
      idle        <= 1'b1;
      mem_addr_update <= 1'b0;
    end else begin
      // ---- level 更新 ----
      if (mem_addr_update && !(find_pte || access_fault_r))
        level <= level_next;
      else if (req_fire)
        level <= start_lv;

      // ---- af_level 更新 ----
      if (mem_resp_valid && !w_mem_resp)
        af_level <= af_level - 2'h1;
      else if (req_fire)
        af_level <= start_lv;

      // ---- 握手位 ----
      if (flush) begin
        s_pmp_check <= 1'b1;
        s_mem_req   <= 1'b1;
        w_mem_resp  <= 1'b1;
        idle        <= 1'b1;
        mem_addr_update <= 1'b0;
      end else begin
        // s_pmp_check
        if (access_fault_r && !idle)          s_pmp_check <= 1'b1;
        else if (sent_to_pmp && !mem_addr_update) s_pmp_check <= 1'b1;
        else if (req_fire)                    s_pmp_check <= 1'b0;

        // s_mem_req：mem.req.fire / access fault / pmp 通过后置发 / mem_addr_update 降级后重发
        if (mem_addr_update && !(find_pte || access_fault_r))
          s_mem_req <= 1'b0;                      // 降级后重新发起下一级读
        else if (mem_req_ready && mem_req_valid)  s_mem_req <= 1'b1;
        else if (access_fault_r && !idle)         s_mem_req <= 1'b1;
        else if (sent_to_pmp && !mem_addr_update) s_mem_req <= 1'b0;

        // w_mem_resp
        if (mem_resp_valid && !w_mem_resp)        w_mem_resp <= 1'b1;
        else if (mem_req_ready && mem_req_valid)  w_mem_resp <= 1'b0;
        else if (access_fault_r && !idle)         w_mem_resp <= 1'b1;

        // idle：走完且 resp 被接收时回到空闲
        if (mem_addr_update && (find_pte || access_fault_r) && resp_valid_w && resp_ready)
          idle <= 1'b1;
        else if (req_fire)                        idle <= 1'b0;

        // mem_addr_update：mem.resp 回来 / access fault 触发置位；降级或 resp.fire 清零
        if (mem_addr_update && (!(find_pte || access_fault_r) ||
                                (resp_valid_w && resp_ready)))
          mem_addr_update <= 1'b0;
        else if ((mem_resp_valid && !w_mem_resp) || (access_fault_r && !idle))
          mem_addr_update <= 1'b1;
      end
    end
  end

  // accessFault：RegEnable(pmp.ld|mmio, sent_to_pmp)，复位/flush/req_fire 清。
  // 与 golden 一致：finish 拍若没被 resp.fire/req_fire 清，则继续保持 pmp 结果。
  always_ff @(posedge clock) begin
    if (req_fire) begin
      gpaddr     <= {req.gvpn, 12'h0};
      req_ppn    <= req.ppn;
      l3_hit_r   <= is_sv48 && req.l3_hit;
      l2_hit_r   <= req.l2_hit;
      l1_hit_r   <= req.l1_hit;
      bypassed_r <= req.bypassed;
      id_r       <= req.id;
    end
    if (req_fire) source_r <= req.source;

    if (flush)
      access_fault_r <= 1'b0;
    else if (finish)
      access_fault_r <= !(( resp_valid_w && resp_ready) || req_fire) &&
                        (sent_to_pmp ? (pmp_resp_ld || pmp_resp_mmio) : access_fault_r);
    else
      access_fault_r <= !req_fire &&
                        (sent_to_pmp ? (pmp_resp_ld || pmp_resp_mmio) : access_fault_r);
  end

endmodule
