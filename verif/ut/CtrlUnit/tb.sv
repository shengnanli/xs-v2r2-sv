// 自动生成：verif/ut/CtrlUnit/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// CtrlUnit / Queue1_RegMapperInput_6 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Queue1_RegMapperInput_6 =================
  int unsigned q_mode = 0;
  logic q_reset;
  wire  q_g_io_enq_ready, q_i_io_enq_ready;
  logic q_s0_io_enq_ready = '0, q_s1_io_enq_ready = '0;
  logic q_io_enq_valid;
  logic q_io_enq_bits_read;
  logic [3:0] q_io_enq_bits_index;
  logic [63:0] q_io_enq_bits_data;
  logic [7:0] q_io_enq_bits_mask;
  logic [3:0] q_io_enq_bits_extra_tlrr_extra_source;
  logic [1:0] q_io_enq_bits_extra_tlrr_extra_size;
  logic q_io_deq_ready;
  wire  q_g_io_deq_valid, q_i_io_deq_valid;
  logic q_s0_io_deq_valid = '0, q_s1_io_deq_valid = '0;
  wire  q_g_io_deq_bits_read, q_i_io_deq_bits_read;
  logic q_s0_io_deq_bits_read = '0, q_s1_io_deq_bits_read = '0;
  wire  [3:0] q_g_io_deq_bits_index, q_i_io_deq_bits_index;
  logic [3:0] q_s0_io_deq_bits_index = '0, q_s1_io_deq_bits_index = '0;
  wire  [63:0] q_g_io_deq_bits_data, q_i_io_deq_bits_data;
  logic [63:0] q_s0_io_deq_bits_data = '0, q_s1_io_deq_bits_data = '0;
  wire  [7:0] q_g_io_deq_bits_mask, q_i_io_deq_bits_mask;
  logic [7:0] q_s0_io_deq_bits_mask = '0, q_s1_io_deq_bits_mask = '0;
  wire  [3:0] q_g_io_deq_bits_extra_tlrr_extra_source, q_i_io_deq_bits_extra_tlrr_extra_source;
  logic [3:0] q_s0_io_deq_bits_extra_tlrr_extra_source = '0, q_s1_io_deq_bits_extra_tlrr_extra_source = '0;
  wire  [1:0] q_g_io_deq_bits_extra_tlrr_extra_size, q_i_io_deq_bits_extra_tlrr_extra_size;
  logic [1:0] q_s0_io_deq_bits_extra_tlrr_extra_size = '0, q_s1_io_deq_bits_extra_tlrr_extra_size = '0;
  int q_cov_enq = 0;
  int q_cov_deq = 0;
  int q_cov_full_stall = 0;
  logic [0:0] q_armed = '0;
  int q_armed_at = -1;
  Queue1_RegMapperInput_6 q_u_gold (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_g_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_read(q_io_enq_bits_read),
    .io_enq_bits_index(q_io_enq_bits_index),
    .io_enq_bits_data(q_io_enq_bits_data),
    .io_enq_bits_mask(q_io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(q_io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(q_io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_g_io_deq_valid),
    .io_deq_bits_read(q_g_io_deq_bits_read),
    .io_deq_bits_index(q_g_io_deq_bits_index),
    .io_deq_bits_data(q_g_io_deq_bits_data),
    .io_deq_bits_mask(q_g_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(q_g_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(q_g_io_deq_bits_extra_tlrr_extra_size)
  );
  Queue1_RegMapperInput_6_xs q_u_impl (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_i_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_read(q_io_enq_bits_read),
    .io_enq_bits_index(q_io_enq_bits_index),
    .io_enq_bits_data(q_io_enq_bits_data),
    .io_enq_bits_mask(q_io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(q_io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(q_io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_i_io_deq_valid),
    .io_deq_bits_read(q_i_io_deq_bits_read),
    .io_deq_bits_index(q_i_io_deq_bits_index),
    .io_deq_bits_data(q_i_io_deq_bits_data),
    .io_deq_bits_mask(q_i_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(q_i_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(q_i_io_deq_bits_extra_tlrr_extra_size)
  );

  // ================= CtrlUnit =================
  int unsigned cu_mode = 0;
  logic cu_reset;
  wire  cu_g_auto_in_a_ready, cu_i_auto_in_a_ready;
  logic cu_s0_auto_in_a_ready = '0, cu_s1_auto_in_a_ready = '0;
  logic cu_auto_in_a_valid;
  logic [3:0] cu_auto_in_a_bits_opcode;
  logic [1:0] cu_auto_in_a_bits_size;
  logic [3:0] cu_auto_in_a_bits_source;
  logic [29:0] cu_auto_in_a_bits_address;
  logic [7:0] cu_auto_in_a_bits_mask;
  logic [63:0] cu_auto_in_a_bits_data;
  logic cu_auto_in_d_ready;
  wire  cu_g_auto_in_d_valid, cu_i_auto_in_d_valid;
  logic cu_s0_auto_in_d_valid = '0, cu_s1_auto_in_d_valid = '0;
  wire  [3:0] cu_g_auto_in_d_bits_opcode, cu_i_auto_in_d_bits_opcode;
  logic [3:0] cu_s0_auto_in_d_bits_opcode = '0, cu_s1_auto_in_d_bits_opcode = '0;
  wire  [1:0] cu_g_auto_in_d_bits_size, cu_i_auto_in_d_bits_size;
  logic [1:0] cu_s0_auto_in_d_bits_size = '0, cu_s1_auto_in_d_bits_size = '0;
  wire  [3:0] cu_g_auto_in_d_bits_source, cu_i_auto_in_d_bits_source;
  logic [3:0] cu_s0_auto_in_d_bits_source = '0, cu_s1_auto_in_d_bits_source = '0;
  wire  [63:0] cu_g_auto_in_d_bits_data, cu_i_auto_in_d_bits_data;
  logic [63:0] cu_s0_auto_in_d_bits_data = '0, cu_s1_auto_in_d_bits_data = '0;
  logic cu_io_pseudoError_0_ready;
  wire  cu_g_io_pseudoError_0_valid, cu_i_io_pseudoError_0_valid;
  logic cu_s0_io_pseudoError_0_valid = '0, cu_s1_io_pseudoError_0_valid = '0;
  wire  cu_g_io_pseudoError_0_bits_0_valid, cu_i_io_pseudoError_0_bits_0_valid;
  logic cu_s0_io_pseudoError_0_bits_0_valid = '0, cu_s1_io_pseudoError_0_bits_0_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_0_bits_0_mask, cu_i_io_pseudoError_0_bits_0_mask;
  logic [63:0] cu_s0_io_pseudoError_0_bits_0_mask = '0, cu_s1_io_pseudoError_0_bits_0_mask = '0;
  logic cu_io_pseudoError_1_ready;
  wire  cu_g_io_pseudoError_1_valid, cu_i_io_pseudoError_1_valid;
  logic cu_s0_io_pseudoError_1_valid = '0, cu_s1_io_pseudoError_1_valid = '0;
  wire  cu_g_io_pseudoError_1_bits_0_valid, cu_i_io_pseudoError_1_bits_0_valid;
  logic cu_s0_io_pseudoError_1_bits_0_valid = '0, cu_s1_io_pseudoError_1_bits_0_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_0_mask, cu_i_io_pseudoError_1_bits_0_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_0_mask = '0, cu_s1_io_pseudoError_1_bits_0_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_1_valid, cu_i_io_pseudoError_1_bits_1_valid;
  logic cu_s0_io_pseudoError_1_bits_1_valid = '0, cu_s1_io_pseudoError_1_bits_1_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_1_mask, cu_i_io_pseudoError_1_bits_1_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_1_mask = '0, cu_s1_io_pseudoError_1_bits_1_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_2_valid, cu_i_io_pseudoError_1_bits_2_valid;
  logic cu_s0_io_pseudoError_1_bits_2_valid = '0, cu_s1_io_pseudoError_1_bits_2_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_2_mask, cu_i_io_pseudoError_1_bits_2_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_2_mask = '0, cu_s1_io_pseudoError_1_bits_2_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_3_valid, cu_i_io_pseudoError_1_bits_3_valid;
  logic cu_s0_io_pseudoError_1_bits_3_valid = '0, cu_s1_io_pseudoError_1_bits_3_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_3_mask, cu_i_io_pseudoError_1_bits_3_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_3_mask = '0, cu_s1_io_pseudoError_1_bits_3_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_4_valid, cu_i_io_pseudoError_1_bits_4_valid;
  logic cu_s0_io_pseudoError_1_bits_4_valid = '0, cu_s1_io_pseudoError_1_bits_4_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_4_mask, cu_i_io_pseudoError_1_bits_4_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_4_mask = '0, cu_s1_io_pseudoError_1_bits_4_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_5_valid, cu_i_io_pseudoError_1_bits_5_valid;
  logic cu_s0_io_pseudoError_1_bits_5_valid = '0, cu_s1_io_pseudoError_1_bits_5_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_5_mask, cu_i_io_pseudoError_1_bits_5_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_5_mask = '0, cu_s1_io_pseudoError_1_bits_5_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_6_valid, cu_i_io_pseudoError_1_bits_6_valid;
  logic cu_s0_io_pseudoError_1_bits_6_valid = '0, cu_s1_io_pseudoError_1_bits_6_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_6_mask, cu_i_io_pseudoError_1_bits_6_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_6_mask = '0, cu_s1_io_pseudoError_1_bits_6_mask = '0;
  wire  cu_g_io_pseudoError_1_bits_7_valid, cu_i_io_pseudoError_1_bits_7_valid;
  logic cu_s0_io_pseudoError_1_bits_7_valid = '0, cu_s1_io_pseudoError_1_bits_7_valid = '0;
  wire  [63:0] cu_g_io_pseudoError_1_bits_7_mask, cu_i_io_pseudoError_1_bits_7_mask;
  logic [63:0] cu_s0_io_pseudoError_1_bits_7_mask = '0, cu_s1_io_pseudoError_1_bits_7_mask = '0;
  int cu_cov_fire_tag = 0;
  int cu_cov_fire_data = 0;
  int cu_cov_count_down = 0;
  int cu_cov_reload_persist = 0;
  int cu_cov_write_ctrl = 0;
  int cu_cov_write_delay = 0;
  int cu_cov_write_mask7 = 0;
  int cu_cov_write_partial = 0;
  int cu_cov_read = 0;
  int cu_cov_out0_stall = 0;
  int cu_cov_out1_stall = 0;
  logic [2:0] cu_armed = '0;
  int cu_armed_at = -1;
  CtrlUnit cu_u_gold (
    .clock(clk),
    .reset(cu_reset),
    .auto_in_a_ready(cu_g_auto_in_a_ready),
    .auto_in_a_valid(cu_auto_in_a_valid),
    .auto_in_a_bits_opcode(cu_auto_in_a_bits_opcode),
    .auto_in_a_bits_size(cu_auto_in_a_bits_size),
    .auto_in_a_bits_source(cu_auto_in_a_bits_source),
    .auto_in_a_bits_address(cu_auto_in_a_bits_address),
    .auto_in_a_bits_mask(cu_auto_in_a_bits_mask),
    .auto_in_a_bits_data(cu_auto_in_a_bits_data),
    .auto_in_d_ready(cu_auto_in_d_ready),
    .auto_in_d_valid(cu_g_auto_in_d_valid),
    .auto_in_d_bits_opcode(cu_g_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(cu_g_auto_in_d_bits_size),
    .auto_in_d_bits_source(cu_g_auto_in_d_bits_source),
    .auto_in_d_bits_data(cu_g_auto_in_d_bits_data),
    .io_pseudoError_0_ready(cu_io_pseudoError_0_ready),
    .io_pseudoError_0_valid(cu_g_io_pseudoError_0_valid),
    .io_pseudoError_0_bits_0_valid(cu_g_io_pseudoError_0_bits_0_valid),
    .io_pseudoError_0_bits_0_mask(cu_g_io_pseudoError_0_bits_0_mask),
    .io_pseudoError_1_ready(cu_io_pseudoError_1_ready),
    .io_pseudoError_1_valid(cu_g_io_pseudoError_1_valid),
    .io_pseudoError_1_bits_0_valid(cu_g_io_pseudoError_1_bits_0_valid),
    .io_pseudoError_1_bits_0_mask(cu_g_io_pseudoError_1_bits_0_mask),
    .io_pseudoError_1_bits_1_valid(cu_g_io_pseudoError_1_bits_1_valid),
    .io_pseudoError_1_bits_1_mask(cu_g_io_pseudoError_1_bits_1_mask),
    .io_pseudoError_1_bits_2_valid(cu_g_io_pseudoError_1_bits_2_valid),
    .io_pseudoError_1_bits_2_mask(cu_g_io_pseudoError_1_bits_2_mask),
    .io_pseudoError_1_bits_3_valid(cu_g_io_pseudoError_1_bits_3_valid),
    .io_pseudoError_1_bits_3_mask(cu_g_io_pseudoError_1_bits_3_mask),
    .io_pseudoError_1_bits_4_valid(cu_g_io_pseudoError_1_bits_4_valid),
    .io_pseudoError_1_bits_4_mask(cu_g_io_pseudoError_1_bits_4_mask),
    .io_pseudoError_1_bits_5_valid(cu_g_io_pseudoError_1_bits_5_valid),
    .io_pseudoError_1_bits_5_mask(cu_g_io_pseudoError_1_bits_5_mask),
    .io_pseudoError_1_bits_6_valid(cu_g_io_pseudoError_1_bits_6_valid),
    .io_pseudoError_1_bits_6_mask(cu_g_io_pseudoError_1_bits_6_mask),
    .io_pseudoError_1_bits_7_valid(cu_g_io_pseudoError_1_bits_7_valid),
    .io_pseudoError_1_bits_7_mask(cu_g_io_pseudoError_1_bits_7_mask)
  );
  CtrlUnit_xs cu_u_impl (
    .clock(clk),
    .reset(cu_reset),
    .auto_in_a_ready(cu_i_auto_in_a_ready),
    .auto_in_a_valid(cu_auto_in_a_valid),
    .auto_in_a_bits_opcode(cu_auto_in_a_bits_opcode),
    .auto_in_a_bits_size(cu_auto_in_a_bits_size),
    .auto_in_a_bits_source(cu_auto_in_a_bits_source),
    .auto_in_a_bits_address(cu_auto_in_a_bits_address),
    .auto_in_a_bits_mask(cu_auto_in_a_bits_mask),
    .auto_in_a_bits_data(cu_auto_in_a_bits_data),
    .auto_in_d_ready(cu_auto_in_d_ready),
    .auto_in_d_valid(cu_i_auto_in_d_valid),
    .auto_in_d_bits_opcode(cu_i_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(cu_i_auto_in_d_bits_size),
    .auto_in_d_bits_source(cu_i_auto_in_d_bits_source),
    .auto_in_d_bits_data(cu_i_auto_in_d_bits_data),
    .io_pseudoError_0_ready(cu_io_pseudoError_0_ready),
    .io_pseudoError_0_valid(cu_i_io_pseudoError_0_valid),
    .io_pseudoError_0_bits_0_valid(cu_i_io_pseudoError_0_bits_0_valid),
    .io_pseudoError_0_bits_0_mask(cu_i_io_pseudoError_0_bits_0_mask),
    .io_pseudoError_1_ready(cu_io_pseudoError_1_ready),
    .io_pseudoError_1_valid(cu_i_io_pseudoError_1_valid),
    .io_pseudoError_1_bits_0_valid(cu_i_io_pseudoError_1_bits_0_valid),
    .io_pseudoError_1_bits_0_mask(cu_i_io_pseudoError_1_bits_0_mask),
    .io_pseudoError_1_bits_1_valid(cu_i_io_pseudoError_1_bits_1_valid),
    .io_pseudoError_1_bits_1_mask(cu_i_io_pseudoError_1_bits_1_mask),
    .io_pseudoError_1_bits_2_valid(cu_i_io_pseudoError_1_bits_2_valid),
    .io_pseudoError_1_bits_2_mask(cu_i_io_pseudoError_1_bits_2_mask),
    .io_pseudoError_1_bits_3_valid(cu_i_io_pseudoError_1_bits_3_valid),
    .io_pseudoError_1_bits_3_mask(cu_i_io_pseudoError_1_bits_3_mask),
    .io_pseudoError_1_bits_4_valid(cu_i_io_pseudoError_1_bits_4_valid),
    .io_pseudoError_1_bits_4_mask(cu_i_io_pseudoError_1_bits_4_mask),
    .io_pseudoError_1_bits_5_valid(cu_i_io_pseudoError_1_bits_5_valid),
    .io_pseudoError_1_bits_5_mask(cu_i_io_pseudoError_1_bits_5_mask),
    .io_pseudoError_1_bits_6_valid(cu_i_io_pseudoError_1_bits_6_valid),
    .io_pseudoError_1_bits_6_mask(cu_i_io_pseudoError_1_bits_6_mask),
    .io_pseudoError_1_bits_7_valid(cu_i_io_pseudoError_1_bits_7_valid),
    .io_pseudoError_1_bits_7_mask(cu_i_io_pseudoError_1_bits_7_mask)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) q_mode = $urandom_range(0, 15);
      q_io_enq_valid = 1'($urandom);
      q_io_enq_bits_read = 1'($urandom);
      q_io_enq_bits_index = 4'($urandom);
      q_io_enq_bits_data = 64'({$urandom, $urandom});
      q_io_enq_bits_mask = 8'($urandom);
      q_io_enq_bits_extra_tlrr_extra_source = 4'($urandom);
      q_io_enq_bits_extra_tlrr_extra_size = 2'($urandom);
      q_io_deq_ready = 1'($urandom);
      q_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      if (cyc % 3000 == 0) cu_mode = $urandom_range(0, 15);
      cu_auto_in_a_valid = 1'($urandom);
      cu_auto_in_a_bits_opcode = 4'($urandom);
      cu_auto_in_a_bits_size = 2'($urandom);
      cu_auto_in_a_bits_source = 4'($urandom);
      cu_auto_in_a_bits_address = 30'($urandom);
      cu_auto_in_a_bits_mask = 8'($urandom);
      cu_auto_in_a_bits_data = 64'({$urandom, $urandom});
      cu_auto_in_d_ready = 1'($urandom);
      cu_io_pseudoError_0_ready = 1'($urandom);
      cu_io_pseudoError_1_ready = 1'($urandom);
      cu_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49999) == 0);
      begin : stim_cu
        if (cu_mode[0]) cu_auto_in_a_bits_opcode = ($urandom_range(0, 1) ? 4'h4 : 4'h0);
        if ($urandom_range(0, 2) != 0) cu_auto_in_a_bits_address[6:3] = 4'($urandom_range(0, 9));
        if ($urandom_range(0, 3) != 0) cu_auto_in_a_bits_mask = 8'hFF;
        if (cu_auto_in_a_bits_address[6:3] == 4'd0) begin
          cu_auto_in_a_bits_data[0] = ($urandom_range(0, 3) != 0);      // ese
          if (cu_mode[1]) cu_auto_in_a_bits_data[2] = 1'b0;                // ede 关的阶段
        end
        if (cu_auto_in_a_bits_address[6:3] == 4'd1 && $urandom_range(0, 7) != 0)
          cu_auto_in_a_bits_data = 64'($urandom_range(0, 15));
        if (cu_mode[3:2] == 2'd0) cu_auto_in_a_valid = ($urandom_range(0, 15) == 0);  // 少访问，让注入跑起来
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&q_armed)) begin
        checks++;
        if (q_g_io_enq_ready !== q_i_io_enq_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_enq_ready g=%h i=%h", cyc, q_g_io_enq_ready, q_i_io_enq_ready);
        end
        q_s1_io_enq_ready |= q_g_io_enq_ready;
        q_s0_io_enq_ready |= ~q_g_io_enq_ready;
        checks++;
        if (q_g_io_deq_valid !== q_i_io_deq_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_valid g=%h i=%h", cyc, q_g_io_deq_valid, q_i_io_deq_valid);
        end
        q_s1_io_deq_valid |= q_g_io_deq_valid;
        q_s0_io_deq_valid |= ~q_g_io_deq_valid;
        checks++;
        if (q_g_io_deq_bits_read !== q_i_io_deq_bits_read) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_read g=%h i=%h", cyc, q_g_io_deq_bits_read, q_i_io_deq_bits_read);
        end
        q_s1_io_deq_bits_read |= q_g_io_deq_bits_read;
        q_s0_io_deq_bits_read |= ~q_g_io_deq_bits_read;
        checks++;
        if (q_g_io_deq_bits_index !== q_i_io_deq_bits_index) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_index g=%h i=%h", cyc, q_g_io_deq_bits_index, q_i_io_deq_bits_index);
        end
        q_s1_io_deq_bits_index |= q_g_io_deq_bits_index;
        q_s0_io_deq_bits_index |= ~q_g_io_deq_bits_index;
        checks++;
        if (q_g_io_deq_bits_data !== q_i_io_deq_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_data g=%h i=%h", cyc, q_g_io_deq_bits_data, q_i_io_deq_bits_data);
        end
        q_s1_io_deq_bits_data |= q_g_io_deq_bits_data;
        q_s0_io_deq_bits_data |= ~q_g_io_deq_bits_data;
        checks++;
        if (q_g_io_deq_bits_mask !== q_i_io_deq_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_mask g=%h i=%h", cyc, q_g_io_deq_bits_mask, q_i_io_deq_bits_mask);
        end
        q_s1_io_deq_bits_mask |= q_g_io_deq_bits_mask;
        q_s0_io_deq_bits_mask |= ~q_g_io_deq_bits_mask;
        checks++;
        if (q_g_io_deq_bits_extra_tlrr_extra_source !== q_i_io_deq_bits_extra_tlrr_extra_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source g=%h i=%h", cyc, q_g_io_deq_bits_extra_tlrr_extra_source, q_i_io_deq_bits_extra_tlrr_extra_source);
        end
        q_s1_io_deq_bits_extra_tlrr_extra_source |= q_g_io_deq_bits_extra_tlrr_extra_source;
        q_s0_io_deq_bits_extra_tlrr_extra_source |= ~q_g_io_deq_bits_extra_tlrr_extra_source;
        checks++;
        if (q_g_io_deq_bits_extra_tlrr_extra_size !== q_i_io_deq_bits_extra_tlrr_extra_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size g=%h i=%h", cyc, q_g_io_deq_bits_extra_tlrr_extra_size, q_i_io_deq_bits_extra_tlrr_extra_size);
        end
        q_s1_io_deq_bits_extra_tlrr_extra_size |= q_g_io_deq_bits_extra_tlrr_extra_size;
        q_s0_io_deq_bits_extra_tlrr_extra_size |= ~q_g_io_deq_bits_extra_tlrr_extra_size;
        if (q_io_enq_valid && q_g_io_enq_ready) q_cov_enq++;
        if (q_g_io_deq_valid && q_io_deq_ready) q_cov_deq++;
        if (q_g_io_deq_valid && !q_io_deq_ready && q_io_enq_valid) q_cov_full_stall++;
      end
      if (q_io_enq_valid && q_g_io_enq_ready) q_armed[0] = 1'b1;
      if (q_armed_at < 0 && (&q_armed)) q_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && (&cu_armed)) begin
        checks++;
        if (cu_g_auto_in_a_ready !== cu_i_auto_in_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_a_ready g=%h i=%h", cyc, cu_g_auto_in_a_ready, cu_i_auto_in_a_ready);
        end
        cu_s1_auto_in_a_ready |= cu_g_auto_in_a_ready;
        cu_s0_auto_in_a_ready |= ~cu_g_auto_in_a_ready;
        checks++;
        if (cu_g_auto_in_d_valid !== cu_i_auto_in_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_d_valid g=%h i=%h", cyc, cu_g_auto_in_d_valid, cu_i_auto_in_d_valid);
        end
        cu_s1_auto_in_d_valid |= cu_g_auto_in_d_valid;
        cu_s0_auto_in_d_valid |= ~cu_g_auto_in_d_valid;
        checks++;
        if (cu_g_auto_in_d_bits_opcode !== cu_i_auto_in_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_d_bits_opcode g=%h i=%h", cyc, cu_g_auto_in_d_bits_opcode, cu_i_auto_in_d_bits_opcode);
        end
        cu_s1_auto_in_d_bits_opcode |= cu_g_auto_in_d_bits_opcode;
        cu_s0_auto_in_d_bits_opcode |= ~cu_g_auto_in_d_bits_opcode;
        checks++;
        if (cu_g_auto_in_d_bits_size !== cu_i_auto_in_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_d_bits_size g=%h i=%h", cyc, cu_g_auto_in_d_bits_size, cu_i_auto_in_d_bits_size);
        end
        cu_s1_auto_in_d_bits_size |= cu_g_auto_in_d_bits_size;
        cu_s0_auto_in_d_bits_size |= ~cu_g_auto_in_d_bits_size;
        checks++;
        if (cu_g_auto_in_d_bits_source !== cu_i_auto_in_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_d_bits_source g=%h i=%h", cyc, cu_g_auto_in_d_bits_source, cu_i_auto_in_d_bits_source);
        end
        cu_s1_auto_in_d_bits_source |= cu_g_auto_in_d_bits_source;
        cu_s0_auto_in_d_bits_source |= ~cu_g_auto_in_d_bits_source;
        checks++;
        if (cu_g_auto_in_d_bits_data !== cu_i_auto_in_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.auto_in_d_bits_data g=%h i=%h", cyc, cu_g_auto_in_d_bits_data, cu_i_auto_in_d_bits_data);
        end
        cu_s1_auto_in_d_bits_data |= cu_g_auto_in_d_bits_data;
        cu_s0_auto_in_d_bits_data |= ~cu_g_auto_in_d_bits_data;
        checks++;
        if (cu_g_io_pseudoError_0_valid !== cu_i_io_pseudoError_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_0_valid g=%h i=%h", cyc, cu_g_io_pseudoError_0_valid, cu_i_io_pseudoError_0_valid);
        end
        cu_s1_io_pseudoError_0_valid |= cu_g_io_pseudoError_0_valid;
        cu_s0_io_pseudoError_0_valid |= ~cu_g_io_pseudoError_0_valid;
        checks++;
        if (cu_g_io_pseudoError_0_bits_0_valid !== cu_i_io_pseudoError_0_bits_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_0_bits_0_valid g=%h i=%h", cyc, cu_g_io_pseudoError_0_bits_0_valid, cu_i_io_pseudoError_0_bits_0_valid);
        end
        cu_s1_io_pseudoError_0_bits_0_valid |= cu_g_io_pseudoError_0_bits_0_valid;
        cu_s0_io_pseudoError_0_bits_0_valid |= ~cu_g_io_pseudoError_0_bits_0_valid;
        checks++;
        if (cu_g_io_pseudoError_0_bits_0_mask !== cu_i_io_pseudoError_0_bits_0_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_0_bits_0_mask g=%h i=%h", cyc, cu_g_io_pseudoError_0_bits_0_mask, cu_i_io_pseudoError_0_bits_0_mask);
        end
        cu_s1_io_pseudoError_0_bits_0_mask |= cu_g_io_pseudoError_0_bits_0_mask;
        cu_s0_io_pseudoError_0_bits_0_mask |= ~cu_g_io_pseudoError_0_bits_0_mask;
        checks++;
        if (cu_g_io_pseudoError_1_valid !== cu_i_io_pseudoError_1_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_valid, cu_i_io_pseudoError_1_valid);
        end
        cu_s1_io_pseudoError_1_valid |= cu_g_io_pseudoError_1_valid;
        cu_s0_io_pseudoError_1_valid |= ~cu_g_io_pseudoError_1_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_0_valid !== cu_i_io_pseudoError_1_bits_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_0_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_0_valid, cu_i_io_pseudoError_1_bits_0_valid);
        end
        cu_s1_io_pseudoError_1_bits_0_valid |= cu_g_io_pseudoError_1_bits_0_valid;
        cu_s0_io_pseudoError_1_bits_0_valid |= ~cu_g_io_pseudoError_1_bits_0_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_0_mask !== cu_i_io_pseudoError_1_bits_0_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_0_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_0_mask, cu_i_io_pseudoError_1_bits_0_mask);
        end
        cu_s1_io_pseudoError_1_bits_0_mask |= cu_g_io_pseudoError_1_bits_0_mask;
        cu_s0_io_pseudoError_1_bits_0_mask |= ~cu_g_io_pseudoError_1_bits_0_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_1_valid !== cu_i_io_pseudoError_1_bits_1_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_1_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_1_valid, cu_i_io_pseudoError_1_bits_1_valid);
        end
        cu_s1_io_pseudoError_1_bits_1_valid |= cu_g_io_pseudoError_1_bits_1_valid;
        cu_s0_io_pseudoError_1_bits_1_valid |= ~cu_g_io_pseudoError_1_bits_1_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_1_mask !== cu_i_io_pseudoError_1_bits_1_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_1_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_1_mask, cu_i_io_pseudoError_1_bits_1_mask);
        end
        cu_s1_io_pseudoError_1_bits_1_mask |= cu_g_io_pseudoError_1_bits_1_mask;
        cu_s0_io_pseudoError_1_bits_1_mask |= ~cu_g_io_pseudoError_1_bits_1_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_2_valid !== cu_i_io_pseudoError_1_bits_2_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_2_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_2_valid, cu_i_io_pseudoError_1_bits_2_valid);
        end
        cu_s1_io_pseudoError_1_bits_2_valid |= cu_g_io_pseudoError_1_bits_2_valid;
        cu_s0_io_pseudoError_1_bits_2_valid |= ~cu_g_io_pseudoError_1_bits_2_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_2_mask !== cu_i_io_pseudoError_1_bits_2_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_2_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_2_mask, cu_i_io_pseudoError_1_bits_2_mask);
        end
        cu_s1_io_pseudoError_1_bits_2_mask |= cu_g_io_pseudoError_1_bits_2_mask;
        cu_s0_io_pseudoError_1_bits_2_mask |= ~cu_g_io_pseudoError_1_bits_2_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_3_valid !== cu_i_io_pseudoError_1_bits_3_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_3_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_3_valid, cu_i_io_pseudoError_1_bits_3_valid);
        end
        cu_s1_io_pseudoError_1_bits_3_valid |= cu_g_io_pseudoError_1_bits_3_valid;
        cu_s0_io_pseudoError_1_bits_3_valid |= ~cu_g_io_pseudoError_1_bits_3_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_3_mask !== cu_i_io_pseudoError_1_bits_3_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_3_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_3_mask, cu_i_io_pseudoError_1_bits_3_mask);
        end
        cu_s1_io_pseudoError_1_bits_3_mask |= cu_g_io_pseudoError_1_bits_3_mask;
        cu_s0_io_pseudoError_1_bits_3_mask |= ~cu_g_io_pseudoError_1_bits_3_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_4_valid !== cu_i_io_pseudoError_1_bits_4_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_4_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_4_valid, cu_i_io_pseudoError_1_bits_4_valid);
        end
        cu_s1_io_pseudoError_1_bits_4_valid |= cu_g_io_pseudoError_1_bits_4_valid;
        cu_s0_io_pseudoError_1_bits_4_valid |= ~cu_g_io_pseudoError_1_bits_4_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_4_mask !== cu_i_io_pseudoError_1_bits_4_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_4_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_4_mask, cu_i_io_pseudoError_1_bits_4_mask);
        end
        cu_s1_io_pseudoError_1_bits_4_mask |= cu_g_io_pseudoError_1_bits_4_mask;
        cu_s0_io_pseudoError_1_bits_4_mask |= ~cu_g_io_pseudoError_1_bits_4_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_5_valid !== cu_i_io_pseudoError_1_bits_5_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_5_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_5_valid, cu_i_io_pseudoError_1_bits_5_valid);
        end
        cu_s1_io_pseudoError_1_bits_5_valid |= cu_g_io_pseudoError_1_bits_5_valid;
        cu_s0_io_pseudoError_1_bits_5_valid |= ~cu_g_io_pseudoError_1_bits_5_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_5_mask !== cu_i_io_pseudoError_1_bits_5_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_5_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_5_mask, cu_i_io_pseudoError_1_bits_5_mask);
        end
        cu_s1_io_pseudoError_1_bits_5_mask |= cu_g_io_pseudoError_1_bits_5_mask;
        cu_s0_io_pseudoError_1_bits_5_mask |= ~cu_g_io_pseudoError_1_bits_5_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_6_valid !== cu_i_io_pseudoError_1_bits_6_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_6_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_6_valid, cu_i_io_pseudoError_1_bits_6_valid);
        end
        cu_s1_io_pseudoError_1_bits_6_valid |= cu_g_io_pseudoError_1_bits_6_valid;
        cu_s0_io_pseudoError_1_bits_6_valid |= ~cu_g_io_pseudoError_1_bits_6_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_6_mask !== cu_i_io_pseudoError_1_bits_6_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_6_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_6_mask, cu_i_io_pseudoError_1_bits_6_mask);
        end
        cu_s1_io_pseudoError_1_bits_6_mask |= cu_g_io_pseudoError_1_bits_6_mask;
        cu_s0_io_pseudoError_1_bits_6_mask |= ~cu_g_io_pseudoError_1_bits_6_mask;
        checks++;
        if (cu_g_io_pseudoError_1_bits_7_valid !== cu_i_io_pseudoError_1_bits_7_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_7_valid g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_7_valid, cu_i_io_pseudoError_1_bits_7_valid);
        end
        cu_s1_io_pseudoError_1_bits_7_valid |= cu_g_io_pseudoError_1_bits_7_valid;
        cu_s0_io_pseudoError_1_bits_7_valid |= ~cu_g_io_pseudoError_1_bits_7_valid;
        checks++;
        if (cu_g_io_pseudoError_1_bits_7_mask !== cu_i_io_pseudoError_1_bits_7_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CtrlUnit.io_pseudoError_1_bits_7_mask g=%h i=%h", cyc, cu_g_io_pseudoError_1_bits_7_mask, cu_i_io_pseudoError_1_bits_7_mask);
        end
        cu_s1_io_pseudoError_1_bits_7_mask |= cu_g_io_pseudoError_1_bits_7_mask;
        cu_s0_io_pseudoError_1_bits_7_mask |= ~cu_g_io_pseudoError_1_bits_7_mask;
        if (cu_u_gold._CtrlUnitPseudoErrorPipelineConnect0_io_in_ready && cu_u_gold.pseudoError_gen_0_valid) cu_cov_fire_tag++;
        if (cu_u_gold._CtrlUnitPseudoErrorPipelineConnect1_io_in_ready && cu_u_gold.pseudoError_gen_1_valid) cu_cov_fire_data++;
        if (cu_u_gold.ctrlRegs_0[0] && cu_u_gold.ctrlRegs_0[2] && (|cu_u_gold.counterRegs_0)) cu_cov_count_down++;
        if ((cu_u_gold._GEN_0 || cu_u_gold._GEN_1) && cu_u_gold.ctrlRegs_0[1] && cu_u_gold.ctrlRegs_0[2]) cu_cov_reload_persist++;
        if (cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h0 && (&cu_u_gold.out_backMask)) cu_cov_write_ctrl++;
        if (cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h1 && (&cu_u_gold.out_backMask)) cu_cov_write_delay++;
        if (cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h9 && (&cu_u_gold.out_backMask)) cu_cov_write_mask7++;
        if (cu_u_gold._out_wofireMux_T_2 && !(&cu_u_gold.out_backMask)) cu_cov_write_partial++;
        if (cu_g_auto_in_d_valid && cu_auto_in_d_ready && cu_g_auto_in_d_bits_opcode[0]) cu_cov_read++;
        if (cu_g_io_pseudoError_0_valid && !cu_io_pseudoError_0_ready) cu_cov_out0_stall++;
        if (cu_g_io_pseudoError_1_valid && !cu_io_pseudoError_1_ready) cu_cov_out1_stall++;
      end
      if (cu_auto_in_a_valid && cu_g_auto_in_a_ready) cu_armed[0] = 1'b1;
      if (cu_u_gold._CtrlUnitPseudoErrorPipelineConnect0_io_in_ready && cu_u_gold.pseudoError_gen_0_valid) cu_armed[1] = 1'b1;
      if (cu_u_gold._CtrlUnitPseudoErrorPipelineConnect1_io_in_ready && cu_u_gold.pseudoError_gen_1_valid) cu_armed[2] = 1'b1;
      if (cu_armed_at < 0 && (&cu_armed)) cu_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(q_s0_io_enq_ready && q_s1_io_enq_ready)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_enq_ready 未见过 0 和 1"); end
    if (!(q_s0_io_deq_valid && q_s1_io_deq_valid)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_valid 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_read && q_s1_io_deq_bits_read)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_read 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[0] && q_s1_io_deq_bits_index[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[1] && q_s1_io_deq_bits_index[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[2] && q_s1_io_deq_bits_index[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[3] && q_s1_io_deq_bits_index[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[0] && q_s1_io_deq_bits_data[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[1] && q_s1_io_deq_bits_data[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[2] && q_s1_io_deq_bits_data[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[3] && q_s1_io_deq_bits_data[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[4] && q_s1_io_deq_bits_data[4])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[4] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[5] && q_s1_io_deq_bits_data[5])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[5] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[6] && q_s1_io_deq_bits_data[6])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[6] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[7] && q_s1_io_deq_bits_data[7])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[7] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[8] && q_s1_io_deq_bits_data[8])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[8] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[9] && q_s1_io_deq_bits_data[9])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[9] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[10] && q_s1_io_deq_bits_data[10])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[10] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[11] && q_s1_io_deq_bits_data[11])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[11] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[12] && q_s1_io_deq_bits_data[12])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[12] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[13] && q_s1_io_deq_bits_data[13])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[13] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[14] && q_s1_io_deq_bits_data[14])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[14] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[15] && q_s1_io_deq_bits_data[15])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[15] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[16] && q_s1_io_deq_bits_data[16])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[16] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[17] && q_s1_io_deq_bits_data[17])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[17] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[18] && q_s1_io_deq_bits_data[18])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[18] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[19] && q_s1_io_deq_bits_data[19])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[19] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[20] && q_s1_io_deq_bits_data[20])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[20] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[21] && q_s1_io_deq_bits_data[21])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[21] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[22] && q_s1_io_deq_bits_data[22])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[22] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[23] && q_s1_io_deq_bits_data[23])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[23] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[24] && q_s1_io_deq_bits_data[24])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[24] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[25] && q_s1_io_deq_bits_data[25])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[25] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[26] && q_s1_io_deq_bits_data[26])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[26] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[27] && q_s1_io_deq_bits_data[27])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[27] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[28] && q_s1_io_deq_bits_data[28])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[28] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[29] && q_s1_io_deq_bits_data[29])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[29] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[30] && q_s1_io_deq_bits_data[30])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[30] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[31] && q_s1_io_deq_bits_data[31])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[31] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[32] && q_s1_io_deq_bits_data[32])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[32] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[33] && q_s1_io_deq_bits_data[33])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[33] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[34] && q_s1_io_deq_bits_data[34])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[34] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[35] && q_s1_io_deq_bits_data[35])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[35] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[36] && q_s1_io_deq_bits_data[36])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[36] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[37] && q_s1_io_deq_bits_data[37])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[37] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[38] && q_s1_io_deq_bits_data[38])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[38] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[39] && q_s1_io_deq_bits_data[39])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[39] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[40] && q_s1_io_deq_bits_data[40])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[40] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[41] && q_s1_io_deq_bits_data[41])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[41] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[42] && q_s1_io_deq_bits_data[42])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[42] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[43] && q_s1_io_deq_bits_data[43])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[43] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[44] && q_s1_io_deq_bits_data[44])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[44] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[45] && q_s1_io_deq_bits_data[45])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[45] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[46] && q_s1_io_deq_bits_data[46])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[46] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[47] && q_s1_io_deq_bits_data[47])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[47] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[48] && q_s1_io_deq_bits_data[48])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[48] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[49] && q_s1_io_deq_bits_data[49])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[49] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[50] && q_s1_io_deq_bits_data[50])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[50] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[51] && q_s1_io_deq_bits_data[51])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[51] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[52] && q_s1_io_deq_bits_data[52])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[52] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[53] && q_s1_io_deq_bits_data[53])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[53] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[54] && q_s1_io_deq_bits_data[54])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[54] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[55] && q_s1_io_deq_bits_data[55])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[55] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[56] && q_s1_io_deq_bits_data[56])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[56] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[57] && q_s1_io_deq_bits_data[57])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[57] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[58] && q_s1_io_deq_bits_data[58])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[58] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[59] && q_s1_io_deq_bits_data[59])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[59] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[60] && q_s1_io_deq_bits_data[60])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[60] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[61] && q_s1_io_deq_bits_data[61])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[61] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[62] && q_s1_io_deq_bits_data[62])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[62] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[63] && q_s1_io_deq_bits_data[63])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[63] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[0] && q_s1_io_deq_bits_mask[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[1] && q_s1_io_deq_bits_mask[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[2] && q_s1_io_deq_bits_mask[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[3] && q_s1_io_deq_bits_mask[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[4] && q_s1_io_deq_bits_mask[4])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[4] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[5] && q_s1_io_deq_bits_mask[5])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[5] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[6] && q_s1_io_deq_bits_mask[6])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[6] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[7] && q_s1_io_deq_bits_mask[7])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[7] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[0] && q_s1_io_deq_bits_extra_tlrr_extra_source[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[1] && q_s1_io_deq_bits_extra_tlrr_extra_source[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[2] && q_s1_io_deq_bits_extra_tlrr_extra_source[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[3] && q_s1_io_deq_bits_extra_tlrr_extra_source[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_size[0] && q_s1_io_deq_bits_extra_tlrr_extra_size[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_size[1] && q_s1_io_deq_bits_extra_tlrr_extra_size[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size[1] 未见过 0 和 1"); end
    $display("[ARM] Queue1_RegMapperInput_6 armed_at=%0d", q_armed_at);
    if (q_armed_at < 0) begin cov_fail++; $display("[ARM] Queue1_RegMapperInput_6 从未 arm"); end
    $display("[COV] Queue1_RegMapperInput_6.enq = %0d", q_cov_enq);
    if (q_cov_enq < 1000) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.enq < 1000"); end
    $display("[COV] Queue1_RegMapperInput_6.deq = %0d", q_cov_deq);
    if (q_cov_deq < 1000) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.deq < 1000"); end
    $display("[COV] Queue1_RegMapperInput_6.full_stall = %0d", q_cov_full_stall);
    if (q_cov_full_stall < 1000) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.full_stall < 1000"); end
    if (!(cu_s0_auto_in_a_ready && cu_s1_auto_in_a_ready)) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_a_ready 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_valid && cu_s1_auto_in_d_valid)) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_valid 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_opcode[0] && cu_s1_auto_in_d_bits_opcode[0])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_size[0] && cu_s1_auto_in_d_bits_size[0])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_size[0] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_size[1] && cu_s1_auto_in_d_bits_size[1])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_size[1] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_source[0] && cu_s1_auto_in_d_bits_source[0])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_source[0] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_source[1] && cu_s1_auto_in_d_bits_source[1])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_source[1] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_source[2] && cu_s1_auto_in_d_bits_source[2])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_source[2] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_source[3] && cu_s1_auto_in_d_bits_source[3])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_source[3] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[0] && cu_s1_auto_in_d_bits_data[0])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[0] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[1] && cu_s1_auto_in_d_bits_data[1])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[1] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[2] && cu_s1_auto_in_d_bits_data[2])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[2] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[3] && cu_s1_auto_in_d_bits_data[3])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[3] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[4] && cu_s1_auto_in_d_bits_data[4])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[4] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[5] && cu_s1_auto_in_d_bits_data[5])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[5] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[6] && cu_s1_auto_in_d_bits_data[6])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[6] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[7] && cu_s1_auto_in_d_bits_data[7])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[7] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[8] && cu_s1_auto_in_d_bits_data[8])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[8] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[9] && cu_s1_auto_in_d_bits_data[9])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[9] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[10] && cu_s1_auto_in_d_bits_data[10])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[10] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[11] && cu_s1_auto_in_d_bits_data[11])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[11] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[12] && cu_s1_auto_in_d_bits_data[12])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[12] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[13] && cu_s1_auto_in_d_bits_data[13])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[13] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[14] && cu_s1_auto_in_d_bits_data[14])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[14] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[15] && cu_s1_auto_in_d_bits_data[15])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[15] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[16] && cu_s1_auto_in_d_bits_data[16])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[16] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[17] && cu_s1_auto_in_d_bits_data[17])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[17] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[18] && cu_s1_auto_in_d_bits_data[18])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[18] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[19] && cu_s1_auto_in_d_bits_data[19])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[19] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[20] && cu_s1_auto_in_d_bits_data[20])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[20] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[21] && cu_s1_auto_in_d_bits_data[21])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[21] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[22] && cu_s1_auto_in_d_bits_data[22])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[22] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[23] && cu_s1_auto_in_d_bits_data[23])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[23] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[24] && cu_s1_auto_in_d_bits_data[24])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[24] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[25] && cu_s1_auto_in_d_bits_data[25])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[25] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[26] && cu_s1_auto_in_d_bits_data[26])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[26] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[27] && cu_s1_auto_in_d_bits_data[27])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[27] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[28] && cu_s1_auto_in_d_bits_data[28])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[28] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[29] && cu_s1_auto_in_d_bits_data[29])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[29] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[30] && cu_s1_auto_in_d_bits_data[30])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[30] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[31] && cu_s1_auto_in_d_bits_data[31])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[31] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[32] && cu_s1_auto_in_d_bits_data[32])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[32] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[33] && cu_s1_auto_in_d_bits_data[33])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[33] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[34] && cu_s1_auto_in_d_bits_data[34])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[34] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[35] && cu_s1_auto_in_d_bits_data[35])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[35] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[36] && cu_s1_auto_in_d_bits_data[36])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[36] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[37] && cu_s1_auto_in_d_bits_data[37])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[37] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[38] && cu_s1_auto_in_d_bits_data[38])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[38] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[39] && cu_s1_auto_in_d_bits_data[39])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[39] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[40] && cu_s1_auto_in_d_bits_data[40])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[40] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[41] && cu_s1_auto_in_d_bits_data[41])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[41] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[42] && cu_s1_auto_in_d_bits_data[42])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[42] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[43] && cu_s1_auto_in_d_bits_data[43])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[43] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[44] && cu_s1_auto_in_d_bits_data[44])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[44] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[45] && cu_s1_auto_in_d_bits_data[45])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[45] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[46] && cu_s1_auto_in_d_bits_data[46])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[46] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[47] && cu_s1_auto_in_d_bits_data[47])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[47] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[48] && cu_s1_auto_in_d_bits_data[48])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[48] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[49] && cu_s1_auto_in_d_bits_data[49])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[49] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[50] && cu_s1_auto_in_d_bits_data[50])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[50] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[51] && cu_s1_auto_in_d_bits_data[51])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[51] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[52] && cu_s1_auto_in_d_bits_data[52])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[52] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[53] && cu_s1_auto_in_d_bits_data[53])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[53] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[54] && cu_s1_auto_in_d_bits_data[54])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[54] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[55] && cu_s1_auto_in_d_bits_data[55])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[55] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[56] && cu_s1_auto_in_d_bits_data[56])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[56] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[57] && cu_s1_auto_in_d_bits_data[57])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[57] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[58] && cu_s1_auto_in_d_bits_data[58])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[58] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[59] && cu_s1_auto_in_d_bits_data[59])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[59] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[60] && cu_s1_auto_in_d_bits_data[60])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[60] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[61] && cu_s1_auto_in_d_bits_data[61])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[61] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[62] && cu_s1_auto_in_d_bits_data[62])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[62] 未见过 0 和 1"); end
    if (!(cu_s0_auto_in_d_bits_data[63] && cu_s1_auto_in_d_bits_data[63])) begin cov_fail++; $display("[COV] CtrlUnit.auto_in_d_bits_data[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_valid && cu_s1_io_pseudoError_0_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_valid && cu_s1_io_pseudoError_0_bits_0_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[0] && cu_s1_io_pseudoError_0_bits_0_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[1] && cu_s1_io_pseudoError_0_bits_0_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[2] && cu_s1_io_pseudoError_0_bits_0_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[3] && cu_s1_io_pseudoError_0_bits_0_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[4] && cu_s1_io_pseudoError_0_bits_0_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[5] && cu_s1_io_pseudoError_0_bits_0_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[6] && cu_s1_io_pseudoError_0_bits_0_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[7] && cu_s1_io_pseudoError_0_bits_0_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[8] && cu_s1_io_pseudoError_0_bits_0_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[9] && cu_s1_io_pseudoError_0_bits_0_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[10] && cu_s1_io_pseudoError_0_bits_0_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[11] && cu_s1_io_pseudoError_0_bits_0_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[12] && cu_s1_io_pseudoError_0_bits_0_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[13] && cu_s1_io_pseudoError_0_bits_0_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[14] && cu_s1_io_pseudoError_0_bits_0_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[15] && cu_s1_io_pseudoError_0_bits_0_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[16] && cu_s1_io_pseudoError_0_bits_0_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[17] && cu_s1_io_pseudoError_0_bits_0_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[18] && cu_s1_io_pseudoError_0_bits_0_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[19] && cu_s1_io_pseudoError_0_bits_0_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[20] && cu_s1_io_pseudoError_0_bits_0_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[21] && cu_s1_io_pseudoError_0_bits_0_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[22] && cu_s1_io_pseudoError_0_bits_0_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[23] && cu_s1_io_pseudoError_0_bits_0_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[24] && cu_s1_io_pseudoError_0_bits_0_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[25] && cu_s1_io_pseudoError_0_bits_0_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[26] && cu_s1_io_pseudoError_0_bits_0_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[27] && cu_s1_io_pseudoError_0_bits_0_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[28] && cu_s1_io_pseudoError_0_bits_0_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[29] && cu_s1_io_pseudoError_0_bits_0_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[30] && cu_s1_io_pseudoError_0_bits_0_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[31] && cu_s1_io_pseudoError_0_bits_0_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[32] && cu_s1_io_pseudoError_0_bits_0_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[33] && cu_s1_io_pseudoError_0_bits_0_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[34] && cu_s1_io_pseudoError_0_bits_0_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[35] && cu_s1_io_pseudoError_0_bits_0_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[36] && cu_s1_io_pseudoError_0_bits_0_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[37] && cu_s1_io_pseudoError_0_bits_0_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[38] && cu_s1_io_pseudoError_0_bits_0_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[39] && cu_s1_io_pseudoError_0_bits_0_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[40] && cu_s1_io_pseudoError_0_bits_0_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[41] && cu_s1_io_pseudoError_0_bits_0_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[42] && cu_s1_io_pseudoError_0_bits_0_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[43] && cu_s1_io_pseudoError_0_bits_0_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[44] && cu_s1_io_pseudoError_0_bits_0_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[45] && cu_s1_io_pseudoError_0_bits_0_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[46] && cu_s1_io_pseudoError_0_bits_0_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[47] && cu_s1_io_pseudoError_0_bits_0_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[48] && cu_s1_io_pseudoError_0_bits_0_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[49] && cu_s1_io_pseudoError_0_bits_0_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[50] && cu_s1_io_pseudoError_0_bits_0_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[51] && cu_s1_io_pseudoError_0_bits_0_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[52] && cu_s1_io_pseudoError_0_bits_0_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[53] && cu_s1_io_pseudoError_0_bits_0_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[54] && cu_s1_io_pseudoError_0_bits_0_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[55] && cu_s1_io_pseudoError_0_bits_0_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[56] && cu_s1_io_pseudoError_0_bits_0_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[57] && cu_s1_io_pseudoError_0_bits_0_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[58] && cu_s1_io_pseudoError_0_bits_0_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[59] && cu_s1_io_pseudoError_0_bits_0_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[60] && cu_s1_io_pseudoError_0_bits_0_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[61] && cu_s1_io_pseudoError_0_bits_0_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[62] && cu_s1_io_pseudoError_0_bits_0_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_0_bits_0_mask[63] && cu_s1_io_pseudoError_0_bits_0_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_0_bits_0_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_valid && cu_s1_io_pseudoError_1_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_valid && cu_s1_io_pseudoError_1_bits_0_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[0] && cu_s1_io_pseudoError_1_bits_0_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[1] && cu_s1_io_pseudoError_1_bits_0_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[2] && cu_s1_io_pseudoError_1_bits_0_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[3] && cu_s1_io_pseudoError_1_bits_0_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[4] && cu_s1_io_pseudoError_1_bits_0_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[5] && cu_s1_io_pseudoError_1_bits_0_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[6] && cu_s1_io_pseudoError_1_bits_0_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[7] && cu_s1_io_pseudoError_1_bits_0_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[8] && cu_s1_io_pseudoError_1_bits_0_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[9] && cu_s1_io_pseudoError_1_bits_0_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[10] && cu_s1_io_pseudoError_1_bits_0_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[11] && cu_s1_io_pseudoError_1_bits_0_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[12] && cu_s1_io_pseudoError_1_bits_0_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[13] && cu_s1_io_pseudoError_1_bits_0_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[14] && cu_s1_io_pseudoError_1_bits_0_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[15] && cu_s1_io_pseudoError_1_bits_0_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[16] && cu_s1_io_pseudoError_1_bits_0_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[17] && cu_s1_io_pseudoError_1_bits_0_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[18] && cu_s1_io_pseudoError_1_bits_0_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[19] && cu_s1_io_pseudoError_1_bits_0_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[20] && cu_s1_io_pseudoError_1_bits_0_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[21] && cu_s1_io_pseudoError_1_bits_0_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[22] && cu_s1_io_pseudoError_1_bits_0_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[23] && cu_s1_io_pseudoError_1_bits_0_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[24] && cu_s1_io_pseudoError_1_bits_0_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[25] && cu_s1_io_pseudoError_1_bits_0_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[26] && cu_s1_io_pseudoError_1_bits_0_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[27] && cu_s1_io_pseudoError_1_bits_0_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[28] && cu_s1_io_pseudoError_1_bits_0_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[29] && cu_s1_io_pseudoError_1_bits_0_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[30] && cu_s1_io_pseudoError_1_bits_0_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[31] && cu_s1_io_pseudoError_1_bits_0_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[32] && cu_s1_io_pseudoError_1_bits_0_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[33] && cu_s1_io_pseudoError_1_bits_0_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[34] && cu_s1_io_pseudoError_1_bits_0_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[35] && cu_s1_io_pseudoError_1_bits_0_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[36] && cu_s1_io_pseudoError_1_bits_0_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[37] && cu_s1_io_pseudoError_1_bits_0_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[38] && cu_s1_io_pseudoError_1_bits_0_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[39] && cu_s1_io_pseudoError_1_bits_0_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[40] && cu_s1_io_pseudoError_1_bits_0_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[41] && cu_s1_io_pseudoError_1_bits_0_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[42] && cu_s1_io_pseudoError_1_bits_0_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[43] && cu_s1_io_pseudoError_1_bits_0_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[44] && cu_s1_io_pseudoError_1_bits_0_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[45] && cu_s1_io_pseudoError_1_bits_0_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[46] && cu_s1_io_pseudoError_1_bits_0_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[47] && cu_s1_io_pseudoError_1_bits_0_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[48] && cu_s1_io_pseudoError_1_bits_0_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[49] && cu_s1_io_pseudoError_1_bits_0_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[50] && cu_s1_io_pseudoError_1_bits_0_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[51] && cu_s1_io_pseudoError_1_bits_0_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[52] && cu_s1_io_pseudoError_1_bits_0_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[53] && cu_s1_io_pseudoError_1_bits_0_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[54] && cu_s1_io_pseudoError_1_bits_0_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[55] && cu_s1_io_pseudoError_1_bits_0_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[56] && cu_s1_io_pseudoError_1_bits_0_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[57] && cu_s1_io_pseudoError_1_bits_0_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[58] && cu_s1_io_pseudoError_1_bits_0_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[59] && cu_s1_io_pseudoError_1_bits_0_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[60] && cu_s1_io_pseudoError_1_bits_0_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[61] && cu_s1_io_pseudoError_1_bits_0_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[62] && cu_s1_io_pseudoError_1_bits_0_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_0_mask[63] && cu_s1_io_pseudoError_1_bits_0_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_0_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_valid && cu_s1_io_pseudoError_1_bits_1_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[0] && cu_s1_io_pseudoError_1_bits_1_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[1] && cu_s1_io_pseudoError_1_bits_1_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[2] && cu_s1_io_pseudoError_1_bits_1_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[3] && cu_s1_io_pseudoError_1_bits_1_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[4] && cu_s1_io_pseudoError_1_bits_1_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[5] && cu_s1_io_pseudoError_1_bits_1_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[6] && cu_s1_io_pseudoError_1_bits_1_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[7] && cu_s1_io_pseudoError_1_bits_1_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[8] && cu_s1_io_pseudoError_1_bits_1_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[9] && cu_s1_io_pseudoError_1_bits_1_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[10] && cu_s1_io_pseudoError_1_bits_1_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[11] && cu_s1_io_pseudoError_1_bits_1_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[12] && cu_s1_io_pseudoError_1_bits_1_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[13] && cu_s1_io_pseudoError_1_bits_1_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[14] && cu_s1_io_pseudoError_1_bits_1_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[15] && cu_s1_io_pseudoError_1_bits_1_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[16] && cu_s1_io_pseudoError_1_bits_1_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[17] && cu_s1_io_pseudoError_1_bits_1_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[18] && cu_s1_io_pseudoError_1_bits_1_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[19] && cu_s1_io_pseudoError_1_bits_1_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[20] && cu_s1_io_pseudoError_1_bits_1_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[21] && cu_s1_io_pseudoError_1_bits_1_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[22] && cu_s1_io_pseudoError_1_bits_1_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[23] && cu_s1_io_pseudoError_1_bits_1_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[24] && cu_s1_io_pseudoError_1_bits_1_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[25] && cu_s1_io_pseudoError_1_bits_1_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[26] && cu_s1_io_pseudoError_1_bits_1_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[27] && cu_s1_io_pseudoError_1_bits_1_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[28] && cu_s1_io_pseudoError_1_bits_1_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[29] && cu_s1_io_pseudoError_1_bits_1_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[30] && cu_s1_io_pseudoError_1_bits_1_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[31] && cu_s1_io_pseudoError_1_bits_1_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[32] && cu_s1_io_pseudoError_1_bits_1_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[33] && cu_s1_io_pseudoError_1_bits_1_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[34] && cu_s1_io_pseudoError_1_bits_1_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[35] && cu_s1_io_pseudoError_1_bits_1_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[36] && cu_s1_io_pseudoError_1_bits_1_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[37] && cu_s1_io_pseudoError_1_bits_1_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[38] && cu_s1_io_pseudoError_1_bits_1_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[39] && cu_s1_io_pseudoError_1_bits_1_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[40] && cu_s1_io_pseudoError_1_bits_1_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[41] && cu_s1_io_pseudoError_1_bits_1_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[42] && cu_s1_io_pseudoError_1_bits_1_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[43] && cu_s1_io_pseudoError_1_bits_1_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[44] && cu_s1_io_pseudoError_1_bits_1_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[45] && cu_s1_io_pseudoError_1_bits_1_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[46] && cu_s1_io_pseudoError_1_bits_1_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[47] && cu_s1_io_pseudoError_1_bits_1_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[48] && cu_s1_io_pseudoError_1_bits_1_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[49] && cu_s1_io_pseudoError_1_bits_1_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[50] && cu_s1_io_pseudoError_1_bits_1_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[51] && cu_s1_io_pseudoError_1_bits_1_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[52] && cu_s1_io_pseudoError_1_bits_1_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[53] && cu_s1_io_pseudoError_1_bits_1_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[54] && cu_s1_io_pseudoError_1_bits_1_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[55] && cu_s1_io_pseudoError_1_bits_1_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[56] && cu_s1_io_pseudoError_1_bits_1_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[57] && cu_s1_io_pseudoError_1_bits_1_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[58] && cu_s1_io_pseudoError_1_bits_1_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[59] && cu_s1_io_pseudoError_1_bits_1_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[60] && cu_s1_io_pseudoError_1_bits_1_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[61] && cu_s1_io_pseudoError_1_bits_1_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[62] && cu_s1_io_pseudoError_1_bits_1_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_1_mask[63] && cu_s1_io_pseudoError_1_bits_1_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_1_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_valid && cu_s1_io_pseudoError_1_bits_2_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[0] && cu_s1_io_pseudoError_1_bits_2_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[1] && cu_s1_io_pseudoError_1_bits_2_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[2] && cu_s1_io_pseudoError_1_bits_2_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[3] && cu_s1_io_pseudoError_1_bits_2_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[4] && cu_s1_io_pseudoError_1_bits_2_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[5] && cu_s1_io_pseudoError_1_bits_2_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[6] && cu_s1_io_pseudoError_1_bits_2_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[7] && cu_s1_io_pseudoError_1_bits_2_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[8] && cu_s1_io_pseudoError_1_bits_2_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[9] && cu_s1_io_pseudoError_1_bits_2_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[10] && cu_s1_io_pseudoError_1_bits_2_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[11] && cu_s1_io_pseudoError_1_bits_2_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[12] && cu_s1_io_pseudoError_1_bits_2_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[13] && cu_s1_io_pseudoError_1_bits_2_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[14] && cu_s1_io_pseudoError_1_bits_2_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[15] && cu_s1_io_pseudoError_1_bits_2_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[16] && cu_s1_io_pseudoError_1_bits_2_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[17] && cu_s1_io_pseudoError_1_bits_2_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[18] && cu_s1_io_pseudoError_1_bits_2_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[19] && cu_s1_io_pseudoError_1_bits_2_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[20] && cu_s1_io_pseudoError_1_bits_2_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[21] && cu_s1_io_pseudoError_1_bits_2_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[22] && cu_s1_io_pseudoError_1_bits_2_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[23] && cu_s1_io_pseudoError_1_bits_2_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[24] && cu_s1_io_pseudoError_1_bits_2_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[25] && cu_s1_io_pseudoError_1_bits_2_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[26] && cu_s1_io_pseudoError_1_bits_2_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[27] && cu_s1_io_pseudoError_1_bits_2_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[28] && cu_s1_io_pseudoError_1_bits_2_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[29] && cu_s1_io_pseudoError_1_bits_2_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[30] && cu_s1_io_pseudoError_1_bits_2_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[31] && cu_s1_io_pseudoError_1_bits_2_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[32] && cu_s1_io_pseudoError_1_bits_2_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[33] && cu_s1_io_pseudoError_1_bits_2_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[34] && cu_s1_io_pseudoError_1_bits_2_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[35] && cu_s1_io_pseudoError_1_bits_2_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[36] && cu_s1_io_pseudoError_1_bits_2_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[37] && cu_s1_io_pseudoError_1_bits_2_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[38] && cu_s1_io_pseudoError_1_bits_2_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[39] && cu_s1_io_pseudoError_1_bits_2_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[40] && cu_s1_io_pseudoError_1_bits_2_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[41] && cu_s1_io_pseudoError_1_bits_2_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[42] && cu_s1_io_pseudoError_1_bits_2_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[43] && cu_s1_io_pseudoError_1_bits_2_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[44] && cu_s1_io_pseudoError_1_bits_2_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[45] && cu_s1_io_pseudoError_1_bits_2_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[46] && cu_s1_io_pseudoError_1_bits_2_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[47] && cu_s1_io_pseudoError_1_bits_2_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[48] && cu_s1_io_pseudoError_1_bits_2_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[49] && cu_s1_io_pseudoError_1_bits_2_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[50] && cu_s1_io_pseudoError_1_bits_2_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[51] && cu_s1_io_pseudoError_1_bits_2_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[52] && cu_s1_io_pseudoError_1_bits_2_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[53] && cu_s1_io_pseudoError_1_bits_2_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[54] && cu_s1_io_pseudoError_1_bits_2_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[55] && cu_s1_io_pseudoError_1_bits_2_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[56] && cu_s1_io_pseudoError_1_bits_2_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[57] && cu_s1_io_pseudoError_1_bits_2_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[58] && cu_s1_io_pseudoError_1_bits_2_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[59] && cu_s1_io_pseudoError_1_bits_2_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[60] && cu_s1_io_pseudoError_1_bits_2_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[61] && cu_s1_io_pseudoError_1_bits_2_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[62] && cu_s1_io_pseudoError_1_bits_2_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_2_mask[63] && cu_s1_io_pseudoError_1_bits_2_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_2_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_valid && cu_s1_io_pseudoError_1_bits_3_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[0] && cu_s1_io_pseudoError_1_bits_3_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[1] && cu_s1_io_pseudoError_1_bits_3_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[2] && cu_s1_io_pseudoError_1_bits_3_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[3] && cu_s1_io_pseudoError_1_bits_3_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[4] && cu_s1_io_pseudoError_1_bits_3_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[5] && cu_s1_io_pseudoError_1_bits_3_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[6] && cu_s1_io_pseudoError_1_bits_3_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[7] && cu_s1_io_pseudoError_1_bits_3_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[8] && cu_s1_io_pseudoError_1_bits_3_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[9] && cu_s1_io_pseudoError_1_bits_3_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[10] && cu_s1_io_pseudoError_1_bits_3_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[11] && cu_s1_io_pseudoError_1_bits_3_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[12] && cu_s1_io_pseudoError_1_bits_3_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[13] && cu_s1_io_pseudoError_1_bits_3_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[14] && cu_s1_io_pseudoError_1_bits_3_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[15] && cu_s1_io_pseudoError_1_bits_3_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[16] && cu_s1_io_pseudoError_1_bits_3_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[17] && cu_s1_io_pseudoError_1_bits_3_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[18] && cu_s1_io_pseudoError_1_bits_3_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[19] && cu_s1_io_pseudoError_1_bits_3_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[20] && cu_s1_io_pseudoError_1_bits_3_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[21] && cu_s1_io_pseudoError_1_bits_3_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[22] && cu_s1_io_pseudoError_1_bits_3_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[23] && cu_s1_io_pseudoError_1_bits_3_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[24] && cu_s1_io_pseudoError_1_bits_3_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[25] && cu_s1_io_pseudoError_1_bits_3_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[26] && cu_s1_io_pseudoError_1_bits_3_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[27] && cu_s1_io_pseudoError_1_bits_3_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[28] && cu_s1_io_pseudoError_1_bits_3_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[29] && cu_s1_io_pseudoError_1_bits_3_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[30] && cu_s1_io_pseudoError_1_bits_3_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[31] && cu_s1_io_pseudoError_1_bits_3_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[32] && cu_s1_io_pseudoError_1_bits_3_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[33] && cu_s1_io_pseudoError_1_bits_3_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[34] && cu_s1_io_pseudoError_1_bits_3_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[35] && cu_s1_io_pseudoError_1_bits_3_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[36] && cu_s1_io_pseudoError_1_bits_3_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[37] && cu_s1_io_pseudoError_1_bits_3_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[38] && cu_s1_io_pseudoError_1_bits_3_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[39] && cu_s1_io_pseudoError_1_bits_3_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[40] && cu_s1_io_pseudoError_1_bits_3_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[41] && cu_s1_io_pseudoError_1_bits_3_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[42] && cu_s1_io_pseudoError_1_bits_3_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[43] && cu_s1_io_pseudoError_1_bits_3_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[44] && cu_s1_io_pseudoError_1_bits_3_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[45] && cu_s1_io_pseudoError_1_bits_3_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[46] && cu_s1_io_pseudoError_1_bits_3_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[47] && cu_s1_io_pseudoError_1_bits_3_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[48] && cu_s1_io_pseudoError_1_bits_3_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[49] && cu_s1_io_pseudoError_1_bits_3_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[50] && cu_s1_io_pseudoError_1_bits_3_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[51] && cu_s1_io_pseudoError_1_bits_3_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[52] && cu_s1_io_pseudoError_1_bits_3_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[53] && cu_s1_io_pseudoError_1_bits_3_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[54] && cu_s1_io_pseudoError_1_bits_3_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[55] && cu_s1_io_pseudoError_1_bits_3_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[56] && cu_s1_io_pseudoError_1_bits_3_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[57] && cu_s1_io_pseudoError_1_bits_3_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[58] && cu_s1_io_pseudoError_1_bits_3_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[59] && cu_s1_io_pseudoError_1_bits_3_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[60] && cu_s1_io_pseudoError_1_bits_3_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[61] && cu_s1_io_pseudoError_1_bits_3_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[62] && cu_s1_io_pseudoError_1_bits_3_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_3_mask[63] && cu_s1_io_pseudoError_1_bits_3_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_3_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_valid && cu_s1_io_pseudoError_1_bits_4_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[0] && cu_s1_io_pseudoError_1_bits_4_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[1] && cu_s1_io_pseudoError_1_bits_4_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[2] && cu_s1_io_pseudoError_1_bits_4_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[3] && cu_s1_io_pseudoError_1_bits_4_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[4] && cu_s1_io_pseudoError_1_bits_4_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[5] && cu_s1_io_pseudoError_1_bits_4_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[6] && cu_s1_io_pseudoError_1_bits_4_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[7] && cu_s1_io_pseudoError_1_bits_4_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[8] && cu_s1_io_pseudoError_1_bits_4_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[9] && cu_s1_io_pseudoError_1_bits_4_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[10] && cu_s1_io_pseudoError_1_bits_4_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[11] && cu_s1_io_pseudoError_1_bits_4_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[12] && cu_s1_io_pseudoError_1_bits_4_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[13] && cu_s1_io_pseudoError_1_bits_4_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[14] && cu_s1_io_pseudoError_1_bits_4_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[15] && cu_s1_io_pseudoError_1_bits_4_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[16] && cu_s1_io_pseudoError_1_bits_4_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[17] && cu_s1_io_pseudoError_1_bits_4_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[18] && cu_s1_io_pseudoError_1_bits_4_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[19] && cu_s1_io_pseudoError_1_bits_4_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[20] && cu_s1_io_pseudoError_1_bits_4_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[21] && cu_s1_io_pseudoError_1_bits_4_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[22] && cu_s1_io_pseudoError_1_bits_4_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[23] && cu_s1_io_pseudoError_1_bits_4_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[24] && cu_s1_io_pseudoError_1_bits_4_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[25] && cu_s1_io_pseudoError_1_bits_4_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[26] && cu_s1_io_pseudoError_1_bits_4_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[27] && cu_s1_io_pseudoError_1_bits_4_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[28] && cu_s1_io_pseudoError_1_bits_4_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[29] && cu_s1_io_pseudoError_1_bits_4_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[30] && cu_s1_io_pseudoError_1_bits_4_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[31] && cu_s1_io_pseudoError_1_bits_4_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[32] && cu_s1_io_pseudoError_1_bits_4_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[33] && cu_s1_io_pseudoError_1_bits_4_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[34] && cu_s1_io_pseudoError_1_bits_4_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[35] && cu_s1_io_pseudoError_1_bits_4_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[36] && cu_s1_io_pseudoError_1_bits_4_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[37] && cu_s1_io_pseudoError_1_bits_4_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[38] && cu_s1_io_pseudoError_1_bits_4_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[39] && cu_s1_io_pseudoError_1_bits_4_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[40] && cu_s1_io_pseudoError_1_bits_4_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[41] && cu_s1_io_pseudoError_1_bits_4_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[42] && cu_s1_io_pseudoError_1_bits_4_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[43] && cu_s1_io_pseudoError_1_bits_4_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[44] && cu_s1_io_pseudoError_1_bits_4_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[45] && cu_s1_io_pseudoError_1_bits_4_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[46] && cu_s1_io_pseudoError_1_bits_4_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[47] && cu_s1_io_pseudoError_1_bits_4_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[48] && cu_s1_io_pseudoError_1_bits_4_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[49] && cu_s1_io_pseudoError_1_bits_4_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[50] && cu_s1_io_pseudoError_1_bits_4_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[51] && cu_s1_io_pseudoError_1_bits_4_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[52] && cu_s1_io_pseudoError_1_bits_4_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[53] && cu_s1_io_pseudoError_1_bits_4_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[54] && cu_s1_io_pseudoError_1_bits_4_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[55] && cu_s1_io_pseudoError_1_bits_4_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[56] && cu_s1_io_pseudoError_1_bits_4_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[57] && cu_s1_io_pseudoError_1_bits_4_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[58] && cu_s1_io_pseudoError_1_bits_4_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[59] && cu_s1_io_pseudoError_1_bits_4_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[60] && cu_s1_io_pseudoError_1_bits_4_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[61] && cu_s1_io_pseudoError_1_bits_4_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[62] && cu_s1_io_pseudoError_1_bits_4_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_4_mask[63] && cu_s1_io_pseudoError_1_bits_4_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_4_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_valid && cu_s1_io_pseudoError_1_bits_5_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[0] && cu_s1_io_pseudoError_1_bits_5_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[1] && cu_s1_io_pseudoError_1_bits_5_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[2] && cu_s1_io_pseudoError_1_bits_5_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[3] && cu_s1_io_pseudoError_1_bits_5_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[4] && cu_s1_io_pseudoError_1_bits_5_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[5] && cu_s1_io_pseudoError_1_bits_5_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[6] && cu_s1_io_pseudoError_1_bits_5_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[7] && cu_s1_io_pseudoError_1_bits_5_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[8] && cu_s1_io_pseudoError_1_bits_5_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[9] && cu_s1_io_pseudoError_1_bits_5_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[10] && cu_s1_io_pseudoError_1_bits_5_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[11] && cu_s1_io_pseudoError_1_bits_5_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[12] && cu_s1_io_pseudoError_1_bits_5_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[13] && cu_s1_io_pseudoError_1_bits_5_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[14] && cu_s1_io_pseudoError_1_bits_5_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[15] && cu_s1_io_pseudoError_1_bits_5_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[16] && cu_s1_io_pseudoError_1_bits_5_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[17] && cu_s1_io_pseudoError_1_bits_5_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[18] && cu_s1_io_pseudoError_1_bits_5_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[19] && cu_s1_io_pseudoError_1_bits_5_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[20] && cu_s1_io_pseudoError_1_bits_5_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[21] && cu_s1_io_pseudoError_1_bits_5_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[22] && cu_s1_io_pseudoError_1_bits_5_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[23] && cu_s1_io_pseudoError_1_bits_5_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[24] && cu_s1_io_pseudoError_1_bits_5_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[25] && cu_s1_io_pseudoError_1_bits_5_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[26] && cu_s1_io_pseudoError_1_bits_5_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[27] && cu_s1_io_pseudoError_1_bits_5_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[28] && cu_s1_io_pseudoError_1_bits_5_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[29] && cu_s1_io_pseudoError_1_bits_5_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[30] && cu_s1_io_pseudoError_1_bits_5_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[31] && cu_s1_io_pseudoError_1_bits_5_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[32] && cu_s1_io_pseudoError_1_bits_5_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[33] && cu_s1_io_pseudoError_1_bits_5_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[34] && cu_s1_io_pseudoError_1_bits_5_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[35] && cu_s1_io_pseudoError_1_bits_5_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[36] && cu_s1_io_pseudoError_1_bits_5_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[37] && cu_s1_io_pseudoError_1_bits_5_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[38] && cu_s1_io_pseudoError_1_bits_5_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[39] && cu_s1_io_pseudoError_1_bits_5_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[40] && cu_s1_io_pseudoError_1_bits_5_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[41] && cu_s1_io_pseudoError_1_bits_5_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[42] && cu_s1_io_pseudoError_1_bits_5_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[43] && cu_s1_io_pseudoError_1_bits_5_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[44] && cu_s1_io_pseudoError_1_bits_5_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[45] && cu_s1_io_pseudoError_1_bits_5_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[46] && cu_s1_io_pseudoError_1_bits_5_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[47] && cu_s1_io_pseudoError_1_bits_5_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[48] && cu_s1_io_pseudoError_1_bits_5_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[49] && cu_s1_io_pseudoError_1_bits_5_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[50] && cu_s1_io_pseudoError_1_bits_5_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[51] && cu_s1_io_pseudoError_1_bits_5_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[52] && cu_s1_io_pseudoError_1_bits_5_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[53] && cu_s1_io_pseudoError_1_bits_5_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[54] && cu_s1_io_pseudoError_1_bits_5_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[55] && cu_s1_io_pseudoError_1_bits_5_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[56] && cu_s1_io_pseudoError_1_bits_5_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[57] && cu_s1_io_pseudoError_1_bits_5_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[58] && cu_s1_io_pseudoError_1_bits_5_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[59] && cu_s1_io_pseudoError_1_bits_5_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[60] && cu_s1_io_pseudoError_1_bits_5_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[61] && cu_s1_io_pseudoError_1_bits_5_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[62] && cu_s1_io_pseudoError_1_bits_5_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_5_mask[63] && cu_s1_io_pseudoError_1_bits_5_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_5_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_valid && cu_s1_io_pseudoError_1_bits_6_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[0] && cu_s1_io_pseudoError_1_bits_6_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[1] && cu_s1_io_pseudoError_1_bits_6_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[2] && cu_s1_io_pseudoError_1_bits_6_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[3] && cu_s1_io_pseudoError_1_bits_6_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[4] && cu_s1_io_pseudoError_1_bits_6_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[5] && cu_s1_io_pseudoError_1_bits_6_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[6] && cu_s1_io_pseudoError_1_bits_6_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[7] && cu_s1_io_pseudoError_1_bits_6_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[8] && cu_s1_io_pseudoError_1_bits_6_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[9] && cu_s1_io_pseudoError_1_bits_6_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[10] && cu_s1_io_pseudoError_1_bits_6_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[11] && cu_s1_io_pseudoError_1_bits_6_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[12] && cu_s1_io_pseudoError_1_bits_6_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[13] && cu_s1_io_pseudoError_1_bits_6_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[14] && cu_s1_io_pseudoError_1_bits_6_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[15] && cu_s1_io_pseudoError_1_bits_6_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[16] && cu_s1_io_pseudoError_1_bits_6_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[17] && cu_s1_io_pseudoError_1_bits_6_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[18] && cu_s1_io_pseudoError_1_bits_6_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[19] && cu_s1_io_pseudoError_1_bits_6_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[20] && cu_s1_io_pseudoError_1_bits_6_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[21] && cu_s1_io_pseudoError_1_bits_6_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[22] && cu_s1_io_pseudoError_1_bits_6_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[23] && cu_s1_io_pseudoError_1_bits_6_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[24] && cu_s1_io_pseudoError_1_bits_6_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[25] && cu_s1_io_pseudoError_1_bits_6_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[26] && cu_s1_io_pseudoError_1_bits_6_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[27] && cu_s1_io_pseudoError_1_bits_6_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[28] && cu_s1_io_pseudoError_1_bits_6_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[29] && cu_s1_io_pseudoError_1_bits_6_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[30] && cu_s1_io_pseudoError_1_bits_6_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[31] && cu_s1_io_pseudoError_1_bits_6_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[32] && cu_s1_io_pseudoError_1_bits_6_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[33] && cu_s1_io_pseudoError_1_bits_6_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[34] && cu_s1_io_pseudoError_1_bits_6_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[35] && cu_s1_io_pseudoError_1_bits_6_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[36] && cu_s1_io_pseudoError_1_bits_6_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[37] && cu_s1_io_pseudoError_1_bits_6_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[38] && cu_s1_io_pseudoError_1_bits_6_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[39] && cu_s1_io_pseudoError_1_bits_6_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[40] && cu_s1_io_pseudoError_1_bits_6_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[41] && cu_s1_io_pseudoError_1_bits_6_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[42] && cu_s1_io_pseudoError_1_bits_6_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[43] && cu_s1_io_pseudoError_1_bits_6_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[44] && cu_s1_io_pseudoError_1_bits_6_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[45] && cu_s1_io_pseudoError_1_bits_6_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[46] && cu_s1_io_pseudoError_1_bits_6_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[47] && cu_s1_io_pseudoError_1_bits_6_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[48] && cu_s1_io_pseudoError_1_bits_6_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[49] && cu_s1_io_pseudoError_1_bits_6_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[50] && cu_s1_io_pseudoError_1_bits_6_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[51] && cu_s1_io_pseudoError_1_bits_6_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[52] && cu_s1_io_pseudoError_1_bits_6_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[53] && cu_s1_io_pseudoError_1_bits_6_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[54] && cu_s1_io_pseudoError_1_bits_6_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[55] && cu_s1_io_pseudoError_1_bits_6_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[56] && cu_s1_io_pseudoError_1_bits_6_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[57] && cu_s1_io_pseudoError_1_bits_6_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[58] && cu_s1_io_pseudoError_1_bits_6_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[59] && cu_s1_io_pseudoError_1_bits_6_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[60] && cu_s1_io_pseudoError_1_bits_6_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[61] && cu_s1_io_pseudoError_1_bits_6_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[62] && cu_s1_io_pseudoError_1_bits_6_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_6_mask[63] && cu_s1_io_pseudoError_1_bits_6_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_6_mask[63] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_valid && cu_s1_io_pseudoError_1_bits_7_valid)) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_valid 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[0] && cu_s1_io_pseudoError_1_bits_7_mask[0])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[0] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[1] && cu_s1_io_pseudoError_1_bits_7_mask[1])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[1] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[2] && cu_s1_io_pseudoError_1_bits_7_mask[2])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[2] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[3] && cu_s1_io_pseudoError_1_bits_7_mask[3])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[3] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[4] && cu_s1_io_pseudoError_1_bits_7_mask[4])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[4] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[5] && cu_s1_io_pseudoError_1_bits_7_mask[5])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[5] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[6] && cu_s1_io_pseudoError_1_bits_7_mask[6])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[6] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[7] && cu_s1_io_pseudoError_1_bits_7_mask[7])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[7] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[8] && cu_s1_io_pseudoError_1_bits_7_mask[8])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[8] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[9] && cu_s1_io_pseudoError_1_bits_7_mask[9])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[9] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[10] && cu_s1_io_pseudoError_1_bits_7_mask[10])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[10] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[11] && cu_s1_io_pseudoError_1_bits_7_mask[11])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[11] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[12] && cu_s1_io_pseudoError_1_bits_7_mask[12])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[12] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[13] && cu_s1_io_pseudoError_1_bits_7_mask[13])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[13] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[14] && cu_s1_io_pseudoError_1_bits_7_mask[14])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[14] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[15] && cu_s1_io_pseudoError_1_bits_7_mask[15])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[15] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[16] && cu_s1_io_pseudoError_1_bits_7_mask[16])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[16] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[17] && cu_s1_io_pseudoError_1_bits_7_mask[17])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[17] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[18] && cu_s1_io_pseudoError_1_bits_7_mask[18])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[18] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[19] && cu_s1_io_pseudoError_1_bits_7_mask[19])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[19] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[20] && cu_s1_io_pseudoError_1_bits_7_mask[20])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[20] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[21] && cu_s1_io_pseudoError_1_bits_7_mask[21])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[21] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[22] && cu_s1_io_pseudoError_1_bits_7_mask[22])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[22] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[23] && cu_s1_io_pseudoError_1_bits_7_mask[23])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[23] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[24] && cu_s1_io_pseudoError_1_bits_7_mask[24])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[24] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[25] && cu_s1_io_pseudoError_1_bits_7_mask[25])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[25] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[26] && cu_s1_io_pseudoError_1_bits_7_mask[26])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[26] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[27] && cu_s1_io_pseudoError_1_bits_7_mask[27])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[27] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[28] && cu_s1_io_pseudoError_1_bits_7_mask[28])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[28] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[29] && cu_s1_io_pseudoError_1_bits_7_mask[29])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[29] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[30] && cu_s1_io_pseudoError_1_bits_7_mask[30])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[30] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[31] && cu_s1_io_pseudoError_1_bits_7_mask[31])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[31] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[32] && cu_s1_io_pseudoError_1_bits_7_mask[32])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[32] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[33] && cu_s1_io_pseudoError_1_bits_7_mask[33])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[33] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[34] && cu_s1_io_pseudoError_1_bits_7_mask[34])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[34] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[35] && cu_s1_io_pseudoError_1_bits_7_mask[35])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[35] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[36] && cu_s1_io_pseudoError_1_bits_7_mask[36])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[36] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[37] && cu_s1_io_pseudoError_1_bits_7_mask[37])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[37] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[38] && cu_s1_io_pseudoError_1_bits_7_mask[38])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[38] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[39] && cu_s1_io_pseudoError_1_bits_7_mask[39])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[39] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[40] && cu_s1_io_pseudoError_1_bits_7_mask[40])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[40] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[41] && cu_s1_io_pseudoError_1_bits_7_mask[41])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[41] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[42] && cu_s1_io_pseudoError_1_bits_7_mask[42])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[42] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[43] && cu_s1_io_pseudoError_1_bits_7_mask[43])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[43] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[44] && cu_s1_io_pseudoError_1_bits_7_mask[44])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[44] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[45] && cu_s1_io_pseudoError_1_bits_7_mask[45])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[45] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[46] && cu_s1_io_pseudoError_1_bits_7_mask[46])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[46] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[47] && cu_s1_io_pseudoError_1_bits_7_mask[47])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[47] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[48] && cu_s1_io_pseudoError_1_bits_7_mask[48])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[48] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[49] && cu_s1_io_pseudoError_1_bits_7_mask[49])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[49] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[50] && cu_s1_io_pseudoError_1_bits_7_mask[50])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[50] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[51] && cu_s1_io_pseudoError_1_bits_7_mask[51])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[51] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[52] && cu_s1_io_pseudoError_1_bits_7_mask[52])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[52] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[53] && cu_s1_io_pseudoError_1_bits_7_mask[53])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[53] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[54] && cu_s1_io_pseudoError_1_bits_7_mask[54])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[54] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[55] && cu_s1_io_pseudoError_1_bits_7_mask[55])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[55] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[56] && cu_s1_io_pseudoError_1_bits_7_mask[56])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[56] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[57] && cu_s1_io_pseudoError_1_bits_7_mask[57])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[57] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[58] && cu_s1_io_pseudoError_1_bits_7_mask[58])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[58] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[59] && cu_s1_io_pseudoError_1_bits_7_mask[59])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[59] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[60] && cu_s1_io_pseudoError_1_bits_7_mask[60])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[60] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[61] && cu_s1_io_pseudoError_1_bits_7_mask[61])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[61] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[62] && cu_s1_io_pseudoError_1_bits_7_mask[62])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[62] 未见过 0 和 1"); end
    if (!(cu_s0_io_pseudoError_1_bits_7_mask[63] && cu_s1_io_pseudoError_1_bits_7_mask[63])) begin cov_fail++; $display("[COV] CtrlUnit.io_pseudoError_1_bits_7_mask[63] 未见过 0 和 1"); end
    $display("[ARM] CtrlUnit armed_at=%0d", cu_armed_at);
    if (cu_armed_at < 0) begin cov_fail++; $display("[ARM] CtrlUnit 从未 arm"); end
    $display("[COV] CtrlUnit.fire_tag = %0d", cu_cov_fire_tag);
    if (cu_cov_fire_tag < 100) begin cov_fail++; $display("[COV] CtrlUnit.fire_tag < 100"); end
    $display("[COV] CtrlUnit.fire_data = %0d", cu_cov_fire_data);
    if (cu_cov_fire_data < 100) begin cov_fail++; $display("[COV] CtrlUnit.fire_data < 100"); end
    $display("[COV] CtrlUnit.count_down = %0d", cu_cov_count_down);
    if (cu_cov_count_down < 100) begin cov_fail++; $display("[COV] CtrlUnit.count_down < 100"); end
    $display("[COV] CtrlUnit.reload_persist = %0d", cu_cov_reload_persist);
    if (cu_cov_reload_persist < 100) begin cov_fail++; $display("[COV] CtrlUnit.reload_persist < 100"); end
    $display("[COV] CtrlUnit.write_ctrl = %0d", cu_cov_write_ctrl);
    if (cu_cov_write_ctrl < 100) begin cov_fail++; $display("[COV] CtrlUnit.write_ctrl < 100"); end
    $display("[COV] CtrlUnit.write_delay = %0d", cu_cov_write_delay);
    if (cu_cov_write_delay < 100) begin cov_fail++; $display("[COV] CtrlUnit.write_delay < 100"); end
    $display("[COV] CtrlUnit.write_mask7 = %0d", cu_cov_write_mask7);
    if (cu_cov_write_mask7 < 100) begin cov_fail++; $display("[COV] CtrlUnit.write_mask7 < 100"); end
    $display("[COV] CtrlUnit.write_partial = %0d", cu_cov_write_partial);
    if (cu_cov_write_partial < 100) begin cov_fail++; $display("[COV] CtrlUnit.write_partial < 100"); end
    $display("[COV] CtrlUnit.read = %0d", cu_cov_read);
    if (cu_cov_read < 100) begin cov_fail++; $display("[COV] CtrlUnit.read < 100"); end
    $display("[COV] CtrlUnit.out0_stall = %0d", cu_cov_out0_stall);
    if (cu_cov_out0_stall < 100) begin cov_fail++; $display("[COV] CtrlUnit.out0_stall < 100"); end
    $display("[COV] CtrlUnit.out1_stall = %0d", cu_cov_out1_stall);
    if (cu_cov_out1_stall < 100) begin cov_fail++; $display("[COV] CtrlUnit.out1_stall < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
