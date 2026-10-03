// =============================================================================
// tb —— VectorCvtTop UT：golden VectorCvtTop 与重写 VectorCvtTop_xs 双例化，逐拍比 io_result /
//   io_fflags；另按元素把 golden 结果与 cvt_tb_pkg 的 oracle 对比（i2f / f2i（非 RTZ 编码）/ rec7 / rsqrt7）。
//
// 激励（每拍）：fire 70%；(opType, sew) 由 pick_op 选；85% 的拍 outputWidth1H / isWiden / isNarrow
//   与 opType、sew 一致（上层 VCVT_8 的译码），15% 任意；uopIdx 随机；两半 64 位源各按源元素宽度填。
// 元素布局（oracle 用，只在「一致」的拍检）：每半 n = 64 / max(源宽, 目的宽) 个元素，共 2n 个；
//   源向量 = 变宽 ? (uopIdx ? src_1 : src_0) : {src_1, src_0}；第 e 个元素源在 [e*源宽 +: 源宽]，
//   结果在 result[e*目的宽 +: 目的宽]，fflags 在 fflags[5e +: 5]。
// 覆盖（写进 PASS 判据）：每个合法 (opType, sew) × rm 0..4 组合 >= 20 次；uopIdx 两值在变宽下各 >= 1000。
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

  logic         reset;
  logic         io_fire;
  logic         io_uopIdx;
  logic [63:0]  io_src_0, io_src_1;
  logic [7:0]   io_opType;
  logic [1:0]   io_sew;
  logic [2:0]   io_rm;
  logic [3:0]   io_outputWidth1H;
  logic         io_isWiden, io_isNarrow;
  wire  [127:0] g_res, i_res;
  wire  [39:0]  g_ff, i_ff;

  VectorCvtTop u_g (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_uopIdx(io_uopIdx), .io_src_0(io_src_0),
    .io_src_1(io_src_1), .io_opType(io_opType), .io_sew(io_sew), .io_rm(io_rm),
    .io_outputWidth1H(io_outputWidth1H), .io_isWiden(io_isWiden), .io_isNarrow(io_isNarrow),
    .io_result(g_res), .io_fflags(g_ff));
  VectorCvtTop_xs u_i (
    .clock(clock), .reset(reset), .io_fire(io_fire), .io_uopIdx(io_uopIdx), .io_src_0(io_src_0),
    .io_src_1(io_src_1), .io_opType(io_opType), .io_sew(io_sew), .io_rm(io_rm),
    .io_outputWidth1H(io_outputWidth1H), .io_isWiden(io_isWiden), .io_isNarrow(io_isNarrow),
    .io_result(i_res), .io_fflags(i_ff));

  typedef struct {
    bit           valid;
    bit           consistent;
    logic [127:0] srcv;      // 元素源向量（见文件头）
    logic [7:0]   op;
    logic [1:0]   sew;
    logic [2:0]   rm;
  } tx_t;
  tx_t pipe [3];

  int cov [string];
  int o_cls [6];
  int cov_uop [2];

  task automatic check_oracle(tx_t t);
    int n, iw, ow;
    logic [68:0]  e;
    logic [63:0]  x, m, got;
    n = elems64(t.op, t.sew);
    if (!t.consistent || !op_legal(t.op, t.sew) || n == 0) return;
    iw = in_width(t.op, t.sew); ow = out_width(t.op, t.sew);
    m  = (ow == 64) ? '1 : ((64'h1 << ow) - 1);
    for (int k = 0; k < 2 * n; k++) begin
      x = 64'(t.srcv >> (k * iw));
      if (!oracle_elem(t.op, t.sew, t.rm, x, 0, e)) return;
      got = 64'(g_res >> (k * ow)) & m;
      o_checks++;
      o_cls[op_class(t.op)]++;
      if (e[63:0] !== got || e[68:64] !== g_ff[5*k +: 5]) begin
        o_errors++;
        if (o_errors <= 20)
          $display("[%0d] ORACLE MISMATCH %s elem%0d golden=%h/%b oracle=%h/%b",
                   cyc, op_key(t.op, t.sew, t.rm), k, got, g_ff[5*k +: 5], e[63:0], e[68:64]);
      end
    end
  endtask

  initial begin
    int bad;
    logic [7:0] op;
    logic [1:0] sew;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; io_fire = 0; io_uopIdx = 0; io_src_0 = 0; io_src_1 = 0; io_opType = 0; io_sew = 0;
    io_rm = 0; io_outputWidth1H = 0; io_isWiden = 0; io_isNarrow = 0;
    foreach (pipe[k]) pipe[k].valid = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(posedge clock); #1;
      if (cyc >= WARM) checks++;
      if (cyc >= WARM && (g_res !== i_res || g_ff !== i_ff)) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%h i=%h", cyc, g_res, i_res, g_ff, i_ff);
      end
      pipe[2] = pipe[1]; pipe[1] = pipe[0];
      if (pipe[2].valid && !reset) check_oracle(pipe[2]);
      // ---- 新激励 ----
      reset = (cyc < 5) || ($urandom_range(0, 19999) == 0);
      pick_op(op, sew);
      io_fire   = ($urandom_range(0, 9) < 7) || (cyc >= 5 && cyc < WARM);
      io_opType = op;
      io_sew    = sew;
      io_rm     = pick_rm();
      io_uopIdx = 1'($urandom);
      io_src_0  = pick_vec64(op, sew);
      io_src_1  = pick_vec64(op, sew);
      pipe[0].consistent = ($urandom_range(0, 99) < 85);
      if (pipe[0].consistent) begin
        io_outputWidth1H = dec_out1h(op, sew);
        io_isWiden       = ~op[4] & op[3];
        io_isNarrow      = op[4] & ~op[3];
      end else begin
        io_outputWidth1H = 4'($urandom);
        io_isWiden       = 1'($urandom);
        io_isNarrow      = 1'($urandom);
      end
      if (io_fire && !reset && pipe[0].consistent && op_legal(op, sew)) begin
        cov[op_key(op, sew, io_rm)]++;
        if (io_isWiden) cov_uop[io_uopIdx]++;
      end
      pipe[0].valid = io_fire && !reset;
      pipe[0].srcv  = io_isWiden ? 128'(io_uopIdx ? io_src_1 : io_src_0) : {io_src_1, io_src_0};
      pipe[0].op = op; pipe[0].sew = sew; pipe[0].rm = io_rm;
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
    $display("cov widen uopIdx 0/1 : %0d / %0d", cov_uop[0], cov_uop[1]);
    foreach (cov_uop[u]) if (cov_uop[u] < NCYCLES / 200) bad++;
    $display("oracle elems by class i2f/f2i/f2f/rec7/rsqrt7 : %0d %0d %0d %0d %0d",
             o_cls[C_I2F], o_cls[C_F2I], o_cls[C_F2F], o_cls[C_REC7], o_cls[C_RSQRT7]);
    $display("oracle_checks=%0d oracle_errors=%0d", o_checks, o_errors);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && o_errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
