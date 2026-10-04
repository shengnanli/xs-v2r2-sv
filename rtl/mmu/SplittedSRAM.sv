// SplittedSRAM.sv —— L2TLB bitmap cache 的存储阵列：32 组 × 4 路 × 90 位，切成 2×2 = 4 块物理 SRAM
//
// 位置：L2TLB → Bitmap → BitmapCache 里的 bitmapcache（cache/mmu/BitmapCheck.scala:416，
//   `new SplittedSRAM(bitmapCacheEntry, set=32, way=4, waySplit=2, dataSplit=2, readMCP2=false)`）。
//   bitmap cache 缓存的是"每页一个权限位"的 bitmap：每项 = 一个 64 位 bitmap 字 + 它的 25 位 tag。
//   本层**没有任何寄存器、没有运算**：只把一条逻辑项切块、分给内层 SRAMTemplate_124，读回再拼回来。
//   对应 Chisel：coupledL2/utils/SplittedSRAM.scala（本实例 setSplit=1，所以没有 bank 选择与 ren_vec 寄存器）。
//
// 一条逻辑项 bitmapCacheEntry 的位布局（Chisel asUInt：先声明的字段在高位），共 90 位：
//   [89:65] tag (25)   [64:1] data (64)   [0] reservedBits (1)
//   reservedBits 由 BitmapCache 写入时恒为 1（refill() 里 `reservedBits.map(_ := true.B)`），
//   firtool 把这个常数推进了本模块 —— golden 端口上没有它，写口直接填 1'b1；读口也不把它读出来。
//
// 切块（块 (g,k) = golden 实例 array_0_<g>_<k>，MBIST/DFT 口编号 n = 2g+k）：
//   waySplit=2：way 0..1 归 g=0 组、way 2..3 归 g=1 组，每块 SRAM 一次存 2 路；
//               第 g 组用 waymask[2g+1:2g] 做自己的写掩码。
//   dataSplit=2：90 位均分成两段，k=0 管 [44:0]（低段），k=1 管 [89:45]（高段）。
//   读回：way 2g+w = {块(g,1) 第 w 路, 块(g,0) 第 w 路}，再从中取出 tag / data。
// 第 n 块的 DFT 广播口 / MBIST bore 口接 sigFromSrams_bore_<n>_* / boreChildrenBd_bore_<n>_*（n=0 无后缀）。
// golden 330 行 / 91 端口；4 个子模块 SRAMTemplate_124（已独立签核）。

