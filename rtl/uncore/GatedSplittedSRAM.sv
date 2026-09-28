// GatedSplittedSRAM.sv —— L2 数据阵列：548 位宽逻辑 SRAM = 4 个 137 位物理 bank + 4 个读时钟门控（DataStorage（slice 0））
//
// 纯连线模块（golden 369 行，没有任何寄存器或运算）。每个 bank 存一个 128 位数据块及其 9 位
// SECDED 校验（校验在上层 DataStorage 里算），所以 bank k 管写数据的 [137k+136:137k]。
// 各 bank：bank0=SRAMTemplate_155, bank1=SRAMTemplate_155, bank2=SRAMTemplate_155, bank3=SRAMTemplate_155；门控单元 MbistClockGateCell_93（rtl/common/）。
//   * 读/写请求广播到 4 个 bank；读数据按 bank 号低到高拼回；
//   * bank 把自己的 MBIST 读写请求（mbistCgCtl_en/rckEn/wckEn）交给同号门控单元，门控单元
//     在"真要访问"的拍放出读时钟（mbistCgCtl_rclk）；正常工作时的使能是 io_en；
//   * 第 k 个 bank 的 DFT 广播口 / MBIST bore 口接 sigFromSrams_bore_<k>_* / boreChildrenBd_bore_<k>_*
//     （k=0 无后缀）。
// 由 scripts/gen_l2_gated_sram.py 生成：逐实例逐端口与 golden 比对连接规则，对不上即失败。

