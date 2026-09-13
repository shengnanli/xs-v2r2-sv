// MbistPipeMemBlk.sv —— MBIST 分发树的 中间(node) 节点：访存块整棵 MBIST 子树（DCache + L2TLB + SMS 预取器）
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      中间节点：往下接 MbistPipe，6 个 child（toNextPipeline_0..5）
//   例化于    MemBlock
//   MBIST array id  0x00..0x42（共 67 个），故 ARRAY_W = clog2(0x42+1) = 7 位
//   上游总线  addr/addr_rd 9 位  indata/outdata 148 位  be 2 位
//   规模      golden 392 行 / 79 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体因此出现 5/6/7 位并存的参差宽度——这正是本家族最容易写错的地方：
//   child 0   id 0x00..0x1F    array 5 位  addr 9   data 72   be 1 
//   child 1   id 0x20..0x27    array 6 位  addr 9   data 86   be 2 
//   child 2   id 0x28..0x2B    array 6 位  addr 6   data 90   be 2 
//   child 3   id 0x2C..0x31    array 6 位  addr 3   data 131  be 1 
//   child 4   id 0x32..0x41    array 7 位  addr 7   data 114  be 2 
//   child 5   id 0x42          array 7 位  addr 6   data 148  be 2 
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(MbistPipeMemBlk) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module MbistPipeMemBlk (
  input  logic clock,
  input  logic reset,
  input  logic [6:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic [1:0] mbist_be,
  input  logic [8:0] mbist_addr,
  input  logic [147:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [8:0] mbist_addr_rd,
  output logic [147:0] mbist_outdata,
  output logic [4:0] toNextPipeline_0_array,
  output logic toNextPipeline_0_all,
  output logic toNextPipeline_0_req,
  input  logic toNextPipeline_0_ack,
  output logic toNextPipeline_0_writeen,
  output logic toNextPipeline_0_be,
  output logic [8:0] toNextPipeline_0_addr,
  output logic [71:0] toNextPipeline_0_indata,
  output logic toNextPipeline_0_readen,
  output logic [8:0] toNextPipeline_0_addr_rd,
  input  logic [71:0] toNextPipeline_0_outdata,
  output logic [5:0] toNextPipeline_1_array,
  output logic toNextPipeline_1_all,
  output logic toNextPipeline_1_req,
  input  logic toNextPipeline_1_ack,
  output logic toNextPipeline_1_writeen,
  output logic [1:0] toNextPipeline_1_be,
  output logic [8:0] toNextPipeline_1_addr,
  output logic [85:0] toNextPipeline_1_indata,
  output logic toNextPipeline_1_readen,
  output logic [8:0] toNextPipeline_1_addr_rd,
  input  logic [85:0] toNextPipeline_1_outdata,
  output logic [5:0] toNextPipeline_2_array,
  output logic toNextPipeline_2_all,
  output logic toNextPipeline_2_req,
  input  logic toNextPipeline_2_ack,
  output logic toNextPipeline_2_writeen,
  output logic [1:0] toNextPipeline_2_be,
  output logic [5:0] toNextPipeline_2_addr,
  output logic [89:0] toNextPipeline_2_indata,
  output logic toNextPipeline_2_readen,
  output logic [5:0] toNextPipeline_2_addr_rd,
  input  logic [89:0] toNextPipeline_2_outdata,
  output logic [5:0] toNextPipeline_3_array,
  output logic toNextPipeline_3_all,
  output logic toNextPipeline_3_req,
  input  logic toNextPipeline_3_ack,
  output logic toNextPipeline_3_writeen,
  output logic toNextPipeline_3_be,
  output logic [2:0] toNextPipeline_3_addr,
  output logic [130:0] toNextPipeline_3_indata,
  output logic toNextPipeline_3_readen,
  output logic [2:0] toNextPipeline_3_addr_rd,
  input  logic [130:0] toNextPipeline_3_outdata,
  output logic [6:0] toNextPipeline_4_array,
  output logic toNextPipeline_4_all,
  output logic toNextPipeline_4_req,
  input  logic toNextPipeline_4_ack,
  output logic toNextPipeline_4_writeen,
  output logic [1:0] toNextPipeline_4_be,
  output logic [6:0] toNextPipeline_4_addr,
  output logic [113:0] toNextPipeline_4_indata,
  output logic toNextPipeline_4_readen,
  output logic [6:0] toNextPipeline_4_addr_rd,
  input  logic [113:0] toNextPipeline_4_outdata,
  output logic [6:0] toNextPipeline_5_array,
  output logic toNextPipeline_5_all,
  output logic toNextPipeline_5_req,
  input  logic toNextPipeline_5_ack,
  output logic toNextPipeline_5_writeen,
  output logic [1:0] toNextPipeline_5_be,
  output logic [5:0] toNextPipeline_5_addr,
  output logic [147:0] toNextPipeline_5_indata,
  output logic toNextPipeline_5_readen,
  output logic [5:0] toNextPipeline_5_addr_rd,
  input  logic [147:0] toNextPipeline_5_outdata
);

  localparam int unsigned N_CHILD = 6;
  localparam int unsigned MAX_IDS = 32;
  localparam int unsigned ARRAY_W = 7;
  localparam int unsigned ADDR_W  = 9;
  localparam int unsigned DATA_W  = 148;
  localparam int unsigned BE_W    = 2;

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
    .ID_LO   ('{'h00, 'h20, 'h28, 'h2C, 'h32, 'h42}),
    .ID_CNT  ('{32, 8, 4, 6, 16, 1}),
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
  // ---- child 0：array id 0x00..0x1F ----
  assign toNextPipeline_0_array   = ch_array[0][4:0];
  assign toNextPipeline_0_all     = ch_all[0];
  assign toNextPipeline_0_req     = ch_reqpulse[0];
  assign toNextPipeline_0_writeen = ch_writeen[0];
  assign toNextPipeline_0_be      = ch_wmask[0][0:0];
  assign toNextPipeline_0_addr    = ch_addr[0];
  assign toNextPipeline_0_indata  = ch_wdata[0][71:0];
  assign toNextPipeline_0_readen  = ch_readen[0];
  assign toNextPipeline_0_addr_rd = ch_addr_rd[0];
  assign ch_rdata[0] = DATA_W'(toNextPipeline_0_outdata);
  assign ch_ack[0]   = toNextPipeline_0_ack;
  // ---- child 1：array id 0x20..0x27 ----
  assign toNextPipeline_1_array   = ch_array[1][5:0];
  assign toNextPipeline_1_all     = ch_all[1];
  assign toNextPipeline_1_req     = ch_reqpulse[1];
  assign toNextPipeline_1_writeen = ch_writeen[1];
  assign toNextPipeline_1_be      = ch_wmask[1];
  assign toNextPipeline_1_addr    = ch_addr[1];
  assign toNextPipeline_1_indata  = ch_wdata[1][85:0];
  assign toNextPipeline_1_readen  = ch_readen[1];
  assign toNextPipeline_1_addr_rd = ch_addr_rd[1];
  assign ch_rdata[1] = DATA_W'(toNextPipeline_1_outdata);
  assign ch_ack[1]   = toNextPipeline_1_ack;
  // ---- child 2：array id 0x28..0x2B ----
  assign toNextPipeline_2_array   = ch_array[2][5:0];
  assign toNextPipeline_2_all     = ch_all[2];
  assign toNextPipeline_2_req     = ch_reqpulse[2];
  assign toNextPipeline_2_writeen = ch_writeen[2];
  assign toNextPipeline_2_be      = ch_wmask[2];
  assign toNextPipeline_2_addr    = ch_addr[2][5:0];
  assign toNextPipeline_2_indata  = ch_wdata[2][89:0];
  assign toNextPipeline_2_readen  = ch_readen[2];
  assign toNextPipeline_2_addr_rd = ch_addr_rd[2][5:0];
  assign ch_rdata[2] = DATA_W'(toNextPipeline_2_outdata);
  assign ch_ack[2]   = toNextPipeline_2_ack;
  // ---- child 3：array id 0x2C..0x31 ----
  assign toNextPipeline_3_array   = ch_array[3][5:0];
  assign toNextPipeline_3_all     = ch_all[3];
  assign toNextPipeline_3_req     = ch_reqpulse[3];
  assign toNextPipeline_3_writeen = ch_writeen[3];
  assign toNextPipeline_3_be      = ch_wmask[3][0:0];
  assign toNextPipeline_3_addr    = ch_addr[3][2:0];
  assign toNextPipeline_3_indata  = ch_wdata[3][130:0];
  assign toNextPipeline_3_readen  = ch_readen[3];
  assign toNextPipeline_3_addr_rd = ch_addr_rd[3][2:0];
  assign ch_rdata[3] = DATA_W'(toNextPipeline_3_outdata);
  assign ch_ack[3]   = toNextPipeline_3_ack;
  // ---- child 4：array id 0x32..0x41 ----
  assign toNextPipeline_4_array   = ch_array[4];
  assign toNextPipeline_4_all     = ch_all[4];
  assign toNextPipeline_4_req     = ch_reqpulse[4];
  assign toNextPipeline_4_writeen = ch_writeen[4];
  assign toNextPipeline_4_be      = ch_wmask[4];
  assign toNextPipeline_4_addr    = ch_addr[4][6:0];
  assign toNextPipeline_4_indata  = ch_wdata[4][113:0];
  assign toNextPipeline_4_readen  = ch_readen[4];
  assign toNextPipeline_4_addr_rd = ch_addr_rd[4][6:0];
  assign ch_rdata[4] = DATA_W'(toNextPipeline_4_outdata);
  assign ch_ack[4]   = toNextPipeline_4_ack;
  // ---- child 5：array id 0x42 ----
  assign toNextPipeline_5_array   = ch_array[5];
  assign toNextPipeline_5_all     = ch_all[5];
  assign toNextPipeline_5_req     = ch_reqpulse[5];
  assign toNextPipeline_5_writeen = ch_writeen[5];
  assign toNextPipeline_5_be      = ch_wmask[5];
  assign toNextPipeline_5_addr    = ch_addr[5][5:0];
  assign toNextPipeline_5_indata  = ch_wdata[5];
  assign toNextPipeline_5_readen  = ch_readen[5];
  assign toNextPipeline_5_addr_rd = ch_addr_rd[5][5:0];
  assign ch_rdata[5] = DATA_W'(toNextPipeline_5_outdata);
  assign ch_ack[5]   = toNextPipeline_5_ack;

endmodule
// END GENERATED(MbistPipeMemBlk)
