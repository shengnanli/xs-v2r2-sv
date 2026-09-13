// 负测台：证明 xs_PipelineConnect 的 G1 锚点不变式**真的**拦得住，而且
// 「不传锚点」不再等于「不校验」（老的 fail-open 已封）。
//
// 对照原型 = NewPipelineConnectPipe_25（golden io_in_bits_* 端口位数之和 = 124）。
//   +define+NEG_PC_NARROW     payload 打包成 123 位（某一项抄少 1 位的典型形态：
//        逻辑一行不改，UT 驱动低位照样全绿，只有 FM 才炸）。
//        期望命中「payload 打包出来 123 位 != G1 golden 逐项位数之和 124 位」。
//   +define+NEG_PC_NO_ANCHOR  不传 PAYLOAD_W_G1 —— 期望命中 fail-closed 那条。
//        （改造前这个 case 会**静静通过**，因为默认值就是 DATA_WIDTH 自己。）
//
// 判据：两个都必须让 VCS 在 elaborate 期非零退出（Error-[FEST]）。
// 链接成功、跑出 NEGTEST_UNREACHED = 不变式形同虚设，判 FAIL。
module neg_pc_probe;
`ifdef NEG_PC_NARROW
  localparam int unsigned DW = 123;   // <-- 抄错：golden 逐项位数之和是 124
`else
  localparam int unsigned DW = 124;
`endif

  logic clock = 1'b0, reset = 1'b0;
  logic [DW-1:0] in_bits = '0, out_bits;
  logic in_ready, out_valid;

  xs_PipelineConnect #(
    .DATA_WIDTH(DW)
`ifndef NEG_PC_NO_ANCHOR
    , .PAYLOAD_W_G1(124)
`endif
  ) u_core (
    .clock(clock), .reset(reset),
    .io_in_ready(in_ready), .io_in_valid(1'b0), .io_in_bits(in_bits),
    .io_out_ready(1'b0), .io_out_valid(out_valid), .io_out_bits(out_bits),
    .io_rightOutFire(1'b0), .io_isFlush(1'b0)
  );

  initial begin
    $display("NEGTEST_UNREACHED: 抄错的 payload 位数没有被 elaborate 期不变式拦下");
    $finish;
  end
endmodule
