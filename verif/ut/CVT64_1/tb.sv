// =============================================================================
// tb —— CVT64_1 UT：两对双例化共用同一激励
//   golden CVT64_1 vs 重写 CVT64_1_xs；golden VCVT vs 重写 VCVT_xs（外面那层壳）。
//   逐拍比 io_result / io_fflags；另把 golden CVT64_1 结果与 cvt_tb_pkg 的 oracle 对比
//   （i2f / f2i（非 RTZ 编码）/ rec7 / rsqrt7；f2f 无 oracle，只靠双例化比）。
//
// 激励（每拍）：fire 70%；(opType, sew) 由 pick_op 选（80% 合法组合）；input1H/output1H 85% 由
//   VectorCvt 的宽度译码表从 (opType, sew) 得出，15% 任意 4 位；源元素按源类型/宽度从定向池取，
//   高位按 1/2 概率填垃圾；rm 见 pick_rm。复位：前 5 拍拉高，之后随机偶发。
// 覆盖（写进 PASS 判据）：每个合法 (opType, sew) × rm 0..4 组合 >= 20 次（键 = 类.符号.源宽>目的宽.rm）。
// =============================================================================
`timescale 1ns/1ps
module tb import cvt_tb_pkg::*; ;
  int unsigned NCYCLES = 200000;
  // ★暖机★：golden 有不复位、只在流水推进时才写的寄存器（fflags0_reg1 / s2 选择位 /
  //   outputWidth1H / outEew / perfVec …）。+vcs+initreg+random 给两个实例各摇各的初值，
  //   这些寄存器在第一次被写之前的读数两侧必然不同 —— 那是 tb 读了「从没写过且不复位」的
  //   寄存器，不是 RTL 差异（CONVENTIONS「读一个从没写过、而且不复位的寄存器」一节）。
  //   所以复位后连发 WARM-5 拍有效请求把整条流水写满，从第 WARM 拍起才比较；
  //   复位域本身归 FM 管（UT 结构上看不见）。
  localparam int WARM = 12;
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
  wire  [63:0] g_res, i_res, gv_res, iv_res;
  wire  [4:0]  g_ff, i_ff, gv_ff, iv_ff;

  CVT64_1 u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(g_res), .io_fflags(g_ff));
  CVT64_1_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(i_res), .io_fflags(i_ff));
  VCVT u_gv (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(gv_res), .io_fflags(gv_ff));
  VCVT_xs u_iv (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_src(io_src), .io_opType(io_opType),
    .io_rm(io_rm), .io_input1H(io_input1H), .io_output1H(io_output1H),
    .io_result(iv_res), .io_fflags(iv_ff));

  typedef struct {
    bit          valid;
    logic [63:0] src;
    logic [7:0]  op;
    logic [1:0]  sew;
    logic [2:0]  rm;
    bit          decoded;   // input1H/output1H 是否按译码表给出
  } tx_t;
  tx_t pipe [3];

  int cov [string];
  int o_cls [6];

  task automatic cmp(input logic [63:0] g, i, input logic [4:0] gf, if_, input string nm);
    checks++;
    if (g !== i || gf !== if_) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH %s result g=%h i=%h fflags g=%b i=%b", cyc, nm, g, i, gf, if_);
    end
  endtask

  task automatic check_oracle(tx_t t);
    logic [68:0] e;
    logic [63:0] m;
    int ow;
    if (!t.decoded) return;
    if (!oracle_elem(t.op, t.sew, t.rm, t.src, 0, e)) return;
    ow = out_width(t.op, t.sew);
    m  = (ow == 64) ? '1 : ((64'h1 << ow) - 1);
    o_checks++;
    o_cls[op_class(t.op)]++;
    if (e[63:0] !== (g_res & m) || e[68:64] !== g_ff) begin
      o_errors++;
      if (o_errors <= 20)
        $display("[%0d] ORACLE MISMATCH %s src=%h op=%h sew=%0d rm=%0d golden=%h/%b oracle=%h/%b",
                 cyc, op_key(t.op, t.sew, t.rm), t.src, t.op, t.sew, t.rm, g_res, g_ff, e[63:0], e[68:64]);
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
      if (cyc >= WARM) begin
        cmp(g_res, i_res, g_ff, i_ff, "CVT64_1");
        cmp(gv_res, iv_res, gv_ff, iv_ff, "VCVT");
      end
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      io_fire   = ($urandom_range(0, 9) < 7) || (cyc >= 5 && cyc < WARM);
      io_opType = op;
      io_rm     = pick_rm();
      pipe[0].decoded = ($urandom_range(0, 99) < 85);
      if (pipe[0].decoded) begin
        io_input1H  = dec_in1h(op, sew);
        io_output1H = dec_out1h(op, sew);
      end else begin
        io_input1H  = 4'($urandom);
        io_output1H = 4'($urandom);
      end
      io_src = pick_elem(op, sew);
      if (io_fire && !reset && pipe[0].decoded) cov[op_key(op, sew, io_rm)]++;
      pipe[0].valid = io_fire && !reset; pipe[0].src = io_src; pipe[0].op = op; pipe[0].sew = sew;
      pipe[0].rm = io_rm;
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
    $display("oracle by class i2f/f2i/f2f/rec7/rsqrt7 : %0d %0d %0d %0d %0d",
             o_cls[C_I2F], o_cls[C_F2I], o_cls[C_F2F], o_cls[C_REC7], o_cls[C_RSQRT7]);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
