`timescale 1ns/1ps
// Differential UT for Pipeline200c: golden (g_*) vs rewritten (x_*, *_xs) side by side, same random inputs.
// Takeover changes (agent/next200c-takeover):
//   * warm-up phase after the first reset writes every non-reset register (OverrideableQueue entries,
//     PipelineRegModule_6 payload, SatpFlushMod snapshot) before comparing, so +vcs+initreg+random /
//     +vcs+initreg+<n> runs do not compare per-instance random power-up values;
//   * random mid-run reset pulses on the async-reset modules (reset is held while inputs keep toggling,
//     so a payload register wrongly placed in the reset always-block is caught);
//   * Arbiter16 valids are made sparse on 1/4 of the cycles so the low-priority / fallback lanes win;
//   * outputs compared twice per cycle (after the negedge input change, and after the posedge), so a
//     synchronous reset where golden is asynchronous is visible;
//   * coverage counters; every counter must be non-zero or the test fails.
module tb;
  parameter integer NCYCLES = 200000;
  logic clock = 1'b0;
  integer errors = 0;
  integer checks = 0;
  integer cycle = 0;
  integer rst_left = 0;
  integer cov_rst_pulses = 0;
  integer cov_preg_fire_in_reset = 0;
  integer cov_preg_stall = 0;
  integer cov_oq_overwrite = 0;
  integer cov_oq_same_slot_rw = 0;
  integer cov_oq1_overwrite = 0;
  integer cov_oq1_deq = 0;
  integer cov_a16_win15 = 0;
  integer cov_a16_idle = 0;
  integer cov_pfgen_lane2 = 0;
  integer cov_pfreq_idle = 0;
  integer cov_hint_lane3 = 0;
  integer cov_satp_wen = 0;
  always #5 clock = ~clock;

  wire Arbiter16_TLBundleD_g_io_in_0_ready;
  wire Arbiter16_TLBundleD_x_io_in_0_ready;
  logic Arbiter16_TLBundleD_io_in_0_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_0_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_0_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_0_bits_source;
  logic Arbiter16_TLBundleD_io_in_0_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_0_bits_data;
  logic Arbiter16_TLBundleD_io_in_0_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_1_ready;
  wire Arbiter16_TLBundleD_x_io_in_1_ready;
  logic Arbiter16_TLBundleD_io_in_1_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_1_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_1_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_1_bits_source;
  logic Arbiter16_TLBundleD_io_in_1_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_1_bits_data;
  logic Arbiter16_TLBundleD_io_in_1_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_2_ready;
  wire Arbiter16_TLBundleD_x_io_in_2_ready;
  logic Arbiter16_TLBundleD_io_in_2_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_2_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_2_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_2_bits_source;
  logic Arbiter16_TLBundleD_io_in_2_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_2_bits_data;
  logic Arbiter16_TLBundleD_io_in_2_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_3_ready;
  wire Arbiter16_TLBundleD_x_io_in_3_ready;
  logic Arbiter16_TLBundleD_io_in_3_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_3_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_3_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_3_bits_source;
  logic Arbiter16_TLBundleD_io_in_3_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_3_bits_data;
  logic Arbiter16_TLBundleD_io_in_3_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_4_ready;
  wire Arbiter16_TLBundleD_x_io_in_4_ready;
  logic Arbiter16_TLBundleD_io_in_4_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_4_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_4_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_4_bits_source;
  logic Arbiter16_TLBundleD_io_in_4_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_4_bits_data;
  logic Arbiter16_TLBundleD_io_in_4_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_5_ready;
  wire Arbiter16_TLBundleD_x_io_in_5_ready;
  logic Arbiter16_TLBundleD_io_in_5_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_5_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_5_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_5_bits_source;
  logic Arbiter16_TLBundleD_io_in_5_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_5_bits_data;
  logic Arbiter16_TLBundleD_io_in_5_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_6_ready;
  wire Arbiter16_TLBundleD_x_io_in_6_ready;
  logic Arbiter16_TLBundleD_io_in_6_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_6_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_6_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_6_bits_source;
  logic Arbiter16_TLBundleD_io_in_6_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_6_bits_data;
  logic Arbiter16_TLBundleD_io_in_6_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_7_ready;
  wire Arbiter16_TLBundleD_x_io_in_7_ready;
  logic Arbiter16_TLBundleD_io_in_7_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_7_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_7_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_7_bits_source;
  logic Arbiter16_TLBundleD_io_in_7_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_7_bits_data;
  logic Arbiter16_TLBundleD_io_in_7_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_8_ready;
  wire Arbiter16_TLBundleD_x_io_in_8_ready;
  logic Arbiter16_TLBundleD_io_in_8_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_8_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_8_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_8_bits_source;
  logic Arbiter16_TLBundleD_io_in_8_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_8_bits_data;
  logic Arbiter16_TLBundleD_io_in_8_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_9_ready;
  wire Arbiter16_TLBundleD_x_io_in_9_ready;
  logic Arbiter16_TLBundleD_io_in_9_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_9_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_9_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_9_bits_source;
  logic Arbiter16_TLBundleD_io_in_9_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_9_bits_data;
  logic Arbiter16_TLBundleD_io_in_9_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_10_ready;
  wire Arbiter16_TLBundleD_x_io_in_10_ready;
  logic Arbiter16_TLBundleD_io_in_10_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_10_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_10_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_10_bits_source;
  logic Arbiter16_TLBundleD_io_in_10_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_10_bits_data;
  logic Arbiter16_TLBundleD_io_in_10_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_11_ready;
  wire Arbiter16_TLBundleD_x_io_in_11_ready;
  logic Arbiter16_TLBundleD_io_in_11_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_11_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_11_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_11_bits_source;
  logic Arbiter16_TLBundleD_io_in_11_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_11_bits_data;
  logic Arbiter16_TLBundleD_io_in_11_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_12_ready;
  wire Arbiter16_TLBundleD_x_io_in_12_ready;
  logic Arbiter16_TLBundleD_io_in_12_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_12_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_12_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_12_bits_source;
  logic Arbiter16_TLBundleD_io_in_12_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_12_bits_data;
  logic Arbiter16_TLBundleD_io_in_12_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_13_ready;
  wire Arbiter16_TLBundleD_x_io_in_13_ready;
  logic Arbiter16_TLBundleD_io_in_13_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_13_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_13_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_13_bits_source;
  logic Arbiter16_TLBundleD_io_in_13_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_13_bits_data;
  logic Arbiter16_TLBundleD_io_in_13_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_14_ready;
  wire Arbiter16_TLBundleD_x_io_in_14_ready;
  logic Arbiter16_TLBundleD_io_in_14_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_14_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_14_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_14_bits_source;
  logic Arbiter16_TLBundleD_io_in_14_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_14_bits_data;
  logic Arbiter16_TLBundleD_io_in_14_bits_corrupt;
  wire Arbiter16_TLBundleD_g_io_in_15_ready;
  wire Arbiter16_TLBundleD_x_io_in_15_ready;
  logic Arbiter16_TLBundleD_io_in_15_valid;
  logic [3:0] Arbiter16_TLBundleD_io_in_15_bits_opcode;
  logic [1:0] Arbiter16_TLBundleD_io_in_15_bits_size;
  logic [4:0] Arbiter16_TLBundleD_io_in_15_bits_source;
  logic Arbiter16_TLBundleD_io_in_15_bits_denied;
  logic [63:0] Arbiter16_TLBundleD_io_in_15_bits_data;
  logic Arbiter16_TLBundleD_io_in_15_bits_corrupt;
  logic Arbiter16_TLBundleD_io_out_ready;
  wire Arbiter16_TLBundleD_g_io_out_valid;
  wire Arbiter16_TLBundleD_x_io_out_valid;
  wire [3:0] Arbiter16_TLBundleD_g_io_out_bits_opcode;
  wire [3:0] Arbiter16_TLBundleD_x_io_out_bits_opcode;
  wire [1:0] Arbiter16_TLBundleD_g_io_out_bits_size;
  wire [1:0] Arbiter16_TLBundleD_x_io_out_bits_size;
  wire [4:0] Arbiter16_TLBundleD_g_io_out_bits_source;
  wire [4:0] Arbiter16_TLBundleD_x_io_out_bits_source;
  wire Arbiter16_TLBundleD_g_io_out_bits_denied;
  wire Arbiter16_TLBundleD_x_io_out_bits_denied;
  wire [63:0] Arbiter16_TLBundleD_g_io_out_bits_data;
  wire [63:0] Arbiter16_TLBundleD_x_io_out_bits_data;
  wire Arbiter16_TLBundleD_g_io_out_bits_corrupt;
  wire Arbiter16_TLBundleD_x_io_out_bits_corrupt;

  logic Arbiter3_PfGenReq_io_in_0_valid;
  logic [10:0] Arbiter3_PfGenReq_io_in_0_bits_region_tag;
  logic [39:0] Arbiter3_PfGenReq_io_in_0_bits_region_addr;
  logic [15:0] Arbiter3_PfGenReq_io_in_0_bits_region_bits;
  wire Arbiter3_PfGenReq_g_io_in_1_ready;
  wire Arbiter3_PfGenReq_x_io_in_1_ready;
  logic Arbiter3_PfGenReq_io_in_1_valid;
  logic [10:0] Arbiter3_PfGenReq_io_in_1_bits_region_tag;
  logic [39:0] Arbiter3_PfGenReq_io_in_1_bits_region_addr;
  logic [15:0] Arbiter3_PfGenReq_io_in_1_bits_region_bits;
  logic Arbiter3_PfGenReq_io_in_1_bits_paddr_valid;
  wire Arbiter3_PfGenReq_g_io_in_2_ready;
  wire Arbiter3_PfGenReq_x_io_in_2_ready;
  logic Arbiter3_PfGenReq_io_in_2_valid;
  logic [10:0] Arbiter3_PfGenReq_io_in_2_bits_region_tag;
  logic [39:0] Arbiter3_PfGenReq_io_in_2_bits_region_addr;
  logic [15:0] Arbiter3_PfGenReq_io_in_2_bits_region_bits;
  logic Arbiter3_PfGenReq_io_in_2_bits_paddr_valid;
  wire Arbiter3_PfGenReq_g_io_out_valid;
  wire Arbiter3_PfGenReq_x_io_out_valid;
  wire [10:0] Arbiter3_PfGenReq_g_io_out_bits_region_tag;
  wire [10:0] Arbiter3_PfGenReq_x_io_out_bits_region_tag;
  wire [39:0] Arbiter3_PfGenReq_g_io_out_bits_region_addr;
  wire [39:0] Arbiter3_PfGenReq_x_io_out_bits_region_addr;
  wire [15:0] Arbiter3_PfGenReq_g_io_out_bits_region_bits;
  wire [15:0] Arbiter3_PfGenReq_x_io_out_bits_region_bits;
  wire Arbiter3_PfGenReq_g_io_out_bits_paddr_valid;
  wire Arbiter3_PfGenReq_x_io_out_bits_paddr_valid;
  wire Arbiter3_PfGenReq_g_io_out_bits_decr_mode;
  wire Arbiter3_PfGenReq_x_io_out_bits_decr_mode;

  wire Arbiter4_L2ToL1Hint_g_io_in_0_ready;
  wire Arbiter4_L2ToL1Hint_x_io_in_0_ready;
  logic Arbiter4_L2ToL1Hint_io_in_0_valid;
  logic [31:0] Arbiter4_L2ToL1Hint_io_in_0_bits_sourceId;
  logic Arbiter4_L2ToL1Hint_io_in_0_bits_isKeyword;
  wire Arbiter4_L2ToL1Hint_g_io_in_1_ready;
  wire Arbiter4_L2ToL1Hint_x_io_in_1_ready;
  logic Arbiter4_L2ToL1Hint_io_in_1_valid;
  logic [31:0] Arbiter4_L2ToL1Hint_io_in_1_bits_sourceId;
  logic Arbiter4_L2ToL1Hint_io_in_1_bits_isKeyword;
  wire Arbiter4_L2ToL1Hint_g_io_in_2_ready;
  wire Arbiter4_L2ToL1Hint_x_io_in_2_ready;
  logic Arbiter4_L2ToL1Hint_io_in_2_valid;
  logic [31:0] Arbiter4_L2ToL1Hint_io_in_2_bits_sourceId;
  logic Arbiter4_L2ToL1Hint_io_in_2_bits_isKeyword;
  wire Arbiter4_L2ToL1Hint_g_io_in_3_ready;
  wire Arbiter4_L2ToL1Hint_x_io_in_3_ready;
  logic Arbiter4_L2ToL1Hint_io_in_3_valid;
  logic [31:0] Arbiter4_L2ToL1Hint_io_in_3_bits_sourceId;
  logic Arbiter4_L2ToL1Hint_io_in_3_bits_isKeyword;
  logic Arbiter4_L2ToL1Hint_io_out_ready;
  wire Arbiter4_L2ToL1Hint_g_io_out_valid;
  wire Arbiter4_L2ToL1Hint_x_io_out_valid;
  wire [31:0] Arbiter4_L2ToL1Hint_g_io_out_bits_sourceId;
  wire [31:0] Arbiter4_L2ToL1Hint_x_io_out_bits_sourceId;
  wire Arbiter4_L2ToL1Hint_g_io_out_bits_isKeyword;
  wire Arbiter4_L2ToL1Hint_x_io_out_bits_isKeyword;
  wire [1:0] Arbiter4_L2ToL1Hint_g_io_chosen;
  wire [1:0] Arbiter4_L2ToL1Hint_x_io_chosen;

  logic Arbiter4_PrefetchReq_io_in_0_valid;
  logic [32:0] Arbiter4_PrefetchReq_io_in_0_bits_tag;
  logic [8:0] Arbiter4_PrefetchReq_io_in_0_bits_set;
  logic [4:0] Arbiter4_PrefetchReq_io_in_0_bits_pfSource;
  wire Arbiter4_PrefetchReq_g_io_in_1_ready;
  wire Arbiter4_PrefetchReq_x_io_in_1_ready;
  logic Arbiter4_PrefetchReq_io_in_1_valid;
  logic [32:0] Arbiter4_PrefetchReq_io_in_1_bits_tag;
  logic [8:0] Arbiter4_PrefetchReq_io_in_1_bits_set;
  logic [43:0] Arbiter4_PrefetchReq_io_in_1_bits_vaddr;
  logic Arbiter4_PrefetchReq_io_in_1_bits_needT;
  logic [6:0] Arbiter4_PrefetchReq_io_in_1_bits_source;
  wire Arbiter4_PrefetchReq_g_io_in_2_ready;
  wire Arbiter4_PrefetchReq_x_io_in_2_ready;
  logic Arbiter4_PrefetchReq_io_in_2_valid;
  logic [32:0] Arbiter4_PrefetchReq_io_in_2_bits_tag;
  logic [8:0] Arbiter4_PrefetchReq_io_in_2_bits_set;
  logic [43:0] Arbiter4_PrefetchReq_io_in_2_bits_vaddr;
  logic Arbiter4_PrefetchReq_io_in_2_bits_needT;
  logic [6:0] Arbiter4_PrefetchReq_io_in_2_bits_source;
  wire Arbiter4_PrefetchReq_g_io_out_valid;
  wire Arbiter4_PrefetchReq_x_io_out_valid;
  wire [32:0] Arbiter4_PrefetchReq_g_io_out_bits_tag;
  wire [32:0] Arbiter4_PrefetchReq_x_io_out_bits_tag;
  wire [8:0] Arbiter4_PrefetchReq_g_io_out_bits_set;
  wire [8:0] Arbiter4_PrefetchReq_x_io_out_bits_set;
  wire [43:0] Arbiter4_PrefetchReq_g_io_out_bits_vaddr;
  wire [43:0] Arbiter4_PrefetchReq_x_io_out_bits_vaddr;
  wire Arbiter4_PrefetchReq_g_io_out_bits_needT;
  wire Arbiter4_PrefetchReq_x_io_out_bits_needT;
  wire [6:0] Arbiter4_PrefetchReq_g_io_out_bits_source;
  wire [6:0] Arbiter4_PrefetchReq_x_io_out_bits_source;
  wire [4:0] Arbiter4_PrefetchReq_g_io_out_bits_pfSource;
  wire [4:0] Arbiter4_PrefetchReq_x_io_out_bits_pfSource;

  logic [15:0] CSA4to2_15_io_in_a;
  logic [15:0] CSA4to2_15_io_in_b;
  logic [15:0] CSA4to2_15_io_in_c;
  logic [15:0] CSA4to2_15_io_in_d;
  wire [15:0] CSA4to2_15_g_io_out_sum;
  wire [15:0] CSA4to2_15_x_io_out_sum;
  wire [15:0] CSA4to2_15_g_io_out_car;
  wire [15:0] CSA4to2_15_x_io_out_car;

  wire [6:0] MbistIntfFrontend_g_toPipeline_0_array;
  wire [6:0] MbistIntfFrontend_x_toPipeline_0_array;
  wire MbistIntfFrontend_g_toPipeline_0_all;
  wire MbistIntfFrontend_x_toPipeline_0_all;
  wire MbistIntfFrontend_g_toPipeline_0_req;
  wire MbistIntfFrontend_x_toPipeline_0_req;
  logic MbistIntfFrontend_toPipeline_0_ack;
  wire MbistIntfFrontend_g_toPipeline_0_writeen;
  wire MbistIntfFrontend_x_toPipeline_0_writeen;
  wire [75:0] MbistIntfFrontend_g_toPipeline_0_be;
  wire [75:0] MbistIntfFrontend_x_toPipeline_0_be;
  wire [9:0] MbistIntfFrontend_g_toPipeline_0_addr;
  wire [9:0] MbistIntfFrontend_x_toPipeline_0_addr;
  wire [75:0] MbistIntfFrontend_g_toPipeline_0_indata;
  wire [75:0] MbistIntfFrontend_x_toPipeline_0_indata;
  wire MbistIntfFrontend_g_toPipeline_0_readen;
  wire MbistIntfFrontend_x_toPipeline_0_readen;
  wire [9:0] MbistIntfFrontend_g_toPipeline_0_addr_rd;
  wire [9:0] MbistIntfFrontend_x_toPipeline_0_addr_rd;
  logic [75:0] MbistIntfFrontend_toPipeline_0_outdata;
  logic [6:0] MbistIntfFrontend_mbist_array;
  logic MbistIntfFrontend_mbist_all;
  logic MbistIntfFrontend_mbist_req;
  wire MbistIntfFrontend_g_mbist_ack;
  wire MbistIntfFrontend_x_mbist_ack;
  logic MbistIntfFrontend_mbist_writeen;
  logic [75:0] MbistIntfFrontend_mbist_be;
  logic [9:0] MbistIntfFrontend_mbist_addr;
  logic [75:0] MbistIntfFrontend_mbist_indata;
  logic MbistIntfFrontend_mbist_readen;
  logic [9:0] MbistIntfFrontend_mbist_addr_rd;
  wire [75:0] MbistIntfFrontend_g_mbist_outdata;
  wire [75:0] MbistIntfFrontend_x_mbist_outdata;

  wire [6:0] MbistIntfMemBlk_g_toPipeline_0_array;
  wire [6:0] MbistIntfMemBlk_x_toPipeline_0_array;
  wire MbistIntfMemBlk_g_toPipeline_0_all;
  wire MbistIntfMemBlk_x_toPipeline_0_all;
  wire MbistIntfMemBlk_g_toPipeline_0_req;
  wire MbistIntfMemBlk_x_toPipeline_0_req;
  logic MbistIntfMemBlk_toPipeline_0_ack;
  wire MbistIntfMemBlk_g_toPipeline_0_writeen;
  wire MbistIntfMemBlk_x_toPipeline_0_writeen;
  wire [1:0] MbistIntfMemBlk_g_toPipeline_0_be;
  wire [1:0] MbistIntfMemBlk_x_toPipeline_0_be;
  wire [8:0] MbistIntfMemBlk_g_toPipeline_0_addr;
  wire [8:0] MbistIntfMemBlk_x_toPipeline_0_addr;
  wire [147:0] MbistIntfMemBlk_g_toPipeline_0_indata;
  wire [147:0] MbistIntfMemBlk_x_toPipeline_0_indata;
  wire MbistIntfMemBlk_g_toPipeline_0_readen;
  wire MbistIntfMemBlk_x_toPipeline_0_readen;
  wire [8:0] MbistIntfMemBlk_g_toPipeline_0_addr_rd;
  wire [8:0] MbistIntfMemBlk_x_toPipeline_0_addr_rd;
  logic [147:0] MbistIntfMemBlk_toPipeline_0_outdata;
  logic [6:0] MbistIntfMemBlk_mbist_array;
  logic MbistIntfMemBlk_mbist_all;
  logic MbistIntfMemBlk_mbist_req;
  wire MbistIntfMemBlk_g_mbist_ack;
  wire MbistIntfMemBlk_x_mbist_ack;
  logic MbistIntfMemBlk_mbist_writeen;
  logic [1:0] MbistIntfMemBlk_mbist_be;
  logic [8:0] MbistIntfMemBlk_mbist_addr;
  logic [147:0] MbistIntfMemBlk_mbist_indata;
  logic MbistIntfMemBlk_mbist_readen;
  logic [8:0] MbistIntfMemBlk_mbist_addr_rd;
  wire [147:0] MbistIntfMemBlk_g_mbist_outdata;
  wire [147:0] MbistIntfMemBlk_x_mbist_outdata;

  logic [2:0] NfMappedElemIdx_in_nf;
  logic [3:0] NfMappedElemIdx_in_eewOH;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_0_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_0_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_0_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_0_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_1_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_1_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_1_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_1_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_2_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_2_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_2_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_2_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_3_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_3_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_3_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_3_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_4_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_4_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_4_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_4_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_5_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_5_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_5_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_5_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_6_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_6_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_6_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_6_until;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_7_from;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_7_from;
  wire [7:0] NfMappedElemIdx_g_out_idxRangeVec_7_until;
  wire [7:0] NfMappedElemIdx_x_out_idxRangeVec_7_until;

  logic OverrideableQueue_reset;
  logic OverrideableQueue_io_in_valid;
  logic [4:0] OverrideableQueue_io_in_bits_pht_index;
  logic [12:0] OverrideableQueue_io_in_bits_pht_tag;
  logic [39:0] OverrideableQueue_io_in_bits_region_paddr;
  logic [39:0] OverrideableQueue_io_in_bits_region_vaddr;
  logic [3:0] OverrideableQueue_io_in_bits_region_offset;
  logic OverrideableQueue_io_out_ready;
  wire OverrideableQueue_g_io_out_valid;
  wire OverrideableQueue_x_io_out_valid;
  wire [4:0] OverrideableQueue_g_io_out_bits_pht_index;
  wire [4:0] OverrideableQueue_x_io_out_bits_pht_index;
  wire [12:0] OverrideableQueue_g_io_out_bits_pht_tag;
  wire [12:0] OverrideableQueue_x_io_out_bits_pht_tag;
  wire [39:0] OverrideableQueue_g_io_out_bits_region_paddr;
  wire [39:0] OverrideableQueue_x_io_out_bits_region_paddr;
  wire [39:0] OverrideableQueue_g_io_out_bits_region_vaddr;
  wire [39:0] OverrideableQueue_x_io_out_bits_region_vaddr;
  wire [3:0] OverrideableQueue_g_io_out_bits_region_offset;
  wire [3:0] OverrideableQueue_x_io_out_bits_region_offset;

  logic OverrideableQueue_1_reset;
  logic OverrideableQueue_1_io_in_valid;
  logic [4:0] OverrideableQueue_1_io_in_bits_pht_index;
  logic [12:0] OverrideableQueue_1_io_in_bits_pht_tag;
  logic [15:0] OverrideableQueue_1_io_in_bits_region_bits;
  logic [15:0] OverrideableQueue_1_io_in_bits_region_bit_single;
  logic [3:0] OverrideableQueue_1_io_in_bits_region_offset;
  logic [3:0] OverrideableQueue_1_io_in_bits_access_cnt;
  logic OverrideableQueue_1_io_in_bits_decr_mode;
  logic OverrideableQueue_1_io_in_bits_single_update;
  logic OverrideableQueue_1_io_in_bits_has_been_signal_updated;
  logic OverrideableQueue_1_io_out_ready;
  wire OverrideableQueue_1_g_io_out_valid;
  wire OverrideableQueue_1_x_io_out_valid;
  wire [4:0] OverrideableQueue_1_g_io_out_bits_pht_index;
  wire [4:0] OverrideableQueue_1_x_io_out_bits_pht_index;
  wire [12:0] OverrideableQueue_1_g_io_out_bits_pht_tag;
  wire [12:0] OverrideableQueue_1_x_io_out_bits_pht_tag;
  wire [15:0] OverrideableQueue_1_g_io_out_bits_region_bits;
  wire [15:0] OverrideableQueue_1_x_io_out_bits_region_bits;
  wire [15:0] OverrideableQueue_1_g_io_out_bits_region_bit_single;
  wire [15:0] OverrideableQueue_1_x_io_out_bits_region_bit_single;
  wire [3:0] OverrideableQueue_1_g_io_out_bits_region_offset;
  wire [3:0] OverrideableQueue_1_x_io_out_bits_region_offset;
  wire [3:0] OverrideableQueue_1_g_io_out_bits_access_cnt;
  wire [3:0] OverrideableQueue_1_x_io_out_bits_access_cnt;
  wire OverrideableQueue_1_g_io_out_bits_decr_mode;
  wire OverrideableQueue_1_x_io_out_bits_decr_mode;
  wire OverrideableQueue_1_g_io_out_bits_single_update;
  wire OverrideableQueue_1_x_io_out_bits_single_update;
  wire OverrideableQueue_1_g_io_out_bits_has_been_signal_updated;
  wire OverrideableQueue_1_x_io_out_bits_has_been_signal_updated;

  logic PipelineRegModule_6_reset;
  wire PipelineRegModule_6_g_io_in_ready;
  wire PipelineRegModule_6_x_io_in_ready;
  logic PipelineRegModule_6_io_in_valid;
  logic [63:0] PipelineRegModule_6_io_in_bits_data;
  logic [3:0] PipelineRegModule_6_io_in_bits_id;
  logic PipelineRegModule_6_io_in_bits_nc;
  logic PipelineRegModule_6_io_in_bits_is2lq;
  logic PipelineRegModule_6_io_in_bits_denied;
  logic PipelineRegModule_6_io_in_bits_corrupt;
  logic PipelineRegModule_6_io_out_ready;
  wire PipelineRegModule_6_g_io_out_valid;
  wire PipelineRegModule_6_x_io_out_valid;
  wire [63:0] PipelineRegModule_6_g_io_out_bits_data;
  wire [63:0] PipelineRegModule_6_x_io_out_bits_data;
  wire [3:0] PipelineRegModule_6_g_io_out_bits_id;
  wire [3:0] PipelineRegModule_6_x_io_out_bits_id;
  wire PipelineRegModule_6_g_io_out_bits_nc;
  wire PipelineRegModule_6_x_io_out_bits_nc;
  wire PipelineRegModule_6_g_io_out_bits_is2lq;
  wire PipelineRegModule_6_x_io_out_bits_is2lq;
  wire PipelineRegModule_6_g_io_out_bits_denied;
  wire PipelineRegModule_6_x_io_out_bits_denied;
  wire PipelineRegModule_6_g_io_out_bits_corrupt;
  wire PipelineRegModule_6_x_io_out_bits_corrupt;

  logic SatpFlushMod_in_satp_valid;
  logic [3:0] SatpFlushMod_in_satp_bits;
  logic SatpFlushMod_in_vsatp_valid;
  logic [3:0] SatpFlushMod_in_vsatp_bits;
  logic [1:0] SatpFlushMod_in_privState_PRVM;
  logic SatpFlushMod_in_privState_V;
  wire [1:0] SatpFlushMod_g_out_oldPrivState_PRVM;
  wire [1:0] SatpFlushMod_x_out_oldPrivState_PRVM;
  wire SatpFlushMod_g_out_oldPrivState_V;
  wire SatpFlushMod_x_out_oldPrivState_V;
  wire [3:0] SatpFlushMod_g_out_oldSatpMode;
  wire [3:0] SatpFlushMod_x_out_oldSatpMode;
  wire [3:0] SatpFlushMod_g_out_oldVsatpMode;
  wire [3:0] SatpFlushMod_x_out_oldVsatpMode;

  Arbiter16_TLBundleD g_Arbiter16_TLBundleD (
    .io_in_0_ready(Arbiter16_TLBundleD_g_io_in_0_ready),
    .io_in_0_valid(Arbiter16_TLBundleD_io_in_0_valid),
    .io_in_0_bits_opcode(Arbiter16_TLBundleD_io_in_0_bits_opcode),
    .io_in_0_bits_size(Arbiter16_TLBundleD_io_in_0_bits_size),
    .io_in_0_bits_source(Arbiter16_TLBundleD_io_in_0_bits_source),
    .io_in_0_bits_denied(Arbiter16_TLBundleD_io_in_0_bits_denied),
    .io_in_0_bits_data(Arbiter16_TLBundleD_io_in_0_bits_data),
    .io_in_0_bits_corrupt(Arbiter16_TLBundleD_io_in_0_bits_corrupt),
    .io_in_1_ready(Arbiter16_TLBundleD_g_io_in_1_ready),
    .io_in_1_valid(Arbiter16_TLBundleD_io_in_1_valid),
    .io_in_1_bits_opcode(Arbiter16_TLBundleD_io_in_1_bits_opcode),
    .io_in_1_bits_size(Arbiter16_TLBundleD_io_in_1_bits_size),
    .io_in_1_bits_source(Arbiter16_TLBundleD_io_in_1_bits_source),
    .io_in_1_bits_denied(Arbiter16_TLBundleD_io_in_1_bits_denied),
    .io_in_1_bits_data(Arbiter16_TLBundleD_io_in_1_bits_data),
    .io_in_1_bits_corrupt(Arbiter16_TLBundleD_io_in_1_bits_corrupt),
    .io_in_2_ready(Arbiter16_TLBundleD_g_io_in_2_ready),
    .io_in_2_valid(Arbiter16_TLBundleD_io_in_2_valid),
    .io_in_2_bits_opcode(Arbiter16_TLBundleD_io_in_2_bits_opcode),
    .io_in_2_bits_size(Arbiter16_TLBundleD_io_in_2_bits_size),
    .io_in_2_bits_source(Arbiter16_TLBundleD_io_in_2_bits_source),
    .io_in_2_bits_denied(Arbiter16_TLBundleD_io_in_2_bits_denied),
    .io_in_2_bits_data(Arbiter16_TLBundleD_io_in_2_bits_data),
    .io_in_2_bits_corrupt(Arbiter16_TLBundleD_io_in_2_bits_corrupt),
    .io_in_3_ready(Arbiter16_TLBundleD_g_io_in_3_ready),
    .io_in_3_valid(Arbiter16_TLBundleD_io_in_3_valid),
    .io_in_3_bits_opcode(Arbiter16_TLBundleD_io_in_3_bits_opcode),
    .io_in_3_bits_size(Arbiter16_TLBundleD_io_in_3_bits_size),
    .io_in_3_bits_source(Arbiter16_TLBundleD_io_in_3_bits_source),
    .io_in_3_bits_denied(Arbiter16_TLBundleD_io_in_3_bits_denied),
    .io_in_3_bits_data(Arbiter16_TLBundleD_io_in_3_bits_data),
    .io_in_3_bits_corrupt(Arbiter16_TLBundleD_io_in_3_bits_corrupt),
    .io_in_4_ready(Arbiter16_TLBundleD_g_io_in_4_ready),
    .io_in_4_valid(Arbiter16_TLBundleD_io_in_4_valid),
    .io_in_4_bits_opcode(Arbiter16_TLBundleD_io_in_4_bits_opcode),
    .io_in_4_bits_size(Arbiter16_TLBundleD_io_in_4_bits_size),
    .io_in_4_bits_source(Arbiter16_TLBundleD_io_in_4_bits_source),
    .io_in_4_bits_denied(Arbiter16_TLBundleD_io_in_4_bits_denied),
    .io_in_4_bits_data(Arbiter16_TLBundleD_io_in_4_bits_data),
    .io_in_4_bits_corrupt(Arbiter16_TLBundleD_io_in_4_bits_corrupt),
    .io_in_5_ready(Arbiter16_TLBundleD_g_io_in_5_ready),
    .io_in_5_valid(Arbiter16_TLBundleD_io_in_5_valid),
    .io_in_5_bits_opcode(Arbiter16_TLBundleD_io_in_5_bits_opcode),
    .io_in_5_bits_size(Arbiter16_TLBundleD_io_in_5_bits_size),
    .io_in_5_bits_source(Arbiter16_TLBundleD_io_in_5_bits_source),
    .io_in_5_bits_denied(Arbiter16_TLBundleD_io_in_5_bits_denied),
    .io_in_5_bits_data(Arbiter16_TLBundleD_io_in_5_bits_data),
    .io_in_5_bits_corrupt(Arbiter16_TLBundleD_io_in_5_bits_corrupt),
    .io_in_6_ready(Arbiter16_TLBundleD_g_io_in_6_ready),
    .io_in_6_valid(Arbiter16_TLBundleD_io_in_6_valid),
    .io_in_6_bits_opcode(Arbiter16_TLBundleD_io_in_6_bits_opcode),
    .io_in_6_bits_size(Arbiter16_TLBundleD_io_in_6_bits_size),
    .io_in_6_bits_source(Arbiter16_TLBundleD_io_in_6_bits_source),
    .io_in_6_bits_denied(Arbiter16_TLBundleD_io_in_6_bits_denied),
    .io_in_6_bits_data(Arbiter16_TLBundleD_io_in_6_bits_data),
    .io_in_6_bits_corrupt(Arbiter16_TLBundleD_io_in_6_bits_corrupt),
    .io_in_7_ready(Arbiter16_TLBundleD_g_io_in_7_ready),
    .io_in_7_valid(Arbiter16_TLBundleD_io_in_7_valid),
    .io_in_7_bits_opcode(Arbiter16_TLBundleD_io_in_7_bits_opcode),
    .io_in_7_bits_size(Arbiter16_TLBundleD_io_in_7_bits_size),
    .io_in_7_bits_source(Arbiter16_TLBundleD_io_in_7_bits_source),
    .io_in_7_bits_denied(Arbiter16_TLBundleD_io_in_7_bits_denied),
    .io_in_7_bits_data(Arbiter16_TLBundleD_io_in_7_bits_data),
    .io_in_7_bits_corrupt(Arbiter16_TLBundleD_io_in_7_bits_corrupt),
    .io_in_8_ready(Arbiter16_TLBundleD_g_io_in_8_ready),
    .io_in_8_valid(Arbiter16_TLBundleD_io_in_8_valid),
    .io_in_8_bits_opcode(Arbiter16_TLBundleD_io_in_8_bits_opcode),
    .io_in_8_bits_size(Arbiter16_TLBundleD_io_in_8_bits_size),
    .io_in_8_bits_source(Arbiter16_TLBundleD_io_in_8_bits_source),
    .io_in_8_bits_denied(Arbiter16_TLBundleD_io_in_8_bits_denied),
    .io_in_8_bits_data(Arbiter16_TLBundleD_io_in_8_bits_data),
    .io_in_8_bits_corrupt(Arbiter16_TLBundleD_io_in_8_bits_corrupt),
    .io_in_9_ready(Arbiter16_TLBundleD_g_io_in_9_ready),
    .io_in_9_valid(Arbiter16_TLBundleD_io_in_9_valid),
    .io_in_9_bits_opcode(Arbiter16_TLBundleD_io_in_9_bits_opcode),
    .io_in_9_bits_size(Arbiter16_TLBundleD_io_in_9_bits_size),
    .io_in_9_bits_source(Arbiter16_TLBundleD_io_in_9_bits_source),
    .io_in_9_bits_denied(Arbiter16_TLBundleD_io_in_9_bits_denied),
    .io_in_9_bits_data(Arbiter16_TLBundleD_io_in_9_bits_data),
    .io_in_9_bits_corrupt(Arbiter16_TLBundleD_io_in_9_bits_corrupt),
    .io_in_10_ready(Arbiter16_TLBundleD_g_io_in_10_ready),
    .io_in_10_valid(Arbiter16_TLBundleD_io_in_10_valid),
    .io_in_10_bits_opcode(Arbiter16_TLBundleD_io_in_10_bits_opcode),
    .io_in_10_bits_size(Arbiter16_TLBundleD_io_in_10_bits_size),
    .io_in_10_bits_source(Arbiter16_TLBundleD_io_in_10_bits_source),
    .io_in_10_bits_denied(Arbiter16_TLBundleD_io_in_10_bits_denied),
    .io_in_10_bits_data(Arbiter16_TLBundleD_io_in_10_bits_data),
    .io_in_10_bits_corrupt(Arbiter16_TLBundleD_io_in_10_bits_corrupt),
    .io_in_11_ready(Arbiter16_TLBundleD_g_io_in_11_ready),
    .io_in_11_valid(Arbiter16_TLBundleD_io_in_11_valid),
    .io_in_11_bits_opcode(Arbiter16_TLBundleD_io_in_11_bits_opcode),
    .io_in_11_bits_size(Arbiter16_TLBundleD_io_in_11_bits_size),
    .io_in_11_bits_source(Arbiter16_TLBundleD_io_in_11_bits_source),
    .io_in_11_bits_denied(Arbiter16_TLBundleD_io_in_11_bits_denied),
    .io_in_11_bits_data(Arbiter16_TLBundleD_io_in_11_bits_data),
    .io_in_11_bits_corrupt(Arbiter16_TLBundleD_io_in_11_bits_corrupt),
    .io_in_12_ready(Arbiter16_TLBundleD_g_io_in_12_ready),
    .io_in_12_valid(Arbiter16_TLBundleD_io_in_12_valid),
    .io_in_12_bits_opcode(Arbiter16_TLBundleD_io_in_12_bits_opcode),
    .io_in_12_bits_size(Arbiter16_TLBundleD_io_in_12_bits_size),
    .io_in_12_bits_source(Arbiter16_TLBundleD_io_in_12_bits_source),
    .io_in_12_bits_denied(Arbiter16_TLBundleD_io_in_12_bits_denied),
    .io_in_12_bits_data(Arbiter16_TLBundleD_io_in_12_bits_data),
    .io_in_12_bits_corrupt(Arbiter16_TLBundleD_io_in_12_bits_corrupt),
    .io_in_13_ready(Arbiter16_TLBundleD_g_io_in_13_ready),
    .io_in_13_valid(Arbiter16_TLBundleD_io_in_13_valid),
    .io_in_13_bits_opcode(Arbiter16_TLBundleD_io_in_13_bits_opcode),
    .io_in_13_bits_size(Arbiter16_TLBundleD_io_in_13_bits_size),
    .io_in_13_bits_source(Arbiter16_TLBundleD_io_in_13_bits_source),
    .io_in_13_bits_denied(Arbiter16_TLBundleD_io_in_13_bits_denied),
    .io_in_13_bits_data(Arbiter16_TLBundleD_io_in_13_bits_data),
    .io_in_13_bits_corrupt(Arbiter16_TLBundleD_io_in_13_bits_corrupt),
    .io_in_14_ready(Arbiter16_TLBundleD_g_io_in_14_ready),
    .io_in_14_valid(Arbiter16_TLBundleD_io_in_14_valid),
    .io_in_14_bits_opcode(Arbiter16_TLBundleD_io_in_14_bits_opcode),
    .io_in_14_bits_size(Arbiter16_TLBundleD_io_in_14_bits_size),
    .io_in_14_bits_source(Arbiter16_TLBundleD_io_in_14_bits_source),
    .io_in_14_bits_denied(Arbiter16_TLBundleD_io_in_14_bits_denied),
    .io_in_14_bits_data(Arbiter16_TLBundleD_io_in_14_bits_data),
    .io_in_14_bits_corrupt(Arbiter16_TLBundleD_io_in_14_bits_corrupt),
    .io_in_15_ready(Arbiter16_TLBundleD_g_io_in_15_ready),
    .io_in_15_valid(Arbiter16_TLBundleD_io_in_15_valid),
    .io_in_15_bits_opcode(Arbiter16_TLBundleD_io_in_15_bits_opcode),
    .io_in_15_bits_size(Arbiter16_TLBundleD_io_in_15_bits_size),
    .io_in_15_bits_source(Arbiter16_TLBundleD_io_in_15_bits_source),
    .io_in_15_bits_denied(Arbiter16_TLBundleD_io_in_15_bits_denied),
    .io_in_15_bits_data(Arbiter16_TLBundleD_io_in_15_bits_data),
    .io_in_15_bits_corrupt(Arbiter16_TLBundleD_io_in_15_bits_corrupt),
    .io_out_ready(Arbiter16_TLBundleD_io_out_ready),
    .io_out_valid(Arbiter16_TLBundleD_g_io_out_valid),
    .io_out_bits_opcode(Arbiter16_TLBundleD_g_io_out_bits_opcode),
    .io_out_bits_size(Arbiter16_TLBundleD_g_io_out_bits_size),
    .io_out_bits_source(Arbiter16_TLBundleD_g_io_out_bits_source),
    .io_out_bits_denied(Arbiter16_TLBundleD_g_io_out_bits_denied),
    .io_out_bits_data(Arbiter16_TLBundleD_g_io_out_bits_data),
    .io_out_bits_corrupt(Arbiter16_TLBundleD_g_io_out_bits_corrupt)
  );
  Arbiter16_TLBundleD_xs x_Arbiter16_TLBundleD (
    .io_in_0_ready(Arbiter16_TLBundleD_x_io_in_0_ready),
    .io_in_0_valid(Arbiter16_TLBundleD_io_in_0_valid),
    .io_in_0_bits_opcode(Arbiter16_TLBundleD_io_in_0_bits_opcode),
    .io_in_0_bits_size(Arbiter16_TLBundleD_io_in_0_bits_size),
    .io_in_0_bits_source(Arbiter16_TLBundleD_io_in_0_bits_source),
    .io_in_0_bits_denied(Arbiter16_TLBundleD_io_in_0_bits_denied),
    .io_in_0_bits_data(Arbiter16_TLBundleD_io_in_0_bits_data),
    .io_in_0_bits_corrupt(Arbiter16_TLBundleD_io_in_0_bits_corrupt),
    .io_in_1_ready(Arbiter16_TLBundleD_x_io_in_1_ready),
    .io_in_1_valid(Arbiter16_TLBundleD_io_in_1_valid),
    .io_in_1_bits_opcode(Arbiter16_TLBundleD_io_in_1_bits_opcode),
    .io_in_1_bits_size(Arbiter16_TLBundleD_io_in_1_bits_size),
    .io_in_1_bits_source(Arbiter16_TLBundleD_io_in_1_bits_source),
    .io_in_1_bits_denied(Arbiter16_TLBundleD_io_in_1_bits_denied),
    .io_in_1_bits_data(Arbiter16_TLBundleD_io_in_1_bits_data),
    .io_in_1_bits_corrupt(Arbiter16_TLBundleD_io_in_1_bits_corrupt),
    .io_in_2_ready(Arbiter16_TLBundleD_x_io_in_2_ready),
    .io_in_2_valid(Arbiter16_TLBundleD_io_in_2_valid),
    .io_in_2_bits_opcode(Arbiter16_TLBundleD_io_in_2_bits_opcode),
    .io_in_2_bits_size(Arbiter16_TLBundleD_io_in_2_bits_size),
    .io_in_2_bits_source(Arbiter16_TLBundleD_io_in_2_bits_source),
    .io_in_2_bits_denied(Arbiter16_TLBundleD_io_in_2_bits_denied),
    .io_in_2_bits_data(Arbiter16_TLBundleD_io_in_2_bits_data),
    .io_in_2_bits_corrupt(Arbiter16_TLBundleD_io_in_2_bits_corrupt),
    .io_in_3_ready(Arbiter16_TLBundleD_x_io_in_3_ready),
    .io_in_3_valid(Arbiter16_TLBundleD_io_in_3_valid),
    .io_in_3_bits_opcode(Arbiter16_TLBundleD_io_in_3_bits_opcode),
    .io_in_3_bits_size(Arbiter16_TLBundleD_io_in_3_bits_size),
    .io_in_3_bits_source(Arbiter16_TLBundleD_io_in_3_bits_source),
    .io_in_3_bits_denied(Arbiter16_TLBundleD_io_in_3_bits_denied),
    .io_in_3_bits_data(Arbiter16_TLBundleD_io_in_3_bits_data),
    .io_in_3_bits_corrupt(Arbiter16_TLBundleD_io_in_3_bits_corrupt),
    .io_in_4_ready(Arbiter16_TLBundleD_x_io_in_4_ready),
    .io_in_4_valid(Arbiter16_TLBundleD_io_in_4_valid),
    .io_in_4_bits_opcode(Arbiter16_TLBundleD_io_in_4_bits_opcode),
    .io_in_4_bits_size(Arbiter16_TLBundleD_io_in_4_bits_size),
    .io_in_4_bits_source(Arbiter16_TLBundleD_io_in_4_bits_source),
    .io_in_4_bits_denied(Arbiter16_TLBundleD_io_in_4_bits_denied),
    .io_in_4_bits_data(Arbiter16_TLBundleD_io_in_4_bits_data),
    .io_in_4_bits_corrupt(Arbiter16_TLBundleD_io_in_4_bits_corrupt),
    .io_in_5_ready(Arbiter16_TLBundleD_x_io_in_5_ready),
    .io_in_5_valid(Arbiter16_TLBundleD_io_in_5_valid),
    .io_in_5_bits_opcode(Arbiter16_TLBundleD_io_in_5_bits_opcode),
    .io_in_5_bits_size(Arbiter16_TLBundleD_io_in_5_bits_size),
    .io_in_5_bits_source(Arbiter16_TLBundleD_io_in_5_bits_source),
    .io_in_5_bits_denied(Arbiter16_TLBundleD_io_in_5_bits_denied),
    .io_in_5_bits_data(Arbiter16_TLBundleD_io_in_5_bits_data),
    .io_in_5_bits_corrupt(Arbiter16_TLBundleD_io_in_5_bits_corrupt),
    .io_in_6_ready(Arbiter16_TLBundleD_x_io_in_6_ready),
    .io_in_6_valid(Arbiter16_TLBundleD_io_in_6_valid),
    .io_in_6_bits_opcode(Arbiter16_TLBundleD_io_in_6_bits_opcode),
    .io_in_6_bits_size(Arbiter16_TLBundleD_io_in_6_bits_size),
    .io_in_6_bits_source(Arbiter16_TLBundleD_io_in_6_bits_source),
    .io_in_6_bits_denied(Arbiter16_TLBundleD_io_in_6_bits_denied),
    .io_in_6_bits_data(Arbiter16_TLBundleD_io_in_6_bits_data),
    .io_in_6_bits_corrupt(Arbiter16_TLBundleD_io_in_6_bits_corrupt),
    .io_in_7_ready(Arbiter16_TLBundleD_x_io_in_7_ready),
    .io_in_7_valid(Arbiter16_TLBundleD_io_in_7_valid),
    .io_in_7_bits_opcode(Arbiter16_TLBundleD_io_in_7_bits_opcode),
    .io_in_7_bits_size(Arbiter16_TLBundleD_io_in_7_bits_size),
    .io_in_7_bits_source(Arbiter16_TLBundleD_io_in_7_bits_source),
    .io_in_7_bits_denied(Arbiter16_TLBundleD_io_in_7_bits_denied),
    .io_in_7_bits_data(Arbiter16_TLBundleD_io_in_7_bits_data),
    .io_in_7_bits_corrupt(Arbiter16_TLBundleD_io_in_7_bits_corrupt),
    .io_in_8_ready(Arbiter16_TLBundleD_x_io_in_8_ready),
    .io_in_8_valid(Arbiter16_TLBundleD_io_in_8_valid),
    .io_in_8_bits_opcode(Arbiter16_TLBundleD_io_in_8_bits_opcode),
    .io_in_8_bits_size(Arbiter16_TLBundleD_io_in_8_bits_size),
    .io_in_8_bits_source(Arbiter16_TLBundleD_io_in_8_bits_source),
    .io_in_8_bits_denied(Arbiter16_TLBundleD_io_in_8_bits_denied),
    .io_in_8_bits_data(Arbiter16_TLBundleD_io_in_8_bits_data),
    .io_in_8_bits_corrupt(Arbiter16_TLBundleD_io_in_8_bits_corrupt),
    .io_in_9_ready(Arbiter16_TLBundleD_x_io_in_9_ready),
    .io_in_9_valid(Arbiter16_TLBundleD_io_in_9_valid),
    .io_in_9_bits_opcode(Arbiter16_TLBundleD_io_in_9_bits_opcode),
    .io_in_9_bits_size(Arbiter16_TLBundleD_io_in_9_bits_size),
    .io_in_9_bits_source(Arbiter16_TLBundleD_io_in_9_bits_source),
    .io_in_9_bits_denied(Arbiter16_TLBundleD_io_in_9_bits_denied),
    .io_in_9_bits_data(Arbiter16_TLBundleD_io_in_9_bits_data),
    .io_in_9_bits_corrupt(Arbiter16_TLBundleD_io_in_9_bits_corrupt),
    .io_in_10_ready(Arbiter16_TLBundleD_x_io_in_10_ready),
    .io_in_10_valid(Arbiter16_TLBundleD_io_in_10_valid),
    .io_in_10_bits_opcode(Arbiter16_TLBundleD_io_in_10_bits_opcode),
    .io_in_10_bits_size(Arbiter16_TLBundleD_io_in_10_bits_size),
    .io_in_10_bits_source(Arbiter16_TLBundleD_io_in_10_bits_source),
    .io_in_10_bits_denied(Arbiter16_TLBundleD_io_in_10_bits_denied),
    .io_in_10_bits_data(Arbiter16_TLBundleD_io_in_10_bits_data),
    .io_in_10_bits_corrupt(Arbiter16_TLBundleD_io_in_10_bits_corrupt),
    .io_in_11_ready(Arbiter16_TLBundleD_x_io_in_11_ready),
    .io_in_11_valid(Arbiter16_TLBundleD_io_in_11_valid),
    .io_in_11_bits_opcode(Arbiter16_TLBundleD_io_in_11_bits_opcode),
    .io_in_11_bits_size(Arbiter16_TLBundleD_io_in_11_bits_size),
    .io_in_11_bits_source(Arbiter16_TLBundleD_io_in_11_bits_source),
    .io_in_11_bits_denied(Arbiter16_TLBundleD_io_in_11_bits_denied),
    .io_in_11_bits_data(Arbiter16_TLBundleD_io_in_11_bits_data),
    .io_in_11_bits_corrupt(Arbiter16_TLBundleD_io_in_11_bits_corrupt),
    .io_in_12_ready(Arbiter16_TLBundleD_x_io_in_12_ready),
    .io_in_12_valid(Arbiter16_TLBundleD_io_in_12_valid),
    .io_in_12_bits_opcode(Arbiter16_TLBundleD_io_in_12_bits_opcode),
    .io_in_12_bits_size(Arbiter16_TLBundleD_io_in_12_bits_size),
    .io_in_12_bits_source(Arbiter16_TLBundleD_io_in_12_bits_source),
    .io_in_12_bits_denied(Arbiter16_TLBundleD_io_in_12_bits_denied),
    .io_in_12_bits_data(Arbiter16_TLBundleD_io_in_12_bits_data),
    .io_in_12_bits_corrupt(Arbiter16_TLBundleD_io_in_12_bits_corrupt),
    .io_in_13_ready(Arbiter16_TLBundleD_x_io_in_13_ready),
    .io_in_13_valid(Arbiter16_TLBundleD_io_in_13_valid),
    .io_in_13_bits_opcode(Arbiter16_TLBundleD_io_in_13_bits_opcode),
    .io_in_13_bits_size(Arbiter16_TLBundleD_io_in_13_bits_size),
    .io_in_13_bits_source(Arbiter16_TLBundleD_io_in_13_bits_source),
    .io_in_13_bits_denied(Arbiter16_TLBundleD_io_in_13_bits_denied),
    .io_in_13_bits_data(Arbiter16_TLBundleD_io_in_13_bits_data),
    .io_in_13_bits_corrupt(Arbiter16_TLBundleD_io_in_13_bits_corrupt),
    .io_in_14_ready(Arbiter16_TLBundleD_x_io_in_14_ready),
    .io_in_14_valid(Arbiter16_TLBundleD_io_in_14_valid),
    .io_in_14_bits_opcode(Arbiter16_TLBundleD_io_in_14_bits_opcode),
    .io_in_14_bits_size(Arbiter16_TLBundleD_io_in_14_bits_size),
    .io_in_14_bits_source(Arbiter16_TLBundleD_io_in_14_bits_source),
    .io_in_14_bits_denied(Arbiter16_TLBundleD_io_in_14_bits_denied),
    .io_in_14_bits_data(Arbiter16_TLBundleD_io_in_14_bits_data),
    .io_in_14_bits_corrupt(Arbiter16_TLBundleD_io_in_14_bits_corrupt),
    .io_in_15_ready(Arbiter16_TLBundleD_x_io_in_15_ready),
    .io_in_15_valid(Arbiter16_TLBundleD_io_in_15_valid),
    .io_in_15_bits_opcode(Arbiter16_TLBundleD_io_in_15_bits_opcode),
    .io_in_15_bits_size(Arbiter16_TLBundleD_io_in_15_bits_size),
    .io_in_15_bits_source(Arbiter16_TLBundleD_io_in_15_bits_source),
    .io_in_15_bits_denied(Arbiter16_TLBundleD_io_in_15_bits_denied),
    .io_in_15_bits_data(Arbiter16_TLBundleD_io_in_15_bits_data),
    .io_in_15_bits_corrupt(Arbiter16_TLBundleD_io_in_15_bits_corrupt),
    .io_out_ready(Arbiter16_TLBundleD_io_out_ready),
    .io_out_valid(Arbiter16_TLBundleD_x_io_out_valid),
    .io_out_bits_opcode(Arbiter16_TLBundleD_x_io_out_bits_opcode),
    .io_out_bits_size(Arbiter16_TLBundleD_x_io_out_bits_size),
    .io_out_bits_source(Arbiter16_TLBundleD_x_io_out_bits_source),
    .io_out_bits_denied(Arbiter16_TLBundleD_x_io_out_bits_denied),
    .io_out_bits_data(Arbiter16_TLBundleD_x_io_out_bits_data),
    .io_out_bits_corrupt(Arbiter16_TLBundleD_x_io_out_bits_corrupt)
  );

  Arbiter3_PfGenReq g_Arbiter3_PfGenReq (
    .io_in_0_valid(Arbiter3_PfGenReq_io_in_0_valid),
    .io_in_0_bits_region_tag(Arbiter3_PfGenReq_io_in_0_bits_region_tag),
    .io_in_0_bits_region_addr(Arbiter3_PfGenReq_io_in_0_bits_region_addr),
    .io_in_0_bits_region_bits(Arbiter3_PfGenReq_io_in_0_bits_region_bits),
    .io_in_1_ready(Arbiter3_PfGenReq_g_io_in_1_ready),
    .io_in_1_valid(Arbiter3_PfGenReq_io_in_1_valid),
    .io_in_1_bits_region_tag(Arbiter3_PfGenReq_io_in_1_bits_region_tag),
    .io_in_1_bits_region_addr(Arbiter3_PfGenReq_io_in_1_bits_region_addr),
    .io_in_1_bits_region_bits(Arbiter3_PfGenReq_io_in_1_bits_region_bits),
    .io_in_1_bits_paddr_valid(Arbiter3_PfGenReq_io_in_1_bits_paddr_valid),
    .io_in_2_ready(Arbiter3_PfGenReq_g_io_in_2_ready),
    .io_in_2_valid(Arbiter3_PfGenReq_io_in_2_valid),
    .io_in_2_bits_region_tag(Arbiter3_PfGenReq_io_in_2_bits_region_tag),
    .io_in_2_bits_region_addr(Arbiter3_PfGenReq_io_in_2_bits_region_addr),
    .io_in_2_bits_region_bits(Arbiter3_PfGenReq_io_in_2_bits_region_bits),
    .io_in_2_bits_paddr_valid(Arbiter3_PfGenReq_io_in_2_bits_paddr_valid),
    .io_out_valid(Arbiter3_PfGenReq_g_io_out_valid),
    .io_out_bits_region_tag(Arbiter3_PfGenReq_g_io_out_bits_region_tag),
    .io_out_bits_region_addr(Arbiter3_PfGenReq_g_io_out_bits_region_addr),
    .io_out_bits_region_bits(Arbiter3_PfGenReq_g_io_out_bits_region_bits),
    .io_out_bits_paddr_valid(Arbiter3_PfGenReq_g_io_out_bits_paddr_valid),
    .io_out_bits_decr_mode(Arbiter3_PfGenReq_g_io_out_bits_decr_mode)
  );
  Arbiter3_PfGenReq_xs x_Arbiter3_PfGenReq (
    .io_in_0_valid(Arbiter3_PfGenReq_io_in_0_valid),
    .io_in_0_bits_region_tag(Arbiter3_PfGenReq_io_in_0_bits_region_tag),
    .io_in_0_bits_region_addr(Arbiter3_PfGenReq_io_in_0_bits_region_addr),
    .io_in_0_bits_region_bits(Arbiter3_PfGenReq_io_in_0_bits_region_bits),
    .io_in_1_ready(Arbiter3_PfGenReq_x_io_in_1_ready),
    .io_in_1_valid(Arbiter3_PfGenReq_io_in_1_valid),
    .io_in_1_bits_region_tag(Arbiter3_PfGenReq_io_in_1_bits_region_tag),
    .io_in_1_bits_region_addr(Arbiter3_PfGenReq_io_in_1_bits_region_addr),
    .io_in_1_bits_region_bits(Arbiter3_PfGenReq_io_in_1_bits_region_bits),
    .io_in_1_bits_paddr_valid(Arbiter3_PfGenReq_io_in_1_bits_paddr_valid),
    .io_in_2_ready(Arbiter3_PfGenReq_x_io_in_2_ready),
    .io_in_2_valid(Arbiter3_PfGenReq_io_in_2_valid),
    .io_in_2_bits_region_tag(Arbiter3_PfGenReq_io_in_2_bits_region_tag),
    .io_in_2_bits_region_addr(Arbiter3_PfGenReq_io_in_2_bits_region_addr),
    .io_in_2_bits_region_bits(Arbiter3_PfGenReq_io_in_2_bits_region_bits),
    .io_in_2_bits_paddr_valid(Arbiter3_PfGenReq_io_in_2_bits_paddr_valid),
    .io_out_valid(Arbiter3_PfGenReq_x_io_out_valid),
    .io_out_bits_region_tag(Arbiter3_PfGenReq_x_io_out_bits_region_tag),
    .io_out_bits_region_addr(Arbiter3_PfGenReq_x_io_out_bits_region_addr),
    .io_out_bits_region_bits(Arbiter3_PfGenReq_x_io_out_bits_region_bits),
    .io_out_bits_paddr_valid(Arbiter3_PfGenReq_x_io_out_bits_paddr_valid),
    .io_out_bits_decr_mode(Arbiter3_PfGenReq_x_io_out_bits_decr_mode)
  );

  Arbiter4_L2ToL1Hint g_Arbiter4_L2ToL1Hint (
    .io_in_0_ready(Arbiter4_L2ToL1Hint_g_io_in_0_ready),
    .io_in_0_valid(Arbiter4_L2ToL1Hint_io_in_0_valid),
    .io_in_0_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_0_bits_sourceId),
    .io_in_0_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_0_bits_isKeyword),
    .io_in_1_ready(Arbiter4_L2ToL1Hint_g_io_in_1_ready),
    .io_in_1_valid(Arbiter4_L2ToL1Hint_io_in_1_valid),
    .io_in_1_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_1_bits_sourceId),
    .io_in_1_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_1_bits_isKeyword),
    .io_in_2_ready(Arbiter4_L2ToL1Hint_g_io_in_2_ready),
    .io_in_2_valid(Arbiter4_L2ToL1Hint_io_in_2_valid),
    .io_in_2_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_2_bits_sourceId),
    .io_in_2_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_2_bits_isKeyword),
    .io_in_3_ready(Arbiter4_L2ToL1Hint_g_io_in_3_ready),
    .io_in_3_valid(Arbiter4_L2ToL1Hint_io_in_3_valid),
    .io_in_3_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_3_bits_sourceId),
    .io_in_3_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_3_bits_isKeyword),
    .io_out_ready(Arbiter4_L2ToL1Hint_io_out_ready),
    .io_out_valid(Arbiter4_L2ToL1Hint_g_io_out_valid),
    .io_out_bits_sourceId(Arbiter4_L2ToL1Hint_g_io_out_bits_sourceId),
    .io_out_bits_isKeyword(Arbiter4_L2ToL1Hint_g_io_out_bits_isKeyword),
    .io_chosen(Arbiter4_L2ToL1Hint_g_io_chosen)
  );
  Arbiter4_L2ToL1Hint_xs x_Arbiter4_L2ToL1Hint (
    .io_in_0_ready(Arbiter4_L2ToL1Hint_x_io_in_0_ready),
    .io_in_0_valid(Arbiter4_L2ToL1Hint_io_in_0_valid),
    .io_in_0_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_0_bits_sourceId),
    .io_in_0_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_0_bits_isKeyword),
    .io_in_1_ready(Arbiter4_L2ToL1Hint_x_io_in_1_ready),
    .io_in_1_valid(Arbiter4_L2ToL1Hint_io_in_1_valid),
    .io_in_1_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_1_bits_sourceId),
    .io_in_1_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_1_bits_isKeyword),
    .io_in_2_ready(Arbiter4_L2ToL1Hint_x_io_in_2_ready),
    .io_in_2_valid(Arbiter4_L2ToL1Hint_io_in_2_valid),
    .io_in_2_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_2_bits_sourceId),
    .io_in_2_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_2_bits_isKeyword),
    .io_in_3_ready(Arbiter4_L2ToL1Hint_x_io_in_3_ready),
    .io_in_3_valid(Arbiter4_L2ToL1Hint_io_in_3_valid),
    .io_in_3_bits_sourceId(Arbiter4_L2ToL1Hint_io_in_3_bits_sourceId),
    .io_in_3_bits_isKeyword(Arbiter4_L2ToL1Hint_io_in_3_bits_isKeyword),
    .io_out_ready(Arbiter4_L2ToL1Hint_io_out_ready),
    .io_out_valid(Arbiter4_L2ToL1Hint_x_io_out_valid),
    .io_out_bits_sourceId(Arbiter4_L2ToL1Hint_x_io_out_bits_sourceId),
    .io_out_bits_isKeyword(Arbiter4_L2ToL1Hint_x_io_out_bits_isKeyword),
    .io_chosen(Arbiter4_L2ToL1Hint_x_io_chosen)
  );

  Arbiter4_PrefetchReq g_Arbiter4_PrefetchReq (
    .io_in_0_valid(Arbiter4_PrefetchReq_io_in_0_valid),
    .io_in_0_bits_tag(Arbiter4_PrefetchReq_io_in_0_bits_tag),
    .io_in_0_bits_set(Arbiter4_PrefetchReq_io_in_0_bits_set),
    .io_in_0_bits_pfSource(Arbiter4_PrefetchReq_io_in_0_bits_pfSource),
    .io_in_1_ready(Arbiter4_PrefetchReq_g_io_in_1_ready),
    .io_in_1_valid(Arbiter4_PrefetchReq_io_in_1_valid),
    .io_in_1_bits_tag(Arbiter4_PrefetchReq_io_in_1_bits_tag),
    .io_in_1_bits_set(Arbiter4_PrefetchReq_io_in_1_bits_set),
    .io_in_1_bits_vaddr(Arbiter4_PrefetchReq_io_in_1_bits_vaddr),
    .io_in_1_bits_needT(Arbiter4_PrefetchReq_io_in_1_bits_needT),
    .io_in_1_bits_source(Arbiter4_PrefetchReq_io_in_1_bits_source),
    .io_in_2_ready(Arbiter4_PrefetchReq_g_io_in_2_ready),
    .io_in_2_valid(Arbiter4_PrefetchReq_io_in_2_valid),
    .io_in_2_bits_tag(Arbiter4_PrefetchReq_io_in_2_bits_tag),
    .io_in_2_bits_set(Arbiter4_PrefetchReq_io_in_2_bits_set),
    .io_in_2_bits_vaddr(Arbiter4_PrefetchReq_io_in_2_bits_vaddr),
    .io_in_2_bits_needT(Arbiter4_PrefetchReq_io_in_2_bits_needT),
    .io_in_2_bits_source(Arbiter4_PrefetchReq_io_in_2_bits_source),
    .io_out_valid(Arbiter4_PrefetchReq_g_io_out_valid),
    .io_out_bits_tag(Arbiter4_PrefetchReq_g_io_out_bits_tag),
    .io_out_bits_set(Arbiter4_PrefetchReq_g_io_out_bits_set),
    .io_out_bits_vaddr(Arbiter4_PrefetchReq_g_io_out_bits_vaddr),
    .io_out_bits_needT(Arbiter4_PrefetchReq_g_io_out_bits_needT),
    .io_out_bits_source(Arbiter4_PrefetchReq_g_io_out_bits_source),
    .io_out_bits_pfSource(Arbiter4_PrefetchReq_g_io_out_bits_pfSource)
  );
  Arbiter4_PrefetchReq_xs x_Arbiter4_PrefetchReq (
    .io_in_0_valid(Arbiter4_PrefetchReq_io_in_0_valid),
    .io_in_0_bits_tag(Arbiter4_PrefetchReq_io_in_0_bits_tag),
    .io_in_0_bits_set(Arbiter4_PrefetchReq_io_in_0_bits_set),
    .io_in_0_bits_pfSource(Arbiter4_PrefetchReq_io_in_0_bits_pfSource),
    .io_in_1_ready(Arbiter4_PrefetchReq_x_io_in_1_ready),
    .io_in_1_valid(Arbiter4_PrefetchReq_io_in_1_valid),
    .io_in_1_bits_tag(Arbiter4_PrefetchReq_io_in_1_bits_tag),
    .io_in_1_bits_set(Arbiter4_PrefetchReq_io_in_1_bits_set),
    .io_in_1_bits_vaddr(Arbiter4_PrefetchReq_io_in_1_bits_vaddr),
    .io_in_1_bits_needT(Arbiter4_PrefetchReq_io_in_1_bits_needT),
    .io_in_1_bits_source(Arbiter4_PrefetchReq_io_in_1_bits_source),
    .io_in_2_ready(Arbiter4_PrefetchReq_x_io_in_2_ready),
    .io_in_2_valid(Arbiter4_PrefetchReq_io_in_2_valid),
    .io_in_2_bits_tag(Arbiter4_PrefetchReq_io_in_2_bits_tag),
    .io_in_2_bits_set(Arbiter4_PrefetchReq_io_in_2_bits_set),
    .io_in_2_bits_vaddr(Arbiter4_PrefetchReq_io_in_2_bits_vaddr),
    .io_in_2_bits_needT(Arbiter4_PrefetchReq_io_in_2_bits_needT),
    .io_in_2_bits_source(Arbiter4_PrefetchReq_io_in_2_bits_source),
    .io_out_valid(Arbiter4_PrefetchReq_x_io_out_valid),
    .io_out_bits_tag(Arbiter4_PrefetchReq_x_io_out_bits_tag),
    .io_out_bits_set(Arbiter4_PrefetchReq_x_io_out_bits_set),
    .io_out_bits_vaddr(Arbiter4_PrefetchReq_x_io_out_bits_vaddr),
    .io_out_bits_needT(Arbiter4_PrefetchReq_x_io_out_bits_needT),
    .io_out_bits_source(Arbiter4_PrefetchReq_x_io_out_bits_source),
    .io_out_bits_pfSource(Arbiter4_PrefetchReq_x_io_out_bits_pfSource)
  );

  CSA4to2_15 g_CSA4to2_15 (
    .io_in_a(CSA4to2_15_io_in_a),
    .io_in_b(CSA4to2_15_io_in_b),
    .io_in_c(CSA4to2_15_io_in_c),
    .io_in_d(CSA4to2_15_io_in_d),
    .io_out_sum(CSA4to2_15_g_io_out_sum),
    .io_out_car(CSA4to2_15_g_io_out_car)
  );
  CSA4to2_15_xs x_CSA4to2_15 (
    .io_in_a(CSA4to2_15_io_in_a),
    .io_in_b(CSA4to2_15_io_in_b),
    .io_in_c(CSA4to2_15_io_in_c),
    .io_in_d(CSA4to2_15_io_in_d),
    .io_out_sum(CSA4to2_15_x_io_out_sum),
    .io_out_car(CSA4to2_15_x_io_out_car)
  );

  MbistIntfFrontend g_MbistIntfFrontend (
    .toPipeline_0_array(MbistIntfFrontend_g_toPipeline_0_array),
    .toPipeline_0_all(MbistIntfFrontend_g_toPipeline_0_all),
    .toPipeline_0_req(MbistIntfFrontend_g_toPipeline_0_req),
    .toPipeline_0_ack(MbistIntfFrontend_toPipeline_0_ack),
    .toPipeline_0_writeen(MbistIntfFrontend_g_toPipeline_0_writeen),
    .toPipeline_0_be(MbistIntfFrontend_g_toPipeline_0_be),
    .toPipeline_0_addr(MbistIntfFrontend_g_toPipeline_0_addr),
    .toPipeline_0_indata(MbistIntfFrontend_g_toPipeline_0_indata),
    .toPipeline_0_readen(MbistIntfFrontend_g_toPipeline_0_readen),
    .toPipeline_0_addr_rd(MbistIntfFrontend_g_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(MbistIntfFrontend_toPipeline_0_outdata),
    .mbist_array(MbistIntfFrontend_mbist_array),
    .mbist_all(MbistIntfFrontend_mbist_all),
    .mbist_req(MbistIntfFrontend_mbist_req),
    .mbist_ack(MbistIntfFrontend_g_mbist_ack),
    .mbist_writeen(MbistIntfFrontend_mbist_writeen),
    .mbist_be(MbistIntfFrontend_mbist_be),
    .mbist_addr(MbistIntfFrontend_mbist_addr),
    .mbist_indata(MbistIntfFrontend_mbist_indata),
    .mbist_readen(MbistIntfFrontend_mbist_readen),
    .mbist_addr_rd(MbistIntfFrontend_mbist_addr_rd),
    .mbist_outdata(MbistIntfFrontend_g_mbist_outdata)
  );
  MbistIntfFrontend_xs x_MbistIntfFrontend (
    .toPipeline_0_array(MbistIntfFrontend_x_toPipeline_0_array),
    .toPipeline_0_all(MbistIntfFrontend_x_toPipeline_0_all),
    .toPipeline_0_req(MbistIntfFrontend_x_toPipeline_0_req),
    .toPipeline_0_ack(MbistIntfFrontend_toPipeline_0_ack),
    .toPipeline_0_writeen(MbistIntfFrontend_x_toPipeline_0_writeen),
    .toPipeline_0_be(MbistIntfFrontend_x_toPipeline_0_be),
    .toPipeline_0_addr(MbistIntfFrontend_x_toPipeline_0_addr),
    .toPipeline_0_indata(MbistIntfFrontend_x_toPipeline_0_indata),
    .toPipeline_0_readen(MbistIntfFrontend_x_toPipeline_0_readen),
    .toPipeline_0_addr_rd(MbistIntfFrontend_x_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(MbistIntfFrontend_toPipeline_0_outdata),
    .mbist_array(MbistIntfFrontend_mbist_array),
    .mbist_all(MbistIntfFrontend_mbist_all),
    .mbist_req(MbistIntfFrontend_mbist_req),
    .mbist_ack(MbistIntfFrontend_x_mbist_ack),
    .mbist_writeen(MbistIntfFrontend_mbist_writeen),
    .mbist_be(MbistIntfFrontend_mbist_be),
    .mbist_addr(MbistIntfFrontend_mbist_addr),
    .mbist_indata(MbistIntfFrontend_mbist_indata),
    .mbist_readen(MbistIntfFrontend_mbist_readen),
    .mbist_addr_rd(MbistIntfFrontend_mbist_addr_rd),
    .mbist_outdata(MbistIntfFrontend_x_mbist_outdata)
  );

  MbistIntfMemBlk g_MbistIntfMemBlk (
    .toPipeline_0_array(MbistIntfMemBlk_g_toPipeline_0_array),
    .toPipeline_0_all(MbistIntfMemBlk_g_toPipeline_0_all),
    .toPipeline_0_req(MbistIntfMemBlk_g_toPipeline_0_req),
    .toPipeline_0_ack(MbistIntfMemBlk_toPipeline_0_ack),
    .toPipeline_0_writeen(MbistIntfMemBlk_g_toPipeline_0_writeen),
    .toPipeline_0_be(MbistIntfMemBlk_g_toPipeline_0_be),
    .toPipeline_0_addr(MbistIntfMemBlk_g_toPipeline_0_addr),
    .toPipeline_0_indata(MbistIntfMemBlk_g_toPipeline_0_indata),
    .toPipeline_0_readen(MbistIntfMemBlk_g_toPipeline_0_readen),
    .toPipeline_0_addr_rd(MbistIntfMemBlk_g_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(MbistIntfMemBlk_toPipeline_0_outdata),
    .mbist_array(MbistIntfMemBlk_mbist_array),
    .mbist_all(MbistIntfMemBlk_mbist_all),
    .mbist_req(MbistIntfMemBlk_mbist_req),
    .mbist_ack(MbistIntfMemBlk_g_mbist_ack),
    .mbist_writeen(MbistIntfMemBlk_mbist_writeen),
    .mbist_be(MbistIntfMemBlk_mbist_be),
    .mbist_addr(MbistIntfMemBlk_mbist_addr),
    .mbist_indata(MbistIntfMemBlk_mbist_indata),
    .mbist_readen(MbistIntfMemBlk_mbist_readen),
    .mbist_addr_rd(MbistIntfMemBlk_mbist_addr_rd),
    .mbist_outdata(MbistIntfMemBlk_g_mbist_outdata)
  );
  MbistIntfMemBlk_xs x_MbistIntfMemBlk (
    .toPipeline_0_array(MbistIntfMemBlk_x_toPipeline_0_array),
    .toPipeline_0_all(MbistIntfMemBlk_x_toPipeline_0_all),
    .toPipeline_0_req(MbistIntfMemBlk_x_toPipeline_0_req),
    .toPipeline_0_ack(MbistIntfMemBlk_toPipeline_0_ack),
    .toPipeline_0_writeen(MbistIntfMemBlk_x_toPipeline_0_writeen),
    .toPipeline_0_be(MbistIntfMemBlk_x_toPipeline_0_be),
    .toPipeline_0_addr(MbistIntfMemBlk_x_toPipeline_0_addr),
    .toPipeline_0_indata(MbistIntfMemBlk_x_toPipeline_0_indata),
    .toPipeline_0_readen(MbistIntfMemBlk_x_toPipeline_0_readen),
    .toPipeline_0_addr_rd(MbistIntfMemBlk_x_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(MbistIntfMemBlk_toPipeline_0_outdata),
    .mbist_array(MbistIntfMemBlk_mbist_array),
    .mbist_all(MbistIntfMemBlk_mbist_all),
    .mbist_req(MbistIntfMemBlk_mbist_req),
    .mbist_ack(MbistIntfMemBlk_x_mbist_ack),
    .mbist_writeen(MbistIntfMemBlk_mbist_writeen),
    .mbist_be(MbistIntfMemBlk_mbist_be),
    .mbist_addr(MbistIntfMemBlk_mbist_addr),
    .mbist_indata(MbistIntfMemBlk_mbist_indata),
    .mbist_readen(MbistIntfMemBlk_mbist_readen),
    .mbist_addr_rd(MbistIntfMemBlk_mbist_addr_rd),
    .mbist_outdata(MbistIntfMemBlk_x_mbist_outdata)
  );

  NfMappedElemIdx g_NfMappedElemIdx (
    .in_nf(NfMappedElemIdx_in_nf),
    .in_eewOH(NfMappedElemIdx_in_eewOH),
    .out_idxRangeVec_0_from(NfMappedElemIdx_g_out_idxRangeVec_0_from),
    .out_idxRangeVec_0_until(NfMappedElemIdx_g_out_idxRangeVec_0_until),
    .out_idxRangeVec_1_from(NfMappedElemIdx_g_out_idxRangeVec_1_from),
    .out_idxRangeVec_1_until(NfMappedElemIdx_g_out_idxRangeVec_1_until),
    .out_idxRangeVec_2_from(NfMappedElemIdx_g_out_idxRangeVec_2_from),
    .out_idxRangeVec_2_until(NfMappedElemIdx_g_out_idxRangeVec_2_until),
    .out_idxRangeVec_3_from(NfMappedElemIdx_g_out_idxRangeVec_3_from),
    .out_idxRangeVec_3_until(NfMappedElemIdx_g_out_idxRangeVec_3_until),
    .out_idxRangeVec_4_from(NfMappedElemIdx_g_out_idxRangeVec_4_from),
    .out_idxRangeVec_4_until(NfMappedElemIdx_g_out_idxRangeVec_4_until),
    .out_idxRangeVec_5_from(NfMappedElemIdx_g_out_idxRangeVec_5_from),
    .out_idxRangeVec_5_until(NfMappedElemIdx_g_out_idxRangeVec_5_until),
    .out_idxRangeVec_6_from(NfMappedElemIdx_g_out_idxRangeVec_6_from),
    .out_idxRangeVec_6_until(NfMappedElemIdx_g_out_idxRangeVec_6_until),
    .out_idxRangeVec_7_from(NfMappedElemIdx_g_out_idxRangeVec_7_from),
    .out_idxRangeVec_7_until(NfMappedElemIdx_g_out_idxRangeVec_7_until)
  );
  NfMappedElemIdx_xs x_NfMappedElemIdx (
    .in_nf(NfMappedElemIdx_in_nf),
    .in_eewOH(NfMappedElemIdx_in_eewOH),
    .out_idxRangeVec_0_from(NfMappedElemIdx_x_out_idxRangeVec_0_from),
    .out_idxRangeVec_0_until(NfMappedElemIdx_x_out_idxRangeVec_0_until),
    .out_idxRangeVec_1_from(NfMappedElemIdx_x_out_idxRangeVec_1_from),
    .out_idxRangeVec_1_until(NfMappedElemIdx_x_out_idxRangeVec_1_until),
    .out_idxRangeVec_2_from(NfMappedElemIdx_x_out_idxRangeVec_2_from),
    .out_idxRangeVec_2_until(NfMappedElemIdx_x_out_idxRangeVec_2_until),
    .out_idxRangeVec_3_from(NfMappedElemIdx_x_out_idxRangeVec_3_from),
    .out_idxRangeVec_3_until(NfMappedElemIdx_x_out_idxRangeVec_3_until),
    .out_idxRangeVec_4_from(NfMappedElemIdx_x_out_idxRangeVec_4_from),
    .out_idxRangeVec_4_until(NfMappedElemIdx_x_out_idxRangeVec_4_until),
    .out_idxRangeVec_5_from(NfMappedElemIdx_x_out_idxRangeVec_5_from),
    .out_idxRangeVec_5_until(NfMappedElemIdx_x_out_idxRangeVec_5_until),
    .out_idxRangeVec_6_from(NfMappedElemIdx_x_out_idxRangeVec_6_from),
    .out_idxRangeVec_6_until(NfMappedElemIdx_x_out_idxRangeVec_6_until),
    .out_idxRangeVec_7_from(NfMappedElemIdx_x_out_idxRangeVec_7_from),
    .out_idxRangeVec_7_until(NfMappedElemIdx_x_out_idxRangeVec_7_until)
  );

  OverrideableQueue g_OverrideableQueue (
    .clock(clock),
    .reset(OverrideableQueue_reset),
    .io_in_valid(OverrideableQueue_io_in_valid),
    .io_in_bits_pht_index(OverrideableQueue_io_in_bits_pht_index),
    .io_in_bits_pht_tag(OverrideableQueue_io_in_bits_pht_tag),
    .io_in_bits_region_paddr(OverrideableQueue_io_in_bits_region_paddr),
    .io_in_bits_region_vaddr(OverrideableQueue_io_in_bits_region_vaddr),
    .io_in_bits_region_offset(OverrideableQueue_io_in_bits_region_offset),
    .io_out_ready(OverrideableQueue_io_out_ready),
    .io_out_valid(OverrideableQueue_g_io_out_valid),
    .io_out_bits_pht_index(OverrideableQueue_g_io_out_bits_pht_index),
    .io_out_bits_pht_tag(OverrideableQueue_g_io_out_bits_pht_tag),
    .io_out_bits_region_paddr(OverrideableQueue_g_io_out_bits_region_paddr),
    .io_out_bits_region_vaddr(OverrideableQueue_g_io_out_bits_region_vaddr),
    .io_out_bits_region_offset(OverrideableQueue_g_io_out_bits_region_offset)
  );
  OverrideableQueue_xs x_OverrideableQueue (
    .clock(clock),
    .reset(OverrideableQueue_reset),
    .io_in_valid(OverrideableQueue_io_in_valid),
    .io_in_bits_pht_index(OverrideableQueue_io_in_bits_pht_index),
    .io_in_bits_pht_tag(OverrideableQueue_io_in_bits_pht_tag),
    .io_in_bits_region_paddr(OverrideableQueue_io_in_bits_region_paddr),
    .io_in_bits_region_vaddr(OverrideableQueue_io_in_bits_region_vaddr),
    .io_in_bits_region_offset(OverrideableQueue_io_in_bits_region_offset),
    .io_out_ready(OverrideableQueue_io_out_ready),
    .io_out_valid(OverrideableQueue_x_io_out_valid),
    .io_out_bits_pht_index(OverrideableQueue_x_io_out_bits_pht_index),
    .io_out_bits_pht_tag(OverrideableQueue_x_io_out_bits_pht_tag),
    .io_out_bits_region_paddr(OverrideableQueue_x_io_out_bits_region_paddr),
    .io_out_bits_region_vaddr(OverrideableQueue_x_io_out_bits_region_vaddr),
    .io_out_bits_region_offset(OverrideableQueue_x_io_out_bits_region_offset)
  );

  OverrideableQueue_1 g_OverrideableQueue_1 (
    .clock(clock),
    .reset(OverrideableQueue_1_reset),
    .io_in_valid(OverrideableQueue_1_io_in_valid),
    .io_in_bits_pht_index(OverrideableQueue_1_io_in_bits_pht_index),
    .io_in_bits_pht_tag(OverrideableQueue_1_io_in_bits_pht_tag),
    .io_in_bits_region_bits(OverrideableQueue_1_io_in_bits_region_bits),
    .io_in_bits_region_bit_single(OverrideableQueue_1_io_in_bits_region_bit_single),
    .io_in_bits_region_offset(OverrideableQueue_1_io_in_bits_region_offset),
    .io_in_bits_access_cnt(OverrideableQueue_1_io_in_bits_access_cnt),
    .io_in_bits_decr_mode(OverrideableQueue_1_io_in_bits_decr_mode),
    .io_in_bits_single_update(OverrideableQueue_1_io_in_bits_single_update),
    .io_in_bits_has_been_signal_updated(OverrideableQueue_1_io_in_bits_has_been_signal_updated),
    .io_out_ready(OverrideableQueue_1_io_out_ready),
    .io_out_valid(OverrideableQueue_1_g_io_out_valid),
    .io_out_bits_pht_index(OverrideableQueue_1_g_io_out_bits_pht_index),
    .io_out_bits_pht_tag(OverrideableQueue_1_g_io_out_bits_pht_tag),
    .io_out_bits_region_bits(OverrideableQueue_1_g_io_out_bits_region_bits),
    .io_out_bits_region_bit_single(OverrideableQueue_1_g_io_out_bits_region_bit_single),
    .io_out_bits_region_offset(OverrideableQueue_1_g_io_out_bits_region_offset),
    .io_out_bits_access_cnt(OverrideableQueue_1_g_io_out_bits_access_cnt),
    .io_out_bits_decr_mode(OverrideableQueue_1_g_io_out_bits_decr_mode),
    .io_out_bits_single_update(OverrideableQueue_1_g_io_out_bits_single_update),
    .io_out_bits_has_been_signal_updated(OverrideableQueue_1_g_io_out_bits_has_been_signal_updated)
  );
  OverrideableQueue_1_xs x_OverrideableQueue_1 (
    .clock(clock),
    .reset(OverrideableQueue_1_reset),
    .io_in_valid(OverrideableQueue_1_io_in_valid),
    .io_in_bits_pht_index(OverrideableQueue_1_io_in_bits_pht_index),
    .io_in_bits_pht_tag(OverrideableQueue_1_io_in_bits_pht_tag),
    .io_in_bits_region_bits(OverrideableQueue_1_io_in_bits_region_bits),
    .io_in_bits_region_bit_single(OverrideableQueue_1_io_in_bits_region_bit_single),
    .io_in_bits_region_offset(OverrideableQueue_1_io_in_bits_region_offset),
    .io_in_bits_access_cnt(OverrideableQueue_1_io_in_bits_access_cnt),
    .io_in_bits_decr_mode(OverrideableQueue_1_io_in_bits_decr_mode),
    .io_in_bits_single_update(OverrideableQueue_1_io_in_bits_single_update),
    .io_in_bits_has_been_signal_updated(OverrideableQueue_1_io_in_bits_has_been_signal_updated),
    .io_out_ready(OverrideableQueue_1_io_out_ready),
    .io_out_valid(OverrideableQueue_1_x_io_out_valid),
    .io_out_bits_pht_index(OverrideableQueue_1_x_io_out_bits_pht_index),
    .io_out_bits_pht_tag(OverrideableQueue_1_x_io_out_bits_pht_tag),
    .io_out_bits_region_bits(OverrideableQueue_1_x_io_out_bits_region_bits),
    .io_out_bits_region_bit_single(OverrideableQueue_1_x_io_out_bits_region_bit_single),
    .io_out_bits_region_offset(OverrideableQueue_1_x_io_out_bits_region_offset),
    .io_out_bits_access_cnt(OverrideableQueue_1_x_io_out_bits_access_cnt),
    .io_out_bits_decr_mode(OverrideableQueue_1_x_io_out_bits_decr_mode),
    .io_out_bits_single_update(OverrideableQueue_1_x_io_out_bits_single_update),
    .io_out_bits_has_been_signal_updated(OverrideableQueue_1_x_io_out_bits_has_been_signal_updated)
  );

  PipelineRegModule_6 g_PipelineRegModule_6 (
    .clock(clock),
    .reset(PipelineRegModule_6_reset),
    .io_in_ready(PipelineRegModule_6_g_io_in_ready),
    .io_in_valid(PipelineRegModule_6_io_in_valid),
    .io_in_bits_data(PipelineRegModule_6_io_in_bits_data),
    .io_in_bits_id(PipelineRegModule_6_io_in_bits_id),
    .io_in_bits_nc(PipelineRegModule_6_io_in_bits_nc),
    .io_in_bits_is2lq(PipelineRegModule_6_io_in_bits_is2lq),
    .io_in_bits_denied(PipelineRegModule_6_io_in_bits_denied),
    .io_in_bits_corrupt(PipelineRegModule_6_io_in_bits_corrupt),
    .io_out_ready(PipelineRegModule_6_io_out_ready),
    .io_out_valid(PipelineRegModule_6_g_io_out_valid),
    .io_out_bits_data(PipelineRegModule_6_g_io_out_bits_data),
    .io_out_bits_id(PipelineRegModule_6_g_io_out_bits_id),
    .io_out_bits_nc(PipelineRegModule_6_g_io_out_bits_nc),
    .io_out_bits_is2lq(PipelineRegModule_6_g_io_out_bits_is2lq),
    .io_out_bits_denied(PipelineRegModule_6_g_io_out_bits_denied),
    .io_out_bits_corrupt(PipelineRegModule_6_g_io_out_bits_corrupt)
  );
  PipelineRegModule_6_xs x_PipelineRegModule_6 (
    .clock(clock),
    .reset(PipelineRegModule_6_reset),
    .io_in_ready(PipelineRegModule_6_x_io_in_ready),
    .io_in_valid(PipelineRegModule_6_io_in_valid),
    .io_in_bits_data(PipelineRegModule_6_io_in_bits_data),
    .io_in_bits_id(PipelineRegModule_6_io_in_bits_id),
    .io_in_bits_nc(PipelineRegModule_6_io_in_bits_nc),
    .io_in_bits_is2lq(PipelineRegModule_6_io_in_bits_is2lq),
    .io_in_bits_denied(PipelineRegModule_6_io_in_bits_denied),
    .io_in_bits_corrupt(PipelineRegModule_6_io_in_bits_corrupt),
    .io_out_ready(PipelineRegModule_6_io_out_ready),
    .io_out_valid(PipelineRegModule_6_x_io_out_valid),
    .io_out_bits_data(PipelineRegModule_6_x_io_out_bits_data),
    .io_out_bits_id(PipelineRegModule_6_x_io_out_bits_id),
    .io_out_bits_nc(PipelineRegModule_6_x_io_out_bits_nc),
    .io_out_bits_is2lq(PipelineRegModule_6_x_io_out_bits_is2lq),
    .io_out_bits_denied(PipelineRegModule_6_x_io_out_bits_denied),
    .io_out_bits_corrupt(PipelineRegModule_6_x_io_out_bits_corrupt)
  );

  SatpFlushMod g_SatpFlushMod (
    .clock(clock),
    .in_satp_valid(SatpFlushMod_in_satp_valid),
    .in_satp_bits(SatpFlushMod_in_satp_bits),
    .in_vsatp_valid(SatpFlushMod_in_vsatp_valid),
    .in_vsatp_bits(SatpFlushMod_in_vsatp_bits),
    .in_privState_PRVM(SatpFlushMod_in_privState_PRVM),
    .in_privState_V(SatpFlushMod_in_privState_V),
    .out_oldPrivState_PRVM(SatpFlushMod_g_out_oldPrivState_PRVM),
    .out_oldPrivState_V(SatpFlushMod_g_out_oldPrivState_V),
    .out_oldSatpMode(SatpFlushMod_g_out_oldSatpMode),
    .out_oldVsatpMode(SatpFlushMod_g_out_oldVsatpMode)
  );
  SatpFlushMod_xs x_SatpFlushMod (
    .clock(clock),
    .in_satp_valid(SatpFlushMod_in_satp_valid),
    .in_satp_bits(SatpFlushMod_in_satp_bits),
    .in_vsatp_valid(SatpFlushMod_in_vsatp_valid),
    .in_vsatp_bits(SatpFlushMod_in_vsatp_bits),
    .in_privState_PRVM(SatpFlushMod_in_privState_PRVM),
    .in_privState_V(SatpFlushMod_in_privState_V),
    .out_oldPrivState_PRVM(SatpFlushMod_x_out_oldPrivState_PRVM),
    .out_oldPrivState_V(SatpFlushMod_x_out_oldPrivState_V),
    .out_oldSatpMode(SatpFlushMod_x_out_oldSatpMode),
    .out_oldVsatpMode(SatpFlushMod_x_out_oldVsatpMode)
  );

  task automatic compare_outputs;
    begin
      checks = checks + 1;
      if ({Arbiter16_TLBundleD_g_io_in_0_ready, Arbiter16_TLBundleD_g_io_in_1_ready, Arbiter16_TLBundleD_g_io_in_2_ready, Arbiter16_TLBundleD_g_io_in_3_ready, Arbiter16_TLBundleD_g_io_in_4_ready, Arbiter16_TLBundleD_g_io_in_5_ready, Arbiter16_TLBundleD_g_io_in_6_ready, Arbiter16_TLBundleD_g_io_in_7_ready, Arbiter16_TLBundleD_g_io_in_8_ready, Arbiter16_TLBundleD_g_io_in_9_ready, Arbiter16_TLBundleD_g_io_in_10_ready, Arbiter16_TLBundleD_g_io_in_11_ready, Arbiter16_TLBundleD_g_io_in_12_ready, Arbiter16_TLBundleD_g_io_in_13_ready, Arbiter16_TLBundleD_g_io_in_14_ready, Arbiter16_TLBundleD_g_io_in_15_ready, Arbiter16_TLBundleD_g_io_out_valid, Arbiter16_TLBundleD_g_io_out_bits_opcode, Arbiter16_TLBundleD_g_io_out_bits_size, Arbiter16_TLBundleD_g_io_out_bits_source, Arbiter16_TLBundleD_g_io_out_bits_denied, Arbiter16_TLBundleD_g_io_out_bits_data, Arbiter16_TLBundleD_g_io_out_bits_corrupt} !== {Arbiter16_TLBundleD_x_io_in_0_ready, Arbiter16_TLBundleD_x_io_in_1_ready, Arbiter16_TLBundleD_x_io_in_2_ready, Arbiter16_TLBundleD_x_io_in_3_ready, Arbiter16_TLBundleD_x_io_in_4_ready, Arbiter16_TLBundleD_x_io_in_5_ready, Arbiter16_TLBundleD_x_io_in_6_ready, Arbiter16_TLBundleD_x_io_in_7_ready, Arbiter16_TLBundleD_x_io_in_8_ready, Arbiter16_TLBundleD_x_io_in_9_ready, Arbiter16_TLBundleD_x_io_in_10_ready, Arbiter16_TLBundleD_x_io_in_11_ready, Arbiter16_TLBundleD_x_io_in_12_ready, Arbiter16_TLBundleD_x_io_in_13_ready, Arbiter16_TLBundleD_x_io_in_14_ready, Arbiter16_TLBundleD_x_io_in_15_ready, Arbiter16_TLBundleD_x_io_out_valid, Arbiter16_TLBundleD_x_io_out_bits_opcode, Arbiter16_TLBundleD_x_io_out_bits_size, Arbiter16_TLBundleD_x_io_out_bits_source, Arbiter16_TLBundleD_x_io_out_bits_denied, Arbiter16_TLBundleD_x_io_out_bits_data, Arbiter16_TLBundleD_x_io_out_bits_corrupt}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Arbiter16_TLBundleD mismatch at cycle %0d", cycle);
      end
      if ({Arbiter3_PfGenReq_g_io_in_1_ready, Arbiter3_PfGenReq_g_io_in_2_ready, Arbiter3_PfGenReq_g_io_out_valid, Arbiter3_PfGenReq_g_io_out_bits_region_tag, Arbiter3_PfGenReq_g_io_out_bits_region_addr, Arbiter3_PfGenReq_g_io_out_bits_region_bits, Arbiter3_PfGenReq_g_io_out_bits_paddr_valid, Arbiter3_PfGenReq_g_io_out_bits_decr_mode} !== {Arbiter3_PfGenReq_x_io_in_1_ready, Arbiter3_PfGenReq_x_io_in_2_ready, Arbiter3_PfGenReq_x_io_out_valid, Arbiter3_PfGenReq_x_io_out_bits_region_tag, Arbiter3_PfGenReq_x_io_out_bits_region_addr, Arbiter3_PfGenReq_x_io_out_bits_region_bits, Arbiter3_PfGenReq_x_io_out_bits_paddr_valid, Arbiter3_PfGenReq_x_io_out_bits_decr_mode}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Arbiter3_PfGenReq mismatch at cycle %0d", cycle);
      end
      if ({Arbiter4_L2ToL1Hint_g_io_in_0_ready, Arbiter4_L2ToL1Hint_g_io_in_1_ready, Arbiter4_L2ToL1Hint_g_io_in_2_ready, Arbiter4_L2ToL1Hint_g_io_in_3_ready, Arbiter4_L2ToL1Hint_g_io_out_valid, Arbiter4_L2ToL1Hint_g_io_out_bits_sourceId, Arbiter4_L2ToL1Hint_g_io_out_bits_isKeyword, Arbiter4_L2ToL1Hint_g_io_chosen} !== {Arbiter4_L2ToL1Hint_x_io_in_0_ready, Arbiter4_L2ToL1Hint_x_io_in_1_ready, Arbiter4_L2ToL1Hint_x_io_in_2_ready, Arbiter4_L2ToL1Hint_x_io_in_3_ready, Arbiter4_L2ToL1Hint_x_io_out_valid, Arbiter4_L2ToL1Hint_x_io_out_bits_sourceId, Arbiter4_L2ToL1Hint_x_io_out_bits_isKeyword, Arbiter4_L2ToL1Hint_x_io_chosen}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Arbiter4_L2ToL1Hint mismatch at cycle %0d", cycle);
      end
      if ({Arbiter4_PrefetchReq_g_io_in_1_ready, Arbiter4_PrefetchReq_g_io_in_2_ready, Arbiter4_PrefetchReq_g_io_out_valid, Arbiter4_PrefetchReq_g_io_out_bits_tag, Arbiter4_PrefetchReq_g_io_out_bits_set, Arbiter4_PrefetchReq_g_io_out_bits_vaddr, Arbiter4_PrefetchReq_g_io_out_bits_needT, Arbiter4_PrefetchReq_g_io_out_bits_source, Arbiter4_PrefetchReq_g_io_out_bits_pfSource} !== {Arbiter4_PrefetchReq_x_io_in_1_ready, Arbiter4_PrefetchReq_x_io_in_2_ready, Arbiter4_PrefetchReq_x_io_out_valid, Arbiter4_PrefetchReq_x_io_out_bits_tag, Arbiter4_PrefetchReq_x_io_out_bits_set, Arbiter4_PrefetchReq_x_io_out_bits_vaddr, Arbiter4_PrefetchReq_x_io_out_bits_needT, Arbiter4_PrefetchReq_x_io_out_bits_source, Arbiter4_PrefetchReq_x_io_out_bits_pfSource}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Arbiter4_PrefetchReq mismatch at cycle %0d", cycle);
      end
      if ({CSA4to2_15_g_io_out_sum, CSA4to2_15_g_io_out_car} !== {CSA4to2_15_x_io_out_sum, CSA4to2_15_x_io_out_car}) begin
        errors = errors + 1;
        if (errors <= 8) $display("CSA4to2_15 mismatch at cycle %0d", cycle);
      end
      if ({MbistIntfFrontend_g_toPipeline_0_array, MbistIntfFrontend_g_toPipeline_0_all, MbistIntfFrontend_g_toPipeline_0_req, MbistIntfFrontend_g_toPipeline_0_writeen, MbistIntfFrontend_g_toPipeline_0_be, MbistIntfFrontend_g_toPipeline_0_addr, MbistIntfFrontend_g_toPipeline_0_indata, MbistIntfFrontend_g_toPipeline_0_readen, MbistIntfFrontend_g_toPipeline_0_addr_rd, MbistIntfFrontend_g_mbist_ack, MbistIntfFrontend_g_mbist_outdata} !== {MbistIntfFrontend_x_toPipeline_0_array, MbistIntfFrontend_x_toPipeline_0_all, MbistIntfFrontend_x_toPipeline_0_req, MbistIntfFrontend_x_toPipeline_0_writeen, MbistIntfFrontend_x_toPipeline_0_be, MbistIntfFrontend_x_toPipeline_0_addr, MbistIntfFrontend_x_toPipeline_0_indata, MbistIntfFrontend_x_toPipeline_0_readen, MbistIntfFrontend_x_toPipeline_0_addr_rd, MbistIntfFrontend_x_mbist_ack, MbistIntfFrontend_x_mbist_outdata}) begin
        errors = errors + 1;
        if (errors <= 8) $display("MbistIntfFrontend mismatch at cycle %0d", cycle);
      end
      if ({MbistIntfMemBlk_g_toPipeline_0_array, MbistIntfMemBlk_g_toPipeline_0_all, MbistIntfMemBlk_g_toPipeline_0_req, MbistIntfMemBlk_g_toPipeline_0_writeen, MbistIntfMemBlk_g_toPipeline_0_be, MbistIntfMemBlk_g_toPipeline_0_addr, MbistIntfMemBlk_g_toPipeline_0_indata, MbistIntfMemBlk_g_toPipeline_0_readen, MbistIntfMemBlk_g_toPipeline_0_addr_rd, MbistIntfMemBlk_g_mbist_ack, MbistIntfMemBlk_g_mbist_outdata} !== {MbistIntfMemBlk_x_toPipeline_0_array, MbistIntfMemBlk_x_toPipeline_0_all, MbistIntfMemBlk_x_toPipeline_0_req, MbistIntfMemBlk_x_toPipeline_0_writeen, MbistIntfMemBlk_x_toPipeline_0_be, MbistIntfMemBlk_x_toPipeline_0_addr, MbistIntfMemBlk_x_toPipeline_0_indata, MbistIntfMemBlk_x_toPipeline_0_readen, MbistIntfMemBlk_x_toPipeline_0_addr_rd, MbistIntfMemBlk_x_mbist_ack, MbistIntfMemBlk_x_mbist_outdata}) begin
        errors = errors + 1;
        if (errors <= 8) $display("MbistIntfMemBlk mismatch at cycle %0d", cycle);
      end
      if ({NfMappedElemIdx_g_out_idxRangeVec_0_from, NfMappedElemIdx_g_out_idxRangeVec_0_until, NfMappedElemIdx_g_out_idxRangeVec_1_from, NfMappedElemIdx_g_out_idxRangeVec_1_until, NfMappedElemIdx_g_out_idxRangeVec_2_from, NfMappedElemIdx_g_out_idxRangeVec_2_until, NfMappedElemIdx_g_out_idxRangeVec_3_from, NfMappedElemIdx_g_out_idxRangeVec_3_until, NfMappedElemIdx_g_out_idxRangeVec_4_from, NfMappedElemIdx_g_out_idxRangeVec_4_until, NfMappedElemIdx_g_out_idxRangeVec_5_from, NfMappedElemIdx_g_out_idxRangeVec_5_until, NfMappedElemIdx_g_out_idxRangeVec_6_from, NfMappedElemIdx_g_out_idxRangeVec_6_until, NfMappedElemIdx_g_out_idxRangeVec_7_from, NfMappedElemIdx_g_out_idxRangeVec_7_until} !== {NfMappedElemIdx_x_out_idxRangeVec_0_from, NfMappedElemIdx_x_out_idxRangeVec_0_until, NfMappedElemIdx_x_out_idxRangeVec_1_from, NfMappedElemIdx_x_out_idxRangeVec_1_until, NfMappedElemIdx_x_out_idxRangeVec_2_from, NfMappedElemIdx_x_out_idxRangeVec_2_until, NfMappedElemIdx_x_out_idxRangeVec_3_from, NfMappedElemIdx_x_out_idxRangeVec_3_until, NfMappedElemIdx_x_out_idxRangeVec_4_from, NfMappedElemIdx_x_out_idxRangeVec_4_until, NfMappedElemIdx_x_out_idxRangeVec_5_from, NfMappedElemIdx_x_out_idxRangeVec_5_until, NfMappedElemIdx_x_out_idxRangeVec_6_from, NfMappedElemIdx_x_out_idxRangeVec_6_until, NfMappedElemIdx_x_out_idxRangeVec_7_from, NfMappedElemIdx_x_out_idxRangeVec_7_until}) begin
        errors = errors + 1;
        if (errors <= 8) $display("NfMappedElemIdx mismatch at cycle %0d", cycle);
      end
      if ({OverrideableQueue_g_io_out_valid, OverrideableQueue_g_io_out_bits_pht_index, OverrideableQueue_g_io_out_bits_pht_tag, OverrideableQueue_g_io_out_bits_region_paddr, OverrideableQueue_g_io_out_bits_region_vaddr, OverrideableQueue_g_io_out_bits_region_offset} !== {OverrideableQueue_x_io_out_valid, OverrideableQueue_x_io_out_bits_pht_index, OverrideableQueue_x_io_out_bits_pht_tag, OverrideableQueue_x_io_out_bits_region_paddr, OverrideableQueue_x_io_out_bits_region_vaddr, OverrideableQueue_x_io_out_bits_region_offset}) begin
        errors = errors + 1;
        if (errors <= 8) $display("OverrideableQueue mismatch at cycle %0d", cycle);
      end
      if ({OverrideableQueue_1_g_io_out_valid, OverrideableQueue_1_g_io_out_bits_pht_index, OverrideableQueue_1_g_io_out_bits_pht_tag, OverrideableQueue_1_g_io_out_bits_region_bits, OverrideableQueue_1_g_io_out_bits_region_bit_single, OverrideableQueue_1_g_io_out_bits_region_offset, OverrideableQueue_1_g_io_out_bits_access_cnt, OverrideableQueue_1_g_io_out_bits_decr_mode, OverrideableQueue_1_g_io_out_bits_single_update, OverrideableQueue_1_g_io_out_bits_has_been_signal_updated} !== {OverrideableQueue_1_x_io_out_valid, OverrideableQueue_1_x_io_out_bits_pht_index, OverrideableQueue_1_x_io_out_bits_pht_tag, OverrideableQueue_1_x_io_out_bits_region_bits, OverrideableQueue_1_x_io_out_bits_region_bit_single, OverrideableQueue_1_x_io_out_bits_region_offset, OverrideableQueue_1_x_io_out_bits_access_cnt, OverrideableQueue_1_x_io_out_bits_decr_mode, OverrideableQueue_1_x_io_out_bits_single_update, OverrideableQueue_1_x_io_out_bits_has_been_signal_updated}) begin
        errors = errors + 1;
        if (errors <= 8) $display("OverrideableQueue_1 mismatch at cycle %0d", cycle);
      end
      if ({PipelineRegModule_6_g_io_in_ready, PipelineRegModule_6_g_io_out_valid, PipelineRegModule_6_g_io_out_bits_data, PipelineRegModule_6_g_io_out_bits_id, PipelineRegModule_6_g_io_out_bits_nc, PipelineRegModule_6_g_io_out_bits_is2lq, PipelineRegModule_6_g_io_out_bits_denied, PipelineRegModule_6_g_io_out_bits_corrupt} !== {PipelineRegModule_6_x_io_in_ready, PipelineRegModule_6_x_io_out_valid, PipelineRegModule_6_x_io_out_bits_data, PipelineRegModule_6_x_io_out_bits_id, PipelineRegModule_6_x_io_out_bits_nc, PipelineRegModule_6_x_io_out_bits_is2lq, PipelineRegModule_6_x_io_out_bits_denied, PipelineRegModule_6_x_io_out_bits_corrupt}) begin
        errors = errors + 1;
        if (errors <= 8) $display("PipelineRegModule_6 mismatch at cycle %0d", cycle);
      end
      if ({SatpFlushMod_g_out_oldPrivState_PRVM, SatpFlushMod_g_out_oldPrivState_V, SatpFlushMod_g_out_oldSatpMode, SatpFlushMod_g_out_oldVsatpMode} !== {SatpFlushMod_x_out_oldPrivState_PRVM, SatpFlushMod_x_out_oldPrivState_V, SatpFlushMod_x_out_oldSatpMode, SatpFlushMod_x_out_oldVsatpMode}) begin
        errors = errors + 1;
        if (errors <= 8) $display("SatpFlushMod mismatch at cycle %0d", cycle);
      end
    end
  endtask

  task automatic drive_inputs;
    begin
      Arbiter16_TLBundleD_io_in_0_valid = $urandom;
      Arbiter16_TLBundleD_io_in_0_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_0_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_0_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_0_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_0_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_0_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_1_valid = $urandom;
      Arbiter16_TLBundleD_io_in_1_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_1_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_1_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_1_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_1_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_1_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_2_valid = $urandom;
      Arbiter16_TLBundleD_io_in_2_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_2_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_2_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_2_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_2_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_2_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_3_valid = $urandom;
      Arbiter16_TLBundleD_io_in_3_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_3_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_3_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_3_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_3_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_3_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_4_valid = $urandom;
      Arbiter16_TLBundleD_io_in_4_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_4_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_4_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_4_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_4_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_4_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_5_valid = $urandom;
      Arbiter16_TLBundleD_io_in_5_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_5_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_5_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_5_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_5_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_5_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_6_valid = $urandom;
      Arbiter16_TLBundleD_io_in_6_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_6_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_6_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_6_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_6_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_6_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_7_valid = $urandom;
      Arbiter16_TLBundleD_io_in_7_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_7_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_7_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_7_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_7_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_7_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_8_valid = $urandom;
      Arbiter16_TLBundleD_io_in_8_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_8_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_8_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_8_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_8_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_8_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_9_valid = $urandom;
      Arbiter16_TLBundleD_io_in_9_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_9_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_9_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_9_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_9_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_9_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_10_valid = $urandom;
      Arbiter16_TLBundleD_io_in_10_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_10_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_10_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_10_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_10_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_10_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_11_valid = $urandom;
      Arbiter16_TLBundleD_io_in_11_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_11_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_11_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_11_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_11_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_11_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_12_valid = $urandom;
      Arbiter16_TLBundleD_io_in_12_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_12_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_12_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_12_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_12_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_12_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_13_valid = $urandom;
      Arbiter16_TLBundleD_io_in_13_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_13_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_13_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_13_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_13_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_13_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_14_valid = $urandom;
      Arbiter16_TLBundleD_io_in_14_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_14_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_14_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_14_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_14_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_14_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_in_15_valid = $urandom;
      Arbiter16_TLBundleD_io_in_15_bits_opcode = $urandom;
      Arbiter16_TLBundleD_io_in_15_bits_size = $urandom;
      Arbiter16_TLBundleD_io_in_15_bits_source = $urandom;
      Arbiter16_TLBundleD_io_in_15_bits_denied = $urandom;
      Arbiter16_TLBundleD_io_in_15_bits_data = {$urandom, $urandom};
      Arbiter16_TLBundleD_io_in_15_bits_corrupt = $urandom;
      Arbiter16_TLBundleD_io_out_ready = $urandom;
      Arbiter3_PfGenReq_io_in_0_valid = $urandom;
      Arbiter3_PfGenReq_io_in_0_bits_region_tag = $urandom;
      Arbiter3_PfGenReq_io_in_0_bits_region_addr = {$urandom, $urandom};
      Arbiter3_PfGenReq_io_in_0_bits_region_bits = $urandom;
      Arbiter3_PfGenReq_io_in_1_valid = $urandom;
      Arbiter3_PfGenReq_io_in_1_bits_region_tag = $urandom;
      Arbiter3_PfGenReq_io_in_1_bits_region_addr = {$urandom, $urandom};
      Arbiter3_PfGenReq_io_in_1_bits_region_bits = $urandom;
      Arbiter3_PfGenReq_io_in_1_bits_paddr_valid = $urandom;
      Arbiter3_PfGenReq_io_in_2_valid = $urandom;
      Arbiter3_PfGenReq_io_in_2_bits_region_tag = $urandom;
      Arbiter3_PfGenReq_io_in_2_bits_region_addr = {$urandom, $urandom};
      Arbiter3_PfGenReq_io_in_2_bits_region_bits = $urandom;
      Arbiter3_PfGenReq_io_in_2_bits_paddr_valid = $urandom;
      Arbiter4_L2ToL1Hint_io_in_0_valid = $urandom;
      Arbiter4_L2ToL1Hint_io_in_0_bits_sourceId = $urandom;
      Arbiter4_L2ToL1Hint_io_in_0_bits_isKeyword = $urandom;
      Arbiter4_L2ToL1Hint_io_in_1_valid = $urandom;
      Arbiter4_L2ToL1Hint_io_in_1_bits_sourceId = $urandom;
      Arbiter4_L2ToL1Hint_io_in_1_bits_isKeyword = $urandom;
      Arbiter4_L2ToL1Hint_io_in_2_valid = $urandom;
      Arbiter4_L2ToL1Hint_io_in_2_bits_sourceId = $urandom;
      Arbiter4_L2ToL1Hint_io_in_2_bits_isKeyword = $urandom;
      Arbiter4_L2ToL1Hint_io_in_3_valid = $urandom;
      Arbiter4_L2ToL1Hint_io_in_3_bits_sourceId = $urandom;
      Arbiter4_L2ToL1Hint_io_in_3_bits_isKeyword = $urandom;
      Arbiter4_L2ToL1Hint_io_out_ready = $urandom;
      Arbiter4_PrefetchReq_io_in_0_valid = $urandom;
      Arbiter4_PrefetchReq_io_in_0_bits_tag = {$urandom, $urandom};
      Arbiter4_PrefetchReq_io_in_0_bits_set = $urandom;
      Arbiter4_PrefetchReq_io_in_0_bits_pfSource = $urandom;
      Arbiter4_PrefetchReq_io_in_1_valid = $urandom;
      Arbiter4_PrefetchReq_io_in_1_bits_tag = {$urandom, $urandom};
      Arbiter4_PrefetchReq_io_in_1_bits_set = $urandom;
      Arbiter4_PrefetchReq_io_in_1_bits_vaddr = {$urandom, $urandom};
      Arbiter4_PrefetchReq_io_in_1_bits_needT = $urandom;
      Arbiter4_PrefetchReq_io_in_1_bits_source = $urandom;
      Arbiter4_PrefetchReq_io_in_2_valid = $urandom;
      Arbiter4_PrefetchReq_io_in_2_bits_tag = {$urandom, $urandom};
      Arbiter4_PrefetchReq_io_in_2_bits_set = $urandom;
      Arbiter4_PrefetchReq_io_in_2_bits_vaddr = {$urandom, $urandom};
      Arbiter4_PrefetchReq_io_in_2_bits_needT = $urandom;
      Arbiter4_PrefetchReq_io_in_2_bits_source = $urandom;
      CSA4to2_15_io_in_a = $urandom;
      CSA4to2_15_io_in_b = $urandom;
      CSA4to2_15_io_in_c = $urandom;
      CSA4to2_15_io_in_d = $urandom;
      MbistIntfFrontend_toPipeline_0_ack = $urandom;
      MbistIntfFrontend_toPipeline_0_outdata = {$urandom, $urandom, $urandom};
      MbistIntfFrontend_mbist_array = $urandom;
      MbistIntfFrontend_mbist_all = $urandom;
      MbistIntfFrontend_mbist_req = $urandom;
      MbistIntfFrontend_mbist_writeen = $urandom;
      MbistIntfFrontend_mbist_be = {$urandom, $urandom, $urandom};
      MbistIntfFrontend_mbist_addr = $urandom;
      MbistIntfFrontend_mbist_indata = {$urandom, $urandom, $urandom};
      MbistIntfFrontend_mbist_readen = $urandom;
      MbistIntfFrontend_mbist_addr_rd = $urandom;
      MbistIntfMemBlk_toPipeline_0_ack = $urandom;
      MbistIntfMemBlk_toPipeline_0_outdata = {$urandom, $urandom, $urandom, $urandom, $urandom};
      MbistIntfMemBlk_mbist_array = $urandom;
      MbistIntfMemBlk_mbist_all = $urandom;
      MbistIntfMemBlk_mbist_req = $urandom;
      MbistIntfMemBlk_mbist_writeen = $urandom;
      MbistIntfMemBlk_mbist_be = $urandom;
      MbistIntfMemBlk_mbist_addr = $urandom;
      MbistIntfMemBlk_mbist_indata = {$urandom, $urandom, $urandom, $urandom, $urandom};
      MbistIntfMemBlk_mbist_readen = $urandom;
      MbistIntfMemBlk_mbist_addr_rd = $urandom;
      NfMappedElemIdx_in_nf = $urandom;
      NfMappedElemIdx_in_eewOH = $urandom;
      OverrideableQueue_io_in_valid = $urandom;
      OverrideableQueue_io_in_bits_pht_index = $urandom;
      OverrideableQueue_io_in_bits_pht_tag = $urandom;
      OverrideableQueue_io_in_bits_region_paddr = {$urandom, $urandom};
      OverrideableQueue_io_in_bits_region_vaddr = {$urandom, $urandom};
      OverrideableQueue_io_in_bits_region_offset = $urandom;
      OverrideableQueue_io_out_ready = $urandom;
      OverrideableQueue_1_io_in_valid = $urandom;
      OverrideableQueue_1_io_in_bits_pht_index = $urandom;
      OverrideableQueue_1_io_in_bits_pht_tag = $urandom;
      OverrideableQueue_1_io_in_bits_region_bits = $urandom;
      OverrideableQueue_1_io_in_bits_region_bit_single = $urandom;
      OverrideableQueue_1_io_in_bits_region_offset = $urandom;
      OverrideableQueue_1_io_in_bits_access_cnt = $urandom;
      OverrideableQueue_1_io_in_bits_decr_mode = $urandom;
      OverrideableQueue_1_io_in_bits_single_update = $urandom;
      OverrideableQueue_1_io_in_bits_has_been_signal_updated = $urandom;
      OverrideableQueue_1_io_out_ready = $urandom;
      PipelineRegModule_6_io_in_valid = $urandom;
      PipelineRegModule_6_io_in_bits_data = {$urandom, $urandom};
      PipelineRegModule_6_io_in_bits_id = $urandom;
      PipelineRegModule_6_io_in_bits_nc = $urandom;
      PipelineRegModule_6_io_in_bits_is2lq = $urandom;
      PipelineRegModule_6_io_in_bits_denied = $urandom;
      PipelineRegModule_6_io_in_bits_corrupt = $urandom;
      PipelineRegModule_6_io_out_ready = $urandom;
      SatpFlushMod_in_satp_valid = $urandom;
      SatpFlushMod_in_satp_bits = $urandom;
      SatpFlushMod_in_vsatp_valid = $urandom;
      SatpFlushMod_in_vsatp_bits = $urandom;
      SatpFlushMod_in_privState_PRVM = $urandom;
      SatpFlushMod_in_privState_V = $urandom;
    end
  endtask

  task automatic zero_inputs;
    begin
      Arbiter16_TLBundleD_io_in_0_valid = '0;
      Arbiter16_TLBundleD_io_in_0_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_0_bits_size = '0;
      Arbiter16_TLBundleD_io_in_0_bits_source = '0;
      Arbiter16_TLBundleD_io_in_0_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_0_bits_data = '0;
      Arbiter16_TLBundleD_io_in_0_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_1_valid = '0;
      Arbiter16_TLBundleD_io_in_1_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_1_bits_size = '0;
      Arbiter16_TLBundleD_io_in_1_bits_source = '0;
      Arbiter16_TLBundleD_io_in_1_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_1_bits_data = '0;
      Arbiter16_TLBundleD_io_in_1_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_2_valid = '0;
      Arbiter16_TLBundleD_io_in_2_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_2_bits_size = '0;
      Arbiter16_TLBundleD_io_in_2_bits_source = '0;
      Arbiter16_TLBundleD_io_in_2_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_2_bits_data = '0;
      Arbiter16_TLBundleD_io_in_2_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_3_valid = '0;
      Arbiter16_TLBundleD_io_in_3_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_3_bits_size = '0;
      Arbiter16_TLBundleD_io_in_3_bits_source = '0;
      Arbiter16_TLBundleD_io_in_3_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_3_bits_data = '0;
      Arbiter16_TLBundleD_io_in_3_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_4_valid = '0;
      Arbiter16_TLBundleD_io_in_4_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_4_bits_size = '0;
      Arbiter16_TLBundleD_io_in_4_bits_source = '0;
      Arbiter16_TLBundleD_io_in_4_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_4_bits_data = '0;
      Arbiter16_TLBundleD_io_in_4_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_5_valid = '0;
      Arbiter16_TLBundleD_io_in_5_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_5_bits_size = '0;
      Arbiter16_TLBundleD_io_in_5_bits_source = '0;
      Arbiter16_TLBundleD_io_in_5_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_5_bits_data = '0;
      Arbiter16_TLBundleD_io_in_5_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_6_valid = '0;
      Arbiter16_TLBundleD_io_in_6_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_6_bits_size = '0;
      Arbiter16_TLBundleD_io_in_6_bits_source = '0;
      Arbiter16_TLBundleD_io_in_6_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_6_bits_data = '0;
      Arbiter16_TLBundleD_io_in_6_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_7_valid = '0;
      Arbiter16_TLBundleD_io_in_7_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_7_bits_size = '0;
      Arbiter16_TLBundleD_io_in_7_bits_source = '0;
      Arbiter16_TLBundleD_io_in_7_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_7_bits_data = '0;
      Arbiter16_TLBundleD_io_in_7_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_8_valid = '0;
      Arbiter16_TLBundleD_io_in_8_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_8_bits_size = '0;
      Arbiter16_TLBundleD_io_in_8_bits_source = '0;
      Arbiter16_TLBundleD_io_in_8_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_8_bits_data = '0;
      Arbiter16_TLBundleD_io_in_8_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_9_valid = '0;
      Arbiter16_TLBundleD_io_in_9_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_9_bits_size = '0;
      Arbiter16_TLBundleD_io_in_9_bits_source = '0;
      Arbiter16_TLBundleD_io_in_9_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_9_bits_data = '0;
      Arbiter16_TLBundleD_io_in_9_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_10_valid = '0;
      Arbiter16_TLBundleD_io_in_10_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_10_bits_size = '0;
      Arbiter16_TLBundleD_io_in_10_bits_source = '0;
      Arbiter16_TLBundleD_io_in_10_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_10_bits_data = '0;
      Arbiter16_TLBundleD_io_in_10_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_11_valid = '0;
      Arbiter16_TLBundleD_io_in_11_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_11_bits_size = '0;
      Arbiter16_TLBundleD_io_in_11_bits_source = '0;
      Arbiter16_TLBundleD_io_in_11_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_11_bits_data = '0;
      Arbiter16_TLBundleD_io_in_11_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_12_valid = '0;
      Arbiter16_TLBundleD_io_in_12_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_12_bits_size = '0;
      Arbiter16_TLBundleD_io_in_12_bits_source = '0;
      Arbiter16_TLBundleD_io_in_12_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_12_bits_data = '0;
      Arbiter16_TLBundleD_io_in_12_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_13_valid = '0;
      Arbiter16_TLBundleD_io_in_13_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_13_bits_size = '0;
      Arbiter16_TLBundleD_io_in_13_bits_source = '0;
      Arbiter16_TLBundleD_io_in_13_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_13_bits_data = '0;
      Arbiter16_TLBundleD_io_in_13_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_14_valid = '0;
      Arbiter16_TLBundleD_io_in_14_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_14_bits_size = '0;
      Arbiter16_TLBundleD_io_in_14_bits_source = '0;
      Arbiter16_TLBundleD_io_in_14_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_14_bits_data = '0;
      Arbiter16_TLBundleD_io_in_14_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_in_15_valid = '0;
      Arbiter16_TLBundleD_io_in_15_bits_opcode = '0;
      Arbiter16_TLBundleD_io_in_15_bits_size = '0;
      Arbiter16_TLBundleD_io_in_15_bits_source = '0;
      Arbiter16_TLBundleD_io_in_15_bits_denied = '0;
      Arbiter16_TLBundleD_io_in_15_bits_data = '0;
      Arbiter16_TLBundleD_io_in_15_bits_corrupt = '0;
      Arbiter16_TLBundleD_io_out_ready = '0;
      Arbiter3_PfGenReq_io_in_0_valid = '0;
      Arbiter3_PfGenReq_io_in_0_bits_region_tag = '0;
      Arbiter3_PfGenReq_io_in_0_bits_region_addr = '0;
      Arbiter3_PfGenReq_io_in_0_bits_region_bits = '0;
      Arbiter3_PfGenReq_io_in_1_valid = '0;
      Arbiter3_PfGenReq_io_in_1_bits_region_tag = '0;
      Arbiter3_PfGenReq_io_in_1_bits_region_addr = '0;
      Arbiter3_PfGenReq_io_in_1_bits_region_bits = '0;
      Arbiter3_PfGenReq_io_in_1_bits_paddr_valid = '0;
      Arbiter3_PfGenReq_io_in_2_valid = '0;
      Arbiter3_PfGenReq_io_in_2_bits_region_tag = '0;
      Arbiter3_PfGenReq_io_in_2_bits_region_addr = '0;
      Arbiter3_PfGenReq_io_in_2_bits_region_bits = '0;
      Arbiter3_PfGenReq_io_in_2_bits_paddr_valid = '0;
      Arbiter4_L2ToL1Hint_io_in_0_valid = '0;
      Arbiter4_L2ToL1Hint_io_in_0_bits_sourceId = '0;
      Arbiter4_L2ToL1Hint_io_in_0_bits_isKeyword = '0;
      Arbiter4_L2ToL1Hint_io_in_1_valid = '0;
      Arbiter4_L2ToL1Hint_io_in_1_bits_sourceId = '0;
      Arbiter4_L2ToL1Hint_io_in_1_bits_isKeyword = '0;
      Arbiter4_L2ToL1Hint_io_in_2_valid = '0;
      Arbiter4_L2ToL1Hint_io_in_2_bits_sourceId = '0;
      Arbiter4_L2ToL1Hint_io_in_2_bits_isKeyword = '0;
      Arbiter4_L2ToL1Hint_io_in_3_valid = '0;
      Arbiter4_L2ToL1Hint_io_in_3_bits_sourceId = '0;
      Arbiter4_L2ToL1Hint_io_in_3_bits_isKeyword = '0;
      Arbiter4_L2ToL1Hint_io_out_ready = '0;
      Arbiter4_PrefetchReq_io_in_0_valid = '0;
      Arbiter4_PrefetchReq_io_in_0_bits_tag = '0;
      Arbiter4_PrefetchReq_io_in_0_bits_set = '0;
      Arbiter4_PrefetchReq_io_in_0_bits_pfSource = '0;
      Arbiter4_PrefetchReq_io_in_1_valid = '0;
      Arbiter4_PrefetchReq_io_in_1_bits_tag = '0;
      Arbiter4_PrefetchReq_io_in_1_bits_set = '0;
      Arbiter4_PrefetchReq_io_in_1_bits_vaddr = '0;
      Arbiter4_PrefetchReq_io_in_1_bits_needT = '0;
      Arbiter4_PrefetchReq_io_in_1_bits_source = '0;
      Arbiter4_PrefetchReq_io_in_2_valid = '0;
      Arbiter4_PrefetchReq_io_in_2_bits_tag = '0;
      Arbiter4_PrefetchReq_io_in_2_bits_set = '0;
      Arbiter4_PrefetchReq_io_in_2_bits_vaddr = '0;
      Arbiter4_PrefetchReq_io_in_2_bits_needT = '0;
      Arbiter4_PrefetchReq_io_in_2_bits_source = '0;
      CSA4to2_15_io_in_a = '0;
      CSA4to2_15_io_in_b = '0;
      CSA4to2_15_io_in_c = '0;
      CSA4to2_15_io_in_d = '0;
      MbistIntfFrontend_toPipeline_0_ack = '0;
      MbistIntfFrontend_toPipeline_0_outdata = '0;
      MbistIntfFrontend_mbist_array = '0;
      MbistIntfFrontend_mbist_all = '0;
      MbistIntfFrontend_mbist_req = '0;
      MbistIntfFrontend_mbist_writeen = '0;
      MbistIntfFrontend_mbist_be = '0;
      MbistIntfFrontend_mbist_addr = '0;
      MbistIntfFrontend_mbist_indata = '0;
      MbistIntfFrontend_mbist_readen = '0;
      MbistIntfFrontend_mbist_addr_rd = '0;
      MbistIntfMemBlk_toPipeline_0_ack = '0;
      MbistIntfMemBlk_toPipeline_0_outdata = '0;
      MbistIntfMemBlk_mbist_array = '0;
      MbistIntfMemBlk_mbist_all = '0;
      MbistIntfMemBlk_mbist_req = '0;
      MbistIntfMemBlk_mbist_writeen = '0;
      MbistIntfMemBlk_mbist_be = '0;
      MbistIntfMemBlk_mbist_addr = '0;
      MbistIntfMemBlk_mbist_indata = '0;
      MbistIntfMemBlk_mbist_readen = '0;
      MbistIntfMemBlk_mbist_addr_rd = '0;
      NfMappedElemIdx_in_nf = '0;
      NfMappedElemIdx_in_eewOH = '0;
      OverrideableQueue_reset = '0;
      OverrideableQueue_io_in_valid = '0;
      OverrideableQueue_io_in_bits_pht_index = '0;
      OverrideableQueue_io_in_bits_pht_tag = '0;
      OverrideableQueue_io_in_bits_region_paddr = '0;
      OverrideableQueue_io_in_bits_region_vaddr = '0;
      OverrideableQueue_io_in_bits_region_offset = '0;
      OverrideableQueue_io_out_ready = '0;
      OverrideableQueue_1_reset = '0;
      OverrideableQueue_1_io_in_valid = '0;
      OverrideableQueue_1_io_in_bits_pht_index = '0;
      OverrideableQueue_1_io_in_bits_pht_tag = '0;
      OverrideableQueue_1_io_in_bits_region_bits = '0;
      OverrideableQueue_1_io_in_bits_region_bit_single = '0;
      OverrideableQueue_1_io_in_bits_region_offset = '0;
      OverrideableQueue_1_io_in_bits_access_cnt = '0;
      OverrideableQueue_1_io_in_bits_decr_mode = '0;
      OverrideableQueue_1_io_in_bits_single_update = '0;
      OverrideableQueue_1_io_in_bits_has_been_signal_updated = '0;
      OverrideableQueue_1_io_out_ready = '0;
      PipelineRegModule_6_reset = '0;
      PipelineRegModule_6_io_in_valid = '0;
      PipelineRegModule_6_io_in_bits_data = '0;
      PipelineRegModule_6_io_in_bits_id = '0;
      PipelineRegModule_6_io_in_bits_nc = '0;
      PipelineRegModule_6_io_in_bits_is2lq = '0;
      PipelineRegModule_6_io_in_bits_denied = '0;
      PipelineRegModule_6_io_in_bits_corrupt = '0;
      PipelineRegModule_6_io_out_ready = '0;
      SatpFlushMod_in_satp_valid = '0;
      SatpFlushMod_in_satp_bits = '0;
      SatpFlushMod_in_vsatp_valid = '0;
      SatpFlushMod_in_vsatp_bits = '0;
      SatpFlushMod_in_privState_PRVM = '0;
      SatpFlushMod_in_privState_V = '0;
    end
  endtask

  task automatic bias_inputs;
    begin
      if ($urandom % 4 == 0) begin
        Arbiter16_TLBundleD_io_in_0_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_1_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_2_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_3_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_4_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_5_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_6_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_7_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_8_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_9_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_10_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_11_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_12_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_13_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_14_valid = ($urandom % 16 == 0);
        Arbiter16_TLBundleD_io_in_15_valid = ($urandom % 16 == 0);
      end
    end
  endtask

  task automatic sample_coverage;
    begin
      if (PipelineRegModule_6_reset && PipelineRegModule_6_io_in_valid && g_PipelineRegModule_6.io_in_ready)
        cov_preg_fire_in_reset = cov_preg_fire_in_reset + 1;
      if (!PipelineRegModule_6_reset && g_PipelineRegModule_6.io_out_valid && !PipelineRegModule_6_io_out_ready)
        cov_preg_stall = cov_preg_stall + 1;
      if (!OverrideableQueue_reset && OverrideableQueue_io_in_valid &&
          g_OverrideableQueue.valids_0 && g_OverrideableQueue.valids_1 &&
          g_OverrideableQueue.valids_2 && g_OverrideableQueue.valids_3)
        cov_oq_overwrite = cov_oq_overwrite + 1;
      if (!OverrideableQueue_reset && OverrideableQueue_io_in_valid && OverrideableQueue_io_out_ready &&
          g_OverrideableQueue.io_out_valid && g_OverrideableQueue.wr_ptr == g_OverrideableQueue.rd_ptr)
        cov_oq_same_slot_rw = cov_oq_same_slot_rw + 1;
      if (!OverrideableQueue_1_reset && OverrideableQueue_1_io_in_valid &&
          g_OverrideableQueue_1.valids_0 && g_OverrideableQueue_1.valids_1 &&
          g_OverrideableQueue_1.valids_2 && g_OverrideableQueue_1.valids_3)
        cov_oq1_overwrite = cov_oq1_overwrite + 1;
      if (!OverrideableQueue_1_reset && g_OverrideableQueue_1.io_out_valid && OverrideableQueue_1_io_out_ready)
        cov_oq1_deq = cov_oq1_deq + 1;
      if (Arbiter16_TLBundleD_io_out_ready && Arbiter16_TLBundleD_io_in_15_valid && g_Arbiter16_TLBundleD.io_in_15_ready)
        cov_a16_win15 = cov_a16_win15 + 1;
      if (!g_Arbiter16_TLBundleD.io_out_valid)
        cov_a16_idle = cov_a16_idle + 1;
      if (Arbiter3_PfGenReq_io_in_2_valid && g_Arbiter3_PfGenReq.io_in_2_ready)
        cov_pfgen_lane2 = cov_pfgen_lane2 + 1;
      if (!g_Arbiter4_PrefetchReq.io_out_valid)
        cov_pfreq_idle = cov_pfreq_idle + 1;
      if (g_Arbiter4_L2ToL1Hint.io_chosen == 2'd3 && Arbiter4_L2ToL1Hint_io_in_3_valid)
        cov_hint_lane3 = cov_hint_lane3 + 1;
      if (SatpFlushMod_in_satp_valid || SatpFlushMod_in_vsatp_valid)
        cov_satp_wen = cov_satp_wen + 1;
    end
  endtask

  initial begin
    zero_inputs();
    OverrideableQueue_reset = 1'b1;
    OverrideableQueue_1_reset = 1'b1;
    PipelineRegModule_6_reset = 1'b1;
    repeat (2) @(posedge clock);
    #1;
    OverrideableQueue_reset = 1'b0;
    OverrideableQueue_1_reset = 1'b0;
    PipelineRegModule_6_reset = 1'b0;
    // ---- warm-up: write all non-reset state on both sides, no comparison ----
    repeat (8) begin
      @(negedge clock);
      drive_inputs();
      OverrideableQueue_io_in_valid = 1'b1;
      OverrideableQueue_io_out_ready = 1'b0;
      OverrideableQueue_1_io_in_valid = 1'b1;
      OverrideableQueue_1_io_out_ready = 1'b0;
      PipelineRegModule_6_io_in_valid = 1'b1;
      PipelineRegModule_6_io_out_ready = 1'b1;
      SatpFlushMod_in_satp_valid = 1'b1;
    end
    repeat (NCYCLES) begin
      @(negedge clock);
      cycle = cycle + 1;
      drive_inputs();
      bias_inputs();
      if (rst_left > 0)
        rst_left = rst_left - 1;
      else if ($urandom % 512 == 0) begin
        rst_left = 1 + $urandom % 3;
        cov_rst_pulses = cov_rst_pulses + 1;
      end
      OverrideableQueue_reset = (rst_left > 0);
      OverrideableQueue_1_reset = (rst_left > 0);
      PipelineRegModule_6_reset = (rst_left > 0);
      #1;
      sample_coverage();
      // mid-cycle compare: an async reset raised at this negedge must already have cleared state
      compare_outputs();
      @(posedge clock);
      #1;
      compare_outputs();
    end
    $display("COVERAGE rst_pulses=%0d preg_fire_in_reset=%0d preg_stall=%0d oq_overwrite=%0d oq_same_slot_rw=%0d",
             cov_rst_pulses, cov_preg_fire_in_reset, cov_preg_stall, cov_oq_overwrite, cov_oq_same_slot_rw);
    $display("COVERAGE oq1_overwrite=%0d oq1_deq=%0d a16_win15=%0d a16_idle=%0d pfgen_lane2=%0d pfreq_idle=%0d hint_lane3=%0d satp_wen=%0d",
             cov_oq1_overwrite, cov_oq1_deq, cov_a16_win15, cov_a16_idle, cov_pfgen_lane2, cov_pfreq_idle, cov_hint_lane3, cov_satp_wen);
    if (cov_rst_pulses == 0 || cov_preg_fire_in_reset == 0 || cov_preg_stall == 0 || cov_oq_overwrite == 0 ||
        cov_oq_same_slot_rw == 0 || cov_oq1_overwrite == 0 || cov_oq1_deq == 0 || cov_a16_win15 == 0 ||
        cov_a16_idle == 0 || cov_pfgen_lane2 == 0 || cov_pfreq_idle == 0 || cov_hint_lane3 == 0 || cov_satp_wen == 0) begin
      $display("COVERAGE HOLE: at least one counter is zero");
      errors = errors + 1;
    end
    $display("Pipeline200c UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
