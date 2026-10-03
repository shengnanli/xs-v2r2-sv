// =============================================================================
// tb —— FloatAdderWidenFormat UT：golden 与重写件 FloatAdderWidenFormat_xs 双例化，逐次比 6 个输出；
//   外加独立 IEEE oracle（不看任何一侧实现，用仿真器自带的浮点转换）：
//     f16 → f32：按 IEEE 把 f16 的数值 (-1)^s × m × 2^(e-25) 算成 real 再 $shortrealtobits（f16 在 f32 里精确可表示）；
//     f32 → f64：$realtobits($bitstoshortreal(x))（精确）。
//   oracle 只管"有限非零"的输入（规格数 + 非零非规格数）；指数全 1（Inf/NaN）与 ±0 的输出按 golden 是
//   非 IEEE 的格式化结果（见 rtl 文件头的怪癖），这两类只做差分，另外各单独计数。
// 激励：每个 16 位 / 32 位元素的指数按类别挑（0 = 非规格/零、1、中间、全 1 附近、全 1），尾数含
//   全 0 / 全 1 / 单个 1 游走（非规格数的每个移位量）/ 随机；uop_idx 1/2。
// 覆盖判据（写进 PASS）：f16 非规格数 10 种移位量、f32 非规格数 23 种移位量各 >= 50 次；
//   oracle 比对的 f16/f32 元素各 >= 50000；源的高/低半（及两个 f16）互不相同的拍 >= 一半；Inf/NaN、零各 >= 1000；每个输出位见过 0 和 1（结构恒 0 的低位除外）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  bit clk = 0; always #5 clk = ~clk;

  logic [63:0] wa, wb;
  logic        uop_idx;
  logic [31:0] g_a0, g_b0, g_a1, g_b1, i_a0, i_b0, i_a1, i_b1;
  logic [63:0] g_a64, g_b64, i_a64, i_b64;

  FloatAdderWidenFormat u_g (.io_widen_a(wa), .io_widen_b(wb), .io_uop_idx(uop_idx),
    .io_widen_a_f32_0(g_a0), .io_widen_b_f32_0(g_b0), .io_widen_a_f32_1(g_a1), .io_widen_b_f32_1(g_b1),
    .io_widen_a_f64(g_a64), .io_widen_b_f64(g_b64));
  FloatAdderWidenFormat_xs u_i (.io_widen_a(wa), .io_widen_b(wb), .io_uop_idx(uop_idx),
    .io_widen_a_f32_0(i_a0), .io_widen_b_f32_0(i_b0), .io_widen_a_f32_1(i_a1), .io_widen_b_f32_1(i_b1),
    .io_widen_a_f64(i_a64), .io_widen_b_f64(i_b64));

  longint oracle16 = 0, oracle32 = 0, special = 0, zeros = 0, halves_differ = 0;
  longint den16 [10], den32 [23];
  logic [63:0] seen0 [6], seen1 [6];

  // ---- 激励构造 ----
  function automatic logic [15:0] mk16();
    logic [4:0] e; logic [9:0] m;
    case ($urandom_range(0, 9))
      0, 1, 2: e = 5'd0;
      3: e = 5'd1;
      4: e = 5'h1F;
      5: e = 5'h1E;
      default: e = 5'($urandom);
    endcase
    case ($urandom_range(0, 5))
      0: m = '0;
      1: m = '1;
      2, 3: m = 10'(1) << $urandom_range(0, 9);
      default: m = 10'($urandom);
    endcase
    if ($urandom_range(0, 1) && m != 0 && ($urandom_range(0, 1))) m = m | (10'($urandom) >> ($urandom_range(0, 10)));
    return {1'($urandom), e, m};
  endfunction
  function automatic logic [31:0] mk32();
    logic [7:0] e; logic [22:0] m;
    case ($urandom_range(0, 9))
      0, 1, 2: e = 8'd0;
      3: e = 8'd1;
      4: e = 8'hFF;
      5: e = 8'hFE;
      default: e = 8'($urandom);
    endcase
    case ($urandom_range(0, 5))
      0: m = '0;
      1: m = '1;
      2, 3: m = 23'(1) << $urandom_range(0, 22);
      default: m = 23'($urandom);
    endcase
    if (m != 0 && $urandom_range(0, 3) == 0) m = m | (23'($urandom) >> ($urandom_range(0, 23)));
    return {1'($urandom), e, m};
  endfunction
  // ★逐个调用存进变量再拼★：实测 VCS 会把同一拼接里重复的 {mk16(), mk16(), ...} 只求值一次
  //   （四个半字完全相同，"uop_idx 选高/低半"这类错就看不见了——变异 M3 因此漏网，见 prereg）。
  function automatic logic [63:0] mk64();
    logic [15:0] h0, h1, h2, h3;
    logic [31:0] w0, w1;
    if ($urandom_range(0, 1)) begin
      h0 = mk16(); h1 = mk16(); h2 = mk16(); h3 = mk16();
      return {h3, h2, h1, h0};
    end
    w0 = mk32(); w1 = mk32();
    return {w1, w0};
  endfunction

  // ---- 独立 IEEE oracle ----
  function automatic logic [31:0] ieee_f16_to_f32(input logic [15:0] h);
    real v; int e;
    e = h[14:10];
    if (e == 0) v = real'(h[9:0]) * (2.0 ** -24);
    else        v = real'({1'b1, h[9:0]}) * (2.0 ** (e - 25));
    if (h[15]) v = -v;
    return $shortrealtobits(shortreal'(v));
  endfunction
  function automatic logic [63:0] ieee_f32_to_f64(input logic [31:0] f);
    return $realtobits(real'($bitstoshortreal(f)));
  endfunction
  function automatic int msb10(input logic [9:0] m);
    for (int k = 9; k >= 0; k--) if (m[k]) return k;
    return -1;
  endfunction
  function automatic int msb23(input logic [22:0] m);
    for (int k = 22; k >= 0; k--) if (m[k]) return k;
    return -1;
  endfunction

  task automatic oracle16_chk(input logic [15:0] h, input logic [31:0] got, input string nm, input int cyc);
    if (h[14:10] == 5'h1F) begin special++; return; end
    if (h[14:0] == 0) begin zeros++; return; end
    if (h[14:10] == 0) den16[9 - msb10(h[9:0])]++;
    oracle16++;
    if (got !== ieee_f16_to_f32(h)) begin
      errors++;
      if (errors <= 20) $display("[%0d] ORACLE %s in=%h got=%h ieee=%h", cyc, nm, h, got, ieee_f16_to_f32(h));
    end
  endtask
  task automatic oracle32_chk(input logic [31:0] f, input logic [63:0] got, input string nm, input int cyc);
    if (f[30:23] == 8'hFF) begin special++; return; end
    if (f[30:0] == 0) begin zeros++; return; end
    if (f[30:23] == 0) den32[22 - msb23(f[22:0])]++;
    oracle32++;
    if (got !== ieee_f32_to_f64(f)) begin
      errors++;
      if (errors <= 20) $display("[%0d] ORACLE %s in=%h got=%h ieee=%h", cyc, nm, f, got, ieee_f32_to_f64(f));
    end
  endtask

  `define CMP(k, g, i, nm) begin checks++; \
      if ((g) !== (i)) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH %s g=%h i=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= 64'(g); seen0[k] |= ~64'(g); end

  initial begin
    int cyc, bad;
    logic [63:0] must [6];
    for (int k = 0; k < 10; k++) den16[k] = 0;
    for (int k = 0; k < 23; k++) den32[k] = 0;
    for (int k = 0; k < 6; k++) begin seen0[k] = '0; seen1[k] = '0; end
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      wa = mk64(); wb = mk64(); uop_idx = $urandom;
      if ($urandom_range(0, 15) == 0) wa = {$urandom, $urandom};
      if (wa[63:32] != wa[31:0] && wb[63:32] != wb[31:0] && wa[31:16] != wa[15:0]) halves_differ++;
      #1;
      `CMP(0, g_a0, i_a0, "widen_a_f32_0")
      `CMP(1, g_b0, i_b0, "widen_b_f32_0")
      `CMP(2, g_a1, i_a1, "widen_a_f32_1")
      `CMP(3, g_b1, i_b1, "widen_b_f32_1")
      `CMP(4, g_a64, i_a64, "widen_a_f64")
      `CMP(5, g_b64, i_b64, "widen_b_f64")
      // oracle 对重写件的输出
      oracle16_chk(uop_idx ? wa[47:32] : wa[15:0],  i_a0, "a_f32_0", cyc);
      oracle16_chk(uop_idx ? wb[47:32] : wb[15:0],  i_b0, "b_f32_0", cyc);
      oracle16_chk(uop_idx ? wa[63:48] : wa[31:16], i_a1, "a_f32_1", cyc);
      oracle16_chk(uop_idx ? wb[63:48] : wb[31:16], i_b1, "b_f32_1", cyc);
      oracle32_chk(uop_idx ? wa[63:32] : wa[31:0],  i_a64, "a_f64", cyc);
      oracle32_chk(uop_idx ? wb[63:32] : wb[31:0],  i_b64, "b_f64", cyc);
      @(posedge clk);
    end
    // 覆盖判据
    bad = 0;
    for (int k = 0; k < 10; k++) if (den16[k] < 50) begin bad++; $display("COVER f16 denormal shift %0d = %0d", k, den16[k]); end
    for (int k = 0; k < 23; k++) if (den32[k] < 50) begin bad++; $display("COVER f32 denormal shift %0d = %0d", k, den32[k]); end
    if (oracle16 < 50000 || oracle32 < 50000 || special < 1000 || zeros < 1000 || halves_differ < NCYCLES / 2) bad++;
    // 结构恒 0：f32 输出低 13 位、f64 输出低 29 位
    for (int k = 0; k < 4; k++) must[k] = 64'hFFFF_E000;
    must[4] = 64'hFFFF_FFFF_E000_0000; must[5] = must[4];
    for (int k = 0; k < 6; k++) begin
      if ((seen1[k] & must[k]) != must[k]) begin bad++; $display("COVER out%0d never-1 bits %h", k, must[k] & ~seen1[k]); end
      if ((seen0[k] & must[k]) != must[k]) begin bad++; $display("COVER out%0d never-0 bits %h", k, must[k] & ~seen0[k]); end
      if (seen1[k] & ~must[k]) begin bad++; $display("ERROR out%0d structural-zero bit went 1", k); end
    end
    $display("checks=%0d errors=%0d oracle_f16=%0d oracle_f32=%0d special(Inf/NaN)=%0d zero=%0d halves_differ=%0d",
             checks, errors, oracle16, oracle32, special, zeros, halves_differ);
    $write("den16_by_shift:"); for (int k = 0; k < 10; k++) $write(" %0d", den16[k]); $display("");
    $write("den32_by_shift:"); for (int k = 0; k < 23; k++) $write(" %0d", den32[k]); $display("");
    if (errors == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED (coverage_bad=%0d)", bad);
    $finish;
  end
endmodule
