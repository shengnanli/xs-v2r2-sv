// L2DataStorage_1.sv —— MBIST 分发树的 extraHold 叶子节点：L2 slice 1 数据阵列 GatedSplittedSRAM_1 的 4 个 bank（extraHold）
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      叶子（extraHold）：直接驱动 SRAM 的 bore 口，4 个 child（toSRAM_0..3）
//   例化于    DataStorage_1
//   MBIST array id  0x14..0x17（共 4 个），故 ARRAY_W = clog2(0x17+1) = 5 位
//   上游总线  addr/addr_rd 13 位  indata/outdata 137 位  be 1 位
//   规模      golden 289 行 / 53 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_hold_leaf_core
//
// 各 child 认领的 array id 与端口宽度：
//   child 0   id 0x14          array 5 位  addr 13  data 137  be 1   selectedOH 1 位
//   child 1   id 0x15          array 5 位  addr 13  data 137  be 1   selectedOH 1 位
//   child 2   id 0x16          array 5 位  addr 13  data 137  be 1   selectedOH 1 位
//   child 3   id 0x17          array 5 位  addr 13  data 137  be 1   selectedOH 1 位
//
// extraHold 与普通叶子的区别讲在 rtl/dft/xs_mbist_hold_leaf_core.sv 文件头；
// 分发树整体讲在 rtl/dft/xs_mbist_pipe_core.sv 文件头。

