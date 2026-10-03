// =============================================================================
// tb —— INT2FP UT：golden INT2FP 与重写 INT2FP_xs 双例化，逐拍比 io_result / io_fflags；
//   另把 golden 结果与独立数学 oracle（cvt_tb_pkg::o_int2fp）对比。
//
// 激励（每拍）：fire 70%；源整数按 input1H 宽度从定向池/随机位长取（高位填垃圾）；
//   input1H/output1H 75% 取独热（4 种源宽 × 3 种浮点格式任意配对），25% 任意 4 位
//   （含多热、全 0 —— golden 的 Mux1H 会把多路或在一起，同样要比）；rm 见 pick_rm。
//   复位：前 5 拍拉高，之后每 ~20000 拍随机再拉一次（异步复位域也要比）。
// oracle 只检「源/目的都独热、目的是浮点格式、rm∈0..4」的拍；结果在 fire 后第 2 个时钟沿可见。
// 覆盖（写进 PASS 判据）：源宽 4 × 目的格式 3 × 有无符号 2 × rm 0..4 = 120 格每格 >= 50；
//   结果类别 零 / 正常精确 / 正常不精确 / 上溢 各 >= 100。
// =============================================================================
`timescale 1ns/1ps
module tb import cvt_tb_pkg::*; ;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, o_checks = 0, o_errors = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;

  logic        reset;
  logic        io_fire;
  logic [63:0] io_src;
  logic [7:0]  io_opType;
  logic [2:0]  io_rm;
  logic [3:0]  io_input1H;
  logic [3:0]  io_output1H;
  wire  [63:0] g_io_result, i_io_result;
  wire  [4:0]  g_io_fflags, i_io_fflags;

  INT2FP u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(g_io_result), .io_fflags(g_io_fflags));
  INT2FP_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(i_io_result), .io_fflags(i_io_fflags));

  // 两拍延迟的事务记录（oracle 用）
  typedef struct {
    bit          valid;
    logic [63:0] src;
    logic [7:0]  op;
    logic [2:0]  rm;
    logic [3:0]  in1h, out1h;
  } tx_t;
  tx_t pipe [3];

  int cov [4][3][2][8];    // [源宽][目的格式][有符号][rm]
  int cov_res [4];         // 零 / 正常精确 / 正常不精确 / 上溢
  int cov_fl [5];

  function automatic int idx1h(logic [3:0] v);
    for (int i = 0; i < 4; i++) if (v == (4'b1 << i)) return i;
    return -1;
  endfunction

  task automatic check_oracle(tx_t t);
    int iw, ow;
    logic [63:0] x, mag;
    bit neg;
    logic [68:0] o;
    iw = idx1h(t.in1h); ow = idx1h(t.out1h);
    if (iw < 0 || ow < 1 || t.rm > 3'd4) return;
    x = t.src & ((iw == 3) ? '1 : ((64'h1 << (8 << iw)) - 1));
    neg = t.op[0] & x[(8 << iw) - 1];
    mag = neg ? 64'(-(x | ~((iw == 3) ? '1 : ((64'h1 << (8 << iw)) - 1)))) : x;
    o = o_int2fp(mag, neg, 8 << ow, t.rm);
    o_checks++;
    cov[iw][ow - 1][t.op[0]][t.rm]++;
    if (mag == 0) cov_res[0]++;
    else if (o[66]) cov_res[3]++;
    else if (o[64]) cov_res[2]++;
    else cov_res[1]++;
    if (o[63:0] !== g_io_result || o[68:64] !== g_io_fflags) begin
      o_errors++;
      if (o_errors <= 20)
        $display("[%0d] ORACLE MISMATCH src=%h op=%h rm=%0d in1h=%b out1h=%b golden=%h/%b oracle=%h/%b",
                 cyc, t.src, t.op, t.rm, t.in1h, t.out1h, g_io_result, g_io_fflags, o[63:0], o[68:64]);
    end
  endtask

  initial begin
    int bad;
    logic [7:0] op;
    logic [1:0] sew;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; io_fire = 0; io_src = 0; io_opType = 0; io_rm = 0; io_input1H = 0; io_output1H = 0;
    foreach (pipe[k]) pipe[k].valid = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      // ---- 比较：两份实现逐拍全输出 ----
      checks++;
      if (g_io_result !== i_io_result || g_io_fflags !== i_io_fflags) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%b i=%b",
                                   cyc, g_io_result, i_io_result, g_io_fflags, i_io_fflags);
      end
      for (int b = 0; b < 5; b++) if (g_io_fflags[b]) cov_fl[b]++;
      // ---- oracle：两拍前发出的事务 ----
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      io_fire   = ($urandom_range(0, 9) < 7);
      io_opType = op;
      io_rm     = pick_rm();
      if ($urandom_range(0, 3) != 0) begin
        io_input1H  = 4'b1 << $urandom_range(0, 3);
        io_output1H = 4'b1 << $urandom_range(1, 3);
      end else begin
        io_input1H  = 4'($urandom);
        io_output1H = 4'($urandom);
      end
      begin
        int iw;
        iw = idx1h(io_input1H);
        io_src = (iw < 0) ? rnd64() : pick_int(8 << iw);
        if (iw >= 0 && iw < 3 && $urandom_range(0, 1)) io_src = io_src | (rnd64() << (8 << iw));
      end
      pipe[0].valid = io_fire && !reset; pipe[0].src = io_src; pipe[0].op = io_opType;
      pipe[0].rm = io_rm; pipe[0].in1h = io_input1H; pipe[0].out1h = io_output1H;
      if (reset) begin pipe[1].valid = 0; end
    end
    bad = 0;
    foreach (cov[a, b, c, d]) if (d <= 4) begin
      if (cov[a][b][c][d] < 50) begin bad++; $display("cov LOW in%0d>f%0d s=%0d rm%0d : %0d", 8 << a, 16 << b, c, d, cov[a][b][c][d]); end
    end
    for (int a = 0; a < 4; a++) for (int b = 0; b < 3; b++) for (int c = 0; c < 2; c++)
      $display("cov i2f.%s.%0d>%0d rm0..4 : %0d %0d %0d %0d %0d", c ? "s" : "u", 8 << a, 16 << b,
               cov[a][b][c][0], cov[a][b][c][1], cov[a][b][c][2], cov[a][b][c][3], cov[a][b][c][4]);
    $display("cov result zero/exact/inexact/overflow : %0d / %0d / %0d / %0d", cov_res[0], cov_res[1], cov_res[2], cov_res[3]);
    foreach (cov_res[a]) if (cov_res[a] < 100) bad++;
    $display("cov fflags set NX/UF/OF/DZ/NV : %0d %0d %0d %0d %0d", cov_fl[0], cov_fl[1], cov_fl[2], cov_fl[3], cov_fl[4]);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
