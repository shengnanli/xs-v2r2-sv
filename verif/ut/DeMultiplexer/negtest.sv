// 负测台：证明 xs_DeMultiplexer_core 的端口数恒等式真会拦下"出口数抄错"。
// 用 DeMultiplexer_1 的真实规模（45 个端口、chosen 4 位），但把 NUM_OUT 抄成 8。
// 载荷位宽全对、逻辑一行不改，随机激励只会少测两路，不会报错。
// 期望：45 != 2+2+8*(2+2)+1 = 37，time 0 $fatal。
module neg_demux_wrong_numout;
  logic [7:0] out_ready, out_valid;
  logic [8*50-1:0] out_bits;
  logic in_ready;
  logic [3:0] chosen;
  xs_DeMultiplexer_core #(
    .WIDTH(50), .NUM_OUT(8), .CHOSEN_W(4),   // <-- 抄错：DeMultiplexer_1 有 10 个出口
    .PORT_BITS_IN(50), .PORT_BITS_OUT0(50), .HAS_CHOSEN(1'b1),
    .GOLDEN_PORTS(45), .GOLDEN_FIELDS(2)
  ) u_core (
    .in_valid(1'b0), .in_ready(in_ready), .in_bits(50'h0),
    .out_ready(out_ready), .out_valid(out_valid), .out_bits(out_bits), .chosen(chosen)
  );
  initial begin
    out_ready = '0;
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下出口数抄错");
    $finish;
  end
endmodule

module neg_tb;
  neg_demux_wrong_numout u_dut ();
endmodule
