// Queue40_L2TlbMQBundle.sv —— xiangshan mmu L2TLBMissQueue.scala `Queue(io.in, MissQueueSize, flush = Some(...))`：L2TLB miss 回灌队列（40 项、带 flush）
//
// chisel3 Queue(entries=40, pipe=false, flow=false, flush) 的单态化；例化处：L2TlbMissQueue.io_out_q。
// 控制+存储都在已签的 xs_L2TlbMissQueue_core（rtl/memblock/L2TlbMissQueue.sv，40 项、flush 一拍清空）；
// 存储叶子 ram_40x47（40 项 x 47 位；深度非 2 的幂 —— FM 边界须按 verif/vendor_boundary.tsv 逐父级审定）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   req_info_vpn[37:0] req_info_s2xlate[39:38] req_info_source[41:40] 1'h0[42:42] isLLptw[43:43] 3'h0[46:44]
// 常量段：父模块入队时恒为常量的 Bundle 字段（firtool 删了入口端口，把常量直接拼进 ram 字）；
//   出队时照样从 ram 读出 —— 上电后第一次入队之前它们是 ram 的初值，照 golden 保留，不省。
// golden 194 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue40_L2TlbMQBundle) —— scripts/gen_uncore_queues.py
module Queue40_L2TlbMQBundle (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [37:0] io_enq_bits_req_info_vpn,
  input  logic [1:0] io_enq_bits_req_info_s2xlate,
  input  logic [1:0] io_enq_bits_req_info_source,
  input  logic io_enq_bits_isLLptw,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [37:0] io_deq_bits_req_info_vpn,
  output logic [1:0] io_deq_bits_req_info_s2xlate,
  output logic [1:0] io_deq_bits_req_info_source,
  output logic io_deq_bits_isHptwReq,
  output logic io_deq_bits_isLLptw,
  output logic [2:0] io_deq_bits_hptwId,
  input  logic io_flush
);

  logic [46:0] ramReadWord;

  xs_L2TlbMissQueue_core u_core (
    .clock     (clock),
    .reset     (reset),
    .flush     (io_flush),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_bits  ({3'h0, io_enq_bits_isLLptw, 1'h0, io_enq_bits_req_info_source, io_enq_bits_req_info_s2xlate, io_enq_bits_req_info_vpn}),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_bits  (ramReadWord)
  );

  assign io_deq_bits_req_info_vpn = ramReadWord[37:0];
  assign io_deq_bits_req_info_s2xlate = ramReadWord[39:38];
  assign io_deq_bits_req_info_source = ramReadWord[41:40];
  assign io_deq_bits_isHptwReq = ramReadWord[42];
  assign io_deq_bits_isLLptw = ramReadWord[43];
  assign io_deq_bits_hptwId = ramReadWord[46:44];

endmodule
// END GENERATED(Queue40_L2TlbMQBundle)
