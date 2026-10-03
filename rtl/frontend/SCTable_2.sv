// =============================================================================
// SCTable_2 —— SC 计数器表，历史长度 10 那一档（折叠历史 min(8,10)=8 位）
//
// 核体与机制说明见 SCTable.sv（package sctable_pkg + xs_SCTable_core）。
// 本文件只有 golden 同名 wrapper：端口展平 + 本档 MBIST 流水 MbistPipeSc_2。
// =============================================================================
// BEGIN GENERATED(sctable_wrapper) —— scripts/gen_sctable.py 生成，勿手改
module SCTable_2
  import sctable_pkg::*;
(
  input  clock,
  input  reset,
  input  io_req_valid,
  input  [49:0] io_req_bits_pc,
  input  [7:0] io_req_bits_folded_hist_hist_11_folded_hist,
  output [5:0] io_resp_ctrs_0_0,
  output [5:0] io_resp_ctrs_0_1,
  output [5:0] io_resp_ctrs_1_0,
  output [5:0] io_resp_ctrs_1_1,
  input  [49:0] io_update_pc,
  input  [255:0] io_update_ghist,
  input  io_update_mask_0,
  input  io_update_mask_1,
  input  [5:0] io_update_oldCtrs_0,
  input  [5:0] io_update_oldCtrs_1,
  input  io_update_tagePreds_0,
  input  io_update_tagePreds_1,
  input  io_update_takens_0,
  input  io_update_takens_1,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [3:0] boreChildrenBd_bore_be,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [23:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  output [23:0] boreChildrenBd_bore_outdata,
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
  input  sigFromSrams_bore_1_cgen
);

  logic [CTR_W-1:0] resp_ctrs [NUM_BR][2];
  logic [CTR_W-1:0] update_old_ctrs [NUM_BR];
  sc_mbist_req_t    mbist_req   [NUM_BANK];
  logic [23:0]      mbist_rdata [NUM_BANK];
  sc_sram_bcast_t   sram_bcast  [NUM_BANK];

  // SRAM 宏广播控制位：bank 0 = sigFromSrams_bore_*，bank 1 = sigFromSrams_bore_1_*
  assign sram_bcast[0] = '{
    ram_hold: sigFromSrams_bore_ram_hold,
    ram_bypass: sigFromSrams_bore_ram_bypass,
    ram_bp_clken: sigFromSrams_bore_ram_bp_clken,
    ram_aux_clk: sigFromSrams_bore_ram_aux_clk,
    ram_aux_ckbp: sigFromSrams_bore_ram_aux_ckbp,
    ram_mcp_hold: sigFromSrams_bore_ram_mcp_hold,
    cgen: sigFromSrams_bore_cgen
  };
  assign sram_bcast[1] = '{
    ram_hold: sigFromSrams_bore_1_ram_hold,
    ram_bypass: sigFromSrams_bore_1_ram_bypass,
    ram_bp_clken: sigFromSrams_bore_1_ram_bp_clken,
    ram_aux_clk: sigFromSrams_bore_1_ram_aux_clk,
    ram_aux_ckbp: sigFromSrams_bore_1_ram_aux_ckbp,
    ram_mcp_hold: sigFromSrams_bore_1_ram_mcp_hold,
    cgen: sigFromSrams_bore_1_cgen
  };
  assign update_old_ctrs[0] = io_update_oldCtrs_0;
  assign update_old_ctrs[1] = io_update_oldCtrs_1;

  xs_SCTable_core #(
    .HIST_LEN (10)
  ) u_core (
    .clock             (clock),
    .reset             (reset),
    .req_valid         (io_req_valid),
    .req_pc            (io_req_bits_pc),
    .req_folded_hist   (io_req_bits_folded_hist_hist_11_folded_hist),
    .resp_ctrs         (resp_ctrs),
    .update_pc         (io_update_pc),
    .update_ghist      (io_update_ghist),
    .update_mask       ({io_update_mask_1, io_update_mask_0}),
    .update_old_ctrs   (update_old_ctrs),
    .update_tage_preds ({io_update_tagePreds_1, io_update_tagePreds_0}),
    .update_takens     ({io_update_takens_1, io_update_takens_0}),
    .mbist_req         (mbist_req),
    .mbist_rdata       (mbist_rdata),
    .sram_bcast        (sram_bcast)
  );

  assign io_resp_ctrs_0_0 = resp_ctrs[0][0];
  assign io_resp_ctrs_0_1 = resp_ctrs[0][1];
  assign io_resp_ctrs_1_0 = resp_ctrs[1][0];
  assign io_resp_ctrs_1_1 = resp_ctrs[1][1];

  // MBIST 流水：把顶层 boreChildrenBd 测试口分发到两个 SRAM bank
  MbistPipeSc_2 mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (mbist_req[0].addr),
    .toSRAM_0_addr_rd    (mbist_req[0].addr_rd),
    .toSRAM_0_wdata      (mbist_req[0].wdata),
    .toSRAM_0_wmask      (mbist_req[0].wmask),
    .toSRAM_0_re         (mbist_req[0].re),
    .toSRAM_0_we         (mbist_req[0].we),
    .toSRAM_0_ack        (mbist_req[0].ack),
    .toSRAM_0_selectedOH (mbist_req[0].selectedOH),
    .toSRAM_0_array      (mbist_req[0].array),
    .toSRAM_0_rdata      (mbist_rdata[0]),
    .toSRAM_1_addr       (mbist_req[1].addr),
    .toSRAM_1_addr_rd    (mbist_req[1].addr_rd),
    .toSRAM_1_wdata      (mbist_req[1].wdata),
    .toSRAM_1_wmask      (mbist_req[1].wmask),
    .toSRAM_1_re         (mbist_req[1].re),
    .toSRAM_1_we         (mbist_req[1].we),
    .toSRAM_1_ack        (mbist_req[1].ack),
    .toSRAM_1_selectedOH (mbist_req[1].selectedOH),
    .toSRAM_1_array      (mbist_req[1].array),
    .toSRAM_1_rdata      (mbist_rdata[1])
  );

endmodule
// END GENERATED(sctable_wrapper)
