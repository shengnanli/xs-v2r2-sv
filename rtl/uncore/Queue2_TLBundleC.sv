// Queue2_TLBundleC.sv —— rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)） 的 C 通道（release/probeAck）
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：TLBuffer_7.nodeOut_c_q。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_2x373 行为级叶子（2 项 x 373 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   opcode[2:0] param[5:3] size[8:6] source[14:9] address[62:15] 53'h0[115:63] data[371:116]
//   corrupt[372:372]
// 常量段：父模块入队时恒为常量的 Bundle 字段（firtool 删了入口端口，把常量直接拼进 ram 字）；
//   出队时照样从 ram 读出 —— 上电后第一次入队之前它们是 ram 的初值，照 golden 保留，不省。
// golden 197 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_TLBundleC) —— scripts/gen_uncore_queues.py
module Queue2_TLBundleC (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [2:0] io_enq_bits_opcode,
  input  logic [2:0] io_enq_bits_param,
  input  logic [2:0] io_enq_bits_size,
  input  logic [5:0] io_enq_bits_source,
  input  logic [47:0] io_enq_bits_address,
  input  logic [255:0] io_enq_bits_data,
  input  logic io_enq_bits_corrupt,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [2:0] io_deq_bits_opcode,
  output logic [2:0] io_deq_bits_param,
  output logic [2:0] io_deq_bits_size,
  output logic [5:0] io_deq_bits_source,
  output logic [47:0] io_deq_bits_address,
  output logic [1:0] io_deq_bits_user_alias,
  output logic [43:0] io_deq_bits_user_vaddr,
  output logic [4:0] io_deq_bits_user_reqSource,
  output logic io_deq_bits_user_needHint,
  output logic io_deq_bits_echo_isKeyword,
  output logic [255:0] io_deq_bits_data,
  output logic io_deq_bits_corrupt
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [372:0] ramReadWord;

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
  ram_2x373 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_corrupt, io_enq_bits_data, 53'h0, io_enq_bits_address, io_enq_bits_source, io_enq_bits_size, io_enq_bits_param, io_enq_bits_opcode})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_opcode = ramReadWord[2:0];
  assign io_deq_bits_param = ramReadWord[5:3];
  assign io_deq_bits_size = ramReadWord[8:6];
  assign io_deq_bits_source = ramReadWord[14:9];
  assign io_deq_bits_address = ramReadWord[62:15];
  assign io_deq_bits_user_alias = ramReadWord[64:63];
  assign io_deq_bits_user_vaddr = ramReadWord[108:65];
  assign io_deq_bits_user_reqSource = ramReadWord[113:109];
  assign io_deq_bits_user_needHint = ramReadWord[114];
  assign io_deq_bits_echo_isKeyword = ramReadWord[115];
  assign io_deq_bits_data = ramReadWord[371:116];
  assign io_deq_bits_corrupt = ramReadWord[372];

endmodule
// END GENERATED(Queue2_TLBundleC)
