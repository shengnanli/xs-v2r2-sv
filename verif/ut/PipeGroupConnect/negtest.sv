// negtest.sv —— xs_PipeGroupConnect_slot 的 G1 锚点不变式必失败负测（由 scripts/gen_cb_connect.py 生成，勿手改）。
//   NEG_NARROW    payload 比 G1 锚点少 1 位（"位宽停在旧基线"这一类真实故障的最小复现）
//   NEG_NO_ANCHOR 不传 G1 锚点（老 fail-open：不传即不校验）
// 判据：两个都必须在 VCS elaborate 期非零退出（Error-[FEST]）。
module neg_probe;
  logic clock = 0;
`ifdef NEG_NARROW
  xs_PipeGroupConnect_slot #(.W(7), .W_G1(8)) u_dut (.clock(clock), .fire(1'b0), .io_in_bits('0), .io_out_bits());
`elsif NEG_NO_ANCHOR
  xs_PipeGroupConnect_slot #(.W(8)) u_dut (.clock(clock), .fire(1'b0), .io_in_bits('0), .io_out_bits());
`else
  initial $fatal(1, "negtest.sv must be compiled with +define+NEG_NARROW or +define+NEG_NO_ANCHOR");
`endif
  initial begin
    #1 $display("NEG_ESCAPED: wrong parameter elaborated -- the anchor check is a no-op");
    $finish;
  end
endmodule
