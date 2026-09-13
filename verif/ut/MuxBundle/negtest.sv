// 负测台：证明 xs_MuxBundle_core 的 source 空间等式真会拦下"基址抄错"。
// 把 SOURCE_BASE 从 4（预取 MSHR 接在 4 个取指 MSHR 后面）抄成 8。
// 位宽、入口数、逻辑全对，随机激励只会得到一整套偏移 4 的 source —— tb 若不比
// golden 就发现不了；这里由 source 空间等式 8+10 > 2^4 直接拦下。
module neg_mux_wrong_source_base;
  logic [9:0] in_valid, in_ready;
  logic [10*56-1:0] in_bits;
  logic out_valid;
  logic [55:0] out_bits;
  logic [3:0] out_source;
  xs_MuxBundle_core #(
    .WIDTH(56), .NUM_IN(10), .SEL_W(4), .SOURCE_W(4),
    .SOURCE_BASE(8),                    // <-- 抄错：golden 是 4
    .PORT_BITS_IN0(56), .PORT_BITS_OUT(56), .GOLDEN_PORTS(46), .IN_FIELDS(2)
  ) u_core (
    .sel(4'h0), .in_valid(in_valid), .in_ready(in_ready), .in_bits(in_bits),
    .out_ready(1'b0), .out_valid(out_valid), .out_bits(out_bits), .out_source(out_source)
  );
  initial begin
    in_valid = '0; in_bits = '0;
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下 source 基址抄错");
    $finish;
  end
endmodule

module neg_tb;
  neg_mux_wrong_source_base u_dut ();
endmodule
