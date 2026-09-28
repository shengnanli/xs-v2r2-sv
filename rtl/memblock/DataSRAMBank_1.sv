// DataSRAMBank_1 —— DCache 数据阵列的一个 bank（DataSRAMBank 家族的变体）
//
// 与 DataSRAMBank 逻辑完全相同（见 rtl/memblock/DataSRAMBank.sv 文件头与可读核 xs_DataSRAMBank_core），
// 只有每一路例化的 SRAMTemplate 变体（MBIST array id 位宽不同）与 bore*_array 端口位宽不同。
// 本文件整体由 scripts/gen_datasrambank.py 生成。

// BEGIN GENERATED(datasrambank_wrapper)
// 由 scripts/gen_datasrambank.py 从 golden DataSRAMBank_1.sv 的端口表与 SRAMTemplate 例化生成 —— 勿手改。
// 每路 SRAMTemplate：路0=SRAMTemplate_88, 路1=SRAMTemplate_88, 路2=SRAMTemplate_88, 路3=SRAMTemplate_88
module DataSRAMBank_1(
  input         clock,
  input         reset,
  input         io_w_en,
  input  [7:0]  io_w_addr,
  input  [3:0]  io_w_way_en,
  input  [71:0] io_w_data,
  input         io_r_en,
  input  [7:0]  io_r_addr,
  output [71:0] io_r_data_0,
  output [71:0] io_r_data_1,
  output [71:0] io_r_data_2,
  output [71:0] io_r_data_3,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [71:0] boreChildrenBd_bore_wdata,
  input         boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [71:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [2:0]  boreChildrenBd_bore_array,
  input  [8:0]  boreChildrenBd_bore_1_addr,
  input  [8:0]  boreChildrenBd_bore_1_addr_rd,
  input  [71:0] boreChildrenBd_bore_1_wdata,
  input         boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [71:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [2:0]  boreChildrenBd_bore_1_array,
  input  [8:0]  boreChildrenBd_bore_2_addr,
  input  [8:0]  boreChildrenBd_bore_2_addr_rd,
  input  [71:0] boreChildrenBd_bore_2_wdata,
  input         boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,
  input         boreChildrenBd_bore_2_we,
  output [71:0] boreChildrenBd_bore_2_rdata,
  input         boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH,
  input  [2:0]  boreChildrenBd_bore_2_array,
  input  [8:0]  boreChildrenBd_bore_3_addr,
  input  [8:0]  boreChildrenBd_bore_3_addr_rd,
  input  [71:0] boreChildrenBd_bore_3_wdata,
  input         boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,
  input         boreChildrenBd_bore_3_we,
  output [71:0] boreChildrenBd_bore_3_rdata,
  input         boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH,
  input  [2:0]  boreChildrenBd_bore_3_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen
);

  logic [3:0] way_wen;           // 每路写使能 = w_en & way_en[w]
  logic       write_one_hot_ok;  // 本拍写最多一路（仿真检查用）
  xs_DataSRAMBank_core u_core (
    .io_w_en          (io_w_en),
    .io_w_way_en      (io_w_way_en),
    .way_wen          (way_wen),
    .write_one_hot_ok (write_one_hot_ok)
  );

  // assert(RegNext(!io.w.en || PopCount(io.w.way_en) <= 1.U)) 在 golden 里留下的寄存器（名同 golden）
  logic REG;
  always_ff @(posedge clock) REG <= write_one_hot_ok;
`ifndef SYNTHESIS
  always @(posedge clock)
    if (!reset && !REG) $error("DataSRAMBank: write enables more than one way");
`endif

  // 第 0 路
  SRAMTemplate_88 data_bank_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_en),
    .io_r_req_bits_setIdx           (io_r_addr),
    .io_r_resp_data_0               (io_r_data_0),
    .io_w_req_valid                 (way_wen[0]),
    .io_w_req_bits_setIdx           (io_w_addr),
    .io_w_req_bits_data_0           (io_w_data),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
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
  // 第 1 路
  SRAMTemplate_88 data_bank_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_en),
    .io_r_req_bits_setIdx           (io_r_addr),
    .io_r_resp_data_0               (io_r_data_1),
    .io_w_req_valid                 (way_wen[1]),
    .io_w_req_bits_setIdx           (io_w_addr),
    .io_w_req_bits_data_0           (io_w_data),
    .io_broadcast_ram_hold          (sigFromSrams_bore_1_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_1_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_1_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_1_cgen),
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
  // 第 2 路
  SRAMTemplate_88 data_bank_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_en),
    .io_r_req_bits_setIdx           (io_r_addr),
    .io_r_resp_data_0               (io_r_data_2),
    .io_w_req_valid                 (way_wen[2]),
    .io_w_req_bits_setIdx           (io_w_addr),
    .io_w_req_bits_data_0           (io_w_data),
    .io_broadcast_ram_hold          (sigFromSrams_bore_2_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_2_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_2_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_2_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_2_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_2_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_2_cgen),
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
  // 第 3 路
  SRAMTemplate_88 data_bank_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_en),
    .io_r_req_bits_setIdx           (io_r_addr),
    .io_r_resp_data_0               (io_r_data_3),
    .io_w_req_valid                 (way_wen[3]),
    .io_w_req_bits_setIdx           (io_w_addr),
    .io_w_req_bits_data_0           (io_w_data),
    .io_broadcast_ram_hold          (sigFromSrams_bore_3_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_3_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_3_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_3_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_3_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_3_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_3_cgen),
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

endmodule
// END GENERATED