// BEGIN GENERATED(GatedSplittedSRAM) —— scripts/gen_l2_gated_sram.py
module GatedSplittedSRAM (
  input  logic clock,
  input  logic reset,
  input  logic io_r_req_valid,
  input  logic [11:0] io_r_req_bits_setIdx,
  output logic [547:0] io_r_resp_data_0_data,
  input  logic io_w_req_valid,
  input  logic [11:0] io_w_req_bits_setIdx,
  input  logic [547:0] io_w_req_bits_data_0_data,
  input  logic io_en,
  input  logic [12:0] boreChildrenBd_bore_addr,
  input  logic [12:0] boreChildrenBd_bore_addr_rd,
  input  logic [136:0] boreChildrenBd_bore_wdata,
  input  logic boreChildrenBd_bore_wmask,
  input  logic boreChildrenBd_bore_re,
  input  logic boreChildrenBd_bore_we,
  output logic [136:0] boreChildrenBd_bore_rdata,
  input  logic boreChildrenBd_bore_ack,
  input  logic boreChildrenBd_bore_selectedOH,
  input  logic [3:0] boreChildrenBd_bore_array,
  input  logic [12:0] boreChildrenBd_bore_1_addr,
  input  logic [12:0] boreChildrenBd_bore_1_addr_rd,
  input  logic [136:0] boreChildrenBd_bore_1_wdata,
  input  logic boreChildrenBd_bore_1_wmask,
  input  logic boreChildrenBd_bore_1_re,
  input  logic boreChildrenBd_bore_1_we,
  output logic [136:0] boreChildrenBd_bore_1_rdata,
  input  logic boreChildrenBd_bore_1_ack,
  input  logic boreChildrenBd_bore_1_selectedOH,
  input  logic [3:0] boreChildrenBd_bore_1_array,
  input  logic [12:0] boreChildrenBd_bore_2_addr,
  input  logic [12:0] boreChildrenBd_bore_2_addr_rd,
  input  logic [136:0] boreChildrenBd_bore_2_wdata,
  input  logic boreChildrenBd_bore_2_wmask,
  input  logic boreChildrenBd_bore_2_re,
  input  logic boreChildrenBd_bore_2_we,
  output logic [136:0] boreChildrenBd_bore_2_rdata,
  input  logic boreChildrenBd_bore_2_ack,
  input  logic boreChildrenBd_bore_2_selectedOH,
  input  logic [3:0] boreChildrenBd_bore_2_array,
  input  logic [12:0] boreChildrenBd_bore_3_addr,
  input  logic [12:0] boreChildrenBd_bore_3_addr_rd,
  input  logic [136:0] boreChildrenBd_bore_3_wdata,
  input  logic boreChildrenBd_bore_3_wmask,
  input  logic boreChildrenBd_bore_3_re,
  input  logic boreChildrenBd_bore_3_we,
  output logic [136:0] boreChildrenBd_bore_3_rdata,
  input  logic boreChildrenBd_bore_3_ack,
  input  logic boreChildrenBd_bore_3_selectedOH,
  input  logic [3:0] boreChildrenBd_bore_3_array,
  input  logic sigFromSrams_bore_ram_hold,
  input  logic sigFromSrams_bore_ram_bypass,
  input  logic sigFromSrams_bore_ram_bp_clken,
  input  logic sigFromSrams_bore_ram_aux_clk,
  input  logic sigFromSrams_bore_ram_aux_ckbp,
  input  logic sigFromSrams_bore_ram_mcp_hold,
  input  logic sigFromSrams_bore_cgen,
  input  logic sigFromSrams_bore_1_ram_hold,
  input  logic sigFromSrams_bore_1_ram_bypass,
  input  logic sigFromSrams_bore_1_ram_bp_clken,
  input  logic sigFromSrams_bore_1_ram_aux_clk,
  input  logic sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic sigFromSrams_bore_1_ram_mcp_hold,
  input  logic sigFromSrams_bore_1_cgen,
  input  logic sigFromSrams_bore_2_ram_hold,
  input  logic sigFromSrams_bore_2_ram_bypass,
  input  logic sigFromSrams_bore_2_ram_bp_clken,
  input  logic sigFromSrams_bore_2_ram_aux_clk,
  input  logic sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic sigFromSrams_bore_2_ram_mcp_hold,
  input  logic sigFromSrams_bore_2_cgen,
  input  logic sigFromSrams_bore_3_ram_hold,
  input  logic sigFromSrams_bore_3_ram_bypass,
  input  logic sigFromSrams_bore_3_ram_bp_clken,
  input  logic sigFromSrams_bore_3_ram_aux_clk,
  input  logic sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic sigFromSrams_bore_3_ram_mcp_hold,
  input  logic sigFromSrams_bore_3_cgen
);

  logic [136:0] bankReadData   [4];   // 各 bank 读出的 137 位
  logic         bankMbistReq   [4];   // bank -> 门控：MBIST 正在访问本 bank
  logic         bankMbistRead  [4];
  logic         bankMbistWrite [4];
  logic         bankReadClock  [4];   // 门控 -> bank：门控后的读时钟

  // ---- bank 0：写数据 [136:0] ----
  SRAMTemplate_155 array_0_0_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (bankReadData[0]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (io_w_req_bits_data_0_data[136:0]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .io_mbistCgCtl_en               (bankMbistReq[0]),
    .io_mbistCgCtl_rckEn            (bankMbistRead[0]),
    .io_mbistCgCtl_wckEn            (bankMbistWrite[0]),
    .io_mbistCgCtl_rclk             (bankReadClock[0]),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array)
  );
  MbistClockGateCell_93 cg (
    .clock            (clock),
    .mbist_writeen    (bankMbistWrite[0]),
    .mbist_readen     (bankMbistRead[0]),
    .mbist_req        (bankMbistReq[0]),
    .E                (io_en),
    .dft_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .dft_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .dft_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .dft_cgen         (sigFromSrams_bore_cgen),
    .out_clock        (bankReadClock[0])
  );

  // ---- bank 1：写数据 [273:137] ----
  SRAMTemplate_155 array_0_0_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (bankReadData[1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (io_w_req_bits_data_0_data[273:137]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_1_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_1_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_1_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_1_cgen),
    .io_mbistCgCtl_en               (bankMbistReq[1]),
    .io_mbistCgCtl_rckEn            (bankMbistRead[1]),
    .io_mbistCgCtl_wckEn            (bankMbistWrite[1]),
    .io_mbistCgCtl_rclk             (bankReadClock[1]),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_1_array)
  );
  MbistClockGateCell_93 cg_1 (
    .clock            (clock),
    .mbist_writeen    (bankMbistWrite[1]),
    .mbist_readen     (bankMbistRead[1]),
    .mbist_req        (bankMbistReq[1]),
    .E                (io_en),
    .dft_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .dft_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .dft_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .dft_cgen         (sigFromSrams_bore_1_cgen),
    .out_clock        (bankReadClock[1])
  );

  // ---- bank 2：写数据 [410:274] ----
  SRAMTemplate_155 array_0_0_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (bankReadData[2]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (io_w_req_bits_data_0_data[410:274]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_2_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_2_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_2_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_2_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_2_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_2_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_2_cgen),
    .io_mbistCgCtl_en               (bankMbistReq[2]),
    .io_mbistCgCtl_rckEn            (bankMbistRead[2]),
    .io_mbistCgCtl_wckEn            (bankMbistWrite[2]),
    .io_mbistCgCtl_rclk             (bankReadClock[2]),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_2_array)
  );
  MbistClockGateCell_93 cg_2 (
    .clock            (clock),
    .mbist_writeen    (bankMbistWrite[2]),
    .mbist_readen     (bankMbistRead[2]),
    .mbist_req        (bankMbistReq[2]),
    .E                (io_en),
    .dft_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .dft_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .dft_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .dft_cgen         (sigFromSrams_bore_2_cgen),
    .out_clock        (bankReadClock[2])
  );

  // ---- bank 3：写数据 [547:411] ----
  SRAMTemplate_155 array_0_0_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (bankReadData[3]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (io_w_req_bits_data_0_data[547:411]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_3_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_3_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_3_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_3_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_3_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_3_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_3_cgen),
    .io_mbistCgCtl_en               (bankMbistReq[3]),
    .io_mbistCgCtl_rckEn            (bankMbistRead[3]),
    .io_mbistCgCtl_wckEn            (bankMbistWrite[3]),
    .io_mbistCgCtl_rclk             (bankReadClock[3]),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_3_array)
  );
  MbistClockGateCell_93 cg_3 (
    .clock            (clock),
    .mbist_writeen    (bankMbistWrite[3]),
    .mbist_readen     (bankMbistRead[3]),
    .mbist_req        (bankMbistReq[3]),
    .E                (io_en),
    .dft_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .dft_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .dft_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .dft_cgen         (sigFromSrams_bore_3_cgen),
    .out_clock        (bankReadClock[3])
  );

  assign io_r_resp_data_0_data = {bankReadData[3], bankReadData[2], bankReadData[1], bankReadData[0]};

endmodule
// END GENERATED(GatedSplittedSRAM)