// BEGIN GENERATED(L2DataStorage_1) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module L2DataStorage_1 (
  input  logic clock,
  input  logic reset,
  input  logic [4:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic mbist_be,
  input  logic [12:0] mbist_addr,
  input  logic [136:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [12:0] mbist_addr_rd,
  output logic [136:0] mbist_outdata,
  output logic [12:0] toSRAM_0_addr,
  output logic [12:0] toSRAM_0_addr_rd,
  output logic [136:0] toSRAM_0_wdata,
  output logic toSRAM_0_wmask,
  output logic toSRAM_0_re,
  output logic toSRAM_0_we,
  input  logic [136:0] toSRAM_0_rdata,
  output logic toSRAM_0_ack,
  output logic toSRAM_0_selectedOH,
  output logic [4:0] toSRAM_0_array,
  output logic [12:0] toSRAM_1_addr,
  output logic [12:0] toSRAM_1_addr_rd,
  output logic [136:0] toSRAM_1_wdata,
  output logic toSRAM_1_wmask,
  output logic toSRAM_1_re,
  output logic toSRAM_1_we,
  input  logic [136:0] toSRAM_1_rdata,
  output logic toSRAM_1_ack,
  output logic toSRAM_1_selectedOH,
  output logic [4:0] toSRAM_1_array,
  output logic [12:0] toSRAM_2_addr,
  output logic [12:0] toSRAM_2_addr_rd,
  output logic [136:0] toSRAM_2_wdata,
  output logic toSRAM_2_wmask,
  output logic toSRAM_2_re,
  output logic toSRAM_2_we,
  input  logic [136:0] toSRAM_2_rdata,
  output logic toSRAM_2_ack,
  output logic toSRAM_2_selectedOH,
  output logic [4:0] toSRAM_2_array,
  output logic [12:0] toSRAM_3_addr,
  output logic [12:0] toSRAM_3_addr_rd,
  output logic [136:0] toSRAM_3_wdata,
  output logic toSRAM_3_wmask,
  output logic toSRAM_3_re,
  output logic toSRAM_3_we,
  input  logic [136:0] toSRAM_3_rdata,
  output logic toSRAM_3_ack,
  output logic toSRAM_3_selectedOH,
  output logic [4:0] toSRAM_3_array
);

  localparam int unsigned N_CHILD = 4;
  localparam int unsigned MAX_IDS = 1;
  localparam int unsigned ARRAY_W = 5;
  localparam int unsigned ADDR_W  = 13;
  localparam int unsigned DATA_W  = 137;
  localparam int unsigned BE_W    = 1;

  logic [ARRAY_W-1:0] ch_array      [N_CHILD];
  logic               ch_ack        [N_CHILD];
  logic               ch_writeen    [N_CHILD];
  logic [BE_W-1:0]    ch_wmask      [N_CHILD];
  logic [ADDR_W-1:0]  ch_addr       [N_CHILD];
  logic [DATA_W-1:0]  ch_wdata      [N_CHILD];
  logic               ch_readen     [N_CHILD];
  logic [ADDR_W-1:0]  ch_addr_rd    [N_CHILD];
  logic [MAX_IDS-1:0] ch_selectedOH [N_CHILD];
  logic [DATA_W-1:0]  ch_rdata      [N_CHILD];

  xs_mbist_hold_leaf_core #(
    .N_CHILD (N_CHILD),
    .ARRAY_W (ARRAY_W),
    .BE_W    (BE_W),
    .ADDR_W  (ADDR_W),
    .DATA_W  (DATA_W),
    .ID_LO   ('{'h14, 'h15, 'h16, 'h17}),
    .ID_CNT  ('{1, 1, 1, 1}),
    .MAX_IDS (MAX_IDS)
  ) u_core (
    .clock (clock), .reset (reset),
    .mbist_array (mbist_array), .mbist_all (mbist_all), .mbist_req (mbist_req),
    .mbist_ack (mbist_ack), .mbist_writeen (mbist_writeen), .mbist_be (mbist_be),
    .mbist_addr (mbist_addr), .mbist_indata (mbist_indata), .mbist_readen (mbist_readen),
    .mbist_addr_rd (mbist_addr_rd), .mbist_outdata (mbist_outdata),
    .ch_array (ch_array), .ch_ack (ch_ack), .ch_writeen (ch_writeen), .ch_wmask (ch_wmask),
    .ch_addr (ch_addr), .ch_wdata (ch_wdata), .ch_readen (ch_readen), .ch_addr_rd (ch_addr_rd),
    .ch_selectedOH (ch_selectedOH), .ch_rdata (ch_rdata)
  );

  // 端口展平：核按上游最大位宽给，这里截到每个 child 的实宽；读数据反向零扩展。
  // ---- child 0 ----
  assign toSRAM_0_addr       = ch_addr[0];
  assign toSRAM_0_addr_rd    = ch_addr_rd[0];
  assign toSRAM_0_wdata      = ch_wdata[0];
  assign toSRAM_0_wmask      = ch_wmask[0];
  assign toSRAM_0_re         = ch_readen[0];
  assign toSRAM_0_we         = ch_writeen[0];
  assign toSRAM_0_ack        = ch_ack[0];
  assign toSRAM_0_selectedOH = ch_selectedOH[0];
  assign toSRAM_0_array      = ch_array[0];
  assign ch_rdata[0]         = DATA_W'(toSRAM_0_rdata);
  // ---- child 1 ----
  assign toSRAM_1_addr       = ch_addr[1];
  assign toSRAM_1_addr_rd    = ch_addr_rd[1];
  assign toSRAM_1_wdata      = ch_wdata[1];
  assign toSRAM_1_wmask      = ch_wmask[1];
  assign toSRAM_1_re         = ch_readen[1];
  assign toSRAM_1_we         = ch_writeen[1];
  assign toSRAM_1_ack        = ch_ack[1];
  assign toSRAM_1_selectedOH = ch_selectedOH[1];
  assign toSRAM_1_array      = ch_array[1];
  assign ch_rdata[1]         = DATA_W'(toSRAM_1_rdata);
  // ---- child 2 ----
  assign toSRAM_2_addr       = ch_addr[2];
  assign toSRAM_2_addr_rd    = ch_addr_rd[2];
  assign toSRAM_2_wdata      = ch_wdata[2];
  assign toSRAM_2_wmask      = ch_wmask[2];
  assign toSRAM_2_re         = ch_readen[2];
  assign toSRAM_2_we         = ch_writeen[2];
  assign toSRAM_2_ack        = ch_ack[2];
  assign toSRAM_2_selectedOH = ch_selectedOH[2];
  assign toSRAM_2_array      = ch_array[2];
  assign ch_rdata[2]         = DATA_W'(toSRAM_2_rdata);
  // ---- child 3 ----
  assign toSRAM_3_addr       = ch_addr[3];
  assign toSRAM_3_addr_rd    = ch_addr_rd[3];
  assign toSRAM_3_wdata      = ch_wdata[3];
  assign toSRAM_3_wmask      = ch_wmask[3];
  assign toSRAM_3_re         = ch_readen[3];
  assign toSRAM_3_we         = ch_writeen[3];
  assign toSRAM_3_ack        = ch_ack[3];
  assign toSRAM_3_selectedOH = ch_selectedOH[3];
  assign toSRAM_3_array      = ch_array[3];
  assign ch_rdata[3]         = DATA_W'(toSRAM_3_rdata);

endmodule
// END GENERATED(L2DataStorage_1)
