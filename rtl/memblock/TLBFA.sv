// ============================================================================
// TLBFA —— itlb（取指 TLB） 的 L1 TLB 全相联存储阵列（TLBFA 家族薄 wrapper）
//
// 本变体参数与规模：PORTS=3（查询端口数）  nWays=48（全相联条数，四变体一致）
//   nDups=1   KEEP_WPERM=0   golden TLBFA.sv = 21303 行 / 140 端口
//
// 本变体 = itlb 的存储阵列：3 个查询端口（ICache 三路 vpn 查询），nDups=1。
// KEEP_WPERM=0：取指不关心"能不能写"，父级从不读 perm.d / g_perm.{d,w,r}，
// firtool 把这 4×48 个寄存器连同端口一起消掉了——本变体的端口表里确实
// 找不到 io_r_resp_*_bits_perm_*_d，也找不到 g_perm 的 d/w/r。
// 同理 g_perm 只剩 pf/af/a/x 四位（其余在四个变体里都被消掉）。
//
// 逻辑全部在参数化核 xs_TLBFA_core（同目录 xs_TLBFA_core.sv）里；本文件只做
// 端口展平与改名：把 golden 的扁平 io_* 名接到核的按端口号成组的向量端口上。
// 端口表逐位抄自 G1 golden 同名模块（scripts/gen_tlbfa_family.py 生成，勿手改）。
// ============================================================================

