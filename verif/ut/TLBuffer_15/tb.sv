// tb —— TLBuffer_15：L2Top 的 64 位 TL-UL A/D 两通道缓冲（inner_i_mmio_buffer / inner_buffers*）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= TLBuffer_15 =================
  int unsigned tlb_mode = 0;
  logic tlb_reset;
  wire  tlb_g_auto_in_a_ready, tlb_i_auto_in_a_ready;
  logic tlb_s0_auto_in_a_ready = '0, tlb_s1_auto_in_a_ready = '0;
  logic tlb_auto_in_a_valid;
  logic [3:0] tlb_auto_in_a_bits_opcode;
  logic [2:0] tlb_auto_in_a_bits_param;
  logic [1:0] tlb_auto_in_a_bits_size;
  logic tlb_auto_in_a_bits_source;
  logic [47:0] tlb_auto_in_a_bits_address;
  logic tlb_auto_in_a_bits_user_memPageType_NC;
  logic tlb_auto_in_a_bits_user_memBackType_MM;
  logic [7:0] tlb_auto_in_a_bits_mask;
  logic [63:0] tlb_auto_in_a_bits_data;
  logic tlb_auto_in_a_bits_corrupt;
  logic tlb_auto_in_d_ready;
  wire  tlb_g_auto_in_d_valid, tlb_i_auto_in_d_valid;
  logic tlb_s0_auto_in_d_valid = '0, tlb_s1_auto_in_d_valid = '0;
  wire  [3:0] tlb_g_auto_in_d_bits_opcode, tlb_i_auto_in_d_bits_opcode;
  logic [3:0] tlb_s0_auto_in_d_bits_opcode = '0, tlb_s1_auto_in_d_bits_opcode = '0;
  wire  [1:0] tlb_g_auto_in_d_bits_param, tlb_i_auto_in_d_bits_param;
  logic [1:0] tlb_s0_auto_in_d_bits_param = '0, tlb_s1_auto_in_d_bits_param = '0;
  wire  [1:0] tlb_g_auto_in_d_bits_size, tlb_i_auto_in_d_bits_size;
  logic [1:0] tlb_s0_auto_in_d_bits_size = '0, tlb_s1_auto_in_d_bits_size = '0;
  wire  tlb_g_auto_in_d_bits_source, tlb_i_auto_in_d_bits_source;
  logic tlb_s0_auto_in_d_bits_source = '0, tlb_s1_auto_in_d_bits_source = '0;
  wire  tlb_g_auto_in_d_bits_sink, tlb_i_auto_in_d_bits_sink;
  logic tlb_s0_auto_in_d_bits_sink = '0, tlb_s1_auto_in_d_bits_sink = '0;
  wire  tlb_g_auto_in_d_bits_denied, tlb_i_auto_in_d_bits_denied;
  logic tlb_s0_auto_in_d_bits_denied = '0, tlb_s1_auto_in_d_bits_denied = '0;
  wire  [63:0] tlb_g_auto_in_d_bits_data, tlb_i_auto_in_d_bits_data;
  logic [63:0] tlb_s0_auto_in_d_bits_data = '0, tlb_s1_auto_in_d_bits_data = '0;
  wire  tlb_g_auto_in_d_bits_corrupt, tlb_i_auto_in_d_bits_corrupt;
  logic tlb_s0_auto_in_d_bits_corrupt = '0, tlb_s1_auto_in_d_bits_corrupt = '0;
  logic tlb_auto_out_a_ready;
  wire  tlb_g_auto_out_a_valid, tlb_i_auto_out_a_valid;
  logic tlb_s0_auto_out_a_valid = '0, tlb_s1_auto_out_a_valid = '0;
  wire  [3:0] tlb_g_auto_out_a_bits_opcode, tlb_i_auto_out_a_bits_opcode;
  logic [3:0] tlb_s0_auto_out_a_bits_opcode = '0, tlb_s1_auto_out_a_bits_opcode = '0;
  wire  [2:0] tlb_g_auto_out_a_bits_param, tlb_i_auto_out_a_bits_param;
  logic [2:0] tlb_s0_auto_out_a_bits_param = '0, tlb_s1_auto_out_a_bits_param = '0;
  wire  [1:0] tlb_g_auto_out_a_bits_size, tlb_i_auto_out_a_bits_size;
  logic [1:0] tlb_s0_auto_out_a_bits_size = '0, tlb_s1_auto_out_a_bits_size = '0;
  wire  tlb_g_auto_out_a_bits_source, tlb_i_auto_out_a_bits_source;
  logic tlb_s0_auto_out_a_bits_source = '0, tlb_s1_auto_out_a_bits_source = '0;
  wire  [47:0] tlb_g_auto_out_a_bits_address, tlb_i_auto_out_a_bits_address;
  logic [47:0] tlb_s0_auto_out_a_bits_address = '0, tlb_s1_auto_out_a_bits_address = '0;
  wire  tlb_g_auto_out_a_bits_user_memPageType_NC, tlb_i_auto_out_a_bits_user_memPageType_NC;
  logic tlb_s0_auto_out_a_bits_user_memPageType_NC = '0, tlb_s1_auto_out_a_bits_user_memPageType_NC = '0;
  wire  tlb_g_auto_out_a_bits_user_memBackType_MM, tlb_i_auto_out_a_bits_user_memBackType_MM;
  logic tlb_s0_auto_out_a_bits_user_memBackType_MM = '0, tlb_s1_auto_out_a_bits_user_memBackType_MM = '0;
  wire  [7:0] tlb_g_auto_out_a_bits_mask, tlb_i_auto_out_a_bits_mask;
  logic [7:0] tlb_s0_auto_out_a_bits_mask = '0, tlb_s1_auto_out_a_bits_mask = '0;
  wire  [63:0] tlb_g_auto_out_a_bits_data, tlb_i_auto_out_a_bits_data;
  logic [63:0] tlb_s0_auto_out_a_bits_data = '0, tlb_s1_auto_out_a_bits_data = '0;
  wire  tlb_g_auto_out_a_bits_corrupt, tlb_i_auto_out_a_bits_corrupt;
  logic tlb_s0_auto_out_a_bits_corrupt = '0, tlb_s1_auto_out_a_bits_corrupt = '0;
  wire  tlb_g_auto_out_d_ready, tlb_i_auto_out_d_ready;
  logic tlb_s0_auto_out_d_ready = '0, tlb_s1_auto_out_d_ready = '0;
  logic tlb_auto_out_d_valid;
  logic [3:0] tlb_auto_out_d_bits_opcode;
  logic [1:0] tlb_auto_out_d_bits_param;
  logic [1:0] tlb_auto_out_d_bits_size;
  logic tlb_auto_out_d_bits_source;
  logic tlb_auto_out_d_bits_sink;
  logic tlb_auto_out_d_bits_denied;
  logic [63:0] tlb_auto_out_d_bits_data;
  logic tlb_auto_out_d_bits_corrupt;
  int tlb_cov_a_fire_in = 0;
  int tlb_cov_a_fire_out = 0;
  int tlb_cov_d_fire_in = 0;
  int tlb_cov_d_fire_out = 0;
  int tlb_cov_a_full_stall = 0;
  int tlb_cov_d_full_stall = 0;
  int tlb_cov_a_enq_deq_same = 0;
  int tlb_cov_d_enq_deq_same = 0;
  logic [3:0] tlb_armed = '0;
  int tlb_armed_at = -1;
  TLBuffer_15 tlb_u_gold (
    .clock(clk),
    .reset(tlb_reset),
    .auto_in_a_ready(tlb_g_auto_in_a_ready),
    .auto_in_a_valid(tlb_auto_in_a_valid),
    .auto_in_a_bits_opcode(tlb_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(tlb_auto_in_a_bits_param),
    .auto_in_a_bits_size(tlb_auto_in_a_bits_size),
    .auto_in_a_bits_source(tlb_auto_in_a_bits_source),
    .auto_in_a_bits_address(tlb_auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC(tlb_auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM(tlb_auto_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask(tlb_auto_in_a_bits_mask),
    .auto_in_a_bits_data(tlb_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(tlb_auto_in_a_bits_corrupt),
    .auto_in_d_ready(tlb_auto_in_d_ready),
    .auto_in_d_valid(tlb_g_auto_in_d_valid),
    .auto_in_d_bits_opcode(tlb_g_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(tlb_g_auto_in_d_bits_param),
    .auto_in_d_bits_size(tlb_g_auto_in_d_bits_size),
    .auto_in_d_bits_source(tlb_g_auto_in_d_bits_source),
    .auto_in_d_bits_sink(tlb_g_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(tlb_g_auto_in_d_bits_denied),
    .auto_in_d_bits_data(tlb_g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(tlb_g_auto_in_d_bits_corrupt),
    .auto_out_a_ready(tlb_auto_out_a_ready),
    .auto_out_a_valid(tlb_g_auto_out_a_valid),
    .auto_out_a_bits_opcode(tlb_g_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(tlb_g_auto_out_a_bits_param),
    .auto_out_a_bits_size(tlb_g_auto_out_a_bits_size),
    .auto_out_a_bits_source(tlb_g_auto_out_a_bits_source),
    .auto_out_a_bits_address(tlb_g_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC(tlb_g_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM(tlb_g_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask(tlb_g_auto_out_a_bits_mask),
    .auto_out_a_bits_data(tlb_g_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(tlb_g_auto_out_a_bits_corrupt),
    .auto_out_d_ready(tlb_g_auto_out_d_ready),
    .auto_out_d_valid(tlb_auto_out_d_valid),
    .auto_out_d_bits_opcode(tlb_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(tlb_auto_out_d_bits_param),
    .auto_out_d_bits_size(tlb_auto_out_d_bits_size),
    .auto_out_d_bits_source(tlb_auto_out_d_bits_source),
    .auto_out_d_bits_sink(tlb_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(tlb_auto_out_d_bits_denied),
    .auto_out_d_bits_data(tlb_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(tlb_auto_out_d_bits_corrupt)
  );
  TLBuffer_15_xs tlb_u_impl (
    .clock(clk),
    .reset(tlb_reset),
    .auto_in_a_ready(tlb_i_auto_in_a_ready),
    .auto_in_a_valid(tlb_auto_in_a_valid),
    .auto_in_a_bits_opcode(tlb_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(tlb_auto_in_a_bits_param),
    .auto_in_a_bits_size(tlb_auto_in_a_bits_size),
    .auto_in_a_bits_source(tlb_auto_in_a_bits_source),
    .auto_in_a_bits_address(tlb_auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC(tlb_auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM(tlb_auto_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask(tlb_auto_in_a_bits_mask),
    .auto_in_a_bits_data(tlb_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(tlb_auto_in_a_bits_corrupt),
    .auto_in_d_ready(tlb_auto_in_d_ready),
    .auto_in_d_valid(tlb_i_auto_in_d_valid),
    .auto_in_d_bits_opcode(tlb_i_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(tlb_i_auto_in_d_bits_param),
    .auto_in_d_bits_size(tlb_i_auto_in_d_bits_size),
    .auto_in_d_bits_source(tlb_i_auto_in_d_bits_source),
    .auto_in_d_bits_sink(tlb_i_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(tlb_i_auto_in_d_bits_denied),
    .auto_in_d_bits_data(tlb_i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(tlb_i_auto_in_d_bits_corrupt),
    .auto_out_a_ready(tlb_auto_out_a_ready),
    .auto_out_a_valid(tlb_i_auto_out_a_valid),
    .auto_out_a_bits_opcode(tlb_i_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(tlb_i_auto_out_a_bits_param),
    .auto_out_a_bits_size(tlb_i_auto_out_a_bits_size),
    .auto_out_a_bits_source(tlb_i_auto_out_a_bits_source),
    .auto_out_a_bits_address(tlb_i_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC(tlb_i_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM(tlb_i_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask(tlb_i_auto_out_a_bits_mask),
    .auto_out_a_bits_data(tlb_i_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(tlb_i_auto_out_a_bits_corrupt),
    .auto_out_d_ready(tlb_i_auto_out_d_ready),
    .auto_out_d_valid(tlb_auto_out_d_valid),
    .auto_out_d_bits_opcode(tlb_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(tlb_auto_out_d_bits_param),
    .auto_out_d_bits_size(tlb_auto_out_d_bits_size),
    .auto_out_d_bits_source(tlb_auto_out_d_bits_source),
    .auto_out_d_bits_sink(tlb_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(tlb_auto_out_d_bits_denied),
    .auto_out_d_bits_data(tlb_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(tlb_auto_out_d_bits_corrupt)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) tlb_mode = $urandom_range(0, 15);
      tlb_auto_in_a_valid = 1'($urandom);
      tlb_auto_in_a_bits_opcode = 4'($urandom);
      tlb_auto_in_a_bits_param = 3'($urandom);
      tlb_auto_in_a_bits_size = 2'($urandom);
      tlb_auto_in_a_bits_source = 1'($urandom);
      tlb_auto_in_a_bits_address = 48'({$urandom, $urandom});
      tlb_auto_in_a_bits_user_memPageType_NC = 1'($urandom);
      tlb_auto_in_a_bits_user_memBackType_MM = 1'($urandom);
      tlb_auto_in_a_bits_mask = 8'($urandom);
      tlb_auto_in_a_bits_data = 64'({$urandom, $urandom});
      tlb_auto_in_a_bits_corrupt = 1'($urandom);
      tlb_auto_in_d_ready = 1'($urandom);
      tlb_auto_out_a_ready = 1'($urandom);
      tlb_auto_out_d_valid = 1'($urandom);
      tlb_auto_out_d_bits_opcode = 4'($urandom);
      tlb_auto_out_d_bits_param = 2'($urandom);
      tlb_auto_out_d_bits_size = 2'($urandom);
      tlb_auto_out_d_bits_source = 1'($urandom);
      tlb_auto_out_d_bits_sink = 1'($urandom);
      tlb_auto_out_d_bits_denied = 1'($urandom);
      tlb_auto_out_d_bits_data = 64'({$urandom, $urandom});
      tlb_auto_out_d_bits_corrupt = 1'($urandom);
      tlb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_tlb
        case (tlb_mode % 3)
          0: begin  // 畅通
            tlb_auto_in_a_valid = ($urandom_range(0, 1) == 0);
            tlb_auto_out_a_ready = ($urandom_range(0, 7) != 0);
            tlb_auto_out_d_valid = ($urandom_range(0, 1) == 0);
            tlb_auto_in_d_ready = ($urandom_range(0, 7) != 0);
          end
          1: begin  // 下游堵：队列攒满
            tlb_auto_in_a_valid = ($urandom_range(0, 3) != 0);
            tlb_auto_out_a_ready = ($urandom_range(0, 3) == 0);
            tlb_auto_out_d_valid = ($urandom_range(0, 3) != 0);
            tlb_auto_in_d_ready = ($urandom_range(0, 3) == 0);
          end
          default: ;  // 全随机
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&tlb_armed)) begin
        checks++;
        if (tlb_g_auto_in_a_ready !== tlb_i_auto_in_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_a_ready g=%h i=%h", cyc, tlb_g_auto_in_a_ready, tlb_i_auto_in_a_ready);
        end
        tlb_s1_auto_in_a_ready |= tlb_g_auto_in_a_ready;
        tlb_s0_auto_in_a_ready |= ~tlb_g_auto_in_a_ready;
        checks++;
        if (tlb_g_auto_in_d_valid !== tlb_i_auto_in_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_valid g=%h i=%h", cyc, tlb_g_auto_in_d_valid, tlb_i_auto_in_d_valid);
        end
        tlb_s1_auto_in_d_valid |= tlb_g_auto_in_d_valid;
        tlb_s0_auto_in_d_valid |= ~tlb_g_auto_in_d_valid;
        checks++;
        if (tlb_g_auto_in_d_bits_opcode !== tlb_i_auto_in_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_opcode g=%h i=%h", cyc, tlb_g_auto_in_d_bits_opcode, tlb_i_auto_in_d_bits_opcode);
        end
        tlb_s1_auto_in_d_bits_opcode |= tlb_g_auto_in_d_bits_opcode;
        tlb_s0_auto_in_d_bits_opcode |= ~tlb_g_auto_in_d_bits_opcode;
        checks++;
        if (tlb_g_auto_in_d_bits_param !== tlb_i_auto_in_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_param g=%h i=%h", cyc, tlb_g_auto_in_d_bits_param, tlb_i_auto_in_d_bits_param);
        end
        tlb_s1_auto_in_d_bits_param |= tlb_g_auto_in_d_bits_param;
        tlb_s0_auto_in_d_bits_param |= ~tlb_g_auto_in_d_bits_param;
        checks++;
        if (tlb_g_auto_in_d_bits_size !== tlb_i_auto_in_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_size g=%h i=%h", cyc, tlb_g_auto_in_d_bits_size, tlb_i_auto_in_d_bits_size);
        end
        tlb_s1_auto_in_d_bits_size |= tlb_g_auto_in_d_bits_size;
        tlb_s0_auto_in_d_bits_size |= ~tlb_g_auto_in_d_bits_size;
        checks++;
        if (tlb_g_auto_in_d_bits_source !== tlb_i_auto_in_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_source g=%h i=%h", cyc, tlb_g_auto_in_d_bits_source, tlb_i_auto_in_d_bits_source);
        end
        tlb_s1_auto_in_d_bits_source |= tlb_g_auto_in_d_bits_source;
        tlb_s0_auto_in_d_bits_source |= ~tlb_g_auto_in_d_bits_source;
        checks++;
        if (tlb_g_auto_in_d_bits_sink !== tlb_i_auto_in_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_sink g=%h i=%h", cyc, tlb_g_auto_in_d_bits_sink, tlb_i_auto_in_d_bits_sink);
        end
        tlb_s1_auto_in_d_bits_sink |= tlb_g_auto_in_d_bits_sink;
        tlb_s0_auto_in_d_bits_sink |= ~tlb_g_auto_in_d_bits_sink;
        checks++;
        if (tlb_g_auto_in_d_bits_denied !== tlb_i_auto_in_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_denied g=%h i=%h", cyc, tlb_g_auto_in_d_bits_denied, tlb_i_auto_in_d_bits_denied);
        end
        tlb_s1_auto_in_d_bits_denied |= tlb_g_auto_in_d_bits_denied;
        tlb_s0_auto_in_d_bits_denied |= ~tlb_g_auto_in_d_bits_denied;
        checks++;
        if (tlb_g_auto_in_d_bits_data !== tlb_i_auto_in_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_data g=%h i=%h", cyc, tlb_g_auto_in_d_bits_data, tlb_i_auto_in_d_bits_data);
        end
        tlb_s1_auto_in_d_bits_data |= tlb_g_auto_in_d_bits_data;
        tlb_s0_auto_in_d_bits_data |= ~tlb_g_auto_in_d_bits_data;
        checks++;
        if (tlb_g_auto_in_d_bits_corrupt !== tlb_i_auto_in_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_in_d_bits_corrupt g=%h i=%h", cyc, tlb_g_auto_in_d_bits_corrupt, tlb_i_auto_in_d_bits_corrupt);
        end
        tlb_s1_auto_in_d_bits_corrupt |= tlb_g_auto_in_d_bits_corrupt;
        tlb_s0_auto_in_d_bits_corrupt |= ~tlb_g_auto_in_d_bits_corrupt;
        checks++;
        if (tlb_g_auto_out_a_valid !== tlb_i_auto_out_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_valid g=%h i=%h", cyc, tlb_g_auto_out_a_valid, tlb_i_auto_out_a_valid);
        end
        tlb_s1_auto_out_a_valid |= tlb_g_auto_out_a_valid;
        tlb_s0_auto_out_a_valid |= ~tlb_g_auto_out_a_valid;
        checks++;
        if (tlb_g_auto_out_a_bits_opcode !== tlb_i_auto_out_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_opcode g=%h i=%h", cyc, tlb_g_auto_out_a_bits_opcode, tlb_i_auto_out_a_bits_opcode);
        end
        tlb_s1_auto_out_a_bits_opcode |= tlb_g_auto_out_a_bits_opcode;
        tlb_s0_auto_out_a_bits_opcode |= ~tlb_g_auto_out_a_bits_opcode;
        checks++;
        if (tlb_g_auto_out_a_bits_param !== tlb_i_auto_out_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_param g=%h i=%h", cyc, tlb_g_auto_out_a_bits_param, tlb_i_auto_out_a_bits_param);
        end
        tlb_s1_auto_out_a_bits_param |= tlb_g_auto_out_a_bits_param;
        tlb_s0_auto_out_a_bits_param |= ~tlb_g_auto_out_a_bits_param;
        checks++;
        if (tlb_g_auto_out_a_bits_size !== tlb_i_auto_out_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_size g=%h i=%h", cyc, tlb_g_auto_out_a_bits_size, tlb_i_auto_out_a_bits_size);
        end
        tlb_s1_auto_out_a_bits_size |= tlb_g_auto_out_a_bits_size;
        tlb_s0_auto_out_a_bits_size |= ~tlb_g_auto_out_a_bits_size;
        checks++;
        if (tlb_g_auto_out_a_bits_source !== tlb_i_auto_out_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_source g=%h i=%h", cyc, tlb_g_auto_out_a_bits_source, tlb_i_auto_out_a_bits_source);
        end
        tlb_s1_auto_out_a_bits_source |= tlb_g_auto_out_a_bits_source;
        tlb_s0_auto_out_a_bits_source |= ~tlb_g_auto_out_a_bits_source;
        checks++;
        if (tlb_g_auto_out_a_bits_address !== tlb_i_auto_out_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_address g=%h i=%h", cyc, tlb_g_auto_out_a_bits_address, tlb_i_auto_out_a_bits_address);
        end
        tlb_s1_auto_out_a_bits_address |= tlb_g_auto_out_a_bits_address;
        tlb_s0_auto_out_a_bits_address |= ~tlb_g_auto_out_a_bits_address;
        checks++;
        if (tlb_g_auto_out_a_bits_user_memPageType_NC !== tlb_i_auto_out_a_bits_user_memPageType_NC) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_user_memPageType_NC g=%h i=%h", cyc, tlb_g_auto_out_a_bits_user_memPageType_NC, tlb_i_auto_out_a_bits_user_memPageType_NC);
        end
        tlb_s1_auto_out_a_bits_user_memPageType_NC |= tlb_g_auto_out_a_bits_user_memPageType_NC;
        tlb_s0_auto_out_a_bits_user_memPageType_NC |= ~tlb_g_auto_out_a_bits_user_memPageType_NC;
        checks++;
        if (tlb_g_auto_out_a_bits_user_memBackType_MM !== tlb_i_auto_out_a_bits_user_memBackType_MM) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_user_memBackType_MM g=%h i=%h", cyc, tlb_g_auto_out_a_bits_user_memBackType_MM, tlb_i_auto_out_a_bits_user_memBackType_MM);
        end
        tlb_s1_auto_out_a_bits_user_memBackType_MM |= tlb_g_auto_out_a_bits_user_memBackType_MM;
        tlb_s0_auto_out_a_bits_user_memBackType_MM |= ~tlb_g_auto_out_a_bits_user_memBackType_MM;
        checks++;
        if (tlb_g_auto_out_a_bits_mask !== tlb_i_auto_out_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_mask g=%h i=%h", cyc, tlb_g_auto_out_a_bits_mask, tlb_i_auto_out_a_bits_mask);
        end
        tlb_s1_auto_out_a_bits_mask |= tlb_g_auto_out_a_bits_mask;
        tlb_s0_auto_out_a_bits_mask |= ~tlb_g_auto_out_a_bits_mask;
        checks++;
        if (tlb_g_auto_out_a_bits_data !== tlb_i_auto_out_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_data g=%h i=%h", cyc, tlb_g_auto_out_a_bits_data, tlb_i_auto_out_a_bits_data);
        end
        tlb_s1_auto_out_a_bits_data |= tlb_g_auto_out_a_bits_data;
        tlb_s0_auto_out_a_bits_data |= ~tlb_g_auto_out_a_bits_data;
        checks++;
        if (tlb_g_auto_out_a_bits_corrupt !== tlb_i_auto_out_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_a_bits_corrupt g=%h i=%h", cyc, tlb_g_auto_out_a_bits_corrupt, tlb_i_auto_out_a_bits_corrupt);
        end
        tlb_s1_auto_out_a_bits_corrupt |= tlb_g_auto_out_a_bits_corrupt;
        tlb_s0_auto_out_a_bits_corrupt |= ~tlb_g_auto_out_a_bits_corrupt;
        checks++;
        if (tlb_g_auto_out_d_ready !== tlb_i_auto_out_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLBuffer_15.auto_out_d_ready g=%h i=%h", cyc, tlb_g_auto_out_d_ready, tlb_i_auto_out_d_ready);
        end
        tlb_s1_auto_out_d_ready |= tlb_g_auto_out_d_ready;
        tlb_s0_auto_out_d_ready |= ~tlb_g_auto_out_d_ready;
        if (tlb_auto_in_a_valid && tlb_g_auto_in_a_ready) tlb_cov_a_fire_in++;
        if (tlb_g_auto_out_a_valid && tlb_auto_out_a_ready) tlb_cov_a_fire_out++;
        if (tlb_auto_out_d_valid && tlb_g_auto_out_d_ready) tlb_cov_d_fire_in++;
        if (tlb_g_auto_in_d_valid && tlb_auto_in_d_ready) tlb_cov_d_fire_out++;
        if (tlb_auto_in_a_valid && !tlb_g_auto_in_a_ready) tlb_cov_a_full_stall++;
        if (tlb_auto_out_d_valid && !tlb_g_auto_out_d_ready) tlb_cov_d_full_stall++;
        if (tlb_u_gold.nodeOut_a_q.do_enq && tlb_u_gold.nodeOut_a_q.do_deq) tlb_cov_a_enq_deq_same++;
        if (tlb_u_gold.nodeIn_d_q.do_enq && tlb_u_gold.nodeIn_d_q.do_deq) tlb_cov_d_enq_deq_same++;
      end
      if (tlb_u_gold.nodeOut_a_q.do_enq && !tlb_u_gold.nodeOut_a_q.wrap) tlb_armed[0] = 1'b1;
      if (tlb_u_gold.nodeOut_a_q.do_enq && tlb_u_gold.nodeOut_a_q.wrap) tlb_armed[1] = 1'b1;
      if (tlb_u_gold.nodeIn_d_q.do_enq && !tlb_u_gold.nodeIn_d_q.wrap) tlb_armed[2] = 1'b1;
      if (tlb_u_gold.nodeIn_d_q.do_enq && tlb_u_gold.nodeIn_d_q.wrap) tlb_armed[3] = 1'b1;
      if (tlb_armed_at < 0 && (&tlb_armed)) tlb_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(tlb_s0_auto_in_a_ready && tlb_s1_auto_in_a_ready)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_a_ready 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_valid && tlb_s1_auto_in_d_valid)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_valid 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_opcode[0] && tlb_s1_auto_in_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_opcode[1] && tlb_s1_auto_in_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_opcode[2] && tlb_s1_auto_in_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_opcode[3] && tlb_s1_auto_in_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_param[0] && tlb_s1_auto_in_d_bits_param[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_param[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_param[1] && tlb_s1_auto_in_d_bits_param[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_param[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_size[0] && tlb_s1_auto_in_d_bits_size[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_size[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_size[1] && tlb_s1_auto_in_d_bits_size[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_size[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_source && tlb_s1_auto_in_d_bits_source)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_source 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_sink && tlb_s1_auto_in_d_bits_sink)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_sink 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_denied && tlb_s1_auto_in_d_bits_denied)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_denied 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[0] && tlb_s1_auto_in_d_bits_data[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[1] && tlb_s1_auto_in_d_bits_data[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[2] && tlb_s1_auto_in_d_bits_data[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[3] && tlb_s1_auto_in_d_bits_data[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[4] && tlb_s1_auto_in_d_bits_data[4])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[4] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[5] && tlb_s1_auto_in_d_bits_data[5])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[5] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[6] && tlb_s1_auto_in_d_bits_data[6])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[6] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[7] && tlb_s1_auto_in_d_bits_data[7])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[7] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[8] && tlb_s1_auto_in_d_bits_data[8])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[8] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[9] && tlb_s1_auto_in_d_bits_data[9])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[9] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[10] && tlb_s1_auto_in_d_bits_data[10])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[10] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[11] && tlb_s1_auto_in_d_bits_data[11])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[11] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[12] && tlb_s1_auto_in_d_bits_data[12])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[12] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[13] && tlb_s1_auto_in_d_bits_data[13])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[13] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[14] && tlb_s1_auto_in_d_bits_data[14])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[14] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[15] && tlb_s1_auto_in_d_bits_data[15])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[15] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[16] && tlb_s1_auto_in_d_bits_data[16])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[16] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[17] && tlb_s1_auto_in_d_bits_data[17])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[17] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[18] && tlb_s1_auto_in_d_bits_data[18])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[18] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[19] && tlb_s1_auto_in_d_bits_data[19])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[19] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[20] && tlb_s1_auto_in_d_bits_data[20])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[20] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[21] && tlb_s1_auto_in_d_bits_data[21])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[21] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[22] && tlb_s1_auto_in_d_bits_data[22])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[22] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[23] && tlb_s1_auto_in_d_bits_data[23])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[23] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[24] && tlb_s1_auto_in_d_bits_data[24])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[24] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[25] && tlb_s1_auto_in_d_bits_data[25])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[25] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[26] && tlb_s1_auto_in_d_bits_data[26])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[26] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[27] && tlb_s1_auto_in_d_bits_data[27])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[27] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[28] && tlb_s1_auto_in_d_bits_data[28])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[28] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[29] && tlb_s1_auto_in_d_bits_data[29])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[29] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[30] && tlb_s1_auto_in_d_bits_data[30])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[30] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[31] && tlb_s1_auto_in_d_bits_data[31])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[31] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[32] && tlb_s1_auto_in_d_bits_data[32])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[32] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[33] && tlb_s1_auto_in_d_bits_data[33])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[33] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[34] && tlb_s1_auto_in_d_bits_data[34])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[34] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[35] && tlb_s1_auto_in_d_bits_data[35])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[35] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[36] && tlb_s1_auto_in_d_bits_data[36])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[36] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[37] && tlb_s1_auto_in_d_bits_data[37])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[37] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[38] && tlb_s1_auto_in_d_bits_data[38])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[38] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[39] && tlb_s1_auto_in_d_bits_data[39])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[39] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[40] && tlb_s1_auto_in_d_bits_data[40])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[40] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[41] && tlb_s1_auto_in_d_bits_data[41])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[41] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[42] && tlb_s1_auto_in_d_bits_data[42])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[42] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[43] && tlb_s1_auto_in_d_bits_data[43])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[43] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[44] && tlb_s1_auto_in_d_bits_data[44])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[44] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[45] && tlb_s1_auto_in_d_bits_data[45])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[45] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[46] && tlb_s1_auto_in_d_bits_data[46])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[46] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[47] && tlb_s1_auto_in_d_bits_data[47])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[47] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[48] && tlb_s1_auto_in_d_bits_data[48])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[48] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[49] && tlb_s1_auto_in_d_bits_data[49])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[49] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[50] && tlb_s1_auto_in_d_bits_data[50])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[50] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[51] && tlb_s1_auto_in_d_bits_data[51])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[51] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[52] && tlb_s1_auto_in_d_bits_data[52])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[52] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[53] && tlb_s1_auto_in_d_bits_data[53])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[53] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[54] && tlb_s1_auto_in_d_bits_data[54])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[54] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[55] && tlb_s1_auto_in_d_bits_data[55])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[55] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[56] && tlb_s1_auto_in_d_bits_data[56])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[56] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[57] && tlb_s1_auto_in_d_bits_data[57])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[57] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[58] && tlb_s1_auto_in_d_bits_data[58])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[58] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[59] && tlb_s1_auto_in_d_bits_data[59])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[59] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[60] && tlb_s1_auto_in_d_bits_data[60])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[60] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[61] && tlb_s1_auto_in_d_bits_data[61])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[61] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[62] && tlb_s1_auto_in_d_bits_data[62])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[62] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_data[63] && tlb_s1_auto_in_d_bits_data[63])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_data[63] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_in_d_bits_corrupt && tlb_s1_auto_in_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_in_d_bits_corrupt 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_valid && tlb_s1_auto_out_a_valid)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_valid 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_opcode[0] && tlb_s1_auto_out_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_opcode[1] && tlb_s1_auto_out_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_opcode[2] && tlb_s1_auto_out_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_opcode[3] && tlb_s1_auto_out_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_param[0] && tlb_s1_auto_out_a_bits_param[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_param[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_param[1] && tlb_s1_auto_out_a_bits_param[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_param[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_param[2] && tlb_s1_auto_out_a_bits_param[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_param[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_size[0] && tlb_s1_auto_out_a_bits_size[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_size[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_size[1] && tlb_s1_auto_out_a_bits_size[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_size[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_source && tlb_s1_auto_out_a_bits_source)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_source 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[0] && tlb_s1_auto_out_a_bits_address[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[1] && tlb_s1_auto_out_a_bits_address[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[2] && tlb_s1_auto_out_a_bits_address[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[3] && tlb_s1_auto_out_a_bits_address[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[4] && tlb_s1_auto_out_a_bits_address[4])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[4] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[5] && tlb_s1_auto_out_a_bits_address[5])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[5] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[6] && tlb_s1_auto_out_a_bits_address[6])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[6] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[7] && tlb_s1_auto_out_a_bits_address[7])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[7] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[8] && tlb_s1_auto_out_a_bits_address[8])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[8] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[9] && tlb_s1_auto_out_a_bits_address[9])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[9] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[10] && tlb_s1_auto_out_a_bits_address[10])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[10] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[11] && tlb_s1_auto_out_a_bits_address[11])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[11] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[12] && tlb_s1_auto_out_a_bits_address[12])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[12] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[13] && tlb_s1_auto_out_a_bits_address[13])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[13] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[14] && tlb_s1_auto_out_a_bits_address[14])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[14] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[15] && tlb_s1_auto_out_a_bits_address[15])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[15] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[16] && tlb_s1_auto_out_a_bits_address[16])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[16] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[17] && tlb_s1_auto_out_a_bits_address[17])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[17] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[18] && tlb_s1_auto_out_a_bits_address[18])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[18] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[19] && tlb_s1_auto_out_a_bits_address[19])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[19] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[20] && tlb_s1_auto_out_a_bits_address[20])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[20] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[21] && tlb_s1_auto_out_a_bits_address[21])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[21] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[22] && tlb_s1_auto_out_a_bits_address[22])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[22] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[23] && tlb_s1_auto_out_a_bits_address[23])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[23] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[24] && tlb_s1_auto_out_a_bits_address[24])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[24] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[25] && tlb_s1_auto_out_a_bits_address[25])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[25] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[26] && tlb_s1_auto_out_a_bits_address[26])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[26] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[27] && tlb_s1_auto_out_a_bits_address[27])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[27] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[28] && tlb_s1_auto_out_a_bits_address[28])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[28] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[29] && tlb_s1_auto_out_a_bits_address[29])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[29] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[30] && tlb_s1_auto_out_a_bits_address[30])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[30] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[31] && tlb_s1_auto_out_a_bits_address[31])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[31] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[32] && tlb_s1_auto_out_a_bits_address[32])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[32] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[33] && tlb_s1_auto_out_a_bits_address[33])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[33] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[34] && tlb_s1_auto_out_a_bits_address[34])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[34] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[35] && tlb_s1_auto_out_a_bits_address[35])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[35] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[36] && tlb_s1_auto_out_a_bits_address[36])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[36] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[37] && tlb_s1_auto_out_a_bits_address[37])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[37] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[38] && tlb_s1_auto_out_a_bits_address[38])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[38] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[39] && tlb_s1_auto_out_a_bits_address[39])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[39] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[40] && tlb_s1_auto_out_a_bits_address[40])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[40] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[41] && tlb_s1_auto_out_a_bits_address[41])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[41] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[42] && tlb_s1_auto_out_a_bits_address[42])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[42] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[43] && tlb_s1_auto_out_a_bits_address[43])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[43] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[44] && tlb_s1_auto_out_a_bits_address[44])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[44] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[45] && tlb_s1_auto_out_a_bits_address[45])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[45] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[46] && tlb_s1_auto_out_a_bits_address[46])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[46] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_address[47] && tlb_s1_auto_out_a_bits_address[47])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_address[47] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_user_memPageType_NC && tlb_s1_auto_out_a_bits_user_memPageType_NC)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_user_memPageType_NC 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_user_memBackType_MM && tlb_s1_auto_out_a_bits_user_memBackType_MM)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_user_memBackType_MM 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[0] && tlb_s1_auto_out_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[1] && tlb_s1_auto_out_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[2] && tlb_s1_auto_out_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[3] && tlb_s1_auto_out_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[4] && tlb_s1_auto_out_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[5] && tlb_s1_auto_out_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[6] && tlb_s1_auto_out_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_mask[7] && tlb_s1_auto_out_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[0] && tlb_s1_auto_out_a_bits_data[0])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[0] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[1] && tlb_s1_auto_out_a_bits_data[1])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[1] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[2] && tlb_s1_auto_out_a_bits_data[2])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[2] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[3] && tlb_s1_auto_out_a_bits_data[3])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[3] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[4] && tlb_s1_auto_out_a_bits_data[4])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[4] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[5] && tlb_s1_auto_out_a_bits_data[5])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[5] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[6] && tlb_s1_auto_out_a_bits_data[6])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[6] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[7] && tlb_s1_auto_out_a_bits_data[7])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[7] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[8] && tlb_s1_auto_out_a_bits_data[8])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[8] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[9] && tlb_s1_auto_out_a_bits_data[9])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[9] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[10] && tlb_s1_auto_out_a_bits_data[10])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[10] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[11] && tlb_s1_auto_out_a_bits_data[11])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[11] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[12] && tlb_s1_auto_out_a_bits_data[12])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[12] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[13] && tlb_s1_auto_out_a_bits_data[13])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[13] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[14] && tlb_s1_auto_out_a_bits_data[14])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[14] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[15] && tlb_s1_auto_out_a_bits_data[15])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[15] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[16] && tlb_s1_auto_out_a_bits_data[16])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[16] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[17] && tlb_s1_auto_out_a_bits_data[17])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[17] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[18] && tlb_s1_auto_out_a_bits_data[18])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[18] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[19] && tlb_s1_auto_out_a_bits_data[19])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[19] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[20] && tlb_s1_auto_out_a_bits_data[20])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[20] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[21] && tlb_s1_auto_out_a_bits_data[21])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[21] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[22] && tlb_s1_auto_out_a_bits_data[22])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[22] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[23] && tlb_s1_auto_out_a_bits_data[23])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[23] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[24] && tlb_s1_auto_out_a_bits_data[24])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[24] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[25] && tlb_s1_auto_out_a_bits_data[25])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[25] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[26] && tlb_s1_auto_out_a_bits_data[26])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[26] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[27] && tlb_s1_auto_out_a_bits_data[27])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[27] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[28] && tlb_s1_auto_out_a_bits_data[28])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[28] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[29] && tlb_s1_auto_out_a_bits_data[29])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[29] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[30] && tlb_s1_auto_out_a_bits_data[30])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[30] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[31] && tlb_s1_auto_out_a_bits_data[31])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[31] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[32] && tlb_s1_auto_out_a_bits_data[32])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[32] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[33] && tlb_s1_auto_out_a_bits_data[33])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[33] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[34] && tlb_s1_auto_out_a_bits_data[34])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[34] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[35] && tlb_s1_auto_out_a_bits_data[35])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[35] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[36] && tlb_s1_auto_out_a_bits_data[36])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[36] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[37] && tlb_s1_auto_out_a_bits_data[37])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[37] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[38] && tlb_s1_auto_out_a_bits_data[38])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[38] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[39] && tlb_s1_auto_out_a_bits_data[39])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[39] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[40] && tlb_s1_auto_out_a_bits_data[40])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[40] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[41] && tlb_s1_auto_out_a_bits_data[41])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[41] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[42] && tlb_s1_auto_out_a_bits_data[42])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[42] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[43] && tlb_s1_auto_out_a_bits_data[43])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[43] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[44] && tlb_s1_auto_out_a_bits_data[44])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[44] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[45] && tlb_s1_auto_out_a_bits_data[45])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[45] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[46] && tlb_s1_auto_out_a_bits_data[46])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[46] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[47] && tlb_s1_auto_out_a_bits_data[47])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[47] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[48] && tlb_s1_auto_out_a_bits_data[48])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[48] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[49] && tlb_s1_auto_out_a_bits_data[49])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[49] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[50] && tlb_s1_auto_out_a_bits_data[50])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[50] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[51] && tlb_s1_auto_out_a_bits_data[51])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[51] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[52] && tlb_s1_auto_out_a_bits_data[52])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[52] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[53] && tlb_s1_auto_out_a_bits_data[53])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[53] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[54] && tlb_s1_auto_out_a_bits_data[54])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[54] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[55] && tlb_s1_auto_out_a_bits_data[55])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[55] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[56] && tlb_s1_auto_out_a_bits_data[56])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[56] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[57] && tlb_s1_auto_out_a_bits_data[57])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[57] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[58] && tlb_s1_auto_out_a_bits_data[58])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[58] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[59] && tlb_s1_auto_out_a_bits_data[59])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[59] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[60] && tlb_s1_auto_out_a_bits_data[60])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[60] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[61] && tlb_s1_auto_out_a_bits_data[61])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[61] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[62] && tlb_s1_auto_out_a_bits_data[62])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[62] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_data[63] && tlb_s1_auto_out_a_bits_data[63])) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_data[63] 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_a_bits_corrupt && tlb_s1_auto_out_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_a_bits_corrupt 未见过 0 和 1"); end
    if (!(tlb_s0_auto_out_d_ready && tlb_s1_auto_out_d_ready)) begin cov_fail++; $display("[COV] TLBuffer_15.auto_out_d_ready 未见过 0 和 1"); end
    $display("[ARM] TLBuffer_15 armed_at=%0d", tlb_armed_at);
    if (tlb_armed_at < 0) begin cov_fail++; $display("[ARM] TLBuffer_15 从未 arm"); end
    $display("[COV] TLBuffer_15.a_fire_in = %0d", tlb_cov_a_fire_in);
    if (tlb_cov_a_fire_in < 100) begin cov_fail++; $display("[COV] TLBuffer_15.a_fire_in < 100"); end
    $display("[COV] TLBuffer_15.a_fire_out = %0d", tlb_cov_a_fire_out);
    if (tlb_cov_a_fire_out < 100) begin cov_fail++; $display("[COV] TLBuffer_15.a_fire_out < 100"); end
    $display("[COV] TLBuffer_15.d_fire_in = %0d", tlb_cov_d_fire_in);
    if (tlb_cov_d_fire_in < 100) begin cov_fail++; $display("[COV] TLBuffer_15.d_fire_in < 100"); end
    $display("[COV] TLBuffer_15.d_fire_out = %0d", tlb_cov_d_fire_out);
    if (tlb_cov_d_fire_out < 100) begin cov_fail++; $display("[COV] TLBuffer_15.d_fire_out < 100"); end
    $display("[COV] TLBuffer_15.a_full_stall = %0d", tlb_cov_a_full_stall);
    if (tlb_cov_a_full_stall < 100) begin cov_fail++; $display("[COV] TLBuffer_15.a_full_stall < 100"); end
    $display("[COV] TLBuffer_15.d_full_stall = %0d", tlb_cov_d_full_stall);
    if (tlb_cov_d_full_stall < 100) begin cov_fail++; $display("[COV] TLBuffer_15.d_full_stall < 100"); end
    $display("[COV] TLBuffer_15.a_enq_deq_same = %0d", tlb_cov_a_enq_deq_same);
    if (tlb_cov_a_enq_deq_same < 100) begin cov_fail++; $display("[COV] TLBuffer_15.a_enq_deq_same < 100"); end
    $display("[COV] TLBuffer_15.d_enq_deq_same = %0d", tlb_cov_d_enq_deq_same);
    if (tlb_cov_d_enq_deq_same < 100) begin cov_fail++; $display("[COV] TLBuffer_15.d_enq_deq_same < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
