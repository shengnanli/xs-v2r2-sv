// TLXbar_6 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= TLXbar_6 =================
  int unsigned x_mode = 0;
  initial begin
    #1;
    force x_u_impl.u_core.g_out_a[0].u_arb.beats_left = x_u_gold.beatsLeft;
    force x_u_impl.u_core.g_out_a[0].u_arb.mask = x_u_gold.readys_mask;
    force x_u_impl.u_core.g_out_a[0].u_arb.state = {x_u_gold.state_1, x_u_gold.state_0};
    force x_u_impl.u_core.g_out_a[1].u_arb.beats_left = x_u_gold.beatsLeft_1;
    force x_u_impl.u_core.g_out_a[1].u_arb.mask = x_u_gold.readys_mask_1;
    force x_u_impl.u_core.g_out_a[1].u_arb.state = {x_u_gold.state_1_1, x_u_gold.state_1_0};
    force x_u_impl.u_core.g_out_a[2].u_arb.beats_left = x_u_gold.beatsLeft_2;
    force x_u_impl.u_core.g_out_a[2].u_arb.mask = x_u_gold.readys_mask_2;
    force x_u_impl.u_core.g_out_a[2].u_arb.state = {x_u_gold.state_2_1, x_u_gold.state_2_0};
    force x_u_impl.u_core.g_in_d[0].u_arb.beats_left = x_u_gold.beatsLeft_3;
    force x_u_impl.u_core.g_in_d[0].u_arb.mask = x_u_gold.readys_mask_3;
    force x_u_impl.u_core.g_in_d[0].u_arb.state = {x_u_gold.state_3_2, x_u_gold.state_3_1, x_u_gold.state_3_0};
    force x_u_impl.u_core.g_in_d[1].u_arb.beats_left = x_u_gold.beatsLeft_4;
    force x_u_impl.u_core.g_in_d[1].u_arb.mask = x_u_gold.readys_mask_4;
    force x_u_impl.u_core.g_in_d[1].u_arb.state = {x_u_gold.state_4_2, x_u_gold.state_4_1, x_u_gold.state_4_0};
    #0;
    release x_u_impl.u_core.g_out_a[0].u_arb.beats_left;
    release x_u_impl.u_core.g_out_a[0].u_arb.mask;
    release x_u_impl.u_core.g_out_a[0].u_arb.state;
    release x_u_impl.u_core.g_out_a[1].u_arb.beats_left;
    release x_u_impl.u_core.g_out_a[1].u_arb.mask;
    release x_u_impl.u_core.g_out_a[1].u_arb.state;
    release x_u_impl.u_core.g_out_a[2].u_arb.beats_left;
    release x_u_impl.u_core.g_out_a[2].u_arb.mask;
    release x_u_impl.u_core.g_out_a[2].u_arb.state;
    release x_u_impl.u_core.g_in_d[0].u_arb.beats_left;
    release x_u_impl.u_core.g_in_d[0].u_arb.mask;
    release x_u_impl.u_core.g_in_d[0].u_arb.state;
    release x_u_impl.u_core.g_in_d[1].u_arb.beats_left;
    release x_u_impl.u_core.g_in_d[1].u_arb.mask;
    release x_u_impl.u_core.g_in_d[1].u_arb.state;
  end
  logic x_reset;
  wire  x_g_auto_in_1_a_ready, x_i_auto_in_1_a_ready;
  logic x_s0_auto_in_1_a_ready = '0, x_s1_auto_in_1_a_ready = '0;
  logic x_auto_in_1_a_valid;
  logic [3:0] x_auto_in_1_a_bits_opcode;
  logic [2:0] x_auto_in_1_a_bits_param;
  logic [1:0] x_auto_in_1_a_bits_size;
  logic [3:0] x_auto_in_1_a_bits_source;
  logic [47:0] x_auto_in_1_a_bits_address;
  logic x_auto_in_1_a_bits_user_memBackType_MM;
  logic x_auto_in_1_a_bits_user_memPageType_NC;
  logic [7:0] x_auto_in_1_a_bits_mask;
  logic [63:0] x_auto_in_1_a_bits_data;
  logic x_auto_in_1_a_bits_corrupt;
  logic x_auto_in_1_d_ready;
  wire  x_g_auto_in_1_d_valid, x_i_auto_in_1_d_valid;
  logic x_s0_auto_in_1_d_valid = '0, x_s1_auto_in_1_d_valid = '0;
  wire  [3:0] x_g_auto_in_1_d_bits_opcode, x_i_auto_in_1_d_bits_opcode;
  logic [3:0] x_s0_auto_in_1_d_bits_opcode = '0, x_s1_auto_in_1_d_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_1_d_bits_param, x_i_auto_in_1_d_bits_param;
  logic [1:0] x_s0_auto_in_1_d_bits_param = '0, x_s1_auto_in_1_d_bits_param = '0;
  wire  [1:0] x_g_auto_in_1_d_bits_size, x_i_auto_in_1_d_bits_size;
  logic [1:0] x_s0_auto_in_1_d_bits_size = '0, x_s1_auto_in_1_d_bits_size = '0;
  wire  [3:0] x_g_auto_in_1_d_bits_source, x_i_auto_in_1_d_bits_source;
  logic [3:0] x_s0_auto_in_1_d_bits_source = '0, x_s1_auto_in_1_d_bits_source = '0;
  wire  x_g_auto_in_1_d_bits_sink, x_i_auto_in_1_d_bits_sink;
  logic x_s0_auto_in_1_d_bits_sink = '0, x_s1_auto_in_1_d_bits_sink = '0;
  wire  x_g_auto_in_1_d_bits_denied, x_i_auto_in_1_d_bits_denied;
  logic x_s0_auto_in_1_d_bits_denied = '0, x_s1_auto_in_1_d_bits_denied = '0;
  wire  [63:0] x_g_auto_in_1_d_bits_data, x_i_auto_in_1_d_bits_data;
  logic [63:0] x_s0_auto_in_1_d_bits_data = '0, x_s1_auto_in_1_d_bits_data = '0;
  wire  x_g_auto_in_1_d_bits_corrupt, x_i_auto_in_1_d_bits_corrupt;
  logic x_s0_auto_in_1_d_bits_corrupt = '0, x_s1_auto_in_1_d_bits_corrupt = '0;
  wire  x_g_auto_in_0_a_ready, x_i_auto_in_0_a_ready;
  logic x_s0_auto_in_0_a_ready = '0, x_s1_auto_in_0_a_ready = '0;
  logic x_auto_in_0_a_valid;
  logic [3:0] x_auto_in_0_a_bits_opcode;
  logic [2:0] x_auto_in_0_a_bits_param;
  logic [1:0] x_auto_in_0_a_bits_size;
  logic x_auto_in_0_a_bits_source;
  logic [47:0] x_auto_in_0_a_bits_address;
  logic x_auto_in_0_a_bits_user_memPageType_NC;
  logic x_auto_in_0_a_bits_user_memBackType_MM;
  logic [7:0] x_auto_in_0_a_bits_mask;
  logic [63:0] x_auto_in_0_a_bits_data;
  logic x_auto_in_0_a_bits_corrupt;
  logic x_auto_in_0_d_ready;
  wire  x_g_auto_in_0_d_valid, x_i_auto_in_0_d_valid;
  logic x_s0_auto_in_0_d_valid = '0, x_s1_auto_in_0_d_valid = '0;
  wire  [3:0] x_g_auto_in_0_d_bits_opcode, x_i_auto_in_0_d_bits_opcode;
  logic [3:0] x_s0_auto_in_0_d_bits_opcode = '0, x_s1_auto_in_0_d_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_0_d_bits_param, x_i_auto_in_0_d_bits_param;
  logic [1:0] x_s0_auto_in_0_d_bits_param = '0, x_s1_auto_in_0_d_bits_param = '0;
  wire  [1:0] x_g_auto_in_0_d_bits_size, x_i_auto_in_0_d_bits_size;
  logic [1:0] x_s0_auto_in_0_d_bits_size = '0, x_s1_auto_in_0_d_bits_size = '0;
  wire  x_g_auto_in_0_d_bits_sink, x_i_auto_in_0_d_bits_sink;
  logic x_s0_auto_in_0_d_bits_sink = '0, x_s1_auto_in_0_d_bits_sink = '0;
  wire  x_g_auto_in_0_d_bits_denied, x_i_auto_in_0_d_bits_denied;
  logic x_s0_auto_in_0_d_bits_denied = '0, x_s1_auto_in_0_d_bits_denied = '0;
  wire  [63:0] x_g_auto_in_0_d_bits_data, x_i_auto_in_0_d_bits_data;
  logic [63:0] x_s0_auto_in_0_d_bits_data = '0, x_s1_auto_in_0_d_bits_data = '0;
  wire  x_g_auto_in_0_d_bits_corrupt, x_i_auto_in_0_d_bits_corrupt;
  logic x_s0_auto_in_0_d_bits_corrupt = '0, x_s1_auto_in_0_d_bits_corrupt = '0;
  logic x_auto_out_2_a_ready;
  wire  x_g_auto_out_2_a_valid, x_i_auto_out_2_a_valid;
  logic x_s0_auto_out_2_a_valid = '0, x_s1_auto_out_2_a_valid = '0;
  wire  [3:0] x_g_auto_out_2_a_bits_opcode, x_i_auto_out_2_a_bits_opcode;
  logic [3:0] x_s0_auto_out_2_a_bits_opcode = '0, x_s1_auto_out_2_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_2_a_bits_param, x_i_auto_out_2_a_bits_param;
  logic [2:0] x_s0_auto_out_2_a_bits_param = '0, x_s1_auto_out_2_a_bits_param = '0;
  wire  [1:0] x_g_auto_out_2_a_bits_size, x_i_auto_out_2_a_bits_size;
  logic [1:0] x_s0_auto_out_2_a_bits_size = '0, x_s1_auto_out_2_a_bits_size = '0;
  wire  [4:0] x_g_auto_out_2_a_bits_source, x_i_auto_out_2_a_bits_source;
  logic [4:0] x_s0_auto_out_2_a_bits_source = '0, x_s1_auto_out_2_a_bits_source = '0;
  wire  [47:0] x_g_auto_out_2_a_bits_address, x_i_auto_out_2_a_bits_address;
  logic [47:0] x_s0_auto_out_2_a_bits_address = '0, x_s1_auto_out_2_a_bits_address = '0;
  wire  x_g_auto_out_2_a_bits_user_memBackType_MM, x_i_auto_out_2_a_bits_user_memBackType_MM;
  logic x_s0_auto_out_2_a_bits_user_memBackType_MM = '0, x_s1_auto_out_2_a_bits_user_memBackType_MM = '0;
  wire  x_g_auto_out_2_a_bits_user_memPageType_NC, x_i_auto_out_2_a_bits_user_memPageType_NC;
  logic x_s0_auto_out_2_a_bits_user_memPageType_NC = '0, x_s1_auto_out_2_a_bits_user_memPageType_NC = '0;
  wire  [7:0] x_g_auto_out_2_a_bits_mask, x_i_auto_out_2_a_bits_mask;
  logic [7:0] x_s0_auto_out_2_a_bits_mask = '0, x_s1_auto_out_2_a_bits_mask = '0;
  wire  [63:0] x_g_auto_out_2_a_bits_data, x_i_auto_out_2_a_bits_data;
  logic [63:0] x_s0_auto_out_2_a_bits_data = '0, x_s1_auto_out_2_a_bits_data = '0;
  wire  x_g_auto_out_2_a_bits_corrupt, x_i_auto_out_2_a_bits_corrupt;
  logic x_s0_auto_out_2_a_bits_corrupt = '0, x_s1_auto_out_2_a_bits_corrupt = '0;
  wire  x_g_auto_out_2_d_ready, x_i_auto_out_2_d_ready;
  logic x_s0_auto_out_2_d_ready = '0, x_s1_auto_out_2_d_ready = '0;
  logic x_auto_out_2_d_valid;
  logic [3:0] x_auto_out_2_d_bits_opcode;
  logic [1:0] x_auto_out_2_d_bits_param;
  logic [1:0] x_auto_out_2_d_bits_size;
  logic [4:0] x_auto_out_2_d_bits_source;
  logic x_auto_out_2_d_bits_sink;
  logic x_auto_out_2_d_bits_denied;
  logic [63:0] x_auto_out_2_d_bits_data;
  logic x_auto_out_2_d_bits_corrupt;
  logic x_auto_out_1_a_ready;
  wire  x_g_auto_out_1_a_valid, x_i_auto_out_1_a_valid;
  logic x_s0_auto_out_1_a_valid = '0, x_s1_auto_out_1_a_valid = '0;
  wire  [3:0] x_g_auto_out_1_a_bits_opcode, x_i_auto_out_1_a_bits_opcode;
  logic [3:0] x_s0_auto_out_1_a_bits_opcode = '0, x_s1_auto_out_1_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_1_a_bits_param, x_i_auto_out_1_a_bits_param;
  logic [2:0] x_s0_auto_out_1_a_bits_param = '0, x_s1_auto_out_1_a_bits_param = '0;
  wire  [1:0] x_g_auto_out_1_a_bits_size, x_i_auto_out_1_a_bits_size;
  logic [1:0] x_s0_auto_out_1_a_bits_size = '0, x_s1_auto_out_1_a_bits_size = '0;
  wire  [4:0] x_g_auto_out_1_a_bits_source, x_i_auto_out_1_a_bits_source;
  logic [4:0] x_s0_auto_out_1_a_bits_source = '0, x_s1_auto_out_1_a_bits_source = '0;
  wire  [29:0] x_g_auto_out_1_a_bits_address, x_i_auto_out_1_a_bits_address;
  logic [29:0] x_s0_auto_out_1_a_bits_address = '0, x_s1_auto_out_1_a_bits_address = '0;
  wire  [7:0] x_g_auto_out_1_a_bits_mask, x_i_auto_out_1_a_bits_mask;
  logic [7:0] x_s0_auto_out_1_a_bits_mask = '0, x_s1_auto_out_1_a_bits_mask = '0;
  wire  [63:0] x_g_auto_out_1_a_bits_data, x_i_auto_out_1_a_bits_data;
  logic [63:0] x_s0_auto_out_1_a_bits_data = '0, x_s1_auto_out_1_a_bits_data = '0;
  wire  x_g_auto_out_1_a_bits_corrupt, x_i_auto_out_1_a_bits_corrupt;
  logic x_s0_auto_out_1_a_bits_corrupt = '0, x_s1_auto_out_1_a_bits_corrupt = '0;
  wire  x_g_auto_out_1_d_ready, x_i_auto_out_1_d_ready;
  logic x_s0_auto_out_1_d_ready = '0, x_s1_auto_out_1_d_ready = '0;
  logic x_auto_out_1_d_valid;
  logic [3:0] x_auto_out_1_d_bits_opcode;
  logic [1:0] x_auto_out_1_d_bits_param;
  logic [1:0] x_auto_out_1_d_bits_size;
  logic [4:0] x_auto_out_1_d_bits_source;
  logic x_auto_out_1_d_bits_sink;
  logic x_auto_out_1_d_bits_denied;
  logic [63:0] x_auto_out_1_d_bits_data;
  logic x_auto_out_1_d_bits_corrupt;
  logic x_auto_out_0_a_ready;
  wire  x_g_auto_out_0_a_valid, x_i_auto_out_0_a_valid;
  logic x_s0_auto_out_0_a_valid = '0, x_s1_auto_out_0_a_valid = '0;
  wire  [3:0] x_g_auto_out_0_a_bits_opcode, x_i_auto_out_0_a_bits_opcode;
  logic [3:0] x_s0_auto_out_0_a_bits_opcode = '0, x_s1_auto_out_0_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_0_a_bits_param, x_i_auto_out_0_a_bits_param;
  logic [2:0] x_s0_auto_out_0_a_bits_param = '0, x_s1_auto_out_0_a_bits_param = '0;
  wire  [1:0] x_g_auto_out_0_a_bits_size, x_i_auto_out_0_a_bits_size;
  logic [1:0] x_s0_auto_out_0_a_bits_size = '0, x_s1_auto_out_0_a_bits_size = '0;
  wire  [4:0] x_g_auto_out_0_a_bits_source, x_i_auto_out_0_a_bits_source;
  logic [4:0] x_s0_auto_out_0_a_bits_source = '0, x_s1_auto_out_0_a_bits_source = '0;
  wire  [29:0] x_g_auto_out_0_a_bits_address, x_i_auto_out_0_a_bits_address;
  logic [29:0] x_s0_auto_out_0_a_bits_address = '0, x_s1_auto_out_0_a_bits_address = '0;
  wire  [7:0] x_g_auto_out_0_a_bits_mask, x_i_auto_out_0_a_bits_mask;
  logic [7:0] x_s0_auto_out_0_a_bits_mask = '0, x_s1_auto_out_0_a_bits_mask = '0;
  wire  [63:0] x_g_auto_out_0_a_bits_data, x_i_auto_out_0_a_bits_data;
  logic [63:0] x_s0_auto_out_0_a_bits_data = '0, x_s1_auto_out_0_a_bits_data = '0;
  wire  x_g_auto_out_0_a_bits_corrupt, x_i_auto_out_0_a_bits_corrupt;
  logic x_s0_auto_out_0_a_bits_corrupt = '0, x_s1_auto_out_0_a_bits_corrupt = '0;
  wire  x_g_auto_out_0_d_ready, x_i_auto_out_0_d_ready;
  logic x_s0_auto_out_0_d_ready = '0, x_s1_auto_out_0_d_ready = '0;
  logic x_auto_out_0_d_valid;
  logic [3:0] x_auto_out_0_d_bits_opcode;
  logic [1:0] x_auto_out_0_d_bits_param;
  logic [1:0] x_auto_out_0_d_bits_size;
  logic [4:0] x_auto_out_0_d_bits_source;
  logic x_auto_out_0_d_bits_sink;
  logic x_auto_out_0_d_bits_denied;
  logic [63:0] x_auto_out_0_d_bits_data;
  logic x_auto_out_0_d_bits_corrupt;
  int x_cov_a0_in0 = 0;
  int x_cov_a0_in1 = 0;
  int x_cov_a1_fire = 0;
  int x_cov_a2_fire = 0;
  int x_cov_a_contend = 0;
  int x_cov_d0_fire = 0;
  int x_cov_d1_fire = 0;
  int x_cov_d_contend = 0;
  int x_cov_rr_flip = 0;
  logic [0:0] x_armed = '0;
  int x_armed_at = -1;
  TLXbar_6 x_u_gold (
    .clock(clk),
    .reset(x_reset),
    .auto_in_1_a_ready(x_g_auto_in_1_a_ready),
    .auto_in_1_a_valid(x_auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(x_auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_param(x_auto_in_1_a_bits_param),
    .auto_in_1_a_bits_size(x_auto_in_1_a_bits_size),
    .auto_in_1_a_bits_source(x_auto_in_1_a_bits_source),
    .auto_in_1_a_bits_address(x_auto_in_1_a_bits_address),
    .auto_in_1_a_bits_user_memBackType_MM(x_auto_in_1_a_bits_user_memBackType_MM),
    .auto_in_1_a_bits_user_memPageType_NC(x_auto_in_1_a_bits_user_memPageType_NC),
    .auto_in_1_a_bits_mask(x_auto_in_1_a_bits_mask),
    .auto_in_1_a_bits_data(x_auto_in_1_a_bits_data),
    .auto_in_1_a_bits_corrupt(x_auto_in_1_a_bits_corrupt),
    .auto_in_1_d_ready(x_auto_in_1_d_ready),
    .auto_in_1_d_valid(x_g_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode(x_g_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param(x_g_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size(x_g_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source(x_g_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink(x_g_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied(x_g_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data(x_g_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt(x_g_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready(x_g_auto_in_0_a_ready),
    .auto_in_0_a_valid(x_auto_in_0_a_valid),
    .auto_in_0_a_bits_opcode(x_auto_in_0_a_bits_opcode),
    .auto_in_0_a_bits_param(x_auto_in_0_a_bits_param),
    .auto_in_0_a_bits_size(x_auto_in_0_a_bits_size),
    .auto_in_0_a_bits_source(x_auto_in_0_a_bits_source),
    .auto_in_0_a_bits_address(x_auto_in_0_a_bits_address),
    .auto_in_0_a_bits_user_memPageType_NC(x_auto_in_0_a_bits_user_memPageType_NC),
    .auto_in_0_a_bits_user_memBackType_MM(x_auto_in_0_a_bits_user_memBackType_MM),
    .auto_in_0_a_bits_mask(x_auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(x_auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(x_auto_in_0_a_bits_corrupt),
    .auto_in_0_d_ready(x_auto_in_0_d_ready),
    .auto_in_0_d_valid(x_g_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(x_g_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(x_g_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(x_g_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_sink(x_g_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(x_g_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_data(x_g_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(x_g_auto_in_0_d_bits_corrupt),
    .auto_out_2_a_ready(x_auto_out_2_a_ready),
    .auto_out_2_a_valid(x_g_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(x_g_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(x_g_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(x_g_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(x_g_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(x_g_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_memBackType_MM(x_g_auto_out_2_a_bits_user_memBackType_MM),
    .auto_out_2_a_bits_user_memPageType_NC(x_g_auto_out_2_a_bits_user_memPageType_NC),
    .auto_out_2_a_bits_mask(x_g_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(x_g_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(x_g_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready(x_g_auto_out_2_d_ready),
    .auto_out_2_d_valid(x_auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(x_auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(x_auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(x_auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(x_auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(x_auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(x_auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_data(x_auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(x_auto_out_2_d_bits_corrupt),
    .auto_out_1_a_ready(x_auto_out_1_a_ready),
    .auto_out_1_a_valid(x_g_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(x_g_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(x_g_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(x_g_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(x_g_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(x_g_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_mask(x_g_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(x_g_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(x_g_auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready(x_g_auto_out_1_d_ready),
    .auto_out_1_d_valid(x_auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(x_auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(x_auto_out_1_d_bits_param),
    .auto_out_1_d_bits_size(x_auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(x_auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(x_auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(x_auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_data(x_auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(x_auto_out_1_d_bits_corrupt),
    .auto_out_0_a_ready(x_auto_out_0_a_ready),
    .auto_out_0_a_valid(x_g_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(x_g_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(x_g_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(x_g_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(x_g_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(x_g_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(x_g_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(x_g_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(x_g_auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(x_g_auto_out_0_d_ready),
    .auto_out_0_d_valid(x_auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(x_auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(x_auto_out_0_d_bits_param),
    .auto_out_0_d_bits_size(x_auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(x_auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(x_auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(x_auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_data(x_auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(x_auto_out_0_d_bits_corrupt)
  );
  TLXbar_6_xs x_u_impl (
    .clock(clk),
    .reset(x_reset),
    .auto_in_1_a_ready(x_i_auto_in_1_a_ready),
    .auto_in_1_a_valid(x_auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(x_auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_param(x_auto_in_1_a_bits_param),
    .auto_in_1_a_bits_size(x_auto_in_1_a_bits_size),
    .auto_in_1_a_bits_source(x_auto_in_1_a_bits_source),
    .auto_in_1_a_bits_address(x_auto_in_1_a_bits_address),
    .auto_in_1_a_bits_user_memBackType_MM(x_auto_in_1_a_bits_user_memBackType_MM),
    .auto_in_1_a_bits_user_memPageType_NC(x_auto_in_1_a_bits_user_memPageType_NC),
    .auto_in_1_a_bits_mask(x_auto_in_1_a_bits_mask),
    .auto_in_1_a_bits_data(x_auto_in_1_a_bits_data),
    .auto_in_1_a_bits_corrupt(x_auto_in_1_a_bits_corrupt),
    .auto_in_1_d_ready(x_auto_in_1_d_ready),
    .auto_in_1_d_valid(x_i_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode(x_i_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param(x_i_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size(x_i_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source(x_i_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink(x_i_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied(x_i_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data(x_i_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt(x_i_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready(x_i_auto_in_0_a_ready),
    .auto_in_0_a_valid(x_auto_in_0_a_valid),
    .auto_in_0_a_bits_opcode(x_auto_in_0_a_bits_opcode),
    .auto_in_0_a_bits_param(x_auto_in_0_a_bits_param),
    .auto_in_0_a_bits_size(x_auto_in_0_a_bits_size),
    .auto_in_0_a_bits_source(x_auto_in_0_a_bits_source),
    .auto_in_0_a_bits_address(x_auto_in_0_a_bits_address),
    .auto_in_0_a_bits_user_memPageType_NC(x_auto_in_0_a_bits_user_memPageType_NC),
    .auto_in_0_a_bits_user_memBackType_MM(x_auto_in_0_a_bits_user_memBackType_MM),
    .auto_in_0_a_bits_mask(x_auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(x_auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(x_auto_in_0_a_bits_corrupt),
    .auto_in_0_d_ready(x_auto_in_0_d_ready),
    .auto_in_0_d_valid(x_i_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(x_i_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(x_i_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(x_i_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_sink(x_i_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(x_i_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_data(x_i_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(x_i_auto_in_0_d_bits_corrupt),
    .auto_out_2_a_ready(x_auto_out_2_a_ready),
    .auto_out_2_a_valid(x_i_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(x_i_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(x_i_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(x_i_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(x_i_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(x_i_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_memBackType_MM(x_i_auto_out_2_a_bits_user_memBackType_MM),
    .auto_out_2_a_bits_user_memPageType_NC(x_i_auto_out_2_a_bits_user_memPageType_NC),
    .auto_out_2_a_bits_mask(x_i_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(x_i_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(x_i_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready(x_i_auto_out_2_d_ready),
    .auto_out_2_d_valid(x_auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(x_auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(x_auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(x_auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(x_auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(x_auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(x_auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_data(x_auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(x_auto_out_2_d_bits_corrupt),
    .auto_out_1_a_ready(x_auto_out_1_a_ready),
    .auto_out_1_a_valid(x_i_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(x_i_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(x_i_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(x_i_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(x_i_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(x_i_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_mask(x_i_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(x_i_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(x_i_auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready(x_i_auto_out_1_d_ready),
    .auto_out_1_d_valid(x_auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(x_auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(x_auto_out_1_d_bits_param),
    .auto_out_1_d_bits_size(x_auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(x_auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(x_auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(x_auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_data(x_auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(x_auto_out_1_d_bits_corrupt),
    .auto_out_0_a_ready(x_auto_out_0_a_ready),
    .auto_out_0_a_valid(x_i_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(x_i_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(x_i_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(x_i_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(x_i_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(x_i_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(x_i_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(x_i_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(x_i_auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(x_i_auto_out_0_d_ready),
    .auto_out_0_d_valid(x_auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(x_auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(x_auto_out_0_d_bits_param),
    .auto_out_0_d_bits_size(x_auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(x_auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(x_auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(x_auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_data(x_auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(x_auto_out_0_d_bits_corrupt)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) x_mode = $urandom_range(0, 15);
      x_auto_in_1_a_valid = 1'($urandom);
      x_auto_in_1_a_bits_opcode = 4'($urandom);
      x_auto_in_1_a_bits_param = 3'($urandom);
      x_auto_in_1_a_bits_size = 2'($urandom);
      x_auto_in_1_a_bits_source = 4'($urandom);
      x_auto_in_1_a_bits_address = 48'({$urandom, $urandom});
      x_auto_in_1_a_bits_user_memBackType_MM = 1'($urandom);
      x_auto_in_1_a_bits_user_memPageType_NC = 1'($urandom);
      x_auto_in_1_a_bits_mask = 8'($urandom);
      x_auto_in_1_a_bits_data = 64'({$urandom, $urandom});
      x_auto_in_1_a_bits_corrupt = 1'($urandom);
      x_auto_in_1_d_ready = 1'($urandom);
      x_auto_in_0_a_valid = 1'($urandom);
      x_auto_in_0_a_bits_opcode = 4'($urandom);
      x_auto_in_0_a_bits_param = 3'($urandom);
      x_auto_in_0_a_bits_size = 2'($urandom);
      x_auto_in_0_a_bits_source = 1'($urandom);
      x_auto_in_0_a_bits_address = 48'({$urandom, $urandom});
      x_auto_in_0_a_bits_user_memPageType_NC = 1'($urandom);
      x_auto_in_0_a_bits_user_memBackType_MM = 1'($urandom);
      x_auto_in_0_a_bits_mask = 8'($urandom);
      x_auto_in_0_a_bits_data = 64'({$urandom, $urandom});
      x_auto_in_0_a_bits_corrupt = 1'($urandom);
      x_auto_in_0_d_ready = 1'($urandom);
      x_auto_out_2_a_ready = 1'($urandom);
      x_auto_out_2_d_valid = 1'($urandom);
      x_auto_out_2_d_bits_opcode = 4'($urandom);
      x_auto_out_2_d_bits_param = 2'($urandom);
      x_auto_out_2_d_bits_size = 2'($urandom);
      x_auto_out_2_d_bits_source = 5'($urandom);
      x_auto_out_2_d_bits_sink = 1'($urandom);
      x_auto_out_2_d_bits_denied = 1'($urandom);
      x_auto_out_2_d_bits_data = 64'({$urandom, $urandom});
      x_auto_out_2_d_bits_corrupt = 1'($urandom);
      x_auto_out_1_a_ready = 1'($urandom);
      x_auto_out_1_d_valid = 1'($urandom);
      x_auto_out_1_d_bits_opcode = 4'($urandom);
      x_auto_out_1_d_bits_param = 2'($urandom);
      x_auto_out_1_d_bits_size = 2'($urandom);
      x_auto_out_1_d_bits_source = 5'($urandom);
      x_auto_out_1_d_bits_sink = 1'($urandom);
      x_auto_out_1_d_bits_denied = 1'($urandom);
      x_auto_out_1_d_bits_data = 64'({$urandom, $urandom});
      x_auto_out_1_d_bits_corrupt = 1'($urandom);
      x_auto_out_0_a_ready = 1'($urandom);
      x_auto_out_0_d_valid = 1'($urandom);
      x_auto_out_0_d_bits_opcode = 4'($urandom);
      x_auto_out_0_d_bits_param = 2'($urandom);
      x_auto_out_0_d_bits_size = 2'($urandom);
      x_auto_out_0_d_bits_source = 5'($urandom);
      x_auto_out_0_d_bits_sink = 1'($urandom);
      x_auto_out_0_d_bits_denied = 1'($urandom);
      x_auto_out_0_d_bits_data = 64'({$urandom, $urandom});
      x_auto_out_0_d_bits_corrupt = 1'($urandom);
      x_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_x
        case ($urandom_range(0, 5))
          0, 1: x_auto_in_0_a_bits_address = {18'h0, 18'h38010, x_auto_in_0_a_bits_address[11:0]};
          2, 3: x_auto_in_0_a_bits_address = {18'h0, 22'h380220, x_auto_in_0_a_bits_address[7:0]};
          4:    x_auto_in_0_a_bits_address = {18'h0, 22'h380221, x_auto_in_0_a_bits_address[7:0]};
          default: ;
        endcase
        
        case ($urandom_range(0, 5))
          0, 1: x_auto_in_1_a_bits_address = {18'h0, 18'h38010, x_auto_in_1_a_bits_address[11:0]};
          2, 3: x_auto_in_1_a_bits_address = {18'h0, 22'h380220, x_auto_in_1_a_bits_address[7:0]};
          4:    x_auto_in_1_a_bits_address = {18'h0, 22'h380221, x_auto_in_1_a_bits_address[7:0]};
          default: ;
        endcase
        
        if ($urandom_range(0, 1)) x_auto_out_0_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
        if ($urandom_range(0, 1)) x_auto_out_1_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
        if ($urandom_range(0, 1)) x_auto_out_2_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
        if (x_mode >= 10) begin
          x_auto_out_0_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_out_1_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_out_2_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_in_0_d_ready  = ($urandom_range(0, 7) == 0);
          x_auto_in_1_d_ready  = ($urandom_range(0, 7) == 0);
        end
      end
      #4;
      x_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&x_armed)) begin
        checks++;
        if (x_g_auto_in_1_a_ready !== x_i_auto_in_1_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_a_ready g=%h i=%h", cyc, x_g_auto_in_1_a_ready, x_i_auto_in_1_a_ready);
        end
        x_s1_auto_in_1_a_ready |= x_g_auto_in_1_a_ready;
        x_s0_auto_in_1_a_ready |= ~x_g_auto_in_1_a_ready;
        checks++;
        if (x_g_auto_in_1_d_valid !== x_i_auto_in_1_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_valid g=%h i=%h", cyc, x_g_auto_in_1_d_valid, x_i_auto_in_1_d_valid);
        end
        x_s1_auto_in_1_d_valid |= x_g_auto_in_1_d_valid;
        x_s0_auto_in_1_d_valid |= ~x_g_auto_in_1_d_valid;
        checks++;
        if (x_g_auto_in_1_d_bits_opcode !== x_i_auto_in_1_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_opcode g=%h i=%h", cyc, x_g_auto_in_1_d_bits_opcode, x_i_auto_in_1_d_bits_opcode);
        end
        x_s1_auto_in_1_d_bits_opcode |= x_g_auto_in_1_d_bits_opcode;
        x_s0_auto_in_1_d_bits_opcode |= ~x_g_auto_in_1_d_bits_opcode;
        checks++;
        if (x_g_auto_in_1_d_bits_param !== x_i_auto_in_1_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_param g=%h i=%h", cyc, x_g_auto_in_1_d_bits_param, x_i_auto_in_1_d_bits_param);
        end
        x_s1_auto_in_1_d_bits_param |= x_g_auto_in_1_d_bits_param;
        x_s0_auto_in_1_d_bits_param |= ~x_g_auto_in_1_d_bits_param;
        checks++;
        if (x_g_auto_in_1_d_bits_size !== x_i_auto_in_1_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_size g=%h i=%h", cyc, x_g_auto_in_1_d_bits_size, x_i_auto_in_1_d_bits_size);
        end
        x_s1_auto_in_1_d_bits_size |= x_g_auto_in_1_d_bits_size;
        x_s0_auto_in_1_d_bits_size |= ~x_g_auto_in_1_d_bits_size;
        checks++;
        if (x_g_auto_in_1_d_bits_source !== x_i_auto_in_1_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_source g=%h i=%h", cyc, x_g_auto_in_1_d_bits_source, x_i_auto_in_1_d_bits_source);
        end
        x_s1_auto_in_1_d_bits_source |= x_g_auto_in_1_d_bits_source;
        x_s0_auto_in_1_d_bits_source |= ~x_g_auto_in_1_d_bits_source;
        checks++;
        if (x_g_auto_in_1_d_bits_sink !== x_i_auto_in_1_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_sink g=%h i=%h", cyc, x_g_auto_in_1_d_bits_sink, x_i_auto_in_1_d_bits_sink);
        end
        x_s1_auto_in_1_d_bits_sink |= x_g_auto_in_1_d_bits_sink;
        x_s0_auto_in_1_d_bits_sink |= ~x_g_auto_in_1_d_bits_sink;
        checks++;
        if (x_g_auto_in_1_d_bits_denied !== x_i_auto_in_1_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_denied g=%h i=%h", cyc, x_g_auto_in_1_d_bits_denied, x_i_auto_in_1_d_bits_denied);
        end
        x_s1_auto_in_1_d_bits_denied |= x_g_auto_in_1_d_bits_denied;
        x_s0_auto_in_1_d_bits_denied |= ~x_g_auto_in_1_d_bits_denied;
        checks++;
        if (x_g_auto_in_1_d_bits_data !== x_i_auto_in_1_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_data g=%h i=%h", cyc, x_g_auto_in_1_d_bits_data, x_i_auto_in_1_d_bits_data);
        end
        x_s1_auto_in_1_d_bits_data |= x_g_auto_in_1_d_bits_data;
        x_s0_auto_in_1_d_bits_data |= ~x_g_auto_in_1_d_bits_data;
        checks++;
        if (x_g_auto_in_1_d_bits_corrupt !== x_i_auto_in_1_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_1_d_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_1_d_bits_corrupt, x_i_auto_in_1_d_bits_corrupt);
        end
        x_s1_auto_in_1_d_bits_corrupt |= x_g_auto_in_1_d_bits_corrupt;
        x_s0_auto_in_1_d_bits_corrupt |= ~x_g_auto_in_1_d_bits_corrupt;
        checks++;
        if (x_g_auto_in_0_a_ready !== x_i_auto_in_0_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_a_ready g=%h i=%h", cyc, x_g_auto_in_0_a_ready, x_i_auto_in_0_a_ready);
        end
        x_s1_auto_in_0_a_ready |= x_g_auto_in_0_a_ready;
        x_s0_auto_in_0_a_ready |= ~x_g_auto_in_0_a_ready;
        checks++;
        if (x_g_auto_in_0_d_valid !== x_i_auto_in_0_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_valid g=%h i=%h", cyc, x_g_auto_in_0_d_valid, x_i_auto_in_0_d_valid);
        end
        x_s1_auto_in_0_d_valid |= x_g_auto_in_0_d_valid;
        x_s0_auto_in_0_d_valid |= ~x_g_auto_in_0_d_valid;
        checks++;
        if (x_g_auto_in_0_d_bits_opcode !== x_i_auto_in_0_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_opcode g=%h i=%h", cyc, x_g_auto_in_0_d_bits_opcode, x_i_auto_in_0_d_bits_opcode);
        end
        x_s1_auto_in_0_d_bits_opcode |= x_g_auto_in_0_d_bits_opcode;
        x_s0_auto_in_0_d_bits_opcode |= ~x_g_auto_in_0_d_bits_opcode;
        checks++;
        if (x_g_auto_in_0_d_bits_param !== x_i_auto_in_0_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_param g=%h i=%h", cyc, x_g_auto_in_0_d_bits_param, x_i_auto_in_0_d_bits_param);
        end
        x_s1_auto_in_0_d_bits_param |= x_g_auto_in_0_d_bits_param;
        x_s0_auto_in_0_d_bits_param |= ~x_g_auto_in_0_d_bits_param;
        checks++;
        if (x_g_auto_in_0_d_bits_size !== x_i_auto_in_0_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_size g=%h i=%h", cyc, x_g_auto_in_0_d_bits_size, x_i_auto_in_0_d_bits_size);
        end
        x_s1_auto_in_0_d_bits_size |= x_g_auto_in_0_d_bits_size;
        x_s0_auto_in_0_d_bits_size |= ~x_g_auto_in_0_d_bits_size;
        checks++;
        if (x_g_auto_in_0_d_bits_sink !== x_i_auto_in_0_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_sink g=%h i=%h", cyc, x_g_auto_in_0_d_bits_sink, x_i_auto_in_0_d_bits_sink);
        end
        x_s1_auto_in_0_d_bits_sink |= x_g_auto_in_0_d_bits_sink;
        x_s0_auto_in_0_d_bits_sink |= ~x_g_auto_in_0_d_bits_sink;
        checks++;
        if (x_g_auto_in_0_d_bits_denied !== x_i_auto_in_0_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_denied g=%h i=%h", cyc, x_g_auto_in_0_d_bits_denied, x_i_auto_in_0_d_bits_denied);
        end
        x_s1_auto_in_0_d_bits_denied |= x_g_auto_in_0_d_bits_denied;
        x_s0_auto_in_0_d_bits_denied |= ~x_g_auto_in_0_d_bits_denied;
        checks++;
        if (x_g_auto_in_0_d_bits_data !== x_i_auto_in_0_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_data g=%h i=%h", cyc, x_g_auto_in_0_d_bits_data, x_i_auto_in_0_d_bits_data);
        end
        x_s1_auto_in_0_d_bits_data |= x_g_auto_in_0_d_bits_data;
        x_s0_auto_in_0_d_bits_data |= ~x_g_auto_in_0_d_bits_data;
        checks++;
        if (x_g_auto_in_0_d_bits_corrupt !== x_i_auto_in_0_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_in_0_d_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_0_d_bits_corrupt, x_i_auto_in_0_d_bits_corrupt);
        end
        x_s1_auto_in_0_d_bits_corrupt |= x_g_auto_in_0_d_bits_corrupt;
        x_s0_auto_in_0_d_bits_corrupt |= ~x_g_auto_in_0_d_bits_corrupt;
        checks++;
        if (x_g_auto_out_2_a_valid !== x_i_auto_out_2_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_valid g=%h i=%h", cyc, x_g_auto_out_2_a_valid, x_i_auto_out_2_a_valid);
        end
        x_s1_auto_out_2_a_valid |= x_g_auto_out_2_a_valid;
        x_s0_auto_out_2_a_valid |= ~x_g_auto_out_2_a_valid;
        checks++;
        if (x_g_auto_out_2_a_bits_opcode !== x_i_auto_out_2_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_2_a_bits_opcode, x_i_auto_out_2_a_bits_opcode);
        end
        x_s1_auto_out_2_a_bits_opcode |= x_g_auto_out_2_a_bits_opcode;
        x_s0_auto_out_2_a_bits_opcode |= ~x_g_auto_out_2_a_bits_opcode;
        checks++;
        if (x_g_auto_out_2_a_bits_param !== x_i_auto_out_2_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_param g=%h i=%h", cyc, x_g_auto_out_2_a_bits_param, x_i_auto_out_2_a_bits_param);
        end
        x_s1_auto_out_2_a_bits_param |= x_g_auto_out_2_a_bits_param;
        x_s0_auto_out_2_a_bits_param |= ~x_g_auto_out_2_a_bits_param;
        checks++;
        if (x_g_auto_out_2_a_bits_size !== x_i_auto_out_2_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_size g=%h i=%h", cyc, x_g_auto_out_2_a_bits_size, x_i_auto_out_2_a_bits_size);
        end
        x_s1_auto_out_2_a_bits_size |= x_g_auto_out_2_a_bits_size;
        x_s0_auto_out_2_a_bits_size |= ~x_g_auto_out_2_a_bits_size;
        checks++;
        if (x_g_auto_out_2_a_bits_source !== x_i_auto_out_2_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_source g=%h i=%h", cyc, x_g_auto_out_2_a_bits_source, x_i_auto_out_2_a_bits_source);
        end
        x_s1_auto_out_2_a_bits_source |= x_g_auto_out_2_a_bits_source;
        x_s0_auto_out_2_a_bits_source |= ~x_g_auto_out_2_a_bits_source;
        checks++;
        if (x_g_auto_out_2_a_bits_address !== x_i_auto_out_2_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_address g=%h i=%h", cyc, x_g_auto_out_2_a_bits_address, x_i_auto_out_2_a_bits_address);
        end
        x_s1_auto_out_2_a_bits_address |= x_g_auto_out_2_a_bits_address;
        x_s0_auto_out_2_a_bits_address |= ~x_g_auto_out_2_a_bits_address;
        checks++;
        if (x_g_auto_out_2_a_bits_user_memBackType_MM !== x_i_auto_out_2_a_bits_user_memBackType_MM) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_user_memBackType_MM g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_memBackType_MM, x_i_auto_out_2_a_bits_user_memBackType_MM);
        end
        x_s1_auto_out_2_a_bits_user_memBackType_MM |= x_g_auto_out_2_a_bits_user_memBackType_MM;
        x_s0_auto_out_2_a_bits_user_memBackType_MM |= ~x_g_auto_out_2_a_bits_user_memBackType_MM;
        checks++;
        if (x_g_auto_out_2_a_bits_user_memPageType_NC !== x_i_auto_out_2_a_bits_user_memPageType_NC) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_user_memPageType_NC g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_memPageType_NC, x_i_auto_out_2_a_bits_user_memPageType_NC);
        end
        x_s1_auto_out_2_a_bits_user_memPageType_NC |= x_g_auto_out_2_a_bits_user_memPageType_NC;
        x_s0_auto_out_2_a_bits_user_memPageType_NC |= ~x_g_auto_out_2_a_bits_user_memPageType_NC;
        checks++;
        if (x_g_auto_out_2_a_bits_mask !== x_i_auto_out_2_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_2_a_bits_mask, x_i_auto_out_2_a_bits_mask);
        end
        x_s1_auto_out_2_a_bits_mask |= x_g_auto_out_2_a_bits_mask;
        x_s0_auto_out_2_a_bits_mask |= ~x_g_auto_out_2_a_bits_mask;
        checks++;
        if (x_g_auto_out_2_a_bits_data !== x_i_auto_out_2_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_data g=%h i=%h", cyc, x_g_auto_out_2_a_bits_data, x_i_auto_out_2_a_bits_data);
        end
        x_s1_auto_out_2_a_bits_data |= x_g_auto_out_2_a_bits_data;
        x_s0_auto_out_2_a_bits_data |= ~x_g_auto_out_2_a_bits_data;
        checks++;
        if (x_g_auto_out_2_a_bits_corrupt !== x_i_auto_out_2_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_2_a_bits_corrupt, x_i_auto_out_2_a_bits_corrupt);
        end
        x_s1_auto_out_2_a_bits_corrupt |= x_g_auto_out_2_a_bits_corrupt;
        x_s0_auto_out_2_a_bits_corrupt |= ~x_g_auto_out_2_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_2_d_ready !== x_i_auto_out_2_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_2_d_ready g=%h i=%h", cyc, x_g_auto_out_2_d_ready, x_i_auto_out_2_d_ready);
        end
        x_s1_auto_out_2_d_ready |= x_g_auto_out_2_d_ready;
        x_s0_auto_out_2_d_ready |= ~x_g_auto_out_2_d_ready;
        checks++;
        if (x_g_auto_out_1_a_valid !== x_i_auto_out_1_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_valid g=%h i=%h", cyc, x_g_auto_out_1_a_valid, x_i_auto_out_1_a_valid);
        end
        x_s1_auto_out_1_a_valid |= x_g_auto_out_1_a_valid;
        x_s0_auto_out_1_a_valid |= ~x_g_auto_out_1_a_valid;
        checks++;
        if (x_g_auto_out_1_a_bits_opcode !== x_i_auto_out_1_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_1_a_bits_opcode, x_i_auto_out_1_a_bits_opcode);
        end
        x_s1_auto_out_1_a_bits_opcode |= x_g_auto_out_1_a_bits_opcode;
        x_s0_auto_out_1_a_bits_opcode |= ~x_g_auto_out_1_a_bits_opcode;
        checks++;
        if (x_g_auto_out_1_a_bits_param !== x_i_auto_out_1_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_param g=%h i=%h", cyc, x_g_auto_out_1_a_bits_param, x_i_auto_out_1_a_bits_param);
        end
        x_s1_auto_out_1_a_bits_param |= x_g_auto_out_1_a_bits_param;
        x_s0_auto_out_1_a_bits_param |= ~x_g_auto_out_1_a_bits_param;
        checks++;
        if (x_g_auto_out_1_a_bits_size !== x_i_auto_out_1_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_size g=%h i=%h", cyc, x_g_auto_out_1_a_bits_size, x_i_auto_out_1_a_bits_size);
        end
        x_s1_auto_out_1_a_bits_size |= x_g_auto_out_1_a_bits_size;
        x_s0_auto_out_1_a_bits_size |= ~x_g_auto_out_1_a_bits_size;
        checks++;
        if (x_g_auto_out_1_a_bits_source !== x_i_auto_out_1_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_source g=%h i=%h", cyc, x_g_auto_out_1_a_bits_source, x_i_auto_out_1_a_bits_source);
        end
        x_s1_auto_out_1_a_bits_source |= x_g_auto_out_1_a_bits_source;
        x_s0_auto_out_1_a_bits_source |= ~x_g_auto_out_1_a_bits_source;
        checks++;
        if (x_g_auto_out_1_a_bits_address !== x_i_auto_out_1_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_address g=%h i=%h", cyc, x_g_auto_out_1_a_bits_address, x_i_auto_out_1_a_bits_address);
        end
        x_s1_auto_out_1_a_bits_address |= x_g_auto_out_1_a_bits_address;
        x_s0_auto_out_1_a_bits_address |= ~x_g_auto_out_1_a_bits_address;
        checks++;
        if (x_g_auto_out_1_a_bits_mask !== x_i_auto_out_1_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_1_a_bits_mask, x_i_auto_out_1_a_bits_mask);
        end
        x_s1_auto_out_1_a_bits_mask |= x_g_auto_out_1_a_bits_mask;
        x_s0_auto_out_1_a_bits_mask |= ~x_g_auto_out_1_a_bits_mask;
        checks++;
        if (x_g_auto_out_1_a_bits_data !== x_i_auto_out_1_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_data g=%h i=%h", cyc, x_g_auto_out_1_a_bits_data, x_i_auto_out_1_a_bits_data);
        end
        x_s1_auto_out_1_a_bits_data |= x_g_auto_out_1_a_bits_data;
        x_s0_auto_out_1_a_bits_data |= ~x_g_auto_out_1_a_bits_data;
        checks++;
        if (x_g_auto_out_1_a_bits_corrupt !== x_i_auto_out_1_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_1_a_bits_corrupt, x_i_auto_out_1_a_bits_corrupt);
        end
        x_s1_auto_out_1_a_bits_corrupt |= x_g_auto_out_1_a_bits_corrupt;
        x_s0_auto_out_1_a_bits_corrupt |= ~x_g_auto_out_1_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_1_d_ready !== x_i_auto_out_1_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_1_d_ready g=%h i=%h", cyc, x_g_auto_out_1_d_ready, x_i_auto_out_1_d_ready);
        end
        x_s1_auto_out_1_d_ready |= x_g_auto_out_1_d_ready;
        x_s0_auto_out_1_d_ready |= ~x_g_auto_out_1_d_ready;
        checks++;
        if (x_g_auto_out_0_a_valid !== x_i_auto_out_0_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_valid g=%h i=%h", cyc, x_g_auto_out_0_a_valid, x_i_auto_out_0_a_valid);
        end
        x_s1_auto_out_0_a_valid |= x_g_auto_out_0_a_valid;
        x_s0_auto_out_0_a_valid |= ~x_g_auto_out_0_a_valid;
        checks++;
        if (x_g_auto_out_0_a_bits_opcode !== x_i_auto_out_0_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_0_a_bits_opcode, x_i_auto_out_0_a_bits_opcode);
        end
        x_s1_auto_out_0_a_bits_opcode |= x_g_auto_out_0_a_bits_opcode;
        x_s0_auto_out_0_a_bits_opcode |= ~x_g_auto_out_0_a_bits_opcode;
        checks++;
        if (x_g_auto_out_0_a_bits_param !== x_i_auto_out_0_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_param g=%h i=%h", cyc, x_g_auto_out_0_a_bits_param, x_i_auto_out_0_a_bits_param);
        end
        x_s1_auto_out_0_a_bits_param |= x_g_auto_out_0_a_bits_param;
        x_s0_auto_out_0_a_bits_param |= ~x_g_auto_out_0_a_bits_param;
        checks++;
        if (x_g_auto_out_0_a_bits_size !== x_i_auto_out_0_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_size g=%h i=%h", cyc, x_g_auto_out_0_a_bits_size, x_i_auto_out_0_a_bits_size);
        end
        x_s1_auto_out_0_a_bits_size |= x_g_auto_out_0_a_bits_size;
        x_s0_auto_out_0_a_bits_size |= ~x_g_auto_out_0_a_bits_size;
        checks++;
        if (x_g_auto_out_0_a_bits_source !== x_i_auto_out_0_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_source g=%h i=%h", cyc, x_g_auto_out_0_a_bits_source, x_i_auto_out_0_a_bits_source);
        end
        x_s1_auto_out_0_a_bits_source |= x_g_auto_out_0_a_bits_source;
        x_s0_auto_out_0_a_bits_source |= ~x_g_auto_out_0_a_bits_source;
        checks++;
        if (x_g_auto_out_0_a_bits_address !== x_i_auto_out_0_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_address g=%h i=%h", cyc, x_g_auto_out_0_a_bits_address, x_i_auto_out_0_a_bits_address);
        end
        x_s1_auto_out_0_a_bits_address |= x_g_auto_out_0_a_bits_address;
        x_s0_auto_out_0_a_bits_address |= ~x_g_auto_out_0_a_bits_address;
        checks++;
        if (x_g_auto_out_0_a_bits_mask !== x_i_auto_out_0_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_0_a_bits_mask, x_i_auto_out_0_a_bits_mask);
        end
        x_s1_auto_out_0_a_bits_mask |= x_g_auto_out_0_a_bits_mask;
        x_s0_auto_out_0_a_bits_mask |= ~x_g_auto_out_0_a_bits_mask;
        checks++;
        if (x_g_auto_out_0_a_bits_data !== x_i_auto_out_0_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_data g=%h i=%h", cyc, x_g_auto_out_0_a_bits_data, x_i_auto_out_0_a_bits_data);
        end
        x_s1_auto_out_0_a_bits_data |= x_g_auto_out_0_a_bits_data;
        x_s0_auto_out_0_a_bits_data |= ~x_g_auto_out_0_a_bits_data;
        checks++;
        if (x_g_auto_out_0_a_bits_corrupt !== x_i_auto_out_0_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_0_a_bits_corrupt, x_i_auto_out_0_a_bits_corrupt);
        end
        x_s1_auto_out_0_a_bits_corrupt |= x_g_auto_out_0_a_bits_corrupt;
        x_s0_auto_out_0_a_bits_corrupt |= ~x_g_auto_out_0_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_0_d_ready !== x_i_auto_out_0_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_6.auto_out_0_d_ready g=%h i=%h", cyc, x_g_auto_out_0_d_ready, x_i_auto_out_0_d_ready);
        end
        x_s1_auto_out_0_d_ready |= x_g_auto_out_0_d_ready;
        x_s0_auto_out_0_d_ready |= ~x_g_auto_out_0_d_ready;
        if (x_g_auto_out_0_a_valid && x_auto_out_0_a_ready && x_g_auto_out_0_a_bits_source[4]) x_cov_a0_in0++;
        if (x_g_auto_out_0_a_valid && x_auto_out_0_a_ready && !x_g_auto_out_0_a_bits_source[4]) x_cov_a0_in1++;
        if (x_g_auto_out_1_a_valid && x_auto_out_1_a_ready) x_cov_a1_fire++;
        if (x_g_auto_out_2_a_valid && x_auto_out_2_a_ready) x_cov_a2_fire++;
        if (x_auto_in_0_a_valid && x_auto_in_1_a_valid && x_auto_in_0_a_bits_address[29:12] == x_auto_in_1_a_bits_address[29:12]) x_cov_a_contend++;
        if (x_g_auto_in_0_d_valid && x_auto_in_0_d_ready) x_cov_d0_fire++;
        if (x_g_auto_in_1_d_valid && x_auto_in_1_d_ready) x_cov_d1_fire++;
        if (x_auto_out_0_d_valid && x_auto_out_1_d_valid && x_auto_out_2_d_valid) x_cov_d_contend++;
        if (x_g_auto_in_1_d_valid && !x_u_gold.readys_mask_4[0]) x_cov_rr_flip++;
      end
      if (x_armed_at < 0 && (&x_armed)) x_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(x_s0_auto_in_1_a_ready && x_s1_auto_in_1_a_ready)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_a_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_valid && x_s1_auto_in_1_d_valid)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[0] && x_s1_auto_in_1_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[1] && x_s1_auto_in_1_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[2] && x_s1_auto_in_1_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[3] && x_s1_auto_in_1_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_param[0] && x_s1_auto_in_1_d_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_param[1] && x_s1_auto_in_1_d_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_size[0] && x_s1_auto_in_1_d_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_size[1] && x_s1_auto_in_1_d_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[0] && x_s1_auto_in_1_d_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[1] && x_s1_auto_in_1_d_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[2] && x_s1_auto_in_1_d_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[3] && x_s1_auto_in_1_d_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink && x_s1_auto_in_1_d_bits_sink)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_sink 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_denied && x_s1_auto_in_1_d_bits_denied)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_denied 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[0] && x_s1_auto_in_1_d_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[1] && x_s1_auto_in_1_d_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[2] && x_s1_auto_in_1_d_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[3] && x_s1_auto_in_1_d_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[4] && x_s1_auto_in_1_d_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[5] && x_s1_auto_in_1_d_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[6] && x_s1_auto_in_1_d_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[7] && x_s1_auto_in_1_d_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[8] && x_s1_auto_in_1_d_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[9] && x_s1_auto_in_1_d_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[10] && x_s1_auto_in_1_d_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[11] && x_s1_auto_in_1_d_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[12] && x_s1_auto_in_1_d_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[13] && x_s1_auto_in_1_d_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[14] && x_s1_auto_in_1_d_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[15] && x_s1_auto_in_1_d_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[16] && x_s1_auto_in_1_d_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[17] && x_s1_auto_in_1_d_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[18] && x_s1_auto_in_1_d_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[19] && x_s1_auto_in_1_d_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[20] && x_s1_auto_in_1_d_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[21] && x_s1_auto_in_1_d_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[22] && x_s1_auto_in_1_d_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[23] && x_s1_auto_in_1_d_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[24] && x_s1_auto_in_1_d_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[25] && x_s1_auto_in_1_d_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[26] && x_s1_auto_in_1_d_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[27] && x_s1_auto_in_1_d_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[28] && x_s1_auto_in_1_d_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[29] && x_s1_auto_in_1_d_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[30] && x_s1_auto_in_1_d_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[31] && x_s1_auto_in_1_d_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[32] && x_s1_auto_in_1_d_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[33] && x_s1_auto_in_1_d_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[34] && x_s1_auto_in_1_d_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[35] && x_s1_auto_in_1_d_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[36] && x_s1_auto_in_1_d_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[37] && x_s1_auto_in_1_d_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[38] && x_s1_auto_in_1_d_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[39] && x_s1_auto_in_1_d_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[40] && x_s1_auto_in_1_d_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[41] && x_s1_auto_in_1_d_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[42] && x_s1_auto_in_1_d_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[43] && x_s1_auto_in_1_d_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[44] && x_s1_auto_in_1_d_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[45] && x_s1_auto_in_1_d_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[46] && x_s1_auto_in_1_d_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[47] && x_s1_auto_in_1_d_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[48] && x_s1_auto_in_1_d_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[49] && x_s1_auto_in_1_d_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[50] && x_s1_auto_in_1_d_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[51] && x_s1_auto_in_1_d_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[52] && x_s1_auto_in_1_d_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[53] && x_s1_auto_in_1_d_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[54] && x_s1_auto_in_1_d_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[55] && x_s1_auto_in_1_d_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[56] && x_s1_auto_in_1_d_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[57] && x_s1_auto_in_1_d_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[58] && x_s1_auto_in_1_d_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[59] && x_s1_auto_in_1_d_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[60] && x_s1_auto_in_1_d_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[61] && x_s1_auto_in_1_d_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[62] && x_s1_auto_in_1_d_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[63] && x_s1_auto_in_1_d_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_corrupt && x_s1_auto_in_1_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_1_d_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_a_ready && x_s1_auto_in_0_a_ready)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_a_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_valid && x_s1_auto_in_0_d_valid)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[0] && x_s1_auto_in_0_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[1] && x_s1_auto_in_0_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[2] && x_s1_auto_in_0_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[3] && x_s1_auto_in_0_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_param[0] && x_s1_auto_in_0_d_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_param[1] && x_s1_auto_in_0_d_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_size[0] && x_s1_auto_in_0_d_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_size[1] && x_s1_auto_in_0_d_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink && x_s1_auto_in_0_d_bits_sink)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_sink 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_denied && x_s1_auto_in_0_d_bits_denied)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_denied 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[0] && x_s1_auto_in_0_d_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[1] && x_s1_auto_in_0_d_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[2] && x_s1_auto_in_0_d_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[3] && x_s1_auto_in_0_d_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[4] && x_s1_auto_in_0_d_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[5] && x_s1_auto_in_0_d_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[6] && x_s1_auto_in_0_d_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[7] && x_s1_auto_in_0_d_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[8] && x_s1_auto_in_0_d_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[9] && x_s1_auto_in_0_d_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[10] && x_s1_auto_in_0_d_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[11] && x_s1_auto_in_0_d_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[12] && x_s1_auto_in_0_d_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[13] && x_s1_auto_in_0_d_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[14] && x_s1_auto_in_0_d_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[15] && x_s1_auto_in_0_d_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[16] && x_s1_auto_in_0_d_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[17] && x_s1_auto_in_0_d_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[18] && x_s1_auto_in_0_d_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[19] && x_s1_auto_in_0_d_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[20] && x_s1_auto_in_0_d_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[21] && x_s1_auto_in_0_d_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[22] && x_s1_auto_in_0_d_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[23] && x_s1_auto_in_0_d_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[24] && x_s1_auto_in_0_d_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[25] && x_s1_auto_in_0_d_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[26] && x_s1_auto_in_0_d_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[27] && x_s1_auto_in_0_d_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[28] && x_s1_auto_in_0_d_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[29] && x_s1_auto_in_0_d_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[30] && x_s1_auto_in_0_d_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[31] && x_s1_auto_in_0_d_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[32] && x_s1_auto_in_0_d_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[33] && x_s1_auto_in_0_d_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[34] && x_s1_auto_in_0_d_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[35] && x_s1_auto_in_0_d_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[36] && x_s1_auto_in_0_d_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[37] && x_s1_auto_in_0_d_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[38] && x_s1_auto_in_0_d_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[39] && x_s1_auto_in_0_d_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[40] && x_s1_auto_in_0_d_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[41] && x_s1_auto_in_0_d_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[42] && x_s1_auto_in_0_d_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[43] && x_s1_auto_in_0_d_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[44] && x_s1_auto_in_0_d_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[45] && x_s1_auto_in_0_d_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[46] && x_s1_auto_in_0_d_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[47] && x_s1_auto_in_0_d_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[48] && x_s1_auto_in_0_d_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[49] && x_s1_auto_in_0_d_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[50] && x_s1_auto_in_0_d_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[51] && x_s1_auto_in_0_d_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[52] && x_s1_auto_in_0_d_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[53] && x_s1_auto_in_0_d_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[54] && x_s1_auto_in_0_d_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[55] && x_s1_auto_in_0_d_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[56] && x_s1_auto_in_0_d_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[57] && x_s1_auto_in_0_d_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[58] && x_s1_auto_in_0_d_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[59] && x_s1_auto_in_0_d_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[60] && x_s1_auto_in_0_d_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[61] && x_s1_auto_in_0_d_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[62] && x_s1_auto_in_0_d_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[63] && x_s1_auto_in_0_d_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_corrupt && x_s1_auto_in_0_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_6.auto_in_0_d_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_valid && x_s1_auto_out_2_a_valid)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[0] && x_s1_auto_out_2_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[1] && x_s1_auto_out_2_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[2] && x_s1_auto_out_2_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[3] && x_s1_auto_out_2_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[0] && x_s1_auto_out_2_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[1] && x_s1_auto_out_2_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[2] && x_s1_auto_out_2_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_size[0] && x_s1_auto_out_2_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_size[1] && x_s1_auto_out_2_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[0] && x_s1_auto_out_2_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[1] && x_s1_auto_out_2_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[2] && x_s1_auto_out_2_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[3] && x_s1_auto_out_2_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[4] && x_s1_auto_out_2_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[0] && x_s1_auto_out_2_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[1] && x_s1_auto_out_2_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[2] && x_s1_auto_out_2_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[3] && x_s1_auto_out_2_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[4] && x_s1_auto_out_2_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[5] && x_s1_auto_out_2_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[6] && x_s1_auto_out_2_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[7] && x_s1_auto_out_2_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[8] && x_s1_auto_out_2_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[9] && x_s1_auto_out_2_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[10] && x_s1_auto_out_2_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[11] && x_s1_auto_out_2_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[12] && x_s1_auto_out_2_a_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[13] && x_s1_auto_out_2_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[14] && x_s1_auto_out_2_a_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[15] && x_s1_auto_out_2_a_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[16] && x_s1_auto_out_2_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[17] && x_s1_auto_out_2_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[18] && x_s1_auto_out_2_a_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[19] && x_s1_auto_out_2_a_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[20] && x_s1_auto_out_2_a_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[21] && x_s1_auto_out_2_a_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[22] && x_s1_auto_out_2_a_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[23] && x_s1_auto_out_2_a_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[24] && x_s1_auto_out_2_a_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[25] && x_s1_auto_out_2_a_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[26] && x_s1_auto_out_2_a_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[27] && x_s1_auto_out_2_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[28] && x_s1_auto_out_2_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[29] && x_s1_auto_out_2_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[30] && x_s1_auto_out_2_a_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[31] && x_s1_auto_out_2_a_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[32] && x_s1_auto_out_2_a_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[33] && x_s1_auto_out_2_a_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[34] && x_s1_auto_out_2_a_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[35] && x_s1_auto_out_2_a_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[36] && x_s1_auto_out_2_a_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[37] && x_s1_auto_out_2_a_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[38] && x_s1_auto_out_2_a_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[39] && x_s1_auto_out_2_a_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[40] && x_s1_auto_out_2_a_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[41] && x_s1_auto_out_2_a_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[42] && x_s1_auto_out_2_a_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[43] && x_s1_auto_out_2_a_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[44] && x_s1_auto_out_2_a_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[45] && x_s1_auto_out_2_a_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[46] && x_s1_auto_out_2_a_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[47] && x_s1_auto_out_2_a_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_memBackType_MM && x_s1_auto_out_2_a_bits_user_memBackType_MM)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_user_memBackType_MM 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_memPageType_NC && x_s1_auto_out_2_a_bits_user_memPageType_NC)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_user_memPageType_NC 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[0] && x_s1_auto_out_2_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[1] && x_s1_auto_out_2_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[2] && x_s1_auto_out_2_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[3] && x_s1_auto_out_2_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[4] && x_s1_auto_out_2_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[5] && x_s1_auto_out_2_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[6] && x_s1_auto_out_2_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[7] && x_s1_auto_out_2_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[0] && x_s1_auto_out_2_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[1] && x_s1_auto_out_2_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[2] && x_s1_auto_out_2_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[3] && x_s1_auto_out_2_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[4] && x_s1_auto_out_2_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[5] && x_s1_auto_out_2_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[6] && x_s1_auto_out_2_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[7] && x_s1_auto_out_2_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[8] && x_s1_auto_out_2_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[9] && x_s1_auto_out_2_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[10] && x_s1_auto_out_2_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[11] && x_s1_auto_out_2_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[12] && x_s1_auto_out_2_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[13] && x_s1_auto_out_2_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[14] && x_s1_auto_out_2_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[15] && x_s1_auto_out_2_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[16] && x_s1_auto_out_2_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[17] && x_s1_auto_out_2_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[18] && x_s1_auto_out_2_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[19] && x_s1_auto_out_2_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[20] && x_s1_auto_out_2_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[21] && x_s1_auto_out_2_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[22] && x_s1_auto_out_2_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[23] && x_s1_auto_out_2_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[24] && x_s1_auto_out_2_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[25] && x_s1_auto_out_2_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[26] && x_s1_auto_out_2_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[27] && x_s1_auto_out_2_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[28] && x_s1_auto_out_2_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[29] && x_s1_auto_out_2_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[30] && x_s1_auto_out_2_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[31] && x_s1_auto_out_2_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[32] && x_s1_auto_out_2_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[33] && x_s1_auto_out_2_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[34] && x_s1_auto_out_2_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[35] && x_s1_auto_out_2_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[36] && x_s1_auto_out_2_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[37] && x_s1_auto_out_2_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[38] && x_s1_auto_out_2_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[39] && x_s1_auto_out_2_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[40] && x_s1_auto_out_2_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[41] && x_s1_auto_out_2_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[42] && x_s1_auto_out_2_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[43] && x_s1_auto_out_2_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[44] && x_s1_auto_out_2_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[45] && x_s1_auto_out_2_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[46] && x_s1_auto_out_2_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[47] && x_s1_auto_out_2_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[48] && x_s1_auto_out_2_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[49] && x_s1_auto_out_2_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[50] && x_s1_auto_out_2_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[51] && x_s1_auto_out_2_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[52] && x_s1_auto_out_2_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[53] && x_s1_auto_out_2_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[54] && x_s1_auto_out_2_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[55] && x_s1_auto_out_2_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[56] && x_s1_auto_out_2_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[57] && x_s1_auto_out_2_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[58] && x_s1_auto_out_2_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[59] && x_s1_auto_out_2_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[60] && x_s1_auto_out_2_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[61] && x_s1_auto_out_2_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[62] && x_s1_auto_out_2_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[63] && x_s1_auto_out_2_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_corrupt && x_s1_auto_out_2_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_d_ready && x_s1_auto_out_2_d_ready)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_2_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_valid && x_s1_auto_out_1_a_valid)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[0] && x_s1_auto_out_1_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[1] && x_s1_auto_out_1_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[2] && x_s1_auto_out_1_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[3] && x_s1_auto_out_1_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[0] && x_s1_auto_out_1_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[1] && x_s1_auto_out_1_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[2] && x_s1_auto_out_1_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_size[0] && x_s1_auto_out_1_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_size[1] && x_s1_auto_out_1_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[0] && x_s1_auto_out_1_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[1] && x_s1_auto_out_1_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[2] && x_s1_auto_out_1_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[3] && x_s1_auto_out_1_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[4] && x_s1_auto_out_1_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[0] && x_s1_auto_out_1_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[1] && x_s1_auto_out_1_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[2] && x_s1_auto_out_1_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[3] && x_s1_auto_out_1_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[4] && x_s1_auto_out_1_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[5] && x_s1_auto_out_1_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[6] && x_s1_auto_out_1_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[7] && x_s1_auto_out_1_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[13] && x_s1_auto_out_1_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[17] && x_s1_auto_out_1_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[27] && x_s1_auto_out_1_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[28] && x_s1_auto_out_1_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[29] && x_s1_auto_out_1_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[0] && x_s1_auto_out_1_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[1] && x_s1_auto_out_1_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[2] && x_s1_auto_out_1_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[3] && x_s1_auto_out_1_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[4] && x_s1_auto_out_1_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[5] && x_s1_auto_out_1_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[6] && x_s1_auto_out_1_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[7] && x_s1_auto_out_1_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[0] && x_s1_auto_out_1_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[1] && x_s1_auto_out_1_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[2] && x_s1_auto_out_1_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[3] && x_s1_auto_out_1_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[4] && x_s1_auto_out_1_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[5] && x_s1_auto_out_1_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[6] && x_s1_auto_out_1_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[7] && x_s1_auto_out_1_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[8] && x_s1_auto_out_1_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[9] && x_s1_auto_out_1_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[10] && x_s1_auto_out_1_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[11] && x_s1_auto_out_1_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[12] && x_s1_auto_out_1_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[13] && x_s1_auto_out_1_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[14] && x_s1_auto_out_1_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[15] && x_s1_auto_out_1_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[16] && x_s1_auto_out_1_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[17] && x_s1_auto_out_1_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[18] && x_s1_auto_out_1_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[19] && x_s1_auto_out_1_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[20] && x_s1_auto_out_1_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[21] && x_s1_auto_out_1_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[22] && x_s1_auto_out_1_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[23] && x_s1_auto_out_1_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[24] && x_s1_auto_out_1_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[25] && x_s1_auto_out_1_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[26] && x_s1_auto_out_1_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[27] && x_s1_auto_out_1_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[28] && x_s1_auto_out_1_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[29] && x_s1_auto_out_1_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[30] && x_s1_auto_out_1_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[31] && x_s1_auto_out_1_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[32] && x_s1_auto_out_1_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[33] && x_s1_auto_out_1_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[34] && x_s1_auto_out_1_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[35] && x_s1_auto_out_1_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[36] && x_s1_auto_out_1_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[37] && x_s1_auto_out_1_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[38] && x_s1_auto_out_1_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[39] && x_s1_auto_out_1_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[40] && x_s1_auto_out_1_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[41] && x_s1_auto_out_1_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[42] && x_s1_auto_out_1_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[43] && x_s1_auto_out_1_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[44] && x_s1_auto_out_1_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[45] && x_s1_auto_out_1_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[46] && x_s1_auto_out_1_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[47] && x_s1_auto_out_1_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[48] && x_s1_auto_out_1_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[49] && x_s1_auto_out_1_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[50] && x_s1_auto_out_1_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[51] && x_s1_auto_out_1_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[52] && x_s1_auto_out_1_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[53] && x_s1_auto_out_1_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[54] && x_s1_auto_out_1_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[55] && x_s1_auto_out_1_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[56] && x_s1_auto_out_1_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[57] && x_s1_auto_out_1_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[58] && x_s1_auto_out_1_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[59] && x_s1_auto_out_1_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[60] && x_s1_auto_out_1_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[61] && x_s1_auto_out_1_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[62] && x_s1_auto_out_1_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[63] && x_s1_auto_out_1_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_corrupt && x_s1_auto_out_1_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_d_ready && x_s1_auto_out_1_d_ready)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_1_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_valid && x_s1_auto_out_0_a_valid)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[0] && x_s1_auto_out_0_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[1] && x_s1_auto_out_0_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[2] && x_s1_auto_out_0_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[3] && x_s1_auto_out_0_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[0] && x_s1_auto_out_0_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[1] && x_s1_auto_out_0_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[2] && x_s1_auto_out_0_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_size[0] && x_s1_auto_out_0_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_size[1] && x_s1_auto_out_0_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[0] && x_s1_auto_out_0_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[1] && x_s1_auto_out_0_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[2] && x_s1_auto_out_0_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[3] && x_s1_auto_out_0_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[4] && x_s1_auto_out_0_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[0] && x_s1_auto_out_0_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[1] && x_s1_auto_out_0_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[2] && x_s1_auto_out_0_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[3] && x_s1_auto_out_0_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[4] && x_s1_auto_out_0_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[5] && x_s1_auto_out_0_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[6] && x_s1_auto_out_0_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[7] && x_s1_auto_out_0_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[8] && x_s1_auto_out_0_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[9] && x_s1_auto_out_0_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[10] && x_s1_auto_out_0_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[11] && x_s1_auto_out_0_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[16] && x_s1_auto_out_0_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[27] && x_s1_auto_out_0_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[28] && x_s1_auto_out_0_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[29] && x_s1_auto_out_0_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[0] && x_s1_auto_out_0_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[1] && x_s1_auto_out_0_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[2] && x_s1_auto_out_0_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[3] && x_s1_auto_out_0_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[4] && x_s1_auto_out_0_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[5] && x_s1_auto_out_0_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[6] && x_s1_auto_out_0_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[7] && x_s1_auto_out_0_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[0] && x_s1_auto_out_0_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[1] && x_s1_auto_out_0_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[2] && x_s1_auto_out_0_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[3] && x_s1_auto_out_0_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[4] && x_s1_auto_out_0_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[5] && x_s1_auto_out_0_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[6] && x_s1_auto_out_0_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[7] && x_s1_auto_out_0_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[8] && x_s1_auto_out_0_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[9] && x_s1_auto_out_0_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[10] && x_s1_auto_out_0_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[11] && x_s1_auto_out_0_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[12] && x_s1_auto_out_0_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[13] && x_s1_auto_out_0_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[14] && x_s1_auto_out_0_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[15] && x_s1_auto_out_0_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[16] && x_s1_auto_out_0_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[17] && x_s1_auto_out_0_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[18] && x_s1_auto_out_0_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[19] && x_s1_auto_out_0_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[20] && x_s1_auto_out_0_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[21] && x_s1_auto_out_0_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[22] && x_s1_auto_out_0_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[23] && x_s1_auto_out_0_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[24] && x_s1_auto_out_0_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[25] && x_s1_auto_out_0_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[26] && x_s1_auto_out_0_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[27] && x_s1_auto_out_0_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[28] && x_s1_auto_out_0_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[29] && x_s1_auto_out_0_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[30] && x_s1_auto_out_0_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[31] && x_s1_auto_out_0_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[32] && x_s1_auto_out_0_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[33] && x_s1_auto_out_0_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[34] && x_s1_auto_out_0_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[35] && x_s1_auto_out_0_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[36] && x_s1_auto_out_0_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[37] && x_s1_auto_out_0_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[38] && x_s1_auto_out_0_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[39] && x_s1_auto_out_0_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[40] && x_s1_auto_out_0_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[41] && x_s1_auto_out_0_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[42] && x_s1_auto_out_0_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[43] && x_s1_auto_out_0_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[44] && x_s1_auto_out_0_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[45] && x_s1_auto_out_0_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[46] && x_s1_auto_out_0_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[47] && x_s1_auto_out_0_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[48] && x_s1_auto_out_0_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[49] && x_s1_auto_out_0_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[50] && x_s1_auto_out_0_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[51] && x_s1_auto_out_0_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[52] && x_s1_auto_out_0_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[53] && x_s1_auto_out_0_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[54] && x_s1_auto_out_0_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[55] && x_s1_auto_out_0_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[56] && x_s1_auto_out_0_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[57] && x_s1_auto_out_0_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[58] && x_s1_auto_out_0_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[59] && x_s1_auto_out_0_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[60] && x_s1_auto_out_0_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[61] && x_s1_auto_out_0_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[62] && x_s1_auto_out_0_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[63] && x_s1_auto_out_0_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_corrupt && x_s1_auto_out_0_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_d_ready && x_s1_auto_out_0_d_ready)) begin cov_fail++; $display("[COV] TLXbar_6.auto_out_0_d_ready 未见过 0 和 1"); end
    $display("[ARM] TLXbar_6 armed_at=%0d", x_armed_at);
    if (x_armed_at < 0) begin cov_fail++; $display("[ARM] TLXbar_6 从未 arm"); end
    $display("[COV] TLXbar_6.a0_in0 = %0d", x_cov_a0_in0);
    if (x_cov_a0_in0 < 200) begin cov_fail++; $display("[COV] TLXbar_6.a0_in0 < 200"); end
    $display("[COV] TLXbar_6.a0_in1 = %0d", x_cov_a0_in1);
    if (x_cov_a0_in1 < 200) begin cov_fail++; $display("[COV] TLXbar_6.a0_in1 < 200"); end
    $display("[COV] TLXbar_6.a1_fire = %0d", x_cov_a1_fire);
    if (x_cov_a1_fire < 200) begin cov_fail++; $display("[COV] TLXbar_6.a1_fire < 200"); end
    $display("[COV] TLXbar_6.a2_fire = %0d", x_cov_a2_fire);
    if (x_cov_a2_fire < 200) begin cov_fail++; $display("[COV] TLXbar_6.a2_fire < 200"); end
    $display("[COV] TLXbar_6.a_contend = %0d", x_cov_a_contend);
    if (x_cov_a_contend < 200) begin cov_fail++; $display("[COV] TLXbar_6.a_contend < 200"); end
    $display("[COV] TLXbar_6.d0_fire = %0d", x_cov_d0_fire);
    if (x_cov_d0_fire < 200) begin cov_fail++; $display("[COV] TLXbar_6.d0_fire < 200"); end
    $display("[COV] TLXbar_6.d1_fire = %0d", x_cov_d1_fire);
    if (x_cov_d1_fire < 200) begin cov_fail++; $display("[COV] TLXbar_6.d1_fire < 200"); end
    $display("[COV] TLXbar_6.d_contend = %0d", x_cov_d_contend);
    if (x_cov_d_contend < 200) begin cov_fail++; $display("[COV] TLXbar_6.d_contend < 200"); end
    $display("[COV] TLXbar_6.rr_flip = %0d", x_cov_rr_flip);
    if (x_cov_rr_flip < 200) begin cov_fail++; $display("[COV] TLXbar_6.rr_flip < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
