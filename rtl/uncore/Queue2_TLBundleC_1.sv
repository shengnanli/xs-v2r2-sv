// Queue2_TLBundleC_1.sv —— rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)） 的 C 通道（release/probeAck）
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：TLBuffer_13.nodeOut_c_q{,_1,_2,_3}。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_2x321 行为级叶子（2 项 x 321 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   opcode[2:0] param[5:3] size[8:6] source[15:9] address[63:16] data[319:64] corrupt[320:320]
// 入队端口 io_enq_bits_user_reqSource, io_enq_bits_user_alias, io_enq_bits_user_vaddr, io_enq_bits_user_needHint, io_enq_bits_echo_isKeyword 没有存进 ram（出队侧无读者，firtool 删了存储但留了端口），这里同样只留端口。
// golden 191 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_TLBundleC_1) —— scripts/gen_uncore_queues.py
module Queue2_TLBundleC_1 (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [2:0] io_enq_bits_opcode,
  input  logic [2:0] io_enq_bits_param,
  input  logic [2:0] io_enq_bits_size,
  input  logic [6:0] io_enq_bits_source,
  input  logic [47:0] io_enq_bits_address,
  input  logic [4:0] io_enq_bits_user_reqSource,
  input  logic [1:0] io_enq_bits_user_alias,
  input  logic [43:0] io_enq_bits_user_vaddr,
  input  logic io_enq_bits_user_needHint,
  input  logic io_enq_bits_echo_isKeyword,
  input  logic [255:0] io_enq_bits_data,
  input  logic io_enq_bits_corrupt,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [2:0] io_deq_bits_opcode,
  output logic [2:0] io_deq_bits_param,
  output logic [2:0] io_deq_bits_size,
  output logic [6:0] io_deq_bits_source,
  output logic [47:0] io_deq_bits_address,
  output logic [255:0] io_deq_bits_data,
  output logic io_deq_bits_corrupt
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [320:0] ramReadWord;

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
  ram_2x321 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_corrupt, io_enq_bits_data, io_enq_bits_address, io_enq_bits_source, io_enq_bits_size, io_enq_bits_param, io_enq_bits_opcode})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_opcode = ramReadWord[2:0];
  assign io_deq_bits_param = ramReadWord[5:3];
  assign io_deq_bits_size = ramReadWord[8:6];
  assign io_deq_bits_source = ramReadWord[15:9];
  assign io_deq_bits_address = ramReadWord[63:16];
  assign io_deq_bits_data = ramReadWord[319:64];
  assign io_deq_bits_corrupt = ramReadWord[320];

endmodule
// END GENERATED(Queue2_TLBundleC_1)
