// =============================================================================
// DataSRAMBank —— DCache 数据阵列的一个 bank（4 路 × 256 组 × 72 位 {ecc, data}）
//
// 对应 Chisel：xiangshan.cache.DataSRAMBank（src/main/scala/xiangshan/cache/dcache/data/BankedDataArray.scala）
//
// 【位置】DCache 的一行 64B 按 8B 切成 8 个 bank（BankedDataArray.data_banks_0_0..0_7），每个 bank 是本件
//   （DataSRAMBank / _1 / _2 / _4 四个变体，只差 SRAMTemplate 的 MBIST 端口宽度）。
//   bank 内 4 路各是一个单口 SRAMTemplate（1 路宽、72 位 = 8 位 SECDED + 64 位数据）。
// 【读】4 路用同一个 set 下标一起读（io_r_en / io_r_addr），下一拍 4 路结果都出来，
//   选哪一路由上层（BankedDataArray）按命中路去选。
// 【写】写请求带 4 位 way_en（独热，refill/替换只写一路）：第 w 路写使能 = w_en & way_en[w]，
//   写数据与地址 4 路共用。Chisel 在此放了一条断言"一次最多写一路"，golden 里留下一个寄存器 REG。
// 【MBIST / SRAM 控制】boreChildrenBd_bore*（4 路各一套）/ sigFromSrams_bore* 只透传给各路 SRAMTemplate；
//   io_broadcast_ram_ctl 本配置接常量 0。
// 【可读核】xs_DataSRAMBank_core 只含写使能译码与"写最多一路"检查；wrapper（下方 GENERATED 区与
//   DataSRAMBank_1/_2/_4.sv）由 scripts/gen_datasrambank.py 从 golden 端口表生成——4 个变体的差别只是
//   "每路例化哪一个 SRAMTemplate_N"，Verilog 不能把被例化的模块名做成参数。
// =============================================================================

module xs_DataSRAMBank_core #(
  parameter int N_WAYS = 4
) (
  input  logic              io_w_en,
  input  logic [N_WAYS-1:0] io_w_way_en,
  output logic [N_WAYS-1:0] way_wen,            // 第 w 路 SRAM 的写使能
  output logic              write_one_hot_ok    // !w_en || PopCount(way_en) <= 1
);
  assign way_wen = {N_WAYS{io_w_en}} & io_w_way_en;

  logic [$clog2(N_WAYS+1)-1:0] n_ways_written;
  always_comb begin
    n_ways_written = '0;
    for (int w = 0; w < N_WAYS; w++)
      n_ways_written += io_w_way_en[w];
  end
  assign write_one_hot_ok = ~io_w_en | (n_ways_written <= 1);
endmodule

// BEGIN GENERATED(datasrambank_wrapper)
// 由 scripts/gen_datasrambank.py 从 golden DataSRAMBank.sv 的端口表与 SRAMTemplate 例化生成 —— 勿手改。
// 每路 SRAMTemplate：路0=SRAMTemplate_84, 路1=SRAMTemplate_84, 路2=SRAMTemplate_86, 路3=SRAMTemplate_86
module DataSRAMBank(
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
  input         boreChildrenBd_bore_array,
  input  [8:0]  boreChildrenBd_bore_1_addr,
  input  [8:0]  boreChildrenBd_bore_1_addr_rd,
  input  [71:0] boreChildrenBd_bore_1_wdata,
  input         boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [71:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input         boreChildrenBd_bore_1_array,
  input  [8:0]  boreChildrenBd_bore_2_addr,
  input  [8:0]  boreChildrenBd_bore_2_addr_rd,
  input  [71:0] boreChildrenBd_bore_2_wdata,
  input         boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,
  input         boreChildrenBd_bore_2_we,
  output [71:0] boreChildrenBd_bore_2_rdata,
  input         boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH,
  input  [1:0]  boreChildrenBd_bore_2_array,
  input  [8:0]  boreChildrenBd_bore_3_addr,
  input  [8:0]  boreChildrenBd_bore_3_addr_rd,
  input  [71:0] boreChildrenBd_bore_3_wdata,
  input         boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,
  input         boreChildrenBd_bore_3_we,
  output [71:0] boreChildrenBd_bore_3_rdata,
  input         boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH,
  input  [1:0]  boreChildrenBd_bore_3_array,
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
  SRAMTemplate_84 data_bank_0 (
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
  SRAMTemplate_84 data_bank_1 (
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
  SRAMTemplate_86 data_bank_2 (
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
  SRAMTemplate_86 data_bank_3 (
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