module xs_SplittedSRAM_bitmap_core #(
  parameter int unsigned SET_W   = 5,    // 32 组
  parameter int unsigned TAG_W   = 25,
  parameter int unsigned DATA_W  = 64,
  parameter int unsigned BORE_AW = 6,
  parameter int unsigned BORE_DW = 90,
  parameter int unsigned BORE_MW = 2,
  parameter int unsigned BORE_YW = 6     // bore array 编号宽
)(
  input  logic                  clock,
  input  logic                  reset,
  // 读口
  input  logic                  r_valid,
  input  logic [SET_W-1:0]      r_set,
  output logic [3:0][TAG_W-1:0]  r_tag,
  output logic [3:0][DATA_W-1:0] r_data,
  // 写口
  input  logic                  w_valid,
  input  logic [SET_W-1:0]      w_set,
  input  logic [3:0][TAG_W-1:0]  w_tag,
  input  logic [3:0][DATA_W-1:0] w_data,
  input  logic [3:0]            w_waymask,
  // ---- 4 块各自的 DFT 透传（下标 = 块号 n）----
  input  logic [3:0][BORE_AW-1:0] bore_addr,
  input  logic [3:0][BORE_AW-1:0] bore_addr_rd,
  input  logic [3:0][BORE_DW-1:0] bore_wdata,
  input  logic [3:0][BORE_MW-1:0] bore_wmask,
  input  logic [3:0]              bore_re,
  input  logic [3:0]              bore_we,
  output logic [3:0][BORE_DW-1:0] bore_rdata,
  input  logic [3:0]              bore_ack,
  input  logic [3:0]              bore_selectedOH,
  input  logic [3:0][BORE_YW-1:0] bore_array,
  input  logic [3:0]              sram_ram_hold,
  input  logic [3:0]              sram_ram_bypass,
  input  logic [3:0]              sram_ram_bp_clken,
  input  logic [3:0]              sram_ram_aux_clk,
  input  logic [3:0]              sram_ram_aux_ckbp,
  input  logic [3:0]              sram_ram_mcp_hold,
  input  logic [3:0]              sram_cgen
);

  localparam int unsigned ENTRY_W = TAG_W + DATA_W + 1;   // 90（含 1 位 reservedBits）
  localparam int unsigned SLICE_W = ENTRY_W / 2;          // 45：每块 SRAM 的数据宽

  // 一条逻辑项（写入时 reservedBits 恒 1）
  typedef struct packed {
    logic [TAG_W-1:0]  tag;
    logic [DATA_W-1:0] data;
    logic              rsvd;
  } bc_entry_t;

  // ---------------------------------------------------------------------------
  // 切块：blk_w[n][w] = 第 n 块 SRAM 第 w 路（块内 2 路）的写数据；blk_r 同理为读回
  //   n = 2g + k：g = way 组（way 2g、2g+1），k = 数据段（0 低 45 位 / 1 高 45 位）
  // ---------------------------------------------------------------------------
  logic [3:0][1:0][SLICE_W-1:0] blk_w, blk_r;
  logic [3:0][1:0]              blk_waymask;

  for (genvar g = 0; g < 2; g++) begin : g_way_group
    for (genvar w = 0; w < 2; w++) begin : g_way
      bc_entry_t ent_w, ent_r;
      assign ent_w = {w_tag[2*g+w], w_data[2*g+w], 1'b1};   // reservedBits 恒 1
      assign blk_w[2*g+0][w] = ent_w[SLICE_W-1:0];
      assign blk_w[2*g+1][w] = ent_w[ENTRY_W-1:SLICE_W];
      assign ent_r = {blk_r[2*g+1][w], blk_r[2*g+0][w]};
      assign r_tag[2*g+w]  = ent_r.tag;
      assign r_data[2*g+w] = ent_r.data;
    end
    assign blk_waymask[2*g+0] = w_waymask[2*g+1:2*g];
    assign blk_waymask[2*g+1] = w_waymask[2*g+1:2*g];
  end

  // ---------------------------------------------------------------------------
  // 4 块物理 SRAM（实例名照 golden：array_0_<g>_<k>，块号 n = 2g+k）
  // ---------------------------------------------------------------------------
  SRAMTemplate_124 array_0_0_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (r_valid),
    .io_r_req_bits_setIdx           (r_set),
    .io_r_resp_data_0               (blk_r[0][0]),
    .io_r_resp_data_1               (blk_r[0][1]),
    .io_w_req_valid                 (w_valid),
    .io_w_req_bits_setIdx           (w_set),
    .io_w_req_bits_data_0           (blk_w[0][0]),
    .io_w_req_bits_data_1           (blk_w[0][1]),
    .io_w_req_bits_waymask          (blk_waymask[0]),
    .io_broadcast_ram_hold          (sram_ram_hold[0]),
    .io_broadcast_ram_bypass        (sram_ram_bypass[0]),
    .io_broadcast_ram_bp_clken      (sram_ram_bp_clken[0]),
    .io_broadcast_ram_aux_clk       (sram_ram_aux_clk[0]),
    .io_broadcast_ram_aux_ckbp      (sram_ram_aux_ckbp[0]),
    .io_broadcast_ram_mcp_hold      (sram_ram_mcp_hold[0]),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sram_cgen[0]),
    .boreChildrenBd_bore_addr       (bore_addr[0]),
    .boreChildrenBd_bore_addr_rd    (bore_addr_rd[0]),
    .boreChildrenBd_bore_wdata      (bore_wdata[0]),
    .boreChildrenBd_bore_wmask      (bore_wmask[0]),
    .boreChildrenBd_bore_re         (bore_re[0]),
    .boreChildrenBd_bore_we         (bore_we[0]),
    .boreChildrenBd_bore_rdata      (bore_rdata[0]),
    .boreChildrenBd_bore_ack        (bore_ack[0]),
    .boreChildrenBd_bore_selectedOH (bore_selectedOH[0]),
    .boreChildrenBd_bore_array      (bore_array[0])
  );

  SRAMTemplate_124 array_0_0_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (r_valid),
    .io_r_req_bits_setIdx           (r_set),
    .io_r_resp_data_0               (blk_r[1][0]),
    .io_r_resp_data_1               (blk_r[1][1]),
    .io_w_req_valid                 (w_valid),
    .io_w_req_bits_setIdx           (w_set),
    .io_w_req_bits_data_0           (blk_w[1][0]),
    .io_w_req_bits_data_1           (blk_w[1][1]),
    .io_w_req_bits_waymask          (blk_waymask[1]),
    .io_broadcast_ram_hold          (sram_ram_hold[1]),
    .io_broadcast_ram_bypass        (sram_ram_bypass[1]),
    .io_broadcast_ram_bp_clken      (sram_ram_bp_clken[1]),
    .io_broadcast_ram_aux_clk       (sram_ram_aux_clk[1]),
    .io_broadcast_ram_aux_ckbp      (sram_ram_aux_ckbp[1]),
    .io_broadcast_ram_mcp_hold      (sram_ram_mcp_hold[1]),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sram_cgen[1]),
    .boreChildrenBd_bore_addr       (bore_addr[1]),
    .boreChildrenBd_bore_addr_rd    (bore_addr_rd[1]),
    .boreChildrenBd_bore_wdata      (bore_wdata[1]),
    .boreChildrenBd_bore_wmask      (bore_wmask[1]),
    .boreChildrenBd_bore_re         (bore_re[1]),
    .boreChildrenBd_bore_we         (bore_we[1]),
    .boreChildrenBd_bore_rdata      (bore_rdata[1]),
    .boreChildrenBd_bore_ack        (bore_ack[1]),
    .boreChildrenBd_bore_selectedOH (bore_selectedOH[1]),
    .boreChildrenBd_bore_array      (bore_array[1])
  );

  SRAMTemplate_124 array_0_1_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (r_valid),
    .io_r_req_bits_setIdx           (r_set),
    .io_r_resp_data_0               (blk_r[2][0]),
    .io_r_resp_data_1               (blk_r[2][1]),
    .io_w_req_valid                 (w_valid),
    .io_w_req_bits_setIdx           (w_set),
    .io_w_req_bits_data_0           (blk_w[2][0]),
    .io_w_req_bits_data_1           (blk_w[2][1]),
    .io_w_req_bits_waymask          (blk_waymask[2]),
    .io_broadcast_ram_hold          (sram_ram_hold[2]),
    .io_broadcast_ram_bypass        (sram_ram_bypass[2]),
    .io_broadcast_ram_bp_clken      (sram_ram_bp_clken[2]),
    .io_broadcast_ram_aux_clk       (sram_ram_aux_clk[2]),
    .io_broadcast_ram_aux_ckbp      (sram_ram_aux_ckbp[2]),
    .io_broadcast_ram_mcp_hold      (sram_ram_mcp_hold[2]),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sram_cgen[2]),
    .boreChildrenBd_bore_addr       (bore_addr[2]),
    .boreChildrenBd_bore_addr_rd    (bore_addr_rd[2]),
    .boreChildrenBd_bore_wdata      (bore_wdata[2]),
    .boreChildrenBd_bore_wmask      (bore_wmask[2]),
    .boreChildrenBd_bore_re         (bore_re[2]),
    .boreChildrenBd_bore_we         (bore_we[2]),
    .boreChildrenBd_bore_rdata      (bore_rdata[2]),
    .boreChildrenBd_bore_ack        (bore_ack[2]),
    .boreChildrenBd_bore_selectedOH (bore_selectedOH[2]),
    .boreChildrenBd_bore_array      (bore_array[2])
  );

  SRAMTemplate_124 array_0_1_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (r_valid),
    .io_r_req_bits_setIdx           (r_set),
    .io_r_resp_data_0               (blk_r[3][0]),
    .io_r_resp_data_1               (blk_r[3][1]),
    .io_w_req_valid                 (w_valid),
    .io_w_req_bits_setIdx           (w_set),
    .io_w_req_bits_data_0           (blk_w[3][0]),
    .io_w_req_bits_data_1           (blk_w[3][1]),
    .io_w_req_bits_waymask          (blk_waymask[3]),
    .io_broadcast_ram_hold          (sram_ram_hold[3]),
    .io_broadcast_ram_bypass        (sram_ram_bypass[3]),
    .io_broadcast_ram_bp_clken      (sram_ram_bp_clken[3]),
    .io_broadcast_ram_aux_clk       (sram_ram_aux_clk[3]),
    .io_broadcast_ram_aux_ckbp      (sram_ram_aux_ckbp[3]),
    .io_broadcast_ram_mcp_hold      (sram_ram_mcp_hold[3]),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sram_cgen[3]),
    .boreChildrenBd_bore_addr       (bore_addr[3]),
    .boreChildrenBd_bore_addr_rd    (bore_addr_rd[3]),
    .boreChildrenBd_bore_wdata      (bore_wdata[3]),
    .boreChildrenBd_bore_wmask      (bore_wmask[3]),
    .boreChildrenBd_bore_re         (bore_re[3]),
    .boreChildrenBd_bore_we         (bore_we[3]),
    .boreChildrenBd_bore_rdata      (bore_rdata[3]),
    .boreChildrenBd_bore_ack        (bore_ack[3]),
    .boreChildrenBd_bore_selectedOH (bore_selectedOH[3]),
    .boreChildrenBd_bore_array      (bore_array[3])
  );

