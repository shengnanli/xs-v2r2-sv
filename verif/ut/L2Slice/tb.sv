// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：L2Slice L2Slice_1 L2Slice_2 L2Slice_3
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= L2Slice =======================
  logic [3:0] L2Slice__mbist_array;
  logic L2Slice__mbist_all;
  logic L2Slice__mbist_req;
  logic L2Slice__mbist_writeen;
  logic [7:0] L2Slice__mbist_be;
  logic [12:0] L2Slice__mbist_addr;
  logic [136:0] L2Slice__mbist_indata;
  logic L2Slice__mbist_readen;
  logic [12:0] L2Slice__mbist_addr_rd;
  logic L2Slice__toNextPipeline_0_ack;
  logic [103:0] L2Slice__toNextPipeline_0_outdata;
  logic L2Slice__toNextPipeline_1_ack;
  logic [136:0] L2Slice__toNextPipeline_1_outdata;
  wire  g_L2Slice__mbist_ack;
  wire  i_L2Slice__mbist_ack;
  logic p_L2Slice__mbist_ack;
  bit   t_L2Slice__mbist_ack;
  wire  [136:0] g_L2Slice__mbist_outdata;
  wire  [136:0] i_L2Slice__mbist_outdata;
  logic [136:0] p_L2Slice__mbist_outdata;
  bit   t_L2Slice__mbist_outdata;
  wire  [3:0] g_L2Slice__toNextPipeline_0_array;
  wire  [3:0] i_L2Slice__toNextPipeline_0_array;
  logic [3:0] p_L2Slice__toNextPipeline_0_array;
  bit   t_L2Slice__toNextPipeline_0_array;
  wire  g_L2Slice__toNextPipeline_0_all;
  wire  i_L2Slice__toNextPipeline_0_all;
  logic p_L2Slice__toNextPipeline_0_all;
  bit   t_L2Slice__toNextPipeline_0_all;
  wire  g_L2Slice__toNextPipeline_0_req;
  wire  i_L2Slice__toNextPipeline_0_req;
  logic p_L2Slice__toNextPipeline_0_req;
  bit   t_L2Slice__toNextPipeline_0_req;
  wire  g_L2Slice__toNextPipeline_0_writeen;
  wire  i_L2Slice__toNextPipeline_0_writeen;
  logic p_L2Slice__toNextPipeline_0_writeen;
  bit   t_L2Slice__toNextPipeline_0_writeen;
  wire  [7:0] g_L2Slice__toNextPipeline_0_be;
  wire  [7:0] i_L2Slice__toNextPipeline_0_be;
  logic [7:0] p_L2Slice__toNextPipeline_0_be;
  bit   t_L2Slice__toNextPipeline_0_be;
  wire  [9:0] g_L2Slice__toNextPipeline_0_addr;
  wire  [9:0] i_L2Slice__toNextPipeline_0_addr;
  logic [9:0] p_L2Slice__toNextPipeline_0_addr;
  bit   t_L2Slice__toNextPipeline_0_addr;
  wire  [103:0] g_L2Slice__toNextPipeline_0_indata;
  wire  [103:0] i_L2Slice__toNextPipeline_0_indata;
  logic [103:0] p_L2Slice__toNextPipeline_0_indata;
  bit   t_L2Slice__toNextPipeline_0_indata;
  wire  g_L2Slice__toNextPipeline_0_readen;
  wire  i_L2Slice__toNextPipeline_0_readen;
  logic p_L2Slice__toNextPipeline_0_readen;
  bit   t_L2Slice__toNextPipeline_0_readen;
  wire  [9:0] g_L2Slice__toNextPipeline_0_addr_rd;
  wire  [9:0] i_L2Slice__toNextPipeline_0_addr_rd;
  logic [9:0] p_L2Slice__toNextPipeline_0_addr_rd;
  bit   t_L2Slice__toNextPipeline_0_addr_rd;
  wire  [3:0] g_L2Slice__toNextPipeline_1_array;
  wire  [3:0] i_L2Slice__toNextPipeline_1_array;
  logic [3:0] p_L2Slice__toNextPipeline_1_array;
  bit   t_L2Slice__toNextPipeline_1_array;
  wire  g_L2Slice__toNextPipeline_1_all;
  wire  i_L2Slice__toNextPipeline_1_all;
  logic p_L2Slice__toNextPipeline_1_all;
  bit   t_L2Slice__toNextPipeline_1_all;
  wire  g_L2Slice__toNextPipeline_1_req;
  wire  i_L2Slice__toNextPipeline_1_req;
  logic p_L2Slice__toNextPipeline_1_req;
  bit   t_L2Slice__toNextPipeline_1_req;
  wire  g_L2Slice__toNextPipeline_1_writeen;
  wire  i_L2Slice__toNextPipeline_1_writeen;
  logic p_L2Slice__toNextPipeline_1_writeen;
  bit   t_L2Slice__toNextPipeline_1_writeen;
  wire  g_L2Slice__toNextPipeline_1_be;
  wire  i_L2Slice__toNextPipeline_1_be;
  logic p_L2Slice__toNextPipeline_1_be;
  bit   t_L2Slice__toNextPipeline_1_be;
  wire  [12:0] g_L2Slice__toNextPipeline_1_addr;
  wire  [12:0] i_L2Slice__toNextPipeline_1_addr;
  logic [12:0] p_L2Slice__toNextPipeline_1_addr;
  bit   t_L2Slice__toNextPipeline_1_addr;
  wire  [136:0] g_L2Slice__toNextPipeline_1_indata;
  wire  [136:0] i_L2Slice__toNextPipeline_1_indata;
  logic [136:0] p_L2Slice__toNextPipeline_1_indata;
  bit   t_L2Slice__toNextPipeline_1_indata;
  wire  g_L2Slice__toNextPipeline_1_readen;
  wire  i_L2Slice__toNextPipeline_1_readen;
  logic p_L2Slice__toNextPipeline_1_readen;
  bit   t_L2Slice__toNextPipeline_1_readen;
  wire  [12:0] g_L2Slice__toNextPipeline_1_addr_rd;
  wire  [12:0] i_L2Slice__toNextPipeline_1_addr_rd;
  logic [12:0] p_L2Slice__toNextPipeline_1_addr_rd;
  bit   t_L2Slice__toNextPipeline_1_addr_rd;
  L2Slice u_g_L2Slice (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice__mbist_array),
    .mbist_all (L2Slice__mbist_all),
    .mbist_req (L2Slice__mbist_req),
    .mbist_ack (g_L2Slice__mbist_ack),
    .mbist_writeen (L2Slice__mbist_writeen),
    .mbist_be (L2Slice__mbist_be),
    .mbist_addr (L2Slice__mbist_addr),
    .mbist_indata (L2Slice__mbist_indata),
    .mbist_readen (L2Slice__mbist_readen),
    .mbist_addr_rd (L2Slice__mbist_addr_rd),
    .mbist_outdata (g_L2Slice__mbist_outdata),
    .toNextPipeline_0_array (g_L2Slice__toNextPipeline_0_array),
    .toNextPipeline_0_all (g_L2Slice__toNextPipeline_0_all),
    .toNextPipeline_0_req (g_L2Slice__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (g_L2Slice__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g_L2Slice__toNextPipeline_0_be),
    .toNextPipeline_0_addr (g_L2Slice__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g_L2Slice__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g_L2Slice__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g_L2Slice__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (g_L2Slice__toNextPipeline_1_array),
    .toNextPipeline_1_all (g_L2Slice__toNextPipeline_1_all),
    .toNextPipeline_1_req (g_L2Slice__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (g_L2Slice__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g_L2Slice__toNextPipeline_1_be),
    .toNextPipeline_1_addr (g_L2Slice__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g_L2Slice__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g_L2Slice__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g_L2Slice__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice__toNextPipeline_1_outdata)
  );
  L2Slice_xs u_i_L2Slice (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice__mbist_array),
    .mbist_all (L2Slice__mbist_all),
    .mbist_req (L2Slice__mbist_req),
    .mbist_ack (i_L2Slice__mbist_ack),
    .mbist_writeen (L2Slice__mbist_writeen),
    .mbist_be (L2Slice__mbist_be),
    .mbist_addr (L2Slice__mbist_addr),
    .mbist_indata (L2Slice__mbist_indata),
    .mbist_readen (L2Slice__mbist_readen),
    .mbist_addr_rd (L2Slice__mbist_addr_rd),
    .mbist_outdata (i_L2Slice__mbist_outdata),
    .toNextPipeline_0_array (i_L2Slice__toNextPipeline_0_array),
    .toNextPipeline_0_all (i_L2Slice__toNextPipeline_0_all),
    .toNextPipeline_0_req (i_L2Slice__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (i_L2Slice__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (i_L2Slice__toNextPipeline_0_be),
    .toNextPipeline_0_addr (i_L2Slice__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (i_L2Slice__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (i_L2Slice__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (i_L2Slice__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (i_L2Slice__toNextPipeline_1_array),
    .toNextPipeline_1_all (i_L2Slice__toNextPipeline_1_all),
    .toNextPipeline_1_req (i_L2Slice__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (i_L2Slice__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (i_L2Slice__toNextPipeline_1_be),
    .toNextPipeline_1_addr (i_L2Slice__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (i_L2Slice__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (i_L2Slice__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (i_L2Slice__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice__toNextPipeline_1_outdata)
  );
  task automatic drive_L2Slice();
    L2Slice__mbist_array = rnd(4);
    L2Slice__mbist_all = $urandom % 2;
    L2Slice__mbist_req = $urandom % 2;
    L2Slice__mbist_writeen = $urandom % 2;
    L2Slice__mbist_be = rnd(8);
    L2Slice__mbist_addr = rnd(13);
    L2Slice__mbist_indata = rnd(137);
    L2Slice__mbist_readen = $urandom % 2;
    L2Slice__mbist_addr_rd = rnd(13);
    L2Slice__toNextPipeline_0_ack = $urandom % 2;
    L2Slice__toNextPipeline_0_outdata = rnd(104);
    L2Slice__toNextPipeline_1_ack = $urandom % 2;
    L2Slice__toNextPipeline_1_outdata = rnd(137);
  endtask
  task automatic check_L2Slice();
    checks++;
    if (g_L2Slice__mbist_ack !== i_L2Slice__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.mbist_ack g=%h i=%h", cyc, g_L2Slice__mbist_ack, i_L2Slice__mbist_ack);
    end
    if (g_L2Slice__mbist_ack !== p_L2Slice__mbist_ack) t_L2Slice__mbist_ack = 1'b1;
    p_L2Slice__mbist_ack = g_L2Slice__mbist_ack;
    checks++;
    if (g_L2Slice__mbist_outdata !== i_L2Slice__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.mbist_outdata g=%h i=%h", cyc, g_L2Slice__mbist_outdata, i_L2Slice__mbist_outdata);
    end
    if (g_L2Slice__mbist_outdata !== p_L2Slice__mbist_outdata) t_L2Slice__mbist_outdata = 1'b1;
    p_L2Slice__mbist_outdata = g_L2Slice__mbist_outdata;
    checks++;
    if (g_L2Slice__toNextPipeline_0_array !== i_L2Slice__toNextPipeline_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_array g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_array, i_L2Slice__toNextPipeline_0_array);
    end
    if (g_L2Slice__toNextPipeline_0_array !== p_L2Slice__toNextPipeline_0_array) t_L2Slice__toNextPipeline_0_array = 1'b1;
    p_L2Slice__toNextPipeline_0_array = g_L2Slice__toNextPipeline_0_array;
    checks++;
    if (g_L2Slice__toNextPipeline_0_all !== i_L2Slice__toNextPipeline_0_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_all g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_all, i_L2Slice__toNextPipeline_0_all);
    end
    if (g_L2Slice__toNextPipeline_0_all !== p_L2Slice__toNextPipeline_0_all) t_L2Slice__toNextPipeline_0_all = 1'b1;
    p_L2Slice__toNextPipeline_0_all = g_L2Slice__toNextPipeline_0_all;
    checks++;
    if (g_L2Slice__toNextPipeline_0_req !== i_L2Slice__toNextPipeline_0_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_req g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_req, i_L2Slice__toNextPipeline_0_req);
    end
    if (g_L2Slice__toNextPipeline_0_req !== p_L2Slice__toNextPipeline_0_req) t_L2Slice__toNextPipeline_0_req = 1'b1;
    p_L2Slice__toNextPipeline_0_req = g_L2Slice__toNextPipeline_0_req;
    checks++;
    if (g_L2Slice__toNextPipeline_0_writeen !== i_L2Slice__toNextPipeline_0_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_writeen g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_writeen, i_L2Slice__toNextPipeline_0_writeen);
    end
    if (g_L2Slice__toNextPipeline_0_writeen !== p_L2Slice__toNextPipeline_0_writeen) t_L2Slice__toNextPipeline_0_writeen = 1'b1;
    p_L2Slice__toNextPipeline_0_writeen = g_L2Slice__toNextPipeline_0_writeen;
    checks++;
    if (g_L2Slice__toNextPipeline_0_be !== i_L2Slice__toNextPipeline_0_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_be g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_be, i_L2Slice__toNextPipeline_0_be);
    end
    if (g_L2Slice__toNextPipeline_0_be !== p_L2Slice__toNextPipeline_0_be) t_L2Slice__toNextPipeline_0_be = 1'b1;
    p_L2Slice__toNextPipeline_0_be = g_L2Slice__toNextPipeline_0_be;
    checks++;
    if (g_L2Slice__toNextPipeline_0_addr !== i_L2Slice__toNextPipeline_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_addr g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_addr, i_L2Slice__toNextPipeline_0_addr);
    end
    if (g_L2Slice__toNextPipeline_0_addr !== p_L2Slice__toNextPipeline_0_addr) t_L2Slice__toNextPipeline_0_addr = 1'b1;
    p_L2Slice__toNextPipeline_0_addr = g_L2Slice__toNextPipeline_0_addr;
    checks++;
    if (g_L2Slice__toNextPipeline_0_indata !== i_L2Slice__toNextPipeline_0_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_indata g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_indata, i_L2Slice__toNextPipeline_0_indata);
    end
    if (g_L2Slice__toNextPipeline_0_indata !== p_L2Slice__toNextPipeline_0_indata) t_L2Slice__toNextPipeline_0_indata = 1'b1;
    p_L2Slice__toNextPipeline_0_indata = g_L2Slice__toNextPipeline_0_indata;
    checks++;
    if (g_L2Slice__toNextPipeline_0_readen !== i_L2Slice__toNextPipeline_0_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_readen g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_readen, i_L2Slice__toNextPipeline_0_readen);
    end
    if (g_L2Slice__toNextPipeline_0_readen !== p_L2Slice__toNextPipeline_0_readen) t_L2Slice__toNextPipeline_0_readen = 1'b1;
    p_L2Slice__toNextPipeline_0_readen = g_L2Slice__toNextPipeline_0_readen;
    checks++;
    if (g_L2Slice__toNextPipeline_0_addr_rd !== i_L2Slice__toNextPipeline_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_0_addr_rd g=%h i=%h", cyc, g_L2Slice__toNextPipeline_0_addr_rd, i_L2Slice__toNextPipeline_0_addr_rd);
    end
    if (g_L2Slice__toNextPipeline_0_addr_rd !== p_L2Slice__toNextPipeline_0_addr_rd) t_L2Slice__toNextPipeline_0_addr_rd = 1'b1;
    p_L2Slice__toNextPipeline_0_addr_rd = g_L2Slice__toNextPipeline_0_addr_rd;
    checks++;
    if (g_L2Slice__toNextPipeline_1_array !== i_L2Slice__toNextPipeline_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_array g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_array, i_L2Slice__toNextPipeline_1_array);
    end
    if (g_L2Slice__toNextPipeline_1_array !== p_L2Slice__toNextPipeline_1_array) t_L2Slice__toNextPipeline_1_array = 1'b1;
    p_L2Slice__toNextPipeline_1_array = g_L2Slice__toNextPipeline_1_array;
    checks++;
    if (g_L2Slice__toNextPipeline_1_all !== i_L2Slice__toNextPipeline_1_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_all g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_all, i_L2Slice__toNextPipeline_1_all);
    end
    if (g_L2Slice__toNextPipeline_1_all !== p_L2Slice__toNextPipeline_1_all) t_L2Slice__toNextPipeline_1_all = 1'b1;
    p_L2Slice__toNextPipeline_1_all = g_L2Slice__toNextPipeline_1_all;
    checks++;
    if (g_L2Slice__toNextPipeline_1_req !== i_L2Slice__toNextPipeline_1_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_req g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_req, i_L2Slice__toNextPipeline_1_req);
    end
    if (g_L2Slice__toNextPipeline_1_req !== p_L2Slice__toNextPipeline_1_req) t_L2Slice__toNextPipeline_1_req = 1'b1;
    p_L2Slice__toNextPipeline_1_req = g_L2Slice__toNextPipeline_1_req;
    checks++;
    if (g_L2Slice__toNextPipeline_1_writeen !== i_L2Slice__toNextPipeline_1_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_writeen g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_writeen, i_L2Slice__toNextPipeline_1_writeen);
    end
    if (g_L2Slice__toNextPipeline_1_writeen !== p_L2Slice__toNextPipeline_1_writeen) t_L2Slice__toNextPipeline_1_writeen = 1'b1;
    p_L2Slice__toNextPipeline_1_writeen = g_L2Slice__toNextPipeline_1_writeen;
    checks++;
    if (g_L2Slice__toNextPipeline_1_be !== i_L2Slice__toNextPipeline_1_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_be g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_be, i_L2Slice__toNextPipeline_1_be);
    end
    if (g_L2Slice__toNextPipeline_1_be !== p_L2Slice__toNextPipeline_1_be) t_L2Slice__toNextPipeline_1_be = 1'b1;
    p_L2Slice__toNextPipeline_1_be = g_L2Slice__toNextPipeline_1_be;
    checks++;
    if (g_L2Slice__toNextPipeline_1_addr !== i_L2Slice__toNextPipeline_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_addr g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_addr, i_L2Slice__toNextPipeline_1_addr);
    end
    if (g_L2Slice__toNextPipeline_1_addr !== p_L2Slice__toNextPipeline_1_addr) t_L2Slice__toNextPipeline_1_addr = 1'b1;
    p_L2Slice__toNextPipeline_1_addr = g_L2Slice__toNextPipeline_1_addr;
    checks++;
    if (g_L2Slice__toNextPipeline_1_indata !== i_L2Slice__toNextPipeline_1_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_indata g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_indata, i_L2Slice__toNextPipeline_1_indata);
    end
    if (g_L2Slice__toNextPipeline_1_indata !== p_L2Slice__toNextPipeline_1_indata) t_L2Slice__toNextPipeline_1_indata = 1'b1;
    p_L2Slice__toNextPipeline_1_indata = g_L2Slice__toNextPipeline_1_indata;
    checks++;
    if (g_L2Slice__toNextPipeline_1_readen !== i_L2Slice__toNextPipeline_1_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_readen g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_readen, i_L2Slice__toNextPipeline_1_readen);
    end
    if (g_L2Slice__toNextPipeline_1_readen !== p_L2Slice__toNextPipeline_1_readen) t_L2Slice__toNextPipeline_1_readen = 1'b1;
    p_L2Slice__toNextPipeline_1_readen = g_L2Slice__toNextPipeline_1_readen;
    checks++;
    if (g_L2Slice__toNextPipeline_1_addr_rd !== i_L2Slice__toNextPipeline_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice.toNextPipeline_1_addr_rd g=%h i=%h", cyc, g_L2Slice__toNextPipeline_1_addr_rd, i_L2Slice__toNextPipeline_1_addr_rd);
    end
    if (g_L2Slice__toNextPipeline_1_addr_rd !== p_L2Slice__toNextPipeline_1_addr_rd) t_L2Slice__toNextPipeline_1_addr_rd = 1'b1;
    p_L2Slice__toNextPipeline_1_addr_rd = g_L2Slice__toNextPipeline_1_addr_rd;
  endtask
  longint cov_L2Slice_sel0 = 0;
  longint cov_L2Slice_sel1 = 0;
  longint cov_L2Slice_act = 0;
  task automatic cover_L2Slice();
    if (u_g_L2Slice.selected) cov_L2Slice_sel0++;
    if (u_g_L2Slice.selected_1) cov_L2Slice_sel1++;
    if (u_g_L2Slice.activated) cov_L2Slice_act++;
  endtask
  task automatic sync_L2Slice();
    force u_i_L2Slice.u_core.g_node_return.pipelineDataOutReg = u_g_L2Slice.pipelineDataOutReg;
    #0 release u_i_L2Slice.u_core.g_node_return.pipelineDataOutReg;
  endtask

  // ======================= L2Slice_1 =======================
  logic [4:0] L2Slice_1__mbist_array;
  logic L2Slice_1__mbist_all;
  logic L2Slice_1__mbist_req;
  logic L2Slice_1__mbist_writeen;
  logic [7:0] L2Slice_1__mbist_be;
  logic [12:0] L2Slice_1__mbist_addr;
  logic [136:0] L2Slice_1__mbist_indata;
  logic L2Slice_1__mbist_readen;
  logic [12:0] L2Slice_1__mbist_addr_rd;
  logic L2Slice_1__toNextPipeline_0_ack;
  logic [103:0] L2Slice_1__toNextPipeline_0_outdata;
  logic L2Slice_1__toNextPipeline_1_ack;
  logic [136:0] L2Slice_1__toNextPipeline_1_outdata;
  wire  g_L2Slice_1__mbist_ack;
  wire  i_L2Slice_1__mbist_ack;
  logic p_L2Slice_1__mbist_ack;
  bit   t_L2Slice_1__mbist_ack;
  wire  [136:0] g_L2Slice_1__mbist_outdata;
  wire  [136:0] i_L2Slice_1__mbist_outdata;
  logic [136:0] p_L2Slice_1__mbist_outdata;
  bit   t_L2Slice_1__mbist_outdata;
  wire  [4:0] g_L2Slice_1__toNextPipeline_0_array;
  wire  [4:0] i_L2Slice_1__toNextPipeline_0_array;
  logic [4:0] p_L2Slice_1__toNextPipeline_0_array;
  bit   t_L2Slice_1__toNextPipeline_0_array;
  wire  g_L2Slice_1__toNextPipeline_0_all;
  wire  i_L2Slice_1__toNextPipeline_0_all;
  logic p_L2Slice_1__toNextPipeline_0_all;
  bit   t_L2Slice_1__toNextPipeline_0_all;
  wire  g_L2Slice_1__toNextPipeline_0_req;
  wire  i_L2Slice_1__toNextPipeline_0_req;
  logic p_L2Slice_1__toNextPipeline_0_req;
  bit   t_L2Slice_1__toNextPipeline_0_req;
  wire  g_L2Slice_1__toNextPipeline_0_writeen;
  wire  i_L2Slice_1__toNextPipeline_0_writeen;
  logic p_L2Slice_1__toNextPipeline_0_writeen;
  bit   t_L2Slice_1__toNextPipeline_0_writeen;
  wire  [7:0] g_L2Slice_1__toNextPipeline_0_be;
  wire  [7:0] i_L2Slice_1__toNextPipeline_0_be;
  logic [7:0] p_L2Slice_1__toNextPipeline_0_be;
  bit   t_L2Slice_1__toNextPipeline_0_be;
  wire  [9:0] g_L2Slice_1__toNextPipeline_0_addr;
  wire  [9:0] i_L2Slice_1__toNextPipeline_0_addr;
  logic [9:0] p_L2Slice_1__toNextPipeline_0_addr;
  bit   t_L2Slice_1__toNextPipeline_0_addr;
  wire  [103:0] g_L2Slice_1__toNextPipeline_0_indata;
  wire  [103:0] i_L2Slice_1__toNextPipeline_0_indata;
  logic [103:0] p_L2Slice_1__toNextPipeline_0_indata;
  bit   t_L2Slice_1__toNextPipeline_0_indata;
  wire  g_L2Slice_1__toNextPipeline_0_readen;
  wire  i_L2Slice_1__toNextPipeline_0_readen;
  logic p_L2Slice_1__toNextPipeline_0_readen;
  bit   t_L2Slice_1__toNextPipeline_0_readen;
  wire  [9:0] g_L2Slice_1__toNextPipeline_0_addr_rd;
  wire  [9:0] i_L2Slice_1__toNextPipeline_0_addr_rd;
  logic [9:0] p_L2Slice_1__toNextPipeline_0_addr_rd;
  bit   t_L2Slice_1__toNextPipeline_0_addr_rd;
  wire  [4:0] g_L2Slice_1__toNextPipeline_1_array;
  wire  [4:0] i_L2Slice_1__toNextPipeline_1_array;
  logic [4:0] p_L2Slice_1__toNextPipeline_1_array;
  bit   t_L2Slice_1__toNextPipeline_1_array;
  wire  g_L2Slice_1__toNextPipeline_1_all;
  wire  i_L2Slice_1__toNextPipeline_1_all;
  logic p_L2Slice_1__toNextPipeline_1_all;
  bit   t_L2Slice_1__toNextPipeline_1_all;
  wire  g_L2Slice_1__toNextPipeline_1_req;
  wire  i_L2Slice_1__toNextPipeline_1_req;
  logic p_L2Slice_1__toNextPipeline_1_req;
  bit   t_L2Slice_1__toNextPipeline_1_req;
  wire  g_L2Slice_1__toNextPipeline_1_writeen;
  wire  i_L2Slice_1__toNextPipeline_1_writeen;
  logic p_L2Slice_1__toNextPipeline_1_writeen;
  bit   t_L2Slice_1__toNextPipeline_1_writeen;
  wire  g_L2Slice_1__toNextPipeline_1_be;
  wire  i_L2Slice_1__toNextPipeline_1_be;
  logic p_L2Slice_1__toNextPipeline_1_be;
  bit   t_L2Slice_1__toNextPipeline_1_be;
  wire  [12:0] g_L2Slice_1__toNextPipeline_1_addr;
  wire  [12:0] i_L2Slice_1__toNextPipeline_1_addr;
  logic [12:0] p_L2Slice_1__toNextPipeline_1_addr;
  bit   t_L2Slice_1__toNextPipeline_1_addr;
  wire  [136:0] g_L2Slice_1__toNextPipeline_1_indata;
  wire  [136:0] i_L2Slice_1__toNextPipeline_1_indata;
  logic [136:0] p_L2Slice_1__toNextPipeline_1_indata;
  bit   t_L2Slice_1__toNextPipeline_1_indata;
  wire  g_L2Slice_1__toNextPipeline_1_readen;
  wire  i_L2Slice_1__toNextPipeline_1_readen;
  logic p_L2Slice_1__toNextPipeline_1_readen;
  bit   t_L2Slice_1__toNextPipeline_1_readen;
  wire  [12:0] g_L2Slice_1__toNextPipeline_1_addr_rd;
  wire  [12:0] i_L2Slice_1__toNextPipeline_1_addr_rd;
  logic [12:0] p_L2Slice_1__toNextPipeline_1_addr_rd;
  bit   t_L2Slice_1__toNextPipeline_1_addr_rd;
  L2Slice_1 u_g_L2Slice_1 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_1__mbist_array),
    .mbist_all (L2Slice_1__mbist_all),
    .mbist_req (L2Slice_1__mbist_req),
    .mbist_ack (g_L2Slice_1__mbist_ack),
    .mbist_writeen (L2Slice_1__mbist_writeen),
    .mbist_be (L2Slice_1__mbist_be),
    .mbist_addr (L2Slice_1__mbist_addr),
    .mbist_indata (L2Slice_1__mbist_indata),
    .mbist_readen (L2Slice_1__mbist_readen),
    .mbist_addr_rd (L2Slice_1__mbist_addr_rd),
    .mbist_outdata (g_L2Slice_1__mbist_outdata),
    .toNextPipeline_0_array (g_L2Slice_1__toNextPipeline_0_array),
    .toNextPipeline_0_all (g_L2Slice_1__toNextPipeline_0_all),
    .toNextPipeline_0_req (g_L2Slice_1__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_1__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (g_L2Slice_1__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g_L2Slice_1__toNextPipeline_0_be),
    .toNextPipeline_0_addr (g_L2Slice_1__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g_L2Slice_1__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g_L2Slice_1__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g_L2Slice_1__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_1__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (g_L2Slice_1__toNextPipeline_1_array),
    .toNextPipeline_1_all (g_L2Slice_1__toNextPipeline_1_all),
    .toNextPipeline_1_req (g_L2Slice_1__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_1__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (g_L2Slice_1__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g_L2Slice_1__toNextPipeline_1_be),
    .toNextPipeline_1_addr (g_L2Slice_1__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g_L2Slice_1__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g_L2Slice_1__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g_L2Slice_1__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_1__toNextPipeline_1_outdata)
  );
  L2Slice_1_xs u_i_L2Slice_1 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_1__mbist_array),
    .mbist_all (L2Slice_1__mbist_all),
    .mbist_req (L2Slice_1__mbist_req),
    .mbist_ack (i_L2Slice_1__mbist_ack),
    .mbist_writeen (L2Slice_1__mbist_writeen),
    .mbist_be (L2Slice_1__mbist_be),
    .mbist_addr (L2Slice_1__mbist_addr),
    .mbist_indata (L2Slice_1__mbist_indata),
    .mbist_readen (L2Slice_1__mbist_readen),
    .mbist_addr_rd (L2Slice_1__mbist_addr_rd),
    .mbist_outdata (i_L2Slice_1__mbist_outdata),
    .toNextPipeline_0_array (i_L2Slice_1__toNextPipeline_0_array),
    .toNextPipeline_0_all (i_L2Slice_1__toNextPipeline_0_all),
    .toNextPipeline_0_req (i_L2Slice_1__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_1__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (i_L2Slice_1__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (i_L2Slice_1__toNextPipeline_0_be),
    .toNextPipeline_0_addr (i_L2Slice_1__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (i_L2Slice_1__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (i_L2Slice_1__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (i_L2Slice_1__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_1__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (i_L2Slice_1__toNextPipeline_1_array),
    .toNextPipeline_1_all (i_L2Slice_1__toNextPipeline_1_all),
    .toNextPipeline_1_req (i_L2Slice_1__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_1__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (i_L2Slice_1__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (i_L2Slice_1__toNextPipeline_1_be),
    .toNextPipeline_1_addr (i_L2Slice_1__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (i_L2Slice_1__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (i_L2Slice_1__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (i_L2Slice_1__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_1__toNextPipeline_1_outdata)
  );
  task automatic drive_L2Slice_1();
    L2Slice_1__mbist_array = rnd(5);
    L2Slice_1__mbist_all = $urandom % 2;
    L2Slice_1__mbist_req = $urandom % 2;
    L2Slice_1__mbist_writeen = $urandom % 2;
    L2Slice_1__mbist_be = rnd(8);
    L2Slice_1__mbist_addr = rnd(13);
    L2Slice_1__mbist_indata = rnd(137);
    L2Slice_1__mbist_readen = $urandom % 2;
    L2Slice_1__mbist_addr_rd = rnd(13);
    L2Slice_1__toNextPipeline_0_ack = $urandom % 2;
    L2Slice_1__toNextPipeline_0_outdata = rnd(104);
    L2Slice_1__toNextPipeline_1_ack = $urandom % 2;
    L2Slice_1__toNextPipeline_1_outdata = rnd(137);
  endtask
  task automatic check_L2Slice_1();
    checks++;
    if (g_L2Slice_1__mbist_ack !== i_L2Slice_1__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.mbist_ack g=%h i=%h", cyc, g_L2Slice_1__mbist_ack, i_L2Slice_1__mbist_ack);
    end
    if (g_L2Slice_1__mbist_ack !== p_L2Slice_1__mbist_ack) t_L2Slice_1__mbist_ack = 1'b1;
    p_L2Slice_1__mbist_ack = g_L2Slice_1__mbist_ack;
    checks++;
    if (g_L2Slice_1__mbist_outdata !== i_L2Slice_1__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.mbist_outdata g=%h i=%h", cyc, g_L2Slice_1__mbist_outdata, i_L2Slice_1__mbist_outdata);
    end
    if (g_L2Slice_1__mbist_outdata !== p_L2Slice_1__mbist_outdata) t_L2Slice_1__mbist_outdata = 1'b1;
    p_L2Slice_1__mbist_outdata = g_L2Slice_1__mbist_outdata;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_array !== i_L2Slice_1__toNextPipeline_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_array g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_array, i_L2Slice_1__toNextPipeline_0_array);
    end
    if (g_L2Slice_1__toNextPipeline_0_array !== p_L2Slice_1__toNextPipeline_0_array) t_L2Slice_1__toNextPipeline_0_array = 1'b1;
    p_L2Slice_1__toNextPipeline_0_array = g_L2Slice_1__toNextPipeline_0_array;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_all !== i_L2Slice_1__toNextPipeline_0_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_all g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_all, i_L2Slice_1__toNextPipeline_0_all);
    end
    if (g_L2Slice_1__toNextPipeline_0_all !== p_L2Slice_1__toNextPipeline_0_all) t_L2Slice_1__toNextPipeline_0_all = 1'b1;
    p_L2Slice_1__toNextPipeline_0_all = g_L2Slice_1__toNextPipeline_0_all;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_req !== i_L2Slice_1__toNextPipeline_0_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_req g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_req, i_L2Slice_1__toNextPipeline_0_req);
    end
    if (g_L2Slice_1__toNextPipeline_0_req !== p_L2Slice_1__toNextPipeline_0_req) t_L2Slice_1__toNextPipeline_0_req = 1'b1;
    p_L2Slice_1__toNextPipeline_0_req = g_L2Slice_1__toNextPipeline_0_req;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_writeen !== i_L2Slice_1__toNextPipeline_0_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_writeen g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_writeen, i_L2Slice_1__toNextPipeline_0_writeen);
    end
    if (g_L2Slice_1__toNextPipeline_0_writeen !== p_L2Slice_1__toNextPipeline_0_writeen) t_L2Slice_1__toNextPipeline_0_writeen = 1'b1;
    p_L2Slice_1__toNextPipeline_0_writeen = g_L2Slice_1__toNextPipeline_0_writeen;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_be !== i_L2Slice_1__toNextPipeline_0_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_be g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_be, i_L2Slice_1__toNextPipeline_0_be);
    end
    if (g_L2Slice_1__toNextPipeline_0_be !== p_L2Slice_1__toNextPipeline_0_be) t_L2Slice_1__toNextPipeline_0_be = 1'b1;
    p_L2Slice_1__toNextPipeline_0_be = g_L2Slice_1__toNextPipeline_0_be;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_addr !== i_L2Slice_1__toNextPipeline_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_addr g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_addr, i_L2Slice_1__toNextPipeline_0_addr);
    end
    if (g_L2Slice_1__toNextPipeline_0_addr !== p_L2Slice_1__toNextPipeline_0_addr) t_L2Slice_1__toNextPipeline_0_addr = 1'b1;
    p_L2Slice_1__toNextPipeline_0_addr = g_L2Slice_1__toNextPipeline_0_addr;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_indata !== i_L2Slice_1__toNextPipeline_0_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_indata g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_indata, i_L2Slice_1__toNextPipeline_0_indata);
    end
    if (g_L2Slice_1__toNextPipeline_0_indata !== p_L2Slice_1__toNextPipeline_0_indata) t_L2Slice_1__toNextPipeline_0_indata = 1'b1;
    p_L2Slice_1__toNextPipeline_0_indata = g_L2Slice_1__toNextPipeline_0_indata;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_readen !== i_L2Slice_1__toNextPipeline_0_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_readen g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_readen, i_L2Slice_1__toNextPipeline_0_readen);
    end
    if (g_L2Slice_1__toNextPipeline_0_readen !== p_L2Slice_1__toNextPipeline_0_readen) t_L2Slice_1__toNextPipeline_0_readen = 1'b1;
    p_L2Slice_1__toNextPipeline_0_readen = g_L2Slice_1__toNextPipeline_0_readen;
    checks++;
    if (g_L2Slice_1__toNextPipeline_0_addr_rd !== i_L2Slice_1__toNextPipeline_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_0_addr_rd g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_0_addr_rd, i_L2Slice_1__toNextPipeline_0_addr_rd);
    end
    if (g_L2Slice_1__toNextPipeline_0_addr_rd !== p_L2Slice_1__toNextPipeline_0_addr_rd) t_L2Slice_1__toNextPipeline_0_addr_rd = 1'b1;
    p_L2Slice_1__toNextPipeline_0_addr_rd = g_L2Slice_1__toNextPipeline_0_addr_rd;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_array !== i_L2Slice_1__toNextPipeline_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_array g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_array, i_L2Slice_1__toNextPipeline_1_array);
    end
    if (g_L2Slice_1__toNextPipeline_1_array !== p_L2Slice_1__toNextPipeline_1_array) t_L2Slice_1__toNextPipeline_1_array = 1'b1;
    p_L2Slice_1__toNextPipeline_1_array = g_L2Slice_1__toNextPipeline_1_array;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_all !== i_L2Slice_1__toNextPipeline_1_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_all g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_all, i_L2Slice_1__toNextPipeline_1_all);
    end
    if (g_L2Slice_1__toNextPipeline_1_all !== p_L2Slice_1__toNextPipeline_1_all) t_L2Slice_1__toNextPipeline_1_all = 1'b1;
    p_L2Slice_1__toNextPipeline_1_all = g_L2Slice_1__toNextPipeline_1_all;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_req !== i_L2Slice_1__toNextPipeline_1_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_req g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_req, i_L2Slice_1__toNextPipeline_1_req);
    end
    if (g_L2Slice_1__toNextPipeline_1_req !== p_L2Slice_1__toNextPipeline_1_req) t_L2Slice_1__toNextPipeline_1_req = 1'b1;
    p_L2Slice_1__toNextPipeline_1_req = g_L2Slice_1__toNextPipeline_1_req;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_writeen !== i_L2Slice_1__toNextPipeline_1_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_writeen g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_writeen, i_L2Slice_1__toNextPipeline_1_writeen);
    end
    if (g_L2Slice_1__toNextPipeline_1_writeen !== p_L2Slice_1__toNextPipeline_1_writeen) t_L2Slice_1__toNextPipeline_1_writeen = 1'b1;
    p_L2Slice_1__toNextPipeline_1_writeen = g_L2Slice_1__toNextPipeline_1_writeen;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_be !== i_L2Slice_1__toNextPipeline_1_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_be g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_be, i_L2Slice_1__toNextPipeline_1_be);
    end
    if (g_L2Slice_1__toNextPipeline_1_be !== p_L2Slice_1__toNextPipeline_1_be) t_L2Slice_1__toNextPipeline_1_be = 1'b1;
    p_L2Slice_1__toNextPipeline_1_be = g_L2Slice_1__toNextPipeline_1_be;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_addr !== i_L2Slice_1__toNextPipeline_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_addr g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_addr, i_L2Slice_1__toNextPipeline_1_addr);
    end
    if (g_L2Slice_1__toNextPipeline_1_addr !== p_L2Slice_1__toNextPipeline_1_addr) t_L2Slice_1__toNextPipeline_1_addr = 1'b1;
    p_L2Slice_1__toNextPipeline_1_addr = g_L2Slice_1__toNextPipeline_1_addr;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_indata !== i_L2Slice_1__toNextPipeline_1_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_indata g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_indata, i_L2Slice_1__toNextPipeline_1_indata);
    end
    if (g_L2Slice_1__toNextPipeline_1_indata !== p_L2Slice_1__toNextPipeline_1_indata) t_L2Slice_1__toNextPipeline_1_indata = 1'b1;
    p_L2Slice_1__toNextPipeline_1_indata = g_L2Slice_1__toNextPipeline_1_indata;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_readen !== i_L2Slice_1__toNextPipeline_1_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_readen g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_readen, i_L2Slice_1__toNextPipeline_1_readen);
    end
    if (g_L2Slice_1__toNextPipeline_1_readen !== p_L2Slice_1__toNextPipeline_1_readen) t_L2Slice_1__toNextPipeline_1_readen = 1'b1;
    p_L2Slice_1__toNextPipeline_1_readen = g_L2Slice_1__toNextPipeline_1_readen;
    checks++;
    if (g_L2Slice_1__toNextPipeline_1_addr_rd !== i_L2Slice_1__toNextPipeline_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_1.toNextPipeline_1_addr_rd g=%h i=%h", cyc, g_L2Slice_1__toNextPipeline_1_addr_rd, i_L2Slice_1__toNextPipeline_1_addr_rd);
    end
    if (g_L2Slice_1__toNextPipeline_1_addr_rd !== p_L2Slice_1__toNextPipeline_1_addr_rd) t_L2Slice_1__toNextPipeline_1_addr_rd = 1'b1;
    p_L2Slice_1__toNextPipeline_1_addr_rd = g_L2Slice_1__toNextPipeline_1_addr_rd;
  endtask
  longint cov_L2Slice_1_sel0 = 0;
  longint cov_L2Slice_1_sel1 = 0;
  longint cov_L2Slice_1_act = 0;
  task automatic cover_L2Slice_1();
    if (u_g_L2Slice_1.selected) cov_L2Slice_1_sel0++;
    if (u_g_L2Slice_1.selected_1) cov_L2Slice_1_sel1++;
    if (u_g_L2Slice_1.activated) cov_L2Slice_1_act++;
  endtask
  task automatic sync_L2Slice_1();
    force u_i_L2Slice_1.u_core.g_node_return.pipelineDataOutReg = u_g_L2Slice_1.pipelineDataOutReg;
    #0 release u_i_L2Slice_1.u_core.g_node_return.pipelineDataOutReg;
  endtask

  // ======================= L2Slice_2 =======================
  logic [5:0] L2Slice_2__mbist_array;
  logic L2Slice_2__mbist_all;
  logic L2Slice_2__mbist_req;
  logic L2Slice_2__mbist_writeen;
  logic [7:0] L2Slice_2__mbist_be;
  logic [12:0] L2Slice_2__mbist_addr;
  logic [136:0] L2Slice_2__mbist_indata;
  logic L2Slice_2__mbist_readen;
  logic [12:0] L2Slice_2__mbist_addr_rd;
  logic L2Slice_2__toNextPipeline_0_ack;
  logic [103:0] L2Slice_2__toNextPipeline_0_outdata;
  logic L2Slice_2__toNextPipeline_1_ack;
  logic [136:0] L2Slice_2__toNextPipeline_1_outdata;
  wire  g_L2Slice_2__mbist_ack;
  wire  i_L2Slice_2__mbist_ack;
  logic p_L2Slice_2__mbist_ack;
  bit   t_L2Slice_2__mbist_ack;
  wire  [136:0] g_L2Slice_2__mbist_outdata;
  wire  [136:0] i_L2Slice_2__mbist_outdata;
  logic [136:0] p_L2Slice_2__mbist_outdata;
  bit   t_L2Slice_2__mbist_outdata;
  wire  [4:0] g_L2Slice_2__toNextPipeline_0_array;
  wire  [4:0] i_L2Slice_2__toNextPipeline_0_array;
  logic [4:0] p_L2Slice_2__toNextPipeline_0_array;
  bit   t_L2Slice_2__toNextPipeline_0_array;
  wire  g_L2Slice_2__toNextPipeline_0_all;
  wire  i_L2Slice_2__toNextPipeline_0_all;
  logic p_L2Slice_2__toNextPipeline_0_all;
  bit   t_L2Slice_2__toNextPipeline_0_all;
  wire  g_L2Slice_2__toNextPipeline_0_req;
  wire  i_L2Slice_2__toNextPipeline_0_req;
  logic p_L2Slice_2__toNextPipeline_0_req;
  bit   t_L2Slice_2__toNextPipeline_0_req;
  wire  g_L2Slice_2__toNextPipeline_0_writeen;
  wire  i_L2Slice_2__toNextPipeline_0_writeen;
  logic p_L2Slice_2__toNextPipeline_0_writeen;
  bit   t_L2Slice_2__toNextPipeline_0_writeen;
  wire  [7:0] g_L2Slice_2__toNextPipeline_0_be;
  wire  [7:0] i_L2Slice_2__toNextPipeline_0_be;
  logic [7:0] p_L2Slice_2__toNextPipeline_0_be;
  bit   t_L2Slice_2__toNextPipeline_0_be;
  wire  [9:0] g_L2Slice_2__toNextPipeline_0_addr;
  wire  [9:0] i_L2Slice_2__toNextPipeline_0_addr;
  logic [9:0] p_L2Slice_2__toNextPipeline_0_addr;
  bit   t_L2Slice_2__toNextPipeline_0_addr;
  wire  [103:0] g_L2Slice_2__toNextPipeline_0_indata;
  wire  [103:0] i_L2Slice_2__toNextPipeline_0_indata;
  logic [103:0] p_L2Slice_2__toNextPipeline_0_indata;
  bit   t_L2Slice_2__toNextPipeline_0_indata;
  wire  g_L2Slice_2__toNextPipeline_0_readen;
  wire  i_L2Slice_2__toNextPipeline_0_readen;
  logic p_L2Slice_2__toNextPipeline_0_readen;
  bit   t_L2Slice_2__toNextPipeline_0_readen;
  wire  [9:0] g_L2Slice_2__toNextPipeline_0_addr_rd;
  wire  [9:0] i_L2Slice_2__toNextPipeline_0_addr_rd;
  logic [9:0] p_L2Slice_2__toNextPipeline_0_addr_rd;
  bit   t_L2Slice_2__toNextPipeline_0_addr_rd;
  wire  [5:0] g_L2Slice_2__toNextPipeline_1_array;
  wire  [5:0] i_L2Slice_2__toNextPipeline_1_array;
  logic [5:0] p_L2Slice_2__toNextPipeline_1_array;
  bit   t_L2Slice_2__toNextPipeline_1_array;
  wire  g_L2Slice_2__toNextPipeline_1_all;
  wire  i_L2Slice_2__toNextPipeline_1_all;
  logic p_L2Slice_2__toNextPipeline_1_all;
  bit   t_L2Slice_2__toNextPipeline_1_all;
  wire  g_L2Slice_2__toNextPipeline_1_req;
  wire  i_L2Slice_2__toNextPipeline_1_req;
  logic p_L2Slice_2__toNextPipeline_1_req;
  bit   t_L2Slice_2__toNextPipeline_1_req;
  wire  g_L2Slice_2__toNextPipeline_1_writeen;
  wire  i_L2Slice_2__toNextPipeline_1_writeen;
  logic p_L2Slice_2__toNextPipeline_1_writeen;
  bit   t_L2Slice_2__toNextPipeline_1_writeen;
  wire  g_L2Slice_2__toNextPipeline_1_be;
  wire  i_L2Slice_2__toNextPipeline_1_be;
  logic p_L2Slice_2__toNextPipeline_1_be;
  bit   t_L2Slice_2__toNextPipeline_1_be;
  wire  [12:0] g_L2Slice_2__toNextPipeline_1_addr;
  wire  [12:0] i_L2Slice_2__toNextPipeline_1_addr;
  logic [12:0] p_L2Slice_2__toNextPipeline_1_addr;
  bit   t_L2Slice_2__toNextPipeline_1_addr;
  wire  [136:0] g_L2Slice_2__toNextPipeline_1_indata;
  wire  [136:0] i_L2Slice_2__toNextPipeline_1_indata;
  logic [136:0] p_L2Slice_2__toNextPipeline_1_indata;
  bit   t_L2Slice_2__toNextPipeline_1_indata;
  wire  g_L2Slice_2__toNextPipeline_1_readen;
  wire  i_L2Slice_2__toNextPipeline_1_readen;
  logic p_L2Slice_2__toNextPipeline_1_readen;
  bit   t_L2Slice_2__toNextPipeline_1_readen;
  wire  [12:0] g_L2Slice_2__toNextPipeline_1_addr_rd;
  wire  [12:0] i_L2Slice_2__toNextPipeline_1_addr_rd;
  logic [12:0] p_L2Slice_2__toNextPipeline_1_addr_rd;
  bit   t_L2Slice_2__toNextPipeline_1_addr_rd;
  L2Slice_2 u_g_L2Slice_2 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_2__mbist_array),
    .mbist_all (L2Slice_2__mbist_all),
    .mbist_req (L2Slice_2__mbist_req),
    .mbist_ack (g_L2Slice_2__mbist_ack),
    .mbist_writeen (L2Slice_2__mbist_writeen),
    .mbist_be (L2Slice_2__mbist_be),
    .mbist_addr (L2Slice_2__mbist_addr),
    .mbist_indata (L2Slice_2__mbist_indata),
    .mbist_readen (L2Slice_2__mbist_readen),
    .mbist_addr_rd (L2Slice_2__mbist_addr_rd),
    .mbist_outdata (g_L2Slice_2__mbist_outdata),
    .toNextPipeline_0_array (g_L2Slice_2__toNextPipeline_0_array),
    .toNextPipeline_0_all (g_L2Slice_2__toNextPipeline_0_all),
    .toNextPipeline_0_req (g_L2Slice_2__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_2__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (g_L2Slice_2__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g_L2Slice_2__toNextPipeline_0_be),
    .toNextPipeline_0_addr (g_L2Slice_2__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g_L2Slice_2__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g_L2Slice_2__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g_L2Slice_2__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_2__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (g_L2Slice_2__toNextPipeline_1_array),
    .toNextPipeline_1_all (g_L2Slice_2__toNextPipeline_1_all),
    .toNextPipeline_1_req (g_L2Slice_2__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_2__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (g_L2Slice_2__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g_L2Slice_2__toNextPipeline_1_be),
    .toNextPipeline_1_addr (g_L2Slice_2__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g_L2Slice_2__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g_L2Slice_2__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g_L2Slice_2__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_2__toNextPipeline_1_outdata)
  );
  L2Slice_2_xs u_i_L2Slice_2 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_2__mbist_array),
    .mbist_all (L2Slice_2__mbist_all),
    .mbist_req (L2Slice_2__mbist_req),
    .mbist_ack (i_L2Slice_2__mbist_ack),
    .mbist_writeen (L2Slice_2__mbist_writeen),
    .mbist_be (L2Slice_2__mbist_be),
    .mbist_addr (L2Slice_2__mbist_addr),
    .mbist_indata (L2Slice_2__mbist_indata),
    .mbist_readen (L2Slice_2__mbist_readen),
    .mbist_addr_rd (L2Slice_2__mbist_addr_rd),
    .mbist_outdata (i_L2Slice_2__mbist_outdata),
    .toNextPipeline_0_array (i_L2Slice_2__toNextPipeline_0_array),
    .toNextPipeline_0_all (i_L2Slice_2__toNextPipeline_0_all),
    .toNextPipeline_0_req (i_L2Slice_2__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_2__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (i_L2Slice_2__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (i_L2Slice_2__toNextPipeline_0_be),
    .toNextPipeline_0_addr (i_L2Slice_2__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (i_L2Slice_2__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (i_L2Slice_2__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (i_L2Slice_2__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_2__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (i_L2Slice_2__toNextPipeline_1_array),
    .toNextPipeline_1_all (i_L2Slice_2__toNextPipeline_1_all),
    .toNextPipeline_1_req (i_L2Slice_2__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_2__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (i_L2Slice_2__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (i_L2Slice_2__toNextPipeline_1_be),
    .toNextPipeline_1_addr (i_L2Slice_2__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (i_L2Slice_2__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (i_L2Slice_2__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (i_L2Slice_2__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_2__toNextPipeline_1_outdata)
  );
  task automatic drive_L2Slice_2();
    L2Slice_2__mbist_array = rnd(6);
    L2Slice_2__mbist_all = $urandom % 2;
    L2Slice_2__mbist_req = $urandom % 2;
    L2Slice_2__mbist_writeen = $urandom % 2;
    L2Slice_2__mbist_be = rnd(8);
    L2Slice_2__mbist_addr = rnd(13);
    L2Slice_2__mbist_indata = rnd(137);
    L2Slice_2__mbist_readen = $urandom % 2;
    L2Slice_2__mbist_addr_rd = rnd(13);
    L2Slice_2__toNextPipeline_0_ack = $urandom % 2;
    L2Slice_2__toNextPipeline_0_outdata = rnd(104);
    L2Slice_2__toNextPipeline_1_ack = $urandom % 2;
    L2Slice_2__toNextPipeline_1_outdata = rnd(137);
  endtask
  task automatic check_L2Slice_2();
    checks++;
    if (g_L2Slice_2__mbist_ack !== i_L2Slice_2__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.mbist_ack g=%h i=%h", cyc, g_L2Slice_2__mbist_ack, i_L2Slice_2__mbist_ack);
    end
    if (g_L2Slice_2__mbist_ack !== p_L2Slice_2__mbist_ack) t_L2Slice_2__mbist_ack = 1'b1;
    p_L2Slice_2__mbist_ack = g_L2Slice_2__mbist_ack;
    checks++;
    if (g_L2Slice_2__mbist_outdata !== i_L2Slice_2__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.mbist_outdata g=%h i=%h", cyc, g_L2Slice_2__mbist_outdata, i_L2Slice_2__mbist_outdata);
    end
    if (g_L2Slice_2__mbist_outdata !== p_L2Slice_2__mbist_outdata) t_L2Slice_2__mbist_outdata = 1'b1;
    p_L2Slice_2__mbist_outdata = g_L2Slice_2__mbist_outdata;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_array !== i_L2Slice_2__toNextPipeline_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_array g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_array, i_L2Slice_2__toNextPipeline_0_array);
    end
    if (g_L2Slice_2__toNextPipeline_0_array !== p_L2Slice_2__toNextPipeline_0_array) t_L2Slice_2__toNextPipeline_0_array = 1'b1;
    p_L2Slice_2__toNextPipeline_0_array = g_L2Slice_2__toNextPipeline_0_array;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_all !== i_L2Slice_2__toNextPipeline_0_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_all g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_all, i_L2Slice_2__toNextPipeline_0_all);
    end
    if (g_L2Slice_2__toNextPipeline_0_all !== p_L2Slice_2__toNextPipeline_0_all) t_L2Slice_2__toNextPipeline_0_all = 1'b1;
    p_L2Slice_2__toNextPipeline_0_all = g_L2Slice_2__toNextPipeline_0_all;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_req !== i_L2Slice_2__toNextPipeline_0_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_req g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_req, i_L2Slice_2__toNextPipeline_0_req);
    end
    if (g_L2Slice_2__toNextPipeline_0_req !== p_L2Slice_2__toNextPipeline_0_req) t_L2Slice_2__toNextPipeline_0_req = 1'b1;
    p_L2Slice_2__toNextPipeline_0_req = g_L2Slice_2__toNextPipeline_0_req;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_writeen !== i_L2Slice_2__toNextPipeline_0_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_writeen g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_writeen, i_L2Slice_2__toNextPipeline_0_writeen);
    end
    if (g_L2Slice_2__toNextPipeline_0_writeen !== p_L2Slice_2__toNextPipeline_0_writeen) t_L2Slice_2__toNextPipeline_0_writeen = 1'b1;
    p_L2Slice_2__toNextPipeline_0_writeen = g_L2Slice_2__toNextPipeline_0_writeen;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_be !== i_L2Slice_2__toNextPipeline_0_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_be g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_be, i_L2Slice_2__toNextPipeline_0_be);
    end
    if (g_L2Slice_2__toNextPipeline_0_be !== p_L2Slice_2__toNextPipeline_0_be) t_L2Slice_2__toNextPipeline_0_be = 1'b1;
    p_L2Slice_2__toNextPipeline_0_be = g_L2Slice_2__toNextPipeline_0_be;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_addr !== i_L2Slice_2__toNextPipeline_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_addr g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_addr, i_L2Slice_2__toNextPipeline_0_addr);
    end
    if (g_L2Slice_2__toNextPipeline_0_addr !== p_L2Slice_2__toNextPipeline_0_addr) t_L2Slice_2__toNextPipeline_0_addr = 1'b1;
    p_L2Slice_2__toNextPipeline_0_addr = g_L2Slice_2__toNextPipeline_0_addr;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_indata !== i_L2Slice_2__toNextPipeline_0_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_indata g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_indata, i_L2Slice_2__toNextPipeline_0_indata);
    end
    if (g_L2Slice_2__toNextPipeline_0_indata !== p_L2Slice_2__toNextPipeline_0_indata) t_L2Slice_2__toNextPipeline_0_indata = 1'b1;
    p_L2Slice_2__toNextPipeline_0_indata = g_L2Slice_2__toNextPipeline_0_indata;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_readen !== i_L2Slice_2__toNextPipeline_0_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_readen g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_readen, i_L2Slice_2__toNextPipeline_0_readen);
    end
    if (g_L2Slice_2__toNextPipeline_0_readen !== p_L2Slice_2__toNextPipeline_0_readen) t_L2Slice_2__toNextPipeline_0_readen = 1'b1;
    p_L2Slice_2__toNextPipeline_0_readen = g_L2Slice_2__toNextPipeline_0_readen;
    checks++;
    if (g_L2Slice_2__toNextPipeline_0_addr_rd !== i_L2Slice_2__toNextPipeline_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_0_addr_rd g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_0_addr_rd, i_L2Slice_2__toNextPipeline_0_addr_rd);
    end
    if (g_L2Slice_2__toNextPipeline_0_addr_rd !== p_L2Slice_2__toNextPipeline_0_addr_rd) t_L2Slice_2__toNextPipeline_0_addr_rd = 1'b1;
    p_L2Slice_2__toNextPipeline_0_addr_rd = g_L2Slice_2__toNextPipeline_0_addr_rd;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_array !== i_L2Slice_2__toNextPipeline_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_array g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_array, i_L2Slice_2__toNextPipeline_1_array);
    end
    if (g_L2Slice_2__toNextPipeline_1_array !== p_L2Slice_2__toNextPipeline_1_array) t_L2Slice_2__toNextPipeline_1_array = 1'b1;
    p_L2Slice_2__toNextPipeline_1_array = g_L2Slice_2__toNextPipeline_1_array;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_all !== i_L2Slice_2__toNextPipeline_1_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_all g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_all, i_L2Slice_2__toNextPipeline_1_all);
    end
    if (g_L2Slice_2__toNextPipeline_1_all !== p_L2Slice_2__toNextPipeline_1_all) t_L2Slice_2__toNextPipeline_1_all = 1'b1;
    p_L2Slice_2__toNextPipeline_1_all = g_L2Slice_2__toNextPipeline_1_all;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_req !== i_L2Slice_2__toNextPipeline_1_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_req g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_req, i_L2Slice_2__toNextPipeline_1_req);
    end
    if (g_L2Slice_2__toNextPipeline_1_req !== p_L2Slice_2__toNextPipeline_1_req) t_L2Slice_2__toNextPipeline_1_req = 1'b1;
    p_L2Slice_2__toNextPipeline_1_req = g_L2Slice_2__toNextPipeline_1_req;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_writeen !== i_L2Slice_2__toNextPipeline_1_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_writeen g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_writeen, i_L2Slice_2__toNextPipeline_1_writeen);
    end
    if (g_L2Slice_2__toNextPipeline_1_writeen !== p_L2Slice_2__toNextPipeline_1_writeen) t_L2Slice_2__toNextPipeline_1_writeen = 1'b1;
    p_L2Slice_2__toNextPipeline_1_writeen = g_L2Slice_2__toNextPipeline_1_writeen;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_be !== i_L2Slice_2__toNextPipeline_1_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_be g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_be, i_L2Slice_2__toNextPipeline_1_be);
    end
    if (g_L2Slice_2__toNextPipeline_1_be !== p_L2Slice_2__toNextPipeline_1_be) t_L2Slice_2__toNextPipeline_1_be = 1'b1;
    p_L2Slice_2__toNextPipeline_1_be = g_L2Slice_2__toNextPipeline_1_be;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_addr !== i_L2Slice_2__toNextPipeline_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_addr g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_addr, i_L2Slice_2__toNextPipeline_1_addr);
    end
    if (g_L2Slice_2__toNextPipeline_1_addr !== p_L2Slice_2__toNextPipeline_1_addr) t_L2Slice_2__toNextPipeline_1_addr = 1'b1;
    p_L2Slice_2__toNextPipeline_1_addr = g_L2Slice_2__toNextPipeline_1_addr;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_indata !== i_L2Slice_2__toNextPipeline_1_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_indata g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_indata, i_L2Slice_2__toNextPipeline_1_indata);
    end
    if (g_L2Slice_2__toNextPipeline_1_indata !== p_L2Slice_2__toNextPipeline_1_indata) t_L2Slice_2__toNextPipeline_1_indata = 1'b1;
    p_L2Slice_2__toNextPipeline_1_indata = g_L2Slice_2__toNextPipeline_1_indata;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_readen !== i_L2Slice_2__toNextPipeline_1_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_readen g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_readen, i_L2Slice_2__toNextPipeline_1_readen);
    end
    if (g_L2Slice_2__toNextPipeline_1_readen !== p_L2Slice_2__toNextPipeline_1_readen) t_L2Slice_2__toNextPipeline_1_readen = 1'b1;
    p_L2Slice_2__toNextPipeline_1_readen = g_L2Slice_2__toNextPipeline_1_readen;
    checks++;
    if (g_L2Slice_2__toNextPipeline_1_addr_rd !== i_L2Slice_2__toNextPipeline_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_2.toNextPipeline_1_addr_rd g=%h i=%h", cyc, g_L2Slice_2__toNextPipeline_1_addr_rd, i_L2Slice_2__toNextPipeline_1_addr_rd);
    end
    if (g_L2Slice_2__toNextPipeline_1_addr_rd !== p_L2Slice_2__toNextPipeline_1_addr_rd) t_L2Slice_2__toNextPipeline_1_addr_rd = 1'b1;
    p_L2Slice_2__toNextPipeline_1_addr_rd = g_L2Slice_2__toNextPipeline_1_addr_rd;
  endtask
  longint cov_L2Slice_2_sel0 = 0;
  longint cov_L2Slice_2_sel1 = 0;
  longint cov_L2Slice_2_act = 0;
  task automatic cover_L2Slice_2();
    if (u_g_L2Slice_2.selected) cov_L2Slice_2_sel0++;
    if (u_g_L2Slice_2.selected_1) cov_L2Slice_2_sel1++;
    if (u_g_L2Slice_2.activated) cov_L2Slice_2_act++;
  endtask
  task automatic sync_L2Slice_2();
    force u_i_L2Slice_2.u_core.g_node_return.pipelineDataOutReg = u_g_L2Slice_2.pipelineDataOutReg;
    #0 release u_i_L2Slice_2.u_core.g_node_return.pipelineDataOutReg;
  endtask

  // ======================= L2Slice_3 =======================
  logic [5:0] L2Slice_3__mbist_array;
  logic L2Slice_3__mbist_all;
  logic L2Slice_3__mbist_req;
  logic L2Slice_3__mbist_writeen;
  logic [7:0] L2Slice_3__mbist_be;
  logic [12:0] L2Slice_3__mbist_addr;
  logic [136:0] L2Slice_3__mbist_indata;
  logic L2Slice_3__mbist_readen;
  logic [12:0] L2Slice_3__mbist_addr_rd;
  logic L2Slice_3__toNextPipeline_0_ack;
  logic [103:0] L2Slice_3__toNextPipeline_0_outdata;
  logic L2Slice_3__toNextPipeline_1_ack;
  logic [136:0] L2Slice_3__toNextPipeline_1_outdata;
  wire  g_L2Slice_3__mbist_ack;
  wire  i_L2Slice_3__mbist_ack;
  logic p_L2Slice_3__mbist_ack;
  bit   t_L2Slice_3__mbist_ack;
  wire  [136:0] g_L2Slice_3__mbist_outdata;
  wire  [136:0] i_L2Slice_3__mbist_outdata;
  logic [136:0] p_L2Slice_3__mbist_outdata;
  bit   t_L2Slice_3__mbist_outdata;
  wire  [5:0] g_L2Slice_3__toNextPipeline_0_array;
  wire  [5:0] i_L2Slice_3__toNextPipeline_0_array;
  logic [5:0] p_L2Slice_3__toNextPipeline_0_array;
  bit   t_L2Slice_3__toNextPipeline_0_array;
  wire  g_L2Slice_3__toNextPipeline_0_all;
  wire  i_L2Slice_3__toNextPipeline_0_all;
  logic p_L2Slice_3__toNextPipeline_0_all;
  bit   t_L2Slice_3__toNextPipeline_0_all;
  wire  g_L2Slice_3__toNextPipeline_0_req;
  wire  i_L2Slice_3__toNextPipeline_0_req;
  logic p_L2Slice_3__toNextPipeline_0_req;
  bit   t_L2Slice_3__toNextPipeline_0_req;
  wire  g_L2Slice_3__toNextPipeline_0_writeen;
  wire  i_L2Slice_3__toNextPipeline_0_writeen;
  logic p_L2Slice_3__toNextPipeline_0_writeen;
  bit   t_L2Slice_3__toNextPipeline_0_writeen;
  wire  [7:0] g_L2Slice_3__toNextPipeline_0_be;
  wire  [7:0] i_L2Slice_3__toNextPipeline_0_be;
  logic [7:0] p_L2Slice_3__toNextPipeline_0_be;
  bit   t_L2Slice_3__toNextPipeline_0_be;
  wire  [9:0] g_L2Slice_3__toNextPipeline_0_addr;
  wire  [9:0] i_L2Slice_3__toNextPipeline_0_addr;
  logic [9:0] p_L2Slice_3__toNextPipeline_0_addr;
  bit   t_L2Slice_3__toNextPipeline_0_addr;
  wire  [103:0] g_L2Slice_3__toNextPipeline_0_indata;
  wire  [103:0] i_L2Slice_3__toNextPipeline_0_indata;
  logic [103:0] p_L2Slice_3__toNextPipeline_0_indata;
  bit   t_L2Slice_3__toNextPipeline_0_indata;
  wire  g_L2Slice_3__toNextPipeline_0_readen;
  wire  i_L2Slice_3__toNextPipeline_0_readen;
  logic p_L2Slice_3__toNextPipeline_0_readen;
  bit   t_L2Slice_3__toNextPipeline_0_readen;
  wire  [9:0] g_L2Slice_3__toNextPipeline_0_addr_rd;
  wire  [9:0] i_L2Slice_3__toNextPipeline_0_addr_rd;
  logic [9:0] p_L2Slice_3__toNextPipeline_0_addr_rd;
  bit   t_L2Slice_3__toNextPipeline_0_addr_rd;
  wire  [5:0] g_L2Slice_3__toNextPipeline_1_array;
  wire  [5:0] i_L2Slice_3__toNextPipeline_1_array;
  logic [5:0] p_L2Slice_3__toNextPipeline_1_array;
  bit   t_L2Slice_3__toNextPipeline_1_array;
  wire  g_L2Slice_3__toNextPipeline_1_all;
  wire  i_L2Slice_3__toNextPipeline_1_all;
  logic p_L2Slice_3__toNextPipeline_1_all;
  bit   t_L2Slice_3__toNextPipeline_1_all;
  wire  g_L2Slice_3__toNextPipeline_1_req;
  wire  i_L2Slice_3__toNextPipeline_1_req;
  logic p_L2Slice_3__toNextPipeline_1_req;
  bit   t_L2Slice_3__toNextPipeline_1_req;
  wire  g_L2Slice_3__toNextPipeline_1_writeen;
  wire  i_L2Slice_3__toNextPipeline_1_writeen;
  logic p_L2Slice_3__toNextPipeline_1_writeen;
  bit   t_L2Slice_3__toNextPipeline_1_writeen;
  wire  g_L2Slice_3__toNextPipeline_1_be;
  wire  i_L2Slice_3__toNextPipeline_1_be;
  logic p_L2Slice_3__toNextPipeline_1_be;
  bit   t_L2Slice_3__toNextPipeline_1_be;
  wire  [12:0] g_L2Slice_3__toNextPipeline_1_addr;
  wire  [12:0] i_L2Slice_3__toNextPipeline_1_addr;
  logic [12:0] p_L2Slice_3__toNextPipeline_1_addr;
  bit   t_L2Slice_3__toNextPipeline_1_addr;
  wire  [136:0] g_L2Slice_3__toNextPipeline_1_indata;
  wire  [136:0] i_L2Slice_3__toNextPipeline_1_indata;
  logic [136:0] p_L2Slice_3__toNextPipeline_1_indata;
  bit   t_L2Slice_3__toNextPipeline_1_indata;
  wire  g_L2Slice_3__toNextPipeline_1_readen;
  wire  i_L2Slice_3__toNextPipeline_1_readen;
  logic p_L2Slice_3__toNextPipeline_1_readen;
  bit   t_L2Slice_3__toNextPipeline_1_readen;
  wire  [12:0] g_L2Slice_3__toNextPipeline_1_addr_rd;
  wire  [12:0] i_L2Slice_3__toNextPipeline_1_addr_rd;
  logic [12:0] p_L2Slice_3__toNextPipeline_1_addr_rd;
  bit   t_L2Slice_3__toNextPipeline_1_addr_rd;
  L2Slice_3 u_g_L2Slice_3 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_3__mbist_array),
    .mbist_all (L2Slice_3__mbist_all),
    .mbist_req (L2Slice_3__mbist_req),
    .mbist_ack (g_L2Slice_3__mbist_ack),
    .mbist_writeen (L2Slice_3__mbist_writeen),
    .mbist_be (L2Slice_3__mbist_be),
    .mbist_addr (L2Slice_3__mbist_addr),
    .mbist_indata (L2Slice_3__mbist_indata),
    .mbist_readen (L2Slice_3__mbist_readen),
    .mbist_addr_rd (L2Slice_3__mbist_addr_rd),
    .mbist_outdata (g_L2Slice_3__mbist_outdata),
    .toNextPipeline_0_array (g_L2Slice_3__toNextPipeline_0_array),
    .toNextPipeline_0_all (g_L2Slice_3__toNextPipeline_0_all),
    .toNextPipeline_0_req (g_L2Slice_3__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_3__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (g_L2Slice_3__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g_L2Slice_3__toNextPipeline_0_be),
    .toNextPipeline_0_addr (g_L2Slice_3__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g_L2Slice_3__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g_L2Slice_3__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g_L2Slice_3__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_3__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (g_L2Slice_3__toNextPipeline_1_array),
    .toNextPipeline_1_all (g_L2Slice_3__toNextPipeline_1_all),
    .toNextPipeline_1_req (g_L2Slice_3__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_3__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (g_L2Slice_3__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g_L2Slice_3__toNextPipeline_1_be),
    .toNextPipeline_1_addr (g_L2Slice_3__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g_L2Slice_3__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g_L2Slice_3__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g_L2Slice_3__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_3__toNextPipeline_1_outdata)
  );
  L2Slice_3_xs u_i_L2Slice_3 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Slice_3__mbist_array),
    .mbist_all (L2Slice_3__mbist_all),
    .mbist_req (L2Slice_3__mbist_req),
    .mbist_ack (i_L2Slice_3__mbist_ack),
    .mbist_writeen (L2Slice_3__mbist_writeen),
    .mbist_be (L2Slice_3__mbist_be),
    .mbist_addr (L2Slice_3__mbist_addr),
    .mbist_indata (L2Slice_3__mbist_indata),
    .mbist_readen (L2Slice_3__mbist_readen),
    .mbist_addr_rd (L2Slice_3__mbist_addr_rd),
    .mbist_outdata (i_L2Slice_3__mbist_outdata),
    .toNextPipeline_0_array (i_L2Slice_3__toNextPipeline_0_array),
    .toNextPipeline_0_all (i_L2Slice_3__toNextPipeline_0_all),
    .toNextPipeline_0_req (i_L2Slice_3__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Slice_3__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (i_L2Slice_3__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (i_L2Slice_3__toNextPipeline_0_be),
    .toNextPipeline_0_addr (i_L2Slice_3__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (i_L2Slice_3__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (i_L2Slice_3__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (i_L2Slice_3__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Slice_3__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (i_L2Slice_3__toNextPipeline_1_array),
    .toNextPipeline_1_all (i_L2Slice_3__toNextPipeline_1_all),
    .toNextPipeline_1_req (i_L2Slice_3__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Slice_3__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (i_L2Slice_3__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (i_L2Slice_3__toNextPipeline_1_be),
    .toNextPipeline_1_addr (i_L2Slice_3__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (i_L2Slice_3__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (i_L2Slice_3__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (i_L2Slice_3__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Slice_3__toNextPipeline_1_outdata)
  );
  task automatic drive_L2Slice_3();
    L2Slice_3__mbist_array = rnd(6);
    L2Slice_3__mbist_all = $urandom % 2;
    L2Slice_3__mbist_req = $urandom % 2;
    L2Slice_3__mbist_writeen = $urandom % 2;
    L2Slice_3__mbist_be = rnd(8);
    L2Slice_3__mbist_addr = rnd(13);
    L2Slice_3__mbist_indata = rnd(137);
    L2Slice_3__mbist_readen = $urandom % 2;
    L2Slice_3__mbist_addr_rd = rnd(13);
    L2Slice_3__toNextPipeline_0_ack = $urandom % 2;
    L2Slice_3__toNextPipeline_0_outdata = rnd(104);
    L2Slice_3__toNextPipeline_1_ack = $urandom % 2;
    L2Slice_3__toNextPipeline_1_outdata = rnd(137);
  endtask
  task automatic check_L2Slice_3();
    checks++;
    if (g_L2Slice_3__mbist_ack !== i_L2Slice_3__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.mbist_ack g=%h i=%h", cyc, g_L2Slice_3__mbist_ack, i_L2Slice_3__mbist_ack);
    end
    if (g_L2Slice_3__mbist_ack !== p_L2Slice_3__mbist_ack) t_L2Slice_3__mbist_ack = 1'b1;
    p_L2Slice_3__mbist_ack = g_L2Slice_3__mbist_ack;
    checks++;
    if (g_L2Slice_3__mbist_outdata !== i_L2Slice_3__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.mbist_outdata g=%h i=%h", cyc, g_L2Slice_3__mbist_outdata, i_L2Slice_3__mbist_outdata);
    end
    if (g_L2Slice_3__mbist_outdata !== p_L2Slice_3__mbist_outdata) t_L2Slice_3__mbist_outdata = 1'b1;
    p_L2Slice_3__mbist_outdata = g_L2Slice_3__mbist_outdata;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_array !== i_L2Slice_3__toNextPipeline_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_array g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_array, i_L2Slice_3__toNextPipeline_0_array);
    end
    if (g_L2Slice_3__toNextPipeline_0_array !== p_L2Slice_3__toNextPipeline_0_array) t_L2Slice_3__toNextPipeline_0_array = 1'b1;
    p_L2Slice_3__toNextPipeline_0_array = g_L2Slice_3__toNextPipeline_0_array;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_all !== i_L2Slice_3__toNextPipeline_0_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_all g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_all, i_L2Slice_3__toNextPipeline_0_all);
    end
    if (g_L2Slice_3__toNextPipeline_0_all !== p_L2Slice_3__toNextPipeline_0_all) t_L2Slice_3__toNextPipeline_0_all = 1'b1;
    p_L2Slice_3__toNextPipeline_0_all = g_L2Slice_3__toNextPipeline_0_all;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_req !== i_L2Slice_3__toNextPipeline_0_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_req g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_req, i_L2Slice_3__toNextPipeline_0_req);
    end
    if (g_L2Slice_3__toNextPipeline_0_req !== p_L2Slice_3__toNextPipeline_0_req) t_L2Slice_3__toNextPipeline_0_req = 1'b1;
    p_L2Slice_3__toNextPipeline_0_req = g_L2Slice_3__toNextPipeline_0_req;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_writeen !== i_L2Slice_3__toNextPipeline_0_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_writeen g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_writeen, i_L2Slice_3__toNextPipeline_0_writeen);
    end
    if (g_L2Slice_3__toNextPipeline_0_writeen !== p_L2Slice_3__toNextPipeline_0_writeen) t_L2Slice_3__toNextPipeline_0_writeen = 1'b1;
    p_L2Slice_3__toNextPipeline_0_writeen = g_L2Slice_3__toNextPipeline_0_writeen;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_be !== i_L2Slice_3__toNextPipeline_0_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_be g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_be, i_L2Slice_3__toNextPipeline_0_be);
    end
    if (g_L2Slice_3__toNextPipeline_0_be !== p_L2Slice_3__toNextPipeline_0_be) t_L2Slice_3__toNextPipeline_0_be = 1'b1;
    p_L2Slice_3__toNextPipeline_0_be = g_L2Slice_3__toNextPipeline_0_be;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_addr !== i_L2Slice_3__toNextPipeline_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_addr g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_addr, i_L2Slice_3__toNextPipeline_0_addr);
    end
    if (g_L2Slice_3__toNextPipeline_0_addr !== p_L2Slice_3__toNextPipeline_0_addr) t_L2Slice_3__toNextPipeline_0_addr = 1'b1;
    p_L2Slice_3__toNextPipeline_0_addr = g_L2Slice_3__toNextPipeline_0_addr;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_indata !== i_L2Slice_3__toNextPipeline_0_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_indata g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_indata, i_L2Slice_3__toNextPipeline_0_indata);
    end
    if (g_L2Slice_3__toNextPipeline_0_indata !== p_L2Slice_3__toNextPipeline_0_indata) t_L2Slice_3__toNextPipeline_0_indata = 1'b1;
    p_L2Slice_3__toNextPipeline_0_indata = g_L2Slice_3__toNextPipeline_0_indata;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_readen !== i_L2Slice_3__toNextPipeline_0_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_readen g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_readen, i_L2Slice_3__toNextPipeline_0_readen);
    end
    if (g_L2Slice_3__toNextPipeline_0_readen !== p_L2Slice_3__toNextPipeline_0_readen) t_L2Slice_3__toNextPipeline_0_readen = 1'b1;
    p_L2Slice_3__toNextPipeline_0_readen = g_L2Slice_3__toNextPipeline_0_readen;
    checks++;
    if (g_L2Slice_3__toNextPipeline_0_addr_rd !== i_L2Slice_3__toNextPipeline_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_0_addr_rd g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_0_addr_rd, i_L2Slice_3__toNextPipeline_0_addr_rd);
    end
    if (g_L2Slice_3__toNextPipeline_0_addr_rd !== p_L2Slice_3__toNextPipeline_0_addr_rd) t_L2Slice_3__toNextPipeline_0_addr_rd = 1'b1;
    p_L2Slice_3__toNextPipeline_0_addr_rd = g_L2Slice_3__toNextPipeline_0_addr_rd;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_array !== i_L2Slice_3__toNextPipeline_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_array g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_array, i_L2Slice_3__toNextPipeline_1_array);
    end
    if (g_L2Slice_3__toNextPipeline_1_array !== p_L2Slice_3__toNextPipeline_1_array) t_L2Slice_3__toNextPipeline_1_array = 1'b1;
    p_L2Slice_3__toNextPipeline_1_array = g_L2Slice_3__toNextPipeline_1_array;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_all !== i_L2Slice_3__toNextPipeline_1_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_all g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_all, i_L2Slice_3__toNextPipeline_1_all);
    end
    if (g_L2Slice_3__toNextPipeline_1_all !== p_L2Slice_3__toNextPipeline_1_all) t_L2Slice_3__toNextPipeline_1_all = 1'b1;
    p_L2Slice_3__toNextPipeline_1_all = g_L2Slice_3__toNextPipeline_1_all;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_req !== i_L2Slice_3__toNextPipeline_1_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_req g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_req, i_L2Slice_3__toNextPipeline_1_req);
    end
    if (g_L2Slice_3__toNextPipeline_1_req !== p_L2Slice_3__toNextPipeline_1_req) t_L2Slice_3__toNextPipeline_1_req = 1'b1;
    p_L2Slice_3__toNextPipeline_1_req = g_L2Slice_3__toNextPipeline_1_req;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_writeen !== i_L2Slice_3__toNextPipeline_1_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_writeen g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_writeen, i_L2Slice_3__toNextPipeline_1_writeen);
    end
    if (g_L2Slice_3__toNextPipeline_1_writeen !== p_L2Slice_3__toNextPipeline_1_writeen) t_L2Slice_3__toNextPipeline_1_writeen = 1'b1;
    p_L2Slice_3__toNextPipeline_1_writeen = g_L2Slice_3__toNextPipeline_1_writeen;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_be !== i_L2Slice_3__toNextPipeline_1_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_be g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_be, i_L2Slice_3__toNextPipeline_1_be);
    end
    if (g_L2Slice_3__toNextPipeline_1_be !== p_L2Slice_3__toNextPipeline_1_be) t_L2Slice_3__toNextPipeline_1_be = 1'b1;
    p_L2Slice_3__toNextPipeline_1_be = g_L2Slice_3__toNextPipeline_1_be;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_addr !== i_L2Slice_3__toNextPipeline_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_addr g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_addr, i_L2Slice_3__toNextPipeline_1_addr);
    end
    if (g_L2Slice_3__toNextPipeline_1_addr !== p_L2Slice_3__toNextPipeline_1_addr) t_L2Slice_3__toNextPipeline_1_addr = 1'b1;
    p_L2Slice_3__toNextPipeline_1_addr = g_L2Slice_3__toNextPipeline_1_addr;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_indata !== i_L2Slice_3__toNextPipeline_1_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_indata g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_indata, i_L2Slice_3__toNextPipeline_1_indata);
    end
    if (g_L2Slice_3__toNextPipeline_1_indata !== p_L2Slice_3__toNextPipeline_1_indata) t_L2Slice_3__toNextPipeline_1_indata = 1'b1;
    p_L2Slice_3__toNextPipeline_1_indata = g_L2Slice_3__toNextPipeline_1_indata;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_readen !== i_L2Slice_3__toNextPipeline_1_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_readen g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_readen, i_L2Slice_3__toNextPipeline_1_readen);
    end
    if (g_L2Slice_3__toNextPipeline_1_readen !== p_L2Slice_3__toNextPipeline_1_readen) t_L2Slice_3__toNextPipeline_1_readen = 1'b1;
    p_L2Slice_3__toNextPipeline_1_readen = g_L2Slice_3__toNextPipeline_1_readen;
    checks++;
    if (g_L2Slice_3__toNextPipeline_1_addr_rd !== i_L2Slice_3__toNextPipeline_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Slice_3.toNextPipeline_1_addr_rd g=%h i=%h", cyc, g_L2Slice_3__toNextPipeline_1_addr_rd, i_L2Slice_3__toNextPipeline_1_addr_rd);
    end
    if (g_L2Slice_3__toNextPipeline_1_addr_rd !== p_L2Slice_3__toNextPipeline_1_addr_rd) t_L2Slice_3__toNextPipeline_1_addr_rd = 1'b1;
    p_L2Slice_3__toNextPipeline_1_addr_rd = g_L2Slice_3__toNextPipeline_1_addr_rd;
  endtask
  longint cov_L2Slice_3_sel0 = 0;
  longint cov_L2Slice_3_sel1 = 0;
  longint cov_L2Slice_3_act = 0;
  task automatic cover_L2Slice_3();
    if (u_g_L2Slice_3.selected) cov_L2Slice_3_sel0++;
    if (u_g_L2Slice_3.selected_1) cov_L2Slice_3_sel1++;
    if (u_g_L2Slice_3.activated) cov_L2Slice_3_act++;
  endtask
  task automatic sync_L2Slice_3();
    force u_i_L2Slice_3.u_core.g_node_return.pipelineDataOutReg = u_g_L2Slice_3.pipelineDataOutReg;
    #0 release u_i_L2Slice_3.u_core.g_node_return.pipelineDataOutReg;
  endtask

  longint cyc = 0;
  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_L2Slice();
    drive_L2Slice_1();
    drive_L2Slice_2();
    drive_L2Slice_3();
    #1;
    sync_L2Slice();
    sync_L2Slice_1();
    sync_L2Slice_2();
    sync_L2Slice_3();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_L2Slice();
      drive_L2Slice_1();
      drive_L2Slice_2();
      drive_L2Slice_3();
      #1;
      check_L2Slice();
      cover_L2Slice();
      check_L2Slice_1();
      cover_L2Slice_1();
      check_L2Slice_2();
      cover_L2Slice_2();
      check_L2Slice_3();
      cover_L2Slice_3();
    end
    begin int tg; tg = 0;
      if (t_L2Slice__mbist_ack) tg++; else $display("COV: L2Slice.mbist_ack never toggled");
      if (t_L2Slice__mbist_outdata) tg++; else $display("COV: L2Slice.mbist_outdata never toggled");
      if (t_L2Slice__toNextPipeline_0_array) tg++; else $display("COV: L2Slice.toNextPipeline_0_array never toggled");
      if (t_L2Slice__toNextPipeline_0_all) tg++; else $display("COV: L2Slice.toNextPipeline_0_all never toggled");
      if (t_L2Slice__toNextPipeline_0_req) tg++; else $display("COV: L2Slice.toNextPipeline_0_req never toggled");
      if (t_L2Slice__toNextPipeline_0_writeen) tg++; else $display("COV: L2Slice.toNextPipeline_0_writeen never toggled");
      if (t_L2Slice__toNextPipeline_0_be) tg++; else $display("COV: L2Slice.toNextPipeline_0_be never toggled");
      if (t_L2Slice__toNextPipeline_0_addr) tg++; else $display("COV: L2Slice.toNextPipeline_0_addr never toggled");
      if (t_L2Slice__toNextPipeline_0_indata) tg++; else $display("COV: L2Slice.toNextPipeline_0_indata never toggled");
      if (t_L2Slice__toNextPipeline_0_readen) tg++; else $display("COV: L2Slice.toNextPipeline_0_readen never toggled");
      if (t_L2Slice__toNextPipeline_0_addr_rd) tg++; else $display("COV: L2Slice.toNextPipeline_0_addr_rd never toggled");
      if (t_L2Slice__toNextPipeline_1_array) tg++; else $display("COV: L2Slice.toNextPipeline_1_array never toggled");
      if (t_L2Slice__toNextPipeline_1_all) tg++; else $display("COV: L2Slice.toNextPipeline_1_all never toggled");
      if (t_L2Slice__toNextPipeline_1_req) tg++; else $display("COV: L2Slice.toNextPipeline_1_req never toggled");
      if (t_L2Slice__toNextPipeline_1_writeen) tg++; else $display("COV: L2Slice.toNextPipeline_1_writeen never toggled");
      if (t_L2Slice__toNextPipeline_1_be) tg++; else $display("COV: L2Slice.toNextPipeline_1_be never toggled");
      if (t_L2Slice__toNextPipeline_1_addr) tg++; else $display("COV: L2Slice.toNextPipeline_1_addr never toggled");
      if (t_L2Slice__toNextPipeline_1_indata) tg++; else $display("COV: L2Slice.toNextPipeline_1_indata never toggled");
      if (t_L2Slice__toNextPipeline_1_readen) tg++; else $display("COV: L2Slice.toNextPipeline_1_readen never toggled");
      if (t_L2Slice__toNextPipeline_1_addr_rd) tg++; else $display("COV: L2Slice.toNextPipeline_1_addr_rd never toggled");
      $display("L2Slice: toggled=%0d/20 (need >= 20)", tg);
      if (tg < 20) covfail = 1;
      $display("L2Slice: cover sel0 = %0d", cov_L2Slice_sel0);
      if (cov_L2Slice_sel0 == 0) covfail = 1;
      $display("L2Slice: cover sel1 = %0d", cov_L2Slice_sel1);
      if (cov_L2Slice_sel1 == 0) covfail = 1;
      $display("L2Slice: cover act = %0d", cov_L2Slice_act);
      if (cov_L2Slice_act == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_L2Slice_1__mbist_ack) tg++; else $display("COV: L2Slice_1.mbist_ack never toggled");
      if (t_L2Slice_1__mbist_outdata) tg++; else $display("COV: L2Slice_1.mbist_outdata never toggled");
      if (t_L2Slice_1__toNextPipeline_0_array) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_array never toggled");
      if (t_L2Slice_1__toNextPipeline_0_all) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_all never toggled");
      if (t_L2Slice_1__toNextPipeline_0_req) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_req never toggled");
      if (t_L2Slice_1__toNextPipeline_0_writeen) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_writeen never toggled");
      if (t_L2Slice_1__toNextPipeline_0_be) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_be never toggled");
      if (t_L2Slice_1__toNextPipeline_0_addr) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_addr never toggled");
      if (t_L2Slice_1__toNextPipeline_0_indata) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_indata never toggled");
      if (t_L2Slice_1__toNextPipeline_0_readen) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_readen never toggled");
      if (t_L2Slice_1__toNextPipeline_0_addr_rd) tg++; else $display("COV: L2Slice_1.toNextPipeline_0_addr_rd never toggled");
      if (t_L2Slice_1__toNextPipeline_1_array) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_array never toggled");
      if (t_L2Slice_1__toNextPipeline_1_all) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_all never toggled");
      if (t_L2Slice_1__toNextPipeline_1_req) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_req never toggled");
      if (t_L2Slice_1__toNextPipeline_1_writeen) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_writeen never toggled");
      if (t_L2Slice_1__toNextPipeline_1_be) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_be never toggled");
      if (t_L2Slice_1__toNextPipeline_1_addr) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_addr never toggled");
      if (t_L2Slice_1__toNextPipeline_1_indata) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_indata never toggled");
      if (t_L2Slice_1__toNextPipeline_1_readen) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_readen never toggled");
      if (t_L2Slice_1__toNextPipeline_1_addr_rd) tg++; else $display("COV: L2Slice_1.toNextPipeline_1_addr_rd never toggled");
      $display("L2Slice_1: toggled=%0d/20 (need >= 20)", tg);
      if (tg < 20) covfail = 1;
      $display("L2Slice_1: cover sel0 = %0d", cov_L2Slice_1_sel0);
      if (cov_L2Slice_1_sel0 == 0) covfail = 1;
      $display("L2Slice_1: cover sel1 = %0d", cov_L2Slice_1_sel1);
      if (cov_L2Slice_1_sel1 == 0) covfail = 1;
      $display("L2Slice_1: cover act = %0d", cov_L2Slice_1_act);
      if (cov_L2Slice_1_act == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_L2Slice_2__mbist_ack) tg++; else $display("COV: L2Slice_2.mbist_ack never toggled");
      if (t_L2Slice_2__mbist_outdata) tg++; else $display("COV: L2Slice_2.mbist_outdata never toggled");
      if (t_L2Slice_2__toNextPipeline_0_array) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_array never toggled");
      if (t_L2Slice_2__toNextPipeline_0_all) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_all never toggled");
      if (t_L2Slice_2__toNextPipeline_0_req) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_req never toggled");
      if (t_L2Slice_2__toNextPipeline_0_writeen) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_writeen never toggled");
      if (t_L2Slice_2__toNextPipeline_0_be) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_be never toggled");
      if (t_L2Slice_2__toNextPipeline_0_addr) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_addr never toggled");
      if (t_L2Slice_2__toNextPipeline_0_indata) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_indata never toggled");
      if (t_L2Slice_2__toNextPipeline_0_readen) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_readen never toggled");
      if (t_L2Slice_2__toNextPipeline_0_addr_rd) tg++; else $display("COV: L2Slice_2.toNextPipeline_0_addr_rd never toggled");
      if (t_L2Slice_2__toNextPipeline_1_array) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_array never toggled");
      if (t_L2Slice_2__toNextPipeline_1_all) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_all never toggled");
      if (t_L2Slice_2__toNextPipeline_1_req) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_req never toggled");
      if (t_L2Slice_2__toNextPipeline_1_writeen) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_writeen never toggled");
      if (t_L2Slice_2__toNextPipeline_1_be) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_be never toggled");
      if (t_L2Slice_2__toNextPipeline_1_addr) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_addr never toggled");
      if (t_L2Slice_2__toNextPipeline_1_indata) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_indata never toggled");
      if (t_L2Slice_2__toNextPipeline_1_readen) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_readen never toggled");
      if (t_L2Slice_2__toNextPipeline_1_addr_rd) tg++; else $display("COV: L2Slice_2.toNextPipeline_1_addr_rd never toggled");
      $display("L2Slice_2: toggled=%0d/20 (need >= 20)", tg);
      if (tg < 20) covfail = 1;
      $display("L2Slice_2: cover sel0 = %0d", cov_L2Slice_2_sel0);
      if (cov_L2Slice_2_sel0 == 0) covfail = 1;
      $display("L2Slice_2: cover sel1 = %0d", cov_L2Slice_2_sel1);
      if (cov_L2Slice_2_sel1 == 0) covfail = 1;
      $display("L2Slice_2: cover act = %0d", cov_L2Slice_2_act);
      if (cov_L2Slice_2_act == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_L2Slice_3__mbist_ack) tg++; else $display("COV: L2Slice_3.mbist_ack never toggled");
      if (t_L2Slice_3__mbist_outdata) tg++; else $display("COV: L2Slice_3.mbist_outdata never toggled");
      if (t_L2Slice_3__toNextPipeline_0_array) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_array never toggled");
      if (t_L2Slice_3__toNextPipeline_0_all) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_all never toggled");
      if (t_L2Slice_3__toNextPipeline_0_req) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_req never toggled");
      if (t_L2Slice_3__toNextPipeline_0_writeen) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_writeen never toggled");
      if (t_L2Slice_3__toNextPipeline_0_be) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_be never toggled");
      if (t_L2Slice_3__toNextPipeline_0_addr) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_addr never toggled");
      if (t_L2Slice_3__toNextPipeline_0_indata) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_indata never toggled");
      if (t_L2Slice_3__toNextPipeline_0_readen) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_readen never toggled");
      if (t_L2Slice_3__toNextPipeline_0_addr_rd) tg++; else $display("COV: L2Slice_3.toNextPipeline_0_addr_rd never toggled");
      if (t_L2Slice_3__toNextPipeline_1_array) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_array never toggled");
      if (t_L2Slice_3__toNextPipeline_1_all) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_all never toggled");
      if (t_L2Slice_3__toNextPipeline_1_req) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_req never toggled");
      if (t_L2Slice_3__toNextPipeline_1_writeen) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_writeen never toggled");
      if (t_L2Slice_3__toNextPipeline_1_be) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_be never toggled");
      if (t_L2Slice_3__toNextPipeline_1_addr) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_addr never toggled");
      if (t_L2Slice_3__toNextPipeline_1_indata) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_indata never toggled");
      if (t_L2Slice_3__toNextPipeline_1_readen) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_readen never toggled");
      if (t_L2Slice_3__toNextPipeline_1_addr_rd) tg++; else $display("COV: L2Slice_3.toNextPipeline_1_addr_rd never toggled");
      $display("L2Slice_3: toggled=%0d/20 (need >= 20)", tg);
      if (tg < 20) covfail = 1;
      $display("L2Slice_3: cover sel0 = %0d", cov_L2Slice_3_sel0);
      if (cov_L2Slice_3_sel0 == 0) covfail = 1;
      $display("L2Slice_3: cover sel1 = %0d", cov_L2Slice_3_sel1);
      if (cov_L2Slice_3_sel1 == 0) covfail = 1;
      $display("L2Slice_3: cover act = %0d", cov_L2Slice_3_act);
      if (cov_L2Slice_3_act == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
