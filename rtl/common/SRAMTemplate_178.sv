// SRAMTemplate_178.sv — L2 Slice 的数据阵列（一个 bank 的 data storage）
// 规模：4096 set × 1 way × 137 位/way = 宏 137 位（sram_array_1p4096x137m137s1h1l2b_l2_dat）；
//       写掩码 无（宏不带 wmask，整条写）；MBIST bore 口 137 位（整宏）；
//       上电清零 无；读保持 无；时钟门控 外置（上层例化门控单元；本模块导出使能、收回 rclk）；多周期宏 是（隔拍门控 + 读数据晚 2 拍回）。
// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 rtl/common/xs_SRAMTemplate_core.sv。
module SRAMTemplate_178(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [11:0] io_r_req_bits_setIdx,
  output [136:0] io_r_resp_data_0,
  input  io_w_req_valid,
  input  [11:0] io_w_req_bits_setIdx,
  input  [136:0] io_w_req_bits_data_0,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  output io_mbistCgCtl_en,
  output io_mbistCgCtl_rckEn,
  output io_mbistCgCtl_wckEn,
  input  io_mbistCgCtl_rclk,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  input  [136:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [136:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [11:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [136:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(4096), .WAY(1), .DATA_WIDTH(137), .BORE_AW(13),
    .ENABLE_RESET(0), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    .MASK_SEG_W(0), .BORE_NSEG(1),
    .EXT_CLOCKGATE(1), .MCP_HOLD(1),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_178.sv）：
    //   宏名 sram_array_1p4096x137m137...l2b_* / io_r_resp_data_<k> 共 1 个 / bore_addr 13 位
    .G1_MACRO_SETS(4096), .G1_MACRO_BITS(137), .G1_MACRO_MASK(137),
    .G1_MACRO_LAT(2), .G1_WAY_PORTS(1), .G1_BORE_AW(13)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* 本变体无 r ready 口 */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(io_r_resp_data_0),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(io_w_req_bits_data_0), .io_w_mask(1'b1),
    .io_resetDone(/* 本变体不引出清零完成 */),
    .io_broadcast_ram_hold(io_broadcast_ram_hold),
    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),
    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),
    .io_broadcast_cgen(io_broadcast_cgen),
    .io_mbistCgCtl_en(io_mbistCgCtl_en), .io_mbistCgCtl_rckEn(io_mbistCgCtl_rckEn),
    .io_mbistCgCtl_wckEn(io_mbistCgCtl_wckEn), .io_mbistCgCtl_rclk(io_mbistCgCtl_rclk),
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
  sram_array_1p4096x137m137s1h1l2b_l2_dat array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule
