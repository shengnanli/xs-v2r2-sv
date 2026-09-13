// MbistPipeDcacheTag.sv —— MBIST 分发树的 叶子(leaf) 节点：DCache tag 阵列 TagArray x4（4 份复制）
//
// 本变体参数（全部从 G1 golden 逐根量出来，见 scripts/gen_mbist_pipe_family.py）：
//   拓扑      叶子：直接驱动 SRAM 的 bore 口，8 个 child（toSRAM_0..7）
//   例化于    DuplicatedTagArray
//   MBIST array id  0x20..0x27（共 8 个），故 ARRAY_W = clog2(0x27+1) = 6 位
//   上游总线  addr/addr_rd 9 位  indata/outdata 86 位  be 2 位
//   规模      golden 374 行 / 93 端口；本文件只做参数化例化 + 端口展平，逻辑全在 xs_mbist_pipe_core
//
// 各 child 认领的 array id 与端口宽度。child 的 array 端口按**它自己**的最大 id 算宽，
// 本变体各 child 恰好都是 6 位（不要当成"反正照抄父节点宽度"——换个变体就不是了）：
//   child 0   id 0x20          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 1   id 0x21          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 2   id 0x22          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 3   id 0x23          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 4   id 0x24          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 5   id 0x25          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 6   id 0x26          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//   child 7   id 0x27          array 6 位  addr 9   data 86   be 2   selectedOH 1 位
//
// MBIST 分发树整体是怎么回事、bore 口每根线什么含义、array id 怎么编址，
// 全部讲在核文件 rtl/dft/xs_mbist_pipe_core.sv 的文件头，不在这里重复。

