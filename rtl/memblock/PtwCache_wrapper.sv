// 自动生成：scripts/gen_ptwcache.py —— golden 同名 PtwCache，例化可读核 xs_PtwCache_core
//   + golden 黑盒 SplittedSRAM/SplittedSRAM_1/MbistPipePtwL1/L0/ClockGate。
// 控制逻辑全在 xs_PtwCache_core（rtl/memblock/PtwCache.sv + ptwcache_*.svh）。
module PtwCache import xs_ptwcache_pkg::*; (
  input          clock,
  input          reset,
  input          io_csr_mPBMTE,
  input          io_csr_hPBMTE,
  output         io_req_ready,
  input          io_req_valid,
  input  [37:0]  io_req_bits_req_info_vpn,
  input  [1:0]   io_req_bits_req_info_s2xlate,
  input  [1:0]   io_req_bits_req_info_source,
  input          io_req_bits_isFirst,
  input          io_req_bits_isHptwReq,
  input  [2:0]   io_req_bits_hptwId,
  input          io_resp_ready,
  output         io_resp_valid,
  output [37:0]  io_resp_bits_req_info_vpn,
  output [1:0]   io_resp_bits_req_info_s2xlate,
  output [1:0]   io_resp_bits_req_info_source,
  output         io_resp_bits_isFirst,
  output         io_resp_bits_hit,
  output         io_resp_bits_prefetch,
  output         io_resp_bits_bypassed,
  output         io_resp_bits_toFsm_l3Hit,
  output         io_resp_bits_toFsm_l2Hit,
  output         io_resp_bits_toFsm_l1Hit,
  output [37:0]  io_resp_bits_toFsm_ppn,
  output         io_resp_bits_toFsm_stage1Hit,
  output [34:0]  io_resp_bits_stage1_entry_0_tag,
  output [15:0]  io_resp_bits_stage1_entry_0_asid,
  output [13:0]  io_resp_bits_stage1_entry_0_vmid,
  output         io_resp_bits_stage1_entry_0_n,
  output [1:0]   io_resp_bits_stage1_entry_0_pbmt,
  output         io_resp_bits_stage1_entry_0_perm_d,
  output         io_resp_bits_stage1_entry_0_perm_a,
  output         io_resp_bits_stage1_entry_0_perm_g,
  output         io_resp_bits_stage1_entry_0_perm_u,
  output         io_resp_bits_stage1_entry_0_perm_x,
  output         io_resp_bits_stage1_entry_0_perm_w,
  output         io_resp_bits_stage1_entry_0_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_0_level,
  output         io_resp_bits_stage1_entry_0_v,
  output [40:0]  io_resp_bits_stage1_entry_0_ppn,
  output [2:0]   io_resp_bits_stage1_entry_0_ppn_low,
  output         io_resp_bits_stage1_entry_0_pf,
  output [34:0]  io_resp_bits_stage1_entry_1_tag,
  output [15:0]  io_resp_bits_stage1_entry_1_asid,
  output [13:0]  io_resp_bits_stage1_entry_1_vmid,
  output         io_resp_bits_stage1_entry_1_n,
  output [1:0]   io_resp_bits_stage1_entry_1_pbmt,
  output         io_resp_bits_stage1_entry_1_perm_d,
  output         io_resp_bits_stage1_entry_1_perm_a,
  output         io_resp_bits_stage1_entry_1_perm_g,
  output         io_resp_bits_stage1_entry_1_perm_u,
  output         io_resp_bits_stage1_entry_1_perm_x,
  output         io_resp_bits_stage1_entry_1_perm_w,
  output         io_resp_bits_stage1_entry_1_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_1_level,
  output         io_resp_bits_stage1_entry_1_v,
  output [40:0]  io_resp_bits_stage1_entry_1_ppn,
  output [2:0]   io_resp_bits_stage1_entry_1_ppn_low,
  output         io_resp_bits_stage1_entry_1_pf,
  output [34:0]  io_resp_bits_stage1_entry_2_tag,
  output [15:0]  io_resp_bits_stage1_entry_2_asid,
  output [13:0]  io_resp_bits_stage1_entry_2_vmid,
  output         io_resp_bits_stage1_entry_2_n,
  output [1:0]   io_resp_bits_stage1_entry_2_pbmt,
  output         io_resp_bits_stage1_entry_2_perm_d,
  output         io_resp_bits_stage1_entry_2_perm_a,
  output         io_resp_bits_stage1_entry_2_perm_g,
  output         io_resp_bits_stage1_entry_2_perm_u,
  output         io_resp_bits_stage1_entry_2_perm_x,
  output         io_resp_bits_stage1_entry_2_perm_w,
  output         io_resp_bits_stage1_entry_2_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_2_level,
  output         io_resp_bits_stage1_entry_2_v,
  output [40:0]  io_resp_bits_stage1_entry_2_ppn,
  output [2:0]   io_resp_bits_stage1_entry_2_ppn_low,
  output         io_resp_bits_stage1_entry_2_pf,
  output [34:0]  io_resp_bits_stage1_entry_3_tag,
  output [15:0]  io_resp_bits_stage1_entry_3_asid,
  output [13:0]  io_resp_bits_stage1_entry_3_vmid,
  output         io_resp_bits_stage1_entry_3_n,
  output [1:0]   io_resp_bits_stage1_entry_3_pbmt,
  output         io_resp_bits_stage1_entry_3_perm_d,
  output         io_resp_bits_stage1_entry_3_perm_a,
  output         io_resp_bits_stage1_entry_3_perm_g,
  output         io_resp_bits_stage1_entry_3_perm_u,
  output         io_resp_bits_stage1_entry_3_perm_x,
  output         io_resp_bits_stage1_entry_3_perm_w,
  output         io_resp_bits_stage1_entry_3_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_3_level,
  output         io_resp_bits_stage1_entry_3_v,
  output [40:0]  io_resp_bits_stage1_entry_3_ppn,
  output [2:0]   io_resp_bits_stage1_entry_3_ppn_low,
  output         io_resp_bits_stage1_entry_3_pf,
  output [34:0]  io_resp_bits_stage1_entry_4_tag,
  output [15:0]  io_resp_bits_stage1_entry_4_asid,
  output [13:0]  io_resp_bits_stage1_entry_4_vmid,
  output         io_resp_bits_stage1_entry_4_n,
  output [1:0]   io_resp_bits_stage1_entry_4_pbmt,
  output         io_resp_bits_stage1_entry_4_perm_d,
  output         io_resp_bits_stage1_entry_4_perm_a,
  output         io_resp_bits_stage1_entry_4_perm_g,
  output         io_resp_bits_stage1_entry_4_perm_u,
  output         io_resp_bits_stage1_entry_4_perm_x,
  output         io_resp_bits_stage1_entry_4_perm_w,
  output         io_resp_bits_stage1_entry_4_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_4_level,
  output         io_resp_bits_stage1_entry_4_v,
  output [40:0]  io_resp_bits_stage1_entry_4_ppn,
  output [2:0]   io_resp_bits_stage1_entry_4_ppn_low,
  output         io_resp_bits_stage1_entry_4_pf,
  output [34:0]  io_resp_bits_stage1_entry_5_tag,
  output [15:0]  io_resp_bits_stage1_entry_5_asid,
  output [13:0]  io_resp_bits_stage1_entry_5_vmid,
  output         io_resp_bits_stage1_entry_5_n,
  output [1:0]   io_resp_bits_stage1_entry_5_pbmt,
  output         io_resp_bits_stage1_entry_5_perm_d,
  output         io_resp_bits_stage1_entry_5_perm_a,
  output         io_resp_bits_stage1_entry_5_perm_g,
  output         io_resp_bits_stage1_entry_5_perm_u,
  output         io_resp_bits_stage1_entry_5_perm_x,
  output         io_resp_bits_stage1_entry_5_perm_w,
  output         io_resp_bits_stage1_entry_5_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_5_level,
  output         io_resp_bits_stage1_entry_5_v,
  output [40:0]  io_resp_bits_stage1_entry_5_ppn,
  output [2:0]   io_resp_bits_stage1_entry_5_ppn_low,
  output         io_resp_bits_stage1_entry_5_pf,
  output [34:0]  io_resp_bits_stage1_entry_6_tag,
  output [15:0]  io_resp_bits_stage1_entry_6_asid,
  output [13:0]  io_resp_bits_stage1_entry_6_vmid,
  output         io_resp_bits_stage1_entry_6_n,
  output [1:0]   io_resp_bits_stage1_entry_6_pbmt,
  output         io_resp_bits_stage1_entry_6_perm_d,
  output         io_resp_bits_stage1_entry_6_perm_a,
  output         io_resp_bits_stage1_entry_6_perm_g,
  output         io_resp_bits_stage1_entry_6_perm_u,
  output         io_resp_bits_stage1_entry_6_perm_x,
  output         io_resp_bits_stage1_entry_6_perm_w,
  output         io_resp_bits_stage1_entry_6_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_6_level,
  output         io_resp_bits_stage1_entry_6_v,
  output [40:0]  io_resp_bits_stage1_entry_6_ppn,
  output [2:0]   io_resp_bits_stage1_entry_6_ppn_low,
  output         io_resp_bits_stage1_entry_6_pf,
  output [34:0]  io_resp_bits_stage1_entry_7_tag,
  output [15:0]  io_resp_bits_stage1_entry_7_asid,
  output [13:0]  io_resp_bits_stage1_entry_7_vmid,
  output         io_resp_bits_stage1_entry_7_n,
  output [1:0]   io_resp_bits_stage1_entry_7_pbmt,
  output         io_resp_bits_stage1_entry_7_perm_d,
  output         io_resp_bits_stage1_entry_7_perm_a,
  output         io_resp_bits_stage1_entry_7_perm_g,
  output         io_resp_bits_stage1_entry_7_perm_u,
  output         io_resp_bits_stage1_entry_7_perm_x,
  output         io_resp_bits_stage1_entry_7_perm_w,
  output         io_resp_bits_stage1_entry_7_perm_r,
  output [1:0]   io_resp_bits_stage1_entry_7_level,
  output         io_resp_bits_stage1_entry_7_v,
  output [40:0]  io_resp_bits_stage1_entry_7_ppn,
  output [2:0]   io_resp_bits_stage1_entry_7_ppn_low,
  output         io_resp_bits_stage1_entry_7_pf,
  output         io_resp_bits_stage1_pteidx_0,
  output         io_resp_bits_stage1_pteidx_1,
  output         io_resp_bits_stage1_pteidx_2,
  output         io_resp_bits_stage1_pteidx_3,
  output         io_resp_bits_stage1_pteidx_4,
  output         io_resp_bits_stage1_pteidx_5,
  output         io_resp_bits_stage1_pteidx_6,
  output         io_resp_bits_stage1_pteidx_7,
  output         io_resp_bits_stage1_not_super,
  output         io_resp_bits_isHptwReq,
  output         io_resp_bits_toHptw_l3Hit,
  output         io_resp_bits_toHptw_l2Hit,
  output         io_resp_bits_toHptw_l1Hit,
  output [35:0]  io_resp_bits_toHptw_ppn,
  output [2:0]   io_resp_bits_toHptw_id,
  output [37:0]  io_resp_bits_toHptw_resp_entry_tag,
  output [13:0]  io_resp_bits_toHptw_resp_entry_vmid,
  output         io_resp_bits_toHptw_resp_entry_n,
  output [1:0]   io_resp_bits_toHptw_resp_entry_pbmt,
  output [37:0]  io_resp_bits_toHptw_resp_entry_ppn,
  output         io_resp_bits_toHptw_resp_entry_perm_d,
  output         io_resp_bits_toHptw_resp_entry_perm_a,
  output         io_resp_bits_toHptw_resp_entry_perm_g,
  output         io_resp_bits_toHptw_resp_entry_perm_u,
  output         io_resp_bits_toHptw_resp_entry_perm_x,
  output         io_resp_bits_toHptw_resp_entry_perm_w,
  output         io_resp_bits_toHptw_resp_entry_perm_r,
  output [1:0]   io_resp_bits_toHptw_resp_entry_level,
  output         io_resp_bits_toHptw_resp_gpf,
  output         io_resp_bits_toHptw_bypassed,
  input          io_refill_valid,
  input  [511:0] io_refill_bits_ptes,
  input          io_refill_bits_levelOH_sp,
  input          io_refill_bits_levelOH_l0,
  input          io_refill_bits_levelOH_l1,
  input          io_refill_bits_levelOH_l2,
  input          io_refill_bits_levelOH_l3,
  input  [37:0]  io_refill_bits_req_info_dup_0_vpn,
  input  [1:0]   io_refill_bits_req_info_dup_0_s2xlate,
  input  [1:0]   io_refill_bits_req_info_dup_0_source,
  input  [37:0]  io_refill_bits_req_info_dup_1_vpn,
  input  [1:0]   io_refill_bits_req_info_dup_1_s2xlate,
  input  [1:0]   io_refill_bits_req_info_dup_1_source,
  input  [37:0]  io_refill_bits_req_info_dup_2_vpn,
  input  [1:0]   io_refill_bits_req_info_dup_2_s2xlate,
  input  [1:0]   io_refill_bits_req_info_dup_2_source,
  input  [1:0]   io_refill_bits_level_dup_0,
  input  [1:0]   io_refill_bits_level_dup_2,
  input  [63:0]  io_refill_bits_sel_pte_dup_0,
  input  [63:0]  io_refill_bits_sel_pte_dup_2,
  input          io_sfence_dup_0_valid,
  input          io_sfence_dup_0_bits_rs1,
  input          io_sfence_dup_0_bits_rs2,
  input  [49:0]  io_sfence_dup_0_bits_addr,
  input  [15:0]  io_sfence_dup_0_bits_id,
  input          io_sfence_dup_0_bits_hv,
  input          io_sfence_dup_0_bits_hg,
  input          io_sfence_dup_1_valid,
  input  [15:0]  io_sfence_dup_1_bits_id,
  input          io_sfence_dup_2_valid,
  input          io_sfence_dup_2_bits_rs1,
  input          io_sfence_dup_2_bits_rs2,
  input  [15:0]  io_sfence_dup_2_bits_id,
  input  [15:0]  io_csr_dup_0_satp_asid,
  input          io_csr_dup_0_satp_changed,
  input  [15:0]  io_csr_dup_0_vsatp_asid,
  input          io_csr_dup_0_vsatp_changed,
  input  [3:0]   io_csr_dup_0_hgatp_mode,
  input  [15:0]  io_csr_dup_0_hgatp_vmid,
  input          io_csr_dup_0_hgatp_changed,
  input          io_csr_dup_0_priv_virt,
  input  [15:0]  io_csr_dup_1_satp_asid,
  input          io_csr_dup_1_satp_changed,
  input  [15:0]  io_csr_dup_1_vsatp_asid,
  input          io_csr_dup_1_vsatp_changed,
  input  [3:0]   io_csr_dup_1_hgatp_mode,
  input  [15:0]  io_csr_dup_1_hgatp_vmid,
  input          io_csr_dup_1_hgatp_changed,
  input          io_csr_dup_1_priv_virt,
  input  [15:0]  io_csr_dup_2_satp_asid,
  input          io_csr_dup_2_satp_changed,
  input  [15:0]  io_csr_dup_2_vsatp_asid,
  input          io_csr_dup_2_vsatp_changed,
  input  [3:0]   io_csr_dup_2_hgatp_mode,
  input  [15:0]  io_csr_dup_2_hgatp_vmid,
  input          io_csr_dup_2_hgatp_changed,
  input          io_csr_dup_2_priv_virt,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  output [5:0]   io_perf_7_value,
  input  [5:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input  [1:0]   boreChildrenBd_bore_be,
  input  [3:0]   boreChildrenBd_bore_addr,
  input  [199:0] boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [3:0]   boreChildrenBd_bore_addr_rd,
  output [199:0] boreChildrenBd_bore_outdata,
  input  [5:0]   boreChildrenBd_bore_1_array,
  input          boreChildrenBd_bore_1_all,
  input          boreChildrenBd_bore_1_req,
  output         boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_writeen,
  input  [1:0]   boreChildrenBd_bore_1_be,
  input  [5:0]   boreChildrenBd_bore_1_addr,
  input  [227:0] boreChildrenBd_bore_1_indata,
  input          boreChildrenBd_bore_1_readen,
  input  [5:0]   boreChildrenBd_bore_1_addr_rd,
  output [227:0] boreChildrenBd_bore_1_outdata,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          cg_bore_cgen
);

  // ---- 黑盒间互连 / SRAM 读出 / ClockGate 中间 wire ----
  wire             _ClockGate_1_Q;
  wire             _ClockGate_Q;
  wire [22:0]      _l1_io_r_resp_data_0_entries_tag;
  wire [15:0]      _l1_io_r_resp_data_0_entries_asid;
  wire [13:0]      _l1_io_r_resp_data_0_entries_vmid;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_0;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_1;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_2;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_3;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_4;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_5;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_6;
  wire [1:0]       _l1_io_r_resp_data_0_entries_pbmts_7;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_0;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_1;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_2;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_3;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_4;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_5;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_6;
  wire [37:0]      _l1_io_r_resp_data_0_entries_ppns_7;
  wire             _l1_io_r_resp_data_0_entries_vs_0;
  wire             _l1_io_r_resp_data_0_entries_vs_1;
  wire             _l1_io_r_resp_data_0_entries_vs_2;
  wire             _l1_io_r_resp_data_0_entries_vs_3;
  wire             _l1_io_r_resp_data_0_entries_vs_4;
  wire             _l1_io_r_resp_data_0_entries_vs_5;
  wire             _l1_io_r_resp_data_0_entries_vs_6;
  wire             _l1_io_r_resp_data_0_entries_vs_7;
  wire             _l1_io_r_resp_data_0_entries_prefetch;
  wire [22:0]      _l1_io_r_resp_data_1_entries_tag;
  wire [15:0]      _l1_io_r_resp_data_1_entries_asid;
  wire [13:0]      _l1_io_r_resp_data_1_entries_vmid;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_0;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_1;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_2;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_3;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_4;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_5;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_6;
  wire [1:0]       _l1_io_r_resp_data_1_entries_pbmts_7;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_0;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_1;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_2;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_3;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_4;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_5;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_6;
  wire [37:0]      _l1_io_r_resp_data_1_entries_ppns_7;
  wire             _l1_io_r_resp_data_1_entries_vs_0;
  wire             _l1_io_r_resp_data_1_entries_vs_1;
  wire             _l1_io_r_resp_data_1_entries_vs_2;
  wire             _l1_io_r_resp_data_1_entries_vs_3;
  wire             _l1_io_r_resp_data_1_entries_vs_4;
  wire             _l1_io_r_resp_data_1_entries_vs_5;
  wire             _l1_io_r_resp_data_1_entries_vs_6;
  wire             _l1_io_r_resp_data_1_entries_vs_7;
  wire             _l1_io_r_resp_data_1_entries_prefetch;
  wire [29:0]      _l0_io_r_resp_data_0_entries_tag;
  wire [15:0]      _l0_io_r_resp_data_0_entries_asid;
  wire [13:0]      _l0_io_r_resp_data_0_entries_vmid;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_0;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_1;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_2;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_3;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_4;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_5;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_6;
  wire [1:0]       _l0_io_r_resp_data_0_entries_pbmts_7;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_0;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_1;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_2;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_3;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_4;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_5;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_6;
  wire [37:0]      _l0_io_r_resp_data_0_entries_ppns_7;
  wire             _l0_io_r_resp_data_0_entries_vs_0;
  wire             _l0_io_r_resp_data_0_entries_vs_1;
  wire             _l0_io_r_resp_data_0_entries_vs_2;
  wire             _l0_io_r_resp_data_0_entries_vs_3;
  wire             _l0_io_r_resp_data_0_entries_vs_4;
  wire             _l0_io_r_resp_data_0_entries_vs_5;
  wire             _l0_io_r_resp_data_0_entries_vs_6;
  wire             _l0_io_r_resp_data_0_entries_vs_7;
  wire             _l0_io_r_resp_data_0_entries_onlypf_0;
  wire             _l0_io_r_resp_data_0_entries_onlypf_1;
  wire             _l0_io_r_resp_data_0_entries_onlypf_2;
  wire             _l0_io_r_resp_data_0_entries_onlypf_3;
  wire             _l0_io_r_resp_data_0_entries_onlypf_4;
  wire             _l0_io_r_resp_data_0_entries_onlypf_5;
  wire             _l0_io_r_resp_data_0_entries_onlypf_6;
  wire             _l0_io_r_resp_data_0_entries_onlypf_7;
  wire             _l0_io_r_resp_data_0_entries_perms_0_d;
  wire             _l0_io_r_resp_data_0_entries_perms_0_a;
  wire             _l0_io_r_resp_data_0_entries_perms_0_g;
  wire             _l0_io_r_resp_data_0_entries_perms_0_u;
  wire             _l0_io_r_resp_data_0_entries_perms_0_x;
  wire             _l0_io_r_resp_data_0_entries_perms_0_w;
  wire             _l0_io_r_resp_data_0_entries_perms_0_r;
  wire             _l0_io_r_resp_data_0_entries_perms_1_d;
  wire             _l0_io_r_resp_data_0_entries_perms_1_a;
  wire             _l0_io_r_resp_data_0_entries_perms_1_g;
  wire             _l0_io_r_resp_data_0_entries_perms_1_u;
  wire             _l0_io_r_resp_data_0_entries_perms_1_x;
  wire             _l0_io_r_resp_data_0_entries_perms_1_w;
  wire             _l0_io_r_resp_data_0_entries_perms_1_r;
  wire             _l0_io_r_resp_data_0_entries_perms_2_d;
  wire             _l0_io_r_resp_data_0_entries_perms_2_a;
  wire             _l0_io_r_resp_data_0_entries_perms_2_g;
  wire             _l0_io_r_resp_data_0_entries_perms_2_u;
  wire             _l0_io_r_resp_data_0_entries_perms_2_x;
  wire             _l0_io_r_resp_data_0_entries_perms_2_w;
  wire             _l0_io_r_resp_data_0_entries_perms_2_r;
  wire             _l0_io_r_resp_data_0_entries_perms_3_d;
  wire             _l0_io_r_resp_data_0_entries_perms_3_a;
  wire             _l0_io_r_resp_data_0_entries_perms_3_g;
  wire             _l0_io_r_resp_data_0_entries_perms_3_u;
  wire             _l0_io_r_resp_data_0_entries_perms_3_x;
  wire             _l0_io_r_resp_data_0_entries_perms_3_w;
  wire             _l0_io_r_resp_data_0_entries_perms_3_r;
  wire             _l0_io_r_resp_data_0_entries_perms_4_d;
  wire             _l0_io_r_resp_data_0_entries_perms_4_a;
  wire             _l0_io_r_resp_data_0_entries_perms_4_g;
  wire             _l0_io_r_resp_data_0_entries_perms_4_u;
  wire             _l0_io_r_resp_data_0_entries_perms_4_x;
  wire             _l0_io_r_resp_data_0_entries_perms_4_w;
  wire             _l0_io_r_resp_data_0_entries_perms_4_r;
  wire             _l0_io_r_resp_data_0_entries_perms_5_d;
  wire             _l0_io_r_resp_data_0_entries_perms_5_a;
  wire             _l0_io_r_resp_data_0_entries_perms_5_g;
  wire             _l0_io_r_resp_data_0_entries_perms_5_u;
  wire             _l0_io_r_resp_data_0_entries_perms_5_x;
  wire             _l0_io_r_resp_data_0_entries_perms_5_w;
  wire             _l0_io_r_resp_data_0_entries_perms_5_r;
  wire             _l0_io_r_resp_data_0_entries_perms_6_d;
  wire             _l0_io_r_resp_data_0_entries_perms_6_a;
  wire             _l0_io_r_resp_data_0_entries_perms_6_g;
  wire             _l0_io_r_resp_data_0_entries_perms_6_u;
  wire             _l0_io_r_resp_data_0_entries_perms_6_x;
  wire             _l0_io_r_resp_data_0_entries_perms_6_w;
  wire             _l0_io_r_resp_data_0_entries_perms_6_r;
  wire             _l0_io_r_resp_data_0_entries_perms_7_d;
  wire             _l0_io_r_resp_data_0_entries_perms_7_a;
  wire             _l0_io_r_resp_data_0_entries_perms_7_g;
  wire             _l0_io_r_resp_data_0_entries_perms_7_u;
  wire             _l0_io_r_resp_data_0_entries_perms_7_x;
  wire             _l0_io_r_resp_data_0_entries_perms_7_w;
  wire             _l0_io_r_resp_data_0_entries_perms_7_r;
  wire             _l0_io_r_resp_data_0_entries_prefetch;
  wire [29:0]      _l0_io_r_resp_data_1_entries_tag;
  wire [15:0]      _l0_io_r_resp_data_1_entries_asid;
  wire [13:0]      _l0_io_r_resp_data_1_entries_vmid;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_0;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_1;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_2;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_3;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_4;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_5;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_6;
  wire [1:0]       _l0_io_r_resp_data_1_entries_pbmts_7;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_0;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_1;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_2;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_3;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_4;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_5;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_6;
  wire [37:0]      _l0_io_r_resp_data_1_entries_ppns_7;
  wire             _l0_io_r_resp_data_1_entries_vs_0;
  wire             _l0_io_r_resp_data_1_entries_vs_1;
  wire             _l0_io_r_resp_data_1_entries_vs_2;
  wire             _l0_io_r_resp_data_1_entries_vs_3;
  wire             _l0_io_r_resp_data_1_entries_vs_4;
  wire             _l0_io_r_resp_data_1_entries_vs_5;
  wire             _l0_io_r_resp_data_1_entries_vs_6;
  wire             _l0_io_r_resp_data_1_entries_vs_7;
  wire             _l0_io_r_resp_data_1_entries_onlypf_0;
  wire             _l0_io_r_resp_data_1_entries_onlypf_1;
  wire             _l0_io_r_resp_data_1_entries_onlypf_2;
  wire             _l0_io_r_resp_data_1_entries_onlypf_3;
  wire             _l0_io_r_resp_data_1_entries_onlypf_4;
  wire             _l0_io_r_resp_data_1_entries_onlypf_5;
  wire             _l0_io_r_resp_data_1_entries_onlypf_6;
  wire             _l0_io_r_resp_data_1_entries_onlypf_7;
  wire             _l0_io_r_resp_data_1_entries_perms_0_d;
  wire             _l0_io_r_resp_data_1_entries_perms_0_a;
  wire             _l0_io_r_resp_data_1_entries_perms_0_g;
  wire             _l0_io_r_resp_data_1_entries_perms_0_u;
  wire             _l0_io_r_resp_data_1_entries_perms_0_x;
  wire             _l0_io_r_resp_data_1_entries_perms_0_w;
  wire             _l0_io_r_resp_data_1_entries_perms_0_r;
  wire             _l0_io_r_resp_data_1_entries_perms_1_d;
  wire             _l0_io_r_resp_data_1_entries_perms_1_a;
  wire             _l0_io_r_resp_data_1_entries_perms_1_g;
  wire             _l0_io_r_resp_data_1_entries_perms_1_u;
  wire             _l0_io_r_resp_data_1_entries_perms_1_x;
  wire             _l0_io_r_resp_data_1_entries_perms_1_w;
  wire             _l0_io_r_resp_data_1_entries_perms_1_r;
  wire             _l0_io_r_resp_data_1_entries_perms_2_d;
  wire             _l0_io_r_resp_data_1_entries_perms_2_a;
  wire             _l0_io_r_resp_data_1_entries_perms_2_g;
  wire             _l0_io_r_resp_data_1_entries_perms_2_u;
  wire             _l0_io_r_resp_data_1_entries_perms_2_x;
  wire             _l0_io_r_resp_data_1_entries_perms_2_w;
  wire             _l0_io_r_resp_data_1_entries_perms_2_r;
  wire             _l0_io_r_resp_data_1_entries_perms_3_d;
  wire             _l0_io_r_resp_data_1_entries_perms_3_a;
  wire             _l0_io_r_resp_data_1_entries_perms_3_g;
  wire             _l0_io_r_resp_data_1_entries_perms_3_u;
  wire             _l0_io_r_resp_data_1_entries_perms_3_x;
  wire             _l0_io_r_resp_data_1_entries_perms_3_w;
  wire             _l0_io_r_resp_data_1_entries_perms_3_r;
  wire             _l0_io_r_resp_data_1_entries_perms_4_d;
  wire             _l0_io_r_resp_data_1_entries_perms_4_a;
  wire             _l0_io_r_resp_data_1_entries_perms_4_g;
  wire             _l0_io_r_resp_data_1_entries_perms_4_u;
  wire             _l0_io_r_resp_data_1_entries_perms_4_x;
  wire             _l0_io_r_resp_data_1_entries_perms_4_w;
  wire             _l0_io_r_resp_data_1_entries_perms_4_r;
  wire             _l0_io_r_resp_data_1_entries_perms_5_d;
  wire             _l0_io_r_resp_data_1_entries_perms_5_a;
  wire             _l0_io_r_resp_data_1_entries_perms_5_g;
  wire             _l0_io_r_resp_data_1_entries_perms_5_u;
  wire             _l0_io_r_resp_data_1_entries_perms_5_x;
  wire             _l0_io_r_resp_data_1_entries_perms_5_w;
  wire             _l0_io_r_resp_data_1_entries_perms_5_r;
  wire             _l0_io_r_resp_data_1_entries_perms_6_d;
  wire             _l0_io_r_resp_data_1_entries_perms_6_a;
  wire             _l0_io_r_resp_data_1_entries_perms_6_g;
  wire             _l0_io_r_resp_data_1_entries_perms_6_u;
  wire             _l0_io_r_resp_data_1_entries_perms_6_x;
  wire             _l0_io_r_resp_data_1_entries_perms_6_w;
  wire             _l0_io_r_resp_data_1_entries_perms_6_r;
  wire             _l0_io_r_resp_data_1_entries_perms_7_d;
  wire             _l0_io_r_resp_data_1_entries_perms_7_a;
  wire             _l0_io_r_resp_data_1_entries_perms_7_g;
  wire             _l0_io_r_resp_data_1_entries_perms_7_u;
  wire             _l0_io_r_resp_data_1_entries_perms_7_x;
  wire             _l0_io_r_resp_data_1_entries_perms_7_w;
  wire             _l0_io_r_resp_data_1_entries_perms_7_r;
  wire             _l0_io_r_resp_data_1_entries_prefetch;
  wire [29:0]      _l0_io_r_resp_data_2_entries_tag;
  wire [15:0]      _l0_io_r_resp_data_2_entries_asid;
  wire [13:0]      _l0_io_r_resp_data_2_entries_vmid;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_0;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_1;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_2;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_3;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_4;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_5;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_6;
  wire [1:0]       _l0_io_r_resp_data_2_entries_pbmts_7;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_0;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_1;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_2;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_3;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_4;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_5;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_6;
  wire [37:0]      _l0_io_r_resp_data_2_entries_ppns_7;
  wire             _l0_io_r_resp_data_2_entries_vs_0;
  wire             _l0_io_r_resp_data_2_entries_vs_1;
  wire             _l0_io_r_resp_data_2_entries_vs_2;
  wire             _l0_io_r_resp_data_2_entries_vs_3;
  wire             _l0_io_r_resp_data_2_entries_vs_4;
  wire             _l0_io_r_resp_data_2_entries_vs_5;
  wire             _l0_io_r_resp_data_2_entries_vs_6;
  wire             _l0_io_r_resp_data_2_entries_vs_7;
  wire             _l0_io_r_resp_data_2_entries_onlypf_0;
  wire             _l0_io_r_resp_data_2_entries_onlypf_1;
  wire             _l0_io_r_resp_data_2_entries_onlypf_2;
  wire             _l0_io_r_resp_data_2_entries_onlypf_3;
  wire             _l0_io_r_resp_data_2_entries_onlypf_4;
  wire             _l0_io_r_resp_data_2_entries_onlypf_5;
  wire             _l0_io_r_resp_data_2_entries_onlypf_6;
  wire             _l0_io_r_resp_data_2_entries_onlypf_7;
  wire             _l0_io_r_resp_data_2_entries_perms_0_d;
  wire             _l0_io_r_resp_data_2_entries_perms_0_a;
  wire             _l0_io_r_resp_data_2_entries_perms_0_g;
  wire             _l0_io_r_resp_data_2_entries_perms_0_u;
  wire             _l0_io_r_resp_data_2_entries_perms_0_x;
  wire             _l0_io_r_resp_data_2_entries_perms_0_w;
  wire             _l0_io_r_resp_data_2_entries_perms_0_r;
  wire             _l0_io_r_resp_data_2_entries_perms_1_d;
  wire             _l0_io_r_resp_data_2_entries_perms_1_a;
  wire             _l0_io_r_resp_data_2_entries_perms_1_g;
  wire             _l0_io_r_resp_data_2_entries_perms_1_u;
  wire             _l0_io_r_resp_data_2_entries_perms_1_x;
  wire             _l0_io_r_resp_data_2_entries_perms_1_w;
  wire             _l0_io_r_resp_data_2_entries_perms_1_r;
  wire             _l0_io_r_resp_data_2_entries_perms_2_d;
  wire             _l0_io_r_resp_data_2_entries_perms_2_a;
  wire             _l0_io_r_resp_data_2_entries_perms_2_g;
  wire             _l0_io_r_resp_data_2_entries_perms_2_u;
  wire             _l0_io_r_resp_data_2_entries_perms_2_x;
  wire             _l0_io_r_resp_data_2_entries_perms_2_w;
  wire             _l0_io_r_resp_data_2_entries_perms_2_r;
  wire             _l0_io_r_resp_data_2_entries_perms_3_d;
  wire             _l0_io_r_resp_data_2_entries_perms_3_a;
  wire             _l0_io_r_resp_data_2_entries_perms_3_g;
  wire             _l0_io_r_resp_data_2_entries_perms_3_u;
  wire             _l0_io_r_resp_data_2_entries_perms_3_x;
  wire             _l0_io_r_resp_data_2_entries_perms_3_w;
  wire             _l0_io_r_resp_data_2_entries_perms_3_r;
  wire             _l0_io_r_resp_data_2_entries_perms_4_d;
  wire             _l0_io_r_resp_data_2_entries_perms_4_a;
  wire             _l0_io_r_resp_data_2_entries_perms_4_g;
  wire             _l0_io_r_resp_data_2_entries_perms_4_u;
  wire             _l0_io_r_resp_data_2_entries_perms_4_x;
  wire             _l0_io_r_resp_data_2_entries_perms_4_w;
  wire             _l0_io_r_resp_data_2_entries_perms_4_r;
  wire             _l0_io_r_resp_data_2_entries_perms_5_d;
  wire             _l0_io_r_resp_data_2_entries_perms_5_a;
  wire             _l0_io_r_resp_data_2_entries_perms_5_g;
  wire             _l0_io_r_resp_data_2_entries_perms_5_u;
  wire             _l0_io_r_resp_data_2_entries_perms_5_x;
  wire             _l0_io_r_resp_data_2_entries_perms_5_w;
  wire             _l0_io_r_resp_data_2_entries_perms_5_r;
  wire             _l0_io_r_resp_data_2_entries_perms_6_d;
  wire             _l0_io_r_resp_data_2_entries_perms_6_a;
  wire             _l0_io_r_resp_data_2_entries_perms_6_g;
  wire             _l0_io_r_resp_data_2_entries_perms_6_u;
  wire             _l0_io_r_resp_data_2_entries_perms_6_x;
  wire             _l0_io_r_resp_data_2_entries_perms_6_w;
  wire             _l0_io_r_resp_data_2_entries_perms_6_r;
  wire             _l0_io_r_resp_data_2_entries_perms_7_d;
  wire             _l0_io_r_resp_data_2_entries_perms_7_a;
  wire             _l0_io_r_resp_data_2_entries_perms_7_g;
  wire             _l0_io_r_resp_data_2_entries_perms_7_u;
  wire             _l0_io_r_resp_data_2_entries_perms_7_x;
  wire             _l0_io_r_resp_data_2_entries_perms_7_w;
  wire             _l0_io_r_resp_data_2_entries_perms_7_r;
  wire             _l0_io_r_resp_data_2_entries_prefetch;
  wire [29:0]      _l0_io_r_resp_data_3_entries_tag;
  wire [15:0]      _l0_io_r_resp_data_3_entries_asid;
  wire [13:0]      _l0_io_r_resp_data_3_entries_vmid;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_0;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_1;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_2;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_3;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_4;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_5;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_6;
  wire [1:0]       _l0_io_r_resp_data_3_entries_pbmts_7;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_0;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_1;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_2;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_3;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_4;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_5;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_6;
  wire [37:0]      _l0_io_r_resp_data_3_entries_ppns_7;
  wire             _l0_io_r_resp_data_3_entries_vs_0;
  wire             _l0_io_r_resp_data_3_entries_vs_1;
  wire             _l0_io_r_resp_data_3_entries_vs_2;
  wire             _l0_io_r_resp_data_3_entries_vs_3;
  wire             _l0_io_r_resp_data_3_entries_vs_4;
  wire             _l0_io_r_resp_data_3_entries_vs_5;
  wire             _l0_io_r_resp_data_3_entries_vs_6;
  wire             _l0_io_r_resp_data_3_entries_vs_7;
  wire             _l0_io_r_resp_data_3_entries_onlypf_0;
  wire             _l0_io_r_resp_data_3_entries_onlypf_1;
  wire             _l0_io_r_resp_data_3_entries_onlypf_2;
  wire             _l0_io_r_resp_data_3_entries_onlypf_3;
  wire             _l0_io_r_resp_data_3_entries_onlypf_4;
  wire             _l0_io_r_resp_data_3_entries_onlypf_5;
  wire             _l0_io_r_resp_data_3_entries_onlypf_6;
  wire             _l0_io_r_resp_data_3_entries_onlypf_7;
  wire             _l0_io_r_resp_data_3_entries_perms_0_d;
  wire             _l0_io_r_resp_data_3_entries_perms_0_a;
  wire             _l0_io_r_resp_data_3_entries_perms_0_g;
  wire             _l0_io_r_resp_data_3_entries_perms_0_u;
  wire             _l0_io_r_resp_data_3_entries_perms_0_x;
  wire             _l0_io_r_resp_data_3_entries_perms_0_w;
  wire             _l0_io_r_resp_data_3_entries_perms_0_r;
  wire             _l0_io_r_resp_data_3_entries_perms_1_d;
  wire             _l0_io_r_resp_data_3_entries_perms_1_a;
  wire             _l0_io_r_resp_data_3_entries_perms_1_g;
  wire             _l0_io_r_resp_data_3_entries_perms_1_u;
  wire             _l0_io_r_resp_data_3_entries_perms_1_x;
  wire             _l0_io_r_resp_data_3_entries_perms_1_w;
  wire             _l0_io_r_resp_data_3_entries_perms_1_r;
  wire             _l0_io_r_resp_data_3_entries_perms_2_d;
  wire             _l0_io_r_resp_data_3_entries_perms_2_a;
  wire             _l0_io_r_resp_data_3_entries_perms_2_g;
  wire             _l0_io_r_resp_data_3_entries_perms_2_u;
  wire             _l0_io_r_resp_data_3_entries_perms_2_x;
  wire             _l0_io_r_resp_data_3_entries_perms_2_w;
  wire             _l0_io_r_resp_data_3_entries_perms_2_r;
  wire             _l0_io_r_resp_data_3_entries_perms_3_d;
  wire             _l0_io_r_resp_data_3_entries_perms_3_a;
  wire             _l0_io_r_resp_data_3_entries_perms_3_g;
  wire             _l0_io_r_resp_data_3_entries_perms_3_u;
  wire             _l0_io_r_resp_data_3_entries_perms_3_x;
  wire             _l0_io_r_resp_data_3_entries_perms_3_w;
  wire             _l0_io_r_resp_data_3_entries_perms_3_r;
  wire             _l0_io_r_resp_data_3_entries_perms_4_d;
  wire             _l0_io_r_resp_data_3_entries_perms_4_a;
  wire             _l0_io_r_resp_data_3_entries_perms_4_g;
  wire             _l0_io_r_resp_data_3_entries_perms_4_u;
  wire             _l0_io_r_resp_data_3_entries_perms_4_x;
  wire             _l0_io_r_resp_data_3_entries_perms_4_w;
  wire             _l0_io_r_resp_data_3_entries_perms_4_r;
  wire             _l0_io_r_resp_data_3_entries_perms_5_d;
  wire             _l0_io_r_resp_data_3_entries_perms_5_a;
  wire             _l0_io_r_resp_data_3_entries_perms_5_g;
  wire             _l0_io_r_resp_data_3_entries_perms_5_u;
  wire             _l0_io_r_resp_data_3_entries_perms_5_x;
  wire             _l0_io_r_resp_data_3_entries_perms_5_w;
  wire             _l0_io_r_resp_data_3_entries_perms_5_r;
  wire             _l0_io_r_resp_data_3_entries_perms_6_d;
  wire             _l0_io_r_resp_data_3_entries_perms_6_a;
  wire             _l0_io_r_resp_data_3_entries_perms_6_g;
  wire             _l0_io_r_resp_data_3_entries_perms_6_u;
  wire             _l0_io_r_resp_data_3_entries_perms_6_x;
  wire             _l0_io_r_resp_data_3_entries_perms_6_w;
  wire             _l0_io_r_resp_data_3_entries_perms_6_r;
  wire             _l0_io_r_resp_data_3_entries_perms_7_d;
  wire             _l0_io_r_resp_data_3_entries_perms_7_a;
  wire             _l0_io_r_resp_data_3_entries_perms_7_g;
  wire             _l0_io_r_resp_data_3_entries_perms_7_u;
  wire             _l0_io_r_resp_data_3_entries_perms_7_x;
  wire             _l0_io_r_resp_data_3_entries_perms_7_w;
  wire             _l0_io_r_resp_data_3_entries_perms_7_r;
  wire             _l0_io_r_resp_data_3_entries_prefetch;
  wire [227:0]     childBd_11_rdata;
  wire [227:0]     childBd_10_rdata;
  wire [227:0]     childBd_9_rdata;
  wire [227:0]     childBd_8_rdata;
  wire [227:0]     childBd_7_rdata;
  wire [227:0]     childBd_6_rdata;
  wire [227:0]     childBd_5_rdata;
  wire [227:0]     childBd_4_rdata;
  wire [199:0]     childBd_3_rdata;
  wire [199:0]     childBd_2_rdata;
  wire [199:0]     childBd_1_rdata;
  wire [199:0]     childBd_rdata;
  wire [3:0]       childBd_addr;
  wire [3:0]       childBd_addr_rd;
  wire [199:0]     childBd_wdata;
  wire [1:0]       childBd_wmask;
  wire             childBd_re;
  wire             childBd_we;
  wire             childBd_ack;
  wire             childBd_selectedOH;
  wire [5:0]       childBd_array;
  wire [3:0]       childBd_1_addr;
  wire [3:0]       childBd_1_addr_rd;
  wire [199:0]     childBd_1_wdata;
  wire [1:0]       childBd_1_wmask;
  wire             childBd_1_re;
  wire             childBd_1_we;
  wire             childBd_1_ack;
  wire             childBd_1_selectedOH;
  wire [5:0]       childBd_1_array;
  wire [3:0]       childBd_2_addr;
  wire [3:0]       childBd_2_addr_rd;
  wire [199:0]     childBd_2_wdata;
  wire [1:0]       childBd_2_wmask;
  wire             childBd_2_re;
  wire             childBd_2_we;
  wire             childBd_2_ack;
  wire             childBd_2_selectedOH;
  wire [5:0]       childBd_2_array;
  wire [3:0]       childBd_3_addr;
  wire [3:0]       childBd_3_addr_rd;
  wire [199:0]     childBd_3_wdata;
  wire [1:0]       childBd_3_wmask;
  wire             childBd_3_re;
  wire             childBd_3_we;
  wire             childBd_3_ack;
  wire             childBd_3_selectedOH;
  wire [5:0]       childBd_3_array;
  wire [5:0]       childBd_4_addr;
  wire [5:0]       childBd_4_addr_rd;
  wire [227:0]     childBd_4_wdata;
  wire [1:0]       childBd_4_wmask;
  wire             childBd_4_re;
  wire             childBd_4_we;
  wire             childBd_4_ack;
  wire             childBd_4_selectedOH;
  wire [5:0]       childBd_4_array;
  wire [5:0]       childBd_5_addr;
  wire [5:0]       childBd_5_addr_rd;
  wire [227:0]     childBd_5_wdata;
  wire [1:0]       childBd_5_wmask;
  wire             childBd_5_re;
  wire             childBd_5_we;
  wire             childBd_5_ack;
  wire             childBd_5_selectedOH;
  wire [5:0]       childBd_5_array;
  wire [5:0]       childBd_6_addr;
  wire [5:0]       childBd_6_addr_rd;
  wire [227:0]     childBd_6_wdata;
  wire [1:0]       childBd_6_wmask;
  wire             childBd_6_re;
  wire             childBd_6_we;
  wire             childBd_6_ack;
  wire             childBd_6_selectedOH;
  wire [5:0]       childBd_6_array;
  wire [5:0]       childBd_7_addr;
  wire [5:0]       childBd_7_addr_rd;
  wire [227:0]     childBd_7_wdata;
  wire [1:0]       childBd_7_wmask;
  wire             childBd_7_re;
  wire             childBd_7_we;
  wire             childBd_7_ack;
  wire             childBd_7_selectedOH;
  wire [5:0]       childBd_7_array;
  wire [5:0]       childBd_8_addr;
  wire [5:0]       childBd_8_addr_rd;
  wire [227:0]     childBd_8_wdata;
  wire [1:0]       childBd_8_wmask;
  wire             childBd_8_re;
  wire             childBd_8_we;
  wire             childBd_8_ack;
  wire             childBd_8_selectedOH;
  wire [5:0]       childBd_8_array;
  wire [5:0]       childBd_9_addr;
  wire [5:0]       childBd_9_addr_rd;
  wire [227:0]     childBd_9_wdata;
  wire [1:0]       childBd_9_wmask;
  wire             childBd_9_re;
  wire             childBd_9_we;
  wire             childBd_9_ack;
  wire             childBd_9_selectedOH;
  wire [5:0]       childBd_9_array;
  wire [5:0]       childBd_10_addr;
  wire [5:0]       childBd_10_addr_rd;
  wire [227:0]     childBd_10_wdata;
  wire [1:0]       childBd_10_wmask;
  wire             childBd_10_re;
  wire             childBd_10_we;
  wire             childBd_10_ack;
  wire             childBd_10_selectedOH;
  wire [5:0]       childBd_10_array;
  wire [5:0]       childBd_11_addr;
  wire [5:0]       childBd_11_addr_rd;
  wire [227:0]     childBd_11_wdata;
  wire [1:0]       childBd_11_wmask;
  wire             childBd_11_re;
  wire             childBd_11_we;
  wire             childBd_11_ack;
  wire             childBd_11_selectedOH;
  wire [5:0]       childBd_11_array;
  wire [227:0]     bd_1_outdata;
  wire             bd_1_ack;
  wire [199:0]     bd_outdata;
  wire             bd_ack;

  // ---- DFT 旁带本地别名（顶层输入 → mbist 输入）----
  wire [5:0]       bd_array = boreChildrenBd_bore_array;
  wire             bd_all = boreChildrenBd_bore_all;
  wire             bd_req = boreChildrenBd_bore_req;
  wire             bd_writeen = boreChildrenBd_bore_writeen;
  wire [1:0]       bd_be = boreChildrenBd_bore_be;
  wire [3:0]       bd_addr = boreChildrenBd_bore_addr;
  wire [199:0]     bd_indata = boreChildrenBd_bore_indata;
  wire             bd_readen = boreChildrenBd_bore_readen;
  wire [3:0]       bd_addr_rd = boreChildrenBd_bore_addr_rd;
  wire [5:0]       bd_1_array = boreChildrenBd_bore_1_array;
  wire             bd_1_all = boreChildrenBd_bore_1_all;
  wire             bd_1_req = boreChildrenBd_bore_1_req;
  wire             bd_1_writeen = boreChildrenBd_bore_1_writeen;
  wire [1:0]       bd_1_be = boreChildrenBd_bore_1_be;
  wire [5:0]       bd_1_addr = boreChildrenBd_bore_1_addr;
  wire [227:0]     bd_1_indata = boreChildrenBd_bore_1_indata;
  wire             bd_1_readen = boreChildrenBd_bore_1_readen;
  wire [5:0]       bd_1_addr_rd = boreChildrenBd_bore_1_addr_rd;
  wire             te_cgen = cg_bore_cgen;

  // ---- DFT 旁带输出（mbist 输出 → 顶层输出）----
  assign boreChildrenBd_bore_ack = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;
  assign boreChildrenBd_bore_1_ack = bd_1_ack;
  assign boreChildrenBd_bore_1_outdata = bd_1_outdata;

  // ---- CSR / sfence / req_info 总线打包 ----
  logic [2:0][15:0] csr_satp_asid_b, csr_vsatp_asid_b, csr_hgatp_vmid_b;
  logic [2:0]       csr_satp_chg_b, csr_vsatp_chg_b, csr_hgatp_chg_b, csr_priv_virt_b;
  logic [2:0][3:0]  csr_hgatp_mode_b;
  assign csr_satp_asid_b[0]  = io_csr_dup_0_satp_asid;
  assign csr_vsatp_asid_b[0] = io_csr_dup_0_vsatp_asid;
  assign csr_hgatp_vmid_b[0] = io_csr_dup_0_hgatp_vmid;
  assign csr_satp_chg_b[0]   = io_csr_dup_0_satp_changed;
  assign csr_vsatp_chg_b[0]  = io_csr_dup_0_vsatp_changed;
  assign csr_hgatp_chg_b[0]  = io_csr_dup_0_hgatp_changed;
  assign csr_priv_virt_b[0]  = io_csr_dup_0_priv_virt;
  assign csr_hgatp_mode_b[0] = io_csr_dup_0_hgatp_mode;
  assign csr_satp_asid_b[1]  = io_csr_dup_1_satp_asid;
  assign csr_vsatp_asid_b[1] = io_csr_dup_1_vsatp_asid;
  assign csr_hgatp_vmid_b[1] = io_csr_dup_1_hgatp_vmid;
  assign csr_satp_chg_b[1]   = io_csr_dup_1_satp_changed;
  assign csr_vsatp_chg_b[1]  = io_csr_dup_1_vsatp_changed;
  assign csr_hgatp_chg_b[1]  = io_csr_dup_1_hgatp_changed;
  assign csr_priv_virt_b[1]  = io_csr_dup_1_priv_virt;
  assign csr_hgatp_mode_b[1] = io_csr_dup_1_hgatp_mode;
  assign csr_satp_asid_b[2]  = io_csr_dup_2_satp_asid;
  assign csr_vsatp_asid_b[2] = io_csr_dup_2_vsatp_asid;
  assign csr_hgatp_vmid_b[2] = io_csr_dup_2_hgatp_vmid;
  assign csr_satp_chg_b[2]   = io_csr_dup_2_satp_changed;
  assign csr_vsatp_chg_b[2]  = io_csr_dup_2_vsatp_changed;
  assign csr_hgatp_chg_b[2]  = io_csr_dup_2_hgatp_changed;
  assign csr_priv_virt_b[2]  = io_csr_dup_2_priv_virt;
  assign csr_hgatp_mode_b[2] = io_csr_dup_2_hgatp_mode;
  req_info_t req_info_b, refill_ri0_b, refill_ri1_b, refill_ri2_b;
  assign req_info_b.vpn = io_req_bits_req_info_vpn;
  assign req_info_b.s2xlate = io_req_bits_req_info_s2xlate;
  assign req_info_b.source  = io_req_bits_req_info_source;
  assign refill_ri0_b.vpn = io_refill_bits_req_info_dup_0_vpn;
  assign refill_ri0_b.s2xlate = io_refill_bits_req_info_dup_0_s2xlate;
  assign refill_ri0_b.source  = io_refill_bits_req_info_dup_0_source;
  assign refill_ri1_b.vpn = io_refill_bits_req_info_dup_1_vpn;
  assign refill_ri1_b.s2xlate = io_refill_bits_req_info_dup_1_s2xlate;
  assign refill_ri1_b.source  = io_refill_bits_req_info_dup_1_source;
  assign refill_ri2_b.vpn = io_refill_bits_req_info_dup_2_vpn;
  assign refill_ri2_b.s2xlate = io_refill_bits_req_info_dup_2_s2xlate;
  assign refill_ri2_b.source  = io_refill_bits_req_info_dup_2_source;
  sfence_bits_t sfence0_b;
  assign sfence0_b.valid = io_sfence_dup_0_valid;
  assign sfence0_b.rs1   = io_sfence_dup_0_bits_rs1;
  assign sfence0_b.rs2   = io_sfence_dup_0_bits_rs2;
  assign sfence0_b.addr  = io_sfence_dup_0_bits_addr;
  assign sfence0_b.id    = io_sfence_dup_0_bits_id;
  assign sfence0_b.hv    = io_sfence_dup_0_bits_hv;
  assign sfence0_b.hg    = io_sfence_dup_0_bits_hg;
  ptwcache_resp_t        core_resp;
  logic [7:0][5:0]       core_perf;
  // L1/L0 SRAM 读写接口
  logic l1_r_req_valid; logic [2:0] l1_r_req_setIdx;  l1_sram_entry_t l1_r_resp_data [2];
  logic l1_w_req_valid; logic [2:0] l1_w_req_setIdx;  l1_sram_entry_t l1_w_req_data;  logic [1:0] l1_w_req_waymask;
  logic l0_r_req_valid; logic [4:0] l0_r_req_setIdx;  l0_sram_entry_t l0_r_resp_data [4];
  logic l0_w_req_valid; logic [4:0] l0_w_req_setIdx;  l0_sram_entry_t l0_w_req_data;  logic [3:0] l0_w_req_waymask;
  logic l0_clock_en, l1_clock_en;

  assign l1_r_resp_data[0].tag      = _l1_io_r_resp_data_0_entries_tag;
  assign l1_r_resp_data[0].asid     = _l1_io_r_resp_data_0_entries_asid;
  assign l1_r_resp_data[0].vmid     = _l1_io_r_resp_data_0_entries_vmid;
  assign l1_r_resp_data[0].pbmts[0]  = _l1_io_r_resp_data_0_entries_pbmts_0;
  assign l1_r_resp_data[0].ppns[0]   = _l1_io_r_resp_data_0_entries_ppns_0;
  assign l1_r_resp_data[0].vs[0]     = _l1_io_r_resp_data_0_entries_vs_0;
  assign l1_r_resp_data[0].onlypf[0] = 1'b0;
  assign l1_r_resp_data[0].pbmts[1]  = _l1_io_r_resp_data_0_entries_pbmts_1;
  assign l1_r_resp_data[0].ppns[1]   = _l1_io_r_resp_data_0_entries_ppns_1;
  assign l1_r_resp_data[0].vs[1]     = _l1_io_r_resp_data_0_entries_vs_1;
  assign l1_r_resp_data[0].onlypf[1] = 1'b0;
  assign l1_r_resp_data[0].pbmts[2]  = _l1_io_r_resp_data_0_entries_pbmts_2;
  assign l1_r_resp_data[0].ppns[2]   = _l1_io_r_resp_data_0_entries_ppns_2;
  assign l1_r_resp_data[0].vs[2]     = _l1_io_r_resp_data_0_entries_vs_2;
  assign l1_r_resp_data[0].onlypf[2] = 1'b0;
  assign l1_r_resp_data[0].pbmts[3]  = _l1_io_r_resp_data_0_entries_pbmts_3;
  assign l1_r_resp_data[0].ppns[3]   = _l1_io_r_resp_data_0_entries_ppns_3;
  assign l1_r_resp_data[0].vs[3]     = _l1_io_r_resp_data_0_entries_vs_3;
  assign l1_r_resp_data[0].onlypf[3] = 1'b0;
  assign l1_r_resp_data[0].pbmts[4]  = _l1_io_r_resp_data_0_entries_pbmts_4;
  assign l1_r_resp_data[0].ppns[4]   = _l1_io_r_resp_data_0_entries_ppns_4;
  assign l1_r_resp_data[0].vs[4]     = _l1_io_r_resp_data_0_entries_vs_4;
  assign l1_r_resp_data[0].onlypf[4] = 1'b0;
  assign l1_r_resp_data[0].pbmts[5]  = _l1_io_r_resp_data_0_entries_pbmts_5;
  assign l1_r_resp_data[0].ppns[5]   = _l1_io_r_resp_data_0_entries_ppns_5;
  assign l1_r_resp_data[0].vs[5]     = _l1_io_r_resp_data_0_entries_vs_5;
  assign l1_r_resp_data[0].onlypf[5] = 1'b0;
  assign l1_r_resp_data[0].pbmts[6]  = _l1_io_r_resp_data_0_entries_pbmts_6;
  assign l1_r_resp_data[0].ppns[6]   = _l1_io_r_resp_data_0_entries_ppns_6;
  assign l1_r_resp_data[0].vs[6]     = _l1_io_r_resp_data_0_entries_vs_6;
  assign l1_r_resp_data[0].onlypf[6] = 1'b0;
  assign l1_r_resp_data[0].pbmts[7]  = _l1_io_r_resp_data_0_entries_pbmts_7;
  assign l1_r_resp_data[0].ppns[7]   = _l1_io_r_resp_data_0_entries_ppns_7;
  assign l1_r_resp_data[0].vs[7]     = _l1_io_r_resp_data_0_entries_vs_7;
  assign l1_r_resp_data[0].onlypf[7] = 1'b0;
  assign l1_r_resp_data[0].prefetch = _l1_io_r_resp_data_0_entries_prefetch;
  assign l1_r_resp_data[1].tag      = _l1_io_r_resp_data_1_entries_tag;
  assign l1_r_resp_data[1].asid     = _l1_io_r_resp_data_1_entries_asid;
  assign l1_r_resp_data[1].vmid     = _l1_io_r_resp_data_1_entries_vmid;
  assign l1_r_resp_data[1].pbmts[0]  = _l1_io_r_resp_data_1_entries_pbmts_0;
  assign l1_r_resp_data[1].ppns[0]   = _l1_io_r_resp_data_1_entries_ppns_0;
  assign l1_r_resp_data[1].vs[0]     = _l1_io_r_resp_data_1_entries_vs_0;
  assign l1_r_resp_data[1].onlypf[0] = 1'b0;
  assign l1_r_resp_data[1].pbmts[1]  = _l1_io_r_resp_data_1_entries_pbmts_1;
  assign l1_r_resp_data[1].ppns[1]   = _l1_io_r_resp_data_1_entries_ppns_1;
  assign l1_r_resp_data[1].vs[1]     = _l1_io_r_resp_data_1_entries_vs_1;
  assign l1_r_resp_data[1].onlypf[1] = 1'b0;
  assign l1_r_resp_data[1].pbmts[2]  = _l1_io_r_resp_data_1_entries_pbmts_2;
  assign l1_r_resp_data[1].ppns[2]   = _l1_io_r_resp_data_1_entries_ppns_2;
  assign l1_r_resp_data[1].vs[2]     = _l1_io_r_resp_data_1_entries_vs_2;
  assign l1_r_resp_data[1].onlypf[2] = 1'b0;
  assign l1_r_resp_data[1].pbmts[3]  = _l1_io_r_resp_data_1_entries_pbmts_3;
  assign l1_r_resp_data[1].ppns[3]   = _l1_io_r_resp_data_1_entries_ppns_3;
  assign l1_r_resp_data[1].vs[3]     = _l1_io_r_resp_data_1_entries_vs_3;
  assign l1_r_resp_data[1].onlypf[3] = 1'b0;
  assign l1_r_resp_data[1].pbmts[4]  = _l1_io_r_resp_data_1_entries_pbmts_4;
  assign l1_r_resp_data[1].ppns[4]   = _l1_io_r_resp_data_1_entries_ppns_4;
  assign l1_r_resp_data[1].vs[4]     = _l1_io_r_resp_data_1_entries_vs_4;
  assign l1_r_resp_data[1].onlypf[4] = 1'b0;
  assign l1_r_resp_data[1].pbmts[5]  = _l1_io_r_resp_data_1_entries_pbmts_5;
  assign l1_r_resp_data[1].ppns[5]   = _l1_io_r_resp_data_1_entries_ppns_5;
  assign l1_r_resp_data[1].vs[5]     = _l1_io_r_resp_data_1_entries_vs_5;
  assign l1_r_resp_data[1].onlypf[5] = 1'b0;
  assign l1_r_resp_data[1].pbmts[6]  = _l1_io_r_resp_data_1_entries_pbmts_6;
  assign l1_r_resp_data[1].ppns[6]   = _l1_io_r_resp_data_1_entries_ppns_6;
  assign l1_r_resp_data[1].vs[6]     = _l1_io_r_resp_data_1_entries_vs_6;
  assign l1_r_resp_data[1].onlypf[6] = 1'b0;
  assign l1_r_resp_data[1].pbmts[7]  = _l1_io_r_resp_data_1_entries_pbmts_7;
  assign l1_r_resp_data[1].ppns[7]   = _l1_io_r_resp_data_1_entries_ppns_7;
  assign l1_r_resp_data[1].vs[7]     = _l1_io_r_resp_data_1_entries_vs_7;
  assign l1_r_resp_data[1].onlypf[7] = 1'b0;
  assign l1_r_resp_data[1].prefetch = _l1_io_r_resp_data_1_entries_prefetch;
  assign l0_r_resp_data[0].tag      = _l0_io_r_resp_data_0_entries_tag;
  assign l0_r_resp_data[0].asid     = _l0_io_r_resp_data_0_entries_asid;
  assign l0_r_resp_data[0].vmid     = _l0_io_r_resp_data_0_entries_vmid;
  assign l0_r_resp_data[0].pbmts[0]  = _l0_io_r_resp_data_0_entries_pbmts_0;
  assign l0_r_resp_data[0].ppns[0]   = _l0_io_r_resp_data_0_entries_ppns_0;
  assign l0_r_resp_data[0].vs[0]     = _l0_io_r_resp_data_0_entries_vs_0;
  assign l0_r_resp_data[0].onlypf[0] = _l0_io_r_resp_data_0_entries_onlypf_0;
  assign l0_r_resp_data[0].perm_d[0] = _l0_io_r_resp_data_0_entries_perms_0_d;
  assign l0_r_resp_data[0].perm_a[0] = _l0_io_r_resp_data_0_entries_perms_0_a;
  assign l0_r_resp_data[0].perm_g[0] = _l0_io_r_resp_data_0_entries_perms_0_g;
  assign l0_r_resp_data[0].perm_u[0] = _l0_io_r_resp_data_0_entries_perms_0_u;
  assign l0_r_resp_data[0].perm_x[0] = _l0_io_r_resp_data_0_entries_perms_0_x;
  assign l0_r_resp_data[0].perm_w[0] = _l0_io_r_resp_data_0_entries_perms_0_w;
  assign l0_r_resp_data[0].perm_r[0] = _l0_io_r_resp_data_0_entries_perms_0_r;
  assign l0_r_resp_data[0].pbmts[1]  = _l0_io_r_resp_data_0_entries_pbmts_1;
  assign l0_r_resp_data[0].ppns[1]   = _l0_io_r_resp_data_0_entries_ppns_1;
  assign l0_r_resp_data[0].vs[1]     = _l0_io_r_resp_data_0_entries_vs_1;
  assign l0_r_resp_data[0].onlypf[1] = _l0_io_r_resp_data_0_entries_onlypf_1;
  assign l0_r_resp_data[0].perm_d[1] = _l0_io_r_resp_data_0_entries_perms_1_d;
  assign l0_r_resp_data[0].perm_a[1] = _l0_io_r_resp_data_0_entries_perms_1_a;
  assign l0_r_resp_data[0].perm_g[1] = _l0_io_r_resp_data_0_entries_perms_1_g;
  assign l0_r_resp_data[0].perm_u[1] = _l0_io_r_resp_data_0_entries_perms_1_u;
  assign l0_r_resp_data[0].perm_x[1] = _l0_io_r_resp_data_0_entries_perms_1_x;
  assign l0_r_resp_data[0].perm_w[1] = _l0_io_r_resp_data_0_entries_perms_1_w;
  assign l0_r_resp_data[0].perm_r[1] = _l0_io_r_resp_data_0_entries_perms_1_r;
  assign l0_r_resp_data[0].pbmts[2]  = _l0_io_r_resp_data_0_entries_pbmts_2;
  assign l0_r_resp_data[0].ppns[2]   = _l0_io_r_resp_data_0_entries_ppns_2;
  assign l0_r_resp_data[0].vs[2]     = _l0_io_r_resp_data_0_entries_vs_2;
  assign l0_r_resp_data[0].onlypf[2] = _l0_io_r_resp_data_0_entries_onlypf_2;
  assign l0_r_resp_data[0].perm_d[2] = _l0_io_r_resp_data_0_entries_perms_2_d;
  assign l0_r_resp_data[0].perm_a[2] = _l0_io_r_resp_data_0_entries_perms_2_a;
  assign l0_r_resp_data[0].perm_g[2] = _l0_io_r_resp_data_0_entries_perms_2_g;
  assign l0_r_resp_data[0].perm_u[2] = _l0_io_r_resp_data_0_entries_perms_2_u;
  assign l0_r_resp_data[0].perm_x[2] = _l0_io_r_resp_data_0_entries_perms_2_x;
  assign l0_r_resp_data[0].perm_w[2] = _l0_io_r_resp_data_0_entries_perms_2_w;
  assign l0_r_resp_data[0].perm_r[2] = _l0_io_r_resp_data_0_entries_perms_2_r;
  assign l0_r_resp_data[0].pbmts[3]  = _l0_io_r_resp_data_0_entries_pbmts_3;
  assign l0_r_resp_data[0].ppns[3]   = _l0_io_r_resp_data_0_entries_ppns_3;
  assign l0_r_resp_data[0].vs[3]     = _l0_io_r_resp_data_0_entries_vs_3;
  assign l0_r_resp_data[0].onlypf[3] = _l0_io_r_resp_data_0_entries_onlypf_3;
  assign l0_r_resp_data[0].perm_d[3] = _l0_io_r_resp_data_0_entries_perms_3_d;
  assign l0_r_resp_data[0].perm_a[3] = _l0_io_r_resp_data_0_entries_perms_3_a;
  assign l0_r_resp_data[0].perm_g[3] = _l0_io_r_resp_data_0_entries_perms_3_g;
  assign l0_r_resp_data[0].perm_u[3] = _l0_io_r_resp_data_0_entries_perms_3_u;
  assign l0_r_resp_data[0].perm_x[3] = _l0_io_r_resp_data_0_entries_perms_3_x;
  assign l0_r_resp_data[0].perm_w[3] = _l0_io_r_resp_data_0_entries_perms_3_w;
  assign l0_r_resp_data[0].perm_r[3] = _l0_io_r_resp_data_0_entries_perms_3_r;
  assign l0_r_resp_data[0].pbmts[4]  = _l0_io_r_resp_data_0_entries_pbmts_4;
  assign l0_r_resp_data[0].ppns[4]   = _l0_io_r_resp_data_0_entries_ppns_4;
  assign l0_r_resp_data[0].vs[4]     = _l0_io_r_resp_data_0_entries_vs_4;
  assign l0_r_resp_data[0].onlypf[4] = _l0_io_r_resp_data_0_entries_onlypf_4;
  assign l0_r_resp_data[0].perm_d[4] = _l0_io_r_resp_data_0_entries_perms_4_d;
  assign l0_r_resp_data[0].perm_a[4] = _l0_io_r_resp_data_0_entries_perms_4_a;
  assign l0_r_resp_data[0].perm_g[4] = _l0_io_r_resp_data_0_entries_perms_4_g;
  assign l0_r_resp_data[0].perm_u[4] = _l0_io_r_resp_data_0_entries_perms_4_u;
  assign l0_r_resp_data[0].perm_x[4] = _l0_io_r_resp_data_0_entries_perms_4_x;
  assign l0_r_resp_data[0].perm_w[4] = _l0_io_r_resp_data_0_entries_perms_4_w;
  assign l0_r_resp_data[0].perm_r[4] = _l0_io_r_resp_data_0_entries_perms_4_r;
  assign l0_r_resp_data[0].pbmts[5]  = _l0_io_r_resp_data_0_entries_pbmts_5;
  assign l0_r_resp_data[0].ppns[5]   = _l0_io_r_resp_data_0_entries_ppns_5;
  assign l0_r_resp_data[0].vs[5]     = _l0_io_r_resp_data_0_entries_vs_5;
  assign l0_r_resp_data[0].onlypf[5] = _l0_io_r_resp_data_0_entries_onlypf_5;
  assign l0_r_resp_data[0].perm_d[5] = _l0_io_r_resp_data_0_entries_perms_5_d;
  assign l0_r_resp_data[0].perm_a[5] = _l0_io_r_resp_data_0_entries_perms_5_a;
  assign l0_r_resp_data[0].perm_g[5] = _l0_io_r_resp_data_0_entries_perms_5_g;
  assign l0_r_resp_data[0].perm_u[5] = _l0_io_r_resp_data_0_entries_perms_5_u;
  assign l0_r_resp_data[0].perm_x[5] = _l0_io_r_resp_data_0_entries_perms_5_x;
  assign l0_r_resp_data[0].perm_w[5] = _l0_io_r_resp_data_0_entries_perms_5_w;
  assign l0_r_resp_data[0].perm_r[5] = _l0_io_r_resp_data_0_entries_perms_5_r;
  assign l0_r_resp_data[0].pbmts[6]  = _l0_io_r_resp_data_0_entries_pbmts_6;
  assign l0_r_resp_data[0].ppns[6]   = _l0_io_r_resp_data_0_entries_ppns_6;
  assign l0_r_resp_data[0].vs[6]     = _l0_io_r_resp_data_0_entries_vs_6;
  assign l0_r_resp_data[0].onlypf[6] = _l0_io_r_resp_data_0_entries_onlypf_6;
  assign l0_r_resp_data[0].perm_d[6] = _l0_io_r_resp_data_0_entries_perms_6_d;
  assign l0_r_resp_data[0].perm_a[6] = _l0_io_r_resp_data_0_entries_perms_6_a;
  assign l0_r_resp_data[0].perm_g[6] = _l0_io_r_resp_data_0_entries_perms_6_g;
  assign l0_r_resp_data[0].perm_u[6] = _l0_io_r_resp_data_0_entries_perms_6_u;
  assign l0_r_resp_data[0].perm_x[6] = _l0_io_r_resp_data_0_entries_perms_6_x;
  assign l0_r_resp_data[0].perm_w[6] = _l0_io_r_resp_data_0_entries_perms_6_w;
  assign l0_r_resp_data[0].perm_r[6] = _l0_io_r_resp_data_0_entries_perms_6_r;
  assign l0_r_resp_data[0].pbmts[7]  = _l0_io_r_resp_data_0_entries_pbmts_7;
  assign l0_r_resp_data[0].ppns[7]   = _l0_io_r_resp_data_0_entries_ppns_7;
  assign l0_r_resp_data[0].vs[7]     = _l0_io_r_resp_data_0_entries_vs_7;
  assign l0_r_resp_data[0].onlypf[7] = _l0_io_r_resp_data_0_entries_onlypf_7;
  assign l0_r_resp_data[0].perm_d[7] = _l0_io_r_resp_data_0_entries_perms_7_d;
  assign l0_r_resp_data[0].perm_a[7] = _l0_io_r_resp_data_0_entries_perms_7_a;
  assign l0_r_resp_data[0].perm_g[7] = _l0_io_r_resp_data_0_entries_perms_7_g;
  assign l0_r_resp_data[0].perm_u[7] = _l0_io_r_resp_data_0_entries_perms_7_u;
  assign l0_r_resp_data[0].perm_x[7] = _l0_io_r_resp_data_0_entries_perms_7_x;
  assign l0_r_resp_data[0].perm_w[7] = _l0_io_r_resp_data_0_entries_perms_7_w;
  assign l0_r_resp_data[0].perm_r[7] = _l0_io_r_resp_data_0_entries_perms_7_r;
  assign l0_r_resp_data[0].prefetch = _l0_io_r_resp_data_0_entries_prefetch;
  assign l0_r_resp_data[1].tag      = _l0_io_r_resp_data_1_entries_tag;
  assign l0_r_resp_data[1].asid     = _l0_io_r_resp_data_1_entries_asid;
  assign l0_r_resp_data[1].vmid     = _l0_io_r_resp_data_1_entries_vmid;
  assign l0_r_resp_data[1].pbmts[0]  = _l0_io_r_resp_data_1_entries_pbmts_0;
  assign l0_r_resp_data[1].ppns[0]   = _l0_io_r_resp_data_1_entries_ppns_0;
  assign l0_r_resp_data[1].vs[0]     = _l0_io_r_resp_data_1_entries_vs_0;
  assign l0_r_resp_data[1].onlypf[0] = _l0_io_r_resp_data_1_entries_onlypf_0;
  assign l0_r_resp_data[1].perm_d[0] = _l0_io_r_resp_data_1_entries_perms_0_d;
  assign l0_r_resp_data[1].perm_a[0] = _l0_io_r_resp_data_1_entries_perms_0_a;
  assign l0_r_resp_data[1].perm_g[0] = _l0_io_r_resp_data_1_entries_perms_0_g;
  assign l0_r_resp_data[1].perm_u[0] = _l0_io_r_resp_data_1_entries_perms_0_u;
  assign l0_r_resp_data[1].perm_x[0] = _l0_io_r_resp_data_1_entries_perms_0_x;
  assign l0_r_resp_data[1].perm_w[0] = _l0_io_r_resp_data_1_entries_perms_0_w;
  assign l0_r_resp_data[1].perm_r[0] = _l0_io_r_resp_data_1_entries_perms_0_r;
  assign l0_r_resp_data[1].pbmts[1]  = _l0_io_r_resp_data_1_entries_pbmts_1;
  assign l0_r_resp_data[1].ppns[1]   = _l0_io_r_resp_data_1_entries_ppns_1;
  assign l0_r_resp_data[1].vs[1]     = _l0_io_r_resp_data_1_entries_vs_1;
  assign l0_r_resp_data[1].onlypf[1] = _l0_io_r_resp_data_1_entries_onlypf_1;
  assign l0_r_resp_data[1].perm_d[1] = _l0_io_r_resp_data_1_entries_perms_1_d;
  assign l0_r_resp_data[1].perm_a[1] = _l0_io_r_resp_data_1_entries_perms_1_a;
  assign l0_r_resp_data[1].perm_g[1] = _l0_io_r_resp_data_1_entries_perms_1_g;
  assign l0_r_resp_data[1].perm_u[1] = _l0_io_r_resp_data_1_entries_perms_1_u;
  assign l0_r_resp_data[1].perm_x[1] = _l0_io_r_resp_data_1_entries_perms_1_x;
  assign l0_r_resp_data[1].perm_w[1] = _l0_io_r_resp_data_1_entries_perms_1_w;
  assign l0_r_resp_data[1].perm_r[1] = _l0_io_r_resp_data_1_entries_perms_1_r;
  assign l0_r_resp_data[1].pbmts[2]  = _l0_io_r_resp_data_1_entries_pbmts_2;
  assign l0_r_resp_data[1].ppns[2]   = _l0_io_r_resp_data_1_entries_ppns_2;
  assign l0_r_resp_data[1].vs[2]     = _l0_io_r_resp_data_1_entries_vs_2;
  assign l0_r_resp_data[1].onlypf[2] = _l0_io_r_resp_data_1_entries_onlypf_2;
  assign l0_r_resp_data[1].perm_d[2] = _l0_io_r_resp_data_1_entries_perms_2_d;
  assign l0_r_resp_data[1].perm_a[2] = _l0_io_r_resp_data_1_entries_perms_2_a;
  assign l0_r_resp_data[1].perm_g[2] = _l0_io_r_resp_data_1_entries_perms_2_g;
  assign l0_r_resp_data[1].perm_u[2] = _l0_io_r_resp_data_1_entries_perms_2_u;
  assign l0_r_resp_data[1].perm_x[2] = _l0_io_r_resp_data_1_entries_perms_2_x;
  assign l0_r_resp_data[1].perm_w[2] = _l0_io_r_resp_data_1_entries_perms_2_w;
  assign l0_r_resp_data[1].perm_r[2] = _l0_io_r_resp_data_1_entries_perms_2_r;
  assign l0_r_resp_data[1].pbmts[3]  = _l0_io_r_resp_data_1_entries_pbmts_3;
  assign l0_r_resp_data[1].ppns[3]   = _l0_io_r_resp_data_1_entries_ppns_3;
  assign l0_r_resp_data[1].vs[3]     = _l0_io_r_resp_data_1_entries_vs_3;
  assign l0_r_resp_data[1].onlypf[3] = _l0_io_r_resp_data_1_entries_onlypf_3;
  assign l0_r_resp_data[1].perm_d[3] = _l0_io_r_resp_data_1_entries_perms_3_d;
  assign l0_r_resp_data[1].perm_a[3] = _l0_io_r_resp_data_1_entries_perms_3_a;
  assign l0_r_resp_data[1].perm_g[3] = _l0_io_r_resp_data_1_entries_perms_3_g;
  assign l0_r_resp_data[1].perm_u[3] = _l0_io_r_resp_data_1_entries_perms_3_u;
  assign l0_r_resp_data[1].perm_x[3] = _l0_io_r_resp_data_1_entries_perms_3_x;
  assign l0_r_resp_data[1].perm_w[3] = _l0_io_r_resp_data_1_entries_perms_3_w;
  assign l0_r_resp_data[1].perm_r[3] = _l0_io_r_resp_data_1_entries_perms_3_r;
  assign l0_r_resp_data[1].pbmts[4]  = _l0_io_r_resp_data_1_entries_pbmts_4;
  assign l0_r_resp_data[1].ppns[4]   = _l0_io_r_resp_data_1_entries_ppns_4;
  assign l0_r_resp_data[1].vs[4]     = _l0_io_r_resp_data_1_entries_vs_4;
  assign l0_r_resp_data[1].onlypf[4] = _l0_io_r_resp_data_1_entries_onlypf_4;
  assign l0_r_resp_data[1].perm_d[4] = _l0_io_r_resp_data_1_entries_perms_4_d;
  assign l0_r_resp_data[1].perm_a[4] = _l0_io_r_resp_data_1_entries_perms_4_a;
  assign l0_r_resp_data[1].perm_g[4] = _l0_io_r_resp_data_1_entries_perms_4_g;
  assign l0_r_resp_data[1].perm_u[4] = _l0_io_r_resp_data_1_entries_perms_4_u;
  assign l0_r_resp_data[1].perm_x[4] = _l0_io_r_resp_data_1_entries_perms_4_x;
  assign l0_r_resp_data[1].perm_w[4] = _l0_io_r_resp_data_1_entries_perms_4_w;
  assign l0_r_resp_data[1].perm_r[4] = _l0_io_r_resp_data_1_entries_perms_4_r;
  assign l0_r_resp_data[1].pbmts[5]  = _l0_io_r_resp_data_1_entries_pbmts_5;
  assign l0_r_resp_data[1].ppns[5]   = _l0_io_r_resp_data_1_entries_ppns_5;
  assign l0_r_resp_data[1].vs[5]     = _l0_io_r_resp_data_1_entries_vs_5;
  assign l0_r_resp_data[1].onlypf[5] = _l0_io_r_resp_data_1_entries_onlypf_5;
  assign l0_r_resp_data[1].perm_d[5] = _l0_io_r_resp_data_1_entries_perms_5_d;
  assign l0_r_resp_data[1].perm_a[5] = _l0_io_r_resp_data_1_entries_perms_5_a;
  assign l0_r_resp_data[1].perm_g[5] = _l0_io_r_resp_data_1_entries_perms_5_g;
  assign l0_r_resp_data[1].perm_u[5] = _l0_io_r_resp_data_1_entries_perms_5_u;
  assign l0_r_resp_data[1].perm_x[5] = _l0_io_r_resp_data_1_entries_perms_5_x;
  assign l0_r_resp_data[1].perm_w[5] = _l0_io_r_resp_data_1_entries_perms_5_w;
  assign l0_r_resp_data[1].perm_r[5] = _l0_io_r_resp_data_1_entries_perms_5_r;
  assign l0_r_resp_data[1].pbmts[6]  = _l0_io_r_resp_data_1_entries_pbmts_6;
  assign l0_r_resp_data[1].ppns[6]   = _l0_io_r_resp_data_1_entries_ppns_6;
  assign l0_r_resp_data[1].vs[6]     = _l0_io_r_resp_data_1_entries_vs_6;
  assign l0_r_resp_data[1].onlypf[6] = _l0_io_r_resp_data_1_entries_onlypf_6;
  assign l0_r_resp_data[1].perm_d[6] = _l0_io_r_resp_data_1_entries_perms_6_d;
  assign l0_r_resp_data[1].perm_a[6] = _l0_io_r_resp_data_1_entries_perms_6_a;
  assign l0_r_resp_data[1].perm_g[6] = _l0_io_r_resp_data_1_entries_perms_6_g;
  assign l0_r_resp_data[1].perm_u[6] = _l0_io_r_resp_data_1_entries_perms_6_u;
  assign l0_r_resp_data[1].perm_x[6] = _l0_io_r_resp_data_1_entries_perms_6_x;
  assign l0_r_resp_data[1].perm_w[6] = _l0_io_r_resp_data_1_entries_perms_6_w;
  assign l0_r_resp_data[1].perm_r[6] = _l0_io_r_resp_data_1_entries_perms_6_r;
  assign l0_r_resp_data[1].pbmts[7]  = _l0_io_r_resp_data_1_entries_pbmts_7;
  assign l0_r_resp_data[1].ppns[7]   = _l0_io_r_resp_data_1_entries_ppns_7;
  assign l0_r_resp_data[1].vs[7]     = _l0_io_r_resp_data_1_entries_vs_7;
  assign l0_r_resp_data[1].onlypf[7] = _l0_io_r_resp_data_1_entries_onlypf_7;
  assign l0_r_resp_data[1].perm_d[7] = _l0_io_r_resp_data_1_entries_perms_7_d;
  assign l0_r_resp_data[1].perm_a[7] = _l0_io_r_resp_data_1_entries_perms_7_a;
  assign l0_r_resp_data[1].perm_g[7] = _l0_io_r_resp_data_1_entries_perms_7_g;
  assign l0_r_resp_data[1].perm_u[7] = _l0_io_r_resp_data_1_entries_perms_7_u;
  assign l0_r_resp_data[1].perm_x[7] = _l0_io_r_resp_data_1_entries_perms_7_x;
  assign l0_r_resp_data[1].perm_w[7] = _l0_io_r_resp_data_1_entries_perms_7_w;
  assign l0_r_resp_data[1].perm_r[7] = _l0_io_r_resp_data_1_entries_perms_7_r;
  assign l0_r_resp_data[1].prefetch = _l0_io_r_resp_data_1_entries_prefetch;
  assign l0_r_resp_data[2].tag      = _l0_io_r_resp_data_2_entries_tag;
  assign l0_r_resp_data[2].asid     = _l0_io_r_resp_data_2_entries_asid;
  assign l0_r_resp_data[2].vmid     = _l0_io_r_resp_data_2_entries_vmid;
  assign l0_r_resp_data[2].pbmts[0]  = _l0_io_r_resp_data_2_entries_pbmts_0;
  assign l0_r_resp_data[2].ppns[0]   = _l0_io_r_resp_data_2_entries_ppns_0;
  assign l0_r_resp_data[2].vs[0]     = _l0_io_r_resp_data_2_entries_vs_0;
  assign l0_r_resp_data[2].onlypf[0] = _l0_io_r_resp_data_2_entries_onlypf_0;
  assign l0_r_resp_data[2].perm_d[0] = _l0_io_r_resp_data_2_entries_perms_0_d;
  assign l0_r_resp_data[2].perm_a[0] = _l0_io_r_resp_data_2_entries_perms_0_a;
  assign l0_r_resp_data[2].perm_g[0] = _l0_io_r_resp_data_2_entries_perms_0_g;
  assign l0_r_resp_data[2].perm_u[0] = _l0_io_r_resp_data_2_entries_perms_0_u;
  assign l0_r_resp_data[2].perm_x[0] = _l0_io_r_resp_data_2_entries_perms_0_x;
  assign l0_r_resp_data[2].perm_w[0] = _l0_io_r_resp_data_2_entries_perms_0_w;
  assign l0_r_resp_data[2].perm_r[0] = _l0_io_r_resp_data_2_entries_perms_0_r;
  assign l0_r_resp_data[2].pbmts[1]  = _l0_io_r_resp_data_2_entries_pbmts_1;
  assign l0_r_resp_data[2].ppns[1]   = _l0_io_r_resp_data_2_entries_ppns_1;
  assign l0_r_resp_data[2].vs[1]     = _l0_io_r_resp_data_2_entries_vs_1;
  assign l0_r_resp_data[2].onlypf[1] = _l0_io_r_resp_data_2_entries_onlypf_1;
  assign l0_r_resp_data[2].perm_d[1] = _l0_io_r_resp_data_2_entries_perms_1_d;
  assign l0_r_resp_data[2].perm_a[1] = _l0_io_r_resp_data_2_entries_perms_1_a;
  assign l0_r_resp_data[2].perm_g[1] = _l0_io_r_resp_data_2_entries_perms_1_g;
  assign l0_r_resp_data[2].perm_u[1] = _l0_io_r_resp_data_2_entries_perms_1_u;
  assign l0_r_resp_data[2].perm_x[1] = _l0_io_r_resp_data_2_entries_perms_1_x;
  assign l0_r_resp_data[2].perm_w[1] = _l0_io_r_resp_data_2_entries_perms_1_w;
  assign l0_r_resp_data[2].perm_r[1] = _l0_io_r_resp_data_2_entries_perms_1_r;
  assign l0_r_resp_data[2].pbmts[2]  = _l0_io_r_resp_data_2_entries_pbmts_2;
  assign l0_r_resp_data[2].ppns[2]   = _l0_io_r_resp_data_2_entries_ppns_2;
  assign l0_r_resp_data[2].vs[2]     = _l0_io_r_resp_data_2_entries_vs_2;
  assign l0_r_resp_data[2].onlypf[2] = _l0_io_r_resp_data_2_entries_onlypf_2;
  assign l0_r_resp_data[2].perm_d[2] = _l0_io_r_resp_data_2_entries_perms_2_d;
  assign l0_r_resp_data[2].perm_a[2] = _l0_io_r_resp_data_2_entries_perms_2_a;
  assign l0_r_resp_data[2].perm_g[2] = _l0_io_r_resp_data_2_entries_perms_2_g;
  assign l0_r_resp_data[2].perm_u[2] = _l0_io_r_resp_data_2_entries_perms_2_u;
  assign l0_r_resp_data[2].perm_x[2] = _l0_io_r_resp_data_2_entries_perms_2_x;
  assign l0_r_resp_data[2].perm_w[2] = _l0_io_r_resp_data_2_entries_perms_2_w;
  assign l0_r_resp_data[2].perm_r[2] = _l0_io_r_resp_data_2_entries_perms_2_r;
  assign l0_r_resp_data[2].pbmts[3]  = _l0_io_r_resp_data_2_entries_pbmts_3;
  assign l0_r_resp_data[2].ppns[3]   = _l0_io_r_resp_data_2_entries_ppns_3;
  assign l0_r_resp_data[2].vs[3]     = _l0_io_r_resp_data_2_entries_vs_3;
  assign l0_r_resp_data[2].onlypf[3] = _l0_io_r_resp_data_2_entries_onlypf_3;
  assign l0_r_resp_data[2].perm_d[3] = _l0_io_r_resp_data_2_entries_perms_3_d;
  assign l0_r_resp_data[2].perm_a[3] = _l0_io_r_resp_data_2_entries_perms_3_a;
  assign l0_r_resp_data[2].perm_g[3] = _l0_io_r_resp_data_2_entries_perms_3_g;
  assign l0_r_resp_data[2].perm_u[3] = _l0_io_r_resp_data_2_entries_perms_3_u;
  assign l0_r_resp_data[2].perm_x[3] = _l0_io_r_resp_data_2_entries_perms_3_x;
  assign l0_r_resp_data[2].perm_w[3] = _l0_io_r_resp_data_2_entries_perms_3_w;
  assign l0_r_resp_data[2].perm_r[3] = _l0_io_r_resp_data_2_entries_perms_3_r;
  assign l0_r_resp_data[2].pbmts[4]  = _l0_io_r_resp_data_2_entries_pbmts_4;
  assign l0_r_resp_data[2].ppns[4]   = _l0_io_r_resp_data_2_entries_ppns_4;
  assign l0_r_resp_data[2].vs[4]     = _l0_io_r_resp_data_2_entries_vs_4;
  assign l0_r_resp_data[2].onlypf[4] = _l0_io_r_resp_data_2_entries_onlypf_4;
  assign l0_r_resp_data[2].perm_d[4] = _l0_io_r_resp_data_2_entries_perms_4_d;
  assign l0_r_resp_data[2].perm_a[4] = _l0_io_r_resp_data_2_entries_perms_4_a;
  assign l0_r_resp_data[2].perm_g[4] = _l0_io_r_resp_data_2_entries_perms_4_g;
  assign l0_r_resp_data[2].perm_u[4] = _l0_io_r_resp_data_2_entries_perms_4_u;
  assign l0_r_resp_data[2].perm_x[4] = _l0_io_r_resp_data_2_entries_perms_4_x;
  assign l0_r_resp_data[2].perm_w[4] = _l0_io_r_resp_data_2_entries_perms_4_w;
  assign l0_r_resp_data[2].perm_r[4] = _l0_io_r_resp_data_2_entries_perms_4_r;
  assign l0_r_resp_data[2].pbmts[5]  = _l0_io_r_resp_data_2_entries_pbmts_5;
  assign l0_r_resp_data[2].ppns[5]   = _l0_io_r_resp_data_2_entries_ppns_5;
  assign l0_r_resp_data[2].vs[5]     = _l0_io_r_resp_data_2_entries_vs_5;
  assign l0_r_resp_data[2].onlypf[5] = _l0_io_r_resp_data_2_entries_onlypf_5;
  assign l0_r_resp_data[2].perm_d[5] = _l0_io_r_resp_data_2_entries_perms_5_d;
  assign l0_r_resp_data[2].perm_a[5] = _l0_io_r_resp_data_2_entries_perms_5_a;
  assign l0_r_resp_data[2].perm_g[5] = _l0_io_r_resp_data_2_entries_perms_5_g;
  assign l0_r_resp_data[2].perm_u[5] = _l0_io_r_resp_data_2_entries_perms_5_u;
  assign l0_r_resp_data[2].perm_x[5] = _l0_io_r_resp_data_2_entries_perms_5_x;
  assign l0_r_resp_data[2].perm_w[5] = _l0_io_r_resp_data_2_entries_perms_5_w;
  assign l0_r_resp_data[2].perm_r[5] = _l0_io_r_resp_data_2_entries_perms_5_r;
  assign l0_r_resp_data[2].pbmts[6]  = _l0_io_r_resp_data_2_entries_pbmts_6;
  assign l0_r_resp_data[2].ppns[6]   = _l0_io_r_resp_data_2_entries_ppns_6;
  assign l0_r_resp_data[2].vs[6]     = _l0_io_r_resp_data_2_entries_vs_6;
  assign l0_r_resp_data[2].onlypf[6] = _l0_io_r_resp_data_2_entries_onlypf_6;
  assign l0_r_resp_data[2].perm_d[6] = _l0_io_r_resp_data_2_entries_perms_6_d;
  assign l0_r_resp_data[2].perm_a[6] = _l0_io_r_resp_data_2_entries_perms_6_a;
  assign l0_r_resp_data[2].perm_g[6] = _l0_io_r_resp_data_2_entries_perms_6_g;
  assign l0_r_resp_data[2].perm_u[6] = _l0_io_r_resp_data_2_entries_perms_6_u;
  assign l0_r_resp_data[2].perm_x[6] = _l0_io_r_resp_data_2_entries_perms_6_x;
  assign l0_r_resp_data[2].perm_w[6] = _l0_io_r_resp_data_2_entries_perms_6_w;
  assign l0_r_resp_data[2].perm_r[6] = _l0_io_r_resp_data_2_entries_perms_6_r;
  assign l0_r_resp_data[2].pbmts[7]  = _l0_io_r_resp_data_2_entries_pbmts_7;
  assign l0_r_resp_data[2].ppns[7]   = _l0_io_r_resp_data_2_entries_ppns_7;
  assign l0_r_resp_data[2].vs[7]     = _l0_io_r_resp_data_2_entries_vs_7;
  assign l0_r_resp_data[2].onlypf[7] = _l0_io_r_resp_data_2_entries_onlypf_7;
  assign l0_r_resp_data[2].perm_d[7] = _l0_io_r_resp_data_2_entries_perms_7_d;
  assign l0_r_resp_data[2].perm_a[7] = _l0_io_r_resp_data_2_entries_perms_7_a;
  assign l0_r_resp_data[2].perm_g[7] = _l0_io_r_resp_data_2_entries_perms_7_g;
  assign l0_r_resp_data[2].perm_u[7] = _l0_io_r_resp_data_2_entries_perms_7_u;
  assign l0_r_resp_data[2].perm_x[7] = _l0_io_r_resp_data_2_entries_perms_7_x;
  assign l0_r_resp_data[2].perm_w[7] = _l0_io_r_resp_data_2_entries_perms_7_w;
  assign l0_r_resp_data[2].perm_r[7] = _l0_io_r_resp_data_2_entries_perms_7_r;
  assign l0_r_resp_data[2].prefetch = _l0_io_r_resp_data_2_entries_prefetch;
  assign l0_r_resp_data[3].tag      = _l0_io_r_resp_data_3_entries_tag;
  assign l0_r_resp_data[3].asid     = _l0_io_r_resp_data_3_entries_asid;
  assign l0_r_resp_data[3].vmid     = _l0_io_r_resp_data_3_entries_vmid;
  assign l0_r_resp_data[3].pbmts[0]  = _l0_io_r_resp_data_3_entries_pbmts_0;
  assign l0_r_resp_data[3].ppns[0]   = _l0_io_r_resp_data_3_entries_ppns_0;
  assign l0_r_resp_data[3].vs[0]     = _l0_io_r_resp_data_3_entries_vs_0;
  assign l0_r_resp_data[3].onlypf[0] = _l0_io_r_resp_data_3_entries_onlypf_0;
  assign l0_r_resp_data[3].perm_d[0] = _l0_io_r_resp_data_3_entries_perms_0_d;
  assign l0_r_resp_data[3].perm_a[0] = _l0_io_r_resp_data_3_entries_perms_0_a;
  assign l0_r_resp_data[3].perm_g[0] = _l0_io_r_resp_data_3_entries_perms_0_g;
  assign l0_r_resp_data[3].perm_u[0] = _l0_io_r_resp_data_3_entries_perms_0_u;
  assign l0_r_resp_data[3].perm_x[0] = _l0_io_r_resp_data_3_entries_perms_0_x;
  assign l0_r_resp_data[3].perm_w[0] = _l0_io_r_resp_data_3_entries_perms_0_w;
  assign l0_r_resp_data[3].perm_r[0] = _l0_io_r_resp_data_3_entries_perms_0_r;
  assign l0_r_resp_data[3].pbmts[1]  = _l0_io_r_resp_data_3_entries_pbmts_1;
  assign l0_r_resp_data[3].ppns[1]   = _l0_io_r_resp_data_3_entries_ppns_1;
  assign l0_r_resp_data[3].vs[1]     = _l0_io_r_resp_data_3_entries_vs_1;
  assign l0_r_resp_data[3].onlypf[1] = _l0_io_r_resp_data_3_entries_onlypf_1;
  assign l0_r_resp_data[3].perm_d[1] = _l0_io_r_resp_data_3_entries_perms_1_d;
  assign l0_r_resp_data[3].perm_a[1] = _l0_io_r_resp_data_3_entries_perms_1_a;
  assign l0_r_resp_data[3].perm_g[1] = _l0_io_r_resp_data_3_entries_perms_1_g;
  assign l0_r_resp_data[3].perm_u[1] = _l0_io_r_resp_data_3_entries_perms_1_u;
  assign l0_r_resp_data[3].perm_x[1] = _l0_io_r_resp_data_3_entries_perms_1_x;
  assign l0_r_resp_data[3].perm_w[1] = _l0_io_r_resp_data_3_entries_perms_1_w;
  assign l0_r_resp_data[3].perm_r[1] = _l0_io_r_resp_data_3_entries_perms_1_r;
  assign l0_r_resp_data[3].pbmts[2]  = _l0_io_r_resp_data_3_entries_pbmts_2;
  assign l0_r_resp_data[3].ppns[2]   = _l0_io_r_resp_data_3_entries_ppns_2;
  assign l0_r_resp_data[3].vs[2]     = _l0_io_r_resp_data_3_entries_vs_2;
  assign l0_r_resp_data[3].onlypf[2] = _l0_io_r_resp_data_3_entries_onlypf_2;
  assign l0_r_resp_data[3].perm_d[2] = _l0_io_r_resp_data_3_entries_perms_2_d;
  assign l0_r_resp_data[3].perm_a[2] = _l0_io_r_resp_data_3_entries_perms_2_a;
  assign l0_r_resp_data[3].perm_g[2] = _l0_io_r_resp_data_3_entries_perms_2_g;
  assign l0_r_resp_data[3].perm_u[2] = _l0_io_r_resp_data_3_entries_perms_2_u;
  assign l0_r_resp_data[3].perm_x[2] = _l0_io_r_resp_data_3_entries_perms_2_x;
  assign l0_r_resp_data[3].perm_w[2] = _l0_io_r_resp_data_3_entries_perms_2_w;
  assign l0_r_resp_data[3].perm_r[2] = _l0_io_r_resp_data_3_entries_perms_2_r;
  assign l0_r_resp_data[3].pbmts[3]  = _l0_io_r_resp_data_3_entries_pbmts_3;
  assign l0_r_resp_data[3].ppns[3]   = _l0_io_r_resp_data_3_entries_ppns_3;
  assign l0_r_resp_data[3].vs[3]     = _l0_io_r_resp_data_3_entries_vs_3;
  assign l0_r_resp_data[3].onlypf[3] = _l0_io_r_resp_data_3_entries_onlypf_3;
  assign l0_r_resp_data[3].perm_d[3] = _l0_io_r_resp_data_3_entries_perms_3_d;
  assign l0_r_resp_data[3].perm_a[3] = _l0_io_r_resp_data_3_entries_perms_3_a;
  assign l0_r_resp_data[3].perm_g[3] = _l0_io_r_resp_data_3_entries_perms_3_g;
  assign l0_r_resp_data[3].perm_u[3] = _l0_io_r_resp_data_3_entries_perms_3_u;
  assign l0_r_resp_data[3].perm_x[3] = _l0_io_r_resp_data_3_entries_perms_3_x;
  assign l0_r_resp_data[3].perm_w[3] = _l0_io_r_resp_data_3_entries_perms_3_w;
  assign l0_r_resp_data[3].perm_r[3] = _l0_io_r_resp_data_3_entries_perms_3_r;
  assign l0_r_resp_data[3].pbmts[4]  = _l0_io_r_resp_data_3_entries_pbmts_4;
  assign l0_r_resp_data[3].ppns[4]   = _l0_io_r_resp_data_3_entries_ppns_4;
  assign l0_r_resp_data[3].vs[4]     = _l0_io_r_resp_data_3_entries_vs_4;
  assign l0_r_resp_data[3].onlypf[4] = _l0_io_r_resp_data_3_entries_onlypf_4;
  assign l0_r_resp_data[3].perm_d[4] = _l0_io_r_resp_data_3_entries_perms_4_d;
  assign l0_r_resp_data[3].perm_a[4] = _l0_io_r_resp_data_3_entries_perms_4_a;
  assign l0_r_resp_data[3].perm_g[4] = _l0_io_r_resp_data_3_entries_perms_4_g;
  assign l0_r_resp_data[3].perm_u[4] = _l0_io_r_resp_data_3_entries_perms_4_u;
  assign l0_r_resp_data[3].perm_x[4] = _l0_io_r_resp_data_3_entries_perms_4_x;
  assign l0_r_resp_data[3].perm_w[4] = _l0_io_r_resp_data_3_entries_perms_4_w;
  assign l0_r_resp_data[3].perm_r[4] = _l0_io_r_resp_data_3_entries_perms_4_r;
  assign l0_r_resp_data[3].pbmts[5]  = _l0_io_r_resp_data_3_entries_pbmts_5;
  assign l0_r_resp_data[3].ppns[5]   = _l0_io_r_resp_data_3_entries_ppns_5;
  assign l0_r_resp_data[3].vs[5]     = _l0_io_r_resp_data_3_entries_vs_5;
  assign l0_r_resp_data[3].onlypf[5] = _l0_io_r_resp_data_3_entries_onlypf_5;
  assign l0_r_resp_data[3].perm_d[5] = _l0_io_r_resp_data_3_entries_perms_5_d;
  assign l0_r_resp_data[3].perm_a[5] = _l0_io_r_resp_data_3_entries_perms_5_a;
  assign l0_r_resp_data[3].perm_g[5] = _l0_io_r_resp_data_3_entries_perms_5_g;
  assign l0_r_resp_data[3].perm_u[5] = _l0_io_r_resp_data_3_entries_perms_5_u;
  assign l0_r_resp_data[3].perm_x[5] = _l0_io_r_resp_data_3_entries_perms_5_x;
  assign l0_r_resp_data[3].perm_w[5] = _l0_io_r_resp_data_3_entries_perms_5_w;
  assign l0_r_resp_data[3].perm_r[5] = _l0_io_r_resp_data_3_entries_perms_5_r;
  assign l0_r_resp_data[3].pbmts[6]  = _l0_io_r_resp_data_3_entries_pbmts_6;
  assign l0_r_resp_data[3].ppns[6]   = _l0_io_r_resp_data_3_entries_ppns_6;
  assign l0_r_resp_data[3].vs[6]     = _l0_io_r_resp_data_3_entries_vs_6;
  assign l0_r_resp_data[3].onlypf[6] = _l0_io_r_resp_data_3_entries_onlypf_6;
  assign l0_r_resp_data[3].perm_d[6] = _l0_io_r_resp_data_3_entries_perms_6_d;
  assign l0_r_resp_data[3].perm_a[6] = _l0_io_r_resp_data_3_entries_perms_6_a;
  assign l0_r_resp_data[3].perm_g[6] = _l0_io_r_resp_data_3_entries_perms_6_g;
  assign l0_r_resp_data[3].perm_u[6] = _l0_io_r_resp_data_3_entries_perms_6_u;
  assign l0_r_resp_data[3].perm_x[6] = _l0_io_r_resp_data_3_entries_perms_6_x;
  assign l0_r_resp_data[3].perm_w[6] = _l0_io_r_resp_data_3_entries_perms_6_w;
  assign l0_r_resp_data[3].perm_r[6] = _l0_io_r_resp_data_3_entries_perms_6_r;
  assign l0_r_resp_data[3].pbmts[7]  = _l0_io_r_resp_data_3_entries_pbmts_7;
  assign l0_r_resp_data[3].ppns[7]   = _l0_io_r_resp_data_3_entries_ppns_7;
  assign l0_r_resp_data[3].vs[7]     = _l0_io_r_resp_data_3_entries_vs_7;
  assign l0_r_resp_data[3].onlypf[7] = _l0_io_r_resp_data_3_entries_onlypf_7;
  assign l0_r_resp_data[3].perm_d[7] = _l0_io_r_resp_data_3_entries_perms_7_d;
  assign l0_r_resp_data[3].perm_a[7] = _l0_io_r_resp_data_3_entries_perms_7_a;
  assign l0_r_resp_data[3].perm_g[7] = _l0_io_r_resp_data_3_entries_perms_7_g;
  assign l0_r_resp_data[3].perm_u[7] = _l0_io_r_resp_data_3_entries_perms_7_u;
  assign l0_r_resp_data[3].perm_x[7] = _l0_io_r_resp_data_3_entries_perms_7_x;
  assign l0_r_resp_data[3].perm_w[7] = _l0_io_r_resp_data_3_entries_perms_7_w;
  assign l0_r_resp_data[3].perm_r[7] = _l0_io_r_resp_data_3_entries_perms_7_r;
  assign l0_r_resp_data[3].prefetch = _l0_io_r_resp_data_3_entries_prefetch;

  xs_PtwCache_core u_core (
    .clock(clock), .reset(reset),
    .csr_mPBMTE(io_csr_mPBMTE), .csr_hPBMTE(io_csr_hPBMTE),
    .csr_satp_asid(csr_satp_asid_b), .csr_satp_changed(csr_satp_chg_b),
    .csr_vsatp_asid(csr_vsatp_asid_b), .csr_vsatp_changed(csr_vsatp_chg_b),
    .csr_hgatp_mode(csr_hgatp_mode_b), .csr_hgatp_vmid(csr_hgatp_vmid_b),
    .csr_hgatp_changed(csr_hgatp_chg_b), .csr_priv_virt(csr_priv_virt_b),
    .req_ready(io_req_ready), .req_valid(io_req_valid), .req_info(req_info_b),
    .req_isFirst(io_req_bits_isFirst), .req_isHptwReq(io_req_bits_isHptwReq), .req_hptwId(io_req_bits_hptwId),
    .resp_ready(io_resp_ready), .resp_valid(io_resp_valid), .resp_bits(core_resp),
    .refill_valid(io_refill_valid), .refill_ptes(io_refill_bits_ptes),
    .refill_levelOH_sp(io_refill_bits_levelOH_sp), .refill_levelOH_l0(io_refill_bits_levelOH_l0),
    .refill_levelOH_l1(io_refill_bits_levelOH_l1), .refill_levelOH_l2(io_refill_bits_levelOH_l2),
    .refill_levelOH_l3(io_refill_bits_levelOH_l3),
    .refill_req_info_dup_0(refill_ri0_b), .refill_req_info_dup_1(refill_ri1_b), .refill_req_info_dup_2(refill_ri2_b),
    .refill_level_dup_0(io_refill_bits_level_dup_0), .refill_level_dup_2(io_refill_bits_level_dup_2),
    .refill_sel_pte_dup_0(io_refill_bits_sel_pte_dup_0), .refill_sel_pte_dup_2(io_refill_bits_sel_pte_dup_2),
    .sfence_dup_0(sfence0_b),
    .sfence_dup_1_valid(io_sfence_dup_1_valid), .sfence_dup_1_id(io_sfence_dup_1_bits_id),
    .sfence_dup_2_valid(io_sfence_dup_2_valid), .sfence_dup_2_rs1(io_sfence_dup_2_bits_rs1),
    .sfence_dup_2_rs2(io_sfence_dup_2_bits_rs2), .sfence_dup_2_id(io_sfence_dup_2_bits_id),
    .l1_r_req_valid(l1_r_req_valid), .l1_r_req_setIdx(l1_r_req_setIdx), .l1_r_resp_data(l1_r_resp_data),
    .l1_w_req_valid(l1_w_req_valid), .l1_w_req_setIdx(l1_w_req_setIdx), .l1_w_req_data(l1_w_req_data), .l1_w_req_waymask(l1_w_req_waymask),
    .l0_r_req_valid(l0_r_req_valid), .l0_r_req_setIdx(l0_r_req_setIdx), .l0_r_resp_data(l0_r_resp_data),
    .l0_w_req_valid(l0_w_req_valid), .l0_w_req_setIdx(l0_w_req_setIdx), .l0_w_req_data(l0_w_req_data), .l0_w_req_waymask(l0_w_req_waymask),
    .l0_clock_en(l0_clock_en), .l1_clock_en(l1_clock_en),
    .perf(core_perf)
  );

  // ---- core_resp 解包到 io_resp_bits_* ----
  assign io_resp_bits_req_info_vpn     = core_resp.req_info.vpn;
  assign io_resp_bits_req_info_s2xlate = core_resp.req_info.s2xlate;
  assign io_resp_bits_req_info_source  = core_resp.req_info.source;
  assign io_resp_bits_isFirst   = core_resp.isFirst;
  assign io_resp_bits_hit       = core_resp.hit;
  assign io_resp_bits_prefetch  = core_resp.prefetch;
  assign io_resp_bits_bypassed  = core_resp.bypassed;
  assign io_resp_bits_toFsm_l3Hit = core_resp.toFsm_l3Hit;
  assign io_resp_bits_toFsm_l2Hit = core_resp.toFsm_l2Hit;
  assign io_resp_bits_toFsm_l1Hit = core_resp.toFsm_l1Hit;
  assign io_resp_bits_toFsm_ppn   = core_resp.toFsm_ppn;
  assign io_resp_bits_toFsm_stage1Hit = core_resp.toFsm_stage1Hit;
  assign io_resp_bits_stage1_entry_0_tag    = core_resp.stage1_entry[0].tag;
  assign io_resp_bits_stage1_entry_0_asid   = core_resp.stage1_entry[0].asid;
  assign io_resp_bits_stage1_entry_0_vmid   = core_resp.stage1_entry[0].vmid;
  assign io_resp_bits_stage1_entry_0_n      = core_resp.stage1_entry[0].n;
  assign io_resp_bits_stage1_entry_0_pbmt   = core_resp.stage1_entry[0].pbmt;
  assign io_resp_bits_stage1_entry_0_perm_d = core_resp.stage1_entry[0].perm.d;
  assign io_resp_bits_stage1_entry_0_perm_a = core_resp.stage1_entry[0].perm.a;
  assign io_resp_bits_stage1_entry_0_perm_g = core_resp.stage1_entry[0].perm.g;
  assign io_resp_bits_stage1_entry_0_perm_u = core_resp.stage1_entry[0].perm.u;
  assign io_resp_bits_stage1_entry_0_perm_x = core_resp.stage1_entry[0].perm.x;
  assign io_resp_bits_stage1_entry_0_perm_w = core_resp.stage1_entry[0].perm.w;
  assign io_resp_bits_stage1_entry_0_perm_r = core_resp.stage1_entry[0].perm.r;
  assign io_resp_bits_stage1_entry_0_level  = core_resp.stage1_entry[0].level;
  assign io_resp_bits_stage1_entry_0_v      = core_resp.stage1_entry[0].v;
  assign io_resp_bits_stage1_entry_0_ppn    = core_resp.stage1_entry[0].ppn;
  assign io_resp_bits_stage1_entry_0_ppn_low = core_resp.stage1_entry[0].ppn_low;
  assign io_resp_bits_stage1_entry_0_pf     = core_resp.stage1_entry[0].pf;
  assign io_resp_bits_stage1_entry_1_tag    = core_resp.stage1_entry[1].tag;
  assign io_resp_bits_stage1_entry_1_asid   = core_resp.stage1_entry[1].asid;
  assign io_resp_bits_stage1_entry_1_vmid   = core_resp.stage1_entry[1].vmid;
  assign io_resp_bits_stage1_entry_1_n      = core_resp.stage1_entry[1].n;
  assign io_resp_bits_stage1_entry_1_pbmt   = core_resp.stage1_entry[1].pbmt;
  assign io_resp_bits_stage1_entry_1_perm_d = core_resp.stage1_entry[1].perm.d;
  assign io_resp_bits_stage1_entry_1_perm_a = core_resp.stage1_entry[1].perm.a;
  assign io_resp_bits_stage1_entry_1_perm_g = core_resp.stage1_entry[1].perm.g;
  assign io_resp_bits_stage1_entry_1_perm_u = core_resp.stage1_entry[1].perm.u;
  assign io_resp_bits_stage1_entry_1_perm_x = core_resp.stage1_entry[1].perm.x;
  assign io_resp_bits_stage1_entry_1_perm_w = core_resp.stage1_entry[1].perm.w;
  assign io_resp_bits_stage1_entry_1_perm_r = core_resp.stage1_entry[1].perm.r;
  assign io_resp_bits_stage1_entry_1_level  = core_resp.stage1_entry[1].level;
  assign io_resp_bits_stage1_entry_1_v      = core_resp.stage1_entry[1].v;
  assign io_resp_bits_stage1_entry_1_ppn    = core_resp.stage1_entry[1].ppn;
  assign io_resp_bits_stage1_entry_1_ppn_low = core_resp.stage1_entry[1].ppn_low;
  assign io_resp_bits_stage1_entry_1_pf     = core_resp.stage1_entry[1].pf;
  assign io_resp_bits_stage1_entry_2_tag    = core_resp.stage1_entry[2].tag;
  assign io_resp_bits_stage1_entry_2_asid   = core_resp.stage1_entry[2].asid;
  assign io_resp_bits_stage1_entry_2_vmid   = core_resp.stage1_entry[2].vmid;
  assign io_resp_bits_stage1_entry_2_n      = core_resp.stage1_entry[2].n;
  assign io_resp_bits_stage1_entry_2_pbmt   = core_resp.stage1_entry[2].pbmt;
  assign io_resp_bits_stage1_entry_2_perm_d = core_resp.stage1_entry[2].perm.d;
  assign io_resp_bits_stage1_entry_2_perm_a = core_resp.stage1_entry[2].perm.a;
  assign io_resp_bits_stage1_entry_2_perm_g = core_resp.stage1_entry[2].perm.g;
  assign io_resp_bits_stage1_entry_2_perm_u = core_resp.stage1_entry[2].perm.u;
  assign io_resp_bits_stage1_entry_2_perm_x = core_resp.stage1_entry[2].perm.x;
  assign io_resp_bits_stage1_entry_2_perm_w = core_resp.stage1_entry[2].perm.w;
  assign io_resp_bits_stage1_entry_2_perm_r = core_resp.stage1_entry[2].perm.r;
  assign io_resp_bits_stage1_entry_2_level  = core_resp.stage1_entry[2].level;
  assign io_resp_bits_stage1_entry_2_v      = core_resp.stage1_entry[2].v;
  assign io_resp_bits_stage1_entry_2_ppn    = core_resp.stage1_entry[2].ppn;
  assign io_resp_bits_stage1_entry_2_ppn_low = core_resp.stage1_entry[2].ppn_low;
  assign io_resp_bits_stage1_entry_2_pf     = core_resp.stage1_entry[2].pf;
  assign io_resp_bits_stage1_entry_3_tag    = core_resp.stage1_entry[3].tag;
  assign io_resp_bits_stage1_entry_3_asid   = core_resp.stage1_entry[3].asid;
  assign io_resp_bits_stage1_entry_3_vmid   = core_resp.stage1_entry[3].vmid;
  assign io_resp_bits_stage1_entry_3_n      = core_resp.stage1_entry[3].n;
  assign io_resp_bits_stage1_entry_3_pbmt   = core_resp.stage1_entry[3].pbmt;
  assign io_resp_bits_stage1_entry_3_perm_d = core_resp.stage1_entry[3].perm.d;
  assign io_resp_bits_stage1_entry_3_perm_a = core_resp.stage1_entry[3].perm.a;
  assign io_resp_bits_stage1_entry_3_perm_g = core_resp.stage1_entry[3].perm.g;
  assign io_resp_bits_stage1_entry_3_perm_u = core_resp.stage1_entry[3].perm.u;
  assign io_resp_bits_stage1_entry_3_perm_x = core_resp.stage1_entry[3].perm.x;
  assign io_resp_bits_stage1_entry_3_perm_w = core_resp.stage1_entry[3].perm.w;
  assign io_resp_bits_stage1_entry_3_perm_r = core_resp.stage1_entry[3].perm.r;
  assign io_resp_bits_stage1_entry_3_level  = core_resp.stage1_entry[3].level;
  assign io_resp_bits_stage1_entry_3_v      = core_resp.stage1_entry[3].v;
  assign io_resp_bits_stage1_entry_3_ppn    = core_resp.stage1_entry[3].ppn;
  assign io_resp_bits_stage1_entry_3_ppn_low = core_resp.stage1_entry[3].ppn_low;
  assign io_resp_bits_stage1_entry_3_pf     = core_resp.stage1_entry[3].pf;
  assign io_resp_bits_stage1_entry_4_tag    = core_resp.stage1_entry[4].tag;
  assign io_resp_bits_stage1_entry_4_asid   = core_resp.stage1_entry[4].asid;
  assign io_resp_bits_stage1_entry_4_vmid   = core_resp.stage1_entry[4].vmid;
  assign io_resp_bits_stage1_entry_4_n      = core_resp.stage1_entry[4].n;
  assign io_resp_bits_stage1_entry_4_pbmt   = core_resp.stage1_entry[4].pbmt;
  assign io_resp_bits_stage1_entry_4_perm_d = core_resp.stage1_entry[4].perm.d;
  assign io_resp_bits_stage1_entry_4_perm_a = core_resp.stage1_entry[4].perm.a;
  assign io_resp_bits_stage1_entry_4_perm_g = core_resp.stage1_entry[4].perm.g;
  assign io_resp_bits_stage1_entry_4_perm_u = core_resp.stage1_entry[4].perm.u;
  assign io_resp_bits_stage1_entry_4_perm_x = core_resp.stage1_entry[4].perm.x;
  assign io_resp_bits_stage1_entry_4_perm_w = core_resp.stage1_entry[4].perm.w;
  assign io_resp_bits_stage1_entry_4_perm_r = core_resp.stage1_entry[4].perm.r;
  assign io_resp_bits_stage1_entry_4_level  = core_resp.stage1_entry[4].level;
  assign io_resp_bits_stage1_entry_4_v      = core_resp.stage1_entry[4].v;
  assign io_resp_bits_stage1_entry_4_ppn    = core_resp.stage1_entry[4].ppn;
  assign io_resp_bits_stage1_entry_4_ppn_low = core_resp.stage1_entry[4].ppn_low;
  assign io_resp_bits_stage1_entry_4_pf     = core_resp.stage1_entry[4].pf;
  assign io_resp_bits_stage1_entry_5_tag    = core_resp.stage1_entry[5].tag;
  assign io_resp_bits_stage1_entry_5_asid   = core_resp.stage1_entry[5].asid;
  assign io_resp_bits_stage1_entry_5_vmid   = core_resp.stage1_entry[5].vmid;
  assign io_resp_bits_stage1_entry_5_n      = core_resp.stage1_entry[5].n;
  assign io_resp_bits_stage1_entry_5_pbmt   = core_resp.stage1_entry[5].pbmt;
  assign io_resp_bits_stage1_entry_5_perm_d = core_resp.stage1_entry[5].perm.d;
  assign io_resp_bits_stage1_entry_5_perm_a = core_resp.stage1_entry[5].perm.a;
  assign io_resp_bits_stage1_entry_5_perm_g = core_resp.stage1_entry[5].perm.g;
  assign io_resp_bits_stage1_entry_5_perm_u = core_resp.stage1_entry[5].perm.u;
  assign io_resp_bits_stage1_entry_5_perm_x = core_resp.stage1_entry[5].perm.x;
  assign io_resp_bits_stage1_entry_5_perm_w = core_resp.stage1_entry[5].perm.w;
  assign io_resp_bits_stage1_entry_5_perm_r = core_resp.stage1_entry[5].perm.r;
  assign io_resp_bits_stage1_entry_5_level  = core_resp.stage1_entry[5].level;
  assign io_resp_bits_stage1_entry_5_v      = core_resp.stage1_entry[5].v;
  assign io_resp_bits_stage1_entry_5_ppn    = core_resp.stage1_entry[5].ppn;
  assign io_resp_bits_stage1_entry_5_ppn_low = core_resp.stage1_entry[5].ppn_low;
  assign io_resp_bits_stage1_entry_5_pf     = core_resp.stage1_entry[5].pf;
  assign io_resp_bits_stage1_entry_6_tag    = core_resp.stage1_entry[6].tag;
  assign io_resp_bits_stage1_entry_6_asid   = core_resp.stage1_entry[6].asid;
  assign io_resp_bits_stage1_entry_6_vmid   = core_resp.stage1_entry[6].vmid;
  assign io_resp_bits_stage1_entry_6_n      = core_resp.stage1_entry[6].n;
  assign io_resp_bits_stage1_entry_6_pbmt   = core_resp.stage1_entry[6].pbmt;
  assign io_resp_bits_stage1_entry_6_perm_d = core_resp.stage1_entry[6].perm.d;
  assign io_resp_bits_stage1_entry_6_perm_a = core_resp.stage1_entry[6].perm.a;
  assign io_resp_bits_stage1_entry_6_perm_g = core_resp.stage1_entry[6].perm.g;
  assign io_resp_bits_stage1_entry_6_perm_u = core_resp.stage1_entry[6].perm.u;
  assign io_resp_bits_stage1_entry_6_perm_x = core_resp.stage1_entry[6].perm.x;
  assign io_resp_bits_stage1_entry_6_perm_w = core_resp.stage1_entry[6].perm.w;
  assign io_resp_bits_stage1_entry_6_perm_r = core_resp.stage1_entry[6].perm.r;
  assign io_resp_bits_stage1_entry_6_level  = core_resp.stage1_entry[6].level;
  assign io_resp_bits_stage1_entry_6_v      = core_resp.stage1_entry[6].v;
  assign io_resp_bits_stage1_entry_6_ppn    = core_resp.stage1_entry[6].ppn;
  assign io_resp_bits_stage1_entry_6_ppn_low = core_resp.stage1_entry[6].ppn_low;
  assign io_resp_bits_stage1_entry_6_pf     = core_resp.stage1_entry[6].pf;
  assign io_resp_bits_stage1_entry_7_tag    = core_resp.stage1_entry[7].tag;
  assign io_resp_bits_stage1_entry_7_asid   = core_resp.stage1_entry[7].asid;
  assign io_resp_bits_stage1_entry_7_vmid   = core_resp.stage1_entry[7].vmid;
  assign io_resp_bits_stage1_entry_7_n      = core_resp.stage1_entry[7].n;
  assign io_resp_bits_stage1_entry_7_pbmt   = core_resp.stage1_entry[7].pbmt;
  assign io_resp_bits_stage1_entry_7_perm_d = core_resp.stage1_entry[7].perm.d;
  assign io_resp_bits_stage1_entry_7_perm_a = core_resp.stage1_entry[7].perm.a;
  assign io_resp_bits_stage1_entry_7_perm_g = core_resp.stage1_entry[7].perm.g;
  assign io_resp_bits_stage1_entry_7_perm_u = core_resp.stage1_entry[7].perm.u;
  assign io_resp_bits_stage1_entry_7_perm_x = core_resp.stage1_entry[7].perm.x;
  assign io_resp_bits_stage1_entry_7_perm_w = core_resp.stage1_entry[7].perm.w;
  assign io_resp_bits_stage1_entry_7_perm_r = core_resp.stage1_entry[7].perm.r;
  assign io_resp_bits_stage1_entry_7_level  = core_resp.stage1_entry[7].level;
  assign io_resp_bits_stage1_entry_7_v      = core_resp.stage1_entry[7].v;
  assign io_resp_bits_stage1_entry_7_ppn    = core_resp.stage1_entry[7].ppn;
  assign io_resp_bits_stage1_entry_7_ppn_low = core_resp.stage1_entry[7].ppn_low;
  assign io_resp_bits_stage1_entry_7_pf     = core_resp.stage1_entry[7].pf;
  assign io_resp_bits_stage1_pteidx_0 = core_resp.stage1_pteidx[0];
  assign io_resp_bits_stage1_pteidx_1 = core_resp.stage1_pteidx[1];
  assign io_resp_bits_stage1_pteidx_2 = core_resp.stage1_pteidx[2];
  assign io_resp_bits_stage1_pteidx_3 = core_resp.stage1_pteidx[3];
  assign io_resp_bits_stage1_pteidx_4 = core_resp.stage1_pteidx[4];
  assign io_resp_bits_stage1_pteidx_5 = core_resp.stage1_pteidx[5];
  assign io_resp_bits_stage1_pteidx_6 = core_resp.stage1_pteidx[6];
  assign io_resp_bits_stage1_pteidx_7 = core_resp.stage1_pteidx[7];
  assign io_resp_bits_stage1_not_super = core_resp.stage1_not_super;
  assign io_resp_bits_isHptwReq = core_resp.isHptwReq;
  assign io_resp_bits_toHptw_l3Hit = core_resp.toHptw_l3Hit;
  assign io_resp_bits_toHptw_l2Hit = core_resp.toHptw_l2Hit;
  assign io_resp_bits_toHptw_l1Hit = core_resp.toHptw_l1Hit;
  assign io_resp_bits_toHptw_ppn   = core_resp.toHptw_ppn;
  assign io_resp_bits_toHptw_id    = core_resp.toHptw_id;
  assign io_resp_bits_toHptw_resp_entry_tag  = core_resp.toHptw_entry.tag;
  assign io_resp_bits_toHptw_resp_entry_vmid = core_resp.toHptw_entry.vmid;
  assign io_resp_bits_toHptw_resp_entry_n    = core_resp.toHptw_entry.n;
  assign io_resp_bits_toHptw_resp_entry_pbmt = core_resp.toHptw_entry.pbmt;
  assign io_resp_bits_toHptw_resp_entry_ppn  = core_resp.toHptw_entry.ppn;
  assign io_resp_bits_toHptw_resp_entry_perm_d = core_resp.toHptw_entry.perm.d;
  assign io_resp_bits_toHptw_resp_entry_perm_a = core_resp.toHptw_entry.perm.a;
  assign io_resp_bits_toHptw_resp_entry_perm_g = core_resp.toHptw_entry.perm.g;
  assign io_resp_bits_toHptw_resp_entry_perm_u = core_resp.toHptw_entry.perm.u;
  assign io_resp_bits_toHptw_resp_entry_perm_x = core_resp.toHptw_entry.perm.x;
  assign io_resp_bits_toHptw_resp_entry_perm_w = core_resp.toHptw_entry.perm.w;
  assign io_resp_bits_toHptw_resp_entry_perm_r = core_resp.toHptw_entry.perm.r;
  assign io_resp_bits_toHptw_resp_entry_level = core_resp.toHptw_entry.level;
  assign io_resp_bits_toHptw_resp_gpf = core_resp.toHptw_gpf;
  assign io_resp_bits_toHptw_bypassed = core_resp.toHptw_bypassed;

  assign io_perf_0_value = core_perf[0];
  assign io_perf_1_value = core_perf[1];
  assign io_perf_2_value = core_perf[2];
  assign io_perf_3_value = core_perf[3];
  assign io_perf_4_value = core_perf[4];
  assign io_perf_5_value = core_perf[5];
  assign io_perf_6_value = core_perf[6];
  assign io_perf_7_value = core_perf[7];

  // ===== golden 黑盒存储/DFT 子模块（UT/FM 两侧共用同一份 golden）=====
  SplittedSRAM l1 (
    .clock                                 (_ClockGate_1_Q),
    .reset                                 (reset),
    .io_r_req_valid                        (l1_r_req_valid),
    .io_r_req_bits_setIdx                  (l1_r_req_setIdx),
    .io_r_resp_data_0_entries_tag          (_l1_io_r_resp_data_0_entries_tag),
    .io_r_resp_data_0_entries_asid         (_l1_io_r_resp_data_0_entries_asid),
    .io_r_resp_data_0_entries_vmid         (_l1_io_r_resp_data_0_entries_vmid),
    .io_r_resp_data_0_entries_pbmts_0      (_l1_io_r_resp_data_0_entries_pbmts_0),
    .io_r_resp_data_0_entries_pbmts_1      (_l1_io_r_resp_data_0_entries_pbmts_1),
    .io_r_resp_data_0_entries_pbmts_2      (_l1_io_r_resp_data_0_entries_pbmts_2),
    .io_r_resp_data_0_entries_pbmts_3      (_l1_io_r_resp_data_0_entries_pbmts_3),
    .io_r_resp_data_0_entries_pbmts_4      (_l1_io_r_resp_data_0_entries_pbmts_4),
    .io_r_resp_data_0_entries_pbmts_5      (_l1_io_r_resp_data_0_entries_pbmts_5),
    .io_r_resp_data_0_entries_pbmts_6      (_l1_io_r_resp_data_0_entries_pbmts_6),
    .io_r_resp_data_0_entries_pbmts_7      (_l1_io_r_resp_data_0_entries_pbmts_7),
    .io_r_resp_data_0_entries_ppns_0       (_l1_io_r_resp_data_0_entries_ppns_0),
    .io_r_resp_data_0_entries_ppns_1       (_l1_io_r_resp_data_0_entries_ppns_1),
    .io_r_resp_data_0_entries_ppns_2       (_l1_io_r_resp_data_0_entries_ppns_2),
    .io_r_resp_data_0_entries_ppns_3       (_l1_io_r_resp_data_0_entries_ppns_3),
    .io_r_resp_data_0_entries_ppns_4       (_l1_io_r_resp_data_0_entries_ppns_4),
    .io_r_resp_data_0_entries_ppns_5       (_l1_io_r_resp_data_0_entries_ppns_5),
    .io_r_resp_data_0_entries_ppns_6       (_l1_io_r_resp_data_0_entries_ppns_6),
    .io_r_resp_data_0_entries_ppns_7       (_l1_io_r_resp_data_0_entries_ppns_7),
    .io_r_resp_data_0_entries_vs_0         (_l1_io_r_resp_data_0_entries_vs_0),
    .io_r_resp_data_0_entries_vs_1         (_l1_io_r_resp_data_0_entries_vs_1),
    .io_r_resp_data_0_entries_vs_2         (_l1_io_r_resp_data_0_entries_vs_2),
    .io_r_resp_data_0_entries_vs_3         (_l1_io_r_resp_data_0_entries_vs_3),
    .io_r_resp_data_0_entries_vs_4         (_l1_io_r_resp_data_0_entries_vs_4),
    .io_r_resp_data_0_entries_vs_5         (_l1_io_r_resp_data_0_entries_vs_5),
    .io_r_resp_data_0_entries_vs_6         (_l1_io_r_resp_data_0_entries_vs_6),
    .io_r_resp_data_0_entries_vs_7         (_l1_io_r_resp_data_0_entries_vs_7),
    .io_r_resp_data_0_entries_prefetch     (_l1_io_r_resp_data_0_entries_prefetch),
    .io_r_resp_data_1_entries_tag          (_l1_io_r_resp_data_1_entries_tag),
    .io_r_resp_data_1_entries_asid         (_l1_io_r_resp_data_1_entries_asid),
    .io_r_resp_data_1_entries_vmid         (_l1_io_r_resp_data_1_entries_vmid),
    .io_r_resp_data_1_entries_pbmts_0      (_l1_io_r_resp_data_1_entries_pbmts_0),
    .io_r_resp_data_1_entries_pbmts_1      (_l1_io_r_resp_data_1_entries_pbmts_1),
    .io_r_resp_data_1_entries_pbmts_2      (_l1_io_r_resp_data_1_entries_pbmts_2),
    .io_r_resp_data_1_entries_pbmts_3      (_l1_io_r_resp_data_1_entries_pbmts_3),
    .io_r_resp_data_1_entries_pbmts_4      (_l1_io_r_resp_data_1_entries_pbmts_4),
    .io_r_resp_data_1_entries_pbmts_5      (_l1_io_r_resp_data_1_entries_pbmts_5),
    .io_r_resp_data_1_entries_pbmts_6      (_l1_io_r_resp_data_1_entries_pbmts_6),
    .io_r_resp_data_1_entries_pbmts_7      (_l1_io_r_resp_data_1_entries_pbmts_7),
    .io_r_resp_data_1_entries_ppns_0       (_l1_io_r_resp_data_1_entries_ppns_0),
    .io_r_resp_data_1_entries_ppns_1       (_l1_io_r_resp_data_1_entries_ppns_1),
    .io_r_resp_data_1_entries_ppns_2       (_l1_io_r_resp_data_1_entries_ppns_2),
    .io_r_resp_data_1_entries_ppns_3       (_l1_io_r_resp_data_1_entries_ppns_3),
    .io_r_resp_data_1_entries_ppns_4       (_l1_io_r_resp_data_1_entries_ppns_4),
    .io_r_resp_data_1_entries_ppns_5       (_l1_io_r_resp_data_1_entries_ppns_5),
    .io_r_resp_data_1_entries_ppns_6       (_l1_io_r_resp_data_1_entries_ppns_6),
    .io_r_resp_data_1_entries_ppns_7       (_l1_io_r_resp_data_1_entries_ppns_7),
    .io_r_resp_data_1_entries_vs_0         (_l1_io_r_resp_data_1_entries_vs_0),
    .io_r_resp_data_1_entries_vs_1         (_l1_io_r_resp_data_1_entries_vs_1),
    .io_r_resp_data_1_entries_vs_2         (_l1_io_r_resp_data_1_entries_vs_2),
    .io_r_resp_data_1_entries_vs_3         (_l1_io_r_resp_data_1_entries_vs_3),
    .io_r_resp_data_1_entries_vs_4         (_l1_io_r_resp_data_1_entries_vs_4),
    .io_r_resp_data_1_entries_vs_5         (_l1_io_r_resp_data_1_entries_vs_5),
    .io_r_resp_data_1_entries_vs_6         (_l1_io_r_resp_data_1_entries_vs_6),
    .io_r_resp_data_1_entries_vs_7         (_l1_io_r_resp_data_1_entries_vs_7),
    .io_r_resp_data_1_entries_prefetch     (_l1_io_r_resp_data_1_entries_prefetch),
    .io_w_req_valid                        (l1_w_req_valid),
    .io_w_req_bits_setIdx                  (l1_w_req_setIdx),
    .io_w_req_bits_data_0_entries_tag      (l1_w_req_data.tag),
    .io_w_req_bits_data_0_entries_asid     (l1_w_req_data.asid),
    .io_w_req_bits_data_0_entries_vmid     (l1_w_req_data.vmid),
    .io_w_req_bits_data_0_entries_pbmts_0  (l1_w_req_data.pbmts[0]),
    .io_w_req_bits_data_0_entries_pbmts_1  (l1_w_req_data.pbmts[1]),
    .io_w_req_bits_data_0_entries_pbmts_2  (l1_w_req_data.pbmts[2]),
    .io_w_req_bits_data_0_entries_pbmts_3  (l1_w_req_data.pbmts[3]),
    .io_w_req_bits_data_0_entries_pbmts_4  (l1_w_req_data.pbmts[4]),
    .io_w_req_bits_data_0_entries_pbmts_5  (l1_w_req_data.pbmts[5]),
    .io_w_req_bits_data_0_entries_pbmts_6  (l1_w_req_data.pbmts[6]),
    .io_w_req_bits_data_0_entries_pbmts_7  (l1_w_req_data.pbmts[7]),
    .io_w_req_bits_data_0_entries_ppns_0   (l1_w_req_data.ppns[0]),
    .io_w_req_bits_data_0_entries_ppns_1   (l1_w_req_data.ppns[1]),
    .io_w_req_bits_data_0_entries_ppns_2   (l1_w_req_data.ppns[2]),
    .io_w_req_bits_data_0_entries_ppns_3   (l1_w_req_data.ppns[3]),
    .io_w_req_bits_data_0_entries_ppns_4   (l1_w_req_data.ppns[4]),
    .io_w_req_bits_data_0_entries_ppns_5   (l1_w_req_data.ppns[5]),
    .io_w_req_bits_data_0_entries_ppns_6   (l1_w_req_data.ppns[6]),
    .io_w_req_bits_data_0_entries_ppns_7   (l1_w_req_data.ppns[7]),
    .io_w_req_bits_data_0_entries_vs_0     (l1_w_req_data.vs[0]),
    .io_w_req_bits_data_0_entries_vs_1     (l1_w_req_data.vs[1]),
    .io_w_req_bits_data_0_entries_vs_2     (l1_w_req_data.vs[2]),
    .io_w_req_bits_data_0_entries_vs_3     (l1_w_req_data.vs[3]),
    .io_w_req_bits_data_0_entries_vs_4     (l1_w_req_data.vs[4]),
    .io_w_req_bits_data_0_entries_vs_5     (l1_w_req_data.vs[5]),
    .io_w_req_bits_data_0_entries_vs_6     (l1_w_req_data.vs[6]),
    .io_w_req_bits_data_0_entries_vs_7     (l1_w_req_data.vs[7]),
    .io_w_req_bits_data_0_entries_onlypf_0 (l1_w_req_data.onlypf[0]),
    .io_w_req_bits_data_0_entries_onlypf_1 (l1_w_req_data.onlypf[1]),
    .io_w_req_bits_data_0_entries_onlypf_2 (l1_w_req_data.onlypf[2]),
    .io_w_req_bits_data_0_entries_onlypf_3 (l1_w_req_data.onlypf[3]),
    .io_w_req_bits_data_0_entries_onlypf_4 (l1_w_req_data.onlypf[4]),
    .io_w_req_bits_data_0_entries_onlypf_5 (l1_w_req_data.onlypf[5]),
    .io_w_req_bits_data_0_entries_onlypf_6 (l1_w_req_data.onlypf[6]),
    .io_w_req_bits_data_0_entries_onlypf_7 (l1_w_req_data.onlypf[7]),
    .io_w_req_bits_data_0_entries_prefetch (l1_w_req_data.prefetch),
    .io_w_req_bits_data_1_entries_tag      (l1_w_req_data.tag),
    .io_w_req_bits_data_1_entries_asid     (l1_w_req_data.asid),
    .io_w_req_bits_data_1_entries_vmid     (l1_w_req_data.vmid),
    .io_w_req_bits_data_1_entries_pbmts_0  (l1_w_req_data.pbmts[0]),
    .io_w_req_bits_data_1_entries_pbmts_1  (l1_w_req_data.pbmts[1]),
    .io_w_req_bits_data_1_entries_pbmts_2  (l1_w_req_data.pbmts[2]),
    .io_w_req_bits_data_1_entries_pbmts_3  (l1_w_req_data.pbmts[3]),
    .io_w_req_bits_data_1_entries_pbmts_4  (l1_w_req_data.pbmts[4]),
    .io_w_req_bits_data_1_entries_pbmts_5  (l1_w_req_data.pbmts[5]),
    .io_w_req_bits_data_1_entries_pbmts_6  (l1_w_req_data.pbmts[6]),
    .io_w_req_bits_data_1_entries_pbmts_7  (l1_w_req_data.pbmts[7]),
    .io_w_req_bits_data_1_entries_ppns_0   (l1_w_req_data.ppns[0]),
    .io_w_req_bits_data_1_entries_ppns_1   (l1_w_req_data.ppns[1]),
    .io_w_req_bits_data_1_entries_ppns_2   (l1_w_req_data.ppns[2]),
    .io_w_req_bits_data_1_entries_ppns_3   (l1_w_req_data.ppns[3]),
    .io_w_req_bits_data_1_entries_ppns_4   (l1_w_req_data.ppns[4]),
    .io_w_req_bits_data_1_entries_ppns_5   (l1_w_req_data.ppns[5]),
    .io_w_req_bits_data_1_entries_ppns_6   (l1_w_req_data.ppns[6]),
    .io_w_req_bits_data_1_entries_ppns_7   (l1_w_req_data.ppns[7]),
    .io_w_req_bits_data_1_entries_vs_0     (l1_w_req_data.vs[0]),
    .io_w_req_bits_data_1_entries_vs_1     (l1_w_req_data.vs[1]),
    .io_w_req_bits_data_1_entries_vs_2     (l1_w_req_data.vs[2]),
    .io_w_req_bits_data_1_entries_vs_3     (l1_w_req_data.vs[3]),
    .io_w_req_bits_data_1_entries_vs_4     (l1_w_req_data.vs[4]),
    .io_w_req_bits_data_1_entries_vs_5     (l1_w_req_data.vs[5]),
    .io_w_req_bits_data_1_entries_vs_6     (l1_w_req_data.vs[6]),
    .io_w_req_bits_data_1_entries_vs_7     (l1_w_req_data.vs[7]),
    .io_w_req_bits_data_1_entries_onlypf_0 (l1_w_req_data.onlypf[0]),
    .io_w_req_bits_data_1_entries_onlypf_1 (l1_w_req_data.onlypf[1]),
    .io_w_req_bits_data_1_entries_onlypf_2 (l1_w_req_data.onlypf[2]),
    .io_w_req_bits_data_1_entries_onlypf_3 (l1_w_req_data.onlypf[3]),
    .io_w_req_bits_data_1_entries_onlypf_4 (l1_w_req_data.onlypf[4]),
    .io_w_req_bits_data_1_entries_onlypf_5 (l1_w_req_data.onlypf[5]),
    .io_w_req_bits_data_1_entries_onlypf_6 (l1_w_req_data.onlypf[6]),
    .io_w_req_bits_data_1_entries_onlypf_7 (l1_w_req_data.onlypf[7]),
    .io_w_req_bits_data_1_entries_prefetch (l1_w_req_data.prefetch),
    .io_w_req_bits_waymask                 (l1_w_req_waymask),
    .boreChildrenBd_bore_addr              (childBd_addr),
    .boreChildrenBd_bore_addr_rd           (childBd_addr_rd),
    .boreChildrenBd_bore_wdata             (childBd_wdata),
    .boreChildrenBd_bore_wmask             (childBd_wmask),
    .boreChildrenBd_bore_re                (childBd_re),
    .boreChildrenBd_bore_we                (childBd_we),
    .boreChildrenBd_bore_rdata             (childBd_rdata),
    .boreChildrenBd_bore_ack               (childBd_ack),
    .boreChildrenBd_bore_selectedOH        (childBd_selectedOH),
    .boreChildrenBd_bore_array             (childBd_array),
    .boreChildrenBd_bore_1_addr            (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd         (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata           (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask           (childBd_1_wmask),
    .boreChildrenBd_bore_1_re              (childBd_1_re),
    .boreChildrenBd_bore_1_we              (childBd_1_we),
    .boreChildrenBd_bore_1_rdata           (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack             (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH      (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array           (childBd_1_array),
    .boreChildrenBd_bore_2_addr            (childBd_2_addr),
    .boreChildrenBd_bore_2_addr_rd         (childBd_2_addr_rd),
    .boreChildrenBd_bore_2_wdata           (childBd_2_wdata),
    .boreChildrenBd_bore_2_wmask           (childBd_2_wmask),
    .boreChildrenBd_bore_2_re              (childBd_2_re),
    .boreChildrenBd_bore_2_we              (childBd_2_we),
    .boreChildrenBd_bore_2_rdata           (childBd_2_rdata),
    .boreChildrenBd_bore_2_ack             (childBd_2_ack),
    .boreChildrenBd_bore_2_selectedOH      (childBd_2_selectedOH),
    .boreChildrenBd_bore_2_array           (childBd_2_array),
    .boreChildrenBd_bore_3_addr            (childBd_3_addr),
    .boreChildrenBd_bore_3_addr_rd         (childBd_3_addr_rd),
    .boreChildrenBd_bore_3_wdata           (childBd_3_wdata),
    .boreChildrenBd_bore_3_wmask           (childBd_3_wmask),
    .boreChildrenBd_bore_3_re              (childBd_3_re),
    .boreChildrenBd_bore_3_we              (childBd_3_we),
    .boreChildrenBd_bore_3_rdata           (childBd_3_rdata),
    .boreChildrenBd_bore_3_ack             (childBd_3_ack),
    .boreChildrenBd_bore_3_selectedOH      (childBd_3_selectedOH),
    .boreChildrenBd_bore_3_array           (childBd_3_array),
    .sigFromSrams_bore_ram_hold            (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass          (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken        (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk         (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp        (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold        (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold          (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass        (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken      (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk       (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp      (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold      (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen              (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold          (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass        (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken      (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk       (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp      (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold      (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen              (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold          (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass        (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken      (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk       (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp      (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold      (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen              (sigFromSrams_bore_3_cgen)
  );
  MbistPipePtwL1 mbistPlL1 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (bd_array),
    .mbist_all           (bd_all),
    .mbist_req           (bd_req),
    .mbist_ack           (bd_ack),
    .mbist_writeen       (bd_writeen),
    .mbist_be            (bd_be),
    .mbist_addr          (bd_addr),
    .mbist_indata        (bd_indata),
    .mbist_readen        (bd_readen),
    .mbist_addr_rd       (bd_addr_rd),
    .mbist_outdata       (bd_outdata),
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array),
    .toSRAM_1_addr       (childBd_1_addr),
    .toSRAM_1_addr_rd    (childBd_1_addr_rd),
    .toSRAM_1_wdata      (childBd_1_wdata),
    .toSRAM_1_wmask      (childBd_1_wmask),
    .toSRAM_1_re         (childBd_1_re),
    .toSRAM_1_we         (childBd_1_we),
    .toSRAM_1_rdata      (childBd_1_rdata),
    .toSRAM_1_ack        (childBd_1_ack),
    .toSRAM_1_selectedOH (childBd_1_selectedOH),
    .toSRAM_1_array      (childBd_1_array),
    .toSRAM_2_addr       (childBd_2_addr),
    .toSRAM_2_addr_rd    (childBd_2_addr_rd),
    .toSRAM_2_wdata      (childBd_2_wdata),
    .toSRAM_2_wmask      (childBd_2_wmask),
    .toSRAM_2_re         (childBd_2_re),
    .toSRAM_2_we         (childBd_2_we),
    .toSRAM_2_rdata      (childBd_2_rdata),
    .toSRAM_2_ack        (childBd_2_ack),
    .toSRAM_2_selectedOH (childBd_2_selectedOH),
    .toSRAM_2_array      (childBd_2_array),
    .toSRAM_3_addr       (childBd_3_addr),
    .toSRAM_3_addr_rd    (childBd_3_addr_rd),
    .toSRAM_3_wdata      (childBd_3_wdata),
    .toSRAM_3_wmask      (childBd_3_wmask),
    .toSRAM_3_re         (childBd_3_re),
    .toSRAM_3_we         (childBd_3_we),
    .toSRAM_3_rdata      (childBd_3_rdata),
    .toSRAM_3_ack        (childBd_3_ack),
    .toSRAM_3_selectedOH (childBd_3_selectedOH),
    .toSRAM_3_array      (childBd_3_array)
  );
  SplittedSRAM_1 l0 (
    .clock                                  (_ClockGate_Q),
    .reset                                  (reset),
    .io_r_req_valid                         (l0_r_req_valid),
    .io_r_req_bits_setIdx                   (l0_r_req_setIdx),
    .io_r_resp_data_0_entries_tag           (_l0_io_r_resp_data_0_entries_tag),
    .io_r_resp_data_0_entries_asid          (_l0_io_r_resp_data_0_entries_asid),
    .io_r_resp_data_0_entries_vmid          (_l0_io_r_resp_data_0_entries_vmid),
    .io_r_resp_data_0_entries_pbmts_0       (_l0_io_r_resp_data_0_entries_pbmts_0),
    .io_r_resp_data_0_entries_pbmts_1       (_l0_io_r_resp_data_0_entries_pbmts_1),
    .io_r_resp_data_0_entries_pbmts_2       (_l0_io_r_resp_data_0_entries_pbmts_2),
    .io_r_resp_data_0_entries_pbmts_3       (_l0_io_r_resp_data_0_entries_pbmts_3),
    .io_r_resp_data_0_entries_pbmts_4       (_l0_io_r_resp_data_0_entries_pbmts_4),
    .io_r_resp_data_0_entries_pbmts_5       (_l0_io_r_resp_data_0_entries_pbmts_5),
    .io_r_resp_data_0_entries_pbmts_6       (_l0_io_r_resp_data_0_entries_pbmts_6),
    .io_r_resp_data_0_entries_pbmts_7       (_l0_io_r_resp_data_0_entries_pbmts_7),
    .io_r_resp_data_0_entries_ppns_0        (_l0_io_r_resp_data_0_entries_ppns_0),
    .io_r_resp_data_0_entries_ppns_1        (_l0_io_r_resp_data_0_entries_ppns_1),
    .io_r_resp_data_0_entries_ppns_2        (_l0_io_r_resp_data_0_entries_ppns_2),
    .io_r_resp_data_0_entries_ppns_3        (_l0_io_r_resp_data_0_entries_ppns_3),
    .io_r_resp_data_0_entries_ppns_4        (_l0_io_r_resp_data_0_entries_ppns_4),
    .io_r_resp_data_0_entries_ppns_5        (_l0_io_r_resp_data_0_entries_ppns_5),
    .io_r_resp_data_0_entries_ppns_6        (_l0_io_r_resp_data_0_entries_ppns_6),
    .io_r_resp_data_0_entries_ppns_7        (_l0_io_r_resp_data_0_entries_ppns_7),
    .io_r_resp_data_0_entries_vs_0          (_l0_io_r_resp_data_0_entries_vs_0),
    .io_r_resp_data_0_entries_vs_1          (_l0_io_r_resp_data_0_entries_vs_1),
    .io_r_resp_data_0_entries_vs_2          (_l0_io_r_resp_data_0_entries_vs_2),
    .io_r_resp_data_0_entries_vs_3          (_l0_io_r_resp_data_0_entries_vs_3),
    .io_r_resp_data_0_entries_vs_4          (_l0_io_r_resp_data_0_entries_vs_4),
    .io_r_resp_data_0_entries_vs_5          (_l0_io_r_resp_data_0_entries_vs_5),
    .io_r_resp_data_0_entries_vs_6          (_l0_io_r_resp_data_0_entries_vs_6),
    .io_r_resp_data_0_entries_vs_7          (_l0_io_r_resp_data_0_entries_vs_7),
    .io_r_resp_data_0_entries_onlypf_0      (_l0_io_r_resp_data_0_entries_onlypf_0),
    .io_r_resp_data_0_entries_onlypf_1      (_l0_io_r_resp_data_0_entries_onlypf_1),
    .io_r_resp_data_0_entries_onlypf_2      (_l0_io_r_resp_data_0_entries_onlypf_2),
    .io_r_resp_data_0_entries_onlypf_3      (_l0_io_r_resp_data_0_entries_onlypf_3),
    .io_r_resp_data_0_entries_onlypf_4      (_l0_io_r_resp_data_0_entries_onlypf_4),
    .io_r_resp_data_0_entries_onlypf_5      (_l0_io_r_resp_data_0_entries_onlypf_5),
    .io_r_resp_data_0_entries_onlypf_6      (_l0_io_r_resp_data_0_entries_onlypf_6),
    .io_r_resp_data_0_entries_onlypf_7      (_l0_io_r_resp_data_0_entries_onlypf_7),
    .io_r_resp_data_0_entries_perms_0_d     (_l0_io_r_resp_data_0_entries_perms_0_d),
    .io_r_resp_data_0_entries_perms_0_a     (_l0_io_r_resp_data_0_entries_perms_0_a),
    .io_r_resp_data_0_entries_perms_0_g     (_l0_io_r_resp_data_0_entries_perms_0_g),
    .io_r_resp_data_0_entries_perms_0_u     (_l0_io_r_resp_data_0_entries_perms_0_u),
    .io_r_resp_data_0_entries_perms_0_x     (_l0_io_r_resp_data_0_entries_perms_0_x),
    .io_r_resp_data_0_entries_perms_0_w     (_l0_io_r_resp_data_0_entries_perms_0_w),
    .io_r_resp_data_0_entries_perms_0_r     (_l0_io_r_resp_data_0_entries_perms_0_r),
    .io_r_resp_data_0_entries_perms_1_d     (_l0_io_r_resp_data_0_entries_perms_1_d),
    .io_r_resp_data_0_entries_perms_1_a     (_l0_io_r_resp_data_0_entries_perms_1_a),
    .io_r_resp_data_0_entries_perms_1_g     (_l0_io_r_resp_data_0_entries_perms_1_g),
    .io_r_resp_data_0_entries_perms_1_u     (_l0_io_r_resp_data_0_entries_perms_1_u),
    .io_r_resp_data_0_entries_perms_1_x     (_l0_io_r_resp_data_0_entries_perms_1_x),
    .io_r_resp_data_0_entries_perms_1_w     (_l0_io_r_resp_data_0_entries_perms_1_w),
    .io_r_resp_data_0_entries_perms_1_r     (_l0_io_r_resp_data_0_entries_perms_1_r),
    .io_r_resp_data_0_entries_perms_2_d     (_l0_io_r_resp_data_0_entries_perms_2_d),
    .io_r_resp_data_0_entries_perms_2_a     (_l0_io_r_resp_data_0_entries_perms_2_a),
    .io_r_resp_data_0_entries_perms_2_g     (_l0_io_r_resp_data_0_entries_perms_2_g),
    .io_r_resp_data_0_entries_perms_2_u     (_l0_io_r_resp_data_0_entries_perms_2_u),
    .io_r_resp_data_0_entries_perms_2_x     (_l0_io_r_resp_data_0_entries_perms_2_x),
    .io_r_resp_data_0_entries_perms_2_w     (_l0_io_r_resp_data_0_entries_perms_2_w),
    .io_r_resp_data_0_entries_perms_2_r     (_l0_io_r_resp_data_0_entries_perms_2_r),
    .io_r_resp_data_0_entries_perms_3_d     (_l0_io_r_resp_data_0_entries_perms_3_d),
    .io_r_resp_data_0_entries_perms_3_a     (_l0_io_r_resp_data_0_entries_perms_3_a),
    .io_r_resp_data_0_entries_perms_3_g     (_l0_io_r_resp_data_0_entries_perms_3_g),
    .io_r_resp_data_0_entries_perms_3_u     (_l0_io_r_resp_data_0_entries_perms_3_u),
    .io_r_resp_data_0_entries_perms_3_x     (_l0_io_r_resp_data_0_entries_perms_3_x),
    .io_r_resp_data_0_entries_perms_3_w     (_l0_io_r_resp_data_0_entries_perms_3_w),
    .io_r_resp_data_0_entries_perms_3_r     (_l0_io_r_resp_data_0_entries_perms_3_r),
    .io_r_resp_data_0_entries_perms_4_d     (_l0_io_r_resp_data_0_entries_perms_4_d),
    .io_r_resp_data_0_entries_perms_4_a     (_l0_io_r_resp_data_0_entries_perms_4_a),
    .io_r_resp_data_0_entries_perms_4_g     (_l0_io_r_resp_data_0_entries_perms_4_g),
    .io_r_resp_data_0_entries_perms_4_u     (_l0_io_r_resp_data_0_entries_perms_4_u),
    .io_r_resp_data_0_entries_perms_4_x     (_l0_io_r_resp_data_0_entries_perms_4_x),
    .io_r_resp_data_0_entries_perms_4_w     (_l0_io_r_resp_data_0_entries_perms_4_w),
    .io_r_resp_data_0_entries_perms_4_r     (_l0_io_r_resp_data_0_entries_perms_4_r),
    .io_r_resp_data_0_entries_perms_5_d     (_l0_io_r_resp_data_0_entries_perms_5_d),
    .io_r_resp_data_0_entries_perms_5_a     (_l0_io_r_resp_data_0_entries_perms_5_a),
    .io_r_resp_data_0_entries_perms_5_g     (_l0_io_r_resp_data_0_entries_perms_5_g),
    .io_r_resp_data_0_entries_perms_5_u     (_l0_io_r_resp_data_0_entries_perms_5_u),
    .io_r_resp_data_0_entries_perms_5_x     (_l0_io_r_resp_data_0_entries_perms_5_x),
    .io_r_resp_data_0_entries_perms_5_w     (_l0_io_r_resp_data_0_entries_perms_5_w),
    .io_r_resp_data_0_entries_perms_5_r     (_l0_io_r_resp_data_0_entries_perms_5_r),
    .io_r_resp_data_0_entries_perms_6_d     (_l0_io_r_resp_data_0_entries_perms_6_d),
    .io_r_resp_data_0_entries_perms_6_a     (_l0_io_r_resp_data_0_entries_perms_6_a),
    .io_r_resp_data_0_entries_perms_6_g     (_l0_io_r_resp_data_0_entries_perms_6_g),
    .io_r_resp_data_0_entries_perms_6_u     (_l0_io_r_resp_data_0_entries_perms_6_u),
    .io_r_resp_data_0_entries_perms_6_x     (_l0_io_r_resp_data_0_entries_perms_6_x),
    .io_r_resp_data_0_entries_perms_6_w     (_l0_io_r_resp_data_0_entries_perms_6_w),
    .io_r_resp_data_0_entries_perms_6_r     (_l0_io_r_resp_data_0_entries_perms_6_r),
    .io_r_resp_data_0_entries_perms_7_d     (_l0_io_r_resp_data_0_entries_perms_7_d),
    .io_r_resp_data_0_entries_perms_7_a     (_l0_io_r_resp_data_0_entries_perms_7_a),
    .io_r_resp_data_0_entries_perms_7_g     (_l0_io_r_resp_data_0_entries_perms_7_g),
    .io_r_resp_data_0_entries_perms_7_u     (_l0_io_r_resp_data_0_entries_perms_7_u),
    .io_r_resp_data_0_entries_perms_7_x     (_l0_io_r_resp_data_0_entries_perms_7_x),
    .io_r_resp_data_0_entries_perms_7_w     (_l0_io_r_resp_data_0_entries_perms_7_w),
    .io_r_resp_data_0_entries_perms_7_r     (_l0_io_r_resp_data_0_entries_perms_7_r),
    .io_r_resp_data_0_entries_prefetch      (_l0_io_r_resp_data_0_entries_prefetch),
    .io_r_resp_data_1_entries_tag           (_l0_io_r_resp_data_1_entries_tag),
    .io_r_resp_data_1_entries_asid          (_l0_io_r_resp_data_1_entries_asid),
    .io_r_resp_data_1_entries_vmid          (_l0_io_r_resp_data_1_entries_vmid),
    .io_r_resp_data_1_entries_pbmts_0       (_l0_io_r_resp_data_1_entries_pbmts_0),
    .io_r_resp_data_1_entries_pbmts_1       (_l0_io_r_resp_data_1_entries_pbmts_1),
    .io_r_resp_data_1_entries_pbmts_2       (_l0_io_r_resp_data_1_entries_pbmts_2),
    .io_r_resp_data_1_entries_pbmts_3       (_l0_io_r_resp_data_1_entries_pbmts_3),
    .io_r_resp_data_1_entries_pbmts_4       (_l0_io_r_resp_data_1_entries_pbmts_4),
    .io_r_resp_data_1_entries_pbmts_5       (_l0_io_r_resp_data_1_entries_pbmts_5),
    .io_r_resp_data_1_entries_pbmts_6       (_l0_io_r_resp_data_1_entries_pbmts_6),
    .io_r_resp_data_1_entries_pbmts_7       (_l0_io_r_resp_data_1_entries_pbmts_7),
    .io_r_resp_data_1_entries_ppns_0        (_l0_io_r_resp_data_1_entries_ppns_0),
    .io_r_resp_data_1_entries_ppns_1        (_l0_io_r_resp_data_1_entries_ppns_1),
    .io_r_resp_data_1_entries_ppns_2        (_l0_io_r_resp_data_1_entries_ppns_2),
    .io_r_resp_data_1_entries_ppns_3        (_l0_io_r_resp_data_1_entries_ppns_3),
    .io_r_resp_data_1_entries_ppns_4        (_l0_io_r_resp_data_1_entries_ppns_4),
    .io_r_resp_data_1_entries_ppns_5        (_l0_io_r_resp_data_1_entries_ppns_5),
    .io_r_resp_data_1_entries_ppns_6        (_l0_io_r_resp_data_1_entries_ppns_6),
    .io_r_resp_data_1_entries_ppns_7        (_l0_io_r_resp_data_1_entries_ppns_7),
    .io_r_resp_data_1_entries_vs_0          (_l0_io_r_resp_data_1_entries_vs_0),
    .io_r_resp_data_1_entries_vs_1          (_l0_io_r_resp_data_1_entries_vs_1),
    .io_r_resp_data_1_entries_vs_2          (_l0_io_r_resp_data_1_entries_vs_2),
    .io_r_resp_data_1_entries_vs_3          (_l0_io_r_resp_data_1_entries_vs_3),
    .io_r_resp_data_1_entries_vs_4          (_l0_io_r_resp_data_1_entries_vs_4),
    .io_r_resp_data_1_entries_vs_5          (_l0_io_r_resp_data_1_entries_vs_5),
    .io_r_resp_data_1_entries_vs_6          (_l0_io_r_resp_data_1_entries_vs_6),
    .io_r_resp_data_1_entries_vs_7          (_l0_io_r_resp_data_1_entries_vs_7),
    .io_r_resp_data_1_entries_onlypf_0      (_l0_io_r_resp_data_1_entries_onlypf_0),
    .io_r_resp_data_1_entries_onlypf_1      (_l0_io_r_resp_data_1_entries_onlypf_1),
    .io_r_resp_data_1_entries_onlypf_2      (_l0_io_r_resp_data_1_entries_onlypf_2),
    .io_r_resp_data_1_entries_onlypf_3      (_l0_io_r_resp_data_1_entries_onlypf_3),
    .io_r_resp_data_1_entries_onlypf_4      (_l0_io_r_resp_data_1_entries_onlypf_4),
    .io_r_resp_data_1_entries_onlypf_5      (_l0_io_r_resp_data_1_entries_onlypf_5),
    .io_r_resp_data_1_entries_onlypf_6      (_l0_io_r_resp_data_1_entries_onlypf_6),
    .io_r_resp_data_1_entries_onlypf_7      (_l0_io_r_resp_data_1_entries_onlypf_7),
    .io_r_resp_data_1_entries_perms_0_d     (_l0_io_r_resp_data_1_entries_perms_0_d),
    .io_r_resp_data_1_entries_perms_0_a     (_l0_io_r_resp_data_1_entries_perms_0_a),
    .io_r_resp_data_1_entries_perms_0_g     (_l0_io_r_resp_data_1_entries_perms_0_g),
    .io_r_resp_data_1_entries_perms_0_u     (_l0_io_r_resp_data_1_entries_perms_0_u),
    .io_r_resp_data_1_entries_perms_0_x     (_l0_io_r_resp_data_1_entries_perms_0_x),
    .io_r_resp_data_1_entries_perms_0_w     (_l0_io_r_resp_data_1_entries_perms_0_w),
    .io_r_resp_data_1_entries_perms_0_r     (_l0_io_r_resp_data_1_entries_perms_0_r),
    .io_r_resp_data_1_entries_perms_1_d     (_l0_io_r_resp_data_1_entries_perms_1_d),
    .io_r_resp_data_1_entries_perms_1_a     (_l0_io_r_resp_data_1_entries_perms_1_a),
    .io_r_resp_data_1_entries_perms_1_g     (_l0_io_r_resp_data_1_entries_perms_1_g),
    .io_r_resp_data_1_entries_perms_1_u     (_l0_io_r_resp_data_1_entries_perms_1_u),
    .io_r_resp_data_1_entries_perms_1_x     (_l0_io_r_resp_data_1_entries_perms_1_x),
    .io_r_resp_data_1_entries_perms_1_w     (_l0_io_r_resp_data_1_entries_perms_1_w),
    .io_r_resp_data_1_entries_perms_1_r     (_l0_io_r_resp_data_1_entries_perms_1_r),
    .io_r_resp_data_1_entries_perms_2_d     (_l0_io_r_resp_data_1_entries_perms_2_d),
    .io_r_resp_data_1_entries_perms_2_a     (_l0_io_r_resp_data_1_entries_perms_2_a),
    .io_r_resp_data_1_entries_perms_2_g     (_l0_io_r_resp_data_1_entries_perms_2_g),
    .io_r_resp_data_1_entries_perms_2_u     (_l0_io_r_resp_data_1_entries_perms_2_u),
    .io_r_resp_data_1_entries_perms_2_x     (_l0_io_r_resp_data_1_entries_perms_2_x),
    .io_r_resp_data_1_entries_perms_2_w     (_l0_io_r_resp_data_1_entries_perms_2_w),
    .io_r_resp_data_1_entries_perms_2_r     (_l0_io_r_resp_data_1_entries_perms_2_r),
    .io_r_resp_data_1_entries_perms_3_d     (_l0_io_r_resp_data_1_entries_perms_3_d),
    .io_r_resp_data_1_entries_perms_3_a     (_l0_io_r_resp_data_1_entries_perms_3_a),
    .io_r_resp_data_1_entries_perms_3_g     (_l0_io_r_resp_data_1_entries_perms_3_g),
    .io_r_resp_data_1_entries_perms_3_u     (_l0_io_r_resp_data_1_entries_perms_3_u),
    .io_r_resp_data_1_entries_perms_3_x     (_l0_io_r_resp_data_1_entries_perms_3_x),
    .io_r_resp_data_1_entries_perms_3_w     (_l0_io_r_resp_data_1_entries_perms_3_w),
    .io_r_resp_data_1_entries_perms_3_r     (_l0_io_r_resp_data_1_entries_perms_3_r),
    .io_r_resp_data_1_entries_perms_4_d     (_l0_io_r_resp_data_1_entries_perms_4_d),
    .io_r_resp_data_1_entries_perms_4_a     (_l0_io_r_resp_data_1_entries_perms_4_a),
    .io_r_resp_data_1_entries_perms_4_g     (_l0_io_r_resp_data_1_entries_perms_4_g),
    .io_r_resp_data_1_entries_perms_4_u     (_l0_io_r_resp_data_1_entries_perms_4_u),
    .io_r_resp_data_1_entries_perms_4_x     (_l0_io_r_resp_data_1_entries_perms_4_x),
    .io_r_resp_data_1_entries_perms_4_w     (_l0_io_r_resp_data_1_entries_perms_4_w),
    .io_r_resp_data_1_entries_perms_4_r     (_l0_io_r_resp_data_1_entries_perms_4_r),
    .io_r_resp_data_1_entries_perms_5_d     (_l0_io_r_resp_data_1_entries_perms_5_d),
    .io_r_resp_data_1_entries_perms_5_a     (_l0_io_r_resp_data_1_entries_perms_5_a),
    .io_r_resp_data_1_entries_perms_5_g     (_l0_io_r_resp_data_1_entries_perms_5_g),
    .io_r_resp_data_1_entries_perms_5_u     (_l0_io_r_resp_data_1_entries_perms_5_u),
    .io_r_resp_data_1_entries_perms_5_x     (_l0_io_r_resp_data_1_entries_perms_5_x),
    .io_r_resp_data_1_entries_perms_5_w     (_l0_io_r_resp_data_1_entries_perms_5_w),
    .io_r_resp_data_1_entries_perms_5_r     (_l0_io_r_resp_data_1_entries_perms_5_r),
    .io_r_resp_data_1_entries_perms_6_d     (_l0_io_r_resp_data_1_entries_perms_6_d),
    .io_r_resp_data_1_entries_perms_6_a     (_l0_io_r_resp_data_1_entries_perms_6_a),
    .io_r_resp_data_1_entries_perms_6_g     (_l0_io_r_resp_data_1_entries_perms_6_g),
    .io_r_resp_data_1_entries_perms_6_u     (_l0_io_r_resp_data_1_entries_perms_6_u),
    .io_r_resp_data_1_entries_perms_6_x     (_l0_io_r_resp_data_1_entries_perms_6_x),
    .io_r_resp_data_1_entries_perms_6_w     (_l0_io_r_resp_data_1_entries_perms_6_w),
    .io_r_resp_data_1_entries_perms_6_r     (_l0_io_r_resp_data_1_entries_perms_6_r),
    .io_r_resp_data_1_entries_perms_7_d     (_l0_io_r_resp_data_1_entries_perms_7_d),
    .io_r_resp_data_1_entries_perms_7_a     (_l0_io_r_resp_data_1_entries_perms_7_a),
    .io_r_resp_data_1_entries_perms_7_g     (_l0_io_r_resp_data_1_entries_perms_7_g),
    .io_r_resp_data_1_entries_perms_7_u     (_l0_io_r_resp_data_1_entries_perms_7_u),
    .io_r_resp_data_1_entries_perms_7_x     (_l0_io_r_resp_data_1_entries_perms_7_x),
    .io_r_resp_data_1_entries_perms_7_w     (_l0_io_r_resp_data_1_entries_perms_7_w),
    .io_r_resp_data_1_entries_perms_7_r     (_l0_io_r_resp_data_1_entries_perms_7_r),
    .io_r_resp_data_1_entries_prefetch      (_l0_io_r_resp_data_1_entries_prefetch),
    .io_r_resp_data_2_entries_tag           (_l0_io_r_resp_data_2_entries_tag),
    .io_r_resp_data_2_entries_asid          (_l0_io_r_resp_data_2_entries_asid),
    .io_r_resp_data_2_entries_vmid          (_l0_io_r_resp_data_2_entries_vmid),
    .io_r_resp_data_2_entries_pbmts_0       (_l0_io_r_resp_data_2_entries_pbmts_0),
    .io_r_resp_data_2_entries_pbmts_1       (_l0_io_r_resp_data_2_entries_pbmts_1),
    .io_r_resp_data_2_entries_pbmts_2       (_l0_io_r_resp_data_2_entries_pbmts_2),
    .io_r_resp_data_2_entries_pbmts_3       (_l0_io_r_resp_data_2_entries_pbmts_3),
    .io_r_resp_data_2_entries_pbmts_4       (_l0_io_r_resp_data_2_entries_pbmts_4),
    .io_r_resp_data_2_entries_pbmts_5       (_l0_io_r_resp_data_2_entries_pbmts_5),
    .io_r_resp_data_2_entries_pbmts_6       (_l0_io_r_resp_data_2_entries_pbmts_6),
    .io_r_resp_data_2_entries_pbmts_7       (_l0_io_r_resp_data_2_entries_pbmts_7),
    .io_r_resp_data_2_entries_ppns_0        (_l0_io_r_resp_data_2_entries_ppns_0),
    .io_r_resp_data_2_entries_ppns_1        (_l0_io_r_resp_data_2_entries_ppns_1),
    .io_r_resp_data_2_entries_ppns_2        (_l0_io_r_resp_data_2_entries_ppns_2),
    .io_r_resp_data_2_entries_ppns_3        (_l0_io_r_resp_data_2_entries_ppns_3),
    .io_r_resp_data_2_entries_ppns_4        (_l0_io_r_resp_data_2_entries_ppns_4),
    .io_r_resp_data_2_entries_ppns_5        (_l0_io_r_resp_data_2_entries_ppns_5),
    .io_r_resp_data_2_entries_ppns_6        (_l0_io_r_resp_data_2_entries_ppns_6),
    .io_r_resp_data_2_entries_ppns_7        (_l0_io_r_resp_data_2_entries_ppns_7),
    .io_r_resp_data_2_entries_vs_0          (_l0_io_r_resp_data_2_entries_vs_0),
    .io_r_resp_data_2_entries_vs_1          (_l0_io_r_resp_data_2_entries_vs_1),
    .io_r_resp_data_2_entries_vs_2          (_l0_io_r_resp_data_2_entries_vs_2),
    .io_r_resp_data_2_entries_vs_3          (_l0_io_r_resp_data_2_entries_vs_3),
    .io_r_resp_data_2_entries_vs_4          (_l0_io_r_resp_data_2_entries_vs_4),
    .io_r_resp_data_2_entries_vs_5          (_l0_io_r_resp_data_2_entries_vs_5),
    .io_r_resp_data_2_entries_vs_6          (_l0_io_r_resp_data_2_entries_vs_6),
    .io_r_resp_data_2_entries_vs_7          (_l0_io_r_resp_data_2_entries_vs_7),
    .io_r_resp_data_2_entries_onlypf_0      (_l0_io_r_resp_data_2_entries_onlypf_0),
    .io_r_resp_data_2_entries_onlypf_1      (_l0_io_r_resp_data_2_entries_onlypf_1),
    .io_r_resp_data_2_entries_onlypf_2      (_l0_io_r_resp_data_2_entries_onlypf_2),
    .io_r_resp_data_2_entries_onlypf_3      (_l0_io_r_resp_data_2_entries_onlypf_3),
    .io_r_resp_data_2_entries_onlypf_4      (_l0_io_r_resp_data_2_entries_onlypf_4),
    .io_r_resp_data_2_entries_onlypf_5      (_l0_io_r_resp_data_2_entries_onlypf_5),
    .io_r_resp_data_2_entries_onlypf_6      (_l0_io_r_resp_data_2_entries_onlypf_6),
    .io_r_resp_data_2_entries_onlypf_7      (_l0_io_r_resp_data_2_entries_onlypf_7),
    .io_r_resp_data_2_entries_perms_0_d     (_l0_io_r_resp_data_2_entries_perms_0_d),
    .io_r_resp_data_2_entries_perms_0_a     (_l0_io_r_resp_data_2_entries_perms_0_a),
    .io_r_resp_data_2_entries_perms_0_g     (_l0_io_r_resp_data_2_entries_perms_0_g),
    .io_r_resp_data_2_entries_perms_0_u     (_l0_io_r_resp_data_2_entries_perms_0_u),
    .io_r_resp_data_2_entries_perms_0_x     (_l0_io_r_resp_data_2_entries_perms_0_x),
    .io_r_resp_data_2_entries_perms_0_w     (_l0_io_r_resp_data_2_entries_perms_0_w),
    .io_r_resp_data_2_entries_perms_0_r     (_l0_io_r_resp_data_2_entries_perms_0_r),
    .io_r_resp_data_2_entries_perms_1_d     (_l0_io_r_resp_data_2_entries_perms_1_d),
    .io_r_resp_data_2_entries_perms_1_a     (_l0_io_r_resp_data_2_entries_perms_1_a),
    .io_r_resp_data_2_entries_perms_1_g     (_l0_io_r_resp_data_2_entries_perms_1_g),
    .io_r_resp_data_2_entries_perms_1_u     (_l0_io_r_resp_data_2_entries_perms_1_u),
    .io_r_resp_data_2_entries_perms_1_x     (_l0_io_r_resp_data_2_entries_perms_1_x),
    .io_r_resp_data_2_entries_perms_1_w     (_l0_io_r_resp_data_2_entries_perms_1_w),
    .io_r_resp_data_2_entries_perms_1_r     (_l0_io_r_resp_data_2_entries_perms_1_r),
    .io_r_resp_data_2_entries_perms_2_d     (_l0_io_r_resp_data_2_entries_perms_2_d),
    .io_r_resp_data_2_entries_perms_2_a     (_l0_io_r_resp_data_2_entries_perms_2_a),
    .io_r_resp_data_2_entries_perms_2_g     (_l0_io_r_resp_data_2_entries_perms_2_g),
    .io_r_resp_data_2_entries_perms_2_u     (_l0_io_r_resp_data_2_entries_perms_2_u),
    .io_r_resp_data_2_entries_perms_2_x     (_l0_io_r_resp_data_2_entries_perms_2_x),
    .io_r_resp_data_2_entries_perms_2_w     (_l0_io_r_resp_data_2_entries_perms_2_w),
    .io_r_resp_data_2_entries_perms_2_r     (_l0_io_r_resp_data_2_entries_perms_2_r),
    .io_r_resp_data_2_entries_perms_3_d     (_l0_io_r_resp_data_2_entries_perms_3_d),
    .io_r_resp_data_2_entries_perms_3_a     (_l0_io_r_resp_data_2_entries_perms_3_a),
    .io_r_resp_data_2_entries_perms_3_g     (_l0_io_r_resp_data_2_entries_perms_3_g),
    .io_r_resp_data_2_entries_perms_3_u     (_l0_io_r_resp_data_2_entries_perms_3_u),
    .io_r_resp_data_2_entries_perms_3_x     (_l0_io_r_resp_data_2_entries_perms_3_x),
    .io_r_resp_data_2_entries_perms_3_w     (_l0_io_r_resp_data_2_entries_perms_3_w),
    .io_r_resp_data_2_entries_perms_3_r     (_l0_io_r_resp_data_2_entries_perms_3_r),
    .io_r_resp_data_2_entries_perms_4_d     (_l0_io_r_resp_data_2_entries_perms_4_d),
    .io_r_resp_data_2_entries_perms_4_a     (_l0_io_r_resp_data_2_entries_perms_4_a),
    .io_r_resp_data_2_entries_perms_4_g     (_l0_io_r_resp_data_2_entries_perms_4_g),
    .io_r_resp_data_2_entries_perms_4_u     (_l0_io_r_resp_data_2_entries_perms_4_u),
    .io_r_resp_data_2_entries_perms_4_x     (_l0_io_r_resp_data_2_entries_perms_4_x),
    .io_r_resp_data_2_entries_perms_4_w     (_l0_io_r_resp_data_2_entries_perms_4_w),
    .io_r_resp_data_2_entries_perms_4_r     (_l0_io_r_resp_data_2_entries_perms_4_r),
    .io_r_resp_data_2_entries_perms_5_d     (_l0_io_r_resp_data_2_entries_perms_5_d),
    .io_r_resp_data_2_entries_perms_5_a     (_l0_io_r_resp_data_2_entries_perms_5_a),
    .io_r_resp_data_2_entries_perms_5_g     (_l0_io_r_resp_data_2_entries_perms_5_g),
    .io_r_resp_data_2_entries_perms_5_u     (_l0_io_r_resp_data_2_entries_perms_5_u),
    .io_r_resp_data_2_entries_perms_5_x     (_l0_io_r_resp_data_2_entries_perms_5_x),
    .io_r_resp_data_2_entries_perms_5_w     (_l0_io_r_resp_data_2_entries_perms_5_w),
    .io_r_resp_data_2_entries_perms_5_r     (_l0_io_r_resp_data_2_entries_perms_5_r),
    .io_r_resp_data_2_entries_perms_6_d     (_l0_io_r_resp_data_2_entries_perms_6_d),
    .io_r_resp_data_2_entries_perms_6_a     (_l0_io_r_resp_data_2_entries_perms_6_a),
    .io_r_resp_data_2_entries_perms_6_g     (_l0_io_r_resp_data_2_entries_perms_6_g),
    .io_r_resp_data_2_entries_perms_6_u     (_l0_io_r_resp_data_2_entries_perms_6_u),
    .io_r_resp_data_2_entries_perms_6_x     (_l0_io_r_resp_data_2_entries_perms_6_x),
    .io_r_resp_data_2_entries_perms_6_w     (_l0_io_r_resp_data_2_entries_perms_6_w),
    .io_r_resp_data_2_entries_perms_6_r     (_l0_io_r_resp_data_2_entries_perms_6_r),
    .io_r_resp_data_2_entries_perms_7_d     (_l0_io_r_resp_data_2_entries_perms_7_d),
    .io_r_resp_data_2_entries_perms_7_a     (_l0_io_r_resp_data_2_entries_perms_7_a),
    .io_r_resp_data_2_entries_perms_7_g     (_l0_io_r_resp_data_2_entries_perms_7_g),
    .io_r_resp_data_2_entries_perms_7_u     (_l0_io_r_resp_data_2_entries_perms_7_u),
    .io_r_resp_data_2_entries_perms_7_x     (_l0_io_r_resp_data_2_entries_perms_7_x),
    .io_r_resp_data_2_entries_perms_7_w     (_l0_io_r_resp_data_2_entries_perms_7_w),
    .io_r_resp_data_2_entries_perms_7_r     (_l0_io_r_resp_data_2_entries_perms_7_r),
    .io_r_resp_data_2_entries_prefetch      (_l0_io_r_resp_data_2_entries_prefetch),
    .io_r_resp_data_3_entries_tag           (_l0_io_r_resp_data_3_entries_tag),
    .io_r_resp_data_3_entries_asid          (_l0_io_r_resp_data_3_entries_asid),
    .io_r_resp_data_3_entries_vmid          (_l0_io_r_resp_data_3_entries_vmid),
    .io_r_resp_data_3_entries_pbmts_0       (_l0_io_r_resp_data_3_entries_pbmts_0),
    .io_r_resp_data_3_entries_pbmts_1       (_l0_io_r_resp_data_3_entries_pbmts_1),
    .io_r_resp_data_3_entries_pbmts_2       (_l0_io_r_resp_data_3_entries_pbmts_2),
    .io_r_resp_data_3_entries_pbmts_3       (_l0_io_r_resp_data_3_entries_pbmts_3),
    .io_r_resp_data_3_entries_pbmts_4       (_l0_io_r_resp_data_3_entries_pbmts_4),
    .io_r_resp_data_3_entries_pbmts_5       (_l0_io_r_resp_data_3_entries_pbmts_5),
    .io_r_resp_data_3_entries_pbmts_6       (_l0_io_r_resp_data_3_entries_pbmts_6),
    .io_r_resp_data_3_entries_pbmts_7       (_l0_io_r_resp_data_3_entries_pbmts_7),
    .io_r_resp_data_3_entries_ppns_0        (_l0_io_r_resp_data_3_entries_ppns_0),
    .io_r_resp_data_3_entries_ppns_1        (_l0_io_r_resp_data_3_entries_ppns_1),
    .io_r_resp_data_3_entries_ppns_2        (_l0_io_r_resp_data_3_entries_ppns_2),
    .io_r_resp_data_3_entries_ppns_3        (_l0_io_r_resp_data_3_entries_ppns_3),
    .io_r_resp_data_3_entries_ppns_4        (_l0_io_r_resp_data_3_entries_ppns_4),
    .io_r_resp_data_3_entries_ppns_5        (_l0_io_r_resp_data_3_entries_ppns_5),
    .io_r_resp_data_3_entries_ppns_6        (_l0_io_r_resp_data_3_entries_ppns_6),
    .io_r_resp_data_3_entries_ppns_7        (_l0_io_r_resp_data_3_entries_ppns_7),
    .io_r_resp_data_3_entries_vs_0          (_l0_io_r_resp_data_3_entries_vs_0),
    .io_r_resp_data_3_entries_vs_1          (_l0_io_r_resp_data_3_entries_vs_1),
    .io_r_resp_data_3_entries_vs_2          (_l0_io_r_resp_data_3_entries_vs_2),
    .io_r_resp_data_3_entries_vs_3          (_l0_io_r_resp_data_3_entries_vs_3),
    .io_r_resp_data_3_entries_vs_4          (_l0_io_r_resp_data_3_entries_vs_4),
    .io_r_resp_data_3_entries_vs_5          (_l0_io_r_resp_data_3_entries_vs_5),
    .io_r_resp_data_3_entries_vs_6          (_l0_io_r_resp_data_3_entries_vs_6),
    .io_r_resp_data_3_entries_vs_7          (_l0_io_r_resp_data_3_entries_vs_7),
    .io_r_resp_data_3_entries_onlypf_0      (_l0_io_r_resp_data_3_entries_onlypf_0),
    .io_r_resp_data_3_entries_onlypf_1      (_l0_io_r_resp_data_3_entries_onlypf_1),
    .io_r_resp_data_3_entries_onlypf_2      (_l0_io_r_resp_data_3_entries_onlypf_2),
    .io_r_resp_data_3_entries_onlypf_3      (_l0_io_r_resp_data_3_entries_onlypf_3),
    .io_r_resp_data_3_entries_onlypf_4      (_l0_io_r_resp_data_3_entries_onlypf_4),
    .io_r_resp_data_3_entries_onlypf_5      (_l0_io_r_resp_data_3_entries_onlypf_5),
    .io_r_resp_data_3_entries_onlypf_6      (_l0_io_r_resp_data_3_entries_onlypf_6),
    .io_r_resp_data_3_entries_onlypf_7      (_l0_io_r_resp_data_3_entries_onlypf_7),
    .io_r_resp_data_3_entries_perms_0_d     (_l0_io_r_resp_data_3_entries_perms_0_d),
    .io_r_resp_data_3_entries_perms_0_a     (_l0_io_r_resp_data_3_entries_perms_0_a),
    .io_r_resp_data_3_entries_perms_0_g     (_l0_io_r_resp_data_3_entries_perms_0_g),
    .io_r_resp_data_3_entries_perms_0_u     (_l0_io_r_resp_data_3_entries_perms_0_u),
    .io_r_resp_data_3_entries_perms_0_x     (_l0_io_r_resp_data_3_entries_perms_0_x),
    .io_r_resp_data_3_entries_perms_0_w     (_l0_io_r_resp_data_3_entries_perms_0_w),
    .io_r_resp_data_3_entries_perms_0_r     (_l0_io_r_resp_data_3_entries_perms_0_r),
    .io_r_resp_data_3_entries_perms_1_d     (_l0_io_r_resp_data_3_entries_perms_1_d),
    .io_r_resp_data_3_entries_perms_1_a     (_l0_io_r_resp_data_3_entries_perms_1_a),
    .io_r_resp_data_3_entries_perms_1_g     (_l0_io_r_resp_data_3_entries_perms_1_g),
    .io_r_resp_data_3_entries_perms_1_u     (_l0_io_r_resp_data_3_entries_perms_1_u),
    .io_r_resp_data_3_entries_perms_1_x     (_l0_io_r_resp_data_3_entries_perms_1_x),
    .io_r_resp_data_3_entries_perms_1_w     (_l0_io_r_resp_data_3_entries_perms_1_w),
    .io_r_resp_data_3_entries_perms_1_r     (_l0_io_r_resp_data_3_entries_perms_1_r),
    .io_r_resp_data_3_entries_perms_2_d     (_l0_io_r_resp_data_3_entries_perms_2_d),
    .io_r_resp_data_3_entries_perms_2_a     (_l0_io_r_resp_data_3_entries_perms_2_a),
    .io_r_resp_data_3_entries_perms_2_g     (_l0_io_r_resp_data_3_entries_perms_2_g),
    .io_r_resp_data_3_entries_perms_2_u     (_l0_io_r_resp_data_3_entries_perms_2_u),
    .io_r_resp_data_3_entries_perms_2_x     (_l0_io_r_resp_data_3_entries_perms_2_x),
    .io_r_resp_data_3_entries_perms_2_w     (_l0_io_r_resp_data_3_entries_perms_2_w),
    .io_r_resp_data_3_entries_perms_2_r     (_l0_io_r_resp_data_3_entries_perms_2_r),
    .io_r_resp_data_3_entries_perms_3_d     (_l0_io_r_resp_data_3_entries_perms_3_d),
    .io_r_resp_data_3_entries_perms_3_a     (_l0_io_r_resp_data_3_entries_perms_3_a),
    .io_r_resp_data_3_entries_perms_3_g     (_l0_io_r_resp_data_3_entries_perms_3_g),
    .io_r_resp_data_3_entries_perms_3_u     (_l0_io_r_resp_data_3_entries_perms_3_u),
    .io_r_resp_data_3_entries_perms_3_x     (_l0_io_r_resp_data_3_entries_perms_3_x),
    .io_r_resp_data_3_entries_perms_3_w     (_l0_io_r_resp_data_3_entries_perms_3_w),
    .io_r_resp_data_3_entries_perms_3_r     (_l0_io_r_resp_data_3_entries_perms_3_r),
    .io_r_resp_data_3_entries_perms_4_d     (_l0_io_r_resp_data_3_entries_perms_4_d),
    .io_r_resp_data_3_entries_perms_4_a     (_l0_io_r_resp_data_3_entries_perms_4_a),
    .io_r_resp_data_3_entries_perms_4_g     (_l0_io_r_resp_data_3_entries_perms_4_g),
    .io_r_resp_data_3_entries_perms_4_u     (_l0_io_r_resp_data_3_entries_perms_4_u),
    .io_r_resp_data_3_entries_perms_4_x     (_l0_io_r_resp_data_3_entries_perms_4_x),
    .io_r_resp_data_3_entries_perms_4_w     (_l0_io_r_resp_data_3_entries_perms_4_w),
    .io_r_resp_data_3_entries_perms_4_r     (_l0_io_r_resp_data_3_entries_perms_4_r),
    .io_r_resp_data_3_entries_perms_5_d     (_l0_io_r_resp_data_3_entries_perms_5_d),
    .io_r_resp_data_3_entries_perms_5_a     (_l0_io_r_resp_data_3_entries_perms_5_a),
    .io_r_resp_data_3_entries_perms_5_g     (_l0_io_r_resp_data_3_entries_perms_5_g),
    .io_r_resp_data_3_entries_perms_5_u     (_l0_io_r_resp_data_3_entries_perms_5_u),
    .io_r_resp_data_3_entries_perms_5_x     (_l0_io_r_resp_data_3_entries_perms_5_x),
    .io_r_resp_data_3_entries_perms_5_w     (_l0_io_r_resp_data_3_entries_perms_5_w),
    .io_r_resp_data_3_entries_perms_5_r     (_l0_io_r_resp_data_3_entries_perms_5_r),
    .io_r_resp_data_3_entries_perms_6_d     (_l0_io_r_resp_data_3_entries_perms_6_d),
    .io_r_resp_data_3_entries_perms_6_a     (_l0_io_r_resp_data_3_entries_perms_6_a),
    .io_r_resp_data_3_entries_perms_6_g     (_l0_io_r_resp_data_3_entries_perms_6_g),
    .io_r_resp_data_3_entries_perms_6_u     (_l0_io_r_resp_data_3_entries_perms_6_u),
    .io_r_resp_data_3_entries_perms_6_x     (_l0_io_r_resp_data_3_entries_perms_6_x),
    .io_r_resp_data_3_entries_perms_6_w     (_l0_io_r_resp_data_3_entries_perms_6_w),
    .io_r_resp_data_3_entries_perms_6_r     (_l0_io_r_resp_data_3_entries_perms_6_r),
    .io_r_resp_data_3_entries_perms_7_d     (_l0_io_r_resp_data_3_entries_perms_7_d),
    .io_r_resp_data_3_entries_perms_7_a     (_l0_io_r_resp_data_3_entries_perms_7_a),
    .io_r_resp_data_3_entries_perms_7_g     (_l0_io_r_resp_data_3_entries_perms_7_g),
    .io_r_resp_data_3_entries_perms_7_u     (_l0_io_r_resp_data_3_entries_perms_7_u),
    .io_r_resp_data_3_entries_perms_7_x     (_l0_io_r_resp_data_3_entries_perms_7_x),
    .io_r_resp_data_3_entries_perms_7_w     (_l0_io_r_resp_data_3_entries_perms_7_w),
    .io_r_resp_data_3_entries_perms_7_r     (_l0_io_r_resp_data_3_entries_perms_7_r),
    .io_r_resp_data_3_entries_prefetch      (_l0_io_r_resp_data_3_entries_prefetch),
    .io_w_req_valid                         (l0_w_req_valid),
    .io_w_req_bits_setIdx                   (l0_w_req_setIdx),
    .io_w_req_bits_data_0_entries_tag       (l0_w_req_data.tag),
    .io_w_req_bits_data_0_entries_asid      (l0_w_req_data.asid),
    .io_w_req_bits_data_0_entries_vmid      (l0_w_req_data.vmid),
    .io_w_req_bits_data_0_entries_pbmts_0   (l0_w_req_data.pbmts[0]),
    .io_w_req_bits_data_0_entries_pbmts_1   (l0_w_req_data.pbmts[1]),
    .io_w_req_bits_data_0_entries_pbmts_2   (l0_w_req_data.pbmts[2]),
    .io_w_req_bits_data_0_entries_pbmts_3   (l0_w_req_data.pbmts[3]),
    .io_w_req_bits_data_0_entries_pbmts_4   (l0_w_req_data.pbmts[4]),
    .io_w_req_bits_data_0_entries_pbmts_5   (l0_w_req_data.pbmts[5]),
    .io_w_req_bits_data_0_entries_pbmts_6   (l0_w_req_data.pbmts[6]),
    .io_w_req_bits_data_0_entries_pbmts_7   (l0_w_req_data.pbmts[7]),
    .io_w_req_bits_data_0_entries_ppns_0    (l0_w_req_data.ppns[0]),
    .io_w_req_bits_data_0_entries_ppns_1    (l0_w_req_data.ppns[1]),
    .io_w_req_bits_data_0_entries_ppns_2    (l0_w_req_data.ppns[2]),
    .io_w_req_bits_data_0_entries_ppns_3    (l0_w_req_data.ppns[3]),
    .io_w_req_bits_data_0_entries_ppns_4    (l0_w_req_data.ppns[4]),
    .io_w_req_bits_data_0_entries_ppns_5    (l0_w_req_data.ppns[5]),
    .io_w_req_bits_data_0_entries_ppns_6    (l0_w_req_data.ppns[6]),
    .io_w_req_bits_data_0_entries_ppns_7    (l0_w_req_data.ppns[7]),
    .io_w_req_bits_data_0_entries_vs_0      (l0_w_req_data.vs[0]),
    .io_w_req_bits_data_0_entries_vs_1      (l0_w_req_data.vs[1]),
    .io_w_req_bits_data_0_entries_vs_2      (l0_w_req_data.vs[2]),
    .io_w_req_bits_data_0_entries_vs_3      (l0_w_req_data.vs[3]),
    .io_w_req_bits_data_0_entries_vs_4      (l0_w_req_data.vs[4]),
    .io_w_req_bits_data_0_entries_vs_5      (l0_w_req_data.vs[5]),
    .io_w_req_bits_data_0_entries_vs_6      (l0_w_req_data.vs[6]),
    .io_w_req_bits_data_0_entries_vs_7      (l0_w_req_data.vs[7]),
    .io_w_req_bits_data_0_entries_onlypf_0  (l0_w_req_data.onlypf[0]),
    .io_w_req_bits_data_0_entries_onlypf_1  (l0_w_req_data.onlypf[1]),
    .io_w_req_bits_data_0_entries_onlypf_2  (l0_w_req_data.onlypf[2]),
    .io_w_req_bits_data_0_entries_onlypf_3  (l0_w_req_data.onlypf[3]),
    .io_w_req_bits_data_0_entries_onlypf_4  (l0_w_req_data.onlypf[4]),
    .io_w_req_bits_data_0_entries_onlypf_5  (l0_w_req_data.onlypf[5]),
    .io_w_req_bits_data_0_entries_onlypf_6  (l0_w_req_data.onlypf[6]),
    .io_w_req_bits_data_0_entries_onlypf_7  (l0_w_req_data.onlypf[7]),
    .io_w_req_bits_data_0_entries_perms_0_d (l0_w_req_data.perm_d[0]),
    .io_w_req_bits_data_0_entries_perms_0_a (l0_w_req_data.perm_a[0]),
    .io_w_req_bits_data_0_entries_perms_0_g (l0_w_req_data.perm_g[0]),
    .io_w_req_bits_data_0_entries_perms_0_u (l0_w_req_data.perm_u[0]),
    .io_w_req_bits_data_0_entries_perms_0_x (l0_w_req_data.perm_x[0]),
    .io_w_req_bits_data_0_entries_perms_0_w (l0_w_req_data.perm_w[0]),
    .io_w_req_bits_data_0_entries_perms_0_r (l0_w_req_data.perm_r[0]),
    .io_w_req_bits_data_0_entries_perms_1_d (l0_w_req_data.perm_d[1]),
    .io_w_req_bits_data_0_entries_perms_1_a (l0_w_req_data.perm_a[1]),
    .io_w_req_bits_data_0_entries_perms_1_g (l0_w_req_data.perm_g[1]),
    .io_w_req_bits_data_0_entries_perms_1_u (l0_w_req_data.perm_u[1]),
    .io_w_req_bits_data_0_entries_perms_1_x (l0_w_req_data.perm_x[1]),
    .io_w_req_bits_data_0_entries_perms_1_w (l0_w_req_data.perm_w[1]),
    .io_w_req_bits_data_0_entries_perms_1_r (l0_w_req_data.perm_r[1]),
    .io_w_req_bits_data_0_entries_perms_2_d (l0_w_req_data.perm_d[2]),
    .io_w_req_bits_data_0_entries_perms_2_a (l0_w_req_data.perm_a[2]),
    .io_w_req_bits_data_0_entries_perms_2_g (l0_w_req_data.perm_g[2]),
    .io_w_req_bits_data_0_entries_perms_2_u (l0_w_req_data.perm_u[2]),
    .io_w_req_bits_data_0_entries_perms_2_x (l0_w_req_data.perm_x[2]),
    .io_w_req_bits_data_0_entries_perms_2_w (l0_w_req_data.perm_w[2]),
    .io_w_req_bits_data_0_entries_perms_2_r (l0_w_req_data.perm_r[2]),
    .io_w_req_bits_data_0_entries_perms_3_d (l0_w_req_data.perm_d[3]),
    .io_w_req_bits_data_0_entries_perms_3_a (l0_w_req_data.perm_a[3]),
    .io_w_req_bits_data_0_entries_perms_3_g (l0_w_req_data.perm_g[3]),
    .io_w_req_bits_data_0_entries_perms_3_u (l0_w_req_data.perm_u[3]),
    .io_w_req_bits_data_0_entries_perms_3_x (l0_w_req_data.perm_x[3]),
    .io_w_req_bits_data_0_entries_perms_3_w (l0_w_req_data.perm_w[3]),
    .io_w_req_bits_data_0_entries_perms_3_r (l0_w_req_data.perm_r[3]),
    .io_w_req_bits_data_0_entries_perms_4_d (l0_w_req_data.perm_d[4]),
    .io_w_req_bits_data_0_entries_perms_4_a (l0_w_req_data.perm_a[4]),
    .io_w_req_bits_data_0_entries_perms_4_g (l0_w_req_data.perm_g[4]),
    .io_w_req_bits_data_0_entries_perms_4_u (l0_w_req_data.perm_u[4]),
    .io_w_req_bits_data_0_entries_perms_4_x (l0_w_req_data.perm_x[4]),
    .io_w_req_bits_data_0_entries_perms_4_w (l0_w_req_data.perm_w[4]),
    .io_w_req_bits_data_0_entries_perms_4_r (l0_w_req_data.perm_r[4]),
    .io_w_req_bits_data_0_entries_perms_5_d (l0_w_req_data.perm_d[5]),
    .io_w_req_bits_data_0_entries_perms_5_a (l0_w_req_data.perm_a[5]),
    .io_w_req_bits_data_0_entries_perms_5_g (l0_w_req_data.perm_g[5]),
    .io_w_req_bits_data_0_entries_perms_5_u (l0_w_req_data.perm_u[5]),
    .io_w_req_bits_data_0_entries_perms_5_x (l0_w_req_data.perm_x[5]),
    .io_w_req_bits_data_0_entries_perms_5_w (l0_w_req_data.perm_w[5]),
    .io_w_req_bits_data_0_entries_perms_5_r (l0_w_req_data.perm_r[5]),
    .io_w_req_bits_data_0_entries_perms_6_d (l0_w_req_data.perm_d[6]),
    .io_w_req_bits_data_0_entries_perms_6_a (l0_w_req_data.perm_a[6]),
    .io_w_req_bits_data_0_entries_perms_6_g (l0_w_req_data.perm_g[6]),
    .io_w_req_bits_data_0_entries_perms_6_u (l0_w_req_data.perm_u[6]),
    .io_w_req_bits_data_0_entries_perms_6_x (l0_w_req_data.perm_x[6]),
    .io_w_req_bits_data_0_entries_perms_6_w (l0_w_req_data.perm_w[6]),
    .io_w_req_bits_data_0_entries_perms_6_r (l0_w_req_data.perm_r[6]),
    .io_w_req_bits_data_0_entries_perms_7_d (l0_w_req_data.perm_d[7]),
    .io_w_req_bits_data_0_entries_perms_7_a (l0_w_req_data.perm_a[7]),
    .io_w_req_bits_data_0_entries_perms_7_g (l0_w_req_data.perm_g[7]),
    .io_w_req_bits_data_0_entries_perms_7_u (l0_w_req_data.perm_u[7]),
    .io_w_req_bits_data_0_entries_perms_7_x (l0_w_req_data.perm_x[7]),
    .io_w_req_bits_data_0_entries_perms_7_w (l0_w_req_data.perm_w[7]),
    .io_w_req_bits_data_0_entries_perms_7_r (l0_w_req_data.perm_r[7]),
    .io_w_req_bits_data_0_entries_prefetch  (l0_w_req_data.prefetch),
    .io_w_req_bits_data_1_entries_tag       (l0_w_req_data.tag),
    .io_w_req_bits_data_1_entries_asid      (l0_w_req_data.asid),
    .io_w_req_bits_data_1_entries_vmid      (l0_w_req_data.vmid),
    .io_w_req_bits_data_1_entries_pbmts_0   (l0_w_req_data.pbmts[0]),
    .io_w_req_bits_data_1_entries_pbmts_1   (l0_w_req_data.pbmts[1]),
    .io_w_req_bits_data_1_entries_pbmts_2   (l0_w_req_data.pbmts[2]),
    .io_w_req_bits_data_1_entries_pbmts_3   (l0_w_req_data.pbmts[3]),
    .io_w_req_bits_data_1_entries_pbmts_4   (l0_w_req_data.pbmts[4]),
    .io_w_req_bits_data_1_entries_pbmts_5   (l0_w_req_data.pbmts[5]),
    .io_w_req_bits_data_1_entries_pbmts_6   (l0_w_req_data.pbmts[6]),
    .io_w_req_bits_data_1_entries_pbmts_7   (l0_w_req_data.pbmts[7]),
    .io_w_req_bits_data_1_entries_ppns_0    (l0_w_req_data.ppns[0]),
    .io_w_req_bits_data_1_entries_ppns_1    (l0_w_req_data.ppns[1]),
    .io_w_req_bits_data_1_entries_ppns_2    (l0_w_req_data.ppns[2]),
    .io_w_req_bits_data_1_entries_ppns_3    (l0_w_req_data.ppns[3]),
    .io_w_req_bits_data_1_entries_ppns_4    (l0_w_req_data.ppns[4]),
    .io_w_req_bits_data_1_entries_ppns_5    (l0_w_req_data.ppns[5]),
    .io_w_req_bits_data_1_entries_ppns_6    (l0_w_req_data.ppns[6]),
    .io_w_req_bits_data_1_entries_ppns_7    (l0_w_req_data.ppns[7]),
    .io_w_req_bits_data_1_entries_vs_0      (l0_w_req_data.vs[0]),
    .io_w_req_bits_data_1_entries_vs_1      (l0_w_req_data.vs[1]),
    .io_w_req_bits_data_1_entries_vs_2      (l0_w_req_data.vs[2]),
    .io_w_req_bits_data_1_entries_vs_3      (l0_w_req_data.vs[3]),
    .io_w_req_bits_data_1_entries_vs_4      (l0_w_req_data.vs[4]),
    .io_w_req_bits_data_1_entries_vs_5      (l0_w_req_data.vs[5]),
    .io_w_req_bits_data_1_entries_vs_6      (l0_w_req_data.vs[6]),
    .io_w_req_bits_data_1_entries_vs_7      (l0_w_req_data.vs[7]),
    .io_w_req_bits_data_1_entries_onlypf_0  (l0_w_req_data.onlypf[0]),
    .io_w_req_bits_data_1_entries_onlypf_1  (l0_w_req_data.onlypf[1]),
    .io_w_req_bits_data_1_entries_onlypf_2  (l0_w_req_data.onlypf[2]),
    .io_w_req_bits_data_1_entries_onlypf_3  (l0_w_req_data.onlypf[3]),
    .io_w_req_bits_data_1_entries_onlypf_4  (l0_w_req_data.onlypf[4]),
    .io_w_req_bits_data_1_entries_onlypf_5  (l0_w_req_data.onlypf[5]),
    .io_w_req_bits_data_1_entries_onlypf_6  (l0_w_req_data.onlypf[6]),
    .io_w_req_bits_data_1_entries_onlypf_7  (l0_w_req_data.onlypf[7]),
    .io_w_req_bits_data_1_entries_perms_0_d (l0_w_req_data.perm_d[0]),
    .io_w_req_bits_data_1_entries_perms_0_a (l0_w_req_data.perm_a[0]),
    .io_w_req_bits_data_1_entries_perms_0_g (l0_w_req_data.perm_g[0]),
    .io_w_req_bits_data_1_entries_perms_0_u (l0_w_req_data.perm_u[0]),
    .io_w_req_bits_data_1_entries_perms_0_x (l0_w_req_data.perm_x[0]),
    .io_w_req_bits_data_1_entries_perms_0_w (l0_w_req_data.perm_w[0]),
    .io_w_req_bits_data_1_entries_perms_0_r (l0_w_req_data.perm_r[0]),
    .io_w_req_bits_data_1_entries_perms_1_d (l0_w_req_data.perm_d[1]),
    .io_w_req_bits_data_1_entries_perms_1_a (l0_w_req_data.perm_a[1]),
    .io_w_req_bits_data_1_entries_perms_1_g (l0_w_req_data.perm_g[1]),
    .io_w_req_bits_data_1_entries_perms_1_u (l0_w_req_data.perm_u[1]),
    .io_w_req_bits_data_1_entries_perms_1_x (l0_w_req_data.perm_x[1]),
    .io_w_req_bits_data_1_entries_perms_1_w (l0_w_req_data.perm_w[1]),
    .io_w_req_bits_data_1_entries_perms_1_r (l0_w_req_data.perm_r[1]),
    .io_w_req_bits_data_1_entries_perms_2_d (l0_w_req_data.perm_d[2]),
    .io_w_req_bits_data_1_entries_perms_2_a (l0_w_req_data.perm_a[2]),
    .io_w_req_bits_data_1_entries_perms_2_g (l0_w_req_data.perm_g[2]),
    .io_w_req_bits_data_1_entries_perms_2_u (l0_w_req_data.perm_u[2]),
    .io_w_req_bits_data_1_entries_perms_2_x (l0_w_req_data.perm_x[2]),
    .io_w_req_bits_data_1_entries_perms_2_w (l0_w_req_data.perm_w[2]),
    .io_w_req_bits_data_1_entries_perms_2_r (l0_w_req_data.perm_r[2]),
    .io_w_req_bits_data_1_entries_perms_3_d (l0_w_req_data.perm_d[3]),
    .io_w_req_bits_data_1_entries_perms_3_a (l0_w_req_data.perm_a[3]),
    .io_w_req_bits_data_1_entries_perms_3_g (l0_w_req_data.perm_g[3]),
    .io_w_req_bits_data_1_entries_perms_3_u (l0_w_req_data.perm_u[3]),
    .io_w_req_bits_data_1_entries_perms_3_x (l0_w_req_data.perm_x[3]),
    .io_w_req_bits_data_1_entries_perms_3_w (l0_w_req_data.perm_w[3]),
    .io_w_req_bits_data_1_entries_perms_3_r (l0_w_req_data.perm_r[3]),
    .io_w_req_bits_data_1_entries_perms_4_d (l0_w_req_data.perm_d[4]),
    .io_w_req_bits_data_1_entries_perms_4_a (l0_w_req_data.perm_a[4]),
    .io_w_req_bits_data_1_entries_perms_4_g (l0_w_req_data.perm_g[4]),
    .io_w_req_bits_data_1_entries_perms_4_u (l0_w_req_data.perm_u[4]),
    .io_w_req_bits_data_1_entries_perms_4_x (l0_w_req_data.perm_x[4]),
    .io_w_req_bits_data_1_entries_perms_4_w (l0_w_req_data.perm_w[4]),
    .io_w_req_bits_data_1_entries_perms_4_r (l0_w_req_data.perm_r[4]),
    .io_w_req_bits_data_1_entries_perms_5_d (l0_w_req_data.perm_d[5]),
    .io_w_req_bits_data_1_entries_perms_5_a (l0_w_req_data.perm_a[5]),
    .io_w_req_bits_data_1_entries_perms_5_g (l0_w_req_data.perm_g[5]),
    .io_w_req_bits_data_1_entries_perms_5_u (l0_w_req_data.perm_u[5]),
    .io_w_req_bits_data_1_entries_perms_5_x (l0_w_req_data.perm_x[5]),
    .io_w_req_bits_data_1_entries_perms_5_w (l0_w_req_data.perm_w[5]),
    .io_w_req_bits_data_1_entries_perms_5_r (l0_w_req_data.perm_r[5]),
    .io_w_req_bits_data_1_entries_perms_6_d (l0_w_req_data.perm_d[6]),
    .io_w_req_bits_data_1_entries_perms_6_a (l0_w_req_data.perm_a[6]),
    .io_w_req_bits_data_1_entries_perms_6_g (l0_w_req_data.perm_g[6]),
    .io_w_req_bits_data_1_entries_perms_6_u (l0_w_req_data.perm_u[6]),
    .io_w_req_bits_data_1_entries_perms_6_x (l0_w_req_data.perm_x[6]),
    .io_w_req_bits_data_1_entries_perms_6_w (l0_w_req_data.perm_w[6]),
    .io_w_req_bits_data_1_entries_perms_6_r (l0_w_req_data.perm_r[6]),
    .io_w_req_bits_data_1_entries_perms_7_d (l0_w_req_data.perm_d[7]),
    .io_w_req_bits_data_1_entries_perms_7_a (l0_w_req_data.perm_a[7]),
    .io_w_req_bits_data_1_entries_perms_7_g (l0_w_req_data.perm_g[7]),
    .io_w_req_bits_data_1_entries_perms_7_u (l0_w_req_data.perm_u[7]),
    .io_w_req_bits_data_1_entries_perms_7_x (l0_w_req_data.perm_x[7]),
    .io_w_req_bits_data_1_entries_perms_7_w (l0_w_req_data.perm_w[7]),
    .io_w_req_bits_data_1_entries_perms_7_r (l0_w_req_data.perm_r[7]),
    .io_w_req_bits_data_1_entries_prefetch  (l0_w_req_data.prefetch),
    .io_w_req_bits_data_2_entries_tag       (l0_w_req_data.tag),
    .io_w_req_bits_data_2_entries_asid      (l0_w_req_data.asid),
    .io_w_req_bits_data_2_entries_vmid      (l0_w_req_data.vmid),
    .io_w_req_bits_data_2_entries_pbmts_0   (l0_w_req_data.pbmts[0]),
    .io_w_req_bits_data_2_entries_pbmts_1   (l0_w_req_data.pbmts[1]),
    .io_w_req_bits_data_2_entries_pbmts_2   (l0_w_req_data.pbmts[2]),
    .io_w_req_bits_data_2_entries_pbmts_3   (l0_w_req_data.pbmts[3]),
    .io_w_req_bits_data_2_entries_pbmts_4   (l0_w_req_data.pbmts[4]),
    .io_w_req_bits_data_2_entries_pbmts_5   (l0_w_req_data.pbmts[5]),
    .io_w_req_bits_data_2_entries_pbmts_6   (l0_w_req_data.pbmts[6]),
    .io_w_req_bits_data_2_entries_pbmts_7   (l0_w_req_data.pbmts[7]),
    .io_w_req_bits_data_2_entries_ppns_0    (l0_w_req_data.ppns[0]),
    .io_w_req_bits_data_2_entries_ppns_1    (l0_w_req_data.ppns[1]),
    .io_w_req_bits_data_2_entries_ppns_2    (l0_w_req_data.ppns[2]),
    .io_w_req_bits_data_2_entries_ppns_3    (l0_w_req_data.ppns[3]),
    .io_w_req_bits_data_2_entries_ppns_4    (l0_w_req_data.ppns[4]),
    .io_w_req_bits_data_2_entries_ppns_5    (l0_w_req_data.ppns[5]),
    .io_w_req_bits_data_2_entries_ppns_6    (l0_w_req_data.ppns[6]),
    .io_w_req_bits_data_2_entries_ppns_7    (l0_w_req_data.ppns[7]),
    .io_w_req_bits_data_2_entries_vs_0      (l0_w_req_data.vs[0]),
    .io_w_req_bits_data_2_entries_vs_1      (l0_w_req_data.vs[1]),
    .io_w_req_bits_data_2_entries_vs_2      (l0_w_req_data.vs[2]),
    .io_w_req_bits_data_2_entries_vs_3      (l0_w_req_data.vs[3]),
    .io_w_req_bits_data_2_entries_vs_4      (l0_w_req_data.vs[4]),
    .io_w_req_bits_data_2_entries_vs_5      (l0_w_req_data.vs[5]),
    .io_w_req_bits_data_2_entries_vs_6      (l0_w_req_data.vs[6]),
    .io_w_req_bits_data_2_entries_vs_7      (l0_w_req_data.vs[7]),
    .io_w_req_bits_data_2_entries_onlypf_0  (l0_w_req_data.onlypf[0]),
    .io_w_req_bits_data_2_entries_onlypf_1  (l0_w_req_data.onlypf[1]),
    .io_w_req_bits_data_2_entries_onlypf_2  (l0_w_req_data.onlypf[2]),
    .io_w_req_bits_data_2_entries_onlypf_3  (l0_w_req_data.onlypf[3]),
    .io_w_req_bits_data_2_entries_onlypf_4  (l0_w_req_data.onlypf[4]),
    .io_w_req_bits_data_2_entries_onlypf_5  (l0_w_req_data.onlypf[5]),
    .io_w_req_bits_data_2_entries_onlypf_6  (l0_w_req_data.onlypf[6]),
    .io_w_req_bits_data_2_entries_onlypf_7  (l0_w_req_data.onlypf[7]),
    .io_w_req_bits_data_2_entries_perms_0_d (l0_w_req_data.perm_d[0]),
    .io_w_req_bits_data_2_entries_perms_0_a (l0_w_req_data.perm_a[0]),
    .io_w_req_bits_data_2_entries_perms_0_g (l0_w_req_data.perm_g[0]),
    .io_w_req_bits_data_2_entries_perms_0_u (l0_w_req_data.perm_u[0]),
    .io_w_req_bits_data_2_entries_perms_0_x (l0_w_req_data.perm_x[0]),
    .io_w_req_bits_data_2_entries_perms_0_w (l0_w_req_data.perm_w[0]),
    .io_w_req_bits_data_2_entries_perms_0_r (l0_w_req_data.perm_r[0]),
    .io_w_req_bits_data_2_entries_perms_1_d (l0_w_req_data.perm_d[1]),
    .io_w_req_bits_data_2_entries_perms_1_a (l0_w_req_data.perm_a[1]),
    .io_w_req_bits_data_2_entries_perms_1_g (l0_w_req_data.perm_g[1]),
    .io_w_req_bits_data_2_entries_perms_1_u (l0_w_req_data.perm_u[1]),
    .io_w_req_bits_data_2_entries_perms_1_x (l0_w_req_data.perm_x[1]),
    .io_w_req_bits_data_2_entries_perms_1_w (l0_w_req_data.perm_w[1]),
    .io_w_req_bits_data_2_entries_perms_1_r (l0_w_req_data.perm_r[1]),
    .io_w_req_bits_data_2_entries_perms_2_d (l0_w_req_data.perm_d[2]),
    .io_w_req_bits_data_2_entries_perms_2_a (l0_w_req_data.perm_a[2]),
    .io_w_req_bits_data_2_entries_perms_2_g (l0_w_req_data.perm_g[2]),
    .io_w_req_bits_data_2_entries_perms_2_u (l0_w_req_data.perm_u[2]),
    .io_w_req_bits_data_2_entries_perms_2_x (l0_w_req_data.perm_x[2]),
    .io_w_req_bits_data_2_entries_perms_2_w (l0_w_req_data.perm_w[2]),
    .io_w_req_bits_data_2_entries_perms_2_r (l0_w_req_data.perm_r[2]),
    .io_w_req_bits_data_2_entries_perms_3_d (l0_w_req_data.perm_d[3]),
    .io_w_req_bits_data_2_entries_perms_3_a (l0_w_req_data.perm_a[3]),
    .io_w_req_bits_data_2_entries_perms_3_g (l0_w_req_data.perm_g[3]),
    .io_w_req_bits_data_2_entries_perms_3_u (l0_w_req_data.perm_u[3]),
    .io_w_req_bits_data_2_entries_perms_3_x (l0_w_req_data.perm_x[3]),
    .io_w_req_bits_data_2_entries_perms_3_w (l0_w_req_data.perm_w[3]),
    .io_w_req_bits_data_2_entries_perms_3_r (l0_w_req_data.perm_r[3]),
    .io_w_req_bits_data_2_entries_perms_4_d (l0_w_req_data.perm_d[4]),
    .io_w_req_bits_data_2_entries_perms_4_a (l0_w_req_data.perm_a[4]),
    .io_w_req_bits_data_2_entries_perms_4_g (l0_w_req_data.perm_g[4]),
    .io_w_req_bits_data_2_entries_perms_4_u (l0_w_req_data.perm_u[4]),
    .io_w_req_bits_data_2_entries_perms_4_x (l0_w_req_data.perm_x[4]),
    .io_w_req_bits_data_2_entries_perms_4_w (l0_w_req_data.perm_w[4]),
    .io_w_req_bits_data_2_entries_perms_4_r (l0_w_req_data.perm_r[4]),
    .io_w_req_bits_data_2_entries_perms_5_d (l0_w_req_data.perm_d[5]),
    .io_w_req_bits_data_2_entries_perms_5_a (l0_w_req_data.perm_a[5]),
    .io_w_req_bits_data_2_entries_perms_5_g (l0_w_req_data.perm_g[5]),
    .io_w_req_bits_data_2_entries_perms_5_u (l0_w_req_data.perm_u[5]),
    .io_w_req_bits_data_2_entries_perms_5_x (l0_w_req_data.perm_x[5]),
    .io_w_req_bits_data_2_entries_perms_5_w (l0_w_req_data.perm_w[5]),
    .io_w_req_bits_data_2_entries_perms_5_r (l0_w_req_data.perm_r[5]),
    .io_w_req_bits_data_2_entries_perms_6_d (l0_w_req_data.perm_d[6]),
    .io_w_req_bits_data_2_entries_perms_6_a (l0_w_req_data.perm_a[6]),
    .io_w_req_bits_data_2_entries_perms_6_g (l0_w_req_data.perm_g[6]),
    .io_w_req_bits_data_2_entries_perms_6_u (l0_w_req_data.perm_u[6]),
    .io_w_req_bits_data_2_entries_perms_6_x (l0_w_req_data.perm_x[6]),
    .io_w_req_bits_data_2_entries_perms_6_w (l0_w_req_data.perm_w[6]),
    .io_w_req_bits_data_2_entries_perms_6_r (l0_w_req_data.perm_r[6]),
    .io_w_req_bits_data_2_entries_perms_7_d (l0_w_req_data.perm_d[7]),
    .io_w_req_bits_data_2_entries_perms_7_a (l0_w_req_data.perm_a[7]),
    .io_w_req_bits_data_2_entries_perms_7_g (l0_w_req_data.perm_g[7]),
    .io_w_req_bits_data_2_entries_perms_7_u (l0_w_req_data.perm_u[7]),
    .io_w_req_bits_data_2_entries_perms_7_x (l0_w_req_data.perm_x[7]),
    .io_w_req_bits_data_2_entries_perms_7_w (l0_w_req_data.perm_w[7]),
    .io_w_req_bits_data_2_entries_perms_7_r (l0_w_req_data.perm_r[7]),
    .io_w_req_bits_data_2_entries_prefetch  (l0_w_req_data.prefetch),
    .io_w_req_bits_data_3_entries_tag       (l0_w_req_data.tag),
    .io_w_req_bits_data_3_entries_asid      (l0_w_req_data.asid),
    .io_w_req_bits_data_3_entries_vmid      (l0_w_req_data.vmid),
    .io_w_req_bits_data_3_entries_pbmts_0   (l0_w_req_data.pbmts[0]),
    .io_w_req_bits_data_3_entries_pbmts_1   (l0_w_req_data.pbmts[1]),
    .io_w_req_bits_data_3_entries_pbmts_2   (l0_w_req_data.pbmts[2]),
    .io_w_req_bits_data_3_entries_pbmts_3   (l0_w_req_data.pbmts[3]),
    .io_w_req_bits_data_3_entries_pbmts_4   (l0_w_req_data.pbmts[4]),
    .io_w_req_bits_data_3_entries_pbmts_5   (l0_w_req_data.pbmts[5]),
    .io_w_req_bits_data_3_entries_pbmts_6   (l0_w_req_data.pbmts[6]),
    .io_w_req_bits_data_3_entries_pbmts_7   (l0_w_req_data.pbmts[7]),
    .io_w_req_bits_data_3_entries_ppns_0    (l0_w_req_data.ppns[0]),
    .io_w_req_bits_data_3_entries_ppns_1    (l0_w_req_data.ppns[1]),
    .io_w_req_bits_data_3_entries_ppns_2    (l0_w_req_data.ppns[2]),
    .io_w_req_bits_data_3_entries_ppns_3    (l0_w_req_data.ppns[3]),
    .io_w_req_bits_data_3_entries_ppns_4    (l0_w_req_data.ppns[4]),
    .io_w_req_bits_data_3_entries_ppns_5    (l0_w_req_data.ppns[5]),
    .io_w_req_bits_data_3_entries_ppns_6    (l0_w_req_data.ppns[6]),
    .io_w_req_bits_data_3_entries_ppns_7    (l0_w_req_data.ppns[7]),
    .io_w_req_bits_data_3_entries_vs_0      (l0_w_req_data.vs[0]),
    .io_w_req_bits_data_3_entries_vs_1      (l0_w_req_data.vs[1]),
    .io_w_req_bits_data_3_entries_vs_2      (l0_w_req_data.vs[2]),
    .io_w_req_bits_data_3_entries_vs_3      (l0_w_req_data.vs[3]),
    .io_w_req_bits_data_3_entries_vs_4      (l0_w_req_data.vs[4]),
    .io_w_req_bits_data_3_entries_vs_5      (l0_w_req_data.vs[5]),
    .io_w_req_bits_data_3_entries_vs_6      (l0_w_req_data.vs[6]),
    .io_w_req_bits_data_3_entries_vs_7      (l0_w_req_data.vs[7]),
    .io_w_req_bits_data_3_entries_onlypf_0  (l0_w_req_data.onlypf[0]),
    .io_w_req_bits_data_3_entries_onlypf_1  (l0_w_req_data.onlypf[1]),
    .io_w_req_bits_data_3_entries_onlypf_2  (l0_w_req_data.onlypf[2]),
    .io_w_req_bits_data_3_entries_onlypf_3  (l0_w_req_data.onlypf[3]),
    .io_w_req_bits_data_3_entries_onlypf_4  (l0_w_req_data.onlypf[4]),
    .io_w_req_bits_data_3_entries_onlypf_5  (l0_w_req_data.onlypf[5]),
    .io_w_req_bits_data_3_entries_onlypf_6  (l0_w_req_data.onlypf[6]),
    .io_w_req_bits_data_3_entries_onlypf_7  (l0_w_req_data.onlypf[7]),
    .io_w_req_bits_data_3_entries_perms_0_d (l0_w_req_data.perm_d[0]),
    .io_w_req_bits_data_3_entries_perms_0_a (l0_w_req_data.perm_a[0]),
    .io_w_req_bits_data_3_entries_perms_0_g (l0_w_req_data.perm_g[0]),
    .io_w_req_bits_data_3_entries_perms_0_u (l0_w_req_data.perm_u[0]),
    .io_w_req_bits_data_3_entries_perms_0_x (l0_w_req_data.perm_x[0]),
    .io_w_req_bits_data_3_entries_perms_0_w (l0_w_req_data.perm_w[0]),
    .io_w_req_bits_data_3_entries_perms_0_r (l0_w_req_data.perm_r[0]),
    .io_w_req_bits_data_3_entries_perms_1_d (l0_w_req_data.perm_d[1]),
    .io_w_req_bits_data_3_entries_perms_1_a (l0_w_req_data.perm_a[1]),
    .io_w_req_bits_data_3_entries_perms_1_g (l0_w_req_data.perm_g[1]),
    .io_w_req_bits_data_3_entries_perms_1_u (l0_w_req_data.perm_u[1]),
    .io_w_req_bits_data_3_entries_perms_1_x (l0_w_req_data.perm_x[1]),
    .io_w_req_bits_data_3_entries_perms_1_w (l0_w_req_data.perm_w[1]),
    .io_w_req_bits_data_3_entries_perms_1_r (l0_w_req_data.perm_r[1]),
    .io_w_req_bits_data_3_entries_perms_2_d (l0_w_req_data.perm_d[2]),
    .io_w_req_bits_data_3_entries_perms_2_a (l0_w_req_data.perm_a[2]),
    .io_w_req_bits_data_3_entries_perms_2_g (l0_w_req_data.perm_g[2]),
    .io_w_req_bits_data_3_entries_perms_2_u (l0_w_req_data.perm_u[2]),
    .io_w_req_bits_data_3_entries_perms_2_x (l0_w_req_data.perm_x[2]),
    .io_w_req_bits_data_3_entries_perms_2_w (l0_w_req_data.perm_w[2]),
    .io_w_req_bits_data_3_entries_perms_2_r (l0_w_req_data.perm_r[2]),
    .io_w_req_bits_data_3_entries_perms_3_d (l0_w_req_data.perm_d[3]),
    .io_w_req_bits_data_3_entries_perms_3_a (l0_w_req_data.perm_a[3]),
    .io_w_req_bits_data_3_entries_perms_3_g (l0_w_req_data.perm_g[3]),
    .io_w_req_bits_data_3_entries_perms_3_u (l0_w_req_data.perm_u[3]),
    .io_w_req_bits_data_3_entries_perms_3_x (l0_w_req_data.perm_x[3]),
    .io_w_req_bits_data_3_entries_perms_3_w (l0_w_req_data.perm_w[3]),
    .io_w_req_bits_data_3_entries_perms_3_r (l0_w_req_data.perm_r[3]),
    .io_w_req_bits_data_3_entries_perms_4_d (l0_w_req_data.perm_d[4]),
    .io_w_req_bits_data_3_entries_perms_4_a (l0_w_req_data.perm_a[4]),
    .io_w_req_bits_data_3_entries_perms_4_g (l0_w_req_data.perm_g[4]),
    .io_w_req_bits_data_3_entries_perms_4_u (l0_w_req_data.perm_u[4]),
    .io_w_req_bits_data_3_entries_perms_4_x (l0_w_req_data.perm_x[4]),
    .io_w_req_bits_data_3_entries_perms_4_w (l0_w_req_data.perm_w[4]),
    .io_w_req_bits_data_3_entries_perms_4_r (l0_w_req_data.perm_r[4]),
    .io_w_req_bits_data_3_entries_perms_5_d (l0_w_req_data.perm_d[5]),
    .io_w_req_bits_data_3_entries_perms_5_a (l0_w_req_data.perm_a[5]),
    .io_w_req_bits_data_3_entries_perms_5_g (l0_w_req_data.perm_g[5]),
    .io_w_req_bits_data_3_entries_perms_5_u (l0_w_req_data.perm_u[5]),
    .io_w_req_bits_data_3_entries_perms_5_x (l0_w_req_data.perm_x[5]),
    .io_w_req_bits_data_3_entries_perms_5_w (l0_w_req_data.perm_w[5]),
    .io_w_req_bits_data_3_entries_perms_5_r (l0_w_req_data.perm_r[5]),
    .io_w_req_bits_data_3_entries_perms_6_d (l0_w_req_data.perm_d[6]),
    .io_w_req_bits_data_3_entries_perms_6_a (l0_w_req_data.perm_a[6]),
    .io_w_req_bits_data_3_entries_perms_6_g (l0_w_req_data.perm_g[6]),
    .io_w_req_bits_data_3_entries_perms_6_u (l0_w_req_data.perm_u[6]),
    .io_w_req_bits_data_3_entries_perms_6_x (l0_w_req_data.perm_x[6]),
    .io_w_req_bits_data_3_entries_perms_6_w (l0_w_req_data.perm_w[6]),
    .io_w_req_bits_data_3_entries_perms_6_r (l0_w_req_data.perm_r[6]),
    .io_w_req_bits_data_3_entries_perms_7_d (l0_w_req_data.perm_d[7]),
    .io_w_req_bits_data_3_entries_perms_7_a (l0_w_req_data.perm_a[7]),
    .io_w_req_bits_data_3_entries_perms_7_g (l0_w_req_data.perm_g[7]),
    .io_w_req_bits_data_3_entries_perms_7_u (l0_w_req_data.perm_u[7]),
    .io_w_req_bits_data_3_entries_perms_7_x (l0_w_req_data.perm_x[7]),
    .io_w_req_bits_data_3_entries_perms_7_w (l0_w_req_data.perm_w[7]),
    .io_w_req_bits_data_3_entries_perms_7_r (l0_w_req_data.perm_r[7]),
    .io_w_req_bits_data_3_entries_prefetch  (l0_w_req_data.prefetch),
    .io_w_req_bits_waymask                  (l0_w_req_waymask),
    .boreChildrenBd_bore_addr               (childBd_4_addr),
    .boreChildrenBd_bore_addr_rd            (childBd_4_addr_rd),
    .boreChildrenBd_bore_wdata              (childBd_4_wdata),
    .boreChildrenBd_bore_wmask              (childBd_4_wmask),
    .boreChildrenBd_bore_re                 (childBd_4_re),
    .boreChildrenBd_bore_we                 (childBd_4_we),
    .boreChildrenBd_bore_rdata              (childBd_4_rdata),
    .boreChildrenBd_bore_ack                (childBd_4_ack),
    .boreChildrenBd_bore_selectedOH         (childBd_4_selectedOH),
    .boreChildrenBd_bore_array              (childBd_4_array),
    .boreChildrenBd_bore_1_addr             (childBd_5_addr),
    .boreChildrenBd_bore_1_addr_rd          (childBd_5_addr_rd),
    .boreChildrenBd_bore_1_wdata            (childBd_5_wdata),
    .boreChildrenBd_bore_1_wmask            (childBd_5_wmask),
    .boreChildrenBd_bore_1_re               (childBd_5_re),
    .boreChildrenBd_bore_1_we               (childBd_5_we),
    .boreChildrenBd_bore_1_rdata            (childBd_5_rdata),
    .boreChildrenBd_bore_1_ack              (childBd_5_ack),
    .boreChildrenBd_bore_1_selectedOH       (childBd_5_selectedOH),
    .boreChildrenBd_bore_1_array            (childBd_5_array),
    .boreChildrenBd_bore_2_addr             (childBd_6_addr),
    .boreChildrenBd_bore_2_addr_rd          (childBd_6_addr_rd),
    .boreChildrenBd_bore_2_wdata            (childBd_6_wdata),
    .boreChildrenBd_bore_2_wmask            (childBd_6_wmask),
    .boreChildrenBd_bore_2_re               (childBd_6_re),
    .boreChildrenBd_bore_2_we               (childBd_6_we),
    .boreChildrenBd_bore_2_rdata            (childBd_6_rdata),
    .boreChildrenBd_bore_2_ack              (childBd_6_ack),
    .boreChildrenBd_bore_2_selectedOH       (childBd_6_selectedOH),
    .boreChildrenBd_bore_2_array            (childBd_6_array),
    .boreChildrenBd_bore_3_addr             (childBd_7_addr),
    .boreChildrenBd_bore_3_addr_rd          (childBd_7_addr_rd),
    .boreChildrenBd_bore_3_wdata            (childBd_7_wdata),
    .boreChildrenBd_bore_3_wmask            (childBd_7_wmask),
    .boreChildrenBd_bore_3_re               (childBd_7_re),
    .boreChildrenBd_bore_3_we               (childBd_7_we),
    .boreChildrenBd_bore_3_rdata            (childBd_7_rdata),
    .boreChildrenBd_bore_3_ack              (childBd_7_ack),
    .boreChildrenBd_bore_3_selectedOH       (childBd_7_selectedOH),
    .boreChildrenBd_bore_3_array            (childBd_7_array),
    .boreChildrenBd_bore_4_addr             (childBd_8_addr),
    .boreChildrenBd_bore_4_addr_rd          (childBd_8_addr_rd),
    .boreChildrenBd_bore_4_wdata            (childBd_8_wdata),
    .boreChildrenBd_bore_4_wmask            (childBd_8_wmask),
    .boreChildrenBd_bore_4_re               (childBd_8_re),
    .boreChildrenBd_bore_4_we               (childBd_8_we),
    .boreChildrenBd_bore_4_rdata            (childBd_8_rdata),
    .boreChildrenBd_bore_4_ack              (childBd_8_ack),
    .boreChildrenBd_bore_4_selectedOH       (childBd_8_selectedOH),
    .boreChildrenBd_bore_4_array            (childBd_8_array),
    .boreChildrenBd_bore_5_addr             (childBd_9_addr),
    .boreChildrenBd_bore_5_addr_rd          (childBd_9_addr_rd),
    .boreChildrenBd_bore_5_wdata            (childBd_9_wdata),
    .boreChildrenBd_bore_5_wmask            (childBd_9_wmask),
    .boreChildrenBd_bore_5_re               (childBd_9_re),
    .boreChildrenBd_bore_5_we               (childBd_9_we),
    .boreChildrenBd_bore_5_rdata            (childBd_9_rdata),
    .boreChildrenBd_bore_5_ack              (childBd_9_ack),
    .boreChildrenBd_bore_5_selectedOH       (childBd_9_selectedOH),
    .boreChildrenBd_bore_5_array            (childBd_9_array),
    .boreChildrenBd_bore_6_addr             (childBd_10_addr),
    .boreChildrenBd_bore_6_addr_rd          (childBd_10_addr_rd),
    .boreChildrenBd_bore_6_wdata            (childBd_10_wdata),
    .boreChildrenBd_bore_6_wmask            (childBd_10_wmask),
    .boreChildrenBd_bore_6_re               (childBd_10_re),
    .boreChildrenBd_bore_6_we               (childBd_10_we),
    .boreChildrenBd_bore_6_rdata            (childBd_10_rdata),
    .boreChildrenBd_bore_6_ack              (childBd_10_ack),
    .boreChildrenBd_bore_6_selectedOH       (childBd_10_selectedOH),
    .boreChildrenBd_bore_6_array            (childBd_10_array),
    .boreChildrenBd_bore_7_addr             (childBd_11_addr),
    .boreChildrenBd_bore_7_addr_rd          (childBd_11_addr_rd),
    .boreChildrenBd_bore_7_wdata            (childBd_11_wdata),
    .boreChildrenBd_bore_7_wmask            (childBd_11_wmask),
    .boreChildrenBd_bore_7_re               (childBd_11_re),
    .boreChildrenBd_bore_7_we               (childBd_11_we),
    .boreChildrenBd_bore_7_rdata            (childBd_11_rdata),
    .boreChildrenBd_bore_7_ack              (childBd_11_ack),
    .boreChildrenBd_bore_7_selectedOH       (childBd_11_selectedOH),
    .boreChildrenBd_bore_7_array            (childBd_11_array),
    .sigFromSrams_bore_ram_hold             (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass           (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken         (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk          (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp         (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold         (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen                 (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold           (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass         (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken       (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk        (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp       (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold       (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen               (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_2_ram_hold           (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_2_ram_bypass         (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken       (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk        (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp       (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold       (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen               (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_3_ram_hold           (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_3_ram_bypass         (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken       (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk        (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp       (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold       (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen               (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_4_ram_hold           (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_4_ram_bypass         (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken       (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk        (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp       (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold       (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen               (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_5_ram_hold           (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_5_ram_bypass         (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken       (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk        (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp       (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold       (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen               (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_6_ram_hold           (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_6_ram_bypass         (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken       (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk        (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp       (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold       (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen               (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_7_ram_hold           (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_7_ram_bypass         (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken       (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk        (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp       (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold       (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen               (sigFromSrams_bore_11_cgen)
  );
  MbistPipePtwL0 mbistPlL0 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (bd_1_array),
    .mbist_all           (bd_1_all),
    .mbist_req           (bd_1_req),
    .mbist_ack           (bd_1_ack),
    .mbist_writeen       (bd_1_writeen),
    .mbist_be            (bd_1_be),
    .mbist_addr          (bd_1_addr),
    .mbist_indata        (bd_1_indata),
    .mbist_readen        (bd_1_readen),
    .mbist_addr_rd       (bd_1_addr_rd),
    .mbist_outdata       (bd_1_outdata),
    .toSRAM_0_addr       (childBd_4_addr),
    .toSRAM_0_addr_rd    (childBd_4_addr_rd),
    .toSRAM_0_wdata      (childBd_4_wdata),
    .toSRAM_0_wmask      (childBd_4_wmask),
    .toSRAM_0_re         (childBd_4_re),
    .toSRAM_0_we         (childBd_4_we),
    .toSRAM_0_rdata      (childBd_4_rdata),
    .toSRAM_0_ack        (childBd_4_ack),
    .toSRAM_0_selectedOH (childBd_4_selectedOH),
    .toSRAM_0_array      (childBd_4_array),
    .toSRAM_1_addr       (childBd_5_addr),
    .toSRAM_1_addr_rd    (childBd_5_addr_rd),
    .toSRAM_1_wdata      (childBd_5_wdata),
    .toSRAM_1_wmask      (childBd_5_wmask),
    .toSRAM_1_re         (childBd_5_re),
    .toSRAM_1_we         (childBd_5_we),
    .toSRAM_1_rdata      (childBd_5_rdata),
    .toSRAM_1_ack        (childBd_5_ack),
    .toSRAM_1_selectedOH (childBd_5_selectedOH),
    .toSRAM_1_array      (childBd_5_array),
    .toSRAM_2_addr       (childBd_6_addr),
    .toSRAM_2_addr_rd    (childBd_6_addr_rd),
    .toSRAM_2_wdata      (childBd_6_wdata),
    .toSRAM_2_wmask      (childBd_6_wmask),
    .toSRAM_2_re         (childBd_6_re),
    .toSRAM_2_we         (childBd_6_we),
    .toSRAM_2_rdata      (childBd_6_rdata),
    .toSRAM_2_ack        (childBd_6_ack),
    .toSRAM_2_selectedOH (childBd_6_selectedOH),
    .toSRAM_2_array      (childBd_6_array),
    .toSRAM_3_addr       (childBd_7_addr),
    .toSRAM_3_addr_rd    (childBd_7_addr_rd),
    .toSRAM_3_wdata      (childBd_7_wdata),
    .toSRAM_3_wmask      (childBd_7_wmask),
    .toSRAM_3_re         (childBd_7_re),
    .toSRAM_3_we         (childBd_7_we),
    .toSRAM_3_rdata      (childBd_7_rdata),
    .toSRAM_3_ack        (childBd_7_ack),
    .toSRAM_3_selectedOH (childBd_7_selectedOH),
    .toSRAM_3_array      (childBd_7_array),
    .toSRAM_4_addr       (childBd_8_addr),
    .toSRAM_4_addr_rd    (childBd_8_addr_rd),
    .toSRAM_4_wdata      (childBd_8_wdata),
    .toSRAM_4_wmask      (childBd_8_wmask),
    .toSRAM_4_re         (childBd_8_re),
    .toSRAM_4_we         (childBd_8_we),
    .toSRAM_4_rdata      (childBd_8_rdata),
    .toSRAM_4_ack        (childBd_8_ack),
    .toSRAM_4_selectedOH (childBd_8_selectedOH),
    .toSRAM_4_array      (childBd_8_array),
    .toSRAM_5_addr       (childBd_9_addr),
    .toSRAM_5_addr_rd    (childBd_9_addr_rd),
    .toSRAM_5_wdata      (childBd_9_wdata),
    .toSRAM_5_wmask      (childBd_9_wmask),
    .toSRAM_5_re         (childBd_9_re),
    .toSRAM_5_we         (childBd_9_we),
    .toSRAM_5_rdata      (childBd_9_rdata),
    .toSRAM_5_ack        (childBd_9_ack),
    .toSRAM_5_selectedOH (childBd_9_selectedOH),
    .toSRAM_5_array      (childBd_9_array),
    .toSRAM_6_addr       (childBd_10_addr),
    .toSRAM_6_addr_rd    (childBd_10_addr_rd),
    .toSRAM_6_wdata      (childBd_10_wdata),
    .toSRAM_6_wmask      (childBd_10_wmask),
    .toSRAM_6_re         (childBd_10_re),
    .toSRAM_6_we         (childBd_10_we),
    .toSRAM_6_rdata      (childBd_10_rdata),
    .toSRAM_6_ack        (childBd_10_ack),
    .toSRAM_6_selectedOH (childBd_10_selectedOH),
    .toSRAM_6_array      (childBd_10_array),
    .toSRAM_7_addr       (childBd_11_addr),
    .toSRAM_7_addr_rd    (childBd_11_addr_rd),
    .toSRAM_7_wdata      (childBd_11_wdata),
    .toSRAM_7_wmask      (childBd_11_wmask),
    .toSRAM_7_re         (childBd_11_re),
    .toSRAM_7_we         (childBd_11_we),
    .toSRAM_7_rdata      (childBd_11_rdata),
    .toSRAM_7_ack        (childBd_11_ack),
    .toSRAM_7_selectedOH (childBd_11_selectedOH),
    .toSRAM_7_array      (childBd_11_array)
  );
  ClockGate ClockGate (
    .TE (te_cgen),
    .E  (_s2x_info_T_1 | ~flush_dup_0 & io_refill_bits_levelOH_l0 | bd_1_req),
    .CK (clock),
    .Q  (_ClockGate_Q)
  );
  ClockGate ClockGate_1 (
    .TE (te_cgen),
    .E  (_s2x_info_T_1 | ~flush_dup_1 & io_refill_bits_levelOH_l1 | bd_req),
    .CK (clock),
    .Q  (_ClockGate_1_Q)
  );

endmodule
