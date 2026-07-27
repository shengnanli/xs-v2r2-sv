// xs_Queue1_UInt32_core —— 深度 1 队列可读核(仅 valid/bits 流, 无 ready 背压)。
//
// 对应 golden Queue1_UInt32(Chisel `Queue(UInt(32.W), entries=1, flow=false,
// pipe=false)` 但被例化处 deq_ready 恒真、enq_ready 未连出, 故 firtool 裁掉了
// io_enq_ready / io_deq_ready 端口, 仅剩 io_enq_valid/bits 与 io_deq_valid/bits)。
//
// 语义(与 golden Queue1_UInt32 逐位一致):
//   - full: 当前是否驻留一拍数据(异步 reset 清 0)。
//   - ram(32b): io_enq_valid 时锁存入队数据(同步写, 无 reset)。
//   - full 更新: 仅当 io_enq_valid != full 时改变, 取值 io_enq_valid。
//     (因 deq_ready 恒真, do_deq==full; do_enq==io_enq_valid;
//      full' = do_enq XOR-gated: enq!=full 时随 enq。)
//   - deq_valid = full; deq_bits = ram。
module xs_Queue1_UInt32_core(
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [31:0] io_enq_bits,
  output        io_deq_valid,
  output [31:0] io_deq_bits
);

  reg [31:0] ram;
  reg        full;

  always @(posedge clock) begin
    if (io_enq_valid)
      ram <= io_enq_bits;
  end

  always @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'h0;
    else if (~(io_enq_valid == full))
      full <= io_enq_valid;
  end

  assign io_deq_valid = full;
  assign io_deq_bits  = ram;

endmodule
