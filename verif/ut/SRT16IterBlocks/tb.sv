// =============================================================================
// tb —— SRT radix-16 整数除法迭代块 UT（SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6}）
//
// (A) 块级双例化：五个块各自 golden vs 重写（_xs），每拍随机灌全部输入、逐拍比全部
//     输出。商位独热口（io_q_j / io_q_j_1）80% 取独热、20% 取任意 5 位（golden 的
//     Mux1H 是按位或，多热也要一致）；每拍另有 1/16 概率全 0、1/16 全 1。
// (B) 系统级：golden SRT16Divint{,_4,_6} 与「同一 golden 父级、但 IterBlock 子树换成
//     重写件」的副本（ut_gen/subst_*.sv）各一对，由 div_lane 跑真实除法：逐拍对拍
//     + 独立 oracle（商/余数逐位对照 RISC-V 语义：除零、负数、最小值/-1、各 SEW）。
//     这一层让重写件处在真实的商位/余数分布下，补块级随机激励覆盖不到的「合法轨迹」。
// 判据：两部分 errors 合计 0 才打印 TEST PASSED。
// 本文件由 verif/ut/SRT16IterBlocks/gen.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;

  function automatic logic [127:0] rnd_bits(input int mode);
    if (mode == 1) return '0;
    if (mode == 2) return '1;
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  function automatic logic [4:0] pick_q(input int mode);
    if (mode == 1) return '0;
    if (mode == 2) return '1;
    if ($urandom_range(0, 9) < 8) return 5'd1 << $urandom_range(0, 4);
    return 5'($urandom);
  endfunction
  // 商位输出分类：0..4 = 独热第 i 位，5 = 全 0，6 = 多热
  function automatic int q_class(input logic [4:0] q);
    if (q == 0) return 5;
    if ($onehot(q)) for (int i = 0; i < 5; i++) if (q[i]) return i;
    return 6;
  endfunction
  longint qhist_SelBlock_v4 [7] = '{default: 0};
  longint qhist_SpecBlock_v4 [7] = '{default: 0};
  // ---------------- SelBlock_v4（31 入 / 9 出）----------------
  logic [4:0] SelBlock_v4__io_q_j;
  logic [7:0] SelBlock_v4__io_cons_0_0;
  logic [7:0] SelBlock_v4__io_cons_0_1;
  logic [7:0] SelBlock_v4__io_cons_0_2;
  logic [7:0] SelBlock_v4__io_cons_0_3;
  logic [7:0] SelBlock_v4__io_cons_1_0;
  logic [7:0] SelBlock_v4__io_cons_1_1;
  logic [7:0] SelBlock_v4__io_cons_1_2;
  logic [7:0] SelBlock_v4__io_cons_1_3;
  logic [7:0] SelBlock_v4__io_cons_2_0;
  logic [7:0] SelBlock_v4__io_cons_2_1;
  logic [7:0] SelBlock_v4__io_cons_2_2;
  logic [7:0] SelBlock_v4__io_cons_2_3;
  logic [7:0] SelBlock_v4__io_cons_3_0;
  logic [7:0] SelBlock_v4__io_cons_3_1;
  logic [7:0] SelBlock_v4__io_cons_3_2;
  logic [7:0] SelBlock_v4__io_cons_3_3;
  logic [7:0] SelBlock_v4__io_cons_4_0;
  logic [7:0] SelBlock_v4__io_cons_4_1;
  logic [7:0] SelBlock_v4__io_cons_4_2;
  logic [7:0] SelBlock_v4__io_cons_4_3;
  logic [7:0] SelBlock_v4__io_rem_3_5_0;
  logic [7:0] SelBlock_v4__io_rem_3_5_1;
  logic [7:0] SelBlock_v4__io_pre_sel_0_0;
  logic [7:0] SelBlock_v4__io_pre_sel_0_1;
  logic [7:0] SelBlock_v4__io_pre_sel_1_0;
  logic [7:0] SelBlock_v4__io_pre_sel_1_1;
  logic [7:0] SelBlock_v4__io_pre_sel_2_0;
  logic [7:0] SelBlock_v4__io_pre_sel_2_1;
  logic [7:0] SelBlock_v4__io_pre_sel_3_0;
  logic [7:0] SelBlock_v4__io_pre_sel_3_1;
  wire  [4:0] SelBlock_v4__g__io_q_j_1, SelBlock_v4__i__io_q_j_1;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_0_0, SelBlock_v4__i__io_nxt_sel_0_0;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_0_1, SelBlock_v4__i__io_nxt_sel_0_1;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_1_0, SelBlock_v4__i__io_nxt_sel_1_0;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_1_1, SelBlock_v4__i__io_nxt_sel_1_1;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_2_0, SelBlock_v4__i__io_nxt_sel_2_0;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_2_1, SelBlock_v4__i__io_nxt_sel_2_1;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_3_0, SelBlock_v4__i__io_nxt_sel_3_0;
  wire  [7:0] SelBlock_v4__g__io_nxt_sel_3_1, SelBlock_v4__i__io_nxt_sel_3_1;
  SelBlock_v4 u_g_SelBlock_v4 (
    .io_q_j(SelBlock_v4__io_q_j),
    .io_cons_0_0(SelBlock_v4__io_cons_0_0),
    .io_cons_0_1(SelBlock_v4__io_cons_0_1),
    .io_cons_0_2(SelBlock_v4__io_cons_0_2),
    .io_cons_0_3(SelBlock_v4__io_cons_0_3),
    .io_cons_1_0(SelBlock_v4__io_cons_1_0),
    .io_cons_1_1(SelBlock_v4__io_cons_1_1),
    .io_cons_1_2(SelBlock_v4__io_cons_1_2),
    .io_cons_1_3(SelBlock_v4__io_cons_1_3),
    .io_cons_2_0(SelBlock_v4__io_cons_2_0),
    .io_cons_2_1(SelBlock_v4__io_cons_2_1),
    .io_cons_2_2(SelBlock_v4__io_cons_2_2),
    .io_cons_2_3(SelBlock_v4__io_cons_2_3),
    .io_cons_3_0(SelBlock_v4__io_cons_3_0),
    .io_cons_3_1(SelBlock_v4__io_cons_3_1),
    .io_cons_3_2(SelBlock_v4__io_cons_3_2),
    .io_cons_3_3(SelBlock_v4__io_cons_3_3),
    .io_cons_4_0(SelBlock_v4__io_cons_4_0),
    .io_cons_4_1(SelBlock_v4__io_cons_4_1),
    .io_cons_4_2(SelBlock_v4__io_cons_4_2),
    .io_cons_4_3(SelBlock_v4__io_cons_4_3),
    .io_rem_3_5_0(SelBlock_v4__io_rem_3_5_0),
    .io_rem_3_5_1(SelBlock_v4__io_rem_3_5_1),
    .io_pre_sel_0_0(SelBlock_v4__io_pre_sel_0_0),
    .io_pre_sel_0_1(SelBlock_v4__io_pre_sel_0_1),
    .io_pre_sel_1_0(SelBlock_v4__io_pre_sel_1_0),
    .io_pre_sel_1_1(SelBlock_v4__io_pre_sel_1_1),
    .io_pre_sel_2_0(SelBlock_v4__io_pre_sel_2_0),
    .io_pre_sel_2_1(SelBlock_v4__io_pre_sel_2_1),
    .io_pre_sel_3_0(SelBlock_v4__io_pre_sel_3_0),
    .io_pre_sel_3_1(SelBlock_v4__io_pre_sel_3_1),
    .io_q_j_1(SelBlock_v4__g__io_q_j_1),
    .io_nxt_sel_0_0(SelBlock_v4__g__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(SelBlock_v4__g__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(SelBlock_v4__g__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(SelBlock_v4__g__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(SelBlock_v4__g__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(SelBlock_v4__g__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(SelBlock_v4__g__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(SelBlock_v4__g__io_nxt_sel_3_1)
  );
  SelBlock_v4_xs u_i_SelBlock_v4 (
    .io_q_j(SelBlock_v4__io_q_j),
    .io_cons_0_0(SelBlock_v4__io_cons_0_0),
    .io_cons_0_1(SelBlock_v4__io_cons_0_1),
    .io_cons_0_2(SelBlock_v4__io_cons_0_2),
    .io_cons_0_3(SelBlock_v4__io_cons_0_3),
    .io_cons_1_0(SelBlock_v4__io_cons_1_0),
    .io_cons_1_1(SelBlock_v4__io_cons_1_1),
    .io_cons_1_2(SelBlock_v4__io_cons_1_2),
    .io_cons_1_3(SelBlock_v4__io_cons_1_3),
    .io_cons_2_0(SelBlock_v4__io_cons_2_0),
    .io_cons_2_1(SelBlock_v4__io_cons_2_1),
    .io_cons_2_2(SelBlock_v4__io_cons_2_2),
    .io_cons_2_3(SelBlock_v4__io_cons_2_3),
    .io_cons_3_0(SelBlock_v4__io_cons_3_0),
    .io_cons_3_1(SelBlock_v4__io_cons_3_1),
    .io_cons_3_2(SelBlock_v4__io_cons_3_2),
    .io_cons_3_3(SelBlock_v4__io_cons_3_3),
    .io_cons_4_0(SelBlock_v4__io_cons_4_0),
    .io_cons_4_1(SelBlock_v4__io_cons_4_1),
    .io_cons_4_2(SelBlock_v4__io_cons_4_2),
    .io_cons_4_3(SelBlock_v4__io_cons_4_3),
    .io_rem_3_5_0(SelBlock_v4__io_rem_3_5_0),
    .io_rem_3_5_1(SelBlock_v4__io_rem_3_5_1),
    .io_pre_sel_0_0(SelBlock_v4__io_pre_sel_0_0),
    .io_pre_sel_0_1(SelBlock_v4__io_pre_sel_0_1),
    .io_pre_sel_1_0(SelBlock_v4__io_pre_sel_1_0),
    .io_pre_sel_1_1(SelBlock_v4__io_pre_sel_1_1),
    .io_pre_sel_2_0(SelBlock_v4__io_pre_sel_2_0),
    .io_pre_sel_2_1(SelBlock_v4__io_pre_sel_2_1),
    .io_pre_sel_3_0(SelBlock_v4__io_pre_sel_3_0),
    .io_pre_sel_3_1(SelBlock_v4__io_pre_sel_3_1),
    .io_q_j_1(SelBlock_v4__i__io_q_j_1),
    .io_nxt_sel_0_0(SelBlock_v4__i__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(SelBlock_v4__i__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(SelBlock_v4__i__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(SelBlock_v4__i__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(SelBlock_v4__i__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(SelBlock_v4__i__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(SelBlock_v4__i__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(SelBlock_v4__i__io_nxt_sel_3_1)
  );
  task automatic drive_SelBlock_v4(input int mode);
    SelBlock_v4__io_q_j = pick_q(mode);
    SelBlock_v4__io_cons_0_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_0_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_0_2 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_0_3 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_1_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_1_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_1_2 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_1_3 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_2_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_2_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_2_2 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_2_3 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_3_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_3_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_3_2 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_3_3 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_4_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_4_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_4_2 = 8'(rnd_bits(mode));
    SelBlock_v4__io_cons_4_3 = 8'(rnd_bits(mode));
    SelBlock_v4__io_rem_3_5_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_rem_3_5_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_0_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_0_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_1_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_1_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_2_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_2_1 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_3_0 = 8'(rnd_bits(mode));
    SelBlock_v4__io_pre_sel_3_1 = 8'(rnd_bits(mode));
  endtask
  task automatic check_SelBlock_v4();
    checks++;
    if (SelBlock_v4__g__io_q_j_1 !== SelBlock_v4__i__io_q_j_1) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_q_j_1 g=%h i=%h", SelBlock_v4__g__io_q_j_1, SelBlock_v4__i__io_q_j_1); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_0_0 !== SelBlock_v4__i__io_nxt_sel_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_0_0 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_0_0, SelBlock_v4__i__io_nxt_sel_0_0); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_0_1 !== SelBlock_v4__i__io_nxt_sel_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_0_1 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_0_1, SelBlock_v4__i__io_nxt_sel_0_1); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_1_0 !== SelBlock_v4__i__io_nxt_sel_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_1_0 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_1_0, SelBlock_v4__i__io_nxt_sel_1_0); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_1_1 !== SelBlock_v4__i__io_nxt_sel_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_1_1 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_1_1, SelBlock_v4__i__io_nxt_sel_1_1); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_2_0 !== SelBlock_v4__i__io_nxt_sel_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_2_0 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_2_0, SelBlock_v4__i__io_nxt_sel_2_0); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_2_1 !== SelBlock_v4__i__io_nxt_sel_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_2_1 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_2_1, SelBlock_v4__i__io_nxt_sel_2_1); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_3_0 !== SelBlock_v4__i__io_nxt_sel_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_3_0 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_3_0, SelBlock_v4__i__io_nxt_sel_3_0); end
    checks++;
    if (SelBlock_v4__g__io_nxt_sel_3_1 !== SelBlock_v4__i__io_nxt_sel_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SelBlock_v4.io_nxt_sel_3_1 g=%h i=%h", SelBlock_v4__g__io_nxt_sel_3_1, SelBlock_v4__i__io_nxt_sel_3_1); end
    qhist_SelBlock_v4[q_class(SelBlock_v4__g__io_q_j_1)]++;
  endtask
  // ---------------- SpecBlock_v4（68 入 / 41 出）----------------
  logic [4:0] SpecBlock_v4__io_q_j;
  logic [8:0] SpecBlock_v4__io_cons_0_0;
  logic [8:0] SpecBlock_v4__io_cons_0_1;
  logic [8:0] SpecBlock_v4__io_cons_0_2;
  logic [8:0] SpecBlock_v4__io_cons_0_3;
  logic [8:0] SpecBlock_v4__io_cons_1_0;
  logic [8:0] SpecBlock_v4__io_cons_1_1;
  logic [8:0] SpecBlock_v4__io_cons_1_2;
  logic [8:0] SpecBlock_v4__io_cons_1_3;
  logic [8:0] SpecBlock_v4__io_cons_2_0;
  logic [8:0] SpecBlock_v4__io_cons_2_1;
  logic [8:0] SpecBlock_v4__io_cons_2_2;
  logic [8:0] SpecBlock_v4__io_cons_2_3;
  logic [8:0] SpecBlock_v4__io_cons_3_0;
  logic [8:0] SpecBlock_v4__io_cons_3_1;
  logic [8:0] SpecBlock_v4__io_cons_3_2;
  logic [8:0] SpecBlock_v4__io_cons_3_3;
  logic [8:0] SpecBlock_v4__io_cons_4_0;
  logic [8:0] SpecBlock_v4__io_cons_4_1;
  logic [8:0] SpecBlock_v4__io_cons_4_2;
  logic [8:0] SpecBlock_v4__io_cons_4_3;
  logic [8:0] SpecBlock_v4__io_d_trunc_0;
  logic [8:0] SpecBlock_v4__io_d_trunc_1;
  logic [8:0] SpecBlock_v4__io_d_trunc_2;
  logic [8:0] SpecBlock_v4__io_d_trunc_3;
  logic [4:0] SpecBlock_v4__io_q_j_1;
  logic [8:0] SpecBlock_v4__io_rem_3_5_0;
  logic [8:0] SpecBlock_v4__io_rem_3_5_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_0_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_0_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_1_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_1_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_2_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_2_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_3_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_0_3_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_0_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_0_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_1_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_1_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_2_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_2_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_3_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_1_3_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_0_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_0_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_1_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_1_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_2_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_2_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_3_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_2_3_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_0_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_0_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_1_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_1_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_2_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_2_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_3_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_3_3_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_0_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_0_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_1_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_1_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_2_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_2_1;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_3_0;
  logic [8:0] SpecBlock_v4__io_pre_spec_4_3_1;
  wire  [4:0] SpecBlock_v4__g__io_q_j_2, SpecBlock_v4__i__io_q_j_2;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_0_0, SpecBlock_v4__i__io_nxt_spec_0_0_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_0_1, SpecBlock_v4__i__io_nxt_spec_0_0_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_1_0, SpecBlock_v4__i__io_nxt_spec_0_1_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_1_1, SpecBlock_v4__i__io_nxt_spec_0_1_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_2_0, SpecBlock_v4__i__io_nxt_spec_0_2_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_2_1, SpecBlock_v4__i__io_nxt_spec_0_2_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_3_0, SpecBlock_v4__i__io_nxt_spec_0_3_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_0_3_1, SpecBlock_v4__i__io_nxt_spec_0_3_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_0_0, SpecBlock_v4__i__io_nxt_spec_1_0_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_0_1, SpecBlock_v4__i__io_nxt_spec_1_0_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_1_0, SpecBlock_v4__i__io_nxt_spec_1_1_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_1_1, SpecBlock_v4__i__io_nxt_spec_1_1_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_2_0, SpecBlock_v4__i__io_nxt_spec_1_2_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_2_1, SpecBlock_v4__i__io_nxt_spec_1_2_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_3_0, SpecBlock_v4__i__io_nxt_spec_1_3_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_1_3_1, SpecBlock_v4__i__io_nxt_spec_1_3_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_0_0, SpecBlock_v4__i__io_nxt_spec_2_0_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_0_1, SpecBlock_v4__i__io_nxt_spec_2_0_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_1_0, SpecBlock_v4__i__io_nxt_spec_2_1_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_1_1, SpecBlock_v4__i__io_nxt_spec_2_1_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_2_0, SpecBlock_v4__i__io_nxt_spec_2_2_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_2_1, SpecBlock_v4__i__io_nxt_spec_2_2_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_3_0, SpecBlock_v4__i__io_nxt_spec_2_3_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_2_3_1, SpecBlock_v4__i__io_nxt_spec_2_3_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_0_0, SpecBlock_v4__i__io_nxt_spec_3_0_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_0_1, SpecBlock_v4__i__io_nxt_spec_3_0_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_1_0, SpecBlock_v4__i__io_nxt_spec_3_1_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_1_1, SpecBlock_v4__i__io_nxt_spec_3_1_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_2_0, SpecBlock_v4__i__io_nxt_spec_3_2_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_2_1, SpecBlock_v4__i__io_nxt_spec_3_2_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_3_0, SpecBlock_v4__i__io_nxt_spec_3_3_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_3_3_1, SpecBlock_v4__i__io_nxt_spec_3_3_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_0_0, SpecBlock_v4__i__io_nxt_spec_4_0_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_0_1, SpecBlock_v4__i__io_nxt_spec_4_0_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_1_0, SpecBlock_v4__i__io_nxt_spec_4_1_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_1_1, SpecBlock_v4__i__io_nxt_spec_4_1_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_2_0, SpecBlock_v4__i__io_nxt_spec_4_2_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_2_1, SpecBlock_v4__i__io_nxt_spec_4_2_1;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_3_0, SpecBlock_v4__i__io_nxt_spec_4_3_0;
  wire  [8:0] SpecBlock_v4__g__io_nxt_spec_4_3_1, SpecBlock_v4__i__io_nxt_spec_4_3_1;
  SpecBlock_v4 u_g_SpecBlock_v4 (
    .io_q_j(SpecBlock_v4__io_q_j),
    .io_cons_0_0(SpecBlock_v4__io_cons_0_0),
    .io_cons_0_1(SpecBlock_v4__io_cons_0_1),
    .io_cons_0_2(SpecBlock_v4__io_cons_0_2),
    .io_cons_0_3(SpecBlock_v4__io_cons_0_3),
    .io_cons_1_0(SpecBlock_v4__io_cons_1_0),
    .io_cons_1_1(SpecBlock_v4__io_cons_1_1),
    .io_cons_1_2(SpecBlock_v4__io_cons_1_2),
    .io_cons_1_3(SpecBlock_v4__io_cons_1_3),
    .io_cons_2_0(SpecBlock_v4__io_cons_2_0),
    .io_cons_2_1(SpecBlock_v4__io_cons_2_1),
    .io_cons_2_2(SpecBlock_v4__io_cons_2_2),
    .io_cons_2_3(SpecBlock_v4__io_cons_2_3),
    .io_cons_3_0(SpecBlock_v4__io_cons_3_0),
    .io_cons_3_1(SpecBlock_v4__io_cons_3_1),
    .io_cons_3_2(SpecBlock_v4__io_cons_3_2),
    .io_cons_3_3(SpecBlock_v4__io_cons_3_3),
    .io_cons_4_0(SpecBlock_v4__io_cons_4_0),
    .io_cons_4_1(SpecBlock_v4__io_cons_4_1),
    .io_cons_4_2(SpecBlock_v4__io_cons_4_2),
    .io_cons_4_3(SpecBlock_v4__io_cons_4_3),
    .io_d_trunc_0(SpecBlock_v4__io_d_trunc_0),
    .io_d_trunc_1(SpecBlock_v4__io_d_trunc_1),
    .io_d_trunc_2(SpecBlock_v4__io_d_trunc_2),
    .io_d_trunc_3(SpecBlock_v4__io_d_trunc_3),
    .io_q_j_1(SpecBlock_v4__io_q_j_1),
    .io_rem_3_5_0(SpecBlock_v4__io_rem_3_5_0),
    .io_rem_3_5_1(SpecBlock_v4__io_rem_3_5_1),
    .io_pre_spec_0_0_0(SpecBlock_v4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(SpecBlock_v4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(SpecBlock_v4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(SpecBlock_v4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(SpecBlock_v4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(SpecBlock_v4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(SpecBlock_v4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(SpecBlock_v4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(SpecBlock_v4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(SpecBlock_v4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(SpecBlock_v4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(SpecBlock_v4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(SpecBlock_v4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(SpecBlock_v4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(SpecBlock_v4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(SpecBlock_v4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(SpecBlock_v4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(SpecBlock_v4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(SpecBlock_v4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(SpecBlock_v4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(SpecBlock_v4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(SpecBlock_v4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(SpecBlock_v4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(SpecBlock_v4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(SpecBlock_v4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(SpecBlock_v4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(SpecBlock_v4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(SpecBlock_v4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(SpecBlock_v4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(SpecBlock_v4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(SpecBlock_v4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(SpecBlock_v4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(SpecBlock_v4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(SpecBlock_v4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(SpecBlock_v4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(SpecBlock_v4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(SpecBlock_v4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(SpecBlock_v4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(SpecBlock_v4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(SpecBlock_v4__io_pre_spec_4_3_1),
    .io_q_j_2(SpecBlock_v4__g__io_q_j_2),
    .io_nxt_spec_0_0_0(SpecBlock_v4__g__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(SpecBlock_v4__g__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(SpecBlock_v4__g__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(SpecBlock_v4__g__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(SpecBlock_v4__g__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(SpecBlock_v4__g__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(SpecBlock_v4__g__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(SpecBlock_v4__g__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(SpecBlock_v4__g__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(SpecBlock_v4__g__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(SpecBlock_v4__g__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(SpecBlock_v4__g__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(SpecBlock_v4__g__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(SpecBlock_v4__g__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(SpecBlock_v4__g__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(SpecBlock_v4__g__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(SpecBlock_v4__g__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(SpecBlock_v4__g__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(SpecBlock_v4__g__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(SpecBlock_v4__g__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(SpecBlock_v4__g__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(SpecBlock_v4__g__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(SpecBlock_v4__g__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(SpecBlock_v4__g__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(SpecBlock_v4__g__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(SpecBlock_v4__g__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(SpecBlock_v4__g__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(SpecBlock_v4__g__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(SpecBlock_v4__g__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(SpecBlock_v4__g__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(SpecBlock_v4__g__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(SpecBlock_v4__g__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(SpecBlock_v4__g__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(SpecBlock_v4__g__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(SpecBlock_v4__g__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(SpecBlock_v4__g__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(SpecBlock_v4__g__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(SpecBlock_v4__g__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(SpecBlock_v4__g__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(SpecBlock_v4__g__io_nxt_spec_4_3_1)
  );
  SpecBlock_v4_xs u_i_SpecBlock_v4 (
    .io_q_j(SpecBlock_v4__io_q_j),
    .io_cons_0_0(SpecBlock_v4__io_cons_0_0),
    .io_cons_0_1(SpecBlock_v4__io_cons_0_1),
    .io_cons_0_2(SpecBlock_v4__io_cons_0_2),
    .io_cons_0_3(SpecBlock_v4__io_cons_0_3),
    .io_cons_1_0(SpecBlock_v4__io_cons_1_0),
    .io_cons_1_1(SpecBlock_v4__io_cons_1_1),
    .io_cons_1_2(SpecBlock_v4__io_cons_1_2),
    .io_cons_1_3(SpecBlock_v4__io_cons_1_3),
    .io_cons_2_0(SpecBlock_v4__io_cons_2_0),
    .io_cons_2_1(SpecBlock_v4__io_cons_2_1),
    .io_cons_2_2(SpecBlock_v4__io_cons_2_2),
    .io_cons_2_3(SpecBlock_v4__io_cons_2_3),
    .io_cons_3_0(SpecBlock_v4__io_cons_3_0),
    .io_cons_3_1(SpecBlock_v4__io_cons_3_1),
    .io_cons_3_2(SpecBlock_v4__io_cons_3_2),
    .io_cons_3_3(SpecBlock_v4__io_cons_3_3),
    .io_cons_4_0(SpecBlock_v4__io_cons_4_0),
    .io_cons_4_1(SpecBlock_v4__io_cons_4_1),
    .io_cons_4_2(SpecBlock_v4__io_cons_4_2),
    .io_cons_4_3(SpecBlock_v4__io_cons_4_3),
    .io_d_trunc_0(SpecBlock_v4__io_d_trunc_0),
    .io_d_trunc_1(SpecBlock_v4__io_d_trunc_1),
    .io_d_trunc_2(SpecBlock_v4__io_d_trunc_2),
    .io_d_trunc_3(SpecBlock_v4__io_d_trunc_3),
    .io_q_j_1(SpecBlock_v4__io_q_j_1),
    .io_rem_3_5_0(SpecBlock_v4__io_rem_3_5_0),
    .io_rem_3_5_1(SpecBlock_v4__io_rem_3_5_1),
    .io_pre_spec_0_0_0(SpecBlock_v4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(SpecBlock_v4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(SpecBlock_v4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(SpecBlock_v4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(SpecBlock_v4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(SpecBlock_v4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(SpecBlock_v4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(SpecBlock_v4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(SpecBlock_v4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(SpecBlock_v4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(SpecBlock_v4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(SpecBlock_v4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(SpecBlock_v4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(SpecBlock_v4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(SpecBlock_v4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(SpecBlock_v4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(SpecBlock_v4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(SpecBlock_v4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(SpecBlock_v4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(SpecBlock_v4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(SpecBlock_v4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(SpecBlock_v4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(SpecBlock_v4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(SpecBlock_v4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(SpecBlock_v4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(SpecBlock_v4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(SpecBlock_v4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(SpecBlock_v4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(SpecBlock_v4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(SpecBlock_v4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(SpecBlock_v4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(SpecBlock_v4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(SpecBlock_v4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(SpecBlock_v4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(SpecBlock_v4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(SpecBlock_v4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(SpecBlock_v4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(SpecBlock_v4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(SpecBlock_v4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(SpecBlock_v4__io_pre_spec_4_3_1),
    .io_q_j_2(SpecBlock_v4__i__io_q_j_2),
    .io_nxt_spec_0_0_0(SpecBlock_v4__i__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(SpecBlock_v4__i__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(SpecBlock_v4__i__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(SpecBlock_v4__i__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(SpecBlock_v4__i__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(SpecBlock_v4__i__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(SpecBlock_v4__i__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(SpecBlock_v4__i__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(SpecBlock_v4__i__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(SpecBlock_v4__i__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(SpecBlock_v4__i__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(SpecBlock_v4__i__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(SpecBlock_v4__i__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(SpecBlock_v4__i__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(SpecBlock_v4__i__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(SpecBlock_v4__i__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(SpecBlock_v4__i__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(SpecBlock_v4__i__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(SpecBlock_v4__i__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(SpecBlock_v4__i__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(SpecBlock_v4__i__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(SpecBlock_v4__i__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(SpecBlock_v4__i__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(SpecBlock_v4__i__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(SpecBlock_v4__i__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(SpecBlock_v4__i__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(SpecBlock_v4__i__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(SpecBlock_v4__i__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(SpecBlock_v4__i__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(SpecBlock_v4__i__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(SpecBlock_v4__i__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(SpecBlock_v4__i__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(SpecBlock_v4__i__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(SpecBlock_v4__i__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(SpecBlock_v4__i__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(SpecBlock_v4__i__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(SpecBlock_v4__i__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(SpecBlock_v4__i__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(SpecBlock_v4__i__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(SpecBlock_v4__i__io_nxt_spec_4_3_1)
  );
  task automatic drive_SpecBlock_v4(input int mode);
    SpecBlock_v4__io_q_j = pick_q(mode);
    SpecBlock_v4__io_cons_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_0_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_0_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_1_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_1_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_2_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_2_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_3_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_3_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_3_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_4_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_4_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_4_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_cons_4_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_d_trunc_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_d_trunc_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_d_trunc_2 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_d_trunc_3 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_q_j_1 = pick_q(mode);
    SpecBlock_v4__io_rem_3_5_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_rem_3_5_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_0_3_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_1_3_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_2_3_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_3_3_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_0_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_0_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_1_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_1_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_2_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_2_1 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_3_0 = 9'(rnd_bits(mode));
    SpecBlock_v4__io_pre_spec_4_3_1 = 9'(rnd_bits(mode));
  endtask
  task automatic check_SpecBlock_v4();
    checks++;
    if (SpecBlock_v4__g__io_q_j_2 !== SpecBlock_v4__i__io_q_j_2) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_q_j_2 g=%h i=%h", SpecBlock_v4__g__io_q_j_2, SpecBlock_v4__i__io_q_j_2); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_0_0 !== SpecBlock_v4__i__io_nxt_spec_0_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_0_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_0_0, SpecBlock_v4__i__io_nxt_spec_0_0_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_0_1 !== SpecBlock_v4__i__io_nxt_spec_0_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_0_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_0_1, SpecBlock_v4__i__io_nxt_spec_0_0_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_1_0 !== SpecBlock_v4__i__io_nxt_spec_0_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_1_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_1_0, SpecBlock_v4__i__io_nxt_spec_0_1_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_1_1 !== SpecBlock_v4__i__io_nxt_spec_0_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_1_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_1_1, SpecBlock_v4__i__io_nxt_spec_0_1_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_2_0 !== SpecBlock_v4__i__io_nxt_spec_0_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_2_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_2_0, SpecBlock_v4__i__io_nxt_spec_0_2_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_2_1 !== SpecBlock_v4__i__io_nxt_spec_0_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_2_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_2_1, SpecBlock_v4__i__io_nxt_spec_0_2_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_3_0 !== SpecBlock_v4__i__io_nxt_spec_0_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_3_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_3_0, SpecBlock_v4__i__io_nxt_spec_0_3_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_0_3_1 !== SpecBlock_v4__i__io_nxt_spec_0_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_0_3_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_0_3_1, SpecBlock_v4__i__io_nxt_spec_0_3_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_0_0 !== SpecBlock_v4__i__io_nxt_spec_1_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_0_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_0_0, SpecBlock_v4__i__io_nxt_spec_1_0_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_0_1 !== SpecBlock_v4__i__io_nxt_spec_1_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_0_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_0_1, SpecBlock_v4__i__io_nxt_spec_1_0_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_1_0 !== SpecBlock_v4__i__io_nxt_spec_1_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_1_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_1_0, SpecBlock_v4__i__io_nxt_spec_1_1_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_1_1 !== SpecBlock_v4__i__io_nxt_spec_1_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_1_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_1_1, SpecBlock_v4__i__io_nxt_spec_1_1_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_2_0 !== SpecBlock_v4__i__io_nxt_spec_1_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_2_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_2_0, SpecBlock_v4__i__io_nxt_spec_1_2_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_2_1 !== SpecBlock_v4__i__io_nxt_spec_1_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_2_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_2_1, SpecBlock_v4__i__io_nxt_spec_1_2_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_3_0 !== SpecBlock_v4__i__io_nxt_spec_1_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_3_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_3_0, SpecBlock_v4__i__io_nxt_spec_1_3_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_1_3_1 !== SpecBlock_v4__i__io_nxt_spec_1_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_1_3_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_1_3_1, SpecBlock_v4__i__io_nxt_spec_1_3_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_0_0 !== SpecBlock_v4__i__io_nxt_spec_2_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_0_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_0_0, SpecBlock_v4__i__io_nxt_spec_2_0_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_0_1 !== SpecBlock_v4__i__io_nxt_spec_2_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_0_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_0_1, SpecBlock_v4__i__io_nxt_spec_2_0_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_1_0 !== SpecBlock_v4__i__io_nxt_spec_2_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_1_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_1_0, SpecBlock_v4__i__io_nxt_spec_2_1_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_1_1 !== SpecBlock_v4__i__io_nxt_spec_2_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_1_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_1_1, SpecBlock_v4__i__io_nxt_spec_2_1_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_2_0 !== SpecBlock_v4__i__io_nxt_spec_2_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_2_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_2_0, SpecBlock_v4__i__io_nxt_spec_2_2_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_2_1 !== SpecBlock_v4__i__io_nxt_spec_2_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_2_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_2_1, SpecBlock_v4__i__io_nxt_spec_2_2_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_3_0 !== SpecBlock_v4__i__io_nxt_spec_2_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_3_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_3_0, SpecBlock_v4__i__io_nxt_spec_2_3_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_2_3_1 !== SpecBlock_v4__i__io_nxt_spec_2_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_2_3_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_2_3_1, SpecBlock_v4__i__io_nxt_spec_2_3_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_0_0 !== SpecBlock_v4__i__io_nxt_spec_3_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_0_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_0_0, SpecBlock_v4__i__io_nxt_spec_3_0_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_0_1 !== SpecBlock_v4__i__io_nxt_spec_3_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_0_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_0_1, SpecBlock_v4__i__io_nxt_spec_3_0_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_1_0 !== SpecBlock_v4__i__io_nxt_spec_3_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_1_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_1_0, SpecBlock_v4__i__io_nxt_spec_3_1_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_1_1 !== SpecBlock_v4__i__io_nxt_spec_3_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_1_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_1_1, SpecBlock_v4__i__io_nxt_spec_3_1_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_2_0 !== SpecBlock_v4__i__io_nxt_spec_3_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_2_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_2_0, SpecBlock_v4__i__io_nxt_spec_3_2_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_2_1 !== SpecBlock_v4__i__io_nxt_spec_3_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_2_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_2_1, SpecBlock_v4__i__io_nxt_spec_3_2_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_3_0 !== SpecBlock_v4__i__io_nxt_spec_3_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_3_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_3_0, SpecBlock_v4__i__io_nxt_spec_3_3_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_3_3_1 !== SpecBlock_v4__i__io_nxt_spec_3_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_3_3_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_3_3_1, SpecBlock_v4__i__io_nxt_spec_3_3_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_0_0 !== SpecBlock_v4__i__io_nxt_spec_4_0_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_0_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_0_0, SpecBlock_v4__i__io_nxt_spec_4_0_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_0_1 !== SpecBlock_v4__i__io_nxt_spec_4_0_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_0_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_0_1, SpecBlock_v4__i__io_nxt_spec_4_0_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_1_0 !== SpecBlock_v4__i__io_nxt_spec_4_1_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_1_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_1_0, SpecBlock_v4__i__io_nxt_spec_4_1_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_1_1 !== SpecBlock_v4__i__io_nxt_spec_4_1_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_1_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_1_1, SpecBlock_v4__i__io_nxt_spec_4_1_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_2_0 !== SpecBlock_v4__i__io_nxt_spec_4_2_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_2_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_2_0, SpecBlock_v4__i__io_nxt_spec_4_2_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_2_1 !== SpecBlock_v4__i__io_nxt_spec_4_2_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_2_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_2_1, SpecBlock_v4__i__io_nxt_spec_4_2_1); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_3_0 !== SpecBlock_v4__i__io_nxt_spec_4_3_0) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_3_0 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_3_0, SpecBlock_v4__i__io_nxt_spec_4_3_0); end
    checks++;
    if (SpecBlock_v4__g__io_nxt_spec_4_3_1 !== SpecBlock_v4__i__io_nxt_spec_4_3_1) begin errors++; if (errors <= 10) $display("MISMATCH SpecBlock_v4.io_nxt_spec_4_3_1 g=%h i=%h", SpecBlock_v4__g__io_nxt_spec_4_3_1, SpecBlock_v4__i__io_nxt_spec_4_3_1); end
    qhist_SpecBlock_v4[q_class(SpecBlock_v4__g__io_q_j_2)]++;
  endtask
  // ---------------- IterBlock_v4（104 入 / 52 出）----------------
  logic [7:0] IterBlock_v4__io_Sel_cons_0_0;
  logic [7:0] IterBlock_v4__io_Sel_cons_0_1;
  logic [7:0] IterBlock_v4__io_Sel_cons_0_2;
  logic [7:0] IterBlock_v4__io_Sel_cons_0_3;
  logic [7:0] IterBlock_v4__io_Sel_cons_1_0;
  logic [7:0] IterBlock_v4__io_Sel_cons_1_1;
  logic [7:0] IterBlock_v4__io_Sel_cons_1_2;
  logic [7:0] IterBlock_v4__io_Sel_cons_1_3;
  logic [7:0] IterBlock_v4__io_Sel_cons_2_0;
  logic [7:0] IterBlock_v4__io_Sel_cons_2_1;
  logic [7:0] IterBlock_v4__io_Sel_cons_2_2;
  logic [7:0] IterBlock_v4__io_Sel_cons_2_3;
  logic [7:0] IterBlock_v4__io_Sel_cons_3_0;
  logic [7:0] IterBlock_v4__io_Sel_cons_3_1;
  logic [7:0] IterBlock_v4__io_Sel_cons_3_2;
  logic [7:0] IterBlock_v4__io_Sel_cons_3_3;
  logic [7:0] IterBlock_v4__io_Sel_cons_4_0;
  logic [7:0] IterBlock_v4__io_Sel_cons_4_1;
  logic [7:0] IterBlock_v4__io_Sel_cons_4_2;
  logic [7:0] IterBlock_v4__io_Sel_cons_4_3;
  logic [8:0] IterBlock_v4__io_Spec_cons_0_0;
  logic [8:0] IterBlock_v4__io_Spec_cons_0_1;
  logic [8:0] IterBlock_v4__io_Spec_cons_0_2;
  logic [8:0] IterBlock_v4__io_Spec_cons_0_3;
  logic [8:0] IterBlock_v4__io_Spec_cons_1_0;
  logic [8:0] IterBlock_v4__io_Spec_cons_1_1;
  logic [8:0] IterBlock_v4__io_Spec_cons_1_2;
  logic [8:0] IterBlock_v4__io_Spec_cons_1_3;
  logic [8:0] IterBlock_v4__io_Spec_cons_2_0;
  logic [8:0] IterBlock_v4__io_Spec_cons_2_1;
  logic [8:0] IterBlock_v4__io_Spec_cons_2_2;
  logic [8:0] IterBlock_v4__io_Spec_cons_2_3;
  logic [8:0] IterBlock_v4__io_Spec_cons_3_0;
  logic [8:0] IterBlock_v4__io_Spec_cons_3_1;
  logic [8:0] IterBlock_v4__io_Spec_cons_3_2;
  logic [8:0] IterBlock_v4__io_Spec_cons_3_3;
  logic [8:0] IterBlock_v4__io_Spec_cons_4_0;
  logic [8:0] IterBlock_v4__io_Spec_cons_4_1;
  logic [8:0] IterBlock_v4__io_Spec_cons_4_2;
  logic [8:0] IterBlock_v4__io_Spec_cons_4_3;
  logic [21:0] IterBlock_v4__io_iter_cons_0;
  logic [21:0] IterBlock_v4__io_iter_cons_1;
  logic [21:0] IterBlock_v4__io_iter_cons_3;
  logic [21:0] IterBlock_v4__io_iter_cons_4;
  logic [8:0] IterBlock_v4__io_d_trunc_0;
  logic [8:0] IterBlock_v4__io_d_trunc_1;
  logic [8:0] IterBlock_v4__io_d_trunc_2;
  logic [8:0] IterBlock_v4__io_d_trunc_3;
  logic [10:0] IterBlock_v4__io_spec_r2ud_0;
  logic [10:0] IterBlock_v4__io_spec_r2ud_1;
  logic [10:0] IterBlock_v4__io_spec_r2ud_3;
  logic [10:0] IterBlock_v4__io_spec_r2ud_4;
  logic [15:0] IterBlock_v4__io_pre_q_A;
  logic [15:0] IterBlock_v4__io_pre_q_B;
  logic [7:0] IterBlock_v4__io_pre_sel_0_0;
  logic [7:0] IterBlock_v4__io_pre_sel_0_1;
  logic [7:0] IterBlock_v4__io_pre_sel_1_0;
  logic [7:0] IterBlock_v4__io_pre_sel_1_1;
  logic [7:0] IterBlock_v4__io_pre_sel_2_0;
  logic [7:0] IterBlock_v4__io_pre_sel_2_1;
  logic [7:0] IterBlock_v4__io_pre_sel_3_0;
  logic [7:0] IterBlock_v4__io_pre_sel_3_1;
  logic [8:0] IterBlock_v4__io_pre_spec_0_0_0;
  logic [8:0] IterBlock_v4__io_pre_spec_0_0_1;
  logic [8:0] IterBlock_v4__io_pre_spec_0_1_0;
  logic [8:0] IterBlock_v4__io_pre_spec_0_1_1;
  logic [8:0] IterBlock_v4__io_pre_spec_0_2_0;
  logic [8:0] IterBlock_v4__io_pre_spec_0_2_1;
  logic [8:0] IterBlock_v4__io_pre_spec_0_3_0;
  logic [8:0] IterBlock_v4__io_pre_spec_0_3_1;
  logic [8:0] IterBlock_v4__io_pre_spec_1_0_0;
  logic [8:0] IterBlock_v4__io_pre_spec_1_0_1;
  logic [8:0] IterBlock_v4__io_pre_spec_1_1_0;
  logic [8:0] IterBlock_v4__io_pre_spec_1_1_1;
  logic [8:0] IterBlock_v4__io_pre_spec_1_2_0;
  logic [8:0] IterBlock_v4__io_pre_spec_1_2_1;
  logic [8:0] IterBlock_v4__io_pre_spec_1_3_0;
  logic [8:0] IterBlock_v4__io_pre_spec_1_3_1;
  logic [8:0] IterBlock_v4__io_pre_spec_2_0_0;
  logic [8:0] IterBlock_v4__io_pre_spec_2_0_1;
  logic [8:0] IterBlock_v4__io_pre_spec_2_1_0;
  logic [8:0] IterBlock_v4__io_pre_spec_2_1_1;
  logic [8:0] IterBlock_v4__io_pre_spec_2_2_0;
  logic [8:0] IterBlock_v4__io_pre_spec_2_2_1;
  logic [8:0] IterBlock_v4__io_pre_spec_2_3_0;
  logic [8:0] IterBlock_v4__io_pre_spec_2_3_1;
  logic [8:0] IterBlock_v4__io_pre_spec_3_0_0;
  logic [8:0] IterBlock_v4__io_pre_spec_3_0_1;
  logic [8:0] IterBlock_v4__io_pre_spec_3_1_0;
  logic [8:0] IterBlock_v4__io_pre_spec_3_1_1;
  logic [8:0] IterBlock_v4__io_pre_spec_3_2_0;
  logic [8:0] IterBlock_v4__io_pre_spec_3_2_1;
  logic [8:0] IterBlock_v4__io_pre_spec_3_3_0;
  logic [8:0] IterBlock_v4__io_pre_spec_3_3_1;
  logic [8:0] IterBlock_v4__io_pre_spec_4_0_0;
  logic [8:0] IterBlock_v4__io_pre_spec_4_0_1;
  logic [8:0] IterBlock_v4__io_pre_spec_4_1_0;
  logic [8:0] IterBlock_v4__io_pre_spec_4_1_1;
  logic [8:0] IterBlock_v4__io_pre_spec_4_2_0;
  logic [8:0] IterBlock_v4__io_pre_spec_4_2_1;
  logic [8:0] IterBlock_v4__io_pre_spec_4_3_0;
  logic [8:0] IterBlock_v4__io_pre_spec_4_3_1;
  logic [21:0] IterBlock_v4__io_pre_iterB_0;
  logic [21:0] IterBlock_v4__io_pre_iterB_1;
  wire  [15:0] IterBlock_v4__g__io_nxt_q_A, IterBlock_v4__i__io_nxt_q_A;
  wire  [15:0] IterBlock_v4__g__io_nxt_q_B, IterBlock_v4__i__io_nxt_q_B;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_0_0, IterBlock_v4__i__io_nxt_sel_0_0;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_0_1, IterBlock_v4__i__io_nxt_sel_0_1;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_1_0, IterBlock_v4__i__io_nxt_sel_1_0;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_1_1, IterBlock_v4__i__io_nxt_sel_1_1;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_2_0, IterBlock_v4__i__io_nxt_sel_2_0;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_2_1, IterBlock_v4__i__io_nxt_sel_2_1;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_3_0, IterBlock_v4__i__io_nxt_sel_3_0;
  wire  [7:0] IterBlock_v4__g__io_nxt_sel_3_1, IterBlock_v4__i__io_nxt_sel_3_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_0_0, IterBlock_v4__i__io_nxt_spec_0_0_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_0_1, IterBlock_v4__i__io_nxt_spec_0_0_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_1_0, IterBlock_v4__i__io_nxt_spec_0_1_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_1_1, IterBlock_v4__i__io_nxt_spec_0_1_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_2_0, IterBlock_v4__i__io_nxt_spec_0_2_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_2_1, IterBlock_v4__i__io_nxt_spec_0_2_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_3_0, IterBlock_v4__i__io_nxt_spec_0_3_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_0_3_1, IterBlock_v4__i__io_nxt_spec_0_3_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_0_0, IterBlock_v4__i__io_nxt_spec_1_0_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_0_1, IterBlock_v4__i__io_nxt_spec_1_0_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_1_0, IterBlock_v4__i__io_nxt_spec_1_1_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_1_1, IterBlock_v4__i__io_nxt_spec_1_1_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_2_0, IterBlock_v4__i__io_nxt_spec_1_2_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_2_1, IterBlock_v4__i__io_nxt_spec_1_2_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_3_0, IterBlock_v4__i__io_nxt_spec_1_3_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_1_3_1, IterBlock_v4__i__io_nxt_spec_1_3_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_0_0, IterBlock_v4__i__io_nxt_spec_2_0_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_0_1, IterBlock_v4__i__io_nxt_spec_2_0_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_1_0, IterBlock_v4__i__io_nxt_spec_2_1_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_1_1, IterBlock_v4__i__io_nxt_spec_2_1_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_2_0, IterBlock_v4__i__io_nxt_spec_2_2_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_2_1, IterBlock_v4__i__io_nxt_spec_2_2_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_3_0, IterBlock_v4__i__io_nxt_spec_2_3_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_2_3_1, IterBlock_v4__i__io_nxt_spec_2_3_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_0_0, IterBlock_v4__i__io_nxt_spec_3_0_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_0_1, IterBlock_v4__i__io_nxt_spec_3_0_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_1_0, IterBlock_v4__i__io_nxt_spec_3_1_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_1_1, IterBlock_v4__i__io_nxt_spec_3_1_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_2_0, IterBlock_v4__i__io_nxt_spec_3_2_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_2_1, IterBlock_v4__i__io_nxt_spec_3_2_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_3_0, IterBlock_v4__i__io_nxt_spec_3_3_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_3_3_1, IterBlock_v4__i__io_nxt_spec_3_3_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_0_0, IterBlock_v4__i__io_nxt_spec_4_0_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_0_1, IterBlock_v4__i__io_nxt_spec_4_0_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_1_0, IterBlock_v4__i__io_nxt_spec_4_1_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_1_1, IterBlock_v4__i__io_nxt_spec_4_1_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_2_0, IterBlock_v4__i__io_nxt_spec_4_2_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_2_1, IterBlock_v4__i__io_nxt_spec_4_2_1;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_3_0, IterBlock_v4__i__io_nxt_spec_4_3_0;
  wire  [8:0] IterBlock_v4__g__io_nxt_spec_4_3_1, IterBlock_v4__i__io_nxt_spec_4_3_1;
  wire  [21:0] IterBlock_v4__g__io_nxt_iterB_0, IterBlock_v4__i__io_nxt_iterB_0;
  wire  [21:0] IterBlock_v4__g__io_nxt_iterB_1, IterBlock_v4__i__io_nxt_iterB_1;
  IterBlock_v4 u_g_IterBlock_v4 (
    .io_Sel_cons_0_0(IterBlock_v4__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4__g__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4__g__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4__g__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4__g__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4__g__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4__g__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4__g__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4__g__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4__g__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4__g__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4__g__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4__g__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4__g__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4__g__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4__g__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4__g__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4__g__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4__g__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4__g__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4__g__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4__g__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4__g__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4__g__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4__g__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4__g__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4__g__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4__g__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4__g__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4__g__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4__g__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4__g__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4__g__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4__g__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4__g__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4__g__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4__g__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4__g__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4__g__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4__g__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4__g__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4__g__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4__g__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4__g__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4__g__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4__g__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4__g__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4__g__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4__g__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4__g__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4__g__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4__g__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4__g__io_nxt_iterB_1)
  );
  IterBlock_v4_xs u_i_IterBlock_v4 (
    .io_Sel_cons_0_0(IterBlock_v4__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4__i__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4__i__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4__i__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4__i__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4__i__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4__i__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4__i__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4__i__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4__i__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4__i__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4__i__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4__i__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4__i__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4__i__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4__i__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4__i__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4__i__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4__i__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4__i__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4__i__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4__i__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4__i__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4__i__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4__i__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4__i__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4__i__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4__i__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4__i__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4__i__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4__i__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4__i__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4__i__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4__i__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4__i__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4__i__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4__i__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4__i__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4__i__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4__i__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4__i__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4__i__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4__i__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4__i__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4__i__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4__i__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4__i__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4__i__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4__i__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4__i__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4__i__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4__i__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4__i__io_nxt_iterB_1)
  );
  task automatic drive_IterBlock_v4(input int mode);
    IterBlock_v4__io_Sel_cons_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_0_2 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_0_3 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_1_2 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_1_3 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_2_2 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_2_3 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_3_2 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_3_3 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_4_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_4_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_4_2 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Sel_cons_4_3 = 8'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_0_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_0_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_1_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_1_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_2_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_2_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_3_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_3_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_4_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_4_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_4_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_Spec_cons_4_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_iter_cons_0 = 22'(rnd_bits(mode));
    IterBlock_v4__io_iter_cons_1 = 22'(rnd_bits(mode));
    IterBlock_v4__io_iter_cons_3 = 22'(rnd_bits(mode));
    IterBlock_v4__io_iter_cons_4 = 22'(rnd_bits(mode));
    IterBlock_v4__io_d_trunc_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_d_trunc_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_d_trunc_2 = 9'(rnd_bits(mode));
    IterBlock_v4__io_d_trunc_3 = 9'(rnd_bits(mode));
    IterBlock_v4__io_spec_r2ud_0 = 11'(rnd_bits(mode));
    IterBlock_v4__io_spec_r2ud_1 = 11'(rnd_bits(mode));
    IterBlock_v4__io_spec_r2ud_3 = 11'(rnd_bits(mode));
    IterBlock_v4__io_spec_r2ud_4 = 11'(rnd_bits(mode));
    IterBlock_v4__io_pre_q_A = 16'(rnd_bits(mode));
    IterBlock_v4__io_pre_q_B = 16'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_sel_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_0_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_1_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_2_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_3_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_spec_4_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4__io_pre_iterB_0 = 22'(rnd_bits(mode));
    IterBlock_v4__io_pre_iterB_1 = 22'(rnd_bits(mode));
  endtask
  task automatic check_IterBlock_v4();
    checks++;
    if (IterBlock_v4__g__io_nxt_q_A !== IterBlock_v4__i__io_nxt_q_A) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_q_A g=%h i=%h", IterBlock_v4__g__io_nxt_q_A, IterBlock_v4__i__io_nxt_q_A); end
    checks++;
    if (IterBlock_v4__g__io_nxt_q_B !== IterBlock_v4__i__io_nxt_q_B) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_q_B g=%h i=%h", IterBlock_v4__g__io_nxt_q_B, IterBlock_v4__i__io_nxt_q_B); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_0_0 !== IterBlock_v4__i__io_nxt_sel_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_0_0, IterBlock_v4__i__io_nxt_sel_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_0_1 !== IterBlock_v4__i__io_nxt_sel_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_0_1, IterBlock_v4__i__io_nxt_sel_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_1_0 !== IterBlock_v4__i__io_nxt_sel_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_1_0, IterBlock_v4__i__io_nxt_sel_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_1_1 !== IterBlock_v4__i__io_nxt_sel_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_1_1, IterBlock_v4__i__io_nxt_sel_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_2_0 !== IterBlock_v4__i__io_nxt_sel_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_2_0, IterBlock_v4__i__io_nxt_sel_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_2_1 !== IterBlock_v4__i__io_nxt_sel_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_2_1, IterBlock_v4__i__io_nxt_sel_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_3_0 !== IterBlock_v4__i__io_nxt_sel_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_3_0, IterBlock_v4__i__io_nxt_sel_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_sel_3_1 !== IterBlock_v4__i__io_nxt_sel_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_sel_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_sel_3_1, IterBlock_v4__i__io_nxt_sel_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_0_0 !== IterBlock_v4__i__io_nxt_spec_0_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_0_0, IterBlock_v4__i__io_nxt_spec_0_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_0_1 !== IterBlock_v4__i__io_nxt_spec_0_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_0_1, IterBlock_v4__i__io_nxt_spec_0_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_1_0 !== IterBlock_v4__i__io_nxt_spec_0_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_1_0, IterBlock_v4__i__io_nxt_spec_0_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_1_1 !== IterBlock_v4__i__io_nxt_spec_0_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_1_1, IterBlock_v4__i__io_nxt_spec_0_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_2_0 !== IterBlock_v4__i__io_nxt_spec_0_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_2_0, IterBlock_v4__i__io_nxt_spec_0_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_2_1 !== IterBlock_v4__i__io_nxt_spec_0_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_2_1, IterBlock_v4__i__io_nxt_spec_0_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_3_0 !== IterBlock_v4__i__io_nxt_spec_0_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_3_0, IterBlock_v4__i__io_nxt_spec_0_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_0_3_1 !== IterBlock_v4__i__io_nxt_spec_0_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_0_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_0_3_1, IterBlock_v4__i__io_nxt_spec_0_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_0_0 !== IterBlock_v4__i__io_nxt_spec_1_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_0_0, IterBlock_v4__i__io_nxt_spec_1_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_0_1 !== IterBlock_v4__i__io_nxt_spec_1_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_0_1, IterBlock_v4__i__io_nxt_spec_1_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_1_0 !== IterBlock_v4__i__io_nxt_spec_1_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_1_0, IterBlock_v4__i__io_nxt_spec_1_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_1_1 !== IterBlock_v4__i__io_nxt_spec_1_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_1_1, IterBlock_v4__i__io_nxt_spec_1_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_2_0 !== IterBlock_v4__i__io_nxt_spec_1_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_2_0, IterBlock_v4__i__io_nxt_spec_1_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_2_1 !== IterBlock_v4__i__io_nxt_spec_1_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_2_1, IterBlock_v4__i__io_nxt_spec_1_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_3_0 !== IterBlock_v4__i__io_nxt_spec_1_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_3_0, IterBlock_v4__i__io_nxt_spec_1_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_1_3_1 !== IterBlock_v4__i__io_nxt_spec_1_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_1_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_1_3_1, IterBlock_v4__i__io_nxt_spec_1_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_0_0 !== IterBlock_v4__i__io_nxt_spec_2_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_0_0, IterBlock_v4__i__io_nxt_spec_2_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_0_1 !== IterBlock_v4__i__io_nxt_spec_2_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_0_1, IterBlock_v4__i__io_nxt_spec_2_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_1_0 !== IterBlock_v4__i__io_nxt_spec_2_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_1_0, IterBlock_v4__i__io_nxt_spec_2_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_1_1 !== IterBlock_v4__i__io_nxt_spec_2_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_1_1, IterBlock_v4__i__io_nxt_spec_2_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_2_0 !== IterBlock_v4__i__io_nxt_spec_2_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_2_0, IterBlock_v4__i__io_nxt_spec_2_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_2_1 !== IterBlock_v4__i__io_nxt_spec_2_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_2_1, IterBlock_v4__i__io_nxt_spec_2_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_3_0 !== IterBlock_v4__i__io_nxt_spec_2_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_3_0, IterBlock_v4__i__io_nxt_spec_2_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_2_3_1 !== IterBlock_v4__i__io_nxt_spec_2_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_2_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_2_3_1, IterBlock_v4__i__io_nxt_spec_2_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_0_0 !== IterBlock_v4__i__io_nxt_spec_3_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_0_0, IterBlock_v4__i__io_nxt_spec_3_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_0_1 !== IterBlock_v4__i__io_nxt_spec_3_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_0_1, IterBlock_v4__i__io_nxt_spec_3_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_1_0 !== IterBlock_v4__i__io_nxt_spec_3_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_1_0, IterBlock_v4__i__io_nxt_spec_3_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_1_1 !== IterBlock_v4__i__io_nxt_spec_3_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_1_1, IterBlock_v4__i__io_nxt_spec_3_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_2_0 !== IterBlock_v4__i__io_nxt_spec_3_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_2_0, IterBlock_v4__i__io_nxt_spec_3_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_2_1 !== IterBlock_v4__i__io_nxt_spec_3_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_2_1, IterBlock_v4__i__io_nxt_spec_3_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_3_0 !== IterBlock_v4__i__io_nxt_spec_3_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_3_0, IterBlock_v4__i__io_nxt_spec_3_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_3_3_1 !== IterBlock_v4__i__io_nxt_spec_3_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_3_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_3_3_1, IterBlock_v4__i__io_nxt_spec_3_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_0_0 !== IterBlock_v4__i__io_nxt_spec_4_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_0_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_0_0, IterBlock_v4__i__io_nxt_spec_4_0_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_0_1 !== IterBlock_v4__i__io_nxt_spec_4_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_0_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_0_1, IterBlock_v4__i__io_nxt_spec_4_0_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_1_0 !== IterBlock_v4__i__io_nxt_spec_4_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_1_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_1_0, IterBlock_v4__i__io_nxt_spec_4_1_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_1_1 !== IterBlock_v4__i__io_nxt_spec_4_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_1_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_1_1, IterBlock_v4__i__io_nxt_spec_4_1_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_2_0 !== IterBlock_v4__i__io_nxt_spec_4_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_2_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_2_0, IterBlock_v4__i__io_nxt_spec_4_2_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_2_1 !== IterBlock_v4__i__io_nxt_spec_4_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_2_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_2_1, IterBlock_v4__i__io_nxt_spec_4_2_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_3_0 !== IterBlock_v4__i__io_nxt_spec_4_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_3_0 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_3_0, IterBlock_v4__i__io_nxt_spec_4_3_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_spec_4_3_1 !== IterBlock_v4__i__io_nxt_spec_4_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_spec_4_3_1 g=%h i=%h", IterBlock_v4__g__io_nxt_spec_4_3_1, IterBlock_v4__i__io_nxt_spec_4_3_1); end
    checks++;
    if (IterBlock_v4__g__io_nxt_iterB_0 !== IterBlock_v4__i__io_nxt_iterB_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_iterB_0 g=%h i=%h", IterBlock_v4__g__io_nxt_iterB_0, IterBlock_v4__i__io_nxt_iterB_0); end
    checks++;
    if (IterBlock_v4__g__io_nxt_iterB_1 !== IterBlock_v4__i__io_nxt_iterB_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4.io_nxt_iterB_1 g=%h i=%h", IterBlock_v4__g__io_nxt_iterB_1, IterBlock_v4__i__io_nxt_iterB_1); end
  endtask
  // ---------------- IterBlock_v4_4（104 入 / 52 出）----------------
  logic [7:0] IterBlock_v4_4__io_Sel_cons_0_0;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_0_1;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_0_2;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_0_3;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_1_0;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_1_1;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_1_2;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_1_3;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_2_0;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_2_1;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_2_2;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_2_3;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_3_0;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_3_1;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_3_2;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_3_3;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_4_0;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_4_1;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_4_2;
  logic [7:0] IterBlock_v4_4__io_Sel_cons_4_3;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_0_0;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_0_1;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_0_2;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_0_3;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_1_0;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_1_1;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_1_2;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_1_3;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_2_0;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_2_1;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_2_2;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_2_3;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_3_0;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_3_1;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_3_2;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_3_3;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_4_0;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_4_1;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_4_2;
  logic [8:0] IterBlock_v4_4__io_Spec_cons_4_3;
  logic [37:0] IterBlock_v4_4__io_iter_cons_0;
  logic [37:0] IterBlock_v4_4__io_iter_cons_1;
  logic [37:0] IterBlock_v4_4__io_iter_cons_3;
  logic [37:0] IterBlock_v4_4__io_iter_cons_4;
  logic [8:0] IterBlock_v4_4__io_d_trunc_0;
  logic [8:0] IterBlock_v4_4__io_d_trunc_1;
  logic [8:0] IterBlock_v4_4__io_d_trunc_2;
  logic [8:0] IterBlock_v4_4__io_d_trunc_3;
  logic [10:0] IterBlock_v4_4__io_spec_r2ud_0;
  logic [10:0] IterBlock_v4_4__io_spec_r2ud_1;
  logic [10:0] IterBlock_v4_4__io_spec_r2ud_3;
  logic [10:0] IterBlock_v4_4__io_spec_r2ud_4;
  logic [31:0] IterBlock_v4_4__io_pre_q_A;
  logic [31:0] IterBlock_v4_4__io_pre_q_B;
  logic [7:0] IterBlock_v4_4__io_pre_sel_0_0;
  logic [7:0] IterBlock_v4_4__io_pre_sel_0_1;
  logic [7:0] IterBlock_v4_4__io_pre_sel_1_0;
  logic [7:0] IterBlock_v4_4__io_pre_sel_1_1;
  logic [7:0] IterBlock_v4_4__io_pre_sel_2_0;
  logic [7:0] IterBlock_v4_4__io_pre_sel_2_1;
  logic [7:0] IterBlock_v4_4__io_pre_sel_3_0;
  logic [7:0] IterBlock_v4_4__io_pre_sel_3_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_0_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_0_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_1_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_1_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_2_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_2_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_3_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_0_3_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_0_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_0_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_1_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_1_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_2_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_2_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_3_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_1_3_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_0_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_0_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_1_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_1_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_2_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_2_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_3_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_2_3_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_0_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_0_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_1_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_1_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_2_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_2_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_3_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_3_3_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_0_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_0_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_1_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_1_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_2_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_2_1;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_3_0;
  logic [8:0] IterBlock_v4_4__io_pre_spec_4_3_1;
  logic [37:0] IterBlock_v4_4__io_pre_iterB_0;
  logic [37:0] IterBlock_v4_4__io_pre_iterB_1;
  wire  [31:0] IterBlock_v4_4__g__io_nxt_q_A, IterBlock_v4_4__i__io_nxt_q_A;
  wire  [31:0] IterBlock_v4_4__g__io_nxt_q_B, IterBlock_v4_4__i__io_nxt_q_B;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_0_0, IterBlock_v4_4__i__io_nxt_sel_0_0;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_0_1, IterBlock_v4_4__i__io_nxt_sel_0_1;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_1_0, IterBlock_v4_4__i__io_nxt_sel_1_0;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_1_1, IterBlock_v4_4__i__io_nxt_sel_1_1;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_2_0, IterBlock_v4_4__i__io_nxt_sel_2_0;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_2_1, IterBlock_v4_4__i__io_nxt_sel_2_1;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_3_0, IterBlock_v4_4__i__io_nxt_sel_3_0;
  wire  [7:0] IterBlock_v4_4__g__io_nxt_sel_3_1, IterBlock_v4_4__i__io_nxt_sel_3_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_0_0, IterBlock_v4_4__i__io_nxt_spec_0_0_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_0_1, IterBlock_v4_4__i__io_nxt_spec_0_0_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_1_0, IterBlock_v4_4__i__io_nxt_spec_0_1_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_1_1, IterBlock_v4_4__i__io_nxt_spec_0_1_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_2_0, IterBlock_v4_4__i__io_nxt_spec_0_2_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_2_1, IterBlock_v4_4__i__io_nxt_spec_0_2_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_3_0, IterBlock_v4_4__i__io_nxt_spec_0_3_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_0_3_1, IterBlock_v4_4__i__io_nxt_spec_0_3_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_0_0, IterBlock_v4_4__i__io_nxt_spec_1_0_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_0_1, IterBlock_v4_4__i__io_nxt_spec_1_0_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_1_0, IterBlock_v4_4__i__io_nxt_spec_1_1_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_1_1, IterBlock_v4_4__i__io_nxt_spec_1_1_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_2_0, IterBlock_v4_4__i__io_nxt_spec_1_2_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_2_1, IterBlock_v4_4__i__io_nxt_spec_1_2_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_3_0, IterBlock_v4_4__i__io_nxt_spec_1_3_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_1_3_1, IterBlock_v4_4__i__io_nxt_spec_1_3_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_0_0, IterBlock_v4_4__i__io_nxt_spec_2_0_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_0_1, IterBlock_v4_4__i__io_nxt_spec_2_0_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_1_0, IterBlock_v4_4__i__io_nxt_spec_2_1_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_1_1, IterBlock_v4_4__i__io_nxt_spec_2_1_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_2_0, IterBlock_v4_4__i__io_nxt_spec_2_2_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_2_1, IterBlock_v4_4__i__io_nxt_spec_2_2_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_3_0, IterBlock_v4_4__i__io_nxt_spec_2_3_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_2_3_1, IterBlock_v4_4__i__io_nxt_spec_2_3_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_0_0, IterBlock_v4_4__i__io_nxt_spec_3_0_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_0_1, IterBlock_v4_4__i__io_nxt_spec_3_0_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_1_0, IterBlock_v4_4__i__io_nxt_spec_3_1_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_1_1, IterBlock_v4_4__i__io_nxt_spec_3_1_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_2_0, IterBlock_v4_4__i__io_nxt_spec_3_2_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_2_1, IterBlock_v4_4__i__io_nxt_spec_3_2_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_3_0, IterBlock_v4_4__i__io_nxt_spec_3_3_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_3_3_1, IterBlock_v4_4__i__io_nxt_spec_3_3_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_0_0, IterBlock_v4_4__i__io_nxt_spec_4_0_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_0_1, IterBlock_v4_4__i__io_nxt_spec_4_0_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_1_0, IterBlock_v4_4__i__io_nxt_spec_4_1_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_1_1, IterBlock_v4_4__i__io_nxt_spec_4_1_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_2_0, IterBlock_v4_4__i__io_nxt_spec_4_2_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_2_1, IterBlock_v4_4__i__io_nxt_spec_4_2_1;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_3_0, IterBlock_v4_4__i__io_nxt_spec_4_3_0;
  wire  [8:0] IterBlock_v4_4__g__io_nxt_spec_4_3_1, IterBlock_v4_4__i__io_nxt_spec_4_3_1;
  wire  [37:0] IterBlock_v4_4__g__io_nxt_iterB_0, IterBlock_v4_4__i__io_nxt_iterB_0;
  wire  [37:0] IterBlock_v4_4__g__io_nxt_iterB_1, IterBlock_v4_4__i__io_nxt_iterB_1;
  IterBlock_v4_4 u_g_IterBlock_v4_4 (
    .io_Sel_cons_0_0(IterBlock_v4_4__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4_4__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4_4__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4_4__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4_4__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4_4__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4_4__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4_4__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4_4__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4_4__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4_4__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4_4__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4_4__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4_4__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4_4__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4_4__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4_4__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4_4__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4_4__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4_4__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4_4__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4_4__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4_4__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4_4__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4_4__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4_4__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4_4__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4_4__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4_4__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4_4__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4_4__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4_4__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4_4__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4_4__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4_4__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4_4__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4_4__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4_4__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4_4__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4_4__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4_4__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4_4__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4_4__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4_4__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4_4__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4_4__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4_4__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4_4__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4_4__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4_4__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4_4__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4_4__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4_4__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4_4__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4_4__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4_4__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4_4__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4_4__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4_4__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4_4__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4_4__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4_4__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4_4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4_4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4_4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4_4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4_4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4_4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4_4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4_4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4_4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4_4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4_4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4_4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4_4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4_4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4_4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4_4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4_4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4_4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4_4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4_4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4_4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4_4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4_4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4_4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4_4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4_4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4_4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4_4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4_4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4_4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4_4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4_4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4_4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4_4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4_4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4_4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4_4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4_4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4_4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4_4__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4_4__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4_4__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4_4__g__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4_4__g__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4_4__g__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4_4__g__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4_4__g__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4_4__g__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4_4__g__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4_4__g__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4_4__g__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4_4__g__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4_4__g__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4_4__g__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4_4__g__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4_4__g__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4_4__g__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4_4__g__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4_4__g__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4_4__g__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4_4__g__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4_4__g__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4_4__g__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4_4__g__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4_4__g__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4_4__g__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4_4__g__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4_4__g__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4_4__g__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4_4__g__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4_4__g__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4_4__g__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4_4__g__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4_4__g__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4_4__g__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4_4__g__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4_4__g__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4_4__g__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4_4__g__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4_4__g__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4_4__g__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4_4__g__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4_4__g__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4_4__g__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4_4__g__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4_4__g__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4_4__g__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4_4__g__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4_4__g__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4_4__g__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4_4__g__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4_4__g__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4_4__g__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4_4__g__io_nxt_iterB_1)
  );
  IterBlock_v4_4_xs u_i_IterBlock_v4_4 (
    .io_Sel_cons_0_0(IterBlock_v4_4__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4_4__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4_4__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4_4__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4_4__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4_4__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4_4__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4_4__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4_4__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4_4__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4_4__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4_4__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4_4__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4_4__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4_4__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4_4__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4_4__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4_4__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4_4__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4_4__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4_4__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4_4__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4_4__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4_4__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4_4__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4_4__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4_4__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4_4__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4_4__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4_4__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4_4__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4_4__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4_4__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4_4__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4_4__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4_4__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4_4__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4_4__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4_4__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4_4__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4_4__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4_4__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4_4__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4_4__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4_4__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4_4__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4_4__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4_4__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4_4__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4_4__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4_4__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4_4__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4_4__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4_4__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4_4__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4_4__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4_4__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4_4__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4_4__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4_4__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4_4__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4_4__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4_4__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4_4__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4_4__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4_4__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4_4__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4_4__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4_4__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4_4__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4_4__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4_4__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4_4__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4_4__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4_4__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4_4__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4_4__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4_4__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4_4__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4_4__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4_4__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4_4__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4_4__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4_4__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4_4__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4_4__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4_4__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4_4__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4_4__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4_4__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4_4__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4_4__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4_4__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4_4__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4_4__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4_4__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4_4__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4_4__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4_4__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4_4__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4_4__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4_4__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4_4__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4_4__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4_4__i__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4_4__i__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4_4__i__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4_4__i__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4_4__i__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4_4__i__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4_4__i__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4_4__i__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4_4__i__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4_4__i__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4_4__i__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4_4__i__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4_4__i__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4_4__i__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4_4__i__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4_4__i__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4_4__i__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4_4__i__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4_4__i__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4_4__i__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4_4__i__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4_4__i__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4_4__i__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4_4__i__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4_4__i__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4_4__i__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4_4__i__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4_4__i__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4_4__i__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4_4__i__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4_4__i__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4_4__i__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4_4__i__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4_4__i__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4_4__i__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4_4__i__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4_4__i__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4_4__i__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4_4__i__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4_4__i__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4_4__i__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4_4__i__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4_4__i__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4_4__i__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4_4__i__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4_4__i__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4_4__i__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4_4__i__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4_4__i__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4_4__i__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4_4__i__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4_4__i__io_nxt_iterB_1)
  );
  task automatic drive_IterBlock_v4_4(input int mode);
    IterBlock_v4_4__io_Sel_cons_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_0_2 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_0_3 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_1_2 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_1_3 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_2_2 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_2_3 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_3_2 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_3_3 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_4_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_4_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_4_2 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Sel_cons_4_3 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_0_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_0_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_1_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_1_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_2_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_2_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_3_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_3_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_4_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_4_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_4_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_Spec_cons_4_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_iter_cons_0 = 38'(rnd_bits(mode));
    IterBlock_v4_4__io_iter_cons_1 = 38'(rnd_bits(mode));
    IterBlock_v4_4__io_iter_cons_3 = 38'(rnd_bits(mode));
    IterBlock_v4_4__io_iter_cons_4 = 38'(rnd_bits(mode));
    IterBlock_v4_4__io_d_trunc_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_d_trunc_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_d_trunc_2 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_d_trunc_3 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_spec_r2ud_0 = 11'(rnd_bits(mode));
    IterBlock_v4_4__io_spec_r2ud_1 = 11'(rnd_bits(mode));
    IterBlock_v4_4__io_spec_r2ud_3 = 11'(rnd_bits(mode));
    IterBlock_v4_4__io_spec_r2ud_4 = 11'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_q_A = 32'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_q_B = 32'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_sel_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_0_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_1_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_2_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_3_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_spec_4_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_iterB_0 = 38'(rnd_bits(mode));
    IterBlock_v4_4__io_pre_iterB_1 = 38'(rnd_bits(mode));
  endtask
  task automatic check_IterBlock_v4_4();
    checks++;
    if (IterBlock_v4_4__g__io_nxt_q_A !== IterBlock_v4_4__i__io_nxt_q_A) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_q_A g=%h i=%h", IterBlock_v4_4__g__io_nxt_q_A, IterBlock_v4_4__i__io_nxt_q_A); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_q_B !== IterBlock_v4_4__i__io_nxt_q_B) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_q_B g=%h i=%h", IterBlock_v4_4__g__io_nxt_q_B, IterBlock_v4_4__i__io_nxt_q_B); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_0_0 !== IterBlock_v4_4__i__io_nxt_sel_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_0_0, IterBlock_v4_4__i__io_nxt_sel_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_0_1 !== IterBlock_v4_4__i__io_nxt_sel_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_0_1, IterBlock_v4_4__i__io_nxt_sel_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_1_0 !== IterBlock_v4_4__i__io_nxt_sel_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_1_0, IterBlock_v4_4__i__io_nxt_sel_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_1_1 !== IterBlock_v4_4__i__io_nxt_sel_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_1_1, IterBlock_v4_4__i__io_nxt_sel_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_2_0 !== IterBlock_v4_4__i__io_nxt_sel_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_2_0, IterBlock_v4_4__i__io_nxt_sel_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_2_1 !== IterBlock_v4_4__i__io_nxt_sel_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_2_1, IterBlock_v4_4__i__io_nxt_sel_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_3_0 !== IterBlock_v4_4__i__io_nxt_sel_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_3_0, IterBlock_v4_4__i__io_nxt_sel_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_sel_3_1 !== IterBlock_v4_4__i__io_nxt_sel_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_sel_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_sel_3_1, IterBlock_v4_4__i__io_nxt_sel_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_0_0 !== IterBlock_v4_4__i__io_nxt_spec_0_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_0_0, IterBlock_v4_4__i__io_nxt_spec_0_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_0_1 !== IterBlock_v4_4__i__io_nxt_spec_0_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_0_1, IterBlock_v4_4__i__io_nxt_spec_0_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_1_0 !== IterBlock_v4_4__i__io_nxt_spec_0_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_1_0, IterBlock_v4_4__i__io_nxt_spec_0_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_1_1 !== IterBlock_v4_4__i__io_nxt_spec_0_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_1_1, IterBlock_v4_4__i__io_nxt_spec_0_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_2_0 !== IterBlock_v4_4__i__io_nxt_spec_0_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_2_0, IterBlock_v4_4__i__io_nxt_spec_0_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_2_1 !== IterBlock_v4_4__i__io_nxt_spec_0_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_2_1, IterBlock_v4_4__i__io_nxt_spec_0_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_3_0 !== IterBlock_v4_4__i__io_nxt_spec_0_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_3_0, IterBlock_v4_4__i__io_nxt_spec_0_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_0_3_1 !== IterBlock_v4_4__i__io_nxt_spec_0_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_0_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_0_3_1, IterBlock_v4_4__i__io_nxt_spec_0_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_0_0 !== IterBlock_v4_4__i__io_nxt_spec_1_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_0_0, IterBlock_v4_4__i__io_nxt_spec_1_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_0_1 !== IterBlock_v4_4__i__io_nxt_spec_1_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_0_1, IterBlock_v4_4__i__io_nxt_spec_1_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_1_0 !== IterBlock_v4_4__i__io_nxt_spec_1_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_1_0, IterBlock_v4_4__i__io_nxt_spec_1_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_1_1 !== IterBlock_v4_4__i__io_nxt_spec_1_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_1_1, IterBlock_v4_4__i__io_nxt_spec_1_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_2_0 !== IterBlock_v4_4__i__io_nxt_spec_1_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_2_0, IterBlock_v4_4__i__io_nxt_spec_1_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_2_1 !== IterBlock_v4_4__i__io_nxt_spec_1_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_2_1, IterBlock_v4_4__i__io_nxt_spec_1_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_3_0 !== IterBlock_v4_4__i__io_nxt_spec_1_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_3_0, IterBlock_v4_4__i__io_nxt_spec_1_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_1_3_1 !== IterBlock_v4_4__i__io_nxt_spec_1_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_1_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_1_3_1, IterBlock_v4_4__i__io_nxt_spec_1_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_0_0 !== IterBlock_v4_4__i__io_nxt_spec_2_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_0_0, IterBlock_v4_4__i__io_nxt_spec_2_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_0_1 !== IterBlock_v4_4__i__io_nxt_spec_2_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_0_1, IterBlock_v4_4__i__io_nxt_spec_2_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_1_0 !== IterBlock_v4_4__i__io_nxt_spec_2_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_1_0, IterBlock_v4_4__i__io_nxt_spec_2_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_1_1 !== IterBlock_v4_4__i__io_nxt_spec_2_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_1_1, IterBlock_v4_4__i__io_nxt_spec_2_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_2_0 !== IterBlock_v4_4__i__io_nxt_spec_2_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_2_0, IterBlock_v4_4__i__io_nxt_spec_2_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_2_1 !== IterBlock_v4_4__i__io_nxt_spec_2_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_2_1, IterBlock_v4_4__i__io_nxt_spec_2_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_3_0 !== IterBlock_v4_4__i__io_nxt_spec_2_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_3_0, IterBlock_v4_4__i__io_nxt_spec_2_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_2_3_1 !== IterBlock_v4_4__i__io_nxt_spec_2_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_2_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_2_3_1, IterBlock_v4_4__i__io_nxt_spec_2_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_0_0 !== IterBlock_v4_4__i__io_nxt_spec_3_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_0_0, IterBlock_v4_4__i__io_nxt_spec_3_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_0_1 !== IterBlock_v4_4__i__io_nxt_spec_3_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_0_1, IterBlock_v4_4__i__io_nxt_spec_3_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_1_0 !== IterBlock_v4_4__i__io_nxt_spec_3_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_1_0, IterBlock_v4_4__i__io_nxt_spec_3_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_1_1 !== IterBlock_v4_4__i__io_nxt_spec_3_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_1_1, IterBlock_v4_4__i__io_nxt_spec_3_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_2_0 !== IterBlock_v4_4__i__io_nxt_spec_3_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_2_0, IterBlock_v4_4__i__io_nxt_spec_3_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_2_1 !== IterBlock_v4_4__i__io_nxt_spec_3_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_2_1, IterBlock_v4_4__i__io_nxt_spec_3_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_3_0 !== IterBlock_v4_4__i__io_nxt_spec_3_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_3_0, IterBlock_v4_4__i__io_nxt_spec_3_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_3_3_1 !== IterBlock_v4_4__i__io_nxt_spec_3_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_3_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_3_3_1, IterBlock_v4_4__i__io_nxt_spec_3_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_0_0 !== IterBlock_v4_4__i__io_nxt_spec_4_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_0_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_0_0, IterBlock_v4_4__i__io_nxt_spec_4_0_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_0_1 !== IterBlock_v4_4__i__io_nxt_spec_4_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_0_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_0_1, IterBlock_v4_4__i__io_nxt_spec_4_0_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_1_0 !== IterBlock_v4_4__i__io_nxt_spec_4_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_1_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_1_0, IterBlock_v4_4__i__io_nxt_spec_4_1_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_1_1 !== IterBlock_v4_4__i__io_nxt_spec_4_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_1_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_1_1, IterBlock_v4_4__i__io_nxt_spec_4_1_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_2_0 !== IterBlock_v4_4__i__io_nxt_spec_4_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_2_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_2_0, IterBlock_v4_4__i__io_nxt_spec_4_2_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_2_1 !== IterBlock_v4_4__i__io_nxt_spec_4_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_2_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_2_1, IterBlock_v4_4__i__io_nxt_spec_4_2_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_3_0 !== IterBlock_v4_4__i__io_nxt_spec_4_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_3_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_3_0, IterBlock_v4_4__i__io_nxt_spec_4_3_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_spec_4_3_1 !== IterBlock_v4_4__i__io_nxt_spec_4_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_spec_4_3_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_spec_4_3_1, IterBlock_v4_4__i__io_nxt_spec_4_3_1); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_iterB_0 !== IterBlock_v4_4__i__io_nxt_iterB_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_iterB_0 g=%h i=%h", IterBlock_v4_4__g__io_nxt_iterB_0, IterBlock_v4_4__i__io_nxt_iterB_0); end
    checks++;
    if (IterBlock_v4_4__g__io_nxt_iterB_1 !== IterBlock_v4_4__i__io_nxt_iterB_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_4.io_nxt_iterB_1 g=%h i=%h", IterBlock_v4_4__g__io_nxt_iterB_1, IterBlock_v4_4__i__io_nxt_iterB_1); end
  endtask
  // ---------------- IterBlock_v4_6（104 入 / 52 出）----------------
  logic [7:0] IterBlock_v4_6__io_Sel_cons_0_0;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_0_1;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_0_2;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_0_3;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_1_0;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_1_1;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_1_2;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_1_3;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_2_0;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_2_1;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_2_2;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_2_3;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_3_0;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_3_1;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_3_2;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_3_3;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_4_0;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_4_1;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_4_2;
  logic [7:0] IterBlock_v4_6__io_Sel_cons_4_3;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_0_0;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_0_1;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_0_2;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_0_3;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_1_0;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_1_1;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_1_2;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_1_3;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_2_0;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_2_1;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_2_2;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_2_3;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_3_0;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_3_1;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_3_2;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_3_3;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_4_0;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_4_1;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_4_2;
  logic [8:0] IterBlock_v4_6__io_Spec_cons_4_3;
  logic [69:0] IterBlock_v4_6__io_iter_cons_0;
  logic [69:0] IterBlock_v4_6__io_iter_cons_1;
  logic [69:0] IterBlock_v4_6__io_iter_cons_3;
  logic [69:0] IterBlock_v4_6__io_iter_cons_4;
  logic [8:0] IterBlock_v4_6__io_d_trunc_0;
  logic [8:0] IterBlock_v4_6__io_d_trunc_1;
  logic [8:0] IterBlock_v4_6__io_d_trunc_2;
  logic [8:0] IterBlock_v4_6__io_d_trunc_3;
  logic [10:0] IterBlock_v4_6__io_spec_r2ud_0;
  logic [10:0] IterBlock_v4_6__io_spec_r2ud_1;
  logic [10:0] IterBlock_v4_6__io_spec_r2ud_3;
  logic [10:0] IterBlock_v4_6__io_spec_r2ud_4;
  logic [63:0] IterBlock_v4_6__io_pre_q_A;
  logic [63:0] IterBlock_v4_6__io_pre_q_B;
  logic [7:0] IterBlock_v4_6__io_pre_sel_0_0;
  logic [7:0] IterBlock_v4_6__io_pre_sel_0_1;
  logic [7:0] IterBlock_v4_6__io_pre_sel_1_0;
  logic [7:0] IterBlock_v4_6__io_pre_sel_1_1;
  logic [7:0] IterBlock_v4_6__io_pre_sel_2_0;
  logic [7:0] IterBlock_v4_6__io_pre_sel_2_1;
  logic [7:0] IterBlock_v4_6__io_pre_sel_3_0;
  logic [7:0] IterBlock_v4_6__io_pre_sel_3_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_0_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_0_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_1_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_1_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_2_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_2_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_3_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_0_3_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_0_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_0_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_1_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_1_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_2_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_2_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_3_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_1_3_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_0_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_0_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_1_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_1_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_2_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_2_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_3_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_2_3_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_0_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_0_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_1_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_1_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_2_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_2_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_3_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_3_3_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_0_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_0_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_1_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_1_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_2_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_2_1;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_3_0;
  logic [8:0] IterBlock_v4_6__io_pre_spec_4_3_1;
  logic [69:0] IterBlock_v4_6__io_pre_iterB_0;
  logic [69:0] IterBlock_v4_6__io_pre_iterB_1;
  wire  [63:0] IterBlock_v4_6__g__io_nxt_q_A, IterBlock_v4_6__i__io_nxt_q_A;
  wire  [63:0] IterBlock_v4_6__g__io_nxt_q_B, IterBlock_v4_6__i__io_nxt_q_B;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_0_0, IterBlock_v4_6__i__io_nxt_sel_0_0;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_0_1, IterBlock_v4_6__i__io_nxt_sel_0_1;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_1_0, IterBlock_v4_6__i__io_nxt_sel_1_0;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_1_1, IterBlock_v4_6__i__io_nxt_sel_1_1;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_2_0, IterBlock_v4_6__i__io_nxt_sel_2_0;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_2_1, IterBlock_v4_6__i__io_nxt_sel_2_1;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_3_0, IterBlock_v4_6__i__io_nxt_sel_3_0;
  wire  [7:0] IterBlock_v4_6__g__io_nxt_sel_3_1, IterBlock_v4_6__i__io_nxt_sel_3_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_0_0, IterBlock_v4_6__i__io_nxt_spec_0_0_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_0_1, IterBlock_v4_6__i__io_nxt_spec_0_0_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_1_0, IterBlock_v4_6__i__io_nxt_spec_0_1_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_1_1, IterBlock_v4_6__i__io_nxt_spec_0_1_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_2_0, IterBlock_v4_6__i__io_nxt_spec_0_2_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_2_1, IterBlock_v4_6__i__io_nxt_spec_0_2_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_3_0, IterBlock_v4_6__i__io_nxt_spec_0_3_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_0_3_1, IterBlock_v4_6__i__io_nxt_spec_0_3_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_0_0, IterBlock_v4_6__i__io_nxt_spec_1_0_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_0_1, IterBlock_v4_6__i__io_nxt_spec_1_0_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_1_0, IterBlock_v4_6__i__io_nxt_spec_1_1_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_1_1, IterBlock_v4_6__i__io_nxt_spec_1_1_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_2_0, IterBlock_v4_6__i__io_nxt_spec_1_2_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_2_1, IterBlock_v4_6__i__io_nxt_spec_1_2_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_3_0, IterBlock_v4_6__i__io_nxt_spec_1_3_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_1_3_1, IterBlock_v4_6__i__io_nxt_spec_1_3_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_0_0, IterBlock_v4_6__i__io_nxt_spec_2_0_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_0_1, IterBlock_v4_6__i__io_nxt_spec_2_0_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_1_0, IterBlock_v4_6__i__io_nxt_spec_2_1_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_1_1, IterBlock_v4_6__i__io_nxt_spec_2_1_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_2_0, IterBlock_v4_6__i__io_nxt_spec_2_2_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_2_1, IterBlock_v4_6__i__io_nxt_spec_2_2_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_3_0, IterBlock_v4_6__i__io_nxt_spec_2_3_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_2_3_1, IterBlock_v4_6__i__io_nxt_spec_2_3_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_0_0, IterBlock_v4_6__i__io_nxt_spec_3_0_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_0_1, IterBlock_v4_6__i__io_nxt_spec_3_0_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_1_0, IterBlock_v4_6__i__io_nxt_spec_3_1_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_1_1, IterBlock_v4_6__i__io_nxt_spec_3_1_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_2_0, IterBlock_v4_6__i__io_nxt_spec_3_2_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_2_1, IterBlock_v4_6__i__io_nxt_spec_3_2_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_3_0, IterBlock_v4_6__i__io_nxt_spec_3_3_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_3_3_1, IterBlock_v4_6__i__io_nxt_spec_3_3_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_0_0, IterBlock_v4_6__i__io_nxt_spec_4_0_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_0_1, IterBlock_v4_6__i__io_nxt_spec_4_0_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_1_0, IterBlock_v4_6__i__io_nxt_spec_4_1_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_1_1, IterBlock_v4_6__i__io_nxt_spec_4_1_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_2_0, IterBlock_v4_6__i__io_nxt_spec_4_2_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_2_1, IterBlock_v4_6__i__io_nxt_spec_4_2_1;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_3_0, IterBlock_v4_6__i__io_nxt_spec_4_3_0;
  wire  [8:0] IterBlock_v4_6__g__io_nxt_spec_4_3_1, IterBlock_v4_6__i__io_nxt_spec_4_3_1;
  wire  [69:0] IterBlock_v4_6__g__io_nxt_iterB_0, IterBlock_v4_6__i__io_nxt_iterB_0;
  wire  [69:0] IterBlock_v4_6__g__io_nxt_iterB_1, IterBlock_v4_6__i__io_nxt_iterB_1;
  IterBlock_v4_6 u_g_IterBlock_v4_6 (
    .io_Sel_cons_0_0(IterBlock_v4_6__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4_6__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4_6__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4_6__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4_6__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4_6__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4_6__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4_6__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4_6__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4_6__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4_6__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4_6__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4_6__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4_6__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4_6__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4_6__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4_6__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4_6__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4_6__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4_6__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4_6__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4_6__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4_6__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4_6__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4_6__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4_6__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4_6__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4_6__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4_6__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4_6__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4_6__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4_6__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4_6__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4_6__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4_6__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4_6__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4_6__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4_6__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4_6__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4_6__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4_6__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4_6__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4_6__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4_6__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4_6__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4_6__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4_6__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4_6__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4_6__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4_6__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4_6__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4_6__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4_6__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4_6__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4_6__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4_6__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4_6__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4_6__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4_6__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4_6__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4_6__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4_6__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4_6__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4_6__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4_6__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4_6__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4_6__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4_6__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4_6__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4_6__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4_6__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4_6__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4_6__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4_6__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4_6__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4_6__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4_6__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4_6__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4_6__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4_6__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4_6__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4_6__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4_6__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4_6__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4_6__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4_6__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4_6__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4_6__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4_6__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4_6__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4_6__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4_6__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4_6__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4_6__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4_6__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4_6__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4_6__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4_6__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4_6__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4_6__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4_6__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4_6__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4_6__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4_6__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4_6__g__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4_6__g__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4_6__g__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4_6__g__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4_6__g__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4_6__g__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4_6__g__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4_6__g__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4_6__g__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4_6__g__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4_6__g__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4_6__g__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4_6__g__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4_6__g__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4_6__g__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4_6__g__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4_6__g__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4_6__g__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4_6__g__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4_6__g__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4_6__g__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4_6__g__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4_6__g__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4_6__g__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4_6__g__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4_6__g__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4_6__g__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4_6__g__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4_6__g__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4_6__g__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4_6__g__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4_6__g__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4_6__g__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4_6__g__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4_6__g__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4_6__g__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4_6__g__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4_6__g__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4_6__g__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4_6__g__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4_6__g__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4_6__g__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4_6__g__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4_6__g__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4_6__g__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4_6__g__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4_6__g__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4_6__g__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4_6__g__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4_6__g__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4_6__g__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4_6__g__io_nxt_iterB_1)
  );
  IterBlock_v4_6_xs u_i_IterBlock_v4_6 (
    .io_Sel_cons_0_0(IterBlock_v4_6__io_Sel_cons_0_0),
    .io_Sel_cons_0_1(IterBlock_v4_6__io_Sel_cons_0_1),
    .io_Sel_cons_0_2(IterBlock_v4_6__io_Sel_cons_0_2),
    .io_Sel_cons_0_3(IterBlock_v4_6__io_Sel_cons_0_3),
    .io_Sel_cons_1_0(IterBlock_v4_6__io_Sel_cons_1_0),
    .io_Sel_cons_1_1(IterBlock_v4_6__io_Sel_cons_1_1),
    .io_Sel_cons_1_2(IterBlock_v4_6__io_Sel_cons_1_2),
    .io_Sel_cons_1_3(IterBlock_v4_6__io_Sel_cons_1_3),
    .io_Sel_cons_2_0(IterBlock_v4_6__io_Sel_cons_2_0),
    .io_Sel_cons_2_1(IterBlock_v4_6__io_Sel_cons_2_1),
    .io_Sel_cons_2_2(IterBlock_v4_6__io_Sel_cons_2_2),
    .io_Sel_cons_2_3(IterBlock_v4_6__io_Sel_cons_2_3),
    .io_Sel_cons_3_0(IterBlock_v4_6__io_Sel_cons_3_0),
    .io_Sel_cons_3_1(IterBlock_v4_6__io_Sel_cons_3_1),
    .io_Sel_cons_3_2(IterBlock_v4_6__io_Sel_cons_3_2),
    .io_Sel_cons_3_3(IterBlock_v4_6__io_Sel_cons_3_3),
    .io_Sel_cons_4_0(IterBlock_v4_6__io_Sel_cons_4_0),
    .io_Sel_cons_4_1(IterBlock_v4_6__io_Sel_cons_4_1),
    .io_Sel_cons_4_2(IterBlock_v4_6__io_Sel_cons_4_2),
    .io_Sel_cons_4_3(IterBlock_v4_6__io_Sel_cons_4_3),
    .io_Spec_cons_0_0(IterBlock_v4_6__io_Spec_cons_0_0),
    .io_Spec_cons_0_1(IterBlock_v4_6__io_Spec_cons_0_1),
    .io_Spec_cons_0_2(IterBlock_v4_6__io_Spec_cons_0_2),
    .io_Spec_cons_0_3(IterBlock_v4_6__io_Spec_cons_0_3),
    .io_Spec_cons_1_0(IterBlock_v4_6__io_Spec_cons_1_0),
    .io_Spec_cons_1_1(IterBlock_v4_6__io_Spec_cons_1_1),
    .io_Spec_cons_1_2(IterBlock_v4_6__io_Spec_cons_1_2),
    .io_Spec_cons_1_3(IterBlock_v4_6__io_Spec_cons_1_3),
    .io_Spec_cons_2_0(IterBlock_v4_6__io_Spec_cons_2_0),
    .io_Spec_cons_2_1(IterBlock_v4_6__io_Spec_cons_2_1),
    .io_Spec_cons_2_2(IterBlock_v4_6__io_Spec_cons_2_2),
    .io_Spec_cons_2_3(IterBlock_v4_6__io_Spec_cons_2_3),
    .io_Spec_cons_3_0(IterBlock_v4_6__io_Spec_cons_3_0),
    .io_Spec_cons_3_1(IterBlock_v4_6__io_Spec_cons_3_1),
    .io_Spec_cons_3_2(IterBlock_v4_6__io_Spec_cons_3_2),
    .io_Spec_cons_3_3(IterBlock_v4_6__io_Spec_cons_3_3),
    .io_Spec_cons_4_0(IterBlock_v4_6__io_Spec_cons_4_0),
    .io_Spec_cons_4_1(IterBlock_v4_6__io_Spec_cons_4_1),
    .io_Spec_cons_4_2(IterBlock_v4_6__io_Spec_cons_4_2),
    .io_Spec_cons_4_3(IterBlock_v4_6__io_Spec_cons_4_3),
    .io_iter_cons_0(IterBlock_v4_6__io_iter_cons_0),
    .io_iter_cons_1(IterBlock_v4_6__io_iter_cons_1),
    .io_iter_cons_3(IterBlock_v4_6__io_iter_cons_3),
    .io_iter_cons_4(IterBlock_v4_6__io_iter_cons_4),
    .io_d_trunc_0(IterBlock_v4_6__io_d_trunc_0),
    .io_d_trunc_1(IterBlock_v4_6__io_d_trunc_1),
    .io_d_trunc_2(IterBlock_v4_6__io_d_trunc_2),
    .io_d_trunc_3(IterBlock_v4_6__io_d_trunc_3),
    .io_spec_r2ud_0(IterBlock_v4_6__io_spec_r2ud_0),
    .io_spec_r2ud_1(IterBlock_v4_6__io_spec_r2ud_1),
    .io_spec_r2ud_3(IterBlock_v4_6__io_spec_r2ud_3),
    .io_spec_r2ud_4(IterBlock_v4_6__io_spec_r2ud_4),
    .io_pre_q_A(IterBlock_v4_6__io_pre_q_A),
    .io_pre_q_B(IterBlock_v4_6__io_pre_q_B),
    .io_pre_sel_0_0(IterBlock_v4_6__io_pre_sel_0_0),
    .io_pre_sel_0_1(IterBlock_v4_6__io_pre_sel_0_1),
    .io_pre_sel_1_0(IterBlock_v4_6__io_pre_sel_1_0),
    .io_pre_sel_1_1(IterBlock_v4_6__io_pre_sel_1_1),
    .io_pre_sel_2_0(IterBlock_v4_6__io_pre_sel_2_0),
    .io_pre_sel_2_1(IterBlock_v4_6__io_pre_sel_2_1),
    .io_pre_sel_3_0(IterBlock_v4_6__io_pre_sel_3_0),
    .io_pre_sel_3_1(IterBlock_v4_6__io_pre_sel_3_1),
    .io_pre_spec_0_0_0(IterBlock_v4_6__io_pre_spec_0_0_0),
    .io_pre_spec_0_0_1(IterBlock_v4_6__io_pre_spec_0_0_1),
    .io_pre_spec_0_1_0(IterBlock_v4_6__io_pre_spec_0_1_0),
    .io_pre_spec_0_1_1(IterBlock_v4_6__io_pre_spec_0_1_1),
    .io_pre_spec_0_2_0(IterBlock_v4_6__io_pre_spec_0_2_0),
    .io_pre_spec_0_2_1(IterBlock_v4_6__io_pre_spec_0_2_1),
    .io_pre_spec_0_3_0(IterBlock_v4_6__io_pre_spec_0_3_0),
    .io_pre_spec_0_3_1(IterBlock_v4_6__io_pre_spec_0_3_1),
    .io_pre_spec_1_0_0(IterBlock_v4_6__io_pre_spec_1_0_0),
    .io_pre_spec_1_0_1(IterBlock_v4_6__io_pre_spec_1_0_1),
    .io_pre_spec_1_1_0(IterBlock_v4_6__io_pre_spec_1_1_0),
    .io_pre_spec_1_1_1(IterBlock_v4_6__io_pre_spec_1_1_1),
    .io_pre_spec_1_2_0(IterBlock_v4_6__io_pre_spec_1_2_0),
    .io_pre_spec_1_2_1(IterBlock_v4_6__io_pre_spec_1_2_1),
    .io_pre_spec_1_3_0(IterBlock_v4_6__io_pre_spec_1_3_0),
    .io_pre_spec_1_3_1(IterBlock_v4_6__io_pre_spec_1_3_1),
    .io_pre_spec_2_0_0(IterBlock_v4_6__io_pre_spec_2_0_0),
    .io_pre_spec_2_0_1(IterBlock_v4_6__io_pre_spec_2_0_1),
    .io_pre_spec_2_1_0(IterBlock_v4_6__io_pre_spec_2_1_0),
    .io_pre_spec_2_1_1(IterBlock_v4_6__io_pre_spec_2_1_1),
    .io_pre_spec_2_2_0(IterBlock_v4_6__io_pre_spec_2_2_0),
    .io_pre_spec_2_2_1(IterBlock_v4_6__io_pre_spec_2_2_1),
    .io_pre_spec_2_3_0(IterBlock_v4_6__io_pre_spec_2_3_0),
    .io_pre_spec_2_3_1(IterBlock_v4_6__io_pre_spec_2_3_1),
    .io_pre_spec_3_0_0(IterBlock_v4_6__io_pre_spec_3_0_0),
    .io_pre_spec_3_0_1(IterBlock_v4_6__io_pre_spec_3_0_1),
    .io_pre_spec_3_1_0(IterBlock_v4_6__io_pre_spec_3_1_0),
    .io_pre_spec_3_1_1(IterBlock_v4_6__io_pre_spec_3_1_1),
    .io_pre_spec_3_2_0(IterBlock_v4_6__io_pre_spec_3_2_0),
    .io_pre_spec_3_2_1(IterBlock_v4_6__io_pre_spec_3_2_1),
    .io_pre_spec_3_3_0(IterBlock_v4_6__io_pre_spec_3_3_0),
    .io_pre_spec_3_3_1(IterBlock_v4_6__io_pre_spec_3_3_1),
    .io_pre_spec_4_0_0(IterBlock_v4_6__io_pre_spec_4_0_0),
    .io_pre_spec_4_0_1(IterBlock_v4_6__io_pre_spec_4_0_1),
    .io_pre_spec_4_1_0(IterBlock_v4_6__io_pre_spec_4_1_0),
    .io_pre_spec_4_1_1(IterBlock_v4_6__io_pre_spec_4_1_1),
    .io_pre_spec_4_2_0(IterBlock_v4_6__io_pre_spec_4_2_0),
    .io_pre_spec_4_2_1(IterBlock_v4_6__io_pre_spec_4_2_1),
    .io_pre_spec_4_3_0(IterBlock_v4_6__io_pre_spec_4_3_0),
    .io_pre_spec_4_3_1(IterBlock_v4_6__io_pre_spec_4_3_1),
    .io_pre_iterB_0(IterBlock_v4_6__io_pre_iterB_0),
    .io_pre_iterB_1(IterBlock_v4_6__io_pre_iterB_1),
    .io_nxt_q_A(IterBlock_v4_6__i__io_nxt_q_A),
    .io_nxt_q_B(IterBlock_v4_6__i__io_nxt_q_B),
    .io_nxt_sel_0_0(IterBlock_v4_6__i__io_nxt_sel_0_0),
    .io_nxt_sel_0_1(IterBlock_v4_6__i__io_nxt_sel_0_1),
    .io_nxt_sel_1_0(IterBlock_v4_6__i__io_nxt_sel_1_0),
    .io_nxt_sel_1_1(IterBlock_v4_6__i__io_nxt_sel_1_1),
    .io_nxt_sel_2_0(IterBlock_v4_6__i__io_nxt_sel_2_0),
    .io_nxt_sel_2_1(IterBlock_v4_6__i__io_nxt_sel_2_1),
    .io_nxt_sel_3_0(IterBlock_v4_6__i__io_nxt_sel_3_0),
    .io_nxt_sel_3_1(IterBlock_v4_6__i__io_nxt_sel_3_1),
    .io_nxt_spec_0_0_0(IterBlock_v4_6__i__io_nxt_spec_0_0_0),
    .io_nxt_spec_0_0_1(IterBlock_v4_6__i__io_nxt_spec_0_0_1),
    .io_nxt_spec_0_1_0(IterBlock_v4_6__i__io_nxt_spec_0_1_0),
    .io_nxt_spec_0_1_1(IterBlock_v4_6__i__io_nxt_spec_0_1_1),
    .io_nxt_spec_0_2_0(IterBlock_v4_6__i__io_nxt_spec_0_2_0),
    .io_nxt_spec_0_2_1(IterBlock_v4_6__i__io_nxt_spec_0_2_1),
    .io_nxt_spec_0_3_0(IterBlock_v4_6__i__io_nxt_spec_0_3_0),
    .io_nxt_spec_0_3_1(IterBlock_v4_6__i__io_nxt_spec_0_3_1),
    .io_nxt_spec_1_0_0(IterBlock_v4_6__i__io_nxt_spec_1_0_0),
    .io_nxt_spec_1_0_1(IterBlock_v4_6__i__io_nxt_spec_1_0_1),
    .io_nxt_spec_1_1_0(IterBlock_v4_6__i__io_nxt_spec_1_1_0),
    .io_nxt_spec_1_1_1(IterBlock_v4_6__i__io_nxt_spec_1_1_1),
    .io_nxt_spec_1_2_0(IterBlock_v4_6__i__io_nxt_spec_1_2_0),
    .io_nxt_spec_1_2_1(IterBlock_v4_6__i__io_nxt_spec_1_2_1),
    .io_nxt_spec_1_3_0(IterBlock_v4_6__i__io_nxt_spec_1_3_0),
    .io_nxt_spec_1_3_1(IterBlock_v4_6__i__io_nxt_spec_1_3_1),
    .io_nxt_spec_2_0_0(IterBlock_v4_6__i__io_nxt_spec_2_0_0),
    .io_nxt_spec_2_0_1(IterBlock_v4_6__i__io_nxt_spec_2_0_1),
    .io_nxt_spec_2_1_0(IterBlock_v4_6__i__io_nxt_spec_2_1_0),
    .io_nxt_spec_2_1_1(IterBlock_v4_6__i__io_nxt_spec_2_1_1),
    .io_nxt_spec_2_2_0(IterBlock_v4_6__i__io_nxt_spec_2_2_0),
    .io_nxt_spec_2_2_1(IterBlock_v4_6__i__io_nxt_spec_2_2_1),
    .io_nxt_spec_2_3_0(IterBlock_v4_6__i__io_nxt_spec_2_3_0),
    .io_nxt_spec_2_3_1(IterBlock_v4_6__i__io_nxt_spec_2_3_1),
    .io_nxt_spec_3_0_0(IterBlock_v4_6__i__io_nxt_spec_3_0_0),
    .io_nxt_spec_3_0_1(IterBlock_v4_6__i__io_nxt_spec_3_0_1),
    .io_nxt_spec_3_1_0(IterBlock_v4_6__i__io_nxt_spec_3_1_0),
    .io_nxt_spec_3_1_1(IterBlock_v4_6__i__io_nxt_spec_3_1_1),
    .io_nxt_spec_3_2_0(IterBlock_v4_6__i__io_nxt_spec_3_2_0),
    .io_nxt_spec_3_2_1(IterBlock_v4_6__i__io_nxt_spec_3_2_1),
    .io_nxt_spec_3_3_0(IterBlock_v4_6__i__io_nxt_spec_3_3_0),
    .io_nxt_spec_3_3_1(IterBlock_v4_6__i__io_nxt_spec_3_3_1),
    .io_nxt_spec_4_0_0(IterBlock_v4_6__i__io_nxt_spec_4_0_0),
    .io_nxt_spec_4_0_1(IterBlock_v4_6__i__io_nxt_spec_4_0_1),
    .io_nxt_spec_4_1_0(IterBlock_v4_6__i__io_nxt_spec_4_1_0),
    .io_nxt_spec_4_1_1(IterBlock_v4_6__i__io_nxt_spec_4_1_1),
    .io_nxt_spec_4_2_0(IterBlock_v4_6__i__io_nxt_spec_4_2_0),
    .io_nxt_spec_4_2_1(IterBlock_v4_6__i__io_nxt_spec_4_2_1),
    .io_nxt_spec_4_3_0(IterBlock_v4_6__i__io_nxt_spec_4_3_0),
    .io_nxt_spec_4_3_1(IterBlock_v4_6__i__io_nxt_spec_4_3_1),
    .io_nxt_iterB_0(IterBlock_v4_6__i__io_nxt_iterB_0),
    .io_nxt_iterB_1(IterBlock_v4_6__i__io_nxt_iterB_1)
  );
  task automatic drive_IterBlock_v4_6(input int mode);
    IterBlock_v4_6__io_Sel_cons_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_0_2 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_0_3 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_1_2 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_1_3 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_2_2 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_2_3 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_3_2 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_3_3 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_4_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_4_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_4_2 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Sel_cons_4_3 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_0_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_0_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_1_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_1_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_2_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_2_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_3_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_3_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_4_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_4_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_4_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_Spec_cons_4_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_iter_cons_0 = 70'(rnd_bits(mode));
    IterBlock_v4_6__io_iter_cons_1 = 70'(rnd_bits(mode));
    IterBlock_v4_6__io_iter_cons_3 = 70'(rnd_bits(mode));
    IterBlock_v4_6__io_iter_cons_4 = 70'(rnd_bits(mode));
    IterBlock_v4_6__io_d_trunc_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_d_trunc_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_d_trunc_2 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_d_trunc_3 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_spec_r2ud_0 = 11'(rnd_bits(mode));
    IterBlock_v4_6__io_spec_r2ud_1 = 11'(rnd_bits(mode));
    IterBlock_v4_6__io_spec_r2ud_3 = 11'(rnd_bits(mode));
    IterBlock_v4_6__io_spec_r2ud_4 = 11'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_q_A = 64'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_q_B = 64'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_0_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_0_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_1_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_1_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_2_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_2_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_3_0 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_sel_3_1 = 8'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_0_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_1_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_2_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_3_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_0_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_0_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_1_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_1_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_2_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_2_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_3_0 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_spec_4_3_1 = 9'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_iterB_0 = 70'(rnd_bits(mode));
    IterBlock_v4_6__io_pre_iterB_1 = 70'(rnd_bits(mode));
  endtask
  task automatic check_IterBlock_v4_6();
    checks++;
    if (IterBlock_v4_6__g__io_nxt_q_A !== IterBlock_v4_6__i__io_nxt_q_A) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_q_A g=%h i=%h", IterBlock_v4_6__g__io_nxt_q_A, IterBlock_v4_6__i__io_nxt_q_A); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_q_B !== IterBlock_v4_6__i__io_nxt_q_B) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_q_B g=%h i=%h", IterBlock_v4_6__g__io_nxt_q_B, IterBlock_v4_6__i__io_nxt_q_B); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_0_0 !== IterBlock_v4_6__i__io_nxt_sel_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_0_0, IterBlock_v4_6__i__io_nxt_sel_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_0_1 !== IterBlock_v4_6__i__io_nxt_sel_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_0_1, IterBlock_v4_6__i__io_nxt_sel_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_1_0 !== IterBlock_v4_6__i__io_nxt_sel_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_1_0, IterBlock_v4_6__i__io_nxt_sel_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_1_1 !== IterBlock_v4_6__i__io_nxt_sel_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_1_1, IterBlock_v4_6__i__io_nxt_sel_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_2_0 !== IterBlock_v4_6__i__io_nxt_sel_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_2_0, IterBlock_v4_6__i__io_nxt_sel_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_2_1 !== IterBlock_v4_6__i__io_nxt_sel_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_2_1, IterBlock_v4_6__i__io_nxt_sel_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_3_0 !== IterBlock_v4_6__i__io_nxt_sel_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_3_0, IterBlock_v4_6__i__io_nxt_sel_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_sel_3_1 !== IterBlock_v4_6__i__io_nxt_sel_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_sel_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_sel_3_1, IterBlock_v4_6__i__io_nxt_sel_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_0_0 !== IterBlock_v4_6__i__io_nxt_spec_0_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_0_0, IterBlock_v4_6__i__io_nxt_spec_0_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_0_1 !== IterBlock_v4_6__i__io_nxt_spec_0_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_0_1, IterBlock_v4_6__i__io_nxt_spec_0_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_1_0 !== IterBlock_v4_6__i__io_nxt_spec_0_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_1_0, IterBlock_v4_6__i__io_nxt_spec_0_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_1_1 !== IterBlock_v4_6__i__io_nxt_spec_0_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_1_1, IterBlock_v4_6__i__io_nxt_spec_0_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_2_0 !== IterBlock_v4_6__i__io_nxt_spec_0_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_2_0, IterBlock_v4_6__i__io_nxt_spec_0_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_2_1 !== IterBlock_v4_6__i__io_nxt_spec_0_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_2_1, IterBlock_v4_6__i__io_nxt_spec_0_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_3_0 !== IterBlock_v4_6__i__io_nxt_spec_0_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_3_0, IterBlock_v4_6__i__io_nxt_spec_0_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_0_3_1 !== IterBlock_v4_6__i__io_nxt_spec_0_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_0_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_0_3_1, IterBlock_v4_6__i__io_nxt_spec_0_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_0_0 !== IterBlock_v4_6__i__io_nxt_spec_1_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_0_0, IterBlock_v4_6__i__io_nxt_spec_1_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_0_1 !== IterBlock_v4_6__i__io_nxt_spec_1_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_0_1, IterBlock_v4_6__i__io_nxt_spec_1_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_1_0 !== IterBlock_v4_6__i__io_nxt_spec_1_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_1_0, IterBlock_v4_6__i__io_nxt_spec_1_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_1_1 !== IterBlock_v4_6__i__io_nxt_spec_1_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_1_1, IterBlock_v4_6__i__io_nxt_spec_1_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_2_0 !== IterBlock_v4_6__i__io_nxt_spec_1_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_2_0, IterBlock_v4_6__i__io_nxt_spec_1_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_2_1 !== IterBlock_v4_6__i__io_nxt_spec_1_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_2_1, IterBlock_v4_6__i__io_nxt_spec_1_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_3_0 !== IterBlock_v4_6__i__io_nxt_spec_1_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_3_0, IterBlock_v4_6__i__io_nxt_spec_1_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_1_3_1 !== IterBlock_v4_6__i__io_nxt_spec_1_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_1_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_1_3_1, IterBlock_v4_6__i__io_nxt_spec_1_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_0_0 !== IterBlock_v4_6__i__io_nxt_spec_2_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_0_0, IterBlock_v4_6__i__io_nxt_spec_2_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_0_1 !== IterBlock_v4_6__i__io_nxt_spec_2_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_0_1, IterBlock_v4_6__i__io_nxt_spec_2_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_1_0 !== IterBlock_v4_6__i__io_nxt_spec_2_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_1_0, IterBlock_v4_6__i__io_nxt_spec_2_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_1_1 !== IterBlock_v4_6__i__io_nxt_spec_2_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_1_1, IterBlock_v4_6__i__io_nxt_spec_2_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_2_0 !== IterBlock_v4_6__i__io_nxt_spec_2_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_2_0, IterBlock_v4_6__i__io_nxt_spec_2_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_2_1 !== IterBlock_v4_6__i__io_nxt_spec_2_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_2_1, IterBlock_v4_6__i__io_nxt_spec_2_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_3_0 !== IterBlock_v4_6__i__io_nxt_spec_2_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_3_0, IterBlock_v4_6__i__io_nxt_spec_2_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_2_3_1 !== IterBlock_v4_6__i__io_nxt_spec_2_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_2_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_2_3_1, IterBlock_v4_6__i__io_nxt_spec_2_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_0_0 !== IterBlock_v4_6__i__io_nxt_spec_3_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_0_0, IterBlock_v4_6__i__io_nxt_spec_3_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_0_1 !== IterBlock_v4_6__i__io_nxt_spec_3_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_0_1, IterBlock_v4_6__i__io_nxt_spec_3_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_1_0 !== IterBlock_v4_6__i__io_nxt_spec_3_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_1_0, IterBlock_v4_6__i__io_nxt_spec_3_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_1_1 !== IterBlock_v4_6__i__io_nxt_spec_3_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_1_1, IterBlock_v4_6__i__io_nxt_spec_3_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_2_0 !== IterBlock_v4_6__i__io_nxt_spec_3_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_2_0, IterBlock_v4_6__i__io_nxt_spec_3_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_2_1 !== IterBlock_v4_6__i__io_nxt_spec_3_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_2_1, IterBlock_v4_6__i__io_nxt_spec_3_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_3_0 !== IterBlock_v4_6__i__io_nxt_spec_3_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_3_0, IterBlock_v4_6__i__io_nxt_spec_3_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_3_3_1 !== IterBlock_v4_6__i__io_nxt_spec_3_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_3_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_3_3_1, IterBlock_v4_6__i__io_nxt_spec_3_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_0_0 !== IterBlock_v4_6__i__io_nxt_spec_4_0_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_0_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_0_0, IterBlock_v4_6__i__io_nxt_spec_4_0_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_0_1 !== IterBlock_v4_6__i__io_nxt_spec_4_0_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_0_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_0_1, IterBlock_v4_6__i__io_nxt_spec_4_0_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_1_0 !== IterBlock_v4_6__i__io_nxt_spec_4_1_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_1_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_1_0, IterBlock_v4_6__i__io_nxt_spec_4_1_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_1_1 !== IterBlock_v4_6__i__io_nxt_spec_4_1_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_1_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_1_1, IterBlock_v4_6__i__io_nxt_spec_4_1_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_2_0 !== IterBlock_v4_6__i__io_nxt_spec_4_2_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_2_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_2_0, IterBlock_v4_6__i__io_nxt_spec_4_2_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_2_1 !== IterBlock_v4_6__i__io_nxt_spec_4_2_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_2_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_2_1, IterBlock_v4_6__i__io_nxt_spec_4_2_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_3_0 !== IterBlock_v4_6__i__io_nxt_spec_4_3_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_3_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_3_0, IterBlock_v4_6__i__io_nxt_spec_4_3_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_spec_4_3_1 !== IterBlock_v4_6__i__io_nxt_spec_4_3_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_spec_4_3_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_spec_4_3_1, IterBlock_v4_6__i__io_nxt_spec_4_3_1); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_iterB_0 !== IterBlock_v4_6__i__io_nxt_iterB_0) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_iterB_0 g=%h i=%h", IterBlock_v4_6__g__io_nxt_iterB_0, IterBlock_v4_6__i__io_nxt_iterB_0); end
    checks++;
    if (IterBlock_v4_6__g__io_nxt_iterB_1 !== IterBlock_v4_6__i__io_nxt_iterB_1) begin errors++; if (errors <= 10) $display("MISMATCH IterBlock_v4_6.io_nxt_iterB_1 g=%h i=%h", IterBlock_v4_6__g__io_nxt_iterB_1, IterBlock_v4_6__i__io_nxt_iterB_1); end
  endtask

  // ---------------- 系统级车道：SRT16Divint（16 位）----------------
  logic        L16_rst, L16_sign, L16_flush, L16_in_valid, L16_out_ready;
  logic [15:0] L16_dividend, L16_divisor;
  logic [1:0]  L16_sew;
  wire         L16_g_valid, L16_i_valid;
  wire  [15:0] L16_g_q, L16_g_rem, L16_i_q, L16_i_rem;
  div_lane #(.WIDTH(16), .MAXSEW(1), .NAME("SRT16Divint")) u_lane16 (
    .clk(clk), .rst(L16_rst), .sign(L16_sign), .dividend(L16_dividend), .divisor(L16_divisor),
    .flush(L16_flush), .sew(L16_sew), .in_valid(L16_in_valid), .out_ready(L16_out_ready),
    .g_valid(L16_g_valid), .g_q(L16_g_q), .g_rem(L16_g_rem),
    .i_valid(L16_i_valid), .i_q(L16_i_q), .i_rem(L16_i_rem));
  SRT16Divint u_g_SRT16Divint (
    .clock(clk), .reset(L16_rst), .io_sign(L16_sign), .io_dividend(L16_dividend),
    .io_divisor(L16_divisor), .io_flush(L16_flush), .io_sew(L16_sew),
    .io_div_in_valid(L16_in_valid), .io_div_out_ready(L16_out_ready),
    .io_div_out_valid(L16_g_valid), .io_div_out_q(L16_g_q), .io_div_out_rem(L16_g_rem));
  SRT16Divint_subst u_i_SRT16Divint (
    .clock(clk), .reset(L16_rst), .io_sign(L16_sign), .io_dividend(L16_dividend),
    .io_divisor(L16_divisor), .io_flush(L16_flush), .io_sew(L16_sew),
    .io_div_in_valid(L16_in_valid), .io_div_out_ready(L16_out_ready),
    .io_div_out_valid(L16_i_valid), .io_div_out_q(L16_i_q), .io_div_out_rem(L16_i_rem));

  // ---------------- 系统级车道：SRT16Divint_4（32 位）----------------
  logic        L32_rst, L32_sign, L32_flush, L32_in_valid, L32_out_ready;
  logic [31:0] L32_dividend, L32_divisor;
  logic [1:0]  L32_sew;
  wire         L32_g_valid, L32_i_valid;
  wire  [31:0] L32_g_q, L32_g_rem, L32_i_q, L32_i_rem;
  div_lane #(.WIDTH(32), .MAXSEW(2), .NAME("SRT16Divint_4")) u_lane32 (
    .clk(clk), .rst(L32_rst), .sign(L32_sign), .dividend(L32_dividend), .divisor(L32_divisor),
    .flush(L32_flush), .sew(L32_sew), .in_valid(L32_in_valid), .out_ready(L32_out_ready),
    .g_valid(L32_g_valid), .g_q(L32_g_q), .g_rem(L32_g_rem),
    .i_valid(L32_i_valid), .i_q(L32_i_q), .i_rem(L32_i_rem));
  SRT16Divint_4 u_g_SRT16Divint_4 (
    .clock(clk), .reset(L32_rst), .io_sign(L32_sign), .io_dividend(L32_dividend),
    .io_divisor(L32_divisor), .io_flush(L32_flush), .io_sew(L32_sew),
    .io_div_in_valid(L32_in_valid), .io_div_out_ready(L32_out_ready),
    .io_div_out_valid(L32_g_valid), .io_div_out_q(L32_g_q), .io_div_out_rem(L32_g_rem));
  SRT16Divint_4_subst u_i_SRT16Divint_4 (
    .clock(clk), .reset(L32_rst), .io_sign(L32_sign), .io_dividend(L32_dividend),
    .io_divisor(L32_divisor), .io_flush(L32_flush), .io_sew(L32_sew),
    .io_div_in_valid(L32_in_valid), .io_div_out_ready(L32_out_ready),
    .io_div_out_valid(L32_i_valid), .io_div_out_q(L32_i_q), .io_div_out_rem(L32_i_rem));

  // ---------------- 系统级车道：SRT16Divint_6（64 位）----------------
  logic        L64_rst, L64_sign, L64_flush, L64_in_valid, L64_out_ready;
  logic [63:0] L64_dividend, L64_divisor;
  logic [1:0]  L64_sew;
  wire         L64_g_valid, L64_i_valid;
  wire  [63:0] L64_g_q, L64_g_rem, L64_i_q, L64_i_rem;
  div_lane #(.WIDTH(64), .MAXSEW(3), .NAME("SRT16Divint_6")) u_lane64 (
    .clk(clk), .rst(L64_rst), .sign(L64_sign), .dividend(L64_dividend), .divisor(L64_divisor),
    .flush(L64_flush), .sew(L64_sew), .in_valid(L64_in_valid), .out_ready(L64_out_ready),
    .g_valid(L64_g_valid), .g_q(L64_g_q), .g_rem(L64_g_rem),
    .i_valid(L64_i_valid), .i_q(L64_i_q), .i_rem(L64_i_rem));
  SRT16Divint_6 u_g_SRT16Divint_6 (
    .clock(clk), .reset(L64_rst), .io_sign(L64_sign), .io_dividend(L64_dividend),
    .io_divisor(L64_divisor), .io_flush(L64_flush), .io_sew(L64_sew),
    .io_div_in_valid(L64_in_valid), .io_div_out_ready(L64_out_ready),
    .io_div_out_valid(L64_g_valid), .io_div_out_q(L64_g_q), .io_div_out_rem(L64_g_rem));
  SRT16Divint_6_subst u_i_SRT16Divint_6 (
    .clock(clk), .reset(L64_rst), .io_sign(L64_sign), .io_dividend(L64_dividend),
    .io_divisor(L64_divisor), .io_flush(L64_flush), .io_sew(L64_sew),
    .io_div_in_valid(L64_in_valid), .io_div_out_ready(L64_out_ready),
    .io_div_out_valid(L64_i_valid), .io_div_out_q(L64_i_q), .io_div_out_rem(L64_i_rem));

  // ---------------- 主循环：下降沿灌块级激励，上升沿比块级输出 ----------------
  initial begin
    int mode;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      mode = ($urandom_range(0, 15) == 0) ? 1 : (($urandom_range(0, 15) == 0) ? 2 : 0);
      drive_SelBlock_v4(mode);
      drive_SpecBlock_v4(mode);
      drive_IterBlock_v4(mode);
      drive_IterBlock_v4_4(mode);
      drive_IterBlock_v4_6(mode);
      @(posedge clk);
      #1;
      check_SelBlock_v4();
      check_SpecBlock_v4();
      check_IterBlock_v4();
      check_IterBlock_v4_4();
      check_IterBlock_v4_6();
    end
    @(negedge clk);
    $display("blocks: checks=%0d", checks);
    $display("cover SelBlock_v4 q_j_1 (golden): +2=%0d +1=%0d 0=%0d -1=%0d -2=%0d none=%0d multi=%0d",
             qhist_SelBlock_v4[0], qhist_SelBlock_v4[1], qhist_SelBlock_v4[2], qhist_SelBlock_v4[3],
             qhist_SelBlock_v4[4], qhist_SelBlock_v4[5], qhist_SelBlock_v4[6]);
    $display("cover SpecBlock_v4 q_j_2 (golden): +2=%0d +1=%0d 0=%0d -1=%0d -2=%0d none=%0d multi=%0d",
             qhist_SpecBlock_v4[0], qhist_SpecBlock_v4[1], qhist_SpecBlock_v4[2], qhist_SpecBlock_v4[3],
             qhist_SpecBlock_v4[4], qhist_SpecBlock_v4[5], qhist_SpecBlock_v4[6]);
    u_lane16.report();
    u_lane32.report();
    u_lane64.report();
    errors += u_lane16.errors + u_lane32.errors + u_lane64.errors;
    $display("SRT16IterBlocks: block_checks=%0d lane_checks=%0d errors=%0d", checks, u_lane16.oracle_checks + u_lane32.oracle_checks + u_lane64.oracle_checks, errors);
    if (errors == 0 && u_lane16.ops_done >= 1000 && u_lane32.ops_done >= 1000 && u_lane64.ops_done >= 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
