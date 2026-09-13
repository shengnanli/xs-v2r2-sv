// 负测台：证明 xs_FIFOReg_core 的指针位宽等式真会拦下"深度抄错"。
// 把 DEPTH 从 10 抄成 8（4 位指针恰好能装 0..7，看起来"更整齐"），
// PTR_W 仍按 golden 的 4 位填。逻辑一行不改、位宽全对，UT 也只会少测两个槽位。
// 期望：PTR_W=4 != clog2(8)=3，time 0 $fatal。
module neg_fifo_wrong_depth;
  bit clock = 0;
  wire enq_ready, deq_valid;
  wire [3:0] deq_bits;
  xs_FIFOReg_core #(
    .WIDTH(4), .DEPTH(8), .PTR_W(4),      // <-- 抄错：golden 是 10 深
    .PORT_BITS_ENQ(4), .PORT_BITS_DEQ(4), .GOLDEN_PORTS(9)
  ) u_core (
    .clock(clock), .reset(1'b1), .flush(1'b0),
    .enq_ready(enq_ready), .enq_valid(1'b0), .enq_bits(4'h0),
    .deq_ready(1'b0), .deq_valid(deq_valid), .deq_bits(deq_bits)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下深度抄错");
    $finish;
  end
endmodule

module neg_tb;
  neg_fifo_wrong_depth u_dut ();
endmodule
