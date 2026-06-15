// =============================================================================
// ICacheDataArray_xs —— ICacheDataArray 包装层（机械端口适配 + 黑盒例化）
// -----------------------------------------------------------------------------
// 本文件由 scripts/gen_icachedata.py 生成。职责：
//   1) 把 golden 扁平端口（io_read_*, io_readResp_*, io_write_*）拆/拼成可读核
//      xs_ICacheDataArray 的数组端口；
//   2) 例化 4 路 × 8 bank = 32 块 golden 数据 SRAM 黑盒；
//   3) 例化 4 条 golden Mbist 流水黑盒，并完成 Mbist toSRAM_n <-> SRAM 的 DFT 互联；
//   4) 透传 sigFromSrams_bore_* / boreChildrenBd_bore_* 等 DFT 信号。
//   存储体与 DFT 细节沿用 golden（不在可读重写范围内），数据阵列逻辑在 u_core 内。
// =============================================================================
module ICacheDataArray_xs(
  input          clock,
  input          reset,
  // ---- 写口（refill 一整条 cacheline）----
  input          io_write_valid,
  input  [7:0]   io_write_bits_virIdx,
  input  [511:0] io_write_bits_data,
  input  [3:0]   io_write_bits_waymask,
  input          io_write_bits_poison,
  // ---- 读口 0：携带全部译码所需信息（其余端口仅 valid + vSetIdx）----
  input          io_read_0_valid,
  input  [7:0]   io_read_0_bits_vSetIdx_0,
  input  [7:0]   io_read_0_bits_vSetIdx_1,
  input          io_read_0_bits_waymask_0_0,
  input          io_read_0_bits_waymask_0_1,
  input          io_read_0_bits_waymask_0_2,
  input          io_read_0_bits_waymask_0_3,
  input          io_read_0_bits_waymask_1_0,
  input          io_read_0_bits_waymask_1_1,
  input          io_read_0_bits_waymask_1_2,
  input          io_read_0_bits_waymask_1_3,
  input  [5:0]   io_read_0_bits_blkOffset,
  input          io_read_1_valid,
  input  [7:0]   io_read_1_bits_vSetIdx_0,
  input  [7:0]   io_read_1_bits_vSetIdx_1,
  input          io_read_2_valid,
  input  [7:0]   io_read_2_bits_vSetIdx_0,
  input  [7:0]   io_read_2_bits_vSetIdx_1,
  output         io_read_3_ready,
  input          io_read_3_valid,
  input  [7:0]   io_read_3_bits_vSetIdx_0,
  input  [7:0]   io_read_3_bits_vSetIdx_1,
  // ---- 读结果：每 bank 一组 64bit 数据 + 1bit 校验码 ----
  output [63:0]  io_readResp_datas_0,
  output [63:0]  io_readResp_datas_1,
  output [63:0]  io_readResp_datas_2,
  output [63:0]  io_readResp_datas_3,
  output [63:0]  io_readResp_datas_4,
  output [63:0]  io_readResp_datas_5,
  output [63:0]  io_readResp_datas_6,
  output [63:0]  io_readResp_datas_7,
  output         io_readResp_codes_0,
  output         io_readResp_codes_1,
  output         io_readResp_codes_2,
  output         io_readResp_codes_3,
  output         io_readResp_codes_4,
  output         io_readResp_codes_5,
  output         io_readResp_codes_6,
  output         io_readResp_codes_7,
  input  [3:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input          boreChildrenBd_bore_be,
  input  [8:0]   boreChildrenBd_bore_addr,
  input  [65:0]  boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [8:0]   boreChildrenBd_bore_addr_rd,
  output [65:0]  boreChildrenBd_bore_outdata,
  input  [4:0]   boreChildrenBd_bore_1_array,
  input          boreChildrenBd_bore_1_all,
  input          boreChildrenBd_bore_1_req,
  output         boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_writeen,
  input          boreChildrenBd_bore_1_be,
  input  [8:0]   boreChildrenBd_bore_1_addr,
  input  [65:0]  boreChildrenBd_bore_1_indata,
  input          boreChildrenBd_bore_1_readen,
  input  [8:0]   boreChildrenBd_bore_1_addr_rd,
  output [65:0]  boreChildrenBd_bore_1_outdata,
  input  [4:0]   boreChildrenBd_bore_2_array,
  input          boreChildrenBd_bore_2_all,
  input          boreChildrenBd_bore_2_req,
  output         boreChildrenBd_bore_2_ack,
  input          boreChildrenBd_bore_2_writeen,
  input          boreChildrenBd_bore_2_be,
  input  [8:0]   boreChildrenBd_bore_2_addr,
  input  [65:0]  boreChildrenBd_bore_2_indata,
  input          boreChildrenBd_bore_2_readen,
  input  [8:0]   boreChildrenBd_bore_2_addr_rd,
  output [65:0]  boreChildrenBd_bore_2_outdata,
  input  [5:0]   boreChildrenBd_bore_3_array,
  input          boreChildrenBd_bore_3_all,
  input          boreChildrenBd_bore_3_req,
  output         boreChildrenBd_bore_3_ack,
  input          boreChildrenBd_bore_3_writeen,
  input          boreChildrenBd_bore_3_be,
  input  [8:0]   boreChildrenBd_bore_3_addr,
  input  [65:0]  boreChildrenBd_bore_3_indata,
  input          boreChildrenBd_bore_3_readen,
  input  [8:0]   boreChildrenBd_bore_3_addr_rd,
  output [65:0]  boreChildrenBd_bore_3_outdata,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          sigFromSrams_bore_12_ram_hold,
  input          sigFromSrams_bore_12_ram_bypass,
  input          sigFromSrams_bore_12_ram_bp_clken,
  input          sigFromSrams_bore_12_ram_aux_clk,
  input          sigFromSrams_bore_12_ram_aux_ckbp,
  input          sigFromSrams_bore_12_ram_mcp_hold,
  input          sigFromSrams_bore_12_cgen,
  input          sigFromSrams_bore_13_ram_hold,
  input          sigFromSrams_bore_13_ram_bypass,
  input          sigFromSrams_bore_13_ram_bp_clken,
  input          sigFromSrams_bore_13_ram_aux_clk,
  input          sigFromSrams_bore_13_ram_aux_ckbp,
  input          sigFromSrams_bore_13_ram_mcp_hold,
  input          sigFromSrams_bore_13_cgen,
  input          sigFromSrams_bore_14_ram_hold,
  input          sigFromSrams_bore_14_ram_bypass,
  input          sigFromSrams_bore_14_ram_bp_clken,
  input          sigFromSrams_bore_14_ram_aux_clk,
  input          sigFromSrams_bore_14_ram_aux_ckbp,
  input          sigFromSrams_bore_14_ram_mcp_hold,
  input          sigFromSrams_bore_14_cgen,
  input          sigFromSrams_bore_15_ram_hold,
  input          sigFromSrams_bore_15_ram_bypass,
  input          sigFromSrams_bore_15_ram_bp_clken,
  input          sigFromSrams_bore_15_ram_aux_clk,
  input          sigFromSrams_bore_15_ram_aux_ckbp,
  input          sigFromSrams_bore_15_ram_mcp_hold,
  input          sigFromSrams_bore_15_cgen,
  input          sigFromSrams_bore_16_ram_hold,
  input          sigFromSrams_bore_16_ram_bypass,
  input          sigFromSrams_bore_16_ram_bp_clken,
  input          sigFromSrams_bore_16_ram_aux_clk,
  input          sigFromSrams_bore_16_ram_aux_ckbp,
  input          sigFromSrams_bore_16_ram_mcp_hold,
  input          sigFromSrams_bore_16_cgen,
  input          sigFromSrams_bore_17_ram_hold,
  input          sigFromSrams_bore_17_ram_bypass,
  input          sigFromSrams_bore_17_ram_bp_clken,
  input          sigFromSrams_bore_17_ram_aux_clk,
  input          sigFromSrams_bore_17_ram_aux_ckbp,
  input          sigFromSrams_bore_17_ram_mcp_hold,
  input          sigFromSrams_bore_17_cgen,
  input          sigFromSrams_bore_18_ram_hold,
  input          sigFromSrams_bore_18_ram_bypass,
  input          sigFromSrams_bore_18_ram_bp_clken,
  input          sigFromSrams_bore_18_ram_aux_clk,
  input          sigFromSrams_bore_18_ram_aux_ckbp,
  input          sigFromSrams_bore_18_ram_mcp_hold,
  input          sigFromSrams_bore_18_cgen,
  input          sigFromSrams_bore_19_ram_hold,
  input          sigFromSrams_bore_19_ram_bypass,
  input          sigFromSrams_bore_19_ram_bp_clken,
  input          sigFromSrams_bore_19_ram_aux_clk,
  input          sigFromSrams_bore_19_ram_aux_ckbp,
  input          sigFromSrams_bore_19_ram_mcp_hold,
  input          sigFromSrams_bore_19_cgen,
  input          sigFromSrams_bore_20_ram_hold,
  input          sigFromSrams_bore_20_ram_bypass,
  input          sigFromSrams_bore_20_ram_bp_clken,
  input          sigFromSrams_bore_20_ram_aux_clk,
  input          sigFromSrams_bore_20_ram_aux_ckbp,
  input          sigFromSrams_bore_20_ram_mcp_hold,
  input          sigFromSrams_bore_20_cgen,
  input          sigFromSrams_bore_21_ram_hold,
  input          sigFromSrams_bore_21_ram_bypass,
  input          sigFromSrams_bore_21_ram_bp_clken,
  input          sigFromSrams_bore_21_ram_aux_clk,
  input          sigFromSrams_bore_21_ram_aux_ckbp,
  input          sigFromSrams_bore_21_ram_mcp_hold,
  input          sigFromSrams_bore_21_cgen,
  input          sigFromSrams_bore_22_ram_hold,
  input          sigFromSrams_bore_22_ram_bypass,
  input          sigFromSrams_bore_22_ram_bp_clken,
  input          sigFromSrams_bore_22_ram_aux_clk,
  input          sigFromSrams_bore_22_ram_aux_ckbp,
  input          sigFromSrams_bore_22_ram_mcp_hold,
  input          sigFromSrams_bore_22_cgen,
  input          sigFromSrams_bore_23_ram_hold,
  input          sigFromSrams_bore_23_ram_bypass,
  input          sigFromSrams_bore_23_ram_bp_clken,
  input          sigFromSrams_bore_23_ram_aux_clk,
  input          sigFromSrams_bore_23_ram_aux_ckbp,
  input          sigFromSrams_bore_23_ram_mcp_hold,
  input          sigFromSrams_bore_23_cgen,
  input          sigFromSrams_bore_24_ram_hold,
  input          sigFromSrams_bore_24_ram_bypass,
  input          sigFromSrams_bore_24_ram_bp_clken,
  input          sigFromSrams_bore_24_ram_aux_clk,
  input          sigFromSrams_bore_24_ram_aux_ckbp,
  input          sigFromSrams_bore_24_ram_mcp_hold,
  input          sigFromSrams_bore_24_cgen,
  input          sigFromSrams_bore_25_ram_hold,
  input          sigFromSrams_bore_25_ram_bypass,
  input          sigFromSrams_bore_25_ram_bp_clken,
  input          sigFromSrams_bore_25_ram_aux_clk,
  input          sigFromSrams_bore_25_ram_aux_ckbp,
  input          sigFromSrams_bore_25_ram_mcp_hold,
  input          sigFromSrams_bore_25_cgen,
  input          sigFromSrams_bore_26_ram_hold,
  input          sigFromSrams_bore_26_ram_bypass,
  input          sigFromSrams_bore_26_ram_bp_clken,
  input          sigFromSrams_bore_26_ram_aux_clk,
  input          sigFromSrams_bore_26_ram_aux_ckbp,
  input          sigFromSrams_bore_26_ram_mcp_hold,
  input          sigFromSrams_bore_26_cgen,
  input          sigFromSrams_bore_27_ram_hold,
  input          sigFromSrams_bore_27_ram_bypass,
  input          sigFromSrams_bore_27_ram_bp_clken,
  input          sigFromSrams_bore_27_ram_aux_clk,
  input          sigFromSrams_bore_27_ram_aux_ckbp,
  input          sigFromSrams_bore_27_ram_mcp_hold,
  input          sigFromSrams_bore_27_cgen,
  input          sigFromSrams_bore_28_ram_hold,
  input          sigFromSrams_bore_28_ram_bypass,
  input          sigFromSrams_bore_28_ram_bp_clken,
  input          sigFromSrams_bore_28_ram_aux_clk,
  input          sigFromSrams_bore_28_ram_aux_ckbp,
  input          sigFromSrams_bore_28_ram_mcp_hold,
  input          sigFromSrams_bore_28_cgen,
  input          sigFromSrams_bore_29_ram_hold,
  input          sigFromSrams_bore_29_ram_bypass,
  input          sigFromSrams_bore_29_ram_bp_clken,
  input          sigFromSrams_bore_29_ram_aux_clk,
  input          sigFromSrams_bore_29_ram_aux_ckbp,
  input          sigFromSrams_bore_29_ram_mcp_hold,
  input          sigFromSrams_bore_29_cgen,
  input          sigFromSrams_bore_30_ram_hold,
  input          sigFromSrams_bore_30_ram_bypass,
  input          sigFromSrams_bore_30_ram_bp_clken,
  input          sigFromSrams_bore_30_ram_aux_clk,
  input          sigFromSrams_bore_30_ram_aux_ckbp,
  input          sigFromSrams_bore_30_ram_mcp_hold,
  input          sigFromSrams_bore_30_cgen,
  input          sigFromSrams_bore_31_ram_hold,
  input          sigFromSrams_bore_31_ram_bypass,
  input          sigFromSrams_bore_31_ram_bp_clken,
  input          sigFromSrams_bore_31_ram_aux_clk,
  input          sigFromSrams_bore_31_ram_aux_ckbp,
  input          sigFromSrams_bore_31_ram_mcp_hold,
  input          sigFromSrams_bore_31_cgen
);

  // -------------------------------------------------------------------------
  // 把扁平 read/write 端口聚合成可读核的数组端口
  // -------------------------------------------------------------------------
  logic                 read_valid   [7:0];
  logic [7:0]           read_vSetIdx [7:0][1:0];
  logic [3:0]           read_waymask [1:0];
  logic [63:0]          resp_datas   [7:0];
  logic                 resp_codes   [7:0];

  // 仅读端口 0..3 有效，按 golden 接到 4 个外部读请求
  assign read_valid[0] = io_read_0_valid;
  assign read_valid[1] = io_read_1_valid;
  assign read_valid[2] = io_read_2_valid;
  assign read_valid[3] = io_read_3_valid;
  assign read_valid[4] = 1'b0;
  assign read_valid[5] = 1'b0;
  assign read_valid[6] = 1'b0;
  assign read_valid[7] = 1'b0;

  // 两条行各自的组索引（[port][line]）
  assign read_vSetIdx[0][0] = io_read_0_bits_vSetIdx_0;
  assign read_vSetIdx[0][1] = io_read_0_bits_vSetIdx_1;
  assign read_vSetIdx[1][0] = io_read_1_bits_vSetIdx_0;
  assign read_vSetIdx[1][1] = io_read_1_bits_vSetIdx_1;
  assign read_vSetIdx[2][0] = io_read_2_bits_vSetIdx_0;
  assign read_vSetIdx[2][1] = io_read_2_bits_vSetIdx_1;
  assign read_vSetIdx[3][0] = io_read_3_bits_vSetIdx_0;
  assign read_vSetIdx[3][1] = io_read_3_bits_vSetIdx_1;
  assign read_vSetIdx[4][0] = 8'b0;
  assign read_vSetIdx[4][1] = 8'b0;
  assign read_vSetIdx[5][0] = 8'b0;
  assign read_vSetIdx[5][1] = 8'b0;
  assign read_vSetIdx[6][0] = 8'b0;
  assign read_vSetIdx[6][1] = 8'b0;
  assign read_vSetIdx[7][0] = 8'b0;
  assign read_vSetIdx[7][1] = 8'b0;

  // 命中掩码 [line][way]，全部取自读端口 0
  assign read_waymask[0] = {io_read_0_bits_waymask_0_3, io_read_0_bits_waymask_0_2,
                            io_read_0_bits_waymask_0_1, io_read_0_bits_waymask_0_0};
  assign read_waymask[1] = {io_read_0_bits_waymask_1_3, io_read_0_bits_waymask_1_2,
                            io_read_0_bits_waymask_1_1, io_read_0_bits_waymask_1_0};

  // 可读核 <-> SRAM 黑盒之间的读写端口数组
  logic        sram_r_valid  [3:0][7:0];
  logic [7:0]  sram_r_setIdx [3:0][7:0];
  logic [64:0] sram_r_data   [3:0][7:0];
  logic        sram_w_valid  [3:0][7:0];
  logic [7:0]  sram_w_setIdx [3:0][7:0];
  logic [64:0] sram_w_data   [3:0][7:0];

  // -------------------------------------------------------------------------
  // 可读核：数据阵列全部逻辑（bankSel/lineSel/masks/Mux1H/ECC 编码/写切分）
  // -------------------------------------------------------------------------
  xs_ICacheDataArray u_core (
    .clock          (clock),
    .reset          (reset),
    .write_valid    (io_write_valid),
    .write_virIdx   (io_write_bits_virIdx),
    .write_data     (io_write_bits_data),
    .write_waymask  (io_write_bits_waymask),
    .write_poison   (io_write_bits_poison),
    .read_valid     (read_valid),
    .read_vSetIdx   (read_vSetIdx),
    .read_waymask   (read_waymask),
    .read_blkOffset (io_read_0_bits_blkOffset),
    .read_ready     (io_read_3_ready),
    .resp_datas     (resp_datas),
    .resp_codes     (resp_codes),
    .sram_r_valid   (sram_r_valid),
    .sram_r_setIdx  (sram_r_setIdx),
    .sram_r_data    (sram_r_data),
    .sram_w_valid   (sram_w_valid),
    .sram_w_setIdx  (sram_w_setIdx),
    .sram_w_data    (sram_w_data)
  );

  // 读结果回拼到扁平输出端口
  assign io_readResp_datas_0 = resp_datas[0];
  assign io_readResp_datas_1 = resp_datas[1];
  assign io_readResp_datas_2 = resp_datas[2];
  assign io_readResp_datas_3 = resp_datas[3];
  assign io_readResp_datas_4 = resp_datas[4];
  assign io_readResp_datas_5 = resp_datas[5];
  assign io_readResp_datas_6 = resp_datas[6];
  assign io_readResp_datas_7 = resp_datas[7];
  assign io_readResp_codes_0 = resp_codes[0];
  assign io_readResp_codes_1 = resp_codes[1];
  assign io_readResp_codes_2 = resp_codes[2];
  assign io_readResp_codes_3 = resp_codes[3];
  assign io_readResp_codes_4 = resp_codes[4];
  assign io_readResp_codes_5 = resp_codes[5];
  assign io_readResp_codes_6 = resp_codes[6];
  assign io_readResp_codes_7 = resp_codes[7];

  // -------------------------------------------------------------------------
  // Mbist <-> SRAM DFT 互联网（childBd_<k>，k = way*8 + bank）
  // -------------------------------------------------------------------------
  wire [8:0]  childBd_addr;
  wire [8:0]  childBd_addr_rd;
  wire [65:0] childBd_wdata;
  wire        childBd_wmask;
  wire        childBd_re;
  wire        childBd_we;
  wire [65:0] childBd_rdata;
  wire        childBd_ack;
  wire        childBd_selectedOH;
  wire [2:0]  childBd_array;
  wire [8:0]  childBd_1_addr;
  wire [8:0]  childBd_1_addr_rd;
  wire [65:0] childBd_1_wdata;
  wire        childBd_1_wmask;
  wire        childBd_1_re;
  wire        childBd_1_we;
  wire [65:0] childBd_1_rdata;
  wire        childBd_1_ack;
  wire        childBd_1_selectedOH;
  wire [2:0]  childBd_1_array;
  wire [8:0]  childBd_2_addr;
  wire [8:0]  childBd_2_addr_rd;
  wire [65:0] childBd_2_wdata;
  wire        childBd_2_wmask;
  wire        childBd_2_re;
  wire        childBd_2_we;
  wire [65:0] childBd_2_rdata;
  wire        childBd_2_ack;
  wire        childBd_2_selectedOH;
  wire [2:0]  childBd_2_array;
  wire [8:0]  childBd_3_addr;
  wire [8:0]  childBd_3_addr_rd;
  wire [65:0] childBd_3_wdata;
  wire        childBd_3_wmask;
  wire        childBd_3_re;
  wire        childBd_3_we;
  wire [65:0] childBd_3_rdata;
  wire        childBd_3_ack;
  wire        childBd_3_selectedOH;
  wire [2:0]  childBd_3_array;
  wire [8:0]  childBd_4_addr;
  wire [8:0]  childBd_4_addr_rd;
  wire [65:0] childBd_4_wdata;
  wire        childBd_4_wmask;
  wire        childBd_4_re;
  wire        childBd_4_we;
  wire [65:0] childBd_4_rdata;
  wire        childBd_4_ack;
  wire        childBd_4_selectedOH;
  wire [3:0]  childBd_4_array;
  wire [8:0]  childBd_5_addr;
  wire [8:0]  childBd_5_addr_rd;
  wire [65:0] childBd_5_wdata;
  wire        childBd_5_wmask;
  wire        childBd_5_re;
  wire        childBd_5_we;
  wire [65:0] childBd_5_rdata;
  wire        childBd_5_ack;
  wire        childBd_5_selectedOH;
  wire [3:0]  childBd_5_array;
  wire [8:0]  childBd_6_addr;
  wire [8:0]  childBd_6_addr_rd;
  wire [65:0] childBd_6_wdata;
  wire        childBd_6_wmask;
  wire        childBd_6_re;
  wire        childBd_6_we;
  wire [65:0] childBd_6_rdata;
  wire        childBd_6_ack;
  wire        childBd_6_selectedOH;
  wire [3:0]  childBd_6_array;
  wire [8:0]  childBd_7_addr;
  wire [8:0]  childBd_7_addr_rd;
  wire [65:0] childBd_7_wdata;
  wire        childBd_7_wmask;
  wire        childBd_7_re;
  wire        childBd_7_we;
  wire [65:0] childBd_7_rdata;
  wire        childBd_7_ack;
  wire        childBd_7_selectedOH;
  wire [3:0]  childBd_7_array;
  wire [8:0]  childBd_8_addr;
  wire [8:0]  childBd_8_addr_rd;
  wire [65:0] childBd_8_wdata;
  wire        childBd_8_wmask;
  wire        childBd_8_re;
  wire        childBd_8_we;
  wire [65:0] childBd_8_rdata;
  wire        childBd_8_ack;
  wire        childBd_8_selectedOH;
  wire [3:0]  childBd_8_array;
  wire [8:0]  childBd_9_addr;
  wire [8:0]  childBd_9_addr_rd;
  wire [65:0] childBd_9_wdata;
  wire        childBd_9_wmask;
  wire        childBd_9_re;
  wire        childBd_9_we;
  wire [65:0] childBd_9_rdata;
  wire        childBd_9_ack;
  wire        childBd_9_selectedOH;
  wire [3:0]  childBd_9_array;
  wire [8:0]  childBd_10_addr;
  wire [8:0]  childBd_10_addr_rd;
  wire [65:0] childBd_10_wdata;
  wire        childBd_10_wmask;
  wire        childBd_10_re;
  wire        childBd_10_we;
  wire [65:0] childBd_10_rdata;
  wire        childBd_10_ack;
  wire        childBd_10_selectedOH;
  wire [3:0]  childBd_10_array;
  wire [8:0]  childBd_11_addr;
  wire [8:0]  childBd_11_addr_rd;
  wire [65:0] childBd_11_wdata;
  wire        childBd_11_wmask;
  wire        childBd_11_re;
  wire        childBd_11_we;
  wire [65:0] childBd_11_rdata;
  wire        childBd_11_ack;
  wire        childBd_11_selectedOH;
  wire [3:0]  childBd_11_array;
  wire [8:0]  childBd_12_addr;
  wire [8:0]  childBd_12_addr_rd;
  wire [65:0] childBd_12_wdata;
  wire        childBd_12_wmask;
  wire        childBd_12_re;
  wire        childBd_12_we;
  wire [65:0] childBd_12_rdata;
  wire        childBd_12_ack;
  wire        childBd_12_selectedOH;
  wire [4:0]  childBd_12_array;
  wire [8:0]  childBd_13_addr;
  wire [8:0]  childBd_13_addr_rd;
  wire [65:0] childBd_13_wdata;
  wire        childBd_13_wmask;
  wire        childBd_13_re;
  wire        childBd_13_we;
  wire [65:0] childBd_13_rdata;
  wire        childBd_13_ack;
  wire        childBd_13_selectedOH;
  wire [4:0]  childBd_13_array;
  wire [8:0]  childBd_14_addr;
  wire [8:0]  childBd_14_addr_rd;
  wire [65:0] childBd_14_wdata;
  wire        childBd_14_wmask;
  wire        childBd_14_re;
  wire        childBd_14_we;
  wire [65:0] childBd_14_rdata;
  wire        childBd_14_ack;
  wire        childBd_14_selectedOH;
  wire [4:0]  childBd_14_array;
  wire [8:0]  childBd_15_addr;
  wire [8:0]  childBd_15_addr_rd;
  wire [65:0] childBd_15_wdata;
  wire        childBd_15_wmask;
  wire        childBd_15_re;
  wire        childBd_15_we;
  wire [65:0] childBd_15_rdata;
  wire        childBd_15_ack;
  wire        childBd_15_selectedOH;
  wire [4:0]  childBd_15_array;
  wire [8:0]  childBd_16_addr;
  wire [8:0]  childBd_16_addr_rd;
  wire [65:0] childBd_16_wdata;
  wire        childBd_16_wmask;
  wire        childBd_16_re;
  wire        childBd_16_we;
  wire [65:0] childBd_16_rdata;
  wire        childBd_16_ack;
  wire        childBd_16_selectedOH;
  wire [4:0]  childBd_16_array;
  wire [8:0]  childBd_17_addr;
  wire [8:0]  childBd_17_addr_rd;
  wire [65:0] childBd_17_wdata;
  wire        childBd_17_wmask;
  wire        childBd_17_re;
  wire        childBd_17_we;
  wire [65:0] childBd_17_rdata;
  wire        childBd_17_ack;
  wire        childBd_17_selectedOH;
  wire [4:0]  childBd_17_array;
  wire [8:0]  childBd_18_addr;
  wire [8:0]  childBd_18_addr_rd;
  wire [65:0] childBd_18_wdata;
  wire        childBd_18_wmask;
  wire        childBd_18_re;
  wire        childBd_18_we;
  wire [65:0] childBd_18_rdata;
  wire        childBd_18_ack;
  wire        childBd_18_selectedOH;
  wire [4:0]  childBd_18_array;
  wire [8:0]  childBd_19_addr;
  wire [8:0]  childBd_19_addr_rd;
  wire [65:0] childBd_19_wdata;
  wire        childBd_19_wmask;
  wire        childBd_19_re;
  wire        childBd_19_we;
  wire [65:0] childBd_19_rdata;
  wire        childBd_19_ack;
  wire        childBd_19_selectedOH;
  wire [4:0]  childBd_19_array;
  wire [8:0]  childBd_20_addr;
  wire [8:0]  childBd_20_addr_rd;
  wire [65:0] childBd_20_wdata;
  wire        childBd_20_wmask;
  wire        childBd_20_re;
  wire        childBd_20_we;
  wire [65:0] childBd_20_rdata;
  wire        childBd_20_ack;
  wire        childBd_20_selectedOH;
  wire [4:0]  childBd_20_array;
  wire [8:0]  childBd_21_addr;
  wire [8:0]  childBd_21_addr_rd;
  wire [65:0] childBd_21_wdata;
  wire        childBd_21_wmask;
  wire        childBd_21_re;
  wire        childBd_21_we;
  wire [65:0] childBd_21_rdata;
  wire        childBd_21_ack;
  wire        childBd_21_selectedOH;
  wire [4:0]  childBd_21_array;
  wire [8:0]  childBd_22_addr;
  wire [8:0]  childBd_22_addr_rd;
  wire [65:0] childBd_22_wdata;
  wire        childBd_22_wmask;
  wire        childBd_22_re;
  wire        childBd_22_we;
  wire [65:0] childBd_22_rdata;
  wire        childBd_22_ack;
  wire        childBd_22_selectedOH;
  wire [4:0]  childBd_22_array;
  wire [8:0]  childBd_23_addr;
  wire [8:0]  childBd_23_addr_rd;
  wire [65:0] childBd_23_wdata;
  wire        childBd_23_wmask;
  wire        childBd_23_re;
  wire        childBd_23_we;
  wire [65:0] childBd_23_rdata;
  wire        childBd_23_ack;
  wire        childBd_23_selectedOH;
  wire [4:0]  childBd_23_array;
  wire [8:0]  childBd_24_addr;
  wire [8:0]  childBd_24_addr_rd;
  wire [65:0] childBd_24_wdata;
  wire        childBd_24_wmask;
  wire        childBd_24_re;
  wire        childBd_24_we;
  wire [65:0] childBd_24_rdata;
  wire        childBd_24_ack;
  wire        childBd_24_selectedOH;
  wire [4:0]  childBd_24_array;
  wire [8:0]  childBd_25_addr;
  wire [8:0]  childBd_25_addr_rd;
  wire [65:0] childBd_25_wdata;
  wire        childBd_25_wmask;
  wire        childBd_25_re;
  wire        childBd_25_we;
  wire [65:0] childBd_25_rdata;
  wire        childBd_25_ack;
  wire        childBd_25_selectedOH;
  wire [4:0]  childBd_25_array;
  wire [8:0]  childBd_26_addr;
  wire [8:0]  childBd_26_addr_rd;
  wire [65:0] childBd_26_wdata;
  wire        childBd_26_wmask;
  wire        childBd_26_re;
  wire        childBd_26_we;
  wire [65:0] childBd_26_rdata;
  wire        childBd_26_ack;
  wire        childBd_26_selectedOH;
  wire [4:0]  childBd_26_array;
  wire [8:0]  childBd_27_addr;
  wire [8:0]  childBd_27_addr_rd;
  wire [65:0] childBd_27_wdata;
  wire        childBd_27_wmask;
  wire        childBd_27_re;
  wire        childBd_27_we;
  wire [65:0] childBd_27_rdata;
  wire        childBd_27_ack;
  wire        childBd_27_selectedOH;
  wire [4:0]  childBd_27_array;
  wire [8:0]  childBd_28_addr;
  wire [8:0]  childBd_28_addr_rd;
  wire [65:0] childBd_28_wdata;
  wire        childBd_28_wmask;
  wire        childBd_28_re;
  wire        childBd_28_we;
  wire [65:0] childBd_28_rdata;
  wire        childBd_28_ack;
  wire        childBd_28_selectedOH;
  wire [5:0]  childBd_28_array;
  wire [8:0]  childBd_29_addr;
  wire [8:0]  childBd_29_addr_rd;
  wire [65:0] childBd_29_wdata;
  wire        childBd_29_wmask;
  wire        childBd_29_re;
  wire        childBd_29_we;
  wire [65:0] childBd_29_rdata;
  wire        childBd_29_ack;
  wire        childBd_29_selectedOH;
  wire [5:0]  childBd_29_array;
  wire [8:0]  childBd_30_addr;
  wire [8:0]  childBd_30_addr_rd;
  wire [65:0] childBd_30_wdata;
  wire        childBd_30_wmask;
  wire        childBd_30_re;
  wire        childBd_30_we;
  wire [65:0] childBd_30_rdata;
  wire        childBd_30_ack;
  wire        childBd_30_selectedOH;
  wire [5:0]  childBd_30_array;
  wire [8:0]  childBd_31_addr;
  wire [8:0]  childBd_31_addr_rd;
  wire [65:0] childBd_31_wdata;
  wire        childBd_31_wmask;
  wire        childBd_31_re;
  wire        childBd_31_we;
  wire [65:0] childBd_31_rdata;
  wire        childBd_31_ack;
  wire        childBd_31_selectedOH;
  wire [5:0]  childBd_31_array;

  // -------------------------------------------------------------------------
  // 32 块数据 SRAM 黑盒（golden 同名）
  // -------------------------------------------------------------------------
  SRAMTemplateWithFixedWidth dataArrays_0_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][0]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][0]),
    .io_r_resp_data_0               (sram_r_data[0][0]),
    .io_w_req_valid                 (sram_w_valid[0][0]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][0]),
    .io_w_req_bits_data_0           (sram_w_data[0][0]),
    .boreChildrenBd_bore_addr       (childBd_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_wdata),
    .boreChildrenBd_bore_wmask      (childBd_wmask),
    .boreChildrenBd_bore_re         (childBd_re),
    .boreChildrenBd_bore_we         (childBd_we),
    .boreChildrenBd_bore_rdata      (childBd_rdata),
    .boreChildrenBd_bore_ack        (childBd_ack),
    .boreChildrenBd_bore_selectedOH (childBd_selectedOH),
    .boreChildrenBd_bore_array      (childBd_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_cgen)
  );
  SRAMTemplateWithFixedWidth dataArrays_0_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][1]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][1]),
    .io_r_resp_data_0               (sram_r_data[0][1]),
    .io_w_req_valid                 (sram_w_valid[0][1]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][1]),
    .io_w_req_bits_data_0           (sram_w_data[0][1]),
    .boreChildrenBd_bore_addr       (childBd_1_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_1_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_1_wdata),
    .boreChildrenBd_bore_wmask      (childBd_1_wmask),
    .boreChildrenBd_bore_re         (childBd_1_re),
    .boreChildrenBd_bore_we         (childBd_1_we),
    .boreChildrenBd_bore_rdata      (childBd_1_rdata),
    .boreChildrenBd_bore_ack        (childBd_1_ack),
    .boreChildrenBd_bore_selectedOH (childBd_1_selectedOH),
    .boreChildrenBd_bore_array      (childBd_1_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_1_cgen)
  );
  SRAMTemplateWithFixedWidth dataArrays_0_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][2]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][2]),
    .io_r_resp_data_0               (sram_r_data[0][2]),
    .io_w_req_valid                 (sram_w_valid[0][2]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][2]),
    .io_w_req_bits_data_0           (sram_w_data[0][2]),
    .boreChildrenBd_bore_addr       (childBd_2_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_2_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_2_wdata),
    .boreChildrenBd_bore_wmask      (childBd_2_wmask),
    .boreChildrenBd_bore_re         (childBd_2_re),
    .boreChildrenBd_bore_we         (childBd_2_we),
    .boreChildrenBd_bore_rdata      (childBd_2_rdata),
    .boreChildrenBd_bore_ack        (childBd_2_ack),
    .boreChildrenBd_bore_selectedOH (childBd_2_selectedOH),
    .boreChildrenBd_bore_array      (childBd_2_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_2_cgen)
  );
  SRAMTemplateWithFixedWidth dataArrays_0_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][3]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][3]),
    .io_r_resp_data_0               (sram_r_data[0][3]),
    .io_w_req_valid                 (sram_w_valid[0][3]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][3]),
    .io_w_req_bits_data_0           (sram_w_data[0][3]),
    .boreChildrenBd_bore_addr       (childBd_3_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_3_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_3_wdata),
    .boreChildrenBd_bore_wmask      (childBd_3_wmask),
    .boreChildrenBd_bore_re         (childBd_3_re),
    .boreChildrenBd_bore_we         (childBd_3_we),
    .boreChildrenBd_bore_rdata      (childBd_3_rdata),
    .boreChildrenBd_bore_ack        (childBd_3_ack),
    .boreChildrenBd_bore_selectedOH (childBd_3_selectedOH),
    .boreChildrenBd_bore_array      (childBd_3_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_3_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_0_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][4]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][4]),
    .io_r_resp_data_0               (sram_r_data[0][4]),
    .io_w_req_valid                 (sram_w_valid[0][4]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][4]),
    .io_w_req_bits_data_0           (sram_w_data[0][4]),
    .boreChildrenBd_bore_addr       (childBd_4_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_4_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_4_wdata),
    .boreChildrenBd_bore_wmask      (childBd_4_wmask),
    .boreChildrenBd_bore_re         (childBd_4_re),
    .boreChildrenBd_bore_we         (childBd_4_we),
    .boreChildrenBd_bore_rdata      (childBd_4_rdata),
    .boreChildrenBd_bore_ack        (childBd_4_ack),
    .boreChildrenBd_bore_selectedOH (childBd_4_selectedOH),
    .boreChildrenBd_bore_array      (childBd_4_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_4_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_0_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][5]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][5]),
    .io_r_resp_data_0               (sram_r_data[0][5]),
    .io_w_req_valid                 (sram_w_valid[0][5]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][5]),
    .io_w_req_bits_data_0           (sram_w_data[0][5]),
    .boreChildrenBd_bore_addr       (childBd_5_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_5_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_5_wdata),
    .boreChildrenBd_bore_wmask      (childBd_5_wmask),
    .boreChildrenBd_bore_re         (childBd_5_re),
    .boreChildrenBd_bore_we         (childBd_5_we),
    .boreChildrenBd_bore_rdata      (childBd_5_rdata),
    .boreChildrenBd_bore_ack        (childBd_5_ack),
    .boreChildrenBd_bore_selectedOH (childBd_5_selectedOH),
    .boreChildrenBd_bore_array      (childBd_5_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_5_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_0_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][6]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][6]),
    .io_r_resp_data_0               (sram_r_data[0][6]),
    .io_w_req_valid                 (sram_w_valid[0][6]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][6]),
    .io_w_req_bits_data_0           (sram_w_data[0][6]),
    .boreChildrenBd_bore_addr       (childBd_6_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_6_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_6_wdata),
    .boreChildrenBd_bore_wmask      (childBd_6_wmask),
    .boreChildrenBd_bore_re         (childBd_6_re),
    .boreChildrenBd_bore_we         (childBd_6_we),
    .boreChildrenBd_bore_rdata      (childBd_6_rdata),
    .boreChildrenBd_bore_ack        (childBd_6_ack),
    .boreChildrenBd_bore_selectedOH (childBd_6_selectedOH),
    .boreChildrenBd_bore_array      (childBd_6_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_6_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_0_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[0][7]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[0][7]),
    .io_r_resp_data_0               (sram_r_data[0][7]),
    .io_w_req_valid                 (sram_w_valid[0][7]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[0][7]),
    .io_w_req_bits_data_0           (sram_w_data[0][7]),
    .boreChildrenBd_bore_addr       (childBd_7_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_7_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_7_wdata),
    .boreChildrenBd_bore_wmask      (childBd_7_wmask),
    .boreChildrenBd_bore_re         (childBd_7_re),
    .boreChildrenBd_bore_we         (childBd_7_we),
    .boreChildrenBd_bore_rdata      (childBd_7_rdata),
    .boreChildrenBd_bore_ack        (childBd_7_ack),
    .boreChildrenBd_bore_selectedOH (childBd_7_selectedOH),
    .boreChildrenBd_bore_array      (childBd_7_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_7_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_1_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][0]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][0]),
    .io_r_resp_data_0               (sram_r_data[1][0]),
    .io_w_req_valid                 (sram_w_valid[1][0]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][0]),
    .io_w_req_bits_data_0           (sram_w_data[1][0]),
    .boreChildrenBd_bore_addr       (childBd_8_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_8_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_8_wdata),
    .boreChildrenBd_bore_wmask      (childBd_8_wmask),
    .boreChildrenBd_bore_re         (childBd_8_re),
    .boreChildrenBd_bore_we         (childBd_8_we),
    .boreChildrenBd_bore_rdata      (childBd_8_rdata),
    .boreChildrenBd_bore_ack        (childBd_8_ack),
    .boreChildrenBd_bore_selectedOH (childBd_8_selectedOH),
    .boreChildrenBd_bore_array      (childBd_8_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_8_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_1_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][1]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][1]),
    .io_r_resp_data_0               (sram_r_data[1][1]),
    .io_w_req_valid                 (sram_w_valid[1][1]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][1]),
    .io_w_req_bits_data_0           (sram_w_data[1][1]),
    .boreChildrenBd_bore_addr       (childBd_9_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_9_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_9_wdata),
    .boreChildrenBd_bore_wmask      (childBd_9_wmask),
    .boreChildrenBd_bore_re         (childBd_9_re),
    .boreChildrenBd_bore_we         (childBd_9_we),
    .boreChildrenBd_bore_rdata      (childBd_9_rdata),
    .boreChildrenBd_bore_ack        (childBd_9_ack),
    .boreChildrenBd_bore_selectedOH (childBd_9_selectedOH),
    .boreChildrenBd_bore_array      (childBd_9_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_9_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_1_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][2]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][2]),
    .io_r_resp_data_0               (sram_r_data[1][2]),
    .io_w_req_valid                 (sram_w_valid[1][2]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][2]),
    .io_w_req_bits_data_0           (sram_w_data[1][2]),
    .boreChildrenBd_bore_addr       (childBd_10_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_10_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_10_wdata),
    .boreChildrenBd_bore_wmask      (childBd_10_wmask),
    .boreChildrenBd_bore_re         (childBd_10_re),
    .boreChildrenBd_bore_we         (childBd_10_we),
    .boreChildrenBd_bore_rdata      (childBd_10_rdata),
    .boreChildrenBd_bore_ack        (childBd_10_ack),
    .boreChildrenBd_bore_selectedOH (childBd_10_selectedOH),
    .boreChildrenBd_bore_array      (childBd_10_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_10_cgen)
  );
  SRAMTemplateWithFixedWidth_4 dataArrays_1_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][3]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][3]),
    .io_r_resp_data_0               (sram_r_data[1][3]),
    .io_w_req_valid                 (sram_w_valid[1][3]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][3]),
    .io_w_req_bits_data_0           (sram_w_data[1][3]),
    .boreChildrenBd_bore_addr       (childBd_11_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_11_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_11_wdata),
    .boreChildrenBd_bore_wmask      (childBd_11_wmask),
    .boreChildrenBd_bore_re         (childBd_11_re),
    .boreChildrenBd_bore_we         (childBd_11_we),
    .boreChildrenBd_bore_rdata      (childBd_11_rdata),
    .boreChildrenBd_bore_ack        (childBd_11_ack),
    .boreChildrenBd_bore_selectedOH (childBd_11_selectedOH),
    .boreChildrenBd_bore_array      (childBd_11_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_11_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_1_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][4]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][4]),
    .io_r_resp_data_0               (sram_r_data[1][4]),
    .io_w_req_valid                 (sram_w_valid[1][4]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][4]),
    .io_w_req_bits_data_0           (sram_w_data[1][4]),
    .boreChildrenBd_bore_addr       (childBd_12_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_12_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_12_wdata),
    .boreChildrenBd_bore_wmask      (childBd_12_wmask),
    .boreChildrenBd_bore_re         (childBd_12_re),
    .boreChildrenBd_bore_we         (childBd_12_we),
    .boreChildrenBd_bore_rdata      (childBd_12_rdata),
    .boreChildrenBd_bore_ack        (childBd_12_ack),
    .boreChildrenBd_bore_selectedOH (childBd_12_selectedOH),
    .boreChildrenBd_bore_array      (childBd_12_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_12_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_1_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][5]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][5]),
    .io_r_resp_data_0               (sram_r_data[1][5]),
    .io_w_req_valid                 (sram_w_valid[1][5]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][5]),
    .io_w_req_bits_data_0           (sram_w_data[1][5]),
    .boreChildrenBd_bore_addr       (childBd_13_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_13_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_13_wdata),
    .boreChildrenBd_bore_wmask      (childBd_13_wmask),
    .boreChildrenBd_bore_re         (childBd_13_re),
    .boreChildrenBd_bore_we         (childBd_13_we),
    .boreChildrenBd_bore_rdata      (childBd_13_rdata),
    .boreChildrenBd_bore_ack        (childBd_13_ack),
    .boreChildrenBd_bore_selectedOH (childBd_13_selectedOH),
    .boreChildrenBd_bore_array      (childBd_13_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_13_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_1_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][6]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][6]),
    .io_r_resp_data_0               (sram_r_data[1][6]),
    .io_w_req_valid                 (sram_w_valid[1][6]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][6]),
    .io_w_req_bits_data_0           (sram_w_data[1][6]),
    .boreChildrenBd_bore_addr       (childBd_14_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_14_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_14_wdata),
    .boreChildrenBd_bore_wmask      (childBd_14_wmask),
    .boreChildrenBd_bore_re         (childBd_14_re),
    .boreChildrenBd_bore_we         (childBd_14_we),
    .boreChildrenBd_bore_rdata      (childBd_14_rdata),
    .boreChildrenBd_bore_ack        (childBd_14_ack),
    .boreChildrenBd_bore_selectedOH (childBd_14_selectedOH),
    .boreChildrenBd_bore_array      (childBd_14_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_14_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_1_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[1][7]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[1][7]),
    .io_r_resp_data_0               (sram_r_data[1][7]),
    .io_w_req_valid                 (sram_w_valid[1][7]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[1][7]),
    .io_w_req_bits_data_0           (sram_w_data[1][7]),
    .boreChildrenBd_bore_addr       (childBd_15_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_15_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_15_wdata),
    .boreChildrenBd_bore_wmask      (childBd_15_wmask),
    .boreChildrenBd_bore_re         (childBd_15_re),
    .boreChildrenBd_bore_we         (childBd_15_we),
    .boreChildrenBd_bore_rdata      (childBd_15_rdata),
    .boreChildrenBd_bore_ack        (childBd_15_ack),
    .boreChildrenBd_bore_selectedOH (childBd_15_selectedOH),
    .boreChildrenBd_bore_array      (childBd_15_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_15_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][0]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][0]),
    .io_r_resp_data_0               (sram_r_data[2][0]),
    .io_w_req_valid                 (sram_w_valid[2][0]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][0]),
    .io_w_req_bits_data_0           (sram_w_data[2][0]),
    .boreChildrenBd_bore_addr       (childBd_16_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_16_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_16_wdata),
    .boreChildrenBd_bore_wmask      (childBd_16_wmask),
    .boreChildrenBd_bore_re         (childBd_16_re),
    .boreChildrenBd_bore_we         (childBd_16_we),
    .boreChildrenBd_bore_rdata      (childBd_16_rdata),
    .boreChildrenBd_bore_ack        (childBd_16_ack),
    .boreChildrenBd_bore_selectedOH (childBd_16_selectedOH),
    .boreChildrenBd_bore_array      (childBd_16_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_16_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][1]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][1]),
    .io_r_resp_data_0               (sram_r_data[2][1]),
    .io_w_req_valid                 (sram_w_valid[2][1]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][1]),
    .io_w_req_bits_data_0           (sram_w_data[2][1]),
    .boreChildrenBd_bore_addr       (childBd_17_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_17_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_17_wdata),
    .boreChildrenBd_bore_wmask      (childBd_17_wmask),
    .boreChildrenBd_bore_re         (childBd_17_re),
    .boreChildrenBd_bore_we         (childBd_17_we),
    .boreChildrenBd_bore_rdata      (childBd_17_rdata),
    .boreChildrenBd_bore_ack        (childBd_17_ack),
    .boreChildrenBd_bore_selectedOH (childBd_17_selectedOH),
    .boreChildrenBd_bore_array      (childBd_17_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_17_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][2]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][2]),
    .io_r_resp_data_0               (sram_r_data[2][2]),
    .io_w_req_valid                 (sram_w_valid[2][2]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][2]),
    .io_w_req_bits_data_0           (sram_w_data[2][2]),
    .boreChildrenBd_bore_addr       (childBd_18_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_18_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_18_wdata),
    .boreChildrenBd_bore_wmask      (childBd_18_wmask),
    .boreChildrenBd_bore_re         (childBd_18_re),
    .boreChildrenBd_bore_we         (childBd_18_we),
    .boreChildrenBd_bore_rdata      (childBd_18_rdata),
    .boreChildrenBd_bore_ack        (childBd_18_ack),
    .boreChildrenBd_bore_selectedOH (childBd_18_selectedOH),
    .boreChildrenBd_bore_array      (childBd_18_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_18_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][3]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][3]),
    .io_r_resp_data_0               (sram_r_data[2][3]),
    .io_w_req_valid                 (sram_w_valid[2][3]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][3]),
    .io_w_req_bits_data_0           (sram_w_data[2][3]),
    .boreChildrenBd_bore_addr       (childBd_19_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_19_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_19_wdata),
    .boreChildrenBd_bore_wmask      (childBd_19_wmask),
    .boreChildrenBd_bore_re         (childBd_19_re),
    .boreChildrenBd_bore_we         (childBd_19_we),
    .boreChildrenBd_bore_rdata      (childBd_19_rdata),
    .boreChildrenBd_bore_ack        (childBd_19_ack),
    .boreChildrenBd_bore_selectedOH (childBd_19_selectedOH),
    .boreChildrenBd_bore_array      (childBd_19_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_19_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][4]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][4]),
    .io_r_resp_data_0               (sram_r_data[2][4]),
    .io_w_req_valid                 (sram_w_valid[2][4]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][4]),
    .io_w_req_bits_data_0           (sram_w_data[2][4]),
    .boreChildrenBd_bore_addr       (childBd_20_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_20_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_20_wdata),
    .boreChildrenBd_bore_wmask      (childBd_20_wmask),
    .boreChildrenBd_bore_re         (childBd_20_re),
    .boreChildrenBd_bore_we         (childBd_20_we),
    .boreChildrenBd_bore_rdata      (childBd_20_rdata),
    .boreChildrenBd_bore_ack        (childBd_20_ack),
    .boreChildrenBd_bore_selectedOH (childBd_20_selectedOH),
    .boreChildrenBd_bore_array      (childBd_20_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_20_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][5]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][5]),
    .io_r_resp_data_0               (sram_r_data[2][5]),
    .io_w_req_valid                 (sram_w_valid[2][5]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][5]),
    .io_w_req_bits_data_0           (sram_w_data[2][5]),
    .boreChildrenBd_bore_addr       (childBd_21_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_21_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_21_wdata),
    .boreChildrenBd_bore_wmask      (childBd_21_wmask),
    .boreChildrenBd_bore_re         (childBd_21_re),
    .boreChildrenBd_bore_we         (childBd_21_we),
    .boreChildrenBd_bore_rdata      (childBd_21_rdata),
    .boreChildrenBd_bore_ack        (childBd_21_ack),
    .boreChildrenBd_bore_selectedOH (childBd_21_selectedOH),
    .boreChildrenBd_bore_array      (childBd_21_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_21_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][6]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][6]),
    .io_r_resp_data_0               (sram_r_data[2][6]),
    .io_w_req_valid                 (sram_w_valid[2][6]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][6]),
    .io_w_req_bits_data_0           (sram_w_data[2][6]),
    .boreChildrenBd_bore_addr       (childBd_22_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_22_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_22_wdata),
    .boreChildrenBd_bore_wmask      (childBd_22_wmask),
    .boreChildrenBd_bore_re         (childBd_22_re),
    .boreChildrenBd_bore_we         (childBd_22_we),
    .boreChildrenBd_bore_rdata      (childBd_22_rdata),
    .boreChildrenBd_bore_ack        (childBd_22_ack),
    .boreChildrenBd_bore_selectedOH (childBd_22_selectedOH),
    .boreChildrenBd_bore_array      (childBd_22_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_22_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_2_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[2][7]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[2][7]),
    .io_r_resp_data_0               (sram_r_data[2][7]),
    .io_w_req_valid                 (sram_w_valid[2][7]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[2][7]),
    .io_w_req_bits_data_0           (sram_w_data[2][7]),
    .boreChildrenBd_bore_addr       (childBd_23_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_23_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_23_wdata),
    .boreChildrenBd_bore_wmask      (childBd_23_wmask),
    .boreChildrenBd_bore_re         (childBd_23_re),
    .boreChildrenBd_bore_we         (childBd_23_we),
    .boreChildrenBd_bore_rdata      (childBd_23_rdata),
    .boreChildrenBd_bore_ack        (childBd_23_ack),
    .boreChildrenBd_bore_selectedOH (childBd_23_selectedOH),
    .boreChildrenBd_bore_array      (childBd_23_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_23_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_3_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][0]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][0]),
    .io_r_resp_data_0               (sram_r_data[3][0]),
    .io_w_req_valid                 (sram_w_valid[3][0]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][0]),
    .io_w_req_bits_data_0           (sram_w_data[3][0]),
    .boreChildrenBd_bore_addr       (childBd_24_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_24_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_24_wdata),
    .boreChildrenBd_bore_wmask      (childBd_24_wmask),
    .boreChildrenBd_bore_re         (childBd_24_re),
    .boreChildrenBd_bore_we         (childBd_24_we),
    .boreChildrenBd_bore_rdata      (childBd_24_rdata),
    .boreChildrenBd_bore_ack        (childBd_24_ack),
    .boreChildrenBd_bore_selectedOH (childBd_24_selectedOH),
    .boreChildrenBd_bore_array      (childBd_24_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_24_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_3_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][1]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][1]),
    .io_r_resp_data_0               (sram_r_data[3][1]),
    .io_w_req_valid                 (sram_w_valid[3][1]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][1]),
    .io_w_req_bits_data_0           (sram_w_data[3][1]),
    .boreChildrenBd_bore_addr       (childBd_25_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_25_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_25_wdata),
    .boreChildrenBd_bore_wmask      (childBd_25_wmask),
    .boreChildrenBd_bore_re         (childBd_25_re),
    .boreChildrenBd_bore_we         (childBd_25_we),
    .boreChildrenBd_bore_rdata      (childBd_25_rdata),
    .boreChildrenBd_bore_ack        (childBd_25_ack),
    .boreChildrenBd_bore_selectedOH (childBd_25_selectedOH),
    .boreChildrenBd_bore_array      (childBd_25_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_25_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_3_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][2]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][2]),
    .io_r_resp_data_0               (sram_r_data[3][2]),
    .io_w_req_valid                 (sram_w_valid[3][2]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][2]),
    .io_w_req_bits_data_0           (sram_w_data[3][2]),
    .boreChildrenBd_bore_addr       (childBd_26_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_26_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_26_wdata),
    .boreChildrenBd_bore_wmask      (childBd_26_wmask),
    .boreChildrenBd_bore_re         (childBd_26_re),
    .boreChildrenBd_bore_we         (childBd_26_we),
    .boreChildrenBd_bore_rdata      (childBd_26_rdata),
    .boreChildrenBd_bore_ack        (childBd_26_ack),
    .boreChildrenBd_bore_selectedOH (childBd_26_selectedOH),
    .boreChildrenBd_bore_array      (childBd_26_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_26_cgen)
  );
  SRAMTemplateWithFixedWidth_12 dataArrays_3_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][3]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][3]),
    .io_r_resp_data_0               (sram_r_data[3][3]),
    .io_w_req_valid                 (sram_w_valid[3][3]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][3]),
    .io_w_req_bits_data_0           (sram_w_data[3][3]),
    .boreChildrenBd_bore_addr       (childBd_27_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_27_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_27_wdata),
    .boreChildrenBd_bore_wmask      (childBd_27_wmask),
    .boreChildrenBd_bore_re         (childBd_27_re),
    .boreChildrenBd_bore_we         (childBd_27_we),
    .boreChildrenBd_bore_rdata      (childBd_27_rdata),
    .boreChildrenBd_bore_ack        (childBd_27_ack),
    .boreChildrenBd_bore_selectedOH (childBd_27_selectedOH),
    .boreChildrenBd_bore_array      (childBd_27_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_27_cgen)
  );
  SRAMTemplateWithFixedWidth_28 dataArrays_3_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][4]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][4]),
    .io_r_resp_data_0               (sram_r_data[3][4]),
    .io_w_req_valid                 (sram_w_valid[3][4]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][4]),
    .io_w_req_bits_data_0           (sram_w_data[3][4]),
    .boreChildrenBd_bore_addr       (childBd_28_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_28_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_28_wdata),
    .boreChildrenBd_bore_wmask      (childBd_28_wmask),
    .boreChildrenBd_bore_re         (childBd_28_re),
    .boreChildrenBd_bore_we         (childBd_28_we),
    .boreChildrenBd_bore_rdata      (childBd_28_rdata),
    .boreChildrenBd_bore_ack        (childBd_28_ack),
    .boreChildrenBd_bore_selectedOH (childBd_28_selectedOH),
    .boreChildrenBd_bore_array      (childBd_28_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_28_cgen)
  );
  SRAMTemplateWithFixedWidth_28 dataArrays_3_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][5]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][5]),
    .io_r_resp_data_0               (sram_r_data[3][5]),
    .io_w_req_valid                 (sram_w_valid[3][5]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][5]),
    .io_w_req_bits_data_0           (sram_w_data[3][5]),
    .boreChildrenBd_bore_addr       (childBd_29_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_29_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_29_wdata),
    .boreChildrenBd_bore_wmask      (childBd_29_wmask),
    .boreChildrenBd_bore_re         (childBd_29_re),
    .boreChildrenBd_bore_we         (childBd_29_we),
    .boreChildrenBd_bore_rdata      (childBd_29_rdata),
    .boreChildrenBd_bore_ack        (childBd_29_ack),
    .boreChildrenBd_bore_selectedOH (childBd_29_selectedOH),
    .boreChildrenBd_bore_array      (childBd_29_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_29_cgen)
  );
  SRAMTemplateWithFixedWidth_28 dataArrays_3_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][6]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][6]),
    .io_r_resp_data_0               (sram_r_data[3][6]),
    .io_w_req_valid                 (sram_w_valid[3][6]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][6]),
    .io_w_req_bits_data_0           (sram_w_data[3][6]),
    .boreChildrenBd_bore_addr       (childBd_30_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_30_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_30_wdata),
    .boreChildrenBd_bore_wmask      (childBd_30_wmask),
    .boreChildrenBd_bore_re         (childBd_30_re),
    .boreChildrenBd_bore_we         (childBd_30_we),
    .boreChildrenBd_bore_rdata      (childBd_30_rdata),
    .boreChildrenBd_bore_ack        (childBd_30_ack),
    .boreChildrenBd_bore_selectedOH (childBd_30_selectedOH),
    .boreChildrenBd_bore_array      (childBd_30_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_30_cgen)
  );
  SRAMTemplateWithFixedWidth_28 dataArrays_3_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (sram_r_valid[3][7]),
    .io_r_req_bits_setIdx           (sram_r_setIdx[3][7]),
    .io_r_resp_data_0               (sram_r_data[3][7]),
    .io_w_req_valid                 (sram_w_valid[3][7]),
    .io_w_req_bits_setIdx           (sram_w_setIdx[3][7]),
    .io_w_req_bits_data_0           (sram_w_data[3][7]),
    .boreChildrenBd_bore_addr       (childBd_31_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_31_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_31_wdata),
    .boreChildrenBd_bore_wmask      (childBd_31_wmask),
    .boreChildrenBd_bore_re         (childBd_31_re),
    .boreChildrenBd_bore_we         (childBd_31_we),
    .boreChildrenBd_bore_rdata      (childBd_31_rdata),
    .boreChildrenBd_bore_ack        (childBd_31_ack),
    .boreChildrenBd_bore_selectedOH (childBd_31_selectedOH),
    .boreChildrenBd_bore_array      (childBd_31_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_31_cgen)
  );

  // -------------------------------------------------------------------------
  // 4 条 Mbist 流水黑盒（golden 同名），每 way 一条，其 toSRAM_n 接本 way 的 8 个 bank
  // -------------------------------------------------------------------------
  MbistPipeIcacheDataWay0 res (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array),
    .toSRAM_1_addr       (childBd_1_addr),
    .toSRAM_1_addr_rd    (childBd_1_addr_rd),
    .toSRAM_1_wdata      (childBd_1_wdata),
    .toSRAM_1_wmask      (childBd_1_wmask),
    .toSRAM_1_re         (childBd_1_re),
    .toSRAM_1_we         (childBd_1_we),
    .toSRAM_1_rdata      (childBd_1_rdata),
    .toSRAM_1_ack        (childBd_1_ack),
    .toSRAM_1_selectedOH (childBd_1_selectedOH),
    .toSRAM_1_array      (childBd_1_array),
    .toSRAM_2_addr       (childBd_2_addr),
    .toSRAM_2_addr_rd    (childBd_2_addr_rd),
    .toSRAM_2_wdata      (childBd_2_wdata),
    .toSRAM_2_wmask      (childBd_2_wmask),
    .toSRAM_2_re         (childBd_2_re),
    .toSRAM_2_we         (childBd_2_we),
    .toSRAM_2_rdata      (childBd_2_rdata),
    .toSRAM_2_ack        (childBd_2_ack),
    .toSRAM_2_selectedOH (childBd_2_selectedOH),
    .toSRAM_2_array      (childBd_2_array),
    .toSRAM_3_addr       (childBd_3_addr),
    .toSRAM_3_addr_rd    (childBd_3_addr_rd),
    .toSRAM_3_wdata      (childBd_3_wdata),
    .toSRAM_3_wmask      (childBd_3_wmask),
    .toSRAM_3_re         (childBd_3_re),
    .toSRAM_3_we         (childBd_3_we),
    .toSRAM_3_rdata      (childBd_3_rdata),
    .toSRAM_3_ack        (childBd_3_ack),
    .toSRAM_3_selectedOH (childBd_3_selectedOH),
    .toSRAM_3_array      (childBd_3_array),
    .toSRAM_4_addr       (childBd_4_addr),
    .toSRAM_4_addr_rd    (childBd_4_addr_rd),
    .toSRAM_4_wdata      (childBd_4_wdata),
    .toSRAM_4_wmask      (childBd_4_wmask),
    .toSRAM_4_re         (childBd_4_re),
    .toSRAM_4_we         (childBd_4_we),
    .toSRAM_4_rdata      (childBd_4_rdata),
    .toSRAM_4_ack        (childBd_4_ack),
    .toSRAM_4_selectedOH (childBd_4_selectedOH),
    .toSRAM_4_array      (childBd_4_array),
    .toSRAM_5_addr       (childBd_5_addr),
    .toSRAM_5_addr_rd    (childBd_5_addr_rd),
    .toSRAM_5_wdata      (childBd_5_wdata),
    .toSRAM_5_wmask      (childBd_5_wmask),
    .toSRAM_5_re         (childBd_5_re),
    .toSRAM_5_we         (childBd_5_we),
    .toSRAM_5_rdata      (childBd_5_rdata),
    .toSRAM_5_ack        (childBd_5_ack),
    .toSRAM_5_selectedOH (childBd_5_selectedOH),
    .toSRAM_5_array      (childBd_5_array),
    .toSRAM_6_addr       (childBd_6_addr),
    .toSRAM_6_addr_rd    (childBd_6_addr_rd),
    .toSRAM_6_wdata      (childBd_6_wdata),
    .toSRAM_6_wmask      (childBd_6_wmask),
    .toSRAM_6_re         (childBd_6_re),
    .toSRAM_6_we         (childBd_6_we),
    .toSRAM_6_rdata      (childBd_6_rdata),
    .toSRAM_6_ack        (childBd_6_ack),
    .toSRAM_6_selectedOH (childBd_6_selectedOH),
    .toSRAM_6_array      (childBd_6_array),
    .toSRAM_7_addr       (childBd_7_addr),
    .toSRAM_7_addr_rd    (childBd_7_addr_rd),
    .toSRAM_7_wdata      (childBd_7_wdata),
    .toSRAM_7_wmask      (childBd_7_wmask),
    .toSRAM_7_re         (childBd_7_re),
    .toSRAM_7_we         (childBd_7_we),
    .toSRAM_7_rdata      (childBd_7_rdata),
    .toSRAM_7_ack        (childBd_7_ack),
    .toSRAM_7_selectedOH (childBd_7_selectedOH),
    .toSRAM_7_array      (childBd_7_array)
  );
  MbistPipeIcacheDataWay1 res_1 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_1_array),
    .mbist_all           (boreChildrenBd_bore_1_all),
    .mbist_req           (boreChildrenBd_bore_1_req),
    .mbist_ack           (boreChildrenBd_bore_1_ack),
    .mbist_writeen       (boreChildrenBd_bore_1_writeen),
    .mbist_be            (boreChildrenBd_bore_1_be),
    .mbist_addr          (boreChildrenBd_bore_1_addr),
    .mbist_indata        (boreChildrenBd_bore_1_indata),
    .mbist_readen        (boreChildrenBd_bore_1_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_1_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_1_outdata),
    .toSRAM_0_addr       (childBd_8_addr),
    .toSRAM_0_addr_rd    (childBd_8_addr_rd),
    .toSRAM_0_wdata      (childBd_8_wdata),
    .toSRAM_0_wmask      (childBd_8_wmask),
    .toSRAM_0_re         (childBd_8_re),
    .toSRAM_0_we         (childBd_8_we),
    .toSRAM_0_rdata      (childBd_8_rdata),
    .toSRAM_0_ack        (childBd_8_ack),
    .toSRAM_0_selectedOH (childBd_8_selectedOH),
    .toSRAM_0_array      (childBd_8_array),
    .toSRAM_1_addr       (childBd_9_addr),
    .toSRAM_1_addr_rd    (childBd_9_addr_rd),
    .toSRAM_1_wdata      (childBd_9_wdata),
    .toSRAM_1_wmask      (childBd_9_wmask),
    .toSRAM_1_re         (childBd_9_re),
    .toSRAM_1_we         (childBd_9_we),
    .toSRAM_1_rdata      (childBd_9_rdata),
    .toSRAM_1_ack        (childBd_9_ack),
    .toSRAM_1_selectedOH (childBd_9_selectedOH),
    .toSRAM_1_array      (childBd_9_array),
    .toSRAM_2_addr       (childBd_10_addr),
    .toSRAM_2_addr_rd    (childBd_10_addr_rd),
    .toSRAM_2_wdata      (childBd_10_wdata),
    .toSRAM_2_wmask      (childBd_10_wmask),
    .toSRAM_2_re         (childBd_10_re),
    .toSRAM_2_we         (childBd_10_we),
    .toSRAM_2_rdata      (childBd_10_rdata),
    .toSRAM_2_ack        (childBd_10_ack),
    .toSRAM_2_selectedOH (childBd_10_selectedOH),
    .toSRAM_2_array      (childBd_10_array),
    .toSRAM_3_addr       (childBd_11_addr),
    .toSRAM_3_addr_rd    (childBd_11_addr_rd),
    .toSRAM_3_wdata      (childBd_11_wdata),
    .toSRAM_3_wmask      (childBd_11_wmask),
    .toSRAM_3_re         (childBd_11_re),
    .toSRAM_3_we         (childBd_11_we),
    .toSRAM_3_rdata      (childBd_11_rdata),
    .toSRAM_3_ack        (childBd_11_ack),
    .toSRAM_3_selectedOH (childBd_11_selectedOH),
    .toSRAM_3_array      (childBd_11_array),
    .toSRAM_4_addr       (childBd_12_addr),
    .toSRAM_4_addr_rd    (childBd_12_addr_rd),
    .toSRAM_4_wdata      (childBd_12_wdata),
    .toSRAM_4_wmask      (childBd_12_wmask),
    .toSRAM_4_re         (childBd_12_re),
    .toSRAM_4_we         (childBd_12_we),
    .toSRAM_4_rdata      (childBd_12_rdata),
    .toSRAM_4_ack        (childBd_12_ack),
    .toSRAM_4_selectedOH (childBd_12_selectedOH),
    .toSRAM_4_array      (childBd_12_array),
    .toSRAM_5_addr       (childBd_13_addr),
    .toSRAM_5_addr_rd    (childBd_13_addr_rd),
    .toSRAM_5_wdata      (childBd_13_wdata),
    .toSRAM_5_wmask      (childBd_13_wmask),
    .toSRAM_5_re         (childBd_13_re),
    .toSRAM_5_we         (childBd_13_we),
    .toSRAM_5_rdata      (childBd_13_rdata),
    .toSRAM_5_ack        (childBd_13_ack),
    .toSRAM_5_selectedOH (childBd_13_selectedOH),
    .toSRAM_5_array      (childBd_13_array),
    .toSRAM_6_addr       (childBd_14_addr),
    .toSRAM_6_addr_rd    (childBd_14_addr_rd),
    .toSRAM_6_wdata      (childBd_14_wdata),
    .toSRAM_6_wmask      (childBd_14_wmask),
    .toSRAM_6_re         (childBd_14_re),
    .toSRAM_6_we         (childBd_14_we),
    .toSRAM_6_rdata      (childBd_14_rdata),
    .toSRAM_6_ack        (childBd_14_ack),
    .toSRAM_6_selectedOH (childBd_14_selectedOH),
    .toSRAM_6_array      (childBd_14_array),
    .toSRAM_7_addr       (childBd_15_addr),
    .toSRAM_7_addr_rd    (childBd_15_addr_rd),
    .toSRAM_7_wdata      (childBd_15_wdata),
    .toSRAM_7_wmask      (childBd_15_wmask),
    .toSRAM_7_re         (childBd_15_re),
    .toSRAM_7_we         (childBd_15_we),
    .toSRAM_7_rdata      (childBd_15_rdata),
    .toSRAM_7_ack        (childBd_15_ack),
    .toSRAM_7_selectedOH (childBd_15_selectedOH),
    .toSRAM_7_array      (childBd_15_array)
  );
  MbistPipeIcacheDataWay2 res_2 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_2_array),
    .mbist_all           (boreChildrenBd_bore_2_all),
    .mbist_req           (boreChildrenBd_bore_2_req),
    .mbist_ack           (boreChildrenBd_bore_2_ack),
    .mbist_writeen       (boreChildrenBd_bore_2_writeen),
    .mbist_be            (boreChildrenBd_bore_2_be),
    .mbist_addr          (boreChildrenBd_bore_2_addr),
    .mbist_indata        (boreChildrenBd_bore_2_indata),
    .mbist_readen        (boreChildrenBd_bore_2_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_2_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_2_outdata),
    .toSRAM_0_addr       (childBd_16_addr),
    .toSRAM_0_addr_rd    (childBd_16_addr_rd),
    .toSRAM_0_wdata      (childBd_16_wdata),
    .toSRAM_0_wmask      (childBd_16_wmask),
    .toSRAM_0_re         (childBd_16_re),
    .toSRAM_0_we         (childBd_16_we),
    .toSRAM_0_rdata      (childBd_16_rdata),
    .toSRAM_0_ack        (childBd_16_ack),
    .toSRAM_0_selectedOH (childBd_16_selectedOH),
    .toSRAM_0_array      (childBd_16_array),
    .toSRAM_1_addr       (childBd_17_addr),
    .toSRAM_1_addr_rd    (childBd_17_addr_rd),
    .toSRAM_1_wdata      (childBd_17_wdata),
    .toSRAM_1_wmask      (childBd_17_wmask),
    .toSRAM_1_re         (childBd_17_re),
    .toSRAM_1_we         (childBd_17_we),
    .toSRAM_1_rdata      (childBd_17_rdata),
    .toSRAM_1_ack        (childBd_17_ack),
    .toSRAM_1_selectedOH (childBd_17_selectedOH),
    .toSRAM_1_array      (childBd_17_array),
    .toSRAM_2_addr       (childBd_18_addr),
    .toSRAM_2_addr_rd    (childBd_18_addr_rd),
    .toSRAM_2_wdata      (childBd_18_wdata),
    .toSRAM_2_wmask      (childBd_18_wmask),
    .toSRAM_2_re         (childBd_18_re),
    .toSRAM_2_we         (childBd_18_we),
    .toSRAM_2_rdata      (childBd_18_rdata),
    .toSRAM_2_ack        (childBd_18_ack),
    .toSRAM_2_selectedOH (childBd_18_selectedOH),
    .toSRAM_2_array      (childBd_18_array),
    .toSRAM_3_addr       (childBd_19_addr),
    .toSRAM_3_addr_rd    (childBd_19_addr_rd),
    .toSRAM_3_wdata      (childBd_19_wdata),
    .toSRAM_3_wmask      (childBd_19_wmask),
    .toSRAM_3_re         (childBd_19_re),
    .toSRAM_3_we         (childBd_19_we),
    .toSRAM_3_rdata      (childBd_19_rdata),
    .toSRAM_3_ack        (childBd_19_ack),
    .toSRAM_3_selectedOH (childBd_19_selectedOH),
    .toSRAM_3_array      (childBd_19_array),
    .toSRAM_4_addr       (childBd_20_addr),
    .toSRAM_4_addr_rd    (childBd_20_addr_rd),
    .toSRAM_4_wdata      (childBd_20_wdata),
    .toSRAM_4_wmask      (childBd_20_wmask),
    .toSRAM_4_re         (childBd_20_re),
    .toSRAM_4_we         (childBd_20_we),
    .toSRAM_4_rdata      (childBd_20_rdata),
    .toSRAM_4_ack        (childBd_20_ack),
    .toSRAM_4_selectedOH (childBd_20_selectedOH),
    .toSRAM_4_array      (childBd_20_array),
    .toSRAM_5_addr       (childBd_21_addr),
    .toSRAM_5_addr_rd    (childBd_21_addr_rd),
    .toSRAM_5_wdata      (childBd_21_wdata),
    .toSRAM_5_wmask      (childBd_21_wmask),
    .toSRAM_5_re         (childBd_21_re),
    .toSRAM_5_we         (childBd_21_we),
    .toSRAM_5_rdata      (childBd_21_rdata),
    .toSRAM_5_ack        (childBd_21_ack),
    .toSRAM_5_selectedOH (childBd_21_selectedOH),
    .toSRAM_5_array      (childBd_21_array),
    .toSRAM_6_addr       (childBd_22_addr),
    .toSRAM_6_addr_rd    (childBd_22_addr_rd),
    .toSRAM_6_wdata      (childBd_22_wdata),
    .toSRAM_6_wmask      (childBd_22_wmask),
    .toSRAM_6_re         (childBd_22_re),
    .toSRAM_6_we         (childBd_22_we),
    .toSRAM_6_rdata      (childBd_22_rdata),
    .toSRAM_6_ack        (childBd_22_ack),
    .toSRAM_6_selectedOH (childBd_22_selectedOH),
    .toSRAM_6_array      (childBd_22_array),
    .toSRAM_7_addr       (childBd_23_addr),
    .toSRAM_7_addr_rd    (childBd_23_addr_rd),
    .toSRAM_7_wdata      (childBd_23_wdata),
    .toSRAM_7_wmask      (childBd_23_wmask),
    .toSRAM_7_re         (childBd_23_re),
    .toSRAM_7_we         (childBd_23_we),
    .toSRAM_7_rdata      (childBd_23_rdata),
    .toSRAM_7_ack        (childBd_23_ack),
    .toSRAM_7_selectedOH (childBd_23_selectedOH),
    .toSRAM_7_array      (childBd_23_array)
  );
  MbistPipeIcacheDataWay3 res_3 (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_3_array),
    .mbist_all           (boreChildrenBd_bore_3_all),
    .mbist_req           (boreChildrenBd_bore_3_req),
    .mbist_ack           (boreChildrenBd_bore_3_ack),
    .mbist_writeen       (boreChildrenBd_bore_3_writeen),
    .mbist_be            (boreChildrenBd_bore_3_be),
    .mbist_addr          (boreChildrenBd_bore_3_addr),
    .mbist_indata        (boreChildrenBd_bore_3_indata),
    .mbist_readen        (boreChildrenBd_bore_3_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_3_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_3_outdata),
    .toSRAM_0_addr       (childBd_24_addr),
    .toSRAM_0_addr_rd    (childBd_24_addr_rd),
    .toSRAM_0_wdata      (childBd_24_wdata),
    .toSRAM_0_wmask      (childBd_24_wmask),
    .toSRAM_0_re         (childBd_24_re),
    .toSRAM_0_we         (childBd_24_we),
    .toSRAM_0_rdata      (childBd_24_rdata),
    .toSRAM_0_ack        (childBd_24_ack),
    .toSRAM_0_selectedOH (childBd_24_selectedOH),
    .toSRAM_0_array      (childBd_24_array),
    .toSRAM_1_addr       (childBd_25_addr),
    .toSRAM_1_addr_rd    (childBd_25_addr_rd),
    .toSRAM_1_wdata      (childBd_25_wdata),
    .toSRAM_1_wmask      (childBd_25_wmask),
    .toSRAM_1_re         (childBd_25_re),
    .toSRAM_1_we         (childBd_25_we),
    .toSRAM_1_rdata      (childBd_25_rdata),
    .toSRAM_1_ack        (childBd_25_ack),
    .toSRAM_1_selectedOH (childBd_25_selectedOH),
    .toSRAM_1_array      (childBd_25_array),
    .toSRAM_2_addr       (childBd_26_addr),
    .toSRAM_2_addr_rd    (childBd_26_addr_rd),
    .toSRAM_2_wdata      (childBd_26_wdata),
    .toSRAM_2_wmask      (childBd_26_wmask),
    .toSRAM_2_re         (childBd_26_re),
    .toSRAM_2_we         (childBd_26_we),
    .toSRAM_2_rdata      (childBd_26_rdata),
    .toSRAM_2_ack        (childBd_26_ack),
    .toSRAM_2_selectedOH (childBd_26_selectedOH),
    .toSRAM_2_array      (childBd_26_array),
    .toSRAM_3_addr       (childBd_27_addr),
    .toSRAM_3_addr_rd    (childBd_27_addr_rd),
    .toSRAM_3_wdata      (childBd_27_wdata),
    .toSRAM_3_wmask      (childBd_27_wmask),
    .toSRAM_3_re         (childBd_27_re),
    .toSRAM_3_we         (childBd_27_we),
    .toSRAM_3_rdata      (childBd_27_rdata),
    .toSRAM_3_ack        (childBd_27_ack),
    .toSRAM_3_selectedOH (childBd_27_selectedOH),
    .toSRAM_3_array      (childBd_27_array),
    .toSRAM_4_addr       (childBd_28_addr),
    .toSRAM_4_addr_rd    (childBd_28_addr_rd),
    .toSRAM_4_wdata      (childBd_28_wdata),
    .toSRAM_4_wmask      (childBd_28_wmask),
    .toSRAM_4_re         (childBd_28_re),
    .toSRAM_4_we         (childBd_28_we),
    .toSRAM_4_rdata      (childBd_28_rdata),
    .toSRAM_4_ack        (childBd_28_ack),
    .toSRAM_4_selectedOH (childBd_28_selectedOH),
    .toSRAM_4_array      (childBd_28_array),
    .toSRAM_5_addr       (childBd_29_addr),
    .toSRAM_5_addr_rd    (childBd_29_addr_rd),
    .toSRAM_5_wdata      (childBd_29_wdata),
    .toSRAM_5_wmask      (childBd_29_wmask),
    .toSRAM_5_re         (childBd_29_re),
    .toSRAM_5_we         (childBd_29_we),
    .toSRAM_5_rdata      (childBd_29_rdata),
    .toSRAM_5_ack        (childBd_29_ack),
    .toSRAM_5_selectedOH (childBd_29_selectedOH),
    .toSRAM_5_array      (childBd_29_array),
    .toSRAM_6_addr       (childBd_30_addr),
    .toSRAM_6_addr_rd    (childBd_30_addr_rd),
    .toSRAM_6_wdata      (childBd_30_wdata),
    .toSRAM_6_wmask      (childBd_30_wmask),
    .toSRAM_6_re         (childBd_30_re),
    .toSRAM_6_we         (childBd_30_we),
    .toSRAM_6_rdata      (childBd_30_rdata),
    .toSRAM_6_ack        (childBd_30_ack),
    .toSRAM_6_selectedOH (childBd_30_selectedOH),
    .toSRAM_6_array      (childBd_30_array),
    .toSRAM_7_addr       (childBd_31_addr),
    .toSRAM_7_addr_rd    (childBd_31_addr_rd),
    .toSRAM_7_wdata      (childBd_31_wdata),
    .toSRAM_7_wmask      (childBd_31_wmask),
    .toSRAM_7_re         (childBd_31_re),
    .toSRAM_7_we         (childBd_31_we),
    .toSRAM_7_rdata      (childBd_31_rdata),
    .toSRAM_7_ack        (childBd_31_ack),
    .toSRAM_7_selectedOH (childBd_31_selectedOH),
    .toSRAM_7_array      (childBd_31_array)
  );

endmodule
