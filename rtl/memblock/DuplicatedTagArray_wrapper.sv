// =============================================================================
// DuplicatedTagArray_wrapper —— golden 同名顶层（FM 对比 / ST 替换用）
// -----------------------------------------------------------------------------
// 端口与 golden DuplicatedTagArray 完全一致（扁平）。本 wrapper 是机械适配层：
//   · 例化 4 个 golden TagArray 黑盒（array_0..3，每副本一套读口）；
//   · 例化 golden MbistPipeDcacheTag 黑盒，按 golden 拓扑把 8 条 childBd bore 链
//     连到 4 个副本（每副本 2 个 bore 子口，对应其 2 个 TagSRAMBank）；
//   · 把读/写/resp 路由与 Tag-ECC 计算交给可读核 xs_DuplicatedTagArray_core
//     （golden 在顶层内联算 ecc 并扇出，此处改由核统一处理）。
//   · sigFromSrams_bore_N（N=0..7）的 SRAM 旁带按 golden 映射：array_k 取 [2k,2k+1]。
//
// 命名同 golden（DuplicatedTagArray），供 FM/ST 直接对接。UT 用 _xs 镜像（见 variants）。
// =============================================================================
module DuplicatedTagArray import dtagarray_pkg::*; (
  input         clock,
  input         reset,
  input         io_read_0_valid,
  input  [7:0]  io_read_0_bits_idx,
  input         io_read_1_valid,
  input  [7:0]  io_read_1_bits_idx,
  input         io_read_2_valid,
  input  [7:0]  io_read_2_bits_idx,
  output        io_read_3_ready,
  input         io_read_3_valid,
  input  [7:0]  io_read_3_bits_idx,
  output [42:0] io_resp_0_0,
  output [42:0] io_resp_0_1,
  output [42:0] io_resp_0_2,
  output [42:0] io_resp_0_3,
  output [42:0] io_resp_1_0,
  output [42:0] io_resp_1_1,
  output [42:0] io_resp_1_2,
  output [42:0] io_resp_1_3,
  output [42:0] io_resp_2_0,
  output [42:0] io_resp_2_1,
  output [42:0] io_resp_2_2,
  output [42:0] io_resp_2_3,
  output [42:0] io_resp_3_0,
  output [42:0] io_resp_3_1,
  output [42:0] io_resp_3_2,
  output [42:0] io_resp_3_3,
  input         io_write_valid,
  input  [7:0]  io_write_bits_idx,
  input  [3:0]  io_write_bits_way_en,
  input  [35:0] io_write_bits_tag,
  input  [5:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input  [1:0]  boreChildrenBd_bore_be,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [85:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  output [85:0] boreChildrenBd_bore_outdata,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,
  input         sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken,
  input         sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp,
  input         sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,
  input         sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken,
  input         sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp,
  input         sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,
  input         sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken,
  input         sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp,
  input         sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,
  input         sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken,
  input         sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp,
  input         sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen
);

  // ---------------------------------------------------------------------------
  // 可读核接口信号（struct/数组端口拆成局部变量再扁平连）
  // ---------------------------------------------------------------------------
  logic               core_read_valid [READ_PORTS];
  logic [IDX_W-1:0]   core_read_idx   [READ_PORTS];
  logic               core_read3_ready;
  logic [ENC_TAG_W-1:0] core_resp     [READ_PORTS][N_WAYS];

  logic               core_tarr_read_valid [READ_PORTS];
  logic [IDX_W-1:0]   core_tarr_read_idx   [READ_PORTS];
  logic               core_tarr_read_ready [READ_PORTS];
  logic [ENC_TAG_W-1:0] core_tarr_resp     [READ_PORTS][N_WAYS];
  logic               core_tarr_write_valid  [READ_PORTS];
  logic [IDX_W-1:0]   core_tarr_write_idx    [READ_PORTS];
  logic [N_WAYS-1:0]  core_tarr_write_way_en [READ_PORTS];
  logic [TAG_W-1:0]   core_tarr_write_tag    [READ_PORTS];
  logic [ECC_W-1:0]   core_tarr_write_ecc    [READ_PORTS];

  // 扁平 → 核数组
  assign core_read_valid[0] = io_read_0_valid;
  assign core_read_valid[1] = io_read_1_valid;
  assign core_read_valid[2] = io_read_2_valid;
  assign core_read_valid[3] = io_read_3_valid;
  assign core_read_idx[0]   = io_read_0_bits_idx;
  assign core_read_idx[1]   = io_read_1_bits_idx;
  assign core_read_idx[2]   = io_read_2_bits_idx;
  assign core_read_idx[3]   = io_read_3_bits_idx;
  assign io_read_3_ready    = core_read3_ready;

  assign io_resp_0_0 = core_resp[0][0];
  assign io_resp_0_1 = core_resp[0][1];
  assign io_resp_0_2 = core_resp[0][2];
  assign io_resp_0_3 = core_resp[0][3];
  assign io_resp_1_0 = core_resp[1][0];
  assign io_resp_1_1 = core_resp[1][1];
  assign io_resp_1_2 = core_resp[1][2];
  assign io_resp_1_3 = core_resp[1][3];
  assign io_resp_2_0 = core_resp[2][0];
  assign io_resp_2_1 = core_resp[2][1];
  assign io_resp_2_2 = core_resp[2][2];
  assign io_resp_2_3 = core_resp[2][3];
  assign io_resp_3_0 = core_resp[3][0];
  assign io_resp_3_1 = core_resp[3][1];
  assign io_resp_3_2 = core_resp[3][2];
  assign io_resp_3_3 = core_resp[3][3];

  xs_DuplicatedTagArray_core u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(core_read_valid), .io_read_idx(core_read_idx),
    .io_read3_ready(core_read3_ready), .io_resp(core_resp),
    .io_write_valid(io_write_valid), .io_write_idx(io_write_bits_idx),
    .io_write_way_en(io_write_bits_way_en), .io_write_tag(io_write_bits_tag),
    .tarr_read_valid(core_tarr_read_valid), .tarr_read_idx(core_tarr_read_idx),
    .tarr_read_ready(core_tarr_read_ready), .tarr_resp(core_tarr_resp),
    .tarr_write_valid(core_tarr_write_valid), .tarr_write_idx(core_tarr_write_idx),
    .tarr_write_way_en(core_tarr_write_way_en), .tarr_write_tag(core_tarr_write_tag),
    .tarr_write_ecc(core_tarr_write_ecc)
  );

  // ---------------------------------------------------------------------------
  // MBIST bore 链（8 条 childBd，对应 4 副本 × 2 TagSRAMBank），按 golden 拓扑
  // ---------------------------------------------------------------------------
  wire [8:0]  childBd_addr   [8];
  wire [8:0]  childBd_addr_rd[8];
  wire [85:0] childBd_wdata  [8];
  wire [1:0]  childBd_wmask  [8];
  wire        childBd_re     [8];
  wire        childBd_we     [8];
  wire [85:0] childBd_rdata  [8];
  wire        childBd_ack    [8];
  wire        childBd_selectedOH[8];
  wire [5:0]  childBd_array  [8];

  // sigFromSrams 旁带按组打包：8 组，每组 7 个标量
  wire [6:0] sig [8];
  assign sig[0] = {sigFromSrams_bore_cgen,   sigFromSrams_bore_ram_mcp_hold,   sigFromSrams_bore_ram_aux_ckbp,   sigFromSrams_bore_ram_aux_clk,   sigFromSrams_bore_ram_bp_clken,   sigFromSrams_bore_ram_bypass,   sigFromSrams_bore_ram_hold};
  assign sig[1] = {sigFromSrams_bore_1_cgen, sigFromSrams_bore_1_ram_mcp_hold, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_1_ram_hold};
  assign sig[2] = {sigFromSrams_bore_2_cgen, sigFromSrams_bore_2_ram_mcp_hold, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_2_ram_bp_clken, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_2_ram_hold};
  assign sig[3] = {sigFromSrams_bore_3_cgen, sigFromSrams_bore_3_ram_mcp_hold, sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_3_ram_bp_clken, sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_3_ram_hold};
  assign sig[4] = {sigFromSrams_bore_4_cgen, sigFromSrams_bore_4_ram_mcp_hold, sigFromSrams_bore_4_ram_aux_ckbp, sigFromSrams_bore_4_ram_aux_clk, sigFromSrams_bore_4_ram_bp_clken, sigFromSrams_bore_4_ram_bypass, sigFromSrams_bore_4_ram_hold};
  assign sig[5] = {sigFromSrams_bore_5_cgen, sigFromSrams_bore_5_ram_mcp_hold, sigFromSrams_bore_5_ram_aux_ckbp, sigFromSrams_bore_5_ram_aux_clk, sigFromSrams_bore_5_ram_bp_clken, sigFromSrams_bore_5_ram_bypass, sigFromSrams_bore_5_ram_hold};
  assign sig[6] = {sigFromSrams_bore_6_cgen, sigFromSrams_bore_6_ram_mcp_hold, sigFromSrams_bore_6_ram_aux_ckbp, sigFromSrams_bore_6_ram_aux_clk, sigFromSrams_bore_6_ram_bp_clken, sigFromSrams_bore_6_ram_bypass, sigFromSrams_bore_6_ram_hold};
  assign sig[7] = {sigFromSrams_bore_7_cgen, sigFromSrams_bore_7_ram_mcp_hold, sigFromSrams_bore_7_ram_aux_ckbp, sigFromSrams_bore_7_ram_aux_clk, sigFromSrams_bore_7_ram_bp_clken, sigFromSrams_bore_7_ram_bypass, sigFromSrams_bore_7_ram_hold};

  // 4 个 TagArray 副本：array_k 用 childBd[2k]/childBd[2k+1] 两条 bore 链，sig[2k]/sig[2k+1]
  for (genvar k = 0; k < READ_PORTS; k++) begin : g_tarr
    localparam int B0 = 2*k;
    localparam int B1 = 2*k+1;
    TagArray array_k (
      .clock(clock), .reset(reset),
      .io_read_ready       (core_tarr_read_ready[k]),
      .io_read_valid       (core_tarr_read_valid[k]),
      .io_read_bits_idx    (core_tarr_read_idx[k]),
      .io_resp_0           (core_tarr_resp[k][0]),
      .io_resp_1           (core_tarr_resp[k][1]),
      .io_resp_2           (core_tarr_resp[k][2]),
      .io_resp_3           (core_tarr_resp[k][3]),
      .io_write_valid      (core_tarr_write_valid[k]),
      .io_write_bits_idx   (core_tarr_write_idx[k]),
      .io_write_bits_way_en(core_tarr_write_way_en[k]),
      .io_write_bits_tag   (core_tarr_write_tag[k]),
      .io_write_bits_ecc   (core_tarr_write_ecc[k]),
      // bore 子口 0
      .boreChildrenBd_bore_addr       (childBd_addr[B0]),
      .boreChildrenBd_bore_addr_rd    (childBd_addr_rd[B0]),
      .boreChildrenBd_bore_wdata      (childBd_wdata[B0]),
      .boreChildrenBd_bore_wmask      (childBd_wmask[B0]),
      .boreChildrenBd_bore_re         (childBd_re[B0]),
      .boreChildrenBd_bore_we         (childBd_we[B0]),
      .boreChildrenBd_bore_rdata      (childBd_rdata[B0]),
      .boreChildrenBd_bore_ack        (childBd_ack[B0]),
      .boreChildrenBd_bore_selectedOH (childBd_selectedOH[B0]),
      .boreChildrenBd_bore_array      (childBd_array[B0]),
      // bore 子口 1
      .boreChildrenBd_bore_1_addr       (childBd_addr[B1]),
      .boreChildrenBd_bore_1_addr_rd    (childBd_addr_rd[B1]),
      .boreChildrenBd_bore_1_wdata      (childBd_wdata[B1]),
      .boreChildrenBd_bore_1_wmask      (childBd_wmask[B1]),
      .boreChildrenBd_bore_1_re         (childBd_re[B1]),
      .boreChildrenBd_bore_1_we         (childBd_we[B1]),
      .boreChildrenBd_bore_1_rdata      (childBd_rdata[B1]),
      .boreChildrenBd_bore_1_ack        (childBd_ack[B1]),
      .boreChildrenBd_bore_1_selectedOH (childBd_selectedOH[B1]),
      .boreChildrenBd_bore_1_array      (childBd_array[B1]),
      // SRAM 旁带（每副本 2 组）
      .sigFromSrams_bore_ram_hold     (sig[B0][0]),
      .sigFromSrams_bore_ram_bypass   (sig[B0][1]),
      .sigFromSrams_bore_ram_bp_clken (sig[B0][2]),
      .sigFromSrams_bore_ram_aux_clk  (sig[B0][3]),
      .sigFromSrams_bore_ram_aux_ckbp (sig[B0][4]),
      .sigFromSrams_bore_ram_mcp_hold (sig[B0][5]),
      .sigFromSrams_bore_cgen         (sig[B0][6]),
      .sigFromSrams_bore_1_ram_hold     (sig[B1][0]),
      .sigFromSrams_bore_1_ram_bypass   (sig[B1][1]),
      .sigFromSrams_bore_1_ram_bp_clken (sig[B1][2]),
      .sigFromSrams_bore_1_ram_aux_clk  (sig[B1][3]),
      .sigFromSrams_bore_1_ram_aux_ckbp (sig[B1][4]),
      .sigFromSrams_bore_1_ram_mcp_hold (sig[B1][5]),
      .sigFromSrams_bore_1_cgen         (sig[B1][6])
    );
  end

  // ---------------------------------------------------------------------------
  // MbistPipeDcacheTag：把顶层 bd_* 信号驱动 8 条 childBd（黑盒，结构同 golden）
  // ---------------------------------------------------------------------------
  MbistPipeDcacheTag mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array  (boreChildrenBd_bore_array),
    .mbist_all    (boreChildrenBd_bore_all),
    .mbist_req    (boreChildrenBd_bore_req),
    .mbist_ack    (boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen),
    .mbist_be     (boreChildrenBd_bore_be),
    .mbist_addr   (boreChildrenBd_bore_addr),
    .mbist_indata (boreChildrenBd_bore_indata),
    .mbist_readen (boreChildrenBd_bore_readen),
    .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_0_addr(childBd_addr[0]), .toSRAM_0_addr_rd(childBd_addr_rd[0]), .toSRAM_0_wdata(childBd_wdata[0]), .toSRAM_0_wmask(childBd_wmask[0]), .toSRAM_0_re(childBd_re[0]), .toSRAM_0_we(childBd_we[0]), .toSRAM_0_rdata(childBd_rdata[0]), .toSRAM_0_ack(childBd_ack[0]), .toSRAM_0_selectedOH(childBd_selectedOH[0]), .toSRAM_0_array(childBd_array[0]),
    .toSRAM_1_addr(childBd_addr[1]), .toSRAM_1_addr_rd(childBd_addr_rd[1]), .toSRAM_1_wdata(childBd_wdata[1]), .toSRAM_1_wmask(childBd_wmask[1]), .toSRAM_1_re(childBd_re[1]), .toSRAM_1_we(childBd_we[1]), .toSRAM_1_rdata(childBd_rdata[1]), .toSRAM_1_ack(childBd_ack[1]), .toSRAM_1_selectedOH(childBd_selectedOH[1]), .toSRAM_1_array(childBd_array[1]),
    .toSRAM_2_addr(childBd_addr[2]), .toSRAM_2_addr_rd(childBd_addr_rd[2]), .toSRAM_2_wdata(childBd_wdata[2]), .toSRAM_2_wmask(childBd_wmask[2]), .toSRAM_2_re(childBd_re[2]), .toSRAM_2_we(childBd_we[2]), .toSRAM_2_rdata(childBd_rdata[2]), .toSRAM_2_ack(childBd_ack[2]), .toSRAM_2_selectedOH(childBd_selectedOH[2]), .toSRAM_2_array(childBd_array[2]),
    .toSRAM_3_addr(childBd_addr[3]), .toSRAM_3_addr_rd(childBd_addr_rd[3]), .toSRAM_3_wdata(childBd_wdata[3]), .toSRAM_3_wmask(childBd_wmask[3]), .toSRAM_3_re(childBd_re[3]), .toSRAM_3_we(childBd_we[3]), .toSRAM_3_rdata(childBd_rdata[3]), .toSRAM_3_ack(childBd_ack[3]), .toSRAM_3_selectedOH(childBd_selectedOH[3]), .toSRAM_3_array(childBd_array[3]),
    .toSRAM_4_addr(childBd_addr[4]), .toSRAM_4_addr_rd(childBd_addr_rd[4]), .toSRAM_4_wdata(childBd_wdata[4]), .toSRAM_4_wmask(childBd_wmask[4]), .toSRAM_4_re(childBd_re[4]), .toSRAM_4_we(childBd_we[4]), .toSRAM_4_rdata(childBd_rdata[4]), .toSRAM_4_ack(childBd_ack[4]), .toSRAM_4_selectedOH(childBd_selectedOH[4]), .toSRAM_4_array(childBd_array[4]),
    .toSRAM_5_addr(childBd_addr[5]), .toSRAM_5_addr_rd(childBd_addr_rd[5]), .toSRAM_5_wdata(childBd_wdata[5]), .toSRAM_5_wmask(childBd_wmask[5]), .toSRAM_5_re(childBd_re[5]), .toSRAM_5_we(childBd_we[5]), .toSRAM_5_rdata(childBd_rdata[5]), .toSRAM_5_ack(childBd_ack[5]), .toSRAM_5_selectedOH(childBd_selectedOH[5]), .toSRAM_5_array(childBd_array[5]),
    .toSRAM_6_addr(childBd_addr[6]), .toSRAM_6_addr_rd(childBd_addr_rd[6]), .toSRAM_6_wdata(childBd_wdata[6]), .toSRAM_6_wmask(childBd_wmask[6]), .toSRAM_6_re(childBd_re[6]), .toSRAM_6_we(childBd_we[6]), .toSRAM_6_rdata(childBd_rdata[6]), .toSRAM_6_ack(childBd_ack[6]), .toSRAM_6_selectedOH(childBd_selectedOH[6]), .toSRAM_6_array(childBd_array[6]),
    .toSRAM_7_addr(childBd_addr[7]), .toSRAM_7_addr_rd(childBd_addr_rd[7]), .toSRAM_7_wdata(childBd_wdata[7]), .toSRAM_7_wmask(childBd_wmask[7]), .toSRAM_7_re(childBd_re[7]), .toSRAM_7_we(childBd_we[7]), .toSRAM_7_rdata(childBd_rdata[7]), .toSRAM_7_ack(childBd_ack[7]), .toSRAM_7_selectedOH(childBd_selectedOH[7]), .toSRAM_7_array(childBd_array[7])
  );

endmodule