endmodule

module SplittedSRAM (
  input  logic         clock,
  input  logic         reset,
  input  logic         io_r_req_valid,
  input  logic [4:0]   io_r_req_bits_setIdx,
  output logic [24:0]  io_r_resp_data_0_tag,
  output logic [63:0]  io_r_resp_data_0_data,
  output logic [24:0]  io_r_resp_data_1_tag,
  output logic [63:0]  io_r_resp_data_1_data,
  output logic [24:0]  io_r_resp_data_2_tag,
  output logic [63:0]  io_r_resp_data_2_data,
  output logic [24:0]  io_r_resp_data_3_tag,
  output logic [63:0]  io_r_resp_data_3_data,
  input  logic         io_w_req_valid,
  input  logic [4:0]   io_w_req_bits_setIdx,
  input  logic [24:0]  io_w_req_bits_data_0_tag,
  input  logic [63:0]  io_w_req_bits_data_0_data,
  input  logic [24:0]  io_w_req_bits_data_1_tag,
  input  logic [63:0]  io_w_req_bits_data_1_data,
  input  logic [24:0]  io_w_req_bits_data_2_tag,
  input  logic [63:0]  io_w_req_bits_data_2_data,
  input  logic [24:0]  io_w_req_bits_data_3_tag,
  input  logic [63:0]  io_w_req_bits_data_3_data,
  input  logic [3:0]   io_w_req_bits_waymask,
  input  logic [5:0]   boreChildrenBd_bore_addr,
  input  logic [5:0]   boreChildrenBd_bore_addr_rd,
  input  logic [89:0]  boreChildrenBd_bore_wdata,
  input  logic [1:0]   boreChildrenBd_bore_wmask,
  input  logic         boreChildrenBd_bore_re,
  input  logic         boreChildrenBd_bore_we,
  output logic [89:0]  boreChildrenBd_bore_rdata,
  input  logic         boreChildrenBd_bore_ack,
  input  logic         boreChildrenBd_bore_selectedOH,
  input  logic [5:0]   boreChildrenBd_bore_array,
  input  logic [5:0]   boreChildrenBd_bore_1_addr,
  input  logic [5:0]   boreChildrenBd_bore_1_addr_rd,
  input  logic [89:0]  boreChildrenBd_bore_1_wdata,
  input  logic [1:0]   boreChildrenBd_bore_1_wmask,
  input  logic         boreChildrenBd_bore_1_re,
  input  logic         boreChildrenBd_bore_1_we,
  output logic [89:0]  boreChildrenBd_bore_1_rdata,
  input  logic         boreChildrenBd_bore_1_ack,
  input  logic         boreChildrenBd_bore_1_selectedOH,
  input  logic [5:0]   boreChildrenBd_bore_1_array,
  input  logic [5:0]   boreChildrenBd_bore_2_addr,
  input  logic [5:0]   boreChildrenBd_bore_2_addr_rd,
  input  logic [89:0]  boreChildrenBd_bore_2_wdata,
  input  logic [1:0]   boreChildrenBd_bore_2_wmask,
  input  logic         boreChildrenBd_bore_2_re,
  input  logic         boreChildrenBd_bore_2_we,
  output logic [89:0]  boreChildrenBd_bore_2_rdata,
  input  logic         boreChildrenBd_bore_2_ack,
  input  logic         boreChildrenBd_bore_2_selectedOH,
  input  logic [5:0]   boreChildrenBd_bore_2_array,
  input  logic [5:0]   boreChildrenBd_bore_3_addr,
  input  logic [5:0]   boreChildrenBd_bore_3_addr_rd,
  input  logic [89:0]  boreChildrenBd_bore_3_wdata,
  input  logic [1:0]   boreChildrenBd_bore_3_wmask,
  input  logic         boreChildrenBd_bore_3_re,
  input  logic         boreChildrenBd_bore_3_we,
  output logic [89:0]  boreChildrenBd_bore_3_rdata,
  input  logic         boreChildrenBd_bore_3_ack,
  input  logic         boreChildrenBd_bore_3_selectedOH,
  input  logic [5:0]   boreChildrenBd_bore_3_array,
  input  logic         sigFromSrams_bore_ram_hold,
  input  logic         sigFromSrams_bore_ram_bypass,
  input  logic         sigFromSrams_bore_ram_bp_clken,
  input  logic         sigFromSrams_bore_ram_aux_clk,
  input  logic         sigFromSrams_bore_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_ram_mcp_hold,
  input  logic         sigFromSrams_bore_cgen,
  input  logic         sigFromSrams_bore_1_ram_hold,
  input  logic         sigFromSrams_bore_1_ram_bypass,
  input  logic         sigFromSrams_bore_1_ram_bp_clken,
  input  logic         sigFromSrams_bore_1_ram_aux_clk,
  input  logic         sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_1_ram_mcp_hold,
  input  logic         sigFromSrams_bore_1_cgen,
  input  logic         sigFromSrams_bore_2_ram_hold,
  input  logic         sigFromSrams_bore_2_ram_bypass,
  input  logic         sigFromSrams_bore_2_ram_bp_clken,
  input  logic         sigFromSrams_bore_2_ram_aux_clk,
  input  logic         sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_2_ram_mcp_hold,
  input  logic         sigFromSrams_bore_2_cgen,
  input  logic         sigFromSrams_bore_3_ram_hold,
  input  logic         sigFromSrams_bore_3_ram_bypass,
  input  logic         sigFromSrams_bore_3_ram_bp_clken,
  input  logic         sigFromSrams_bore_3_ram_aux_clk,
  input  logic         sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_3_ram_mcp_hold,
  input  logic         sigFromSrams_bore_3_cgen
);

  // 块号 n 的 DFT 端口后缀：n=0 无后缀，其余为 _<n>
  xs_SplittedSRAM_bitmap_core u_core (
    .clock             (clock),
    .reset             (reset),
    .r_valid           (io_r_req_valid),
    .r_set             (io_r_req_bits_setIdx),
    .r_tag             ({io_r_resp_data_3_tag, io_r_resp_data_2_tag, io_r_resp_data_1_tag, io_r_resp_data_0_tag}),
    .r_data            ({io_r_resp_data_3_data, io_r_resp_data_2_data, io_r_resp_data_1_data, io_r_resp_data_0_data}),
    .w_valid           (io_w_req_valid),
    .w_set             (io_w_req_bits_setIdx),
    .w_tag             ({io_w_req_bits_data_3_tag, io_w_req_bits_data_2_tag, io_w_req_bits_data_1_tag, io_w_req_bits_data_0_tag}),
    .w_data            ({io_w_req_bits_data_3_data, io_w_req_bits_data_2_data, io_w_req_bits_data_1_data, io_w_req_bits_data_0_data}),
    .w_waymask         (io_w_req_bits_waymask),
    .bore_addr         ({boreChildrenBd_bore_3_addr, boreChildrenBd_bore_2_addr, boreChildrenBd_bore_1_addr, boreChildrenBd_bore_addr}),
    .bore_addr_rd      ({boreChildrenBd_bore_3_addr_rd, boreChildrenBd_bore_2_addr_rd, boreChildrenBd_bore_1_addr_rd, boreChildrenBd_bore_addr_rd}),
    .bore_wdata        ({boreChildrenBd_bore_3_wdata, boreChildrenBd_bore_2_wdata, boreChildrenBd_bore_1_wdata, boreChildrenBd_bore_wdata}),
    .bore_wmask        ({boreChildrenBd_bore_3_wmask, boreChildrenBd_bore_2_wmask, boreChildrenBd_bore_1_wmask, boreChildrenBd_bore_wmask}),
    .bore_re           ({boreChildrenBd_bore_3_re, boreChildrenBd_bore_2_re, boreChildrenBd_bore_1_re, boreChildrenBd_bore_re}),
    .bore_we           ({boreChildrenBd_bore_3_we, boreChildrenBd_bore_2_we, boreChildrenBd_bore_1_we, boreChildrenBd_bore_we}),
    .bore_rdata        ({boreChildrenBd_bore_3_rdata, boreChildrenBd_bore_2_rdata, boreChildrenBd_bore_1_rdata, boreChildrenBd_bore_rdata}),
    .bore_ack          ({boreChildrenBd_bore_3_ack, boreChildrenBd_bore_2_ack, boreChildrenBd_bore_1_ack, boreChildrenBd_bore_ack}),
    .bore_selectedOH   ({boreChildrenBd_bore_3_selectedOH, boreChildrenBd_bore_2_selectedOH, boreChildrenBd_bore_1_selectedOH, boreChildrenBd_bore_selectedOH}),
    .bore_array        ({boreChildrenBd_bore_3_array, boreChildrenBd_bore_2_array, boreChildrenBd_bore_1_array, boreChildrenBd_bore_array}),
    .sram_ram_hold     ({sigFromSrams_bore_3_ram_hold, sigFromSrams_bore_2_ram_hold, sigFromSrams_bore_1_ram_hold, sigFromSrams_bore_ram_hold}),
    .sram_ram_bypass   ({sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_ram_bypass}),
    .sram_ram_bp_clken ({sigFromSrams_bore_3_ram_bp_clken, sigFromSrams_bore_2_ram_bp_clken, sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_ram_bp_clken}),
    .sram_ram_aux_clk  ({sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_ram_aux_clk}),
    .sram_ram_aux_ckbp ({sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_ram_aux_ckbp}),
    .sram_ram_mcp_hold ({sigFromSrams_bore_3_ram_mcp_hold, sigFromSrams_bore_2_ram_mcp_hold, sigFromSrams_bore_1_ram_mcp_hold, sigFromSrams_bore_ram_mcp_hold}),
    .sram_cgen         ({sigFromSrams_bore_3_cgen, sigFromSrams_bore_2_cgen, sigFromSrams_bore_1_cgen, sigFromSrams_bore_cgen})
  );

endmodule
