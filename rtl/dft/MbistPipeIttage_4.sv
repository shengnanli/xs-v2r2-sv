// MbistPipeIttage_4.sv —— MBIST 分发树的 叶子(leaf) 节点：ITTage 表 4 的 FoldedSRAMTemplate_24（双 bore 口）
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      叶子：直接驱动 SRAM 的 bore 口，2 个 child（toSRAM_0..1）
//   例化于    ITTageTable_4
//   MBIST array id  0x52..0x53（共 2 个），故 ARRAY_W = clog2(0x53+1) = 7 位
//   上游总线  addr/addr_rd 8 位  indata/outdata 76 位  be 76 位
//   规模      golden 231 行 / 33 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体各 child 恰好都是 7 位（不要当成"反正照抄父节点宽度"——换个变体就不是了）：
//   child 0   id 0x52          array 7 位  addr 8   data 76   be 76  selectedOH 1 位
//   child 1   id 0x53          array 7 位  addr 8   data 76   be 76  selectedOH 1 位
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(MbistPipeIttage_4) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module MbistPipeIttage_4 (
  input  logic clock,
  input  logic reset,
  input  logic [6:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic [75:0] mbist_be,
  input  logic [7:0] mbist_addr,
  input  logic [75:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [7:0] mbist_addr_rd,
  output logic [75:0] mbist_outdata,
  output logic [7:0] toSRAM_0_addr,
  output logic [7:0] toSRAM_0_addr_rd,
  output logic [75:0] toSRAM_0_wdata,
  output logic [75:0] toSRAM_0_wmask,
  output logic toSRAM_0_re,
  output logic toSRAM_0_we,
  input  logic [75:0] toSRAM_0_rdata,
  output logic toSRAM_0_ack,
  output logic toSRAM_0_selectedOH,
  output logic [6:0] toSRAM_0_array,
  output logic [7:0] toSRAM_1_addr,
  output logic [7:0] toSRAM_1_addr_rd,
  output logic [75:0] toSRAM_1_wdata,
  output logic [75:0] toSRAM_1_wmask,
  output logic toSRAM_1_re,
  output logic toSRAM_1_we,
  input  logic [75:0] toSRAM_1_rdata,
  output logic toSRAM_1_ack,
  output logic toSRAM_1_selectedOH,
  output logic [6:0] toSRAM_1_array
);

  localparam int unsigned N_CHILD = 2;
  localparam int unsigned MAX_IDS = 1;
  localparam int unsigned ARRAY_W = 7;
  localparam int unsigned ADDR_W  = 8;
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
    .IS_NODE (1'b0),
    .N_CHILD (N_CHILD),
    .ARRAY_W (ARRAY_W),
    .BE_W    (BE_W),
    .ADDR_W  (ADDR_W),
    .DATA_W  (DATA_W),
    .ID_LO   ('{'h52, 'h53}),
    .ID_CNT  ('{1, 1}),
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
  // ---- child 0：array id 0x52 ----
  assign toSRAM_0_addr       = ch_addr[0];
  assign toSRAM_0_addr_rd    = ch_addr_rd[0];
  assign toSRAM_0_wdata      = ch_wdata[0];
  assign toSRAM_0_wmask      = ch_wmask[0];
  assign toSRAM_0_re         = ch_readen[0];
  assign toSRAM_0_we         = ch_writeen[0];
  assign toSRAM_0_ack        = ch_reqpulse[0];
  assign toSRAM_0_selectedOH = ch_selectedOH[0];
  assign toSRAM_0_array      = ch_array[0];
  assign ch_rdata[0]    = DATA_W'(toSRAM_0_rdata);
  assign ch_ack[0]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 1：array id 0x53 ----
  assign toSRAM_1_addr       = ch_addr[1];
  assign toSRAM_1_addr_rd    = ch_addr_rd[1];
  assign toSRAM_1_wdata      = ch_wdata[1];
  assign toSRAM_1_wmask      = ch_wmask[1];
  assign toSRAM_1_re         = ch_readen[1];
  assign toSRAM_1_we         = ch_writeen[1];
  assign toSRAM_1_ack        = ch_reqpulse[1];
  assign toSRAM_1_selectedOH = ch_selectedOH[1];
  assign toSRAM_1_array      = ch_array[1];
  assign ch_rdata[1]    = DATA_W'(toSRAM_1_rdata);
  assign ch_ack[1]      = 1'b0;   // 叶子不看 SRAM 的 ack

endmodule
// END GENERATED(MbistPipeIttage_4)
