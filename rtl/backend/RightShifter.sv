// RightShifter —— 64 位可配置填充值的右移桶形网络。
// shiftNum 的每一位依次控制 1/2/4/8/16/32 位移位级；右侧丢弃低位，
// 左侧全部用 msb 填充。因此 msb=0 时是逻辑右移，msb=1 时等价于
// 把输入视为负数所做的算术右移，但填充值由调用者显式给出。

module xs_RightShifter_core (
  input  logic [5:0]  shift_amount,
  input  logic [63:0] operand,
  input  logic        fill_bit,
  output logic [63:0] shifted
);
  logic [63:0] shift_1;
  logic [63:0] shift_2;
  logic [63:0] shift_4;
  logic [63:0] shift_8;
  logic [63:0] shift_16;

  assign shift_1  = shift_amount[0] ? {fill_bit, operand[63:1]} : operand;
  assign shift_2  = shift_amount[1] ? {{2{fill_bit}}, shift_1[63:2]} : shift_1;
  assign shift_4  = shift_amount[2] ? {{4{fill_bit}}, shift_2[63:4]} : shift_2;
  assign shift_8  = shift_amount[3] ? {{8{fill_bit}}, shift_4[63:8]} : shift_4;
  assign shift_16 = shift_amount[4] ? {{16{fill_bit}}, shift_8[63:16]} : shift_8;
  assign shifted  = shift_amount[5] ? {{32{fill_bit}}, shift_16[63:32]} : shift_16;
endmodule


module RightShifter (
  input  logic [5:0]  io_shiftNum,
  input  logic [63:0] io_in,
  input  logic        io_msb,
  output logic [63:0] io_out
);
  xs_RightShifter_core u_core (
    .shift_amount(io_shiftNum),
    .operand     (io_in),
    .fill_bit    (io_msb),
    .shifted     (io_out)
  );
endmodule
