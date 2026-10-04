// Queue2_TLBundleB.sv —— rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)） 的 B 通道（probe）
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：TLBuffer_7.nodeIn_b_q。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_2x309 行为级叶子（2 项 x 309 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   opcode[2:0] param[4:3] address[52:5] data[308:53]
// 入队端口 io_enq_bits_size, io_enq_bits_source, io_enq_bits_mask, io_enq_bits_corrupt 没有存进 ram（出队侧无读者，firtool 删了存储但留了端口），这里同样只留端口。
// golden 175 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_TLBundleB) —— scripts/gen_uncore_queues.py
module Queue2_TLBundleB (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [2:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_param,
  input  logic [2:0] io_enq_bits_size,
  input  logic [5:0] io_enq_bits_source,
  input  logic [47:0] io_enq_bits_address,
  input  logic [31:0] io_enq_bits_mask,
  input  logic [255:0] io_enq_bits_data,
  input  logic io_enq_bits_corrupt,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [2:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_param,
  output logic [47:0] io_deq_bits_address,
  output logic [255:0] io_deq_bits_data
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [308:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(2), .FLOW(1'b0)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (enq_ready),
    .deq_valid (deq_valid),
    .deq_ready (io_deq_ready),
    .do_enq    (do_enq),
    .enq_ptr   (enq_ptr),
    .deq_ptr   (deq_ptr),
    .empty     (empty),
    .count     (count)
  );

  // 存储：写口在 enq_ptr、读口恒使能读 deq_ptr（组合读）
  ram_2x309 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_data, io_enq_bits_address, io_enq_bits_param, io_enq_bits_opcode})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_opcode = ramReadWord[2:0];
  assign io_deq_bits_param = ramReadWord[4:3];
  assign io_deq_bits_address = ramReadWord[52:5];
  assign io_deq_bits_data = ramReadWord[308:53];

endmodule
// END GENERATED(Queue2_TLBundleB)
