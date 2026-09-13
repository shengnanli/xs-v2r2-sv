// SRAMTemplate_128.sv — PTW 页表缓存 L1 层的 tag/数据阵列（MMU L2TLB 内）
// 规模：4 set × 2 way × 393 位/way = 宏 786 位（sram_array_1p4x786m131s1h0l1b_ptw_l1）；
//       写掩码 6 段 × 131 位，每 way 一位掩码复制 3 份盖住自己那几段；MBIST bore 口 131 位（= 宏的 1/6，selectedOH 选段）；
//       上电清零 无；读保持 无；时钟门控 无（宏时钟直连 clock）；多周期宏 否。
// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 rtl/common/xs_SRAMTemplate_core.sv。
module SRAMTemplate_128(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [1:0] io_r_req_bits_setIdx,
  output [392:0] io_r_resp_data_0,
  output [392:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [1:0] io_w_req_bits_setIdx,
  input  [392:0] io_w_req_bits_data_0,
  input  [392:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [2:0] boreChildrenBd_bore_addr,
  input  [2:0] boreChildrenBd_bore_addr_rd,
  input  [130:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [130:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  [5:0] boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [1:0]  ram_addr;
  wire [5:0]  ram_wmask;
  wire [785:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(4), .WAY(2), .DATA_WIDTH(393), .BORE_AW(3),
    .ENABLE_RESET(0), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    .MASK_SEG_W(131), .BORE_NSEG(6),
    .EXT_CLOCKGATE(0), .MCP_HOLD(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_128.sv）：
    //   宏名 sram_array_1p4x786m131...l1b_* / io_r_resp_data_<k> 共 2 个 / bore_addr 3 位
    .G1_MACRO_SETS(4), .G1_MACRO_BITS(786), .G1_MACRO_MASK(131),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(2), .G1_BORE_AW(3)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* 本变体无 r ready 口 */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
    .io_resetDone(/* 本变体不引出清零完成 */),
    .io_broadcast_ram_hold(io_broadcast_ram_hold),
    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),
    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),
    .io_broadcast_cgen(io_broadcast_cgen),
    .io_mbistCgCtl_en(/* 门控内置 */), .io_mbistCgCtl_rckEn(/* 门控内置 */),
    .io_mbistCgCtl_wckEn(/* 门控内置 */), .io_mbistCgCtl_rclk(1'b0),
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
  sram_array_1p4x786m131s1h0l1b_ptw_l1 array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule
