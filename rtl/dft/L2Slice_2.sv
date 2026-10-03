// L2Slice_2.sv —— MBIST 分发树的 中间(node) 节点：L2 slice 2 的 MBIST 子树：child0=Directory 层(L2Directory_2)、child1=DataStorage 层(L2DataStorage_2)
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      中间节点：往下接 MbistPipe，2 个 child（toNextPipeline_0..1）
//   例化于    Slice_2
//   MBIST array id  0x18..0x22（共 11 个），故 ARRAY_W = clog2(0x22+1) = 6 位
//   上游总线  addr/addr_rd 13 位  indata/outdata 137 位  be 8 位
//   规模      golden 254 行 / 35 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体因此出现 5/6 位并存的参差宽度——这正是本家族最容易写错的地方：
//   child 0   id 0x18..0x1E    array 5 位  addr 10  data 104  be 8 
//   child 1   id 0x1F..0x22    array 6 位  addr 13  data 137  be 1 
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(L2Slice_2) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module L2Slice_2 (
  input  logic clock,
  input  logic reset,
  input  logic [5:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic [7:0] mbist_be,
  input  logic [12:0] mbist_addr,
  input  logic [136:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [12:0] mbist_addr_rd,
  output logic [136:0] mbist_outdata,
  output logic [4:0] toNextPipeline_0_array,
  output logic toNextPipeline_0_all,
  output logic toNextPipeline_0_req,
  input  logic toNextPipeline_0_ack,
  output logic toNextPipeline_0_writeen,
  output logic [7:0] toNextPipeline_0_be,
  output logic [9:0] toNextPipeline_0_addr,
  output logic [103:0] toNextPipeline_0_indata,
  output logic toNextPipeline_0_readen,
  output logic [9:0] toNextPipeline_0_addr_rd,
  input  logic [103:0] toNextPipeline_0_outdata,
  output logic [5:0] toNextPipeline_1_array,
  output logic toNextPipeline_1_all,
  output logic toNextPipeline_1_req,
  input  logic toNextPipeline_1_ack,
  output logic toNextPipeline_1_writeen,
  output logic toNextPipeline_1_be,
  output logic [12:0] toNextPipeline_1_addr,
  output logic [136:0] toNextPipeline_1_indata,
  output logic toNextPipeline_1_readen,
  output logic [12:0] toNextPipeline_1_addr_rd,
  input  logic [136:0] toNextPipeline_1_outdata
);

  localparam int unsigned N_CHILD = 2;
  localparam int unsigned MAX_IDS = 7;
  localparam int unsigned ARRAY_W = 6;
  localparam int unsigned ADDR_W  = 13;
  localparam int unsigned DATA_W  = 137;
  localparam int unsigned BE_W    = 8;

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
    .ID_LO   ('{'h18, 'h1F}),
    .ID_CNT  ('{7, 4}),
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
  // ---- child 0：array id 0x18..0x1E ----
  assign toNextPipeline_0_array   = ch_array[0][4:0];
  assign toNextPipeline_0_all     = ch_all[0];
  assign toNextPipeline_0_req     = ch_reqpulse[0];
  assign toNextPipeline_0_writeen = ch_writeen[0];
  assign toNextPipeline_0_be      = ch_wmask[0];
  assign toNextPipeline_0_addr    = ch_addr[0][9:0];
  assign toNextPipeline_0_indata  = ch_wdata[0][103:0];
  assign toNextPipeline_0_readen  = ch_readen[0];
  assign toNextPipeline_0_addr_rd = ch_addr_rd[0][9:0];
  assign ch_rdata[0] = DATA_W'(toNextPipeline_0_outdata);
  assign ch_ack[0]   = toNextPipeline_0_ack;
  // ---- child 1：array id 0x1F..0x22 ----
  assign toNextPipeline_1_array   = ch_array[1];
  assign toNextPipeline_1_all     = ch_all[1];
  assign toNextPipeline_1_req     = ch_reqpulse[1];
  assign toNextPipeline_1_writeen = ch_writeen[1];
  assign toNextPipeline_1_be      = ch_wmask[1][0:0];
  assign toNextPipeline_1_addr    = ch_addr[1];
  assign toNextPipeline_1_indata  = ch_wdata[1];
  assign toNextPipeline_1_readen  = ch_readen[1];
  assign toNextPipeline_1_addr_rd = ch_addr_rd[1];
  assign ch_rdata[1] = DATA_W'(toNextPipeline_1_outdata);
  assign ch_ack[1]   = toNextPipeline_1_ack;

endmodule
// END GENERATED(L2Slice_2)
