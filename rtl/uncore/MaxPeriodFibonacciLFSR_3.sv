// MaxPeriodFibonacciLFSR_3 —— 16bit 最大周期 Fibonacci LFSR(可读重写)。
// 反馈抽头 {15,13,12,10}(异或), 每拍右移入反馈位; 复位态 0x0001(非全零, 保证非退化)。
// L2 SubDirectory 的替换随机源。io_out_N = state[N]。
module MaxPeriodFibonacciLFSR_3 (
  input  clock,
  input  reset,
  output io_out_0,  output io_out_1,  output io_out_2,  output io_out_3,
  output io_out_4,  output io_out_5,  output io_out_6,  output io_out_7,
  output io_out_8,  output io_out_9,  output io_out_10, output io_out_11,
  output io_out_12, output io_out_13, output io_out_14, output io_out_15
);
  reg  [15:0] state;
  // Fibonacci 反馈: 抽头 15/13/12/10 异或
  wire feedback = state[15] ^ state[13] ^ state[12] ^ state[10];

  always @(posedge clock or posedge reset)
    if (reset) state <= 16'h0001;          // state_0=1, 其余 0
    else       state <= {state[14:0], feedback};  // state[0]<=feedback, state[N]<=state[N-1]

  assign io_out_0  = state[0];
  assign io_out_1  = state[1];
  assign io_out_2  = state[2];
  assign io_out_3  = state[3];
  assign io_out_4  = state[4];
  assign io_out_5  = state[5];
  assign io_out_6  = state[6];
  assign io_out_7  = state[7];
  assign io_out_8  = state[8];
  assign io_out_9  = state[9];
  assign io_out_10 = state[10];
  assign io_out_11 = state[11];
  assign io_out_12 = state[12];
  assign io_out_13 = state[13];
  assign io_out_14 = state[14];
  assign io_out_15 = state[15];
endmodule
