// Queue1_UInt32.sv —— 32 位无反压流水的级寄存器（深度 1；无 ready 端口）
//
// payload 32 位（io_enq_bits → io_deq_bits 直通一个整字）。golden 没有 ready 端口：
// 父模块 Pipeline_10 / Pipeline_11 里 deq 恒被接走（deq_ready 恒 1）、enq_ready 恒 1，两个端口都被 firtool
// 常数折叠删掉；等价于 PIPE=1 + deq_ready 恒 1，do_enq 退化为 io_enq_valid，
// full 更新退化为 `~(io_enq_valid == full)`——下方例化照此接。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 134 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_UInt32) —— scripts/gen_depth1queue_leaves5.py
module Queue1_UInt32 (
  input  logic clock,
  input  logic reset,
  input  logic io_enq_valid,
  input  logic [31:0] io_enq_bits,
  output logic io_deq_valid,
  output logic [31:0] io_deq_bits
);

  xs_ChiselQueue1_core #(.W(32), .PIPE(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (),
    .enq_word  (io_enq_bits),
    .deq_valid (io_deq_valid),
    .deq_ready (1'b1),
    .deq_word  (io_deq_bits)
  );

endmodule
// END GENERATED(Queue1_UInt32)
