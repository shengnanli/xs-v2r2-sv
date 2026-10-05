// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：ICacheBuffer InstrUncacheBuffer ICacheCtrlBuffer
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

  // ======================= ICacheBuffer =======================
  logic ICacheBuffer__auto_in_a_valid;
  logic [3:0] ICacheBuffer__auto_in_a_bits_source;
  logic [47:0] ICacheBuffer__auto_in_a_bits_address;
  logic ICacheBuffer__auto_out_a_ready;
  logic ICacheBuffer__auto_out_d_valid;
  logic [3:0] ICacheBuffer__auto_out_d_bits_opcode;
  logic [1:0] ICacheBuffer__auto_out_d_bits_param;
  logic [2:0] ICacheBuffer__auto_out_d_bits_size;
  logic [3:0] ICacheBuffer__auto_out_d_bits_source;
  logic [9:0] ICacheBuffer__auto_out_d_bits_sink;
  logic ICacheBuffer__auto_out_d_bits_denied;
  logic [255:0] ICacheBuffer__auto_out_d_bits_data;
  logic ICacheBuffer__auto_out_d_bits_corrupt;
  wire  g_ICacheBuffer__auto_in_a_ready;
  wire  i_ICacheBuffer__auto_in_a_ready;
  logic p_ICacheBuffer__auto_in_a_ready;
  bit   t_ICacheBuffer__auto_in_a_ready;
  wire  g_ICacheBuffer__auto_in_d_valid;
  wire  i_ICacheBuffer__auto_in_d_valid;
  logic p_ICacheBuffer__auto_in_d_valid;
  bit   t_ICacheBuffer__auto_in_d_valid;
  wire  [3:0] g_ICacheBuffer__auto_in_d_bits_opcode;
  wire  [3:0] i_ICacheBuffer__auto_in_d_bits_opcode;
  logic [3:0] p_ICacheBuffer__auto_in_d_bits_opcode;
  bit   t_ICacheBuffer__auto_in_d_bits_opcode;
  wire  [2:0] g_ICacheBuffer__auto_in_d_bits_size;
  wire  [2:0] i_ICacheBuffer__auto_in_d_bits_size;
  logic [2:0] p_ICacheBuffer__auto_in_d_bits_size;
  bit   t_ICacheBuffer__auto_in_d_bits_size;
  wire  [3:0] g_ICacheBuffer__auto_in_d_bits_source;
  wire  [3:0] i_ICacheBuffer__auto_in_d_bits_source;
  logic [3:0] p_ICacheBuffer__auto_in_d_bits_source;
  bit   t_ICacheBuffer__auto_in_d_bits_source;
  wire  [255:0] g_ICacheBuffer__auto_in_d_bits_data;
  wire  [255:0] i_ICacheBuffer__auto_in_d_bits_data;
  logic [255:0] p_ICacheBuffer__auto_in_d_bits_data;
  bit   t_ICacheBuffer__auto_in_d_bits_data;
  wire  g_ICacheBuffer__auto_in_d_bits_corrupt;
  wire  i_ICacheBuffer__auto_in_d_bits_corrupt;
  logic p_ICacheBuffer__auto_in_d_bits_corrupt;
  bit   t_ICacheBuffer__auto_in_d_bits_corrupt;
  wire  g_ICacheBuffer__auto_out_a_valid;
  wire  i_ICacheBuffer__auto_out_a_valid;
  logic p_ICacheBuffer__auto_out_a_valid;
  bit   t_ICacheBuffer__auto_out_a_valid;
  wire  [3:0] g_ICacheBuffer__auto_out_a_bits_opcode;
  wire  [3:0] i_ICacheBuffer__auto_out_a_bits_opcode;
  logic [3:0] p_ICacheBuffer__auto_out_a_bits_opcode;
  bit   t_ICacheBuffer__auto_out_a_bits_opcode;
  wire  [2:0] g_ICacheBuffer__auto_out_a_bits_param;
  wire  [2:0] i_ICacheBuffer__auto_out_a_bits_param;
  logic [2:0] p_ICacheBuffer__auto_out_a_bits_param;
  bit   t_ICacheBuffer__auto_out_a_bits_param;
  wire  [2:0] g_ICacheBuffer__auto_out_a_bits_size;
  wire  [2:0] i_ICacheBuffer__auto_out_a_bits_size;
  logic [2:0] p_ICacheBuffer__auto_out_a_bits_size;
  bit   t_ICacheBuffer__auto_out_a_bits_size;
  wire  [3:0] g_ICacheBuffer__auto_out_a_bits_source;
  wire  [3:0] i_ICacheBuffer__auto_out_a_bits_source;
  logic [3:0] p_ICacheBuffer__auto_out_a_bits_source;
  bit   t_ICacheBuffer__auto_out_a_bits_source;
  wire  [47:0] g_ICacheBuffer__auto_out_a_bits_address;
  wire  [47:0] i_ICacheBuffer__auto_out_a_bits_address;
  logic [47:0] p_ICacheBuffer__auto_out_a_bits_address;
  bit   t_ICacheBuffer__auto_out_a_bits_address;
  wire  [1:0] g_ICacheBuffer__auto_out_a_bits_user_alias;
  wire  [1:0] i_ICacheBuffer__auto_out_a_bits_user_alias;
  logic [1:0] p_ICacheBuffer__auto_out_a_bits_user_alias;
  bit   t_ICacheBuffer__auto_out_a_bits_user_alias;
  wire  [4:0] g_ICacheBuffer__auto_out_a_bits_user_reqSource;
  wire  [4:0] i_ICacheBuffer__auto_out_a_bits_user_reqSource;
  logic [4:0] p_ICacheBuffer__auto_out_a_bits_user_reqSource;
  bit   t_ICacheBuffer__auto_out_a_bits_user_reqSource;
  wire  g_ICacheBuffer__auto_out_a_bits_user_needHint;
  wire  i_ICacheBuffer__auto_out_a_bits_user_needHint;
  logic p_ICacheBuffer__auto_out_a_bits_user_needHint;
  bit   t_ICacheBuffer__auto_out_a_bits_user_needHint;
  wire  [31:0] g_ICacheBuffer__auto_out_a_bits_mask;
  wire  [31:0] i_ICacheBuffer__auto_out_a_bits_mask;
  logic [31:0] p_ICacheBuffer__auto_out_a_bits_mask;
  bit   t_ICacheBuffer__auto_out_a_bits_mask;
  wire  [255:0] g_ICacheBuffer__auto_out_a_bits_data;
  wire  [255:0] i_ICacheBuffer__auto_out_a_bits_data;
  logic [255:0] p_ICacheBuffer__auto_out_a_bits_data;
  bit   t_ICacheBuffer__auto_out_a_bits_data;
  wire  g_ICacheBuffer__auto_out_a_bits_corrupt;
  wire  i_ICacheBuffer__auto_out_a_bits_corrupt;
  logic p_ICacheBuffer__auto_out_a_bits_corrupt;
  bit   t_ICacheBuffer__auto_out_a_bits_corrupt;
  wire  g_ICacheBuffer__auto_out_d_ready;
  wire  i_ICacheBuffer__auto_out_d_ready;
  logic p_ICacheBuffer__auto_out_d_ready;
  bit   t_ICacheBuffer__auto_out_d_ready;
  ICacheBuffer u_g_ICacheBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (g_ICacheBuffer__auto_in_a_ready),
    .auto_in_a_valid (ICacheBuffer__auto_in_a_valid),
    .auto_in_a_bits_source (ICacheBuffer__auto_in_a_bits_source),
    .auto_in_a_bits_address (ICacheBuffer__auto_in_a_bits_address),
    .auto_in_d_valid (g_ICacheBuffer__auto_in_d_valid),
    .auto_in_d_bits_opcode (g_ICacheBuffer__auto_in_d_bits_opcode),
    .auto_in_d_bits_size (g_ICacheBuffer__auto_in_d_bits_size),
    .auto_in_d_bits_source (g_ICacheBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_data (g_ICacheBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (g_ICacheBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (ICacheBuffer__auto_out_a_ready),
    .auto_out_a_valid (g_ICacheBuffer__auto_out_a_valid),
    .auto_out_a_bits_opcode (g_ICacheBuffer__auto_out_a_bits_opcode),
    .auto_out_a_bits_param (g_ICacheBuffer__auto_out_a_bits_param),
    .auto_out_a_bits_size (g_ICacheBuffer__auto_out_a_bits_size),
    .auto_out_a_bits_source (g_ICacheBuffer__auto_out_a_bits_source),
    .auto_out_a_bits_address (g_ICacheBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_user_alias (g_ICacheBuffer__auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource (g_ICacheBuffer__auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint (g_ICacheBuffer__auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask (g_ICacheBuffer__auto_out_a_bits_mask),
    .auto_out_a_bits_data (g_ICacheBuffer__auto_out_a_bits_data),
    .auto_out_a_bits_corrupt (g_ICacheBuffer__auto_out_a_bits_corrupt),
    .auto_out_d_ready (g_ICacheBuffer__auto_out_d_ready),
    .auto_out_d_valid (ICacheBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (ICacheBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_param (ICacheBuffer__auto_out_d_bits_param),
    .auto_out_d_bits_size (ICacheBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (ICacheBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_sink (ICacheBuffer__auto_out_d_bits_sink),
    .auto_out_d_bits_denied (ICacheBuffer__auto_out_d_bits_denied),
    .auto_out_d_bits_data (ICacheBuffer__auto_out_d_bits_data),
    .auto_out_d_bits_corrupt (ICacheBuffer__auto_out_d_bits_corrupt)
  );
  ICacheBuffer_xs u_i_ICacheBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (i_ICacheBuffer__auto_in_a_ready),
    .auto_in_a_valid (ICacheBuffer__auto_in_a_valid),
    .auto_in_a_bits_source (ICacheBuffer__auto_in_a_bits_source),
    .auto_in_a_bits_address (ICacheBuffer__auto_in_a_bits_address),
    .auto_in_d_valid (i_ICacheBuffer__auto_in_d_valid),
    .auto_in_d_bits_opcode (i_ICacheBuffer__auto_in_d_bits_opcode),
    .auto_in_d_bits_size (i_ICacheBuffer__auto_in_d_bits_size),
    .auto_in_d_bits_source (i_ICacheBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_data (i_ICacheBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (i_ICacheBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (ICacheBuffer__auto_out_a_ready),
    .auto_out_a_valid (i_ICacheBuffer__auto_out_a_valid),
    .auto_out_a_bits_opcode (i_ICacheBuffer__auto_out_a_bits_opcode),
    .auto_out_a_bits_param (i_ICacheBuffer__auto_out_a_bits_param),
    .auto_out_a_bits_size (i_ICacheBuffer__auto_out_a_bits_size),
    .auto_out_a_bits_source (i_ICacheBuffer__auto_out_a_bits_source),
    .auto_out_a_bits_address (i_ICacheBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_user_alias (i_ICacheBuffer__auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource (i_ICacheBuffer__auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint (i_ICacheBuffer__auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask (i_ICacheBuffer__auto_out_a_bits_mask),
    .auto_out_a_bits_data (i_ICacheBuffer__auto_out_a_bits_data),
    .auto_out_a_bits_corrupt (i_ICacheBuffer__auto_out_a_bits_corrupt),
    .auto_out_d_ready (i_ICacheBuffer__auto_out_d_ready),
    .auto_out_d_valid (ICacheBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (ICacheBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_param (ICacheBuffer__auto_out_d_bits_param),
    .auto_out_d_bits_size (ICacheBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (ICacheBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_sink (ICacheBuffer__auto_out_d_bits_sink),
    .auto_out_d_bits_denied (ICacheBuffer__auto_out_d_bits_denied),
    .auto_out_d_bits_data (ICacheBuffer__auto_out_d_bits_data),
    .auto_out_d_bits_corrupt (ICacheBuffer__auto_out_d_bits_corrupt)
  );
  task automatic drive_ICacheBuffer();
    ICacheBuffer__auto_in_a_valid = $urandom % 2;
    ICacheBuffer__auto_in_a_bits_source = rnd(4);
    ICacheBuffer__auto_in_a_bits_address = rnd(48);
    ICacheBuffer__auto_out_a_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    ICacheBuffer__auto_out_d_valid = $urandom % 2;
    ICacheBuffer__auto_out_d_bits_opcode = rnd(4);
    ICacheBuffer__auto_out_d_bits_param = rnd(2);
    ICacheBuffer__auto_out_d_bits_size = rnd(3);
    ICacheBuffer__auto_out_d_bits_source = rnd(4);
    ICacheBuffer__auto_out_d_bits_sink = rnd(10);
    ICacheBuffer__auto_out_d_bits_denied = $urandom % 2;
    ICacheBuffer__auto_out_d_bits_data = rnd(256);
    ICacheBuffer__auto_out_d_bits_corrupt = $urandom % 2;
  endtask
  task automatic check_ICacheBuffer();
    checks++;
    if (g_ICacheBuffer__auto_in_a_ready !== i_ICacheBuffer__auto_in_a_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_a_ready g=%h i=%h", cyc, g_ICacheBuffer__auto_in_a_ready, i_ICacheBuffer__auto_in_a_ready);
    end
    if (g_ICacheBuffer__auto_in_a_ready !== p_ICacheBuffer__auto_in_a_ready) t_ICacheBuffer__auto_in_a_ready = 1'b1;
    p_ICacheBuffer__auto_in_a_ready = g_ICacheBuffer__auto_in_a_ready;
    checks++;
    if (g_ICacheBuffer__auto_in_d_valid !== i_ICacheBuffer__auto_in_d_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_valid g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_valid, i_ICacheBuffer__auto_in_d_valid);
    end
    if (g_ICacheBuffer__auto_in_d_valid !== p_ICacheBuffer__auto_in_d_valid) t_ICacheBuffer__auto_in_d_valid = 1'b1;
    p_ICacheBuffer__auto_in_d_valid = g_ICacheBuffer__auto_in_d_valid;
    checks++;
    if (g_ICacheBuffer__auto_in_d_bits_opcode !== i_ICacheBuffer__auto_in_d_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_bits_opcode g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_bits_opcode, i_ICacheBuffer__auto_in_d_bits_opcode);
    end
    if (g_ICacheBuffer__auto_in_d_bits_opcode !== p_ICacheBuffer__auto_in_d_bits_opcode) t_ICacheBuffer__auto_in_d_bits_opcode = 1'b1;
    p_ICacheBuffer__auto_in_d_bits_opcode = g_ICacheBuffer__auto_in_d_bits_opcode;
    checks++;
    if (g_ICacheBuffer__auto_in_d_bits_size !== i_ICacheBuffer__auto_in_d_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_bits_size g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_bits_size, i_ICacheBuffer__auto_in_d_bits_size);
    end
    if (g_ICacheBuffer__auto_in_d_bits_size !== p_ICacheBuffer__auto_in_d_bits_size) t_ICacheBuffer__auto_in_d_bits_size = 1'b1;
    p_ICacheBuffer__auto_in_d_bits_size = g_ICacheBuffer__auto_in_d_bits_size;
    checks++;
    if (g_ICacheBuffer__auto_in_d_bits_source !== i_ICacheBuffer__auto_in_d_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_bits_source g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_bits_source, i_ICacheBuffer__auto_in_d_bits_source);
    end
    if (g_ICacheBuffer__auto_in_d_bits_source !== p_ICacheBuffer__auto_in_d_bits_source) t_ICacheBuffer__auto_in_d_bits_source = 1'b1;
    p_ICacheBuffer__auto_in_d_bits_source = g_ICacheBuffer__auto_in_d_bits_source;
    checks++;
    if (g_ICacheBuffer__auto_in_d_bits_data !== i_ICacheBuffer__auto_in_d_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_bits_data g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_bits_data, i_ICacheBuffer__auto_in_d_bits_data);
    end
    if (g_ICacheBuffer__auto_in_d_bits_data !== p_ICacheBuffer__auto_in_d_bits_data) t_ICacheBuffer__auto_in_d_bits_data = 1'b1;
    p_ICacheBuffer__auto_in_d_bits_data = g_ICacheBuffer__auto_in_d_bits_data;
    checks++;
    if (g_ICacheBuffer__auto_in_d_bits_corrupt !== i_ICacheBuffer__auto_in_d_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_in_d_bits_corrupt g=%h i=%h", cyc, g_ICacheBuffer__auto_in_d_bits_corrupt, i_ICacheBuffer__auto_in_d_bits_corrupt);
    end
    if (g_ICacheBuffer__auto_in_d_bits_corrupt !== p_ICacheBuffer__auto_in_d_bits_corrupt) t_ICacheBuffer__auto_in_d_bits_corrupt = 1'b1;
    p_ICacheBuffer__auto_in_d_bits_corrupt = g_ICacheBuffer__auto_in_d_bits_corrupt;
    checks++;
    if (g_ICacheBuffer__auto_out_a_valid !== i_ICacheBuffer__auto_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_valid g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_valid, i_ICacheBuffer__auto_out_a_valid);
    end
    if (g_ICacheBuffer__auto_out_a_valid !== p_ICacheBuffer__auto_out_a_valid) t_ICacheBuffer__auto_out_a_valid = 1'b1;
    p_ICacheBuffer__auto_out_a_valid = g_ICacheBuffer__auto_out_a_valid;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_opcode !== i_ICacheBuffer__auto_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_opcode g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_opcode, i_ICacheBuffer__auto_out_a_bits_opcode);
    end
    if (g_ICacheBuffer__auto_out_a_bits_opcode !== p_ICacheBuffer__auto_out_a_bits_opcode) t_ICacheBuffer__auto_out_a_bits_opcode = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_opcode = g_ICacheBuffer__auto_out_a_bits_opcode;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_param !== i_ICacheBuffer__auto_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_param g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_param, i_ICacheBuffer__auto_out_a_bits_param);
    end
    if (g_ICacheBuffer__auto_out_a_bits_param !== p_ICacheBuffer__auto_out_a_bits_param) t_ICacheBuffer__auto_out_a_bits_param = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_param = g_ICacheBuffer__auto_out_a_bits_param;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_size !== i_ICacheBuffer__auto_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_size g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_size, i_ICacheBuffer__auto_out_a_bits_size);
    end
    if (g_ICacheBuffer__auto_out_a_bits_size !== p_ICacheBuffer__auto_out_a_bits_size) t_ICacheBuffer__auto_out_a_bits_size = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_size = g_ICacheBuffer__auto_out_a_bits_size;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_source !== i_ICacheBuffer__auto_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_source g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_source, i_ICacheBuffer__auto_out_a_bits_source);
    end
    if (g_ICacheBuffer__auto_out_a_bits_source !== p_ICacheBuffer__auto_out_a_bits_source) t_ICacheBuffer__auto_out_a_bits_source = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_source = g_ICacheBuffer__auto_out_a_bits_source;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_address !== i_ICacheBuffer__auto_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_address g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_address, i_ICacheBuffer__auto_out_a_bits_address);
    end
    if (g_ICacheBuffer__auto_out_a_bits_address !== p_ICacheBuffer__auto_out_a_bits_address) t_ICacheBuffer__auto_out_a_bits_address = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_address = g_ICacheBuffer__auto_out_a_bits_address;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_user_alias !== i_ICacheBuffer__auto_out_a_bits_user_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_user_alias g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_user_alias, i_ICacheBuffer__auto_out_a_bits_user_alias);
    end
    if (g_ICacheBuffer__auto_out_a_bits_user_alias !== p_ICacheBuffer__auto_out_a_bits_user_alias) t_ICacheBuffer__auto_out_a_bits_user_alias = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_user_alias = g_ICacheBuffer__auto_out_a_bits_user_alias;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_user_reqSource !== i_ICacheBuffer__auto_out_a_bits_user_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_user_reqSource g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_user_reqSource, i_ICacheBuffer__auto_out_a_bits_user_reqSource);
    end
    if (g_ICacheBuffer__auto_out_a_bits_user_reqSource !== p_ICacheBuffer__auto_out_a_bits_user_reqSource) t_ICacheBuffer__auto_out_a_bits_user_reqSource = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_user_reqSource = g_ICacheBuffer__auto_out_a_bits_user_reqSource;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_user_needHint !== i_ICacheBuffer__auto_out_a_bits_user_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_user_needHint g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_user_needHint, i_ICacheBuffer__auto_out_a_bits_user_needHint);
    end
    if (g_ICacheBuffer__auto_out_a_bits_user_needHint !== p_ICacheBuffer__auto_out_a_bits_user_needHint) t_ICacheBuffer__auto_out_a_bits_user_needHint = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_user_needHint = g_ICacheBuffer__auto_out_a_bits_user_needHint;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_mask !== i_ICacheBuffer__auto_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_mask g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_mask, i_ICacheBuffer__auto_out_a_bits_mask);
    end
    if (g_ICacheBuffer__auto_out_a_bits_mask !== p_ICacheBuffer__auto_out_a_bits_mask) t_ICacheBuffer__auto_out_a_bits_mask = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_mask = g_ICacheBuffer__auto_out_a_bits_mask;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_data !== i_ICacheBuffer__auto_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_data g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_data, i_ICacheBuffer__auto_out_a_bits_data);
    end
    if (g_ICacheBuffer__auto_out_a_bits_data !== p_ICacheBuffer__auto_out_a_bits_data) t_ICacheBuffer__auto_out_a_bits_data = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_data = g_ICacheBuffer__auto_out_a_bits_data;
    checks++;
    if (g_ICacheBuffer__auto_out_a_bits_corrupt !== i_ICacheBuffer__auto_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_a_bits_corrupt g=%h i=%h", cyc, g_ICacheBuffer__auto_out_a_bits_corrupt, i_ICacheBuffer__auto_out_a_bits_corrupt);
    end
    if (g_ICacheBuffer__auto_out_a_bits_corrupt !== p_ICacheBuffer__auto_out_a_bits_corrupt) t_ICacheBuffer__auto_out_a_bits_corrupt = 1'b1;
    p_ICacheBuffer__auto_out_a_bits_corrupt = g_ICacheBuffer__auto_out_a_bits_corrupt;
    checks++;
    if (g_ICacheBuffer__auto_out_d_ready !== i_ICacheBuffer__auto_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheBuffer.auto_out_d_ready g=%h i=%h", cyc, g_ICacheBuffer__auto_out_d_ready, i_ICacheBuffer__auto_out_d_ready);
    end
    if (g_ICacheBuffer__auto_out_d_ready !== p_ICacheBuffer__auto_out_d_ready) t_ICacheBuffer__auto_out_d_ready = 1'b1;
    p_ICacheBuffer__auto_out_d_ready = g_ICacheBuffer__auto_out_d_ready;
  endtask
  longint cov_ICacheBuffer_nodeOut_a_q_enq = 0;
  longint cov_ICacheBuffer_nodeOut_a_q_deq = 0;
  longint cov_ICacheBuffer_nodeOut_a_q_full_blocked = 0;
  longint cov_ICacheBuffer_nodeOut_a_q_1_enq = 0;
  longint cov_ICacheBuffer_nodeOut_a_q_1_deq = 0;
  longint cov_ICacheBuffer_nodeOut_a_q_1_full_blocked = 0;
  longint cov_ICacheBuffer_nodeIn_d_q_enq = 0;
  longint cov_ICacheBuffer_nodeIn_d_q_deq = 0;
  longint cov_ICacheBuffer_nodeIn_d_q_1_enq = 0;
  longint cov_ICacheBuffer_nodeIn_d_q_1_deq = 0;
  task automatic cover_ICacheBuffer();
    if (u_g_ICacheBuffer.nodeOut_a_q.do_enq) cov_ICacheBuffer_nodeOut_a_q_enq++;
    if (u_g_ICacheBuffer.nodeOut_a_q.do_deq) cov_ICacheBuffer_nodeOut_a_q_deq++;
    if (u_g_ICacheBuffer.nodeOut_a_q.full && u_g_ICacheBuffer.nodeOut_a_q.io_enq_valid) cov_ICacheBuffer_nodeOut_a_q_full_blocked++;
    if (u_g_ICacheBuffer.nodeOut_a_q_1.do_enq) cov_ICacheBuffer_nodeOut_a_q_1_enq++;
    if (u_g_ICacheBuffer.nodeOut_a_q_1.do_deq) cov_ICacheBuffer_nodeOut_a_q_1_deq++;
    if (u_g_ICacheBuffer.nodeOut_a_q_1.full && u_g_ICacheBuffer.nodeOut_a_q_1.io_enq_valid) cov_ICacheBuffer_nodeOut_a_q_1_full_blocked++;
    if (u_g_ICacheBuffer.nodeIn_d_q.do_enq) cov_ICacheBuffer_nodeIn_d_q_enq++;
    if (u_g_ICacheBuffer.nodeIn_d_q.do_deq) cov_ICacheBuffer_nodeIn_d_q_deq++;
    if (u_g_ICacheBuffer.nodeIn_d_q_1.do_enq) cov_ICacheBuffer_nodeIn_d_q_1_enq++;
    if (u_g_ICacheBuffer.nodeIn_d_q_1.do_deq) cov_ICacheBuffer_nodeIn_d_q_1_deq++;
  endtask
  task automatic preinit_ICacheBuffer();
  endtask
  task automatic sync_ICacheBuffer();
    u_i_ICacheBuffer.nodeOut_a_q.ram_ext.Memory = u_g_ICacheBuffer.nodeOut_a_q.ram_ext.Memory;
    u_i_ICacheBuffer.nodeOut_a_q_1.ram_ext.Memory = u_g_ICacheBuffer.nodeOut_a_q_1.ram_ext.Memory;
    u_i_ICacheBuffer.nodeIn_d_q.ram_ext.Memory = u_g_ICacheBuffer.nodeIn_d_q.ram_ext.Memory;
    u_i_ICacheBuffer.nodeIn_d_q_1.ram_ext.Memory = u_g_ICacheBuffer.nodeIn_d_q_1.ram_ext.Memory;
  endtask

  // ======================= InstrUncacheBuffer =======================
  logic InstrUncacheBuffer__auto_in_a_valid;
  logic [47:0] InstrUncacheBuffer__auto_in_a_bits_address;
  logic InstrUncacheBuffer__auto_in_a_bits_user_memPageType_NC;
  logic InstrUncacheBuffer__auto_in_a_bits_user_memBackType_MM;
  logic InstrUncacheBuffer__auto_out_a_ready;
  logic InstrUncacheBuffer__auto_out_d_valid;
  logic [3:0] InstrUncacheBuffer__auto_out_d_bits_opcode;
  logic [1:0] InstrUncacheBuffer__auto_out_d_bits_param;
  logic [1:0] InstrUncacheBuffer__auto_out_d_bits_size;
  logic InstrUncacheBuffer__auto_out_d_bits_source;
  logic InstrUncacheBuffer__auto_out_d_bits_sink;
  logic InstrUncacheBuffer__auto_out_d_bits_denied;
  logic [63:0] InstrUncacheBuffer__auto_out_d_bits_data;
  logic InstrUncacheBuffer__auto_out_d_bits_corrupt;
  wire  g_InstrUncacheBuffer__auto_in_a_ready;
  wire  i_InstrUncacheBuffer__auto_in_a_ready;
  logic p_InstrUncacheBuffer__auto_in_a_ready;
  bit   t_InstrUncacheBuffer__auto_in_a_ready;
  wire  g_InstrUncacheBuffer__auto_in_d_valid;
  wire  i_InstrUncacheBuffer__auto_in_d_valid;
  logic p_InstrUncacheBuffer__auto_in_d_valid;
  bit   t_InstrUncacheBuffer__auto_in_d_valid;
  wire  g_InstrUncacheBuffer__auto_in_d_bits_source;
  wire  i_InstrUncacheBuffer__auto_in_d_bits_source;
  logic p_InstrUncacheBuffer__auto_in_d_bits_source;
  bit   t_InstrUncacheBuffer__auto_in_d_bits_source;
  wire  [63:0] g_InstrUncacheBuffer__auto_in_d_bits_data;
  wire  [63:0] i_InstrUncacheBuffer__auto_in_d_bits_data;
  logic [63:0] p_InstrUncacheBuffer__auto_in_d_bits_data;
  bit   t_InstrUncacheBuffer__auto_in_d_bits_data;
  wire  g_InstrUncacheBuffer__auto_in_d_bits_corrupt;
  wire  i_InstrUncacheBuffer__auto_in_d_bits_corrupt;
  logic p_InstrUncacheBuffer__auto_in_d_bits_corrupt;
  bit   t_InstrUncacheBuffer__auto_in_d_bits_corrupt;
  wire  g_InstrUncacheBuffer__auto_out_a_valid;
  wire  i_InstrUncacheBuffer__auto_out_a_valid;
  logic p_InstrUncacheBuffer__auto_out_a_valid;
  bit   t_InstrUncacheBuffer__auto_out_a_valid;
  wire  [2:0] g_InstrUncacheBuffer__auto_out_a_bits_param;
  wire  [2:0] i_InstrUncacheBuffer__auto_out_a_bits_param;
  logic [2:0] p_InstrUncacheBuffer__auto_out_a_bits_param;
  bit   t_InstrUncacheBuffer__auto_out_a_bits_param;
  wire  [47:0] g_InstrUncacheBuffer__auto_out_a_bits_address;
  wire  [47:0] i_InstrUncacheBuffer__auto_out_a_bits_address;
  logic [47:0] p_InstrUncacheBuffer__auto_out_a_bits_address;
  bit   t_InstrUncacheBuffer__auto_out_a_bits_address;
  wire  g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC;
  wire  i_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC;
  logic p_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC;
  bit   t_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC;
  wire  g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM;
  wire  i_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM;
  logic p_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM;
  bit   t_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM;
  wire  g_InstrUncacheBuffer__auto_out_a_bits_corrupt;
  wire  i_InstrUncacheBuffer__auto_out_a_bits_corrupt;
  logic p_InstrUncacheBuffer__auto_out_a_bits_corrupt;
  bit   t_InstrUncacheBuffer__auto_out_a_bits_corrupt;
  wire  g_InstrUncacheBuffer__auto_out_d_ready;
  wire  i_InstrUncacheBuffer__auto_out_d_ready;
  logic p_InstrUncacheBuffer__auto_out_d_ready;
  bit   t_InstrUncacheBuffer__auto_out_d_ready;
  InstrUncacheBuffer u_g_InstrUncacheBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (g_InstrUncacheBuffer__auto_in_a_ready),
    .auto_in_a_valid (InstrUncacheBuffer__auto_in_a_valid),
    .auto_in_a_bits_address (InstrUncacheBuffer__auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC (InstrUncacheBuffer__auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM (InstrUncacheBuffer__auto_in_a_bits_user_memBackType_MM),
    .auto_in_d_valid (g_InstrUncacheBuffer__auto_in_d_valid),
    .auto_in_d_bits_source (g_InstrUncacheBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_data (g_InstrUncacheBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (g_InstrUncacheBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (InstrUncacheBuffer__auto_out_a_ready),
    .auto_out_a_valid (g_InstrUncacheBuffer__auto_out_a_valid),
    .auto_out_a_bits_param (g_InstrUncacheBuffer__auto_out_a_bits_param),
    .auto_out_a_bits_address (g_InstrUncacheBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC (g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM (g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_corrupt (g_InstrUncacheBuffer__auto_out_a_bits_corrupt),
    .auto_out_d_ready (g_InstrUncacheBuffer__auto_out_d_ready),
    .auto_out_d_valid (InstrUncacheBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (InstrUncacheBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_param (InstrUncacheBuffer__auto_out_d_bits_param),
    .auto_out_d_bits_size (InstrUncacheBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (InstrUncacheBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_sink (InstrUncacheBuffer__auto_out_d_bits_sink),
    .auto_out_d_bits_denied (InstrUncacheBuffer__auto_out_d_bits_denied),
    .auto_out_d_bits_data (InstrUncacheBuffer__auto_out_d_bits_data),
    .auto_out_d_bits_corrupt (InstrUncacheBuffer__auto_out_d_bits_corrupt)
  );
  InstrUncacheBuffer_xs u_i_InstrUncacheBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (i_InstrUncacheBuffer__auto_in_a_ready),
    .auto_in_a_valid (InstrUncacheBuffer__auto_in_a_valid),
    .auto_in_a_bits_address (InstrUncacheBuffer__auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC (InstrUncacheBuffer__auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM (InstrUncacheBuffer__auto_in_a_bits_user_memBackType_MM),
    .auto_in_d_valid (i_InstrUncacheBuffer__auto_in_d_valid),
    .auto_in_d_bits_source (i_InstrUncacheBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_data (i_InstrUncacheBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (i_InstrUncacheBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (InstrUncacheBuffer__auto_out_a_ready),
    .auto_out_a_valid (i_InstrUncacheBuffer__auto_out_a_valid),
    .auto_out_a_bits_param (i_InstrUncacheBuffer__auto_out_a_bits_param),
    .auto_out_a_bits_address (i_InstrUncacheBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC (i_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM (i_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_corrupt (i_InstrUncacheBuffer__auto_out_a_bits_corrupt),
    .auto_out_d_ready (i_InstrUncacheBuffer__auto_out_d_ready),
    .auto_out_d_valid (InstrUncacheBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (InstrUncacheBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_param (InstrUncacheBuffer__auto_out_d_bits_param),
    .auto_out_d_bits_size (InstrUncacheBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (InstrUncacheBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_sink (InstrUncacheBuffer__auto_out_d_bits_sink),
    .auto_out_d_bits_denied (InstrUncacheBuffer__auto_out_d_bits_denied),
    .auto_out_d_bits_data (InstrUncacheBuffer__auto_out_d_bits_data),
    .auto_out_d_bits_corrupt (InstrUncacheBuffer__auto_out_d_bits_corrupt)
  );
  task automatic drive_InstrUncacheBuffer();
    InstrUncacheBuffer__auto_in_a_valid = $urandom % 2;
    InstrUncacheBuffer__auto_in_a_bits_address = rnd(48);
    InstrUncacheBuffer__auto_in_a_bits_user_memPageType_NC = $urandom % 2;
    InstrUncacheBuffer__auto_in_a_bits_user_memBackType_MM = $urandom % 2;
    InstrUncacheBuffer__auto_out_a_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    InstrUncacheBuffer__auto_out_d_valid = $urandom % 2;
    InstrUncacheBuffer__auto_out_d_bits_opcode = rnd(4);
    InstrUncacheBuffer__auto_out_d_bits_param = rnd(2);
    InstrUncacheBuffer__auto_out_d_bits_size = rnd(2);
    InstrUncacheBuffer__auto_out_d_bits_source = $urandom % 2;
    InstrUncacheBuffer__auto_out_d_bits_sink = $urandom % 2;
    InstrUncacheBuffer__auto_out_d_bits_denied = $urandom % 2;
    InstrUncacheBuffer__auto_out_d_bits_data = rnd(64);
    InstrUncacheBuffer__auto_out_d_bits_corrupt = $urandom % 2;
  endtask
  task automatic check_InstrUncacheBuffer();
    checks++;
    if (g_InstrUncacheBuffer__auto_in_a_ready !== i_InstrUncacheBuffer__auto_in_a_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_in_a_ready g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_in_a_ready, i_InstrUncacheBuffer__auto_in_a_ready);
    end
    if (g_InstrUncacheBuffer__auto_in_a_ready !== p_InstrUncacheBuffer__auto_in_a_ready) t_InstrUncacheBuffer__auto_in_a_ready = 1'b1;
    p_InstrUncacheBuffer__auto_in_a_ready = g_InstrUncacheBuffer__auto_in_a_ready;
    checks++;
    if (g_InstrUncacheBuffer__auto_in_d_valid !== i_InstrUncacheBuffer__auto_in_d_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_in_d_valid g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_in_d_valid, i_InstrUncacheBuffer__auto_in_d_valid);
    end
    if (g_InstrUncacheBuffer__auto_in_d_valid !== p_InstrUncacheBuffer__auto_in_d_valid) t_InstrUncacheBuffer__auto_in_d_valid = 1'b1;
    p_InstrUncacheBuffer__auto_in_d_valid = g_InstrUncacheBuffer__auto_in_d_valid;
    checks++;
    if (g_InstrUncacheBuffer__auto_in_d_bits_source !== i_InstrUncacheBuffer__auto_in_d_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_in_d_bits_source g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_in_d_bits_source, i_InstrUncacheBuffer__auto_in_d_bits_source);
    end
    if (g_InstrUncacheBuffer__auto_in_d_bits_source !== p_InstrUncacheBuffer__auto_in_d_bits_source) t_InstrUncacheBuffer__auto_in_d_bits_source = 1'b1;
    p_InstrUncacheBuffer__auto_in_d_bits_source = g_InstrUncacheBuffer__auto_in_d_bits_source;
    checks++;
    if (g_InstrUncacheBuffer__auto_in_d_bits_data !== i_InstrUncacheBuffer__auto_in_d_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_in_d_bits_data g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_in_d_bits_data, i_InstrUncacheBuffer__auto_in_d_bits_data);
    end
    if (g_InstrUncacheBuffer__auto_in_d_bits_data !== p_InstrUncacheBuffer__auto_in_d_bits_data) t_InstrUncacheBuffer__auto_in_d_bits_data = 1'b1;
    p_InstrUncacheBuffer__auto_in_d_bits_data = g_InstrUncacheBuffer__auto_in_d_bits_data;
    checks++;
    if (g_InstrUncacheBuffer__auto_in_d_bits_corrupt !== i_InstrUncacheBuffer__auto_in_d_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_in_d_bits_corrupt g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_in_d_bits_corrupt, i_InstrUncacheBuffer__auto_in_d_bits_corrupt);
    end
    if (g_InstrUncacheBuffer__auto_in_d_bits_corrupt !== p_InstrUncacheBuffer__auto_in_d_bits_corrupt) t_InstrUncacheBuffer__auto_in_d_bits_corrupt = 1'b1;
    p_InstrUncacheBuffer__auto_in_d_bits_corrupt = g_InstrUncacheBuffer__auto_in_d_bits_corrupt;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_valid !== i_InstrUncacheBuffer__auto_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_valid g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_valid, i_InstrUncacheBuffer__auto_out_a_valid);
    end
    if (g_InstrUncacheBuffer__auto_out_a_valid !== p_InstrUncacheBuffer__auto_out_a_valid) t_InstrUncacheBuffer__auto_out_a_valid = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_valid = g_InstrUncacheBuffer__auto_out_a_valid;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_bits_param !== i_InstrUncacheBuffer__auto_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_bits_param g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_bits_param, i_InstrUncacheBuffer__auto_out_a_bits_param);
    end
    if (g_InstrUncacheBuffer__auto_out_a_bits_param !== p_InstrUncacheBuffer__auto_out_a_bits_param) t_InstrUncacheBuffer__auto_out_a_bits_param = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_bits_param = g_InstrUncacheBuffer__auto_out_a_bits_param;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_bits_address !== i_InstrUncacheBuffer__auto_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_bits_address g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_bits_address, i_InstrUncacheBuffer__auto_out_a_bits_address);
    end
    if (g_InstrUncacheBuffer__auto_out_a_bits_address !== p_InstrUncacheBuffer__auto_out_a_bits_address) t_InstrUncacheBuffer__auto_out_a_bits_address = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_bits_address = g_InstrUncacheBuffer__auto_out_a_bits_address;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC !== i_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_bits_user_memPageType_NC g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC, i_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC);
    end
    if (g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC !== p_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC) t_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC = g_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM !== i_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_bits_user_memBackType_MM g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM, i_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM);
    end
    if (g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM !== p_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM) t_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM = g_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_a_bits_corrupt !== i_InstrUncacheBuffer__auto_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_a_bits_corrupt g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_a_bits_corrupt, i_InstrUncacheBuffer__auto_out_a_bits_corrupt);
    end
    if (g_InstrUncacheBuffer__auto_out_a_bits_corrupt !== p_InstrUncacheBuffer__auto_out_a_bits_corrupt) t_InstrUncacheBuffer__auto_out_a_bits_corrupt = 1'b1;
    p_InstrUncacheBuffer__auto_out_a_bits_corrupt = g_InstrUncacheBuffer__auto_out_a_bits_corrupt;
    checks++;
    if (g_InstrUncacheBuffer__auto_out_d_ready !== i_InstrUncacheBuffer__auto_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH InstrUncacheBuffer.auto_out_d_ready g=%h i=%h", cyc, g_InstrUncacheBuffer__auto_out_d_ready, i_InstrUncacheBuffer__auto_out_d_ready);
    end
    if (g_InstrUncacheBuffer__auto_out_d_ready !== p_InstrUncacheBuffer__auto_out_d_ready) t_InstrUncacheBuffer__auto_out_d_ready = 1'b1;
    p_InstrUncacheBuffer__auto_out_d_ready = g_InstrUncacheBuffer__auto_out_d_ready;
  endtask
  longint cov_InstrUncacheBuffer_nodeOut_a_q_enq = 0;
  longint cov_InstrUncacheBuffer_nodeOut_a_q_deq = 0;
  longint cov_InstrUncacheBuffer_nodeOut_a_q_full_blocked = 0;
  longint cov_InstrUncacheBuffer_nodeOut_a_q_1_enq = 0;
  longint cov_InstrUncacheBuffer_nodeOut_a_q_1_deq = 0;
  longint cov_InstrUncacheBuffer_nodeOut_a_q_1_full_blocked = 0;
  longint cov_InstrUncacheBuffer_nodeIn_d_q_enq = 0;
  longint cov_InstrUncacheBuffer_nodeIn_d_q_deq = 0;
  longint cov_InstrUncacheBuffer_nodeIn_d_q_1_enq = 0;
  longint cov_InstrUncacheBuffer_nodeIn_d_q_1_deq = 0;
  task automatic cover_InstrUncacheBuffer();
    if (u_g_InstrUncacheBuffer.nodeOut_a_q.do_enq) cov_InstrUncacheBuffer_nodeOut_a_q_enq++;
    if (u_g_InstrUncacheBuffer.nodeOut_a_q.do_deq) cov_InstrUncacheBuffer_nodeOut_a_q_deq++;
    if (u_g_InstrUncacheBuffer.nodeOut_a_q.full && u_g_InstrUncacheBuffer.nodeOut_a_q.io_enq_valid) cov_InstrUncacheBuffer_nodeOut_a_q_full_blocked++;
    if (u_g_InstrUncacheBuffer.nodeOut_a_q_1.do_enq) cov_InstrUncacheBuffer_nodeOut_a_q_1_enq++;
    if (u_g_InstrUncacheBuffer.nodeOut_a_q_1.do_deq) cov_InstrUncacheBuffer_nodeOut_a_q_1_deq++;
    if (u_g_InstrUncacheBuffer.nodeOut_a_q_1.full && u_g_InstrUncacheBuffer.nodeOut_a_q_1.io_enq_valid) cov_InstrUncacheBuffer_nodeOut_a_q_1_full_blocked++;
    if (u_g_InstrUncacheBuffer.nodeIn_d_q.do_enq) cov_InstrUncacheBuffer_nodeIn_d_q_enq++;
    if (u_g_InstrUncacheBuffer.nodeIn_d_q.do_deq) cov_InstrUncacheBuffer_nodeIn_d_q_deq++;
    if (u_g_InstrUncacheBuffer.nodeIn_d_q_1.do_enq) cov_InstrUncacheBuffer_nodeIn_d_q_1_enq++;
    if (u_g_InstrUncacheBuffer.nodeIn_d_q_1.do_deq) cov_InstrUncacheBuffer_nodeIn_d_q_1_deq++;
  endtask
  task automatic preinit_InstrUncacheBuffer();
  endtask
  task automatic sync_InstrUncacheBuffer();
    u_i_InstrUncacheBuffer.nodeOut_a_q.ram_ext.Memory = u_g_InstrUncacheBuffer.nodeOut_a_q.ram_ext.Memory;
    u_i_InstrUncacheBuffer.nodeOut_a_q_1.ram_ext.Memory = u_g_InstrUncacheBuffer.nodeOut_a_q_1.ram_ext.Memory;
    u_i_InstrUncacheBuffer.nodeIn_d_q.ram_ext.Memory = u_g_InstrUncacheBuffer.nodeIn_d_q.ram_ext.Memory;
    u_i_InstrUncacheBuffer.nodeIn_d_q_1.ram_ext.Memory = u_g_InstrUncacheBuffer.nodeIn_d_q_1.ram_ext.Memory;
  endtask

  // ======================= ICacheCtrlBuffer =======================
  logic ICacheCtrlBuffer__auto_in_a_valid;
  logic [3:0] ICacheCtrlBuffer__auto_in_a_bits_opcode;
  logic [2:0] ICacheCtrlBuffer__auto_in_a_bits_param;
  logic [1:0] ICacheCtrlBuffer__auto_in_a_bits_size;
  logic [4:0] ICacheCtrlBuffer__auto_in_a_bits_source;
  logic [29:0] ICacheCtrlBuffer__auto_in_a_bits_address;
  logic [7:0] ICacheCtrlBuffer__auto_in_a_bits_mask;
  logic [63:0] ICacheCtrlBuffer__auto_in_a_bits_data;
  logic ICacheCtrlBuffer__auto_in_a_bits_corrupt;
  logic ICacheCtrlBuffer__auto_in_d_ready;
  logic ICacheCtrlBuffer__auto_out_a_ready;
  logic ICacheCtrlBuffer__auto_out_d_valid;
  logic [3:0] ICacheCtrlBuffer__auto_out_d_bits_opcode;
  logic [1:0] ICacheCtrlBuffer__auto_out_d_bits_size;
  logic [4:0] ICacheCtrlBuffer__auto_out_d_bits_source;
  logic [63:0] ICacheCtrlBuffer__auto_out_d_bits_data;
  wire  g_ICacheCtrlBuffer__auto_in_a_ready;
  wire  i_ICacheCtrlBuffer__auto_in_a_ready;
  logic p_ICacheCtrlBuffer__auto_in_a_ready;
  bit   t_ICacheCtrlBuffer__auto_in_a_ready;
  wire  g_ICacheCtrlBuffer__auto_in_d_valid;
  wire  i_ICacheCtrlBuffer__auto_in_d_valid;
  logic p_ICacheCtrlBuffer__auto_in_d_valid;
  bit   t_ICacheCtrlBuffer__auto_in_d_valid;
  wire  [3:0] g_ICacheCtrlBuffer__auto_in_d_bits_opcode;
  wire  [3:0] i_ICacheCtrlBuffer__auto_in_d_bits_opcode;
  logic [3:0] p_ICacheCtrlBuffer__auto_in_d_bits_opcode;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_opcode;
  wire  [1:0] g_ICacheCtrlBuffer__auto_in_d_bits_param;
  wire  [1:0] i_ICacheCtrlBuffer__auto_in_d_bits_param;
  logic [1:0] p_ICacheCtrlBuffer__auto_in_d_bits_param;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_param;
  wire  [1:0] g_ICacheCtrlBuffer__auto_in_d_bits_size;
  wire  [1:0] i_ICacheCtrlBuffer__auto_in_d_bits_size;
  logic [1:0] p_ICacheCtrlBuffer__auto_in_d_bits_size;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_size;
  wire  [4:0] g_ICacheCtrlBuffer__auto_in_d_bits_source;
  wire  [4:0] i_ICacheCtrlBuffer__auto_in_d_bits_source;
  logic [4:0] p_ICacheCtrlBuffer__auto_in_d_bits_source;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_source;
  wire  g_ICacheCtrlBuffer__auto_in_d_bits_sink;
  wire  i_ICacheCtrlBuffer__auto_in_d_bits_sink;
  logic p_ICacheCtrlBuffer__auto_in_d_bits_sink;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_sink;
  wire  g_ICacheCtrlBuffer__auto_in_d_bits_denied;
  wire  i_ICacheCtrlBuffer__auto_in_d_bits_denied;
  logic p_ICacheCtrlBuffer__auto_in_d_bits_denied;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_denied;
  wire  [63:0] g_ICacheCtrlBuffer__auto_in_d_bits_data;
  wire  [63:0] i_ICacheCtrlBuffer__auto_in_d_bits_data;
  logic [63:0] p_ICacheCtrlBuffer__auto_in_d_bits_data;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_data;
  wire  g_ICacheCtrlBuffer__auto_in_d_bits_corrupt;
  wire  i_ICacheCtrlBuffer__auto_in_d_bits_corrupt;
  logic p_ICacheCtrlBuffer__auto_in_d_bits_corrupt;
  bit   t_ICacheCtrlBuffer__auto_in_d_bits_corrupt;
  wire  g_ICacheCtrlBuffer__auto_out_a_valid;
  wire  i_ICacheCtrlBuffer__auto_out_a_valid;
  logic p_ICacheCtrlBuffer__auto_out_a_valid;
  bit   t_ICacheCtrlBuffer__auto_out_a_valid;
  wire  [3:0] g_ICacheCtrlBuffer__auto_out_a_bits_opcode;
  wire  [3:0] i_ICacheCtrlBuffer__auto_out_a_bits_opcode;
  logic [3:0] p_ICacheCtrlBuffer__auto_out_a_bits_opcode;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_opcode;
  wire  [1:0] g_ICacheCtrlBuffer__auto_out_a_bits_size;
  wire  [1:0] i_ICacheCtrlBuffer__auto_out_a_bits_size;
  logic [1:0] p_ICacheCtrlBuffer__auto_out_a_bits_size;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_size;
  wire  [4:0] g_ICacheCtrlBuffer__auto_out_a_bits_source;
  wire  [4:0] i_ICacheCtrlBuffer__auto_out_a_bits_source;
  logic [4:0] p_ICacheCtrlBuffer__auto_out_a_bits_source;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_source;
  wire  [29:0] g_ICacheCtrlBuffer__auto_out_a_bits_address;
  wire  [29:0] i_ICacheCtrlBuffer__auto_out_a_bits_address;
  logic [29:0] p_ICacheCtrlBuffer__auto_out_a_bits_address;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_address;
  wire  [7:0] g_ICacheCtrlBuffer__auto_out_a_bits_mask;
  wire  [7:0] i_ICacheCtrlBuffer__auto_out_a_bits_mask;
  logic [7:0] p_ICacheCtrlBuffer__auto_out_a_bits_mask;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_mask;
  wire  [63:0] g_ICacheCtrlBuffer__auto_out_a_bits_data;
  wire  [63:0] i_ICacheCtrlBuffer__auto_out_a_bits_data;
  logic [63:0] p_ICacheCtrlBuffer__auto_out_a_bits_data;
  bit   t_ICacheCtrlBuffer__auto_out_a_bits_data;
  wire  g_ICacheCtrlBuffer__auto_out_d_ready;
  wire  i_ICacheCtrlBuffer__auto_out_d_ready;
  logic p_ICacheCtrlBuffer__auto_out_d_ready;
  bit   t_ICacheCtrlBuffer__auto_out_d_ready;
  ICacheCtrlBuffer u_g_ICacheCtrlBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (g_ICacheCtrlBuffer__auto_in_a_ready),
    .auto_in_a_valid (ICacheCtrlBuffer__auto_in_a_valid),
    .auto_in_a_bits_opcode (ICacheCtrlBuffer__auto_in_a_bits_opcode),
    .auto_in_a_bits_param (ICacheCtrlBuffer__auto_in_a_bits_param),
    .auto_in_a_bits_size (ICacheCtrlBuffer__auto_in_a_bits_size),
    .auto_in_a_bits_source (ICacheCtrlBuffer__auto_in_a_bits_source),
    .auto_in_a_bits_address (ICacheCtrlBuffer__auto_in_a_bits_address),
    .auto_in_a_bits_mask (ICacheCtrlBuffer__auto_in_a_bits_mask),
    .auto_in_a_bits_data (ICacheCtrlBuffer__auto_in_a_bits_data),
    .auto_in_a_bits_corrupt (ICacheCtrlBuffer__auto_in_a_bits_corrupt),
    .auto_in_d_ready (ICacheCtrlBuffer__auto_in_d_ready),
    .auto_in_d_valid (g_ICacheCtrlBuffer__auto_in_d_valid),
    .auto_in_d_bits_opcode (g_ICacheCtrlBuffer__auto_in_d_bits_opcode),
    .auto_in_d_bits_param (g_ICacheCtrlBuffer__auto_in_d_bits_param),
    .auto_in_d_bits_size (g_ICacheCtrlBuffer__auto_in_d_bits_size),
    .auto_in_d_bits_source (g_ICacheCtrlBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_sink (g_ICacheCtrlBuffer__auto_in_d_bits_sink),
    .auto_in_d_bits_denied (g_ICacheCtrlBuffer__auto_in_d_bits_denied),
    .auto_in_d_bits_data (g_ICacheCtrlBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (g_ICacheCtrlBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (ICacheCtrlBuffer__auto_out_a_ready),
    .auto_out_a_valid (g_ICacheCtrlBuffer__auto_out_a_valid),
    .auto_out_a_bits_opcode (g_ICacheCtrlBuffer__auto_out_a_bits_opcode),
    .auto_out_a_bits_size (g_ICacheCtrlBuffer__auto_out_a_bits_size),
    .auto_out_a_bits_source (g_ICacheCtrlBuffer__auto_out_a_bits_source),
    .auto_out_a_bits_address (g_ICacheCtrlBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_mask (g_ICacheCtrlBuffer__auto_out_a_bits_mask),
    .auto_out_a_bits_data (g_ICacheCtrlBuffer__auto_out_a_bits_data),
    .auto_out_d_ready (g_ICacheCtrlBuffer__auto_out_d_ready),
    .auto_out_d_valid (ICacheCtrlBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (ICacheCtrlBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_size (ICacheCtrlBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (ICacheCtrlBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_data (ICacheCtrlBuffer__auto_out_d_bits_data)
  );
  ICacheCtrlBuffer_xs u_i_ICacheCtrlBuffer (
    .clock (clock),
    .reset (reset),
    .auto_in_a_ready (i_ICacheCtrlBuffer__auto_in_a_ready),
    .auto_in_a_valid (ICacheCtrlBuffer__auto_in_a_valid),
    .auto_in_a_bits_opcode (ICacheCtrlBuffer__auto_in_a_bits_opcode),
    .auto_in_a_bits_param (ICacheCtrlBuffer__auto_in_a_bits_param),
    .auto_in_a_bits_size (ICacheCtrlBuffer__auto_in_a_bits_size),
    .auto_in_a_bits_source (ICacheCtrlBuffer__auto_in_a_bits_source),
    .auto_in_a_bits_address (ICacheCtrlBuffer__auto_in_a_bits_address),
    .auto_in_a_bits_mask (ICacheCtrlBuffer__auto_in_a_bits_mask),
    .auto_in_a_bits_data (ICacheCtrlBuffer__auto_in_a_bits_data),
    .auto_in_a_bits_corrupt (ICacheCtrlBuffer__auto_in_a_bits_corrupt),
    .auto_in_d_ready (ICacheCtrlBuffer__auto_in_d_ready),
    .auto_in_d_valid (i_ICacheCtrlBuffer__auto_in_d_valid),
    .auto_in_d_bits_opcode (i_ICacheCtrlBuffer__auto_in_d_bits_opcode),
    .auto_in_d_bits_param (i_ICacheCtrlBuffer__auto_in_d_bits_param),
    .auto_in_d_bits_size (i_ICacheCtrlBuffer__auto_in_d_bits_size),
    .auto_in_d_bits_source (i_ICacheCtrlBuffer__auto_in_d_bits_source),
    .auto_in_d_bits_sink (i_ICacheCtrlBuffer__auto_in_d_bits_sink),
    .auto_in_d_bits_denied (i_ICacheCtrlBuffer__auto_in_d_bits_denied),
    .auto_in_d_bits_data (i_ICacheCtrlBuffer__auto_in_d_bits_data),
    .auto_in_d_bits_corrupt (i_ICacheCtrlBuffer__auto_in_d_bits_corrupt),
    .auto_out_a_ready (ICacheCtrlBuffer__auto_out_a_ready),
    .auto_out_a_valid (i_ICacheCtrlBuffer__auto_out_a_valid),
    .auto_out_a_bits_opcode (i_ICacheCtrlBuffer__auto_out_a_bits_opcode),
    .auto_out_a_bits_size (i_ICacheCtrlBuffer__auto_out_a_bits_size),
    .auto_out_a_bits_source (i_ICacheCtrlBuffer__auto_out_a_bits_source),
    .auto_out_a_bits_address (i_ICacheCtrlBuffer__auto_out_a_bits_address),
    .auto_out_a_bits_mask (i_ICacheCtrlBuffer__auto_out_a_bits_mask),
    .auto_out_a_bits_data (i_ICacheCtrlBuffer__auto_out_a_bits_data),
    .auto_out_d_ready (i_ICacheCtrlBuffer__auto_out_d_ready),
    .auto_out_d_valid (ICacheCtrlBuffer__auto_out_d_valid),
    .auto_out_d_bits_opcode (ICacheCtrlBuffer__auto_out_d_bits_opcode),
    .auto_out_d_bits_size (ICacheCtrlBuffer__auto_out_d_bits_size),
    .auto_out_d_bits_source (ICacheCtrlBuffer__auto_out_d_bits_source),
    .auto_out_d_bits_data (ICacheCtrlBuffer__auto_out_d_bits_data)
  );
  task automatic drive_ICacheCtrlBuffer();
    ICacheCtrlBuffer__auto_in_a_valid = $urandom % 2;
    ICacheCtrlBuffer__auto_in_a_bits_opcode = rnd(4);
    ICacheCtrlBuffer__auto_in_a_bits_param = rnd(3);
    ICacheCtrlBuffer__auto_in_a_bits_size = rnd(2);
    ICacheCtrlBuffer__auto_in_a_bits_source = rnd(5);
    ICacheCtrlBuffer__auto_in_a_bits_address = rnd(30);
    ICacheCtrlBuffer__auto_in_a_bits_mask = rnd(8);
    ICacheCtrlBuffer__auto_in_a_bits_data = rnd(64);
    ICacheCtrlBuffer__auto_in_a_bits_corrupt = $urandom % 2;
    ICacheCtrlBuffer__auto_in_d_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    ICacheCtrlBuffer__auto_out_a_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    ICacheCtrlBuffer__auto_out_d_valid = $urandom % 2;
    ICacheCtrlBuffer__auto_out_d_bits_opcode = rnd(4);
    ICacheCtrlBuffer__auto_out_d_bits_size = rnd(2);
    ICacheCtrlBuffer__auto_out_d_bits_source = rnd(5);
    ICacheCtrlBuffer__auto_out_d_bits_data = rnd(64);
  endtask
  task automatic check_ICacheCtrlBuffer();
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_a_ready !== i_ICacheCtrlBuffer__auto_in_a_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_a_ready g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_a_ready, i_ICacheCtrlBuffer__auto_in_a_ready);
    end
    if (g_ICacheCtrlBuffer__auto_in_a_ready !== p_ICacheCtrlBuffer__auto_in_a_ready) t_ICacheCtrlBuffer__auto_in_a_ready = 1'b1;
    p_ICacheCtrlBuffer__auto_in_a_ready = g_ICacheCtrlBuffer__auto_in_a_ready;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_valid !== i_ICacheCtrlBuffer__auto_in_d_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_valid g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_valid, i_ICacheCtrlBuffer__auto_in_d_valid);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_valid !== p_ICacheCtrlBuffer__auto_in_d_valid) t_ICacheCtrlBuffer__auto_in_d_valid = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_valid = g_ICacheCtrlBuffer__auto_in_d_valid;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_opcode !== i_ICacheCtrlBuffer__auto_in_d_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_opcode g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_opcode, i_ICacheCtrlBuffer__auto_in_d_bits_opcode);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_opcode !== p_ICacheCtrlBuffer__auto_in_d_bits_opcode) t_ICacheCtrlBuffer__auto_in_d_bits_opcode = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_opcode = g_ICacheCtrlBuffer__auto_in_d_bits_opcode;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_param !== i_ICacheCtrlBuffer__auto_in_d_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_param g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_param, i_ICacheCtrlBuffer__auto_in_d_bits_param);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_param !== p_ICacheCtrlBuffer__auto_in_d_bits_param) t_ICacheCtrlBuffer__auto_in_d_bits_param = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_param = g_ICacheCtrlBuffer__auto_in_d_bits_param;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_size !== i_ICacheCtrlBuffer__auto_in_d_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_size g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_size, i_ICacheCtrlBuffer__auto_in_d_bits_size);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_size !== p_ICacheCtrlBuffer__auto_in_d_bits_size) t_ICacheCtrlBuffer__auto_in_d_bits_size = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_size = g_ICacheCtrlBuffer__auto_in_d_bits_size;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_source !== i_ICacheCtrlBuffer__auto_in_d_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_source g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_source, i_ICacheCtrlBuffer__auto_in_d_bits_source);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_source !== p_ICacheCtrlBuffer__auto_in_d_bits_source) t_ICacheCtrlBuffer__auto_in_d_bits_source = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_source = g_ICacheCtrlBuffer__auto_in_d_bits_source;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_sink !== i_ICacheCtrlBuffer__auto_in_d_bits_sink) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_sink g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_sink, i_ICacheCtrlBuffer__auto_in_d_bits_sink);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_sink !== p_ICacheCtrlBuffer__auto_in_d_bits_sink) t_ICacheCtrlBuffer__auto_in_d_bits_sink = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_sink = g_ICacheCtrlBuffer__auto_in_d_bits_sink;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_denied !== i_ICacheCtrlBuffer__auto_in_d_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_denied g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_denied, i_ICacheCtrlBuffer__auto_in_d_bits_denied);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_denied !== p_ICacheCtrlBuffer__auto_in_d_bits_denied) t_ICacheCtrlBuffer__auto_in_d_bits_denied = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_denied = g_ICacheCtrlBuffer__auto_in_d_bits_denied;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_data !== i_ICacheCtrlBuffer__auto_in_d_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_data g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_data, i_ICacheCtrlBuffer__auto_in_d_bits_data);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_data !== p_ICacheCtrlBuffer__auto_in_d_bits_data) t_ICacheCtrlBuffer__auto_in_d_bits_data = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_data = g_ICacheCtrlBuffer__auto_in_d_bits_data;
    checks++;
    if (g_ICacheCtrlBuffer__auto_in_d_bits_corrupt !== i_ICacheCtrlBuffer__auto_in_d_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_in_d_bits_corrupt g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_in_d_bits_corrupt, i_ICacheCtrlBuffer__auto_in_d_bits_corrupt);
    end
    if (g_ICacheCtrlBuffer__auto_in_d_bits_corrupt !== p_ICacheCtrlBuffer__auto_in_d_bits_corrupt) t_ICacheCtrlBuffer__auto_in_d_bits_corrupt = 1'b1;
    p_ICacheCtrlBuffer__auto_in_d_bits_corrupt = g_ICacheCtrlBuffer__auto_in_d_bits_corrupt;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_valid !== i_ICacheCtrlBuffer__auto_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_valid g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_valid, i_ICacheCtrlBuffer__auto_out_a_valid);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_valid !== p_ICacheCtrlBuffer__auto_out_a_valid) t_ICacheCtrlBuffer__auto_out_a_valid = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_valid = g_ICacheCtrlBuffer__auto_out_a_valid;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_opcode !== i_ICacheCtrlBuffer__auto_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_opcode g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_opcode, i_ICacheCtrlBuffer__auto_out_a_bits_opcode);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_opcode !== p_ICacheCtrlBuffer__auto_out_a_bits_opcode) t_ICacheCtrlBuffer__auto_out_a_bits_opcode = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_opcode = g_ICacheCtrlBuffer__auto_out_a_bits_opcode;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_size !== i_ICacheCtrlBuffer__auto_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_size g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_size, i_ICacheCtrlBuffer__auto_out_a_bits_size);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_size !== p_ICacheCtrlBuffer__auto_out_a_bits_size) t_ICacheCtrlBuffer__auto_out_a_bits_size = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_size = g_ICacheCtrlBuffer__auto_out_a_bits_size;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_source !== i_ICacheCtrlBuffer__auto_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_source g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_source, i_ICacheCtrlBuffer__auto_out_a_bits_source);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_source !== p_ICacheCtrlBuffer__auto_out_a_bits_source) t_ICacheCtrlBuffer__auto_out_a_bits_source = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_source = g_ICacheCtrlBuffer__auto_out_a_bits_source;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_address !== i_ICacheCtrlBuffer__auto_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_address g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_address, i_ICacheCtrlBuffer__auto_out_a_bits_address);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_address !== p_ICacheCtrlBuffer__auto_out_a_bits_address) t_ICacheCtrlBuffer__auto_out_a_bits_address = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_address = g_ICacheCtrlBuffer__auto_out_a_bits_address;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_mask !== i_ICacheCtrlBuffer__auto_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_mask g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_mask, i_ICacheCtrlBuffer__auto_out_a_bits_mask);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_mask !== p_ICacheCtrlBuffer__auto_out_a_bits_mask) t_ICacheCtrlBuffer__auto_out_a_bits_mask = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_mask = g_ICacheCtrlBuffer__auto_out_a_bits_mask;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_a_bits_data !== i_ICacheCtrlBuffer__auto_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_a_bits_data g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_a_bits_data, i_ICacheCtrlBuffer__auto_out_a_bits_data);
    end
    if (g_ICacheCtrlBuffer__auto_out_a_bits_data !== p_ICacheCtrlBuffer__auto_out_a_bits_data) t_ICacheCtrlBuffer__auto_out_a_bits_data = 1'b1;
    p_ICacheCtrlBuffer__auto_out_a_bits_data = g_ICacheCtrlBuffer__auto_out_a_bits_data;
    checks++;
    if (g_ICacheCtrlBuffer__auto_out_d_ready !== i_ICacheCtrlBuffer__auto_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ICacheCtrlBuffer.auto_out_d_ready g=%h i=%h", cyc, g_ICacheCtrlBuffer__auto_out_d_ready, i_ICacheCtrlBuffer__auto_out_d_ready);
    end
    if (g_ICacheCtrlBuffer__auto_out_d_ready !== p_ICacheCtrlBuffer__auto_out_d_ready) t_ICacheCtrlBuffer__auto_out_d_ready = 1'b1;
    p_ICacheCtrlBuffer__auto_out_d_ready = g_ICacheCtrlBuffer__auto_out_d_ready;
  endtask
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_enq = 0;
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_deq = 0;
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_full_blocked = 0;
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_1_enq = 0;
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_1_deq = 0;
  longint cov_ICacheCtrlBuffer_nodeOut_a_q_1_full_blocked = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_enq = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_deq = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_full_blocked = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_1_enq = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_1_deq = 0;
  longint cov_ICacheCtrlBuffer_nodeIn_d_q_1_full_blocked = 0;
  task automatic cover_ICacheCtrlBuffer();
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q.do_enq) cov_ICacheCtrlBuffer_nodeOut_a_q_enq++;
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q.do_deq) cov_ICacheCtrlBuffer_nodeOut_a_q_deq++;
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q.full && u_g_ICacheCtrlBuffer.nodeOut_a_q.io_enq_valid) cov_ICacheCtrlBuffer_nodeOut_a_q_full_blocked++;
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q_1.do_enq) cov_ICacheCtrlBuffer_nodeOut_a_q_1_enq++;
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q_1.do_deq) cov_ICacheCtrlBuffer_nodeOut_a_q_1_deq++;
    if (u_g_ICacheCtrlBuffer.nodeOut_a_q_1.full && u_g_ICacheCtrlBuffer.nodeOut_a_q_1.io_enq_valid) cov_ICacheCtrlBuffer_nodeOut_a_q_1_full_blocked++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q.do_enq) cov_ICacheCtrlBuffer_nodeIn_d_q_enq++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q.do_deq) cov_ICacheCtrlBuffer_nodeIn_d_q_deq++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q.full && u_g_ICacheCtrlBuffer.nodeIn_d_q.io_enq_valid) cov_ICacheCtrlBuffer_nodeIn_d_q_full_blocked++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q_1.do_enq) cov_ICacheCtrlBuffer_nodeIn_d_q_1_enq++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q_1.do_deq) cov_ICacheCtrlBuffer_nodeIn_d_q_1_deq++;
    if (u_g_ICacheCtrlBuffer.nodeIn_d_q_1.full && u_g_ICacheCtrlBuffer.nodeIn_d_q_1.io_enq_valid) cov_ICacheCtrlBuffer_nodeIn_d_q_1_full_blocked++;
  endtask
  task automatic preinit_ICacheCtrlBuffer();
  endtask
  task automatic sync_ICacheCtrlBuffer();
    u_i_ICacheCtrlBuffer.nodeOut_a_q.ram_ext.Memory = u_g_ICacheCtrlBuffer.nodeOut_a_q.ram_ext.Memory;
    u_i_ICacheCtrlBuffer.nodeOut_a_q_1.ram_ext.Memory = u_g_ICacheCtrlBuffer.nodeOut_a_q_1.ram_ext.Memory;
    u_i_ICacheCtrlBuffer.nodeIn_d_q.ram_ext.Memory = u_g_ICacheCtrlBuffer.nodeIn_d_q.ram_ext.Memory;
    u_i_ICacheCtrlBuffer.nodeIn_d_q_1.ram_ext.Memory = u_g_ICacheCtrlBuffer.nodeIn_d_q_1.ram_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_ICacheBuffer();
    drive_InstrUncacheBuffer();
    drive_ICacheCtrlBuffer();
    #1;
    preinit_ICacheBuffer();
    preinit_InstrUncacheBuffer();
    preinit_ICacheCtrlBuffer();
    sync_ICacheBuffer();
    sync_InstrUncacheBuffer();
    sync_ICacheCtrlBuffer();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_ICacheBuffer();
      drive_InstrUncacheBuffer();
      drive_ICacheCtrlBuffer();
      #1;
      check_ICacheBuffer();
      cover_ICacheBuffer();
      check_InstrUncacheBuffer();
      cover_InstrUncacheBuffer();
      check_ICacheCtrlBuffer();
      cover_ICacheCtrlBuffer();
    end
    begin int tg; tg = 0;
      if (t_ICacheBuffer__auto_in_a_ready) tg++; else $display("COV: ICacheBuffer.auto_in_a_ready never toggled");
      if (t_ICacheBuffer__auto_in_d_valid) tg++; else $display("COV: ICacheBuffer.auto_in_d_valid never toggled");
      if (t_ICacheBuffer__auto_in_d_bits_opcode) tg++; else $display("COV: ICacheBuffer.auto_in_d_bits_opcode never toggled");
      if (t_ICacheBuffer__auto_in_d_bits_size) tg++; else $display("COV: ICacheBuffer.auto_in_d_bits_size never toggled");
      if (t_ICacheBuffer__auto_in_d_bits_source) tg++; else $display("COV: ICacheBuffer.auto_in_d_bits_source never toggled");
      if (t_ICacheBuffer__auto_in_d_bits_data) tg++; else $display("COV: ICacheBuffer.auto_in_d_bits_data never toggled");
      if (t_ICacheBuffer__auto_in_d_bits_corrupt) tg++; else $display("COV: ICacheBuffer.auto_in_d_bits_corrupt never toggled");
      if (t_ICacheBuffer__auto_out_a_valid) tg++; else $display("COV: ICacheBuffer.auto_out_a_valid never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_opcode) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_opcode never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_param) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_param never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_size) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_size never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_source) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_source never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_address) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_address never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_user_alias) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_user_alias never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_user_reqSource) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_user_reqSource never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_user_needHint) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_user_needHint never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_mask) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_mask never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_data) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_data never toggled");
      if (t_ICacheBuffer__auto_out_a_bits_corrupt) tg++; else $display("COV: ICacheBuffer.auto_out_a_bits_corrupt never toggled");
      if (t_ICacheBuffer__auto_out_d_ready) tg++; else $display("COV: ICacheBuffer.auto_out_d_ready never toggled");
      $display("ICacheBuffer: toggled=%0d/20 (need >= 15)", tg);
      if (tg < 15) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_enq = %0d", cov_ICacheBuffer_nodeOut_a_q_enq);
      if (cov_ICacheBuffer_nodeOut_a_q_enq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_deq = %0d", cov_ICacheBuffer_nodeOut_a_q_deq);
      if (cov_ICacheBuffer_nodeOut_a_q_deq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_full_blocked = %0d", cov_ICacheBuffer_nodeOut_a_q_full_blocked);
      if (cov_ICacheBuffer_nodeOut_a_q_full_blocked == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_1_enq = %0d", cov_ICacheBuffer_nodeOut_a_q_1_enq);
      if (cov_ICacheBuffer_nodeOut_a_q_1_enq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_1_deq = %0d", cov_ICacheBuffer_nodeOut_a_q_1_deq);
      if (cov_ICacheBuffer_nodeOut_a_q_1_deq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeOut_a_q_1_full_blocked = %0d", cov_ICacheBuffer_nodeOut_a_q_1_full_blocked);
      if (cov_ICacheBuffer_nodeOut_a_q_1_full_blocked == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeIn_d_q_enq = %0d", cov_ICacheBuffer_nodeIn_d_q_enq);
      if (cov_ICacheBuffer_nodeIn_d_q_enq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeIn_d_q_deq = %0d", cov_ICacheBuffer_nodeIn_d_q_deq);
      if (cov_ICacheBuffer_nodeIn_d_q_deq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeIn_d_q_1_enq = %0d", cov_ICacheBuffer_nodeIn_d_q_1_enq);
      if (cov_ICacheBuffer_nodeIn_d_q_1_enq == 0) covfail = 1;
      $display("ICacheBuffer: cover nodeIn_d_q_1_deq = %0d", cov_ICacheBuffer_nodeIn_d_q_1_deq);
      if (cov_ICacheBuffer_nodeIn_d_q_1_deq == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_InstrUncacheBuffer__auto_in_a_ready) tg++; else $display("COV: InstrUncacheBuffer.auto_in_a_ready never toggled");
      if (t_InstrUncacheBuffer__auto_in_d_valid) tg++; else $display("COV: InstrUncacheBuffer.auto_in_d_valid never toggled");
      if (t_InstrUncacheBuffer__auto_in_d_bits_source) tg++; else $display("COV: InstrUncacheBuffer.auto_in_d_bits_source never toggled");
      if (t_InstrUncacheBuffer__auto_in_d_bits_data) tg++; else $display("COV: InstrUncacheBuffer.auto_in_d_bits_data never toggled");
      if (t_InstrUncacheBuffer__auto_in_d_bits_corrupt) tg++; else $display("COV: InstrUncacheBuffer.auto_in_d_bits_corrupt never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_valid) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_valid never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_bits_param) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_bits_param never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_bits_address) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_bits_address never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_bits_user_memPageType_NC) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_bits_user_memPageType_NC never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_bits_user_memBackType_MM) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_bits_user_memBackType_MM never toggled");
      if (t_InstrUncacheBuffer__auto_out_a_bits_corrupt) tg++; else $display("COV: InstrUncacheBuffer.auto_out_a_bits_corrupt never toggled");
      if (t_InstrUncacheBuffer__auto_out_d_ready) tg++; else $display("COV: InstrUncacheBuffer.auto_out_d_ready never toggled");
      $display("InstrUncacheBuffer: toggled=%0d/12 (need >= 10)", tg);
      if (tg < 10) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_enq = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_enq);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_enq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_deq = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_deq);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_deq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_full_blocked = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_full_blocked);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_full_blocked == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_1_enq = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_1_enq);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_1_enq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_1_deq = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_1_deq);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_1_deq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeOut_a_q_1_full_blocked = %0d", cov_InstrUncacheBuffer_nodeOut_a_q_1_full_blocked);
      if (cov_InstrUncacheBuffer_nodeOut_a_q_1_full_blocked == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeIn_d_q_enq = %0d", cov_InstrUncacheBuffer_nodeIn_d_q_enq);
      if (cov_InstrUncacheBuffer_nodeIn_d_q_enq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeIn_d_q_deq = %0d", cov_InstrUncacheBuffer_nodeIn_d_q_deq);
      if (cov_InstrUncacheBuffer_nodeIn_d_q_deq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeIn_d_q_1_enq = %0d", cov_InstrUncacheBuffer_nodeIn_d_q_1_enq);
      if (cov_InstrUncacheBuffer_nodeIn_d_q_1_enq == 0) covfail = 1;
      $display("InstrUncacheBuffer: cover nodeIn_d_q_1_deq = %0d", cov_InstrUncacheBuffer_nodeIn_d_q_1_deq);
      if (cov_InstrUncacheBuffer_nodeIn_d_q_1_deq == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_ICacheCtrlBuffer__auto_in_a_ready) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_a_ready never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_valid) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_valid never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_opcode) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_opcode never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_param) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_param never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_size) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_size never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_source) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_source never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_sink) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_sink never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_denied) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_denied never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_data) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_data never toggled");
      if (t_ICacheCtrlBuffer__auto_in_d_bits_corrupt) tg++; else $display("COV: ICacheCtrlBuffer.auto_in_d_bits_corrupt never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_valid) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_valid never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_opcode) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_opcode never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_size) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_size never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_source) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_source never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_address) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_address never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_mask) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_mask never toggled");
      if (t_ICacheCtrlBuffer__auto_out_a_bits_data) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_a_bits_data never toggled");
      if (t_ICacheCtrlBuffer__auto_out_d_ready) tg++; else $display("COV: ICacheCtrlBuffer.auto_out_d_ready never toggled");
      $display("ICacheCtrlBuffer: toggled=%0d/18 (need >= 14)", tg);
      if (tg < 14) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_enq = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_enq);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_enq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_deq = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_deq);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_deq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_full_blocked = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_full_blocked);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_full_blocked == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_1_enq = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_1_enq);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_1_enq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_1_deq = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_1_deq);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_1_deq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeOut_a_q_1_full_blocked = %0d", cov_ICacheCtrlBuffer_nodeOut_a_q_1_full_blocked);
      if (cov_ICacheCtrlBuffer_nodeOut_a_q_1_full_blocked == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_enq = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_enq);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_enq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_deq = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_deq);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_deq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_full_blocked = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_full_blocked);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_full_blocked == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_1_enq = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_1_enq);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_1_enq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_1_deq = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_1_deq);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_1_deq == 0) covfail = 1;
      $display("ICacheCtrlBuffer: cover nodeIn_d_q_1_full_blocked = %0d", cov_ICacheCtrlBuffer_nodeIn_d_q_1_full_blocked);
      if (cov_ICacheCtrlBuffer_nodeIn_d_q_1_full_blocked == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
