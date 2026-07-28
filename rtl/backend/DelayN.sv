// =============================================================================
// DelayN 家族 —— 可读核 + golden 同名 wrapper。
//
// golden DelayN_15 / DelayN_17 (来自 CtrlBlock, 经 CIRCT firtool dedup 命名) 都是
// 纯 1-bit 移位延迟链, 只是深度不同:
//   DelayN_15 : 4 级 (REG..REG_3), io_out = REG_3
//   DelayN_17 : 5 级 (REG..REG_4), io_out = REG_4
// 后缀数字仅是 firtool 的 dedup id, 与延迟拍数无关。
//
// 本文件提供一个参数化的 xs_delayn_core (WIDTH x N 深移位链), 并用 golden 同名的
// 薄 wrapper 例化, 供 FM 逐位等价 + UT 双例化对拍。无 _GEN_/_T_ 噪声。
// =============================================================================

// 参数化 N 级移位延迟链。级数 N>=1, 位宽 WIDTH>=1。
module xs_delayn_core #(
    parameter int WIDTH = 1,
    parameter int N     = 5
) (
    input                    clock,
    input      [WIDTH-1:0]   io_in,
    output     [WIDTH-1:0]   io_out
);
  // N 级流水寄存器: stages[0] 采样 io_in, stages[k] 采样 stages[k-1]。
  logic [WIDTH-1:0] stages [N];
  always_ff @(posedge clock) begin
    stages[0] <= io_in;
    for (int k = 1; k < N; k++) stages[k] <= stages[k-1];
  end
  assign io_out = stages[N-1];
endmodule

// golden 同名 wrapper: DelayN_1 = 2 级 1-bit (REG, REG_1; io_out=REG_1)。
module DelayN_1(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(2)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule

// golden 同名 wrapper: DelayN_15 = 4 级 1-bit。
module DelayN_15(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(4)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule

// golden 同名 wrapper: DelayN_17 = 5 级 1-bit。
module DelayN_17(
  input  clock,
  input  io_in,
  output io_out
);
  xs_delayn_core #(.WIDTH(1), .N(5)) u_core (
    .clock(clock), .io_in(io_in), .io_out(io_out));
endmodule
