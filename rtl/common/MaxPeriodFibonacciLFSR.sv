// =============================================================================
// MaxPeriodFibonacciLFSR —— 15 位最大周期 Fibonacci 线性反馈移位寄存器
//
// 对应 Chisel: chisel3.util.random.MaxPeriodFibonacciLFSR(15)（经 LFSR(15) 调用）。
// 在 BPU 里它是"分配时挑哪一张表"的伪随机源：Tage_SC 两份（allocLFSR，每个
// 预测槽一份）、ITTage 一份（s2_allocLFSR）。上层只读 io_out 的若干位。
//
// 机制：Fibonacci 结构 = 一条移位链，新位从 state[0] 移入，其余逐位右移
// （state[i] <= state[i-1]）。反馈多项式取 Chisel LFSR 表里 15 位的最大周期抽头
// {15, 14}，即 x^15 + x^14 + 1，于是新位 = state[13] ^ state[14]，周期 2^15-1。
// 移位方向 / 抽头位置与 golden 逐位一致（golden 本体就是 15 行 state_k <= state_{k-1}）。
//
// 复位：异步高有效，复位值 = seed 1（state[0]=1，其余 0）—— Chisel 默认 seed
// 为 Some(1)，保证 LFSR 不会落在全 0 锁死态。无使能端（increment = true.B），
// 每拍都走一步。io_out 直接是当前状态。
//
// 参数化核 xs_MaxPeriodFibonacciLFSR_core 只依赖位宽与抽头掩码，留给
// 其他位宽的变体（如 16 位的 MaxPeriodFibonacciLFSR_3）复用；本文件只有 15 位一档。
// =============================================================================
module xs_MaxPeriodFibonacciLFSR_core #(
  parameter int unsigned            WIDTH    = 15,
  // TAP_MASK[k]=1 表示 state[k] 参与反馈异或（state 下标从 0 起）
  parameter logic [WIDTH-1:0]       TAP_MASK = 15'b110_0000_0000_0000,
  parameter logic [WIDTH-1:0]       SEED     = 15'd1
)(
  input  logic             clock,
  input  logic             reset,
  output logic [WIDTH-1:0] state_q
);

  logic feedback;
  assign feedback = ^(state_q & TAP_MASK);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) state_q <= SEED;
    else       state_q <= {state_q[WIDTH-2:0], feedback};
  end

endmodule

module MaxPeriodFibonacciLFSR(
  input  clock,
  input  reset,
  output io_out_0,
  output io_out_1,
  output io_out_2,
  output io_out_3,
  output io_out_4,
  output io_out_5,
  output io_out_6,
  output io_out_7,
  output io_out_8,
  output io_out_9,
  output io_out_10,
  output io_out_11,
  output io_out_12,
  output io_out_13,
  output io_out_14
);

  logic [14:0] state;

  xs_MaxPeriodFibonacciLFSR_core #(
    .WIDTH    (15),
    .TAP_MASK (15'b110_0000_0000_0000),  // 抽头 {15,14} -> state[14] ^ state[13]
    .SEED     (15'd1)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .state_q (state)
  );

  assign {io_out_14, io_out_13, io_out_12, io_out_11, io_out_10,
          io_out_9,  io_out_8,  io_out_7,  io_out_6,  io_out_5,
          io_out_4,  io_out_3,  io_out_2,  io_out_1,  io_out_0} = state;

endmodule
