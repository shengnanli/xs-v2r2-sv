// =============================================================================
// OverrideableQueue —— SMS 预取器 PHT 查询请求的 4 项可覆盖队列（lookup_queue）
//
// 在哪一层：MemBlock / SMS 预取器的 PatternHistoryTable（mem/prefetch/SMSPrefetcher.scala
//   `lookup_queue = Module(new OverrideableQueue(new PhtLookup, smsParams.pht_lookup_queue_size))`，size = 4）。AGT 在 s2 级发出的 PHT 查询
//   （io.s2_agt_lookup：pht_index/pht_tag + 区域物理/虚拟地址 + 触发偏移）先进这里；PHT 的 s0 级
//   evict 优先、lookup 其次，轮不到时在这里排队。
// 机制：可覆盖环形队列——入口不反压，满了覆盖；全部逻辑在共享核 rtl/common/xs_OverrideableQueue_core.sv，
//   本文件只把 5 个载荷字段按端口顺序 MSB 优先拼成一根 102 位载荷。
// golden 对照：G1-canonical/golden-rtl/OverrideableQueue.sv（271 行）
// =============================================================================
module OverrideableQueue (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_in_valid,
  input  logic [4:0]  io_in_bits_pht_index,
  input  logic [12:0] io_in_bits_pht_tag,
  input  logic [39:0] io_in_bits_region_paddr,
  input  logic [39:0] io_in_bits_region_vaddr,
  input  logic [3:0]  io_in_bits_region_offset,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [4:0]  io_out_bits_pht_index,
  output logic [12:0] io_out_bits_pht_tag,
  output logic [39:0] io_out_bits_region_paddr,
  output logic [39:0] io_out_bits_region_vaddr,
  output logic [3:0]  io_out_bits_region_offset
);

  localparam int unsigned W = 5 + 13 + 40 + 40 + 4;   // = 102

  logic [W-1:0] in_payload;
  logic [W-1:0] out_payload;

  assign in_payload = {io_in_bits_pht_index,
                       io_in_bits_pht_tag,
                       io_in_bits_region_paddr,
                       io_in_bits_region_vaddr,
                       io_in_bits_region_offset};

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
          io_out_bits_region_paddr,
          io_out_bits_region_vaddr,
          io_out_bits_region_offset} = out_payload;
endmodule
