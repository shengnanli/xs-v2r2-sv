// SRAMTemplate_152.sv — L2 Directory 的元数据阵列（coherence meta，每 way 一条）
// 规模：512 set × 8 way × 13 位/way = 宏 104 位（sram_array_1p512x104m13s1h0l1b_l2_meta）；
//       写掩码 8 段 × 13 位，每 way 恰好一位；MBIST bore 口 104 位（整宏）；
//       上电清零 无；读保持 无；时钟门控 无（宏时钟直连 clock）；多周期宏 否。
// 本文件设参数并把 golden 的扁平端口装配成核要的位向量；核体见 rtl/common/xs_SRAMTemplate_core.sv。
module SRAMTemplate_152(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [8:0] io_r_req_bits_setIdx,
  output io_r_resp_data_0_dirty,
  output [1:0] io_r_resp_data_0_state,
  output io_r_resp_data_0_clients,
  output [1:0] io_r_resp_data_0_alias,
  output io_r_resp_data_0_prefetch,
  output [2:0] io_r_resp_data_0_prefetchSrc,
  output io_r_resp_data_0_accessed,
  output io_r_resp_data_0_tagErr,
  output io_r_resp_data_0_dataErr,
  output io_r_resp_data_1_dirty,
  output [1:0] io_r_resp_data_1_state,
  output io_r_resp_data_1_clients,
  output [1:0] io_r_resp_data_1_alias,
  output io_r_resp_data_1_prefetch,
  output [2:0] io_r_resp_data_1_prefetchSrc,
  output io_r_resp_data_1_accessed,
  output io_r_resp_data_1_tagErr,
  output io_r_resp_data_1_dataErr,
  output io_r_resp_data_2_dirty,
  output [1:0] io_r_resp_data_2_state,
  output io_r_resp_data_2_clients,
  output [1:0] io_r_resp_data_2_alias,
  output io_r_resp_data_2_prefetch,
  output [2:0] io_r_resp_data_2_prefetchSrc,
  output io_r_resp_data_2_accessed,
  output io_r_resp_data_2_tagErr,
  output io_r_resp_data_2_dataErr,
  output io_r_resp_data_3_dirty,
  output [1:0] io_r_resp_data_3_state,
  output io_r_resp_data_3_clients,
  output [1:0] io_r_resp_data_3_alias,
  output io_r_resp_data_3_prefetch,
  output [2:0] io_r_resp_data_3_prefetchSrc,
  output io_r_resp_data_3_accessed,
  output io_r_resp_data_3_tagErr,
  output io_r_resp_data_3_dataErr,
  output io_r_resp_data_4_dirty,
  output [1:0] io_r_resp_data_4_state,
  output io_r_resp_data_4_clients,
  output [1:0] io_r_resp_data_4_alias,
  output io_r_resp_data_4_prefetch,
  output [2:0] io_r_resp_data_4_prefetchSrc,
  output io_r_resp_data_4_accessed,
  output io_r_resp_data_4_tagErr,
  output io_r_resp_data_4_dataErr,
  output io_r_resp_data_5_dirty,
  output [1:0] io_r_resp_data_5_state,
  output io_r_resp_data_5_clients,
  output [1:0] io_r_resp_data_5_alias,
  output io_r_resp_data_5_prefetch,
  output [2:0] io_r_resp_data_5_prefetchSrc,
  output io_r_resp_data_5_accessed,
  output io_r_resp_data_5_tagErr,
  output io_r_resp_data_5_dataErr,
  output io_r_resp_data_6_dirty,
  output [1:0] io_r_resp_data_6_state,
  output io_r_resp_data_6_clients,
  output [1:0] io_r_resp_data_6_alias,
  output io_r_resp_data_6_prefetch,
  output [2:0] io_r_resp_data_6_prefetchSrc,
  output io_r_resp_data_6_accessed,
  output io_r_resp_data_6_tagErr,
  output io_r_resp_data_6_dataErr,
  output io_r_resp_data_7_dirty,
  output [1:0] io_r_resp_data_7_state,
  output io_r_resp_data_7_clients,
  output [1:0] io_r_resp_data_7_alias,
  output io_r_resp_data_7_prefetch,
  output [2:0] io_r_resp_data_7_prefetchSrc,
  output io_r_resp_data_7_accessed,
  output io_r_resp_data_7_tagErr,
  output io_r_resp_data_7_dataErr,
  output io_w_req_ready,
  input  io_w_req_valid,
  input  [8:0] io_w_req_bits_setIdx,
  input  io_w_req_bits_data_0_dirty,
  input  [1:0] io_w_req_bits_data_0_state,
  input  io_w_req_bits_data_0_clients,
  input  [1:0] io_w_req_bits_data_0_alias,
  input  io_w_req_bits_data_0_prefetch,
  input  [2:0] io_w_req_bits_data_0_prefetchSrc,
  input  io_w_req_bits_data_0_accessed,
  input  io_w_req_bits_data_0_tagErr,
  input  io_w_req_bits_data_0_dataErr,
  input  io_w_req_bits_data_1_dirty,
  input  [1:0] io_w_req_bits_data_1_state,
  input  io_w_req_bits_data_1_clients,
  input  [1:0] io_w_req_bits_data_1_alias,
  input  io_w_req_bits_data_1_prefetch,
  input  [2:0] io_w_req_bits_data_1_prefetchSrc,
  input  io_w_req_bits_data_1_accessed,
  input  io_w_req_bits_data_1_tagErr,
  input  io_w_req_bits_data_1_dataErr,
  input  io_w_req_bits_data_2_dirty,
  input  [1:0] io_w_req_bits_data_2_state,
  input  io_w_req_bits_data_2_clients,
  input  [1:0] io_w_req_bits_data_2_alias,
  input  io_w_req_bits_data_2_prefetch,
  input  [2:0] io_w_req_bits_data_2_prefetchSrc,
  input  io_w_req_bits_data_2_accessed,
  input  io_w_req_bits_data_2_tagErr,
  input  io_w_req_bits_data_2_dataErr,
  input  io_w_req_bits_data_3_dirty,
  input  [1:0] io_w_req_bits_data_3_state,
  input  io_w_req_bits_data_3_clients,
  input  [1:0] io_w_req_bits_data_3_alias,
  input  io_w_req_bits_data_3_prefetch,
  input  [2:0] io_w_req_bits_data_3_prefetchSrc,
  input  io_w_req_bits_data_3_accessed,
  input  io_w_req_bits_data_3_tagErr,
  input  io_w_req_bits_data_3_dataErr,
  input  io_w_req_bits_data_4_dirty,
  input  [1:0] io_w_req_bits_data_4_state,
  input  io_w_req_bits_data_4_clients,
  input  [1:0] io_w_req_bits_data_4_alias,
  input  io_w_req_bits_data_4_prefetch,
  input  [2:0] io_w_req_bits_data_4_prefetchSrc,
  input  io_w_req_bits_data_4_accessed,
  input  io_w_req_bits_data_4_tagErr,
  input  io_w_req_bits_data_4_dataErr,
  input  io_w_req_bits_data_5_dirty,
  input  [1:0] io_w_req_bits_data_5_state,
  input  io_w_req_bits_data_5_clients,
  input  [1:0] io_w_req_bits_data_5_alias,
  input  io_w_req_bits_data_5_prefetch,
  input  [2:0] io_w_req_bits_data_5_prefetchSrc,
  input  io_w_req_bits_data_5_accessed,
  input  io_w_req_bits_data_5_tagErr,
  input  io_w_req_bits_data_5_dataErr,
  input  io_w_req_bits_data_6_dirty,
  input  [1:0] io_w_req_bits_data_6_state,
  input  io_w_req_bits_data_6_clients,
  input  [1:0] io_w_req_bits_data_6_alias,
  input  io_w_req_bits_data_6_prefetch,
  input  [2:0] io_w_req_bits_data_6_prefetchSrc,
  input  io_w_req_bits_data_6_accessed,
  input  io_w_req_bits_data_6_tagErr,
  input  io_w_req_bits_data_6_dataErr,
  input  io_w_req_bits_data_7_dirty,
  input  [1:0] io_w_req_bits_data_7_state,
  input  io_w_req_bits_data_7_clients,
  input  [1:0] io_w_req_bits_data_7_alias,
  input  io_w_req_bits_data_7_prefetch,
  input  [2:0] io_w_req_bits_data_7_prefetchSrc,
  input  io_w_req_bits_data_7_accessed,
  input  io_w_req_bits_data_7_tagErr,
  input  io_w_req_bits_data_7_dataErr,
  input  [7:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  output io_resetDone,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  input  [103:0] boreChildrenBd_bore_wdata,
  input  [7:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [103:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [2:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [8:0]  ram_addr;
  wire [7:0]  ram_wmask;
  wire [103:0] ram_wdata, ram_rdata;
  wire        resetDone;   // 清零 FSM 已跑完（无清零 FSM 的变体恒 1）

  // 一条 13 位表项；字段顺序 = golden 写口拼接顺序（MSB→LSB），位 [12:0]
  typedef struct packed {
    logic       dirty;
    logic [1:0] state;
    logic       clients;
    logic [1:0] way_alias;      // golden 端口名叫 alias，是 SV 保留字，这里改名
    logic       prefetch;
    logic [2:0] prefetchSrc;
    logic       accessed;
    logic       tagErr;
    logic       dataErr;
  } entry_t;
  entry_t [7:0] wdata, rdata;   // 按 way 索引，[0] 在宏数据的低位

  always_comb begin
    wdata[0] = '{
      dirty      : io_w_req_bits_data_0_dirty,
      state      : io_w_req_bits_data_0_state,
      clients    : io_w_req_bits_data_0_clients,
      way_alias  : io_w_req_bits_data_0_alias,
      prefetch   : io_w_req_bits_data_0_prefetch,
      prefetchSrc: io_w_req_bits_data_0_prefetchSrc,
      accessed   : io_w_req_bits_data_0_accessed,
      tagErr     : io_w_req_bits_data_0_tagErr,
      dataErr    : io_w_req_bits_data_0_dataErr
    };
    wdata[1] = '{
      dirty      : io_w_req_bits_data_1_dirty,
      state      : io_w_req_bits_data_1_state,
      clients    : io_w_req_bits_data_1_clients,
      way_alias  : io_w_req_bits_data_1_alias,
      prefetch   : io_w_req_bits_data_1_prefetch,
      prefetchSrc: io_w_req_bits_data_1_prefetchSrc,
      accessed   : io_w_req_bits_data_1_accessed,
      tagErr     : io_w_req_bits_data_1_tagErr,
      dataErr    : io_w_req_bits_data_1_dataErr
    };
    wdata[2] = '{
      dirty      : io_w_req_bits_data_2_dirty,
      state      : io_w_req_bits_data_2_state,
      clients    : io_w_req_bits_data_2_clients,
      way_alias  : io_w_req_bits_data_2_alias,
      prefetch   : io_w_req_bits_data_2_prefetch,
      prefetchSrc: io_w_req_bits_data_2_prefetchSrc,
      accessed   : io_w_req_bits_data_2_accessed,
      tagErr     : io_w_req_bits_data_2_tagErr,
      dataErr    : io_w_req_bits_data_2_dataErr
    };
    wdata[3] = '{
      dirty      : io_w_req_bits_data_3_dirty,
      state      : io_w_req_bits_data_3_state,
      clients    : io_w_req_bits_data_3_clients,
      way_alias  : io_w_req_bits_data_3_alias,
      prefetch   : io_w_req_bits_data_3_prefetch,
      prefetchSrc: io_w_req_bits_data_3_prefetchSrc,
      accessed   : io_w_req_bits_data_3_accessed,
      tagErr     : io_w_req_bits_data_3_tagErr,
      dataErr    : io_w_req_bits_data_3_dataErr
    };
    wdata[4] = '{
      dirty      : io_w_req_bits_data_4_dirty,
      state      : io_w_req_bits_data_4_state,
      clients    : io_w_req_bits_data_4_clients,
      way_alias  : io_w_req_bits_data_4_alias,
      prefetch   : io_w_req_bits_data_4_prefetch,
      prefetchSrc: io_w_req_bits_data_4_prefetchSrc,
      accessed   : io_w_req_bits_data_4_accessed,
      tagErr     : io_w_req_bits_data_4_tagErr,
      dataErr    : io_w_req_bits_data_4_dataErr
    };
    wdata[5] = '{
      dirty      : io_w_req_bits_data_5_dirty,
      state      : io_w_req_bits_data_5_state,
      clients    : io_w_req_bits_data_5_clients,
      way_alias  : io_w_req_bits_data_5_alias,
      prefetch   : io_w_req_bits_data_5_prefetch,
      prefetchSrc: io_w_req_bits_data_5_prefetchSrc,
      accessed   : io_w_req_bits_data_5_accessed,
      tagErr     : io_w_req_bits_data_5_tagErr,
      dataErr    : io_w_req_bits_data_5_dataErr
    };
    wdata[6] = '{
      dirty      : io_w_req_bits_data_6_dirty,
      state      : io_w_req_bits_data_6_state,
      clients    : io_w_req_bits_data_6_clients,
      way_alias  : io_w_req_bits_data_6_alias,
      prefetch   : io_w_req_bits_data_6_prefetch,
      prefetchSrc: io_w_req_bits_data_6_prefetchSrc,
      accessed   : io_w_req_bits_data_6_accessed,
      tagErr     : io_w_req_bits_data_6_tagErr,
      dataErr    : io_w_req_bits_data_6_dataErr
    };
    wdata[7] = '{
      dirty      : io_w_req_bits_data_7_dirty,
      state      : io_w_req_bits_data_7_state,
      clients    : io_w_req_bits_data_7_clients,
      way_alias  : io_w_req_bits_data_7_alias,
      prefetch   : io_w_req_bits_data_7_prefetch,
      prefetchSrc: io_w_req_bits_data_7_prefetchSrc,
      accessed   : io_w_req_bits_data_7_accessed,
      tagErr     : io_w_req_bits_data_7_tagErr,
      dataErr    : io_w_req_bits_data_7_dataErr
    };
  end

  xs_SRAMTemplate_core #(
    .SET(512), .WAY(8), .DATA_WIDTH(13), .BORE_AW(10),
    .ENABLE_RESET(0), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0),
    .MASK_SEG_W(0), .BORE_NSEG(1),
    .EXT_CLOCKGATE(0), .MCP_HOLD(0),
    // G1 锚点（勿手改，全部来自 golden SRAMTemplate_152.sv）：
    //   宏名 sram_array_1p512x104m13...l1b_* / io_r_resp_data_<k> 共 8 个 / bore_addr 10 位
    .G1_MACRO_SETS(512), .G1_MACRO_BITS(104), .G1_MACRO_MASK(13),
    .G1_MACRO_LAT(1), .G1_WAY_PORTS(8), .G1_BORE_AW(10)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(rdata),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(wdata), .io_w_mask(io_w_req_bits_waymask),
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
  sram_array_1p512x104m13s1h0l1b_l2_meta array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
  assign io_r_resp_data_0_dirty = rdata[0].dirty;
  assign io_r_resp_data_0_state = rdata[0].state;
  assign io_r_resp_data_0_clients = rdata[0].clients;
  assign io_r_resp_data_0_alias = rdata[0].way_alias;
  assign io_r_resp_data_0_prefetch = rdata[0].prefetch;
  assign io_r_resp_data_0_prefetchSrc = rdata[0].prefetchSrc;
  assign io_r_resp_data_0_accessed = rdata[0].accessed;
  assign io_r_resp_data_0_tagErr = rdata[0].tagErr;
  assign io_r_resp_data_0_dataErr = rdata[0].dataErr;
  assign io_r_resp_data_1_dirty = rdata[1].dirty;
  assign io_r_resp_data_1_state = rdata[1].state;
  assign io_r_resp_data_1_clients = rdata[1].clients;
  assign io_r_resp_data_1_alias = rdata[1].way_alias;
  assign io_r_resp_data_1_prefetch = rdata[1].prefetch;
  assign io_r_resp_data_1_prefetchSrc = rdata[1].prefetchSrc;
  assign io_r_resp_data_1_accessed = rdata[1].accessed;
  assign io_r_resp_data_1_tagErr = rdata[1].tagErr;
  assign io_r_resp_data_1_dataErr = rdata[1].dataErr;
  assign io_r_resp_data_2_dirty = rdata[2].dirty;
  assign io_r_resp_data_2_state = rdata[2].state;
  assign io_r_resp_data_2_clients = rdata[2].clients;
  assign io_r_resp_data_2_alias = rdata[2].way_alias;
  assign io_r_resp_data_2_prefetch = rdata[2].prefetch;
  assign io_r_resp_data_2_prefetchSrc = rdata[2].prefetchSrc;
  assign io_r_resp_data_2_accessed = rdata[2].accessed;
  assign io_r_resp_data_2_tagErr = rdata[2].tagErr;
  assign io_r_resp_data_2_dataErr = rdata[2].dataErr;
  assign io_r_resp_data_3_dirty = rdata[3].dirty;
  assign io_r_resp_data_3_state = rdata[3].state;
  assign io_r_resp_data_3_clients = rdata[3].clients;
  assign io_r_resp_data_3_alias = rdata[3].way_alias;
  assign io_r_resp_data_3_prefetch = rdata[3].prefetch;
  assign io_r_resp_data_3_prefetchSrc = rdata[3].prefetchSrc;
  assign io_r_resp_data_3_accessed = rdata[3].accessed;
  assign io_r_resp_data_3_tagErr = rdata[3].tagErr;
  assign io_r_resp_data_3_dataErr = rdata[3].dataErr;
  assign io_r_resp_data_4_dirty = rdata[4].dirty;
  assign io_r_resp_data_4_state = rdata[4].state;
  assign io_r_resp_data_4_clients = rdata[4].clients;
  assign io_r_resp_data_4_alias = rdata[4].way_alias;
  assign io_r_resp_data_4_prefetch = rdata[4].prefetch;
  assign io_r_resp_data_4_prefetchSrc = rdata[4].prefetchSrc;
  assign io_r_resp_data_4_accessed = rdata[4].accessed;
  assign io_r_resp_data_4_tagErr = rdata[4].tagErr;
  assign io_r_resp_data_4_dataErr = rdata[4].dataErr;
  assign io_r_resp_data_5_dirty = rdata[5].dirty;
  assign io_r_resp_data_5_state = rdata[5].state;
  assign io_r_resp_data_5_clients = rdata[5].clients;
  assign io_r_resp_data_5_alias = rdata[5].way_alias;
  assign io_r_resp_data_5_prefetch = rdata[5].prefetch;
  assign io_r_resp_data_5_prefetchSrc = rdata[5].prefetchSrc;
  assign io_r_resp_data_5_accessed = rdata[5].accessed;
  assign io_r_resp_data_5_tagErr = rdata[5].tagErr;
  assign io_r_resp_data_5_dataErr = rdata[5].dataErr;
  assign io_r_resp_data_6_dirty = rdata[6].dirty;
  assign io_r_resp_data_6_state = rdata[6].state;
  assign io_r_resp_data_6_clients = rdata[6].clients;
  assign io_r_resp_data_6_alias = rdata[6].way_alias;
  assign io_r_resp_data_6_prefetch = rdata[6].prefetch;
  assign io_r_resp_data_6_prefetchSrc = rdata[6].prefetchSrc;
  assign io_r_resp_data_6_accessed = rdata[6].accessed;
  assign io_r_resp_data_6_tagErr = rdata[6].tagErr;
  assign io_r_resp_data_6_dataErr = rdata[6].dataErr;
  assign io_r_resp_data_7_dirty = rdata[7].dirty;
  assign io_r_resp_data_7_state = rdata[7].state;
  assign io_r_resp_data_7_clients = rdata[7].clients;
  assign io_r_resp_data_7_alias = rdata[7].way_alias;
  assign io_r_resp_data_7_prefetch = rdata[7].prefetch;
  assign io_r_resp_data_7_prefetchSrc = rdata[7].prefetchSrc;
  assign io_r_resp_data_7_accessed = rdata[7].accessed;
  assign io_r_resp_data_7_tagErr = rdata[7].tagErr;
  assign io_r_resp_data_7_dataErr = rdata[7].dataErr;
  assign io_w_req_ready = resetDone;   // 清零期间不收写
  assign io_resetDone = resetDone;
endmodule
