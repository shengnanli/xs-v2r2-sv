// RecentRequestTable_1.sv —— VBestOffsetPrefetch（虚地址 BOP）的 RR 表（RecentRequestTable 家族变体）
//
// 本变体参数：地址 50 位（VAddr）、testOffset 10 位、ptr 7 位（ADDR_W=50 / OFFSET_W=10 / PTR_W=7）。
// 与 RecentRequestTable（物理地址 BOP：48 / 7 / 6）只差端口宽度 —— 表只用地址低 26 位，
//   hash/tag/读流水/单口仲裁全部相同，同一个 rrTable 子模块 SRAMTemplate_146。
// 核 xs_RecentRequestTable_core 在 rtl/uncore/RecentRequestTable.sv（表结构与读流水讲在那里）。
// golden 228 行 / 29 端口；本文件只是 golden 同名 wrapper。

module RecentRequestTable_1 (
  input  logic        clock,
  input  logic        reset,
  output logic        io_w_ready,
  input  logic        io_w_valid,
  input  logic [49:0] io_w_bits,
  input  logic        io_r_req_valid,
  input  logic [49:0] io_r_req_bits_addr,
  input  logic [9:0]  io_r_req_bits_testOffset,
  input  logic [6:0]  io_r_req_bits_ptr,
  output logic        io_r_resp_valid,
  output logic [6:0]  io_r_resp_bits_ptr,
  output logic        io_r_resp_bits_hit,
  input  logic [8:0]  boreChildrenBd_bore_addr,
  input  logic [8:0]  boreChildrenBd_bore_addr_rd,
  input  logic [12:0] boreChildrenBd_bore_wdata,
  input  logic        boreChildrenBd_bore_wmask,
  input  logic        boreChildrenBd_bore_re,
  input  logic        boreChildrenBd_bore_we,
  output logic [12:0] boreChildrenBd_bore_rdata,
  input  logic        boreChildrenBd_bore_ack,
  input  logic        boreChildrenBd_bore_selectedOH,
  input  logic        boreChildrenBd_bore_array,
  input  logic        sigFromSrams_bore_ram_hold,
  input  logic        sigFromSrams_bore_ram_bypass,
  input  logic        sigFromSrams_bore_ram_bp_clken,
  input  logic        sigFromSrams_bore_ram_aux_clk,
  input  logic        sigFromSrams_bore_ram_aux_ckbp,
  input  logic        sigFromSrams_bore_ram_mcp_hold,
  input  logic        sigFromSrams_bore_cgen
);

  xs_RecentRequestTable_core #(.ADDR_W(50), .OFFSET_W(10), .PTR_W(7)) u_core (
    .clock             (clock),
    .reset             (reset),
    .w_ready           (io_w_ready),
    .w_valid           (io_w_valid),
    .w_addr            (io_w_bits),
    .r_req_valid       (io_r_req_valid),
    .r_req_addr        (io_r_req_bits_addr),
    .r_req_test_offset (io_r_req_bits_testOffset),
    .r_req_ptr         (io_r_req_bits_ptr),
    .r_resp_valid      (io_r_resp_valid),
    .r_resp_ptr        (io_r_resp_bits_ptr),
    .r_resp_hit        (io_r_resp_bits_hit),
    .bore_addr         (boreChildrenBd_bore_addr),
    .bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .bore_wdata        (boreChildrenBd_bore_wdata),
    .bore_wmask        (boreChildrenBd_bore_wmask),
    .bore_re           (boreChildrenBd_bore_re),
    .bore_we           (boreChildrenBd_bore_we),
    .bore_rdata        (boreChildrenBd_bore_rdata),
    .bore_ack          (boreChildrenBd_bore_ack),
    .bore_selectedOH   (boreChildrenBd_bore_selectedOH),
    .bore_array        (boreChildrenBd_bore_array),
    .sram_ram_hold     (sigFromSrams_bore_ram_hold),
    .sram_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sram_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sram_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sram_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sram_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sram_cgen         (sigFromSrams_bore_cgen)
  );

endmodule
