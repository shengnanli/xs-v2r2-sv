// Queue2_TLBundleD_11.sv —— rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)） 的 D 通道
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：ICacheCtrlBuffer / TLBuffer_20 / TLBuffer_22 .nodeIn_d_q。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_2x80 行为级叶子（2 项 x 80 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   opcode[3:0] param[5:4] size[7:6] source[12:8] sink[13:13] denied[14:14] data[78:15] corrupt[79:79]
// golden 190 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_TLBundleD_11) —— scripts/gen_uncore_queues.py
module Queue2_TLBundleD_11 (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_param,
  input  logic [1:0] io_enq_bits_size,
  input  logic [4:0] io_enq_bits_source,
  input  logic io_enq_bits_sink,
  input  logic io_enq_bits_denied,
  input  logic [63:0] io_enq_bits_data,
  input  logic io_enq_bits_corrupt,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_param,
  output logic [1:0] io_deq_bits_size,
  output logic [4:0] io_deq_bits_source,
  output logic io_deq_bits_sink,
  output logic io_deq_bits_denied,
  output logic [63:0] io_deq_bits_data,
  output logic io_deq_bits_corrupt
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [79:0] ramReadWord;

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
  ram_2x80 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_corrupt, io_enq_bits_data, io_enq_bits_denied, io_enq_bits_sink, io_enq_bits_source, io_enq_bits_size, io_enq_bits_param, io_enq_bits_opcode})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_opcode = ramReadWord[3:0];
  assign io_deq_bits_param = ramReadWord[5:4];
  assign io_deq_bits_size = ramReadWord[7:6];
  assign io_deq_bits_source = ramReadWord[12:8];
  assign io_deq_bits_sink = ramReadWord[13];
  assign io_deq_bits_denied = ramReadWord[14];
  assign io_deq_bits_data = ramReadWord[78:15];
  assign io_deq_bits_corrupt = ramReadWord[79];

endmodule
// END GENERATED(Queue2_TLBundleD_11)
