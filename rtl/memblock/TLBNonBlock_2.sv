// =============================================================================
// xs_TLBNonBlock_2_core —— 非阻塞 DTLB 变体 2（预取/walker 侧, Width=2/dup=1）可读重写
//
// 对应 Chisel: xiangshan.cache.mmu.TLB.scala class TLB（Block=false）
//   端口不对称：port0 完整 load 端口(preflight/REG+REG_1/全 requestor 输入)，
//   port1 裸端口(无 preflight/无 REG, 仅 cmd/kill/no_translate/vaddr)。
//   输出精简：{valid, paddr_0, pbmt_0, miss, pf_ld, af_ld, gpf_ld}。见 tlbnonblock2_pkg.sv。
//
// 说明：共享 s1 逻辑(命中/perm/paddr/PTW/need_gpa)用 genvar 铺 2 端口；port0-only 的
//   preflight(prepf/pregpf/preaf)+REG 打拍在 gi==0 分支；port1 的 preflight/REG 恒 0。
// =============================================================================
module xs_TLBNonBlock_2_core
  import xs_tlbnb2_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  input  logic                io_sfd_valid,
  input  logic [3:0]          io_csrd_satp_mode,
  input  logic [15:0]         io_csrd_satp_asid,
  input  logic                io_csrd_satp_changed,
  input  logic [3:0]          io_csrd_vsatp_mode,
  input  logic [15:0]         io_csrd_vsatp_asid,
  input  logic                io_csrd_vsatp_changed,
  input  logic [3:0]          io_csrd_hgatp_mode,
  input  logic [15:0]         io_csrd_hgatp_vmid,
  input  logic                io_csrd_hgatp_changed,
  input  logic                io_csrd_priv_mxr,
  input  logic                io_csrd_priv_sum,
  input  logic                io_csrd_priv_vmxr,
  input  logic                io_csrd_priv_vsum,
  input  logic                io_csrd_priv_virt,
  input  logic                io_csrd_priv_spvp,
  input  logic [1:0]          io_csrd_priv_imode,
  input  logic [1:0]          io_csrd_priv_dmode,
  input  logic [1:0]          io_csrd_pmm_mseccfg,
  input  logic [1:0]          io_csrd_pmm_menvcfg,
  input  logic [1:0]          io_csrd_pmm_henvcfg,
  input  logic [1:0]          io_csrd_pmm_hstatus,
  input  logic [1:0]          io_csrd_pmm_senvcfg,

  // ---- port0 完整 requestor ----
  input  logic                io_req0_valid,
  input  logic [VADDR_W-1:0]  io_req0_vaddr,
  input  logic [63:0]         io_req0_fullva,
  input  logic                io_req0_checkfullva,
  input  logic [2:0]          io_req0_cmd,
  input  logic                io_req0_hyperinst,
  input  logic                io_req0_hlvx,
  input  logic                io_req0_kill,
  input  logic                io_req0_isPrefetch,
  input  logic                io_req0_no_translate,
  input  logic [47:0]         io_req0_pmp_addr,
  input  logic                io_req0_robIdx_flag,
  input  logic [ROB_W-1:0]    io_req0_robIdx_value,
  // ---- port1 裸 requestor ----
  input  logic                io_req1_valid,
  input  logic [VADDR_W-1:0]  io_req1_vaddr,
  input  logic [2:0]          io_req1_cmd,
  input  logic                io_req1_kill,
  input  logic                io_req1_no_translate,

  input  logic                io_redirect_valid,
  input  logic                io_redirect_robIdx_flag,
  input  logic [ROB_W-1:0]    io_redirect_robIdx_value,
  input  logic                io_redirect_level,

  input  logic [WIDTH-1:0]              io_entries_hit,
  input  logic [WIDTH-1:0][PPN_W-1:0]  io_entries_ppn_0,
  input  logic [WIDTH-1:0][1:0]        io_entries_pbmt,
  input  logic [WIDTH-1:0][1:0]        io_entries_g_pbmt,
  input  tlb_perm_t [WIDTH-1:0]        io_entries_perm0,
  input  tlb_gperm_t [WIDTH-1:0]       io_entries_gperm0,

  output logic [WIDTH-1:0]             io_entries_rreq_valid,
  output logic [WIDTH-1:0][VPN_W-1:0]  io_entries_rreq_vpn,
  output logic [WIDTH-1:0][1:0]        io_entries_rreq_s2xlate,

  input  logic                io_ptw_resp_valid,
  input  logic [1:0]          io_ptw_resp_s2xlate,
  input  logic [34:0]         io_ptw_resp_s1_entry_tag,
  input  logic [15:0]         io_ptw_resp_s1_entry_asid,
  input  logic [13:0]         io_ptw_resp_s1_entry_vmid,
  input  logic                io_ptw_resp_s1_entry_n,
  input  logic [1:0]          io_ptw_resp_s1_entry_pbmt,
  input  logic                io_ptw_resp_s1_entry_perm_d,
  input  logic                io_ptw_resp_s1_entry_perm_a,
  input  logic                io_ptw_resp_s1_entry_perm_g,
  input  logic                io_ptw_resp_s1_entry_perm_u,
  input  logic                io_ptw_resp_s1_entry_perm_x,
  input  logic                io_ptw_resp_s1_entry_perm_w,
  input  logic                io_ptw_resp_s1_entry_perm_r,
  input  logic [1:0]          io_ptw_resp_s1_entry_level,
  input  logic                io_ptw_resp_s1_entry_v,
  input  logic [40:0]         io_ptw_resp_s1_entry_ppn,
  input  logic [2:0]          io_ptw_resp_s1_addr_low,
  input  logic [2:0]          io_ptw_resp_s1_ppn_low [0:7],
  input  logic [7:0]          io_ptw_resp_s1_valididx,
  input  logic [7:0]          io_ptw_resp_s1_pteidx,
  input  logic                io_ptw_resp_s1_pf,
  input  logic                io_ptw_resp_s1_af,
  input  logic [37:0]         io_ptw_resp_s2_entry_tag,
  input  logic [13:0]         io_ptw_resp_s2_entry_vmid,
  input  logic                io_ptw_resp_s2_entry_n,
  input  logic [1:0]          io_ptw_resp_s2_entry_pbmt,
  input  logic [37:0]         io_ptw_resp_s2_entry_ppn,
  input  logic                io_ptw_resp_s2_entry_perm_d,
  input  logic                io_ptw_resp_s2_entry_perm_a,
  input  logic                io_ptw_resp_s2_entry_perm_g,
  input  logic                io_ptw_resp_s2_entry_perm_u,
  input  logic                io_ptw_resp_s2_entry_perm_x,
  input  logic                io_ptw_resp_s2_entry_perm_w,
  input  logic                io_ptw_resp_s2_entry_perm_r,
  input  logic [1:0]          io_ptw_resp_s2_entry_level,
  input  logic                io_ptw_resp_s2_gpf,
  input  logic                io_ptw_resp_s2_gaf,
  input  logic                io_ptw_resp_getGpa,

  output logic                io_refill_valid,

  // ---- resp 输出（精简，2 端口）----
  output logic [WIDTH-1:0]             io_resp_valid,
  output logic [WIDTH-1:0][PADDR_W-1:0] io_resp_paddr0,
  output logic [WIDTH-1:0][1:0]        io_resp_pbmt0,
  output logic [WIDTH-1:0]             io_resp_miss,
  output logic [WIDTH-1:0]             io_resp_excp_gpf_ld,
  output logic [WIDTH-1:0]             io_resp_excp_pf_ld,
  output logic [WIDTH-1:0]             io_resp_excp_af_ld,

  output logic [WIDTH-1:0]             io_pmp_valid,
  output logic [WIDTH-1:0][47:0]       io_pmp_addr,
  output logic [WIDTH-1:0][2:0]        io_pmp_cmd,

  output logic [WIDTH-1:0]             io_ptw_req_valid,
  output logic [WIDTH-1:0][VPN_W-1:0]  io_ptw_req_vpn,
  output logic [WIDTH-1:0][1:0]        io_ptw_req_s2xlate,
  output logic [WIDTH-1:0]             io_ptw_req_getGpa,
  output logic [WIDTH-1:0]             io_tlbreplay
);

  genvar gi;

  wire Sv39Enable   = io_csrd_satp_mode  == 4'h8;
  wire Sv48Enable   = io_csrd_satp_mode  == 4'h9;
  wire Sv39vsEnable = io_csrd_vsatp_mode == 4'h8;
  wire Sv48vsEnable = io_csrd_vsatp_mode == 4'h9;
  wire Sv39x4Enable = io_csrd_hgatp_mode == 4'h8;
  wire Sv48x4Enable = io_csrd_hgatp_mode == 4'h9;
  wire vsatp_on = |io_csrd_vsatp_mode;
  wire hgatp_on = |io_csrd_hgatp_mode;
  wire flush_mmu = io_sfd_valid || io_csrd_satp_changed
                || io_csrd_vsatp_changed || io_csrd_hgatp_changed;

  // ---- 端口输入打包（port1 缺失字段用默认: hlvx/isPrefetch/hyperinst/checkfullva=0,
  //      fullva/pmp_addr=0, robIdx=0）----
  logic [WIDTH-1:0]               io_req_valid;
  logic [WIDTH-1:0][VADDR_W-1:0]  io_req_vaddr;
  logic [WIDTH-1:0][63:0]         io_req_fullva;
  logic [WIDTH-1:0]               io_req_checkfullva;
  logic [WIDTH-1:0][2:0]          io_req_cmd;
  logic [WIDTH-1:0]               io_req_hyperinst;
  logic [WIDTH-1:0]               io_req_hlvx;
  logic [WIDTH-1:0]               io_req_kill;
  logic [WIDTH-1:0]               io_req_isPrefetch;
  logic [WIDTH-1:0]               io_req_no_translate;
  logic [WIDTH-1:0][47:0]         io_req_pmp_addr;
  logic [WIDTH-1:0]               io_req_robIdx_flag;
  logic [WIDTH-1:0][ROB_W-1:0]    io_req_robIdx_value;
  assign io_req_valid       = {io_req1_valid, io_req0_valid};
  assign io_req_vaddr       = {io_req1_vaddr, io_req0_vaddr};
  assign io_req_fullva      = {64'h0, io_req0_fullva};
  assign io_req_checkfullva = {1'b0, io_req0_checkfullva};
  assign io_req_cmd         = {io_req1_cmd, io_req0_cmd};
  assign io_req_hyperinst   = {1'b0, io_req0_hyperinst};
  assign io_req_hlvx        = {1'b0, io_req0_hlvx};
  assign io_req_kill        = {io_req1_kill, io_req0_kill};
  assign io_req_isPrefetch  = {1'b0, io_req0_isPrefetch};
  assign io_req_no_translate= {io_req1_no_translate, io_req0_no_translate};
  assign io_req_pmp_addr    = {48'h0, io_req0_pmp_addr};
  assign io_req_robIdx_flag = {1'b0, io_req0_robIdx_flag};
  assign io_req_robIdx_value= {8'h0, io_req0_robIdx_value};

  // ---- s1 请求寄存 ----
  logic [WIDTH-1:0]               req_out_v;
  logic [WIDTH-1:0][VADDR_W-1:0]  req_out_vaddr;
  logic [WIDTH-1:0][2:0]          req_out_cmd;
  // port1 无 hyperinst/hlvx/isPrefetch/robIdx 输入(恒 0)→ 只寄存 port0(标量), port1 组合常量 0。
  logic                          req_out0_hyperinst, req_out0_hlvx, req_out0_isPrefetch, req_out0_robIdx_flag;
  logic [ROB_W-1:0]              req_out0_robIdx_value;
  wire  [WIDTH-1:0]              req_out_hyperinst  = {1'b0, req_out0_hyperinst};
  wire  [WIDTH-1:0]              req_out_hlvx       = {1'b0, req_out0_hlvx};
  wire  [WIDTH-1:0]              req_out_isPrefetch = {1'b0, req_out0_isPrefetch};
  wire  [WIDTH-1:0]             req_out_robIdx_flag = {1'b0, req_out0_robIdx_flag};
  wire  [WIDTH-1:0][ROB_W-1:0]  req_out_robIdx_value= {{ROB_W{1'b0}}, req_out0_robIdx_value};
  logic [WIDTH-1:0]               virt_out;
  logic [WIDTH-1:0]               porttr_r;
  logic [WIDTH-1:0]               noTransReg;

  // ---- s0 预检（仅 port0 有效；port1 恒 0）----
  logic [WIDTH-1:0][63:0] EffectiveVa;
  logic [WIDTH-1:0]       prepf, pregpf, preaf;
  logic [WIDTH-1:0][1:0]  req_in_s2xlate;

  for (gi = 0; gi < WIDTH; gi++) begin : g_s0
    wire        hyper_in = io_req_hyperinst[gi];
    wire        virt_or_hyper_in = io_csrd_priv_virt | hyper_in;
    wire [1:0]  premode = hyper_in ? {1'b0, io_csrd_priv_spvp} : io_csrd_priv_dmode;
    wire        prevmEnable = ~virt_or_hyper_in & (Sv39Enable|Sv48Enable) & (premode != 2'h3);
    wire        pres2xlEnable = virt_or_hyper_in
                  & (Sv39vsEnable|Sv48vsEnable|Sv39x4Enable|Sv48x4Enable) & (premode != 2'h3);
    assign req_in_s2xlate[gi] = calc_s2xlate(virt_or_hyper_in, vsatp_on, hgatp_on);
    wire [1:0] pmm =
        io_req_hlvx[gi]        ? 2'h0 :
        (&premode)             ? io_csrd_pmm_mseccfg :
        (~virt_or_hyper_in & (premode==2'h1)) ? io_csrd_pmm_menvcfg :
        ( virt_or_hyper_in & (premode==2'h1)) ? io_csrd_pmm_henvcfg :
        (hyper_in & (io_csrd_priv_imode==2'h0)) ? io_csrd_pmm_hstatus :
        (premode==2'h0)        ? io_csrd_pmm_senvcfg : 2'h0;
    wire pmm7  = (pmm == 2'h2);
    wire pmm16 = (&pmm);
    wire [63:0] fv = io_req_fullva[gi];
    assign EffectiveVa[gi] =
        (prevmEnable | (pres2xlEnable & vsatp_on))
          ? (pmm7  ? {{7{fv[56]}}, fv[56:0]} : pmm16 ? {{16{fv[47]}}, fv[47:0]} : fv)
          : (pmm7  ? {7'h0, fv[56:0]} : pmm16 ? {16'h0, fv[47:0]} : fv);
    wire [63:0] ev = EffectiveVa[gi];
    wire pf48  = {{16{ev[47]}}, ev[47:0]} != ev;
    wire pf39  = {{25{ev[38]}}, ev[38:0]} != ev;
    wire gpf48 = |ev[63:50];
    wire gpf39 = |ev[63:41];
    wire af_hi = |ev[63:48];
    wire chk = io_req_valid[gi] & io_req_checkfullva[gi];   // port1 checkfullva=0 → chk=0
    wire onlyS2_in = req_in_s2xlate[gi] == ONLY_STAGE2;
    assign pregpf[gi] = chk & (prevmEnable|pres2xlEnable) & onlyS2_in
                          & (Sv48x4Enable ? gpf48 : (Sv39x4Enable & gpf39));
    assign prepf[gi]  = chk & (prevmEnable|pres2xlEnable) & ~onlyS2_in
                          & ((req_in_s2xlate[gi]==ONLY_STAGE1) | (&req_in_s2xlate[gi])
                               ? (Sv48vsEnable ? pf48 : (Sv39vsEnable & pf39))
                               : (Sv48Enable   ? pf48 : (Sv39Enable   & pf39)));
    assign preaf[gi]  = chk & ~(prevmEnable|pres2xlEnable) & af_hi;
    assign io_entries_rreq_valid[gi]   = io_req_valid[gi];
    assign io_entries_rreq_vpn[gi]     = io_req_vaddr[gi][VADDR_W-1:12];
    assign io_entries_rreq_s2xlate[gi] = req_in_s2xlate[gi];
  end

  // ---- 跨拍共享状态 ----
  logic                need_gpa, need_gpa_wire;
  logic                need_gpa_robidx_flag;
  logic [ROB_W-1:0]    need_gpa_robidx_value;
  logic [VPN_W-1:0]    need_gpa_vpn;
  logic                resp_gpa_refill;
  // 注: _2 无 gpaddr 输出 → resp_gpa_gvpn/resp_s1_level/isLeaf/isFakePte/p_s2xlate 死状态, 不建。

  logic [WIDTH-1:0]                lcr_valid, lcr_robIdx_flag, lcr_level;
  logic [WIDTH-1:0][ROB_W-1:0]     lcr_robIdx_value;

  logic [WIDTH-1:0]              p_hit;
  logic [WIDTH-1:0][PPN_W-1:0]  p_ppn;
  logic [WIDTH-1:0][1:0]        p_pbmt;
  tlb_perm_t [WIDTH-1:0]        p_perm;
  logic [WIDTH-1:0][1:0]        p_g_pbmt;
  tlb_gperm_t [WIDTH-1:0]       p_g_perm;

  logic [WIDTH-1:0][1:0]        pr_s2xlate;
  logic [WIDTH-1:0][34:0]       pr_s1_tag;
  logic [WIDTH-1:0][15:0]       pr_s1_asid;
  logic [WIDTH-1:0][13:0]       pr_s1_vmid;
  logic [WIDTH-1:0]             pr_s1_n, pr_s1_perm_g;
  logic [WIDTH-1:0][1:0]        pr_s1_level;
  logic [WIDTH-1:0][2:0]        pr_s1_addr_low;
  logic [WIDTH-1:0][7:0]        pr_s1_valididx;
  logic [WIDTH-1:0][37:0]       pr_s2_tag;
  logic [WIDTH-1:0][13:0]       pr_s2_vmid;
  logic [WIDTH-1:0]             pr_s2_n;
  logic [WIDTH-1:0][1:0]        pr_s2_level;
  logic [WIDTH-1:0]             ptw_already_back_last;

  // ---- 命中纯函数 ----
  function automatic logic s1_entry_hit(
    input logic [34:0] tag, input logic n, input logic [1:0] level,
    input logic [49:0] vaddr, input logic [7:0] valididx);
    logic m3, m2, m1, lvlmatch;
    m1 = tag[14:6]  == vaddr[29:21]; m2 = tag[23:15] == vaddr[38:30]; m3 = tag[34:24] == vaddr[49:39];
    if (level == 2'h0)
      lvlmatch = (m3 & m2) & m1 & (n ? (tag[5:1] == vaddr[20:16]) : (tag[5:0] == vaddr[20:15]));
    else if (level == 2'h1) lvlmatch = (m3 & m2) & m1;
    else                    lvlmatch = ((level != 2'h2) | m2) & m3;
    return lvlmatch & ((|level) | n | valididx[vaddr[14:12]]);
  endfunction
  function automatic logic s2_entry_hit(
    input logic [37:0] tag, input logic n, input logic [1:0] level, input logic [49:0] vaddr);
    logic m3, m2, m1;
    m1 = tag[17:9]  == vaddr[29:21]; m2 = tag[26:18] == vaddr[38:30]; m3 = tag[37:27] == vaddr[49:39];
    if (level == 2'h0)
      return (m3 & m2) & m1 & (n ? (tag[8:4]==vaddr[20:16]) : (tag[8:0]==vaddr[20:12]));
    else if (level == 2'h1) return (m3 & m2) & m1;
    else                    return ((level != 2'h2) | m2) & m3;
  endfunction
  function automatic logic all_hit_full(
    input logic [34:0] tag, input logic s1_n, input logic [1:0] s1_level,
    input logic [2:0] addr_low, input logic s2_n, input logic [1:0] s2_level,
    input logic s2xlate_onlyS1, input logic [49:0] vaddr);
    logic m3, m2, m1; logic [1:0] lvl; logic nsel;
    m1 = vaddr[29:21] == tag[14:6]; m2 = vaddr[38:30] == tag[23:15]; m3 = vaddr[49:39] == tag[34:24];
    lvl  = (s2xlate_onlyS1 | (s1_level < s2_level)) ? s1_level : s2_level;
    nsel = s2xlate_onlyS1 ? s1_n : (s1_n & (|s2_level)) | (s2_n & (|s1_level)) | (s1_n & s2_n);
    if (lvl == 2'h0)
      return (m3 & m2) & m1 & (nsel ? (vaddr[20:16]==tag[5:1]) : (vaddr[20:12]=={tag[5:0],addr_low}));
    else if (lvl == 2'h1) return (m3 & m2) & m1;
    else                  return ((lvl != 2'h2) | m2) & m3;
  endfunction

  // ---- s1 逐端口 ----
  logic [WIDTH-1:0] hit_read, miss_read, hasGpf, porttr, isHyperInst;
  logic [WIDTH-1:0][1:0] req_out_s2xlate;
  // port0-only preflight 打拍（REG=REG_1）；port1 恒 0。
  logic             REG_pre0, REG_pre0_1;
  logic             excp_pf_ld_REG0, excp_gpf_ld_REG0, excp_gpf_st_REG0, excp_af_ld_REG0;
  wire [WIDTH-1:0]  REG_pre  = {1'b0, REG_pre0};      // port1 无 REG
  wire [WIDTH-1:0]  REG_pre2 = {1'b0, REG_pre0_1};

  wire [1:0] ptw_level = (|io_ptw_resp_s2xlate)
      ? ((&io_ptw_resp_s2xlate)
           ? (io_ptw_resp_s1_entry_level < io_ptw_resp_s2_entry_level
                ? io_ptw_resp_s1_entry_level : io_ptw_resp_s2_entry_level)
           : (io_ptw_resp_s2xlate==ONLY_STAGE2 ? io_ptw_resp_s2_entry_level
                                               : io_ptw_resp_s1_entry_level))
      : io_ptw_resp_s1_entry_level;
  wire [2:0] ptw_pteidx_or = io_ptw_resp_s1_pteidx[7:5] | io_ptw_resp_s1_pteidx[3:1];
  logic [VPN_W-1:0] ptw_getvpn_w;
  always_comb begin
    logic [VPN_W-1:0] s1v [0:3]; logic [VPN_W-1:0] s2v [0:3];
    s1v[0] = {io_ptw_resp_s1_entry_tag, |io_ptw_resp_s1_pteidx[7:4],
              |ptw_pteidx_or[2:1], ptw_pteidx_or[2]|ptw_pteidx_or[0]};
    s1v[1] = {io_ptw_resp_s1_entry_tag[34:6],  need_gpa_vpn[8:0]};
    s1v[2] = {io_ptw_resp_s1_entry_tag[34:15], need_gpa_vpn[17:0]};
    s1v[3] = {io_ptw_resp_s1_entry_tag[34:24], need_gpa_vpn[26:0]};
    s2v[0] = io_ptw_resp_s2_entry_tag;
    s2v[1] = {io_ptw_resp_s2_entry_tag[37:9],  need_gpa_vpn[8:0]};
    s2v[2] = {io_ptw_resp_s2_entry_tag[37:18], need_gpa_vpn[17:0]};
    s2v[3] = {io_ptw_resp_s2_entry_tag[37:27], need_gpa_vpn[26:0]};
    ptw_getvpn_w = (io_ptw_resp_s2xlate==ONLY_STAGE2) ? s2v[ptw_level] : s1v[ptw_level];
  end

  logic [WIDTH-1:0] rr_T_redirect, rr_T_enter, rr_T_ptwhit;

  for (gi = 0; gi < WIDTH; gi++) begin : g_s1
    wire [VADDR_W-1:0] vaddr = req_out_vaddr[gi];
    wire [2:0]  cmd  = req_out_cmd[gi];
    wire        virt_or_hyper = virt_out[gi] | (req_out_v[gi] & req_out_hyperinst[gi]);
    assign isHyperInst[gi] = req_out_v[gi] & req_out_hyperinst[gi];
    wire [1:0]  mode = isHyperInst[gi] ? {1'b0, io_csrd_priv_spvp} : io_csrd_priv_dmode;
    assign req_out_s2xlate[gi] = calc_s2xlate(virt_or_hyper, vsatp_on, hgatp_on);
    wire        onlyS2 = req_out_s2xlate[gi] == ONLY_STAGE2;
    wire        s2both = onlyS2 | (&req_out_s2xlate[gi]);
    wire vmE = ~virt_or_hyper & (Sv39Enable|Sv48Enable) & (mode != 2'h3);
    wire s2E =  virt_or_hyper & (Sv39vsEnable|Sv48vsEnable|Sv39x4Enable|Sv48x4Enable) & (mode != 2'h3);
    assign porttr[gi] = (vmE | s2E) & porttr_r[gi];

    tlb_perm_t  perm0; tlb_gperm_t gperm0;
    logic [PPN_W-1:0] ppn0; logic [1:0] pbmt_d, gpbmt_d;
    assign perm0  = p_hit[gi] ? p_perm[gi] : io_entries_perm0[gi];
    assign gperm0 = p_hit[gi] ? p_g_perm[gi] : io_entries_gperm0[gi];
    assign ppn0   = p_hit[gi] ? p_ppn[gi] : io_entries_ppn_0[gi];
    assign pbmt_d = p_hit[gi] ? p_pbmt[gi] : io_entries_pbmt[gi];
    assign gpbmt_d= p_hit[gi] ? p_g_pbmt[gi] : io_entries_g_pbmt[gi];

    wire need_gpa_vpn_hit = need_gpa_vpn == vaddr[VADDR_W-1:12];
    assign hit_read[gi] = io_entries_hit[gi] | p_hit[gi];
    wire lcr_hit = lcr_valid[gi]
        & ( (lcr_level[gi] & ({req_out_robIdx_flag[gi],req_out_robIdx_value[gi]}
                            == {lcr_robIdx_flag[gi], lcr_robIdx_value[gi]}))
            | (req_out_robIdx_flag[gi]^lcr_robIdx_flag[gi]
               ^ (req_out_robIdx_value[gi] > lcr_robIdx_value[gi])) );
    assign miss_read[gi] = (~hit_read[gi] & porttr[gi])
        | (hasGpf[gi] & ~p_hit[gi] & ~(resp_gpa_refill & need_gpa_vpn_hit)
           & ~onlyS2 & ~req_out_isPrefetch[gi] & ~lcr_hit);

    wire isLd   = cmd_is_ld(cmd);
    wire isSt   = cmd_is_st(cmd);
    wire isInst = cmd_is_inst(cmd);
    wire af = (~onlyS2 & perm0.af) | (s2both & gperm0.af);
    wire modeFail = (mode==2'h0 & ~perm0.u)
                  | (mode==2'h1 & perm0.u & ~(virt_or_hyper ? io_csrd_priv_vsum : io_csrd_priv_sum));
    wire hlvx = req_out_hlvx[gi];
    wire ldPermFail = ~(~modeFail & (hlvx ? perm0.x
                          : (perm0.r | ((virt_or_hyper & io_csrd_priv_vmxr | io_csrd_priv_mxr) & perm0.x))));
    wire stPermFail = ~(~modeFail & perm0.w);
    wire inPermFail = ~(~modeFail & perm0.x);
    wire ldPf = (ldPermFail | perm0.pf) & isLd;
    wire stPf = (stPermFail | perm0.pf) & isSt;
    wire inPf = (inPermFail | perm0.pf) & isInst;
    wire ldUpd = ~perm0.a & isLd;
    wire stUpd = (~perm0.a | ~perm0.d) & isSt;
    wire inUpd = ~perm0.a & isInst;
    wire isFakePte = ~perm0.v & ~perm0.pf & ~perm0.af & ~onlyS2;
    wire isNonLeaf = ~(perm0.r|perm0.w|perm0.x) & perm0.v & ~perm0.pf & ~perm0.af;
    wire s1_valid = porttr[gi] & ~onlyS2;
    wire s2_valid = porttr[gi] & s2both;
    wire fault_valid = s1_valid | s2_valid;
    wire g_ldPermFail = ~(hlvx ? gperm0.x : (gperm0.r | (io_csrd_priv_mxr & gperm0.x)));
    wire g_stPermFail = ~gperm0.w;
    wire ldGpf = (g_ldPermFail | gperm0.pf) & isLd;
    wire stGpf = (g_stPermFail | gperm0.pf) & isSt;
    wire g_ldUpd = ~gperm0.a & isLd;
    wire g_stUpd = (~gperm0.a | ~gperm0.d) & isSt;
    wire hasPf = (ldPf|ldUpd|stPf|stUpd|inPf|inUpd) & s1_valid & ~af & ~isFakePte & ~isNonLeaf;

    wire pf_ld_dyn = (ldPf|ldUpd) & s1_valid & ~af & ~isFakePte & ~isNonLeaf;
    wire gpf_ld_dyn= (ldGpf|g_ldUpd) & s2_valid & ~af & ~hasPf;
    wire gpf_st_dyn= (stGpf|g_stUpd) & s2_valid & ~af & ~hasPf;

    // 输出仅 pf_ld/af_ld/gpf_ld；port0 用 REG_pre 门控，port1 纯 dynamic
    assign io_resp_excp_pf_ld[gi] = REG_pre[gi] ? (excp_pf_ld_REG0 & isLd) : pf_ld_dyn;
    wire gpf_ld_o = REG_pre[gi] ? (excp_gpf_ld_REG0 & isLd) : gpf_ld_dyn;
    wire gpf_st_o = REG_pre[gi] ? (excp_gpf_st_REG0 & isSt) : gpf_st_dyn;
    assign io_resp_excp_gpf_ld[gi] = gpf_ld_o;
    assign io_resp_excp_af_ld[gi] = REG_pre[gi]
        ? (excp_af_ld_REG0 & cmd_is_read(cmd)) : (af & cmd_is_read(cmd) & fault_valid);

    assign hasGpf[gi] = hit_read[gi] & ( gpf_ld_o | gpf_st_o
        | (~REG_pre[gi] & ((~gperm0.x|gperm0.pf)&isInst | ~gperm0.a&isInst) & s2_valid & ~af & ~hasPf) );

    assign io_resp_paddr0[gi] = porttr[gi] ? {ppn0, vaddr[11:0]} : vaddr[47:0];
    wire [1:0] pbmt_res = (req_out_s2xlate[gi]==ALL_STAGE) ? ((|pbmt_d) ? pbmt_d : gpbmt_d)
                        : (req_out_s2xlate[gi]==ONLY_STAGE2) ? gpbmt_d : pbmt_d;
    assign io_resp_pbmt0[gi] = porttr[gi] ? pbmt_res : 2'h0;
    assign io_resp_miss[gi]   = ~(REG_pre2[gi] | REG_pre[gi]) & miss_read[gi];
    assign io_resp_valid[gi]  = req_out_v[gi];

    // PMP（port0 有 no_translate/pmp_addr; port1 no_translate 有, pmp_addr=0）
    assign io_pmp_valid[gi] = req_out_v[gi] | noTransReg[gi];
    assign io_pmp_addr[gi]  = noTransReg[gi] ? io_req_pmp_addr[gi] : io_resp_paddr0[gi];
    assign io_pmp_cmd[gi]   = cmd;

    wire [1:0] req_s2x = calc_s2xlate(virt_out[gi] | req_out_hyperinst[gi], vsatp_on, hgatp_on);
    wire pjb_s1 = s1_entry_hit(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                               io_ptw_resp_s1_entry_level, vaddr, io_ptw_resp_s1_valididx)
                & (io_ptw_resp_s1_entry_asid==io_csrd_satp_asid | io_ptw_resp_s1_entry_perm_g);
    wire pjb_s2 = s2_entry_hit(io_ptw_resp_s2_entry_tag, io_ptw_resp_s2_entry_n,
                               io_ptw_resp_s2_entry_level, vaddr)
                & ({2'h0,io_ptw_resp_s2_entry_vmid}==io_csrd_hgatp_vmid);
    wire pjb_all= all_hit_full(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                    io_ptw_resp_s1_entry_level, io_ptw_resp_s1_addr_low,
                    io_ptw_resp_s2_entry_n, io_ptw_resp_s2_entry_level,
                    io_ptw_resp_s2xlate==ONLY_STAGE1, vaddr)
                & ({2'h0,io_ptw_resp_s1_entry_vmid}==io_csrd_hgatp_vmid)
                & (io_ptw_resp_s1_entry_asid==io_csrd_vsatp_asid | io_ptw_resp_s1_entry_perm_g);
    wire ptw_just_back = io_ptw_resp_valid & (req_s2x==io_ptw_resp_s2xlate)
        & ((|io_ptw_resp_s2xlate) ? (io_ptw_resp_s2xlate==ONLY_STAGE2 ? pjb_s2 : pjb_all) : pjb_s1);
    wire pab_s1 = s1_entry_hit(pr_s1_tag[gi], pr_s1_n[gi], pr_s1_level[gi], vaddr, pr_s1_valididx[gi])
                & (pr_s1_asid[gi]==io_csrd_satp_asid | pr_s1_perm_g[gi]);
    wire pab_s2 = s2_entry_hit(pr_s2_tag[gi], pr_s2_n[gi], pr_s2_level[gi], vaddr)
                & ({2'h0,pr_s2_vmid[gi]}==io_csrd_hgatp_vmid);
    wire pab_all= all_hit_full(pr_s1_tag[gi], pr_s1_n[gi], pr_s1_level[gi], pr_s1_addr_low[gi],
                    pr_s2_n[gi], pr_s2_level[gi], pr_s2xlate[gi]==ONLY_STAGE1, vaddr)
                & ({2'h0,pr_s1_vmid[gi]}==io_csrd_hgatp_vmid)
                & (pr_s1_asid[gi]==io_csrd_vsatp_asid | pr_s1_perm_g[gi]);
    wire ptw_already_back = ptw_already_back_last[gi] & (req_s2x==pr_s2xlate[gi])
        & (pr_s2xlate[gi]==NO_S2XLATE ? pab_s1 : pr_s2xlate[gi]==ONLY_STAGE2 ? pab_s2 : pab_all);

    wire need_gpa_state_block = need_gpa & (need_gpa_vpn != vaddr[VADDR_W-1:12]) & ~resp_gpa_refill;
    wire miss_active = req_out_v[gi] & miss_read[gi];
    assign io_ptw_req_valid[gi]  = miss_active & ~ptw_just_back & ~ptw_already_back & ~need_gpa_state_block;
    assign io_ptw_req_vpn[gi]    = vaddr[VADDR_W-1:12];
    assign io_ptw_req_s2xlate[gi]= req_s2x;
    assign io_ptw_req_getGpa[gi] = hasGpf[gi] & hit_read[gi];
    assign io_tlbreplay[gi]      = miss_active & ((ptw_just_back|ptw_already_back)|need_gpa_state_block);

    wire isitlb = cmd[1:0] == 2'h2;
    assign rr_T_redirect[gi] = ~isitlb & io_redirect_valid
        & ( (io_redirect_level & ({need_gpa_robidx_flag,need_gpa_robidx_value}
                                   == {io_redirect_robIdx_flag,io_redirect_robIdx_value}))
          | ((need_gpa_robidx_flag^io_redirect_robIdx_flag)
             ^ (need_gpa_robidx_value > io_redirect_robIdx_value)) );
    wire cur_redirect = io_redirect_valid
        & ( (io_redirect_level & ({req_out_robIdx_flag[gi],req_out_robIdx_value[gi]}
                                   == {io_redirect_robIdx_flag,io_redirect_robIdx_value}))
          | (req_out_robIdx_flag[gi]^io_redirect_robIdx_flag
             ^ (req_out_robIdx_value[gi] > io_redirect_robIdx_value)) );
    assign rr_T_enter[gi] = req_out_v[gi] & ~p_hit[gi]
        & ~(resp_gpa_refill & need_gpa_vpn_hit) & ~onlyS2 & hasGpf[gi] & ~need_gpa
        & ~req_out_isPrefetch[gi] & ~cur_redirect & ~lcr_hit;
    assign rr_T_ptwhit[gi] = io_ptw_resp_valid & need_gpa & (need_gpa_vpn == ptw_getvpn_w);
  end

  assign need_gpa_wire = (~rr_T_redirect[1] & rr_T_enter[1]) | (~rr_T_redirect[0] & rr_T_enter[0]);
  assign io_refill_valid = io_ptw_resp_valid & ~io_ptw_resp_getGpa
                         & ~need_gpa & ~need_gpa_wire & ~flush_mmu;

  // ---- PTW 回填合成（p_ppn 用）----
  wire [7:0][2:0] ptw_ppn_low_tbl = {
      io_ptw_resp_s1_ppn_low[7], io_ptw_resp_s1_ppn_low[6],
      io_ptw_resp_s1_ppn_low[5], io_ptw_resp_s1_ppn_low[4],
      io_ptw_resp_s1_ppn_low[3], io_ptw_resp_s1_ppn_low[2],
      io_ptw_resp_s1_ppn_low[1], io_ptw_resp_s1_ppn_low[0]};
  function automatic logic [GVPN_W-1:0] gen_s1_ppn44(
    input logic [40:0] ppn, input logic n, input logic [1:0] level,
    input logic [2:0] napot_low, input logic [VPN_W-1:0] v);
    logic [GVPN_W-1:0] r [0:3];
    r[3] = {ppn[40:24], v[26:0]}; r[2] = {ppn[40:15], v[17:0]};
    r[1] = {ppn[40:6],  v[8:0]};  r[0] = n ? {ppn[40:1], v[3:0]} : {ppn, napot_low};
    return r[level];
  endfunction
  function automatic logic [37:0] gen_s2_ppn38(
    input logic [37:0] ppn, input logic n, input logic [1:0] level, input logic [26:0] gv);
    logic [37:0] r [0:3];
    r[3] = {ppn[37:27], gv}; r[2] = {ppn[37:18], gv[17:0]};
    r[1] = {ppn[37:9],  gv[8:0]}; r[0] = n ? {ppn[37:4], gv[3:0]} : ppn;
    return r[level];
  endfunction
  wire tlb_perm_t  ptw_perm  = '{pf:io_ptw_resp_s1_pf, af:io_ptw_resp_s1_af,
       v:io_ptw_resp_s1_entry_v, d:io_ptw_resp_s1_entry_perm_d, a:io_ptw_resp_s1_entry_perm_a,
       u:io_ptw_resp_s1_entry_perm_u, x:io_ptw_resp_s1_entry_perm_x,
       w:io_ptw_resp_s1_entry_perm_w, r:io_ptw_resp_s1_entry_perm_r};
  wire tlb_gperm_t ptw_gperm = '{pf:io_ptw_resp_s2_gpf, af:io_ptw_resp_s2_gaf,
       d:io_ptw_resp_s2_entry_perm_d, a:io_ptw_resp_s2_entry_perm_a,
       x:io_ptw_resp_s2_entry_perm_x, w:io_ptw_resp_s2_entry_perm_w, r:io_ptw_resp_s2_entry_perm_r};
  wire ptw_isLeaf = (io_ptw_resp_s1_entry_perm_r|io_ptw_resp_s1_entry_perm_x
                     |io_ptw_resp_s1_entry_perm_w) & io_ptw_resp_s1_entry_v;
  wire ptw_isFakePte = ~io_ptw_resp_s1_pf & ~io_ptw_resp_s1_entry_v & ~io_ptw_resp_s1_af;

  // ---- s0 PTW 旁路 ----
  logic [WIDTH-1:0]             p_hit_s0;
  logic [WIDTH-1:0][PPN_W-1:0]  p_ppn_s0;
  for (gi = 0; gi < WIDTH; gi++) begin : g_s0_bypass
    wire [VADDR_W-1:0] v = io_req_vaddr[gi];
    wire [1:0] s2x = req_in_s2xlate[gi];
    wire hit_s0 = (|io_ptw_resp_s2xlate)
        ? ((io_ptw_resp_s2xlate==ONLY_STAGE2)
             ? ( s2_entry_hit(io_ptw_resp_s2_entry_tag, io_ptw_resp_s2_entry_n,
                              io_ptw_resp_s2_entry_level, v)
                 & ({2'h0,io_ptw_resp_s2_entry_vmid}==io_csrd_hgatp_vmid) )
             : ( all_hit_full(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                              io_ptw_resp_s1_entry_level, io_ptw_resp_s1_addr_low,
                              io_ptw_resp_s2_entry_n, io_ptw_resp_s2_entry_level,
                              io_ptw_resp_s2xlate==ONLY_STAGE1, v)
                 & ({2'h0,io_ptw_resp_s1_entry_vmid}==io_csrd_hgatp_vmid)
                 & (io_ptw_resp_s1_entry_asid==io_csrd_vsatp_asid | io_ptw_resp_s1_entry_perm_g) ))
        : ( s1_entry_hit(io_ptw_resp_s1_entry_tag, io_ptw_resp_s1_entry_n,
                         io_ptw_resp_s1_entry_level, v, io_ptw_resp_s1_valididx)
            & (io_ptw_resp_s1_entry_asid==io_csrd_satp_asid | io_ptw_resp_s1_entry_perm_g) );
    assign p_hit_s0[gi] = hit_s0 & io_ptw_resp_valid & (s2x == io_ptw_resp_s2xlate);
    wire [GVPN_W-1:0] s1ppn = gen_s1_ppn44(io_ptw_resp_s1_entry_ppn, io_ptw_resp_s1_entry_n,
                                     io_ptw_resp_s1_entry_level, ptw_ppn_low_tbl[v[14:12]], v[VADDR_W-1:12]);
    wire [26:0] gvpn27 = (s2x==ONLY_STAGE2) ? v[38:12] : s1ppn[26:0];
    wire [37:0] s2ppn = gen_s2_ppn38(io_ptw_resp_s2_entry_ppn, io_ptw_resp_s2_entry_n,
                                     io_ptw_resp_s2_entry_level, gvpn27);
    assign p_ppn_s0[gi]  = (s2x==ONLY_STAGE2 | (&s2x)) ? s2ppn[PPN_W-1:0] : s1ppn[PPN_W-1:0];
  end

  // ---- 时序：req_out + preflight(port0) + redirect ----
  always_ff @(posedge clock) begin
    for (int i = 0; i < WIDTH; i++) begin
      if (io_req_valid[i]) begin
        req_out_vaddr[i]        <= io_req_vaddr[i];
        req_out_cmd[i]          <= io_req_cmd[i];
        virt_out[i]             <= io_csrd_priv_virt;
        porttr_r[i]             <= ~io_req_no_translate[i];
      end
      noTransReg[i]      <= io_req_no_translate[i];
      lcr_valid[i]        <= io_redirect_valid;
      lcr_robIdx_flag[i]  <= io_redirect_robIdx_flag;
      lcr_robIdx_value[i] <= io_redirect_robIdx_value;
      lcr_level[i]        <= io_redirect_level;
    end
    // port0-only requestor 字段打拍(port1 无这些输入)
    if (io_req_valid[0]) begin
      req_out0_hyperinst   <= io_req_hyperinst[0];
      req_out0_hlvx        <= io_req_hlvx[0];
      req_out0_isPrefetch  <= io_req_isPrefetch[0];
      req_out0_robIdx_flag <= io_req_robIdx_flag[0];
      req_out0_robIdx_value<= io_req_robIdx_value[0];
    end
    // port0-only preflight 打拍（REG=REG_1=prepf|pregpf|preaf[0]）
    REG_pre0          <= prepf[0] | pregpf[0] | preaf[0];
    REG_pre0_1        <= prepf[0] | pregpf[0] | preaf[0];
    excp_pf_ld_REG0   <= prepf[0];
    excp_gpf_ld_REG0  <= pregpf[0];
    excp_gpf_st_REG0  <= pregpf[0];
    excp_af_ld_REG0   <= preaf[0];
  end

  wire resp_gpa_wr_en = |( ~(rr_T_redirect | rr_T_enter) & rr_T_ptwhit );

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_out_v <= '0; need_gpa <= 1'b0; resp_gpa_refill <= 1'b0;
      p_hit <= '0; ptw_already_back_last <= '0;
    end else begin
      for (int i = 0; i < WIDTH; i++) begin
        req_out_v[i] <= io_req_valid[i] & ~io_req_kill[i];
        ptw_already_back_last[i] <= io_ptw_resp_valid;
        p_hit[i] <= p_hit_s0[i];
      end
      need_gpa <=
        ~( (req_out_v[1]&hasGpf[1]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[1][VADDR_W-1:12]))
           | rr_T_redirect[1] )
        & ( rr_T_enter[1]
          | ~( (req_out_v[0]&hasGpf[0]&resp_gpa_refill&(need_gpa_vpn==req_out_vaddr[0][VADDR_W-1:12]))
               | rr_T_redirect[0] )
            & ( rr_T_enter[0] | need_gpa ) );
      resp_gpa_refill <=
        ~(rr_T_redirect[1] | rr_T_enter[1])
        & ( rr_T_ptwhit[1] | ~(rr_T_redirect[0]|rr_T_enter[0])
          & ( rr_T_ptwhit[0] | resp_gpa_refill ) );
    end
  end

  always_ff @(posedge clock) begin
    if (rr_T_redirect[1])      need_gpa_vpn <= '0;
    else if (rr_T_enter[1])    need_gpa_vpn <= req_out_vaddr[1][VADDR_W-1:12];
    else if (rr_T_redirect[0]) need_gpa_vpn <= '0;
    else if (rr_T_enter[0])    need_gpa_vpn <= req_out_vaddr[0][VADDR_W-1:12];

    if (rr_T_redirect[1] | ~rr_T_enter[1]) begin
      if (rr_T_redirect[0] | ~rr_T_enter[0]) begin end
      else begin need_gpa_robidx_flag <= req_out_robIdx_flag[0];
                 need_gpa_robidx_value <= req_out_robIdx_value[0]; end
    end else begin need_gpa_robidx_flag <= req_out_robIdx_flag[1];
                   need_gpa_robidx_value <= req_out_robIdx_value[1]; end

    for (int i = 0; i < WIDTH; i++) begin
      if (io_ptw_resp_valid) begin
        p_ppn[i]   <= p_ppn_s0[i];
        p_pbmt[i]  <= io_ptw_resp_s1_entry_pbmt;
        p_perm[i]  <= ptw_perm;
        p_g_pbmt[i]<= io_ptw_resp_s2_entry_pbmt;
        p_g_perm[i]<= ptw_gperm;
        pr_s2xlate[i]   <= io_ptw_resp_s2xlate;
        pr_s1_tag[i]    <= io_ptw_resp_s1_entry_tag;
        pr_s1_asid[i]   <= io_ptw_resp_s1_entry_asid;
        pr_s1_vmid[i]   <= io_ptw_resp_s1_entry_vmid;
        pr_s1_n[i]      <= io_ptw_resp_s1_entry_n;
        pr_s1_perm_g[i] <= io_ptw_resp_s1_entry_perm_g;
        pr_s1_level[i]  <= io_ptw_resp_s1_entry_level;
        pr_s1_addr_low[i]<= io_ptw_resp_s1_addr_low;
        pr_s1_valididx[i]<= io_ptw_resp_s1_valididx;
        pr_s2_tag[i]    <= io_ptw_resp_s2_entry_tag;
        pr_s2_vmid[i]   <= io_ptw_resp_s2_entry_vmid;
        pr_s2_n[i]      <= io_ptw_resp_s2_entry_n;
        pr_s2_level[i]  <= io_ptw_resp_s2_entry_level;
      end
    end
  end

endmodule
