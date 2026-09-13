// SRAMTemplate_146.sv — L2 预取器的 Recent Request Table（近期请求过滤表）
// 规模：256 set × 1 way × 13 位/way = 宏 13 位（sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt）；
//       写掩码 无（宏不带 wmask，整条写）；MBIST bore 口 13 位（整宏）；
//       上电清零 有；读保持 无；时钟门控 无（宏时钟直连 clock）；多周期宏 否。
// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 rtl/common/xs_SRAMTemplate_core.sv。
module SRAMTemplate_146(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output io_r_resp_data_0_valid,
  output [11:0] io_r_resp_data_0_tag,
  output io_w_req_ready,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [11:0] io_w_req_bits_data_0_tag,
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
  input  [12:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [12:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [12:0] ram_wdata, ram_rdata;
  wire        resetDone;   // 清零 FSM 已跑完（无清零 FSM 的变体恒 1）

  // 一条 13 位表项；字段顺序 = golden 写口拼接顺序（MSB→LSB），位 [12:0]
  typedef struct packed {
    logic        valid;    // golden 写入恒为 1'h1
    logic [11:0] tag;
  } entry_t;
  entry_t wdata, rdata;

  always_comb begin
    wdata = '{
      valid: 1'h1,
      tag  : io_w_req_bits_data_0_tag
    };
  end

  xs_SRAMTemplate_core #(
    .SET(256), .WAY(1), .DATA_WIDTH(13), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    .MASK_SEG_W(0), .BORE_NSEG(1),
    .EXT_CLOCKGATE(0), .MCP_HOLD(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_146.sv）：
    //   宏名 sram_array_1p256x13m13...l1b_* / io_r_resp_data_<k> 共 1 个 / bore_addr 9 位
    .G1_MACRO_SETS(256), .G1_MACRO_BITS(13), .G1_MACRO_MASK(13),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(1), .G1_BORE_AW(9)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(rdata),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(wdata), .io_w_mask(1'b1),
    .io_resetDone(resetDone),
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
  sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
  assign io_r_resp_data_0_valid = rdata.valid;
  assign io_r_resp_data_0_tag = rdata.tag;
  assign io_w_req_ready = resetDone;   // 清零期间不收写
endmodule
