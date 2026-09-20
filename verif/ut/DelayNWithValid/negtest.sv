// 负测台：证明 xs_DelayNWithValid_core 的 elaborate 期不变式真会拦下抄错。
//
// ★这个文件自己就当过一次反面教材★：它原先写的是
//     xs_DelayNWithValid_core #( .GOLDEN_DATA_REG_BITS(120), ... )
// 而核早已把这个参数改名成 GOLDEN_REG_BITS。VCS 对「覆盖一个不存在的参数」只给
// 一条 `Warning-[AOUP] ... will be ignored`，于是 GOLDEN_REG_BITS 取默认值
// （= VALID_CHAIN + STAGES*WIDTH），守恒等式变成恒真 —— 负测**照样报 PASSED**，
// 但它当时证明的只是 PORT_BITS 那一条，守恒等式那一条根本没被测到。
// 负测自己被静默解除武装，是最难发现的一种假绿：它每次都是绿的。
// 现在两条不变式各有一个用例，参数名与核保持一致。
//
// 用 +define+NEG_CASE_2 选第 2 个用例（不给就是第 1 个；Makefile 两个都跑）：
//   1  端口位宽抄错：DelayNWithValid_1 的 tailSlot_lower 是 20 位，这里抄成 18 位。
//      载荷总位数变成 58，而 WIDTH 仍按 60 传 -> PORT_BITS_IN != WIDTH。
//   2  级数抄错：DelayNWithValid（golden 2 级 / 101 个 reg 位）的 STAGES 抄成 3。
//      GOLDEN_REG_BITS 仍按 golden 数出来的 101 填 -> 1 + 3*50 = 151 != 101。
//      ★这一条只有在参数名对得上时才会响★ —— 就是上面那次事故漏掉的那条。

`ifndef NEG_CASE_2
module neg_dnv_narrow_field(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [17:0] io_in_bits_tailSlot_lower,   // <-- 抄错：golden 是 [19:0]
  input  [39:0] io_in_bits_rest,
  output [19:0] io_out_bits_tailSlot_lower,
  output [39:0] io_out_bits_rest
);
  localparam int unsigned STAGES          = 2;
  localparam int unsigned VALID_CHAIN     = 1;
  localparam int unsigned PAYLOAD_W       = 60;    // golden 端口表求和（正确值）
  localparam int unsigned GOLDEN_REG_BITS = 121;   // golden reg 声明求和（正确值）

  localparam int unsigned PORT_BITS_IN =
    $bits({io_in_bits_tailSlot_lower, io_in_bits_rest});   // 抄错后只有 58
  localparam int unsigned PORT_BITS_OUT =
    $bits({io_out_bits_tailSlot_lower, io_out_bits_rest});

  logic [PAYLOAD_W-1:0] payload_out;

  xs_DelayNWithValid_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .VALID_CHAIN    (VALID_CHAIN),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (PAYLOAD_W'({io_in_bits_tailSlot_lower, io_in_bits_rest})),
    .d_out   (payload_out),
    .out_valid()
  );

  assign {io_out_bits_tailSlot_lower, io_out_bits_rest} = payload_out[59:0];
endmodule

module neg_tb;
  bit clock = 0;
  wire [19:0] o_lower;
  wire [39:0] o_rest;
  neg_dnv_narrow_field u_dut (
    .clock(clock), .reset(1'b1), .io_in_valid(1'b0),
    .io_in_bits_tailSlot_lower(18'h0), .io_in_bits_rest(40'h0),
    .io_out_bits_tailSlot_lower(o_lower), .io_out_bits_rest(o_rest)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下端口位宽抄错");
    $finish;
  end
endmodule
`else
module neg_dnv_wrong_stages(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [49:0] io_in_bits,
  output [49:0] io_out_bits
);
  localparam int unsigned STAGES          = 3;    // <-- 抄错：golden DelayNWithValid 是 2 级
  localparam int unsigned VALID_CHAIN     = 1;
  localparam int unsigned PAYLOAD_W       = 50;
  localparam int unsigned GOLDEN_REG_BITS = 101;  // 从 golden 数出来的事实，不跟着抄错走

  localparam int unsigned PORT_BITS_IN  = $bits({io_in_bits});
  localparam int unsigned PORT_BITS_OUT = $bits({io_out_bits});

  logic [PAYLOAD_W-1:0] payload_out;

  xs_DelayNWithValid_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .VALID_CHAIN    (VALID_CHAIN),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (io_in_bits),
    .d_out   (payload_out),
    .out_valid()
  );

  assign io_out_bits = payload_out;
endmodule

module neg_tb;
  bit clock = 0;
  wire [49:0] o_bits;
  neg_dnv_wrong_stages u_dut (
    .clock(clock), .reset(1'b1), .io_in_valid(1'b0),
    .io_in_bits(50'h0), .io_out_bits(o_bits)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下级数抄错");
    $finish;
  end
endmodule
`endif
