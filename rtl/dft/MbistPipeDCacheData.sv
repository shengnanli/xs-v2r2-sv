// MbistPipeDCacheData.sv —— MBIST 分发树的 叶子(leaf) 节点：DCache 数据阵列 8 bank x 4 way 的 SRAM
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      叶子：直接驱动 SRAM 的 bore 口，32 个 child（toSRAM_0..31）
//   例化于    BankedDataArray
//   MBIST array id  0x00..0x1F（共 32 个），故 ARRAY_W = clog2(0x1F+1) = 5 位
//   上游总线  addr/addr_rd 9 位  indata/outdata 72 位  be 1 位
//   规模      golden 937 行 / 333 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体因此出现 1/2/3/4/5 位并存的参差宽度——这正是本家族最容易写错的地方：
//   child 0   id 0x00          array 1 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 1   id 0x01          array 1 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 2   id 0x02          array 2 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 3   id 0x03          array 2 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 4   id 0x04          array 3 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 5   id 0x05          array 3 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 6   id 0x06          array 3 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 7   id 0x07          array 3 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 8   id 0x08          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 9   id 0x09          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 10  id 0x0A          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 11  id 0x0B          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 12  id 0x0C          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 13  id 0x0D          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 14  id 0x0E          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 15  id 0x0F          array 4 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 16  id 0x10          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 17  id 0x11          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 18  id 0x12          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 19  id 0x13          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 20  id 0x14          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 21  id 0x15          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 22  id 0x16          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 23  id 0x17          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 24  id 0x18          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 25  id 0x19          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 26  id 0x1A          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 27  id 0x1B          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 28  id 0x1C          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 29  id 0x1D          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 30  id 0x1E          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//   child 31  id 0x1F          array 5 位  addr 9   data 72   be 1   selectedOH 1 位
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(MbistPipeDCacheData) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module MbistPipeDCacheData (
  input  logic clock,
  input  logic reset,
  input  logic [4:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic mbist_be,
  input  logic [8:0] mbist_addr,
  input  logic [71:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [8:0] mbist_addr_rd,
  output logic [71:0] mbist_outdata,
  output logic [8:0] toSRAM_0_addr,
  output logic [8:0] toSRAM_0_addr_rd,
  output logic [71:0] toSRAM_0_wdata,
  output logic toSRAM_0_wmask,
  output logic toSRAM_0_re,
  output logic toSRAM_0_we,
  input  logic [71:0] toSRAM_0_rdata,
  output logic toSRAM_0_ack,
  output logic toSRAM_0_selectedOH,
  output logic toSRAM_0_array,
  output logic [8:0] toSRAM_1_addr,
  output logic [8:0] toSRAM_1_addr_rd,
  output logic [71:0] toSRAM_1_wdata,
  output logic toSRAM_1_wmask,
  output logic toSRAM_1_re,
  output logic toSRAM_1_we,
  input  logic [71:0] toSRAM_1_rdata,
  output logic toSRAM_1_ack,
  output logic toSRAM_1_selectedOH,
  output logic toSRAM_1_array,
  output logic [8:0] toSRAM_2_addr,
  output logic [8:0] toSRAM_2_addr_rd,
  output logic [71:0] toSRAM_2_wdata,
  output logic toSRAM_2_wmask,
  output logic toSRAM_2_re,
  output logic toSRAM_2_we,
  input  logic [71:0] toSRAM_2_rdata,
  output logic toSRAM_2_ack,
  output logic toSRAM_2_selectedOH,
  output logic [1:0] toSRAM_2_array,
  output logic [8:0] toSRAM_3_addr,
  output logic [8:0] toSRAM_3_addr_rd,
  output logic [71:0] toSRAM_3_wdata,
  output logic toSRAM_3_wmask,
  output logic toSRAM_3_re,
  output logic toSRAM_3_we,
  input  logic [71:0] toSRAM_3_rdata,
  output logic toSRAM_3_ack,
  output logic toSRAM_3_selectedOH,
  output logic [1:0] toSRAM_3_array,
  output logic [8:0] toSRAM_4_addr,
  output logic [8:0] toSRAM_4_addr_rd,
  output logic [71:0] toSRAM_4_wdata,
  output logic toSRAM_4_wmask,
  output logic toSRAM_4_re,
  output logic toSRAM_4_we,
  input  logic [71:0] toSRAM_4_rdata,
  output logic toSRAM_4_ack,
  output logic toSRAM_4_selectedOH,
  output logic [2:0] toSRAM_4_array,
  output logic [8:0] toSRAM_5_addr,
  output logic [8:0] toSRAM_5_addr_rd,
  output logic [71:0] toSRAM_5_wdata,
  output logic toSRAM_5_wmask,
  output logic toSRAM_5_re,
  output logic toSRAM_5_we,
  input  logic [71:0] toSRAM_5_rdata,
  output logic toSRAM_5_ack,
  output logic toSRAM_5_selectedOH,
  output logic [2:0] toSRAM_5_array,
  output logic [8:0] toSRAM_6_addr,
  output logic [8:0] toSRAM_6_addr_rd,
  output logic [71:0] toSRAM_6_wdata,
  output logic toSRAM_6_wmask,
  output logic toSRAM_6_re,
  output logic toSRAM_6_we,
  input  logic [71:0] toSRAM_6_rdata,
  output logic toSRAM_6_ack,
  output logic toSRAM_6_selectedOH,
  output logic [2:0] toSRAM_6_array,
  output logic [8:0] toSRAM_7_addr,
  output logic [8:0] toSRAM_7_addr_rd,
  output logic [71:0] toSRAM_7_wdata,
  output logic toSRAM_7_wmask,
  output logic toSRAM_7_re,
  output logic toSRAM_7_we,
  input  logic [71:0] toSRAM_7_rdata,
  output logic toSRAM_7_ack,
  output logic toSRAM_7_selectedOH,
  output logic [2:0] toSRAM_7_array,
  output logic [8:0] toSRAM_8_addr,
  output logic [8:0] toSRAM_8_addr_rd,
  output logic [71:0] toSRAM_8_wdata,
  output logic toSRAM_8_wmask,
  output logic toSRAM_8_re,
  output logic toSRAM_8_we,
  input  logic [71:0] toSRAM_8_rdata,
  output logic toSRAM_8_ack,
  output logic toSRAM_8_selectedOH,
  output logic [3:0] toSRAM_8_array,
  output logic [8:0] toSRAM_9_addr,
  output logic [8:0] toSRAM_9_addr_rd,
  output logic [71:0] toSRAM_9_wdata,
  output logic toSRAM_9_wmask,
  output logic toSRAM_9_re,
  output logic toSRAM_9_we,
  input  logic [71:0] toSRAM_9_rdata,
  output logic toSRAM_9_ack,
  output logic toSRAM_9_selectedOH,
  output logic [3:0] toSRAM_9_array,
  output logic [8:0] toSRAM_10_addr,
  output logic [8:0] toSRAM_10_addr_rd,
  output logic [71:0] toSRAM_10_wdata,
  output logic toSRAM_10_wmask,
  output logic toSRAM_10_re,
  output logic toSRAM_10_we,
  input  logic [71:0] toSRAM_10_rdata,
  output logic toSRAM_10_ack,
  output logic toSRAM_10_selectedOH,
  output logic [3:0] toSRAM_10_array,
  output logic [8:0] toSRAM_11_addr,
  output logic [8:0] toSRAM_11_addr_rd,
  output logic [71:0] toSRAM_11_wdata,
  output logic toSRAM_11_wmask,
  output logic toSRAM_11_re,
  output logic toSRAM_11_we,
  input  logic [71:0] toSRAM_11_rdata,
  output logic toSRAM_11_ack,
  output logic toSRAM_11_selectedOH,
  output logic [3:0] toSRAM_11_array,
  output logic [8:0] toSRAM_12_addr,
  output logic [8:0] toSRAM_12_addr_rd,
  output logic [71:0] toSRAM_12_wdata,
  output logic toSRAM_12_wmask,
  output logic toSRAM_12_re,
  output logic toSRAM_12_we,
  input  logic [71:0] toSRAM_12_rdata,
  output logic toSRAM_12_ack,
  output logic toSRAM_12_selectedOH,
  output logic [3:0] toSRAM_12_array,
  output logic [8:0] toSRAM_13_addr,
  output logic [8:0] toSRAM_13_addr_rd,
  output logic [71:0] toSRAM_13_wdata,
  output logic toSRAM_13_wmask,
  output logic toSRAM_13_re,
  output logic toSRAM_13_we,
  input  logic [71:0] toSRAM_13_rdata,
  output logic toSRAM_13_ack,
  output logic toSRAM_13_selectedOH,
  output logic [3:0] toSRAM_13_array,
  output logic [8:0] toSRAM_14_addr,
  output logic [8:0] toSRAM_14_addr_rd,
  output logic [71:0] toSRAM_14_wdata,
  output logic toSRAM_14_wmask,
  output logic toSRAM_14_re,
  output logic toSRAM_14_we,
  input  logic [71:0] toSRAM_14_rdata,
  output logic toSRAM_14_ack,
  output logic toSRAM_14_selectedOH,
  output logic [3:0] toSRAM_14_array,
  output logic [8:0] toSRAM_15_addr,
  output logic [8:0] toSRAM_15_addr_rd,
  output logic [71:0] toSRAM_15_wdata,
  output logic toSRAM_15_wmask,
  output logic toSRAM_15_re,
  output logic toSRAM_15_we,
  input  logic [71:0] toSRAM_15_rdata,
  output logic toSRAM_15_ack,
  output logic toSRAM_15_selectedOH,
  output logic [3:0] toSRAM_15_array,
  output logic [8:0] toSRAM_16_addr,
  output logic [8:0] toSRAM_16_addr_rd,
  output logic [71:0] toSRAM_16_wdata,
  output logic toSRAM_16_wmask,
  output logic toSRAM_16_re,
  output logic toSRAM_16_we,
  input  logic [71:0] toSRAM_16_rdata,
  output logic toSRAM_16_ack,
  output logic toSRAM_16_selectedOH,
  output logic [4:0] toSRAM_16_array,
  output logic [8:0] toSRAM_17_addr,
  output logic [8:0] toSRAM_17_addr_rd,
  output logic [71:0] toSRAM_17_wdata,
  output logic toSRAM_17_wmask,
  output logic toSRAM_17_re,
  output logic toSRAM_17_we,
  input  logic [71:0] toSRAM_17_rdata,
  output logic toSRAM_17_ack,
  output logic toSRAM_17_selectedOH,
  output logic [4:0] toSRAM_17_array,
  output logic [8:0] toSRAM_18_addr,
  output logic [8:0] toSRAM_18_addr_rd,
  output logic [71:0] toSRAM_18_wdata,
  output logic toSRAM_18_wmask,
  output logic toSRAM_18_re,
  output logic toSRAM_18_we,
  input  logic [71:0] toSRAM_18_rdata,
  output logic toSRAM_18_ack,
  output logic toSRAM_18_selectedOH,
  output logic [4:0] toSRAM_18_array,
  output logic [8:0] toSRAM_19_addr,
  output logic [8:0] toSRAM_19_addr_rd,
  output logic [71:0] toSRAM_19_wdata,
  output logic toSRAM_19_wmask,
  output logic toSRAM_19_re,
  output logic toSRAM_19_we,
  input  logic [71:0] toSRAM_19_rdata,
  output logic toSRAM_19_ack,
  output logic toSRAM_19_selectedOH,
  output logic [4:0] toSRAM_19_array,
  output logic [8:0] toSRAM_20_addr,
  output logic [8:0] toSRAM_20_addr_rd,
  output logic [71:0] toSRAM_20_wdata,
  output logic toSRAM_20_wmask,
  output logic toSRAM_20_re,
  output logic toSRAM_20_we,
  input  logic [71:0] toSRAM_20_rdata,
  output logic toSRAM_20_ack,
  output logic toSRAM_20_selectedOH,
  output logic [4:0] toSRAM_20_array,
  output logic [8:0] toSRAM_21_addr,
  output logic [8:0] toSRAM_21_addr_rd,
  output logic [71:0] toSRAM_21_wdata,
  output logic toSRAM_21_wmask,
  output logic toSRAM_21_re,
  output logic toSRAM_21_we,
  input  logic [71:0] toSRAM_21_rdata,
  output logic toSRAM_21_ack,
  output logic toSRAM_21_selectedOH,
  output logic [4:0] toSRAM_21_array,
  output logic [8:0] toSRAM_22_addr,
  output logic [8:0] toSRAM_22_addr_rd,
  output logic [71:0] toSRAM_22_wdata,
  output logic toSRAM_22_wmask,
  output logic toSRAM_22_re,
  output logic toSRAM_22_we,
  input  logic [71:0] toSRAM_22_rdata,
  output logic toSRAM_22_ack,
  output logic toSRAM_22_selectedOH,
  output logic [4:0] toSRAM_22_array,
  output logic [8:0] toSRAM_23_addr,
  output logic [8:0] toSRAM_23_addr_rd,
  output logic [71:0] toSRAM_23_wdata,
  output logic toSRAM_23_wmask,
  output logic toSRAM_23_re,
  output logic toSRAM_23_we,
  input  logic [71:0] toSRAM_23_rdata,
  output logic toSRAM_23_ack,
  output logic toSRAM_23_selectedOH,
  output logic [4:0] toSRAM_23_array,
  output logic [8:0] toSRAM_24_addr,
  output logic [8:0] toSRAM_24_addr_rd,
  output logic [71:0] toSRAM_24_wdata,
  output logic toSRAM_24_wmask,
  output logic toSRAM_24_re,
  output logic toSRAM_24_we,
  input  logic [71:0] toSRAM_24_rdata,
  output logic toSRAM_24_ack,
  output logic toSRAM_24_selectedOH,
  output logic [4:0] toSRAM_24_array,
  output logic [8:0] toSRAM_25_addr,
  output logic [8:0] toSRAM_25_addr_rd,
  output logic [71:0] toSRAM_25_wdata,
  output logic toSRAM_25_wmask,
  output logic toSRAM_25_re,
  output logic toSRAM_25_we,
  input  logic [71:0] toSRAM_25_rdata,
  output logic toSRAM_25_ack,
  output logic toSRAM_25_selectedOH,
  output logic [4:0] toSRAM_25_array,
  output logic [8:0] toSRAM_26_addr,
  output logic [8:0] toSRAM_26_addr_rd,
  output logic [71:0] toSRAM_26_wdata,
  output logic toSRAM_26_wmask,
  output logic toSRAM_26_re,
  output logic toSRAM_26_we,
  input  logic [71:0] toSRAM_26_rdata,
  output logic toSRAM_26_ack,
  output logic toSRAM_26_selectedOH,
  output logic [4:0] toSRAM_26_array,
  output logic [8:0] toSRAM_27_addr,
  output logic [8:0] toSRAM_27_addr_rd,
  output logic [71:0] toSRAM_27_wdata,
  output logic toSRAM_27_wmask,
  output logic toSRAM_27_re,
  output logic toSRAM_27_we,
  input  logic [71:0] toSRAM_27_rdata,
  output logic toSRAM_27_ack,
  output logic toSRAM_27_selectedOH,
  output logic [4:0] toSRAM_27_array,
  output logic [8:0] toSRAM_28_addr,
  output logic [8:0] toSRAM_28_addr_rd,
  output logic [71:0] toSRAM_28_wdata,
  output logic toSRAM_28_wmask,
  output logic toSRAM_28_re,
  output logic toSRAM_28_we,
  input  logic [71:0] toSRAM_28_rdata,
  output logic toSRAM_28_ack,
  output logic toSRAM_28_selectedOH,
  output logic [4:0] toSRAM_28_array,
  output logic [8:0] toSRAM_29_addr,
  output logic [8:0] toSRAM_29_addr_rd,
  output logic [71:0] toSRAM_29_wdata,
  output logic toSRAM_29_wmask,
  output logic toSRAM_29_re,
  output logic toSRAM_29_we,
  input  logic [71:0] toSRAM_29_rdata,
  output logic toSRAM_29_ack,
  output logic toSRAM_29_selectedOH,
  output logic [4:0] toSRAM_29_array,
  output logic [8:0] toSRAM_30_addr,
  output logic [8:0] toSRAM_30_addr_rd,
  output logic [71:0] toSRAM_30_wdata,
  output logic toSRAM_30_wmask,
  output logic toSRAM_30_re,
  output logic toSRAM_30_we,
  input  logic [71:0] toSRAM_30_rdata,
  output logic toSRAM_30_ack,
  output logic toSRAM_30_selectedOH,
  output logic [4:0] toSRAM_30_array,
  output logic [8:0] toSRAM_31_addr,
  output logic [8:0] toSRAM_31_addr_rd,
  output logic [71:0] toSRAM_31_wdata,
  output logic toSRAM_31_wmask,
  output logic toSRAM_31_re,
  output logic toSRAM_31_we,
  input  logic [71:0] toSRAM_31_rdata,
  output logic toSRAM_31_ack,
  output logic toSRAM_31_selectedOH,
  output logic [4:0] toSRAM_31_array
);

  localparam int unsigned N_CHILD = 32;
  localparam int unsigned MAX_IDS = 1;
  localparam int unsigned ARRAY_W = 5;
  localparam int unsigned ADDR_W  = 9;
  localparam int unsigned DATA_W  = 72;
  localparam int unsigned BE_W    = 1;

  logic [ARRAY_W-1:0] ch_array      [N_CHILD];
  logic               ch_all        [N_CHILD];
  logic               ch_reqpulse   [N_CHILD];
  logic               ch_writeen    [N_CHILD];
  logic [BE_W-1:0]    ch_wmask      [N_CHILD];
  logic [ADDR_W-1:0]  ch_addr       [N_CHILD];
  logic [DATA_W-1:0]  ch_wdata      [N_CHILD];
  logic               ch_readen     [N_CHILD];
  logic [ADDR_W-1:0]  ch_addr_rd    [N_CHILD];
  logic [MAX_IDS-1:0] ch_selectedOH [N_CHILD];
  logic [DATA_W-1:0]  ch_rdata      [N_CHILD];
  logic               ch_ack        [N_CHILD];

  xs_mbist_pipe_core #(
    .IS_NODE (1'b0),
    .N_CHILD (N_CHILD),
    .ARRAY_W (ARRAY_W),
    .BE_W    (BE_W),
    .ADDR_W  (ADDR_W),
    .DATA_W  (DATA_W),
    .ID_LO   ('{'h00, 'h01, 'h02, 'h03, 'h04, 'h05, 'h06, 'h07, 'h08, 'h09, 'h0A, 'h0B, 'h0C, 'h0D, 'h0E, 'h0F, 'h10, 'h11, 'h12, 'h13, 'h14, 'h15, 'h16, 'h17, 'h18, 'h19, 'h1A, 'h1B, 'h1C, 'h1D, 'h1E, 'h1F}),
    .ID_CNT  ('{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}),
    .MAX_IDS (MAX_IDS)
  ) u_core (
    .clock (clock), .reset (reset),
    .mbist_array (mbist_array), .mbist_all (mbist_all), .mbist_req (mbist_req),
    .mbist_ack (mbist_ack), .mbist_writeen (mbist_writeen), .mbist_be (mbist_be),
    .mbist_addr (mbist_addr), .mbist_indata (mbist_indata), .mbist_readen (mbist_readen),
    .mbist_addr_rd (mbist_addr_rd), .mbist_outdata (mbist_outdata),
    .ch_array (ch_array), .ch_all (ch_all), .ch_reqpulse (ch_reqpulse),
    .ch_writeen (ch_writeen), .ch_wmask (ch_wmask), .ch_addr (ch_addr),
    .ch_wdata (ch_wdata), .ch_readen (ch_readen), .ch_addr_rd (ch_addr_rd),
    .ch_selectedOH (ch_selectedOH), .ch_rdata (ch_rdata), .ch_ack (ch_ack)
  );

  // 端口展平：核按上游最大位宽给，这里截到每个 child 的实宽；读数据反向零扩展。
  // ---- child 0：array id 0x00 ----
  assign toSRAM_0_addr       = ch_addr[0];
  assign toSRAM_0_addr_rd    = ch_addr_rd[0];
  assign toSRAM_0_wdata      = ch_wdata[0];
  assign toSRAM_0_wmask      = ch_wmask[0];
  assign toSRAM_0_re         = ch_readen[0];
  assign toSRAM_0_we         = ch_writeen[0];
  assign toSRAM_0_ack        = ch_reqpulse[0];
  assign toSRAM_0_selectedOH = ch_selectedOH[0];
  assign toSRAM_0_array      = ch_array[0][0:0];
  assign ch_rdata[0]    = DATA_W'(toSRAM_0_rdata);
  assign ch_ack[0]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 1：array id 0x01 ----
  assign toSRAM_1_addr       = ch_addr[1];
  assign toSRAM_1_addr_rd    = ch_addr_rd[1];
  assign toSRAM_1_wdata      = ch_wdata[1];
  assign toSRAM_1_wmask      = ch_wmask[1];
  assign toSRAM_1_re         = ch_readen[1];
  assign toSRAM_1_we         = ch_writeen[1];
  assign toSRAM_1_ack        = ch_reqpulse[1];
  assign toSRAM_1_selectedOH = ch_selectedOH[1];
  assign toSRAM_1_array      = ch_array[1][0:0];
  assign ch_rdata[1]    = DATA_W'(toSRAM_1_rdata);
  assign ch_ack[1]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 2：array id 0x02 ----
  assign toSRAM_2_addr       = ch_addr[2];
  assign toSRAM_2_addr_rd    = ch_addr_rd[2];
  assign toSRAM_2_wdata      = ch_wdata[2];
  assign toSRAM_2_wmask      = ch_wmask[2];
  assign toSRAM_2_re         = ch_readen[2];
  assign toSRAM_2_we         = ch_writeen[2];
  assign toSRAM_2_ack        = ch_reqpulse[2];
  assign toSRAM_2_selectedOH = ch_selectedOH[2];
  assign toSRAM_2_array      = ch_array[2][1:0];
  assign ch_rdata[2]    = DATA_W'(toSRAM_2_rdata);
  assign ch_ack[2]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 3：array id 0x03 ----
  assign toSRAM_3_addr       = ch_addr[3];
  assign toSRAM_3_addr_rd    = ch_addr_rd[3];
  assign toSRAM_3_wdata      = ch_wdata[3];
  assign toSRAM_3_wmask      = ch_wmask[3];
  assign toSRAM_3_re         = ch_readen[3];
  assign toSRAM_3_we         = ch_writeen[3];
  assign toSRAM_3_ack        = ch_reqpulse[3];
  assign toSRAM_3_selectedOH = ch_selectedOH[3];
  assign toSRAM_3_array      = ch_array[3][1:0];
  assign ch_rdata[3]    = DATA_W'(toSRAM_3_rdata);
  assign ch_ack[3]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 4：array id 0x04 ----
  assign toSRAM_4_addr       = ch_addr[4];
  assign toSRAM_4_addr_rd    = ch_addr_rd[4];
  assign toSRAM_4_wdata      = ch_wdata[4];
  assign toSRAM_4_wmask      = ch_wmask[4];
  assign toSRAM_4_re         = ch_readen[4];
  assign toSRAM_4_we         = ch_writeen[4];
  assign toSRAM_4_ack        = ch_reqpulse[4];
  assign toSRAM_4_selectedOH = ch_selectedOH[4];
  assign toSRAM_4_array      = ch_array[4][2:0];
  assign ch_rdata[4]    = DATA_W'(toSRAM_4_rdata);
  assign ch_ack[4]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 5：array id 0x05 ----
  assign toSRAM_5_addr       = ch_addr[5];
  assign toSRAM_5_addr_rd    = ch_addr_rd[5];
  assign toSRAM_5_wdata      = ch_wdata[5];
  assign toSRAM_5_wmask      = ch_wmask[5];
  assign toSRAM_5_re         = ch_readen[5];
  assign toSRAM_5_we         = ch_writeen[5];
  assign toSRAM_5_ack        = ch_reqpulse[5];
  assign toSRAM_5_selectedOH = ch_selectedOH[5];
  assign toSRAM_5_array      = ch_array[5][2:0];
  assign ch_rdata[5]    = DATA_W'(toSRAM_5_rdata);
  assign ch_ack[5]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 6：array id 0x06 ----
  assign toSRAM_6_addr       = ch_addr[6];
  assign toSRAM_6_addr_rd    = ch_addr_rd[6];
  assign toSRAM_6_wdata      = ch_wdata[6];
  assign toSRAM_6_wmask      = ch_wmask[6];
  assign toSRAM_6_re         = ch_readen[6];
  assign toSRAM_6_we         = ch_writeen[6];
  assign toSRAM_6_ack        = ch_reqpulse[6];
  assign toSRAM_6_selectedOH = ch_selectedOH[6];
  assign toSRAM_6_array      = ch_array[6][2:0];
  assign ch_rdata[6]    = DATA_W'(toSRAM_6_rdata);
  assign ch_ack[6]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 7：array id 0x07 ----
  assign toSRAM_7_addr       = ch_addr[7];
  assign toSRAM_7_addr_rd    = ch_addr_rd[7];
  assign toSRAM_7_wdata      = ch_wdata[7];
  assign toSRAM_7_wmask      = ch_wmask[7];
  assign toSRAM_7_re         = ch_readen[7];
  assign toSRAM_7_we         = ch_writeen[7];
  assign toSRAM_7_ack        = ch_reqpulse[7];
  assign toSRAM_7_selectedOH = ch_selectedOH[7];
  assign toSRAM_7_array      = ch_array[7][2:0];
  assign ch_rdata[7]    = DATA_W'(toSRAM_7_rdata);
  assign ch_ack[7]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 8：array id 0x08 ----
  assign toSRAM_8_addr       = ch_addr[8];
  assign toSRAM_8_addr_rd    = ch_addr_rd[8];
  assign toSRAM_8_wdata      = ch_wdata[8];
  assign toSRAM_8_wmask      = ch_wmask[8];
  assign toSRAM_8_re         = ch_readen[8];
  assign toSRAM_8_we         = ch_writeen[8];
  assign toSRAM_8_ack        = ch_reqpulse[8];
  assign toSRAM_8_selectedOH = ch_selectedOH[8];
  assign toSRAM_8_array      = ch_array[8][3:0];
  assign ch_rdata[8]    = DATA_W'(toSRAM_8_rdata);
  assign ch_ack[8]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 9：array id 0x09 ----
  assign toSRAM_9_addr       = ch_addr[9];
  assign toSRAM_9_addr_rd    = ch_addr_rd[9];
  assign toSRAM_9_wdata      = ch_wdata[9];
  assign toSRAM_9_wmask      = ch_wmask[9];
  assign toSRAM_9_re         = ch_readen[9];
  assign toSRAM_9_we         = ch_writeen[9];
  assign toSRAM_9_ack        = ch_reqpulse[9];
  assign toSRAM_9_selectedOH = ch_selectedOH[9];
  assign toSRAM_9_array      = ch_array[9][3:0];
  assign ch_rdata[9]    = DATA_W'(toSRAM_9_rdata);
  assign ch_ack[9]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 10：array id 0x0A ----
  assign toSRAM_10_addr       = ch_addr[10];
  assign toSRAM_10_addr_rd    = ch_addr_rd[10];
  assign toSRAM_10_wdata      = ch_wdata[10];
  assign toSRAM_10_wmask      = ch_wmask[10];
  assign toSRAM_10_re         = ch_readen[10];
  assign toSRAM_10_we         = ch_writeen[10];
  assign toSRAM_10_ack        = ch_reqpulse[10];
  assign toSRAM_10_selectedOH = ch_selectedOH[10];
  assign toSRAM_10_array      = ch_array[10][3:0];
  assign ch_rdata[10]    = DATA_W'(toSRAM_10_rdata);
  assign ch_ack[10]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 11：array id 0x0B ----
  assign toSRAM_11_addr       = ch_addr[11];
  assign toSRAM_11_addr_rd    = ch_addr_rd[11];
  assign toSRAM_11_wdata      = ch_wdata[11];
  assign toSRAM_11_wmask      = ch_wmask[11];
  assign toSRAM_11_re         = ch_readen[11];
  assign toSRAM_11_we         = ch_writeen[11];
  assign toSRAM_11_ack        = ch_reqpulse[11];
  assign toSRAM_11_selectedOH = ch_selectedOH[11];
  assign toSRAM_11_array      = ch_array[11][3:0];
  assign ch_rdata[11]    = DATA_W'(toSRAM_11_rdata);
  assign ch_ack[11]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 12：array id 0x0C ----
  assign toSRAM_12_addr       = ch_addr[12];
  assign toSRAM_12_addr_rd    = ch_addr_rd[12];
  assign toSRAM_12_wdata      = ch_wdata[12];
  assign toSRAM_12_wmask      = ch_wmask[12];
  assign toSRAM_12_re         = ch_readen[12];
  assign toSRAM_12_we         = ch_writeen[12];
  assign toSRAM_12_ack        = ch_reqpulse[12];
  assign toSRAM_12_selectedOH = ch_selectedOH[12];
  assign toSRAM_12_array      = ch_array[12][3:0];
  assign ch_rdata[12]    = DATA_W'(toSRAM_12_rdata);
  assign ch_ack[12]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 13：array id 0x0D ----
  assign toSRAM_13_addr       = ch_addr[13];
  assign toSRAM_13_addr_rd    = ch_addr_rd[13];
  assign toSRAM_13_wdata      = ch_wdata[13];
  assign toSRAM_13_wmask      = ch_wmask[13];
  assign toSRAM_13_re         = ch_readen[13];
  assign toSRAM_13_we         = ch_writeen[13];
  assign toSRAM_13_ack        = ch_reqpulse[13];
  assign toSRAM_13_selectedOH = ch_selectedOH[13];
  assign toSRAM_13_array      = ch_array[13][3:0];
  assign ch_rdata[13]    = DATA_W'(toSRAM_13_rdata);
  assign ch_ack[13]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 14：array id 0x0E ----
  assign toSRAM_14_addr       = ch_addr[14];
  assign toSRAM_14_addr_rd    = ch_addr_rd[14];
  assign toSRAM_14_wdata      = ch_wdata[14];
  assign toSRAM_14_wmask      = ch_wmask[14];
  assign toSRAM_14_re         = ch_readen[14];
  assign toSRAM_14_we         = ch_writeen[14];
  assign toSRAM_14_ack        = ch_reqpulse[14];
  assign toSRAM_14_selectedOH = ch_selectedOH[14];
  assign toSRAM_14_array      = ch_array[14][3:0];
  assign ch_rdata[14]    = DATA_W'(toSRAM_14_rdata);
  assign ch_ack[14]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 15：array id 0x0F ----
  assign toSRAM_15_addr       = ch_addr[15];
  assign toSRAM_15_addr_rd    = ch_addr_rd[15];
  assign toSRAM_15_wdata      = ch_wdata[15];
  assign toSRAM_15_wmask      = ch_wmask[15];
  assign toSRAM_15_re         = ch_readen[15];
  assign toSRAM_15_we         = ch_writeen[15];
  assign toSRAM_15_ack        = ch_reqpulse[15];
  assign toSRAM_15_selectedOH = ch_selectedOH[15];
  assign toSRAM_15_array      = ch_array[15][3:0];
  assign ch_rdata[15]    = DATA_W'(toSRAM_15_rdata);
  assign ch_ack[15]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 16：array id 0x10 ----
  assign toSRAM_16_addr       = ch_addr[16];
  assign toSRAM_16_addr_rd    = ch_addr_rd[16];
  assign toSRAM_16_wdata      = ch_wdata[16];
  assign toSRAM_16_wmask      = ch_wmask[16];
  assign toSRAM_16_re         = ch_readen[16];
  assign toSRAM_16_we         = ch_writeen[16];
  assign toSRAM_16_ack        = ch_reqpulse[16];
  assign toSRAM_16_selectedOH = ch_selectedOH[16];
  assign toSRAM_16_array      = ch_array[16];
  assign ch_rdata[16]    = DATA_W'(toSRAM_16_rdata);
  assign ch_ack[16]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 17：array id 0x11 ----
  assign toSRAM_17_addr       = ch_addr[17];
  assign toSRAM_17_addr_rd    = ch_addr_rd[17];
  assign toSRAM_17_wdata      = ch_wdata[17];
  assign toSRAM_17_wmask      = ch_wmask[17];
  assign toSRAM_17_re         = ch_readen[17];
  assign toSRAM_17_we         = ch_writeen[17];
  assign toSRAM_17_ack        = ch_reqpulse[17];
  assign toSRAM_17_selectedOH = ch_selectedOH[17];
  assign toSRAM_17_array      = ch_array[17];
  assign ch_rdata[17]    = DATA_W'(toSRAM_17_rdata);
  assign ch_ack[17]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 18：array id 0x12 ----
  assign toSRAM_18_addr       = ch_addr[18];
  assign toSRAM_18_addr_rd    = ch_addr_rd[18];
  assign toSRAM_18_wdata      = ch_wdata[18];
  assign toSRAM_18_wmask      = ch_wmask[18];
  assign toSRAM_18_re         = ch_readen[18];
  assign toSRAM_18_we         = ch_writeen[18];
  assign toSRAM_18_ack        = ch_reqpulse[18];
  assign toSRAM_18_selectedOH = ch_selectedOH[18];
  assign toSRAM_18_array      = ch_array[18];
  assign ch_rdata[18]    = DATA_W'(toSRAM_18_rdata);
  assign ch_ack[18]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 19：array id 0x13 ----
  assign toSRAM_19_addr       = ch_addr[19];
  assign toSRAM_19_addr_rd    = ch_addr_rd[19];
  assign toSRAM_19_wdata      = ch_wdata[19];
  assign toSRAM_19_wmask      = ch_wmask[19];
  assign toSRAM_19_re         = ch_readen[19];
  assign toSRAM_19_we         = ch_writeen[19];
  assign toSRAM_19_ack        = ch_reqpulse[19];
  assign toSRAM_19_selectedOH = ch_selectedOH[19];
  assign toSRAM_19_array      = ch_array[19];
  assign ch_rdata[19]    = DATA_W'(toSRAM_19_rdata);
  assign ch_ack[19]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 20：array id 0x14 ----
  assign toSRAM_20_addr       = ch_addr[20];
  assign toSRAM_20_addr_rd    = ch_addr_rd[20];
  assign toSRAM_20_wdata      = ch_wdata[20];
  assign toSRAM_20_wmask      = ch_wmask[20];
  assign toSRAM_20_re         = ch_readen[20];
  assign toSRAM_20_we         = ch_writeen[20];
  assign toSRAM_20_ack        = ch_reqpulse[20];
  assign toSRAM_20_selectedOH = ch_selectedOH[20];
  assign toSRAM_20_array      = ch_array[20];
  assign ch_rdata[20]    = DATA_W'(toSRAM_20_rdata);
  assign ch_ack[20]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 21：array id 0x15 ----
  assign toSRAM_21_addr       = ch_addr[21];
  assign toSRAM_21_addr_rd    = ch_addr_rd[21];
  assign toSRAM_21_wdata      = ch_wdata[21];
  assign toSRAM_21_wmask      = ch_wmask[21];
  assign toSRAM_21_re         = ch_readen[21];
  assign toSRAM_21_we         = ch_writeen[21];
  assign toSRAM_21_ack        = ch_reqpulse[21];
  assign toSRAM_21_selectedOH = ch_selectedOH[21];
  assign toSRAM_21_array      = ch_array[21];
  assign ch_rdata[21]    = DATA_W'(toSRAM_21_rdata);
  assign ch_ack[21]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 22：array id 0x16 ----
  assign toSRAM_22_addr       = ch_addr[22];
  assign toSRAM_22_addr_rd    = ch_addr_rd[22];
  assign toSRAM_22_wdata      = ch_wdata[22];
  assign toSRAM_22_wmask      = ch_wmask[22];
  assign toSRAM_22_re         = ch_readen[22];
  assign toSRAM_22_we         = ch_writeen[22];
  assign toSRAM_22_ack        = ch_reqpulse[22];
  assign toSRAM_22_selectedOH = ch_selectedOH[22];
  assign toSRAM_22_array      = ch_array[22];
  assign ch_rdata[22]    = DATA_W'(toSRAM_22_rdata);
  assign ch_ack[22]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 23：array id 0x17 ----
  assign toSRAM_23_addr       = ch_addr[23];
  assign toSRAM_23_addr_rd    = ch_addr_rd[23];
  assign toSRAM_23_wdata      = ch_wdata[23];
  assign toSRAM_23_wmask      = ch_wmask[23];
  assign toSRAM_23_re         = ch_readen[23];
  assign toSRAM_23_we         = ch_writeen[23];
  assign toSRAM_23_ack        = ch_reqpulse[23];
  assign toSRAM_23_selectedOH = ch_selectedOH[23];
  assign toSRAM_23_array      = ch_array[23];
  assign ch_rdata[23]    = DATA_W'(toSRAM_23_rdata);
  assign ch_ack[23]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 24：array id 0x18 ----
  assign toSRAM_24_addr       = ch_addr[24];
  assign toSRAM_24_addr_rd    = ch_addr_rd[24];
  assign toSRAM_24_wdata      = ch_wdata[24];
  assign toSRAM_24_wmask      = ch_wmask[24];
  assign toSRAM_24_re         = ch_readen[24];
  assign toSRAM_24_we         = ch_writeen[24];
  assign toSRAM_24_ack        = ch_reqpulse[24];
  assign toSRAM_24_selectedOH = ch_selectedOH[24];
  assign toSRAM_24_array      = ch_array[24];
  assign ch_rdata[24]    = DATA_W'(toSRAM_24_rdata);
  assign ch_ack[24]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 25：array id 0x19 ----
  assign toSRAM_25_addr       = ch_addr[25];
  assign toSRAM_25_addr_rd    = ch_addr_rd[25];
  assign toSRAM_25_wdata      = ch_wdata[25];
  assign toSRAM_25_wmask      = ch_wmask[25];
  assign toSRAM_25_re         = ch_readen[25];
  assign toSRAM_25_we         = ch_writeen[25];
  assign toSRAM_25_ack        = ch_reqpulse[25];
  assign toSRAM_25_selectedOH = ch_selectedOH[25];
  assign toSRAM_25_array      = ch_array[25];
  assign ch_rdata[25]    = DATA_W'(toSRAM_25_rdata);
  assign ch_ack[25]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 26：array id 0x1A ----
  assign toSRAM_26_addr       = ch_addr[26];
  assign toSRAM_26_addr_rd    = ch_addr_rd[26];
  assign toSRAM_26_wdata      = ch_wdata[26];
  assign toSRAM_26_wmask      = ch_wmask[26];
  assign toSRAM_26_re         = ch_readen[26];
  assign toSRAM_26_we         = ch_writeen[26];
  assign toSRAM_26_ack        = ch_reqpulse[26];
  assign toSRAM_26_selectedOH = ch_selectedOH[26];
  assign toSRAM_26_array      = ch_array[26];
  assign ch_rdata[26]    = DATA_W'(toSRAM_26_rdata);
  assign ch_ack[26]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 27：array id 0x1B ----
  assign toSRAM_27_addr       = ch_addr[27];
  assign toSRAM_27_addr_rd    = ch_addr_rd[27];
  assign toSRAM_27_wdata      = ch_wdata[27];
  assign toSRAM_27_wmask      = ch_wmask[27];
  assign toSRAM_27_re         = ch_readen[27];
  assign toSRAM_27_we         = ch_writeen[27];
  assign toSRAM_27_ack        = ch_reqpulse[27];
  assign toSRAM_27_selectedOH = ch_selectedOH[27];
  assign toSRAM_27_array      = ch_array[27];
  assign ch_rdata[27]    = DATA_W'(toSRAM_27_rdata);
  assign ch_ack[27]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 28：array id 0x1C ----
  assign toSRAM_28_addr       = ch_addr[28];
  assign toSRAM_28_addr_rd    = ch_addr_rd[28];
  assign toSRAM_28_wdata      = ch_wdata[28];
  assign toSRAM_28_wmask      = ch_wmask[28];
  assign toSRAM_28_re         = ch_readen[28];
  assign toSRAM_28_we         = ch_writeen[28];
  assign toSRAM_28_ack        = ch_reqpulse[28];
  assign toSRAM_28_selectedOH = ch_selectedOH[28];
  assign toSRAM_28_array      = ch_array[28];
  assign ch_rdata[28]    = DATA_W'(toSRAM_28_rdata);
  assign ch_ack[28]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 29：array id 0x1D ----
  assign toSRAM_29_addr       = ch_addr[29];
  assign toSRAM_29_addr_rd    = ch_addr_rd[29];
  assign toSRAM_29_wdata      = ch_wdata[29];
  assign toSRAM_29_wmask      = ch_wmask[29];
  assign toSRAM_29_re         = ch_readen[29];
  assign toSRAM_29_we         = ch_writeen[29];
  assign toSRAM_29_ack        = ch_reqpulse[29];
  assign toSRAM_29_selectedOH = ch_selectedOH[29];
  assign toSRAM_29_array      = ch_array[29];
  assign ch_rdata[29]    = DATA_W'(toSRAM_29_rdata);
  assign ch_ack[29]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 30：array id 0x1E ----
  assign toSRAM_30_addr       = ch_addr[30];
  assign toSRAM_30_addr_rd    = ch_addr_rd[30];
  assign toSRAM_30_wdata      = ch_wdata[30];
  assign toSRAM_30_wmask      = ch_wmask[30];
  assign toSRAM_30_re         = ch_readen[30];
  assign toSRAM_30_we         = ch_writeen[30];
  assign toSRAM_30_ack        = ch_reqpulse[30];
  assign toSRAM_30_selectedOH = ch_selectedOH[30];
  assign toSRAM_30_array      = ch_array[30];
  assign ch_rdata[30]    = DATA_W'(toSRAM_30_rdata);
  assign ch_ack[30]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 31：array id 0x1F ----
  assign toSRAM_31_addr       = ch_addr[31];
  assign toSRAM_31_addr_rd    = ch_addr_rd[31];
  assign toSRAM_31_wdata      = ch_wdata[31];
  assign toSRAM_31_wmask      = ch_wmask[31];
  assign toSRAM_31_re         = ch_readen[31];
  assign toSRAM_31_we         = ch_writeen[31];
  assign toSRAM_31_ack        = ch_reqpulse[31];
  assign toSRAM_31_selectedOH = ch_selectedOH[31];
  assign toSRAM_31_array      = ch_array[31];
  assign ch_rdata[31]    = DATA_W'(toSRAM_31_rdata);
  assign ch_ack[31]      = 1'b0;   // 叶子不看 SRAM 的 ack

endmodule
// END GENERATED(MbistPipeDCacheData)
