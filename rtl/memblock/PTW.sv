// =============================================================================
// xs_PTW_core —— Page Table Walker（页表遍历器，可读 SystemVerilog 重写）
//
// 设计意图来自 PageTableWalker.scala class PTW。PTW 是共享 MMU/L2TLB 的
// “串行上层 walker”：L2TLB miss 后，PTW 先走 Sv48/Sv39 的高层页表，
// 遇到 superpage/fault 直接返回可回填项；若走到最后一级仍未找到 leaf，
// 则把请求交给 LLPTW 并释放本 FSM。H 扩展下，VS-stage 产生的 GPA 还需
// 通过 HPTW 做 G-stage 翻译，page-cache 访问地址因此可能是 host PA。
//
// 微架构要点：
//   1. 本核一次只服务一个 L2TLB miss，io_req_ready 等价于 idle。
//   2. “s_* / w_*”握手位来自 Scala：s 表示 request 已发送/不需要发送，
//      w 表示 response 已回来/不需要等待。复位均为 1，清零表示有事要做。
//   3. PTE 解析集中在 xs_ptw_pkg：leaf/non-leaf/page fault/access fault/
//      superpage 地址拼接都用纯函数表达，避免把 PTE 位域散落在控制 FSM 中。
//   4. G-stage 分两类：首次 HPTW 用于把页表页 GPA 翻译成 HPA；最后一次
//      HPTW 用于把 VS-stage leaf 结果翻译成最终 HPA entry。
// =============================================================================
module xs_PTW_core
  import xs_ptw_pkg::*;
