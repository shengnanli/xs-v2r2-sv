// =============================================================================
// WrBypass_41 —— WrBypass 单态化变体（4 项 / idx 8b / 1 路 × 2b）
// golden 上层未消费 io_hit_data_0_valid，firtool 已裁剪该输出端口 →
// TRACK_HIT_VALID=0 不建 valids 寄存器（否则悬空成死寄存器，FM strict 不过）。
// 核体见 rtl/frontend/WrBypass.sv（xs_WrBypass_core）。
// =============================================================================
module WrBypass_41(
  input        clock,
  input        reset,
  input        io_wen,
  input  [7:0] io_write_idx,
  input  [1:0] io_write_data_0,
  output       io_hit,
  output [1:0] io_hit_data_0_bits
);

  xs_WrBypass_core #(
    .NUM_ENTRIES(4), .IDX_WIDTH(8), .NUM_WAYS(1), .TAG_WIDTH(0), .DATA_WIDTH(2),
    .TRACK_HIT_VALID(1'b0)
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .io_wen           (io_wen),
    .io_write_idx     (io_write_idx),
    .io_write_tag     (1'b0),
    .io_write_data    (io_write_data_0),
    .io_write_way_mask(1'b1),
    .io_hit           (io_hit),
    .io_hit_data_valid(),
    .io_hit_data_bits (io_hit_data_0_bits)
  );

endmodule
