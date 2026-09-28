// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：L2Directory_1 L2Directory_2 L2Directory_3
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

  // ======================= L2Directory_1 =======================
  logic [4:0] L2Directory_1__mbist_array;
  logic L2Directory_1__mbist_all;
  logic L2Directory_1__mbist_req;
  logic L2Directory_1__mbist_writeen;
  logic [7:0] L2Directory_1__mbist_be;
  logic [9:0] L2Directory_1__mbist_addr;
  logic [103:0] L2Directory_1__mbist_indata;
  logic L2Directory_1__mbist_readen;
  logic [9:0] L2Directory_1__mbist_addr_rd;
  logic [75:0] L2Directory_1__toSRAM_0_rdata;
  logic [75:0] L2Directory_1__toSRAM_1_rdata;
  logic [75:0] L2Directory_1__toSRAM_2_rdata;
  logic [75:0] L2Directory_1__toSRAM_3_rdata;
  logic [103:0] L2Directory_1__toSRAM_4_rdata;
  logic [15:0] L2Directory_1__toSRAM_5_rdata;
  logic [7:0] L2Directory_1__toSRAM_6_rdata;
  wire  g_L2Directory_1__mbist_ack;
  wire  i_L2Directory_1__mbist_ack;
  logic p_L2Directory_1__mbist_ack;
  bit   t_L2Directory_1__mbist_ack;
  wire  [103:0] g_L2Directory_1__mbist_outdata;
  wire  [103:0] i_L2Directory_1__mbist_outdata;
  logic [103:0] p_L2Directory_1__mbist_outdata;
  bit   t_L2Directory_1__mbist_outdata;
  wire  [9:0] g_L2Directory_1__toSRAM_0_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_0_addr;
  logic [9:0] p_L2Directory_1__toSRAM_0_addr;
  bit   t_L2Directory_1__toSRAM_0_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_0_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_0_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_0_addr_rd;
  bit   t_L2Directory_1__toSRAM_0_addr_rd;
  wire  [75:0] g_L2Directory_1__toSRAM_0_wdata;
  wire  [75:0] i_L2Directory_1__toSRAM_0_wdata;
  logic [75:0] p_L2Directory_1__toSRAM_0_wdata;
  bit   t_L2Directory_1__toSRAM_0_wdata;
  wire  [3:0] g_L2Directory_1__toSRAM_0_wmask;
  wire  [3:0] i_L2Directory_1__toSRAM_0_wmask;
  logic [3:0] p_L2Directory_1__toSRAM_0_wmask;
  bit   t_L2Directory_1__toSRAM_0_wmask;
  wire  g_L2Directory_1__toSRAM_0_re;
  wire  i_L2Directory_1__toSRAM_0_re;
  logic p_L2Directory_1__toSRAM_0_re;
  bit   t_L2Directory_1__toSRAM_0_re;
  wire  g_L2Directory_1__toSRAM_0_we;
  wire  i_L2Directory_1__toSRAM_0_we;
  logic p_L2Directory_1__toSRAM_0_we;
  bit   t_L2Directory_1__toSRAM_0_we;
  wire  g_L2Directory_1__toSRAM_0_ack;
  wire  i_L2Directory_1__toSRAM_0_ack;
  logic p_L2Directory_1__toSRAM_0_ack;
  bit   t_L2Directory_1__toSRAM_0_ack;
  wire  g_L2Directory_1__toSRAM_0_selectedOH;
  wire  i_L2Directory_1__toSRAM_0_selectedOH;
  logic p_L2Directory_1__toSRAM_0_selectedOH;
  bit   t_L2Directory_1__toSRAM_0_selectedOH;
  wire  [3:0] g_L2Directory_1__toSRAM_0_array;
  wire  [3:0] i_L2Directory_1__toSRAM_0_array;
  logic [3:0] p_L2Directory_1__toSRAM_0_array;
  bit   t_L2Directory_1__toSRAM_0_array;
  wire  [9:0] g_L2Directory_1__toSRAM_1_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_1_addr;
  logic [9:0] p_L2Directory_1__toSRAM_1_addr;
  bit   t_L2Directory_1__toSRAM_1_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_1_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_1_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_1_addr_rd;
  bit   t_L2Directory_1__toSRAM_1_addr_rd;
  wire  [75:0] g_L2Directory_1__toSRAM_1_wdata;
  wire  [75:0] i_L2Directory_1__toSRAM_1_wdata;
  logic [75:0] p_L2Directory_1__toSRAM_1_wdata;
  bit   t_L2Directory_1__toSRAM_1_wdata;
  wire  [3:0] g_L2Directory_1__toSRAM_1_wmask;
  wire  [3:0] i_L2Directory_1__toSRAM_1_wmask;
  logic [3:0] p_L2Directory_1__toSRAM_1_wmask;
  bit   t_L2Directory_1__toSRAM_1_wmask;
  wire  g_L2Directory_1__toSRAM_1_re;
  wire  i_L2Directory_1__toSRAM_1_re;
  logic p_L2Directory_1__toSRAM_1_re;
  bit   t_L2Directory_1__toSRAM_1_re;
  wire  g_L2Directory_1__toSRAM_1_we;
  wire  i_L2Directory_1__toSRAM_1_we;
  logic p_L2Directory_1__toSRAM_1_we;
  bit   t_L2Directory_1__toSRAM_1_we;
  wire  g_L2Directory_1__toSRAM_1_ack;
  wire  i_L2Directory_1__toSRAM_1_ack;
  logic p_L2Directory_1__toSRAM_1_ack;
  bit   t_L2Directory_1__toSRAM_1_ack;
  wire  g_L2Directory_1__toSRAM_1_selectedOH;
  wire  i_L2Directory_1__toSRAM_1_selectedOH;
  logic p_L2Directory_1__toSRAM_1_selectedOH;
  bit   t_L2Directory_1__toSRAM_1_selectedOH;
  wire  [3:0] g_L2Directory_1__toSRAM_1_array;
  wire  [3:0] i_L2Directory_1__toSRAM_1_array;
  logic [3:0] p_L2Directory_1__toSRAM_1_array;
  bit   t_L2Directory_1__toSRAM_1_array;
  wire  [9:0] g_L2Directory_1__toSRAM_2_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_2_addr;
  logic [9:0] p_L2Directory_1__toSRAM_2_addr;
  bit   t_L2Directory_1__toSRAM_2_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_2_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_2_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_2_addr_rd;
  bit   t_L2Directory_1__toSRAM_2_addr_rd;
  wire  [75:0] g_L2Directory_1__toSRAM_2_wdata;
  wire  [75:0] i_L2Directory_1__toSRAM_2_wdata;
  logic [75:0] p_L2Directory_1__toSRAM_2_wdata;
  bit   t_L2Directory_1__toSRAM_2_wdata;
  wire  [3:0] g_L2Directory_1__toSRAM_2_wmask;
  wire  [3:0] i_L2Directory_1__toSRAM_2_wmask;
  logic [3:0] p_L2Directory_1__toSRAM_2_wmask;
  bit   t_L2Directory_1__toSRAM_2_wmask;
  wire  g_L2Directory_1__toSRAM_2_re;
  wire  i_L2Directory_1__toSRAM_2_re;
  logic p_L2Directory_1__toSRAM_2_re;
  bit   t_L2Directory_1__toSRAM_2_re;
  wire  g_L2Directory_1__toSRAM_2_we;
  wire  i_L2Directory_1__toSRAM_2_we;
  logic p_L2Directory_1__toSRAM_2_we;
  bit   t_L2Directory_1__toSRAM_2_we;
  wire  g_L2Directory_1__toSRAM_2_ack;
  wire  i_L2Directory_1__toSRAM_2_ack;
  logic p_L2Directory_1__toSRAM_2_ack;
  bit   t_L2Directory_1__toSRAM_2_ack;
  wire  g_L2Directory_1__toSRAM_2_selectedOH;
  wire  i_L2Directory_1__toSRAM_2_selectedOH;
  logic p_L2Directory_1__toSRAM_2_selectedOH;
  bit   t_L2Directory_1__toSRAM_2_selectedOH;
  wire  [3:0] g_L2Directory_1__toSRAM_2_array;
  wire  [3:0] i_L2Directory_1__toSRAM_2_array;
  logic [3:0] p_L2Directory_1__toSRAM_2_array;
  bit   t_L2Directory_1__toSRAM_2_array;
  wire  [9:0] g_L2Directory_1__toSRAM_3_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_3_addr;
  logic [9:0] p_L2Directory_1__toSRAM_3_addr;
  bit   t_L2Directory_1__toSRAM_3_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_3_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_3_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_3_addr_rd;
  bit   t_L2Directory_1__toSRAM_3_addr_rd;
  wire  [75:0] g_L2Directory_1__toSRAM_3_wdata;
  wire  [75:0] i_L2Directory_1__toSRAM_3_wdata;
  logic [75:0] p_L2Directory_1__toSRAM_3_wdata;
  bit   t_L2Directory_1__toSRAM_3_wdata;
  wire  [3:0] g_L2Directory_1__toSRAM_3_wmask;
  wire  [3:0] i_L2Directory_1__toSRAM_3_wmask;
  logic [3:0] p_L2Directory_1__toSRAM_3_wmask;
  bit   t_L2Directory_1__toSRAM_3_wmask;
  wire  g_L2Directory_1__toSRAM_3_re;
  wire  i_L2Directory_1__toSRAM_3_re;
  logic p_L2Directory_1__toSRAM_3_re;
  bit   t_L2Directory_1__toSRAM_3_re;
  wire  g_L2Directory_1__toSRAM_3_we;
  wire  i_L2Directory_1__toSRAM_3_we;
  logic p_L2Directory_1__toSRAM_3_we;
  bit   t_L2Directory_1__toSRAM_3_we;
  wire  g_L2Directory_1__toSRAM_3_ack;
  wire  i_L2Directory_1__toSRAM_3_ack;
  logic p_L2Directory_1__toSRAM_3_ack;
  bit   t_L2Directory_1__toSRAM_3_ack;
  wire  g_L2Directory_1__toSRAM_3_selectedOH;
  wire  i_L2Directory_1__toSRAM_3_selectedOH;
  logic p_L2Directory_1__toSRAM_3_selectedOH;
  bit   t_L2Directory_1__toSRAM_3_selectedOH;
  wire  [4:0] g_L2Directory_1__toSRAM_3_array;
  wire  [4:0] i_L2Directory_1__toSRAM_3_array;
  logic [4:0] p_L2Directory_1__toSRAM_3_array;
  bit   t_L2Directory_1__toSRAM_3_array;
  wire  [9:0] g_L2Directory_1__toSRAM_4_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_4_addr;
  logic [9:0] p_L2Directory_1__toSRAM_4_addr;
  bit   t_L2Directory_1__toSRAM_4_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_4_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_4_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_4_addr_rd;
  bit   t_L2Directory_1__toSRAM_4_addr_rd;
  wire  [103:0] g_L2Directory_1__toSRAM_4_wdata;
  wire  [103:0] i_L2Directory_1__toSRAM_4_wdata;
  logic [103:0] p_L2Directory_1__toSRAM_4_wdata;
  bit   t_L2Directory_1__toSRAM_4_wdata;
  wire  [7:0] g_L2Directory_1__toSRAM_4_wmask;
  wire  [7:0] i_L2Directory_1__toSRAM_4_wmask;
  logic [7:0] p_L2Directory_1__toSRAM_4_wmask;
  bit   t_L2Directory_1__toSRAM_4_wmask;
  wire  g_L2Directory_1__toSRAM_4_re;
  wire  i_L2Directory_1__toSRAM_4_re;
  logic p_L2Directory_1__toSRAM_4_re;
  bit   t_L2Directory_1__toSRAM_4_re;
  wire  g_L2Directory_1__toSRAM_4_we;
  wire  i_L2Directory_1__toSRAM_4_we;
  logic p_L2Directory_1__toSRAM_4_we;
  bit   t_L2Directory_1__toSRAM_4_we;
  wire  g_L2Directory_1__toSRAM_4_ack;
  wire  i_L2Directory_1__toSRAM_4_ack;
  logic p_L2Directory_1__toSRAM_4_ack;
  bit   t_L2Directory_1__toSRAM_4_ack;
  wire  g_L2Directory_1__toSRAM_4_selectedOH;
  wire  i_L2Directory_1__toSRAM_4_selectedOH;
  logic p_L2Directory_1__toSRAM_4_selectedOH;
  bit   t_L2Directory_1__toSRAM_4_selectedOH;
  wire  [4:0] g_L2Directory_1__toSRAM_4_array;
  wire  [4:0] i_L2Directory_1__toSRAM_4_array;
  logic [4:0] p_L2Directory_1__toSRAM_4_array;
  bit   t_L2Directory_1__toSRAM_4_array;
  wire  [9:0] g_L2Directory_1__toSRAM_5_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_5_addr;
  logic [9:0] p_L2Directory_1__toSRAM_5_addr;
  bit   t_L2Directory_1__toSRAM_5_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_5_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_5_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_5_addr_rd;
  bit   t_L2Directory_1__toSRAM_5_addr_rd;
  wire  [15:0] g_L2Directory_1__toSRAM_5_wdata;
  wire  [15:0] i_L2Directory_1__toSRAM_5_wdata;
  logic [15:0] p_L2Directory_1__toSRAM_5_wdata;
  bit   t_L2Directory_1__toSRAM_5_wdata;
  wire  g_L2Directory_1__toSRAM_5_wmask;
  wire  i_L2Directory_1__toSRAM_5_wmask;
  logic p_L2Directory_1__toSRAM_5_wmask;
  bit   t_L2Directory_1__toSRAM_5_wmask;
  wire  g_L2Directory_1__toSRAM_5_re;
  wire  i_L2Directory_1__toSRAM_5_re;
  logic p_L2Directory_1__toSRAM_5_re;
  bit   t_L2Directory_1__toSRAM_5_re;
  wire  g_L2Directory_1__toSRAM_5_we;
  wire  i_L2Directory_1__toSRAM_5_we;
  logic p_L2Directory_1__toSRAM_5_we;
  bit   t_L2Directory_1__toSRAM_5_we;
  wire  g_L2Directory_1__toSRAM_5_ack;
  wire  i_L2Directory_1__toSRAM_5_ack;
  logic p_L2Directory_1__toSRAM_5_ack;
  bit   t_L2Directory_1__toSRAM_5_ack;
  wire  g_L2Directory_1__toSRAM_5_selectedOH;
  wire  i_L2Directory_1__toSRAM_5_selectedOH;
  logic p_L2Directory_1__toSRAM_5_selectedOH;
  bit   t_L2Directory_1__toSRAM_5_selectedOH;
  wire  [4:0] g_L2Directory_1__toSRAM_5_array;
  wire  [4:0] i_L2Directory_1__toSRAM_5_array;
  logic [4:0] p_L2Directory_1__toSRAM_5_array;
  bit   t_L2Directory_1__toSRAM_5_array;
  wire  [9:0] g_L2Directory_1__toSRAM_6_addr;
  wire  [9:0] i_L2Directory_1__toSRAM_6_addr;
  logic [9:0] p_L2Directory_1__toSRAM_6_addr;
  bit   t_L2Directory_1__toSRAM_6_addr;
  wire  [9:0] g_L2Directory_1__toSRAM_6_addr_rd;
  wire  [9:0] i_L2Directory_1__toSRAM_6_addr_rd;
  logic [9:0] p_L2Directory_1__toSRAM_6_addr_rd;
  bit   t_L2Directory_1__toSRAM_6_addr_rd;
  wire  [7:0] g_L2Directory_1__toSRAM_6_wdata;
  wire  [7:0] i_L2Directory_1__toSRAM_6_wdata;
  logic [7:0] p_L2Directory_1__toSRAM_6_wdata;
  bit   t_L2Directory_1__toSRAM_6_wdata;
  wire  [7:0] g_L2Directory_1__toSRAM_6_wmask;
  wire  [7:0] i_L2Directory_1__toSRAM_6_wmask;
  logic [7:0] p_L2Directory_1__toSRAM_6_wmask;
  bit   t_L2Directory_1__toSRAM_6_wmask;
  wire  g_L2Directory_1__toSRAM_6_re;
  wire  i_L2Directory_1__toSRAM_6_re;
  logic p_L2Directory_1__toSRAM_6_re;
  bit   t_L2Directory_1__toSRAM_6_re;
  wire  g_L2Directory_1__toSRAM_6_we;
  wire  i_L2Directory_1__toSRAM_6_we;
  logic p_L2Directory_1__toSRAM_6_we;
  bit   t_L2Directory_1__toSRAM_6_we;
  wire  g_L2Directory_1__toSRAM_6_ack;
  wire  i_L2Directory_1__toSRAM_6_ack;
  logic p_L2Directory_1__toSRAM_6_ack;
  bit   t_L2Directory_1__toSRAM_6_ack;
  wire  g_L2Directory_1__toSRAM_6_selectedOH;
  wire  i_L2Directory_1__toSRAM_6_selectedOH;
  logic p_L2Directory_1__toSRAM_6_selectedOH;
  bit   t_L2Directory_1__toSRAM_6_selectedOH;
  wire  [4:0] g_L2Directory_1__toSRAM_6_array;
  wire  [4:0] i_L2Directory_1__toSRAM_6_array;
  logic [4:0] p_L2Directory_1__toSRAM_6_array;
  bit   t_L2Directory_1__toSRAM_6_array;
  L2Directory_1 u_g_L2Directory_1 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_1__mbist_array),
    .mbist_all (L2Directory_1__mbist_all),
    .mbist_req (L2Directory_1__mbist_req),
    .mbist_ack (g_L2Directory_1__mbist_ack),
    .mbist_writeen (L2Directory_1__mbist_writeen),
    .mbist_be (L2Directory_1__mbist_be),
    .mbist_addr (L2Directory_1__mbist_addr),
    .mbist_indata (L2Directory_1__mbist_indata),
    .mbist_readen (L2Directory_1__mbist_readen),
    .mbist_addr_rd (L2Directory_1__mbist_addr_rd),
    .mbist_outdata (g_L2Directory_1__mbist_outdata),
    .toSRAM_0_addr (g_L2Directory_1__toSRAM_0_addr),
    .toSRAM_0_addr_rd (g_L2Directory_1__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g_L2Directory_1__toSRAM_0_wdata),
    .toSRAM_0_wmask (g_L2Directory_1__toSRAM_0_wmask),
    .toSRAM_0_re (g_L2Directory_1__toSRAM_0_re),
    .toSRAM_0_we (g_L2Directory_1__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_1__toSRAM_0_rdata),
    .toSRAM_0_ack (g_L2Directory_1__toSRAM_0_ack),
    .toSRAM_0_selectedOH (g_L2Directory_1__toSRAM_0_selectedOH),
    .toSRAM_0_array (g_L2Directory_1__toSRAM_0_array),
    .toSRAM_1_addr (g_L2Directory_1__toSRAM_1_addr),
    .toSRAM_1_addr_rd (g_L2Directory_1__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g_L2Directory_1__toSRAM_1_wdata),
    .toSRAM_1_wmask (g_L2Directory_1__toSRAM_1_wmask),
    .toSRAM_1_re (g_L2Directory_1__toSRAM_1_re),
    .toSRAM_1_we (g_L2Directory_1__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_1__toSRAM_1_rdata),
    .toSRAM_1_ack (g_L2Directory_1__toSRAM_1_ack),
    .toSRAM_1_selectedOH (g_L2Directory_1__toSRAM_1_selectedOH),
    .toSRAM_1_array (g_L2Directory_1__toSRAM_1_array),
    .toSRAM_2_addr (g_L2Directory_1__toSRAM_2_addr),
    .toSRAM_2_addr_rd (g_L2Directory_1__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g_L2Directory_1__toSRAM_2_wdata),
    .toSRAM_2_wmask (g_L2Directory_1__toSRAM_2_wmask),
    .toSRAM_2_re (g_L2Directory_1__toSRAM_2_re),
    .toSRAM_2_we (g_L2Directory_1__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_1__toSRAM_2_rdata),
    .toSRAM_2_ack (g_L2Directory_1__toSRAM_2_ack),
    .toSRAM_2_selectedOH (g_L2Directory_1__toSRAM_2_selectedOH),
    .toSRAM_2_array (g_L2Directory_1__toSRAM_2_array),
    .toSRAM_3_addr (g_L2Directory_1__toSRAM_3_addr),
    .toSRAM_3_addr_rd (g_L2Directory_1__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g_L2Directory_1__toSRAM_3_wdata),
    .toSRAM_3_wmask (g_L2Directory_1__toSRAM_3_wmask),
    .toSRAM_3_re (g_L2Directory_1__toSRAM_3_re),
    .toSRAM_3_we (g_L2Directory_1__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_1__toSRAM_3_rdata),
    .toSRAM_3_ack (g_L2Directory_1__toSRAM_3_ack),
    .toSRAM_3_selectedOH (g_L2Directory_1__toSRAM_3_selectedOH),
    .toSRAM_3_array (g_L2Directory_1__toSRAM_3_array),
    .toSRAM_4_addr (g_L2Directory_1__toSRAM_4_addr),
    .toSRAM_4_addr_rd (g_L2Directory_1__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g_L2Directory_1__toSRAM_4_wdata),
    .toSRAM_4_wmask (g_L2Directory_1__toSRAM_4_wmask),
    .toSRAM_4_re (g_L2Directory_1__toSRAM_4_re),
    .toSRAM_4_we (g_L2Directory_1__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_1__toSRAM_4_rdata),
    .toSRAM_4_ack (g_L2Directory_1__toSRAM_4_ack),
    .toSRAM_4_selectedOH (g_L2Directory_1__toSRAM_4_selectedOH),
    .toSRAM_4_array (g_L2Directory_1__toSRAM_4_array),
    .toSRAM_5_addr (g_L2Directory_1__toSRAM_5_addr),
    .toSRAM_5_addr_rd (g_L2Directory_1__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g_L2Directory_1__toSRAM_5_wdata),
    .toSRAM_5_wmask (g_L2Directory_1__toSRAM_5_wmask),
    .toSRAM_5_re (g_L2Directory_1__toSRAM_5_re),
    .toSRAM_5_we (g_L2Directory_1__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_1__toSRAM_5_rdata),
    .toSRAM_5_ack (g_L2Directory_1__toSRAM_5_ack),
    .toSRAM_5_selectedOH (g_L2Directory_1__toSRAM_5_selectedOH),
    .toSRAM_5_array (g_L2Directory_1__toSRAM_5_array),
    .toSRAM_6_addr (g_L2Directory_1__toSRAM_6_addr),
    .toSRAM_6_addr_rd (g_L2Directory_1__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g_L2Directory_1__toSRAM_6_wdata),
    .toSRAM_6_wmask (g_L2Directory_1__toSRAM_6_wmask),
    .toSRAM_6_re (g_L2Directory_1__toSRAM_6_re),
    .toSRAM_6_we (g_L2Directory_1__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_1__toSRAM_6_rdata),
    .toSRAM_6_ack (g_L2Directory_1__toSRAM_6_ack),
    .toSRAM_6_selectedOH (g_L2Directory_1__toSRAM_6_selectedOH),
    .toSRAM_6_array (g_L2Directory_1__toSRAM_6_array)
  );
  L2Directory_1_xs u_i_L2Directory_1 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_1__mbist_array),
    .mbist_all (L2Directory_1__mbist_all),
    .mbist_req (L2Directory_1__mbist_req),
    .mbist_ack (i_L2Directory_1__mbist_ack),
    .mbist_writeen (L2Directory_1__mbist_writeen),
    .mbist_be (L2Directory_1__mbist_be),
    .mbist_addr (L2Directory_1__mbist_addr),
    .mbist_indata (L2Directory_1__mbist_indata),
    .mbist_readen (L2Directory_1__mbist_readen),
    .mbist_addr_rd (L2Directory_1__mbist_addr_rd),
    .mbist_outdata (i_L2Directory_1__mbist_outdata),
    .toSRAM_0_addr (i_L2Directory_1__toSRAM_0_addr),
    .toSRAM_0_addr_rd (i_L2Directory_1__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (i_L2Directory_1__toSRAM_0_wdata),
    .toSRAM_0_wmask (i_L2Directory_1__toSRAM_0_wmask),
    .toSRAM_0_re (i_L2Directory_1__toSRAM_0_re),
    .toSRAM_0_we (i_L2Directory_1__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_1__toSRAM_0_rdata),
    .toSRAM_0_ack (i_L2Directory_1__toSRAM_0_ack),
    .toSRAM_0_selectedOH (i_L2Directory_1__toSRAM_0_selectedOH),
    .toSRAM_0_array (i_L2Directory_1__toSRAM_0_array),
    .toSRAM_1_addr (i_L2Directory_1__toSRAM_1_addr),
    .toSRAM_1_addr_rd (i_L2Directory_1__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (i_L2Directory_1__toSRAM_1_wdata),
    .toSRAM_1_wmask (i_L2Directory_1__toSRAM_1_wmask),
    .toSRAM_1_re (i_L2Directory_1__toSRAM_1_re),
    .toSRAM_1_we (i_L2Directory_1__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_1__toSRAM_1_rdata),
    .toSRAM_1_ack (i_L2Directory_1__toSRAM_1_ack),
    .toSRAM_1_selectedOH (i_L2Directory_1__toSRAM_1_selectedOH),
    .toSRAM_1_array (i_L2Directory_1__toSRAM_1_array),
    .toSRAM_2_addr (i_L2Directory_1__toSRAM_2_addr),
    .toSRAM_2_addr_rd (i_L2Directory_1__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (i_L2Directory_1__toSRAM_2_wdata),
    .toSRAM_2_wmask (i_L2Directory_1__toSRAM_2_wmask),
    .toSRAM_2_re (i_L2Directory_1__toSRAM_2_re),
    .toSRAM_2_we (i_L2Directory_1__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_1__toSRAM_2_rdata),
    .toSRAM_2_ack (i_L2Directory_1__toSRAM_2_ack),
    .toSRAM_2_selectedOH (i_L2Directory_1__toSRAM_2_selectedOH),
    .toSRAM_2_array (i_L2Directory_1__toSRAM_2_array),
    .toSRAM_3_addr (i_L2Directory_1__toSRAM_3_addr),
    .toSRAM_3_addr_rd (i_L2Directory_1__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (i_L2Directory_1__toSRAM_3_wdata),
    .toSRAM_3_wmask (i_L2Directory_1__toSRAM_3_wmask),
    .toSRAM_3_re (i_L2Directory_1__toSRAM_3_re),
    .toSRAM_3_we (i_L2Directory_1__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_1__toSRAM_3_rdata),
    .toSRAM_3_ack (i_L2Directory_1__toSRAM_3_ack),
    .toSRAM_3_selectedOH (i_L2Directory_1__toSRAM_3_selectedOH),
    .toSRAM_3_array (i_L2Directory_1__toSRAM_3_array),
    .toSRAM_4_addr (i_L2Directory_1__toSRAM_4_addr),
    .toSRAM_4_addr_rd (i_L2Directory_1__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (i_L2Directory_1__toSRAM_4_wdata),
    .toSRAM_4_wmask (i_L2Directory_1__toSRAM_4_wmask),
    .toSRAM_4_re (i_L2Directory_1__toSRAM_4_re),
    .toSRAM_4_we (i_L2Directory_1__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_1__toSRAM_4_rdata),
    .toSRAM_4_ack (i_L2Directory_1__toSRAM_4_ack),
    .toSRAM_4_selectedOH (i_L2Directory_1__toSRAM_4_selectedOH),
    .toSRAM_4_array (i_L2Directory_1__toSRAM_4_array),
    .toSRAM_5_addr (i_L2Directory_1__toSRAM_5_addr),
    .toSRAM_5_addr_rd (i_L2Directory_1__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (i_L2Directory_1__toSRAM_5_wdata),
    .toSRAM_5_wmask (i_L2Directory_1__toSRAM_5_wmask),
    .toSRAM_5_re (i_L2Directory_1__toSRAM_5_re),
    .toSRAM_5_we (i_L2Directory_1__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_1__toSRAM_5_rdata),
    .toSRAM_5_ack (i_L2Directory_1__toSRAM_5_ack),
    .toSRAM_5_selectedOH (i_L2Directory_1__toSRAM_5_selectedOH),
    .toSRAM_5_array (i_L2Directory_1__toSRAM_5_array),
    .toSRAM_6_addr (i_L2Directory_1__toSRAM_6_addr),
    .toSRAM_6_addr_rd (i_L2Directory_1__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (i_L2Directory_1__toSRAM_6_wdata),
    .toSRAM_6_wmask (i_L2Directory_1__toSRAM_6_wmask),
    .toSRAM_6_re (i_L2Directory_1__toSRAM_6_re),
    .toSRAM_6_we (i_L2Directory_1__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_1__toSRAM_6_rdata),
    .toSRAM_6_ack (i_L2Directory_1__toSRAM_6_ack),
    .toSRAM_6_selectedOH (i_L2Directory_1__toSRAM_6_selectedOH),
    .toSRAM_6_array (i_L2Directory_1__toSRAM_6_array)
  );
  task automatic drive_L2Directory_1();
    L2Directory_1__mbist_array = rnd(5);
    L2Directory_1__mbist_all = $urandom % 2;
    L2Directory_1__mbist_req = $urandom % 2;
    L2Directory_1__mbist_writeen = $urandom % 2;
    L2Directory_1__mbist_be = rnd(8);
    L2Directory_1__mbist_addr = rnd(10);
    L2Directory_1__mbist_indata = rnd(104);
    L2Directory_1__mbist_readen = $urandom % 2;
    L2Directory_1__mbist_addr_rd = rnd(10);
    L2Directory_1__toSRAM_0_rdata = rnd(76);
    L2Directory_1__toSRAM_1_rdata = rnd(76);
    L2Directory_1__toSRAM_2_rdata = rnd(76);
    L2Directory_1__toSRAM_3_rdata = rnd(76);
    L2Directory_1__toSRAM_4_rdata = rnd(104);
    L2Directory_1__toSRAM_5_rdata = rnd(16);
    L2Directory_1__toSRAM_6_rdata = rnd(8);
  endtask
  task automatic check_L2Directory_1();
    checks++;
    if (g_L2Directory_1__mbist_ack !== i_L2Directory_1__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.mbist_ack g=%h i=%h", cyc, g_L2Directory_1__mbist_ack, i_L2Directory_1__mbist_ack);
    end
    if (g_L2Directory_1__mbist_ack !== p_L2Directory_1__mbist_ack) t_L2Directory_1__mbist_ack = 1'b1;
    p_L2Directory_1__mbist_ack = g_L2Directory_1__mbist_ack;
    checks++;
    if (g_L2Directory_1__mbist_outdata !== i_L2Directory_1__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.mbist_outdata g=%h i=%h", cyc, g_L2Directory_1__mbist_outdata, i_L2Directory_1__mbist_outdata);
    end
    if (g_L2Directory_1__mbist_outdata !== p_L2Directory_1__mbist_outdata) t_L2Directory_1__mbist_outdata = 1'b1;
    p_L2Directory_1__mbist_outdata = g_L2Directory_1__mbist_outdata;
    checks++;
    if (g_L2Directory_1__toSRAM_0_addr !== i_L2Directory_1__toSRAM_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_addr, i_L2Directory_1__toSRAM_0_addr);
    end
    if (g_L2Directory_1__toSRAM_0_addr !== p_L2Directory_1__toSRAM_0_addr) t_L2Directory_1__toSRAM_0_addr = 1'b1;
    p_L2Directory_1__toSRAM_0_addr = g_L2Directory_1__toSRAM_0_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_0_addr_rd !== i_L2Directory_1__toSRAM_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_addr_rd, i_L2Directory_1__toSRAM_0_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_0_addr_rd !== p_L2Directory_1__toSRAM_0_addr_rd) t_L2Directory_1__toSRAM_0_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_0_addr_rd = g_L2Directory_1__toSRAM_0_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_0_wdata !== i_L2Directory_1__toSRAM_0_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_wdata, i_L2Directory_1__toSRAM_0_wdata);
    end
    if (g_L2Directory_1__toSRAM_0_wdata !== p_L2Directory_1__toSRAM_0_wdata) t_L2Directory_1__toSRAM_0_wdata = 1'b1;
    p_L2Directory_1__toSRAM_0_wdata = g_L2Directory_1__toSRAM_0_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_0_wmask !== i_L2Directory_1__toSRAM_0_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_wmask, i_L2Directory_1__toSRAM_0_wmask);
    end
    if (g_L2Directory_1__toSRAM_0_wmask !== p_L2Directory_1__toSRAM_0_wmask) t_L2Directory_1__toSRAM_0_wmask = 1'b1;
    p_L2Directory_1__toSRAM_0_wmask = g_L2Directory_1__toSRAM_0_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_0_re !== i_L2Directory_1__toSRAM_0_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_re, i_L2Directory_1__toSRAM_0_re);
    end
    if (g_L2Directory_1__toSRAM_0_re !== p_L2Directory_1__toSRAM_0_re) t_L2Directory_1__toSRAM_0_re = 1'b1;
    p_L2Directory_1__toSRAM_0_re = g_L2Directory_1__toSRAM_0_re;
    checks++;
    if (g_L2Directory_1__toSRAM_0_we !== i_L2Directory_1__toSRAM_0_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_we, i_L2Directory_1__toSRAM_0_we);
    end
    if (g_L2Directory_1__toSRAM_0_we !== p_L2Directory_1__toSRAM_0_we) t_L2Directory_1__toSRAM_0_we = 1'b1;
    p_L2Directory_1__toSRAM_0_we = g_L2Directory_1__toSRAM_0_we;
    checks++;
    if (g_L2Directory_1__toSRAM_0_ack !== i_L2Directory_1__toSRAM_0_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_ack, i_L2Directory_1__toSRAM_0_ack);
    end
    if (g_L2Directory_1__toSRAM_0_ack !== p_L2Directory_1__toSRAM_0_ack) t_L2Directory_1__toSRAM_0_ack = 1'b1;
    p_L2Directory_1__toSRAM_0_ack = g_L2Directory_1__toSRAM_0_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_0_selectedOH !== i_L2Directory_1__toSRAM_0_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_selectedOH, i_L2Directory_1__toSRAM_0_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_0_selectedOH !== p_L2Directory_1__toSRAM_0_selectedOH) t_L2Directory_1__toSRAM_0_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_0_selectedOH = g_L2Directory_1__toSRAM_0_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_0_array !== i_L2Directory_1__toSRAM_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_0_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_0_array, i_L2Directory_1__toSRAM_0_array);
    end
    if (g_L2Directory_1__toSRAM_0_array !== p_L2Directory_1__toSRAM_0_array) t_L2Directory_1__toSRAM_0_array = 1'b1;
    p_L2Directory_1__toSRAM_0_array = g_L2Directory_1__toSRAM_0_array;
    checks++;
    if (g_L2Directory_1__toSRAM_1_addr !== i_L2Directory_1__toSRAM_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_addr, i_L2Directory_1__toSRAM_1_addr);
    end
    if (g_L2Directory_1__toSRAM_1_addr !== p_L2Directory_1__toSRAM_1_addr) t_L2Directory_1__toSRAM_1_addr = 1'b1;
    p_L2Directory_1__toSRAM_1_addr = g_L2Directory_1__toSRAM_1_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_1_addr_rd !== i_L2Directory_1__toSRAM_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_addr_rd, i_L2Directory_1__toSRAM_1_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_1_addr_rd !== p_L2Directory_1__toSRAM_1_addr_rd) t_L2Directory_1__toSRAM_1_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_1_addr_rd = g_L2Directory_1__toSRAM_1_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_1_wdata !== i_L2Directory_1__toSRAM_1_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_wdata, i_L2Directory_1__toSRAM_1_wdata);
    end
    if (g_L2Directory_1__toSRAM_1_wdata !== p_L2Directory_1__toSRAM_1_wdata) t_L2Directory_1__toSRAM_1_wdata = 1'b1;
    p_L2Directory_1__toSRAM_1_wdata = g_L2Directory_1__toSRAM_1_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_1_wmask !== i_L2Directory_1__toSRAM_1_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_wmask, i_L2Directory_1__toSRAM_1_wmask);
    end
    if (g_L2Directory_1__toSRAM_1_wmask !== p_L2Directory_1__toSRAM_1_wmask) t_L2Directory_1__toSRAM_1_wmask = 1'b1;
    p_L2Directory_1__toSRAM_1_wmask = g_L2Directory_1__toSRAM_1_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_1_re !== i_L2Directory_1__toSRAM_1_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_re, i_L2Directory_1__toSRAM_1_re);
    end
    if (g_L2Directory_1__toSRAM_1_re !== p_L2Directory_1__toSRAM_1_re) t_L2Directory_1__toSRAM_1_re = 1'b1;
    p_L2Directory_1__toSRAM_1_re = g_L2Directory_1__toSRAM_1_re;
    checks++;
    if (g_L2Directory_1__toSRAM_1_we !== i_L2Directory_1__toSRAM_1_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_we, i_L2Directory_1__toSRAM_1_we);
    end
    if (g_L2Directory_1__toSRAM_1_we !== p_L2Directory_1__toSRAM_1_we) t_L2Directory_1__toSRAM_1_we = 1'b1;
    p_L2Directory_1__toSRAM_1_we = g_L2Directory_1__toSRAM_1_we;
    checks++;
    if (g_L2Directory_1__toSRAM_1_ack !== i_L2Directory_1__toSRAM_1_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_ack, i_L2Directory_1__toSRAM_1_ack);
    end
    if (g_L2Directory_1__toSRAM_1_ack !== p_L2Directory_1__toSRAM_1_ack) t_L2Directory_1__toSRAM_1_ack = 1'b1;
    p_L2Directory_1__toSRAM_1_ack = g_L2Directory_1__toSRAM_1_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_1_selectedOH !== i_L2Directory_1__toSRAM_1_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_selectedOH, i_L2Directory_1__toSRAM_1_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_1_selectedOH !== p_L2Directory_1__toSRAM_1_selectedOH) t_L2Directory_1__toSRAM_1_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_1_selectedOH = g_L2Directory_1__toSRAM_1_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_1_array !== i_L2Directory_1__toSRAM_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_1_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_1_array, i_L2Directory_1__toSRAM_1_array);
    end
    if (g_L2Directory_1__toSRAM_1_array !== p_L2Directory_1__toSRAM_1_array) t_L2Directory_1__toSRAM_1_array = 1'b1;
    p_L2Directory_1__toSRAM_1_array = g_L2Directory_1__toSRAM_1_array;
    checks++;
    if (g_L2Directory_1__toSRAM_2_addr !== i_L2Directory_1__toSRAM_2_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_addr, i_L2Directory_1__toSRAM_2_addr);
    end
    if (g_L2Directory_1__toSRAM_2_addr !== p_L2Directory_1__toSRAM_2_addr) t_L2Directory_1__toSRAM_2_addr = 1'b1;
    p_L2Directory_1__toSRAM_2_addr = g_L2Directory_1__toSRAM_2_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_2_addr_rd !== i_L2Directory_1__toSRAM_2_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_addr_rd, i_L2Directory_1__toSRAM_2_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_2_addr_rd !== p_L2Directory_1__toSRAM_2_addr_rd) t_L2Directory_1__toSRAM_2_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_2_addr_rd = g_L2Directory_1__toSRAM_2_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_2_wdata !== i_L2Directory_1__toSRAM_2_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_wdata, i_L2Directory_1__toSRAM_2_wdata);
    end
    if (g_L2Directory_1__toSRAM_2_wdata !== p_L2Directory_1__toSRAM_2_wdata) t_L2Directory_1__toSRAM_2_wdata = 1'b1;
    p_L2Directory_1__toSRAM_2_wdata = g_L2Directory_1__toSRAM_2_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_2_wmask !== i_L2Directory_1__toSRAM_2_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_wmask, i_L2Directory_1__toSRAM_2_wmask);
    end
    if (g_L2Directory_1__toSRAM_2_wmask !== p_L2Directory_1__toSRAM_2_wmask) t_L2Directory_1__toSRAM_2_wmask = 1'b1;
    p_L2Directory_1__toSRAM_2_wmask = g_L2Directory_1__toSRAM_2_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_2_re !== i_L2Directory_1__toSRAM_2_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_re, i_L2Directory_1__toSRAM_2_re);
    end
    if (g_L2Directory_1__toSRAM_2_re !== p_L2Directory_1__toSRAM_2_re) t_L2Directory_1__toSRAM_2_re = 1'b1;
    p_L2Directory_1__toSRAM_2_re = g_L2Directory_1__toSRAM_2_re;
    checks++;
    if (g_L2Directory_1__toSRAM_2_we !== i_L2Directory_1__toSRAM_2_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_we, i_L2Directory_1__toSRAM_2_we);
    end
    if (g_L2Directory_1__toSRAM_2_we !== p_L2Directory_1__toSRAM_2_we) t_L2Directory_1__toSRAM_2_we = 1'b1;
    p_L2Directory_1__toSRAM_2_we = g_L2Directory_1__toSRAM_2_we;
    checks++;
    if (g_L2Directory_1__toSRAM_2_ack !== i_L2Directory_1__toSRAM_2_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_ack, i_L2Directory_1__toSRAM_2_ack);
    end
    if (g_L2Directory_1__toSRAM_2_ack !== p_L2Directory_1__toSRAM_2_ack) t_L2Directory_1__toSRAM_2_ack = 1'b1;
    p_L2Directory_1__toSRAM_2_ack = g_L2Directory_1__toSRAM_2_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_2_selectedOH !== i_L2Directory_1__toSRAM_2_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_selectedOH, i_L2Directory_1__toSRAM_2_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_2_selectedOH !== p_L2Directory_1__toSRAM_2_selectedOH) t_L2Directory_1__toSRAM_2_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_2_selectedOH = g_L2Directory_1__toSRAM_2_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_2_array !== i_L2Directory_1__toSRAM_2_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_2_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_2_array, i_L2Directory_1__toSRAM_2_array);
    end
    if (g_L2Directory_1__toSRAM_2_array !== p_L2Directory_1__toSRAM_2_array) t_L2Directory_1__toSRAM_2_array = 1'b1;
    p_L2Directory_1__toSRAM_2_array = g_L2Directory_1__toSRAM_2_array;
    checks++;
    if (g_L2Directory_1__toSRAM_3_addr !== i_L2Directory_1__toSRAM_3_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_addr, i_L2Directory_1__toSRAM_3_addr);
    end
    if (g_L2Directory_1__toSRAM_3_addr !== p_L2Directory_1__toSRAM_3_addr) t_L2Directory_1__toSRAM_3_addr = 1'b1;
    p_L2Directory_1__toSRAM_3_addr = g_L2Directory_1__toSRAM_3_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_3_addr_rd !== i_L2Directory_1__toSRAM_3_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_addr_rd, i_L2Directory_1__toSRAM_3_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_3_addr_rd !== p_L2Directory_1__toSRAM_3_addr_rd) t_L2Directory_1__toSRAM_3_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_3_addr_rd = g_L2Directory_1__toSRAM_3_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_3_wdata !== i_L2Directory_1__toSRAM_3_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_wdata, i_L2Directory_1__toSRAM_3_wdata);
    end
    if (g_L2Directory_1__toSRAM_3_wdata !== p_L2Directory_1__toSRAM_3_wdata) t_L2Directory_1__toSRAM_3_wdata = 1'b1;
    p_L2Directory_1__toSRAM_3_wdata = g_L2Directory_1__toSRAM_3_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_3_wmask !== i_L2Directory_1__toSRAM_3_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_wmask, i_L2Directory_1__toSRAM_3_wmask);
    end
    if (g_L2Directory_1__toSRAM_3_wmask !== p_L2Directory_1__toSRAM_3_wmask) t_L2Directory_1__toSRAM_3_wmask = 1'b1;
    p_L2Directory_1__toSRAM_3_wmask = g_L2Directory_1__toSRAM_3_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_3_re !== i_L2Directory_1__toSRAM_3_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_re, i_L2Directory_1__toSRAM_3_re);
    end
    if (g_L2Directory_1__toSRAM_3_re !== p_L2Directory_1__toSRAM_3_re) t_L2Directory_1__toSRAM_3_re = 1'b1;
    p_L2Directory_1__toSRAM_3_re = g_L2Directory_1__toSRAM_3_re;
    checks++;
    if (g_L2Directory_1__toSRAM_3_we !== i_L2Directory_1__toSRAM_3_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_we, i_L2Directory_1__toSRAM_3_we);
    end
    if (g_L2Directory_1__toSRAM_3_we !== p_L2Directory_1__toSRAM_3_we) t_L2Directory_1__toSRAM_3_we = 1'b1;
    p_L2Directory_1__toSRAM_3_we = g_L2Directory_1__toSRAM_3_we;
    checks++;
    if (g_L2Directory_1__toSRAM_3_ack !== i_L2Directory_1__toSRAM_3_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_ack, i_L2Directory_1__toSRAM_3_ack);
    end
    if (g_L2Directory_1__toSRAM_3_ack !== p_L2Directory_1__toSRAM_3_ack) t_L2Directory_1__toSRAM_3_ack = 1'b1;
    p_L2Directory_1__toSRAM_3_ack = g_L2Directory_1__toSRAM_3_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_3_selectedOH !== i_L2Directory_1__toSRAM_3_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_selectedOH, i_L2Directory_1__toSRAM_3_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_3_selectedOH !== p_L2Directory_1__toSRAM_3_selectedOH) t_L2Directory_1__toSRAM_3_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_3_selectedOH = g_L2Directory_1__toSRAM_3_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_3_array !== i_L2Directory_1__toSRAM_3_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_3_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_3_array, i_L2Directory_1__toSRAM_3_array);
    end
    if (g_L2Directory_1__toSRAM_3_array !== p_L2Directory_1__toSRAM_3_array) t_L2Directory_1__toSRAM_3_array = 1'b1;
    p_L2Directory_1__toSRAM_3_array = g_L2Directory_1__toSRAM_3_array;
    checks++;
    if (g_L2Directory_1__toSRAM_4_addr !== i_L2Directory_1__toSRAM_4_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_addr, i_L2Directory_1__toSRAM_4_addr);
    end
    if (g_L2Directory_1__toSRAM_4_addr !== p_L2Directory_1__toSRAM_4_addr) t_L2Directory_1__toSRAM_4_addr = 1'b1;
    p_L2Directory_1__toSRAM_4_addr = g_L2Directory_1__toSRAM_4_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_4_addr_rd !== i_L2Directory_1__toSRAM_4_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_addr_rd, i_L2Directory_1__toSRAM_4_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_4_addr_rd !== p_L2Directory_1__toSRAM_4_addr_rd) t_L2Directory_1__toSRAM_4_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_4_addr_rd = g_L2Directory_1__toSRAM_4_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_4_wdata !== i_L2Directory_1__toSRAM_4_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_wdata, i_L2Directory_1__toSRAM_4_wdata);
    end
    if (g_L2Directory_1__toSRAM_4_wdata !== p_L2Directory_1__toSRAM_4_wdata) t_L2Directory_1__toSRAM_4_wdata = 1'b1;
    p_L2Directory_1__toSRAM_4_wdata = g_L2Directory_1__toSRAM_4_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_4_wmask !== i_L2Directory_1__toSRAM_4_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_wmask, i_L2Directory_1__toSRAM_4_wmask);
    end
    if (g_L2Directory_1__toSRAM_4_wmask !== p_L2Directory_1__toSRAM_4_wmask) t_L2Directory_1__toSRAM_4_wmask = 1'b1;
    p_L2Directory_1__toSRAM_4_wmask = g_L2Directory_1__toSRAM_4_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_4_re !== i_L2Directory_1__toSRAM_4_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_re, i_L2Directory_1__toSRAM_4_re);
    end
    if (g_L2Directory_1__toSRAM_4_re !== p_L2Directory_1__toSRAM_4_re) t_L2Directory_1__toSRAM_4_re = 1'b1;
    p_L2Directory_1__toSRAM_4_re = g_L2Directory_1__toSRAM_4_re;
    checks++;
    if (g_L2Directory_1__toSRAM_4_we !== i_L2Directory_1__toSRAM_4_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_we, i_L2Directory_1__toSRAM_4_we);
    end
    if (g_L2Directory_1__toSRAM_4_we !== p_L2Directory_1__toSRAM_4_we) t_L2Directory_1__toSRAM_4_we = 1'b1;
    p_L2Directory_1__toSRAM_4_we = g_L2Directory_1__toSRAM_4_we;
    checks++;
    if (g_L2Directory_1__toSRAM_4_ack !== i_L2Directory_1__toSRAM_4_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_ack, i_L2Directory_1__toSRAM_4_ack);
    end
    if (g_L2Directory_1__toSRAM_4_ack !== p_L2Directory_1__toSRAM_4_ack) t_L2Directory_1__toSRAM_4_ack = 1'b1;
    p_L2Directory_1__toSRAM_4_ack = g_L2Directory_1__toSRAM_4_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_4_selectedOH !== i_L2Directory_1__toSRAM_4_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_selectedOH, i_L2Directory_1__toSRAM_4_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_4_selectedOH !== p_L2Directory_1__toSRAM_4_selectedOH) t_L2Directory_1__toSRAM_4_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_4_selectedOH = g_L2Directory_1__toSRAM_4_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_4_array !== i_L2Directory_1__toSRAM_4_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_4_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_4_array, i_L2Directory_1__toSRAM_4_array);
    end
    if (g_L2Directory_1__toSRAM_4_array !== p_L2Directory_1__toSRAM_4_array) t_L2Directory_1__toSRAM_4_array = 1'b1;
    p_L2Directory_1__toSRAM_4_array = g_L2Directory_1__toSRAM_4_array;
    checks++;
    if (g_L2Directory_1__toSRAM_5_addr !== i_L2Directory_1__toSRAM_5_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_addr, i_L2Directory_1__toSRAM_5_addr);
    end
    if (g_L2Directory_1__toSRAM_5_addr !== p_L2Directory_1__toSRAM_5_addr) t_L2Directory_1__toSRAM_5_addr = 1'b1;
    p_L2Directory_1__toSRAM_5_addr = g_L2Directory_1__toSRAM_5_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_5_addr_rd !== i_L2Directory_1__toSRAM_5_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_addr_rd, i_L2Directory_1__toSRAM_5_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_5_addr_rd !== p_L2Directory_1__toSRAM_5_addr_rd) t_L2Directory_1__toSRAM_5_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_5_addr_rd = g_L2Directory_1__toSRAM_5_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_5_wdata !== i_L2Directory_1__toSRAM_5_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_wdata, i_L2Directory_1__toSRAM_5_wdata);
    end
    if (g_L2Directory_1__toSRAM_5_wdata !== p_L2Directory_1__toSRAM_5_wdata) t_L2Directory_1__toSRAM_5_wdata = 1'b1;
    p_L2Directory_1__toSRAM_5_wdata = g_L2Directory_1__toSRAM_5_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_5_wmask !== i_L2Directory_1__toSRAM_5_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_wmask, i_L2Directory_1__toSRAM_5_wmask);
    end
    if (g_L2Directory_1__toSRAM_5_wmask !== p_L2Directory_1__toSRAM_5_wmask) t_L2Directory_1__toSRAM_5_wmask = 1'b1;
    p_L2Directory_1__toSRAM_5_wmask = g_L2Directory_1__toSRAM_5_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_5_re !== i_L2Directory_1__toSRAM_5_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_re, i_L2Directory_1__toSRAM_5_re);
    end
    if (g_L2Directory_1__toSRAM_5_re !== p_L2Directory_1__toSRAM_5_re) t_L2Directory_1__toSRAM_5_re = 1'b1;
    p_L2Directory_1__toSRAM_5_re = g_L2Directory_1__toSRAM_5_re;
    checks++;
    if (g_L2Directory_1__toSRAM_5_we !== i_L2Directory_1__toSRAM_5_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_we, i_L2Directory_1__toSRAM_5_we);
    end
    if (g_L2Directory_1__toSRAM_5_we !== p_L2Directory_1__toSRAM_5_we) t_L2Directory_1__toSRAM_5_we = 1'b1;
    p_L2Directory_1__toSRAM_5_we = g_L2Directory_1__toSRAM_5_we;
    checks++;
    if (g_L2Directory_1__toSRAM_5_ack !== i_L2Directory_1__toSRAM_5_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_ack, i_L2Directory_1__toSRAM_5_ack);
    end
    if (g_L2Directory_1__toSRAM_5_ack !== p_L2Directory_1__toSRAM_5_ack) t_L2Directory_1__toSRAM_5_ack = 1'b1;
    p_L2Directory_1__toSRAM_5_ack = g_L2Directory_1__toSRAM_5_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_5_selectedOH !== i_L2Directory_1__toSRAM_5_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_selectedOH, i_L2Directory_1__toSRAM_5_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_5_selectedOH !== p_L2Directory_1__toSRAM_5_selectedOH) t_L2Directory_1__toSRAM_5_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_5_selectedOH = g_L2Directory_1__toSRAM_5_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_5_array !== i_L2Directory_1__toSRAM_5_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_5_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_5_array, i_L2Directory_1__toSRAM_5_array);
    end
    if (g_L2Directory_1__toSRAM_5_array !== p_L2Directory_1__toSRAM_5_array) t_L2Directory_1__toSRAM_5_array = 1'b1;
    p_L2Directory_1__toSRAM_5_array = g_L2Directory_1__toSRAM_5_array;
    checks++;
    if (g_L2Directory_1__toSRAM_6_addr !== i_L2Directory_1__toSRAM_6_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_addr g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_addr, i_L2Directory_1__toSRAM_6_addr);
    end
    if (g_L2Directory_1__toSRAM_6_addr !== p_L2Directory_1__toSRAM_6_addr) t_L2Directory_1__toSRAM_6_addr = 1'b1;
    p_L2Directory_1__toSRAM_6_addr = g_L2Directory_1__toSRAM_6_addr;
    checks++;
    if (g_L2Directory_1__toSRAM_6_addr_rd !== i_L2Directory_1__toSRAM_6_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_addr_rd g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_addr_rd, i_L2Directory_1__toSRAM_6_addr_rd);
    end
    if (g_L2Directory_1__toSRAM_6_addr_rd !== p_L2Directory_1__toSRAM_6_addr_rd) t_L2Directory_1__toSRAM_6_addr_rd = 1'b1;
    p_L2Directory_1__toSRAM_6_addr_rd = g_L2Directory_1__toSRAM_6_addr_rd;
    checks++;
    if (g_L2Directory_1__toSRAM_6_wdata !== i_L2Directory_1__toSRAM_6_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_wdata g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_wdata, i_L2Directory_1__toSRAM_6_wdata);
    end
    if (g_L2Directory_1__toSRAM_6_wdata !== p_L2Directory_1__toSRAM_6_wdata) t_L2Directory_1__toSRAM_6_wdata = 1'b1;
    p_L2Directory_1__toSRAM_6_wdata = g_L2Directory_1__toSRAM_6_wdata;
    checks++;
    if (g_L2Directory_1__toSRAM_6_wmask !== i_L2Directory_1__toSRAM_6_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_wmask g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_wmask, i_L2Directory_1__toSRAM_6_wmask);
    end
    if (g_L2Directory_1__toSRAM_6_wmask !== p_L2Directory_1__toSRAM_6_wmask) t_L2Directory_1__toSRAM_6_wmask = 1'b1;
    p_L2Directory_1__toSRAM_6_wmask = g_L2Directory_1__toSRAM_6_wmask;
    checks++;
    if (g_L2Directory_1__toSRAM_6_re !== i_L2Directory_1__toSRAM_6_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_re g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_re, i_L2Directory_1__toSRAM_6_re);
    end
    if (g_L2Directory_1__toSRAM_6_re !== p_L2Directory_1__toSRAM_6_re) t_L2Directory_1__toSRAM_6_re = 1'b1;
    p_L2Directory_1__toSRAM_6_re = g_L2Directory_1__toSRAM_6_re;
    checks++;
    if (g_L2Directory_1__toSRAM_6_we !== i_L2Directory_1__toSRAM_6_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_we g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_we, i_L2Directory_1__toSRAM_6_we);
    end
    if (g_L2Directory_1__toSRAM_6_we !== p_L2Directory_1__toSRAM_6_we) t_L2Directory_1__toSRAM_6_we = 1'b1;
    p_L2Directory_1__toSRAM_6_we = g_L2Directory_1__toSRAM_6_we;
    checks++;
    if (g_L2Directory_1__toSRAM_6_ack !== i_L2Directory_1__toSRAM_6_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_ack g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_ack, i_L2Directory_1__toSRAM_6_ack);
    end
    if (g_L2Directory_1__toSRAM_6_ack !== p_L2Directory_1__toSRAM_6_ack) t_L2Directory_1__toSRAM_6_ack = 1'b1;
    p_L2Directory_1__toSRAM_6_ack = g_L2Directory_1__toSRAM_6_ack;
    checks++;
    if (g_L2Directory_1__toSRAM_6_selectedOH !== i_L2Directory_1__toSRAM_6_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_selectedOH g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_selectedOH, i_L2Directory_1__toSRAM_6_selectedOH);
    end
    if (g_L2Directory_1__toSRAM_6_selectedOH !== p_L2Directory_1__toSRAM_6_selectedOH) t_L2Directory_1__toSRAM_6_selectedOH = 1'b1;
    p_L2Directory_1__toSRAM_6_selectedOH = g_L2Directory_1__toSRAM_6_selectedOH;
    checks++;
    if (g_L2Directory_1__toSRAM_6_array !== i_L2Directory_1__toSRAM_6_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_1.toSRAM_6_array g=%h i=%h", cyc, g_L2Directory_1__toSRAM_6_array, i_L2Directory_1__toSRAM_6_array);
    end
    if (g_L2Directory_1__toSRAM_6_array !== p_L2Directory_1__toSRAM_6_array) t_L2Directory_1__toSRAM_6_array = 1'b1;
    p_L2Directory_1__toSRAM_6_array = g_L2Directory_1__toSRAM_6_array;
  endtask
  longint cov_L2Directory_1_act = 0;
  longint cov_L2Directory_1_sel6 = 0;
  task automatic cover_L2Directory_1();
    if (u_g_L2Directory_1.activated) cov_L2Directory_1_act++;
    if (u_g_L2Directory_1.selectedVec_0_6) cov_L2Directory_1_sel6++;
  endtask
  task automatic preinit_L2Directory_1();
  endtask
  task automatic sync_L2Directory_1();
  endtask

  // ======================= L2Directory_2 =======================
  logic [4:0] L2Directory_2__mbist_array;
  logic L2Directory_2__mbist_all;
  logic L2Directory_2__mbist_req;
  logic L2Directory_2__mbist_writeen;
  logic [7:0] L2Directory_2__mbist_be;
  logic [9:0] L2Directory_2__mbist_addr;
  logic [103:0] L2Directory_2__mbist_indata;
  logic L2Directory_2__mbist_readen;
  logic [9:0] L2Directory_2__mbist_addr_rd;
  logic [75:0] L2Directory_2__toSRAM_0_rdata;
  logic [75:0] L2Directory_2__toSRAM_1_rdata;
  logic [75:0] L2Directory_2__toSRAM_2_rdata;
  logic [75:0] L2Directory_2__toSRAM_3_rdata;
  logic [103:0] L2Directory_2__toSRAM_4_rdata;
  logic [15:0] L2Directory_2__toSRAM_5_rdata;
  logic [7:0] L2Directory_2__toSRAM_6_rdata;
  wire  g_L2Directory_2__mbist_ack;
  wire  i_L2Directory_2__mbist_ack;
  logic p_L2Directory_2__mbist_ack;
  bit   t_L2Directory_2__mbist_ack;
  wire  [103:0] g_L2Directory_2__mbist_outdata;
  wire  [103:0] i_L2Directory_2__mbist_outdata;
  logic [103:0] p_L2Directory_2__mbist_outdata;
  bit   t_L2Directory_2__mbist_outdata;
  wire  [9:0] g_L2Directory_2__toSRAM_0_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_0_addr;
  logic [9:0] p_L2Directory_2__toSRAM_0_addr;
  bit   t_L2Directory_2__toSRAM_0_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_0_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_0_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_0_addr_rd;
  bit   t_L2Directory_2__toSRAM_0_addr_rd;
  wire  [75:0] g_L2Directory_2__toSRAM_0_wdata;
  wire  [75:0] i_L2Directory_2__toSRAM_0_wdata;
  logic [75:0] p_L2Directory_2__toSRAM_0_wdata;
  bit   t_L2Directory_2__toSRAM_0_wdata;
  wire  [3:0] g_L2Directory_2__toSRAM_0_wmask;
  wire  [3:0] i_L2Directory_2__toSRAM_0_wmask;
  logic [3:0] p_L2Directory_2__toSRAM_0_wmask;
  bit   t_L2Directory_2__toSRAM_0_wmask;
  wire  g_L2Directory_2__toSRAM_0_re;
  wire  i_L2Directory_2__toSRAM_0_re;
  logic p_L2Directory_2__toSRAM_0_re;
  bit   t_L2Directory_2__toSRAM_0_re;
  wire  g_L2Directory_2__toSRAM_0_we;
  wire  i_L2Directory_2__toSRAM_0_we;
  logic p_L2Directory_2__toSRAM_0_we;
  bit   t_L2Directory_2__toSRAM_0_we;
  wire  g_L2Directory_2__toSRAM_0_ack;
  wire  i_L2Directory_2__toSRAM_0_ack;
  logic p_L2Directory_2__toSRAM_0_ack;
  bit   t_L2Directory_2__toSRAM_0_ack;
  wire  g_L2Directory_2__toSRAM_0_selectedOH;
  wire  i_L2Directory_2__toSRAM_0_selectedOH;
  logic p_L2Directory_2__toSRAM_0_selectedOH;
  bit   t_L2Directory_2__toSRAM_0_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_0_array;
  wire  [4:0] i_L2Directory_2__toSRAM_0_array;
  logic [4:0] p_L2Directory_2__toSRAM_0_array;
  bit   t_L2Directory_2__toSRAM_0_array;
  wire  [9:0] g_L2Directory_2__toSRAM_1_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_1_addr;
  logic [9:0] p_L2Directory_2__toSRAM_1_addr;
  bit   t_L2Directory_2__toSRAM_1_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_1_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_1_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_1_addr_rd;
  bit   t_L2Directory_2__toSRAM_1_addr_rd;
  wire  [75:0] g_L2Directory_2__toSRAM_1_wdata;
  wire  [75:0] i_L2Directory_2__toSRAM_1_wdata;
  logic [75:0] p_L2Directory_2__toSRAM_1_wdata;
  bit   t_L2Directory_2__toSRAM_1_wdata;
  wire  [3:0] g_L2Directory_2__toSRAM_1_wmask;
  wire  [3:0] i_L2Directory_2__toSRAM_1_wmask;
  logic [3:0] p_L2Directory_2__toSRAM_1_wmask;
  bit   t_L2Directory_2__toSRAM_1_wmask;
  wire  g_L2Directory_2__toSRAM_1_re;
  wire  i_L2Directory_2__toSRAM_1_re;
  logic p_L2Directory_2__toSRAM_1_re;
  bit   t_L2Directory_2__toSRAM_1_re;
  wire  g_L2Directory_2__toSRAM_1_we;
  wire  i_L2Directory_2__toSRAM_1_we;
  logic p_L2Directory_2__toSRAM_1_we;
  bit   t_L2Directory_2__toSRAM_1_we;
  wire  g_L2Directory_2__toSRAM_1_ack;
  wire  i_L2Directory_2__toSRAM_1_ack;
  logic p_L2Directory_2__toSRAM_1_ack;
  bit   t_L2Directory_2__toSRAM_1_ack;
  wire  g_L2Directory_2__toSRAM_1_selectedOH;
  wire  i_L2Directory_2__toSRAM_1_selectedOH;
  logic p_L2Directory_2__toSRAM_1_selectedOH;
  bit   t_L2Directory_2__toSRAM_1_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_1_array;
  wire  [4:0] i_L2Directory_2__toSRAM_1_array;
  logic [4:0] p_L2Directory_2__toSRAM_1_array;
  bit   t_L2Directory_2__toSRAM_1_array;
  wire  [9:0] g_L2Directory_2__toSRAM_2_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_2_addr;
  logic [9:0] p_L2Directory_2__toSRAM_2_addr;
  bit   t_L2Directory_2__toSRAM_2_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_2_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_2_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_2_addr_rd;
  bit   t_L2Directory_2__toSRAM_2_addr_rd;
  wire  [75:0] g_L2Directory_2__toSRAM_2_wdata;
  wire  [75:0] i_L2Directory_2__toSRAM_2_wdata;
  logic [75:0] p_L2Directory_2__toSRAM_2_wdata;
  bit   t_L2Directory_2__toSRAM_2_wdata;
  wire  [3:0] g_L2Directory_2__toSRAM_2_wmask;
  wire  [3:0] i_L2Directory_2__toSRAM_2_wmask;
  logic [3:0] p_L2Directory_2__toSRAM_2_wmask;
  bit   t_L2Directory_2__toSRAM_2_wmask;
  wire  g_L2Directory_2__toSRAM_2_re;
  wire  i_L2Directory_2__toSRAM_2_re;
  logic p_L2Directory_2__toSRAM_2_re;
  bit   t_L2Directory_2__toSRAM_2_re;
  wire  g_L2Directory_2__toSRAM_2_we;
  wire  i_L2Directory_2__toSRAM_2_we;
  logic p_L2Directory_2__toSRAM_2_we;
  bit   t_L2Directory_2__toSRAM_2_we;
  wire  g_L2Directory_2__toSRAM_2_ack;
  wire  i_L2Directory_2__toSRAM_2_ack;
  logic p_L2Directory_2__toSRAM_2_ack;
  bit   t_L2Directory_2__toSRAM_2_ack;
  wire  g_L2Directory_2__toSRAM_2_selectedOH;
  wire  i_L2Directory_2__toSRAM_2_selectedOH;
  logic p_L2Directory_2__toSRAM_2_selectedOH;
  bit   t_L2Directory_2__toSRAM_2_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_2_array;
  wire  [4:0] i_L2Directory_2__toSRAM_2_array;
  logic [4:0] p_L2Directory_2__toSRAM_2_array;
  bit   t_L2Directory_2__toSRAM_2_array;
  wire  [9:0] g_L2Directory_2__toSRAM_3_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_3_addr;
  logic [9:0] p_L2Directory_2__toSRAM_3_addr;
  bit   t_L2Directory_2__toSRAM_3_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_3_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_3_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_3_addr_rd;
  bit   t_L2Directory_2__toSRAM_3_addr_rd;
  wire  [75:0] g_L2Directory_2__toSRAM_3_wdata;
  wire  [75:0] i_L2Directory_2__toSRAM_3_wdata;
  logic [75:0] p_L2Directory_2__toSRAM_3_wdata;
  bit   t_L2Directory_2__toSRAM_3_wdata;
  wire  [3:0] g_L2Directory_2__toSRAM_3_wmask;
  wire  [3:0] i_L2Directory_2__toSRAM_3_wmask;
  logic [3:0] p_L2Directory_2__toSRAM_3_wmask;
  bit   t_L2Directory_2__toSRAM_3_wmask;
  wire  g_L2Directory_2__toSRAM_3_re;
  wire  i_L2Directory_2__toSRAM_3_re;
  logic p_L2Directory_2__toSRAM_3_re;
  bit   t_L2Directory_2__toSRAM_3_re;
  wire  g_L2Directory_2__toSRAM_3_we;
  wire  i_L2Directory_2__toSRAM_3_we;
  logic p_L2Directory_2__toSRAM_3_we;
  bit   t_L2Directory_2__toSRAM_3_we;
  wire  g_L2Directory_2__toSRAM_3_ack;
  wire  i_L2Directory_2__toSRAM_3_ack;
  logic p_L2Directory_2__toSRAM_3_ack;
  bit   t_L2Directory_2__toSRAM_3_ack;
  wire  g_L2Directory_2__toSRAM_3_selectedOH;
  wire  i_L2Directory_2__toSRAM_3_selectedOH;
  logic p_L2Directory_2__toSRAM_3_selectedOH;
  bit   t_L2Directory_2__toSRAM_3_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_3_array;
  wire  [4:0] i_L2Directory_2__toSRAM_3_array;
  logic [4:0] p_L2Directory_2__toSRAM_3_array;
  bit   t_L2Directory_2__toSRAM_3_array;
  wire  [9:0] g_L2Directory_2__toSRAM_4_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_4_addr;
  logic [9:0] p_L2Directory_2__toSRAM_4_addr;
  bit   t_L2Directory_2__toSRAM_4_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_4_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_4_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_4_addr_rd;
  bit   t_L2Directory_2__toSRAM_4_addr_rd;
  wire  [103:0] g_L2Directory_2__toSRAM_4_wdata;
  wire  [103:0] i_L2Directory_2__toSRAM_4_wdata;
  logic [103:0] p_L2Directory_2__toSRAM_4_wdata;
  bit   t_L2Directory_2__toSRAM_4_wdata;
  wire  [7:0] g_L2Directory_2__toSRAM_4_wmask;
  wire  [7:0] i_L2Directory_2__toSRAM_4_wmask;
  logic [7:0] p_L2Directory_2__toSRAM_4_wmask;
  bit   t_L2Directory_2__toSRAM_4_wmask;
  wire  g_L2Directory_2__toSRAM_4_re;
  wire  i_L2Directory_2__toSRAM_4_re;
  logic p_L2Directory_2__toSRAM_4_re;
  bit   t_L2Directory_2__toSRAM_4_re;
  wire  g_L2Directory_2__toSRAM_4_we;
  wire  i_L2Directory_2__toSRAM_4_we;
  logic p_L2Directory_2__toSRAM_4_we;
  bit   t_L2Directory_2__toSRAM_4_we;
  wire  g_L2Directory_2__toSRAM_4_ack;
  wire  i_L2Directory_2__toSRAM_4_ack;
  logic p_L2Directory_2__toSRAM_4_ack;
  bit   t_L2Directory_2__toSRAM_4_ack;
  wire  g_L2Directory_2__toSRAM_4_selectedOH;
  wire  i_L2Directory_2__toSRAM_4_selectedOH;
  logic p_L2Directory_2__toSRAM_4_selectedOH;
  bit   t_L2Directory_2__toSRAM_4_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_4_array;
  wire  [4:0] i_L2Directory_2__toSRAM_4_array;
  logic [4:0] p_L2Directory_2__toSRAM_4_array;
  bit   t_L2Directory_2__toSRAM_4_array;
  wire  [9:0] g_L2Directory_2__toSRAM_5_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_5_addr;
  logic [9:0] p_L2Directory_2__toSRAM_5_addr;
  bit   t_L2Directory_2__toSRAM_5_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_5_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_5_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_5_addr_rd;
  bit   t_L2Directory_2__toSRAM_5_addr_rd;
  wire  [15:0] g_L2Directory_2__toSRAM_5_wdata;
  wire  [15:0] i_L2Directory_2__toSRAM_5_wdata;
  logic [15:0] p_L2Directory_2__toSRAM_5_wdata;
  bit   t_L2Directory_2__toSRAM_5_wdata;
  wire  g_L2Directory_2__toSRAM_5_wmask;
  wire  i_L2Directory_2__toSRAM_5_wmask;
  logic p_L2Directory_2__toSRAM_5_wmask;
  bit   t_L2Directory_2__toSRAM_5_wmask;
  wire  g_L2Directory_2__toSRAM_5_re;
  wire  i_L2Directory_2__toSRAM_5_re;
  logic p_L2Directory_2__toSRAM_5_re;
  bit   t_L2Directory_2__toSRAM_5_re;
  wire  g_L2Directory_2__toSRAM_5_we;
  wire  i_L2Directory_2__toSRAM_5_we;
  logic p_L2Directory_2__toSRAM_5_we;
  bit   t_L2Directory_2__toSRAM_5_we;
  wire  g_L2Directory_2__toSRAM_5_ack;
  wire  i_L2Directory_2__toSRAM_5_ack;
  logic p_L2Directory_2__toSRAM_5_ack;
  bit   t_L2Directory_2__toSRAM_5_ack;
  wire  g_L2Directory_2__toSRAM_5_selectedOH;
  wire  i_L2Directory_2__toSRAM_5_selectedOH;
  logic p_L2Directory_2__toSRAM_5_selectedOH;
  bit   t_L2Directory_2__toSRAM_5_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_5_array;
  wire  [4:0] i_L2Directory_2__toSRAM_5_array;
  logic [4:0] p_L2Directory_2__toSRAM_5_array;
  bit   t_L2Directory_2__toSRAM_5_array;
  wire  [9:0] g_L2Directory_2__toSRAM_6_addr;
  wire  [9:0] i_L2Directory_2__toSRAM_6_addr;
  logic [9:0] p_L2Directory_2__toSRAM_6_addr;
  bit   t_L2Directory_2__toSRAM_6_addr;
  wire  [9:0] g_L2Directory_2__toSRAM_6_addr_rd;
  wire  [9:0] i_L2Directory_2__toSRAM_6_addr_rd;
  logic [9:0] p_L2Directory_2__toSRAM_6_addr_rd;
  bit   t_L2Directory_2__toSRAM_6_addr_rd;
  wire  [7:0] g_L2Directory_2__toSRAM_6_wdata;
  wire  [7:0] i_L2Directory_2__toSRAM_6_wdata;
  logic [7:0] p_L2Directory_2__toSRAM_6_wdata;
  bit   t_L2Directory_2__toSRAM_6_wdata;
  wire  [7:0] g_L2Directory_2__toSRAM_6_wmask;
  wire  [7:0] i_L2Directory_2__toSRAM_6_wmask;
  logic [7:0] p_L2Directory_2__toSRAM_6_wmask;
  bit   t_L2Directory_2__toSRAM_6_wmask;
  wire  g_L2Directory_2__toSRAM_6_re;
  wire  i_L2Directory_2__toSRAM_6_re;
  logic p_L2Directory_2__toSRAM_6_re;
  bit   t_L2Directory_2__toSRAM_6_re;
  wire  g_L2Directory_2__toSRAM_6_we;
  wire  i_L2Directory_2__toSRAM_6_we;
  logic p_L2Directory_2__toSRAM_6_we;
  bit   t_L2Directory_2__toSRAM_6_we;
  wire  g_L2Directory_2__toSRAM_6_ack;
  wire  i_L2Directory_2__toSRAM_6_ack;
  logic p_L2Directory_2__toSRAM_6_ack;
  bit   t_L2Directory_2__toSRAM_6_ack;
  wire  g_L2Directory_2__toSRAM_6_selectedOH;
  wire  i_L2Directory_2__toSRAM_6_selectedOH;
  logic p_L2Directory_2__toSRAM_6_selectedOH;
  bit   t_L2Directory_2__toSRAM_6_selectedOH;
  wire  [4:0] g_L2Directory_2__toSRAM_6_array;
  wire  [4:0] i_L2Directory_2__toSRAM_6_array;
  logic [4:0] p_L2Directory_2__toSRAM_6_array;
  bit   t_L2Directory_2__toSRAM_6_array;
  L2Directory_2 u_g_L2Directory_2 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_2__mbist_array),
    .mbist_all (L2Directory_2__mbist_all),
    .mbist_req (L2Directory_2__mbist_req),
    .mbist_ack (g_L2Directory_2__mbist_ack),
    .mbist_writeen (L2Directory_2__mbist_writeen),
    .mbist_be (L2Directory_2__mbist_be),
    .mbist_addr (L2Directory_2__mbist_addr),
    .mbist_indata (L2Directory_2__mbist_indata),
    .mbist_readen (L2Directory_2__mbist_readen),
    .mbist_addr_rd (L2Directory_2__mbist_addr_rd),
    .mbist_outdata (g_L2Directory_2__mbist_outdata),
    .toSRAM_0_addr (g_L2Directory_2__toSRAM_0_addr),
    .toSRAM_0_addr_rd (g_L2Directory_2__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g_L2Directory_2__toSRAM_0_wdata),
    .toSRAM_0_wmask (g_L2Directory_2__toSRAM_0_wmask),
    .toSRAM_0_re (g_L2Directory_2__toSRAM_0_re),
    .toSRAM_0_we (g_L2Directory_2__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_2__toSRAM_0_rdata),
    .toSRAM_0_ack (g_L2Directory_2__toSRAM_0_ack),
    .toSRAM_0_selectedOH (g_L2Directory_2__toSRAM_0_selectedOH),
    .toSRAM_0_array (g_L2Directory_2__toSRAM_0_array),
    .toSRAM_1_addr (g_L2Directory_2__toSRAM_1_addr),
    .toSRAM_1_addr_rd (g_L2Directory_2__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g_L2Directory_2__toSRAM_1_wdata),
    .toSRAM_1_wmask (g_L2Directory_2__toSRAM_1_wmask),
    .toSRAM_1_re (g_L2Directory_2__toSRAM_1_re),
    .toSRAM_1_we (g_L2Directory_2__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_2__toSRAM_1_rdata),
    .toSRAM_1_ack (g_L2Directory_2__toSRAM_1_ack),
    .toSRAM_1_selectedOH (g_L2Directory_2__toSRAM_1_selectedOH),
    .toSRAM_1_array (g_L2Directory_2__toSRAM_1_array),
    .toSRAM_2_addr (g_L2Directory_2__toSRAM_2_addr),
    .toSRAM_2_addr_rd (g_L2Directory_2__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g_L2Directory_2__toSRAM_2_wdata),
    .toSRAM_2_wmask (g_L2Directory_2__toSRAM_2_wmask),
    .toSRAM_2_re (g_L2Directory_2__toSRAM_2_re),
    .toSRAM_2_we (g_L2Directory_2__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_2__toSRAM_2_rdata),
    .toSRAM_2_ack (g_L2Directory_2__toSRAM_2_ack),
    .toSRAM_2_selectedOH (g_L2Directory_2__toSRAM_2_selectedOH),
    .toSRAM_2_array (g_L2Directory_2__toSRAM_2_array),
    .toSRAM_3_addr (g_L2Directory_2__toSRAM_3_addr),
    .toSRAM_3_addr_rd (g_L2Directory_2__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g_L2Directory_2__toSRAM_3_wdata),
    .toSRAM_3_wmask (g_L2Directory_2__toSRAM_3_wmask),
    .toSRAM_3_re (g_L2Directory_2__toSRAM_3_re),
    .toSRAM_3_we (g_L2Directory_2__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_2__toSRAM_3_rdata),
    .toSRAM_3_ack (g_L2Directory_2__toSRAM_3_ack),
    .toSRAM_3_selectedOH (g_L2Directory_2__toSRAM_3_selectedOH),
    .toSRAM_3_array (g_L2Directory_2__toSRAM_3_array),
    .toSRAM_4_addr (g_L2Directory_2__toSRAM_4_addr),
    .toSRAM_4_addr_rd (g_L2Directory_2__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g_L2Directory_2__toSRAM_4_wdata),
    .toSRAM_4_wmask (g_L2Directory_2__toSRAM_4_wmask),
    .toSRAM_4_re (g_L2Directory_2__toSRAM_4_re),
    .toSRAM_4_we (g_L2Directory_2__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_2__toSRAM_4_rdata),
    .toSRAM_4_ack (g_L2Directory_2__toSRAM_4_ack),
    .toSRAM_4_selectedOH (g_L2Directory_2__toSRAM_4_selectedOH),
    .toSRAM_4_array (g_L2Directory_2__toSRAM_4_array),
    .toSRAM_5_addr (g_L2Directory_2__toSRAM_5_addr),
    .toSRAM_5_addr_rd (g_L2Directory_2__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g_L2Directory_2__toSRAM_5_wdata),
    .toSRAM_5_wmask (g_L2Directory_2__toSRAM_5_wmask),
    .toSRAM_5_re (g_L2Directory_2__toSRAM_5_re),
    .toSRAM_5_we (g_L2Directory_2__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_2__toSRAM_5_rdata),
    .toSRAM_5_ack (g_L2Directory_2__toSRAM_5_ack),
    .toSRAM_5_selectedOH (g_L2Directory_2__toSRAM_5_selectedOH),
    .toSRAM_5_array (g_L2Directory_2__toSRAM_5_array),
    .toSRAM_6_addr (g_L2Directory_2__toSRAM_6_addr),
    .toSRAM_6_addr_rd (g_L2Directory_2__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g_L2Directory_2__toSRAM_6_wdata),
    .toSRAM_6_wmask (g_L2Directory_2__toSRAM_6_wmask),
    .toSRAM_6_re (g_L2Directory_2__toSRAM_6_re),
    .toSRAM_6_we (g_L2Directory_2__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_2__toSRAM_6_rdata),
    .toSRAM_6_ack (g_L2Directory_2__toSRAM_6_ack),
    .toSRAM_6_selectedOH (g_L2Directory_2__toSRAM_6_selectedOH),
    .toSRAM_6_array (g_L2Directory_2__toSRAM_6_array)
  );
  L2Directory_2_xs u_i_L2Directory_2 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_2__mbist_array),
    .mbist_all (L2Directory_2__mbist_all),
    .mbist_req (L2Directory_2__mbist_req),
    .mbist_ack (i_L2Directory_2__mbist_ack),
    .mbist_writeen (L2Directory_2__mbist_writeen),
    .mbist_be (L2Directory_2__mbist_be),
    .mbist_addr (L2Directory_2__mbist_addr),
    .mbist_indata (L2Directory_2__mbist_indata),
    .mbist_readen (L2Directory_2__mbist_readen),
    .mbist_addr_rd (L2Directory_2__mbist_addr_rd),
    .mbist_outdata (i_L2Directory_2__mbist_outdata),
    .toSRAM_0_addr (i_L2Directory_2__toSRAM_0_addr),
    .toSRAM_0_addr_rd (i_L2Directory_2__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (i_L2Directory_2__toSRAM_0_wdata),
    .toSRAM_0_wmask (i_L2Directory_2__toSRAM_0_wmask),
    .toSRAM_0_re (i_L2Directory_2__toSRAM_0_re),
    .toSRAM_0_we (i_L2Directory_2__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_2__toSRAM_0_rdata),
    .toSRAM_0_ack (i_L2Directory_2__toSRAM_0_ack),
    .toSRAM_0_selectedOH (i_L2Directory_2__toSRAM_0_selectedOH),
    .toSRAM_0_array (i_L2Directory_2__toSRAM_0_array),
    .toSRAM_1_addr (i_L2Directory_2__toSRAM_1_addr),
    .toSRAM_1_addr_rd (i_L2Directory_2__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (i_L2Directory_2__toSRAM_1_wdata),
    .toSRAM_1_wmask (i_L2Directory_2__toSRAM_1_wmask),
    .toSRAM_1_re (i_L2Directory_2__toSRAM_1_re),
    .toSRAM_1_we (i_L2Directory_2__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_2__toSRAM_1_rdata),
    .toSRAM_1_ack (i_L2Directory_2__toSRAM_1_ack),
    .toSRAM_1_selectedOH (i_L2Directory_2__toSRAM_1_selectedOH),
    .toSRAM_1_array (i_L2Directory_2__toSRAM_1_array),
    .toSRAM_2_addr (i_L2Directory_2__toSRAM_2_addr),
    .toSRAM_2_addr_rd (i_L2Directory_2__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (i_L2Directory_2__toSRAM_2_wdata),
    .toSRAM_2_wmask (i_L2Directory_2__toSRAM_2_wmask),
    .toSRAM_2_re (i_L2Directory_2__toSRAM_2_re),
    .toSRAM_2_we (i_L2Directory_2__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_2__toSRAM_2_rdata),
    .toSRAM_2_ack (i_L2Directory_2__toSRAM_2_ack),
    .toSRAM_2_selectedOH (i_L2Directory_2__toSRAM_2_selectedOH),
    .toSRAM_2_array (i_L2Directory_2__toSRAM_2_array),
    .toSRAM_3_addr (i_L2Directory_2__toSRAM_3_addr),
    .toSRAM_3_addr_rd (i_L2Directory_2__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (i_L2Directory_2__toSRAM_3_wdata),
    .toSRAM_3_wmask (i_L2Directory_2__toSRAM_3_wmask),
    .toSRAM_3_re (i_L2Directory_2__toSRAM_3_re),
    .toSRAM_3_we (i_L2Directory_2__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_2__toSRAM_3_rdata),
    .toSRAM_3_ack (i_L2Directory_2__toSRAM_3_ack),
    .toSRAM_3_selectedOH (i_L2Directory_2__toSRAM_3_selectedOH),
    .toSRAM_3_array (i_L2Directory_2__toSRAM_3_array),
    .toSRAM_4_addr (i_L2Directory_2__toSRAM_4_addr),
    .toSRAM_4_addr_rd (i_L2Directory_2__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (i_L2Directory_2__toSRAM_4_wdata),
    .toSRAM_4_wmask (i_L2Directory_2__toSRAM_4_wmask),
    .toSRAM_4_re (i_L2Directory_2__toSRAM_4_re),
    .toSRAM_4_we (i_L2Directory_2__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_2__toSRAM_4_rdata),
    .toSRAM_4_ack (i_L2Directory_2__toSRAM_4_ack),
    .toSRAM_4_selectedOH (i_L2Directory_2__toSRAM_4_selectedOH),
    .toSRAM_4_array (i_L2Directory_2__toSRAM_4_array),
    .toSRAM_5_addr (i_L2Directory_2__toSRAM_5_addr),
    .toSRAM_5_addr_rd (i_L2Directory_2__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (i_L2Directory_2__toSRAM_5_wdata),
    .toSRAM_5_wmask (i_L2Directory_2__toSRAM_5_wmask),
    .toSRAM_5_re (i_L2Directory_2__toSRAM_5_re),
    .toSRAM_5_we (i_L2Directory_2__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_2__toSRAM_5_rdata),
    .toSRAM_5_ack (i_L2Directory_2__toSRAM_5_ack),
    .toSRAM_5_selectedOH (i_L2Directory_2__toSRAM_5_selectedOH),
    .toSRAM_5_array (i_L2Directory_2__toSRAM_5_array),
    .toSRAM_6_addr (i_L2Directory_2__toSRAM_6_addr),
    .toSRAM_6_addr_rd (i_L2Directory_2__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (i_L2Directory_2__toSRAM_6_wdata),
    .toSRAM_6_wmask (i_L2Directory_2__toSRAM_6_wmask),
    .toSRAM_6_re (i_L2Directory_2__toSRAM_6_re),
    .toSRAM_6_we (i_L2Directory_2__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_2__toSRAM_6_rdata),
    .toSRAM_6_ack (i_L2Directory_2__toSRAM_6_ack),
    .toSRAM_6_selectedOH (i_L2Directory_2__toSRAM_6_selectedOH),
    .toSRAM_6_array (i_L2Directory_2__toSRAM_6_array)
  );
  task automatic drive_L2Directory_2();
    L2Directory_2__mbist_array = rnd(5);
    L2Directory_2__mbist_all = $urandom % 2;
    L2Directory_2__mbist_req = $urandom % 2;
    L2Directory_2__mbist_writeen = $urandom % 2;
    L2Directory_2__mbist_be = rnd(8);
    L2Directory_2__mbist_addr = rnd(10);
    L2Directory_2__mbist_indata = rnd(104);
    L2Directory_2__mbist_readen = $urandom % 2;
    L2Directory_2__mbist_addr_rd = rnd(10);
    L2Directory_2__toSRAM_0_rdata = rnd(76);
    L2Directory_2__toSRAM_1_rdata = rnd(76);
    L2Directory_2__toSRAM_2_rdata = rnd(76);
    L2Directory_2__toSRAM_3_rdata = rnd(76);
    L2Directory_2__toSRAM_4_rdata = rnd(104);
    L2Directory_2__toSRAM_5_rdata = rnd(16);
    L2Directory_2__toSRAM_6_rdata = rnd(8);
  endtask
  task automatic check_L2Directory_2();
    checks++;
    if (g_L2Directory_2__mbist_ack !== i_L2Directory_2__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.mbist_ack g=%h i=%h", cyc, g_L2Directory_2__mbist_ack, i_L2Directory_2__mbist_ack);
    end
    if (g_L2Directory_2__mbist_ack !== p_L2Directory_2__mbist_ack) t_L2Directory_2__mbist_ack = 1'b1;
    p_L2Directory_2__mbist_ack = g_L2Directory_2__mbist_ack;
    checks++;
    if (g_L2Directory_2__mbist_outdata !== i_L2Directory_2__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.mbist_outdata g=%h i=%h", cyc, g_L2Directory_2__mbist_outdata, i_L2Directory_2__mbist_outdata);
    end
    if (g_L2Directory_2__mbist_outdata !== p_L2Directory_2__mbist_outdata) t_L2Directory_2__mbist_outdata = 1'b1;
    p_L2Directory_2__mbist_outdata = g_L2Directory_2__mbist_outdata;
    checks++;
    if (g_L2Directory_2__toSRAM_0_addr !== i_L2Directory_2__toSRAM_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_addr, i_L2Directory_2__toSRAM_0_addr);
    end
    if (g_L2Directory_2__toSRAM_0_addr !== p_L2Directory_2__toSRAM_0_addr) t_L2Directory_2__toSRAM_0_addr = 1'b1;
    p_L2Directory_2__toSRAM_0_addr = g_L2Directory_2__toSRAM_0_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_0_addr_rd !== i_L2Directory_2__toSRAM_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_addr_rd, i_L2Directory_2__toSRAM_0_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_0_addr_rd !== p_L2Directory_2__toSRAM_0_addr_rd) t_L2Directory_2__toSRAM_0_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_0_addr_rd = g_L2Directory_2__toSRAM_0_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_0_wdata !== i_L2Directory_2__toSRAM_0_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_wdata, i_L2Directory_2__toSRAM_0_wdata);
    end
    if (g_L2Directory_2__toSRAM_0_wdata !== p_L2Directory_2__toSRAM_0_wdata) t_L2Directory_2__toSRAM_0_wdata = 1'b1;
    p_L2Directory_2__toSRAM_0_wdata = g_L2Directory_2__toSRAM_0_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_0_wmask !== i_L2Directory_2__toSRAM_0_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_wmask, i_L2Directory_2__toSRAM_0_wmask);
    end
    if (g_L2Directory_2__toSRAM_0_wmask !== p_L2Directory_2__toSRAM_0_wmask) t_L2Directory_2__toSRAM_0_wmask = 1'b1;
    p_L2Directory_2__toSRAM_0_wmask = g_L2Directory_2__toSRAM_0_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_0_re !== i_L2Directory_2__toSRAM_0_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_re, i_L2Directory_2__toSRAM_0_re);
    end
    if (g_L2Directory_2__toSRAM_0_re !== p_L2Directory_2__toSRAM_0_re) t_L2Directory_2__toSRAM_0_re = 1'b1;
    p_L2Directory_2__toSRAM_0_re = g_L2Directory_2__toSRAM_0_re;
    checks++;
    if (g_L2Directory_2__toSRAM_0_we !== i_L2Directory_2__toSRAM_0_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_we, i_L2Directory_2__toSRAM_0_we);
    end
    if (g_L2Directory_2__toSRAM_0_we !== p_L2Directory_2__toSRAM_0_we) t_L2Directory_2__toSRAM_0_we = 1'b1;
    p_L2Directory_2__toSRAM_0_we = g_L2Directory_2__toSRAM_0_we;
    checks++;
    if (g_L2Directory_2__toSRAM_0_ack !== i_L2Directory_2__toSRAM_0_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_ack, i_L2Directory_2__toSRAM_0_ack);
    end
    if (g_L2Directory_2__toSRAM_0_ack !== p_L2Directory_2__toSRAM_0_ack) t_L2Directory_2__toSRAM_0_ack = 1'b1;
    p_L2Directory_2__toSRAM_0_ack = g_L2Directory_2__toSRAM_0_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_0_selectedOH !== i_L2Directory_2__toSRAM_0_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_selectedOH, i_L2Directory_2__toSRAM_0_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_0_selectedOH !== p_L2Directory_2__toSRAM_0_selectedOH) t_L2Directory_2__toSRAM_0_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_0_selectedOH = g_L2Directory_2__toSRAM_0_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_0_array !== i_L2Directory_2__toSRAM_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_0_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_0_array, i_L2Directory_2__toSRAM_0_array);
    end
    if (g_L2Directory_2__toSRAM_0_array !== p_L2Directory_2__toSRAM_0_array) t_L2Directory_2__toSRAM_0_array = 1'b1;
    p_L2Directory_2__toSRAM_0_array = g_L2Directory_2__toSRAM_0_array;
    checks++;
    if (g_L2Directory_2__toSRAM_1_addr !== i_L2Directory_2__toSRAM_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_addr, i_L2Directory_2__toSRAM_1_addr);
    end
    if (g_L2Directory_2__toSRAM_1_addr !== p_L2Directory_2__toSRAM_1_addr) t_L2Directory_2__toSRAM_1_addr = 1'b1;
    p_L2Directory_2__toSRAM_1_addr = g_L2Directory_2__toSRAM_1_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_1_addr_rd !== i_L2Directory_2__toSRAM_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_addr_rd, i_L2Directory_2__toSRAM_1_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_1_addr_rd !== p_L2Directory_2__toSRAM_1_addr_rd) t_L2Directory_2__toSRAM_1_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_1_addr_rd = g_L2Directory_2__toSRAM_1_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_1_wdata !== i_L2Directory_2__toSRAM_1_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_wdata, i_L2Directory_2__toSRAM_1_wdata);
    end
    if (g_L2Directory_2__toSRAM_1_wdata !== p_L2Directory_2__toSRAM_1_wdata) t_L2Directory_2__toSRAM_1_wdata = 1'b1;
    p_L2Directory_2__toSRAM_1_wdata = g_L2Directory_2__toSRAM_1_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_1_wmask !== i_L2Directory_2__toSRAM_1_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_wmask, i_L2Directory_2__toSRAM_1_wmask);
    end
    if (g_L2Directory_2__toSRAM_1_wmask !== p_L2Directory_2__toSRAM_1_wmask) t_L2Directory_2__toSRAM_1_wmask = 1'b1;
    p_L2Directory_2__toSRAM_1_wmask = g_L2Directory_2__toSRAM_1_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_1_re !== i_L2Directory_2__toSRAM_1_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_re, i_L2Directory_2__toSRAM_1_re);
    end
    if (g_L2Directory_2__toSRAM_1_re !== p_L2Directory_2__toSRAM_1_re) t_L2Directory_2__toSRAM_1_re = 1'b1;
    p_L2Directory_2__toSRAM_1_re = g_L2Directory_2__toSRAM_1_re;
    checks++;
    if (g_L2Directory_2__toSRAM_1_we !== i_L2Directory_2__toSRAM_1_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_we, i_L2Directory_2__toSRAM_1_we);
    end
    if (g_L2Directory_2__toSRAM_1_we !== p_L2Directory_2__toSRAM_1_we) t_L2Directory_2__toSRAM_1_we = 1'b1;
    p_L2Directory_2__toSRAM_1_we = g_L2Directory_2__toSRAM_1_we;
    checks++;
    if (g_L2Directory_2__toSRAM_1_ack !== i_L2Directory_2__toSRAM_1_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_ack, i_L2Directory_2__toSRAM_1_ack);
    end
    if (g_L2Directory_2__toSRAM_1_ack !== p_L2Directory_2__toSRAM_1_ack) t_L2Directory_2__toSRAM_1_ack = 1'b1;
    p_L2Directory_2__toSRAM_1_ack = g_L2Directory_2__toSRAM_1_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_1_selectedOH !== i_L2Directory_2__toSRAM_1_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_selectedOH, i_L2Directory_2__toSRAM_1_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_1_selectedOH !== p_L2Directory_2__toSRAM_1_selectedOH) t_L2Directory_2__toSRAM_1_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_1_selectedOH = g_L2Directory_2__toSRAM_1_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_1_array !== i_L2Directory_2__toSRAM_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_1_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_1_array, i_L2Directory_2__toSRAM_1_array);
    end
    if (g_L2Directory_2__toSRAM_1_array !== p_L2Directory_2__toSRAM_1_array) t_L2Directory_2__toSRAM_1_array = 1'b1;
    p_L2Directory_2__toSRAM_1_array = g_L2Directory_2__toSRAM_1_array;
    checks++;
    if (g_L2Directory_2__toSRAM_2_addr !== i_L2Directory_2__toSRAM_2_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_addr, i_L2Directory_2__toSRAM_2_addr);
    end
    if (g_L2Directory_2__toSRAM_2_addr !== p_L2Directory_2__toSRAM_2_addr) t_L2Directory_2__toSRAM_2_addr = 1'b1;
    p_L2Directory_2__toSRAM_2_addr = g_L2Directory_2__toSRAM_2_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_2_addr_rd !== i_L2Directory_2__toSRAM_2_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_addr_rd, i_L2Directory_2__toSRAM_2_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_2_addr_rd !== p_L2Directory_2__toSRAM_2_addr_rd) t_L2Directory_2__toSRAM_2_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_2_addr_rd = g_L2Directory_2__toSRAM_2_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_2_wdata !== i_L2Directory_2__toSRAM_2_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_wdata, i_L2Directory_2__toSRAM_2_wdata);
    end
    if (g_L2Directory_2__toSRAM_2_wdata !== p_L2Directory_2__toSRAM_2_wdata) t_L2Directory_2__toSRAM_2_wdata = 1'b1;
    p_L2Directory_2__toSRAM_2_wdata = g_L2Directory_2__toSRAM_2_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_2_wmask !== i_L2Directory_2__toSRAM_2_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_wmask, i_L2Directory_2__toSRAM_2_wmask);
    end
    if (g_L2Directory_2__toSRAM_2_wmask !== p_L2Directory_2__toSRAM_2_wmask) t_L2Directory_2__toSRAM_2_wmask = 1'b1;
    p_L2Directory_2__toSRAM_2_wmask = g_L2Directory_2__toSRAM_2_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_2_re !== i_L2Directory_2__toSRAM_2_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_re, i_L2Directory_2__toSRAM_2_re);
    end
    if (g_L2Directory_2__toSRAM_2_re !== p_L2Directory_2__toSRAM_2_re) t_L2Directory_2__toSRAM_2_re = 1'b1;
    p_L2Directory_2__toSRAM_2_re = g_L2Directory_2__toSRAM_2_re;
    checks++;
    if (g_L2Directory_2__toSRAM_2_we !== i_L2Directory_2__toSRAM_2_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_we, i_L2Directory_2__toSRAM_2_we);
    end
    if (g_L2Directory_2__toSRAM_2_we !== p_L2Directory_2__toSRAM_2_we) t_L2Directory_2__toSRAM_2_we = 1'b1;
    p_L2Directory_2__toSRAM_2_we = g_L2Directory_2__toSRAM_2_we;
    checks++;
    if (g_L2Directory_2__toSRAM_2_ack !== i_L2Directory_2__toSRAM_2_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_ack, i_L2Directory_2__toSRAM_2_ack);
    end
    if (g_L2Directory_2__toSRAM_2_ack !== p_L2Directory_2__toSRAM_2_ack) t_L2Directory_2__toSRAM_2_ack = 1'b1;
    p_L2Directory_2__toSRAM_2_ack = g_L2Directory_2__toSRAM_2_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_2_selectedOH !== i_L2Directory_2__toSRAM_2_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_selectedOH, i_L2Directory_2__toSRAM_2_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_2_selectedOH !== p_L2Directory_2__toSRAM_2_selectedOH) t_L2Directory_2__toSRAM_2_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_2_selectedOH = g_L2Directory_2__toSRAM_2_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_2_array !== i_L2Directory_2__toSRAM_2_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_2_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_2_array, i_L2Directory_2__toSRAM_2_array);
    end
    if (g_L2Directory_2__toSRAM_2_array !== p_L2Directory_2__toSRAM_2_array) t_L2Directory_2__toSRAM_2_array = 1'b1;
    p_L2Directory_2__toSRAM_2_array = g_L2Directory_2__toSRAM_2_array;
    checks++;
    if (g_L2Directory_2__toSRAM_3_addr !== i_L2Directory_2__toSRAM_3_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_addr, i_L2Directory_2__toSRAM_3_addr);
    end
    if (g_L2Directory_2__toSRAM_3_addr !== p_L2Directory_2__toSRAM_3_addr) t_L2Directory_2__toSRAM_3_addr = 1'b1;
    p_L2Directory_2__toSRAM_3_addr = g_L2Directory_2__toSRAM_3_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_3_addr_rd !== i_L2Directory_2__toSRAM_3_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_addr_rd, i_L2Directory_2__toSRAM_3_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_3_addr_rd !== p_L2Directory_2__toSRAM_3_addr_rd) t_L2Directory_2__toSRAM_3_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_3_addr_rd = g_L2Directory_2__toSRAM_3_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_3_wdata !== i_L2Directory_2__toSRAM_3_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_wdata, i_L2Directory_2__toSRAM_3_wdata);
    end
    if (g_L2Directory_2__toSRAM_3_wdata !== p_L2Directory_2__toSRAM_3_wdata) t_L2Directory_2__toSRAM_3_wdata = 1'b1;
    p_L2Directory_2__toSRAM_3_wdata = g_L2Directory_2__toSRAM_3_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_3_wmask !== i_L2Directory_2__toSRAM_3_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_wmask, i_L2Directory_2__toSRAM_3_wmask);
    end
    if (g_L2Directory_2__toSRAM_3_wmask !== p_L2Directory_2__toSRAM_3_wmask) t_L2Directory_2__toSRAM_3_wmask = 1'b1;
    p_L2Directory_2__toSRAM_3_wmask = g_L2Directory_2__toSRAM_3_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_3_re !== i_L2Directory_2__toSRAM_3_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_re, i_L2Directory_2__toSRAM_3_re);
    end
    if (g_L2Directory_2__toSRAM_3_re !== p_L2Directory_2__toSRAM_3_re) t_L2Directory_2__toSRAM_3_re = 1'b1;
    p_L2Directory_2__toSRAM_3_re = g_L2Directory_2__toSRAM_3_re;
    checks++;
    if (g_L2Directory_2__toSRAM_3_we !== i_L2Directory_2__toSRAM_3_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_we, i_L2Directory_2__toSRAM_3_we);
    end
    if (g_L2Directory_2__toSRAM_3_we !== p_L2Directory_2__toSRAM_3_we) t_L2Directory_2__toSRAM_3_we = 1'b1;
    p_L2Directory_2__toSRAM_3_we = g_L2Directory_2__toSRAM_3_we;
    checks++;
    if (g_L2Directory_2__toSRAM_3_ack !== i_L2Directory_2__toSRAM_3_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_ack, i_L2Directory_2__toSRAM_3_ack);
    end
    if (g_L2Directory_2__toSRAM_3_ack !== p_L2Directory_2__toSRAM_3_ack) t_L2Directory_2__toSRAM_3_ack = 1'b1;
    p_L2Directory_2__toSRAM_3_ack = g_L2Directory_2__toSRAM_3_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_3_selectedOH !== i_L2Directory_2__toSRAM_3_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_selectedOH, i_L2Directory_2__toSRAM_3_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_3_selectedOH !== p_L2Directory_2__toSRAM_3_selectedOH) t_L2Directory_2__toSRAM_3_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_3_selectedOH = g_L2Directory_2__toSRAM_3_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_3_array !== i_L2Directory_2__toSRAM_3_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_3_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_3_array, i_L2Directory_2__toSRAM_3_array);
    end
    if (g_L2Directory_2__toSRAM_3_array !== p_L2Directory_2__toSRAM_3_array) t_L2Directory_2__toSRAM_3_array = 1'b1;
    p_L2Directory_2__toSRAM_3_array = g_L2Directory_2__toSRAM_3_array;
    checks++;
    if (g_L2Directory_2__toSRAM_4_addr !== i_L2Directory_2__toSRAM_4_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_addr, i_L2Directory_2__toSRAM_4_addr);
    end
    if (g_L2Directory_2__toSRAM_4_addr !== p_L2Directory_2__toSRAM_4_addr) t_L2Directory_2__toSRAM_4_addr = 1'b1;
    p_L2Directory_2__toSRAM_4_addr = g_L2Directory_2__toSRAM_4_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_4_addr_rd !== i_L2Directory_2__toSRAM_4_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_addr_rd, i_L2Directory_2__toSRAM_4_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_4_addr_rd !== p_L2Directory_2__toSRAM_4_addr_rd) t_L2Directory_2__toSRAM_4_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_4_addr_rd = g_L2Directory_2__toSRAM_4_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_4_wdata !== i_L2Directory_2__toSRAM_4_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_wdata, i_L2Directory_2__toSRAM_4_wdata);
    end
    if (g_L2Directory_2__toSRAM_4_wdata !== p_L2Directory_2__toSRAM_4_wdata) t_L2Directory_2__toSRAM_4_wdata = 1'b1;
    p_L2Directory_2__toSRAM_4_wdata = g_L2Directory_2__toSRAM_4_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_4_wmask !== i_L2Directory_2__toSRAM_4_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_wmask, i_L2Directory_2__toSRAM_4_wmask);
    end
    if (g_L2Directory_2__toSRAM_4_wmask !== p_L2Directory_2__toSRAM_4_wmask) t_L2Directory_2__toSRAM_4_wmask = 1'b1;
    p_L2Directory_2__toSRAM_4_wmask = g_L2Directory_2__toSRAM_4_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_4_re !== i_L2Directory_2__toSRAM_4_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_re, i_L2Directory_2__toSRAM_4_re);
    end
    if (g_L2Directory_2__toSRAM_4_re !== p_L2Directory_2__toSRAM_4_re) t_L2Directory_2__toSRAM_4_re = 1'b1;
    p_L2Directory_2__toSRAM_4_re = g_L2Directory_2__toSRAM_4_re;
    checks++;
    if (g_L2Directory_2__toSRAM_4_we !== i_L2Directory_2__toSRAM_4_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_we, i_L2Directory_2__toSRAM_4_we);
    end
    if (g_L2Directory_2__toSRAM_4_we !== p_L2Directory_2__toSRAM_4_we) t_L2Directory_2__toSRAM_4_we = 1'b1;
    p_L2Directory_2__toSRAM_4_we = g_L2Directory_2__toSRAM_4_we;
    checks++;
    if (g_L2Directory_2__toSRAM_4_ack !== i_L2Directory_2__toSRAM_4_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_ack, i_L2Directory_2__toSRAM_4_ack);
    end
    if (g_L2Directory_2__toSRAM_4_ack !== p_L2Directory_2__toSRAM_4_ack) t_L2Directory_2__toSRAM_4_ack = 1'b1;
    p_L2Directory_2__toSRAM_4_ack = g_L2Directory_2__toSRAM_4_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_4_selectedOH !== i_L2Directory_2__toSRAM_4_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_selectedOH, i_L2Directory_2__toSRAM_4_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_4_selectedOH !== p_L2Directory_2__toSRAM_4_selectedOH) t_L2Directory_2__toSRAM_4_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_4_selectedOH = g_L2Directory_2__toSRAM_4_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_4_array !== i_L2Directory_2__toSRAM_4_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_4_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_4_array, i_L2Directory_2__toSRAM_4_array);
    end
    if (g_L2Directory_2__toSRAM_4_array !== p_L2Directory_2__toSRAM_4_array) t_L2Directory_2__toSRAM_4_array = 1'b1;
    p_L2Directory_2__toSRAM_4_array = g_L2Directory_2__toSRAM_4_array;
    checks++;
    if (g_L2Directory_2__toSRAM_5_addr !== i_L2Directory_2__toSRAM_5_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_addr, i_L2Directory_2__toSRAM_5_addr);
    end
    if (g_L2Directory_2__toSRAM_5_addr !== p_L2Directory_2__toSRAM_5_addr) t_L2Directory_2__toSRAM_5_addr = 1'b1;
    p_L2Directory_2__toSRAM_5_addr = g_L2Directory_2__toSRAM_5_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_5_addr_rd !== i_L2Directory_2__toSRAM_5_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_addr_rd, i_L2Directory_2__toSRAM_5_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_5_addr_rd !== p_L2Directory_2__toSRAM_5_addr_rd) t_L2Directory_2__toSRAM_5_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_5_addr_rd = g_L2Directory_2__toSRAM_5_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_5_wdata !== i_L2Directory_2__toSRAM_5_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_wdata, i_L2Directory_2__toSRAM_5_wdata);
    end
    if (g_L2Directory_2__toSRAM_5_wdata !== p_L2Directory_2__toSRAM_5_wdata) t_L2Directory_2__toSRAM_5_wdata = 1'b1;
    p_L2Directory_2__toSRAM_5_wdata = g_L2Directory_2__toSRAM_5_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_5_wmask !== i_L2Directory_2__toSRAM_5_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_wmask, i_L2Directory_2__toSRAM_5_wmask);
    end
    if (g_L2Directory_2__toSRAM_5_wmask !== p_L2Directory_2__toSRAM_5_wmask) t_L2Directory_2__toSRAM_5_wmask = 1'b1;
    p_L2Directory_2__toSRAM_5_wmask = g_L2Directory_2__toSRAM_5_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_5_re !== i_L2Directory_2__toSRAM_5_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_re, i_L2Directory_2__toSRAM_5_re);
    end
    if (g_L2Directory_2__toSRAM_5_re !== p_L2Directory_2__toSRAM_5_re) t_L2Directory_2__toSRAM_5_re = 1'b1;
    p_L2Directory_2__toSRAM_5_re = g_L2Directory_2__toSRAM_5_re;
    checks++;
    if (g_L2Directory_2__toSRAM_5_we !== i_L2Directory_2__toSRAM_5_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_we, i_L2Directory_2__toSRAM_5_we);
    end
    if (g_L2Directory_2__toSRAM_5_we !== p_L2Directory_2__toSRAM_5_we) t_L2Directory_2__toSRAM_5_we = 1'b1;
    p_L2Directory_2__toSRAM_5_we = g_L2Directory_2__toSRAM_5_we;
    checks++;
    if (g_L2Directory_2__toSRAM_5_ack !== i_L2Directory_2__toSRAM_5_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_ack, i_L2Directory_2__toSRAM_5_ack);
    end
    if (g_L2Directory_2__toSRAM_5_ack !== p_L2Directory_2__toSRAM_5_ack) t_L2Directory_2__toSRAM_5_ack = 1'b1;
    p_L2Directory_2__toSRAM_5_ack = g_L2Directory_2__toSRAM_5_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_5_selectedOH !== i_L2Directory_2__toSRAM_5_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_selectedOH, i_L2Directory_2__toSRAM_5_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_5_selectedOH !== p_L2Directory_2__toSRAM_5_selectedOH) t_L2Directory_2__toSRAM_5_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_5_selectedOH = g_L2Directory_2__toSRAM_5_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_5_array !== i_L2Directory_2__toSRAM_5_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_5_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_5_array, i_L2Directory_2__toSRAM_5_array);
    end
    if (g_L2Directory_2__toSRAM_5_array !== p_L2Directory_2__toSRAM_5_array) t_L2Directory_2__toSRAM_5_array = 1'b1;
    p_L2Directory_2__toSRAM_5_array = g_L2Directory_2__toSRAM_5_array;
    checks++;
    if (g_L2Directory_2__toSRAM_6_addr !== i_L2Directory_2__toSRAM_6_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_addr g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_addr, i_L2Directory_2__toSRAM_6_addr);
    end
    if (g_L2Directory_2__toSRAM_6_addr !== p_L2Directory_2__toSRAM_6_addr) t_L2Directory_2__toSRAM_6_addr = 1'b1;
    p_L2Directory_2__toSRAM_6_addr = g_L2Directory_2__toSRAM_6_addr;
    checks++;
    if (g_L2Directory_2__toSRAM_6_addr_rd !== i_L2Directory_2__toSRAM_6_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_addr_rd g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_addr_rd, i_L2Directory_2__toSRAM_6_addr_rd);
    end
    if (g_L2Directory_2__toSRAM_6_addr_rd !== p_L2Directory_2__toSRAM_6_addr_rd) t_L2Directory_2__toSRAM_6_addr_rd = 1'b1;
    p_L2Directory_2__toSRAM_6_addr_rd = g_L2Directory_2__toSRAM_6_addr_rd;
    checks++;
    if (g_L2Directory_2__toSRAM_6_wdata !== i_L2Directory_2__toSRAM_6_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_wdata g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_wdata, i_L2Directory_2__toSRAM_6_wdata);
    end
    if (g_L2Directory_2__toSRAM_6_wdata !== p_L2Directory_2__toSRAM_6_wdata) t_L2Directory_2__toSRAM_6_wdata = 1'b1;
    p_L2Directory_2__toSRAM_6_wdata = g_L2Directory_2__toSRAM_6_wdata;
    checks++;
    if (g_L2Directory_2__toSRAM_6_wmask !== i_L2Directory_2__toSRAM_6_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_wmask g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_wmask, i_L2Directory_2__toSRAM_6_wmask);
    end
    if (g_L2Directory_2__toSRAM_6_wmask !== p_L2Directory_2__toSRAM_6_wmask) t_L2Directory_2__toSRAM_6_wmask = 1'b1;
    p_L2Directory_2__toSRAM_6_wmask = g_L2Directory_2__toSRAM_6_wmask;
    checks++;
    if (g_L2Directory_2__toSRAM_6_re !== i_L2Directory_2__toSRAM_6_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_re g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_re, i_L2Directory_2__toSRAM_6_re);
    end
    if (g_L2Directory_2__toSRAM_6_re !== p_L2Directory_2__toSRAM_6_re) t_L2Directory_2__toSRAM_6_re = 1'b1;
    p_L2Directory_2__toSRAM_6_re = g_L2Directory_2__toSRAM_6_re;
    checks++;
    if (g_L2Directory_2__toSRAM_6_we !== i_L2Directory_2__toSRAM_6_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_we g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_we, i_L2Directory_2__toSRAM_6_we);
    end
    if (g_L2Directory_2__toSRAM_6_we !== p_L2Directory_2__toSRAM_6_we) t_L2Directory_2__toSRAM_6_we = 1'b1;
    p_L2Directory_2__toSRAM_6_we = g_L2Directory_2__toSRAM_6_we;
    checks++;
    if (g_L2Directory_2__toSRAM_6_ack !== i_L2Directory_2__toSRAM_6_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_ack g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_ack, i_L2Directory_2__toSRAM_6_ack);
    end
    if (g_L2Directory_2__toSRAM_6_ack !== p_L2Directory_2__toSRAM_6_ack) t_L2Directory_2__toSRAM_6_ack = 1'b1;
    p_L2Directory_2__toSRAM_6_ack = g_L2Directory_2__toSRAM_6_ack;
    checks++;
    if (g_L2Directory_2__toSRAM_6_selectedOH !== i_L2Directory_2__toSRAM_6_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_selectedOH g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_selectedOH, i_L2Directory_2__toSRAM_6_selectedOH);
    end
    if (g_L2Directory_2__toSRAM_6_selectedOH !== p_L2Directory_2__toSRAM_6_selectedOH) t_L2Directory_2__toSRAM_6_selectedOH = 1'b1;
    p_L2Directory_2__toSRAM_6_selectedOH = g_L2Directory_2__toSRAM_6_selectedOH;
    checks++;
    if (g_L2Directory_2__toSRAM_6_array !== i_L2Directory_2__toSRAM_6_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_2.toSRAM_6_array g=%h i=%h", cyc, g_L2Directory_2__toSRAM_6_array, i_L2Directory_2__toSRAM_6_array);
    end
    if (g_L2Directory_2__toSRAM_6_array !== p_L2Directory_2__toSRAM_6_array) t_L2Directory_2__toSRAM_6_array = 1'b1;
    p_L2Directory_2__toSRAM_6_array = g_L2Directory_2__toSRAM_6_array;
  endtask
  longint cov_L2Directory_2_act = 0;
  longint cov_L2Directory_2_sel6 = 0;
  task automatic cover_L2Directory_2();
    if (u_g_L2Directory_2.activated) cov_L2Directory_2_act++;
    if (u_g_L2Directory_2.selectedVec_0_6) cov_L2Directory_2_sel6++;
  endtask
  task automatic preinit_L2Directory_2();
  endtask
  task automatic sync_L2Directory_2();
  endtask

  // ======================= L2Directory_3 =======================
  logic [5:0] L2Directory_3__mbist_array;
  logic L2Directory_3__mbist_all;
  logic L2Directory_3__mbist_req;
  logic L2Directory_3__mbist_writeen;
  logic [7:0] L2Directory_3__mbist_be;
  logic [9:0] L2Directory_3__mbist_addr;
  logic [103:0] L2Directory_3__mbist_indata;
  logic L2Directory_3__mbist_readen;
  logic [9:0] L2Directory_3__mbist_addr_rd;
  logic [75:0] L2Directory_3__toSRAM_0_rdata;
  logic [75:0] L2Directory_3__toSRAM_1_rdata;
  logic [75:0] L2Directory_3__toSRAM_2_rdata;
  logic [75:0] L2Directory_3__toSRAM_3_rdata;
  logic [103:0] L2Directory_3__toSRAM_4_rdata;
  logic [15:0] L2Directory_3__toSRAM_5_rdata;
  logic [7:0] L2Directory_3__toSRAM_6_rdata;
  wire  g_L2Directory_3__mbist_ack;
  wire  i_L2Directory_3__mbist_ack;
  logic p_L2Directory_3__mbist_ack;
  bit   t_L2Directory_3__mbist_ack;
  wire  [103:0] g_L2Directory_3__mbist_outdata;
  wire  [103:0] i_L2Directory_3__mbist_outdata;
  logic [103:0] p_L2Directory_3__mbist_outdata;
  bit   t_L2Directory_3__mbist_outdata;
  wire  [9:0] g_L2Directory_3__toSRAM_0_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_0_addr;
  logic [9:0] p_L2Directory_3__toSRAM_0_addr;
  bit   t_L2Directory_3__toSRAM_0_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_0_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_0_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_0_addr_rd;
  bit   t_L2Directory_3__toSRAM_0_addr_rd;
  wire  [75:0] g_L2Directory_3__toSRAM_0_wdata;
  wire  [75:0] i_L2Directory_3__toSRAM_0_wdata;
  logic [75:0] p_L2Directory_3__toSRAM_0_wdata;
  bit   t_L2Directory_3__toSRAM_0_wdata;
  wire  [3:0] g_L2Directory_3__toSRAM_0_wmask;
  wire  [3:0] i_L2Directory_3__toSRAM_0_wmask;
  logic [3:0] p_L2Directory_3__toSRAM_0_wmask;
  bit   t_L2Directory_3__toSRAM_0_wmask;
  wire  g_L2Directory_3__toSRAM_0_re;
  wire  i_L2Directory_3__toSRAM_0_re;
  logic p_L2Directory_3__toSRAM_0_re;
  bit   t_L2Directory_3__toSRAM_0_re;
  wire  g_L2Directory_3__toSRAM_0_we;
  wire  i_L2Directory_3__toSRAM_0_we;
  logic p_L2Directory_3__toSRAM_0_we;
  bit   t_L2Directory_3__toSRAM_0_we;
  wire  g_L2Directory_3__toSRAM_0_ack;
  wire  i_L2Directory_3__toSRAM_0_ack;
  logic p_L2Directory_3__toSRAM_0_ack;
  bit   t_L2Directory_3__toSRAM_0_ack;
  wire  g_L2Directory_3__toSRAM_0_selectedOH;
  wire  i_L2Directory_3__toSRAM_0_selectedOH;
  logic p_L2Directory_3__toSRAM_0_selectedOH;
  bit   t_L2Directory_3__toSRAM_0_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_0_array;
  wire  [5:0] i_L2Directory_3__toSRAM_0_array;
  logic [5:0] p_L2Directory_3__toSRAM_0_array;
  bit   t_L2Directory_3__toSRAM_0_array;
  wire  [9:0] g_L2Directory_3__toSRAM_1_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_1_addr;
  logic [9:0] p_L2Directory_3__toSRAM_1_addr;
  bit   t_L2Directory_3__toSRAM_1_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_1_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_1_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_1_addr_rd;
  bit   t_L2Directory_3__toSRAM_1_addr_rd;
  wire  [75:0] g_L2Directory_3__toSRAM_1_wdata;
  wire  [75:0] i_L2Directory_3__toSRAM_1_wdata;
  logic [75:0] p_L2Directory_3__toSRAM_1_wdata;
  bit   t_L2Directory_3__toSRAM_1_wdata;
  wire  [3:0] g_L2Directory_3__toSRAM_1_wmask;
  wire  [3:0] i_L2Directory_3__toSRAM_1_wmask;
  logic [3:0] p_L2Directory_3__toSRAM_1_wmask;
  bit   t_L2Directory_3__toSRAM_1_wmask;
  wire  g_L2Directory_3__toSRAM_1_re;
  wire  i_L2Directory_3__toSRAM_1_re;
  logic p_L2Directory_3__toSRAM_1_re;
  bit   t_L2Directory_3__toSRAM_1_re;
  wire  g_L2Directory_3__toSRAM_1_we;
  wire  i_L2Directory_3__toSRAM_1_we;
  logic p_L2Directory_3__toSRAM_1_we;
  bit   t_L2Directory_3__toSRAM_1_we;
  wire  g_L2Directory_3__toSRAM_1_ack;
  wire  i_L2Directory_3__toSRAM_1_ack;
  logic p_L2Directory_3__toSRAM_1_ack;
  bit   t_L2Directory_3__toSRAM_1_ack;
  wire  g_L2Directory_3__toSRAM_1_selectedOH;
  wire  i_L2Directory_3__toSRAM_1_selectedOH;
  logic p_L2Directory_3__toSRAM_1_selectedOH;
  bit   t_L2Directory_3__toSRAM_1_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_1_array;
  wire  [5:0] i_L2Directory_3__toSRAM_1_array;
  logic [5:0] p_L2Directory_3__toSRAM_1_array;
  bit   t_L2Directory_3__toSRAM_1_array;
  wire  [9:0] g_L2Directory_3__toSRAM_2_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_2_addr;
  logic [9:0] p_L2Directory_3__toSRAM_2_addr;
  bit   t_L2Directory_3__toSRAM_2_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_2_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_2_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_2_addr_rd;
  bit   t_L2Directory_3__toSRAM_2_addr_rd;
  wire  [75:0] g_L2Directory_3__toSRAM_2_wdata;
  wire  [75:0] i_L2Directory_3__toSRAM_2_wdata;
  logic [75:0] p_L2Directory_3__toSRAM_2_wdata;
  bit   t_L2Directory_3__toSRAM_2_wdata;
  wire  [3:0] g_L2Directory_3__toSRAM_2_wmask;
  wire  [3:0] i_L2Directory_3__toSRAM_2_wmask;
  logic [3:0] p_L2Directory_3__toSRAM_2_wmask;
  bit   t_L2Directory_3__toSRAM_2_wmask;
  wire  g_L2Directory_3__toSRAM_2_re;
  wire  i_L2Directory_3__toSRAM_2_re;
  logic p_L2Directory_3__toSRAM_2_re;
  bit   t_L2Directory_3__toSRAM_2_re;
  wire  g_L2Directory_3__toSRAM_2_we;
  wire  i_L2Directory_3__toSRAM_2_we;
  logic p_L2Directory_3__toSRAM_2_we;
  bit   t_L2Directory_3__toSRAM_2_we;
  wire  g_L2Directory_3__toSRAM_2_ack;
  wire  i_L2Directory_3__toSRAM_2_ack;
  logic p_L2Directory_3__toSRAM_2_ack;
  bit   t_L2Directory_3__toSRAM_2_ack;
  wire  g_L2Directory_3__toSRAM_2_selectedOH;
  wire  i_L2Directory_3__toSRAM_2_selectedOH;
  logic p_L2Directory_3__toSRAM_2_selectedOH;
  bit   t_L2Directory_3__toSRAM_2_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_2_array;
  wire  [5:0] i_L2Directory_3__toSRAM_2_array;
  logic [5:0] p_L2Directory_3__toSRAM_2_array;
  bit   t_L2Directory_3__toSRAM_2_array;
  wire  [9:0] g_L2Directory_3__toSRAM_3_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_3_addr;
  logic [9:0] p_L2Directory_3__toSRAM_3_addr;
  bit   t_L2Directory_3__toSRAM_3_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_3_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_3_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_3_addr_rd;
  bit   t_L2Directory_3__toSRAM_3_addr_rd;
  wire  [75:0] g_L2Directory_3__toSRAM_3_wdata;
  wire  [75:0] i_L2Directory_3__toSRAM_3_wdata;
  logic [75:0] p_L2Directory_3__toSRAM_3_wdata;
  bit   t_L2Directory_3__toSRAM_3_wdata;
  wire  [3:0] g_L2Directory_3__toSRAM_3_wmask;
  wire  [3:0] i_L2Directory_3__toSRAM_3_wmask;
  logic [3:0] p_L2Directory_3__toSRAM_3_wmask;
  bit   t_L2Directory_3__toSRAM_3_wmask;
  wire  g_L2Directory_3__toSRAM_3_re;
  wire  i_L2Directory_3__toSRAM_3_re;
  logic p_L2Directory_3__toSRAM_3_re;
  bit   t_L2Directory_3__toSRAM_3_re;
  wire  g_L2Directory_3__toSRAM_3_we;
  wire  i_L2Directory_3__toSRAM_3_we;
  logic p_L2Directory_3__toSRAM_3_we;
  bit   t_L2Directory_3__toSRAM_3_we;
  wire  g_L2Directory_3__toSRAM_3_ack;
  wire  i_L2Directory_3__toSRAM_3_ack;
  logic p_L2Directory_3__toSRAM_3_ack;
  bit   t_L2Directory_3__toSRAM_3_ack;
  wire  g_L2Directory_3__toSRAM_3_selectedOH;
  wire  i_L2Directory_3__toSRAM_3_selectedOH;
  logic p_L2Directory_3__toSRAM_3_selectedOH;
  bit   t_L2Directory_3__toSRAM_3_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_3_array;
  wire  [5:0] i_L2Directory_3__toSRAM_3_array;
  logic [5:0] p_L2Directory_3__toSRAM_3_array;
  bit   t_L2Directory_3__toSRAM_3_array;
  wire  [9:0] g_L2Directory_3__toSRAM_4_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_4_addr;
  logic [9:0] p_L2Directory_3__toSRAM_4_addr;
  bit   t_L2Directory_3__toSRAM_4_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_4_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_4_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_4_addr_rd;
  bit   t_L2Directory_3__toSRAM_4_addr_rd;
  wire  [103:0] g_L2Directory_3__toSRAM_4_wdata;
  wire  [103:0] i_L2Directory_3__toSRAM_4_wdata;
  logic [103:0] p_L2Directory_3__toSRAM_4_wdata;
  bit   t_L2Directory_3__toSRAM_4_wdata;
  wire  [7:0] g_L2Directory_3__toSRAM_4_wmask;
  wire  [7:0] i_L2Directory_3__toSRAM_4_wmask;
  logic [7:0] p_L2Directory_3__toSRAM_4_wmask;
  bit   t_L2Directory_3__toSRAM_4_wmask;
  wire  g_L2Directory_3__toSRAM_4_re;
  wire  i_L2Directory_3__toSRAM_4_re;
  logic p_L2Directory_3__toSRAM_4_re;
  bit   t_L2Directory_3__toSRAM_4_re;
  wire  g_L2Directory_3__toSRAM_4_we;
  wire  i_L2Directory_3__toSRAM_4_we;
  logic p_L2Directory_3__toSRAM_4_we;
  bit   t_L2Directory_3__toSRAM_4_we;
  wire  g_L2Directory_3__toSRAM_4_ack;
  wire  i_L2Directory_3__toSRAM_4_ack;
  logic p_L2Directory_3__toSRAM_4_ack;
  bit   t_L2Directory_3__toSRAM_4_ack;
  wire  g_L2Directory_3__toSRAM_4_selectedOH;
  wire  i_L2Directory_3__toSRAM_4_selectedOH;
  logic p_L2Directory_3__toSRAM_4_selectedOH;
  bit   t_L2Directory_3__toSRAM_4_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_4_array;
  wire  [5:0] i_L2Directory_3__toSRAM_4_array;
  logic [5:0] p_L2Directory_3__toSRAM_4_array;
  bit   t_L2Directory_3__toSRAM_4_array;
  wire  [9:0] g_L2Directory_3__toSRAM_5_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_5_addr;
  logic [9:0] p_L2Directory_3__toSRAM_5_addr;
  bit   t_L2Directory_3__toSRAM_5_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_5_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_5_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_5_addr_rd;
  bit   t_L2Directory_3__toSRAM_5_addr_rd;
  wire  [15:0] g_L2Directory_3__toSRAM_5_wdata;
  wire  [15:0] i_L2Directory_3__toSRAM_5_wdata;
  logic [15:0] p_L2Directory_3__toSRAM_5_wdata;
  bit   t_L2Directory_3__toSRAM_5_wdata;
  wire  g_L2Directory_3__toSRAM_5_wmask;
  wire  i_L2Directory_3__toSRAM_5_wmask;
  logic p_L2Directory_3__toSRAM_5_wmask;
  bit   t_L2Directory_3__toSRAM_5_wmask;
  wire  g_L2Directory_3__toSRAM_5_re;
  wire  i_L2Directory_3__toSRAM_5_re;
  logic p_L2Directory_3__toSRAM_5_re;
  bit   t_L2Directory_3__toSRAM_5_re;
  wire  g_L2Directory_3__toSRAM_5_we;
  wire  i_L2Directory_3__toSRAM_5_we;
  logic p_L2Directory_3__toSRAM_5_we;
  bit   t_L2Directory_3__toSRAM_5_we;
  wire  g_L2Directory_3__toSRAM_5_ack;
  wire  i_L2Directory_3__toSRAM_5_ack;
  logic p_L2Directory_3__toSRAM_5_ack;
  bit   t_L2Directory_3__toSRAM_5_ack;
  wire  g_L2Directory_3__toSRAM_5_selectedOH;
  wire  i_L2Directory_3__toSRAM_5_selectedOH;
  logic p_L2Directory_3__toSRAM_5_selectedOH;
  bit   t_L2Directory_3__toSRAM_5_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_5_array;
  wire  [5:0] i_L2Directory_3__toSRAM_5_array;
  logic [5:0] p_L2Directory_3__toSRAM_5_array;
  bit   t_L2Directory_3__toSRAM_5_array;
  wire  [9:0] g_L2Directory_3__toSRAM_6_addr;
  wire  [9:0] i_L2Directory_3__toSRAM_6_addr;
  logic [9:0] p_L2Directory_3__toSRAM_6_addr;
  bit   t_L2Directory_3__toSRAM_6_addr;
  wire  [9:0] g_L2Directory_3__toSRAM_6_addr_rd;
  wire  [9:0] i_L2Directory_3__toSRAM_6_addr_rd;
  logic [9:0] p_L2Directory_3__toSRAM_6_addr_rd;
  bit   t_L2Directory_3__toSRAM_6_addr_rd;
  wire  [7:0] g_L2Directory_3__toSRAM_6_wdata;
  wire  [7:0] i_L2Directory_3__toSRAM_6_wdata;
  logic [7:0] p_L2Directory_3__toSRAM_6_wdata;
  bit   t_L2Directory_3__toSRAM_6_wdata;
  wire  [7:0] g_L2Directory_3__toSRAM_6_wmask;
  wire  [7:0] i_L2Directory_3__toSRAM_6_wmask;
  logic [7:0] p_L2Directory_3__toSRAM_6_wmask;
  bit   t_L2Directory_3__toSRAM_6_wmask;
  wire  g_L2Directory_3__toSRAM_6_re;
  wire  i_L2Directory_3__toSRAM_6_re;
  logic p_L2Directory_3__toSRAM_6_re;
  bit   t_L2Directory_3__toSRAM_6_re;
  wire  g_L2Directory_3__toSRAM_6_we;
  wire  i_L2Directory_3__toSRAM_6_we;
  logic p_L2Directory_3__toSRAM_6_we;
  bit   t_L2Directory_3__toSRAM_6_we;
  wire  g_L2Directory_3__toSRAM_6_ack;
  wire  i_L2Directory_3__toSRAM_6_ack;
  logic p_L2Directory_3__toSRAM_6_ack;
  bit   t_L2Directory_3__toSRAM_6_ack;
  wire  g_L2Directory_3__toSRAM_6_selectedOH;
  wire  i_L2Directory_3__toSRAM_6_selectedOH;
  logic p_L2Directory_3__toSRAM_6_selectedOH;
  bit   t_L2Directory_3__toSRAM_6_selectedOH;
  wire  [5:0] g_L2Directory_3__toSRAM_6_array;
  wire  [5:0] i_L2Directory_3__toSRAM_6_array;
  logic [5:0] p_L2Directory_3__toSRAM_6_array;
  bit   t_L2Directory_3__toSRAM_6_array;
  L2Directory_3 u_g_L2Directory_3 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_3__mbist_array),
    .mbist_all (L2Directory_3__mbist_all),
    .mbist_req (L2Directory_3__mbist_req),
    .mbist_ack (g_L2Directory_3__mbist_ack),
    .mbist_writeen (L2Directory_3__mbist_writeen),
    .mbist_be (L2Directory_3__mbist_be),
    .mbist_addr (L2Directory_3__mbist_addr),
    .mbist_indata (L2Directory_3__mbist_indata),
    .mbist_readen (L2Directory_3__mbist_readen),
    .mbist_addr_rd (L2Directory_3__mbist_addr_rd),
    .mbist_outdata (g_L2Directory_3__mbist_outdata),
    .toSRAM_0_addr (g_L2Directory_3__toSRAM_0_addr),
    .toSRAM_0_addr_rd (g_L2Directory_3__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g_L2Directory_3__toSRAM_0_wdata),
    .toSRAM_0_wmask (g_L2Directory_3__toSRAM_0_wmask),
    .toSRAM_0_re (g_L2Directory_3__toSRAM_0_re),
    .toSRAM_0_we (g_L2Directory_3__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_3__toSRAM_0_rdata),
    .toSRAM_0_ack (g_L2Directory_3__toSRAM_0_ack),
    .toSRAM_0_selectedOH (g_L2Directory_3__toSRAM_0_selectedOH),
    .toSRAM_0_array (g_L2Directory_3__toSRAM_0_array),
    .toSRAM_1_addr (g_L2Directory_3__toSRAM_1_addr),
    .toSRAM_1_addr_rd (g_L2Directory_3__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g_L2Directory_3__toSRAM_1_wdata),
    .toSRAM_1_wmask (g_L2Directory_3__toSRAM_1_wmask),
    .toSRAM_1_re (g_L2Directory_3__toSRAM_1_re),
    .toSRAM_1_we (g_L2Directory_3__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_3__toSRAM_1_rdata),
    .toSRAM_1_ack (g_L2Directory_3__toSRAM_1_ack),
    .toSRAM_1_selectedOH (g_L2Directory_3__toSRAM_1_selectedOH),
    .toSRAM_1_array (g_L2Directory_3__toSRAM_1_array),
    .toSRAM_2_addr (g_L2Directory_3__toSRAM_2_addr),
    .toSRAM_2_addr_rd (g_L2Directory_3__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g_L2Directory_3__toSRAM_2_wdata),
    .toSRAM_2_wmask (g_L2Directory_3__toSRAM_2_wmask),
    .toSRAM_2_re (g_L2Directory_3__toSRAM_2_re),
    .toSRAM_2_we (g_L2Directory_3__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_3__toSRAM_2_rdata),
    .toSRAM_2_ack (g_L2Directory_3__toSRAM_2_ack),
    .toSRAM_2_selectedOH (g_L2Directory_3__toSRAM_2_selectedOH),
    .toSRAM_2_array (g_L2Directory_3__toSRAM_2_array),
    .toSRAM_3_addr (g_L2Directory_3__toSRAM_3_addr),
    .toSRAM_3_addr_rd (g_L2Directory_3__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g_L2Directory_3__toSRAM_3_wdata),
    .toSRAM_3_wmask (g_L2Directory_3__toSRAM_3_wmask),
    .toSRAM_3_re (g_L2Directory_3__toSRAM_3_re),
    .toSRAM_3_we (g_L2Directory_3__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_3__toSRAM_3_rdata),
    .toSRAM_3_ack (g_L2Directory_3__toSRAM_3_ack),
    .toSRAM_3_selectedOH (g_L2Directory_3__toSRAM_3_selectedOH),
    .toSRAM_3_array (g_L2Directory_3__toSRAM_3_array),
    .toSRAM_4_addr (g_L2Directory_3__toSRAM_4_addr),
    .toSRAM_4_addr_rd (g_L2Directory_3__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g_L2Directory_3__toSRAM_4_wdata),
    .toSRAM_4_wmask (g_L2Directory_3__toSRAM_4_wmask),
    .toSRAM_4_re (g_L2Directory_3__toSRAM_4_re),
    .toSRAM_4_we (g_L2Directory_3__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_3__toSRAM_4_rdata),
    .toSRAM_4_ack (g_L2Directory_3__toSRAM_4_ack),
    .toSRAM_4_selectedOH (g_L2Directory_3__toSRAM_4_selectedOH),
    .toSRAM_4_array (g_L2Directory_3__toSRAM_4_array),
    .toSRAM_5_addr (g_L2Directory_3__toSRAM_5_addr),
    .toSRAM_5_addr_rd (g_L2Directory_3__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g_L2Directory_3__toSRAM_5_wdata),
    .toSRAM_5_wmask (g_L2Directory_3__toSRAM_5_wmask),
    .toSRAM_5_re (g_L2Directory_3__toSRAM_5_re),
    .toSRAM_5_we (g_L2Directory_3__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_3__toSRAM_5_rdata),
    .toSRAM_5_ack (g_L2Directory_3__toSRAM_5_ack),
    .toSRAM_5_selectedOH (g_L2Directory_3__toSRAM_5_selectedOH),
    .toSRAM_5_array (g_L2Directory_3__toSRAM_5_array),
    .toSRAM_6_addr (g_L2Directory_3__toSRAM_6_addr),
    .toSRAM_6_addr_rd (g_L2Directory_3__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g_L2Directory_3__toSRAM_6_wdata),
    .toSRAM_6_wmask (g_L2Directory_3__toSRAM_6_wmask),
    .toSRAM_6_re (g_L2Directory_3__toSRAM_6_re),
    .toSRAM_6_we (g_L2Directory_3__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_3__toSRAM_6_rdata),
    .toSRAM_6_ack (g_L2Directory_3__toSRAM_6_ack),
    .toSRAM_6_selectedOH (g_L2Directory_3__toSRAM_6_selectedOH),
    .toSRAM_6_array (g_L2Directory_3__toSRAM_6_array)
  );
  L2Directory_3_xs u_i_L2Directory_3 (
    .clock (clock),
    .reset (reset),
    .mbist_array (L2Directory_3__mbist_array),
    .mbist_all (L2Directory_3__mbist_all),
    .mbist_req (L2Directory_3__mbist_req),
    .mbist_ack (i_L2Directory_3__mbist_ack),
    .mbist_writeen (L2Directory_3__mbist_writeen),
    .mbist_be (L2Directory_3__mbist_be),
    .mbist_addr (L2Directory_3__mbist_addr),
    .mbist_indata (L2Directory_3__mbist_indata),
    .mbist_readen (L2Directory_3__mbist_readen),
    .mbist_addr_rd (L2Directory_3__mbist_addr_rd),
    .mbist_outdata (i_L2Directory_3__mbist_outdata),
    .toSRAM_0_addr (i_L2Directory_3__toSRAM_0_addr),
    .toSRAM_0_addr_rd (i_L2Directory_3__toSRAM_0_addr_rd),
    .toSRAM_0_wdata (i_L2Directory_3__toSRAM_0_wdata),
    .toSRAM_0_wmask (i_L2Directory_3__toSRAM_0_wmask),
    .toSRAM_0_re (i_L2Directory_3__toSRAM_0_re),
    .toSRAM_0_we (i_L2Directory_3__toSRAM_0_we),
    .toSRAM_0_rdata (L2Directory_3__toSRAM_0_rdata),
    .toSRAM_0_ack (i_L2Directory_3__toSRAM_0_ack),
    .toSRAM_0_selectedOH (i_L2Directory_3__toSRAM_0_selectedOH),
    .toSRAM_0_array (i_L2Directory_3__toSRAM_0_array),
    .toSRAM_1_addr (i_L2Directory_3__toSRAM_1_addr),
    .toSRAM_1_addr_rd (i_L2Directory_3__toSRAM_1_addr_rd),
    .toSRAM_1_wdata (i_L2Directory_3__toSRAM_1_wdata),
    .toSRAM_1_wmask (i_L2Directory_3__toSRAM_1_wmask),
    .toSRAM_1_re (i_L2Directory_3__toSRAM_1_re),
    .toSRAM_1_we (i_L2Directory_3__toSRAM_1_we),
    .toSRAM_1_rdata (L2Directory_3__toSRAM_1_rdata),
    .toSRAM_1_ack (i_L2Directory_3__toSRAM_1_ack),
    .toSRAM_1_selectedOH (i_L2Directory_3__toSRAM_1_selectedOH),
    .toSRAM_1_array (i_L2Directory_3__toSRAM_1_array),
    .toSRAM_2_addr (i_L2Directory_3__toSRAM_2_addr),
    .toSRAM_2_addr_rd (i_L2Directory_3__toSRAM_2_addr_rd),
    .toSRAM_2_wdata (i_L2Directory_3__toSRAM_2_wdata),
    .toSRAM_2_wmask (i_L2Directory_3__toSRAM_2_wmask),
    .toSRAM_2_re (i_L2Directory_3__toSRAM_2_re),
    .toSRAM_2_we (i_L2Directory_3__toSRAM_2_we),
    .toSRAM_2_rdata (L2Directory_3__toSRAM_2_rdata),
    .toSRAM_2_ack (i_L2Directory_3__toSRAM_2_ack),
    .toSRAM_2_selectedOH (i_L2Directory_3__toSRAM_2_selectedOH),
    .toSRAM_2_array (i_L2Directory_3__toSRAM_2_array),
    .toSRAM_3_addr (i_L2Directory_3__toSRAM_3_addr),
    .toSRAM_3_addr_rd (i_L2Directory_3__toSRAM_3_addr_rd),
    .toSRAM_3_wdata (i_L2Directory_3__toSRAM_3_wdata),
    .toSRAM_3_wmask (i_L2Directory_3__toSRAM_3_wmask),
    .toSRAM_3_re (i_L2Directory_3__toSRAM_3_re),
    .toSRAM_3_we (i_L2Directory_3__toSRAM_3_we),
    .toSRAM_3_rdata (L2Directory_3__toSRAM_3_rdata),
    .toSRAM_3_ack (i_L2Directory_3__toSRAM_3_ack),
    .toSRAM_3_selectedOH (i_L2Directory_3__toSRAM_3_selectedOH),
    .toSRAM_3_array (i_L2Directory_3__toSRAM_3_array),
    .toSRAM_4_addr (i_L2Directory_3__toSRAM_4_addr),
    .toSRAM_4_addr_rd (i_L2Directory_3__toSRAM_4_addr_rd),
    .toSRAM_4_wdata (i_L2Directory_3__toSRAM_4_wdata),
    .toSRAM_4_wmask (i_L2Directory_3__toSRAM_4_wmask),
    .toSRAM_4_re (i_L2Directory_3__toSRAM_4_re),
    .toSRAM_4_we (i_L2Directory_3__toSRAM_4_we),
    .toSRAM_4_rdata (L2Directory_3__toSRAM_4_rdata),
    .toSRAM_4_ack (i_L2Directory_3__toSRAM_4_ack),
    .toSRAM_4_selectedOH (i_L2Directory_3__toSRAM_4_selectedOH),
    .toSRAM_4_array (i_L2Directory_3__toSRAM_4_array),
    .toSRAM_5_addr (i_L2Directory_3__toSRAM_5_addr),
    .toSRAM_5_addr_rd (i_L2Directory_3__toSRAM_5_addr_rd),
    .toSRAM_5_wdata (i_L2Directory_3__toSRAM_5_wdata),
    .toSRAM_5_wmask (i_L2Directory_3__toSRAM_5_wmask),
    .toSRAM_5_re (i_L2Directory_3__toSRAM_5_re),
    .toSRAM_5_we (i_L2Directory_3__toSRAM_5_we),
    .toSRAM_5_rdata (L2Directory_3__toSRAM_5_rdata),
    .toSRAM_5_ack (i_L2Directory_3__toSRAM_5_ack),
    .toSRAM_5_selectedOH (i_L2Directory_3__toSRAM_5_selectedOH),
    .toSRAM_5_array (i_L2Directory_3__toSRAM_5_array),
    .toSRAM_6_addr (i_L2Directory_3__toSRAM_6_addr),
    .toSRAM_6_addr_rd (i_L2Directory_3__toSRAM_6_addr_rd),
    .toSRAM_6_wdata (i_L2Directory_3__toSRAM_6_wdata),
    .toSRAM_6_wmask (i_L2Directory_3__toSRAM_6_wmask),
    .toSRAM_6_re (i_L2Directory_3__toSRAM_6_re),
    .toSRAM_6_we (i_L2Directory_3__toSRAM_6_we),
    .toSRAM_6_rdata (L2Directory_3__toSRAM_6_rdata),
    .toSRAM_6_ack (i_L2Directory_3__toSRAM_6_ack),
    .toSRAM_6_selectedOH (i_L2Directory_3__toSRAM_6_selectedOH),
    .toSRAM_6_array (i_L2Directory_3__toSRAM_6_array)
  );
  task automatic drive_L2Directory_3();
    L2Directory_3__mbist_array = rnd(6);
    L2Directory_3__mbist_all = $urandom % 2;
    L2Directory_3__mbist_req = $urandom % 2;
    L2Directory_3__mbist_writeen = $urandom % 2;
    L2Directory_3__mbist_be = rnd(8);
    L2Directory_3__mbist_addr = rnd(10);
    L2Directory_3__mbist_indata = rnd(104);
    L2Directory_3__mbist_readen = $urandom % 2;
    L2Directory_3__mbist_addr_rd = rnd(10);
    L2Directory_3__toSRAM_0_rdata = rnd(76);
    L2Directory_3__toSRAM_1_rdata = rnd(76);
    L2Directory_3__toSRAM_2_rdata = rnd(76);
    L2Directory_3__toSRAM_3_rdata = rnd(76);
    L2Directory_3__toSRAM_4_rdata = rnd(104);
    L2Directory_3__toSRAM_5_rdata = rnd(16);
    L2Directory_3__toSRAM_6_rdata = rnd(8);
  endtask
  task automatic check_L2Directory_3();
    checks++;
    if (g_L2Directory_3__mbist_ack !== i_L2Directory_3__mbist_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.mbist_ack g=%h i=%h", cyc, g_L2Directory_3__mbist_ack, i_L2Directory_3__mbist_ack);
    end
    if (g_L2Directory_3__mbist_ack !== p_L2Directory_3__mbist_ack) t_L2Directory_3__mbist_ack = 1'b1;
    p_L2Directory_3__mbist_ack = g_L2Directory_3__mbist_ack;
    checks++;
    if (g_L2Directory_3__mbist_outdata !== i_L2Directory_3__mbist_outdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.mbist_outdata g=%h i=%h", cyc, g_L2Directory_3__mbist_outdata, i_L2Directory_3__mbist_outdata);
    end
    if (g_L2Directory_3__mbist_outdata !== p_L2Directory_3__mbist_outdata) t_L2Directory_3__mbist_outdata = 1'b1;
    p_L2Directory_3__mbist_outdata = g_L2Directory_3__mbist_outdata;
    checks++;
    if (g_L2Directory_3__toSRAM_0_addr !== i_L2Directory_3__toSRAM_0_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_addr, i_L2Directory_3__toSRAM_0_addr);
    end
    if (g_L2Directory_3__toSRAM_0_addr !== p_L2Directory_3__toSRAM_0_addr) t_L2Directory_3__toSRAM_0_addr = 1'b1;
    p_L2Directory_3__toSRAM_0_addr = g_L2Directory_3__toSRAM_0_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_0_addr_rd !== i_L2Directory_3__toSRAM_0_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_addr_rd, i_L2Directory_3__toSRAM_0_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_0_addr_rd !== p_L2Directory_3__toSRAM_0_addr_rd) t_L2Directory_3__toSRAM_0_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_0_addr_rd = g_L2Directory_3__toSRAM_0_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_0_wdata !== i_L2Directory_3__toSRAM_0_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_wdata, i_L2Directory_3__toSRAM_0_wdata);
    end
    if (g_L2Directory_3__toSRAM_0_wdata !== p_L2Directory_3__toSRAM_0_wdata) t_L2Directory_3__toSRAM_0_wdata = 1'b1;
    p_L2Directory_3__toSRAM_0_wdata = g_L2Directory_3__toSRAM_0_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_0_wmask !== i_L2Directory_3__toSRAM_0_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_wmask, i_L2Directory_3__toSRAM_0_wmask);
    end
    if (g_L2Directory_3__toSRAM_0_wmask !== p_L2Directory_3__toSRAM_0_wmask) t_L2Directory_3__toSRAM_0_wmask = 1'b1;
    p_L2Directory_3__toSRAM_0_wmask = g_L2Directory_3__toSRAM_0_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_0_re !== i_L2Directory_3__toSRAM_0_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_re, i_L2Directory_3__toSRAM_0_re);
    end
    if (g_L2Directory_3__toSRAM_0_re !== p_L2Directory_3__toSRAM_0_re) t_L2Directory_3__toSRAM_0_re = 1'b1;
    p_L2Directory_3__toSRAM_0_re = g_L2Directory_3__toSRAM_0_re;
    checks++;
    if (g_L2Directory_3__toSRAM_0_we !== i_L2Directory_3__toSRAM_0_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_we, i_L2Directory_3__toSRAM_0_we);
    end
    if (g_L2Directory_3__toSRAM_0_we !== p_L2Directory_3__toSRAM_0_we) t_L2Directory_3__toSRAM_0_we = 1'b1;
    p_L2Directory_3__toSRAM_0_we = g_L2Directory_3__toSRAM_0_we;
    checks++;
    if (g_L2Directory_3__toSRAM_0_ack !== i_L2Directory_3__toSRAM_0_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_ack, i_L2Directory_3__toSRAM_0_ack);
    end
    if (g_L2Directory_3__toSRAM_0_ack !== p_L2Directory_3__toSRAM_0_ack) t_L2Directory_3__toSRAM_0_ack = 1'b1;
    p_L2Directory_3__toSRAM_0_ack = g_L2Directory_3__toSRAM_0_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_0_selectedOH !== i_L2Directory_3__toSRAM_0_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_selectedOH, i_L2Directory_3__toSRAM_0_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_0_selectedOH !== p_L2Directory_3__toSRAM_0_selectedOH) t_L2Directory_3__toSRAM_0_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_0_selectedOH = g_L2Directory_3__toSRAM_0_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_0_array !== i_L2Directory_3__toSRAM_0_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_0_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_0_array, i_L2Directory_3__toSRAM_0_array);
    end
    if (g_L2Directory_3__toSRAM_0_array !== p_L2Directory_3__toSRAM_0_array) t_L2Directory_3__toSRAM_0_array = 1'b1;
    p_L2Directory_3__toSRAM_0_array = g_L2Directory_3__toSRAM_0_array;
    checks++;
    if (g_L2Directory_3__toSRAM_1_addr !== i_L2Directory_3__toSRAM_1_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_addr, i_L2Directory_3__toSRAM_1_addr);
    end
    if (g_L2Directory_3__toSRAM_1_addr !== p_L2Directory_3__toSRAM_1_addr) t_L2Directory_3__toSRAM_1_addr = 1'b1;
    p_L2Directory_3__toSRAM_1_addr = g_L2Directory_3__toSRAM_1_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_1_addr_rd !== i_L2Directory_3__toSRAM_1_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_addr_rd, i_L2Directory_3__toSRAM_1_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_1_addr_rd !== p_L2Directory_3__toSRAM_1_addr_rd) t_L2Directory_3__toSRAM_1_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_1_addr_rd = g_L2Directory_3__toSRAM_1_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_1_wdata !== i_L2Directory_3__toSRAM_1_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_wdata, i_L2Directory_3__toSRAM_1_wdata);
    end
    if (g_L2Directory_3__toSRAM_1_wdata !== p_L2Directory_3__toSRAM_1_wdata) t_L2Directory_3__toSRAM_1_wdata = 1'b1;
    p_L2Directory_3__toSRAM_1_wdata = g_L2Directory_3__toSRAM_1_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_1_wmask !== i_L2Directory_3__toSRAM_1_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_wmask, i_L2Directory_3__toSRAM_1_wmask);
    end
    if (g_L2Directory_3__toSRAM_1_wmask !== p_L2Directory_3__toSRAM_1_wmask) t_L2Directory_3__toSRAM_1_wmask = 1'b1;
    p_L2Directory_3__toSRAM_1_wmask = g_L2Directory_3__toSRAM_1_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_1_re !== i_L2Directory_3__toSRAM_1_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_re, i_L2Directory_3__toSRAM_1_re);
    end
    if (g_L2Directory_3__toSRAM_1_re !== p_L2Directory_3__toSRAM_1_re) t_L2Directory_3__toSRAM_1_re = 1'b1;
    p_L2Directory_3__toSRAM_1_re = g_L2Directory_3__toSRAM_1_re;
    checks++;
    if (g_L2Directory_3__toSRAM_1_we !== i_L2Directory_3__toSRAM_1_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_we, i_L2Directory_3__toSRAM_1_we);
    end
    if (g_L2Directory_3__toSRAM_1_we !== p_L2Directory_3__toSRAM_1_we) t_L2Directory_3__toSRAM_1_we = 1'b1;
    p_L2Directory_3__toSRAM_1_we = g_L2Directory_3__toSRAM_1_we;
    checks++;
    if (g_L2Directory_3__toSRAM_1_ack !== i_L2Directory_3__toSRAM_1_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_ack, i_L2Directory_3__toSRAM_1_ack);
    end
    if (g_L2Directory_3__toSRAM_1_ack !== p_L2Directory_3__toSRAM_1_ack) t_L2Directory_3__toSRAM_1_ack = 1'b1;
    p_L2Directory_3__toSRAM_1_ack = g_L2Directory_3__toSRAM_1_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_1_selectedOH !== i_L2Directory_3__toSRAM_1_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_selectedOH, i_L2Directory_3__toSRAM_1_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_1_selectedOH !== p_L2Directory_3__toSRAM_1_selectedOH) t_L2Directory_3__toSRAM_1_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_1_selectedOH = g_L2Directory_3__toSRAM_1_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_1_array !== i_L2Directory_3__toSRAM_1_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_1_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_1_array, i_L2Directory_3__toSRAM_1_array);
    end
    if (g_L2Directory_3__toSRAM_1_array !== p_L2Directory_3__toSRAM_1_array) t_L2Directory_3__toSRAM_1_array = 1'b1;
    p_L2Directory_3__toSRAM_1_array = g_L2Directory_3__toSRAM_1_array;
    checks++;
    if (g_L2Directory_3__toSRAM_2_addr !== i_L2Directory_3__toSRAM_2_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_addr, i_L2Directory_3__toSRAM_2_addr);
    end
    if (g_L2Directory_3__toSRAM_2_addr !== p_L2Directory_3__toSRAM_2_addr) t_L2Directory_3__toSRAM_2_addr = 1'b1;
    p_L2Directory_3__toSRAM_2_addr = g_L2Directory_3__toSRAM_2_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_2_addr_rd !== i_L2Directory_3__toSRAM_2_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_addr_rd, i_L2Directory_3__toSRAM_2_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_2_addr_rd !== p_L2Directory_3__toSRAM_2_addr_rd) t_L2Directory_3__toSRAM_2_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_2_addr_rd = g_L2Directory_3__toSRAM_2_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_2_wdata !== i_L2Directory_3__toSRAM_2_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_wdata, i_L2Directory_3__toSRAM_2_wdata);
    end
    if (g_L2Directory_3__toSRAM_2_wdata !== p_L2Directory_3__toSRAM_2_wdata) t_L2Directory_3__toSRAM_2_wdata = 1'b1;
    p_L2Directory_3__toSRAM_2_wdata = g_L2Directory_3__toSRAM_2_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_2_wmask !== i_L2Directory_3__toSRAM_2_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_wmask, i_L2Directory_3__toSRAM_2_wmask);
    end
    if (g_L2Directory_3__toSRAM_2_wmask !== p_L2Directory_3__toSRAM_2_wmask) t_L2Directory_3__toSRAM_2_wmask = 1'b1;
    p_L2Directory_3__toSRAM_2_wmask = g_L2Directory_3__toSRAM_2_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_2_re !== i_L2Directory_3__toSRAM_2_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_re, i_L2Directory_3__toSRAM_2_re);
    end
    if (g_L2Directory_3__toSRAM_2_re !== p_L2Directory_3__toSRAM_2_re) t_L2Directory_3__toSRAM_2_re = 1'b1;
    p_L2Directory_3__toSRAM_2_re = g_L2Directory_3__toSRAM_2_re;
    checks++;
    if (g_L2Directory_3__toSRAM_2_we !== i_L2Directory_3__toSRAM_2_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_we, i_L2Directory_3__toSRAM_2_we);
    end
    if (g_L2Directory_3__toSRAM_2_we !== p_L2Directory_3__toSRAM_2_we) t_L2Directory_3__toSRAM_2_we = 1'b1;
    p_L2Directory_3__toSRAM_2_we = g_L2Directory_3__toSRAM_2_we;
    checks++;
    if (g_L2Directory_3__toSRAM_2_ack !== i_L2Directory_3__toSRAM_2_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_ack, i_L2Directory_3__toSRAM_2_ack);
    end
    if (g_L2Directory_3__toSRAM_2_ack !== p_L2Directory_3__toSRAM_2_ack) t_L2Directory_3__toSRAM_2_ack = 1'b1;
    p_L2Directory_3__toSRAM_2_ack = g_L2Directory_3__toSRAM_2_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_2_selectedOH !== i_L2Directory_3__toSRAM_2_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_selectedOH, i_L2Directory_3__toSRAM_2_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_2_selectedOH !== p_L2Directory_3__toSRAM_2_selectedOH) t_L2Directory_3__toSRAM_2_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_2_selectedOH = g_L2Directory_3__toSRAM_2_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_2_array !== i_L2Directory_3__toSRAM_2_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_2_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_2_array, i_L2Directory_3__toSRAM_2_array);
    end
    if (g_L2Directory_3__toSRAM_2_array !== p_L2Directory_3__toSRAM_2_array) t_L2Directory_3__toSRAM_2_array = 1'b1;
    p_L2Directory_3__toSRAM_2_array = g_L2Directory_3__toSRAM_2_array;
    checks++;
    if (g_L2Directory_3__toSRAM_3_addr !== i_L2Directory_3__toSRAM_3_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_addr, i_L2Directory_3__toSRAM_3_addr);
    end
    if (g_L2Directory_3__toSRAM_3_addr !== p_L2Directory_3__toSRAM_3_addr) t_L2Directory_3__toSRAM_3_addr = 1'b1;
    p_L2Directory_3__toSRAM_3_addr = g_L2Directory_3__toSRAM_3_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_3_addr_rd !== i_L2Directory_3__toSRAM_3_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_addr_rd, i_L2Directory_3__toSRAM_3_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_3_addr_rd !== p_L2Directory_3__toSRAM_3_addr_rd) t_L2Directory_3__toSRAM_3_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_3_addr_rd = g_L2Directory_3__toSRAM_3_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_3_wdata !== i_L2Directory_3__toSRAM_3_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_wdata, i_L2Directory_3__toSRAM_3_wdata);
    end
    if (g_L2Directory_3__toSRAM_3_wdata !== p_L2Directory_3__toSRAM_3_wdata) t_L2Directory_3__toSRAM_3_wdata = 1'b1;
    p_L2Directory_3__toSRAM_3_wdata = g_L2Directory_3__toSRAM_3_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_3_wmask !== i_L2Directory_3__toSRAM_3_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_wmask, i_L2Directory_3__toSRAM_3_wmask);
    end
    if (g_L2Directory_3__toSRAM_3_wmask !== p_L2Directory_3__toSRAM_3_wmask) t_L2Directory_3__toSRAM_3_wmask = 1'b1;
    p_L2Directory_3__toSRAM_3_wmask = g_L2Directory_3__toSRAM_3_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_3_re !== i_L2Directory_3__toSRAM_3_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_re, i_L2Directory_3__toSRAM_3_re);
    end
    if (g_L2Directory_3__toSRAM_3_re !== p_L2Directory_3__toSRAM_3_re) t_L2Directory_3__toSRAM_3_re = 1'b1;
    p_L2Directory_3__toSRAM_3_re = g_L2Directory_3__toSRAM_3_re;
    checks++;
    if (g_L2Directory_3__toSRAM_3_we !== i_L2Directory_3__toSRAM_3_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_we, i_L2Directory_3__toSRAM_3_we);
    end
    if (g_L2Directory_3__toSRAM_3_we !== p_L2Directory_3__toSRAM_3_we) t_L2Directory_3__toSRAM_3_we = 1'b1;
    p_L2Directory_3__toSRAM_3_we = g_L2Directory_3__toSRAM_3_we;
    checks++;
    if (g_L2Directory_3__toSRAM_3_ack !== i_L2Directory_3__toSRAM_3_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_ack, i_L2Directory_3__toSRAM_3_ack);
    end
    if (g_L2Directory_3__toSRAM_3_ack !== p_L2Directory_3__toSRAM_3_ack) t_L2Directory_3__toSRAM_3_ack = 1'b1;
    p_L2Directory_3__toSRAM_3_ack = g_L2Directory_3__toSRAM_3_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_3_selectedOH !== i_L2Directory_3__toSRAM_3_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_selectedOH, i_L2Directory_3__toSRAM_3_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_3_selectedOH !== p_L2Directory_3__toSRAM_3_selectedOH) t_L2Directory_3__toSRAM_3_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_3_selectedOH = g_L2Directory_3__toSRAM_3_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_3_array !== i_L2Directory_3__toSRAM_3_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_3_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_3_array, i_L2Directory_3__toSRAM_3_array);
    end
    if (g_L2Directory_3__toSRAM_3_array !== p_L2Directory_3__toSRAM_3_array) t_L2Directory_3__toSRAM_3_array = 1'b1;
    p_L2Directory_3__toSRAM_3_array = g_L2Directory_3__toSRAM_3_array;
    checks++;
    if (g_L2Directory_3__toSRAM_4_addr !== i_L2Directory_3__toSRAM_4_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_addr, i_L2Directory_3__toSRAM_4_addr);
    end
    if (g_L2Directory_3__toSRAM_4_addr !== p_L2Directory_3__toSRAM_4_addr) t_L2Directory_3__toSRAM_4_addr = 1'b1;
    p_L2Directory_3__toSRAM_4_addr = g_L2Directory_3__toSRAM_4_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_4_addr_rd !== i_L2Directory_3__toSRAM_4_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_addr_rd, i_L2Directory_3__toSRAM_4_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_4_addr_rd !== p_L2Directory_3__toSRAM_4_addr_rd) t_L2Directory_3__toSRAM_4_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_4_addr_rd = g_L2Directory_3__toSRAM_4_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_4_wdata !== i_L2Directory_3__toSRAM_4_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_wdata, i_L2Directory_3__toSRAM_4_wdata);
    end
    if (g_L2Directory_3__toSRAM_4_wdata !== p_L2Directory_3__toSRAM_4_wdata) t_L2Directory_3__toSRAM_4_wdata = 1'b1;
    p_L2Directory_3__toSRAM_4_wdata = g_L2Directory_3__toSRAM_4_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_4_wmask !== i_L2Directory_3__toSRAM_4_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_wmask, i_L2Directory_3__toSRAM_4_wmask);
    end
    if (g_L2Directory_3__toSRAM_4_wmask !== p_L2Directory_3__toSRAM_4_wmask) t_L2Directory_3__toSRAM_4_wmask = 1'b1;
    p_L2Directory_3__toSRAM_4_wmask = g_L2Directory_3__toSRAM_4_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_4_re !== i_L2Directory_3__toSRAM_4_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_re, i_L2Directory_3__toSRAM_4_re);
    end
    if (g_L2Directory_3__toSRAM_4_re !== p_L2Directory_3__toSRAM_4_re) t_L2Directory_3__toSRAM_4_re = 1'b1;
    p_L2Directory_3__toSRAM_4_re = g_L2Directory_3__toSRAM_4_re;
    checks++;
    if (g_L2Directory_3__toSRAM_4_we !== i_L2Directory_3__toSRAM_4_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_we, i_L2Directory_3__toSRAM_4_we);
    end
    if (g_L2Directory_3__toSRAM_4_we !== p_L2Directory_3__toSRAM_4_we) t_L2Directory_3__toSRAM_4_we = 1'b1;
    p_L2Directory_3__toSRAM_4_we = g_L2Directory_3__toSRAM_4_we;
    checks++;
    if (g_L2Directory_3__toSRAM_4_ack !== i_L2Directory_3__toSRAM_4_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_ack, i_L2Directory_3__toSRAM_4_ack);
    end
    if (g_L2Directory_3__toSRAM_4_ack !== p_L2Directory_3__toSRAM_4_ack) t_L2Directory_3__toSRAM_4_ack = 1'b1;
    p_L2Directory_3__toSRAM_4_ack = g_L2Directory_3__toSRAM_4_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_4_selectedOH !== i_L2Directory_3__toSRAM_4_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_selectedOH, i_L2Directory_3__toSRAM_4_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_4_selectedOH !== p_L2Directory_3__toSRAM_4_selectedOH) t_L2Directory_3__toSRAM_4_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_4_selectedOH = g_L2Directory_3__toSRAM_4_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_4_array !== i_L2Directory_3__toSRAM_4_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_4_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_4_array, i_L2Directory_3__toSRAM_4_array);
    end
    if (g_L2Directory_3__toSRAM_4_array !== p_L2Directory_3__toSRAM_4_array) t_L2Directory_3__toSRAM_4_array = 1'b1;
    p_L2Directory_3__toSRAM_4_array = g_L2Directory_3__toSRAM_4_array;
    checks++;
    if (g_L2Directory_3__toSRAM_5_addr !== i_L2Directory_3__toSRAM_5_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_addr, i_L2Directory_3__toSRAM_5_addr);
    end
    if (g_L2Directory_3__toSRAM_5_addr !== p_L2Directory_3__toSRAM_5_addr) t_L2Directory_3__toSRAM_5_addr = 1'b1;
    p_L2Directory_3__toSRAM_5_addr = g_L2Directory_3__toSRAM_5_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_5_addr_rd !== i_L2Directory_3__toSRAM_5_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_addr_rd, i_L2Directory_3__toSRAM_5_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_5_addr_rd !== p_L2Directory_3__toSRAM_5_addr_rd) t_L2Directory_3__toSRAM_5_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_5_addr_rd = g_L2Directory_3__toSRAM_5_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_5_wdata !== i_L2Directory_3__toSRAM_5_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_wdata, i_L2Directory_3__toSRAM_5_wdata);
    end
    if (g_L2Directory_3__toSRAM_5_wdata !== p_L2Directory_3__toSRAM_5_wdata) t_L2Directory_3__toSRAM_5_wdata = 1'b1;
    p_L2Directory_3__toSRAM_5_wdata = g_L2Directory_3__toSRAM_5_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_5_wmask !== i_L2Directory_3__toSRAM_5_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_wmask, i_L2Directory_3__toSRAM_5_wmask);
    end
    if (g_L2Directory_3__toSRAM_5_wmask !== p_L2Directory_3__toSRAM_5_wmask) t_L2Directory_3__toSRAM_5_wmask = 1'b1;
    p_L2Directory_3__toSRAM_5_wmask = g_L2Directory_3__toSRAM_5_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_5_re !== i_L2Directory_3__toSRAM_5_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_re, i_L2Directory_3__toSRAM_5_re);
    end
    if (g_L2Directory_3__toSRAM_5_re !== p_L2Directory_3__toSRAM_5_re) t_L2Directory_3__toSRAM_5_re = 1'b1;
    p_L2Directory_3__toSRAM_5_re = g_L2Directory_3__toSRAM_5_re;
    checks++;
    if (g_L2Directory_3__toSRAM_5_we !== i_L2Directory_3__toSRAM_5_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_we, i_L2Directory_3__toSRAM_5_we);
    end
    if (g_L2Directory_3__toSRAM_5_we !== p_L2Directory_3__toSRAM_5_we) t_L2Directory_3__toSRAM_5_we = 1'b1;
    p_L2Directory_3__toSRAM_5_we = g_L2Directory_3__toSRAM_5_we;
    checks++;
    if (g_L2Directory_3__toSRAM_5_ack !== i_L2Directory_3__toSRAM_5_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_ack, i_L2Directory_3__toSRAM_5_ack);
    end
    if (g_L2Directory_3__toSRAM_5_ack !== p_L2Directory_3__toSRAM_5_ack) t_L2Directory_3__toSRAM_5_ack = 1'b1;
    p_L2Directory_3__toSRAM_5_ack = g_L2Directory_3__toSRAM_5_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_5_selectedOH !== i_L2Directory_3__toSRAM_5_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_selectedOH, i_L2Directory_3__toSRAM_5_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_5_selectedOH !== p_L2Directory_3__toSRAM_5_selectedOH) t_L2Directory_3__toSRAM_5_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_5_selectedOH = g_L2Directory_3__toSRAM_5_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_5_array !== i_L2Directory_3__toSRAM_5_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_5_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_5_array, i_L2Directory_3__toSRAM_5_array);
    end
    if (g_L2Directory_3__toSRAM_5_array !== p_L2Directory_3__toSRAM_5_array) t_L2Directory_3__toSRAM_5_array = 1'b1;
    p_L2Directory_3__toSRAM_5_array = g_L2Directory_3__toSRAM_5_array;
    checks++;
    if (g_L2Directory_3__toSRAM_6_addr !== i_L2Directory_3__toSRAM_6_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_addr g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_addr, i_L2Directory_3__toSRAM_6_addr);
    end
    if (g_L2Directory_3__toSRAM_6_addr !== p_L2Directory_3__toSRAM_6_addr) t_L2Directory_3__toSRAM_6_addr = 1'b1;
    p_L2Directory_3__toSRAM_6_addr = g_L2Directory_3__toSRAM_6_addr;
    checks++;
    if (g_L2Directory_3__toSRAM_6_addr_rd !== i_L2Directory_3__toSRAM_6_addr_rd) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_addr_rd g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_addr_rd, i_L2Directory_3__toSRAM_6_addr_rd);
    end
    if (g_L2Directory_3__toSRAM_6_addr_rd !== p_L2Directory_3__toSRAM_6_addr_rd) t_L2Directory_3__toSRAM_6_addr_rd = 1'b1;
    p_L2Directory_3__toSRAM_6_addr_rd = g_L2Directory_3__toSRAM_6_addr_rd;
    checks++;
    if (g_L2Directory_3__toSRAM_6_wdata !== i_L2Directory_3__toSRAM_6_wdata) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_wdata g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_wdata, i_L2Directory_3__toSRAM_6_wdata);
    end
    if (g_L2Directory_3__toSRAM_6_wdata !== p_L2Directory_3__toSRAM_6_wdata) t_L2Directory_3__toSRAM_6_wdata = 1'b1;
    p_L2Directory_3__toSRAM_6_wdata = g_L2Directory_3__toSRAM_6_wdata;
    checks++;
    if (g_L2Directory_3__toSRAM_6_wmask !== i_L2Directory_3__toSRAM_6_wmask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_wmask g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_wmask, i_L2Directory_3__toSRAM_6_wmask);
    end
    if (g_L2Directory_3__toSRAM_6_wmask !== p_L2Directory_3__toSRAM_6_wmask) t_L2Directory_3__toSRAM_6_wmask = 1'b1;
    p_L2Directory_3__toSRAM_6_wmask = g_L2Directory_3__toSRAM_6_wmask;
    checks++;
    if (g_L2Directory_3__toSRAM_6_re !== i_L2Directory_3__toSRAM_6_re) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_re g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_re, i_L2Directory_3__toSRAM_6_re);
    end
    if (g_L2Directory_3__toSRAM_6_re !== p_L2Directory_3__toSRAM_6_re) t_L2Directory_3__toSRAM_6_re = 1'b1;
    p_L2Directory_3__toSRAM_6_re = g_L2Directory_3__toSRAM_6_re;
    checks++;
    if (g_L2Directory_3__toSRAM_6_we !== i_L2Directory_3__toSRAM_6_we) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_we g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_we, i_L2Directory_3__toSRAM_6_we);
    end
    if (g_L2Directory_3__toSRAM_6_we !== p_L2Directory_3__toSRAM_6_we) t_L2Directory_3__toSRAM_6_we = 1'b1;
    p_L2Directory_3__toSRAM_6_we = g_L2Directory_3__toSRAM_6_we;
    checks++;
    if (g_L2Directory_3__toSRAM_6_ack !== i_L2Directory_3__toSRAM_6_ack) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_ack g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_ack, i_L2Directory_3__toSRAM_6_ack);
    end
    if (g_L2Directory_3__toSRAM_6_ack !== p_L2Directory_3__toSRAM_6_ack) t_L2Directory_3__toSRAM_6_ack = 1'b1;
    p_L2Directory_3__toSRAM_6_ack = g_L2Directory_3__toSRAM_6_ack;
    checks++;
    if (g_L2Directory_3__toSRAM_6_selectedOH !== i_L2Directory_3__toSRAM_6_selectedOH) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_selectedOH g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_selectedOH, i_L2Directory_3__toSRAM_6_selectedOH);
    end
    if (g_L2Directory_3__toSRAM_6_selectedOH !== p_L2Directory_3__toSRAM_6_selectedOH) t_L2Directory_3__toSRAM_6_selectedOH = 1'b1;
    p_L2Directory_3__toSRAM_6_selectedOH = g_L2Directory_3__toSRAM_6_selectedOH;
    checks++;
    if (g_L2Directory_3__toSRAM_6_array !== i_L2Directory_3__toSRAM_6_array) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH L2Directory_3.toSRAM_6_array g=%h i=%h", cyc, g_L2Directory_3__toSRAM_6_array, i_L2Directory_3__toSRAM_6_array);
    end
    if (g_L2Directory_3__toSRAM_6_array !== p_L2Directory_3__toSRAM_6_array) t_L2Directory_3__toSRAM_6_array = 1'b1;
    p_L2Directory_3__toSRAM_6_array = g_L2Directory_3__toSRAM_6_array;
  endtask
  longint cov_L2Directory_3_act = 0;
  longint cov_L2Directory_3_sel6 = 0;
  task automatic cover_L2Directory_3();
    if (u_g_L2Directory_3.activated) cov_L2Directory_3_act++;
    if (u_g_L2Directory_3.selectedVec_0_6) cov_L2Directory_3_sel6++;
  endtask
  task automatic preinit_L2Directory_3();
  endtask
  task automatic sync_L2Directory_3();
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_L2Directory_1();
    drive_L2Directory_2();
    drive_L2Directory_3();
    #1;
    preinit_L2Directory_1();
    preinit_L2Directory_2();
    preinit_L2Directory_3();
    sync_L2Directory_1();
    sync_L2Directory_2();
    sync_L2Directory_3();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_L2Directory_1();
      drive_L2Directory_2();
      drive_L2Directory_3();
      #1;
      check_L2Directory_1();
      cover_L2Directory_1();
      check_L2Directory_2();
      cover_L2Directory_2();
      check_L2Directory_3();
      cover_L2Directory_3();
    end
    begin int tg; tg = 0;
      if (t_L2Directory_1__mbist_ack) tg++; else $display("COV: L2Directory_1.mbist_ack never toggled");
      if (t_L2Directory_1__mbist_outdata) tg++; else $display("COV: L2Directory_1.mbist_outdata never toggled");
      if (t_L2Directory_1__toSRAM_0_addr) tg++; else $display("COV: L2Directory_1.toSRAM_0_addr never toggled");
      if (t_L2Directory_1__toSRAM_0_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_0_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_0_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_0_wdata never toggled");
      if (t_L2Directory_1__toSRAM_0_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_0_wmask never toggled");
      if (t_L2Directory_1__toSRAM_0_re) tg++; else $display("COV: L2Directory_1.toSRAM_0_re never toggled");
      if (t_L2Directory_1__toSRAM_0_we) tg++; else $display("COV: L2Directory_1.toSRAM_0_we never toggled");
      if (t_L2Directory_1__toSRAM_0_ack) tg++; else $display("COV: L2Directory_1.toSRAM_0_ack never toggled");
      if (t_L2Directory_1__toSRAM_0_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_0_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_0_array) tg++; else $display("COV: L2Directory_1.toSRAM_0_array never toggled");
      if (t_L2Directory_1__toSRAM_1_addr) tg++; else $display("COV: L2Directory_1.toSRAM_1_addr never toggled");
      if (t_L2Directory_1__toSRAM_1_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_1_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_1_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_1_wdata never toggled");
      if (t_L2Directory_1__toSRAM_1_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_1_wmask never toggled");
      if (t_L2Directory_1__toSRAM_1_re) tg++; else $display("COV: L2Directory_1.toSRAM_1_re never toggled");
      if (t_L2Directory_1__toSRAM_1_we) tg++; else $display("COV: L2Directory_1.toSRAM_1_we never toggled");
      if (t_L2Directory_1__toSRAM_1_ack) tg++; else $display("COV: L2Directory_1.toSRAM_1_ack never toggled");
      if (t_L2Directory_1__toSRAM_1_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_1_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_1_array) tg++; else $display("COV: L2Directory_1.toSRAM_1_array never toggled");
      if (t_L2Directory_1__toSRAM_2_addr) tg++; else $display("COV: L2Directory_1.toSRAM_2_addr never toggled");
      if (t_L2Directory_1__toSRAM_2_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_2_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_2_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_2_wdata never toggled");
      if (t_L2Directory_1__toSRAM_2_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_2_wmask never toggled");
      if (t_L2Directory_1__toSRAM_2_re) tg++; else $display("COV: L2Directory_1.toSRAM_2_re never toggled");
      if (t_L2Directory_1__toSRAM_2_we) tg++; else $display("COV: L2Directory_1.toSRAM_2_we never toggled");
      if (t_L2Directory_1__toSRAM_2_ack) tg++; else $display("COV: L2Directory_1.toSRAM_2_ack never toggled");
      if (t_L2Directory_1__toSRAM_2_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_2_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_2_array) tg++; else $display("COV: L2Directory_1.toSRAM_2_array never toggled");
      if (t_L2Directory_1__toSRAM_3_addr) tg++; else $display("COV: L2Directory_1.toSRAM_3_addr never toggled");
      if (t_L2Directory_1__toSRAM_3_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_3_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_3_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_3_wdata never toggled");
      if (t_L2Directory_1__toSRAM_3_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_3_wmask never toggled");
      if (t_L2Directory_1__toSRAM_3_re) tg++; else $display("COV: L2Directory_1.toSRAM_3_re never toggled");
      if (t_L2Directory_1__toSRAM_3_we) tg++; else $display("COV: L2Directory_1.toSRAM_3_we never toggled");
      if (t_L2Directory_1__toSRAM_3_ack) tg++; else $display("COV: L2Directory_1.toSRAM_3_ack never toggled");
      if (t_L2Directory_1__toSRAM_3_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_3_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_3_array) tg++; else $display("COV: L2Directory_1.toSRAM_3_array never toggled");
      if (t_L2Directory_1__toSRAM_4_addr) tg++; else $display("COV: L2Directory_1.toSRAM_4_addr never toggled");
      if (t_L2Directory_1__toSRAM_4_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_4_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_4_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_4_wdata never toggled");
      if (t_L2Directory_1__toSRAM_4_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_4_wmask never toggled");
      if (t_L2Directory_1__toSRAM_4_re) tg++; else $display("COV: L2Directory_1.toSRAM_4_re never toggled");
      if (t_L2Directory_1__toSRAM_4_we) tg++; else $display("COV: L2Directory_1.toSRAM_4_we never toggled");
      if (t_L2Directory_1__toSRAM_4_ack) tg++; else $display("COV: L2Directory_1.toSRAM_4_ack never toggled");
      if (t_L2Directory_1__toSRAM_4_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_4_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_4_array) tg++; else $display("COV: L2Directory_1.toSRAM_4_array never toggled");
      if (t_L2Directory_1__toSRAM_5_addr) tg++; else $display("COV: L2Directory_1.toSRAM_5_addr never toggled");
      if (t_L2Directory_1__toSRAM_5_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_5_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_5_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_5_wdata never toggled");
      if (t_L2Directory_1__toSRAM_5_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_5_wmask never toggled");
      if (t_L2Directory_1__toSRAM_5_re) tg++; else $display("COV: L2Directory_1.toSRAM_5_re never toggled");
      if (t_L2Directory_1__toSRAM_5_we) tg++; else $display("COV: L2Directory_1.toSRAM_5_we never toggled");
      if (t_L2Directory_1__toSRAM_5_ack) tg++; else $display("COV: L2Directory_1.toSRAM_5_ack never toggled");
      if (t_L2Directory_1__toSRAM_5_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_5_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_5_array) tg++; else $display("COV: L2Directory_1.toSRAM_5_array never toggled");
      if (t_L2Directory_1__toSRAM_6_addr) tg++; else $display("COV: L2Directory_1.toSRAM_6_addr never toggled");
      if (t_L2Directory_1__toSRAM_6_addr_rd) tg++; else $display("COV: L2Directory_1.toSRAM_6_addr_rd never toggled");
      if (t_L2Directory_1__toSRAM_6_wdata) tg++; else $display("COV: L2Directory_1.toSRAM_6_wdata never toggled");
      if (t_L2Directory_1__toSRAM_6_wmask) tg++; else $display("COV: L2Directory_1.toSRAM_6_wmask never toggled");
      if (t_L2Directory_1__toSRAM_6_re) tg++; else $display("COV: L2Directory_1.toSRAM_6_re never toggled");
      if (t_L2Directory_1__toSRAM_6_we) tg++; else $display("COV: L2Directory_1.toSRAM_6_we never toggled");
      if (t_L2Directory_1__toSRAM_6_ack) tg++; else $display("COV: L2Directory_1.toSRAM_6_ack never toggled");
      if (t_L2Directory_1__toSRAM_6_selectedOH) tg++; else $display("COV: L2Directory_1.toSRAM_6_selectedOH never toggled");
      if (t_L2Directory_1__toSRAM_6_array) tg++; else $display("COV: L2Directory_1.toSRAM_6_array never toggled");
      $display("L2Directory_1: toggled=%0d/65 (need >= 65)", tg);
      if (tg < 65) covfail = 1;
      $display("L2Directory_1: cover act = %0d", cov_L2Directory_1_act);
      if (cov_L2Directory_1_act == 0) covfail = 1;
      $display("L2Directory_1: cover sel6 = %0d", cov_L2Directory_1_sel6);
      if (cov_L2Directory_1_sel6 == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_L2Directory_2__mbist_ack) tg++; else $display("COV: L2Directory_2.mbist_ack never toggled");
      if (t_L2Directory_2__mbist_outdata) tg++; else $display("COV: L2Directory_2.mbist_outdata never toggled");
      if (t_L2Directory_2__toSRAM_0_addr) tg++; else $display("COV: L2Directory_2.toSRAM_0_addr never toggled");
      if (t_L2Directory_2__toSRAM_0_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_0_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_0_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_0_wdata never toggled");
      if (t_L2Directory_2__toSRAM_0_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_0_wmask never toggled");
      if (t_L2Directory_2__toSRAM_0_re) tg++; else $display("COV: L2Directory_2.toSRAM_0_re never toggled");
      if (t_L2Directory_2__toSRAM_0_we) tg++; else $display("COV: L2Directory_2.toSRAM_0_we never toggled");
      if (t_L2Directory_2__toSRAM_0_ack) tg++; else $display("COV: L2Directory_2.toSRAM_0_ack never toggled");
      if (t_L2Directory_2__toSRAM_0_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_0_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_0_array) tg++; else $display("COV: L2Directory_2.toSRAM_0_array never toggled");
      if (t_L2Directory_2__toSRAM_1_addr) tg++; else $display("COV: L2Directory_2.toSRAM_1_addr never toggled");
      if (t_L2Directory_2__toSRAM_1_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_1_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_1_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_1_wdata never toggled");
      if (t_L2Directory_2__toSRAM_1_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_1_wmask never toggled");
      if (t_L2Directory_2__toSRAM_1_re) tg++; else $display("COV: L2Directory_2.toSRAM_1_re never toggled");
      if (t_L2Directory_2__toSRAM_1_we) tg++; else $display("COV: L2Directory_2.toSRAM_1_we never toggled");
      if (t_L2Directory_2__toSRAM_1_ack) tg++; else $display("COV: L2Directory_2.toSRAM_1_ack never toggled");
      if (t_L2Directory_2__toSRAM_1_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_1_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_1_array) tg++; else $display("COV: L2Directory_2.toSRAM_1_array never toggled");
      if (t_L2Directory_2__toSRAM_2_addr) tg++; else $display("COV: L2Directory_2.toSRAM_2_addr never toggled");
      if (t_L2Directory_2__toSRAM_2_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_2_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_2_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_2_wdata never toggled");
      if (t_L2Directory_2__toSRAM_2_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_2_wmask never toggled");
      if (t_L2Directory_2__toSRAM_2_re) tg++; else $display("COV: L2Directory_2.toSRAM_2_re never toggled");
      if (t_L2Directory_2__toSRAM_2_we) tg++; else $display("COV: L2Directory_2.toSRAM_2_we never toggled");
      if (t_L2Directory_2__toSRAM_2_ack) tg++; else $display("COV: L2Directory_2.toSRAM_2_ack never toggled");
      if (t_L2Directory_2__toSRAM_2_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_2_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_2_array) tg++; else $display("COV: L2Directory_2.toSRAM_2_array never toggled");
      if (t_L2Directory_2__toSRAM_3_addr) tg++; else $display("COV: L2Directory_2.toSRAM_3_addr never toggled");
      if (t_L2Directory_2__toSRAM_3_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_3_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_3_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_3_wdata never toggled");
      if (t_L2Directory_2__toSRAM_3_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_3_wmask never toggled");
      if (t_L2Directory_2__toSRAM_3_re) tg++; else $display("COV: L2Directory_2.toSRAM_3_re never toggled");
      if (t_L2Directory_2__toSRAM_3_we) tg++; else $display("COV: L2Directory_2.toSRAM_3_we never toggled");
      if (t_L2Directory_2__toSRAM_3_ack) tg++; else $display("COV: L2Directory_2.toSRAM_3_ack never toggled");
      if (t_L2Directory_2__toSRAM_3_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_3_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_3_array) tg++; else $display("COV: L2Directory_2.toSRAM_3_array never toggled");
      if (t_L2Directory_2__toSRAM_4_addr) tg++; else $display("COV: L2Directory_2.toSRAM_4_addr never toggled");
      if (t_L2Directory_2__toSRAM_4_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_4_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_4_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_4_wdata never toggled");
      if (t_L2Directory_2__toSRAM_4_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_4_wmask never toggled");
      if (t_L2Directory_2__toSRAM_4_re) tg++; else $display("COV: L2Directory_2.toSRAM_4_re never toggled");
      if (t_L2Directory_2__toSRAM_4_we) tg++; else $display("COV: L2Directory_2.toSRAM_4_we never toggled");
      if (t_L2Directory_2__toSRAM_4_ack) tg++; else $display("COV: L2Directory_2.toSRAM_4_ack never toggled");
      if (t_L2Directory_2__toSRAM_4_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_4_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_4_array) tg++; else $display("COV: L2Directory_2.toSRAM_4_array never toggled");
      if (t_L2Directory_2__toSRAM_5_addr) tg++; else $display("COV: L2Directory_2.toSRAM_5_addr never toggled");
      if (t_L2Directory_2__toSRAM_5_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_5_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_5_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_5_wdata never toggled");
      if (t_L2Directory_2__toSRAM_5_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_5_wmask never toggled");
      if (t_L2Directory_2__toSRAM_5_re) tg++; else $display("COV: L2Directory_2.toSRAM_5_re never toggled");
      if (t_L2Directory_2__toSRAM_5_we) tg++; else $display("COV: L2Directory_2.toSRAM_5_we never toggled");
      if (t_L2Directory_2__toSRAM_5_ack) tg++; else $display("COV: L2Directory_2.toSRAM_5_ack never toggled");
      if (t_L2Directory_2__toSRAM_5_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_5_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_5_array) tg++; else $display("COV: L2Directory_2.toSRAM_5_array never toggled");
      if (t_L2Directory_2__toSRAM_6_addr) tg++; else $display("COV: L2Directory_2.toSRAM_6_addr never toggled");
      if (t_L2Directory_2__toSRAM_6_addr_rd) tg++; else $display("COV: L2Directory_2.toSRAM_6_addr_rd never toggled");
      if (t_L2Directory_2__toSRAM_6_wdata) tg++; else $display("COV: L2Directory_2.toSRAM_6_wdata never toggled");
      if (t_L2Directory_2__toSRAM_6_wmask) tg++; else $display("COV: L2Directory_2.toSRAM_6_wmask never toggled");
      if (t_L2Directory_2__toSRAM_6_re) tg++; else $display("COV: L2Directory_2.toSRAM_6_re never toggled");
      if (t_L2Directory_2__toSRAM_6_we) tg++; else $display("COV: L2Directory_2.toSRAM_6_we never toggled");
      if (t_L2Directory_2__toSRAM_6_ack) tg++; else $display("COV: L2Directory_2.toSRAM_6_ack never toggled");
      if (t_L2Directory_2__toSRAM_6_selectedOH) tg++; else $display("COV: L2Directory_2.toSRAM_6_selectedOH never toggled");
      if (t_L2Directory_2__toSRAM_6_array) tg++; else $display("COV: L2Directory_2.toSRAM_6_array never toggled");
      $display("L2Directory_2: toggled=%0d/65 (need >= 65)", tg);
      if (tg < 65) covfail = 1;
      $display("L2Directory_2: cover act = %0d", cov_L2Directory_2_act);
      if (cov_L2Directory_2_act == 0) covfail = 1;
      $display("L2Directory_2: cover sel6 = %0d", cov_L2Directory_2_sel6);
      if (cov_L2Directory_2_sel6 == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_L2Directory_3__mbist_ack) tg++; else $display("COV: L2Directory_3.mbist_ack never toggled");
      if (t_L2Directory_3__mbist_outdata) tg++; else $display("COV: L2Directory_3.mbist_outdata never toggled");
      if (t_L2Directory_3__toSRAM_0_addr) tg++; else $display("COV: L2Directory_3.toSRAM_0_addr never toggled");
      if (t_L2Directory_3__toSRAM_0_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_0_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_0_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_0_wdata never toggled");
      if (t_L2Directory_3__toSRAM_0_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_0_wmask never toggled");
      if (t_L2Directory_3__toSRAM_0_re) tg++; else $display("COV: L2Directory_3.toSRAM_0_re never toggled");
      if (t_L2Directory_3__toSRAM_0_we) tg++; else $display("COV: L2Directory_3.toSRAM_0_we never toggled");
      if (t_L2Directory_3__toSRAM_0_ack) tg++; else $display("COV: L2Directory_3.toSRAM_0_ack never toggled");
      if (t_L2Directory_3__toSRAM_0_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_0_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_0_array) tg++; else $display("COV: L2Directory_3.toSRAM_0_array never toggled");
      if (t_L2Directory_3__toSRAM_1_addr) tg++; else $display("COV: L2Directory_3.toSRAM_1_addr never toggled");
      if (t_L2Directory_3__toSRAM_1_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_1_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_1_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_1_wdata never toggled");
      if (t_L2Directory_3__toSRAM_1_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_1_wmask never toggled");
      if (t_L2Directory_3__toSRAM_1_re) tg++; else $display("COV: L2Directory_3.toSRAM_1_re never toggled");
      if (t_L2Directory_3__toSRAM_1_we) tg++; else $display("COV: L2Directory_3.toSRAM_1_we never toggled");
      if (t_L2Directory_3__toSRAM_1_ack) tg++; else $display("COV: L2Directory_3.toSRAM_1_ack never toggled");
      if (t_L2Directory_3__toSRAM_1_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_1_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_1_array) tg++; else $display("COV: L2Directory_3.toSRAM_1_array never toggled");
      if (t_L2Directory_3__toSRAM_2_addr) tg++; else $display("COV: L2Directory_3.toSRAM_2_addr never toggled");
      if (t_L2Directory_3__toSRAM_2_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_2_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_2_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_2_wdata never toggled");
      if (t_L2Directory_3__toSRAM_2_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_2_wmask never toggled");
      if (t_L2Directory_3__toSRAM_2_re) tg++; else $display("COV: L2Directory_3.toSRAM_2_re never toggled");
      if (t_L2Directory_3__toSRAM_2_we) tg++; else $display("COV: L2Directory_3.toSRAM_2_we never toggled");
      if (t_L2Directory_3__toSRAM_2_ack) tg++; else $display("COV: L2Directory_3.toSRAM_2_ack never toggled");
      if (t_L2Directory_3__toSRAM_2_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_2_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_2_array) tg++; else $display("COV: L2Directory_3.toSRAM_2_array never toggled");
      if (t_L2Directory_3__toSRAM_3_addr) tg++; else $display("COV: L2Directory_3.toSRAM_3_addr never toggled");
      if (t_L2Directory_3__toSRAM_3_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_3_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_3_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_3_wdata never toggled");
      if (t_L2Directory_3__toSRAM_3_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_3_wmask never toggled");
      if (t_L2Directory_3__toSRAM_3_re) tg++; else $display("COV: L2Directory_3.toSRAM_3_re never toggled");
      if (t_L2Directory_3__toSRAM_3_we) tg++; else $display("COV: L2Directory_3.toSRAM_3_we never toggled");
      if (t_L2Directory_3__toSRAM_3_ack) tg++; else $display("COV: L2Directory_3.toSRAM_3_ack never toggled");
      if (t_L2Directory_3__toSRAM_3_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_3_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_3_array) tg++; else $display("COV: L2Directory_3.toSRAM_3_array never toggled");
      if (t_L2Directory_3__toSRAM_4_addr) tg++; else $display("COV: L2Directory_3.toSRAM_4_addr never toggled");
      if (t_L2Directory_3__toSRAM_4_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_4_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_4_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_4_wdata never toggled");
      if (t_L2Directory_3__toSRAM_4_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_4_wmask never toggled");
      if (t_L2Directory_3__toSRAM_4_re) tg++; else $display("COV: L2Directory_3.toSRAM_4_re never toggled");
      if (t_L2Directory_3__toSRAM_4_we) tg++; else $display("COV: L2Directory_3.toSRAM_4_we never toggled");
      if (t_L2Directory_3__toSRAM_4_ack) tg++; else $display("COV: L2Directory_3.toSRAM_4_ack never toggled");
      if (t_L2Directory_3__toSRAM_4_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_4_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_4_array) tg++; else $display("COV: L2Directory_3.toSRAM_4_array never toggled");
      if (t_L2Directory_3__toSRAM_5_addr) tg++; else $display("COV: L2Directory_3.toSRAM_5_addr never toggled");
      if (t_L2Directory_3__toSRAM_5_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_5_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_5_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_5_wdata never toggled");
      if (t_L2Directory_3__toSRAM_5_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_5_wmask never toggled");
      if (t_L2Directory_3__toSRAM_5_re) tg++; else $display("COV: L2Directory_3.toSRAM_5_re never toggled");
      if (t_L2Directory_3__toSRAM_5_we) tg++; else $display("COV: L2Directory_3.toSRAM_5_we never toggled");
      if (t_L2Directory_3__toSRAM_5_ack) tg++; else $display("COV: L2Directory_3.toSRAM_5_ack never toggled");
      if (t_L2Directory_3__toSRAM_5_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_5_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_5_array) tg++; else $display("COV: L2Directory_3.toSRAM_5_array never toggled");
      if (t_L2Directory_3__toSRAM_6_addr) tg++; else $display("COV: L2Directory_3.toSRAM_6_addr never toggled");
      if (t_L2Directory_3__toSRAM_6_addr_rd) tg++; else $display("COV: L2Directory_3.toSRAM_6_addr_rd never toggled");
      if (t_L2Directory_3__toSRAM_6_wdata) tg++; else $display("COV: L2Directory_3.toSRAM_6_wdata never toggled");
      if (t_L2Directory_3__toSRAM_6_wmask) tg++; else $display("COV: L2Directory_3.toSRAM_6_wmask never toggled");
      if (t_L2Directory_3__toSRAM_6_re) tg++; else $display("COV: L2Directory_3.toSRAM_6_re never toggled");
      if (t_L2Directory_3__toSRAM_6_we) tg++; else $display("COV: L2Directory_3.toSRAM_6_we never toggled");
      if (t_L2Directory_3__toSRAM_6_ack) tg++; else $display("COV: L2Directory_3.toSRAM_6_ack never toggled");
      if (t_L2Directory_3__toSRAM_6_selectedOH) tg++; else $display("COV: L2Directory_3.toSRAM_6_selectedOH never toggled");
      if (t_L2Directory_3__toSRAM_6_array) tg++; else $display("COV: L2Directory_3.toSRAM_6_array never toggled");
      $display("L2Directory_3: toggled=%0d/65 (need >= 65)", tg);
      if (tg < 65) covfail = 1;
      $display("L2Directory_3: cover act = %0d", cov_L2Directory_3_act);
      if (cov_L2Directory_3_act == 0) covfail = 1;
      $display("L2Directory_3: cover sel6 = %0d", cov_L2Directory_3_sel6);
      if (cov_L2Directory_3_sel6 == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
