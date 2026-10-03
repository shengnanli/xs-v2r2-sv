// =============================================================================
// tb —— VectorCvt UT：golden VectorCvt 与重写 VectorCvt_xs 双例化，逐拍比 io_result / io_fflags；
//   另按元素把 golden 结果与 cvt_tb_pkg 的 oracle 对比（i2f / f2i（非 RTZ 编码）/ rec7 / rsqrt7）。
//
// 激励（每拍）：fire 70%；(opType, sew) 由 pick_op 选（80% 合法组合）；64 位源按源元素宽度逐个
//   从定向池填（10% 整体随机）；rm 见 pick_rm。复位：前 5 拍拉高，之后随机偶发。
// 元素布局（oracle 用）：n = 64 / max(源宽, 目的宽)；第 e 个元素源在 src[e*源宽 +: 源宽]，
//   结果在 result[e*目的宽 +: 目的宽]，fflags 在 fflags[5e +: 5]。
// 覆盖（写进 PASS 判据）：每个合法 (opType, sew) × rm 0..4 组合 >= 20 次。
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
  logic [1:0]  io_sew;
  logic [2:0]  io_rm;
  wire  [63:0] g_res, i_res;
  wire  [19:0] g_ff, i_ff;

  VectorCvt u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_sew(io_sew), .io_rm(io_rm), .io_result(g_res), .io_fflags(g_ff));
  VectorCvt_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_sew(io_sew), .io_rm(io_rm), .io_result(i_res), .io_fflags(i_ff));

  typedef struct {
    bit          valid;
    logic [63:0] src;
    logic [7:0]  op;
    logic [1:0]  sew;
    logic [2:0]  rm;
  } tx_t;
  tx_t pipe [3];

  int cov [string];
  int o_cls [6];

  task automatic check_oracle(tx_t t);
    int n, iw, ow;
    logic [68:0] e;
    logic [63:0] x, m, got;
    n = elems64(t.op, t.sew);
    if (!op_legal(t.op, t.sew) || n == 0) return;
    iw = in_width(t.op, t.sew); ow = out_width(t.op, t.sew);
    m  = (ow == 64) ? '1 : ((64'h1 << ow) - 1);
    for (int k = 0; k < n; k++) begin
      x = (t.src >> (k * iw));
      if (!oracle_elem(t.op, t.sew, t.rm, x, 0, e)) return;
      got = (g_res >> (k * ow)) & m;
      o_checks++;
      o_cls[op_class(t.op)]++;
      if (e[63:0] !== got || e[68:64] !== g_ff[5*k +: 5]) begin
        o_errors++;
        if (o_errors <= 20)
          $display("[%0d] ORACLE MISMATCH %s elem%0d src=%h golden=%h/%b oracle=%h/%b",
                   cyc, op_key(t.op, t.sew, t.rm), k, t.src, got, g_ff[5*k +: 5], e[63:0], e[68:64]);
      end
    end
  endtask

  initial begin
    int bad;
    logic [7:0] op;
    logic [1:0] sew;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; io_fire = 0; io_src = 0; io_opType = 0; io_sew = 0; io_rm = 0;
    foreach (pipe[k]) pipe[k].valid = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      checks++;
      if (g_res !== i_res || g_ff !== i_ff) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%h i=%h", cyc, g_res, i_res, g_ff, i_ff);
      end
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      io_fire   = ($urandom_range(0, 9) < 7);
      io_opType = op;
      io_sew    = sew;
      io_rm     = pick_rm();
      io_src    = pick_vec64(op, sew);
      if (io_fire && !reset && op_legal(op, sew)) cov[op_key(op, sew, io_rm)]++;
      pipe[0].valid = io_fire && !reset; pipe[0].src = io_src; pipe[0].op = op;
      pipe[0].sew = sew; pipe[0].rm = io_rm;
      if (reset) pipe[1].valid = 0;
    end
    bad = 0;
    foreach (VEC_OPS[k]) for (int s = 0; s < 4; s++) for (int r = 0; r < 5; r++)
      if (op_legal(VEC_OPS[k], 2'(s))) begin
        string key;
        key = op_key(VEC_OPS[k], 2'(s), 3'(r));
        if (!cov.exists(key) || cov[key] < 20) begin bad++; $display("cov LOW %s", key); end
      end
    foreach (cov[key]) $display("cov %s : %0d", key, cov[key]);
    $display("oracle elems by class i2f/f2i/f2f/rec7/rsqrt7 : %0d %0d %0d %0d %0d",
             o_cls[C_I2F], o_cls[C_F2I], o_cls[C_F2F], o_cls[C_REC7], o_cls[C_RSQRT7]);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
