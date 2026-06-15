// =============================================================================
// RVCExpander UT —— golden(RVCExpander) vs 可读核(xs_RVCExpander_core) 双例化比对
//
// RVCExpander 是纯组合的 RVC→32 位展开器，输入空间小（待展开的 RVC 在低 16 位，
// fsIsOff 1 位），适合近乎穷举：
//   1) 穷举低 16 位（0..65535）× fsIsOff∈{0,1}，高 16 位随机化（高位仅在 op=11
//      透传时影响输出，随机化即可覆盖透传路径）。
//   2) 额外补一批纯随机 32 位向量（再次覆盖透传 + 随机高位组合）。
// 每个激励逐拍比对 io_out_bits(32) 与 io_ill(1)。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int errors = 0;
  longint checks = 0;

  logic [31:0] io_in;
  logic        io_fsIsOff;

  logic [31:0] g_out, i_out;
  logic        g_ill, i_ill;

  // golden（Chisel 生成的参考实现）
  RVCExpander u_g (
    .io_in       (io_in),
    .io_fsIsOff  (io_fsIsOff),
    .io_out_bits (g_out),
    .io_ill      (g_ill)
  );

  // 可读重写核（直接例化，端口同形）
  xs_RVCExpander_core u_i (
    .io_in       (io_in),
    .io_fsIsOff  (io_fsIsOff),
    .io_out_bits (i_out),
    .io_ill      (i_ill)
  );

  task automatic check();
    #1;
    checks++;
    if (g_out !== i_out) begin
      errors++;
      if (errors <= 30)
        $display("MISMATCH out: in=%h fsOff=%b  golden=%h impl=%h",
                 io_in, io_fsIsOff, g_out, i_out);
    end
    if (g_ill !== i_ill) begin
      errors++;
      if (errors <= 30)
        $display("MISMATCH ill: in=%h fsOff=%b  golden=%b impl=%b",
                 io_in, io_fsIsOff, g_ill, i_ill);
    end
  endtask

  initial begin
    // ---- 1) 穷举低 16 位 × fsIsOff，高 16 位随机 ----
    for (int fs = 0; fs < 2; fs++) begin
      io_fsIsOff = fs[0];
      for (int low = 0; low < 65536; low++) begin
        io_in = {$urandom(), 16'h0} | low;  // 高 16 随机，低 16 = 穷举值
        check();
      end
    end

    // ---- 2) 额外纯随机 32 位向量（覆盖透传与随机高位）----
    for (int t = 0; t < 200000; t++) begin
      io_in      = {$urandom(), $urandom()};
      io_fsIsOff = $urandom() & 1;
      check();
    end

    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 100000) $display("TEST PASSED");
    else                                $display("TEST FAILED");
    $finish;
  end
endmodule
