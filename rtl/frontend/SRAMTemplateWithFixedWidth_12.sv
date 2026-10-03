// SRAMTemplateWithFixedWidth_12.sv —— ICache 数据阵列的一块"定宽切分"SRAM（SRAMTemplateWithFixedWidth 家族变体）
//
// 本变体参数：内层 SRAM = SRAMTemplate_16，MBIST bore_array 5 位；其余（65 位数据 → 66 位宽单块 SRAM，
//   写入高位补 0、读出截掉最高位）与家族基础变体完全相同，
//   机制讲在 rtl/frontend/SRAMTemplateWithFixedWidth.sv 的文件头。
// golden 146 行 / 25 端口；唯一子模块 SRAMTemplate_16（已独立签核）。
// 本文件由 scripts/gen_sram_fixed_width.py 从 golden 机械生成并逐端口核对（勿手改）。

// BEGIN GENERATED(SRAMTemplateWithFixedWidth_12) —— scripts/gen_sram_fixed_width.py
module SRAMTemplateWithFixedWidth_12 (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_r_req_valid,
  input  logic [7:0]  io_r_req_bits_setIdx,
  output logic [64:0] io_r_resp_data_0,
  input  logic        io_w_req_valid,
  input  logic [7:0]  io_w_req_bits_setIdx,
  input  logic [64:0] io_w_req_bits_data_0,
  input  logic [8:0]  boreChildrenBd_bore_addr,
  input  logic [8:0]  boreChildrenBd_bore_addr_rd,
  input  logic [65:0] boreChildrenBd_bore_wdata,
  input  logic        boreChildrenBd_bore_wmask,
  input  logic        boreChildrenBd_bore_re,
  input  logic        boreChildrenBd_bore_we,
  output logic [65:0] boreChildrenBd_bore_rdata,
  input  logic        boreChildrenBd_bore_ack,
  input  logic        boreChildrenBd_bore_selectedOH,
  input  logic [4:0]  boreChildrenBd_bore_array,
  input  logic        sigFromSrams_bore_ram_hold,
  input  logic        sigFromSrams_bore_ram_bypass,
  input  logic        sigFromSrams_bore_ram_bp_clken,
  input  logic        sigFromSrams_bore_ram_aux_clk,
  input  logic        sigFromSrams_bore_ram_aux_ckbp,
  input  logic        sigFromSrams_bore_ram_mcp_hold,
  input  logic        sigFromSrams_bore_cgen
);

  localparam int unsigned DATA_W = 65;   // ICacheDataEntryBits
  localparam int unsigned SRAM_W = 66;   // ICacheDataSRAMWidth（bankNum = 1）

  logic [SRAM_W-1:0] sram_rdata;

  // 唯一一块 SRAM：写数据零扩展到 SRAM 宽，DFT 广播/bore 口原样透传
  SRAMTemplate_16 srams_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (sram_rdata),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (SRAM_W'(io_w_req_bits_data_0)),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen)
  );

  // 读回截掉补的最高位
  assign io_r_resp_data_0 = sram_rdata[DATA_W-1:0];

endmodule
// END GENERATED(SRAMTemplateWithFixedWidth_12)
