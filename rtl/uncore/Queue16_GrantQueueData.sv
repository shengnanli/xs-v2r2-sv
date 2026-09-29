// Queue16_GrantQueueData.sv —— GrantBuffer 的 grant 数据队列（两份，各存一个 beat）
//
// chisel3 Queue(entries=16, flow=false) 的单态化（父模块 GrantBuffer）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_data_16x256 行为级
// 存储叶子（16 项 x 256 位，两侧同源 inline）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：data_data[255:0]
// golden 155 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue16_GrantQueueData) —— scripts/gen_l2_queues.py
module Queue16_GrantQueueData (
  input  logic clock,
  input  logic reset,
  input  logic io_enq_valid,
  input  logic [255:0] io_enq_bits_data_data,
  input  logic io_deq_ready,
  output logic [255:0] io_deq_bits_data_data
);

  logic             do_enq;
  logic [3:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [4:0]       count;
  logic             enq_ready, deq_valid;
  logic [255:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(16), .FLOW(1'b0)) u_core (
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
  ram_data_16x256 ram_data_data_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_data_data})
  );

  assign io_deq_bits_data_data = ramReadWord;

endmodule
// END GENERATED(Queue16_GrantQueueData)
