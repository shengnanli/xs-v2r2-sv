// 负测台：证明 xs_CLZ_core 的 elaborate 期不变式真会拦下抄错。
//
// 用 +define+NEG_CASE_2 选第 2 个用例（不给就是第 1 个；Makefile 两个都跑）：
//   1  端口位宽抄错：CLZ_9 的 io_in 是 32 位，这里抄成 31 位。
//      WIDTH 仍按 golden 的 32 传 -> PORT_BITS_IN=31 != WIDTH=32。
//   2  SCAN_LOW 抄错：CLZ 本体的 SCAN_LOW 是 1（golden 不读 io_in[0]），
//      这里抄成 0。于是 NONE 从 63 变成 64，而 io_out 只有 6 位装不下 64
//      -> OUT_W=6 != $clog2(65)=7。
//      ★这一条是本家族最要紧的负测★：SCAN_LOW 是看不见的参数，抄错以后
//      电路语义整个变了（全零输入从输出 63 变成输出 64 截断成 0），
//      而 UT 要不要撞上全零输入是运气问题。不变式必须在 elaborate 期就喊。

`ifndef NEG_CASE_2
module neg_clz_narrow_in(
  input  [30:0] io_in,    // <-- 抄错：CLZ_9 的 golden 是 [31:0]
  output [5:0]  io_out
);
  localparam int unsigned WIDTH    = 32;   // golden 事实（正确值）
  localparam int unsigned SCAN_LOW = 0;
  localparam int unsigned OUT_W    = 6;

  localparam int unsigned PORT_BITS_IN  = $bits(io_in);   // 抄错后只有 31
  localparam int unsigned PORT_BITS_OUT = $bits(io_out);

  xs_CLZ_core #(
    .WIDTH        (WIDTH),
    .SCAN_LOW     (SCAN_LOW),
    .OUT_W        (OUT_W),
    .PORT_BITS_IN (PORT_BITS_IN),
    .PORT_BITS_OUT(PORT_BITS_OUT)
  ) u_core (
    .d_in(WIDTH'(io_in)),
    .cnt (io_out)
  );
endmodule

module neg_tb;
  wire [5:0] o;
  neg_clz_narrow_in u_dut (.io_in(31'h0), .io_out(o));
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下端口位宽抄错");
    $finish;
  end
endmodule
`else
module neg_clz_wrong_scanlow(
  input  [63:0] io_in,
  output [5:0]  io_out
);
  localparam int unsigned WIDTH    = 64;
  localparam int unsigned SCAN_LOW = 0;    // <-- 抄错：CLZ 本体的 golden 是 1
  localparam int unsigned OUT_W    = 6;    // 从 golden 端口表读出来的事实，不跟着抄错走

  localparam int unsigned PORT_BITS_IN  = $bits(io_in);
  localparam int unsigned PORT_BITS_OUT = $bits(io_out);

  xs_CLZ_core #(
    .WIDTH        (WIDTH),
    .SCAN_LOW     (SCAN_LOW),
    .OUT_W        (OUT_W),
    .PORT_BITS_IN (PORT_BITS_IN),
    .PORT_BITS_OUT(PORT_BITS_OUT)
  ) u_core (
    .d_in(io_in),
    .cnt (io_out)
  );
endmodule

module neg_tb;
  wire [5:0] o;
  neg_clz_wrong_scanlow u_dut (.io_in(64'h0), .io_out(o));
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下 SCAN_LOW 抄错");
    $finish;
  end
endmodule
`endif
