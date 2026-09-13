// MbistPipeFrontend.sv —— MBIST 分发树的 中间(node) 节点：前端整棵 MBIST 子树（ICache + 分支预测器 Predictor）
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      中间节点：往下接 MbistPipe，16 个 child（toNextPipeline_0..15）
//   例化于    Frontend
//   MBIST array id  0x00..0x53（共 84 个），故 ARRAY_W = clog2(0x53+1) = 7 位
//   上游总线  addr/addr_rd 10 位  indata/outdata 76 位  be 76 位
//   规模      golden 616 行 / 189 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体因此出现 2/4/5/6/7 位并存的参差宽度——这正是本家族最容易写错的地方：
//   child 0   id 0x00..0x03    array 2 位  addr 8   data 74   be 2 
//   child 1   id 0x04..0x0B    array 4 位  addr 9   data 66   be 1 
//   child 2   id 0x0C..0x13    array 5 位  addr 9   data 66   be 1 
//   child 3   id 0x14..0x1B    array 5 位  addr 9   data 66   be 1 
//   child 4   id 0x1C..0x23    array 6 位  addr 9   data 66   be 1 
//   child 5   id 0x24..0x2B    array 6 位  addr 10  data 40   be 4 
//   child 6   id 0x2C..0x43    array 7 位  addr 10  data 24   be 16
//   child 7   id 0x44..0x45    array 7 位  addr 8   data 24   be 4 
//   child 8   id 0x46..0x47    array 7 位  addr 8   data 24   be 4 
//   child 9   id 0x48..0x49    array 7 位  addr 8   data 24   be 4 
//   child 10  id 0x4A..0x4B    array 7 位  addr 8   data 24   be 4 
//   child 11  id 0x4C          array 7 位  addr 8   data 76   be 76
//   child 12  id 0x4D          array 7 位  addr 8   data 76   be 76
//   child 13  id 0x4E..0x4F    array 7 位  addr 8   data 76   be 76
//   child 14  id 0x50..0x51    array 7 位  addr 8   data 76   be 76
//   child 15  id 0x52..0x53    array 7 位  addr 8   data 76   be 76
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(MbistPipeFrontend) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module MbistPipeFrontend (
  input  logic clock,
  input  logic reset,
  input  logic [6:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic [75:0] mbist_be,
  input  logic [9:0] mbist_addr,
  input  logic [75:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [9:0] mbist_addr_rd,
  output logic [75:0] mbist_outdata,
  output logic [1:0] toNextPipeline_0_array,
  output logic toNextPipeline_0_all,
  output logic toNextPipeline_0_req,
  input  logic toNextPipeline_0_ack,
  output logic toNextPipeline_0_writeen,
  output logic [1:0] toNextPipeline_0_be,
  output logic [7:0] toNextPipeline_0_addr,
  output logic [73:0] toNextPipeline_0_indata,
  output logic toNextPipeline_0_readen,
  output logic [7:0] toNextPipeline_0_addr_rd,
  input  logic [73:0] toNextPipeline_0_outdata,
  output logic [3:0] toNextPipeline_1_array,
  output logic toNextPipeline_1_all,
  output logic toNextPipeline_1_req,
  input  logic toNextPipeline_1_ack,
  output logic toNextPipeline_1_writeen,
  output logic toNextPipeline_1_be,
  output logic [8:0] toNextPipeline_1_addr,
  output logic [65:0] toNextPipeline_1_indata,
  output logic toNextPipeline_1_readen,
  output logic [8:0] toNextPipeline_1_addr_rd,
  input  logic [65:0] toNextPipeline_1_outdata,
  output logic [4:0] toNextPipeline_2_array,
  output logic toNextPipeline_2_all,
  output logic toNextPipeline_2_req,
  input  logic toNextPipeline_2_ack,
  output logic toNextPipeline_2_writeen,
  output logic toNextPipeline_2_be,
  output logic [8:0] toNextPipeline_2_addr,
  output logic [65:0] toNextPipeline_2_indata,
  output logic toNextPipeline_2_readen,
  output logic [8:0] toNextPipeline_2_addr_rd,
  input  logic [65:0] toNextPipeline_2_outdata,
  output logic [4:0] toNextPipeline_3_array,
  output logic toNextPipeline_3_all,
  output logic toNextPipeline_3_req,
  input  logic toNextPipeline_3_ack,
  output logic toNextPipeline_3_writeen,
  output logic toNextPipeline_3_be,
  output logic [8:0] toNextPipeline_3_addr,
  output logic [65:0] toNextPipeline_3_indata,
  output logic toNextPipeline_3_readen,
  output logic [8:0] toNextPipeline_3_addr_rd,
  input  logic [65:0] toNextPipeline_3_outdata,
  output logic [5:0] toNextPipeline_4_array,
  output logic toNextPipeline_4_all,
  output logic toNextPipeline_4_req,
  input  logic toNextPipeline_4_ack,
  output logic toNextPipeline_4_writeen,
  output logic toNextPipeline_4_be,
  output logic [8:0] toNextPipeline_4_addr,
  output logic [65:0] toNextPipeline_4_indata,
  output logic toNextPipeline_4_readen,
  output logic [8:0] toNextPipeline_4_addr_rd,
  input  logic [65:0] toNextPipeline_4_outdata,
  output logic [5:0] toNextPipeline_5_array,
  output logic toNextPipeline_5_all,
  output logic toNextPipeline_5_req,
  input  logic toNextPipeline_5_ack,
  output logic toNextPipeline_5_writeen,
  output logic [3:0] toNextPipeline_5_be,
  output logic [9:0] toNextPipeline_5_addr,
  output logic [39:0] toNextPipeline_5_indata,
  output logic toNextPipeline_5_readen,
  output logic [9:0] toNextPipeline_5_addr_rd,
  input  logic [39:0] toNextPipeline_5_outdata,
  output logic [6:0] toNextPipeline_6_array,
  output logic toNextPipeline_6_all,
  output logic toNextPipeline_6_req,
  input  logic toNextPipeline_6_ack,
  output logic toNextPipeline_6_writeen,
  output logic [15:0] toNextPipeline_6_be,
  output logic [9:0] toNextPipeline_6_addr,
  output logic [23:0] toNextPipeline_6_indata,
  output logic toNextPipeline_6_readen,
  output logic [9:0] toNextPipeline_6_addr_rd,
  input  logic [23:0] toNextPipeline_6_outdata,
  output logic [6:0] toNextPipeline_7_array,
  output logic toNextPipeline_7_all,
  output logic toNextPipeline_7_req,
  input  logic toNextPipeline_7_ack,
  output logic toNextPipeline_7_writeen,
  output logic [3:0] toNextPipeline_7_be,
  output logic [7:0] toNextPipeline_7_addr,
  output logic [23:0] toNextPipeline_7_indata,
  output logic toNextPipeline_7_readen,
  output logic [7:0] toNextPipeline_7_addr_rd,
  input  logic [23:0] toNextPipeline_7_outdata,
  output logic [6:0] toNextPipeline_8_array,
  output logic toNextPipeline_8_all,
  output logic toNextPipeline_8_req,
  input  logic toNextPipeline_8_ack,
  output logic toNextPipeline_8_writeen,
  output logic [3:0] toNextPipeline_8_be,
  output logic [7:0] toNextPipeline_8_addr,
  output logic [23:0] toNextPipeline_8_indata,
  output logic toNextPipeline_8_readen,
  output logic [7:0] toNextPipeline_8_addr_rd,
  input  logic [23:0] toNextPipeline_8_outdata,
  output logic [6:0] toNextPipeline_9_array,
  output logic toNextPipeline_9_all,
  output logic toNextPipeline_9_req,
  input  logic toNextPipeline_9_ack,
  output logic toNextPipeline_9_writeen,
  output logic [3:0] toNextPipeline_9_be,
  output logic [7:0] toNextPipeline_9_addr,
  output logic [23:0] toNextPipeline_9_indata,
  output logic toNextPipeline_9_readen,
  output logic [7:0] toNextPipeline_9_addr_rd,
  input  logic [23:0] toNextPipeline_9_outdata,
  output logic [6:0] toNextPipeline_10_array,
  output logic toNextPipeline_10_all,
  output logic toNextPipeline_10_req,
  input  logic toNextPipeline_10_ack,
  output logic toNextPipeline_10_writeen,
  output logic [3:0] toNextPipeline_10_be,
  output logic [7:0] toNextPipeline_10_addr,
  output logic [23:0] toNextPipeline_10_indata,
  output logic toNextPipeline_10_readen,
  output logic [7:0] toNextPipeline_10_addr_rd,
  input  logic [23:0] toNextPipeline_10_outdata,
  output logic [6:0] toNextPipeline_11_array,
  output logic toNextPipeline_11_all,
  output logic toNextPipeline_11_req,
  input  logic toNextPipeline_11_ack,
  output logic toNextPipeline_11_writeen,
  output logic [75:0] toNextPipeline_11_be,
  output logic [7:0] toNextPipeline_11_addr,
  output logic [75:0] toNextPipeline_11_indata,
  output logic toNextPipeline_11_readen,
  output logic [7:0] toNextPipeline_11_addr_rd,
  input  logic [75:0] toNextPipeline_11_outdata,
  output logic [6:0] toNextPipeline_12_array,
  output logic toNextPipeline_12_all,
  output logic toNextPipeline_12_req,
  input  logic toNextPipeline_12_ack,
  output logic toNextPipeline_12_writeen,
  output logic [75:0] toNextPipeline_12_be,
  output logic [7:0] toNextPipeline_12_addr,
  output logic [75:0] toNextPipeline_12_indata,
  output logic toNextPipeline_12_readen,
  output logic [7:0] toNextPipeline_12_addr_rd,
  input  logic [75:0] toNextPipeline_12_outdata,
  output logic [6:0] toNextPipeline_13_array,
  output logic toNextPipeline_13_all,
  output logic toNextPipeline_13_req,
  input  logic toNextPipeline_13_ack,
  output logic toNextPipeline_13_writeen,
  output logic [75:0] toNextPipeline_13_be,
  output logic [7:0] toNextPipeline_13_addr,
  output logic [75:0] toNextPipeline_13_indata,
  output logic toNextPipeline_13_readen,
  output logic [7:0] toNextPipeline_13_addr_rd,
  input  logic [75:0] toNextPipeline_13_outdata,
  output logic [6:0] toNextPipeline_14_array,
  output logic toNextPipeline_14_all,
  output logic toNextPipeline_14_req,
  input  logic toNextPipeline_14_ack,
  output logic toNextPipeline_14_writeen,
  output logic [75:0] toNextPipeline_14_be,
  output logic [7:0] toNextPipeline_14_addr,
  output logic [75:0] toNextPipeline_14_indata,
  output logic toNextPipeline_14_readen,
  output logic [7:0] toNextPipeline_14_addr_rd,
  input  logic [75:0] toNextPipeline_14_outdata,
  output logic [6:0] toNextPipeline_15_array,
  output logic toNextPipeline_15_all,
  output logic toNextPipeline_15_req,
  input  logic toNextPipeline_15_ack,
  output logic toNextPipeline_15_writeen,
  output logic [75:0] toNextPipeline_15_be,
  output logic [7:0] toNextPipeline_15_addr,
  output logic [75:0] toNextPipeline_15_indata,
  output logic toNextPipeline_15_readen,
  output logic [7:0] toNextPipeline_15_addr_rd,
  input  logic [75:0] toNextPipeline_15_outdata
);

  localparam int unsigned N_CHILD = 16;
  localparam int unsigned MAX_IDS = 24;
  localparam int unsigned ARRAY_W = 7;
  localparam int unsigned ADDR_W  = 10;
  localparam int unsigned DATA_W  = 76;
  localparam int unsigned BE_W    = 76;

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
    .IS_NODE (1'b1),
    .N_CHILD (N_CHILD),
    .ARRAY_W (ARRAY_W),
    .BE_W    (BE_W),
    .ADDR_W  (ADDR_W),
    .DATA_W  (DATA_W),
    .ID_LO   ('{'h00, 'h04, 'h0C, 'h14, 'h1C, 'h24, 'h2C, 'h44, 'h46, 'h48, 'h4A, 'h4C, 'h4D, 'h4E, 'h50, 'h52}),
    .ID_CNT  ('{4, 8, 8, 8, 8, 8, 24, 2, 2, 2, 2, 1, 1, 2, 2, 2}),
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
  // ---- child 0：array id 0x00..0x03 ----
  assign toNextPipeline_0_array   = ch_array[0][1:0];
  assign toNextPipeline_0_all     = ch_all[0];
  assign toNextPipeline_0_req     = ch_reqpulse[0];
  assign toNextPipeline_0_writeen = ch_writeen[0];
  assign toNextPipeline_0_be      = ch_wmask[0][1:0];
  assign toNextPipeline_0_addr    = ch_addr[0][7:0];
  assign toNextPipeline_0_indata  = ch_wdata[0][73:0];
  assign toNextPipeline_0_readen  = ch_readen[0];
  assign toNextPipeline_0_addr_rd = ch_addr_rd[0][7:0];
  assign ch_rdata[0] = DATA_W'(toNextPipeline_0_outdata);
  assign ch_ack[0]   = toNextPipeline_0_ack;
  // ---- child 1：array id 0x04..0x0B ----
  assign toNextPipeline_1_array   = ch_array[1][3:0];
  assign toNextPipeline_1_all     = ch_all[1];
  assign toNextPipeline_1_req     = ch_reqpulse[1];
  assign toNextPipeline_1_writeen = ch_writeen[1];
  assign toNextPipeline_1_be      = ch_wmask[1][0:0];
  assign toNextPipeline_1_addr    = ch_addr[1][8:0];
  assign toNextPipeline_1_indata  = ch_wdata[1][65:0];
  assign toNextPipeline_1_readen  = ch_readen[1];
  assign toNextPipeline_1_addr_rd = ch_addr_rd[1][8:0];
  assign ch_rdata[1] = DATA_W'(toNextPipeline_1_outdata);
  assign ch_ack[1]   = toNextPipeline_1_ack;
  // ---- child 2：array id 0x0C..0x13 ----
  assign toNextPipeline_2_array   = ch_array[2][4:0];
  assign toNextPipeline_2_all     = ch_all[2];
  assign toNextPipeline_2_req     = ch_reqpulse[2];
  assign toNextPipeline_2_writeen = ch_writeen[2];
  assign toNextPipeline_2_be      = ch_wmask[2][0:0];
  assign toNextPipeline_2_addr    = ch_addr[2][8:0];
  assign toNextPipeline_2_indata  = ch_wdata[2][65:0];
  assign toNextPipeline_2_readen  = ch_readen[2];
  assign toNextPipeline_2_addr_rd = ch_addr_rd[2][8:0];
  assign ch_rdata[2] = DATA_W'(toNextPipeline_2_outdata);
  assign ch_ack[2]   = toNextPipeline_2_ack;
  // ---- child 3：array id 0x14..0x1B ----
  assign toNextPipeline_3_array   = ch_array[3][4:0];
  assign toNextPipeline_3_all     = ch_all[3];
  assign toNextPipeline_3_req     = ch_reqpulse[3];
  assign toNextPipeline_3_writeen = ch_writeen[3];
  assign toNextPipeline_3_be      = ch_wmask[3][0:0];
  assign toNextPipeline_3_addr    = ch_addr[3][8:0];
  assign toNextPipeline_3_indata  = ch_wdata[3][65:0];
  assign toNextPipeline_3_readen  = ch_readen[3];
  assign toNextPipeline_3_addr_rd = ch_addr_rd[3][8:0];
  assign ch_rdata[3] = DATA_W'(toNextPipeline_3_outdata);
  assign ch_ack[3]   = toNextPipeline_3_ack;
  // ---- child 4：array id 0x1C..0x23 ----
  assign toNextPipeline_4_array   = ch_array[4][5:0];
  assign toNextPipeline_4_all     = ch_all[4];
  assign toNextPipeline_4_req     = ch_reqpulse[4];
  assign toNextPipeline_4_writeen = ch_writeen[4];
  assign toNextPipeline_4_be      = ch_wmask[4][0:0];
  assign toNextPipeline_4_addr    = ch_addr[4][8:0];
  assign toNextPipeline_4_indata  = ch_wdata[4][65:0];
  assign toNextPipeline_4_readen  = ch_readen[4];
  assign toNextPipeline_4_addr_rd = ch_addr_rd[4][8:0];
  assign ch_rdata[4] = DATA_W'(toNextPipeline_4_outdata);
  assign ch_ack[4]   = toNextPipeline_4_ack;
  // ---- child 5：array id 0x24..0x2B ----
  assign toNextPipeline_5_array   = ch_array[5][5:0];
  assign toNextPipeline_5_all     = ch_all[5];
  assign toNextPipeline_5_req     = ch_reqpulse[5];
  assign toNextPipeline_5_writeen = ch_writeen[5];
  assign toNextPipeline_5_be      = ch_wmask[5][3:0];
  assign toNextPipeline_5_addr    = ch_addr[5];
  assign toNextPipeline_5_indata  = ch_wdata[5][39:0];
  assign toNextPipeline_5_readen  = ch_readen[5];
  assign toNextPipeline_5_addr_rd = ch_addr_rd[5];
  assign ch_rdata[5] = DATA_W'(toNextPipeline_5_outdata);
  assign ch_ack[5]   = toNextPipeline_5_ack;
  // ---- child 6：array id 0x2C..0x43 ----
  assign toNextPipeline_6_array   = ch_array[6];
  assign toNextPipeline_6_all     = ch_all[6];
  assign toNextPipeline_6_req     = ch_reqpulse[6];
  assign toNextPipeline_6_writeen = ch_writeen[6];
  assign toNextPipeline_6_be      = ch_wmask[6][15:0];
  assign toNextPipeline_6_addr    = ch_addr[6];
  assign toNextPipeline_6_indata  = ch_wdata[6][23:0];
  assign toNextPipeline_6_readen  = ch_readen[6];
  assign toNextPipeline_6_addr_rd = ch_addr_rd[6];
  assign ch_rdata[6] = DATA_W'(toNextPipeline_6_outdata);
  assign ch_ack[6]   = toNextPipeline_6_ack;
  // ---- child 7：array id 0x44..0x45 ----
  assign toNextPipeline_7_array   = ch_array[7];
  assign toNextPipeline_7_all     = ch_all[7];
  assign toNextPipeline_7_req     = ch_reqpulse[7];
  assign toNextPipeline_7_writeen = ch_writeen[7];
  assign toNextPipeline_7_be      = ch_wmask[7][3:0];
  assign toNextPipeline_7_addr    = ch_addr[7][7:0];
  assign toNextPipeline_7_indata  = ch_wdata[7][23:0];
  assign toNextPipeline_7_readen  = ch_readen[7];
  assign toNextPipeline_7_addr_rd = ch_addr_rd[7][7:0];
  assign ch_rdata[7] = DATA_W'(toNextPipeline_7_outdata);
  assign ch_ack[7]   = toNextPipeline_7_ack;
  // ---- child 8：array id 0x46..0x47 ----
  assign toNextPipeline_8_array   = ch_array[8];
  assign toNextPipeline_8_all     = ch_all[8];
  assign toNextPipeline_8_req     = ch_reqpulse[8];
  assign toNextPipeline_8_writeen = ch_writeen[8];
  assign toNextPipeline_8_be      = ch_wmask[8][3:0];
  assign toNextPipeline_8_addr    = ch_addr[8][7:0];
  assign toNextPipeline_8_indata  = ch_wdata[8][23:0];
  assign toNextPipeline_8_readen  = ch_readen[8];
  assign toNextPipeline_8_addr_rd = ch_addr_rd[8][7:0];
  assign ch_rdata[8] = DATA_W'(toNextPipeline_8_outdata);
  assign ch_ack[8]   = toNextPipeline_8_ack;
  // ---- child 9：array id 0x48..0x49 ----
  assign toNextPipeline_9_array   = ch_array[9];
  assign toNextPipeline_9_all     = ch_all[9];
  assign toNextPipeline_9_req     = ch_reqpulse[9];
  assign toNextPipeline_9_writeen = ch_writeen[9];
  assign toNextPipeline_9_be      = ch_wmask[9][3:0];
  assign toNextPipeline_9_addr    = ch_addr[9][7:0];
  assign toNextPipeline_9_indata  = ch_wdata[9][23:0];
  assign toNextPipeline_9_readen  = ch_readen[9];
  assign toNextPipeline_9_addr_rd = ch_addr_rd[9][7:0];
  assign ch_rdata[9] = DATA_W'(toNextPipeline_9_outdata);
  assign ch_ack[9]   = toNextPipeline_9_ack;
  // ---- child 10：array id 0x4A..0x4B ----
  assign toNextPipeline_10_array   = ch_array[10];
  assign toNextPipeline_10_all     = ch_all[10];
  assign toNextPipeline_10_req     = ch_reqpulse[10];
  assign toNextPipeline_10_writeen = ch_writeen[10];
  assign toNextPipeline_10_be      = ch_wmask[10][3:0];
  assign toNextPipeline_10_addr    = ch_addr[10][7:0];
  assign toNextPipeline_10_indata  = ch_wdata[10][23:0];
  assign toNextPipeline_10_readen  = ch_readen[10];
  assign toNextPipeline_10_addr_rd = ch_addr_rd[10][7:0];
  assign ch_rdata[10] = DATA_W'(toNextPipeline_10_outdata);
  assign ch_ack[10]   = toNextPipeline_10_ack;
  // ---- child 11：array id 0x4C ----
  assign toNextPipeline_11_array   = ch_array[11];
  assign toNextPipeline_11_all     = ch_all[11];
  assign toNextPipeline_11_req     = ch_reqpulse[11];
  assign toNextPipeline_11_writeen = ch_writeen[11];
  assign toNextPipeline_11_be      = ch_wmask[11];
  assign toNextPipeline_11_addr    = ch_addr[11][7:0];
  assign toNextPipeline_11_indata  = ch_wdata[11];
  assign toNextPipeline_11_readen  = ch_readen[11];
  assign toNextPipeline_11_addr_rd = ch_addr_rd[11][7:0];
  assign ch_rdata[11] = DATA_W'(toNextPipeline_11_outdata);
  assign ch_ack[11]   = toNextPipeline_11_ack;
  // ---- child 12：array id 0x4D ----
  assign toNextPipeline_12_array   = ch_array[12];
  assign toNextPipeline_12_all     = ch_all[12];
  assign toNextPipeline_12_req     = ch_reqpulse[12];
  assign toNextPipeline_12_writeen = ch_writeen[12];
  assign toNextPipeline_12_be      = ch_wmask[12];
  assign toNextPipeline_12_addr    = ch_addr[12][7:0];
  assign toNextPipeline_12_indata  = ch_wdata[12];
  assign toNextPipeline_12_readen  = ch_readen[12];
  assign toNextPipeline_12_addr_rd = ch_addr_rd[12][7:0];
  assign ch_rdata[12] = DATA_W'(toNextPipeline_12_outdata);
  assign ch_ack[12]   = toNextPipeline_12_ack;
  // ---- child 13：array id 0x4E..0x4F ----
  assign toNextPipeline_13_array   = ch_array[13];
  assign toNextPipeline_13_all     = ch_all[13];
  assign toNextPipeline_13_req     = ch_reqpulse[13];
  assign toNextPipeline_13_writeen = ch_writeen[13];
  assign toNextPipeline_13_be      = ch_wmask[13];
  assign toNextPipeline_13_addr    = ch_addr[13][7:0];
  assign toNextPipeline_13_indata  = ch_wdata[13];
  assign toNextPipeline_13_readen  = ch_readen[13];
  assign toNextPipeline_13_addr_rd = ch_addr_rd[13][7:0];
  assign ch_rdata[13] = DATA_W'(toNextPipeline_13_outdata);
  assign ch_ack[13]   = toNextPipeline_13_ack;
  // ---- child 14：array id 0x50..0x51 ----
  assign toNextPipeline_14_array   = ch_array[14];
  assign toNextPipeline_14_all     = ch_all[14];
  assign toNextPipeline_14_req     = ch_reqpulse[14];
  assign toNextPipeline_14_writeen = ch_writeen[14];
  assign toNextPipeline_14_be      = ch_wmask[14];
  assign toNextPipeline_14_addr    = ch_addr[14][7:0];
  assign toNextPipeline_14_indata  = ch_wdata[14];
  assign toNextPipeline_14_readen  = ch_readen[14];
  assign toNextPipeline_14_addr_rd = ch_addr_rd[14][7:0];
  assign ch_rdata[14] = DATA_W'(toNextPipeline_14_outdata);
  assign ch_ack[14]   = toNextPipeline_14_ack;
  // ---- child 15：array id 0x52..0x53 ----
  assign toNextPipeline_15_array   = ch_array[15];
  assign toNextPipeline_15_all     = ch_all[15];
  assign toNextPipeline_15_req     = ch_reqpulse[15];
  assign toNextPipeline_15_writeen = ch_writeen[15];
  assign toNextPipeline_15_be      = ch_wmask[15];
  assign toNextPipeline_15_addr    = ch_addr[15][7:0];
  assign toNextPipeline_15_indata  = ch_wdata[15];
  assign toNextPipeline_15_readen  = ch_readen[15];
  assign toNextPipeline_15_addr_rd = ch_addr_rd[15][7:0];
  assign ch_rdata[15] = DATA_W'(toNextPipeline_15_outdata);
  assign ch_ack[15]   = toNextPipeline_15_ack;

endmodule
// END GENERATED(MbistPipeFrontend)
