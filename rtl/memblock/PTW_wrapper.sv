// 自动生成：scripts/gen_ptw.py —— 仅机械端口适配，核心逻辑在 xs_PTW_core
module PTW import xs_ptw_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  [3:0] io_csr_satp_mode,
  input  [15:0] io_csr_satp_asid,
  input  [43:0] io_csr_satp_ppn,
  input  io_csr_satp_changed,
  input  [3:0] io_csr_vsatp_mode,
  input  [15:0] io_csr_vsatp_asid,
  input  [43:0] io_csr_vsatp_ppn,
  input  io_csr_vsatp_changed,
  input  [3:0] io_csr_hgatp_mode,
  input  [15:0] io_csr_hgatp_vmid,
  input  io_csr_hgatp_changed,
  input  io_csr_priv_mxr,
  input  io_csr_mPBMTE,
  input  io_csr_hPBMTE,
  output io_req_ready,
  input  io_req_valid,
  input  [37:0] io_req_bits_req_info_vpn,
  input  [1:0] io_req_bits_req_info_s2xlate,
  input  [1:0] io_req_bits_req_info_source,
  input  io_req_bits_l3Hit,
  input  io_req_bits_l2Hit,
  input  [43:0] io_req_bits_ppn,
  input  io_req_bits_stage1Hit,
  input  [34:0] io_req_bits_stage1_entry_0_tag,
  input  [15:0] io_req_bits_stage1_entry_0_asid,
  input  [13:0] io_req_bits_stage1_entry_0_vmid,
  input  io_req_bits_stage1_entry_0_n,
  input  [1:0] io_req_bits_stage1_entry_0_pbmt,
  input  io_req_bits_stage1_entry_0_perm_d,
  input  io_req_bits_stage1_entry_0_perm_a,
  input  io_req_bits_stage1_entry_0_perm_g,
  input  io_req_bits_stage1_entry_0_perm_u,
  input  io_req_bits_stage1_entry_0_perm_x,
  input  io_req_bits_stage1_entry_0_perm_w,
  input  io_req_bits_stage1_entry_0_perm_r,
  input  [1:0] io_req_bits_stage1_entry_0_level,
  input  io_req_bits_stage1_entry_0_v,
  input  [40:0] io_req_bits_stage1_entry_0_ppn,
  input  [2:0] io_req_bits_stage1_entry_0_ppn_low,
  input  io_req_bits_stage1_entry_0_pf,
  input  [34:0] io_req_bits_stage1_entry_1_tag,
  input  [15:0] io_req_bits_stage1_entry_1_asid,
  input  [13:0] io_req_bits_stage1_entry_1_vmid,
  input  io_req_bits_stage1_entry_1_n,
  input  [1:0] io_req_bits_stage1_entry_1_pbmt,
  input  io_req_bits_stage1_entry_1_perm_d,
  input  io_req_bits_stage1_entry_1_perm_a,
  input  io_req_bits_stage1_entry_1_perm_g,
  input  io_req_bits_stage1_entry_1_perm_u,
  input  io_req_bits_stage1_entry_1_perm_x,
  input  io_req_bits_stage1_entry_1_perm_w,
  input  io_req_bits_stage1_entry_1_perm_r,
  input  [1:0] io_req_bits_stage1_entry_1_level,
  input  io_req_bits_stage1_entry_1_v,
  input  [40:0] io_req_bits_stage1_entry_1_ppn,
  input  [2:0] io_req_bits_stage1_entry_1_ppn_low,
  input  io_req_bits_stage1_entry_1_pf,
  input  [34:0] io_req_bits_stage1_entry_2_tag,
  input  [15:0] io_req_bits_stage1_entry_2_asid,
  input  [13:0] io_req_bits_stage1_entry_2_vmid,
  input  io_req_bits_stage1_entry_2_n,
  input  [1:0] io_req_bits_stage1_entry_2_pbmt,
  input  io_req_bits_stage1_entry_2_perm_d,
  input  io_req_bits_stage1_entry_2_perm_a,
  input  io_req_bits_stage1_entry_2_perm_g,
  input  io_req_bits_stage1_entry_2_perm_u,
  input  io_req_bits_stage1_entry_2_perm_x,
  input  io_req_bits_stage1_entry_2_perm_w,
  input  io_req_bits_stage1_entry_2_perm_r,
  input  [1:0] io_req_bits_stage1_entry_2_level,
  input  io_req_bits_stage1_entry_2_v,
  input  [40:0] io_req_bits_stage1_entry_2_ppn,
  input  [2:0] io_req_bits_stage1_entry_2_ppn_low,
  input  io_req_bits_stage1_entry_2_pf,
  input  [34:0] io_req_bits_stage1_entry_3_tag,
  input  [15:0] io_req_bits_stage1_entry_3_asid,
  input  [13:0] io_req_bits_stage1_entry_3_vmid,
  input  io_req_bits_stage1_entry_3_n,
  input  [1:0] io_req_bits_stage1_entry_3_pbmt,
  input  io_req_bits_stage1_entry_3_perm_d,
  input  io_req_bits_stage1_entry_3_perm_a,
  input  io_req_bits_stage1_entry_3_perm_g,
  input  io_req_bits_stage1_entry_3_perm_u,
  input  io_req_bits_stage1_entry_3_perm_x,
  input  io_req_bits_stage1_entry_3_perm_w,
  input  io_req_bits_stage1_entry_3_perm_r,
  input  [1:0] io_req_bits_stage1_entry_3_level,
  input  io_req_bits_stage1_entry_3_v,
  input  [40:0] io_req_bits_stage1_entry_3_ppn,
  input  [2:0] io_req_bits_stage1_entry_3_ppn_low,
  input  io_req_bits_stage1_entry_3_pf,
  input  [34:0] io_req_bits_stage1_entry_4_tag,
  input  [15:0] io_req_bits_stage1_entry_4_asid,
  input  [13:0] io_req_bits_stage1_entry_4_vmid,
  input  io_req_bits_stage1_entry_4_n,
  input  [1:0] io_req_bits_stage1_entry_4_pbmt,
  input  io_req_bits_stage1_entry_4_perm_d,
  input  io_req_bits_stage1_entry_4_perm_a,
  input  io_req_bits_stage1_entry_4_perm_g,
  input  io_req_bits_stage1_entry_4_perm_u,
  input  io_req_bits_stage1_entry_4_perm_x,
  input  io_req_bits_stage1_entry_4_perm_w,
  input  io_req_bits_stage1_entry_4_perm_r,
  input  [1:0] io_req_bits_stage1_entry_4_level,
  input  io_req_bits_stage1_entry_4_v,
  input  [40:0] io_req_bits_stage1_entry_4_ppn,
  input  [2:0] io_req_bits_stage1_entry_4_ppn_low,
  input  io_req_bits_stage1_entry_4_pf,
  input  [34:0] io_req_bits_stage1_entry_5_tag,
  input  [15:0] io_req_bits_stage1_entry_5_asid,
  input  [13:0] io_req_bits_stage1_entry_5_vmid,
  input  io_req_bits_stage1_entry_5_n,
  input  [1:0] io_req_bits_stage1_entry_5_pbmt,
  input  io_req_bits_stage1_entry_5_perm_d,
  input  io_req_bits_stage1_entry_5_perm_a,
  input  io_req_bits_stage1_entry_5_perm_g,
  input  io_req_bits_stage1_entry_5_perm_u,
  input  io_req_bits_stage1_entry_5_perm_x,
  input  io_req_bits_stage1_entry_5_perm_w,
  input  io_req_bits_stage1_entry_5_perm_r,
  input  [1:0] io_req_bits_stage1_entry_5_level,
  input  io_req_bits_stage1_entry_5_v,
  input  [40:0] io_req_bits_stage1_entry_5_ppn,
  input  [2:0] io_req_bits_stage1_entry_5_ppn_low,
  input  io_req_bits_stage1_entry_5_pf,
  input  [34:0] io_req_bits_stage1_entry_6_tag,
  input  [15:0] io_req_bits_stage1_entry_6_asid,
  input  [13:0] io_req_bits_stage1_entry_6_vmid,
  input  io_req_bits_stage1_entry_6_n,
  input  [1:0] io_req_bits_stage1_entry_6_pbmt,
  input  io_req_bits_stage1_entry_6_perm_d,
  input  io_req_bits_stage1_entry_6_perm_a,
  input  io_req_bits_stage1_entry_6_perm_g,
  input  io_req_bits_stage1_entry_6_perm_u,
  input  io_req_bits_stage1_entry_6_perm_x,
  input  io_req_bits_stage1_entry_6_perm_w,
  input  io_req_bits_stage1_entry_6_perm_r,
  input  [1:0] io_req_bits_stage1_entry_6_level,
  input  io_req_bits_stage1_entry_6_v,
  input  [40:0] io_req_bits_stage1_entry_6_ppn,
  input  [2:0] io_req_bits_stage1_entry_6_ppn_low,
  input  io_req_bits_stage1_entry_6_pf,
  input  [34:0] io_req_bits_stage1_entry_7_tag,
  input  [15:0] io_req_bits_stage1_entry_7_asid,
  input  [13:0] io_req_bits_stage1_entry_7_vmid,
  input  io_req_bits_stage1_entry_7_n,
  input  [1:0] io_req_bits_stage1_entry_7_pbmt,
  input  io_req_bits_stage1_entry_7_perm_d,
  input  io_req_bits_stage1_entry_7_perm_a,
  input  io_req_bits_stage1_entry_7_perm_g,
  input  io_req_bits_stage1_entry_7_perm_u,
  input  io_req_bits_stage1_entry_7_perm_x,
  input  io_req_bits_stage1_entry_7_perm_w,
  input  io_req_bits_stage1_entry_7_perm_r,
  input  [1:0] io_req_bits_stage1_entry_7_level,
  input  io_req_bits_stage1_entry_7_v,
  input  [40:0] io_req_bits_stage1_entry_7_ppn,
  input  [2:0] io_req_bits_stage1_entry_7_ppn_low,
  input  io_req_bits_stage1_entry_7_pf,
  input  io_req_bits_stage1_pteidx_0,
  input  io_req_bits_stage1_pteidx_1,
  input  io_req_bits_stage1_pteidx_2,
  input  io_req_bits_stage1_pteidx_3,
  input  io_req_bits_stage1_pteidx_4,
  input  io_req_bits_stage1_pteidx_5,
  input  io_req_bits_stage1_pteidx_6,
  input  io_req_bits_stage1_pteidx_7,
  input  io_req_bits_stage1_not_super,
  input  io_resp_ready,
  output io_resp_valid,
  output [1:0] io_resp_bits_source,
  output [1:0] io_resp_bits_s2xlate,
  output [34:0] io_resp_bits_resp_entry_0_tag,
  output [15:0] io_resp_bits_resp_entry_0_asid,
  output [13:0] io_resp_bits_resp_entry_0_vmid,
  output io_resp_bits_resp_entry_0_n,
  output [1:0] io_resp_bits_resp_entry_0_pbmt,
  output io_resp_bits_resp_entry_0_perm_d,
  output io_resp_bits_resp_entry_0_perm_a,
  output io_resp_bits_resp_entry_0_perm_g,
  output io_resp_bits_resp_entry_0_perm_u,
  output io_resp_bits_resp_entry_0_perm_x,
  output io_resp_bits_resp_entry_0_perm_w,
  output io_resp_bits_resp_entry_0_perm_r,
  output [1:0] io_resp_bits_resp_entry_0_level,
  output io_resp_bits_resp_entry_0_v,
  output [40:0] io_resp_bits_resp_entry_0_ppn,
  output [2:0] io_resp_bits_resp_entry_0_ppn_low,
  output io_resp_bits_resp_entry_0_af,
  output io_resp_bits_resp_entry_0_pf,
  output [34:0] io_resp_bits_resp_entry_1_tag,
  output [15:0] io_resp_bits_resp_entry_1_asid,
  output [13:0] io_resp_bits_resp_entry_1_vmid,
  output io_resp_bits_resp_entry_1_n,
  output [1:0] io_resp_bits_resp_entry_1_pbmt,
  output io_resp_bits_resp_entry_1_perm_d,
  output io_resp_bits_resp_entry_1_perm_a,
  output io_resp_bits_resp_entry_1_perm_g,
  output io_resp_bits_resp_entry_1_perm_u,
  output io_resp_bits_resp_entry_1_perm_x,
  output io_resp_bits_resp_entry_1_perm_w,
  output io_resp_bits_resp_entry_1_perm_r,
  output [1:0] io_resp_bits_resp_entry_1_level,
  output io_resp_bits_resp_entry_1_v,
  output [40:0] io_resp_bits_resp_entry_1_ppn,
  output [2:0] io_resp_bits_resp_entry_1_ppn_low,
  output io_resp_bits_resp_entry_1_af,
  output io_resp_bits_resp_entry_1_pf,
  output [34:0] io_resp_bits_resp_entry_2_tag,
  output [15:0] io_resp_bits_resp_entry_2_asid,
  output [13:0] io_resp_bits_resp_entry_2_vmid,
  output io_resp_bits_resp_entry_2_n,
  output [1:0] io_resp_bits_resp_entry_2_pbmt,
  output io_resp_bits_resp_entry_2_perm_d,
  output io_resp_bits_resp_entry_2_perm_a,
  output io_resp_bits_resp_entry_2_perm_g,
  output io_resp_bits_resp_entry_2_perm_u,
  output io_resp_bits_resp_entry_2_perm_x,
  output io_resp_bits_resp_entry_2_perm_w,
  output io_resp_bits_resp_entry_2_perm_r,
  output [1:0] io_resp_bits_resp_entry_2_level,
  output io_resp_bits_resp_entry_2_v,
  output [40:0] io_resp_bits_resp_entry_2_ppn,
  output [2:0] io_resp_bits_resp_entry_2_ppn_low,
  output io_resp_bits_resp_entry_2_af,
  output io_resp_bits_resp_entry_2_pf,
  output [34:0] io_resp_bits_resp_entry_3_tag,
  output [15:0] io_resp_bits_resp_entry_3_asid,
  output [13:0] io_resp_bits_resp_entry_3_vmid,
  output io_resp_bits_resp_entry_3_n,
  output [1:0] io_resp_bits_resp_entry_3_pbmt,
  output io_resp_bits_resp_entry_3_perm_d,
  output io_resp_bits_resp_entry_3_perm_a,
  output io_resp_bits_resp_entry_3_perm_g,
  output io_resp_bits_resp_entry_3_perm_u,
  output io_resp_bits_resp_entry_3_perm_x,
  output io_resp_bits_resp_entry_3_perm_w,
  output io_resp_bits_resp_entry_3_perm_r,
  output [1:0] io_resp_bits_resp_entry_3_level,
  output io_resp_bits_resp_entry_3_v,
  output [40:0] io_resp_bits_resp_entry_3_ppn,
  output [2:0] io_resp_bits_resp_entry_3_ppn_low,
  output io_resp_bits_resp_entry_3_af,
  output io_resp_bits_resp_entry_3_pf,
  output [34:0] io_resp_bits_resp_entry_4_tag,
  output [15:0] io_resp_bits_resp_entry_4_asid,
  output [13:0] io_resp_bits_resp_entry_4_vmid,
  output io_resp_bits_resp_entry_4_n,
  output [1:0] io_resp_bits_resp_entry_4_pbmt,
  output io_resp_bits_resp_entry_4_perm_d,
  output io_resp_bits_resp_entry_4_perm_a,
  output io_resp_bits_resp_entry_4_perm_g,
  output io_resp_bits_resp_entry_4_perm_u,
  output io_resp_bits_resp_entry_4_perm_x,
  output io_resp_bits_resp_entry_4_perm_w,
  output io_resp_bits_resp_entry_4_perm_r,
  output [1:0] io_resp_bits_resp_entry_4_level,
  output io_resp_bits_resp_entry_4_v,
  output [40:0] io_resp_bits_resp_entry_4_ppn,
  output [2:0] io_resp_bits_resp_entry_4_ppn_low,
  output io_resp_bits_resp_entry_4_af,
  output io_resp_bits_resp_entry_4_pf,
  output [34:0] io_resp_bits_resp_entry_5_tag,
  output [15:0] io_resp_bits_resp_entry_5_asid,
  output [13:0] io_resp_bits_resp_entry_5_vmid,
  output io_resp_bits_resp_entry_5_n,
  output [1:0] io_resp_bits_resp_entry_5_pbmt,
  output io_resp_bits_resp_entry_5_perm_d,
  output io_resp_bits_resp_entry_5_perm_a,
  output io_resp_bits_resp_entry_5_perm_g,
  output io_resp_bits_resp_entry_5_perm_u,
  output io_resp_bits_resp_entry_5_perm_x,
  output io_resp_bits_resp_entry_5_perm_w,
  output io_resp_bits_resp_entry_5_perm_r,
  output [1:0] io_resp_bits_resp_entry_5_level,
  output io_resp_bits_resp_entry_5_v,
  output [40:0] io_resp_bits_resp_entry_5_ppn,
  output [2:0] io_resp_bits_resp_entry_5_ppn_low,
  output io_resp_bits_resp_entry_5_af,
  output io_resp_bits_resp_entry_5_pf,
  output [34:0] io_resp_bits_resp_entry_6_tag,
  output [15:0] io_resp_bits_resp_entry_6_asid,
  output [13:0] io_resp_bits_resp_entry_6_vmid,
  output io_resp_bits_resp_entry_6_n,
  output [1:0] io_resp_bits_resp_entry_6_pbmt,
  output io_resp_bits_resp_entry_6_perm_d,
  output io_resp_bits_resp_entry_6_perm_a,
  output io_resp_bits_resp_entry_6_perm_g,
  output io_resp_bits_resp_entry_6_perm_u,
  output io_resp_bits_resp_entry_6_perm_x,
  output io_resp_bits_resp_entry_6_perm_w,
  output io_resp_bits_resp_entry_6_perm_r,
  output [1:0] io_resp_bits_resp_entry_6_level,
  output io_resp_bits_resp_entry_6_v,
  output [40:0] io_resp_bits_resp_entry_6_ppn,
  output [2:0] io_resp_bits_resp_entry_6_ppn_low,
  output io_resp_bits_resp_entry_6_af,
  output io_resp_bits_resp_entry_6_pf,
  output [34:0] io_resp_bits_resp_entry_7_tag,
  output [15:0] io_resp_bits_resp_entry_7_asid,
  output [13:0] io_resp_bits_resp_entry_7_vmid,
  output io_resp_bits_resp_entry_7_n,
  output [1:0] io_resp_bits_resp_entry_7_pbmt,
  output io_resp_bits_resp_entry_7_perm_d,
  output io_resp_bits_resp_entry_7_perm_a,
  output io_resp_bits_resp_entry_7_perm_g,
  output io_resp_bits_resp_entry_7_perm_u,
  output io_resp_bits_resp_entry_7_perm_x,
  output io_resp_bits_resp_entry_7_perm_w,
  output io_resp_bits_resp_entry_7_perm_r,
  output [1:0] io_resp_bits_resp_entry_7_level,
  output io_resp_bits_resp_entry_7_v,
  output [40:0] io_resp_bits_resp_entry_7_ppn,
  output [2:0] io_resp_bits_resp_entry_7_ppn_low,
  output io_resp_bits_resp_entry_7_af,
  output io_resp_bits_resp_entry_7_pf,
  output io_resp_bits_resp_pteidx_0,
  output io_resp_bits_resp_pteidx_1,
  output io_resp_bits_resp_pteidx_2,
  output io_resp_bits_resp_pteidx_3,
  output io_resp_bits_resp_pteidx_4,
  output io_resp_bits_resp_pteidx_5,
  output io_resp_bits_resp_pteidx_6,
  output io_resp_bits_resp_pteidx_7,
  output io_resp_bits_resp_not_super,
  output [37:0] io_resp_bits_h_resp_entry_tag,
  output [13:0] io_resp_bits_h_resp_entry_vmid,
  output io_resp_bits_h_resp_entry_n,
  output [1:0] io_resp_bits_h_resp_entry_pbmt,
  output [37:0] io_resp_bits_h_resp_entry_ppn,
  output io_resp_bits_h_resp_entry_perm_d,
  output io_resp_bits_h_resp_entry_perm_a,
  output io_resp_bits_h_resp_entry_perm_g,
  output io_resp_bits_h_resp_entry_perm_u,
  output io_resp_bits_h_resp_entry_perm_x,
  output io_resp_bits_h_resp_entry_perm_w,
  output io_resp_bits_h_resp_entry_perm_r,
  output [1:0] io_resp_bits_h_resp_entry_level,
  output io_resp_bits_h_resp_gpf,
  output io_resp_bits_h_resp_gaf,
  input  io_llptw_ready,
  output io_llptw_valid,
  output [37:0] io_llptw_bits_req_info_vpn,
  output [1:0] io_llptw_bits_req_info_s2xlate,
  output [1:0] io_llptw_bits_req_info_source,
  input  io_hptw_req_ready,
  output io_hptw_req_valid,
  output [1:0] io_hptw_req_bits_source,
  output [43:0] io_hptw_req_bits_gvpn,
  input  io_hptw_resp_valid,
  input  [37:0] io_hptw_resp_bits_h_resp_entry_tag,
  input  [13:0] io_hptw_resp_bits_h_resp_entry_vmid,
  input  io_hptw_resp_bits_h_resp_entry_n,
  input  [1:0] io_hptw_resp_bits_h_resp_entry_pbmt,
  input  [37:0] io_hptw_resp_bits_h_resp_entry_ppn,
  input  io_hptw_resp_bits_h_resp_entry_perm_d,
  input  io_hptw_resp_bits_h_resp_entry_perm_a,
  input  io_hptw_resp_bits_h_resp_entry_perm_g,
  input  io_hptw_resp_bits_h_resp_entry_perm_u,
  input  io_hptw_resp_bits_h_resp_entry_perm_x,
  input  io_hptw_resp_bits_h_resp_entry_perm_w,
  input  io_hptw_resp_bits_h_resp_entry_perm_r,
  input  [1:0] io_hptw_resp_bits_h_resp_entry_level,
  input  io_hptw_resp_bits_h_resp_gpf,
  input  io_hptw_resp_bits_h_resp_gaf,
  input  io_mem_req_ready,
  output io_mem_req_valid,
  output [47:0] io_mem_req_bits_addr,
  input  io_mem_resp_valid,
  input  [63:0] io_mem_resp_bits,
  input  io_mem_mask,
  output [47:0] io_pmp_req_bits_addr,
  input  io_pmp_resp_ld,
  input  io_pmp_resp_mmio,
  output [37:0] io_refill_req_info_vpn,
  output [1:0] io_refill_req_info_s2xlate,
  output [1:0] io_refill_req_info_source,
  output [1:0] io_refill_level,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value
);

  ptw_csr_t csr_bus;
  ptw_req_info_t req_info_bus;
  ptw_merge_resp_t stage1_bus;
  ptw_merge_resp_t resp_merge;
  hptw_resp_t hptw_resp_in;
  hptw_resp_t resp_h;
  ptw_req_info_t llptw_req_info;
  ptw_req_info_t refill_req_info;
  logic [6:0][5:0] perf_bus;

  assign csr_bus.satp_mode = io_csr_satp_mode;
  assign csr_bus.satp_asid = io_csr_satp_asid;
  assign csr_bus.satp_ppn = io_csr_satp_ppn;
  assign csr_bus.satp_changed = io_csr_satp_changed;
  assign csr_bus.vsatp_mode = io_csr_vsatp_mode;
  assign csr_bus.vsatp_asid = io_csr_vsatp_asid;
  assign csr_bus.vsatp_ppn = io_csr_vsatp_ppn;
  assign csr_bus.vsatp_changed = io_csr_vsatp_changed;
  assign csr_bus.hgatp_mode = io_csr_hgatp_mode;
  assign csr_bus.hgatp_vmid_raw = io_csr_hgatp_vmid;
  assign csr_bus.hgatp_changed = io_csr_hgatp_changed;
  assign csr_bus.priv_mxr = io_csr_priv_mxr;
  assign csr_bus.m_pbmt_enable = io_csr_mPBMTE;
  assign csr_bus.h_pbmt_enable = io_csr_hPBMTE;

  assign req_info_bus.vpn = io_req_bits_req_info_vpn;
  assign req_info_bus.s2xlate = io_req_bits_req_info_s2xlate;
  assign req_info_bus.source = io_req_bits_req_info_source;
  assign stage1_bus.entry[0].tag = io_req_bits_stage1_entry_0_tag;
  assign stage1_bus.entry[0].asid = io_req_bits_stage1_entry_0_asid;
  assign stage1_bus.entry[0].vmid = io_req_bits_stage1_entry_0_vmid;
  assign stage1_bus.entry[0].n = io_req_bits_stage1_entry_0_n;
  assign stage1_bus.entry[0].pbmt = io_req_bits_stage1_entry_0_pbmt;
  assign stage1_bus.entry[0].perm.d = io_req_bits_stage1_entry_0_perm_d;
  assign stage1_bus.entry[0].perm.a = io_req_bits_stage1_entry_0_perm_a;
  assign stage1_bus.entry[0].perm.g = io_req_bits_stage1_entry_0_perm_g;
  assign stage1_bus.entry[0].perm.u = io_req_bits_stage1_entry_0_perm_u;
  assign stage1_bus.entry[0].perm.x = io_req_bits_stage1_entry_0_perm_x;
  assign stage1_bus.entry[0].perm.w = io_req_bits_stage1_entry_0_perm_w;
  assign stage1_bus.entry[0].perm.r = io_req_bits_stage1_entry_0_perm_r;
  assign stage1_bus.entry[0].level = io_req_bits_stage1_entry_0_level;
  assign stage1_bus.entry[0].v = io_req_bits_stage1_entry_0_v;
  assign stage1_bus.entry[0].ppn = io_req_bits_stage1_entry_0_ppn;
  assign stage1_bus.entry[0].ppn_low = io_req_bits_stage1_entry_0_ppn_low;
  assign stage1_bus.entry[0].pf = io_req_bits_stage1_entry_0_pf;
  assign stage1_bus.entry[0].af = 1'b0;
  assign stage1_bus.entry[1].tag = io_req_bits_stage1_entry_1_tag;
  assign stage1_bus.entry[1].asid = io_req_bits_stage1_entry_1_asid;
  assign stage1_bus.entry[1].vmid = io_req_bits_stage1_entry_1_vmid;
  assign stage1_bus.entry[1].n = io_req_bits_stage1_entry_1_n;
  assign stage1_bus.entry[1].pbmt = io_req_bits_stage1_entry_1_pbmt;
  assign stage1_bus.entry[1].perm.d = io_req_bits_stage1_entry_1_perm_d;
  assign stage1_bus.entry[1].perm.a = io_req_bits_stage1_entry_1_perm_a;
  assign stage1_bus.entry[1].perm.g = io_req_bits_stage1_entry_1_perm_g;
  assign stage1_bus.entry[1].perm.u = io_req_bits_stage1_entry_1_perm_u;
  assign stage1_bus.entry[1].perm.x = io_req_bits_stage1_entry_1_perm_x;
  assign stage1_bus.entry[1].perm.w = io_req_bits_stage1_entry_1_perm_w;
  assign stage1_bus.entry[1].perm.r = io_req_bits_stage1_entry_1_perm_r;
  assign stage1_bus.entry[1].level = io_req_bits_stage1_entry_1_level;
  assign stage1_bus.entry[1].v = io_req_bits_stage1_entry_1_v;
  assign stage1_bus.entry[1].ppn = io_req_bits_stage1_entry_1_ppn;
  assign stage1_bus.entry[1].ppn_low = io_req_bits_stage1_entry_1_ppn_low;
  assign stage1_bus.entry[1].pf = io_req_bits_stage1_entry_1_pf;
  assign stage1_bus.entry[1].af = 1'b0;
  assign stage1_bus.entry[2].tag = io_req_bits_stage1_entry_2_tag;
  assign stage1_bus.entry[2].asid = io_req_bits_stage1_entry_2_asid;
  assign stage1_bus.entry[2].vmid = io_req_bits_stage1_entry_2_vmid;
  assign stage1_bus.entry[2].n = io_req_bits_stage1_entry_2_n;
  assign stage1_bus.entry[2].pbmt = io_req_bits_stage1_entry_2_pbmt;
  assign stage1_bus.entry[2].perm.d = io_req_bits_stage1_entry_2_perm_d;
  assign stage1_bus.entry[2].perm.a = io_req_bits_stage1_entry_2_perm_a;
  assign stage1_bus.entry[2].perm.g = io_req_bits_stage1_entry_2_perm_g;
  assign stage1_bus.entry[2].perm.u = io_req_bits_stage1_entry_2_perm_u;
  assign stage1_bus.entry[2].perm.x = io_req_bits_stage1_entry_2_perm_x;
  assign stage1_bus.entry[2].perm.w = io_req_bits_stage1_entry_2_perm_w;
  assign stage1_bus.entry[2].perm.r = io_req_bits_stage1_entry_2_perm_r;
  assign stage1_bus.entry[2].level = io_req_bits_stage1_entry_2_level;
  assign stage1_bus.entry[2].v = io_req_bits_stage1_entry_2_v;
  assign stage1_bus.entry[2].ppn = io_req_bits_stage1_entry_2_ppn;
  assign stage1_bus.entry[2].ppn_low = io_req_bits_stage1_entry_2_ppn_low;
  assign stage1_bus.entry[2].pf = io_req_bits_stage1_entry_2_pf;
  assign stage1_bus.entry[2].af = 1'b0;
  assign stage1_bus.entry[3].tag = io_req_bits_stage1_entry_3_tag;
  assign stage1_bus.entry[3].asid = io_req_bits_stage1_entry_3_asid;
  assign stage1_bus.entry[3].vmid = io_req_bits_stage1_entry_3_vmid;
  assign stage1_bus.entry[3].n = io_req_bits_stage1_entry_3_n;
  assign stage1_bus.entry[3].pbmt = io_req_bits_stage1_entry_3_pbmt;
  assign stage1_bus.entry[3].perm.d = io_req_bits_stage1_entry_3_perm_d;
  assign stage1_bus.entry[3].perm.a = io_req_bits_stage1_entry_3_perm_a;
  assign stage1_bus.entry[3].perm.g = io_req_bits_stage1_entry_3_perm_g;
  assign stage1_bus.entry[3].perm.u = io_req_bits_stage1_entry_3_perm_u;
  assign stage1_bus.entry[3].perm.x = io_req_bits_stage1_entry_3_perm_x;
  assign stage1_bus.entry[3].perm.w = io_req_bits_stage1_entry_3_perm_w;
  assign stage1_bus.entry[3].perm.r = io_req_bits_stage1_entry_3_perm_r;
  assign stage1_bus.entry[3].level = io_req_bits_stage1_entry_3_level;
  assign stage1_bus.entry[3].v = io_req_bits_stage1_entry_3_v;
  assign stage1_bus.entry[3].ppn = io_req_bits_stage1_entry_3_ppn;
  assign stage1_bus.entry[3].ppn_low = io_req_bits_stage1_entry_3_ppn_low;
  assign stage1_bus.entry[3].pf = io_req_bits_stage1_entry_3_pf;
  assign stage1_bus.entry[3].af = 1'b0;
  assign stage1_bus.entry[4].tag = io_req_bits_stage1_entry_4_tag;
  assign stage1_bus.entry[4].asid = io_req_bits_stage1_entry_4_asid;
  assign stage1_bus.entry[4].vmid = io_req_bits_stage1_entry_4_vmid;
  assign stage1_bus.entry[4].n = io_req_bits_stage1_entry_4_n;
  assign stage1_bus.entry[4].pbmt = io_req_bits_stage1_entry_4_pbmt;
  assign stage1_bus.entry[4].perm.d = io_req_bits_stage1_entry_4_perm_d;
  assign stage1_bus.entry[4].perm.a = io_req_bits_stage1_entry_4_perm_a;
  assign stage1_bus.entry[4].perm.g = io_req_bits_stage1_entry_4_perm_g;
  assign stage1_bus.entry[4].perm.u = io_req_bits_stage1_entry_4_perm_u;
  assign stage1_bus.entry[4].perm.x = io_req_bits_stage1_entry_4_perm_x;
  assign stage1_bus.entry[4].perm.w = io_req_bits_stage1_entry_4_perm_w;
  assign stage1_bus.entry[4].perm.r = io_req_bits_stage1_entry_4_perm_r;
  assign stage1_bus.entry[4].level = io_req_bits_stage1_entry_4_level;
  assign stage1_bus.entry[4].v = io_req_bits_stage1_entry_4_v;
  assign stage1_bus.entry[4].ppn = io_req_bits_stage1_entry_4_ppn;
  assign stage1_bus.entry[4].ppn_low = io_req_bits_stage1_entry_4_ppn_low;
  assign stage1_bus.entry[4].pf = io_req_bits_stage1_entry_4_pf;
  assign stage1_bus.entry[4].af = 1'b0;
  assign stage1_bus.entry[5].tag = io_req_bits_stage1_entry_5_tag;
  assign stage1_bus.entry[5].asid = io_req_bits_stage1_entry_5_asid;
  assign stage1_bus.entry[5].vmid = io_req_bits_stage1_entry_5_vmid;
  assign stage1_bus.entry[5].n = io_req_bits_stage1_entry_5_n;
  assign stage1_bus.entry[5].pbmt = io_req_bits_stage1_entry_5_pbmt;
  assign stage1_bus.entry[5].perm.d = io_req_bits_stage1_entry_5_perm_d;
  assign stage1_bus.entry[5].perm.a = io_req_bits_stage1_entry_5_perm_a;
  assign stage1_bus.entry[5].perm.g = io_req_bits_stage1_entry_5_perm_g;
  assign stage1_bus.entry[5].perm.u = io_req_bits_stage1_entry_5_perm_u;
  assign stage1_bus.entry[5].perm.x = io_req_bits_stage1_entry_5_perm_x;
  assign stage1_bus.entry[5].perm.w = io_req_bits_stage1_entry_5_perm_w;
  assign stage1_bus.entry[5].perm.r = io_req_bits_stage1_entry_5_perm_r;
  assign stage1_bus.entry[5].level = io_req_bits_stage1_entry_5_level;
  assign stage1_bus.entry[5].v = io_req_bits_stage1_entry_5_v;
  assign stage1_bus.entry[5].ppn = io_req_bits_stage1_entry_5_ppn;
  assign stage1_bus.entry[5].ppn_low = io_req_bits_stage1_entry_5_ppn_low;
  assign stage1_bus.entry[5].pf = io_req_bits_stage1_entry_5_pf;
  assign stage1_bus.entry[5].af = 1'b0;
  assign stage1_bus.entry[6].tag = io_req_bits_stage1_entry_6_tag;
  assign stage1_bus.entry[6].asid = io_req_bits_stage1_entry_6_asid;
  assign stage1_bus.entry[6].vmid = io_req_bits_stage1_entry_6_vmid;
  assign stage1_bus.entry[6].n = io_req_bits_stage1_entry_6_n;
  assign stage1_bus.entry[6].pbmt = io_req_bits_stage1_entry_6_pbmt;
  assign stage1_bus.entry[6].perm.d = io_req_bits_stage1_entry_6_perm_d;
  assign stage1_bus.entry[6].perm.a = io_req_bits_stage1_entry_6_perm_a;
  assign stage1_bus.entry[6].perm.g = io_req_bits_stage1_entry_6_perm_g;
  assign stage1_bus.entry[6].perm.u = io_req_bits_stage1_entry_6_perm_u;
  assign stage1_bus.entry[6].perm.x = io_req_bits_stage1_entry_6_perm_x;
  assign stage1_bus.entry[6].perm.w = io_req_bits_stage1_entry_6_perm_w;
  assign stage1_bus.entry[6].perm.r = io_req_bits_stage1_entry_6_perm_r;
  assign stage1_bus.entry[6].level = io_req_bits_stage1_entry_6_level;
  assign stage1_bus.entry[6].v = io_req_bits_stage1_entry_6_v;
  assign stage1_bus.entry[6].ppn = io_req_bits_stage1_entry_6_ppn;
  assign stage1_bus.entry[6].ppn_low = io_req_bits_stage1_entry_6_ppn_low;
  assign stage1_bus.entry[6].pf = io_req_bits_stage1_entry_6_pf;
  assign stage1_bus.entry[6].af = 1'b0;
  assign stage1_bus.entry[7].tag = io_req_bits_stage1_entry_7_tag;
  assign stage1_bus.entry[7].asid = io_req_bits_stage1_entry_7_asid;
  assign stage1_bus.entry[7].vmid = io_req_bits_stage1_entry_7_vmid;
  assign stage1_bus.entry[7].n = io_req_bits_stage1_entry_7_n;
  assign stage1_bus.entry[7].pbmt = io_req_bits_stage1_entry_7_pbmt;
  assign stage1_bus.entry[7].perm.d = io_req_bits_stage1_entry_7_perm_d;
  assign stage1_bus.entry[7].perm.a = io_req_bits_stage1_entry_7_perm_a;
  assign stage1_bus.entry[7].perm.g = io_req_bits_stage1_entry_7_perm_g;
  assign stage1_bus.entry[7].perm.u = io_req_bits_stage1_entry_7_perm_u;
  assign stage1_bus.entry[7].perm.x = io_req_bits_stage1_entry_7_perm_x;
  assign stage1_bus.entry[7].perm.w = io_req_bits_stage1_entry_7_perm_w;
  assign stage1_bus.entry[7].perm.r = io_req_bits_stage1_entry_7_perm_r;
  assign stage1_bus.entry[7].level = io_req_bits_stage1_entry_7_level;
  assign stage1_bus.entry[7].v = io_req_bits_stage1_entry_7_v;
  assign stage1_bus.entry[7].ppn = io_req_bits_stage1_entry_7_ppn;
  assign stage1_bus.entry[7].ppn_low = io_req_bits_stage1_entry_7_ppn_low;
  assign stage1_bus.entry[7].pf = io_req_bits_stage1_entry_7_pf;
  assign stage1_bus.entry[7].af = 1'b0;
  assign stage1_bus.pteidx[0] = io_req_bits_stage1_pteidx_0;
  assign stage1_bus.pteidx[1] = io_req_bits_stage1_pteidx_1;
  assign stage1_bus.pteidx[2] = io_req_bits_stage1_pteidx_2;
  assign stage1_bus.pteidx[3] = io_req_bits_stage1_pteidx_3;
  assign stage1_bus.pteidx[4] = io_req_bits_stage1_pteidx_4;
  assign stage1_bus.pteidx[5] = io_req_bits_stage1_pteidx_5;
  assign stage1_bus.pteidx[6] = io_req_bits_stage1_pteidx_6;
  assign stage1_bus.pteidx[7] = io_req_bits_stage1_pteidx_7;
  assign stage1_bus.not_super = io_req_bits_stage1_not_super;
  assign hptw_resp_in.tag = io_hptw_resp_bits_h_resp_entry_tag;
  assign hptw_resp_in.vmid = io_hptw_resp_bits_h_resp_entry_vmid;
  assign hptw_resp_in.n = io_hptw_resp_bits_h_resp_entry_n;
  assign hptw_resp_in.pbmt = io_hptw_resp_bits_h_resp_entry_pbmt;
  assign hptw_resp_in.ppn = io_hptw_resp_bits_h_resp_entry_ppn;
  assign hptw_resp_in.perm.d = io_hptw_resp_bits_h_resp_entry_perm_d;
  assign hptw_resp_in.perm.a = io_hptw_resp_bits_h_resp_entry_perm_a;
  assign hptw_resp_in.perm.g = io_hptw_resp_bits_h_resp_entry_perm_g;
  assign hptw_resp_in.perm.u = io_hptw_resp_bits_h_resp_entry_perm_u;
  assign hptw_resp_in.perm.x = io_hptw_resp_bits_h_resp_entry_perm_x;
  assign hptw_resp_in.perm.w = io_hptw_resp_bits_h_resp_entry_perm_w;
  assign hptw_resp_in.perm.r = io_hptw_resp_bits_h_resp_entry_perm_r;
  assign hptw_resp_in.level = io_hptw_resp_bits_h_resp_entry_level;
  assign hptw_resp_in.gpf = io_hptw_resp_bits_h_resp_gpf;
  assign hptw_resp_in.gaf = io_hptw_resp_bits_h_resp_gaf;

  xs_PTW_core u_core (
    .clock(clock),
    .reset(reset),
    .sfence_valid(io_sfence_valid),
    .csr(csr_bus),
    .req_ready(io_req_ready),
    .req_valid(io_req_valid),
    .req_info(req_info_bus),
    .req_l3_hit(io_req_bits_l3Hit),
    .req_l2_hit(io_req_bits_l2Hit),
    .req_ppn(io_req_bits_ppn),
    .req_stage1_hit(io_req_bits_stage1Hit),
    .req_stage1(stage1_bus),
    .resp_ready(io_resp_ready),
    .resp_valid(io_resp_valid),
    .resp_source(io_resp_bits_source),
    .resp_s2xlate(io_resp_bits_s2xlate),
    .resp_merge(resp_merge),
    .resp_h(resp_h),
    .llptw_ready(io_llptw_ready),
    .llptw_valid(io_llptw_valid),
    .llptw_req_info(llptw_req_info),
    .hptw_req_ready(io_hptw_req_ready),
    .hptw_req_valid(io_hptw_req_valid),
    .hptw_req_source(io_hptw_req_bits_source),
    .hptw_req_gvpn(io_hptw_req_bits_gvpn),
    .hptw_resp_valid(io_hptw_resp_valid),
    .hptw_resp_in(hptw_resp_in),
    .mem_req_ready(io_mem_req_ready),
    .mem_req_valid(io_mem_req_valid),
    .mem_req_addr(io_mem_req_bits_addr),
    .mem_resp_valid(io_mem_resp_valid),
    .mem_resp_bits(io_mem_resp_bits),
    .mem_mask(io_mem_mask),
    .pmp_addr(io_pmp_req_bits_addr),
    .pmp_resp_ld(io_pmp_resp_ld),
    .pmp_resp_mmio(io_pmp_resp_mmio),
    .refill_req_info(refill_req_info),
    .refill_level(io_refill_level),
    .perf(perf_bus)
  );

  assign io_llptw_bits_req_info_vpn = llptw_req_info.vpn;
  assign io_llptw_bits_req_info_s2xlate = llptw_req_info.s2xlate;
  assign io_llptw_bits_req_info_source = llptw_req_info.source;
  assign io_refill_req_info_vpn = refill_req_info.vpn;
  assign io_refill_req_info_s2xlate = refill_req_info.s2xlate;
  assign io_refill_req_info_source = refill_req_info.source;
  assign io_resp_bits_resp_entry_0_tag = resp_merge.entry[0].tag;
  assign io_resp_bits_resp_entry_0_asid = resp_merge.entry[0].asid;
  assign io_resp_bits_resp_entry_0_vmid = resp_merge.entry[0].vmid;
  assign io_resp_bits_resp_entry_0_n = resp_merge.entry[0].n;
  assign io_resp_bits_resp_entry_0_pbmt = resp_merge.entry[0].pbmt;
  assign io_resp_bits_resp_entry_0_perm_d = resp_merge.entry[0].perm.d;
  assign io_resp_bits_resp_entry_0_perm_a = resp_merge.entry[0].perm.a;
  assign io_resp_bits_resp_entry_0_perm_g = resp_merge.entry[0].perm.g;
  assign io_resp_bits_resp_entry_0_perm_u = resp_merge.entry[0].perm.u;
  assign io_resp_bits_resp_entry_0_perm_x = resp_merge.entry[0].perm.x;
  assign io_resp_bits_resp_entry_0_perm_w = resp_merge.entry[0].perm.w;
  assign io_resp_bits_resp_entry_0_perm_r = resp_merge.entry[0].perm.r;
  assign io_resp_bits_resp_entry_0_level = resp_merge.entry[0].level;
  assign io_resp_bits_resp_entry_0_v = resp_merge.entry[0].v;
  assign io_resp_bits_resp_entry_0_ppn = resp_merge.entry[0].ppn;
  assign io_resp_bits_resp_entry_0_ppn_low = resp_merge.entry[0].ppn_low;
  assign io_resp_bits_resp_entry_0_af = resp_merge.entry[0].af;
  assign io_resp_bits_resp_entry_0_pf = resp_merge.entry[0].pf;
  assign io_resp_bits_resp_entry_1_tag = resp_merge.entry[1].tag;
  assign io_resp_bits_resp_entry_1_asid = resp_merge.entry[1].asid;
  assign io_resp_bits_resp_entry_1_vmid = resp_merge.entry[1].vmid;
  assign io_resp_bits_resp_entry_1_n = resp_merge.entry[1].n;
  assign io_resp_bits_resp_entry_1_pbmt = resp_merge.entry[1].pbmt;
  assign io_resp_bits_resp_entry_1_perm_d = resp_merge.entry[1].perm.d;
  assign io_resp_bits_resp_entry_1_perm_a = resp_merge.entry[1].perm.a;
  assign io_resp_bits_resp_entry_1_perm_g = resp_merge.entry[1].perm.g;
  assign io_resp_bits_resp_entry_1_perm_u = resp_merge.entry[1].perm.u;
  assign io_resp_bits_resp_entry_1_perm_x = resp_merge.entry[1].perm.x;
  assign io_resp_bits_resp_entry_1_perm_w = resp_merge.entry[1].perm.w;
  assign io_resp_bits_resp_entry_1_perm_r = resp_merge.entry[1].perm.r;
  assign io_resp_bits_resp_entry_1_level = resp_merge.entry[1].level;
  assign io_resp_bits_resp_entry_1_v = resp_merge.entry[1].v;
  assign io_resp_bits_resp_entry_1_ppn = resp_merge.entry[1].ppn;
  assign io_resp_bits_resp_entry_1_ppn_low = resp_merge.entry[1].ppn_low;
  assign io_resp_bits_resp_entry_1_af = resp_merge.entry[1].af;
  assign io_resp_bits_resp_entry_1_pf = resp_merge.entry[1].pf;
  assign io_resp_bits_resp_entry_2_tag = resp_merge.entry[2].tag;
  assign io_resp_bits_resp_entry_2_asid = resp_merge.entry[2].asid;
  assign io_resp_bits_resp_entry_2_vmid = resp_merge.entry[2].vmid;
  assign io_resp_bits_resp_entry_2_n = resp_merge.entry[2].n;
  assign io_resp_bits_resp_entry_2_pbmt = resp_merge.entry[2].pbmt;
  assign io_resp_bits_resp_entry_2_perm_d = resp_merge.entry[2].perm.d;
  assign io_resp_bits_resp_entry_2_perm_a = resp_merge.entry[2].perm.a;
  assign io_resp_bits_resp_entry_2_perm_g = resp_merge.entry[2].perm.g;
  assign io_resp_bits_resp_entry_2_perm_u = resp_merge.entry[2].perm.u;
  assign io_resp_bits_resp_entry_2_perm_x = resp_merge.entry[2].perm.x;
  assign io_resp_bits_resp_entry_2_perm_w = resp_merge.entry[2].perm.w;
  assign io_resp_bits_resp_entry_2_perm_r = resp_merge.entry[2].perm.r;
  assign io_resp_bits_resp_entry_2_level = resp_merge.entry[2].level;
  assign io_resp_bits_resp_entry_2_v = resp_merge.entry[2].v;
  assign io_resp_bits_resp_entry_2_ppn = resp_merge.entry[2].ppn;
  assign io_resp_bits_resp_entry_2_ppn_low = resp_merge.entry[2].ppn_low;
  assign io_resp_bits_resp_entry_2_af = resp_merge.entry[2].af;
  assign io_resp_bits_resp_entry_2_pf = resp_merge.entry[2].pf;
  assign io_resp_bits_resp_entry_3_tag = resp_merge.entry[3].tag;
  assign io_resp_bits_resp_entry_3_asid = resp_merge.entry[3].asid;
  assign io_resp_bits_resp_entry_3_vmid = resp_merge.entry[3].vmid;
  assign io_resp_bits_resp_entry_3_n = resp_merge.entry[3].n;
  assign io_resp_bits_resp_entry_3_pbmt = resp_merge.entry[3].pbmt;
  assign io_resp_bits_resp_entry_3_perm_d = resp_merge.entry[3].perm.d;
  assign io_resp_bits_resp_entry_3_perm_a = resp_merge.entry[3].perm.a;
  assign io_resp_bits_resp_entry_3_perm_g = resp_merge.entry[3].perm.g;
  assign io_resp_bits_resp_entry_3_perm_u = resp_merge.entry[3].perm.u;
  assign io_resp_bits_resp_entry_3_perm_x = resp_merge.entry[3].perm.x;
  assign io_resp_bits_resp_entry_3_perm_w = resp_merge.entry[3].perm.w;
  assign io_resp_bits_resp_entry_3_perm_r = resp_merge.entry[3].perm.r;
  assign io_resp_bits_resp_entry_3_level = resp_merge.entry[3].level;
  assign io_resp_bits_resp_entry_3_v = resp_merge.entry[3].v;
  assign io_resp_bits_resp_entry_3_ppn = resp_merge.entry[3].ppn;
  assign io_resp_bits_resp_entry_3_ppn_low = resp_merge.entry[3].ppn_low;
  assign io_resp_bits_resp_entry_3_af = resp_merge.entry[3].af;
  assign io_resp_bits_resp_entry_3_pf = resp_merge.entry[3].pf;
  assign io_resp_bits_resp_entry_4_tag = resp_merge.entry[4].tag;
  assign io_resp_bits_resp_entry_4_asid = resp_merge.entry[4].asid;
  assign io_resp_bits_resp_entry_4_vmid = resp_merge.entry[4].vmid;
  assign io_resp_bits_resp_entry_4_n = resp_merge.entry[4].n;
  assign io_resp_bits_resp_entry_4_pbmt = resp_merge.entry[4].pbmt;
  assign io_resp_bits_resp_entry_4_perm_d = resp_merge.entry[4].perm.d;
  assign io_resp_bits_resp_entry_4_perm_a = resp_merge.entry[4].perm.a;
  assign io_resp_bits_resp_entry_4_perm_g = resp_merge.entry[4].perm.g;
  assign io_resp_bits_resp_entry_4_perm_u = resp_merge.entry[4].perm.u;
  assign io_resp_bits_resp_entry_4_perm_x = resp_merge.entry[4].perm.x;
  assign io_resp_bits_resp_entry_4_perm_w = resp_merge.entry[4].perm.w;
  assign io_resp_bits_resp_entry_4_perm_r = resp_merge.entry[4].perm.r;
  assign io_resp_bits_resp_entry_4_level = resp_merge.entry[4].level;
  assign io_resp_bits_resp_entry_4_v = resp_merge.entry[4].v;
  assign io_resp_bits_resp_entry_4_ppn = resp_merge.entry[4].ppn;
  assign io_resp_bits_resp_entry_4_ppn_low = resp_merge.entry[4].ppn_low;
  assign io_resp_bits_resp_entry_4_af = resp_merge.entry[4].af;
  assign io_resp_bits_resp_entry_4_pf = resp_merge.entry[4].pf;
  assign io_resp_bits_resp_entry_5_tag = resp_merge.entry[5].tag;
  assign io_resp_bits_resp_entry_5_asid = resp_merge.entry[5].asid;
  assign io_resp_bits_resp_entry_5_vmid = resp_merge.entry[5].vmid;
  assign io_resp_bits_resp_entry_5_n = resp_merge.entry[5].n;
  assign io_resp_bits_resp_entry_5_pbmt = resp_merge.entry[5].pbmt;
  assign io_resp_bits_resp_entry_5_perm_d = resp_merge.entry[5].perm.d;
  assign io_resp_bits_resp_entry_5_perm_a = resp_merge.entry[5].perm.a;
  assign io_resp_bits_resp_entry_5_perm_g = resp_merge.entry[5].perm.g;
  assign io_resp_bits_resp_entry_5_perm_u = resp_merge.entry[5].perm.u;
  assign io_resp_bits_resp_entry_5_perm_x = resp_merge.entry[5].perm.x;
  assign io_resp_bits_resp_entry_5_perm_w = resp_merge.entry[5].perm.w;
  assign io_resp_bits_resp_entry_5_perm_r = resp_merge.entry[5].perm.r;
  assign io_resp_bits_resp_entry_5_level = resp_merge.entry[5].level;
  assign io_resp_bits_resp_entry_5_v = resp_merge.entry[5].v;
  assign io_resp_bits_resp_entry_5_ppn = resp_merge.entry[5].ppn;
  assign io_resp_bits_resp_entry_5_ppn_low = resp_merge.entry[5].ppn_low;
  assign io_resp_bits_resp_entry_5_af = resp_merge.entry[5].af;
  assign io_resp_bits_resp_entry_5_pf = resp_merge.entry[5].pf;
  assign io_resp_bits_resp_entry_6_tag = resp_merge.entry[6].tag;
  assign io_resp_bits_resp_entry_6_asid = resp_merge.entry[6].asid;
  assign io_resp_bits_resp_entry_6_vmid = resp_merge.entry[6].vmid;
  assign io_resp_bits_resp_entry_6_n = resp_merge.entry[6].n;
  assign io_resp_bits_resp_entry_6_pbmt = resp_merge.entry[6].pbmt;
  assign io_resp_bits_resp_entry_6_perm_d = resp_merge.entry[6].perm.d;
  assign io_resp_bits_resp_entry_6_perm_a = resp_merge.entry[6].perm.a;
  assign io_resp_bits_resp_entry_6_perm_g = resp_merge.entry[6].perm.g;
  assign io_resp_bits_resp_entry_6_perm_u = resp_merge.entry[6].perm.u;
  assign io_resp_bits_resp_entry_6_perm_x = resp_merge.entry[6].perm.x;
  assign io_resp_bits_resp_entry_6_perm_w = resp_merge.entry[6].perm.w;
  assign io_resp_bits_resp_entry_6_perm_r = resp_merge.entry[6].perm.r;
  assign io_resp_bits_resp_entry_6_level = resp_merge.entry[6].level;
  assign io_resp_bits_resp_entry_6_v = resp_merge.entry[6].v;
  assign io_resp_bits_resp_entry_6_ppn = resp_merge.entry[6].ppn;
  assign io_resp_bits_resp_entry_6_ppn_low = resp_merge.entry[6].ppn_low;
  assign io_resp_bits_resp_entry_6_af = resp_merge.entry[6].af;
  assign io_resp_bits_resp_entry_6_pf = resp_merge.entry[6].pf;
  assign io_resp_bits_resp_entry_7_tag = resp_merge.entry[7].tag;
  assign io_resp_bits_resp_entry_7_asid = resp_merge.entry[7].asid;
  assign io_resp_bits_resp_entry_7_vmid = resp_merge.entry[7].vmid;
  assign io_resp_bits_resp_entry_7_n = resp_merge.entry[7].n;
  assign io_resp_bits_resp_entry_7_pbmt = resp_merge.entry[7].pbmt;
  assign io_resp_bits_resp_entry_7_perm_d = resp_merge.entry[7].perm.d;
  assign io_resp_bits_resp_entry_7_perm_a = resp_merge.entry[7].perm.a;
  assign io_resp_bits_resp_entry_7_perm_g = resp_merge.entry[7].perm.g;
  assign io_resp_bits_resp_entry_7_perm_u = resp_merge.entry[7].perm.u;
  assign io_resp_bits_resp_entry_7_perm_x = resp_merge.entry[7].perm.x;
  assign io_resp_bits_resp_entry_7_perm_w = resp_merge.entry[7].perm.w;
  assign io_resp_bits_resp_entry_7_perm_r = resp_merge.entry[7].perm.r;
  assign io_resp_bits_resp_entry_7_level = resp_merge.entry[7].level;
  assign io_resp_bits_resp_entry_7_v = resp_merge.entry[7].v;
  assign io_resp_bits_resp_entry_7_ppn = resp_merge.entry[7].ppn;
  assign io_resp_bits_resp_entry_7_ppn_low = resp_merge.entry[7].ppn_low;
  assign io_resp_bits_resp_entry_7_af = resp_merge.entry[7].af;
  assign io_resp_bits_resp_entry_7_pf = resp_merge.entry[7].pf;
  assign io_resp_bits_resp_pteidx_0 = resp_merge.pteidx[0];
  assign io_resp_bits_resp_pteidx_1 = resp_merge.pteidx[1];
  assign io_resp_bits_resp_pteidx_2 = resp_merge.pteidx[2];
  assign io_resp_bits_resp_pteidx_3 = resp_merge.pteidx[3];
  assign io_resp_bits_resp_pteidx_4 = resp_merge.pteidx[4];
  assign io_resp_bits_resp_pteidx_5 = resp_merge.pteidx[5];
  assign io_resp_bits_resp_pteidx_6 = resp_merge.pteidx[6];
  assign io_resp_bits_resp_pteidx_7 = resp_merge.pteidx[7];
  assign io_resp_bits_resp_not_super = resp_merge.not_super;
  assign io_resp_bits_h_resp_entry_tag = resp_h.tag;
  assign io_resp_bits_h_resp_entry_vmid = resp_h.vmid;
  assign io_resp_bits_h_resp_entry_n = resp_h.n;
  assign io_resp_bits_h_resp_entry_pbmt = resp_h.pbmt;
  assign io_resp_bits_h_resp_entry_ppn = resp_h.ppn;
  assign io_resp_bits_h_resp_entry_perm_d = resp_h.perm.d;
  assign io_resp_bits_h_resp_entry_perm_a = resp_h.perm.a;
  assign io_resp_bits_h_resp_entry_perm_g = resp_h.perm.g;
  assign io_resp_bits_h_resp_entry_perm_u = resp_h.perm.u;
  assign io_resp_bits_h_resp_entry_perm_x = resp_h.perm.x;
  assign io_resp_bits_h_resp_entry_perm_w = resp_h.perm.w;
  assign io_resp_bits_h_resp_entry_perm_r = resp_h.perm.r;
  assign io_resp_bits_h_resp_entry_level = resp_h.level;
  assign io_resp_bits_h_resp_gpf = resp_h.gpf;
  assign io_resp_bits_h_resp_gaf = resp_h.gaf;
  assign io_perf_0_value = perf_bus[0];
  assign io_perf_1_value = perf_bus[1];
  assign io_perf_2_value = perf_bus[2];
  assign io_perf_3_value = perf_bus[3];
  assign io_perf_4_value = perf_bus[4];
  assign io_perf_5_value = perf_bus[5];
  assign io_perf_6_value = perf_bus[6];

endmodule
