// SRAMTemplate_145.sv — L2 预取器 SPP 的 Pattern History Table
// 规模：32 set × 2 way × 74 位/way = 宏 148 位（sram_array_1p32x148m74s1h0l1b_pftch_pht）；
//       写掩码 2 段 × 74 位，每 way 恰好一位；MBIST bore 口 148 位（整宏）；
//       上电清零 无；读保持 无；时钟门控 内置 MbistClockGateCell；多周期宏 否。
// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 rtl/common/xs_SRAMTemplate_core.sv。
module SRAMTemplate_145(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [4:0] io_r_req_bits_setIdx,
  output [1:0] io_r_resp_data_0_hist_0,
  output [1:0] io_r_resp_data_0_hist_1,
  output [1:0] io_r_resp_data_0_hist_2,
  output [1:0] io_r_resp_data_0_hist_3,
  output [1:0] io_r_resp_data_0_hist_4,
  output [1:0] io_r_resp_data_0_hist_5,
  output [1:0] io_r_resp_data_0_hist_6,
  output [1:0] io_r_resp_data_0_hist_7,
  output [1:0] io_r_resp_data_0_hist_8,
  output [1:0] io_r_resp_data_0_hist_9,
  output [1:0] io_r_resp_data_0_hist_10,
  output [1:0] io_r_resp_data_0_hist_11,
  output [1:0] io_r_resp_data_0_hist_12,
  output [1:0] io_r_resp_data_0_hist_13,
  output [1:0] io_r_resp_data_0_hist_14,
  output [1:0] io_r_resp_data_0_hist_15,
  output [1:0] io_r_resp_data_0_hist_16,
  output [1:0] io_r_resp_data_0_hist_17,
  output [1:0] io_r_resp_data_0_hist_18,
  output [1:0] io_r_resp_data_0_hist_19,
  output [1:0] io_r_resp_data_0_hist_20,
  output [1:0] io_r_resp_data_0_hist_21,
  output [1:0] io_r_resp_data_0_hist_22,
  output [1:0] io_r_resp_data_0_hist_23,
  output [1:0] io_r_resp_data_0_hist_24,
  output [1:0] io_r_resp_data_0_hist_25,
  output [1:0] io_r_resp_data_0_hist_26,
  output [1:0] io_r_resp_data_0_hist_27,
  output [1:0] io_r_resp_data_0_hist_28,
  output [1:0] io_r_resp_data_0_hist_29,
  output [12:0] io_r_resp_data_0_tag,
  output [1:0] io_r_resp_data_1_hist_0,
  output [1:0] io_r_resp_data_1_hist_1,
  output [1:0] io_r_resp_data_1_hist_2,
  output [1:0] io_r_resp_data_1_hist_3,
  output [1:0] io_r_resp_data_1_hist_4,
  output [1:0] io_r_resp_data_1_hist_5,
  output [1:0] io_r_resp_data_1_hist_6,
  output [1:0] io_r_resp_data_1_hist_7,
  output [1:0] io_r_resp_data_1_hist_8,
  output [1:0] io_r_resp_data_1_hist_9,
  output [1:0] io_r_resp_data_1_hist_10,
  output [1:0] io_r_resp_data_1_hist_11,
  output [1:0] io_r_resp_data_1_hist_12,
  output [1:0] io_r_resp_data_1_hist_13,
  output [1:0] io_r_resp_data_1_hist_14,
  output [1:0] io_r_resp_data_1_hist_15,
  output [1:0] io_r_resp_data_1_hist_16,
  output [1:0] io_r_resp_data_1_hist_17,
  output [1:0] io_r_resp_data_1_hist_18,
  output [1:0] io_r_resp_data_1_hist_19,
  output [1:0] io_r_resp_data_1_hist_20,
  output [1:0] io_r_resp_data_1_hist_21,
  output [1:0] io_r_resp_data_1_hist_22,
  output [1:0] io_r_resp_data_1_hist_23,
  output [1:0] io_r_resp_data_1_hist_24,
  output [1:0] io_r_resp_data_1_hist_25,
  output [1:0] io_r_resp_data_1_hist_26,
  output [1:0] io_r_resp_data_1_hist_27,
  output [1:0] io_r_resp_data_1_hist_28,
  output [1:0] io_r_resp_data_1_hist_29,
  output [12:0] io_r_resp_data_1_tag,
  input  io_w_req_valid,
  input  [4:0] io_w_req_bits_setIdx,
  input  [1:0] io_w_req_bits_data_0_hist_0,
  input  [1:0] io_w_req_bits_data_0_hist_1,
  input  [1:0] io_w_req_bits_data_0_hist_2,
  input  [1:0] io_w_req_bits_data_0_hist_3,
  input  [1:0] io_w_req_bits_data_0_hist_4,
  input  [1:0] io_w_req_bits_data_0_hist_5,
  input  [1:0] io_w_req_bits_data_0_hist_6,
  input  [1:0] io_w_req_bits_data_0_hist_7,
  input  [1:0] io_w_req_bits_data_0_hist_8,
  input  [1:0] io_w_req_bits_data_0_hist_9,
  input  [1:0] io_w_req_bits_data_0_hist_10,
  input  [1:0] io_w_req_bits_data_0_hist_11,
  input  [1:0] io_w_req_bits_data_0_hist_12,
  input  [1:0] io_w_req_bits_data_0_hist_13,
  input  [1:0] io_w_req_bits_data_0_hist_14,
  input  [1:0] io_w_req_bits_data_0_hist_15,
  input  [1:0] io_w_req_bits_data_0_hist_16,
  input  [1:0] io_w_req_bits_data_0_hist_17,
  input  [1:0] io_w_req_bits_data_0_hist_18,
  input  [1:0] io_w_req_bits_data_0_hist_19,
  input  [1:0] io_w_req_bits_data_0_hist_20,
  input  [1:0] io_w_req_bits_data_0_hist_21,
  input  [1:0] io_w_req_bits_data_0_hist_22,
  input  [1:0] io_w_req_bits_data_0_hist_23,
  input  [1:0] io_w_req_bits_data_0_hist_24,
  input  [1:0] io_w_req_bits_data_0_hist_25,
  input  [1:0] io_w_req_bits_data_0_hist_26,
  input  [1:0] io_w_req_bits_data_0_hist_27,
  input  [1:0] io_w_req_bits_data_0_hist_28,
  input  [1:0] io_w_req_bits_data_0_hist_29,
  input  [12:0] io_w_req_bits_data_0_tag,
  input  io_w_req_bits_data_0_decr_mode,
  input  [1:0] io_w_req_bits_data_1_hist_0,
  input  [1:0] io_w_req_bits_data_1_hist_1,
  input  [1:0] io_w_req_bits_data_1_hist_2,
  input  [1:0] io_w_req_bits_data_1_hist_3,
  input  [1:0] io_w_req_bits_data_1_hist_4,
  input  [1:0] io_w_req_bits_data_1_hist_5,
  input  [1:0] io_w_req_bits_data_1_hist_6,
  input  [1:0] io_w_req_bits_data_1_hist_7,
  input  [1:0] io_w_req_bits_data_1_hist_8,
  input  [1:0] io_w_req_bits_data_1_hist_9,
  input  [1:0] io_w_req_bits_data_1_hist_10,
  input  [1:0] io_w_req_bits_data_1_hist_11,
  input  [1:0] io_w_req_bits_data_1_hist_12,
  input  [1:0] io_w_req_bits_data_1_hist_13,
  input  [1:0] io_w_req_bits_data_1_hist_14,
  input  [1:0] io_w_req_bits_data_1_hist_15,
  input  [1:0] io_w_req_bits_data_1_hist_16,
  input  [1:0] io_w_req_bits_data_1_hist_17,
  input  [1:0] io_w_req_bits_data_1_hist_18,
  input  [1:0] io_w_req_bits_data_1_hist_19,
  input  [1:0] io_w_req_bits_data_1_hist_20,
  input  [1:0] io_w_req_bits_data_1_hist_21,
  input  [1:0] io_w_req_bits_data_1_hist_22,
  input  [1:0] io_w_req_bits_data_1_hist_23,
  input  [1:0] io_w_req_bits_data_1_hist_24,
  input  [1:0] io_w_req_bits_data_1_hist_25,
  input  [1:0] io_w_req_bits_data_1_hist_26,
  input  [1:0] io_w_req_bits_data_1_hist_27,
  input  [1:0] io_w_req_bits_data_1_hist_28,
  input  [1:0] io_w_req_bits_data_1_hist_29,
  input  [12:0] io_w_req_bits_data_1_tag,
  input  io_w_req_bits_data_1_decr_mode,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [5:0] boreChildrenBd_bore_addr,
  input  [5:0] boreChildrenBd_bore_addr_rd,
  input  [147:0] boreChildrenBd_bore_wdata,
  input  [1:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [147:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [6:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [4:0]  ram_addr;
  wire [1:0]  ram_wmask;
  wire [147:0] ram_wdata, ram_rdata;

  // 一条 74 位表项；字段顺序 = golden 写口拼接顺序（MSB→LSB），位 [73:0]
  typedef struct packed {
    logic [1:0]  hist_29;
    logic [1:0]  hist_28;
    logic [1:0]  hist_27;
    logic [1:0]  hist_26;
    logic [1:0]  hist_25;
    logic [1:0]  hist_24;
    logic [1:0]  hist_23;
    logic [1:0]  hist_22;
    logic [1:0]  hist_21;
    logic [1:0]  hist_20;
    logic [1:0]  hist_19;
    logic [1:0]  hist_18;
    logic [1:0]  hist_17;
    logic [1:0]  hist_16;
    logic [1:0]  hist_15;
    logic [1:0]  hist_14;
    logic [1:0]  hist_13;
    logic [1:0]  hist_12;
    logic [1:0]  hist_11;
    logic [1:0]  hist_10;
    logic [1:0]  hist_9;
    logic [1:0]  hist_8;
    logic [1:0]  hist_7;
    logic [1:0]  hist_6;
    logic [1:0]  hist_5;
    logic [1:0]  hist_4;
    logic [1:0]  hist_3;
    logic [1:0]  hist_2;
    logic [1:0]  hist_1;
    logic [1:0]  hist_0;
    logic [12:0] tag;
    logic        decr_mode;
  } entry_t;
  entry_t [1:0] wdata, rdata;   // 按 way 索引，[0] 在宏数据的低位

  always_comb begin
    wdata[0] = '{
      hist_29  : io_w_req_bits_data_0_hist_29,
      hist_28  : io_w_req_bits_data_0_hist_28,
      hist_27  : io_w_req_bits_data_0_hist_27,
      hist_26  : io_w_req_bits_data_0_hist_26,
      hist_25  : io_w_req_bits_data_0_hist_25,
      hist_24  : io_w_req_bits_data_0_hist_24,
      hist_23  : io_w_req_bits_data_0_hist_23,
      hist_22  : io_w_req_bits_data_0_hist_22,
      hist_21  : io_w_req_bits_data_0_hist_21,
      hist_20  : io_w_req_bits_data_0_hist_20,
      hist_19  : io_w_req_bits_data_0_hist_19,
      hist_18  : io_w_req_bits_data_0_hist_18,
      hist_17  : io_w_req_bits_data_0_hist_17,
      hist_16  : io_w_req_bits_data_0_hist_16,
      hist_15  : io_w_req_bits_data_0_hist_15,
      hist_14  : io_w_req_bits_data_0_hist_14,
      hist_13  : io_w_req_bits_data_0_hist_13,
      hist_12  : io_w_req_bits_data_0_hist_12,
      hist_11  : io_w_req_bits_data_0_hist_11,
      hist_10  : io_w_req_bits_data_0_hist_10,
      hist_9   : io_w_req_bits_data_0_hist_9,
      hist_8   : io_w_req_bits_data_0_hist_8,
      hist_7   : io_w_req_bits_data_0_hist_7,
      hist_6   : io_w_req_bits_data_0_hist_6,
      hist_5   : io_w_req_bits_data_0_hist_5,
      hist_4   : io_w_req_bits_data_0_hist_4,
      hist_3   : io_w_req_bits_data_0_hist_3,
      hist_2   : io_w_req_bits_data_0_hist_2,
      hist_1   : io_w_req_bits_data_0_hist_1,
      hist_0   : io_w_req_bits_data_0_hist_0,
      tag      : io_w_req_bits_data_0_tag,
      decr_mode: io_w_req_bits_data_0_decr_mode
    };
    wdata[1] = '{
      hist_29  : io_w_req_bits_data_1_hist_29,
      hist_28  : io_w_req_bits_data_1_hist_28,
      hist_27  : io_w_req_bits_data_1_hist_27,
      hist_26  : io_w_req_bits_data_1_hist_26,
      hist_25  : io_w_req_bits_data_1_hist_25,
      hist_24  : io_w_req_bits_data_1_hist_24,
      hist_23  : io_w_req_bits_data_1_hist_23,
      hist_22  : io_w_req_bits_data_1_hist_22,
      hist_21  : io_w_req_bits_data_1_hist_21,
      hist_20  : io_w_req_bits_data_1_hist_20,
      hist_19  : io_w_req_bits_data_1_hist_19,
      hist_18  : io_w_req_bits_data_1_hist_18,
      hist_17  : io_w_req_bits_data_1_hist_17,
      hist_16  : io_w_req_bits_data_1_hist_16,
      hist_15  : io_w_req_bits_data_1_hist_15,
      hist_14  : io_w_req_bits_data_1_hist_14,
      hist_13  : io_w_req_bits_data_1_hist_13,
      hist_12  : io_w_req_bits_data_1_hist_12,
      hist_11  : io_w_req_bits_data_1_hist_11,
      hist_10  : io_w_req_bits_data_1_hist_10,
      hist_9   : io_w_req_bits_data_1_hist_9,
      hist_8   : io_w_req_bits_data_1_hist_8,
      hist_7   : io_w_req_bits_data_1_hist_7,
      hist_6   : io_w_req_bits_data_1_hist_6,
      hist_5   : io_w_req_bits_data_1_hist_5,
      hist_4   : io_w_req_bits_data_1_hist_4,
      hist_3   : io_w_req_bits_data_1_hist_3,
      hist_2   : io_w_req_bits_data_1_hist_2,
      hist_1   : io_w_req_bits_data_1_hist_1,
      hist_0   : io_w_req_bits_data_1_hist_0,
      tag      : io_w_req_bits_data_1_tag,
      decr_mode: io_w_req_bits_data_1_decr_mode
    };
  end

  xs_SRAMTemplate_core #(
    .SET(32), .WAY(2), .DATA_WIDTH(74), .BORE_AW(6),
    .ENABLE_RESET(0), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    .MASK_SEG_W(0), .BORE_NSEG(1),
    .EXT_CLOCKGATE(0), .MCP_HOLD(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_145.sv）：
    //   宏名 sram_array_1p32x148m74...l1b_* / io_r_resp_data_<k> 共 2 个 / bore_addr 6 位
    .G1_MACRO_SETS(32), .G1_MACRO_BITS(148), .G1_MACRO_MASK(74),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(2), .G1_BORE_AW(6)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* 本变体无 r ready 口 */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(rdata),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(wdata), .io_w_mask(io_w_req_bits_waymask),
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
  sram_array_1p32x148m74s1h0l1b_pftch_pht array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
  assign io_r_resp_data_0_hist_29 = rdata[0].hist_29;
  assign io_r_resp_data_0_hist_28 = rdata[0].hist_28;
  assign io_r_resp_data_0_hist_27 = rdata[0].hist_27;
  assign io_r_resp_data_0_hist_26 = rdata[0].hist_26;
  assign io_r_resp_data_0_hist_25 = rdata[0].hist_25;
  assign io_r_resp_data_0_hist_24 = rdata[0].hist_24;
  assign io_r_resp_data_0_hist_23 = rdata[0].hist_23;
  assign io_r_resp_data_0_hist_22 = rdata[0].hist_22;
  assign io_r_resp_data_0_hist_21 = rdata[0].hist_21;
  assign io_r_resp_data_0_hist_20 = rdata[0].hist_20;
  assign io_r_resp_data_0_hist_19 = rdata[0].hist_19;
  assign io_r_resp_data_0_hist_18 = rdata[0].hist_18;
  assign io_r_resp_data_0_hist_17 = rdata[0].hist_17;
  assign io_r_resp_data_0_hist_16 = rdata[0].hist_16;
  assign io_r_resp_data_0_hist_15 = rdata[0].hist_15;
  assign io_r_resp_data_0_hist_14 = rdata[0].hist_14;
  assign io_r_resp_data_0_hist_13 = rdata[0].hist_13;
  assign io_r_resp_data_0_hist_12 = rdata[0].hist_12;
  assign io_r_resp_data_0_hist_11 = rdata[0].hist_11;
  assign io_r_resp_data_0_hist_10 = rdata[0].hist_10;
  assign io_r_resp_data_0_hist_9 = rdata[0].hist_9;
  assign io_r_resp_data_0_hist_8 = rdata[0].hist_8;
  assign io_r_resp_data_0_hist_7 = rdata[0].hist_7;
  assign io_r_resp_data_0_hist_6 = rdata[0].hist_6;
  assign io_r_resp_data_0_hist_5 = rdata[0].hist_5;
  assign io_r_resp_data_0_hist_4 = rdata[0].hist_4;
  assign io_r_resp_data_0_hist_3 = rdata[0].hist_3;
  assign io_r_resp_data_0_hist_2 = rdata[0].hist_2;
  assign io_r_resp_data_0_hist_1 = rdata[0].hist_1;
  assign io_r_resp_data_0_hist_0 = rdata[0].hist_0;
  assign io_r_resp_data_0_tag = rdata[0].tag;
  assign io_r_resp_data_1_hist_29 = rdata[1].hist_29;
  assign io_r_resp_data_1_hist_28 = rdata[1].hist_28;
  assign io_r_resp_data_1_hist_27 = rdata[1].hist_27;
  assign io_r_resp_data_1_hist_26 = rdata[1].hist_26;
  assign io_r_resp_data_1_hist_25 = rdata[1].hist_25;
  assign io_r_resp_data_1_hist_24 = rdata[1].hist_24;
  assign io_r_resp_data_1_hist_23 = rdata[1].hist_23;
  assign io_r_resp_data_1_hist_22 = rdata[1].hist_22;
  assign io_r_resp_data_1_hist_21 = rdata[1].hist_21;
  assign io_r_resp_data_1_hist_20 = rdata[1].hist_20;
  assign io_r_resp_data_1_hist_19 = rdata[1].hist_19;
  assign io_r_resp_data_1_hist_18 = rdata[1].hist_18;
  assign io_r_resp_data_1_hist_17 = rdata[1].hist_17;
  assign io_r_resp_data_1_hist_16 = rdata[1].hist_16;
  assign io_r_resp_data_1_hist_15 = rdata[1].hist_15;
  assign io_r_resp_data_1_hist_14 = rdata[1].hist_14;
  assign io_r_resp_data_1_hist_13 = rdata[1].hist_13;
  assign io_r_resp_data_1_hist_12 = rdata[1].hist_12;
  assign io_r_resp_data_1_hist_11 = rdata[1].hist_11;
  assign io_r_resp_data_1_hist_10 = rdata[1].hist_10;
  assign io_r_resp_data_1_hist_9 = rdata[1].hist_9;
  assign io_r_resp_data_1_hist_8 = rdata[1].hist_8;
  assign io_r_resp_data_1_hist_7 = rdata[1].hist_7;
  assign io_r_resp_data_1_hist_6 = rdata[1].hist_6;
  assign io_r_resp_data_1_hist_5 = rdata[1].hist_5;
  assign io_r_resp_data_1_hist_4 = rdata[1].hist_4;
  assign io_r_resp_data_1_hist_3 = rdata[1].hist_3;
  assign io_r_resp_data_1_hist_2 = rdata[1].hist_2;
  assign io_r_resp_data_1_hist_1 = rdata[1].hist_1;
  assign io_r_resp_data_1_hist_0 = rdata[1].hist_0;
  assign io_r_resp_data_1_tag = rdata[1].tag;
endmodule
