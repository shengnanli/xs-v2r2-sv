// 负测台：证明 xs_FixedPriorityArbiter_core 的端口数恒等式真会拦下"入口数抄错"。
// 这里直接用 Arbiter5_MSHRAcquire 的真实规模（26 个端口、14 根载荷端口），
// 但把 NUM_IN 抄成 4 —— 少数一路。载荷位宽全对、逻辑一行不改，
// 随机激励只会少测一路，不会报错。期望：26 != 2*4+2+14 = 24，time 0 $fatal。
module neg_arb_wrong_numin;
  logic [3:0]  in_valid, in_ready;
  logic [4*60-1:0] in_bits;
  logic out_valid;
  logic [59:0] out_bits;
  xs_FixedPriorityArbiter_core #(
    .WIDTH(60), .NUM_IN(4),          // <-- 抄错：Arbiter5 有 5 路
    .PORT_BITS_OUT(60), .PORT_BITS_LAST_IN(60),
    .GOLDEN_PORTS(26), .GOLDEN_BITS_PORTS(14)
  ) u_core (
    .in_valid(in_valid), .in_ready(in_ready), .in_bits(in_bits),
    .out_ready(1'b1), .out_valid(out_valid), .out_bits(out_bits)
  );
  initial begin
    in_valid = '0; in_bits = '0;
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下入口数抄错");
    $finish;
  end
endmodule

module neg_tb;
  neg_arb_wrong_numin u_dut ();
endmodule
