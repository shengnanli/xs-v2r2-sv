// ICacheMetaArray_xs —— UT 用「手写实现」顶层（= 可读核 xs_ICacheMetaArray_core +
// golden tag SRAM 黑盒 + MbistPipeIcacheTag 的端口适配层）。
// 内容与 rtl/frontend/ICacheMetaArray_wrapper.sv（golden 同名 ICacheMetaArray，供 FM）
// 完全相同，仅模块名改为 ICacheMetaArray_xs 以避免与 golden 顶层在 UT 双例化时同名冲突。
// 注：保持二者一致；改 wrapper 时请同步本文件。
module ICacheMetaArray_xs(
  input         clock,
  input         reset,
  input         io_write_valid,
  input  [7:0]  io_write_bits_virIdx,
  input  [35:0] io_write_bits_phyTag,
  input  [3:0]  io_write_bits_waymask,
  input         io_write_bits_bankIdx,
  input         io_write_bits_poison,
  output        io_read_ready,
  input         io_read_valid,
  input  [7:0]  io_read_bits_vSetIdx_0,
  input  [7:0]  io_read_bits_vSetIdx_1,
  input         io_read_bits_isDoubleLine,
  output [35:0] io_readResp_metas_0_0_tag,
  output [35:0] io_readResp_metas_0_1_tag,
  output [35:0] io_readResp_metas_0_2_tag,
  output [35:0] io_readResp_metas_0_3_tag,
  output [35:0] io_readResp_metas_1_0_tag,
  output [35:0] io_readResp_metas_1_1_tag,
  output [35:0] io_readResp_metas_1_2_tag,
  output [35:0] io_readResp_metas_1_3_tag,
  output        io_readResp_codes_0_0,
  output        io_readResp_codes_0_1,
  output        io_readResp_codes_0_2,
  output        io_readResp_codes_0_3,
  output        io_readResp_codes_1_0,
  output        io_readResp_codes_1_1,
  output        io_readResp_codes_1_2,
  output        io_readResp_codes_1_3,
  output        io_readResp_entryValid_0_0,
  output        io_readResp_entryValid_0_1,
  output        io_readResp_entryValid_0_2,
  output        io_readResp_entryValid_0_3,
  output        io_readResp_entryValid_1_0,
  output        io_readResp_entryValid_1_1,
  output        io_readResp_entryValid_1_2,
  output        io_readResp_entryValid_1_3,
  input         io_flush_0_valid,
  input  [7:0]  io_flush_0_bits_virIdx,
  input  [3:0]  io_flush_0_bits_waymask,
  input         io_flush_1_valid,
  input  [7:0]  io_flush_1_bits_virIdx,
  input  [3:0]  io_flush_1_bits_waymask,
  input         io_flushAll,
  input  [1:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input  [1:0]  boreChildrenBd_bore_be,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [73:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  output [73:0] boreChildrenBd_bore_outdata,
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
  input         sigFromSrams_bore_3_cgen
);
  import xs_icache_meta_pkg::*;

  // ---- 核 <-> tag SRAM 接口（数组化）----
  logic                core_sram_r_valid  [PORT_NUM];
  logic [BANK_IDX_BITS-1:0] core_sram_r_setIdx [PORT_NUM];
  logic                core_sram_r_ready  [PORT_NUM];
  meta_resp_t          core_sram_r_resp   [PORT_NUM][N_WAYS];
  logic                core_sram_w_valid  [PORT_NUM];
  logic [BANK_IDX_BITS-1:0] core_sram_w_setIdx;
  meta_resp_t          core_sram_w_data;
  logic [N_WAYS-1:0]   core_sram_w_waymask;

  // ---- 核读响应（数组）----
  logic [TAG_BITS-1:0] rr_metas      [PORT_NUM][N_WAYS];
  logic                rr_codes      [PORT_NUM][N_WAYS];
  logic                rr_entryValid [PORT_NUM][N_WAYS];

  // ---- flush 输入（数组化）----
  logic                flush_valid   [PORT_NUM];
  logic [IDX_BITS-1:0] flush_virIdx  [PORT_NUM];
  logic [N_WAYS-1:0]   flush_waymask [PORT_NUM];
  assign flush_valid[0]   = io_flush_0_valid;
  assign flush_valid[1]   = io_flush_1_valid;
  assign flush_virIdx[0]  = io_flush_0_bits_virIdx;
  assign flush_virIdx[1]  = io_flush_1_bits_virIdx;
  assign flush_waymask[0] = io_flush_0_bits_waymask;
  assign flush_waymask[1] = io_flush_1_bits_waymask;

  // ===========================================================================
  // 可读核例化（固定实例名 u_core，供 FM 脚本定位 valid_array 等）
  // ===========================================================================
  xs_ICacheMetaArray_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_write_valid         (io_write_valid),
    .io_write_bits_virIdx   (io_write_bits_virIdx),
    .io_write_bits_phyTag   (io_write_bits_phyTag),
    .io_write_bits_waymask  (io_write_bits_waymask),
    .io_write_bits_bankIdx  (io_write_bits_bankIdx),
    .io_write_bits_poison   (io_write_bits_poison),
    .io_read_ready          (io_read_ready),
    .io_read_valid          (io_read_valid),
    .io_read_bits_vSetIdx_0 (io_read_bits_vSetIdx_0),
    .io_read_bits_vSetIdx_1 (io_read_bits_vSetIdx_1),
    .io_read_bits_isDoubleLine (io_read_bits_isDoubleLine),
    .io_readResp_metas      (rr_metas),
    .io_readResp_codes      (rr_codes),
    .io_readResp_entryValid (rr_entryValid),
    .io_flush_valid         (flush_valid),
    .io_flush_virIdx        (flush_virIdx),
    .io_flush_waymask       (flush_waymask),
    .io_flushAll            (io_flushAll),
    .sram_r_valid           (core_sram_r_valid),
    .sram_r_setIdx          (core_sram_r_setIdx),
    .sram_r_ready           (core_sram_r_ready),
    .sram_r_resp            (core_sram_r_resp),
    .sram_w_valid           (core_sram_w_valid),
    .sram_w_setIdx          (core_sram_w_setIdx),
    .sram_w_data            (core_sram_w_data),
    .sram_w_waymask         (core_sram_w_waymask)
  );

  // ---- 读响应：核数组 → golden 扁平输出 ----
  assign io_readResp_metas_0_0_tag = rr_metas[0][0];
  assign io_readResp_metas_0_1_tag = rr_metas[0][1];
  assign io_readResp_metas_0_2_tag = rr_metas[0][2];
  assign io_readResp_metas_0_3_tag = rr_metas[0][3];
  assign io_readResp_metas_1_0_tag = rr_metas[1][0];
  assign io_readResp_metas_1_1_tag = rr_metas[1][1];
  assign io_readResp_metas_1_2_tag = rr_metas[1][2];
  assign io_readResp_metas_1_3_tag = rr_metas[1][3];
  assign io_readResp_codes_0_0 = rr_codes[0][0];
  assign io_readResp_codes_0_1 = rr_codes[0][1];
  assign io_readResp_codes_0_2 = rr_codes[0][2];
  assign io_readResp_codes_0_3 = rr_codes[0][3];
  assign io_readResp_codes_1_0 = rr_codes[1][0];
  assign io_readResp_codes_1_1 = rr_codes[1][1];
  assign io_readResp_codes_1_2 = rr_codes[1][2];
  assign io_readResp_codes_1_3 = rr_codes[1][3];
  assign io_readResp_entryValid_0_0 = rr_entryValid[0][0];
  assign io_readResp_entryValid_0_1 = rr_entryValid[0][1];
  assign io_readResp_entryValid_0_2 = rr_entryValid[0][2];
  assign io_readResp_entryValid_0_3 = rr_entryValid[0][3];
  assign io_readResp_entryValid_1_0 = rr_entryValid[1][0];
  assign io_readResp_entryValid_1_1 = rr_entryValid[1][1];
  assign io_readResp_entryValid_1_2 = rr_entryValid[1][2];
  assign io_readResp_entryValid_1_3 = rr_entryValid[1][3];

  // ===========================================================================
  // Mbist 流水（黑盒）：把外部 boreChildrenBd 总线分发给 4 个 SRAM 子端口
  //   toSRAM_0/1 → tagArrays_0（bank0 内部两块 SRAM），toSRAM_2/3 → tagArrays_1。
  // ===========================================================================
  wire [73:0] bd_outdata;
  wire        bd_ack;
  // childBd_N：Mbist → 各内层 SRAM 的子总线（与 golden 同构）
  wire [7:0]  childBd_addr,   childBd_addr_rd;
  wire [73:0] childBd_wdata,  childBd_rdata;
  wire [1:0]  childBd_wmask;
  wire        childBd_re, childBd_we, childBd_ack, childBd_selectedOH, childBd_array;
  wire [7:0]  childBd_1_addr,  childBd_1_addr_rd;
  wire [73:0] childBd_1_wdata, childBd_1_rdata;
  wire [1:0]  childBd_1_wmask;
  wire        childBd_1_re, childBd_1_we, childBd_1_ack, childBd_1_selectedOH, childBd_1_array;
  wire [7:0]  childBd_2_addr,  childBd_2_addr_rd;
  wire [73:0] childBd_2_wdata, childBd_2_rdata;
  wire [1:0]  childBd_2_wmask;
  wire        childBd_2_re, childBd_2_we, childBd_2_ack, childBd_2_selectedOH;
  wire [1:0]  childBd_2_array;
  wire [7:0]  childBd_3_addr,  childBd_3_addr_rd;
  wire [73:0] childBd_3_wdata, childBd_3_rdata;
  wire [1:0]  childBd_3_wmask;
  wire        childBd_3_re, childBd_3_we, childBd_3_ack, childBd_3_selectedOH;
  wire [1:0]  childBd_3_array;

  assign boreChildrenBd_bore_ack     = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;

  // ===========================================================================
  // bank0 tag SRAM 黑盒（golden SplittedSRAMTemplate）
  //   读：核给 valid/setIdx；读出聚回核 core_sram_r_resp[0][*]。
  //   写：核给写数据（4 路同）+ waymask；写 valid 来自核 core_sram_w_valid[0]。
  // ===========================================================================
  SplittedSRAMTemplate tagArrays_0 (
    .clock                            (clock),
    .reset                            (reset),
    .io_r_req_ready                   (core_sram_r_ready[0]),
    .io_r_req_valid                   (core_sram_r_valid[0]),
    .io_r_req_bits_setIdx             (core_sram_r_setIdx[0]),
    .io_r_resp_data_0_meta_tag        (core_sram_r_resp[0][0].tag),
    .io_r_resp_data_0_code            (core_sram_r_resp[0][0].code),
    .io_r_resp_data_1_meta_tag        (core_sram_r_resp[0][1].tag),
    .io_r_resp_data_1_code            (core_sram_r_resp[0][1].code),
    .io_r_resp_data_2_meta_tag        (core_sram_r_resp[0][2].tag),
    .io_r_resp_data_2_code            (core_sram_r_resp[0][2].code),
    .io_r_resp_data_3_meta_tag        (core_sram_r_resp[0][3].tag),
    .io_r_resp_data_3_code            (core_sram_r_resp[0][3].code),
    .io_w_req_valid                   (core_sram_w_valid[0]),
    .io_w_req_bits_setIdx             (core_sram_w_setIdx),
    .io_w_req_bits_data_0_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_0_code        (core_sram_w_data.code),
    .io_w_req_bits_data_1_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_1_code        (core_sram_w_data.code),
    .io_w_req_bits_data_2_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_2_code        (core_sram_w_data.code),
    .io_w_req_bits_data_3_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_3_code        (core_sram_w_data.code),
    .io_w_req_bits_waymask            (core_sram_w_waymask),
    .boreChildrenBd_bore_addr         (childBd_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_wdata),
    .boreChildrenBd_bore_wmask        (childBd_wmask),
    .boreChildrenBd_bore_re           (childBd_re),
    .boreChildrenBd_bore_we           (childBd_we),
    .boreChildrenBd_bore_rdata        (childBd_rdata),
    .boreChildrenBd_bore_ack          (childBd_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_selectedOH),
    .boreChildrenBd_bore_array        (childBd_array),
    .boreChildrenBd_bore_1_addr       (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_1_wmask),
    .boreChildrenBd_bore_1_re         (childBd_1_re),
    .boreChildrenBd_bore_1_we         (childBd_1_we),
    .boreChildrenBd_bore_1_rdata      (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_1_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen)
  );

  // ===========================================================================
  // bank1 tag SRAM 黑盒（golden SplittedSRAMTemplate_1）
  // ===========================================================================
  SplittedSRAMTemplate_1 tagArrays_1 (
    .clock                            (clock),
    .reset                            (reset),
    .io_r_req_ready                   (core_sram_r_ready[1]),
    .io_r_req_valid                   (core_sram_r_valid[1]),
    .io_r_req_bits_setIdx             (core_sram_r_setIdx[1]),
    .io_r_resp_data_0_meta_tag        (core_sram_r_resp[1][0].tag),
    .io_r_resp_data_0_code            (core_sram_r_resp[1][0].code),
    .io_r_resp_data_1_meta_tag        (core_sram_r_resp[1][1].tag),
    .io_r_resp_data_1_code            (core_sram_r_resp[1][1].code),
    .io_r_resp_data_2_meta_tag        (core_sram_r_resp[1][2].tag),
    .io_r_resp_data_2_code            (core_sram_r_resp[1][2].code),
    .io_r_resp_data_3_meta_tag        (core_sram_r_resp[1][3].tag),
    .io_r_resp_data_3_code            (core_sram_r_resp[1][3].code),
    .io_w_req_valid                   (core_sram_w_valid[1]),
    .io_w_req_bits_setIdx             (core_sram_w_setIdx),
    .io_w_req_bits_data_0_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_0_code        (core_sram_w_data.code),
    .io_w_req_bits_data_1_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_1_code        (core_sram_w_data.code),
    .io_w_req_bits_data_2_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_2_code        (core_sram_w_data.code),
    .io_w_req_bits_data_3_meta_tag    (core_sram_w_data.tag),
    .io_w_req_bits_data_3_code        (core_sram_w_data.code),
    .io_w_req_bits_waymask            (core_sram_w_waymask),
    .boreChildrenBd_bore_addr         (childBd_2_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_2_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_2_wdata),
    .boreChildrenBd_bore_wmask        (childBd_2_wmask),
    .boreChildrenBd_bore_re           (childBd_2_re),
    .boreChildrenBd_bore_we           (childBd_2_we),
    .boreChildrenBd_bore_rdata        (childBd_2_rdata),
    .boreChildrenBd_bore_ack          (childBd_2_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_2_selectedOH),
    .boreChildrenBd_bore_array        (childBd_2_array),
    .boreChildrenBd_bore_1_addr       (childBd_3_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_3_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_3_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_3_wmask),
    .boreChildrenBd_bore_1_re         (childBd_3_re),
    .boreChildrenBd_bore_1_we         (childBd_3_we),
    .boreChildrenBd_bore_1_rdata      (childBd_3_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_3_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_3_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_3_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_3_cgen)
  );

  // ===========================================================================
  // Mbist 流水黑盒：内建自测总线分发（与 golden 端口一致）
  // ===========================================================================
  MbistPipeIcacheTag mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (bd_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (bd_outdata),
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
    .toSRAM_3_array      (childBd_3_array)
  );

endmodule
