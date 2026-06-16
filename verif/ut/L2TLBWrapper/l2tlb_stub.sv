// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改
// 内层 L2TLB 黑盒桩：UT 两侧共用，驱动 perf 计数以激励包装层 perf 流水。
module L2TLB(
  input  clock,
  input  reset,
  input  auto_out_a_ready,
  output auto_out_a_valid,
  output [2:0] auto_out_a_bits_source,
  output [47:0] auto_out_a_bits_address,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [2:0] auto_out_d_bits_size,
  input  [2:0] auto_out_d_bits_source,
  input  [255:0] auto_out_d_bits_data,
  output io_tlb_0_req_0_ready,
  input  io_tlb_0_req_0_valid,
  input  [37:0] io_tlb_0_req_0_bits_vpn,
  input  [1:0] io_tlb_0_req_0_bits_s2xlate,
  input  io_tlb_0_resp_ready,
  output io_tlb_0_resp_valid,
  output [1:0] io_tlb_0_resp_bits_s2xlate,
  output [34:0] io_tlb_0_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_0_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_0_resp_bits_s1_entry_vmid,
  output io_tlb_0_resp_bits_s1_entry_n,
  output [1:0] io_tlb_0_resp_bits_s1_entry_pbmt,
  output io_tlb_0_resp_bits_s1_entry_perm_d,
  output io_tlb_0_resp_bits_s1_entry_perm_a,
  output io_tlb_0_resp_bits_s1_entry_perm_g,
  output io_tlb_0_resp_bits_s1_entry_perm_u,
  output io_tlb_0_resp_bits_s1_entry_perm_x,
  output io_tlb_0_resp_bits_s1_entry_perm_w,
  output io_tlb_0_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s1_entry_level,
  output io_tlb_0_resp_bits_s1_entry_v,
  output [40:0] io_tlb_0_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_0_resp_bits_s1_addr_low,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_0_resp_bits_s1_ppn_low_7,
  output io_tlb_0_resp_bits_s1_valididx_0,
  output io_tlb_0_resp_bits_s1_valididx_1,
  output io_tlb_0_resp_bits_s1_valididx_2,
  output io_tlb_0_resp_bits_s1_valididx_3,
  output io_tlb_0_resp_bits_s1_valididx_4,
  output io_tlb_0_resp_bits_s1_valididx_5,
  output io_tlb_0_resp_bits_s1_valididx_6,
  output io_tlb_0_resp_bits_s1_valididx_7,
  output io_tlb_0_resp_bits_s1_pteidx_0,
  output io_tlb_0_resp_bits_s1_pteidx_1,
  output io_tlb_0_resp_bits_s1_pteidx_2,
  output io_tlb_0_resp_bits_s1_pteidx_3,
  output io_tlb_0_resp_bits_s1_pteidx_4,
  output io_tlb_0_resp_bits_s1_pteidx_5,
  output io_tlb_0_resp_bits_s1_pteidx_6,
  output io_tlb_0_resp_bits_s1_pteidx_7,
  output io_tlb_0_resp_bits_s1_pf,
  output io_tlb_0_resp_bits_s1_af,
  output [37:0] io_tlb_0_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_0_resp_bits_s2_entry_vmid,
  output io_tlb_0_resp_bits_s2_entry_n,
  output [1:0] io_tlb_0_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_0_resp_bits_s2_entry_ppn,
  output io_tlb_0_resp_bits_s2_entry_perm_d,
  output io_tlb_0_resp_bits_s2_entry_perm_a,
  output io_tlb_0_resp_bits_s2_entry_perm_g,
  output io_tlb_0_resp_bits_s2_entry_perm_u,
  output io_tlb_0_resp_bits_s2_entry_perm_x,
  output io_tlb_0_resp_bits_s2_entry_perm_w,
  output io_tlb_0_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_0_resp_bits_s2_entry_level,
  output io_tlb_0_resp_bits_s2_gpf,
  output io_tlb_0_resp_bits_s2_gaf,
  output io_tlb_1_req_0_ready,
  input  io_tlb_1_req_0_valid,
  input  [37:0] io_tlb_1_req_0_bits_vpn,
  input  [1:0] io_tlb_1_req_0_bits_s2xlate,
  output io_tlb_1_resp_valid,
  output [1:0] io_tlb_1_resp_bits_s2xlate,
  output [34:0] io_tlb_1_resp_bits_s1_entry_tag,
  output [15:0] io_tlb_1_resp_bits_s1_entry_asid,
  output [13:0] io_tlb_1_resp_bits_s1_entry_vmid,
  output io_tlb_1_resp_bits_s1_entry_n,
  output [1:0] io_tlb_1_resp_bits_s1_entry_pbmt,
  output io_tlb_1_resp_bits_s1_entry_perm_d,
  output io_tlb_1_resp_bits_s1_entry_perm_a,
  output io_tlb_1_resp_bits_s1_entry_perm_g,
  output io_tlb_1_resp_bits_s1_entry_perm_u,
  output io_tlb_1_resp_bits_s1_entry_perm_x,
  output io_tlb_1_resp_bits_s1_entry_perm_w,
  output io_tlb_1_resp_bits_s1_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s1_entry_level,
  output io_tlb_1_resp_bits_s1_entry_v,
  output [40:0] io_tlb_1_resp_bits_s1_entry_ppn,
  output [2:0] io_tlb_1_resp_bits_s1_addr_low,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_0,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_1,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_2,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_3,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_4,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_5,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_6,
  output [2:0] io_tlb_1_resp_bits_s1_ppn_low_7,
  output io_tlb_1_resp_bits_s1_valididx_0,
  output io_tlb_1_resp_bits_s1_valididx_1,
  output io_tlb_1_resp_bits_s1_valididx_2,
  output io_tlb_1_resp_bits_s1_valididx_3,
  output io_tlb_1_resp_bits_s1_valididx_4,
  output io_tlb_1_resp_bits_s1_valididx_5,
  output io_tlb_1_resp_bits_s1_valididx_6,
  output io_tlb_1_resp_bits_s1_valididx_7,
  output io_tlb_1_resp_bits_s1_pteidx_0,
  output io_tlb_1_resp_bits_s1_pteidx_1,
  output io_tlb_1_resp_bits_s1_pteidx_2,
  output io_tlb_1_resp_bits_s1_pteidx_3,
  output io_tlb_1_resp_bits_s1_pteidx_4,
  output io_tlb_1_resp_bits_s1_pteidx_5,
  output io_tlb_1_resp_bits_s1_pteidx_6,
  output io_tlb_1_resp_bits_s1_pteidx_7,
  output io_tlb_1_resp_bits_s1_pf,
  output io_tlb_1_resp_bits_s1_af,
  output [37:0] io_tlb_1_resp_bits_s2_entry_tag,
  output [13:0] io_tlb_1_resp_bits_s2_entry_vmid,
  output io_tlb_1_resp_bits_s2_entry_n,
  output [1:0] io_tlb_1_resp_bits_s2_entry_pbmt,
  output [37:0] io_tlb_1_resp_bits_s2_entry_ppn,
  output io_tlb_1_resp_bits_s2_entry_perm_d,
  output io_tlb_1_resp_bits_s2_entry_perm_a,
  output io_tlb_1_resp_bits_s2_entry_perm_g,
  output io_tlb_1_resp_bits_s2_entry_perm_u,
  output io_tlb_1_resp_bits_s2_entry_perm_x,
  output io_tlb_1_resp_bits_s2_entry_perm_w,
  output io_tlb_1_resp_bits_s2_entry_perm_r,
  output [1:0] io_tlb_1_resp_bits_s2_entry_level,
  output io_tlb_1_resp_bits_s2_gpf,
  output io_tlb_1_resp_bits_s2_gaf,
  input  io_sfence_valid,
  input  io_sfence_bits_rs1,
  input  io_sfence_bits_rs2,
  input  [49:0] io_sfence_bits_addr,
  input  [15:0] io_sfence_bits_id,
  input  io_sfence_bits_hv,
  input  io_sfence_bits_hg,
  input  io_wfi_wfiReq,
  output io_wfi_wfiSafe,
  input  [3:0] io_csr_tlb_satp_mode,
  input  [15:0] io_csr_tlb_satp_asid,
  input  [43:0] io_csr_tlb_satp_ppn,
  input  io_csr_tlb_satp_changed,
  input  [3:0] io_csr_tlb_vsatp_mode,
  input  [15:0] io_csr_tlb_vsatp_asid,
  input  [43:0] io_csr_tlb_vsatp_ppn,
  input  io_csr_tlb_vsatp_changed,
  input  [3:0] io_csr_tlb_hgatp_mode,
  input  [15:0] io_csr_tlb_hgatp_vmid,
  input  [43:0] io_csr_tlb_hgatp_ppn,
  input  io_csr_tlb_hgatp_changed,
  input  io_csr_tlb_priv_mxr,
  input  io_csr_tlb_priv_virt,
  input  io_csr_tlb_mPBMTE,
  input  io_csr_tlb_hPBMTE,
  input  io_csr_distribute_csr_w_valid,
  input  [11:0] io_csr_distribute_csr_w_bits_addr,
  input  [63:0] io_csr_distribute_csr_w_bits_data,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  input  [5:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [1:0] boreChildrenBd_bore_be,
  input  [3:0] boreChildrenBd_bore_addr,
  input  [199:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [3:0] boreChildrenBd_bore_addr_rd,
  output [199:0] boreChildrenBd_bore_outdata,
  input  [5:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [1:0] boreChildrenBd_bore_1_be,
  input  [5:0] boreChildrenBd_bore_1_addr,
  input  [227:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [5:0] boreChildrenBd_bore_1_addr_rd,
  output [227:0] boreChildrenBd_bore_1_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  cg_bore_cgen
);
  // 简易 perf 计数源：逐拍自增 + 输入扰动，保证非 X 且确定。
  reg [5:0] perf_ctr;
  always @(posedge clock) begin
    if (reset) perf_ctr <= 6'd0;
    else       perf_ctr <= perf_ctr + 6'd1;
  end
  assign auto_out_a_valid = 1'b0;
  assign auto_out_a_bits_source = 3'd0;
  assign auto_out_a_bits_address = 48'd0;
  assign io_tlb_0_req_0_ready = 1'b0;
  assign io_tlb_0_resp_valid = 1'b0;
  assign io_tlb_0_resp_bits_s2xlate = 2'd0;
  assign io_tlb_0_resp_bits_s1_entry_tag = 35'd0;
  assign io_tlb_0_resp_bits_s1_entry_asid = 16'd0;
  assign io_tlb_0_resp_bits_s1_entry_vmid = 14'd0;
  assign io_tlb_0_resp_bits_s1_entry_n = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_pbmt = 2'd0;
  assign io_tlb_0_resp_bits_s1_entry_perm_d = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_a = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_g = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_u = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_x = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_w = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_perm_r = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_level = 2'd0;
  assign io_tlb_0_resp_bits_s1_entry_v = 1'b0;
  assign io_tlb_0_resp_bits_s1_entry_ppn = 41'd0;
  assign io_tlb_0_resp_bits_s1_addr_low = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_0 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_1 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_2 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_3 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_4 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_5 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_6 = 3'd0;
  assign io_tlb_0_resp_bits_s1_ppn_low_7 = 3'd0;
  assign io_tlb_0_resp_bits_s1_valididx_0 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_1 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_2 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_3 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_4 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_5 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_6 = 1'b0;
  assign io_tlb_0_resp_bits_s1_valididx_7 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_0 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_1 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_2 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_3 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_4 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_5 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_6 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pteidx_7 = 1'b0;
  assign io_tlb_0_resp_bits_s1_pf = 1'b0;
  assign io_tlb_0_resp_bits_s1_af = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_tag = 38'd0;
  assign io_tlb_0_resp_bits_s2_entry_vmid = 14'd0;
  assign io_tlb_0_resp_bits_s2_entry_n = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_pbmt = 2'd0;
  assign io_tlb_0_resp_bits_s2_entry_ppn = 38'd0;
  assign io_tlb_0_resp_bits_s2_entry_perm_d = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_a = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_g = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_u = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_x = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_w = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_perm_r = 1'b0;
  assign io_tlb_0_resp_bits_s2_entry_level = 2'd0;
  assign io_tlb_0_resp_bits_s2_gpf = 1'b0;
  assign io_tlb_0_resp_bits_s2_gaf = 1'b0;
  assign io_tlb_1_req_0_ready = 1'b0;
  assign io_tlb_1_resp_valid = 1'b0;
  assign io_tlb_1_resp_bits_s2xlate = 2'd0;
  assign io_tlb_1_resp_bits_s1_entry_tag = 35'd0;
  assign io_tlb_1_resp_bits_s1_entry_asid = 16'd0;
  assign io_tlb_1_resp_bits_s1_entry_vmid = 14'd0;
  assign io_tlb_1_resp_bits_s1_entry_n = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_pbmt = 2'd0;
  assign io_tlb_1_resp_bits_s1_entry_perm_d = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_a = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_g = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_u = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_x = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_w = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_perm_r = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_level = 2'd0;
  assign io_tlb_1_resp_bits_s1_entry_v = 1'b0;
  assign io_tlb_1_resp_bits_s1_entry_ppn = 41'd0;
  assign io_tlb_1_resp_bits_s1_addr_low = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_0 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_1 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_2 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_3 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_4 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_5 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_6 = 3'd0;
  assign io_tlb_1_resp_bits_s1_ppn_low_7 = 3'd0;
  assign io_tlb_1_resp_bits_s1_valididx_0 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_1 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_2 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_3 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_4 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_5 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_6 = 1'b0;
  assign io_tlb_1_resp_bits_s1_valididx_7 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_0 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_1 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_2 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_3 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_4 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_5 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_6 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pteidx_7 = 1'b0;
  assign io_tlb_1_resp_bits_s1_pf = 1'b0;
  assign io_tlb_1_resp_bits_s1_af = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_tag = 38'd0;
  assign io_tlb_1_resp_bits_s2_entry_vmid = 14'd0;
  assign io_tlb_1_resp_bits_s2_entry_n = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_pbmt = 2'd0;
  assign io_tlb_1_resp_bits_s2_entry_ppn = 38'd0;
  assign io_tlb_1_resp_bits_s2_entry_perm_d = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_a = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_g = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_u = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_x = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_w = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_perm_r = 1'b0;
  assign io_tlb_1_resp_bits_s2_entry_level = 2'd0;
  assign io_tlb_1_resp_bits_s2_gpf = 1'b0;
  assign io_tlb_1_resp_bits_s2_gaf = 1'b0;
  assign io_wfi_wfiSafe = 1'b0;
  assign io_perf_0_value = perf_ctr + 6'd0 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_1_value = perf_ctr + 6'd1 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_2_value = perf_ctr + 6'd2 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_3_value = perf_ctr + 6'd3 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_4_value = perf_ctr + 6'd4 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_5_value = perf_ctr + 6'd5 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_6_value = perf_ctr + 6'd6 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_7_value = perf_ctr + 6'd7 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_8_value = perf_ctr + 6'd8 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_9_value = perf_ctr + 6'd9 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_10_value = perf_ctr + 6'd10 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_11_value = perf_ctr + 6'd11 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_12_value = perf_ctr + 6'd12 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_13_value = perf_ctr + 6'd13 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_14_value = perf_ctr + 6'd14 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_15_value = perf_ctr + 6'd15 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_16_value = perf_ctr + 6'd16 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_17_value = perf_ctr + 6'd17 ^ {5'd0, io_tlb_0_req_0_valid};
  assign io_perf_18_value = perf_ctr + 6'd18 ^ {5'd0, io_tlb_0_req_0_valid};
  assign boreChildrenBd_bore_ack = 1'b0;
  assign boreChildrenBd_bore_outdata = 200'd0;
  assign boreChildrenBd_bore_1_ack = 1'b0;
  assign boreChildrenBd_bore_1_outdata = 228'd0;
endmodule