(
  input  logic          clock,
  input  logic          reset,

  input  logic          sfence_valid,
  input  ptw_csr_t      csr,

  output logic          req_ready,
  input  logic          req_valid,
  input  ptw_req_info_t req_info,
  input  logic          req_l3_hit,
  input  logic          req_l2_hit,
  input  logic [PTE_PPN_W-1:0] req_ppn,
  input  logic          req_stage1_hit,
  input  ptw_merge_resp_t req_stage1,

  input  logic          resp_ready,
  output logic          resp_valid,
  output logic [SOURCE_W-1:0] resp_source,
  output logic [1:0]    resp_s2xlate,
  output ptw_merge_resp_t resp_merge,
  output hptw_resp_t    resp_h,

  input  logic          llptw_ready,
  output logic          llptw_valid,
  output ptw_req_info_t llptw_req_info,

  input  logic          hptw_req_ready,
  output logic          hptw_req_valid,
  output logic [SOURCE_W-1:0] hptw_req_source,
  output logic [PTE_PPN_W-1:0] hptw_req_gvpn,
  input  logic          hptw_resp_valid,
  input  hptw_resp_t    hptw_resp_in,

  input  logic          mem_req_ready,
  output logic          mem_req_valid,
  output logic [PADDR_W-1:0] mem_req_addr,
  input  logic          mem_resp_valid,
  input  logic [XLEN-1:0] mem_resp_bits,
  input  logic          mem_mask,

  output logic [PADDR_W-1:0] pmp_addr,
  input  logic          pmp_resp_ld,
  input  logic          pmp_resp_mmio,

  output ptw_req_info_t refill_req_info,
  output logic [1:0]    refill_level,

  output logic [6:0][5:0] perf
);

  genvar gi;

  // ---------------------------------------------------------------------------
  // 请求上下文寄存：一次 PTW walk 的固定元数据
  // ---------------------------------------------------------------------------
  logic idle;
  logic [1:0] req_s2xlate;
  logic [1:0] level;
  logic [1:0] af_level;
  logic [1:0] gpf_level;
  logic [PTE_PPN_W-1:0] root_or_cache_ppn;
  logic [VPN_W-1:0] vpn;
  logic l3_hit_r;
  logic l2_hit_r;
  logic [SOURCE_W-1:0] source_r;
  logic stage1_hit_r;
  ptw_merge_resp_t stage1_r;
  hptw_resp_t hptw_resp_r;

  // Scala 中的握手状态位。1 表示“空闲/已完成”，0 表示“需要发送或等待”。
  logic sent_pmp_check;
  logic sent_mem_req;
  logic sent_llptw_req;
  logic wait_mem_resp;
  logic sent_hptw_req;
  logic wait_hptw_resp;
  logic sent_last_hptw_req;
  logic wait_last_hptw_resp;
  logic mem_addr_ready;
  logic hptw_page_fault;
  logic hptw_access_fault;
  logic need_last_s2xlate;
  logic hptw_resp_stage2;
  logic first_gvpn_check_fail;
  logic pte_valid;
  logic access_fault_r;
  logic update_full_gvpn_from_mem;
  logic [PTE_PPN_W-1:0] full_gvpn_r;
  logic [6:0] perf_event_s1;   // bit5 由 perf_event_s1_5 提供(见下), 本向量 bit5 不驱动不读
  logic [6:0] perf_event_s2;
  // perf[5] 的事件累积器(mem 在途): golden perfEvents_5_2 带复位, 单独拆出放复位块;
  // 其余 perf 流水级 golden 无复位(XSPerfAccumulate 的 REG/REG_1), 放无复位块。
  logic perf_event_s1_5;

  // 这个 enum 是代码阅读用的高层状态投影；实际控制仍保持 Scala 的 s/w
  // 位级协议，避免把并行 handshake 行为压扁成过度简化的单状态。
  ptw_state_e state_q, state_d;

  wire flush = sfence_valid || csr.satp_changed || csr.vsatp_changed || csr.hgatp_changed;
  wire req_fire = idle && req_valid;
  wire s2_enabled = req_s2xlate != NO_S2XLATE;
  wire only_stage1 = req_s2xlate == ONLY_STAGE1;
  wire only_stage2 = req_s2xlate == ONLY_STAGE2;
  wire need_g_stage_for_mem = s2_enabled && !only_stage1;

  wire satp_from_vs = req_fire ? (req_info.s2xlate != NO_S2XLATE) : s2_enabled;
  wire [3:0] satp_mode = satp_from_vs ? csr.vsatp_mode : csr.satp_mode;
  wire [ASID_W-1:0] satp_asid = satp_from_vs ? csr.vsatp_asid : csr.satp_asid;
  wire [PTE_PPN_W-1:0] satp_ppn = satp_from_vs ? csr.vsatp_ppn : csr.satp_ppn;
  wire s1_pbmt_enable = s2_enabled ? csr.h_pbmt_enable : csr.m_pbmt_enable;

  pte_t pte;
  assign pte = pte_t'(mem_resp_bits);
  wire [PTE_PPN_W-1:0] pte_full_ppn = pte_ppn(pte);
  wire [PTE_PPN_W-1:0] req_start_ppn =
    (req_l2_hit || ((satp_mode == 4'h9) && req_l3_hit)) ? req_ppn : satp_ppn;

  wire pte_pf = pte_page_fault(pte, level, s1_pbmt_enable);
  wire ppn_af = s2_enabled ? (only_stage1 && pte_access_fault(pte)) : pte_access_fault(pte);
  wire find_pte = pte_is_leaf(pte) || ppn_af || pte_pf;
  wire to_find_last_level = (level == 2'h1) && !find_pte;

  // ---------------------------------------------------------------------------
  // 页表项地址生成：satp/vsatp root、上级 PTE.ppn、PTW cache 命中 ppn 三者拼接 vpnn
  // ---------------------------------------------------------------------------
  logic [PTE_ADDR_W-1:0] l3_addr;
  logic [PTE_ADDR_W-1:0] l2_addr;
  logic [PTE_ADDR_W-1:0] l1_addr;
  logic [PTE_ADDR_W-1:0] current_pt_addr;
  logic [PTE_ADDR_W-1:0] gpaddr_56;
  logic [H_ENTRY_PPN_W-1:0] hptw_host_ppn;

  always_comb begin
    l3_addr = make_pte_addr(satp_ppn, get_vpnn(vpn, 2'h3));
    if (satp_mode == 4'h9)
      l2_addr = make_pte_addr(l3_hit_r ? root_or_cache_ppn : pte_full_ppn, get_vpnn(vpn, 2'h2));
    else
      l2_addr = make_pte_addr(satp_ppn, get_vpnn(vpn, 2'h2));
    l1_addr = make_pte_addr(l2_hit_r ? root_or_cache_ppn : pte_full_ppn, get_vpnn(vpn, 2'h1));

    priority case (af_level)
      2'h3:    current_pt_addr = l3_addr;
      2'h2:    current_pt_addr = l2_addr;
      default: current_pt_addr = l1_addr;
    endcase
  end

  wire [PTE_PPN_W-1:0] full_gvpn = update_full_gvpn_from_mem ? pte_full_ppn : full_gvpn_r;

  always_comb begin
    gpaddr_56 = current_pt_addr;
    if (stage1_hit_r || only_stage2) begin
      gpaddr_56 = {full_gvpn, 12'h0};
    end else if (!sent_last_hptw_req) begin
      priority case (level)
        2'h3:    gpaddr_56 = {pte_full_ppn[43:27], vpn[26:0], 12'h0};
        2'h2:    gpaddr_56 = {pte_full_ppn[43:18], vpn[17:0], 12'h0};
        2'h1:    gpaddr_56 = {pte_full_ppn[43:9],  vpn[8:0],  12'h0};
        default: gpaddr_56 = {pte_full_ppn, 12'h0};
      endcase
    end
  end

  wire gstage_first_fault = hptw_page_fault || hptw_access_fault;
  wire high_fail_sv39 = |full_gvpn[43:29];
  wire high_fail_sv48 = |full_gvpn[43:38];
  wire gvpn_gpf =
    (!(gstage_first_fault || ((pte_pf || ppn_af) && pte_valid)) &&
      ((need_g_stage_for_mem && csr.hgatp_mode == 4'h8 && high_fail_sv39) ||
       (need_g_stage_for_mem && csr.hgatp_mode == 4'h9 && high_fail_sv48))) ||
    first_gvpn_check_fail;
  wire guest_fault = gstage_first_fault || gvpn_gpf;

  assign hptw_host_ppn = hptw_gen_ppn_s2(hptw_resp_r, gpaddr_56[49:12]);
  assign mem_req_addr = need_g_stage_for_mem ? {hptw_host_ppn[35:0], gpaddr_56[11:0]}
                                             : current_pt_addr[PADDR_W-1:0];
  assign pmp_addr = mem_req_addr;

  // ---------------------------------------------------------------------------
  // PTE → PTW merge resp。8 个 sector entry 共用同一份 PTE 解析结果；pteidx
  // 指出本次命中的 4KB 子页。stage1Hit/早期 guestFault 时直接返回传入的 stage1。
  // ---------------------------------------------------------------------------
  wire resp_pf = pte_valid && pte_pf;
  wire resp_af = (access_fault_r || ppn_af) && !(resp_pf || guest_fault);
  wire [1:0] resp_level = (access_fault_r && resp_af) ? af_level
                            : (guest_fault ? gpf_level : level);
  wire return_stage1 = stage1_hit_r || ((l3_hit_r || l2_hit_r) && guest_fault && !pte_valid);

  ptw_merge_entry_t generated_entry;
  always_comb begin
    generated_entry = '0;
    generated_entry.tag = vpn[VPN_W-1:SECTOR_BITS];
    generated_entry.asid = satp_asid;
    generated_entry.vmid = csr.hgatp_vmid_raw[VMID_W-1:0];
    generated_entry.n = pte_valid && pte.n;
    generated_entry.pbmt = pte_valid ? pte.pbmt : 2'h0;
    generated_entry.perm.d = pte_valid && pte.perm.d;
    generated_entry.perm.a = pte_valid && pte.perm.a;
    generated_entry.perm.g = pte_valid && pte.perm.g;
    generated_entry.perm.u = pte_valid && pte.perm.u;
    generated_entry.perm.x = pte_valid && pte.perm.x;
    generated_entry.perm.w = pte_valid && pte.perm.w;
    generated_entry.perm.r = pte_valid && pte.perm.r;
    generated_entry.level = resp_level;
    generated_entry.v = pte_valid && pte.perm.v;
    generated_entry.ppn = {pte_valid ? pte.ppn_high : root_or_cache_ppn[43:36],
                           pte_valid ? pte.ppn[35:3] : root_or_cache_ppn[35:3]};
    generated_entry.ppn_low = pte_valid ? pte.ppn[2:0] : root_or_cache_ppn[2:0];
    generated_entry.af = resp_af;
    generated_entry.pf = resp_pf;

    resp_merge = '0;
    for (int i = 0; i < CONTIGUOUS; i++) begin
      resp_merge.entry[i] = return_stage1 ? stage1_r.entry[i] : generated_entry;
      // golden 的 stage1 entry 输入没有 af 字段(常量0折叠), stage1_r.entry[i].af
      // 寄存器无复位后上电为 X, 读出点强制回 golden 的常量 0。
      resp_merge.entry[i].af = return_stage1 ? 1'b0 : generated_entry.af;
      resp_merge.pteidx[i] = return_stage1 ? stage1_r.pteidx[i] : (vpn[2:0] == 3'(i));
    end
    resp_merge.not_super = return_stage1 && stage1_r.not_super;
  end

  always_comb begin
    resp_h = hptw_resp_r;
    if (gvpn_gpf) begin
      resp_h = '0;
      resp_h.tag = gpaddr_56[49:12];
      resp_h.vmid = csr.hgatp_vmid_raw[VMID_W-1:0];
      resp_h.gpf = 1'b1;
    end
  end

  assign resp_valid =
    stage1_hit_r
      ? (!idle && hptw_resp_stage2)
      : (!idle && mem_addr_ready && !need_last_s2xlate &&
         (guest_fault || (wait_mem_resp && find_pte) ||
          (sent_pmp_check && access_fault_r) || only_stage2));
  assign resp_source = source_r;
  assign resp_s2xlate = req_s2xlate;

  assign llptw_valid = !sent_llptw_req && to_find_last_level && !access_fault_r && !guest_fault;
  assign llptw_req_info = '{vpn: vpn, s2xlate: req_s2xlate, source: source_r};

  assign hptw_req_valid = !sent_hptw_req || !sent_last_hptw_req;
  assign hptw_req_source = source_r;
  assign hptw_req_gvpn = gpaddr_56[55:12];

  assign mem_req_valid = !sent_mem_req && !mem_mask && !access_fault_r && sent_pmp_check;
  assign req_ready = idle;
  assign refill_req_info = '{vpn: vpn, s2xlate: req_s2xlate, source: source_r};
  assign refill_level = level;

  // 高层状态投影，供波形阅读和文档对应。
  always_comb begin
    state_d = state_q;
    if (idle) state_d = PTW_IDLE;
    else if (!sent_hptw_req) state_d = PTW_HPTW_REQ;
    else if (!wait_hptw_resp) state_d = PTW_HPTW_WAIT;
    else if (!sent_pmp_check) state_d = PTW_PMP_CHECK;
    else if (!sent_mem_req) state_d = PTW_MEM_REQ;
    else if (!wait_mem_resp) state_d = PTW_MEM_WAIT;
    else if (!sent_last_hptw_req) state_d = PTW_LAST_HPTW_REQ;
    else if (!wait_last_hptw_resp) state_d = PTW_LAST_HPTW_WAIT;
    else if (llptw_valid) state_d = PTW_LLPTW_REQ;
    else if (resp_valid) state_d = PTW_RESP_WAIT;
    else state_d = PTW_EVAL_PTE;
  end

  // ---------------------------------------------------------------------------
  // 主控制时序：按 Scala when 顺序写，后面的事件覆盖前面的更新。
  // ---------------------------------------------------------------------------
  wire hptw_first_fire = hptw_req_valid && hptw_req_ready && !sent_hptw_req;
  wire hptw_last_fire  = hptw_req_valid && hptw_req_ready && !sent_last_hptw_req;
  wire hptw_perm_fail =
    hptw_resp_valid && !hptw_resp_in.gaf &&
    !hptw_resp_in.perm.r && !(csr.priv_mxr && hptw_resp_in.perm.x);
  wire mem_req_fire = mem_req_valid && mem_req_ready;
  wire resp_fire = resp_valid && resp_ready;
  wire llptw_fire = llptw_valid && llptw_ready;
  wire descend_next_level =
    level[1] && !only_stage2 && !(guest_fault || find_pte || access_fault_r);
  wire vs_finish = mem_addr_ready && descend_next_level && need_g_stage_for_mem;
  wire finish =
    mem_addr_ready && !descend_next_level &&
    (llptw_valid || (!(need_g_stage_for_mem && need_last_s2xlate) && resp_valid));
  wire sent_to_pmp =
    !idle && (!sent_pmp_check || mem_addr_ready) &&
    !finish && !vs_finish && !first_gvpn_check_fail && !(find_pte && pte_valid);

  function automatic logic [2:0] onehot_index(input logic [CONTIGUOUS-1:0] oh);
    logic [2:0] idx;
    idx = 3'h0;
    for (int i = 0; i < CONTIGUOUS; i++) begin
      if (oh[i]) idx = 3'(i);
    end
    return idx;
  endfunction

  // ---------------------------------------------------------------------------
  // 复位域拆分与 golden 精确对齐(FM 等价性):
  //   golden 只复位控制寄存器(idle/level/af_level/gpf_level/s_*/w_*/mem_addr_update/
  //   hptw_pageFault/hptw_accessFault/need_last_s2xlate/first_gvpn_check_fail/
  //   pte_valid/accessFault/update_full_gvpn_mem_resp/perfEvents_5_2), 异步复位;
  //   payload 寄存器(req_s2xlate/ppn/vpn/l2Hit/l3Hit/source/stage1Hit/stage1_entry/
  //   hptw_resp_entry/hptw_resp_stage2/full_gvpn_reg/perf 打拍级)golden 无复位。
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      idle <= 1'b1;
      level <= 2'h3;
      af_level <= 2'h3;
      gpf_level <= 2'h3;
      sent_pmp_check <= 1'b1;
      sent_mem_req <= 1'b1;
      sent_llptw_req <= 1'b1;
      wait_mem_resp <= 1'b1;
      sent_hptw_req <= 1'b1;
      wait_hptw_resp <= 1'b1;
      sent_last_hptw_req <= 1'b1;
      wait_last_hptw_resp <= 1'b1;
      mem_addr_ready <= 1'b0;
      hptw_page_fault <= 1'b0;
      hptw_access_fault <= 1'b0;
      need_last_s2xlate <= 1'b0;
      first_gvpn_check_fail <= 1'b0;
      pte_valid <= 1'b0;
      access_fault_r <= 1'b0;
      update_full_gvpn_from_mem <= 1'b0;
      state_q <= PTW_IDLE;
      perf_event_s1_5 <= 1'b0;
    end else begin
      state_q <= state_d;

      // 请求进入：按 PTW cache 命中情况决定从 level3/2/1 开始走。
      if (req_fire) begin
        hptw_page_fault <= 1'b0;
        hptw_access_fault <= 1'b0;
        idle <= 1'b0;
      end

      if (req_fire && req_stage1_hit) begin
        need_last_s2xlate <= 1'b0;
        sent_last_hptw_req <= 1'b0;
        // golden 不在 stage1Hit 入队时写 w_last_hptw_resp(靠不变式此时恒为1),
        // 显式置1会造成 FM 次态函数不等价 —— 保持 hold。
      end

      if (req_fire && !req_stage1_hit) begin
        access_fault_r <= 1'b0;
        pte_valid <= 1'b0;
        // first_gvpn_check_fail: golden 在新请求进入时是 chk|old(OR 保持), 不清零
        // (上一走完 resp_fire/flush 已清), 此处不写 0 以对齐次态函数。
        if (satp_mode == 4'h9) begin
          level <= req_l2_hit ? 2'h1 : (req_l3_hit ? 2'h2 : 2'h3);
          af_level <= req_l2_hit ? 2'h1 : (req_l3_hit ? 2'h2 : 2'h3);
          gpf_level <= req_l2_hit ? 2'h2 : (req_l3_hit ? 2'h3 : 2'h0);
        end else begin
          level <= req_l2_hit ? 2'h1 : 2'h2;
          af_level <= req_l2_hit ? 2'h1 : 2'h2;
          gpf_level <= req_l2_hit ? 2'h2 : 2'h0;
        end

        if (req_info.s2xlate == ONLY_STAGE2) begin
          need_last_s2xlate <= 1'b0;
          if (csr.hgatp_mode == 4'h8 && |req_info.vpn[37:29]) begin
            mem_addr_ready <= 1'b1;
            first_gvpn_check_fail <= 1'b1;
          end else begin
            sent_last_hptw_req <= 1'b0;
          end
        end else if (req_info.s2xlate == ALL_STAGE) begin
          if ((csr.hgatp_mode == 4'h8 && |req_start_ppn[43:29]) ||
              (csr.hgatp_mode == 4'h9 && |req_start_ppn[43:38])) begin
            mem_addr_ready <= 1'b1;
            first_gvpn_check_fail <= 1'b1;
          end else begin
            need_last_s2xlate <= 1'b1;
            sent_hptw_req <= 1'b0;
          end
        end else begin
          need_last_s2xlate <= 1'b0;
          sent_pmp_check <= 1'b0;
        end
      end

      if (resp_fire && stage1_hit_r) begin
        idle <= 1'b1;
      end

      if (hptw_first_fire) begin
        sent_hptw_req <= 1'b1;
        wait_hptw_resp <= 1'b0;
      end
      if (hptw_resp_valid && !wait_hptw_resp) begin
        wait_hptw_resp <= 1'b1;
        hptw_page_fault <= hptw_resp_in.gpf || hptw_perm_fail;
        hptw_access_fault <= hptw_resp_in.gaf;
        if (!(hptw_perm_fail || hptw_resp_in.gpf || hptw_resp_in.gaf))
          sent_pmp_check <= 1'b0;
        else begin
          mem_addr_ready <= 1'b1;
          need_last_s2xlate <= 1'b0;
        end
      end

      if (hptw_last_fire) begin
        sent_last_hptw_req <= 1'b1;
        wait_last_hptw_resp <= 1'b0;
      end
      if (hptw_resp_valid && !wait_last_hptw_resp && stage1_hit_r) begin
        wait_last_hptw_resp <= 1'b1;
      end
      if (hptw_resp_valid && !wait_last_hptw_resp && !stage1_hit_r) begin
        wait_last_hptw_resp <= 1'b1;
        hptw_page_fault <= hptw_resp_in.gpf;
        hptw_access_fault <= hptw_resp_in.gaf;
        mem_addr_ready <= 1'b1;
      end

      if (sent_to_pmp) begin
        access_fault_r <= pmp_resp_ld || pmp_resp_mmio;
        if (!mem_addr_ready) begin
          sent_mem_req <= 1'b0;
          sent_pmp_check <= 1'b1;
        end
      end

      if (access_fault_r && !idle) begin
        sent_pmp_check <= 1'b1;
        sent_mem_req <= 1'b1;
        sent_llptw_req <= 1'b1;
        wait_mem_resp <= 1'b1;
        sent_hptw_req <= 1'b1;
        wait_hptw_resp <= 1'b1;
        sent_last_hptw_req <= 1'b1;
        wait_last_hptw_resp <= 1'b1;
        mem_addr_ready <= 1'b1;
        need_last_s2xlate <= 1'b0;
      end

      if (guest_fault && !idle) begin
        sent_pmp_check <= 1'b1;
        sent_mem_req <= 1'b1;
        sent_llptw_req <= 1'b1;
        wait_mem_resp <= 1'b1;
        sent_hptw_req <= 1'b1;
        wait_hptw_resp <= 1'b1;
        sent_last_hptw_req <= 1'b1;
        wait_last_hptw_resp <= 1'b1;
        mem_addr_ready <= 1'b1;
        need_last_s2xlate <= 1'b0;
      end

      if (mem_req_fire) begin
        sent_mem_req <= 1'b1;
        wait_mem_resp <= 1'b0;
      end
      if (mem_resp_valid && !wait_mem_resp) begin
        wait_mem_resp <= 1'b1;
        af_level <= af_level - 2'h1;
        gpf_level <= (satp_mode == 4'h8 && !pte_valid && !l2_hit_r) ? (gpf_level - 2'h2)
                                                                    : (gpf_level - 2'h1);
        pte_valid <= 1'b1;
        update_full_gvpn_from_mem <= 1'b1;
        sent_llptw_req <= 1'b0;
        mem_addr_ready <= 1'b1;
      end
      if (update_full_gvpn_from_mem) begin
        update_full_gvpn_from_mem <= 1'b0;
      end

      if (mem_addr_ready) begin
        if (descend_next_level) begin
          level <= level - 2'h1;
          if (need_g_stage_for_mem)
            sent_hptw_req <= 1'b0;
          else
            sent_mem_req <= 1'b0;
          sent_llptw_req <= 1'b1;
          mem_addr_ready <= 1'b0;
        end else if (llptw_valid) begin
          if (llptw_fire) begin
            idle <= 1'b1;
            sent_llptw_req <= 1'b1;
            mem_addr_ready <= 1'b0;
            need_last_s2xlate <= 1'b0;
          end
        end else if (need_g_stage_for_mem && need_last_s2xlate) begin
          need_last_s2xlate <= 1'b0;
          if (!(guest_fault || access_fault_r || pte_pf || ppn_af)) begin
            sent_last_hptw_req <= 1'b0;
            mem_addr_ready <= 1'b0;
          end
        end else if (resp_valid) begin
          if (resp_fire) begin
            idle <= 1'b1;
            sent_llptw_req <= 1'b1;
            mem_addr_ready <= 1'b0;
            access_fault_r <= 1'b0;
            first_gvpn_check_fail <= 1'b0;
          end
        end
      end

      if (flush) begin
        idle <= 1'b1;
        sent_pmp_check <= 1'b1;
        sent_mem_req <= 1'b1;
        sent_llptw_req <= 1'b1;
        wait_mem_resp <= 1'b1;
        access_fault_r <= 1'b0;
        mem_addr_ready <= 1'b0;
        first_gvpn_check_fail <= 1'b0;
        sent_hptw_req <= 1'b1;
        wait_hptw_resp <= 1'b1;
        sent_last_hptw_req <= 1'b1;
        wait_last_hptw_resp <= 1'b1;
      end

      // perf[5] 事件累积器(golden perfEvents_5_2, 带复位): mem 请求在途。
      perf_event_s1_5 <= mem_req_fire || (perf_event_s1_5 && !mem_resp_valid);
    end
  end

  // ---------------------------------------------------------------------------
  // 无复位 payload 寄存器(golden 873-1089 行 always @(posedge clock) 块):
  // 写使能条件与上面复位块中的控制流保持一致, 只是这些寄存器 golden 不复位。
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (req_fire) begin
      req_s2xlate <= req_info.s2xlate;
      source_r <= req_info.source;
      stage1_hit_r <= req_stage1_hit;
      stage1_r <= req_stage1;
    end

    if (req_fire && req_stage1_hit) begin
      hptw_resp_stage2 <= 1'b0;
      full_gvpn_r <= merge_resp_gen_ppn(req_stage1);
    end

    if (req_fire && !req_stage1_hit) begin
      vpn <= req_info.vpn;
      l2_hit_r <= req_l2_hit;
      l3_hit_r <= (satp_mode == 4'h9) && req_l3_hit;
      if (satp_mode == 4'h9)
        root_or_cache_ppn <= (req_l2_hit || req_l3_hit) ? req_ppn : satp_ppn;
      else
        root_or_cache_ppn <= req_l2_hit ? req_ppn : satp_ppn;
      if (req_info.s2xlate == ONLY_STAGE2)
        full_gvpn_r <= {6'h0, req_info.vpn};
      else
        full_gvpn_r <= '0;
    end

    if (hptw_resp_valid && !wait_hptw_resp) begin
      hptw_resp_r <= hptw_resp_in;
      hptw_resp_r.gpf <= hptw_resp_in.gpf || hptw_perm_fail;
    end
    if (hptw_resp_valid && !wait_last_hptw_resp && stage1_hit_r) begin
      hptw_resp_stage2 <= 1'b1;
      hptw_resp_r <= hptw_resp_in;
    end
    if (hptw_resp_valid && !wait_last_hptw_resp && !stage1_hit_r) begin
      hptw_resp_r <= hptw_resp_in;
    end

    if (update_full_gvpn_from_mem) begin
      full_gvpn_r <= pte_full_ppn;
    end

    // perf 输出是事件打一拍、再输出打一拍(XSPerfAccumulate 的 REG/REG_1, golden 无复位)。
    perf_event_s1[0] <= req_fire;
    perf_event_s1[1] <= !idle;
    perf_event_s1[2] <= idle;
    perf_event_s1[3] <= resp_valid && !resp_ready;
    perf_event_s1[4] <= mem_req_fire;
    perf_event_s1[6] <= mem_req_valid && !mem_req_ready;
    perf_event_s2 <= {perf_event_s1[6], perf_event_s1_5, perf_event_s1[4:0]};
    for (int i = 0; i < 7; i++) begin
      perf[i] <= {5'h0, (i == 5) ? perf_event_s2[i] : perf_event_s1[i]};
    end
  end

endmodule
