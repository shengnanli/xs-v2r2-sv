// 负测台：证明 xs_DelayNWithValid_core 的位宽等式真会拦下"载荷位宽抄错"。
// 场景：DelayNWithValid_1 的 tailSlot_lower 是 20 位，这里抄成 18 位。
// GOLDEN_DATA_REG_BITS 仍按 golden 的 120 填（因为那是从 golden 数出来的事实），
// 于是 PAYLOAD_W=60 而端口拼接只有 58 位 —— 逻辑一行不改，UT 按抄错的位宽驱动
// 也测不出来。期望：PORT_BITS_IN=58 != WIDTH=60，time 0 $fatal。
module neg_dnv_narrow_field(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [17:0] io_in_bits_tailSlot_lower,   // <-- 抄错：golden 是 [19:0]
  input  [39:0] io_in_bits_rest,
  output [19:0] io_out_bits_tailSlot_lower,
  output [39:0] io_out_bits_rest
);
  localparam int unsigned GOLDEN_DATA_REG_BITS = 120;
  localparam int unsigned PAYLOAD_W            = GOLDEN_DATA_REG_BITS / 2;

  localparam int unsigned PORT_BITS_IN =
    $bits({io_in_bits_tailSlot_lower, io_in_bits_rest});
  localparam int unsigned PORT_BITS_OUT =
    $bits({io_out_bits_tailSlot_lower, io_out_bits_rest});

  logic [PAYLOAD_W-1:0] payload_out;

  xs_DelayNWithValid_core #(
    .WIDTH               (PAYLOAD_W),
    .GOLDEN_DATA_REG_BITS(GOLDEN_DATA_REG_BITS),
    .PORT_BITS_IN        (PORT_BITS_IN),
    .PORT_BITS_OUT       (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (PAYLOAD_W'({io_in_bits_tailSlot_lower, io_in_bits_rest})),
    .d_out   (payload_out)
  );

  assign {io_out_bits_tailSlot_lower, io_out_bits_rest} = payload_out;
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
    $display("NEGTEST_UNREACHED: 不变式没有拦下位宽抄错");
    $finish;
  end
endmodule
