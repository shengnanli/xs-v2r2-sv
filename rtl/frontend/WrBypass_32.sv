// =============================================================================
// WrBypass_32 —— WrBypass 单态化变体（8 项 / idx 11b / 2 路 × 2b，带 way 掩码）
// 核体见 rtl/frontend/WrBypass.sv（xs_WrBypass_core），本文件仅设参数与端口展平。
// =============================================================================
module WrBypass_32(
  input         clock,
  input         reset,
  input         io_wen,
  input  [10:0] io_write_idx,
  input  [1:0]  io_write_data_0,
  input  [1:0]  io_write_data_1,
  input         io_write_way_mask_0,
  input         io_write_way_mask_1,
  output        io_hit,
  output        io_hit_data_0_valid,
  output [1:0]  io_hit_data_0_bits,
  output        io_hit_data_1_valid,
  output [1:0]  io_hit_data_1_bits
);

  xs_WrBypass_core #(
    .NUM_ENTRIES(8), .IDX_WIDTH(11), .NUM_WAYS(2), .TAG_WIDTH(0), .DATA_WIDTH(2)
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .io_wen           (io_wen),
    .io_write_idx     (io_write_idx),
    .io_write_tag     (1'b0),
    .io_write_data    ({io_write_data_1, io_write_data_0}),
    .io_write_way_mask({io_write_way_mask_1, io_write_way_mask_0}),
    .io_hit           (io_hit),
    .io_hit_data_valid({io_hit_data_1_valid, io_hit_data_0_valid}),
    .io_hit_data_bits ({io_hit_data_1_bits, io_hit_data_0_bits})
  );

endmodule
