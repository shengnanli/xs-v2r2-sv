// Serializer 双例化 UT（手写 tb，不走 gen.py：本模块没有任何输出端口，dual_tb_lib 无从比较）。
//
// golden Serializer 只剩 clock/reset 两个端口，内部一个死指针 enqPtrExt_0 {flag 1 位, value 4 位}。
// 两侧都无输出可比，所以本 tb 用**层次探针 + 状态注入**直接比次态函数：
//   每拍 negedge 先比两侧当前指针（上一拍注入值经同一个 posedge 推出的次态），
//   再给两侧注入**同一个**随机指针值（force/release，32 种取值里 value>=12 的回绕区占 1/4 以上），
//   下一个 posedge 两侧各自算次态。这样 32 个状态的次态函数每个都被比过成千上万次，
//   而不是只看到复位后永远停在 (0,0) 的那一个。另有 1/50 拍拉 reset 比异步复位。
// 判据：两侧 {flag, value} 每拍 !== 即记错；覆盖闸：32 种注入值各 >= 200 次、回绕（flag 翻转）>= 200 次。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc;
  int unsigned seen[32];
  int unsigned wraps = 0, resets = 0;
  logic clk = 1'b0;
  logic rst;
  always #5 clk = ~clk;

  Serializer    u_gold (.clock(clk), .reset(rst));
  Serializer_xs u_impl (.clock(clk), .reset(rst));

  logic [4:0] g_ptr, i_ptr, inj;
  assign g_ptr = {u_gold.enqPtrExt_0_flag, u_gold.enqPtrExt_0_value};
  assign i_ptr = {u_impl.u_core.enq_flag, u_impl.u_core.enq_value};

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (4) @(posedge clk);
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      checks++;
      if (g_ptr !== i_ptr) begin
        errors++;
        if (errors <= 20) $display("[MISMATCH] cyc=%0d g={%b,%0d} i={%b,%0d}",
                                   cyc, g_ptr[4], g_ptr[3:0], i_ptr[4], i_ptr[3:0]);
      end
      if (g_ptr[4] != inj[4] && !rst && cyc > 0) wraps++;
      rst = ($urandom_range(0, 49) == 0);
      if (rst) resets++;
      inj = 5'($urandom);
      seen[inj]++;
      force u_gold.enqPtrExt_0_flag  = inj[4];
      force u_gold.enqPtrExt_0_value = inj[3:0];
      force u_impl.u_core.enq_flag   = inj[4];
      force u_impl.u_core.enq_value  = inj[3:0];
      #1;
      release u_gold.enqPtrExt_0_flag;
      release u_gold.enqPtrExt_0_value;
      release u_impl.u_core.enq_flag;
      release u_impl.u_core.enq_value;
    end
    for (int k = 0; k < 32; k++)
      if (seen[k] < 200) begin cov_fail++; $display("[COV] 注入值 %0d 只出现 %0d 次", k, seen[k]); end
    $display("[COV] wraps(flag 翻转)=%0d resets=%0d", wraps, resets);
    if (wraps < 200) begin cov_fail++; $display("[COV] wraps < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
