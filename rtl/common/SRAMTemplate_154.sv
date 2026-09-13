// 自动生成：scripts/gen_sram_wrappers.py（G1 基线驱动）—— 勿手改
// 变体薄文件：例化 xs_SRAMTemplate_core（rtl/common/xs_SRAMTemplate_core.sv）
// + 厂商 SRAM 宏（golden 同源，两侧同读；唯一黑盒是宏内 *_ext 叶子）
module SRAMTemplate_154(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [8:0] io_r_req_bits_setIdx,
  output io_r_resp_data_0,
  output io_r_resp_data_1,
  output io_r_resp_data_2,
  output io_r_resp_data_3,
  output io_r_resp_data_4,
  output io_r_resp_data_5,
  output io_r_resp_data_6,
  output io_r_resp_data_7,
  input  io_w_req_valid,
  input  [8:0] io_w_req_bits_setIdx,
  input  io_w_req_bits_data_0,
  input  io_w_req_bits_data_1,
  input  io_w_req_bits_data_2,
  input  io_w_req_bits_data_3,
  input  io_w_req_bits_data_4,
  input  io_w_req_bits_data_5,
  input  io_w_req_bits_data_6,
  input  io_w_req_bits_data_7,
  input  [7:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  input  [7:0] boreChildrenBd_bore_wdata,
  input  [7:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [7:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [3:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [8:0]  ram_addr;
  wire [7:0]  ram_wmask;
  wire [7:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(512), .WAY(8), .DATA_WIDTH(1), .BORE_AW(10),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_154.sv）：
    //   宏名 sram_array_1p512x8m1...l1b_* / io_r_resp_data_<k> 共 8 个 / bore_addr 10 位
    .G1_MACRO_SETS(512), .G1_MACRO_BITS(8), .G1_MACRO_MASK(1),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(8), .G1_BORE_AW(10)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_7, io_r_resp_data_6, io_r_resp_data_5, io_r_resp_data_4, io_r_resp_data_3, io_r_resp_data_2, io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_7, io_w_req_bits_data_6, io_w_req_bits_data_5, io_w_req_bits_data_4, io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(io_broadcast_ram_hold),
    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),
    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),
    .io_broadcast_cgen(io_broadcast_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p512x8m1s1h0l1b_l2_orgb array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule
