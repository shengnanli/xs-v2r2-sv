// 自动生成：scripts/gen_tlbfa.py —— 勿手改
// TLBFA golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核 struct/数组端口。
// 输出端口集合按 golden 实测裁剪结果生成（firtool 死代码消除非均匀）。
module TLBFA_1 import xs_tlbfa_pkg::*; (
  input clock,
  input reset,
  input io_sfence_valid,
  input io_sfence_bits_rs1,
  input io_sfence_bits_rs2,
  input [49:0] io_sfence_bits_addr,
  input [15:0] io_sfence_bits_id,
  input io_sfence_bits_hv,
  input io_sfence_bits_hg,
  input [15:0] io_csr_satp_asid,
  input [15:0] io_csr_vsatp_asid,
  input [15:0] io_csr_hgatp_vmid,
  input io_csr_priv_virt,
  input io_r_req_0_valid,
  input [37:0] io_r_req_0_bits_vpn,
  input [1:0] io_r_req_0_bits_s2xlate,
  input io_r_req_1_valid,
  input [37:0] io_r_req_1_bits_vpn,
  input [1:0] io_r_req_1_bits_s2xlate,
  input io_r_req_2_valid,
  input [37:0] io_r_req_2_bits_vpn,
  input [1:0] io_r_req_2_bits_s2xlate,
  input io_r_req_3_valid,
  input [37:0] io_r_req_3_bits_vpn,
  input [1:0] io_r_req_3_bits_s2xlate,
  input io_w_valid,
  input [5:0] io_w_bits_wayIdx,
  input [1:0] io_w_bits_data_s2xlate,
  input [34:0] io_w_bits_data_s1_entry_tag,
  input [15:0] io_w_bits_data_s1_entry_asid,
  input [13:0] io_w_bits_data_s1_entry_vmid,
  input io_w_bits_data_s1_entry_n,
  input [1:0] io_w_bits_data_s1_entry_pbmt,
  input io_w_bits_data_s1_entry_perm_d,
  input io_w_bits_data_s1_entry_perm_a,
  input io_w_bits_data_s1_entry_perm_g,
  input io_w_bits_data_s1_entry_perm_u,
  input io_w_bits_data_s1_entry_perm_x,
  input io_w_bits_data_s1_entry_perm_w,
  input io_w_bits_data_s1_entry_perm_r,
  input [1:0] io_w_bits_data_s1_entry_level,
  input io_w_bits_data_s1_entry_v,
  input [40:0] io_w_bits_data_s1_entry_ppn,
  input [2:0] io_w_bits_data_s1_ppn_low_0,
  input [2:0] io_w_bits_data_s1_ppn_low_1,
  input [2:0] io_w_bits_data_s1_ppn_low_2,
  input [2:0] io_w_bits_data_s1_ppn_low_3,
  input [2:0] io_w_bits_data_s1_ppn_low_4,
  input [2:0] io_w_bits_data_s1_ppn_low_5,
  input [2:0] io_w_bits_data_s1_ppn_low_6,
  input [2:0] io_w_bits_data_s1_ppn_low_7,
  input io_w_bits_data_s1_valididx_0,
  input io_w_bits_data_s1_valididx_1,
  input io_w_bits_data_s1_valididx_2,
  input io_w_bits_data_s1_valididx_3,
  input io_w_bits_data_s1_valididx_4,
  input io_w_bits_data_s1_valididx_5,
  input io_w_bits_data_s1_valididx_6,
  input io_w_bits_data_s1_valididx_7,
  input io_w_bits_data_s1_pteidx_0,
  input io_w_bits_data_s1_pteidx_1,
  input io_w_bits_data_s1_pteidx_2,
  input io_w_bits_data_s1_pteidx_3,
  input io_w_bits_data_s1_pteidx_4,
  input io_w_bits_data_s1_pteidx_5,
  input io_w_bits_data_s1_pteidx_6,
  input io_w_bits_data_s1_pteidx_7,
  input io_w_bits_data_s1_pf,
  input io_w_bits_data_s1_af,
  input [37:0] io_w_bits_data_s2_entry_tag,
  input [13:0] io_w_bits_data_s2_entry_vmid,
  input io_w_bits_data_s2_entry_n,
  input [1:0] io_w_bits_data_s2_entry_pbmt,
  input [37:0] io_w_bits_data_s2_entry_ppn,
  input io_w_bits_data_s2_entry_perm_d,
  input io_w_bits_data_s2_entry_perm_a,
  input io_w_bits_data_s2_entry_perm_g,
  input io_w_bits_data_s2_entry_perm_u,
  input io_w_bits_data_s2_entry_perm_x,
  input io_w_bits_data_s2_entry_perm_w,
  input io_w_bits_data_s2_entry_perm_r,
  input [1:0] io_w_bits_data_s2_entry_level,
  input io_w_bits_data_s2_gpf,
  input io_w_bits_data_s2_gaf,
  output io_r_resp_0_bits_hit,
  output [35:0] io_r_resp_0_bits_ppn_0,
  output [35:0] io_r_resp_0_bits_ppn_1,
  output [1:0] io_r_resp_0_bits_pbmt_0,
  output [1:0] io_r_resp_0_bits_g_pbmt_0,
  output io_r_resp_0_bits_perm_0_pf,
  output io_r_resp_0_bits_perm_0_af,
  output io_r_resp_0_bits_perm_0_v,
  output io_r_resp_0_bits_perm_0_d,
  output io_r_resp_0_bits_perm_0_a,
  output io_r_resp_0_bits_perm_0_u,
  output io_r_resp_0_bits_perm_0_x,
  output io_r_resp_0_bits_perm_0_w,
  output io_r_resp_0_bits_perm_0_r,
  output io_r_resp_0_bits_perm_1_pf,
  output io_r_resp_0_bits_perm_1_af,
  output io_r_resp_0_bits_perm_1_v,
  output io_r_resp_0_bits_perm_1_x,
  output io_r_resp_0_bits_perm_1_w,
  output io_r_resp_0_bits_perm_1_r,
  output io_r_resp_0_bits_g_perm_0_pf,
  output io_r_resp_0_bits_g_perm_0_af,
  output io_r_resp_0_bits_g_perm_0_d,
  output io_r_resp_0_bits_g_perm_0_a,
  output io_r_resp_0_bits_g_perm_0_x,
  output io_r_resp_0_bits_g_perm_0_w,
  output io_r_resp_0_bits_g_perm_0_r,
  output [1:0] io_r_resp_0_bits_s2xlate_0,
  output io_r_resp_1_bits_hit,
  output [35:0] io_r_resp_1_bits_ppn_0,
  output [35:0] io_r_resp_1_bits_ppn_1,
  output [1:0] io_r_resp_1_bits_pbmt_0,
  output [1:0] io_r_resp_1_bits_g_pbmt_0,
  output io_r_resp_1_bits_perm_0_pf,
  output io_r_resp_1_bits_perm_0_af,
  output io_r_resp_1_bits_perm_0_v,
  output io_r_resp_1_bits_perm_0_d,
  output io_r_resp_1_bits_perm_0_a,
  output io_r_resp_1_bits_perm_0_u,
  output io_r_resp_1_bits_perm_0_x,
  output io_r_resp_1_bits_perm_0_w,
  output io_r_resp_1_bits_perm_0_r,
  output io_r_resp_1_bits_perm_1_pf,
  output io_r_resp_1_bits_perm_1_af,
  output io_r_resp_1_bits_perm_1_v,
  output io_r_resp_1_bits_perm_1_x,
  output io_r_resp_1_bits_perm_1_w,
  output io_r_resp_1_bits_perm_1_r,
  output io_r_resp_1_bits_g_perm_0_pf,
  output io_r_resp_1_bits_g_perm_0_af,
  output io_r_resp_1_bits_g_perm_0_d,
  output io_r_resp_1_bits_g_perm_0_a,
  output io_r_resp_1_bits_g_perm_0_x,
  output io_r_resp_1_bits_g_perm_0_w,
  output io_r_resp_1_bits_g_perm_0_r,
  output [1:0] io_r_resp_1_bits_s2xlate_0,
  output io_r_resp_2_bits_hit,
  output [35:0] io_r_resp_2_bits_ppn_0,
  output [35:0] io_r_resp_2_bits_ppn_1,
  output [1:0] io_r_resp_2_bits_pbmt_0,
  output [1:0] io_r_resp_2_bits_g_pbmt_0,
  output io_r_resp_2_bits_perm_0_pf,
  output io_r_resp_2_bits_perm_0_af,
  output io_r_resp_2_bits_perm_0_v,
  output io_r_resp_2_bits_perm_0_d,
  output io_r_resp_2_bits_perm_0_a,
  output io_r_resp_2_bits_perm_0_u,
  output io_r_resp_2_bits_perm_0_x,
  output io_r_resp_2_bits_perm_0_w,
  output io_r_resp_2_bits_perm_0_r,
  output io_r_resp_2_bits_perm_1_pf,
  output io_r_resp_2_bits_perm_1_af,
  output io_r_resp_2_bits_perm_1_v,
  output io_r_resp_2_bits_perm_1_x,
  output io_r_resp_2_bits_perm_1_w,
  output io_r_resp_2_bits_perm_1_r,
  output io_r_resp_2_bits_g_perm_0_pf,
  output io_r_resp_2_bits_g_perm_0_af,
  output io_r_resp_2_bits_g_perm_0_d,
  output io_r_resp_2_bits_g_perm_0_a,
  output io_r_resp_2_bits_g_perm_0_x,
  output io_r_resp_2_bits_g_perm_0_w,
  output io_r_resp_2_bits_g_perm_0_r,
  output [1:0] io_r_resp_2_bits_s2xlate_0,
  output io_r_resp_3_bits_hit,
  output [35:0] io_r_resp_3_bits_ppn_0,
  output [1:0] io_r_resp_3_bits_pbmt_0,
  output [1:0] io_r_resp_3_bits_g_pbmt_0,
  output io_r_resp_3_bits_perm_0_pf,
  output io_r_resp_3_bits_perm_0_af,
  output io_r_resp_3_bits_perm_0_v,
  output io_r_resp_3_bits_perm_0_d,
  output io_r_resp_3_bits_perm_0_a,
  output io_r_resp_3_bits_perm_0_u,
  output io_r_resp_3_bits_perm_0_x,
  output io_r_resp_3_bits_perm_0_w,
  output io_r_resp_3_bits_perm_0_r,
  output io_r_resp_3_bits_g_perm_0_pf,
  output io_r_resp_3_bits_g_perm_0_af,
  output io_r_resp_3_bits_g_perm_0_d,
  output io_r_resp_3_bits_g_perm_0_a,
  output io_r_resp_3_bits_g_perm_0_x,
  output io_r_resp_3_bits_g_perm_0_w,
  output io_r_resp_3_bits_g_perm_0_r,
  output io_access_0_touch_ways_valid,
  output [5:0] io_access_0_touch_ways_bits,
  output io_access_1_touch_ways_valid,
  output [5:0] io_access_1_touch_ways_bits,
  output io_access_2_touch_ways_valid,
  output [5:0] io_access_2_touch_ways_bits,
  output io_access_3_touch_ways_valid,
  output [5:0] io_access_3_touch_ways_bits
);
  tlb_req_t      req       [4];
  logic          req_valid [4];
  logic          resp_valid[4];
  logic          resp_hit  [4];
  logic [35:0]   resp_ppn    [4][2];
  logic [1:0]    resp_pbmt   [4][2];
  logic [1:0]    resp_g_pbmt [4][2];
  tlb_perm_t     resp_perm   [4][2];
  tlb_gperm_t    resp_g_perm [4][2];
  logic [1:0]    resp_s2xlate[4][2];
  tlb_refill_t   wdata;
  logic          acc_valid [4];
  logic [5:0] acc_bits  [4];
  always_comb begin
    req[0].vpn = io_r_req_0_bits_vpn;
    req[0].s2xlate = io_r_req_0_bits_s2xlate;
    req_valid[0] = io_r_req_0_valid;
    req[1].vpn = io_r_req_1_bits_vpn;
    req[1].s2xlate = io_r_req_1_bits_s2xlate;
    req_valid[1] = io_r_req_1_valid;
    req[2].vpn = io_r_req_2_bits_vpn;
    req[2].s2xlate = io_r_req_2_bits_s2xlate;
    req_valid[2] = io_r_req_2_valid;
    req[3].vpn = io_r_req_3_bits_vpn;
    req[3].s2xlate = io_r_req_3_bits_s2xlate;
    req_valid[3] = io_r_req_3_valid;
    wdata.s1_entry_tag  = io_w_bits_data_s1_entry_tag;
    wdata.s1_entry_asid = io_w_bits_data_s1_entry_asid;
    wdata.s1_entry_vmid = io_w_bits_data_s1_entry_vmid;
    wdata.s1_entry_n    = io_w_bits_data_s1_entry_n;
    wdata.s1_entry_pbmt = io_w_bits_data_s1_entry_pbmt;
    wdata.s1_entry_perm = '0;
    wdata.s1_entry_perm.d = io_w_bits_data_s1_entry_perm_d;
    wdata.s1_entry_perm.a = io_w_bits_data_s1_entry_perm_a;
    wdata.s1_entry_perm.g = io_w_bits_data_s1_entry_perm_g;
    wdata.s1_entry_perm.u = io_w_bits_data_s1_entry_perm_u;
    wdata.s1_entry_perm.x = io_w_bits_data_s1_entry_perm_x;
    wdata.s1_entry_perm.w = io_w_bits_data_s1_entry_perm_w;
    wdata.s1_entry_perm.r = io_w_bits_data_s1_entry_perm_r;
    wdata.s1_entry_level = io_w_bits_data_s1_entry_level;
    wdata.s1_entry_v     = io_w_bits_data_s1_entry_v;
    wdata.s1_entry_ppn   = io_w_bits_data_s1_entry_ppn;
    wdata.s1_ppn_low[0] = io_w_bits_data_s1_ppn_low_0;
    wdata.s1_valididx[0] = io_w_bits_data_s1_valididx_0;
    wdata.s1_pteidx[0]   = io_w_bits_data_s1_pteidx_0;
    wdata.s1_ppn_low[1] = io_w_bits_data_s1_ppn_low_1;
    wdata.s1_valididx[1] = io_w_bits_data_s1_valididx_1;
    wdata.s1_pteidx[1]   = io_w_bits_data_s1_pteidx_1;
    wdata.s1_ppn_low[2] = io_w_bits_data_s1_ppn_low_2;
    wdata.s1_valididx[2] = io_w_bits_data_s1_valididx_2;
    wdata.s1_pteidx[2]   = io_w_bits_data_s1_pteidx_2;
    wdata.s1_ppn_low[3] = io_w_bits_data_s1_ppn_low_3;
    wdata.s1_valididx[3] = io_w_bits_data_s1_valididx_3;
    wdata.s1_pteidx[3]   = io_w_bits_data_s1_pteidx_3;
    wdata.s1_ppn_low[4] = io_w_bits_data_s1_ppn_low_4;
    wdata.s1_valididx[4] = io_w_bits_data_s1_valididx_4;
    wdata.s1_pteidx[4]   = io_w_bits_data_s1_pteidx_4;
    wdata.s1_ppn_low[5] = io_w_bits_data_s1_ppn_low_5;
    wdata.s1_valididx[5] = io_w_bits_data_s1_valididx_5;
    wdata.s1_pteidx[5]   = io_w_bits_data_s1_pteidx_5;
    wdata.s1_ppn_low[6] = io_w_bits_data_s1_ppn_low_6;
    wdata.s1_valididx[6] = io_w_bits_data_s1_valididx_6;
    wdata.s1_pteidx[6]   = io_w_bits_data_s1_pteidx_6;
    wdata.s1_ppn_low[7] = io_w_bits_data_s1_ppn_low_7;
    wdata.s1_valididx[7] = io_w_bits_data_s1_valididx_7;
    wdata.s1_pteidx[7]   = io_w_bits_data_s1_pteidx_7;
    wdata.s1_pf = io_w_bits_data_s1_pf;
    wdata.s1_af = io_w_bits_data_s1_af;
    wdata.s2_entry_tag  = io_w_bits_data_s2_entry_tag;
    wdata.s2_entry_vmid = io_w_bits_data_s2_entry_vmid;
    wdata.s2_entry_n    = io_w_bits_data_s2_entry_n;
    wdata.s2_entry_pbmt = io_w_bits_data_s2_entry_pbmt;
    wdata.s2_entry_ppn  = io_w_bits_data_s2_entry_ppn;
    wdata.s2_entry_perm = '0;
    wdata.s2_entry_perm.d = io_w_bits_data_s2_entry_perm_d;
    wdata.s2_entry_perm.a = io_w_bits_data_s2_entry_perm_a;
    wdata.s2_entry_perm.g = io_w_bits_data_s2_entry_perm_g;
    wdata.s2_entry_perm.u = io_w_bits_data_s2_entry_perm_u;
    wdata.s2_entry_perm.x = io_w_bits_data_s2_entry_perm_x;
    wdata.s2_entry_perm.w = io_w_bits_data_s2_entry_perm_w;
    wdata.s2_entry_perm.r = io_w_bits_data_s2_entry_perm_r;
    wdata.s2_entry_level = io_w_bits_data_s2_entry_level;
    wdata.s2_gpf = io_w_bits_data_s2_gpf;
    wdata.s2_gaf = io_w_bits_data_s2_gaf;
    wdata.s2xlate = io_w_bits_data_s2xlate;
  end
  xs_TLBFA_core #(.PORTS(4), .NDUPS(2), .NWAYS(48), .WAY_W(6)) u_core (
    .clock(clock), .reset(reset),
    .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1),
    .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr),
    .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv),
    .io_sfence_bits_hg(io_sfence_bits_hg),
    .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_priv_virt(io_csr_priv_virt),
    .io_r_req(req), .io_r_req_valid(req_valid),
    .io_r_resp_valid(resp_valid), .io_r_resp_hit(resp_hit),
    .io_r_resp_ppn(resp_ppn), .io_r_resp_pbmt(resp_pbmt), .io_r_resp_g_pbmt(resp_g_pbmt),
    .io_r_resp_perm(resp_perm), .io_r_resp_g_perm(resp_g_perm), .io_r_resp_s2xlate(resp_s2xlate),
    .io_w_valid(io_w_valid), .io_w_bits_wayIdx(io_w_bits_wayIdx), .io_w_bits_data(wdata),
    .io_access_touch_ways_valid(acc_valid), .io_access_touch_ways_bits(acc_bits)
  );
  assign io_r_resp_0_bits_hit = resp_hit[0];
  assign io_r_resp_0_bits_ppn_0 = resp_ppn[0][0];
  assign io_r_resp_0_bits_ppn_1 = resp_ppn[0][1];
  assign io_r_resp_0_bits_pbmt_0 = resp_pbmt[0][0];
  assign io_r_resp_0_bits_g_pbmt_0 = resp_g_pbmt[0][0];
  assign io_r_resp_0_bits_perm_0_pf = resp_perm[0][0].pf;
  assign io_r_resp_0_bits_perm_0_af = resp_perm[0][0].af;
  assign io_r_resp_0_bits_perm_0_v = resp_perm[0][0].v;
  assign io_r_resp_0_bits_perm_0_d = resp_perm[0][0].d;
  assign io_r_resp_0_bits_perm_0_a = resp_perm[0][0].a;
  assign io_r_resp_0_bits_perm_0_u = resp_perm[0][0].u;
  assign io_r_resp_0_bits_perm_0_x = resp_perm[0][0].x;
  assign io_r_resp_0_bits_perm_0_w = resp_perm[0][0].w;
  assign io_r_resp_0_bits_perm_0_r = resp_perm[0][0].r;
  assign io_r_resp_0_bits_perm_1_pf = resp_perm[0][1].pf;
  assign io_r_resp_0_bits_perm_1_af = resp_perm[0][1].af;
  assign io_r_resp_0_bits_perm_1_v = resp_perm[0][1].v;
  assign io_r_resp_0_bits_perm_1_x = resp_perm[0][1].x;
  assign io_r_resp_0_bits_perm_1_w = resp_perm[0][1].w;
  assign io_r_resp_0_bits_perm_1_r = resp_perm[0][1].r;
  assign io_r_resp_0_bits_g_perm_0_pf = resp_g_perm[0][0].pf;
  assign io_r_resp_0_bits_g_perm_0_af = resp_g_perm[0][0].af;
  assign io_r_resp_0_bits_g_perm_0_d = resp_g_perm[0][0].d;
  assign io_r_resp_0_bits_g_perm_0_a = resp_g_perm[0][0].a;
  assign io_r_resp_0_bits_g_perm_0_x = resp_g_perm[0][0].x;
  assign io_r_resp_0_bits_g_perm_0_w = resp_g_perm[0][0].w;
  assign io_r_resp_0_bits_g_perm_0_r = resp_g_perm[0][0].r;
  assign io_r_resp_0_bits_s2xlate_0 = resp_s2xlate[0][0];
  assign io_r_resp_1_bits_hit = resp_hit[1];
  assign io_r_resp_1_bits_ppn_0 = resp_ppn[1][0];
  assign io_r_resp_1_bits_ppn_1 = resp_ppn[1][1];
  assign io_r_resp_1_bits_pbmt_0 = resp_pbmt[1][0];
  assign io_r_resp_1_bits_g_pbmt_0 = resp_g_pbmt[1][0];
  assign io_r_resp_1_bits_perm_0_pf = resp_perm[1][0].pf;
  assign io_r_resp_1_bits_perm_0_af = resp_perm[1][0].af;
  assign io_r_resp_1_bits_perm_0_v = resp_perm[1][0].v;
  assign io_r_resp_1_bits_perm_0_d = resp_perm[1][0].d;
  assign io_r_resp_1_bits_perm_0_a = resp_perm[1][0].a;
  assign io_r_resp_1_bits_perm_0_u = resp_perm[1][0].u;
  assign io_r_resp_1_bits_perm_0_x = resp_perm[1][0].x;
  assign io_r_resp_1_bits_perm_0_w = resp_perm[1][0].w;
  assign io_r_resp_1_bits_perm_0_r = resp_perm[1][0].r;
  assign io_r_resp_1_bits_perm_1_pf = resp_perm[1][1].pf;
  assign io_r_resp_1_bits_perm_1_af = resp_perm[1][1].af;
  assign io_r_resp_1_bits_perm_1_v = resp_perm[1][1].v;
  assign io_r_resp_1_bits_perm_1_x = resp_perm[1][1].x;
  assign io_r_resp_1_bits_perm_1_w = resp_perm[1][1].w;
  assign io_r_resp_1_bits_perm_1_r = resp_perm[1][1].r;
  assign io_r_resp_1_bits_g_perm_0_pf = resp_g_perm[1][0].pf;
  assign io_r_resp_1_bits_g_perm_0_af = resp_g_perm[1][0].af;
  assign io_r_resp_1_bits_g_perm_0_d = resp_g_perm[1][0].d;
  assign io_r_resp_1_bits_g_perm_0_a = resp_g_perm[1][0].a;
  assign io_r_resp_1_bits_g_perm_0_x = resp_g_perm[1][0].x;
  assign io_r_resp_1_bits_g_perm_0_w = resp_g_perm[1][0].w;
  assign io_r_resp_1_bits_g_perm_0_r = resp_g_perm[1][0].r;
  assign io_r_resp_1_bits_s2xlate_0 = resp_s2xlate[1][0];
  assign io_r_resp_2_bits_hit = resp_hit[2];
  assign io_r_resp_2_bits_ppn_0 = resp_ppn[2][0];
  assign io_r_resp_2_bits_ppn_1 = resp_ppn[2][1];
  assign io_r_resp_2_bits_pbmt_0 = resp_pbmt[2][0];
  assign io_r_resp_2_bits_g_pbmt_0 = resp_g_pbmt[2][0];
  assign io_r_resp_2_bits_perm_0_pf = resp_perm[2][0].pf;
  assign io_r_resp_2_bits_perm_0_af = resp_perm[2][0].af;
  assign io_r_resp_2_bits_perm_0_v = resp_perm[2][0].v;
  assign io_r_resp_2_bits_perm_0_d = resp_perm[2][0].d;
  assign io_r_resp_2_bits_perm_0_a = resp_perm[2][0].a;
  assign io_r_resp_2_bits_perm_0_u = resp_perm[2][0].u;
  assign io_r_resp_2_bits_perm_0_x = resp_perm[2][0].x;
  assign io_r_resp_2_bits_perm_0_w = resp_perm[2][0].w;
  assign io_r_resp_2_bits_perm_0_r = resp_perm[2][0].r;
  assign io_r_resp_2_bits_perm_1_pf = resp_perm[2][1].pf;
  assign io_r_resp_2_bits_perm_1_af = resp_perm[2][1].af;
  assign io_r_resp_2_bits_perm_1_v = resp_perm[2][1].v;
  assign io_r_resp_2_bits_perm_1_x = resp_perm[2][1].x;
  assign io_r_resp_2_bits_perm_1_w = resp_perm[2][1].w;
  assign io_r_resp_2_bits_perm_1_r = resp_perm[2][1].r;
  assign io_r_resp_2_bits_g_perm_0_pf = resp_g_perm[2][0].pf;
  assign io_r_resp_2_bits_g_perm_0_af = resp_g_perm[2][0].af;
  assign io_r_resp_2_bits_g_perm_0_d = resp_g_perm[2][0].d;
  assign io_r_resp_2_bits_g_perm_0_a = resp_g_perm[2][0].a;
  assign io_r_resp_2_bits_g_perm_0_x = resp_g_perm[2][0].x;
  assign io_r_resp_2_bits_g_perm_0_w = resp_g_perm[2][0].w;
  assign io_r_resp_2_bits_g_perm_0_r = resp_g_perm[2][0].r;
  assign io_r_resp_2_bits_s2xlate_0 = resp_s2xlate[2][0];
  assign io_r_resp_3_bits_hit = resp_hit[3];
  assign io_r_resp_3_bits_ppn_0 = resp_ppn[3][0];
  assign io_r_resp_3_bits_pbmt_0 = resp_pbmt[3][0];
  assign io_r_resp_3_bits_g_pbmt_0 = resp_g_pbmt[3][0];
  assign io_r_resp_3_bits_perm_0_pf = resp_perm[3][0].pf;
  assign io_r_resp_3_bits_perm_0_af = resp_perm[3][0].af;
  assign io_r_resp_3_bits_perm_0_v = resp_perm[3][0].v;
  assign io_r_resp_3_bits_perm_0_d = resp_perm[3][0].d;
  assign io_r_resp_3_bits_perm_0_a = resp_perm[3][0].a;
  assign io_r_resp_3_bits_perm_0_u = resp_perm[3][0].u;
  assign io_r_resp_3_bits_perm_0_x = resp_perm[3][0].x;
  assign io_r_resp_3_bits_perm_0_w = resp_perm[3][0].w;
  assign io_r_resp_3_bits_perm_0_r = resp_perm[3][0].r;
  assign io_r_resp_3_bits_g_perm_0_pf = resp_g_perm[3][0].pf;
  assign io_r_resp_3_bits_g_perm_0_af = resp_g_perm[3][0].af;
  assign io_r_resp_3_bits_g_perm_0_d = resp_g_perm[3][0].d;
  assign io_r_resp_3_bits_g_perm_0_a = resp_g_perm[3][0].a;
  assign io_r_resp_3_bits_g_perm_0_x = resp_g_perm[3][0].x;
  assign io_r_resp_3_bits_g_perm_0_w = resp_g_perm[3][0].w;
  assign io_r_resp_3_bits_g_perm_0_r = resp_g_perm[3][0].r;
  assign io_access_0_touch_ways_valid = acc_valid[0];
  assign io_access_0_touch_ways_bits = acc_bits[0];
  assign io_access_1_touch_ways_valid = acc_valid[1];
  assign io_access_1_touch_ways_bits = acc_bits[1];
  assign io_access_2_touch_ways_valid = acc_valid[2];
  assign io_access_2_touch_ways_bits = acc_bits[2];
  assign io_access_3_touch_ways_valid = acc_valid[3];
  assign io_access_3_touch_ways_bits = acc_bits[3];
endmodule