// BEGIN GENERATED(MbistPipeDcacheTag) —— 由 scripts/gen_mbist_pipe_family.py 从 G1 golden 生成
module MbistPipeDcacheTag (
  input  logic clock,
  input  logic reset,
  input  logic [5:0] mbist_array,
  input  logic mbist_all,
  input  logic mbist_req,
  output logic mbist_ack,
  input  logic mbist_writeen,
  input  logic [1:0] mbist_be,
  input  logic [8:0] mbist_addr,
  input  logic [85:0] mbist_indata,
  input  logic mbist_readen,
  input  logic [8:0] mbist_addr_rd,
  output logic [85:0] mbist_outdata,
  output logic [8:0] toSRAM_0_addr,
  output logic [8:0] toSRAM_0_addr_rd,
  output logic [85:0] toSRAM_0_wdata,
  output logic [1:0] toSRAM_0_wmask,
  output logic toSRAM_0_re,
  output logic toSRAM_0_we,
  input  logic [85:0] toSRAM_0_rdata,
  output logic toSRAM_0_ack,
  output logic toSRAM_0_selectedOH,
  output logic [5:0] toSRAM_0_array,
  output logic [8:0] toSRAM_1_addr,
  output logic [8:0] toSRAM_1_addr_rd,
  output logic [85:0] toSRAM_1_wdata,
  output logic [1:0] toSRAM_1_wmask,
  output logic toSRAM_1_re,
  output logic toSRAM_1_we,
  input  logic [85:0] toSRAM_1_rdata,
  output logic toSRAM_1_ack,
  output logic toSRAM_1_selectedOH,
  output logic [5:0] toSRAM_1_array,
  output logic [8:0] toSRAM_2_addr,
  output logic [8:0] toSRAM_2_addr_rd,
  output logic [85:0] toSRAM_2_wdata,
  output logic [1:0] toSRAM_2_wmask,
  output logic toSRAM_2_re,
  output logic toSRAM_2_we,
  input  logic [85:0] toSRAM_2_rdata,
  output logic toSRAM_2_ack,
  output logic toSRAM_2_selectedOH,
  output logic [5:0] toSRAM_2_array,
  output logic [8:0] toSRAM_3_addr,
  output logic [8:0] toSRAM_3_addr_rd,
  output logic [85:0] toSRAM_3_wdata,
  output logic [1:0] toSRAM_3_wmask,
  output logic toSRAM_3_re,
  output logic toSRAM_3_we,
  input  logic [85:0] toSRAM_3_rdata,
  output logic toSRAM_3_ack,
  output logic toSRAM_3_selectedOH,
  output logic [5:0] toSRAM_3_array,
  output logic [8:0] toSRAM_4_addr,
  output logic [8:0] toSRAM_4_addr_rd,
  output logic [85:0] toSRAM_4_wdata,
  output logic [1:0] toSRAM_4_wmask,
  output logic toSRAM_4_re,
  output logic toSRAM_4_we,
  input  logic [85:0] toSRAM_4_rdata,
  output logic toSRAM_4_ack,
  output logic toSRAM_4_selectedOH,
  output logic [5:0] toSRAM_4_array,
  output logic [8:0] toSRAM_5_addr,
  output logic [8:0] toSRAM_5_addr_rd,
  output logic [85:0] toSRAM_5_wdata,
  output logic [1:0] toSRAM_5_wmask,
  output logic toSRAM_5_re,
  output logic toSRAM_5_we,
  input  logic [85:0] toSRAM_5_rdata,
  output logic toSRAM_5_ack,
  output logic toSRAM_5_selectedOH,
  output logic [5:0] toSRAM_5_array,
  output logic [8:0] toSRAM_6_addr,
  output logic [8:0] toSRAM_6_addr_rd,
  output logic [85:0] toSRAM_6_wdata,
  output logic [1:0] toSRAM_6_wmask,
  output logic toSRAM_6_re,
  output logic toSRAM_6_we,
  input  logic [85:0] toSRAM_6_rdata,
  output logic toSRAM_6_ack,
  output logic toSRAM_6_selectedOH,
  output logic [5:0] toSRAM_6_array,
  output logic [8:0] toSRAM_7_addr,
  output logic [8:0] toSRAM_7_addr_rd,
  output logic [85:0] toSRAM_7_wdata,
  output logic [1:0] toSRAM_7_wmask,
  output logic toSRAM_7_re,
  output logic toSRAM_7_we,
  input  logic [85:0] toSRAM_7_rdata,
  output logic toSRAM_7_ack,
  output logic toSRAM_7_selectedOH,
  output logic [5:0] toSRAM_7_array
);

  localparam int unsigned N_CHILD = 8;
  localparam int unsigned MAX_IDS = 1;
  localparam int unsigned ARRAY_W = 6;
  localparam int unsigned ADDR_W  = 9;
  localparam int unsigned DATA_W  = 86;
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
    .IS_NODE (1'b0),
    .N_CHILD (N_CHILD),
    .ARRAY_W (ARRAY_W),
    .BE_W    (BE_W),
    .ADDR_W  (ADDR_W),
    .DATA_W  (DATA_W),
    .ID_LO   ('{'h20, 'h21, 'h22, 'h23, 'h24, 'h25, 'h26, 'h27}),
    .ID_CNT  ('{1, 1, 1, 1, 1, 1, 1, 1}),
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
  // ---- child 0：array id 0x20 ----
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
  // ---- child 1：array id 0x21 ----
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
  // ---- child 2：array id 0x22 ----
  assign toSRAM_2_addr       = ch_addr[2];
  assign toSRAM_2_addr_rd    = ch_addr_rd[2];
  assign toSRAM_2_wdata      = ch_wdata[2];
  assign toSRAM_2_wmask      = ch_wmask[2];
  assign toSRAM_2_re         = ch_readen[2];
  assign toSRAM_2_we         = ch_writeen[2];
  assign toSRAM_2_ack        = ch_reqpulse[2];
  assign toSRAM_2_selectedOH = ch_selectedOH[2];
  assign toSRAM_2_array      = ch_array[2];
  assign ch_rdata[2]    = DATA_W'(toSRAM_2_rdata);
  assign ch_ack[2]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 3：array id 0x23 ----
  assign toSRAM_3_addr       = ch_addr[3];
  assign toSRAM_3_addr_rd    = ch_addr_rd[3];
  assign toSRAM_3_wdata      = ch_wdata[3];
  assign toSRAM_3_wmask      = ch_wmask[3];
  assign toSRAM_3_re         = ch_readen[3];
  assign toSRAM_3_we         = ch_writeen[3];
  assign toSRAM_3_ack        = ch_reqpulse[3];
  assign toSRAM_3_selectedOH = ch_selectedOH[3];
  assign toSRAM_3_array      = ch_array[3];
  assign ch_rdata[3]    = DATA_W'(toSRAM_3_rdata);
  assign ch_ack[3]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 4：array id 0x24 ----
  assign toSRAM_4_addr       = ch_addr[4];
  assign toSRAM_4_addr_rd    = ch_addr_rd[4];
  assign toSRAM_4_wdata      = ch_wdata[4];
  assign toSRAM_4_wmask      = ch_wmask[4];
  assign toSRAM_4_re         = ch_readen[4];
  assign toSRAM_4_we         = ch_writeen[4];
  assign toSRAM_4_ack        = ch_reqpulse[4];
  assign toSRAM_4_selectedOH = ch_selectedOH[4];
  assign toSRAM_4_array      = ch_array[4];
  assign ch_rdata[4]    = DATA_W'(toSRAM_4_rdata);
  assign ch_ack[4]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 5：array id 0x25 ----
  assign toSRAM_5_addr       = ch_addr[5];
  assign toSRAM_5_addr_rd    = ch_addr_rd[5];
  assign toSRAM_5_wdata      = ch_wdata[5];
  assign toSRAM_5_wmask      = ch_wmask[5];
  assign toSRAM_5_re         = ch_readen[5];
  assign toSRAM_5_we         = ch_writeen[5];
  assign toSRAM_5_ack        = ch_reqpulse[5];
  assign toSRAM_5_selectedOH = ch_selectedOH[5];
  assign toSRAM_5_array      = ch_array[5];
  assign ch_rdata[5]    = DATA_W'(toSRAM_5_rdata);
  assign ch_ack[5]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 6：array id 0x26 ----
  assign toSRAM_6_addr       = ch_addr[6];
  assign toSRAM_6_addr_rd    = ch_addr_rd[6];
  assign toSRAM_6_wdata      = ch_wdata[6];
  assign toSRAM_6_wmask      = ch_wmask[6];
  assign toSRAM_6_re         = ch_readen[6];
  assign toSRAM_6_we         = ch_writeen[6];
  assign toSRAM_6_ack        = ch_reqpulse[6];
  assign toSRAM_6_selectedOH = ch_selectedOH[6];
  assign toSRAM_6_array      = ch_array[6];
  assign ch_rdata[6]    = DATA_W'(toSRAM_6_rdata);
  assign ch_ack[6]      = 1'b0;   // 叶子不看 SRAM 的 ack
  // ---- child 7：array id 0x27 ----
  assign toSRAM_7_addr       = ch_addr[7];
  assign toSRAM_7_addr_rd    = ch_addr_rd[7];
  assign toSRAM_7_wdata      = ch_wdata[7];
  assign toSRAM_7_wmask      = ch_wmask[7];
  assign toSRAM_7_re         = ch_readen[7];
  assign toSRAM_7_we         = ch_writeen[7];
  assign toSRAM_7_ack        = ch_reqpulse[7];
  assign toSRAM_7_selectedOH = ch_selectedOH[7];
  assign toSRAM_7_array      = ch_array[7];
  assign ch_rdata[7]    = DATA_W'(toSRAM_7_rdata);
  assign ch_ack[7]      = 1'b0;   // 叶子不看 SRAM 的 ack

endmodule
// END GENERATED(MbistPipeDcacheTag)
