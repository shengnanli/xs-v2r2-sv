// 负测台：证明 xs_PipeWithFlush_core 的 elaborate 期不变式真会拦下抄错。
//
// 用 +define+NEG_CASE_2 选第 2 个用例（不给就是第 1 个；Makefile 两个都跑）：
//   1  端口位宽抄错：PipeWithFlush_7 的 io_enq_bits_fuType 是 35 位，这里抄成 33 位。
//      载荷总位数变成 53，而 WIDTH 仍按 golden 的 55 传 -> PORT_BITS_IN != WIDTH。
//   2  级数抄错：PipeWithFlush_9（golden 3 级 / 168 个 reg 位）的 STAGES 抄成 2。
//      GOLDEN_REG_BITS 仍按 golden 数出来的 168 填 -> 2*(1+55) = 112 != 168。
//
// 两个用例都保持"其余参数是 golden 的真值"，只动一处 —— 负测要证的是
// **不变式能在只有一处错时就喊出来**，而不是"参数全错时它也会喊"。

`ifndef NEG_CASE_2
module neg_pwf_narrow_field(
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [32:0] io_enq_bits_fuType,   // <-- 抄错：golden 是 [34:0]
  input  [19:0] io_enq_bits_rest,
  output        io_deq_valid,
  output [34:0] io_deq_bits_fuType,
  output [19:0] io_deq_bits_rest
);
  localparam int unsigned STAGES          = 2;
  localparam int unsigned PAYLOAD_W       = 55;    // golden 端口表求和（正确值）
  localparam int unsigned GOLDEN_REG_BITS = 112;   // golden reg 声明求和（正确值）

  localparam int unsigned PORT_BITS_IN =
    $bits({io_enq_bits_fuType, io_enq_bits_rest});   // 抄错后只有 53
  localparam int unsigned PORT_BITS_OUT =
    $bits({io_deq_bits_fuType, io_deq_bits_rest});

  logic [PAYLOAD_W-1:0] payload_out;

  xs_PipeWithFlush_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .HAS_ROBIDX     (1),
    .LD_CNT         (0),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_redirect_valid(1'b0), .flush_redirect_level(1'b0),
    .flush_redirect_robidx(9'b0), .flush_ldcancel(1'b0), .flush_ogfail(1'b0),
    .enq_valid(io_enq_valid),
    .enq_bits (PAYLOAD_W'({io_enq_bits_fuType, io_enq_bits_rest})),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign {io_deq_bits_fuType, io_deq_bits_rest} = payload_out;
endmodule

module neg_tb;
  bit clock = 0;
  wire dv;
  wire [34:0] o_fuType;
  wire [19:0] o_rest;
  neg_pwf_narrow_field u_dut (
    .clock(clock), .reset(1'b1), .io_enq_valid(1'b0),
    .io_enq_bits_fuType(33'h0), .io_enq_bits_rest(20'h0),
    .io_deq_valid(dv), .io_deq_bits_fuType(o_fuType), .io_deq_bits_rest(o_rest)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下端口位宽抄错");
    $finish;
  end
endmodule
`else
module neg_pwf_wrong_stages(
  input         clock,
  input         reset,
  input         io_enq_valid,
  input  [54:0] io_enq_bits,
  output        io_deq_valid,
  output [54:0] io_deq_bits
);
  localparam int unsigned STAGES          = 2;    // <-- 抄错：PipeWithFlush_9 是 3 级
  localparam int unsigned PAYLOAD_W       = 55;
  localparam int unsigned GOLDEN_REG_BITS = 168;  // 从 golden 数出来的事实，不跟着抄错走

  localparam int unsigned PORT_BITS_IN  = $bits({io_enq_bits});
  localparam int unsigned PORT_BITS_OUT = $bits({io_deq_bits});

  logic [PAYLOAD_W-1:0] payload_out;

  xs_PipeWithFlush_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .HAS_ROBIDX     (1),
    .LD_CNT         (0),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_redirect_valid(1'b0), .flush_redirect_level(1'b0),
    .flush_redirect_robidx(9'b0), .flush_ldcancel(1'b0), .flush_ogfail(1'b0),
    .enq_valid(io_enq_valid),
    .enq_bits (io_enq_bits),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign io_deq_bits = payload_out;
endmodule

module neg_tb;
  bit clock = 0;
  wire dv;
  wire [54:0] o;
  neg_pwf_wrong_stages u_dut (
    .clock(clock), .reset(1'b1), .io_enq_valid(1'b0),
    .io_enq_bits(55'h0), .io_deq_valid(dv), .io_deq_bits(o)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下级数抄错");
    $finish;
  end
endmodule
`endif
