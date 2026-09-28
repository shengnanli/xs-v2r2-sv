// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：MSHRBuffer MSHRBuffer_1
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

  // ======================= MSHRBuffer =======================
  logic MSHRBuffer__io_r_valid;
  logic [7:0] MSHRBuffer__io_r_bits_id;
  logic MSHRBuffer__io_w_0_valid;
  logic [7:0] MSHRBuffer__io_w_0_bits_id;
  logic [511:0] MSHRBuffer__io_w_0_bits_data_data;
  logic [1:0] MSHRBuffer__io_w_0_bits_beatMask;
  logic MSHRBuffer__io_w_1_valid;
  logic [7:0] MSHRBuffer__io_w_1_bits_id;
  logic [511:0] MSHRBuffer__io_w_1_bits_data_data;
  wire  [511:0] g_MSHRBuffer__io_resp_data_data;
  wire  [511:0] i_MSHRBuffer__io_resp_data_data;
  logic [511:0] p_MSHRBuffer__io_resp_data_data;
  bit   t_MSHRBuffer__io_resp_data_data;
  MSHRBuffer u_g_MSHRBuffer (
    .clock (clock),
    .reset (reset),
    .io_r_valid (MSHRBuffer__io_r_valid),
    .io_r_bits_id (MSHRBuffer__io_r_bits_id),
    .io_resp_data_data (g_MSHRBuffer__io_resp_data_data),
    .io_w_0_valid (MSHRBuffer__io_w_0_valid),
    .io_w_0_bits_id (MSHRBuffer__io_w_0_bits_id),
    .io_w_0_bits_data_data (MSHRBuffer__io_w_0_bits_data_data),
    .io_w_0_bits_beatMask (MSHRBuffer__io_w_0_bits_beatMask),
    .io_w_1_valid (MSHRBuffer__io_w_1_valid),
    .io_w_1_bits_id (MSHRBuffer__io_w_1_bits_id),
    .io_w_1_bits_data_data (MSHRBuffer__io_w_1_bits_data_data)
  );
  MSHRBuffer_xs u_i_MSHRBuffer (
    .clock (clock),
    .reset (reset),
    .io_r_valid (MSHRBuffer__io_r_valid),
    .io_r_bits_id (MSHRBuffer__io_r_bits_id),
    .io_resp_data_data (i_MSHRBuffer__io_resp_data_data),
    .io_w_0_valid (MSHRBuffer__io_w_0_valid),
    .io_w_0_bits_id (MSHRBuffer__io_w_0_bits_id),
    .io_w_0_bits_data_data (MSHRBuffer__io_w_0_bits_data_data),
    .io_w_0_bits_beatMask (MSHRBuffer__io_w_0_bits_beatMask),
    .io_w_1_valid (MSHRBuffer__io_w_1_valid),
    .io_w_1_bits_id (MSHRBuffer__io_w_1_bits_id),
    .io_w_1_bits_data_data (MSHRBuffer__io_w_1_bits_data_data)
  );
  task automatic drive_MSHRBuffer();
    MSHRBuffer__io_r_valid = $urandom % 2;
    MSHRBuffer__io_r_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer__io_w_0_valid = $urandom % 2;
    MSHRBuffer__io_w_0_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer__io_w_0_bits_data_data = rnd(512);
    MSHRBuffer__io_w_0_bits_beatMask = rnd(2);
    MSHRBuffer__io_w_1_valid = $urandom % 2;
    MSHRBuffer__io_w_1_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer__io_w_1_bits_data_data = rnd(512);
  endtask
  task automatic check_MSHRBuffer();
    checks++;
    if (g_MSHRBuffer__io_resp_data_data !== i_MSHRBuffer__io_resp_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH MSHRBuffer.io_resp_data_data g=%h i=%h", cyc, g_MSHRBuffer__io_resp_data_data, i_MSHRBuffer__io_resp_data_data);
    end
    if (g_MSHRBuffer__io_resp_data_data !== p_MSHRBuffer__io_resp_data_data) t_MSHRBuffer__io_resp_data_data = 1'b1;
    p_MSHRBuffer__io_resp_data_data = g_MSHRBuffer__io_resp_data_data;
  endtask
  longint cov_MSHRBuffer_rd = 0;
  longint cov_MSHRBuffer_w0partial = 0;
  longint cov_MSHRBuffer_collide = 0;
  longint cov_MSHRBuffer_rdhigh = 0;
  task automatic cover_MSHRBuffer();
    if (u_g_MSHRBuffer.io_r_valid) cov_MSHRBuffer_rd++;
    if (MSHRBuffer__io_w_0_valid && MSHRBuffer__io_w_0_bits_beatMask != 2'b11 && MSHRBuffer__io_w_0_bits_id < 16) cov_MSHRBuffer_w0partial++;
    if (MSHRBuffer__io_w_0_valid && MSHRBuffer__io_w_1_valid && MSHRBuffer__io_w_0_bits_id == MSHRBuffer__io_w_1_bits_id && MSHRBuffer__io_w_0_bits_id < 16) cov_MSHRBuffer_collide++;
    if (MSHRBuffer__io_r_valid && MSHRBuffer__io_r_bits_id > 15) cov_MSHRBuffer_rdhigh++;
  endtask
  task automatic preinit_MSHRBuffer();
  endtask
  task automatic sync_MSHRBuffer();
    force u_i_MSHRBuffer.u_core.buffer[0][0] = u_g_MSHRBuffer.buffer_0_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[0][0];
    force u_i_MSHRBuffer.u_core.buffer[0][1] = u_g_MSHRBuffer.buffer_0_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[0][1];
    force u_i_MSHRBuffer.u_core.buffer[1][0] = u_g_MSHRBuffer.buffer_1_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[1][0];
    force u_i_MSHRBuffer.u_core.buffer[1][1] = u_g_MSHRBuffer.buffer_1_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[1][1];
    force u_i_MSHRBuffer.u_core.buffer[2][0] = u_g_MSHRBuffer.buffer_2_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[2][0];
    force u_i_MSHRBuffer.u_core.buffer[2][1] = u_g_MSHRBuffer.buffer_2_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[2][1];
    force u_i_MSHRBuffer.u_core.buffer[3][0] = u_g_MSHRBuffer.buffer_3_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[3][0];
    force u_i_MSHRBuffer.u_core.buffer[3][1] = u_g_MSHRBuffer.buffer_3_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[3][1];
    force u_i_MSHRBuffer.u_core.buffer[4][0] = u_g_MSHRBuffer.buffer_4_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[4][0];
    force u_i_MSHRBuffer.u_core.buffer[4][1] = u_g_MSHRBuffer.buffer_4_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[4][1];
    force u_i_MSHRBuffer.u_core.buffer[5][0] = u_g_MSHRBuffer.buffer_5_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[5][0];
    force u_i_MSHRBuffer.u_core.buffer[5][1] = u_g_MSHRBuffer.buffer_5_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[5][1];
    force u_i_MSHRBuffer.u_core.buffer[6][0] = u_g_MSHRBuffer.buffer_6_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[6][0];
    force u_i_MSHRBuffer.u_core.buffer[6][1] = u_g_MSHRBuffer.buffer_6_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[6][1];
    force u_i_MSHRBuffer.u_core.buffer[7][0] = u_g_MSHRBuffer.buffer_7_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[7][0];
    force u_i_MSHRBuffer.u_core.buffer[7][1] = u_g_MSHRBuffer.buffer_7_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[7][1];
    force u_i_MSHRBuffer.u_core.buffer[8][0] = u_g_MSHRBuffer.buffer_8_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[8][0];
    force u_i_MSHRBuffer.u_core.buffer[8][1] = u_g_MSHRBuffer.buffer_8_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[8][1];
    force u_i_MSHRBuffer.u_core.buffer[9][0] = u_g_MSHRBuffer.buffer_9_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[9][0];
    force u_i_MSHRBuffer.u_core.buffer[9][1] = u_g_MSHRBuffer.buffer_9_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[9][1];
    force u_i_MSHRBuffer.u_core.buffer[10][0] = u_g_MSHRBuffer.buffer_10_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[10][0];
    force u_i_MSHRBuffer.u_core.buffer[10][1] = u_g_MSHRBuffer.buffer_10_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[10][1];
    force u_i_MSHRBuffer.u_core.buffer[11][0] = u_g_MSHRBuffer.buffer_11_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[11][0];
    force u_i_MSHRBuffer.u_core.buffer[11][1] = u_g_MSHRBuffer.buffer_11_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[11][1];
    force u_i_MSHRBuffer.u_core.buffer[12][0] = u_g_MSHRBuffer.buffer_12_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[12][0];
    force u_i_MSHRBuffer.u_core.buffer[12][1] = u_g_MSHRBuffer.buffer_12_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[12][1];
    force u_i_MSHRBuffer.u_core.buffer[13][0] = u_g_MSHRBuffer.buffer_13_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[13][0];
    force u_i_MSHRBuffer.u_core.buffer[13][1] = u_g_MSHRBuffer.buffer_13_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[13][1];
    force u_i_MSHRBuffer.u_core.buffer[14][0] = u_g_MSHRBuffer.buffer_14_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[14][0];
    force u_i_MSHRBuffer.u_core.buffer[14][1] = u_g_MSHRBuffer.buffer_14_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[14][1];
    force u_i_MSHRBuffer.u_core.buffer[15][0] = u_g_MSHRBuffer.buffer_15_0;
    #0 release u_i_MSHRBuffer.u_core.buffer[15][0];
    force u_i_MSHRBuffer.u_core.buffer[15][1] = u_g_MSHRBuffer.buffer_15_1;
    #0 release u_i_MSHRBuffer.u_core.buffer[15][1];
  endtask

  // ======================= MSHRBuffer_1 =======================
  logic MSHRBuffer_1__io_r_valid;
  logic [7:0] MSHRBuffer_1__io_r_bits_id;
  logic MSHRBuffer_1__io_w_0_valid;
  logic [7:0] MSHRBuffer_1__io_w_0_bits_id;
  logic [511:0] MSHRBuffer_1__io_w_0_bits_data_data;
  logic MSHRBuffer_1__io_w_1_valid;
  logic [7:0] MSHRBuffer_1__io_w_1_bits_id;
  logic [511:0] MSHRBuffer_1__io_w_1_bits_data_data;
  logic MSHRBuffer_1__io_w_2_valid;
  logic [7:0] MSHRBuffer_1__io_w_2_bits_id;
  logic [511:0] MSHRBuffer_1__io_w_2_bits_data_data;
  wire  [511:0] g_MSHRBuffer_1__io_resp_data_data;
  wire  [511:0] i_MSHRBuffer_1__io_resp_data_data;
  logic [511:0] p_MSHRBuffer_1__io_resp_data_data;
  bit   t_MSHRBuffer_1__io_resp_data_data;
  MSHRBuffer_1 u_g_MSHRBuffer_1 (
    .clock (clock),
    .reset (reset),
    .io_r_valid (MSHRBuffer_1__io_r_valid),
    .io_r_bits_id (MSHRBuffer_1__io_r_bits_id),
    .io_resp_data_data (g_MSHRBuffer_1__io_resp_data_data),
    .io_w_0_valid (MSHRBuffer_1__io_w_0_valid),
    .io_w_0_bits_id (MSHRBuffer_1__io_w_0_bits_id),
    .io_w_0_bits_data_data (MSHRBuffer_1__io_w_0_bits_data_data),
    .io_w_1_valid (MSHRBuffer_1__io_w_1_valid),
    .io_w_1_bits_id (MSHRBuffer_1__io_w_1_bits_id),
    .io_w_1_bits_data_data (MSHRBuffer_1__io_w_1_bits_data_data),
    .io_w_2_valid (MSHRBuffer_1__io_w_2_valid),
    .io_w_2_bits_id (MSHRBuffer_1__io_w_2_bits_id),
    .io_w_2_bits_data_data (MSHRBuffer_1__io_w_2_bits_data_data)
  );
  MSHRBuffer_1_xs u_i_MSHRBuffer_1 (
    .clock (clock),
    .reset (reset),
    .io_r_valid (MSHRBuffer_1__io_r_valid),
    .io_r_bits_id (MSHRBuffer_1__io_r_bits_id),
    .io_resp_data_data (i_MSHRBuffer_1__io_resp_data_data),
    .io_w_0_valid (MSHRBuffer_1__io_w_0_valid),
    .io_w_0_bits_id (MSHRBuffer_1__io_w_0_bits_id),
    .io_w_0_bits_data_data (MSHRBuffer_1__io_w_0_bits_data_data),
    .io_w_1_valid (MSHRBuffer_1__io_w_1_valid),
    .io_w_1_bits_id (MSHRBuffer_1__io_w_1_bits_id),
    .io_w_1_bits_data_data (MSHRBuffer_1__io_w_1_bits_data_data),
    .io_w_2_valid (MSHRBuffer_1__io_w_2_valid),
    .io_w_2_bits_id (MSHRBuffer_1__io_w_2_bits_id),
    .io_w_2_bits_data_data (MSHRBuffer_1__io_w_2_bits_data_data)
  );
  task automatic drive_MSHRBuffer_1();
    MSHRBuffer_1__io_r_valid = $urandom % 2;
    MSHRBuffer_1__io_r_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer_1__io_w_0_valid = $urandom % 2;
    MSHRBuffer_1__io_w_0_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer_1__io_w_0_bits_data_data = rnd(512);
    MSHRBuffer_1__io_w_1_valid = $urandom % 2;
    MSHRBuffer_1__io_w_1_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer_1__io_w_1_bits_data_data = rnd(512);
    MSHRBuffer_1__io_w_2_valid = $urandom % 2;
    MSHRBuffer_1__io_w_2_bits_id = (($urandom % 8) == 0) ? 8'($urandom) : 8'($urandom_range(0, 17));
    MSHRBuffer_1__io_w_2_bits_data_data = rnd(512);
  endtask
  task automatic check_MSHRBuffer_1();
    checks++;
    if (g_MSHRBuffer_1__io_resp_data_data !== i_MSHRBuffer_1__io_resp_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH MSHRBuffer_1.io_resp_data_data g=%h i=%h", cyc, g_MSHRBuffer_1__io_resp_data_data, i_MSHRBuffer_1__io_resp_data_data);
    end
    if (g_MSHRBuffer_1__io_resp_data_data !== p_MSHRBuffer_1__io_resp_data_data) t_MSHRBuffer_1__io_resp_data_data = 1'b1;
    p_MSHRBuffer_1__io_resp_data_data = g_MSHRBuffer_1__io_resp_data_data;
  endtask
  longint cov_MSHRBuffer_1_rd = 0;
  longint cov_MSHRBuffer_1_collide3 = 0;
  task automatic cover_MSHRBuffer_1();
    if (u_g_MSHRBuffer_1.io_r_valid) cov_MSHRBuffer_1_rd++;
    if (MSHRBuffer_1__io_w_1_valid && MSHRBuffer_1__io_w_2_valid && MSHRBuffer_1__io_w_1_bits_id == MSHRBuffer_1__io_w_2_bits_id && MSHRBuffer_1__io_w_1_bits_id < 16) cov_MSHRBuffer_1_collide3++;
  endtask
  task automatic preinit_MSHRBuffer_1();
  endtask
  task automatic sync_MSHRBuffer_1();
    force u_i_MSHRBuffer_1.u_core.buffer[0][0] = u_g_MSHRBuffer_1.buffer_0_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[0][0];
    force u_i_MSHRBuffer_1.u_core.buffer[0][1] = u_g_MSHRBuffer_1.buffer_0_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[0][1];
    force u_i_MSHRBuffer_1.u_core.buffer[1][0] = u_g_MSHRBuffer_1.buffer_1_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[1][0];
    force u_i_MSHRBuffer_1.u_core.buffer[1][1] = u_g_MSHRBuffer_1.buffer_1_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[1][1];
    force u_i_MSHRBuffer_1.u_core.buffer[2][0] = u_g_MSHRBuffer_1.buffer_2_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[2][0];
    force u_i_MSHRBuffer_1.u_core.buffer[2][1] = u_g_MSHRBuffer_1.buffer_2_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[2][1];
    force u_i_MSHRBuffer_1.u_core.buffer[3][0] = u_g_MSHRBuffer_1.buffer_3_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[3][0];
    force u_i_MSHRBuffer_1.u_core.buffer[3][1] = u_g_MSHRBuffer_1.buffer_3_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[3][1];
    force u_i_MSHRBuffer_1.u_core.buffer[4][0] = u_g_MSHRBuffer_1.buffer_4_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[4][0];
    force u_i_MSHRBuffer_1.u_core.buffer[4][1] = u_g_MSHRBuffer_1.buffer_4_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[4][1];
    force u_i_MSHRBuffer_1.u_core.buffer[5][0] = u_g_MSHRBuffer_1.buffer_5_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[5][0];
    force u_i_MSHRBuffer_1.u_core.buffer[5][1] = u_g_MSHRBuffer_1.buffer_5_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[5][1];
    force u_i_MSHRBuffer_1.u_core.buffer[6][0] = u_g_MSHRBuffer_1.buffer_6_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[6][0];
    force u_i_MSHRBuffer_1.u_core.buffer[6][1] = u_g_MSHRBuffer_1.buffer_6_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[6][1];
    force u_i_MSHRBuffer_1.u_core.buffer[7][0] = u_g_MSHRBuffer_1.buffer_7_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[7][0];
    force u_i_MSHRBuffer_1.u_core.buffer[7][1] = u_g_MSHRBuffer_1.buffer_7_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[7][1];
    force u_i_MSHRBuffer_1.u_core.buffer[8][0] = u_g_MSHRBuffer_1.buffer_8_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[8][0];
    force u_i_MSHRBuffer_1.u_core.buffer[8][1] = u_g_MSHRBuffer_1.buffer_8_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[8][1];
    force u_i_MSHRBuffer_1.u_core.buffer[9][0] = u_g_MSHRBuffer_1.buffer_9_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[9][0];
    force u_i_MSHRBuffer_1.u_core.buffer[9][1] = u_g_MSHRBuffer_1.buffer_9_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[9][1];
    force u_i_MSHRBuffer_1.u_core.buffer[10][0] = u_g_MSHRBuffer_1.buffer_10_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[10][0];
    force u_i_MSHRBuffer_1.u_core.buffer[10][1] = u_g_MSHRBuffer_1.buffer_10_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[10][1];
    force u_i_MSHRBuffer_1.u_core.buffer[11][0] = u_g_MSHRBuffer_1.buffer_11_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[11][0];
    force u_i_MSHRBuffer_1.u_core.buffer[11][1] = u_g_MSHRBuffer_1.buffer_11_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[11][1];
    force u_i_MSHRBuffer_1.u_core.buffer[12][0] = u_g_MSHRBuffer_1.buffer_12_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[12][0];
    force u_i_MSHRBuffer_1.u_core.buffer[12][1] = u_g_MSHRBuffer_1.buffer_12_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[12][1];
    force u_i_MSHRBuffer_1.u_core.buffer[13][0] = u_g_MSHRBuffer_1.buffer_13_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[13][0];
    force u_i_MSHRBuffer_1.u_core.buffer[13][1] = u_g_MSHRBuffer_1.buffer_13_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[13][1];
    force u_i_MSHRBuffer_1.u_core.buffer[14][0] = u_g_MSHRBuffer_1.buffer_14_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[14][0];
    force u_i_MSHRBuffer_1.u_core.buffer[14][1] = u_g_MSHRBuffer_1.buffer_14_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[14][1];
    force u_i_MSHRBuffer_1.u_core.buffer[15][0] = u_g_MSHRBuffer_1.buffer_15_0;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[15][0];
    force u_i_MSHRBuffer_1.u_core.buffer[15][1] = u_g_MSHRBuffer_1.buffer_15_1;
    #0 release u_i_MSHRBuffer_1.u_core.buffer[15][1];
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_MSHRBuffer();
    drive_MSHRBuffer_1();
    #1;
    preinit_MSHRBuffer();
    preinit_MSHRBuffer_1();
    sync_MSHRBuffer();
    sync_MSHRBuffer_1();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_MSHRBuffer();
      drive_MSHRBuffer_1();
      #1;
      check_MSHRBuffer();
      cover_MSHRBuffer();
      check_MSHRBuffer_1();
      cover_MSHRBuffer_1();
    end
    begin int tg; tg = 0;
      if (t_MSHRBuffer__io_resp_data_data) tg++; else $display("COV: MSHRBuffer.io_resp_data_data never toggled");
      $display("MSHRBuffer: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("MSHRBuffer: cover rd = %0d", cov_MSHRBuffer_rd);
      if (cov_MSHRBuffer_rd == 0) covfail = 1;
      $display("MSHRBuffer: cover w0partial = %0d", cov_MSHRBuffer_w0partial);
      if (cov_MSHRBuffer_w0partial == 0) covfail = 1;
      $display("MSHRBuffer: cover collide = %0d", cov_MSHRBuffer_collide);
      if (cov_MSHRBuffer_collide == 0) covfail = 1;
      $display("MSHRBuffer: cover rdhigh = %0d", cov_MSHRBuffer_rdhigh);
      if (cov_MSHRBuffer_rdhigh == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_MSHRBuffer_1__io_resp_data_data) tg++; else $display("COV: MSHRBuffer_1.io_resp_data_data never toggled");
      $display("MSHRBuffer_1: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("MSHRBuffer_1: cover rd = %0d", cov_MSHRBuffer_1_rd);
      if (cov_MSHRBuffer_1_rd == 0) covfail = 1;
      $display("MSHRBuffer_1: cover collide3 = %0d", cov_MSHRBuffer_1_collide3);
      if (cov_MSHRBuffer_1_collide3 == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
