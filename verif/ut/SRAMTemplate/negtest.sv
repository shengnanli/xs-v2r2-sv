// 负测台：证明 xs_SRAMTemplate_core 的 G1 锚点不变式**真的**会在 elaborate 期拦下
// 抄错的参数（不是摆设）。
//
// 对照原型 = SRAMTemplate_148（golden 宏 sram_array_1p512x76m19s1h0l1b_l2_tag：
// 512 set × 76 位、掩码粒度 19；golden 端口表里 io_r_resp_data_0..3 共 4 个口、
// boreChildrenBd_bore_addr 10 位）。三个负例各只动一处参数，逻辑一行不改：
//
//   +define+NEG_DW_NARROW  DATA_WIDTH 19→18 —— 本轮真实事故形态：位宽抄小，UT 只
//        驱动低位照样全绿，只有 FM 才炸。期望命中「WAY*DATA_WIDTH != golden 宏位宽」。
//   +define+NEG_WAY_SPLIT  4 way × 19 位抄成 2 way × 38 位 —— 乘积 76 仍然对，光比
//        总位宽抓不到。期望命中「WAY != golden io_r_resp_data_<k> 端口个数」。
//   +define+NEG_NO_ANCHOR  干脆不传 G1_* 锚点 —— 期望命中 fail-closed 那条，证明
//        「省略即免检」的 fail-open 口子不存在。
//
// 判据：VCS 必须在 **elaborate 期**非零退出（Error-[FEST] $fatal elaboration
// system task）。链接成功、跑出 NEGTEST_UNREACHED = 不变式形同虚设，判 FAIL。
module neg_sram_probe;
  localparam int unsigned SET = 512;
`ifdef NEG_WAY_SPLIT
  localparam int unsigned WAY = 2;
  localparam int unsigned DW  = 38;   // <-- 抄错：way/位宽劈法不对，乘积却仍是 76
`elsif NEG_DW_NARROW
  localparam int unsigned WAY = 4;
  localparam int unsigned DW  = 18;   // <-- 抄错：golden 宏是 ...x76m19...，19 抄成 18
`else
  localparam int unsigned WAY = 4;
  localparam int unsigned DW  = 19;   // 正确值（NEG_NO_ANCHOR 只考验"不传锚点"）
`endif
  localparam int unsigned BORE_AW = 10;
  localparam int unsigned AW      = $clog2(SET);
  localparam int unsigned MW      = WAY * DW;

  logic clock = 1'b0, reset = 1'b0;
  logic [AW-1:0]      setIdx = '0;
  logic [MW-1:0]      wdata  = '0, rdata = '0, resp, ram_wdata, bore_rdata;
  logic [WAY-1:0]     wmask  = '0, ram_wmask, bore_wmask = '0;
  logic [BORE_AW-1:0] bore_addr = '0;
  logic [AW-1:0]      ram_addr;
  logic               ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  logic               rdy, done, cg_en, cg_rck, cg_wck;

  xs_SRAMTemplate_core #(
    .SET(SET), .WAY(WAY), .DATA_WIDTH(DW), .BORE_AW(BORE_AW),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0), .USE_BITMASK(0),
    .MASK_SEG_W(0), .BORE_NSEG(1), .EXT_CLOCKGATE(0), .MCP_HOLD(0)
`ifndef NEG_NO_ANCHOR
    ,
    .G1_MACRO_SETS(512), .G1_MACRO_BITS(76), .G1_MACRO_MASK(19),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(4), .G1_BORE_AW(10)
`endif
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(rdy), .io_r_req_valid(1'b0), .io_r_req_bits_setIdx(setIdx),
    .io_r_resp_data(resp),
    .io_w_req_valid(1'b0), .io_w_req_bits_setIdx(setIdx),
    .io_w_req_bits_data(wdata), .io_w_mask(wmask), .io_resetDone(done),
    .io_broadcast_ram_hold(1'b0), .io_broadcast_ram_bypass(1'b0),
    .io_broadcast_ram_bp_clken(1'b0), .io_broadcast_cgen(1'b0),
    .io_mbistCgCtl_en(cg_en), .io_mbistCgCtl_rckEn(cg_rck),
    .io_mbistCgCtl_wckEn(cg_wck), .io_mbistCgCtl_rclk(1'b0),
    .boreChildrenBd_bore_addr(bore_addr), .boreChildrenBd_bore_addr_rd(bore_addr),
    .boreChildrenBd_bore_wdata(wdata), .boreChildrenBd_bore_wmask(bore_wmask),
    .boreChildrenBd_bore_re(1'b0), .boreChildrenBd_bore_we(1'b0),
    .boreChildrenBd_bore_rdata(bore_rdata), .boreChildrenBd_bore_ack(1'b0),
    .boreChildrenBd_bore_selectedOH(1'b0),
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(rdata)
  );

  initial begin
    $display("NEGTEST_UNREACHED: 抄错的参数没有被 elaborate 期不变式拦下");
    $finish;
  end
endmodule
