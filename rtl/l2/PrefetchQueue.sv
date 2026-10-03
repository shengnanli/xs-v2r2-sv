// =============================================================================
// PrefetchQueue —— L2 预取器出口的"只留最新"请求队列
//
// 位置：coupledL2 Prefetcher 里，各预取源（BOP/SMS/TP/接收）仲裁后的预取请求经本队列
//   送往 L2 的请求通道。队列 32 项，特点（照 Chisel 注释）：
//   1. 流水（pipelined）：每拍可同时入队出队；
//   2. 直通（flows）：队空时入队请求当拍直接出队（deq.bits = enq.bits）；
//   3. 永远 ready：队满再来新请求就**丢最老的**（head 跟着 +1），保证队里总是最新的请求。
//
// 握手细节（照 golden）：
//   empty = head==tail && !valid[31]；full = head==tail && valid[31]（指针相等时各 valid 一致，
//   Chisel 取了 valids.last）。
//   出队：!empty && deq.ready → valid[head] 清、head+1。
//   入队：enq.valid → queue[tail] 写入；valid[tail] <= (!empty || !deq.ready)，即"直通出去了就不留"；
//         tail += 同一个布尔；若 full && !deq.ready，head 再 +1（丢最老）。
//   同一槽同拍"入队写"与"出队清"相撞时入队赢（golden if/else 顺序）。
//   deq.valid = !empty || enq.valid；deq.bits = empty ? enq.bits : queue[head]。
// 载荷 {tag, set, vaddr, needT, source, pfSource} 对队列透明，核按一根 PL_W 位总线处理，
// wrapper 负责拼拆。全部寄存器异步复位清零。
// =============================================================================

module xs_PrefetchQueue_core #(
  parameter int unsigned PL_W    = 99,
  parameter int unsigned ENTRIES = 32
) (
  input  logic            clock,
  input  logic            reset,
  input  logic            enq_valid,
  input  logic [PL_W-1:0] enq_payload,
  input  logic            deq_ready,
  output logic            deq_valid,
  output logic [PL_W-1:0] deq_payload
);

  localparam int unsigned IDX_W = $clog2(ENTRIES);

  logic [PL_W-1:0]  queue_payload [ENTRIES];
  logic             queue_valid   [ENTRIES];
  logic [IDX_W-1:0] head, tail;

  logic ptr_equal, empty, full;
  logic deq_fire;      // 真正从队里弹出一项
  logic enq_keep;      // 入队的请求要留在队里（没有直通出去）

  assign ptr_equal = (head == tail);
  assign empty     = ptr_equal & ~queue_valid[ENTRIES-1];
  assign full      = ptr_equal &  queue_valid[ENTRIES-1];
  assign deq_fire  = ~empty & deq_ready;
  assign enq_keep  = ~empty | ~deq_ready;

  assign deq_valid   = ~empty | enq_valid;
  assign deq_payload = empty ? enq_payload : queue_payload[head];

  for (genvar i = 0; i < ENTRIES; i++) begin : g_entry
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        queue_payload[i] <= '0;
        queue_valid[i]   <= 1'b0;
      end else if (enq_valid && tail == IDX_W'(i)) begin
        queue_payload[i] <= enq_payload;
        queue_valid[i]   <= enq_keep;
      end else begin
        queue_valid[i]   <= ~(deq_fire & (head == IDX_W'(i))) & queue_valid[i];
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      head <= '0;
      tail <= '0;
    end else begin
      if ((enq_valid & full & ~deq_ready) | deq_fire) head <= head + 1'b1;   // 丢最老 或 正常出队
      if (enq_valid) tail <= tail + IDX_W'(enq_keep);
    end
  end

endmodule

module PrefetchQueue(
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_tag,
  input  [8:0]  io_enq_bits_set,
  input  [43:0] io_enq_bits_vaddr,
  input         io_enq_bits_needT,
  input  [6:0]  io_enq_bits_source,
  input  [4:0]  io_enq_bits_pfSource,
  input         io_deq_ready,
  output        io_deq_valid,
  output [32:0] io_deq_bits_tag,
  output [8:0]  io_deq_bits_set,
  output [43:0] io_deq_bits_vaddr,
  output        io_deq_bits_needT,
  output [6:0]  io_deq_bits_source,
  output [4:0]  io_deq_bits_pfSource
);

  localparam int unsigned PL_W = 33 + 9 + 44 + 1 + 7 + 5;

  logic [PL_W-1:0] enq_payload, deq_payload;

  assign enq_payload = {io_enq_bits_tag, io_enq_bits_set, io_enq_bits_vaddr,
                        io_enq_bits_needT, io_enq_bits_source, io_enq_bits_pfSource};

  xs_PrefetchQueue_core #(
    .PL_W   (PL_W),
    .ENTRIES(32)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .enq_valid  (io_enq_valid),
    .enq_payload(enq_payload),
    .deq_ready  (io_deq_ready),
    .deq_valid  (io_deq_valid),
    .deq_payload(deq_payload)
  );

  assign {io_deq_bits_tag, io_deq_bits_set, io_deq_bits_vaddr,
          io_deq_bits_needT, io_deq_bits_source, io_deq_bits_pfSource} = deq_payload;

endmodule