// BEGIN GENERATED(tlbfa-wrapper)
module TLBFA(
  input          clock,
  input          reset,
  input          io_sfence_valid,
  input          io_sfence_bits_rs1,
  input          io_sfence_bits_rs2,
  input  [49:0]  io_sfence_bits_addr,
  input  [15:0]  io_sfence_bits_id,
  input          io_sfence_bits_hv,
  input          io_sfence_bits_hg,
  input  [15:0]  io_csr_satp_asid,
  input  [15:0]  io_csr_vsatp_asid,
  input  [15:0]  io_csr_hgatp_vmid,
  input          io_csr_mbmc_BME,
  input          io_csr_mbmc_CMODE,
  input          io_csr_priv_virt,
  input          io_r_req_0_valid,
  input  [37:0]  io_r_req_0_bits_vpn,
  input  [1:0]   io_r_req_0_bits_s2xlate,
  input          io_r_req_1_valid,
  input  [37:0]  io_r_req_1_bits_vpn,
  input  [1:0]   io_r_req_1_bits_s2xlate,
  input          io_r_req_2_valid,
  input  [37:0]  io_r_req_2_bits_vpn,
  input  [1:0]   io_r_req_2_bits_s2xlate,
  output         io_r_resp_0_bits_hit,
  output [35:0]  io_r_resp_0_bits_ppn_0,
  output [1:0]   io_r_resp_0_bits_pbmt_0,
  output [1:0]   io_r_resp_0_bits_g_pbmt_0,
  output         io_r_resp_0_bits_perm_0_pf,
  output         io_r_resp_0_bits_perm_0_af,
  output         io_r_resp_0_bits_perm_0_v,
  output         io_r_resp_0_bits_perm_0_a,
  output         io_r_resp_0_bits_perm_0_u,
  output         io_r_resp_0_bits_perm_0_x,
  output         io_r_resp_0_bits_perm_0_w,
  output         io_r_resp_0_bits_perm_0_r,
  output         io_r_resp_0_bits_g_perm_0_pf,
  output         io_r_resp_0_bits_g_perm_0_af,
  output         io_r_resp_0_bits_g_perm_0_a,
  output         io_r_resp_0_bits_g_perm_0_x,
  output [1:0]   io_r_resp_0_bits_s2xlate_0,
  output         io_r_resp_1_bits_hit,
  output [35:0]  io_r_resp_1_bits_ppn_0,
  output [1:0]   io_r_resp_1_bits_pbmt_0,
  output [1:0]   io_r_resp_1_bits_g_pbmt_0,
  output         io_r_resp_1_bits_perm_0_pf,
  output         io_r_resp_1_bits_perm_0_af,
  output         io_r_resp_1_bits_perm_0_v,
  output         io_r_resp_1_bits_perm_0_a,
  output         io_r_resp_1_bits_perm_0_u,
  output         io_r_resp_1_bits_perm_0_x,
  output         io_r_resp_1_bits_perm_0_w,
  output         io_r_resp_1_bits_perm_0_r,
  output         io_r_resp_1_bits_g_perm_0_pf,
  output         io_r_resp_1_bits_g_perm_0_af,
  output         io_r_resp_1_bits_g_perm_0_a,
  output         io_r_resp_1_bits_g_perm_0_x,
  output [1:0]   io_r_resp_1_bits_s2xlate_0,
  output         io_r_resp_2_bits_hit,
  output [35:0]  io_r_resp_2_bits_ppn_0,
  output [1:0]   io_r_resp_2_bits_pbmt_0,
  output [1:0]   io_r_resp_2_bits_g_pbmt_0,
  output         io_r_resp_2_bits_perm_0_pf,
  output         io_r_resp_2_bits_perm_0_af,
  output         io_r_resp_2_bits_perm_0_v,
  output         io_r_resp_2_bits_perm_0_a,
  output         io_r_resp_2_bits_perm_0_u,
  output         io_r_resp_2_bits_perm_0_x,
  output         io_r_resp_2_bits_perm_0_w,
  output         io_r_resp_2_bits_perm_0_r,
  output         io_r_resp_2_bits_g_perm_0_pf,
  output         io_r_resp_2_bits_g_perm_0_af,
  output         io_r_resp_2_bits_g_perm_0_a,
  output         io_r_resp_2_bits_g_perm_0_x,
  output [1:0]   io_r_resp_2_bits_s2xlate_0,
  input          io_w_valid,
  input  [5:0]   io_w_bits_wayIdx,
  input  [1:0]   io_w_bits_data_s2xlate,
  input  [34:0]  io_w_bits_data_s1_entry_tag,
  input  [15:0]  io_w_bits_data_s1_entry_asid,
  input  [13:0]  io_w_bits_data_s1_entry_vmid,
  input          io_w_bits_data_s1_entry_n,
  input  [1:0]   io_w_bits_data_s1_entry_pbmt,
  input          io_w_bits_data_s1_entry_perm_d,
  input          io_w_bits_data_s1_entry_perm_a,
  input          io_w_bits_data_s1_entry_perm_g,
  input          io_w_bits_data_s1_entry_perm_u,
  input          io_w_bits_data_s1_entry_perm_x,
  input          io_w_bits_data_s1_entry_perm_w,
  input          io_w_bits_data_s1_entry_perm_r,
  input  [1:0]   io_w_bits_data_s1_entry_level,
  input          io_w_bits_data_s1_entry_v,
  input  [40:0]  io_w_bits_data_s1_entry_ppn,
  input  [2:0]   io_w_bits_data_s1_ppn_low_0,
  input  [2:0]   io_w_bits_data_s1_ppn_low_1,
  input  [2:0]   io_w_bits_data_s1_ppn_low_2,
  input  [2:0]   io_w_bits_data_s1_ppn_low_3,
  input  [2:0]   io_w_bits_data_s1_ppn_low_4,
  input  [2:0]   io_w_bits_data_s1_ppn_low_5,
  input  [2:0]   io_w_bits_data_s1_ppn_low_6,
  input  [2:0]   io_w_bits_data_s1_ppn_low_7,
  input          io_w_bits_data_s1_valididx_0,
  input          io_w_bits_data_s1_valididx_1,
  input          io_w_bits_data_s1_valididx_2,
  input          io_w_bits_data_s1_valididx_3,
  input          io_w_bits_data_s1_valididx_4,
  input          io_w_bits_data_s1_valididx_5,
  input          io_w_bits_data_s1_valididx_6,
  input          io_w_bits_data_s1_valididx_7,
  input          io_w_bits_data_s1_pteidx_0,
  input          io_w_bits_data_s1_pteidx_1,
  input          io_w_bits_data_s1_pteidx_2,
  input          io_w_bits_data_s1_pteidx_3,
  input          io_w_bits_data_s1_pteidx_4,
  input          io_w_bits_data_s1_pteidx_5,
  input          io_w_bits_data_s1_pteidx_6,
  input          io_w_bits_data_s1_pteidx_7,
  input          io_w_bits_data_s1_pf,
  input          io_w_bits_data_s1_af,
  input  [37:0]  io_w_bits_data_s2_entry_tag,
  input  [13:0]  io_w_bits_data_s2_entry_vmid,
  input          io_w_bits_data_s2_entry_n,
  input  [1:0]   io_w_bits_data_s2_entry_pbmt,
  input  [37:0]  io_w_bits_data_s2_entry_ppn,
  input          io_w_bits_data_s2_entry_perm_d,
  input          io_w_bits_data_s2_entry_perm_a,
  input          io_w_bits_data_s2_entry_perm_g,
  input          io_w_bits_data_s2_entry_perm_u,
  input          io_w_bits_data_s2_entry_perm_x,
  input          io_w_bits_data_s2_entry_perm_w,
  input          io_w_bits_data_s2_entry_perm_r,
  input  [1:0]   io_w_bits_data_s2_entry_level,
  input          io_w_bits_data_s2_gpf,
  input          io_w_bits_data_s2_gaf,
  output         io_access_0_touch_ways_valid,
  output [5:0]   io_access_0_touch_ways_bits,
  output         io_access_1_touch_ways_valid,
  output [5:0]   io_access_1_touch_ways_bits,
  output         io_access_2_touch_ways_valid,
  output [5:0]   io_access_2_touch_ways_bits
);

  // ---- 核侧信号（按端口号成组的 packed 数组，与核端口同型）----
  logic               core_sfence_valid;
  logic               core_sfence_rs1;
  logic               core_sfence_rs2;
  logic [49:0]        core_sfence_addr;
  logic [15:0]        core_sfence_id;
  logic               core_sfence_hv;
  logic               core_sfence_hg;
  logic [15:0]        core_csr_satp_asid;
  logic [15:0]        core_csr_vsatp_asid;
  logic [15:0]        core_csr_hgatp_vmid;
  logic               core_csr_mbmc_bme;
  logic               core_csr_mbmc_cmode;
  logic               core_csr_priv_virt;
  logic [2:0]         core_req_valid;
  logic [2:0][37:0]   core_req_vpn;
  logic [2:0][1:0]    core_req_s2xlate;
  logic [2:0]         core_resp_hit;
  logic [2:0][35:0]   core_resp_ppn;
  logic [2:0][1:0]    core_resp_pbmt;
  logic [2:0][1:0]    core_resp_g_pbmt;
  logic [2:0]         core_resp_perm_pf;
  logic [2:0]         core_resp_perm_af;
  logic [2:0]         core_resp_perm_v;
  logic [2:0]         core_resp_perm_d;
  logic [2:0]         core_resp_perm_a;
  logic [2:0]         core_resp_perm_g;
  logic [2:0]         core_resp_perm_u;
  logic [2:0]         core_resp_perm_x;
  logic [2:0]         core_resp_perm_w;
  logic [2:0]         core_resp_perm_r;
  logic [2:0]         core_resp_g_perm_pf;
  logic [2:0]         core_resp_g_perm_af;
  logic [2:0]         core_resp_g_perm_d;
  logic [2:0]         core_resp_g_perm_a;
  logic [2:0]         core_resp_g_perm_x;
  logic [2:0]         core_resp_g_perm_w;
  logic [2:0]         core_resp_g_perm_r;
  logic [2:0][1:0]    core_resp_s2xlate;
  logic               core_w_valid;
  logic [5:0]         core_w_way;
  logic [1:0]         core_w_s2xlate;
  logic [34:0]        core_w_s1_entry_tag;
  logic [15:0]        core_w_s1_entry_asid;
  logic [13:0]        core_w_s1_entry_vmid;
  logic               core_w_s1_entry_n;
  logic [1:0]         core_w_s1_entry_pbmt;
  logic               core_w_s1_entry_perm_d;
  logic               core_w_s1_entry_perm_a;
  logic               core_w_s1_entry_perm_g;
  logic               core_w_s1_entry_perm_u;
  logic               core_w_s1_entry_perm_x;
  logic               core_w_s1_entry_perm_w;
  logic               core_w_s1_entry_perm_r;
  logic [1:0]         core_w_s1_entry_level;
  logic               core_w_s1_entry_v;
  logic [40:0]        core_w_s1_entry_ppn;
  logic [7:0][2:0]    core_w_s1_ppn_low;
  logic [7:0]         core_w_s1_valididx;
  logic [7:0]         core_w_s1_pteidx;
  logic               core_w_s1_pf;
  logic               core_w_s1_af;
  logic [37:0]        core_w_s2_entry_tag;
  logic [13:0]        core_w_s2_entry_vmid;
  logic               core_w_s2_entry_n;
  logic [1:0]         core_w_s2_entry_pbmt;
  logic [37:0]        core_w_s2_entry_ppn;
  logic               core_w_s2_entry_perm_d;
  logic               core_w_s2_entry_perm_a;
  logic               core_w_s2_entry_perm_g;
  logic               core_w_s2_entry_perm_u;
  logic               core_w_s2_entry_perm_x;
  logic               core_w_s2_entry_perm_w;
  logic               core_w_s2_entry_perm_r;
  logic [1:0]         core_w_s2_entry_level;
  logic               core_w_s2_gpf;
  logic               core_w_s2_gaf;
  logic [2:0]         core_access_touch_valid;
  logic [2:0][5:0]    core_access_touch_way;

  // ---- 输入：golden 扁平端口 -> 核 ----
  assign core_sfence_valid = io_sfence_valid;
  assign core_sfence_rs1 = io_sfence_bits_rs1;
  assign core_sfence_rs2 = io_sfence_bits_rs2;
  assign core_sfence_addr = io_sfence_bits_addr;
  assign core_sfence_id = io_sfence_bits_id;
  assign core_sfence_hv = io_sfence_bits_hv;
  assign core_sfence_hg = io_sfence_bits_hg;
  assign core_csr_satp_asid = io_csr_satp_asid;
  assign core_csr_vsatp_asid = io_csr_vsatp_asid;
  assign core_csr_hgatp_vmid = io_csr_hgatp_vmid;
  assign core_csr_mbmc_bme = io_csr_mbmc_BME;
  assign core_csr_mbmc_cmode = io_csr_mbmc_CMODE;
  assign core_csr_priv_virt = io_csr_priv_virt;
  assign core_req_valid[0] = io_r_req_0_valid;
  assign core_req_vpn[0] = io_r_req_0_bits_vpn;
  assign core_req_s2xlate[0] = io_r_req_0_bits_s2xlate;
  assign core_req_valid[1] = io_r_req_1_valid;
  assign core_req_vpn[1] = io_r_req_1_bits_vpn;
  assign core_req_s2xlate[1] = io_r_req_1_bits_s2xlate;
  assign core_req_valid[2] = io_r_req_2_valid;
  assign core_req_vpn[2] = io_r_req_2_bits_vpn;
  assign core_req_s2xlate[2] = io_r_req_2_bits_s2xlate;
  assign core_w_valid = io_w_valid;
  assign core_w_way = io_w_bits_wayIdx;
  assign core_w_s2xlate = io_w_bits_data_s2xlate;
  assign core_w_s1_entry_tag = io_w_bits_data_s1_entry_tag;
  assign core_w_s1_entry_asid = io_w_bits_data_s1_entry_asid;
  assign core_w_s1_entry_vmid = io_w_bits_data_s1_entry_vmid;
  assign core_w_s1_entry_n = io_w_bits_data_s1_entry_n;
  assign core_w_s1_entry_pbmt = io_w_bits_data_s1_entry_pbmt;
  assign core_w_s1_entry_perm_d = io_w_bits_data_s1_entry_perm_d;
  assign core_w_s1_entry_perm_a = io_w_bits_data_s1_entry_perm_a;
  assign core_w_s1_entry_perm_g = io_w_bits_data_s1_entry_perm_g;
  assign core_w_s1_entry_perm_u = io_w_bits_data_s1_entry_perm_u;
  assign core_w_s1_entry_perm_x = io_w_bits_data_s1_entry_perm_x;
  assign core_w_s1_entry_perm_w = io_w_bits_data_s1_entry_perm_w;
  assign core_w_s1_entry_perm_r = io_w_bits_data_s1_entry_perm_r;
  assign core_w_s1_entry_level = io_w_bits_data_s1_entry_level;
  assign core_w_s1_entry_v = io_w_bits_data_s1_entry_v;
  assign core_w_s1_entry_ppn = io_w_bits_data_s1_entry_ppn;
  assign core_w_s1_ppn_low[0] = io_w_bits_data_s1_ppn_low_0;
  assign core_w_s1_ppn_low[1] = io_w_bits_data_s1_ppn_low_1;
  assign core_w_s1_ppn_low[2] = io_w_bits_data_s1_ppn_low_2;
  assign core_w_s1_ppn_low[3] = io_w_bits_data_s1_ppn_low_3;
  assign core_w_s1_ppn_low[4] = io_w_bits_data_s1_ppn_low_4;
  assign core_w_s1_ppn_low[5] = io_w_bits_data_s1_ppn_low_5;
  assign core_w_s1_ppn_low[6] = io_w_bits_data_s1_ppn_low_6;
  assign core_w_s1_ppn_low[7] = io_w_bits_data_s1_ppn_low_7;
  assign core_w_s1_valididx[0] = io_w_bits_data_s1_valididx_0;
  assign core_w_s1_valididx[1] = io_w_bits_data_s1_valididx_1;
  assign core_w_s1_valididx[2] = io_w_bits_data_s1_valididx_2;
  assign core_w_s1_valididx[3] = io_w_bits_data_s1_valididx_3;
  assign core_w_s1_valididx[4] = io_w_bits_data_s1_valididx_4;
  assign core_w_s1_valididx[5] = io_w_bits_data_s1_valididx_5;
  assign core_w_s1_valididx[6] = io_w_bits_data_s1_valididx_6;
  assign core_w_s1_valididx[7] = io_w_bits_data_s1_valididx_7;
  assign core_w_s1_pteidx[0] = io_w_bits_data_s1_pteidx_0;
  assign core_w_s1_pteidx[1] = io_w_bits_data_s1_pteidx_1;
  assign core_w_s1_pteidx[2] = io_w_bits_data_s1_pteidx_2;
  assign core_w_s1_pteidx[3] = io_w_bits_data_s1_pteidx_3;
  assign core_w_s1_pteidx[4] = io_w_bits_data_s1_pteidx_4;
  assign core_w_s1_pteidx[5] = io_w_bits_data_s1_pteidx_5;
  assign core_w_s1_pteidx[6] = io_w_bits_data_s1_pteidx_6;
  assign core_w_s1_pteidx[7] = io_w_bits_data_s1_pteidx_7;
  assign core_w_s1_pf = io_w_bits_data_s1_pf;
  assign core_w_s1_af = io_w_bits_data_s1_af;
  assign core_w_s2_entry_tag = io_w_bits_data_s2_entry_tag;
  assign core_w_s2_entry_vmid = io_w_bits_data_s2_entry_vmid;
  assign core_w_s2_entry_n = io_w_bits_data_s2_entry_n;
  assign core_w_s2_entry_pbmt = io_w_bits_data_s2_entry_pbmt;
  assign core_w_s2_entry_ppn = io_w_bits_data_s2_entry_ppn;
  assign core_w_s2_entry_perm_d = io_w_bits_data_s2_entry_perm_d;
  assign core_w_s2_entry_perm_a = io_w_bits_data_s2_entry_perm_a;
  assign core_w_s2_entry_perm_g = io_w_bits_data_s2_entry_perm_g;
  assign core_w_s2_entry_perm_u = io_w_bits_data_s2_entry_perm_u;
  assign core_w_s2_entry_perm_x = io_w_bits_data_s2_entry_perm_x;
  assign core_w_s2_entry_perm_w = io_w_bits_data_s2_entry_perm_w;
  assign core_w_s2_entry_perm_r = io_w_bits_data_s2_entry_perm_r;
  assign core_w_s2_entry_level = io_w_bits_data_s2_entry_level;
  assign core_w_s2_gpf = io_w_bits_data_s2_gpf;
  assign core_w_s2_gaf = io_w_bits_data_s2_gaf;

  xs_TLBFA_core #(
    .PORTS      (3),
    .KEEP_WPERM (0)
  ) u_core (
    .clock               (clock),
    .reset               (reset),
    .sfence_valid        (core_sfence_valid),
    .sfence_rs1          (core_sfence_rs1),
    .sfence_rs2          (core_sfence_rs2),
    .sfence_addr         (core_sfence_addr),
    .sfence_id           (core_sfence_id),
    .sfence_hv           (core_sfence_hv),
    .sfence_hg           (core_sfence_hg),
    .csr_satp_asid       (core_csr_satp_asid),
    .csr_vsatp_asid      (core_csr_vsatp_asid),
    .csr_hgatp_vmid      (core_csr_hgatp_vmid),
    .csr_mbmc_bme        (core_csr_mbmc_bme),
    .csr_mbmc_cmode      (core_csr_mbmc_cmode),
    .csr_priv_virt       (core_csr_priv_virt),
    .req_valid           (core_req_valid),
    .req_vpn             (core_req_vpn),
    .req_s2xlate         (core_req_s2xlate),
    .resp_hit            (core_resp_hit),
    .resp_ppn            (core_resp_ppn),
    .resp_pbmt           (core_resp_pbmt),
    .resp_g_pbmt         (core_resp_g_pbmt),
    .resp_perm_pf        (core_resp_perm_pf),
    .resp_perm_af        (core_resp_perm_af),
    .resp_perm_v         (core_resp_perm_v),
    .resp_perm_d         (core_resp_perm_d),
    .resp_perm_a         (core_resp_perm_a),
    .resp_perm_g         (core_resp_perm_g),
    .resp_perm_u         (core_resp_perm_u),
    .resp_perm_x         (core_resp_perm_x),
    .resp_perm_w         (core_resp_perm_w),
    .resp_perm_r         (core_resp_perm_r),
    .resp_g_perm_pf      (core_resp_g_perm_pf),
    .resp_g_perm_af      (core_resp_g_perm_af),
    .resp_g_perm_d       (core_resp_g_perm_d),
    .resp_g_perm_a       (core_resp_g_perm_a),
    .resp_g_perm_x       (core_resp_g_perm_x),
    .resp_g_perm_w       (core_resp_g_perm_w),
    .resp_g_perm_r       (core_resp_g_perm_r),
    .resp_s2xlate        (core_resp_s2xlate),
    .w_valid             (core_w_valid),
    .w_way               (core_w_way),
    .w_s2xlate           (core_w_s2xlate),
    .w_s1_entry_tag      (core_w_s1_entry_tag),
    .w_s1_entry_asid     (core_w_s1_entry_asid),
    .w_s1_entry_vmid     (core_w_s1_entry_vmid),
    .w_s1_entry_n        (core_w_s1_entry_n),
    .w_s1_entry_pbmt     (core_w_s1_entry_pbmt),
    .w_s1_entry_perm_d   (core_w_s1_entry_perm_d),
    .w_s1_entry_perm_a   (core_w_s1_entry_perm_a),
    .w_s1_entry_perm_g   (core_w_s1_entry_perm_g),
    .w_s1_entry_perm_u   (core_w_s1_entry_perm_u),
    .w_s1_entry_perm_x   (core_w_s1_entry_perm_x),
    .w_s1_entry_perm_w   (core_w_s1_entry_perm_w),
    .w_s1_entry_perm_r   (core_w_s1_entry_perm_r),
    .w_s1_entry_level    (core_w_s1_entry_level),
    .w_s1_entry_v        (core_w_s1_entry_v),
    .w_s1_entry_ppn      (core_w_s1_entry_ppn),
    .w_s1_ppn_low        (core_w_s1_ppn_low),
    .w_s1_valididx       (core_w_s1_valididx),
    .w_s1_pteidx         (core_w_s1_pteidx),
    .w_s1_pf             (core_w_s1_pf),
    .w_s1_af             (core_w_s1_af),
    .w_s2_entry_tag      (core_w_s2_entry_tag),
    .w_s2_entry_vmid     (core_w_s2_entry_vmid),
    .w_s2_entry_n        (core_w_s2_entry_n),
    .w_s2_entry_pbmt     (core_w_s2_entry_pbmt),
    .w_s2_entry_ppn      (core_w_s2_entry_ppn),
    .w_s2_entry_perm_d   (core_w_s2_entry_perm_d),
    .w_s2_entry_perm_a   (core_w_s2_entry_perm_a),
    .w_s2_entry_perm_g   (core_w_s2_entry_perm_g),
    .w_s2_entry_perm_u   (core_w_s2_entry_perm_u),
    .w_s2_entry_perm_x   (core_w_s2_entry_perm_x),
    .w_s2_entry_perm_w   (core_w_s2_entry_perm_w),
    .w_s2_entry_perm_r   (core_w_s2_entry_perm_r),
    .w_s2_entry_level    (core_w_s2_entry_level),
    .w_s2_gpf            (core_w_s2_gpf),
    .w_s2_gaf            (core_w_s2_gaf),
    .access_touch_valid  (core_access_touch_valid),
    .access_touch_way    (core_access_touch_way)
  );

  // ---- 输出：核 -> golden 扁平端口 ----
  // 同一个核信号可能接到多个 golden 端口（nDups 复制），也可能一个都不接
  //（该字段在本变体里被 firtool 消掉了）——两种情况都在上面的变体说明里交代过。
  assign io_r_resp_0_bits_hit = core_resp_hit[0];
  assign io_r_resp_0_bits_ppn_0 = core_resp_ppn[0];
  assign io_r_resp_0_bits_pbmt_0 = core_resp_pbmt[0];
  assign io_r_resp_0_bits_g_pbmt_0 = core_resp_g_pbmt[0];
  assign io_r_resp_0_bits_perm_0_pf = core_resp_perm_pf[0];
  assign io_r_resp_0_bits_perm_0_af = core_resp_perm_af[0];
  assign io_r_resp_0_bits_perm_0_v = core_resp_perm_v[0];
  assign io_r_resp_0_bits_perm_0_a = core_resp_perm_a[0];
  assign io_r_resp_0_bits_perm_0_u = core_resp_perm_u[0];
  assign io_r_resp_0_bits_perm_0_x = core_resp_perm_x[0];
  assign io_r_resp_0_bits_perm_0_w = core_resp_perm_w[0];
  assign io_r_resp_0_bits_perm_0_r = core_resp_perm_r[0];
  assign io_r_resp_0_bits_g_perm_0_pf = core_resp_g_perm_pf[0];
  assign io_r_resp_0_bits_g_perm_0_af = core_resp_g_perm_af[0];
  assign io_r_resp_0_bits_g_perm_0_a = core_resp_g_perm_a[0];
  assign io_r_resp_0_bits_g_perm_0_x = core_resp_g_perm_x[0];
  assign io_r_resp_0_bits_s2xlate_0 = core_resp_s2xlate[0];
  assign io_r_resp_1_bits_hit = core_resp_hit[1];
  assign io_r_resp_1_bits_ppn_0 = core_resp_ppn[1];
  assign io_r_resp_1_bits_pbmt_0 = core_resp_pbmt[1];
  assign io_r_resp_1_bits_g_pbmt_0 = core_resp_g_pbmt[1];
  assign io_r_resp_1_bits_perm_0_pf = core_resp_perm_pf[1];
  assign io_r_resp_1_bits_perm_0_af = core_resp_perm_af[1];
  assign io_r_resp_1_bits_perm_0_v = core_resp_perm_v[1];
  assign io_r_resp_1_bits_perm_0_a = core_resp_perm_a[1];
  assign io_r_resp_1_bits_perm_0_u = core_resp_perm_u[1];
  assign io_r_resp_1_bits_perm_0_x = core_resp_perm_x[1];
  assign io_r_resp_1_bits_perm_0_w = core_resp_perm_w[1];
  assign io_r_resp_1_bits_perm_0_r = core_resp_perm_r[1];
  assign io_r_resp_1_bits_g_perm_0_pf = core_resp_g_perm_pf[1];
  assign io_r_resp_1_bits_g_perm_0_af = core_resp_g_perm_af[1];
  assign io_r_resp_1_bits_g_perm_0_a = core_resp_g_perm_a[1];
  assign io_r_resp_1_bits_g_perm_0_x = core_resp_g_perm_x[1];
  assign io_r_resp_1_bits_s2xlate_0 = core_resp_s2xlate[1];
  assign io_r_resp_2_bits_hit = core_resp_hit[2];
  assign io_r_resp_2_bits_ppn_0 = core_resp_ppn[2];
  assign io_r_resp_2_bits_pbmt_0 = core_resp_pbmt[2];
  assign io_r_resp_2_bits_g_pbmt_0 = core_resp_g_pbmt[2];
  assign io_r_resp_2_bits_perm_0_pf = core_resp_perm_pf[2];
  assign io_r_resp_2_bits_perm_0_af = core_resp_perm_af[2];
  assign io_r_resp_2_bits_perm_0_v = core_resp_perm_v[2];
  assign io_r_resp_2_bits_perm_0_a = core_resp_perm_a[2];
  assign io_r_resp_2_bits_perm_0_u = core_resp_perm_u[2];
  assign io_r_resp_2_bits_perm_0_x = core_resp_perm_x[2];
  assign io_r_resp_2_bits_perm_0_w = core_resp_perm_w[2];
  assign io_r_resp_2_bits_perm_0_r = core_resp_perm_r[2];
  assign io_r_resp_2_bits_g_perm_0_pf = core_resp_g_perm_pf[2];
  assign io_r_resp_2_bits_g_perm_0_af = core_resp_g_perm_af[2];
  assign io_r_resp_2_bits_g_perm_0_a = core_resp_g_perm_a[2];
  assign io_r_resp_2_bits_g_perm_0_x = core_resp_g_perm_x[2];
  assign io_r_resp_2_bits_s2xlate_0 = core_resp_s2xlate[2];
  assign io_access_0_touch_ways_valid = core_access_touch_valid[0];
  assign io_access_0_touch_ways_bits = core_access_touch_way[0];
  assign io_access_1_touch_ways_valid = core_access_touch_valid[1];
  assign io_access_1_touch_ways_bits = core_access_touch_way[1];
  assign io_access_2_touch_ways_valid = core_access_touch_valid[2];
  assign io_access_2_touch_ways_bits = core_access_touch_way[2];

endmodule
// END GENERATED(tlbfa-wrapper)
