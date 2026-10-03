// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：L2Cache
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= L2Cache =======================
  logic [5:0] L2Cache__mbist_array;
  logic L2Cache__mbist_all;
  logic L2Cache__mbist_req;
  logic L2Cache__mbist_writeen;
  logic [7:0] L2Cache__mbist_be;
  logic [12:0] L2Cache__mbist_addr;
  logic [136:0] L2Cache__mbist_indata;
  logic L2Cache__mbist_readen;
  logic [12:0] L2Cache__mbist_addr_rd;
  logic L2Cache__toNextPipeline_0_ack;
  logic [12:0] L2Cache__toNextPipeline_0_outdata;
  logic L2Cache__toNextPipeline_1_ack;
  logic [136:0] L2Cache__toNextPipeline_1_outdata;
  logic L2Cache__toNextPipeline_2_ack;
  logic [136:0] L2Cache__toNextPipeline_2_outdata;
  logic L2Cache__toNextPipeline_3_ack;
  logic [136:0] L2Cache__toNextPipeline_3_outdata;
  logic L2Cache__toNextPipeline_4_ack;
  logic [136:0] L2Cache__toNextPipeline_4_outdata;
  wire  g_L2Cache__mbist_ack;
  wire  i_L2Cache__mbist_ack;
  logic p_L2Cache__mbist_ack;
  bit   t_L2Cache__mbist_ack;
  wire  [136:0] g_L2Cache__mbist_outdata;
  wire  [136:0] i_L2Cache__mbist_outdata;
  logic [136:0] p_L2Cache__mbist_outdata;
  bit   t_L2Cache__mbist_outdata;
  wire  g_L2Cache__toNextPipeline_0_array;
  wire  i_L2Cache__toNextPipeline_0_array;
  logic p_L2Cache__toNextPipeline_0_array;
  bit   t_L2Cache__toNextPipeline_0_array;
  wire  g_L2Cache__toNextPipeline_0_all;
  wire  i_L2Cache__toNextPipeline_0_all;
  logic p_L2Cache__toNextPipeline_0_all;
  bit   t_L2Cache__toNextPipeline_0_all;
  wire  g_L2Cache__toNextPipeline_0_req;
  wire  i_L2Cache__toNextPipeline_0_req;
  logic p_L2Cache__toNextPipeline_0_req;
  bit   t_L2Cache__toNextPipeline_0_req;
  wire  g_L2Cache__toNextPipeline_0_writeen;
  wire  i_L2Cache__toNextPipeline_0_writeen;
  logic p_L2Cache__toNextPipeline_0_writeen;
  bit   t_L2Cache__toNextPipeline_0_writeen;
  wire  g_L2Cache__toNextPipeline_0_be;
  wire  i_L2Cache__toNextPipeline_0_be;
  logic p_L2Cache__toNextPipeline_0_be;
  bit   t_L2Cache__toNextPipeline_0_be;
  wire  [8:0] g_L2Cache__toNextPipeline_0_addr;
  wire  [8:0] i_L2Cache__toNextPipeline_0_addr;
  logic [8:0] p_L2Cache__toNextPipeline_0_addr;
  bit   t_L2Cache__toNextPipeline_0_addr;
  wire  [12:0] g_L2Cache__toNextPipeline_0_indata;
  wire  [12:0] i_L2Cache__toNextPipeline_0_indata;
  logic [12:0] p_L2Cache__toNextPipeline_0_indata;
  bit   t_L2Cache__toNextPipeline_0_indata;
  wire  g_L2Cache__toNextPipeline_0_readen;
  wire  i_L2Cache__toNextPipeline_0_readen;
  logic p_L2Cache__toNextPipeline_0_readen;
  bit   t_L2Cache__toNextPipeline_0_readen;
  wire  [8:0] g_L2Cache__toNextPipeline_0_addr_rd;
  wire  [8:0] i_L2Cache__toNextPipeline_0_addr_rd;
  logic [8:0] p_L2Cache__toNextPipeline_0_addr_rd;
  bit   t_L2Cache__toNextPipeline_0_addr_rd;
  wire  [3:0] g_L2Cache__toNextPipeline_1_array;
  wire  [3:0] i_L2Cache__toNextPipeline_1_array;
  logic [3:0] p_L2Cache__toNextPipeline_1_array;
  bit   t_L2Cache__toNextPipeline_1_array;
  wire  g_L2Cache__toNextPipeline_1_all;
  wire  i_L2Cache__toNextPipeline_1_all;
  logic p_L2Cache__toNextPipeline_1_all;
  bit   t_L2Cache__toNextPipeline_1_all;
  wire  g_L2Cache__toNextPipeline_1_req;
  wire  i_L2Cache__toNextPipeline_1_req;
  logic p_L2Cache__toNextPipeline_1_req;
  bit   t_L2Cache__toNextPipeline_1_req;
  wire  g_L2Cache__toNextPipeline_1_writeen;
  wire  i_L2Cache__toNextPipeline_1_writeen;
  logic p_L2Cache__toNextPipeline_1_writeen;
  bit   t_L2Cache__toNextPipeline_1_writeen;
  wire  [7:0] g_L2Cache__toNextPipeline_1_be;
  wire  [7:0] i_L2Cache__toNextPipeline_1_be;
  logic [7:0] p_L2Cache__toNextPipeline_1_be;
  bit   t_L2Cache__toNextPipeline_1_be;
  wire  [12:0] g_L2Cache__toNextPipeline_1_addr;
  wire  [12:0] i_L2Cache__toNextPipeline_1_addr;
  logic [12:0] p_L2Cache__toNextPipeline_1_addr;
  bit   t_L2Cache__toNextPipeline_1_addr;
  wire  [136:0] g_L2Cache__toNextPipeline_1_indata;
  wire  [136:0] i_L2Cache__toNextPipeline_1_indata;
  logic [136:0] p_L2Cache__toNextPipeline_1_indata;
  bit   t_L2Cache__toNextPipeline_1_indata;
  wire  g_L2Cache__toNextPipeline_1_readen;
  wire  i_L2Cache__toNextPipeline_1_readen;
  logic p_L2Cache__toNextPipeline_1_readen;
  bit   t_L2Cache__toNextPipeline_1_readen;
  wire  [12:0] g_L2Cache__toNextPipeline_1_addr_rd;
  wire  [12:0] i_L2Cache__toNextPipeline_1_addr_rd;
  logic [12:0] p_L2Cache__toNextPipeline_1_addr_rd;
  bit   t_L2Cache__toNextPipeline_1_addr_rd;
  wire  [4:0] g_L2Cache__toNextPipeline_2_array;
  wire  [4:0] i_L2Cache__toNextPipeline_2_array;
  logic [4:0] p_L2Cache__toNextPipeline_2_array;
  bit   t_L2Cache__toNextPipeline_2_array;
  wire  g_L2Cache__toNextPipeline_2_all;
  wire  i_L2Cache__toNextPipeline_2_all;
  logic p_L2Cache__toNextPipeline_2_all;
  bit   t_L2Cache__toNextPipeline_2_all;
  wire  g_L2Cache__toNextPipeline_2_req;
  wire  i_L2Cache__toNextPipeline_2_req;
  logic p_L2Cache__toNextPipeline_2_req;
  bit   t_L2Cache__toNextPipeline_2_req;
  wire  g_L2Cache__toNextPipeline_2_writeen;
  wire  i_L2Cache__toNextPipeline_2_writeen;
  logic p_L2Cache__toNextPipeline_2_writeen;
  bit   t_L2Cache__toNextPipeline_2_writeen;
  wire  [7:0] g_L2Cache__toNextPipeline_2_be;
  wire  [7:0] i_L2Cache__toNextPipeline_2_be;
  logic [7:0] p_L2Cache__toNextPipeline_2_be;
  bit   t_L2Cache__toNextPipeline_2_be;
  wire  [12:0] g_L2Cache__toNextPipeline_2_addr;
  wire  [12:0] i_L2Cache__toNextPipeline_2_addr;
  logic [12:0] p_L2Cache__toNextPipeline_2_addr;
  bit   t_L2Cache__toNextPipeline_2_addr;
  wire  [136:0] g_L2Cache__toNextPipeline_2_indata;
  wire  [136:0] i_L2Cache__toNextPipeline_2_indata;
  logic [136:0] p_L2Cache__toNextPipeline_2_indata;
  bit   t_L2Cache__toNextPipeline_2_indata;
  wire  g_L2Cache__toNextPipeline_2_readen;
  wire  i_L2Cache__toNextPipeline_2_readen;
  logic p_L2Cache__toNextPipeline_2_readen;
  bit   t_L2Cache__toNextPipeline_2_readen;
  wire  [12:0] g_L2Cache__toNextPipeline_2_addr_rd;
  wire  [12:0] i_L2Cache__toNextPipeline_2_addr_rd;
  logic [12:0] p_L2Cache__toNextPipeline_2_addr_rd;
  bit   t_L2Cache__toNextPipeline_2_addr_rd;
  wire  [5:0] g_L2Cache__toNextPipeline_3_array;
  wire  [5:0] i_L2Cache__toNextPipeline_3_array;
  logic [5:0] p_L2Cache__toNextPipeline_3_array;
  bit   t_L2Cache__toNextPipeline_3_array;
  wire  g_L2Cache__toNextPipeline_3_all;
  wire  i_L2Cache__toNextPipeline_3_all;
  logic p_L2Cache__toNextPipeline_3_all;
  bit   t_L2Cache__toNextPipeline_3_all;
  wire  g_L2Cache__toNextPipeline_3_req;
  wire  i_L2Cache__toNextPipeline_3_req;
  logic p_L2Cache__toNextPipeline_3_req;
  bit   t_L2Cache__toNextPipeline_3_req;
  wire  g_L2Cache__toNextPipeline_3_writeen;
  wire  i_L2Cache__toNextPipeline_3_writeen;
  logic p_L2Cache__toNextPipeline_3_writeen;
  bit   t_L2Cache__toNextPipeline_3_writeen;
  wire  [7:0] g_L2Cache__toNextPipeline_3_be;
  wire  [7:0] i_L2Cache__toNextPipeline_3_be;
  logic [7:0] p_L2Cache__toNextPipeline_3_be;
  bit   t_L2Cache__toNextPipeline_3_be;
  wire  [12:0] g_L2Cache__toNextPipeline_3_addr;
  wire  [12:0] i_L2Cache__toNextPipeline_3_addr;
  logic [12:0] p_L2Cache__toNextPipeline_3_addr;
  bit   t_L2Cache__toNextPipeline_3_addr;
  wire  [136:0] g_L2Cache__toNextPipeline_3_indata;
  wire  [136:0] i_L2Cache__toNextPipeline_3_indata;
  logic [136:0] p_L2Cache__toNextPipeline_3_indata;
  bit   t_L2Cache__toNextPipeline_3_indata;
  wire  g_L2Cache__toNextPipeline_3_readen;
  wire  i_L2Cache__toNextPipeline_3_readen;
  logic p_L2Cache__toNextPipeline_3_readen;
  bit   t_L2Cache__toNextPipeline_3_readen;
  wire  [12:0] g_L2Cache__toNextPipeline_3_addr_rd;
  wire  [12:0] i_L2Cache__toNextPipeline_3_addr_rd;
  logic [12:0] p_L2Cache__toNextPipeline_3_addr_rd;
  bit   t_L2Cache__toNextPipeline_3_addr_rd;
  wire  [5:0] g_L2Cache__toNextPipeline_4_array;
  wire  [5:0] i_L2Cache__toNextPipeline_4_array;
  logic [5:0] p_L2Cache__toNextPipeline_4_array;
  bit   t_L2Cache__toNextPipeline_4_array;
  wire  g_L2Cache__toNextPipeline_4_all;
  wire  i_L2Cache__toNextPipeline_4_all;
  logic p_L2Cache__toNextPipeline_4_all;
  bit   t_L2Cache__toNextPipeline_4_all;
  wire  g_L2Cache__toNextPipeline_4_req;
  wire  i_L2Cache__toNextPipeline_4_req;
  logic p_L2Cache__toNextPipeline_4_req;
  bit   t_L2Cache__toNextPipeline_4_req;
  wire  g_L2Cache__toNextPipeline_4_writeen;
  wire  i_L2Cache__toNextPipeline_4_writeen;
  logic p_L2Cache__toNextPipeline_4_writeen;
  bit   t_L2Cache__toNextPipeline_4_writeen;
  wire  [7:0] g_L2Cache__toNextPipeline_4_be;
  wire  [7:0] i_L2Cache__toNextPipeline_4_be;
  logic [7:0] p_L2Cache__toNextPipeline_4_be;
  bit   t_L2Cache__toNextPipeline_4_be;
  wire  [12:0] g_L2Cache__toNextPipeline_4_addr;
  wire  [12:0] i_L2Cache__toNextPipeline_4_addr;
  logic [12:0] p_L2Cache__toNextPipeline_4_addr;
  bit   t_L2Cache__toNextPipeline_4_addr;
  wire  [136:0] g_L2Cache__toNextPipeline_4_indata;
  wire  [136:0] i_L2Cache__toNextPipeline_4_indata;
  logic [136:0] p_L2Cache__toNextPipeline_4_indata;
  bit   t_L2Cache__toNextPipeline_4_indata;
  wire  g_L2Cache__toNextPipeline_4_readen;
  wire  i_L2Cache__toNextPipeline_4_readen;
  logic p_L2Cache__toNextPipeline_4_readen;
  bit   t_L2Cache__toNextPipeline_4_readen;
  wire  [12:0] g_L2Cache__toNextPipeline_4_addr_rd;
  wire  [12:0] i_L2Cache__toNextPipeline_4_addr_rd;
  logic [12:0] p_L2Cache__toNextPipeline_4_addr_rd;
  bit   t_L2Cache__toNextPipeline_4_addr_rd;
  L2Cache u_g_L2Cache (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Cache__mbist_array),
    .mbist_all (L2Cache__mbist_all),
    .mbist_req (L2Cache__mbist_req),
    .mbist_ack (g_L2Cache__mbist_ack),
    .mbist_writeen (L2Cache__mbist_writeen),
    .mbist_be (L2Cache__mbist_be),
    .mbist_addr (L2Cache__mbist_addr),
    .mbist_indata (L2Cache__mbist_indata),
    .mbist_readen (L2Cache__mbist_readen),
    .mbist_addr_rd (L2Cache__mbist_addr_rd),
    .mbist_outdata (g_L2Cache__mbist_outdata),
    .toNextPipeline_0_array (g_L2Cache__toNextPipeline_0_array),
    .toNextPipeline_0_all (g_L2Cache__toNextPipeline_0_all),
    .toNextPipeline_0_req (g_L2Cache__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Cache__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (g_L2Cache__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g_L2Cache__toNextPipeline_0_be),
    .toNextPipeline_0_addr (g_L2Cache__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g_L2Cache__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g_L2Cache__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g_L2Cache__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Cache__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (g_L2Cache__toNextPipeline_1_array),
    .toNextPipeline_1_all (g_L2Cache__toNextPipeline_1_all),
    .toNextPipeline_1_req (g_L2Cache__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Cache__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (g_L2Cache__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g_L2Cache__toNextPipeline_1_be),
    .toNextPipeline_1_addr (g_L2Cache__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g_L2Cache__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g_L2Cache__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g_L2Cache__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Cache__toNextPipeline_1_outdata),
    .toNextPipeline_2_array (g_L2Cache__toNextPipeline_2_array),
    .toNextPipeline_2_all (g_L2Cache__toNextPipeline_2_all),
    .toNextPipeline_2_req (g_L2Cache__toNextPipeline_2_req),
    .toNextPipeline_2_ack (L2Cache__toNextPipeline_2_ack),
    .toNextPipeline_2_writeen (g_L2Cache__toNextPipeline_2_writeen),
    .toNextPipeline_2_be (g_L2Cache__toNextPipeline_2_be),
    .toNextPipeline_2_addr (g_L2Cache__toNextPipeline_2_addr),
    .toNextPipeline_2_indata (g_L2Cache__toNextPipeline_2_indata),
    .toNextPipeline_2_readen (g_L2Cache__toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (g_L2Cache__toNextPipeline_2_addr_rd),
    .toNextPipeline_2_outdata (L2Cache__toNextPipeline_2_outdata),
    .toNextPipeline_3_array (g_L2Cache__toNextPipeline_3_array),
    .toNextPipeline_3_all (g_L2Cache__toNextPipeline_3_all),
    .toNextPipeline_3_req (g_L2Cache__toNextPipeline_3_req),
    .toNextPipeline_3_ack (L2Cache__toNextPipeline_3_ack),
    .toNextPipeline_3_writeen (g_L2Cache__toNextPipeline_3_writeen),
    .toNextPipeline_3_be (g_L2Cache__toNextPipeline_3_be),
    .toNextPipeline_3_addr (g_L2Cache__toNextPipeline_3_addr),
    .toNextPipeline_3_indata (g_L2Cache__toNextPipeline_3_indata),
    .toNextPipeline_3_readen (g_L2Cache__toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (g_L2Cache__toNextPipeline_3_addr_rd),
    .toNextPipeline_3_outdata (L2Cache__toNextPipeline_3_outdata),
    .toNextPipeline_4_array (g_L2Cache__toNextPipeline_4_array),
    .toNextPipeline_4_all (g_L2Cache__toNextPipeline_4_all),
    .toNextPipeline_4_req (g_L2Cache__toNextPipeline_4_req),
    .toNextPipeline_4_ack (L2Cache__toNextPipeline_4_ack),
    .toNextPipeline_4_writeen (g_L2Cache__toNextPipeline_4_writeen),
    .toNextPipeline_4_be (g_L2Cache__toNextPipeline_4_be),
    .toNextPipeline_4_addr (g_L2Cache__toNextPipeline_4_addr),
    .toNextPipeline_4_indata (g_L2Cache__toNextPipeline_4_indata),
    .toNextPipeline_4_readen (g_L2Cache__toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (g_L2Cache__toNextPipeline_4_addr_rd),
    .toNextPipeline_4_outdata (L2Cache__toNextPipeline_4_outdata)
  );
  L2Cache_xs u_i_L2Cache (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Cache__mbist_array),
    .mbist_all (L2Cache__mbist_all),
    .mbist_req (L2Cache__mbist_req),
    .mbist_ack (i_L2Cache__mbist_ack),
    .mbist_writeen (L2Cache__mbist_writeen),
    .mbist_be (L2Cache__mbist_be),
    .mbist_addr (L2Cache__mbist_addr),
    .mbist_indata (L2Cache__mbist_indata),
    .mbist_readen (L2Cache__mbist_readen),
    .mbist_addr_rd (L2Cache__mbist_addr_rd),
    .mbist_outdata (i_L2Cache__mbist_outdata),
    .toNextPipeline_0_array (i_L2Cache__toNextPipeline_0_array),
    .toNextPipeline_0_all (i_L2Cache__toNextPipeline_0_all),
    .toNextPipeline_0_req (i_L2Cache__toNextPipeline_0_req),
    .toNextPipeline_0_ack (L2Cache__toNextPipeline_0_ack),
    .toNextPipeline_0_writeen (i_L2Cache__toNextPipeline_0_writeen),
    .toNextPipeline_0_be (i_L2Cache__toNextPipeline_0_be),
    .toNextPipeline_0_addr (i_L2Cache__toNextPipeline_0_addr),
    .toNextPipeline_0_indata (i_L2Cache__toNextPipeline_0_indata),
    .toNextPipeline_0_readen (i_L2Cache__toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (i_L2Cache__toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata (L2Cache__toNextPipeline_0_outdata),
    .toNextPipeline_1_array (i_L2Cache__toNextPipeline_1_array),
    .toNextPipeline_1_all (i_L2Cache__toNextPipeline_1_all),
    .toNextPipeline_1_req (i_L2Cache__toNextPipeline_1_req),
    .toNextPipeline_1_ack (L2Cache__toNextPipeline_1_ack),
    .toNextPipeline_1_writeen (i_L2Cache__toNextPipeline_1_writeen),
    .toNextPipeline_1_be (i_L2Cache__toNextPipeline_1_be),
    .toNextPipeline_1_addr (i_L2Cache__toNextPipeline_1_addr),
    .toNextPipeline_1_indata (i_L2Cache__toNextPipeline_1_indata),
    .toNextPipeline_1_readen (i_L2Cache__toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (i_L2Cache__toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata (L2Cache__toNextPipeline_1_outdata),
    .toNextPipeline_2_array (i_L2Cache__toNextPipeline_2_array),
    .toNextPipeline_2_all (i_L2Cache__toNextPipeline_2_all),
    .toNextPipeline_2_req (i_L2Cache__toNextPipeline_2_req),
    .toNextPipeline_2_ack (L2Cache__toNextPipeline_2_ack),
    .toNextPipeline_2_writeen (i_L2Cache__toNextPipeline_2_writeen),
    .toNextPipeline_2_be (i_L2Cache__toNextPipeline_2_be),
    .toNextPipeline_2_addr (i_L2Cache__toNextPipeline_2_addr),
    .toNextPipeline_2_indata (i_L2Cache__toNextPipeline_2_indata),
    .toNextPipeline_2_readen (i_L2Cache__toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (i_L2Cache__toNextPipeline_2_addr_rd),
    .toNextPipeline_2_outdata (L2Cache__toNextPipeline_2_outdata),
    .toNextPipeline_3_array (i_L2Cache__toNextPipeline_3_array),
    .toNextPipeline_3_all (i_L2Cache__toNextPipeline_3_all),
    .toNextPipeline_3_req (i_L2Cache__toNextPipeline_3_req),
    .toNextPipeline_3_ack (L2Cache__toNextPipeline_3_ack),
    .toNextPipeline_3_writeen (i_L2Cache__toNextPipeline_3_writeen),
    .toNextPipeline_3_be (i_L2Cache__toNextPipeline_3_be),
    .toNextPipeline_3_addr (i_L2Cache__toNextPipeline_3_addr),
    .toNextPipeline_3_indata (i_L2Cache__toNextPipeline_3_indata),
    .toNextPipeline_3_readen (i_L2Cache__toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (i_L2Cache__toNextPipeline_3_addr_rd),
    .toNextPipeline_3_outdata (L2Cache__toNextPipeline_3_outdata),
    .toNextPipeline_4_array (i_L2Cache__toNextPipeline_4_array),
    .toNextPipeline_4_all (i_L2Cache__toNextPipeline_4_all),
    .toNextPipeline_4_req (i_L2Cache__toNextPipeline_4_req),
    .toNextPipeline_4_ack (L2Cache__toNextPipeline_4_ack),
    .toNextPipeline_4_writeen (i_L2Cache__toNextPipeline_4_writeen),
    .toNextPipeline_4_be (i_L2Cache__toNextPipeline_4_be),
    .toNextPipeline_4_addr (i_L2Cache__toNextPipeline_4_addr),
    .toNextPipeline_4_indata (i_L2Cache__toNextPipeline_4_indata),
    .toNextPipeline_4_readen (i_L2Cache__toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (i_L2Cache__toNextPipeline_4_addr_rd),
    .toNextPipeline_4_outdata (L2Cache__toNextPipeline_4_outdata)
  );
  task automatic drive_L2Cache();
    L2Cache__mbist_array = rnd(6);
    L2Cache__mbist_all = $urandom % 2;
    L2Cache__mbist_req = $urandom % 2;
    L2Cache__mbist_writeen = $urandom % 2;
    L2Cache__mbist_be = rnd(8);
    L2Cache__mbist_addr = rnd(13);
    L2Cache__mbist_indata = rnd(137);
    L2Cache__mbist_readen = $urandom % 2;
    L2Cache__mbist_addr_rd = rnd(13);
    L2Cache__toNextPipeline_0_ack = $urandom % 2;
    L2Cache__toNextPipeline_0_outdata = rnd(13);
    L2Cache__toNextPipeline_1_ack = $urandom % 2;
    L2Cache__toNextPipeline_1_outdata = rnd(137);
    L2Cache__toNextPipeline_2_ack = $urandom % 2;
    L2Cache__toNextPipeline_2_outdata = rnd(137);
    L2Cache__toNextPipeline_3_ack = $urandom % 2;
    L2Cache__toNextPipeline_3_outdata = rnd(137);
    L2Cache__toNextPipeline_4_ack = $urandom % 2;
    L2Cache__toNextPipeline_4_outdata = rnd(137);
  endtask
  task automatic check_L2Cache();
    checks++;
    if (g_L2Cache__mbist_ack !== i_L2Cache__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.mbist_ack g=%h i=%h", cyc, g_L2Cache__mbist_ack, i_L2Cache__mbist_ack);
    end
    if (g_L2Cache__mbist_ack !== p_L2Cache__mbist_ack) t_L2Cache__mbist_ack = 1'b1;
    p_L2Cache__mbist_ack = g_L2Cache__mbist_ack;
    checks++;
    if (g_L2Cache__mbist_outdata !== i_L2Cache__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.mbist_outdata g=%h i=%h", cyc, g_L2Cache__mbist_outdata, i_L2Cache__mbist_outdata);
    end
    if (g_L2Cache__mbist_outdata !== p_L2Cache__mbist_outdata) t_L2Cache__mbist_outdata = 1'b1;
    p_L2Cache__mbist_outdata = g_L2Cache__mbist_outdata;
    checks++;
    if (g_L2Cache__toNextPipeline_0_array !== i_L2Cache__toNextPipeline_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_array g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_array, i_L2Cache__toNextPipeline_0_array);
    end
    if (g_L2Cache__toNextPipeline_0_array !== p_L2Cache__toNextPipeline_0_array) t_L2Cache__toNextPipeline_0_array = 1'b1;
    p_L2Cache__toNextPipeline_0_array = g_L2Cache__toNextPipeline_0_array;
    checks++;
    if (g_L2Cache__toNextPipeline_0_all !== i_L2Cache__toNextPipeline_0_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_all g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_all, i_L2Cache__toNextPipeline_0_all);
    end
    if (g_L2Cache__toNextPipeline_0_all !== p_L2Cache__toNextPipeline_0_all) t_L2Cache__toNextPipeline_0_all = 1'b1;
    p_L2Cache__toNextPipeline_0_all = g_L2Cache__toNextPipeline_0_all;
    checks++;
    if (g_L2Cache__toNextPipeline_0_req !== i_L2Cache__toNextPipeline_0_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_req g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_req, i_L2Cache__toNextPipeline_0_req);
    end
    if (g_L2Cache__toNextPipeline_0_req !== p_L2Cache__toNextPipeline_0_req) t_L2Cache__toNextPipeline_0_req = 1'b1;
    p_L2Cache__toNextPipeline_0_req = g_L2Cache__toNextPipeline_0_req;
    checks++;
    if (g_L2Cache__toNextPipeline_0_writeen !== i_L2Cache__toNextPipeline_0_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_writeen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_writeen, i_L2Cache__toNextPipeline_0_writeen);
    end
    if (g_L2Cache__toNextPipeline_0_writeen !== p_L2Cache__toNextPipeline_0_writeen) t_L2Cache__toNextPipeline_0_writeen = 1'b1;
    p_L2Cache__toNextPipeline_0_writeen = g_L2Cache__toNextPipeline_0_writeen;
    checks++;
    if (g_L2Cache__toNextPipeline_0_be !== i_L2Cache__toNextPipeline_0_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_be g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_be, i_L2Cache__toNextPipeline_0_be);
    end
    if (g_L2Cache__toNextPipeline_0_be !== p_L2Cache__toNextPipeline_0_be) t_L2Cache__toNextPipeline_0_be = 1'b1;
    p_L2Cache__toNextPipeline_0_be = g_L2Cache__toNextPipeline_0_be;
    checks++;
    if (g_L2Cache__toNextPipeline_0_addr !== i_L2Cache__toNextPipeline_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_addr g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_addr, i_L2Cache__toNextPipeline_0_addr);
    end
    if (g_L2Cache__toNextPipeline_0_addr !== p_L2Cache__toNextPipeline_0_addr) t_L2Cache__toNextPipeline_0_addr = 1'b1;
    p_L2Cache__toNextPipeline_0_addr = g_L2Cache__toNextPipeline_0_addr;
    checks++;
    if (g_L2Cache__toNextPipeline_0_indata !== i_L2Cache__toNextPipeline_0_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_indata g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_indata, i_L2Cache__toNextPipeline_0_indata);
    end
    if (g_L2Cache__toNextPipeline_0_indata !== p_L2Cache__toNextPipeline_0_indata) t_L2Cache__toNextPipeline_0_indata = 1'b1;
    p_L2Cache__toNextPipeline_0_indata = g_L2Cache__toNextPipeline_0_indata;
    checks++;
    if (g_L2Cache__toNextPipeline_0_readen !== i_L2Cache__toNextPipeline_0_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_readen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_readen, i_L2Cache__toNextPipeline_0_readen);
    end
    if (g_L2Cache__toNextPipeline_0_readen !== p_L2Cache__toNextPipeline_0_readen) t_L2Cache__toNextPipeline_0_readen = 1'b1;
    p_L2Cache__toNextPipeline_0_readen = g_L2Cache__toNextPipeline_0_readen;
    checks++;
    if (g_L2Cache__toNextPipeline_0_addr_rd !== i_L2Cache__toNextPipeline_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_0_addr_rd g=%h i=%h", cyc, g_L2Cache__toNextPipeline_0_addr_rd, i_L2Cache__toNextPipeline_0_addr_rd);
    end
    if (g_L2Cache__toNextPipeline_0_addr_rd !== p_L2Cache__toNextPipeline_0_addr_rd) t_L2Cache__toNextPipeline_0_addr_rd = 1'b1;
    p_L2Cache__toNextPipeline_0_addr_rd = g_L2Cache__toNextPipeline_0_addr_rd;
    checks++;
    if (g_L2Cache__toNextPipeline_1_array !== i_L2Cache__toNextPipeline_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_array g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_array, i_L2Cache__toNextPipeline_1_array);
    end
    if (g_L2Cache__toNextPipeline_1_array !== p_L2Cache__toNextPipeline_1_array) t_L2Cache__toNextPipeline_1_array = 1'b1;
    p_L2Cache__toNextPipeline_1_array = g_L2Cache__toNextPipeline_1_array;
    checks++;
    if (g_L2Cache__toNextPipeline_1_all !== i_L2Cache__toNextPipeline_1_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_all g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_all, i_L2Cache__toNextPipeline_1_all);
    end
    if (g_L2Cache__toNextPipeline_1_all !== p_L2Cache__toNextPipeline_1_all) t_L2Cache__toNextPipeline_1_all = 1'b1;
    p_L2Cache__toNextPipeline_1_all = g_L2Cache__toNextPipeline_1_all;
    checks++;
    if (g_L2Cache__toNextPipeline_1_req !== i_L2Cache__toNextPipeline_1_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_req g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_req, i_L2Cache__toNextPipeline_1_req);
    end
    if (g_L2Cache__toNextPipeline_1_req !== p_L2Cache__toNextPipeline_1_req) t_L2Cache__toNextPipeline_1_req = 1'b1;
    p_L2Cache__toNextPipeline_1_req = g_L2Cache__toNextPipeline_1_req;
    checks++;
    if (g_L2Cache__toNextPipeline_1_writeen !== i_L2Cache__toNextPipeline_1_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_writeen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_writeen, i_L2Cache__toNextPipeline_1_writeen);
    end
    if (g_L2Cache__toNextPipeline_1_writeen !== p_L2Cache__toNextPipeline_1_writeen) t_L2Cache__toNextPipeline_1_writeen = 1'b1;
    p_L2Cache__toNextPipeline_1_writeen = g_L2Cache__toNextPipeline_1_writeen;
    checks++;
    if (g_L2Cache__toNextPipeline_1_be !== i_L2Cache__toNextPipeline_1_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_be g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_be, i_L2Cache__toNextPipeline_1_be);
    end
    if (g_L2Cache__toNextPipeline_1_be !== p_L2Cache__toNextPipeline_1_be) t_L2Cache__toNextPipeline_1_be = 1'b1;
    p_L2Cache__toNextPipeline_1_be = g_L2Cache__toNextPipeline_1_be;
    checks++;
    if (g_L2Cache__toNextPipeline_1_addr !== i_L2Cache__toNextPipeline_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_addr g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_addr, i_L2Cache__toNextPipeline_1_addr);
    end
    if (g_L2Cache__toNextPipeline_1_addr !== p_L2Cache__toNextPipeline_1_addr) t_L2Cache__toNextPipeline_1_addr = 1'b1;
    p_L2Cache__toNextPipeline_1_addr = g_L2Cache__toNextPipeline_1_addr;
    checks++;
    if (g_L2Cache__toNextPipeline_1_indata !== i_L2Cache__toNextPipeline_1_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_indata g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_indata, i_L2Cache__toNextPipeline_1_indata);
    end
    if (g_L2Cache__toNextPipeline_1_indata !== p_L2Cache__toNextPipeline_1_indata) t_L2Cache__toNextPipeline_1_indata = 1'b1;
    p_L2Cache__toNextPipeline_1_indata = g_L2Cache__toNextPipeline_1_indata;
    checks++;
    if (g_L2Cache__toNextPipeline_1_readen !== i_L2Cache__toNextPipeline_1_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_readen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_readen, i_L2Cache__toNextPipeline_1_readen);
    end
    if (g_L2Cache__toNextPipeline_1_readen !== p_L2Cache__toNextPipeline_1_readen) t_L2Cache__toNextPipeline_1_readen = 1'b1;
    p_L2Cache__toNextPipeline_1_readen = g_L2Cache__toNextPipeline_1_readen;
    checks++;
    if (g_L2Cache__toNextPipeline_1_addr_rd !== i_L2Cache__toNextPipeline_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_1_addr_rd g=%h i=%h", cyc, g_L2Cache__toNextPipeline_1_addr_rd, i_L2Cache__toNextPipeline_1_addr_rd);
    end
    if (g_L2Cache__toNextPipeline_1_addr_rd !== p_L2Cache__toNextPipeline_1_addr_rd) t_L2Cache__toNextPipeline_1_addr_rd = 1'b1;
    p_L2Cache__toNextPipeline_1_addr_rd = g_L2Cache__toNextPipeline_1_addr_rd;
    checks++;
    if (g_L2Cache__toNextPipeline_2_array !== i_L2Cache__toNextPipeline_2_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_array g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_array, i_L2Cache__toNextPipeline_2_array);
    end
    if (g_L2Cache__toNextPipeline_2_array !== p_L2Cache__toNextPipeline_2_array) t_L2Cache__toNextPipeline_2_array = 1'b1;
    p_L2Cache__toNextPipeline_2_array = g_L2Cache__toNextPipeline_2_array;
    checks++;
    if (g_L2Cache__toNextPipeline_2_all !== i_L2Cache__toNextPipeline_2_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_all g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_all, i_L2Cache__toNextPipeline_2_all);
    end
    if (g_L2Cache__toNextPipeline_2_all !== p_L2Cache__toNextPipeline_2_all) t_L2Cache__toNextPipeline_2_all = 1'b1;
    p_L2Cache__toNextPipeline_2_all = g_L2Cache__toNextPipeline_2_all;
    checks++;
    if (g_L2Cache__toNextPipeline_2_req !== i_L2Cache__toNextPipeline_2_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_req g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_req, i_L2Cache__toNextPipeline_2_req);
    end
    if (g_L2Cache__toNextPipeline_2_req !== p_L2Cache__toNextPipeline_2_req) t_L2Cache__toNextPipeline_2_req = 1'b1;
    p_L2Cache__toNextPipeline_2_req = g_L2Cache__toNextPipeline_2_req;
    checks++;
    if (g_L2Cache__toNextPipeline_2_writeen !== i_L2Cache__toNextPipeline_2_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_writeen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_writeen, i_L2Cache__toNextPipeline_2_writeen);
    end
    if (g_L2Cache__toNextPipeline_2_writeen !== p_L2Cache__toNextPipeline_2_writeen) t_L2Cache__toNextPipeline_2_writeen = 1'b1;
    p_L2Cache__toNextPipeline_2_writeen = g_L2Cache__toNextPipeline_2_writeen;
    checks++;
    if (g_L2Cache__toNextPipeline_2_be !== i_L2Cache__toNextPipeline_2_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_be g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_be, i_L2Cache__toNextPipeline_2_be);
    end
    if (g_L2Cache__toNextPipeline_2_be !== p_L2Cache__toNextPipeline_2_be) t_L2Cache__toNextPipeline_2_be = 1'b1;
    p_L2Cache__toNextPipeline_2_be = g_L2Cache__toNextPipeline_2_be;
    checks++;
    if (g_L2Cache__toNextPipeline_2_addr !== i_L2Cache__toNextPipeline_2_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_addr g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_addr, i_L2Cache__toNextPipeline_2_addr);
    end
    if (g_L2Cache__toNextPipeline_2_addr !== p_L2Cache__toNextPipeline_2_addr) t_L2Cache__toNextPipeline_2_addr = 1'b1;
    p_L2Cache__toNextPipeline_2_addr = g_L2Cache__toNextPipeline_2_addr;
    checks++;
    if (g_L2Cache__toNextPipeline_2_indata !== i_L2Cache__toNextPipeline_2_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_indata g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_indata, i_L2Cache__toNextPipeline_2_indata);
    end
    if (g_L2Cache__toNextPipeline_2_indata !== p_L2Cache__toNextPipeline_2_indata) t_L2Cache__toNextPipeline_2_indata = 1'b1;
    p_L2Cache__toNextPipeline_2_indata = g_L2Cache__toNextPipeline_2_indata;
    checks++;
    if (g_L2Cache__toNextPipeline_2_readen !== i_L2Cache__toNextPipeline_2_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_readen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_readen, i_L2Cache__toNextPipeline_2_readen);
    end
    if (g_L2Cache__toNextPipeline_2_readen !== p_L2Cache__toNextPipeline_2_readen) t_L2Cache__toNextPipeline_2_readen = 1'b1;
    p_L2Cache__toNextPipeline_2_readen = g_L2Cache__toNextPipeline_2_readen;
    checks++;
    if (g_L2Cache__toNextPipeline_2_addr_rd !== i_L2Cache__toNextPipeline_2_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_2_addr_rd g=%h i=%h", cyc, g_L2Cache__toNextPipeline_2_addr_rd, i_L2Cache__toNextPipeline_2_addr_rd);
    end
    if (g_L2Cache__toNextPipeline_2_addr_rd !== p_L2Cache__toNextPipeline_2_addr_rd) t_L2Cache__toNextPipeline_2_addr_rd = 1'b1;
    p_L2Cache__toNextPipeline_2_addr_rd = g_L2Cache__toNextPipeline_2_addr_rd;
    checks++;
    if (g_L2Cache__toNextPipeline_3_array !== i_L2Cache__toNextPipeline_3_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_array g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_array, i_L2Cache__toNextPipeline_3_array);
    end
    if (g_L2Cache__toNextPipeline_3_array !== p_L2Cache__toNextPipeline_3_array) t_L2Cache__toNextPipeline_3_array = 1'b1;
    p_L2Cache__toNextPipeline_3_array = g_L2Cache__toNextPipeline_3_array;
    checks++;
    if (g_L2Cache__toNextPipeline_3_all !== i_L2Cache__toNextPipeline_3_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_all g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_all, i_L2Cache__toNextPipeline_3_all);
    end
    if (g_L2Cache__toNextPipeline_3_all !== p_L2Cache__toNextPipeline_3_all) t_L2Cache__toNextPipeline_3_all = 1'b1;
    p_L2Cache__toNextPipeline_3_all = g_L2Cache__toNextPipeline_3_all;
    checks++;
    if (g_L2Cache__toNextPipeline_3_req !== i_L2Cache__toNextPipeline_3_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_req g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_req, i_L2Cache__toNextPipeline_3_req);
    end
    if (g_L2Cache__toNextPipeline_3_req !== p_L2Cache__toNextPipeline_3_req) t_L2Cache__toNextPipeline_3_req = 1'b1;
    p_L2Cache__toNextPipeline_3_req = g_L2Cache__toNextPipeline_3_req;
    checks++;
    if (g_L2Cache__toNextPipeline_3_writeen !== i_L2Cache__toNextPipeline_3_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_writeen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_writeen, i_L2Cache__toNextPipeline_3_writeen);
    end
    if (g_L2Cache__toNextPipeline_3_writeen !== p_L2Cache__toNextPipeline_3_writeen) t_L2Cache__toNextPipeline_3_writeen = 1'b1;
    p_L2Cache__toNextPipeline_3_writeen = g_L2Cache__toNextPipeline_3_writeen;
    checks++;
    if (g_L2Cache__toNextPipeline_3_be !== i_L2Cache__toNextPipeline_3_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_be g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_be, i_L2Cache__toNextPipeline_3_be);
    end
    if (g_L2Cache__toNextPipeline_3_be !== p_L2Cache__toNextPipeline_3_be) t_L2Cache__toNextPipeline_3_be = 1'b1;
    p_L2Cache__toNextPipeline_3_be = g_L2Cache__toNextPipeline_3_be;
    checks++;
    if (g_L2Cache__toNextPipeline_3_addr !== i_L2Cache__toNextPipeline_3_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_addr g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_addr, i_L2Cache__toNextPipeline_3_addr);
    end
    if (g_L2Cache__toNextPipeline_3_addr !== p_L2Cache__toNextPipeline_3_addr) t_L2Cache__toNextPipeline_3_addr = 1'b1;
    p_L2Cache__toNextPipeline_3_addr = g_L2Cache__toNextPipeline_3_addr;
    checks++;
    if (g_L2Cache__toNextPipeline_3_indata !== i_L2Cache__toNextPipeline_3_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_indata g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_indata, i_L2Cache__toNextPipeline_3_indata);
    end
    if (g_L2Cache__toNextPipeline_3_indata !== p_L2Cache__toNextPipeline_3_indata) t_L2Cache__toNextPipeline_3_indata = 1'b1;
    p_L2Cache__toNextPipeline_3_indata = g_L2Cache__toNextPipeline_3_indata;
    checks++;
    if (g_L2Cache__toNextPipeline_3_readen !== i_L2Cache__toNextPipeline_3_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_readen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_readen, i_L2Cache__toNextPipeline_3_readen);
    end
    if (g_L2Cache__toNextPipeline_3_readen !== p_L2Cache__toNextPipeline_3_readen) t_L2Cache__toNextPipeline_3_readen = 1'b1;
    p_L2Cache__toNextPipeline_3_readen = g_L2Cache__toNextPipeline_3_readen;
    checks++;
    if (g_L2Cache__toNextPipeline_3_addr_rd !== i_L2Cache__toNextPipeline_3_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_3_addr_rd g=%h i=%h", cyc, g_L2Cache__toNextPipeline_3_addr_rd, i_L2Cache__toNextPipeline_3_addr_rd);
    end
    if (g_L2Cache__toNextPipeline_3_addr_rd !== p_L2Cache__toNextPipeline_3_addr_rd) t_L2Cache__toNextPipeline_3_addr_rd = 1'b1;
    p_L2Cache__toNextPipeline_3_addr_rd = g_L2Cache__toNextPipeline_3_addr_rd;
    checks++;
    if (g_L2Cache__toNextPipeline_4_array !== i_L2Cache__toNextPipeline_4_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_array g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_array, i_L2Cache__toNextPipeline_4_array);
    end
    if (g_L2Cache__toNextPipeline_4_array !== p_L2Cache__toNextPipeline_4_array) t_L2Cache__toNextPipeline_4_array = 1'b1;
    p_L2Cache__toNextPipeline_4_array = g_L2Cache__toNextPipeline_4_array;
    checks++;
    if (g_L2Cache__toNextPipeline_4_all !== i_L2Cache__toNextPipeline_4_all) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_all g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_all, i_L2Cache__toNextPipeline_4_all);
    end
    if (g_L2Cache__toNextPipeline_4_all !== p_L2Cache__toNextPipeline_4_all) t_L2Cache__toNextPipeline_4_all = 1'b1;
    p_L2Cache__toNextPipeline_4_all = g_L2Cache__toNextPipeline_4_all;
    checks++;
    if (g_L2Cache__toNextPipeline_4_req !== i_L2Cache__toNextPipeline_4_req) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_req g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_req, i_L2Cache__toNextPipeline_4_req);
    end
    if (g_L2Cache__toNextPipeline_4_req !== p_L2Cache__toNextPipeline_4_req) t_L2Cache__toNextPipeline_4_req = 1'b1;
    p_L2Cache__toNextPipeline_4_req = g_L2Cache__toNextPipeline_4_req;
    checks++;
    if (g_L2Cache__toNextPipeline_4_writeen !== i_L2Cache__toNextPipeline_4_writeen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_writeen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_writeen, i_L2Cache__toNextPipeline_4_writeen);
    end
    if (g_L2Cache__toNextPipeline_4_writeen !== p_L2Cache__toNextPipeline_4_writeen) t_L2Cache__toNextPipeline_4_writeen = 1'b1;
    p_L2Cache__toNextPipeline_4_writeen = g_L2Cache__toNextPipeline_4_writeen;
    checks++;
    if (g_L2Cache__toNextPipeline_4_be !== i_L2Cache__toNextPipeline_4_be) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_be g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_be, i_L2Cache__toNextPipeline_4_be);
    end
    if (g_L2Cache__toNextPipeline_4_be !== p_L2Cache__toNextPipeline_4_be) t_L2Cache__toNextPipeline_4_be = 1'b1;
    p_L2Cache__toNextPipeline_4_be = g_L2Cache__toNextPipeline_4_be;
    checks++;
    if (g_L2Cache__toNextPipeline_4_addr !== i_L2Cache__toNextPipeline_4_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_addr g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_addr, i_L2Cache__toNextPipeline_4_addr);
    end
    if (g_L2Cache__toNextPipeline_4_addr !== p_L2Cache__toNextPipeline_4_addr) t_L2Cache__toNextPipeline_4_addr = 1'b1;
    p_L2Cache__toNextPipeline_4_addr = g_L2Cache__toNextPipeline_4_addr;
    checks++;
    if (g_L2Cache__toNextPipeline_4_indata !== i_L2Cache__toNextPipeline_4_indata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_indata g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_indata, i_L2Cache__toNextPipeline_4_indata);
    end
    if (g_L2Cache__toNextPipeline_4_indata !== p_L2Cache__toNextPipeline_4_indata) t_L2Cache__toNextPipeline_4_indata = 1'b1;
    p_L2Cache__toNextPipeline_4_indata = g_L2Cache__toNextPipeline_4_indata;
    checks++;
    if (g_L2Cache__toNextPipeline_4_readen !== i_L2Cache__toNextPipeline_4_readen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_readen g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_readen, i_L2Cache__toNextPipeline_4_readen);
    end
    if (g_L2Cache__toNextPipeline_4_readen !== p_L2Cache__toNextPipeline_4_readen) t_L2Cache__toNextPipeline_4_readen = 1'b1;
    p_L2Cache__toNextPipeline_4_readen = g_L2Cache__toNextPipeline_4_readen;
    checks++;
    if (g_L2Cache__toNextPipeline_4_addr_rd !== i_L2Cache__toNextPipeline_4_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Cache.toNextPipeline_4_addr_rd g=%h i=%h", cyc, g_L2Cache__toNextPipeline_4_addr_rd, i_L2Cache__toNextPipeline_4_addr_rd);
    end
    if (g_L2Cache__toNextPipeline_4_addr_rd !== p_L2Cache__toNextPipeline_4_addr_rd) t_L2Cache__toNextPipeline_4_addr_rd = 1'b1;
    p_L2Cache__toNextPipeline_4_addr_rd = g_L2Cache__toNextPipeline_4_addr_rd;
  endtask
  longint cov_L2Cache_sel0 = 0;
  longint cov_L2Cache_sel1 = 0;
  longint cov_L2Cache_sel2 = 0;
  longint cov_L2Cache_sel3 = 0;
  longint cov_L2Cache_sel4 = 0;
  longint cov_L2Cache_act = 0;
  task automatic cover_L2Cache();
    if (u_g_L2Cache.selected) cov_L2Cache_sel0++;
    if (u_g_L2Cache.selected_1) cov_L2Cache_sel1++;
    if (u_g_L2Cache.selected_2) cov_L2Cache_sel2++;
    if (u_g_L2Cache.selected_3) cov_L2Cache_sel3++;
    if (u_g_L2Cache.selected_4) cov_L2Cache_sel4++;
    if (u_g_L2Cache.activated) cov_L2Cache_act++;
  endtask
  task automatic preinit_L2Cache();
  endtask
  task automatic sync_L2Cache();
    force u_i_L2Cache.u_core.g_node_return.pipelineDataOutReg = u_g_L2Cache.pipelineDataOutReg;
    #0 release u_i_L2Cache.u_core.g_node_return.pipelineDataOutReg;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_L2Cache();
    #1;
    preinit_L2Cache();
    sync_L2Cache();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_L2Cache();
      #1;
      check_L2Cache();
      cover_L2Cache();
    end
    begin int tg; tg = 0;
      if (t_L2Cache__mbist_ack) tg++; else $display("COV: L2Cache.mbist_ack never toggled");
      if (t_L2Cache__mbist_outdata) tg++; else $display("COV: L2Cache.mbist_outdata never toggled");
      if (t_L2Cache__toNextPipeline_0_array) tg++; else $display("COV: L2Cache.toNextPipeline_0_array never toggled");
      if (t_L2Cache__toNextPipeline_0_all) tg++; else $display("COV: L2Cache.toNextPipeline_0_all never toggled");
      if (t_L2Cache__toNextPipeline_0_req) tg++; else $display("COV: L2Cache.toNextPipeline_0_req never toggled");
      if (t_L2Cache__toNextPipeline_0_writeen) tg++; else $display("COV: L2Cache.toNextPipeline_0_writeen never toggled");
      if (t_L2Cache__toNextPipeline_0_be) tg++; else $display("COV: L2Cache.toNextPipeline_0_be never toggled");
      if (t_L2Cache__toNextPipeline_0_addr) tg++; else $display("COV: L2Cache.toNextPipeline_0_addr never toggled");
      if (t_L2Cache__toNextPipeline_0_indata) tg++; else $display("COV: L2Cache.toNextPipeline_0_indata never toggled");
      if (t_L2Cache__toNextPipeline_0_readen) tg++; else $display("COV: L2Cache.toNextPipeline_0_readen never toggled");
      if (t_L2Cache__toNextPipeline_0_addr_rd) tg++; else $display("COV: L2Cache.toNextPipeline_0_addr_rd never toggled");
      if (t_L2Cache__toNextPipeline_1_array) tg++; else $display("COV: L2Cache.toNextPipeline_1_array never toggled");
      if (t_L2Cache__toNextPipeline_1_all) tg++; else $display("COV: L2Cache.toNextPipeline_1_all never toggled");
      if (t_L2Cache__toNextPipeline_1_req) tg++; else $display("COV: L2Cache.toNextPipeline_1_req never toggled");
      if (t_L2Cache__toNextPipeline_1_writeen) tg++; else $display("COV: L2Cache.toNextPipeline_1_writeen never toggled");
      if (t_L2Cache__toNextPipeline_1_be) tg++; else $display("COV: L2Cache.toNextPipeline_1_be never toggled");
      if (t_L2Cache__toNextPipeline_1_addr) tg++; else $display("COV: L2Cache.toNextPipeline_1_addr never toggled");
      if (t_L2Cache__toNextPipeline_1_indata) tg++; else $display("COV: L2Cache.toNextPipeline_1_indata never toggled");
      if (t_L2Cache__toNextPipeline_1_readen) tg++; else $display("COV: L2Cache.toNextPipeline_1_readen never toggled");
      if (t_L2Cache__toNextPipeline_1_addr_rd) tg++; else $display("COV: L2Cache.toNextPipeline_1_addr_rd never toggled");
      if (t_L2Cache__toNextPipeline_2_array) tg++; else $display("COV: L2Cache.toNextPipeline_2_array never toggled");
      if (t_L2Cache__toNextPipeline_2_all) tg++; else $display("COV: L2Cache.toNextPipeline_2_all never toggled");
      if (t_L2Cache__toNextPipeline_2_req) tg++; else $display("COV: L2Cache.toNextPipeline_2_req never toggled");
      if (t_L2Cache__toNextPipeline_2_writeen) tg++; else $display("COV: L2Cache.toNextPipeline_2_writeen never toggled");
      if (t_L2Cache__toNextPipeline_2_be) tg++; else $display("COV: L2Cache.toNextPipeline_2_be never toggled");
      if (t_L2Cache__toNextPipeline_2_addr) tg++; else $display("COV: L2Cache.toNextPipeline_2_addr never toggled");
      if (t_L2Cache__toNextPipeline_2_indata) tg++; else $display("COV: L2Cache.toNextPipeline_2_indata never toggled");
      if (t_L2Cache__toNextPipeline_2_readen) tg++; else $display("COV: L2Cache.toNextPipeline_2_readen never toggled");
      if (t_L2Cache__toNextPipeline_2_addr_rd) tg++; else $display("COV: L2Cache.toNextPipeline_2_addr_rd never toggled");
      if (t_L2Cache__toNextPipeline_3_array) tg++; else $display("COV: L2Cache.toNextPipeline_3_array never toggled");
      if (t_L2Cache__toNextPipeline_3_all) tg++; else $display("COV: L2Cache.toNextPipeline_3_all never toggled");
      if (t_L2Cache__toNextPipeline_3_req) tg++; else $display("COV: L2Cache.toNextPipeline_3_req never toggled");
      if (t_L2Cache__toNextPipeline_3_writeen) tg++; else $display("COV: L2Cache.toNextPipeline_3_writeen never toggled");
      if (t_L2Cache__toNextPipeline_3_be) tg++; else $display("COV: L2Cache.toNextPipeline_3_be never toggled");
      if (t_L2Cache__toNextPipeline_3_addr) tg++; else $display("COV: L2Cache.toNextPipeline_3_addr never toggled");
      if (t_L2Cache__toNextPipeline_3_indata) tg++; else $display("COV: L2Cache.toNextPipeline_3_indata never toggled");
      if (t_L2Cache__toNextPipeline_3_readen) tg++; else $display("COV: L2Cache.toNextPipeline_3_readen never toggled");
      if (t_L2Cache__toNextPipeline_3_addr_rd) tg++; else $display("COV: L2Cache.toNextPipeline_3_addr_rd never toggled");
      if (t_L2Cache__toNextPipeline_4_array) tg++; else $display("COV: L2Cache.toNextPipeline_4_array never toggled");
      if (t_L2Cache__toNextPipeline_4_all) tg++; else $display("COV: L2Cache.toNextPipeline_4_all never toggled");
      if (t_L2Cache__toNextPipeline_4_req) tg++; else $display("COV: L2Cache.toNextPipeline_4_req never toggled");
      if (t_L2Cache__toNextPipeline_4_writeen) tg++; else $display("COV: L2Cache.toNextPipeline_4_writeen never toggled");
      if (t_L2Cache__toNextPipeline_4_be) tg++; else $display("COV: L2Cache.toNextPipeline_4_be never toggled");
      if (t_L2Cache__toNextPipeline_4_addr) tg++; else $display("COV: L2Cache.toNextPipeline_4_addr never toggled");
      if (t_L2Cache__toNextPipeline_4_indata) tg++; else $display("COV: L2Cache.toNextPipeline_4_indata never toggled");
      if (t_L2Cache__toNextPipeline_4_readen) tg++; else $display("COV: L2Cache.toNextPipeline_4_readen never toggled");
      if (t_L2Cache__toNextPipeline_4_addr_rd) tg++; else $display("COV: L2Cache.toNextPipeline_4_addr_rd never toggled");
      $display("L2Cache: toggled=%0d/47 (need >= 47)", tg);
      if (tg < 47) covfail = 1;
      $display("L2Cache: cover sel0 = %0d", cov_L2Cache_sel0);
      if (cov_L2Cache_sel0 == 0) covfail = 1;
      $display("L2Cache: cover sel1 = %0d", cov_L2Cache_sel1);
      if (cov_L2Cache_sel1 == 0) covfail = 1;
      $display("L2Cache: cover sel2 = %0d", cov_L2Cache_sel2);
      if (cov_L2Cache_sel2 == 0) covfail = 1;
      $display("L2Cache: cover sel3 = %0d", cov_L2Cache_sel3);
      if (cov_L2Cache_sel3 == 0) covfail = 1;
      $display("L2Cache: cover sel4 = %0d", cov_L2Cache_sel4);
      if (cov_L2Cache_sel4 == 0) covfail = 1;
      $display("L2Cache: cover act = %0d", cov_L2Cache_act);
      if (cov_L2Cache_act == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
