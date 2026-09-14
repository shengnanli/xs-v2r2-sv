// 自动生成：scripts/gen_sram_wrappers.py（G1 基线驱动）—— 勿手改
// 变体薄文件：例化 xs_SRAMTemplate_core（rtl/common/xs_SRAMTemplate_core.sv）
// + 厂商 SRAM 宏（golden 同源，两侧同读；唯一黑盒是宏内 *_ext 叶子）
module SRAMTemplate_116(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output [42:0] io_r_resp_data_0,
  output [42:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [42:0] io_w_req_bits_data_0,
  input  [42:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [85:0] boreChildrenBd_bore_wdata,
  input  [1:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [85:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [1:0]  ram_wmask;
  wire [85:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(2), .DATA_WIDTH(43), .BORE_AW(9),
    .ENABLE_RESET(0), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_116.sv）：
    //   宏名 sram_array_1p256x86m43...l1b_* / io_r_resp_data_<k> 共 2 个 / bore_addr 9 位
    .G1_MACRO_SETS(256), .G1_MACRO_BITS(86), .G1_MACRO_MASK(43),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(2), .G1_BORE_AW(9)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
    .io_resetDone(/* 本变体 golden 不引出清零完成 */),
    .io_broadcast_ram_hold(io_broadcast_ram_hold),
    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),
    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),
    .io_broadcast_cgen(io_broadcast_cgen),
    .io_mbistCgCtl_en(/* 门控不外置 */), .io_mbistCgCtl_rckEn(/* 门控不外置 */),
    .io_mbistCgCtl_wckEn(/* 门控不外置 */), .io_mbistCgCtl_rclk(1'b0),
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
  sram_array_1p256x86m43s1h0l1b_dcsh_tag array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule
