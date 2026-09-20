// 自动生成：verif/ut/CLZ/gen.py（读 G1 golden）—— 勿手改
// CLZ 家族 9 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_CLZ_core 设不同 WIDTH / SCAN_LOW / OUT_W）。
// 被测语义：从最高位往下找第一个 1，输出它前面有几个 0；扫描范围内没有 1 时
//   输出 NONE = WIDTH - SCAN_LOW。纯组合，无寄存器，故不需要热身窗口。
//
// ★SCAN_LOW=1 的那个变体（CLZ 本体）必须被这个 tb 真的打到★
//   它不读 io_in[0]：全零输入与"只有第 0 位是 1"输出**相同**（都是 63）。
//   激励里专门有"全零"和"单点 one-hot 到每一位"两种模式，覆盖闸再要求
//   **每一个可能的输出值都被观察到**（0..NONE 全见），这两件事才算被证到。
//
// 激励每拍按 8 种模式之一：全零 / 全一 / 随机 one-hot / **指定前导零个数**
//   （清掉最高 k 位再把第 WIDTH-1-k 位置 1，于是输出确定等于 k）/ 全随机。
//   第 4 种是覆盖闸能在 20 万拍内填满 0..64 的原因，不靠运气。
// 覆盖闸：每个变体都要 (1) 比对次数 >= COV_MIN；(2) **0..NONE 每个输出值都见过**；
//   (3) 全零输入至少 COV_MIN 次；(4) 输入每一位都见过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  // ---- CLZ: WIDTH=64 OUT_W=6 SCAN_LOW=1 NONE=63 ----
  logic [63:0] c0_in;
  wire  [5:0] g_c0_out, i_c0_out;
  logic [63:0] c0_ones, c0_zeros;
  logic [63:0] c0_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c0_checks, c0_zero_in;
  CLZ u_g_c0 (.io_in(c0_in), .io_out(g_c0_out));
  CLZ_xs u_i_c0 (.io_in(c0_in), .io_out(i_c0_out));

  // ---- CLZ_6: WIDTH=64 OUT_W=7 SCAN_LOW=0 NONE=64 ----
  logic [63:0] c1_in;
  wire  [6:0] g_c1_out, i_c1_out;
  logic [63:0] c1_ones, c1_zeros;
  logic [64:0] c1_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c1_checks, c1_zero_in;
  CLZ_6 u_g_c1 (.io_in(c1_in), .io_out(g_c1_out));
  CLZ_6_xs u_i_c1 (.io_in(c1_in), .io_out(i_c1_out));

  // ---- CLZ_7: WIDTH=16 OUT_W=5 SCAN_LOW=0 NONE=16 ----
  logic [15:0] c2_in;
  wire  [4:0] g_c2_out, i_c2_out;
  logic [15:0] c2_ones, c2_zeros;
  logic [16:0] c2_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c2_checks, c2_zero_in;
  CLZ_7 u_g_c2 (.io_in(c2_in), .io_out(g_c2_out));
  CLZ_7_xs u_i_c2 (.io_in(c2_in), .io_out(i_c2_out));

  // ---- CLZ_9: WIDTH=32 OUT_W=6 SCAN_LOW=0 NONE=32 ----
  logic [31:0] c3_in;
  wire  [5:0] g_c3_out, i_c3_out;
  logic [31:0] c3_ones, c3_zeros;
  logic [32:0] c3_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c3_checks, c3_zero_in;
  CLZ_9 u_g_c3 (.io_in(c3_in), .io_out(g_c3_out));
  CLZ_9_xs u_i_c3 (.io_in(c3_in), .io_out(i_c3_out));

  // ---- CLZ_11: WIDTH=8 OUT_W=4 SCAN_LOW=0 NONE=8 ----
  logic [7:0] c4_in;
  wire  [3:0] g_c4_out, i_c4_out;
  logic [7:0] c4_ones, c4_zeros;
  logic [8:0] c4_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c4_checks, c4_zero_in;
  CLZ_11 u_g_c4 (.io_in(c4_in), .io_out(g_c4_out));
  CLZ_11_xs u_i_c4 (.io_in(c4_in), .io_out(i_c4_out));

  // ---- CLZ_28: WIDTH=10 OUT_W=4 SCAN_LOW=0 NONE=10 ----
  logic [9:0] c5_in;
  wire  [3:0] g_c5_out, i_c5_out;
  logic [9:0] c5_ones, c5_zeros;
  logic [10:0] c5_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c5_checks, c5_zero_in;
  CLZ_28 u_g_c5 (.io_in(c5_in), .io_out(g_c5_out));
  CLZ_28_xs u_i_c5 (.io_in(c5_in), .io_out(i_c5_out));

  // ---- CLZ_29: WIDTH=23 OUT_W=5 SCAN_LOW=0 NONE=23 ----
  logic [22:0] c6_in;
  wire  [4:0] g_c6_out, i_c6_out;
  logic [22:0] c6_ones, c6_zeros;
  logic [23:0] c6_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c6_checks, c6_zero_in;
  CLZ_29 u_g_c6 (.io_in(c6_in), .io_out(g_c6_out));
  CLZ_29_xs u_i_c6 (.io_in(c6_in), .io_out(i_c6_out));

  // ---- CLZ_30: WIDTH=11 OUT_W=4 SCAN_LOW=0 NONE=11 ----
  logic [10:0] c7_in;
  wire  [3:0] g_c7_out, i_c7_out;
  logic [10:0] c7_ones, c7_zeros;
  logic [11:0] c7_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c7_checks, c7_zero_in;
  CLZ_30 u_g_c7 (.io_in(c7_in), .io_out(g_c7_out));
  CLZ_30_xs u_i_c7 (.io_in(c7_in), .io_out(i_c7_out));

  // ---- CLZ_31: WIDTH=24 OUT_W=5 SCAN_LOW=0 NONE=24 ----
  logic [23:0] c8_in;
  wire  [4:0] g_c8_out, i_c8_out;
  logic [23:0] c8_ones, c8_zeros;
  logic [24:0] c8_seen;   // 见过的输出值（位 v = 输出过 v）
  int   c8_checks, c8_zero_in;
  CLZ_31 u_g_c8 (.io_in(c8_in), .io_out(g_c8_out));
  CLZ_31_xs u_i_c8 (.io_in(c8_in), .io_out(i_c8_out));


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    case ($urandom_range(0, 7))
      0: c0_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c0_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c0_in = '0;
           c0_in[$urandom_range(0, 63)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 64);
           for (int b = 0; b < 64; b++) c0_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c0_in[63 - b] = 1'b0;
           if (k < 64) c0_in[63 - k] = 1'b1; else c0_in = '0;
         end
      default: for (int b = 0; b < 64; b++) c0_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c1_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c1_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c1_in = '0;
           c1_in[$urandom_range(0, 63)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 64);
           for (int b = 0; b < 64; b++) c1_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c1_in[63 - b] = 1'b0;
           if (k < 64) c1_in[63 - k] = 1'b1; else c1_in = '0;
         end
      default: for (int b = 0; b < 64; b++) c1_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c2_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c2_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c2_in = '0;
           c2_in[$urandom_range(0, 15)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 16);
           for (int b = 0; b < 16; b++) c2_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c2_in[15 - b] = 1'b0;
           if (k < 16) c2_in[15 - k] = 1'b1; else c2_in = '0;
         end
      default: for (int b = 0; b < 16; b++) c2_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c3_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c3_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c3_in = '0;
           c3_in[$urandom_range(0, 31)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 32);
           for (int b = 0; b < 32; b++) c3_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c3_in[31 - b] = 1'b0;
           if (k < 32) c3_in[31 - k] = 1'b1; else c3_in = '0;
         end
      default: for (int b = 0; b < 32; b++) c3_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c4_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c4_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c4_in = '0;
           c4_in[$urandom_range(0, 7)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 8);
           for (int b = 0; b < 8; b++) c4_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c4_in[7 - b] = 1'b0;
           if (k < 8) c4_in[7 - k] = 1'b1; else c4_in = '0;
         end
      default: for (int b = 0; b < 8; b++) c4_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c5_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c5_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c5_in = '0;
           c5_in[$urandom_range(0, 9)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 10);
           for (int b = 0; b < 10; b++) c5_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c5_in[9 - b] = 1'b0;
           if (k < 10) c5_in[9 - k] = 1'b1; else c5_in = '0;
         end
      default: for (int b = 0; b < 10; b++) c5_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c6_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c6_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c6_in = '0;
           c6_in[$urandom_range(0, 22)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 23);
           for (int b = 0; b < 23; b++) c6_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c6_in[22 - b] = 1'b0;
           if (k < 23) c6_in[22 - k] = 1'b1; else c6_in = '0;
         end
      default: for (int b = 0; b < 23; b++) c6_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c7_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c7_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c7_in = '0;
           c7_in[$urandom_range(0, 10)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 11);
           for (int b = 0; b < 11; b++) c7_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c7_in[10 - b] = 1'b0;
           if (k < 11) c7_in[10 - k] = 1'b1; else c7_in = '0;
         end
      default: for (int b = 0; b < 11; b++) c7_in[b] = 1'($urandom);
    endcase
    case ($urandom_range(0, 7))
      0: c8_in = '0;                                  // 全零：SCAN_LOW 语义的关键用例
      1: c8_in = '1;
      2: begin                                       // 随机 one-hot（含第 0 位）
           c8_in = '0;
           c8_in[$urandom_range(0, 23)] = 1'b1;
         end
      3, 4: begin                                    // 指定前导零个数 k，输出必等于 k
           int k;
           k = $urandom_range(0, 24);
           for (int b = 0; b < 24; b++) c8_in[b] = 1'($urandom);
           for (int b = 0; b < k; b++) c8_in[23 - b] = 1'b0;
           if (k < 24) c8_in[23 - k] = 1'b1; else c8_in = '0;
         end
      default: for (int b = 0; b < 24; b++) c8_in[b] = 1'($urandom);
    endcase
  endtask

  task automatic check_outputs();
    checks++; c0_checks++;
    c0_ones  |= c0_in;
    c0_zeros |= ~c0_in;
    if (c0_in == '0) c0_zero_in++;
    c0_seen[g_c0_out] = 1'b1;
    if (g_c0_out !== i_c0_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ in=%0h g=%0d i=%0d",
                 $time, c0_in, g_c0_out, i_c0_out);
    end
    checks++; c1_checks++;
    c1_ones  |= c1_in;
    c1_zeros |= ~c1_in;
    if (c1_in == '0) c1_zero_in++;
    c1_seen[g_c1_out] = 1'b1;
    if (g_c1_out !== i_c1_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_6 in=%0h g=%0d i=%0d",
                 $time, c1_in, g_c1_out, i_c1_out);
    end
    checks++; c2_checks++;
    c2_ones  |= c2_in;
    c2_zeros |= ~c2_in;
    if (c2_in == '0) c2_zero_in++;
    c2_seen[g_c2_out] = 1'b1;
    if (g_c2_out !== i_c2_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_7 in=%0h g=%0d i=%0d",
                 $time, c2_in, g_c2_out, i_c2_out);
    end
    checks++; c3_checks++;
    c3_ones  |= c3_in;
    c3_zeros |= ~c3_in;
    if (c3_in == '0) c3_zero_in++;
    c3_seen[g_c3_out] = 1'b1;
    if (g_c3_out !== i_c3_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_9 in=%0h g=%0d i=%0d",
                 $time, c3_in, g_c3_out, i_c3_out);
    end
    checks++; c4_checks++;
    c4_ones  |= c4_in;
    c4_zeros |= ~c4_in;
    if (c4_in == '0) c4_zero_in++;
    c4_seen[g_c4_out] = 1'b1;
    if (g_c4_out !== i_c4_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_11 in=%0h g=%0d i=%0d",
                 $time, c4_in, g_c4_out, i_c4_out);
    end
    checks++; c5_checks++;
    c5_ones  |= c5_in;
    c5_zeros |= ~c5_in;
    if (c5_in == '0) c5_zero_in++;
    c5_seen[g_c5_out] = 1'b1;
    if (g_c5_out !== i_c5_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_28 in=%0h g=%0d i=%0d",
                 $time, c5_in, g_c5_out, i_c5_out);
    end
    checks++; c6_checks++;
    c6_ones  |= c6_in;
    c6_zeros |= ~c6_in;
    if (c6_in == '0) c6_zero_in++;
    c6_seen[g_c6_out] = 1'b1;
    if (g_c6_out !== i_c6_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_29 in=%0h g=%0d i=%0d",
                 $time, c6_in, g_c6_out, i_c6_out);
    end
    checks++; c7_checks++;
    c7_ones  |= c7_in;
    c7_zeros |= ~c7_in;
    if (c7_in == '0) c7_zero_in++;
    c7_seen[g_c7_out] = 1'b1;
    if (g_c7_out !== i_c7_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_30 in=%0h g=%0d i=%0d",
                 $time, c7_in, g_c7_out, i_c7_out);
    end
    checks++; c8_checks++;
    c8_ones  |= c8_in;
    c8_zeros |= ~c8_in;
    if (c8_in == '0) c8_zero_in++;
    c8_seen[g_c8_out] = 1'b1;
    if (g_c8_out !== i_c8_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH CLZ_31 in=%0h g=%0d i=%0d",
                 $time, c8_in, g_c8_out, i_c8_out);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    c0_in = '0; c0_ones = '0; c0_zeros = '0; c0_seen = '0;
    c0_checks = 0; c0_zero_in = 0;
    c1_in = '0; c1_ones = '0; c1_zeros = '0; c1_seen = '0;
    c1_checks = 0; c1_zero_in = 0;
    c2_in = '0; c2_ones = '0; c2_zeros = '0; c2_seen = '0;
    c2_checks = 0; c2_zero_in = 0;
    c3_in = '0; c3_ones = '0; c3_zeros = '0; c3_seen = '0;
    c3_checks = 0; c3_zero_in = 0;
    c4_in = '0; c4_ones = '0; c4_zeros = '0; c4_seen = '0;
    c4_checks = 0; c4_zero_in = 0;
    c5_in = '0; c5_ones = '0; c5_zeros = '0; c5_seen = '0;
    c5_checks = 0; c5_zero_in = 0;
    c6_in = '0; c6_ones = '0; c6_zeros = '0; c6_seen = '0;
    c6_checks = 0; c6_zero_in = 0;
    c7_in = '0; c7_ones = '0; c7_zeros = '0; c7_seen = '0;
    c7_checks = 0; c7_zero_in = 0;
    c8_in = '0; c8_ones = '0; c8_zeros = '0; c8_seen = '0;
    c8_checks = 0; c8_zero_in = 0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();     // 纯组合：驱动后延一个 delta 再比
      @(posedge clock);
    end
    $display("CLZ family checks=%0d errors=%0d", checks, errors);
    $display("  CLZ: checks=%0d zero_in=%0d seen=%0d/64 ones=%0d/64 zeros=%0d/64",
             c0_checks, c0_zero_in, $countones(c0_seen),
             $countones(c0_ones), $countones(c0_zeros));
    cov_fail += cov_short("CLZ checks",  c0_checks)
              + cov_short("CLZ zero_in", c0_zero_in);
    if (!(&c0_seen)) begin
      $display("COVERAGE FAIL: CLZ 有输出值从未被观察到（见 %0d / 64）",
               $countones(c0_seen)); cov_fail++;
    end
    if (!(&c0_ones) || !(&c0_zeros)) begin
      $display("COVERAGE FAIL: CLZ 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_6: checks=%0d zero_in=%0d seen=%0d/65 ones=%0d/64 zeros=%0d/64",
             c1_checks, c1_zero_in, $countones(c1_seen),
             $countones(c1_ones), $countones(c1_zeros));
    cov_fail += cov_short("CLZ_6 checks",  c1_checks)
              + cov_short("CLZ_6 zero_in", c1_zero_in);
    if (!(&c1_seen)) begin
      $display("COVERAGE FAIL: CLZ_6 有输出值从未被观察到（见 %0d / 65）",
               $countones(c1_seen)); cov_fail++;
    end
    if (!(&c1_ones) || !(&c1_zeros)) begin
      $display("COVERAGE FAIL: CLZ_6 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_7: checks=%0d zero_in=%0d seen=%0d/17 ones=%0d/16 zeros=%0d/16",
             c2_checks, c2_zero_in, $countones(c2_seen),
             $countones(c2_ones), $countones(c2_zeros));
    cov_fail += cov_short("CLZ_7 checks",  c2_checks)
              + cov_short("CLZ_7 zero_in", c2_zero_in);
    if (!(&c2_seen)) begin
      $display("COVERAGE FAIL: CLZ_7 有输出值从未被观察到（见 %0d / 17）",
               $countones(c2_seen)); cov_fail++;
    end
    if (!(&c2_ones) || !(&c2_zeros)) begin
      $display("COVERAGE FAIL: CLZ_7 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_9: checks=%0d zero_in=%0d seen=%0d/33 ones=%0d/32 zeros=%0d/32",
             c3_checks, c3_zero_in, $countones(c3_seen),
             $countones(c3_ones), $countones(c3_zeros));
    cov_fail += cov_short("CLZ_9 checks",  c3_checks)
              + cov_short("CLZ_9 zero_in", c3_zero_in);
    if (!(&c3_seen)) begin
      $display("COVERAGE FAIL: CLZ_9 有输出值从未被观察到（见 %0d / 33）",
               $countones(c3_seen)); cov_fail++;
    end
    if (!(&c3_ones) || !(&c3_zeros)) begin
      $display("COVERAGE FAIL: CLZ_9 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_11: checks=%0d zero_in=%0d seen=%0d/9 ones=%0d/8 zeros=%0d/8",
             c4_checks, c4_zero_in, $countones(c4_seen),
             $countones(c4_ones), $countones(c4_zeros));
    cov_fail += cov_short("CLZ_11 checks",  c4_checks)
              + cov_short("CLZ_11 zero_in", c4_zero_in);
    if (!(&c4_seen)) begin
      $display("COVERAGE FAIL: CLZ_11 有输出值从未被观察到（见 %0d / 9）",
               $countones(c4_seen)); cov_fail++;
    end
    if (!(&c4_ones) || !(&c4_zeros)) begin
      $display("COVERAGE FAIL: CLZ_11 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_28: checks=%0d zero_in=%0d seen=%0d/11 ones=%0d/10 zeros=%0d/10",
             c5_checks, c5_zero_in, $countones(c5_seen),
             $countones(c5_ones), $countones(c5_zeros));
    cov_fail += cov_short("CLZ_28 checks",  c5_checks)
              + cov_short("CLZ_28 zero_in", c5_zero_in);
    if (!(&c5_seen)) begin
      $display("COVERAGE FAIL: CLZ_28 有输出值从未被观察到（见 %0d / 11）",
               $countones(c5_seen)); cov_fail++;
    end
    if (!(&c5_ones) || !(&c5_zeros)) begin
      $display("COVERAGE FAIL: CLZ_28 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_29: checks=%0d zero_in=%0d seen=%0d/24 ones=%0d/23 zeros=%0d/23",
             c6_checks, c6_zero_in, $countones(c6_seen),
             $countones(c6_ones), $countones(c6_zeros));
    cov_fail += cov_short("CLZ_29 checks",  c6_checks)
              + cov_short("CLZ_29 zero_in", c6_zero_in);
    if (!(&c6_seen)) begin
      $display("COVERAGE FAIL: CLZ_29 有输出值从未被观察到（见 %0d / 24）",
               $countones(c6_seen)); cov_fail++;
    end
    if (!(&c6_ones) || !(&c6_zeros)) begin
      $display("COVERAGE FAIL: CLZ_29 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_30: checks=%0d zero_in=%0d seen=%0d/12 ones=%0d/11 zeros=%0d/11",
             c7_checks, c7_zero_in, $countones(c7_seen),
             $countones(c7_ones), $countones(c7_zeros));
    cov_fail += cov_short("CLZ_30 checks",  c7_checks)
              + cov_short("CLZ_30 zero_in", c7_zero_in);
    if (!(&c7_seen)) begin
      $display("COVERAGE FAIL: CLZ_30 有输出值从未被观察到（见 %0d / 12）",
               $countones(c7_seen)); cov_fail++;
    end
    if (!(&c7_ones) || !(&c7_zeros)) begin
      $display("COVERAGE FAIL: CLZ_30 有输入位从未见过 1 或 0"); cov_fail++;
    end
    $display("  CLZ_31: checks=%0d zero_in=%0d seen=%0d/25 ones=%0d/24 zeros=%0d/24",
             c8_checks, c8_zero_in, $countones(c8_seen),
             $countones(c8_ones), $countones(c8_zeros));
    cov_fail += cov_short("CLZ_31 checks",  c8_checks)
              + cov_short("CLZ_31 zero_in", c8_zero_in);
    if (!(&c8_seen)) begin
      $display("COVERAGE FAIL: CLZ_31 有输出值从未被观察到（见 %0d / 25）",
               $countones(c8_seen)); cov_fail++;
    end
    if (!(&c8_ones) || !(&c8_zeros)) begin
      $display("COVERAGE FAIL: CLZ_31 有输入位从未见过 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
