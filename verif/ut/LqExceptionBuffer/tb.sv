// ===========================================================================
// LqExceptionBuffer UT：golden LqExceptionBuffer 对重写 LqExceptionBuffer_xs，同一激励，
// 逐拍比对全部 5 个输出（io_exceptionAddr_*，共 131 位）。
//
// ★激励★ 6 个入口各 ~30% 有效；LduCfg 的 6 个异常位各 ~12%（候选率约一半）；robIdx 从
//   16 值小池（flag x value 0..7）里抽、uopIdx 只取 0..3 —— 同龄（robIdx 相等、比 uopIdx）、
//   绕圈比较、7 个选手互相比都常态出现；地址字段全随机。redirect ~8%，robIdx 同池
//   （本拍冲掉 s2 候选 / 冲掉已记着的那条都会发生）。每 20000 拍一次 3 拍复位。
// ★比较口径★ req 的信息寄存器不复位，但每拍无条件写"锦标赛胜者"：全无效时胜者就是
//   它自己（保持），所以在它第一次记下一条有效异常之前，两侧各保持自己的上电随机值。
//   随机 initreg 档里 5 个输出只在 golden 的 req_valid 第一次为 1 之后才比；
//   +vcs+initreg+0 / +1 两个常量档从第一拍起比。req_valid 本身（复位域）不是输出，
//   它的对错经由"何时开始换记另一条"间接可见。
// ★覆盖★ COVERAGE 行各项为 0 本轮判红。
// 自动生成：scripts/gen_lqexcbuf.py —— 勿手改
// ===========================================================================
`timescale 1ns/1ps

module tb;
  import lqexceptionbuffer_pkg::*;

  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;
  int      errors = 0;
  longint  checks = 0;
  bit      cmp_all = 0;
  bit      written = 0;
  always #5 clk = ~clk;

  logic            io_redirect_valid;
  logic            io_redirect_bits_robIdx_flag;
  logic [7:0]      io_redirect_bits_robIdx_value;
  logic            io_redirect_bits_level;
  logic [5:0]      req_valid;
  leb_req_t        req_bits [6];

  localparam int NOW = 131;
  wire [NOW-1:0] g_out, x_out;

  LqExceptionBuffer u_g (
    .clock                              (clk),
    .reset                              (rst),
    .io_redirect_valid                  (io_redirect_valid),
    .io_redirect_bits_robIdx_flag       (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value      (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level             (io_redirect_bits_level),
    .io_req_0_valid                     (req_valid[0]),
    .io_req_0_bits_uop_exceptionVec_3   (req_bits[0].uop_exceptionVec_3),
    .io_req_0_bits_uop_exceptionVec_4   (req_bits[0].uop_exceptionVec_4),
    .io_req_0_bits_uop_exceptionVec_5   (req_bits[0].uop_exceptionVec_5),
    .io_req_0_bits_uop_exceptionVec_13  (req_bits[0].uop_exceptionVec_13),
    .io_req_0_bits_uop_exceptionVec_19  (req_bits[0].uop_exceptionVec_19),
    .io_req_0_bits_uop_exceptionVec_21  (req_bits[0].uop_exceptionVec_21),
    .io_req_0_bits_uop_uopIdx           (req_bits[0].uop_uopIdx),
    .io_req_0_bits_uop_robIdx_flag      (req_bits[0].uop_robIdx_flag),
    .io_req_0_bits_uop_robIdx_value     (req_bits[0].uop_robIdx_value),
    .io_req_0_bits_fullva               (req_bits[0].fullva),
    .io_req_0_bits_vaNeedExt            (req_bits[0].vaNeedExt),
    .io_req_0_bits_gpaddr               (req_bits[0].gpaddr),
    .io_req_0_bits_isHyper              (req_bits[0].isHyper),
    .io_req_0_bits_isForVSnonLeafPTE    (req_bits[0].isForVSnonLeafPTE),
    .io_req_1_valid                     (req_valid[1]),
    .io_req_1_bits_uop_exceptionVec_3   (req_bits[1].uop_exceptionVec_3),
    .io_req_1_bits_uop_exceptionVec_4   (req_bits[1].uop_exceptionVec_4),
    .io_req_1_bits_uop_exceptionVec_5   (req_bits[1].uop_exceptionVec_5),
    .io_req_1_bits_uop_exceptionVec_13  (req_bits[1].uop_exceptionVec_13),
    .io_req_1_bits_uop_exceptionVec_19  (req_bits[1].uop_exceptionVec_19),
    .io_req_1_bits_uop_exceptionVec_21  (req_bits[1].uop_exceptionVec_21),
    .io_req_1_bits_uop_uopIdx           (req_bits[1].uop_uopIdx),
    .io_req_1_bits_uop_robIdx_flag      (req_bits[1].uop_robIdx_flag),
    .io_req_1_bits_uop_robIdx_value     (req_bits[1].uop_robIdx_value),
    .io_req_1_bits_fullva               (req_bits[1].fullva),
    .io_req_1_bits_vaNeedExt            (req_bits[1].vaNeedExt),
    .io_req_1_bits_gpaddr               (req_bits[1].gpaddr),
    .io_req_1_bits_isHyper              (req_bits[1].isHyper),
    .io_req_1_bits_isForVSnonLeafPTE    (req_bits[1].isForVSnonLeafPTE),
    .io_req_2_valid                     (req_valid[2]),
    .io_req_2_bits_uop_exceptionVec_3   (req_bits[2].uop_exceptionVec_3),
    .io_req_2_bits_uop_exceptionVec_4   (req_bits[2].uop_exceptionVec_4),
    .io_req_2_bits_uop_exceptionVec_5   (req_bits[2].uop_exceptionVec_5),
    .io_req_2_bits_uop_exceptionVec_13  (req_bits[2].uop_exceptionVec_13),
    .io_req_2_bits_uop_exceptionVec_19  (req_bits[2].uop_exceptionVec_19),
    .io_req_2_bits_uop_exceptionVec_21  (req_bits[2].uop_exceptionVec_21),
    .io_req_2_bits_uop_uopIdx           (req_bits[2].uop_uopIdx),
    .io_req_2_bits_uop_robIdx_flag      (req_bits[2].uop_robIdx_flag),
    .io_req_2_bits_uop_robIdx_value     (req_bits[2].uop_robIdx_value),
    .io_req_2_bits_fullva               (req_bits[2].fullva),
    .io_req_2_bits_vaNeedExt            (req_bits[2].vaNeedExt),
    .io_req_2_bits_gpaddr               (req_bits[2].gpaddr),
    .io_req_2_bits_isHyper              (req_bits[2].isHyper),
    .io_req_2_bits_isForVSnonLeafPTE    (req_bits[2].isForVSnonLeafPTE),
    .io_req_3_valid                     (req_valid[3]),
    .io_req_3_bits_uop_exceptionVec_3   (req_bits[3].uop_exceptionVec_3),
    .io_req_3_bits_uop_exceptionVec_4   (req_bits[3].uop_exceptionVec_4),
    .io_req_3_bits_uop_exceptionVec_5   (req_bits[3].uop_exceptionVec_5),
    .io_req_3_bits_uop_exceptionVec_13  (req_bits[3].uop_exceptionVec_13),
    .io_req_3_bits_uop_exceptionVec_19  (req_bits[3].uop_exceptionVec_19),
    .io_req_3_bits_uop_exceptionVec_21  (req_bits[3].uop_exceptionVec_21),
    .io_req_3_bits_uop_uopIdx           (req_bits[3].uop_uopIdx),
    .io_req_3_bits_uop_robIdx_flag      (req_bits[3].uop_robIdx_flag),
    .io_req_3_bits_uop_robIdx_value     (req_bits[3].uop_robIdx_value),
    .io_req_3_bits_fullva               (req_bits[3].fullva),
    .io_req_3_bits_vaNeedExt            (req_bits[3].vaNeedExt),
    .io_req_3_bits_gpaddr               (req_bits[3].gpaddr),
    .io_req_3_bits_isForVSnonLeafPTE    (req_bits[3].isForVSnonLeafPTE),
    .io_req_4_valid                     (req_valid[4]),
    .io_req_4_bits_uop_exceptionVec_3   (req_bits[4].uop_exceptionVec_3),
    .io_req_4_bits_uop_exceptionVec_4   (req_bits[4].uop_exceptionVec_4),
    .io_req_4_bits_uop_exceptionVec_5   (req_bits[4].uop_exceptionVec_5),
    .io_req_4_bits_uop_exceptionVec_13  (req_bits[4].uop_exceptionVec_13),
    .io_req_4_bits_uop_exceptionVec_19  (req_bits[4].uop_exceptionVec_19),
    .io_req_4_bits_uop_exceptionVec_21  (req_bits[4].uop_exceptionVec_21),
    .io_req_4_bits_uop_uopIdx           (req_bits[4].uop_uopIdx),
    .io_req_4_bits_uop_robIdx_flag      (req_bits[4].uop_robIdx_flag),
    .io_req_4_bits_uop_robIdx_value     (req_bits[4].uop_robIdx_value),
    .io_req_4_bits_fullva               (req_bits[4].fullva),
    .io_req_4_bits_vaNeedExt            (req_bits[4].vaNeedExt),
    .io_req_4_bits_gpaddr               (req_bits[4].gpaddr),
    .io_req_4_bits_isForVSnonLeafPTE    (req_bits[4].isForVSnonLeafPTE),
    .io_req_5_valid                     (req_valid[5]),
    .io_req_5_bits_uop_exceptionVec_3   (req_bits[5].uop_exceptionVec_3),
    .io_req_5_bits_uop_exceptionVec_4   (req_bits[5].uop_exceptionVec_4),
    .io_req_5_bits_uop_exceptionVec_5   (req_bits[5].uop_exceptionVec_5),
    .io_req_5_bits_uop_exceptionVec_13  (req_bits[5].uop_exceptionVec_13),
    .io_req_5_bits_uop_exceptionVec_19  (req_bits[5].uop_exceptionVec_19),
    .io_req_5_bits_uop_exceptionVec_21  (req_bits[5].uop_exceptionVec_21),
    .io_req_5_bits_uop_uopIdx           (req_bits[5].uop_uopIdx),
    .io_req_5_bits_uop_robIdx_flag      (req_bits[5].uop_robIdx_flag),
    .io_req_5_bits_uop_robIdx_value     (req_bits[5].uop_robIdx_value),
    .io_req_5_bits_fullva               (req_bits[5].fullva),
    .io_req_5_bits_gpaddr               (req_bits[5].gpaddr),
    .io_req_5_bits_isHyper              (req_bits[5].isHyper),
    .io_req_5_bits_isForVSnonLeafPTE    (req_bits[5].isForVSnonLeafPTE),
    .io_exceptionAddr_vaddr             (g_out[0 +: 64]),
    .io_exceptionAddr_vaNeedExt         (g_out[64 +: 1]),
    .io_exceptionAddr_isHyper           (g_out[65 +: 1]),
    .io_exceptionAddr_gpaddr            (g_out[66 +: 64]),
    .io_exceptionAddr_isForVSnonLeafPTE (g_out[130 +: 1])
  );
  LqExceptionBuffer_xs u_x (
    .clock                              (clk),
    .reset                              (rst),
    .io_redirect_valid                  (io_redirect_valid),
    .io_redirect_bits_robIdx_flag       (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value      (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level             (io_redirect_bits_level),
    .io_req_0_valid                     (req_valid[0]),
    .io_req_0_bits_uop_exceptionVec_3   (req_bits[0].uop_exceptionVec_3),
    .io_req_0_bits_uop_exceptionVec_4   (req_bits[0].uop_exceptionVec_4),
    .io_req_0_bits_uop_exceptionVec_5   (req_bits[0].uop_exceptionVec_5),
    .io_req_0_bits_uop_exceptionVec_13  (req_bits[0].uop_exceptionVec_13),
    .io_req_0_bits_uop_exceptionVec_19  (req_bits[0].uop_exceptionVec_19),
    .io_req_0_bits_uop_exceptionVec_21  (req_bits[0].uop_exceptionVec_21),
    .io_req_0_bits_uop_uopIdx           (req_bits[0].uop_uopIdx),
    .io_req_0_bits_uop_robIdx_flag      (req_bits[0].uop_robIdx_flag),
    .io_req_0_bits_uop_robIdx_value     (req_bits[0].uop_robIdx_value),
    .io_req_0_bits_fullva               (req_bits[0].fullva),
    .io_req_0_bits_vaNeedExt            (req_bits[0].vaNeedExt),
    .io_req_0_bits_gpaddr               (req_bits[0].gpaddr),
    .io_req_0_bits_isHyper              (req_bits[0].isHyper),
    .io_req_0_bits_isForVSnonLeafPTE    (req_bits[0].isForVSnonLeafPTE),
    .io_req_1_valid                     (req_valid[1]),
    .io_req_1_bits_uop_exceptionVec_3   (req_bits[1].uop_exceptionVec_3),
    .io_req_1_bits_uop_exceptionVec_4   (req_bits[1].uop_exceptionVec_4),
    .io_req_1_bits_uop_exceptionVec_5   (req_bits[1].uop_exceptionVec_5),
    .io_req_1_bits_uop_exceptionVec_13  (req_bits[1].uop_exceptionVec_13),
    .io_req_1_bits_uop_exceptionVec_19  (req_bits[1].uop_exceptionVec_19),
    .io_req_1_bits_uop_exceptionVec_21  (req_bits[1].uop_exceptionVec_21),
    .io_req_1_bits_uop_uopIdx           (req_bits[1].uop_uopIdx),
    .io_req_1_bits_uop_robIdx_flag      (req_bits[1].uop_robIdx_flag),
    .io_req_1_bits_uop_robIdx_value     (req_bits[1].uop_robIdx_value),
    .io_req_1_bits_fullva               (req_bits[1].fullva),
    .io_req_1_bits_vaNeedExt            (req_bits[1].vaNeedExt),
    .io_req_1_bits_gpaddr               (req_bits[1].gpaddr),
    .io_req_1_bits_isHyper              (req_bits[1].isHyper),
    .io_req_1_bits_isForVSnonLeafPTE    (req_bits[1].isForVSnonLeafPTE),
    .io_req_2_valid                     (req_valid[2]),
    .io_req_2_bits_uop_exceptionVec_3   (req_bits[2].uop_exceptionVec_3),
    .io_req_2_bits_uop_exceptionVec_4   (req_bits[2].uop_exceptionVec_4),
    .io_req_2_bits_uop_exceptionVec_5   (req_bits[2].uop_exceptionVec_5),
    .io_req_2_bits_uop_exceptionVec_13  (req_bits[2].uop_exceptionVec_13),
    .io_req_2_bits_uop_exceptionVec_19  (req_bits[2].uop_exceptionVec_19),
    .io_req_2_bits_uop_exceptionVec_21  (req_bits[2].uop_exceptionVec_21),
    .io_req_2_bits_uop_uopIdx           (req_bits[2].uop_uopIdx),
    .io_req_2_bits_uop_robIdx_flag      (req_bits[2].uop_robIdx_flag),
    .io_req_2_bits_uop_robIdx_value     (req_bits[2].uop_robIdx_value),
    .io_req_2_bits_fullva               (req_bits[2].fullva),
    .io_req_2_bits_vaNeedExt            (req_bits[2].vaNeedExt),
    .io_req_2_bits_gpaddr               (req_bits[2].gpaddr),
    .io_req_2_bits_isHyper              (req_bits[2].isHyper),
    .io_req_2_bits_isForVSnonLeafPTE    (req_bits[2].isForVSnonLeafPTE),
    .io_req_3_valid                     (req_valid[3]),
    .io_req_3_bits_uop_exceptionVec_3   (req_bits[3].uop_exceptionVec_3),
    .io_req_3_bits_uop_exceptionVec_4   (req_bits[3].uop_exceptionVec_4),
    .io_req_3_bits_uop_exceptionVec_5   (req_bits[3].uop_exceptionVec_5),
    .io_req_3_bits_uop_exceptionVec_13  (req_bits[3].uop_exceptionVec_13),
    .io_req_3_bits_uop_exceptionVec_19  (req_bits[3].uop_exceptionVec_19),
    .io_req_3_bits_uop_exceptionVec_21  (req_bits[3].uop_exceptionVec_21),
    .io_req_3_bits_uop_uopIdx           (req_bits[3].uop_uopIdx),
    .io_req_3_bits_uop_robIdx_flag      (req_bits[3].uop_robIdx_flag),
    .io_req_3_bits_uop_robIdx_value     (req_bits[3].uop_robIdx_value),
    .io_req_3_bits_fullva               (req_bits[3].fullva),
    .io_req_3_bits_vaNeedExt            (req_bits[3].vaNeedExt),
    .io_req_3_bits_gpaddr               (req_bits[3].gpaddr),
    .io_req_3_bits_isForVSnonLeafPTE    (req_bits[3].isForVSnonLeafPTE),
    .io_req_4_valid                     (req_valid[4]),
    .io_req_4_bits_uop_exceptionVec_3   (req_bits[4].uop_exceptionVec_3),
    .io_req_4_bits_uop_exceptionVec_4   (req_bits[4].uop_exceptionVec_4),
    .io_req_4_bits_uop_exceptionVec_5   (req_bits[4].uop_exceptionVec_5),
    .io_req_4_bits_uop_exceptionVec_13  (req_bits[4].uop_exceptionVec_13),
    .io_req_4_bits_uop_exceptionVec_19  (req_bits[4].uop_exceptionVec_19),
    .io_req_4_bits_uop_exceptionVec_21  (req_bits[4].uop_exceptionVec_21),
    .io_req_4_bits_uop_uopIdx           (req_bits[4].uop_uopIdx),
    .io_req_4_bits_uop_robIdx_flag      (req_bits[4].uop_robIdx_flag),
    .io_req_4_bits_uop_robIdx_value     (req_bits[4].uop_robIdx_value),
    .io_req_4_bits_fullva               (req_bits[4].fullva),
    .io_req_4_bits_vaNeedExt            (req_bits[4].vaNeedExt),
    .io_req_4_bits_gpaddr               (req_bits[4].gpaddr),
    .io_req_4_bits_isForVSnonLeafPTE    (req_bits[4].isForVSnonLeafPTE),
    .io_req_5_valid                     (req_valid[5]),
    .io_req_5_bits_uop_exceptionVec_3   (req_bits[5].uop_exceptionVec_3),
    .io_req_5_bits_uop_exceptionVec_4   (req_bits[5].uop_exceptionVec_4),
    .io_req_5_bits_uop_exceptionVec_5   (req_bits[5].uop_exceptionVec_5),
    .io_req_5_bits_uop_exceptionVec_13  (req_bits[5].uop_exceptionVec_13),
    .io_req_5_bits_uop_exceptionVec_19  (req_bits[5].uop_exceptionVec_19),
    .io_req_5_bits_uop_exceptionVec_21  (req_bits[5].uop_exceptionVec_21),
    .io_req_5_bits_uop_uopIdx           (req_bits[5].uop_uopIdx),
    .io_req_5_bits_uop_robIdx_flag      (req_bits[5].uop_robIdx_flag),
    .io_req_5_bits_uop_robIdx_value     (req_bits[5].uop_robIdx_value),
    .io_req_5_bits_fullva               (req_bits[5].fullva),
    .io_req_5_bits_gpaddr               (req_bits[5].gpaddr),
    .io_req_5_bits_isHyper              (req_bits[5].isHyper),
    .io_req_5_bits_isForVSnonLeafPTE    (req_bits[5].isForVSnonLeafPTE),
    .io_exceptionAddr_vaddr             (x_out[0 +: 64]),
    .io_exceptionAddr_vaNeedExt         (x_out[64 +: 1]),
    .io_exceptionAddr_isHyper           (x_out[65 +: 1]),
    .io_exceptionAddr_gpaddr            (x_out[66 +: 64]),
    .io_exceptionAddr_isForVSnonLeafPTE (x_out[130 +: 1])
  );

  longint cov_cand = 0, cov_multi = 0, cov_replace = 0, cov_keep = 0, cov_tie = 0, cov_flush = 0, cov_reset = 0;
  logic [63:0] prev_vaddr;

  task automatic quiet();
    io_redirect_valid = 0; io_redirect_bits_robIdx_flag = 0; io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0; req_valid = 0;
    for (int p = 0; p < 6; p++) req_bits[p] = '0;
  endtask

  task automatic drive();
    logic [$bits(leb_req_t)+31:0] rnd;
    io_redirect_valid = ($urandom_range(0, 99) < 8);
    io_redirect_bits_robIdx_flag = $urandom_range(0, 1);
    io_redirect_bits_robIdx_value = 8'($urandom_range(0, 7));
    io_redirect_bits_level = $urandom_range(0, 1);
    for (int p = 0; p < 6; p++) begin
      for (int b = 0; b < $bits(leb_req_t); b += 32) rnd[b +: 32] = $urandom();
      req_bits[p] = rnd[$bits(leb_req_t)-1:0];
      req_valid[p] = ($urandom_range(0, 99) < 30);
      req_bits[p].uop_robIdx_flag = $urandom_range(0, 1);
      req_bits[p].uop_robIdx_value = 8'($urandom_range(0, 7));
      req_bits[p].uop_uopIdx = 7'($urandom_range(0, 3));
      req_bits[p].uop_exceptionVec_3  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_4  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_5  = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_13 = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_19 = ($urandom_range(0, 99) < 12);
      req_bits[p].uop_exceptionVec_21 = ($urandom_range(0, 99) < 12);
    end
  endtask

  task automatic compare(int cyc);
    if (u_g.req_valid) written = 1;
    checks++;
    if ((cmp_all || written) && g_out !== x_out) begin
      errors++;
      if (errors <= 20) $display("[%0d] MISMATCH g=%h x=%h", cyc, g_out, x_out);
    end
  endtask

  task automatic sample();   // 时钟沿之前：看即将被采下的量
    int n;
    n = 0;
    for (int p = 0; p < 6; p++) if (u_x.u_core.s2_enqueue[p]) n++;
    cov_cand += n;
    if (n >= 2) cov_multi++;
    if (u_x.u_core.cand[6].valid && n > 0) begin
      if (u_x.u_core.winner.bits == u_x.u_core.req_q) cov_keep++; else cov_replace++;
    end
    for (int p = 0; p < 6; p++)
      for (int q = p + 1; q < 6; q++)
        if (u_x.u_core.s2_enqueue[p] && u_x.u_core.s2_enqueue[q]
            && u_x.u_core.s2_req[p].uop_robIdx_flag == u_x.u_core.s2_req[q].uop_robIdx_flag
            && u_x.u_core.s2_req[p].uop_robIdx_value == u_x.u_core.s2_req[q].uop_robIdx_value)
          cov_tie++;
    if (u_x.u_core.req_valid_q && !u_x.u_core.cand[6].valid) cov_flush++;
  endtask

  initial begin
    string ir;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    if ($value$plusargs("vcs+initreg+%s", ir) && (ir == "0" || ir == "1")) cmp_all = 1;
    rst = 1'b1;
    quiet();
    repeat (4) @(posedge clk);
    #1 rst = 1'b0;
    for (int cyc = 0; cyc < NCYCLES; cyc++) begin
      if (cyc % 20000 == 10000) begin
        rst = 1'b1; quiet(); cov_reset++;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
      end
      drive();
      #1 compare(cyc);
      sample();
      @(posedge clk);
      #1;
    end
    $display("COVERAGE cand=%0d multi=%0d replace=%0d keep=%0d tie=%0d flush_held=%0d reset=%0d",
             cov_cand, cov_multi, cov_replace, cov_keep, cov_tie, cov_flush, cov_reset);
    if (cov_cand == 0 || cov_multi == 0 || cov_replace == 0 || cov_keep == 0 || cov_tie == 0
        || cov_flush == 0 || cov_reset == 0) begin
      $display("COVERAGE HOLE -> run does not count");
      errors++;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
