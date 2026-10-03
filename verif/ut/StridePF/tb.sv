// StridePF UT —— golden vs 重写件双例化。模块没有输出端口，逐拍比两侧全部寄存器（层次引用）。
//
// 比对对象（= golden 的 53 个寄存器）：prev_valid、prev_pc、valids[16]、entries_pc[16]、s1_hit/alloc 打拍、
// s1_match_vec[16]、PLRU state(15)。不复位的三组只在"被写过"之后比：prev_pc 在首个 lookup 之后、
// entries_pc[i] 在 valids[i]=1 时、s1_match_vec 在首个 s0_valid 之后（中途复位后重新计）。
// 激励：pc 从 24 个值的池子取（> 16 项 → 替换）、1/4 概率重复上一拍 pc（打去抖）、s1_valid 随机。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic       lv, s1v;
  logic [9:0] lpc;

  StridePF    g (.clock(clk), .reset(rst), .io_s0_lookup_valid(lv), .io_s0_lookup_bits_pc(lpc), .io_s1_valid(s1v));
  StridePF_xs i (.clock(clk), .reset(rst), .io_s0_lookup_valid(lv), .io_s0_lookup_bits_pc(lpc), .io_s1_valid(s1v));

  logic [9:0] pool [24];
  int cyc;
  bit seen_lookup, seen_s0valid;
  int cov_hit, cov_alloc, cov_dedup, cov_s1drop, cov_midrst;

  `define GV(n) g.valids_``n
  wire [15:0] g_valids = {g.valids_15, g.valids_14, g.valids_13, g.valids_12, g.valids_11, g.valids_10, g.valids_9, g.valids_8,
                          g.valids_7, g.valids_6, g.valids_5, g.valids_4, g.valids_3, g.valids_2, g.valids_1, g.valids_0};
  wire [15:0] g_match  = {g.s1_match_vec_15, g.s1_match_vec_14, g.s1_match_vec_13, g.s1_match_vec_12, g.s1_match_vec_11,
                          g.s1_match_vec_10, g.s1_match_vec_9, g.s1_match_vec_8, g.s1_match_vec_7, g.s1_match_vec_6,
                          g.s1_match_vec_5, g.s1_match_vec_4, g.s1_match_vec_3, g.s1_match_vec_2, g.s1_match_vec_1, g.s1_match_vec_0};
  wire [9:0]  g_pc [16] = '{g.entries_pc_0, g.entries_pc_1, g.entries_pc_2, g.entries_pc_3, g.entries_pc_4, g.entries_pc_5,
                            g.entries_pc_6, g.entries_pc_7, g.entries_pc_8, g.entries_pc_9, g.entries_pc_10, g.entries_pc_11,
                            g.entries_pc_12, g.entries_pc_13, g.entries_pc_14, g.entries_pc_15};
  logic [15:0] i_valids, i_match;
  always_comb for (int k = 0; k < 16; k++) begin i_valids[k] = i.u_core.ent_valid[k]; i_match[k] = i.u_core.s1_match[k]; end

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; lv <= 0; lpc <= '0; s1v <= 0; seen_lookup <= 0; seen_s0valid <= 0;
    end else begin
      cyc <= cyc + 1;
      lv  <= ($urandom_range(0, 2) != 0);
      s1v <= ($urandom_range(0, 3) != 0);
      if ($urandom_range(0, 3) != 0) lpc <= pool[$urandom_range(0, 23)];
      if ($urandom_range(0, 999) == 0) pool[$urandom_range(0, 23)] <= 10'($urandom);
      if (lv) seen_lookup <= 1;
      if (g.s0_valid) seen_s0valid <= 1;
    end
  end

  `define CHK(nm, gg, ii) \
    if ((gg) !== (ii)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, gg, ii); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("prev_valid", g.prev_valid_last_REG, i.u_core.prev_valid)
    if (seen_lookup) `CHK("prev_pc", g.prev_pc, i.u_core.prev_pc)
    `CHK("valids", g_valids, i_valids)
    `CHK("s1_hit_q", g.s1_hit_last_REG, i.u_core.s1_hit_q)
    `CHK("s1_alloc_q", g.s1_alloc_last_REG, i.u_core.s1_alloc_q)
    if (seen_s0valid) `CHK("s1_match_vec", g_match, i_match)
    `CHK("plru", g.state_reg, i.u_core.u_plru.state_reg)
    for (int k = 0; k < 16; k++) if (g_valids[k]) `CHK($sformatf("entries_pc[%0d]", k), g_pc[k], i.u_core.ent_pc[k])
    if (g.s1_hit) cov_hit++;
    if (g.s1_alloc) cov_alloc++;
    if (lv && !g.s0_valid) cov_dedup++;
    if ((g.s1_hit_last_REG || g.s1_alloc_last_REG) && !s1v) cov_s1drop++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 24; k++) pool[k] = 10'($urandom);
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV hit=%0d alloc=%0d dedup=%0d s1drop=%0d midrst=%0d", cov_hit, cov_alloc, cov_dedup, cov_s1drop, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_hit > 1000 && cov_alloc > 1000 && cov_dedup > 1000 && cov_s1drop > 1000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
