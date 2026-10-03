// =============================================================================
// tb —— Estimate7 UT：golden Estimate7 与重写 Estimate7_xs 双例化，逐拍比 io_result / io_fflags；
//   另把 golden 结果与 RVV 规范算法 oracle（cvt_tb_pkg::o_estimate7）对比。
//
// 激励（每拍）：fire 70%；opType 85% 取 vfrec7/vfrsqrt7（其余任意 8 位）；源浮点按 input1H 格式
//   从定向边界池取（零/Inf/qNaN/sNaN/各种非规格化/max-1、max-2 指数档/随机）；
//   input1H 与 output1H 75% 同为一种浮点格式的独热，25% 任意 4 位；rm 见 pick_rm。
//   复位：前 5 拍拉高，之后随机偶发。
// oracle 只检「估算类 opType、input1H==output1H 且为 f16/f32/f64 独热、rm∈0..4」的拍。
// 覆盖（写进 PASS 判据）：{rec7, rsqrt7} × 3 格式 × 9 类输入 × 符号 2 = 108 格每格 >= 20；
//   rec7 上溢档 × 3 格式 × rm 0..4 每格 >= 5。
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

  Estimate7 u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(g_io_result), .io_fflags(g_io_fflags));
  Estimate7_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(i_io_result), .io_fflags(i_io_fflags));

  typedef struct {
    bit          valid;
    logic [63:0] src;
    logic [7:0]  op;
    logic [2:0]  rm;
    logic [3:0]  in1h, out1h;
  } tx_t;
  tx_t pipe [3];

  // 输入类别：0 零 1 非规格化(最高两位 00) 2 非规格化(其余) 3 指数 max-1 4 指数 max-2
  //           5 其余规格化 6 Inf 7 qNaN 8 sNaN
  int cov [2][3][9][2];     // [rec][fmt][类][符号]
  int cov_of [3][5];        // rec7 上溢 [fmt][rm]
  int cov_fl [5];

  function automatic int idx1h(logic [3:0] v);
    for (int i = 0; i < 4; i++) if (v == (4'b1 << i)) return i;
    return -1;
  endfunction

  function automatic int in_class(logic [63:0] x, int w);
    int ew, fw;
    longint unsigned e, emax;
    logic [63:0] f;
    ew = f_ew(w); fw = f_fw(w);
    emax = (64'h1 << ew) - 1;
    e = (x >> fw) & emax;
    f = x & ((64'h1 << fw) - 1);
    if (e == 0) return (f == 0) ? 0 : (f[fw - 1 -: 2] == 2'b00) ? 1 : 2;
    if (e == emax) return (f == 0) ? 6 : f[fw - 1] ? 7 : 8;
    if (e == emax - 1) return 3;
    if (e == emax - 2) return 4;
    return 5;
  endfunction

  task automatic check_oracle(tx_t t);
    int fi, w, c;
    logic [68:0] o;
    logic [63:0] x;
    fi = idx1h(t.in1h);
    if (!t.op[5] || t.in1h != t.out1h || fi < 1 || t.rm > 3'd4) return;
    w = 8 << fi;
    x = t.src & ((w == 64) ? '1 : ((64'h1 << w) - 1));
    c = in_class(x, w);
    cov[t.op[0]][fi - 1][c][x[w - 1]]++;
    if (t.op[0] && c == 1) cov_of[fi - 1][t.rm]++;
    o = o_estimate7(x, w, t.op[0], t.rm);
    o_checks++;
    if (o[63:0] !== g_io_result || o[68:64] !== g_io_fflags) begin
      o_errors++;
      if (o_errors <= 20)
        $display("[%0d] ORACLE MISMATCH src=%h op=%h rm=%0d fmt=f%0d golden=%h/%b oracle=%h/%b",
                 cyc, t.src, t.op, t.rm, w, g_io_result, g_io_fflags, o[63:0], o[68:64]);
    end
  endtask

  initial begin
    int bad;
    logic [7:0] op;
    logic [1:0] sew;
    string nm [9] = '{"zero", "sub00", "sub", "e=max-1", "e=max-2", "normal", "inf", "qnan", "snan"};
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; io_fire = 0; io_src = 0; io_opType = 0; io_rm = 0; io_input1H = 0; io_output1H = 0;
    foreach (pipe[k]) pipe[k].valid = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      checks++;
      if (g_io_result !== i_io_result || g_io_fflags !== i_io_fflags) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%b i=%b",
                                   cyc, g_io_result, i_io_result, g_io_fflags, i_io_fflags);
      end
      for (int b = 0; b < 5; b++) if (g_io_fflags[b]) cov_fl[b]++;
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      if ($urandom_range(0, 99) < 85) op = $urandom_range(0, 1) ? 8'b11_100001 : 8'b11_100000;
      io_fire   = ($urandom_range(0, 9) < 7);
      io_opType = op;
      io_rm     = pick_rm();
      if ($urandom_range(0, 3) != 0) begin
        io_input1H  = 4'b1 << $urandom_range(1, 3);
        io_output1H = io_input1H;
      end else begin
        io_input1H  = 4'($urandom);
        io_output1H = 4'($urandom);
      end
      begin
        int fi;
        fi = idx1h(io_input1H);
        io_src = (fi < 1) ? rnd64() : pick_fp(8 << fi);
        if (fi >= 1 && fi < 3 && $urandom_range(0, 1)) io_src = io_src | (rnd64() << (8 << fi));
      end
      pipe[0].valid = io_fire && !reset; pipe[0].src = io_src; pipe[0].op = io_opType;
      pipe[0].rm = io_rm; pipe[0].in1h = io_input1H; pipe[0].out1h = io_output1H;
      if (reset) pipe[1].valid = 0;
    end
    bad = 0;
    for (int r = 0; r < 2; r++) for (int f = 0; f < 3; f++) begin
      string line;
      line = $sformatf("cov %s.f%0d", r ? "rec7" : "rsqrt7", 16 << f);
      for (int c = 0; c < 9; c++) begin
        line = {line, $sformatf(" %s=%0d/%0d", nm[c], cov[r][f][c][0], cov[r][f][c][1])};
        for (int s = 0; s < 2; s++) if (cov[r][f][c][s] < 20) bad++;
      end
      $display("%s", line);
    end
    for (int f = 0; f < 3; f++) begin
      $display("cov rec7.f%0d overflow rm0..4 : %0d %0d %0d %0d %0d", 16 << f,
               cov_of[f][0], cov_of[f][1], cov_of[f][2], cov_of[f][3], cov_of[f][4]);
      for (int m = 0; m < 5; m++) if (cov_of[f][m] < 5) bad++;
    end
    $display("cov fflags set NX/UF/OF/DZ/NV : %0d %0d %0d %0d %0d", cov_fl[0], cov_fl[1], cov_fl[2], cov_fl[3], cov_fl[4]);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
