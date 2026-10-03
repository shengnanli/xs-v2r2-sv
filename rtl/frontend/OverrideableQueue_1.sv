// =============================================================================
// OverrideableQueue_1 —— SMS 预取器 PHT 更新（AGT 逐出表项）的 4 项可覆盖队列（evict_queue）
//
// 在哪一层：MemBlock / SMS 预取器的 PatternHistoryTable（mem/prefetch/SMSPrefetcher.scala
//   `evict_queue = Module(new OverrideableQueue(new AGTEntry, smsParams.pht_lookup_queue_size))`，size = 4）。
//   AGT（活跃区域表）逐出一个表项时把它的访问模式（io.agt_update）送来写回 PHT；
//   PHT 的 s0 级 evict 优先于 lookup，下游 s1 被阻塞时在这里排队。
// 机制：可覆盖环形队列——入口不反压，满了覆盖；全部逻辑在共享核 rtl/common/xs_OverrideableQueue_core.sv，
//   本文件只把 AGTEntry 的 9 个字段按端口顺序 MSB 优先拼成一根 61 位载荷。
// golden 对照：G1-canonical/golden-rtl/OverrideableQueue_1.sv（338 行）
// =============================================================================
module OverrideableQueue_1 (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_in_valid,
  input  logic [4:0]  io_in_bits_pht_index,
  input  logic [12:0] io_in_bits_pht_tag,
  input  logic [15:0] io_in_bits_region_bits,
  input  logic [15:0] io_in_bits_region_bit_single,
  input  logic [3:0]  io_in_bits_region_offset,
  input  logic [3:0]  io_in_bits_access_cnt,
  input  logic        io_in_bits_decr_mode,
  input  logic        io_in_bits_single_update,
  input  logic        io_in_bits_has_been_signal_updated,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [4:0]  io_out_bits_pht_index,
  output logic [12:0] io_out_bits_pht_tag,
  output logic [15:0] io_out_bits_region_bits,
  output logic [15:0] io_out_bits_region_bit_single,
  output logic [3:0]  io_out_bits_region_offset,
  output logic [3:0]  io_out_bits_access_cnt,
  output logic        io_out_bits_decr_mode,
  output logic        io_out_bits_single_update,
  output logic        io_out_bits_has_been_signal_updated
);

  localparam int unsigned W = 5 + 13 + 16 + 16 + 4 + 4 + 1 + 1 + 1;   // = 61

  logic [W-1:0] in_payload;
  logic [W-1:0] out_payload;

  assign in_payload = {io_in_bits_pht_index,
                       io_in_bits_pht_tag,
                       io_in_bits_region_bits,
                       io_in_bits_region_bit_single,
                       io_in_bits_region_offset,
                       io_in_bits_access_cnt,
                       io_in_bits_decr_mode,
                       io_in_bits_single_update,
                       io_in_bits_has_been_signal_updated};

  xs_OverrideableQueue_core #(
    .N(4),
    .W(W)
  ) u_core (
    .clock    (clock),
    .reset    (reset),
    .in_valid (io_in_valid),
    .in_bits  (in_payload),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_payload)
  );

  assign {io_out_bits_pht_index,
          io_out_bits_pht_tag,
          io_out_bits_region_bits,
          io_out_bits_region_bit_single,
          io_out_bits_region_offset,
          io_out_bits_access_cnt,
          io_out_bits_decr_mode,
          io_out_bits_single_update,
          io_out_bits_has_been_signal_updated} = out_payload;
endmodule
