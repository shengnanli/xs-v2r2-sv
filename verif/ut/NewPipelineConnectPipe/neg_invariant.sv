// 参数不变式负测：故意用错误参数例化 xs_PipelineConnect。
//
// 正测（tb.sv）只能证明「参数对的时候功能对」，证明不了「参数错的时候会被发现」。
// 这个负测把 DATA_WIDTH 与 PAYLOAD_W_G1 故意配成不一致（8 vs 9），期望核里的
// initial 自检 $fatal。由 `make neg` 驱动，**仿真必须炸**才算通过；跑到
// NEG_ESCAPED 那一行就说明闸失效了。
`timescale 1ns/1ps
module neg_tb;
  logic        clock = 1'b0;
  logic        reset = 1'b1;
  logic        in_ready, out_valid;
  logic [7:0]  out_bits;

  always #5 clock = ~clock;

  // 故意写错：payload 实际 8 位，却声称 G1 字段位宽之和是 9 位。
  xs_PipelineConnect #(
    .DATA_WIDTH   (8),
    .PAYLOAD_W_G1 (9)
  ) u_bad (
    .clock           (clock),
    .reset           (reset),
    .io_in_ready     (in_ready),
    .io_in_valid     (1'b0),
    .io_in_bits      (8'h00),
    .io_out_ready    (1'b1),
    .io_out_valid    (out_valid),
    .io_out_bits     (out_bits),
    .io_rightOutFire (1'b0),
    .io_isFlush      (1'b0)
  );

  initial begin
    repeat (20) @(posedge clock);
    $display("NEG_ESCAPED: 不变式没有触发 —— 错误参数溜过去了");
    $finish;
  end
endmodule
